-- =============================================================================
-- D03-03-PH07 · DDL schema ph07_rdm — PH-07 Danh mục dùng chung (RDM)
-- Phiên bản 0.1 · 2026-11-21 · Dự thảo · Nhóm phân hệ PH-07
--
-- Mục đích: tạo đầy đủ schema ph07_rdm trên một CSDL PostgreSQL trống
-- (đích PostgreSQL 18; tương thích ngược tới PostgreSQL 16 nhờ các khối DO
-- có điều kiện theo server_version_num).
--
-- Cách chạy độc lập (môi trường phát triển):
--   psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph07_rdm.sql
-- Người chạy phải là superuser hoặc chủ CSDL có CREATEROLE. Ở môi trường
-- thật, vai trò do CloudNativePG (managed roles) tạo trước và phần còn lại
-- chạy qua Liquibase (xem liquibase/db.changelog-ph07.yaml).
--
-- Tệp này là NGUỒN DUY NHẤT: các changeset Liquibase trong liquibase/changes/
-- được sinh tự động từ các dấu "-- @changeset" / "-- @rollback" / "-- @file"
-- dưới đây. Không sửa tay tệp changeset; sửa tệp này rồi sinh lại.
--
-- Quy ước dấu:
--   -- @file <tên>.sql                     : bắt đầu một tệp changeset mới
--   -- @changeset <id> [splitStatements:false] [context:<ctx>]
--   -- @rollback <câu lệnh SQL>              : có thể lặp nhiều dòng
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 07-0000-bootstrap.sql
-- @changeset ph07-0000-roles splitStatements:false context:bootstrap
-- Vai trò nhóm (NOLOGIN). Tài khoản đăng nhập thật (dh_data_app,
-- dh_data_migrator, dh_report) là thành viên của các vai trò này và do
-- CloudNativePG quản lý mật khẩu qua OpenBao; không đặt mật khẩu ở đây.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_owner') THEN
    CREATE ROLE ph07_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_app') THEN
    CREATE ROLE ph07_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_readonly') THEN
    CREATE ROLE ph07_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback: vai trò có thể đang được schema khác hoặc tài khoản đăng nhập dùng.

-- @changeset ph07-0001-extensions context:bootstrap
-- unaccent, pg_trgm, btree_gist là extension "trusted" từ PostgreSQL 13:
-- chủ CSDL có quyền CREATE tạo được mà không cần superuser.
CREATE EXTENSION IF NOT EXISTS unaccent   WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm    WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;
-- @rollback -- Không gỡ extension: có thể đang được schema khác dùng.

-- @changeset ph07-0002-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph07_rdm AUTHORIZATION ph07_owner;
COMMENT ON SCHEMA ph07_rdm IS 'PH-07 Danh mục dùng chung (RDM): danh mục có phiên bản, thuộc tính động, ĐVHC, ánh xạ mã, đồng bộ quốc gia. Chủ sở hữu ph07_owner; ứng dụng kết nối bằng ph07_app (không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph07_rdm TO ph07_app, ph07_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph07_rdm CASCADE;

-- Từ đây mọi đối tượng do ph07_owner sở hữu (khi chạy độc lập bằng superuser).
-- Liquibase kết nối bằng dh_data_migrator (thành viên ph07_owner) và đặt
-- defaultSchemaName=ph07_rdm; dòng SET ROLE dưới đây chỉ dùng khi chạy psql.
SET ROLE ph07_owner;

-- @file 07-0001-functions.sql
-- @changeset ph07-0010-fn-unaccent splitStatements:false
-- Hàm bỏ dấu bất biến. unaccent() gốc chỉ STABLE (phụ thuộc search_path để
-- tìm từ điển) nên không dùng được trong cột sinh và index biểu thức. Ta cố
-- định từ điển public.unaccent và khai báo IMMUTABLE. Thân BEGIN ATOMIC
-- (PostgreSQL 14+) được phân giải lúc tạo hàm, không phụ thuộc search_path
-- lúc chạy. Nếu sửa tệp unaccent.rules thì phải REINDEX và cập nhật lại cột
-- name_search (xem tài liệu §5.3).
CREATE OR REPLACE FUNCTION ph07_rdm.f_unaccent_immutable(p_text text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT public.unaccent('public.unaccent'::regdictionary, p_text);
END;
COMMENT ON FUNCTION ph07_rdm.f_unaccent_immutable(text) IS 'Bỏ dấu tiếng Việt (kể cả đ/Đ) với từ điển cố định public.unaccent; IMMUTABLE để dùng cho cột sinh name_search và index biểu thức.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.f_unaccent_immutable(text);

-- @changeset ph07-0011-fn-search-norm splitStatements:false
CREATE OR REPLACE FUNCTION ph07_rdm.f_search_norm(p_text text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT lower(regexp_replace(ph07_rdm.f_unaccent_immutable(normalize(p_text, NFC)), '\s+', ' ', 'g'));
END;
COMMENT ON FUNCTION ph07_rdm.f_search_norm(text) IS 'Chuẩn hóa chuỗi tìm kiếm: NFC, bỏ dấu, chữ thường, gộp khoảng trắng. Ứng dụng gọi cùng hàm này cho chuỗi người dùng nhập để so khớp với name_search.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.f_search_norm(text);

-- @changeset ph07-0012-fn-uuid-v7 splitStatements:false
-- UUID v7 sinh ở ứng dụng là quy tắc chung (D00-01 §5). Ngoại lệ có chủ đích:
-- thao tác sao chép hàng loạt bằng INSERT … SELECT (tạo bản nháp copy-on-write)
-- cần sinh khóa trong CSDL. PostgreSQL 18 có sẵn uuidv7(); bản 16/17 dùng
-- hàm thay thế cùng định dạng RFC 9562.
DO $uuid$
BEGIN
  IF current_setting('server_version_num')::int >= 180000 THEN
    EXECUTE $f$
      CREATE OR REPLACE FUNCTION ph07_rdm.f_uuid_v7() RETURNS uuid
        LANGUAGE sql VOLATILE PARALLEL SAFE
        AS 'SELECT uuidv7()'
    $f$;
  ELSE
    EXECUTE $f$
      CREATE OR REPLACE FUNCTION ph07_rdm.f_uuid_v7() RETURNS uuid
        LANGUAGE sql VOLATILE PARALLEL SAFE
        AS $b$
          SELECT encode(
                   set_bit(set_bit(
                     overlay(uuid_send(gen_random_uuid())
                             PLACING substring(int8send((extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3)
                             FROM 1 FOR 6),
                   52, 1), 53, 1),
                 'hex')::uuid
        $b$
    $f$;
  END IF;
END
$uuid$;
COMMENT ON FUNCTION ph07_rdm.f_uuid_v7() IS 'UUID phiên bản 7 sinh trong CSDL; chỉ dùng cho sao chép hàng loạt (copy-on-write, di trú). Đường ghi thông thường sinh UUID v7 ở ứng dụng.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.f_uuid_v7();

-- @changeset ph07-0013-fn-touch splitStatements:false
-- Trigger chung: cập nhật updated_at và tăng version (khóa lạc quan) khi
-- ứng dụng quên. Ứng dụng (JPA @Version) vẫn là nơi so sánh version.
CREATE OR REPLACE FUNCTION ph07_rdm.tg_touch()
  RETURNS trigger
  LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$$;
COMMENT ON FUNCTION ph07_rdm.tg_touch() IS 'BEFORE UPDATE: đặt updated_at = now() và tăng version nếu ứng dụng chưa tăng.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.tg_touch();

-- =============================================================================
-- MẪU CHÍNH SÁCH RLS (tài liệu §6)
--   Mẫu S (SHARED, bảng có thể chứa COMMON và mọi tenant được đọc COMMON):
--     SELECT : tenant_id IN (current_setting('app.tenant_id', false), 'COMMON')
--     GHI    : (tenant_id = cur AND tenant_id ~ '^T[0-9]{2}$')
--              OR (tenant_id = 'COMMON' AND cur = 'PLATFORM')
--   Mẫu P (PRIVATE, dữ liệu tác nghiệp; COMMON chỉ PLATFORM thấy):
--     SELECT = GHI = biểu thức GHI ở trên.
--   cur = current_setting('app.tenant_id', false): quên đặt biến phiên thì lỗi.
-- =============================================================================

-- @file 07-0010-catalog-group.sql
-- @changeset ph07-0100-catalog-group
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.catalog_group CASCADE;

-- @file 07-0020-catalog.sql
-- @changeset ph07-0200-catalog
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.catalog CASCADE;

-- @file 07-0030-catalog-version.sql
-- @changeset ph07-0300-catalog-version
CREATE TABLE ph07_rdm.catalog_version (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  catalog_id      uuid          NOT NULL,
  version_no      integer       NOT NULL,
  status          varchar(32)   NOT NULL DEFAULT 'DRAFT',
  effective_from  date,
  effective_to    date,
  legal_basis     text,
  change_note     text,
  origin          varchar(32)   NOT NULL DEFAULT 'MANUAL',
  item_count      integer       NOT NULL DEFAULT 0,
  stats           jsonb         NOT NULL DEFAULT '{}'::jsonb,
  submitted_by    uuid,
  submitted_at    timestamptz,
  approved_by     uuid,
  approved_at     timestamptz,
  published_by    uuid,
  published_at    timestamptz,
  snapshot_uri    varchar(2048),
  schema_hash     char(64),
  last_edited_by  uuid,
  last_edited_at  timestamptz,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      uuid          NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      uuid          NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_version PRIMARY KEY (id),
  CONSTRAINT uq_catalog_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_catalog_version_no UNIQUE (catalog_id, version_no),
  CONSTRAINT fk_catalog_version_catalog FOREIGN KEY (catalog_id, tenant_id)
    REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_catalog_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_catalog_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_catalog_version_status CHECK (status IN ('DRAFT','IN_REVIEW','APPROVED','PUBLISHED','DISCARDED')),
  CONSTRAINT ck_catalog_version_origin CHECK (origin IN ('MANUAL','IMPORT','API','SYNC','MIGRATION')),
  CONSTRAINT ck_catalog_version_range CHECK (effective_to IS NULL OR (effective_from IS NOT NULL AND effective_to > effective_from)),
  CONSTRAINT ck_catalog_version_published CHECK (status <> 'PUBLISHED'
      OR (effective_from IS NOT NULL AND published_at IS NOT NULL AND published_by IS NOT NULL)),
  CONSTRAINT ck_catalog_version_stats CHECK (jsonb_typeof(stats) = 'object'),
  CONSTRAINT ck_catalog_version_item_count CHECK (item_count >= 0),
  -- BR-07-007: khoảng hiệu lực [from, to) của các phiên bản đã phát hành
  -- trong một danh mục không chồng lấn. Index GiST của ràng buộc này cũng
  -- phục vụ truy vấn "phiên bản hiệu lực tại ngày d" (toán tử @>).
  CONSTRAINT ex_catalog_version_no_overlap EXCLUDE USING gist (
      catalog_id WITH =,
      daterange(effective_from, effective_to, '[)') WITH &&
  ) WHERE (status = 'PUBLISHED')
);
-- BR-07-005: mỗi danh mục tối đa một phiên bản mở.
CREATE UNIQUE INDEX uq_catalog_version_open ON ph07_rdm.catalog_version (catalog_id)
  WHERE status IN ('DRAFT','IN_REVIEW','APPROVED');
-- Danh sách phiên bản (API-07-011) và tìm phiên bản phát hành mới nhất.
CREATE INDEX ix_catalog_version_catalog ON ph07_rdm.catalog_version (catalog_id, version_no DESC);
-- Hộp chờ duyệt theo tenant.
CREATE INDEX ix_catalog_version_review ON ph07_rdm.catalog_version (tenant_id, submitted_at)
  WHERE status = 'IN_REVIEW';
ALTER TABLE ph07_rdm.catalog_version SET (fillfactor = 90);
CREATE TRIGGER tg_catalog_version_touch BEFORE UPDATE ON ph07_rdm.catalog_version
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.catalog_version ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.catalog_version FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_catalog_version_select ON ph07_rdm.catalog_version FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_catalog_version_insert ON ph07_rdm.catalog_version FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_version_update ON ph07_rdm.catalog_version FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_version_delete ON ph07_rdm.catalog_version FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.catalog_version IS 'EN-07-03 Phiên bản danh mục: ảnh chụp đầy đủ, bất biến khi PUBLISHED (ADR-051). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.catalog_version.status IS 'DRAFT, IN_REVIEW, APPROVED, PUBLISHED, DISCARDED. Nhãn Đang/Sắp/Hết hiệu lực tính từ khoảng ngày, không lưu.';
COMMENT ON COLUMN ph07_rdm.catalog_version.effective_from IS 'Ngày bắt đầu hiệu lực (bao gồm). Bắt buộc khi PUBLISHED.';
COMMENT ON COLUMN ph07_rdm.catalog_version.effective_to IS 'Ngày hết hiệu lực (không bao gồm); rỗng là vô hạn. Được đặt bằng effective_from của phiên bản kế tiếp khi phát hành.';
COMMENT ON COLUMN ph07_rdm.catalog_version.stats IS 'Thống kê khác biệt so với phiên bản trước: {"added":n,"changed":n,"deprecated":n,"removed":n,"breaking":bool}.';
COMMENT ON COLUMN ph07_rdm.catalog_version.schema_hash IS 'SHA-256 hex của JSON Schema sinh từ attribute_def; dùng làm ETag lược đồ.';
COMMENT ON COLUMN ph07_rdm.catalog_version.last_edited_by IS 'Người sửa nội dung bản nháp lần cuối (bản ghi, thuộc tính); phục vụ kiểm tra bốn mắt (D02-08). Cột bổ sung ngoài khung.';
COMMENT ON COLUMN ph07_rdm.catalog_version.version IS 'Khóa lạc quan của cả bản nháp: ứng dụng tăng mỗi khi nội dung bản nháp đổi; tác vụ nhập so sánh khi commit (BR-07-016).';
-- @rollback DROP TABLE IF EXISTS ph07_rdm.catalog_version CASCADE;

-- @changeset ph07-0301-catalog-current-version-fk
ALTER TABLE ph07_rdm.catalog
  ADD CONSTRAINT fk_catalog_current_version FOREIGN KEY (current_version_id, tenant_id)
  REFERENCES ph07_rdm.catalog_version (id, tenant_id);
-- @rollback ALTER TABLE ph07_rdm.catalog DROP CONSTRAINT IF EXISTS fk_catalog_current_version;

-- @file 07-0040-attribute-def.sql
-- @changeset ph07-0400-attribute-def
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.attribute_def CASCADE;

-- @file 07-0050-catalog-item.sql
-- @changeset ph07-0500-catalog-item
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.catalog_item CASCADE;

-- @file 07-0060-item-succession.sql
-- @changeset ph07-0600-item-succession
CREATE TABLE ph07_rdm.item_succession (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  catalog_id      uuid          NOT NULL,
  version_id      uuid          NOT NULL,
  event_type      varchar(32)   NOT NULL,
  from_codes      text[]        NOT NULL DEFAULT '{}',
  to_codes        text[]        NOT NULL DEFAULT '{}',
  effective_date  date          NOT NULL,
  legal_basis     text          NOT NULL,
  note            text,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      uuid          NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      uuid          NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_item_succession PRIMARY KEY (id),
  CONSTRAINT fk_item_succession_version FOREIGN KEY (version_id, tenant_id)
    REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_item_succession_catalog FOREIGN KEY (catalog_id, tenant_id)
    REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_item_succession_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_item_succession_type CHECK (event_type IN ('MERGE','SPLIT','RENAME','ABOLISH','ESTABLISH','RECODE')),
  CONSTRAINT ck_item_succession_legal CHECK (length(btrim(legal_basis)) > 0),
  -- Bản số theo loại sự kiện (BR-07-021).
  CONSTRAINT ck_item_succession_cardinality CHECK (
       (event_type = 'MERGE'     AND cardinality(from_codes) >= 2 AND cardinality(to_codes) = 1)
    OR (event_type = 'SPLIT'     AND cardinality(from_codes) >= 1 AND cardinality(to_codes) >= 2)
    OR (event_type = 'RENAME'    AND cardinality(from_codes) = 1  AND to_codes = from_codes)
    OR (event_type = 'RECODE'    AND cardinality(from_codes) = 1  AND cardinality(to_codes) = 1 AND to_codes <> from_codes)
    OR (event_type = 'ABOLISH'   AND cardinality(from_codes) >= 1 AND cardinality(to_codes) = 0)
    OR (event_type = 'ESTABLISH' AND cardinality(from_codes) = 0  AND cardinality(to_codes) >= 1))
);
CREATE INDEX ix_item_succession_version ON ph07_rdm.item_succession (version_id, effective_date);
-- Chuyển mã cũ sang mới: from_codes @> ARRAY[$code]; tra ngược: to_codes @> ARRAY[$code].
CREATE INDEX ix_item_succession_from ON ph07_rdm.item_succession USING gin (from_codes);
CREATE INDEX ix_item_succession_to   ON ph07_rdm.item_succession USING gin (to_codes);
CREATE INDEX ix_item_succession_catalog ON ph07_rdm.item_succession (catalog_id, effective_date);
CREATE TRIGGER tg_item_succession_touch BEFORE UPDATE ON ph07_rdm.item_succession
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.item_succession ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.item_succession FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_item_succession_select ON ph07_rdm.item_succession FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_item_succession_insert ON ph07_rdm.item_succession FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_item_succession_update ON ph07_rdm.item_succession FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_item_succession_delete ON ph07_rdm.item_succession FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.item_succession IS 'EN-07-06 Sự kiện kế thừa bản ghi (sắp xếp ĐVHC): nhiều-nhiều, có căn cứ pháp lý và ngày hiệu lực (FR-07-045, ADR-055). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.item_succession.version_id IS 'Phiên bản ghi nhận sự kiện; bất biến cùng phiên bản khi phát hành.';
COMMENT ON COLUMN ph07_rdm.item_succession.from_codes IS 'Mã đơn vị trước sự kiện.';
COMMENT ON COLUMN ph07_rdm.item_succession.to_codes IS 'Mã đơn vị sau sự kiện.';
-- @rollback DROP TABLE IF EXISTS ph07_rdm.item_succession CASCADE;

-- @file 07-0070-version-review.sql
-- @changeset ph07-0700-version-review
-- Bảng chỉ-thêm: ngoại lệ có chủ đích với D00-01 §5.1 (giống DD-10),
-- không có updated_at/updated_by/version; actor/at đóng vai created_by/at.
CREATE TABLE ph07_rdm.version_review (
  id          uuid          NOT NULL,
  tenant_id   varchar(16)   NOT NULL,
  version_id  uuid          NOT NULL,
  action      varchar(32)   NOT NULL,
  actor       uuid          NOT NULL,
  comment     text,
  diff_stats  jsonb,
  at          timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_version_review PRIMARY KEY (id),
  CONSTRAINT fk_version_review_version FOREIGN KEY (version_id, tenant_id)
    REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_version_review_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_version_review_action CHECK (action IN ('SUBMIT','APPROVE','REJECT','PUBLISH','DISCARD')),
  CONSTRAINT ck_version_review_reject_reason CHECK (action <> 'REJECT' OR length(btrim(coalesce(comment, ''))) > 0)
);
CREATE INDEX ix_version_review_version ON ph07_rdm.version_review (version_id, at);
ALTER TABLE ph07_rdm.version_review ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.version_review FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_version_review_select ON ph07_rdm.version_review FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_version_review_insert ON ph07_rdm.version_review FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.version_review IS 'EN-07-07 Nhật ký duyệt phiên bản (chỉ-thêm). Mẫu RLS P: lời phê duyệt COMMON chỉ PLATFORM thấy.';
COMMENT ON COLUMN ph07_rdm.version_review.comment IS 'Ý kiến; bắt buộc khi REJECT.';
-- @rollback DROP TABLE IF EXISTS ph07_rdm.version_review CASCADE;

-- @file 07-0080-file-object.sql
-- @changeset ph07-0800-file-object
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.file_object CASCADE;

-- @file 07-0090-import-job.sql
-- @changeset ph07-0900-import-job
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.import_job CASCADE;

-- @file 07-0100-import-row.sql
-- @changeset ph07-1000-import-row
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
-- @rollback DROP TABLE IF EXISTS ph07_rdm.import_row CASCADE;

-- @file 07-0110-sync.sql
-- @changeset ph07-1100-sync-source
CREATE TABLE ph07_rdm.sync_source (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  catalog_id       uuid          NOT NULL,
  provider         varchar(32)   NOT NULL DEFAULT 'NDXP_DMDC',
  remote_code      varchar(128)  NOT NULL,
  remote_name      varchar(255),
  schedule_cron    varchar(64)   NOT NULL DEFAULT '0 0 1 * * *',
  auto_apply       boolean       NOT NULL DEFAULT true,
  enabled          boolean       NOT NULL DEFAULT true,
  last_run_id      uuid,
  last_success_at  timestamptz,
  remote_version   varchar(128),
  field_mapping    jsonb         NOT NULL DEFAULT '{}'::jsonb,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       uuid          NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       uuid          NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_source PRIMARY KEY (id),
  CONSTRAINT uq_sync_source_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_sync_source_catalog UNIQUE (catalog_id, provider),
  CONSTRAINT fk_sync_source_catalog FOREIGN KEY (catalog_id, tenant_id) REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_sync_source_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_sync_source_provider CHECK (provider IN ('NDXP_DMDC')),
  CONSTRAINT ck_sync_source_mapping CHECK (jsonb_typeof(field_mapping) = 'object')
);
CREATE INDEX ix_sync_source_enabled ON ph07_rdm.sync_source (tenant_id) WHERE enabled;
ALTER TABLE ph07_rdm.sync_source SET (fillfactor = 90);
CREATE TRIGGER tg_sync_source_touch BEFORE UPDATE ON ph07_rdm.sync_source
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.sync_source ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.sync_source FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_sync_source_select ON ph07_rdm.sync_source FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_source_insert ON ph07_rdm.sync_source FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_source_update ON ph07_rdm.sync_source FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_source_delete ON ph07_rdm.sync_source FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.sync_source IS 'EN-07-10 Nguồn đồng bộ danh mục quốc gia qua PH-14 (ADR-057). Mẫu RLS P.';
COMMENT ON COLUMN ph07_rdm.sync_source.schedule_cron IS 'Biểu thức cron Spring 6 trường; mặc định 01:00 hằng ngày (giờ Việt Nam).';
COMMENT ON COLUMN ph07_rdm.sync_source.field_mapping IS 'Ánh xạ trường nguồn sang thuộc tính: {"remoteField":"attrCode"}.';
-- @rollback DROP TABLE IF EXISTS ph07_rdm.sync_source CASCADE;

-- @changeset ph07-1101-sync-run
CREATE TABLE ph07_rdm.sync_run (
  id                 uuid          NOT NULL,
  tenant_id          varchar(16)   NOT NULL,
  source_id          uuid          NOT NULL,
  trigger            varchar(32)   NOT NULL,
  status             varchar(32)   NOT NULL DEFAULT 'RUNNING',
  remote_version     varchar(128),
  diff_stats         jsonb,
  has_breaking       boolean       NOT NULL DEFAULT false,
  result_version_id  uuid,
  confirmed_by       uuid,
  confirmed_at       timestamptz,
  error_message      text,
  started_at         timestamptz   NOT NULL DEFAULT now(),
  finished_at        timestamptz,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  created_by         uuid          NOT NULL,
  updated_at         timestamptz   NOT NULL DEFAULT now(),
  updated_by         uuid          NOT NULL,
  version            integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_run PRIMARY KEY (id),
  CONSTRAINT uq_sync_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_sync_run_source FOREIGN KEY (source_id, tenant_id) REFERENCES ph07_rdm.sync_source (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_sync_run_result FOREIGN KEY (result_version_id, tenant_id) REFERENCES ph07_rdm.catalog_version (id, tenant_id),
  CONSTRAINT ck_sync_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_sync_run_trigger CHECK (trigger IN ('SCHEDULE','MANUAL')),
  CONSTRAINT ck_sync_run_status CHECK (status IN ('RUNNING','NO_CHANGE','APPLIED','PENDING_CONFIRMATION','REJECTED','FAILED')),
  CONSTRAINT ck_sync_run_finished CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_sync_run_failed CHECK (status <> 'FAILED' OR error_message IS NOT NULL)
);
-- Một nguồn chỉ có một lần chạy RUNNING tại một thời điểm.
CREATE UNIQUE INDEX uq_sync_run_running ON ph07_rdm.sync_run (source_id) WHERE status = 'RUNNING';
CREATE INDEX ix_sync_run_source ON ph07_rdm.sync_run (source_id, started_at DESC);
CREATE INDEX ix_sync_run_pending ON ph07_rdm.sync_run (tenant_id) WHERE status = 'PENDING_CONFIRMATION';
ALTER TABLE ph07_rdm.sync_run SET (fillfactor = 90);
CREATE TRIGGER tg_sync_run_touch BEFORE UPDATE ON ph07_rdm.sync_run
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.sync_run ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.sync_run FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_sync_run_select ON ph07_rdm.sync_run FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_run_insert ON ph07_rdm.sync_run FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_run_update ON ph07_rdm.sync_run FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_run_delete ON ph07_rdm.sync_run FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.sync_run IS 'EN-07-11 Một lần chạy đồng bộ quốc gia. Mẫu RLS P.';
-- @rollback DROP TABLE IF EXISTS ph07_rdm.sync_run CASCADE;

-- @changeset ph07-1102-sync-source-last-run-fk
ALTER TABLE ph07_rdm.sync_source
  ADD CONSTRAINT fk_sync_source_last_run FOREIGN KEY (last_run_id, tenant_id)
  REFERENCES ph07_rdm.sync_run (id, tenant_id) ON DELETE SET NULL (last_run_id);
-- @rollback ALTER TABLE ph07_rdm.sync_source DROP CONSTRAINT IF EXISTS fk_sync_source_last_run;

-- @changeset ph07-1103-sync-change
-- Chỉ-thêm: ngoại lệ D00-01 §5.1 (không có updated_*/version).
CREATE TABLE ph07_rdm.sync_change (
  id           uuid          NOT NULL,
  tenant_id    varchar(16)   NOT NULL,
  run_id       uuid          NOT NULL,
  item_code    varchar(64),
  change_type  varchar(32)   NOT NULL,
  breaking     boolean       NOT NULL DEFAULT false,
  before       jsonb,
  after        jsonb,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_sync_change PRIMARY KEY (id),
  CONSTRAINT fk_sync_change_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph07_rdm.sync_run (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_sync_change_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_sync_change_type CHECK (change_type IN ('ADDED','CHANGED','REMOVED','ATTRIBUTE_ADDED','ATTRIBUTE_REMOVED','ATTRIBUTE_TYPE_CHANGED')),
  CONSTRAINT ck_sync_change_item CHECK (change_type LIKE 'ATTRIBUTE_%' OR item_code IS NOT NULL)
);
CREATE INDEX ix_sync_change_run ON ph07_rdm.sync_change (run_id, breaking DESC, item_code);
ALTER TABLE ph07_rdm.sync_change ALTER COLUMN before SET COMPRESSION lz4;
ALTER TABLE ph07_rdm.sync_change ALTER COLUMN after SET COMPRESSION lz4;
ALTER TABLE ph07_rdm.sync_change ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.sync_change FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_sync_change_select ON ph07_rdm.sync_change FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_change_insert ON ph07_rdm.sync_change FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_sync_change_delete ON ph07_rdm.sync_change FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.sync_change IS 'EN-07-12 Chi tiết khác biệt của một lần đồng bộ. Mẫu RLS P. Giữ 3 năm.';
-- @rollback DROP TABLE IF EXISTS ph07_rdm.sync_change CASCADE;
