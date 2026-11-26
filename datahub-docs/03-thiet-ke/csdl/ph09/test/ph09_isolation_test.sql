-- =============================================================================
-- D03-03-PH09 · Kiểm thử DDL ph09_privacy: cô lập tenant (RLS), phân loại và hạ mức bốn mắt, phiên bản bất biến,
-- chấp thuận theo bộ ba, chính sách che cần mô phỏng, phiếu xem đầy đủ 60 giây, khôi phục giá trị gốc hai cấp,
-- khóa giả danh hóa, k ≥ 10 và rủi ro, giữ pháp lý, xóa mật mã tenant, yêu cầu chủ thể, đồng ý, vi phạm 72 giờ,
-- bảng kiểm toán chỉ thêm, outbox không chứa giá trị, quyền vai trò, không lưu giá trị DLCN rõ, thủ tục nạp tenant.
-- Chạy sau ph09_privacy.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d ph09_test -f ph09_isolation_test.sql
-- pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại, 42501 quyền hoặc RLS,
-- 55000 bất biến) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- Tương ứng nhóm ca cô lập (NFR-09-019, BR-09-060) và BR-09-002, 005, 011, 013, 015, 023, 026, 032, 033, 035, 039, 041,
-- 042, 045, 050, 054, 055, 058 của D05-02-PH09.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_data_app') THEN CREATE ROLE dh_data_app LOGIN NOBYPASSRLS; END IF;
  GRANT ph09_app TO dh_data_app;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS; END IF;
  GRANT ph09_readonly TO dh_report_ro;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_decide_app') THEN CREATE ROLE dh_decide_app LOGIN NOBYPASSRLS; END IF;
  GRANT ph09_decide TO dh_decide_app;
END $$;
SET ROLE dh_data_app;

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
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['e1','e2','e3','cc1','ch1','act1','act2','pur1','pur2','ar1','ar2','pg1','mp1','mp2','ms1','pd1','pk1','ak1','aj1','rr1','ds1','rs1','sr1','sr2','ct1','cr1','dp1','bc1','lh1','sc1']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.h(text) RETURNS bytea LANGUAGE sql AS $$ SELECT sha256(convert_to($1, 'UTF8')) $$;
CREATE FUNCTION pg_temp.enc(text) RETURNS bytea LANGUAGE sql AS $$ SELECT '\x01'::bytea || sha256(convert_to($1, 'UTF8')) || sha256(convert_to($1 || 'x', 'UTF8')) $$;

-- ---------- 1. Nạp tenant bằng thủ tục ----------
SET app.tenant_id = 'T90';
CALL ph09_privacy.p_seed_tenant('T90');
SET app.tenant_id = 'T91';
CALL ph09_privacy.p_seed_tenant('T91');
SET app.tenant_id = 'T90';
CALL ph09_privacy.p_seed_tenant('T90');
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM ph09_privacy.data_class) = 4 AND (SELECT count(*) FROM ph09_privacy.personal_data_category) = 18
  AND (SELECT count(*) FROM ph09_privacy.detector_rule) = 7 AND (SELECT count(*) FROM ph09_privacy.legal_basis) = 7 AND (SELECT count(*) FROM ph09_privacy.mask_type) = 12
  AND (SELECT count(*) FROM ph09_privacy.tenant_setting) = 43 AND (SELECT count(*) FROM ph09_privacy.log_mask_config) = 1$q$, '01 nạp tenant: 4 mức, 18 loại, 7 mẫu, 7 cơ sở, 12 kiểu che, 43 tham số; chạy lại không nhân bản');
SELECT pg_temp.is_true($q$SELECT status = 'ACTIVE' AND (SELECT count(*) FROM ph09_privacy.retention_schedule_line) = 17 FROM ph09_privacy.retention_schedule WHERE schedule_code = 'PH09-OWN'$q$, '02 lịch lưu giữ PH09-OWN ACTIVE với 17 dòng');
SELECT pg_temp.is_true($q$SELECT value = '10'::jsonb AND floor_value = '3'::jsonb FROM ph09_privacy.tenant_setting WHERE setting_key = '09.request.sla-days'$q$, '03 tham số 09.request.sla-days = 10, sàn 3');

-- ---------- 2. Dữ liệu T90 ----------
INSERT INTO ph09_privacy.data_element (id, tenant_id, scope, target, owner_org_id, source, created_by, updated_by) VALUES
  (pg_temp.id('e1'), 'T90', 'INTERNAL_ENTITY', 'ph06_mdm.CITIZEN.nationalId', 'ORG-CA', 'MANUAL', 'ds-an', 'ds-an'),
  (pg_temp.id('e2'), 'T90', 'API_SCHEMA', '/components/schemas/Citizen/properties/fullName', 'ORG-CA', 'SCHEMA_IMPORT', 'ds-an', 'ds-an'),
  (pg_temp.id('e3'), 'T90', 'EVENT_SCHEMA', '/payload/healthStatus', 'ORG-YT', 'MVP_IMPORT', 'ds-an', 'ds-an');
INSERT INTO ph09_privacy.element_classification (id, tenant_id, element_id, data_class, personal_data_type, category_code, identifiability, status, source, confirmed_by, confirmed_at, created_by, updated_by) VALUES
  (pg_temp.id('cc1'), 'T90', pg_temp.id('e1'), 'RESTRICTED', 'BASIC', 'NATIONAL_ID', 'DIRECT', 'CONFIRMED', 'MANUAL', 'ta-binh', now(), 'ds-an', 'ds-an');
INSERT INTO ph09_privacy.legal_document (id, tenant_id, doc_type, number, title, issued_on, effective_from, cmp_law_code, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'LAW', '91/2025/QH15', 'Luật Bảo vệ dữ liệu cá nhân', '2025-06-26', '2026-01-01', 'CMP-LAW-05', 'so-chi', 'so-chi');
INSERT INTO ph09_privacy.purpose (id, tenant_id, code, name, legal_basis_code, allowed_categories, statutory, created_by, updated_by) VALUES
  (pg_temp.id('pur1'), 'T90', 'TTHC-HO-TICH', 'Thủ tục hộ tịch', 'STATE_TASK', ARRAY['FULL_NAME', 'NATIONAL_ID'], true, 'do-binh', 'do-binh'),
  (pg_temp.id('pur2'), 'T90', 'THONG-KE', 'Thống kê', 'STATISTICS_RESEARCH', ARRAY['ADDRESS'], false, 'do-binh', 'do-binh');
INSERT INTO ph09_privacy.purpose_element (id, tenant_id, purpose_id, element_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pur1'), pg_temp.id('e1'), 'do-binh', 'do-binh');
INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, status, submitted_at, created_by, updated_by)
VALUES (pg_temp.id('ar1'), 'T90', 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', ARRAY['fullName', 'nationalId'], 2000, 365, 'Tra cứu khi đăng ký khai sinh', 'ORG-CA', 'SUBMITTED', now(), 'httt-an', 'httt-an');
UPDATE ph09_privacy.access_request SET status = 'APPROVED', decision = 'APPROVE_WITH_CONDITIONS', decided_by = 'do-binh', decided_at = now() WHERE id = pg_temp.id('ar1');
INSERT INTO ph09_privacy.purpose_grant (id, tenant_id, request_id, httt_id, purpose_code, contract_kind, contract_id, valid_from, valid_to, status, fields, quota_per_day, approved_by, created_by, updated_by)
VALUES (pg_temp.id('pg1'), 'T90', pg_temp.id('ar1'), 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', now(), now() + interval '365 days', 'ACTIVE', ARRAY['fullName', 'nationalId'], 2000, 'do-binh', 'do-binh', 'do-binh');
INSERT INTO ph09_privacy.grant_condition (id, tenant_id, grant_id, condition_type, params, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pg1'), 'DAILY_QUOTA', '{"perDay": 2000}', 'do-binh', 'do-binh');
INSERT INTO ph09_privacy.processing_activity (id, tenant_id, code, version_no, purpose_text, legal_basis_code, categories, subject_groups, retention, controller_role, measures, created_by, updated_by)
VALUES (pg_temp.id('act1'), 'T90', 'RO-MDM-CONG-DAN', 1, 'Hợp nhất hồ sơ công dân liên ngành', 'STATE_TASK', ARRAY['FULL_NAME', 'NATIONAL_ID'], ARRAY['Công dân tỉnh'],
        '{"months": 60, "endCondition": "hết hồ sơ", "action": "PSEUDONYMIZE"}', 'CONTROLLER', ARRAY['Mã hóa trường', 'RLS', 'Che theo vai trò'], 'so-chi', 'so-chi');
INSERT INTO ph09_privacy.activity_link (id, tenant_id, activity_id, target_kind, target_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('act1'), 'ELEMENT', 'ph06_mdm.CITIZEN.nationalId', 'so-chi', 'so-chi');
INSERT INTO ph09_privacy.mask_policy (id, tenant_id, policy_code, version_no, status, created_by, updated_by) VALUES (pg_temp.id('mp1'), 'T90', 'CHINH-SACH-CHUNG', 1, 'DRAFT', 'ta-binh', 'ta-binh');
INSERT INTO ph09_privacy.mask_rule (id, tenant_id, policy_id, seq, cond_class, mask_type, pattern_kind, params, created_by, updated_by) VALUES
  (gen_random_uuid(), 'T90', pg_temp.id('mp1'), 1, 'RESTRICTED', 'PARTIAL', 'KEEP_LAST_N', '{"n": 4}', 'ta-binh', 'ta-binh'),
  (gen_random_uuid(), 'T90', pg_temp.id('mp1'), 2, 'SENSITIVE', 'DROP', NULL, '{}', 'ta-binh', 'ta-binh');
INSERT INTO ph09_privacy.pseudonym_domain (id, tenant_id, domain_code, purpose_code, method, key_name, created_by, updated_by) VALUES (pg_temp.id('pd1'), 'T90', 'THONG-KE-2026', 'THONG-KE', 'TOKEN_TRANSIT', 'dh-t90-pseudo-thong-ke-2026', 'ta-binh', 'ta-binh');
INSERT INTO ph09_privacy.pseudonym_key (id, tenant_id, domain_id, key_version, openbao_ref, created_by, updated_by) VALUES (pg_temp.id('pk1'), 'T90', pg_temp.id('pd1'), 1, 'transit/keys/dh-t90-pseudo-thong-ke-2026', 'ta-binh', 'ta-binh');
INSERT INTO ph09_privacy.anonymization_config (id, tenant_id, config_code, version_no, rules, purpose_code, created_by, updated_by) VALUES (pg_temp.id('ak1'), 'T90', 'CAU-HINH-ADN', 1, '[{"field":"dateOfBirth","transform":"GENERALIZE"}]', 'THONG-KE', 'da-chi', 'da-chi');
INSERT INTO ph09_privacy.subject_request (id, tenant_id, request_type, channel, identifier_type, subject_hash, identifier_enc, identifier_kid, content_enc, content_kid, idempotency_key, due_at, created_by, updated_by)
VALUES (pg_temp.id('sr1'), 'T90', 'ACCESS', 'PUBLIC_SERVICE', 'NATIONAL_ID', pg_temp.h('T90:012345678901'), pg_temp.enc('012345678901'), 'dh-t90-pii:1', pg_temp.enc('xin xem du lieu'), 'dh-t90-pii:1', 'idem-0001', now() + interval '14 days', 'cd-001', 'cd-001');
INSERT INTO ph09_privacy.consent_template (id, tenant_id, template_code, version_no, purpose_code, data_scope, body_text, withdrawal_guide, created_by, updated_by)
VALUES (pg_temp.id('ct1'), 'T90', 'NHAN-THONG-BAO', 1, 'THONG-KE', 'Số điện thoại', 'Tôi đồng ý nhận thông báo kết quả hồ sơ qua tin nhắn.', 'Rút tại quầy hoặc cổng dịch vụ công', 'ds-an', 'ds-an');
INSERT INTO ph09_privacy.breach_case (id, tenant_id, detected_at, deadline_at, source, description, data_types, reported_by, created_by, updated_by)
VALUES (pg_temp.id('bc1'), 'T90', '2026-11-20 08:00+07', '2026-11-23 08:00+07', 'PERSON', 'Nghi lộ tệp xuất', ARRAY['NATIONAL_ID'], 'so-chi', 'so-chi', 'so-chi');
INSERT INTO ph09_privacy.usage_counter (id, tenant_id, bucket_at, httt_id, purpose_code, contract_kind, contract_id, reporter, allowed_count)
VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()), 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', 'apisix-1', 5);
INSERT INTO ph09_privacy.privacy_audit_event (id, tenant_id, actor, action, target_kind, target_id, api_code, success, trace_id)
VALUES (gen_random_uuid(), 'T90', 'ta-binh', 'classification.confirm', 'ELEMENT', 'ph06_mdm.CITIZEN.nationalId', 'API-09-016', true, md5('t90'));
SELECT pg_temp.is_true($q$SELECT version = 0 FROM ph09_privacy.purpose WHERE code = 'THONG-KE'$q$, '04 version khởi tạo 0');
UPDATE ph09_privacy.purpose SET description = 'Thống kê định kỳ' WHERE code = 'THONG-KE';
SELECT pg_temp.is_true($q$SELECT version = 1 FROM ph09_privacy.purpose WHERE code = 'THONG-KE'$q$, '05 tg_touch tăng version');

-- ---------- 3. Cô lập tenant: T91 không đọc, chèn, sửa, xóa dòng T90 ----------
SET app.tenant_id = 'T91';
DO $$
DECLARE t text; n bigint; bad text := '';
BEGIN
  FOR t IN SELECT c.relname FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
           WHERE s.nspname = 'ph09_privacy' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname NOT IN ('data_class', 'personal_data_category', 'detector_rule', 'legal_basis', 'mask_type', 'tenant_setting', 'log_mask_config', 'retention_schedule', 'retention_schedule_line') LOOP
    EXECUTE format('SELECT count(*) FROM ph09_privacy.%I', t) INTO n;
    IF n <> 0 THEN bad := bad || t || ' '; END IF;
  END LOOP;
  IF bad <> '' THEN RAISE EXCEPTION 'FAIL 06 T91 đọc được dòng T90 ở: %', bad; END IF;
  RAISE NOTICE 'PASS 06 T91 đọc 0 dòng nghiệp vụ T90 trên mọi bảng (kể cả phân vùng)';
END $$;
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM ph09_privacy.data_class) = 4 AND NOT EXISTS (SELECT 1 FROM ph09_privacy.tenant_setting WHERE tenant_id <> 'T91')$q$, '07 bảng danh mục của T91 chỉ có dòng của T91, không dòng dùng chung');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.purpose (id, tenant_id, code, name, legal_basis_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'X-CHEO', 'chéo', 'STATE_TASK', 'x', 'x')$q$, '42501', '08 T91 chèn dòng mang tenant T90 bị RLS chặn');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.usage_counter (id, tenant_id, bucket_at, httt_id, purpose_code, contract_kind, contract_id, reporter) VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()), 'H', 'P', 'API', 'c', 'r')$q$, '42501', '09 T91 chèn vào bảng phân vùng usage_counter cho T90 bị chặn');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.privacy_audit_event (id, tenant_id, actor, action, target_kind, success, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 'y', 'z', true, repeat('a', 32))$q$, '42501', '10 T91 chèn kiểm toán cho T90 bị chặn');
DO $$
DECLARE n bigint;
BEGIN
  UPDATE ph09_privacy.purpose SET description = 'bị sửa chéo' WHERE code = 'TTHC-HO-TICH'; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 11 T91 sửa được dòng T90'; END IF;
  DELETE FROM ph09_privacy.purpose_element WHERE tenant_id = 'T90'; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 11 T91 xóa được dòng T90'; END IF;
  RAISE NOTICE 'PASS 11 T91 sửa, xóa dòng T90 tác động 0 dòng';
END $$;
SET app.tenant_id = 'COMMON';
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.data_class (id, tenant_id, code, rank, name, log_policy, display_policy, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'PUBLIC', 1, 'x', 'FULL', 'FULL', 'x', 'x')$q$, '42501', '12 không có dòng dùng chung COMMON');
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.purpose (id, tenant_id, code, name, legal_basis_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'X', 'x', 'STATE_TASK', 'x', 'x')$q$, '42501', '13 phiên T90 không chèn được dòng mang tenant T91');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.purpose (id, tenant_id, code, name, legal_basis_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TTHC-HO-TICH', 'trùng', 'STATE_TASK', 'x', 'x')$q$, '23505', '14 mã mục đích duy nhất trong tenant');
RESET app.tenant_id;
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph09_privacy.purpose$q$, '15 chưa đặt app.tenant_id (rỗng) thì không thấy dòng nào, không rò rỉ');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph09_privacy' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND NOT (c.relrowsecurity AND c.relforcerowsecurity)) = 0$q$, '16 mọi bảng bật ENABLE và FORCE RLS');
SELECT pg_temp.is_true($q$SELECT bool_and(n = 4) FROM (SELECT count(*) n FROM pg_policies WHERE schemaname = 'ph09_privacy' GROUP BY tablename) x$q$, '17 mỗi bảng đúng 4 chính sách RLS');

-- ---------- 4. Phân loại: hạ mức bốn mắt (BR-09-002, 003) ----------
INSERT INTO ph09_privacy.classification_change (id, tenant_id, element_id, from_class, to_class, from_personal_data_type, to_personal_data_type, proposed, basis, reason, proposed_by, source, created_by, updated_by)
VALUES (pg_temp.id('ch1'), 'T90', pg_temp.id('e1'), 'RESTRICTED', 'INTERNAL', 'BASIC', 'BASIC', '{"dataClass":"INTERNAL"}', 'CV-123/SO-TTTT', 'Hạ mức theo công văn của Sở', 'ds-an', 'MANUAL', 'ds-an', 'ds-an');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.classification_change SET status = 'CONFIRMED', confirmed_by = 'ds-an', confirmed_at = now() WHERE id = pg_temp.id('ch1')$q$, '23514', '18 người đề xuất không tự xác nhận');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.classification_change SET status = 'CONFIRMED', confirmed_by = 'ta-binh', confirmed_at = now() WHERE id = pg_temp.id('ch1')$q$, '23514', '19 hạ mức cần người xác nhận thứ hai');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.classification_change SET status = 'CONFIRMED', confirmed_by = 'ta-binh', confirmed_at = now(), confirmed_by_2 = 'ta-binh', confirmed_at_2 = now() WHERE id = pg_temp.id('ch1')$q$, '23514', '20 người xác nhận thứ hai phải khác người thứ nhất');
UPDATE ph09_privacy.classification_change SET status = 'CONFIRMED', confirmed_by = 'ta-binh', confirmed_at = now(), confirmed_by_2 = 'so-chi', confirmed_at_2 = now() WHERE id = pg_temp.id('ch1');
SELECT pg_temp.is_true($q$SELECT status = 'CONFIRMED' FROM ph09_privacy.classification_change WHERE id = pg_temp.id('ch1')$q$, '21 hạ mức đủ hai người xác nhận và số văn bản được chấp nhận');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.classification_change SET to_class = 'PUBLIC' WHERE id = pg_temp.id('ch1')$q$, '55000', '22 đề xuất đã chốt không đổi mức đích (bất biến)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.classification_change (id, tenant_id, element_id, from_class, to_class, from_personal_data_type, to_personal_data_type, proposed, status, reason, proposed_by, confirmed_by, confirmed_at, source, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('e1'), 'SENSITIVE', 'SENSITIVE', 'SENSITIVE', 'BASIC', '{}', 'CONFIRMED', 'Đổi loại DLCN xuống cơ bản', 'ds-an', 'ta-binh', now(), 'MANUAL', 'ds-an', 'ds-an')$q$, '23514', '23 hạ loại SENSITIVE xuống BASIC cần căn cứ và người thứ hai');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.element_classification (id, tenant_id, element_id, data_class, personal_data_type, category_code, status, source, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('e2'), 'RESTRICTED', 'SENSITIVE', 'HEALTH', 'PROPOSED', 'MANUAL', 'x', 'x')$q$, '23514', '24 loại DLCN SENSITIVE kéo theo mức SENSITIVE');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.element_classification (id, tenant_id, element_id, data_class, personal_data_type, category_code, status, source, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('e2'), 'RESTRICTED', 'BASIC', NULL, 'PROPOSED', 'MANUAL', 'x', 'x')$q$, '23514', '25 loại DLCN khác NONE phải có categoryCode');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.element_classification (id, tenant_id, element_id, data_class, personal_data_type, category_code, status, source, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('e1'), 'RESTRICTED', 'BASIC', 'NATIONAL_ID', 'PROPOSED', 'MANUAL', 'x', 'x')$q$, '23505', '26 mỗi phần tử một phân loại hiện hành');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.element_classification (id, tenant_id, element_id, data_class, personal_data_type, category_code, status, source, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('e3'), 'SENSITIVE', 'SENSITIVE', 'KHONG-CO', 'PROPOSED', 'MANUAL', 'x', 'x')$q$, '23503', '27 categoryCode phải có trong danh mục loại DLCN');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.element_classification (id, tenant_id, element_id, data_class, personal_data_type, category_code, status, source, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('e3'), 'SENSITIVE', 'SENSITIVE', 'HEALTH', 'CONFIRMED', 'MANUAL', 'x', 'x')$q$, '23514', '28 CONFIRMED phải có người và thời điểm xác nhận');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.data_class SET rank = 9 WHERE code = 'PUBLIC'$q$, '55000', '29 không đổi rank của mức cố định');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.data_class SET log_policy = 'FULL' WHERE code = 'SENSITIVE'$q$, '23514', '30 SENSITIVE luôn NO_VALUE ở log');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.data_class (id, tenant_id, code, rank, name, log_policy, display_policy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SECRET', 5, 'x', 'FULL', 'FULL', 'x', 'x')$q$, '23514', '31 chỉ bốn giá trị DataClass');
-- ---------- 5. Nhãn chặn STATE_SECRET: gỡ cần hai người (BR-09-005) ----------
INSERT INTO ph09_privacy.block_label (id, tenant_id, target_kind, target_id, legal_doc, assigned_by, created_by, updated_by) VALUES (pg_temp.id('sc1'), 'T90', 'API', 'api-x', 'QĐ-01/BCA', 'so-chi', 'so-chi', 'so-chi');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.block_label (id, tenant_id, target_kind, target_id, legal_doc, assigned_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API', 'api-x', 'QĐ-02', 'so-chi', 'so-chi', 'so-chi')$q$, '23505', '32 một nhãn hiệu lực mỗi đối tượng');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.block_label SET released_by = 'so-chi', released_at = now() WHERE id = pg_temp.id('sc1')$q$, '23514', '33 gỡ nhãn khi chưa có đề nghị gỡ kèm văn bản giải mật bị chặn');
UPDATE ph09_privacy.block_label SET release_requested_by = 'ds-an', release_requested_at = now(), release_doc = 'QĐ giải mật 77' WHERE id = pg_temp.id('sc1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.block_label SET released_by = 'ds-an', released_at = now() WHERE id = pg_temp.id('sc1')$q$, '23514', '34 người duyệt gỡ phải khác người đề nghị gỡ');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.block_label SET legal_doc = 'QĐ-sửa' WHERE id = pg_temp.id('sc1')$q$, '55000', '35 văn bản gán nhãn bất biến');
UPDATE ph09_privacy.block_label SET released_by = 'so-chi', released_at = now() WHERE id = pg_temp.id('sc1');

-- ---------- 6. Sổ hoạt động xử lý: phiên bản bất biến, bốn mắt (BR-09-011, 012) ----------
SELECT pg_temp.expect($q$UPDATE ph09_privacy.processing_activity SET status = 'ACTIVE', decided_by = 'so-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('act1')$q$, '23514', '36 người duyệt khác người soạn: so-chi soạn nên không tự duyệt');
UPDATE ph09_privacy.processing_activity SET status = 'ACTIVE', decided_by = 'da-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('act1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.processing_activity SET purpose_text = 'Đổi mục đích sau khi đã kích hoạt xong' WHERE id = pg_temp.id('act1')$q$, '55000', '37 hoạt động ACTIVE không sửa nội dung tại chỗ');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.activity_link (id, tenant_id, activity_id, target_kind, target_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('act1'), 'ELEMENT', 'ph06_mdm.CITIZEN.fullName', 'x', 'x')$q$, '55000', '38 không thêm liên kết vào hoạt động ACTIVE');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.processing_activity (id, tenant_id, code, version_no, purpose_text, legal_basis_code, categories, subject_groups, retention, controller_role, measures, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'RO-KHONG-HAN', 1, 'Hoạt động thiếu thời hạn lưu tường minh', 'STATE_TASK', ARRAY['PHONE'], ARRAY['Công dân'], '{"note": "chưa có"}', 'CONTROLLER', ARRAY['RLS'], 'x', 'x')$q$, '23514', '39 hoạt động phải có thời hạn lưu và hành động khi hết hạn');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.processing_activity (id, tenant_id, code, version_no, purpose_text, legal_basis_code, categories, subject_groups, retention, controller_role, measures, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'RO-SAI-CO-SO', 1, 'Hoạt động có cơ sở pháp lý không có trong danh mục', 'KHONG-CO', ARRAY['PHONE'], ARRAY['Công dân'], '{"months": 12, "action": "DELETE"}', 'CONTROLLER', ARRAY['RLS'], 'x', 'x')$q$, '23503', '40 cơ sở pháp lý phải có trong danh mục');
INSERT INTO ph09_privacy.processing_activity (id, tenant_id, code, version_no, purpose_text, legal_basis_code, categories, subject_groups, retention, controller_role, measures, created_by, updated_by)
VALUES (pg_temp.id('act2'), 'T90', 'RO-MDM-CONG-DAN', 2, 'Hợp nhất hồ sơ công dân liên ngành, bản sửa', 'STATE_TASK', ARRAY['FULL_NAME'], ARRAY['Công dân tỉnh'], '{"months": 60, "action": "DELETE"}', 'CONTROLLER', ARRAY['RLS'], 'so-chi', 'so-chi');
UPDATE ph09_privacy.processing_activity SET status = 'SUPERSEDED', superseded_at = now() WHERE id = pg_temp.id('act1');
UPDATE ph09_privacy.processing_activity SET status = 'ACTIVE', decided_by = 'da-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('act2');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.processing_activity SET status = 'ACTIVE', decided_by = 'da-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('act1')$q$, '23505', '41 mỗi hoạt động chỉ một phiên bản ACTIVE (bản cũ SUPERSEDED không bật lại)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.dpia_record (id, tenant_id, dpia_code, version_no, activity_id, dpia_kind, description, risks, measures, review_on, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'DPIA-MDM', 1, pg_temp.id('act2'), 'PROCESSING', 'Đánh giá tác động xử lý dữ liệu công dân', '[]', '[{"m":"RLS"}]', current_date + 300, 'so-chi', 'so-chi')$q$, '23514', '42 hồ sơ đánh giá tác động phải nêu ít nhất một rủi ro và một biện pháp');
INSERT INTO ph09_privacy.dpia_record (id, tenant_id, dpia_code, version_no, activity_id, dpia_kind, description, risks, measures, review_on, created_by, updated_by)
VALUES (pg_temp.id('dp1'), 'T90', 'DPIA-MDM', 1, pg_temp.id('act2'), 'PROCESSING', 'Đánh giá tác động xử lý dữ liệu công dân', '[{"r":"lộ số định danh","level":"HIGH"}]', '[{"m":"RLS và mã hóa trường"}]', current_date + 300, 'so-chi', 'so-chi');
UPDATE ph09_privacy.dpia_record SET status = 'ACTIVE', decided_by = 'da-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('dp1');
UPDATE ph09_privacy.dpia_record SET status = 'SUBMITTED_A05', submitted_a05_at = now(), a05_ref = 'A05-2026-0001' WHERE id = pg_temp.id('dp1');
SELECT pg_temp.is_true($q$SELECT status = 'SUBMITTED_A05' FROM ph09_privacy.dpia_record WHERE id = pg_temp.id('dp1')$q$, '43 DPIA chuyển SUBMITTED_A05 kèm thời điểm gửi');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.dpia_record SET risks = '[{"r":"đã sửa"}]' WHERE id = pg_temp.id('dp1')$q$, '55000', '44 hồ sơ đã gửi A05 không sửa nội dung rủi ro');

-- ---------- 7. Mục đích và chấp thuận (BR-09-013…016) ----------
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.purpose_grant (id, tenant_id, request_id, httt_id, purpose_code, contract_kind, contract_id, valid_from, valid_to, status, fields, approved_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('ar1'), 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', now(), now() + interval '30 days', 'ACTIVE', ARRAY['fullName'], 'do-binh', 'do-binh', 'do-binh')$q$, '23505', '45 một chấp thuận hiệu lực mỗi bộ ba (HTTT, mục đích, hợp đồng)');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.purpose_grant SET httt_id = 'HT-KHAC' WHERE id = pg_temp.id('pg1')$q$, '55000', '46 chấp thuận không chuyển nhượng cho HTTT khác');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.purpose_grant SET valid_to = valid_from + interval '800 days' WHERE id = pg_temp.id('pg1')$q$, '23514', '47 chấp thuận không quá 730 ngày');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.purpose_grant SET status = 'REVOKED', revoked_by = 'do-binh', revoked_at = now(), revoke_reason = 'ngắn' WHERE id = pg_temp.id('pg1')$q$, '23514', '48 thu hồi cần lý do từ 20 ký tự');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.purpose_grant SET status = 'SUSPENDED' WHERE id = pg_temp.id('pg1')$q$, '23514', '49 tạm dừng phải có thời điểm và lý do');
UPDATE ph09_privacy.purpose_grant SET status = 'REVOKED', revoked_by = 'do-binh', revoked_at = now(), revoke_reason = 'Phát hiện khai thác ngoài phạm vi mục đích' WHERE id = pg_temp.id('pg1');
INSERT INTO ph09_privacy.purpose_grant (id, tenant_id, request_id, httt_id, purpose_code, contract_kind, contract_id, valid_from, valid_to, status, fields, approved_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('ar1'), 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', now(), now() + interval '30 days', 'ACTIVE', ARRAY['fullName'], 'do-binh', 'do-binh', 'do-binh');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph09_privacy.purpose_grant WHERE status = 'ACTIVE'$q$, '50 sau thu hồi lập chấp thuận mới được (yêu cầu mới trên cùng bộ ba)');
INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, status, submitted_at, created_by, updated_by)
VALUES (pg_temp.id('ar2'), 'T90', 'HT-YTE', 'THONG-KE', 'TOPIC', 'topic-kham-benh', ARRAY['gender'], 100, 90, 'Thống kê số ca khám theo giới tính', 'ORG-YT', 'UNDER_REVIEW', now(), 'httt-yt', 'httt-yt');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.access_request SET status = 'APPROVED', decision = 'APPROVE', decided_by = 'httt-yt', decided_at = now() WHERE id = pg_temp.id('ar2')$q$, '23514', '51 người lập yêu cầu không tự duyệt (BR-09-014)');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.access_request SET status = 'REJECTED', decision = 'REJECT', decided_by = 'do-binh', decided_at = now(), decision_reason = 'thiếu' WHERE id = pg_temp.id('ar2')$q$, '23514', '52 từ chối phải nêu lý do từ 20 ký tự');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-X', 'THONG-KE', 'API', 'c', ARRAY['a'], 10, 900, 'Yêu cầu quá hạn tối đa cho phép của chấp thuận', 'ORG', 'x', 'x')$q$, '23514', '53 số ngày yêu cầu không quá 730');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-X', 'KHONG-CO', 'API', 'c', ARRAY['a'], 10, 30, 'Yêu cầu cho mục đích không có trong danh mục', 'ORG', 'x', 'x')$q$, '23503', '54 mục đích phải có trong danh mục');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.grant_condition (id, tenant_id, grant_id, condition_type, created_by, updated_by) SELECT gen_random_uuid(), 'T90', grant_id, 'DAILY_QUOTA', 'x', 'x' FROM ph09_privacy.grant_condition LIMIT 1$q$, '23505', '55 mỗi loại điều kiện một dòng mỗi chấp thuận');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.grant_condition (id, tenant_id, grant_id, condition_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pg1'), 'DAILY_LIMIT', 'x', 'x')$q$, '23514', '56 ConditionType chỉ năm giá trị Phụ lục A');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.policy_bundle (id, tenant_id, bundle_no, content_hash, object_ref, size_bytes, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 1, '\x00', 's3://b/1', 1000, 'x', 'x')$q$, '23514', '57 content_hash đúng 32 byte');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.policy_bundle (id, tenant_id, bundle_no, content_hash, object_ref, size_bytes, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 1, pg_temp.h('b1'), 's3://b/1', 6000000, 'x', 'x')$q$, '23514', '58 bundle không quá 5 MB (NFR-09-020)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.policy_bundle (id, tenant_id, bundle_no, content_hash, object_ref, size_bytes, signature, signing_key_ref, published_at, valid_until, test_passed, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 1, pg_temp.h('b1'), 's3://b/1', 1000, '\x01', 'transit/keys/dh-t90-bundle', now(), now() + interval '60 minutes', false, 'x', 'x')$q$, '23514', '59 chỉ phát hành bundle khi kiểm thử đạt');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.policy_bundle (id, tenant_id, bundle_no, content_hash, object_ref, size_bytes, signature, signing_key_ref, published_at, valid_until, test_passed, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 1, pg_temp.h('b1'), 's3://b/1', 1000, '\x01', 'transit/keys/dh-t90-bundle', now(), now() + interval '300 minutes', true, 'x', 'x')$q$, '23514', '60 validUntil không quá 240 phút sau phát hành');
INSERT INTO ph09_privacy.policy_bundle (id, tenant_id, bundle_no, content_hash, object_ref, size_bytes, signature, signing_key_ref, published_at, valid_until, test_passed, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 1, pg_temp.h('b1'), 's3://b/1', 1000, '\x01', 'transit/keys/dh-t90-bundle', now(), now() + interval '60 minutes', true, 'ta-binh', 'ta-binh');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.policy_bundle SET content_hash = pg_temp.h('khac')$q$, '55000', '61 nội dung bundle đã băm không đổi');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.usage_counter (id, tenant_id, bucket_at, httt_id, purpose_code, contract_kind, contract_id, reporter) VALUES (gen_random_uuid(), 'T90', now(), 'H', 'P', 'API', 'c', 'r')$q$, '23514', '62 bộ đếm khai thác theo đúng phút');

-- ---------- 8. Chính sách che (BR-09-021…026) ----------
SELECT pg_temp.expect($q$UPDATE ph09_privacy.mask_policy SET status = 'PENDING_APPROVAL', submitted_by = 'ta-binh', submitted_at = now() WHERE id = pg_temp.id('mp1')$q$, '23514', '63 gửi duyệt chính sách che khi chưa có mô phỏng đạt');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.mask_rule (id, tenant_id, policy_id, seq, cond_class, mask_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mp1'), 3, 'SENSITIVE', 'NONE', 'x', 'x')$q$, '23514', '64 mức SENSITIVE không được đặt kiểu che NONE');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.mask_rule (id, tenant_id, policy_id, seq, cond_class, mask_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mp1'), 3, 'RESTRICTED', 'PARTIAL', 'x', 'x')$q$, '23514', '65 kiểu PARTIAL phải có mẫu che MaskPatternKind');
INSERT INTO ph09_privacy.mask_simulation (id, tenant_id, policy_id, policy_version, sample_ref, sample_rows, role, channel, passed, run_by, created_by, updated_by)
VALUES (pg_temp.id('ms1'), 'T90', pg_temp.id('mp1'), 1, 's3://mau/ms1.json', 500, 'VW', 'API', true, 'ta-binh', 'ta-binh', 'ta-binh');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.mask_simulation (id, tenant_id, policy_id, policy_version, sample_ref, sample_rows, run_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mp1'), 1, 's3://mau/x', 5000, 'x', 'x', 'x')$q$, '23514', '66 mô phỏng tối đa 1.000 dòng mẫu');
UPDATE ph09_privacy.mask_policy SET passed_simulation_id = pg_temp.id('ms1'), status = 'PENDING_APPROVAL', submitted_by = 'ta-binh', submitted_at = now() WHERE id = pg_temp.id('mp1');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.mask_rule (id, tenant_id, policy_id, seq, cond_class, mask_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('mp1'), 3, 'INTERNAL', 'NONE', 'x', 'x')$q$, '55000', '67 chính sách đã gửi duyệt không thêm quy tắc con');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.mask_policy SET status = 'ACTIVE', decided_by = 'ta-binh', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('mp1')$q$, '23514', '68 phát hành chính sách che cần người duyệt khác người soạn (bốn mắt)');
UPDATE ph09_privacy.mask_policy SET status = 'ACTIVE', decided_by = 'so-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('mp1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.mask_policy SET scope = 'CONTRACT' WHERE id = pg_temp.id('mp1')$q$, '55000', '69 phạm vi chính sách bất biến');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.mask_policy (id, tenant_id, policy_code, version_no, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CS-HD', 1, 'CONTRACT', 'x', 'x')$q$, '23514', '70 phạm vi CONTRACT phải có hợp đồng');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.mask_type (id, tenant_id, code, mask_type, pattern_kind, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'X', 'PARTIAL', 'YEAR_ONLY', 'sai cặp', 'x', 'x')$q$, '23514', '71 mẫu YEAR_ONLY chỉ đi với GENERALIZE');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.reveal_grant (id, tenant_id, requested_by, target_ref, fields, reason, expires_at, token_hash, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ta-binh', 'ho-so-1', ARRAY['nationalId'], 'Đối chiếu hồ sơ khiếu nại số 15', now() + interval '120 seconds', pg_temp.h('t'), 'x', 'x')$q$, '23514', '72 phiếu xem đầy đủ hết hạn trong tối đa 60 giây');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.reveal_grant (id, tenant_id, requested_by, target_ref, fields, reason, expires_at, token_hash, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ta-binh', 'ho-so-1', ARRAY['nationalId'], 'ngắn', now() + interval '60 seconds', pg_temp.h('t'), 'x', 'x')$q$, '23514', '73 lý do xem đầy đủ từ 20 ký tự');
INSERT INTO ph09_privacy.reveal_grant (id, tenant_id, requested_by, target_ref, fields, reason, expires_at, token_hash, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'ta-binh', 'ho-so-1', ARRAY['nationalId'], 'Đối chiếu hồ sơ khiếu nại số 15', now() + interval '60 seconds', pg_temp.h('t'), 'ta-binh', 'ta-binh');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.reveal_grant SET expires_at = expires_at + interval '1 hour'$q$, '55000', '74 không gia hạn phiếu xem đầy đủ (bất biến)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.leak_finding (id, tenant_id, source, detector_code, match_count, fingerprint, first_seen_at, last_seen_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'log-dh-data', 'NATIONAL_ID_12', 3, '\x01', now(), now(), 'x', 'x')$q$, '23514', '75 dấu vân rò rỉ là HMAC 32 byte, không lưu đoạn log');

-- ---------- 9. Giả danh hóa, khôi phục, ẩn danh hóa (BR-09-029…037) ----------
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.pseudonym_key (id, tenant_id, domain_id, key_version, openbao_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pd1'), 2, 'transit/keys/dh-t90-pseudo-thong-ke-2026', 'x', 'x')$q$, '23505', '76 mỗi miền một phiên bản khóa ACTIVE');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.pseudonym_key (id, tenant_id, domain_id, key_version, status, openbao_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pd1'), 2, 'DECRYPT_ONLY', 'vault://khoa-that-su', 'x', 'x')$q$, '23514', '77 openbao_ref chỉ là tham chiếu transit, không chứa vật liệu khóa');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.pseudonym_key SET status = 'DESTROYED', disabled_at = now(), destroyed_at = now(), destroy_requested_by = 'ta-binh', destroy_approved_by = 'ta-binh', destroy_not_before = now() - interval '1 day' WHERE id = pg_temp.id('pk1')$q$, '23514', '78 hủy khóa cần hai người khác nhau');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.pseudonym_key SET status = 'DESTROYED', disabled_at = now(), destroyed_at = now(), destroy_requested_by = 'ta-binh', destroy_approved_by = 'so-chi', destroy_not_before = now() + interval '7 days' WHERE id = pg_temp.id('pk1')$q$, '23514', '79 chưa đủ thời gian chờ thì không hủy khóa');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.pseudonym_domain (id, tenant_id, domain_code, purpose_code, method, rotate_days, key_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MIEN-SAI', 'THONG-KE', 'HMAC_SHA256', 30, 'dh-t90-x', 'x', 'x')$q$, '23514', '80 chu kỳ xoay khóa từ 90 đến 730 ngày');
INSERT INTO ph09_privacy.reidentification_request (id, tenant_id, domain_id, token_count, tokens_digest, purpose_code, basis, reason, requested_by, approval_expires_at, created_by, updated_by)
VALUES (pg_temp.id('rr1'), 'T90', pg_temp.id('pd1'), 5, pg_temp.h('tokens'), 'TTHC-HO-TICH', 'Yêu cầu của Cơ quan điều tra số 15', 'Xác định chủ thể theo yêu cầu điều tra', 'ta-binh', now() + interval '24 hours', 'ta-binh', 'ta-binh');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.reidentification_request (id, tenant_id, domain_id, token_count, tokens_digest, purpose_code, basis, reason, requested_by, approval_expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('pd1'), 101, pg_temp.h('tokens'), 'TTHC-HO-TICH', 'căn cứ', 'Khôi phục quá số lượng cho phép của một đề nghị', 'x', now(), 'x', 'x')$q$, '23514', '81 tối đa 100 giá trị mỗi đề nghị khôi phục');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.reidentification_request SET status = 'PENDING_L2', l1_by = 'ta-binh', l1_at = now() WHERE id = pg_temp.id('rr1')$q$, '23514', '82 người duyệt cấp 1 khác người đề nghị');
UPDATE ph09_privacy.reidentification_request SET status = 'PENDING_L2', l1_by = 'so-chi', l1_at = now() WHERE id = pg_temp.id('rr1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.reidentification_request SET status = 'APPROVED', l2_by = 'so-chi', l2_at = now(), mfa_verified = true, exec_deadline_at = now() + interval '30 minutes' WHERE id = pg_temp.id('rr1')$q$, '23514', '83 người duyệt cấp 2 khác cấp 1 và khác người đề nghị');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.reidentification_request SET status = 'APPROVED', l2_by = 'da-chi', l2_at = now(), mfa_verified = false, exec_deadline_at = now() + interval '30 minutes' WHERE id = pg_temp.id('rr1')$q$, '23514', '84 duyệt đủ hai cấp phải có MFA');
UPDATE ph09_privacy.reidentification_request SET status = 'APPROVED', l2_by = 'da-chi', l2_at = now(), mfa_verified = true, exec_deadline_at = now() + interval '30 minutes' WHERE id = pg_temp.id('rr1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.reidentification_request SET token_count = 50 WHERE id = pg_temp.id('rr1')$q$, '55000', '85 phạm vi đề nghị khôi phục bất biến sau khi lập');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymization_config (id, tenant_id, config_code, version_no, k, rules, purpose_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'K-NHO', 1, 5, '[{"f":1}]', 'THONG-KE', 'x', 'x')$q$, '23514', '86 k tối thiểu 10 (SEC-38, BR-09-035)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymization_config (id, tenant_id, config_code, version_no, privacy_model, k, rules, purpose_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'L-THIEU', 1, 'L_DIVERSITY', 10, '[{"f":1}]', 'THONG-KE', 'x', 'x')$q$, '23514', '87 l-đa dạng phải có tham số l');
INSERT INTO ph09_privacy.anonymization_job (id, tenant_id, config_id, source_ref, purpose_code, target, status, requested_by, rows_before, rows_after, k_actual, generalization_rounds, output_ref, finished_at, created_by, updated_by)
VALUES (pg_temp.id('aj1'), 'T90', pg_temp.id('ak1'), 's3://nguon/kham-benh', 'THONG-KE', 'AI_TRAINING', 'COMPLETED', 'da-chi', 1000000, 600000, 12, 2, 's3://ra/aj1', now(), 'da-chi', 'da-chi');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymization_job (id, tenant_id, config_id, source_ref, purpose_code, status, requested_by, rows_before, rows_after, k_actual, output_ref, finished_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('ak1'), 's3://n', 'THONG-KE', 'COMPLETED', 'x', 1000, 100, 12, 's3://o', now(), 'x', 'x')$q$, '23514', '88 tập ẩn danh phải còn ít nhất 30% bản ghi');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymization_job (id, tenant_id, config_id, source_ref, purpose_code, status, requested_by, rows_before, rows_after, k_actual, output_ref, finished_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('ak1'), 's3://n', 'THONG-KE', 'COMPLETED', 'x', 1000, 900, 5, 's3://o', now(), 'x', 'x')$q$, '23514', '89 job hoàn tất phải đạt k thực tế ≥ 10');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymization_job (id, tenant_id, config_id, source_ref, purpose_code, requested_by, generalization_rounds, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ak1'), 's3://n', 'THONG-KE', 'x', 4, 'x', 'x')$q$, '23514', '90 tối đa 3 vòng tổng quát hóa');
INSERT INTO ph09_privacy.risk_report (id, tenant_id, job_id, dataset_ref, risk_model, quasi_identifiers, k_actual, small_group_ratio, risk_value, level, created_by, updated_by)
VALUES (pg_temp.id('rs1'), 'T90', pg_temp.id('aj1'), 's3://ra/aj1', 'PROSECUTOR', ARRAY['yearOfBirth', 'adminUnit'], 12, 0.02, 0.083, 'MEDIUM', 'da-chi', 'da-chi');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymized_dataset (id, tenant_id, job_id, risk_report_id, name, storage_ref, purpose_code, target, terms, k_actual, risk_level, status, expires_on, published_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('aj1'), pg_temp.id('rs1'), 'Tập khám bệnh', 's3://ra/aj1', 'THONG-KE', 'AI_TRAINING', '{"noReidentify": true}', 12, 'MEDIUM', 'PUBLISHED', current_date + 180, now(), 'x', 'x')$q$, '23514', '91 phát hành tập rủi ro MEDIUM cần người duyệt (SO)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.anonymized_dataset (id, tenant_id, job_id, risk_report_id, name, storage_ref, purpose_code, target, terms, k_actual, risk_level, status, expires_on, published_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('aj1'), pg_temp.id('rs1'), 'Tập khám bệnh', 's3://ra/aj1', 'THONG-KE', 'AI_TRAINING', '{"noReidentify": true}', 12, 'HIGH', 'PUBLISHED', current_date + 180, now(), 'x', 'x')$q$, '23514', '92 rủi ro HIGH chặn phát hành');
INSERT INTO ph09_privacy.anonymized_dataset (id, tenant_id, job_id, risk_report_id, name, storage_ref, purpose_code, target, terms, k_actual, risk_level, approved_by, status, expires_on, published_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('aj1'), pg_temp.id('rs1'), 'Tập khám bệnh', 's3://ra/aj1', 'THONG-KE', 'AI_TRAINING', '{"noReidentify": true}', 12, 'MEDIUM', 'so-chi', 'PUBLISHED', current_date + 180, now(), 'da-chi', 'da-chi');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph09_privacy.anonymized_dataset WHERE status = 'PUBLISHED'$q$, '93 tập MEDIUM có SO duyệt, k ≥ 10 được phát hành');

-- ---------- 10. Lưu giữ, giữ pháp lý, xóa mật mã tenant ----------
SELECT pg_temp.expect($q$UPDATE ph09_privacy.retention_schedule_line SET retain_days = 1 WHERE entity = 'subject_request'$q$, '55000', '94 lịch lưu giữ ACTIVE không sửa dòng con');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.retention_schedule SET description = 'sửa' || 'x', status = 'ACTIVE', decided_by = 'system:seed', activated_at = now() WHERE schedule_code = 'PH09-OWN'$q$, '23514', '95 người duyệt lịch lưu giữ khác người soạn');
INSERT INTO ph09_privacy.legal_hold (id, tenant_id, scope, basis_doc, basis_date, authority, review_on, placed_by, created_by, updated_by)
VALUES (pg_temp.id('lh1'), 'T90', '{"subjectHashes": ["ab12"], "entities": ["subject_request"]}', 'Lệnh 55/CQĐT', '2026-11-01', 'Cơ quan điều tra Công an tỉnh', '2027-02-01', 'so-chi', 'so-chi', 'so-chi');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.legal_hold SET status = 'RELEASED' WHERE id = pg_temp.id('lh1')$q$, '23514', '96 gỡ giữ pháp lý phải có người, thời điểm, lý do');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.legal_hold SET basis_doc = 'sửa văn bản' WHERE id = pg_temp.id('lh1')$q$, '55000', '97 văn bản căn cứ giữ pháp lý bất biến');
INSERT INTO ph09_privacy.retention_task (id, tenant_id, schedule_id, entity, run_date, status, requested_by, rows_scanned, rows_affected, rows_skipped_hold, hold_ids, finished_at, created_by, updated_by)
SELECT gen_random_uuid(), 'T90', id, 'subject_request', current_date, 'COMPLETED', 'system:job', 100, 90, 10, ARRAY[pg_temp.id('lh1')], now(), 'system:job', 'system:job' FROM ph09_privacy.retention_schedule WHERE schedule_code = 'PH09-OWN';
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.retention_task (id, tenant_id, schedule_id, entity, run_date, status, requested_by, rows_scanned, rows_affected, rows_skipped_hold, created_by, updated_by)
  SELECT gen_random_uuid(), 'T90', id, 'subject_request', current_date, 'COMPLETED', 'x', 100, 95, 10, 'x', 'x' FROM ph09_privacy.retention_schedule WHERE schedule_code = 'PH09-OWN'$q$, '23514', '98 số bản ghi xử lý cộng bỏ qua không vượt số quét');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.retention_task (id, tenant_id, schedule_id, entity, run_date, status, requested_by, finished_at, created_by, updated_by)
  SELECT gen_random_uuid(), 'T90', id, 'subject_request', current_date, 'COMPLETED', 'x', now(), 'x', 'x' FROM ph09_privacy.retention_schedule WHERE schedule_code = 'PH09-OWN'$q$, '23505', '99 chạy lại cùng ngày không nhân bản tác vụ');
INSERT INTO ph09_privacy.tenant_shred_request (id, tenant_id, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'Chấm dứt tenant theo quyết định giải thể số 12', 'ta-binh', 'ta-binh', 'ta-binh');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.tenant_shred_request (id, tenant_id, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'Đề nghị thứ hai khi đề nghị đầu còn mở', 'ta-binh', 'x', 'x')$q$, '23505', '100 một đề nghị xóa mật mã đang mở mỗi tenant');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.tenant_shred_request SET status = 'APPROVED', export_confirmed = true, approver_1 = 'so-chi', approver_2 = 'da-chi', approved_at = now(), wait_until = now() + interval '3 days'$q$, '23514', '101 chờ tối thiểu 7 ngày trước khi hủy KEK');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.tenant_shred_request SET status = 'APPROVED', export_confirmed = false, approver_1 = 'so-chi', approver_2 = 'da-chi', approved_at = now(), wait_until = now() + interval '8 days'$q$, '23514', '102 chỉ duyệt xóa mật mã sau khi đã bàn giao dữ liệu');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.tenant_shred_request SET status = 'APPROVED', export_confirmed = true, approver_1 = 'ta-binh', approver_2 = 'da-chi', approved_at = now(), wait_until = now() + interval '8 days'$q$, '23514', '103 người duyệt xóa mật mã khác người đề nghị');

-- ---------- 11. Yêu cầu chủ thể và đồng ý (BR-09-042…051, 061) ----------
SELECT pg_temp.expect($q$UPDATE ph09_privacy.subject_request SET status = 'IN_PROGRESS' WHERE id = pg_temp.id('sr1')$q$, '23514', '104 chưa xác minh danh tính thì không chuyển IN_PROGRESS (BR-09-042)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.subject_request (id, tenant_id, request_type, channel, identifier_type, subject_hash, identifier_enc, identifier_kid, content_enc, content_kid, idempotency_key, due_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ACCESS', 'EMAIL', 'EMAIL', pg_temp.h('x'), pg_temp.enc('a@b.vn'), 'k:1', pg_temp.enc('nd'), 'k:1', 'idem-0001', now() + interval '10 days', 'x', 'x')$q$, '23505', '105 Idempotency-Key duy nhất trong tenant (BR-09-061)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.subject_request (id, tenant_id, request_type, channel, identifier_type, subject_hash, identifier_enc, identifier_kid, content_enc, content_kid, idempotency_key, due_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ACCESS', 'EMAIL', 'EMAIL', '\x01', pg_temp.enc('a@b.vn'), 'k:1', pg_temp.enc('nd'), 'k:1', 'idem-0002', now() + interval '10 days', 'x', 'x')$q$, '23514', '106 băm chủ thể HMAC đúng 32 byte');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.subject_request (id, tenant_id, request_type, channel, identifier_type, subject_hash, identifier_enc, identifier_kid, content_enc, content_kid, idempotency_key, due_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ACCESS', 'EMAIL', 'EMAIL', pg_temp.h('y'), '\x0102', 'k:1', pg_temp.enc('nd'), 'k:1', 'idem-0003', now() + interval '10 days', 'x', 'x')$q$, '23514', '107 định danh chỉ ở dạng bản mã envelope (≥ 29 byte)');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.subject_request SET restriction_active = true WHERE id = pg_temp.id('sr1')$q$, '23514', '108 cờ hạn chế xử lý chỉ cho yêu cầu RESTRICT');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.subject_request SET identifier_enc = pg_temp.enc('khac') WHERE id = pg_temp.id('sr1')$q$, '55000', '109 định danh mã hóa của phiếu bất biến');
INSERT INTO ph09_privacy.subject_verification (id, tenant_id, request_id, method, passed, evidence_hash, verified_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('sr1'), 'ID_DOCUMENT', true, pg_temp.h('cccd-scan'), 'cb-quay', 'cb-quay', 'cb-quay');
UPDATE ph09_privacy.subject_request SET status = 'IN_PROGRESS', verified_at = now() WHERE id = pg_temp.id('sr1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.subject_request SET status = 'RESPONDED', outcome = 'REFUSED', responded_at = now() WHERE id = pg_temp.id('sr1')$q$, '23514', '110 từ chối yêu cầu phải nêu căn cứ pháp lý (BR-09-046)');
INSERT INTO ph09_privacy.subject_task (id, tenant_id, request_id, target, action, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('sr1'), 'PH06_MASTER', 'ACCESS', 'so-chi', 'so-chi');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.subject_task SET status = 'REFUSED' WHERE request_id = pg_temp.id('sr1')$q$, '23514', '111 tác vụ bị từ chối phải có lý do');
UPDATE ph09_privacy.consent_template SET status = 'ACTIVE', decided_by = 'so-chi', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('ct1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.consent_template SET body_text = 'Nội dung mới sau khi đã kích hoạt mẫu' WHERE id = pg_temp.id('ct1')$q$, '55000', '112 nội dung mẫu đồng ý ACTIVE bất biến (bằng chứng băm nội dung)');
INSERT INTO ph09_privacy.consent_record (id, tenant_id, template_id, template_code, template_version, subject_hash, channel, text_hash, recorded_by, created_by, updated_by)
VALUES (pg_temp.id('cr1'), 'T90', pg_temp.id('ct1'), 'NHAN-THONG-BAO', 1, pg_temp.h('T90:0912345678'), 'WEB', pg_temp.h('noi-dung-hien-thi'), 'cd-001', 'cd-001', 'cd-001');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.consent_record (id, tenant_id, template_id, template_code, template_version, subject_hash, channel, text_hash, recorded_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', pg_temp.id('ct1'), 'NHAN-THONG-BAO', 1, pg_temp.h('T90:0912345678'), 'APP', pg_temp.h('nd'), 'cd-001', 'x', 'x')$q$, '23505', '113 một đồng ý GIVEN mỗi (chủ thể, mẫu)');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.consent_record SET status = 'WITHDRAWN' WHERE id = pg_temp.id('cr1')$q$, '23514', '114 rút đồng ý phải ghi thời điểm, kênh, người rút');
UPDATE ph09_privacy.consent_record SET status = 'WITHDRAWN', withdrawn_at = now(), withdrawn_channel = 'COUNTER', withdrawn_by = 'cb-quay' WHERE id = pg_temp.id('cr1');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.consent_record SET text_hash = pg_temp.h('khac') WHERE id = pg_temp.id('cr1')$q$, '55000', '115 bằng chứng đồng ý (băm nội dung) bất biến');
INSERT INTO ph09_privacy.consent_record (id, tenant_id, template_id, template_code, template_version, subject_hash, channel, text_hash, recorded_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('ct1'), 'NHAN-THONG-BAO', 1, pg_temp.h('T90:0912345678'), 'WEB', pg_temp.h('noi-dung-hien-thi'), 'cd-001', 'cd-001', 'cd-001');
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph09_privacy.consent_record$q$, '116 đồng ý lại sau khi rút tạo bản ghi mới, giữ bản ghi rút làm lịch sử');

-- ---------- 12. Vi phạm DLCN: đồng hồ 72 giờ (BR-09-054…056) ----------
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.breach_case (id, tenant_id, detected_at, deadline_at, source, description, data_types, reported_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', now(), now() + interval '96 hours', 'PERSON', 'Hạn sai 96 giờ', ARRAY['PHONE'], 'x', 'x', 'x')$q$, '23514', '117 hạn thông báo đúng 72 giờ kể từ detectedAt');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.breach_case (id, tenant_id, detected_at, deadline_at, source, description, data_types, reported_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', now(), now() + interval '72 hours', 'PERSON', 'Loại dữ liệu ngoài danh mục', ARRAY['KHONG-CO'], 'x', 'x', 'x')$q$, '23514', '118 loại dữ liệu bị ảnh hưởng thuộc PersonalDataCategory');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.breach_case SET deadline_at = deadline_at + interval '24 hours' WHERE id = pg_temp.id('bc1')$q$, '55000', '119 đồng hồ không dừng hay đặt lại (detectedAt, deadlineAt bất biến)');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.breach_case SET status = 'NOTIFIED', assessed_by = 'so-chi', assessed_at = now() WHERE id = pg_temp.id('bc1')$q$, '23514', '120 NOTIFIED cần thông báo Cục A05 hoặc căn cứ miễn trừ');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.breach_case SET status = 'NOT_A_BREACH', assessed_by = 'so-chi', assessed_at = now(), not_breach_reason = 'Tệp chỉ chứa dữ liệu giả lập kiểm thử', not_breach_approved_by = 'so-chi' WHERE id = pg_temp.id('bc1')$q$, '23514', '121 NOT_A_BREACH cần người duyệt khác người đánh giá');
UPDATE ph09_privacy.breach_case SET status = 'NOTIFIED', assessed_by = 'so-chi', assessed_at = now(), notified_a05_at = '2026-11-22 10:00+07' WHERE id = pg_temp.id('bc1');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.breach_notification (id, tenant_id, case_id, recipient, status, content, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('bc1'), 'A05', 'SENT', 'Nội dung thông báo gửi Cục A05', 'x', 'x')$q$, '23514', '122 thông báo SENT phải có người gửi, thời điểm, bằng chứng');
INSERT INTO ph09_privacy.breach_notification (id, tenant_id, case_id, recipient, status, content, sent_at, sent_by, evidence_ref, evidence_hash, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('bc1'), 'A05', 'SENT', 'Nội dung thông báo gửi Cục A05', now(), 'so-chi', 's3://bang-chung/a05-1.pdf', pg_temp.h('a05'), 'so-chi', 'so-chi');

-- ---------- 13. Nhật ký chỉ thêm, outbox, tham số ----------
SELECT pg_temp.expect($q$UPDATE ph09_privacy.privacy_audit_event SET success = false$q$, '42501', '123 ứng dụng không UPDATE nhật ký kiểm toán');
SELECT pg_temp.expect($q$DELETE FROM ph09_privacy.privacy_audit_event$q$, '42501', '124 ứng dụng không DELETE nhật ký kiểm toán');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.privacy_audit_event (id, tenant_id, actor, action, target_kind, success, details, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 'reveal', 'ELEMENT', true, '{"value": "012345678901"}', repeat('a', 32))$q$, '23514', '125 kiểm toán không mang khóa giá trị (BR-09-058)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.privacy_audit_event (id, tenant_id, actor, action, target_kind, success, api_code, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 'y', 'z', true, 'API-06-001', repeat('a', 32))$q$, '23514', '126 api_code chỉ dạng API-09-nnn');
INSERT INTO ph09_privacy.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
VALUES (gen_random_uuid(), 'T90', 'purpose-grant.revoked', 't90.privacy.purpose-grant.revoked.v1', 'PurposeGrant', pg_temp.id('pg1')::text, 'T90', '{"grantId": "g1", "status": "REVOKED", "revokedAt": "2026-11-26T01:00:00Z"}', repeat('b', 32));
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 't90.privacy.purpose-grant.revoked.v1', 'PurposeGrant', 'a', 'T90', '{"identifier": "012345678901"}', repeat('b', 32))$q$, '23514', '127 sự kiện outbox không mang giá trị định danh (BR-09-025)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 't90.privacy.khong-co.v1', 'PurposeGrant', 'a', 'T90', '{}', repeat('b', 32))$q$, '23514', '128 chỉ 32 topic EVT-09 và kiểm toán');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 't91.privacy.purpose-grant.revoked.v1', 'PurposeGrant', 'a', 'T90', '{}', repeat('b', 32))$q$, '23514', '129 topic mang tiền tố của đúng tenant');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.outbox_event SET payload = '{}'$q$, '42501', '130 ứng dụng không UPDATE outbox');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.tenant_setting SET setting_key = '09.khac.khoa' WHERE setting_key = '09.scan.confidence'$q$, '55000', '131 khóa tham số bất biến');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '09.khong.co', '1', 'x', 'x')$q$, '23514', '132 chỉ 43 khóa tham số 09.* hợp lệ');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.tenant_setting SET value = '999999' WHERE setting_key = '09.grant.max-days'$q$, '23514', '133 giá trị tham số không vượt trần của PA (BR-09-059)');

-- ---------- 14. Quyền theo vai trò ----------
SELECT pg_temp.expect($q$DELETE FROM ph09_privacy.purpose_grant$q$, '42501', '134 ứng dụng không xóa cứng chấp thuận (đối tượng nghiệp vụ)');
SELECT pg_temp.expect($q$DELETE FROM ph09_privacy.subject_request$q$, '42501', '135 ứng dụng không xóa phiếu yêu cầu chủ thể (lưu 5 năm)');
SELECT pg_temp.expect($q$DELETE FROM ph09_privacy.consent_record$q$, '42501', '136 ứng dụng không xóa bản ghi đồng ý');
SELECT pg_temp.expect($q$DELETE FROM ph09_privacy.block_label$q$, '42501', '137 ứng dụng không xóa nhãn chặn');
DELETE FROM ph09_privacy.leak_finding;
DELETE FROM ph09_privacy.reveal_grant;
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph09_privacy.reveal_grant$q$, '138 bảng tạm (phiếu xem đầy đủ hết hạn, kết quả rò rỉ) dọn được theo lịch lưu giữ');

RESET ROLE;
SET ROLE dh_report_ro;
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$SELECT identifier_enc FROM ph09_privacy.subject_request$q$, '42501', '139 vai báo cáo không đọc định danh mã hóa của phiếu chủ thể');
SELECT pg_temp.expect($q$SELECT subject_hash FROM ph09_privacy.subject_request$q$, '42501', '140 vai báo cáo không đọc băm chủ thể');
SELECT pg_temp.expect($q$SELECT content FROM ph09_privacy.breach_notification$q$, '42501', '141 vai báo cáo không đọc nội dung thông báo vi phạm');
SELECT pg_temp.expect($q$SELECT token_hash FROM ph09_privacy.reveal_grant$q$, '42501', '142 vai báo cáo không đọc phiếu xem đầy đủ');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM (SELECT status, due_at FROM ph09_privacy.subject_request) x$q$, '143 vai báo cáo đọc được cột trạng thái, hạn của phiếu (đếm quá hạn)');
SELECT pg_temp.is_true($q$SELECT count(*) >= 1 FROM ph09_privacy.purpose_grant$q$, '144 vai báo cáo đọc được chấp thuận của tenant phiên');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.purpose (id, tenant_id, code, name, legal_basis_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'X', 'x', 'STATE_TASK', 'x', 'x')$q$, '42501', '145 vai báo cáo không ghi');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph09_privacy.purpose_grant$q$, '146 vai báo cáo của phiên T91 không thấy chấp thuận T90');

RESET ROLE;
SET ROLE dh_decide_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph09_privacy.purpose_grant WHERE status = 'ACTIVE'$q$, '147 vai data plane đọc được chấp thuận hiệu lực để quyết định');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM (SELECT subject_hash, restriction_active FROM ph09_privacy.subject_request) x$q$, '148 vai data plane tra cờ hạn chế theo băm chủ thể');
SELECT pg_temp.expect($q$SELECT identifier_enc FROM ph09_privacy.subject_request$q$, '42501', '149 vai data plane không đọc định danh mã hóa');
SELECT pg_temp.expect($q$SELECT * FROM ph09_privacy.breach_case$q$, '42501', '150 vai data plane không đọc hồ sơ vi phạm');
SELECT pg_temp.expect($q$UPDATE ph09_privacy.purpose_grant SET quota_per_day = 1$q$, '42501', '151 vai data plane không sửa chấp thuận');
SELECT pg_temp.expect($q$SELECT * FROM ph09_privacy.reidentification_request$q$, '42501', '152 vai data plane không đọc đề nghị khôi phục giá trị gốc');
INSERT INTO ph09_privacy.usage_counter (id, tenant_id, bucket_at, httt_id, purpose_code, contract_kind, contract_id, reporter, denied_count)
VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now() - interval '1 minute'), 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', 'apisix-2', 1);
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph09_privacy.usage_counter$q$, '153 vai data plane ghi được bộ đếm khai thác');
SELECT pg_temp.expect($q$DELETE FROM ph09_privacy.usage_counter$q$, '42501', '154 vai data plane không xóa bộ đếm');
RESET ROLE;
SET ROLE dh_data_app;
SET app.tenant_id = 'T90';

-- ---------- 15. Không lưu giá trị DLCN rõ, không bảng ánh xạ bí danh (BR-09-030, NFR-09-014) ----------
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM information_schema.columns
  WHERE table_schema = 'ph09_privacy' AND column_name ~ '(^|_)(national_id|phone|email|full_name|date_of_birth|address|identifier|pseudonym|token|plaintext|raw)(_|$)'
    AND column_name !~ '(_enc|_hash|_kid|_type|_digest|_count|_code|_kinds?|_ref|_hashes)$'$q$,
  '155 không cột nào tên giá trị DLCN dạng rõ (định danh, điện thoại, thư điện tử, họ tên, bí danh, token)');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM information_schema.columns WHERE table_schema = 'ph09_privacy' AND data_type = 'bytea'
  AND column_name !~ '(_enc|_hash|_digest)$' AND column_name NOT IN ('signature', 'fingerprint', 'content_hash', 'token_hash', 'tokens_digest')$q$,
  '156 cột bytea chỉ là bản mã, băm, chữ ký hoặc dấu vân');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM information_schema.tables WHERE table_schema = 'ph09_privacy' AND table_name ~ '(mapping|pseudonym_map|token_vault|alias)'$q$, '157 không có bảng ánh xạ bí danh với giá trị gốc');
SELECT pg_temp.is_true($q$SELECT count(*) = 55 FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph09_privacy' AND c.relkind IN ('r', 'p') AND NOT c.relispartition$q$, '158 schema có đúng 55 bảng gốc');
SELECT pg_temp.is_true($q$SELECT count(*) = 6 FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph09_privacy' AND c.relkind = 'r' AND c.relispartition$q$, '159 hai bảng phân vùng tháng có 3 phân vùng mỗi bảng');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph09_privacy' AND c.relkind IN ('r', 'p') AND c.relowner <> (SELECT oid FROM pg_roles WHERE rolname = 'ph09_owner')$q$, '160 mọi bảng thuộc ph09_owner (NOLOGIN)');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, request_kind, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', ARRAY['a'], 10, 30, 'Gia hạn chấp thuận nhưng không nêu chấp thuận cần gia hạn', 'ORG', 'RENEWAL', 'x', 'x')$q$, '23514', '161 yêu cầu RENEWAL phải có renews_grant_id');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, request_kind, renews_grant_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', ARRAY['a'], 10, 30, 'Yêu cầu mới không được kèm chấp thuận gia hạn', 'ORG', 'NEW', pg_temp.id('pg1'), 'x', 'x')$q$, '23514', '162 yêu cầu NEW không có renews_grant_id');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, request_kind, renews_grant_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', ARRAY['a'], 10, 30, 'Gia hạn một chấp thuận không có trong hệ thống', 'ORG', 'RENEWAL', gen_random_uuid(), 'x', 'x')$q$, '23503', '163 renews_grant_id phải trỏ tới chấp thuận có thật');
SELECT pg_temp.expect($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, request_kind, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', ARRAY['a'], 10, 30, 'Loại yêu cầu ngoài danh sách AccessRequestKind', 'ORG', 'EXTEND', 'x', 'x')$q$, '23514', '164 request_kind chỉ NEW hoặc RENEWAL');
SELECT pg_temp.is_true($q$INSERT INTO ph09_privacy.access_request (id, tenant_id, httt_id, purpose_code, contract_kind, contract_id, fields, expected_volume, requested_days, justification, owner_org_id, request_kind, renews_grant_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'HT-TUPHAP', 'TTHC-HO-TICH', 'API', 'api-dan-cu-tra-cuu', ARRAY['a'], 10, 30, 'Gia hạn chấp thuận đang hiệu lực của cùng HTTT', 'ORG', 'RENEWAL', pg_temp.id('pg1'), 'x', 'x') RETURNING true$q$, '165 yêu cầu RENEWAL hợp lệ trỏ tới chấp thuận pg1');
RESET ROLE;
\echo 'KẾT QUẢ: toàn bộ khối kiểm thử PASS'
