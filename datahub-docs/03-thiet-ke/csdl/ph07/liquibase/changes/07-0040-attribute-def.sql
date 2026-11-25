--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0040-attribute-def.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0400-attribute-def
CREATE TABLE ph07_rdm.attribute_def (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  version_id         uuid          NOT NULL,
  code               varchar(64)   NOT NULL,
  label              varchar(255)  NOT NULL,
  data_type          varchar(32)   NOT NULL,
  required           boolean       NOT NULL DEFAULT false,
  unique_in_version  boolean       NOT NULL DEFAULT false,
  max_length         integer,
  pattern            varchar(500),
  min_value          numeric,
  max_value          numeric,
  enum_values        jsonb,
  ref_catalog_code   varchar(64),
  default_value      jsonb,
  sort_order         integer       NOT NULL DEFAULT 0,
  status             varchar(32)   NOT NULL DEFAULT 'ACTIVE',
  queryable          boolean       NOT NULL DEFAULT false,
  searchable         boolean       NOT NULL DEFAULT false,
  classification     varchar(32)   NOT NULL DEFAULT 'PUBLIC',
  description        text,
  legacy_field_id    varchar(64),
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         uuid          NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         uuid          NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_attribute_def PRIMARY KEY (id),
  CONSTRAINT fk_attribute_def_version FOREIGN KEY (version_id, tenant_id)
    REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_attribute_def_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_attribute_def_code CHECK (code ~ '^([a-z][a-z0-9_]{0,63}|[A-Z0-9][A-Z0-9_.-]{0,63})$'),
  CONSTRAINT ck_attribute_def_reserved CHECK (lower(code) NOT IN ('code','name','parent_code','status','sort_order','valid_from','valid_to','depth','path')),
  CONSTRAINT ck_attribute_def_label_nfc CHECK (label IS NFC NORMALIZED),
  CONSTRAINT ck_attribute_def_type CHECK (data_type IN ('STRING','TEXT','INTEGER','DECIMAL','BOOLEAN','DATE','DATETIME','ENUM','CATALOG_REF','URI','EMAIL')),
  CONSTRAINT ck_attribute_def_status CHECK (status IN ('ACTIVE','HIDDEN')),
  -- BR-07-025: không có mức Nhạy cảm trong danh mục.
  CONSTRAINT ck_attribute_def_classification CHECK (classification IN ('PUBLIC','INTERNAL','RESTRICTED')),
  CONSTRAINT ck_attribute_def_enum CHECK ((data_type = 'ENUM') = (enum_values IS NOT NULL)
      AND (enum_values IS NULL OR (jsonb_typeof(enum_values) = 'array' AND jsonb_array_length(enum_values) BETWEEN 1 AND 500))),
  CONSTRAINT ck_attribute_def_ref CHECK ((data_type = 'CATALOG_REF') = (ref_catalog_code IS NOT NULL)),
  CONSTRAINT ck_attribute_def_length CHECK (max_length IS NULL OR (data_type IN ('STRING','TEXT','URI','EMAIL') AND max_length BETWEEN 1 AND 4000)),
  CONSTRAINT ck_attribute_def_minmax CHECK ((min_value IS NULL AND max_value IS NULL)
      OR (data_type IN ('INTEGER','DECIMAL') AND (min_value IS NULL OR max_value IS NULL OR min_value <= max_value))),
  CONSTRAINT ck_attribute_def_query CHECK (NOT queryable OR data_type <> 'TEXT')
);
-- Mã thuộc tính duy nhất trong phiên bản, không phân biệt hoa thường.
CREATE UNIQUE INDEX uq_attribute_def_code ON ph07_rdm.attribute_def (version_id, lower(code));
CREATE INDEX ix_attribute_def_order ON ph07_rdm.attribute_def (version_id, sort_order);
CREATE TRIGGER tg_attribute_def_touch BEFORE UPDATE ON ph07_rdm.attribute_def
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.attribute_def ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.attribute_def FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_attribute_def_select ON ph07_rdm.attribute_def FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_attribute_def_insert ON ph07_rdm.attribute_def FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_attribute_def_update ON ph07_rdm.attribute_def FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_attribute_def_delete ON ph07_rdm.attribute_def FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.attribute_def IS 'EN-07-04 Định nghĩa thuộc tính động theo phiên bản (ADR-050). Giá trị lưu ở catalog_item.attrs. Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.attribute_def.code IS 'Mã thuộc tính: snake_case thường hoặc T-CODE; là khóa trong attrs. Không trùng tên trường hệ thống.';
COMMENT ON COLUMN ph07_rdm.attribute_def.queryable IS 'Cho phép dùng trong DSL truy vấn (BR-07-018).';
COMMENT ON COLUMN ph07_rdm.attribute_def.searchable IS 'Đưa vào tìm kiếm không dấu bên cạnh tên (FR-07-030).';
COMMENT ON COLUMN ph07_rdm.attribute_def.classification IS 'Mức phân loại của thuộc tính; CHECK cấm SENSITIVE (BR-07-025, ERR-07-036). Cột bổ sung ngoài khung.';
COMMENT ON COLUMN ph07_rdm.attribute_def.default_value IS 'Giá trị mặc định dạng JSON đúng kiểu data_type.';
COMMENT ON COLUMN ph07_rdm.attribute_def.legacy_field_id IS 'Khóa hệ cũ (Aita category_fields.id).';
--rollback DROP TABLE IF EXISTS ph07_rdm.attribute_def CASCADE;
