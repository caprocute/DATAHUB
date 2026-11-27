-- =============================================================================
-- D03-03-PH20 · DDL schema ph20_tenant — PH-20 Quản trị tenant và phát hành sản phẩm
-- Phiên bản 0.1 · 2026-11-27 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py (khung theo PH-16); sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph20_tenant.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên bảng: brief PH-20 §5.1, §5.2; FRS PH-20 Phụ lục A. Schema nằm trên cụm pg-core, do dh-platform (control plane)
-- dùng. Hai nhóm bảng: bảng theo tenant (tenant_id = mã tỉnh, RLS mẫu D03-10 §4) và bảng dữ liệu nền tảng (tenant_id = PLATFORM).
-- Bảng tenant là ngoại lệ: không có cột tenant_id, chính nó là tenant (D02-07 DD-01).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 20-0000-bootstrap.sql
-- @changeset ph20-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_owner') THEN
    CREATE ROLE ph20_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_app') THEN
    CREATE ROLE ph20_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_platform_app') THEN
    CREATE ROLE ph20_platform_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_ro') THEN
    CREATE ROLE ph20_ro NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph20-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph20_tenant AUTHORIZATION ph20_owner;
COMMENT ON SCHEMA ph20_tenant IS 'PH-20 Quản trị tenant và phát hành sản phẩm (dh-platform, package vn.datahub.platform.tenant và vn.datahub.platform.release): hồ sơ tenant, tổ chức, saga khởi tạo, cấu hình, hạn mức và sử dụng, phân hệ, vòng đời, sáp nhập, phát hành và nâng cấp. Không lưu bí mật hay khóa: chỉ tham chiếu đường dẫn.';
GRANT USAGE ON SCHEMA ph20_tenant TO ph20_app, ph20_platform_app, ph20_ro;
COMMENT ON ROLE ph20_app IS 'Vai kết nối của nhóm API /api/tenant/v1 và các luồng theo tenant: chỉ DML trên bảng theo tenant, không BYPASSRLS, không là chủ bảng.';
COMMENT ON ROLE ph20_platform_app IS 'Vai kết nối riêng của nhóm /api/platform/v1, /internal/tenant/v1 và saga (FR-00-012): đọc, ghi liên tenant khi phiên đặt app.tenant_id = PLATFORM; không BYPASSRLS, không là chủ bảng.';
COMMENT ON ROLE ph20_ro IS 'Vai chỉ đọc cho kiểm toán nền tảng, báo cáo, BI: chỉ SELECT, vẫn chịu RLS (đọc liên tenant khi phiên là PLATFORM).';
-- @rollback DROP SCHEMA IF EXISTS ph20_tenant CASCADE;

SET ROLE ph20_owner;

-- @changeset ph20-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback empty

-- @file 20-0001-functions.sql
-- @changeset ph20-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph20_tenant.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_touch();

-- @changeset ph20-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph20_tenant.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, dữ kiện đã ghi.';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_immutable();

-- @changeset ph20-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph20_tenant.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (lịch sử trạng thái, kết quả kiểm tra khói). Dọn bằng DETACH, DROP phân vùng dưới ph20_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_append_only();

-- @changeset ph20-0013-fn-no-delete splitStatements:false
CREATE OR REPLACE FUNCTION ph20_tenant.tg_no_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % không xóa dòng: dùng trạng thái DECOMMISSIONED, DISSOLVED hoặc RETIRED', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_no_delete() IS 'Chặn xóa dòng bảng tenant, kể cả chủ schema (FR-20-006, FR-20-042: tenant chấm dứt vẫn giữ hồ sơ).';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_no_delete();

-- @changeset ph20-0014-fn-frozen splitStatements:false
-- Bất biến theo trạng thái: đối số 1 là tên cột trạng thái, đối số 2 là danh sách trạng thái (cách nhau dấu phẩy), các đối số sau là cột không được đổi khi dòng cũ ở các trạng thái đó.
CREATE OR REPLACE FUNCTION ph20_tenant.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
  st text := to_jsonb(OLD) ->> TG_ARGV[0];
  frozen text[] := string_to_array(TG_ARGV[1], ',');
  i integer;
BEGIN
  IF st = ANY (frozen) THEN
    FOR i IN 3 .. TG_NARGS LOOP
      c := TG_ARGV[i - 1];
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Bản ghi % ở trạng thái % không sửa được cột %', TG_TABLE_NAME, st, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_frozen() IS 'Mẫu khởi tạo, phiên bản sản phẩm đã ACTIVE hoặc đã phát hành không đổi nội dung; thay đổi cần phiên bản mới.';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_frozen();

-- @changeset ph20-0015-fn-transition splitStatements:false
-- Máy trạng thái: đối số 1 là tên cột, đối số 2 là bản đồ JSON {trạng thái cũ: [trạng thái mới được phép]}.
CREATE OR REPLACE FUNCTION ph20_tenant.tg_transition() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  o text := to_jsonb(OLD) ->> TG_ARGV[0];
  n text := to_jsonb(NEW) ->> TG_ARGV[0];
BEGIN
  IF o IS DISTINCT FROM n AND NOT COALESCE((TG_ARGV[1]::jsonb -> o) @> to_jsonb(n), false) THEN
    RAISE EXCEPTION 'Bảng %: không chuyển % từ % sang %', TG_TABLE_NAME, TG_ARGV[0], o, n USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_transition() IS 'Chỉ cho chuyển trạng thái theo bản đồ khai báo ở tham số trigger (D03-10 §5.1 và vòng đời ở FRS Phụ lục A).';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_transition();

-- @changeset ph20-0016-fn-org-cycle splitStatements:false
CREATE OR REPLACE FUNCTION ph20_tenant.tg_organization_cycle() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  hit boolean;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;
  WITH RECURSIVE up AS (
    SELECT o.id, o.parent_id FROM ph20_tenant.organization o WHERE o.id = NEW.parent_id AND o.tenant_id = NEW.tenant_id
    UNION
    SELECT o.id, o.parent_id FROM ph20_tenant.organization o JOIN up ON o.id = up.parent_id AND o.tenant_id = NEW.tenant_id
  )
  SELECT EXISTS (SELECT 1 FROM up WHERE id = NEW.id) INTO hit;
  IF hit THEN
    RAISE EXCEPTION 'Tổ chức % tạo chu trình cấp trên', NEW.code USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph20_tenant.tg_organization_cycle() IS 'Chặn chu trình trong cây tổ chức (DD-02 parent_id không tạo chu trình); CHECK chỉ chặn tự trỏ vào chính mình.';
-- @rollback DROP FUNCTION IF EXISTS ph20_tenant.tg_organization_cycle();

-- @changeset ph20-0017-fn-rls splitStatements:false
-- Mẫu D03-10 §4 mở rộng. Chế độ: OWN (tenant ghi, PLATFORM đọc), CTL (PLATFORM ghi, tenant đọc), TECH (tenant ghi cùng giao dịch, PLATFORM ghi),
-- PLAT (dữ liệu nền tảng, chỉ phiên PLATFORM), PLATR (như PLAT, mọi tenant đọc). Chính sách theo vai chỉ cấp cho ph20_platform_app, ph20_owner, ph20_ro;
-- ph20_app giả mạo phiên PLATFORM cũng không đọc thêm được dòng của tenant khác.
CREATE OR REPLACE PROCEDURE ph20_tenant.p_enable_rls(p_table regclass, p_mode text)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  cur text := $c$current_setting('app.tenant_id', false)$c$;
  mine text := format('tenant_id = %s', cur);
  isplat text := format('%s = ''PLATFORM''', cur);
BEGIN
  IF p_mode NOT IN ('OWN', 'CTL', 'TECH', 'PLAT', 'PLATR') THEN
    RAISE EXCEPTION 'Chế độ RLS không hợp lệ: %', p_mode;
  END IF;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  IF p_mode = 'CTL' THEN
    EXECUTE format('CREATE POLICY tenant_isolation ON %s FOR SELECT USING (%s)', t, mine);
  ELSE
    EXECUTE format('CREATE POLICY tenant_isolation ON %s USING (%s) WITH CHECK (%s)', t, mine, mine);
  END IF;
  IF p_mode IN ('CTL', 'TECH') THEN
    EXECUTE format('CREATE POLICY platform_write ON %s FOR ALL TO ph20_platform_app, ph20_owner USING (%s) WITH CHECK (%s)', t, isplat, isplat);
    EXECUTE format('CREATE POLICY platform_read ON %s FOR SELECT TO ph20_ro USING (%s)', t, isplat);
  ELSIF p_mode = 'OWN' THEN
    EXECUTE format('CREATE POLICY platform_read ON %s FOR SELECT TO ph20_platform_app, ph20_owner, ph20_ro USING (%s)', t, isplat);
  ELSIF p_mode = 'PLATR' THEN
    EXECUTE format('CREATE POLICY platform_data_read ON %s FOR SELECT USING (tenant_id = ''PLATFORM'')', t);
  END IF;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_enable_rls(regclass, text) IS 'Bật FORCE RLS và chính sách tenant_isolation theo D03-10 §4 (ADR-003), thêm chính sách cho phiên PLATFORM theo chế độ OWN, CTL, TECH, PLAT, PLATR.';
-- @rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_enable_rls(regclass, text);

-- @changeset ph20-0018-fn-partitions splitStatements:false
-- Phân vùng tháng. Cột phân vùng kiểu timestamptz: biên 00:00 giờ Việt Nam (UTC+7, không có giờ mùa hè).
CREATE OR REPLACE PROCEDURE ph20_tenant.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)', part, p_table,
                     to_char(d + interval '1 month' * i, 'YYYY-MM-DD') || ' 00:00:00+07',
                     to_char(d + interval '1 month' * (i + 1), 'YYYY-MM-DD') || ' 00:00:00+07');
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho usage_snapshot. PartitionMaintenanceJob (PH-18) gọi hằng ngày; dọn bằng DETACH, DROP dưới ph20_owner theo 20.usage.retention-months.';
-- @rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_ensure_partitions(regclass, date, integer);

-- @file 20-0010-core.sql
-- @changeset ph20-0110-file-object
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
-- @rollback DROP TABLE IF EXISTS ph20_tenant.file_object CASCADE;

-- @changeset ph20-0120-provisioning-template
CREATE TABLE ph20_tenant.provisioning_template (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  template_code          varchar(32)    NOT NULL,
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
  CONSTRAINT ck_provisioning_template_code CHECK (template_code ~ '^QM-[A-Z0-9]{2,12}$'),
  CONSTRAINT ck_provisioning_template_version CHECK (version_no >= 1),
  CONSTRAINT ck_provisioning_template_status CHECK (status IN ('DRAFT', 'ACTIVE', 'RETIRED')),
  CONSTRAINT ck_provisioning_template_isolation CHECK (default_isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_provisioning_template_profile CHECK (deployment_profile IN ('HT-A', 'HT-B')),
  CONSTRAINT ck_provisioning_template_json CHECK (jsonb_typeof(default_quota) = 'object' AND jsonb_typeof(step_plan) = 'array' AND jsonb_typeof(default_settings) = 'object' AND jsonb_typeof(org_seed) = 'array'),
  CONSTRAINT ck_provisioning_template_active CHECK (status <> 'ACTIVE' OR activated_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_provisioning_template_active ON ph20_tenant.provisioning_template (template_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_provisioning_template_touch BEFORE UPDATE ON ph20_tenant.provisioning_template FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_provisioning_template_immutable BEFORE UPDATE ON ph20_tenant.provisioning_template FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('template_code', 'version_no');
CREATE TRIGGER tg_provisioning_template_frozen BEFORE UPDATE ON ph20_tenant.provisioning_template FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_frozen('status', 'ACTIVE,RETIRED', 'default_quota', 'default_modules', 'step_plan', 'default_settings', 'org_seed', 'default_isolation_mode', 'deployment_profile');
CALL ph20_tenant.p_enable_rls('ph20_tenant.provisioning_template', 'PLAT');
COMMENT ON TABLE ph20_tenant.provisioning_template IS 'EN-20-09 Mẫu khởi tạo có phiên bản (FR-20-015): hạn mức mặc định, phân hệ bật mặc định, kế hoạch bước saga, cài đặt tỉnh mặc định, tổ chức cấp tỉnh nạp ở bước S13. Dữ liệu nền tảng (`tenant_id = PLATFORM`), chỉ PLATFORM đọc, ghi. Mẫu ACTIVE bất biến, đổi bằng phiên bản mới.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.template_code IS 'Mã mẫu, dạng `QM-*` (hồ sơ quy mô), ví dụ `QM-VUA`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.version_no IS 'Số phiên bản của mẫu, bắt đầu từ 1.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.name IS 'Tên mẫu.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.description IS 'Mô tả, cơ sở giả định quy mô.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.status IS 'Trạng thái mẫu: `DRAFT`, `ACTIVE`, `RETIRED` (mỗi mã một bản ACTIVE).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_isolation_mode IS 'Chế độ cách ly mặc định: `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.deployment_profile IS 'Hồ sơ triển khai: `HT-A` hoặc `HT-B`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_quota IS 'Hạn mức mặc định, đối tượng {QuotaResource: giá trị số}.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_modules IS 'Mã phân hệ bật mặc định (`PH-nn`), dùng ở bước S15_MODULES.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.step_plan IS 'Danh sách bước saga và tùy chọn (bước bắt buộc, điều kiện bỏ qua).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.default_settings IS 'Cài đặt tỉnh mặc định sao chép vào `tenant_settings`.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.org_seed IS 'Danh sách tổ chức cấp tỉnh nạp ở bước S13_ORG_SEED.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.activated_at IS 'Thời điểm chuyển ACTIVE.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.retired_at IS 'Thời điểm chuyển RETIRED.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.provisioning_template.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.provisioning_template.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.provisioning_template CASCADE;

-- @changeset ph20-0130-tenant
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
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant CASCADE;

-- @changeset ph20-0140-organization
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
-- @rollback DROP TABLE IF EXISTS ph20_tenant.organization CASCADE;

-- @changeset ph20-0150-tenant-contact
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
  CONSTRAINT ck_tenant_contact_contact_type CHECK (contact_type IN ('PRIMARY', 'TECHNICAL', 'SECURITY', 'BILLING')),
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
COMMENT ON TABLE ph20_tenant.tenant_contact IS 'EN-20-03 Đầu mối của tenant (FR-20-005): người liên hệ chính, kỹ thuật, an ninh, thanh toán; nhận thông báo đổi trạng thái, bảo trì, ngưỡng hạn mức. Có dữ liệu cá nhân (họ tên, thư điện tử, điện thoại), phân loại HC theo DD-09.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_contact.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_contact.contact_type IS 'Loại đầu mối: `PRIMARY`, `TECHNICAL`, `SECURITY`, `BILLING`.';
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
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_contact CASCADE;

-- @changeset ph20-0160-tenant-contract
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
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_contract CASCADE;

-- @file 20-0020-module.sql
-- @changeset ph20-0170-platform-module
CREATE TABLE ph20_tenant.platform_module (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8)     NOT NULL,
  name                   varchar(255)   NOT NULL,
  wave                   smallint       NOT NULL,
  du_code                varchar(32)    NOT NULL,
  is_core                boolean        NOT NULL DEFAULT false,
  default_enabled        boolean        NOT NULL DEFAULT false,
  status                 varchar(12)    NOT NULL DEFAULT 'AVAILABLE',
  display_order          smallint       NOT NULL DEFAULT 0,
  description            varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_platform_module PRIMARY KEY (id),
  CONSTRAINT uq_platform_module_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_platform_module_code UNIQUE (module_code),
  CONSTRAINT ck_platform_module_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_platform_module_code CHECK (module_code ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_platform_module_wave CHECK (wave BETWEEN 1 AND 3),
  CONSTRAINT ck_platform_module_status CHECK (status IN ('AVAILABLE', 'PLANNED', 'DEPRECATED'))
);
CREATE TRIGGER tg_platform_module_touch BEFORE UPDATE ON ph20_tenant.platform_module FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_platform_module_immutable BEFORE UPDATE ON ph20_tenant.platform_module FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('module_code');
CALL ph20_tenant.p_enable_rls('ph20_tenant.platform_module', 'PLATR');
COMMENT ON TABLE ph20_tenant.platform_module IS 'EN-20-18 Phân hệ của nền tảng (FR-20-033): danh mục 20 phân hệ PH-01…20 với đợt, đơn vị triển khai, cờ lõi. Dữ liệu nền tảng, mọi tenant đọc được để dựng menu (FR-20-037), chỉ PLATFORM ghi.';
COMMENT ON COLUMN ph20_tenant.platform_module.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.platform_module.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.platform_module.module_code IS 'Mã phân hệ `PH-nn`, bất biến.';
COMMENT ON COLUMN ph20_tenant.platform_module.name IS 'Tên phân hệ.';
COMMENT ON COLUMN ph20_tenant.platform_module.wave IS 'Đợt phát triển: 1 (MVP), 2 hoặc 3 (D02-01 §8.3).';
COMMENT ON COLUMN ph20_tenant.platform_module.du_code IS 'Đơn vị triển khai (DU), ví dụ `dh-platform`.';
COMMENT ON COLUMN ph20_tenant.platform_module.is_core IS 'Phân hệ lõi, luôn bật, không tắt được cho tenant.';
COMMENT ON COLUMN ph20_tenant.platform_module.default_enabled IS 'Bật mặc định khi khởi tạo tenant theo mẫu.';
COMMENT ON COLUMN ph20_tenant.platform_module.status IS 'Trạng thái trong danh mục: `AVAILABLE`, `PLANNED`, `DEPRECATED`.';
COMMENT ON COLUMN ph20_tenant.platform_module.display_order IS 'Thứ tự hiển thị.';
COMMENT ON COLUMN ph20_tenant.platform_module.description IS 'Mô tả ngắn.';
COMMENT ON COLUMN ph20_tenant.platform_module.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.platform_module.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.platform_module.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.platform_module.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.platform_module.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.platform_module CASCADE;

-- @changeset ph20-0180-module-dependency
CREATE TABLE ph20_tenant.module_dependency (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8)     NOT NULL,
  depends_on_code        varchar(8)     NOT NULL,
  dependency_type        varchar(10)    NOT NULL DEFAULT 'REQUIRED',
  reason                 varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_module_dependency PRIMARY KEY (id),
  CONSTRAINT uq_module_dependency_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_module_dependency_pair UNIQUE (module_code, depends_on_code),
  CONSTRAINT ck_module_dependency_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_module_dependency_dependency_type CHECK (dependency_type IN ('REQUIRED', 'OPTIONAL')),
  CONSTRAINT ck_module_dependency_not_self CHECK (module_code <> depends_on_code),
  CONSTRAINT fk_module_dependency_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code),
  CONSTRAINT fk_module_dependency_depends_on FOREIGN KEY (depends_on_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE INDEX ix_module_dependency_depends_on ON ph20_tenant.module_dependency (depends_on_code);
CREATE TRIGGER tg_module_dependency_touch BEFORE UPDATE ON ph20_tenant.module_dependency FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.module_dependency', 'PLATR');
COMMENT ON TABLE ph20_tenant.module_dependency IS 'EN-20-19 Phụ thuộc phân hệ (FR-20-033): ma trận phân hệ cần phân hệ nào, bắt buộc hay tùy chọn; chặn bật phân hệ khi thiếu phân hệ bắt buộc. Chu trình do dịch vụ kiểm khi lưu.';
COMMENT ON COLUMN ph20_tenant.module_dependency.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.module_dependency.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.module_dependency.module_code IS 'Phân hệ phụ thuộc.';
COMMENT ON COLUMN ph20_tenant.module_dependency.depends_on_code IS 'Phân hệ được cần.';
COMMENT ON COLUMN ph20_tenant.module_dependency.dependency_type IS 'Loại: `REQUIRED` hoặc `OPTIONAL`.';
COMMENT ON COLUMN ph20_tenant.module_dependency.reason IS 'Lý do phụ thuộc.';
COMMENT ON COLUMN ph20_tenant.module_dependency.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.module_dependency.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.module_dependency.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.module_dependency.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.module_dependency.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.module_dependency CASCADE;

-- @changeset ph20-0190-tenant-module
CREATE TABLE ph20_tenant.tenant_module (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8)     NOT NULL,
  state                  varchar(10)    NOT NULL DEFAULT 'DISABLED',
  enabled_at             timestamptz,
  disabled_at            timestamptz,
  state_reason           varchar(500),
  config                 jsonb          NOT NULL DEFAULT '{}',
  last_report_at         timestamptz,
  last_event_id          uuid,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_module PRIMARY KEY (id),
  CONSTRAINT uq_tenant_module_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_module_module UNIQUE (tenant_id, module_code),
  CONSTRAINT ck_tenant_module_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_module_state CHECK (state IN ('DISABLED', 'ENABLING', 'ENABLED', 'DISABLING', 'SUSPENDED', 'FAILED')),
  CONSTRAINT ck_tenant_module_config CHECK (jsonb_typeof(config) = 'object'),
  CONSTRAINT ck_tenant_module_enabled CHECK (state NOT IN ('ENABLED') OR enabled_at IS NOT NULL),
  CONSTRAINT fk_tenant_module_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_module_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE INDEX ix_tenant_module_state ON ph20_tenant.tenant_module (tenant_id, state);
CREATE TRIGGER tg_tenant_module_touch BEFORE UPDATE ON ph20_tenant.tenant_module FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_module', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_module IS 'EN-20-20 Phân hệ theo tenant (FR-20-034, 035, 037): trạng thái bật, tắt, tạm ngừng của từng phân hệ đối với tenant; phân hệ báo kết quả bất đồng bộ qua EVT-20-07, 08. Nguồn cho menu và ERR-20-103.';
COMMENT ON COLUMN ph20_tenant.tenant_module.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_module.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_module.module_code IS 'Phân hệ.';
COMMENT ON COLUMN ph20_tenant.tenant_module.state IS 'Trạng thái: `DISABLED`, `ENABLING`, `ENABLED`, `DISABLING`, `SUSPENDED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant_module.enabled_at IS 'Lần bật gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_module.disabled_at IS 'Lần tắt gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_module.state_reason IS 'Lý do đổi trạng thái (bắt buộc khi tắt, tạm ngừng).';
COMMENT ON COLUMN ph20_tenant.tenant_module.config IS 'Cấu hình riêng của phân hệ cho tenant (ví dụ PH-17 `enabled`).';
COMMENT ON COLUMN ph20_tenant.tenant_module.last_report_at IS 'Lần phân hệ báo tiến độ gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_module.last_event_id IS 'Sự kiện outbox gần nhất đã phát.';
COMMENT ON COLUMN ph20_tenant.tenant_module.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_module.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_module.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_module.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_module.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_module CASCADE;

-- @changeset ph20-0200-tenant-feature-flag
CREATE TABLE ph20_tenant.tenant_feature_flag (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8),
  flag_code              varchar(64)    NOT NULL,
  enabled                boolean        NOT NULL DEFAULT false,
  rollout_percent        numeric(5,2)   NOT NULL DEFAULT 100,
  valid_from             timestamptz,
  valid_to               timestamptz,
  description            varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_feature_flag PRIMARY KEY (id),
  CONSTRAINT uq_tenant_feature_flag_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_feature_flag_flag UNIQUE (tenant_id, flag_code),
  CONSTRAINT ck_tenant_feature_flag_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_feature_flag_code CHECK (flag_code ~ '^[a-z0-9][a-z0-9._-]{2,63}$'),
  CONSTRAINT ck_tenant_feature_flag_rollout CHECK (rollout_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_tenant_feature_flag_valid CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from),
  CONSTRAINT fk_tenant_feature_flag_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_feature_flag_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE TRIGGER tg_tenant_feature_flag_touch BEFORE UPDATE ON ph20_tenant.tenant_feature_flag FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_feature_flag', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_feature_flag IS 'EN-20-21 Cờ tính năng theo tenant (FR-20-036): bật, tắt tính năng cụ thể, có tỷ lệ phát hành và thời hạn. Mã cờ dùng cột `flag_code`.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.module_code IS 'Phân hệ chứa tính năng (nếu có).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.flag_code IS 'Mã cờ tính năng, dạng `{phân-hệ}.{tính-năng}`.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.enabled IS 'Cờ đang bật.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.rollout_percent IS 'Tỷ lệ phát hành dần, 0 đến 100.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.valid_from IS 'Cờ có hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.valid_to IS 'Cờ hết hiệu lực.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.description IS 'Mô tả.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_feature_flag CASCADE;

-- @file 20-0030-config.sql
-- @changeset ph20-0210-tenant-platform-config
CREATE TABLE ph20_tenant.tenant_platform_config (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  realm_code             varchar(64)    NOT NULL,
  api_host               varchar(253),
  api_path_prefix        varchar(64),
  deployment_profile     varchar(4)     NOT NULL DEFAULT 'HT-A',
  dr_zone                varchar(32),
  kafka_prefix           varchar(16)    NOT NULL,
  bucket_prefix          varchar(32)    NOT NULL,
  db_route_ref           varchar(128),
  cluster_ref            varchar(64),
  config_version_no      integer        NOT NULL DEFAULT 0,
  last_commit_sha        char(40),
  drift_status           varchar(12)    NOT NULL DEFAULT 'UNKNOWN',
  last_applied_at        timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_platform_config PRIMARY KEY (id),
  CONSTRAINT uq_tenant_platform_config_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_platform_config_tenant UNIQUE (tenant_id),
  CONSTRAINT uq_tenant_platform_config_realm UNIQUE (realm_code),
  CONSTRAINT ck_tenant_platform_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_platform_config_drift_status CHECK (drift_status IN ('IN_SYNC', 'DRIFTED', 'RECONCILING', 'UNKNOWN')),
  CONSTRAINT ck_tenant_platform_config_profile CHECK (deployment_profile IN ('HT-A', 'HT-B')),
  CONSTRAINT ck_tenant_platform_config_sha CHECK (last_commit_sha IS NULL OR last_commit_sha ~ '^[0-9a-f]{40}$'),
  CONSTRAINT ck_tenant_platform_config_host CHECK (api_host IS NULL OR api_host ~ '^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$'),
  CONSTRAINT ck_tenant_platform_config_version CHECK (config_version_no >= 0),
  CONSTRAINT fk_tenant_platform_config_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_tenant_platform_config_api_host ON ph20_tenant.tenant_platform_config (api_host) WHERE api_host IS NOT NULL;
CREATE TRIGGER tg_tenant_platform_config_touch BEFORE UPDATE ON ph20_tenant.tenant_platform_config FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_platform_config', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_platform_config IS 'EN-20-05 Cấu hình nền tảng của tenant (FR-20-019): realm, host và tiền tố API công bố, hồ sơ triển khai, vùng DR, tham chiếu cụm riêng. Một dòng mỗi tenant; cấu hình mong muốn nằm ở kho Git `dh-tenant-config`, bảng giữ bản chiếu và trạng thái áp.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.realm_code IS 'Realm Keycloak của tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.api_host IS 'Host API công bố của tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.api_path_prefix IS 'Tiền tố đường dẫn API công bố.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.deployment_profile IS 'Hồ sơ triển khai: `HT-A` hoặc `HT-B`.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.dr_zone IS 'Vùng khôi phục thảm họa.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.kafka_prefix IS 'Tiền tố topic Kafka (mã tenant viết thường, `t68.`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.bucket_prefix IS 'Tiền tố bucket kho đối tượng (`dh-t68-`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.db_route_ref IS 'Tham chiếu bảng định tuyến CSDL khi `DEDICATED_DB`; không chứa chuỗi kết nối.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.cluster_ref IS 'Tên cụm riêng khi `DEDICATED_CLUSTER`.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.config_version_no IS 'Phiên bản cấu hình hiện hành (khớp `tenant_config_version`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.last_commit_sha IS 'Mã commit Git đã áp gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.drift_status IS 'Trạng thái đồng bộ: `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN`.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.last_applied_at IS 'Lần áp cấu hình xuống gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_platform_config CASCADE;

-- @changeset ph20-0220-tenant-settings
CREATE TABLE ph20_tenant.tenant_settings (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  display_name           varchar(255)   NOT NULL,
  logo_file_id           uuid,
  it_owner_org_id        uuid,
  hotline                varchar(20),
  support_email          varchar(254),
  idle_session_minutes   smallint       NOT NULL DEFAULT 30,
  mfa_required           boolean        NOT NULL DEFAULT true,
  password_min_length    smallint       NOT NULL DEFAULT 12,
  lockout_attempts       smallint       NOT NULL DEFAULT 5,
  ip_allowlist           text[]         NOT NULL DEFAULT '{}',
  notify_emails          text[]         NOT NULL DEFAULT '{}',
  locale                 varchar(10)    NOT NULL DEFAULT 'vi-VN',
  timezone               varchar(40)    NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  extra                  jsonb          NOT NULL DEFAULT '{}',
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_settings PRIMARY KEY (id),
  CONSTRAINT uq_tenant_settings_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_settings_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_settings_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_settings_idle CHECK (idle_session_minutes BETWEEN 5 AND 480),
  CONSTRAINT ck_tenant_settings_password CHECK (password_min_length BETWEEN 8 AND 128),
  CONSTRAINT ck_tenant_settings_lockout CHECK (lockout_attempts BETWEEN 3 AND 20),
  CONSTRAINT ck_tenant_settings_extra CHECK (jsonb_typeof(extra) = 'object'),
  CONSTRAINT ck_tenant_settings_email CHECK (support_email IS NULL OR support_email ~ '^[^@[:space:]]+@[^@[:space:]]+$'),
  CONSTRAINT fk_tenant_settings_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_settings_logo FOREIGN KEY (logo_file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id),
  CONSTRAINT fk_tenant_settings_it_owner FOREIGN KEY (it_owner_org_id, tenant_id) REFERENCES ph20_tenant.organization (id, tenant_id)
);
CREATE INDEX ix_tenant_settings_fk_logo ON ph20_tenant.tenant_settings (tenant_id, logo_file_id);
CREATE INDEX ix_tenant_settings_fk_it_owner ON ph20_tenant.tenant_settings (tenant_id, it_owner_org_id);
CREATE TRIGGER tg_tenant_settings_touch BEFORE UPDATE ON ph20_tenant.tenant_settings FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_settings', 'OWN');
COMMENT ON TABLE ph20_tenant.tenant_settings IS 'EN-20-06 Cài đặt tỉnh do quản trị tỉnh tự quản (FR-20-018): thông tin hiển thị, chủ quản CNTT, an toàn đăng nhập trong giới hạn nền tảng, địa chỉ nhận thông báo. Một dòng mỗi tenant; giới hạn nền tảng kiểm ở dịch vụ.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.display_name IS 'Tên hiển thị của tỉnh trên cổng, thư thông báo.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.logo_file_id IS 'Tệp logo.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.it_owner_org_id IS 'Tổ chức chủ quản CNTT của tỉnh.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.hotline IS 'Đường dây hỗ trợ.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.support_email IS 'Thư điện tử hỗ trợ.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.idle_session_minutes IS 'Thời gian rảnh tối đa của phiên, phút.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.mfa_required IS 'Bắt buộc xác thực nhiều lớp.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.password_min_length IS 'Độ dài tối thiểu của mật khẩu.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.lockout_attempts IS 'Số lần đăng nhập sai trước khi khóa.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.ip_allowlist IS 'Dải IP được phép đăng nhập quản trị (rỗng là không giới hạn).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.notify_emails IS 'Địa chỉ nhận thông báo phát hành, bảo trì.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.locale IS 'Ngôn ngữ mặc định.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.timezone IS 'Múi giờ hiển thị.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.extra IS 'Cài đặt mở rộng theo hồ sơ triển khai.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_settings CASCADE;

-- @changeset ph20-0230-tenant-config-version
CREATE TABLE ph20_tenant.tenant_config_version (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  version_no             integer        NOT NULL,
  config_scope           varchar(16)    NOT NULL DEFAULT 'ALL',
  git_commit_sha         char(40)       NOT NULL,
  commit_message         varchar(500),
  content_hash           char(64)       NOT NULL,
  snapshot               jsonb          NOT NULL,
  change_source          varchar(12)    NOT NULL DEFAULT 'API',
  reason                 varchar(500),
  apply_status           varchar(10)    NOT NULL DEFAULT 'PENDING',
  applied_at             timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_config_version PRIMARY KEY (id),
  CONSTRAINT uq_tenant_config_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_config_version_version UNIQUE (tenant_id, version_no),
  CONSTRAINT ck_tenant_config_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_config_version_version CHECK (version_no >= 1),
  CONSTRAINT ck_tenant_config_version_config_scope CHECK (config_scope IN ('PLATFORM_CONFIG', 'SETTINGS', 'QUOTA', 'MODULES', 'ALL')),
  CONSTRAINT ck_tenant_config_version_change_source CHECK (change_source IN ('API', 'SAGA', 'RESTORE', 'DRIFT_FIX')),
  CONSTRAINT ck_tenant_config_version_apply_status CHECK (apply_status IN ('PENDING', 'APPLIED', 'FAILED')),
  CONSTRAINT ck_tenant_config_version_sha CHECK (git_commit_sha ~ '^[0-9a-f]{40}$'),
  CONSTRAINT ck_tenant_config_version_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_tenant_config_version_snapshot CHECK (jsonb_typeof(snapshot) = 'object'),
  CONSTRAINT fk_tenant_config_version_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE TRIGGER tg_tenant_config_version_touch BEFORE UPDATE ON ph20_tenant.tenant_config_version FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_tenant_config_version_immutable BEFORE UPDATE ON ph20_tenant.tenant_config_version FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('version_no', 'git_commit_sha', 'content_hash', 'snapshot', 'config_scope', 'change_source');
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_config_version', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_config_version IS 'EN-20-07 Phiên bản cấu hình (FR-20-020, 021): bản chiếu mỗi commit cấu hình ở kho Git, giữ ảnh chụp để so sánh và khôi phục. Chỉ thêm; cột nội dung bất biến, chỉ trạng thái áp được cập nhật.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.version_no IS 'Số phiên bản tăng dần trong tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.config_scope IS 'Phạm vi: `PLATFORM_CONFIG`, `SETTINGS`, `QUOTA`, `MODULES`, `ALL`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.git_commit_sha IS 'Mã commit trong kho `dh-tenant-config`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.commit_message IS 'Nội dung commit.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.content_hash IS 'Mã băm SHA-256 của nội dung cấu hình.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.snapshot IS 'Ảnh chụp cấu hình (không chứa bí mật), dùng so sánh và khôi phục.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.change_source IS 'Nguồn thay đổi: `API`, `SAGA`, `RESTORE`, `DRIFT_FIX`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.reason IS 'Lý do, mã phiếu.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.apply_status IS 'Trạng thái áp xuống: `PENDING`, `APPLIED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.applied_at IS 'Thời điểm áp xong.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_config_version CASCADE;

-- @changeset ph20-0240-config-drift
CREATE TABLE ph20_tenant.config_drift (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  status                 varchar(12)    NOT NULL DEFAULT 'DRIFTED',
  detected_at            timestamptz    NOT NULL DEFAULT now(),
  detected_by            varchar(12)    NOT NULL DEFAULT 'PERIODIC',
  desired_version_no     integer,
  desired_hash           char(64),
  actual_hash            char(64),
  differences            jsonb          NOT NULL DEFAULT '[]',
  resolution             varchar(10),
  resolved_by            varchar(64),
  resolved_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_config_drift PRIMARY KEY (id),
  CONSTRAINT uq_config_drift_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_config_drift_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_config_drift_status CHECK (status IN ('IN_SYNC', 'DRIFTED', 'RECONCILING', 'UNKNOWN')),
  CONSTRAINT ck_config_drift_resolution CHECK (resolution IN ('RECONCILED', 'ACCEPTED', 'IGNORED')),
  CONSTRAINT ck_config_drift_detected_by CHECK (detected_by IN ('PERIODIC', 'ARGOCD')),
  CONSTRAINT ck_config_drift_diff CHECK (jsonb_typeof(differences) = 'array'),
  CONSTRAINT ck_config_drift_resolved CHECK (resolution IS NULL OR (resolved_at IS NOT NULL AND resolved_by IS NOT NULL)),
  CONSTRAINT fk_config_drift_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_config_drift_open ON ph20_tenant.config_drift (tenant_id) WHERE status IN ('DRIFTED', 'RECONCILING');
CREATE INDEX ix_config_drift_detected ON ph20_tenant.config_drift (tenant_id, detected_at DESC);
CREATE TRIGGER tg_config_drift_touch BEFORE UPDATE ON ph20_tenant.config_drift FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.config_drift', 'CTL');
COMMENT ON TABLE ph20_tenant.config_drift IS 'EN-20-08 Lệch cấu hình (FR-20-022): kết quả đối chiếu định kỳ giữa kho Git và thực tế; mỗi tenant tối đa một lệch đang mở. Số liệu so sánh chỉ là băm và danh sách khác biệt, không chứa giá trị bí mật.';
COMMENT ON COLUMN ph20_tenant.config_drift.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.config_drift.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.config_drift.status IS 'Trạng thái: `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN`.';
COMMENT ON COLUMN ph20_tenant.config_drift.detected_at IS 'Thời điểm phát hiện.';
COMMENT ON COLUMN ph20_tenant.config_drift.detected_by IS 'Nguồn phát hiện: `PERIODIC` hoặc `ARGOCD`.';
COMMENT ON COLUMN ph20_tenant.config_drift.desired_version_no IS 'Phiên bản cấu hình mong muốn.';
COMMENT ON COLUMN ph20_tenant.config_drift.desired_hash IS 'Băm cấu hình mong muốn.';
COMMENT ON COLUMN ph20_tenant.config_drift.actual_hash IS 'Băm cấu hình thực tế.';
COMMENT ON COLUMN ph20_tenant.config_drift.differences IS 'Danh sách khác biệt (đường dẫn, loại), không chứa giá trị bí mật.';
COMMENT ON COLUMN ph20_tenant.config_drift.resolution IS 'Cách xử lý: `RECONCILED`, `ACCEPTED`, `IGNORED`.';
COMMENT ON COLUMN ph20_tenant.config_drift.resolved_by IS 'Người xử lý.';
COMMENT ON COLUMN ph20_tenant.config_drift.resolved_at IS 'Thời điểm xử lý xong.';
COMMENT ON COLUMN ph20_tenant.config_drift.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.config_drift.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.config_drift.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.config_drift.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.config_drift.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.config_drift CASCADE;

-- @changeset ph20-0250-cross-tenant-policy
CREATE TABLE ph20_tenant.cross_tenant_policy (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  allow_write            boolean        NOT NULL DEFAULT false,
  preapproved_roles      text[]         NOT NULL DEFAULT '{}',
  max_hours              smallint       NOT NULL DEFAULT 4,
  require_reason         boolean        NOT NULL DEFAULT true,
  notify_emails          text[]         NOT NULL DEFAULT '{}',
  notify_contact_types   text[]         NOT NULL DEFAULT '{SECURITY}',
  effective_from         timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_cross_tenant_policy PRIMARY KEY (id),
  CONSTRAINT uq_cross_tenant_policy_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_cross_tenant_policy_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_cross_tenant_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_cross_tenant_policy_hours CHECK (max_hours BETWEEN 1 AND 24),
  CONSTRAINT fk_cross_tenant_policy_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE TRIGGER tg_cross_tenant_policy_touch BEFORE UPDATE ON ph20_tenant.cross_tenant_policy FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.cross_tenant_policy', 'OWN');
COMMENT ON TABLE ph20_tenant.cross_tenant_policy IS 'EN-20-29 Chính sách tiếp nhận truy cập liên tenant của tỉnh (FR-20-023): có cho phép ghi hay không, chấp thuận trước, thời hạn tối đa, người nhận thông báo. PH-12 đọc khi cấp quyền liên tenant (FR-00-012); thời hạn không vượt trần nền tảng `20.cross-tenant.max-hours` (kiểm ở dịch vụ).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.allow_write IS 'Cho phép phiên liên tenant ghi (mặc định chỉ đọc).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.preapproved_roles IS 'Vai trò nền tảng được chấp thuận trước, không cần phê duyệt từng lần.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.max_hours IS 'Thời hạn tối đa một phiên liên tenant, giờ.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.require_reason IS 'Bắt buộc nêu lý do và mã phiếu.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.notify_emails IS 'Địa chỉ nhận thông báo mỗi lần có truy cập liên tenant.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.notify_contact_types IS 'Loại đầu mối nhận thông báo.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.effective_from IS 'Hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.cross_tenant_policy CASCADE;

-- @file 20-0040-provision.sql
-- @changeset ph20-0260-provisioning-run
CREATE TABLE ph20_tenant.provisioning_run (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  run_kind               varchar(16)    NOT NULL DEFAULT 'INITIAL',
  status                 varchar(12)    NOT NULL DEFAULT 'PENDING',
  template_id            uuid,
  isolation_mode         varchar(24)    NOT NULL DEFAULT 'SHARED',
  attempt                integer        NOT NULL DEFAULT 1,
  current_step_code      varchar(20),
  started_at             timestamptz,
  finished_at            timestamptz,
  duration_seconds       integer,
  error_code             varchar(16),
  error_message          varchar(1000),
  requested_by           varchar(64)    NOT NULL,
  trace_id               char(32),
  kpi_reported_at        timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_provisioning_run PRIMARY KEY (id),
  CONSTRAINT uq_provisioning_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_provisioning_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_provisioning_run_status CHECK (status IN ('PENDING', 'RUNNING', 'WAITING', 'FAILED', 'COMPENSATING', 'COMPENSATED', 'SUCCEEDED', 'CANCELLED')),
  CONSTRAINT ck_provisioning_run_run_kind CHECK (run_kind IN ('INITIAL', 'SUPPLEMENT', 'ISOLATION_CHANGE')),
  CONSTRAINT ck_provisioning_run_isolation_mode CHECK (isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_provisioning_run_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_provisioning_run_step CHECK (current_step_code IS NULL OR current_step_code IN ('S01_RECORD', 'S02_CONFIG_REPO', 'S03_REALM', 'S04_SECRETS', 'S05_BUCKETS', 'S06_EVENTING', 'S07_DATABASE', 'S08_OBSERVABILITY', 'S09_GATEWAY', 'S10_INTEGRATION', 'S11_SEED_RDM', 'S12_SEED_MDM', 'S13_ORG_SEED', 'S14_KPI', 'S15_MODULES', 'S16_SMOKE', 'S17_ACTIVATE')),
  CONSTRAINT ck_provisioning_run_finished CHECK (status NOT IN ('SUCCEEDED', 'COMPENSATED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_provisioning_run_duration CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  CONSTRAINT ck_provisioning_run_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT fk_provisioning_run_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_provisioning_run_template FOREIGN KEY (template_id) REFERENCES ph20_tenant.provisioning_template (id)
);
CREATE UNIQUE INDEX uq_provisioning_run_active ON ph20_tenant.provisioning_run (tenant_id) WHERE status IN ('RUNNING', 'WAITING', 'COMPENSATING');
CREATE INDEX ix_provisioning_run_tenant_started ON ph20_tenant.provisioning_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_provisioning_run_touch BEFORE UPDATE ON ph20_tenant.provisioning_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_provisioning_run_immutable BEFORE UPDATE ON ph20_tenant.provisioning_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('run_kind');
CREATE TRIGGER tg_provisioning_run_transition BEFORE UPDATE ON ph20_tenant.provisioning_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"PENDING": ["RUNNING", "CANCELLED"], "RUNNING": ["WAITING", "FAILED", "COMPENSATING", "SUCCEEDED", "CANCELLED"], "WAITING": ["RUNNING", "FAILED", "COMPENSATING"], "FAILED": ["RUNNING", "COMPENSATING", "CANCELLED"], "COMPENSATING": ["COMPENSATED", "FAILED"]}');
CALL ph20_tenant.p_enable_rls('ph20_tenant.provisioning_run', 'CTL');
COMMENT ON TABLE ph20_tenant.provisioning_run IS 'EN-20-10 Lần chạy saga (FR-20-008…011, 016, 017): khởi tạo ban đầu, khởi tạo bổ sung, đổi chế độ cách ly. Mỗi tenant tối đa một lần chạy đang hoạt động (RUNNING, WAITING, COMPENSATING). Saga điều phối trên PostgreSQL (ADR-200), có khóa ShedLock ở dịch vụ.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.run_kind IS 'Loại lần chạy: `INITIAL`, `SUPPLEMENT`, `ISOLATION_CHANGE`.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.status IS 'Trạng thái: `PENDING`, `RUNNING`, `WAITING`, `FAILED`, `COMPENSATING`, `COMPENSATED`, `SUCCEEDED`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.template_id IS 'Phiên bản mẫu khởi tạo dùng cho lần chạy.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.isolation_mode IS 'Chế độ cách ly của lần chạy (quyết định bước S07).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.attempt IS 'Lần thử (tăng khi thử lại từ bước lỗi).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.current_step_code IS 'Bước đang chạy hoặc dừng ở lỗi.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.started_at IS 'Thời điểm bắt đầu.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.finished_at IS 'Thời điểm kết thúc.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.duration_seconds IS 'Thời gian khởi tạo, giây (KPI-12, FR-20-014).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.error_code IS 'Mã lỗi `ERR-20-*` khi thất bại.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.error_message IS 'Thông điệp lỗi đã che dữ liệu nhạy cảm.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.requested_by IS 'Người, hoặc tài khoản dịch vụ, khởi chạy.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.trace_id IS 'Mã vết phân tán (W3C).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.kpi_reported_at IS 'Thời điểm đẩy thời gian khởi tạo sang PH-16 (API-16-030).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.provisioning_run.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.provisioning_run.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.provisioning_run CASCADE;

-- @changeset ph20-0270-provisioning-step
CREATE TABLE ph20_tenant.provisioning_step (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  run_id                 uuid           NOT NULL,
  step_code              varchar(20)    NOT NULL,
  step_order             smallint       NOT NULL,
  status                 varchar(16)    NOT NULL DEFAULT 'PENDING',
  executor               varchar(16)    NOT NULL,
  is_async               boolean        NOT NULL DEFAULT false,
  attempt                integer        NOT NULL DEFAULT 1,
  idempotency_ref        varchar(64)    NOT NULL,
  started_at             timestamptz,
  reported_at            timestamptz,
  finished_at            timestamptz,
  timeout_at             timestamptz,
  error_code             varchar(16),
  error_message          varchar(1000),
  detail                 jsonb          NOT NULL DEFAULT '{}',
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_provisioning_step PRIMARY KEY (id),
  CONSTRAINT uq_provisioning_step_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_provisioning_step_step UNIQUE (run_id, step_code),
  CONSTRAINT ck_provisioning_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_provisioning_step_status CHECK (status IN ('PENDING', 'RUNNING', 'WAITING_REPORT', 'SUCCEEDED', 'FAILED', 'SKIPPED', 'COMPENSATING', 'COMPENSATED')),
  CONSTRAINT ck_provisioning_step_code CHECK (step_code IN ('S01_RECORD', 'S02_CONFIG_REPO', 'S03_REALM', 'S04_SECRETS', 'S05_BUCKETS', 'S06_EVENTING', 'S07_DATABASE', 'S08_OBSERVABILITY', 'S09_GATEWAY', 'S10_INTEGRATION', 'S11_SEED_RDM', 'S12_SEED_MDM', 'S13_ORG_SEED', 'S14_KPI', 'S15_MODULES', 'S16_SMOKE', 'S17_ACTIVATE')),
  CONSTRAINT ck_provisioning_step_order CHECK (step_order BETWEEN 1 AND 17),
  CONSTRAINT ck_provisioning_step_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_provisioning_step_idem CHECK (idempotency_ref ~ '^[0-9a-f-]{36}:S[0-9]{2}_[A-Z_]+$'),
  CONSTRAINT ck_provisioning_step_detail CHECK (jsonb_typeof(detail) = 'object'),
  CONSTRAINT fk_provisioning_step_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_provisioning_step_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph20_tenant.provisioning_run (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_provisioning_step_waiting ON ph20_tenant.provisioning_step (timeout_at) WHERE status = 'WAITING_REPORT';
CREATE INDEX ix_provisioning_step_fk_run ON ph20_tenant.provisioning_step (tenant_id, run_id);
CREATE TRIGGER tg_provisioning_step_touch BEFORE UPDATE ON ph20_tenant.provisioning_step FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_provisioning_step_immutable BEFORE UPDATE ON ph20_tenant.provisioning_step FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('run_id', 'step_code', 'idempotency_ref');
CALL ph20_tenant.p_enable_rls('ph20_tenant.provisioning_step', 'CTL');
COMMENT ON TABLE ph20_tenant.provisioning_step IS 'EN-20-11 Bước saga (FR-20-009, 010, 011): sổ bước của một lần chạy, 17 mã bước `S01_RECORD`…`S17_ACTIVATE`; bước bất đồng bộ chờ phân hệ báo qua `:report`. Lũy đẳng theo `idempotency_ref = {runId}:{stepCode}`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.run_id IS 'Lần chạy chứa bước.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.step_code IS 'Mã bước `S01_RECORD`…`S17_ACTIVATE` (brief mục 4.1).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.step_order IS 'Thứ tự thực hiện, 1 đến 17.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.status IS 'Trạng thái: `PENDING`, `RUNNING`, `WAITING_REPORT`, `SUCCEEDED`, `FAILED`, `SKIPPED`, `COMPENSATING`, `COMPENSATED`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.executor IS 'Bên thực hiện, ví dụ `PH-12`, `PH-20`, `PH-10`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.is_async IS 'Bước chờ phân hệ báo kết quả bất đồng bộ (S06, S09, S10, S12, S15).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.attempt IS 'Số lần thử của bước.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.idempotency_ref IS 'Khóa lũy đẳng `{runId}:{stepCode}` gửi cho bên thực hiện.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.started_at IS 'Thời điểm bắt đầu.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.reported_at IS 'Thời điểm bên thực hiện báo kết quả.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.finished_at IS 'Thời điểm kết thúc.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.timeout_at IS 'Hạn chờ báo cáo (`20.provision.step-timeout-minutes`), quá hạn thì `FAILED`.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.error_code IS 'Mã lỗi.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.error_message IS 'Thông điệp lỗi đã che dữ liệu nhạy cảm.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.detail IS 'Chi tiết kết quả (tên tài nguyên đã tạo, không chứa bí mật), dùng cho bù trừ.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.provisioning_step.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.provisioning_step.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.provisioning_step CASCADE;

-- @changeset ph20-0280-smoke-test-result
CREATE TABLE ph20_tenant.smoke_test_result (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  run_id                 uuid           NOT NULL,
  check_code             varchar(24)    NOT NULL,
  result                 varchar(8)     NOT NULL,
  duration_ms            integer,
  detail                 jsonb          NOT NULL DEFAULT '{}',
  executed_at            timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_smoke_test_result PRIMARY KEY (id),
  CONSTRAINT uq_smoke_test_result_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_smoke_test_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_smoke_test_result_check_code CHECK (check_code IN ('LOGIN_ADMIN', 'API_SAMPLE', 'EVENT_SAMPLE', 'CROSS_TENANT_LEAK')),
  CONSTRAINT ck_smoke_test_result_result CHECK (result IN ('PASS', 'FAIL', 'SKIPPED')),
  CONSTRAINT ck_smoke_test_result_duration CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CONSTRAINT ck_smoke_test_result_detail CHECK (jsonb_typeof(detail) = 'object'),
  CONSTRAINT fk_smoke_test_result_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_smoke_test_result_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph20_tenant.provisioning_run (id, tenant_id)
);
CREATE INDEX ix_smoke_test_result_executed ON ph20_tenant.smoke_test_result (tenant_id, executed_at DESC);
CREATE INDEX ix_smoke_test_result_fk_run ON ph20_tenant.smoke_test_result (tenant_id, run_id);
CREATE TRIGGER tg_smoke_test_result_touch BEFORE UPDATE ON ph20_tenant.smoke_test_result FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_smoke_test_result_append_only BEFORE UPDATE OR DELETE ON ph20_tenant.smoke_test_result FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_append_only();
CALL ph20_tenant.p_enable_rls('ph20_tenant.smoke_test_result', 'CTL');
COMMENT ON TABLE ph20_tenant.smoke_test_result IS 'EN-20-12 Kết quả kiểm tra khói (FR-20-012): đăng nhập quản trị, gọi API mẫu, phát nhận sự kiện mẫu, một ca rò rỉ chéo tenant (bước S16). Chỉ thêm; tenant chưa qua kiểm tra khói không được `ACTIVE`.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.run_id IS 'Lần chạy saga.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.check_code IS 'Ca kiểm tra: `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK`.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.result IS 'Kết quả: `PASS`, `FAIL`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.duration_ms IS 'Thời gian chạy, mili giây.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.detail IS 'Chi tiết (mã trạng thái, thông điệp đã che).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.executed_at IS 'Thời điểm chạy.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.smoke_test_result.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.smoke_test_result CASCADE;

-- @file 20-0050-quota.sql
-- @changeset ph20-0290-tenant-quota
CREATE TABLE ph20_tenant.tenant_quota (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  limit_value            numeric(20,3)  NOT NULL,
  unit                   varchar(16)    NOT NULL,
  source                 varchar(10)    NOT NULL DEFAULT 'TEMPLATE',
  warn_percent           smallint       NOT NULL DEFAULT 80,
  effective_from         timestamptz    NOT NULL DEFAULT now(),
  push_status            varchar(8)     NOT NULL DEFAULT 'PENDING',
  pushed_at              timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_quota PRIMARY KEY (id),
  CONSTRAINT uq_tenant_quota_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_quota_resource UNIQUE (tenant_id, resource_code),
  CONSTRAINT ck_tenant_quota_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_quota_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_tenant_quota_limit CHECK (limit_value >= 0),
  CONSTRAINT ck_tenant_quota_source CHECK (source IN ('TEMPLATE', 'CONTRACT', 'OVERRIDE')),
  CONSTRAINT ck_tenant_quota_push_status CHECK (push_status IN ('PENDING', 'PUSHED', 'FAILED')),
  CONSTRAINT ck_tenant_quota_warn CHECK (warn_percent BETWEEN 1 AND 99),
  CONSTRAINT fk_tenant_quota_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE TRIGGER tg_tenant_quota_touch BEFORE UPDATE ON ph20_tenant.tenant_quota FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_quota', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_quota IS 'EN-20-13 Hạn mức hợp đồng của tenant (FR-20-026, 027): mỗi tenant một dòng cho mỗi tài nguyên (12 loại). PH-20 giữ giá trị và đẩy xuống nơi thực thi (APISIX, Kafka, PH-04…), không tự thực thi (ADR-204).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.resource_code IS 'Tài nguyên: 12 giá trị `QuotaResource`.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.limit_value IS 'Giá trị hạn mức hợp đồng.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.unit IS 'Đơn vị: `rps`, `MB/s`, `GB`, `user`, `vCPU`…';
COMMENT ON COLUMN ph20_tenant.tenant_quota.source IS 'Nguồn giá trị: `TEMPLATE`, `CONTRACT`, `OVERRIDE`.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.warn_percent IS 'Ngưỡng cảnh báo, phần trăm (`20.quota.warn-percent`).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.effective_from IS 'Hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.push_status IS 'Trạng thái đẩy xuống nơi thực thi: `PENDING`, `PUSHED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.pushed_at IS 'Lần đẩy thành công gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_quota CASCADE;

-- @changeset ph20-0300-quota-change-request
CREATE TABLE ph20_tenant.quota_change_request (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  current_value          numeric(20,3)  NOT NULL,
  requested_value        numeric(20,3)  NOT NULL,
  current_usage          numeric(20,3),
  status                 varchar(16)    NOT NULL DEFAULT 'DRAFT',
  reason                 varchar(1000)  NOT NULL,
  ticket_code            varchar(32)    NOT NULL,
  requested_by           varchar(64)    NOT NULL,
  requested_at           timestamptz    NOT NULL DEFAULT now(),
  approved_by            varchar(64),
  approved_at            timestamptz,
  decision_note          varchar(1000),
  executed_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_change_request PRIMARY KEY (id),
  CONSTRAINT uq_quota_change_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_quota_change_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_change_request_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_quota_change_request_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'EXECUTING', 'DONE', 'CANCELLED')),
  CONSTRAINT ck_quota_change_request_values CHECK (current_value >= 0 AND requested_value >= 0 AND requested_value <> current_value),
  CONSTRAINT ck_quota_change_request_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_quota_change_request_approved CHECK (status NOT IN ('APPROVED', 'EXECUTING', 'DONE') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT fk_quota_change_request_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_quota_change_request_open ON ph20_tenant.quota_change_request (tenant_id, resource_code) WHERE status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING');
CREATE INDEX ix_quota_change_request_tenant_status ON ph20_tenant.quota_change_request (tenant_id, status);
CREATE TRIGGER tg_quota_change_request_touch BEFORE UPDATE ON ph20_tenant.quota_change_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_quota_change_request_transition BEFORE UPDATE ON ph20_tenant.quota_change_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "REJECTED", "CANCELLED", "DRAFT"], "APPROVED": ["EXECUTING", "CANCELLED"], "EXECUTING": ["DONE", "APPROVED"]}');
CREATE TRIGGER tg_quota_change_request_immutable BEFORE UPDATE ON ph20_tenant.quota_change_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('resource_code', 'requested_by', 'requested_value');
CALL ph20_tenant.p_enable_rls('ph20_tenant.quota_change_request', 'CTL');
COMMENT ON TABLE ph20_tenant.quota_change_request IS 'EN-20-14 Đề nghị đổi hạn mức (FR-20-026, 027): có duyệt bốn mắt, người duyệt khác người đề nghị; hạ dưới mức đang dùng cần lý do và duyệt. Duyệt xong thì cập nhật `tenant_quota` và phát EVT-20-05.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.resource_code IS 'Tài nguyên đề nghị đổi.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.current_value IS 'Giá trị hạn mức hiện tại khi đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.requested_value IS 'Giá trị đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.current_usage IS 'Mức đang dùng khi đề nghị (để phát hiện hạ dưới mức dùng).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.status IS 'Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.reason IS 'Lý do đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.ticket_code IS 'Mã phiếu đề nghị (SEC-85).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.requested_by IS 'Người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.requested_at IS 'Thời điểm đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.approved_by IS 'Người duyệt, khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.approved_at IS 'Thời điểm duyệt.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.decision_note IS 'Ghi chú quyết định, lý do từ chối.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.executed_at IS 'Thời điểm áp dụng.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.quota_change_request CASCADE;

-- @changeset ph20-0310-quota-override
CREATE TABLE ph20_tenant.quota_override (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  override_value         numeric(20,3)  NOT NULL,
  valid_from             timestamptz    NOT NULL,
  valid_to               timestamptz    NOT NULL,
  status                 varchar(8)     NOT NULL DEFAULT 'ACTIVE',
  reason                 varchar(1000)  NOT NULL,
  ticket_code            varchar(32)    NOT NULL,
  requested_by           varchar(64)    NOT NULL,
  approved_by            varchar(64)    NOT NULL,
  revoked_at             timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_override PRIMARY KEY (id),
  CONSTRAINT uq_quota_override_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_quota_override_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_override_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_quota_override_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_quota_override_value CHECK (override_value >= 0),
  CONSTRAINT ck_quota_override_valid CHECK (valid_to > valid_from),
  CONSTRAINT ck_quota_override_four_eyes CHECK (approved_by <> requested_by),
  CONSTRAINT ck_quota_override_revoked CHECK (status <> 'REVOKED' OR revoked_at IS NOT NULL),
  CONSTRAINT fk_quota_override_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE INDEX ix_quota_override_active ON ph20_tenant.quota_override (tenant_id, resource_code, valid_to) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_quota_override_touch BEFORE UPDATE ON ph20_tenant.quota_override FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.quota_override', 'CTL');
COMMENT ON TABLE ph20_tenant.quota_override IS 'EN-20-15 Ghi đè hạn mức tạm thời có thời hạn (FR-20-032): nâng tạm trần cho một tài nguyên trong khoảng ngày, tự hết hạn; thời hạn tối đa `20.quota.override-max-days` kiểm ở dịch vụ. Người phê duyệt khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_override.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.quota_override.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.quota_override.resource_code IS 'Tài nguyên được ghi đè.';
COMMENT ON COLUMN ph20_tenant.quota_override.override_value IS 'Giá trị hạn mức tạm thời.';
COMMENT ON COLUMN ph20_tenant.quota_override.valid_from IS 'Hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.quota_override.valid_to IS 'Hết hiệu lực, sau `valid_from`.';
COMMENT ON COLUMN ph20_tenant.quota_override.status IS 'Trạng thái: `ACTIVE`, `EXPIRED`, `REVOKED`.';
COMMENT ON COLUMN ph20_tenant.quota_override.reason IS 'Lý do ghi đè.';
COMMENT ON COLUMN ph20_tenant.quota_override.ticket_code IS 'Mã phiếu.';
COMMENT ON COLUMN ph20_tenant.quota_override.requested_by IS 'Người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_override.approved_by IS 'Người duyệt, khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_override.revoked_at IS 'Thời điểm thu hồi sớm.';
COMMENT ON COLUMN ph20_tenant.quota_override.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.quota_override.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.quota_override.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.quota_override.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.quota_override.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.quota_override CASCADE;

-- @changeset ph20-0320-usage-snapshot
CREATE TABLE ph20_tenant.usage_snapshot (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  captured_at            timestamptz    NOT NULL,
  used_value             numeric(20,3)  NOT NULL,
  limit_value            numeric(20,3),
  percent_used           numeric(7,2),
  source                 varchar(14)    NOT NULL DEFAULT 'MIMIR',
  is_estimate            boolean        NOT NULL DEFAULT false,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_usage_snapshot PRIMARY KEY (id, captured_at),
  CONSTRAINT uq_usage_snapshot_point UNIQUE (tenant_id, resource_code, captured_at),
  CONSTRAINT ck_usage_snapshot_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_usage_snapshot_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_usage_snapshot_source CHECK (source IN ('MIMIR', 'APISIX', 'KAFKA', 'OBJECT_STORE', 'DATABASE', 'IAM', 'CATALOG', 'RUNTIME', 'OTHER')),
  CONSTRAINT ck_usage_snapshot_used CHECK (used_value >= 0),
  CONSTRAINT ck_usage_snapshot_limit CHECK (limit_value IS NULL OR limit_value >= 0),
  CONSTRAINT fk_usage_snapshot_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
) PARTITION BY RANGE (captured_at);
CREATE INDEX ix_usage_snapshot_tenant_time ON ph20_tenant.usage_snapshot (tenant_id, captured_at DESC);
CREATE TRIGGER tg_usage_snapshot_touch BEFORE UPDATE ON ph20_tenant.usage_snapshot FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.usage_snapshot', 'CTL');
CREATE TABLE ph20_tenant.usage_snapshot_default PARTITION OF ph20_tenant.usage_snapshot DEFAULT;
CALL ph20_tenant.p_ensure_partitions('ph20_tenant.usage_snapshot', date '2026-11-01', 6);
COMMENT ON TABLE ph20_tenant.usage_snapshot IS 'EN-20-16 Ảnh chụp sử dụng tài nguyên (FR-20-028, 030): mỗi giờ mỗi tài nguyên một dòng lấy từ nơi thực thi (Mimir, APISIX, Kafka, kho đối tượng, CSDL…). Phân vùng theo tháng trên `captured_at`, giữ `20.usage.retention-months` tháng.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.resource_code IS 'Tài nguyên: 12 giá trị `QuotaResource`.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.captured_at IS 'Thời điểm chụp (đầu giờ), khóa phân vùng.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.used_value IS 'Mức đang dùng.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.limit_value IS 'Hạn mức hiệu lực tại thời điểm chụp (gồm ghi đè).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.percent_used IS 'Phần trăm đã dùng so với hạn mức.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.source IS 'Nơi lấy số liệu: `MIMIR`, `APISIX`, `KAFKA`, `OBJECT_STORE`, `DATABASE`, `IAM`, `CATALOG`, `RUNTIME`, `OTHER`.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.is_estimate IS 'Số liệu ước tính khi nguồn tạm không đọc được.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.usage_snapshot CASCADE;

-- @changeset ph20-0330-quota-alert
CREATE TABLE ph20_tenant.quota_alert (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  alert_level            varchar(10)    NOT NULL,
  state                  varchar(12)    NOT NULL DEFAULT 'OPEN',
  used_value             numeric(20,3)  NOT NULL,
  limit_value            numeric(20,3)  NOT NULL,
  percent_used           numeric(7,2)   NOT NULL,
  raised_at              timestamptz    NOT NULL DEFAULT now(),
  acknowledged_by        varchar(64),
  acknowledged_at        timestamptz,
  resolved_at            timestamptz,
  event_id               uuid,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_alert PRIMARY KEY (id),
  CONSTRAINT uq_quota_alert_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_quota_alert_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_alert_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_quota_alert_alert_level CHECK (alert_level IN ('WARN_80', 'LIMIT_100')),
  CONSTRAINT ck_quota_alert_state CHECK (state IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED')),
  CONSTRAINT ck_quota_alert_limit CHECK (limit_value > 0),
  CONSTRAINT ck_quota_alert_resolved CHECK (state <> 'RESOLVED' OR resolved_at IS NOT NULL),
  CONSTRAINT fk_quota_alert_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_quota_alert_open ON ph20_tenant.quota_alert (tenant_id, resource_code, alert_level) WHERE state IN ('OPEN', 'ACKNOWLEDGED');
CREATE INDEX ix_quota_alert_raised ON ph20_tenant.quota_alert (tenant_id, raised_at DESC);
CREATE TRIGGER tg_quota_alert_touch BEFORE UPDATE ON ph20_tenant.quota_alert FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.quota_alert', 'CTL');
COMMENT ON TABLE ph20_tenant.quota_alert IS 'EN-20-17 Cảnh báo hạn mức (FR-20-029): chạm 80% (`WARN_80`) hoặc 100% (`LIMIT_100`), phát EVT-20-06 cho PH-13, PH-18; mỗi (tenant, tài nguyên, mức) tối đa một cảnh báo đang mở.';
COMMENT ON COLUMN ph20_tenant.quota_alert.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.quota_alert.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.quota_alert.resource_code IS 'Tài nguyên.';
COMMENT ON COLUMN ph20_tenant.quota_alert.alert_level IS 'Mức: `WARN_80` hoặc `LIMIT_100`.';
COMMENT ON COLUMN ph20_tenant.quota_alert.state IS 'Trạng thái: `OPEN`, `ACKNOWLEDGED`, `RESOLVED`.';
COMMENT ON COLUMN ph20_tenant.quota_alert.used_value IS 'Mức dùng khi phát cảnh báo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.limit_value IS 'Hạn mức hiệu lực khi phát cảnh báo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.percent_used IS 'Phần trăm đã dùng.';
COMMENT ON COLUMN ph20_tenant.quota_alert.raised_at IS 'Thời điểm phát.';
COMMENT ON COLUMN ph20_tenant.quota_alert.acknowledged_by IS 'Người xác nhận đã xem.';
COMMENT ON COLUMN ph20_tenant.quota_alert.acknowledged_at IS 'Thời điểm xác nhận.';
COMMENT ON COLUMN ph20_tenant.quota_alert.resolved_at IS 'Thời điểm hết cảnh báo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.event_id IS 'Sự kiện outbox EVT-20-06 đã phát.';
COMMENT ON COLUMN ph20_tenant.quota_alert.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.quota_alert.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.quota_alert.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.quota_alert.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.quota_alert CASCADE;

-- @changeset ph20-0340-usage-report
CREATE TABLE ph20_tenant.usage_report (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  report_scope           varchar(8)     NOT NULL DEFAULT 'TENANT',
  period_from            date           NOT NULL,
  period_to              date           NOT NULL,
  granularity            varchar(8)     NOT NULL DEFAULT 'MONTH',
  format                 varchar(4)     NOT NULL DEFAULT 'XLSX',
  status                 varchar(12)    NOT NULL DEFAULT 'REQUESTED',
  file_id                uuid,
  row_count              integer,
  requested_by           varchar(64)    NOT NULL,
  expires_at             timestamptz,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_usage_report PRIMARY KEY (id),
  CONSTRAINT uq_usage_report_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_usage_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_usage_report_report_scope CHECK (report_scope IN ('TENANT', 'PLATFORM')),
  CONSTRAINT ck_usage_report_format CHECK (format IN ('XLSX', 'CSV', 'PDF')),
  CONSTRAINT ck_usage_report_status CHECK (status IN ('REQUESTED', 'GENERATING', 'READY', 'FAILED', 'EXPIRED')),
  CONSTRAINT ck_usage_report_period CHECK (period_to >= period_from),
  CONSTRAINT ck_usage_report_granularity CHECK (granularity IN ('HOUR', 'DAY', 'MONTH')),
  CONSTRAINT ck_usage_report_scope_tenant CHECK ((report_scope = 'PLATFORM') = (tenant_id = 'PLATFORM')),
  CONSTRAINT ck_usage_report_ready CHECK (status <> 'READY' OR file_id IS NOT NULL),
  CONSTRAINT fk_usage_report_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_usage_report_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_usage_report_tenant_period ON ph20_tenant.usage_report (tenant_id, period_from DESC);
CREATE INDEX ix_usage_report_fk_file ON ph20_tenant.usage_report (tenant_id, file_id);
CREATE TRIGGER tg_usage_report_touch BEFORE UPDATE ON ph20_tenant.usage_report FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.usage_report', 'CTL');
COMMENT ON TABLE ph20_tenant.usage_report IS 'EN-20-37 Báo cáo sử dụng (FR-20-031): báo cáo theo kỳ cho một tenant hoặc toàn nền tảng (`tenant_id = PLATFORM`), xuất `XLSX`, `CSV`, `PDF`; tệp lưu ở `file_object`, hết hạn tự dọn.';
COMMENT ON COLUMN ph20_tenant.usage_report.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.usage_report.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.usage_report.report_scope IS 'Phạm vi: `TENANT` hoặc `PLATFORM`.';
COMMENT ON COLUMN ph20_tenant.usage_report.period_from IS 'Kỳ báo cáo từ ngày.';
COMMENT ON COLUMN ph20_tenant.usage_report.period_to IS 'Kỳ báo cáo đến ngày, không nhỏ hơn `period_from`.';
COMMENT ON COLUMN ph20_tenant.usage_report.granularity IS 'Độ mịn: `HOUR`, `DAY`, `MONTH`.';
COMMENT ON COLUMN ph20_tenant.usage_report.format IS 'Định dạng: `XLSX`, `CSV`, `PDF`.';
COMMENT ON COLUMN ph20_tenant.usage_report.status IS 'Trạng thái: `REQUESTED`, `GENERATING`, `READY`, `FAILED`, `EXPIRED`.';
COMMENT ON COLUMN ph20_tenant.usage_report.file_id IS 'Tệp kết quả.';
COMMENT ON COLUMN ph20_tenant.usage_report.row_count IS 'Số dòng của báo cáo.';
COMMENT ON COLUMN ph20_tenant.usage_report.requested_by IS 'Người yêu cầu.';
COMMENT ON COLUMN ph20_tenant.usage_report.expires_at IS 'Hạn tải tệp.';
COMMENT ON COLUMN ph20_tenant.usage_report.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.usage_report.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.usage_report.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.usage_report.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.usage_report.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.usage_report.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.usage_report CASCADE;

-- @file 20-0060-lifecycle.sql
-- @changeset ph20-0350-lifecycle-request
CREATE TABLE ph20_tenant.lifecycle_request (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  request_type           varchar(20)    NOT NULL,
  status                 varchar(16)    NOT NULL DEFAULT 'DRAFT',
  suspend_reason         varchar(24),
  essential_api_allowed  boolean        NOT NULL DEFAULT false,
  reason                 varchar(1000)  NOT NULL,
  ticket_code            varchar(32)    NOT NULL,
  requested_by           varchar(64)    NOT NULL,
  requested_at           timestamptz    NOT NULL DEFAULT now(),
  approved_by            varchar(64),
  approved_at            timestamptz,
  decision_note          varchar(1000),
  scheduled_at           timestamptz,
  cooling_until          timestamptz,
  target_isolation_mode  varchar(24),
  quota_change_id        uuid,
  executed_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_lifecycle_request PRIMARY KEY (id),
  CONSTRAINT uq_lifecycle_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_lifecycle_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_lifecycle_request_request_type CHECK (request_type IN ('SUSPEND', 'RESUME', 'TERMINATE', 'ISOLATION_CHANGE', 'QUOTA_DECREASE')),
  CONSTRAINT ck_lifecycle_request_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'EXECUTING', 'DONE', 'CANCELLED')),
  CONSTRAINT ck_lifecycle_request_suspend_reason CHECK (suspend_reason IN ('MANAGEMENT_DECISION', 'SECURITY_INCIDENT', 'CONTRACT_EXPIRED', 'TENANT_REQUEST', 'OTHER')),
  CONSTRAINT ck_lifecycle_request_target_isolation CHECK (target_isolation_mode IS NULL OR target_isolation_mode IN ('SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')),
  CONSTRAINT ck_lifecycle_request_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_lifecycle_request_suspend CHECK (request_type <> 'SUSPEND' OR suspend_reason IS NOT NULL),
  CONSTRAINT ck_lifecycle_request_isolation CHECK (request_type <> 'ISOLATION_CHANGE' OR target_isolation_mode IS NOT NULL),
  CONSTRAINT ck_lifecycle_request_quota CHECK (request_type <> 'QUOTA_DECREASE' OR quota_change_id IS NOT NULL),
  CONSTRAINT ck_lifecycle_request_approved CHECK (request_type NOT IN ('TERMINATE', 'ISOLATION_CHANGE', 'QUOTA_DECREASE') OR status NOT IN ('APPROVED', 'EXECUTING', 'DONE') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_lifecycle_request_done CHECK (status <> 'DONE' OR executed_at IS NOT NULL),
  CONSTRAINT fk_lifecycle_request_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_lifecycle_request_quota_change FOREIGN KEY (quota_change_id, tenant_id) REFERENCES ph20_tenant.quota_change_request (id, tenant_id)
);
CREATE UNIQUE INDEX uq_lifecycle_request_open ON ph20_tenant.lifecycle_request (tenant_id, request_type) WHERE status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING');
CREATE INDEX ix_lifecycle_request_tenant_status ON ph20_tenant.lifecycle_request (tenant_id, status);
CREATE INDEX ix_lifecycle_request_fk_quota_change ON ph20_tenant.lifecycle_request (tenant_id, quota_change_id);
CREATE TRIGGER tg_lifecycle_request_touch BEFORE UPDATE ON ph20_tenant.lifecycle_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_lifecycle_request_transition BEFORE UPDATE ON ph20_tenant.lifecycle_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "REJECTED", "CANCELLED", "DRAFT"], "APPROVED": ["EXECUTING", "CANCELLED"], "EXECUTING": ["DONE", "APPROVED"]}');
CREATE TRIGGER tg_lifecycle_request_immutable BEFORE UPDATE ON ph20_tenant.lifecycle_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('request_type', 'requested_by');
CALL ph20_tenant.p_enable_rls('ph20_tenant.lifecycle_request', 'CTL');
COMMENT ON TABLE ph20_tenant.lifecycle_request IS 'EN-20-22 Đề nghị vòng đời có duyệt (FR-20-038…042): tạm ngừng, khôi phục, chấm dứt, đổi chế độ cách ly, hạ hạn mức. Chấm dứt, đổi cách ly, hạ hạn mức cần duyệt bốn mắt (người duyệt khác người đề nghị); mỗi (tenant, loại) tối đa một đề nghị đang mở. Mọi đề nghị có lý do và mã phiếu (SEC-85).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.request_type IS 'Loại: `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.status IS 'Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.suspend_reason IS 'Lý do tạm ngừng: `MANAGEMENT_DECISION`, `SECURITY_INCIDENT`, `CONTRACT_EXPIRED`, `TENANT_REQUEST`, `OTHER`; bắt buộc với `SUSPEND`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.essential_api_allowed IS 'Cho phép API thiết yếu hoạt động khi tạm ngừng (`20.suspend.essential-api-allowed`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.reason IS 'Lý do đề nghị (văn bản).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.ticket_code IS 'Mã phiếu, căn cứ quyết định.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.requested_by IS 'Người đề nghị.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.requested_at IS 'Thời điểm đề nghị.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.approved_by IS 'Người duyệt, khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.approved_at IS 'Thời điểm duyệt.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.decision_note IS 'Ghi chú quyết định, lý do từ chối.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.scheduled_at IS 'Thời điểm dự kiến thực hiện.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.cooling_until IS 'Hết thời gian chờ trước khi chấm dứt (`20.terminate.cooling-days`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.target_isolation_mode IS 'Chế độ cách ly đích khi `ISOLATION_CHANGE`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.quota_change_id IS 'Đề nghị đổi hạn mức liên quan khi `QUOTA_DECREASE`.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.executed_at IS 'Thời điểm thực hiện xong.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.lifecycle_request.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.lifecycle_request CASCADE;

-- @changeset ph20-0360-tenant-status-history
CREATE TABLE ph20_tenant.tenant_status_history (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  from_status            varchar(16),
  to_status              varchar(16)    NOT NULL,
  reason                 varchar(1000),
  ticket_code            varchar(32),
  request_id             uuid,
  run_id                 uuid,
  changed_by             varchar(64)    NOT NULL,
  changed_at             timestamptz    NOT NULL DEFAULT now(),
  trace_id               char(32),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_status_history PRIMARY KEY (id),
  CONSTRAINT uq_tenant_status_history_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_tenant_status_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_status_history_from_status CHECK (from_status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'MERGED', 'DECOMMISSIONED', 'FAILED')),
  CONSTRAINT ck_tenant_status_history_to_status CHECK (to_status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'MERGED', 'DECOMMISSIONED', 'FAILED')),
  CONSTRAINT ck_tenant_status_history_changed CHECK (from_status IS NULL OR from_status <> to_status),
  CONSTRAINT ck_tenant_status_history_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT fk_tenant_status_history_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_status_history_request FOREIGN KEY (request_id, tenant_id) REFERENCES ph20_tenant.lifecycle_request (id, tenant_id),
  CONSTRAINT fk_tenant_status_history_run FOREIGN KEY (run_id, tenant_id) REFERENCES ph20_tenant.provisioning_run (id, tenant_id)
);
CREATE INDEX ix_tenant_status_history_tenant_changed ON ph20_tenant.tenant_status_history (tenant_id, changed_at DESC);
CREATE INDEX ix_tenant_status_history_fk_request ON ph20_tenant.tenant_status_history (tenant_id, request_id);
CREATE INDEX ix_tenant_status_history_fk_run ON ph20_tenant.tenant_status_history (tenant_id, run_id);
CREATE TRIGGER tg_tenant_status_history_touch BEFORE UPDATE ON ph20_tenant.tenant_status_history FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_tenant_status_history_append_only BEFORE UPDATE OR DELETE ON ph20_tenant.tenant_status_history FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_append_only();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_status_history', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_status_history IS 'EN-20-23 Sự kiện vòng đời, lịch sử trạng thái tenant (FR-20-043): mỗi lần đổi `tenant.status` ghi một dòng kèm lý do, mã phiếu, đề nghị hoặc lần chạy saga liên quan. Chỉ thêm. Nhật ký kiểm toán chuỗi băm của tenant do PH-13 giữ; bảng này phục vụ hiển thị nhanh và đối chiếu.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.from_status IS 'Trạng thái trước (rỗng với lần khai báo đầu).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.to_status IS 'Trạng thái sau.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.reason IS 'Lý do.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.ticket_code IS 'Mã phiếu.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.request_id IS 'Đề nghị vòng đời liên quan.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.run_id IS 'Lần chạy saga liên quan.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.changed_by IS 'Người hoặc tài khoản dịch vụ thực hiện.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.changed_at IS 'Thời điểm đổi.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.trace_id IS 'Mã vết phân tán.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_status_history.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_status_history CASCADE;

-- @changeset ph20-0370-data-export-package
CREATE TABLE ph20_tenant.data_export_package (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  request_id             uuid,
  status                 varchar(12)    NOT NULL DEFAULT 'REQUESTED',
  file_id                uuid,
  size_bytes             bigint,
  sha256                 char(64),
  item_count             integer        NOT NULL DEFAULT 0,
  ready_at               timestamptz,
  delivered_at           timestamptz,
  delivered_to           varchar(255),
  expires_at             timestamptz,
  requested_by           varchar(64)    NOT NULL,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_export_package PRIMARY KEY (id),
  CONSTRAINT uq_data_export_package_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_data_export_package_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_data_export_package_status CHECK (status IN ('REQUESTED', 'COLLECTING', 'READY', 'DELIVERED', 'EXPIRED', 'FAILED')),
  CONSTRAINT ck_data_export_package_size CHECK (size_bytes IS NULL OR size_bytes >= 0),
  CONSTRAINT ck_data_export_package_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_data_export_package_ready CHECK (status NOT IN ('READY', 'DELIVERED') OR (file_id IS NOT NULL AND sha256 IS NOT NULL)),
  CONSTRAINT ck_data_export_package_delivered CHECK (status <> 'DELIVERED' OR (delivered_at IS NOT NULL AND delivered_to IS NOT NULL)),
  CONSTRAINT ck_data_export_package_items CHECK (item_count >= 0),
  CONSTRAINT fk_data_export_package_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_data_export_package_request FOREIGN KEY (request_id, tenant_id) REFERENCES ph20_tenant.lifecycle_request (id, tenant_id),
  CONSTRAINT fk_data_export_package_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE UNIQUE INDEX uq_data_export_package_open ON ph20_tenant.data_export_package (tenant_id) WHERE status IN ('REQUESTED', 'COLLECTING');
CREATE INDEX ix_data_export_package_tenant_status ON ph20_tenant.data_export_package (tenant_id, status);
CREATE INDEX ix_data_export_package_fk_request ON ph20_tenant.data_export_package (tenant_id, request_id);
CREATE INDEX ix_data_export_package_fk_file ON ph20_tenant.data_export_package (tenant_id, file_id);
CREATE TRIGGER tg_data_export_package_touch BEFORE UPDATE ON ph20_tenant.data_export_package FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.data_export_package', 'CTL');
COMMENT ON TABLE ph20_tenant.data_export_package IS 'EN-20-24 Gói bàn giao dữ liệu tenant (FR-20-041): gói xuất khi chấm dứt, gồm các mục theo phân hệ; giữ `20.export.retention-days` ngày. Phát EVT-20-16 khi sẵn sàng.';
COMMENT ON COLUMN ph20_tenant.data_export_package.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.data_export_package.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.data_export_package.request_id IS 'Đề nghị vòng đời chấm dứt phát sinh gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.status IS 'Trạng thái: `REQUESTED`, `COLLECTING`, `READY`, `DELIVERED`, `EXPIRED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.data_export_package.file_id IS 'Tệp gói ở `file_object`.';
COMMENT ON COLUMN ph20_tenant.data_export_package.size_bytes IS 'Kích thước gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.sha256 IS 'Mã băm SHA-256 của gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.item_count IS 'Số mục theo phân hệ.';
COMMENT ON COLUMN ph20_tenant.data_export_package.ready_at IS 'Thời điểm sẵn sàng.';
COMMENT ON COLUMN ph20_tenant.data_export_package.delivered_at IS 'Thời điểm bàn giao.';
COMMENT ON COLUMN ph20_tenant.data_export_package.delivered_to IS 'Người, đơn vị nhận bàn giao.';
COMMENT ON COLUMN ph20_tenant.data_export_package.expires_at IS 'Hạn giữ gói.';
COMMENT ON COLUMN ph20_tenant.data_export_package.requested_by IS 'Người yêu cầu.';
COMMENT ON COLUMN ph20_tenant.data_export_package.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.data_export_package.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.data_export_package.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.data_export_package.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.data_export_package.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.data_export_package.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.data_export_package CASCADE;

-- @changeset ph20-0380-data-export-item
CREATE TABLE ph20_tenant.data_export_item (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  package_id             uuid           NOT NULL,
  module_code            varchar(8)     NOT NULL,
  item_type              varchar(32)    NOT NULL,
  status                 varchar(12)    NOT NULL DEFAULT 'PENDING',
  row_count              bigint,
  size_bytes             bigint,
  sha256                 char(64),
  file_id                uuid,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_data_export_item PRIMARY KEY (id),
  CONSTRAINT uq_data_export_item_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_data_export_item_item UNIQUE (package_id, module_code, item_type),
  CONSTRAINT ck_data_export_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_data_export_item_status CHECK (status IN ('PENDING', 'COLLECTING', 'DONE', 'FAILED')),
  CONSTRAINT ck_data_export_item_counts CHECK ((row_count IS NULL OR row_count >= 0) AND (size_bytes IS NULL OR size_bytes >= 0)),
  CONSTRAINT ck_data_export_item_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_data_export_item_done CHECK (status <> 'DONE' OR sha256 IS NOT NULL),
  CONSTRAINT fk_data_export_item_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_data_export_item_package FOREIGN KEY (package_id, tenant_id) REFERENCES ph20_tenant.data_export_package (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_data_export_item_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code),
  CONSTRAINT fk_data_export_item_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_data_export_item_fk_package ON ph20_tenant.data_export_item (tenant_id, package_id);
CREATE INDEX ix_data_export_item_fk_file ON ph20_tenant.data_export_item (tenant_id, file_id);
CREATE TRIGGER tg_data_export_item_touch BEFORE UPDATE ON ph20_tenant.data_export_item FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.data_export_item', 'CTL');
COMMENT ON TABLE ph20_tenant.data_export_item IS 'EN-20-24 Mục của gói bàn giao (FR-20-041): dữ liệu một phân hệ đóng gói riêng, có số dòng và mã băm để đối chiếu.';
COMMENT ON COLUMN ph20_tenant.data_export_item.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.data_export_item.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.data_export_item.package_id IS 'Gói bàn giao chứa mục.';
COMMENT ON COLUMN ph20_tenant.data_export_item.module_code IS 'Phân hệ có dữ liệu.';
COMMENT ON COLUMN ph20_tenant.data_export_item.item_type IS 'Loại dữ liệu trong phân hệ (ví dụ `catalog`, `audit-chain`).';
COMMENT ON COLUMN ph20_tenant.data_export_item.status IS 'Trạng thái: `PENDING`, `COLLECTING`, `DONE`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.data_export_item.row_count IS 'Số bản ghi.';
COMMENT ON COLUMN ph20_tenant.data_export_item.size_bytes IS 'Kích thước.';
COMMENT ON COLUMN ph20_tenant.data_export_item.sha256 IS 'Mã băm SHA-256.';
COMMENT ON COLUMN ph20_tenant.data_export_item.file_id IS 'Tệp của mục.';
COMMENT ON COLUMN ph20_tenant.data_export_item.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.data_export_item.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.data_export_item.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.data_export_item.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.data_export_item.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.data_export_item.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.data_export_item CASCADE;

-- @file 20-0070-merge.sql
-- @changeset ph20-0390-merge-plan
CREATE TABLE ph20_tenant.merge_plan (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_code              varchar(48)    NOT NULL,
  name                   varchar(255)   NOT NULL,
  status                 varchar(20)    NOT NULL DEFAULT 'DRAFT',
  source_tenant_code     varchar(16)    NOT NULL,
  target_tenant_code     varchar(16)    NOT NULL,
  legal_basis            varchar(1000)  NOT NULL,
  ticket_code            varchar(32),
  effective_date         date,
  transition_months      smallint       NOT NULL DEFAULT 6,
  requested_by           varchar(64)    NOT NULL,
  approved_by            varchar(64),
  approved_at            timestamptz,
  dry_run_at             timestamptz,
  started_at             timestamptz,
  cutover_at             timestamptz,
  transition_until       date,
  completed_at           timestamptz,
  cancel_reason          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_plan PRIMARY KEY (id),
  CONSTRAINT uq_merge_plan_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_merge_plan_code UNIQUE (plan_code),
  CONSTRAINT ck_merge_plan_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_plan_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'DRY_RUN', 'TRANSFERRING', 'CONFLICT_REVIEW', 'IDENTITY_TRANSFER', 'CUTOVER', 'TRANSITION', 'COMPLETED', 'CANCELLED', 'FAILED')),
  CONSTRAINT ck_merge_plan_code CHECK (plan_code ~ '^[a-z0-9][a-z0-9-]{2,47}$'),
  CONSTRAINT ck_merge_plan_source CHECK (source_tenant_code ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_merge_plan_target CHECK (target_tenant_code ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_merge_plan_distinct CHECK (source_tenant_code <> target_tenant_code),
  CONSTRAINT ck_merge_plan_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_merge_plan_months CHECK (transition_months BETWEEN 1 AND 24),
  CONSTRAINT ck_merge_plan_approved CHECK (status NOT IN ('APPROVED', 'DRY_RUN', 'TRANSFERRING', 'CONFLICT_REVIEW', 'IDENTITY_TRANSFER', 'CUTOVER', 'TRANSITION', 'COMPLETED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_merge_plan_cutover CHECK (status NOT IN ('CUTOVER', 'TRANSITION', 'COMPLETED') OR cutover_at IS NOT NULL),
  CONSTRAINT ck_merge_plan_completed CHECK (status <> 'COMPLETED' OR completed_at IS NOT NULL),
  CONSTRAINT fk_merge_plan_source FOREIGN KEY (source_tenant_code) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_merge_plan_target FOREIGN KEY (target_tenant_code) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_merge_plan_open_source ON ph20_tenant.merge_plan (source_tenant_code) WHERE status NOT IN ('COMPLETED', 'CANCELLED');
CREATE INDEX ix_merge_plan_target ON ph20_tenant.merge_plan (target_tenant_code);
CREATE INDEX ix_merge_plan_status ON ph20_tenant.merge_plan (status);
CREATE TRIGGER tg_merge_plan_touch BEFORE UPDATE ON ph20_tenant.merge_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_merge_plan_transition BEFORE UPDATE ON ph20_tenant.merge_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "DRAFT", "CANCELLED"], "APPROVED": ["DRY_RUN", "TRANSFERRING", "CANCELLED"], "DRY_RUN": ["APPROVED", "TRANSFERRING", "FAILED", "CANCELLED"], "TRANSFERRING": ["CONFLICT_REVIEW", "IDENTITY_TRANSFER", "FAILED"], "CONFLICT_REVIEW": ["TRANSFERRING", "IDENTITY_TRANSFER", "CANCELLED"], "IDENTITY_TRANSFER": ["CUTOVER", "FAILED"], "CUTOVER": ["TRANSITION", "FAILED"], "TRANSITION": ["COMPLETED"], "FAILED": ["DRY_RUN", "TRANSFERRING", "CANCELLED"]}');
CREATE TRIGGER tg_merge_plan_immutable BEFORE UPDATE ON ph20_tenant.merge_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('plan_code', 'source_tenant_code', 'target_tenant_code');
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_plan', 'PLAT');
CREATE POLICY merge_party_read ON ph20_tenant.merge_plan FOR SELECT USING (current_setting('app.tenant_id', false) IN (source_tenant_code, target_tenant_code));
COMMENT ON TABLE ph20_tenant.merge_plan IS 'EN-20-25 Kế hoạch sáp nhập (FR-20-045, 051, 052): tenant nguồn sáp nhập vào tenant đích (D03-10 §5.4). Dữ liệu nền tảng; hai tenant bên tham gia đọc được kế hoạch của mình. Mỗi tenant nguồn tối đa một kế hoạch đang mở; duyệt bốn mắt (người duyệt khác người lập).';
COMMENT ON COLUMN ph20_tenant.merge_plan.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_plan.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_plan.plan_code IS 'Mã kế hoạch dạng `sap-nhap-t68-t69`, dùng ở route `/nen-tang/sap-nhap/{ma}`.';
COMMENT ON COLUMN ph20_tenant.merge_plan.name IS 'Tên kế hoạch.';
COMMENT ON COLUMN ph20_tenant.merge_plan.status IS 'Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `DRY_RUN`, `TRANSFERRING`, `CONFLICT_REVIEW`, `IDENTITY_TRANSFER`, `CUTOVER`, `TRANSITION`, `COMPLETED`, `CANCELLED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.merge_plan.source_tenant_code IS 'Tenant nguồn (sẽ sang `MERGED`).';
COMMENT ON COLUMN ph20_tenant.merge_plan.target_tenant_code IS 'Tenant đích nhận dữ liệu.';
COMMENT ON COLUMN ph20_tenant.merge_plan.legal_basis IS 'Căn cứ pháp lý của việc sắp xếp đơn vị hành chính.';
COMMENT ON COLUMN ph20_tenant.merge_plan.ticket_code IS 'Mã phiếu.';
COMMENT ON COLUMN ph20_tenant.merge_plan.effective_date IS 'Ngày hiệu lực của việc sắp xếp.';
COMMENT ON COLUMN ph20_tenant.merge_plan.transition_months IS 'Thời gian chuyển tiếp, tháng (`20.merge.transition-months`, trần `20.merge.transition-max-months` kiểm ở dịch vụ).';
COMMENT ON COLUMN ph20_tenant.merge_plan.requested_by IS 'Người lập kế hoạch.';
COMMENT ON COLUMN ph20_tenant.merge_plan.approved_by IS 'Người duyệt, khác người lập.';
COMMENT ON COLUMN ph20_tenant.merge_plan.approved_at IS 'Thời điểm duyệt.';
COMMENT ON COLUMN ph20_tenant.merge_plan.dry_run_at IS 'Lần chạy thử gần nhất.';
COMMENT ON COLUMN ph20_tenant.merge_plan.started_at IS 'Bắt đầu chuyển dữ liệu.';
COMMENT ON COLUMN ph20_tenant.merge_plan.cutover_at IS 'Thời điểm nguồn sang `MERGED`, bật chuyển tiếp.';
COMMENT ON COLUMN ph20_tenant.merge_plan.transition_until IS 'Hết thời gian chuyển tiếp.';
COMMENT ON COLUMN ph20_tenant.merge_plan.completed_at IS 'Thời điểm kết thúc.';
COMMENT ON COLUMN ph20_tenant.merge_plan.cancel_reason IS 'Lý do hủy hoặc thất bại.';
COMMENT ON COLUMN ph20_tenant.merge_plan.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_plan.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_plan.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_plan.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_plan.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.merge_plan CASCADE;

-- @changeset ph20-0400-merge-mapping
CREATE TABLE ph20_tenant.merge_mapping (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  mapping_type           varchar(16)    NOT NULL,
  source_ref             varchar(255)   NOT NULL,
  target_ref             varchar(255),
  status                 varchar(10)    NOT NULL DEFAULT 'PROPOSED',
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_mapping PRIMARY KEY (id),
  CONSTRAINT uq_merge_mapping_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_merge_mapping_source UNIQUE (plan_id, mapping_type, source_ref),
  CONSTRAINT ck_merge_mapping_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_mapping_mapping_type CHECK (mapping_type IN ('ORGANIZATION', 'MEMBER_SYSTEM', 'CATALOG_CODE', 'API_CONTEXT_PATH', 'USER', 'TOPIC')),
  CONSTRAINT ck_merge_mapping_status CHECK (status IN ('PROPOSED', 'CONFIRMED', 'CONFLICT', 'APPLIED')),
  CONSTRAINT ck_merge_mapping_target CHECK (status NOT IN ('CONFIRMED', 'APPLIED') OR target_ref IS NOT NULL),
  CONSTRAINT fk_merge_mapping_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.merge_plan (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_merge_mapping_fk_plan ON ph20_tenant.merge_mapping (tenant_id, plan_id);
CREATE TRIGGER tg_merge_mapping_touch BEFORE UPDATE ON ph20_tenant.merge_mapping FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_mapping', 'PLAT');
COMMENT ON TABLE ph20_tenant.merge_mapping IS 'EN-20-26 Ánh xạ sáp nhập (FR-20-046): bảng ánh xạ tổ chức, HTTT, mã danh mục địa phương, đường dẫn API, người dùng, topic từ nguồn sang đích; dùng cho chuyển dữ liệu và định tuyến chuyển tiếp ở APISIX.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_mapping.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.plan_id IS 'Kế hoạch sáp nhập.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.mapping_type IS 'Loại: `ORGANIZATION`, `MEMBER_SYSTEM`, `CATALOG_CODE`, `API_CONTEXT_PATH`, `USER`, `TOPIC`.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.source_ref IS 'Mã, đường dẫn hoặc định danh ở tenant nguồn.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.target_ref IS 'Mã, đường dẫn hoặc định danh tương ứng ở tenant đích.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.status IS 'Trạng thái: `PROPOSED`, `CONFIRMED`, `CONFLICT`, `APPLIED`.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_mapping.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_mapping.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_mapping.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.merge_mapping CASCADE;

-- @changeset ph20-0410-merge-participant-run
CREATE TABLE ph20_tenant.merge_participant_run (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  module_code            varchar(8)     NOT NULL,
  phase                  varchar(10)    NOT NULL,
  status                 varchar(10)    NOT NULL DEFAULT 'PENDING',
  attempt                integer        NOT NULL DEFAULT 1,
  exported_count         bigint         NOT NULL DEFAULT 0,
  imported_count         bigint         NOT NULL DEFAULT 0,
  verified_count         bigint         NOT NULL DEFAULT 0,
  conflict_count         bigint         NOT NULL DEFAULT 0,
  transfer_ref           varchar(64),
  started_at             timestamptz,
  finished_at            timestamptz,
  error_code             varchar(16),
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_participant_run PRIMARY KEY (id),
  CONSTRAINT uq_merge_participant_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_merge_participant_run_phase UNIQUE (plan_id, module_code, phase),
  CONSTRAINT ck_merge_participant_run_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_participant_run_phase CHECK (phase IN ('DRY_RUN', 'TRANSFER', 'IDENTITY', 'CUTOVER', 'VERIFY')),
  CONSTRAINT ck_merge_participant_run_status CHECK (status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED')),
  CONSTRAINT ck_merge_participant_run_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_merge_participant_run_counts CHECK (exported_count >= 0 AND imported_count >= 0 AND verified_count >= 0 AND conflict_count >= 0),
  CONSTRAINT fk_merge_participant_run_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.merge_plan (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_merge_participant_run_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE INDEX ix_merge_participant_run_fk_plan ON ph20_tenant.merge_participant_run (tenant_id, plan_id);
CREATE TRIGGER tg_merge_participant_run_touch BEFORE UPDATE ON ph20_tenant.merge_participant_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_participant_run', 'PLAT');
COMMENT ON TABLE ph20_tenant.merge_participant_run IS 'EN-20-27 Lần chuyển theo phân hệ (FR-20-047, 048): mỗi phân hệ có dữ liệu chạy từng pha (chạy thử, chuyển, định danh, chuyển tiếp, kiểm đếm) theo hợp đồng bên tham gia sáp nhập (ADR-202); PH-18 chạy công cụ chuyển, PH-20 điều phối.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.plan_id IS 'Kế hoạch sáp nhập.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.module_code IS 'Phân hệ tham gia.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.phase IS 'Pha: `DRY_RUN`, `TRANSFER`, `IDENTITY`, `CUTOVER`, `VERIFY`.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.status IS 'Trạng thái: `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.attempt IS 'Lần thử.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.exported_count IS 'Số bản ghi xuất từ nguồn.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.imported_count IS 'Số bản ghi nhập vào đích (giữ `id` gốc, ghi `origin_tenant_id`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.verified_count IS 'Số bản ghi đã kiểm đếm khớp.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.conflict_count IS 'Số xung đột phát sinh.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.transfer_ref IS 'Mã lệnh chuyển ở PH-18 (`/api/ops/v1/merge-transfers`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.started_at IS 'Bắt đầu.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.error_code IS 'Mã lỗi.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_participant_run.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.merge_participant_run CASCADE;

-- @changeset ph20-0420-merge-conflict
CREATE TABLE ph20_tenant.merge_conflict (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  participant_run_id     uuid,
  mapping_type           varchar(16)    NOT NULL,
  source_ref             varchar(255)   NOT NULL,
  target_ref             varchar(255),
  conflict_kind          varchar(16)    NOT NULL,
  state                  varchar(10)    NOT NULL DEFAULT 'OPEN',
  resolution             varchar(16),
  resolved_by            varchar(64),
  resolved_at            timestamptz,
  resolution_note        varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_conflict PRIMARY KEY (id),
  CONSTRAINT uq_merge_conflict_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_merge_conflict_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_merge_conflict_mapping_type CHECK (mapping_type IN ('ORGANIZATION', 'MEMBER_SYSTEM', 'CATALOG_CODE', 'API_CONTEXT_PATH', 'USER', 'TOPIC')),
  CONSTRAINT ck_merge_conflict_conflict_kind CHECK (conflict_kind IN ('DUPLICATE_CODE', 'DUPLICATE_PATH', 'DUPLICATE_USER', 'OTHER')),
  CONSTRAINT ck_merge_conflict_state CHECK (state IN ('OPEN', 'RESOLVED')),
  CONSTRAINT ck_merge_conflict_resolution CHECK (resolution IN ('KEEP_TARGET', 'KEEP_SOURCE', 'RENAME_SOURCE', 'MERGE_ITEMS', 'SKIP')),
  CONSTRAINT ck_merge_conflict_resolved CHECK (state <> 'RESOLVED' OR (resolution IS NOT NULL AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL)),
  CONSTRAINT fk_merge_conflict_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.merge_plan (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_merge_conflict_participant_run FOREIGN KEY (participant_run_id, tenant_id) REFERENCES ph20_tenant.merge_participant_run (id, tenant_id)
);
CREATE INDEX ix_merge_conflict_plan_state ON ph20_tenant.merge_conflict (plan_id, state);
CREATE INDEX ix_merge_conflict_fk_plan ON ph20_tenant.merge_conflict (tenant_id, plan_id);
CREATE INDEX ix_merge_conflict_fk_participant_run ON ph20_tenant.merge_conflict (tenant_id, participant_run_id);
CREATE TRIGGER tg_merge_conflict_touch BEFORE UPDATE ON ph20_tenant.merge_conflict FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.merge_conflict', 'PLAT');
COMMENT ON TABLE ph20_tenant.merge_conflict IS 'EN-20-28 Xung đột sáp nhập (FR-20-049): mã danh mục, đường dẫn API, người dùng trùng giữa nguồn và đích; cán bộ nghiệp vụ chọn cách xử lý (`ConflictResolution`).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.plan_id IS 'Kế hoạch sáp nhập.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.participant_run_id IS 'Lần chuyển phát hiện xung đột.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.mapping_type IS 'Loại đối tượng xung đột.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.source_ref IS 'Đối tượng ở nguồn.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.target_ref IS 'Đối tượng trùng ở đích.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.conflict_kind IS 'Dạng: `DUPLICATE_CODE`, `DUPLICATE_PATH`, `DUPLICATE_USER`, `OTHER`.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.state IS 'Trạng thái: `OPEN` hoặc `RESOLVED`.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolution IS 'Cách xử lý: `KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP`.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolved_by IS 'Người xử lý.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolved_at IS 'Thời điểm xử lý.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.resolution_note IS 'Ghi chú xử lý.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.merge_conflict.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.merge_conflict.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.merge_conflict CASCADE;

-- @file 20-0075-orgimport.sql
-- @changeset ph20-0430-org-import-job
CREATE TABLE ph20_tenant.org_import_job (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  file_id                uuid           NOT NULL,
  format                 varchar(4)     NOT NULL,
  mode                   varchar(12)    NOT NULL DEFAULT 'CREATE_ONLY',
  status                 varchar(10)    NOT NULL DEFAULT 'UPLOADED',
  total_rows             integer        NOT NULL DEFAULT 0,
  valid_rows             integer        NOT NULL DEFAULT 0,
  error_rows             integer        NOT NULL DEFAULT 0,
  applied_rows           integer        NOT NULL DEFAULT 0,
  preview_expires_at     timestamptz,
  applied_at             timestamptz,
  error_file_id          uuid,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_org_import_job PRIMARY KEY (id),
  CONSTRAINT uq_org_import_job_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_org_import_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_org_import_job_status CHECK (status IN ('UPLOADED', 'PREVIEWED', 'APPLYING', 'DONE', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_org_import_job_mode CHECK (mode IN ('CREATE_ONLY', 'UPSERT')),
  CONSTRAINT ck_org_import_job_format CHECK (format IN ('XLSX', 'CSV')),
  CONSTRAINT ck_org_import_job_rows CHECK (total_rows >= 0 AND valid_rows >= 0 AND error_rows >= 0 AND applied_rows >= 0 AND valid_rows + error_rows <= total_rows AND applied_rows <= valid_rows),
  CONSTRAINT ck_org_import_job_done CHECK (status <> 'DONE' OR applied_at IS NOT NULL),
  CONSTRAINT fk_org_import_job_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_org_import_job_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id),
  CONSTRAINT fk_org_import_job_error_file FOREIGN KEY (error_file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_org_import_job_status ON ph20_tenant.org_import_job (tenant_id, status);
CREATE INDEX ix_org_import_job_fk_file ON ph20_tenant.org_import_job (tenant_id, file_id);
CREATE INDEX ix_org_import_job_fk_error_file ON ph20_tenant.org_import_job (tenant_id, error_file_id);
CREATE TRIGGER tg_org_import_job_touch BEFORE UPDATE ON ph20_tenant.org_import_job FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.org_import_job', 'OWN');
COMMENT ON TABLE ph20_tenant.org_import_job IS 'EN-20-30 Lô nhập tổ chức (FR-20-055): tệp Excel hoặc CSV, xem trước kết quả kiểm tra rồi mới áp dụng; số dòng tối đa `20.org.import-max-rows` kiểm ở dịch vụ; bản xem trước hết hạn.';
COMMENT ON COLUMN ph20_tenant.org_import_job.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.org_import_job.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.org_import_job.file_id IS 'Tệp nhập ở `file_object`.';
COMMENT ON COLUMN ph20_tenant.org_import_job.format IS 'Định dạng tệp: `XLSX` hoặc `CSV`.';
COMMENT ON COLUMN ph20_tenant.org_import_job.mode IS 'Chế độ: `CREATE_ONLY` (chỉ thêm mới) hoặc `UPSERT` (thêm hoặc cập nhật).';
COMMENT ON COLUMN ph20_tenant.org_import_job.status IS 'Trạng thái: `UPLOADED`, `PREVIEWED`, `APPLYING`, `DONE`, `FAILED`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.org_import_job.total_rows IS 'Tổng số dòng dữ liệu.';
COMMENT ON COLUMN ph20_tenant.org_import_job.valid_rows IS 'Số dòng hợp lệ.';
COMMENT ON COLUMN ph20_tenant.org_import_job.error_rows IS 'Số dòng lỗi.';
COMMENT ON COLUMN ph20_tenant.org_import_job.applied_rows IS 'Số dòng đã áp dụng.';
COMMENT ON COLUMN ph20_tenant.org_import_job.preview_expires_at IS 'Hạn giữ bản xem trước.';
COMMENT ON COLUMN ph20_tenant.org_import_job.applied_at IS 'Thời điểm áp dụng xong.';
COMMENT ON COLUMN ph20_tenant.org_import_job.error_file_id IS 'Tệp liệt kê dòng lỗi để tải về sửa.';
COMMENT ON COLUMN ph20_tenant.org_import_job.error_message IS 'Thông điệp lỗi chung.';
COMMENT ON COLUMN ph20_tenant.org_import_job.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.org_import_job.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.org_import_job.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.org_import_job.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.org_import_job.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.org_import_job CASCADE;

-- @changeset ph20-0440-org-import-row
CREATE TABLE ph20_tenant.org_import_row (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  job_id                 uuid           NOT NULL,
  row_no                 integer        NOT NULL,
  org_code               varchar(64),
  action                 varchar(8)     NOT NULL DEFAULT 'SKIP',
  status                 varchar(8)     NOT NULL DEFAULT 'VALID',
  errors                 jsonb          NOT NULL DEFAULT '[]',
  data                   jsonb          NOT NULL,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_org_import_row PRIMARY KEY (id),
  CONSTRAINT uq_org_import_row_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_org_import_row_row UNIQUE (job_id, row_no),
  CONSTRAINT ck_org_import_row_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_org_import_row_action CHECK (action IN ('CREATE', 'UPDATE', 'SKIP', 'ERROR')),
  CONSTRAINT ck_org_import_row_status CHECK (status IN ('VALID', 'ERROR', 'APPLIED', 'SKIPPED')),
  CONSTRAINT ck_org_import_row_row CHECK (row_no >= 1),
  CONSTRAINT ck_org_import_row_errors CHECK (jsonb_typeof(errors) = 'array' AND jsonb_typeof(data) = 'object'),
  CONSTRAINT ck_org_import_row_error_action CHECK (status <> 'ERROR' OR action = 'ERROR'),
  CONSTRAINT fk_org_import_row_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_org_import_row_job FOREIGN KEY (job_id, tenant_id) REFERENCES ph20_tenant.org_import_job (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_org_import_row_fk_job ON ph20_tenant.org_import_row (tenant_id, job_id);
CREATE TRIGGER tg_org_import_row_touch BEFORE UPDATE ON ph20_tenant.org_import_row FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.org_import_row', 'OWN');
COMMENT ON TABLE ph20_tenant.org_import_row IS 'EN-20-30 Dòng của lô nhập tổ chức (FR-20-055): nội dung từng dòng, hành động dự kiến và lỗi kiểm tra; dòng lỗi không được áp dụng.';
COMMENT ON COLUMN ph20_tenant.org_import_row.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.org_import_row.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.org_import_row.job_id IS 'Lô nhập.';
COMMENT ON COLUMN ph20_tenant.org_import_row.row_no IS 'Số thứ tự dòng trong tệp, bắt đầu từ 1.';
COMMENT ON COLUMN ph20_tenant.org_import_row.org_code IS 'Mã tổ chức đọc được từ dòng.';
COMMENT ON COLUMN ph20_tenant.org_import_row.action IS 'Hành động: `CREATE`, `UPDATE`, `SKIP`, `ERROR`.';
COMMENT ON COLUMN ph20_tenant.org_import_row.status IS 'Trạng thái: `VALID`, `ERROR`, `APPLIED`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.org_import_row.errors IS 'Danh sách lỗi kiểm tra (cột, mã lỗi, thông điệp).';
COMMENT ON COLUMN ph20_tenant.org_import_row.data IS 'Nội dung dòng đã chuẩn hóa.';
COMMENT ON COLUMN ph20_tenant.org_import_row.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.org_import_row.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.org_import_row.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.org_import_row.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.org_import_row.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.org_import_row CASCADE;

-- @file 20-0080-release.sql
-- @changeset ph20-0450-product-release
CREATE TABLE ph20_tenant.product_release (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  version_code           varchar(32)    NOT NULL,
  name                   varchar(255),
  status                 varchar(12)    NOT NULL DEFAULT 'DRAFT',
  release_notes          text,
  breaking_change        boolean        NOT NULL DEFAULT false,
  min_from_version       varchar(32),
  preview_at             timestamptz,
  stable_at              timestamptz,
  deprecated_at          timestamptz,
  withdrawn_at           timestamptz,
  withdrawn_reason       varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_product_release PRIMARY KEY (id),
  CONSTRAINT uq_product_release_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_product_release_version UNIQUE (version_code),
  CONSTRAINT ck_product_release_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_product_release_status CHECK (status IN ('DRAFT', 'PREVIEW', 'STABLE', 'DEPRECATED', 'WITHDRAWN')),
  CONSTRAINT ck_product_release_version CHECK (version_code ~ '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$'),
  CONSTRAINT ck_product_release_preview CHECK (status NOT IN ('PREVIEW', 'STABLE', 'DEPRECATED') OR preview_at IS NOT NULL),
  CONSTRAINT ck_product_release_stable CHECK (status <> 'STABLE' OR (stable_at IS NOT NULL AND preview_at IS NOT NULL AND stable_at >= preview_at)),
  CONSTRAINT ck_product_release_withdrawn CHECK (status <> 'WITHDRAWN' OR (withdrawn_at IS NOT NULL AND withdrawn_reason IS NOT NULL))
);
CREATE TRIGGER tg_product_release_touch BEFORE UPDATE ON ph20_tenant.product_release FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_product_release_transition BEFORE UPDATE ON ph20_tenant.product_release FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PREVIEW", "WITHDRAWN"], "PREVIEW": ["STABLE", "DEPRECATED", "WITHDRAWN"], "STABLE": ["DEPRECATED", "WITHDRAWN"], "DEPRECATED": ["WITHDRAWN"]}');
CREATE TRIGGER tg_product_release_immutable BEFORE UPDATE ON ph20_tenant.product_release FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('version_code');
CALL ph20_tenant.p_enable_rls('ph20_tenant.product_release', 'PLATR');
COMMENT ON TABLE ph20_tenant.product_release IS 'EN-20-31 Phiên bản sản phẩm (FR-20-059, 060): danh mục phiên bản Datahub với ghi chú phát hành, qua `PREVIEW` rồi `STABLE` (ADR-203). Dữ liệu nền tảng, mọi tenant đọc được để xem phiên bản và ghi chú (FR-20-064).';
COMMENT ON COLUMN ph20_tenant.product_release.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.product_release.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.product_release.version_code IS 'Số phiên bản, dạng `1.0.0` hoặc `1.1.0-rc.1`.';
COMMENT ON COLUMN ph20_tenant.product_release.name IS 'Tên bản phát hành.';
COMMENT ON COLUMN ph20_tenant.product_release.status IS 'Trạng thái: `DRAFT`, `PREVIEW`, `STABLE`, `DEPRECATED`, `WITHDRAWN`.';
COMMENT ON COLUMN ph20_tenant.product_release.release_notes IS 'Ghi chú phát hành (Markdown).';
COMMENT ON COLUMN ph20_tenant.product_release.breaking_change IS 'Có thay đổi phá vỡ tương thích.';
COMMENT ON COLUMN ph20_tenant.product_release.min_from_version IS 'Phiên bản thấp nhất được nâng cấp thẳng lên bản này.';
COMMENT ON COLUMN ph20_tenant.product_release.preview_at IS 'Thời điểm sang kênh `PREVIEW`.';
COMMENT ON COLUMN ph20_tenant.product_release.stable_at IS 'Thời điểm sang kênh `STABLE` (sau thời gian chạy thử, `20.release.stable-soak-days`).';
COMMENT ON COLUMN ph20_tenant.product_release.deprecated_at IS 'Thời điểm ngừng khuyến nghị.';
COMMENT ON COLUMN ph20_tenant.product_release.withdrawn_at IS 'Thời điểm rút bản.';
COMMENT ON COLUMN ph20_tenant.product_release.withdrawn_reason IS 'Lý do rút bản.';
COMMENT ON COLUMN ph20_tenant.product_release.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.product_release.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.product_release.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.product_release.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.product_release.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.product_release CASCADE;

-- @changeset ph20-0460-release-component
CREATE TABLE ph20_tenant.release_component (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  release_id             uuid           NOT NULL,
  component_code         varchar(64)    NOT NULL,
  component_type         varchar(10)    NOT NULL,
  image_ref              varchar(255),
  chart_version          varchar(32),
  digest                 varchar(71),
  migration_required     boolean        NOT NULL DEFAULT false,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_release_component PRIMARY KEY (id),
  CONSTRAINT uq_release_component_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_release_component_component UNIQUE (release_id, component_code),
  CONSTRAINT ck_release_component_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_release_component_component_type CHECK (component_type IN ('SERVICE', 'CONSOLE', 'CHART', 'SCHEMA', 'CONFIG')),
  CONSTRAINT ck_release_component_digest CHECK (digest IS NULL OR digest ~ '^sha256:[0-9a-f]{64}$'),
  CONSTRAINT fk_release_component_release FOREIGN KEY (release_id, tenant_id) REFERENCES ph20_tenant.product_release (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_release_component_fk_release ON ph20_tenant.release_component (tenant_id, release_id);
CREATE TRIGGER tg_release_component_touch BEFORE UPDATE ON ph20_tenant.release_component FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.release_component', 'PLATR');
COMMENT ON TABLE ph20_tenant.release_component IS 'EN-20-31 Thành phần của phiên bản (FR-20-059): dịch vụ, giao diện, chart, schema CSDL, cấu hình thuộc một bản phát hành, kèm mã băm ảnh. Không chứa thông tin xác thực kho ảnh.';
COMMENT ON COLUMN ph20_tenant.release_component.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.release_component.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.release_component.release_id IS 'Phiên bản sản phẩm.';
COMMENT ON COLUMN ph20_tenant.release_component.component_code IS 'Mã thành phần, ví dụ `dh-platform`, `dh-console`, `ph20_tenant`.';
COMMENT ON COLUMN ph20_tenant.release_component.component_type IS 'Loại: `SERVICE`, `CONSOLE`, `CHART`, `SCHEMA`, `CONFIG`.';
COMMENT ON COLUMN ph20_tenant.release_component.image_ref IS 'Tham chiếu ảnh, gói (không kèm thông tin xác thực).';
COMMENT ON COLUMN ph20_tenant.release_component.chart_version IS 'Phiên bản Helm chart.';
COMMENT ON COLUMN ph20_tenant.release_component.digest IS 'Mã băm ảnh `sha256:...`.';
COMMENT ON COLUMN ph20_tenant.release_component.migration_required IS 'Cần chạy migration CSDL khi nâng cấp.';
COMMENT ON COLUMN ph20_tenant.release_component.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.release_component.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.release_component.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.release_component.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.release_component.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.release_component CASCADE;

-- @changeset ph20-0470-tenant-release-subscription
CREATE TABLE ph20_tenant.tenant_release_subscription (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  channel                varchar(8)     NOT NULL DEFAULT 'STABLE',
  pinned_release_id      uuid,
  current_release_id     uuid,
  is_pilot               boolean        NOT NULL DEFAULT false,
  subscribed_at          timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_release_subscription PRIMARY KEY (id),
  CONSTRAINT uq_tenant_release_subscription_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_release_subscription_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_release_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_release_subscription_channel CHECK (channel IN ('STABLE', 'PREVIEW')),
  CONSTRAINT fk_tenant_release_subscription_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_release_subscription_pinned_release FOREIGN KEY (pinned_release_id) REFERENCES ph20_tenant.product_release (id),
  CONSTRAINT fk_tenant_release_subscription_current_release FOREIGN KEY (current_release_id) REFERENCES ph20_tenant.product_release (id)
);
CREATE TRIGGER tg_tenant_release_subscription_touch BEFORE UPDATE ON ph20_tenant.tenant_release_subscription FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_release_subscription', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_release_subscription IS 'EN-20-32 Đăng ký kênh phát hành của tenant (FR-20-060): tenant theo kênh `STABLE` hoặc `PREVIEW`, có thể ghim phiên bản, đánh dấu tenant thí điểm nhận bản trước (ADR-203). Một dòng mỗi tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.channel IS 'Kênh: `STABLE` hoặc `PREVIEW`.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.pinned_release_id IS 'Phiên bản được ghim (không tự nâng cấp lên bản mới hơn).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.current_release_id IS 'Phiên bản đang chạy của tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.is_pilot IS 'Tenant thí điểm, nhận bản `PREVIEW` và là nơi chạy thử đủ thời gian trước khi sang `STABLE`.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.subscribed_at IS 'Thời điểm đăng ký kênh.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_release_subscription CASCADE;

-- @changeset ph20-0480-maintenance-window
CREATE TABLE ph20_tenant.maintenance_window (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  name                   varchar(255)   NOT NULL,
  window_type            varchar(10)    NOT NULL DEFAULT 'RECURRING',
  day_of_week            smallint,
  start_time             time,
  duration_minutes       integer        NOT NULL DEFAULT 120,
  starts_at              timestamptz,
  ends_at                timestamptz,
  timezone               varchar(40)    NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  enabled                boolean        NOT NULL DEFAULT true,
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_maintenance_window PRIMARY KEY (id),
  CONSTRAINT uq_maintenance_window_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_maintenance_window_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_maintenance_window_window_type CHECK (window_type IN ('RECURRING', 'ONE_OFF')),
  CONSTRAINT ck_maintenance_window_duration CHECK (duration_minutes BETWEEN 15 AND 1440),
  CONSTRAINT ck_maintenance_window_day CHECK (day_of_week IS NULL OR day_of_week BETWEEN 1 AND 7),
  CONSTRAINT ck_maintenance_window_recurring CHECK (window_type <> 'RECURRING' OR (day_of_week IS NOT NULL AND start_time IS NOT NULL)),
  CONSTRAINT ck_maintenance_window_one_off CHECK (window_type <> 'ONE_OFF' OR (starts_at IS NOT NULL AND ends_at IS NOT NULL AND ends_at > starts_at)),
  CONSTRAINT fk_maintenance_window_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE INDEX ix_maintenance_window_enabled ON ph20_tenant.maintenance_window (tenant_id, enabled);
CREATE TRIGGER tg_maintenance_window_touch BEFORE UPDATE ON ph20_tenant.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.maintenance_window', 'OWN');
COMMENT ON TABLE ph20_tenant.maintenance_window IS 'EN-20-33 Cửa sổ bảo trì của tenant (FR-20-061, 063, 064): khung giờ định kỳ hoặc một lần mà nâng cấp được phép chạy; tỉnh tự khai báo, kế hoạch nâng cấp tôn trọng cửa sổ.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.name IS 'Tên cửa sổ.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.window_type IS 'Loại: `RECURRING` (hằng tuần) hoặc `ONE_OFF` (một lần).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.day_of_week IS 'Thứ trong tuần theo ISO, 1 là thứ Hai (cửa sổ `RECURRING`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.start_time IS 'Giờ bắt đầu theo múi giờ của cửa sổ (cửa sổ `RECURRING`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.duration_minutes IS 'Thời lượng, phút.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.starts_at IS 'Bắt đầu (cửa sổ `ONE_OFF`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.ends_at IS 'Kết thúc (cửa sổ `ONE_OFF`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.timezone IS 'Múi giờ.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.enabled IS 'Cửa sổ đang áp dụng.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.maintenance_window CASCADE;

-- @changeset ph20-0490-upgrade-plan
CREATE TABLE ph20_tenant.upgrade_plan (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_code              varchar(48)    NOT NULL,
  release_id             uuid           NOT NULL,
  channel                varchar(8)     NOT NULL DEFAULT 'STABLE',
  status                 varchar(12)    NOT NULL DEFAULT 'DRAFT',
  error_threshold_percent numeric(5,2)   NOT NULL DEFAULT 2,
  scheduled_at           timestamptz,
  started_at             timestamptz,
  completed_at           timestamptz,
  pause_reason           varchar(1000),
  ticket_code            varchar(32),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_upgrade_plan PRIMARY KEY (id),
  CONSTRAINT uq_upgrade_plan_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_upgrade_plan_code UNIQUE (plan_code),
  CONSTRAINT ck_upgrade_plan_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_upgrade_plan_status CHECK (status IN ('DRAFT', 'SCHEDULED', 'RUNNING', 'PAUSED', 'COMPLETED', 'ROLLED_BACK', 'CANCELLED')),
  CONSTRAINT ck_upgrade_plan_channel CHECK (channel IN ('STABLE', 'PREVIEW')),
  CONSTRAINT ck_upgrade_plan_code CHECK (plan_code ~ '^[a-z0-9][a-z0-9-]{2,47}$'),
  CONSTRAINT ck_upgrade_plan_threshold CHECK (error_threshold_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_upgrade_plan_running CHECK (status NOT IN ('RUNNING', 'PAUSED', 'COMPLETED', 'ROLLED_BACK') OR started_at IS NOT NULL),
  CONSTRAINT fk_upgrade_plan_release FOREIGN KEY (release_id, tenant_id) REFERENCES ph20_tenant.product_release (id, tenant_id)
);
CREATE INDEX ix_upgrade_plan_status ON ph20_tenant.upgrade_plan (status);
CREATE INDEX ix_upgrade_plan_fk_release ON ph20_tenant.upgrade_plan (tenant_id, release_id);
CREATE TRIGGER tg_upgrade_plan_touch BEFORE UPDATE ON ph20_tenant.upgrade_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_upgrade_plan_immutable BEFORE UPDATE ON ph20_tenant.upgrade_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('plan_code', 'release_id');
CALL ph20_tenant.p_enable_rls('ph20_tenant.upgrade_plan', 'PLAT');
COMMENT ON TABLE ph20_tenant.upgrade_plan IS 'EN-20-34 Kế hoạch nâng cấp theo sóng (FR-20-061, 062): đưa một phiên bản lên các tenant theo từng sóng; tự dừng khi tỷ lệ lỗi vượt `error_threshold_percent` (`20.release.wave-error-threshold-percent`).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.plan_code IS 'Mã kế hoạch, dạng `nang-cap-1-1-0`.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.release_id IS 'Phiên bản đích.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.channel IS 'Kênh áp dụng: `STABLE` hoặc `PREVIEW`.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.status IS 'Trạng thái: `DRAFT`, `SCHEDULED`, `RUNNING`, `PAUSED`, `COMPLETED`, `ROLLED_BACK`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.error_threshold_percent IS 'Ngưỡng lỗi dừng sóng, phần trăm.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.scheduled_at IS 'Thời điểm bắt đầu dự kiến.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.started_at IS 'Bắt đầu thực tế.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.completed_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.pause_reason IS 'Lý do dừng.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.ticket_code IS 'Mã phiếu thay đổi.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.upgrade_plan CASCADE;

-- @changeset ph20-0500-upgrade-wave
CREATE TABLE ph20_tenant.upgrade_wave (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  wave_no                smallint       NOT NULL,
  name                   varchar(255),
  status                 varchar(10)    NOT NULL DEFAULT 'PENDING',
  tenant_selector        jsonb          NOT NULL DEFAULT '{}',
  tenant_count           integer        NOT NULL DEFAULT 0,
  planned_start          timestamptz,
  started_at             timestamptz,
  finished_at            timestamptz,
  error_percent          numeric(5,2),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_upgrade_wave PRIMARY KEY (id),
  CONSTRAINT uq_upgrade_wave_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_upgrade_wave_wave UNIQUE (plan_id, wave_no),
  CONSTRAINT ck_upgrade_wave_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_upgrade_wave_status CHECK (status IN ('PENDING', 'RUNNING', 'PAUSED', 'DONE', 'STOPPED')),
  CONSTRAINT ck_upgrade_wave_wave CHECK (wave_no >= 1),
  CONSTRAINT ck_upgrade_wave_selector CHECK (jsonb_typeof(tenant_selector) = 'object'),
  CONSTRAINT ck_upgrade_wave_count CHECK (tenant_count >= 0),
  CONSTRAINT ck_upgrade_wave_error CHECK (error_percent IS NULL OR error_percent BETWEEN 0 AND 100),
  CONSTRAINT fk_upgrade_wave_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.upgrade_plan (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_upgrade_wave_fk_plan ON ph20_tenant.upgrade_wave (tenant_id, plan_id);
CREATE TRIGGER tg_upgrade_wave_touch BEFORE UPDATE ON ph20_tenant.upgrade_wave FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.upgrade_wave', 'PLAT');
COMMENT ON TABLE ph20_tenant.upgrade_wave IS 'EN-20-34 Sóng nâng cấp (FR-20-061, 062): nhóm tenant nâng cấp cùng lúc, thường sóng 1 là tenant thí điểm; dừng sóng tự động khi vượt ngưỡng lỗi.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.plan_id IS 'Kế hoạch nâng cấp.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.wave_no IS 'Số thứ tự sóng, bắt đầu từ 1.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.name IS 'Tên sóng.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.status IS 'Trạng thái: `PENDING`, `RUNNING`, `PAUSED`, `DONE`, `STOPPED`.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.tenant_selector IS 'Điều kiện chọn tenant (danh sách mã, cờ thí điểm, hồ sơ quy mô).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.tenant_count IS 'Số tenant trong sóng.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.planned_start IS 'Bắt đầu dự kiến.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.started_at IS 'Bắt đầu thực tế.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.error_percent IS 'Tỷ lệ lỗi hiện tại của sóng.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.upgrade_wave CASCADE;

-- @changeset ph20-0510-tenant-upgrade
CREATE TABLE ph20_tenant.tenant_upgrade (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  wave_id                uuid           NOT NULL,
  release_id             uuid           NOT NULL,
  status                 varchar(12)    NOT NULL DEFAULT 'PENDING',
  maintenance_window_id  uuid,
  scheduled_for          timestamptz,
  started_at             timestamptz,
  verified_at            timestamptz,
  finished_at            timestamptz,
  attempt                integer        NOT NULL DEFAULT 1,
  rollback_release_id    uuid,
  error_code             varchar(16),
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_upgrade PRIMARY KEY (id),
  CONSTRAINT uq_tenant_upgrade_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_upgrade_wave UNIQUE (wave_id, tenant_id),
  CONSTRAINT ck_tenant_upgrade_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_upgrade_status CHECK (status IN ('PENDING', 'IN_WINDOW', 'UPGRADING', 'VERIFYING', 'DONE', 'FAILED', 'ROLLED_BACK', 'SKIPPED')),
  CONSTRAINT ck_tenant_upgrade_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_tenant_upgrade_done CHECK (status <> 'DONE' OR finished_at IS NOT NULL),
  CONSTRAINT ck_tenant_upgrade_rollback CHECK (status <> 'ROLLED_BACK' OR rollback_release_id IS NOT NULL),
  CONSTRAINT fk_tenant_upgrade_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_upgrade_plan FOREIGN KEY (plan_id) REFERENCES ph20_tenant.upgrade_plan (id),
  CONSTRAINT fk_tenant_upgrade_wave FOREIGN KEY (wave_id) REFERENCES ph20_tenant.upgrade_wave (id),
  CONSTRAINT fk_tenant_upgrade_release FOREIGN KEY (release_id) REFERENCES ph20_tenant.product_release (id),
  CONSTRAINT fk_tenant_upgrade_window FOREIGN KEY (maintenance_window_id, tenant_id) REFERENCES ph20_tenant.maintenance_window (id, tenant_id),
  CONSTRAINT fk_tenant_upgrade_rollback_release FOREIGN KEY (rollback_release_id) REFERENCES ph20_tenant.product_release (id)
);
CREATE INDEX ix_tenant_upgrade_tenant_status ON ph20_tenant.tenant_upgrade (tenant_id, status);
CREATE INDEX ix_tenant_upgrade_plan ON ph20_tenant.tenant_upgrade (plan_id);
CREATE INDEX ix_tenant_upgrade_fk_window ON ph20_tenant.tenant_upgrade (tenant_id, maintenance_window_id);
CREATE TRIGGER tg_tenant_upgrade_touch BEFORE UPDATE ON ph20_tenant.tenant_upgrade FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_upgrade', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_upgrade IS 'EN-20-35 Nâng cấp theo tenant (FR-20-062, 064): trạng thái nâng cấp của từng tenant trong một sóng, gắn cửa sổ bảo trì; mỗi đổi trạng thái phát EVT-20-15.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.plan_id IS 'Kế hoạch nâng cấp.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.wave_id IS 'Sóng chứa tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.release_id IS 'Phiên bản đích.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.status IS 'Trạng thái: `PENDING`, `IN_WINDOW`, `UPGRADING`, `VERIFYING`, `DONE`, `FAILED`, `ROLLED_BACK`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.maintenance_window_id IS 'Cửa sổ bảo trì được dùng.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.scheduled_for IS 'Thời điểm dự kiến trong cửa sổ.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.started_at IS 'Bắt đầu nâng cấp.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.verified_at IS 'Kiểm tra sau nâng cấp xong.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.attempt IS 'Lần thử.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.rollback_release_id IS 'Phiên bản quay lui khi `ROLLED_BACK`.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.error_code IS 'Mã lỗi.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.tenant_upgrade CASCADE;

-- @changeset ph20-0520-leak-test-run
CREATE TABLE ph20_tenant.leak_test_run (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  trigger_type           varchar(14)    NOT NULL DEFAULT 'SCHEDULE',
  status                 varchar(8)     NOT NULL DEFAULT 'RUNNING',
  tenant_codes           text[]         NOT NULL DEFAULT '{}',
  tenants_tested         integer        NOT NULL DEFAULT 0,
  cases_total            integer        NOT NULL DEFAULT 0,
  cases_failed           integer        NOT NULL DEFAULT 0,
  failures               jsonb          NOT NULL DEFAULT '[]',
  report_file_id         uuid,
  started_at             timestamptz    NOT NULL DEFAULT now(),
  finished_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_leak_test_run PRIMARY KEY (id),
  CONSTRAINT uq_leak_test_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_leak_test_run_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_leak_test_run_trigger_type CHECK (trigger_type IN ('SCHEDULE', 'MANUAL', 'PRE_ACTIVATION')),
  CONSTRAINT ck_leak_test_run_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'ERROR')),
  CONSTRAINT ck_leak_test_run_counts CHECK (tenants_tested >= 0 AND cases_total >= 0 AND cases_failed >= 0 AND cases_failed <= cases_total),
  CONSTRAINT ck_leak_test_run_failures CHECK (jsonb_typeof(failures) = 'array'),
  CONSTRAINT ck_leak_test_run_passed CHECK (status <> 'PASSED' OR cases_failed = 0),
  CONSTRAINT ck_leak_test_run_finished CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT fk_leak_test_run_report_file FOREIGN KEY (report_file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_leak_test_run_started ON ph20_tenant.leak_test_run (started_at DESC);
CREATE INDEX ix_leak_test_run_fk_report_file ON ph20_tenant.leak_test_run (tenant_id, report_file_id);
CREATE TRIGGER tg_leak_test_run_touch BEFORE UPDATE ON ph20_tenant.leak_test_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.leak_test_run', 'PLAT');
COMMENT ON TABLE ph20_tenant.leak_test_run IS 'EN-20-36 Lần kiểm thử rò rỉ chéo tenant (FR-20-070, SEC-87): chạy hằng đêm hoặc trước khi kích hoạt tenant mới; ghi số ca, số ca lỗi, danh sách lỗi. Ca lỗi là sự cố an ninh mức cao.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.leak_test_run.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.trigger_type IS 'Nguồn kích hoạt: `SCHEDULE`, `MANUAL`, `PRE_ACTIVATION`.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.status IS 'Trạng thái: `RUNNING`, `PASSED`, `FAILED`, `ERROR`.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.tenant_codes IS 'Các tenant được kiểm trong lần chạy.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.tenants_tested IS 'Số tenant đã kiểm.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.cases_total IS 'Tổng số ca.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.cases_failed IS 'Số ca phát hiện rò rỉ.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.failures IS 'Danh sách ca lỗi (tầng, bên đọc, bên bị đọc, mô tả), không chứa dữ liệu thật.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.report_file_id IS 'Tệp báo cáo chi tiết.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.started_at IS 'Bắt đầu.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.leak_test_run.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.leak_test_run.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.leak_test_run CASCADE;

-- @file 20-0085-ops.sql
-- @changeset ph20-0530-outbox
CREATE TABLE ph20_tenant.outbox (
  tenant_id              varchar(16)    NOT NULL,
  event_id               uuid           NOT NULL,
  event_type             varchar(128)   NOT NULL,
  topic                  varchar(128)   NOT NULL,
  aggregate_type         varchar(32)    NOT NULL,
  aggregate_id           uuid           NOT NULL,
  payload                jsonb          NOT NULL,
  trace_id               char(32)       NOT NULL,
  occurred_at            timestamptz    NOT NULL DEFAULT now(),
  published_at           timestamptz,
  CONSTRAINT pk_outbox PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_outbox_topic CHECK (topic IN ('platform.tenant.created.v1', 'platform.tenant.provisioning-failed.v1', 'platform.tenant.activated.v1', 'platform.tenant.status-changed.v1', 'platform.tenant.quota-changed.v1', 'platform.tenant.quota-threshold-reached.v1', 'platform.tenant.module-enabled.v1', 'platform.tenant.module-disabled.v1', 'platform.tenant.config-changed.v1', 'platform.tenant.merge-started.v1', 'platform.tenant.merge-cutover.v1', 'platform.tenant.merge-completed.v1', 'platform.release.published.v1', 'platform.tenant.upgrade-changed.v1', 'platform.tenant.export-ready.v1', 'platform.obs.audit.recorded.v1') OR topic = lower(tenant_id) || '.tenant.org.changed.v1'),
  CONSTRAINT ck_outbox_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_payload CHECK (jsonb_typeof(payload) = 'object')
);
CREATE INDEX ix_outbox_occurred ON ph20_tenant.outbox (occurred_at);
CREATE INDEX ix_outbox_unpublished ON ph20_tenant.outbox (occurred_at) WHERE published_at IS NULL;
CALL ph20_tenant.p_enable_rls('ph20_tenant.outbox', 'TECH');
COMMENT ON TABLE ph20_tenant.outbox IS 'Hạ tầng, DD-11 Outbox (SAD 7.3) cho EVT-20-01…16 và bản ghi kiểm toán gửi PH-13: ghi cùng giao dịch với thay đổi, Debezium Outbox Event Router đọc WAL và phát Kafka. Sự kiện vòng đời đi trên `platform.*`, sự kiện tổ chức trên `{tenant}.tenant.org.changed.v1`. Dọn sau 3 ngày.';
COMMENT ON COLUMN ph20_tenant.outbox.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.outbox.event_id IS 'Mã sự kiện, thành `id` của CloudEvent; bên nhận dùng để chống trùng.';
COMMENT ON COLUMN ph20_tenant.outbox.event_type IS 'Kiểu sự kiện, ví dụ `vn.datahub.platform.tenant.created.v1`.';
COMMENT ON COLUMN ph20_tenant.outbox.topic IS 'Topic Kafka theo D00-01 §6.';
COMMENT ON COLUMN ph20_tenant.outbox.aggregate_type IS 'Loại thực thể gốc (`tenant`, `organization`, `merge_plan`…).';
COMMENT ON COLUMN ph20_tenant.outbox.aggregate_id IS 'Thực thể gốc, làm khóa phân vùng Kafka.';
COMMENT ON COLUMN ph20_tenant.outbox.payload IS 'Nội dung theo schema đã đăng ký.';
COMMENT ON COLUMN ph20_tenant.outbox.trace_id IS 'Mã vết phân tán.';
COMMENT ON COLUMN ph20_tenant.outbox.occurred_at IS 'Thời điểm xảy ra.';
COMMENT ON COLUMN ph20_tenant.outbox.published_at IS 'Thời điểm đã phát (do Debezium hoặc job dọn đánh dấu).';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.outbox CASCADE;

-- @changeset ph20-0540-inbox-event
CREATE TABLE ph20_tenant.inbox_event (
  tenant_id              varchar(16)    NOT NULL,
  consumer               varchar(64)    NOT NULL,
  event_id               uuid           NOT NULL,
  source_topic           varchar(128)   NOT NULL,
  received_at            timestamptz    NOT NULL DEFAULT now(),
  processed_at           timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM')
);
CREATE INDEX ix_inbox_event_received ON ph20_tenant.inbox_event (received_at);
CALL ph20_tenant.p_enable_rls('ph20_tenant.inbox_event', 'TECH');
COMMENT ON TABLE ph20_tenant.inbox_event IS 'Hạ tầng. Hộp nhận sự kiện từ phân hệ khác (EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11): khử trùng theo `(tenant_id, consumer, event_id)` để tiêu thụ lũy đẳng.';
COMMENT ON COLUMN ph20_tenant.inbox_event.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.inbox_event.consumer IS 'Tên bộ tiêu thụ trong PH-20.';
COMMENT ON COLUMN ph20_tenant.inbox_event.event_id IS 'Mã sự kiện nhận.';
COMMENT ON COLUMN ph20_tenant.inbox_event.source_topic IS 'Topic nguồn.';
COMMENT ON COLUMN ph20_tenant.inbox_event.received_at IS 'Thời điểm nhận.';
COMMENT ON COLUMN ph20_tenant.inbox_event.processed_at IS 'Thời điểm xử lý xong.';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.inbox_event CASCADE;

-- @changeset ph20-0550-idempotency-key
CREATE TABLE ph20_tenant.idempotency_key (
  tenant_id              varchar(16)    NOT NULL,
  client_id              varchar(255)   NOT NULL,
  request_method         varchar(8)     NOT NULL,
  request_path           varchar(512)   NOT NULL,
  idempotency_ref        varchar(128)   NOT NULL,
  request_hash           char(64)       NOT NULL,
  state                  varchar(12)    NOT NULL DEFAULT 'IN_PROGRESS',
  resource_id            uuid,
  response_status        smallint,
  response_body          jsonb,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  completed_at           timestamptz,
  expires_at             timestamptz    NOT NULL,
  CONSTRAINT pk_idempotency_key PRIMARY KEY (tenant_id, client_id, request_method, request_path, idempotency_ref),
  CONSTRAINT ck_idempotency_key_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_idempotency_key_ref CHECK (idempotency_ref ~ '^[A-Za-z0-9_:-]{16,128}$'),
  CONSTRAINT ck_idempotency_key_state CHECK (state IN ('IN_PROGRESS', 'COMPLETED')),
  CONSTRAINT ck_idempotency_key_done CHECK (state = 'IN_PROGRESS' OR response_status IS NOT NULL),
  CONSTRAINT ck_idempotency_key_hash CHECK (request_hash ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_idempotency_key_expiry ON ph20_tenant.idempotency_key (expires_at);
CALL ph20_tenant.p_enable_rls('ph20_tenant.idempotency_key', 'TECH');
COMMENT ON TABLE ph20_tenant.idempotency_key IS 'Hạ tầng. Kết quả yêu cầu ghi có tiêu đề `Idempotency-Key` (API công khai và saga: khóa `{runId}:{stepCode}`); giữ 24 giờ. Cột khóa tên `idempotency_ref` (tránh trùng tên cột nhạy cảm của công cụ quét).';
COMMENT ON COLUMN ph20_tenant.idempotency_key.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.client_id IS 'Định danh máy khách gọi API.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.request_method IS 'Phương thức HTTP.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.request_path IS 'Đường dẫn yêu cầu.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.idempotency_ref IS 'Giá trị tiêu đề `Idempotency-Key`.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.request_hash IS 'Băm nội dung yêu cầu, phát hiện cùng khóa khác nội dung.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.state IS 'Trạng thái: `IN_PROGRESS` hoặc `COMPLETED`.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.resource_id IS 'Tài nguyên đã tạo.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.response_status IS 'Mã HTTP đã trả.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.response_body IS 'Nội dung đã trả (đã che dữ liệu nhạy cảm).';
COMMENT ON COLUMN ph20_tenant.idempotency_key.created_at IS 'Thời điểm nhận yêu cầu đầu.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.completed_at IS 'Thời điểm hoàn tất.';
COMMENT ON COLUMN ph20_tenant.idempotency_key.expires_at IS 'Hạn giữ.';
-- @rollback DROP TABLE IF EXISTS ph20_tenant.idempotency_key CASCADE;

-- @file 20-0090-seed.sql
-- @changeset ph20-0910-fn-seed-platform splitStatements:false
-- Dữ liệu nền: hai tenant đặc biệt, danh mục 20 phân hệ cùng phụ thuộc chính, mẫu khởi tạo QM-VUA. Chạy dưới phiên PLATFORM, chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph20_tenant.p_seed_platform()
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph20_tenant.tenant (id, code, kind, name, short_name, status, isolation_mode, realm, activated_at, config_path, created_by, updated_by)
  VALUES (md5('ph20-tenant:PLATFORM')::uuid, 'PLATFORM', 'PLATFORM', 'Nền tảng Datahub (control plane)', 'Nền tảng', 'ACTIVE', 'SHARED', 'dh-platform', now(), 'tenants/PLATFORM/', 'system:seed', 'system:seed'),
         (md5('ph20-tenant:COMMON')::uuid, 'COMMON', 'COMMON', 'Dữ liệu dùng chung toàn quốc', 'Dùng chung', 'ACTIVE', 'SHARED', NULL, now(), 'tenants/COMMON/', 'system:seed', 'system:seed')
  ON CONFLICT (code) DO NOTHING;
  INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, is_core, default_enabled, status, display_order, created_by, updated_by)
  SELECT md5('ph20-module:' || m.c)::uuid, 'PLATFORM', m.c, m.n, m.w, m.du, m.core, m.def, 'AVAILABLE', m.o, 'system:seed', 'system:seed'
  FROM (VALUES ('PH-01', 'Kết nạp HTTT', 1, 'dh-connect', false, true, 1),
    ('PH-02', 'Danh mục dịch vụ', 1, 'dh-connect', false, true, 2),
    ('PH-03', 'Cổng API', 1, 'dh-connect', false, true, 3),
    ('PH-04', 'Lõi tích hợp và trình thiết kế luồng', 1, 'dh-integration', false, true, 4),
    ('PH-05', 'Bộ điều hợp', 1, 'dh-integration', false, true, 5),
    ('PH-06', 'Dữ liệu chủ', 3, 'dh-data', false, false, 6),
    ('PH-07', 'Danh mục dùng chung', 1, 'dh-data', false, true, 7),
    ('PH-08', 'Chất lượng dữ liệu', 3, 'dh-data', false, false, 8),
    ('PH-09', 'Quyền riêng tư', 2, 'dh-data', false, false, 9),
    ('PH-10', 'Sự kiện', 1, 'dh-integration', false, true, 10),
    ('PH-11', 'Quy trình liên thông', 2, 'dh-platform', false, false, 11),
    ('PH-12', 'Định danh và phân quyền', 1, 'dh-platform', true, true, 12),
    ('PH-13', 'Giám sát và kiểm toán', 1, 'dh-platform', true, true, 13),
    ('PH-14', 'Kết nối quốc gia', 1, 'dh-runtime', false, true, 14),
    ('PH-15', 'Cổng nhà phát triển', 2, 'dh-portal', false, false, 15),
    ('PH-16', 'Báo cáo chỉ tiêu', 3, 'dh-platform', false, false, 16),
    ('PH-17', 'Trợ lý AI', 3, 'dh-assist', false, false, 17),
    ('PH-18', 'Vận hành và xử lý lỗi', 1, 'dh-platform', true, true, 18),
    ('PH-19', 'Thanh toán', 2, 'dh-payment', false, false, 19),
    ('PH-20', 'Quản trị tenant và phát hành sản phẩm', 1, 'dh-platform', true, true, 20)) AS m(c, n, w, du, core, def, o)
  ON CONFLICT (module_code) DO NOTHING;
  INSERT INTO ph20_tenant.module_dependency (id, tenant_id, module_code, depends_on_code, dependency_type, reason, created_by, updated_by)
  SELECT md5('ph20-dep:' || d.a || ':' || d.b)::uuid, 'PLATFORM', d.a, d.b, d.t, d.r, 'system:seed', 'system:seed'
  FROM (VALUES ('PH-01', 'PH-12', 'REQUIRED', 'Cấp định danh ứng dụng cho HTTT'),
    ('PH-01', 'PH-20', 'REQUIRED', 'Danh mục tổ chức chủ quản HTTT'),
    ('PH-02', 'PH-01', 'REQUIRED', 'Dịch vụ thuộc HTTT thành viên'),
    ('PH-03', 'PH-12', 'REQUIRED', 'Xác thực và phân quyền ở cổng'),
    ('PH-03', 'PH-01', 'REQUIRED', 'Định danh ứng dụng gọi API'),
    ('PH-03', 'PH-02', 'REQUIRED', 'Danh mục API công bố'),
    ('PH-04', 'PH-05', 'REQUIRED', 'Luồng dùng bộ điều hợp'),
    ('PH-04', 'PH-10', 'REQUIRED', 'Luồng phát nhận sự kiện'),
    ('PH-04', 'PH-12', 'REQUIRED', 'Phân quyền thiết kế, phát hành luồng'),
    ('PH-05', 'PH-12', 'REQUIRED', 'Bí mật kết nối do OpenBao, phân quyền'),
    ('PH-06', 'PH-07', 'REQUIRED', 'Dùng danh mục dùng chung'),
    ('PH-06', 'PH-10', 'OPTIONAL', 'Phát sự kiện bản ghi vàng'),
    ('PH-07', 'PH-12', 'REQUIRED', 'Phân quyền danh mục'),
    ('PH-08', 'PH-06', 'REQUIRED', 'Đo chất lượng dữ liệu chủ'),
    ('PH-08', 'PH-07', 'OPTIONAL', 'Đối chiếu danh mục'),
    ('PH-09', 'PH-12', 'REQUIRED', 'Phân quyền, người dùng'),
    ('PH-09', 'PH-07', 'OPTIONAL', 'Phân loại theo danh mục'),
    ('PH-10', 'PH-12', 'REQUIRED', 'Phân quyền topic, schema'),
    ('PH-11', 'PH-12', 'REQUIRED', 'Người xử lý quy trình'),
    ('PH-11', 'PH-10', 'OPTIONAL', 'Sự kiện quy trình'),
    ('PH-12', 'PH-13', 'REQUIRED', 'Ghi nhật ký kiểm toán'),
    ('PH-13', 'PH-12', 'REQUIRED', 'Phân quyền xem nhật ký'),
    ('PH-14', 'PH-05', 'REQUIRED', 'Adapter dùng Kamelet'),
    ('PH-14', 'PH-12', 'REQUIRED', 'Phân quyền kết nối quốc gia'),
    ('PH-15', 'PH-02', 'REQUIRED', 'Tài liệu API từ danh mục dịch vụ'),
    ('PH-15', 'PH-03', 'REQUIRED', 'Thử API qua cổng'),
    ('PH-16', 'PH-13', 'OPTIONAL', 'Nguồn số liệu giám sát'),
    ('PH-17', 'PH-12', 'REQUIRED', 'Quyền dùng trợ lý'),
    ('PH-17', 'PH-09', 'OPTIONAL', 'Che dữ liệu cá nhân trong lời nhắc'),
    ('PH-18', 'PH-12', 'REQUIRED', 'Phân quyền vận hành'),
    ('PH-18', 'PH-13', 'REQUIRED', 'Nhật ký vận hành'),
    ('PH-19', 'PH-03', 'REQUIRED', 'API thanh toán qua cổng'),
    ('PH-19', 'PH-10', 'REQUIRED', 'Sự kiện giao dịch'),
    ('PH-19', 'PH-12', 'REQUIRED', 'Phân quyền, đối tác'),
    ('PH-20', 'PH-12', 'REQUIRED', 'Tạo realm khi khởi tạo tenant'),
    ('PH-20', 'PH-13', 'REQUIRED', 'Chuỗi kiểm toán theo tenant'),
    ('PH-20', 'PH-18', 'OPTIONAL', 'Tham số, thông báo')) AS d(a, b, t, r)
  ON CONFLICT (module_code, depends_on_code) DO NOTHING;
  INSERT INTO ph20_tenant.provisioning_template (id, tenant_id, template_code, version_no, name, description, status, default_isolation_mode, deployment_profile,
                                                 default_quota, default_modules, step_plan, default_settings, org_seed, activated_at, created_by, updated_by)
  VALUES (md5('ph20-template:QM-VUA:1')::uuid, 'PLATFORM', 'QM-VUA', 1, 'Tỉnh quy mô vừa (GĐ-01)',
          'Mẫu khởi tạo mặc định cho tỉnh quy mô vừa: khoảng 200 HTTT, chế độ SHARED, hồ sơ triển khai HT-A, mười hai phân hệ MVP, bộ hạn mức theo D03-10 §5.3 cộng năm hạn mức bổ sung (giả định).',
          'ACTIVE', 'SHARED', 'HT-A',
          '{"API_RPS": 500, "ACTIVE_FLOWS": 1000, "KAFKA_PRODUCE_MBPS": 10, "KAFKA_CONSUME_MBPS": 20, "OBJECT_STORAGE_GB": 500, "DATABASE_GB": 200, "USERS": 2000, "MEMBER_SYSTEMS": 300, "PUBLISHED_APIS": 2000, "TOPICS": 2000, "RUNTIME_CPU": 16, "RUNTIME_MEMORY_GB": 64}'::jsonb,
          '{PH-01,PH-02,PH-03,PH-04,PH-05,PH-07,PH-10,PH-12,PH-13,PH-14,PH-18,PH-20}',
          '[{"stepCode": "S01_RECORD", "executor": "PH-20", "required": true}, {"stepCode": "S02_CONFIG_REPO", "executor": "PH-20", "required": true}, {"stepCode": "S03_REALM", "executor": "PH-12", "required": true}, {"stepCode": "S04_SECRETS", "executor": "PH-20", "required": true}, {"stepCode": "S05_BUCKETS", "executor": "PH-20", "required": true}, {"stepCode": "S06_EVENTING", "executor": "PH-10", "required": true}, {"stepCode": "S07_DATABASE", "executor": "PH-20", "required": false}, {"stepCode": "S08_OBSERVABILITY", "executor": "PH-13", "required": true}, {"stepCode": "S09_GATEWAY", "executor": "PH-03", "required": true}, {"stepCode": "S10_INTEGRATION", "executor": "PH-04", "required": true}, {"stepCode": "S11_SEED_RDM", "executor": "PH-07", "required": true}, {"stepCode": "S12_SEED_MDM", "executor": "PH-06", "required": false}, {"stepCode": "S13_ORG_SEED", "executor": "PH-20", "required": true}, {"stepCode": "S14_KPI", "executor": "PH-16", "required": false}, {"stepCode": "S15_MODULES", "executor": "PH-20", "required": true}, {"stepCode": "S16_SMOKE", "executor": "PH-20", "required": true}, {"stepCode": "S17_ACTIVATE", "executor": "PH-20", "required": true}]'::jsonb,
          '{"idleSessionMinutes": 30, "mfaRequired": true, "locale": "vi-VN", "timezone": "Asia/Ho_Chi_Minh"}',
          '[{"code": "UBND", "name": "Ủy ban nhân dân tỉnh", "orgType": "PROVINCE_PC"}, {"code": "SO-NV", "name": "Sở Nội vụ", "orgType": "DEPARTMENT"}, {"code": "SO-TC", "name": "Sở Tài chính", "orgType": "DEPARTMENT"}, {"code": "SO-KHCN", "name": "Sở Khoa học và Công nghệ", "orgType": "DEPARTMENT"}, {"code": "SO-TP", "name": "Sở Tư pháp", "orgType": "DEPARTMENT"}, {"code": "SO-YT", "name": "Sở Y tế", "orgType": "DEPARTMENT"}]'::jsonb,
          now(), 'system:seed', 'system:seed')
  ON CONFLICT (template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_seed_platform() IS 'Nạp dữ liệu nền PH-20: tenant PLATFORM và COMMON, 20 phân hệ cùng phụ thuộc chính, mẫu khởi tạo QM-VUA. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_seed_platform();

-- @changeset ph20-0920-fn-init-quota splitStatements:false
-- Bước S01_RECORD của saga: sao chép hạn mức mặc định từ mẫu khởi tạo của tenant sang tenant_quota. Chạy dưới phiên PLATFORM (ph20_platform_app).
CREATE OR REPLACE PROCEDURE ph20_tenant.p_init_tenant_quota(p_tenant text, p_actor text)
  LANGUAGE plpgsql AS $p$
BEGIN
  INSERT INTO ph20_tenant.tenant_quota (id, tenant_id, resource_code, limit_value, unit, source, effective_from, push_status, created_by, updated_by)
  SELECT md5('ph20-quota:' || p_tenant || ':' || e.res)::uuid, p_tenant, e.res, e.val::numeric,
         CASE e.res WHEN 'API_RPS' THEN 'rps' WHEN 'ACTIVE_FLOWS' THEN 'flow' WHEN 'KAFKA_PRODUCE_MBPS' THEN 'MB/s' WHEN 'KAFKA_CONSUME_MBPS' THEN 'MB/s'
                    WHEN 'OBJECT_STORAGE_GB' THEN 'GB' WHEN 'DATABASE_GB' THEN 'GB' WHEN 'USERS' THEN 'user' WHEN 'MEMBER_SYSTEMS' THEN 'system'
                    WHEN 'PUBLISHED_APIS' THEN 'api' WHEN 'TOPICS' THEN 'topic' WHEN 'RUNTIME_CPU' THEN 'vCPU' ELSE 'GB' END,
         'TEMPLATE', now(), 'PENDING', p_actor, p_actor
  FROM ph20_tenant.tenant t
  JOIN ph20_tenant.provisioning_template pt ON pt.id = t.template_id
  CROSS JOIN LATERAL jsonb_each_text(pt.default_quota) AS e(res, val)
  WHERE t.code = p_tenant
  ON CONFLICT (tenant_id, resource_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph20_tenant.p_init_tenant_quota(text, text) IS 'Sao chép 12 hạn mức mặc định từ mẫu khởi tạo sang tenant_quota (bước S01_RECORD, FR-20-001, FR-20-026). Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph20_tenant.p_init_tenant_quota(text, text);

-- @changeset ph20-0930-seed-run
CALL ph20_tenant.p_seed_platform();
-- @rollback DELETE FROM ph20_tenant.provisioning_template WHERE tenant_id = 'PLATFORM'; DELETE FROM ph20_tenant.module_dependency WHERE tenant_id = 'PLATFORM'; DELETE FROM ph20_tenant.platform_module WHERE tenant_id = 'PLATFORM'; ALTER TABLE ph20_tenant.tenant DISABLE TRIGGER USER; DELETE FROM ph20_tenant.tenant WHERE code IN ('PLATFORM', 'COMMON'); ALTER TABLE ph20_tenant.tenant ENABLE TRIGGER USER;

-- @file 20-0900-grants.sql
-- @changeset ph20-0990-grants runAlways:true
GRANT SELECT ON ph20_tenant.file_object, ph20_tenant.provisioning_template, ph20_tenant.tenant, ph20_tenant.organization, ph20_tenant.tenant_contact, ph20_tenant.tenant_contract, ph20_tenant.platform_module, ph20_tenant.module_dependency, ph20_tenant.tenant_module, ph20_tenant.tenant_feature_flag, ph20_tenant.tenant_platform_config, ph20_tenant.tenant_settings, ph20_tenant.tenant_config_version, ph20_tenant.config_drift, ph20_tenant.cross_tenant_policy, ph20_tenant.provisioning_run, ph20_tenant.provisioning_step, ph20_tenant.smoke_test_result, ph20_tenant.tenant_quota, ph20_tenant.quota_change_request, ph20_tenant.quota_override, ph20_tenant.usage_snapshot, ph20_tenant.quota_alert, ph20_tenant.usage_report, ph20_tenant.lifecycle_request, ph20_tenant.tenant_status_history, ph20_tenant.data_export_package, ph20_tenant.data_export_item, ph20_tenant.merge_plan, ph20_tenant.merge_mapping, ph20_tenant.merge_participant_run, ph20_tenant.merge_conflict, ph20_tenant.org_import_job, ph20_tenant.org_import_row, ph20_tenant.product_release, ph20_tenant.release_component, ph20_tenant.tenant_release_subscription, ph20_tenant.maintenance_window, ph20_tenant.upgrade_plan, ph20_tenant.upgrade_wave, ph20_tenant.tenant_upgrade, ph20_tenant.leak_test_run, ph20_tenant.outbox, ph20_tenant.inbox_event, ph20_tenant.idempotency_key TO ph20_ro;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph20_tenant.file_object, ph20_tenant.provisioning_template, ph20_tenant.tenant, ph20_tenant.organization, ph20_tenant.tenant_contact, ph20_tenant.tenant_contract, ph20_tenant.platform_module, ph20_tenant.module_dependency, ph20_tenant.tenant_module, ph20_tenant.tenant_feature_flag, ph20_tenant.tenant_platform_config, ph20_tenant.tenant_settings, ph20_tenant.tenant_config_version, ph20_tenant.config_drift, ph20_tenant.cross_tenant_policy, ph20_tenant.provisioning_run, ph20_tenant.provisioning_step, ph20_tenant.smoke_test_result, ph20_tenant.tenant_quota, ph20_tenant.quota_change_request, ph20_tenant.quota_override, ph20_tenant.usage_snapshot, ph20_tenant.quota_alert, ph20_tenant.usage_report, ph20_tenant.lifecycle_request, ph20_tenant.tenant_status_history, ph20_tenant.data_export_package, ph20_tenant.data_export_item, ph20_tenant.merge_plan, ph20_tenant.merge_mapping, ph20_tenant.merge_participant_run, ph20_tenant.merge_conflict, ph20_tenant.org_import_job, ph20_tenant.org_import_row, ph20_tenant.product_release, ph20_tenant.release_component, ph20_tenant.tenant_release_subscription, ph20_tenant.maintenance_window, ph20_tenant.upgrade_plan, ph20_tenant.upgrade_wave, ph20_tenant.tenant_upgrade, ph20_tenant.leak_test_run, ph20_tenant.outbox, ph20_tenant.inbox_event, ph20_tenant.idempotency_key TO ph20_platform_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph20_tenant.file_object, ph20_tenant.organization, ph20_tenant.tenant_settings, ph20_tenant.cross_tenant_policy, ph20_tenant.org_import_job, ph20_tenant.org_import_row, ph20_tenant.maintenance_window, ph20_tenant.outbox, ph20_tenant.inbox_event, ph20_tenant.idempotency_key TO ph20_app;
GRANT SELECT ON ph20_tenant.provisioning_template, ph20_tenant.tenant, ph20_tenant.tenant_contact, ph20_tenant.tenant_contract, ph20_tenant.platform_module, ph20_tenant.module_dependency, ph20_tenant.tenant_module, ph20_tenant.tenant_feature_flag, ph20_tenant.tenant_platform_config, ph20_tenant.tenant_config_version, ph20_tenant.config_drift, ph20_tenant.provisioning_run, ph20_tenant.provisioning_step, ph20_tenant.smoke_test_result, ph20_tenant.tenant_quota, ph20_tenant.quota_change_request, ph20_tenant.quota_override, ph20_tenant.usage_snapshot, ph20_tenant.quota_alert, ph20_tenant.usage_report, ph20_tenant.lifecycle_request, ph20_tenant.tenant_status_history, ph20_tenant.data_export_package, ph20_tenant.data_export_item, ph20_tenant.merge_plan, ph20_tenant.merge_mapping, ph20_tenant.merge_participant_run, ph20_tenant.merge_conflict, ph20_tenant.product_release, ph20_tenant.release_component, ph20_tenant.tenant_release_subscription, ph20_tenant.upgrade_plan, ph20_tenant.upgrade_wave, ph20_tenant.tenant_upgrade, ph20_tenant.leak_test_run TO ph20_app;
-- Dữ liệu cấu hình, phiên bản, lịch sử, kế hoạch không xóa cứng: chỉ đổi trạng thái hoặc thay thế; dòng con của bản nháp, hàng đợi kỹ thuật mới được xóa.
REVOKE DELETE ON ph20_tenant.file_object, ph20_tenant.provisioning_template, ph20_tenant.tenant, ph20_tenant.organization, ph20_tenant.tenant_contact, ph20_tenant.tenant_contract, ph20_tenant.platform_module, ph20_tenant.module_dependency, ph20_tenant.tenant_module, ph20_tenant.tenant_feature_flag, ph20_tenant.tenant_platform_config, ph20_tenant.tenant_settings, ph20_tenant.tenant_config_version, ph20_tenant.config_drift, ph20_tenant.cross_tenant_policy, ph20_tenant.provisioning_run, ph20_tenant.provisioning_step, ph20_tenant.smoke_test_result, ph20_tenant.tenant_quota, ph20_tenant.quota_change_request, ph20_tenant.quota_override, ph20_tenant.quota_alert, ph20_tenant.usage_report, ph20_tenant.lifecycle_request, ph20_tenant.tenant_status_history, ph20_tenant.data_export_package, ph20_tenant.data_export_item, ph20_tenant.merge_plan, ph20_tenant.merge_mapping, ph20_tenant.merge_participant_run, ph20_tenant.merge_conflict, ph20_tenant.org_import_job, ph20_tenant.org_import_row, ph20_tenant.product_release, ph20_tenant.release_component, ph20_tenant.tenant_release_subscription, ph20_tenant.maintenance_window, ph20_tenant.upgrade_plan, ph20_tenant.upgrade_wave, ph20_tenant.tenant_upgrade, ph20_tenant.leak_test_run FROM ph20_app, ph20_platform_app;
-- Bảng chỉ thêm: không UPDATE, DELETE (trigger tg_append_only là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph20_owner.
REVOKE UPDATE, DELETE ON ph20_tenant.smoke_test_result, ph20_tenant.tenant_status_history FROM ph20_app, ph20_platform_app;
REVOKE EXECUTE ON PROCEDURE ph20_tenant.p_seed_platform(), ph20_tenant.p_init_tenant_quota(text, text), ph20_tenant.p_ensure_partitions(regclass, date, integer) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE ph20_tenant.p_init_tenant_quota(text, text) TO ph20_platform_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;

