--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0070-messaging.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0700-outbox-event
CREATE TABLE ph11_bpm.outbox_event (
  event_id       uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  status         varchar(8) NOT NULL DEFAULT 'PENDING',
  attempts       smallint NOT NULL DEFAULT 0,
  sent_at        timestamptz,
  last_error     varchar(1000),
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('bpm.model.published.v1', 'bpm.model.retired.v1', 'bpm.instance.started.v1', 'bpm.instance.step.completed.v1', 'bpm.instance.completed.v1', 'bpm.instance.cancelled.v1', 'bpm.instance.suspended.v1', 'bpm.task.created.v1', 'bpm.task.assigned.v1', 'bpm.task.completed.v1', 'bpm.task.due-soon.v1', 'bpm.task.overdue.v1', 'bpm.saga.compensation.started.v1', 'bpm.saga.compensation.completed.v1', 'bpm.saga.compensation.failed.v1', 'bpm.incident.opened.v1', 'bpm.service.requested.v1', 'bpm.notification.requested.v1', 'bpm.audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_status CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
  CONSTRAINT ck_outbox_event_attempts CHECK (attempts BETWEEN 0 AND 100),
  CONSTRAINT ck_outbox_event_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL)),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['variables', 'formData', 'values', 'resultData', 'identifier', 'nationalId', 'fullName', 'dateOfBirth']))
);
CREATE INDEX ix_outbox_event_pending ON ph11_bpm.outbox_event (occurred_at) WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX ix_outbox_event_occurred ON ph11_bpm.outbox_event (occurred_at);
CREATE TRIGGER tg_outbox_event_immutable BEFORE UPDATE ON ph11_bpm.outbox_event FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('event_id', 'tenant_id', 'event_type', 'topic', 'aggregate_type', 'aggregate_id', 'partition_key', 'payload', 'occurred_at');
CALL ph11_bpm.p_enable_rls('ph11_bpm.outbox_event', 'P');
COMMENT ON TABLE ph11_bpm.outbox_event IS 'EN-11-21 Outbox (ADR-042, SAD 7.3; FR-11-028, 032, 056, 065) cho EVT-11-01…17, EVT-11-20, EVT-11-21 (bản ghi kiểm toán gửi PH-13). Ghi cùng giao dịch với thay đổi trạng thái (BR-11-023); bộ chuyển outbox đẩy lên Kafka, định tuyến theo topic, cập nhật status và attempts; quá 11.outbox.maxAttempts thì mở sự cố (ERR-11-101). Gồm cả lệnh service.requested tới PH-04 (ADR 112). Nội dung sự kiện bất biến sau khi ghi; không chứa giá trị biến, dữ liệu biểu mẫu hay định danh cá nhân: CHECK chặn các khóa đó ở cấp cao nhất.';
COMMENT ON COLUMN ph11_bpm.outbox_event.status IS 'Trạng thái đẩy: PENDING chờ đẩy, SENT đã đẩy, FAILED quá lượt thử; OutboxStatus của FRS Phụ lục A.';
COMMENT ON COLUMN ph11_bpm.outbox_event.attempts IS 'Số lần đã đẩy lên Kafka.';
COMMENT ON COLUMN ph11_bpm.outbox_event.partition_key IS 'Khóa phân vùng Kafka: businessKey (mọi sự kiện tiến độ) hoặc processKey (EVT-11-01, 02).';
--rollback DROP TABLE IF EXISTS ph11_bpm.outbox_event CASCADE;

--changeset ph11:ph11-0710-inbox-message
CREATE TABLE ph11_bpm.inbox_message (
  tenant_id       varchar(16) NOT NULL,
  consumer        varchar(64) NOT NULL,
  message_id      varchar(255) NOT NULL,
  source          varchar(249) NOT NULL,
  event_type      varchar(255) NOT NULL,
  correlation_key varchar(120),
  business_key    varchar(100),
  payload         jsonb,
  status          varchar(12) NOT NULL DEFAULT 'RECEIVED',
  attempts        smallint NOT NULL DEFAULT 0,
  received_at     timestamptz NOT NULL DEFAULT now(),
  processed_at    timestamptz,
  expires_at      timestamptz,
  outcome         varchar(2000),
  CONSTRAINT pk_inbox_message PRIMARY KEY (tenant_id, consumer, message_id),
  CONSTRAINT ck_inbox_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_message_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_message_prefix CHECK (split_part(source, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_inbox_message_status CHECK (status IN ('RECEIVED', 'PROCESSED', 'UNCORRELATED', 'FAILED')),
  CONSTRAINT ck_inbox_message_processed CHECK ((status IN ('PROCESSED', 'FAILED')) = (processed_at IS NOT NULL)),
  CONSTRAINT ck_inbox_message_attempts CHECK (attempts BETWEEN 0 AND 20),
  CONSTRAINT ck_inbox_message_no_value CHECK (payload IS NULL OR NOT (payload ?| ARRAY['variables', 'formData', 'values', 'identifier', 'nationalId', 'fullName', 'dateOfBirth']))
);
CREATE INDEX ix_inbox_message_received ON ph11_bpm.inbox_message (received_at);
CREATE INDEX ix_inbox_message_waiting ON ph11_bpm.inbox_message (tenant_id, correlation_key) WHERE status = 'UNCORRELATED';
CALL ph11_bpm.p_enable_rls('ph11_bpm.inbox_message', 'P');
COMMENT ON TABLE ph11_bpm.inbox_message IS 'EN-11-22 Inbox chống xử lý trùng và giữ thông điệp chưa tương quan (at-least-once): kết quả service task từ PH-04 (EVT-11-18, 19), sự kiện khởi tạo, thông điệp từ PH-10 cho message catch (FR-11-019, 029, 030; BR-11-022). Khóa (consumer, message_id). Thông điệp đến trước khi phiên tới bước chờ giữ ở UNCORRELATED đến expires_at (11.message.bufferMinutes) rồi mở sự cố CORRELATION_FAILED.';
COMMENT ON COLUMN ph11_bpm.inbox_message.source IS 'Topic Kafka nguồn của thông điệp, tiền tố là tenant viết thường (FRS: source).';
COMMENT ON COLUMN ph11_bpm.inbox_message.status IS 'Trạng thái xử lý: RECEIVED, PROCESSED, UNCORRELATED (chờ phiên), FAILED; InboxStatus của FRS Phụ lục A.';
COMMENT ON COLUMN ph11_bpm.inbox_message.payload IS 'Nội dung đã lược; không chứa khóa biến, biểu mẫu, định danh cá nhân (CHECK). Dữ liệu cá nhân của thông điệp không được giữ ở đây.';
COMMENT ON COLUMN ph11_bpm.inbox_message.expires_at IS 'Hạn giữ khi UNCORRELATED; quá hạn không tương quan được thì mở sự cố.';
--rollback DROP TABLE IF EXISTS ph11_bpm.inbox_message CASCADE;

--changeset ph11:ph11-0720-shedlock
CREATE TABLE ph11_bpm.shedlock (
  name       varchar(64) NOT NULL,
  lock_until timestamptz NOT NULL,
  locked_at  timestamptz NOT NULL,
  locked_by  varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph11_bpm.shedlock IS 'Khóa tác vụ nền (DueScanner, TimerCatchUp, InboxReaper, OutboxCleaner, SagaReconciler, RetentionPurgeJob, PartitionMaintenanceJob, DelegationExpirer); bảng kỹ thuật của ShedLock, không có tenant_id. Bảng ngoài FRS Phụ lục A, hạ tầng.';
--rollback DROP TABLE IF EXISTS ph11_bpm.shedlock CASCADE;
