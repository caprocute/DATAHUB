--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0020-catalog.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0200-catalog
CREATE TABLE ph07_rdm.catalog (
  id                  uuid         NOT NULL,
  tenant_id           varchar(16)  NOT NULL,
  code                varchar(64)  NOT NULL,
  name                varchar(255) NOT NULL,
  description         text,
  group_id            uuid,
  owner_org_id        uuid,
  source_type         varchar(32)  NOT NULL DEFAULT 'LOCAL',
  classification      varchar(32)  NOT NULL DEFAULT 'PUBLIC',
  status              varchar(32)  NOT NULL DEFAULT 'DRAFT',
  is_hierarchical     boolean      NOT NULL DEFAULT false,
  max_depth           smallint     NOT NULL DEFAULT 1,
  level_names         jsonb,
  local_code_pattern  varchar(255),
  extends_catalog_id  uuid,
  require_approval    boolean      NOT NULL DEFAULT true,
  current_version_id  uuid,
  legacy_ref          varchar(64),
  created_at          timestamptz  NOT NULL DEFAULT now(),
  created_by          uuid         NOT NULL,
  updated_at          timestamptz  NOT NULL DEFAULT now(),
  updated_by          uuid         NOT NULL,
  version             integer      NOT NULL DEFAULT 0,
  deleted_at          timestamptz,
  CONSTRAINT pk_catalog PRIMARY KEY (id),
  CONSTRAINT uq_catalog_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_catalog_group FOREIGN KEY (group_id) REFERENCES ph07_rdm.catalog_group (id),
  CONSTRAINT fk_catalog_extends FOREIGN KEY (extends_catalog_id) REFERENCES ph07_rdm.catalog (id),
  CONSTRAINT ck_catalog_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_catalog_code CHECK (code ~ '^[A-Z0-9][A-Z0-9_.-]{0,63}$'),
  CONSTRAINT ck_catalog_name_nfc CHECK (name IS NFC NORMALIZED),
  CONSTRAINT ck_catalog_source_type CHECK (source_type IN ('LOCAL','NATIONAL','HYBRID')),
  CONSTRAINT ck_catalog_classification CHECK (classification IN ('PUBLIC','INTERNAL','RESTRICTED')),
  CONSTRAINT ck_catalog_status CHECK (status IN ('DRAFT','ACTIVE','RETIRED')),
  CONSTRAINT ck_catalog_max_depth CHECK (max_depth BETWEEN 1 AND 10 AND (is_hierarchical OR max_depth = 1)),
  CONSTRAINT ck_catalog_level_names CHECK (level_names IS NULL
      OR (jsonb_typeof(level_names) = 'array' AND jsonb_array_length(level_names) <= max_depth)),
  CONSTRAINT ck_catalog_hybrid CHECK ((source_type = 'HYBRID') = (extends_catalog_id IS NOT NULL)
      AND (source_type <> 'HYBRID' OR (local_code_pattern IS NOT NULL AND tenant_id <> 'COMMON'))),
  CONSTRAINT ck_catalog_soft_delete CHECK (deleted_at IS NULL OR status = 'DRAFT')
);
CREATE UNIQUE INDEX uq_catalog_tenant_code ON ph07_rdm.catalog (tenant_id, code) WHERE deleted_at IS NULL;
CREATE INDEX ix_catalog_group ON ph07_rdm.catalog (tenant_id, group_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_catalog_status ON ph07_rdm.catalog (tenant_id, status, source_type) WHERE deleted_at IS NULL;
CREATE INDEX ix_catalog_extends ON ph07_rdm.catalog (extends_catalog_id) WHERE extends_catalog_id IS NOT NULL;
CREATE INDEX ix_catalog_name_trgm ON ph07_rdm.catalog USING gin (ph07_rdm.f_search_norm(name) public.gin_trgm_ops);
CREATE TRIGGER tg_catalog_touch BEFORE UPDATE ON ph07_rdm.catalog
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.catalog FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_catalog_select ON ph07_rdm.catalog FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_catalog_insert ON ph07_rdm.catalog FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_update ON ph07_rdm.catalog FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_delete ON ph07_rdm.catalog FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.catalog IS 'EN-07-02 Danh mục: định nghĩa một danh mục (FR-07-001…009, 048). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.catalog.code IS 'Mã danh mục T-CODE chữ hoa; duy nhất trong tenant khi chưa xóa mềm (BR-07-001; phần "không trùng COMMON" kiểm tra ở ứng dụng).';
COMMENT ON COLUMN ph07_rdm.catalog.owner_org_id IS 'Cơ quan chủ quản, FK logic DD-02 ph20_tenant.organization (không FK vật lý chéo schema).';
COMMENT ON COLUMN ph07_rdm.catalog.source_type IS 'LOCAL tỉnh tự quản; NATIONAL đồng bộ NDXP (chỉ đọc với người dùng); HYBRID mở rộng danh mục COMMON.';
COMMENT ON COLUMN ph07_rdm.catalog.level_names IS 'Mảng tên cấp theo độ sâu, ví dụ ["Tỉnh","Xã"].';
COMMENT ON COLUMN ph07_rdm.catalog.local_code_pattern IS 'Biểu thức chính quy dải mã địa phương (HYBRID), BR-07-010.';
COMMENT ON COLUMN ph07_rdm.catalog.extends_catalog_id IS 'Danh mục COMMON được mở rộng (chỉ HYBRID).';
COMMENT ON COLUMN ph07_rdm.catalog.current_version_id IS 'Phiên bản đã phát hành mới nhất (có thể sắp hiệu lực). Tra theo thời điểm dùng khoảng hiệu lực, không dùng cột này.';
COMMENT ON COLUMN ph07_rdm.catalog.legacy_ref IS 'Khóa hệ cũ (Aita category.id) phục vụ di trú, đối chiếu.';
--rollback DROP TABLE IF EXISTS ph07_rdm.catalog CASCADE;
