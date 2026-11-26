--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0070-admin-sync.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0700-portal-setting
CREATE TABLE ph15_portal.portal_setting (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  portal_name         varchar(255)  NOT NULL,
  greeting            varchar(500),
  logo_file_id        uuid,
  links               jsonb         NOT NULL DEFAULT '[]',
  footer_md           varchar(2000),
  param_cache         jsonb         NOT NULL DEFAULT '{}',
  param_synced_at     timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_portal_setting PRIMARY KEY (id),
  CONSTRAINT uq_portal_setting_tenant UNIQUE (tenant_id),
  CONSTRAINT fk_portal_setting_logo FOREIGN KEY (logo_file_id, tenant_id) REFERENCES ph15_portal.content_attachment (id, tenant_id),
  CONSTRAINT ck_portal_setting_links CHECK (jsonb_typeof(links) = 'array' AND jsonb_array_length(links) <= 12),
  CONSTRAINT ck_portal_setting_params CHECK (jsonb_typeof(param_cache) = 'object')
);
CREATE TRIGGER tg_portal_setting_touch BEFORE UPDATE ON ph15_portal.portal_setting FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.portal_setting');
COMMENT ON TABLE ph15_portal.portal_setting IS 'EN-15-17 Nhận diện cổng theo tenant, một dòng mỗi tenant: tên, lời chào, logo, liên kết, chân trang (FR-15-056, BR-15-032: không đổi màu, phông, token).';
COMMENT ON COLUMN ph15_portal.portal_setting.param_cache IS 'Bản sao các tham số 15.* đọc từ PH-18 (nguồn chuẩn ở PH-18); cổng chỉ ghi đệm để chạy khi PH-18 chậm (FR-15-057).';
--rollback DROP TABLE IF EXISTS ph15_portal.portal_setting CASCADE;

--changeset ph15:ph15-0710-sync-state
CREATE TABLE ph15_portal.sync_state (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  state               varchar(8)    NOT NULL DEFAULT 'IDLE',
  updated_since       timestamptz,
  last_success_at     timestamptz,
  last_event_at       timestamptz,
  lag_seconds         integer       NOT NULL DEFAULT 0,
  last_error          varchar(1000),
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_sync_state PRIMARY KEY (tenant_id),
  CONSTRAINT ck_sync_state_state CHECK (state IN ('IDLE', 'RUNNING', 'FAILED', 'STALE')),
  CONSTRAINT ck_sync_state_lag CHECK (lag_seconds >= 0)
);
CALL ph15_portal.p_enable_rls('ph15_portal.sync_state');
COMMENT ON TABLE ph15_portal.sync_state IS 'Trạng thái đồng bộ danh mục của tenant (IDLE, RUNNING, FAILED, STALE) và con trỏ updatedSince; phát EVT-15-14 khi đổi (FR-15-001, BR-15-033).';
--rollback DROP TABLE IF EXISTS ph15_portal.sync_state CASCADE;

--changeset ph15:ph15-0720-sync-run
CREATE TABLE ph15_portal.sync_run (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  kind                varchar(12)   NOT NULL,
  status              varchar(10)   NOT NULL DEFAULT 'RUNNING',
  started_at          timestamptz   NOT NULL DEFAULT now(),
  finished_at         timestamptz,
  items_upserted      integer       NOT NULL DEFAULT 0,
  items_removed       integer       NOT NULL DEFAULT 0,
  items_failed        integer       NOT NULL DEFAULT 0,
  mismatch_count      integer       NOT NULL DEFAULT 0,
  content_git_source_id       uuid,
  error_code          varchar(10),
  error_detail        varchar(1000),
  report              jsonb         NOT NULL DEFAULT '{}',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_run PRIMARY KEY (id),
  CONSTRAINT fk_sync_run_git FOREIGN KEY (content_git_source_id, tenant_id) REFERENCES ph15_portal.content_git_source (id, tenant_id),
  CONSTRAINT ck_sync_run_report CHECK (jsonb_typeof(report) = 'object'),
  CONSTRAINT ck_sync_run_kind CHECK (kind IN ('INCREMENTAL', 'FULL', 'RECONCILE', 'GIT')),
  CONSTRAINT ck_sync_run_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
  CONSTRAINT ck_sync_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-15-[0-9]{3}$'),
  CONSTRAINT ck_sync_run_done CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT ck_sync_run_git CHECK (kind <> 'GIT' OR content_git_source_id IS NOT NULL)
);
CREATE UNIQUE INDEX uq_sync_run_running ON ph15_portal.sync_run (tenant_id, kind) WHERE status = 'RUNNING';
CREATE INDEX ix_sync_run_recent ON ph15_portal.sync_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_sync_run_touch BEFORE UPDATE ON ph15_portal.sync_run FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.sync_run');
COMMENT ON COLUMN ph15_portal.sync_run.report IS 'Chi tiết lệch khi kind = RECONCILE (apiCode, loại lệch, sourceVersion hai phía), thay cho bảng reconciliation_report của SDD.';
COMMENT ON TABLE ph15_portal.sync_run IS 'EN-15-18 Lần đồng bộ: gia tăng, đầy đủ, đối soát với PH-02, nhập Git (FR-15-001, 018, 061). Mỗi loại chỉ một lần RUNNING mỗi tenant.';
--rollback DROP TABLE IF EXISTS ph15_portal.sync_run CASCADE;

--changeset ph15:ph15-0730-migration-batch
CREATE TABLE ph15_portal.content_migration (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  package_file_id     uuid          NOT NULL,
  status              varchar(8)    NOT NULL DEFAULT 'RUNNING',
  pages_total         integer       NOT NULL DEFAULT 0,
  pages_imported      integer       NOT NULL DEFAULT 0,
  pages_skipped       integer       NOT NULL DEFAULT 0,
  report              jsonb         NOT NULL DEFAULT '{}',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_content_migration PRIMARY KEY (id),
  CONSTRAINT uq_content_migration_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_content_migration_file FOREIGN KEY (package_file_id, tenant_id) REFERENCES ph15_portal.content_attachment (id, tenant_id),
  CONSTRAINT ck_content_migration_status CHECK (status IN ('RUNNING', 'PREVIEW', 'APPLIED', 'FAILED')),
  CONSTRAINT ck_content_migration_counts CHECK (pages_imported + pages_skipped <= pages_total),
  CONSTRAINT ck_content_migration_report CHECK (jsonb_typeof(report) = 'object')
);
CREATE UNIQUE INDEX uq_content_migration_running ON ph15_portal.content_migration (tenant_id) WHERE status = 'RUNNING';
CREATE TRIGGER tg_content_migration_touch BEFORE UPDATE ON ph15_portal.content_migration FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.content_migration');
COMMENT ON TABLE ph15_portal.content_migration IS 'Lô di trú nội dung portal Gravitee cũ (FR-15-062): id là migrationId; chỉ một lô RUNNING mỗi tenant (ERR-15-035).';
--rollback DROP TABLE IF EXISTS ph15_portal.content_migration CASCADE;

--changeset ph15:ph15-0740-legacy-mapping
CREATE TABLE ph15_portal.legacy_mapping (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  legacy_system       varchar(24)   NOT NULL DEFAULT 'GRAVITEE_PORTAL',
  legacy_key          varchar(255)  NOT NULL,
  target_type         varchar(12)   NOT NULL,
  target_id           uuid          NOT NULL,
  source_hash         char(64)      NOT NULL,
  migration_id        uuid          NOT NULL,
  mapped_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_legacy_mapping PRIMARY KEY (tenant_id, legacy_system, legacy_key),
  CONSTRAINT fk_legacy_mapping_batch FOREIGN KEY (migration_id, tenant_id) REFERENCES ph15_portal.content_migration (id, tenant_id),
  CONSTRAINT ck_legacy_mapping_system CHECK (legacy_system IN ('GRAVITEE_PORTAL', 'BACKSTAGE')),
  CONSTRAINT ck_legacy_mapping_type CHECK (target_type IN ('PAGE', 'PAGE_VERSION', 'FILE')),
  CONSTRAINT ck_legacy_mapping_hash CHECK (source_hash ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_legacy_mapping_target ON ph15_portal.legacy_mapping (tenant_id, target_type, target_id);
CREATE INDEX ix_legacy_mapping_batch ON ph15_portal.legacy_mapping (tenant_id, migration_id);
CALL ph15_portal.p_enable_rls('ph15_portal.legacy_mapping');
COMMENT ON TABLE ph15_portal.legacy_mapping IS 'Ánh xạ khóa trang, tài liệu của portal hệ cũ sang đối tượng mới; chạy lại cùng migrationId không tạo trùng, băm khác thì cập nhật (FR-15-062, ADR-049).';
--rollback DROP TABLE IF EXISTS ph15_portal.legacy_mapping CASCADE;

--changeset ph15:ph15-0741-legacy-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_legacy_mapping_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.target_id IS DISTINCT FROM OLD.target_id OR NEW.target_type IS DISTINCT FROM OLD.target_type THEN
    RAISE EXCEPTION 'target_id của legacy_mapping không đổi được' USING ERRCODE = 'P1505';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_legacy_mapping_guard BEFORE UPDATE ON ph15_portal.legacy_mapping FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_legacy_mapping_guard();
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_legacy_mapping_guard() CASCADE;
