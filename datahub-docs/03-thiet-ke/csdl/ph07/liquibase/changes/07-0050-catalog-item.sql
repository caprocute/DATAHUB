--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0050-catalog-item.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0500-catalog-item
CREATE TABLE ph07_rdm.catalog_item (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  catalog_id          uuid          NOT NULL,
  version_id          uuid          NOT NULL,
  code                varchar(64)   NOT NULL,
  name                varchar(255)  NOT NULL,
  name_search         text          GENERATED ALWAYS AS (ph07_rdm.f_search_norm(name)) STORED,
  parent_code         varchar(64),
  depth               smallint      NOT NULL DEFAULT 1,
  path                text[]        NOT NULL DEFAULT '{}',
  level_name          varchar(64),
  sort_order          integer       NOT NULL DEFAULT 0,
  status              varchar(32)   NOT NULL DEFAULT 'ACTIVE',
  replaced_by         text[],
  valid_from          date,
  valid_to            date,
  attrs               jsonb         NOT NULL DEFAULT '{}'::jsonb,
  is_local_extension  boolean       NOT NULL DEFAULT false,
  legacy_ref          varchar(64),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          uuid          NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          uuid          NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_item PRIMARY KEY (id),
  -- BR-07-002: mã duy nhất trong phiên bản, không phân biệt hoa thường.
  -- Vì CHECK ck_catalog_item_code_upper buộc lưu chữ hoa, ràng buộc này
  -- tương đương UNIQUE (version_id, upper(code)) nhưng phục vụ trực tiếp
  -- truy vấn code = $1 và code = ANY($1) mà không cần biểu thức upper().
  CONSTRAINT uq_catalog_item_code UNIQUE (version_id, code),
  CONSTRAINT fk_catalog_item_version FOREIGN KEY (version_id, tenant_id)
    REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_catalog_item_catalog FOREIGN KEY (catalog_id, tenant_id)
    REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_catalog_item_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_catalog_item_code_upper CHECK (code = upper(code)),
  CONSTRAINT ck_catalog_item_code CHECK (code ~ '^[A-Z0-9][A-Z0-9_.-]{0,63}$'),
  CONSTRAINT ck_catalog_item_parent CHECK (parent_code IS NULL OR (parent_code <> code AND parent_code = upper(parent_code))),
  CONSTRAINT ck_catalog_item_name_nfc CHECK (name IS NFC NORMALIZED),
  CONSTRAINT ck_catalog_item_depth CHECK (depth BETWEEN 1 AND 10 AND cardinality(path) = depth - 1),
  CONSTRAINT ck_catalog_item_status CHECK (status IN ('ACTIVE','DEPRECATED')),
  CONSTRAINT ck_catalog_item_replaced CHECK (replaced_by IS NULL OR (status = 'DEPRECATED' AND cardinality(replaced_by) BETWEEN 1 AND 100)),
  CONSTRAINT ck_catalog_item_valid CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from),
  CONSTRAINT ck_catalog_item_attrs CHECK (jsonb_typeof(attrs) = 'object')
);
-- Danh sách con trực tiếp (cây, API-07-044) theo thứ tự hiển thị.
CREATE INDEX ix_catalog_item_parent ON ph07_rdm.catalog_item (version_id, parent_code, sort_order, code);
-- Phân trang con trỏ toàn bộ bản ghi (API-07-041, NFR-07-003).
CREATE INDEX ix_catalog_item_order ON ph07_rdm.catalog_item (version_id, sort_order, code);
-- DSL truy vấn: attrs @> '{"k":"v"}' (NFR-07-004).
CREATE INDEX ix_catalog_item_attrs ON ph07_rdm.catalog_item USING gin (attrs jsonb_path_ops);
-- Tìm không dấu: name_search LIKE '%…%' (API-07-045).
CREATE INDEX ix_catalog_item_name_trgm ON ph07_rdm.catalog_item USING gin (name_search public.gin_trgm_ops);
-- Nhánh con theo tổ tiên: path @> ARRAY['68'] (API-07-044 root=…).
CREATE INDEX ix_catalog_item_path ON ph07_rdm.catalog_item USING gin (path);
-- FK sang catalog (xóa, đối chiếu di trú).
CREATE INDEX ix_catalog_item_catalog ON ph07_rdm.catalog_item (catalog_id);
ALTER TABLE ph07_rdm.catalog_item ALTER COLUMN attrs SET COMPRESSION lz4;
ALTER TABLE ph07_rdm.catalog_item SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_analyze_scale_factor = 0.02,
  autovacuum_vacuum_insert_scale_factor = 0.05
);
CREATE TRIGGER tg_catalog_item_touch BEFORE UPDATE ON ph07_rdm.catalog_item
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.catalog_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.catalog_item FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_catalog_item_select ON ph07_rdm.catalog_item FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_catalog_item_insert ON ph07_rdm.catalog_item FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_item_update ON ph07_rdm.catalog_item FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_item_delete ON ph07_rdm.catalog_item FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.catalog_item IS 'EN-07-05 Bản ghi danh mục trong một phiên bản (ảnh chụp copy-on-write). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.catalog_item.catalog_id IS 'Phi chuẩn hóa từ catalog_version để lọc theo danh mục (HYBRID, ánh xạ) không cần nối.';
COMMENT ON COLUMN ph07_rdm.catalog_item.code IS 'Mã bản ghi T-CODE, lưu chữ hoa (BR-07-002).';
COMMENT ON COLUMN ph07_rdm.catalog_item.name_search IS 'Cột sinh: f_search_norm(name) = chữ thường, bỏ dấu, gộp khoảng trắng; dùng cho tìm không dấu.';
COMMENT ON COLUMN ph07_rdm.catalog_item.parent_code IS 'Mã cha trong cùng phiên bản (hoặc trong phiên bản gốc với bản ghi HYBRID).';
COMMENT ON COLUMN ph07_rdm.catalog_item.depth IS 'Độ sâu, gốc = 1. Tính bằng ph07_rdm.f_recompute_hierarchy sau mỗi lô ghi.';
COMMENT ON COLUMN ph07_rdm.catalog_item.path IS 'Mảng mã tổ tiên từ gốc tới cha (không gồm chính nó).';
COMMENT ON COLUMN ph07_rdm.catalog_item.replaced_by IS 'Mảng mã thay thế khi DEPRECATED (BR-07-003, BR-07-004).';
COMMENT ON COLUMN ph07_rdm.catalog_item.valid_from IS 'Ngày bản ghi bắt đầu hiệu lực bên trong phiên bản (rỗng = theo phiên bản). Dùng cho ĐVHC lịch sử.';
COMMENT ON COLUMN ph07_rdm.catalog_item.attrs IS 'Giá trị thuộc tính động {mã thuộc tính: giá trị}, kiểm tra bằng JSON Schema sinh từ attribute_def.';
COMMENT ON COLUMN ph07_rdm.catalog_item.is_local_extension IS 'Bản ghi bổ sung địa phương của danh mục HYBRID.';
--rollback DROP TABLE IF EXISTS ph07_rdm.catalog_item CASCADE;
