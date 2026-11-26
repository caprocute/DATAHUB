-- =============================================================================
-- D03-03-PH12 · DDL schema ph12_iam — PH-12 Định danh và phân quyền
-- Tệp 01: vai trò, schema, hàm và thủ tục dùng chung
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
--
-- Thứ tự chạy: ph12_iam_01 → 02 → 03 → 04 → 05 → 06 (chạy bằng một lệnh, xem ph12_iam_all.sql):
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph12_iam_all.sql
-- Môi trường thật: Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback
-- (công cụ ../ph07/tools/gen_liquibase.py, tham số hóa tên phân hệ).
--
-- Phạm vi: schema ph12_iam ở cụm pg-core giữ phần nghiệp vụ mà Keycloak không có (D03-02-PH12 §4.1).
-- Người dùng, mật khẩu, yếu tố xác thực, phiên và khóa ký chỉ ở Keycloak (CSDL pg-iam, cụm riêng).
-- KHÔNG lưu mật khẩu, mã TOTP, bí mật client, token đầy đủ ở bất kỳ bảng nào (BR-12-045, NFR-12-020).
-- Phân hệ mới, không thay bảng nào của mã hiện tại; schema ph12 rỗng của compose chỉ là chỗ giữ chỗ.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 12-0000-bootstrap.sql
-- @changeset ph12-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph12_owner') THEN
    CREATE ROLE ph12_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph12_app') THEN
    CREATE ROLE ph12_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph12_readonly') THEN
    CREATE ROLE ph12_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph12-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph12_iam AUTHORIZATION ph12_owner;
COMMENT ON SCHEMA ph12_iam IS 'PH-12 Định danh và phân quyền: bản chiếu người dùng, gán vai trò, tách nhiệm vụ, nhóm, quyền có thời hạn, rà soát quyền, liên kết ngoài, client HTTT, danh sách chặn, realm, chính sách và gói chính sách, cảnh báo, báo cáo. Không có giá trị bí mật. dh-platform (module iam) kết nối bằng dh_platform_iam_app (thành viên ph12_app, không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph12_iam TO ph12_app, ph12_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph12_iam CASCADE;

SET ROLE ph12_owner;

-- @changeset ph12-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 12-0001-functions.sql
-- @changeset ph12-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph12_iam.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph12_iam.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag, ERR-12-044) khi ứng dụng không tự tăng.';
-- @rollback DROP FUNCTION IF EXISTS ph12_iam.tg_touch();

-- @changeset ph12-0011-fn-rls splitStatements:false
-- Ba mẫu theo D03-10, mở rộng từ PH-05:
--   P  riêng tenant: đọc, ghi khi tenant_id = app.tenant_id (tenant nền tảng PLATFORM cũng là một tenant).
--   S  dùng chung:   đọc dòng của tenant phiên và dòng COMMON; chỉ phiên PLATFORM được ghi dòng COMMON.
--   G  quyền có thời hạn: như P nhưng đọc thêm dòng có target_tenant = app.tenant_id, để quản trị tỉnh
--      bị truy cập nhìn thấy quyền đang mở vào tỉnh mình (BR-12-032); ghi vẫn chỉ ở tenant của người nhận quyền.
CREATE OR REPLACE PROCEDURE ph12_iam.p_enable_rls(p_table regclass, p_mode char DEFAULT 'P')
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  cur text := $c$current_setting('app.tenant_id', false)$c$;
  w text;
  r text;
BEGIN
  IF p_mode NOT IN ('P', 'S', 'G') THEN RAISE EXCEPTION 'p_mode phải là P, S hoặc G'; END IF;
  IF p_mode = 'S' THEN
    w := format($w$(tenant_id = 'COMMON' AND %s = 'PLATFORM')$w$, cur);
    r := format($r$(tenant_id IN (%s, 'COMMON'))$r$, cur);
  ELSE
    w := format('(tenant_id = %s)', cur);
    r := CASE p_mode WHEN 'G' THEN format('(tenant_id = %s OR target_tenant = %s)', cur, cur) ELSE w END;
  END IF;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph12_iam.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P, S hoặc G (D03-10, ADR-003). current_setting(…, false) lỗi khi quên đặt app.tenant_id.';
-- @rollback DROP PROCEDURE IF EXISTS ph12_iam.p_enable_rls(regclass, char);

-- @changeset ph12-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph12_iam.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % là chỉ-ghi-thêm: không được %', TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'P1299';
END
$f$;
COMMENT ON FUNCTION ph12_iam.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng chứng cứ (kết quả kiểm thử, chạy khô, đóng góp chính sách).';
-- @rollback DROP FUNCTION IF EXISTS ph12_iam.tg_append_only();

-- @changeset ph12-0013-fn-no-delete splitStatements:false
CREATE OR REPLACE FUNCTION ph12_iam.tg_no_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % không cho xóa dòng; kết thúc bằng trạng thái (BR-12-035)', TG_TABLE_NAME
    USING ERRCODE = 'P1235';
END
$f$;
COMMENT ON FUNCTION ph12_iam.tg_no_delete() IS 'Chặn DELETE trên đối tượng chỉ kết thúc bằng trạng thái: tài khoản, client, chính sách, phiên bản (BR-12-035). Dọn dữ liệu hết hạn nếu có dùng thủ tục riêng dưới ph12_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph12_iam.tg_no_delete();

-- @changeset ph12-0015-fn-no-secret splitStatements:false
-- Lớp phòng thủ thứ hai của BR-12-045: JSON không được mang khóa tên bí mật (kể cả lồng một cấp).
CREATE OR REPLACE FUNCTION ph12_iam.f_json_has_secret_key(p_doc jsonb) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE jsonb_typeof(p_doc)
    WHEN 'object' THEN EXISTS (
      SELECT 1 FROM jsonb_each(p_doc) e
      WHERE lower(e.key) IN ('password', 'secret', 'clientsecret', 'client_secret', 'apikey', 'token', 'accesstoken',
                             'refreshtoken', 'privatekey', 'passphrase', 'otp', 'totp', 'wrappingtoken', 'bindpassword')
         OR ph12_iam.f_json_has_secret_key(e.value))
    WHEN 'array' THEN EXISTS (SELECT 1 FROM jsonb_array_elements(p_doc) a WHERE ph12_iam.f_json_has_secret_key(a))
    ELSE false
  END
$f$;
COMMENT ON FUNCTION ph12_iam.f_json_has_secret_key(jsonb) IS 'true nếu JSON (đệ quy) có khóa tên bí mật như password, clientSecret, token, wrappingToken. Dùng trong CHECK của cột jsonb nhận dữ liệu từ ngoài (BR-12-045).';
-- @rollback DROP FUNCTION IF EXISTS ph12_iam.f_json_has_secret_key(jsonb);

-- @changeset ph12-0016-fn-tenant-label splitStatements:false
-- Tên realm theo tenant: dh-{mã viết thường}; riêng PLATFORM là dh-platform (D03-10 §3).
CREATE OR REPLACE FUNCTION ph12_iam.f_realm_name(p_tenant text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$ SELECT 'dh-' || lower(p_tenant) $f$;
COMMENT ON FUNCTION ph12_iam.f_realm_name(text) IS 'dh-{tenant viết thường}, ví dụ dh-t68, dh-platform.';
-- @rollback DROP FUNCTION IF EXISTS ph12_iam.f_realm_name(text);
