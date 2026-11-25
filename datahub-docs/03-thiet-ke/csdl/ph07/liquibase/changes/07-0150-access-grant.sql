--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0150-access-grant.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1500-catalog-access-grant
CREATE TABLE ph07_rdm.catalog_access_grant (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  catalog_id        uuid          NOT NULL,
  member_system_id  uuid          NOT NULL,
  scopes            text[]        NOT NULL DEFAULT ARRAY['rdm.read'],
  granted_by        uuid          NOT NULL,
  expires_at        timestamptz,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        uuid          NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        uuid          NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_access_grant PRIMARY KEY (id),
  CONSTRAINT uq_catalog_access_grant UNIQUE (catalog_id, member_system_id),
  CONSTRAINT fk_catalog_access_grant_catalog FOREIGN KEY (catalog_id, tenant_id) REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_catalog_access_grant_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_catalog_access_grant_scopes CHECK (cardinality(scopes) >= 1 AND scopes <@ ARRAY['rdm.read','rdm.query']::text[])
);
CREATE INDEX ix_catalog_access_grant_member ON ph07_rdm.catalog_access_grant (member_system_id);
CREATE TRIGGER tg_catalog_access_grant_touch BEFORE UPDATE ON ph07_rdm.catalog_access_grant
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.catalog_access_grant ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.catalog_access_grant FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_catalog_access_grant_select ON ph07_rdm.catalog_access_grant FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_access_grant_insert ON ph07_rdm.catalog_access_grant FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_access_grant_update ON ph07_rdm.catalog_access_grant FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_access_grant_delete ON ph07_rdm.catalog_access_grant FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.catalog_access_grant IS 'EN-07-15 Cấp quyền khai thác danh mục RESTRICTED cho HTTT (FR-07-052, BR-07-019). Mẫu RLS P.';
COMMENT ON COLUMN ph07_rdm.catalog_access_grant.member_system_id IS 'FK logic DD-03.';
--rollback DROP TABLE IF EXISTS ph07_rdm.catalog_access_grant CASCADE;
