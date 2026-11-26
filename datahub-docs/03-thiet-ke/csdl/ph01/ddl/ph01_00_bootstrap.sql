-- =============================================================================
-- D03-03-PH01 · DDL schema ph01_onboarding — PH-01 Kết nạp hệ thống thông tin
-- Tệp 00: vai trò, schema, hàm dùng chung.
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Chạy độc lập (phát triển), theo thứ tự tên tệp:
--   for f in ph01_00_bootstrap ph01_10_member ph01_20_demand_review ph01_30_credential \
--            ph01_40_review_cycle ph01_50_infra ph01_80_seed ph01_90_grants; do
--     psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f $f.sql; done
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (cùng cách của ../ph07/tools/gen_liquibase.py, cần tham số hóa tên phân hệ trước khi dùng cho PH-01).
--
-- Không lưu bí mật ở bất kỳ bảng nào (BR-01-007): chỉ secret_ref (đường dẫn OpenBao),
-- dấu vân tay và giá trị băm. Thay schema ph01 cũ của apps/control (changeset ph01-9000).
-- Mọi bảng nghiệp vụ có tenant_id và FORCE ROW LEVEL SECURITY (ADR-003, D03-10).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 01-0000-bootstrap.sql
-- @changeset ph01-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph01_owner') THEN
    CREATE ROLE ph01_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph01_app') THEN
    CREATE ROLE ph01_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph01_readonly') THEN
    CREATE ROLE ph01_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph01-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE SCHEMA IF NOT EXISTS ph01_onboarding AUTHORIZATION ph01_owner;
COMMENT ON SCHEMA ph01_onboarding IS 'PH-01 Kết nạp hệ thống thông tin: HTTT thành viên, hồ sơ kỹ thuật, nhu cầu khai thác, trần phạm vi, đầu mối, thẩm định, định danh ứng dụng, bàn giao, saga cấp định danh, cắt quyền, rà soát quyền. Không có giá trị bí mật. dh-connect kết nối bằng dh_connect_app (thành viên ph01_app).';
GRANT USAGE ON SCHEMA ph01_onboarding TO ph01_app, ph01_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph01_onboarding CASCADE;

SET ROLE ph01_owner;

-- @changeset ph01-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 01-0001-functions.sql
-- @changeset ph01-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph01_onboarding.tg_touch();

-- @changeset ph01-0011-fn-rls splitStatements:false
-- Hai mẫu của D03-10. 'P' (riêng tenant): đọc và ghi chỉ dòng của tenant phiên, tenant phải dạng T{nn}.
-- 'S' (dùng chung): đọc thêm dòng COMMON; ghi dòng COMMON chỉ khi app.tenant_id = 'PLATFORM'.
-- Thiếu biến phiên app.tenant_id thì mọi truy vấn lỗi (current_setting(..., false)), không trả rỗng im lặng.
CREATE OR REPLACE PROCEDURE ph01_onboarding.p_enable_rls(p_table regclass, p_mode char DEFAULT 'P')
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text;
  r text;
BEGIN
  IF p_mode NOT IN ('P', 'S') THEN RAISE EXCEPTION 'p_mode phải là P hoặc S'; END IF;
  w := CASE p_mode
         WHEN 'S' THEN $w$((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
                        OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))$w$
         ELSE $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$
       END;
  r := CASE p_mode WHEN 'S' THEN $r$(tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'))$r$ ELSE w END;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph01_onboarding.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10).';
-- @rollback DROP PROCEDURE IF EXISTS ph01_onboarding.p_enable_rls(regclass, char);

-- @changeset ph01-0012-fn-validators splitStatements:false
-- Hàm kiểm tra dùng trong CHECK; IMMUTABLE để dùng được trong chỉ mục nếu cần.
CREATE OR REPLACE FUNCTION ph01_onboarding.fn_urls_https(j jsonb) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT jsonb_typeof(j) = 'array'
     AND jsonb_array_length(j) <= 20
     AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(j) e
                      WHERE jsonb_typeof(e) <> 'string' OR (e #>> '{}') !~ '^https://[^\s/?#]+[^\s]*$')
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_urls_https(jsonb) IS 'Mảng JSON gồm tối đa 20 địa chỉ, mọi phần tử bắt đầu bằng https:// (FR-01-003, SEC-43).';

CREATE OR REPLACE FUNCTION ph01_onboarding.fn_cidr_array(j jsonb) RETURNS boolean
  LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE AS $f$
DECLARE e text;
BEGIN
  IF jsonb_typeof(j) <> 'array' OR jsonb_array_length(j) > 100 THEN RETURN false; END IF;
  FOR e IN SELECT jsonb_array_elements_text(j) LOOP
    PERFORM e::cidr;
  END LOOP;
  RETURN true;
EXCEPTION WHEN others THEN
  RETURN false;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_cidr_array(jsonb) IS 'Mảng JSON gồm tối đa 100 khối CIDR hợp lệ (FR-01-003, SEC-43).';

CREATE OR REPLACE FUNCTION ph01_onboarding.fn_unaccent(t text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT lower(public.unaccent('public.unaccent'::regdictionary, t))
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_unaccent(text) IS 'Bỏ dấu và hạ chữ thường, dùng cho search_text của đầu mối (bao bọc unaccent để dùng trong cột sinh, chỉ mục).';

CREATE OR REPLACE FUNCTION ph01_onboarding.fn_rank(p_class text) RETURNS integer
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE p_class WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 WHEN 'SENSITIVE' THEN 4 END
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_rank(text) IS 'Thứ hạng mức phân loại dữ liệu: PUBLIC 1, INTERNAL 2, RESTRICTED 3, SENSITIVE 4 (DD-08).';
-- @rollback DROP FUNCTION IF EXISTS ph01_onboarding.fn_urls_https(jsonb), ph01_onboarding.fn_cidr_array(jsonb), ph01_onboarding.fn_unaccent(text), ph01_onboarding.fn_rank(text);

-- @changeset ph01-0013-fn-draft-only-delete splitStatements:false
-- Bảng con của hồ sơ: chỉ xóa cứng khi hồ sơ cha còn là nháp chưa từng nộp (revision_no = 0)
-- hoặc cha đã bị xóa (xóa theo tầng). Sau nộp chỉ đổi trạng thái, không xóa (BR-01-011).
-- Tham số TG_ARGV[0] là tên cột trỏ tới member_system.id.
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_draft_only_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_sys uuid := (to_jsonb(OLD) ->> TG_ARGV[0])::uuid;
  v_status text;
  v_rev integer;
BEGIN
  SELECT status, revision_no INTO v_status, v_rev FROM ph01_onboarding.member_system WHERE id = v_sys;
  IF NOT FOUND OR (v_status = 'DRAFT' AND v_rev = 0) THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'Bảng % không cho xóa dòng của hồ sơ đã nộp (BR-01-011)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_draft_only_delete() IS 'Chặn xóa dòng con của hồ sơ đã nộp ít nhất một lần (BR-01-011); tham số: tên cột khóa tới member_system.';
-- @rollback DROP FUNCTION IF EXISTS ph01_onboarding.tg_draft_only_delete();
