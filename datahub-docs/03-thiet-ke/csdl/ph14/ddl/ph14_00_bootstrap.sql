-- =============================================================================
-- D03-03-PH14 · DDL schema ph14_national — PH-14 Kết nối quốc gia
-- Tệp 00: vai trò, schema, hàm dùng chung.
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Thứ tự chạy (CSDL rỗng, người dùng có quyền tạo vai trò và extension):
--   for f in ph14_00_bootstrap.sql ph14_10_catalog.sql ph14_20_trust.sql \
--            ph14_30_quota_inbound.sql ph14_40_operations.sql ph14_90_seed_grants.sql; do
--     psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f "$f"; done
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (công cụ ../../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Nguyên tắc: không có bí mật nào trong schema này (BR-14-005). Chỉ lưu tham chiếu
-- (mã kết nối PH-05, keyRef của OpenBao transit) và dữ liệu công khai (chứng thư, CRL).
-- Mặt phẳng dữ liệu (dh-runtime, hồ sơ national-gateway) KHÔNG kết nối schema này;
-- mọi bản ghi từ cổng đến qua Kafka (EVT-14-11 …) rồi dh-integration ghi vào đây.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 14-0000-bootstrap.sql
-- @changeset ph14-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph14_owner') THEN
    CREATE ROLE ph14_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph14_app') THEN
    CREATE ROLE ph14_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph14_readonly') THEN
    CREATE ROLE ph14_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph14-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph14_national AUTHORIZATION ph14_owner;
COMMENT ON SCHEMA ph14_national IS 'PH-14 Kết nối quốc gia: nền tảng và dịch vụ quốc gia, đặc tả, định tuyến, chứng thư, chuỗi tin cậy, hạn mức, chiều vào, đồng bộ, sổ giao dịch, sức khỏe, cảnh báo, chạy song song. Không có bí mật. dh-integration kết nối bằng dh_integration_app (thành viên ph14_app); dh-runtime không kết nối.';
GRANT USAGE ON SCHEMA ph14_national TO ph14_app, ph14_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph14_national CASCADE;

SET ROLE ph14_owner;

-- @changeset ph14-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 14-0001-functions.sql
-- @changeset ph14-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph14_national.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph14_national.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_touch();

-- @changeset ph14-0011-fn-rls splitStatements:false
-- Hai mẫu của D03-10, cùng PH-04, PH-05: 'P' riêng tenant; 'S' dùng chung (đọc thêm COMMON,
-- ghi COMMON chỉ khi app.tenant_id = 'PLATFORM'). Mẫu P cho phiên PLATFORM đọc, ghi dòng COMMON.
CREATE OR REPLACE PROCEDURE ph14_national.p_enable_rls(p_table regclass, p_mode char)
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
COMMENT ON PROCEDURE ph14_national.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10).';
-- @rollback DROP PROCEDURE IF EXISTS ph14_national.p_enable_rls(regclass, char);

-- @changeset ph14-0012-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph14_national.p_ensure_month_partitions(p_table regclass, p_from date, p_months integer)
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
COMMENT ON PROCEDURE ph14_national.p_ensure_month_partitions(regclass, date, integer) IS 'Tạo phân vùng tháng; PartitionMaintenanceJob gọi hằng ngày để luôn có 3 tháng tới. Dọn bằng DETACH rồi DROP dưới ph14_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph14_national.p_ensure_month_partitions(regclass, date, integer);

-- @changeset ph14-0013-fn-guards splitStatements:false
CREATE OR REPLACE FUNCTION ph14_national.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ cho thêm (append-only)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph14_national.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng nhật ký chỉ thêm (usage, health_sample sau khi đã gộp là ngoại lệ không dùng trigger này).';

CREATE OR REPLACE FUNCTION ph14_national.tg_no_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % không cho xóa dòng; dùng trạng thái cuối', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph14_national.tg_no_delete() IS 'Chặn DELETE: chứng thư (BR-14-019), sự cố chữ ký, giao dịch, yêu cầu duyệt không bị xóa; hết hạn lưu giữ thì tháo phân vùng hoặc dọn dưới ph14_owner.';

CREATE OR REPLACE FUNCTION ph14_national.tg_retired_final() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.state = 'RETIRED' AND NEW.state IS DISTINCT FROM 'RETIRED' THEN
    RAISE EXCEPTION '% đã RETIRED, không đảo ngược và không dùng lại mã', TG_TABLE_NAME USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph14_national.tg_retired_final() IS 'RETIRED là trạng thái cuối của nền tảng, dịch vụ (FRS §4.3, §4.4).';
-- @rollback DROP FUNCTION IF EXISTS ph14_national.tg_retired_final(); DROP FUNCTION IF EXISTS ph14_national.tg_no_delete(); DROP FUNCTION IF EXISTS ph14_national.tg_append_only();
