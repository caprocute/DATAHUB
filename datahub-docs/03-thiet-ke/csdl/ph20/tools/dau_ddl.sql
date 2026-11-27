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
