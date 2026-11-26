-- =============================================================================
-- D03-03-PH02 · Tệp 10: danh mục — phân loại, sổ mã, API, phiên bản, đặc tả,
-- thao tác, tìm kiếm, đường dẫn công bố, chuyển chủ quản, bộ đệm so sánh
-- Chạy sau ph02_00_bootstrap.sql (cùng phiên, đang SET ROLE ph02_owner).
-- =============================================================================

-- @file 02-0010-catalog.sql
-- @changeset ph02-0100-category
CREATE TABLE ph02_catalog.category (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  category_code    varchar(32)   NOT NULL,
  name             varchar(255)  NOT NULL,
  parent_id        uuid,
  path             varchar(255)  NOT NULL,
  sort_order       integer       NOT NULL DEFAULT 0,
  status           varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  merged_into_id   uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_category PRIMARY KEY (id),
  CONSTRAINT uq_category_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_category_code UNIQUE (tenant_id, category_code),
  CONSTRAINT fk_category_parent FOREIGN KEY (parent_id, tenant_id) REFERENCES ph02_catalog.category (id, tenant_id),
  CONSTRAINT fk_category_merged FOREIGN KEY (merged_into_id, tenant_id) REFERENCES ph02_catalog.category (id, tenant_id),
  CONSTRAINT ck_category_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_category_code CHECK (category_code ~ '^[a-z][a-z0-9-]{1,31}$'),
  CONSTRAINT ck_category_status CHECK (status IN ('ACTIVE', 'MERGED')),
  CONSTRAINT ck_category_merged CHECK ((status = 'MERGED') = (merged_into_id IS NOT NULL)),
  CONSTRAINT ck_category_self CHECK (parent_id IS DISTINCT FROM id AND merged_into_id IS DISTINCT FROM id)
);
CREATE INDEX ix_category_parent ON ph02_catalog.category (tenant_id, parent_id);
CREATE INDEX ix_category_path ON ph02_catalog.category (tenant_id, path text_pattern_ops);
CREATE TRIGGER tg_category_touch BEFORE UPDATE ON ph02_catalog.category FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.category', 'P');
COMMENT ON TABLE ph02_catalog.category IS 'EN-02-12 Cây phân loại API (FR-02-007, 008). Mã nhóm bất biến, không dùng lại (BR-02-021); gộp nhóm đặt MERGED kèm nhóm đích, API được dời trong một giao dịch.';
COMMENT ON COLUMN ph02_catalog.category.path IS 'Đường dẫn vật hóa từ gốc, ví dụ dat-dai/ban-do; dùng cho truy vấn cây bằng tiền tố.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.category CASCADE;

-- @changeset ph02-0110-code-registry
CREATE TABLE ph02_catalog.code_registry (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  kind             varchar(12)   NOT NULL,
  code             varchar(160)  NOT NULL,
  subject_id       uuid,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_code_registry PRIMARY KEY (id),
  CONSTRAINT uq_code_registry UNIQUE (tenant_id, kind, code),
  CONSTRAINT ck_code_registry_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_code_registry_kind CHECK (kind IN ('API', 'VERSION', 'PLAN', 'CATEGORY'))
);
CREATE TRIGGER tg_code_registry_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.code_registry FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.code_registry', 'P');
COMMENT ON TABLE ph02_catalog.code_registry IS 'Sổ mã đã dùng: mã API, số hiệu phiên bản, mã gói, mã nhóm không bao giờ dùng lại kể cả đối tượng đã xóa hay ngừng (BR-02-021). Chỉ thêm, giữ chỗ bằng khóa duy nhất (ERR-02-002).';
COMMENT ON COLUMN ph02_catalog.code_registry.code IS 'API: apiCode; CATEGORY: categoryCode; VERSION: {apiCode}@{versionNo}; PLAN: {apiCode}@{versionNo}:{planCode}.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.code_registry CASCADE;

-- @changeset ph02-0120-api
CREATE TABLE ph02_catalog.api (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_code         varchar(63)   NOT NULL,
  name             varchar(255)  NOT NULL,
  description      varchar(4000),
  system_code      varchar(64)   NOT NULL,
  owner_org_code   varchar(64)   NOT NULL,
  data_class       varchar(10)   NOT NULL,
  data_class_rank  smallint      GENERATED ALWAYS AS (CASE data_class WHEN 'PUBLIC' THEN 0 WHEN 'INTERNAL' THEN 1 WHEN 'RESTRICTED' THEN 2 ELSE 3 END) STORED,
  visibility       varchar(8)    NOT NULL DEFAULT 'TENANT',
  category_id      uuid,
  base_path        varchar(120)  NOT NULL,
  origin           varchar(8)    NOT NULL DEFAULT 'MANUAL',
  flow_ref         jsonb,
  legacy_id        varchar(128),
  deleted_at       timestamptz,
  delete_reason    varchar(1000),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_api PRIMARY KEY (id),
  CONSTRAINT uq_api_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_api_code UNIQUE (tenant_id, api_code),
  CONSTRAINT fk_api_category FOREIGN KEY (category_id, tenant_id) REFERENCES ph02_catalog.category (id, tenant_id),
  CONSTRAINT ck_api_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_api_code CHECK (api_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_api_data_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_api_visibility CHECK (visibility IN ('TENANT', 'NATIONAL', 'PUBLIC')),
  CONSTRAINT ck_api_visibility_class CHECK (
    (visibility <> 'PUBLIC' OR data_class = 'PUBLIC')
    AND (visibility <> 'NATIONAL' OR data_class <> 'SENSITIVE')),
  CONSTRAINT ck_api_base_path CHECK (base_path ~ '^/[a-z][a-z0-9-]{1,31}/[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_api_origin CHECK (origin IN ('MANUAL', 'OPENAPI', 'FLOW', 'LEGACY')),
  CONSTRAINT ck_api_flow_ref CHECK ((origin = 'FLOW') = (flow_ref IS NOT NULL)),
  CONSTRAINT ck_api_flow_ref_shape CHECK (flow_ref IS NULL OR (jsonb_typeof(flow_ref) = 'object' AND flow_ref ?& ARRAY['workspaceCode', 'flowCode'])),
  CONSTRAINT ck_api_legacy CHECK ((origin = 'LEGACY') = (legacy_id IS NOT NULL)),
  CONSTRAINT ck_api_deleted CHECK ((deleted_at IS NULL) = (delete_reason IS NULL))
);
CREATE UNIQUE INDEX uq_api_legacy_id ON ph02_catalog.api (tenant_id, legacy_id) WHERE legacy_id IS NOT NULL;
CREATE INDEX ix_api_system ON ph02_catalog.api (tenant_id, system_code) WHERE deleted_at IS NULL;
CREATE INDEX ix_api_owner ON ph02_catalog.api (tenant_id, owner_org_code) WHERE deleted_at IS NULL;
CREATE INDEX ix_api_category ON ph02_catalog.api (tenant_id, category_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_api_visibility ON ph02_catalog.api (tenant_id, visibility, data_class) WHERE deleted_at IS NULL;
CREATE INDEX ix_api_name_trgm ON ph02_catalog.api USING gin (lower(name) gin_trgm_ops);
CREATE TRIGGER tg_api_touch BEFORE UPDATE ON ph02_catalog.api FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.api', 'P');
COMMENT ON TABLE ph02_catalog.api IS 'EN-02-01 API: nhận diện, phân loại dữ liệu, mức hiển thị, chủ quản (FR-02-001, 002, 010, 013, 014, 040, 041, 045). Vòng đời nằm ở api_version. Xóa mềm bằng deleted_at (BR-02-020); mã không dùng lại (BR-02-021).';
COMMENT ON COLUMN ph02_catalog.api.system_code IS 'Mã HTTT cung cấp ở PH-01 (bản sao system_replica); không khóa ngoại vì khác schema, kiểm ở dịch vụ (ERR-02-004).';
COMMENT ON COLUMN ph02_catalog.api.owner_org_code IS 'Đơn vị chủ quản API; phải là đơn vị của HTTT cung cấp trừ khi TA chuyển chủ quản (BR-02-032).';
COMMENT ON COLUMN ph02_catalog.api.data_class IS 'PUBLIC, INTERNAL, RESTRICTED, SENSITIVE theo SAD §8.2; quyết định kiểu xác thực tối thiểu của gói (BR-02-016).';
COMMENT ON COLUMN ph02_catalog.api.data_class_rank IS 'Hạng số của data_class (0…3), cột sinh tự động; so với plan.auth_rank ở trigger tg_plan_auth_policy.';
COMMENT ON COLUMN ph02_catalog.api.visibility IS 'TENANT, NATIONAL, PUBLIC; PUBLIC chỉ với dữ liệu PUBLIC, NATIONAL không với SENSITIVE (BR-02-037, CHECK ck_api_visibility_class).';
COMMENT ON COLUMN ph02_catalog.api.base_path IS 'Tiền tố công bố /{nhóm}/{apiCode}; context-path đầy đủ thêm /v{major} ở context_path_reservation.';
COMMENT ON COLUMN ph02_catalog.api.flow_ref IS 'Với origin = FLOW: {workspaceCode, flowCode} của luồng PH-04; phần hợp đồng không sửa tay (BR-02-030).';
COMMENT ON COLUMN ph02_catalog.api.legacy_id IS 'Mã API ở APIM cũ khi origin = LEGACY; khóa duy nhất làm cho nhập lại lũy đẳng (FR-02-061).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api CASCADE;

-- @changeset ph02-0130-api-tag
CREATE TABLE ph02_catalog.api_tag (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_id           uuid          NOT NULL,
  tag              varchar(40)   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_api_tag PRIMARY KEY (id),
  CONSTRAINT uq_api_tag UNIQUE (tenant_id, api_id, tag),
  CONSTRAINT fk_api_tag_api FOREIGN KEY (api_id, tenant_id) REFERENCES ph02_catalog.api (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_api_tag_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_api_tag_format CHECK (tag ~ '^[a-z0-9][a-z0-9-]{0,39}$')
);
CREATE INDEX ix_api_tag_tag ON ph02_catalog.api_tag (tenant_id, tag);
CALL ph02_catalog.p_enable_rls('ph02_catalog.api_tag', 'P');
COMMENT ON TABLE ph02_catalog.api_tag IS 'EN-02-12 Thẻ tự do gắn với API (FR-02-007). Tối đa 10 thẻ mỗi API kiểm ở dịch vụ.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api_tag CASCADE;

-- @changeset ph02-0140-api-version
CREATE TABLE ph02_catalog.api_version (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_id           uuid          NOT NULL,
  version_no       varchar(16)   NOT NULL,
  major            integer       NOT NULL,
  status           varchar(10)   NOT NULL DEFAULT 'DRAFT',
  activating       boolean       NOT NULL DEFAULT false,
  current_spec_id  uuid,
  successor_version_id uuid,
  sunset_at        timestamptz,
  urgent_reason    varchar(1000),
  breaking         boolean       NOT NULL DEFAULT false,
  version_violation boolean      NOT NULL DEFAULT false,
  release_notes    varchar(2000),
  submitted_at     timestamptz,
  submitted_by     varchar(64),
  approved_at      timestamptz,
  published_at     timestamptz,
  suspended_at     timestamptz,
  suspended_by_role varchar(4),
  suspend_kind     varchar(12),
  retired_at       timestamptz,
  gateway_state    varchar(8)    NOT NULL DEFAULT 'NONE',
  last_test_spec_sha256 char(64),
  last_test_config_hash char(64),
  last_test_at     timestamptz,
  minhash          bytea,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_api_version PRIMARY KEY (id),
  CONSTRAINT uq_api_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_api_version_no UNIQUE (tenant_id, api_id, version_no),
  CONSTRAINT fk_api_version_api FOREIGN KEY (api_id, tenant_id) REFERENCES ph02_catalog.api (id, tenant_id),
  CONSTRAINT fk_api_version_successor FOREIGN KEY (successor_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_api_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_api_version_no CHECK (version_no ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
  CONSTRAINT ck_api_version_major CHECK (version_no !~ '^[0-9]+\.[0-9]+\.[0-9]+$' OR major = split_part(version_no, '.', 1)::integer),
  CONSTRAINT ck_api_version_status CHECK (status IN ('DRAFT', 'PENDING', 'PUBLISHED', 'SUSPENDED', 'DEPRECATED', 'RETIRED')),
  CONSTRAINT ck_api_version_activating CHECK (NOT activating OR status = 'PENDING'),
  CONSTRAINT ck_api_version_spec CHECK (status IN ('DRAFT', 'RETIRED') OR current_spec_id IS NOT NULL),
  CONSTRAINT ck_api_version_published CHECK (status NOT IN ('PUBLISHED', 'SUSPENDED', 'DEPRECATED') OR published_at IS NOT NULL),
  CONSTRAINT ck_api_version_deprecated CHECK (status <> 'DEPRECATED' OR sunset_at IS NOT NULL),
  CONSTRAINT ck_api_version_suspended CHECK ((status = 'SUSPENDED') = (suspended_at IS NOT NULL)),
  CONSTRAINT ck_api_version_suspend_kind CHECK (suspend_kind IS NULL OR suspend_kind IN ('INCIDENT', 'SECURITY', 'MAINTENANCE', 'OTHER')),
  CONSTRAINT ck_api_version_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_api_version_gateway CHECK (gateway_state IN ('NONE', 'APPLYING', 'SYNCED', 'FAILED')),
  CONSTRAINT ck_api_version_successor_self CHECK (successor_version_id IS DISTINCT FROM id),
  CONSTRAINT ex_api_version_one_live_per_major EXCLUDE USING btree (tenant_id WITH =, api_id WITH =, major WITH =)
    WHERE (status IN ('PUBLISHED', 'SUSPENDED', 'DEPRECATED')) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX ix_api_version_api ON ph02_catalog.api_version (tenant_id, api_id, status);
CREATE INDEX ix_api_version_status ON ph02_catalog.api_version (tenant_id, status);
CREATE INDEX ix_api_version_sunset ON ph02_catalog.api_version (sunset_at) WHERE status = 'DEPRECATED';
CREATE INDEX ix_api_version_suspended ON ph02_catalog.api_version (suspended_at) WHERE status = 'SUSPENDED';
CREATE INDEX ix_api_version_pending ON ph02_catalog.api_version (submitted_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_api_version_touch BEFORE UPDATE ON ph02_catalog.api_version FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.api_version', 'P');
COMMENT ON TABLE ph02_catalog.api_version IS 'EN-02-02 Phiên bản API, đơn vị của vòng đời (FRS §4.3; FR-02-034…045). Chuyển trạng thái chỉ qua máy trạng thái ở dịch vụ; CSDL giữ chốt chặn: cạnh hợp lệ (tg_api_version_guard), một phiên bản đang chạy mỗi số chính (ex_api_version_one_live_per_major, BR-02-035), đặc tả bất biến từ PENDING (BR-02-014).';
COMMENT ON COLUMN ph02_catalog.api_version.activating IS 'Đã duyệt (quyết định cuối) nhưng chờ gateway xác nhận nạp cấu hình; trạng thái vẫn PENDING cho tới khi có xác nhận (SDD 4.10).';
COMMENT ON COLUMN ph02_catalog.api_version.current_spec_id IS 'Đặc tả hiện hành; chỉ đổi khi DRAFT. FK hoãn tới cuối giao dịch vì api_spec trỏ ngược về phiên bản.';
COMMENT ON COLUMN ph02_catalog.api_version.sunset_at IS 'Hạn ngừng hẳn (tiêu đề Sunset, RFC 8594); bắt buộc khi DEPRECATED; hạn tối thiểu 02.deprecation.min-days kiểm ở dịch vụ (BR-02-004).';
COMMENT ON COLUMN ph02_catalog.api_version.version_violation IS 'Có thay đổi BREAKING mà số chính không tăng; chặn gửi duyệt (ERR-02-017, BR-02-003).';
COMMENT ON COLUMN ph02_catalog.api_version.suspended_by_role IS 'SO khi SO tạm ngừng vì an ninh: chỉ SO hoặc TA được tiếp tục (BR-02-034).';
COMMENT ON COLUMN ph02_catalog.api_version.gateway_state IS 'NONE, APPLYING, SYNCED, FAILED: trạng thái gỡ route sau lệnh hạn chế (SDD 4.10).';
COMMENT ON COLUMN ph02_catalog.api_version.last_test_spec_sha256 IS 'Băm đặc tả đã triển khai thử TEST thành công; so với băm hiện hành khi gửi duyệt (02.submit.require-test-deploy).';
COMMENT ON COLUMN ph02_catalog.api_version.minhash IS 'Chữ ký MinHash của tập (phương thức, đường dẫn) phục vụ phát hiện API trùng chức năng (FR-02-020).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api_version CASCADE;

-- @changeset ph02-0141-api-version-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_api_version_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  ok boolean;
BEGIN
  IF NEW.api_id <> OLD.api_id OR NEW.version_no <> OLD.version_no OR NEW.major <> OLD.major THEN
    RAISE EXCEPTION 'Mã API, số hiệu phiên bản bất biến (BR-02-021)' USING ERRCODE = '55000';
  END IF;
  IF OLD.status <> 'DRAFT' AND NEW.current_spec_id IS DISTINCT FROM OLD.current_spec_id THEN
    RAISE EXCEPTION 'Đặc tả của phiên bản % không còn DRAFT là bất biến (BR-02-014)', OLD.id USING ERRCODE = '55000';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    ok := (OLD.status, NEW.status) IN (
      ('DRAFT', 'PENDING'), ('DRAFT', 'RETIRED'),
      ('PENDING', 'DRAFT'), ('PENDING', 'PUBLISHED'),
      ('PUBLISHED', 'SUSPENDED'), ('PUBLISHED', 'DEPRECATED'), ('PUBLISHED', 'RETIRED'),
      ('SUSPENDED', 'PUBLISHED'), ('SUSPENDED', 'DEPRECATED'),
      ('DEPRECATED', 'RETIRED'));
    IF NOT ok THEN
      RAISE EXCEPTION 'Chuyển trạng thái phiên bản % → % không hợp lệ (FRS 4.3, SDD 8.1)', OLD.status, NEW.status USING ERRCODE = '55000';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_api_version_guard BEFORE UPDATE ON ph02_catalog.api_version FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_api_version_guard();
COMMENT ON FUNCTION ph02_catalog.tg_api_version_guard() IS 'Chốt chặn thứ hai của máy trạng thái phiên bản: cạnh hợp lệ (gồm PUBLISHED → RETIRED do thay thế cùng số chính), mã và số hiệu bất biến, đặc tả bất biến từ PENDING.';
-- @rollback DROP TRIGGER IF EXISTS tg_api_version_guard ON ph02_catalog.api_version; DROP FUNCTION IF EXISTS ph02_catalog.tg_api_version_guard();

-- @changeset ph02-0150-api-spec
CREATE TABLE ph02_catalog.api_spec (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  seq              integer       NOT NULL,
  format           varchar(10)   NOT NULL,
  source           varchar(8)    NOT NULL,
  source_url       varchar(2048),
  sha256           char(64)      NOT NULL,
  merged_sha256    char(64),
  size_bytes       integer       NOT NULL,
  operation_count  integer       NOT NULL DEFAULT 0,
  object_key       varchar(512)  NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_api_spec PRIMARY KEY (id),
  CONSTRAINT uq_api_spec_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_api_spec_seq UNIQUE (api_version_id, seq),
  CONSTRAINT fk_api_spec_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_api_spec_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_api_spec_format CHECK (format IN ('OPENAPI31', 'OPENAPI30', 'SWAGGER2')),
  CONSTRAINT ck_api_spec_source CHECK (source IN ('UPLOAD', 'URL', 'PASTE', 'FLOW', 'LEGACY')),
  CONSTRAINT ck_api_spec_url CHECK ((source = 'URL') = (source_url IS NOT NULL)),
  CONSTRAINT ck_api_spec_sha CHECK (sha256 ~ '^[0-9a-f]{64}$' AND (merged_sha256 IS NULL OR merged_sha256 ~ '^[0-9a-f]{64}$')),
  CONSTRAINT ck_api_spec_size CHECK (size_bytes BETWEEN 1 AND 52428800),
  CONSTRAINT ck_api_spec_ops CHECK (operation_count BETWEEN 0 AND 5000),
  CONSTRAINT ck_api_spec_flow_format CHECK (source <> 'FLOW' OR format = 'OPENAPI31')
);
CREATE INDEX ix_api_spec_sha ON ph02_catalog.api_spec (tenant_id, sha256);
CREATE TRIGGER tg_api_spec_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.api_spec FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.api_spec', 'P');
COMMENT ON TABLE ph02_catalog.api_spec IS 'EN-02-03 Đặc tả OpenAPI của phiên bản: chỉ thêm, giữ vĩnh viễn làm bằng chứng hợp đồng (BR-02-014, NFR-02-017). Nội dung ở kho đối tượng Garage; CSDL chỉ giữ khóa đối tượng và băm. Đặc tả mới là dòng mới (seq tăng).';
COMMENT ON COLUMN ph02_catalog.api_spec.object_key IS 'Khóa đối tượng specs/{apiCode}/{versionNo}/{sha256} ở bucket dh-{tenant}-catalog, dựng bằng ObjectKeys.of(tenant, …).';
COMMENT ON COLUMN ph02_catalog.api_spec.merged_sha256 IS 'Băm của đặc tả đã gộp tham chiếu và chuẩn hóa về OpenAPI 3.1; dùng làm khóa của diff_result.';
COMMENT ON COLUMN ph02_catalog.api_spec.size_bytes IS 'Trần cứng 50 MiB; trần theo tenant 02.spec.max-size-mib (mặc định 10 MiB) kiểm ở dịch vụ (ERR-02-009).';
COMMENT ON COLUMN ph02_catalog.api_spec.operation_count IS 'Không quá 5.000 thao tác (NFR-02-011).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api_spec CASCADE;

-- @changeset ph02-0151-api-version-spec-fk
ALTER TABLE ph02_catalog.api_version ADD CONSTRAINT fk_api_version_spec
  FOREIGN KEY (current_spec_id, tenant_id) REFERENCES ph02_catalog.api_spec (id, tenant_id) DEFERRABLE INITIALLY DEFERRED;
-- @rollback ALTER TABLE ph02_catalog.api_version DROP CONSTRAINT IF EXISTS fk_api_version_spec;

-- @changeset ph02-0160-api-operation
CREATE TABLE ph02_catalog.api_operation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  spec_id          uuid          NOT NULL,
  operation_id     varchar(128)  NOT NULL,
  method           varchar(7)    NOT NULL,
  path_template    varchar(512)  NOT NULL,
  summary          varchar(500),
  tags             varchar(40)[] NOT NULL DEFAULT '{}',
  required_scope   varchar(200),
  idempotent       boolean       NOT NULL DEFAULT false,
  deprecated       boolean       NOT NULL DEFAULT false,
  schema_ptr       varchar(512),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_api_operation PRIMARY KEY (id),
  CONSTRAINT uq_api_operation_id UNIQUE (spec_id, operation_id),
  CONSTRAINT uq_api_operation_route UNIQUE (spec_id, method, path_template),
  CONSTRAINT fk_api_operation_spec FOREIGN KEY (spec_id, tenant_id) REFERENCES ph02_catalog.api_spec (id, tenant_id),
  CONSTRAINT fk_api_operation_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_api_operation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_api_operation_method CHECK (method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS')),
  CONSTRAINT ck_api_operation_path CHECK (path_template ~ '^/'),
  CONSTRAINT ck_api_operation_tags CHECK (cardinality(tags) <= 20)
);
CREATE INDEX ix_api_operation_version ON ph02_catalog.api_operation (tenant_id, api_version_id);
CALL ph02_catalog.p_enable_rls('ph02_catalog.api_operation', 'P');
COMMENT ON TABLE ph02_catalog.api_operation IS 'Thao tác rút từ đặc tả (FR-02-002, 005, 029, 043). Dữ liệu dẫn xuất từ api_spec, dựng lại khi nạp đặc tả mới ở DRAFT; là nguồn cho danh sách thao tác của dữ liệu công bố (SEC-43).';
COMMENT ON COLUMN ph02_catalog.api_operation.required_scope IS 'Phạm vi cần có theo khai báo security của thao tác; PH-03 dùng để dựng luật kiểm tra.';
COMMENT ON COLUMN ph02_catalog.api_operation.schema_ptr IS 'Con trỏ JSON tới lược đồ yêu cầu trong đặc tả đã gộp, để PH-03 sinh lược đồ kiểm tra thân yêu cầu (SEC-43).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api_operation CASCADE;

-- @changeset ph02-0170-api-search-doc
CREATE TABLE ph02_catalog.api_search_doc (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_id           uuid          NOT NULL,
  api_code         varchar(63)   NOT NULL,
  has_published    boolean       NOT NULL DEFAULT false,
  tsv              tsvector      NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_api_search_doc PRIMARY KEY (id),
  CONSTRAINT uq_api_search_doc_api UNIQUE (tenant_id, api_id),
  CONSTRAINT fk_api_search_doc_api FOREIGN KEY (api_id, tenant_id) REFERENCES ph02_catalog.api (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_api_search_doc_tenant CHECK (tenant_id ~ '^T[0-9]{2}$')
);
CREATE INDEX ix_api_search_doc_tsv ON ph02_catalog.api_search_doc USING gin (tsv);
CREATE INDEX ix_api_search_doc_code ON ph02_catalog.api_search_doc USING gin (api_code gin_trgm_ops);
CREATE TRIGGER tg_api_search_doc_touch BEFORE UPDATE ON ph02_catalog.api_search_doc FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.api_search_doc', 'P');
COMMENT ON TABLE ph02_catalog.api_search_doc IS 'Chỉ mục tìm kiếm toàn văn một dòng mỗi API (FR-02-003, NFR-02-002). tsv có bốn trọng số: tên và apiCode (A), mô tả (B), thẻ và phân loại (C), summary thao tác (D) theo cấu hình vn_unaccent. SearchDocumentWriter cập nhật cùng giao dịch với thay đổi. Dùng khi 02.search.engine = POSTGRES (Q02-02).';
COMMENT ON COLUMN ph02_catalog.api_search_doc.has_published IS 'API có ít nhất một phiên bản từ PUBLISHED trở đi; người ngoài tổ chức chủ quản chỉ thấy các dòng này (BR-02-039).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api_search_doc CASCADE;

-- @changeset ph02-0180-context-path-reservation
CREATE TABLE ph02_catalog.context_path_reservation (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_id           uuid          NOT NULL,
  major            integer       NOT NULL,
  kind             varchar(12)   NOT NULL DEFAULT 'PRIMARY',
  path             varchar(255)  NOT NULL,
  released_after   timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_context_path_reservation PRIMARY KEY (id),
  CONSTRAINT uq_context_path UNIQUE (tenant_id, path),
  CONSTRAINT uq_context_path_api UNIQUE (tenant_id, api_id, major, kind),
  CONSTRAINT fk_context_path_api FOREIGN KEY (api_id, tenant_id) REFERENCES ph02_catalog.api (id, tenant_id),
  CONSTRAINT ck_context_path_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_context_path_kind CHECK (kind IN ('PRIMARY', 'LEGACY_ALIAS')),
  CONSTRAINT ck_context_path_major CHECK (major >= 1),
  CONSTRAINT ck_context_path_format CHECK (kind = 'LEGACY_ALIAS' OR path ~ '^/[a-z][a-z0-9-]{1,31}/[a-z][a-z0-9-]{2,62}/v[1-9][0-9]*$'),
  CONSTRAINT ck_context_path_major_suffix CHECK (kind <> 'PRIMARY' OR path LIKE '%/v' || major::text),
  CONSTRAINT ck_context_path_alias CHECK (kind <> 'LEGACY_ALIAS' OR path ~ '^/[A-Za-z0-9._~/-]{2,254}$')
);
CREATE INDEX ix_context_path_release ON ph02_catalog.context_path_reservation (released_after) WHERE released_after IS NOT NULL;
CREATE INDEX ix_context_path_prefix ON ph02_catalog.context_path_reservation (tenant_id, path text_pattern_ops);
CREATE TRIGGER tg_context_path_touch BEFORE UPDATE ON ph02_catalog.context_path_reservation FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.context_path_reservation', 'P');
COMMENT ON TABLE ph02_catalog.context_path_reservation IS 'Giữ chỗ context-path /{nhóm}/{apiCode}/v{major} (FR-02-024, BR-02-022): duy nhất trong tenant, bất biến sau PUBLISHED, giữ chỗ 12 tháng sau RETIRED (released_after). Khóa theo (API, số chính) nên phiên bản cùng số chính thay thế dùng lại đúng đường dẫn (BR-02-035). Bí danh đường dẫn hệ cũ (LEGACY_ALIAS) dùng chung bảng để kiểm xung đột một chỗ. Xung đột tiền tố kiểm ở ContextPathService dưới pg_advisory_xact_lock; khóa duy nhất là chốt chặn.';
COMMENT ON COLUMN ph02_catalog.context_path_reservation.released_after IS 'retired_at + 12 tháng khi phiên bản cuối của (API, số chính) RETIRED; sau mốc này mới cho dùng lại.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.context_path_reservation CASCADE;

-- @changeset ph02-0190-api-owner-transfer
CREATE TABLE ph02_catalog.api_owner_transfer (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_id           uuid          NOT NULL,
  from_org_code    varchar(64)   NOT NULL,
  to_org_code      varchar(64)   NOT NULL,
  from_system_code varchar(64)   NOT NULL,
  to_system_code   varchar(64)   NOT NULL,
  document_no      varchar(64)   NOT NULL,
  document_date    date          NOT NULL,
  reason           varchar(1000) NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_api_owner_transfer PRIMARY KEY (id),
  CONSTRAINT fk_api_owner_transfer_api FOREIGN KEY (api_id, tenant_id) REFERENCES ph02_catalog.api (id, tenant_id),
  CONSTRAINT ck_api_owner_transfer_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_api_owner_transfer_change CHECK ((from_org_code, from_system_code) IS DISTINCT FROM (to_org_code, to_system_code))
);
CREATE INDEX ix_api_owner_transfer_api ON ph02_catalog.api_owner_transfer (tenant_id, api_id, created_at DESC);
CREATE TRIGGER tg_api_owner_transfer_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.api_owner_transfer FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.api_owner_transfer', 'P');
COMMENT ON TABLE ph02_catalog.api_owner_transfer IS 'Lịch sử chuyển chủ quản API (FR-02-045): chỉ TA thực hiện, ghi số và ngày văn bản giao nhận (Q02-07), không lưu tệp ký số ở bản 0.1. Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.api_owner_transfer CASCADE;

-- @changeset ph02-0195-diff-result
CREATE TABLE ph02_catalog.diff_result (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  from_sha256      char(64)      NOT NULL,
  to_sha256        char(64)      NOT NULL,
  classifier_version varchar(16) NOT NULL,
  breaking_count   integer       NOT NULL DEFAULT 0,
  compatible_count integer       NOT NULL DEFAULT 0,
  uncertain_count  integer       NOT NULL DEFAULT 0,
  summary          jsonb         NOT NULL,
  detail_object_key varchar(512),
  computed_ms      integer,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_diff_result PRIMARY KEY (id),
  CONSTRAINT uq_diff_result UNIQUE (tenant_id, from_sha256, to_sha256, classifier_version),
  CONSTRAINT ck_diff_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_diff_result_sha CHECK (from_sha256 ~ '^[0-9a-f]{64}$' AND to_sha256 ~ '^[0-9a-f]{64}$' AND from_sha256 <> to_sha256),
  CONSTRAINT ck_diff_result_counts CHECK (breaking_count >= 0 AND compatible_count >= 0 AND uncertain_count >= 0),
  CONSTRAINT ck_diff_result_summary CHECK (jsonb_typeof(summary) = 'object')
);
CREATE TRIGGER tg_diff_result_append_only BEFORE UPDATE ON ph02_catalog.diff_result FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.diff_result', 'P');
COMMENT ON TABLE ph02_catalog.diff_result IS 'Bộ đệm kết quả so sánh hai đặc tả theo cặp băm đã gộp (FR-02-043, NFR-02-004). Hai đặc tả bất biến nên kết quả đúng vĩnh viễn với cùng classifier_version; khi đổi bảng luật phân loại thì có dòng mới, dòng cũ có thể xóa. Không chứa danh sách bên bị ảnh hưởng (tính lại từ đăng ký khi xem).';
COMMENT ON COLUMN ph02_catalog.diff_result.detail_object_key IS 'Danh sách thay đổi đầy đủ ở kho đối tượng khi vượt 5.000 thay đổi hoặc 256 KiB; summary chỉ giữ số đếm và nhóm đầu.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.diff_result CASCADE;
