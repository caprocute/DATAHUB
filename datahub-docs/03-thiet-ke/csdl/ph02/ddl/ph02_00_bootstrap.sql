-- =============================================================================
-- D03-03-PH02 · DDL schema ph02_catalog — PH-02 Danh mục dịch vụ
-- Tệp 00: vai trò, schema, cấu hình tìm kiếm, hàm dùng chung
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy toàn bộ (phát triển):  psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph02_all.sql
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (công cụ ../../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Không lưu nội dung đặc tả OpenAPI trong CSDL: đặc tả ở kho đối tượng (object_key + sha256).
-- Không lưu giá trị bí mật: kết quả quét bí mật chỉ giữ dấu vân tay ngắn của chuỗi khớp.
-- Thay bảng ph02.api_service của apps/control (W1); di trú ở ph02_60_seed_grants.sql
-- (changeset ph02-9000, context migrate-w1).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 02-0000-bootstrap.sql
-- @changeset ph02-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph02_owner') THEN
    CREATE ROLE ph02_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph02_app') THEN
    CREATE ROLE ph02_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph02_readonly') THEN
    CREATE ROLE ph02_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph02-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE SCHEMA IF NOT EXISTS ph02_catalog AUTHORIZATION ph02_owner;
COMMENT ON SCHEMA ph02_catalog IS 'PH-02 Danh mục dịch vụ: API, phiên bản, đặc tả, kiểm tra, backend, gói, đăng ký sử dụng, duyệt, SLA, đồng bộ quốc gia, công bố cho gateway. Không có nội dung đặc tả, không có bí mật. dh-connect kết nối bằng dh_connect_app (thành viên ph02_app).';
GRANT USAGE ON SCHEMA ph02_catalog TO ph02_app, ph02_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph02_catalog CASCADE;

SET ROLE ph02_owner;

-- @changeset ph02-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 02-0001-functions.sql
-- @changeset ph02-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph02_catalog.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag, If-Match).';
-- @rollback DROP FUNCTION IF EXISTS ph02_catalog.tg_touch();

-- @changeset ph02-0011-fn-rls splitStatements:false
-- Hai mẫu của D03-10: 'P' riêng tenant; 'S' dùng chung (đọc thêm COMMON,
-- ghi COMMON chỉ khi app.tenant_id = 'PLATFORM').
CREATE OR REPLACE PROCEDURE ph02_catalog.p_enable_rls(p_table regclass, p_mode char)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
            OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))$w$;
  r text;
BEGIN
  IF p_mode NOT IN ('P', 'S') THEN RAISE EXCEPTION 'p_mode phải là P hoặc S'; END IF;
  r := CASE p_mode WHEN 'S' THEN $r$(tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'))$r$ ELSE w END;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph02_catalog.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10).';
-- @rollback DROP PROCEDURE IF EXISTS ph02_catalog.p_enable_rls(regclass, char);

-- @changeset ph02-0012-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph02_catalog.p_ensure_month_partitions(p_table regclass, p_from date, p_months integer)
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
COMMENT ON PROCEDURE ph02_catalog.p_ensure_month_partitions(regclass, date, integer) IS 'Tạo phân vùng tháng; PartitionMaintenanceJob gọi hằng ngày để luôn có 3 tháng tới. Dọn bằng DETACH, DROP dưới ph02_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph02_catalog.p_ensure_month_partitions(regclass, date, integer);

-- @changeset ph02-0013-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph02_catalog.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ cho thêm (append-only)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph02_catalog.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng bằng chứng (BR-02-014, BR-02-021, BR-02-028). Không có đường xóa; bảng lớn theo thời gian dọn bằng DETACH PARTITION dưới ph02_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph02_catalog.tg_append_only();

-- @changeset ph02-0014-ts-config splitStatements:false
-- Cấu hình tìm kiếm tiếng Việt không dấu (SDD 4.2): "ho so dat dai" khớp "Hồ sơ đất đai".
DO $ts$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_ts_config c JOIN pg_namespace n ON n.oid = c.cfgnamespace
                  WHERE n.nspname = 'ph02_catalog' AND c.cfgname = 'vn_unaccent') THEN
    CREATE TEXT SEARCH CONFIGURATION ph02_catalog.vn_unaccent (COPY = pg_catalog.simple);
    ALTER TEXT SEARCH CONFIGURATION ph02_catalog.vn_unaccent
      ALTER MAPPING FOR word, hword, hword_part WITH public.unaccent, pg_catalog.simple;
  END IF;
END
$ts$;
-- @rollback DROP TEXT SEARCH CONFIGURATION IF EXISTS ph02_catalog.vn_unaccent;
