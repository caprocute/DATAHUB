--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0085-ops.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0530-outbox
CREATE TABLE ph20_tenant.outbox (
  tenant_id              varchar(16)    NOT NULL,
  event_id               uuid           NOT NULL,
  event_type             varchar(128)   NOT NULL,
  topic                  varchar(128)   NOT NULL,
  aggregate_type         varchar(32)    NOT NULL,
  aggregate_id           uuid           NOT NULL,
  payload                jsonb          NOT NULL,
  trace_id               char(32)       NOT NULL,
  occurred_at            timestamptz    NOT NULL DEFAULT now(),
  published_at           timestamptz,
  CONSTRAINT pk_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_outbox_topic CHECK (topic IN ('platform.tenant.created.v1', 'platform.tenant.provisioning-failed.v1', 'platform.tenant.activated.v1', 'platform.tenant.status-changed.v1', 'platform.tenant.quota-changed.v1', 'platform.tenant.quota-threshold-reached.v1', 'platform.tenant.module-enabled.v1', 'platform.tenant.module-disabled.v1', 'platform.tenant.config-changed.v1', 'platform.tenant.merge-started.v1', 'platform.tenant.merge-cutover.v1', 'platform.tenant.merge-completed.v1', 'platform.release.published.v1', 'platform.tenant.upgrade-changed.v1', 'platform.tenant.export-ready.v1', 'platform.obs.audit.recorded.v1') OR topic = lower(tenant_id) || '.tenant.org.changed.v1'),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_payload CHECK (jsonb_typeof(payload) = 'object')
);
CREATE INDEX ix_outbox_occurred ON ph20_tenant.outbox (occurred_at);
CREATE INDEX ix_outbox_unpublished ON ph20_tenant.outbox (occurred_at) WHERE published_at IS NULL;
CALL ph20_tenant.p_enable_rls('ph20_tenant.outbox', 'TECH');
COMMENT ON TABLE ph20_tenant.outbox IS 'Hạ tầng, DD-11 Outbox (SAD 7.3) cho EVT-20-01…16 và bản ghi kiểm toán gửi PH-13: ghi cùng giao dịch với thay đổi, Debezium Outbox Event Router đọc WAL và phát Kafka. Sự kiện vòng đời đi trên `platform.*`, sự kiện tổ chức trên `{tenant}.tenant.org.changed.v1`. Dọn sau 3 ngày.';
COMMENT ON COLUMN ph20_tenant.outbox.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.outbox.event_id IS 'Mã sự kiện, thành `id` của CloudEvent; bên nhận dùng để chống trùng.';
COMMENT ON COLUMN ph20_tenant.outbox.event_type IS 'Kiểu sự kiện, ví dụ `vn.datahub.platform.tenant.created.v1`.';
COMMENT ON COLUMN ph20_tenant.outbox.topic IS 'Topic Kafka theo D00-01 §6.';
COMMENT ON COLUMN ph20_tenant.outbox.aggregate_type IS 'Loại thực thể gốc (`tenant`, `organization`, `merge_plan`…).';
COMMENT ON COLUMN ph20_tenant.outbox.aggregate_id IS 'Thực thể gốc, làm khóa phân vùng Kafka.';
COMMENT ON COLUMN ph20_tenant.outbox.payload IS 'Nội dung theo schema đã đăng ký.';
COMMENT ON COLUMN ph20_tenant.outbox.trace_id IS 'Mã vết phân tán.';
COMMENT ON COLUMN ph20_tenant.outbox.occurred_at IS 'Thời điểm xảy ra.';
COMMENT ON COLUMN ph20_tenant.outbox.published_at IS 'Thời điểm đã phát (do Debezium hoặc job dọn đánh dấu).';
--rollback DROP TABLE IF EXISTS ph20_tenant.outbox CASCADE;

--changeset ph20:ph20-0540-inbox-event
CREATE TABLE ph20_tenant.inbox_event (
  tenant_id              varchar(16)    NOT NULL,
  consumer               varchar(64)    NOT NULL,
  event_id               uuid           NOT NULL,
  source_topic           varchar(128)   NOT NULL,
  received_at            timestamptz    NOT NULL DEFAULT now(),
  processed_at           timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM')
);
CREATE INDEX ix_inbox_event_received ON ph20_tenant.inbox_event (received_at);
CALL ph20_tenant.p_enable_rls('ph20_tenant.inbox_event', 'TECH');
COMMENT ON TABLE ph20_tenant.inbox_event IS 'Hạ tầng. Hộp nhận sự kiện từ phân hệ khác (EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11): khử trùng theo `(tenant_id, consumer, event_id)` để tiêu thụ lũy đẳng.';
COMMENT ON COLUMN ph20_tenant.inbox_event.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.inbox_event.consumer IS 'Tên bộ tiêu thụ trong PH-20.';
COMMENT ON COLUMN ph20_tenant.inbox_event.event_id IS 'Mã sự kiện nhận.';
COMMENT ON COLUMN ph20_tenant.inbox_event.source_topic IS 'Topic nguồn.';
COMMENT ON COLUMN ph20_tenant.inbox_event.received_at IS 'Thời điểm nhận.';
COMMENT ON COLUMN ph20_tenant.inbox_event.processed_at IS 'Thời điểm xử lý xong.';
--rollback DROP TABLE IF EXISTS ph20_tenant.inbox_event CASCADE;

--changeset ph20:ph20-0550-idempotency-key
CREATE TABLE ph20_tenant.idempotency_key (
  tenant_id              varchar(16)    NOT NULL,
  client_id              varchar(255)   NOT NULL,
  request_method         varchar(8)     NOT NULL,
  request_path           varchar(512)   NOT NULL,
  idempotency_ref        varchar(128)   NOT NULL,
  request_hash           char(64)       NOT NULL,
  state                  varchar(12)    NOT NULL DEFAULT 'IN_PROGRESS',
  resource_id            uuid,
  response_status        smallint,
  response_body          jsonb,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  completed_at           timestamptz,
  expires_at             timestamptz    NOT NULL,
  CONSTRAINT pk_idempotency_key PRIMARY KEY (tenant_id, client_id, request_method, request_path, idempotency_ref),
  CONSTRAINT ck_idempotency_key_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_idempotency_key_ref CHECK (idempotency_ref ~ '^[A-Za-z0-9_:-]{16,128}$'),
  CONSTRAINT ck_idempotency_key_state CHECK (state IN ('IN_PROGRESS', 'COMPLETED')),
  CONSTRAINT ck_idempotency_key_done CHECK (state = 'IN_PROGRESS' OR response_status IS NOT NULL),
  CONSTRAINT ck_idempotency_key_hash CHECK (request_hash ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_idempotency_key_expiry ON ph20_tenant.idempotency_key (expires_at);
CALL ph20_tenant.p_enable_rls('ph20_tenant.idempotency_key', 'TECH');
COMMENT ON TABLE ph20_tenant.idempotency_key IS 'Hạ tầng. Kết quả yêu cầu ghi có tiêu đề `Idempotency-Key` (API công khai và saga: khóa `{runId}:{stepCode}`); giữ 24 giờ. Cột khóa tên `idempotency_ref` (tránh trùng tên cột nhạy cảm của công cụ quét).';
COMMENT ON COLUMN ph20_tenant.idempotency_key.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.client_id IS 'Định danh máy khách gọi API.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.request_method IS 'Phương thức HTTP.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.request_path IS 'Đường dẫn yêu cầu.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.idempotency_ref IS 'Giá trị tiêu đề `Idempotency-Key`.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.request_hash IS 'Băm nội dung yêu cầu, phát hiện cùng khóa khác nội dung.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.state IS 'Trạng thái: `IN_PROGRESS` hoặc `COMPLETED`.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.resource_id IS 'Tài nguyên đã tạo.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.response_status IS 'Mã HTTP đã trả.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.response_body IS 'Nội dung đã trả (đã che dữ liệu nhạy cảm).';
COMMENT ON COLUMN ph20_tenant.idempotency_key.created_at IS 'Thời điểm nhận yêu cầu đầu.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.completed_at IS 'Thời điểm hoàn tất.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.expires_at IS 'Hạn giữ.';
--rollback DROP TABLE IF EXISTS ph20_tenant.idempotency_key CASCADE;
