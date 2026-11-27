--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0010-core.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0110-file-object
CREATE TABLE ph20_tenant.file_object (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  bucket                 varchar(63)    NOT NULL,
  object_path            varchar(1024)  NOT NULL,
  file_name              varchar(255)   NOT NULL,
  content_type           varchar(127)   NOT NULL,
  size_bytes             bigint         NOT NULL,
  sha256                 char(64)       NOT NULL,
  scan_status            varchar(10)    NOT NULL DEFAULT 'PENDING',
  data_class_id          uuid           NOT NULL,
  purpose                varchar(24)    NOT NULL DEFAULT 'OTHER',
  expires_at             timestamptz,
  deleted_at             timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_file_object PRIMARY KEY (id),
  CONSTRAINT uq_file_object_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_file_object_location UNIQUE (bucket, object_path),
  CONSTRAINT ck_file_object_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_file_object_size CHECK (size_bytes >= 0),
  CONSTRAINT ck_file_object_sha256 CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_file_object_scan_status CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED')),
  CONSTRAINT ck_file_object_purpose CHECK (purpose IN ('CONTRACT', 'EXPORT_PACKAGE', 'ORG_IMPORT', 'USAGE_REPORT', 'LEAK_REPORT', 'LOGO', 'OTHER')),
  CONSTRAINT ck_file_object_bucket CHECK (bucket ~ '^dh-[a-z0-9-]{3,58}$')
);
CREATE INDEX ix_file_object_expiry ON ph20_tenant.file_object (expires_at) WHERE expires_at IS NOT NULL;
CREATE TRIGGER tg_file_object_touch BEFORE UPDATE ON ph20_tenant.file_object FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.file_object', 'TECH');
COMMENT ON TABLE ph20_tenant.file_object IS 'Hạ tầng, DD-12 Siêu dữ liệu tệp: hợp đồng, gói bàn giao, tệp nhập tổ chức, báo cáo sử dụng, báo cáo kiểm thử rò rỉ, logo tỉnh. Nội dung nằm ở kho đối tượng Ceph RGW, bucket `dh-{tenant}-{mục đích}`; chỉ tệp quét sạch (`CLEAN`) mới được xử lý.';
COMMENT ON COLUMN ph20_tenant.file_object.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.file_object.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.file_object.bucket IS 'Bucket kho đối tượng, dạng `dh-{tenant}-{mục đích}` (D03-10 §4).';
COMMENT ON COLUMN ph20_tenant.file_object.object_path IS 'Đường dẫn đối tượng trong bucket (DD-12 `object_key`).';
COMMENT ON COLUMN ph20_tenant.file_object.file_name IS 'Tên gốc của tệp.';
COMMENT ON COLUMN ph20_tenant.file_object.content_type IS 'Kiểu nội dung, kiểm theo nội dung chứ không tin phần mở rộng.';
COMMENT ON COLUMN ph20_tenant.file_object.size_bytes IS 'Kích thước tệp, byte.';
COMMENT ON COLUMN ph20_tenant.file_object.sha256 IS 'Mã băm SHA-256 dạng hex, kiểm toàn vẹn.';
COMMENT ON COLUMN ph20_tenant.file_object.scan_status IS 'Kết quả quét mã độc: `PENDING`, `CLEAN`, `INFECTED`; chỉ `CLEAN` mới được xử lý.';
COMMENT ON COLUMN ph20_tenant.file_object.data_class_id IS 'Phân loại dữ liệu DD-08 (tham chiếu logic sang PH-09).';
COMMENT ON COLUMN ph20_tenant.file_object.purpose IS 'Mục đích: `CONTRACT`, `EXPORT_PACKAGE`, `ORG_IMPORT`, `USAGE_REPORT`, `LEAK_REPORT`, `LOGO`, `OTHER`.';
COMMENT ON COLUMN ph20_tenant.file_object.expires_at IS 'Hạn giữ của tệp tạm (gói bàn giao, tệp xuất).';
COMMENT ON COLUMN ph20_tenant.file_object.deleted_at IS 'Thời điểm xóa mềm.';
COMMENT ON COLUMN ph20_tenant.file_object.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.file_object.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.file_object.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.file_object.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.file_object.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.file_object CASCADE;

--changeset ph20:ph20-0120-provisioning-template
CREATE TABLE ph20_tenant.provisioning_template (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  template_code          varchar(63)    NOT NULL,
  version_no             integer        NOT NULL DEFAULT 1,
  name                   varchar(255)   NOT NULL,
  description            text,
  status                 varchar(16)    NOT NULL DEFAULT 'DRAFT',
  default_isolation_mode varchar(24)    NOT NULL DEFAULT 'SHARED',
  deployment_profile     varchar(4)     NOT NULL DEFAULT 'HT-A',
  default_quota          jsonb          NOT NULL DEFAULT '{}',
  default_modules        text[]         NOT NULL DEFAULT '{}',
  step_plan              jsonb          NOT NULL DEFAULT '[]',
  default_settings       jsonb          NOT NULL DEFAULT '{}',
  org_seed               jsonb          NOT NULL DEFAULT '[]',
  activated_at           timestamptz,
  retired_at             timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_provisioning_template PRIMARY KEY (id),
  CONSTRAINT uq_provisioning_template_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_provisioning_template_code_version UNIQUE (template_code, version_no),
  CONSTRAINT ck_provisioning_template_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_provisioning_template_code CHECK (template_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_provisioning_template_version CHECK (version_no >= 1),
  CONSTRAINT ck_provisioning_template_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_provisioning_template_isolation CHECK (default_isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_provisioning_template_profile CHECK (deployment_profile IN ('HT-A', 'HT-B')),
  CONSTRAINT ck_provisioning_template_json CHECK (jsonb_typeof(default_quota) = 'object' AND jsonb_typeof(step_plan) = 'array' AND jsonb_typeof(default_settings) = 'object' AND jsonb_typeof(org_seed) = 'array'),
  CONSTRAINT ck_provisioning_template_published CHECK (status <> 'PUBLISHED' OR activated_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_provisioning_template_published ON ph20_tenant.provisioning_template (template_code) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_provisioning_template_touch BEFORE UPDATE ON ph20_tenant.provisioning_template FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_provisioning_template_immutable BEFORE UPDATE ON ph20_tenant.provisioning_template FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('template_code', 'version_no');
CREATE TRIGGER tg_provisioning_template_frozen BEFORE UPDATE ON ph20_tenant.provisioning_template FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_frozen('status', 'PUBLISHED,RETIRED', 'default_quota', 'default_modules', 'step_plan', 'default_settings', 'org_seed', 'default_isolation_mode', 'deployment_profile');
CALL ph20_tenant.p_enable_rls('ph20_tenant.provisioning_template', 'PLAT');
COMMENT ON TABLE ph20_tenant.provisioning_template IS 'EN-20-09 Mẫu khởi tạo có phiên bản (FR-20-015): hạn mức mặc định, phân hệ bật mặc định, kế hoạch bước saga, cài đặt tỉnh mặc định, tổ chức cấp tỉnh nạp ở bước S13. Dữ liệu nền tảng (`tenant_id = PLATFORM`), chỉ PLATFORM đọc, ghi. Mẫu PUBLISHED bất biến, đổi bằng phiên bản mới.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.template_code IS 'Mã mẫu, chữ thường và gạch nối (`^[a-z][a-z0-9-]{2,62}$`), ví dụ `tinh-chuan`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.version_no IS 'Số phiên bản của mẫu, bắt đầu từ 1.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.name IS 'Tên mẫu.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.description IS 'Mô tả, cơ sở giả định quy mô.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.status IS 'Trạng thái mẫu: `DRAFT`, `PUBLISHED`, `RETIRED` (mỗi mã một bản PUBLISHED).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_isolation_mode IS 'Chế độ cách ly mặc định: `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.deployment_profile IS 'Hồ sơ triển khai: `HT-A` hoặc `HT-B`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_quota IS 'Hạn mức mặc định, đối tượng {QuotaResource: giá trị số}.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_modules IS 'Mã phân hệ bật mặc định (`PH-nn`), dùng ở bước S15_MODULES.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.step_plan IS 'Danh sách bước saga và tùy chọn (bước bắt buộc, điều kiện bỏ qua).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_settings IS 'Cài đặt tỉnh mặc định sao chép vào `tenant_settings`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.org_seed IS 'Danh sách tổ chức cấp tỉnh nạp ở bước S13_ORG_SEED.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.activated_at IS 'Thời điểm chuyển PUBLISHED.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.retired_at IS 'Thời điểm chuyển RETIRED.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.provisioning_template CASCADE;

--changeset ph20:ph20-0130-tenant
CREATE TABLE ph20_tenant.tenant (
  id                     uuid           NOT NULL,
  code                   varchar(16)    NOT NULL,
  kind                   varchar(16)    NOT NULL DEFAULT 'PROVINCE',
  name                   varchar(255)   NOT NULL,
  short_name             varchar(64),
  admin_unit_id          uuid,
  status                 varchar(16)    NOT NULL DEFAULT 'PROVISIONING',
  isolation_mode         varchar(24)    NOT NULL DEFAULT 'SHARED',
  merged_into_id         uuid,
  realm                  varchar(64),
  scale_profile          varchar(16),
  deployment_profile     varchar(4)     NOT NULL DEFAULT 'HT-A',
  template_id            uuid,
  config_path            varchar(128),
  declared_at            timestamptz    NOT NULL DEFAULT now(),
  activated_at           timestamptz,
  suspended_at           timestamptz,
  merged_at              timestamptz,
  decommissioned_at      timestamptz,
  status_reason          varchar(500),
  status_changed_at      timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant PRIMARY KEY (id),
  CONSTRAINT uq_tenant_code UNIQUE (code),
  CONSTRAINT ck_tenant_code CHECK (code ~ '^T[0-9]{2}$' OR code IN ('PLATFORM', 'COMMON')),
  CONSTRAINT ck_tenant_kind CHECK (kind IN ('PROVINCE', 'PLATFORM', 'COMMON')),
  CONSTRAINT ck_tenant_status CHECK (status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'MERGED', 'DECOMMISSIONED', 'FAILED')),
  CONSTRAINT ck_tenant_isolation_mode CHECK (isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_tenant_kind_code CHECK ((kind = 'PROVINCE' AND code ~ '^T[0-9]{2}$') OR (kind = 'PLATFORM' AND code = 'PLATFORM') OR (kind = 'COMMON' AND code = 'COMMON')),
  CONSTRAINT ck_tenant_province CHECK (kind <> 'PROVINCE' OR (admin_unit_id IS NOT NULL AND realm IS NOT NULL)),
  CONSTRAINT ck_tenant_realm CHECK (realm IS NULL OR realm = 'dh-' || lower(code)),
  CONSTRAINT ck_tenant_special CHECK (kind = 'PROVINCE' OR (status = 'ACTIVE' AND isolation_mode = 'SHARED')),
  CONSTRAINT ck_tenant_merged CHECK (status <> 'MERGED' OR merged_into_id IS NOT NULL),
  CONSTRAINT ck_tenant_self_merge CHECK (merged_into_id IS NULL OR merged_into_id <> id),
  CONSTRAINT ck_tenant_active CHECK (status <> 'ACTIVE' OR activated_at IS NOT NULL),
  CONSTRAINT ck_tenant_profile CHECK (deployment_profile IN ('HT-A', 'HT-B')),
  CONSTRAINT ck_tenant_scale CHECK (scale_profile IS NULL OR scale_profile ~ '^QM-[A-Z0-9]{2,12}$'),
  CONSTRAINT fk_tenant_merged_into FOREIGN KEY (merged_into_id) REFERENCES ph20_tenant.tenant (id),
  CONSTRAINT fk_tenant_template FOREIGN KEY (template_id) REFERENCES ph20_tenant.provisioning_template (id)
);
CREATE UNIQUE INDEX uq_tenant_admin_unit_active ON ph20_tenant.tenant (admin_unit_id) WHERE kind = 'PROVINCE' AND status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'FAILED');
CREATE INDEX ix_tenant_status ON ph20_tenant.tenant (status);
CREATE INDEX ix_tenant_merged_into ON ph20_tenant.tenant (merged_into_id) WHERE merged_into_id IS NOT NULL;
CREATE TRIGGER tg_tenant_touch BEFORE UPDATE ON ph20_tenant.tenant FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_tenant_immutable BEFORE UPDATE ON ph20_tenant.tenant FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('code', 'kind');
CREATE TRIGGER tg_tenant_transition BEFORE UPDATE ON ph20_tenant.tenant FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"PROVISIONING": ["ACTIVE", "FAILED"], "FAILED": ["PROVISIONING", "DECOMMISSIONED"], "ACTIVE": ["SUSPENDED", "MERGING"], "SUSPENDED": ["ACTIVE", "DECOMMISSIONED"], "MERGING": ["MERGED", "ACTIVE"], "MERGED": ["DECOMMISSIONED"]}');
CREATE TRIGGER tg_tenant_no_delete BEFORE DELETE ON ph20_tenant.tenant FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_no_delete();
ALTER TABLE ph20_tenant.tenant ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph20_tenant.tenant FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ph20_tenant.tenant FOR SELECT USING (code = current_setting('app.tenant_id', false));
CREATE POLICY platform_read ON ph20_tenant.tenant FOR SELECT TO ph20_platform_app, ph20_owner, ph20_ro USING (current_setting('app.tenant_id', false) = 'PLATFORM');
CREATE POLICY platform_insert ON ph20_tenant.tenant FOR INSERT TO ph20_platform_app, ph20_owner WITH CHECK (current_setting('app.tenant_id', false) = 'PLATFORM');
CREATE POLICY platform_update ON ph20_tenant.tenant FOR UPDATE TO ph20_platform_app, ph20_owner USING (current_setting('app.tenant_id', false) = 'PLATFORM') WITH CHECK (current_setting('app.tenant_id', false) = 'PLATFORM');
CREATE POLICY platform_delete ON ph20_tenant.tenant FOR DELETE TO ph20_platform_app, ph20_owner USING (current_setting('app.tenant_id', false) = 'PLATFORM');
COMMENT ON TABLE ph20_tenant.tenant IS 'EN-20-01 Tenant (DD-01): một tỉnh hoặc thành phố trực thuộc trung ương, cộng hai tenant đặc biệt `PLATFORM` và `COMMON`. Không có cột `tenant_id` vì chính bảng là tenant. RLS đặc thù: phiên PLATFORM thấy mọi dòng, tenant khác chỉ thấy dòng `code` của mình, chỉ PLATFORM ghi. Không xóa dòng; chấm dứt bằng `DECOMMISSIONED`. FR-20-001…007, 038…043, 065, 066.';
COMMENT ON COLUMN ph20_tenant.tenant.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant.code IS 'Mã tenant `Tnn`, `PLATFORM` hoặc `COMMON`; khóa nghiệp vụ, bất biến.';
COMMENT ON COLUMN ph20_tenant.tenant.kind IS 'Loại tenant: `PROVINCE`, `PLATFORM`, `COMMON`; bất biến.';
COMMENT ON COLUMN ph20_tenant.tenant.name IS 'Tên tỉnh, ví dụ `Tỉnh Lâm Đồng`.';
COMMENT ON COLUMN ph20_tenant.tenant.short_name IS 'Tên ngắn hiển thị.';
COMMENT ON COLUMN ph20_tenant.tenant.admin_unit_id IS 'Đơn vị hành chính cấp tỉnh (DD-07 ở PH-07, tham chiếu logic); bắt buộc với tenant tỉnh.';
COMMENT ON COLUMN ph20_tenant.tenant.status IS 'Trạng thái tenant (D03-10 §5.1): `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `MERGING`, `MERGED`, `DECOMMISSIONED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant.isolation_mode IS 'Chế độ cách ly: `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER`.';
COMMENT ON COLUMN ph20_tenant.tenant.merged_into_id IS 'Tenant đích khi `MERGED` (DD-01 `merged_into_id`).';
COMMENT ON COLUMN ph20_tenant.tenant.realm IS 'Realm Keycloak `dh-{code thường}`; bắt buộc với tenant tỉnh.';
COMMENT ON COLUMN ph20_tenant.tenant.scale_profile IS 'Hồ sơ quy mô `QM-*` (FR-20-001).';
COMMENT ON COLUMN ph20_tenant.tenant.deployment_profile IS 'Hồ sơ triển khai: `HT-A` hoặc `HT-B`.';
COMMENT ON COLUMN ph20_tenant.tenant.template_id IS 'Phiên bản mẫu khởi tạo đã dùng.';
COMMENT ON COLUMN ph20_tenant.tenant.config_path IS 'Thư mục cấu hình trong kho Git `dh-tenant-config`, dạng `tenants/{mã}/`.';
COMMENT ON COLUMN ph20_tenant.tenant.declared_at IS 'Thời điểm khai báo; cùng `activated_at` tính thời gian khởi tạo (KPI-12).';
COMMENT ON COLUMN ph20_tenant.tenant.activated_at IS 'Lần đầu chuyển `ACTIVE`.';
COMMENT ON COLUMN ph20_tenant.tenant.suspended_at IS 'Lần tạm ngừng gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant.merged_at IS 'Thời điểm chuyển `MERGED`.';
COMMENT ON COLUMN ph20_tenant.tenant.decommissioned_at IS 'Thời điểm chấm dứt.';
COMMENT ON COLUMN ph20_tenant.tenant.status_reason IS 'Lý do của lần đổi trạng thái gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant.status_changed_at IS 'Thời điểm đổi trạng thái gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant CASCADE;

--changeset ph20:ph20-0140-organization
CREATE TABLE ph20_tenant.organization (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  code                   varchar(64)    NOT NULL,
  name                   varchar(255)   NOT NULL,
  short_name             varchar(64),
  parent_id              uuid,
  org_type               varchar(16)    NOT NULL,
  status                 varchar(16)    NOT NULL DEFAULT 'ACTIVE',
  admin_unit_id          uuid           NOT NULL,
  is_data_owner          boolean        NOT NULL DEFAULT false,
  effective_from         date           NOT NULL,
  effective_to           date,
  successor_id           uuid,
  external_code          varchar(64),
  sort_order             integer        NOT NULL DEFAULT 0,
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_organization PRIMARY KEY (id),
  CONSTRAINT uq_organization_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_organization_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_organization_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_organization_org_type CHECK (org_type IN ('PROVINCE_PC', 'DEPARTMENT', 'COMMUNE_PC', 'PUBLIC_UNIT', 'OTHER')),
  CONSTRAINT ck_organization_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'DISSOLVED', 'MERGED')),
  CONSTRAINT ck_organization_code CHECK (code ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'),
  CONSTRAINT ck_organization_no_self_parent CHECK (parent_id IS NULL OR parent_id <> id),
  CONSTRAINT ck_organization_no_self_successor CHECK (successor_id IS NULL OR successor_id <> id),
  CONSTRAINT ck_organization_effective CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CONSTRAINT ck_organization_closed CHECK (status NOT IN ('DISSOLVED', 'MERGED') OR effective_to IS NOT NULL),
  CONSTRAINT ck_organization_merged CHECK (status <> 'MERGED' OR successor_id IS NOT NULL),
  CONSTRAINT fk_organization_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_organization_parent FOREIGN KEY (parent_id, tenant_id) REFERENCES ph20_tenant.organization (id, tenant_id),
  CONSTRAINT fk_organization_successor FOREIGN KEY (successor_id, tenant_id) REFERENCES ph20_tenant.organization (id, tenant_id)
);
CREATE INDEX ix_organization_type ON ph20_tenant.organization (tenant_id, org_type);
CREATE INDEX ix_organization_owner ON ph20_tenant.organization (tenant_id, is_data_owner) WHERE is_data_owner;
CREATE INDEX ix_organization_status ON ph20_tenant.organization (tenant_id, status);
CREATE INDEX ix_organization_fk_parent ON ph20_tenant.organization (tenant_id, parent_id);
CREATE INDEX ix_organization_fk_successor ON ph20_tenant.organization (tenant_id, successor_id);
CREATE TRIGGER tg_organization_touch BEFORE UPDATE ON ph20_tenant.organization FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_organization_immutable BEFORE UPDATE ON ph20_tenant.organization FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('code');
CREATE TRIGGER tg_organization_cycle BEFORE INSERT OR UPDATE OF parent_id ON ph20_tenant.organization FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_organization_cycle();
CALL ph20_tenant.p_enable_rls('ph20_tenant.organization', 'OWN');
COMMENT ON TABLE ph20_tenant.organization IS 'EN-20-02 Tổ chức (DD-02): cơ quan, đơn vị trong tỉnh, là chủ quản HTTT, nơi công tác của người dùng, chủ quản dữ liệu. Cây cấp trên không chu trình, hiệu lực theo ngày, giải thể hoặc sáp nhập có tổ chức kế thừa. FR-20-053…058.';
COMMENT ON COLUMN ph20_tenant.organization.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.organization.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.organization.code IS 'Mã tổ chức, duy nhất trong tenant, ưu tiên mã định danh điện tử của cơ quan; bất biến.';
COMMENT ON COLUMN ph20_tenant.organization.name IS 'Tên tổ chức.';
COMMENT ON COLUMN ph20_tenant.organization.short_name IS 'Tên viết tắt.';
COMMENT ON COLUMN ph20_tenant.organization.parent_id IS 'Cơ quan cấp trên cùng tenant, không tạo chu trình, không tự trỏ vào mình.';
COMMENT ON COLUMN ph20_tenant.organization.org_type IS 'Loại: `PROVINCE_PC`, `DEPARTMENT`, `COMMUNE_PC`, `PUBLIC_UNIT`, `OTHER`.';
COMMENT ON COLUMN ph20_tenant.organization.status IS 'Trạng thái: `ACTIVE`, `INACTIVE`, `DISSOLVED`, `MERGED`.';
COMMENT ON COLUMN ph20_tenant.organization.admin_unit_id IS 'Địa bàn, đơn vị hành chính (DD-07 ở PH-07, tham chiếu logic).';
COMMENT ON COLUMN ph20_tenant.organization.is_data_owner IS 'Là chủ quản dữ liệu (SH-08, FR-20-058).';
COMMENT ON COLUMN ph20_tenant.organization.effective_from IS 'Ngày bắt đầu hiệu lực.';
COMMENT ON COLUMN ph20_tenant.organization.effective_to IS 'Ngày hết hiệu lực, không nhỏ hơn `effective_from`.';
COMMENT ON COLUMN ph20_tenant.organization.successor_id IS 'Tổ chức kế thừa khi giải thể hoặc sáp nhập.';
COMMENT ON COLUMN ph20_tenant.organization.external_code IS 'Mã định danh điện tử theo quy định hiện hành (nếu khác `code`).';
COMMENT ON COLUMN ph20_tenant.organization.sort_order IS 'Thứ tự hiển thị trong cùng cấp.';
COMMENT ON COLUMN ph20_tenant.organization.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.organization.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.organization.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.organization.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.organization.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.organization.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.organization CASCADE;

--changeset ph20:ph20-0150-tenant-contact
CREATE TABLE ph20_tenant.tenant_contact (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  contact_type           varchar(12)    NOT NULL,
  full_name              varchar(255)   NOT NULL,
  job_title              varchar(255),
  email                  varchar(254)   NOT NULL,
  phone                  varchar(20),
  organization_id        uuid,
  is_primary             boolean        NOT NULL DEFAULT false,
  status                 varchar(10)    NOT NULL DEFAULT 'ACTIVE',
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_contact PRIMARY KEY (id),
  CONSTRAINT uq_tenant_contact_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_tenant_contact_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_contact_contact_type CHECK (contact_type IN ('LEADER', 'TENANT_ADMIN', 'TECHNICAL', 'SECURITY')),
  CONSTRAINT ck_tenant_contact_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
  CONSTRAINT ck_tenant_contact_email CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+$'),
  CONSTRAINT ck_tenant_contact_phone CHECK (phone IS NULL OR phone ~ '^[0-9+() .-]{6,20}$'),
  CONSTRAINT fk_tenant_contact_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_contact_organization FOREIGN KEY (organization_id, tenant_id) REFERENCES ph20_tenant.organization (id, tenant_id)
);
CREATE UNIQUE INDEX uq_tenant_contact_primary ON ph20_tenant.tenant_contact (tenant_id, contact_type) WHERE is_primary AND status = 'ACTIVE';
CREATE INDEX ix_tenant_contact_tenant_type ON ph20_tenant.tenant_contact (tenant_id, contact_type);
CREATE INDEX ix_tenant_contact_fk_organization ON ph20_tenant.tenant_contact (tenant_id, organization_id);
CREATE TRIGGER tg_tenant_contact_touch BEFORE UPDATE ON ph20_tenant.tenant_contact FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_contact', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_contact IS 'EN-20-03 Đầu mối của tenant (FR-20-005): lãnh đạo, quản trị tenant, kỹ thuật, an ninh; nhận thông báo đổi trạng thái, bảo trì, ngưỡng hạn mức. Có dữ liệu cá nhân (họ tên, thư điện tử, điện thoại), phân loại HC theo DD-09.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.contact_type IS 'Vai đầu mối: `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY`.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.full_name IS 'Họ tên (dữ liệu cá nhân).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.job_title IS 'Chức danh.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.email IS 'Thư điện tử nhận thông báo (dữ liệu cá nhân).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.phone IS 'Điện thoại (dữ liệu cá nhân).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.organization_id IS 'Tổ chức công tác của đầu mối.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.is_primary IS 'Đầu mối chính của loại này; mỗi (tenant, loại) tối đa một dòng.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.status IS 'Trạng thái: `ACTIVE` hoặc `INACTIVE`.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_contact CASCADE;

--changeset ph20:ph20-0160-tenant-contract
CREATE TABLE ph20_tenant.tenant_contract (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  contract_no            varchar(64)    NOT NULL,
  title                  varchar(255)   NOT NULL,
  service_level          varchar(10)    NOT NULL DEFAULT 'STANDARD',
  status                 varchar(12)    NOT NULL DEFAULT 'DRAFT',
  signed_at              date,
  valid_from             date           NOT NULL,
  valid_to               date,
  file_id                uuid,
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_contract PRIMARY KEY (id),
  CONSTRAINT uq_tenant_contract_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_contract_no UNIQUE (tenant_id, contract_no),
  CONSTRAINT ck_tenant_contract_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_contract_status CHECK (status IN ('DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED')),
  CONSTRAINT ck_tenant_contract_service_level CHECK (service_level IN ('STANDARD', 'PREMIUM')),
  CONSTRAINT ck_tenant_contract_valid CHECK (valid_to IS NULL OR valid_to >= valid_from),
  CONSTRAINT ck_tenant_contract_active CHECK (status <> 'ACTIVE' OR signed_at IS NOT NULL),
  CONSTRAINT fk_tenant_contract_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_contract_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_tenant_contract_fk_file ON ph20_tenant.tenant_contract (tenant_id, file_id);
CREATE TRIGGER tg_tenant_contract_touch BEFORE UPDATE ON ph20_tenant.tenant_contract FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_contract', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_contract IS 'EN-20-04 Hợp đồng dịch vụ của tenant (FR-20-005): số hợp đồng, hiệu lực, mức dịch vụ, tệp hợp đồng. Hợp đồng hết hạn là một lý do tạm ngừng (`CONTRACT_EXPIRED`).';
COMMENT ON COLUMN ph20_tenant.tenant_contract.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_contract.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.contract_no IS 'Số hợp đồng, duy nhất trong tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.title IS 'Tên, trích yếu hợp đồng.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.service_level IS 'Mức dịch vụ: `STANDARD` hoặc `PREMIUM`.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.status IS 'Trạng thái: `DRAFT`, `ACTIVE`, `EXPIRED`, `TERMINATED`.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.signed_at IS 'Ngày ký.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.valid_from IS 'Ngày bắt đầu hiệu lực.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.valid_to IS 'Ngày hết hiệu lực, không nhỏ hơn `valid_from`.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.file_id IS 'Tệp hợp đồng ở `file_object`.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_contract.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_contract.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_contract.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_contract CASCADE;
