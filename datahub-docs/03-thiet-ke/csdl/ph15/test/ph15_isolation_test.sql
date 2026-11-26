-- =============================================================================
-- D03-03-PH15 · Kiểm thử DDL ph15_portal: cô lập tenant, bất biến, bốn mắt, ràng buộc nghiệp vụ.
-- Chạy sau ph15/ddl/ph15_portal.sql trên CSDL rỗng, bằng siêu người dùng (tệp tự chuyển sang dh_portal_app):
--   psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph15_isolation_test.sql
-- Mỗi ca ghi PASS qua NOTICE; ca sai thì RAISE EXCEPTION và tệp dừng. Tương ứng TS-15 cô lập (D05-02-PH15).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_portal_app') THEN
    CREATE ROLE dh_portal_app LOGIN NOBYPASSRLS IN ROLE ph15_app;
  END IF;
END $$;
SET ROLE dh_portal_app;

CREATE FUNCTION pg_temp.u(n int) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('00000000-0000-7000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.expect(p_label text, p_sql text, p_state text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE ok boolean := false;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = p_state THEN ok := true;
    ELSE RAISE EXCEPTION 'FAIL %: SQLSTATE % thay vì %: %', p_label, SQLSTATE, p_state, SQLERRM; END IF;
  END;
  IF NOT ok THEN RAISE EXCEPTION 'FAIL %: câu lệnh không bị chặn', p_label; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;
CREATE FUNCTION pg_temp.expect_count(p_label text, p_sql text, p_n bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  EXECUTE p_sql INTO n;
  IF n <> p_n THEN RAISE EXCEPTION 'FAIL %: được % dòng, cần %', p_label, n, p_n; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
SELECT ph15_portal.seed_tenant('T68', 'u1');
INSERT INTO ph15_portal.catalog_api (id, tenant_id, origin_tenant_id, api_code, name, summary, owner_org_code, field_domain, data_class, visibility, portal_published, tags, source_version, synced_at, created_by, updated_by)
VALUES (pg_temp.u(1), 'T68', 'T68', 'tra-cuu-ho-tich', 'Tra cứu hộ tịch', 'Tra cứu thông tin đăng ký hộ tịch', 'STP68', 'tu-phap', 'INTERNAL', 'TENANT', true, ARRAY['hộ tịch'], 10, now(), 'u1', 'u1');
INSERT INTO ph15_portal.catalog_api (id, tenant_id, origin_tenant_id, api_code, name, data_class, visibility, portal_published, source_version, synced_at, created_by, updated_by)
VALUES (pg_temp.u(2), 'T68', 'T68', 'tra-cuu-dat-dai', 'Tra cứu đất đai', 'SENSITIVE', 'TENANT', false, 11, now(), 'u1', 'u1');
INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, created_by, updated_by)
VALUES (pg_temp.u(10), 'T68', 'kc-an', 'TENANT_SSO', 'ACTIVE', 'nguyen.van.an@example.gov.vn', 'Nguyễn Văn An', 'u1', 'u1');
INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, organization, contract_no, email_verified_at, approved_by, approved_at, created_by, updated_by)
VALUES (pg_temp.u(11), 'T68', 'kc-binh', 'DH_DEV', 'ACTIVE', 'tran.binh@thau-a.vn', 'Trần Bình', 'Công ty Thầu A', 'HD-2026-07', now(), 'admin1', now(), 'u1', 'u1');
INSERT INTO ph15_portal.dev_team (id, tenant_id, team_code, name, created_by, updated_by) VALUES (pg_temp.u(20), 'T68', 'nhom-thau-a', 'Nhóm thầu A', 'u1', 'u1');
INSERT INTO ph15_portal.dev_team_member (id, tenant_id, team_id, account_id, role, invite_status, created_by, updated_by)
VALUES (pg_temp.u(21), 'T68', pg_temp.u(20), pg_temp.u(11), 'OWNER', 'ACCEPTED', 'u1', 'u1');
INSERT INTO ph15_portal.app (id, tenant_id, app_code, name, owner_type, owner_account_id, created_by, updated_by)
VALUES (pg_temp.u(30), 'T68', 'app-tra-cuu-ho-tich', 'Ứng dụng tra cứu hộ tịch', 'USER', pg_temp.u(11), 'u1', 'u1');
INSERT INTO ph15_portal.app_credential (id, tenant_id, app_id, kind, client_id, key_prefix, expires_at, created_by, updated_by)
VALUES (pg_temp.u(31), 'T68', pg_temp.u(30), 'CLIENT_CREDENTIALS', 'sbx-t68-app-tra-cuu-ho-tich-1', 'Ab12Cd34', now() + interval '90 days', 'u1', 'u1');
INSERT INTO ph15_portal.try_run (id, tenant_id, app_id, account_id, api_id, version_no, method, path_template, environment, sandbox_mode, result, http_status, latency_ms, trace_id)
VALUES (pg_temp.u(40), 'T68', pg_temp.u(30), pg_temp.u(11), pg_temp.u(1), '1.0.0', 'GET', '/ho-tich/{id}', 'SANDBOX', 'MOCK', 'OK', 200, 12, repeat('a', 32));
INSERT INTO ph15_portal.support_ticket (id, tenant_id, ticket_code, kind, requester_id, subject, body, created_by, updated_by)
VALUES (pg_temp.u(50), 'T68', ph15_portal.next_ticket_code(), 'QUESTION', pg_temp.u(11), 'Hỏi về phiên bản', 'API này có bản 2.0 chưa?', 'u1', 'u1');
INSERT INTO ph15_portal.outbox_event (id, tenant_id, event_code, topic, message_key, payload) VALUES (pg_temp.u(60), 'T68', 'EVT-15-01', 't68.portal.app.created.v1', 'app-tra-cuu-ho-tich', '{"appCode":"app-tra-cuu-ho-tich"}');

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
SELECT ph15_portal.seed_tenant('T01', 'u9');
INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, created_by, updated_by)
VALUES (pg_temp.u(110), 'T01', 'kc-chi', 'TENANT_SSO', 'ACTIVE', 'le.chi@example.gov.vn', 'Lê Chi', 'u9', 'u9');

-- 1. Cô lập đọc: T01 không thấy dữ liệu của T68 ở mọi bảng chính (kể cả bảng phân vùng)
SELECT pg_temp.expect_count('1a T01 không thấy mục danh mục T68', 'SELECT count(*) FROM ph15_portal.catalog_api', 0);
SELECT pg_temp.expect_count('1b T01 không thấy ứng dụng, thông tin xác thực T68', 'SELECT (SELECT count(*) FROM ph15_portal.app) + (SELECT count(*) FROM ph15_portal.app_credential)', 0);
SELECT pg_temp.expect_count('1c T01 không thấy lượt thử (phân vùng) và phiếu T68', 'SELECT (SELECT count(*) FROM ph15_portal.try_run) + (SELECT count(*) FROM ph15_portal.support_ticket) + (SELECT count(*) FROM ph15_portal.outbox_event)', 0);
SELECT pg_temp.expect_count('1d T01 chỉ thấy tài khoản của mình', 'SELECT count(*) FROM ph15_portal.dev_account', 1);
-- 2. WITH CHECK: không ghi được dòng mang tenant khác
SELECT pg_temp.expect('2 chặn ghi chéo tenant', $q$INSERT INTO ph15_portal.dev_team (id, tenant_id, team_code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'nhom-x', 'x', 'u9', 'u9')$q$, '42501');
-- 3. Sửa, xóa chéo tenant: 0 dòng bị ảnh hưởng
DO $$ DECLARE n int; BEGIN
  UPDATE ph15_portal.app SET name = 'bị sửa' WHERE id = pg_temp.u(30);
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 3: sửa chéo tenant được % dòng', n; END IF;
  UPDATE ph15_portal.catalog_api SET removed_at = now();
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 3: sửa mục danh mục chéo tenant'; END IF;
  RAISE NOTICE 'PASS 3 sửa chéo tenant: 0 dòng';
END $$;
-- 4. Khóa ngoại kép: ứng dụng T01 không trỏ được tài khoản T68
SELECT pg_temp.expect('4 khóa ngoại kép chặn trỏ sang tài khoản tenant khác', $q$INSERT INTO ph15_portal.app (id, tenant_id, app_code, name, owner_type, owner_account_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T01', 'app-cheo', 'x', 'USER', pg_temp.u(11), 'u9', 'u9')$q$, '23503');
-- 5. Không đặt tenant (hoặc rỗng): không thấy dòng nào
SET app.tenant_id = '';
SELECT pg_temp.expect_count('5 tenant rỗng: 0 dòng', 'SELECT (SELECT count(*) FROM ph15_portal.catalog_api) + (SELECT count(*) FROM ph15_portal.dev_account) + (SELECT count(*) FROM ph15_portal.portal_setting)', 0);
SELECT pg_temp.expect('5b tenant rỗng: không ghi được', $q$INSERT INTO ph15_portal.dev_team (id, tenant_id, team_code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T01', 'nhom-y', 'y', 'u9', 'u9')$q$, '42501');

SET app.tenant_id = 'T68';
-- 6. Mã định danh bất biến, không xóa vật lý
SELECT pg_temp.expect('6a appCode bất biến', $q$UPDATE ph15_portal.app SET app_code = 'app-doi' WHERE id = pg_temp.u(30)$q$, 'P1501');
SELECT pg_temp.expect('6b apiCode bất biến', $q$UPDATE ph15_portal.catalog_api SET api_code = 'doi-ma' WHERE id = pg_temp.u(1)$q$, 'P1501');
SELECT pg_temp.expect('6c ticketCode bất biến', $q$UPDATE ph15_portal.support_ticket SET ticket_code = 'HT-2026-9999' WHERE id = pg_temp.u(50)$q$, 'P1501');
SELECT pg_temp.expect('6d ứng dụng không xóa vật lý', $q$DELETE FROM ph15_portal.app WHERE id = pg_temp.u(30)$q$, '42501');
SELECT pg_temp.expect('6e mã ứng dụng sai mẫu', $q$INSERT INTO ph15_portal.app (id, tenant_id, app_code, name, owner_type, owner_account_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'App_Sai', 'x', 'USER', pg_temp.u(11), 'u1', 'u1')$q$, '23514');
-- 7. Chủ ứng dụng đúng một trong hai
SELECT pg_temp.expect('7 ứng dụng vừa của người vừa của nhóm', $q$INSERT INTO ph15_portal.app (id, tenant_id, app_code, name, owner_type, owner_account_id, owner_team_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'app-hai-chu', 'x', 'USER', pg_temp.u(11), pg_temp.u(20), 'u1', 'u1')$q$, '23514');
-- 8. Thông tin xác thực: hạn ≤ 180 ngày, khóa API cần băm, client_id đúng mẫu, không trùng
SELECT pg_temp.expect('8a hạn quá 180 ngày', $q$INSERT INTO ph15_portal.app_credential (id, tenant_id, app_id, kind, client_id, key_prefix, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), 'CLIENT_CREDENTIALS', 'sbx-t68-app-tra-cuu-ho-tich-2', 'Zz12Yy34', now() + interval '200 days', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('8b khóa API thiếu băm', $q$INSERT INTO ph15_portal.app_credential (id, tenant_id, app_id, kind, key_prefix, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), 'API_KEY', 'dhsk_t68', now() + interval '30 days', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('8c client_id sai mẫu', $q$INSERT INTO ph15_portal.app_credential (id, tenant_id, app_id, kind, client_id, key_prefix, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), 'CLIENT_CREDENTIALS', 'client-bat-ky', 'Zz12Yy34', now() + interval '30 days', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('8d client_id trùng', $q$INSERT INTO ph15_portal.app_credential (id, tenant_id, app_id, kind, client_id, key_prefix, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), 'CLIENT_CREDENTIALS', 'sbx-t68-app-tra-cuu-ho-tich-1', 'Zz12Yy34', now() + interval '30 days', 'u1', 'u1')$q$, '23505');
SELECT pg_temp.expect('8e thu hồi phải có thời điểm', $q$UPDATE ph15_portal.app_credential SET status = 'REVOKED' WHERE id = pg_temp.u(31)$q$, '23514');
-- 9. Tài khoản dh-dev: phải có xác minh thư, duyệt, tổ chức; SSO không có trạng thái chờ; ẩn danh xóa dữ liệu
SELECT pg_temp.expect('9a dh-dev ACTIVE thiếu duyệt', $q$INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'kc-x', 'DH_DEV', 'ACTIVE', 'x@thau.vn', 'X', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('9b SSO ở trạng thái chờ duyệt', $q$INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'kc-y', 'TENANT_SSO', 'PENDING_APPROVAL', 'y@x.vn', 'Y', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('9c thư viết hoa', $q$INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'kc-z', 'TENANT_SSO', 'ACTIVE', 'Z@X.VN', 'Z', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('9d ERASED còn dữ liệu nhận diện', $q$UPDATE ph15_portal.dev_account SET status = 'ERASED' WHERE id = pg_temp.u(11)$q$, '23514');
SELECT pg_temp.expect('9e điện thoại mã hóa thiếu DEK', $q$UPDATE ph15_portal.dev_account SET phone_enc = '\x00'::bytea WHERE id = pg_temp.u(10)$q$, '23514');
SELECT pg_temp.expect('9f trùng thư cùng nguồn', $q$INSERT INTO ph15_portal.dev_account (id, tenant_id, user_id, source, status, email, full_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'kc-w', 'TENANT_SSO', 'ACTIVE', 'nguyen.van.an@example.gov.vn', 'W', 'u1', 'u1')$q$, '23505');
-- 10. Nội dung: bốn mắt, một bản PUBLISHED, bất biến sau đăng
INSERT INTO ph15_portal.content_page (id, tenant_id, page_code, type, audience, title, created_by, updated_by) VALUES (pg_temp.u(70), 'T68', 'bat-dau-nhanh', 'QUICKSTART', 'LOGGED_IN', 'Bắt đầu nhanh', 'u1', 'u1');
INSERT INTO ph15_portal.content_page_version (id, tenant_id, page_id, version_no, body_md, content_hash, status, last_edited_by, submitted_by, submitted_at, created_by, updated_by)
VALUES (pg_temp.u(71), 'T68', pg_temp.u(70), 1, '# Bắt đầu', repeat('1', 64), 'IN_REVIEW', 'ed1', 'ed1', now(), 'ed1', 'ed1');
SELECT pg_temp.expect('10a người duyệt trùng người gửi', $q$UPDATE ph15_portal.content_page_version SET status = 'PUBLISHED', reviewed_by = 'ed1', reviewed_at = now(), published_at = now() WHERE id = pg_temp.u(71)$q$, '23514');
SELECT pg_temp.expect('10b người duyệt trùng người sửa gần nhất', $q$UPDATE ph15_portal.content_page_version SET status = 'PUBLISHED', reviewed_by = 'rv1', reviewed_at = now(), last_edited_by = 'rv1' WHERE id = pg_temp.u(71)$q$, '23514');
SELECT pg_temp.expect('10c IN_REVIEW thiếu người gửi', $q$INSERT INTO ph15_portal.content_page_version (id, tenant_id, page_id, version_no, body_md, content_hash, status, last_edited_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(70), 2, 'x', repeat('2', 64), 'IN_REVIEW', 'ed1', 'ed1', 'ed1')$q$, '23514');
SELECT pg_temp.expect('10d trang quá 200 KB', format($q$INSERT INTO ph15_portal.content_page_version (id, tenant_id, page_id, version_no, body_md, content_hash, last_edited_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(70), 3, %L, repeat('3', 64), 'ed1', 'ed1', 'ed1')$q$, repeat('a', 204801)), '23514');
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
UPDATE ph15_portal.content_page_version SET status = 'PUBLISHED', reviewed_by = 'rv1', reviewed_at = now(), published_at = now() WHERE id = pg_temp.u(71);
UPDATE ph15_portal.content_page SET status = 'PUBLISHED', published_version_id = pg_temp.u(71) WHERE id = pg_temp.u(70);
COMMIT;
SELECT pg_temp.expect('10e nội dung đã đăng không sửa được', $q$UPDATE ph15_portal.content_page_version SET body_md = 'đã sửa' WHERE id = pg_temp.u(71)$q$, 'P1502');
SELECT pg_temp.expect('10f hai bản PUBLISHED cùng trang', $q$INSERT INTO ph15_portal.content_page_version (id, tenant_id, page_id, version_no, body_md, content_hash, status, last_edited_by, submitted_by, submitted_at, reviewed_by, reviewed_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(70), 4, 'y', repeat('4', 64), 'PUBLISHED', 'ed2', 'ed2', now(), 'rv2', now(), 'ed2', 'ed2')$q$, '23505');
SELECT pg_temp.expect('10g trang PUBLISHED thiếu phiên bản đang đăng', $q$INSERT INTO ph15_portal.content_page (id, tenant_id, page_code, type, title, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'trang-loi', 'GUIDE', 't', 'PUBLISHED', 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('10h không xóa vật lý phiên bản trang', $q$DELETE FROM ph15_portal.content_page_version WHERE id = pg_temp.u(71)$q$, '42501');
-- 11. Thử production: bốn mắt, tối đa 90 ngày; lượt thử production không lưu thân, chỉ GET/HEAD
SELECT pg_temp.expect('11a bật thử production do chính người đề xuất duyệt', $q$INSERT INTO ph15_portal.try_prod_grant (id, tenant_id, api_id, status, proposed_by, approved_by, approved_at, valid_until, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(1), 'ENABLED', 'ta1', 'ta1', now(), now() + interval '30 days', 'ta1', 'ta1')$q$, '23514');
SELECT pg_temp.expect('11b thời hạn quá 90 ngày', $q$INSERT INTO ph15_portal.try_prod_grant (id, tenant_id, api_id, status, proposed_by, approved_by, approved_at, valid_until, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(1), 'ENABLED', 'ta1', 'ta2', now(), now() + interval '120 days', 'ta1', 'ta1')$q$, '23514');
INSERT INTO ph15_portal.try_prod_grant (id, tenant_id, api_id, status, proposed_by, approved_by, approved_at, valid_until, created_by, updated_by) VALUES (pg_temp.u(80), 'T68', pg_temp.u(1), 'ENABLED', 'ta1', 'ta2', now(), now() + interval '30 days', 'ta1', 'ta1');
SELECT pg_temp.expect('11c mỗi API một bản ghi cho phép thử', $q$INSERT INTO ph15_portal.try_prod_grant (id, tenant_id, api_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(1), 'ta1', 'ta1')$q$, '23505');
SELECT pg_temp.expect('11d thử production bằng POST', $q$INSERT INTO ph15_portal.try_run (id, tenant_id, app_id, account_id, api_id, version_no, method, path_template, environment, result, trace_id) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), pg_temp.u(11), pg_temp.u(1), '1.0.0', 'POST', '/x', 'PRODUCTION', 'OK', repeat('b', 32))$q$, '23514');
SELECT pg_temp.expect('11e thử production có lưu thân yêu cầu', $q$INSERT INTO ph15_portal.try_run (id, tenant_id, app_id, account_id, api_id, version_no, method, path_template, environment, result, trace_id, request_snapshot) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), pg_temp.u(11), pg_temp.u(1), '1.0.0', 'GET', '/x', 'PRODUCTION', 'OK', repeat('b', 32), '{"a":1}')$q$, '23514');
SELECT pg_temp.expect('11f lượt thử ngoài phân vùng', $q$INSERT INTO ph15_portal.try_run (id, tenant_id, app_id, account_id, api_id, version_no, method, path_template, environment, sandbox_mode, result, trace_id, executed_at) VALUES (gen_random_uuid(), 'T68', pg_temp.u(30), pg_temp.u(11), pg_temp.u(1), '1.0.0', 'GET', '/x', 'SANDBOX', 'MOCK', 'OK', repeat('b', 32), '2020-01-01')$q$, '23514');
-- 12. Bộ sưu tập: giới hạn 50 bộ và 100 yêu cầu
DO $$ BEGIN
  FOR i IN 1..50 LOOP
    INSERT INTO ph15_portal.try_collection (id, tenant_id, account_id, name, created_by, updated_by) VALUES (pg_temp.u(200 + i), 'T68', pg_temp.u(11), 'bộ ' || i, 'u1', 'u1');
  END LOOP;
  FOR i IN 1..100 LOOP
    INSERT INTO ph15_portal.try_collection_item (id, tenant_id, collection_id, position, name, request_spec, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(201), i, 'y' || i, '{"method":"GET","path":"/ho-tich"}', 'u1', 'u1');
  END LOOP;
END $$;
SELECT pg_temp.expect('12a bộ sưu tập thứ 51', $q$INSERT INTO ph15_portal.try_collection (id, tenant_id, account_id, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(11), 'bộ 51', 'u1', 'u1')$q$, 'P1503');
SELECT pg_temp.expect('12b yêu cầu thứ 101', $q$INSERT INTO ph15_portal.try_collection_item (id, tenant_id, collection_id, position, name, request_spec, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(201), 101, 'y101', '{"method":"GET"}', 'u1', 'u1')$q$, 'P1503');
SELECT pg_temp.expect('12c yêu cầu mẫu quá 16 KB', format($q$INSERT INTO ph15_portal.try_collection_item (id, tenant_id, collection_id, position, name, request_spec, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(202), 1, 'lon', %L::jsonb, 'u1', 'u1')$q$, '{"body":"' || repeat('a', 17000) || '"}'), '23514');
-- 13. Theo dõi thay đổi: loại bắt buộc không xóa được
INSERT INTO ph15_portal.notification_subscription (id, tenant_id, account_id, api_id, channel, kind, created_by, updated_by) VALUES (pg_temp.u(90), 'T68', pg_temp.u(11), pg_temp.u(1), 'IN_APP', 'MANDATORY', 'sys', 'sys');
INSERT INTO ph15_portal.notification_subscription (id, tenant_id, account_id, api_id, channel, kind, created_by, updated_by) VALUES (pg_temp.u(91), 'T68', pg_temp.u(11), pg_temp.u(1), 'EMAIL', 'INFO', 'u1', 'u1');
SELECT pg_temp.expect('13a xóa đăng ký bắt buộc', $q$DELETE FROM ph15_portal.notification_subscription WHERE id = pg_temp.u(90)$q$, 'P1504');
DELETE FROM ph15_portal.notification_subscription WHERE id = pg_temp.u(91);
-- 14. Chỉ-ghi-thêm: bằng chứng chấp nhận điều khoản, tin nhắn hỗ trợ
INSERT INTO ph15_portal.support_message (id, tenant_id, ticket_id, author_id, author_side, body, created_by) VALUES (pg_temp.u(95), 'T68', pg_temp.u(50), 'kc-binh', 'REQUESTER', 'Cảm ơn', 'kc-binh');
SELECT pg_temp.expect('14a sửa tin nhắn hỗ trợ', $q$UPDATE ph15_portal.support_message SET body = 'sửa' WHERE id = pg_temp.u(95)$q$, '42501');
-- 15. Phiếu hỗ trợ: mã theo tenant và năm, đánh giá chỉ cho FEEDBACK
SELECT pg_temp.expect_count('15a mã phiếu đầu tiên T68 là HT-năm-0001', $q$SELECT count(*) FROM ph15_portal.support_ticket WHERE ticket_code = 'HT-' || extract(year FROM now())::int || '-0001'$q$, 1);
SELECT pg_temp.expect('15b đánh giá trên phiếu không phải FEEDBACK', $q$UPDATE ph15_portal.support_ticket SET rating = 5 WHERE id = pg_temp.u(50)$q$, '23514');
SELECT pg_temp.expect('15c phiếu RESOLVED thiếu resolved_at', $q$UPDATE ph15_portal.support_ticket SET status = 'RESOLVED' WHERE id = pg_temp.u(50)$q$, '23514');
-- 16. Tệp: giới hạn loại và kích thước (Phụ lục A.6)
SELECT pg_temp.expect('16a ảnh trang là SVG', $q$INSERT INTO ph15_portal.content_attachment (id, tenant_id, purpose, bucket, object_key, file_name, mime_type, size_bytes, sha256, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'PAGE_IMAGE', 'dh-t68-portal', 'img/a.svg', 'a.svg', 'image/svg+xml', 1000, repeat('a', 64), 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('16b logo quá 512 KB', $q$INSERT INTO ph15_portal.content_attachment (id, tenant_id, purpose, bucket, object_key, file_name, mime_type, size_bytes, sha256, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'LOGO', 'dh-t68-portal', 'logo/a.png', 'a.png', 'image/png', 600000, repeat('a', 64), 'u1', 'u1')$q$, '23514');
SELECT pg_temp.expect('16c bucket của tenant khác', $q$INSERT INTO ph15_portal.content_attachment (id, tenant_id, purpose, bucket, object_key, file_name, mime_type, size_bytes, sha256, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'LOGO', 'bucket-la', 'logo/b.png', 'b.png', 'image/png', 1000, repeat('a', 64), 'u1', 'u1')$q$, '23514');
INSERT INTO ph15_portal.content_attachment (id, tenant_id, purpose, bucket, object_key, file_name, mime_type, size_bytes, sha256, scan_status, created_by, updated_by) VALUES (pg_temp.u(100), 'T68', 'MIGRATION_PACKAGE', 'dh-t68-portal', 'migration/gravitee.zip', 'gravitee.zip', 'application/zip', 1048576, repeat('c', 64), 'CLEAN', 'u1', 'u1');
-- 17. Di trú: một lô RUNNING mỗi tenant; ánh xạ lũy đẳng và target_id bất biến
INSERT INTO ph15_portal.content_migration (id, tenant_id, package_file_id, created_by, updated_by) VALUES (pg_temp.u(101), 'T68', pg_temp.u(100), 'ta1', 'ta1');
SELECT pg_temp.expect('17a hai lô di trú cùng chạy', $q$INSERT INTO ph15_portal.content_migration (id, tenant_id, package_file_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', pg_temp.u(100), 'ta1', 'ta1')$q$, '23505');
INSERT INTO ph15_portal.legacy_mapping (tenant_id, legacy_key, target_type, target_id, source_hash, migration_id) VALUES ('T68', 'pages/gioi-thieu', 'PAGE', pg_temp.u(70), repeat('d', 64), pg_temp.u(101));
SELECT pg_temp.expect('17b ánh xạ trùng khóa cũ', $q$INSERT INTO ph15_portal.legacy_mapping (tenant_id, legacy_key, target_type, target_id, source_hash, migration_id) VALUES ('T68', 'pages/gioi-thieu', 'PAGE', pg_temp.u(70), repeat('d', 64), pg_temp.u(101))$q$, '23505');
SELECT pg_temp.expect('17c đổi target_id', $q$UPDATE ph15_portal.legacy_mapping SET target_id = gen_random_uuid() WHERE legacy_key = 'pages/gioi-thieu'$q$, 'P1505');
-- 18. Đồng bộ: một lần RUNNING mỗi loại; hoàn tất phải có thời điểm kết thúc
INSERT INTO ph15_portal.sync_run (id, tenant_id, kind, created_by, updated_by) VALUES (pg_temp.u(120), 'T68', 'INCREMENTAL', 'system:sync', 'system:sync');
SELECT pg_temp.expect('18a hai lần kéo bù cùng chạy', $q$INSERT INTO ph15_portal.sync_run (id, tenant_id, kind, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'INCREMENTAL', 'system:sync', 'system:sync')$q$, '23505');
SELECT pg_temp.expect('18b hoàn tất thiếu finished_at', $q$UPDATE ph15_portal.sync_run SET status = 'SUCCEEDED' WHERE id = pg_temp.u(120)$q$, '23514');
-- 19. Mục danh mục: removed[] không còn hiển thị; tìm không dấu; hộp thư đi đúng mẫu chủ đề
SELECT pg_temp.expect('19a mục bị gỡ nhưng còn portalPublished', $q$UPDATE ph15_portal.catalog_api SET removed_at = now() WHERE id = pg_temp.u(1)$q$, '23514');
SELECT pg_temp.expect_count('19b tìm "tra cuu ho tich" không dấu', $q$SELECT count(*) FROM ph15_portal.catalog_api WHERE search_tsv @@ plainto_tsquery('simple', ph15_portal.f_unaccent('tra cuu ho tich'))$q$, 1);
SELECT pg_temp.expect_count('19c tìm có dấu cũng khớp', $q$SELECT count(*) FROM ph15_portal.catalog_api WHERE search_tsv @@ plainto_tsquery('simple', ph15_portal.f_unaccent('Tra cứu hộ tịch'))$q$, 1);
SELECT pg_temp.expect('19d chủ đề Kafka sai mẫu', $q$INSERT INTO ph15_portal.outbox_event (id, tenant_id, event_code, topic, message_key, payload) VALUES (gen_random_uuid(), 'T68', 'EVT-15-02', 'portal.app.state', 'k', '{}')$q$, '23514');
SELECT pg_temp.expect('19e mã sự kiện ngoài EVT-15-01…14', $q$INSERT INTO ph15_portal.outbox_event (id, tenant_id, event_code, topic, message_key, payload) VALUES (gen_random_uuid(), 'T68', 'EVT-15-15', 't68.portal.app.created.v1', 'k', '{}')$q$, '23514');
-- 20. Seed lũy đẳng
SELECT ph15_portal.seed_tenant('T68', 'u1');
SELECT pg_temp.expect_count('20 seed lặp không nhân bản', 'SELECT count(*) FROM ph15_portal.portal_setting', 1);

-- 21. Mọi bảng có tenant_id đều ENABLE + FORCE RLS và có chính sách
RESET ROLE;
DO $$ DECLARE bad text; BEGIN
  SELECT string_agg(c.relname, ', ') INTO bad
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'ph15_portal' AND c.relkind IN ('r', 'p') AND NOT c.relispartition
    AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)
    AND NOT (c.relrowsecurity AND c.relforcerowsecurity AND EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid));
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'FAIL 21: bảng thiếu FORCE RLS: %', bad; END IF;
  RAISE NOTICE 'PASS 21 mọi bảng có tenant_id đều FORCE RLS';
END $$;

-- 22. Vai trò chỉ đọc: không thấy bí mật, bản mã, bảng kỹ thuật
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_portal_ro') THEN
    CREATE ROLE dh_portal_ro LOGIN NOBYPASSRLS IN ROLE ph15_readonly;
  END IF;
END $$;
SET ROLE dh_portal_ro;
SET app.tenant_id = 'T68';
SELECT pg_temp.expect('22a đọc key_hash', 'SELECT key_hash FROM ph15_portal.app_credential', '42501');
SELECT pg_temp.expect('22b đọc phone_enc', 'SELECT phone_enc FROM ph15_portal.dev_account', '42501');
SELECT pg_temp.expect('22c đọc idempotency_record', 'SELECT * FROM ph15_portal.idempotency_record', '42501');
SELECT pg_temp.expect_count('22d đọc được cột không nhạy cảm của thông tin xác thực', 'SELECT count(client_id) FROM ph15_portal.app_credential', 1);
SELECT pg_temp.expect('22e chỉ đọc không ghi được', $q$UPDATE ph15_portal.catalog_api SET name = 'x'$q$, '42501');
RESET ROLE;
