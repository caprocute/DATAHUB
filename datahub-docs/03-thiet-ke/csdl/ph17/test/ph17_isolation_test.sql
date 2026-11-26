-- =============================================================================
-- D03-03-PH17 · Kiểm thử DDL ph17_assist: cô lập tenant (RLS), vai nền tảng ghi COMMON, bốn mắt bật trợ lý và duyệt phiên bản
-- mô hình, prompt, máy trạng thái (tenant, mô hình, tài liệu, gợi ý, prompt), cổng phát hành (đánh giá, ca đỏ ≥ 50 ca),
-- mô hình ngoài theo danh sách trắng, khóa chỉ PUBLIC hoặc INTERNAL ở chỉ mục và xóa lan truyền, RLS theo người dùng
-- cho hội thoại kèm phiếu truy cập nhật ký, nhật ký chỉ thêm, outbox không chứa nội dung, quyền vai trò, nạp tenant.
-- Chạy sau ph17_assist.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d ph17_test -f ph17_isolation_test.sql
-- pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại, 42501 quyền hoặc RLS,
-- 55000 bất biến hoặc chuyển trạng thái sai) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- Không phụ thuộc pgvector: cột embedding là real[] (CI) hoặc vector(1024) (có extension), cùng nhận mảng 1024 số thực.
-- Tương ứng nhóm ca cô lập (NFR-17-021, BR-17-086) và BR-17-002, 004, 008, 014, 015, 018, 026, 029, 033, 056, 062, 064, 067,
-- 069, 073, 074 của D05-02-PH17.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_assist_app') THEN CREATE ROLE dh_assist_app LOGIN NOBYPASSRLS; END IF;
  GRANT ph17_app TO dh_assist_app;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_assist_platform') THEN CREATE ROLE dh_assist_platform LOGIN NOBYPASSRLS; END IF;
  GRANT ph17_platform TO dh_assist_platform;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_assist_infer') THEN CREATE ROLE dh_assist_infer LOGIN NOBYPASSRLS; END IF;
  GRANT ph17_infer TO dh_assist_infer;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_assist_job') THEN CREATE ROLE dh_assist_job LOGIN NOBYPASSRLS; END IF;
  GRANT ph17_job TO dh_assist_job;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_assist_ro') THEN CREATE ROLE dh_assist_ro LOGIN NOBYPASSRLS; END IF;
  GRANT ph17_readonly TO dh_assist_ro;
END $$;
SET ROLE dh_assist_app;

CREATE FUNCTION pg_temp.expect(p_sql text, p_state text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE ok boolean := false;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = p_state THEN ok := true;
    ELSE RAISE EXCEPTION 'FAIL %: SQLSTATE % (mong %): %', p_label, SQLSTATE, p_state, SQLERRM; END IF;
  END;
  IF NOT ok THEN RAISE EXCEPTION 'FAIL %: không bị chặn', p_label; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE FUNCTION pg_temp.is_true(p_sql text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE r boolean;
BEGIN
  EXECUTE p_sql INTO r;
  IF r IS NOT TRUE THEN RAISE EXCEPTION 'FAIL %', p_label; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['pc1','pc2','pc3','pc4','pc5','n1','n2','prov_in','prov_ex','prov_bad','cm1','m_chat','m_emb','m_ext','mv_chat','mv_emb','mv_ext','mv_draft','mv_x',
  'es1','es2','dl1','ec1','ec2','er_pv','er_pr','er_x','rt_t90','er_ev','er_rt','er_rt_bad','tm1','tm2','tm3','src1','src2','src3','doc1','doc2','doc3','doc4','doc5','ch1','ch2','ch3','ch4','cv1','cv2','cv3','cv4','ms1','ms2','ms3','ms4','ms5','sg1','sg2','sg3','sg4',
  'pt1','pv1','pv2','pv3','pv_er_ev','pv_er_rt','fb1','fb2','lg1','lg2','lg3','lg4','f1','f2','f3','ks1','ks2','route1','kd1']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
GRANT SELECT ON pg_temp.ids TO PUBLIC;
CREATE FUNCTION pg_temp.vec(real) RETURNS real[] LANGUAGE sql AS $$ SELECT array_fill($1, ARRAY[1024]) $$;
CREATE FUNCTION pg_temp.hash(text) RETURNS text LANGUAGE sql AS $$ SELECT encode(sha256(convert_to($1, 'UTF8')), 'hex') $$;

-- ---------- 1. Nạp tenant bằng thủ tục ----------
SET app.tenant_id = 'T90';
CALL ph17_assist.p_seed_tenant('T90');
SET app.tenant_id = 'T91';
CALL ph17_assist.p_seed_tenant('T91');
SET app.tenant_id = 'T90';
CALL ph17_assist.p_seed_tenant('T90');
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM ph17_assist.tenant_policy) = 1 AND (SELECT count(*) FROM ph17_assist.capability_policy) = 3
  AND (SELECT count(*) FROM ph17_assist.tool_definition) = 9 AND (SELECT count(*) FROM ph17_assist.guardrail_rule) = 10 AND (SELECT count(*) FROM ph17_assist.tenant_setting) = 49
  AND (SELECT count(*) FROM ph17_assist.suggested_question) = 6 AND (SELECT count(*) FROM ph17_assist.link_allowlist) = 1$q$, '01 nạp tenant: 1 chính sách, 3 năng lực, 9 công cụ, 10 quy tắc lọc, 49 tham số, 6 câu hỏi; chạy lại không nhân bản');
SELECT pg_temp.is_true($q$SELECT assist_state = 'DISABLED' AND NOT external_allowed FROM ph17_assist.tenant_policy$q$, '02 trợ lý tắt mặc định, mô hình ngoài tắt (BR-17-001, 004)');
SELECT pg_temp.is_true($q$SELECT bool_and(NOT enabled) FROM ph17_assist.capability_policy$q$, '03 mọi năng lực tắt mặc định');
SELECT pg_temp.is_true($q$SELECT value = '90'::jsonb AND floor_value = '90'::jsonb AND four_eyes FROM ph17_assist.tenant_setting WHERE setting_key = '17.log.retention-days'$q$, '04 17.log.retention-days = 90, sàn 90, bốn mắt');
SELECT pg_temp.is_true($q$SELECT value = '0.55'::jsonb AND floor_value = '0.3'::jsonb AND ceiling_value = '0.9'::jsonb FROM ph17_assist.tenant_setting WHERE setting_key = '17.rag.min-score'$q$, '05 17.rag.min-score = 0,55 trong 0,3 đến 0,9');
SELECT pg_temp.is_true($q$SELECT value = '2000000'::jsonb AND ceiling_value = '50000000'::jsonb FROM ph17_assist.tenant_setting WHERE setting_key = '17.quota.tenant-tokens-per-day'$q$, '06 hạn mức token tenant mặc định 2.000.000, trần 50.000.000');
SELECT pg_temp.is_true($q$SELECT bool_and(read_only) AND bool_and(scope LIKE '%:read') FROM ph17_assist.tool_definition$q$, '07 mọi công cụ chỉ đọc, scope kết thúc :read (BR-17-056)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tool_definition SET read_only = false WHERE tool_code = 'SEARCH_API'$q$, '55000', '08 read_only của công cụ bất biến, không chuyển sang ghi');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tool_definition SET scope = 'catalog:write' WHERE tool_code = 'SEARCH_API'$q$, '55000', '09 scope công cụ bất biến');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tool_definition SET enabled = true WHERE tool_code = 'SEARCH_API'$q$, '23514', '10 bật công cụ cần người bật và thời điểm');
UPDATE ph17_assist.tool_definition SET enabled = true, enabled_by = 'so-binh', enabled_at = now() WHERE tool_code = 'SEARCH_API';
SELECT pg_temp.expect($q$UPDATE ph17_assist.tool_definition SET tool_code = 'KHAC' WHERE tool_code = 'SEARCH_API'$q$, '55000', '11 mã công cụ bất biến');
SELECT pg_temp.expect($q$UPDATE ph17_assist.guardrail_rule SET builtin = false WHERE rule_code = 'GR-IN-INJECT-001'$q$, '55000', '12 quy tắc dựng sẵn không đổi cờ builtin');
SELECT pg_temp.expect($q$UPDATE ph17_assist.guardrail_rule SET action = 'WARN' WHERE rule_code = 'GR-OUT-SECRET-PEM'$q$, '23514', '13 quy tắc chặn bí mật không hạ thành cảnh báo');
SELECT pg_temp.expect($q$UPDATE ph17_assist.guardrail_rule SET action = 'MASK' WHERE rule_code = 'GR-IN-INJECT-001'$q$, '23514', '14 quy tắc tiêm lệnh luôn chặn');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_setting SET value = '30'::jsonb WHERE setting_key = '17.log.retention-days'$q$, '23514', '15 hạn lưu nhật ký không thấp hơn 90 (ERR-17-083)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_setting SET value = '90'::jsonb WHERE setting_key = '17.redteam.min-pass-rate'$q$, '23514', '16 tỷ lệ ca đỏ phải chặn luôn 100');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_setting SET value = '9000'::jsonb WHERE setting_key = '17.input.max-chars'$q$, '23514', '17 vượt trần 17.input.max-chars (ERR-17-018)') ;
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '17.khong.co', '1'::jsonb, 'ta-an', 'ta-an')$q$, '23514', '18 khóa tham số lạ bị chặn (ERR-17-084)');

-- ---------- 2. Cô lập tenant: T91 không đọc, chèn, sửa, xóa dòng T90 ----------
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM ph17_assist.tool_definition) = 9 AND (SELECT count(*) FROM ph17_assist.tool_definition WHERE enabled) = 0$q$, '19 T91 chỉ thấy 9 công cụ của mình, công cụ T90 đã bật không lộ');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.link_allowlist (id, tenant_id, route_prefix, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '/x', 'a', 'a')$q$, '42501', '20 T91 không chèn dòng của T90 (RLS)');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph17_assist.tenant_setting SET value = '"x"'::jsonb WHERE tenant_id = 'T90' RETURNING 1) SELECT count(*) = 0 FROM u$q$, '21 T91 sửa tham số T90 không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph17_assist.link_allowlist WHERE tenant_id = 'T90' RETURNING 1) SELECT count(*) = 0 FROM d$q$, '22 T91 xóa dòng T90 không được dòng nào');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.link_allowlist (id, tenant_id, route_prefix, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '/x', 'a', 'a')$q$, '42501', '23 vai ứng dụng không ghi dòng COMMON');
SET app.tenant_id = 'T90';

-- ---------- 3. Bật trợ lý: bốn mắt, máy trạng thái tenant ----------
INSERT INTO ph17_assist.policy_change (id, tenant_id, change_type, reason, decision_no, requested_by, created_by, updated_by)
VALUES (pg_temp.id('pc1'), 'T90', 'ENABLE', 'Bật trợ lý theo quyết định của lãnh đạo tỉnh cho thí điểm', '123/QĐ-UBND', 'ta-an', 'ta-an', 'ta-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.policy_change (id, tenant_id, change_type, reason, decision_no, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'ENABLE', 'Đề nghị thứ hai cùng loại đang chờ duyệt', '124/QĐ-UBND', 'ta-an', 'ta-an', 'ta-an')$q$, '23505', '24 mỗi loại chỉ một đề nghị PENDING (ERR-17-013)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.policy_change (id, tenant_id, change_type, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RESUME', 'Gỡ tắt khẩn cần số quyết định của lãnh đạo', 'ta-an', 'ta-an', 'ta-an')$q$, '23514', '25 bật lại cần số quyết định (ERR-17-014)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.policy_change SET state = 'APPROVED', decided_by = 'ta-an', decided_at = now() WHERE id = pg_temp.id('pc1')$q$, '23514', '26 người đề nghị tự duyệt bị chặn (ERR-17-005)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_policy SET assist_state = 'ENABLED', enable_decision_no = '123/QĐ-UBND', enabled_at = now(), enabled_by = 'ta-an'$q$, '23514', '27 ENABLED cần đề nghị đã duyệt (enabled_change_id)');
UPDATE ph17_assist.policy_change SET state = 'APPROVED', decided_by = 'ta-binh', decided_at = now() WHERE id = pg_temp.id('pc1');
SELECT pg_temp.expect($q$UPDATE ph17_assist.policy_change SET state = 'PENDING' WHERE id = pg_temp.id('pc1')$q$, '55000', '28 đề nghị đã duyệt không quay lại PENDING');
UPDATE ph17_assist.tenant_policy SET assist_state = 'ENABLED', enable_decision_no = '123/QĐ-UBND', enable_reason = 'Thí điểm', enabled_change_id = pg_temp.id('pc1'), enabled_at = now(), enabled_by = 'ta-binh';
SELECT pg_temp.is_true($q$SELECT assist_state = 'ENABLED' AND version = 1 FROM ph17_assist.tenant_policy$q$, '29 bật được khi có số quyết định và đề nghị duyệt; version tăng');
UPDATE ph17_assist.tenant_policy SET assist_state = 'KILLED', killed_at = now(), killed_by = 'ta-an', kill_reason = 'Nghi lộ dữ liệu qua câu trả lời';
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_policy SET assist_state = 'ENABLED', killed_at = NULL$q$, '55000', '30 KILLED không tự quay về ENABLED (BR-17-008)');
UPDATE ph17_assist.tenant_policy SET assist_state = 'DISABLED', killed_at = NULL, enabled_at = NULL;
SELECT pg_temp.is_true($q$SELECT assist_state = 'DISABLED' FROM ph17_assist.tenant_policy$q$, '31 gỡ tắt khẩn đưa về DISABLED');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_policy SET external_allowed = true$q$, '23514', '32 cho phép mô hình ngoài cần đề nghị EXTERNAL_ON');
INSERT INTO ph17_assist.kill_switch_record (id, tenant_id, scope, reason, activated_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TENANT', 'Phát hiện câu trả lời lộ mã định danh', 'ta-an', 'ta-an', 'ta-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.kill_switch_record (id, tenant_id, scope, reason, activated_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TENANT', 'Lần tắt khẩn thứ hai khi lần một chưa gỡ', 'ta-an', 'ta-an', 'ta-an')$q$, '23505', '33 mỗi tenant chỉ một tắt khẩn đang hiệu lực');
SELECT pg_temp.expect($q$UPDATE ph17_assist.kill_switch_record SET release_requested_by = 'ta-an', release_requested_at = now(), released_by = 'ta-an', released_at = now()$q$, '23514', '34 gỡ tắt khẩn cần hai người khác nhau');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.kill_switch_record (id, tenant_id, scope, reason, activated_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'TENANT', 'ngắn', 'ta-an', 'ta-an', 'ta-an')$q$, '42501', '35 không tắt khẩn thay tenant khác (RLS)');
UPDATE ph17_assist.kill_switch_record SET release_requested_by = 'ta-an', release_requested_at = now(), released_by = 'ta-binh', released_at = now();
SELECT pg_temp.is_true($q$SELECT released_by = 'ta-binh' FROM ph17_assist.kill_switch_record$q$, '36 gỡ tắt khẩn bởi người thứ hai');
SELECT pg_temp.expect($q$UPDATE ph17_assist.kill_switch_record SET reason = 'Sửa lý do sau khi tắt khẩn đã xong'$q$, '55000', '37 lý do tắt khẩn bất biến');

-- ---------- 4. Điều khoản, xác nhận ----------
INSERT INTO ph17_assist.ai_notice (id, tenant_id, version_no, title, body_text, created_by, updated_by) VALUES (pg_temp.id('n1'), 'T90', 1, 'Điều khoản dùng trợ lý AI', 'Nội dung do AI tạo, cần kiểm tra lại. Không nhập dữ liệu cá nhân nhạy cảm.', 'ta-an', 'ta-an');
UPDATE ph17_assist.ai_notice SET status = 'PUBLISHED', published_at = now(), published_by = 'ta-an' WHERE id = pg_temp.id('n1');
SELECT pg_temp.expect($q$UPDATE ph17_assist.ai_notice SET body_text = 'Sửa nội dung đã công bố' WHERE id = pg_temp.id('n1')$q$, '55000', '38 điều khoản đã công bố không sửa nội dung (ERR-17-024)');
INSERT INTO ph17_assist.ai_notice (id, tenant_id, version_no, title, body_text, created_by, updated_by) VALUES (pg_temp.id('n2'), 'T90', 2, 'Điều khoản dùng trợ lý AI bản 2', 'Bản bổ sung nội dung giải thích sự cố.', 'ta-an', 'ta-an');
SELECT pg_temp.expect($q$UPDATE ph17_assist.ai_notice SET status = 'PUBLISHED', published_at = now(), published_by = 'ta-an' WHERE id = pg_temp.id('n2')$q$, '23505', '39 chỉ một điều khoản PUBLISHED; bản cũ phải RETIRED trước');
UPDATE ph17_assist.ai_notice SET status = 'RETIRED', retired_at = now() WHERE id = pg_temp.id('n1');
UPDATE ph17_assist.ai_notice SET status = 'PUBLISHED', published_at = now(), published_by = 'ta-an' WHERE id = pg_temp.id('n2');
INSERT INTO ph17_assist.notice_acceptance (id, tenant_id, notice_id, user_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('n2'), 'user-an', 'user-an', 'user-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.notice_acceptance (id, tenant_id, notice_id, user_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('n2'), 'user-an', 'user-an', 'user-an')$q$, '23505', '40 xác nhận một lần cho mỗi (điều khoản, người dùng)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.notice_acceptance SET user_id = 'user-binh'$q$, '42501', '41 xác nhận điều khoản chỉ thêm (không UPDATE)');
SELECT pg_temp.expect($q$DELETE FROM ph17_assist.notice_acceptance$q$, '42501', '42 xác nhận điều khoản không xóa');

-- ---------- 5. Nền tảng: nhà cung cấp, mô hình, phiên bản (vai ph17_platform, phiên COMMON) ----------
RESET ROLE;
SET ROLE dh_assist_platform;
SET app.tenant_id = 'COMMON';
INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, status, created_by, updated_by)
VALUES (pg_temp.id('prov_in'), 'COMMON', 'VLLM-NOI-BO', 'Dịch vụ vLLM nội bộ của tỉnh', 'INTERNAL', 'http://vllm.dh-assist.svc:8000/v1', 'DRAFT', 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, secret_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'NCC-NGOAI-1', 'Nhà cung cấp ngoài', 'EXTERNAL', 'https://10.20.30.40/v1', 'openbao://kv/tenants/COMMON/assist/provider-x', 'pa-an', 'pa-an')$q$, '23514', '43 điểm cuối ngoài không nhận IP trần (BR-17-012)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'NCC-NGOAI-2', 'Nhà cung cấp ngoài', 'EXTERNAL', 'https://api.nha-cung-cap.example.vn/v1', 'pa-an', 'pa-an')$q$, '23514', '44 nhà cung cấp ngoài phải có secret_ref (ERR-17-028)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, secret_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'NCC-NGOAI-3', 'Nhà cung cấp ngoài', 'EXTERNAL', 'http://api.nha-cung-cap.example.vn/v1', 'openbao://kv/tenants/COMMON/assist/provider-x', 'pa-an', 'pa-an')$q$, '23514', '45 điểm cuối ngoài phải HTTPS (ERR-17-025)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, secret_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'NCC-NGOAI-4', 'Nhà cung cấp ngoài', 'EXTERNAL', 'https://api.nha-cung-cap.example.vn/v1', 'sk-live-giatri-that', 'pa-an', 'pa-an')$q$, '23514', '46 secret_ref chỉ dạng openbao://kv/..., không giá trị bí mật (BR-17-011)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, secret_ref, data_region, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'NCC-NGOAI-5', 'Nhà cung cấp ngoài', 'EXTERNAL', 'https://api.nha-cung-cap.example.vn/v1', 'openbao://kv/tenants/COMMON/assist/provider-x', 'SG', 'pa-an', 'pa-an')$q$, '23514', '47 nhà cung cấp ngoài phải lưu dữ liệu trong nước (vùng VN)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LAC-TENANT', 'Dòng không phải COMMON', 'INTERNAL', 'http://vllm.dh-assist.svc:8000/v1', 'pa-an', 'pa-an')$q$, '42501', '48 vai nền tảng chỉ ghi dòng COMMON (RLS)');
INSERT INTO ph17_assist.model_provider (id, tenant_id, provider_code, name, provider_kind, endpoint_url, secret_ref, status, created_by, updated_by)
VALUES (pg_temp.id('prov_ex'), 'COMMON', 'NCC-NGOAI-VN', 'Nhà cung cấp mô hình trong nước (giả lập)', 'EXTERNAL', 'https://api.nha-cung-cap.example.vn/v1', 'openbao://kv/tenants/COMMON/assist/provider-x', 'DRAFT', 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_provider SET status = 'ACTIVE' WHERE id = pg_temp.id('prov_ex')$q$, '23514', '49 nhà cung cấp ngoài ACTIVE cần cam kết còn hiệu lực (BR-17-013)');
INSERT INTO ph17_assist.file_object (id, tenant_id, bucket, object_key, file_name, content_type, size_bytes, sha256, scan_status, purpose, created_by, updated_by)
VALUES (pg_temp.id('f1'), 'COMMON', 'dh-assist-commit', 'COMMON/cam-ket-01.pdf', 'cam-ket-01.pdf', 'application/pdf', 120000, pg_temp.hash('cam-ket-01'), 'CLEAN', 'COMMITMENT', 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.file_object (id, tenant_id, bucket, object_key, file_name, content_type, size_bytes, sha256, purpose, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'b', 'k1', 'a.exe', 'application/x-msdownload', 1, repeat('a', 64), 'COMMITMENT', 'pa-an', 'pa-an')$q$, '23514', '50 tệp chỉ nhận loại nội dung cho phép');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.file_object (id, tenant_id, bucket, object_key, file_name, content_type, size_bytes, sha256, data_class, purpose, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'b', 'k2', 'a.pdf', 'application/pdf', 1, repeat('a', 64), 'RESTRICTED', 'COMMITMENT', 'pa-an', 'pa-an')$q$, '23514', '51 tệp chỉ mức PUBLIC hoặc INTERNAL');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.provider_commitment (id, tenant_id, provider_id, doc_no, doc_date, valid_from, valid_to, domestic_storage, no_training, file_id, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', pg_temp.id('prov_ex'), 'CK-01', '2026-10-01', '2026-10-01', '2027-10-01', true, false, pg_temp.id('f1'), 'pa-an', 'pa-an')$q$, '23514', '52 cam kết phải đủ lưu trong nước và không huấn luyện (ERR-17-026)');
INSERT INTO ph17_assist.provider_commitment (id, tenant_id, provider_id, doc_no, doc_date, valid_from, valid_to, domestic_storage, no_training, file_id, created_by, updated_by)
VALUES (pg_temp.id('cm1'), 'COMMON', pg_temp.id('prov_ex'), 'CK-01', '2026-10-01', '2026-10-01', '2027-10-01', true, true, pg_temp.id('f1'), 'pa-an', 'pa-an');
UPDATE ph17_assist.model_provider SET commitment_valid_to = '2027-10-01', status = 'ACTIVE' WHERE id = pg_temp.id('prov_ex');
UPDATE ph17_assist.model_provider SET status = 'ACTIVE' WHERE id = pg_temp.id('prov_in');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_provider SET status = 'DRAFT' WHERE id = pg_temp.id('prov_in')$q$, '55000', '53 nhà cung cấp ACTIVE không quay về DRAFT');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_provider SET provider_kind = 'INTERNAL' WHERE id = pg_temp.id('prov_ex')$q$, '55000', '54 loại nhà cung cấp bất biến');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_provider SET status = 'SUSPENDED' WHERE id = pg_temp.id('prov_ex')$q$, '23514', '55 đình chỉ nhà cung cấp phải có lý do');
INSERT INTO ph17_assist.model (id, tenant_id, model_code, name, model_kind, scope, provider_id, capabilities, created_by, updated_by) VALUES
  (pg_temp.id('m_chat'), 'COMMON', 'chat-noi-bo-8b', 'Mô hình hội thoại nội bộ', 'CHAT', 'COMMON', pg_temp.id('prov_in'), ARRAY['SEARCH','MAPPING','EXPLAIN','CLASSIFY_TEXT','EXTRACT_FIELDS','SUGGEST_STEP'], 'pa-an', 'pa-an'),
  (pg_temp.id('m_emb'), 'COMMON', 'nhung-da-ngu-1024', 'Mô hình nhúng đa ngữ 1024 chiều', 'EMBEDDING', 'COMMON', pg_temp.id('prov_in'), ARRAY['EMBED'], 'pa-an', 'pa-an'),
  (pg_temp.id('m_ext'), 'COMMON', 'chat-ngoai-vn', 'Mô hình hội thoại ngoài trong nước', 'CHAT', 'COMMON', pg_temp.id('prov_ex'), ARRAY['SEARCH','EXPLAIN'], 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model (id, tenant_id, model_code, name, model_kind, scope, provider_id, capabilities, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'nhung-sai', 'Nhúng sai năng lực', 'EMBEDDING', 'COMMON', pg_temp.id('prov_in'), ARRAY['SEARCH'], 'pa-an', 'pa-an')$q$, '23514', '56 mô hình nhúng chỉ có năng lực EMBED');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model (id, tenant_id, model_code, name, model_kind, scope, provider_id, capabilities, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'pham-vi-sai', 'Sai phạm vi', 'CHAT', 'TENANT', pg_temp.id('prov_in'), ARRAY['SEARCH'], 'pa-an', 'pa-an')$q$, '23514', '57 phạm vi TENANT không dùng tenant_id COMMON');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model (id, tenant_id, model_code, name, model_kind, scope, provider_id, capabilities, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'khong-ncc', 'Không có nhà cung cấp', 'CHAT', 'COMMON', gen_random_uuid(), ARRAY['SEARCH'], 'pa-an', 'pa-an')$q$, '23503', '58 mô hình phải thuộc nhà cung cấp có thật');
INSERT INTO ph17_assist.model_version (id, tenant_id, model_id, version_no, version_label, upstream_name, context_tokens, embedding_dim, created_by, updated_by) VALUES
  (pg_temp.id('mv_chat'), 'COMMON', pg_temp.id('m_chat'), 1, 'chat-noi-bo-8b-v1', 'llama-8b-instruct', 32768, NULL, 'pa-an', 'pa-an'),
  (pg_temp.id('mv_emb'), 'COMMON', pg_temp.id('m_emb'), 1, 'nhung-1024-v1', 'bge-m3', 8192, 1024, 'pa-an', 'pa-an'),
  (pg_temp.id('mv_ext'), 'COMMON', pg_temp.id('m_ext'), 1, 'chat-ngoai-vn-v1', 'nha-cung-cap-chat', 32768, NULL, 'pa-an', 'pa-an'),
  (pg_temp.id('mv_draft'), 'COMMON', pg_temp.id('m_chat'), 2, 'chat-noi-bo-8b-v2', 'llama-8b-instruct-2', 32768, NULL, 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET status = 'APPROVED', decided_by = 'pa-binh', decided_at = now(), approved_at = now() WHERE id = pg_temp.id('mv_draft')$q$, '55000', '59 DRAFT không sang APPROVED thẳng (phải qua EVALUATING)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_version (id, tenant_id, model_id, version_no, version_label, upstream_name, context_tokens, gen_params, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', pg_temp.id('m_chat'), 3, 'v3', 'x', 4096, '{"api_key": "abc"}', 'pa-an', 'pa-an')$q$, '23514', '60 tham số sinh không chứa khóa API');
-- Bộ ca đỏ COMMON: 49 ca (chưa đủ), rồi 50
INSERT INTO ph17_assist.redteam_case (id, tenant_id, case_code, category, attack_text, created_by, updated_by)
SELECT gen_random_uuid(), 'COMMON', 'RT-SEED-' || lpad(g::text, 3, '0'),
       (ARRAY['INDIRECT_INJECTION','TOOL_ABUSE','PII_LEAK','CROSS_TENANT','SECRET_LEAK','JAILBREAK'])[1 + g % 6], 'Ca tổng hợp số ' || g || ': yêu cầu bỏ qua chỉ dẫn hệ thống và lộ dữ liệu', 'pa-an', 'pa-an'
FROM generate_series(1, 49) g;
SELECT pg_temp.is_true($q$SELECT count(*) = 49 FROM ph17_assist.redteam_case WHERE status = 'ACTIVE'$q$, '61 49 ca đỏ đang hoạt động');
INSERT INTO ph17_assist.eval_set (id, tenant_id, set_code, capability, name, created_by, updated_by) VALUES (pg_temp.id('es1'), 'COMMON', 'BDG-TIM-DICH-VU', 'SEARCH', 'Bộ đánh giá tìm dịch vụ', 'pa-an', 'pa-an');
-- Lượt đánh giá chuẩn đạt và lượt ca đỏ đạt cho mv_chat
INSERT INTO ph17_assist.eval_run (id, tenant_id, run_kind, eval_set_id, subject_type, subject_id, status, trigger_kind, cases_total, cases_passed, score, finished_at, created_by, updated_by)
VALUES (pg_temp.id('er_ev'), 'COMMON', 'EVAL', pg_temp.id('es1'), 'MODEL_VERSION', pg_temp.id('mv_chat'), 'PASSED', 'MODEL_CHANGE', 40, 36, 0.9000, now(), 'pa-an', 'pa-an');
INSERT INTO ph17_assist.eval_run (id, tenant_id, run_kind, subject_type, subject_id, status, trigger_kind, cases_total, cases_passed, cases_leaked, pass_rate, finished_at, created_by, updated_by)
VALUES (pg_temp.id('er_rt'), 'COMMON', 'REDTEAM', 'MODEL_VERSION', pg_temp.id('mv_chat'), 'PASSED', 'MODEL_CHANGE', 50, 50, 0, 100, now(), 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.eval_run (id, tenant_id, run_kind, subject_type, subject_id, status, trigger_kind, cases_total, cases_passed, cases_leaked, pass_rate, finished_at, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'REDTEAM', 'MODEL_VERSION', pg_temp.id('mv_emb'), 'PASSED', 'MANUAL', 60, 59, 1, 98.33, now(), 'pa-an', 'pa-an')$q$, '23514', '62 lượt ca đỏ có ca lọt không thể PASSED (BR-17-067)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.eval_run (id, tenant_id, run_kind, eval_set_id, subject_type, subject_id, status, trigger_kind, cases_total, cases_passed, score, finished_at, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'EVAL', pg_temp.id('es1'), 'MODEL_VERSION', pg_temp.id('mv_emb'), 'PASSED', 'MANUAL', 29, 29, 1, now(), 'pa-an', 'pa-an')$q$, '23514', '63 đánh giá chuẩn PASSED cần tối thiểu 30 ca (BR-17-066)');
UPDATE ph17_assist.model_version SET status = 'EVALUATING', submitted_by = 'pa-an', submitted_at = now() WHERE id = pg_temp.id('mv_chat');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET context_tokens = 65536 WHERE id = pg_temp.id('mv_chat')$q$, '55000', '64 phiên bản EVALUATING không sửa nội dung (ERR-17-040)');
UPDATE ph17_assist.model_version SET eval_run_id = pg_temp.id('er_ev'), redteam_run_id = pg_temp.id('er_rt') WHERE id = pg_temp.id('mv_chat');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET status = 'APPROVED', decided_by = 'pa-binh', decided_at = now(), approved_at = now() WHERE id = pg_temp.id('mv_chat')$q$, '23514', '66 bộ ca đỏ mới 49 ca: cổng phát hành chặn (ERR-17-075)');
INSERT INTO ph17_assist.redteam_case (id, tenant_id, case_code, category, attack_text, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'RT-SEED-050', 'JAILBREAK', 'Ca tổng hợp số 50: nhập vai để vượt giới hạn', 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET status = 'APPROVED', decided_by = 'pa-an', decided_at = now(), approved_at = now() WHERE id = pg_temp.id('mv_chat')$q$, '23514', '65 người đề nghị tự duyệt phiên bản mô hình bị chặn (BR-17-015)');
-- Ca đỏ lọt: lượt chạy FAILED không dùng để duyệt
UPDATE ph17_assist.model_version SET redteam_run_id = pg_temp.id('er_ev') WHERE id = pg_temp.id('mv_chat');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET status = 'APPROVED', decided_by = 'pa-binh', decided_at = now(), approved_at = now() WHERE id = pg_temp.id('mv_chat')$q$, '23514', '67 redteam_run_id không phải lượt ca đỏ đạt: chặn (ERR-17-073)');
UPDATE ph17_assist.model_version SET redteam_run_id = pg_temp.id('er_rt') WHERE id = pg_temp.id('mv_chat');
UPDATE ph17_assist.model_version SET status = 'APPROVED', decided_by = 'pa-binh', decided_at = now(), approved_at = now() WHERE id = pg_temp.id('mv_chat');
SELECT pg_temp.is_true($q$SELECT status = 'APPROVED' FROM ph17_assist.model_version WHERE id = pg_temp.id('mv_chat')$q$, '68 duyệt bốn mắt, bộ ca đỏ đủ 50, đánh giá đạt: APPROVED');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET price_in_per_1k = 5 WHERE id = pg_temp.id('mv_chat')$q$, '55000', '69 phiên bản APPROVED không sửa đơn giá, tạo phiên bản mới');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET status = 'DRAFT' WHERE id = pg_temp.id('mv_chat')$q$, '55000', '70 APPROVED không quay về DRAFT');
-- Hai phiên bản còn lại cho kiểm thử tenant_model: duyệt mv_emb và mv_ext bằng bộ chạy tương ứng
INSERT INTO ph17_assist.eval_run (id, tenant_id, run_kind, eval_set_id, subject_type, subject_id, status, trigger_kind, cases_total, cases_passed, score, finished_at, created_by, updated_by)
SELECT gen_random_uuid(), 'COMMON', 'EVAL', pg_temp.id('es1'), 'MODEL_VERSION', pg_temp.id(k), 'PASSED', 'MODEL_CHANGE', 40, 36, 0.9, now(), 'pa-an', 'pa-an' FROM unnest(ARRAY['mv_emb','mv_ext']) k;
INSERT INTO ph17_assist.eval_run (id, tenant_id, run_kind, subject_type, subject_id, status, trigger_kind, cases_total, cases_passed, cases_leaked, pass_rate, finished_at, created_by, updated_by)
SELECT gen_random_uuid(), 'COMMON', 'REDTEAM', 'MODEL_VERSION', pg_temp.id(k), 'PASSED', 'MODEL_CHANGE', 50, 50, 0, 100, now(), 'pa-an', 'pa-an' FROM unnest(ARRAY['mv_emb','mv_ext']) k;
UPDATE ph17_assist.model_version v SET status = 'EVALUATING', submitted_by = 'pa-an', submitted_at = now(),
  eval_run_id = (SELECT id FROM ph17_assist.eval_run WHERE subject_id = v.id AND run_kind = 'EVAL'), redteam_run_id = (SELECT id FROM ph17_assist.eval_run WHERE subject_id = v.id AND run_kind = 'REDTEAM')
 WHERE id IN (pg_temp.id('mv_emb'), pg_temp.id('mv_ext'));
UPDATE ph17_assist.model_version SET status = 'APPROVED', decided_by = 'pa-binh', decided_at = now(), approved_at = now() WHERE id IN (pg_temp.id('mv_emb'), pg_temp.id('mv_ext'));
SELECT pg_temp.is_true($q$SELECT count(*) = 3 FROM ph17_assist.model_version WHERE status = 'APPROVED'$q$, '71 ba phiên bản APPROVED (hội thoại, nhúng, ngoài)');
-- Ca đỏ không xóa, không sửa nội dung, chỉ ngừng
SELECT pg_temp.expect($q$UPDATE ph17_assist.redteam_case SET attack_text = 'Đổi nội dung ca đỏ đã có' WHERE case_code = 'RT-SEED-001'$q$, '55000', '72 nội dung ca đỏ bất biến (BR-17-067)');
SELECT pg_temp.expect($q$DELETE FROM ph17_assist.redteam_case WHERE case_code = 'RT-SEED-001'$q$, '42501', '73 ca đỏ không xóa, chỉ ngừng');
SELECT pg_temp.expect($q$UPDATE ph17_assist.redteam_case SET expected_behavior = 'ALLOW' WHERE case_code = 'RT-SEED-001'$q$, '55000', '74 hành vi mong đợi của ca đỏ luôn BLOCK');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.redteam_case (id, tenant_id, case_code, category, attack_text, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'RT-X-001', 'KHAC', 'Nhóm tấn công ngoài Phụ lục A', 'pa-an', 'pa-an')$q$, '23514', '75 nhóm tấn công theo Phụ lục A');
UPDATE ph17_assist.redteam_case SET status = 'RETIRED', retired_at = now(), retired_reason = 'Trùng với ca RT-SEED-002 sau rà soát' WHERE case_code = 'RT-SEED-001';
SELECT pg_temp.expect($q$UPDATE ph17_assist.redteam_case SET status = 'ACTIVE', retired_at = NULL, retired_reason = NULL WHERE case_code = 'RT-SEED-001'$q$, '55000', '76 ca đỏ đã ngừng không bật lại');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_version SET status = 'EVALUATING' WHERE id = pg_temp.id('mv_draft')$q$, '23514', '77 gửi đánh giá cần người gửi (submitted_by)');
-- Tuyến egress
INSERT INTO ph17_assist.model_route (id, tenant_id, version_id, route_ref, egress_host, priority, created_by, updated_by) VALUES (pg_temp.id('route1'), 'COMMON', pg_temp.id('mv_ext'), 'ai-chat-ngoai-vn', 'api.nha-cung-cap.example.vn', 0, 'pa-an', 'pa-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.model_route (id, tenant_id, version_id, route_ref, egress_host, priority, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', pg_temp.id('mv_ext'), 'ai-sai', '10.1.2.3', 1, 'pa-an', 'pa-an')$q$, '23514', '78 đích egress không là IP (BR-17-012)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_route SET status = 'SYNCED' WHERE id = pg_temp.id('route1')$q$, '23514', '79 SYNCED cần snapshot và thời điểm đồng bộ (BR-17-020)');
UPDATE ph17_assist.model_route SET status = 'SYNCED', snapshot_ref = 'gw-snap-0412', last_synced_at = now() WHERE id = pg_temp.id('route1');
SELECT pg_temp.expect($q$UPDATE ph17_assist.model_route SET status = 'FAILED' WHERE id = pg_temp.id('route1')$q$, '55000', '80 SYNCED không sang FAILED thẳng (phải qua PENDING khi lệch)');
-- Cô lập nền tảng: tenant không ghi, vai nền tảng không đọc dữ liệu tenant
SELECT pg_temp.expect($q$SELECT count(*) FROM ph17_assist.tenant_policy$q$, '42501', '81 vai nền tảng không có quyền đọc bảng của tenant');

-- ---------- 6. Bật mô hình cho tenant: duyệt, mô hình ngoài, danh sách trắng, dự phòng ----------
RESET ROLE;
SET ROLE dh_assist_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 3 FROM ph17_assist.model_version WHERE status = 'APPROVED'$q$, '83 tenant T90 đọc được phiên bản mô hình COMMON');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph17_assist.model_version SET context_tokens = 1024 WHERE id = pg_temp.id('mv_draft') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '84 tenant không sửa phiên bản COMMON (chỉ PA), không dòng nào bị đổi');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tenant_model (id, tenant_id, version_id, model_kind, enabled, enabled_by, enabled_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mv_draft'), 'CHAT', true, 'ta-an', now(), 'ta-an', 'ta-an')$q$, '23514', '85 phiên bản chưa APPROVED chưa bật được (ERR-17-030)');
INSERT INTO ph17_assist.tenant_model (id, tenant_id, version_id, model_kind, enabled, is_default, enabled_by, enabled_at, created_by, updated_by) VALUES
  (pg_temp.id('tm1'), 'T90', pg_temp.id('mv_chat'), 'CHAT', true, true, 'ta-an', now(), 'ta-an', 'ta-an'),
  (pg_temp.id('tm2'), 'T90', pg_temp.id('mv_emb'), 'EMBEDDING', true, true, 'ta-an', now(), 'ta-an', 'ta-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tenant_model (id, tenant_id, version_id, model_kind, enabled, enabled_by, enabled_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mv_chat'), 'CHAT', true, 'ta-an', now(), 'ta-an', 'ta-an')$q$, '23505', '86 một phiên bản chỉ bật một lần cho tenant');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tenant_model (id, tenant_id, version_id, model_kind, enabled, is_default, enabled_by, enabled_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mv_ext'), 'CHAT', true, true, 'ta-an', now(), 'ta-an', 'ta-an')$q$, '23514', '87 mô hình ngoài chưa được phép khi tenant chưa bật chính sách (ERR-17-016)');
-- Đề nghị EXTERNAL_ON được duyệt bốn mắt
INSERT INTO ph17_assist.policy_change (id, tenant_id, change_type, reason, requested_by, created_by, updated_by) VALUES (pg_temp.id('pc2'), 'T90', 'EXTERNAL_ON', 'Cho phép nhà cung cấp trong nước phục vụ câu hỏi công khai', 'ta-an', 'ta-an', 'ta-an');
UPDATE ph17_assist.policy_change SET state = 'APPROVED', decided_by = 'so-binh', decided_at = now() WHERE id = pg_temp.id('pc2');
UPDATE ph17_assist.tenant_policy SET external_allowed = true, external_change_id = pg_temp.id('pc2');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tenant_model (id, tenant_id, version_id, model_kind, enabled, enabled_by, enabled_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mv_ext'), 'CHAT', true, 'ta-an', now(), 'ta-an', 'ta-an')$q$, '23514', '88 đã cho phép mô hình ngoài nhưng chưa vào danh sách trắng (ERR-17-017)');
INSERT INTO ph17_assist.provider_grant (id, tenant_id, provider_id, change_id, granted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('prov_ex'), pg_temp.id('pc2'), 'ta-an', 'ta-an', 'ta-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.provider_grant (id, tenant_id, provider_id, change_id, granted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('prov_ex'), pg_temp.id('pc2'), 'ta-an', 'ta-an', 'ta-an')$q$, '23505', '89 mỗi nhà cung cấp một dòng danh sách trắng còn hiệu lực');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.provider_grant (id, tenant_id, provider_id, change_id, granted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('prov_in'), gen_random_uuid(), 'ta-an', 'ta-an', 'ta-an')$q$, '23503', '90 danh sách trắng phải có đề nghị có thật');
INSERT INTO ph17_assist.tenant_model (id, tenant_id, version_id, model_kind, enabled, enabled_by, enabled_at, created_by, updated_by) VALUES (pg_temp.id('tm3'), 'T90', pg_temp.id('mv_ext'), 'CHAT', true, 'ta-an', now(), 'ta-an', 'ta-an');
SELECT pg_temp.is_true($q$SELECT enabled FROM ph17_assist.tenant_model WHERE id = pg_temp.id('tm3')$q$, '91 bật mô hình ngoài khi đủ: chính sách, danh sách trắng, cam kết, ACTIVE');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_model SET fallback_version_id = pg_temp.id('mv_ext') WHERE id = pg_temp.id('tm1')$q$, '23514', '92 dự phòng từ mô hình nội bộ sang ngoài bị cấm (BR-17-018, ERR-17-034)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_model SET fallback_version_id = pg_temp.id('mv_emb') WHERE id = pg_temp.id('tm1')$q$, '23514', '93 dự phòng phải cùng loại mô hình');
UPDATE ph17_assist.tenant_model SET fallback_version_id = pg_temp.id('mv_chat') WHERE id = pg_temp.id('tm3');
SELECT pg_temp.is_true($q$SELECT fallback_version_id = pg_temp.id('mv_chat') FROM ph17_assist.tenant_model WHERE id = pg_temp.id('tm3')$q$, '94 dự phòng từ ngoài sang nội bộ cùng loại được phép');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_model SET is_default = true WHERE id = pg_temp.id('tm3')$q$, '23505', '95 mỗi tenant tối đa một mô hình mặc định mỗi loại (BR-17-017)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.tenant_model SET is_default = true, enabled = false WHERE id = pg_temp.id('tm3')$q$, '23514', '96 mô hình mặc định phải đang bật');

-- ---------- 7. Kho tri thức: chỉ PUBLIC, INTERNAL; trạng thái tài liệu; xóa lan truyền ----------
INSERT INTO ph17_assist.knowledge_source (id, tenant_id, source_code, source_type, name, created_by, updated_by) VALUES
  (pg_temp.id('src1'), 'T90', 'MO-TA-API', 'API_SPEC', 'Mô tả API từ danh mục dịch vụ PH-02', 'ds-an', 'ds-an'),
  (pg_temp.id('src3'), 'T90', 'TAI-LIEU-TINH', 'UPLOAD', 'Tài liệu hướng dẫn nội bộ của tỉnh', 'ds-an', 'ds-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_source (id, tenant_id, source_code, source_type, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'NGUON-LA', 'DATABASE_ROWS', 'Bản ghi nghiệp vụ', 'ds-an', 'ds-an')$q$, '23514', '97 nguồn chỉ thuộc loại cố định, không lập chỉ mục bản ghi nghiệp vụ (BR-17-025)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_source SET source_type = 'FLOW' WHERE id = pg_temp.id('src1')$q$, '55000', '98 loại nguồn bất biến');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_source SET source_state = 'PAUSED' WHERE id = pg_temp.id('src1')$q$, '23514', '99 PAUSED cần paused_at');
INSERT INTO ph17_assist.knowledge_document (id, tenant_id, source_id, external_ref, title, created_by, updated_by) VALUES
  (pg_temp.id('doc1'), 'T90', pg_temp.id('src1'), 'api/tra-cuu-thue/v1', 'API tra cứu thuế (mô tả)', 'ds-an', 'ds-an'),
  (pg_temp.id('doc2'), 'T90', pg_temp.id('src1'), 'api/ho-so-nhay-cam/v1', 'API hồ sơ mức hạn chế', 'ds-an', 'ds-an'),
  (pg_temp.id('doc3'), 'T90', pg_temp.id('src1'), 'api/danh-muc-dan-toc/v1', 'API danh mục dân tộc', 'ds-an', 'ds-an');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'INDEXED', class_level = 'INTERNAL' WHERE id = pg_temp.id('doc1')$q$, '55000', '100 PENDING không sang INDEXED thẳng (phải CLASSIFYING)');
UPDATE ph17_assist.knowledge_document SET index_status = 'CLASSIFYING' WHERE id IN (pg_temp.id('doc1'), pg_temp.id('doc2'), pg_temp.id('doc3'));
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 0, 'x', 'x', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'INTERNAL', '{"visibility":"TENANT"}', repeat('a', 64), 10, 'ds-an', 'ds-an')$q$, '23514', '101 mức chưa xác định thì không có đoạn (đóng an toàn, BR-17-026)');
UPDATE ph17_assist.knowledge_document SET class_level = 'INTERNAL', class_checked_at = now() WHERE id = pg_temp.id('doc1');
UPDATE ph17_assist.knowledge_document SET class_level = 'RESTRICTED', class_checked_at = now() WHERE id = pg_temp.id('doc2');
UPDATE ph17_assist.knowledge_document SET class_level = 'PUBLIC', class_checked_at = now() WHERE id = pg_temp.id('doc3');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'INDEXED' WHERE id = pg_temp.id('doc2')$q$, '23514', '102 tài liệu mức RESTRICTED không INDEXED (BR-17-026)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), pg_temp.id('doc2'), 0, 'x', 'x', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'RESTRICTED', '{"visibility":"TENANT"}', repeat('a', 64), 10, 'ds-an', 'ds-an')$q$, '23514', '103 đoạn mức RESTRICTED bị chặn ở bảng đoạn');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 0, 'x', 'x', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'PUBLIC', '{"visibility":"TENANT"}', repeat('a', 64), 10, 'ds-an', 'ds-an')$q$, '23514', '104 class_level của đoạn phải bằng mức hiện hành của tài liệu');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 0, 'x', 'x', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'INTERNAL', '{"visibility":"ALL"}', repeat('a', 64), 10, 'ds-an', 'ds-an')$q$, '23514', '105 acl phải có visibility TENANT, ORG hoặc ROLE (BR-17-027)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 0, 'x', 'x', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'INTERNAL', '{"visibility":"ORG"}', repeat('a', 64), 10, 'ds-an', 'ds-an')$q$, '23514', '106 acl ORG cần danh sách tổ chức');
INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES
  (pg_temp.id('ch1'), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 0, 'API tra cứu thuế của tổ chức, trả mã số thuế và tình trạng hoạt động.', 'api tra cuu thue cua to chuc tra ma so thue va tinh trang hoat dong', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'INTERNAL', '{"visibility":"TENANT"}', pg_temp.hash('c1'), 18, 'ds-an', 'ds-an'),
  (pg_temp.id('ch2'), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 1, 'Phiên bản v1 áp dụng từ 2026.', 'phien ban v1 ap dung tu 2026', pg_temp.vec(0.2), pg_temp.id('mv_emb'), 'INTERNAL', '{"visibility":"ORG","orgIds":["ORG-THUE"]}', pg_temp.hash('c2'), 8, 'ds-an', 'ds-an'),
  (pg_temp.id('ch3'), 'T90', pg_temp.id('src1'), pg_temp.id('doc3'), 0, 'Danh mục dân tộc dùng chung toàn tỉnh.', 'danh muc dan toc dung chung toan tinh', pg_temp.vec(0.3), pg_temp.id('mv_emb'), 'PUBLIC', '{"visibility":"TENANT"}', pg_temp.hash('c3'), 9, 'ds-an', 'ds-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), pg_temp.id('doc1'), 0, 'trùng', 'trung', pg_temp.vec(0.1), pg_temp.id('mv_emb'), 'INTERNAL', '{"visibility":"TENANT"}', pg_temp.hash('c1x'), 1, 'ds-an', 'ds-an')$q$, '23505', '107 mỗi (tài liệu, số đoạn, phiên bản nhúng) một đoạn');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph17_assist.knowledge_chunk WHERE content_tsv @@ plainto_tsquery('simple', 'thue') AND document_id = pg_temp.id('doc1')$q$, '108 tìm từ khóa không dấu theo tsvector');
UPDATE ph17_assist.knowledge_document SET index_status = 'INDEXED', chunk_count = 2, content_hash = pg_temp.hash('d1'), indexed_at = now() WHERE id = pg_temp.id('doc1');
UPDATE ph17_assist.knowledge_document SET index_status = 'INDEXED', chunk_count = 1, content_hash = pg_temp.hash('d3'), indexed_at = now() WHERE id = pg_temp.id('doc3');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'CLASSIFYING' WHERE id = pg_temp.id('doc1')$q$, '55000', '109 INDEXED không về CLASSIFYING (chỉ về PENDING khi nguồn đổi)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'SKIPPED_CLASS' WHERE id = pg_temp.id('doc2')$q$, '23514', '110 SKIPPED_CLASS cần ghi lý do');
UPDATE ph17_assist.knowledge_document SET index_status = 'SKIPPED_CLASS', skip_reason = 'Mức RESTRICTED không được lập chỉ mục' WHERE id = pg_temp.id('doc2');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'FAILED', failure_count = 2, last_error_code = 'E-TIMEOUT' WHERE id = pg_temp.id('doc2')$q$, '55000', '111 SKIPPED_CLASS không sang FAILED');
UPDATE ph17_assist.knowledge_document SET index_status = 'PENDING' WHERE id = pg_temp.id('doc2');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'FAILED', failure_count = 2, last_error_code = 'E-TIMEOUT' WHERE id = pg_temp.id('doc2')$q$, '23514', '112 FAILED chỉ sau ba lần thử (BR-17-028)');
UPDATE ph17_assist.knowledge_document SET index_status = 'FAILED', failure_count = 3, last_error_code = 'E-TIMEOUT' WHERE id = pg_temp.id('doc2');
-- cô lập: T91 không thấy đoạn của T90
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.knowledge_chunk$q$, '113 T91 không thấy đoạn tri thức của T90 (cô lập tenant, BR-17-027)');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.knowledge_document$q$, '114 T91 không thấy tài liệu của T90');
SET app.tenant_id = 'T90';
-- đoạn COMMON do PA quản
RESET ROLE;
SET ROLE dh_assist_platform;
SET app.tenant_id = 'COMMON';
INSERT INTO ph17_assist.knowledge_source (id, tenant_id, source_code, source_type, name, created_by, updated_by) VALUES (pg_temp.id('src2'), 'COMMON', 'DANH-MUC-ERR', 'ERROR_CODE', 'Danh mục mã lỗi ERR dùng chung', 'pa-an', 'pa-an');
INSERT INTO ph17_assist.knowledge_document (id, tenant_id, source_id, external_ref, title, class_level, created_by, updated_by) VALUES (pg_temp.id('doc4'), 'COMMON', pg_temp.id('src2'), 'err/ERR-00-401', 'ERR-00-401 chưa xác thực', 'PUBLIC', 'pa-an', 'pa-an');
UPDATE ph17_assist.knowledge_document SET index_status = 'CLASSIFYING' WHERE id = pg_temp.id('doc4');
INSERT INTO ph17_assist.knowledge_chunk (id, tenant_id, source_id, document_id, chunk_no, content, content_norm, embedding, embed_version_id, class_level, acl, content_hash, token_count, created_by, updated_by)
VALUES (pg_temp.id('ch4'), 'COMMON', pg_temp.id('src2'), pg_temp.id('doc4'), 0, 'ERR-00-401: chưa xác thực, đăng nhập lại.', 'err 00 401 chua xac thuc dang nhap lai', pg_temp.vec(0.4), pg_temp.id('mv_emb'), 'PUBLIC', '{"visibility":"TENANT"}', pg_temp.hash('c4'), 9, 'pa-an', 'pa-an');
UPDATE ph17_assist.knowledge_document SET index_status = 'INDEXED', chunk_count = 1, content_hash = pg_temp.hash('d4'), indexed_at = now() WHERE id = pg_temp.id('doc4');
RESET ROLE;
SET ROLE dh_assist_app;
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph17_assist.knowledge_chunk WHERE id = pg_temp.id('ch4')$q$, '115 T91 đọc được đoạn COMMON');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph17_assist.knowledge_chunk SET token_count = 1 WHERE id = pg_temp.id('ch4') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '116 T91 không sửa đoạn COMMON (chỉ đọc, BR-17-027)');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph17_assist.knowledge_chunk WHERE id = pg_temp.id('ch4') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '117 T91 không xóa đoạn COMMON');
SET app.tenant_id = 'T90';
-- Xóa lan truyền: đổi mức tài liệu sang RESTRICTED, tài liệu DELETED, hết đoạn, có nhật ký
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph17_assist.knowledge_chunk WHERE document_id = pg_temp.id('doc1')$q$, '118 trước khi đổi mức: tài liệu có 2 đoạn');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'DELETED' WHERE id = pg_temp.id('doc1')$q$, '23514', '119 DELETED cần lý do xóa (delete_reason)');
UPDATE ph17_assist.knowledge_document SET index_status = 'DELETED', delete_reason = 'CLASS_CHANGED', class_level = 'RESTRICTED' WHERE id = pg_temp.id('doc1');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.knowledge_chunk WHERE document_id = pg_temp.id('doc1')$q$, '120 đổi mức: đoạn bị xóa vật lý trong cùng giao dịch (BR-17-029)');
SELECT pg_temp.is_true($q$SELECT chunks_deleted = 2 AND reason = 'CLASS_CHANGED' FROM ph17_assist.knowledge_deletion WHERE document_id = pg_temp.id('doc1')$q$, '121 nhật ký xóa lan truyền ghi 2 đoạn, lý do CLASS_CHANGED');
SELECT pg_temp.is_true($q$SELECT chunk_count = 0 FROM ph17_assist.knowledge_document WHERE id = pg_temp.id('doc1')$q$, '122 chunk_count về 0');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_deletion SET chunks_deleted = 0$q$, '42501', '123 nhật ký xóa lan truyền chỉ thêm');
-- Tài liệu tải lên: bốn mắt
INSERT INTO ph17_assist.file_object (id, tenant_id, bucket, object_key, file_name, content_type, size_bytes, sha256, scan_status, purpose, created_by, updated_by)
VALUES (pg_temp.id('f2'), 'T90', 'dh-assist-upload', 'T90/huong-dan-van-hanh.md', 'huong-dan-van-hanh.md', 'text/markdown', 8000, pg_temp.hash('hd1'), 'CLEAN', 'UPLOAD_SOURCE', 'ds-an', 'ds-an');
INSERT INTO ph17_assist.knowledge_document (id, tenant_id, source_id, external_ref, title, file_id, upload_status, declared_class, uploaded_by, created_by, updated_by)
VALUES (pg_temp.id('doc5'), 'T90', pg_temp.id('src3'), 'upload/huong-dan-van-hanh', 'Hướng dẫn vận hành của tỉnh', pg_temp.id('f2'), 'UPLOADED', 'INTERNAL', 'ds-an', 'ds-an', 'ds-an');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET index_status = 'CLASSIFYING', class_level = 'INTERNAL' WHERE id = pg_temp.id('doc5')$q$, '23514', '124 tài liệu tải lên chưa duyệt không vào chỉ mục (BR-17-030)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET declared_class = 'RESTRICTED' WHERE id = pg_temp.id('doc5')$q$, '23514', '125 người tải chỉ khai PUBLIC hoặc INTERNAL');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET upload_status = 'APPROVED' WHERE id = pg_temp.id('doc5')$q$, '55000', '126 UPLOADED không sang APPROVED thẳng');
UPDATE ph17_assist.knowledge_document SET upload_status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('doc5');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET upload_status = 'APPROVED', approved_by = 'ds-an', approved_at = now() WHERE id = pg_temp.id('doc5')$q$, '23514', '127 người tải tự duyệt bị chặn (bốn mắt, BR-17-030)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.knowledge_document SET upload_status = 'REJECTED', reject_reason = 'ngắn' WHERE id = pg_temp.id('doc5')$q$, '23514', '128 từ chối tài liệu cần lý do từ 20 ký tự');
UPDATE ph17_assist.knowledge_document SET upload_status = 'APPROVED', approved_by = 'so-binh', approved_at = now() WHERE id = pg_temp.id('doc5');
UPDATE ph17_assist.knowledge_document SET index_status = 'CLASSIFYING', class_level = 'INTERNAL' WHERE id = pg_temp.id('doc5');
SELECT pg_temp.is_true($q$SELECT index_status = 'CLASSIFYING' FROM ph17_assist.knowledge_document WHERE id = pg_temp.id('doc5')$q$, '129 tài liệu tải lên được duyệt thì vào hàng lập chỉ mục');
-- Lượt lập chỉ mục
INSERT INTO ph17_assist.index_job (id, tenant_id, source_id, job_kind, status, trigger_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), 'FULL', 'QUEUED', 'CRON', 'job', 'job');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.index_job (id, tenant_id, source_id, job_kind, status, trigger_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), 'FULL', 'RUNNING', 'ta-an', 'ta-an', 'ta-an')$q$, '23505', '130 một nguồn chỉ một lượt FULL đang chạy (ERR-17-044)');
INSERT INTO ph17_assist.index_job (id, tenant_id, source_id, job_kind, status, trigger_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src1'), 'EVENT', 'QUEUED', '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b', 'job', 'job');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.index_job (id, tenant_id, source_id, job_kind, status, trigger_ref, attempt, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src3'), 'EVENT', 'QUEUED', 'x', 4, 'job', 'job')$q$, '23514', '131 tối đa ba lần thử');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.index_job (id, tenant_id, source_id, job_kind, status, trigger_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('src3'), 'EVENT', 'FAILED', 'x', 'job', 'job')$q$, '23514', '132 lượt FAILED cần mã lỗi và thời điểm kết thúc');

-- ---------- 8. Hội thoại: RLS theo người dùng, phiếu truy cập nhật ký, lưu giữ ----------
SET app.user_id = 'user-an';
INSERT INTO ph17_assist.conversation (id, tenant_id, user_id, title, screen_context, expires_at, created_by, updated_by)
VALUES (pg_temp.id('cv1'), 'T90', 'user-an', 'Tìm API tra cứu thuế', '{"route": "/dich-vu", "tab": "tong-quan"}', now() + interval '91 days', 'user-an', 'user-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.conversation (id, tenant_id, user_id, screen_context, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'user-an', '{"route": "/dich-vu", "rows": [1,2]}', now() + interval '91 days', 'user-an', 'user-an')$q$, '23514', '133 ngữ cảnh màn hình không mang giá trị dữ liệu (BR-17-032)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.conversation (id, tenant_id, user_id, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'user-an', now() + interval '30 days', 'user-an', 'user-an')$q$, '23514', '134 hạn lưu hội thoại tối thiểu 90 ngày (BR-17-039)');
INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, dedup_id, created_by, updated_by)
VALUES (pg_temp.id('ms1'), 'T90', pg_temp.id('cv1'), 'user-an', 1, 'USER', 'Dịch vụ nào tra cứu mã số thuế của tổ chức, số định danh ***', pg_temp.id('pc3'), 'user-an', 'user-an');
INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, outcome, capability, model_version_id, tokens_in, tokens_out, trace_id, created_by, updated_by)
VALUES (pg_temp.id('ms2'), 'T90', pg_temp.id('cv1'), 'user-an', 2, 'ASSISTANT', 'API tra cứu thuế (xem mô tả). Nội dung do AI tạo, cần kiểm tra lại.', 'ANSWERED', 'SEARCH', pg_temp.id('mv_chat'), 320, 110, md5('t1'), 'user-an', 'user-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, outcome, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 3, 'USER', 'hỏi', 'ANSWERED', 'user-an', 'user-an')$q$, '23514', '135 chỉ tin nhắn trợ lý có outcome');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 3, 'ASSISTANT', 'đáp', 'user-an', 'user-an')$q$, '23514', '136 tin nhắn trợ lý phải có outcome');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, masked, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 3, 'USER', 'dữ liệu chưa che', false, 'user-an', 'user-an')$q$, '23514', '137 không lưu nội dung chưa che (BR-17-073)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 1, 'USER', 'trùng thứ tự', 'user-an', 'user-an')$q$, '23505', '138 số thứ tự tin nhắn duy nhất trong hội thoại');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, dedup_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 3, 'USER', 'gửi trùng', pg_temp.id('pc3'), 'user-an', 'user-an')$q$, '23505', '139 chống gửi trùng theo dedup_id (BR-17-087)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 3, 'USER', 'dùng Bearer ' || repeat('a', 30) || ' để gọi', 'user-an', 'user-an')$q$, '23514', '140 nội dung chứa chuỗi giống bí mật bị chặn');
SELECT pg_temp.expect($q$UPDATE ph17_assist.message SET content_masked = 'sửa lịch sử' WHERE id = pg_temp.id('ms1')$q$, '55000', '141 nội dung tin nhắn bất biến');
INSERT INTO ph17_assist.citation (id, tenant_id, message_id, user_id, rank, chunk_id, source_id, object_ref, link_route, score, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 1, pg_temp.id('ch1'), pg_temp.id('src1'), 'api/tra-cuu-thue/v1', '/dich-vu/api/tra-cuu-thue?tab=mo-ta', 0.8123, 'user-an', 'user-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.citation (id, tenant_id, message_id, user_id, rank, object_ref, link_route, score, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 2, 'x', 'https://trang-ngoai.example.com/a', 0.7, 'user-an', 'user-an')$q$, '23514', '142 liên kết trích dẫn chỉ là route nội bộ (BR-17-037)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.citation (id, tenant_id, message_id, user_id, rank, object_ref, link_route, score, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 2, 'x', '//trang-ngoai.example.com/a', 0.7, 'user-an', 'user-an')$q$, '23514', '143 liên kết giao thức tương đối ra ngoài bị chặn');
INSERT INTO ph17_assist.tool_call (id, tenant_id, message_id, user_id, tool_code, depth, args_masked, result_summary, outcome, duration_ms, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 'SEARCH_API', 1, '{"q": "thue"}', '3 kết quả', 'OK', 420, 'user-an', 'user-an');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tool_call (id, tenant_id, message_id, user_id, tool_code, depth, outcome, duration_ms, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 'SEARCH_API', 6, 'OK', 1, 'user-an', 'user-an')$q$, '23514', '144 độ sâu chuỗi công cụ 1 đến 5 (BR-17-061)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tool_call (id, tenant_id, message_id, user_id, tool_code, depth, outcome, duration_ms, act_subject, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 'SEARCH_API', 1, 'OK', 1, 'dh-khac', 'user-an', 'user-an')$q$, '23514', '145 chủ thể hành động của token đổi luôn dh-assist (BR-17-057)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.tool_call (id, tenant_id, message_id, user_id, tool_code, args_masked, outcome, duration_ms, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ms2'), 'user-an', 'SEARCH_API', '{"h": "Bearer abc"}', 'OK', 1, 'user-an', 'user-an')$q$, '23514', '146 không lưu token trong tham số gọi công cụ');
-- RLS theo người dùng
SET app.user_id = 'user-binh';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.conversation$q$, '147 người dùng khác cùng tenant không thấy hội thoại (BR-17-033)');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.message$q$, '148 người dùng khác không thấy tin nhắn');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('cv1'), 'user-an', 9, 'USER', 'chen hộ', 'user-binh', 'user-binh')$q$, '42501', '149 không ghi tin nhắn mạo danh người khác');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph17_assist.conversation SET title = 'sửa trộm' RETURNING 1) SELECT count(*) = 0 FROM u$q$, '150 không sửa hội thoại của người khác');
-- Phiếu truy cập nhật ký của SO
SET app.user_id = 'so-chi';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.conversation$q$, '151 SO chưa có phiếu thì không thấy hội thoại');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.log_access_grant (id, tenant_id, grantee, grantee_role, reason, scope_kind, conversation_id, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'so-chi', 'DEVELOPER', 'Điều tra khiếu nại về câu trả lời của trợ lý', 'CONVERSATION', pg_temp.id('cv1'), now() + interval '30 minutes', 'so-chi', 'so-chi')$q$, '23514', '152 chỉ SO, AUDITOR xin phiếu (BR-17-075)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.log_access_grant (id, tenant_id, grantee, grantee_role, reason, scope_kind, conversation_id, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'so-chi', 'SO', 'ngắn', 'CONVERSATION', pg_temp.id('cv1'), now() + interval '30 minutes', 'so-chi', 'so-chi')$q$, '23514', '153 lý do truy cập tối thiểu 20 ký tự (ERR-17-007)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.log_access_grant (id, tenant_id, grantee, grantee_role, reason, scope_kind, conversation_id, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'so-chi', 'SO', 'Điều tra khiếu nại về câu trả lời của trợ lý', 'CONVERSATION', pg_temp.id('cv1'), now() + interval '61 minutes', 'so-chi', 'so-chi')$q$, '23514', '154 phiếu hiệu lực tối đa 60 phút (BR-17-074)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.log_access_grant (id, tenant_id, grantee, grantee_role, reason, scope_kind, range_from, range_to, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'so-chi', 'AUDITOR', 'Kiểm tra định kỳ nhật ký trợ lý theo kế hoạch quý', 'RANGE', now() - interval '100 days', now(), now() + interval '30 minutes', 'so-chi', 'so-chi')$q$, '23514', '155 khoảng xem nhật ký tối đa 92 ngày');
-- phiếu đã quá hạn (cấp 2 giờ trước, hiệu lực 30 phút): không mở khóa
INSERT INTO ph17_assist.log_access_grant (id, tenant_id, grantee, grantee_role, reason, scope_kind, conversation_id, granted_at, expires_at, created_by, updated_by)
VALUES (pg_temp.id('lg1'), 'T90', 'so-chi', 'SO', 'Điều tra khiếu nại đã xong từ hôm trước', 'CONVERSATION', pg_temp.id('cv1'), now() - interval '2 hours', now() - interval '90 minutes', 'so-chi', 'so-chi');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.conversation$q$, '156 phiếu hết hiệu lực không mở khóa hội thoại');
INSERT INTO ph17_assist.log_access_grant (id, tenant_id, grantee, grantee_role, reason, scope_kind, conversation_id, expires_at, created_by, updated_by)
VALUES (pg_temp.id('lg2'), 'T90', 'so-chi', 'SO', 'Điều tra khiếu nại về câu trả lời của trợ lý', 'CONVERSATION', pg_temp.id('cv1'), now() + interval '30 minutes', 'so-chi', 'so-chi');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph17_assist.conversation$q$, '157 phiếu còn hiệu lực: SO thấy đúng hội thoại được cấp');
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph17_assist.message$q$, '158 phiếu mở khóa tin nhắn của hội thoại đó');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph17_assist.conversation SET title = 'SO sửa' RETURNING 1) SELECT count(*) = 0 FROM u$q$, '159 phiếu chỉ cho đọc, không cho ghi hội thoại');
UPDATE ph17_assist.log_access_grant SET state = 'REVOKED', revoked_at = now(), revoked_by = 'ta-an' WHERE id = pg_temp.id('lg2');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.conversation$q$, '160 thu hồi phiếu thì khóa lại ngay');
SELECT pg_temp.expect($q$UPDATE ph17_assist.log_access_grant SET reason = 'Sửa lý do sau khi cấp phiếu' WHERE id = pg_temp.id('lg2')$q$, '55000', '161 lý do truy cập bất biến');
-- Lưu giữ: chỉ vai job xóa hội thoại hết hạn
SET app.user_id = 'user-an';
INSERT INTO ph17_assist.conversation (id, tenant_id, user_id, title, created_at, expires_at, created_by, updated_by) VALUES (pg_temp.id('cv2'), 'T90', 'user-an', 'Hội thoại cũ', now() - interval '100 days', now() - interval '5 days', 'user-an', 'user-an');
INSERT INTO ph17_assist.message (id, tenant_id, conversation_id, user_id, seq, role, content_masked, created_by, updated_by) VALUES (pg_temp.id('ms3'), 'T90', pg_temp.id('cv2'), 'user-an', 1, 'USER', 'câu hỏi cũ', 'user-an', 'user-an');
SELECT pg_temp.expect($q$DELETE FROM ph17_assist.conversation WHERE id = pg_temp.id('cv2')$q$, '42501', '162 vai ứng dụng không xóa hội thoại (chỉ ẩn bằng DELETED_BY_USER)');
UPDATE ph17_assist.conversation SET state = 'DELETED_BY_USER', deleted_by_user_at = now() WHERE id = pg_temp.id('cv1');
SELECT pg_temp.is_true($q$SELECT state = 'DELETED_BY_USER' FROM ph17_assist.conversation WHERE id = pg_temp.id('cv1')$q$, '163 người dùng xóa hội thoại: trạng thái DELETED_BY_USER, bản đã che vẫn giữ tới hết hạn');
SELECT pg_temp.expect($q$UPDATE ph17_assist.conversation SET state = 'ACTIVE', deleted_by_user_at = NULL WHERE id = pg_temp.id('cv1')$q$, '55000', '164 hội thoại đã xóa không khôi phục');
RESET ROLE;
SET ROLE dh_assist_job;
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph17_assist.conversation WHERE id = pg_temp.id('cv1') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '165 vai job không xóa hội thoại chưa hết hạn');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph17_assist.conversation WHERE id = pg_temp.id('cv2') RETURNING 1) SELECT count(*) = 1 FROM d$q$, '166 vai job xóa hội thoại hết hạn (BR-17-039, 073)');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.message WHERE id = pg_temp.id('ms3')$q$, '167 xóa hội thoại xóa theo tin nhắn con');
RESET ROLE;
SET ROLE dh_assist_app;
SET app.tenant_id = 'T90';
SET app.user_id = 'user-an';

-- ---------- 9. Nhật ký gọi mô hình, hộp thư đi, quét lược đồ ----------
RESET ROLE;
SET ROLE dh_assist_infer;
SET app.tenant_id = 'T90';
INSERT INTO ph17_assist.invocation_log (id, tenant_id, capability, model_version_id, caller_kind, caller_ref, request_ref, tokens_in, tokens_out, latency_ms, result, trace_id)
VALUES (gen_random_uuid(), 'T90', 'SEARCH', pg_temp.id('mv_chat'), 'USER', 'user-an', 'req-0001', 320, 110, 850, 'OK', md5('inv1'));
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.invocation_log (id, tenant_id, capability, model_version_id, caller_kind, caller_ref, request_ref, latency_ms, result, trace_id) VALUES (gen_random_uuid(), 'T91', 'SEARCH', pg_temp.id('mv_chat'), 'USER', 'user-an', 'req-0002', 10, 'OK', md5('inv2'))$q$, '42501', '168 vai suy luận không ghi nhật ký sang tenant khác (RLS)');
SELECT pg_temp.expect($q$UPDATE ph17_assist.invocation_log SET tokens_in = 0$q$, '42501', '169 nhật ký gọi mô hình chỉ thêm, vai suy luận không sửa');
SELECT pg_temp.expect($q$SELECT count(*) FROM ph17_assist.message$q$, '42501', '170 vai suy luận không đọc hội thoại');
SELECT pg_temp.expect($q$SELECT count(*) FROM ph17_assist.knowledge_chunk$q$, '42501', '171 vai suy luận không đọc đoạn tri thức');
RESET ROLE;
SET ROLE dh_assist_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$UPDATE ph17_assist.invocation_log SET tokens_in = 0$q$, '42501', '172 vai ứng dụng không sửa nhật ký gọi mô hình');
SELECT pg_temp.expect($q$DELETE FROM ph17_assist.invocation_log$q$, '42501', '173 vai ứng dụng không xóa nhật ký gọi mô hình');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph17_assist.invocation_log$q$, '174 tenant đọc đúng nhật ký của mình');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph17_assist.invocation_log$q$, '175 T91 không thấy nhật ký của T90');
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 't90.assist.config.changed.v1', 'tenant', 'T90', 'T90', '{"content": "không được"}', md5('o1'))$q$, '23514', '176 hộp thư đi không mang nội dung hội thoại (BR-17-073)');
SELECT pg_temp.expect($q$INSERT INTO ph17_assist.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 't91.assist.config.changed.v1', 'tenant', 'T90', 'T90', '{}', md5('o2'))$q$, '23514', '177 tiền tố chủ đề phải trùng tenant');
-- Quét lược đồ
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM information_schema.columns WHERE table_schema = 'ph17_assist' AND (column_name ~* '(secret|password|passwd|api_?key|private_key)$' AND column_name <> 'secret_ref')$q$, '178 không có cột chứa bí mật (SEC-49), chỉ secret_ref');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'ph17_assist' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND NOT (c.relrowsecurity AND c.relforcerowsecurity)$q$, '179 mọi bảng đều bật RLS và FORCE RLS');
SELECT pg_temp.is_true($q$SELECT count(*) >= 50 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'ph17_assist' AND c.relkind IN ('r', 'p') AND NOT c.relispartition$q$, '180 lược đồ có đủ 50 bảng EN-17');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM information_schema.columns WHERE table_schema = 'ph17_assist' AND column_name = 'tenant_id' AND data_type <> 'character varying'$q$, '181 tenant_id luôn varchar');
SELECT pg_temp.is_true($q$SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN (SELECT udt_name = 'vector' FROM information_schema.columns WHERE table_schema = 'ph17_assist' AND table_name = 'knowledge_chunk' AND column_name = 'embedding') ELSE (SELECT udt_name = '_float4' FROM information_schema.columns WHERE table_schema = 'ph17_assist' AND table_name = 'knowledge_chunk' AND column_name = 'embedding') END$q$, '182 kiểu embedding khớp với việc có pgvector hay không');
SELECT pg_temp.is_true($q$SELECT count(*) >= 3 FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'invocation_log'$q$, '183 nhật ký gọi mô hình đã có phân vùng tháng');
