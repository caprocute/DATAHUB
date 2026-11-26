-- =============================================================================
-- D03-03-PH01 · Tệp 50: bảng hạ tầng: outbox (DD-11), hộp nhận, hàng đợi thông báo, lũy đẳng, ShedLock.
-- Chạy sau ph01_40_review_cycle.sql.
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0050-infra.sql
-- @changeset ph01-0500-outbox
CREATE TABLE ph01_onboarding.outbox (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(64)   NOT NULL,
  aggregate_id     varchar(64)   NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  relayed_at       timestamptz,
  CONSTRAINT pk_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_type CHECK (event_type ~ '^vn\.datahub\.connect\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic CHECK (topic ~ '^t[0-9]{2}\.(connect|audit)\.[a-z-]+(\.[a-z-]+)?\.v[0-9]+$'),
  CONSTRAINT ck_outbox_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_outbox_no_secret CHECK (NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'secretRef', 'secret_ref', 'linkToken'])),
  CONSTRAINT ck_outbox_no_pii CHECK (NOT (payload ?| ARRAY['email', 'phone', 'fullName', 'full_name', 'contactEmail', 'contactPhone']))
);
CREATE INDEX ix_outbox_pending ON ph01_onboarding.outbox (occurred_at) WHERE relayed_at IS NULL;
CREATE INDEX ix_outbox_occurred ON ph01_onboarding.outbox (occurred_at);
ALTER TABLE ph01_onboarding.outbox SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.outbox', 'P');
COMMENT ON TABLE ph01_onboarding.outbox IS 'Outbox (DD-11) cho EVT-01-01…15 và bản ghi kiểm toán gửi PH-13, ghi cùng giao dịch với thay đổi (BR-01-031, ADR-042). Debezium Outbox Event Router đọc WAL (QM-VUA, QM-LON); OutboxRelay dự phòng đánh dấu relayed_at (QM-NHO). Dọn sau 7 ngày. Không bí mật, không secret_ref, không dữ liệu liên hệ cá nhân.';
COMMENT ON COLUMN ph01_onboarding.outbox.aggregate_id IS 'Khóa bản ghi Kafka: mã HTTT (systemCode) để giữ thứ tự theo HTTT (NFR-01-021); với sự kiện cấp kỳ rà soát là mã kỳ.';
COMMENT ON COLUMN ph01_onboarding.outbox.topic IS 'Dạng t{nn}.connect.{thực-thể}.{sự-kiện}.v{n}, chữ thường, tiền tố bằng mã tenant (D00-04 §4, SEC-82); kiểm toán dùng miền audit.';
COMMENT ON COLUMN ph01_onboarding.outbox.relayed_at IS 'Thời điểm OutboxRelay đã phát (chỉ dùng ở đường dự phòng); NULL với Debezium vì WAL không cần cờ.';
COMMENT ON COLUMN ph01_onboarding.outbox.event_id IS 'UUID v7 (thứ tự theo thời gian, tương đương vai trò ULID của SDD §4.11).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.outbox CASCADE;

-- @changeset ph01-0510-inbox
CREATE TABLE ph01_onboarding.inbox (
  tenant_id     varchar(16)   NOT NULL,
  event_id      varchar(64)   NOT NULL,
  source        varchar(8)    NOT NULL,
  event_type    varchar(128)  NOT NULL,
  status        varchar(9)    NOT NULL DEFAULT 'RECEIVED',
  attempts      smallint      NOT NULL DEFAULT 0,
  last_error    varchar(1000),
  received_at   timestamptz   NOT NULL DEFAULT now(),
  processed_at  timestamptz,
  CONSTRAINT pk_inbox PRIMARY KEY (tenant_id, event_id),
  CONSTRAINT ck_inbox_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_source CHECK (source IN ('PH12', 'PH18', 'PH20')),
  CONSTRAINT ck_inbox_status CHECK (status IN ('RECEIVED', 'PROCESSED', 'FAILED', 'DEAD')),
  CONSTRAINT ck_inbox_processed CHECK ((status = 'PROCESSED') = (processed_at IS NOT NULL)),
  CONSTRAINT ck_inbox_attempts CHECK (attempts >= 0)
);
CREATE INDEX ix_inbox_retention ON ph01_onboarding.inbox (received_at);
CREATE INDEX ix_inbox_failed ON ph01_onboarding.inbox (tenant_id, received_at) WHERE status IN ('FAILED', 'DEAD');
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.inbox', 'P');
COMMENT ON TABLE ph01_onboarding.inbox IS 'Hộp nhận: sự kiện vào từ PH-12 (tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức), PH-18 (thư bị trả lại), PH-20 (tenant tạm ngừng) xử lý lũy đẳng theo event_id; lỗi ba lần thì DEAD, chuyển hàng đợi lỗi của PH-18. Giữ 30 ngày.';
COMMENT ON COLUMN ph01_onboarding.inbox.event_id IS 'Mã sự kiện do bên phát đặt (ULID hoặc UUID), duy nhất trong tenant.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.inbox CASCADE;

-- @changeset ph01-0520-notify-outbox
CREATE TABLE ph01_onboarding.notify_outbox (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  kind            varchar(6)    NOT NULL,
  template_code   varchar(64)   NOT NULL,
  recipient_type  varchar(8)    NOT NULL,
  recipient_ref   varchar(128)  NOT NULL,
  payload         jsonb         NOT NULL DEFAULT '{}',
  dedupe_key      varchar(128),
  status          varchar(7)    NOT NULL DEFAULT 'PENDING',
  attempt         integer       NOT NULL DEFAULT 0,
  next_run_at     timestamptz   NOT NULL DEFAULT now(),
  deadline_at     timestamptz   NOT NULL,
  sent_at         timestamptz,
  last_error      varchar(1000),
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      varchar(64)   NOT NULL,
  CONSTRAINT pk_notify_outbox PRIMARY KEY (id),
  CONSTRAINT uq_notify_outbox_dedupe UNIQUE (tenant_id, dedupe_key),
  CONSTRAINT ck_notify_outbox_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_notify_outbox_kind CHECK (kind IN ('NOTIFY', 'TASK')),
  CONSTRAINT ck_notify_outbox_recipient CHECK (recipient_type IN ('USER', 'ROLE', 'CONTACT', 'ORG_ROLE')),
  CONSTRAINT ck_notify_outbox_status CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'DEAD')),
  CONSTRAINT ck_notify_outbox_sent CHECK ((status = 'SENT') = (sent_at IS NOT NULL)),
  CONSTRAINT ck_notify_outbox_deadline CHECK (deadline_at > created_at AND deadline_at <= created_at + interval '24 hours'),
  CONSTRAINT ck_notify_outbox_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_notify_outbox_no_secret CHECK (NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'link', 'linkToken', 'handoverLink', 'confirmLink'])),
  CONSTRAINT ck_notify_outbox_no_link CHECK (payload::text !~ '/(ban-giao|xac-nhan)/[A-Za-z0-9_-]{20,}')
);
CREATE INDEX ix_notify_outbox_due ON ph01_onboarding.notify_outbox (tenant_id, next_run_at) WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX ix_notify_outbox_retention ON ph01_onboarding.notify_outbox (created_at);
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.notify_outbox', 'P');
COMMENT ON TABLE ph01_onboarding.notify_outbox IS 'Hàng đợi thông báo và việc cho hộp việc của PH-18, thử lại tới 24 giờ để lỗi PH-18 không làm hỏng giao dịch nghiệp vụ (SDD §8.2). Không chứa liên kết bàn giao hay phiếu xác nhận: thư mang liên kết gửi trực tiếp qua NotifyPort, lỗi thì tạo lại liên kết (Q01-52).';
COMMENT ON COLUMN ph01_onboarding.notify_outbox.recipient_ref IS 'Mã người dùng, mã vai trò, hoặc id đầu mối (CONTACT) để PH-18 tự tra thư điện tử; không sao chép thư, số điện thoại vào bảng này.';
COMMENT ON COLUMN ph01_onboarding.notify_outbox.dedupe_key IS 'Khóa chống gửi trùng nhắc việc, ví dụ expiring:{credentialId}:30; duy nhất trong tenant khi khác NULL.';
COMMENT ON COLUMN ph01_onboarding.notify_outbox.payload IS 'Tham số điền mẫu thông báo; ràng buộc chặn khóa bí mật, liên kết và đường dẫn chứa mã (ck_notify_outbox_no_secret, ck_notify_outbox_no_link; giả định đường dẫn dạng /ban-giao/{mã}, /xac-nhan/{mã}).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.notify_outbox CASCADE;

-- @changeset ph01-0530-idempotency
CREATE TABLE ph01_onboarding.idempotency_record (
  tenant_id         varchar(16)   NOT NULL,
  client_id         varchar(255)  NOT NULL,
  request_method    varchar(8)    NOT NULL,
  request_path      varchar(512)  NOT NULL,
  idempotency_key   varchar(64)   NOT NULL,
  request_hash      char(64)      NOT NULL,
  state             varchar(12)   NOT NULL DEFAULT 'IN_PROGRESS',
  resource_id       uuid,
  response_status   smallint,
  response_body     jsonb,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  completed_at      timestamptz,
  expires_at        timestamptz   NOT NULL,
  CONSTRAINT pk_idempotency_record PRIMARY KEY (tenant_id, client_id, request_method, request_path, idempotency_key),
  CONSTRAINT ck_idempotency_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_idempotency_record_method CHECK (request_method IN ('POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_idempotency_record_key CHECK (idempotency_key ~ '^[A-Za-z0-9_-]{16,64}$'),
  CONSTRAINT ck_idempotency_record_hash CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_idempotency_record_state CHECK (state IN ('IN_PROGRESS', 'COMPLETED')),
  CONSTRAINT ck_idempotency_record_done CHECK (state = 'IN_PROGRESS' OR (response_status IS NOT NULL AND completed_at IS NOT NULL)),
  CONSTRAINT ck_idempotency_record_ttl CHECK (expires_at > created_at AND expires_at <= created_at + interval '24 hours'),
  CONSTRAINT ck_idempotency_record_no_open CHECK (request_path !~ 'handovers[:/]open'),
  CONSTRAINT ck_idempotency_record_no_secret CHECK (response_body IS NULL OR NOT (response_body ?| ARRAY['clientSecret', 'secret', 'password', 'apiKey', 'token', 'privateKey']))
);
CREATE INDEX ix_idempotency_record_expiry ON ph01_onboarding.idempotency_record (expires_at);
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.idempotency_record', 'P');
COMMENT ON TABLE ph01_onboarding.idempotency_record IS 'Kết quả yêu cầu ghi có Idempotency-Key bắt buộc; cùng khóa cùng thân trả lại phản hồi đã lưu, khác thân thì ERR-01-051 (type idempotency-mismatch), đang xử lý thì ERR-01-054; giữ 24 giờ (ADR-041, SDD §8.2). Không bao giờ lưu phản hồi mở bàn giao có chứa bí mật.';
COMMENT ON COLUMN ph01_onboarding.idempotency_record.request_hash IS 'SHA-256 thân yêu cầu chuẩn hóa JCS (RFC 8785).';
COMMENT ON COLUMN ph01_onboarding.idempotency_record.request_path IS 'Đường dẫn đã chuẩn hóa; ck_idempotency_record_no_open chặn lưu tuyến handovers:open vì phản hồi chứa bí mật (BR-01-007, NFR-01-009).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.idempotency_record CASCADE;

-- @changeset ph01-0540-shedlock
CREATE TABLE ph01_onboarding.shedlock (
  name        varchar(64)  NOT NULL,
  lock_until  timestamptz  NOT NULL,
  locked_at   timestamptz  NOT NULL,
  locked_by   varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph01_onboarding.shedlock IS 'Khóa tác vụ định kỳ (DraftCleaner, EscalationJob, EmergencyConfirmationJob, ExpiryJob, InactivityJob, AccessReviewScheduler, LegalValidityChecker, GapDetector, SnapshotPublisher, retention); bảng kỹ thuật của ShedLock, không có tenant_id. Bộ chạy saga và cắt quyền dùng SKIP LOCKED nên không cần khóa này.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.shedlock;
