-- =============================================================================
-- D03-03-PH15 · DDL schema ph15_portal — PH-15 Cổng nhà phát triển
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo · Nhóm phân hệ PH-15
--
-- Mục đích: tạo schema ph15_portal trên cụm pg-core (PostgreSQL 18, tương thích 16).
-- Chạy độc lập (phát triển), bằng siêu người dùng vì có CREATE EXTENSION unaccent:
--   psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph15_portal.sql
-- Môi trường thật: extension do DBA cài trước; phần còn lại chạy qua Liquibase, changeset
-- sinh từ dấu -- @file / -- @changeset / -- @rollback (tools/gen_liquibase.py).
-- Bám thực thể EN-15-01…18 của FRS §4.2 và enum Phụ lục A. Mọi bảng nghiệp vụ có RLS theo tenant.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 15-0000-bootstrap.sql
-- @changeset ph15-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph15_owner') THEN
    CREATE ROLE ph15_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph15_app') THEN
    CREATE ROLE ph15_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph15_readonly') THEN
    CREATE ROLE ph15_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph15-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph15_portal AUTHORIZATION ph15_owner;
COMMENT ON SCHEMA ph15_portal IS 'PH-15 Cổng nhà phát triển: bản sao danh mục, đặc tả, nội dung, tài khoản và ứng dụng sandbox, lượt thử, hỗ trợ, cấu hình cổng, di trú. Chủ ph15_owner; module portal của dh-connect kết nối bằng dh_portal_app (thành viên ph15_app, không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph15_portal TO ph15_app, ph15_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph15_portal CASCADE;

-- @changeset ph15-0002-unaccent context:bootstrap
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA ph15_portal;
-- @rollback DROP EXTENSION IF EXISTS unaccent;

-- Phiên migration: tạo đối tượng dưới ph15_owner; app.tenant_id đặt giá trị giữ chỗ vì FORCE RLS áp cả cho chủ bảng
-- khi ALTER TABLE ... ADD CONSTRAINT quét bảng. Chạy lại mỗi lần (runAlways), cùng kết nối với các changeset sau.
-- @changeset ph15-0003-session runAlways:true context:bootstrap
SET ROLE ph15_owner;
SET app.tenant_id = 'PLATFORM';
-- @rollback RESET ROLE;

-- @file 15-0001-functions.sql
-- @changeset ph15-0010-domain
CREATE DOMAIN ph15_portal.t_tenant AS varchar(16) CHECK (VALUE ~ '^T[0-9]{2}$');
COMMENT ON DOMAIN ph15_portal.t_tenant IS 'T-TENANT (D00-01): mã tenant dạng T{nn}, ví dụ T68.';
-- @rollback DROP DOMAIN IF EXISTS ph15_portal.t_tenant;

-- @changeset ph15-0011-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_touch() IS 'Cập nhật updated_at và tăng version (ETag, If-Match; BR-15-034) khi ứng dụng không tự tăng.';
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_touch();

-- @changeset ph15-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % là chỉ-ghi-thêm: không được %', TG_TABLE_NAME, TG_OP USING ERRCODE = 'P1500';
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng bất biến (bằng chứng chấp nhận điều khoản, tin nhắn hỗ trợ).';
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_append_only();

-- @changeset ph15-0013-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_immutable_cols() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF to_jsonb(NEW)->c IS DISTINCT FROM to_jsonb(OLD)->c THEN
      RAISE EXCEPTION 'Cột %.% bất biến (BR-15-007)', TG_TABLE_NAME, c USING ERRCODE = 'P1501';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_immutable_cols() IS 'Chặn sửa các cột mã định danh bất biến (appCode, pageCode, teamCode, ticketCode, apiCode); tên cột truyền qua TG_ARGV.';
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_immutable_cols();

-- @changeset ph15-0014-fn-rls splitStatements:false
CREATE OR REPLACE PROCEDURE ph15_portal.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false))$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_all ON %s FOR ALL USING %s WITH CHECK %s', n, t, w, w);
END
$p$;
COMMENT ON PROCEDURE ph15_portal.p_enable_rls(regclass) IS 'Bật FORCE RLS và một chính sách FOR ALL theo tenant (mẫu P của D03-10, ADR-003). PH-15 không có dữ liệu COMMON.';
-- @rollback DROP PROCEDURE IF EXISTS ph15_portal.p_enable_rls(regclass);

-- @changeset ph15-0015-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph15_portal.p_ensure_month_partitions(p_table regclass, p_from date, p_months integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_months - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + make_interval(months => i), 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, (d + make_interval(months => i))::timestamptz,
                     (d + make_interval(months => i + 1))::timestamptz);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph15_portal.p_ensure_month_partitions(regclass, date, integer) IS 'Tạo phân vùng tháng (ADR-047). PartitionMaintenanceJob gọi hằng ngày để luôn có 3 tháng tới.';
-- @rollback DROP PROCEDURE IF EXISTS ph15_portal.p_ensure_month_partitions(regclass, date, integer);

-- @changeset ph15-0016-fn-unaccent splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.f_unaccent(p_text text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS
$f$ SELECT ph15_portal.unaccent('ph15_portal.unaccent'::regdictionary, p_text) $f$;
COMMENT ON FUNCTION ph15_portal.f_unaccent(text) IS 'Bỏ dấu tiếng Việt, đánh dấu IMMUTABLE để dùng được trong trigger tsvector và chỉ mục (dự phòng PG FTS, tham số 15.search.engine).';
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.f_unaccent(text);

-- @file 15-0010-catalog.sql
-- @changeset ph15-0100-catalog-entry
CREATE TABLE ph15_portal.catalog_api (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  origin_tenant_id    ph15_portal.t_tenant NOT NULL,
  api_code            varchar(64)   NOT NULL,
  name                varchar(255)  NOT NULL,
  summary             varchar(1000),
  kind                varchar(8)    NOT NULL DEFAULT 'API',
  owner_org_code      varchar(64),
  provider_system_code varchar(64),
  field_domain        varchar(64),
  auth_method         varchar(32),
  data_class          varchar(12)   NOT NULL,
  visibility          varchar(12)   NOT NULL,
  portal_published    boolean       NOT NULL DEFAULT false,
  status              varchar(12)   NOT NULL DEFAULT 'PUBLISHED',
  tags                text[]        NOT NULL DEFAULT '{}',
  usage_path          varchar(512),
  sla                 jsonb         NOT NULL DEFAULT '{}',
  latest_version_no   varchar(32),
  source_version      bigint        NOT NULL,
  synced_at           timestamptz   NOT NULL,
  removed_at          timestamptz,
  search_tsv          tsvector,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_api PRIMARY KEY (id),
  CONSTRAINT uq_catalog_api_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_catalog_api_code UNIQUE (tenant_id, origin_tenant_id, api_code),
  CONSTRAINT ck_catalog_api_code CHECK (api_code ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
  CONSTRAINT ck_catalog_api_kind CHECK (kind IN ('API', 'EVENT')),
  CONSTRAINT ck_catalog_api_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_catalog_api_visibility CHECK (visibility IN ('TENANT', 'NATIONAL', 'PUBLIC')),
  CONSTRAINT ck_catalog_api_status CHECK (status IN ('PUBLISHED', 'DEPRECATED', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_catalog_api_removed CHECK (removed_at IS NULL OR NOT portal_published),
  CONSTRAINT ck_catalog_api_sla CHECK (jsonb_typeof(sla) = 'object'),
  CONSTRAINT ck_catalog_api_srcver CHECK (source_version >= 0)
);
CREATE INDEX ix_catalog_api_list ON ph15_portal.catalog_api (tenant_id, visibility, status) WHERE portal_published AND removed_at IS NULL;
CREATE INDEX ix_catalog_api_domain ON ph15_portal.catalog_api (tenant_id, field_domain, owner_org_code);
CREATE INDEX ix_catalog_api_tags ON ph15_portal.catalog_api USING gin (tags);
CREATE INDEX ix_catalog_api_tsv ON ph15_portal.catalog_api USING gin (search_tsv);
CREATE INDEX ix_catalog_api_synced ON ph15_portal.catalog_api (tenant_id, source_version);
CREATE TRIGGER tg_catalog_api_touch BEFORE UPDATE ON ph15_portal.catalog_api FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_catalog_api_immutable BEFORE UPDATE ON ph15_portal.catalog_api FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('api_code', 'origin_tenant_id', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.catalog_api');
COMMENT ON TABLE ph15_portal.catalog_api IS 'EN-15-01 Mục danh mục: bản sao chỉ đọc của API và dịch vụ sự kiện từ PH-02 (FR-15-001…008, 013).';
COMMENT ON COLUMN ph15_portal.catalog_api.origin_tenant_id IS 'Tenant sở hữu API; khác tenant_id khi mục đến từ danh mục quốc gia (mức NATIONAL, hạng OTHER_TENANT_USER).';
COMMENT ON COLUMN ph15_portal.catalog_api.portal_published IS 'Bản sao cờ portalPublished của PH-02 (FR-02-041); cổng không bao giờ tự đặt (BR-15-001).';
COMMENT ON COLUMN ph15_portal.catalog_api.source_version IS 'sourceVersion của PH-02, dùng làm con trỏ gia tăng updatedSince và so khớp khi đối soát (FR-15-061).';
COMMENT ON COLUMN ph15_portal.catalog_api.removed_at IS 'Đánh dấu mục thuộc removed[] của PH-02 (xóa mềm); không bao giờ DELETE dòng.';
COMMENT ON COLUMN ph15_portal.catalog_api.search_tsv IS 'tsvector không dấu (cấu hình simple) cho tìm kiếm dự phòng PG FTS; trigger tg_catalog_api_tsv.';
COMMENT ON COLUMN ph15_portal.catalog_api.usage_path IS 'Đường dẫn sử dụng gateway + context path (LGC-APIM-017, FR-02-005); không hiện cho khách ẩn danh khi dataClass khác PUBLIC (BR-15-006).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.catalog_api CASCADE;

-- @changeset ph15-0101-catalog-tsv splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_catalog_api_tsv() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.search_tsv :=
    setweight(to_tsvector('simple', ph15_portal.f_unaccent(coalesce(NEW.name, '') || ' ' || NEW.api_code)), 'A') ||
    setweight(to_tsvector('simple', ph15_portal.f_unaccent(coalesce(NEW.summary, '') || ' ' || array_to_string(NEW.tags, ' '))), 'B') ||
    setweight(to_tsvector('simple', ph15_portal.f_unaccent(coalesce(NEW.owner_org_code, '') || ' ' || coalesce(NEW.field_domain, ''))), 'C');
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_catalog_api_tsv BEFORE INSERT OR UPDATE ON ph15_portal.catalog_api FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_catalog_api_tsv();
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_catalog_api_tsv() CASCADE;

-- @changeset ph15-0110-catalog-api-version
CREATE TABLE ph15_portal.catalog_api_version (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  api_id              uuid          NOT NULL,
  version_no          varchar(32)   NOT NULL,
  status              varchar(12)   NOT NULL DEFAULT 'PUBLISHED',
  spec_hash           char(64),
  successor_version_no varchar(32),
  sunset_at           timestamptz,
  breaking            boolean       NOT NULL DEFAULT false,
  changelog_md        text,
  source_version      bigint        NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_api_version PRIMARY KEY (id),
  CONSTRAINT uq_catalog_api_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_catalog_api_version_no UNIQUE (tenant_id, api_id, version_no),
  CONSTRAINT fk_catalog_api_version_api FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_catalog_api_version_no CHECK (version_no ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
  CONSTRAINT ck_catalog_api_version_status CHECK (status IN ('PUBLISHED', 'DEPRECATED', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_catalog_api_version_hash CHECK (spec_hash IS NULL OR spec_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_catalog_api_version_sunset CHECK (sunset_at IS NULL OR status IN ('DEPRECATED', 'SUSPENDED', 'RETIRED'))
);
CREATE INDEX ix_catalog_api_version_api ON ph15_portal.catalog_api_version (tenant_id, api_id, status);
CREATE TRIGGER tg_catalog_api_version_touch BEFORE UPDATE ON ph15_portal.catalog_api_version FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.catalog_api_version');
COMMENT ON TABLE ph15_portal.catalog_api_version IS 'EN-15-01 Phiên bản API của bản sao danh mục: trạng thái PUBLISHED, DEPRECATED, SUSPENDED, RETIRED, kế nhiệm, hạn ngừng, thay đổi phá vỡ (FR-15-006, 011, 013).';
COMMENT ON COLUMN ph15_portal.catalog_api_version.successor_version_no IS 'Phiên bản kế nhiệm của PH-02 (lộ trình ngừng, banner DEPRECATED).';
COMMENT ON COLUMN ph15_portal.catalog_api_version.spec_hash IS 'Băm nội dung đặc tả hiện hành của phiên bản; đổi băm thì nạp lại catalog_spec.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.catalog_api_version CASCADE;

-- @changeset ph15-0111-catalog-spec
CREATE TABLE ph15_portal.catalog_spec (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  version_id          uuid          NOT NULL,
  spec_kind           varchar(10)   NOT NULL,
  content_hash        char(64)      NOT NULL,
  model_json          jsonb,
  size_bytes          integer       NOT NULL,
  object_key          varchar(512),
  loaded_at           timestamptz   NOT NULL DEFAULT now(),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_spec PRIMARY KEY (id),
  CONSTRAINT uq_catalog_spec_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_catalog_spec_kind UNIQUE (tenant_id, version_id, spec_kind),
  CONSTRAINT fk_catalog_spec_version FOREIGN KEY (version_id, tenant_id) REFERENCES ph15_portal.catalog_api_version (id, tenant_id),
  CONSTRAINT ck_catalog_spec_kind CHECK (spec_kind IN ('OPENAPI', 'ASYNCAPI')),
  CONSTRAINT ck_catalog_spec_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_catalog_spec_size CHECK (size_bytes BETWEEN 1 AND 20971520)
);
CREATE TRIGGER tg_catalog_spec_touch BEFORE UPDATE ON ph15_portal.catalog_spec FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.catalog_spec');
COMMENT ON TABLE ph15_portal.catalog_spec IS 'EN-15-02 Đặc tả đã nạp: một dòng cho mỗi phiên bản API và loại đặc tả OPENAPI, ASYNCAPI (FR-15-009…012).';
COMMENT ON COLUMN ph15_portal.catalog_spec.object_key IS 'Khóa đối tượng của bản đặc tả đã kết xuất (gộp $ref) trong bucket dh-{tenant}-portal-render; NULL khi chỉ giữ mô hình.';
COMMENT ON COLUMN ph15_portal.catalog_spec.model_json IS 'Mô hình đã phân tích (đường dẫn, thao tác, ví dụ) cho khung tài liệu, mẫu mã và sinh MOCK; sinh lại được từ bản gốc.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.catalog_spec CASCADE;

-- @changeset ph15-0120-sandbox-profile
CREATE TABLE ph15_portal.sandbox_profile (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  version_id          uuid          NOT NULL,
  mode                varchar(8)    NOT NULL DEFAULT 'OFF',
  backend_url         varchar(2048),
  example_policy      varchar(8)    NOT NULL DEFAULT 'FIRST',
  mock_overrides      jsonb         NOT NULL DEFAULT '{}',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sandbox_profile PRIMARY KEY (id),
  CONSTRAINT uq_sandbox_profile_version UNIQUE (tenant_id, version_id),
  CONSTRAINT fk_sandbox_profile_version FOREIGN KEY (version_id, tenant_id) REFERENCES ph15_portal.catalog_api_version (id, tenant_id),
  CONSTRAINT ck_sandbox_profile_mode CHECK (mode IN ('MOCK', 'BACKEND', 'OFF')),
  CONSTRAINT ck_sandbox_profile_policy CHECK (example_policy IN ('FIRST', 'RANDOM')),
  CONSTRAINT ck_sandbox_profile_backend CHECK (mode <> 'BACKEND' OR (backend_url IS NOT NULL AND backend_url ~ '^https://')),
  CONSTRAINT ck_sandbox_profile_url CHECK (backend_url IS NULL OR backend_url ~ '^https://'),
  CONSTRAINT ck_sandbox_profile_overrides CHECK (jsonb_typeof(mock_overrides) = 'object')
);
CREATE TRIGGER tg_sandbox_profile_touch BEFORE UPDATE ON ph15_portal.sandbox_profile FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.sandbox_profile');
COMMENT ON TABLE ph15_portal.sandbox_profile IS 'EN-15-03 Hồ sơ sandbox của dịch vụ: chế độ MOCK, BACKEND hoặc OFF theo từng phiên bản API (FR-15-034, 036, 037).';
COMMENT ON COLUMN ph15_portal.sandbox_profile.backend_url IS 'Backend thử do chủ dịch vụ khai báo, bắt buộc HTTPS, kiểm lại danh sách egress lúc gọi (BR-15-018); không hiện cho khách ẩn danh.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.sandbox_profile CASCADE;

-- @changeset ph15-0130-prod-try-grant
CREATE TABLE ph15_portal.try_prod_grant (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  api_id            uuid          NOT NULL,
  status               varchar(8)    NOT NULL DEFAULT 'OFF',
  allow_write         boolean       NOT NULL DEFAULT false,
  proposed_by         varchar(64),
  proposed_at         timestamptz,
  approved_by         varchar(64),
  approved_at         timestamptz,
  valid_until          timestamptz,
  reason              varchar(1000),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_try_prod_grant PRIMARY KEY (id),
  CONSTRAINT uq_try_prod_grant_entry UNIQUE (tenant_id, api_id),
  CONSTRAINT fk_try_prod_grant_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_try_prod_grant_status CHECK (status IN ('OFF', 'PENDING', 'ENABLED', 'EXPIRED')),
  CONSTRAINT ck_try_prod_grant_pending CHECK (status NOT IN ('PENDING', 'ENABLED', 'EXPIRED') OR proposed_by IS NOT NULL),
  CONSTRAINT ck_try_prod_grant_four_eyes CHECK (status NOT IN ('ENABLED', 'EXPIRED')
    OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND approved_by <> proposed_by AND valid_until IS NOT NULL)),
  CONSTRAINT ck_try_prod_grant_ttl CHECK (approved_at IS NULL OR valid_until IS NULL OR valid_until <= approved_at + interval '90 days')
);
CREATE INDEX ix_try_prod_grant_expiry ON ph15_portal.try_prod_grant (tenant_id, valid_until) WHERE status = 'ENABLED';
CREATE TRIGGER tg_try_prod_grant_touch BEFORE UPDATE ON ph15_portal.try_prod_grant FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.try_prod_grant');
COMMENT ON TABLE ph15_portal.try_prod_grant IS 'EN-15-13 Cho phép thử production theo dịch vụ, mặc định OFF, bốn mắt, tối đa 90 ngày (FR-15-042, BR-15-019…021).';
COMMENT ON COLUMN ph15_portal.try_prod_grant.allow_write IS 'Luôn false ở Đợt 2 (BR-15-020: chỉ GET, HEAD); chốt true chỉ khi Q15-05 được ATTT quyết, kiểm ở ứng dụng.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.try_prod_grant CASCADE;

-- @file 15-0020-content.sql
-- @changeset ph15-0200-content-page
CREATE TABLE ph15_portal.content_page (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  page_code           varchar(63)   NOT NULL,
  lang                varchar(2)    NOT NULL DEFAULT 'vi',
  type                varchar(12)   NOT NULL,
  audience            varchar(10)   NOT NULL DEFAULT 'LOGGED_IN',
  title               varchar(255)  NOT NULL,
  status              varchar(12)   NOT NULL DEFAULT 'DRAFT',
  published_version_id uuid,
  api_id            uuid,
  tags                text[]        NOT NULL DEFAULT '{}',
  source              varchar(10)   NOT NULL DEFAULT 'MANUAL',
  source_ref          varchar(512),
  search_tsv          tsvector,
  deleted_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_content_page PRIMARY KEY (id),
  CONSTRAINT uq_content_page_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_content_page_code UNIQUE (tenant_id, page_code, lang),
  CONSTRAINT fk_content_page_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_content_page_code CHECK (page_code ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
  CONSTRAINT ck_content_page_lang CHECK (lang IN ('vi', 'en')),
  CONSTRAINT ck_content_page_type CHECK (type IN ('GUIDE', 'QUICKSTART', 'FAQ', 'ANNOUNCEMENT', 'TERMS')),
  CONSTRAINT ck_content_page_audience CHECK (audience IN ('PUBLIC', 'LOGGED_IN', 'TENANT')),
  CONSTRAINT ck_content_page_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'UNPUBLISHED', 'ARCHIVED')),
  CONSTRAINT ck_content_page_source CHECK (source IN ('MANUAL', 'GIT', 'MIGRATION')),
  CONSTRAINT ck_content_page_published CHECK (status <> 'PUBLISHED' OR published_version_id IS NOT NULL)
);
CREATE INDEX ix_content_page_list ON ph15_portal.content_page (tenant_id, type, audience) WHERE status = 'PUBLISHED' AND deleted_at IS NULL;
CREATE INDEX ix_content_page_entry ON ph15_portal.content_page (tenant_id, api_id) WHERE api_id IS NOT NULL;
CREATE INDEX ix_content_page_tsv ON ph15_portal.content_page USING gin (search_tsv);
CREATE TRIGGER tg_content_page_touch BEFORE UPDATE ON ph15_portal.content_page FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_content_page_immutable BEFORE UPDATE ON ph15_portal.content_page FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('page_code', 'lang', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.content_page');
COMMENT ON TABLE ph15_portal.content_page IS 'EN-15-04 Trang nội dung Markdown: hướng dẫn, bắt đầu nhanh, hỏi đáp, thông báo, điều khoản (FR-15-014…017). Không DELETE: pageCode không dùng lại (BR-15-007).';
COMMENT ON COLUMN ph15_portal.content_page.published_version_id IS 'Phiên bản đang hiển thị; khóa ngoại hoãn tới cuối giao dịch vì hai bảng trỏ vòng tròn.';
COMMENT ON COLUMN ph15_portal.content_page.source_ref IS 'Với source = GIT: đường dẫn tệp trong kho (portal.yaml); với MIGRATION: khóa trang ở portal Gravitee cũ.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.content_page CASCADE;

-- @changeset ph15-0201-content-page-tsv splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_content_page_tsv() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.search_tsv :=
    setweight(to_tsvector('simple', ph15_portal.f_unaccent(NEW.title || ' ' || NEW.page_code)), 'A') ||
    setweight(to_tsvector('simple', ph15_portal.f_unaccent(array_to_string(NEW.tags, ' '))), 'B');
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_content_page_tsv BEFORE INSERT OR UPDATE ON ph15_portal.content_page FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_content_page_tsv();
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_content_page_tsv() CASCADE;

-- @changeset ph15-0210-content-page-version
CREATE TABLE ph15_portal.content_page_version (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  page_id             uuid          NOT NULL,
  version_no          integer       NOT NULL,
  body_md             text          NOT NULL,
  content_hash        char(64)      NOT NULL,
  status              varchar(12)   NOT NULL DEFAULT 'DRAFT',
  last_edited_by      varchar(64)   NOT NULL,
  submitted_by        varchar(64),
  submitted_at        timestamptz,
  reviewed_by         varchar(64),
  reviewed_at         timestamptz,
  review_note         varchar(1000),
  published_at        timestamptz,
  source_commit       varchar(64),
  migration_id        uuid,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_content_page_version PRIMARY KEY (id),
  CONSTRAINT uq_content_page_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_content_page_version_no UNIQUE (tenant_id, page_id, version_no),
  CONSTRAINT fk_content_page_version_page FOREIGN KEY (page_id, tenant_id) REFERENCES ph15_portal.content_page (id, tenant_id),
  CONSTRAINT ck_content_page_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_content_page_version_size CHECK (octet_length(body_md) <= 204800),
  CONSTRAINT ck_content_page_version_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_content_page_version_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'REJECTED', 'PUBLISHED', 'SUPERSEDED', 'UNPUBLISHED')),
  CONSTRAINT ck_content_page_version_submit CHECK (status NOT IN ('IN_REVIEW', 'REJECTED', 'PUBLISHED', 'SUPERSEDED', 'UNPUBLISHED')
    OR (submitted_by IS NOT NULL AND submitted_at IS NOT NULL)),
  CONSTRAINT ck_content_page_version_four_eyes CHECK (status NOT IN ('REJECTED', 'PUBLISHED', 'SUPERSEDED', 'UNPUBLISHED')
    OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL AND reviewed_by <> submitted_by AND reviewed_by <> last_edited_by))
);
CREATE UNIQUE INDEX uq_content_page_version_published ON ph15_portal.content_page_version (tenant_id, page_id) WHERE status = 'PUBLISHED';
CREATE INDEX ix_content_page_version_queue ON ph15_portal.content_page_version (tenant_id, submitted_at) WHERE status = 'IN_REVIEW';
CREATE INDEX ix_content_page_version_migration ON ph15_portal.content_page_version (tenant_id, migration_id) WHERE migration_id IS NOT NULL;
CREATE TRIGGER tg_content_page_version_touch BEFORE UPDATE ON ph15_portal.content_page_version FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.content_page_version');
ALTER TABLE ph15_portal.content_page ADD CONSTRAINT fk_content_page_published FOREIGN KEY (published_version_id, tenant_id)
  REFERENCES ph15_portal.content_page_version (id, tenant_id) DEFERRABLE INITIALLY DEFERRED;
COMMENT ON TABLE ph15_portal.content_page_version IS 'EN-15-05 Phiên bản trang: nội dung Markdown, vòng đời soạn, duyệt, đăng bốn mắt (FR-15-014…016, 018, BR-15-012).';
COMMENT ON COLUMN ph15_portal.content_page_version.last_edited_by IS 'Người sửa gần nhất; người duyệt phải khác người này, người gửi và (BR-15-012).';
COMMENT ON COLUMN ph15_portal.content_page_version.body_md IS 'Markdown đã qua bộ lọc BR-15-013 ở ứng dụng; ≤ 200 KB; bất biến khi PUBLISHED hoặc SUPERSEDED (trigger tg_version_body_guard).';
-- @rollback ALTER TABLE ph15_portal.content_page DROP CONSTRAINT IF EXISTS fk_content_page_published; DROP TABLE IF EXISTS ph15_portal.content_page_version CASCADE;

-- @changeset ph15-0211-version-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_version_body_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status IN ('PUBLISHED', 'SUPERSEDED')
     AND (NEW.body_md IS DISTINCT FROM OLD.body_md OR NEW.content_hash IS DISTINCT FROM OLD.content_hash) THEN
    RAISE EXCEPTION 'Nội dung phiên bản % đã đăng không sửa được; tạo phiên bản nháp mới (FR-15-016)', OLD.version_no USING ERRCODE = 'P1502';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_content_page_version_body BEFORE UPDATE ON ph15_portal.content_page_version FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_version_body_guard();
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_version_body_guard() CASCADE;

-- @changeset ph15-0220-portal-file
CREATE TABLE ph15_portal.content_attachment (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  purpose             varchar(20)   NOT NULL,
  bucket              varchar(63)   NOT NULL,
  object_key          varchar(512)  NOT NULL,
  file_name           varchar(255)  NOT NULL,
  mime_type           varchar(64)   NOT NULL,
  size_bytes          bigint        NOT NULL,
  sha256              char(64)      NOT NULL,
  scan_status         varchar(10)   NOT NULL DEFAULT 'PENDING',
  page_id             uuid,
  migration_id        uuid,
  expires_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_content_attachment PRIMARY KEY (id),
  CONSTRAINT uq_content_attachment_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_content_attachment_object UNIQUE (bucket, object_key),
  CONSTRAINT fk_content_attachment_page FOREIGN KEY (page_id, tenant_id) REFERENCES ph15_portal.content_page (id, tenant_id),
  CONSTRAINT ck_content_attachment_purpose CHECK (purpose IN ('PAGE_IMAGE', 'LOGO', 'MIGRATION_PACKAGE')),
  CONSTRAINT ck_content_attachment_scan CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED')),
  CONSTRAINT ck_content_attachment_hash CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_content_attachment_bucket CHECK (bucket ~ '^dh-t[0-9]{2}-portal(-[a-z]+)?$'),
  CONSTRAINT ck_content_attachment_image CHECK (purpose <> 'PAGE_IMAGE' OR (mime_type IN ('image/png', 'image/jpeg', 'image/webp') AND size_bytes BETWEEN 1 AND 5242880)),
  CONSTRAINT ck_content_attachment_logo CHECK (purpose <> 'LOGO' OR (mime_type IN ('image/png', 'image/webp') AND size_bytes BETWEEN 1 AND 524288)),
  CONSTRAINT ck_content_attachment_package CHECK (purpose <> 'MIGRATION_PACKAGE' OR (mime_type = 'application/zip' AND size_bytes BETWEEN 1 AND 52428800))
);
CREATE INDEX ix_content_attachment_page ON ph15_portal.content_attachment (tenant_id, page_id) WHERE page_id IS NOT NULL;
CREATE INDEX ix_content_attachment_expiry ON ph15_portal.content_attachment (expires_at) WHERE expires_at IS NOT NULL;
CREATE TRIGGER tg_content_attachment_touch BEFORE UPDATE ON ph15_portal.content_attachment FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.content_attachment');
COMMENT ON TABLE ph15_portal.content_attachment IS 'Siêu dữ liệu đối tượng trong kho Garage: ảnh trang, logo, gói di trú, bản gốc đặc tả (BR-15-013, FR-15-056, 062). Không SVG; giới hạn kích thước theo Phụ lục A.6.';
COMMENT ON COLUMN ph15_portal.content_attachment.scan_status IS 'Kết quả quét mã độc (SEC-45): chỉ CLEAN mới được phục vụ hoặc xử lý.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.content_attachment CASCADE;

-- @changeset ph15-0230-git-source
CREATE TABLE ph15_portal.content_git_source (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  name                varchar(128)  NOT NULL,
  repo_url            varchar(512)  NOT NULL,
  branch              varchar(128)  NOT NULL DEFAULT 'main',
  path                varchar(255)  NOT NULL DEFAULT 'docs/',
  secret_ref          varchar(512),
  enabled             boolean       NOT NULL DEFAULT true,
  last_commit         varchar(64),
  last_synced_at      timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_content_git_source PRIMARY KEY (id),
  CONSTRAINT uq_content_git_source_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_content_git_source_repo UNIQUE (tenant_id, repo_url, branch, path),
  CONSTRAINT ck_content_git_source_url CHECK (repo_url ~ '^https://'),
  CONSTRAINT ck_content_git_source_secret CHECK (secret_ref IS NULL OR secret_ref ~ '^kv/dh/[tT][0-9]{2}/portal/')
);
CREATE TRIGGER tg_content_git_source_touch BEFORE UPDATE ON ph15_portal.content_git_source FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.content_git_source');
COMMENT ON TABLE ph15_portal.content_git_source IS 'Nguồn Git cho tài liệu tích hợp (FR-15-018): chỉ tham chiếu mã truy cập đã ghi một chiều vào OpenBao, không lưu bí mật.';
COMMENT ON COLUMN ph15_portal.content_git_source.secret_ref IS 'Đường dẫn OpenBao của mã truy cập chỉ đọc; không bao giờ hiển thị lại (FR-15-018 bước 1).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.content_git_source CASCADE;

-- @file 15-0030-account.sql
-- @changeset ph15-0300-dev-account
CREATE TABLE ph15_portal.dev_account (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  user_id             varchar(64)   NOT NULL,
  source              varchar(12)   NOT NULL,
  status              varchar(16)   NOT NULL,
  email               varchar(254),
  full_name           varchar(255)  NOT NULL,
  organization        varchar(255),
  contract_no         varchar(64),
  sponsor_unit        varchar(255),
  phone_enc           bytea,
  dek_wrapped         bytea,
  verification_token_hash char(64),
  verification_expires_at timestamptz,
  email_verified_at   timestamptz,
  approved_by         varchar(64),
  approved_at         timestamptz,
  decision_reason     varchar(1000),
  last_active_at      timestamptz,
  anonymized_at       timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_account PRIMARY KEY (id),
  CONSTRAINT uq_dev_account_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_dev_account_user UNIQUE (tenant_id, user_id),
  CONSTRAINT ck_dev_account_source CHECK (source IN ('TENANT_SSO', 'DH_DEV')),
  CONSTRAINT ck_dev_account_status CHECK (status IN ('PENDING_EMAIL', 'PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'LOCKED', 'DISABLED', 'EXPIRED', 'ERASED')),
  CONSTRAINT ck_dev_account_sso_state CHECK (source <> 'TENANT_SSO' OR status IN ('ACTIVE', 'LOCKED', 'DISABLED', 'ERASED')),
  CONSTRAINT ck_dev_account_email_case CHECK (email IS NULL OR email = lower(email)),
  CONSTRAINT ck_dev_account_email_erased CHECK (email IS NOT NULL OR status = 'ERASED'),
  CONSTRAINT ck_dev_account_approved CHECK (source <> 'DH_DEV' OR status NOT IN ('ACTIVE', 'LOCKED')
    OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND organization IS NOT NULL AND contract_no IS NOT NULL AND email_verified_at IS NOT NULL)),
  CONSTRAINT ck_dev_account_phone CHECK ((phone_enc IS NULL) = (dek_wrapped IS NULL)),
  CONSTRAINT ck_dev_account_token CHECK (verification_token_hash IS NULL OR verification_token_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dev_account_erased CHECK (status <> 'ERASED' OR (anonymized_at IS NOT NULL AND phone_enc IS NULL AND dek_wrapped IS NULL AND email IS NULL))
);
CREATE UNIQUE INDEX uq_dev_account_email ON ph15_portal.dev_account (tenant_id, source, email) WHERE email IS NOT NULL;
CREATE INDEX ix_dev_account_queue ON ph15_portal.dev_account (tenant_id, created_at) WHERE status = 'PENDING_APPROVAL';
CREATE INDEX ix_dev_account_idle ON ph15_portal.dev_account (tenant_id, last_active_at) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_dev_account_touch BEFORE UPDATE ON ph15_portal.dev_account FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_account');
COMMENT ON TABLE ph15_portal.dev_account IS 'EN-15-06 Tài khoản nhà phát triển: dh-dev (vòng đời đầy đủ) và bản ghi tạo khi cán bộ SSO đăng nhập lần đầu (FR-15-019…024, 058, 059).';
COMMENT ON COLUMN ph15_portal.dev_account.user_id IS 'Chủ thể (sub) của Keycloak: realm tenant hoặc realm dh-dev; mật khẩu và MFA do PH-12 giữ, cổng không lưu.';
COMMENT ON COLUMN ph15_portal.dev_account.phone_enc IS 'Điện thoại (tùy chọn) mã hóa envelope AES-256-GCM, DEK bọc bằng KEK transit/dh/{tenant}/portal/dev-kek (ADR-032); chỉ module portal giải mã khi quản trị mở hồ sơ.';
COMMENT ON COLUMN ph15_portal.dev_account.verification_token_hash IS 'SHA-256 của mã xác minh thư; hết hạn sau 24 giờ (BR-15-028), dùng một lần.';
COMMENT ON COLUMN ph15_portal.dev_account.anonymized_at IS 'Thời điểm ẩn danh (xóa theo yêu cầu hoặc sau 15.dev.anonymize-after-months); khi đó email, điện thoại bị xóa, họ tên thay bằng chuỗi cố định (BR-15-029).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.dev_account CASCADE;

-- @changeset ph15-0310-dev-team
CREATE TABLE ph15_portal.dev_team (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  team_code           varchar(41)   NOT NULL,
  name                varchar(255)  NOT NULL,
  description         varchar(1000),
  deleted_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_team PRIMARY KEY (id),
  CONSTRAINT uq_dev_team_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_dev_team_code UNIQUE (tenant_id, team_code),
  CONSTRAINT ck_dev_team_code CHECK (team_code ~ '^[a-z][a-z0-9-]{2,40}$')
);
CREATE TRIGGER tg_dev_team_touch BEFORE UPDATE ON ph15_portal.dev_team FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_dev_team_immutable BEFORE UPDATE ON ph15_portal.dev_team FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('team_code', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.dev_team');
COMMENT ON TABLE ph15_portal.dev_team IS 'EN-15-07 Nhóm phát triển (FR-15-022). Xóa mềm; teamCode không dùng lại (BR-15-007).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.dev_team CASCADE;

-- @changeset ph15-0311-team-member
CREATE TABLE ph15_portal.dev_team_member (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  team_id             uuid          NOT NULL,
  account_id          uuid          NOT NULL,
  role                varchar(10)   NOT NULL DEFAULT 'DEVELOPER',
  invite_status       varchar(10)   NOT NULL DEFAULT 'PENDING',
  invited_by          varchar(64),
  invite_expires_at   timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_team_member PRIMARY KEY (id),
  CONSTRAINT uq_dev_team_member UNIQUE (team_id, account_id),
  CONSTRAINT fk_dev_team_member_team FOREIGN KEY (team_id, tenant_id) REFERENCES ph15_portal.dev_team (id, tenant_id),
  CONSTRAINT fk_dev_team_member_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT ck_dev_team_member_role CHECK (role IN ('OWNER', 'DEVELOPER', 'VIEWER')),
  CONSTRAINT ck_dev_team_member_invite CHECK (invite_status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED')),
  CONSTRAINT ck_dev_team_member_owner CHECK (role <> 'OWNER' OR invite_status = 'ACCEPTED')
);
CREATE INDEX ix_dev_team_member_account ON ph15_portal.dev_team_member (tenant_id, account_id) WHERE invite_status = 'ACCEPTED';
CREATE TRIGGER tg_dev_team_member_touch BEFORE UPDATE ON ph15_portal.dev_team_member FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_team_member');
COMMENT ON TABLE ph15_portal.dev_team_member IS 'EN-15-07 Thành viên nhóm và lời mời (PENDING, ACCEPTED, DECLINED, EXPIRED) với vai trò OWNER, DEVELOPER, VIEWER (FR-15-022, 033).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.dev_team_member CASCADE;

-- @changeset ph15-0320-terms
CREATE TABLE ph15_portal.dev_terms (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  version_label       varchar(32)   NOT NULL,
  page_version_id     uuid          NOT NULL,
  content_hash        char(64)      NOT NULL,
  effective_from      timestamptz   NOT NULL,
  retired_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_dev_terms PRIMARY KEY (id),
  CONSTRAINT uq_dev_terms_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_dev_terms_label UNIQUE (tenant_id, version_label),
  CONSTRAINT fk_dev_terms_page FOREIGN KEY (page_version_id, tenant_id) REFERENCES ph15_portal.content_page_version (id, tenant_id),
  CONSTRAINT ck_dev_terms_hash CHECK (content_hash ~ '^[0-9a-f]{64}$')
);
CREATE TRIGGER tg_dev_terms_touch BEFORE UPDATE ON ph15_portal.dev_terms FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_terms');
COMMENT ON TABLE ph15_portal.dev_terms IS 'EN-15-16 Điều khoản sử dụng có phiên bản: tham chiếu phiên bản trang loại TERMS đã đăng; băm nội dung để chứng minh người dùng chấp nhận đúng văn bản (FR-15-023).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.dev_terms CASCADE;

-- @changeset ph15-0321-terms-acceptance
CREATE TABLE ph15_portal.dev_terms_acceptance (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  terms_id            uuid          NOT NULL,
  accepted_at         timestamptz   NOT NULL DEFAULT now(),
  client_ip_hash      char(64),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  CONSTRAINT pk_dev_terms_acceptance PRIMARY KEY (id),
  CONSTRAINT uq_dev_terms_acceptance UNIQUE (account_id, terms_id),
  CONSTRAINT fk_dev_terms_acceptance_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_dev_terms_acceptance_terms FOREIGN KEY (terms_id, tenant_id) REFERENCES ph15_portal.dev_terms (id, tenant_id),
  CONSTRAINT ck_dev_terms_acceptance_ip CHECK (client_ip_hash IS NULL OR client_ip_hash ~ '^[0-9a-f]{64}$')
);
CREATE TRIGGER tg_dev_terms_acceptance_ro BEFORE UPDATE OR DELETE ON ph15_portal.dev_terms_acceptance FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_append_only();
CALL ph15_portal.p_enable_rls('ph15_portal.dev_terms_acceptance');
COMMENT ON TABLE ph15_portal.dev_terms_acceptance IS 'EN-15-16 Bằng chứng chấp nhận điều khoản theo người dùng; chỉ thêm, không sửa (BR-15-008). Địa chỉ IP chỉ lưu băm.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.dev_terms_acceptance CASCADE;

-- @file 15-0040-app.sql
-- @changeset ph15-0400-sandbox-app
CREATE TABLE ph15_portal.app (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_code            varchar(41)   NOT NULL,
  name                varchar(255)  NOT NULL,
  description         varchar(1000),
  owner_type          varchar(4)    NOT NULL,
  owner_account_id    uuid,
  owner_team_id       uuid,
  status              varchar(10)   NOT NULL DEFAULT 'ACTIVE',
  status_reason       varchar(1000),
  linked_system_code  varchar(64),
  daily_quota_override integer,
  last_used_at        timestamptz,
  archived_at         timestamptz,
  deleted_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app PRIMARY KEY (id),
  CONSTRAINT uq_app_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_app_code UNIQUE (tenant_id, app_code),
  CONSTRAINT fk_app_account FOREIGN KEY (owner_account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_app_team FOREIGN KEY (owner_team_id, tenant_id) REFERENCES ph15_portal.dev_team (id, tenant_id),
  CONSTRAINT ck_app_code CHECK (app_code ~ '^[a-z][a-z0-9-]{2,40}$'),
  CONSTRAINT ck_app_owner_type CHECK (owner_type IN ('USER', 'TEAM')),
  CONSTRAINT ck_app_owner CHECK ((owner_type = 'USER' AND owner_account_id IS NOT NULL AND owner_team_id IS NULL)
    OR (owner_type = 'TEAM' AND owner_team_id IS NOT NULL AND owner_account_id IS NULL)),
  CONSTRAINT ck_app_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'ARCHIVED')),
  CONSTRAINT ck_app_archived CHECK (status <> 'ARCHIVED' OR archived_at IS NOT NULL),
  CONSTRAINT ck_app_quota CHECK (daily_quota_override IS NULL OR daily_quota_override BETWEEN 100 AND 50000)
);
CREATE INDEX ix_app_owner_user ON ph15_portal.app (tenant_id, owner_account_id) WHERE deleted_at IS NULL AND owner_account_id IS NOT NULL;
CREATE INDEX ix_app_owner_team ON ph15_portal.app (tenant_id, owner_team_id) WHERE deleted_at IS NULL AND owner_team_id IS NOT NULL;
CREATE INDEX ix_app_idle ON ph15_portal.app (tenant_id, last_used_at) WHERE status = 'ACTIVE';
CREATE INDEX ix_app_purge ON ph15_portal.app (archived_at) WHERE status = 'ARCHIVED' AND deleted_at IS NULL;
CREATE TRIGGER tg_app_touch BEFORE UPDATE ON ph15_portal.app FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_app_immutable BEFORE UPDATE ON ph15_portal.app FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('app_code', 'owner_type', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.app');
COMMENT ON TABLE ph15_portal.app IS 'EN-15-08 Ứng dụng sandbox của một người hoặc một nhóm (FR-15-025, 026, 059). Không DELETE: appCode không dùng lại; xóa sau 30 ngày lưu trữ là đặt deleted_at (BR-15-007, BR-15-034).';
COMMENT ON COLUMN ph15_portal.app.linked_system_code IS 'Mã HTTT (PH-01) mà ứng dụng được giao để xem tham chiếu thông tin xác thực production (FR-15-032, BR-15-015); NULL = không giao. Cách giao chốt ở Q15-52.';
COMMENT ON COLUMN ph15_portal.app.daily_quota_override IS 'Hạn mức lượt thử mỗi ngày riêng của ứng dụng (100…50.000, trần của 15.try.rate-per-app-day); NULL = theo tham số tenant.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.app CASCADE;

-- @changeset ph15-0410-app-member
CREATE TABLE ph15_portal.app_member (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_id              uuid          NOT NULL,
  account_id          uuid          NOT NULL,
  role                varchar(10)   NOT NULL DEFAULT 'DEVELOPER',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app_member PRIMARY KEY (id),
  CONSTRAINT uq_app_member UNIQUE (app_id, account_id),
  CONSTRAINT fk_app_member_app FOREIGN KEY (app_id, tenant_id) REFERENCES ph15_portal.app (id, tenant_id),
  CONSTRAINT fk_app_member_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT ck_app_member_role CHECK (role IN ('OWNER', 'DEVELOPER', 'VIEWER'))
);
CREATE INDEX ix_app_member_account ON ph15_portal.app_member (tenant_id, account_id);
CREATE TRIGGER tg_app_member_touch BEFORE UPDATE ON ph15_portal.app_member FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.app_member');
COMMENT ON TABLE ph15_portal.app_member IS 'Giao ứng dụng cho thành viên với vai trò OWNER, DEVELOPER, VIEWER; PERM-15-app và PERM-15-try chỉ áp trên ứng dụng mà người dùng là thành viên (FR-15-033, BR-15-009).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.app_member CASCADE;

-- @changeset ph15-0420-sandbox-credential
CREATE TABLE ph15_portal.app_credential (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_id              uuid          NOT NULL,
  kind                varchar(20)   NOT NULL,
  status              varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  provisioning_state  varchar(14)   NOT NULL DEFAULT 'PENDING',
  client_id           varchar(128),
  keycloak_client_uuid varchar(64),
  key_prefix       char(8)       NOT NULL,
  key_hash         char(64),
  expires_at          timestamptz   NOT NULL,
  rotated_from_id     uuid,
  grace_until         timestamptz,
  revoked_at          timestamptz,
  revoke_reason       varchar(200),
  last_used_at        timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_app_credential PRIMARY KEY (id),
  CONSTRAINT uq_app_credential_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_app_credential_app FOREIGN KEY (app_id, tenant_id) REFERENCES ph15_portal.app (id, tenant_id),
  CONSTRAINT fk_app_credential_prev FOREIGN KEY (rotated_from_id, tenant_id) REFERENCES ph15_portal.app_credential (id, tenant_id),
  CONSTRAINT ck_app_credential_prov CHECK (provisioning_state IN ('PENDING', 'PROVISIONED', 'FAILED', 'DEPROVISIONING')),
  CONSTRAINT ck_app_credential_kind CHECK (kind IN ('CLIENT_CREDENTIALS', 'API_KEY')),
  CONSTRAINT ck_app_credential_status CHECK (status IN ('ACTIVE', 'ROTATING', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_app_credential_client CHECK ((kind = 'CLIENT_CREDENTIALS' AND client_id IS NOT NULL AND client_id ~ '^sbx-t[0-9]{2}-[a-z][a-z0-9-]{2,40}-[0-9]+$')
    OR (kind = 'API_KEY' AND client_id IS NULL AND key_hash IS NOT NULL AND key_hash ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_app_credential_ttl CHECK (expires_at <= created_at + interval '180 days'),
  CONSTRAINT ck_app_credential_revoked CHECK (status <> 'REVOKED' OR revoked_at IS NOT NULL),
  CONSTRAINT ck_app_credential_grace CHECK (status <> 'ROTATING' OR (grace_until IS NOT NULL AND grace_until <= updated_at + interval '72 hours' + interval '1 minute')),
  CONSTRAINT ck_app_credential_prefix CHECK (key_prefix ~ '^[A-Za-z0-9_-]{8}$'),
  CONSTRAINT ck_app_credential_active CHECK (status NOT IN ('ACTIVE', 'ROTATING') OR provisioning_state IN ('PENDING', 'PROVISIONED'))
);
CREATE UNIQUE INDEX uq_app_credential_client ON ph15_portal.app_credential (client_id) WHERE client_id IS NOT NULL;
CREATE UNIQUE INDEX uq_app_credential_prefix ON ph15_portal.app_credential (tenant_id, key_prefix) WHERE kind = 'API_KEY';
CREATE INDEX ix_app_credential_app ON ph15_portal.app_credential (tenant_id, app_id, status);
CREATE INDEX ix_app_credential_expiry ON ph15_portal.app_credential (expires_at) WHERE status IN ('ACTIVE', 'ROTATING');
CREATE TRIGGER tg_app_credential_touch BEFORE UPDATE ON ph15_portal.app_credential FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.app_credential');
COMMENT ON TABLE ph15_portal.app_credential IS 'EN-15-09 Thông tin xác thực sandbox: client_credentials ở realm dh-dev hoặc API key sandbox (FR-15-027…031). Không lưu bí mật, chỉ tiền tố 8 ký tự và băm (BR-15-011).';
COMMENT ON COLUMN ph15_portal.app_credential.key_hash IS 'HMAC-SHA256 (hex) của khóa API sandbox dhsk_… với pepper giữ ở OpenBao, để forward-auth đối chiếu; với client_credentials bí mật do Keycloak giữ nên cột để trống.';
COMMENT ON COLUMN ph15_portal.app_credential.provisioning_state IS 'Trạng thái saga cấp phát ở Keycloak realm dh-dev hoặc kho khóa: PENDING (đang tạo), PROVISIONED, FAILED (bù trừ), DEPROVISIONING (đang thu hồi); chỉ PENDING, PROVISIONED được xác thực.';
COMMENT ON COLUMN ph15_portal.app_credential.expires_at IS 'Tối đa 180 ngày kể từ lúc cấp (SEC-24); mặc định 15.cred.ttl-days = 90.';
COMMENT ON COLUMN ph15_portal.app_credential.grace_until IS 'Hết thời gian chuyển tiếp khi xoay vòng (≤ 72 giờ, 15.cred.rotate-grace-hours); sau mốc này bản ROTATING thành EXPIRED.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.app_credential CASCADE;

-- @changeset ph15-0430-prod-credential-ref
CREATE TABLE ph15_portal.prod_credential_ref (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  system_code         varchar(64)   NOT NULL,
  client_id           varchar(128)  NOT NULL,
  auth_method         varchar(24)   NOT NULL,
  fingerprint_prefix  char(16),
  expires_at          timestamptz,
  status              varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  source_version      bigint        NOT NULL DEFAULT 0,
  synced_at           timestamptz   NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_prod_credential_ref PRIMARY KEY (id),
  CONSTRAINT uq_prod_credential_ref UNIQUE (tenant_id, system_code, client_id),
  CONSTRAINT ck_prod_credential_ref_method CHECK (auth_method IN ('tls_client_auth', 'private_key_jwt', 'client_secret_basic')),
  CONSTRAINT ck_prod_credential_ref_status CHECK (status IN ('ACTIVE', 'EXPIRING', 'REVOKED')),
  CONSTRAINT ck_prod_credential_ref_fp CHECK (fingerprint_prefix IS NULL OR fingerprint_prefix ~ '^[0-9a-f]{16}$')
);
CREATE INDEX ix_prod_credential_ref_system ON ph15_portal.prod_credential_ref (tenant_id, system_code);
CREATE TRIGGER tg_prod_credential_ref_touch BEFORE UPDATE ON ph15_portal.prod_credential_ref FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.prod_credential_ref');
COMMENT ON TABLE ph15_portal.prod_credential_ref IS 'EN-15-10 Tham chiếu thông tin xác thực production, bản sao chỉ đọc từ PH-01: không có cột bí mật; dấu vân tay chỉ 16 ký tự đầu (FR-15-032, BR-15-015).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.prod_credential_ref CASCADE;

-- @file 15-0050-try.sql
-- @changeset ph15-0500-try-run
CREATE TABLE ph15_portal.try_run (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  app_id              uuid          NOT NULL,
  account_id          uuid          NOT NULL,
  api_id            uuid          NOT NULL,
  version_no          varchar(32)   NOT NULL,
  method              varchar(7)    NOT NULL,
  path_template       varchar(512)  NOT NULL,
  environment         varchar(10)   NOT NULL,
  sandbox_mode        varchar(8),
  result              varchar(14)   NOT NULL,
  http_status         smallint,
  latency_ms          integer,
  trace_id            char(32)      NOT NULL,
  request_snapshot    jsonb,
  executed_at         timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_try_run PRIMARY KEY (id, executed_at),
  CONSTRAINT fk_try_run_app FOREIGN KEY (app_id, tenant_id) REFERENCES ph15_portal.app (id, tenant_id),
  CONSTRAINT fk_try_run_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_try_run_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_try_run_method CHECK (method IN ('GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE')),
  CONSTRAINT ck_try_run_env CHECK (environment IN ('SANDBOX', 'PRODUCTION')),
  CONSTRAINT ck_try_run_mode CHECK (sandbox_mode IS NULL OR sandbox_mode IN ('MOCK', 'BACKEND')),
  CONSTRAINT ck_try_run_result CHECK (result IN ('OK', 'UPSTREAM_ERROR', 'DENIED', 'THROTTLED', 'TIMEOUT')),
  CONSTRAINT ck_try_run_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_try_run_latency CHECK (latency_ms IS NULL OR latency_ms >= 0),
  CONSTRAINT ck_try_run_prod CHECK (environment <> 'PRODUCTION' OR (method IN ('GET', 'HEAD') AND request_snapshot IS NULL AND sandbox_mode IS NULL)),
  CONSTRAINT ck_try_run_sandbox CHECK (environment <> 'SANDBOX' OR sandbox_mode IS NOT NULL OR result = 'DENIED'),
  CONSTRAINT ck_try_run_snapshot CHECK (request_snapshot IS NULL OR (jsonb_typeof(request_snapshot) = 'object' AND octet_length(request_snapshot::text) <= 16384))
) PARTITION BY RANGE (executed_at);
CREATE INDEX ix_try_run_account ON ph15_portal.try_run (tenant_id, account_id, executed_at DESC);
CREATE INDEX ix_try_run_app ON ph15_portal.try_run (tenant_id, app_id, executed_at DESC);
CREATE INDEX ix_try_run_entry ON ph15_portal.try_run (tenant_id, api_id, executed_at DESC);
CREATE INDEX ix_try_run_trace ON ph15_portal.try_run (trace_id);
CALL ph15_portal.p_enable_rls('ph15_portal.try_run');
CALL ph15_portal.p_ensure_month_partitions('ph15_portal.try_run', DATE '2026-11-01', 6);
COMMENT ON TABLE ph15_portal.try_run IS 'EN-15-11 Lượt thử API (FR-15-035, 040, 043): siêu dữ liệu và, với SANDBOX, bản yêu cầu đã quét PII-15 để gửi lại. Không thân phản hồi, không tiêu đề xác thực (BR-15-024). Phân vùng tháng (ADR-047).';
COMMENT ON COLUMN ph15_portal.try_run.id IS 'tryId, cũng là giá trị tiêu đề X-DH-Try-Id (BR-15-026); UUID v7.';
COMMENT ON COLUMN ph15_portal.try_run.request_snapshot IS 'Chỉ lượt SANDBOX: phương thức, tham số, thân tổng hợp ≤ 16 KB đã qua bộ luật PII-15; PRODUCTION luôn NULL (không lưu thân).';
COMMENT ON COLUMN ph15_portal.try_run.path_template IS 'Đường dẫn dạng mẫu /ho-tich/{id}, không chứa giá trị thật của tham số đường dẫn.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.try_run CASCADE;

-- @changeset ph15-0510-request-collection
CREATE TABLE ph15_portal.try_collection (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  name                varchar(128)  NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_try_collection PRIMARY KEY (id),
  CONSTRAINT uq_try_collection_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_try_collection_name UNIQUE (account_id, name),
  CONSTRAINT fk_try_collection_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id)
);
CREATE TRIGGER tg_try_collection_touch BEFORE UPDATE ON ph15_portal.try_collection FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.try_collection');
COMMENT ON TABLE ph15_portal.try_collection IS 'EN-15-12 Bộ sưu tập yêu cầu của người dùng, tối đa 50 bộ (trigger tg_collection_limit; ERR-15-003). Chia sẻ cho nhóm là Đợt 3 (Q15-12).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.try_collection CASCADE;

-- @changeset ph15-0511-collection-item
CREATE TABLE ph15_portal.try_collection_item (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  collection_id       uuid          NOT NULL,
  api_id            uuid,
  position            integer       NOT NULL DEFAULT 0,
  name                varchar(128)  NOT NULL,
  request_spec        jsonb         NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_try_collection_item PRIMARY KEY (id),
  CONSTRAINT fk_try_collection_item_collection FOREIGN KEY (collection_id, tenant_id) REFERENCES ph15_portal.try_collection (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_try_collection_item_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_try_collection_item_spec CHECK (jsonb_typeof(request_spec) = 'object' AND octet_length(request_spec::text) <= 16384)
);
CREATE INDEX ix_try_collection_item_collection ON ph15_portal.try_collection_item (tenant_id, collection_id, position);
CREATE TRIGGER tg_try_collection_item_touch BEFORE UPDATE ON ph15_portal.try_collection_item FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.try_collection_item');
COMMENT ON TABLE ph15_portal.try_collection_item IS 'Yêu cầu mẫu trong bộ sưu tập, tối đa 100 mỗi bộ và 16 KB mỗi yêu cầu (FR-15-040, Phụ lục A.6); chỉ nội dung tổng hợp đã quét PII-15.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.try_collection_item CASCADE;

-- @changeset ph15-0512-collection-limits splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_collection_limit() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE n integer;
BEGIN
  IF TG_TABLE_NAME = 'try_collection' THEN
    SELECT count(*) INTO n FROM ph15_portal.try_collection WHERE account_id = NEW.account_id;
    IF n >= 50 THEN RAISE EXCEPTION 'Đã đạt số bộ sưu tập tối đa (50)' USING ERRCODE = 'P1503'; END IF;
  ELSE
    SELECT count(*) INTO n FROM ph15_portal.try_collection_item WHERE collection_id = NEW.collection_id;
    IF n >= 100 THEN RAISE EXCEPTION 'Đã đạt số yêu cầu tối đa trong bộ sưu tập (100)' USING ERRCODE = 'P1503'; END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_collection_limit() IS 'Chốt chặn giới hạn 50 bộ sưu tập mỗi người và 100 yêu cầu mỗi bộ (ứng dụng kiểm trước, ERR-15-003).';
CREATE TRIGGER tg_try_collection_limit BEFORE INSERT ON ph15_portal.try_collection FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_collection_limit();
CREATE TRIGGER tg_try_collection_item_limit BEFORE INSERT ON ph15_portal.try_collection_item FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_collection_limit();
-- @rollback DROP TRIGGER IF EXISTS tg_try_collection_limit ON ph15_portal.try_collection; DROP TRIGGER IF EXISTS tg_try_collection_item_limit ON ph15_portal.try_collection_item; DROP FUNCTION IF EXISTS ph15_portal.tg_collection_limit();

-- @file 15-0060-notify-support.sql
-- @changeset ph15-0600-watch-subscription
CREATE TABLE ph15_portal.notification_subscription (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  api_id            uuid          NOT NULL,
  channel             varchar(6)    NOT NULL,
  kind                varchar(9)    NOT NULL DEFAULT 'INFO',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_subscription PRIMARY KEY (id),
  CONSTRAINT uq_notification_subscription UNIQUE (account_id, api_id, channel, kind),
  CONSTRAINT fk_notification_subscription_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_notification_subscription_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_notification_subscription_channel CHECK (channel IN ('IN_APP', 'EMAIL')),
  CONSTRAINT ck_notification_subscription_kind CHECK (kind IN ('MANDATORY', 'INFO'))
);
CREATE INDEX ix_notification_subscription_entry ON ph15_portal.notification_subscription (tenant_id, api_id, kind);
CREATE TRIGGER tg_notification_subscription_touch BEFORE UPDATE ON ph15_portal.notification_subscription FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.notification_subscription');
COMMENT ON TABLE ph15_portal.notification_subscription IS 'EN-15-14 Theo dõi thay đổi API (FR-15-051): INFO do người dùng bật tắt; MANDATORY (ngừng khuyến nghị, tạm ngừng, ngừng hẳn, SLA kém đi, thay đổi phá vỡ) hệ thống tạo và không xóa được (BR-15-027).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.notification_subscription CASCADE;

-- @changeset ph15-0601-mandatory-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_mandatory_watch_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.kind = 'MANDATORY' THEN
    RAISE EXCEPTION 'Đăng ký nhận thông báo bắt buộc không tắt được (BR-15-027)' USING ERRCODE = 'P1504';
  END IF;
  RETURN OLD;
END
$f$;
CREATE TRIGGER tg_notification_subscription_mandatory BEFORE DELETE ON ph15_portal.notification_subscription FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_mandatory_watch_guard();
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_mandatory_watch_guard() CASCADE;

-- @changeset ph15-0610-inbox-notification
CREATE TABLE ph15_portal.inbox_message (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  channel             varchar(6)    NOT NULL DEFAULT 'IN_APP',
  kind                varchar(9)    NOT NULL DEFAULT 'INFO',
  api_id            uuid,
  title               varchar(255)  NOT NULL,
  body                varchar(2000),
  link_path           varchar(512),
  source_event_id     uuid,
  delivered_at        timestamptz,
  read_at             timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  CONSTRAINT pk_inbox_message PRIMARY KEY (id),
  CONSTRAINT fk_inbox_message_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_inbox_message_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_inbox_message_channel CHECK (channel IN ('IN_APP', 'EMAIL')),
  CONSTRAINT ck_inbox_message_kind CHECK (kind IN ('MANDATORY', 'INFO'))
);
CREATE UNIQUE INDEX uq_inbox_message_event ON ph15_portal.inbox_message (account_id, source_event_id, channel) WHERE source_event_id IS NOT NULL;
CREATE INDEX ix_inbox_message_unread ON ph15_portal.inbox_message (tenant_id, account_id, created_at DESC) WHERE read_at IS NULL;
CALL ph15_portal.p_enable_rls('ph15_portal.inbox_message');
COMMENT ON TABLE ph15_portal.inbox_message IS 'Hộp thông báo (FR-15-052): một dòng cho mỗi người nhận và kênh; chống gửi trùng nhờ khóa duy nhất theo sự kiện nguồn (EVT-02-12).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.inbox_message CASCADE;

-- @changeset ph15-0620-support-ticket
CREATE TABLE ph15_portal.support_ticket (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  ticket_code         varchar(16)   NOT NULL,
  kind                varchar(16)   NOT NULL,
  status              varchar(8)    NOT NULL DEFAULT 'OPEN',
  api_id            uuid,
  page_id             uuid,
  requester_id        uuid          NOT NULL,
  assignee_org_code   varchar(64),
  assignee_user_id    varchar(64),
  subject             varchar(255)  NOT NULL,
  body                varchar(4000) NOT NULL,
  rating              smallint,
  first_response_due_at timestamptz,
  first_responded_at  timestamptz,
  resolved_at         timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_support_ticket PRIMARY KEY (id),
  CONSTRAINT uq_support_ticket_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_support_ticket_code UNIQUE (tenant_id, ticket_code),
  CONSTRAINT fk_support_ticket_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT fk_support_ticket_page FOREIGN KEY (page_id, tenant_id) REFERENCES ph15_portal.content_page (id, tenant_id),
  CONSTRAINT fk_support_ticket_requester FOREIGN KEY (requester_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT ck_support_ticket_code CHECK (ticket_code ~ '^HT-[0-9]{4}-[0-9]{4,}$'),
  CONSTRAINT ck_support_ticket_kind CHECK (kind IN ('QUESTION', 'DOC_ERROR', 'SUPPORT_REQUEST', 'ACCESS_REQUEST', 'FEEDBACK')),
  CONSTRAINT ck_support_ticket_status CHECK (status IN ('OPEN', 'ANSWERED', 'RESOLVED', 'CLOSED')),
  CONSTRAINT ck_support_ticket_rating CHECK (rating IS NULL OR (kind = 'FEEDBACK' AND rating BETWEEN 1 AND 5)),
  CONSTRAINT ck_support_ticket_resolved CHECK (status NOT IN ('RESOLVED', 'CLOSED') OR resolved_at IS NOT NULL)
);
CREATE INDEX ix_support_ticket_inbox ON ph15_portal.support_ticket (tenant_id, assignee_org_code, status, created_at);
CREATE INDEX ix_support_ticket_requester ON ph15_portal.support_ticket (tenant_id, requester_id, created_at DESC);
CREATE INDEX ix_support_ticket_sla ON ph15_portal.support_ticket (tenant_id, first_response_due_at) WHERE first_responded_at IS NULL AND status = 'OPEN';
CREATE TRIGGER tg_support_ticket_touch BEFORE UPDATE ON ph15_portal.support_ticket FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_support_ticket_immutable BEFORE UPDATE ON ph15_portal.support_ticket FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('ticket_code', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.support_ticket');
COMMENT ON TABLE ph15_portal.support_ticket IS 'EN-15-15 Phiếu hỗ trợ: hỏi đáp theo API, báo lỗi tài liệu, yêu cầu hỗ trợ, yêu cầu truy cập, đánh giá (FR-15-053…055). Văn bản thuần ≤ 4.000 ký tự (BR-15-030).';
COMMENT ON COLUMN ph15_portal.support_ticket.assignee_org_code IS 'Đầu mối của chủ dịch vụ (owner_org_code của API); phiếu không gắn API chuyển quản trị cổng.';
COMMENT ON COLUMN ph15_portal.support_ticket.first_response_due_at IS 'Hạn phản hồi đầu = tạo + 15.support.sla-hours; quá hạn thì nhắc và báo quản trị.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.support_ticket CASCADE;

-- @changeset ph15-0621-support-message
CREATE TABLE ph15_portal.support_message (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  ticket_id           uuid          NOT NULL,
  author_id           varchar(64)   NOT NULL,
  author_side         varchar(9)    NOT NULL,
  body                varchar(4000) NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  CONSTRAINT pk_support_message PRIMARY KEY (id),
  CONSTRAINT fk_support_message_ticket FOREIGN KEY (ticket_id, tenant_id) REFERENCES ph15_portal.support_ticket (id, tenant_id),
  CONSTRAINT ck_support_message_side CHECK (author_side IN ('REQUESTER', 'HANDLER'))
);
CREATE INDEX ix_support_message_ticket ON ph15_portal.support_message (tenant_id, ticket_id, created_at);
CREATE TRIGGER tg_support_message_ro BEFORE UPDATE OR DELETE ON ph15_portal.support_message FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_append_only();
CALL ph15_portal.p_enable_rls('ph15_portal.support_message');
COMMENT ON TABLE ph15_portal.support_message IS 'Chuỗi tin trong phiếu hỗ trợ; chỉ thêm, giữ nguyên lịch sử xử lý (FR-15-054, 055).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.support_message CASCADE;

-- @changeset ph15-0622-ticket-counter splitStatements:false
CREATE TABLE ph15_portal.ticket_counter (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  year                smallint      NOT NULL,
  last_no             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_ticket_counter PRIMARY KEY (tenant_id, year),
  CONSTRAINT ck_ticket_counter_no CHECK (last_no >= 0)
);
CALL ph15_portal.p_enable_rls('ph15_portal.ticket_counter');
COMMENT ON TABLE ph15_portal.ticket_counter IS 'Bộ đếm số phiếu theo tenant và năm cho ticketCode HT-{năm}-{số}; tăng trong cùng giao dịch tạo phiếu.';
CREATE OR REPLACE FUNCTION ph15_portal.next_ticket_code() RETURNS varchar
  LANGUAGE plpgsql AS $f$
DECLARE
  y smallint := extract(year FROM now())::smallint;
  n integer;
BEGIN
  INSERT INTO ph15_portal.ticket_counter (tenant_id, year, last_no)
  VALUES (current_setting('app.tenant_id', false), y, 1)
  ON CONFLICT (tenant_id, year) DO UPDATE SET last_no = ph15_portal.ticket_counter.last_no + 1
  RETURNING last_no INTO n;
  RETURN format('HT-%s-%s', y, lpad(n::text, 4, '0'));
END
$f$;
COMMENT ON FUNCTION ph15_portal.next_ticket_code() IS 'Cấp mã phiếu kế tiếp cho tenant của phiên (RLS áp dụng); đồng thời an toàn nhờ khóa dòng của ON CONFLICT.';
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.next_ticket_code(); DROP TABLE IF EXISTS ph15_portal.ticket_counter;

-- @file 15-0070-admin-sync.sql
-- @changeset ph15-0700-portal-setting
CREATE TABLE ph15_portal.portal_setting (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  portal_name         varchar(255)  NOT NULL,
  greeting            varchar(500),
  logo_file_id        uuid,
  links               jsonb         NOT NULL DEFAULT '[]',
  footer_md           varchar(2000),
  param_cache         jsonb         NOT NULL DEFAULT '{}',
  param_synced_at     timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_portal_setting PRIMARY KEY (id),
  CONSTRAINT uq_portal_setting_tenant UNIQUE (tenant_id),
  CONSTRAINT fk_portal_setting_logo FOREIGN KEY (logo_file_id, tenant_id) REFERENCES ph15_portal.content_attachment (id, tenant_id),
  CONSTRAINT ck_portal_setting_links CHECK (jsonb_typeof(links) = 'array' AND jsonb_array_length(links) <= 12),
  CONSTRAINT ck_portal_setting_params CHECK (jsonb_typeof(param_cache) = 'object')
);
CREATE TRIGGER tg_portal_setting_touch BEFORE UPDATE ON ph15_portal.portal_setting FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.portal_setting');
COMMENT ON TABLE ph15_portal.portal_setting IS 'EN-15-17 Nhận diện cổng theo tenant, một dòng mỗi tenant: tên, lời chào, logo, liên kết, chân trang (FR-15-056, BR-15-032: không đổi màu, phông, token).';
COMMENT ON COLUMN ph15_portal.portal_setting.param_cache IS 'Bản sao các tham số 15.* đọc từ PH-18 (nguồn chuẩn ở PH-18); cổng chỉ ghi đệm để chạy khi PH-18 chậm (FR-15-057).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.portal_setting CASCADE;

-- @changeset ph15-0710-sync-state
CREATE TABLE ph15_portal.sync_state (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  state               varchar(8)    NOT NULL DEFAULT 'IDLE',
  updated_since       timestamptz,
  last_success_at     timestamptz,
  last_event_at       timestamptz,
  lag_seconds         integer       NOT NULL DEFAULT 0,
  last_error          varchar(1000),
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_sync_state PRIMARY KEY (tenant_id),
  CONSTRAINT ck_sync_state_state CHECK (state IN ('IDLE', 'RUNNING', 'FAILED', 'STALE')),
  CONSTRAINT ck_sync_state_lag CHECK (lag_seconds >= 0)
);
CALL ph15_portal.p_enable_rls('ph15_portal.sync_state');
COMMENT ON TABLE ph15_portal.sync_state IS 'Trạng thái đồng bộ danh mục của tenant (IDLE, RUNNING, FAILED, STALE) và con trỏ updatedSince; phát EVT-15-14 khi đổi (FR-15-001, BR-15-033).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.sync_state CASCADE;

-- @changeset ph15-0720-sync-run
CREATE TABLE ph15_portal.sync_run (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  kind                varchar(12)   NOT NULL,
  status              varchar(10)   NOT NULL DEFAULT 'RUNNING',
  started_at          timestamptz   NOT NULL DEFAULT now(),
  finished_at         timestamptz,
  items_upserted      integer       NOT NULL DEFAULT 0,
  items_removed       integer       NOT NULL DEFAULT 0,
  items_failed        integer       NOT NULL DEFAULT 0,
  mismatch_count      integer       NOT NULL DEFAULT 0,
  content_git_source_id       uuid,
  error_code          varchar(10),
  error_detail        varchar(1000),
  report              jsonb         NOT NULL DEFAULT '{}',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sync_run PRIMARY KEY (id),
  CONSTRAINT fk_sync_run_git FOREIGN KEY (content_git_source_id, tenant_id) REFERENCES ph15_portal.content_git_source (id, tenant_id),
  CONSTRAINT ck_sync_run_report CHECK (jsonb_typeof(report) = 'object'),
  CONSTRAINT ck_sync_run_kind CHECK (kind IN ('INCREMENTAL', 'FULL', 'RECONCILE', 'GIT')),
  CONSTRAINT ck_sync_run_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
  CONSTRAINT ck_sync_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-15-[0-9]{3}$'),
  CONSTRAINT ck_sync_run_done CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT ck_sync_run_git CHECK (kind <> 'GIT' OR content_git_source_id IS NOT NULL)
);
CREATE UNIQUE INDEX uq_sync_run_running ON ph15_portal.sync_run (tenant_id, kind) WHERE status = 'RUNNING';
CREATE INDEX ix_sync_run_recent ON ph15_portal.sync_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_sync_run_touch BEFORE UPDATE ON ph15_portal.sync_run FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.sync_run');
COMMENT ON COLUMN ph15_portal.sync_run.report IS 'Chi tiết lệch khi kind = RECONCILE (apiCode, loại lệch, sourceVersion hai phía), thay cho bảng reconciliation_report của SDD.';
COMMENT ON TABLE ph15_portal.sync_run IS 'EN-15-18 Lần đồng bộ: gia tăng, đầy đủ, đối soát với PH-02, nhập Git (FR-15-001, 018, 061). Mỗi loại chỉ một lần RUNNING mỗi tenant.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.sync_run CASCADE;

-- @changeset ph15-0730-migration-batch
CREATE TABLE ph15_portal.content_migration (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  package_file_id     uuid          NOT NULL,
  status              varchar(8)    NOT NULL DEFAULT 'RUNNING',
  pages_total         integer       NOT NULL DEFAULT 0,
  pages_imported      integer       NOT NULL DEFAULT 0,
  pages_skipped       integer       NOT NULL DEFAULT 0,
  report              jsonb         NOT NULL DEFAULT '{}',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_content_migration PRIMARY KEY (id),
  CONSTRAINT uq_content_migration_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_content_migration_file FOREIGN KEY (package_file_id, tenant_id) REFERENCES ph15_portal.content_attachment (id, tenant_id),
  CONSTRAINT ck_content_migration_status CHECK (status IN ('RUNNING', 'PREVIEW', 'APPLIED', 'FAILED')),
  CONSTRAINT ck_content_migration_counts CHECK (pages_imported + pages_skipped <= pages_total),
  CONSTRAINT ck_content_migration_report CHECK (jsonb_typeof(report) = 'object')
);
CREATE UNIQUE INDEX uq_content_migration_running ON ph15_portal.content_migration (tenant_id) WHERE status = 'RUNNING';
CREATE TRIGGER tg_content_migration_touch BEFORE UPDATE ON ph15_portal.content_migration FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.content_migration');
COMMENT ON TABLE ph15_portal.content_migration IS 'Lô di trú nội dung portal Gravitee cũ (FR-15-062): id là migrationId; chỉ một lô RUNNING mỗi tenant (ERR-15-035).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.content_migration CASCADE;

-- @changeset ph15-0740-legacy-mapping
CREATE TABLE ph15_portal.legacy_mapping (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  legacy_system       varchar(24)   NOT NULL DEFAULT 'GRAVITEE_PORTAL',
  legacy_key          varchar(255)  NOT NULL,
  target_type         varchar(12)   NOT NULL,
  target_id           uuid          NOT NULL,
  source_hash         char(64)      NOT NULL,
  migration_id        uuid          NOT NULL,
  mapped_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_legacy_mapping PRIMARY KEY (tenant_id, legacy_system, legacy_key),
  CONSTRAINT fk_legacy_mapping_batch FOREIGN KEY (migration_id, tenant_id) REFERENCES ph15_portal.content_migration (id, tenant_id),
  CONSTRAINT ck_legacy_mapping_system CHECK (legacy_system IN ('GRAVITEE_PORTAL', 'BACKSTAGE')),
  CONSTRAINT ck_legacy_mapping_type CHECK (target_type IN ('PAGE', 'PAGE_VERSION', 'FILE')),
  CONSTRAINT ck_legacy_mapping_hash CHECK (source_hash ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_legacy_mapping_target ON ph15_portal.legacy_mapping (tenant_id, target_type, target_id);
CREATE INDEX ix_legacy_mapping_batch ON ph15_portal.legacy_mapping (tenant_id, migration_id);
CALL ph15_portal.p_enable_rls('ph15_portal.legacy_mapping');
COMMENT ON TABLE ph15_portal.legacy_mapping IS 'Ánh xạ khóa trang, tài liệu của portal hệ cũ sang đối tượng mới; chạy lại cùng migrationId không tạo trùng, băm khác thì cập nhật (FR-15-062, ADR-049).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.legacy_mapping CASCADE;

-- @changeset ph15-0741-legacy-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_legacy_mapping_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.target_id IS DISTINCT FROM OLD.target_id OR NEW.target_type IS DISTINCT FROM OLD.target_type THEN
    RAISE EXCEPTION 'target_id của legacy_mapping không đổi được' USING ERRCODE = 'P1505';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_legacy_mapping_guard BEFORE UPDATE ON ph15_portal.legacy_mapping FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_legacy_mapping_guard();
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.tg_legacy_mapping_guard() CASCADE;

-- @file 15-0080-messaging.sql
-- @changeset ph15-0800-inbound-event
CREATE TABLE ph15_portal.inbox_event (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  event_id            uuid          NOT NULL,
  event_code          varchar(10)   NOT NULL,
  topic               varchar(160)  NOT NULL,
  received_at         timestamptz   NOT NULL DEFAULT now(),
  processed_at        timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, event_id),
  CONSTRAINT ck_inbox_event_code CHECK (event_code ~ '^EVT-02-[0-9]{2}$')
);
CREATE INDEX ix_inbox_event_received ON ph15_portal.inbox_event (received_at);
CALL ph15_portal.p_enable_rls('ph15_portal.inbox_event');
COMMENT ON TABLE ph15_portal.inbox_event IS 'Hộp thư đến: ghi nhận sự kiện EVT-02-* của PH-02 đã xử lý để loại trùng (xử lý at-least-once, ADR-041). Giữ 7 ngày.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.inbox_event CASCADE;

-- @changeset ph15-0810-outbox-event
CREATE TABLE ph15_portal.outbox_event (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  event_code          varchar(10)   NOT NULL,
  topic               varchar(160)  NOT NULL,
  message_key         varchar(128)  NOT NULL,
  aggregate_id        uuid,
  payload             jsonb         NOT NULL,
  trace_id            char(32),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  published_at        timestamptz,
  CONSTRAINT pk_outbox_event PRIMARY KEY (id),
  CONSTRAINT ck_outbox_event_code CHECK (event_code ~ '^EVT-15-(0[1-9]|1[0-4])$'),
  CONSTRAINT ck_outbox_event_topic CHECK (topic ~ '^t[0-9]{2}\.portal\.[a-z-]+\.[a-z-]+\.v1$'),
  CONSTRAINT ck_outbox_event_payload CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_outbox_event_pending ON ph15_portal.outbox_event (created_at) WHERE published_at IS NULL;
CREATE INDEX ix_outbox_event_published ON ph15_portal.outbox_event (published_at) WHERE published_at IS NOT NULL;
CALL ph15_portal.p_enable_rls('ph15_portal.outbox_event');
COMMENT ON TABLE ph15_portal.outbox_event IS 'Hộp thư đi (outbox) cho EVT-15-01…14; Debezium EventRouter đọc WAL phát lên Kafka. Payload không chứa bí mật, thân yêu cầu hay dữ liệu cá nhân. Kiểm toán PH-13 cũng đi qua đây (BR-15-023).';
-- @rollback DROP TABLE IF EXISTS ph15_portal.outbox_event CASCADE;

-- @changeset ph15-0820-idempotency-record
CREATE TABLE ph15_portal.idempotency_record (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  key_hash            char(64)      NOT NULL,
  actor_id            varchar(64)   NOT NULL,
  request_hash        char(64)      NOT NULL,
  response_status     smallint      NOT NULL,
  resource_type       varchar(32),
  resource_id         uuid,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  expires_at          timestamptz   NOT NULL,
  CONSTRAINT pk_idempotency_record PRIMARY KEY (tenant_id, actor_id, key_hash),
  CONSTRAINT ck_idempotency_record_hash CHECK (key_hash ~ '^[0-9a-f]{64}$' AND request_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_idempotency_record_ttl CHECK (expires_at > created_at AND expires_at <= created_at + interval '24 hours' + interval '1 minute')
);
CREATE INDEX ix_idempotency_record_expiry ON ph15_portal.idempotency_record (expires_at);
CALL ph15_portal.p_enable_rls('ph15_portal.idempotency_record');
COMMENT ON TABLE ph15_portal.idempotency_record IS 'Lũy đẳng tầng bền cho thao tác ghi (ADR-041, BR-15-034). Cố ý không lưu thân phản hồi để bí mật sandbox vừa cấp không nằm lại ở CSDL (BR-15-011); lặp lại thì trả trạng thái và tham chiếu tài nguyên.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.idempotency_record CASCADE;

-- @changeset ph15-0830-shedlock
CREATE TABLE ph15_portal.shedlock (
  name                varchar(64)   NOT NULL,
  lock_until          timestamptz   NOT NULL,
  locked_at           timestamptz   NOT NULL,
  locked_by           varchar(255)  NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph15_portal.shedlock IS 'Bảng kỹ thuật của ShedLock cho tác vụ định kỳ (kéo bù danh mục, đồng bộ Git, hết hạn thông tin xác thực, dọn dữ liệu); không RLS, không dữ liệu nghiệp vụ; tên khóa chứa mã tenant.';
-- @rollback DROP TABLE IF EXISTS ph15_portal.shedlock;

-- @file 15-0090-seed.sql
-- @changeset ph15-0900-seed-fn splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.seed_tenant(p_tenant varchar, p_actor varchar) RETURNS void
  LANGUAGE plpgsql AS $f$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph15_portal.portal_setting (id, tenant_id, portal_name, greeting, created_by, updated_by)
  VALUES (gen_random_uuid(), p_tenant, 'Cổng nhà phát triển ' || p_tenant, 'Chào mừng đến Cổng nhà phát triển', p_actor, p_actor)
  ON CONFLICT (tenant_id) DO NOTHING;
  INSERT INTO ph15_portal.sync_state (tenant_id) VALUES (p_tenant) ON CONFLICT (tenant_id) DO NOTHING;
END
$f$;
COMMENT ON FUNCTION ph15_portal.seed_tenant(varchar, varchar) IS 'Khởi tạo dữ liệu nền cho tenant mới (sự kiện tenant.provisioned của PH-20): nhận diện cổng mặc định và trạng thái đồng bộ IDLE; lũy đẳng. Chạy dưới ph15_app của tenant đích.';
-- @rollback DROP FUNCTION IF EXISTS ph15_portal.seed_tenant(varchar, varchar);

-- @file 15-0100-grants.sql
-- @changeset ph15-1000-grants splitStatements:false runOnChange:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph15_portal TO ph15_app;
-- Chỉ-ghi-thêm: bằng chứng chấp nhận điều khoản, tin nhắn hỗ trợ.
REVOKE UPDATE, DELETE ON ph15_portal.dev_terms_acceptance, ph15_portal.support_message FROM ph15_app;
-- Không xóa vật lý: mã định danh không dùng lại, lịch sử nội dung, bản sao danh mục (xóa mềm).
REVOKE DELETE ON ph15_portal.catalog_api, ph15_portal.content_page, ph15_portal.content_page_version, ph15_portal.dev_account,
  ph15_portal.dev_team, ph15_portal.app, ph15_portal.app_credential, ph15_portal.support_ticket, ph15_portal.dev_terms,
  ph15_portal.portal_setting, ph15_portal.legacy_mapping, ph15_portal.content_migration, ph15_portal.try_prod_grant FROM ph15_app;
GRANT EXECUTE ON FUNCTION ph15_portal.next_ticket_code(), ph15_portal.seed_tenant(varchar, varchar), ph15_portal.f_unaccent(text) TO ph15_app, ph15_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA ph15_portal TO ph15_readonly;
-- Đọc kiểm toán, báo cáo: không thấy cột bí mật, mã hóa, băm xác minh; không thấy bảng kỹ thuật.
REVOKE SELECT ON ph15_portal.idempotency_record, ph15_portal.shedlock, ph15_portal.app_credential, ph15_portal.dev_account FROM ph15_readonly;
DO $g$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM (VALUES ('app_credential', 'key_hash'), ('dev_account', 'phone_enc,dek_wrapped,verification_token_hash')) v(t, excl) LOOP
    EXECUTE format('GRANT SELECT (%s) ON ph15_portal.%I TO ph15_readonly',
      (SELECT string_agg(quote_ident(column_name), ',') FROM information_schema.columns
        WHERE table_schema = 'ph15_portal' AND table_name = r.t AND column_name <> ALL (string_to_array(r.excl, ','))), r.t);
  END LOOP;
END
$g$;
-- @rollback REVOKE ALL ON ALL TABLES IN SCHEMA ph15_portal FROM ph15_app, ph15_readonly;
