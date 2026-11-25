--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0110-sync.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1100-sync-source
CREATE TABLE ph07_rdm.sync_source (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  catalog_id       uuid          NOT NULL,
  provider         varchar(32)   NOT NULL DEFAULT 'NDXP_DMDC',
  remote_code      varchar(128)  NOT NULL,
  remote_name      varchar(255),
  schedule_cron    varchar(64)   NOT NULL DEFAULT '0 0 1 * * *',
  auto_apply       boolean       NOT NULL DEFAULT true,
  enabled          boolean       NOT NULL DEFAULT true,
  last_run_id      uuid,
  last_success_at  timestamptz,
  remote_version   varchar(128),
  field_mapping    jsonb         NOT NULL DEFAULT '{}'::jsonb,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       uuid          NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       uuid          NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_source PRIMARY KEY (id),
  CONSTRAINT uq_sync_source_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_sync_source_catalog UNIQUE (catalog_id, provider),
  CONSTRAINT fk_sync_source_catalog FOREIGN KEY (catalog_id, tenant_id) REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_sync_source_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_sync_source_provider CHECK (provider IN ('NDXP_DMDC')),
  CONSTRAINT ck_sync_source_mapping CHECK (jsonb_typeof(field_mapping) = 'object')
);
CREATE INDEX ix_sync_source_enabled ON ph07_rdm.sync_source (tenant_id) WHERE enabled;
ALTER TABLE ph07_rdm.sync_source SET (fillfactor = 90);
CREATE TRIGGER tg_sync_source_touch BEFORE UPDATE ON ph07_rdm.sync_source
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.sync_source ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.sync_source FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_sync_source_select ON ph07_rdm.sync_source FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_source_insert ON ph07_rdm.sync_source FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_source_update ON ph07_rdm.sync_source FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_source_delete ON ph07_rdm.sync_source FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.sync_source IS 'EN-07-10 Nguồn đồng bộ danh mục quốc gia qua PH-14 (ADR-057). Mẫu RLS P.';
COMMENT ON COLUMN ph07_rdm.sync_source.schedule_cron IS 'Biểu thức cron Spring 6 trường; mặc định 01:00 hằng ngày (giờ Việt Nam).';
COMMENT ON COLUMN ph07_rdm.sync_source.field_mapping IS 'Ánh xạ trường nguồn sang thuộc tính: {"remoteField":"attrCode"}.';
--rollback DROP TABLE IF EXISTS ph07_rdm.sync_source CASCADE;

--changeset ph07:ph07-1101-sync-run
CREATE TABLE ph07_rdm.sync_run (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  source_id          uuid          NOT NULL,
  trigger            varchar(32)   NOT NULL,
  status             varchar(32)   NOT NULL DEFAULT 'RUNNING',
  remote_version     varchar(128),
  diff_stats         jsonb,
  has_breaking       boolean       NOT NULL DEFAULT false,
  result_version_id  uuid,
  confirmed_by       uuid,
  confirmed_at       timestamptz,
  error_message      text,
  started_at         timestamptz   NOT NULL DEFAULT now(),
  finished_at        timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         uuid          NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         uuid          NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_run PRIMARY KEY (id),
  CONSTRAINT uq_sync_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_sync_run_source FOREIGN KEY (source_id, tenant_id) REFERENCES ph07_rdm.sync_source (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_sync_run_result FOREIGN KEY (result_version_id, tenant_id) REFERENCES ph07_rdm.catalog_version (id, tenant_id),
  CONSTRAINT ck_sync_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_sync_run_trigger CHECK (trigger IN ('SCHEDULE','MANUAL')),
  CONSTRAINT ck_sync_run_status CHECK (status IN ('RUNNING','NO_CHANGE','APPLIED','PENDING_CONFIRMATION','REJECTED','FAILED')),
  CONSTRAINT ck_sync_run_finished CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_sync_run_failed CHECK (status <> 'FAILED' OR error_message IS NOT NULL)
);
-- Một nguồn chỉ có một lần chạy RUNNING tại một thời điểm.
CREATE UNIQUE INDEX uq_sync_run_running ON ph07_rdm.sync_run (source_id) WHERE status = 'RUNNING';
CREATE INDEX ix_sync_run_source ON ph07_rdm.sync_run (source_id, started_at DESC);
CREATE INDEX ix_sync_run_pending ON ph07_rdm.sync_run (tenant_id) WHERE status = 'PENDING_CONFIRMATION';
ALTER TABLE ph07_rdm.sync_run SET (fillfactor = 90);
CREATE TRIGGER tg_sync_run_touch BEFORE UPDATE ON ph07_rdm.sync_run
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.sync_run ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.sync_run FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_sync_run_select ON ph07_rdm.sync_run FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_run_insert ON ph07_rdm.sync_run FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_run_update ON ph07_rdm.sync_run FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_run_delete ON ph07_rdm.sync_run FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.sync_run IS 'EN-07-11 Một lần chạy đồng bộ quốc gia. Mẫu RLS P.';
--rollback DROP TABLE IF EXISTS ph07_rdm.sync_run CASCADE;

--changeset ph07:ph07-1102-sync-source-last-run-fk
ALTER TABLE ph07_rdm.sync_source
  ADD CONSTRAINT fk_sync_source_last_run FOREIGN KEY (last_run_id, tenant_id)
  REFERENCES ph07_rdm.sync_run (id, tenant_id) ON DELETE SET NULL (last_run_id);
--rollback ALTER TABLE ph07_rdm.sync_source DROP CONSTRAINT IF EXISTS fk_sync_source_last_run;

--changeset ph07:ph07-1103-sync-change
-- Chỉ-thêm: ngoại lệ D00-01 §5.1 (không có updated_*/version).
CREATE TABLE ph07_rdm.sync_change (
  id           uuid          NOT NULL,
  tenant_id    varchar(16)   NOT NULL,
  run_id       uuid          NOT NULL,
  item_code    varchar(64),
  change_type  varchar(32)   NOT NULL,
  breaking     boolean       NOT NULL DEFAULT false,
  before       jsonb,
  after        jsonb,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_sync_change PRIMARY KEY (id),
  CONSTRAINT fk_sync_change_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph07_rdm.sync_run (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_sync_change_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_sync_change_type CHECK (change_type IN ('ADDED','CHANGED','REMOVED','ATTRIBUTE_ADDED','ATTRIBUTE_REMOVED','ATTRIBUTE_TYPE_CHANGED')),
  CONSTRAINT ck_sync_change_item CHECK (change_type LIKE 'ATTRIBUTE_%' OR item_code IS NOT NULL)
);
CREATE INDEX ix_sync_change_run ON ph07_rdm.sync_change (run_id, breaking DESC, item_code);
ALTER TABLE ph07_rdm.sync_change ALTER COLUMN before SET COMPRESSION lz4;
ALTER TABLE ph07_rdm.sync_change ALTER COLUMN after SET COMPRESSION lz4;
ALTER TABLE ph07_rdm.sync_change ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.sync_change FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_sync_change_select ON ph07_rdm.sync_change FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_change_insert ON ph07_rdm.sync_change FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_change_delete ON ph07_rdm.sync_change FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.sync_change IS 'EN-07-12 Chi tiết khác biệt của một lần đồng bộ. Mẫu RLS P. Giữ 3 năm.';
--rollback DROP TABLE IF EXISTS ph07_rdm.sync_change CASCADE;
