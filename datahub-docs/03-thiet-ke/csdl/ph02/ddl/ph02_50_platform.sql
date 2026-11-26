-- =============================================================================
-- D03-03-PH02 · Tệp 50: bảng nền tảng — tác vụ bất đồng bộ, lệnh chờ thử lại,
-- hộp nhận, hộp gửi, lũy đẳng, khóa tác vụ định kỳ, di trú từ APIM cũ
-- Chạy sau ph02_40_publish_sla_sync.sql (cùng phiên, đang SET ROLE ph02_owner).
-- =============================================================================

-- @file 02-0050-platform.sql
-- @changeset ph02-0600-async-operation
CREATE TABLE ph02_catalog.async_operation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kind             varchar(22)   NOT NULL,
  subject_kind     varchar(12),
  subject_id       uuid,
  status           varchar(9)    NOT NULL DEFAULT 'QUEUED',
  progress         smallint      NOT NULL DEFAULT 0,
  result           jsonb,
  error_code       varchar(16),
  requested_by     varchar(64)   NOT NULL,
  started_at       timestamptz,
  finished_at      timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_async_operation PRIMARY KEY (id),
  CONSTRAINT ck_async_operation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_async_operation_kind CHECK (kind IN ('ROUTE_SKELETON', 'DIFF', 'LEGACY_IMPORT_COMMIT', 'SPEC_REFRESH', 'IMPACT_ANALYSIS')),
  CONSTRAINT ck_async_operation_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_async_operation_progress CHECK (progress BETWEEN 0 AND 100),
  CONSTRAINT ck_async_operation_finished CHECK ((status IN ('SUCCEEDED', 'FAILED', 'CANCELLED')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_async_operation_error CHECK (status <> 'FAILED' OR error_code IS NOT NULL)
);
CREATE INDEX ix_async_operation_user ON ph02_catalog.async_operation (tenant_id, requested_by, created_at DESC);
CREATE INDEX ix_async_operation_open ON ph02_catalog.async_operation (tenant_id, kind) WHERE status IN ('QUEUED', 'RUNNING');
CREATE TRIGGER tg_async_operation_touch BEFORE UPDATE ON ph02_catalog.async_operation FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.async_operation', 'P');
COMMENT ON TABLE ph02_catalog.async_operation IS 'Thao tác bất đồng bộ có tiến độ theo FR-00-054: sinh khung route (FR-02-026), so sánh đặc tả lớn (FR-02-043), nhập hệ cũ (FR-02-061), đồng bộ lại đặc tả từ URL (FR-02-012). Giữ 30 ngày, dọn bằng tác vụ định kỳ (giả định).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.async_operation CASCADE;

-- @changeset ph02-0610-pending-command
CREATE TABLE ph02_catalog.pending_command (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  target           varchar(14)   NOT NULL,
  command          varchar(48)   NOT NULL,
  payload          jsonb         NOT NULL,
  idempotency_key  varchar(128)  NOT NULL,
  status           varchar(7)    NOT NULL DEFAULT 'PENDING',
  attempts         smallint      NOT NULL DEFAULT 0,
  next_attempt_at  timestamptz   NOT NULL DEFAULT now(),
  last_error_code  varchar(16),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_pending_command PRIMARY KEY (id),
  CONSTRAINT uq_pending_command UNIQUE (tenant_id, target, idempotency_key),
  CONSTRAINT ck_pending_command_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_pending_command_target CHECK (target IN ('PH04_FLOW', 'PH05_CONN', 'PH12_SCOPE', 'PH14_NATIONAL', 'PH18_NOTICE')),
  CONSTRAINT ck_pending_command_status CHECK (status IN ('PENDING', 'DONE', 'DEAD')),
  CONSTRAINT ck_pending_command_payload CHECK (jsonb_typeof(payload) = 'object' AND NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey']))
);
CREATE INDEX ix_pending_command_due ON ph02_catalog.pending_command (next_attempt_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_pending_command_touch BEFORE UPDATE ON ph02_catalog.pending_command FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.pending_command', 'P');
COMMENT ON TABLE ph02_catalog.pending_command IS 'Lệnh gọi phân hệ ngoài chờ thử lại lùi dần khi đích ngừng (SDD 4.15, ERR-02-034): tạo khung luồng ở PH-04, gắn phạm vi ở PH-12, thông báo PH-18. Khóa lũy đẳng duy nhất theo (đích, khóa) nên xếp hàng lặp lại vô hại. Không chứa bí mật (ck_pending_command_payload). Dòng DONE dọn sau 7 ngày, DEAD giữ 90 ngày để điều tra (giả định).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.pending_command CASCADE;

-- @changeset ph02-0620-inbox-event
CREATE TABLE ph02_catalog.inbox_event (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  source           varchar(8)    NOT NULL,
  event_type       varchar(128)  NOT NULL,
  received_at      timestamptz   NOT NULL DEFAULT now(),
  processed_at     timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_event_source CHECK (source IN ('PH01', 'PH04', 'PH10', 'PH12'))
);
CREATE INDEX ix_inbox_event_received ON ph02_catalog.inbox_event (received_at);
CALL ph02_catalog.p_enable_rls('ph02_catalog.inbox_event', 'P');
COMMENT ON TABLE ph02_catalog.inbox_event IS 'Hộp nhận: ghi event_id trước khi xử lý sự kiện của PH-01, PH-04, PH-10 để sự kiện phát lại không tạo hiệu ứng thứ hai (SDD 8.2). Khóa là mã sự kiện, không có id riêng. Dọn sau 7 ngày (giả định, dài hơn thời gian giữ topic).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.inbox_event CASCADE;

-- @changeset ph02-0630-outbox-event
CREATE TABLE ph02_catalog.outbox_event (
  event_id         uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  event_type       varchar(128)  NOT NULL,
  topic            varchar(249)  NOT NULL,
  aggregate_type   varchar(32)   NOT NULL,
  aggregate_id     varchar(128)  NOT NULL,
  partition_key    varchar(128)  NOT NULL,
  payload          jsonb         NOT NULL,
  trace_id         char(32)      NOT NULL,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  published_at     timestamptz,
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_type CHECK (event_type ~ '^vn\.datahub\.catalog\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_event_topic CHECK (topic ~ '^t[0-9]{2}\.catalog\.[a-z-]+\.[a-z-]+\.v[0-9]+$'),
  CONSTRAINT ck_outbox_event_topic_tenant CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_outbox_event_no_secret CHECK (NOT (payload ?| ARRAY['password', 'secret', 'clientSecret', 'apiKey', 'token', 'privateKey', 'specContent', 'openapi']))
);
CREATE INDEX ix_outbox_event_unpublished ON ph02_catalog.outbox_event (occurred_at) WHERE published_at IS NULL;
CREATE INDEX ix_outbox_event_published ON ph02_catalog.outbox_event (published_at) WHERE published_at IS NOT NULL;
ALTER TABLE ph02_catalog.outbox_event SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000);
CALL ph02_catalog.p_enable_rls('ph02_catalog.outbox_event', 'P');
COMMENT ON TABLE ph02_catalog.outbox_event IS 'Hộp gửi (DD-11, ADR-042) cho EVT-02-01…16: ghi cùng giao dịch với thay đổi gốc, Debezium outbox router hoặc OutboxPublisher quét 500 ms đưa lên Kafka kèm tiêu đề CloudEvents. Topic {tenant}.catalog.{thực-thể}.{sự-kiện}.v1 đúng tenant; khóa phân vùng là apiCode để sự kiện của một API đến theo thứ tự. Không chứa nội dung đặc tả, dữ liệu cá nhân hay bí mật, chỉ mã định danh và trường thay đổi. Dọn dòng đã phát sau 3 ngày; cảnh báo khi dòng chưa phát cũ nhất quá 5 phút.';
COMMENT ON COLUMN ph02_catalog.outbox_event.partition_key IS 'apiCode (hoặc mã đối tượng) làm khóa phân vùng Kafka.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.outbox_event CASCADE;

-- @changeset ph02-0640-idempotency-record
CREATE TABLE ph02_catalog.idempotency_record (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  principal        varchar(64)   NOT NULL,
  idem_key         varchar(128)  NOT NULL,
  request_hash     char(64)      NOT NULL,
  response_status  smallint,
  response_body    jsonb,
  expires_at       timestamptz   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_idempotency_record PRIMARY KEY (id),
  CONSTRAINT uq_idempotency_record UNIQUE (tenant_id, principal, idem_key),
  CONSTRAINT ck_idempotency_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_idempotency_record_hash CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_idempotency_record_status CHECK (response_status IS NULL OR response_status BETWEEN 200 AND 599),
  CONSTRAINT ck_idempotency_record_ttl CHECK (expires_at > created_at AND expires_at <= created_at + interval '48 hours')
);
CREATE INDEX ix_idempotency_record_expiry ON ph02_catalog.idempotency_record (expires_at);
CALL ph02_catalog.p_enable_rls('ph02_catalog.idempotency_record', 'P');
COMMENT ON TABLE ph02_catalog.idempotency_record IS 'Lũy đẳng của lệnh POST đổi trạng thái (SDD 8.5): ghi (tenant, người, khóa) kèm băm yêu cầu và phản hồi trong 24 giờ ở cùng giao dịch với tác dụng. Cùng khóa cùng thân trả lại phản hồi cũ; cùng khóa khác băm thì ERR-02-042 (422). Chỉ dùng PostgreSQL, không cần Valkey vì tần suất lệnh thấp. Dọn khi quá expires_at.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.idempotency_record CASCADE;

-- @changeset ph02-0650-job-lease
CREATE TABLE ph02_catalog.job_lease (
  name             varchar(64)   NOT NULL,
  lock_until       timestamptz   NOT NULL,
  locked_at        timestamptz   NOT NULL,
  locked_by        varchar(255)  NOT NULL,
  CONSTRAINT pk_job_lease PRIMARY KEY (name)
);
COMMENT ON TABLE ph02_catalog.job_lease IS 'Bảng kỹ thuật của ShedLock cho tác vụ định kỳ của vai trò worker (RetireWatcher, SuspensionWatcher, SyncScheduler, OverdueWatcher, SlaEvaluator, DriftReconciler, RenewalScheduler, dọn dữ liệu). Không có tenant_id, không chứa dữ liệu nghiệp vụ; tác vụ liên tenant lặp từng tenant bên trong khóa. Tên cột theo cấu hình ShedLock JDBC.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.job_lease CASCADE;

-- @changeset ph02-0660-import-session
CREATE TABLE ph02_catalog.import_session (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  file_name        varchar(255)  NOT NULL,
  file_sha256      char(64)      NOT NULL,
  size_bytes       integer       NOT NULL,
  plan_object_key  varchar(512),
  report_object_key varchar(512),
  application_map  jsonb         NOT NULL DEFAULT '{}',
  counts           jsonb         NOT NULL DEFAULT '{}',
  checksum         char(64),
  status           varchar(10)   NOT NULL DEFAULT 'UPLOADED',
  expires_at       timestamptz   NOT NULL,
  started_by       varchar(64)   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_import_session PRIMARY KEY (id),
  CONSTRAINT ck_import_session_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_import_session_sha CHECK (file_sha256 ~ '^[0-9a-f]{64}$' AND (checksum IS NULL OR checksum ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_import_session_size CHECK (size_bytes BETWEEN 1 AND 52428800),
  CONSTRAINT ck_import_session_status CHECK (status IN ('UPLOADED', 'PREVIEWED', 'COMMITTING', 'DONE', 'PARTIAL', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_import_session_json CHECK (jsonb_typeof(application_map) = 'object' AND jsonb_typeof(counts) = 'object'),
  CONSTRAINT ck_import_session_report CHECK (status NOT IN ('DONE', 'PARTIAL') OR checksum IS NOT NULL)
);
CREATE INDEX ix_import_session_user ON ph02_catalog.import_session (tenant_id, started_by, created_at DESC);
CREATE INDEX ix_import_session_expiry ON ph02_catalog.import_session (expires_at) WHERE status IN ('UPLOADED', 'PREVIEWED');
CREATE UNIQUE INDEX uq_import_session_one_committing ON ph02_catalog.import_session (tenant_id) WHERE status = 'COMMITTING';
CREATE TRIGGER tg_import_session_touch BEFORE UPDATE ON ph02_catalog.import_session FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.import_session', 'P');
COMMENT ON TABLE ph02_catalog.import_session IS 'Phiên nhập từ APIM cũ (FR-02-061, API-02-085…087): tệp xuất tải lên được quét mã độc, giới hạn 50 MiB, xử lý như đầu vào không tin cậy; kế hoạch ánh xạ ở kho đối tượng legacy/, hạn 24 giờ; khóa và bí mật của hệ cũ không bao giờ được đọc vào mô hình (BR-02-036). Mỗi tenant chỉ một lần nhập đang ghi (ERR-02-035). checksum là SHA-256 danh sách (legacyId, kết quả) đã sắp xếp, hai lần nhập cùng dữ liệu cho cùng tổng kiểm tra (FR-00-092).';
COMMENT ON COLUMN ph02_catalog.import_session.application_map IS 'Ánh xạ Application của APIM cũ sang mã HTTT ở PH-01: {"app-id-cu":"MA_HTTT"}; HTTT không ACTIVE bị từ chối (ERR-02-004).';
COMMENT ON COLUMN ph02_catalog.import_session.counts IS 'Số lượng ở nguồn và đã nhập theo loại: {"api":{"source":n,"imported":n},"plan":{…},"subscription":{…},"secretRemoved":n}.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.import_session CASCADE;

-- @changeset ph02-0670-legacy-id-map
CREATE TABLE ph02_catalog.legacy_id_map (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  session_id       uuid          NOT NULL,
  entity_kind      varchar(12)   NOT NULL,
  legacy_id        varchar(128)  NOT NULL,
  new_id           uuid,
  result           varchar(8)    NOT NULL,
  note             varchar(500),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_legacy_id_map PRIMARY KEY (id),
  CONSTRAINT fk_legacy_id_map_session FOREIGN KEY (session_id) REFERENCES ph02_catalog.import_session (id),
  CONSTRAINT ck_legacy_id_map_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legacy_id_map_kind CHECK (entity_kind IN ('API', 'PLAN', 'SUBSCRIPTION', 'BACKEND')),
  CONSTRAINT ck_legacy_id_map_result CHECK (result IN ('IMPORTED', 'SKIPPED', 'FAILED')),
  CONSTRAINT ck_legacy_id_map_new CHECK ((result = 'IMPORTED') = (new_id IS NOT NULL))
);
CREATE UNIQUE INDEX uq_legacy_id_map_imported ON ph02_catalog.legacy_id_map (tenant_id, entity_kind, legacy_id) WHERE result = 'IMPORTED';
CREATE INDEX ix_legacy_id_map_session ON ph02_catalog.legacy_id_map (tenant_id, session_id);
CREATE INDEX ix_legacy_id_map_new ON ph02_catalog.legacy_id_map (tenant_id, new_id) WHERE new_id IS NOT NULL;
CREATE TRIGGER tg_legacy_id_map_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.legacy_id_map FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.legacy_id_map', 'P');
COMMENT ON TABLE ph02_catalog.legacy_id_map IS 'Ánh xạ định danh APIM cũ sang đối tượng mới, theo từng lần nhập (FR-02-061, FR-00-092). Khóa duy nhất từng phần (tenant, loại, mã cũ) cho kết quả IMPORTED làm cho nhập lại lũy đẳng, một API lỗi không kéo cả đợt (mỗi API một giao dịch); kết quả SKIPPED, FAILED kèm lý do để báo cáo đối chiếu. Giữ vĩnh viễn làm bằng chứng di trú, đầu vào của đối soát D06-01. Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.legacy_id_map CASCADE;
