--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0070-backup.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0460-backup-object splitStatements:false
CREATE TABLE ph18_ops.backup_object (
  id                         uuid NOT NULL,
  tenant_id                  varchar(16) NOT NULL,
  object_code                varchar(64) NOT NULL,
  name                       varchar(255) NOT NULL,
  object_kind                varchar(20) NOT NULL,
  tool                       varchar(20) NOT NULL,
  schedule                   varchar(64) NOT NULL,
  rpo_minutes                integer,
  rto_minutes                integer,
  retention_days             integer NOT NULL,
  target_location            varchar(255) NOT NULL,
  recovery_tier              varchar(8),
  verification_interval_days integer,
  enabled                    boolean NOT NULL DEFAULT true,
  created_at                 timestamptz NOT NULL DEFAULT now(),
  created_by                 varchar(64) NOT NULL,
  updated_at                 timestamptz NOT NULL DEFAULT now(),
  updated_by                 varchar(64) NOT NULL,
  version                    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_backup_object PRIMARY KEY (id),
  CONSTRAINT uq_backup_object_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_backup_object_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_backup_object_code UNIQUE (tenant_id, object_code),
  CONSTRAINT ck_backup_object_code CHECK (object_code ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  CONSTRAINT ck_backup_object_kind CHECK (object_kind IN ('POSTGRES_BASE', 'POSTGRES_WAL', 'TENANT_EXPORT', 'OBJECT_STORE', 'SECRET_STORE', 'K8S_RESOURCES', 'VOLUME', 'GIT', 'REGISTRY', 'CLICKHOUSE', 'KAFKA_CONFIG', 'AUDIT_WORM', 'OFFLINE_SHARES')),
  CONSTRAINT ck_backup_object_tool CHECK (tool IN ('CNPG_BARMAN', 'DH_TENANT_EXPORT', 'RCLONE', 'OPENBAO_RAFT', 'VELERO', 'VELERO_KOPIA', 'GIT_MIRROR', 'HARBOR_REPLICATION', 'CLICKHOUSE_BACKUP', 'PH13_WORM', 'SHAMIR_OFFLINE')),
  CONSTRAINT ck_backup_object_numbers CHECK ((rpo_minutes IS NULL OR rpo_minutes >= 0) AND (rto_minutes IS NULL OR rto_minutes > 0) AND retention_days >= 0),
  CONSTRAINT ck_backup_object_tier CHECK (recovery_tier IS NULL OR recovery_tier ~ '^TPH-[0-9]$'),
  CONSTRAINT ck_backup_object_location CHECK (target_location !~ '://[^/]*@')
);
CREATE TRIGGER tg_backup_object_touch BEFORE UPDATE ON ph18_ops.backup_object FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_backup_object_immutable BEFORE UPDATE ON ph18_ops.backup_object FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('object_code');
CALL ph18_ops.p_enable_rls('ph18_ops.backup_object', false);
COMMENT ON TABLE ph18_ops.backup_object IS 'EN-18-35 Đối tượng sao lưu theo D03-09 §8.2 (PostgreSQL cơ sở và WAL qua CNPG Barman Cloud, xuất logic theo tenant dh-tenant-export, Garage rclone, OpenBao Raft, Velero, ClickHouse, WORM kiểm toán…): công cụ, lịch, RPO, RTO, thời gian giữ, nơi lưu (chỉ tên kho, không thông tin xác thực), tầng phục hồi. Dòng COMMON là đối tượng cụm.';
--rollback DROP TABLE IF EXISTS ph18_ops.backup_object CASCADE;

--changeset ph18:ph18-0470-backup-run splitStatements:false
CREATE TABLE ph18_ops.backup_run (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  object_id     uuid NOT NULL,
  run_ref       varchar(255) NOT NULL,
  started_at    timestamptz NOT NULL,
  finished_at   timestamptz,
  status        varchar(12) NOT NULL,
  size_bytes    bigint,
  location      varchar(500),
  checksum      char(64),
  error_message varchar(2000),
  collector     varchar(32) NOT NULL,
  collected_at  timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_backup_run PRIMARY KEY (id),
  CONSTRAINT uq_backup_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_backup_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_backup_run_ref UNIQUE (tenant_id, object_id, run_ref),
  CONSTRAINT fk_backup_run_object FOREIGN KEY (tenant_id, object_id) REFERENCES ph18_ops.backup_object (tenant_id, id),
  CONSTRAINT ck_backup_run_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED', 'EXPIRED')),
  CONSTRAINT ck_backup_run_finished CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT ck_backup_run_period CHECK (finished_at IS NULL OR finished_at >= started_at),
  CONSTRAINT ck_backup_run_failed CHECK (status <> 'FAILED' OR error_message IS NOT NULL),
  CONSTRAINT ck_backup_run_sha CHECK (checksum IS NULL OR checksum ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_backup_run_collector CHECK (collector IN ('CNPG', 'VELERO', 'RCLONE', 'OPENBAO', 'DH_TENANT_EXPORT', 'CLICKHOUSE', 'MANUAL'))
);
CREATE INDEX ix_backup_run_object ON ph18_ops.backup_run (tenant_id, object_id, started_at DESC);
CREATE TRIGGER tg_backup_run_touch BEFORE UPDATE ON ph18_ops.backup_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_backup_run_immutable BEFORE UPDATE ON ph18_ops.backup_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('object_id', 'run_ref', 'started_at');
CALL ph18_ops.p_enable_rls('ph18_ops.backup_run', false);
COMMENT ON TABLE ph18_ops.backup_run IS 'EN-18-36 Bản sao lưu thu từ nguồn (CNPG Backup CR, Velero Backup, nhật ký rclone, snapshot OpenBao, kết quả dh-tenant-export): mã bản ở nguồn, thời gian, trạng thái, kích thước, vị trí, tổng kiểm tra, lỗi. Lỗi phát sự kiện để mở sự cố và thông báo.';
--rollback DROP TABLE IF EXISTS ph18_ops.backup_run CASCADE;

--changeset ph18:ph18-0480-restore-verification splitStatements:false
CREATE TABLE ph18_ops.restore_verification (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  object_id        uuid NOT NULL,
  backup_run_id    uuid,
  verified_at      timestamptz NOT NULL DEFAULT now(),
  method           varchar(20) NOT NULL,
  outcome          varchar(8) NOT NULL,
  duration_seconds integer NOT NULL,
  rto_met          boolean,
  rows_checked     bigint,
  details          jsonb NOT NULL DEFAULT '{}',
  job_ref          varchar(128),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_restore_verification PRIMARY KEY (id),
  CONSTRAINT uq_restore_verification_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_restore_verification_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_restore_verification_object FOREIGN KEY (tenant_id, object_id) REFERENCES ph18_ops.backup_object (tenant_id, id),
  CONSTRAINT fk_restore_verification_backup_run FOREIGN KEY (tenant_id, backup_run_id) REFERENCES ph18_ops.backup_run (tenant_id, id),
  CONSTRAINT ck_restore_verification_method CHECK (method IN ('PITR_TEMP_CLUSTER', 'TENANT_REIMPORT', 'OBJECT_SAMPLE', 'OPENBAO_RESTORE', 'VELERO_RESTORE', 'CHAIN_INTEGRITY', 'BUNDLE_CHECK')),
  CONSTRAINT ck_restore_verification_outcome CHECK (outcome IN ('PASSED', 'FAILED')),
  CONSTRAINT ck_restore_verification_duration CHECK (duration_seconds >= 0)
);
CREATE INDEX ix_restore_verification_object ON ph18_ops.restore_verification (tenant_id, object_id, verified_at DESC);
CREATE TRIGGER tg_restore_verification_touch BEFORE UPDATE ON ph18_ops.restore_verification FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_restore_verification_append_only BEFORE UPDATE OR DELETE ON ph18_ops.restore_verification FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.restore_verification', false);
COMMENT ON TABLE ph18_ops.restore_verification IS 'EN-18-37 Kết quả kiểm tra khôi phục tự động (điều kiện 0 lỗi của 3-2-1-1-0): đối tượng, bản sao lưu, phương pháp, kết quả, thời lượng, đạt RTO, số dòng kiểm. Chỉ thêm.';
--rollback DROP TABLE IF EXISTS ph18_ops.restore_verification CASCADE;

--changeset ph18:ph18-0490-tenant-restore-request splitStatements:false
CREATE TABLE ph18_ops.tenant_restore_request (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  request_no          varchar(24) NOT NULL,
  restore_point       timestamptz NOT NULL,
  scope               varchar(12) NOT NULL,
  schemas             varchar(32)[] NOT NULL DEFAULT '{}',
  reason              text NOT NULL,
  status              varchar(20) NOT NULL DEFAULT 'DRAFT',
  requested_by        varchar(64) NOT NULL,
  approved_by         varchar(64),
  approved_at         timestamptz,
  rejected_reason     varchar(1000),
  current_step        smallint NOT NULL DEFAULT 0,
  estimated_size_gb   numeric(10,2),
  job_name            varchar(128),
  tenant_suspended_at timestamptz,
  tenant_resumed_at   timestamptz,
  started_at          timestamptz,
  finished_at         timestamptz,
  rows_replaced       bigint,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_restore_request PRIMARY KEY (id),
  CONSTRAINT uq_tenant_restore_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_restore_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_restore_request_no UNIQUE (tenant_id, request_no),
  CONSTRAINT ck_tenant_restore_request_scope CHECK (scope IN ('FULL_TENANT', 'SCHEMAS')),
  CONSTRAINT ck_tenant_restore_request_schemas CHECK ((scope = 'SCHEMAS') = (cardinality(schemas) > 0)),
  CONSTRAINT ck_tenant_restore_request_schema_names CHECK (schemas <@ ARRAY['ph01_onboarding', 'ph02_catalog', 'ph03_gateway', 'ph04', 'ph05_adapter', 'ph06_mdm', 'ph07_rdm', 'ph08_dq', 'ph09_privacy', 'ph10_event', 'ph11_bpm', 'ph11_flowable', 'ph14_national', 'ph15_portal', 'ph16_kpi', 'ph17_assist', 'ph18_ops']::varchar(32)[]),
  CONSTRAINT ck_tenant_restore_request_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 20),
  CONSTRAINT ck_tenant_restore_request_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'ROLLED_BACK', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_tenant_restore_request_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_tenant_restore_request_approved CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'CANCELLED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_tenant_restore_request_step CHECK (current_step BETWEEN 0 AND 8),
  CONSTRAINT ck_tenant_restore_request_point CHECK (restore_point < created_at)
);
CREATE UNIQUE INDEX uq_tenant_restore_request_active ON ph18_ops.tenant_restore_request (tenant_id) WHERE status IN ('PENDING_APPROVAL', 'APPROVED', 'RUNNING');
CREATE TRIGGER tg_tenant_restore_request_touch BEFORE UPDATE ON ph18_ops.tenant_restore_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_tenant_restore_request_immutable BEFORE UPDATE ON ph18_ops.tenant_restore_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('request_no', 'restore_point', 'scope', 'schemas', 'requested_by');
CREATE TRIGGER tg_tenant_restore_request_fsm_status BEFORE UPDATE ON ph18_ops.tenant_restore_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PENDING_APPROVAL,DRAFT>CANCELLED,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED,APPROVED>RUNNING,APPROVED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>FAILED,RUNNING>ROLLED_BACK,FAILED>ROLLED_BACK');
CALL ph18_ops.p_enable_rls('ph18_ops.tenant_restore_request', false);
COMMENT ON TABLE ph18_ops.tenant_restore_request IS 'EN-18-38 Yêu cầu khôi phục một tenant (RBK-04, D03-09 §8.5): thời điểm đích, phạm vi (toàn tenant hay một số schema), lý do; TA tạo, PA duyệt bốn mắt; dh-tenant-restore chạy tám bước, tenant SUSPENDED khi thay, phát ops.tenant.restored; mục tiêu ≤ 4 giờ cho tenant ≤ 200 GB. Mỗi tenant một yêu cầu đang hoạt động.';
COMMENT ON COLUMN ph18_ops.tenant_restore_request.schemas IS 'Schema thuộc phạm vi khi scope = SCHEMAS; không gồm schema kiểm toán ph13 (kiểm toán không khôi phục về quá khứ, D03-09 §8.5 bước 7).';
--rollback DROP TABLE IF EXISTS ph18_ops.tenant_restore_request CASCADE;

--changeset ph18:ph18-0500-tenant-restore-step splitStatements:false
CREATE TABLE ph18_ops.tenant_restore_step (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  request_id    uuid NOT NULL,
  step_no       smallint NOT NULL,
  step_code     varchar(24) NOT NULL,
  status        varchar(12) NOT NULL DEFAULT 'PENDING',
  started_at    timestamptz,
  finished_at   timestamptz,
  rows_affected bigint,
  message       varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_restore_step PRIMARY KEY (id),
  CONSTRAINT uq_tenant_restore_step_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_restore_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_restore_step_no UNIQUE (tenant_id, request_id, step_no),
  CONSTRAINT fk_tenant_restore_step_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph18_ops.tenant_restore_request (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_tenant_restore_step_code CHECK ((step_no, step_code) IN ((1, 'APPROVAL'), (2, 'BUILD_TEMP_CLUSTER'), (3, 'EXTRACT_TENANT'), (4, 'SUSPEND_TENANT'), (5, 'REPLACE_DATA'), (6, 'RESTORE_OTHER_STORES'), (7, 'AUDIT_RECORD'), (8, 'VERIFY_AND_REOPEN'))),
  CONSTRAINT ck_tenant_restore_step_status CHECK (status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED', 'ROLLED_BACK')),
  CONSTRAINT ck_tenant_restore_step_period CHECK (finished_at IS NULL OR (started_at IS NOT NULL AND finished_at >= started_at))
);
CREATE TRIGGER tg_tenant_restore_step_touch BEFORE UPDATE ON ph18_ops.tenant_restore_step FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_tenant_restore_step_immutable BEFORE UPDATE ON ph18_ops.tenant_restore_step FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('request_id', 'step_no', 'step_code');
CALL ph18_ops.p_enable_rls('ph18_ops.tenant_restore_step', false);
COMMENT ON TABLE ph18_ops.tenant_restore_step IS 'EN-18-39 Một trong tám bước của dh-tenant-restore (D03-09 §8.5): phê duyệt, dựng cụm tạm, trích dữ liệu, đặt tenant bảo trì, thay thế, kho khác, ghi kiểm toán, kiểm tra và mở lại; trạng thái, thời gian, số dòng.';
--rollback DROP TABLE IF EXISTS ph18_ops.tenant_restore_step CASCADE;

--changeset ph18:ph18-0510-tenant-export-job splitStatements:false
CREATE TABLE ph18_ops.tenant_export_job (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  purpose             varchar(24) NOT NULL,
  requested_by_module varchar(8) NOT NULL DEFAULT 'PH20',
  ph20_request_ref    varchar(64),
  export_format       varchar(8) NOT NULL DEFAULT 'PG_COPY',
  modules             varchar(8)[] NOT NULL DEFAULT '{}',
  status              varchar(24) NOT NULL DEFAULT 'QUEUED',
  output_location     varchar(500),
  sha256              char(64),
  size_bytes          bigint,
  expires_at          timestamptz,
  started_at          timestamptz,
  finished_at         timestamptz,
  job_name            varchar(128),
  error_message       varchar(2000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_export_job PRIMARY KEY (id),
  CONSTRAINT uq_tenant_export_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_export_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_export_job_purpose CHECK (purpose IN ('DECOMMISSION_HANDOVER', 'CELL_MOVE', 'DEDICATED_DB', 'MERGE', 'ON_REQUEST')),
  CONSTRAINT ck_tenant_export_job_module CHECK (requested_by_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_tenant_export_job_format CHECK (export_format IN ('PG_COPY', 'JSONL', 'CSV')),
  CONSTRAINT ck_tenant_export_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_tenant_export_job_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_tenant_export_job_done CHECK (status <> 'SUCCEEDED' OR (output_location IS NOT NULL AND sha256 IS NOT NULL))
);
CREATE INDEX ix_tenant_export_job_status ON ph18_ops.tenant_export_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_tenant_export_job_touch BEFORE UPDATE ON ph18_ops.tenant_export_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_tenant_export_job_immutable BEFORE UPDATE ON ph18_ops.tenant_export_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('purpose', 'export_format');
CREATE TRIGGER tg_tenant_export_job_fsm_status BEFORE UPDATE ON ph18_ops.tenant_export_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,RUNNING>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.tenant_export_job', false);
COMMENT ON TABLE ph18_ops.tenant_export_job IS 'EN-18-40 Lần xuất dữ liệu tenant bằng dh-tenant-export: bàn giao khi DECOMMISSIONED, chuyển ô CSDL, SHARED sang DEDICATED_DB, sáp nhập (PH-20 gọi) hoặc theo yêu cầu; định dạng, phân hệ, tệp ra ở kho sao lưu, tổng kiểm tra, hạn tải.';
--rollback DROP TABLE IF EXISTS ph18_ops.tenant_export_job CASCADE;

--changeset ph18:ph18-0520-dr-drill splitStatements:false
CREATE TABLE ph18_ops.dr_drill (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  drill_code           varchar(32) NOT NULL,
  drill_kind           varchar(20) NOT NULL,
  scheduled_at         timestamptz,
  performed_at         timestamptz NOT NULL,
  performed_by         varchar(64) NOT NULL,
  outcome              varchar(8) NOT NULL,
  rpo_achieved_minutes integer,
  rto_achieved_minutes integer,
  findings             text,
  actions              text,
  report_ref           varchar(255),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dr_drill PRIMARY KEY (id),
  CONSTRAINT uq_dr_drill_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dr_drill_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_dr_drill_code UNIQUE (tenant_id, drill_code),
  CONSTRAINT ck_dr_drill_kind CHECK (drill_kind IN ('SITE_FAILOVER', 'PITR_CLUSTER', 'FULL_RESTORE', 'TENANT_RESTORE', 'BACKUP_RESTORE_TEST')),
  CONSTRAINT ck_dr_drill_outcome CHECK (outcome IN ('PASSED', 'PARTIAL', 'FAILED')),
  CONSTRAINT ck_dr_drill_findings CHECK (outcome = 'PASSED' OR coalesce(char_length(btrim(findings)), 0) >= 20)
);
CREATE TRIGGER tg_dr_drill_touch BEFORE UPDATE ON ph18_ops.dr_drill FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dr_drill_immutable BEFORE UPDATE ON ph18_ops.dr_drill FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('drill_code', 'drill_kind', 'performed_at');
CALL ph18_ops.p_enable_rls('ph18_ops.dr_drill', false);
COMMENT ON TABLE ph18_ops.dr_drill IS 'EN-18-41 Ghi nhận diễn tập DR và PITR toàn cụm (PA thực hiện ngoài ứng dụng, PH-18 chỉ ghi nhận): loại, thời điểm, kết quả, RPO và RTO đạt được, phát hiện, hành động khắc phục, biên bản ở kho tài liệu.';
--rollback DROP TABLE IF EXISTS ph18_ops.dr_drill CASCADE;

--changeset ph18:ph18-0530-merge-transfer splitStatements:false
CREATE TABLE ph18_ops.merge_transfer (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  merge_plan_id    varchar(64) NOT NULL,
  module           varchar(8) NOT NULL,
  source_tenant    varchar(16) NOT NULL,
  target_tenant    varchar(16) NOT NULL,
  mapping_ref      varchar(255) NOT NULL,
  dry_run          boolean NOT NULL DEFAULT true,
  status           varchar(24) NOT NULL DEFAULT 'QUEUED',
  progress_percent numeric(5,2) NOT NULL DEFAULT 0,
  rows_total       bigint,
  rows_copied      bigint NOT NULL DEFAULT 0,
  rows_skipped     bigint NOT NULL DEFAULT 0,
  rows_failed      bigint NOT NULL DEFAULT 0,
  export_job_id    uuid,
  job_name         varchar(128),
  started_at       timestamptz,
  finished_at      timestamptz,
  last_reported_at timestamptz,
  report_status    varchar(16) NOT NULL DEFAULT 'PENDING',
  error_message    varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_transfer PRIMARY KEY (id),
  CONSTRAINT uq_merge_transfer_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_merge_transfer_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_merge_transfer_export_job FOREIGN KEY (tenant_id, export_job_id) REFERENCES ph18_ops.tenant_export_job (tenant_id, id),
  CONSTRAINT ck_merge_transfer_module CHECK (module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_merge_transfer_tenants CHECK (source_tenant ~ '^T[0-9]{2}$' AND target_tenant = tenant_id AND source_tenant <> target_tenant),
  CONSTRAINT ck_merge_transfer_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_merge_transfer_progress CHECK (progress_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_merge_transfer_rows CHECK (rows_copied >= 0 AND rows_skipped >= 0 AND rows_failed >= 0 AND (rows_total IS NULL OR rows_copied + rows_skipped + rows_failed <= rows_total)),
  CONSTRAINT ck_merge_transfer_report CHECK (report_status IN ('PENDING', 'REPORTED', 'REPORT_FAILED')),
  CONSTRAINT ck_merge_transfer_done CHECK (status <> 'SUCCEEDED' OR progress_percent = 100)
);
CREATE UNIQUE INDEX uq_merge_transfer_real ON ph18_ops.merge_transfer (tenant_id, merge_plan_id, module) WHERE NOT dry_run AND status NOT IN ('FAILED', 'CANCELLED');
CREATE INDEX ix_merge_transfer_plan ON ph18_ops.merge_transfer (tenant_id, merge_plan_id);
CREATE TRIGGER tg_merge_transfer_touch BEFORE UPDATE ON ph18_ops.merge_transfer FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_merge_transfer_immutable BEFORE UPDATE ON ph18_ops.merge_transfer FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('merge_plan_id', 'module', 'source_tenant', 'target_tenant', 'mapping_ref', 'dry_run');
CREATE TRIGGER tg_merge_transfer_fsm_status BEFORE UPDATE ON ph18_ops.merge_transfer FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,RUNNING>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.merge_transfer', false);
COMMENT ON TABLE ph18_ops.merge_transfer IS 'EN-18-55 Chuyển dữ liệu một phân hệ khi sáp nhập tenant (hợp đồng PH-20, BRIEF §7): PH-20 gọi POST /api/ops/v1/merge-transfers với mergePlanId, module, sourceTenant, targetTenant, mappingRef, dryRun; worker dh-tenant-export và nạp giữ id gốc, ghi origin_tenant_id ở PH đích; PH-18 báo tiến độ về PH-20 (participants/{module}:report). Dòng thuộc tenant đích. Mỗi kế hoạch, phân hệ chỉ một lần chạy thật đang hoạt động hoặc đã xong.';
COMMENT ON COLUMN ph18_ops.merge_transfer.mapping_ref IS 'Tham chiếu bảng ánh xạ mã của kế hoạch sáp nhập do PH-20 giữ (không chép nội dung).';
--rollback DROP TABLE IF EXISTS ph18_ops.merge_transfer CASCADE;
