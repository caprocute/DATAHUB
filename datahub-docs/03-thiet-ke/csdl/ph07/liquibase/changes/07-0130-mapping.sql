--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0130-mapping.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1300-code-system
CREATE TABLE ph07_rdm.code_system (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  code              varchar(64)   NOT NULL,
  name              varchar(255)  NOT NULL,
  owner             varchar(255),
  member_system_id  uuid,
  description       text,
  status            varchar(32)   NOT NULL DEFAULT 'ACTIVE',
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        uuid          NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        uuid          NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_code_system PRIMARY KEY (id),
  CONSTRAINT uq_code_system_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_code_system_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_code_system_code CHECK (code ~ '^[A-Z0-9][A-Z0-9_.-]{0,63}$'),
  CONSTRAINT ck_code_system_name_nfc CHECK (name IS NFC NORMALIZED),
  CONSTRAINT ck_code_system_status CHECK (status IN ('ACTIVE','RETIRED'))
);
CREATE TRIGGER tg_code_system_touch BEFORE UPDATE ON ph07_rdm.code_system
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.code_system ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.code_system FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_code_system_select ON ph07_rdm.code_system FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_code_system_insert ON ph07_rdm.code_system FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_code_system_update ON ph07_rdm.code_system FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_code_system_delete ON ph07_rdm.code_system FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.code_system IS 'EN-07-13 Hệ thống mã ngoài (bộ mã riêng của một HTTT hoặc cơ quan). Mẫu RLS S: hệ thống mã toàn quốc lưu COMMON.';
COMMENT ON COLUMN ph07_rdm.code_system.member_system_id IS 'FK logic DD-03 ph01_onboarding.member_system.';
--rollback DROP TABLE IF EXISTS ph07_rdm.code_system CASCADE;

--changeset ph07:ph07-1301-code-mapping
CREATE TABLE ph07_rdm.code_mapping (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  catalog_id      uuid          NOT NULL,
  code_system_id  uuid          NOT NULL,
  item_code       varchar(64)   NOT NULL,
  external_code   varchar(128)  NOT NULL,
  external_label  varchar(255),
  relation        varchar(32)   NOT NULL DEFAULT 'EQUAL',
  provisional     boolean       NOT NULL DEFAULT false,
  reason          text,
  valid_from      date,
  valid_to        date,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      uuid          NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      uuid          NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_code_mapping PRIMARY KEY (id),
  -- catalog_id và code_system_id có thể là của COMMON (tenant ánh xạ hệ
  -- thống mã của mình vào danh mục COMMON) nên dùng FK đơn, không ghép tenant.
  CONSTRAINT fk_code_mapping_catalog FOREIGN KEY (catalog_id) REFERENCES ph07_rdm.catalog (id),
  CONSTRAINT fk_code_mapping_system FOREIGN KEY (code_system_id) REFERENCES ph07_rdm.code_system (id),
  CONSTRAINT ck_code_mapping_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_code_mapping_item CHECK (item_code = upper(item_code)),
  CONSTRAINT ck_code_mapping_relation CHECK (relation IN ('EQUAL','BROADER','NARROWER','RELATED')),
  CONSTRAINT ck_code_mapping_reason CHECK (NOT provisional OR length(btrim(coalesce(reason, ''))) > 0),
  CONSTRAINT ck_code_mapping_valid CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from),
  -- BR-07-023: trong một hệ thống mã và một khoảng hiệu lực, mỗi mã ngoài
  -- trỏ tới đúng một mã danh mục (vi phạm trả SQLSTATE 23P01 → ERR-07-033).
  CONSTRAINT ex_code_mapping_external EXCLUDE USING gist (
      tenant_id WITH =, catalog_id WITH =, code_system_id WITH =, external_code WITH =,
      daterange(valid_from, valid_to, '[)') WITH &&)
);
-- Chiều xuôi: mã danh mục → mã ngoài (API-07-070 direction=toExternal).
CREATE INDEX ix_code_mapping_item ON ph07_rdm.code_mapping (catalog_id, code_system_id, item_code);
-- Chiều ngược dùng index của ràng buộc loại trừ (external_code WITH =).
CREATE INDEX ix_code_mapping_system ON ph07_rdm.code_mapping (code_system_id);
CREATE TRIGGER tg_code_mapping_touch BEFORE UPDATE ON ph07_rdm.code_mapping
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.code_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.code_mapping FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_code_mapping_select ON ph07_rdm.code_mapping FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_code_mapping_insert ON ph07_rdm.code_mapping FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_code_mapping_update ON ph07_rdm.code_mapping FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_code_mapping_delete ON ph07_rdm.code_mapping FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.code_mapping IS 'EN-07-14 Ánh xạ mã danh mục ↔ mã ngoài, có khoảng hiệu lực (FR-07-041…043). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.code_mapping.provisional IS 'Ánh xạ tạm thời; bắt buộc có reason (BR-07-024).';
--rollback DROP TABLE IF EXISTS ph07_rdm.code_mapping CASCADE;
