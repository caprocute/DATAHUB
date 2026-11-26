-- =============================================================================
-- D03-03-PH11 · Kiểm thử DDL ph11_bpm (bản 0.4, đồng bộ FRS Phụ lục A; thêm giữ pháp lý, đề nghị bỏ qua bù trừ, lần chạy mẫu tuân thủ): cô lập tenant (kể cả bảng phân vùng và mẫu dùng chung COMMON),
-- vòng đời phiên bản, bốn mắt, lý do tối thiểu, khóa lũy đẳng khi khởi tạo phiên, máy trạng thái việc, ủy quyền không chồng,
-- lịch làm việc theo năm, hạn xử lý, chạy thử, đề nghị can thiệp phiên, Saga, sự cố, tham số 11.* đúng miền, outbox không chứa giá trị biến,
-- bảng chỉ thêm, quyền vai trò, khởi tạo tenant, schema engine tách riêng.
-- Chạy sau ph11_bpm.sql trên CSDL rỗng, bằng người dùng có quyền tạo vai trò (ví dụ postgres):
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph11_isolation_test.sql
-- Mỗi lệnh pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại,
-- 23P01 exclude, 42501 quyền hoặc RLS, 55000 bất biến) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91
-- (D00-04 §3.1). Tương ứng nhóm ca cô lập (FR-11 mọi API đọc) và quy tắc nghiệp vụ chốt ở CSDL (D03-03-PH11 mục 1.4).
-- Giá trị enum, tên cột theo D02-03-PH11 Phụ lục A (ví dụ status, process_key, APPROVE, REQUESTED).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_app') THEN
    CREATE ROLE dh_platform_app LOGIN NOBYPASSRLS IN ROLE ph11_app;
  ELSE
    GRANT ph11_app TO dh_platform_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph11_readonly;
  ELSE
    GRANT ph11_readonly TO dh_report_ro;
  END IF;
END $$;
SET ROLE dh_platform_app;

CREATE TEMP TABLE passed (n serial, label text);
GRANT ALL ON passed TO PUBLIC;
GRANT ALL ON SEQUENCE passed_n_seq TO PUBLIC;
CREATE FUNCTION pg_temp.expect(p_sql text, p_state text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE ok boolean := false;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF position(SQLSTATE IN p_state) > 0 THEN ok := true;
    ELSE RAISE EXCEPTION 'FAIL %: SQLSTATE % (mong %): %', p_label, SQLSTATE, p_state, SQLERRM; END IF;
  END;
  IF NOT ok THEN RAISE EXCEPTION 'FAIL %: không bị chặn', p_label; END IF;
  INSERT INTO passed (label) VALUES (p_label);
  RAISE NOTICE 'PASS %', p_label;
END $$;
CREATE FUNCTION pg_temp.eq(p_actual bigint, p_expected bigint, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_actual IS DISTINCT FROM p_expected THEN RAISE EXCEPTION 'FAIL %: được %, mong %', p_label, p_actual, p_expected; END IF;
  INSERT INTO passed (label) VALUES (p_label);
  RAISE NOTICE 'PASS %', p_label;
END $$;
CREATE FUNCTION pg_temp.u(n integer) RETURNS uuid LANGUAGE sql AS $$ SELECT ('a1000000-0000-7000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.h(text) RETURNS bytea LANGUAGE sql AS $$ SELECT sha256(convert_to($1, 'UTF8')) $$;
CREATE FUNCTION pg_temp.tr(n integer) RETURNS char(32) LANGUAGE sql AS $$ SELECT lpad(to_hex(n), 32, '0')::char(32) $$;

-- ---------- Khởi tạo hai tenant bằng thủ tục ----------
SET app.tenant_id = 'T90';
CALL ph11_bpm.p_seed_tenant('T90');
SET app.tenant_id = 'T91';
CALL ph11_bpm.p_seed_tenant('T91');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq(count(*), 36, 'seed T90: 36 tham số 11.* theo FRS 8.2') FROM ph11_bpm.tenant_setting WHERE tenant_id = 'T90';
SELECT pg_temp.eq((value #>> '{}')::bigint, 2880, 'seed: 11.service.defaultTimeoutMinutes là 2.880 phút (đơn vị của FRS, không phải giây)') FROM ph11_bpm.tenant_setting WHERE key IN ('11.service.defaultTimeoutMinutes');
SELECT pg_temp.eq((value #>> '{}')::bigint, 8, 'seed: 11.task.dueSoonHours mặc định 8 giờ làm việc') FROM ph11_bpm.tenant_setting WHERE key IN ('11.task.dueSoonHours');
SELECT pg_temp.eq(count(*), 2, 'seed T90: lịch năm hiện tại và năm sau') FROM ph11_bpm.business_calendar WHERE tenant_id = 'T90';
CALL ph11_bpm.p_seed_tenant('T90');
SELECT pg_temp.eq(count(*), 36, 'seed chạy lại không nhân bản tham số') FROM ph11_bpm.tenant_setting WHERE tenant_id = 'T90';
SELECT pg_temp.eq(count(*), 2, 'seed chạy lại không nhân bản lịch') FROM ph11_bpm.business_calendar WHERE tenant_id = 'T90';
SET app.tenant_id = 'T90';

-- ---------- Dữ liệu T90: quy trình LT_KHAI_SINH đến khi phát hành ----------
INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, group_code, allowed_starters, allow_manual_start, default_due_value, default_due_unit, latest_version, created_by, updated_by)
VALUES (pg_temp.u(1), 'T90', 'LT_KHAI_SINH', 'Liên thông đăng ký khai sinh, thường trú, thẻ BHYT trẻ dưới 6 tuổi', 'TTHC_LIEN_THONG', '{sys:ph01,HT-HOTICH}', true, 5, 'WORKING_DAY', 1, 'an', 'an'),
       (pg_temp.u(2), 'T90', 'DUYET_KET_NAP_HTTT', 'Duyệt kết nạp HTTT hai cấp', 'DUYET_NOI_BO', '{}', false, NULL, NULL, 0, 'an', 'an');
INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, status, bpmn_xml, checksum, created_by, updated_by)
VALUES (pg_temp.u(11), 'T90', pg_temp.u(1), 'LT_KHAI_SINH', 1, 'DRAFT', '<definitions/>', pg_temp.h('<definitions/>'), 'an', 'an');
INSERT INTO ph11_bpm.service_intent (id, tenant_id, intent_code, name, status, writes_external, bindings, created_by, updated_by)
VALUES (pg_temp.u(21), 'T90', 'guiTuPhap', 'Gửi hồ sơ khai sinh sang Tư pháp', 'ACTIVE', true, '[{"environment":"PROD","flowCode":"FLOW_TU_PHAP","flowVersion":3}]', 'an', 'an'),
       (pg_temp.u(22), 'T90', 'huyTuPhap', 'Hủy hồ sơ đã gửi Tư pháp', 'ACTIVE', true, '[{"environment":"PROD","flowCode":"FLOW_TU_PHAP_HUY","flowVersion":1}]', 'an', 'an');
INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, policy, compensation_intent_code, business_note, verify_intent_code, waiver_approved_by, created_by, updated_by)
VALUES (pg_temp.u(31), 'T90', pg_temp.u(11), 'svcGuiTuPhap', 'AUTO', 'huyTuPhap', 'Hủy hồ sơ đã gửi Tư pháp bằng ý định huyTuPhap trước khi hoàn tất', NULL, NULL, 'an', 'an'),
       (pg_temp.u(32), 'T90', pg_temp.u(11), 'svcCapSoHoTich', 'NONE_APPROVED', NULL, 'Số hộ tịch đã cấp không thu hồi được, chỉ đánh dấu hồ sơ hủy ở bước sau', NULL, 'binh', 'an', 'an');
INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, type, required_at_start, data_class, encrypt, mask, editable_by, created_by, updated_by)
VALUES (pg_temp.u(41), 'T90', pg_temp.u(11), 'maHoSo', 'STRING', true, 'INTERNAL', false, false, 'NONE', 'an', 'an'),
       (pg_temp.u(42), 'T90', pg_temp.u(11), 'hoTenTre', 'STRING', true, 'RESTRICTED', false, true, 'TASK', 'an', 'an'),
       (pg_temp.u(43), 'T90', pg_temp.u(11), 'soDinhDanhCha', 'STRING', false, 'SENSITIVE', true, true, 'ADMIN_CHANGE', 'an', 'an');
INSERT INTO ph11_bpm.form_definition (id, tenant_id, form_key, version_no, name, status, schema, decisions, field_classification, checksum, created_by, updated_by)
VALUES (pg_temp.u(51), 'T90', 'tiep-nhan-khai-sinh', 1, 'Biểu mẫu tiếp nhận khai sinh', 'PUBLISHED', '{"type":"object"}', '{COMPLETE,REQUEST_SUPPLEMENT}', '{"soDinhDanhCha":"SENSITIVE"}', pg_temp.h('{"type":"object"}'), 'an', 'an');
UPDATE ph11_bpm.process_version SET validation_summary = '{"blocking": false, "errorCount": 0, "warningCount": 1, "checkedAt": "2026-11-26T08:00:00Z"}', lock_owner = 'an', lock_until = now() + interval '30 minutes' WHERE id = pg_temp.u(11);
UPDATE ph11_bpm.process_version SET lock_owner = NULL, lock_until = NULL WHERE id = pg_temp.u(11);
UPDATE ph11_bpm.process_version SET status = 'IN_REVIEW' WHERE id = pg_temp.u(11);
INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, status, requested_by, created_by, updated_by)
VALUES (pg_temp.u(61), 'T90', pg_temp.u(11), 'PUBLISH', 'Phát hành bản đầu tiên cho liên thông khai sinh', pg_temp.h('<definitions/>'), 'PENDING', 'an', 'an', 'an');
UPDATE ph11_bpm.publish_request SET status = 'APPROVED', decided_by = 'binh', decided_at = now(), comment = 'Đã đối chiếu bước bù trừ, đồng ý phát hành' WHERE id = pg_temp.u(61);
UPDATE ph11_bpm.process_version SET status = 'PUBLISHED', deployment_id = 'dep-0001', process_definition_id = 'ltKhaiSinh:1:101', published_at = now() WHERE id = pg_temp.u(11);
INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, idempotency_key, status, wait_state, start_channel, initiator, client_id, trace_id, created_by, updated_by)
VALUES (pg_temp.u(71), 'T90', 'pi-0001', 'LT_KHAI_SINH', 1, 'HS-2026-000001', 'idem-0001', 'RUNNING', 'WAITING_USER', 'API', 'sys:ph01', 'client-hotich', pg_temp.tr(1), 'sys:ph01', 'sys:ph01'),
       (pg_temp.u(72), 'T90', 'pi-0002', 'LT_KHAI_SINH', 1, 'HS-2026-000002', 'idem-0002', 'RUNNING', 'WAITING_SERVICE', 'API', 'sys:ph01', 'client-hotich', pg_temp.tr(2), 'sys:ph01', 'sys:ph01');
INSERT INTO ph11_bpm.instance_step (id, tenant_id, instance_id, element_id, element_name, step_type, trace_id)
VALUES (pg_temp.u(81), 'T90', pg_temp.u(71), 'tiepNhan', 'Tiếp nhận hồ sơ', 'USER_TASK', pg_temp.tr(1));
INSERT INTO ph11_bpm.task_index (id, tenant_id, engine_task_id, instance_id, element_id, task_kind, name, form_key, form_version, status, candidates, due_at, trace_id, created_by, updated_by)
VALUES (pg_temp.u(91), 'T90', 'tk-0001', pg_temp.u(71), 'tiepNhan', 'STANDARD', 'Tiếp nhận hồ sơ khai sinh', 'tiep-nhan-khai-sinh', 1, 'UNASSIGNED', '{group:tu-phap-tiep-nhan,an}', now() + interval '2 days', pg_temp.tr(1), 'system', 'system');
INSERT INTO ph11_bpm.task_comment (id, tenant_id, task_id, instance_id, author, kind, text, mentions, created_by)
VALUES (pg_temp.u(101), 'T90', pg_temp.u(91), pg_temp.u(71), 'an', 'COMMENT', 'Đã nhận hồ sơ, chờ bổ sung giấy chứng sinh', '{binh}', 'an');
INSERT INTO ph11_bpm.task_attachment (id, tenant_id, task_id, instance_id, file_name, content_type, size, checksum, object_ref, data_class, created_by, updated_by)
VALUES (pg_temp.u(111), 'T90', pg_temp.u(91), pg_temp.u(71), 'giay-chung-sinh.pdf', 'application/pdf', 120000, pg_temp.h('f'), 'bpm/T90/pi-0001/att-1', 'RESTRICTED', 'an', 'an');
INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, scope, valid_from, valid_to, reason, created_by, updated_by)
VALUES (pg_temp.u(121), 'T90', 'an', 'binh', '{"all": true}', now(), now() + interval '10 days', 'Nghỉ phép', 'an', 'an');
INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by) VALUES (pg_temp.u(251), 'T90', 2030, 'an', 'an');
INSERT INTO ph11_bpm.calendar_day (id, tenant_id, calendar_id, date, type, name, legal_ref, created_by, updated_by)
VALUES (pg_temp.u(131), 'T90', pg_temp.u(251), DATE '2030-02-04', 'HOLIDAY', 'Tết Nguyên đán', 'Quyết định của Thủ tướng', 'an', 'an');
INSERT INTO ph11_bpm.due_tracking (id, tenant_id, subject, subject_id, instance_id, due_value, due_unit, start_at, due_at, due_soon_at, created_by, updated_by)
VALUES (pg_temp.u(141), 'T90', 'INSTANCE', pg_temp.u(71), pg_temp.u(71), 15, 'WORKING_DAY', now(), now() + interval '21 days', now() + interval '19 days', 'system', 'system'),
       (pg_temp.u(142), 'T90', 'TASK', pg_temp.u(91), pg_temp.u(71), 2, 'WORKING_DAY', now(), now() + interval '2 days', now() + interval '1 day', 'system', 'system');
INSERT INTO ph11_bpm.service_call (id, tenant_id, command_id, instance_id, element_id, intent_code, timeout_at, trace_id, created_by, updated_by)
VALUES (pg_temp.u(151), 'T90', pg_temp.u(152), pg_temp.u(71), 'svcGuiTuPhap', 'guiTuPhap', now() + interval '2880 minutes', pg_temp.tr(1), 'system', 'system');
INSERT INTO ph11_bpm.saga_log (id, tenant_id, instance_id, trigger, failed_element, error_code, total_steps, trace_id, created_by, updated_by)
VALUES (pg_temp.u(161), 'T90', pg_temp.u(71), 'STEP_FAILURE', 'svcCapSoHoTich', 'ERR-11-101', 2, pg_temp.tr(1), 'system', 'system');
INSERT INTO ph11_bpm.saga_step (id, tenant_id, saga_id, seq, forward_element_id, compensation_intent_code, policy, created_by, updated_by)
VALUES (pg_temp.u(171), 'T90', pg_temp.u(161), 1, 'svcGuiTuPhap', 'huyTuPhap', 'AUTO', 'system', 'system');
INSERT INTO ph11_bpm.incident (id, tenant_id, type, instance_id, element_id, job_id, error_code, trace_id, created_by, updated_by)
VALUES (pg_temp.u(181), 'T90', 'JOB_FAILED', pg_temp.u(71), 'svcCapSoHoTich', 'job-0001', 'ERR-11-105', pg_temp.tr(1), 'system', 'system');
INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, based_on, bpmn_xml, checksum, created_by, updated_by)
VALUES (pg_temp.u(12), 'T90', pg_temp.u(1), 'LT_KHAI_SINH', 2, 1, '<definitions/>', pg_temp.h('<definitions/>'), 'an', 'an');
INSERT INTO ph11_bpm.migration_plan (id, tenant_id, process_key, from_version, to_version, mappings, reason, requested_by, created_by, updated_by)
VALUES (pg_temp.u(191), 'T90', 'LT_KHAI_SINH', 1, 2, '[{"fromElementId":"tiepNhan","toElementId":"tiepNhan"}]', 'Bổ sung bước kiểm tra thẻ BHYT sau khi cấp số định danh', 'an', 'an', 'an');
INSERT INTO ph11_bpm.decision_table (id, tenant_id, code, name, inputs, outputs, rules, checksum, created_by, updated_by)
VALUES (pg_temp.u(201), 'T90', 'duoi6Tuoi', 'Trẻ dưới 6 tuổi', '["tuoiThang"]', '["nhanhBHYT"]', '[{"if":["< 72"],"then":["TRE_EM"]}]', pg_temp.h('duoi6Tuoi'), 'an', 'an');
INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
VALUES (pg_temp.u(211), 'T90', 'InstanceStarted', 't90.bpm.instance.started.v1', 'instance', 'HS-2026-000001', 'HS-2026-000001', '{"instanceId":"x","status":"RUNNING"}', pg_temp.tr(1));
INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type, correlation_key, status)
VALUES ('T90', 'ServiceResultConsumer', 'msg-0001', 't90.bpm.service.completed.v1', 'ServiceCompleted', 'cmd-0001', 'RECEIVED');
INSERT INTO ph11_bpm.test_run (id, tenant_id, version_id, scenario, created_by, updated_by)
VALUES (pg_temp.u(231), 'T90', pg_temp.u(12), '{"svcGuiTuPhap":{"mode":"COMPLETE"},"clock":"ACCELERATED"}', 'an', 'an');
INSERT INTO ph11_bpm.instance_change (id, tenant_id, instance_id, type, payload, reason, requested_by, created_by, updated_by)
VALUES (pg_temp.u(241), 'T90', pg_temp.u(72), 'VARIABLE_UPDATE', '{"changes":[{"name":"maHoSo"}]}', 'Sửa mã hồ sơ nhập nhầm theo đề nghị của công dân', 'an', 'an', 'an');
INSERT INTO ph11_bpm.saga_skip_request (id, tenant_id, saga_id, step_id, reason, evidence, requested_by, task_id, created_by, updated_by)
VALUES (pg_temp.u(261), 'T90', pg_temp.u(161), pg_temp.u(171), 'Hệ thống tư pháp đã hủy giao dịch ngoài hệ thống, không cần bù trừ', '[{"note":"Biên bản số 12","docNumber":"12/BB-STP"}]', 'an', pg_temp.u(91), 'an', 'an');
INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, hold_until, created_by, updated_by)
VALUES (pg_temp.u(271), 'T90', 'HS-2026-000001', 'Yêu cầu của cơ quan điều tra, công văn số 45/CV-CSĐT', now() + interval '1 year', 'an', 'an');
INSERT INTO ph11_bpm.compliance_sample_run (id, tenant_id, evidence_pack_id, environment, requested_by, include_models, created_by, updated_by)
VALUES (pg_temp.u(281), 'T90', pg_temp.u(282), 'TEST', 'an', '["LT_KHAI_SINH"]', 'an', 'an');
DO $$
DECLARE v integer;
BEGIN
  UPDATE ph11_bpm.process_model SET description = 'Quy trình ví dụ xuyên suốt' WHERE id = pg_temp.u(1) RETURNING version INTO v;
  PERFORM pg_temp.eq(v, 1, 'tg_touch tăng version khi sửa');
END $$;

-- ---------- 1. Cô lập tenant: T91 không đọc, sửa, xóa, chèn dòng T90 ----------
SET app.tenant_id = 'T91';
DO $$
DECLARE r record; n bigint; k integer := 0;
BEGIN
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace ns ON ns.oid = c.relnamespace
           WHERE ns.nspname = 'ph11_bpm' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname <> 'shedlock' ORDER BY 1 LOOP
    EXECUTE format('SELECT count(*) FROM ph11_bpm.%I WHERE tenant_id = %L', r.relname, 'T90') INTO n;
    IF n <> 0 THEN RAISE EXCEPTION 'FAIL cô lập đọc: T91 thấy % dòng T90 ở %', n, r.relname; END IF;
    k := k + 1;
  END LOOP;
  PERFORM pg_temp.eq(k, 31, 'T91 không đọc dòng T90 trên 31 bảng có tenant_id (kể cả instance_step phân vùng)');
END $$;
DO $$
DECLARE n bigint; t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['process_model', 'process_version', 'instance_index', 'task_index', 'saga_log', 'incident', 'due_tracking', 'tenant_setting', 'service_call', 'migration_plan', 'instance_change', 'test_run', 'saga_skip_request', 'legal_hold', 'compliance_sample_run'] LOOP
    EXECUTE format('UPDATE ph11_bpm.%I SET created_by = created_by WHERE tenant_id = %L', t, 'T90');
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 0 THEN RAISE EXCEPTION 'FAIL cô lập sửa: T91 sửa % dòng T90 ở %', n, t; END IF;
  END LOOP;
  FOREACH t IN ARRAY ARRAY['instance_index', 'task_index', 'due_tracking', 'incident', 'service_call', 'task_attachment', 'outbox_event', 'inbox_message', 'test_run'] LOOP
    EXECUTE format('DELETE FROM ph11_bpm.%I WHERE tenant_id = %L', t, 'T90');
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 0 THEN RAISE EXCEPTION 'FAIL cô lập xóa: T91 xóa % dòng T90 ở %', n, t; END IF;
  END LOOP;
  PERFORM pg_temp.eq(0, 0, 'T91 không sửa 15 bảng, không xóa 9 bảng của T90');
END $$;
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'XAM_NHAP', 'Xâm nhập', 'x', 'x')$q$, '42501', 'T91 không chèn dòng mang tenant T90');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type) VALUES ('T90', 'ServiceResultConsumer', 'msg-x', 't90.bpm.service.completed.v1', 'X')$q$, '42501', 'T91 không chèn inbox cho T90');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_step (id, tenant_id, instance_id, element_id, step_type, trace_id) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000071', 'x', 'USER_TASK', '00000000000000000000000000000001')$q$, '42501', 'T91 không chèn vào bảng phân vùng cho T90');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.test_run (id, tenant_id, version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000011', 'x', 'x')$q$, '42501', 'T91 không chèn lần chạy thử cho T90');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HS-XAM-NHAP', 'Giữ không có thẩm quyền của tenant khác', 'x', 'x')$q$, '42501', 'T91 không chèn giữ pháp lý cho T90');
SELECT pg_temp.eq(count(*), 2, 'T91 chỉ thấy lịch năm của mình (mẫu S: chưa có lịch COMMON)') FROM ph11_bpm.business_calendar;
SELECT pg_temp.eq(count(*), 36, 'T91 chỉ thấy 36 tham số của mình (mẫu S: chưa có trần COMMON)') FROM ph11_bpm.tenant_setting;
SELECT pg_temp.eq(count(*), 1, 'T91 thấy mẫu COMMON (mẫu S: đọc chung)') FROM ph11_bpm.process_template WHERE tenant_id = 'COMMON';
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_template (id, tenant_id, template_code, name, source_xml, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'MAU_LAU', 'Mẫu lậu', '<d/>', sha256('x'), 'x', 'x')$q$, '42501', 'tenant thường không ghi được mẫu COMMON');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 2031, 'x', 'x')$q$, '42501', 'tenant thường không ghi được lịch nền COMMON');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.tenant_setting (id, tenant_id, key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '11.task.bulkMax', '2000', 'x', 'x')$q$, '42501', 'tenant thường không đặt trần COMMON');
DO $$
DECLARE n bigint;
BEGIN
  UPDATE ph11_bpm.process_template SET name = 'đã sửa' WHERE tenant_id = 'COMMON';
  GET DIAGNOSTICS n = ROW_COUNT;
  PERFORM pg_temp.eq(n, 0, 'tenant thường không sửa được dòng COMMON (0 dòng)');
END $$;
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'MAU_LAU', 'Mẫu lậu', 'x', 'x')$q$, '42501', 'bảng kiểu P không nhận dòng COMMON từ tenant thường');
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq(count(*), 0, 'phiên PLATFORM không đọc dòng T90 ở bảng kiểu P') FROM ph11_bpm.process_model WHERE tenant_id = 'T90';
INSERT INTO ph11_bpm.process_template (id, tenant_id, template_code, version_no, name, group_code, status, source_xml, placeholders, checksum, created_by, updated_by)
VALUES (pg_temp.u(221), 'COMMON', 'DUYET_HAI_CAP', 1, 'Duyệt hai cấp', 'DUYET_NOI_BO', 'PUBLISHED', '<definitions/>', '["nhomDuyetCap1", "nhomDuyetCap2"]', pg_temp.h('<definitions/>'), 'pa', 'pa');
SELECT pg_temp.eq(count(*), 2, 'phiên PLATFORM ghi được mẫu COMMON (có 2 mẫu)') FROM ph11_bpm.process_template WHERE tenant_id = 'COMMON';
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_template SET source_xml = '<khac/>', checksum = sha256('khac') WHERE template_code = 'DUYET_HAI_CAP'$q$, '55000', 'mẫu PUBLISHED không đổi nội dung');
INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by) VALUES (pg_temp.u(252), 'COMMON', 2030, 'pa', 'pa');
INSERT INTO ph11_bpm.calendar_day (id, tenant_id, calendar_id, date, type, name, legal_ref, created_by, updated_by)
VALUES (pg_temp.u(132), 'COMMON', pg_temp.u(252), DATE '2030-09-02', 'HOLIDAY', 'Quốc khánh', 'Luật Lao động', 'pa', 'pa');
INSERT INTO ph11_bpm.tenant_setting (id, tenant_id, key, value, created_by, updated_by) VALUES (pg_temp.u(253), 'COMMON', '11.task.bulkMax', '1000', 'pa', 'pa');
SELECT pg_temp.eq(count(*), 3, 'phiên PLATFORM ghi được lịch, ngày lễ, trần tham số ở COMMON') FROM (SELECT 1 FROM ph11_bpm.business_calendar WHERE tenant_id = 'COMMON' UNION ALL SELECT 1 FROM ph11_bpm.calendar_day WHERE tenant_id = 'COMMON' UNION ALL SELECT 1 FROM ph11_bpm.tenant_setting WHERE tenant_id = 'COMMON') t;
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T9', 'LOI_TENANT', 'Lỗi', 'x', 'x')$q$, '23514|42501', 'tenant_id sai dạng bị chặn');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq(count(*), 1, 'T91 đọc được trần tham số COMMON (mẫu S)') FROM ph11_bpm.tenant_setting WHERE tenant_id = 'COMMON';
SELECT pg_temp.eq(count(*), 1, 'T91 đọc được ngày lễ nền COMMON (mẫu S)') FROM ph11_bpm.calendar_day WHERE tenant_id = 'COMMON';
SET app.tenant_id = 'T90';
SELECT pg_temp.eq(count(*), 4, 'T90 đọc được lịch COMMON cùng lịch riêng (2 seed, 1 năm 2030, 1 COMMON)') FROM ph11_bpm.business_calendar;

-- ---------- 2. Mô hình, phiên bản, bốn mắt ----------
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET bpmn_xml = '<sua/>', checksum = sha256('sua') WHERE id = 'a1000000-0000-7000-8000-000000000011'$q$, '55000', 'nội dung phiên bản PUBLISHED bất biến (BR-11-005)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET version_no = 9 WHERE id = 'a1000000-0000-7000-8000-000000000011'$q$, '55000', 'số phiên bản bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET status = 'PUBLISHED', deployment_id = 'dep-0002', process_definition_id = 'ltKhaiSinh:2:102', published_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23514', 'phiên bản chưa kiểm tra tĩnh không được PUBLISHED');
UPDATE ph11_bpm.process_version SET validation_summary = '{"blocking": true, "errorCount": 2, "warningCount": 0, "checkedAt": "2026-11-26T09:00:00Z"}' WHERE id = pg_temp.u(12);
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET status = 'IN_REVIEW' WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23514', 'còn lỗi chặn (blocking = true) thì không gửi duyệt');
UPDATE ph11_bpm.process_version SET validation_summary = '{"blocking": false, "errorCount": 0, "warningCount": 0, "checkedAt": "2026-11-26T09:30:00Z"}' WHERE id = pg_temp.u(12);
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET validation_summary = '{"errorCount": 0}' WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23514', 'tóm tắt kiểm tra tĩnh phải có cờ blocking');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET status = 'PUBLISHED', deployment_id = 'dep-0002', process_definition_id = 'ltKhaiSinh:2:102', published_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23505', 'mỗi mô hình đúng một phiên bản PUBLISHED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET status = 'PUBLISHED' WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23514|23505', 'PUBLISHED thiếu deployment_id, process_definition_id bị chặn');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET status = 'RETIRED', retired_at = now(), retire_reason = 'hết dùng' WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23514', 'RETIRED cần lý do từ 10 ký tự (FR-11-009)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET lock_owner = 'an' WHERE id = 'a1000000-0000-7000-8000-000000000012'$q$, '23514', 'khóa soạn thảo phải có cả người giữ và hạn');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_version SET lock_owner = 'an', lock_until = now() + interval '30 minutes' WHERE id = 'a1000000-0000-7000-8000-000000000011'$q$, '23514', 'chỉ bản DRAFT mới có khóa soạn thảo');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, bpmn_xml, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'KHONG_CO', 1, '<d/>', sha256('x'), 'x', 'x')$q$, '23503', 'phiên bản phải thuộc mô hình có thật (khóa ngoại kèm tenant)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, bpmn_xml, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000001', 'DUYET_KET_NAP_HTTT', 1, '<d/>', sha256('x'), 'x', 'x')$q$, '23503', 'process_key của phiên bản phải khớp mô hình cha');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, bpmn_xml, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000001', 'LT_KHAI_SINH', 3, '<d/>', '\x01', 'x', 'x')$q$, '23514', 'checksum BPMN phải đúng 32 byte');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, bpmn_xml, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000001', 'LT_KHAI_SINH', 1, '<d/>', sha256('x'), 'x', 'x')$q$, '23505', 'trùng số phiên bản trong mô hình');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_version (id, tenant_id, model_id, process_key, version_no, based_on, bpmn_xml, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000001', 'LT_KHAI_SINH', 3, 3, '<d/>', sha256('x'), 'x', 'x')$q$, '23514', 'phiên bản làm gốc (based_on) phải nhỏ hơn số phiên bản');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'sai ma', 'Sai mã', 'x', 'x')$q$, '23514', 'khóa mô hình theo mẫu chữ hoa, gạch dưới');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, default_due_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HAN_LE', 'Hạn lẻ', 5, 'x', 'x')$q$, '23514', 'hạn mặc định phải có cả giá trị và đơn vị (T-DUE)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.process_model (id, tenant_id, process_key, name, default_due_value, default_due_unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HAN_SAI', 'Hạn sai', 5, 'WORKING_WEEK', 'x', 'x')$q$, '23514', 'đơn vị hạn mặc định thuộc DueUnit');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_model SET process_key = 'DOI_MA' WHERE id = 'a1000000-0000-7000-8000-000000000001'$q$, '55000', 'khóa mô hình bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_model SET archived = true WHERE id = 'a1000000-0000-7000-8000-000000000002'$q$, '23514', 'lưu trữ mô hình cần lý do');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.process_model WHERE id = 'a1000000-0000-7000-8000-000000000002'$q$, '42501', 'ứng dụng không xóa mô hình');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.publish_request SET decided_by = 'an' WHERE id = 'a1000000-0000-7000-8000-000000000061'$q$, '23514', 'bốn mắt: người duyệt phải khác người gửi (BR-11-004)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, status, requested_by, decided_by, decided_at, comment, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'PUBLISH', 'Phát hành bản hai kèm bước BHYT', sha256('x'), 'REJECTED', 'an', 'binh', now(), 'thiếu bước', 'x', 'x')$q$, '23514', 'từ chối phát hành cần lý do từ 20 ký tự (BR-11-033)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, status, requested_by, comment, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'PUBLISH', 'Phát hành bản hai kèm bước BHYT', sha256('x'), 'DEPLOY_FAILED', 'an', 'triển khai lỗi', 'x', 'x')$q$, '23514', 'DEPLOY_FAILED phải có người duyệt và thời điểm duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'PUBLISH', 'ngắn', sha256('x'), 'an', 'x', 'x')$q$, '23514', 'ghi chú thay đổi từ 10 ký tự (ERR-11-007)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'DEPRECATE', 'Ngừng dùng bản cũ của quy trình', sha256('x'), 'an', 'x', 'x')$q$, '23514', 'loại yêu cầu duyệt thuộc PUBLISH, RESTORE, TEMPLATE');
INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, status, requested_by, created_by, updated_by)
VALUES (pg_temp.u(62), 'T90', pg_temp.u(12), 'PUBLISH', 'Phát hành bản hai kèm bước BHYT', pg_temp.h('<definitions/>'), 'PENDING', 'an', 'an', 'an');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.publish_request (id, tenant_id, version_id, kind, release_note, checksum, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'PUBLISH', 'Phát hành bản hai kèm bước BHYT', sha256('x'), 'PENDING', 'chi', 'x', 'x')$q$, '23505', 'mỗi phiên bản một yêu cầu PENDING cùng loại');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.publish_request SET requested_by = 'chi' WHERE id = 'a1000000-0000-7000-8000-000000000062'$q$, '55000', 'người gửi duyệt bất biến');

-- ---------- 3. Biến, bù trừ, biểu mẫu, ý định ----------
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, data_class, encrypt, mask, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'cccdMe', 'SENSITIVE', false, true, 'x', 'x')$q$, '23514', 'biến SENSITIVE bắt buộc mã hóa (ERR-11-015)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, data_class, encrypt, mask, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'cccdMe', 'SENSITIVE', true, false, 'x', 'x')$q$, '23514', 'biến SENSITIVE bắt buộc che khi hiển thị');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, data_class, mask, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'hoTenMe', 'RESTRICTED', false, 'x', 'x')$q$, '23514', 'biến RESTRICTED phải che');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'businessKey', 'x', 'x')$q$, '23514', 'tên biến không trùng biến hệ thống (ERR-11-003)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'Sai-Ten', 'x', 'x')$q$, '23514', 'tên biến theo mẫu camelCase');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'soTien', 'INTEGER', 'x', 'x')$q$, '23514', 'kiểu biến thuộc VariableType (NUMBER, không phải INTEGER)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, editable_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'bienKhac', 'ANYONE', 'x', 'x')$q$, '23514', 'editableBy thuộc NONE, TASK, ADMIN_CHANGE');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.variable_definition (id, tenant_id, version_id, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000011', 'bienMoi', 'x', 'x')$q$, '55000', 'không thêm biến vào phiên bản đã PUBLISHED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.variable_definition SET editable_by = 'TASK' WHERE id = 'a1000000-0000-7000-8000-000000000041'$q$, '55000', 'không sửa biến của phiên bản đã PUBLISHED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.variable_definition SET name = 'doiTen' WHERE id = 'a1000000-0000-7000-8000-000000000041'$q$, '55000', 'tên biến bất biến');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.compensation_action WHERE id = 'a1000000-0000-7000-8000-000000000031'$q$, '42501', 'ứng dụng không xóa hành động bù trừ');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, policy, business_note, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'svcX', 'AUTO', 'Hủy hồ sơ đã gửi, ghi chú đủ dài để qua kiểm tra', 'x', 'x')$q$, '23514', 'bù trừ AUTO phải có ý định bù trừ');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, policy, business_note, waiver_approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'svcY', 'NONE_APPROVED', 'ngắn', 'binh', 'x', 'x')$q$, '23514', 'mọi hành động bù trừ có ghi chú nghiệp vụ từ 20 ký tự (BR-11-009)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, policy, business_note, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'svcY', 'NONE_APPROVED', 'Không bù trừ vì văn bản đã phát hành không thu hồi', 'x', 'x')$q$, '23514', 'miễn bù trừ phải có người duyệt miễn (BR-11-008)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, compensation_intent_code, policy, business_note, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000011', 'svcZ', 'huyTuPhap', 'AUTO', 'Hủy hồ sơ đã gửi, ghi chú đủ dài để qua kiểm tra', 'x', 'x')$q$, '55000', 'không thêm bù trừ vào phiên bản đã PUBLISHED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, compensation_intent_code, policy, business_note, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'svcW', 'khongCoYDinh', 'AUTO', 'Hủy hồ sơ đã gửi, ghi chú đủ dài để qua kiểm tra', 'x', 'x')$q$, '23503', 'ý định bù trừ phải tồn tại cùng tenant');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compensation_action (id, tenant_id, version_id, element_id, compensation_intent_code, verify_intent_code, policy, business_note, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'svcV', 'huyTuPhap', 'khongCoKiemTra', 'AUTO', 'Hủy hồ sơ đã gửi, ghi chú đủ dài để qua kiểm tra', 'x', 'x')$q$, '23503', 'ý định kiểm tra bù trừ phải tồn tại cùng tenant');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.form_definition SET schema = '{"type":"object","title":"sửa"}' WHERE id = 'a1000000-0000-7000-8000-000000000051'$q$, '55000', 'biểu mẫu PUBLISHED không đổi nội dung');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.form_definition SET decisions = '{APPROVE}' WHERE id = 'a1000000-0000-7000-8000-000000000051'$q$, '55000', 'quyết định cho phép của biểu mẫu PUBLISHED không đổi');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.form_definition (id, tenant_id, form_key, version_no, name, status, schema, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'tiep-nhan-khai-sinh', 2, 'Bản 2', 'PUBLISHED', '{"type":"object"}', sha256('x'), 'x', 'x')$q$, '23505', 'mỗi form_key đúng một phiên bản PUBLISHED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.form_definition (id, tenant_id, form_key, name, status, schema, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bieu-mau-cu', 'Cũ', 'ACTIVE', '{"type":"object"}', sha256('x'), 'x', 'x')$q$, '23514', 'trạng thái biểu mẫu thuộc DRAFT, PUBLISHED, RETIRED (không còn ACTIVE)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.form_definition (id, tenant_id, form_key, name, schema, decisions, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bieu-mau-moi', 'Mới', '{"type":"object"}', '{APPROVED}', sha256('x'), 'x', 'x')$q$, '23514', 'quyết định của biểu mẫu thuộc Decision (APPROVE, không phải APPROVED)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.form_definition (id, tenant_id, form_key, name, schema, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '1sai', 'Sai', '{"type":"object"}', sha256('x'), 'x', 'x')$q$, '23514', 'form_key theo mẫu của API (bắt đầu bằng chữ cái)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_intent (id, tenant_id, intent_code, name, timeout_seconds, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'giaoHang', 'Giao hàng', 0, 'x', 'x')$q$, '23514', 'timeout ý định từ 1 giây');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_intent (id, tenant_id, intent_code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'Sai Ma', 'Sai mã', 'x', 'x')$q$, '23514', 'mã ý định theo mẫu của API (không dấu cách)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_intent (id, tenant_id, intent_code, name, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'yDinhNhap', 'Nháp', 'DRAFT', 'x', 'x')$q$, '23514', 'trạng thái ý định chỉ ACTIVE hoặc DEPRECATED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_intent (id, tenant_id, intent_code, name, bindings, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'yDinhLoi', 'Lỗi ánh xạ', '{"PROD":"F"}', 'x', 'x')$q$, '23514', 'bindings phải là mảng ánh xạ môi trường sang luồng');

-- ---------- 4. Phiên: khóa lũy đẳng, máy trạng thái, bất biến ----------
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, idempotency_key, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 1, 'HS-9', 'idem-0001', 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23505', 'khởi tạo lũy đẳng: idempotency_key trùng bị chặn (BR-11-007)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, idempotency_key, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 1, 'HS-2026-000001', 'idem-9', 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23505', 'một mã hồ sơ chỉ một phiên đang sống mỗi mô hình');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 7, 'HS-9', 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23503', 'phiên phải chạy trên phiên bản mô hình có thật');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, start_channel, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 1, 'HS-9', 'EVENT_START', 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23514', 'kênh khởi tạo thuộc StartChannel');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, start_channel, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 1, 'HS-9', 'CALL_ACTIVITY', 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23514', 'phiên CALL_ACTIVITY phải có phiên cha');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, start_channel, is_test, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 1, 'HS-9', 'TEST', false, 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23514', 'phiên kênh TEST phải đánh dấu is_test');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, wait_state, initiator, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'pi-9', 'LT_KHAI_SINH', 1, 'HS-9', 'WAITING_ALL', 'x', '00000000000000000000000000000009', 'x', 'x')$q$, '23514', 'trạng thái chờ thuộc WaitState');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET status = 'COMPLETED' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '23514', 'phiên kết thúc phải có ended_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET status = 'CANCELLED', ended_at = now(), status_reason = 'sai' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '23514', 'hủy phiên cần lý do từ 10 ký tự');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET status = 'SUSPENDED' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '23514', 'tạm dừng phải có suspended_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET status = 'PAUSED' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '23514', 'trạng thái phiên thuộc InstanceStatus');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET progress_percent = 101 WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '23514', 'tiến độ 0 đến 100');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET business_key = 'DOI-KHOA' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '55000', 'business_key bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET engine_instance_id = 'pi-doi' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '55000', 'mã phiên engine bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET start_channel = 'MANUAL' WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '55000', 'kênh khởi tạo bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_index SET version_no = 1, migrated_from_version = 1 WHERE id = 'a1000000-0000-7000-8000-000000000072'$q$, '23514', 'di trú phải đổi số phiên bản');
DO $$
BEGIN
  UPDATE ph11_bpm.instance_index SET status = 'CANCELLED', ended_at = now(), status_reason = 'Người nộp rút hồ sơ' WHERE id = pg_temp.u(72);
  INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, idempotency_key, initiator, trace_id, created_by, updated_by)
  VALUES (pg_temp.u(73), 'T90', 'pi-0003', 'LT_KHAI_SINH', 1, 'HS-2026-000002', 'idem-0003', 'x', pg_temp.tr(3), 'x', 'x');
  PERFORM pg_temp.eq(count(*), 1, 'sau khi hủy, mã hồ sơ cũ được khởi tạo lại') FROM ph11_bpm.instance_index WHERE id = pg_temp.u(73);
  INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, start_channel, is_test, initiator, trace_id, created_by, updated_by)
  VALUES (pg_temp.u(74), 'T90', 'pi-test-1', 'LT_KHAI_SINH', 1, 'HS-2026-000001', 'TEST', true, 'an', pg_temp.tr(4), 'an', 'an');
  PERFORM pg_temp.eq(count(*), 1, 'phiên chạy thử cùng business_key với phiên thật vẫn được tạo (không vào khóa phiên sống)') FROM ph11_bpm.instance_index WHERE id = pg_temp.u(74);
  INSERT INTO ph11_bpm.instance_index (id, tenant_id, engine_instance_id, process_key, version_no, business_key, start_channel, parent_instance_id, initiator, trace_id, created_by, updated_by)
  VALUES (pg_temp.u(75), 'T90', 'pi-0004', 'LT_KHAI_SINH', 1, 'HS-2026-000001-CON', 'CALL_ACTIVITY', pg_temp.u(71), 'system', pg_temp.tr(5), 'system', 'system');
  PERFORM pg_temp.eq(count(*), 1, 'phiên con của call activity trỏ về phiên cha') FROM ph11_bpm.instance_index WHERE parent_instance_id = pg_temp.u(71);
END $$;
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_step (id, tenant_id, started_at, instance_id, element_id, step_type, trace_id) VALUES (gen_random_uuid(), 'T90', DATE '2019-01-01', 'a1000000-0000-7000-8000-000000000071', 'x', 'USER_TASK', '00000000000000000000000000000001')$q$, '23514', 'ngoài các phân vùng đã tạo bị từ chối (cần PartitionMaintenanceJob)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_step (id, tenant_id, instance_id, element_id, step_type, trace_id) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000071', 'x', 'OTHER', '00000000000000000000000000000001')$q$, '23514', 'loại bước thuộc StepType (bảng 6.2-a)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_step SET status = 'COMPLETED' WHERE id = 'a1000000-0000-7000-8000-000000000081'$q$, '23514', 'bước hoàn thành phải có ended_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_step SET element_id = 'doiBuoc' WHERE id = 'a1000000-0000-7000-8000-000000000081'$q$, '55000', 'bước của phiên không đổi element_id');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_step (id, tenant_id, instance_id, element_id, step_type, trace_id) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000999', 'x', 'USER_TASK', '00000000000000000000000000000001')$q$, '23503', 'bước phải thuộc phiên có thật');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.instance_step WHERE tenant_id = 'T90'$q$, '42501', 'ứng dụng không xóa lịch sử bước (chỉ DETACH phân vùng)');
UPDATE ph11_bpm.instance_step SET status = 'COMPLETED', ended_at = now(), duration_ms = 1200, actor = 'an', result_code = 'COMPLETE' WHERE id = pg_temp.u(81);
SELECT pg_temp.eq(count(*), 1, 'bước hoàn thành ghi nhận được') FROM ph11_bpm.instance_step WHERE status = 'COMPLETED';

-- ---------- 5. Việc ----------
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET status = 'ASSIGNED' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'việc ASSIGNED phải có người nhận');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET status = 'DELEGATED', assignee = 'binh', delegated_from = 'binh' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'việc giao lại phải khác người gốc (delegated_from)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET status = 'DELEGATED', assignee = 'binh' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'việc DELEGATED phải có delegated_from');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET status = 'COMPLETED', assignee = 'an', closed_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'việc hoàn thành phải có quyết định và người hoàn thành');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET status = 'COMPLETED', assignee = 'an', closed_at = now(), decision = 'RETURN', completed_by = 'an', decision_comment = 'thiếu giấy' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'trả về cần ý kiến từ 20 ký tự (BR-11-033)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET status = 'COMPLETED', assignee = 'an', closed_at = now(), decision = 'APPROVED', completed_by = 'an' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'quyết định thuộc Decision (APPROVE, không phải APPROVED)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET candidates = '{}' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'việc chưa giao phải có ứng viên');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET engine_task_id = 'doi' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '55000', 'mã việc engine bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET task_kind = 'APPROVAL' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '55000', 'loại việc bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_index SET result_enc = '\x01' WHERE id = 'a1000000-0000-7000-8000-000000000091'$q$, '23514', 'kết quả mã hóa cần khóa và độ dài hợp lệ');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.task_index (id, tenant_id, engine_task_id, instance_id, element_id, task_kind, name, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'tk-8', 'a1000000-0000-7000-8000-000000000071', 'x', 'USER', 'Việc', '00000000000000000000000000000009', 'x', 'x')$q$, '23514', 'loại việc thuộc TaskKind (không còn USER, COMPENSATION)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.task_index (id, tenant_id, engine_task_id, instance_id, element_id, name, form_key, status, candidates, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'tk-9', 'a1000000-0000-7000-8000-000000000071', 'x', 'Việc', 'tiep-nhan-khai-sinh', 'UNASSIGNED', '{group:g}', '00000000000000000000000000000009', 'x', 'x')$q$, '23514', 'biểu mẫu gắn việc phải kèm số phiên bản (form_version)');
UPDATE ph11_bpm.task_index SET status = 'ASSIGNED', assignee = 'an', claimed_at = now() WHERE id = pg_temp.u(91);
UPDATE ph11_bpm.task_index SET status = 'DELEGATED', assignee = 'binh', delegated_from = 'an', ai_assisted = true WHERE id = pg_temp.u(91);
UPDATE ph11_bpm.task_index SET status = 'COMPLETED', closed_at = now(), decision = 'APPROVE', completed_by = 'binh' WHERE id = pg_temp.u(91);
SELECT pg_temp.eq(count(*), 1, 'vòng đời việc UNASSIGNED, ASSIGNED, DELEGATED, COMPLETED') FROM ph11_bpm.task_index WHERE status = 'COMPLETED';
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_comment SET text = 'sửa ý kiến' WHERE id = 'a1000000-0000-7000-8000-000000000101'$q$, '42501|55000', 'ý kiến trên việc không sửa được');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.task_comment WHERE id = 'a1000000-0000-7000-8000-000000000101'$q$, '42501|55000', 'ý kiến trên việc không xóa được');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.task_comment (id, tenant_id, task_id, instance_id, author, text, created_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000091', 'a1000000-0000-7000-8000-000000000071', 'an', '   ', 'an')$q$, '23514', 'ý kiến không được trống');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.task_attachment (id, tenant_id, task_id, instance_id, file_name, content_type, size, checksum, object_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000091', 'a1000000-0000-7000-8000-000000000071', 'lon.bin', 'application/octet-stream', 60000000, sha256('x'), 'bpm/T90/x', 'x', 'x')$q$, '23514', 'tệp đính kèm tối đa 50 MiB (trần 11.task.attachmentMaxMb)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.task_attachment (id, tenant_id, task_id, instance_id, file_name, content_type, size, checksum, object_ref, data_class, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000091', 'a1000000-0000-7000-8000-000000000071', 'a.pdf', 'application/pdf', 10, sha256('x'), 'bpm/T90/y', 'SECRET', 'x', 'x')$q$, '23514', 'phân loại tệp đính kèm thuộc DataClass');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_attachment SET removed_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000111'$q$, '23514', 'gỡ tệp phải ghi người gỡ');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.task_attachment SET object_ref = 'bpm/T90/doi' WHERE id = 'a1000000-0000-7000-8000-000000000111'$q$, '55000', 'khóa đối tượng của tệp bất biến');

-- ---------- 6. Ủy quyền, lịch, hạn ----------
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'an', 'chi', now() + interval '5 days', now() + interval '20 days', 'x', 'x')$q$, '23P01', 'hai ủy quyền SCHEDULED hoặc ACTIVE cùng phạm vi không chồng thời gian');
INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, scope, valid_from, valid_to, created_by, updated_by)
VALUES (pg_temp.u(122), 'T90', 'an', 'chi', '{"processKeys": ["LT_KHAI_SINH"]}', now() + interval '5 days', now() + interval '20 days', 'an', 'an');
SELECT pg_temp.eq(count(*), 2, 'ủy quyền theo mô hình khác phạm vi nên cùng tồn tại') FROM ph11_bpm.delegation WHERE from_user = 'an';
SELECT pg_temp.eq(count(*), 1, 'cột sinh scope_key phân biệt phạm vi toàn bộ và phạm vi mô hình') FROM ph11_bpm.delegation WHERE scope_key = '*';
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'chi', 'chi', now(), now() + interval '1 day', 'x', 'x')$q$, '23514', 'không tự ủy quyền cho mình');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'dung', 'chi', now(), now() + interval '100 days', 'x', 'x')$q$, '23514', 'ủy quyền tối đa 90 ngày (trần 11.delegation.maxDays)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, scope, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'dung', 'chi', '{}', now(), now() + interval '1 day', 'x', 'x')$q$, '23514', 'phạm vi ủy quyền phải là all hoặc processKeys');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.delegation (id, tenant_id, from_user, to_user, status, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'dung', 'chi', 'REVOKED_ALL', now(), now() + interval '1 day', 'x', 'x')$q$, '23514', 'trạng thái ủy quyền thuộc DelegationStatus');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.delegation SET status = 'REVOKED' WHERE id = 'a1000000-0000-7000-8000-000000000121'$q$, '23514', 'thu hồi ủy quyền phải ghi người thu hồi');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.delegation WHERE id = 'a1000000-0000-7000-8000-000000000121'$q$, '42501', 'ứng dụng không xóa ủy quyền');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2030, 'x', 'x')$q$, '23505', 'mỗi tenant một lịch mỗi năm');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 1999, 'x', 'x')$q$, '23514', 'năm của lịch trong khoảng 2000 đến 2100');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, work_week, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2031, '{MON,XYZ}', 'x', 'x')$q$, '23514', 'thứ làm việc thuộc MON…SUN');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, work_hours, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2031, '{"start":"07:30","end":"17:00","breakStart":"06:00","breakEnd":"07:00"}', 'x', 'x')$q$, '23514', 'nghỉ trưa nằm trong giờ làm việc (ERR-11-028)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, work_hours, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2031, '{"start":"07:30","end":"17:00","breakStart":"11:30"}', 'x', 'x')$q$, '23514', 'giờ nghỉ trưa phải có cả bắt đầu và kết thúc');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, work_hours, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2031, '{"start":"17:00","end":"07:30"}', 'x', 'x')$q$, '23514', 'giờ kết thúc sau giờ bắt đầu');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, work_hours, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2031, '{"start":"7h30","end":"17h"}', 'x', 'x')$q$, '23514', 'giờ làm việc dạng HH:MM');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, inherited_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 2031, 'T91', 'x', 'x')$q$, '23514', 'inherited_from chỉ nhận COMMON');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.business_calendar WHERE id = 'a1000000-0000-7000-8000-000000000251'$q$, '42501', 'ứng dụng không xóa lịch năm');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.calendar_day (id, tenant_id, calendar_id, date, type, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000251', DATE '2030-02-04', 'HOLIDAY', 'Trùng ngày', 'x', 'x')$q$, '23505', 'mỗi ngày một dòng trong một lịch');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.calendar_day (id, tenant_id, calendar_id, date, type, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), DATE '2030-02-09', 'HOLIDAY', 'Lịch lạ', 'x', 'x')$q$, '23503', 'ngày nghỉ thuộc lịch có thật');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.calendar_day (id, tenant_id, calendar_id, date, type, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000251', DATE '2030-02-09', 'MAKEUP_WORK', 'Làm bù', 'x', 'x')$q$, '23514', 'loại ngày thuộc CalendarDayType (MAKEUP_WORKDAY)');
INSERT INTO ph11_bpm.calendar_day (id, tenant_id, calendar_id, date, type, name, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', pg_temp.u(251), DATE '2030-02-09', 'MAKEUP_WORKDAY', 'Làm bù Tết', 'an', 'an'), (gen_random_uuid(), 'T90', pg_temp.u(251), DATE '2030-02-10', 'SPECIAL_OFF', 'Nghỉ đột xuất', 'an', 'an');
DELETE FROM ph11_bpm.calendar_day WHERE calendar_id = pg_temp.u(251) AND type = 'SPECIAL_OFF';
SELECT pg_temp.eq(count(*), 2, 'ngày nghỉ, ngày làm bù thêm được; ngày nghỉ đột xuất xóa được (FR-11-045)') FROM ph11_bpm.calendar_day WHERE calendar_id = pg_temp.u(251);

-- ---------- 7. Hạn xử lý, gọi dịch vụ, chạy thử, đề nghị can thiệp ----------
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.due_tracking (id, tenant_id, subject, subject_id, instance_id, due_value, due_unit, start_at, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'INSTANCE', 'a1000000-0000-7000-8000-000000000071', 'a1000000-0000-7000-8000-000000000071', 5, 'WORKING_DAY', now(), now() + interval '7 days', 'x', 'x')$q$, '23505', 'mỗi đối tượng đúng một dòng theo dõi hạn');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.due_tracking (id, tenant_id, subject, subject_id, instance_id, due_value, due_unit, start_at, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'INSTANCE', gen_random_uuid(), 'a1000000-0000-7000-8000-000000000071', 5, 'WORKING_DAY', now(), now() + interval '7 days', 'x', 'x')$q$, '23514', 'hạn cấp phiên thì subject_id là chính phiên');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.due_tracking (id, tenant_id, subject, subject_id, instance_id, due_value, due_unit, start_at, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TASK', gen_random_uuid(), 'a1000000-0000-7000-8000-000000000071', 5, 'WORKING_DAY', now(), now() + interval '7 days', 'x', 'x')$q$, '23503', 'hạn cấp việc phải trỏ việc có thật (cột sinh task_id có khóa ngoại)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.due_tracking (id, tenant_id, subject, subject_id, instance_id, due_value, due_unit, start_at, due_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TASK', gen_random_uuid(), 'a1000000-0000-7000-8000-000000000071', 5, 'WORKING_WEEK', now(), now() + interval '7 days', 'x', 'x')$q$, '23514', 'đơn vị hạn thuộc DueUnit');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET due_at = start_at WHERE id = 'a1000000-0000-7000-8000-000000000141'$q$, '23514', 'hạn phải sau thời điểm bắt đầu');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET status = 'PAUSED' WHERE id = 'a1000000-0000-7000-8000-000000000141'$q$, '23514', 'tạm dừng hạn phải có paused_at và lý do');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET status = 'PAUSED', paused_at = now(), pause_reason = 'HOLIDAY' WHERE id = 'a1000000-0000-7000-8000-000000000141'$q$, '23514', 'lý do tạm dừng thuộc WAITING_SUPPLEMENT, LEGAL_SUSPENSION');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET result = 'MET' WHERE id = 'a1000000-0000-7000-8000-000000000141'$q$, '23514', 'kết quả hạn phải đi cùng thời điểm đóng');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET status = 'LATE' WHERE id = 'a1000000-0000-7000-8000-000000000141'$q$, '23514', 'trạng thái hạn thuộc ON_TIME, DUE_SOON, OVERDUE, PAUSED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET escalation_level = 4 WHERE id = 'a1000000-0000-7000-8000-000000000141'$q$, '23514', 'cấp leo thang 0 đến 3');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.due_tracking SET subject_id = gen_random_uuid() WHERE id = 'a1000000-0000-7000-8000-000000000142'$q$, '55000', 'đối tượng của dòng theo dõi hạn bất biến');
UPDATE ph11_bpm.due_tracking SET status = 'PAUSED', paused_at = now(), pause_reason = 'WAITING_SUPPLEMENT' WHERE id = pg_temp.u(141);
UPDATE ph11_bpm.due_tracking SET status = 'ON_TIME', paused_at = NULL, pause_reason = NULL, paused_duration = interval '2 days', due_at = due_at + interval '2 days' WHERE id = pg_temp.u(141);
UPDATE ph11_bpm.due_tracking SET status = 'OVERDUE', result = 'MISSED', closed_at = now() WHERE id = pg_temp.u(142);
SELECT pg_temp.eq(count(*), 1, 'tạm dừng rồi tiếp tục hạn (bổ sung hồ sơ), đóng hạn có kết quả MISSED') FROM ph11_bpm.due_tracking WHERE result = 'MISSED';

SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_call (id, tenant_id, command_id, instance_id, element_id, intent_code, timeout_at, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000152', 'a1000000-0000-7000-8000-000000000071', 'svcX', 'guiTuPhap', now() + interval '1 hour', '00000000000000000000000000000001', 'x', 'x')$q$, '23505', 'command_id gọi dịch vụ duy nhất (lũy đẳng)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_call (id, tenant_id, command_id, instance_id, element_id, intent_code, timeout_at, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'a1000000-0000-7000-8000-000000000071', 'svcX', 'khongCo', now() + interval '1 hour', '00000000000000000000000000000001', 'x', 'x')$q$, '23503', 'gọi dịch vụ phải theo ý định có thật cùng tenant');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.service_call (id, tenant_id, command_id, instance_id, element_id, intent_code, status, timeout_at, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'a1000000-0000-7000-8000-000000000071', 'svcX', 'guiTuPhap', 'SENT', now() + interval '1 hour', '00000000000000000000000000000001', 'x', 'x')$q$, '23514', 'trạng thái gọi dịch vụ thuộc REQUESTED, COMPLETED, FAILED, TIMED_OUT, CANCELLED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.service_call SET status = 'FAILED', completed_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000151'$q$, '23514', 'FAILED phải có loại lỗi và mã lỗi');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.service_call SET status = 'TIMED_OUT', completed_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000151'$q$, '23514', 'TIMED_OUT phải có mã lỗi');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.service_call SET status = 'COMPLETED' WHERE id = 'a1000000-0000-7000-8000-000000000151'$q$, '23514', 'gọi xong phải có completed_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.service_call SET command_id = gen_random_uuid() WHERE id = 'a1000000-0000-7000-8000-000000000151'$q$, '55000', 'command_id bất biến');
UPDATE ph11_bpm.service_call SET attempt = 2 WHERE id = pg_temp.u(151);
UPDATE ph11_bpm.service_call SET status = 'FAILED', completed_at = now(), error_kind = 'TECHNICAL', error_code = 'ERR-11-101', error_message = 'Hệ thống tư pháp không phản hồi' WHERE id = pg_temp.u(151);
SELECT pg_temp.eq(count(*), 1, 'thử lại tăng attempt, kết thúc FAILED kèm loại lỗi') FROM ph11_bpm.service_call WHERE status = 'FAILED' AND attempt = 2;

SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.test_run (id, tenant_id, version_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'x', 'x')$q$, '23503', 'chạy thử phải trên phiên bản có thật (khóa ngoại kèm tenant)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.test_run (id, tenant_id, version_id, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', 'DONE', 'x', 'x')$q$, '23514', 'trạng thái chạy thử thuộc RUNNING, PASSED, FAILED, ABORTED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.test_run (id, tenant_id, version_id, scenario, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000012', '[]', 'x', 'x')$q$, '23514', 'kịch bản chạy thử là đối tượng JSON');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.test_run SET status = 'PASSED' WHERE id = 'a1000000-0000-7000-8000-000000000231'$q$, '23514', 'chạy thử kết thúc phải có ended_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.test_run SET scenario = '{"clock":"REAL"}' WHERE id = 'a1000000-0000-7000-8000-000000000231'$q$, '55000', 'kịch bản chạy thử bất biến sau khi tạo');
UPDATE ph11_bpm.test_run SET status = 'PASSED', ended_at = now(), engine_instance_id = 'pi-test-1', result = '{"steps":5,"failedElement":null}' WHERE id = pg_temp.u(231);
SELECT pg_temp.eq(count(*), 1, 'chạy thử kết thúc PASSED kèm kết quả') FROM ph11_bpm.test_run WHERE status = 'PASSED';

SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_change (id, tenant_id, instance_id, type, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000072', 'MOVE_TOKEN', 'Chuyển token về bước cũ ạ', 'an', 'x', 'x')$q$, '23514', 'chuyển token cần lý do từ 30 ký tự (ERR-11-025)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_change (id, tenant_id, instance_id, type, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000072', 'VARIABLE_UPDATE', 'sai', 'an', 'x', 'x')$q$, '23514', 'sửa biến cần lý do từ 20 ký tự');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_change (id, tenant_id, instance_id, type, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000072', 'DELETE_TOKEN', 'Lý do đủ dài để qua kiểm tra độ dài tối thiểu', 'an', 'x', 'x')$q$, '23514', 'loại can thiệp thuộc VARIABLE_UPDATE, MOVE_TOKEN');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.instance_change (id, tenant_id, instance_id, type, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'VARIABLE_UPDATE', 'Lý do đủ dài để qua kiểm tra độ dài tối thiểu', 'an', 'x', 'x')$q$, '23503', 'đề nghị can thiệp phải trỏ phiên có thật');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_change SET status = 'APPLIED', approved_by = 'an', applied_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000241'$q$, '23514', 'bốn mắt: người duyệt can thiệp khác người đề nghị (BR-11-004)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_change SET status = 'APPLIED', approved_by = 'binh' WHERE id = 'a1000000-0000-7000-8000-000000000241'$q$, '23514', 'APPLIED phải có applied_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_change SET status = 'REJECTED' WHERE id = 'a1000000-0000-7000-8000-000000000241'$q$, '23514', 'trạng thái khác PENDING phải có người duyệt');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.instance_change SET reason = 'Đổi lý do sau khi gửi đề nghị can thiệp phiên' WHERE id = 'a1000000-0000-7000-8000-000000000241'$q$, '55000', 'lý do can thiệp bất biến');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.instance_change WHERE id = 'a1000000-0000-7000-8000-000000000241'$q$, '42501|0', 'ứng dụng không xóa đề nghị can thiệp');
UPDATE ph11_bpm.instance_change SET status = 'APPLIED', approved_by = 'binh', applied_at = now() WHERE id = pg_temp.u(241);
SELECT pg_temp.eq(count(*), 1, 'đề nghị can thiệp được duyệt bởi người khác và áp dụng') FROM ph11_bpm.instance_change WHERE status = 'APPLIED';

-- ---------- 8. Saga, sự cố, di trú, outbox, inbox, tham số, bảng quyết định ----------
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_log (id, tenant_id, instance_id, trigger, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000071', 'MANUAL', '00000000000000000000000000000001', 'x', 'x')$q$, '23505', 'một phiên chỉ một Saga đang RUNNING');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_log (id, tenant_id, instance_id, trigger, status, ended_at, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000071', 'MANUAL', 'DONE', now(), '00000000000000000000000000000001', 'x', 'x')$q$, '23514', 'trạng thái Saga thuộc RUNNING, SUCCEEDED, PARTIAL, FAILED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_log SET done_steps = 3 WHERE id = 'a1000000-0000-7000-8000-000000000161'$q$, '23514', 'số bước xong và lỗi không vượt tổng số bước');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_log SET status = 'SUCCEEDED' WHERE id = 'a1000000-0000-7000-8000-000000000161'$q$, '23514', 'Saga kết thúc phải có ended_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_log SET reconcile_state = 'MATCHED' WHERE id = 'a1000000-0000-7000-8000-000000000161'$q$, '23514', 'đối soát xong phải có reconciled_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_log SET reconcile_state = 'DONE' WHERE id = 'a1000000-0000-7000-8000-000000000161'$q$, '23514', 'trạng thái đối soát thuộc NONE, PENDING, MATCHED, MISMATCH');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_log SET failed_element = 'doi' WHERE id = 'a1000000-0000-7000-8000-000000000161'$q$, '55000', 'phần tử lỗi khởi phát Saga bất biến');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_step (id, tenant_id, saga_id, seq, forward_element_id, compensation_intent_code, policy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000161', 1, 'svcKhac', 'huyTuPhap', 'AUTO', 'x', 'x')$q$, '23505', 'số thứ tự bước Saga duy nhất');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_step (id, tenant_id, saga_id, seq, forward_element_id, policy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000161', 2, 'svcKhac', 'AUTO', 'x', 'x')$q$, '23514', 'bước bù trừ AUTO phải có ý định bù trừ');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_step (id, tenant_id, saga_id, seq, forward_element_id, policy, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000161', 2, 'svcKhac', 'SKIP', 'x', 'x')$q$, '23514', 'chính sách bước Saga thuộc AUTO, MANUAL, NONE_APPROVED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_step SET status = 'FAILED', ended_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000171'$q$, '23514', 'bước FAILED phải ghi lỗi cuối');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_step SET status = 'MANUAL', resolved_by = 'an', evidence = 'ngắn' WHERE id = 'a1000000-0000-7000-8000-000000000171'$q$, '23514', 'xử lý tay bước Saga cần bằng chứng từ 20 ký tự');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_step SET status = 'SKIPPED', ended_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000171'$q$, '23514', 'bỏ qua bước Saga phải được duyệt miễn hoặc có người xử lý');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_step SET seq = 9 WHERE id = 'a1000000-0000-7000-8000-000000000171'$q$, '55000', 'thứ tự bước Saga bất biến');
UPDATE ph11_bpm.saga_step SET status = 'FAILED', attempt = 3, ended_at = now(), last_error = 'Dịch vụ tư pháp trả 503' WHERE id = pg_temp.u(171);
UPDATE ph11_bpm.saga_step SET status = 'MANUAL', ended_at = NULL, resolved_by = 'binh', evidence = 'Đã gọi điện sở tư pháp hủy thủ công, biên bản số 12' WHERE id = pg_temp.u(171);
SELECT pg_temp.eq(count(*), 1, 'bước Saga lỗi chuyển sang xử lý tay có bằng chứng') FROM ph11_bpm.saga_step WHERE status = 'MANUAL';
-- ---------- Đề nghị bỏ qua bù trừ, giữ pháp lý, lần chạy mẫu tuân thủ (bản 0.4) ----------
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_skip_request (id, tenant_id, saga_id, step_id, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000161', 'a1000000-0000-7000-8000-000000000171', 'Lý do đủ dài để qua kiểm tra độ dài', 'an', 'x', 'x')$q$, '23505', 'mỗi bước Saga tối đa một đề nghị bỏ qua đang chờ duyệt');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_skip_request SET status = 'APPROVED', decided_by = 'an', decided_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000261'$q$, '23514', 'bốn mắt: người duyệt bỏ qua bù trừ khác người đề nghị (ERR-11-005)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_skip_request SET status = 'REJECTED', decided_by = 'binh', decided_at = now(), decision_comment = 'ngắn' WHERE id = 'a1000000-0000-7000-8000-000000000261'$q$, '23514', 'từ chối bỏ qua bù trừ cần ý kiến từ 20 ký tự (ERR-11-007)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_skip_request SET status = 'APPROVED' WHERE id = 'a1000000-0000-7000-8000-000000000261'$q$, '23514', 'trạng thái khác PENDING phải có người duyệt và thời điểm');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_skip_request SET reason = 'Đổi lý do sau khi gửi đề nghị bỏ qua bù trừ' WHERE id = 'a1000000-0000-7000-8000-000000000261'$q$, '55000', 'lý do đề nghị bỏ qua bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.saga_skip_request SET status = 'XOA' WHERE id = 'a1000000-0000-7000-8000-000000000261'$q$, '23514', 'trạng thái đề nghị bỏ qua thuộc PENDING, APPROVED, REJECTED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_skip_request (id, tenant_id, saga_id, step_id, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000161', gen_random_uuid(), 'Lý do đủ dài để qua kiểm tra độ dài', 'an', 'x', 'x')$q$, '23503', 'đề nghị bỏ qua phải trỏ bước Saga có thật');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.saga_skip_request (id, tenant_id, saga_id, step_id, reason, evidence, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000161', 'a1000000-0000-7000-8000-000000000171', 'Lý do đủ dài để qua kiểm tra độ dài', '{}', 'an', 'x', 'x')$q$, '23514', 'bằng chứng đề nghị bỏ qua là mảng');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.saga_skip_request WHERE id = 'a1000000-0000-7000-8000-000000000261'$q$, '42501|0', 'ứng dụng không xóa đề nghị bỏ qua bù trừ');
UPDATE ph11_bpm.saga_skip_request SET status = 'REJECTED', decided_by = 'binh', decided_at = now(), decision_comment = 'Chưa có biên bản xác nhận của cơ quan tư pháp' WHERE id = pg_temp.u(261);
SELECT pg_temp.eq(count(*), 1, 'đề nghị bỏ qua bị người khác từ chối kèm ý kiến') FROM ph11_bpm.saga_skip_request WHERE status = 'REJECTED';
INSERT INTO ph11_bpm.saga_skip_request (id, tenant_id, saga_id, step_id, reason, requested_by, created_by, updated_by) VALUES (pg_temp.u(262), 'T90', 'a1000000-0000-7000-8000-000000000161', 'a1000000-0000-7000-8000-000000000171', 'Đề nghị lại sau khi có biên bản xác nhận', 'an', 'x', 'x');
SELECT pg_temp.eq(count(*), 1, 'sau khi bị từ chối được đề nghị lại (một đề nghị PENDING)') FROM ph11_bpm.saga_skip_request WHERE status = 'PENDING';
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HS-2026-000001', 'Giữ trùng mã hồ sơ đã được giữ còn hiệu lực', 'x', 'x')$q$, '23505', 'mỗi mã hồ sơ một giữ pháp lý đang hiệu lực');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HS', 'Mã hồ sơ quá ngắn không hợp lệ', 'x', 'x')$q$, '23514', 'mã hồ sơ giữ pháp lý từ 3 ký tự');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HS-2026-000002', 'ngắn', 'x', 'x')$q$, '23514', 'lý do giữ pháp lý từ 20 ký tự');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, hold_until, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HS-2026-000003', 'Hạn giữ nằm trước thời điểm tạo bản ghi', now() - interval '1 day', 'x', 'x')$q$, '23514', 'hạn giữ pháp lý phải sau thời điểm đặt');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.legal_hold SET released_at = now(), released_by = 'binh' WHERE id = 'a1000000-0000-7000-8000-000000000271'$q$, '23514', 'gỡ giữ phải đủ ba trường: thời điểm, người gỡ, lý do');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.legal_hold SET released_at = now(), released_by = 'binh', release_reason = 'ngắn' WHERE id = 'a1000000-0000-7000-8000-000000000271'$q$, '23514', 'lý do gỡ giữ từ 10 ký tự');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.legal_hold SET business_key = 'HS-KHAC' WHERE id = 'a1000000-0000-7000-8000-000000000271'$q$, '55000', 'mã hồ sơ của giữ pháp lý bất biến');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.legal_hold WHERE id = 'a1000000-0000-7000-8000-000000000271'$q$, '42501|0', 'ứng dụng không xóa giữ pháp lý');
UPDATE ph11_bpm.legal_hold SET released_at = now(), released_by = 'binh', release_reason = 'Cơ quan điều tra đã có văn bản chấm dứt' WHERE id = pg_temp.u(271);
INSERT INTO ph11_bpm.legal_hold (id, tenant_id, business_key, reason, created_by, updated_by) VALUES (pg_temp.u(272), 'T90', 'HS-2026-000001', 'Giữ lại sau khi đã gỡ lần trước theo yêu cầu mới', 'x', 'x');
SELECT pg_temp.eq(count(*), 2, 'giữ đã gỡ còn làm bằng chứng, đặt lại được giữ mới cùng mã hồ sơ') FROM ph11_bpm.legal_hold WHERE business_key = 'HS-2026-000001';
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compliance_sample_run (id, tenant_id, evidence_pack_id, environment, requested_by,  created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'PROD', 'an',  'x', 'x')$q$, '23514', 'lần chạy mẫu chỉ chạy ở TEST hoặc STAGING (FR-11-064)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compliance_sample_run (id, tenant_id, evidence_pack_id, environment, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'a1000000-0000-7000-8000-000000000282', 'TEST', 'an', 'x', 'x')$q$, '23505', 'mã gói bằng chứng duy nhất trong tenant');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compliance_sample_run (id, tenant_id, evidence_pack_id, environment, requested_by, period_from, period_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'TEST', 'an', now() - interval '400 days', now(), 'x', 'x')$q$, '23514', 'khoảng thống kê lần chạy mẫu tối đa 366 ngày (ERR-11-039)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.compliance_sample_run (id, tenant_id, evidence_pack_id, environment, requested_by, period_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), 'TEST', 'an', now(), 'x', 'x')$q$, '23514', 'khoảng thống kê phải đủ hai đầu');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.compliance_sample_run SET status = 'PASSED', finished_at = now() WHERE id = 'a1000000-0000-7000-8000-000000000281'$q$, '23514', 'lần chạy mẫu đạt phải có băm và vị trí gói bằng chứng');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.compliance_sample_run SET status = 'FAILED', finished_at = now(), checksum = 'abc', pack_ref = 'bpm/T90/pack-1' WHERE id = 'a1000000-0000-7000-8000-000000000281'$q$, '23514', 'băm gói bằng chứng đúng 32 byte');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.compliance_sample_run SET status = 'PASSED' WHERE id = 'a1000000-0000-7000-8000-000000000281'$q$, '23514', 'lần chạy mẫu kết thúc phải có thời điểm kết thúc');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.compliance_sample_run SET environment = 'STAGING' WHERE id = 'a1000000-0000-7000-8000-000000000281'$q$, '55000', 'môi trường lần chạy mẫu bất biến');
SELECT pg_temp.expect($q$DELETE FROM ph11_bpm.compliance_sample_run WHERE id = 'a1000000-0000-7000-8000-000000000281'$q$, '42501|0', 'ứng dụng không xóa lần chạy mẫu');
UPDATE ph11_bpm.compliance_sample_run SET status = 'PASSED', finished_at = now(), checksum = pg_temp.h('pack-1'), pack_ref = 'bpm/T90/compliance/pack-1', result = '{"elements":["startEvent","userTask","serviceTask"],"flowable":"7.x"}' WHERE id = pg_temp.u(281);
SELECT pg_temp.eq(count(*), 1, 'lần chạy mẫu tuân thủ đạt có băm và gói bằng chứng') FROM ph11_bpm.compliance_sample_run WHERE status = 'PASSED' AND environment = 'TEST';
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.incident (id, tenant_id, type, trace_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TIMEOUT', '00000000000000000000000000000001', 'x', 'x')$q$, '23514', 'loại sự cố thuộc IncidentType (JOB_FAILED, SERVICE_TIMEOUT, …)');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.incident SET status = 'RESOLVED' WHERE id = 'a1000000-0000-7000-8000-000000000181'$q$, '23514', 'sự cố đã xử lý phải có người xử lý và thời điểm');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.incident SET status = 'IGNORED', handled_by = 'an', resolved_at = now(), reason = 'bỏ qua' WHERE id = 'a1000000-0000-7000-8000-000000000181'$q$, '23514', 'bỏ qua sự cố cần lý do từ 20 ký tự');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.incident SET status = 'CLOSED' WHERE id = 'a1000000-0000-7000-8000-000000000181'$q$, '23514', 'trạng thái sự cố thuộc OPEN, RETRYING, RESOLVED, IGNORED');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.incident SET type = 'ENGINE_ERROR' WHERE id = 'a1000000-0000-7000-8000-000000000181'$q$, '55000', 'loại sự cố bất biến');
UPDATE ph11_bpm.incident SET status = 'RETRYING', retries_done = 1 WHERE id = pg_temp.u(181);
UPDATE ph11_bpm.incident SET status = 'RESOLVED', resolved_at = now(), handled_by = 'an' WHERE id = pg_temp.u(181);
SELECT pg_temp.eq(count(*), 1, 'vòng đời sự cố OPEN, RETRYING, RESOLVED') FROM ph11_bpm.incident WHERE status = 'RESOLVED';

SELECT pg_temp.expect($q$UPDATE ph11_bpm.migration_plan SET approved_by = 'an' WHERE id = 'a1000000-0000-7000-8000-000000000191'$q$, '23514', 'bốn mắt: người duyệt di trú khác người đề nghị');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.migration_plan SET status = 'RUNNING' WHERE id = 'a1000000-0000-7000-8000-000000000191'$q$, '23514', 'chạy di trú phải có người duyệt');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.migration_plan SET status = 'REJECTED', approved_by = 'binh', approved_at = now(), decision_comment = 'không đạt' WHERE id = 'a1000000-0000-7000-8000-000000000191'$q$, '23514', 'từ chối di trú cần ý kiến từ 20 ký tự');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.migration_plan SET status = 'CANCELLED' WHERE id = 'a1000000-0000-7000-8000-000000000191'$q$, '23514', 'trạng thái kế hoạch di trú thuộc MigrationStatus');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.migration_plan SET summary = '{"total": 5, "migrated": 4, "failed": 3}' WHERE id = 'a1000000-0000-7000-8000-000000000191'$q$, '23514', 'tóm tắt di trú: migrated cộng failed không vượt total');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.migration_plan SET to_version = 1 WHERE id = 'a1000000-0000-7000-8000-000000000191'$q$, '55000', 'phiên bản đích của kế hoạch di trú bất biến');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.migration_plan (id, tenant_id, process_key, from_version, to_version, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LT_KHAI_SINH', 1, 1, 'Di trú sang chính phiên bản hiện tại của quy trình', 'an', 'x', 'x')$q$, '23514', 'di trú phải sang phiên bản khác');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.migration_plan (id, tenant_id, process_key, from_version, to_version, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LT_KHAI_SINH', 1, 9, 'Di trú sang phiên bản không tồn tại của quy trình', 'an', 'x', 'x')$q$, '23503', 'phiên bản đích phải có thật');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.migration_plan (id, tenant_id, process_key, from_version, to_version, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LT_KHAI_SINH', 1, 2, 'ngắn', 'an', 'x', 'x')$q$, '23514', 'lý do di trú từ 20 ký tự');

SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'X', 't91.bpm.instance.started.v1', 'instance', 'a', 'a', '{}', '00000000000000000000000000000001')$q$, '23514', 'topic phải mang tiền tố đúng tenant');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'X', 't90.bpm.khac.v1', 'instance', 'a', 'a', '{}', '00000000000000000000000000000001')$q$, '23514', 'topic thuộc danh mục sự kiện PH-11');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'InstanceStarted', 't90.bpm.instance.started.v1', 'instance', 'a', 'a', '{"variables": {"x": 1}}', '00000000000000000000000000000001')$q$, '23514', 'outbox không chứa giá trị biến (NFR bảo mật)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'InstanceStarted', 't90.bpm.instance.started.v1', 'instance', 'a', 'a', '{"fullName": "x"}', '00000000000000000000000000000001')$q$, '23514', 'outbox không chứa họ tên, định danh');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, status, trace_id) VALUES (gen_random_uuid(), 'T90', 'InstanceStarted', 't90.bpm.instance.started.v1', 'instance', 'a', 'a', '{}', 'DONE', '00000000000000000000000000000001')$q$, '23514', 'trạng thái outbox thuộc PENDING, SENT, FAILED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, status, trace_id) VALUES (gen_random_uuid(), 'T90', 'InstanceStarted', 't90.bpm.instance.started.v1', 'instance', 'a', 'a', '{}', 'SENT', '00000000000000000000000000000001')$q$, '23514', 'outbox SENT phải có sent_at');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.outbox_event SET payload = '{"x": 1}' WHERE event_id = 'a1000000-0000-7000-8000-000000000211'$q$, '55000', 'nội dung sự kiện outbox bất biến');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.outbox_event SET topic = 't90.bpm.instance.completed.v1' WHERE event_id = 'a1000000-0000-7000-8000-000000000211'$q$, '55000', 'topic sự kiện outbox bất biến');
UPDATE ph11_bpm.outbox_event SET status = 'SENT', sent_at = now(), attempts = 1 WHERE event_id = pg_temp.u(211);
SELECT pg_temp.eq(count(*), 1, 'chỉ trạng thái gửi của outbox đổi được (PENDING sang SENT)') FROM ph11_bpm.outbox_event WHERE status = 'SENT';
INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
VALUES (pg_temp.u(212), 'T90', 'NotificationRequested', 't90.bpm.notification.requested.v1', 'instance', 'a', 'a', '{}', pg_temp.tr(212)),
       (pg_temp.u(213), 'T90', 'AuditRecorded', 't90.bpm.audit.recorded.v1', 'process_version', 'LT_KHAI_SINH:3', 'LT_KHAI_SINH:3', '{"action": "MODEL_PUBLISH"}', pg_temp.tr(213));
SELECT pg_temp.eq(count(*), 2, 'outbox nhận topic EVT-11-20 (notification.requested) và EVT-11-21 (bpm.audit.recorded)') FROM ph11_bpm.outbox_event WHERE event_id IN (pg_temp.u(212), pg_temp.u(213));
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id) VALUES (gen_random_uuid(), 'T90', 'AuditRecorded', 't90.audit.recorded.v1', 'x', 'a', 'a', '{}', '00000000000000000000000000000001')$q$, '23514', 'topic kiểm toán phải là bpm.audit.recorded.v1 (không thiếu tiền tố bpm)');
INSERT INTO ph11_bpm.incident (id, tenant_id, type, trace_id, created_by, updated_by) VALUES (pg_temp.u(182), 'T90', 'SUPPLEMENT_EXPIRED', pg_temp.tr(182), 'system', 'system');
SELECT pg_temp.eq(count(*), 1, 'sự cố SUPPLEMENT_EXPIRED (hết hạn bổ sung hồ sơ) được nhận') FROM ph11_bpm.incident WHERE type = 'SUPPLEMENT_EXPIRED';
SELECT pg_temp.eq((value #>> '{}')::bigint, 30, 'seed: 11.designer.autosaveSeconds mặc định 30') FROM ph11_bpm.tenant_setting WHERE tenant_id = 'T90' AND key IN ('11.designer.autosaveSeconds');
SELECT pg_temp.eq(count(*), 4, 'seed có bốn tham số mới của FRS 0.2 (autosave, draftDebounce, unmask, escalation)') FROM ph11_bpm.tenant_setting WHERE tenant_id = 'T90' AND key IN ('11.designer.autosaveSeconds', '11.task.draftDebounceSeconds', '11.task.unmaskSeconds', '11.escalation.nextLevelHours');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '4' WHERE tenant_id = 'T90' AND key IN ('11.designer.autosaveSeconds')$q$, '23514', 'tự lưu thiết kế 5 đến 300 giây');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '0' WHERE tenant_id = 'T90' AND key IN ('11.task.draftDebounceSeconds')$q$, '23514', 'độ trễ lưu nháp việc 1 đến 60 giây');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '301' WHERE tenant_id = 'T90' AND key IN ('11.task.unmaskSeconds')$q$, '23514', 'thời gian hiện giá trị SENSITIVE 10 đến 300 giây');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '73' WHERE tenant_id = 'T90' AND key IN ('11.escalation.nextLevelHours')$q$, '23514', 'cách nhau hai mức leo thang 1 đến 72 giờ làm việc');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type) VALUES ('T90', 'ServiceResultConsumer', 'msg-0001', 't90.bpm.service.completed.v1', 'x')$q$, '23505', 'nhận trùng message_id bị chặn (lũy đẳng inbox)');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type) VALUES ('T90', 'ServiceResultConsumer', 'msg-0002', 't91.bpm.service.completed.v1', 'x')$q$, '23514', 'nguồn inbox phải đúng tiền tố tenant');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type, status) VALUES ('T90', 'ServiceResultConsumer', 'msg-0003', 't90.bpm.service.completed.v1', 'x', 'DONE')$q$, '23514', 'trạng thái inbox thuộc RECEIVED, PROCESSED, UNCORRELATED, FAILED');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type, payload) VALUES ('T90', 'ServiceResultConsumer', 'msg-0004', 't90.bpm.service.completed.v1', 'x', '{"formData": {}}')$q$, '23514', 'inbox không chứa dữ liệu biểu mẫu');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.inbox_message (tenant_id, consumer, message_id, source, event_type, status) VALUES ('T90', 'ServiceResultConsumer', 'msg-0005', 't90.bpm.service.completed.v1', 'x', 'PROCESSED')$q$, '23514', 'inbox đã xử lý phải có processed_at');

SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '100' WHERE tenant_id = 'T90' AND key IN ('11.task.dueSoonHours')$q$, '23514', 'tham số 11.task.dueSoonHours ngoài miền 1 đến 72 bị chặn');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '"abc"' WHERE tenant_id = 'T90' AND key IN ('11.task.dueSoonHours')$q$, '23514', 'tham số số không nhận chuỗi');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '"0 0 2 *"' WHERE tenant_id = 'T90' AND key IN ('11.saga.reconcileCron')$q$, '23514', 'biểu thức cron phải đủ 6 trường');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '"SOMETIME"' WHERE tenant_id = 'T90' AND key IN ('11.due.receiveAfterHoursRule')$q$, '23514', 'quy tắc nhận ngoài giờ thuộc NEXT_WORKING_START, SAME_DAY');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET value = '100' WHERE tenant_id = 'T90' AND key IN ('11.delegation.maxDays')$q$, '23514', 'ủy quyền tối đa 90 ngày cũng là miền của tham số');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.tenant_setting (id, tenant_id, key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '11.task.khongCo', '5', 'x', 'x')$q$, '23514', 'khóa tham số ngoài 36 khóa FRS 8.2 bị từ chối');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.tenant_setting (id, tenant_id, key, value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'task.dueSoonHours', '5', 'x', 'x')$q$, '23514', 'khóa tham số phải bắt đầu bằng 11.');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.tenant_setting SET key = concat('11.task.', 'bulkMax') WHERE tenant_id = 'T90' AND key IN ('11.task.dueSoonHours')$q$, '55000', 'khóa tham số bất biến');
UPDATE ph11_bpm.tenant_setting SET value = '48' WHERE tenant_id = 'T90' AND key IN ('11.task.dueSoonHours');
SELECT pg_temp.eq(count(*), 1, 'tham số đúng miền cập nhật được') FROM ph11_bpm.tenant_setting WHERE tenant_id = 'T90' AND key IN ('11.task.dueSoonHours') AND value = '48';
SELECT pg_temp.expect($q$UPDATE ph11_bpm.decision_table SET hit_policy = 'ANY' WHERE id = 'a1000000-0000-7000-8000-000000000201'$q$, '23514', 'chính sách trúng chỉ UNIQUE hoặc FIRST');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.decision_table (id, tenant_id, code, name, inputs, outputs, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'duoi6Tuoi', 'Trùng', '["a"]', '["b"]', sha256('x'), 'x', 'x')$q$, '23505', 'mỗi mã bảng quyết định một số phiên bản');
SELECT pg_temp.expect($q$INSERT INTO ph11_bpm.decision_table (id, tenant_id, code, name, inputs, outputs, checksum, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'bangRong', 'Rỗng', '[]', '["b"]', sha256('x'), 'x', 'x')$q$, '23514', 'bảng quyết định có ít nhất một đầu vào, một đầu ra');

-- ---------- 9. Quyền vai trò và schema engine ----------
RESET ROLE;
SELECT pg_temp.eq(CASE WHEN has_schema_privilege('dh_platform_app', 'ph11_flowable', 'USAGE') THEN 1 ELSE 0 END, 0, 'ứng dụng nghiệp vụ không có quyền trên schema ph11_flowable');
SELECT pg_temp.eq(CASE WHEN has_schema_privilege('dh_report_ro', 'ph11_flowable', 'USAGE') THEN 1 ELSE 0 END, 0, 'vai trò báo cáo không có quyền trên schema ph11_flowable');
SELECT pg_temp.eq(count(*), 0, 'bảng ph11_flowable do Flowable tạo, DDL không tạo bảng ACT_*') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'ph11_flowable' AND c.relkind IN ('r', 'p');
SELECT pg_temp.eq(count(*), 0, 'không bảng nào trong ph11_bpm tắt FORCE RLS (trừ shedlock)') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'ph11_bpm' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname <> 'shedlock' AND NOT (c.relrowsecurity AND c.relforcerowsecurity);
SET ROLE dh_report_ro;
SET app.tenant_id = 'T90';
SELECT pg_temp.eq(count(*), 1, 'vai trò báo cáo đọc được mô hình T90 qua RLS') FROM ph11_bpm.process_model WHERE process_key = 'LT_KHAI_SINH';
SELECT pg_temp.eq(count(*), 1, 'vai trò báo cáo đọc cột an toàn của việc') FROM (SELECT id, status, assignee, due_at FROM ph11_bpm.task_index) t;
SELECT pg_temp.expect($q$SELECT result_enc FROM ph11_bpm.task_index$q$, '42501', 'vai trò báo cáo không đọc kết quả biểu mẫu');
SELECT pg_temp.expect($q$SELECT text FROM ph11_bpm.task_comment$q$, '42501', 'vai trò báo cáo không đọc ý kiến trên việc');
SELECT pg_temp.expect($q$SELECT payload FROM ph11_bpm.inbox_message$q$, '42501', 'vai trò báo cáo không đọc nội dung inbox');
SELECT pg_temp.expect($q$SELECT payload FROM ph11_bpm.instance_change$q$, '42501', 'vai trò báo cáo không đọc đề nghị can thiệp phiên');
SELECT pg_temp.expect($q$SELECT result FROM ph11_bpm.test_run$q$, '42501', 'vai trò báo cáo không đọc kết quả chạy thử');
SELECT pg_temp.expect($q$UPDATE ph11_bpm.process_model SET name = 'x'$q$, '42501', 'vai trò báo cáo không ghi');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq(count(*), 0, 'vai trò báo cáo dưới T91 không thấy mô hình T90') FROM ph11_bpm.process_model WHERE tenant_id = 'T90';
RESET ROLE;

SELECT count(*) AS so_khoi_pass FROM pg_temp.passed \gset
\echo Kết thúc: :so_khoi_pass khối PASS
