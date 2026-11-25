--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0090-import-job.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0900-import-job
CREATE TABLE ph07_rdm.import_job (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  job_type            varchar(32)   NOT NULL,
  catalog_id          uuid,
  version_id          uuid,
  mode                varchar(32),
  format              varchar(32)   NOT NULL,
  template            varchar(32)   NOT NULL DEFAULT 'STANDARD',
  status              varchar(32)   NOT NULL DEFAULT 'QUEUED',
  file_id             uuid,
  file_name           varchar(255),
  file_sha256         char(64),
  encoding            varchar(32),
  total_rows          integer       NOT NULL DEFAULT 0,
  valid_rows          integer       NOT NULL DEFAULT 0,
  error_rows          integer       NOT NULL DEFAULT 0,
  column_mapping      jsonb,
  options             jsonb         NOT NULL DEFAULT '{}'::jsonb,
  result_file_id      uuid,
  draft_lock_version  integer,
  expires_at          timestamptz,
  idempotency_key     varchar(128),
  error_message       text,
  started_at          timestamptz,
  finished_at         timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          uuid          NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          uuid          NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_import_job PRIMARY KEY (id),
  CONSTRAINT uq_import_job_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_import_job_catalog FOREIGN KEY (catalog_id, tenant_id) REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT fk_import_job_version FOREIGN KEY (version_id, tenant_id) REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE SET NULL (version_id),
  CONSTRAINT fk_import_job_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph07_rdm.file_object (id, tenant_id),
  CONSTRAINT fk_import_job_result FOREIGN KEY (result_file_id, tenant_id) REFERENCES ph07_rdm.file_object (id, tenant_id),
  CONSTRAINT ck_import_job_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_import_job_type CHECK (job_type IN ('IMPORT','EXPORT')),
  CONSTRAINT ck_import_job_mode CHECK ((job_type = 'IMPORT' AND mode IN ('UPSERT','REPLACE','APPEND','CREATE_CATALOG'))
      OR (job_type = 'EXPORT' AND mode IS NULL)),
  CONSTRAINT ck_import_job_format CHECK (format IN ('XLSX','CSV','JSON')),
  CONSTRAINT ck_import_job_template CHECK (template IN ('STANDARD','LEGACY_AITA')),
  CONSTRAINT ck_import_job_status CHECK (
       (job_type = 'IMPORT' AND status IN ('QUEUED','SCANNING','PARSING','VALIDATED','COMMITTING','COMMITTED','FAILED','CANCELLED','EXPIRED'))
    OR (job_type = 'EXPORT' AND status IN ('QUEUED','RUNNING','COMPLETED','FAILED','EXPIRED'))),
  CONSTRAINT ck_import_job_encoding CHECK (encoding IS NULL OR encoding IN ('UTF-8','UTF-8-BOM','UTF-16LE','UTF-16BE')),
  CONSTRAINT ck_import_job_rows CHECK (total_rows >= 0 AND valid_rows >= 0 AND error_rows >= 0 AND valid_rows + error_rows <= total_rows),
  CONSTRAINT ck_import_job_catalog CHECK (catalog_id IS NOT NULL OR mode = 'CREATE_CATALOG'),
  CONSTRAINT ck_import_job_file CHECK (job_type = 'EXPORT' OR file_id IS NOT NULL)
);
CREATE UNIQUE INDEX uq_import_job_idem ON ph07_rdm.import_job (tenant_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX ix_import_job_history ON ph07_rdm.import_job (tenant_id, created_at DESC);
CREATE INDEX ix_import_job_catalog ON ph07_rdm.import_job (catalog_id, created_at DESC);
CREATE INDEX ix_import_job_expires ON ph07_rdm.import_job (expires_at) WHERE status IN ('VALIDATED','COMPLETED');
ALTER TABLE ph07_rdm.import_job SET (fillfactor = 85);
CREATE TRIGGER tg_import_job_touch BEFORE UPDATE ON ph07_rdm.import_job
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.import_job ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.import_job FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_import_job_select ON ph07_rdm.import_job FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_import_job_insert ON ph07_rdm.import_job FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_import_job_update ON ph07_rdm.import_job FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_import_job_delete ON ph07_rdm.import_job FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.import_job IS 'EN-07-08 Tác vụ nhập/xuất tệp (ADR-056). Mẫu RLS P; tác vụ trên danh mục COMMON mang tenant_id COMMON do PLATFORM thực hiện.';
COMMENT ON COLUMN ph07_rdm.import_job.status IS 'IMPORT: QUEUED→SCANNING→PARSING→VALIDATED→COMMITTING→COMMITTED (hoặc FAILED/CANCELLED/EXPIRED). EXPORT: QUEUED→RUNNING→COMPLETED (hoặc FAILED/EXPIRED).';
COMMENT ON COLUMN ph07_rdm.import_job.draft_lock_version IS 'Giá trị catalog_version.version lúc phân tích; commit chỉ khi còn bằng (BR-07-016). Cột bổ sung ngoài khung.';
COMMENT ON COLUMN ph07_rdm.import_job.expires_at IS 'Hạn xem trước (24 giờ, BR-07-016) hoặc hạn tải tệp xuất.';
--rollback DROP TABLE IF EXISTS ph07_rdm.import_job CASCADE;
