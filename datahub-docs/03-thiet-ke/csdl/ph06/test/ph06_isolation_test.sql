-- =============================================================================
-- D03-03-PH06 · Kiểm thử DDL ph06_mdm: cô lập tenant, bất biến phiên bản, ngưỡng đối sánh, định danh duy nhất,
-- liên kết nguồn, bốn mắt, lý do ≥ 20 ký tự, SENSITIVE chỉ mã hóa, bảng chỉ thêm, outbox không chứa giá trị,
-- quyền vai trò, khởi tạo tenant.
-- Chạy sau ph06_mdm.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph06_isolation_test.sql
-- Mỗi lệnh pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 42501 quyền/RLS,
-- 55000 bất biến) và ghi PASS; sai thì RAISE dừng tệp. Khối DO kiểm tra đếm. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- Tương ứng nhóm ca cô lập (FR-06 mọi API đọc), BR-06-001, 005…008, 017…024, 031 của D05-02-PH06.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_data_app') THEN
    CREATE ROLE dh_data_app LOGIN NOBYPASSRLS IN ROLE ph06_app;
  ELSE
    GRANT ph06_app TO dh_data_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph06_readonly;
  ELSE
    GRANT ph06_readonly TO dh_report_ro;
  END IF;
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

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['g1','g2','g3','g4','x1','x2','si1','op1','pr1','ev1','es1','ru1','j1','d1','e1','sr1','nr1']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.h(text) RETURNS bytea LANGUAGE sql AS $$ SELECT sha256(convert_to($1, 'UTF8')) $$;
CREATE FUNCTION pg_temp.enc(text) RETURNS bytea LANGUAGE sql AS $$ SELECT '\x01'::bytea || sha256(convert_to($1, 'UTF8')) || sha256(convert_to($1 || 'x', 'UTF8')) $$;

-- ---------- Khởi tạo tenant T90 bằng thủ tục (kiểm tra 19 ở dưới) ----------
SET app.tenant_id = 'T90';
CALL ph06_mdm.p_seed_tenant('T90');

-- ---------- Dữ liệu T90 ----------
INSERT INTO ph06_mdm.mdm_domain (id, tenant_id, domain_code, name, status, baseline, created_by, updated_by)
VALUES (pg_temp.id('d1'), 'T90', 'CITIZEN', 'Công dân', 'DRAFT', true, 'pa', 'pa');
INSERT INTO ph06_mdm.domain_model (id, tenant_id, domain_code, version_no, status, normalization, submitted_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'DRAFT', '{"fullName":"NAME_VN"}', 'an', 'an', 'an');
INSERT INTO ph06_mdm.model_attribute (id, tenant_id, domain_code, version_no, attribute_name, label, attribute_type, matchable, data_class, classification_status, personal_data, legal_basis, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'fullName', 'Họ và tên', 'NAME_VN', true, 'RESTRICTED', 'CONFIRMED', true, 'Luật BVDLCN 91/2025, mục đích quản lý dân cư', 'an', 'an'),
       (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'nationalId', 'Số định danh', 'IDENTIFIER', true, 'SENSITIVE', 'CONFIRMED', true, 'Luật Căn cước', 'an', 'an');
INSERT INTO ph06_mdm.identifier_rule (id, tenant_id, domain_code, version_no, identifier_type, attribute_name, validator, deterministic, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'CCCD_12', 'nationalId', 'CCCD_12', true, 'an', 'an');
UPDATE ph06_mdm.domain_model SET status = 'PENDING_APPROVAL', submitted_at = now() WHERE domain_code = 'CITIZEN';
UPDATE ph06_mdm.domain_model SET status = 'ACTIVE', decision = 'APPROVE', decided_by = 'binh', decided_at = now(), activated_at = now() WHERE domain_code = 'CITIZEN';
UPDATE ph06_mdm.mdm_domain SET status = 'ACTIVE' WHERE domain_code = 'CITIZEN';

INSERT INTO ph06_mdm.mdm_source (id, tenant_id, source_code, name, system_code, source_kind, status, domains, channels, owner_org_code, trust_level, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'QG-DANCU', 'CSDL quốc gia về dân cư qua PH-14', NULL, 'NATIONAL_DB', 'ACTIVE', '{CITIZEN}', '{NATIONAL_SYNC}', 'bo-cong-an', 5, 'an', 'an'),
       (gen_random_uuid(), 'T90', 'HT-YTE', 'Hệ thống y tế', 'HT-YTE', 'SECTOR_RELATED', 'ACTIVE', '{CITIZEN}', '{API,EVENT}', 'so-y-te', 3, 'an', 'an');
INSERT INTO ph06_mdm.golden_record (id, tenant_id, domain_code, model_version, status, confidence, display_name, name_norm, birth_year, admin_unit_code, link_count, created_by, updated_by)
VALUES (pg_temp.id('g1'), 'T90', 'CITIZEN', 1, 'ACTIVE', 0.98, 'Nguyễn Văn An', 'nguyen van an', 1985, '01001', 2, 'system:mdm', 'system:mdm'),
       (pg_temp.id('g2'), 'T90', 'CITIZEN', 1, 'ACTIVE', 0.91, 'Nguyen Van An', 'nguyen van an', 1985, '01001', 1, 'system:mdm', 'system:mdm'),
       (pg_temp.id('g3'), 'T90', 'CITIZEN', 1, 'ACTIVE', 0.90, 'Trần Thị Bình', 'tran thi binh', 1990, '01002', 1, 'system:mdm', 'system:mdm');
INSERT INTO ph06_mdm.golden_attribute (id, tenant_id, golden_id, attribute_name, data_class, value_json, value_enc, value_kid, value_hash, source_code, strategy, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('g1'), 'fullName', 'RESTRICTED', '"Nguyễn Văn An"', NULL, NULL, NULL, 'HT-YTE', 'SOURCE_PRIORITY', 'system:mdm', 'system:mdm'),
       (gen_random_uuid(), 'T90', pg_temp.id('g1'), 'nationalId', 'SENSITIVE', NULL, pg_temp.enc('001085000123'), 'k-mdm-2026', pg_temp.h('001085000123'), 'QG-DANCU', 'NATIONAL_AUTHORITY', 'system:mdm', 'system:mdm');
INSERT INTO ph06_mdm.golden_identifier (id, tenant_id, golden_id, domain_code, identifier_type, value_hash, value_enc, value_kid, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('g1'), 'CITIZEN', 'CCCD_12', pg_temp.h('001085000123'), pg_temp.enc('001085000123'), 'k-mdm-2026', 'system:mdm', 'system:mdm');
INSERT INTO ph06_mdm.source_xref (id, tenant_id, domain_code, golden_id, source_code, source_key, match_method, score, linked_by, created_by, updated_by)
VALUES (pg_temp.id('x1'), 'T90', 'CITIZEN', pg_temp.id('g1'), 'HT-YTE', 'BN-0001', 'DETERMINISTIC', 1, 'system:mdm', 'system:mdm', 'system:mdm');
INSERT INTO ph06_mdm.steward_item (id, tenant_id, domain_code, reason, status, risk_level, left_golden_id, right_golden_id, score, due_at, created_by, updated_by)
VALUES (pg_temp.id('si1'), 'T90', 'CITIZEN', 'POSSIBLE_MATCH', 'OPEN', 'LOW', pg_temp.id('g2'), pg_temp.id('g1'), 0.82, now() + interval '7 days', 'system:mdm', 'system:mdm');
INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, status, risk_level, golden_ids, survivor_id, reason, requested_by, applied_at, created_by, updated_by)
VALUES (pg_temp.id('op1'), 'T90', 'CITIZEN', 'MERGE', 'APPLIED', 'LOW', ARRAY[pg_temp.id('g1'), pg_temp.id('g2')], pg_temp.id('g1'), 'Hai bản ghi cùng CCCD, hợp nhất theo đề nghị DS', 'an', now(), 'an', 'an');
INSERT INTO ph06_mdm.golden_history (id, tenant_id, golden_id, version_no, change_type, operation_id, snapshot_enc, snapshot_kid, snapshot_sha256, changed_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('g1'), 1, 'CREATE', NULL, pg_temp.enc('snap'), 'k-mdm-2026', pg_temp.h('snap'), 'system:mdm');
INSERT INTO ph06_mdm.candidate_record (id, tenant_id, domain_code, source_code, source_key, source_version, source_updated_at, operation, channel, status, raw_enc, raw_kid, name_norm, identifier_type, identifier_status, identifier_hash)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'HT-YTE', 'BN-0001', 1, now(), 'CREATE', 'API', 'NORMALIZED', pg_temp.enc('raw'), 'k-mdm-2026', 'nguyen van an', 'CCCD_12', 'VALID', pg_temp.h('001085000123'));
INSERT INTO ph06_mdm.source_record_head (id, tenant_id, domain_code, source_code, source_key, last_version, last_candidate_id, last_source_updated_at, golden_id, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'HT-YTE', 'BN-0001', 1, gen_random_uuid(), now(), pg_temp.id('g1'), 'system:mdm', 'system:mdm');
INSERT INTO ph06_mdm.access_log (id, tenant_id, actor, system_code, domain_code, golden_id, api_code, purpose_code, attributes, trace_id)
VALUES (gen_random_uuid(), 'T90', 'svc:ht-yte', 'HT-YTE', 'CITIZEN', pg_temp.id('g1'), 'API-06-056', 'kham-benh', '{fullName}', repeat('a', 32));
INSERT INTO ph06_mdm.subject_request (id, tenant_id, request_type, identifier_type, subject_enc, subject_kid, subject_hash, verification_ref, channel, received_at, due_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'ACCESS', 'CCCD_12', pg_temp.enc('001085000123'), 'k-mdm-2026', pg_temp.h('001085000123'), 'VNeID-123', 'PORTAL', now(), now() + interval '14 days', 'ds', 'ds');
INSERT INTO ph06_mdm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
VALUES (gen_random_uuid(), 'T90', 'vn.datahub.mdm.golden.created', 't90.mdm.golden.created.v1', 'golden', pg_temp.id('g1')::text, pg_temp.id('g1')::text, '{"goldenId":"x","version":1,"domain":"CITIZEN"}', repeat('b', 32));

-- ---------- Dữ liệu T91 ----------
SET app.tenant_id = 'T91';
INSERT INTO ph06_mdm.mdm_domain (id, tenant_id, domain_code, name, created_by, updated_by)
VALUES (gen_random_uuid(), 'T91', 'CITIZEN', 'Công dân T91', 'lan', 'lan');

-- 1. Cô lập đọc
DO $$ DECLARE n int; t text; BEGIN
  SELECT count(*) INTO n FROM ph06_mdm.mdm_domain; IF n <> 1 THEN RAISE 'FAIL 1: T91 thấy % domain', n; END IF;
  FOREACH t IN ARRAY ARRAY['domain_model','model_attribute','mdm_source','golden_record','golden_attribute','golden_identifier','source_xref','steward_item',
      'golden_operation','golden_history','candidate_record','source_record_head','access_log','subject_request','outbox_event','tenant_setting','retention_policy','job_schedule'] LOOP
    EXECUTE format('SELECT count(*) FROM ph06_mdm.%I', t) INTO n;
    IF n <> 0 THEN RAISE 'FAIL 1: T91 thấy % dòng của %', n, t; END IF;
  END LOOP;
  RAISE NOTICE 'PASS 1 T91 không đọc được dữ liệu T90 (18 bảng, kể cả bảng phân vùng)';
END $$;

-- 2. Cô lập ghi
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.mdm_domain (id, tenant_id, domain_code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'GIA', 'x', 'lan', 'lan')$q$,
  '42501', '2 chặn chèn dòng tenant T90 từ phiên T91');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.access_log (id, tenant_id, actor, domain_code, api_code, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 'CITIZEN', 'API-06-056', repeat('c', 32))$q$,
  '42501', '2b chặn chèn chéo tenant vào bảng phân vùng access_log');
-- 3. Cô lập sửa, xóa
DO $$ DECLARE n int; BEGIN
  UPDATE ph06_mdm.golden_record SET status = 'LOCKED', lock_reason = 'x' WHERE domain_code = 'CITIZEN';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  DELETE FROM ph06_mdm.candidate_record WHERE tenant_id = 'T90';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3b'; END IF;
  RAISE NOTICE 'PASS 3 không sửa, xóa được dòng tenant khác';
END $$;
-- 4. tenant_id phải dạng Tnn
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.mdm_domain (id, tenant_id, domain_code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'GIA', 'x', 'lan', 'lan')$q$,
  '42501', '4 không có dòng COMMON, tenant phải dạng Tnn');

SET app.tenant_id = 'T90';
-- 5. Mô hình domain: bất biến phiên bản ACTIVE (BR-06-017), một ACTIVE, bốn mắt
SELECT pg_temp.expect($q$UPDATE ph06_mdm.domain_model SET normalization = '{}' WHERE domain_code = 'CITIZEN'$q$, '55000', '5 phiên bản mô hình ACTIVE không đổi quy tắc chuẩn hóa');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.model_attribute (id, tenant_id, domain_code, version_no, attribute_name, label, attribute_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'moi', 'Mới', 'STRING', 'an', 'an')$q$,
  '55000', '5b không thêm thuộc tính vào phiên bản ACTIVE');
SELECT pg_temp.expect($q$DELETE FROM ph06_mdm.identifier_rule WHERE domain_code = 'CITIZEN'$q$, '42501', '5c ứng dụng không xóa khóa định danh (lớp thứ hai: trigger child_frozen)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.domain_model (id, tenant_id, domain_code, version_no, status, decision, decided_by, activated_at, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 2, 'ACTIVE', 'APPROVE', 'binh', now(), 'an', 'an', 'an')$q$,
  '23505', '5d mỗi domain đúng một phiên bản mô hình ACTIVE');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.domain_model (id, tenant_id, domain_code, version_no, status, decision, decided_by, activated_at, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 3, 'PENDING_APPROVAL', NULL, 'an', NULL, 'an', 'an', 'an')$q$,
  '23514', '5e người duyệt khác người gửi (bốn mắt, ERR-06-005)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.domain_model (id, tenant_id, domain_code, version_no, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 4, 'TESTING', 'an', 'an')$q$,
  '23514', '5f mô hình domain không có trạng thái TESTING (4.6)');
INSERT INTO ph06_mdm.domain_model (id, tenant_id, domain_code, version_no, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 5, 'DRAFT', 'an', 'an');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.model_attribute (id, tenant_id, domain_code, version_no, attribute_name, label, attribute_type, personal_data, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 5, 'phone', 'Điện thoại', 'PHONE', true, 'an', 'an')$q$,
  '23514', '6 thuộc tính DLCN cần căn cứ pháp lý (legal_basis)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.model_attribute (id, tenant_id, domain_code, version_no, attribute_name, label, attribute_type, data_class, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 5, 'cccd', 'CCCD', 'IDENTIFIER', 'SENSITIVE', 'an', 'an')$q$,
  '23514', '6b SENSITIVE bắt buộc personal_data');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.model_attribute (id, tenant_id, domain_code, version_no, attribute_name, label, attribute_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 5, 'Bad_Name', 'x', 'STRING', 'an', 'an')$q$,
  '23514', '6c tên thuộc tính camelCase');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.identifier_rule (id, tenant_id, domain_code, version_no, identifier_type, attribute_name, validator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 5, 'MSDN', 'x', 'REGEX', 'an', 'an')$q$,
  '23514', '6d validator REGEX cần pattern');

-- 7. Bộ quy tắc: ngưỡng ba vùng, đánh giá đạt, một ACTIVE (BR-06-020, 021)
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.match_rule_set (id, tenant_id, domain_code, version_no, auto_merge_threshold, review_threshold, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 0.85, 0.50, 'an', 'an')$q$,
  '23514', '7 ngưỡng tự hợp nhất ≥ 0,90');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.match_rule_set (id, tenant_id, domain_code, version_no, auto_merge_threshold, review_threshold, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 0.95, 0.90, 'an', 'an')$q$,
  '23514', '7b ngưỡng tự hợp nhất cao hơn ngưỡng xem xét ≥ 0,10');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.match_rule_set (id, tenant_id, domain_code, version_no, status, decision, decided_by, submitted_by, activated_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'ACTIVE', 'APPROVE', 'binh', 'an', now(), 'an', 'an')$q$,
  '23514', '7c bộ quy tắc ACTIVE phải có báo cáo đánh giá (BR-06-021)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.evaluation_report (id, tenant_id, domain_code, rule_set_version, label_set_code, pair_count, precision_pct, recall_pct, verdict, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 'danh-gia-2026', 800, 99.95, 98.5, 'PASSED', 'an', 'an')$q$,
  '23514', '7d đánh giá đạt cần ≥ 1.000 cặp, precision ≥ 99,9%, recall ≥ 98%');
INSERT INTO ph06_mdm.evaluation_report (id, tenant_id, domain_code, rule_set_version, label_set_code, pair_count, precision_pct, recall_pct, verdict, created_by, updated_by)
VALUES (pg_temp.id('ev1'), 'T90', 'CITIZEN', 1, 'danh-gia-2026', 10000, 99.95, 98.5, 'PASSED', 'an', 'an');
INSERT INTO ph06_mdm.match_rule_set (id, tenant_id, domain_code, version_no, status, evaluation_report_id, decision, decided_by, submitted_by, activated_at, created_by, updated_by)
VALUES (pg_temp.id('ru1'), 'T90', 'CITIZEN', 1, 'ACTIVE', pg_temp.id('ev1'), 'APPROVE', 'binh', 'an', now(), 'an', 'an');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.match_rule_set SET auto_merge_threshold = 0.99 WHERE domain_code = 'CITIZEN' AND version_no = 1$q$, '55000', '7e bộ quy tắc ACTIVE không đổi ngưỡng');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.match_rule_set (id, tenant_id, domain_code, version_no, status, evaluation_report_id, decision, decided_by, submitted_by, activated_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 2, 'ACTIVE', pg_temp.id('ev1'), 'APPROVE', 'binh', 'an', now(), 'an', 'an')$q$,
  '23505', '7f một bộ quy tắc ACTIVE mỗi domain');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.match_rule (id, tenant_id, domain_code, version_no, seq, rule_type, attribute_name, comparator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 1, 1, 'DETERMINISTIC', 'nationalId', 'EXACT', 'an', 'an')$q$,
  '55000', '7g không thêm quy tắc con vào bộ quy tắc ACTIVE');

-- 8. SENSITIVE chỉ mã hóa (BR-06-016, NFR-06-016)
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_attribute (id, tenant_id, golden_id, attribute_name, data_class, value_json, source_code, strategy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g3'), 'nationalId', 'SENSITIVE', '"001090000456"', 'QG-DANCU', 'NATIONAL_AUTHORITY', 'x', 'x')$q$,
  '23514', '8 giá trị SENSITIVE bản rõ bị chặn');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_attribute (id, tenant_id, golden_id, attribute_name, data_class, value_json, value_enc, value_kid, value_hash, source_code, strategy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g3'), 'fullName', 'RESTRICTED', '"x"', pg_temp.enc('x'), 'k', pg_temp.h('x'), 'HT-YTE', 'MOST_RECENT', 'x', 'x')$q$,
  '23514', '8b giá trị không SENSITIVE không có cột mã hóa');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_attribute (id, tenant_id, golden_id, attribute_name, data_class, value_json, source_code, strategy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g3'), 'gender', 'INTERNAL', '"F"', 'HT-YTE', 'MANUAL_OVERRIDE', 'x', 'x')$q$,
  '23514', '8c sửa tay cần hạn manual_valid_until (BR-06-014)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_attribute (id, tenant_id, golden_id, attribute_name, data_class, value_json, source_code, strategy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g1'), 'fullName', 'RESTRICTED', '"dup"', 'HT-YTE', 'MOST_RECENT', 'x', 'x')$q$,
  '23505', '8d một giá trị cho mỗi (bản ghi vàng, thuộc tính, seq)');

-- 9. Định danh duy nhất (BR-06-001, 006, ERR-06-112)
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_identifier (id, tenant_id, golden_id, domain_code, identifier_type, value_hash, value_enc, value_kid, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g2'), 'CITIZEN', 'CCCD_12', pg_temp.h('001085000123'), pg_temp.enc('a'), 'k', 'x', 'x')$q$,
  '23505', '9 hai bản ghi vàng ACTIVE không cùng một CCCD');
UPDATE ph06_mdm.golden_identifier SET active = false WHERE golden_id = pg_temp.id('g1');
INSERT INTO ph06_mdm.golden_identifier (id, tenant_id, golden_id, domain_code, identifier_type, value_hash, value_enc, value_kid, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('g2'), 'CITIZEN', 'CCCD_12', pg_temp.h('001085000123'), pg_temp.enc('a'), 'k', 'x', 'x');
DO $$ BEGIN RAISE NOTICE 'PASS 9b sau khi vô hiệu định danh cũ (hợp nhất), bản ghi vàng sống sót nhận định danh'; END $$;
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_identifier SET value_hash = pg_temp.h('999') WHERE golden_id = pg_temp.id('g2')$q$, '55000', '9c giá trị băm định danh bất biến');

-- 10. Liên kết chéo nguồn (BR-06-018)
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.source_xref (id, tenant_id, domain_code, golden_id, source_code, source_key, match_method, linked_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', pg_temp.id('g2'), 'HT-YTE', 'BN-0001', 'MANUAL', 'an', 'an', 'an')$q$,
  '23505', '10 một bản ghi nguồn chỉ liên kết ACTIVE với một bản ghi vàng');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.source_xref SET status = 'DETACHED', detached_at = now(), detached_by = 'an', detach_reason = 'MANUAL', detach_note = 'ngắn' WHERE id = pg_temp.id('x1')$q$,
  '23514', '10b gỡ liên kết thủ công cần lý do ≥ 20 ký tự (BR-06-008)');
UPDATE ph06_mdm.source_xref SET status = 'DETACHED', detached_at = now(), detached_by = 'an', detach_reason = 'MANUAL', detach_note = 'Nguồn gửi nhầm số hồ sơ bệnh nhân, đã xác minh với bệnh viện' WHERE id = pg_temp.id('x1');
INSERT INTO ph06_mdm.source_xref (id, tenant_id, domain_code, golden_id, source_code, source_key, match_method, linked_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', pg_temp.id('g2'), 'HT-YTE', 'BN-0001', 'MANUAL', 'an', 'an', 'an');
DO $$ BEGIN RAISE NOTICE 'PASS 10c sau khi gỡ, nguồn liên kết lại với bản ghi vàng khác'; END $$;

-- 11. Bản ghi vàng: không xóa, MERGED cần merged_into, RETIRED cần lý do
SELECT pg_temp.expect($q$DELETE FROM ph06_mdm.golden_record WHERE id = pg_temp.id('g3')$q$, '42501', '11 ứng dụng không xóa bản ghi vàng (BR-06-007)');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_record SET status = 'MERGED' WHERE id = pg_temp.id('g3')$q$, '23514', '11b MERGED cần merged_into');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_record SET status = 'MERGED', merged_into = id WHERE id = pg_temp.id('g3')$q$, '23514', '11c không hợp nhất vào chính nó');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_record SET status = 'RETIRED' WHERE id = pg_temp.id('g3')$q$, '23514', '11d RETIRED cần lý do ngừng');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_record SET domain_code = 'ORGANIZATION' WHERE id = pg_temp.id('g3')$q$, '55000', '11e domain của bản ghi vàng bất biến');
DO $$ DECLARE v int; BEGIN
  UPDATE ph06_mdm.golden_record SET status = 'MERGED', merged_into = pg_temp.id('g1') WHERE id = pg_temp.id('g2');
  SELECT version INTO v FROM ph06_mdm.golden_record WHERE id = pg_temp.id('g2');
  IF v <> 2 THEN RAISE 'FAIL 11f version = % (mong 2: tạo 1, hợp nhất 2)', v; END IF;
  RAISE NOTICE 'PASS 11f version bản ghi vàng bắt đầu 1, tăng mỗi thay đổi (ETag, số phiên bản lịch sử)';
END $$;

-- 12. Thao tác trên bản ghi vàng
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, golden_ids, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'MANUAL_EDIT', ARRAY[pg_temp.id('g1')], 'ngắn', 'an', 'an', 'an')$q$,
  '23514', '12 lý do thao tác ≥ 20 ký tự (BR-06-008, ERR-06-007)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, status, risk_level, golden_ids, survivor_id, reason, requested_by, approved_by, decision, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'MERGE', 'PENDING_APPROVAL', 'HIGH', ARRAY[pg_temp.id('g1'), pg_temp.id('g3')], pg_temp.id('g1'), 'Hai bản ghi cùng người, đã đối chiếu giấy tờ gốc', 'an', 'an', 'APPROVE', 'an', 'an')$q$,
  '23514', '12b người duyệt khác người yêu cầu (ERR-06-005)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, status, risk_level, golden_ids, survivor_id, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'MERGE', 'PENDING_APPROVAL', 'LOW', ARRAY[pg_temp.id('g1'), pg_temp.id('g3')], pg_temp.id('g1'), 'Hai bản ghi cùng người, đã đối chiếu giấy tờ gốc', 'an', 'an', 'an')$q$,
  '23514', '12c chờ duyệt chỉ cho thao tác rủi ro cao (BR-06-019)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, golden_ids, reason, requested_by, applied_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'MERGE', ARRAY[pg_temp.id('g1')], 'Hợp nhất chỉ có một bản ghi, không hợp lệ', 'an', now(), 'an', 'an')$q$,
  '23514', '12d hợp nhất cần 2…10 bản ghi và bản sống sót');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, golden_ids, reason, requested_by, applied_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'UNDO', ARRAY[pg_temp.id('g1')], 'Hoàn tác thao tác hợp nhất nhầm theo đề nghị', 'an', now(), 'an', 'an')$q$,
  '23514', '12e hoàn tác phải trỏ thao tác gốc undo_of');
INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, golden_ids, reason, requested_by, applied_at, undo_of, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'UNDO', ARRAY[pg_temp.id('g1')], 'Hoàn tác thao tác hợp nhất nhầm theo đề nghị', 'an', now(), pg_temp.id('op1'), 'an', 'an');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_operation (id, tenant_id, domain_code, change_type, golden_ids, reason, requested_by, applied_at, undo_of, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'UNDO', ARRAY[pg_temp.id('g1')], 'Hoàn tác lần hai cùng thao tác gốc, không hợp lệ', 'an', now(), pg_temp.id('op1'), 'an', 'an')$q$,
  '23505', '12f mỗi thao tác chỉ hoàn tác một lần');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_operation SET reason = 'Đổi lý do sau khi áp dụng thao tác, không được phép' WHERE id = pg_temp.id('op1')$q$, '55000', '12g lý do và danh sách bản ghi của thao tác bất biến');

-- 13. Hàng đợi
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.steward_item (id, tenant_id, domain_code, reason, left_golden_id, right_golden_id, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'POSSIBLE_MATCH', pg_temp.id('g2'), pg_temp.id('g1'), now(), 'x', 'x')$q$,
  '23505', '13 mỗi cặp chỉ một mục hàng đợi đang mở');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.steward_item SET status = 'RESOLVED', decision = 'NO_MATCH', decision_reason = 'ngắn', decided_by = 'an', decided_at = now() WHERE id = pg_temp.id('si1')$q$,
  '23514', '13b quyết định cần lý do ≥ 20 ký tự (BR-06-008)');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.steward_item SET status = 'PENDING_APPROVAL', assignee = 'an', decision = 'MATCH', decided_by = 'an', decision_reason = 'Cùng người, trùng ngày sinh và địa chỉ thường trú' WHERE id = pg_temp.id('si1')$q$,
  '23514', '13c chờ duyệt chỉ với rủi ro cao');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.steward_item SET status = 'ASSIGNED', risk_level = 'HIGH' WHERE id = pg_temp.id('si1')$q$, '23514', '13d mục ASSIGNED cần người nhận');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.steward_item SET approved_by = 'an', decided_by = 'an' WHERE id = pg_temp.id('si1')$q$, '23514', '13e DA không tự duyệt quyết định của mình');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.steward_item SET right_golden_id = pg_temp.id('g3') WHERE id = pg_temp.id('si1')$q$, '55000', '13f cặp của mục hàng đợi bất biến');

-- 14. Lịch sử, nhật ký chỉ thêm (BR-06-005, RB-06-04)
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_history SET change_type = 'UPDATE'$q$, '42501', '14 ứng dụng không sửa lịch sử bản ghi vàng');
SELECT pg_temp.expect($q$DELETE FROM ph06_mdm.access_log$q$, '42501', '14b ứng dụng không xóa nhật ký truy cập');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_history (id, tenant_id, golden_id, version_no, change_type, snapshot_enc, snapshot_kid, snapshot_sha256, changed_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g1'), 0, 'UPDATE', pg_temp.enc('s'), 'k', pg_temp.h('s'), 'x')$q$,
  '23514', '14c số phiên bản lịch sử ≥ 1');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.golden_history (id, tenant_id, golden_id, version_no, change_type, snapshot_enc, snapshot_kid, snapshot_sha256, changed_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('g1'), 2, 'UPDATE', '\x00'::bytea, 'k', pg_temp.h('s'), 'x')$q$,
  '23514', '14d ảnh chụp phải là bản mã envelope (độ dài tối thiểu)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.access_log (id, tenant_id, actor, domain_code, api_code, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 'CITIZEN', 'API-6-56', repeat('c', 32))$q$,
  '23514', '15 api_code đúng dạng API-06-nnn');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.access_log (id, tenant_id, actor, domain_code, api_code, unmasked, unmask_reason, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 'CITIZEN', 'API-06-056', '{nationalId}', 'ngắn', repeat('c', 32))$q$,
  '23514', '15b xem bản không che cần lý do ≥ 20 ký tự');
DO $$ DECLARE n int; p text; BEGIN
  SELECT count(*) INTO n FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhparent JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph06_mdm' AND c.relname = 'access_log';
  IF n < 3 THEN RAISE 'FAIL 15c: % phân vùng access_log', n; END IF;
  SELECT tableoid::regclass::text INTO p FROM ph06_mdm.access_log LIMIT 1;
  IF p !~ 'access_log_[0-9]{6}$' THEN RAISE 'FAIL 15c: dòng không nằm ở phân vùng tháng (%)', p; END IF;
  RAISE NOTICE 'PASS 15c bảng nhật ký phân vùng tháng (% phân vùng), dòng nằm ở %', n, p;
END $$;

-- 16. Outbox: không chứa giá trị thuộc tính (BR-06-012), topic đúng EVT, tiền tố tenant
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'vn.datahub.mdm.golden.updated', 't90.mdm.golden.updated.v1', 'golden', 'g', 'g', '{"attributes":{"fullName":"A"}}', repeat('b', 32))$q$,
  '23514', '16 sự kiện không chứa giá trị thuộc tính (BR-06-012)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'vn.datahub.mdm.golden.created', 't91.mdm.golden.created.v1', 'golden', 'g', 'g', '{}', repeat('b', 32))$q$,
  '23514', '16b tiền tố topic phải là tenant của dòng');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'x', 't90.mdm.golden.deleted.v1', 'golden', 'g', 'g', '{}', repeat('b', 32))$q$,
  '23514', '16c chỉ 15 topic EVT-06-01…15 và audit');

-- 17. Job: một job đang chạy mỗi (domain, loại), lỗi cần mã (ERR-06-025, 101…114)
INSERT INTO ph06_mdm.match_job (id, tenant_id, domain_code, job_type, status, requested_by, created_by, updated_by)
VALUES (pg_temp.id('j1'), 'T90', 'CITIZEN', 'BATCH_MATCH', 'RUNNING', 'an', 'an', 'an');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.match_job (id, tenant_id, domain_code, job_type, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'BATCH_MATCH', 'QUEUED', 'an', 'an', 'an')$q$,
  '23505', '17 một job BATCH_MATCH đang chạy mỗi domain (ERR-06-025)');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.match_job SET status = 'FAILED', finished_at = now() WHERE id = pg_temp.id('j1')$q$, '23514', '17b job FAILED cần mã lỗi ERR-06-1nn');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.match_job SET confirmed_by = 'an' WHERE id = pg_temp.id('j1')$q$, '23514', '17c người xác nhận job khác người yêu cầu (BR-06-022)');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.match_job SET job_type = 'RETENTION_PURGE' WHERE id = pg_temp.id('j1')$q$, '55000', '17d loại job bất biến');
UPDATE ph06_mdm.match_job SET status = 'FAILED', error_code = 'ERR-06-102', finished_at = now() WHERE id = pg_temp.id('j1');
INSERT INTO ph06_mdm.match_job (id, tenant_id, domain_code, job_type, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'BATCH_MATCH', 'QUEUED', 'an', 'an', 'an');
DO $$ BEGIN RAISE NOTICE 'PASS 17e job cũ kết thúc thì tạo được job mới'; END $$;

-- 18. Lưu giữ, tham số
SELECT pg_temp.expect($q$UPDATE ph06_mdm.retention_policy SET retention_days = 90 WHERE object_type = 'access_log'$q$, '23514', '18 nhật ký truy cập giữ tối thiểu 365 ngày (ERR-06-049)');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.retention_policy SET legal_hold = true WHERE object_type = 'candidate_record'$q$, '23514', '18b giữ pháp lý cần lý do (ERR-06-114)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '06.khong-co', '1', 'x', 'x')$q$, '23514', '18c khóa tham số ngoài FRS 8.2');

-- 19. Khởi tạo tenant: đủ 13 tham số, 10 chính sách, 5 lịch; chạy lại không nhân bản
CALL ph06_mdm.p_seed_tenant('T90');
DO $$ DECLARE a int; b int; c int; BEGIN
  SELECT count(*) INTO a FROM ph06_mdm.tenant_setting; SELECT count(*) INTO b FROM ph06_mdm.retention_policy; SELECT count(*) INTO c FROM ph06_mdm.job_schedule;
  IF a <> 13 OR b <> 10 OR c <> 5 THEN RAISE 'FAIL 19: % tham số, % chính sách, % lịch', a, b, c; END IF;
  RAISE NOTICE 'PASS 19 p_seed_tenant: 13 tham số, 10 chính sách lưu giữ, 5 lịch job, chạy lại không nhân bản';
END $$;

-- 20. Ứng viên: dedup theo nguồn, chỉ mục pg_trgm, độ dài băm
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.candidate_record (id, tenant_id, domain_code, source_code, source_key, source_version, source_updated_at, operation, channel, identifier_hash) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'HT-YTE', 'BN-0002', 1, now(), 'CREATE', 'API', '\x1234'::bytea)$q$,
  '23514', '20 băm định danh dài 32 byte');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.candidate_record (id, tenant_id, domain_code, source_code, source_key, source_version, source_updated_at, operation, channel, status) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'HT-YTE', 'BN-0002', 1, now(), 'CREATE', 'API', 'REJECTED')$q$,
  '23514', '20b ứng viên REJECTED cần mã lỗi ERR-06-0nn');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.candidate_record (id, tenant_id, domain_code, source_code, source_key, source_version, source_updated_at, operation, channel, status) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'HT-YTE', 'BN-0002', 1, now(), 'REPLACE', 'API', 'RECEIVED')$q$,
  '23514', '20c operation theo CandidateOperation');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.source_record_head (id, tenant_id, domain_code, source_code, source_key, last_version, last_candidate_id, last_source_updated_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'HT-YTE', 'BN-0001', 2, gen_random_uuid(), now(), 'x', 'x')$q$,
  '23505', '20d mỗi bản ghi nguồn một dòng trạng thái mới nhất (BR-06-028, 029)');
DO $$ DECLARE n int; BEGIN
  SET LOCAL enable_seqscan = off;
  SELECT count(*) INTO n FROM ph06_mdm.golden_record WHERE domain_code = 'CITIZEN' AND name_norm % 'nguyen van ann';
  IF n < 1 THEN RAISE 'FAIL 20e: pg_trgm không tìm thấy gần đúng'; END IF;
  RAISE NOTICE 'PASS 20e truy vấn gần đúng pg_trgm trên golden_record.name_norm (% dòng)', n;
END $$;

-- 21. Đồng bộ quốc gia, xuất, yêu cầu chủ thể
INSERT INTO ph06_mdm.national_sync_run (id, tenant_id, domain_code, direction, requested_by, checked_count, discrepancy_count, ratio, created_by, updated_by)
VALUES (pg_temp.id('nr1'), 'T90', 'CITIZEN', 'RECONCILE', 'an', 100, 6, 0.06, 'an', 'an');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.national_sync_run (id, tenant_id, domain_code, direction, requested_by, checked_count, discrepancy_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'DOWN', 'an', 5, 9, 'an', 'an')$q$,
  '23514', '21 số lệch không vượt số đã kiểm');
INSERT INTO ph06_mdm.national_discrepancy (id, tenant_id, run_id, domain_code, golden_id, attribute_name, severity, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('nr1'), 'CITIZEN', pg_temp.id('g1'), 'dateOfBirth', 'CRITICAL', 'system:mdm', 'system:mdm');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.national_discrepancy (id, tenant_id, run_id, domain_code, golden_id, attribute_name, severity, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('nr1'), 'CITIZEN', pg_temp.id('g1'), 'dateOfBirth', 'MINOR', 'x', 'x')$q$,
  '23505', '21b một lệch OPEN mỗi (bản ghi vàng, thuộc tính)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.national_sync_state (id, tenant_id, domain_code, state, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'PAUSED', 'x', 'x')$q$, '23514', '21d PAUSED cần paused_at và lý do (BR-06-011)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.export_request (id, tenant_id, domain_code, fields, format, purpose_code, legal_basis, recipient, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', '{fullName}', 'CSV', 'thong-ke', 'NĐ 278/2025', 'So KH&CN', 'READY', 'an', 'an', 'an')$q$,
  '23514', '22 tệp xuất READY cần tệp, mã thủy vân, hạn tải (BR-06-027)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.export_request (id, tenant_id, domain_code, fields, format, purpose_code, legal_basis, recipient, status, requested_by, approved_by, owner_approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', '{fullName}', 'CSV', 'thong-ke', 'NĐ 278/2025', 'So KH&CN', 'APPROVED', 'an', 'an', 'cuong', 'an', 'an')$q$,
  '23514', '22b người đề nghị xuất không tự chấp thuận (BR-06-027)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.subject_request (id, tenant_id, request_type, identifier_type, subject_enc, subject_kid, subject_hash, verification_ref, channel, received_at, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'ACCESS', 'CCCD_12', pg_temp.enc('x'), 'k', '\x00'::bytea, 'v', 'PORTAL', now(), now(), 'x', 'x')$q$,
  '23514', '23 yêu cầu chủ thể: băm định danh 32 byte');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.source_priority_proposal (id, tenant_id, domain_code, entries, approval_ref, justification, status, proposed_by, decided_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', '[{"sourceCode":"QG-DANCU","priority":1}]', 'QĐ 12/QĐ-UBND', 'Căn cứ văn bản', 'ACTIVE', 'an', 'an', 'an', 'an')$q$,
  '23514', '24 duyệt thứ tự ưu tiên nguồn bốn mắt (BR-06-004)');

-- 25. Enum theo Phụ lục A
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_record SET status = 'DELETED' WHERE id = pg_temp.id('g3')$q$, '23514', '25 GoldenStatus không có DELETED (BR-06-007)');
SELECT pg_temp.expect($q$INSERT INTO ph06_mdm.mdm_source (id, tenant_id, source_code, name, source_kind, domains, channels, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HT-KHAC', 'x', 'SECTOR_OTHER', '{CITIZEN}', '{SFTP}', 'x', 'x', 'x')$q$,
  '23514', '25b kênh nạp theo IngestChannel');

-- 26. Quyền vai trò báo cáo
RESET ROLE;
SET ROLE dh_report_ro;
SET app.tenant_id = 'T90';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph06_mdm.golden_record; IF n < 1 THEN RAISE 'FAIL 26'; END IF;
  RAISE NOTICE 'PASS 26 vai trò chỉ đọc thấy bản ghi vàng của tenant phiên';
END $$;
SELECT pg_temp.expect($q$SELECT * FROM ph06_mdm.golden_identifier$q$, '42501', '26b vai trò chỉ đọc không đọc chỉ mục định danh mã hóa');
SELECT pg_temp.expect($q$SELECT snapshot_enc FROM ph06_mdm.golden_history$q$, '42501', '26c vai trò chỉ đọc không đọc ảnh chụp lịch sử');
SELECT pg_temp.expect($q$SELECT criteria_hash FROM ph06_mdm.access_log$q$, '42501', '26d vai trò chỉ đọc không đọc cột băm tiêu chí của nhật ký truy cập');
SELECT pg_temp.expect($q$UPDATE ph06_mdm.golden_record SET status = 'LOCKED'$q$, '42501', '26e vai trò chỉ đọc không ghi');
RESET ROLE;
DO $$ BEGIN RAISE NOTICE 'Hoàn tất: mọi khối PASS'; END $$;
