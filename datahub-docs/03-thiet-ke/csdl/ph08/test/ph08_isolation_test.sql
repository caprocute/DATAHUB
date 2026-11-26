-- =============================================================================
-- D03-03-PH08 · Kiểm thử DDL ph08_dq: cô lập tenant (RLS), mẫu RLS dùng chung COMMON, ràng buộc enum và nghiệp vụ,
-- bất biến phiên bản, bảng chỉ thêm, một lần đo đang chạy, một phiếu mở mỗi nhóm, không lưu giá trị gốc trường Nhạy cảm,
-- phân vùng và chuyển phân vùng, outbox, quyền vai trò, khởi tạo tenant.
-- Chạy sau ph08_dq.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph08_isolation_test.sql
-- Mỗi lệnh pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại, 42501 quyền hoặc RLS,
-- 55000 bất biến) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- =============================================================================
\set ON_ERROR_STOP on
\o /dev/null
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_data_app') THEN
    CREATE ROLE dh_data_app LOGIN NOBYPASSRLS IN ROLE ph08_app;
  ELSE
    GRANT ph08_app TO dh_data_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph08_readonly;
  ELSE
    GRANT ph08_readonly TO dh_report_ro;
  END IF;
  GRANT ph08_owner TO CURRENT_USER;
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
CREATE FUNCTION pg_temp.eq(p_actual bigint, p_expected bigint, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_actual IS DISTINCT FROM p_expected THEN RAISE EXCEPTION 'FAIL %: được %, mong %', p_label, p_actual, p_expected; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['d1','a1','a2','f1','rs1','v1','r1','r2','j1','j2','sn1','fi1','is1','w1','ar1','al1','rp1','ex1','pr1','pc1','tp1','x1']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.h(text) RETURNS bytea LANGUAGE sql AS $$ SELECT sha256(convert_to($1, 'UTF8')) $$;

-- ---------- 1. Khởi tạo tenant T90, T91 bằng thủ tục ----------
SET app.tenant_id = 'T90';
CALL ph08_dq.p_seed_tenant('T90');
CALL ph08_dq.p_seed_tenant('T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_tenant_setting), 43, 'seed T90: 43 tham số, chạy lại không nhân bản');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_retention_policy), 12, 'seed T90: 12 chính sách lưu giữ');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_weight_config WHERE status = 'ACTIVE'), 1, 'seed T90: trọng số mặc định ACTIVE');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_schedule), 1, 'seed T90: lịch đo tháng');
SELECT pg_temp.eq((SELECT retention_days FROM ph08_dq.dq_retention_policy WHERE object_type = 'dq_finding'), 395, 'bản ghi lỗi giữ 13 tháng (395 ngày)');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template WHERE tenant_id = 'COMMON'), 12, 'T90 đọc được 12 quy tắc mẫu COMMON');
SET app.tenant_id = 'T91';
CALL ph08_dq.p_seed_tenant('T91');
SET app.tenant_id = 'T90';

-- ---------- 2. Dữ liệu T90 ----------
INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, status, created_by, updated_by)
VALUES (pg_temp.id('d1'), 'T90', 'CITIZEN', 'Dân cư', 'SO-NOI-VU', 'ACTIVE', 'an', 'an');
INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, status, owner_org_code, mdm_domain_code, key_columns, created_by, updated_by)
VALUES (pg_temp.id('a1'), 'T90', 'CITIZEN', 'mdm-citizen', 'Bản ghi vàng công dân', 'MDM_DOMAIN', 'ACTIVE', 'SO-NOI-VU', 'CITIZEN', '{golden_id}', 'an', 'an');
INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, status, owner_org_code, connection_id, object_name, default_scan_mode, sample_ratio, created_by, updated_by)
VALUES (pg_temp.id('a2'), 'T90', 'CITIZEN', 'src-hotich', 'Bảng hộ tịch', 'SOURCE_DATASET', 'ACTIVE', 'SO-TU-PHAP', gen_random_uuid(), 'hotich.khai_sinh', 'SAMPLE', 0.1, 'an', 'an');
INSERT INTO ph08_dq.dq_asset_field (id, tenant_id, asset_id, field_name, cde, data_class, classification_status, value_mode, created_by, updated_by)
VALUES (pg_temp.id('f1'), 'T90', pg_temp.id('a1'), 'nationalId', true, 'SENSITIVE', 'CONFIRMED', 'HASH_ONLY', 'an', 'an'),
       (gen_random_uuid(), 'T90', pg_temp.id('a1'), 'fullName', false, 'RESTRICTED', 'CONFIRMED', 'MASKED', 'an', 'an');
INSERT INTO ph08_dq.dq_rule_set (id, tenant_id, set_code, name, asset_id, created_by, updated_by)
VALUES (pg_temp.id('rs1'), 'T90', 'citizen-core', 'Bộ quy tắc công dân', pg_temp.id('a1'), 'an', 'an');
INSERT INTO ph08_dq.dq_rule_set_version (id, tenant_id, rule_set_id, version_no, status, created_by, updated_by)
VALUES (pg_temp.id('v1'), 'T90', pg_temp.id('rs1'), 1, 'DRAFT', 'an', 'an');
INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, severity, exec_mode, inline_mode, field_name, params, created_by, updated_by)
VALUES (pg_temp.id('r1'), 'T90', pg_temp.id('v1'), 'cccd-not-null', 'CCCD không rỗng', 'COMPLETENESS', 'NOT_NULL', 'CRITICAL', 'BOTH', 'STRICT', 'nationalId', '{}', 'an', 'an'),
       (pg_temp.id('r2'), 'T90', pg_temp.id('v1'), 'gender-in-rdm', 'Giới tính theo danh mục', 'VALIDITY', 'IN_RDM', 'MAJOR', 'BOTH', 'ADVISORY', 'gender', '{"catalogCode":"GIOI-TINH"}', 'an', 'an');
UPDATE ph08_dq.dq_rule_set_version SET status = 'PENDING_APPROVAL', submitted_by = 'an', submitted_at = now(), content_hash = pg_temp.h('v1'), rule_count = 2, last_dry_run_id = gen_random_uuid(), dry_run_content_hash = pg_temp.h('v1-effect'), dry_run_at = now() WHERE id = pg_temp.id('v1');
UPDATE ph08_dq.dq_rule_set_version SET status = 'ACTIVE', decision = 'APPROVE', decided_by = 'binh', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('v1');
INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, started_at, created_by, updated_by)
VALUES (pg_temp.id('j1'), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'SCHEDULE', 'FULL', 'RUNNING', '2026-11', 'scheduler', now(), 'scheduler', 'scheduler');
INSERT INTO ph08_dq.dq_scan_task (id, tenant_id, scan_job_id, shard_no, shard_count, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), 0, 4, 'scheduler', 'scheduler');
INSERT INTO ph08_dq.dq_rule_result (id, tenant_id, scan_job_id, asset_id, rule_id, dimension, severity, status, rows_evaluated, rows_failed, pass_rate, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'CRITICAL', 'FAILED', 1000, 12, 0.988, 'worker', 'worker');
UPDATE ph08_dq.dq_scan_job SET status = 'SUCCEEDED', finished_at = now(), rows_scanned = 1000, rows_failed = 12, task_total = 4, task_done = 4 WHERE id = pg_temp.id('j1');
INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, rule_set_version_id, created_by, updated_by)
VALUES (pg_temp.id('sn1'), 'T90', pg_temp.id('j1'), pg_temp.id('a1'), 'CITIZEN', 'SO-NOI-VU', '2026-11', 'FULL', 91.50, 'PASS', pg_temp.id('v1'), 'worker', 'worker');
INSERT INTO ph08_dq.dq_score_dimension (id, tenant_id, snapshot_id, dimension, status, score, weight, rules_total, rules_passed, rules_failed, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('sn1'), 'COMPLETENESS', 'MEASURED', 98.8, 0.20, 1, 0, 1, 'worker', 'worker'),
       (gen_random_uuid(), 'T90', pg_temp.id('sn1'), 'TIMELINESS', 'SKIPPED', NULL, 0.10, 0, 0, 0, 'worker', 'worker');
INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, record_key_masked, field_name, data_class, value_mode, masked_value, value_hash,
                                owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by)
VALUES (pg_temp.id('fi1'), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'CRITICAL', pg_temp.h('fp1'), pg_temp.h('key1'), NULL, 'nationalId', 'SENSITIVE', 'HASH_ONLY', NULL, pg_temp.h('val1'),
        'SO-NOI-VU', pg_temp.id('j1'), pg_temp.id('j1'), 'worker', 'worker'),
       (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r2'), 'VALIDITY', 'MAJOR', pg_temp.h('fp2'), pg_temp.h('key2'), '0123****', 'fullName', 'RESTRICTED', 'MASKED', 'Ng*** V** A', pg_temp.h('val2'),
        'SO-NOI-VU', pg_temp.id('j1'), pg_temp.id('j1'), 'worker', 'worker');
INSERT INTO ph08_dq.dq_issue (id, tenant_id, issue_code, asset_id, rule_id, group_key, title, severity, finding_count, owner_org_code, sla_days, sla_due_at, created_by, updated_by)
VALUES (pg_temp.id('is1'), 'T90', 'DQ-2026-000001', pg_temp.id('a1'), pg_temp.id('r1'), 'mdm-citizen|cccd-not-null|SO-NOI-VU', 'CCCD trống ở 12 bản ghi', 'CRITICAL', 12, 'SO-NOI-VU', 5, now() + interval '7 days', 'an', 'an');
INSERT INTO ph08_dq.dq_issue_activity (id, tenant_id, issue_id, activity_type, actor, to_status, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('is1'), 'CREATED', 'an', 'OPEN', 'an', 'an');
INSERT INTO ph08_dq.dq_alert_rule (id, tenant_id, alert_rule_code, name, condition_type, threshold, created_by, updated_by)
VALUES (pg_temp.id('ar1'), 'T90', 'score-below-80', 'Điểm dưới 80', 'SCORE_BELOW', 80, 'an', 'an');
INSERT INTO ph08_dq.dq_alert (id, tenant_id, alert_rule_id, asset_id, severity, dedup_key, message, created_by, updated_by)
VALUES (pg_temp.id('al1'), 'T90', pg_temp.id('ar1'), pg_temp.id('a1'), 'HIGH', 'score-below-80|mdm-citizen', 'Điểm mdm-citizen xuống 78', 'system', 'system');
INSERT INTO ph08_dq.dq_report (id, tenant_id, report_code, report_type, period_code, title, created_by, updated_by)
VALUES (pg_temp.id('rp1'), 'T90', 'BC-DQ-2026-11-T90', 'PERIODIC', '2026-11', 'Báo cáo tháng 11/2026', 'an', 'an');
INSERT INTO ph08_dq.dq_inline_stat (id, tenant_id, bucket_at, asset_id, caller_code, mode, check_count, pass_count, fail_count, error_count, p50_ms, p95_ms, max_ms, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()), pg_temp.id('a1'), 'flow-hotich', 'ADVISORY', 100, 95, 5, 0, 8, 31, 44, 'inline', 'inline');
INSERT INTO ph08_dq.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'MdmGoldenChanged', gen_random_uuid(), 't90.mdm.golden.updated.v1');

-- ---------- 3. Cô lập tenant ----------
SET app.tenant_id = 'T91';
INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'CITIZEN', 'Dân cư T91', 'SO-X', 'zz', 'zz');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_domain), 1, 'T91 chỉ thấy miền của mình');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 0, 'T91 không thấy đối tượng đo của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding), 0, 'T91 không thấy bản ghi lỗi của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_result), 0, 'T91 không thấy kết quả quy tắc của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_inline_stat), 0, 'T91 không thấy thống kê trực tuyến của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_issue) + (SELECT count(*) FROM ph08_dq.dq_report) + (SELECT count(*) FROM ph08_dq.dq_alert) + (SELECT count(*) FROM ph08_dq.inbox_event), 0, 'T91 không thấy phiếu, báo cáo, cảnh báo, inbox của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_set_version) + (SELECT count(*) FROM ph08_dq.dq_rule) + (SELECT count(*) FROM ph08_dq.dq_score_snapshot), 0, 'T91 không thấy phiên bản quy tắc, quy tắc, snapshot của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_tenant_setting), 43, 'T91 chỉ thấy 43 tham số của mình');
UPDATE ph08_dq.dq_asset SET name = 'tấn công' WHERE id = pg_temp.id('a1');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 0, 'T91 UPDATE đối tượng T90 không có tác dụng (0 dòng)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LAND', 'x', 'SO-X', 'zz', 'zz')$$, '42501', 'T91 không ghi được dòng mang tenant T90');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, owner_org_code, mdm_domain_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'LAND', 'x-asset', 'x', 'MDM_DOMAIN', 'SO-X', 'LAND', 'zz', 'zz')$$, '23503', 'khóa ngoại (tenant_id, domain_code): miền không tồn tại trong tenant');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset_field (id, tenant_id, asset_id, field_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('a1'), 'x', 'zz', 'zz')$$, '23503', 'khóa ngoại kèm tenant: T91 không trỏ được tới đối tượng đo của T90');

-- Quên đặt biến phiên: không thấy dòng nào (chuỗi rỗng không khớp tenant nào)
RESET app.tenant_id;
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 0, 'không đặt app.tenant_id thì không thấy dòng nào');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LAND', 'x', 'SO-X', 'zz', 'zz')$$, '42501', 'không đặt app.tenant_id thì không ghi được');

-- Mẫu RLS S: quy tắc mẫu COMMON
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template), 12, 'T90 đọc 12 mẫu COMMON');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule_template (id, tenant_id, template_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'X-MAU', 'x', 'VALIDITY', 'REGEX', 'an', 'an')$$, '42501', 'tenant thường không ghi được dòng COMMON');
UPDATE ph08_dq.dq_rule_template SET name = 'sửa trộm' WHERE tenant_id = 'COMMON';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template WHERE name = 'sửa trộm'), 0, 'tenant thường không sửa được mẫu COMMON (0 dòng)');
INSERT INTO ph08_dq.dq_rule_template (id, tenant_id, template_code, name, dimension, operator, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'RIENG-T90', 'Mẫu riêng T90', 'COMPLETENESS', 'NOT_NULL', 'an', 'an');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template), 13, 'T90 thêm được mẫu riêng, thấy 13');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template), 12, 'T91 không thấy mẫu riêng của T90');
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template), 12, 'PLATFORM thấy mẫu COMMON, không thấy mẫu riêng tenant');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 0, 'PLATFORM không đọc được dữ liệu đo của tenant');
INSERT INTO ph08_dq.dq_rule_template (id, tenant_id, template_code, name, dimension, operator, created_by, updated_by)
VALUES (gen_random_uuid(), 'COMMON', 'X-MAU-MOI', 'Mẫu mới', 'VALIDITY', 'REGEX', 'pa', 'pa');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_rule_template), 13, 'PLATFORM ghi được dòng COMMON');
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, owner_org_code, mdm_domain_code, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'CITIZEN', 'x', 'x', 'MDM_DOMAIN', 'x', 'CITIZEN', 'a', 'a')$$, '42501', 'bảng nghiệp vụ không nhận tenant COMMON');

-- ---------- 4. Enum và ràng buộc nghiệp vụ ----------
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BAD', 'x', 'SO-X', 'DELETED', 'a', 'a')$$, '23514', 'enum asset_status sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, on_dependency_failure, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BAD', 'x', 'SO-X', 'FAIL_SOFT', 'a', 'a')$$, '23514', 'enum on_dependency_failure sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'trùng', 'SO-X', 'a', 'a')$$, '23505', 'mã miền duy nhất trong tenant');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SUSP', 'x', 'SO-X', 'SUSPENDED', 'a', 'a')$$, '23514', 'ngừng miền phải có lý do ≥ 20 ký tự');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'bad1', 'x', 'MDM_DOMAIN', 'SO-X', 'a', 'a')$$, '23514', 'đối tượng MDM_DOMAIN thiếu mdm_domain_code');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, owner_org_code, connection_id, object_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'bad2', 'x', 'RDM_CATALOG', 'SO-X', gen_random_uuid(), 'a.b', 'a', 'a')$$, '23514', 'đối tượng RDM_CATALOG không được mang kết nối nguồn');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset (id, tenant_id, domain_code, asset_code, name, asset_type, owner_org_code, flow_code, default_scan_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'CITIZEN', 'bad3', 'x', 'FLOW_MESSAGE', 'SO-X', 'flow-a', 'SAMPLE', 'a', 'a')$$, '23514', 'chế độ SAMPLE phải có sample_ratio');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset_field (id, tenant_id, asset_id, field_name, data_class, value_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), 'taxCode', 'SENSITIVE', 'MASKED', 'a', 'a')$$, '23514', 'trường SENSITIVE bắt buộc HASH_ONLY');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_asset_field (id, tenant_id, asset_id, field_name, data_class, value_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), 'address', 'RESTRICTED', 'PLAIN', 'a', 'a')$$, '23514', 'trường RESTRICTED không được PLAIN');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_profile_run (id, tenant_id, asset_id, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), 'SUCCEEDED', 'a', 'a', 'a')$$, '23514', 'lần hồ sơ SUCCEEDED phải có finished_at');
INSERT INTO ph08_dq.dq_profile_run (id, tenant_id, asset_id, status, requested_by, finished_at, created_by, updated_by) VALUES (pg_temp.id('pr1'), 'T90', pg_temp.id('a1'), 'SUCCEEDED', 'a', now(), 'a', 'a');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_profile_column (id, tenant_id, profile_run_id, asset_id, field_name, sensitive, row_count, top_values, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pr1'), pg_temp.id('a1'), 'nationalId', true, 100, '["012345678901"]', 'a', 'a')$$, '23514', 'hồ sơ cột Nhạy cảm không được lưu giá trị mẫu');
INSERT INTO ph08_dq.dq_profile_column (id, tenant_id, profile_run_id, asset_id, field_name, sensitive, row_count, null_count, distinct_estimate, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('pr1'), pg_temp.id('a1'), 'nationalId', true, 100, 2, 98, 'a', 'a');

-- Quy tắc, toán tử với chiều, CEL, trực tuyến
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule_set_version (id, tenant_id, rule_set_id, version_no, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rs1'), 1, 'a', 'a')$$, '23505', 'số phiên bản duy nhất trong bộ quy tắc');
INSERT INTO ph08_dq.dq_rule_set_version (id, tenant_id, rule_set_id, version_no, status, created_by, updated_by) VALUES (pg_temp.id('x1'), 'T90', pg_temp.id('rs1'), 2, 'DRAFT', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad1', 'x', 'VALIDITY', 'NOT_NULL', 'a', 'a')$$, '23514', 'NOT_NULL chỉ thuộc COMPLETENESS');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad2', 'x', 'COMPLETENESS', 'IN_RDM', 'a', 'a')$$, '23514', 'IN_RDM chỉ thuộc VALIDITY');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, params, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad3', 'x', 'VALIDITY', 'IN_RDM', '{}', 'a', 'a')$$, '23514', 'IN_RDM phải có catalogCode');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad4', 'x', 'CONSISTENCY', 'CEL_EXPRESSION', 'a', 'a')$$, '23514', 'CEL_EXPRESSION phải có expression');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, expression, exec_mode, inline_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad5', 'x', 'ACCURACY', 'SQL_PREDICATE', 'a > 0', 'INLINE', 'STRICT', 'a', 'a')$$, '23514', 'SQL_PREDICATE chỉ chạy theo lô');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, exec_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad6', 'x', 'COMPLETENESS', 'NOT_NULL', 'INLINE', 'a', 'a')$$, '23514', 'quy tắc trực tuyến phải có inline_mode');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, severity, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad7', 'x', 'COMPLETENESS', 'NOT_NULL', 'BLOCKER', 'a', 'a')$$, '23514', 'enum severity sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad8', 'x', 'COMPLETENESS', 'EXISTS', 'a', 'a')$$, '23514', 'enum operator sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-bad9', 'x', 'FRESHNESS', 'NOT_NULL', 'a', 'a')$$, '23514', 'enum dimension sai (chỉ sáu chiều)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v1'), 'r-late', 'x', 'COMPLETENESS', 'NOT_NULL', 'a', 'a')$$, '55000', 'không thêm quy tắc vào phiên bản ACTIVE');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule SET severity = 'MINOR' WHERE id = pg_temp.id('r1')$$, '55000', 'không sửa quy tắc của phiên bản ACTIVE');
INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, exec_mode, inline_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('x1'), 'r-ok', 'ok', 'UNIQUENESS', 'UNIQUE_IN_ASSET', 'BOTH', 'ADVISORY', 'an', 'an');

-- Phiên bản: bốn mắt, ACTIVE, bất biến, một ACTIVE mỗi bộ
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET status = 'PENDING_APPROVAL', submitted_by = 'an', submitted_at = now(), content_hash = pg_temp.h('x1'), rule_count = 1 WHERE id = pg_temp.id('x1')$$, '23514', 'gửi duyệt phải có dấu chạy thử (dry_run_content_hash, dry_run_at)');
UPDATE ph08_dq.dq_rule_set_version SET status = 'PENDING_APPROVAL', submitted_by = 'an', submitted_at = now(), content_hash = pg_temp.h('x1'), rule_count = 1, dry_run_content_hash = pg_temp.h('x1-effect'), dry_run_at = now() WHERE id = pg_temp.id('x1');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET status = 'ACTIVE', decision = 'APPROVE', decided_by = 'an', activated_at = now() WHERE id = pg_temp.id('x1')$$, '23514', 'bốn mắt: người duyệt phải khác người gửi duyệt');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET status = 'ACTIVE', decision = 'APPROVE', decided_by = 'binh' WHERE id = pg_temp.id('x1')$$, '23514', 'ACTIVE phải có activated_at');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET status = 'ACTIVE', decision = 'APPROVE', decided_by = 'binh', activated_at = now() WHERE id = pg_temp.id('x1')$$, '23505', 'mỗi bộ quy tắc chỉ một phiên bản ACTIVE');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET decision = 'REJECT', decided_by = 'binh', decision_comment = 'ngắn' WHERE id = pg_temp.id('x1')$$, '23514', 'từ chối phải có lý do ≥ 20 ký tự');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET content_hash = pg_temp.h('khac') WHERE id = pg_temp.id('v1')$$, '55000', 'phiên bản ACTIVE bất biến nội dung (content_hash)');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_set_version SET version_no = 9 WHERE id = pg_temp.id('x1')$$, '55000', 'version_no bất biến');

-- Cấu hình trọng số
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, w_completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W-BAD', 0.50, 'a', 'a')$$, '23514', 'tổng trọng số khác 1,000 (ngoài dung sai 0,001)');
INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, w_completeness, w_accuracy, w_consistency, w_timeliness, w_uniqueness, w_validity, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'W-OK', 0.2005, 0.2, 0.15, 0.1, 0.15, 0.1995, 'a', 'a');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, pass_min, warn_min, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W-BAD2', 70, 80, 'a', 'a')$$, '23514', 'warn_min không được lớn hơn pass_min');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, status, activated_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W-DUP', 'ACTIVE', now(), 'a', 'a')$$, '23505', 'phạm vi tenant chỉ một cấu hình trọng số ACTIVE');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_weight_config SET w_completeness = 0.25, w_validity = 0.15 WHERE config_code = 'DEFAULT'$$, '55000', 'trọng số ACTIVE bất biến');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, version_no, domain_code, asset_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W-BAD3', 1, 'CITIZEN', pg_temp.id('a1'), 'a', 'a')$$, '23514', 'cấu hình trọng số chỉ một phạm vi (miền hoặc đối tượng)');

-- Lịch, lần đo
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_schedule (id, tenant_id, schedule_code, cron, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bad-cron', 'mỗi ngày', 'a', 'a')$$, '23514', 'cron sai cú pháp');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'ANNUAL', 'SAMPLE', 'QUEUED', '2026', 'a', 'a', 'a')$$, '23514', 'đo chính thức hằng năm bắt buộc FULL');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, period_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'VERIFY', 'FULL', '2026-11', 'a', 'a', 'a')$$, '23514', 'trigger VERIFY phải gắn phiếu khắc phục');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, period_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'EVENT', 'FULL', '2026-11', 'a', 'a', 'a')$$, '23514', 'trigger EVENT phải có source_event_id và INCREMENTAL');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, period_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'MANUAL', 'FULL', '11/2026', 'a', 'a', 'a')$$, '23514', 'period_code sai dạng');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'MANUAL', 'FULL', 'DONE', '2026-11', 'a', 'a', 'a')$$, '23514', 'enum scan_status sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'MANUAL', 'FULL', 'CANCELLED', '2026-11', 'a', 'a', 'a')$$, '23514', 'hủy lần đo phải có lý do và thời điểm kết thúc');
INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, started_at, sample_size, created_by, updated_by) VALUES (pg_temp.id('j2'), 'T90', pg_temp.id('a2'), pg_temp.id('v1'), 'MANUAL', 'SAMPLE', 'RUNNING', '2026-11', 'an', now(), 1000, 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, started_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a2'), pg_temp.id('v1'), 'MANUAL', 'FULL', 'RUNNING', '2026-11', 'an', now(), 'an', 'an')$$, '23505', 'mỗi đối tượng chỉ một lần đo RUNNING');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, period_code, requested_by, idempotency_key, idempotency_hash, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'MANUAL', 'FULL', '2026-11', 'an', 'k1', pg_temp.h('b1'), 'an', 'an'), (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('v1'), 'MANUAL', 'FULL', '2026-11', 'an', 'k1', pg_temp.h('b1'), 'an', 'an')$$, '23505', 'Idempotency-Key trùng không tạo hai lần đo');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_scan_job SET period_code = '2026-10' WHERE id = pg_temp.id('j1')$$, '55000', 'kỳ đo bất biến');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_scan_task SET shard_no = 9 WHERE scan_job_id = pg_temp.id('j1')$$, '23514', 'shard_no phải nhỏ hơn shard_count');

-- Kết quả quy tắc: chỉ thêm
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule_result (id, tenant_id, scan_job_id, asset_id, rule_id, dimension, severity, status, rows_evaluated, rows_failed, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', 'FAILED', 10, 11, 'w', 'w')$$, '23514', 'số dòng lỗi không vượt số dòng xét');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule_result (id, tenant_id, scan_job_id, asset_id, rule_id, dimension, severity, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), pg_temp.id('a1'), pg_temp.id('r2'), 'VALIDITY', 'MAJOR', 'SKIPPED', 'w', 'w')$$, '23514', 'kết quả SKIPPED phải có skip_reason');
INSERT INTO ph08_dq.dq_rule_result (id, tenant_id, scan_job_id, asset_id, rule_id, dimension, severity, status, skip_reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), pg_temp.id('a1'), pg_temp.id('r2'), 'VALIDITY', 'MAJOR', 'SKIPPED', 'RDM_UNAVAILABLE', 'w', 'w');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_result SET status = 'PASSED' WHERE tenant_id = 'T90'$$, '42501', 'ứng dụng không UPDATE được dq_rule_result (quyền)');
SELECT pg_temp.expect($$DELETE FROM ph08_dq.dq_rule_result WHERE tenant_id = 'T90'$$, '42501', 'ứng dụng không DELETE được dq_rule_result (quyền)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule_result (id, tenant_id, scan_job_id, asset_id, rule_id, dimension, severity, status, rows_evaluated, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', 'PASSED', 1, 'w', 'w')$$, '23503', 'khóa ngoại tới lần đo trên bảng phân vùng');

-- Snapshot, điểm
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j2'), pg_temp.id('a2'), 'CITIZEN', 'SO-X', '2026-11', 'FULL', 101, 'PASS', pg_temp.id('v1'), 'w', 'w')$$, '23514', 'điểm nằm trong 0 đến 100');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j2'), pg_temp.id('a2'), 'CITIZEN', 'SO-X', '2026-11', 'FULL', 90, 'GOOD', pg_temp.id('v1'), 'w', 'w')$$, '23514', 'enum verdict sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, flags, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j2'), pg_temp.id('a2'), 'CITIZEN', 'SO-X', '2026-11', 'FULL', 90, 'PASS', '{STALE}', pg_temp.id('v1'), 'w', 'w')$$, '23514', 'cờ snapshot ngoài INCOMPLETE_DIMENSIONS, WEIGHTS_CHANGED');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, flags, official, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j2'), pg_temp.id('a2'), 'CITIZEN', 'SO-X', '2026-11', 'FULL', 90, 'PASS', '{INCOMPLETE_DIMENSIONS}', true, pg_temp.id('v1'), 'w', 'w')$$, '23514', 'snapshot chính thức không được có cờ INCOMPLETE_DIMENSIONS');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, official, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j2'), pg_temp.id('a2'), 'CITIZEN', 'SO-X', '2026-11', 'SAMPLE', 90, 'PASS', true, pg_temp.id('v1'), 'w', 'w')$$, '23514', 'snapshot chính thức phải đo FULL');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, trend, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j2'), pg_temp.id('a2'), 'CITIZEN', 'SO-X', '2026-11', 'FULL', 90, 'PASS', 'IMPROVED', pg_temp.id('v1'), 'w', 'w')$$, '23514', 'xu hướng khác BASELINE phải có snapshot kỳ trước');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, rule_set_version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), pg_temp.id('a1'), 'CITIZEN', 'SO-X', '2026-11', 'FULL', 90, 'PASS', pg_temp.id('v1'), 'w', 'w')$$, '23505', 'mỗi lần đo một snapshot');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_score_snapshot SET score = 99 WHERE id = pg_temp.id('sn1')$$, '55000', 'điểm của snapshot bất biến');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_dimension (id, tenant_id, snapshot_id, dimension, status, score, weight, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('sn1'), 'VALIDITY', 'SKIPPED', 50, 0.2, 'w', 'w')$$, '23514', 'chiều SKIPPED phải có điểm rỗng');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_dimension (id, tenant_id, snapshot_id, dimension, status, score, weight, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('sn1'), 'COMPLETENESS', 'MEASURED', 50, 0.2, 'w', 'w')$$, '23505', 'mỗi snapshot một dòng cho mỗi chiều');

-- Thống kê trực tuyến theo phút
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_inline_stat (id, tenant_id, bucket_at, asset_id, caller_code, check_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', now(), pg_temp.id('a1'), 'x', 1, 'i', 'i')$$, '23514', 'bucket_at phải làm tròn theo phút');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_inline_stat (id, tenant_id, bucket_at, asset_id, caller_code, mode, check_count, fail_count, warn_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()) - interval '3 minute', pg_temp.id('a1'), 'x', 'STRICT', 10, 5, 2, 'i', 'i')$$, '23514', 'chế độ STRICT không có warn_count (chỉ ADVISORY cảnh báo)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_inline_stat (id, tenant_id, bucket_at, asset_id, caller_code, mode, check_count, fail_count, blocked_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()) - interval '1 minute', pg_temp.id('a1'), 'x', 'ADVISORY', 10, 5, 3, 'i', 'i')$$, '23514', 'chế độ ADVISORY không chặn bản ghi (blocked_count = 0)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_inline_stat (id, tenant_id, bucket_at, asset_id, caller_code, mode, check_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()), pg_temp.id('a1'), 'flow-hotich', 'ADVISORY', 1, 'i', 'i')$$, '23505', 'mỗi phút một dòng theo (đối tượng, bên gọi, chế độ)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_inline_stat (id, tenant_id, bucket_at, asset_id, caller_code, mode, check_count, p50_ms, p95_ms, max_ms, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', date_trunc('minute', now()) - interval '2 minute', pg_temp.id('a1'), 'x', 'STRICT', 1, 30, 20, 40, 'i', 'i')$$, '23514', 'p95 không nhỏ hơn p50');

-- ---------- 5. Bản ghi lỗi: không lưu giá trị gốc, dấu vân tay, phân vùng ----------
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, data_class, value_mode, masked_value, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', pg_temp.h('z1'), pg_temp.h('z1k'), 'SENSITIVE', 'HASH_ONLY', '012345678901', 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'trường SENSITIVE không có masked_value');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, data_class, value_mode, masked_value, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', pg_temp.h('z2'), pg_temp.h('z2k'), 'SENSITIVE', 'MASKED', NULL, 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'trường SENSITIVE chỉ được value_mode HASH_ONLY');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, data_class, value_mode, masked_value, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', pg_temp.h('z3'), pg_temp.h('z3k'), 'RESTRICTED', 'PLAIN', 'Nguyễn Văn A', 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'trường RESTRICTED không lưu giá trị rõ (PLAIN)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', 'ngan'::bytea, pg_temp.h('z4k'), 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'fingerprint phải đúng 32 byte');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, status, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', pg_temp.h('z5'), pg_temp.h('z5k'), 'IN_REMEDIATION', 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'lỗi IN_REMEDIATION phải gắn phiếu khắc phục');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, status, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', pg_temp.h('z6'), pg_temp.h('z6k'), 'WAIVED', 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'lỗi WAIVED phải gắn ngoại lệ');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_finding (id, tenant_id, asset_id, rule_id, dimension, severity, fingerprint, record_key_hash, status, owner_org_code, first_scan_job_id, last_scan_job_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r1'), 'COMPLETENESS', 'MAJOR', pg_temp.h('z7'), pg_temp.h('z7k'), 'FIXED', 'SO-X', pg_temp.id('j1'), pg_temp.id('j1'), 'w', 'w')$$, '23514', 'enum finding.status sai');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_finding SET fingerprint = pg_temp.h('doi') WHERE id = pg_temp.id('fi1')$$, '55000', 'fingerprint bất biến');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_finding SET data_class = 'PUBLIC', value_mode = 'PLAIN' WHERE id = pg_temp.id('fi1')$$, '55000', 'không hạ phân loại dữ liệu của bản ghi lỗi (data_class bất biến)');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding WHERE fingerprint = pg_temp.h('fp1')), 1, 'tra bản ghi lỗi theo dấu vân tay');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding WHERE asset_id = pg_temp.id('a1') AND status = 'OPEN'), 2, 'tra bản ghi lỗi theo đối tượng và trạng thái');
-- Chuyển phân vùng khi thấy lại ở kỳ sau
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding_202611 WHERE id = pg_temp.id('fi1')), 1, 'bản ghi lỗi nằm ở phân vùng tháng hiện tại');
UPDATE ph08_dq.dq_finding SET last_seen_at = now() + interval '1 month', seen_count = seen_count + 1 WHERE id = pg_temp.id('fi1');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding_202612 WHERE id = pg_temp.id('fi1')), 1, 'thấy lại ở kỳ sau: dòng chuyển sang phân vùng tháng sau');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding WHERE tenant_id = 'T90'), 2, 'chuyển phân vùng không nhân bản dòng');
SELECT pg_temp.eq((SELECT version FROM ph08_dq.dq_finding WHERE id = pg_temp.id('fi1')), 1, 'version tăng khi cập nhật bản ghi lỗi');

-- ---------- 6. Ngoại lệ, phiếu khắc phục ----------
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_waiver (id, tenant_id, asset_id, rule_id, scope, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r2'), 'RULE_FILTER', 'đủ dài nhưng phạm vi RULE_FILTER thiếu điều kiện lọc', 'an', 'an', 'an')$$, '23514', 'ngoại lệ RULE_FILTER phải có quy tắc và filter');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_waiver (id, tenant_id, asset_id, rule_id, scope, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r2'), 'ALL', 'đủ dài nhưng phạm vi không thuộc enum waiver.scope', 'an', 'an', 'an')$$, '23514', 'enum waiver.scope sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_waiver (id, tenant_id, asset_id, rule_id, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r2'), 'ngắn', 'an', 'an', 'an')$$, '23514', 'lý do ngoại lệ ≥ 20 ký tự');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_waiver (id, tenant_id, asset_id, rule_id, reason, requested_by, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('r2'), 'Nguồn đang chờ nâng cấp, chấp nhận tạm thời', 'an', current_date, current_date + 400, 'an', 'an')$$, '23514', 'ngoại lệ có hạn không quá 366 ngày');
INSERT INTO ph08_dq.dq_waiver (id, tenant_id, asset_id, rule_id, reason, requested_by, created_by, updated_by) VALUES (pg_temp.id('w1'), 'T90', pg_temp.id('a1'), pg_temp.id('r2'), 'Nguồn đang chờ nâng cấp, chấp nhận tạm thời', 'an', 'an', 'an');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_waiver SET status = 'ACTIVE', decided_by = 'an', decided_at = now(), valid_from = current_date, valid_to = current_date + 90 WHERE id = pg_temp.id('w1')$$, '23514', 'bốn mắt: DA duyệt ngoại lệ khác người đề nghị');
UPDATE ph08_dq.dq_waiver SET status = 'ACTIVE', decided_by = 'binh', decided_at = now(), valid_from = current_date, valid_to = current_date + 90 WHERE id = pg_temp.id('w1');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_waiver SET reason = 'đổi lý do sau khi duyệt, vẫn đủ dài' WHERE id = pg_temp.id('w1')$$, '55000', 'lý do ngoại lệ bất biến sau khi tạo');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_issue (id, tenant_id, issue_code, asset_id, group_key, title, severity, owner_org_code, sla_days, sla_due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'DQ-2026-000002', pg_temp.id('a1'), 'mdm-citizen|cccd-not-null|SO-NOI-VU', 't', 'CRITICAL', 'SO-NOI-VU', 5, now(), 'an', 'an')$$, '23505', 'mỗi nhóm lỗi chỉ một phiếu đang mở');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_issue (id, tenant_id, issue_code, asset_id, group_key, title, severity, owner_org_code, sla_days, sla_due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'DQ-2026', pg_temp.id('a1'), 'k', 't', 'CRITICAL', 'SO-X', 5, now(), 'an', 'an')$$, '23514', 'mã phiếu sai dạng');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_issue (id, tenant_id, issue_code, asset_id, group_key, title, severity, owner_org_code, sla_days, sla_due_at, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'DQ-2026-000003', pg_temp.id('a1'), 'k3', 't', 'URGENT', 'SO-X', 5, now(), 'OPEN', 'an', 'an')$$, '23514', 'enum severity của phiếu sai');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue SET status = 'VERIFIED' WHERE id = pg_temp.id('is1')$$, '23514', 'VERIFIED phải có lần đo lại kiểm chứng');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue SET status = 'REJECTED', reject_reason = 'ngắn' WHERE id = pg_temp.id('is1')$$, '23514', 'từ chối phiếu phải có lý do ≥ 20 ký tự');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue SET status = 'ASSIGNED' WHERE id = pg_temp.id('is1')$$, '23514', 'ASSIGNED phải có assigned_at');
UPDATE ph08_dq.dq_issue SET status = 'ASSIGNED', assigned_at = now(), assignee = 'chuyenvien1' WHERE id = pg_temp.id('is1');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue SET owner_org_code = 'SO-KHAC' WHERE id = pg_temp.id('is1')$$, '55000', 'tổ chức chủ quản của phiếu bất biến (chuyển phiếu tạo phiếu mới)');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue_activity SET comment = 'sửa' WHERE tenant_id = 'T90'$$, '42501', 'ứng dụng không UPDATE hoạt động phiếu (quyền)');
SELECT pg_temp.expect($$DELETE FROM ph08_dq.dq_issue_activity WHERE tenant_id = 'T90'$$, '42501', 'ứng dụng không DELETE hoạt động phiếu (quyền)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_issue_activity (id, tenant_id, issue_id, activity_type, actor, from_status, to_status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('is1'), 'STATUS_CHANGE', 'an', 'OPEN', 'OPEN', 'an', 'an')$$, '23514', 'đổi trạng thái phải khác trạng thái cũ');
SELECT pg_temp.expect($$DELETE FROM ph08_dq.dq_issue WHERE tenant_id = 'T90'$$, '42501', 'phiếu khắc phục không bị xóa (quyền)');
SELECT pg_temp.expect($$DELETE FROM ph08_dq.dq_asset WHERE tenant_id = 'T90'$$, '42501', 'đối tượng đo không bị xóa (quyền)');

-- ---------- 7. Cảnh báo, báo cáo, xuất ----------
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_alert_rule (id, tenant_id, alert_rule_code, name, condition_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'no-threshold', 'x', 'SCORE_BELOW', 'a', 'a')$$, '23514', 'điều kiện điểm phải có ngưỡng');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_alert (id, tenant_id, alert_rule_id, severity, dedup_key, message, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ar1'), 'HIGH', 'score-below-80|mdm-citizen', 'trùng cảnh báo đang mở', 'a', 'a')$$, '23505', 'khử trùng cảnh báo đang mở theo dedup_key');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_alert SET status = 'SILENCED', silenced_until = now() + interval '1 day', silence_reason = 'ngắn' WHERE id = pg_temp.id('al1')$$, '23514', 'tắt tiếng cảnh báo phải có lý do ≥ 20 ký tự');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_alert SET status = 'ACKNOWLEDGED' WHERE id = pg_temp.id('al1')$$, '23514', 'xác nhận cảnh báo phải có người và thời điểm');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_alert SET status = 'PAUSED' WHERE id = pg_temp.id('al1')$$, '23514', 'enum alert.status sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_report (id, tenant_id, report_code, report_type, period_code, title, incomplete_snapshot_count, snapshot_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BC-DQ-2026-NAM-T90', 'ANNUAL', '2026', 'Báo cáo năm', 2, 10, 'a', 'a')$$, '23514', 'báo cáo chính thức hằng năm không dùng snapshot thiếu chiều');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_report (id, tenant_id, report_code, report_type, period_code, title, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BC-DQ-2026-AH03-T90', 'ANNUAL', '2026-11', 'Báo cáo năm', 'a', 'a')$$, '23514', 'báo cáo ANNUAL có kỳ là năm');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_report (id, tenant_id, report_code, report_type, period_code, title, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BC-DQ-2026-AH04-T90', 'WEEKLY', '2026-11', 'x', 'a', 'a')$$, '23514', 'enum report_type sai');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_report SET status = 'PUBLISHED', published_by = 'an', published_at = now() WHERE id = pg_temp.id('rp1')$$, '23514', 'công bố phải có người duyệt, mã băm, tệp PDF');
UPDATE ph08_dq.dq_report SET status = 'IN_REVIEW', submitted_by = 'an', submitted_at = now(), snapshot_count = 1 WHERE id = pg_temp.id('rp1');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_report SET status = 'PUBLISHED', reviewed_by = 'an', published_by = 'binh', published_at = now(), content_sha256 = pg_temp.h('rp'), pdf_object_key = 'dq-reports/T90/2026-11.pdf' WHERE id = pg_temp.id('rp1')$$, '23514', 'bốn mắt: người duyệt báo cáo khác người soạn');
UPDATE ph08_dq.dq_report SET status = 'PUBLISHED', reviewed_by = 'binh', reviewed_at = now(), published_by = 'binh', published_at = now(), content_sha256 = pg_temp.h('rp'), pdf_object_key = 'dq-reports/T90/2026-11.pdf' WHERE id = pg_temp.id('rp1');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_report SET summary = '{"score":1}' WHERE id = pg_temp.id('rp1')$$, '55000', 'báo cáo đã công bố bất biến nội dung');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_report SET status = 'WITHDRAWN', withdrawn_reason = 'ngắn' WHERE id = pg_temp.id('rp1')$$, '23514', 'thu hồi báo cáo phải có lý do ≥ 20 ký tự');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_report_subscription (id, tenant_id, report_type, recipient_type, recipient_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PERIODIC', 'GROUP', 'x', 'a', 'a')$$, '23514', 'loại người nhận đăng ký sai');
INSERT INTO ph08_dq.dq_report_subscription (id, tenant_id, report_type, recipient_type, recipient_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PERIODIC', 'ROLE', 'DS', 'a', 'a');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_report_subscription (id, tenant_id, report_type, recipient_type, recipient_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PERIODIC', 'ROLE', 'DS', 'a', 'a')$$, '23505', 'đăng ký nhận báo cáo không trùng');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_export_request (id, tenant_id, requested_by, contains_restricted, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'an', true, 'APPROVED', 'an', 'an')$$, '23514', 'xuất có trường Nhạy cảm, Hạn chế phải có DO chấp thuận');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_export_request (id, tenant_id, requested_by, status, object_key, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'an', 'READY', 'dq-exports/x.csv', 'an', 'an')$$, '23514', 'tệp xuất READY phải có hạn tải, thủy vân, SHA-256');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_export_request (id, tenant_id, requested_by, decided_by, contains_restricted, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'an', 'an', true, 'APPROVED', 'an', 'an')$$, '23514', 'bốn mắt: DO chấp thuận khác người yêu cầu xuất');

-- ---------- 8. Tham số, lưu giữ, outbox, inbox ----------
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '08.khong.co', '1', 'a', 'a')$$, '23514', 'khóa tham số ngoài danh sách 08.*');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '08.waiver.max-days', '20', 'a', 'a')$$, '23505', 'mỗi khóa tham số một dòng trong tenant');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_retention_policy SET retention_days = 365 WHERE object_type = 'dq_report'$$, '23514', 'báo cáo giữ tối thiểu 1095 ngày');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_retention_policy SET action = 'WIPE' WHERE object_type = 'dq_alert'$$, '23514', 'hành động lưu giữ ngoài danh sách');
INSERT INTO ph08_dq.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.dq.scan.completed.v1', 'scan', pg_temp.id('j1'), '{"scanId":"x","score":91.5}', md5('t')::char(32));
SELECT pg_temp.expect($$INSERT INTO ph08_dq.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.dq.scan.deleted.v1', 'scan', gen_random_uuid(), '{}', md5('t')::char(32))$$, '23514', 'outbox chỉ nhận topic EVT-08 đã khai báo');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't91.dq.scan.completed.v1', 'scan', gen_random_uuid(), '{}', md5('t')::char(32))$$, '23514', 'topic outbox phải mang tiền tố đúng tenant');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.dq.finding.opened.v1', 'finding', gen_random_uuid(), '{"maskedValue":"0123****"}', md5('t')::char(32))$$, '23514', 'sự kiện không chứa giá trị bản ghi lỗi (maskedValue)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.dq.kpi.published.v1', 'kpi', gen_random_uuid(), '{}', 'khongphailahex')$$, '23514', 'trace_id phải là 32 ký tự hex');
SELECT pg_temp.expect($$UPDATE ph08_dq.outbox_event SET topic = 't90.dq.scan.failed.v1'$$, '42501', 'ứng dụng không UPDATE outbox (quyền)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'MdmGoldenChanged', (SELECT event_id FROM ph08_dq.inbox_event LIMIT 1), 't90.mdm.golden.updated.v1')$$, '23505', 'inbox khử trùng theo (consumer, event_id)');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'MdmGoldenChanged', gen_random_uuid(), 't91.mdm.golden.updated.v1')$$, '23514', 'inbox: topic nguồn phải đúng tiền tố tenant');

-- ---------- 8b. Bổ sung bản 0.2: cấu hình đối tượng, tác vụ, tăng dần, ngoại lệ, xuất, lưu giữ, so sánh liên tenant ----------
INSERT INTO ids VALUES ('j3', gen_random_uuid());
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'OFF1', 'x', 'x', 'DRAFT', 'a', 'a')$$, '23514', 'domain_status chỉ ACTIVE, INACTIVE');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'OFF2', 'x', 'x', 'INACTIVE', 'a', 'a')$$, '23514', 'miền INACTIVE phải có lý do ≥ 20 ký tự');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_asset SET inline_enabled = true WHERE id = pg_temp.id('a1')$$, '23514', 'bật trực tuyến phải có inline_mode');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_asset SET inline_enabled = true, inline_mode = 'ADVISORY', gate_enabled = true WHERE id = pg_temp.id('a2')$$, '23514', 'cổng chất lượng chỉ cho MDM_DOMAIN');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_asset SET incremental_enabled = true WHERE id = pg_temp.id('a2')$$, '23514', 'đo tăng dần SOURCE_DATASET cần updated_at_field');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_asset SET inline_timeout_ms = 5 WHERE id = pg_temp.id('a1')$$, '23514', 'ngân sách trực tuyến 10 đến 50 ms');
UPDATE ph08_dq.dq_asset SET inline_enabled = true, inline_mode = 'STRICT', on_dependency_failure = 'FAIL_CLOSED', gate_enabled = true, incremental_enabled = true WHERE id = pg_temp.id('a1');
UPDATE ph08_dq.dq_asset SET incremental_enabled = true, updated_at_field = 'updated_at' WHERE id = pg_temp.id('a2');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset WHERE incremental_enabled), 2, 'bật đo tăng dần cho MDM_DOMAIN và SOURCE_DATASET có updated_at_field');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W-APP', 'APPROVED', 'a', 'a')$$, '23514', 'cấu hình trọng số không có trạng thái APPROVED');
INSERT INTO ph08_dq.dq_rule_set_version (id, tenant_id, rule_set_id, version_no, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rs1'), 70, 'DRAFT', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule_set_version (id, tenant_id, rule_set_id, version_no, status, decision, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rs1'), 71, 'APPROVED', 'APPROVE', 'an', 'an')$$, '23514', 'APPROVED phải có dấu chạy thử và effective_from');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, source, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', (SELECT id FROM ph08_dq.dq_rule_set_version WHERE version_no = 70), 'r-src1', 'x', 'COMPLETENESS', 'NOT_NULL', 'AUTO', 'a', 'a')$$, '23514', 'enum rule.source sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, source, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', (SELECT id FROM ph08_dq.dq_rule_set_version WHERE version_no = 70), 'r-src2', 'x', 'COMPLETENESS', 'NOT_NULL', 'TEMPLATE', 'a', 'a')$$, '23514', 'quy tắc nguồn TEMPLATE phải có template_code');
INSERT INTO ph08_dq.dq_rule (id, tenant_id, rule_set_version_id, rule_code, name, dimension, operator, source, template_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', (SELECT id FROM ph08_dq.dq_rule_set_version WHERE version_no = 70), 'r-src3', 'từ mẫu', 'COMPLETENESS', 'NOT_NULL', 'TEMPLATE', 'NOT-NULL-CDE', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_task (id, tenant_id, scan_job_id, shard_no, shard_count, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), 1, 4, 'RUNNING', 's', 's')$$, '23514', 'tác vụ RUNNING phải có worker_id và heartbeat_at');
INSERT INTO ph08_dq.dq_scan_task (id, tenant_id, scan_job_id, shard_no, shard_count, status, worker_id, heartbeat_at, not_before, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('j1'), 1, 4, 'RUNNING', 'worker-1', now(), now() + interval '5 minutes', 's', 's');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_scan_task WHERE status = 'RUNNING' AND heartbeat_at IS NOT NULL), 1, 'tác vụ RUNNING có nhịp heartbeat và not_before');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, period_code, requested_by, flags, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a2'), pg_temp.id('v1'), 'MANUAL', 'FULL', '2026-11', 'an', '{BAD}', 'an', 'an')$$, '23514', 'cờ lần đo ngoài bốn giá trị');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, period_code, requested_by, idempotency_key, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a2'), pg_temp.id('v1'), 'MANUAL', 'FULL', '2026-11', 'an', 'k9', 'an', 'an')$$, '23514', 'Idempotency-Key phải đi kèm idempotency_hash (ERR-08-055)');
INSERT INTO ph08_dq.dq_scan_job (id, tenant_id, asset_id, rule_set_version_id, scan_trigger, scan_mode, status, period_code, requested_by, finished_at, flags, created_by, updated_by) VALUES (pg_temp.id('j3'), 'T90', pg_temp.id('a2'), pg_temp.id('v1'), 'SCHEDULE', 'FULL', 'SUCCEEDED', '2026-10', 'scheduler', now(), '{TRUNCATED,INCREMENTAL}', 'scheduler', 'scheduler');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_finding SET status = 'RESOLVED', resolved_at = now() WHERE id = pg_temp.id('fi1')$$, '23514', 'lỗi RESOLVED phải có resolution_reason');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_finding SET resolution_reason = 'GONE' WHERE id = pg_temp.id('fi1')$$, '23514', 'enum finding.resolution_reason sai');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue SET status = 'REJECTED', reject_reason = 'đủ dài để vượt kiểm tra hai mươi ký tự' WHERE id = pg_temp.id('is1')$$, '23514', 'từ chối phiếu phải có reject_type');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_issue SET status = 'REJECTED', reject_reason = 'đủ dài để vượt kiểm tra hai mươi ký tự', reject_type = 'OTHER' WHERE id = pg_temp.id('is1')$$, '23514', 'enum issue.reject_type sai');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_alert (id, tenant_id, alert_rule_id, asset_id, severity, dedup_key, message, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('ar1'), pg_temp.id('a1'), 'HIGH', 'khac-khoa-khu-trung', 'cùng quy tắc, cùng đối tượng, chưa RESOLVED', 'a', 'a')$$, '23505', 'mỗi (quy tắc cảnh báo, đối tượng) một cảnh báo chưa RESOLVED');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_export_request (id, tenant_id, kind, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'REPORT', 'an', 'an', 'an')$$, '23514', 'xuất kind REPORT phải có report_code');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_export_request (id, tenant_id, kind, format, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'FINDINGS', 'PDF', 'an', 'an', 'an')$$, '23514', 'PDF chỉ cho xuất báo cáo');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_export_request (id, tenant_id, kind, report_code, format, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'REPORT', 'BC-DQ-2026-99-T90', 'PDF', 'an', 'an', 'an')$$, '23503', 'mã báo cáo của yêu cầu xuất phải tồn tại');
INSERT INTO ph08_dq.dq_export_request (id, tenant_id, kind, report_code, format, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'REPORT', 'BC-DQ-2026-11-T90', 'PDF', 'an', 'an', 'an');
INSERT INTO ph08_dq.dq_waiver_item (id, tenant_id, waiver_id, fingerprint, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('w1'), pg_temp.h('fp1'), 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_waiver_item (id, tenant_id, waiver_id, fingerprint, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('w1'), pg_temp.h('fp1'), 'an', 'an')$$, '23505', 'mỗi dấu vân tay một dòng trong một ngoại lệ');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_waiver_item (id, tenant_id, waiver_id, fingerprint, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('w1'), '\x00', 'an', 'an')$$, '23514', 'dấu vân tay mục ngoại lệ đủ 32 byte');
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_waiver_item SET fingerprint = pg_temp.h('khac')$$, '55000', 'mục ngoại lệ bất biến');
INSERT INTO ph08_dq.dq_incremental_buffer (id, tenant_id, asset_id, window_start, window_end, keys, event_count, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), now(), now() + interval '15 minutes', '{g1,g2,g3}', 3, 'dq', 'dq');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_incremental_buffer (id, tenant_id, asset_id, window_start, window_end, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), now(), now() + interval '15 minutes', 'dq', 'dq')$$, '23505', 'mỗi đối tượng đúng một bộ đệm COLLECTING');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_incremental_buffer (id, tenant_id, asset_id, window_start, window_end, status, keys, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a2'), now(), now() + interval '15 minutes', 'OVERFLOW', ARRAY(SELECT g::text FROM generate_series(1, 100001) g), 'dq', 'dq')$$, '23514', 'bộ đệm tối đa 100.000 khóa');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_incremental_buffer (id, tenant_id, asset_id, window_start, window_end, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a2'), now(), now() + interval '15 minutes', 'SCHEDULED', 'dq', 'dq')$$, '23514', 'bộ đệm SCHEDULED phải gắn lần đo');
INSERT INTO ph08_dq.dq_score_current (id, tenant_id, asset_id, full_snapshot_id, current_score, verdict, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('sn1'), 91.5, 'PASS', 'dq', 'dq');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_current (id, tenant_id, asset_id, full_snapshot_id, current_score, verdict, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a1'), pg_temp.id('sn1'), 90, 'PASS', 'dq', 'dq')$$, '23505', 'một dòng điểm hiện hành mỗi đối tượng');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_score_current (id, tenant_id, asset_id, full_snapshot_id, current_score, verdict, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('a2'), pg_temp.id('sn1'), 120, 'PASS', 'dq', 'dq')$$, '23514', 'điểm hiện hành trong 0 đến 100');
INSERT INTO ph08_dq.dq_retention_run (id, tenant_id, object_type, action, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'dq_finding', 'DROP_PARTITION', 'an', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_retention_run (id, tenant_id, object_type, action, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'dq_finding', 'DROP_PARTITION', 'SUCCEEDED', 'an', 'an', 'an')$$, '23514', 'lần dọn đã xong phải có finished_at');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_retention_run (id, tenant_id, object_type, action, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'dq_unknown', 'DELETE', 'an', 'an', 'an')$$, '23514', 'loại dữ liệu dọn phải thuộc danh sách lưu giữ');
INSERT INTO ph08_dq.dq_score_snapshot (id, tenant_id, scan_job_id, asset_id, domain_code, owner_org_code, period_code, scan_mode, score, verdict, rule_set_version_id, official, flags, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('j3'), pg_temp.id('a2'), 'CITIZEN', 'SO-TU-PHAP', '2026-10', 'FULL', 88.00, 'PASS', pg_temp.id('v1'), true, '{TRUNCATED}', 'worker', 'worker');
INSERT INTO ph08_dq.dq_score_dimension (id, tenant_id, snapshot_id, dimension, status, score, weight, created_by, updated_by)
SELECT gen_random_uuid(), 'T90', id, 'VALIDITY', 'MEASURED', 88.0, 0.20, 'worker', 'worker' FROM ph08_dq.dq_score_snapshot WHERE scan_job_id = pg_temp.id('j3');
RESET ROLE;
SET ROLE ph08_benchmark;
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.v_benchmark_dimension WHERE tenant_id = 'T90'), 1, 'vai so sánh liên tenant đọc điểm chiều chính thức của tenant khác (ngoại lệ RLS duy nhất)');
SELECT pg_temp.expect($$SELECT count(*) FROM ph08_dq.dq_finding$$, '42501', 'vai so sánh không đọc bản ghi lỗi');
SELECT pg_temp.expect($$SELECT count(*) FROM ph08_dq.dq_asset$$, '42501', 'vai so sánh không đọc đối tượng đo');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'BM', 'x', 'x', 'a', 'a')$$, '42501', 'vai so sánh không ghi');
RESET ROLE;
SET ROLE dh_data_app;
SET app.tenant_id = 'T90';

-- ---------- 9. Quyền vai trò ----------
SELECT pg_temp.expect($$CREATE TABLE ph08_dq.x (a int)$$, '42501', 'ứng dụng không tạo được bảng trong schema');
SELECT pg_temp.expect($$DROP TABLE ph08_dq.dq_asset$$, '42501', 'ứng dụng không xóa được bảng');
SELECT pg_temp.expect($$ALTER TABLE ph08_dq.dq_finding DISABLE ROW LEVEL SECURITY$$, '42501', 'ứng dụng không tắt được RLS');
RESET ROLE;
SET ROLE dh_report_ro;
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 2, 'vai chỉ đọc đọc được đối tượng đo của tenant phiên');
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_finding WHERE severity = 'CRITICAL'), 1, 'vai chỉ đọc truy vấn bản ghi lỗi theo cột không nhạy cảm');
SELECT pg_temp.expect($$SELECT masked_value FROM ph08_dq.dq_finding$$, '42501', 'vai chỉ đọc không đọc masked_value');
SELECT pg_temp.expect($$SELECT value_hash FROM ph08_dq.dq_finding$$, '42501', 'vai chỉ đọc không đọc value_hash');
SELECT pg_temp.expect($$SELECT record_key_masked FROM ph08_dq.dq_finding$$, '42501', 'vai chỉ đọc không đọc record_key_masked');
SELECT pg_temp.expect($$SELECT * FROM ph08_dq.dq_finding$$, '42501', 'vai chỉ đọc không SELECT * trên bản ghi lỗi');
SELECT pg_temp.expect($$INSERT INTO ph08_dq.dq_domain (id, tenant_id, domain_code, name, owner_org_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RO', 'x', 'x', 'a', 'a')$$, '42501', 'vai chỉ đọc không ghi');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 0, 'vai chỉ đọc cũng bị RLS theo tenant');
RESET ROLE;

-- ---------- 10. Chủ schema vẫn chịu RLS và trigger ----------
SET ROLE ph08_owner;
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph08_dq.dq_asset), 0, 'chủ schema bị FORCE RLS: tenant T91 không thấy dữ liệu T90');
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($$UPDATE ph08_dq.dq_rule_result SET status = 'PASSED'$$, '55000', 'trigger chặn UPDATE dq_rule_result kể cả chủ schema');
SELECT pg_temp.expect($$DELETE FROM ph08_dq.dq_issue_activity$$, '55000', 'trigger chặn DELETE dq_issue_activity kể cả chủ schema');
-- Dọn bằng phân vùng: tách phân vùng tháng kế tiếp (không có dòng bị giữ)
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'dq_rule_result'), 3, 'dq_rule_result có 3 phân vùng tháng');
ALTER TABLE ph08_dq.dq_inline_stat DETACH PARTITION ph08_dq.dq_inline_stat_202701;
DROP TABLE ph08_dq.dq_inline_stat_202701;
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'dq_inline_stat'), 2, 'dọn dữ liệu thống kê bằng DETACH và DROP phân vùng');
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_inline_stat', current_date, 3);
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'dq_inline_stat'), 3, 'p_ensure_partitions tạo lại phân vùng thiếu');
RESET ROLE;

-- ---------- 11. Tổng kiểm ----------
DO $$
DECLARE n integer; m integer;
BEGIN
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph08_dq' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname <> 'shedlock' AND NOT c.relforcerowsecurity;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng chưa FORCE RLS', n; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph08_dq' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname NOT IN ('shedlock', 'outbox_event', 'inbox_event')
     AND (SELECT count(*) FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname IN ('id', 'tenant_id', 'created_at', 'created_by', 'updated_at', 'updated_by', 'version') AND NOT a.attisdropped) <> 7;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng thiếu cột ngữ cảnh', n; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph08_dq' AND c.relkind IN ('r', 'p') AND NOT c.relispartition;
  RAISE NOTICE 'PASS tổng kiểm: % bảng, mọi bảng nghiệp vụ FORCE RLS và đủ cột ngữ cảnh', n;
END $$;
RESET ROLE;
\o
