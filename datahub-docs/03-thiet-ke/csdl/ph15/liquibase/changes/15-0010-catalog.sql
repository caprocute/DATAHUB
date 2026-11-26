--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0010-catalog.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0100-catalog-entry
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
--rollback DROP TABLE IF EXISTS ph15_portal.catalog_api CASCADE;

--changeset ph15:ph15-0101-catalog-tsv splitStatements:false
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
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_catalog_api_tsv() CASCADE;

--changeset ph15:ph15-0110-catalog-api-version
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
--rollback DROP TABLE IF EXISTS ph15_portal.catalog_api_version CASCADE;

--changeset ph15:ph15-0111-catalog-spec
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
--rollback DROP TABLE IF EXISTS ph15_portal.catalog_spec CASCADE;

--changeset ph15:ph15-0120-sandbox-profile
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
--rollback DROP TABLE IF EXISTS ph15_portal.sandbox_profile CASCADE;

--changeset ph15:ph15-0130-prod-try-grant
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
--rollback DROP TABLE IF EXISTS ph15_portal.try_prod_grant CASCADE;
