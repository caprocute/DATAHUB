--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0020-content.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0200-content-page
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
--rollback DROP TABLE IF EXISTS ph15_portal.content_page CASCADE;

--changeset ph15:ph15-0201-content-page-tsv splitStatements:false
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
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_content_page_tsv() CASCADE;

--changeset ph15:ph15-0210-content-page-version
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
--rollback ALTER TABLE ph15_portal.content_page DROP CONSTRAINT IF EXISTS fk_content_page_published; DROP TABLE IF EXISTS ph15_portal.content_page_version CASCADE;

--changeset ph15:ph15-0211-version-guard splitStatements:false
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
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_version_body_guard() CASCADE;

--changeset ph15:ph15-0220-portal-file
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
--rollback DROP TABLE IF EXISTS ph15_portal.content_attachment CASCADE;

--changeset ph15:ph15-0230-git-source
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
--rollback DROP TABLE IF EXISTS ph15_portal.content_git_source CASCADE;
