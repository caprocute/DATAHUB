-- =============================================================================
-- D03-03-PH08 · DDL schema ph08_dq — PH-08 Chất lượng dữ liệu (Data Quality)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py (khung chép từ ph06); sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph08_dq.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: brief PH-08 §5, FRS PH-08 Phụ lục A. Không lưu giá trị gốc của trường Nhạy cảm:
-- chỉ masked_value (đã che) và value_hash (băm có khóa), CHECK ck_dq_finding_no_raw khóa quy tắc này.
-- Bản ghi lỗi, kết quả quy tắc, thống kê trực tuyến phân vùng theo tháng; bảng chỉ thêm có trigger chặn sửa, xóa.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 08-0000-bootstrap.sql
-- @changeset ph08-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_owner') THEN
    CREATE ROLE ph08_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_app') THEN
    CREATE ROLE ph08_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_readonly') THEN
    CREATE ROLE ph08_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_benchmark') THEN
    CREATE ROLE ph08_benchmark NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dq_reader') THEN
    CREATE ROLE dq_reader NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph08-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph08_dq AUTHORIZATION ph08_owner;
COMMENT ON SCHEMA ph08_dq IS 'PH-08 Chất lượng dữ liệu (dh-data, package vn.datahub.data.dq): miền, đối tượng đo, hồ sơ dữ liệu, bộ quy tắc có phiên bản, lần đo, kết quả, điểm, bản ghi lỗi có dấu vân tay, ngoại lệ, phiếu khắc phục, cảnh báo, báo cáo. Không lưu giá trị gốc trường Nhạy cảm.';
GRANT USAGE ON SCHEMA ph08_dq TO ph08_app, ph08_readonly, ph08_benchmark;
COMMENT ON ROLE dq_reader IS 'Vai chỉ đọc cho bộ thực thi đo (dq-worker): PH-06 cấp SELECT trên khung nhìn hợp đồng ph06_mdm.v_dq_{domain}; không có quyền gì trên ph08_dq và không đọc CSDL control (ADR đề xuất 087).';
COMMENT ON ROLE ph08_benchmark IS 'Vai so sánh liên tenant ẩn danh (FR-08-061): đọc điểm chiều của ảnh chụp chính thức qua khung nhìn v_benchmark_dimension, là ngoại lệ RLS duy nhất của PH-08; không đọc bảng khác.';
-- @rollback DROP SCHEMA IF EXISTS ph08_dq CASCADE;

SET ROLE ph08_owner;

-- @changeset ph08-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback empty

-- @file 08-0001-functions.sql
-- @changeset ph08-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph08_dq.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph08_dq.tg_touch();

-- @changeset ph08-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph08_dq.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph08_dq.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, kết quả đã chốt.';
-- @rollback DROP FUNCTION IF EXISTS ph08_dq.tg_immutable();

-- @changeset ph08-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph08_dq.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (dq_rule_result, dq_issue_activity). Dọn bằng DETACH, DROP phân vùng dưới ph08_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph08_dq.tg_append_only();

-- @changeset ph08-0013-fn-frozen splitStatements:false
-- Bất biến theo trạng thái: đối số đầu là danh sách trạng thái (cách nhau dấu phẩy), các đối số sau là cột không được đổi khi dòng cũ ở các trạng thái đó.
CREATE OR REPLACE FUNCTION ph08_dq.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
  frozen text[] := string_to_array(TG_ARGV[0], ',');
  i integer;
BEGIN
  IF OLD.status = ANY (frozen) THEN
    FOR i IN 2 .. TG_NARGS LOOP
      c := TG_ARGV[i - 1];
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Bản ghi % ở trạng thái % không sửa được cột %', TG_TABLE_NAME, OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_frozen() IS 'Phiên bản bộ quy tắc, cấu hình trọng số đã ACTIVE hoặc SUPERSEDED, báo cáo đã công bố không đổi nội dung; thay đổi cần phiên bản mới.';
-- @rollback DROP FUNCTION IF EXISTS ph08_dq.tg_frozen();

-- @changeset ph08-0014-fn-child-frozen splitStatements:false
-- Quy tắc con (dq_rule) chỉ ghi khi phiên bản cha là DRAFT.
CREATE OR REPLACE FUNCTION ph08_dq.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
  tn text;
  vid uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; vid := OLD.rule_set_version_id;
  ELSE
    tn := NEW.tenant_id; vid := NEW.rule_set_version_id;
  END IF;
  SELECT status INTO st FROM ph08_dq.dq_rule_set_version WHERE tenant_id = tn AND id = vid;
  IF st IS NOT NULL AND st <> 'DRAFT' THEN
    RAISE EXCEPTION 'Phiên bản bộ quy tắc ở trạng thái %: không sửa quy tắc con (cần phiên bản mới)', st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_child_frozen() IS 'Chặn thêm, sửa, xóa quy tắc khi phiên bản cha không phải DRAFT (FR-08-012, 017, 018).';
-- @rollback DROP FUNCTION IF EXISTS ph08_dq.tg_child_frozen();

-- @changeset ph08-0015-fn-rls splitStatements:false
-- Mẫu P: chỉ thấy, ghi dòng của tenant phiên (dạng Tnn). Mẫu S: thêm quyền đọc dòng COMMON, ghi COMMON chỉ khi phiên là PLATFORM (cách PH-07).
CREATE OR REPLACE PROCEDURE ph08_dq.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003).';

CREATE OR REPLACE PROCEDURE ph08_dq.p_enable_rls_shared(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  cur text := $c$current_setting('app.tenant_id', false)$c$;
  w text := format($w$((tenant_id = %s AND tenant_id ~ '^T[0-9]{2}$') OR (tenant_id = 'COMMON' AND %s = 'PLATFORM'))$w$, cur, cur);
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING (tenant_id IN (%s, ''COMMON''))', n, t, cur);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_enable_rls_shared(regclass) IS 'Mẫu RLS S cho bảng có dòng COMMON dùng chung (dq_rule_template).';
-- @rollback DROP PROCEDURE IF EXISTS ph08_dq.p_enable_rls_shared(regclass); DROP PROCEDURE IF EXISTS ph08_dq.p_enable_rls(regclass);

-- @changeset ph08-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph08_dq.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho dq_finding, dq_rule_result, dq_inline_stat. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph08_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph08_dq.p_ensure_partitions(regclass, date, integer);


-- @file 08-0010-asset.sql
-- @changeset ph08-0100-dq-domain
CREATE TABLE ph08_dq.dq_domain (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  domain_code           varchar(32) NOT NULL,
  name                  varchar(255) NOT NULL,
  description           varchar(2000),
  owner_org_code        varchar(63) NOT NULL,
  steward_user          varchar(64),
  status                varchar(16) NOT NULL DEFAULT 'ACTIVE',
  status_reason         varchar(2000),
  on_dependency_failure varchar(16) NOT NULL DEFAULT 'FAIL_OPEN',
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_domain PRIMARY KEY (id),
  CONSTRAINT uq_dq_domain_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_domain_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_domain_code UNIQUE (tenant_id, domain_code),
  CONSTRAINT ck_dq_domain_code CHECK (domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_dq_domain_owner CHECK (owner_org_code ~ '^[A-Za-z0-9][A-Za-z0-9._-]{1,62}$'),
  CONSTRAINT ck_dq_domain_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
  CONSTRAINT ck_dq_domain_failure CHECK (on_dependency_failure IN ('FAIL_OPEN', 'FAIL_CLOSED')),
  CONSTRAINT ck_dq_domain_reason CHECK (status <> 'INACTIVE' OR COALESCE(char_length(status_reason) >= 20, false))
);
CREATE TRIGGER tg_dq_domain_touch BEFORE UPDATE ON ph08_dq.dq_domain FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_domain_immutable BEFORE UPDATE ON ph08_dq.dq_domain FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'domain_code');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_domain');
COMMENT ON TABLE ph08_dq.dq_domain IS 'EN-08-01 Miền chất lượng dữ liệu: nhóm đối tượng đo theo lĩnh vực quản lý, gắn tổ chức chủ quản (DO) và cán bộ phụ trách (FR-08-001). Mang chế độ xử lý khi dịch vụ phụ thuộc lỗi lúc kiểm tra trực tuyến (FAIL_OPEN, FAIL_CLOSED). Không xóa, chỉ chuyển INACTIVE.';
COMMENT ON COLUMN ph08_dq.dq_domain.owner_org_code IS 'Mã tổ chức chủ quản (DO) ở PH-01; kiểm ở dịch vụ, không khóa ngoại liên schema.';
COMMENT ON COLUMN ph08_dq.dq_domain.on_dependency_failure IS 'FAIL_OPEN cho phép bản ghi đi tiếp khi PH-07, PH-05 không khả dụng; FAIL_CLOSED chặn (FR-08-031, 032).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_domain CASCADE;

-- @changeset ph08-0110-dq-asset
CREATE TABLE ph08_dq.dq_asset (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  domain_code           varchar(32) NOT NULL,
  asset_code            varchar(63) NOT NULL,
  name                  varchar(255) NOT NULL,
  asset_type            varchar(16) NOT NULL,
  status                varchar(16) NOT NULL DEFAULT 'DRAFT',
  status_reason         varchar(2000),
  owner_org_code        varchar(63) NOT NULL,
  mdm_domain_code       varchar(32),
  rdm_catalog_code      varchar(64),
  connection_id         uuid,
  object_name           varchar(255),
  flow_code             varchar(63),
  key_columns           varchar(63)[] NOT NULL DEFAULT '{}',
  default_scan_mode     varchar(16) NOT NULL DEFAULT 'FULL',
  sample_ratio          numeric(5,4),
  highest_data_class    varchar(16) NOT NULL DEFAULT 'INTERNAL',
  description           varchar(2000),
  incremental_enabled   boolean NOT NULL DEFAULT false,
  updated_at_field      varchar(63),
  inline_enabled        boolean NOT NULL DEFAULT false,
  inline_mode           varchar(10),
  on_dependency_failure varchar(16),
  inline_timeout_ms     smallint NOT NULL DEFAULT 40,
  gate_enabled          boolean NOT NULL DEFAULT false,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_asset PRIMARY KEY (id),
  CONSTRAINT uq_dq_asset_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_asset_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_asset_code UNIQUE (tenant_id, asset_code),
  CONSTRAINT fk_dq_asset_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_asset_code CHECK (asset_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_asset_type CHECK (asset_type IN ('MDM_DOMAIN', 'RDM_CATALOG', 'SOURCE_DATASET', 'FLOW_MESSAGE')),
  CONSTRAINT ck_dq_asset_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_dq_asset_scan_mode CHECK (default_scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_asset_class CHECK (highest_data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_dq_asset_ref CHECK ((asset_type = 'MDM_DOMAIN') = (mdm_domain_code IS NOT NULL) AND (asset_type = 'RDM_CATALOG') = (rdm_catalog_code IS NOT NULL) AND (asset_type = 'SOURCE_DATASET') = (connection_id IS NOT NULL AND object_name IS NOT NULL) AND (asset_type = 'FLOW_MESSAGE') = (flow_code IS NOT NULL)),
  CONSTRAINT ck_dq_asset_inline_mode CHECK (inline_mode IS NULL OR inline_mode IN ('STRICT', 'ADVISORY')),
  CONSTRAINT ck_dq_asset_inline_on CHECK (NOT inline_enabled OR inline_mode IS NOT NULL),
  CONSTRAINT ck_dq_asset_failure CHECK (on_dependency_failure IS NULL OR on_dependency_failure IN ('FAIL_OPEN', 'FAIL_CLOSED')),
  CONSTRAINT ck_dq_asset_timeout CHECK (inline_timeout_ms BETWEEN 10 AND 50),
  CONSTRAINT ck_dq_asset_gate CHECK (NOT gate_enabled OR (asset_type = 'MDM_DOMAIN' AND inline_enabled)),
  CONSTRAINT ck_dq_asset_incremental CHECK (NOT incremental_enabled OR (asset_type <> 'FLOW_MESSAGE' AND (asset_type <> 'SOURCE_DATASET' OR updated_at_field IS NOT NULL))),
  CONSTRAINT ck_dq_asset_updated_field CHECK (updated_at_field IS NULL OR updated_at_field ~ '^[A-Za-z_][A-Za-z0-9_]{0,62}$'),
  CONSTRAINT ck_dq_asset_sample CHECK ((default_scan_mode = 'SAMPLE') = (sample_ratio IS NOT NULL) AND (sample_ratio IS NULL OR (sample_ratio > 0 AND sample_ratio <= 1))),
  CONSTRAINT ck_dq_asset_reason CHECK (status NOT IN ('SUSPENDED', 'RETIRED') OR COALESCE(char_length(status_reason) >= 20, false))
);
CREATE INDEX ix_dq_asset_domain ON ph08_dq.dq_asset (tenant_id, domain_code, status);
CREATE INDEX ix_dq_asset_owner ON ph08_dq.dq_asset (tenant_id, owner_org_code, status);
CREATE INDEX ix_dq_asset_mdm ON ph08_dq.dq_asset (tenant_id, mdm_domain_code) WHERE mdm_domain_code IS NOT NULL;
CREATE INDEX ix_dq_asset_rdm ON ph08_dq.dq_asset (tenant_id, rdm_catalog_code) WHERE rdm_catalog_code IS NOT NULL;
CREATE TRIGGER tg_dq_asset_touch BEFORE UPDATE ON ph08_dq.dq_asset FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_asset_immutable BEFORE UPDATE ON ph08_dq.dq_asset FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_code', 'asset_type');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_asset');
COMMENT ON TABLE ph08_dq.dq_asset IS 'EN-08-02 Đối tượng đo chất lượng, bốn loại: miền dữ liệu chủ PH-06, danh mục PH-07, bảng hoặc khung nhìn nguồn qua kết nối PH-05 chỉ đọc, bản tin luồng PH-04 (FR-08-002, 003, 004, 006, 007). Cột tham chiếu bắt buộc đúng theo loại. Không xóa, chỉ ngừng hoặc khôi phục.';
COMMENT ON COLUMN ph08_dq.dq_asset.connection_id IS 'Mã kết nối PH-05 (tài khoản chỉ đọc, Q359, ADR-067); kiểm ở dịch vụ, không khóa ngoại.';
COMMENT ON COLUMN ph08_dq.dq_asset.mdm_domain_code IS 'Domain PH-06; đọc qua view hợp đồng chỉ đọc do PH-06 cấp, không đọc bảng nghiệp vụ.';
COMMENT ON COLUMN ph08_dq.dq_asset.highest_data_class IS 'Phân loại cao nhất trong các trường, lấy từ PH-09; điều khiển cách lưu giá trị lỗi.';
COMMENT ON COLUMN ph08_dq.dq_asset.incremental_enabled IS 'Bật đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025, API-08-130, 131); không áp cho FLOW_MESSAGE, SOURCE_DATASET cần updated_at_field.';
COMMENT ON COLUMN ph08_dq.dq_asset.inline_enabled IS 'Cấu hình kiểm tra trực tuyến của đối tượng (FR-08-032, 035): bật, chế độ STRICT hay ADVISORY, hành vi khi phụ thuộc lỗi (rỗng thì theo miền), ngân sách ms, cổng chất lượng cho PH-06.';
COMMENT ON COLUMN ph08_dq.dq_asset.gate_enabled IS 'Cổng chất lượng đầu vào cho PH-06, chỉ MDM_DOMAIN đã bật trực tuyến (FR-08-035).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_asset CASCADE;

-- @changeset ph08-0120-dq-asset-field
CREATE TABLE ph08_dq.dq_asset_field (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  asset_id              uuid NOT NULL,
  field_name            varchar(63) NOT NULL,
  label                 varchar(255),
  field_type            varchar(16) NOT NULL DEFAULT 'STRING',
  cde                   boolean NOT NULL DEFAULT false,
  data_class            varchar(16) NOT NULL DEFAULT 'INTERNAL',
  classification_status varchar(16) NOT NULL DEFAULT 'PROPOSED',
  value_mode            varchar(16) NOT NULL DEFAULT 'MASKED',
  rdm_catalog_code      varchar(64),
  sort_order            smallint NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_asset_field PRIMARY KEY (id),
  CONSTRAINT ck_dq_asset_field_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_asset_field_name UNIQUE (tenant_id, asset_id, field_name),
  CONSTRAINT fk_dq_asset_field_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_asset_field_name CHECK (field_name ~ '^[A-Za-z_][A-Za-z0-9_]{0,62}$'),
  CONSTRAINT ck_dq_asset_field_type CHECK (field_type IN ('STRING', 'INTEGER', 'DECIMAL', 'DATE', 'TIMESTAMP', 'BOOLEAN', 'CODE', 'JSON')),
  CONSTRAINT ck_dq_asset_field_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_dq_asset_field_classification CHECK (classification_status IN ('PROPOSED', 'CONFIRMED')),
  CONSTRAINT ck_dq_asset_field_mode CHECK (value_mode IN ('MASKED', 'HASH_ONLY', 'PLAIN')),
  CONSTRAINT ck_dq_asset_field_mode_class CHECK ((data_class <> 'SENSITIVE' OR value_mode = 'HASH_ONLY') AND (data_class <> 'RESTRICTED' OR value_mode <> 'PLAIN'))
);
CREATE INDEX ix_dq_asset_field_cde ON ph08_dq.dq_asset_field (tenant_id, asset_id) WHERE cde;
CREATE TRIGGER tg_dq_asset_field_touch BEFORE UPDATE ON ph08_dq.dq_asset_field FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_asset_field');
COMMENT ON TABLE ph08_dq.dq_asset_field IS 'EN-08-03 Trường của đối tượng đo, kèm cờ phần tử dữ liệu trọng yếu (CDE) và phân loại PH-09 (FR-08-005, 006, 009). Cột value_mode quyết định cách lưu giá trị lỗi: trường Nhạy cảm chỉ được băm, trường Hạn chế phải che.';
COMMENT ON COLUMN ph08_dq.dq_asset_field.value_mode IS 'MASKED lưu giá trị đã che, HASH_ONLY chỉ lưu băm, PLAIN chỉ cho PUBLIC, INTERNAL. SENSITIVE bắt buộc HASH_ONLY, RESTRICTED không được PLAIN (BR giá trị lỗi, FR-08-036).';
COMMENT ON COLUMN ph08_dq.dq_asset_field.cde IS 'Phần tử dữ liệu trọng yếu: lỗi CRITICAL bắt buộc ở CDE theo cấu hình (FR-08-005).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_asset_field CASCADE;

-- @changeset ph08-0130-dq-profile-run
CREATE TABLE ph08_dq.dq_profile_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  asset_id           uuid NOT NULL,
  status             varchar(16) NOT NULL DEFAULT 'QUEUED',
  scan_mode          varchar(16) NOT NULL DEFAULT 'SAMPLE',
  sample_rows        bigint,
  row_count          bigint,
  requested_by       varchar(64) NOT NULL,
  started_at         timestamptz,
  finished_at        timestamptz,
  source_snapshot_at timestamptz,
  error_code         varchar(16),
  error_message      varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_profile_run PRIMARY KEY (id),
  CONSTRAINT uq_dq_profile_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_profile_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_profile_run_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_profile_run_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED')),
  CONSTRAINT ck_dq_profile_run_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'EXTERNAL')),
  CONSTRAINT ck_dq_profile_run_done CHECK (status NOT IN ('SUCCEEDED', 'FAILED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_dq_profile_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_profile_run_asset ON ph08_dq.dq_profile_run (tenant_id, asset_id, created_at DESC);
CREATE TRIGGER tg_dq_profile_run_touch BEFORE UPDATE ON ph08_dq.dq_profile_run FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_profile_run');
COMMENT ON TABLE ph08_dq.dq_profile_run IS 'EN-08-04 Lần chạy hồ sơ dữ liệu (profiling) cho một đối tượng đo, theo mẫu hoặc toàn bộ (FR-08-008, 011). Kết quả theo cột ở dq_profile_column.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_profile_run CASCADE;

-- @changeset ph08-0140-dq-profile-column
CREATE TABLE ph08_dq.dq_profile_column (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  profile_run_id    uuid NOT NULL,
  asset_id          uuid NOT NULL,
  field_name        varchar(63) NOT NULL,
  inferred_type     varchar(16),
  sensitive         boolean NOT NULL DEFAULT false,
  row_count         bigint NOT NULL,
  null_count        bigint NOT NULL DEFAULT 0,
  empty_count       bigint NOT NULL DEFAULT 0,
  distinct_estimate bigint,
  min_masked        varchar(255),
  max_masked        varchar(255),
  quantiles         jsonb,
  top_values        jsonb NOT NULL DEFAULT '[]',
  pattern_stats     jsonb NOT NULL DEFAULT '[]',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_profile_column PRIMARY KEY (id),
  CONSTRAINT ck_dq_profile_column_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_profile_column UNIQUE (tenant_id, profile_run_id, field_name),
  CONSTRAINT fk_dq_profile_column_run FOREIGN KEY (tenant_id, profile_run_id) REFERENCES ph08_dq.dq_profile_run (tenant_id, id),
  CONSTRAINT ck_dq_profile_column_name CHECK (field_name ~ '^[A-Za-z_][A-Za-z0-9_]{0,62}$'),
  CONSTRAINT ck_dq_profile_column_counts CHECK (row_count >= 0 AND null_count >= 0 AND empty_count >= 0 AND null_count <= row_count),
  CONSTRAINT ck_dq_profile_column_sensitive CHECK (NOT sensitive OR (min_masked IS NULL AND max_masked IS NULL AND top_values = '[]'::jsonb))
);
CREATE INDEX ix_dq_profile_column_asset ON ph08_dq.dq_profile_column (tenant_id, asset_id, field_name);
CREATE TRIGGER tg_dq_profile_column_touch BEFORE UPDATE ON ph08_dq.dq_profile_column FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_profile_column');
COMMENT ON TABLE ph08_dq.dq_profile_column IS 'EN-08-05 Thống kê hồ sơ theo cột: số rỗng, số giá trị khác nhau ước lượng bằng HyperLogLog, phân vị (Apache DataSketches), mẫu định dạng thường gặp (FR-08-009, 010). Cột Nhạy cảm không lưu giá trị mẫu, nhỏ nhất, lớn nhất.';
COMMENT ON COLUMN ph08_dq.dq_profile_column.sensitive IS 'Sao chép từ dq_asset_field.value_mode = HASH_ONLY; khi true, CHECK cấm lưu giá trị mẫu.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_profile_column CASCADE;


-- @file 08-0020-rule.sql
-- @changeset ph08-0150-dq-rule-template
CREATE TABLE ph08_dq.dq_rule_template (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  template_code       varchar(64) NOT NULL,
  name                varchar(255) NOT NULL,
  dimension           varchar(16) NOT NULL,
  operator            varchar(24) NOT NULL,
  default_severity    varchar(8) NOT NULL DEFAULT 'MAJOR',
  params              jsonb NOT NULL DEFAULT '{}',
  expression_template text,
  description         varchar(2000),
  status              varchar(16) NOT NULL DEFAULT 'ACTIVE',
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_template PRIMARY KEY (id),
  CONSTRAINT ck_dq_rule_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_dq_rule_template_code UNIQUE (tenant_id, template_code),
  CONSTRAINT ck_dq_rule_template_code CHECK (template_code ~ '^[A-Z][A-Z0-9_-]{2,63}$'),
  CONSTRAINT ck_dq_rule_template_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_rule_template_operator CHECK (operator IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF', 'REGEX', 'LENGTH', 'RANGE', 'CHECKSUM', 'TYPE', 'EQ_SOURCE', 'EQ_FIELDS', 'CROSS_ENTITY', 'MAX_AGE_DAYS', 'UPDATED_AFTER', 'UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE', 'IN_RDM', 'IN_RDM_VERSION', 'CEL_EXPRESSION', 'SQL_PREDICATE')),
  CONSTRAINT ck_dq_rule_template_severity CHECK (default_severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_rule_template_status CHECK (status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_dq_rule_template_expr CHECK ((operator IN ('CEL_EXPRESSION', 'SQL_PREDICATE')) = (expression_template IS NOT NULL))
);
CREATE TRIGGER tg_dq_rule_template_touch BEFORE UPDATE ON ph08_dq.dq_rule_template FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls_shared('ph08_dq.dq_rule_template');
COMMENT ON TABLE ph08_dq.dq_rule_template IS 'EN-08-09 Quy tắc mẫu dùng lại: CCCD, mã số thuế, số điện thoại, email, đơn vị hành chính (FR-08-015). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S, cách PH-07); tenant có thể thêm mẫu riêng.';
COMMENT ON COLUMN ph08_dq.dq_rule_template.tenant_id IS 'Dạng Tnn hoặc COMMON (bộ mẫu dùng chung).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_template CASCADE;

-- @changeset ph08-0160-dq-weight-config
CREATE TABLE ph08_dq.dq_weight_config (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  config_code      varchar(63) NOT NULL,
  version_no       integer NOT NULL DEFAULT 1,
  domain_code      varchar(32),
  asset_id         uuid,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  w_completeness   numeric(5,4) NOT NULL DEFAULT 0.20,
  w_accuracy       numeric(5,4) NOT NULL DEFAULT 0.20,
  w_consistency    numeric(5,4) NOT NULL DEFAULT 0.15,
  w_timeliness     numeric(5,4) NOT NULL DEFAULT 0.10,
  w_uniqueness     numeric(5,4) NOT NULL DEFAULT 0.15,
  w_validity       numeric(5,4) NOT NULL DEFAULT 0.20,
  pass_min         numeric(5,2) NOT NULL DEFAULT 80,
  warn_min         numeric(5,2) NOT NULL DEFAULT 70,
  effective_from   timestamptz,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  change_note      varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_weight_config PRIMARY KEY (id),
  CONSTRAINT uq_dq_weight_config_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_weight_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_weight_config_version UNIQUE (tenant_id, config_code, version_no),
  CONSTRAINT fk_dq_weight_config_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_weight_config_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_weight_config_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'RETIRED')),
  CONSTRAINT ck_dq_weight_config_sum CHECK (abs(w_completeness + w_accuracy + w_consistency + w_timeliness + w_uniqueness + w_validity - 1.0) <= 0.001),
  CONSTRAINT ck_dq_weight_config_range CHECK (w_completeness >= 0 AND w_accuracy >= 0 AND w_consistency >= 0 AND w_timeliness >= 0 AND w_uniqueness >= 0 AND w_validity >= 0),
  CONSTRAINT ck_dq_weight_config_threshold CHECK (pass_min <= 100 AND warn_min >= 0 AND warn_min <= pass_min),
  CONSTRAINT ck_dq_weight_config_scope CHECK (asset_id IS NULL OR domain_code IS NULL),
  CONSTRAINT ck_dq_weight_config_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_dq_weight_config_active CHECK (status <> 'ACTIVE' OR activated_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_dq_weight_config_active ON ph08_dq.dq_weight_config (tenant_id, COALESCE(domain_code, ''), COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_dq_weight_config_touch BEFORE UPDATE ON ph08_dq.dq_weight_config FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_weight_config_immutable BEFORE UPDATE ON ph08_dq.dq_weight_config FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'config_code', 'version_no');
CREATE TRIGGER tg_dq_weight_config_frozen BEFORE UPDATE ON ph08_dq.dq_weight_config FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_frozen('ACTIVE,SUPERSEDED', 'w_completeness', 'w_accuracy', 'w_consistency', 'w_timeliness', 'w_uniqueness', 'w_validity', 'pass_min', 'warn_min');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_weight_config');
COMMENT ON TABLE ph08_dq.dq_weight_config IS 'EN-08-10 Cấu hình trọng số sáu chiều và ngưỡng điểm, có phiên bản và duyệt bốn mắt (FR-08-021, 028). Phạm vi tenant, miền hoặc đối tượng đo; mặc định 0,20/0,20/0,15/0,10/0,15/0,20. Tổng trọng số bằng 1,000 với dung sai 0,001.';
COMMENT ON COLUMN ph08_dq.dq_weight_config.w_completeness IS 'Cột w_* theo thứ tự COMPLETENESS, ACCURACY, CONSISTENCY, TIMELINESS, UNIQUENESS, VALIDITY.';
COMMENT ON COLUMN ph08_dq.dq_weight_config.pass_min IS 'Điểm từ ngưỡng này trở lên: PASS; từ warn_min: WARN; dưới: FAIL (mặc định 80 và 70, FR-08-021).';
COMMENT ON COLUMN ph08_dq.dq_weight_config.effective_from IS 'Thời điểm cấu hình có hiệu lực khi được duyệt; lần đo sau thời điểm này chấm theo cấu hình mới (FR-08-021).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_weight_config CASCADE;

-- @changeset ph08-0170-dq-rule-set
CREATE TABLE ph08_dq.dq_rule_set (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  set_code           varchar(63) NOT NULL,
  name               varchar(255) NOT NULL,
  asset_id           uuid NOT NULL,
  description        varchar(2000),
  current_version_no integer NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_set PRIMARY KEY (id),
  CONSTRAINT uq_dq_rule_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_rule_set_code UNIQUE (tenant_id, set_code),
  CONSTRAINT fk_dq_rule_set_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_code CHECK (set_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_rule_set_current CHECK (current_version_no >= 0)
);
CREATE INDEX ix_dq_rule_set_asset ON ph08_dq.dq_rule_set (tenant_id, asset_id);
CREATE TRIGGER tg_dq_rule_set_touch BEFORE UPDATE ON ph08_dq.dq_rule_set FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_set_immutable BEFORE UPDATE ON ph08_dq.dq_rule_set FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'set_code', 'asset_id');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule_set');
COMMENT ON TABLE ph08_dq.dq_rule_set IS 'EN-08-06 Bộ quy tắc của một đối tượng đo (FR-08-012, 018, 020, 022). Nội dung nằm ở các phiên bản dq_rule_set_version; mỗi bộ có đúng một phiên bản ACTIVE.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_set CASCADE;

-- @changeset ph08-0180-dq-rule-set-version
CREATE TABLE ph08_dq.dq_rule_set_version (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  rule_set_id          uuid NOT NULL,
  version_no           integer NOT NULL,
  status               varchar(20) NOT NULL DEFAULT 'DRAFT',
  weight_config_id     uuid,
  content_hash         bytea,
  rule_count           integer NOT NULL DEFAULT 0,
  change_note          varchar(2000),
  submitted_by         varchar(64),
  submitted_at         timestamptz,
  decision             varchar(8),
  decided_by           varchar(64),
  decided_at           timestamptz,
  decision_comment     varchar(2000),
  activated_at         timestamptz,
  superseded_at        timestamptz,
  effective_from       timestamptz,
  last_dry_run_id      uuid,
  dry_run_content_hash bytea,
  dry_run_at           timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_set_version PRIMARY KEY (id),
  CONSTRAINT uq_dq_rule_set_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_rule_set_version_no UNIQUE (tenant_id, rule_set_id, version_no),
  CONSTRAINT fk_dq_rule_set_version_set FOREIGN KEY (tenant_id, rule_set_id) REFERENCES ph08_dq.dq_rule_set (tenant_id, id),
  CONSTRAINT fk_dq_rule_set_version_weight FOREIGN KEY (tenant_id, weight_config_id) REFERENCES ph08_dq.dq_weight_config (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_dq_rule_set_version_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'ACTIVE', 'SUPERSEDED', 'RETIRED')),
  CONSTRAINT ck_dq_rule_set_version_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32),
  CONSTRAINT ck_dq_rule_set_version_dry_hash CHECK (dry_run_content_hash IS NULL OR octet_length(dry_run_content_hash) = 32),
  CONSTRAINT ck_dq_rule_set_version_dry_run CHECK (status NOT IN ('PENDING_APPROVAL', 'APPROVED', 'ACTIVE') OR (dry_run_content_hash IS NOT NULL AND dry_run_at IS NOT NULL)),
  CONSTRAINT ck_dq_rule_set_version_approved CHECK (status <> 'APPROVED' OR (decision = 'APPROVE' AND effective_from IS NOT NULL)),
  CONSTRAINT ck_dq_rule_set_version_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_dq_rule_set_version_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_dq_rule_set_version_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decision = 'APPROVE' AND content_hash IS NOT NULL AND rule_count > 0)),
  CONSTRAINT ck_dq_rule_set_version_reject CHECK (decision IS DISTINCT FROM 'REJECT' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_dq_rule_set_version_active ON ph08_dq.dq_rule_set_version (tenant_id, rule_set_id) WHERE status = 'ACTIVE';
CREATE INDEX ix_dq_rule_set_version_status ON ph08_dq.dq_rule_set_version (tenant_id, status, submitted_at);
CREATE TRIGGER tg_dq_rule_set_version_touch BEFORE UPDATE ON ph08_dq.dq_rule_set_version FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_set_version_immutable BEFORE UPDATE ON ph08_dq.dq_rule_set_version FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'rule_set_id', 'version_no');
CREATE TRIGGER tg_dq_rule_set_version_frozen BEFORE UPDATE ON ph08_dq.dq_rule_set_version FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_frozen('APPROVED,ACTIVE,SUPERSEDED', 'weight_config_id', 'content_hash', 'rule_count', 'dry_run_content_hash');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule_set_version');
COMMENT ON TABLE ph08_dq.dq_rule_set_version IS 'EN-08-07 Phiên bản bộ quy tắc, vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, duyệt bốn mắt (FR-08-012, 017, 018, 019). Phiên bản ACTIVE hoặc SUPERSEDED bất biến; quy tắc con chỉ sửa khi phiên bản là DRAFT.';
COMMENT ON COLUMN ph08_dq.dq_rule_set_version.content_hash IS 'SHA-256 nội dung quy tắc tại lúc gửi duyệt; ACTIVE bắt buộc có (bất biến, FR-08-018, 019).';
COMMENT ON COLUMN ph08_dq.dq_rule_set_version.rule_count IS 'Số quy tắc; ACTIVE phải lớn hơn 0.';
COMMENT ON COLUMN ph08_dq.dq_rule_set_version.dry_run_content_hash IS 'Băm phần nội dung ảnh hưởng kết quả đo tại lần chạy thử cuối (FR-08-016); gửi duyệt cần bằng content_hash. Sửa tên, mô tả, thông điệp quy tắc không đổi băm này.';
COMMENT ON COLUMN ph08_dq.dq_rule_set_version.effective_from IS 'Giờ hiệu lực khi duyệt; tương lai thì APPROVED chờ kích hoạt, hiện tại thì ACTIVE ngay (FR-08-017, 018).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_set_version CASCADE;

-- @changeset ph08-0190-dq-rule
CREATE TABLE ph08_dq.dq_rule (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  rule_set_version_id uuid NOT NULL,
  rule_code           varchar(63) NOT NULL,
  name                varchar(255) NOT NULL,
  description         varchar(2000),
  dimension           varchar(16) NOT NULL,
  operator            varchar(24) NOT NULL,
  severity            varchar(8) NOT NULL DEFAULT 'MAJOR',
  exec_mode           varchar(8) NOT NULL DEFAULT 'BATCH',
  inline_mode         varchar(10),
  field_name          varchar(63),
  params              jsonb NOT NULL DEFAULT '{}',
  expression          text,
  message             varchar(500),
  weight              numeric(6,3) NOT NULL DEFAULT 1,
  template_code       varchar(64),
  enabled             boolean NOT NULL DEFAULT true,
  source              varchar(12) NOT NULL DEFAULT 'MANUAL',
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule PRIMARY KEY (id),
  CONSTRAINT uq_dq_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_rule_code UNIQUE (tenant_id, rule_set_version_id, rule_code),
  CONSTRAINT fk_dq_rule_version FOREIGN KEY (tenant_id, rule_set_version_id) REFERENCES ph08_dq.dq_rule_set_version (tenant_id, id),
  CONSTRAINT ck_dq_rule_code CHECK (rule_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_rule_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_rule_operator CHECK (operator IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF', 'REGEX', 'LENGTH', 'RANGE', 'CHECKSUM', 'TYPE', 'EQ_SOURCE', 'EQ_FIELDS', 'CROSS_ENTITY', 'MAX_AGE_DAYS', 'UPDATED_AFTER', 'UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE', 'IN_RDM', 'IN_RDM_VERSION', 'CEL_EXPRESSION', 'SQL_PREDICATE')),
  CONSTRAINT ck_dq_rule_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_rule_exec CHECK (exec_mode IN ('BATCH', 'INLINE', 'BOTH')),
  CONSTRAINT ck_dq_rule_inline CHECK ((exec_mode = 'BATCH') = (inline_mode IS NULL) AND (inline_mode IS NULL OR inline_mode IN ('STRICT', 'ADVISORY'))),
  CONSTRAINT ck_dq_rule_operator_dimension CHECK ((operator NOT IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF') OR dimension = 'COMPLETENESS') AND (operator NOT IN ('UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE') OR dimension = 'UNIQUENESS') AND (operator NOT IN ('IN_RDM', 'IN_RDM_VERSION') OR dimension = 'VALIDITY') AND (operator NOT IN ('MAX_AGE_DAYS', 'UPDATED_AFTER') OR dimension = 'TIMELINESS')),
  CONSTRAINT ck_dq_rule_expression CHECK ((operator IN ('CEL_EXPRESSION', 'SQL_PREDICATE')) = (expression IS NOT NULL)),
  CONSTRAINT ck_dq_rule_sql_batch CHECK (operator <> 'SQL_PREDICATE' OR exec_mode = 'BATCH'),
  CONSTRAINT ck_dq_rule_rdm CHECK (operator NOT IN ('IN_RDM', 'IN_RDM_VERSION') OR params ? 'catalogCode'),
  CONSTRAINT ck_dq_rule_weight CHECK (weight > 0),
  CONSTRAINT ck_dq_rule_source CHECK (source IN ('MANUAL', 'TEMPLATE', 'SUGGESTED', 'IMPORTED', 'COPIED') AND (source <> 'TEMPLATE' OR template_code IS NOT NULL))
);
CREATE INDEX ix_dq_rule_version ON ph08_dq.dq_rule (tenant_id, rule_set_version_id, dimension);
CREATE INDEX ix_dq_rule_inline ON ph08_dq.dq_rule (tenant_id, rule_set_version_id) WHERE exec_mode <> 'BATCH' AND enabled;
CREATE TRIGGER tg_dq_rule_touch BEFORE UPDATE ON ph08_dq.dq_rule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph08_dq.dq_rule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_child_frozen();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule');
COMMENT ON TABLE ph08_dq.dq_rule IS 'EN-08-08 Quy tắc chất lượng: chiều, toán tử, mức nghiêm trọng, chế độ chạy (lô, trực tuyến, cả hai) và tham số (FR-08-013, 014, 016, 022). Biểu thức CEL hoặc vị từ SQL có kiểm soát nằm ở cột expression; vị từ SQL chỉ chạy theo lô.';
COMMENT ON COLUMN ph08_dq.dq_rule.message IS 'Thông điệp hiển thị ở bản ghi lỗi khi quy tắc không đạt (thay cột thong_diep của SRS cũ).';
COMMENT ON COLUMN ph08_dq.dq_rule.source IS 'Nguồn gốc quy tắc: nhập tay, từ quy tắc mẫu, gợi ý từ hồ sơ, nhập tệp, sao chép (FR-08-010, 015, 020).';
COMMENT ON COLUMN ph08_dq.dq_rule.inline_mode IS 'STRICT chặn bản ghi lỗi, ADVISORY chỉ cảnh báo; rỗng khi exec_mode = BATCH (FR-08-032, 033).';
COMMENT ON COLUMN ph08_dq.dq_rule.operator IS '19 toán tử theo FRS; ràng buộc operator_dimension khóa quan hệ toán tử với chiều (ví dụ IN_RDM chỉ thuộc VALIDITY).';
COMMENT ON COLUMN ph08_dq.dq_rule.expression IS 'CEL (cel-java) hoặc vị từ SQL có kiểm soát; chỉ khi operator là CEL_EXPRESSION hoặc SQL_PREDICATE (FR-08-014).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_rule CASCADE;


-- @file 08-0030-scan.sql
-- @changeset ph08-0200-dq-schedule
CREATE TABLE ph08_dq.dq_schedule (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  schedule_code varchar(63) NOT NULL,
  domain_code   varchar(32),
  asset_id      uuid,
  cron          varchar(64) NOT NULL DEFAULT '0 0 2 1 * ?',
  timezone      varchar(40) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  scan_mode     varchar(16) NOT NULL DEFAULT 'FULL',
  enabled       boolean NOT NULL DEFAULT true,
  next_run_at   timestamptz,
  last_run_at   timestamptz,
  last_job_id   uuid,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_schedule PRIMARY KEY (id),
  CONSTRAINT uq_dq_schedule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_schedule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_schedule_code UNIQUE (tenant_id, schedule_code),
  CONSTRAINT fk_dq_schedule_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_schedule_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_schedule_code CHECK (schedule_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_schedule_scope CHECK (asset_id IS NULL OR domain_code IS NULL),
  CONSTRAINT ck_dq_schedule_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_schedule_cron CHECK (cron ~ '^[-0-9*/,?LW#A-Za-z]+( [-0-9*/,?LW#A-Za-z]+){5,6}$')
);
CREATE INDEX ix_dq_schedule_next ON ph08_dq.dq_schedule (next_run_at) WHERE enabled;
CREATE TRIGGER tg_dq_schedule_touch BEFORE UPDATE ON ph08_dq.dq_schedule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_schedule');
COMMENT ON TABLE ph08_dq.dq_schedule IS 'EN-08-11 Lịch đo theo lô bằng biểu thức cron (FR-08-023). Phạm vi là một đối tượng, một miền hoặc cả tenant; mặc định ngày 1 hằng tháng lúc 02:00. Lập lịch chạy bằng Quartz có ShedLock.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_schedule CASCADE;

-- @changeset ph08-0210-dq-scan-job
CREATE TABLE ph08_dq.dq_scan_job (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  asset_id            uuid NOT NULL,
  rule_set_version_id uuid NOT NULL,
  weight_config_id    uuid,
  schedule_id         uuid,
  scan_trigger        varchar(12) NOT NULL,
  scan_mode           varchar(16) NOT NULL,
  status              varchar(12) NOT NULL DEFAULT 'QUEUED',
  period_code         varchar(7) NOT NULL,
  requested_by        varchar(64) NOT NULL,
  idempotency_key     varchar(64),
  verify_issue_id     uuid,
  source_event_id     uuid,
  rerun_of            uuid,
  source_snapshot_at  timestamptz,
  started_at          timestamptz,
  finished_at         timestamptz,
  task_total          integer NOT NULL DEFAULT 0,
  task_done           integer NOT NULL DEFAULT 0,
  rows_scanned        bigint NOT NULL DEFAULT 0,
  rows_failed         bigint NOT NULL DEFAULT 0,
  skipped_rules       integer NOT NULL DEFAULT 0,
  sample_size         integer,
  sample_seed         bigint,
  error_code          varchar(16),
  error_message       varchar(2000),
  cancel_reason       varchar(2000),
  flags               varchar(32)[] NOT NULL DEFAULT '{}',
  idempotency_hash    bytea,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_scan_job PRIMARY KEY (id),
  CONSTRAINT uq_dq_scan_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_scan_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_scan_job_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_version FOREIGN KEY (tenant_id, rule_set_version_id) REFERENCES ph08_dq.dq_rule_set_version (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_weight FOREIGN KEY (tenant_id, weight_config_id) REFERENCES ph08_dq.dq_weight_config (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_schedule FOREIGN KEY (tenant_id, schedule_id) REFERENCES ph08_dq.dq_schedule (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_rerun FOREIGN KEY (tenant_id, rerun_of) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_scan_job_trigger CHECK (scan_trigger IN ('SCHEDULE', 'MANUAL', 'EVENT', 'ANNUAL', 'VERIFY')),
  CONSTRAINT ck_dq_scan_job_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_scan_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_dq_scan_job_period CHECK (period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$'),
  CONSTRAINT ck_dq_scan_job_annual_full CHECK (scan_trigger <> 'ANNUAL' OR (scan_mode = 'FULL' AND period_code ~ '^[0-9]{4}$')),
  CONSTRAINT ck_dq_scan_job_verify CHECK ((scan_trigger = 'VERIFY') = (verify_issue_id IS NOT NULL)),
  CONSTRAINT ck_dq_scan_job_event CHECK ((scan_trigger = 'EVENT') = (source_event_id IS NOT NULL) AND (scan_trigger <> 'EVENT' OR scan_mode = 'INCREMENTAL')),
  CONSTRAINT ck_dq_scan_job_done CHECK (status NOT IN ('SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_dq_scan_job_cancel CHECK (status <> 'CANCELLED' OR COALESCE(char_length(cancel_reason) >= 20, false)),
  CONSTRAINT ck_dq_scan_job_progress CHECK (task_done >= 0 AND task_done <= task_total AND rows_scanned >= 0 AND rows_failed >= 0 AND rows_failed <= rows_scanned),
  CONSTRAINT ck_dq_scan_job_sample CHECK ((scan_mode = 'SAMPLE') = (sample_size IS NOT NULL) AND (sample_size IS NULL OR sample_size > 0)),
  CONSTRAINT ck_dq_scan_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$'),
  CONSTRAINT ck_dq_scan_job_flags CHECK (flags <@ ARRAY['INCOMPLETE_DIMENSIONS', 'WEIGHTS_CHANGED', 'TRUNCATED', 'INCREMENTAL']::varchar[]),
  CONSTRAINT ck_dq_scan_job_idem CHECK ((idempotency_key IS NULL) = (idempotency_hash IS NULL) AND (idempotency_hash IS NULL OR octet_length(idempotency_hash) = 32))
);
CREATE UNIQUE INDEX uq_dq_scan_job_running ON ph08_dq.dq_scan_job (tenant_id, asset_id) WHERE status = 'RUNNING';
CREATE UNIQUE INDEX uq_dq_scan_job_idem ON ph08_dq.dq_scan_job (tenant_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX ix_dq_scan_job_asset ON ph08_dq.dq_scan_job (tenant_id, asset_id, created_at DESC);
CREATE INDEX ix_dq_scan_job_period ON ph08_dq.dq_scan_job (tenant_id, period_code, status);
CREATE INDEX ix_dq_scan_job_queue ON ph08_dq.dq_scan_job (tenant_id, created_at) WHERE status IN ('QUEUED', 'RUNNING');
CREATE TRIGGER tg_dq_scan_job_touch BEFORE UPDATE ON ph08_dq.dq_scan_job FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_scan_job_immutable BEFORE UPDATE ON ph08_dq.dq_scan_job FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_id', 'rule_set_version_id', 'scan_trigger', 'scan_mode', 'period_code');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_scan_job');
COMMENT ON TABLE ph08_dq.dq_scan_job IS 'EN-08-12 Lần đo chất lượng của một đối tượng đo với một phiên bản bộ quy tắc (FR-08-023…026, 030, 031). Kích hoạt theo lịch, thủ công, sự kiện, hằng năm (bắt buộc đo đủ) hoặc đo lại kiểm chứng phiếu khắc phục. Mỗi đối tượng chỉ một lần đo đang chạy.';
COMMENT ON COLUMN ph08_dq.dq_scan_job.sample_seed IS 'Hạt giống lấy mẫu để tái lập kết quả khi đo SAMPLE (SRS cũ EN-08-04).';
COMMENT ON COLUMN ph08_dq.dq_scan_job.flags IS 'Cờ lần đo: TRUNCATED (vượt trần bản ghi lỗi), INCREMENTAL, INCOMPLETE_DIMENSIONS, WEIGHTS_CHANGED; sao sang ảnh chụp điểm (FR-08-026, 031).';
COMMENT ON COLUMN ph08_dq.dq_scan_job.idempotency_hash IS 'SHA-256 thân yêu cầu; cùng Idempotency-Key mà băm khác thì trả ERR-08-055 (409), cùng băm thì trả lại lần đo cũ.';
COMMENT ON COLUMN ph08_dq.dq_scan_job.verify_issue_id IS 'Phiếu khắc phục cần kiểm chứng (trigger VERIFY, FR-08-044); khóa ngoại nằm ở dq_issue.verify_scan_job_id.';
COMMENT ON COLUMN ph08_dq.dq_scan_job.period_code IS 'Kỳ đo: YYYY-MM (tháng) hoặc YYYY (đo chính thức hằng năm, FR-08-054).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_scan_job CASCADE;

-- @changeset ph08-0220-dq-scan-task
CREATE TABLE ph08_dq.dq_scan_task (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  scan_job_id  uuid NOT NULL,
  shard_no     integer NOT NULL,
  shard_count  integer NOT NULL,
  status       varchar(12) NOT NULL DEFAULT 'QUEUED',
  key_from     varchar(255),
  key_to       varchar(255),
  attempt      smallint NOT NULL DEFAULT 0,
  worker_id    varchar(64),
  rows_scanned bigint NOT NULL DEFAULT 0,
  rows_failed  bigint NOT NULL DEFAULT 0,
  started_at   timestamptz,
  finished_at  timestamptz,
  error_code   varchar(16),
  heartbeat_at timestamptz,
  not_before   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_scan_task PRIMARY KEY (id),
  CONSTRAINT uq_dq_scan_task_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_scan_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_scan_task_shard UNIQUE (tenant_id, scan_job_id, shard_no),
  CONSTRAINT fk_dq_scan_task_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_scan_task_shard CHECK (shard_no >= 0 AND shard_no < shard_count),
  CONSTRAINT ck_dq_scan_task_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_dq_scan_task_attempt CHECK (attempt >= 0 AND attempt <= 10),
  CONSTRAINT ck_dq_scan_task_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$'),
  CONSTRAINT ck_dq_scan_task_running CHECK (status <> 'RUNNING' OR (worker_id IS NOT NULL AND heartbeat_at IS NOT NULL))
);
CREATE INDEX ix_dq_scan_task_job ON ph08_dq.dq_scan_task (tenant_id, scan_job_id, status);
CREATE INDEX ix_dq_scan_task_heartbeat ON ph08_dq.dq_scan_task (heartbeat_at) WHERE status = 'RUNNING';
CREATE INDEX ix_dq_scan_task_queue ON ph08_dq.dq_scan_task (tenant_id, not_before NULLS FIRST, created_at) WHERE status = 'QUEUED';
CREATE TRIGGER tg_dq_scan_task_touch BEFORE UPDATE ON ph08_dq.dq_scan_task FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_scan_task');
COMMENT ON TABLE ph08_dq.dq_scan_task IS 'EN-08-13 Tác vụ phân mảnh của lần đo: mỗi mảnh là một khoảng khóa của đối tượng, chạy độc lập, thử lại được (FR-08-026, 030). Dọn sau 90 ngày.';
COMMENT ON COLUMN ph08_dq.dq_scan_task.heartbeat_at IS 'Nhịp cuối của bộ thực thi; quá 08.scan.heartbeat-timeout-seconds thì ScanWatchdog thu hồi tác vụ.';
COMMENT ON COLUMN ph08_dq.dq_scan_task.not_before IS 'Không giao tác vụ trước thời điểm này (lùi thử lại, cửa sổ giờ đo).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_scan_task CASCADE;

-- @changeset ph08-0230-dq-rule-result
CREATE TABLE ph08_dq.dq_rule_result (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  executed_at    timestamptz NOT NULL DEFAULT now(),
  scan_job_id    uuid NOT NULL,
  scan_task_id   uuid,
  asset_id       uuid NOT NULL,
  rule_id        uuid NOT NULL,
  dimension      varchar(16) NOT NULL,
  severity       varchar(8) NOT NULL,
  status         varchar(8) NOT NULL,
  rows_evaluated bigint NOT NULL DEFAULT 0,
  rows_failed    bigint NOT NULL DEFAULT 0,
  pass_rate      numeric(7,6),
  skip_reason    varchar(32),
  error_code     varchar(16),
  duration_ms    integer,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_result PRIMARY KEY (id, executed_at),
  CONSTRAINT ck_dq_rule_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_rule_result_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT fk_dq_rule_result_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT ck_dq_rule_result_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_rule_result_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_rule_result_status CHECK (status IN ('PASSED', 'FAILED', 'SKIPPED', 'ERROR')),
  CONSTRAINT ck_dq_rule_result_counts CHECK (rows_evaluated >= 0 AND rows_failed >= 0 AND rows_failed <= rows_evaluated),
  CONSTRAINT ck_dq_rule_result_rate CHECK (pass_rate IS NULL OR (pass_rate >= 0 AND pass_rate <= 1)),
  CONSTRAINT ck_dq_rule_result_skipped CHECK ((status = 'SKIPPED') = (skip_reason IS NOT NULL)),
  CONSTRAINT ck_dq_rule_result_skip_reason CHECK (skip_reason IS NULL OR skip_reason IN ('DEPENDENCY_UNAVAILABLE', 'RDM_UNAVAILABLE', 'SOURCE_UNREACHABLE', 'NO_DATA', 'TIMEOUT')),
  CONSTRAINT ck_dq_rule_result_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
) PARTITION BY RANGE (executed_at);
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_rule_result', current_date, 3);
CREATE INDEX ix_dq_rule_result_job ON ph08_dq.dq_rule_result (tenant_id, scan_job_id, dimension);
CREATE INDEX ix_dq_rule_result_rule ON ph08_dq.dq_rule_result (tenant_id, rule_id, executed_at DESC);
CREATE INDEX ix_dq_rule_result_asset ON ph08_dq.dq_rule_result (tenant_id, asset_id, executed_at DESC);
CREATE TRIGGER tg_dq_rule_result_touch BEFORE UPDATE ON ph08_dq.dq_rule_result FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_result_append_only BEFORE UPDATE OR DELETE ON ph08_dq.dq_rule_result FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_append_only();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule_result');
COMMENT ON TABLE ph08_dq.dq_rule_result IS 'EN-08-14 Kết quả từng quy tắc trong một lần đo: số dòng xét, số dòng lỗi, tỷ lệ đạt, trạng thái PASSED, FAILED, SKIPPED, ERROR (FR-08-026, 027, 028, 031). Ghi một lần, không sửa. Phân vùng tháng theo executed_at.';
COMMENT ON COLUMN ph08_dq.dq_rule_result.pass_rate IS '1 - rows_failed / rows_evaluated; rỗng khi SKIPPED hoặc ERROR.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_result CASCADE;

-- @changeset ph08-0240-dq-score-snapshot
CREATE TABLE ph08_dq.dq_score_snapshot (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  scan_job_id         uuid NOT NULL,
  asset_id            uuid NOT NULL,
  domain_code         varchar(32) NOT NULL,
  owner_org_code      varchar(63) NOT NULL,
  period_code         varchar(7) NOT NULL,
  scan_mode           varchar(16) NOT NULL,
  score               numeric(5,2) NOT NULL,
  verdict             varchar(4) NOT NULL,
  trend               varchar(10) NOT NULL DEFAULT 'BASELINE',
  flags               varchar(32)[] NOT NULL DEFAULT '{}',
  prev_snapshot_id    uuid,
  prev_score          numeric(5,2),
  delta               numeric(6,2),
  weight_config_id    uuid,
  rule_set_version_id uuid NOT NULL,
  row_count           bigint NOT NULL DEFAULT 0,
  official            boolean NOT NULL DEFAULT false,
  measured_at         timestamptz NOT NULL DEFAULT now(),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_score_snapshot PRIMARY KEY (id),
  CONSTRAINT uq_dq_score_snapshot_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_score_snapshot_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_score_snapshot_job UNIQUE (tenant_id, scan_job_id),
  CONSTRAINT fk_dq_score_snapshot_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT fk_dq_score_snapshot_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_score_snapshot_prev FOREIGN KEY (tenant_id, prev_snapshot_id) REFERENCES ph08_dq.dq_score_snapshot (tenant_id, id),
  CONSTRAINT ck_dq_score_snapshot_score CHECK (score >= 0 AND score <= 100),
  CONSTRAINT ck_dq_score_snapshot_verdict CHECK (verdict IN ('PASS', 'WARN', 'FAIL')),
  CONSTRAINT ck_dq_score_snapshot_trend CHECK (trend IN ('BASELINE', 'IMPROVED', 'STABLE', 'DEGRADED')),
  CONSTRAINT ck_dq_score_snapshot_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_score_snapshot_flags CHECK (flags <@ ARRAY['INCOMPLETE_DIMENSIONS', 'WEIGHTS_CHANGED', 'TRUNCATED', 'INCREMENTAL']::varchar[]),
  CONSTRAINT ck_dq_score_snapshot_period CHECK (period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$'),
  CONSTRAINT ck_dq_score_snapshot_baseline CHECK ((trend = 'BASELINE') = (prev_snapshot_id IS NULL)),
  CONSTRAINT ck_dq_score_snapshot_official CHECK (NOT official OR (scan_mode = 'FULL' AND NOT (flags && ARRAY['INCOMPLETE_DIMENSIONS']::varchar[])))
);
CREATE INDEX ix_dq_score_snapshot_asset ON ph08_dq.dq_score_snapshot (tenant_id, asset_id, period_code, measured_at DESC);
CREATE INDEX ix_dq_score_snapshot_domain ON ph08_dq.dq_score_snapshot (tenant_id, domain_code, period_code);
CREATE INDEX ix_dq_score_snapshot_org ON ph08_dq.dq_score_snapshot (tenant_id, owner_org_code, period_code);
CREATE INDEX ix_dq_score_snapshot_official ON ph08_dq.dq_score_snapshot (tenant_id, period_code, asset_id) WHERE official;
CREATE TRIGGER tg_dq_score_snapshot_touch BEFORE UPDATE ON ph08_dq.dq_score_snapshot FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_score_snapshot_immutable BEFORE UPDATE ON ph08_dq.dq_score_snapshot FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'scan_job_id', 'asset_id', 'period_code', 'score', 'verdict', 'flags', 'official');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_score_snapshot');
COMMENT ON TABLE ph08_dq.dq_score_snapshot IS 'EN-08-15 Snapshot điểm chất lượng của một đối tượng trong một kỳ: điểm có trọng số, kết luận PASS, WARN, FAIL, xu hướng so kỳ trước, cờ thiếu chiều hoặc đổi trọng số (FR-08-028, 029, 031, 051). Snapshot chính thức (official) phải từ lần đo đủ và không thiếu chiều.';
COMMENT ON COLUMN ph08_dq.dq_score_snapshot.official IS 'Dùng cho báo cáo chính thức hằng năm (FR-08-054): chỉ khi đo FULL và không có cờ INCOMPLETE_DIMENSIONS.';
COMMENT ON COLUMN ph08_dq.dq_score_snapshot.flags IS 'INCOMPLETE_DIMENSIONS: thiếu chiều do SKIPPED; WEIGHTS_CHANGED: trọng số đổi so với kỳ trước.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_score_snapshot CASCADE;

-- @changeset ph08-0250-dq-score-dimension
CREATE TABLE ph08_dq.dq_score_dimension (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  snapshot_id   uuid NOT NULL,
  dimension     varchar(16) NOT NULL,
  status        varchar(10) NOT NULL DEFAULT 'MEASURED',
  score         numeric(5,2),
  weight        numeric(5,4) NOT NULL,
  rules_total   integer NOT NULL DEFAULT 0,
  rules_passed  integer NOT NULL DEFAULT 0,
  rules_failed  integer NOT NULL DEFAULT 0,
  rules_skipped integer NOT NULL DEFAULT 0,
  rows_failed   bigint NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_score_dimension PRIMARY KEY (id),
  CONSTRAINT uq_dq_score_dimension_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_score_dimension_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_score_dimension UNIQUE (tenant_id, snapshot_id, dimension),
  CONSTRAINT fk_dq_score_dimension_snapshot FOREIGN KEY (tenant_id, snapshot_id) REFERENCES ph08_dq.dq_score_snapshot (tenant_id, id),
  CONSTRAINT ck_dq_score_dimension_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_score_dimension_status CHECK (status IN ('MEASURED', 'SKIPPED')),
  CONSTRAINT ck_dq_score_dimension_score CHECK ((status = 'SKIPPED') = (score IS NULL) AND (score IS NULL OR (score >= 0 AND score <= 100))),
  CONSTRAINT ck_dq_score_dimension_weight CHECK (weight >= 0 AND weight <= 1),
  CONSTRAINT ck_dq_score_dimension_counts CHECK (rules_total >= 0 AND rules_passed + rules_failed + rules_skipped <= rules_total)
);
CREATE TRIGGER tg_dq_score_dimension_touch BEFORE UPDATE ON ph08_dq.dq_score_dimension FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_score_dimension_immutable BEFORE UPDATE ON ph08_dq.dq_score_dimension FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'snapshot_id', 'dimension', 'score', 'status');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_score_dimension');
COMMENT ON TABLE ph08_dq.dq_score_dimension IS 'EN-08-16 Điểm theo từng chiều trong snapshot, kèm trọng số đã áp và số quy tắc đạt, lỗi, bỏ qua (FR-08-028, 029). Chiều bị bỏ qua có điểm rỗng.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_score_dimension CASCADE;

-- @changeset ph08-0260-dq-incremental-buffer
CREATE TABLE ph08_dq.dq_incremental_buffer (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  asset_id     uuid NOT NULL,
  window_start timestamptz NOT NULL,
  window_end   timestamptz NOT NULL,
  status       varchar(12) NOT NULL DEFAULT 'COLLECTING',
  keys         text[] NOT NULL DEFAULT '{}',
  event_count  integer NOT NULL DEFAULT 0,
  scan_job_id  uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_incremental_buffer PRIMARY KEY (id),
  CONSTRAINT uq_dq_incremental_buffer_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_incremental_buffer_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_incremental_buffer_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_incremental_buffer_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_incremental_buffer_status CHECK (status IN ('COLLECTING', 'OVERFLOW', 'SCHEDULED', 'DONE')),
  CONSTRAINT ck_dq_incremental_buffer_window CHECK (window_end > window_start),
  CONSTRAINT ck_dq_incremental_buffer_keys CHECK (cardinality(keys) <= 100000 AND event_count >= 0),
  CONSTRAINT ck_dq_incremental_buffer_scheduled CHECK (status NOT IN ('SCHEDULED', 'DONE') OR scan_job_id IS NOT NULL)
);
CREATE UNIQUE INDEX uq_dq_incremental_buffer_open ON ph08_dq.dq_incremental_buffer (tenant_id, asset_id) WHERE status = 'COLLECTING';
CREATE INDEX ix_dq_incremental_buffer_due ON ph08_dq.dq_incremental_buffer (window_end) WHERE status = 'COLLECTING';
CREATE TRIGGER tg_dq_incremental_buffer_touch BEFORE UPDATE ON ph08_dq.dq_incremental_buffer FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_incremental_buffer');
COMMENT ON TABLE ph08_dq.dq_incremental_buffer IS 'EN-08-31 Bộ đệm gom khóa bản ghi đổi theo cửa sổ để đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025). Mỗi đối tượng đúng một bộ đệm COLLECTING; vượt 100.000 khóa thì OVERFLOW và chờ lần đo FULL.';
COMMENT ON COLUMN ph08_dq.dq_incremental_buffer.keys IS 'Khóa bản ghi đổi đã khử trùng (text, tối đa 100.000 mỗi cửa sổ, BR-08-033); đo xong thì xóa khóa, giữ dòng để kiểm toán.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_incremental_buffer CASCADE;

-- @changeset ph08-0270-dq-score-current
CREATE TABLE ph08_dq.dq_score_current (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  asset_id                uuid NOT NULL,
  full_snapshot_id        uuid NOT NULL,
  incremental_scan_job_id uuid,
  current_score           numeric(5,2) NOT NULL,
  verdict                 varchar(4) NOT NULL,
  flags                   varchar(32)[] NOT NULL DEFAULT '{}',
  as_of                   timestamptz NOT NULL DEFAULT now(),
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_score_current PRIMARY KEY (id),
  CONSTRAINT uq_dq_score_current_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_score_current_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_score_current_asset UNIQUE (tenant_id, asset_id),
  CONSTRAINT fk_dq_score_current_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_score_current_full FOREIGN KEY (tenant_id, full_snapshot_id) REFERENCES ph08_dq.dq_score_snapshot (tenant_id, id),
  CONSTRAINT fk_dq_score_current_job FOREIGN KEY (tenant_id, incremental_scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_score_current_score CHECK (current_score >= 0 AND current_score <= 100),
  CONSTRAINT ck_dq_score_current_verdict CHECK (verdict IN ('PASS', 'WARN', 'FAIL')),
  CONSTRAINT ck_dq_score_current_flags CHECK (flags <@ ARRAY['INCOMPLETE_DIMENSIONS', 'WEIGHTS_CHANGED', 'TRUNCATED', 'INCREMENTAL']::varchar[])
);
CREATE TRIGGER tg_dq_score_current_touch BEFORE UPDATE ON ph08_dq.dq_score_current FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_score_current');
COMMENT ON TABLE ph08_dq.dq_score_current IS 'EN-08-32 Điểm hiện hành của một đối tượng: ảnh chụp đầy đủ gần nhất gộp với các lần đo tăng dần sau đó, nhãn INCREMENTAL, không dùng cho báo cáo năm (FR-08-025, 050, 051). Một dòng mỗi đối tượng.';
COMMENT ON COLUMN ph08_dq.dq_score_current.current_score IS 'Điểm hiển thị ở bảng điều khiển; ảnh chụp đầy đủ vẫn là nguồn cho báo cáo (BR-08-033).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_score_current CASCADE;

-- @changeset ph08-0280-dq-inline-stat
CREATE TABLE ph08_dq.dq_inline_stat (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  bucket_at         timestamptz NOT NULL,
  asset_id          uuid NOT NULL,
  caller_code       varchar(63) NOT NULL,
  mode              varchar(10) NOT NULL DEFAULT 'ADVISORY',
  check_count       integer NOT NULL DEFAULT 0,
  pass_count        integer NOT NULL DEFAULT 0,
  fail_count        integer NOT NULL DEFAULT 0,
  blocked_count     integer NOT NULL DEFAULT 0,
  error_count       integer NOT NULL DEFAULT 0,
  warn_count        integer NOT NULL DEFAULT 0,
  fail_open_count   integer NOT NULL DEFAULT 0,
  fail_closed_count integer NOT NULL DEFAULT 0,
  p50_ms            integer,
  p95_ms            integer,
  max_ms            integer,
  by_rule           jsonb NOT NULL DEFAULT '{}',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_inline_stat PRIMARY KEY (id, bucket_at),
  CONSTRAINT ck_dq_inline_stat_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_inline_stat_bucket UNIQUE (tenant_id, asset_id, caller_code, mode, bucket_at),
  CONSTRAINT ck_dq_inline_stat_bucket CHECK (date_trunc('minute', bucket_at) = bucket_at),
  CONSTRAINT ck_dq_inline_stat_mode CHECK (mode IN ('STRICT', 'ADVISORY')),
  CONSTRAINT ck_dq_inline_stat_counts CHECK (check_count >= 0 AND pass_count >= 0 AND fail_count >= 0 AND error_count >= 0 AND pass_count + fail_count + error_count <= check_count),
  CONSTRAINT ck_dq_inline_stat_warn CHECK (warn_count >= 0 AND warn_count <= fail_count AND (mode = 'ADVISORY' OR warn_count = 0)),
  CONSTRAINT ck_dq_inline_stat_blocked CHECK (blocked_count >= 0 AND blocked_count <= fail_count AND (mode = 'STRICT' OR blocked_count = 0)),
  CONSTRAINT ck_dq_inline_stat_latency CHECK (p50_ms IS NULL OR (p50_ms >= 0 AND p95_ms >= p50_ms AND max_ms >= p95_ms))
) PARTITION BY RANGE (bucket_at);
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_inline_stat', current_date, 3);
CREATE INDEX ix_dq_inline_stat_asset ON ph08_dq.dq_inline_stat (tenant_id, asset_id, bucket_at DESC);
CREATE INDEX ix_dq_inline_stat_caller ON ph08_dq.dq_inline_stat (tenant_id, caller_code, bucket_at DESC);
CREATE TRIGGER tg_dq_inline_stat_touch BEFORE UPDATE ON ph08_dq.dq_inline_stat FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_inline_stat');
COMMENT ON TABLE ph08_dq.dq_inline_stat IS 'EN-08-25 Thống kê kiểm tra trực tuyến gộp theo phút, theo đối tượng và bên gọi: số lượt, đạt, lỗi, thời gian p50, p95, số lần mở hoặc đóng khi phụ thuộc lỗi (FR-08-032, 034). Không lưu nội dung bản ghi. Phân vùng tháng theo bucket_at; dọn sau 90 ngày.';
COMMENT ON COLUMN ph08_dq.dq_inline_stat.warn_count IS 'Số lượt lỗi ở chế độ ADVISORY (chỉ cảnh báo, không chặn); chế độ STRICT dùng blocked_count.';
COMMENT ON COLUMN ph08_dq.dq_inline_stat.fail_open_count IS 'Số lượt phụ thuộc lỗi mà bản ghi vẫn đi tiếp; cộng với fail_closed_count là số lượt suy giảm (degraded).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_inline_stat CASCADE;


-- @file 08-0040-finding.sql
-- @changeset ph08-0290-dq-finding
CREATE TABLE ph08_dq.dq_finding (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  last_seen_at         timestamptz NOT NULL DEFAULT now(),
  asset_id             uuid NOT NULL,
  rule_id              uuid NOT NULL,
  dimension            varchar(16) NOT NULL,
  severity             varchar(8) NOT NULL,
  fingerprint          bytea NOT NULL,
  record_key_hash      bytea NOT NULL,
  record_key_masked    varchar(255),
  field_name           varchar(63),
  data_class           varchar(16) NOT NULL DEFAULT 'INTERNAL',
  value_mode           varchar(16) NOT NULL DEFAULT 'MASKED',
  masked_value         varchar(255),
  value_hash           bytea,
  expected_hint        varchar(255),
  status               varchar(16) NOT NULL DEFAULT 'OPEN',
  owner_org_code       varchar(63) NOT NULL,
  first_seen_at        timestamptz NOT NULL DEFAULT now(),
  first_scan_job_id    uuid NOT NULL,
  last_scan_job_id     uuid NOT NULL,
  seen_count           integer NOT NULL DEFAULT 1,
  resolved_at          timestamptz,
  resolved_scan_job_id uuid,
  issue_id             uuid,
  waiver_id            uuid,
  resolution_reason    varchar(16),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_finding PRIMARY KEY (id, last_seen_at),
  CONSTRAINT ck_dq_finding_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_finding_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_finding_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT ck_dq_finding_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_finding_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_finding_status CHECK (status IN ('OPEN', 'IN_REMEDIATION', 'RESOLVED', 'WAIVED')),
  CONSTRAINT ck_dq_finding_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_dq_finding_mode CHECK (value_mode IN ('MASKED', 'HASH_ONLY', 'PLAIN')),
  CONSTRAINT ck_dq_finding_fingerprint CHECK (octet_length(fingerprint) = 32),
  CONSTRAINT ck_dq_finding_key_hash CHECK (octet_length(record_key_hash) = 32),
  CONSTRAINT ck_dq_finding_value_hash CHECK (value_hash IS NULL OR octet_length(value_hash) = 32),
  CONSTRAINT ck_dq_finding_no_raw CHECK ((data_class <> 'SENSITIVE' OR (value_mode = 'HASH_ONLY' AND masked_value IS NULL AND record_key_masked IS NULL AND expected_hint IS NULL)) AND (data_class <> 'RESTRICTED' OR value_mode <> 'PLAIN') AND (value_mode <> 'HASH_ONLY' OR masked_value IS NULL)),
  CONSTRAINT ck_dq_finding_seen CHECK (seen_count >= 1 AND last_seen_at >= first_seen_at),
  CONSTRAINT ck_dq_finding_resolved CHECK ((status = 'RESOLVED') = (resolved_at IS NOT NULL) AND (status = 'RESOLVED') = (resolution_reason IS NOT NULL)),
  CONSTRAINT ck_dq_finding_reason CHECK (resolution_reason IS NULL OR resolution_reason IN ('CLEARED', 'RECORD_REMOVED', 'RULE_RETIRED', 'MANUAL_CONFIRMED')),
  CONSTRAINT ck_dq_finding_remediation CHECK (status <> 'IN_REMEDIATION' OR issue_id IS NOT NULL),
  CONSTRAINT ck_dq_finding_waived CHECK ((status = 'WAIVED') = (waiver_id IS NOT NULL))
) PARTITION BY RANGE (last_seen_at);
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_finding', current_date, 3);
CREATE INDEX ix_dq_finding_asset ON ph08_dq.dq_finding (tenant_id, asset_id, status, last_seen_at DESC);
CREATE INDEX ix_dq_finding_rule ON ph08_dq.dq_finding (tenant_id, rule_id, status);
CREATE INDEX ix_dq_finding_open ON ph08_dq.dq_finding (tenant_id, status, severity, last_seen_at DESC) WHERE status IN ('OPEN', 'IN_REMEDIATION');
CREATE INDEX ix_dq_finding_fp ON ph08_dq.dq_finding (tenant_id, fingerprint);
CREATE INDEX ix_dq_finding_key ON ph08_dq.dq_finding (tenant_id, asset_id, record_key_hash);
CREATE INDEX ix_dq_finding_issue ON ph08_dq.dq_finding (tenant_id, issue_id) WHERE issue_id IS NOT NULL;
CREATE INDEX ix_dq_finding_owner ON ph08_dq.dq_finding (tenant_id, owner_org_code, status, severity);
CREATE INDEX ix_dq_finding_scan ON ph08_dq.dq_finding (tenant_id, last_scan_job_id);
CREATE TRIGGER tg_dq_finding_touch BEFORE UPDATE ON ph08_dq.dq_finding FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_finding_immutable BEFORE UPDATE ON ph08_dq.dq_finding FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_id', 'rule_id', 'fingerprint', 'record_key_hash', 'first_seen_at', 'first_scan_job_id', 'data_class');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_finding');
COMMENT ON TABLE ph08_dq.dq_finding IS 'EN-08-17 Bản ghi lỗi: một dòng cho mỗi lỗi còn tồn tại, nhận dạng bằng dấu vân tay fingerprint (băm khóa bản ghi và mã quy tắc) để biết mới, còn, hết qua các kỳ (FR-08-036, 037, 038, 039). Không lưu giá trị gốc: chỉ masked_value (đã che) và value_hash (băm có khóa); trường Nhạy cảm chỉ có băm. Phân vùng tháng theo last_seen_at, mỗi lần thấy lại dòng chuyển sang phân vùng mới.';
COMMENT ON COLUMN ph08_dq.dq_finding.fingerprint IS 'HMAC-SHA256 (khóa riêng từng tenant) của asset, mã quy tắc, khóa bản ghi; ổn định qua các kỳ (ADR đề xuất dải 085-089).';
COMMENT ON COLUMN ph08_dq.dq_finding.record_key_hash IS 'Băm có khóa của khóa bản ghi nguồn; tra theo đối tượng mà không lộ khóa.';
COMMENT ON COLUMN ph08_dq.dq_finding.masked_value IS 'Giá trị đã che theo chính sách PH-09, tối đa 255 ký tự; luôn rỗng với trường SENSITIVE. Không bao giờ chứa giá trị gốc.';
COMMENT ON COLUMN ph08_dq.dq_finding.value_hash IS 'Băm có khóa của giá trị gốc để biết giá trị có đổi giữa hai kỳ mà không lưu bản rõ.';
COMMENT ON COLUMN ph08_dq.dq_finding.last_seen_at IS 'Khóa phân vùng; cập nhật mỗi lần lỗi được thấy lại nên dòng có thể chuyển phân vùng (row movement).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_finding CASCADE;

-- @changeset ph08-0300-dq-waiver
CREATE TABLE ph08_dq.dq_waiver (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  asset_id         uuid NOT NULL,
  rule_id          uuid,
  fingerprint      bytea,
  status           varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  reason           varchar(2000) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  valid_from       date,
  valid_to         date,
  revoked_by       varchar(64),
  revoked_at       timestamptz,
  revoke_reason    varchar(2000),
  expired_at       timestamptz,
  scope            varchar(12) NOT NULL DEFAULT 'FINDINGS',
  filter           jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_waiver PRIMARY KEY (id),
  CONSTRAINT uq_dq_waiver_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_waiver_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_waiver_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_waiver_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT ck_dq_waiver_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'EXPIRED', 'REVOKED', 'REJECTED')),
  CONSTRAINT ck_dq_waiver_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_dq_waiver_fingerprint CHECK (fingerprint IS NULL OR octet_length(fingerprint) = 32),
  CONSTRAINT ck_dq_waiver_scope CHECK (scope IN ('FINDINGS', 'RULE_FILTER') AND (scope <> 'RULE_FILTER' OR (rule_id IS NOT NULL AND filter IS NOT NULL))),
  CONSTRAINT ck_dq_waiver_four_eyes CHECK (decided_by IS NULL OR requested_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_dq_waiver_period CHECK (valid_to IS NULL OR valid_from IS NULL OR (valid_to > valid_from AND valid_to <= valid_from + 366)),
  CONSTRAINT ck_dq_waiver_active CHECK (status NOT IN ('ACTIVE', 'EXPIRED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND valid_from IS NOT NULL AND valid_to IS NOT NULL)),
  CONSTRAINT ck_dq_waiver_reject CHECK (status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false)),
  CONSTRAINT ck_dq_waiver_revoke CHECK (status <> 'REVOKED' OR (revoked_by IS NOT NULL AND COALESCE(char_length(revoke_reason) >= 20, false)))
);
CREATE INDEX ix_dq_waiver_asset ON ph08_dq.dq_waiver (tenant_id, asset_id, status);
CREATE INDEX ix_dq_waiver_expiry ON ph08_dq.dq_waiver (valid_to) WHERE status = 'ACTIVE';
CREATE INDEX ix_dq_waiver_fp ON ph08_dq.dq_waiver (tenant_id, fingerprint) WHERE fingerprint IS NOT NULL AND status = 'ACTIVE';
CREATE TRIGGER tg_dq_waiver_touch BEFORE UPDATE ON ph08_dq.dq_waiver FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_waiver_immutable BEFORE UPDATE ON ph08_dq.dq_waiver FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_id', 'rule_id', 'fingerprint', 'reason', 'requested_by', 'scope');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_waiver');
COMMENT ON TABLE ph08_dq.dq_waiver IS 'EN-08-18 Ngoại lệ chấp nhận (waiver): cho phép bỏ qua một lỗi hoặc một quy tắc có thời hạn, DA duyệt, lý do tối thiểu 20 ký tự (FR-08-040). Hết hạn thì lỗi mở lại.';
COMMENT ON COLUMN ph08_dq.dq_waiver.scope IS 'FINDINGS: nhóm dấu vân tay (một dấu ở cột fingerprint, nhiều dấu ở dq_waiver_item); RULE_FILTER: một quy tắc kèm điều kiện lọc CEL ở filter (FR-08-040).';
COMMENT ON COLUMN ph08_dq.dq_waiver.valid_to IS 'Tối đa 366 ngày sau valid_from; thời hạn tối đa theo tham số 08.waiver.max-days kiểm ở dịch vụ.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_waiver CASCADE;

-- @changeset ph08-0310-dq-waiver-item
CREATE TABLE ph08_dq.dq_waiver_item (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  waiver_id   uuid NOT NULL,
  fingerprint bytea NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_waiver_item PRIMARY KEY (id),
  CONSTRAINT ck_dq_waiver_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_waiver_item UNIQUE (tenant_id, waiver_id, fingerprint),
  CONSTRAINT fk_dq_waiver_item_waiver FOREIGN KEY (tenant_id, waiver_id) REFERENCES ph08_dq.dq_waiver (tenant_id, id),
  CONSTRAINT ck_dq_waiver_item_fingerprint CHECK (octet_length(fingerprint) = 32)
);
CREATE INDEX ix_dq_waiver_item_fp ON ph08_dq.dq_waiver_item (tenant_id, fingerprint);
CREATE TRIGGER tg_dq_waiver_item_touch BEFORE UPDATE ON ph08_dq.dq_waiver_item FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_waiver_item_immutable BEFORE UPDATE ON ph08_dq.dq_waiver_item FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'waiver_id', 'fingerprint');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_waiver_item');
COMMENT ON TABLE ph08_dq.dq_waiver_item IS 'EN-08-33 Dấu vân tay thuộc một ngoại lệ phạm vi FINDINGS (tối đa 100.000 mỗi ngoại lệ, FR-08-040). Không sửa sau khi tạo.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_waiver_item CASCADE;


-- @file 08-0050-issue.sql
-- @changeset ph08-0320-dq-issue
CREATE TABLE ph08_dq.dq_issue (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  issue_code              varchar(24) NOT NULL,
  asset_id                uuid NOT NULL,
  rule_id                 uuid,
  group_key               varchar(160) NOT NULL,
  title                   varchar(255) NOT NULL,
  description             varchar(4000),
  severity                varchar(8) NOT NULL,
  finding_count           integer NOT NULL DEFAULT 0,
  owner_org_code          varchar(63) NOT NULL,
  assignee                varchar(64),
  status                  varchar(12) NOT NULL DEFAULT 'OPEN',
  sla_days                smallint NOT NULL,
  sla_due_at              timestamptz NOT NULL,
  escalation_level        smallint NOT NULL DEFAULT 0,
  escalated_at            timestamptz,
  assigned_at             timestamptz,
  fixed_at                timestamptz,
  fix_note                varchar(2000),
  verified_at             timestamptz,
  verify_scan_job_id      uuid,
  reopen_count            smallint NOT NULL DEFAULT 0,
  reject_reason           varchar(2000),
  reject_type             varchar(16),
  steward_item_ref        uuid,
  forwarded_to_steward_at timestamptz,
  cancel_reason           varchar(2000),
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_issue PRIMARY KEY (id),
  CONSTRAINT uq_dq_issue_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_issue_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_issue_code UNIQUE (tenant_id, issue_code),
  CONSTRAINT fk_dq_issue_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_issue_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT fk_dq_issue_verify FOREIGN KEY (tenant_id, verify_scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_issue_code CHECK (issue_code ~ '^DQ-[0-9]{4}-[0-9]{6}$'),
  CONSTRAINT ck_dq_issue_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_issue_status CHECK (status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED', 'REOPENED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_dq_issue_sla CHECK (sla_days BETWEEN 1 AND 365),
  CONSTRAINT ck_dq_issue_assigned CHECK (status NOT IN ('ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED') OR assigned_at IS NOT NULL),
  CONSTRAINT ck_dq_issue_fixed CHECK (status NOT IN ('FIXED', 'VERIFIED') OR fixed_at IS NOT NULL),
  CONSTRAINT ck_dq_issue_verified CHECK ((status = 'VERIFIED') = (verified_at IS NOT NULL AND verify_scan_job_id IS NOT NULL)),
  CONSTRAINT ck_dq_issue_reject CHECK (status <> 'REJECTED' OR (COALESCE(char_length(reject_reason) >= 20, false) AND reject_type IS NOT NULL)),
  CONSTRAINT ck_dq_issue_reject_type CHECK (reject_type IS NULL OR reject_type IN ('WRONG_OWNER', 'NOT_A_DEFECT', 'CANNOT_FIX')),
  CONSTRAINT ck_dq_issue_cancel CHECK (status <> 'CANCELLED' OR COALESCE(char_length(cancel_reason) >= 20, false)),
  CONSTRAINT ck_dq_issue_count CHECK (finding_count >= 0 AND reopen_count >= 0 AND escalation_level BETWEEN 0 AND 3)
);
CREATE UNIQUE INDEX uq_dq_issue_open_group ON ph08_dq.dq_issue (tenant_id, group_key) WHERE status NOT IN ('VERIFIED', 'REJECTED', 'CANCELLED');
CREATE INDEX ix_dq_issue_inbox ON ph08_dq.dq_issue (tenant_id, owner_org_code, status, sla_due_at);
CREATE INDEX ix_dq_issue_assignee ON ph08_dq.dq_issue (tenant_id, assignee, status) WHERE assignee IS NOT NULL;
CREATE INDEX ix_dq_issue_sla ON ph08_dq.dq_issue (sla_due_at) WHERE status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'REOPENED');
CREATE INDEX ix_dq_issue_asset ON ph08_dq.dq_issue (tenant_id, asset_id, status);
CREATE TRIGGER tg_dq_issue_touch BEFORE UPDATE ON ph08_dq.dq_issue FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_issue_immutable BEFORE UPDATE ON ph08_dq.dq_issue FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'issue_code', 'asset_id', 'rule_id', 'group_key', 'severity', 'owner_org_code');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_issue');
COMMENT ON TABLE ph08_dq.dq_issue IS 'EN-08-19 Phiếu khắc phục: nhóm lỗi của một đối tượng và quy tắc giao cho tổ chức chủ quản, hạn xử lý theo mức nghiêm trọng (CRITICAL 5 ngày làm việc, MAJOR 15, MINOR 30, giả định), vòng đời OPEN đến VERIFIED (FR-08-041…046). PH-08 không sửa dữ liệu nguồn; lỗi bản ghi vàng chuyển sang hàng đợi steward PH-06.';
COMMENT ON COLUMN ph08_dq.dq_issue.group_key IS 'asset_code | rule_code | owner_org_code; mỗi nhóm một phiếu đang mở (chỉ mục duy nhất một phần).';
COMMENT ON COLUMN ph08_dq.dq_issue.steward_item_ref IS 'Mã mục hàng đợi steward PH-06 khi lỗi ở bản ghi vàng (FR-08-046); kiểm ở dịch vụ, không khóa ngoại.';
COMMENT ON COLUMN ph08_dq.dq_issue.reject_type IS 'Lý do từ chối của DO: sai chủ quản, không phải lỗi, không sửa được (FR-08-045).';
COMMENT ON COLUMN ph08_dq.dq_issue.verify_scan_job_id IS 'Lần đo lại kiểm chứng (trigger VERIFY); phiếu VERIFIED bắt buộc có (FR-08-044).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_issue CASCADE;

-- @changeset ph08-0330-dq-issue-activity
CREATE TABLE ph08_dq.dq_issue_activity (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  issue_id      uuid NOT NULL,
  activity_type varchar(24) NOT NULL,
  actor         varchar(64) NOT NULL,
  from_status   varchar(12),
  to_status     varchar(12),
  comment       varchar(4000),
  payload       jsonb NOT NULL DEFAULT '{}',
  occurred_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_issue_activity PRIMARY KEY (id),
  CONSTRAINT ck_dq_issue_activity_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_issue_activity_issue FOREIGN KEY (tenant_id, issue_id) REFERENCES ph08_dq.dq_issue (tenant_id, id),
  CONSTRAINT ck_dq_issue_activity_type CHECK (activity_type IN ('COMMENT', 'ATTACHMENT', 'STATUS_CHANGE', 'ASSIGNMENT', 'ESCALATION', 'VERIFY_RESULT', 'CREATED', 'TRANSFER', 'STEWARD_FORWARD')),
  CONSTRAINT ck_dq_issue_activity_status CHECK ((from_status IS NULL OR from_status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED', 'REOPENED', 'REJECTED', 'CANCELLED')) AND (to_status IS NULL OR to_status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED', 'REOPENED', 'REJECTED', 'CANCELLED'))),
  CONSTRAINT ck_dq_issue_activity_change CHECK (activity_type <> 'STATUS_CHANGE' OR (from_status IS NOT NULL AND to_status IS NOT NULL AND from_status <> to_status))
);
CREATE INDEX ix_dq_issue_activity_issue ON ph08_dq.dq_issue_activity (tenant_id, issue_id, occurred_at);
CREATE TRIGGER tg_dq_issue_activity_touch BEFORE UPDATE ON ph08_dq.dq_issue_activity FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_issue_activity_append_only BEFORE UPDATE OR DELETE ON ph08_dq.dq_issue_activity FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_append_only();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_issue_activity');
COMMENT ON TABLE ph08_dq.dq_issue_activity IS 'EN-08-20 Hoạt động trên phiếu khắc phục: tạo, phân công, bình luận, đổi trạng thái, leo thang, chuyển steward, xác nhận (FR-08-043, 045). Chỉ thêm, không sửa, không xóa.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_issue_activity CASCADE;


-- @file 08-0060-alert-report.sql
-- @changeset ph08-0340-dq-alert-rule
CREATE TABLE ph08_dq.dq_alert_rule (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  alert_rule_code  varchar(63) NOT NULL,
  name             varchar(255) NOT NULL,
  domain_code      varchar(32),
  asset_id         uuid,
  condition_type   varchar(24) NOT NULL,
  dimension        varchar(16),
  threshold        numeric(8,3),
  severity         varchar(8) NOT NULL DEFAULT 'MEDIUM',
  channels         jsonb NOT NULL DEFAULT '[]',
  recipients       jsonb NOT NULL DEFAULT '[]',
  cooldown_minutes integer NOT NULL DEFAULT 60,
  enabled          boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_alert_rule PRIMARY KEY (id),
  CONSTRAINT uq_dq_alert_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_alert_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_alert_rule_code UNIQUE (tenant_id, alert_rule_code),
  CONSTRAINT fk_dq_alert_rule_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_alert_rule_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_alert_rule_code CHECK (alert_rule_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_alert_rule_scope CHECK (asset_id IS NULL OR domain_code IS NULL),
  CONSTRAINT ck_dq_alert_rule_condition CHECK (condition_type IN ('SCORE_BELOW', 'SCORE_DROP', 'SCAN_FAILED', 'INCOMPLETE_DIMENSIONS', 'ISSUE_OVERDUE', 'INLINE_FAIL_RATE', 'NEW_CRITICAL_FINDINGS')),
  CONSTRAINT ck_dq_alert_rule_dimension CHECK (dimension IS NULL OR dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_alert_rule_severity CHECK (severity IN ('HIGH', 'MEDIUM', 'LOW')),
  CONSTRAINT ck_dq_alert_rule_threshold CHECK (condition_type NOT IN ('SCORE_BELOW', 'SCORE_DROP', 'INLINE_FAIL_RATE') OR threshold IS NOT NULL),
  CONSTRAINT ck_dq_alert_rule_cooldown CHECK (cooldown_minutes BETWEEN 1 AND 10080)
);
CREATE INDEX ix_dq_alert_rule_scope ON ph08_dq.dq_alert_rule (tenant_id, condition_type) WHERE enabled;
CREATE TRIGGER tg_dq_alert_rule_touch BEFORE UPDATE ON ph08_dq.dq_alert_rule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_alert_rule');
COMMENT ON TABLE ph08_dq.dq_alert_rule IS 'EN-08-21 Quy tắc cảnh báo: điều kiện điểm thấp, điểm giảm, lần đo thất bại, thiếu chiều, phiếu quá hạn, tỷ lệ lỗi trực tuyến, lỗi CRITICAL mới; kênh gửi qua PH-13 (FR-08-047, 048).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_alert_rule CASCADE;

-- @changeset ph08-0350-dq-alert
CREATE TABLE ph08_dq.dq_alert (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  alert_rule_id    uuid NOT NULL,
  asset_id         uuid,
  scan_job_id      uuid,
  snapshot_id      uuid,
  severity         varchar(8) NOT NULL,
  status           varchar(14) NOT NULL DEFAULT 'FIRING',
  dedup_key        varchar(160) NOT NULL,
  message          varchar(1000) NOT NULL,
  fired_at         timestamptz NOT NULL DEFAULT now(),
  notified_at      timestamptz,
  notification_ref varchar(64),
  acknowledged_by  varchar(64),
  acknowledged_at  timestamptz,
  silenced_until   timestamptz,
  silence_reason   varchar(500),
  resolved_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_alert PRIMARY KEY (id),
  CONSTRAINT uq_dq_alert_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_alert_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_alert_rule FOREIGN KEY (tenant_id, alert_rule_id) REFERENCES ph08_dq.dq_alert_rule (tenant_id, id),
  CONSTRAINT fk_dq_alert_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_alert_severity CHECK (severity IN ('HIGH', 'MEDIUM', 'LOW')),
  CONSTRAINT ck_dq_alert_status CHECK (status IN ('FIRING', 'ACKNOWLEDGED', 'RESOLVED', 'SILENCED')),
  CONSTRAINT ck_dq_alert_ack CHECK (status <> 'ACKNOWLEDGED' OR (acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL)),
  CONSTRAINT ck_dq_alert_silence CHECK (status <> 'SILENCED' OR (silenced_until IS NOT NULL AND COALESCE(char_length(silence_reason) >= 20, false))),
  CONSTRAINT ck_dq_alert_resolved CHECK ((status = 'RESOLVED') = (resolved_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_dq_alert_open ON ph08_dq.dq_alert (tenant_id, dedup_key) WHERE status IN ('FIRING', 'ACKNOWLEDGED', 'SILENCED');
CREATE UNIQUE INDEX uq_dq_alert_unresolved ON ph08_dq.dq_alert (tenant_id, alert_rule_id, COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE status <> 'RESOLVED';
CREATE INDEX ix_dq_alert_status ON ph08_dq.dq_alert (tenant_id, status, fired_at DESC);
CREATE INDEX ix_dq_alert_asset ON ph08_dq.dq_alert (tenant_id, asset_id, fired_at DESC) WHERE asset_id IS NOT NULL;
CREATE TRIGGER tg_dq_alert_touch BEFORE UPDATE ON ph08_dq.dq_alert FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_alert');
COMMENT ON TABLE ph08_dq.dq_alert IS 'EN-08-22 Cảnh báo đã phát: trạng thái FIRING, ACKNOWLEDGED, RESOLVED, SILENCED, khóa chống trùng, tham chiếu thông báo PH-13 (FR-08-048, 049).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_alert CASCADE;

-- @changeset ph08-0360-dq-report
CREATE TABLE ph08_dq.dq_report (
  id                        uuid NOT NULL,
  tenant_id                 varchar(16) NOT NULL,
  report_code               varchar(24) NOT NULL,
  report_type               varchar(10) NOT NULL,
  period_code               varchar(7) NOT NULL,
  title                     varchar(255) NOT NULL,
  status                    varchar(10) NOT NULL DEFAULT 'DRAFT',
  scope                     jsonb NOT NULL DEFAULT '{}',
  summary                   jsonb NOT NULL DEFAULT '{}',
  snapshot_count            integer NOT NULL DEFAULT 0,
  incomplete_snapshot_count integer NOT NULL DEFAULT 0,
  generated_at              timestamptz,
  submitted_by              varchar(64),
  submitted_at              timestamptz,
  reviewed_by               varchar(64),
  reviewed_at               timestamptz,
  review_comment            varchar(2000),
  published_by              varchar(64),
  published_at              timestamptz,
  withdrawn_reason          varchar(2000),
  pdf_object_key            varchar(512),
  xlsx_object_key           varchar(512),
  content_sha256            bytea,
  signed                    boolean NOT NULL DEFAULT false,
  signature_ref             varchar(255),
  created_at                timestamptz NOT NULL DEFAULT now(),
  created_by                varchar(64) NOT NULL,
  updated_at                timestamptz NOT NULL DEFAULT now(),
  updated_by                varchar(64) NOT NULL,
  version                   integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_report PRIMARY KEY (id),
  CONSTRAINT uq_dq_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_report_code UNIQUE (tenant_id, report_code),
  CONSTRAINT ck_dq_report_code CHECK (report_code ~ '^BC-DQ-[0-9]{4}-[A-Z0-9]{2,4}-T[0-9]{2}(-R[0-9]{1,2})?$'),
  CONSTRAINT ck_dq_report_type CHECK (report_type IN ('PERIODIC', 'ANNUAL', 'AD_HOC')),
  CONSTRAINT ck_dq_report_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'PUBLISHED', 'WITHDRAWN')),
  CONSTRAINT ck_dq_report_period CHECK (period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$' AND (report_type <> 'ANNUAL' OR period_code ~ '^[0-9]{4}$')),
  CONSTRAINT ck_dq_report_hash CHECK (content_sha256 IS NULL OR octet_length(content_sha256) = 32),
  CONSTRAINT ck_dq_report_annual_full CHECK (report_type <> 'ANNUAL' OR incomplete_snapshot_count = 0),
  CONSTRAINT ck_dq_report_four_eyes CHECK (reviewed_by IS NULL OR submitted_by IS NULL OR reviewed_by <> submitted_by),
  CONSTRAINT ck_dq_report_publisher CHECK (published_by IS NULL OR submitted_by IS NULL OR published_by <> submitted_by),
  CONSTRAINT ck_dq_report_published CHECK (status <> 'PUBLISHED' OR (published_at IS NOT NULL AND published_by IS NOT NULL AND reviewed_by IS NOT NULL AND content_sha256 IS NOT NULL AND pdf_object_key IS NOT NULL)),
  CONSTRAINT ck_dq_report_withdrawn CHECK (status <> 'WITHDRAWN' OR COALESCE(char_length(withdrawn_reason) >= 20, false)),
  CONSTRAINT ck_dq_report_signed CHECK (NOT signed OR signature_ref IS NOT NULL),
  CONSTRAINT ck_dq_report_counts CHECK (snapshot_count >= 0 AND incomplete_snapshot_count >= 0 AND incomplete_snapshot_count <= snapshot_count)
);
CREATE INDEX ix_dq_report_period ON ph08_dq.dq_report (tenant_id, report_type, period_code, status);
CREATE INDEX ix_dq_report_published ON ph08_dq.dq_report (tenant_id, published_at DESC) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_dq_report_touch BEFORE UPDATE ON ph08_dq.dq_report FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_report_immutable BEFORE UPDATE ON ph08_dq.dq_report FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'report_code', 'report_type', 'period_code');
CREATE TRIGGER tg_dq_report_frozen BEFORE UPDATE ON ph08_dq.dq_report FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_frozen('PUBLISHED,WITHDRAWN', 'scope', 'summary', 'snapshot_count', 'incomplete_snapshot_count', 'content_sha256', 'pdf_object_key', 'xlsx_object_key');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_report');
COMMENT ON TABLE ph08_dq.dq_report IS 'EN-08-23 Báo cáo chất lượng: kỳ (tháng), chính thức hằng năm, theo yêu cầu; soạn, duyệt bốn mắt, công bố; tệp PDF, XLSX trên Ceph RGW kèm SHA-256, ký số tùy chọn (FR-08-052…056). Báo cáo ANNUAL không được dựa trên snapshot thiếu chiều. Đã công bố thì bất biến.';
COMMENT ON COLUMN ph08_dq.dq_report.summary IS 'Số liệu tổng hợp (điểm theo miền, theo tổ chức, xu hướng); không chứa giá trị bản ghi.';
COMMENT ON COLUMN ph08_dq.dq_report.pdf_object_key IS 'Khóa đối tượng trên Ceph RGW, bucket dq-reports; không lưu tệp trong PostgreSQL.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_report CASCADE;

-- @changeset ph08-0370-dq-report-subscription
CREATE TABLE ph08_dq.dq_report_subscription (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  report_type    varchar(10) NOT NULL,
  domain_code    varchar(32),
  recipient_type varchar(8) NOT NULL,
  recipient_ref  varchar(128) NOT NULL,
  format         varchar(4) NOT NULL DEFAULT 'PDF',
  enabled        boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_report_subscription PRIMARY KEY (id),
  CONSTRAINT ck_dq_report_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_report_subscription_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_report_subscription_type CHECK (report_type IN ('PERIODIC', 'ANNUAL', 'AD_HOC')),
  CONSTRAINT ck_dq_report_subscription_recipient CHECK (recipient_type IN ('USER', 'ROLE', 'ORG')),
  CONSTRAINT ck_dq_report_subscription_format CHECK (format IN ('PDF', 'XLSX'))
);
CREATE UNIQUE INDEX uq_dq_report_subscription ON ph08_dq.dq_report_subscription (tenant_id, report_type, COALESCE(domain_code, ''), recipient_type, recipient_ref, format);
CREATE TRIGGER tg_dq_report_subscription_touch BEFORE UPDATE ON ph08_dq.dq_report_subscription FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_report_subscription');
COMMENT ON TABLE ph08_dq.dq_report_subscription IS 'EN-08-24 Đăng ký nhận báo cáo: người dùng, vai trò hoặc tổ chức nhận báo cáo công bố qua PH-13 (FR-08-056).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_report_subscription CASCADE;


-- @file 08-0070-ops.sql
-- @changeset ph08-0380-dq-export-request
CREATE TABLE ph08_dq.dq_export_request (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  kind                varchar(10) NOT NULL DEFAULT 'FINDINGS',
  report_code         varchar(24),
  asset_id            uuid,
  filter              jsonb NOT NULL DEFAULT '{}',
  format              varchar(4) NOT NULL DEFAULT 'CSV',
  status              varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  contains_restricted boolean NOT NULL DEFAULT false,
  requested_by        varchar(64) NOT NULL,
  decided_by          varchar(64),
  decided_at          timestamptz,
  decision_comment    varchar(2000),
  row_count           bigint,
  object_key          varchar(512),
  content_sha256      bytea,
  watermark_id        varchar(64),
  expires_at          timestamptz,
  download_count      integer NOT NULL DEFAULT 0,
  error_code          varchar(16),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_export_request PRIMARY KEY (id),
  CONSTRAINT uq_dq_export_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_export_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_export_request_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_export_request_report FOREIGN KEY (tenant_id, report_code) REFERENCES ph08_dq.dq_report (tenant_id, report_code),
  CONSTRAINT ck_dq_export_request_format CHECK (format IN ('CSV', 'XLSX', 'PDF')),
  CONSTRAINT ck_dq_export_request_kind CHECK (kind IN ('FINDINGS', 'REPORT') AND (kind = 'REPORT') = (report_code IS NOT NULL) AND (format <> 'PDF' OR kind = 'REPORT')),
  CONSTRAINT ck_dq_export_request_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'READY', 'FAILED', 'EXPIRED', 'REJECTED')),
  CONSTRAINT ck_dq_export_request_four_eyes CHECK (decided_by IS NULL OR requested_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_dq_export_request_approval CHECK (NOT contains_restricted OR status IN ('PENDING_APPROVAL', 'REJECTED') OR decided_by IS NOT NULL),
  CONSTRAINT ck_dq_export_request_ready CHECK (status <> 'READY' OR (object_key IS NOT NULL AND expires_at IS NOT NULL AND watermark_id IS NOT NULL AND content_sha256 IS NOT NULL)),
  CONSTRAINT ck_dq_export_request_hash CHECK (content_sha256 IS NULL OR octet_length(content_sha256) = 32),
  CONSTRAINT ck_dq_export_request_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_export_request_status ON ph08_dq.dq_export_request (tenant_id, status, created_at DESC);
CREATE INDEX ix_dq_export_request_expiry ON ph08_dq.dq_export_request (expires_at) WHERE status = 'READY';
CREATE TRIGGER tg_dq_export_request_touch BEFORE UPDATE ON ph08_dq.dq_export_request FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_export_request');
COMMENT ON TABLE ph08_dq.dq_export_request IS 'EN-08-29 Yêu cầu xuất bản ghi lỗi ra CSV hoặc XLSX trên Ceph RGW; khi có trường Nhạy cảm hoặc Hạn chế cần DO chấp thuận khác người yêu cầu (FR-08-039). Tệp có hạn tải và thủy vân.';
COMMENT ON COLUMN ph08_dq.dq_export_request.kind IS 'FINDINGS: xuất bản ghi lỗi (FR-08-039, cần DO chấp thuận khi có trường Hạn chế, Nhạy cảm); REPORT: xuất báo cáo PDF, XLSX (FR-08-055, API-08-116).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_export_request CASCADE;

-- @changeset ph08-0390-dq-tenant-setting
CREATE TABLE ph08_dq.dq_tenant_setting (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  setting_key varchar(64) NOT NULL,
  value       jsonb NOT NULL,
  description varchar(500),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_dq_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_dq_tenant_setting_key CHECK (setting_key IN ('08.scan.default-cron', '08.scan.timezone', '08.scan.window', '08.scan.min-interval-hours', '08.scan.max-duration-hours', '08.scan.queue-timeout-hours', '08.scan.duplicate-policy', '08.scan.manual-per-hour', '08.scan.max-concurrent-per-connection', '08.scan.heartbeat-timeout-seconds', '08.scan.task-max-attempts', '08.scan.min-coverage', '08.scan.task-size', '08.incremental.batch-window-minutes', '08.profile.on-activate', '08.profile.max-columns', '08.dryrun.max-rows', '08.rule.sql-predicate-enabled', '08.rdm.snapshot-max-items', '08.score.dimension-method', '08.trend.stable-band', '08.trend.degraded-alert', '08.finding.max-per-scan', '08.finding.max-per-rule-task', '08.finding.retention-months', '08.snapshot.retention-years', '08.report.official-retention-years', '08.report.auto-draft', '08.annual.snapshot-method', '08.issue.sla-days', '08.issue.auto-open-critical', '08.issue.escalate-after-overdue-days', '08.verify.wait-mdm-minutes', '08.verify.wait-source-minutes', '08.waiver.max-days', '08.inline.timeout-ms', '08.inline.default-mode', '08.inline.on-dependency-failure', '08.inline.persist-findings', '08.alert.repeat-hours', '08.export.link-hours', '08.benchmark.opt-in', '08.benchmark.min-group'))
);
CREATE TRIGGER tg_dq_tenant_setting_touch BEFORE UPDATE ON ph08_dq.dq_tenant_setting FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_tenant_setting');
COMMENT ON TABLE ph08_dq.dq_tenant_setting IS 'EN-08-26 Tham số chất lượng theo tenant: 43 khóa 08.* của FRS mục 8.2 (lịch đo, cửa sổ, mẫu, kích thước tác vụ, thời gian chờ, hạn SLA, hạn ngoại lệ, chế độ kiểm tra trực tuyến) (FR-08-058). Chỉ nhận các khóa đã khai báo; ngưỡng điểm và trọng số nằm ở dq_weight_config.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_tenant_setting CASCADE;

-- @changeset ph08-0400-dq-retention-policy
CREATE TABLE ph08_dq.dq_retention_policy (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  object_type    varchar(40) NOT NULL,
  retention_days integer NOT NULL,
  action         varchar(16) NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_retention_policy PRIMARY KEY (id),
  CONSTRAINT ck_dq_retention_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_retention_policy UNIQUE (tenant_id, object_type),
  CONSTRAINT ck_dq_retention_policy_object CHECK (object_type IN ('dq_finding', 'dq_rule_result', 'dq_inline_stat', 'dq_scan_task', 'dq_profile_column', 'dq_score_snapshot', 'dq_issue', 'dq_alert', 'dq_report', 'dq_export_request', 'outbox_event', 'inbox_event')),
  CONSTRAINT ck_dq_retention_policy_action CHECK (action IN ('DROP_PARTITION', 'DELETE', 'ARCHIVE_COLD', 'ANONYMIZE')),
  CONSTRAINT ck_dq_retention_policy_days CHECK (retention_days >= 1 AND (object_type NOT IN ('dq_score_snapshot', 'dq_report') OR retention_days >= 1095))
);
CREATE TRIGGER tg_dq_retention_policy_touch BEFORE UPDATE ON ph08_dq.dq_retention_policy FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_retention_policy');
COMMENT ON TABLE ph08_dq.dq_retention_policy IS 'EN-08-30 Chính sách lưu giữ và dọn dữ liệu đo theo loại đối tượng: số ngày giữ và hành động (xóa phân vùng, xóa dòng, lưu lạnh) (FR-08-059). Bản ghi lỗi giữ mặc định 13 tháng (395 ngày), có thể đổi theo tenant.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_retention_policy CASCADE;

-- @changeset ph08-0410-dq-retention-run
CREATE TABLE ph08_dq.dq_retention_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  object_type        varchar(40) NOT NULL,
  action             varchar(16) NOT NULL,
  status             varchar(10) NOT NULL DEFAULT 'RUNNING',
  dry_run            boolean NOT NULL DEFAULT false,
  requested_by       varchar(64) NOT NULL,
  cutoff_at          timestamptz,
  started_at         timestamptz NOT NULL DEFAULT now(),
  finished_at        timestamptz,
  rows_affected      bigint NOT NULL DEFAULT 0,
  partitions_dropped integer NOT NULL DEFAULT 0,
  error_code         varchar(16),
  error_message      varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_retention_run PRIMARY KEY (id),
  CONSTRAINT uq_dq_retention_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_retention_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_dq_retention_run_object CHECK (object_type IN ('dq_finding', 'dq_rule_result', 'dq_inline_stat', 'dq_scan_task', 'dq_profile_column', 'dq_score_snapshot', 'dq_issue', 'dq_alert', 'dq_report', 'dq_export_request', 'outbox_event', 'inbox_event')),
  CONSTRAINT ck_dq_retention_run_action CHECK (action IN ('DROP_PARTITION', 'DELETE', 'ARCHIVE_COLD', 'ANONYMIZE')),
  CONSTRAINT ck_dq_retention_run_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
  CONSTRAINT ck_dq_retention_run_done CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT ck_dq_retention_run_counts CHECK (rows_affected >= 0 AND partitions_dropped >= 0),
  CONSTRAINT ck_dq_retention_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_retention_run_started ON ph08_dq.dq_retention_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_dq_retention_run_touch BEFORE UPDATE ON ph08_dq.dq_retention_run FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_retention_run');
COMMENT ON TABLE ph08_dq.dq_retention_run IS 'EN-08-30 Lịch sử chạy dọn dữ liệu đo theo chính sách lưu giữ: loại dữ liệu, hành động, số dòng và phân vùng đã dọn, chạy xem trước hay chạy thật (FR-08-059, API-08-125, 126).';
-- @rollback DROP TABLE IF EXISTS ph08_dq.dq_retention_run CASCADE;

-- @changeset ph08-0420-outbox-event
CREATE TABLE ph08_dq.outbox_event (
  tenant_id      varchar(16) NOT NULL,
  event_id       uuid NOT NULL,
  topic          varchar(128) NOT NULL,
  aggregate_type varchar(32) NOT NULL,
  aggregate_id   uuid NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32) NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  published_at   timestamptz,
  CONSTRAINT pk_outbox_event PRIMARY KEY (event_id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (substr(topic, length(split_part(topic, '.', 1)) + 2) IN ('dq.ruleset.activated.v1', 'dq.scan.completed.v1', 'dq.scan.failed.v1', 'dq.score.degraded.v1', 'dq.score.threshold-breached.v1', 'dq.finding.opened.v1', 'dq.issue.created.v1', 'dq.issue.status-changed.v1', 'dq.issue.verified.v1', 'dq.waiver.approved.v1', 'dq.report.published.v1', 'dq.alert.fired.v1', 'dq.check.failed.v1', 'dq.kpi.published.v1', 'audit.recorded.v1')),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_value CHECK (NOT (payload ?| ARRAY['value', 'values', 'maskedValue', 'valueHash', 'record', 'recordKey', 'fields']))
);
CREATE INDEX ix_outbox_event_occurred ON ph08_dq.outbox_event (occurred_at);
CALL ph08_dq.p_enable_rls('ph08_dq.outbox_event');
COMMENT ON TABLE ph08_dq.outbox_event IS 'EN-08-27 Outbox (SAD 7.3) cho EVT-08-01…14 và bản ghi kiểm toán gửi PH-13 (FR-08-057, 060). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic. Sự kiện không chứa giá trị bản ghi lỗi: CHECK chặn các khóa value, maskedValue, record. Dọn sau 3 ngày.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.outbox_event CASCADE;

-- @changeset ph08-0430-inbox-event
CREATE TABLE ph08_dq.inbox_event (
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     uuid NOT NULL,
  source_topic varchar(128) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  CONSTRAINT pk_inbox_event PRIMARY KEY (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) = lower(tenant_id))
);
CREATE INDEX ix_inbox_event_received ON ph08_dq.inbox_event (received_at);
CALL ph08_dq.p_enable_rls('ph08_dq.inbox_event');
COMMENT ON TABLE ph08_dq.inbox_event IS 'EN-08-28 Khử trùng sự kiện nhận: EVT-06-01, 02, 03, 04, 10 của PH-06 và sự kiện phát hành danh mục của PH-07, tiêu thụ lũy đẳng theo event_id (FR-08-025). Dọn sau 30 ngày.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.inbox_event CASCADE;

-- @changeset ph08-0440-shedlock
CREATE TABLE ph08_dq.shedlock (
  name       varchar(64) NOT NULL,
  lock_until timestamptz NOT NULL,
  locked_at  timestamptz NOT NULL,
  locked_by  varchar(255) NOT NULL,
  CONSTRAINT pk_shedlock PRIMARY KEY (name)
);
COMMENT ON TABLE ph08_dq.shedlock IS 'Bảng kỹ thuật của thư viện ShedLock cho các job Quartz (lập lịch đo, dọn, duy trì phân vùng); không chứa dữ liệu nghiệp vụ.';
-- @rollback DROP TABLE IF EXISTS ph08_dq.shedlock CASCADE;

-- @file 08-0090-seed.sql
-- @changeset ph08-0910-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: tham số 08.* mặc định, chính sách lưu giữ, cấu hình trọng số mặc định đã ACTIVE, lịch đo tháng cho cả tenant.
CREATE OR REPLACE PROCEDURE ph08_dq.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph08_dq.dq_tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by)
  SELECT md5('ph08-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('08.scan.default-cron', '"0 0 2 1 * ?"'), ('08.scan.timezone', '"Asia/Ho_Chi_Minh"'), ('08.scan.window', '"22:00-05:00"'), ('08.scan.min-interval-hours', '{"FULL":24,"INCREMENTAL":1}'), ('08.scan.max-duration-hours', '6'), ('08.scan.queue-timeout-hours', '24'), ('08.scan.duplicate-policy', '"QUEUE"'), ('08.scan.manual-per-hour', '10'), ('08.scan.max-concurrent-per-connection', '2'), ('08.scan.heartbeat-timeout-seconds', '180'), ('08.scan.task-max-attempts', '3'), ('08.scan.min-coverage', '95'), ('08.scan.task-size', '200000'), ('08.incremental.batch-window-minutes', '15'), ('08.profile.on-activate', 'true'), ('08.profile.max-columns', '200'), ('08.dryrun.max-rows', '10000'), ('08.rule.sql-predicate-enabled', 'false'), ('08.rdm.snapshot-max-items', '200000'), ('08.score.dimension-method', '"POOLED"'), ('08.trend.stable-band', '1.0'), ('08.trend.degraded-alert', '5.0'), ('08.finding.max-per-scan', '1000000'), ('08.finding.max-per-rule-task', '50000'), ('08.finding.retention-months', '13'), ('08.snapshot.retention-years', '5'), ('08.report.official-retention-years', '10'), ('08.report.auto-draft', 'true'), ('08.annual.snapshot-method', '"FULL_DECEMBER"'), ('08.issue.sla-days', '{"CRITICAL":5,"MAJOR":15,"MINOR":30}'), ('08.issue.auto-open-critical', '100'), ('08.issue.escalate-after-overdue-days', '5'), ('08.verify.wait-mdm-minutes', '60'), ('08.verify.wait-source-minutes', '0'), ('08.waiver.max-days', '180'), ('08.inline.timeout-ms', '40'), ('08.inline.default-mode', '"ADVISORY"'), ('08.inline.on-dependency-failure', '"FAIL_OPEN"'), ('08.inline.persist-findings', 'false'), ('08.alert.repeat-hours', '4'), ('08.export.link-hours', '24'), ('08.benchmark.opt-in', 'false'), ('08.benchmark.min-group', '5')) AS s(k, v)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph08_dq.dq_retention_policy (id, tenant_id, object_type, retention_days, action, created_by, updated_by)
  SELECT md5('ph08-retention:' || p_tenant || ':' || r.t)::uuid, p_tenant, r.t, r.d, r.a, 'system:seed', 'system:seed'
  FROM (VALUES ('dq_finding', 395, 'DROP_PARTITION'), ('dq_rule_result', 395, 'DROP_PARTITION'), ('dq_inline_stat', 90, 'DROP_PARTITION'), ('dq_scan_task', 90, 'DELETE'), ('dq_profile_column', 395, 'DELETE'), ('dq_score_snapshot', 1825, 'ARCHIVE_COLD'), ('dq_issue', 1825, 'ARCHIVE_COLD'), ('dq_alert', 395, 'DELETE'), ('dq_report', 3650, 'ARCHIVE_COLD'), ('dq_export_request', 30, 'DELETE'), ('outbox_event', 3, 'DELETE'), ('inbox_event', 30, 'DELETE')) AS r(t, d, a)
  ON CONFLICT (tenant_id, object_type) DO NOTHING;
  INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, version_no, status, activated_at, change_note, created_by, updated_by)
  VALUES (md5('ph08-weight:' || p_tenant)::uuid, p_tenant, 'DEFAULT', 1, 'ACTIVE', now(), 'Trọng số mặc định 0,20/0,20/0,15/0,10/0,15/0,20', 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, config_code, version_no) DO NOTHING;
  INSERT INTO ph08_dq.dq_schedule (id, tenant_id, schedule_code, cron, scan_mode, enabled, created_by, updated_by)
  VALUES (md5('ph08-schedule:' || p_tenant)::uuid, p_tenant, 'MONTHLY-ALL', '0 0 2 1 * *', 'FULL', true, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, schedule_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): 43 tham số 08.*, 12 chính sách lưu giữ, trọng số mặc định, lịch đo tháng. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph08_dq.p_seed_tenant(text);

-- @changeset ph08-0920-fn-seed-common splitStatements:false
-- Bộ quy tắc mẫu dùng chung (tenant COMMON, FR-08-015). Chạy dưới phiên PLATFORM.
CREATE OR REPLACE PROCEDURE ph08_dq.p_seed_common()
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph08_dq.dq_rule_template (id, tenant_id, template_code, name, dimension, operator, default_severity, params, expression_template, description, created_by, updated_by)
  SELECT md5('ph08-template:' || t.c)::uuid, 'COMMON', t.c, t.n, t.d, t.o, t.s, t.p::jsonb, t.e, t.n, 'system:seed', 'system:seed'
  FROM (VALUES
    ('VN-CCCD-12', 'Số CCCD gồm 12 chữ số', 'VALIDITY', 'REGEX', 'MAJOR', '{"pattern":"^[0-9]{12}$"}', NULL),
    ('VN-MST-FORMAT', 'Mã số thuế 10 số hoặc 13 số có gạch', 'VALIDITY', 'REGEX', 'MAJOR', '{"pattern":"^[0-9]{10}(-[0-9]{3})?$"}', NULL),
    ('VN-MST-CHECKSUM', 'Chữ số kiểm tra của mã số thuế', 'ACCURACY', 'CHECKSUM', 'MAJOR', '{"algorithm":"MST_10"}', NULL),
    ('VN-SDT', 'Số điện thoại di động Việt Nam', 'VALIDITY', 'REGEX', 'MINOR', '{"pattern":"^(0|\\+84)[0-9]{9}$"}', NULL),
    ('VN-EMAIL', 'Địa chỉ email đúng cú pháp', 'VALIDITY', 'REGEX', 'MINOR', '{"pattern":"^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"}', NULL),
    ('VN-DVHC-IN-RDM', 'Mã đơn vị hành chính có trong danh mục PH-07', 'VALIDITY', 'IN_RDM', 'MAJOR', '{"catalogCode":"${catalog}"}', NULL),
    ('NOT-NULL-CDE', 'Phần tử dữ liệu trọng yếu không để trống', 'COMPLETENESS', 'NOT_NULL', 'CRITICAL', '{}', NULL),
    ('NOT-EMPTY-TEXT', 'Chuỗi không rỗng sau khi cắt khoảng trắng', 'COMPLETENESS', 'NOT_EMPTY', 'MINOR', '{}', NULL),
    ('UNIQUE-KEY', 'Khóa nghiệp vụ không trùng trong đối tượng đo', 'UNIQUENESS', 'UNIQUE_IN_ASSET', 'CRITICAL', '{}', NULL),
    ('FRESH-30D', 'Bản ghi cập nhật trong 30 ngày', 'TIMELINESS', 'MAX_AGE_DAYS', 'MINOR', '{"days":30}', NULL),
    ('DOB-RANGE', 'Ngày sinh từ 1900 đến hôm nay', 'VALIDITY', 'RANGE', 'MAJOR', '{"min":"1900-01-01","max":"today"}', NULL),
    ('DATE-ORDER', 'Ngày bắt đầu không sau ngày kết thúc', 'CONSISTENCY', 'CEL_EXPRESSION', 'MAJOR', '{}', 'record.from_date <= record.to_date')
  ) AS t(c, n, d, o, s, p, e)
  ON CONFLICT (tenant_id, template_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_seed_common() IS 'Nạp 12 quy tắc mẫu COMMON (CCCD, MST, SĐT, email, ĐVHC, CDE, trùng khóa, độ tươi, ngày sinh, thứ tự ngày). Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph08_dq.p_seed_common();

-- @changeset ph08-0930-seed-common-run
CALL ph08_dq.p_seed_common();
-- @rollback DELETE FROM ph08_dq.dq_rule_template WHERE tenant_id = 'COMMON';

-- @file 08-0900-grants.sql
-- @changeset ph08-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph08_dq TO ph08_app;
-- Đối tượng nghiệp vụ không xóa cứng: chỉ ngừng. Dòng con của bản nháp, bảng tạm và bảng kỹ thuật mới được xóa.
REVOKE DELETE ON ph08_dq.dq_domain, ph08_dq.dq_asset, ph08_dq.dq_profile_run, ph08_dq.dq_rule_template, ph08_dq.dq_weight_config, ph08_dq.dq_rule_set,
  ph08_dq.dq_rule_set_version, ph08_dq.dq_schedule, ph08_dq.dq_scan_job, ph08_dq.dq_score_snapshot, ph08_dq.dq_score_dimension, ph08_dq.dq_waiver,
  ph08_dq.dq_issue, ph08_dq.dq_alert_rule, ph08_dq.dq_report, ph08_dq.dq_tenant_setting, ph08_dq.dq_retention_policy FROM ph08_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph08_owner.
REVOKE UPDATE, DELETE ON ph08_dq.dq_rule_result, ph08_dq.dq_issue_activity FROM ph08_app;
REVOKE DELETE ON ph08_dq.dq_finding, ph08_dq.dq_inline_stat FROM ph08_app;
REVOKE UPDATE ON ph08_dq.outbox_event FROM ph08_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph08_dq TO ph08_readonly;
-- Báo cáo, BI chỉ đọc không thấy giá trị đã che, băm giá trị, khóa bản ghi che.
REVOKE SELECT ON ph08_dq.dq_finding FROM ph08_readonly;
GRANT SELECT (id, tenant_id, last_seen_at, asset_id, rule_id, dimension, severity, fingerprint, field_name, data_class, status, owner_org_code, first_seen_at,
  first_scan_job_id, last_scan_job_id, seen_count, resolved_at, issue_id, waiver_id) ON ph08_dq.dq_finding TO ph08_readonly;
GRANT EXECUTE ON PROCEDURE ph08_dq.p_ensure_partitions(regclass, date, integer) TO ph08_app;
GRANT EXECUTE ON PROCEDURE ph08_dq.p_seed_tenant(text) TO ph08_app;
-- @rollback -- Không thu hồi tự động.

-- @changeset ph08-0995-benchmark
-- Ngoại lệ RLS duy nhất: vai ph08_benchmark đọc điểm chiều của ảnh chụp chính thức mọi tenant qua khung nhìn security_invoker, chỉ cột cần để tổng hợp.
-- Việc kiểm tenant đã bật 08.benchmark.opt-in và nhóm tối thiểu 5 tenant do dịch vụ làm trước khi trả (BR-08-030).
CREATE POLICY rls_dq_score_snapshot_benchmark ON ph08_dq.dq_score_snapshot FOR SELECT TO ph08_benchmark USING (official);
CREATE POLICY rls_dq_score_dimension_benchmark ON ph08_dq.dq_score_dimension FOR SELECT TO ph08_benchmark USING (status = 'MEASURED');
CREATE VIEW ph08_dq.v_benchmark_dimension WITH (security_invoker = true) AS
  SELECT s.tenant_id, s.period_code, d.dimension, d.score
  FROM ph08_dq.dq_score_dimension d JOIN ph08_dq.dq_score_snapshot s ON s.tenant_id = d.tenant_id AND s.id = d.snapshot_id;
COMMENT ON VIEW ph08_dq.v_benchmark_dimension IS 'Điểm chiều của ảnh chụp chính thức, dùng cho so sánh liên tenant ẩn danh (FR-08-061); chỉ vai ph08_benchmark đọc.';
GRANT SELECT ON ph08_dq.v_benchmark_dimension TO ph08_benchmark;
GRANT SELECT (tenant_id, id, period_code, official) ON ph08_dq.dq_score_snapshot TO ph08_benchmark;
GRANT SELECT (tenant_id, snapshot_id, dimension, score, status) ON ph08_dq.dq_score_dimension TO ph08_benchmark;
-- @rollback DROP VIEW IF EXISTS ph08_dq.v_benchmark_dimension; DROP POLICY IF EXISTS rls_dq_score_dimension_benchmark ON ph08_dq.dq_score_dimension; DROP POLICY IF EXISTS rls_dq_score_snapshot_benchmark ON ph08_dq.dq_score_snapshot;

RESET ROLE;
