-- =============================================================================
-- D03-03-PH12 · Kiểm thử DDL ph12_iam: cô lập tenant, ba mẫu RLS (P, S, G), bất biến, tách nhiệm vụ,
--               bốn mắt, máy trạng thái chính sách, quyền của vai trò, không lưu bí mật.
-- Chạy sau ph12_iam_all.sql trên CSDL có schema mới (một phiên, dưới tài khoản không BYPASSRLS):
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph12_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE làm dừng tệp.
-- Dữ liệu tạo ở dạng giao dịch rồi ROLLBACK cuối tệp nên chạy lại được.
-- Tương ứng TS-12 cô lập tenant, tách nhiệm vụ, bất biến của D05-02-PH12 (do tập test viết).
-- =============================================================================
\set ON_ERROR_STOP on
BEGIN;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_iam_app') THEN
    CREATE ROLE dh_platform_iam_app LOGIN NOBYPASSRLS IN ROLE ph12_app;
  END IF;
END $$;
SET LOCAL ROLE dh_platform_iam_app;

-- Hàm trợ giúp (bảng tạm, mất khi hết phiên)
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT md5('ph12:test:' || p)::uuid $$;
CREATE FUNCTION pg_temp.mkuser(p_name text, p_org text DEFAULT 'VP_UBND') RETURNS uuid LANGUAGE sql AS $$
  INSERT INTO ph12_iam.user_account (id, tenant_id, username, full_name, email, org_code, state, activated_at, created_by, updated_by)
  VALUES (pg_temp.u(current_setting('app.tenant_id') || ':' || p_name), current_setting('app.tenant_id'), p_name, 'Cán bộ ' || p_name,
          p_name || '@gov.vn', p_org, 'ACTIVE', now(), 'system:test', 'system:test')
  RETURNING id $$;
CREATE FUNCTION pg_temp.assign(p_name text, p_role text, p_by text DEFAULT 'system:test') RETURNS void LANGUAGE sql AS $$
  INSERT INTO ph12_iam.role_assignment (id, tenant_id, user_id, role_code, created_by, updated_by)
  VALUES (gen_random_uuid(), current_setting('app.tenant_id'), pg_temp.u(current_setting('app.tenant_id') || ':' || p_name), p_role, p_by, p_by) $$;

-- ---------- Dữ liệu tenant nền tảng ----------
SET LOCAL app.tenant_id = 'PLATFORM';
SELECT pg_temp.mkuser('pa1', 'NEN_TANG');
SELECT pg_temp.mkuser('po1', 'NEN_TANG');
SELECT pg_temp.mkuser('so_nt', 'NEN_TANG');
SELECT pg_temp.assign('pa1', 'PLATFORM_ADMIN');
INSERT INTO ph12_iam.node_heartbeat (id, node_id, node_kind, applied_revocation, created_by, updated_by)
VALUES (gen_random_uuid(), 'apisix-0', 'APISIX', 0, 'system:test', 'system:test');
INSERT INTO ph12_iam.realm_state (id, tenant_code, realm_name, state, provisioned_at, created_by, updated_by)
VALUES (pg_temp.u('realm68'), 'T68', 'dh-t68', 'ACTIVE', now(), 'system:test', 'system:test');
INSERT INTO ph12_iam.policy (id, tenant_id, code, scope, name, is_root, created_by, updated_by)
VALUES (pg_temp.u('base'), 'PLATFORM', 'base-authz', 'PLATFORM', 'Chính sách gốc', true, 'system:test', 'system:test');
-- Quyền có thời hạn của nhân sự nền tảng vào tenant T68 (po1 đề nghị)
INSERT INTO ph12_iam.privileged_grant (id, tenant_id, user_id, role_code, target_tenant, reason, ticket_ref, requested_hours, requested_by, created_by, updated_by)
VALUES (pg_temp.u('grant1'), 'PLATFORM', pg_temp.u('PLATFORM:po1'), 'TENANT_ADMIN', 'T68', 'Xử lý sự cố đồng bộ danh mục theo phiếu hỗ trợ', 'SUP-1024', 2, pg_temp.u('PLATFORM:po1')::text, 'system:test', 'system:test');

-- ---------- Dữ liệu T68 ----------
SET LOCAL app.tenant_id = 'T68';
SELECT pg_temp.mkuser('adm1');
SELECT pg_temp.mkuser('adm2');
SELECT pg_temp.mkuser('so1');
SELECT pg_temp.mkuser('so2');
SELECT pg_temp.mkuser('eng1');
SELECT pg_temp.mkuser('usr1');
SELECT pg_temp.mkuser('aud1');
SELECT pg_temp.mkuser('nguyenvana');
SELECT pg_temp.assign('adm1', 'TENANT_ADMIN', 'system:provisioner');
SELECT pg_temp.assign('so1', 'SECURITY_OFFICER', pg_temp.u('T68:adm1')::text);
INSERT INTO ph12_iam.client (id, tenant_id, client_id, kind, system_code, org_code, name, auth_method, contract_level, state, keycloak_client_id, created_by, updated_by)
VALUES (pg_temp.u('cli68'), 'T68', 'qlvb-so-tttt', 'SYSTEM', 'QLVB_SO_TTTT', 'SO_TTTT', 'Quản lý văn bản Sở TTTT', 'MTLS', 'RESTRICTED', 'ENABLED', gen_random_uuid(), 'system:test', 'system:test');
INSERT INTO ph12_iam.policy (id, tenant_id, code, scope, name, created_by, updated_by)
VALUES (pg_temp.u('pol68'), 'T68', 'deny-ngoai-gio', 'TENANT', 'Từ chối ngoài giờ', 'system:test', 'system:test');
INSERT INTO ph12_iam.policy_version (id, tenant_id, policy_id, version_no, content, author, created_by, updated_by)
VALUES (pg_temp.u('pv68'), 'T68', pg_temp.u('pol68'), 1, 'package dh.tenant_rules.t68' || E'\n' || 'deny contains "OUT_OF_HOURS" if { false }', pg_temp.u('T68:so1')::text, 'system:test', 'system:test');
INSERT INTO ph12_iam.revocation_entry (id, tenant_id, kind, value, reason, created_by, updated_by)
VALUES (pg_temp.u('rev68'), 'T68', 'CLIENT', 'qlvb-so-tttt', 'Nghi lộ chứng thư', pg_temp.u('T68:so1')::text, 'system:test');

-- ---------- Dữ liệu T01 ----------
SET LOCAL app.tenant_id = 'T01';
SELECT pg_temp.mkuser('adm1');
SELECT pg_temp.mkuser('nguyenvana');
SELECT pg_temp.assign('adm1', 'TENANT_ADMIN', 'system:provisioner');

-- 1. Mỗi tenant chỉ thấy dữ liệu của mình
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.user_account;
  IF n <> 2 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy % người dùng, mong đợi 2', n; END IF;
  SELECT count(*) INTO n FROM ph12_iam.client;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy client của T68'; END IF;
  SELECT count(*) INTO n FROM ph12_iam.policy;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy chính sách của T68 hoặc của nền tảng'; END IF;
  SELECT count(*) INTO n FROM ph12_iam.revocation_entry;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy danh sách chặn của T68'; END IF;
  SELECT count(*) INTO n FROM ph12_iam.realm_state;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy trạng thái realm của nền tảng'; END IF;
  RAISE NOTICE 'PASS 1 cô lập đọc (user_account, client, policy, revocation_entry, realm_state)';
END $$;

-- 2. WITH CHECK: không ghi được dòng mang tenant khác
DO $$ BEGIN
  INSERT INTO ph12_iam.user_account (id, tenant_id, username, full_name, email, org_code, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ke.tan.cong', 'x', 'x@gov.vn', 'VP', 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 2: ghi chéo tenant được chấp nhận';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn ghi chéo tenant';
END $$;

-- 3. Không cập nhật được dòng tenant khác (0 dòng)
DO $$ DECLARE n int; BEGIN
  UPDATE ph12_iam.user_account SET title = 'x' WHERE tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 3'; END IF;
  UPDATE ph12_iam.client SET name = 'x' WHERE id = pg_temp.u('cli68');
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 3 client'; END IF;
  RAISE NOTICE 'PASS 3 không sửa được dòng tenant khác';
END $$;

-- 4. Khóa ngoại kép không trỏ được sang bản ghi tenant khác
DO $$ BEGIN
  INSERT INTO ph12_iam.role_assignment (id, tenant_id, user_id, role_code, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.u('T68:usr1'), 'VIEWER', 'system:test', 'system:test');
  RAISE EXCEPTION 'FAIL 4';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 4 FK kép chặn tham chiếu chéo tenant';
END $$;

-- 5. Thiếu app.tenant_id: lỗi hoặc thấy 0 dòng, không bao giờ lộ dữ liệu
RESET app.tenant_id;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.user_account;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 5: thấy % dòng khi không có tenant', n; END IF;
  RAISE NOTICE 'PASS 5 không có tenant thì không thấy dòng nào';
EXCEPTION WHEN undefined_object THEN RAISE NOTICE 'PASS 5 thiếu app.tenant_id thì lỗi';
END $$;

-- 6. Mẫu S: danh mục dùng chung đọc được ở mọi tenant, không ghi được từ ứng dụng
SET LOCAL app.tenant_id = 'T01';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.sod_pair;
  IF n <> 10 THEN RAISE EXCEPTION 'FAIL 6a: T01 thấy % cặp xung đột, mong đợi 10', n; END IF;
  SELECT count(*) INTO n FROM ph12_iam.legacy_role_map;
  IF n < 15 THEN RAISE EXCEPTION 'FAIL 6a: legacy_role_map chỉ có % dòng', n; END IF;
  RAISE NOTICE 'PASS 6a tỉnh đọc được sod_pair và legacy_role_map (COMMON)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.sod_pair (id, tenant_id, role_a, role_b, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'AAA', 'BBB', 'x', 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 6b';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 6b tỉnh không ghi được dòng COMMON';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.node_heartbeat (id, node_id, node_kind, created_by, updated_by) VALUES (gen_random_uuid(), 'apisix-evil', 'APISIX', 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 6c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 6c phiên của tỉnh không ghi được node_heartbeat (COMMON)';
END $$;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.node_heartbeat;
  IF n <> 1 THEN RAISE EXCEPTION 'FAIL 6d: tỉnh phải thấy 1 nút, thấy %', n; END IF;
  RAISE NOTICE 'PASS 6d tỉnh đọc được trạng thái nút cổng dùng chung';
END $$;

-- 7. Mẫu G: quyền có thời hạn vào T68 do nhân sự nền tảng giữ
SET LOCAL app.tenant_id = 'T68';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.privileged_grant WHERE target_tenant = 'T68';
  IF n <> 1 THEN RAISE EXCEPTION 'FAIL 7a: quản trị T68 phải thấy 1 quyền đang mở vào tenant mình, thấy %', n; END IF;
  UPDATE ph12_iam.privileged_grant SET state = 'REVOKED', revoked_by = 'x', revoked_reason = 'x' WHERE id = pg_temp.u('grant1');
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 7a: tenant bị truy cập sửa được quyền của nền tảng'; END IF;
  RAISE NOTICE 'PASS 7a tenant bị truy cập đọc được, không sửa được quyền có thời hạn của nền tảng';
END $$;
SET LOCAL app.tenant_id = 'T01';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.privileged_grant;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 7b: T01 thấy quyền có thời hạn vào T68'; END IF;
  RAISE NOTICE 'PASS 7b tenant khác không thấy quyền có thời hạn';
END $$;
SET LOCAL app.tenant_id = 'T68';
DO $$ BEGIN
  INSERT INTO ph12_iam.privileged_grant (id, tenant_id, user_id, role_code, target_tenant, reason, ticket_ref, requested_hours, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.u('T01:adm1'), 'TENANT_ADMIN', 'T68', 'Ghi quyền vào tenant khác từ tỉnh', 'SUP-1', 1, 'x', 'x', 'x');
  RAISE EXCEPTION 'FAIL 7c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 7c phiên T68 không tạo được quyền cho tenant khác';
END $$;

-- 8. Không xóa vật lý: ứng dụng không có quyền DELETE, chủ bảng bị trigger chặn
DO $$ BEGIN
  DELETE FROM ph12_iam.user_account WHERE id = pg_temp.u('T68:usr1');
  RAISE EXCEPTION 'FAIL 8a';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 8a ứng dụng không xóa được tài khoản (BR-12-035)';
END $$;
RESET ROLE;
SET LOCAL ROLE ph12_owner;
SET LOCAL app.tenant_id = 'T68';
DO $$ BEGIN
  DELETE FROM ph12_iam.user_account WHERE id = pg_temp.u('T68:usr1');
  RAISE EXCEPTION 'FAIL 8b';
EXCEPTION WHEN sqlstate 'P1235' THEN RAISE NOTICE 'PASS 8b chủ bảng cũng không xóa được tài khoản (trigger tg_no_delete)';
END $$;
DO $$ BEGIN
  DELETE FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 8c';
EXCEPTION WHEN sqlstate 'P1235' THEN RAISE NOTICE 'PASS 8c phiên bản chính sách không xóa được';
END $$;
RESET ROLE;
SET LOCAL ROLE dh_platform_iam_app;
SET LOCAL app.tenant_id = 'T68';

-- 9. Tên đăng nhập, thư điện tử duy nhất trong tenant không phân biệt hoa thường; trùng giữa hai tenant được phép
-- (nguyenvana có ở cả T68 lẫn T01 từ phần dữ liệu đầu tệp)
DO $$ BEGIN
  INSERT INTO ph12_iam.user_account (id, tenant_id, username, full_name, email, org_code, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'nguyenvana', 'Người trùng tên', 'khac@gov.vn', 'VP', 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 9a';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 9a tên đăng nhập duy nhất trong tenant; trùng giữa T01 và T68 được phép';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.user_account (id, tenant_id, username, full_name, email, org_code, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ten.moi', 'Người trùng thư', 'NguyenVanA@GOV.vn', 'VP', 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 9c';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 9c thư điện tử duy nhất trong tenant, không phân biệt hoa thường (ERR-12-002)';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.user_account SET state = 'DISABLED' WHERE id = pg_temp.u('T68:usr1');
  RAISE EXCEPTION 'FAIL 9b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9b DISABLED phải có lý do và thời điểm';
END $$;

-- 10. Tách nhiệm vụ: cặp xung đột bị chặn (BR-12-030)
SELECT pg_temp.assign('eng1', 'INTEGRATION_ENGINEER');
DO $$ BEGIN
  PERFORM pg_temp.assign('eng1', 'INTEGRATION_APPROVER');
  RAISE EXCEPTION 'FAIL 10a';
EXCEPTION WHEN sqlstate 'P1209' THEN RAISE NOTICE 'PASS 10a chặn gán INTEGRATION_APPROVER cho kỹ sư tích hợp';
END $$;
SELECT pg_temp.assign('aud1', 'AUDITOR');
DO $$ BEGIN
  PERFORM pg_temp.assign('aud1', 'PAYMENT_ACCOUNTANT');
  RAISE EXCEPTION 'FAIL 10b';
EXCEPTION WHEN sqlstate 'P1209' THEN RAISE NOTICE 'PASS 10b chặn AUDITOR với vai trò ghi của PH-19';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.sod_exception (id, tenant_id, user_id, role_a, role_b, reason, expires_at, proposed_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('T68:aud1'), 'AUDITOR', 'PAYMENT_ACCOUNTANT', repeat('Thiếu nhân sự nên đề nghị ngoại lệ. ', 2), now() + interval '30 days', 'adm1', 'adm1', 'adm1');
  RAISE EXCEPTION 'FAIL 10c';
EXCEPTION WHEN sqlstate 'P1210' THEN RAISE NOTICE 'PASS 10c cặp có AUDITOR và vai trò ghi PH-19 không có ngoại lệ';
END $$;
-- 10d. Ngoại lệ hợp lệ: lý do dài, ≤ 90 ngày, người duyệt khác người đề nghị
DO $$ BEGIN
  INSERT INTO ph12_iam.sod_exception (id, tenant_id, user_id, role_a, role_b, reason, expires_at, proposed_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('T68:eng1'), 'INTEGRATION_APPROVER', 'INTEGRATION_ENGINEER', 'Tỉnh chỉ có một cán bộ tích hợp trong thời gian nghỉ phép', now() + interval '91 days', 'adm1', 'adm1', 'adm1');
  RAISE EXCEPTION 'FAIL 10d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10d ngoại lệ tối đa 90 ngày';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.sod_exception (id, tenant_id, user_id, role_a, role_b, reason, expires_at, proposed_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('T68:eng1'), 'INTEGRATION_APPROVER', 'INTEGRATION_ENGINEER', 'ngắn', now() + interval '30 days', 'adm1', 'adm1', 'adm1');
  RAISE EXCEPTION 'FAIL 10e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10e lý do ngoại lệ ít nhất 30 ký tự';
END $$;
INSERT INTO ph12_iam.sod_exception (id, tenant_id, user_id, role_a, role_b, reason, expires_at, proposed_by, created_by, updated_by)
VALUES (pg_temp.u('sodex1'), 'T68', pg_temp.u('T68:eng1'), 'INTEGRATION_APPROVER', 'INTEGRATION_ENGINEER', 'Tỉnh chỉ có một cán bộ tích hợp trong thời gian nghỉ phép', now() + interval '30 days', 'adm1', 'adm1', 'adm1');
DO $$ BEGIN
  UPDATE ph12_iam.sod_exception SET state = 'ACTIVE', approved_by = 'adm1', decided_at = now() WHERE id = pg_temp.u('sodex1');
  RAISE EXCEPTION 'FAIL 10f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10f người đề nghị không tự duyệt ngoại lệ (bốn mắt)';
END $$;
DO $$ BEGIN
  PERFORM pg_temp.assign('eng1', 'INTEGRATION_APPROVER');
  RAISE EXCEPTION 'FAIL 10g: ngoại lệ chưa duyệt không được mở cặp';
EXCEPTION WHEN sqlstate 'P1209' THEN RAISE NOTICE 'PASS 10g ngoại lệ chưa được duyệt thì vẫn chặn';
END $$;
UPDATE ph12_iam.sod_exception SET state = 'ACTIVE', approved_by = 'so1', decided_at = now() WHERE id = pg_temp.u('sodex1');
SELECT pg_temp.assign('eng1', 'INTEGRATION_APPROVER');
DO $$ BEGIN RAISE NOTICE 'PASS 10h ngoại lệ ACTIVE do SO duyệt cho phép gán cặp'; END $$;

-- 11. Không tự gán vai trò, PLATFORM_* chỉ ở tenant PLATFORM, vai trò máy không gán cho người
DO $$ BEGIN
  PERFORM pg_temp.assign('usr1', 'VIEWER', pg_temp.u('T68:usr1')::text);
  RAISE EXCEPTION 'FAIL 11a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11a không tự gán vai trò cho chính mình (BR-12-033)';
END $$;
DO $$ BEGIN
  PERFORM pg_temp.assign('usr1', 'PLATFORM_ADMIN');
  RAISE EXCEPTION 'FAIL 11b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11b PLATFORM_* chỉ gán ở tenant PLATFORM (BR-12-031)';
END $$;
DO $$ BEGIN
  PERFORM pg_temp.assign('usr1', 'PARTNER_SYSTEM');
  RAISE EXCEPTION 'FAIL 11c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11c PARTNER_SYSTEM chỉ gán cho client';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.role_assignment (id, tenant_id, user_id, role_code, scope_type, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('T68:usr1'), 'DATA_STEWARD', 'ORG', 'system:test', 'system:test');
  RAISE EXCEPTION 'FAIL 11d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11d phạm vi ORG phải nêu mã đơn vị';
END $$;
SELECT pg_temp.assign('usr1', 'DATA_STEWARD');
DO $$ BEGIN
  PERFORM pg_temp.assign('usr1', 'DATA_STEWARD');
  RAISE EXCEPTION 'FAIL 11e';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 11e một gán hiệu lực cho mỗi (người, vai trò, phạm vi)';
END $$;

-- 12. Luôn còn ít nhất một TENANT_ADMIN hoạt động (BR-12-033, ERR-12-046)
DO $$ BEGIN
  UPDATE ph12_iam.role_assignment SET state = 'REVOKED', revoked_at = now(), revoked_by = pg_temp.u('T68:so1')::text
   WHERE tenant_id = 'T68' AND role_code = 'TENANT_ADMIN';
  RAISE EXCEPTION 'FAIL 12a';
EXCEPTION WHEN sqlstate 'P1246' THEN RAISE NOTICE 'PASS 12a không gỡ được quản trị tỉnh cuối cùng';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.user_account SET state = 'DISABLED', disabled_reason = 'MANUAL', disabled_at = now() WHERE id = pg_temp.u('T68:adm1');
  RAISE EXCEPTION 'FAIL 12b';
EXCEPTION WHEN sqlstate 'P1246' THEN RAISE NOTICE 'PASS 12b không vô hiệu được quản trị tỉnh cuối cùng';
END $$;
SELECT pg_temp.assign('adm2', 'TENANT_ADMIN', pg_temp.u('T68:adm1')::text);
UPDATE ph12_iam.role_assignment SET state = 'REVOKED', revoked_at = now(), revoked_by = pg_temp.u('T68:adm2')::text
 WHERE tenant_id = 'T68' AND role_code = 'TENANT_ADMIN' AND user_id = pg_temp.u('T68:adm1');
DO $$ BEGIN RAISE NOTICE 'PASS 12c có quản trị thứ hai thì gỡ được quản trị đầu'; END $$;

-- 13. Nhóm tổ chức: cây ltree, cấm vòng lặp, đổi cha cập nhật cây con
INSERT INTO ph12_iam.org_group (id, tenant_id, code, name, created_by, updated_by) VALUES (pg_temp.u('g_root'), 'T68', 'VP_UBND', 'Văn phòng UBND', 'u1', 'u1');
INSERT INTO ph12_iam.org_group (id, tenant_id, code, name, parent_id, created_by, updated_by) VALUES (pg_temp.u('g_a'), 'T68', 'SO_TTTT', 'Sở TTTT', pg_temp.u('g_root'), 'u1', 'u1');
INSERT INTO ph12_iam.org_group (id, tenant_id, code, name, parent_id, created_by, updated_by) VALUES (pg_temp.u('g_b'), 'T68', 'PHONG_CNTT', 'Phòng CNTT', pg_temp.u('g_a'), 'u1', 'u1');
INSERT INTO ph12_iam.org_group (id, tenant_id, code, name, created_by, updated_by) VALUES (pg_temp.u('g_c'), 'T68', 'SO_YTE', 'Sở Y tế', 'u1', 'u1');
DO $$ DECLARE p text; BEGIN
  SELECT path::text INTO p FROM ph12_iam.org_group WHERE id = pg_temp.u('g_b');
  IF p <> 'VP_UBND.SO_TTTT.PHONG_CNTT' THEN RAISE EXCEPTION 'FAIL 13a: path = %', p; END IF;
  RAISE NOTICE 'PASS 13a trigger tính path ltree theo cha';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.org_group SET parent_id = pg_temp.u('g_b') WHERE id = pg_temp.u('g_root');
  RAISE EXCEPTION 'FAIL 13b';
EXCEPTION WHEN sqlstate 'P1212' THEN RAISE NOTICE 'PASS 13b cấm vòng lặp nhóm (BR-12-039)';
END $$;
UPDATE ph12_iam.org_group SET parent_id = pg_temp.u('g_c') WHERE id = pg_temp.u('g_a');
DO $$ DECLARE p text; BEGIN
  SELECT path::text INTO p FROM ph12_iam.org_group WHERE id = pg_temp.u('g_b');
  IF p <> 'SO_YTE.SO_TTTT.PHONG_CNTT' THEN RAISE EXCEPTION 'FAIL 13c: path = %', p; END IF;
  RAISE NOTICE 'PASS 13c đổi cha cập nhật path của cây con';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.org_group (id, tenant_id, code, name, type, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'X1', 'x', 'ORG', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 13d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13d nhóm ORG phải có mã đơn vị PH-07';
END $$;

-- 14. Quyền có thời hạn: tối đa 4 giờ, mã phiếu, bốn mắt, chỉ nền tảng đi tenant khác
SET LOCAL app.tenant_id = 'PLATFORM';
DO $$ BEGIN
  INSERT INTO ph12_iam.privileged_grant (id, tenant_id, user_id, role_code, target_tenant, reason, ticket_ref, requested_hours, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.u('PLATFORM:po1'), 'TENANT_ADMIN', 'T68', 'Đề nghị quá thời hạn tối đa của quyền', 'SUP-2', 5, 'x', 'x', 'x');
  RAISE EXCEPTION 'FAIL 14a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14a quyền có thời hạn không quá 4 giờ';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.privileged_grant SET state = 'ACTIVE', approved_by = pg_temp.u('PLATFORM:po1')::text, starts_at = now(), expires_at = now() + interval '2 hours', decided_at = now()
   WHERE id = pg_temp.u('grant1');
  RAISE EXCEPTION 'FAIL 14b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14b người đề nghị không tự duyệt quyền có thời hạn';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.privileged_grant SET state = 'ACTIVE', approved_by = pg_temp.u('PLATFORM:so_nt')::text, starts_at = now(), expires_at = now() + interval '5 hours', decided_at = now()
   WHERE id = pg_temp.u('grant1');
  RAISE EXCEPTION 'FAIL 14c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14c cửa sổ hiệu lực không quá 4 giờ';
END $$;
UPDATE ph12_iam.privileged_grant SET state = 'ACTIVE', approved_by = pg_temp.u('PLATFORM:so_nt')::text, starts_at = now(), expires_at = now() + interval '2 hours', decided_at = now()
 WHERE id = pg_temp.u('grant1');
DO $$ BEGIN RAISE NOTICE 'PASS 14d duyệt hợp lệ chuyển ACTIVE'; END $$;
SET LOCAL app.tenant_id = 'T68';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.privileged_grant WHERE target_tenant = 'T68' AND state = 'ACTIVE';
  IF n <> 1 THEN RAISE EXCEPTION 'FAIL 14e'; END IF;
  RAISE NOTICE 'PASS 14e quản trị tỉnh thấy quyền ACTIVE vào tenant mình';
END $$;

-- 15. Client: mức hợp đồng quyết định phương thức xác thực; một client sống cho mỗi HTTT; scope theo nguồn
DO $$ BEGIN
  INSERT INTO ph12_iam.client (id, tenant_id, client_id, system_code, org_code, name, auth_method, contract_level, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ht-nhay-cam', 'HT_NHAY_CAM', 'SO_YTE', 'HT nhạy cảm', 'PRIVATE_KEY_JWT', 'SENSITIVE', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 15a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15a mức Nhạy cảm bắt buộc mTLS (BR-12-024)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.client (id, tenant_id, client_id, system_code, org_code, name, auth_method, contract_level, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ht-han-che', 'HT_HAN_CHE', 'SO_YTE', 'HT hạn chế', 'CLIENT_SECRET', 'RESTRICTED', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 15b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15b mức Hạn chế cấm client_secret';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.client (id, tenant_id, client_id, system_code, org_code, name, auth_method, contract_level, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'qlvb-so-tttt-2', 'QLVB_SO_TTTT', 'SO_TTTT', 'Trùng HTTT', 'MTLS', 'RESTRICTED', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 15c';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 15c một HTTT chỉ một client đang sống (ERR-12-018)';
END $$;
UPDATE ph12_iam.client SET state = 'REVOKED', revoked_at = now(), revoked_reason = 'Nghi lộ khóa' WHERE id = pg_temp.u('cli68');
INSERT INTO ph12_iam.client (id, tenant_id, client_id, system_code, org_code, name, auth_method, contract_level, created_by, updated_by)
VALUES (pg_temp.u('cli68b'), 'T68', 'qlvb-so-tttt-r2', 'QLVB_SO_TTTT', 'SO_TTTT', 'Cấp lại sau thu hồi', 'MTLS', 'RESTRICTED', 'u1', 'u1');
DO $$ BEGIN
  INSERT INTO ph12_iam.client (id, tenant_id, client_id, system_code, org_code, name, auth_method, contract_level, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'qlvb-so-tttt', 'QLVB_KHAC', 'SO_TTTT', 'Dùng lại mã client đã thu hồi', 'MTLS', 'RESTRICTED', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 15d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 15d cấp lại sau thu hồi được nhưng không dùng lại mã client';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.client_scope (id, tenant_id, client_pk, scope, source, created_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('cli68b'), 'topic:t68.rdm.x:publish', 'PH-02', 'u1');
  RAISE EXCEPTION 'FAIL 15e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15e mỗi nguồn chỉ đặt loại scope của mình (BR-12-025)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.client_scope (id, tenant_id, client_pk, scope, source, created_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('cli68b'), 'iam:decide', 'PH-02', 'u1');
  RAISE EXCEPTION 'FAIL 15f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15f scope nội bộ iam:* không do nguồn nghiệp vụ cấp';
END $$;
INSERT INTO ph12_iam.client_scope (id, tenant_id, client_pk, scope, source, created_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('cli68b'), 'api:ktvc-tra-cuu:goi-co-ban', 'PH-02', 'u1');
DO $$ BEGIN RAISE NOTICE 'PASS 15g scope api: từ PH-02 hợp lệ'; END $$;

-- 16. Thông tin xác thực của client: không bí mật, hạn bí mật ≤ 180 ngày, một bản ACTIVE mỗi loại
DO $$ BEGIN
  INSERT INTO ph12_iam.client_credential (id, tenant_id, client_pk, kind, not_after, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('cli68b'), 'SECRET', now() + interval '200 days', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 16a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16a bí mật client hết hạn không quá 180 ngày (BR-12-023)';
END $$;
INSERT INTO ph12_iam.client_credential (id, tenant_id, client_pk, kind, thumbprint, subject_dn, not_before, not_after, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.u('cli68b'), 'CERT', repeat('a', 64), 'CN=qlvb', now(), now() + interval '1 year', 'u1', 'u1');
DO $$ BEGIN
  INSERT INTO ph12_iam.client_credential (id, tenant_id, client_pk, kind, thumbprint, subject_dn, not_before, not_after, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('cli68b'), 'CERT', repeat('b', 64), 'CN=qlvb2', now(), now() + interval '1 year', 'u1', 'u1');
  RAISE EXCEPTION 'FAIL 16b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 16b một chứng thư ACTIVE mỗi client (cần TRANSITION khi xoay)';
END $$;

-- 17. Danh sách chặn: ghi trước, tăng phiên bản, không tự thu hồi, hạ cờ phải có xác nhận Keycloak
DO $$ DECLARE v0 bigint; v1 bigint; BEGIN
  SELECT version INTO v0 FROM ph12_iam.revocation_feed_version;
  INSERT INTO ph12_iam.revocation_entry (id, tenant_id, kind, value, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'SUB', pg_temp.u('T68:usr1')::text, 'Nghi ngờ lộ tài khoản', pg_temp.u('T68:so1')::text, 'system:test');
  SELECT version INTO v1 FROM ph12_iam.revocation_feed_version;
  IF v1 <= v0 THEN RAISE EXCEPTION 'FAIL 17a: phiên bản danh sách chặn không tăng (% → %)', v0, v1; END IF;
  RAISE NOTICE 'PASS 17a ghi danh sách chặn tăng phiên bản (% → %)', v0, v1;
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.revocation_entry (id, tenant_id, kind, value, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'SUB', pg_temp.u('T68:so2')::text, 'Tự thu hồi mình', pg_temp.u('T68:so2')::text, 'x');
  RAISE EXCEPTION 'FAIL 17b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17b không tự thu hồi truy cập của chính mình (BR-12-033)';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.revocation_entry SET block_all = false, expires_at = now() + interval '330 seconds' WHERE id = pg_temp.u('rev68');
  RAISE EXCEPTION 'FAIL 17c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17c hạ block_all phải có xác nhận của Keycloak';
END $$;
UPDATE ph12_iam.revocation_entry SET block_all = false, expires_at = now() + interval '330 seconds', keycloak_confirmed_at = now() WHERE id = pg_temp.u('rev68');
DO $$ BEGIN
  INSERT INTO ph12_iam.revocation_entry (id, tenant_id, kind, value, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'JTI', 'jti-123', 'ab', 'x', 'x');
  RAISE EXCEPTION 'FAIL 17d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17d thu hồi phải nêu lý do (BR-12-028)';
END $$;

-- 18. Chính sách: máy trạng thái, kiểm thử và chạy khô gắn với băm, bốn mắt, bất biến, chính sách gốc
DO $$ DECLARE h text; BEGIN
  SELECT content_hash INTO h FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
  IF h <> encode(sha256(convert_to(E'package dh.tenant_rules.t68\ndeny contains "OUT_OF_HOURS" if { false }', 'UTF8')), 'hex') THEN RAISE EXCEPTION 'FAIL 18a: băm sai'; END IF;
  RAISE NOTICE 'PASS 18a CSDL tự tính content_hash = SHA-256 của nội dung';
END $$;
INSERT INTO ph12_iam.policy_version_contributor (id, tenant_id, version_id, user_ref, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.u('pv68'), pg_temp.u('T68:so1')::text, 'u1'), (gen_random_uuid(), 'T68', pg_temp.u('pv68'), 'contrib2', 'u1');
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'PUBLISHED', bundle_revision = 't68-20261126-0001', published_at = now(), approved_by = 'x', approved_at = now(), submitted_by = 'y', submitted_at = now() WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18b';
EXCEPTION WHEN sqlstate 'P1227' THEN RAISE NOTICE 'PASS 18b DRAFT không nhảy thẳng sang PUBLISHED (ADR-069)';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'PENDING_REVIEW', submitted_by = 'sub1', submitted_at = now() WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18c';
EXCEPTION WHEN sqlstate 'P1225' THEN RAISE NOTICE 'PASS 18c chưa có kiểm thử đạt thì không gửi duyệt (ERR-12-025)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.policy_test_run (id, tenant_id, version_id, content_hash, base_bundle_revision, passed, total_cases, positive_cases, negative_cases, failed_cases, coverage_pct, started_at, finished_at, trace_id, created_by)
  SELECT gen_random_uuid(), 'T68', id, content_hash, 'platform-20261126-0001', true, 4, 2, 2, 1, 95, now(), now(), repeat('0', 32), 'runner' FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18d kết quả đạt không được có ca lỗi';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.policy_test_run (id, tenant_id, version_id, content_hash, base_bundle_revision, passed, total_cases, positive_cases, negative_cases, failed_cases, coverage_pct, started_at, finished_at, trace_id, created_by)
  SELECT gen_random_uuid(), 'T68', id, content_hash, 'platform-20261126-0001', true, 4, 2, 2, 0, 85, now(), now(), repeat('0', 32), 'runner' FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18e kết quả đạt phải phủ ≥ 90%% (SEC-26)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.policy_test_run (id, tenant_id, version_id, content_hash, base_bundle_revision, passed, total_cases, positive_cases, negative_cases, failed_cases, coverage_pct, started_at, finished_at, trace_id, created_by)
  SELECT gen_random_uuid(), 'T68', id, content_hash, 'platform-20261126-0001', true, 3, 3, 0, 0, 95, now(), now(), repeat('0', 32), 'runner' FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18f kết quả đạt phải có ít nhất một ca dương và một ca âm';
END $$;
INSERT INTO ph12_iam.policy_test_run (id, tenant_id, version_id, content_hash, base_bundle_revision, passed, total_cases, positive_cases, negative_cases, failed_cases, coverage_pct, started_at, finished_at, trace_id, created_by)
SELECT gen_random_uuid(), 'T68', id, content_hash, 'platform-20261126-0001', true, 6, 3, 3, 0, 96.5, now(), now(), repeat('0', 32), 'runner' FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'PENDING_REVIEW', submitted_by = 'sub1', submitted_at = now() WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18g';
EXCEPTION WHEN sqlstate 'P1226' THEN RAISE NOTICE 'PASS 18g đạt kiểm thử nhưng chưa chạy khô thì không gửi duyệt (ERR-12-026)';
END $$;
INSERT INTO ph12_iam.policy_dryrun_report (id, tenant_id, version_id, content_hash, base_bundle_revision, status, window_from, window_to, sample_count, changed_count, deny_to_allow_count, finished_at, created_by)
SELECT gen_random_uuid(), 'T68', id, content_hash, 'platform-20261126-0001', 'DONE', now() - interval '24 hours', now(), 1000, 300, 0, now(), 'runner' FROM ph12_iam.policy_version WHERE id = pg_temp.u('pv68');
UPDATE ph12_iam.policy_version SET state = 'PENDING_REVIEW', submitted_by = 'sub1', submitted_at = now() WHERE id = pg_temp.u('pv68');
DO $$ BEGIN RAISE NOTICE 'PASS 18h kiểm thử đạt và chạy khô đúng băm thì gửi duyệt được'; END $$;
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET content = content || E'\n# sửa', state = 'DRAFT' WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18i';
EXCEPTION WHEN sqlstate 'P1227' THEN RAISE NOTICE 'PASS 18i nội dung bất biến sau khi gửi duyệt';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'APPROVED', approved_by = 'contrib2', approved_at = now() WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18j';
EXCEPTION WHEN sqlstate 'P1208' THEN RAISE NOTICE 'PASS 18j người đóng góp không duyệt được (bốn mắt, BR-12-008)';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'APPROVED', approved_by = 'sub1', approved_at = now(), high_impact_confirmed = true WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18k';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18k người gửi duyệt không tự duyệt';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'APPROVED', approved_by = 'reviewer9', approved_at = now() WHERE id = pg_temp.u('pv68');
  RAISE EXCEPTION 'FAIL 18l';
EXCEPTION WHEN sqlstate 'P1229' THEN RAISE NOTICE 'PASS 18l chạy khô đổi 30%% > 20%% cần xác nhận bổ sung (BR-12-011)';
END $$;
UPDATE ph12_iam.policy_version SET state = 'APPROVED', approved_by = 'reviewer9', approved_at = now(), high_impact_confirmed = true WHERE id = pg_temp.u('pv68');
UPDATE ph12_iam.policy_version SET state = 'PUBLISHED', bundle_revision = 't68-20261126-0001', published_at = now() WHERE id = pg_temp.u('pv68');
DO $$ BEGIN RAISE NOTICE 'PASS 18m duyệt đủ điều kiện rồi PUBLISHED'; END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.policy_version (id, tenant_id, policy_id, version_no, content, state, author, submitted_by, submitted_at, approved_by, approved_at, bundle_revision, published_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('pol68'), 2, 'package dh.tenant_rules.t68', 'PUBLISHED', 'a', 'b', now(), 'c', now(), 't68-20261126-0002', now(), 'u', 'u');
  RAISE EXCEPTION 'FAIL 18n';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 18n mỗi mã chính sách đúng một phiên bản PUBLISHED (BR-12-010)';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.policy_test_run SET passed = false WHERE tenant_id = 'T68';
  RAISE EXCEPTION 'FAIL 18o';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 18o ứng dụng không sửa được kết quả kiểm thử (chỉ thêm)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.policy (id, tenant_id, code, scope, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'x-sai-pham-vi', 'PLATFORM', 'x', 'u', 'u');
  RAISE EXCEPTION 'FAIL 18p';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18p chính sách phạm vi PLATFORM chỉ thuộc tenant PLATFORM';
END $$;
SET LOCAL app.tenant_id = 'PLATFORM';
INSERT INTO ph12_iam.policy_version (id, tenant_id, policy_id, version_no, content, state, author, submitted_by, submitted_at, approved_by, approved_at, bundle_revision, published_at, created_by, updated_by)
VALUES (pg_temp.u('pvbase'), 'PLATFORM', pg_temp.u('base'), 1, 'package dh.authz', 'PUBLISHED', 'a', 'b', now(), 'c', now(), 'platform-20261126-0001', now(), 'u', 'u');
DO $$ BEGIN
  UPDATE ph12_iam.policy_version SET state = 'REVOKED', revoked_by = 'x', revoked_reason = 'thử thu hồi chính sách gốc' WHERE id = pg_temp.u('pvbase');
  RAISE EXCEPTION 'FAIL 18q';
EXCEPTION WHEN sqlstate 'P1227' THEN RAISE NOTICE 'PASS 18q không thu hồi được chính sách gốc base-authz (ERR-12-027)';
END $$;

-- 19. Gói chính sách và xác nhận nạp
INSERT INTO ph12_iam.bundle_release (id, tenant_id, bundle_kind, bundle_revision, state, digest, signing_kid, signed_at, object_key, published_at, created_by, updated_by)
VALUES (pg_temp.u('bundle_pf'), 'PLATFORM', 'PLATFORM', 'platform-20261126-0001', 'PUBLISHED', repeat('a', 64), 'k1', now(), 'platform/bundle.tar.gz', now(), 'system:test', 'system:test');
DO $$ BEGIN
  INSERT INTO ph12_iam.bundle_release (id, tenant_id, bundle_kind, bundle_revision, state, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'TENANT', 'platform-20261126-0002', 'BUILDING', 'u', 'u');
  RAISE EXCEPTION 'FAIL 19a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 19a gói TENANT không thuộc tenant PLATFORM';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.bundle_release (id, tenant_id, bundle_kind, bundle_revision, state, digest, signing_kid, signed_at, object_key, published_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'PLATFORM', 'PLATFORM', 'platform-20261126-0003', 'PUBLISHED', repeat('b', 64), 'k1', now(), 'platform/b3.tar.gz', now(), 'u', 'u');
  RAISE EXCEPTION 'FAIL 19b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 19b mỗi tenant đúng một gói PUBLISHED';
END $$;
SET LOCAL app.tenant_id = 'T68';
DO $$ BEGIN
  INSERT INTO ph12_iam.bundle_release (id, tenant_id, bundle_kind, bundle_revision, state, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'TENANT', 't01-20261126-0001', 'BUILDING', 'u', 'u');
  RAISE EXCEPTION 'FAIL 19c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 19c bundleRevision mang mã tenant của gói';
END $$;
INSERT INTO ph12_iam.bundle_release (id, tenant_id, bundle_kind, bundle_revision, state, digest, signing_kid, signed_at, object_key, published_at, created_by, updated_by)
VALUES (pg_temp.u('bundle68'), 'T68', 'TENANT', 't68-20261126-0153', 'PUBLISHED', repeat('c', 64), 'k1', now(), 'tenants/t68/bundle.tar.gz', now(), 'system:test', 'system:test');
INSERT INTO ph12_iam.bundle_ack (id, tenant_id, release_id, node_id, active_revision, created_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('bundle68'), 'opa-apisix-0', 't68-20261126-0153', 'system:status');
DO $$ BEGIN
  INSERT INTO ph12_iam.bundle_ack (id, tenant_id, release_id, node_id, active_revision, created_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('bundle68'), 'opa-apisix-0', 't68-20261126-0153', 'system:status');
  RAISE EXCEPTION 'FAIL 19d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 19d mỗi nút xác nhận một lần cho mỗi bản phát hành';
END $$;

-- 20. Realm và dữ liệu của nền tảng
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph12_iam.realm_state;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 20a: tenant thấy realm_state của nền tảng'; END IF;
  RAISE NOTICE 'PASS 20a tỉnh không thấy trạng thái realm (dữ liệu của nền tảng)';
END $$;
SET LOCAL app.tenant_id = 'PLATFORM';
DO $$ BEGIN
  INSERT INTO ph12_iam.realm_state (id, tenant_code, realm_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T69', 'dh-t68', 'u', 'u');
  RAISE EXCEPTION 'FAIL 20b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20b tên realm phải là dh-{tenant viết thường}';
END $$;
DO $$ BEGIN
  UPDATE ph12_iam.realm_state SET drift_status = 'HELD' WHERE tenant_code = 'T68';
  RAISE EXCEPTION 'FAIL 20c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20c giữ tạm lệch cấu hình phải có lý do, người xác nhận, hạn';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.service_account (id, account_code, du_code, scopes, declaration_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'dh-integration', 'dh-integration', ARRAY['iam:decide', 'khong-hop-le'], 'mr-1', 'u', 'u');
  RAISE EXCEPTION 'FAIL 20d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20d scope của tài khoản dịch vụ phải đúng dạng loại:giá trị';
END $$;
SET LOCAL app.tenant_id = 'T68';
DO $$ BEGIN
  INSERT INTO ph12_iam.service_account (id, tenant_id, account_code, du_code, scopes, declaration_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'dh-x', 'dh-platform', ARRAY['iam:decide'], 'mr-1', 'u', 'u');
  RAISE EXCEPTION 'FAIL 20e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20e tài khoản dịch vụ chỉ ở tenant PLATFORM';
END $$;

-- 21. Liên kết ngoài: LDAPS, kiểm tra đạt mới gửi duyệt, SO khác TA duyệt, VNeID chỉ băm
DO $$ BEGIN
  INSERT INTO ph12_iam.federation (id, tenant_id, code, name, kind, url, base_dn, bind_dn, secret_ref, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ad-tinh', 'AD tỉnh', 'AD', 'ldap://ad.t68.gov.vn', 'DC=t68,DC=gov,DC=vn', 'CN=svc,DC=t68', 'kv/dh/t68/iam/ldap/ad-tinh', 'u', 'u');
  RAISE EXCEPTION 'FAIL 21a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 21a chỉ cho phép LDAPS';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.federation (id, tenant_id, code, name, kind, url, base_dn, bind_dn, secret_ref, state, proposed_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ad-tinh', 'AD tỉnh', 'AD', 'ldaps://ad.t68.gov.vn:636', 'DC=t68,DC=gov,DC=vn', 'CN=svc,DC=t68', 'kv/dh/t68/iam/ldap/ad-tinh', 'PENDING_APPROVAL', 'adm1', 'u', 'u');
  RAISE EXCEPTION 'FAIL 21b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 21b chưa đạt ba kiểm tra thì không gửi duyệt (ERR-12-032)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.federation (id, tenant_id, code, name, kind, url, base_dn, bind_dn, secret_ref, state, tests_passed_at, proposed_by, approved_by, approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ad-tinh', 'AD tỉnh', 'AD', 'ldaps://ad.t68.gov.vn:636', 'DC=t68,DC=gov,DC=vn', 'CN=svc,DC=t68', 'kv/dh/t68/iam/ldap/ad-tinh', 'ACTIVE', now(), 'adm1', 'adm1', now(), 'u', 'u');
  RAISE EXCEPTION 'FAIL 21c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 21c người đề nghị không tự duyệt liên kết LDAP';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.federation (id, tenant_id, code, name, kind, url, base_dn, bind_dn, secret_ref, attribute_map, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ad-tinh', 'AD tỉnh', 'AD', 'ldaps://ad.t68.gov.vn:636', 'DC=t68', 'CN=svc', 'kv/dh/t68/iam/ldap/ad-tinh', '{"bindPassword": "abc"}', 'u', 'u');
  RAISE EXCEPTION 'FAIL 21d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 21d bản đồ thuộc tính không chứa bí mật';
END $$;
INSERT INTO ph12_iam.vneid_link (id, tenant_id, user_id, subject_hash, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('T68:usr1'), repeat('d', 64), 'u', 'u');
DO $$ BEGIN
  INSERT INTO ph12_iam.vneid_link (id, tenant_id, user_id, subject_hash, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('T68:eng1'), repeat('d', 64), 'u', 'u');
  RAISE EXCEPTION 'FAIL 21e';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 21e một định danh VNeID chỉ liên kết một tài khoản (ERR-12-034)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.saml_client (id, tenant_id, entity_id, name, acs_urls, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'https://app.t68.gov.vn/sp', 'Ứng dụng cũ', ARRAY['https://app.t68.gov.vn/*'], 'u', 'u');
  RAISE EXCEPTION 'FAIL 21f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 21f SAML cấm ký tự đại diện ở redirect URI';
END $$;

-- 22. Rà soát quyền, cảnh báo, không lưu bí mật
INSERT INTO ph12_iam.recert_campaign (id, tenant_id, code, kind, due_at, created_by, updated_by) VALUES (pg_temp.u('camp1'), 'T68', 'RS-2026-Q4', 'ADMIN', now() + interval '14 days', 'u', 'u');
DO $$ BEGIN
  INSERT INTO ph12_iam.recert_campaign (id, tenant_id, code, kind, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'RS-2026-Q4b', 'ADMIN', now() + interval '14 days', 'u', 'u');
  RAISE EXCEPTION 'FAIL 22a';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 22a một chiến dịch rà soát mở cho mỗi loại (ERR-12-031)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.recert_item (id, tenant_id, campaign_id, user_id, assignment_id, reviewer_user_id, created_by, updated_by)
  SELECT gen_random_uuid(), 'T68', pg_temp.u('camp1'), a.user_id, a.id, a.user_id, 'u', 'u' FROM ph12_iam.role_assignment a WHERE a.user_id = pg_temp.u('T68:usr1') LIMIT 1;
  RAISE EXCEPTION 'FAIL 22b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22b không tự rà soát quyền của mình (BR-12-044)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.alert (id, tenant_id, rule_code, severity, subject_kind, subject_ref, dedup_key, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'AN-05', 'HIGH', 'USER', 'u1', 'k1', 'u', 'u');
  RAISE EXCEPTION 'FAIL 22c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22c mức nghiêm trọng của cảnh báo theo luật (AN-05 là nghiêm trọng)';
END $$;
INSERT INTO ph12_iam.alert (id, tenant_id, rule_code, severity, subject_kind, subject_ref, dedup_key, created_by, updated_by) VALUES (pg_temp.u('alert1'), 'T68', 'AN-05', 'CRITICAL', 'USER', 'u1', 'AN-05|u1|202611260900', 'u', 'u');
DO $$ BEGIN
  INSERT INTO ph12_iam.alert (id, tenant_id, rule_code, severity, subject_kind, subject_ref, dedup_key, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'AN-05', 'CRITICAL', 'USER', 'u1', 'AN-05|u1|202611260900', 'u', 'u');
  RAISE EXCEPTION 'FAIL 22d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 22d cùng sự việc trong ô 30 phút chỉ một cảnh báo';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.outbox (event_id, tenant_id, event_type, aggregate_type, aggregate_id, topic, partition_key, payload) VALUES (gen_random_uuid(), 'T68', 'EVT-12-01', 'UserAccount', pg_temp.u('T68:usr1'), 't01.iam.user.created.v1', 'k', '{}');
  RAISE EXCEPTION 'FAIL 22e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22e outbox: topic phải mang đúng mã tenant';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.outbox (event_id, tenant_id, event_type, aggregate_type, aggregate_id, topic, partition_key, payload) VALUES (gen_random_uuid(), 'T68', 'EVT-12-06', 'Client', pg_temp.u('cli68b'), 't68.iam.client.provisioned.v1', 'k', '{"client":{"clientSecret":"abc"}}');
  RAISE EXCEPTION 'FAIL 22f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22f outbox không chứa khóa bí mật, kể cả lồng';
END $$;
INSERT INTO ph12_iam.outbox (event_id, tenant_id, event_type, aggregate_type, aggregate_id, topic, partition_key, payload) VALUES (gen_random_uuid(), 'T68', 'EVT-12-06', 'Client', pg_temp.u('cli68b'), 't68.iam.client.provisioned.v1', 'qlvb-so-tttt-r2', '{"clientId":"qlvb-so-tttt-r2"}');
DO $$ BEGIN
  INSERT INTO ph12_iam.idempotency_key (id, tenant_id, idem_key, method, path, body_hash, state, response_status, response_body, created_by)
  VALUES (gen_random_uuid(), 'T68', 'idem-key-0001', 'POST', '/api/iam/v1/clients', repeat('e', 64), 'DONE', 201, '{"secretHandover":{"wrappingToken":"hvs.xxx"}}', 'u');
  RAISE EXCEPTION 'FAIL 22g';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22g phản hồi lũy đẳng không được lưu wrappingToken (BR-12-023)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.user_import (id, tenant_id, file_name, file_ref, file_sha256, file_purge_at, created_by, updated_by) VALUES (pg_temp.u('imp1'), 'T68', 'ds.xlsx', 'imp/1', repeat('f', 64), now() + interval '24 hours', 'u', 'u');
  INSERT INTO ph12_iam.user_import_row (id, tenant_id, import_id, row_no, raw, result, created_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u('imp1'), 1, '{"username":"a.b","password":"123456"}', 'OK', 'u');
  RAISE EXCEPTION 'FAIL 22h';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22h tệp nhập không được mang mật khẩu (BR-12-043)';
END $$;
DO $$ BEGIN
  INSERT INTO ph12_iam.sync_task (id, tenant_id, task_type, target_kind, target_id, payload, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'CREATE_USER', 'USER', pg_temp.u('T68:usr1'), '{"temporaryPassword":"x","token":"y"}', 'u', 'u');
  RAISE EXCEPTION 'FAIL 22i';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22i ý định đồng bộ không chứa bí mật';
END $$;

-- 23. Quyền của vai trò: ứng dụng không xóa gán vai trò, chỉ đọc không thấy bí mật, thông tin cá nhân
DO $$ BEGIN
  DELETE FROM ph12_iam.role_assignment WHERE tenant_id = 'T68';
  RAISE EXCEPTION 'FAIL 23a';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 23a ứng dụng không xóa được gán vai trò (kết thúc bằng trạng thái)';
END $$;
RESET ROLE;
DO $$ BEGIN
  IF has_table_privilege('ph12_readonly', 'ph12_iam.client_credential', 'SELECT') THEN RAISE EXCEPTION 'FAIL 23b: readonly đọc được client_credential'; END IF;
  IF has_table_privilege('ph12_readonly', 'ph12_iam.federation', 'SELECT') THEN RAISE EXCEPTION 'FAIL 23b: readonly đọc được federation'; END IF;
  IF has_table_privilege('ph12_readonly', 'ph12_iam.user_import_row', 'SELECT') THEN RAISE EXCEPTION 'FAIL 23b: readonly đọc được user_import_row'; END IF;
  IF has_column_privilege('ph12_readonly', 'ph12_iam.user_account', 'email', 'SELECT') THEN RAISE EXCEPTION 'FAIL 23c: readonly đọc được email'; END IF;
  IF NOT has_column_privilege('ph12_readonly', 'ph12_iam.user_account', 'state', 'SELECT') THEN RAISE EXCEPTION 'FAIL 23c: readonly không đọc được state'; END IF;
  IF has_table_privilege('ph12_app', 'ph12_iam.policy_test_run', 'UPDATE') THEN RAISE EXCEPTION 'FAIL 23d: ứng dụng sửa được kết quả kiểm thử'; END IF;
  IF has_table_privilege('ph12_app', 'ph12_iam.sod_pair', 'INSERT') THEN RAISE EXCEPTION 'FAIL 23d: ứng dụng ghi được sod_pair'; END IF;
  IF has_table_privilege('ph12_app', 'ph12_iam.user_account', 'DELETE') THEN RAISE EXCEPTION 'FAIL 23d: ứng dụng xóa được tài khoản'; END IF;
  IF has_table_privilege('ph12_app', 'ph12_iam.bundle_release', 'DELETE') THEN RAISE EXCEPTION 'FAIL 23d: ứng dụng xóa được bản phát hành gói'; END IF;
  IF has_function_privilege('ph12_app', 'ph12_iam.p_enable_rls(regclass, char)', 'EXECUTE') THEN RAISE EXCEPTION 'FAIL 23e: ứng dụng gọi được p_enable_rls'; END IF;
  RAISE NOTICE 'PASS 23b-e quyền của ph12_readonly, ph12_app đúng thiết kế (không bí mật, không email, không xóa, không sửa chứng cứ)';
END $$;

-- 24. Vai trò ứng dụng không BYPASSRLS; mọi bảng có tenant_id đều FORCE RLS (trừ bảng kỹ thuật không có tenant_id)
DO $$ DECLARE r record; n int := 0; BEGIN
  IF (SELECT rolbypassrls OR rolsuper FROM pg_roles WHERE rolname = 'dh_platform_iam_app') THEN RAISE EXCEPTION 'FAIL 24a: tài khoản ứng dụng có BYPASSRLS'; END IF;
  FOR r IN SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
           WHERE s.nspname = 'ph12_iam' AND c.relkind IN ('r', 'p') AND NOT c.relispartition
             AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped) LOOP
    n := n + 1;
    IF NOT (r.relrowsecurity AND r.relforcerowsecurity) THEN RAISE EXCEPTION 'FAIL 24b: % chưa bật FORCE RLS', r.relname; END IF;
  END LOOP;
  IF n <> 41 THEN RAISE EXCEPTION 'FAIL 24c: có % bảng có tenant_id, mong đợi 41', n; END IF;
  RAISE NOTICE 'PASS 24 % bảng có tenant_id đều FORCE RLS; ứng dụng không BYPASSRLS', n;
END $$;

ROLLBACK;
