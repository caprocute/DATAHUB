--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0080-file-object.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0800-file-object
CREATE TABLE ph07_rdm.file_object (
  id             uuid          NOT NULL,
  tenant_id      varchar(16)   NOT NULL,
  bucket         varchar(64)   NOT NULL,
  object_key     text          NOT NULL,
  file_name      varchar(255)  NOT NULL,
  content_type   varchar(255)  NOT NULL,
  size_bytes     bigint        NOT NULL,
  sha256         char(64)      NOT NULL,
  scan_status    varchar(32)   NOT NULL DEFAULT 'PENDING',
  data_class_id  uuid          NOT NULL,
  purpose        varchar(32)   NOT NULL,
  expires_at     timestamptz,
  created_at     timestamptz   NOT NULL DEFAULT now(),
  created_by     uuid          NOT NULL,
  updated_at     timestamptz   NOT NULL DEFAULT now(),
  updated_by     uuid          NOT NULL,
  version        integer       NOT NULL DEFAULT 0,
  deleted_at     timestamptz,
  CONSTRAINT pk_file_object PRIMARY KEY (id),
  CONSTRAINT uq_file_object_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_file_object_key UNIQUE (bucket, object_key),
  CONSTRAINT ck_file_object_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_file_object_size CHECK (size_bytes >= 0),
  CONSTRAINT ck_file_object_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_file_object_scan CHECK (scan_status IN ('PENDING','CLEAN','INFECTED')),
  CONSTRAINT ck_file_object_purpose CHECK (purpose IN ('IMPORT_SOURCE','EXPORT_RESULT','ERROR_REPORT','SNAPSHOT','IMPORT_TEMPLATE'))
);
CREATE INDEX ix_file_object_expires ON ph07_rdm.file_object (expires_at) WHERE expires_at IS NOT NULL AND deleted_at IS NULL;
CREATE TRIGGER tg_file_object_touch BEFORE UPDATE ON ph07_rdm.file_object
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.file_object ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.file_object FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_file_object_select ON ph07_rdm.file_object FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_file_object_insert ON ph07_rdm.file_object FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_file_object_update ON ph07_rdm.file_object FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_file_object_delete ON ph07_rdm.file_object FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.file_object IS 'EN-07-19 Tệp (theo DD-12): siêu dữ liệu tệp nhập, tệp xuất, báo cáo lỗi, ảnh chụp; nội dung ở Garage. Mẫu RLS P.';
COMMENT ON COLUMN ph07_rdm.file_object.content_type IS 'Kiểu MIME xác định theo nội dung (không tin phần mở rộng). varchar(255) thay T-CODE vì MIME xlsx dài 65 ký tự.';
COMMENT ON COLUMN ph07_rdm.file_object.scan_status IS 'PENDING, CLEAN, INFECTED; chỉ CLEAN mới được phân tích.';
COMMENT ON COLUMN ph07_rdm.file_object.data_class_id IS 'FK logic DD-08 ph09_privacy.data_class.';
COMMENT ON COLUMN ph07_rdm.file_object.purpose IS 'Mục đích tệp; cột bổ sung ngoài DD-12 phục vụ chính sách dọn dẹp.';
--rollback DROP TABLE IF EXISTS ph07_rdm.file_object CASCADE;
