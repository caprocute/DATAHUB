-- =============================================================================
-- D03-03-PH16 · Kiểm thử DDL ph16_kpi: cô lập tenant (RLS), mẫu RLS dùng chung COMMON, ràng buộc enum và nghiệp vụ,
-- phiên bản định nghĩa bất biến, idempotent quan sát, bốn mắt (báo cáo, số liệu tay, đánh giá, miễn trừ), báo cáo PUBLISHED bất biến,
-- nhật ký nộp chỉ thêm, kỳ CLOSED không ghi giá trị, phân vùng, outbox, quyền vai trò, khởi tạo tenant.
-- Chạy sau ph16_kpi.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph16_isolation_test.sql
-- Mỗi lệnh pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại, 42501 quyền hoặc RLS,
-- 55000 bất biến hoặc sai trạng thái) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- =============================================================================
\set ON_ERROR_STOP on
\o /dev/null
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_app') THEN
    CREATE ROLE dh_platform_app LOGIN NOBYPASSRLS IN ROLE ph16_app;
  ELSE
    GRANT ph16_app TO dh_platform_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_kpi_ro') THEN
    CREATE ROLE dh_kpi_ro LOGIN NOBYPASSRLS IN ROLE ph16_readonly;
  ELSE
    GRANT ph16_readonly TO dh_kpi_ro;
  END IF;
  GRANT ph16_owner TO CURRENT_USER;
  GRANT ph16_compare TO CURRENT_USER;
END $$;
SET ROLE dh_platform_app;

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
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['i1','i2','v1','v2','v3','s1','s2','ct1','o1','lg1','p1','p2','p3','m1','m2','m3','ev1','r1','r2','r3','r4','val1','val2','val3','val4','gs1','gs2',
  'rep1','rep2','rv1','rv2','rv3','rv4','ap1','sg1','sg2','di1','dl1','ex1','c1','c2','c3','cv1','dp1','as1','as2','it1','wv1','nt1','sub1','sub2','sub3','lo1','th1']) k;
GRANT SELECT ON ids TO PUBLIC;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.h(text) RETURNS bytea LANGUAGE sql AS $$ SELECT sha256(convert_to($1, 'UTF8')) $$;

-- ---------- 1. Khởi tạo tenant T90, T91 bằng thủ tục ----------
SET app.tenant_id = 'T90';
CALL ph16_kpi.p_seed_tenant('T90');
CALL ph16_kpi.p_seed_tenant('T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_tenant_setting), 25, 'seed T90: 25 tham số 16.* của FRS §8.2, chạy lại không nhân bản');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_group WHERE tenant_id = 'T90'), 5, 'seed T90: năm nhóm chỉ tiêu');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_compliance_criterion WHERE tenant_id = 'T90'), 6, 'seed T90: sáu tiêu chí tuân thủ tối thiểu');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report_template WHERE tenant_id = 'T90' AND state = 'ACTIVE'), 1, 'seed T90: một mẫu báo cáo ACTIVE');
SELECT pg_temp.eq((SELECT (value #>> '{}')::int FROM ph16_kpi.kpi_tenant_setting WHERE param_code = '16.report.retention-years'), 10, 'báo cáo công bố giữ 10 năm theo tham số');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON'), 24, 'T90 đọc được 24 chỉ tiêu mẫu COMMON');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON' AND brd_ref IS NOT NULL), 18, 'COMMON: 18 chỉ tiêu mang mã KPI-01…18 của BRD');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON' AND measurement = 'MANUAL'), 4, 'COMMON: 4 chỉ tiêu nhập tay (KPI-02, 08, 17, 18)');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON' AND mandatory), 5, 'COMMON: 5 chỉ tiêu bắt buộc cho báo cáo chính thức');
SET app.tenant_id = 'T91';
CALL ph16_kpi.p_seed_tenant('T91');
SET app.tenant_id = 'T90';

-- ---------- 2. Chỉ tiêu, phiên bản định nghĩa, ngưỡng ----------
INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, aggregation, scope, mandatory, brd_ref, template_code, created_by, updated_by)
VALUES (pg_temp.id('i1'), 'T90', 'httt-ket-noi-ty-le', 'KET_NOI', 'Tỷ lệ HTTT đã kết nối', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'LAST', 'TENANT', true, 'KPI-01', 'httt-ket-noi-ty-le', 'an', 'an'),
       (pg_temp.id('i2'), 'T90', 'diem-hai-long-sus', 'KIEN_TRUC', 'Điểm hài lòng SUS', 'SCORE', 'HIGHER_BETTER', 'MANUAL', 'điểm', 'LAST', 'TENANT', false, 'KPI-18', 'diem-hai-long-sus', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'httt-ket-noi-ty-le', 'KET_NOI', 'x', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'a', 'a')$$, '23505', 'mã chỉ tiêu duy nhất theo tenant');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'Sai_Ma', 'KET_NOI', 'x', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'a', 'a')$$, '23514', 'mã chỉ tiêu phải theo T-CODE');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'chi-tieu-sai-loai', 'KET_NOI', 'x', 'PERCENT', 'HIGHER_BETTER', 'AUTO', '%', 'a', 'a')$$, '23514', 'kind ngoài enum bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'chi-tieu-sai-nhom', 'KHAC', 'x', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'a', 'a')$$, '23503', 'nhóm chỉ tiêu phải có (khóa ngoại kèm tenant)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'chi-tieu-pham-vi', 'KET_NOI', 'x', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'COMMON', 'a', 'a')$$, '23514', 'phạm vi COMMON chỉ ở tenant COMMON');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator SET indicator_code = 'doi-ma-khac' WHERE id = pg_temp.id('i1')$$, '55000', 'mã chỉ tiêu bất biến');
UPDATE ph16_kpi.kpi_indicator SET template_version_no = 1, template_dismissed_version_no = 2 WHERE id = pg_temp.id('i1');
SELECT pg_temp.eq((SELECT template_dismissed_version_no FROM ph16_kpi.kpi_indicator WHERE id = pg_temp.id('i1')), 2, 'ghi nhận quyết định bỏ qua cập nhật chỉ tiêu mẫu COMMON (nhận mẫu phiên bản 1, bỏ qua phiên bản 2)');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator SET state = 'RETIRED', state_reason = 'ngắn' WHERE id = pg_temp.id('i2')$$, '23514', 'ngừng chỉ tiêu cần lý do từ 20 ký tự');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_indicator WHERE id = pg_temp.id('i2')$$, '42501', 'ứng dụng không xóa cứng chỉ tiêu');

INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, state, formula_cel, variables, target_value, target_due, created_by, updated_by)
VALUES (pg_temp.id('v1'), 'T90', pg_temp.id('i1'), 1, 'DRAFT', 'obs("ph01.httt.connected") / obs("ph01.httt.total") * 100',
        '[{"name":"connected","metricCode":"ph01.httt.connected","aggregation":"LAST","required":true},{"name":"total","metricCode":"ph01.httt.total","aggregation":"LAST","required":true}]', 90, '2027-12-31', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, state, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('i1'), 1, 'DRAFT', 'a', 'a')$$, '23505', 'mỗi chỉ tiêu một số phiên bản duy nhất');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, state, variables, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('i1'), 9, 'DRAFT', '{}', 'a', 'a')$$, '23514', 'biến phải là mảng JSON');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, state, target_min, target_max, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('i1'), 9, 'DRAFT', 10, 5, 'a', 'a')$$, '23514', 'mục tiêu từ không lớn hơn đến');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET state = 'ACTIVE' WHERE id = pg_temp.id('v1')$$, '55000', 'DRAFT không nhảy thẳng sang ACTIVE (máy trạng thái)');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'PENDING_APPROVAL', submitted_by = 'an', submitted_at = now() WHERE id = pg_temp.id('v1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET formula_cel = '1 + 1' WHERE id = pg_temp.id('v1')$$, '55000', 'phiên bản đã gửi duyệt không đổi công thức');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET state = 'ACTIVE', decided_by = 'an', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('v1')$$, '23514', 'bốn mắt: người duyệt định nghĩa khác người gửi');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'ACTIVE', decided_by = 'binh', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('v1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET formula_cel = '1 + 1' WHERE id = pg_temp.id('v1')$$, '55000', 'phiên bản ACTIVE bất biến, đổi công thức cần phiên bản mới');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET target_value = 95 WHERE id = pg_temp.id('v1')$$, '55000', 'phiên bản ACTIVE không đổi mục tiêu');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET state = 'DRAFT' WHERE id = pg_temp.id('v1')$$, '55000', 'ACTIVE không quay về DRAFT');
INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, state, formula_cel, change_note, created_by, updated_by)
VALUES (pg_temp.id('v2'), 'T90', pg_temp.id('i1'), 2, 'DRAFT', 'obs("ph01.httt.connected") / obs("ph01.httt.total") * 100', 'Đổi cách làm tròn', 'an', 'an');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'PENDING_APPROVAL', submitted_by = 'an', submitted_at = now() WHERE id = pg_temp.id('v2');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('i1'), 3, 'a', 'a')$$, '23505', 'mỗi chỉ tiêu một phiên bản đang soạn hoặc chờ duyệt (FRS 4.3)');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET state = 'ACTIVE', decided_by = 'binh', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('v2')$$, '23505', 'mỗi chỉ tiêu một phiên bản ACTIVE');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'SUPERSEDED', superseded_at = now() WHERE id = pg_temp.id('v1');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'ACTIVE', decided_by = 'binh', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('v2');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_version WHERE state = 'ACTIVE' AND indicator_id = pg_temp.id('i1')), 1, 'thay thế: v1 SUPERSEDED, v2 ACTIVE');
INSERT INTO ph16_kpi.kpi_indicator_version (id, tenant_id, indicator_id, version_no, state, formula_cel, created_by, updated_by)
VALUES (pg_temp.id('v3'), 'T90', pg_temp.id('i2'), 1, 'DRAFT', 'manual("value")', 'an', 'an');
INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, lower_bound, created_by, updated_by) VALUES (pg_temp.id('th1'), 'T90', pg_temp.id('v3'), 'GREEN', 68, 'an', 'an');
INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, lower_bound, upper_bound, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v3'), 'AMBER', 50, 68, 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, lower_bound, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v3'), 'GREEN', 1, 'a', 'a')$$, '23505', 'mỗi phiên bản một ngưỡng cho mỗi mức');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, lower_bound, upper_bound, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v3'), 'RED', 9, 3, 'a', 'a')$$, '23514', 'ngưỡng: cận dưới không vượt cận trên');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v3'), 'RED', 'a', 'a')$$, '23514', 'ngưỡng phải có ít nhất một cận');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'PENDING_APPROVAL', submitted_by = 'an', submitted_at = now() WHERE id = pg_temp.id('v3');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, upper_bound, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v3'), 'RED', 50, 'a', 'a')$$, '55000', 'không thêm ngưỡng khi phiên bản đã gửi duyệt');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_indicator_threshold WHERE id = pg_temp.id('th1')$$, '55000', 'không xóa ngưỡng khi phiên bản đã gửi duyệt');
UPDATE ph16_kpi.kpi_indicator_version SET state = 'CHANGES_REQUESTED', decided_by = 'binh', decided_at = now(), decision_comment = 'Cần bổ sung ngưỡng mức đỏ theo mục tiêu năm' WHERE id = pg_temp.id('v3');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_version SET state = 'ACTIVE', decided_by = 'binh', decided_at = now(), activated_at = now() WHERE id = pg_temp.id('v3')$$, '55000', 'CHANGES_REQUESTED chỉ về DRAFT hoặc gửi duyệt lại');
INSERT INTO ph16_kpi.kpi_indicator_threshold (id, tenant_id, version_id, level, upper_bound, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('v3'), 'RED', 50, 'an', 'an');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_threshold WHERE version_id = pg_temp.id('v3')), 3, 'CHANGES_REQUESTED còn sửa được ngưỡng (3 mức)');

-- ---------- 3. Nguồn số liệu, hợp đồng, quan sát idempotent, nhật ký tiếp nhận ----------
INSERT INTO ph16_kpi.kpi_data_source (id, tenant_id, source_code, name, source_type, owner_phase, topic_pattern, created_by, updated_by)
VALUES (pg_temp.id('s1'), 'T90', 'ph01-ket-nap', 'Kết nạp HTTT (PH-01)', 'EVENT', 'PH-01', '{tenant}.httt.activated.v1', 'an', 'an');
INSERT INTO ph16_kpi.kpi_data_source (id, tenant_id, source_code, name, source_type, owner_phase, api_ref, schedule_cron, created_by, updated_by)
VALUES (pg_temp.id('s2'), 'T90', 'ph13-chi-so', 'Chỉ số PH-13', 'PULL_API', 'PH-13', '/api/mon/v1/kpi-metrics', '0 15 1 * * *', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_data_source (id, tenant_id, source_code, name, source_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'nguon-su-kien', 'x', 'EVENT', 'a', 'a')$$, '23514', 'nguồn EVENT phải có mẫu topic');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_data_source (id, tenant_id, source_code, name, source_type, api_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'nguon-keo', 'x', 'PULL_API', '/x', 'a', 'a')$$, '23514', 'nguồn PULL_API phải có API và lịch');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_data_source (id, tenant_id, source_code, name, source_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'nguon-loai-la', 'x', 'FTP', 'a', 'a')$$, '23514', 'loại nguồn ngoài enum bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_data_source (id, tenant_id, source_code, name, source_type, owner_phase, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'nguon-phan-he', 'x', 'PUSH_API', 'PH-1', 'a', 'a')$$, '23514', 'mã phân hệ nguồn dạng PH-nn');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_data_source SET state = 'PAUSED' WHERE id = pg_temp.id('s2')$$, '23514', 'tạm dừng nguồn cần lý do từ 20 ký tự');
UPDATE ph16_kpi.kpi_data_source SET state = 'STALE' WHERE id = pg_temp.id('s1');
UPDATE ph16_kpi.kpi_data_source SET state = 'ACTIVE' WHERE id = pg_temp.id('s1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_data_source SET state = 'RETIRED', state_reason = 'Nguồn thay bằng PH-13 chỉ số mới từ tháng 12' WHERE id = pg_temp.id('s2')$$, '55000', 'nguồn ACTIVE không ngừng thẳng (phải PAUSED trước)');
UPDATE ph16_kpi.kpi_data_source SET state = 'PAUSED', state_reason = 'Tạm dừng chờ PH-13 phát hành chỉ số mới' WHERE id = pg_temp.id('s2');
UPDATE ph16_kpi.kpi_data_source SET state = 'RETIRED', state_reason = 'Nguồn thay bằng PH-13 chỉ số mới từ tháng 12' WHERE id = pg_temp.id('s2');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_data_source SET state = 'ACTIVE' WHERE id = pg_temp.id('s2')$$, '55000', 'nguồn RETIRED không kích hoạt lại');
INSERT INTO ph16_kpi.kpi_source_contract (id, tenant_id, source_id, metric_code, kind, unit, created_by, updated_by) VALUES (pg_temp.id('ct1'), 'T90', pg_temp.id('s1'), 'ph01.httt.connected', 'COUNT', 'HTTT', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_source_contract (id, tenant_id, source_id, metric_code, kind, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.connected', 'COUNT', 'HTTT', 'a', 'a')$$, '23505', 'hợp đồng chỉ số duy nhất theo (nguồn, chỉ số, lược đồ)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_source_contract (id, tenant_id, source_id, metric_code, kind, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'PH01.httt', 'COUNT', 'HTTT', 'a', 'a')$$, '23514', 'mã chỉ số dạng ph{nn}.{đối-tượng}.{chỉ-số}');

INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, unit, period_start, period_end, idempotency_ref, channel, created_by, updated_by)
VALUES (pg_temp.id('o1'), 'T90', pg_temp.id('s1'), 'ph01.httt.connected', 166, 'HTTT', '2026-10-01 00:00:00+07', '2026-11-01 00:00:00+07', 'evt-0001', 'EVENT', 'ingest', 'ingest');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.connected', 166, '2026-10-01 00:00:00+07', '2026-11-01 00:00:00+07', 'evt-0001', 'EVENT', 'a', 'a')$$, '23505', 'idempotent: nhận lại cùng mã tham chiếu không tạo dòng mới');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.connected', 170, '2026-11-01 00:00:00+07', '2026-12-01 00:00:00+07', 'evt-0001', 'EVENT', 'a', 'a')$$, '23505', 'cùng mã tham chiếu của nguồn không dùng được ở kỳ khác (trigger, bù cột phân vùng)');
INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.total', 200, '2026-10-01 00:00:00+07', '2026-11-01 00:00:00+07', 'evt-0002', 'EVENT', 'ingest', 'ingest');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_observation), 2, 'hai quan sát hợp lệ, bản trùng bị loại');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.total', 1, '2031-01-01 00:00:00+07', '2031-02-01 00:00:00+07', 'evt-9999', 'EVENT', 'a', 'a')$$, '23514', 'kỳ ngoài các phân vùng đã tạo bị chặn (cần PartitionMaintenanceJob)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.total', 1, '2026-10-02', '2026-10-01', 'evt-0003', 'EVENT', 'a', 'a')$$, '23514', 'kết thúc kỳ phải sau bắt đầu kỳ');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'ph01.httt.total', 1, '2026-10-01', '2026-10-02', 'sai mã có khoảng trắng', 'EVENT', 'a', 'a')$$, '23514', 'idempotency_ref sai mẫu bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'ph01.httt.total', 1, '2026-10-01', '2026-10-02', 'evt-0004', 'EVENT', 'a', 'a')$$, '23503', 'quan sát phải trỏ tới nguồn có thật (khóa ngoại kèm tenant)');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_observation SET value = 1$$, '42501', 'ứng dụng không UPDATE quan sát (chỉ thêm)');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_observation$$, '42501', 'ứng dụng không DELETE quan sát');
INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, metric_code, idempotency_ref, payload_hash, observation_id, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'EVENT', 'ACCEPTED', 'ph01.httt.connected', 'evt-0001', pg_temp.h('evt-0001'), pg_temp.id('o1'), 'ingest', 'ingest');
INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, idempotency_ref, payload_hash, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'EVENT', 'DUPLICATE', 'evt-0001', pg_temp.h('evt-0001'), 'ingest', 'ingest');
INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, metric_code, idempotency_ref, reject_code, payload, detail, created_by, updated_by)
VALUES (pg_temp.id('lg1'), 'T90', pg_temp.id('s1'), 'EVENT', 'REJECTED', 'ph99.la.chi-so', 'evt-0005', 'ERR-16-105', '{"metricCode":"ph99.la.chi-so","value":1}', 'Chỉ số ngoài hợp đồng của nguồn', 'ingest', 'ingest');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'EVENT', 'REJECTED', 'a', 'a')$$, '23514', 'quan sát bị loại phải có mã lỗi ERR-16-1xx');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, reject_code, payload, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'EVENT', 'REJECTED', 'ERR-16-001', '{}', 'a', 'a')$$, '23514', 'mã lỗi tiếp nhận thuộc dải ERR-16-101…199');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, reject_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'EVENT', 'REJECTED', 'ERR-16-102', 'a', 'a')$$, '23514', 'dòng REJECTED phải giữ bản tin để xử lý lại');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_ingest_log (id, tenant_id, source_id, channel, outcome, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('s1'), 'EVENT', 'ACCEPTED', 'a', 'a')$$, '23514', 'dòng ACCEPTED phải trỏ tới quan sát');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_ingest_log SET outcome = 'ACCEPTED' WHERE id = pg_temp.id('lg1')$$, '55000', 'REJECTED chỉ chuyển được sang REPROCESSED');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_ingest_log SET reject_code = 'ERR-16-101' WHERE id = pg_temp.id('lg1')$$, '55000', 'mã lỗi tiếp nhận bất biến, giữ làm lịch sử');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_ingest_log SET outcome = 'REPROCESSED', observation_id = pg_temp.id('o1') WHERE id = pg_temp.id('lg1')$$, '23514', 'xử lý lại xong phải có người và thời điểm');
UPDATE ph16_kpi.kpi_ingest_log SET outcome = 'REPROCESSED', observation_id = pg_temp.id('o1'), reprocessed_at = now(), reprocessed_by = 'an' WHERE id = pg_temp.id('lg1');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_ingest_log WHERE outcome = 'REPROCESSED' AND reject_code = 'ERR-16-105'), 1, 'xử lý lại đạt: dòng nhật ký chuyển REPROCESSED, giữ mã lỗi cũ (ingest.result)');

-- ---------- 4. Kỳ báo cáo, số liệu tay và bằng chứng, lần tổng hợp ----------
INSERT INTO ph16_kpi.kpi_reporting_period (id, tenant_id, period_code, period_type, start_date, end_date, created_by, updated_by)
VALUES (pg_temp.id('p1'), 'T90', 'M-2026-10', 'MONTH', '2026-10-01', '2026-10-31', 'an', 'an'),
       (pg_temp.id('p2'), 'T90', 'Q-2026-Q3', 'QUARTER', '2026-07-01', '2026-09-30', 'an', 'an'),
       (pg_temp.id('p3'), 'T90', 'Y-2026', 'YEAR', '2026-01-01', '2026-12-31', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_reporting_period (id, tenant_id, period_code, period_type, start_date, end_date, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'M-2026-13', 'MONTH', '2026-12-01', '2026-12-31', 'a', 'a')$$, '23514', 'mã kỳ tháng 13 bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_reporting_period (id, tenant_id, period_code, period_type, start_date, end_date, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'Q-2026-Q4', 'MONTH', '2026-10-01', '2026-12-31', 'a', 'a')$$, '23514', 'mã kỳ phải khớp loại kỳ');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_reporting_period (id, tenant_id, period_code, period_type, start_date, end_date, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'M-2026-10', 'MONTH', '2026-10-01', '2026-10-31', 'a', 'a')$$, '23505', 'mã kỳ duy nhất theo tenant');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_reporting_period (id, tenant_id, period_code, period_type, start_date, end_date, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'M-2026-11', 'MONTH', '2026-11-30', '2026-11-01', 'a', 'a')$$, '23514', 'ngày kết thúc kỳ không trước ngày bắt đầu');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_reporting_period SET state = 'CLOSED', closed_by = 'an', closed_at = now() WHERE id = pg_temp.id('p2')$$, '55000', 'kỳ OPEN không chốt thẳng (phải qua COLLECTING, COMPUTED)');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'COLLECTING' WHERE id = pg_temp.id('p2');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_reporting_period SET state = 'OPEN' WHERE id = pg_temp.id('p2')$$, '55000', 'kỳ không quay về OPEN');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_reporting_period SET start_date = '2026-10-02' WHERE id = pg_temp.id('p1')$$, '55000', 'ngày của kỳ bất biến');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'COLLECTING' WHERE id = pg_temp.id('p1');

INSERT INTO ph16_kpi.kpi_manual_value (id, tenant_id, indicator_id, period_id, value, entered_by, created_by, updated_by) VALUES (pg_temp.id('m1'), 'T90', pg_temp.id('i2'), pg_temp.id('p1'), 72.5, 'an', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_value (id, tenant_id, indicator_id, period_id, value, entered_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('i2'), pg_temp.id('p1'), 70, 'an', 'a', 'a')$$, '23505', 'mỗi (chỉ tiêu, kỳ, biến) một số liệu tay chưa bị từ chối');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_value (id, tenant_id, indicator_id, period_id, variable_name, value, state, submitted_at, entered_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('i2'), pg_temp.id('p1'), 'khac', 70, 'SUBMITTED', now(), 'an', 'a', 'a')$$, '55000', 'số liệu tay mới phải ở DRAFT');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_value SET state = 'SUBMITTED', submitted_at = now() WHERE id = pg_temp.id('m1')$$, '23514', 'gửi xác nhận số liệu tay cần bằng chứng khi 16.manual.evidence-required bật');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_evidence (id, tenant_id, manual_value_id, evidence_type, uploaded_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('m1'), 'FILE', 'an', 'a', 'a')$$, '23514', 'bằng chứng tệp phải có đường dẫn, tên và mã băm');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_evidence (id, tenant_id, manual_value_id, evidence_type, uploaded_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('m1'), 'DOCUMENT_NUMBER', 'an', 'a', 'a')$$, '23514', 'bằng chứng văn bản phải có số và ngày');
INSERT INTO ph16_kpi.kpi_manual_evidence (id, tenant_id, manual_value_id, evidence_type, object_ref, file_name, content_hash, uploaded_by, created_by, updated_by)
VALUES (pg_temp.id('ev1'), 'T90', pg_temp.id('m1'), 'FILE', 'kpi-evidence/T90/sus-2026-10.xlsx', 'sus-2026-10.xlsx', pg_temp.h('sus'), 'an', 'an', 'an');
UPDATE ph16_kpi.kpi_manual_value SET state = 'SUBMITTED', submitted_at = now() WHERE id = pg_temp.id('m1');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_evidence (id, tenant_id, manual_value_id, evidence_type, document_no, document_date, uploaded_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('m1'), 'DOCUMENT_NUMBER', '12/QĐ-UBND', '2026-10-30', 'an', 'a', 'a')$$, '55000', 'không thêm bằng chứng sau khi đã gửi xác nhận');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_value SET value = 99 WHERE id = pg_temp.id('m1')$$, '55000', 'số liệu tay đã gửi không đổi giá trị');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_value SET state = 'ACCEPTED', decided_by = 'an', decided_at = now() WHERE id = pg_temp.id('m1')$$, '23514', 'bốn mắt: người xác nhận khác người nhập số liệu tay');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_value SET state = 'REJECTED', decided_by = 'binh', decided_at = now(), decision_comment = 'ngắn' WHERE id = pg_temp.id('m1')$$, '23514', 'từ chối số liệu tay cần lý do từ 20 ký tự');
UPDATE ph16_kpi.kpi_manual_value SET state = 'ACCEPTED', decided_by = 'binh', decided_at = now() WHERE id = pg_temp.id('m1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_value SET state = 'DRAFT' WHERE id = pg_temp.id('m1')$$, '55000', 'số liệu tay đã ACCEPTED không về DRAFT');
UPDATE ph16_kpi.kpi_tenant_setting SET value = 'false' WHERE param_code = '16.manual.evidence-required';
INSERT INTO ph16_kpi.kpi_manual_value (id, tenant_id, indicator_id, period_id, variable_name, value, entered_by, created_by, updated_by) VALUES (pg_temp.id('m2'), 'T90', pg_temp.id('i2'), pg_temp.id('p1'), 'phu', 5, 'an', 'an', 'an');
UPDATE ph16_kpi.kpi_manual_value SET state = 'SUBMITTED', submitted_at = now() WHERE id = pg_temp.id('m2');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_manual_value WHERE state = 'SUBMITTED'), 1, 'tắt 16.manual.evidence-required thì gửi xác nhận không cần bằng chứng');
UPDATE ph16_kpi.kpi_tenant_setting SET value = 'true' WHERE param_code = '16.manual.evidence-required';

INSERT INTO ph16_kpi.kpi_aggregation_run (id, tenant_id, period_id, run_no, run_trigger, requested_by, idempotency_ref, created_by, updated_by)
VALUES (pg_temp.id('r1'), 'T90', pg_temp.id('p1'), 1, 'SCHEDULE', 'scheduler', 'agg:M-2026-10:2026-11-05', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_aggregation_run (id, tenant_id, period_id, run_no, run_trigger, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 2, 'MANUAL', 'an', 'a', 'a')$$, '23505', 'mỗi kỳ một lần tổng hợp đang QUEUED hoặc RUNNING');
UPDATE ph16_kpi.kpi_aggregation_run SET state = 'RUNNING', started_at = now() WHERE id = pg_temp.id('r1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_aggregation_run SET state = 'SUCCEEDED', finished_at = now() WHERE id = pg_temp.id('r1')$$, '23514', 'tổng hợp xong phải có độ đầy đủ');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_aggregation_run SET state = 'PARTIAL', finished_at = now(), completeness = 1 WHERE id = pg_temp.id('r1')$$, '23514', 'PARTIAL phải có cờ hoặc độ đầy đủ dưới 1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_aggregation_run SET state = 'FAILED', finished_at = now() WHERE id = pg_temp.id('r1')$$, '23514', 'tổng hợp FAILED phải có mã lỗi');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_aggregation_run SET flags = '{KHONG_CO}' WHERE id = pg_temp.id('r1')$$, '23514', 'cờ tổng hợp ngoài danh sách bị chặn');
UPDATE ph16_kpi.kpi_aggregation_run SET state = 'PARTIAL', finished_at = now(), completeness = 0.9583, flags = '{MANUAL_PENDING}', indicator_total = 24, indicator_computed = 23 WHERE id = pg_temp.id('r1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_aggregation_run SET state = 'RUNNING' WHERE id = pg_temp.id('r1')$$, '55000', 'trạng thái cuối của lần tổng hợp không đổi');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_aggregation_run (id, tenant_id, period_id, run_no, run_trigger, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 2, 'RECOMPUTE', 'an', 'a', 'a')$$, '23514', 'tính lại phải ghi lý do từ 20 ký tự');
INSERT INTO ph16_kpi.kpi_aggregation_run (id, tenant_id, period_id, run_no, run_trigger, requested_by, reason, created_by, updated_by)
VALUES (pg_temp.id('r2'), 'T90', pg_temp.id('p1'), 2, 'LATE_DATA', 'scheduler', 'Số liệu trễ từ PH-01 về sau khi chốt ngày', 'sys', 'sys');
UPDATE ph16_kpi.kpi_aggregation_run SET state = 'RUNNING', started_at = now() WHERE id = pg_temp.id('r2');
UPDATE ph16_kpi.kpi_aggregation_run SET state = 'SUCCEEDED', finished_at = now(), completeness = 1, indicator_total = 24, indicator_computed = 24 WHERE id = pg_temp.id('r2');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'COMPUTED' WHERE id = pg_temp.id('p1');

-- ---------- 5. Giá trị chỉ tiêu, dòng truy nguồn, điểm nhóm, chốt kỳ ----------
INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, trend, is_current, created_by, updated_by)
VALUES (pg_temp.id('val1'), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i1'), 'httt-ket-noi-ty-le', 'KET_NOI', pg_temp.id('v2'), 83.000000, 'AT_RISK', 'COMPLETE', 'FLAT', true, 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), 72, 'NO_DATA', 'NO_DATA', 'sys', 'sys')$$, '23514', 'NO_DATA không được có số');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, trend, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), 72, 'ON_TRACK', 'COMPLETE', 'SIDEWAYS', 'sys', 'sys')$$, '23514', 'xu hướng chỉ nhận UP, DOWN, FLAT');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), NULL, 'ON_TRACK', 'COMPLETE', 'sys', 'sys')$$, '23514', 'có trạng thái ON_TRACK thì phải có số (fail-soft không bịa số)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), 5, 'ON_TRACK', 'PARTIAL', 'sys', 'sys')$$, '23514', 'PARTIAL phải nêu biến còn thiếu');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i1'), 'httt-ket-noi-ty-le', 'KET_NOI', pg_temp.id('v2'), 80, 'AT_RISK', 'COMPLETE', 'sys', 'sys')$$, '23505', 'mỗi lần tổng hợp một giá trị cho mỗi chỉ tiêu');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r1'), pg_temp.id('i1'), 'httt-ket-noi-ty-le', 'KET_NOI', pg_temp.id('v2'), 80, 'AT_RISK', 'COMPLETE', 'sys', 'sys')$$, '23505', 'mỗi (kỳ, chỉ tiêu) một giá trị hiện hành');
UPDATE ph16_kpi.kpi_indicator_value SET is_current = false WHERE id = pg_temp.id('val1');
INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, delta, trend, is_current, created_by, updated_by)
VALUES (pg_temp.id('val2'), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r1'), pg_temp.id('i1'), 'httt-ket-noi-ty-le', 'KET_NOI', pg_temp.id('v2'), 83.000000, 'AT_RISK', 'COMPLETE', 2.5, 'UP', true, 'sys', 'sys');
INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, is_current, created_by, updated_by)
VALUES (pg_temp.id('val3'), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r1'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), NULL, 'NO_DATA', 'NO_DATA', true, 'sys', 'sys');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_value WHERE is_current), 2, 'tính lại: dòng cũ is_current=false, dòng mới hiện hành');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_value SET version_id = pg_temp.id('v1') WHERE id = pg_temp.id('val2')$$, '55000', 'phiên bản công thức đã dùng của giá trị bất biến');
INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, metric_code, observation_id, used_value, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 1, 'connected', 'OBSERVATION', 'ph01.httt.connected', pg_temp.id('o1'), 166, 'sys', 'sys');
INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, manual_value_id, used_value, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 2, 'total', 'MANUAL_VALUE', pg_temp.id('m1'), 200, 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 3, 'x', 'OBSERVATION', 1, 'a', 'a')$$, '23514', 'dòng truy nguồn loại OBSERVATION phải trỏ tới quan sát');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, observation_id, manual_value_id, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 3, 'x', 'OBSERVATION', pg_temp.id('o1'), pg_temp.id('m1'), 1, 'a', 'a')$$, '23514', 'mỗi dòng truy nguồn chỉ một loại tham chiếu');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, observation_id, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 1, 'x', 'OBSERVATION', pg_temp.id('o1'), 1, 'a', 'a')$$, '23505', 'thứ tự biến trong dòng truy nguồn duy nhất');
INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, ref_value_id, used_value, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 4, 'thang', 'PERIOD_VALUE', pg_temp.id('val1'), 80, 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_value_lineage (id, tenant_id, value_id, period_start, run_id, seq, variable_name, source_kind, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('val2'), '2026-10-01', pg_temp.id('r1'), 5, 'thang', 'PERIOD_VALUE', 1, 'a', 'a')$$, '23514', 'dòng truy nguồn loại PERIOD_VALUE (gộp kỳ quý, năm từ tháng) phải trỏ tới giá trị kỳ con');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_value_lineage SET used_value = 0$$, '42501', 'ứng dụng không sửa dòng truy nguồn (chỉ thêm)');
INSERT INTO ph16_kpi.kpi_group_score (id, tenant_id, period_id, run_id, group_code, score, weight, indicator_total, indicator_with_value, completeness, delta, trend, created_by, updated_by)
VALUES (pg_temp.id('gs1'), 'T90', pg_temp.id('p1'), pg_temp.id('r1'), 'KET_NOI', 83.00, 20, 5, 4, 'PARTIAL', 1.50, 'UP', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_group_score (id, tenant_id, period_id, run_id, group_code, score, weight, indicator_total, indicator_with_value, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), pg_temp.id('r2'), 'CHIA_SE', 80, 20, 5, 4, 'COMPLETE', 'a', 'a')$$, '23514', 'điểm nhóm COMPLETE phải đủ số chỉ tiêu có số');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_group_score (id, tenant_id, period_id, run_id, group_code, score, weight, indicator_total, indicator_with_value, completeness, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), pg_temp.id('r2'), 'CHIA_SE', 101, 20, 5, 5, 'COMPLETE', 'a', 'a')$$, '23514', 'điểm nhóm trong khoảng 0…100');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'CLOSED', closed_by = 'binh', closed_at = now() WHERE id = pg_temp.id('p1');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, is_current, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), 70, 'ON_TRACK', 'COMPLETE', false, 'a', 'a')$$, '55000', 'kỳ CLOSED không nhận giá trị chỉ tiêu mới');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_indicator_value SET status = 'ON_TRACK' WHERE id = pg_temp.id('val2')$$, '55000', 'kỳ CLOSED không sửa giá trị chỉ tiêu');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_group_score (id, tenant_id, period_id, run_id, group_code, score, weight, indicator_total, indicator_with_value, completeness, is_current, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('p1'), pg_temp.id('r2'), 'DU_LIEU', 80, 0.2, 5, 5, 'COMPLETE', false, 'a', 'a')$$, '55000', 'kỳ CLOSED không nhận điểm nhóm mới');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_reporting_period SET state = 'REOPENED', reopen_reason = 'ngắn', reopened_by = 'binh', reopened_at = now(), reopen_count = 1 WHERE id = pg_temp.id('p1')$$, '23514', 'mở lại kỳ phải có lý do từ 50 ký tự');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'REOPENED', reopen_reason = 'Phát hiện số liệu PH-01 sai, cần tính lại kỳ tháng 10 theo công văn', reopened_by = 'binh', reopened_at = now(), reopen_count = 1 WHERE id = pg_temp.id('p1');
INSERT INTO ph16_kpi.kpi_indicator_value (id, tenant_id, period_id, period_code, period_start, run_id, indicator_id, indicator_code, group_code, version_id, value, status, completeness, is_current, created_by, updated_by)
VALUES (pg_temp.id('val4'), 'T90', pg_temp.id('p1'), 'M-2026-10', '2026-10-01', pg_temp.id('r2'), pg_temp.id('i2'), 'diem-hai-long-sus', 'KIEN_TRUC', pg_temp.id('v3'), 72.5, 'ON_TRACK', 'COMPLETE', false, 'sys', 'sys');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_value WHERE period_id = pg_temp.id('p1')), 4, 'kỳ REOPENED nhận lại giá trị sau khi mở lại có lý do');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'COMPUTED' WHERE id = pg_temp.id('p1');
UPDATE ph16_kpi.kpi_reporting_period SET state = 'CLOSED', closed_by = 'binh', closed_at = now() WHERE id = pg_temp.id('p1');

-- ---------- 6. Mẫu báo cáo, báo cáo, phiên bản bất biến khi PUBLISHED, bốn mắt, chữ ký ----------
INSERT INTO ids SELECT 'tpl', id FROM ph16_kpi.kpi_report_template WHERE tenant_id = 'T90' AND template_code = 'bao-cao-chi-tieu-ky';
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, name, sections, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'mau-sai-phan', 'x', '{FOO}', 'a', 'a')$$, '23514', 'mẫu báo cáo: loại phần ngoài enum bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, name, sections, formats, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'mau-sai-dinh-dang', 'x', '{SUMMARY}', '{DOC}', 'a', 'a')$$, '23514', 'mẫu báo cáo: định dạng ngoài PDF, XLSX, CSV, JSON bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, name, state, sections, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'mau-chua-duyet', 'x', 'ACTIVE', '{SUMMARY}', 'a', 'a')$$, '23514', 'mẫu ACTIVE phải có thời điểm kích hoạt');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_template SET sections = '{SUMMARY}' WHERE id = pg_temp.id('tpl')$$, '55000', 'mẫu báo cáo ACTIVE bất biến');
INSERT INTO ph16_kpi.kpi_report (id, tenant_id, report_code, report_type, title, period_id, template_id, created_by, updated_by)
VALUES (pg_temp.id('rep1'), 'T90', 'bc-thang-2026-10', 'PERIODIC', 'Báo cáo chỉ tiêu tháng 10/2026', pg_temp.id('p1'), pg_temp.id('tpl'), 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report (id, tenant_id, report_code, report_type, title, template_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bc-thieu-ky', 'PERIODIC', 'x', pg_temp.id('tpl'), 'a', 'a')$$, '23514', 'báo cáo định kỳ phải gắn kỳ');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report (id, tenant_id, report_code, report_type, title, template_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bc-dot-xuat', 'AD_HOC', 'x', pg_temp.id('tpl'), 'a', 'a')$$, '23514', 'báo cáo đột xuất phải có khoảng thời gian');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report (id, tenant_id, report_code, report_type, title, range_from, range_to, template_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bc-dot-xuat', 'AD_HOC', 'x', '2026-10-31', '2026-10-01', pg_temp.id('tpl'), 'a', 'a')$$, '23514', 'khoảng thời gian báo cáo đột xuất từ không sau đến');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report (id, tenant_id, report_code, report_type, title, period_id, template_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bc-thang-2026-10', 'PERIODIC', 'x', pg_temp.id('p1'), pg_temp.id('tpl'), 'a', 'a')$$, '23505', 'mã báo cáo duy nhất theo tenant');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_version (id, tenant_id, report_id, version_no, state, template_id, prepared_by, submitted_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rep1'), 1, 'IN_REVIEW', pg_temp.id('tpl'), 'an', now(), 'a', 'a')$$, '55000', 'phiên bản báo cáo mới phải ở DRAFT');
INSERT INTO ph16_kpi.kpi_report_version (id, tenant_id, report_id, version_no, template_id, run_id, snapshot, narrative, prepared_by, created_by, updated_by)
VALUES (pg_temp.id('rv1'), 'T90', pg_temp.id('rep1'), 1, pg_temp.id('tpl'), pg_temp.id('r2'), '{"indicators":[{"code":"httt-ket-noi-ty-le","value":83.0,"status":"AT_RISK","formulaVersion":2}]}', '{"summary":"Tỷ lệ kết nối đạt 83%"}', 'an', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_version (id, tenant_id, report_id, version_no, template_id, prepared_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rep1'), 1, pg_temp.id('tpl'), 'an', 'a', 'a')$$, '23505', 'mỗi báo cáo một số phiên bản duy nhất');
SELECT pg_temp.eq((SELECT current_version_no FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep1')), 1, 'báo cáo: phiên bản hiện tại là 1');
UPDATE ph16_kpi.kpi_report_version SET narrative = '{"summary":"Tỷ lệ kết nối đạt 83%, thấp hơn mục tiêu 90%"}' WHERE id = pg_temp.id('rv1');
UPDATE ph16_kpi.kpi_report_version SET state = 'IN_REVIEW', submitted_at = now() WHERE id = pg_temp.id('rv1');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep1') AND state = 'IN_REVIEW'), 1, 'báo cáo phản chiếu trạng thái IN_REVIEW của phiên bản');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET snapshot = '{}' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo đang IN_REVIEW không đổi ảnh chụp số liệu');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED' WHERE id = pg_temp.id('rv1')$$, '55000', 'IN_REVIEW không công bố thẳng (phải APPROVED)');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'APPROVED', approved_by = 'an', approved_at = now() WHERE id = pg_temp.id('rv1')$$, '23514', 'bốn mắt: người duyệt báo cáo khác người lập (trigger theo 16.report.four-eyes)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_approval (id, tenant_id, report_version_id, action, actor, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rv1'), 'APPROVE', 'an', 'a', 'a')$$, '23514', 'bốn mắt: người lập không ghi được hành động APPROVE');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_approval (id, tenant_id, report_version_id, action, actor, comment, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rv1'), 'REQUEST_CHANGES', 'binh', 'ngắn', 'a', 'a')$$, '23514', 'yêu cầu sửa báo cáo cần ý kiến từ 20 ký tự');
INSERT INTO ph16_kpi.kpi_report_approval (id, tenant_id, report_version_id, action, actor, created_by, updated_by) VALUES (pg_temp.id('ap1'), 'T90', pg_temp.id('rv1'), 'APPROVE', 'binh', 'binh', 'binh');
UPDATE ph16_kpi.kpi_report_version SET state = 'APPROVED', approved_by = 'binh', approved_at = now() WHERE id = pg_temp.id('rv1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_approval SET actor = 'khac' WHERE id = pg_temp.id('ap1')$$, '42501', 'ứng dụng không sửa nhật ký duyệt (chỉ thêm)');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET narrative = '{}' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo APPROVED không đổi thuyết minh');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc1'), object_ref = 'kpi-reports/T90/bc-thang-2026-10-v1.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv1')$$, '23514', 'công bố cần chữ ký số khi 16.report.signing bật');
INSERT INTO ph16_kpi.kpi_report_signature (id, tenant_id, report_version_id, signer, certificate_serial, signature_ref, signed_hash, created_by, updated_by)
VALUES (pg_temp.id('sg1'), 'T90', pg_temp.id('rv1'), 'binh', '5400B7E1', 'kpi-reports/T90/bc-thang-2026-10-v1.sig', pg_temp.h('khac'), 'binh', 'binh');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc1'), object_ref = 'kpi-reports/T90/bc-thang-2026-10-v1.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv1')$$, '23514', 'chữ ký số phải khớp mã băm nội dung công bố');
INSERT INTO ph16_kpi.kpi_report_signature (id, tenant_id, report_version_id, signer, certificate_serial, signature_ref, signed_hash, created_by, updated_by)
VALUES (pg_temp.id('sg2'), 'T90', pg_temp.id('rv1'), 'binh', '5400B7E1', 'kpi-reports/T90/bc-thang-2026-10-v1.sig', pg_temp.h('bc1'), 'binh', 'binh');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc1'), object_ref = 'kpi-reports/T90/bc-thang-2026-10-v1.pdf' WHERE id = pg_temp.id('rv1')$$, '23514', 'công bố phải có hạn lưu giữ (retain_until)');
UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc1'), object_ref = 'kpi-reports/T90/bc-thang-2026-10-v1.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv1');
SELECT pg_temp.eq((SELECT published_version_no FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep1')), 1, 'báo cáo nhớ phiên bản đang PUBLISHED');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET snapshot = '{"sua":1}' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo PUBLISHED bất biến: ảnh chụp số liệu');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET narrative = '{"sua":1}' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo PUBLISHED bất biến: thuyết minh');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET content_hash = pg_temp.h('khac') WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo PUBLISHED bất biến: mã băm nội dung');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET object_ref = 'kpi-reports/khac.pdf' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo PUBLISHED bất biến: tệp PDF ký số');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET retain_until = '2027-01-01' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo PUBLISHED bất biến: hạn lưu giữ');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'DRAFT' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo PUBLISHED không quay về DRAFT');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_report_version WHERE id = pg_temp.id('rv1')$$, '42501', 'ứng dụng không xóa phiên bản báo cáo');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'WITHDRAWN', withdrawn_by = 'binh', withdrawn_at = now(), withdraw_reason = 'ngắn' WHERE id = pg_temp.id('rv1')$$, '23514', 'rút báo cáo cần lý do từ 50 ký tự (FR-16-030)');
-- Đính chính: phiên bản 2
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_report_version (id, tenant_id, report_id, version_no, template_id, prepared_by, correction_of_version_no, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rep1'), 2, pg_temp.id('tpl'), 'an', 1, 'a', 'a')$$, '23514', 'đính chính phải có lý do đi cùng phiên bản được đính chính');
INSERT INTO ph16_kpi.kpi_report_version (id, tenant_id, report_id, version_no, template_id, run_id, snapshot, narrative, prepared_by, correction_of_version_no, correction_reason, created_by, updated_by)
VALUES (pg_temp.id('rv2'), 'T90', pg_temp.id('rep1'), 2, pg_temp.id('tpl'), pg_temp.id('r2'), '{"indicators":[{"code":"httt-ket-noi-ty-le","value":84.0,"status":"AT_RISK","formulaVersion":2}]}', '{"summary":"Đính chính số liệu kết nối"}', 'an', 1,
        'Đính chính tỷ lệ kết nối sau khi PH-01 gửi lại số liệu', 'an', 'an');
SELECT pg_temp.eq((SELECT current_version_no FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep1')), 2, 'đính chính tạo phiên bản 2, báo cáo trỏ tới phiên bản 2');
SELECT pg_temp.eq((SELECT published_version_no FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep1')), 1, 'trong khi đính chính phiên bản 1 vẫn là bản công bố');
UPDATE ph16_kpi.kpi_report_version SET state = 'IN_REVIEW', submitted_at = now() WHERE id = pg_temp.id('rv2');
UPDATE ph16_kpi.kpi_report_version SET state = 'APPROVED', approved_by = 'binh', approved_at = now() WHERE id = pg_temp.id('rv2');
INSERT INTO ph16_kpi.kpi_report_signature (id, tenant_id, report_version_id, signer, certificate_serial, signature_ref, signed_hash, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.id('rv2'), 'binh', '5400B7E1', 'kpi-reports/T90/bc-thang-2026-10-v2.sig', pg_temp.h('bc2'), 'binh', 'binh');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc2'), object_ref = 'kpi-reports/T90/bc-thang-2026-10-v2.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv2')$$, '23505', 'mỗi báo cáo một phiên bản PUBLISHED: phải SUPERSEDED bản cũ trước');
UPDATE ph16_kpi.kpi_report_version SET state = 'SUPERSEDED' WHERE id = pg_temp.id('rv1');
UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc2'), object_ref = 'kpi-reports/T90/bc-thang-2026-10-v2.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv2');
SELECT pg_temp.eq((SELECT published_version_no FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep1')), 2, 'đính chính xong: bản công bố là phiên bản 2, bản 1 SUPERSEDED');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET snapshot = '{}' WHERE id = pg_temp.id('rv1')$$, '55000', 'báo cáo SUPERSEDED cũng bất biến');
-- Báo cáo đột xuất, thiếu nguồn bắt buộc, rút báo cáo (tham số 16.report.signing tắt để không cần chữ ký)
INSERT INTO ph16_kpi.kpi_report (id, tenant_id, report_code, report_type, title, range_from, range_to, template_id, created_by, updated_by)
VALUES (pg_temp.id('rep2'), 'T90', 'bc-dot-xuat-q4', 'AD_HOC', 'Báo cáo đột xuất quý 4', '2026-10-01', '2026-12-31', pg_temp.id('tpl'), 'an', 'an');
INSERT INTO ph16_kpi.kpi_report_version (id, tenant_id, report_id, version_no, template_id, completeness, missing_mandatory, prepared_by, created_by, updated_by)
VALUES (pg_temp.id('rv3'), 'T90', pg_temp.id('rep2'), 1, pg_temp.id('tpl'), 'PARTIAL', true, 'an', 'an', 'an');
UPDATE ph16_kpi.kpi_report_version SET state = 'IN_REVIEW', submitted_at = now() WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET state = 'APPROVED', approved_by = 'binh', approved_at = now() WHERE id = pg_temp.id('rv3');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'DRAFT' WHERE id = pg_temp.id('rv3')$$, '55000', 'APPROVED không về thẳng DRAFT, phải qua CHANGES_REQUESTED');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'CHANGES_REQUESTED', decision_comment = 'ngắn' WHERE id = pg_temp.id('rv3')$$, '23514', 'trả báo cáo APPROVED về soạn cần ý kiến từ 20 ký tự');
UPDATE ph16_kpi.kpi_report_version SET state = 'CHANGES_REQUESTED', decision_comment = 'Ký số lỗi kéo dài, trả về soạn để cập nhật số liệu' WHERE id = pg_temp.id('rv3');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report_version WHERE id = pg_temp.id('rv3') AND state = 'CHANGES_REQUESTED'), 1, 'báo cáo APPROVED chưa công bố trả về CHANGES_REQUESTED (FR-16-028)');
UPDATE ph16_kpi.kpi_report_version SET state = 'DRAFT', document_number = '15/BC-STTTT', recipients_note = 'UBND tỉnh; Bộ KH và CN' WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET state = 'IN_REVIEW', submitted_at = now() WHERE id = pg_temp.id('rv3');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET document_number = '16/BC-STTTT' WHERE id = pg_temp.id('rv3')$$, '55000', 'số ký hiệu không đổi khi báo cáo đang duyệt');
UPDATE ph16_kpi.kpi_report_version SET state = 'APPROVED', approved_by = 'binh', approved_at = now() WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_tenant_setting SET value = 'false' WHERE param_code = '16.report.signing';
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc3'), object_ref = 'kpi-reports/T90/bc3.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv3')$$, '23514', 'chặn công bố khi còn chỉ tiêu bắt buộc thiếu nguồn');
UPDATE ph16_kpi.kpi_report_version SET state = 'CHANGES_REQUESTED', decision_comment = 'Bổ sung số liệu bắt buộc còn thiếu' WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET state = 'DRAFT' WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET missing_mandatory = false, completeness = 'COMPLETE' WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET state = 'IN_REVIEW' WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET state = 'APPROVED' WHERE id = pg_temp.id('rv3');
UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED', published_by = 'binh', published_at = now(), content_hash = pg_temp.h('bc3'), object_ref = 'kpi-reports/T90/bc3.pdf', retain_until = '2036-11-30' WHERE id = pg_temp.id('rv3');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep2') AND state = 'PUBLISHED'), 1, 'tắt 16.report.signing thì công bố không cần chữ ký');
UPDATE ph16_kpi.kpi_tenant_setting SET value = 'true' WHERE param_code = '16.report.signing';
UPDATE ph16_kpi.kpi_report_version SET state = 'WITHDRAWN', withdrawn_by = 'binh', withdrawn_at = now(), withdraw_reason = 'Rút do dùng sai kỳ so sánh, sẽ lập báo cáo mới thay thế trong tuần' WHERE id = pg_temp.id('rv3');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report WHERE id = pg_temp.id('rep2') AND state = 'WITHDRAWN' AND published_version_no IS NULL), 1, 'rút báo cáo: trạng thái WITHDRAWN, không còn bản công bố');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET state = 'PUBLISHED' WHERE id = pg_temp.id('rv3')$$, '55000', 'báo cáo WITHDRAWN là trạng thái cuối');

-- ---------- 7. Phân phối, lần giao, lệnh xuất ----------
INSERT INTO ph16_kpi.kpi_distribution (id, tenant_id, distribution_code, name, recipients, created_by, updated_by)
VALUES (pg_temp.id('di1'), 'T90', 'lanh-dao-ubnd', 'Lãnh đạo UBND', '[{"type":"GROUP","ref":"lanh-dao-ubnd"},{"type":"EMAIL","ref":"vanthu@tinh.gov.vn"}]', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_distribution (id, tenant_id, distribution_code, name, recipients, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'ds-sai', 'x', '{"type":"USER"}', 'a', 'a')$$, '23514', 'người nhận phải là mảng JSON');
INSERT INTO ph16_kpi.kpi_delivery (id, tenant_id, report_version_id, distribution_id, recipient_type, recipient_ref, created_by, updated_by) VALUES (pg_temp.id('dl1'), 'T90', pg_temp.id('rv2'), pg_temp.id('di1'), 'GROUP', 'lanh-dao-ubnd', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_delivery (id, tenant_id, report_version_id, distribution_id, recipient_type, recipient_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rv2'), pg_temp.id('di1'), 'GROUP', 'lanh-dao-ubnd', 'a', 'a')$$, '23505', 'mỗi người nhận một lần giao cho mỗi phiên bản, định dạng');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_delivery SET state = 'SENT' WHERE id = pg_temp.id('dl1')$$, '23514', 'lần giao SENT phải có thời điểm gửi');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_delivery SET state = 'FAILED' WHERE id = pg_temp.id('dl1')$$, '23514', 'lần giao FAILED phải có mã lỗi');
UPDATE ph16_kpi.kpi_delivery SET state = 'SENT', sent_at = now(), attempt = 1 WHERE id = pg_temp.id('dl1');
INSERT INTO ph16_kpi.kpi_export_job (id, tenant_id, subject_type, period_id, format, requested_by, created_by, updated_by) VALUES (pg_temp.id('ex1'), 'T90', 'INDICATOR_VALUES', pg_temp.id('p1'), 'XLSX', 'an', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_export_job (id, tenant_id, subject_type, format, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'INDICATOR_VALUES', 'CSV', 'an', 'a', 'a')$$, '23514', 'xuất bảng chỉ tiêu phải chỉ rõ kỳ');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_export_job (id, tenant_id, subject_type, format, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'REPORT', 'PDF', 'an', 'a', 'a')$$, '23514', 'xuất báo cáo phải chỉ rõ phiên bản');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_export_job SET state = 'SUCCEEDED', finished_at = now() WHERE id = pg_temp.id('ex1')$$, '55000', 'lệnh xuất QUEUED phải qua RUNNING');
UPDATE ph16_kpi.kpi_export_job SET state = 'RUNNING', started_at = now() WHERE id = pg_temp.id('ex1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_export_job SET state = 'SUCCEEDED', finished_at = now() WHERE id = pg_temp.id('ex1')$$, '23514', 'xuất xong phải có tệp, mã băm và hạn tải');
UPDATE ph16_kpi.kpi_export_job SET state = 'SUCCEEDED', finished_at = now(), row_count = 24, object_ref = 'kpi-exports/T90/ex1.xlsx', content_hash = pg_temp.h('ex1'), expires_at = now() + interval '24 hours' WHERE id = pg_temp.id('ex1');
UPDATE ph16_kpi.kpi_export_job SET state = 'EXPIRED' WHERE id = pg_temp.id('ex1');

-- ---------- 8. Sổ kiến trúc, tuân thủ, miễn trừ ----------
INSERT INTO ph16_kpi.kpi_arch_component (id, tenant_id, component_code, name, component_type, origin, source_phase, created_by, updated_by)
VALUES (pg_temp.id('c1'), 'T90', 'cong-api-trung-tam', 'Cổng API trung tâm', 'PLATFORM_SERVICE', 'AUTO', 'PH-03', 'sys', 'sys'),
       (pg_temp.id('c2'), 'T90', 'httt-quan-ly-van-ban', 'HTTT quản lý văn bản', 'HTTT', 'MANUAL', NULL, 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_component (id, tenant_id, component_code, name, component_type, origin, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'tu-dong-thieu-nguon', 'x', 'API', 'AUTO', 'a', 'a')$$, '23514', 'thành phần AUTO phải nêu phân hệ nguồn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_component (id, tenant_id, component_code, name, component_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'loai-la', 'x', 'DATABASE', 'a', 'a')$$, '23514', 'loại thành phần ngoài bảy loại bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_component (id, tenant_id, component_code, name, component_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'cong-api-trung-tam', 'x', 'API', 'a', 'a')$$, '23505', 'mã thành phần duy nhất theo tenant');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_component SET ops_status = 'BROKEN' WHERE id = pg_temp.id('c1')$$, '23514', 'trạng thái vận hành ngoài UP, DEGRADED, DOWN, UNKNOWN bị chặn');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_component SET lifecycle = 'DEPRECATED' WHERE id = pg_temp.id('c1')$$, '55000', 'PLANNED không sang DEPRECATED thẳng');
UPDATE ph16_kpi.kpi_arch_component SET lifecycle = 'ACTIVE', ops_status = 'UP', ops_updated_at = now() WHERE id = pg_temp.id('c1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_component SET lifecycle = 'PLANNED' WHERE id = pg_temp.id('c1')$$, '55000', 'ACTIVE không quay về PLANNED');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_component SET lifecycle = 'RETIRED' WHERE id = pg_temp.id('c1')$$, '23514', 'ngừng thành phần cần lý do từ 20 ký tự');
UPDATE ph16_kpi.kpi_arch_component SET lifecycle = 'ACTIVE' WHERE id = pg_temp.id('c2');
INSERT INTO ph16_kpi.kpi_arch_component_version (id, tenant_id, component_id, version_label, lifecycle, content_hash, created_by, updated_by) VALUES (pg_temp.id('cv1'), 'T90', pg_temp.id('c1'), '1.4.0', 'ACTIVE', pg_temp.h('c1-1.4.0'), 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_component_version (id, tenant_id, component_id, version_label, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('c1'), '1.4.0', 'a', 'a')$$, '23505', 'nhãn phiên bản thành phần duy nhất');
INSERT INTO ph16_kpi.kpi_arch_dependency (id, tenant_id, from_component_id, to_component_id, dependency_type, origin, created_by, updated_by) VALUES (pg_temp.id('dp1'), 'T90', pg_temp.id('c2'), pg_temp.id('c1'), 'CALLS', 'AUTO', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_dependency (id, tenant_id, from_component_id, to_component_id, dependency_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('c1'), pg_temp.id('c1'), 'CALLS', 'a', 'a')$$, '23514', 'thành phần không phụ thuộc chính nó');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_dependency (id, tenant_id, from_component_id, to_component_id, dependency_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('c2'), pg_temp.id('c1'), 'CALLS', 'a', 'a')$$, '23505', 'một phụ thuộc cùng loại giữa hai thành phần chỉ một dòng');
INSERT INTO ids SELECT 'cr1', id FROM ph16_kpi.kpi_compliance_criterion WHERE tenant_id = 'T90' AND criterion_code = 'AR-REG-01';
INSERT INTO ids SELECT 'cr2', id FROM ph16_kpi.kpi_compliance_criterion WHERE tenant_id = 'T90' AND criterion_code = 'AR-SEC-01';
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_criterion SET weight = 0.5 WHERE id = pg_temp.id('cr1')$$, '55000', 'tiêu chí ACTIVE bất biến');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_compliance_criterion (id, tenant_id, criterion_code, name, applies_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'AR-X-01', 'x', '{KHAC}', 'a', 'a')$$, '23514', 'tiêu chí áp cho loại thành phần ngoài enum bị chặn');
INSERT INTO ph16_kpi.kpi_compliance_assessment (id, tenant_id, component_id, component_version_id, assessed_by, created_by, updated_by) VALUES (pg_temp.id('as1'), 'T90', pg_temp.id('c1'), pg_temp.id('cv1'), 'an', 'an', 'an');
INSERT INTO ph16_kpi.kpi_compliance_item (id, tenant_id, assessment_id, criterion_id, result, created_by, updated_by) VALUES (pg_temp.id('it1'), 'T90', pg_temp.id('as1'), pg_temp.id('cr1'), 'PASS', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_compliance_item (id, tenant_id, assessment_id, criterion_id, result, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('as1'), pg_temp.id('cr1'), 'PASS', 'a', 'a')$$, '23505', 'mỗi đánh giá một mục cho mỗi tiêu chí');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_compliance_item (id, tenant_id, assessment_id, criterion_id, result, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('as1'), pg_temp.id('cr2'), 'FAIL', 'a', 'a')$$, '23514', 'mục không đạt phải có ghi chú từ 20 ký tự');
INSERT INTO ph16_kpi.kpi_compliance_item (id, tenant_id, assessment_id, criterion_id, result, note, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('as1'), pg_temp.id('cr2'), 'FAIL', 'Đã phân loại, chưa có hồ sơ cấp độ', 'an', 'an');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_assessment SET state = 'SUBMITTED' WHERE id = pg_temp.id('as1')$$, '23514', 'gửi xác nhận đánh giá phải có kết quả mức tuân thủ');
UPDATE ph16_kpi.kpi_compliance_assessment SET state = 'SUBMITTED', submitted_at = now(), level_result = 'PARTIAL', score = 75 WHERE id = pg_temp.id('as1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_item SET result = 'PASS' WHERE id = pg_temp.id('it1')$$, '55000', 'đánh giá đã gửi không sửa mục đánh giá');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_assessment SET state = 'CONFIRMED', confirmed_by = 'an', confirmed_at = now() WHERE id = pg_temp.id('as1')$$, '23514', 'bốn mắt: người xác nhận đánh giá khác người đánh giá');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_assessment SET state = 'REJECTED', confirmed_by = 'binh', confirmed_at = now(), decision_comment = 'ngắn' WHERE id = pg_temp.id('as1')$$, '23514', 'từ chối đánh giá cần lý do từ 20 ký tự');
UPDATE ph16_kpi.kpi_compliance_assessment SET state = 'CONFIRMED', confirmed_by = 'binh', confirmed_at = now() WHERE id = pg_temp.id('as1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_assessment SET level_result = 'COMPLIANT' WHERE id = pg_temp.id('as1')$$, '55000', 'đánh giá CONFIRMED bất biến');
UPDATE ph16_kpi.kpi_arch_component SET compliance_level = 'PARTIAL' WHERE id = pg_temp.id('c1');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_compliance_waiver (id, tenant_id, component_id, criterion_id, reason, valid_from, valid_to, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('c1'), pg_temp.id('cr2'), 'ngắn', '2026-11-26', '2027-03-26', 'an', 'a', 'a')$$, '23514', 'miễn trừ cần lý do từ 50 ký tự (FR-16-047)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_compliance_waiver (id, tenant_id, component_id, criterion_id, reason, valid_from, valid_to, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('c1'), pg_temp.id('cr2'), 'Chờ hồ sơ cấp độ được cơ quan có thẩm quyền phê duyệt', '2026-11-26', '2028-01-01', 'an', 'a', 'a')$$, '23514', 'miễn trừ có hạn không quá 366 ngày');
INSERT INTO ph16_kpi.kpi_compliance_waiver (id, tenant_id, component_id, criterion_id, reason, valid_from, valid_to, requested_by, created_by, updated_by)
VALUES (pg_temp.id('wv1'), 'T90', pg_temp.id('c1'), pg_temp.id('cr2'), 'Chờ hồ sơ cấp độ được cơ quan có thẩm quyền phê duyệt', '2026-11-26', '2027-03-26', 'an', 'an', 'an');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_waiver SET state = 'ACTIVE', approved_by = 'an', approved_at = now() WHERE id = pg_temp.id('wv1')$$, '23514', 'bốn mắt: người duyệt miễn trừ khác người đề nghị');
UPDATE ph16_kpi.kpi_compliance_waiver SET state = 'ACTIVE', approved_by = 'binh', approved_at = now() WHERE id = pg_temp.id('wv1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_compliance_waiver SET valid_to = '2027-11-01' WHERE id = pg_temp.id('wv1')$$, '55000', 'miễn trừ đã duyệt không đổi hạn');
UPDATE ph16_kpi.kpi_compliance_waiver SET state = 'EXPIRED' WHERE id = pg_temp.id('wv1');

-- ---------- 8b. Nhập tệp số liệu tay (EN-16-13), đối chiếu sổ kiến trúc (EN-16-33), yêu cầu tính lại ----------
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['im1','ir1','ir2','rc1','ri1','ri2']) k;
INSERT INTO ph16_kpi.kpi_manual_import (id, tenant_id, file_name, object_ref, content_hash, row_total, valid_count, invalid_count, uploaded_by, expires_at, created_by, updated_by)
VALUES (pg_temp.id('im1'), 'T90', 'nhap-so-lieu-q3.xlsx', 'kpi-evidence/T90/imports/im1.xlsx', pg_temp.h('im1'), 2, 1, 1, 'an', now() + interval '24 hours', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_import (id, tenant_id, file_name, object_ref, content_hash, row_total, uploaded_by, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x.xlsx', 'kpi-evidence/x', pg_temp.h('x'), 2001, 'an', now() + interval '1 hour', 'a', 'a')$$, '23514', 'tệp nhập tối đa 2.000 dòng (ERR-16-020)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_import (id, tenant_id, file_name, object_ref, content_hash, row_total, uploaded_by, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x.xlsx', 'kpi-evidence/x', pg_temp.h('x'), 1, 'an', now() + interval '3 days', 'a', 'a')$$, '23514', 'bản xem trước giữ tối đa 24 giờ');
INSERT INTO ph16_kpi.kpi_manual_import_row (id, tenant_id, import_id, row_no, indicator_code, period_code, value, row_status, created_by, updated_by)
VALUES (pg_temp.id('ir1'), 'T90', pg_temp.id('im1'), 1, 'diem-hai-long-sus', 'M-2026-10', 72.5, 'VALID', 'an', 'an');
INSERT INTO ph16_kpi.kpi_manual_import_row (id, tenant_id, import_id, row_no, indicator_code, period_code, value, row_status, error_code, detail, created_by, updated_by)
VALUES (pg_temp.id('ir2'), 'T90', pg_temp.id('im1'), 2, 'khong-co', 'M-2026-10', 1, 'INVALID', 'ERR-16-019', 'Chỉ tiêu không có trong bộ', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_import_row (id, tenant_id, import_id, row_no, row_status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('im1'), 3, 'INVALID', 'a', 'a')$$, '23514', 'dòng INVALID phải có mã lỗi');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_import_row SET row_status = 'IMPORTED' WHERE id = pg_temp.id('ir1')$$, '23514', 'dòng IMPORTED phải trỏ tới số liệu tay đã tạo');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_import_row SET row_status = 'VALID', error_code = NULL WHERE id = pg_temp.id('ir2')$$, '55000', 'dòng INVALID không chuyển thành VALID (tải tệp mới)');
UPDATE ph16_kpi.kpi_manual_import_row SET row_status = 'IMPORTED', manual_value_id = pg_temp.id('m1') WHERE id = pg_temp.id('ir1');
UPDATE ph16_kpi.kpi_manual_import SET imported_count = 1, committed_by = 'an', committed_at = now() WHERE id = pg_temp.id('im1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_manual_import SET row_total = 5 WHERE id = pg_temp.id('im1')$$, '55000', 'số dòng của tệp nhập bất biến');
INSERT INTO ph16_kpi.kpi_arch_reconciliation (id, tenant_id, component_types, started_by, created_by, updated_by) VALUES (pg_temp.id('rc1'), 'T90', '{HTTT,API}', 'system:schedule', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_reconciliation (id, tenant_id, started_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'an', 'a', 'a')$$, '23505', 'mỗi tenant một lần đối chiếu đang chạy (ERR-16-056)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_reconciliation (id, tenant_id, component_types, started_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '{KHAC}', 'an', 'a', 'a')$$, '23514', 'loại thành phần đối chiếu ngoài enum bị chặn');
INSERT INTO ph16_kpi.kpi_arch_recon_item (id, tenant_id, recon_id, item_kind, component_code, component_id, source_phase, source_ref, diff, created_by, updated_by)
VALUES (pg_temp.id('ri1'), 'T90', pg_temp.id('rc1'), 'ORPHAN', 'cong-api-trung-tam', pg_temp.id('c1'), 'PH-03', 'ph03:cong-api-trung-tam', '{}', 'sys', 'sys'),
       (pg_temp.id('ri2'), 'T90', pg_temp.id('rc1'), 'MISSING', 'httt-ho-tich', NULL, 'PH-01', 'ph01:httt-ho-tich', '{"lifecycle":"ACTIVE"}', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_arch_recon_item (id, tenant_id, recon_id, item_kind, component_code, source_phase, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('rc1'), 'ORPHAN', 'khong-co', 'PH-01', 'a', 'a')$$, '23514', 'mục ORPHAN phải trỏ tới thành phần trong sổ');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_recon_item SET resolution = 'IGNORED', resolution_reason = 'ngắn', resolved_by = 'an', resolved_at = now() WHERE id = pg_temp.id('ri1')$$, '23514', 'bỏ qua mục lệch cần lý do từ 20 ký tự');
UPDATE ph16_kpi.kpi_arch_recon_item SET resolution = 'REGISTERED', resolved_by = 'an', resolved_at = now() WHERE id = pg_temp.id('ri2');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_recon_item SET resolution = 'OPEN', resolved_by = NULL, resolved_at = NULL WHERE id = pg_temp.id('ri2')$$, '55000', 'mục đã xử lý không mở lại');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_reconciliation SET state = 'PARTIAL', finished_at = now() WHERE id = pg_temp.id('rc1')$$, '23514', 'đối chiếu PARTIAL phải ghi phân hệ bỏ qua');
UPDATE ph16_kpi.kpi_arch_reconciliation SET state = 'PARTIAL', finished_at = now(), skipped_phases = '{PH-10}', item_count = 2 WHERE id = pg_temp.id('rc1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_arch_reconciliation SET state = 'RUNNING', finished_at = NULL WHERE id = pg_temp.id('rc1')$$, '55000', 'lần đối chiếu đã kết thúc không chạy lại');
UPDATE ph16_kpi.kpi_reporting_period SET recompute_requested_at = now() WHERE id = pg_temp.id('p2');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_reporting_period WHERE recompute_requested_at IS NOT NULL), 1, 'kỳ ghi mốc yêu cầu tính lại để bộ quét gom (FR-16-023)');

-- ---------- 9. Gói gửi quốc gia, nhật ký nộp chỉ thêm ----------
INSERT INTO ph16_kpi.kpi_national_template (id, tenant_id, template_code, name, submission_type, mapping, created_by, updated_by) VALUES (pg_temp.id('nt1'), 'T90', 'goi-bao-cao-chi-tieu', 'Gói báo cáo chỉ tiêu', 'KPI_REPORT', '{"fields":[]}', 'an', 'an');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_template SET state = 'ACTIVE', activated_at = now() WHERE id = pg_temp.id('nt1')$$, '23514', 'mẫu gói quốc gia ACTIVE phải có người duyệt');
UPDATE ph16_kpi.kpi_national_template SET state = 'ACTIVE', approved_by = 'binh', activated_at = now() WHERE id = pg_temp.id('nt1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_template SET mapping = '{}' WHERE id = pg_temp.id('nt1')$$, '55000', 'mẫu gói quốc gia ACTIVE bất biến, đổi cần phiên bản mới');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, report_version_id, report_code, report_version_no, content_hash, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'KPI_REPORT', pg_temp.id('nt1'), pg_temp.id('rv2'), 'bc-thang-2026-10', 2, pg_temp.h('bc2'), 'an', 'a', 'a')$$, '55000', 'gửi quốc gia khi 16.national.enabled tắt (mặc định) bị chặn');
UPDATE ph16_kpi.kpi_tenant_setting SET value = 'true' WHERE param_code = '16.national.enabled';
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, report_version_id, report_code, report_version_no, content_hash, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'KPI_REPORT', pg_temp.id('nt1'), pg_temp.id('rv1'), 'bc-thang-2026-10', 1, pg_temp.h('bc1'), 'an', 'a', 'a')$$, '55000', 'chỉ gửi quốc gia phiên bản báo cáo đã PUBLISHED (bản 1 đã SUPERSEDED)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, report_version_id, report_code, report_version_no, component_code, content_hash, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'KPI_REPORT', pg_temp.id('nt1'), pg_temp.id('rv2'), 'bc-thang-2026-10', 2, 'x', pg_temp.h('bc2'), 'an', 'a', 'a')$$, '23514', 'gói báo cáo không mang thông tin thành phần kiến trúc');
INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, report_version_id, report_code, report_version_no, content_hash, submitted_by, created_by, updated_by)
VALUES (pg_temp.id('sub1'), 'T90', 'KPI_REPORT', pg_temp.id('nt1'), pg_temp.id('rv2'), 'bc-thang-2026-10', 2, pg_temp.h('bc2'), 'an', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, report_version_id, report_code, report_version_no, content_hash, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'KPI_REPORT', pg_temp.id('nt1'), pg_temp.id('rv2'), 'bc-thang-2026-10', 2, pg_temp.h('bc2'), 'an', 'a', 'a')$$, '23505', 'idempotent: một gói cho mỗi (reportCode, phiên bản)');
INSERT INTO ph16_kpi.kpi_national_template (id, tenant_id, template_code, name, submission_type, state, mapping, approved_by, activated_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'goi-so-kien-truc', 'Gói sổ kiến trúc', 'ARCH_REGISTRY', 'ACTIVE', '{}', 'binh', now(), 'an', 'an');
INSERT INTO ids SELECT 'nt2', id FROM ph16_kpi.kpi_national_template WHERE tenant_id = 'T90' AND template_code = 'goi-so-kien-truc';
INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, component_version_id, component_code, version_label, content_hash, submitted_by, created_by, updated_by)
VALUES (pg_temp.id('sub2'), 'T90', 'ARCH_REGISTRY', pg_temp.id('nt2'), pg_temp.id('cv1'), 'cong-api-trung-tam', '1.4.0', pg_temp.h('c1-1.4.0'), 'an', 'an', 'an');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, component_version_id, component_code, version_label, content_hash, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'ARCH_REGISTRY', pg_temp.id('nt2'), pg_temp.id('cv1'), 'cong-api-trung-tam', '1.4.0', pg_temp.h('c1-1.4.0'), 'an', 'a', 'a')$$, '23505', 'idempotent: một gói cho mỗi (componentCode, phiên bản, contentHash)');
INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, component_version_id, component_code, version_label, content_hash, submitted_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'ARCH_REGISTRY', pg_temp.id('nt2'), pg_temp.id('cv1'), 'cong-api-trung-tam', '1.4.0', pg_temp.h('c1-1.4.0-doi'), 'an', 'an', 'an');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_national_submission WHERE submission_type = 'ARCH_REGISTRY'), 2, 'cùng thành phần, phiên bản nhưng nội dung đổi thì gửi gói mới');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_submission SET state = 'SENT' WHERE id = pg_temp.id('sub1')$$, '55000', 'gói PENDING không sang SENT thẳng');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_submission SET report_code = 'bc-khac' WHERE id = pg_temp.id('sub1')$$, '55000', 'mã báo cáo của gói đã tạo bất biến');
UPDATE ph16_kpi.kpi_national_submission SET state = 'SENDING', attempt_count = 1 WHERE id = pg_temp.id('sub1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_submission SET state = 'FAILED' WHERE id = pg_temp.id('sub1')$$, '23514', 'gói FAILED phải có mã lỗi');
UPDATE ph16_kpi.kpi_national_submission SET state = 'FAILED', last_error_code = 'ERR-16-150', last_error_detail = 'PH-14 báo kênh quốc gia không phản hồi' WHERE id = pg_temp.id('sub1');
UPDATE ph16_kpi.kpi_national_submission SET state = 'SENDING', attempt_count = 2 WHERE id = pg_temp.id('sub1');
UPDATE ph16_kpi.kpi_national_submission SET state = 'SENT', sent_at = now(), channel_ref = 'p14-tx-0001' WHERE id = pg_temp.id('sub1');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_submission SET state = 'ACKNOWLEDGED', ack_at = now() WHERE id = pg_temp.id('sub1')$$, '23514', 'biên nhận phải có mã và thời điểm');
UPDATE ph16_kpi.kpi_national_submission SET state = 'ACKNOWLEDGED', ack_at = now(), ack_ref = 'bn-2026-0001' WHERE id = pg_temp.id('sub1');
INSERT INTO ph16_kpi.kpi_national_submission_log (id, tenant_id, submission_id, seq, event_type, state_after, actor, request_hash, response_hash, channel_ref, created_by, updated_by)
VALUES (pg_temp.id('lo1'), 'T90', pg_temp.id('sub1'), 1, 'ACKNOWLEDGED', 'ACKNOWLEDGED', 'ph14-adapter', pg_temp.h('req'), pg_temp.h('resp'), 'p14-tx-0001', 'sys', 'sys');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission_log (id, tenant_id, submission_id, seq, event_type, state_after, actor, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('sub1'), 1, 'RETRY', 'SENDING', 'a', 'a', 'a')$$, '23505', 'thứ tự nhật ký nộp duy nhất theo gói');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission_log (id, tenant_id, submission_id, seq, event_type, state_after, actor, request_hash, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('sub1'), 2, 'SENT', 'SENT', 'a', '\x00', 'a', 'a')$$, '23514', 'băm yêu cầu trong nhật ký nộp đủ 32 byte');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_submission_log SET detail = 'sửa' WHERE id = pg_temp.id('lo1')$$, '42501', 'ứng dụng không sửa nhật ký nộp');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_national_submission_log WHERE id = pg_temp.id('lo1')$$, '42501', 'ứng dụng không xóa nhật ký nộp');

-- ---------- 10. Tham số, outbox, inbox ----------
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '16.khong.co', '1', 'a', 'a')$$, '23514', 'chỉ nhận mã tham số 16.* đã khai báo');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_tenant_setting SET value = '"co"' WHERE param_code = '16.report.four-eyes'$$, '23514', 'tham số boolean phải có giá trị boolean');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_tenant_setting SET value = '"5"' WHERE param_code = '16.period.close-day'$$, '23514', 'tham số số phải có giá trị số');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_tenant_setting SET value = '3' WHERE param_code = '16.period.types'$$, '23514', 'tham số chuỗi phải có giá trị chuỗi');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_tenant_setting$$, '42501', 'ứng dụng không xóa tham số');
INSERT INTO ph16_kpi.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.kpi.report.published.v1', 'report', pg_temp.id('rep1'), '{"reportCode":"bc-thang-2026-10","version":2}', repeat('a', 32));
INSERT INTO ph16_kpi.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.audit.recorded.v1', 'audit', pg_temp.id('rep1'), '{}', repeat('b', 32));
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't91.kpi.report.published.v1', 'report', gen_random_uuid(), '{}', repeat('a', 32))$$, '23514', 'topic outbox phải mang tiền tố tenant của dòng');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.kpi.khac.created.v1', 'report', gen_random_uuid(), '{}', repeat('a', 32))$$, '23514', 'chỉ nhận 13 topic EVT-16 và kiểm toán');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.outbox_event (tenant_id, event_id, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 't90.kpi.report.published.v1', 'report', gen_random_uuid(), '{}', 'ZZ')$$, '23514', 'trace_id phải là 32 ký tự hex');
SELECT pg_temp.expect($$UPDATE ph16_kpi.outbox_event SET published_at = now()$$, '42501', 'ứng dụng không UPDATE outbox (relay Debezium đọc WAL)');
INSERT INTO ph16_kpi.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'ObservationConsumer', '00000000-0000-0000-0000-0000000000a1', 't90.dq.kpi.published.v1');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'ObservationConsumer', '00000000-0000-0000-0000-0000000000a1', 't90.dq.kpi.published.v1')$$, '23505', 'inbox khử trùng sự kiện nhận theo (tenant, consumer, event_id)');

-- ---------- 11. Cô lập tenant ----------
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_tenant_setting), 25, 'T91 chỉ thấy 25 tham số của mình (đã seed)');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id <> 'COMMON'), 0, 'T91 không thấy chỉ tiêu của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_version) + (SELECT count(*) FROM ph16_kpi.kpi_indicator_threshold), 0, 'T91 không thấy phiên bản định nghĩa, ngưỡng của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_data_source) + (SELECT count(*) FROM ph16_kpi.kpi_source_contract) + (SELECT count(*) FROM ph16_kpi.kpi_ingest_log), 0, 'T91 không thấy nguồn, hợp đồng, nhật ký tiếp nhận của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_observation), 0, 'T91 không thấy quan sát của T90 (kể cả cùng idempotency_ref)');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_manual_value) + (SELECT count(*) FROM ph16_kpi.kpi_manual_evidence), 0, 'T91 không thấy số liệu tay, bằng chứng của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_reporting_period) + (SELECT count(*) FROM ph16_kpi.kpi_aggregation_run), 0, 'T91 không thấy kỳ, lần tổng hợp của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator_value) + (SELECT count(*) FROM ph16_kpi.kpi_value_lineage) + (SELECT count(*) FROM ph16_kpi.kpi_group_score), 0, 'T91 không thấy giá trị chỉ tiêu, truy nguồn, điểm nhóm của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report) + (SELECT count(*) FROM ph16_kpi.kpi_report_version) + (SELECT count(*) FROM ph16_kpi.kpi_report_signature) + (SELECT count(*) FROM ph16_kpi.kpi_report_approval), 0, 'T91 không thấy báo cáo, phiên bản, chữ ký, duyệt của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_distribution) + (SELECT count(*) FROM ph16_kpi.kpi_delivery) + (SELECT count(*) FROM ph16_kpi.kpi_export_job), 0, 'T91 không thấy phân phối, lần giao, lệnh xuất của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_arch_component) + (SELECT count(*) FROM ph16_kpi.kpi_arch_component_version) + (SELECT count(*) FROM ph16_kpi.kpi_arch_dependency), 0, 'T91 không thấy sổ kiến trúc của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_compliance_assessment) + (SELECT count(*) FROM ph16_kpi.kpi_compliance_item) + (SELECT count(*) FROM ph16_kpi.kpi_compliance_waiver), 0, 'T91 không thấy đánh giá, mục đánh giá, miễn trừ của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_national_submission) + (SELECT count(*) FROM ph16_kpi.kpi_national_submission_log) + (SELECT count(*) FROM ph16_kpi.outbox_event) + (SELECT count(*) FROM ph16_kpi.inbox_event), 0, 'T91 không thấy gói quốc gia, nhật ký nộp, outbox, inbox của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_national_template WHERE tenant_id <> 'COMMON') + (SELECT count(*) FROM ph16_kpi.kpi_report_template WHERE tenant_id = 'T90'), 0, 'T91 không thấy mẫu quốc gia, mẫu báo cáo của T90');
UPDATE ph16_kpi.kpi_indicator SET name = 'tấn công' WHERE id = pg_temp.id('i1');
UPDATE ph16_kpi.kpi_report_version SET narrative = '{"tan":"cong"}' WHERE id = pg_temp.id('rv1');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE name = 'tấn công'), 0, 'T91 UPDATE chỉ tiêu, báo cáo của T90 không có tác dụng (0 dòng)');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '16.export.max-rows', '1', 'zz', 'zz')$$, '42501', 'T91 không ghi được dòng mang tenant T90');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_manual_value (id, tenant_id, indicator_id, period_id, value, entered_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('i2'), pg_temp.id('p1'), 1, 'zz', 'zz', 'zz')$$, '23503', 'khóa ngoại kèm tenant: T91 không trỏ được tới chỉ tiêu, kỳ của T90');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_observation (id, tenant_id, source_id, metric_code, value, period_start, period_end, idempotency_ref, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('s1'), 'ph01.httt.total', 1, '2026-10-01', '2026-10-02', 'evt-x', 'EVENT', 'zz', 'zz')$$, '23503', 'T91 không gắn quan sát vào nguồn của T90');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_national_submission (id, tenant_id, submission_type, template_id, report_version_id, report_code, report_version_no, content_hash, submitted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'KPI_REPORT', pg_temp.id('nt1'), pg_temp.id('rv2'), 'x', 1, pg_temp.h('x'), 'zz', 'zz', 'zz')$$, '55000', 'T91 chưa bật gửi quốc gia nên không tạo được gói');
-- Mẫu RLS S: đọc COMMON, không ghi COMMON
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON'), 24, 'mẫu RLS S: T91 đọc được 24 chỉ tiêu COMMON');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_compliance_criterion WHERE tenant_id = 'COMMON') + (SELECT count(*) FROM ph16_kpi.kpi_report_template WHERE tenant_id = 'COMMON') + (SELECT count(*) FROM ph16_kpi.kpi_indicator_group WHERE tenant_id = 'COMMON'), 12, 'mẫu RLS S: T91 đọc tiêu chí, mẫu báo cáo, nhóm COMMON');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'mau-tu-t91', 'KET_NOI', 'x', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'COMMON', 'zz', 'zz')$$, '42501', 'chỉ phiên PLATFORM ghi được chỉ tiêu COMMON');
UPDATE ph16_kpi.kpi_indicator SET name = 'đổi mẫu' WHERE tenant_id = 'COMMON';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE name = 'đổi mẫu'), 0, 'T91 UPDATE chỉ tiêu COMMON không có tác dụng');
SELECT pg_temp.expect($$CALL ph16_kpi.p_seed_common()$$, '42501', 'ứng dụng không gọi được p_seed_common');
INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, scope, template_code, created_by, updated_by)
VALUES (gen_random_uuid(), 'T91', 'httt-ket-noi-ty-le', 'KET_NOI', 'Kế thừa mẫu COMMON', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'TENANT', 'httt-ket-noi-ty-le', 'zz', 'zz');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'T91'), 1, 'T91 kế thừa chỉ tiêu mẫu thành bản sao riêng, trùng mã với T90 không xung đột');
-- Quên đặt biến phiên: không thấy dòng nào
RESET app.tenant_id;
SET app.tenant_id = '';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report_version), 0, 'app.tenant_id rỗng thì không thấy dòng nào');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '16.export.max-rows', '1', 'zz', 'zz')$$, '42501', 'app.tenant_id rỗng thì không ghi được');
RESET app.tenant_id;
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report), 0, 'RESET app.tenant_id thì không thấy dòng nào');
-- Tenant ngoài dạng Tnn
SET app.tenant_id = 'T9';
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T9', '16.export.max-rows', '1', 'zz', 'zz')$$, '42501', 'tenant_id ngoài dạng Tnn bị chính sách RLS chặn');
SET app.tenant_id = 'T90';

-- ---------- 12. So sánh liên tenant ẩn danh (ngoại lệ RLS duy nhất) ----------
RESET ROLE;
SET ROLE ph16_compare;
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.v_compare_value WHERE tenant_id = 'T90'), 1, 'vai so sánh đọc giá trị hiện hành đã có số của tenant khác (không đọc dòng NO_DATA, dòng không hiện hành)');
SELECT pg_temp.expect($$SELECT count(*) FROM ph16_kpi.kpi_report$$, '42501', 'vai so sánh không đọc báo cáo');
SELECT pg_temp.expect($$SELECT count(*) FROM ph16_kpi.kpi_manual_value$$, '42501', 'vai so sánh không đọc số liệu tay');
SELECT pg_temp.expect($$SELECT status FROM ph16_kpi.kpi_indicator_value$$, '42501', 'vai so sánh không đọc cột trạng thái, truy nguồn của giá trị');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', '16.export.max-rows', '1', 'a', 'a')$$, '42501', 'vai so sánh không ghi');
RESET ROLE;
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';

-- ---------- 13. Quyền vai trò ----------
SELECT pg_temp.expect($$CREATE TABLE ph16_kpi.x (a int)$$, '42501', 'ứng dụng không tạo được bảng trong schema');
SELECT pg_temp.expect($$DROP TABLE ph16_kpi.kpi_report$$, '42501', 'ứng dụng không xóa được bảng');
SELECT pg_temp.expect($$ALTER TABLE ph16_kpi.kpi_report DISABLE ROW LEVEL SECURITY$$, '42501', 'ứng dụng không tắt được RLS');
SELECT pg_temp.expect($$ALTER TABLE ph16_kpi.kpi_report_version DISABLE TRIGGER tg_kpi_report_version_frozen$$, '42501', 'ứng dụng không tắt được trigger bất biến');
RESET ROLE;
SET ROLE dh_kpi_ro;
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report_version WHERE state = 'PUBLISHED'), 1, 'vai chỉ đọc đọc được báo cáo công bố của tenant phiên');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET narrative = '{}'$$, '42501', 'vai chỉ đọc không ghi');
SELECT pg_temp.expect($$INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '16.export.max-rows', '1', 'a', 'a')$$, '42501', 'vai chỉ đọc không thêm');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report_version), 0, 'vai chỉ đọc cũng bị RLS theo tenant');
RESET ROLE;

-- ---------- 14. Chủ schema vẫn chịu RLS, trigger; dọn bằng phân vùng; seed chạy lại ----------
SET ROLE ph16_owner;
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_report_version), 0, 'chủ schema bị FORCE RLS: tenant T91 không thấy dữ liệu T90');
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_observation SET value = 1$$, '55000', 'trigger chặn UPDATE quan sát kể cả chủ schema');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_value_lineage$$, '55000', 'trigger chặn DELETE dòng truy nguồn kể cả chủ schema');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_national_submission_log$$, '55000', 'trigger chặn DELETE nhật ký nộp kể cả chủ schema');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_national_submission_log SET detail = 'sửa'$$, '55000', 'trigger chặn UPDATE nhật ký nộp kể cả chủ schema');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_approval SET comment = 'sửa'$$, '55000', 'trigger chặn UPDATE nhật ký duyệt kể cả chủ schema');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_report_signature$$, '55000', 'trigger chặn DELETE chữ ký số kể cả chủ schema');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_report_version WHERE id = pg_temp.id('rv2')$$, '55000', 'trigger chặn xóa báo cáo PUBLISHED kể cả chủ schema');
SELECT pg_temp.expect($$DELETE FROM ph16_kpi.kpi_report_version WHERE id = pg_temp.id('rv1')$$, '55000', 'trigger chặn xóa báo cáo SUPERSEDED kể cả chủ schema');
SELECT pg_temp.expect($$UPDATE ph16_kpi.kpi_report_version SET snapshot = '{}' WHERE id = pg_temp.id('rv2')$$, '55000', 'chủ schema cũng không sửa được báo cáo PUBLISHED');
CALL ph16_kpi.p_seed_common();
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON'), 24, 'p_seed_common chạy lại không nhân bản (24 chỉ tiêu)');
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'T90'), 0, 'phiên PLATFORM không đọc được chỉ tiêu của tenant nào');
INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, scope, created_by, updated_by)
VALUES (gen_random_uuid(), 'COMMON', 'mau-them-moi', 'KET_NOI', 'Chỉ tiêu mẫu thêm mới', 'COUNT', 'HIGHER_BETTER', 'AUTO', 'lượt', 'COMMON', 'pa', 'pa');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON'), 25, 'phiên PLATFORM ghi được chỉ tiêu COMMON');
DELETE FROM ph16_kpi.kpi_indicator WHERE indicator_code = 'mau-them-moi';
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'kpi_observation'), 24, 'kpi_observation có 24 phân vùng tháng');
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname IN ('kpi_ingest_log', 'kpi_indicator_value', 'kpi_value_lineage')), 72, 'ba bảng phân vùng còn lại, mỗi bảng 24 phân vùng');
ALTER TABLE ph16_kpi.kpi_observation DETACH PARTITION ph16_kpi.kpi_observation_202601;
DROP TABLE ph16_kpi.kpi_observation_202601;
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'kpi_observation'), 23, 'dọn quan sát hết hạn lưu giữ bằng DETACH và DROP phân vùng');
CALL ph16_kpi.p_ensure_partitions('ph16_kpi.kpi_observation', date '2026-01-01', 24);
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'kpi_observation'), 24, 'p_ensure_partitions tạo lại phân vùng thiếu');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_observation WHERE period_start >= '2026-10-01 00:00:00+07' AND period_start < '2026-11-01 00:00:00+07'), 2, 'quan sát tháng 10 nằm đúng phân vùng theo giờ Việt Nam');
SELECT pg_temp.eq((SELECT count(*) FROM ph16_kpi.kpi_observation_202610), 2, 'phân vùng 202610 chứa hai quan sát');
RESET ROLE;

-- ---------- 15. Tổng kiểm ----------
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph16_kpi' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND NOT c.relforcerowsecurity;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng chưa FORCE RLS', n; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph16_kpi' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname NOT IN ('outbox_event', 'inbox_event')
     AND (SELECT count(*) FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname IN ('id', 'tenant_id', 'created_at', 'created_by', 'updated_at', 'updated_by', 'version') AND NOT a.attisdropped) <> 7;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng thiếu cột ngữ cảnh', n; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph16_kpi' AND c.relkind IN ('r', 'p') AND NOT c.relispartition
     AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = c.oid AND k.conname = 'ck_' || c.relname || '_tenant') AND c.relname NOT IN ('outbox_event', 'inbox_event');
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng thiếu CHECK tenant_id', n; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph16_kpi' AND c.relkind IN ('r', 'p') AND NOT c.relispartition;
  IF n <> 40 THEN RAISE EXCEPTION 'FAIL: % bảng, mong 40', n; END IF;
  RAISE NOTICE 'PASS tổng kiểm: % bảng, mọi bảng FORCE RLS, có CHECK tenant và đủ cột ngữ cảnh', n;
END $$;
\o
