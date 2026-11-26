-- =============================================================================
-- D03-03-PH01 · Kiểm thử DDL ph01_onboarding: cô lập tenant, bốn mắt, máy trạng thái, không lưu bí mật,
-- bàn giao một lần, saga và cắt quyền, rà soát quyền, quyền cột của vai trò chỉ đọc.
-- Chạy sau ph01_00 … ph01_90 trên CSDL rỗng (xem chay_tat_ca.sh):
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph01_isolation_test.sql
-- Mỗi kiểm tra gọi pg_temp.expect (phải lỗi đúng SQLSTATE), pg_temp.ok (phải thành công) hoặc
-- pg_temp.assert; sai thì RAISE dừng tệp. Tương ứng nhóm ca cô lập, tách nhiệm, chống lộ bí mật của D05-02-PH01.
-- =============================================================================
\set ON_ERROR_STOP on
\set QUIET on
\t on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_connect_app') THEN
    CREATE ROLE dh_connect_app LOGIN NOBYPASSRLS IN ROLE ph01_app;
  ELSE
    GRANT ph01_app TO dh_connect_app;
  END IF;
END $$;
SET ROLE dh_connect_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY[
  's68','tp68','ct68','ct68b','at68','at68b','dm68','dm68p','r1','r2','r3','ce68','cr68','cr68p','ho68','ho68b','sg68','sg68b','st1','em68','ch68','ch68b','cy68','it68','cf68',
  's01','ct01','dr1','dr2','tm01','hs68','lj68']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

CREATE FUNCTION pg_temp.expect(label text, stmt text, state text) RETURNS void LANGUAGE plpgsql AS $f$
BEGIN
  BEGIN
    EXECUTE stmt;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = state THEN RAISE NOTICE 'PASS %', label; RETURN; END IF;
    RAISE EXCEPTION 'FAIL %: mong SQLSTATE %, nhận % (%)', label, state, SQLSTATE, SQLERRM;
  END;
  RAISE EXCEPTION 'FAIL %: câu lệnh lẽ ra phải lỗi %', label, state;
END $f$;
CREATE FUNCTION pg_temp.ok(label text, stmt text) RETURNS void LANGUAGE plpgsql AS $f$
BEGIN
  EXECUTE stmt;
  RAISE NOTICE 'PASS %', label;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'FAIL %: lẽ ra thành công, nhận % (%)', label, SQLSTATE, SQLERRM;
END $f$;
CREATE FUNCTION pg_temp.assert(label text, cond boolean) RETURNS void LANGUAGE plpgsql AS $f$
BEGIN
  IF cond IS NOT TRUE THEN RAISE EXCEPTION 'FAIL %', label; END IF;
  RAISE NOTICE 'PASS %', label;
END $f$;

-- ===================== Dữ liệu T68 =====================
SET app.tenant_id = 'T68';
INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, description, owner_org_id, security_level, system_type, roles, base_urls, ip_allowlist, created_by, updated_by)
VALUES (pg_temp.id('s68'), 'T68', 'HT-TUPHAP', 'Hệ thống quản lý hộ tịch', 'Cấp, quản lý giấy khai sinh', 'SO-TUPHAP', 'L3', 'PROVINCIAL',
        ARRAY['CONSUMER', 'PROVIDER'], '["https://hotich.tinh.gov.vn/api"]', '["10.20.0.0/24"]', 'lan', 'lan');
INSERT INTO ph01_onboarding.technical_profile (id, tenant_id, member_system_id, system_kind, technology, has_api, api_spec_kind, protocols, under_maintenance, replacement_planned, proposed_group, created_by, updated_by)
VALUES (pg_temp.id('tp68'), 'T68', pg_temp.id('s68'), 'WEB', 'Java 8, Spring 4', true, 'OPENAPI', ARRAY['REST'], false, false, 1, 'lan', 'lan');

-- ===================== Dữ liệu T01 =====================
SET app.tenant_id = 'T01';
INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, created_by, updated_by)
VALUES (pg_temp.id('s01'), 'T01', 'HT-TUPHAP', 'Hệ thống hộ tịch T01', 'SO-TUPHAP', 'L2', 'PROVINCIAL', ARRAY['CONSUMER'], 'lan', 'lan');
INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, created_by, updated_by)
VALUES (pg_temp.id('ct01'), 'T01', pg_temp.id('s01'), 'TECHNICAL', 'Lê Văn Cường', 'Chuyên viên', 'cuong@t01.gov.vn', 'lan', 'lan');
INSERT INTO ph01_onboarding.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
VALUES (gen_random_uuid(), 'T01', 'vn.datahub.connect.system.state-changed.v1', 't01.connect.system.state-changed.v1', 'MemberSystem', 'HT-TUPHAP', '{"to":"DRAFT"}', repeat('0', 32));

-- ===================== 1. Cô lập tenant =====================
SELECT pg_temp.assert('1 T01 chỉ thấy HTTT của mình', (SELECT count(*) FROM ph01_onboarding.member_system) = 1);
SELECT pg_temp.assert('1b T01 không thấy hồ sơ kỹ thuật của T68', (SELECT count(*) FROM ph01_onboarding.technical_profile) = 0);
SELECT pg_temp.assert('1c T01 chỉ thấy outbox của mình', (SELECT count(*) FROM ph01_onboarding.outbox) = 1);
SELECT pg_temp.expect('2 T01 không chèn được dòng T68', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'GIA-MAO', 'giả mạo', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], 'lan', 'lan')$q$, '42501');
SELECT pg_temp.expect('2b T01 không chèn đầu mối vào HTTT của T68', format($q$INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', %L, 'TECHNICAL', 'x', 'x', 'x@y.vn', 'lan', 'lan')$q$, pg_temp.id('s68')), '23503');
SELECT pg_temp.ok('3 T01 sửa dòng T68 không ảnh hưởng dòng nào', $q$DO $b$ DECLARE n int; BEGIN
  UPDATE ph01_onboarding.member_system SET name = 'bị sửa' WHERE code = 'HT-TUPHAP' AND tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'sửa được dòng tenant khác'; END IF; END $b$$q$);
SELECT pg_temp.ok('3b T01 xóa dòng T68 không ảnh hưởng dòng nào', $q$DO $b$ DECLARE n int; BEGIN
  DELETE FROM ph01_onboarding.technical_profile WHERE tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'xóa được dòng tenant khác'; END IF; END $b$$q$);
SELECT pg_temp.ok('4 biến phiên rỗng thì không thấy dòng nào', $q$DO $b$ DECLARE n int; BEGIN
  PERFORM set_config('app.tenant_id', '', true);
  SELECT count(*) INTO n FROM ph01_onboarding.member_system; IF n <> 0 THEN RAISE 'thấy dòng khi phiên rỗng'; END IF; END $b$$q$);
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.assert('4b phiên PLATFORM không đọc dữ liệu của tenant', (SELECT count(*) FROM ph01_onboarding.member_system) = 0);
SELECT pg_temp.expect('4c phiên PLATFORM không ghi bảng riêng tenant', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'HT-COMMON', 'x', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], 'x', 'x')$q$, '42501');
SET app.tenant_id = 'T68';
SELECT pg_temp.assert('5 cùng mã HTTT dùng được ở hai tenant (duy nhất theo tenant, T01 đã có HT-TUPHAP)', (SELECT count(*) FROM ph01_onboarding.member_system WHERE code = 'HT-TUPHAP') = 1);
SELECT pg_temp.expect('5b trùng mã HTTT trong cùng tenant', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'HT-TUPHAP', 'trùng', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], 'x', 'x')$q$, '23505');
SELECT pg_temp.expect('5c mã HTTT sai mẫu', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ht-thuong', 'x', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], 'x', 'x')$q$, '23514');
SELECT pg_temp.expect('5d địa chỉ backend phải là https', format($q$UPDATE ph01_onboarding.member_system SET base_urls = '["http://hotich.gov.vn"]' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('5e danh sách IP phải là CIDR hợp lệ', format($q$UPDATE ph01_onboarding.member_system SET ip_allowlist = '["10.20.0.1/24"]' WHERE id = %L$q$, pg_temp.id('s68')), '23514');

-- ===================== 2. Điều kiện nộp hồ sơ (BR-01-001, BR-01-013) =====================
SELECT pg_temp.expect('6 không nộp được khi thiếu đầu mối kỹ thuật', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUBMITTED', review_stage = 'WAITING_ASSIGN', revision_no = 1,
  submitted_by = 'mai', submitted_at = now(), security_approval_ref = 'QĐ 1234/QĐ-UBND' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, phone, user_account_id, created_by, updated_by)
VALUES (pg_temp.id('ct68'), 'T68', pg_temp.id('s68'), 'TECHNICAL', 'Nguyễn Văn An', 'Chuyên viên CNTT', 'an.nv@tuphap.tinh.gov.vn', '+84912345678', 'u-an', 'lan', 'lan');
INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, created_by, updated_by)
VALUES (pg_temp.id('ct68b'), 'T68', pg_temp.id('s68'), 'TECHNICAL', 'Trần Thị Bình', 'Chuyên viên', 'binh.tt@tuphap.tinh.gov.vn', 'lan', 'lan');
INSERT INTO ph01_onboarding.attachment (id, tenant_id, member_system_id, kind, file_name, content_type, size_bytes, object_key, sha256, scan_status, scanned_at, uploaded_by, created_by, updated_by)
VALUES (pg_temp.id('at68'), 'T68', pg_temp.id('s68'), 'LEGAL_BASIS', 'luat-91.pdf', 'application/pdf', 120000, 'HT-TUPHAP/at68', repeat('a', 64), 'CLEAN', now(), 'lan', 'lan', 'lan');
INSERT INTO ph01_onboarding.data_demand (id, tenant_id, member_system_id, direction, data_type, scope_requested, classification, purpose, legal_doc_no, legal_issued_on, legal_issuer, created_by, updated_by)
VALUES (pg_temp.id('dm68'), 'T68', pg_temp.id('s68'), 'CONSUME', 'THONG_TIN_CONG_DAN', 'Tra cứu phục vụ giải quyết TTHC', 'RESTRICTED', 'Xác minh nhân thân', 'Luật 91/2025/QH15', '2025-06-26', 'Quốc hội', 'lan', 'lan');
SELECT pg_temp.expect('7 không nộp được khi căn cứ pháp lý thiếu tệp (BR-01-001)', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUBMITTED', review_stage = 'WAITING_ASSIGN', revision_no = 1,
  submitted_by = 'mai', submitted_at = now(), security_approval_ref = 'QĐ 1234/QĐ-UBND' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
UPDATE ph01_onboarding.data_demand SET legal_attachment_id = pg_temp.id('at68') WHERE id = pg_temp.id('dm68');
SELECT pg_temp.expect('7b nộp phải tăng revision_no thêm 1', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUBMITTED', review_stage = 'WAITING_ASSIGN', revision_no = 0,
  submitted_by = 'mai', submitted_at = now(), security_approval_ref = 'QĐ 1234/QĐ-UBND' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('7c cấp độ L3 phải có số quyết định phê duyệt khi nộp', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUBMITTED', review_stage = 'WAITING_ASSIGN', revision_no = 1,
  submitted_by = 'mai', submitted_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('7d giai đoạn thẩm định chỉ có khi SUBMITTED', format($q$UPDATE ph01_onboarding.member_system SET review_stage = 'IN_REVIEW' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('8 nộp hồ sơ đủ điều kiện', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUBMITTED', review_stage = 'WAITING_ASSIGN', revision_no = 1,
  submitted_by = 'mai', submitted_at = now(), security_approval_ref = 'QĐ 1234/QĐ-UBND ngày 12/03/2026', updated_by = 'mai' WHERE id = %L$q$, pg_temp.id('s68')));
SELECT pg_temp.expect('8b chuyển trạng thái không hợp lệ SUBMITTED → ACTIVE', format($q$UPDATE ph01_onboarding.member_system SET status = 'ACTIVE', review_stage = NULL WHERE id = %L$q$, pg_temp.id('s68')), '55000');
SELECT pg_temp.expect('8c mã HTTT bất biến', format($q$UPDATE ph01_onboarding.member_system SET code = 'HT-DOIMA' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('8d không xóa hồ sơ đã nộp (BR-01-011)', format($q$DELETE FROM ph01_onboarding.member_system WHERE id = %L$q$, pg_temp.id('s68')), '55000');
SELECT pg_temp.expect('8e không xóa đầu mối của hồ sơ đã nộp', format($q$DELETE FROM ph01_onboarding.contact WHERE id = %L$q$, pg_temp.id('ct68b')), '55000');
SELECT pg_temp.expect('8f không xóa nhu cầu khai thác của hồ sơ đã nộp', format($q$DELETE FROM ph01_onboarding.data_demand WHERE id = %L$q$, pg_temp.id('dm68')), '55000');
SELECT pg_temp.expect('8g không xóa tài liệu của hồ sơ đã nộp', format($q$DELETE FROM ph01_onboarding.attachment WHERE id = %L$q$, pg_temp.id('at68')), '55000');

-- ===================== 3. Thẩm định, bốn mắt (BR-01-017) =====================
SELECT pg_temp.expect('9 người lập không được phân công thẩm định', format($q$INSERT INTO ph01_onboarding.review_step (id, tenant_id, member_system_id, revision_no, step_type, assignee_id, assigned_by, assigned_at, due_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 1, 'LEGAL', 'lan', 'tung', now(), now() + interval '2 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('9b người nộp không được phân công thẩm định', format($q$INSERT INTO ph01_onboarding.review_step (id, tenant_id, member_system_id, revision_no, step_type, assignee_id, assigned_by, assigned_at, due_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 1, 'LEGAL', 'mai', 'tung', now(), now() + interval '2 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');
INSERT INTO ph01_onboarding.review_step (id, tenant_id, member_system_id, revision_no, step_type, assignee_id, assigned_by, assigned_at, due_at, created_by, updated_by)
SELECT pg_temp.id(x.k), 'T68', pg_temp.id('s68'), 1, x.t, x.a, 'tung', now(), now() + interval '2 days', 'tung', 'tung'
FROM (VALUES ('r1', 'TECHNICAL', 'binh'), ('r2', 'LEGAL', 'cuong'), ('r3', 'SECURITY', 'dung')) AS x(k, t, a);
SELECT pg_temp.expect('9c mỗi vòng nộp một bước mỗi loại', format($q$INSERT INTO ph01_onboarding.review_step (id, tenant_id, member_system_id, revision_no, step_type, due_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 1, 'LEGAL', now() + interval '2 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23505');
SELECT pg_temp.expect('10 người kết luận phải là người được phân công', format($q$UPDATE ph01_onboarding.review_step SET status = 'DONE', result = 'PASS', finished_at = now(), finished_by = 'cuong' WHERE id = %L$q$, pg_temp.id('r1')), '23514');
SELECT pg_temp.expect('10b kết luận FAIL phải có ý kiến', format($q$UPDATE ph01_onboarding.review_step SET status = 'DONE', result = 'FAIL', finished_at = now(), finished_by = 'binh' WHERE id = %L$q$, pg_temp.id('r1')), '23514');
SELECT pg_temp.ok('10c thẩm định kỹ thuật xong', format($q$UPDATE ph01_onboarding.review_step SET status = 'DONE', result = 'PASS', opinion = 'Đạt', finished_at = now(), finished_by = 'binh' WHERE id = %L$q$, pg_temp.id('r1')));
SELECT pg_temp.expect('10d kết luận một lần, bước đã xong bất biến', format($q$UPDATE ph01_onboarding.review_step SET opinion = 'Sửa lại' WHERE id = %L$q$, pg_temp.id('r1')), '55000');
SELECT pg_temp.ok('10e thẩm định pháp lý xong', format($q$UPDATE ph01_onboarding.review_step SET status = 'DONE', result = 'PASS', opinion = 'Đạt', finished_at = now(), finished_by = 'cuong' WHERE id = %L$q$, pg_temp.id('r2')));
SELECT pg_temp.expect('11 không duyệt khi mới đủ hai bước', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'hung', approved_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('11b thẩm định ATTT xong', format($q$UPDATE ph01_onboarding.review_step SET status = 'DONE', result = 'PASS', opinion = 'Đạt', finished_at = now(), finished_by = 'dung' WHERE id = %L$q$, pg_temp.id('r3')));
SELECT pg_temp.expect('11c không duyệt khi còn mục nhu cầu chưa có kết luận (ERR-01-018)', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'hung', approved_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('11d kết luận chấp thuận phải có phạm vi được duyệt', format($q$UPDATE ph01_onboarding.data_demand SET verdict = 'APPROVED', reviewer_id = 'cuong', reviewed_at = now() WHERE id = %L$q$, pg_temp.id('dm68')), '23514');
SELECT pg_temp.expect('11e kết luận thu hẹp hoặc từ chối phải có ý kiến', format($q$UPDATE ph01_onboarding.data_demand SET verdict = 'REJECTED', reviewer_id = 'cuong', reviewed_at = now() WHERE id = %L$q$, pg_temp.id('dm68')), '23514');
SELECT pg_temp.ok('11f kết luận mục nhu cầu', format($q$UPDATE ph01_onboarding.data_demand SET verdict = 'NARROWED', scope_approved = 'Tra cứu TTHC, không gồm sức khỏe', opinion = 'Thu hẹp', reviewer_id = 'cuong', reviewed_at = now() WHERE id = %L$q$, pg_temp.id('dm68')));
SELECT pg_temp.expect('11g không duyệt khi nhóm HTTT chưa xác nhận (ERR-01-019)', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'hung', approved_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
UPDATE ph01_onboarding.technical_profile SET confirmed_group = 3, confirmed_by = 'binh', confirmed_at = now() WHERE id = pg_temp.id('tp68');
SELECT pg_temp.expect('12 người thẩm định không được phê duyệt cùng hồ sơ', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'binh', approved_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('12b người lập không được phê duyệt', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'lan', approved_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('12c người nộp không được phê duyệt', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'mai', approved_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('12d phê duyệt bởi người chưa tham gia', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', review_stage = NULL, provision_stage = 'PROVISIONING', approved_by = 'hung', approved_at = now(), updated_by = 'hung' WHERE id = %L$q$, pg_temp.id('s68')));

-- ===================== 4. Trần phạm vi (BR-01-003, BR-01-012) =====================
SELECT pg_temp.expect('13 trần không rộng hơn phạm vi được duyệt', format($q$INSERT INTO ph01_onboarding.scope_ceiling (id, tenant_id, member_system_id, source_demand_id, direction, data_type, scope_approved, classification, legal_doc_no, legal_issued_on, legal_issuer, created_by, updated_by)
  VALUES (%L, 'T68', %L, %L, 'CONSUME', 'THONG_TIN_CONG_DAN', 'Tra cứu phục vụ giải quyết TTHC', 'RESTRICTED', 'Luật 91/2025/QH15', '2025-06-26', 'Quốc hội', 'hung', 'hung')$q$,
  pg_temp.id('ce68'), pg_temp.id('s68'), pg_temp.id('dm68')), '23514');
SELECT pg_temp.ok('13b trần bằng đúng phạm vi đã thu hẹp', format($q$INSERT INTO ph01_onboarding.scope_ceiling (id, tenant_id, member_system_id, source_demand_id, direction, data_type, scope_approved, classification, legal_doc_no, legal_issued_on, legal_issuer, created_by, updated_by)
  VALUES (%L, 'T68', %L, %L, 'CONSUME', 'THONG_TIN_CONG_DAN', 'Tra cứu TTHC, không gồm sức khỏe', 'RESTRICTED', 'Luật 91/2025/QH15', '2025-06-26', 'Quốc hội', 'hung', 'hung')$q$,
  pg_temp.id('ce68'), pg_temp.id('s68'), pg_temp.id('dm68')));
SELECT pg_temp.expect('13c trần không tự nâng mức phân loại', format($q$UPDATE ph01_onboarding.scope_ceiling SET classification = 'SENSITIVE' WHERE id = %L$q$, pg_temp.id('ce68')), '23514');
SELECT pg_temp.expect('13d danh tính của trần bất biến', format($q$UPDATE ph01_onboarding.scope_ceiling SET data_type = 'DU_LIEU_KHAC' WHERE id = %L$q$, pg_temp.id('ce68')), '23514');
SELECT pg_temp.expect('13e một trần mở mỗi loại dữ liệu', format($q$INSERT INTO ph01_onboarding.scope_ceiling (id, tenant_id, member_system_id, direction, data_type, scope_approved, classification, legal_doc_no, legal_issued_on, legal_issuer, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'CONSUME', 'THONG_TIN_CONG_DAN', 'x', 'INTERNAL', 'Luật', '2025-06-26', 'QH', 'hung', 'hung')$q$, pg_temp.id('s68')), '23505');
SELECT pg_temp.expect('13f tạm ngừng trần phải có lý do', format($q$UPDATE ph01_onboarding.scope_ceiling SET status = 'SUSPENDED' WHERE id = %L$q$, pg_temp.id('ce68')), '23514');
SELECT pg_temp.ok('13g tạm ngừng trần vì căn cứ hết hiệu lực', format($q$UPDATE ph01_onboarding.scope_ceiling SET status = 'SUSPENDED', suspend_reason = 'LEGAL_EXPIRED' WHERE id = %L$q$, pg_temp.id('ce68')));
SELECT pg_temp.ok('13h khôi phục trần', format($q$UPDATE ph01_onboarding.scope_ceiling SET status = 'ACTIVE', suspend_reason = NULL WHERE id = %L$q$, pg_temp.id('ce68')));

-- ===================== 5. Định danh ứng dụng, không lưu bí mật (BR-01-007) =====================
SELECT pg_temp.expect('14 không cấp PRODUCTION khi chưa qua SANDBOX (BR-01-008)', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'PRODUCTION', 'CLIENT_SECRET', 't68-ht-tuphap-prd', now() + interval '300 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('14b client_id phải mở đầu bằng mã tenant', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SANDBOX', 'CLIENT_SECRET', 't01-ht-tuphap-sbx', now() + interval '300 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('14c định danh tối đa 12 tháng', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SANDBOX', 'CLIENT_SECRET', 't68-ht-tuphap-sbx', now() + interval '13 months', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('14d định danh mới cấp không có scope dữ liệu (BR-01-003)', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, granted_scopes, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SANDBOX', 'CLIENT_SECRET', 't68-ht-tuphap-sbx', ARRAY['data:thong-tin-cong-dan'], now() + interval '300 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('14e cấp định danh SANDBOX chờ (bước RECORD)', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, expires_at, created_by, updated_by)
  VALUES (%L, 'T68', %L, 'SANDBOX', 'CLIENT_SECRET', 't68-ht-tuphap-sbx', now() + interval '300 days', 'tung', 'tung')$q$, pg_temp.id('cr68'), pg_temp.id('s68')));
SELECT pg_temp.expect('15 secret_ref không nhận giá trị bí mật', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ACTIVE', secret_ref = 'DH-CANARY-s3cr3t-value', secret_version = 1, secret_issued_at = now(), secret_expires_at = now() + interval '90 days' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.expect('15b secret_ref không trỏ sang tenant khác', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ACTIVE', secret_ref = 'kv/dh/t01/clients/HT-TUPHAP/sandbox', secret_version = 1, secret_issued_at = now(), secret_expires_at = now() + interval '90 days' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.expect('15c chuỗi bí mật tối đa 180 ngày (SEC-24)', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ACTIVE', secret_ref = 'kv/dh/t68/clients/HT-TUPHAP/sandbox', secret_version = 1, secret_issued_at = now(), secret_expires_at = now() + interval '181 days' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.expect('15d định danh ACTIVE có bí mật phải đủ phiên bản', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ACTIVE' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.ok('15e định danh chuyển ACTIVE', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ACTIVE', secret_ref = 'kv/dh/t68/clients/HT-TUPHAP/sandbox', secret_version = 1, secret_issued_at = now(), secret_expires_at = now() + interval '180 days' WHERE id = %L$q$, pg_temp.id('cr68')));
SELECT pg_temp.expect('15f mỗi (HTTT, môi trường) tối đa một định danh sống', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SANDBOX', 'CLIENT_SECRET', 't68-ht-tuphap-sbx2', now() + interval '300 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23505');
SELECT pg_temp.expect('15g client_id, môi trường bất biến', format($q$UPDATE ph01_onboarding.app_credential SET client_id = 't68-doi-ten' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.expect('15h secret_ref bất biến sau khi đặt', format($q$UPDATE ph01_onboarding.app_credential SET secret_ref = 'kv/dh/t68/clients/HT-KHAC/sandbox' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.expect('15i xoay vòng chuyển tiếp tối đa 14 ngày (BR-01-021)', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ROTATING', rotation_started_at = now(), rotation_ends_at = now() + interval '15 days' WHERE id = %L$q$, pg_temp.id('cr68')), '23514');
SELECT pg_temp.ok('15j bắt đầu xoay vòng 7 ngày', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ROTATING', rotation_started_at = now(), rotation_ends_at = now() + interval '7 days', previous_secret_version = 1, secret_version = 2 WHERE id = %L$q$, pg_temp.id('cr68')));
SELECT pg_temp.ok('15k kết thúc xoay vòng', format($q$UPDATE ph01_onboarding.app_credential SET status = 'ACTIVE', rotation_started_at = NULL, rotation_ends_at = NULL, previous_secret_version = NULL WHERE id = %L$q$, pg_temp.id('cr68')));
SELECT pg_temp.expect('15l định danh MTLS không có đường dẫn bí mật', format($q$INSERT INTO ph01_onboarding.app_credential (id, tenant_id, member_system_id, environment, auth_method, client_id, secret_ref, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SANDBOX', 'MTLS', 't68-ht-tuphap-mtls', 'kv/dh/t68/clients/HT-TUPHAP/sandbox', now() + interval '300 days', 'tung', 'tung')$q$, pg_temp.id('s68')), '23514');

-- ===================== 6. Bàn giao một lần (BR-01-005, BR-01-006) =====================
SELECT pg_temp.expect('16 không bàn giao cho đầu mối chưa có tài khoản (ERR-01-003)', format($q$INSERT INTO ph01_onboarding.handover (id, tenant_id, member_system_id, credential_id, recipient_contact_id, link_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, %L, repeat('c', 64), now() + interval '24 hours', 'tung', 'tung')$q$, pg_temp.id('s68'), pg_temp.id('cr68'), pg_temp.id('ct68b')), '23514');
SELECT pg_temp.expect('16b liên kết chỉ lưu dạng băm', format($q$INSERT INTO ph01_onboarding.handover (id, tenant_id, member_system_id, credential_id, recipient_contact_id, link_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, %L, 'qT3x-liên-kết-gốc-không-phải-băm', now() + interval '24 hours', 'tung', 'tung')$q$, pg_temp.id('s68'), pg_temp.id('cr68'), pg_temp.id('ct68')), '23514');
SELECT pg_temp.expect('16c hạn liên kết tối đa 72 giờ (NFR-01-010)', format($q$INSERT INTO ph01_onboarding.handover (id, tenant_id, member_system_id, credential_id, recipient_contact_id, link_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, %L, repeat('c', 64), now() + interval '73 hours', 'tung', 'tung')$q$, pg_temp.id('s68'), pg_temp.id('cr68'), pg_temp.id('ct68')), '23514');
SELECT pg_temp.ok('16d tạo bàn giao', format($q$INSERT INTO ph01_onboarding.handover (id, tenant_id, member_system_id, credential_id, recipient_contact_id, link_hash, wrap_accessor, wrap_token_sealed, expires_at, created_by, updated_by)
  VALUES (%L, 'T68', %L, %L, %L, repeat('b', 64), 'acc-123', 'vault:v1:AAAA', now() + interval '24 hours', 'tung', 'tung')$q$, pg_temp.id('ho68'), pg_temp.id('s68'), pg_temp.id('cr68'), pg_temp.id('ct68')));
SELECT pg_temp.expect('16e tối đa một bàn giao chờ mỗi định danh', format($q$INSERT INTO ph01_onboarding.handover (id, tenant_id, member_system_id, credential_id, recipient_contact_id, link_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, %L, repeat('d', 64), now() + interval '24 hours', 'tung', 'tung')$q$, pg_temp.id('s68'), pg_temp.id('cr68'), pg_temp.id('ct68')), '23505');
SELECT pg_temp.expect('16f liên kết bất biến', format($q$UPDATE ph01_onboarding.handover SET link_hash = repeat('e', 64) WHERE id = %L$q$, pg_temp.id('ho68')), '23514');
SELECT pg_temp.ok('16g chiếm chỗ PENDING → OPENING', format($q$UPDATE ph01_onboarding.handover SET status = 'OPENING' WHERE id = %L$q$, pg_temp.id('ho68')));
SELECT pg_temp.expect('16h mở xong thì mã bọc phải bị xóa', format($q$UPDATE ph01_onboarding.handover SET status = 'OPENED', opened_at = now(), opened_by = 'u-an', opened_ip = '10.0.0.5' WHERE id = %L$q$, pg_temp.id('ho68')), '23514');
SELECT pg_temp.ok('16i mở xong: OPENED, xóa mã bọc', format($q$UPDATE ph01_onboarding.handover SET status = 'OPENED', opened_at = now(), opened_by = 'u-an', opened_ip = '10.0.0.5', wrap_token_sealed = NULL WHERE id = %L$q$, pg_temp.id('ho68')));
SELECT pg_temp.expect('16j không mở lần hai: OPENED → PENDING', format($q$UPDATE ph01_onboarding.handover SET status = 'PENDING' WHERE id = %L$q$, pg_temp.id('ho68')), '55000');
SELECT pg_temp.expect('16k bàn giao đã mở không hủy được', format($q$UPDATE ph01_onboarding.handover SET status = 'CANCELLED' WHERE id = %L$q$, pg_temp.id('ho68')), '55000');

-- ===================== 7. Saga cấp định danh và cắt quyền =====================
SELECT pg_temp.ok('17 tạo saga SANDBOX', format($q$INSERT INTO ph01_onboarding.provisioning_saga (id, tenant_id, member_system_id, environment, deadline_at, requested_by, trace_id, created_by, updated_by)
  VALUES (%L, 'T68', %L, 'SANDBOX', now() + interval '24 hours', 'hung', repeat('1', 32), 'hung', 'hung')$q$, pg_temp.id('sg68'), pg_temp.id('s68')));
SELECT pg_temp.expect('17b mỗi (HTTT, môi trường) tối đa một saga đang chạy', format($q$INSERT INTO ph01_onboarding.provisioning_saga (id, tenant_id, member_system_id, environment, deadline_at, requested_by, trace_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SANDBOX', now() + interval '24 hours', 'hung', repeat('2', 32), 'hung', 'hung')$q$, pg_temp.id('s68')), '23505');
SELECT pg_temp.ok('17c bước RECORD lũy đẳng bằng sagaId:bước', format($q$INSERT INTO ph01_onboarding.saga_step (id, tenant_id, saga_id, step_name, step_no, idempotency_key)
  VALUES (gen_random_uuid(), 'T68', %L, 'RECORD', 1, %L || ':RECORD')$q$, pg_temp.id('sg68'), pg_temp.id('sg68')::text));
SELECT pg_temp.expect('17d khóa lũy đẳng sai', format($q$INSERT INTO ph01_onboarding.saga_step (id, tenant_id, saga_id, step_name, step_no, idempotency_key)
  VALUES (gen_random_uuid(), 'T68', %L, 'CLIENT', 2, 'khoa-sai')$q$, pg_temp.id('sg68')), '23514');
SELECT pg_temp.expect('17e số thứ tự bước sai', format($q$INSERT INTO ph01_onboarding.saga_step (id, tenant_id, saga_id, step_name, step_no, idempotency_key)
  VALUES (gen_random_uuid(), 'T68', %L, 'CLIENT', 5, %L || ':CLIENT')$q$, pg_temp.id('sg68'), pg_temp.id('sg68')::text), '23514');
SELECT pg_temp.expect('17f lỗi saga không được chứa bí mật', format($q$UPDATE ph01_onboarding.provisioning_saga SET last_error_detail = 'PH-12 từ chối: secret=abc' WHERE id = %L$q$, pg_temp.id('sg68')), '23514');
SELECT pg_temp.expect('17g saga kết thúc phải có thời điểm kết thúc', format($q$UPDATE ph01_onboarding.provisioning_saga SET state = 'SUCCEEDED' WHERE id = %L$q$, pg_temp.id('sg68')), '23514');
SELECT pg_temp.ok('17h saga thành công', format($q$UPDATE ph01_onboarding.provisioning_saga SET state = 'SUCCEEDED', finished_at = now(), credential_id = %L WHERE id = %L$q$, pg_temp.id('cr68'), pg_temp.id('sg68')));
SELECT pg_temp.ok('18 lập việc chặn cổng', format($q$INSERT INTO ph01_onboarding.enforcement_task (id, tenant_id, member_system_id, enforcement_id, mode, trigger_source, seq, task_type, client_ids, idempotency_key, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, 'SUSPEND', 'LIFECYCLE', 1, 'BLOCK_GATEWAY', ARRAY['t68-ht-tuphap-sbx'], %L || ':BLOCK_GATEWAY', 'hung', 'hung')$q$, pg_temp.id('s68'), pg_temp.id('st1'), pg_temp.id('st1')::text));
SELECT pg_temp.expect('18b thứ tự việc cắt quyền sai (SUSPEND, ENABLE_CLIENTS)', format($q$INSERT INTO ph01_onboarding.enforcement_task (id, tenant_id, member_system_id, enforcement_id, mode, trigger_source, seq, task_type, client_ids, idempotency_key, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, 'SUSPEND', 'LIFECYCLE', 2, 'ENABLE_CLIENTS', ARRAY['x'], %L || ':ENABLE_CLIENTS', 'hung', 'hung')$q$, pg_temp.id('s68'), pg_temp.id('st1'), pg_temp.id('st1')::text), '23514');
SELECT pg_temp.expect('18c chiều khôi phục không bắt đầu bằng chặn cổng', format($q$INSERT INTO ph01_onboarding.enforcement_task (id, tenant_id, member_system_id, enforcement_id, mode, trigger_source, seq, task_type, client_ids, idempotency_key, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, gen_random_uuid(), 'RESUME', 'LIFECYCLE', 1, 'BLOCK_GATEWAY', ARRAY['x'], 'sai', 'hung', 'hung')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('18d mỗi nhóm một việc mỗi loại', format($q$INSERT INTO ph01_onboarding.enforcement_task (id, tenant_id, member_system_id, enforcement_id, mode, trigger_source, seq, task_type, client_ids, idempotency_key, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, 'SUSPEND', 'LIFECYCLE', 1, 'BLOCK_GATEWAY', ARRAY['t68-ht-tuphap-sbx'], %L || ':BLOCK_GATEWAY', 'hung', 'hung')$q$, pg_temp.id('s68'), pg_temp.id('st1'), pg_temp.id('st1')::text), '23505');

-- ===================== 8. Kích hoạt, tạm ngừng, chấm dứt =====================
SELECT pg_temp.expect('19 không kích hoạt khi chưa qua SANDBOX (BR-01-008)', format($q$UPDATE ph01_onboarding.member_system SET status = 'ACTIVE', provision_stage = NULL, activated_by = 'nam', activated_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
INSERT INTO ph01_onboarding.sandbox_test (id, tenant_id, member_system_id, credential_id, source, observed_at, auth_ok, api_ok, call_count, success_count)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('s68'), pg_temp.id('cr68'), 'PH13', now(), true, true, 5, 5);
SELECT pg_temp.expect('19b kết quả kiểm thử không có lượt thành công vượt số lượt gọi', format($q$INSERT INTO ph01_onboarding.sandbox_test (id, tenant_id, member_system_id, source, observed_at, auth_ok, api_ok, call_count, success_count)
  VALUES (gen_random_uuid(), 'T68', %L, 'PH13', now(), true, true, 2, 3)$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('19c kết quả kiểm thử không được chứa bí mật', format($q$INSERT INTO ph01_onboarding.sandbox_test (id, tenant_id, member_system_id, source, observed_at, auth_ok, api_ok, call_count, success_count, error_detail)
  VALUES (gen_random_uuid(), 'T68', %L, 'PH13', now(), false, false, 1, 0, 'Authorization: Bearer eyJhbGciOi')$q$, pg_temp.id('s68')), '23514');
UPDATE ph01_onboarding.member_system SET sandbox_passed_at = now() WHERE id = pg_temp.id('s68');
SELECT pg_temp.expect('19d người nộp không được kích hoạt PRODUCTION', format($q$UPDATE ph01_onboarding.member_system SET status = 'ACTIVE', provision_stage = NULL, activated_by = 'mai', activated_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('19e kích hoạt bởi người khác', format($q$UPDATE ph01_onboarding.member_system SET status = 'ACTIVE', provision_stage = NULL, activated_by = 'nam', activated_at = now(), updated_by = 'nam' WHERE id = %L$q$, pg_temp.id('s68')));
SELECT pg_temp.expect('19f không quay ACTIVE → APPROVED', format($q$UPDATE ph01_onboarding.member_system SET status = 'APPROVED', provision_stage = 'PROVISIONING' WHERE id = %L$q$, pg_temp.id('s68')), '55000');
SELECT pg_temp.expect('20 tạm ngừng phải có lý do ≥ 10 ký tự', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUSPENDED', suspend_reason_code = 'SECURITY_SUSPECT', status_reason = 'ngắn' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('20b tạm ngừng phải có mã lý do', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUSPENDED', status_reason = 'Nghi lộ bí mật khách hàng' WHERE id = %L$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('20c tạm ngừng khẩn, đặt cờ cắt quyền', format($q$UPDATE ph01_onboarding.member_system SET status = 'SUSPENDED', suspend_reason_code = 'SECURITY_SUSPECT', status_reason = 'Nghi lộ bí mật khách hàng', enforcement = 'PENDING', updated_by = 'so1' WHERE id = %L$q$, pg_temp.id('s68')));
SELECT pg_temp.expect('20d không tạo bàn giao mới khi HTTT đang tạm ngừng (ERR-01-048)', format($q$INSERT INTO ph01_onboarding.handover (id, tenant_id, member_system_id, credential_id, recipient_contact_id, link_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, %L, %L, repeat('f', 64), now() + interval '24 hours', 'tung', 'tung')$q$, pg_temp.id('s68'), pg_temp.id('cr68'), pg_temp.id('ct68')), '23514');
SELECT pg_temp.ok('20e khôi phục', format($q$UPDATE ph01_onboarding.member_system SET status = 'ACTIVE', suspend_reason_code = NULL, enforcement = 'DONE', updated_by = 'so1' WHERE id = %L$q$, pg_temp.id('s68')));

-- ===================== 9. Thao tác khẩn và yêu cầu thay đổi =====================
INSERT INTO ph01_onboarding.emergency_action (id, tenant_id, member_system_id, action_type, reason, performed_by, confirm_by, created_by, updated_by)
VALUES (pg_temp.id('em68'), 'T68', pg_temp.id('s68'), 'SUSPEND', 'Nghi lộ bí mật khách hàng', 'so1', now() + interval '24 hours', 'so1', 'so1');
SELECT pg_temp.expect('21 người xác nhận khác người thực hiện', format($q$UPDATE ph01_onboarding.emergency_action SET status = 'CONFIRMED', confirmed_by = 'so1', confirmed_at = now() WHERE id = %L$q$, pg_temp.id('em68')), '23514');
SELECT pg_temp.expect('21b quá hạn phải có thời điểm quá hạn', format($q$UPDATE ph01_onboarding.emergency_action SET status = 'OVERDUE' WHERE id = %L$q$, pg_temp.id('em68')), '23514');
SELECT pg_temp.ok('21c quá hạn không tự hoàn tác', format($q$UPDATE ph01_onboarding.emergency_action SET status = 'OVERDUE', overdue_at = now() WHERE id = %L$q$, pg_temp.id('em68')));
SELECT pg_temp.ok('21d TA xác nhận bổ sung sau hạn', format($q$UPDATE ph01_onboarding.emergency_action SET status = 'CONFIRMED', confirmed_by = 'ta1', confirmed_at = now() WHERE id = %L$q$, pg_temp.id('em68')));
SELECT pg_temp.expect('21e lý do thao tác khẩn ≥ 10 ký tự', format($q$INSERT INTO ph01_onboarding.emergency_action (id, tenant_id, member_system_id, action_type, reason, performed_by, confirm_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'REVOKE', 'ngắn', 'so1', now() + interval '24 hours', 'so1', 'so1')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('22 đổi chủ quản phải nêu tổ chức mới', format($q$INSERT INTO ph01_onboarding.change_request (id, tenant_id, member_system_id, change_class, reason, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'OWNER_CHANGE', 'Sáp nhập đơn vị chủ quản', 'lan', 'lan', 'lan')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.ok('22b đề nghị thay đổi kỹ thuật', format($q$INSERT INTO ph01_onboarding.change_request (id, tenant_id, member_system_id, change_class, reason, diff, requested_by, created_by, updated_by)
  VALUES (%L, 'T68', %L, 'TECHNICAL', 'Đổi địa chỉ backend sang máy chủ mới', '{"baseUrls":["https://moi.tinh.gov.vn/api"]}', 'lan', 'lan', 'lan')$q$, pg_temp.id('ch68'), pg_temp.id('s68')));
SELECT pg_temp.expect('22c mỗi HTTT tối đa một yêu cầu đang chờ (ERR-01-038)', format($q$INSERT INTO ph01_onboarding.change_request (id, tenant_id, member_system_id, change_class, reason, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'TECHNICAL', 'Đề nghị khác khi còn yêu cầu chờ', 'lan', 'lan', 'lan')$q$, pg_temp.id('s68')), '23505');
SELECT pg_temp.expect('22d người duyệt khác người đề nghị', format($q$UPDATE ph01_onboarding.change_request SET status = 'APPROVED', decided_by = 'lan', decided_at = now() WHERE id = %L$q$, pg_temp.id('ch68')), '23514');
SELECT pg_temp.ok('22e duyệt bởi người khác', format($q$UPDATE ph01_onboarding.change_request SET status = 'APPROVED', decided_by = 'ta1', decided_at = now() WHERE id = %L$q$, pg_temp.id('ch68')));
SELECT pg_temp.ok('22f đề nghị chấm dứt', format($q$INSERT INTO ph01_onboarding.change_request (id, tenant_id, member_system_id, change_class, reason, requested_by, created_by, updated_by)
  VALUES (%L, 'T68', %L, 'TERMINATE', 'HTTT ngừng sử dụng từ quý sau', 'lan', 'lan', 'lan')$q$, pg_temp.id('ch68b'), pg_temp.id('s68')));
SELECT pg_temp.expect('22g duyệt chấm dứt phải kèm báo cáo tác động (FR-01-033)', format($q$UPDATE ph01_onboarding.change_request SET status = 'APPROVED', decided_by = 'ta1', decided_at = now() WHERE id = %L$q$, pg_temp.id('ch68b')), '23514');
SELECT pg_temp.ok('22h duyệt chấm dứt kèm báo cáo tác động', format($q$UPDATE ph01_onboarding.change_request SET status = 'APPROVED', decided_by = 'ta1', decided_at = now(), impact_report = '{"items":[],"partial":false}' WHERE id = %L$q$, pg_temp.id('ch68b')));

-- ===================== 10. Rà soát quyền định kỳ =====================
SELECT pg_temp.ok('23 mở kỳ rà soát', format($q$INSERT INTO ph01_onboarding.access_review_cycle (id, tenant_id, cycle_code, period_from, period_to, opened_by, created_by, updated_by)
  VALUES (%L, 'T68', 'RS-2026-01', '2026-05-01', '2026-11-01', 'ta1', 'ta1', 'ta1')$q$, pg_temp.id('cy68')));
SELECT pg_temp.expect('23b mỗi tenant tối đa một kỳ chưa đóng (ERR-01-039)', $q$INSERT INTO ph01_onboarding.access_review_cycle (id, tenant_id, cycle_code, period_from, period_to, opened_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'RS-2026-02', '2026-05-01', '2026-11-01', 'ta1', 'ta1', 'ta1')$q$, '23505');
SELECT pg_temp.expect('23c mã kỳ đúng mẫu RS-năm-số', $q$INSERT INTO ph01_onboarding.access_review_cycle (id, tenant_id, cycle_code, period_from, period_to, opened_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'KY-1', '2026-05-01', '2026-11-01', 'ta1', 'ta1', 'ta1')$q$, '23514');
SELECT pg_temp.ok('23d sinh mục rà soát', format($q$INSERT INTO ph01_onboarding.access_review_item (id, tenant_id, cycle_id, member_system_id, scope_ceiling_id, org_id, data_type, scope_snapshot, usage_in_period, unused_days, flags, legal_expired, created_by, updated_by)
  VALUES (%L, 'T68', %L, %L, %L, 'SO-TUPHAP', 'THONG_TIN_CONG_DAN', 'Tra cứu TTHC, không gồm sức khỏe', 0, 400, ARRAY['UNUSED_OVER_12M'], true, 'system', 'system')$q$, pg_temp.id('it68'), pg_temp.id('cy68'), pg_temp.id('s68'), pg_temp.id('ce68')));
SELECT pg_temp.expect('23e cờ rà soát ngoài danh sách', format($q$UPDATE ph01_onboarding.access_review_item SET flags = ARRAY['CO_LA'] WHERE id = %L$q$, pg_temp.id('it68')), '23514');
SELECT pg_temp.expect('24 kỳ đi một chiều, không nhảy OPEN → CLOSED', format($q$UPDATE ph01_onboarding.access_review_cycle SET status = 'CLOSED', closed_by = 'ta1', closed_at = now(), evidence_hash = repeat('a', 64) WHERE id = %L$q$, pg_temp.id('cy68')), '55000');
SELECT pg_temp.ok('24b OPEN → WAITING', format($q$UPDATE ph01_onboarding.access_review_cycle SET status = 'WAITING' WHERE id = %L$q$, pg_temp.id('cy68')));
SELECT pg_temp.expect('24c phiếu xác nhận hạn tối đa 60 ngày', format($q$INSERT INTO ph01_onboarding.review_confirmation (id, tenant_id, cycle_id, org_id, link_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SO-TUPHAP', repeat('7', 64), now() + interval '61 days', 'system', 'system')$q$, pg_temp.id('cy68')), '23514');
SELECT pg_temp.ok('24d gửi phiếu xác nhận cho đơn vị', format($q$INSERT INTO ph01_onboarding.review_confirmation (id, tenant_id, cycle_id, org_id, link_hash, expires_at, created_by, updated_by)
  VALUES (%L, 'T68', %L, 'SO-TUPHAP', repeat('7', 64), now() + interval '30 days', 'system', 'system')$q$, pg_temp.id('cf68'), pg_temp.id('cy68')));
SELECT pg_temp.ok('24e WAITING → DECIDING', format($q$UPDATE ph01_onboarding.access_review_cycle SET status = 'DECIDING' WHERE id = %L$q$, pg_temp.id('cy68')));
SELECT pg_temp.expect('24f không đóng kỳ khi còn mục chưa quyết định (FR-01-042)', format($q$UPDATE ph01_onboarding.access_review_cycle SET status = 'CLOSED', closed_by = 'ta1', closed_at = now(), evidence_hash = repeat('a', 64) WHERE id = %L$q$, pg_temp.id('cy68')), '23514');
SELECT pg_temp.expect('25 không giữ mục có căn cứ hết hiệu lực (ERR-01-041)', format($q$UPDATE ph01_onboarding.access_review_item SET decision = 'KEEP', decision_reason = 'Giữ', decided_by = 'ta1', decided_at = now() WHERE id = %L$q$, pg_temp.id('it68')), '23514');
SELECT pg_temp.expect('25b thu hẹp phải nêu phạm vi sau', format($q$UPDATE ph01_onboarding.access_review_item SET decision = 'REDUCE', decision_reason = 'Thu hẹp', decided_by = 'ta1', decided_at = now() WHERE id = %L$q$, pg_temp.id('it68')), '23514');
SELECT pg_temp.expect('25c quyết định phải có lý do và người quyết định', format($q$UPDATE ph01_onboarding.access_review_item SET decision = 'REVOKE_SCOPE' WHERE id = %L$q$, pg_temp.id('it68')), '23514');
SELECT pg_temp.ok('25d thu hồi phạm vi', format($q$UPDATE ph01_onboarding.access_review_item SET decision = 'REVOKE_SCOPE', decision_reason = 'Không dùng 400 ngày, căn cứ hết hiệu lực', decided_by = 'ta1', decided_at = now() WHERE id = %L$q$, pg_temp.id('it68')));
SELECT pg_temp.ok('25e đóng kỳ kèm bằng chứng', format($q$UPDATE ph01_onboarding.access_review_cycle SET status = 'CLOSED', closed_by = 'ta1', closed_at = now(), evidence_hash = repeat('a', 64) WHERE id = %L$q$, pg_temp.id('cy68')));
SELECT pg_temp.expect('25f kỳ đã đóng bất biến (NFR-01-022)', format($q$UPDATE ph01_onboarding.access_review_cycle SET item_count = 9 WHERE id = %L$q$, pg_temp.id('cy68')), '55000');
SELECT pg_temp.expect('25g không xóa kỳ rà soát (đặc quyền)', format($q$DELETE FROM ph01_onboarding.access_review_cycle WHERE id = %L$q$, pg_temp.id('cy68')), '42501');

-- ===================== 11. Đầu mối, tài liệu, nhập hệ cũ =====================
SELECT pg_temp.expect('26 đầu mối ATTT không công khai (BR-01-027)', format($q$INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, is_public, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'SECURITY', 'Phạm Văn Dũng', 'Cán bộ ATTT', 'dung@t68.gov.vn', true, 'lan', 'lan')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('26b thư điện tử sai dạng', format($q$INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'BUSINESS', 'x', 'x', 'khong-phai-thu', 'lan', 'lan')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('26c số điện thoại phải dạng E.164', format($q$UPDATE ph01_onboarding.contact SET phone = '0912345678' WHERE id = %L$q$, pg_temp.id('ct68')), '23514');
SELECT pg_temp.expect('26d trùng thư điện tử của đầu mối đang hoạt động', format($q$INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'TECHNICAL', 'Trùng', 'x', 'AN.NV@tuphap.tinh.gov.vn', 'lan', 'lan')$q$, pg_temp.id('s68')), '23505');
SELECT pg_temp.expect('26e đầu mối không hoạt động phải có lý do', format($q$UPDATE ph01_onboarding.contact SET status = 'INACTIVE' WHERE id = %L$q$, pg_temp.id('ct68b')), '23514');
SELECT pg_temp.ok('26f vô hiệu đầu mối do thư trả lại (BR-01-028)', format($q$UPDATE ph01_onboarding.contact SET status = 'INACTIVE', inactive_reason = 'MAIL_BOUNCED' WHERE id = %L$q$, pg_temp.id('ct68b')));
SELECT pg_temp.assert('26g tìm đầu mối không dấu', (SELECT count(*) FROM ph01_onboarding.contact WHERE search_text LIKE '%nguyen van an%') = 1);
SELECT pg_temp.expect('27 tệp đính kèm tối đa 50 MB (SEC-45)', format($q$INSERT INTO ph01_onboarding.attachment (id, tenant_id, member_system_id, kind, file_name, content_type, size_bytes, object_key, sha256, uploaded_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'OTHER', 'to.pdf', 'application/pdf', 52428801, 'HT-TUPHAP/to', repeat('a', 64), 'lan', 'lan', 'lan')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('27b khóa tạm staging không lưu ở bảng', format($q$INSERT INTO ph01_onboarding.attachment (id, tenant_id, member_system_id, kind, file_name, content_type, size_bytes, object_key, sha256, uploaded_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'OTHER', 'to.pdf', 'application/pdf', 1000, 'staging/abc', repeat('a', 64), 'lan', 'lan', 'lan')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('27c tệp chỉ CLEAN khi đã có thời điểm quét', format($q$INSERT INTO ph01_onboarding.attachment (id, tenant_id, member_system_id, kind, file_name, content_type, size_bytes, object_key, sha256, scan_status, uploaded_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', %L, 'OTHER', 'to.pdf', 'application/pdf', 1000, 'HT-TUPHAP/to2', repeat('a', 64), 'CLEAN', 'lan', 'lan', 'lan')$q$, pg_temp.id('s68')), '23514');
SELECT pg_temp.expect('28 xem trước nhập hệ cũ không mang khóa bí mật (BR-01-033)', format($q$INSERT INTO ph01_onboarding.legacy_import_job (id, tenant_id, source_kind, file_name, file_sha256, file_object_key, status, row_count, preview, requested_by, created_by, updated_by)
  VALUES (%L, 'T68', 'CSV', 'apim.csv', repeat('a', 64), 'tmp/apim.csv', 'PREVIEWED', 1, '[{"name":"HT A","clientSecret":"abcdefghijklmnopqrstuvwxyz"}]', 'ta1', 'ta1', 'ta1')$q$, pg_temp.id('lj68')), '23514');
SELECT pg_temp.expect('28b nhập tối đa 20.000 dòng', $q$INSERT INTO ph01_onboarding.legacy_import_job (id, tenant_id, source_kind, file_name, file_sha256, file_object_key, row_count, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'CSV', 'apim.csv', repeat('a', 64), 'tmp/apim2.csv', 20001, 'ta1', 'ta1', 'ta1')$q$, '23514');
SELECT pg_temp.ok('28c xem trước hợp lệ', format($q$INSERT INTO ph01_onboarding.legacy_import_job (id, tenant_id, source_kind, file_name, file_sha256, file_object_key, status, row_count, created_count, secrets_dropped, preview, requested_by, created_by, updated_by)
  VALUES (%L, 'T68', 'CSV', 'apim.csv', repeat('a', 64), 'tmp/apim.csv', 'PREVIEWED', 2, 1, 3, '[{"name":"HT A","legacyRef":"APIM-APP-1"}]', 'ta1', 'ta1', 'ta1')$q$, pg_temp.id('lj68')));
SELECT pg_temp.ok('28d xác nhận nhập: HTTT từ hệ cũ ở DRAFT, mang legacy_ref', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, legacy_ref, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'HT-NHAP1', 'Nhập 1', 'X', 'L1', 'LEGACY', ARRAY['CONSUMER'], 'APIM-APP-1', 'ta1', 'ta1')$q$);
SELECT pg_temp.expect('28e nhập lại cùng tệp bỏ qua HTTT đã có', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, legacy_ref, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'HT-NHAP2', 'Nhập trùng', 'X', 'L1', 'LEGACY', ARRAY['CONSUMER'], 'APIM-APP-1', 'ta1', 'ta1')$q$, '23505');

-- ===================== 12. Nháp: xóa mềm rồi xóa cứng sau 30 ngày =====================
INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, deleted_at, created_by, updated_by)
VALUES (pg_temp.id('dr1'), 'T68', 'HT-NHAPCU', 'Nháp cũ', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], now() - interval '31 days', 'lan', 'lan'),
       (pg_temp.id('dr2'), 'T68', 'HT-NHAPMOI', 'Nháp mới xóa', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], now() - interval '1 day', 'lan', 'lan');
SELECT pg_temp.ok('29 xóa cứng nháp đã xóa mềm quá 30 ngày (giải phóng mã)', format($q$DELETE FROM ph01_onboarding.member_system WHERE id = %L$q$, pg_temp.id('dr1')));
SELECT pg_temp.expect('29b chưa đủ 30 ngày thì chưa xóa cứng', format($q$DELETE FROM ph01_onboarding.member_system WHERE id = %L$q$, pg_temp.id('dr2')), '55000');
SELECT pg_temp.expect('29c xóa mềm chỉ áp dụng cho nháp chưa từng nộp', format($q$UPDATE ph01_onboarding.member_system SET deleted_at = now() WHERE id = %L$q$, pg_temp.id('s68')), '23514');

-- ===================== 13. Lịch sử trạng thái chỉ thêm =====================
INSERT INTO ph01_onboarding.state_history (id, tenant_id, member_system_id, subject_id, from_status, to_status, revision_no, reason, actor, occurred_at, trace_id)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('s68'), pg_temp.id('s68'), 'ACTIVE', 'SUSPENDED', 1, 'Nghi lộ bí mật khách hàng', 'so1', now(), repeat('3', 32));
SELECT pg_temp.expect('30 vai trò ứng dụng không sửa được lịch sử trạng thái', $q$UPDATE ph01_onboarding.state_history SET reason = 'sửa' WHERE tenant_id = 'T68'$q$, '42501');
SELECT pg_temp.expect('30b vai trò ứng dụng không xóa được lịch sử trạng thái', $q$DELETE FROM ph01_onboarding.state_history WHERE tenant_id = 'T68'$q$, '42501');
SELECT pg_temp.expect('30c trạng thái đến phải khác trạng thái đi', format($q$INSERT INTO ph01_onboarding.state_history (id, tenant_id, member_system_id, subject_id, from_status, to_status, actor, trace_id)
  VALUES (gen_random_uuid(), 'T68', %L, %L, 'ACTIVE', 'ACTIVE', 'so1', repeat('3', 32))$q$, pg_temp.id('s68'), pg_temp.id('s68')), '23514');

-- ===================== 14. Outbox, hàng đợi thông báo, lũy đẳng =====================
SELECT pg_temp.expect('31 outbox: topic phải thuộc đúng tenant', $q$INSERT INTO ph01_onboarding.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.connect.system.state-changed.v1', 't01.connect.system.state-changed.v1', 'MemberSystem', 'HT-TUPHAP', '{}', repeat('0', 32))$q$, '23514');
SELECT pg_temp.expect('31b outbox: không mang bí mật', $q$INSERT INTO ph01_onboarding.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.connect.credential.issued.v1', 't68.connect.credential.issued.v1', 'AppCredential', 'HT-TUPHAP', '{"secretRef":"kv/dh/t68/clients/HT-TUPHAP/sandbox"}', repeat('0', 32))$q$, '23514');
SELECT pg_temp.expect('31c outbox: không mang dữ liệu liên hệ cá nhân (EVT-01-13)', $q$INSERT INTO ph01_onboarding.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.connect.contact.changed.v1', 't68.connect.contact.changed.v1', 'Contact', 'HT-TUPHAP', '{"email":"an@tuphap.gov.vn"}', repeat('0', 32))$q$, '23514');
SELECT pg_temp.ok('31d outbox: sự kiện hợp lệ', $q$INSERT INTO ph01_onboarding.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.connect.system.state-changed.v1', 't68.connect.system.state-changed.v1', 'MemberSystem', 'HT-TUPHAP', '{"from":"ACTIVE","to":"SUSPENDED"}', repeat('0', 32))$q$);
SELECT pg_temp.expect('31e outbox: vai trò ứng dụng chỉ sửa được relayed_at', $q$UPDATE ph01_onboarding.outbox SET payload = '{}' WHERE tenant_id = 'T68'$q$, '42501');
SELECT pg_temp.ok('31f outbox: đánh dấu đã phát (đường dự phòng)', $q$UPDATE ph01_onboarding.outbox SET relayed_at = now() WHERE tenant_id = 'T68'$q$);
SELECT pg_temp.expect('32 thông báo không chứa liên kết bàn giao', $q$INSERT INTO ph01_onboarding.notify_outbox (id, tenant_id, kind, template_code, recipient_type, recipient_ref, payload, deadline_at, created_by)
  VALUES (gen_random_uuid(), 'T68', 'NOTIFY', 'handover-ready', 'USER', 'u-an', '{"url":"https://dh.gov.vn/ket-noi/ban-giao/AbCdEfGhIjKlMnOpQrStUvWxYz0123456789"}', now() + interval '24 hours', 'system')$q$, '23514');
SELECT pg_temp.expect('32b thông báo không có khóa token', $q$INSERT INTO ph01_onboarding.notify_outbox (id, tenant_id, kind, template_code, recipient_type, recipient_ref, payload, deadline_at, created_by)
  VALUES (gen_random_uuid(), 'T68', 'NOTIFY', 'handover-ready', 'USER', 'u-an', '{"token":"abc"}', now() + interval '24 hours', 'system')$q$, '23514');
SELECT pg_temp.ok('32c thông báo nhắc hạn định danh', $q$INSERT INTO ph01_onboarding.notify_outbox (id, tenant_id, kind, template_code, recipient_type, recipient_ref, payload, dedupe_key, deadline_at, created_by)
  VALUES (gen_random_uuid(), 'T68', 'NOTIFY', 'credential-expiring', 'ROLE', 'TA', '{"systemCode":"HT-TUPHAP","days":30}', 'expiring:cr68:30', now() + interval '24 hours', 'system')$q$);
SELECT pg_temp.expect('32d nhắc việc không gửi trùng', $q$INSERT INTO ph01_onboarding.notify_outbox (id, tenant_id, kind, template_code, recipient_type, recipient_ref, payload, dedupe_key, deadline_at, created_by)
  VALUES (gen_random_uuid(), 'T68', 'NOTIFY', 'credential-expiring', 'ROLE', 'TA', '{}', 'expiring:cr68:30', now() + interval '24 hours', 'system')$q$, '23505');
SELECT pg_temp.expect('33 không lưu kết quả lũy đẳng của tuyến mở bàn giao', $q$INSERT INTO ph01_onboarding.idempotency_record (tenant_id, client_id, request_method, request_path, idempotency_key, request_hash, expires_at)
  VALUES ('T68', 'bff', 'POST', '/api/connect/v1/handovers:open', 'abcdefghijklmnop1234', repeat('a', 64), now() + interval '24 hours')$q$, '23514');
SELECT pg_temp.expect('33b phản hồi lưu không chứa bí mật', $q$INSERT INTO ph01_onboarding.idempotency_record (tenant_id, client_id, request_method, request_path, idempotency_key, request_hash, state, response_status, completed_at, response_body, expires_at)
  VALUES ('T68', 'bff', 'POST', '/api/connect/v1/systems', 'abcdefghijklmnop1235', repeat('a', 64), 'COMPLETED', 201, now(), '{"clientSecret":"x"}', now() + interval '24 hours')$q$, '23514');
SELECT pg_temp.expect('33c khóa lũy đẳng giữ tối đa 24 giờ', $q$INSERT INTO ph01_onboarding.idempotency_record (tenant_id, client_id, request_method, request_path, idempotency_key, request_hash, expires_at)
  VALUES ('T68', 'bff', 'POST', '/api/connect/v1/systems', 'abcdefghijklmnop1236', repeat('a', 64), now() + interval '25 hours')$q$, '23514');
SELECT pg_temp.ok('33d lưu khóa lũy đẳng', $q$INSERT INTO ph01_onboarding.idempotency_record (tenant_id, client_id, request_method, request_path, idempotency_key, request_hash, expires_at)
  VALUES ('T68', 'bff', 'POST', '/api/connect/v1/systems', 'abcdefghijklmnop1237', repeat('a', 64), now() + interval '24 hours')$q$);
SELECT pg_temp.expect('33e cùng khóa lũy đẳng, cùng yêu cầu', $q$INSERT INTO ph01_onboarding.idempotency_record (tenant_id, client_id, request_method, request_path, idempotency_key, request_hash, expires_at)
  VALUES ('T68', 'bff', 'POST', '/api/connect/v1/systems', 'abcdefghijklmnop1237', repeat('b', 64), now() + interval '24 hours')$q$, '23505');
SELECT pg_temp.ok('33f hộp nhận sự kiện của PH-12', $q$INSERT INTO ph01_onboarding.inbox (tenant_id, event_id, source, event_type) VALUES ('T68', '01JABCDEF0123456789ABCDEFG', 'PH12', 'user.disabled')$q$);
SELECT pg_temp.expect('33g xử lý sự kiện lũy đẳng theo event_id', $q$INSERT INTO ph01_onboarding.inbox (tenant_id, event_id, source, event_type) VALUES ('T68', '01JABCDEF0123456789ABCDEFG', 'PH12', 'user.disabled')$q$, '23505');
SELECT pg_temp.ok('33h cùng event_id ở tenant khác không đụng nhau', $q$DO $b$ BEGIN PERFORM set_config('app.tenant_id', 'T01', true);
  INSERT INTO ph01_onboarding.inbox (tenant_id, event_id, source, event_type) VALUES ('T01', '01JABCDEF0123456789ABCDEFG', 'PH12', 'user.disabled'); END $b$$q$);

-- ===================== 15. Mẫu văn bản dùng chung (mẫu S) =====================
SET app.tenant_id = 'T01';
SELECT pg_temp.assert('34 tỉnh đọc được 3 mẫu mặc định của COMMON', (SELECT count(*) FROM ph01_onboarding.template WHERE tenant_id = 'COMMON') = 3);
SELECT pg_temp.expect('34b tỉnh không ghi được mẫu COMMON', $q$INSERT INTO ph01_onboarding.template (id, tenant_id, template_code, title, content_version, file_name, content_type, file_ref, file_sha256, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'mau-gia', 'giả', '1.0', 'a.docx', 'application/msword', 'x/a.docx', repeat('a', 64), 'lan', 'lan')$q$, '42501');
SELECT pg_temp.ok('34c tỉnh đặt mẫu riêng', $q$INSERT INTO ph01_onboarding.template (id, tenant_id, template_code, title, content_version, status, file_name, content_type, file_ref, file_sha256, published_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'mau-van-ban-de-nghi-ket-noi', 'Mẫu của tỉnh T01', '1.0', 'PUBLISHED', 'a.docx', 'application/msword', 'x/a.docx', repeat('a', 64), now(), 'lan', 'lan')$q$);
SELECT pg_temp.expect('34d mỗi mã mẫu chỉ một bản đang công bố mỗi tenant', $q$INSERT INTO ph01_onboarding.template (id, tenant_id, template_code, title, content_version, status, file_name, content_type, file_ref, file_sha256, published_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'mau-van-ban-de-nghi-ket-noi', 'Bản khác', '1.1', 'PUBLISHED', 'a.docx', 'application/msword', 'x/a.docx', repeat('a', 64), now(), 'lan', 'lan')$q$, '23505');
SET app.tenant_id = 'T68';
SELECT pg_temp.assert('34e T68 vẫn thấy mẫu COMMON, không thấy mẫu của T01', (SELECT count(*) FROM ph01_onboarding.template) = 3);
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.ok('34f phiên PLATFORM ghi được mẫu COMMON', $q$INSERT INTO ph01_onboarding.template (id, tenant_id, template_code, title, content_version, file_name, content_type, file_ref, file_sha256, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'mau-moi', 'Mẫu mới', '1.0', 'a.docx', 'application/msword', 'x/b.docx', repeat('a', 64), 'pa', 'pa')$q$);

-- ===================== 16. Quyền theo vai trò =====================
SET app.tenant_id = 'T68';
SELECT pg_temp.expect('35 vai trò ứng dụng không xóa được bước thẩm định', $q$DELETE FROM ph01_onboarding.review_step WHERE tenant_id = 'T68'$q$, '42501');
SELECT pg_temp.expect('35b vai trò ứng dụng không xóa được định danh', $q$DELETE FROM ph01_onboarding.app_credential WHERE tenant_id = 'T68'$q$, '42501');
SELECT pg_temp.expect('35c vai trò ứng dụng không sửa kết quả kiểm thử SANDBOX', $q$UPDATE ph01_onboarding.sandbox_test SET api_ok = false WHERE tenant_id = 'T68'$q$, '42501');
SELECT pg_temp.expect('35d vai trò ứng dụng không tạo được bảng', $q$CREATE TABLE ph01_onboarding.x (a int)$q$, '42501');
RESET ROLE;
SET ROLE ph01_owner;
SET app.tenant_id = 'T68';
SELECT pg_temp.expect('36 chủ bảng cũng không sửa được lịch sử trạng thái (trigger)', $q$UPDATE ph01_onboarding.state_history SET reason = 'sửa' WHERE tenant_id = 'T68'$q$, '55000');
SELECT pg_temp.expect('36b chủ bảng cũng chịu RLS (FORCE): không sửa được dòng tenant khác', $q$INSERT INTO ph01_onboarding.member_system (id, tenant_id, code, name, owner_org_id, security_level, system_type, roles, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'HT-CHEO', 'x', 'X', 'L1', 'PROVINCIAL', ARRAY['CONSUMER'], 'x', 'x')$q$, '42501');
RESET ROLE;
SET ROLE ph01_readonly;
SET app.tenant_id = 'T68';
SELECT pg_temp.assert('37 vai trò chỉ đọc đọc được cột không nhạy cảm', (SELECT count(*) FROM ph01_onboarding.member_system WHERE status = 'ACTIVE') = 1);
SELECT pg_temp.expect('37b không đọc họ tên đầu mối', $q$SELECT full_name FROM ph01_onboarding.contact$q$, '42501');
SELECT pg_temp.expect('37c không đọc thư điện tử đầu mối', $q$SELECT email FROM ph01_onboarding.contact$q$, '42501');
SELECT pg_temp.expect('37d không đọc đường dẫn bí mật', $q$SELECT secret_ref FROM ph01_onboarding.app_credential$q$, '42501');
SELECT pg_temp.expect('37e không đọc băm liên kết bàn giao', $q$SELECT link_hash FROM ph01_onboarding.handover$q$, '42501');
SELECT pg_temp.expect('37f không đọc danh sách IP cho phép', $q$SELECT ip_allowlist FROM ph01_onboarding.member_system$q$, '42501');
SELECT pg_temp.expect('37g không đọc khóa đối tượng của tệp', $q$SELECT object_key FROM ph01_onboarding.attachment$q$, '42501');
SELECT pg_temp.expect('37h không đọc outbox', $q$SELECT payload FROM ph01_onboarding.outbox$q$, '42501');
SELECT pg_temp.expect('37i vai trò chỉ đọc không ghi', $q$UPDATE ph01_onboarding.member_system SET name = 'x'$q$, '42501');
SELECT pg_temp.assert('37j vai trò chỉ đọc vẫn chịu RLS', (SELECT count(*) FROM ph01_onboarding.review_step) = 3);
SET app.tenant_id = 'T01';
SELECT pg_temp.assert('37k vai trò chỉ đọc của T01 không thấy bước thẩm định của T68', (SELECT count(*) FROM ph01_onboarding.review_step) = 0);
RESET ROLE;

-- ===================== 17. Cấu trúc: RLS, vai trò, không cột bí mật =====================
SELECT pg_temp.assert('38 mọi bảng có tenant_id đều FORCE ROW LEVEL SECURITY', NOT EXISTS (
  SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ph01_onboarding' AND c.relkind IN ('r', 'p')
     AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)
     AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity)));
SELECT pg_temp.assert('38b bảng duy nhất không có tenant_id là shedlock', (
  SELECT array_agg(c.relname::text ORDER BY c.relname) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ph01_onboarding' AND c.relkind IN ('r', 'p')
     AND NOT EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)) = ARRAY['shedlock']);
SELECT pg_temp.assert('38c schema có đủ 26 bảng', (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'ph01_onboarding' AND c.relkind IN ('r', 'p')) = 26);
SELECT pg_temp.assert('38d mỗi bảng có tenant_id kèm chính sách đọc, thêm, sửa, xóa', NOT EXISTS (
  SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ph01_onboarding' AND c.relrowsecurity
     AND (SELECT count(DISTINCT cmd) FROM pg_policies p WHERE p.schemaname = n.nspname AND p.tablename = c.relname) <> 4));
SELECT pg_temp.assert('39 dh_connect_app không BYPASSRLS, không siêu người dùng', NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_connect_app' AND (rolbypassrls OR rolsuper)));
SELECT pg_temp.assert('39b ph01_owner, ph01_app, ph01_readonly không BYPASSRLS', NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname IN ('ph01_owner', 'ph01_app', 'ph01_readonly') AND (rolbypassrls OR rolsuper OR rolcanlogin)));
SELECT pg_temp.assert('39c ph01_app không là chủ bảng nào', NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'ph01_onboarding' AND tableowner <> 'ph01_owner'));
SELECT pg_temp.assert('40 không có cột chứa giá trị bí mật (BR-01-007, NFR-01-009)', NOT EXISTS (
  SELECT 1 FROM information_schema.columns
   WHERE table_schema = 'ph01_onboarding' AND column_name ~* '(secret|passw|private_?key|credential_value|api_?key)'
     AND column_name NOT IN ('secret_ref', 'secret_version', 'previous_secret_version', 'secret_issued_at', 'secret_expires_at', 'secrets_dropped')));
SELECT pg_temp.assert('40b không có cột lưu liên kết gốc', NOT EXISTS (
  SELECT 1 FROM information_schema.columns WHERE table_schema = 'ph01_onboarding' AND column_name ~* '(^|_)(link|url)(_|$)' AND column_name NOT IN ('base_urls', 'link_hash')));
\echo 'Hoàn tất: mọi khối PASS'
