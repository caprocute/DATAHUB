--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0010-catalog-group.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0100-catalog-group
CREATE TABLE ph07_rdm.catalog_group (
  id           uuid         NOT NULL,
  tenant_id    varchar(16)  NOT NULL,
  code         varchar(64)  NOT NULL,
  name         varchar(255) NOT NULL,
  parent_id    uuid,
  sort_order   integer      NOT NULL DEFAULT 0,
  description  text,
  created_at   timestamptz  NOT NULL DEFAULT now(),
  created_by   uuid         NOT NULL,
  updated_at   timestamptz  NOT NULL DEFAULT now(),
  updated_by   uuid         NOT NULL,
  version      integer      NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_group PRIMARY KEY (id),
  CONSTRAINT uq_catalog_group_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_catalog_group_code UNIQUE (tenant_id, code),
  CONSTRAINT fk_catalog_group_parent FOREIGN KEY (parent_id, tenant_id)
    REFERENCES ph07_rdm.catalog_group (id, tenant_id),
  CONSTRAINT ck_catalog_group_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_catalog_group_code CHECK (code ~ '^[A-Z0-9][A-Z0-9_.-]{0,63}$'),
  CONSTRAINT ck_catalog_group_name_nfc CHECK (name IS NFC NORMALIZED),
  CONSTRAINT ck_catalog_group_not_self CHECK (parent_id IS NULL OR parent_id <> id)
);
CREATE INDEX ix_catalog_group_parent ON ph07_rdm.catalog_group (tenant_id, parent_id, sort_order);
CREATE TRIGGER tg_catalog_group_touch BEFORE UPDATE ON ph07_rdm.catalog_group
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.catalog_group ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.catalog_group FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_catalog_group_select ON ph07_rdm.catalog_group FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_catalog_group_insert ON ph07_rdm.catalog_group FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_group_update ON ph07_rdm.catalog_group FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_group_delete ON ph07_rdm.catalog_group FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.catalog_group IS 'EN-07-01 Nhóm danh mục: cây phân loại danh mục (FR-07-010). Mẫu RLS S: nhóm COMMON dùng chung, tenant thêm nhóm riêng.';
COMMENT ON COLUMN ph07_rdm.catalog_group.code IS 'Mã nhóm (T-CODE, chữ hoa), duy nhất trong tenant.';
COMMENT ON COLUMN ph07_rdm.catalog_group.parent_id IS 'Nhóm cha cùng tenant; rỗng là nhóm gốc. Ứng dụng kiểm tra không tạo vòng.';
--rollback DROP TABLE IF EXISTS ph07_rdm.catalog_group CASCADE;
