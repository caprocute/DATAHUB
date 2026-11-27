--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0080-migration.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0540-legacy-source splitStatements:false
CREATE TABLE ph18_ops.legacy_source (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  source_code        varchar(32) NOT NULL,
  name               varchar(255) NOT NULL,
  system_kind        varchar(12) NOT NULL,
  jdbc_url           varchar(500) NOT NULL,
  credential_ref     varchar(255) NOT NULL,
  read_only_verified boolean NOT NULL DEFAULT false,
  verified_at        timestamptz,
  status             varchar(12) NOT NULL DEFAULT 'DRAFT',
  owner              varchar(64) NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_source PRIMARY KEY (id),
  CONSTRAINT uq_legacy_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legacy_source_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_legacy_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_legacy_source_kind CHECK (system_kind IN ('BUS', 'TOOLING', 'HUB', 'APIM', 'AITA', 'PAYGOV', 'NGSP', 'OTHER')),
  CONSTRAINT ck_legacy_source_jdbc CHECK (jdbc_url ~ '^jdbc:(postgresql|mysql|mariadb|oracle|sqlserver):' AND jdbc_url !~* '(user|pass)[a-z]*=' AND jdbc_url !~ '//[^/]*@'),
  CONSTRAINT ck_legacy_source_vault CHECK (credential_ref ~ ('^kv/dh/' || lower(tenant_id) || '/')),
  CONSTRAINT ck_legacy_source_status CHECK (status IN ('DRAFT', 'VERIFIED', 'DISABLED')),
  CONSTRAINT ck_legacy_source_verified CHECK (status <> 'VERIFIED' OR (read_only_verified AND verified_at IS NOT NULL))
);
CREATE TRIGGER tg_legacy_source_touch BEFORE UPDATE ON ph18_ops.legacy_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_legacy_source_immutable BEFORE UPDATE ON ph18_ops.legacy_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('source_code');
CALL ph18_ops.p_enable_rls('ph18_ops.legacy_source', false);
COMMENT ON TABLE ph18_ops.legacy_source IS 'EN-18-42 Nguồn hệ cũ (IF-07): loại hệ (Bus, Tooling, Hub, APIM, Danh mục Aita, PayGov, NGSP), URL JDBC không kèm thông tin đăng nhập, tham chiếu bí mật OpenBao kv/dh/{tenant}/..., xác nhận kết nối chỉ đọc. Thông tin xác thực không di trú (FR-00-093).';
COMMENT ON COLUMN ph18_ops.legacy_source.credential_ref IS 'Đường dẫn OpenBao kv/dh/{tenant}/migration/{nguồn}; PH-18 không lưu giá trị.';
--rollback DROP TABLE IF EXISTS ph18_ops.legacy_source CASCADE;

--changeset ph18:ph18-0550-migration-plan splitStatements:false
CREATE TABLE ph18_ops.migration_plan (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  plan_code           varchar(32) NOT NULL,
  legacy_source_id    uuid NOT NULL,
  title               varchar(255) NOT NULL,
  description         text,
  status              varchar(8) NOT NULL DEFAULT 'DRAFT',
  ready_at            timestamptz,
  ready_by            varchar(64),
  target_cutover_date date,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_plan PRIMARY KEY (id),
  CONSTRAINT uq_migration_plan_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_plan_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_plan_code UNIQUE (tenant_id, plan_code),
  CONSTRAINT fk_migration_plan_legacy_source FOREIGN KEY (tenant_id, legacy_source_id) REFERENCES ph18_ops.legacy_source (tenant_id, id),
  CONSTRAINT ck_migration_plan_status CHECK (status IN ('DRAFT', 'READY')),
  CONSTRAINT ck_migration_plan_ready CHECK (status <> 'READY' OR (ready_at IS NOT NULL AND ready_by IS NOT NULL))
);
CREATE TRIGGER tg_migration_plan_touch BEFORE UPDATE ON ph18_ops.migration_plan FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_plan_immutable BEFORE UPDATE ON ph18_ops.migration_plan FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('plan_code', 'legacy_source_id');
CREATE TRIGGER tg_migration_plan_fsm_status BEFORE UPDATE ON ph18_ops.migration_plan FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>READY,READY>DRAFT');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_plan', false);
COMMENT ON TABLE ph18_ops.migration_plan IS 'EN-18-43 Kế hoạch di trú một nguồn: các loại đối tượng theo thứ tự phụ thuộc (danh mục, HTTT, API, gói, đăng ký, topic, luồng, giao dịch), ngày cắt chuyển dự kiến. DRAFT sang READY khi đủ mục và nguồn đã xác minh.';
--rollback DROP TABLE IF EXISTS ph18_ops.migration_plan CASCADE;

--changeset ph18:ph18-0560-migration-plan-item splitStatements:false
CREATE TABLE ph18_ops.migration_plan_item (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  plan_id          uuid NOT NULL,
  seq_no           integer NOT NULL,
  object_kind      varchar(12) NOT NULL,
  target_module    varchar(8) NOT NULL,
  converter_code   varchar(64) NOT NULL,
  source_query_ref varchar(255) NOT NULL,
  target_api       varchar(16) NOT NULL,
  depends_on       varchar(12)[] NOT NULL DEFAULT '{}',
  batch_size       integer NOT NULL DEFAULT 500,
  enabled          boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_plan_item PRIMARY KEY (id),
  CONSTRAINT uq_migration_plan_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_plan_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_plan_item_seq UNIQUE (tenant_id, plan_id, seq_no),
  CONSTRAINT uq_migration_plan_item_kind UNIQUE (tenant_id, plan_id, object_kind),
  CONSTRAINT fk_migration_plan_item_plan FOREIGN KEY (tenant_id, plan_id) REFERENCES ph18_ops.migration_plan (tenant_id, id),
  CONSTRAINT ck_migration_plan_item_kind CHECK (object_kind IN ('CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION')),
  CONSTRAINT ck_migration_plan_item_target CHECK ((object_kind = 'CATALOG' AND target_module = 'PH07') OR (object_kind = 'SYSTEM' AND target_module = 'PH01') OR (object_kind IN ('API', 'PLAN', 'SUBSCRIPTION') AND target_module IN ('PH02', 'PH03')) OR (object_kind IN ('TOPIC', 'PUBLISHER', 'SUBSCRIBER') AND target_module = 'PH10') OR (object_kind = 'FLOW' AND target_module = 'PH04') OR (object_kind = 'TRANSACTION' AND target_module = 'PH19')),
  CONSTRAINT ck_migration_plan_item_api CHECK (target_api ~ '^API-[0-9]{2}-[0-9]{3}$' AND substr(target_api, 5, 2) = substr(target_module, 3, 2)),
  CONSTRAINT ck_migration_plan_item_depends CHECK (depends_on <@ ARRAY['CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION']::varchar(12)[] AND NOT (object_kind = ANY (depends_on))),
  CONSTRAINT ck_migration_plan_item_batch CHECK (batch_size BETWEEN 1 AND 10000)
);
CREATE TRIGGER tg_migration_plan_item_touch BEFORE UPDATE ON ph18_ops.migration_plan_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_plan_item_immutable BEFORE UPDATE ON ph18_ops.migration_plan_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('plan_id', 'object_kind', 'target_module');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_plan_item', false);
COMMENT ON TABLE ph18_ops.migration_plan_item IS 'EN-18-44 Mục kế hoạch theo loại đối tượng: PH đích đúng cặp (CATALOG sang PH-07, SYSTEM sang PH-01, API, PLAN, SUBSCRIPTION sang PH-02 hoặc PH-03, TOPIC, PUBLISHER, SUBSCRIBER sang PH-10, FLOW sang PH-04 nháp, TRANSACTION sang PH-19 API nhập), bộ chuyển, truy vấn nguồn đóng gói, API nhập của PH đích, phụ thuộc, cỡ lô.';
--rollback DROP TABLE IF EXISTS ph18_ops.migration_plan_item CASCADE;

--changeset ph18:ph18-0570-migration-run splitStatements:false
CREATE TABLE ph18_ops.migration_run (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  plan_id         uuid NOT NULL,
  run_no          integer NOT NULL,
  run_mode        varchar(8) NOT NULL,
  status          varchar(24) NOT NULL,
  requested_by    varchar(64) NOT NULL,
  approved_by     varchar(64),
  approved_at     timestamptz,
  rerun_of_run_id uuid,
  job_name        varchar(128),
  started_at      timestamptz,
  finished_at     timestamptz,
  items_total     integer NOT NULL DEFAULT 0,
  items_succeeded integer NOT NULL DEFAULT 0,
  items_failed    integer NOT NULL DEFAULT 0,
  items_skipped   integer NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_run PRIMARY KEY (id),
  CONSTRAINT uq_migration_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_run_no UNIQUE (tenant_id, plan_id, run_no),
  CONSTRAINT fk_migration_run_plan FOREIGN KEY (tenant_id, plan_id) REFERENCES ph18_ops.migration_plan (tenant_id, id),
  CONSTRAINT fk_migration_run_rerun FOREIGN KEY (tenant_id, rerun_of_run_id) REFERENCES ph18_ops.migration_run (tenant_id, id),
  CONSTRAINT ck_migration_run_mode CHECK (run_mode IN ('DRY_RUN', 'REAL')),
  CONSTRAINT ck_migration_run_status CHECK (status IN ('PENDING_APPROVAL', 'QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_migration_run_dry CHECK (run_mode = 'REAL' OR status <> 'PENDING_APPROVAL'),
  CONSTRAINT ck_migration_run_real CHECK (run_mode = 'DRY_RUN' OR status IN ('PENDING_APPROVAL', 'CANCELLED') OR approved_by IS NOT NULL),
  CONSTRAINT ck_migration_run_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_migration_run_counts CHECK (items_succeeded + items_failed + items_skipped <= items_total)
);
CREATE UNIQUE INDEX uq_migration_run_active ON ph18_ops.migration_run (tenant_id, plan_id) WHERE run_mode = 'REAL' AND status IN ('QUEUED', 'RUNNING');
CREATE TRIGGER tg_migration_run_touch BEFORE UPDATE ON ph18_ops.migration_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_run_immutable BEFORE UPDATE ON ph18_ops.migration_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('plan_id', 'run_no', 'run_mode', 'requested_by');
CREATE TRIGGER tg_migration_run_fsm_status BEFORE UPDATE ON ph18_ops.migration_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING_APPROVAL>QUEUED,PENDING_APPROVAL>CANCELLED,QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,RUNNING>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_run', false);
COMMENT ON TABLE ph18_ops.migration_run IS 'EN-18-45 Lần chạy di trú: DRY_RUN không ghi, REAL ghi qua API nhập của PH đích và cần bốn mắt (PENDING_APPROVAL trước QUEUED); idempotent nên chạy lại không tạo bản trùng; worker dh-migrate là Job K8s ở dh-batch; bộ đếm mục. Mỗi kế hoạch một lần chạy thật đang chạy.';
--rollback DROP TABLE IF EXISTS ph18_ops.migration_run CASCADE;

--changeset ph18:ph18-0580-migration-run-item-result splitStatements:false
CREATE TABLE ph18_ops.migration_run_item_result (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid NOT NULL,
  plan_item_id    uuid NOT NULL,
  status          varchar(24) NOT NULL DEFAULT 'QUEUED',
  source_count    bigint NOT NULL DEFAULT 0,
  migrated_count  bigint NOT NULL DEFAULT 0,
  unchanged_count bigint NOT NULL DEFAULT 0,
  skipped_count   bigint NOT NULL DEFAULT 0,
  error_count     bigint NOT NULL DEFAULT 0,
  source_checksum char(64),
  target_checksum char(64),
  started_at      timestamptz,
  finished_at     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_run_item_result PRIMARY KEY (id),
  CONSTRAINT uq_migration_run_item_result_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_run_item_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_run_item_result UNIQUE (tenant_id, run_id, plan_item_id),
  CONSTRAINT fk_migration_run_item_result_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_migration_run_item_result_item FOREIGN KEY (tenant_id, plan_item_id) REFERENCES ph18_ops.migration_plan_item (tenant_id, id),
  CONSTRAINT ck_migration_run_item_result_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_migration_run_item_result_counts CHECK (migrated_count + unchanged_count + skipped_count + error_count <= source_count),
  CONSTRAINT ck_migration_run_item_result_sha CHECK ((source_checksum IS NULL OR source_checksum ~ '^[0-9a-f]{64}$') AND (target_checksum IS NULL OR target_checksum ~ '^[0-9a-f]{64}$'))
);
CREATE TRIGGER tg_migration_run_item_result_touch BEFORE UPDATE ON ph18_ops.migration_run_item_result FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_run_item_result_immutable BEFORE UPDATE ON ph18_ops.migration_run_item_result FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('run_id', 'plan_item_id');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_run_item_result', false);
COMMENT ON TABLE ph18_ops.migration_run_item_result IS 'EN-18-46 Kết quả một mục kế hoạch trong lần chạy: số bản ghi nguồn, đã chuyển, bỏ qua, lỗi, không đổi (chạy lại), tổng kiểm tra nguồn và đích.';
--rollback DROP TABLE IF EXISTS ph18_ops.migration_run_item_result CASCADE;

--changeset ph18:ph18-0590-migration-error-record splitStatements:false
CREATE TABLE ph18_ops.migration_error_record (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  run_id            uuid NOT NULL,
  plan_item_id      uuid NOT NULL,
  source_record_ref varchar(255) NOT NULL,
  error_code        varchar(16) NOT NULL,
  error_message     varchar(2000) NOT NULL,
  field_path        varchar(255),
  source_snapshot   jsonb,
  fix_status        varchar(16) NOT NULL DEFAULT 'OPEN',
  fixed_by          varchar(64),
  fixed_at          timestamptz,
  fix_note          varchar(1000),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_error_record PRIMARY KEY (id),
  CONSTRAINT uq_migration_error_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_error_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_migration_error_record_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_migration_error_record_item FOREIGN KEY (tenant_id, plan_item_id) REFERENCES ph18_ops.migration_plan_item (tenant_id, id),
  CONSTRAINT ck_migration_error_record_code CHECK (error_code ~ '^ERR-[0-9]{2}-[0-9]{3}$'),
  CONSTRAINT ck_migration_error_record_fix CHECK (fix_status IN ('OPEN', 'FIXED_AT_SOURCE', 'FIXED_BY_RULE', 'ACCEPTED_SKIP')),
  CONSTRAINT ck_migration_error_record_fixed CHECK ((fix_status = 'OPEN') = (fixed_at IS NULL)),
  CONSTRAINT ck_migration_error_record_snapshot CHECK (source_snapshot IS NULL OR NOT (source_snapshot ?| ARRAY['passwd', 'credential', 'client_secret', 'api_key']))
);
CREATE INDEX ix_migration_error_record_run ON ph18_ops.migration_error_record (tenant_id, run_id, fix_status);
CREATE TRIGGER tg_migration_error_record_touch BEFORE UPDATE ON ph18_ops.migration_error_record FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_error_record_immutable BEFORE UPDATE ON ph18_ops.migration_error_record FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('run_id', 'plan_item_id', 'source_record_ref', 'error_code');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_error_record', false);
COMMENT ON TABLE ph18_ops.migration_error_record IS 'EN-18-47 Bản ghi không chuyển được kèm lý do (FR-00-091, 092): mã bản ghi nguồn, mã lỗi, trường lỗi, ảnh chụp nguồn đã che (không thông tin xác thực), trạng thái sửa (sửa ở nguồn, sửa bằng quy tắc, chấp nhận bỏ qua).';
--rollback DROP TABLE IF EXISTS ph18_ops.migration_error_record CASCADE;

--changeset ph18:ph18-0600-migration-reconciliation splitStatements:false
CREATE TABLE ph18_ops.migration_reconciliation (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid NOT NULL,
  plan_item_id    uuid NOT NULL,
  object_kind     varchar(12) NOT NULL,
  source_count    bigint NOT NULL,
  target_count    bigint NOT NULL,
  missing_count   bigint NOT NULL DEFAULT 0,
  extra_count     bigint NOT NULL DEFAULT 0,
  mismatch_count  bigint NOT NULL DEFAULT 0,
  source_checksum char(64) NOT NULL,
  target_checksum char(64) NOT NULL,
  checksum_algo   varchar(16) NOT NULL DEFAULT 'SHA-256',
  matched         boolean NOT NULL,
  computed_at     timestamptz NOT NULL DEFAULT now(),
  report_location varchar(500),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_reconciliation PRIMARY KEY (id),
  CONSTRAINT uq_migration_reconciliation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_reconciliation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_migration_reconciliation_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id),
  CONSTRAINT fk_migration_reconciliation_item FOREIGN KEY (tenant_id, plan_item_id) REFERENCES ph18_ops.migration_plan_item (tenant_id, id),
  CONSTRAINT ck_migration_reconciliation_kind CHECK (object_kind IN ('CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION')),
  CONSTRAINT ck_migration_reconciliation_counts CHECK (source_count >= 0 AND target_count >= 0 AND missing_count >= 0 AND extra_count >= 0 AND mismatch_count >= 0),
  CONSTRAINT ck_migration_reconciliation_matched CHECK (NOT matched OR (source_count = target_count AND missing_count = 0 AND extra_count = 0 AND mismatch_count = 0 AND source_checksum = target_checksum)),
  CONSTRAINT ck_migration_reconciliation_sha CHECK (source_checksum ~ '^[0-9a-f]{64}$' AND target_checksum ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_migration_reconciliation_run ON ph18_ops.migration_reconciliation (tenant_id, run_id);
CREATE TRIGGER tg_migration_reconciliation_touch BEFORE UPDATE ON ph18_ops.migration_reconciliation FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_reconciliation_append_only BEFORE UPDATE OR DELETE ON ph18_ops.migration_reconciliation FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.migration_reconciliation', false);
COMMENT ON TABLE ph18_ops.migration_reconciliation IS 'EN-18-48 Báo cáo đối chiếu số lượng và tổng kiểm tra theo loại đối tượng sau lần chạy (FR-00-092): số nguồn, số đích, thiếu, thừa, lệch, tổng kiểm tra hai phía, khớp hay không. Chỉ thêm.';
--rollback DROP TABLE IF EXISTS ph18_ops.migration_reconciliation CASCADE;

--changeset ph18:ph18-0610-credential-reissue-marker splitStatements:false
CREATE TABLE ph18_ops.credential_reissue_marker (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid,
  object_kind     varchar(12) NOT NULL,
  target_module   varchar(8) NOT NULL,
  target_ref      varchar(255) NOT NULL,
  legacy_ref      varchar(255) NOT NULL,
  credential_kind varchar(20) NOT NULL,
  status          varchar(12) NOT NULL DEFAULT 'PENDING',
  notified_at     timestamptz,
  reissued_at     timestamptz,
  reissued_ref    varchar(255),
  waived_reason   varchar(1000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_credential_reissue_marker PRIMARY KEY (id),
  CONSTRAINT uq_credential_reissue_marker_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_credential_reissue_marker_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_credential_reissue_marker UNIQUE (tenant_id, target_module, target_ref, credential_kind),
  CONSTRAINT fk_credential_reissue_marker_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id),
  CONSTRAINT ck_credential_reissue_marker_kind CHECK (object_kind IN ('CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION')),
  CONSTRAINT ck_credential_reissue_marker_module CHECK (target_module IN ('PH01', 'PH02', 'PH03', 'PH10', 'PH19')),
  CONSTRAINT ck_credential_reissue_marker_credential CHECK (credential_kind IN ('OAUTH_CLIENT', 'MTLS_CERTIFICATE', 'BASIC_AUTH', 'APIM_SUBSCRIPTION', 'KAFKA_USER', 'PAYMENT_CHANNEL')),
  CONSTRAINT ck_credential_reissue_marker_status CHECK (status IN ('PENDING', 'NOTIFIED', 'REISSUED', 'WAIVED')),
  CONSTRAINT ck_credential_reissue_marker_reissued CHECK (status <> 'REISSUED' OR reissued_at IS NOT NULL),
  CONSTRAINT ck_credential_reissue_marker_waived CHECK (status <> 'WAIVED' OR coalesce(char_length(btrim(waived_reason)), 0) >= 10)
);
CREATE INDEX ix_credential_reissue_marker_open ON ph18_ops.credential_reissue_marker (tenant_id, status) WHERE status IN ('PENDING', 'NOTIFIED');
CREATE TRIGGER tg_credential_reissue_marker_touch BEFORE UPDATE ON ph18_ops.credential_reissue_marker FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_credential_reissue_marker_immutable BEFORE UPDATE ON ph18_ops.credential_reissue_marker FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('target_module', 'target_ref', 'credential_kind', 'legacy_ref');
CALL ph18_ops.p_enable_rls('ph18_ops.credential_reissue_marker', false);
COMMENT ON TABLE ph18_ops.credential_reissue_marker IS 'EN-18-49 Đánh dấu đối tượng đã di trú cần cấp lại thông tin xác thực ở PH đích (FR-00-093: không di trú bí mật): PH-01 (HTTT), PH-03 (đăng ký cổng), PH-02, PH-10; trạng thái chờ, đã báo, đã cấp lại, miễn. Điều kiện cắt chuyển CREDENTIALS_REISSUED.';
--rollback DROP TABLE IF EXISTS ph18_ops.credential_reissue_marker CASCADE;

--changeset ph18:ph18-0620-parallel-run-group splitStatements:false
CREATE TABLE ph18_ops.parallel_run_group (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  group_code              varchar(32) NOT NULL,
  plan_id                 uuid,
  title                   varchar(255) NOT NULL,
  service_scope           varchar(500) NOT NULL,
  legacy_endpoint_ref     varchar(255) NOT NULL,
  datahub_endpoint_ref    varchar(255) NOT NULL,
  mirror_ratio_percent    numeric(5,2) NOT NULL DEFAULT 100,
  match_threshold_percent numeric(6,3) NOT NULL DEFAULT 99.5,
  status                  varchar(16) NOT NULL DEFAULT 'PARALLEL',
  samples_total           bigint NOT NULL DEFAULT 0,
  samples_matched         bigint NOT NULL DEFAULT 0,
  match_rate              numeric(6,3),
  bridge_ref              varchar(128),
  ph10_cutover_event_id   varchar(255),
  cutover_at              timestamptz,
  rollback_deadline_at    timestamptz,
  rolled_back_at          timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_parallel_run_group PRIMARY KEY (id),
  CONSTRAINT uq_parallel_run_group_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_parallel_run_group_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_parallel_run_group_code UNIQUE (tenant_id, group_code),
  CONSTRAINT fk_parallel_run_group_plan FOREIGN KEY (tenant_id, plan_id) REFERENCES ph18_ops.migration_plan (tenant_id, id),
  CONSTRAINT ck_parallel_run_group_ratio CHECK (mirror_ratio_percent BETWEEN 0 AND 100 AND match_threshold_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_parallel_run_group_status CHECK (status IN ('PARALLEL', 'SHADOW_OK', 'PARTIAL_CUTOVER', 'CUT_OVER', 'ROLLED_BACK')),
  CONSTRAINT ck_parallel_run_group_samples CHECK (samples_matched BETWEEN 0 AND samples_total),
  CONSTRAINT ck_parallel_run_group_shadow_ok CHECK (status <> 'SHADOW_OK' OR match_rate >= match_threshold_percent),
  CONSTRAINT ck_parallel_run_group_cutover CHECK (status NOT IN ('PARTIAL_CUTOVER', 'CUT_OVER') OR (cutover_at IS NOT NULL AND rollback_deadline_at IS NOT NULL AND rollback_deadline_at > cutover_at)),
  CONSTRAINT ck_parallel_run_group_rollback CHECK (status <> 'ROLLED_BACK' OR rolled_back_at IS NOT NULL)
);
CREATE TRIGGER tg_parallel_run_group_touch BEFORE UPDATE ON ph18_ops.parallel_run_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_parallel_run_group_immutable BEFORE UPDATE ON ph18_ops.parallel_run_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('group_code');
CREATE TRIGGER tg_parallel_run_group_fsm_status BEFORE UPDATE ON ph18_ops.parallel_run_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PARALLEL>SHADOW_OK,SHADOW_OK>PARALLEL,SHADOW_OK>PARTIAL_CUTOVER,SHADOW_OK>CUT_OVER,PARTIAL_CUTOVER>CUT_OVER,PARTIAL_CUTOVER>ROLLED_BACK,CUT_OVER>ROLLED_BACK,ROLLED_BACK>PARALLEL');
CALL ph18_ops.p_enable_rls('ph18_ops.parallel_run_group', false);
COMMENT ON TABLE ph18_ops.parallel_run_group IS 'EN-18-50 Nhóm dịch vụ chạy song song và cắt chuyển: phạm vi route, điểm cuối cũ và mới (tên, không thông tin xác thực), tỷ lệ nhân bản lưu lượng APISIX, ngưỡng khớp (18.migration.shadow.match-threshold-percent), tỷ lệ khớp, cầu nối PH-10 (EVT-10-15, 16), mốc cắt chuyển và hạn quay lui 15 phút (18.migration.cutover.rollback-minutes).';
--rollback DROP TABLE IF EXISTS ph18_ops.parallel_run_group CASCADE;

--changeset ph18:ph18-0630-shadow-comparison-sample splitStatements:false
CREATE TABLE ph18_ops.shadow_comparison_sample (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  group_id            uuid NOT NULL,
  sampled_at          timestamptz NOT NULL DEFAULT now(),
  route               varchar(255) NOT NULL,
  request_fingerprint char(64) NOT NULL,
  legacy_status       integer,
  datahub_status      integer,
  legacy_latency_ms   integer,
  datahub_latency_ms  integer,
  legacy_body_sha256  char(64),
  datahub_body_sha256 char(64),
  matched             boolean NOT NULL,
  diff_kind           varchar(8) NOT NULL DEFAULT 'NONE',
  diff_paths          varchar(255)[] NOT NULL DEFAULT '{}',
  trace_id            char(32),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_shadow_comparison_sample PRIMARY KEY (id, sampled_at),
  CONSTRAINT uq_shadow_comparison_sample_tid UNIQUE (tenant_id, id, sampled_at),
  CONSTRAINT ck_shadow_comparison_sample_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_shadow_comparison_sample_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.parallel_run_group (tenant_id, id),
  CONSTRAINT ck_shadow_comparison_sample_fingerprint CHECK (request_fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_shadow_comparison_sample_diff CHECK (diff_kind IN ('NONE', 'STATUS', 'BODY', 'LATENCY', 'ERROR') AND (matched = (diff_kind IN ('NONE', 'LATENCY')))),
  CONSTRAINT ck_shadow_comparison_sample_status_code CHECK ((legacy_status IS NULL OR legacy_status BETWEEN 100 AND 599) AND (datahub_status IS NULL OR datahub_status BETWEEN 100 AND 599))
) PARTITION BY RANGE (sampled_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.shadow_comparison_sample', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_shadow_comparison_sample_group ON ph18_ops.shadow_comparison_sample (tenant_id, group_id, sampled_at DESC);
CREATE INDEX ix_shadow_comparison_sample_miss ON ph18_ops.shadow_comparison_sample (tenant_id, group_id, diff_kind) WHERE NOT matched;
CREATE TRIGGER tg_shadow_comparison_sample_touch BEFORE UPDATE ON ph18_ops.shadow_comparison_sample FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_shadow_comparison_sample_append_only BEFORE UPDATE OR DELETE ON ph18_ops.shadow_comparison_sample FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.shadow_comparison_sample', false);
COMMENT ON TABLE ph18_ops.shadow_comparison_sample IS 'EN-18-51 Mẫu so sánh phản hồi cũ và mới khi APISIX nhân bản lưu lượng sang Datahub: dấu vân tay yêu cầu, mã trạng thái, độ trễ, băm thân hai phía, khớp hay không, loại lệch và đường dẫn trường lệch (không lưu giá trị). Chỉ thêm; phân vùng tháng theo sampled_at, giữ 18.migration.shadow.sample-retention-days.';
--rollback DROP TABLE IF EXISTS ph18_ops.shadow_comparison_sample CASCADE;

--changeset ph18:ph18-0640-cutover-checklist splitStatements:false
CREATE TABLE ph18_ops.cutover_checklist (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  group_id      uuid NOT NULL,
  item_code     varchar(24) NOT NULL,
  description   varchar(500) NOT NULL,
  check_kind    varchar(8) NOT NULL,
  status        varchar(8) NOT NULL DEFAULT 'PENDING',
  evidence      jsonb NOT NULL DEFAULT '{}',
  checked_by    varchar(64),
  checked_at    timestamptz,
  waived_reason varchar(1000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_cutover_checklist PRIMARY KEY (id),
  CONSTRAINT uq_cutover_checklist_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_cutover_checklist_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_cutover_checklist_item UNIQUE (tenant_id, group_id, item_code),
  CONSTRAINT fk_cutover_checklist_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.parallel_run_group (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_cutover_checklist_item CHECK (item_code IN ('DLQ_EMPTY', 'MATCH_RATE', 'RECONCILIATION_MATCHED', 'CREDENTIALS_REISSUED', 'BACKUP_VERIFIED', 'ROLLBACK_READY', 'STAKEHOLDER_SIGNOFF', 'FREEZE_WINDOW')),
  CONSTRAINT ck_cutover_checklist_kind CHECK (check_kind IN ('AUTO', 'MANUAL')),
  CONSTRAINT ck_cutover_checklist_status CHECK (status IN ('PENDING', 'PASSED', 'FAILED', 'WAIVED')),
  CONSTRAINT ck_cutover_checklist_checked CHECK (status = 'PENDING' OR (checked_by IS NOT NULL AND checked_at IS NOT NULL)),
  CONSTRAINT ck_cutover_checklist_waived CHECK (status <> 'WAIVED' OR coalesce(char_length(btrim(waived_reason)), 0) >= 10)
);
CREATE TRIGGER tg_cutover_checklist_touch BEFORE UPDATE ON ph18_ops.cutover_checklist FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_cutover_checklist_immutable BEFORE UPDATE ON ph18_ops.cutover_checklist FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('group_id', 'item_code');
CALL ph18_ops.p_enable_rls('ph18_ops.cutover_checklist', false);
COMMENT ON TABLE ph18_ops.cutover_checklist IS 'EN-18-52 Danh sách kiểm tra cắt chuyển của nhóm dịch vụ: DLQ rỗng, tỷ lệ khớp ≥ ngưỡng, đối chiếu khớp, thông tin xác thực đã cấp lại, sao lưu đã kiểm, sẵn sàng quay lui, xác nhận các bên, cửa sổ đóng băng; tự động hay thủ công, bằng chứng, người kiểm.';
--rollback DROP TABLE IF EXISTS ph18_ops.cutover_checklist CASCADE;

--changeset ph18:ph18-0650-cutover-log splitStatements:false
CREATE TABLE ph18_ops.cutover_log (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  group_id    uuid NOT NULL,
  action      varchar(20) NOT NULL,
  actor       varchar(64) NOT NULL,
  approved_by varchar(64),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  from_status varchar(16),
  to_status   varchar(16),
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_cutover_log PRIMARY KEY (id),
  CONSTRAINT uq_cutover_log_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_cutover_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_cutover_log_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.parallel_run_group (tenant_id, id),
  CONSTRAINT ck_cutover_log_action CHECK (action IN ('START_PARALLEL', 'SHADOW_CONFIRMED', 'PARTIAL_CUTOVER', 'CUTOVER', 'ROLLBACK', 'CHECKLIST_SIGNED', 'NOTE')),
  CONSTRAINT ck_cutover_log_four_eyes CHECK (action NOT IN ('PARTIAL_CUTOVER', 'CUTOVER', 'ROLLBACK') OR (approved_by IS NOT NULL AND approved_by <> actor))
);
CREATE INDEX ix_cutover_log_group ON ph18_ops.cutover_log (tenant_id, group_id, occurred_at);
CREATE TRIGGER tg_cutover_log_touch BEFORE UPDATE ON ph18_ops.cutover_log FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_cutover_log_append_only BEFORE UPDATE OR DELETE ON ph18_ops.cutover_log FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.cutover_log', false);
COMMENT ON TABLE ph18_ops.cutover_log IS 'EN-18-53 Sổ cắt chuyển: bắt đầu chạy song song, xác nhận bóng đạt, cắt chuyển một phần, cắt chuyển, quay lui, ký danh sách kiểm tra, ghi chú; cắt chuyển và quay lui cần người duyệt khác người thực hiện. Chỉ thêm.';
--rollback DROP TABLE IF EXISTS ph18_ops.cutover_log CASCADE;
