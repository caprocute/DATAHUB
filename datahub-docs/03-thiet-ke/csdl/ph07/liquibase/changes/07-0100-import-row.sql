--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0100-import-row.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1000-import-row
-- Bảng tạm, phân vùng theo ngày (created_at = created_at của import_job, do
-- ứng dụng đặt, để mọi dòng của một tác vụ nằm trong một phân vùng). Xóa dữ
-- liệu quá 7 ngày bằng DROP phân vùng thay vì DELETE (không phình bảng).
-- Ngoại lệ D00-01 §5.1: không có created_by/updated_*/version.
CREATE TABLE ph07_rdm.import_row (
  id          uuid          NOT NULL,
  tenant_id   varchar(16)   NOT NULL,
  job_id      uuid          NOT NULL,
  row_no      integer       NOT NULL,
  item_code   varchar(64),
  payload     jsonb         NOT NULL,
  action      varchar(32),
  valid       boolean       NOT NULL,
  errors      jsonb,
  created_at  timestamptz   NOT NULL,
  CONSTRAINT pk_import_row PRIMARY KEY (id, created_at),
  CONSTRAINT uq_import_row_no UNIQUE (job_id, row_no, created_at),
  CONSTRAINT fk_import_row_job FOREIGN KEY (job_id, tenant_id)
    REFERENCES ph07_rdm.import_job (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_import_row_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_import_row_action CHECK (action IS NULL OR action IN ('INSERT','UPDATE','DEPRECATE','UNCHANGED','DELETE')),
  CONSTRAINT ck_import_row_errors CHECK (errors IS NULL OR jsonb_typeof(errors) = 'array'),
  CONSTRAINT ck_import_row_valid CHECK (valid OR errors IS NOT NULL)
) PARTITION BY RANGE (created_at);
-- Lọc dòng lỗi của một tác vụ (API-07-035 valid=false).
CREATE INDEX ix_import_row_invalid ON ph07_rdm.import_row (job_id, row_no) WHERE NOT valid;
CREATE TABLE ph07_rdm.import_row_default PARTITION OF ph07_rdm.import_row DEFAULT;
ALTER TABLE ph07_rdm.import_row ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.import_row FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_import_row_select ON ph07_rdm.import_row FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_import_row_insert ON ph07_rdm.import_row FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_import_row_update ON ph07_rdm.import_row FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_import_row_delete ON ph07_rdm.import_row FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.import_row IS 'EN-07-09 Dòng tạm của tác vụ nhập (xem trước, lỗi theo dòng). Phân vùng RANGE theo ngày; giữ 7 ngày. Mẫu RLS P. Phân vùng con không cấp quyền cho ph07_app nên không truy cập trực tiếp được (RLS chỉ áp qua bảng cha).';
COMMENT ON COLUMN ph07_rdm.import_row.payload IS 'Giá trị đã chuẩn hóa của dòng theo mã cột {"MA":…,"TEN":…,"attrs":{…}}.';
COMMENT ON COLUMN ph07_rdm.import_row.errors IS 'Mảng lỗi [{"column":"…","code":"ERR-07-009","message":"…"}].';
COMMENT ON COLUMN ph07_rdm.import_row.created_at IS 'Bằng import_job.created_at; là khóa phân vùng.';
--rollback DROP TABLE IF EXISTS ph07_rdm.import_row CASCADE;
