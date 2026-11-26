--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0080-messaging.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0800-inbound-event
CREATE TABLE ph15_portal.inbox_event (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  event_id            uuid          NOT NULL,
  event_code          varchar(10)   NOT NULL,
  topic               varchar(160)  NOT NULL,
  received_at         timestamptz   NOT NULL DEFAULT now(),
  processed_at        timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, event_id),
  CONSTRAINT ck_inbox_event_code CHECK (event_code ~ '^EVT-02-[0-9]{2}$')
);
CREATE INDEX ix_inbox_event_received ON ph15_portal.inbox_event (received_at);
CALL ph15_portal.p_enable_rls('ph15_portal.inbox_event');
COMMENT ON TABLE ph15_portal.inbox_event IS 'Hộp thư đến: ghi nhận sự kiện EVT-02-* của PH-02 đã xử lý để loại trùng (xử lý at-least-once, ADR-041). Giữ 7 ngày.';
--rollback DROP TABLE IF EXISTS ph15_portal.inbox_event CASCADE;

--changeset ph15:ph15-0810-outbox-event
CREATE TABLE ph15_portal.outbox_event (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  event_code          varchar(10)   NOT NULL,
  topic               varchar(160)  NOT NULL,
  message_key         varchar(128)  NOT NULL,
  aggregate_id        uuid,
  payload             jsonb         NOT NULL,
  trace_id            char(32),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  published_at        timestamptz,
  CONSTRAINT pk_outbox_event PRIMARY KEY (id),
  CONSTRAINT ck_outbox_event_code CHECK (event_code ~ '^EVT-15-(0[1-9]|1[0-4])$'),
  CONSTRAINT ck_outbox_event_topic CHECK (topic ~ '^t[0-9]{2}\.portal\.[a-z-]+\.[a-z-]+\.v1$'),
  CONSTRAINT ck_outbox_event_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_outbox_event_pending ON ph15_portal.outbox_event (created_at) WHERE published_at IS NULL;
CREATE INDEX ix_outbox_event_published ON ph15_portal.outbox_event (published_at) WHERE published_at IS NOT NULL;
CALL ph15_portal.p_enable_rls('ph15_portal.outbox_event');
COMMENT ON TABLE ph15_portal.outbox_event IS 'Hộp thư đi (outbox) cho EVT-15-01…14; Debezium EventRouter đọc WAL phát lên Kafka. Payload không chứa bí mật, thân yêu cầu hay dữ liệu cá nhân. Kiểm toán PH-13 cũng đi qua đây (BR-15-023).';
--rollback DROP TABLE IF EXISTS ph15_portal.outbox_event CASCADE;

--changeset ph15:ph15-0820-idempotency-record
CREATE TABLE ph15_portal.idempotency_record (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  key_hash            char(64)      NOT NULL,
  actor_id            varchar(64)   NOT NULL,
  request_hash        char(64)      NOT NULL,
  response_status     smallint      NOT NULL,
  resource_type       varchar(32),
  resource_id         uuid,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  expires_at          timestamptz   NOT NULL,
  CONSTRAINT pk_idempotency_record PRIMARY KEY (tenant_id, actor_id, key_hash),
  CONSTRAINT ck_idempotency_record_hash CHECK (key_hash ~ '^[0-9a-f]{64}$' AND request_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_idempotency_record_ttl CHECK (expires_at > created_at AND expires_at <= created_at + interval '24 hours' + interval '1 minute')
);
CREATE INDEX ix_idempotency_record_expiry ON ph15_portal.idempotency_record (expires_at);
CALL ph15_portal.p_enable_rls('ph15_portal.idempotency_record');
COMMENT ON TABLE ph15_portal.idempotency_record IS 'Lũy đẳng tầng bền cho thao tác ghi (ADR-041, BR-15-034). Cố ý không lưu thân phản hồi để bí mật sandbox vừa cấp không nằm lại ở CSDL (BR-15-011); lặp lại thì trả trạng thái và tham chiếu tài nguyên.';
--rollback DROP TABLE IF EXISTS ph15_portal.idempotency_record CASCADE;

--changeset ph15:ph15-0830-shedlock
CREATE TABLE ph15_portal.shedlock (
  name                varchar(64)   NOT NULL,
  lock_until          timestamptz   NOT NULL,
  locked_at           timestamptz   NOT NULL,
  locked_by           varchar(255)  NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph15_portal.shedlock IS 'Bảng kỹ thuật của ShedLock cho tác vụ định kỳ (kéo bù danh mục, đồng bộ Git, hết hạn thông tin xác thực, dọn dữ liệu); không RLS, không dữ liệu nghiệp vụ; tên khóa chứa mã tenant.';
--rollback DROP TABLE IF EXISTS ph15_portal.shedlock;
