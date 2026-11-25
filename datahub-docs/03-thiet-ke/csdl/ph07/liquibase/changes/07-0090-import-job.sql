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
  status              varchar(32)   NOT NULL,
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
  lease_owner         varchar(128),
  lease_until         timestamptz,
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
  CONSTRAINT ck_import_job_type CHECK (job_type IN ('IMPORT','EXPORT','MIGRATION','PROPOSAL')),
  CONSTRAINT ck_import_job_mode CHECK ((job_type = 'IMPORT' AND mode IN ('UPSERT','REPLACE','APPEND','CREATE_CATALOG','MAPPING','ADMIN_UNIT_CONVERT'))
      OR (job_type <> 'IMPORT' AND mode IS NULL)),
  CONSTRAINT ck_import_job_format CHECK (format IN ('XLSX','CSV','JSON')),
  CONSTRAINT ck_import_job_template CHECK (template IN ('STANDARD','LEGACY_AITA')),
  CONSTRAINT ck_import_job_status CHECK (
       (job_type IN ('IMPORT','MIGRATION') AND status IN ('UPLOADED','SCANNING','PARSING','VALIDATING','VALIDATED','COMMITTING','COMMITTED','FAILED','CANCELLED','EXPIRED'))
    OR (job_type = 'EXPORT' AND status IN ('QUEUED','RUNNING','COMPLETED','FAILED','EXPIRED'))
    OR (job_type = 'PROPOSAL' AND status IN ('SUBMITTED','ACCEPTED','REJECTED','UNKNOWN'))),
  CONSTRAINT ck_import_job_encoding CHECK (encoding IS NULL OR encoding IN ('UTF-8','UTF-8-BOM','UTF-16LE','UTF-16BE')),
  CONSTRAINT ck_import_job_rows CHECK (total_rows >= 0 AND valid_rows >= 0 AND error_rows >= 0 AND valid_rows + error_rows <= total_rows),
  CONSTRAINT ck_import_job_catalog CHECK (catalog_id IS NOT NULL OR mode = 'CREATE_CATALOG' OR job_type = 'MIGRATION'),
  CONSTRAINT ck_import_job_file CHECK (job_type <> 'IMPORT' OR file_id IS NOT NULL),
  CONSTRAINT ck_import_job_lease CHECK ((lease_owner IS NULL) = (lease_until IS NULL))
);
CREATE UNIQUE INDEX uq_import_job_idem ON ph07_rdm.import_job (tenant_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX ix_import_job_history ON ph07_rdm.import_job (tenant_id, created_at DESC);
CREATE INDEX ix_import_job_catalog ON ph07_rdm.import_job (catalog_id, created_at DESC);
CREATE INDEX ix_import_job_expires ON ph07_rdm.import_job (expires_at) WHERE status IN ('VALIDATED','COMPLETED');
CREATE INDEX ix_import_job_queue ON ph07_rdm.import_job (created_at)
  WHERE status IN ('UPLOADED','SCANNING','PARSING','VALIDATING','COMMITTING','QUEUED','RUNNING');
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
-- Nhận tác vụ liên tenant: chỉ vai trò ph07_worker, chỉ các cột hàng đợi (GRANT cột ở 07-0900).
CREATE POLICY rls_import_job_worker_select ON ph07_rdm.import_job FOR SELECT TO ph07_worker
  USING (status IN ('UPLOADED','SCANNING','PARSING','VALIDATING','COMMITTING','QUEUED','RUNNING'));
CREATE POLICY rls_import_job_worker_update ON ph07_rdm.import_job FOR UPDATE TO ph07_worker
  USING (status IN ('UPLOADED','SCANNING','PARSING','VALIDATING','COMMITTING','QUEUED','RUNNING'))
  WITH CHECK (status IN ('UPLOADED','SCANNING','PARSING','VALIDATING','COMMITTING','QUEUED','RUNNING'));
COMMENT ON TABLE ph07_rdm.import_job IS 'EN-07-08 Tác vụ nhập/xuất tệp (ADR-056). Mẫu RLS P; tác vụ trên danh mục COMMON mang tenant_id COMMON do PLATFORM thực hiện.';
COMMENT ON COLUMN ph07_rdm.import_job.status IS 'IMPORT, MIGRATION: UPLOADED→SCANNING→PARSING→VALIDATING→VALIDATED→COMMITTING→COMMITTED (hoặc FAILED/CANCELLED/EXPIRED), theo FRS §4.14. EXPORT: QUEUED→RUNNING→COMPLETED (hoặc FAILED/EXPIRED). PROPOSAL: SUBMITTED/ACCEPTED/REJECTED/UNKNOWN.';
COMMENT ON COLUMN ph07_rdm.import_job.draft_lock_version IS 'Giá trị catalog_version.version lúc phân tích; commit chỉ khi còn bằng (BR-07-016). Cột bổ sung ngoài khung.';
COMMENT ON COLUMN ph07_rdm.import_job.lease_owner IS 'Pod đang xử lý tác vụ (hàng đợi trong CSDL, D03-02-PH07 §4.7.3).';
COMMENT ON COLUMN ph07_rdm.import_job.lease_until IS 'Hạn thuê; quá hạn thì pod khác nhận lại tác vụ. Gia hạn mỗi 30 giây.';
COMMENT ON COLUMN ph07_rdm.import_job.job_type IS 'IMPORT, EXPORT; MIGRATION là chạy thử/chạy thật di trú Aita (FR-07-051); PROPOSAL là đề xuất bổ sung lên NDXP (FR-07-039, Q07-07).';
COMMENT ON COLUMN ph07_rdm.import_job.expires_at IS 'Hạn xem trước (24 giờ, BR-07-016) hoặc hạn tải tệp xuất.';
--rollback DROP TABLE IF EXISTS ph07_rdm.import_job CASCADE;
