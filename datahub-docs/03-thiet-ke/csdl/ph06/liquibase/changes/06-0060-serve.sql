--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0060-serve.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0390-update-subscription
CREATE TABLE ph06_mdm.update_subscription (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  system_code            varchar(63) NOT NULL,
  domain_code            varchar(32) NOT NULL,
  scope                  varchar(16) NOT NULL,
  event_types            varchar(32)[] NOT NULL,
  delivery               varchar(4) NOT NULL,
  purpose_code           varchar(63) NOT NULL,
  status                 varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  ph10_subscription_code varchar(63),
  requested_by           varchar(64) NOT NULL,
  approved_by            varchar(64),
  approved_at            timestamptz,
  status_reason          varchar(2000),
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_update_subscription PRIMARY KEY (id),
  CONSTRAINT ck_update_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_update_subscription_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_update_subscription_scope CHECK (scope IN ('LINKED_ONLY', 'DOMAIN')),
  CONSTRAINT ck_update_subscription_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
  CONSTRAINT ck_update_subscription_delivery CHECK (delivery IN ('PUSH', 'PULL')),
  CONSTRAINT ck_update_subscription_events CHECK (cardinality(event_types) >= 1),
  CONSTRAINT ck_update_subscription_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_update_subscription_active CHECK (status NOT IN ('ACTIVE') OR approved_by IS NOT NULL)
);
CREATE UNIQUE INDEX uq_update_subscription_live ON ph06_mdm.update_subscription (tenant_id, system_code, domain_code, scope) WHERE status <> 'REVOKED';
CREATE TRIGGER tg_update_subscription_touch BEFORE UPDATE ON ph06_mdm.update_subscription FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_update_subscription_immutable BEFORE UPDATE ON ph06_mdm.update_subscription FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('system_code', 'domain_code', 'requested_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.update_subscription');
COMMENT ON TABLE ph06_mdm.update_subscription IS 'EN-06-18 Đăng ký nhận cập nhật bản ghi vàng của HTTT (FR-06-051). Cần mục đích khai thác đã được PH-09 chấp thuận (ERR-06-043). Kênh giao qua đăng ký PH-10 (ph10_subscription_code). Duyệt bốn mắt.';
--rollback DROP TABLE IF EXISTS ph06_mdm.update_subscription CASCADE;

--changeset ph06:ph06-0400-export-request
CREATE TABLE ph06_mdm.export_request (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  filter            jsonb NOT NULL DEFAULT '{}',
  fields            varchar(63)[] NOT NULL,
  format            varchar(8) NOT NULL,
  purpose_code      varchar(63) NOT NULL,
  legal_basis       varchar(2000) NOT NULL,
  recipient         varchar(255) NOT NULL,
  pseudonymize      boolean NOT NULL DEFAULT false,
  status            varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  row_count         integer,
  requested_by      varchar(64) NOT NULL,
  owner_approved_by varchar(64),
  owner_approved_at timestamptz,
  approved_by       varchar(64),
  approved_at       timestamptz,
  reject_reason     varchar(2000),
  file_ref          varchar(512),
  file_sha256       char(64),
  watermark_id      varchar(64),
  ready_at          timestamptz,
  expires_at        timestamptz,
  downloaded_at     timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_export_request PRIMARY KEY (id),
  CONSTRAINT uq_export_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_export_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_export_request_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_export_request_format CHECK (format IN ('CSV', 'XLSX', 'JSONL')),
  CONSTRAINT ck_export_request_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'GENERATING', 'READY', 'EXPIRED')),
  CONSTRAINT ck_export_request_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_export_request_owner CHECK (owner_approved_by IS NULL OR owner_approved_by <> requested_by),
  CONSTRAINT ck_export_request_approved CHECK (status NOT IN ('APPROVED', 'GENERATING', 'READY') OR (approved_by IS NOT NULL AND owner_approved_by IS NOT NULL)),
  CONSTRAINT ck_export_request_ready CHECK (status <> 'READY' OR (file_ref IS NOT NULL AND file_sha256 IS NOT NULL AND watermark_id IS NOT NULL AND expires_at IS NOT NULL)),
  CONSTRAINT ck_export_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL),
  CONSTRAINT ck_export_request_rows CHECK (row_count IS NULL OR row_count BETWEEN 0 AND 1000000)
);
CREATE INDEX ix_export_request_status ON ph06_mdm.export_request (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_export_request_touch BEFORE UPDATE ON ph06_mdm.export_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_export_request_immutable BEFORE UPDATE ON ph06_mdm.export_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'filter', 'fields', 'format', 'purpose_code', 'requested_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.export_request');
COMMENT ON TABLE ph06_mdm.export_request IS 'EN-06-19 Yêu cầu xuất dữ liệu chủ có duyệt (FR-06-049, BR-06-027): cần chấp thuận của DO các nguồn liên quan và DA; tệp mã hóa, có thủy vân, hạn tải 24 giờ. Tệp ở Ceph RGW (file_ref), không trong PostgreSQL. Giới hạn dòng theo 06.export.max-rows (ERR-06-041).';
COMMENT ON COLUMN ph06_mdm.export_request.expires_at IS 'ready_at + 24 giờ (BR-06-027); sau đó EXPIRED, ERR-06-042.';
--rollback DROP TABLE IF EXISTS ph06_mdm.export_request CASCADE;

--changeset ph06:ph06-0410-national-sync-state
CREATE TABLE ph06_mdm.national_sync_state (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  domain_code   varchar(32) NOT NULL,
  state         varchar(8) NOT NULL DEFAULT 'RUNNING',
  paused_reason varchar(2000),
  paused_at     timestamptz,
  paused_by     varchar(64),
  last_run_id   uuid,
  last_ratio    numeric(6,5),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_sync_state PRIMARY KEY (id),
  CONSTRAINT ck_national_sync_state_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_national_sync_state_domain UNIQUE (tenant_id, domain_code),
  CONSTRAINT fk_national_sync_state_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_national_sync_state_state CHECK (state IN ('RUNNING', 'PAUSED')),
  CONSTRAINT ck_national_sync_state_paused CHECK ((state = 'PAUSED') = (paused_at IS NOT NULL AND paused_reason IS NOT NULL)),
  CONSTRAINT ck_national_sync_state_ratio CHECK (last_ratio IS NULL OR last_ratio BETWEEN 0 AND 1)
);
CREATE TRIGGER tg_national_sync_state_touch BEFORE UPDATE ON ph06_mdm.national_sync_state FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_national_sync_state_immutable BEFORE UPDATE ON ph06_mdm.national_sync_state FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code');
CALL ph06_mdm.p_enable_rls('ph06_mdm.national_sync_state');
COMMENT ON TABLE ph06_mdm.national_sync_state IS 'EN-06-29 FR-06-053, 054 Trạng thái đồng bộ quốc gia mỗi domain: RUNNING hoặc PAUSED. Lệch > 06.sync.pause-ratio tạm dừng tự động (BR-06-011, ERR-06-107); tiếp tục cần người có PERM-06-sync.';
--rollback DROP TABLE IF EXISTS ph06_mdm.national_sync_state CASCADE;

--changeset ph06:ph06-0420-national-sync-run
CREATE TABLE ph06_mdm.national_sync_run (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  direction         varchar(12) NOT NULL,
  job_id            uuid,
  scope             jsonb NOT NULL DEFAULT '{}',
  checked_count     integer NOT NULL DEFAULT 0,
  discrepancy_count integer NOT NULL DEFAULT 0,
  applied_count     integer NOT NULL DEFAULT 0,
  ratio             numeric(6,5),
  paused            boolean NOT NULL DEFAULT false,
  ph14_ref          varchar(64),
  requested_by      varchar(64) NOT NULL,
  started_at        timestamptz NOT NULL DEFAULT now(),
  finished_at       timestamptz,
  error_code        varchar(16),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_sync_run PRIMARY KEY (id),
  CONSTRAINT uq_national_sync_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_national_sync_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_national_sync_run_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_national_sync_run_direction CHECK (direction IN ('DOWN', 'UP', 'RECONCILE')),
  CONSTRAINT ck_national_sync_run_counts CHECK (checked_count >= 0 AND discrepancy_count >= 0 AND applied_count >= 0 AND discrepancy_count <= checked_count),
  CONSTRAINT ck_national_sync_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-06-10[6-8]$'),
  CONSTRAINT ck_national_sync_run_ratio CHECK (ratio IS NULL OR ratio BETWEEN 0 AND 1)
);
CREATE INDEX ix_national_sync_run_domain ON ph06_mdm.national_sync_run (tenant_id, domain_code, started_at DESC);
CREATE TRIGGER tg_national_sync_run_touch BEFORE UPDATE ON ph06_mdm.national_sync_run FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.national_sync_run');
COMMENT ON TABLE ph06_mdm.national_sync_run IS 'EN-06-16 Nhật ký một lượt đồng bộ với CSDL tổng hợp quốc gia qua PH-14 (FR-06-053). Tỷ lệ lệch ratio so với ngưỡng BR-06-011. PH-06 không gọi trực tiếp CSDL quốc gia (BR-06-032); ph14_ref là mã giao dịch PH-14.';
--rollback DROP TABLE IF EXISTS ph06_mdm.national_sync_run CASCADE;

--changeset ph06:ph06-0430-national-discrepancy
CREATE TABLE ph06_mdm.national_discrepancy (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  run_id         uuid NOT NULL,
  domain_code    varchar(32) NOT NULL,
  golden_id      uuid NOT NULL,
  attribute_name varchar(63) NOT NULL,
  severity       varchar(8) NOT NULL,
  status         varchar(24) NOT NULL DEFAULT 'OPEN',
  local_enc      bytea,
  national_enc   bytea,
  value_kid      varchar(64),
  local_hash     bytea,
  national_hash  bytea,
  resolution     varchar(24),
  resolved_by    varchar(64),
  resolved_at    timestamptz,
  resolve_reason varchar(2000),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_discrepancy PRIMARY KEY (id),
  CONSTRAINT ck_national_discrepancy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_national_discrepancy_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph06_mdm.national_sync_run (tenant_id, id),
  CONSTRAINT fk_national_discrepancy_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_national_discrepancy_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_national_discrepancy_status CHECK (status IN ('OPEN', 'ACCEPTED_NATIONAL', 'KEPT_LOCAL', 'REPORTED_TO_NATIONAL', 'IGNORED')),
  CONSTRAINT ck_national_discrepancy_resolution CHECK (resolution IS NULL OR resolution IN ('ACCEPT_NATIONAL', 'KEEP_LOCAL', 'REPORT_TO_NATIONAL', 'IGNORE')),
  CONSTRAINT ck_national_discrepancy_resolved CHECK ((status = 'OPEN') = (resolution IS NULL AND resolved_by IS NULL)),
  CONSTRAINT ck_national_discrepancy_hash CHECK ((local_hash IS NULL OR octet_length(local_hash) = 32) AND (national_hash IS NULL OR octet_length(national_hash) = 32)),
  CONSTRAINT ck_national_discrepancy_enc CHECK ((local_enc IS NULL AND national_enc IS NULL) OR value_kid IS NOT NULL)
);
CREATE UNIQUE INDEX uq_national_discrepancy_open ON ph06_mdm.national_discrepancy (tenant_id, golden_id, attribute_name) WHERE status = 'OPEN';
CREATE INDEX ix_national_discrepancy_run ON ph06_mdm.national_discrepancy (tenant_id, run_id, severity);
CREATE TRIGGER tg_national_discrepancy_touch BEFORE UPDATE ON ph06_mdm.national_discrepancy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_national_discrepancy_immutable BEFORE UPDATE ON ph06_mdm.national_discrepancy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('run_id', 'golden_id', 'attribute_name');
CALL ph06_mdm.p_enable_rls('ph06_mdm.national_discrepancy');
COMMENT ON TABLE ph06_mdm.national_discrepancy IS 'EN-06-30 FR-06-053, 054 Lệch giữa bản ghi vàng và CSDL quốc gia trên thuộc tính đồng bộ. Giá trị hai phía mã hóa envelope kèm HMAC. Một lệch OPEN mỗi (bản ghi vàng, thuộc tính). Thuộc tính thẩm quyền quốc gia không giữ giá trị địa phương khi lệch (BR-06-025).';
--rollback DROP TABLE IF EXISTS ph06_mdm.national_discrepancy CASCADE;

--changeset ph06:ph06-0440-source-correction
CREATE TABLE ph06_mdm.source_correction (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  golden_id      uuid NOT NULL,
  attribute_name varchar(63) NOT NULL,
  source_code    varchar(32) NOT NULL,
  source_key     varchar(120),
  origin         varchar(24) NOT NULL,
  origin_ref     uuid,
  due_at         timestamptz NOT NULL,
  closed_at      timestamptz,
  closed_by      varchar(64),
  close_note     varchar(2000),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_correction PRIMARY KEY (id),
  CONSTRAINT ck_source_correction_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_correction_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT fk_source_correction_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_source_correction_origin CHECK (origin IN ('MANUAL_EDIT', 'NATIONAL_SYNC', 'DSR_CORRECTION')),
  CONSTRAINT ck_source_correction_closed CHECK ((closed_at IS NULL) = (closed_by IS NULL))
);
CREATE INDEX ix_source_correction_open ON ph06_mdm.source_correction (tenant_id, source_code, due_at) WHERE closed_at IS NULL;
CREATE TRIGGER tg_source_correction_touch BEFORE UPDATE ON ph06_mdm.source_correction FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_correction');
COMMENT ON TABLE ph06_mdm.source_correction IS 'EN-06-31 BR-06-014, EVT-06-15 Yêu cầu sửa tại nguồn: phát sinh khi sửa tay bản ghi vàng (FR-06-036), yêu cầu sửa của chủ thể (FR-06-058) hoặc lệch quốc gia (FR-06-054). Dữ liệu sai phải sửa ở nguồn; sửa tay ở bản ghi vàng chỉ tạm thời.';
--rollback DROP TABLE IF EXISTS ph06_mdm.source_correction CASCADE;
