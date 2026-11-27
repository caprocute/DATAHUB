-- =============================================================================
-- D03-03-PH18 · Kiểm thử DDL ph18_ops: cô lập tenant (RLS) cho mọi bảng, dòng COMMON dùng chung chỉ phiên COMMON ghi, bảng chỉ thêm,
-- máy trạng thái DLQ, phát lại, tham số, mẫu thông báo, việc, sự cố, khôi phục, di trú, cắt chuyển; bốn mắt; kiểm miền và trần tham số;
-- payload DLQ gốc không sửa; vai readonly không đọc payload; vai worker chỉ bảng di trú, khôi phục; phân vùng không truy cập trực tiếp;
-- khung nhìn tương thích DD-13 notification, DD-14 config_param. TỆP SINH bởi tools/sinh_test.py; sửa ở đó rồi sinh lại.
-- Chạy sau ph18_ops.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d ph18_test -f ph18_isolation_test.sql
-- pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại, 42501 quyền hoặc RLS,
-- 55000 bất biến, chỉ thêm hoặc chuyển trạng thái sai) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_ops_app') THEN CREATE ROLE dh_ops_app LOGIN NOBYPASSRLS; END IF;
  GRANT ph18_app TO dh_ops_app;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_ops_ro') THEN CREATE ROLE dh_ops_ro LOGIN NOBYPASSRLS; END IF;
  GRANT ph18_readonly TO dh_ops_ro;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_ops_worker') THEN CREATE ROLE dh_ops_worker LOGIN NOBYPASSRLS; END IF;
  GRANT ph18_worker TO dh_ops_worker;
END $$;

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

CREATE FUNCTION pg_temp.ok(p_sql text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
CREATE TEMP TABLE ts0 (v timestamptz);
INSERT INTO ts0 VALUES (date_trunc('second', now()));
INSERT INTO ids VALUES ('outbox_event', gen_random_uuid()), ('inbox_event', gen_random_uuid()), ('param_namespace', gen_random_uuid()), ('param_definition', gen_random_uuid()), ('param_change_request', gen_random_uuid()), ('param_value', gen_random_uuid()), ('param_value_version', gen_random_uuid()), ('feature_flag', gen_random_uuid()), ('egress_allowlist_entry', gen_random_uuid()), ('param_bundle', gen_random_uuid()), ('dlq_source', gen_random_uuid()), ('error_guide', gen_random_uuid()), ('dlq_group', gen_random_uuid()), ('dlq_message', gen_random_uuid()), ('dlq_payload_ref', gen_random_uuid()), ('dlq_revision', gen_random_uuid()), ('dlq_assignment', gen_random_uuid()), ('replay_job', gen_random_uuid()), ('replay_item', gen_random_uuid()), ('dlq_audit', gen_random_uuid()), ('notification_template', gen_random_uuid()), ('notification_template_version', gen_random_uuid()), ('notification_rule', gen_random_uuid()), ('notification_message', gen_random_uuid()), ('notification_delivery', gen_random_uuid()), ('user_notification_pref', gen_random_uuid()), ('suppression_entry', gen_random_uuid()), ('task_type', gen_random_uuid()), ('task_item', gen_random_uuid()), ('task_reminder', gen_random_uuid()), ('work_calendar', gen_random_uuid()), ('calendar_holiday', gen_random_uuid()), ('maintenance_window', gen_random_uuid()), ('incident', gen_random_uuid()), ('incident_timeline', gen_random_uuid()), ('incident_link', gen_random_uuid()), ('backup_object', gen_random_uuid()), ('backup_run', gen_random_uuid()), ('restore_verification', gen_random_uuid()), ('tenant_restore_request', gen_random_uuid()), ('tenant_restore_step', gen_random_uuid()), ('tenant_export_job', gen_random_uuid()), ('dr_drill', gen_random_uuid()), ('merge_transfer', gen_random_uuid()), ('legacy_source', gen_random_uuid()), ('migration_plan', gen_random_uuid()), ('migration_plan_item', gen_random_uuid()), ('migration_run', gen_random_uuid()), ('migration_run_item_result', gen_random_uuid()), ('migration_error_record', gen_random_uuid()), ('migration_reconciliation', gen_random_uuid()), ('credential_reissue_marker', gen_random_uuid()), ('parallel_run_group', gen_random_uuid()), ('shadow_comparison_sample', gen_random_uuid()), ('cutover_checklist', gen_random_uuid()), ('cutover_log', gen_random_uuid()), ('ops_report', gen_random_uuid());
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.ts() RETURNS timestamptz LANGUAGE sql AS $$ SELECT v FROM ts0 $$;
GRANT SELECT ON pg_temp.ids, pg_temp.ts0 TO PUBLIC;


-- ---------- 0. Danh mục hệ thống: FORCE RLS, bốn chính sách, phân vùng không cấp quyền, không extension trong schema ----------
SELECT pg_temp.is_true($q$SELECT count(*) = 57 FROM pg_class c WHERE c.relnamespace = 'ph18_ops'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition$q$, '0.01 schema có đúng 57 bảng cha');
SELECT pg_temp.is_true($q$SELECT bool_and(c.relrowsecurity AND c.relforcerowsecurity) FROM pg_class c WHERE c.relnamespace = 'ph18_ops'::regnamespace AND c.relname IN ('outbox_event', 'inbox_event', 'param_namespace', 'param_definition', 'param_change_request', 'param_value', 'param_value_version', 'feature_flag', 'egress_allowlist_entry', 'param_bundle', 'dlq_source', 'error_guide', 'dlq_group', 'dlq_message', 'dlq_payload_ref', 'dlq_revision', 'dlq_assignment', 'replay_job', 'replay_item', 'dlq_audit', 'notification_template', 'notification_template_version', 'notification_rule', 'notification_message', 'notification_delivery', 'user_notification_pref', 'suppression_entry', 'task_type', 'task_item', 'task_reminder', 'work_calendar', 'calendar_holiday', 'maintenance_window', 'incident', 'incident_timeline', 'incident_link', 'backup_object', 'backup_run', 'restore_verification', 'tenant_restore_request', 'tenant_restore_step', 'tenant_export_job', 'dr_drill', 'merge_transfer', 'legacy_source', 'migration_plan', 'migration_plan_item', 'migration_run', 'migration_run_item_result', 'migration_error_record', 'migration_reconciliation', 'credential_reissue_marker', 'parallel_run_group', 'shadow_comparison_sample', 'cutover_checklist', 'cutover_log', 'ops_report')$q$, '0.02 mọi bảng bật và FORCE RLS');
SELECT pg_temp.is_true($q$SELECT bool_and(k = 4) FROM (SELECT c.relname, count(p.polname) k FROM pg_class c LEFT JOIN pg_policy p ON p.polrelid = c.oid WHERE c.relnamespace = 'ph18_ops'::regnamespace AND c.relname IN ('outbox_event', 'inbox_event', 'param_namespace', 'param_definition', 'param_change_request', 'param_value', 'param_value_version', 'feature_flag', 'egress_allowlist_entry', 'param_bundle', 'dlq_source', 'error_guide', 'dlq_group', 'dlq_message', 'dlq_payload_ref', 'dlq_revision', 'dlq_assignment', 'replay_job', 'replay_item', 'dlq_audit', 'notification_template', 'notification_template_version', 'notification_rule', 'notification_message', 'notification_delivery', 'user_notification_pref', 'suppression_entry', 'task_type', 'task_item', 'task_reminder', 'work_calendar', 'calendar_holiday', 'maintenance_window', 'incident', 'incident_timeline', 'incident_link', 'backup_object', 'backup_run', 'restore_verification', 'tenant_restore_request', 'tenant_restore_step', 'tenant_export_job', 'dr_drill', 'merge_transfer', 'legacy_source', 'migration_plan', 'migration_plan_item', 'migration_run', 'migration_run_item_result', 'migration_error_record', 'migration_reconciliation', 'credential_reissue_marker', 'parallel_run_group', 'shadow_comparison_sample', 'cutover_checklist', 'cutover_log', 'ops_report') GROUP BY c.relname) x$q$, '0.03 mọi bảng có bốn chính sách RLS');
SELECT pg_temp.is_true($q$SELECT bool_and(a.attnotnull) AND count(*) = 57 * 7 FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid WHERE c.relnamespace = 'ph18_ops'::regnamespace AND c.relname IN ('outbox_event', 'inbox_event', 'param_namespace', 'param_definition', 'param_change_request', 'param_value', 'param_value_version', 'feature_flag', 'egress_allowlist_entry', 'param_bundle', 'dlq_source', 'error_guide', 'dlq_group', 'dlq_message', 'dlq_payload_ref', 'dlq_revision', 'dlq_assignment', 'replay_job', 'replay_item', 'dlq_audit', 'notification_template', 'notification_template_version', 'notification_rule', 'notification_message', 'notification_delivery', 'user_notification_pref', 'suppression_entry', 'task_type', 'task_item', 'task_reminder', 'work_calendar', 'calendar_holiday', 'maintenance_window', 'incident', 'incident_timeline', 'incident_link', 'backup_object', 'backup_run', 'restore_verification', 'tenant_restore_request', 'tenant_restore_step', 'tenant_export_job', 'dr_drill', 'merge_transfer', 'legacy_source', 'migration_plan', 'migration_plan_item', 'migration_run', 'migration_run_item_result', 'migration_error_record', 'migration_reconciliation', 'credential_reissue_marker', 'parallel_run_group', 'shadow_comparison_sample', 'cutover_checklist', 'cutover_log', 'ops_report') AND a.attname IN ('id', 'tenant_id', 'created_at', 'created_by', 'updated_at', 'updated_by', 'version')$q$, '0.04 mọi bảng có bảy cột ngữ cảnh NOT NULL');
SELECT pg_temp.is_true($q$SELECT count(*) = 4 FROM pg_partitioned_table p JOIN pg_class c ON c.oid = p.partrelid WHERE c.relnamespace = 'ph18_ops'::regnamespace$q$, '0.05 có 4 bảng phân vùng (dlq_message, dlq_audit, notification_delivery, shadow_comparison_sample)');
SELECT pg_temp.is_true($q$SELECT bool_and(NOT has_table_privilege('ph18_app', c.oid, 'SELECT') AND NOT has_table_privilege('ph18_readonly', c.oid, 'SELECT') AND NOT has_table_privilege('ph18_worker', c.oid, 'SELECT')) AND count(*) >= 16 FROM pg_class c WHERE c.relnamespace = 'ph18_ops'::regnamespace AND c.relispartition$q$, '0.06 phân vùng không cấp quyền trực tiếp cho vai nào, mỗi bảng phân vùng có sẵn ≥ 4 tháng');
SELECT pg_temp.is_true($q$SELECT NOT EXISTS (SELECT 1 FROM pg_extension WHERE extnamespace = 'ph18_ops'::regnamespace)$q$, '0.07 không có extension trong schema ph18_ops');
SELECT pg_temp.is_true($q$SELECT NOT rolcanlogin AND NOT rolbypassrls FROM pg_roles WHERE rolname = 'ph18_owner'$q$, '0.08 ph18_owner NOLOGIN, không BYPASSRLS');
SELECT pg_temp.is_true($q$SELECT count(*) = 4 FROM pg_roles WHERE rolname IN ('ph18_owner', 'ph18_app', 'ph18_readonly', 'ph18_worker') AND NOT rolbypassrls$q$, '0.09 bốn vai ph18_* không BYPASSRLS');

-- ---------- 1. Cô lập tenant từng bảng (sinh tự động) ----------
SET ROLE dh_ops_app;
-- outbox_event (Bảng kỹ thuật (không có mã EN).)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.outbox_event (id, tenant_id, created_by, updated_by, event_type, topic, aggregate_type, aggregate_id, partition_key, payload) VALUES (pg_temp.id('outbox_event'), 'T90', 'kiem-thu', 'kiem-thu', 'ops.param.changed', 't90.ops.param.changed.v1', 'Giá trị kiểm thử mẫu', 'Giá trị kiểm thử mẫu', 'Giá trị kiểm thử mẫu', '{"paramKey": "18.dlq.replay.batch-max"}'::jsonb)$q$, '1.01 outbox_event a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.outbox_event WHERE id = pg_temp.id('outbox_event')$q$, '1.01 outbox_event b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.outbox_event (id, tenant_id, created_by, updated_by, event_type, topic, aggregate_type, aggregate_id, partition_key, payload) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ops.param.changed', 't90.ops.param.changed.v1', 'Giá trị kiểm thử mẫu', 'Giá trị kiểm thử mẫu', 'Giá trị kiểm thử mẫu', '{"paramKey": "18.dlq.replay.batch-max"}'::jsonb)$q$, '42501', '1.01 outbox_event c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.outbox_event SET updated_by = 't91-x' WHERE id = pg_temp.id('outbox_event')$q$, '42501', '1.01 outbox_event d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.outbox_event WHERE id = pg_temp.id('outbox_event') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.01 outbox_event e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.outbox_event WHERE id = pg_temp.id('outbox_event') AND updated_by = 'kiem-thu'$q$, '1.01 outbox_event f T90 vẫn thấy đúng một dòng, không bị sửa');
-- inbox_event (Bảng kỹ thuật (không có mã EN).)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.inbox_event (id, tenant_id, created_by, updated_by, consumer, event_id, source_topic, event_type) VALUES (pg_temp.id('inbox_event'), 'T90', 'kiem-thu', 'kiem-thu', 'DlqIngest', 'dlq-key-0001', 't90.ops.dlq.v1', 'Giá trị kiểm thử mẫu')$q$, '1.02 inbox_event a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.inbox_event WHERE id = pg_temp.id('inbox_event')$q$, '1.02 inbox_event b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.inbox_event (id, tenant_id, created_by, updated_by, consumer, event_id, source_topic, event_type) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'DlqIngest', 'dlq-key-0001', 't90.ops.dlq.v1', 'Giá trị kiểm thử mẫu')$q$, '42501', '1.02 inbox_event c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.inbox_event SET updated_by = 't91-x' WHERE id = pg_temp.id('inbox_event') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.02 inbox_event d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.inbox_event WHERE id = pg_temp.id('inbox_event') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.02 inbox_event e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.inbox_event WHERE id = pg_temp.id('inbox_event') AND updated_by = 'kiem-thu'$q$, '1.02 inbox_event f T90 vẫn thấy đúng một dòng, không bị sửa');
-- param_namespace (EN-18-01)
SET app.tenant_id = 'COMMON';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_namespace (id, tenant_id, created_by, updated_by, code, owner_module, title) VALUES (pg_temp.id('param_namespace'), 'COMMON', 'kiem-thu', 'kiem-thu', 't90test', 'PH-18', 'Không gian kiểm thử')$q$, '1.03 param_namespace a chèn dòng mẫu COMMON');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_namespace WHERE id = pg_temp.id('param_namespace')$q$, '1.03 param_namespace b T91 đọc được dòng COMMON dùng chung');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_namespace (id, tenant_id, created_by, updated_by, code, owner_module, title) VALUES (gen_random_uuid(), 'COMMON', 'kiem-thu', 'kiem-thu', 't90test', 'PH-18', 'Không gian kiểm thử')$q$, '42501', '1.03 param_namespace c T91 không chèn dòng của COMMON');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_namespace SET updated_by = 't91-x' WHERE id = pg_temp.id('param_namespace') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.03 param_namespace d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_namespace WHERE id = pg_temp.id('param_namespace')$q$, '42501', '1.03 param_namespace e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'COMMON';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_namespace WHERE id = pg_temp.id('param_namespace') AND updated_by = 'kiem-thu'$q$, '1.03 param_namespace f COMMON vẫn thấy đúng một dòng, không bị sửa');
-- param_definition (EN-18-02)
SET app.tenant_id = 'COMMON';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, created_by, updated_by, namespace_code, param_key, value_type, default_value, min_value, max_value, platform_ceiling, label) VALUES (pg_temp.id('param_definition'), 'COMMON', 'kiem-thu', 'kiem-thu', 't90test', 't90test.batch-max', 'INT', '100'::jsonb, 1, 1000, '500'::jsonb, 'Số mục tối đa')$q$, '1.04 param_definition a chèn dòng mẫu COMMON');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_definition WHERE id = pg_temp.id('param_definition')$q$, '1.04 param_definition b T91 đọc được dòng COMMON dùng chung');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, created_by, updated_by, namespace_code, param_key, value_type, default_value, min_value, max_value, platform_ceiling, label) VALUES (gen_random_uuid(), 'COMMON', 'kiem-thu', 'kiem-thu', 't90test', 't90test.batch-max', 'INT', '100'::jsonb, 1, 1000, '500'::jsonb, 'Số mục tối đa')$q$, '42501', '1.04 param_definition c T91 không chèn dòng của COMMON');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_definition SET updated_by = 't91-x' WHERE id = pg_temp.id('param_definition') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.04 param_definition d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_definition WHERE id = pg_temp.id('param_definition')$q$, '42501', '1.04 param_definition e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'COMMON';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_definition WHERE id = pg_temp.id('param_definition') AND updated_by = 'kiem-thu'$q$, '1.04 param_definition f COMMON vẫn thấy đúng một dòng, không bị sửa');
-- param_change_request (EN-18-05)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_change_request (id, tenant_id, created_by, updated_by, definition_id, param_key, proposed_value, reason, requested_by, expires_at) VALUES (pg_temp.id('param_change_request'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('param_definition'), 't90test.batch-max', '200'::jsonb, 'Tăng loạt phát lại cho đợt di trú', 'to-an', now() + interval '3 days')$q$, '1.05 param_change_request a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.param_change_request WHERE id = pg_temp.id('param_change_request')$q$, '1.05 param_change_request b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_change_request (id, tenant_id, created_by, updated_by, definition_id, param_key, proposed_value, reason, requested_by, expires_at) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('param_definition'), 't90test.batch-max', '200'::jsonb, 'Tăng loạt phát lại cho đợt di trú', 'to-an', now() + interval '3 days')$q$, '42501', '1.05 param_change_request c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_change_request SET updated_by = 't91-x' WHERE id = pg_temp.id('param_change_request') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.05 param_change_request d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_change_request WHERE id = pg_temp.id('param_change_request')$q$, '42501', '1.05 param_change_request e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_change_request WHERE id = pg_temp.id('param_change_request') AND updated_by = 'kiem-thu'$q$, '1.05 param_change_request f T90 vẫn thấy đúng một dòng, không bị sửa');
-- param_value (EN-18-03)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_value (id, tenant_id, created_by, updated_by, definition_id, param_key, value, scope) VALUES (pg_temp.id('param_value'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('param_definition'), 't90test.batch-max', '300'::jsonb, 'TENANT')$q$, '1.06 param_value a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.param_value WHERE id = pg_temp.id('param_value')$q$, '1.06 param_value b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, created_by, updated_by, definition_id, param_key, value, scope) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('param_definition'), 't90test.batch-max', '300'::jsonb, 'TENANT')$q$, '42501', '1.06 param_value c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_value SET updated_by = 't91-x' WHERE id = pg_temp.id('param_value') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.06 param_value d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_value WHERE id = pg_temp.id('param_value')$q$, '42501', '1.06 param_value e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_value WHERE id = pg_temp.id('param_value') AND updated_by = 'kiem-thu'$q$, '1.06 param_value f T90 vẫn thấy đúng một dòng, không bị sửa');
-- param_value_version (EN-18-04)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_value_version (id, tenant_id, created_by, updated_by, definition_id, param_key, version_no, value, status) VALUES (pg_temp.id('param_value_version'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('param_definition'), 't90test.batch-max', 1, '300'::jsonb, 'ACTIVE')$q$, '1.07 param_value_version a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.param_value_version WHERE id = pg_temp.id('param_value_version')$q$, '1.07 param_value_version b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value_version (id, tenant_id, created_by, updated_by, definition_id, param_key, version_no, value, status) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('param_definition'), 't90test.batch-max', 1, '300'::jsonb, 'ACTIVE')$q$, '42501', '1.07 param_value_version c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_value_version SET updated_by = 't91-x' WHERE id = pg_temp.id('param_value_version') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.07 param_value_version d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_value_version WHERE id = pg_temp.id('param_value_version')$q$, '42501', '1.07 param_value_version e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_value_version WHERE id = pg_temp.id('param_value_version') AND updated_by = 'kiem-thu'$q$, '1.07 param_value_version f T90 vẫn thấy đúng một dòng, không bị sửa');
-- feature_flag (EN-18-06)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.feature_flag (id, tenant_id, created_by, updated_by, flag_key, owner_ph, owner_user, description, retire_by) VALUES (pg_temp.id('feature_flag'), 'T90', 'kiem-thu', 'kiem-thu', 'ff.ops.replay-batch', 'PH-18', 'po-binh', 'Bật phát lại loạt', current_date + 180)$q$, '1.08 feature_flag a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.feature_flag WHERE id = pg_temp.id('feature_flag')$q$, '1.08 feature_flag b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.feature_flag (id, tenant_id, created_by, updated_by, flag_key, owner_ph, owner_user, description, retire_by) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ff.ops.replay-batch', 'PH-18', 'po-binh', 'Bật phát lại loạt', current_date + 180)$q$, '42501', '1.08 feature_flag c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.feature_flag SET updated_by = 't91-x' WHERE id = pg_temp.id('feature_flag') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.08 feature_flag d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.feature_flag WHERE id = pg_temp.id('feature_flag')$q$, '42501', '1.08 feature_flag e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.feature_flag WHERE id = pg_temp.id('feature_flag') AND updated_by = 'kiem-thu'$q$, '1.08 feature_flag f T90 vẫn thấy đúng một dòng, không bị sửa');
-- egress_allowlist_entry (EN-18-07)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.egress_allowlist_entry (id, tenant_id, created_by, updated_by, host, used_by, purpose, reason) VALUES (pg_temp.id('egress_allowlist_entry'), 'T90', 'kiem-thu', 'kiem-thu', 'git.t90.gov.vn', 'PH-15', 'GIT_REPO', 'Kho Git của backend thử')$q$, '1.09 egress_allowlist_entry a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.egress_allowlist_entry WHERE id = pg_temp.id('egress_allowlist_entry')$q$, '1.09 egress_allowlist_entry b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.egress_allowlist_entry (id, tenant_id, created_by, updated_by, host, used_by, purpose, reason) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'git.t90.gov.vn', 'PH-15', 'GIT_REPO', 'Kho Git của backend thử')$q$, '42501', '1.09 egress_allowlist_entry c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.egress_allowlist_entry SET updated_by = 't91-x' WHERE id = pg_temp.id('egress_allowlist_entry') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.09 egress_allowlist_entry d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.egress_allowlist_entry WHERE id = pg_temp.id('egress_allowlist_entry')$q$, '42501', '1.09 egress_allowlist_entry e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.egress_allowlist_entry WHERE id = pg_temp.id('egress_allowlist_entry') AND updated_by = 'kiem-thu'$q$, '1.09 egress_allowlist_entry f T90 vẫn thấy đúng một dòng, không bị sửa');
-- param_bundle (EN-18-08)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_bundle (id, tenant_id, created_by, updated_by, bundle_code, direction, source_env, namespaces) VALUES (pg_temp.id('param_bundle'), 'T90', 'kiem-thu', 'kiem-thu', 'BUNDLE-T90-001', 'EXPORT', 'STAGING', '{18,04}')$q$, '1.10 param_bundle a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.param_bundle WHERE id = pg_temp.id('param_bundle')$q$, '1.10 param_bundle b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_bundle (id, tenant_id, created_by, updated_by, bundle_code, direction, source_env, namespaces) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'BUNDLE-T90-001', 'EXPORT', 'STAGING', '{18,04}')$q$, '42501', '1.10 param_bundle c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_bundle SET updated_by = 't91-x' WHERE id = pg_temp.id('param_bundle') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.10 param_bundle d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_bundle WHERE id = pg_temp.id('param_bundle')$q$, '42501', '1.10 param_bundle e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.param_bundle WHERE id = pg_temp.id('param_bundle') AND updated_by = 'kiem-thu'$q$, '1.10 param_bundle f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_source (EN-18-18)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_source (id, tenant_id, created_by, updated_by, source_code, source_module, ingest_channel, replay_mode) VALUES (pg_temp.id('dlq_source'), 'T90', 'kiem-thu', 'kiem-thu', 'ph04-runtime', 'PH-04', 'KAFKA', 'KAFKA_TOPIC')$q$, '1.11 dlq_source a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_source WHERE id = pg_temp.id('dlq_source')$q$, '1.11 dlq_source b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_source (id, tenant_id, created_by, updated_by, source_code, source_module, ingest_channel, replay_mode) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ph04-runtime', 'PH-04', 'KAFKA', 'KAFKA_TOPIC')$q$, '42501', '1.11 dlq_source c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dlq_source SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_source') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.11 dlq_source d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_source WHERE id = pg_temp.id('dlq_source')$q$, '42501', '1.11 dlq_source e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_source WHERE id = pg_temp.id('dlq_source') AND updated_by = 'kiem-thu'$q$, '1.11 dlq_source f T90 vẫn thấy đúng một dòng, không bị sửa');
-- error_guide (EN-18-15)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.error_guide (id, tenant_id, created_by, updated_by, error_code, title, owner_ph, causes, steps, replayable) VALUES (pg_temp.id('error_guide'), 'T90', 'kiem-thu', 'kiem-thu', 'ERR-04-101', 'Bản tin sai lược đồ', 'PH-04', '{Nguồn đổi lược đồ}', '{Sửa payload rồi phát lại}', 'AFTER_FIX')$q$, '1.12 error_guide a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.error_guide WHERE id = pg_temp.id('error_guide')$q$, '1.12 error_guide b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.error_guide (id, tenant_id, created_by, updated_by, error_code, title, owner_ph, causes, steps, replayable) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ERR-04-101', 'Bản tin sai lược đồ', 'PH-04', '{Nguồn đổi lược đồ}', '{Sửa payload rồi phát lại}', 'AFTER_FIX')$q$, '42501', '1.12 error_guide c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.error_guide SET updated_by = 't91-x' WHERE id = pg_temp.id('error_guide') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.12 error_guide d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.error_guide WHERE id = pg_temp.id('error_guide')$q$, '42501', '1.12 error_guide e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.error_guide WHERE id = pg_temp.id('error_guide') AND updated_by = 'kiem-thu'$q$, '1.12 error_guide f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_group (EN-18-13)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_group (id, tenant_id, created_by, updated_by, signature, source_code, error_class, sample_message) VALUES (pg_temp.id('dlq_group'), 'T90', 'kiem-thu', 'kiem-thu', repeat('a', 64), 'ph04-runtime', 'CONTRACT', 'Bản tin sai lược đồ')$q$, '1.13 dlq_group a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_group WHERE id = pg_temp.id('dlq_group')$q$, '1.13 dlq_group b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_group (id, tenant_id, created_by, updated_by, signature, source_code, error_class, sample_message) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', repeat('a', 64), 'ph04-runtime', 'CONTRACT', 'Bản tin sai lược đồ')$q$, '42501', '1.13 dlq_group c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dlq_group SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_group') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.13 dlq_group d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_group WHERE id = pg_temp.id('dlq_group')$q$, '42501', '1.13 dlq_group e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_group WHERE id = pg_temp.id('dlq_group') AND updated_by = 'kiem-thu'$q$, '1.13 dlq_group f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_message (EN-18-09)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, created_by, updated_by, dlq_key, source_code, source_module, reason_code, received_at, payload_location, payload_inline, payload_size_bytes) VALUES (pg_temp.id('dlq_message'), 'T90', 'kiem-thu', 'kiem-thu', 'dlq-key-0001', 'ph04-runtime', 'PH-04', 'SCHEMA_INVALID', pg_temp.ts(), 'INLINE', '{"maHoSo": "HS-0001"}'::jsonb, 30)$q$, '1.14 dlq_message a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message')$q$, '1.14 dlq_message b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, created_by, updated_by, dlq_key, source_code, source_module, reason_code, received_at, payload_location, payload_inline, payload_size_bytes) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'dlq-key-0001', 'ph04-runtime', 'PH-04', 'SCHEMA_INVALID', pg_temp.ts(), 'INLINE', '{"maHoSo": "HS-0001"}'::jsonb, 30)$q$, '42501', '1.14 dlq_message c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dlq_message SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_message') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.14 dlq_message d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.14 dlq_message e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message') AND updated_by = 'kiem-thu'$q$, '1.14 dlq_message f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_payload_ref (EN-18-10)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_payload_ref (id, tenant_id, created_by, updated_by, dlq_id, dlq_received_at, kind, bucket, object_key, size_bytes, sha256, content_type) VALUES (pg_temp.id('dlq_payload_ref'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), pg_temp.ts(), 'ORIGINAL', 'dh-t90-ops', 'dlq/2026/11/0001.bin', 300000, repeat('b', 64), 'application/json')$q$, '1.15 dlq_payload_ref a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_payload_ref WHERE id = pg_temp.id('dlq_payload_ref')$q$, '1.15 dlq_payload_ref b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_payload_ref (id, tenant_id, created_by, updated_by, dlq_id, dlq_received_at, kind, bucket, object_key, size_bytes, sha256, content_type) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), pg_temp.ts(), 'ORIGINAL', 'dh-t90-ops', 'dlq/2026/11/0001.bin', 300000, repeat('b', 64), 'application/json')$q$, '42501', '1.15 dlq_payload_ref c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dlq_payload_ref SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_payload_ref') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.15 dlq_payload_ref d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_payload_ref WHERE id = pg_temp.id('dlq_payload_ref')$q$, '42501', '1.15 dlq_payload_ref e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_payload_ref WHERE id = pg_temp.id('dlq_payload_ref') AND updated_by = 'kiem-thu'$q$, '1.15 dlq_payload_ref f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_revision (EN-18-11)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_revision (id, tenant_id, created_by, updated_by, dlq_id, dlq_received_at, revision_no, payload_location, payload, payload_sha256, diff, reason) VALUES (pg_temp.id('dlq_revision'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), pg_temp.ts(), 1, 'INLINE', '{"maHoSo": "HS-0001A"}'::jsonb, repeat('c', 64), '[{"op": "replace", "path": "/maHoSo", "value": "HS-0001A"}]'::jsonb, 'Sửa mã hồ sơ sai định dạng')$q$, '1.16 dlq_revision a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_revision WHERE id = pg_temp.id('dlq_revision')$q$, '1.16 dlq_revision b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_revision (id, tenant_id, created_by, updated_by, dlq_id, dlq_received_at, revision_no, payload_location, payload, payload_sha256, diff, reason) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), pg_temp.ts(), 1, 'INLINE', '{"maHoSo": "HS-0001A"}'::jsonb, repeat('c', 64), '[{"op": "replace", "path": "/maHoSo", "value": "HS-0001A"}]'::jsonb, 'Sửa mã hồ sơ sai định dạng')$q$, '42501', '1.16 dlq_revision c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dlq_revision SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_revision') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.16 dlq_revision d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_revision WHERE id = pg_temp.id('dlq_revision')$q$, '42501', '1.16 dlq_revision e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_revision WHERE id = pg_temp.id('dlq_revision') AND updated_by = 'kiem-thu'$q$, '1.16 dlq_revision f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_assignment (EN-18-14)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_assignment (id, tenant_id, created_by, updated_by, dlq_id, dlq_received_at, assignee, assigned_by) VALUES (pg_temp.id('dlq_assignment'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), pg_temp.ts(), 'to-an', 'to-binh')$q$, '1.17 dlq_assignment a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_assignment WHERE id = pg_temp.id('dlq_assignment')$q$, '1.17 dlq_assignment b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_assignment (id, tenant_id, created_by, updated_by, dlq_id, dlq_received_at, assignee, assigned_by) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), pg_temp.ts(), 'to-an', 'to-binh')$q$, '42501', '1.17 dlq_assignment c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dlq_assignment SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_assignment') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.17 dlq_assignment d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_assignment WHERE id = pg_temp.id('dlq_assignment')$q$, '42501', '1.17 dlq_assignment e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_assignment WHERE id = pg_temp.id('dlq_assignment') AND updated_by = 'kiem-thu'$q$, '1.17 dlq_assignment f T90 vẫn thấy đúng một dòng, không bị sửa');
-- replay_job (EN-18-16)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, created_by, updated_by, mode, reason, total_items) VALUES (pg_temp.id('replay_job'), 'T90', 'kiem-thu', 'kiem-thu', 'SINGLE', 'Phát lại sau khi nguồn sửa lược đồ', 1)$q$, '1.18 replay_job a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.replay_job WHERE id = pg_temp.id('replay_job')$q$, '1.18 replay_job b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, created_by, updated_by, mode, reason, total_items) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'SINGLE', 'Phát lại sau khi nguồn sửa lược đồ', 1)$q$, '42501', '1.18 replay_job c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.replay_job SET updated_by = 't91-x' WHERE id = pg_temp.id('replay_job') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.18 replay_job d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.replay_job WHERE id = pg_temp.id('replay_job')$q$, '42501', '1.18 replay_job e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.replay_job WHERE id = pg_temp.id('replay_job') AND updated_by = 'kiem-thu'$q$, '1.18 replay_job f T90 vẫn thấy đúng một dòng, không bị sửa');
-- replay_item (EN-18-17)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.replay_item (id, tenant_id, created_by, updated_by, job_id, dlq_id, dlq_received_at, idempotency_key) VALUES (pg_temp.id('replay_item'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('replay_job'), pg_temp.id('dlq_message'), pg_temp.ts(), pg_temp.id('dlq_message')::text || ':0')$q$, '1.19 replay_item a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.replay_item WHERE id = pg_temp.id('replay_item')$q$, '1.19 replay_item b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_item (id, tenant_id, created_by, updated_by, job_id, dlq_id, dlq_received_at, idempotency_key) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('replay_job'), pg_temp.id('dlq_message'), pg_temp.ts(), pg_temp.id('dlq_message')::text || ':0')$q$, '42501', '1.19 replay_item c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.replay_item SET updated_by = 't91-x' WHERE id = pg_temp.id('replay_item') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.19 replay_item d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.replay_item WHERE id = pg_temp.id('replay_item')$q$, '42501', '1.19 replay_item e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.replay_item WHERE id = pg_temp.id('replay_item') AND updated_by = 'kiem-thu'$q$, '1.19 replay_item f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dlq_audit (EN-18-12)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dlq_audit (id, tenant_id, created_by, updated_by, dlq_id, action, actor, reason, occurred_at) VALUES (pg_temp.id('dlq_audit'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), 'VIEW_PAYLOAD', 'to-an', 'Xem để chẩn đoán lỗi lược đồ', pg_temp.ts())$q$, '1.20 dlq_audit a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dlq_audit WHERE id = pg_temp.id('dlq_audit')$q$, '1.20 dlq_audit b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_audit (id, tenant_id, created_by, updated_by, dlq_id, action, actor, reason, occurred_at) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('dlq_message'), 'VIEW_PAYLOAD', 'to-an', 'Xem để chẩn đoán lỗi lược đồ', pg_temp.ts())$q$, '42501', '1.20 dlq_audit c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_audit SET updated_by = 't91-x' WHERE id = pg_temp.id('dlq_audit')$q$, '42501', '1.20 dlq_audit d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_audit WHERE id = pg_temp.id('dlq_audit')$q$, '42501', '1.20 dlq_audit e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_audit WHERE id = pg_temp.id('dlq_audit') AND updated_by = 'kiem-thu'$q$, '1.20 dlq_audit f T90 vẫn thấy đúng một dòng, không bị sửa');
-- notification_template (EN-18-19)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_template (id, tenant_id, created_by, updated_by, template_code, owner_module, title, category, channels) VALUES (pg_temp.id('notification_template'), 'T90', 'kiem-thu', 'kiem-thu', 'ph01.review-decided', 'PH-01', 'Kết quả thẩm định', 'INFO', '{EMAIL,IN_APP}')$q$, '1.21 notification_template a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.notification_template WHERE id = pg_temp.id('notification_template')$q$, '1.21 notification_template b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_template (id, tenant_id, created_by, updated_by, template_code, owner_module, title, category, channels) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ph01.review-decided', 'PH-01', 'Kết quả thẩm định', 'INFO', '{EMAIL,IN_APP}')$q$, '42501', '1.21 notification_template c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.notification_template SET updated_by = 't91-x' WHERE id = pg_temp.id('notification_template') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.21 notification_template d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.notification_template WHERE id = pg_temp.id('notification_template')$q$, '42501', '1.21 notification_template e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_template WHERE id = pg_temp.id('notification_template') AND updated_by = 'kiem-thu'$q$, '1.21 notification_template f T90 vẫn thấy đúng một dòng, không bị sửa');
-- notification_template_version (EN-18-20)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_template_version (id, tenant_id, created_by, updated_by, template_id, version_no, body_text, allowed_fields) VALUES (pg_temp.id('notification_template_version'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('notification_template'), 1, 'Hồ sơ {{maHoSo}} đã có kết quả thẩm định.', '{maHoSo}')$q$, '1.22 notification_template_version a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.notification_template_version WHERE id = pg_temp.id('notification_template_version')$q$, '1.22 notification_template_version b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_template_version (id, tenant_id, created_by, updated_by, template_id, version_no, body_text, allowed_fields) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('notification_template'), 1, 'Hồ sơ {{maHoSo}} đã có kết quả thẩm định.', '{maHoSo}')$q$, '42501', '1.22 notification_template_version c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.notification_template_version SET updated_by = 't91-x' WHERE id = pg_temp.id('notification_template_version') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.22 notification_template_version d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.notification_template_version WHERE id = pg_temp.id('notification_template_version')$q$, '42501', '1.22 notification_template_version e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_template_version WHERE id = pg_temp.id('notification_template_version') AND updated_by = 'kiem-thu'$q$, '1.22 notification_template_version f T90 vẫn thấy đúng một dòng, không bị sửa');
-- notification_rule (EN-18-21)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_rule (id, tenant_id, created_by, updated_by, rule_code, source_module, event_type, template_code, recipient_kind, recipient_expr, channels) VALUES (pg_temp.id('notification_rule'), 'T90', 'kiem-thu', 'kiem-thu', 'ph01-review-decided', 'PH-01', 'onboarding.review.decided.v1', 'ph01.review-decided', 'EVENT_FIELD', 'submittedBy', '{IN_APP}')$q$, '1.23 notification_rule a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.notification_rule WHERE id = pg_temp.id('notification_rule')$q$, '1.23 notification_rule b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_rule (id, tenant_id, created_by, updated_by, rule_code, source_module, event_type, template_code, recipient_kind, recipient_expr, channels) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ph01-review-decided', 'PH-01', 'onboarding.review.decided.v1', 'ph01.review-decided', 'EVENT_FIELD', 'submittedBy', '{IN_APP}')$q$, '42501', '1.23 notification_rule c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.notification_rule SET updated_by = 't91-x' WHERE id = pg_temp.id('notification_rule') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.23 notification_rule d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.notification_rule WHERE id = pg_temp.id('notification_rule')$q$, '42501', '1.23 notification_rule e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_rule WHERE id = pg_temp.id('notification_rule') AND updated_by = 'kiem-thu'$q$, '1.23 notification_rule f T90 vẫn thấy đúng một dòng, không bị sửa');
-- notification_message (EN-18-22)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, created_by, updated_by, caller_module, message_key, template_code, recipient_ref, category, channels) VALUES (pg_temp.id('notification_message'), 'T90', 'kiem-thu', 'kiem-thu', 'PH-01', 'msg-0001', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-0001"}]'::jsonb, 'INFO', '{IN_APP}')$q$, '1.24 notification_message a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.notification_message WHERE id = pg_temp.id('notification_message')$q$, '1.24 notification_message b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, created_by, updated_by, caller_module, message_key, template_code, recipient_ref, category, channels) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'PH-01', 'msg-0001', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-0001"}]'::jsonb, 'INFO', '{IN_APP}')$q$, '42501', '1.24 notification_message c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.notification_message SET updated_by = 't91-x' WHERE id = pg_temp.id('notification_message') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.24 notification_message d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.notification_message WHERE id = pg_temp.id('notification_message') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.24 notification_message e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_message WHERE id = pg_temp.id('notification_message') AND updated_by = 'kiem-thu'$q$, '1.24 notification_message f T90 vẫn thấy đúng một dòng, không bị sửa');
-- notification_delivery (EN-18-23)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_delivery (id, tenant_id, created_by, updated_by, message_id, channel, recipient_user_id, queued_at) VALUES (pg_temp.id('notification_delivery'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('notification_message'), 'IN_APP', 'u-0001', pg_temp.ts())$q$, '1.25 notification_delivery a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.notification_delivery WHERE id = pg_temp.id('notification_delivery')$q$, '1.25 notification_delivery b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_delivery (id, tenant_id, created_by, updated_by, message_id, channel, recipient_user_id, queued_at) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('notification_message'), 'IN_APP', 'u-0001', pg_temp.ts())$q$, '42501', '1.25 notification_delivery c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.notification_delivery SET updated_by = 't91-x' WHERE id = pg_temp.id('notification_delivery') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.25 notification_delivery d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.notification_delivery WHERE id = pg_temp.id('notification_delivery')$q$, '42501', '1.25 notification_delivery e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_delivery WHERE id = pg_temp.id('notification_delivery') AND updated_by = 'kiem-thu'$q$, '1.25 notification_delivery f T90 vẫn thấy đúng một dòng, không bị sửa');
-- user_notification_pref (EN-18-24)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.user_notification_pref (id, tenant_id, created_by, updated_by, user_id, category, channel) VALUES (pg_temp.id('user_notification_pref'), 'T90', 'kiem-thu', 'kiem-thu', 'u-0001', 'INFO', 'EMAIL')$q$, '1.26 user_notification_pref a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.user_notification_pref WHERE id = pg_temp.id('user_notification_pref')$q$, '1.26 user_notification_pref b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.user_notification_pref (id, tenant_id, created_by, updated_by, user_id, category, channel) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'u-0001', 'INFO', 'EMAIL')$q$, '42501', '1.26 user_notification_pref c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.user_notification_pref SET updated_by = 't91-x' WHERE id = pg_temp.id('user_notification_pref') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.26 user_notification_pref d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.user_notification_pref WHERE id = pg_temp.id('user_notification_pref') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.26 user_notification_pref e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.user_notification_pref WHERE id = pg_temp.id('user_notification_pref') AND updated_by = 'kiem-thu'$q$, '1.26 user_notification_pref f T90 vẫn thấy đúng một dòng, không bị sửa');
-- suppression_entry (EN-18-25)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.suppression_entry (id, tenant_id, created_by, updated_by, channel, address_hash, address_masked, reason) VALUES (pg_temp.id('suppression_entry'), 'T90', 'kiem-thu', 'kiem-thu', 'EMAIL', repeat('d', 64), 'a***@t90.gov.vn', 'HARD_BOUNCE')$q$, '1.27 suppression_entry a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.suppression_entry WHERE id = pg_temp.id('suppression_entry')$q$, '1.27 suppression_entry b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.suppression_entry (id, tenant_id, created_by, updated_by, channel, address_hash, address_masked, reason) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'EMAIL', repeat('d', 64), 'a***@t90.gov.vn', 'HARD_BOUNCE')$q$, '42501', '1.27 suppression_entry c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.suppression_entry SET updated_by = 't91-x' WHERE id = pg_temp.id('suppression_entry') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.27 suppression_entry d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.suppression_entry WHERE id = pg_temp.id('suppression_entry')$q$, '42501', '1.27 suppression_entry e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.suppression_entry WHERE id = pg_temp.id('suppression_entry') AND updated_by = 'kiem-thu'$q$, '1.27 suppression_entry f T90 vẫn thấy đúng một dòng, không bị sửa');
-- task_type (EN-18-26)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.task_type (id, tenant_id, created_by, updated_by, type_code, owner_module, title, required_permission, deep_link_pattern) VALUES (pg_temp.id('task_type'), 'T90', 'kiem-thu', 'kiem-thu', 'ph01.approve-onboarding', 'PH-01', 'Duyệt kết nạp HTTT', 'PERM-01-approve', '/ket-nap/ho-so/{ma}')$q$, '1.28 task_type a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.task_type WHERE id = pg_temp.id('task_type')$q$, '1.28 task_type b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_type (id, tenant_id, created_by, updated_by, type_code, owner_module, title, required_permission, deep_link_pattern) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ph01.approve-onboarding', 'PH-01', 'Duyệt kết nạp HTTT', 'PERM-01-approve', '/ket-nap/ho-so/{ma}')$q$, '42501', '1.28 task_type c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.task_type SET updated_by = 't91-x' WHERE id = pg_temp.id('task_type') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.28 task_type d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.task_type WHERE id = pg_temp.id('task_type')$q$, '42501', '1.28 task_type e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.task_type WHERE id = pg_temp.id('task_type') AND updated_by = 'kiem-thu'$q$, '1.28 task_type f T90 vẫn thấy đúng một dòng, không bị sửa');
-- task_item (EN-18-27)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.task_item (id, tenant_id, created_by, updated_by, type_id, type_code, task_key, title, subject_ref, assignee_kind, assignee_ref, required_permission) VALUES (pg_temp.id('task_item'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('task_type'), 'ph01.approve-onboarding', 'HS-0001', 'Duyệt hồ sơ kết nạp HS-0001', 'HS-0001', 'ROLE', 'TA', 'PERM-01-approve')$q$, '1.29 task_item a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.task_item WHERE id = pg_temp.id('task_item')$q$, '1.29 task_item b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_item (id, tenant_id, created_by, updated_by, type_id, type_code, task_key, title, subject_ref, assignee_kind, assignee_ref, required_permission) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('task_type'), 'ph01.approve-onboarding', 'HS-0001', 'Duyệt hồ sơ kết nạp HS-0001', 'HS-0001', 'ROLE', 'TA', 'PERM-01-approve')$q$, '42501', '1.29 task_item c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.task_item SET updated_by = 't91-x' WHERE id = pg_temp.id('task_item') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.29 task_item d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.task_item WHERE id = pg_temp.id('task_item')$q$, '42501', '1.29 task_item e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.task_item WHERE id = pg_temp.id('task_item') AND updated_by = 'kiem-thu'$q$, '1.29 task_item f T90 vẫn thấy đúng một dòng, không bị sửa');
-- task_reminder (EN-18-28)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.task_reminder (id, tenant_id, created_by, updated_by, task_id, kind, remind_at) VALUES (pg_temp.id('task_reminder'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('task_item'), 'BEFORE_DUE', now() + interval '1 day')$q$, '1.30 task_reminder a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.task_reminder WHERE id = pg_temp.id('task_reminder')$q$, '1.30 task_reminder b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_reminder (id, tenant_id, created_by, updated_by, task_id, kind, remind_at) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('task_item'), 'BEFORE_DUE', now() + interval '1 day')$q$, '42501', '1.30 task_reminder c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.task_reminder SET updated_by = 't91-x' WHERE id = pg_temp.id('task_reminder') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.30 task_reminder d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.task_reminder WHERE id = pg_temp.id('task_reminder') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.30 task_reminder e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.task_reminder WHERE id = pg_temp.id('task_reminder') AND updated_by = 'kiem-thu'$q$, '1.30 task_reminder f T90 vẫn thấy đúng một dòng, không bị sửa');
-- work_calendar (EN-18-29)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.work_calendar (id, tenant_id, created_by, updated_by, name) VALUES (pg_temp.id('work_calendar'), 'T90', 'kiem-thu', 'kiem-thu', 'Lịch làm việc T90')$q$, '1.31 work_calendar a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.work_calendar WHERE id = pg_temp.id('work_calendar')$q$, '1.31 work_calendar b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.work_calendar (id, tenant_id, created_by, updated_by, name) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'Lịch làm việc T90')$q$, '42501', '1.31 work_calendar c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.work_calendar SET updated_by = 't91-x' WHERE id = pg_temp.id('work_calendar') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.31 work_calendar d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.work_calendar WHERE id = pg_temp.id('work_calendar')$q$, '42501', '1.31 work_calendar e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.work_calendar WHERE id = pg_temp.id('work_calendar') AND updated_by = 'kiem-thu'$q$, '1.31 work_calendar f T90 vẫn thấy đúng một dòng, không bị sửa');
-- calendar_holiday (EN-18-30)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.calendar_holiday (id, tenant_id, created_by, updated_by, calendar_id, holiday_date, name) VALUES (pg_temp.id('calendar_holiday'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('work_calendar'), date '2026-09-02', 'Quốc khánh')$q$, '1.32 calendar_holiday a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.calendar_holiday WHERE id = pg_temp.id('calendar_holiday')$q$, '1.32 calendar_holiday b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.calendar_holiday (id, tenant_id, created_by, updated_by, calendar_id, holiday_date, name) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('work_calendar'), date '2026-09-02', 'Quốc khánh')$q$, '42501', '1.32 calendar_holiday c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.calendar_holiday SET updated_by = 't91-x' WHERE id = pg_temp.id('calendar_holiday') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.32 calendar_holiday d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.calendar_holiday WHERE id = pg_temp.id('calendar_holiday') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.32 calendar_holiday e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.calendar_holiday WHERE id = pg_temp.id('calendar_holiday') AND updated_by = 'kiem-thu'$q$, '1.32 calendar_holiday f T90 vẫn thấy đúng một dòng, không bị sửa');
-- maintenance_window (EN-18-31)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.maintenance_window (id, tenant_id, created_by, updated_by, window_code, kind, starts_at, ends_at, reason) VALUES (pg_temp.id('maintenance_window'), 'T90', 'kiem-thu', 'kiem-thu', 'FRZ-T90-2026-12', 'FREEZE', now() + interval '1 day', now() + interval '2 days', 'Đóng băng cuối năm trước kỳ báo cáo')$q$, '1.33 maintenance_window a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.maintenance_window WHERE id = pg_temp.id('maintenance_window')$q$, '1.33 maintenance_window b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.maintenance_window (id, tenant_id, created_by, updated_by, window_code, kind, starts_at, ends_at, reason) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'FRZ-T90-2026-12', 'FREEZE', now() + interval '1 day', now() + interval '2 days', 'Đóng băng cuối năm trước kỳ báo cáo')$q$, '42501', '1.33 maintenance_window c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.maintenance_window SET updated_by = 't91-x' WHERE id = pg_temp.id('maintenance_window') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.33 maintenance_window d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.maintenance_window WHERE id = pg_temp.id('maintenance_window')$q$, '42501', '1.33 maintenance_window e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.maintenance_window WHERE id = pg_temp.id('maintenance_window') AND updated_by = 'kiem-thu'$q$, '1.33 maintenance_window f T90 vẫn thấy đúng một dòng, không bị sửa');
-- incident (EN-18-32)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.incident (id, tenant_id, created_by, updated_by, incident_no, title, severity, category, origin) VALUES (pg_temp.id('incident'), 'T90', 'kiem-thu', 'kiem-thu', 'INC-2026-000001', 'DLQ luồng hồ sơ vượt ngưỡng', 'SEV3', 'AVAILABILITY', 'MANUAL')$q$, '1.34 incident a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.incident WHERE id = pg_temp.id('incident')$q$, '1.34 incident b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.incident (id, tenant_id, created_by, updated_by, incident_no, title, severity, category, origin) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'INC-2026-000001', 'DLQ luồng hồ sơ vượt ngưỡng', 'SEV3', 'AVAILABILITY', 'MANUAL')$q$, '42501', '1.34 incident c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.incident SET updated_by = 't91-x' WHERE id = pg_temp.id('incident') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.34 incident d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.incident WHERE id = pg_temp.id('incident')$q$, '42501', '1.34 incident e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.incident WHERE id = pg_temp.id('incident') AND updated_by = 'kiem-thu'$q$, '1.34 incident f T90 vẫn thấy đúng một dòng, không bị sửa');
-- incident_timeline (EN-18-33)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.incident_timeline (id, tenant_id, created_by, updated_by, incident_id, entry_kind, actor, note) VALUES (pg_temp.id('incident_timeline'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('incident'), 'NOTE', 'po-binh', 'Đã liên hệ chủ luồng')$q$, '1.35 incident_timeline a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.incident_timeline WHERE id = pg_temp.id('incident_timeline')$q$, '1.35 incident_timeline b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.incident_timeline (id, tenant_id, created_by, updated_by, incident_id, entry_kind, actor, note) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('incident'), 'NOTE', 'po-binh', 'Đã liên hệ chủ luồng')$q$, '42501', '1.35 incident_timeline c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident_timeline SET updated_by = 't91-x' WHERE id = pg_temp.id('incident_timeline')$q$, '42501', '1.35 incident_timeline d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.incident_timeline WHERE id = pg_temp.id('incident_timeline')$q$, '42501', '1.35 incident_timeline e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.incident_timeline WHERE id = pg_temp.id('incident_timeline') AND updated_by = 'kiem-thu'$q$, '1.35 incident_timeline f T90 vẫn thấy đúng một dòng, không bị sửa');
-- incident_link (EN-18-34)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.incident_link (id, tenant_id, created_by, updated_by, incident_id, link_kind, target_module, target_ref) VALUES (pg_temp.id('incident_link'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('incident'), 'DLQ_GROUP', 'PH-18', 'grp-0001')$q$, '1.36 incident_link a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.incident_link WHERE id = pg_temp.id('incident_link')$q$, '1.36 incident_link b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.incident_link (id, tenant_id, created_by, updated_by, incident_id, link_kind, target_module, target_ref) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('incident'), 'DLQ_GROUP', 'PH-18', 'grp-0001')$q$, '42501', '1.36 incident_link c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.incident_link SET updated_by = 't91-x' WHERE id = pg_temp.id('incident_link') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.36 incident_link d T91 sửa không được dòng nào');
SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM ph18_ops.incident_link WHERE id = pg_temp.id('incident_link') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '1.36 incident_link e T91 xóa không được dòng nào');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.incident_link WHERE id = pg_temp.id('incident_link') AND updated_by = 'kiem-thu'$q$, '1.36 incident_link f T90 vẫn thấy đúng một dòng, không bị sửa');
-- backup_object (EN-18-35)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.backup_object (id, tenant_id, created_by, updated_by, object_code, name, object_kind, tool, schedule, retention_days, target_location) VALUES (pg_temp.id('backup_object'), 'T90', 'kiem-thu', 'kiem-thu', 't90-tenant-export', 'Xuất logic tenant T90', 'TENANT_EXPORT', 'DH_TENANT_EXPORT', '0 2 * * *', 35, 'kho-sao-luu-bat-bien/t90')$q$, '1.37 backup_object a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.backup_object WHERE id = pg_temp.id('backup_object')$q$, '1.37 backup_object b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.backup_object (id, tenant_id, created_by, updated_by, object_code, name, object_kind, tool, schedule, retention_days, target_location) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 't90-tenant-export', 'Xuất logic tenant T90', 'TENANT_EXPORT', 'DH_TENANT_EXPORT', '0 2 * * *', 35, 'kho-sao-luu-bat-bien/t90')$q$, '42501', '1.37 backup_object c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.backup_object SET updated_by = 't91-x' WHERE id = pg_temp.id('backup_object') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.37 backup_object d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.backup_object WHERE id = pg_temp.id('backup_object')$q$, '42501', '1.37 backup_object e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.backup_object WHERE id = pg_temp.id('backup_object') AND updated_by = 'kiem-thu'$q$, '1.37 backup_object f T90 vẫn thấy đúng một dòng, không bị sửa');
-- backup_run (EN-18-36)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.backup_run (id, tenant_id, created_by, updated_by, object_id, run_ref, started_at, finished_at, status, collector) VALUES (pg_temp.id('backup_run'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('backup_object'), 't90-export-20261127', now() - interval '1 hour', now(), 'SUCCEEDED', 'DH_TENANT_EXPORT')$q$, '1.38 backup_run a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.backup_run WHERE id = pg_temp.id('backup_run')$q$, '1.38 backup_run b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.backup_run (id, tenant_id, created_by, updated_by, object_id, run_ref, started_at, finished_at, status, collector) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('backup_object'), 't90-export-20261127', now() - interval '1 hour', now(), 'SUCCEEDED', 'DH_TENANT_EXPORT')$q$, '42501', '1.38 backup_run c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.backup_run SET updated_by = 't91-x' WHERE id = pg_temp.id('backup_run') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.38 backup_run d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.backup_run WHERE id = pg_temp.id('backup_run')$q$, '42501', '1.38 backup_run e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.backup_run WHERE id = pg_temp.id('backup_run') AND updated_by = 'kiem-thu'$q$, '1.38 backup_run f T90 vẫn thấy đúng một dòng, không bị sửa');
-- restore_verification (EN-18-37)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.restore_verification (id, tenant_id, created_by, updated_by, object_id, method, outcome, duration_seconds) VALUES (pg_temp.id('restore_verification'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('backup_object'), 'TENANT_IMPORT', 'PASSED', 1200)$q$, '1.39 restore_verification a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.restore_verification WHERE id = pg_temp.id('restore_verification')$q$, '1.39 restore_verification b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.restore_verification (id, tenant_id, created_by, updated_by, object_id, method, outcome, duration_seconds) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('backup_object'), 'TENANT_IMPORT', 'PASSED', 1200)$q$, '42501', '1.39 restore_verification c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.restore_verification SET updated_by = 't91-x' WHERE id = pg_temp.id('restore_verification')$q$, '42501', '1.39 restore_verification d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.restore_verification WHERE id = pg_temp.id('restore_verification')$q$, '42501', '1.39 restore_verification e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.restore_verification WHERE id = pg_temp.id('restore_verification') AND updated_by = 'kiem-thu'$q$, '1.39 restore_verification f T90 vẫn thấy đúng một dòng, không bị sửa');
-- tenant_restore_request (EN-18-38)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.tenant_restore_request (id, tenant_id, created_by, updated_by, request_no, restore_point, scope, reason, requested_by) VALUES (pg_temp.id('tenant_restore_request'), 'T90', 'kiem-thu', 'kiem-thu', 'RST-T90-0001', now() - interval '1 day', 'FULL_TENANT', 'Nhập nhầm danh mục và đã phát hành, cần đưa về hôm qua', 'ta-an')$q$, '1.40 tenant_restore_request a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.tenant_restore_request WHERE id = pg_temp.id('tenant_restore_request')$q$, '1.40 tenant_restore_request b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_request (id, tenant_id, created_by, updated_by, request_no, restore_point, scope, reason, requested_by) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'RST-T90-0001', now() - interval '1 day', 'FULL_TENANT', 'Nhập nhầm danh mục và đã phát hành, cần đưa về hôm qua', 'ta-an')$q$, '42501', '1.40 tenant_restore_request c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.tenant_restore_request SET updated_by = 't91-x' WHERE id = pg_temp.id('tenant_restore_request') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.40 tenant_restore_request d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.tenant_restore_request WHERE id = pg_temp.id('tenant_restore_request')$q$, '42501', '1.40 tenant_restore_request e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.tenant_restore_request WHERE id = pg_temp.id('tenant_restore_request') AND updated_by = 'kiem-thu'$q$, '1.40 tenant_restore_request f T90 vẫn thấy đúng một dòng, không bị sửa');
-- tenant_restore_step (EN-18-39)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.tenant_restore_step (id, tenant_id, created_by, updated_by, request_id, step_no, step_code) VALUES (pg_temp.id('tenant_restore_step'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('tenant_restore_request'), 1, 'APPROVAL')$q$, '1.41 tenant_restore_step a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.tenant_restore_step WHERE id = pg_temp.id('tenant_restore_step')$q$, '1.41 tenant_restore_step b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_step (id, tenant_id, created_by, updated_by, request_id, step_no, step_code) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('tenant_restore_request'), 1, 'APPROVAL')$q$, '42501', '1.41 tenant_restore_step c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.tenant_restore_step SET updated_by = 't91-x' WHERE id = pg_temp.id('tenant_restore_step') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.41 tenant_restore_step d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.tenant_restore_step WHERE id = pg_temp.id('tenant_restore_step')$q$, '42501', '1.41 tenant_restore_step e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.tenant_restore_step WHERE id = pg_temp.id('tenant_restore_step') AND updated_by = 'kiem-thu'$q$, '1.41 tenant_restore_step f T90 vẫn thấy đúng một dòng, không bị sửa');
-- tenant_export_job (EN-18-40)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.tenant_export_job (id, tenant_id, created_by, updated_by, purpose) VALUES (pg_temp.id('tenant_export_job'), 'T90', 'kiem-thu', 'kiem-thu', 'ARCHIVE')$q$, '1.42 tenant_export_job a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.tenant_export_job WHERE id = pg_temp.id('tenant_export_job')$q$, '1.42 tenant_export_job b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_export_job (id, tenant_id, created_by, updated_by, purpose) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'ARCHIVE')$q$, '42501', '1.42 tenant_export_job c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.tenant_export_job SET updated_by = 't91-x' WHERE id = pg_temp.id('tenant_export_job') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.42 tenant_export_job d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.tenant_export_job WHERE id = pg_temp.id('tenant_export_job')$q$, '42501', '1.42 tenant_export_job e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.tenant_export_job WHERE id = pg_temp.id('tenant_export_job') AND updated_by = 'kiem-thu'$q$, '1.42 tenant_export_job f T90 vẫn thấy đúng một dòng, không bị sửa');
-- dr_drill (EN-18-41)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.dr_drill (id, tenant_id, created_by, updated_by, drill_code, drill_kind, performed_at, performed_by, outcome) VALUES (pg_temp.id('dr_drill'), 'T90', 'kiem-thu', 'kiem-thu', 'DR-2026-Q4', 'RBK_03', now(), 'pa-an', 'PASSED')$q$, '1.43 dr_drill a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.dr_drill WHERE id = pg_temp.id('dr_drill')$q$, '1.43 dr_drill b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dr_drill (id, tenant_id, created_by, updated_by, drill_code, drill_kind, performed_at, performed_by, outcome) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'DR-2026-Q4', 'RBK_03', now(), 'pa-an', 'PASSED')$q$, '42501', '1.43 dr_drill c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.dr_drill SET updated_by = 't91-x' WHERE id = pg_temp.id('dr_drill') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.43 dr_drill d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dr_drill WHERE id = pg_temp.id('dr_drill')$q$, '42501', '1.43 dr_drill e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dr_drill WHERE id = pg_temp.id('dr_drill') AND updated_by = 'kiem-thu'$q$, '1.43 dr_drill f T90 vẫn thấy đúng một dòng, không bị sửa');
-- merge_transfer (EN-18-55)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, created_by, updated_by, merge_plan_id, module, source_tenant, target_tenant, mapping_ref) VALUES (pg_temp.id('merge_transfer'), 'T90', 'kiem-thu', 'kiem-thu', 'MP-2026-0001', 'PH-07', 'T91', 'T90', 'mp-2026-0001/ph07')$q$, '1.44 merge_transfer a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.merge_transfer WHERE id = pg_temp.id('merge_transfer')$q$, '1.44 merge_transfer b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, created_by, updated_by, merge_plan_id, module, source_tenant, target_tenant, mapping_ref) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'MP-2026-0001', 'PH-07', 'T91', 'T90', 'mp-2026-0001/ph07')$q$, '42501', '1.44 merge_transfer c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.merge_transfer SET updated_by = 't91-x' WHERE id = pg_temp.id('merge_transfer') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.44 merge_transfer d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.merge_transfer WHERE id = pg_temp.id('merge_transfer')$q$, '42501', '1.44 merge_transfer e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.merge_transfer WHERE id = pg_temp.id('merge_transfer') AND updated_by = 'kiem-thu'$q$, '1.44 merge_transfer f T90 vẫn thấy đúng một dòng, không bị sửa');
-- legacy_source (EN-18-42)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.legacy_source (id, tenant_id, created_by, updated_by, source_code, name, system_kind, jdbc_url, credential_ref, owner) VALUES (pg_temp.id('legacy_source'), 'T90', 'kiem-thu', 'kiem-thu', 'APIM-CU', 'APIM hệ cũ', 'APIM', 'jdbc:postgresql://apim-cu.t90.local:5432/apim', 'kv/dh/t90/migration/apim-cu', 'ie-an')$q$, '1.45 legacy_source a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.legacy_source WHERE id = pg_temp.id('legacy_source')$q$, '1.45 legacy_source b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.legacy_source (id, tenant_id, created_by, updated_by, source_code, name, system_kind, jdbc_url, credential_ref, owner) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'APIM-CU', 'APIM hệ cũ', 'APIM', 'jdbc:postgresql://apim-cu.t90.local:5432/apim', 'kv/dh/t90/migration/apim-cu', 'ie-an')$q$, '42501', '1.45 legacy_source c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.legacy_source SET updated_by = 't91-x' WHERE id = pg_temp.id('legacy_source') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.45 legacy_source d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.legacy_source WHERE id = pg_temp.id('legacy_source')$q$, '42501', '1.45 legacy_source e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.legacy_source WHERE id = pg_temp.id('legacy_source') AND updated_by = 'kiem-thu'$q$, '1.45 legacy_source f T90 vẫn thấy đúng một dòng, không bị sửa');
-- migration_plan (EN-18-43)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_plan (id, tenant_id, created_by, updated_by, plan_code, legacy_source_id, title) VALUES (pg_temp.id('migration_plan'), 'T90', 'kiem-thu', 'kiem-thu', 'MIG-APIM-01', pg_temp.id('legacy_source'), 'Di trú APIM cũ')$q$, '1.46 migration_plan a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_plan WHERE id = pg_temp.id('migration_plan')$q$, '1.46 migration_plan b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_plan (id, tenant_id, created_by, updated_by, plan_code, legacy_source_id, title) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'MIG-APIM-01', pg_temp.id('legacy_source'), 'Di trú APIM cũ')$q$, '42501', '1.46 migration_plan c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.migration_plan SET updated_by = 't91-x' WHERE id = pg_temp.id('migration_plan') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.46 migration_plan d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_plan WHERE id = pg_temp.id('migration_plan')$q$, '42501', '1.46 migration_plan e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.migration_plan WHERE id = pg_temp.id('migration_plan') AND updated_by = 'kiem-thu'$q$, '1.46 migration_plan f T90 vẫn thấy đúng một dòng, không bị sửa');
-- migration_plan_item (EN-18-44)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_plan_item (id, tenant_id, created_by, updated_by, plan_id, seq_no, object_kind, target_module, converter_code, source_query_ref, target_api) VALUES (pg_temp.id('migration_plan_item'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_plan'), 1, 'API', 'PH-02', 'apim-api-v1', 'apim.api-list', 'API-02-061')$q$, '1.47 migration_plan_item a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_plan_item WHERE id = pg_temp.id('migration_plan_item')$q$, '1.47 migration_plan_item b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_plan_item (id, tenant_id, created_by, updated_by, plan_id, seq_no, object_kind, target_module, converter_code, source_query_ref, target_api) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_plan'), 1, 'API', 'PH-02', 'apim-api-v1', 'apim.api-list', 'API-02-061')$q$, '42501', '1.47 migration_plan_item c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.migration_plan_item SET updated_by = 't91-x' WHERE id = pg_temp.id('migration_plan_item') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.47 migration_plan_item d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_plan_item WHERE id = pg_temp.id('migration_plan_item')$q$, '42501', '1.47 migration_plan_item e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.migration_plan_item WHERE id = pg_temp.id('migration_plan_item') AND updated_by = 'kiem-thu'$q$, '1.47 migration_plan_item f T90 vẫn thấy đúng một dòng, không bị sửa');
-- migration_run (EN-18-45)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_run (id, tenant_id, created_by, updated_by, plan_id, run_no, run_mode, status, requested_by) VALUES (pg_temp.id('migration_run'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_plan'), 1, 'DRY_RUN', 'QUEUED', 'ie-an')$q$, '1.48 migration_run a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_run WHERE id = pg_temp.id('migration_run')$q$, '1.48 migration_run b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_run (id, tenant_id, created_by, updated_by, plan_id, run_no, run_mode, status, requested_by) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_plan'), 1, 'DRY_RUN', 'QUEUED', 'ie-an')$q$, '42501', '1.48 migration_run c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.migration_run SET updated_by = 't91-x' WHERE id = pg_temp.id('migration_run') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.48 migration_run d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_run WHERE id = pg_temp.id('migration_run')$q$, '42501', '1.48 migration_run e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.migration_run WHERE id = pg_temp.id('migration_run') AND updated_by = 'kiem-thu'$q$, '1.48 migration_run f T90 vẫn thấy đúng một dòng, không bị sửa');
-- migration_run_item_result (EN-18-46)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_run_item_result (id, tenant_id, created_by, updated_by, run_id, plan_item_id) VALUES (pg_temp.id('migration_run_item_result'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'))$q$, '1.49 migration_run_item_result a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_run_item_result WHERE id = pg_temp.id('migration_run_item_result')$q$, '1.49 migration_run_item_result b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_run_item_result (id, tenant_id, created_by, updated_by, run_id, plan_item_id) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'))$q$, '42501', '1.49 migration_run_item_result c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.migration_run_item_result SET updated_by = 't91-x' WHERE id = pg_temp.id('migration_run_item_result') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.49 migration_run_item_result d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_run_item_result WHERE id = pg_temp.id('migration_run_item_result')$q$, '42501', '1.49 migration_run_item_result e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.migration_run_item_result WHERE id = pg_temp.id('migration_run_item_result') AND updated_by = 'kiem-thu'$q$, '1.49 migration_run_item_result f T90 vẫn thấy đúng một dòng, không bị sửa');
-- migration_error_record (EN-18-47)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_error_record (id, tenant_id, created_by, updated_by, run_id, plan_item_id, source_record_ref, error_code, error_message) VALUES (pg_temp.id('migration_error_record'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'), 'api:1234', 'ERR-02-061', 'Thiếu HTTT sở hữu')$q$, '1.50 migration_error_record a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_error_record WHERE id = pg_temp.id('migration_error_record')$q$, '1.50 migration_error_record b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_error_record (id, tenant_id, created_by, updated_by, run_id, plan_item_id, source_record_ref, error_code, error_message) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'), 'api:1234', 'ERR-02-061', 'Thiếu HTTT sở hữu')$q$, '42501', '1.50 migration_error_record c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.migration_error_record SET updated_by = 't91-x' WHERE id = pg_temp.id('migration_error_record') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.50 migration_error_record d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_error_record WHERE id = pg_temp.id('migration_error_record')$q$, '42501', '1.50 migration_error_record e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.migration_error_record WHERE id = pg_temp.id('migration_error_record') AND updated_by = 'kiem-thu'$q$, '1.50 migration_error_record f T90 vẫn thấy đúng một dòng, không bị sửa');
-- migration_reconciliation (EN-18-48)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_reconciliation (id, tenant_id, created_by, updated_by, run_id, plan_item_id, object_kind, source_count, target_count, source_checksum, target_checksum, matched) VALUES (pg_temp.id('migration_reconciliation'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'), 'API', 10, 10, repeat('e', 64), repeat('e', 64), true)$q$, '1.51 migration_reconciliation a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_reconciliation WHERE id = pg_temp.id('migration_reconciliation')$q$, '1.51 migration_reconciliation b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_reconciliation (id, tenant_id, created_by, updated_by, run_id, plan_item_id, object_kind, source_count, target_count, source_checksum, target_checksum, matched) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'), 'API', 10, 10, repeat('e', 64), repeat('e', 64), true)$q$, '42501', '1.51 migration_reconciliation c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_reconciliation SET updated_by = 't91-x' WHERE id = pg_temp.id('migration_reconciliation')$q$, '42501', '1.51 migration_reconciliation d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_reconciliation WHERE id = pg_temp.id('migration_reconciliation')$q$, '42501', '1.51 migration_reconciliation e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.migration_reconciliation WHERE id = pg_temp.id('migration_reconciliation') AND updated_by = 'kiem-thu'$q$, '1.51 migration_reconciliation f T90 vẫn thấy đúng một dòng, không bị sửa');
-- credential_reissue_marker (EN-18-49)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.credential_reissue_marker (id, tenant_id, created_by, updated_by, object_kind, target_module, target_ref, legacy_ref, credential_kind) VALUES (pg_temp.id('credential_reissue_marker'), 'T90', 'kiem-thu', 'kiem-thu', 'SUBSCRIPTION', 'PH-03', 'sub-0001', 'apim:sub:77', 'OAUTH_CLIENT')$q$, '1.52 credential_reissue_marker a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.credential_reissue_marker WHERE id = pg_temp.id('credential_reissue_marker')$q$, '1.52 credential_reissue_marker b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.credential_reissue_marker (id, tenant_id, created_by, updated_by, object_kind, target_module, target_ref, legacy_ref, credential_kind) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'SUBSCRIPTION', 'PH-03', 'sub-0001', 'apim:sub:77', 'OAUTH_CLIENT')$q$, '42501', '1.52 credential_reissue_marker c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.credential_reissue_marker SET updated_by = 't91-x' WHERE id = pg_temp.id('credential_reissue_marker') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.52 credential_reissue_marker d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.credential_reissue_marker WHERE id = pg_temp.id('credential_reissue_marker')$q$, '42501', '1.52 credential_reissue_marker e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.credential_reissue_marker WHERE id = pg_temp.id('credential_reissue_marker') AND updated_by = 'kiem-thu'$q$, '1.52 credential_reissue_marker f T90 vẫn thấy đúng một dòng, không bị sửa');
-- parallel_run_group (EN-18-50)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.parallel_run_group (id, tenant_id, created_by, updated_by, group_code, title, service_scope, legacy_endpoint_ref, datahub_endpoint_ref) VALUES (pg_temp.id('parallel_run_group'), 'T90', 'kiem-thu', 'kiem-thu', 'GRP-DANCU', 'Nhóm dịch vụ dân cư', '/api/dan-cu/*', 'apim-cu/dan-cu', 'apisix/dan-cu')$q$, '1.53 parallel_run_group a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.parallel_run_group WHERE id = pg_temp.id('parallel_run_group')$q$, '1.53 parallel_run_group b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.parallel_run_group (id, tenant_id, created_by, updated_by, group_code, title, service_scope, legacy_endpoint_ref, datahub_endpoint_ref) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'GRP-DANCU', 'Nhóm dịch vụ dân cư', '/api/dan-cu/*', 'apim-cu/dan-cu', 'apisix/dan-cu')$q$, '42501', '1.53 parallel_run_group c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.parallel_run_group SET updated_by = 't91-x' WHERE id = pg_temp.id('parallel_run_group') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.53 parallel_run_group d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.parallel_run_group WHERE id = pg_temp.id('parallel_run_group')$q$, '42501', '1.53 parallel_run_group e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.parallel_run_group WHERE id = pg_temp.id('parallel_run_group') AND updated_by = 'kiem-thu'$q$, '1.53 parallel_run_group f T90 vẫn thấy đúng một dòng, không bị sửa');
-- shadow_comparison_sample (EN-18-51)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.shadow_comparison_sample (id, tenant_id, created_by, updated_by, group_id, sampled_at, route, request_fingerprint, matched) VALUES (pg_temp.id('shadow_comparison_sample'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('parallel_run_group'), pg_temp.ts(), '/api/dan-cu/v1/cong-dan', repeat('f', 64), true)$q$, '1.54 shadow_comparison_sample a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.shadow_comparison_sample WHERE id = pg_temp.id('shadow_comparison_sample')$q$, '1.54 shadow_comparison_sample b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.shadow_comparison_sample (id, tenant_id, created_by, updated_by, group_id, sampled_at, route, request_fingerprint, matched) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('parallel_run_group'), pg_temp.ts(), '/api/dan-cu/v1/cong-dan', repeat('f', 64), true)$q$, '42501', '1.54 shadow_comparison_sample c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.shadow_comparison_sample SET updated_by = 't91-x' WHERE id = pg_temp.id('shadow_comparison_sample')$q$, '42501', '1.54 shadow_comparison_sample d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.shadow_comparison_sample WHERE id = pg_temp.id('shadow_comparison_sample')$q$, '42501', '1.54 shadow_comparison_sample e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.shadow_comparison_sample WHERE id = pg_temp.id('shadow_comparison_sample') AND updated_by = 'kiem-thu'$q$, '1.54 shadow_comparison_sample f T90 vẫn thấy đúng một dòng, không bị sửa');
-- cutover_checklist (EN-18-52)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.cutover_checklist (id, tenant_id, created_by, updated_by, group_id, item_code, description, check_kind) VALUES (pg_temp.id('cutover_checklist'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('parallel_run_group'), 'DLQ_EMPTY', 'Không còn mục DLQ mở của nhóm', 'AUTO')$q$, '1.55 cutover_checklist a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.cutover_checklist WHERE id = pg_temp.id('cutover_checklist')$q$, '1.55 cutover_checklist b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.cutover_checklist (id, tenant_id, created_by, updated_by, group_id, item_code, description, check_kind) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('parallel_run_group'), 'DLQ_EMPTY', 'Không còn mục DLQ mở của nhóm', 'AUTO')$q$, '42501', '1.55 cutover_checklist c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.cutover_checklist SET updated_by = 't91-x' WHERE id = pg_temp.id('cutover_checklist') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.55 cutover_checklist d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.cutover_checklist WHERE id = pg_temp.id('cutover_checklist')$q$, '42501', '1.55 cutover_checklist e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.cutover_checklist WHERE id = pg_temp.id('cutover_checklist') AND updated_by = 'kiem-thu'$q$, '1.55 cutover_checklist f T90 vẫn thấy đúng một dòng, không bị sửa');
-- cutover_log (EN-18-53)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.cutover_log (id, tenant_id, created_by, updated_by, group_id, action, actor, note) VALUES (pg_temp.id('cutover_log'), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('parallel_run_group'), 'NOTE', 'po-binh', 'Bắt đầu theo dõi bóng')$q$, '1.56 cutover_log a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.cutover_log WHERE id = pg_temp.id('cutover_log')$q$, '1.56 cutover_log b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.cutover_log (id, tenant_id, created_by, updated_by, group_id, action, actor, note) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', pg_temp.id('parallel_run_group'), 'NOTE', 'po-binh', 'Bắt đầu theo dõi bóng')$q$, '42501', '1.56 cutover_log c T91 không chèn dòng của T90');
SELECT pg_temp.expect($q$UPDATE ph18_ops.cutover_log SET updated_by = 't91-x' WHERE id = pg_temp.id('cutover_log')$q$, '42501', '1.56 cutover_log d vai ứng dụng không có quyền UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.cutover_log WHERE id = pg_temp.id('cutover_log')$q$, '42501', '1.56 cutover_log e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.cutover_log WHERE id = pg_temp.id('cutover_log') AND updated_by = 'kiem-thu'$q$, '1.56 cutover_log f T90 vẫn thấy đúng một dòng, không bị sửa');
-- ops_report (EN-18-54)
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.ops_report (id, tenant_id, created_by, updated_by, report_kind, period_kind, period_from, period_to) VALUES (pg_temp.id('ops_report'), 'T90', 'kiem-thu', 'kiem-thu', 'DLQ', 'MONTH', date '2026-11-01', date '2026-11-30')$q$, '1.57 ops_report a chèn dòng mẫu T90');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.ops_report WHERE id = pg_temp.id('ops_report')$q$, '1.57 ops_report b T91 không đọc dòng T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.ops_report (id, tenant_id, created_by, updated_by, report_kind, period_kind, period_from, period_to) VALUES (gen_random_uuid(), 'T90', 'kiem-thu', 'kiem-thu', 'DLQ', 'MONTH', date '2026-11-01', date '2026-11-30')$q$, '42501', '1.57 ops_report c T91 không chèn dòng của T90');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.ops_report SET updated_by = 't91-x' WHERE id = pg_temp.id('ops_report') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '1.57 ops_report d T91 sửa không được dòng nào');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.ops_report WHERE id = pg_temp.id('ops_report')$q$, '42501', '1.57 ops_report e vai ứng dụng không có quyền DELETE');
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.ops_report WHERE id = pg_temp.id('ops_report') AND updated_by = 'kiem-thu'$q$, '1.57 ops_report f T90 vẫn thấy đúng một dòng, không bị sửa');
SET app.tenant_id = 'T90';
SELECT pg_temp.expect(format('SELECT count(*) FROM ph18_ops.dlq_message_%s', to_char(now(), 'YYYYMM')), '42501', '1.99 không đọc trực tiếp phân vùng, chỉ qua bảng cha có RLS');

-- ---------- 2. Quy tắc chốt ở CSDL ----------
SET app.tenant_id = 'T90';
-- 2.1 Tham số: kiểu, miền, trần nền tảng, mức PLATFORM, dòng COMMON
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '600'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.01 giá trị vượt trần nền tảng 500 bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '0'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.02 giá trị dưới miền 1 bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '"ba trăm"'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.03 sai kiểu bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '12.5'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.04 kiểu INTEGER không nhận số lẻ');
SELECT pg_temp.ok($q$UPDATE ph18_ops.param_value SET value = '450'::jsonb, current_version_no = 2 WHERE id = pg_temp.id('param_value')$q$, '2.05 giá trị trong miền và trần ghi được');
SELECT pg_temp.is_true($q$SELECT version = 1 FROM ph18_ops.param_value WHERE id = pg_temp.id('param_value')$q$, '2.06 version tăng khi sửa (ETag)');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.param.cache-ttl-seconds')::uuid, '18.param.cache-ttl-seconds', '30'::jsonb, 'TENANT', 'ta-an', 'ta-an')$q$, '23514', '2.07 tham số mức PLATFORM tenant không ghi');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.batch-max')::uuid, '18.dlq.replay.khac', '30'::jsonb, 'TENANT', 'ta-an', 'ta-an')$q$, '23514', '2.08 param_key phải khớp lược đồ');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.batch-max')::uuid, '18.dlq.replay.batch-max', '30'::jsonb, 'PLATFORM', 'ta-an', 'ta-an')$q$, '23514', '2.09 dòng tenant không mang scope PLATFORM');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.batch-max')::uuid, '18.dlq.replay.batch-max', '500'::jsonb, 'TENANT', 'ta-an', 'ta-an')$q$, '2.10 ghi đè 18.dlq.replay.batch-max cho T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, label, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 't90test', 't90test.khac', 'INT', '1'::jsonb, 'x', 'a', 'a')$q$, '23514', '2.11 tenant không đăng ký lược đồ khóa (chỉ COMMON)');
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_definition SET label = 'Sửa nhãn' WHERE param_key = '18.dlq.replay.batch-max' RETURNING 1) SELECT count(*) = 0 FROM u$q$, '2.12 phiên tenant không sửa được lược đồ khóa COMMON');
SELECT pg_temp.is_true($q$SELECT value = '450'::jsonb AND scope = 'TENANT' FROM ph18_ops.config_param WHERE key = 't90test.batch-max'$q$, '2.13 config_param (DD-14) trả giá trị ghi đè của T90');
SELECT pg_temp.is_true($q$SELECT value = '500'::jsonb FROM ph18_ops.config_param WHERE key = '18.dlq.replay.batch-max'$q$, '2.14 config_param trả ghi đè 18.dlq.replay.batch-max');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT value = '100'::jsonb AND scope = 'PLATFORM' FROM ph18_ops.config_param WHERE key = 't90test.batch-max'$q$, '2.15 T91 thấy mặc định, không thấy ghi đè của T90');
SELECT pg_temp.is_true($q$SELECT count(*) = 61 FROM ph18_ops.config_param WHERE namespace_code = '18'$q$, '2.16 T91 đọc đủ 61 khóa 18.* từ lược đồ COMMON');
SET app.tenant_id = 'COMMON';
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, min_value, max_value, label, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '18', '18.x.bad-default', 'INT', '5000'::jsonb, 1, 100, 'x', 'a', 'a')$q$, '23514', '2.17 mặc định ngoài miền của chính lược đồ bị chặn');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, label, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '18', '17.lac.khoa', 'INT', '1'::jsonb, 'x', 'a', 'a')$q$, '23514', '2.18 khóa phải mang tiền tố không gian tên');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_namespace (id, tenant_id, code, owner_module, title, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '19', 'PH-19', 'Thanh toán', 'a', 'a')$q$, '23514', '2.19 không gian tên 19 do PH-19 tự giữ');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_definition SET value_type = 'STRING' WHERE param_key = '18.dlq.replay.batch-max'$q$, '55000', '2.20 kiểu của khóa bất biến');
SET app.tenant_id = 'T90';
-- 2.2 Đề nghị đổi tham số ★: một đề nghị chờ, bốn mắt, máy trạng thái
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_change_request (id, tenant_id, definition_id, param_key, proposed_value, reason, requested_by, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('param_definition'), 't90test.batch-max', '250'::jsonb, 'Đề nghị thứ hai cùng khóa', 'to-an', now() + interval '1 day', 'to-an', 'to-an')$q$, '23505', '2.21 mỗi khóa một đề nghị chờ duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_change_request (id, tenant_id, definition_id, param_key, proposed_value, reason, requested_by, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.approval-threshold')::uuid, '18.dlq.replay.approval-threshold', '20000'::jsonb, 'Giá trị đề xuất ngoài miền', 'to-an', now() + interval '1 day', 'to-an', 'to-an')$q$, '23514', '2.22 giá trị đề xuất cũng kiểm miền');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET status = 'APPROVED', decided_by = 'to-an', decided_at = now() WHERE id = pg_temp.id('param_change_request')$q$, '23514', '2.23 người đề nghị tự duyệt bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET status = 'APPROVED' WHERE id = pg_temp.id('param_change_request')$q$, '23514', '2.24 duyệt cần người và thời điểm duyệt');
SELECT pg_temp.ok($q$UPDATE ph18_ops.param_change_request SET status = 'APPROVED', decided_by = 'ta-binh', decided_at = now() WHERE id = pg_temp.id('param_change_request')$q$, '2.25 người thứ hai duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('param_change_request')$q$, '55000', '2.26 đề nghị đã duyệt không quay lại chờ');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET proposed_value = '1'::jsonb WHERE id = pg_temp.id('param_change_request')$q$, '55000', '2.27 giá trị đề xuất bất biến');
-- 2.3 Lịch sử phiên bản tham số
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value_version SET value = '1'::jsonb WHERE id = pg_temp.id('param_value_version')$q$, '55000', '2.28 nội dung phiên bản bất biến');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value_version (id, tenant_id, definition_id, param_key, version_no, value, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('param_definition'), 't90test.batch-max', 2, '450'::jsonb, 'ACTIVE', 'a', 'a')$q$, '23505', '2.29 mỗi khóa một phiên bản ACTIVE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value_version SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('param_value_version')$q$, '55000', '2.30 ACTIVE không quay lại PENDING_APPROVAL');
SELECT pg_temp.ok($q$UPDATE ph18_ops.param_value_version SET status = 'SUPERSEDED', superseded_at = now() WHERE id = pg_temp.id('param_value_version')$q$, '2.31 ACTIVE sang SUPERSEDED');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_value_version (id, tenant_id, definition_id, param_key, version_no, value, previous_value, status, change_request_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('param_definition'), 't90test.batch-max', 2, '450'::jsonb, '300'::jsonb, 'ACTIVE', pg_temp.id('param_change_request'), 'ta-binh', 'ta-binh')$q$, '2.32 phiên bản 2 ACTIVE gắn đề nghị đã duyệt');
-- 2.4 Cờ tính năng, egress
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.feature_flag (id, tenant_id, flag_key, owner_ph, owner_user, description, retire_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '07.rdm.feature.hybrid', 'PH-07', 'a', 'b', current_date, 'a', 'a')$q$, '23514', '2.33 cờ tính năng phải dạng ff.{module}.{tính-năng}');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.egress_allowlist_entry (id, tenant_id, host, used_by, purpose, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '10.20.30.40', 'PH-15', 'OTHER', 'a', 'a')$q$, '23514', '2.34 egress không nhận địa chỉ IP trần');
SELECT pg_temp.expect($q$UPDATE ph18_ops.egress_allowlist_entry SET enabled = true, approved_by = 'kiem-thu', approved_at = now() WHERE id = pg_temp.id('egress_allowlist_entry')$q$, '23514', '2.35 người tạo không tự duyệt egress');
SELECT pg_temp.ok($q$UPDATE ph18_ops.egress_allowlist_entry SET enabled = true, approved_by = 'so-binh', approved_at = now() WHERE id = pg_temp.id('egress_allowlist_entry')$q$, '2.36 người thứ hai duyệt egress');
-- 2.5 DLQ: máy trạng thái, payload gốc, bỏ qua có lý do
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET status = 'RESOLVED', closed_at = now() WHERE id = pg_temp.id('dlq_message')$q$, '55000', '2.37 NEW không nhảy thẳng RESOLVED');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET payload_inline = '{"maHoSo": "SUA"}'::jsonb WHERE id = pg_temp.id('dlq_message')$q$, '55000', '2.38 payload gốc không sửa');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET dlq_key = 'khac' WHERE id = pg_temp.id('dlq_message')$q$, '55000', '2.39 dlqKey bất biến');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET status = 'TRIAGED', error_class = 'CONTRACT', priority = 'P2' WHERE id = pg_temp.id('dlq_message')$q$, '2.40 NEW sang TRIAGED');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET status = 'DISCARDED', closed_at = now(), discard_reason = 'ngắn' WHERE id = pg_temp.id('dlq_message')$q$, '23514', '2.41 bỏ qua cần lý do ≥ 10 ký tự');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET status = 'DISCARDED', closed_at = now(), discard_reason = 'Bản tin thử nghiệm, không cần xử lý' WHERE id = pg_temp.id('dlq_message')$q$, '2.42 bỏ qua có lý do');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET status = 'TRIAGED', closed_at = NULL WHERE id = pg_temp.id('dlq_message')$q$, '2.43 mở lại mục đã bỏ qua');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, status, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k2', 'ph04-runtime', 'PH-04', 'MISSING', 'PURGED', 'POISON', now(), 'a', 'a')$q$, '23514', '2.44 POISON phải ghi header ngữ cảnh thiếu');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, payload_inline, payload_size_bytes, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k3', 'ph04-runtime', 'PH-04', 'X', 'INLINE', '{}'::jsonb, 300000, now(), 'a', 'a')$q$, '23514', '2.45 payload inline quá 256 KB bị chặn');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k4', 'ph04-runtime', 'PH-04', 'X', 'INLINE', now(), 'a', 'a')$q$, '23514', '2.46 INLINE phải có payload');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET occurrence_count = occurrence_count + 1, last_seen_at = now() WHERE id = pg_temp.id('dlq_message')$q$, '2.46a gặp lại cùng dlqKey chỉ tăng bộ đếm lần gặp (BR-18-015)');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET occurrence_count = 0 WHERE id = pg_temp.id('dlq_message')$q$, '23514', '2.46b bộ đếm lần gặp tối thiểu 1');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, context_headers, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k5', 'ph10-event', 'PH-10', 'X', 'FEDERATED', '{"authorization": "x"}'::jsonb, now(), 'a', 'a')$q$, '23514', '2.47 header ngữ cảnh không giữ authorization, FEDERATED cần external_ref');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_payload_ref (id, tenant_id, dlq_id, dlq_received_at, kind, bucket, object_key, size_bytes, sha256, content_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('dlq_message'), pg_temp.ts(), 'REVISION', 'dh-t91-ops', 'x', 1, repeat('b', 64), 'application/json', 'a', 'a')$q$, '23514', '2.48 payload lớn chỉ ở bucket dh-{tenant}-ops của chính tenant');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_assignment (id, tenant_id, dlq_id, dlq_received_at, assignee, assigned_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('dlq_message'), pg_temp.ts(), 'to-c', 'to-binh', 'a', 'a')$q$, '23505', '2.49 mỗi mục một lần gán đang hiệu lực');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_assignment (id, tenant_id, dlq_id, dlq_received_at, assignee, assigned_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), pg_temp.ts(), 'to-c', 'to-binh', 'a', 'a')$q$, '23503', '2.50 gán cho mục DLQ không tồn tại bị chặn');
-- 2.6 Bản sửa payload: bốn mắt với dữ liệu Hạn chế, nội dung đóng băng
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_revision SET contains_restricted = true, status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('dlq_revision')$q$, '2.51 bản sửa có dữ liệu Hạn chế gửi duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_revision SET diff = '[]'::jsonb WHERE id = pg_temp.id('dlq_revision')$q$, '55000', '2.52 bản sửa chờ duyệt không đổi nội dung');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_revision SET status = 'APPROVED' WHERE id = pg_temp.id('dlq_revision')$q$, '23514', '2.53 duyệt bản sửa Hạn chế cần người duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_revision SET status = 'APPROVED', approved_by = 'kiem-thu', approved_at = now() WHERE id = pg_temp.id('dlq_revision')$q$, '23514', '2.54 người soạn không tự duyệt bản sửa');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_revision SET status = 'APPROVED', approved_by = 'so-binh', approved_at = now() WHERE id = pg_temp.id('dlq_revision')$q$, '2.55 người thứ hai duyệt bản sửa');
-- 2.7 Phát lại: bốn mắt, lũy đẳng, máy trạng thái
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, mode, reason, total_items, approval_required, status, approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BATCH_LIST', 'Phát lại loạt lớn sau sự cố', 500, true, 'APPROVED', 'to-an', 'to-an', 'to-an')$q$, '23514', '2.56 người tạo loạt không tự duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, mode, reason, total_items, approval_required, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BATCH_LIST', 'Phát lại loạt lớn sau sự cố', 500, true, 'RUNNING', 'to-an', 'to-an')$q$, '23514', '2.57 loạt cần duyệt không chạy khi chưa duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, mode, reason, total_items, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BATCH_FILTER', 'Phát lại theo bộ lọc', 10, 'to-an', 'to-an')$q$, '23514', '2.58 loạt theo bộ lọc phải có bộ lọc');
SELECT pg_temp.expect($q$UPDATE ph18_ops.replay_job SET status = 'RUNNING' WHERE id = pg_temp.id('replay_job')$q$, '55000', '2.59 DRAFT không chạy thẳng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'APPROVED' WHERE id = pg_temp.id('replay_job')$q$, '2.60 lượt đơn dưới ngưỡng tự duyệt');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'RUNNING', started_at = now() WHERE id = pg_temp.id('replay_job')$q$, '2.61 APPROVED sang RUNNING');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'PAUSED', paused_at = now() WHERE id = pg_temp.id('replay_job')$q$, '2.62 tạm dừng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'RUNNING' WHERE id = pg_temp.id('replay_job')$q$, '2.63 chạy tiếp');
SELECT pg_temp.expect($q$UPDATE ph18_ops.replay_job SET succeeded = 2 WHERE id = pg_temp.id('replay_job')$q$, '23514', '2.64 bộ đếm không vượt tổng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_item (id, tenant_id, job_id, dlq_id, dlq_received_at, revision_no, idempotency_key, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('replay_job'), pg_temp.id('dlq_message'), pg_temp.ts(), 1, 'sai-khoa', 'a', 'a')$q$, '23514', '2.65 khóa lũy đẳng phải là dlqId:revision');
SELECT pg_temp.expect($q$UPDATE ph18_ops.replay_item SET status = 'SUCCEEDED' WHERE id = pg_temp.id('replay_item')$q$, '55000', '2.66 mục phát lại PENDING không nhảy SUCCEEDED');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_item SET status = 'SENT', dispatched_at = now() WHERE id = pg_temp.id('replay_item')$q$, '2.67 mục phát lại đã gửi');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_item SET status = 'SUCCEEDED', result_at = now() WHERE id = pg_temp.id('replay_item')$q$, '2.68 nguồn báo thành công');
-- 2.8 Thông báo
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, caller_module, message_key, template_code, recipient_ref, category, channels, params, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-01', 'msg-x', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-1"}]'::jsonb, 'INFO', '{EMAIL}', '{"cccd": "001"}'::jsonb, 'a', 'a')$q$, '23514', '2.69 biến mẫu không chứa số định danh (FR-00-062)');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, caller_module, message_key, template_code, recipient_ref, category, channels, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-01', 'msg-0001', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-1"}]'::jsonb, 'INFO', '{EMAIL}', 'a', 'a')$q$, '23505', '2.70 khóa lũy đẳng của bên gọi không nhân bản thông báo');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, caller_module, message_key, template_code, recipient_ref, category, channels, link, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-01', 'msg-y', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-1"}]'::jsonb, 'INFO', '{EMAIL}', 'https://ngoai.example/x', 'a', 'a')$q$, '23514', '2.71 liên kết chỉ là đường dẫn nội bộ');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_template_version (id, tenant_id, template_id, version_no, body_text, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('notification_template'), 2, '{{#ds}}{{ten}}{{/ds}}', 'a', 'a')$q$, '23514', '2.72 mẫu Mustache không logic');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_template_version SET status = 'IN_REVIEW', submitted_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '2.73 gửi duyệt mẫu');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_template_version SET body_text = 'Sửa sau khi gửi duyệt' WHERE id = pg_temp.id('notification_template_version')$q$, '55000', '2.74 mẫu đang duyệt không đổi nội dung');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_template_version SET status = 'ACTIVE', reviewed_by = 'so-binh', reviewed_at = now(), activated_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '23514', '2.75 kích hoạt cần kiểm tra cấm trường đạt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_template_version SET status = 'ACTIVE', field_check_passed = true, reviewed_by = 'kiem-thu', reviewed_at = now(), activated_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '23514', '2.76 người soạn không tự duyệt mẫu');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_template_version SET status = 'ACTIVE', field_check_passed = true, reviewed_by = 'so-binh', reviewed_at = now(), activated_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '2.77 người thứ hai kích hoạt mẫu');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_delivery SET status = 'DELIVERED' WHERE id = pg_temp.id('notification_delivery')$q$, '55000', '2.78 QUEUED không nhảy DELIVERED');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_delivery SET status = 'SUPPRESSED' WHERE id = pg_temp.id('notification_delivery')$q$, '23514', '2.79 SUPPRESSED phải có lý do');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_delivery SET status = 'SENT', sent_at = now(), rendered_title = 'Kết quả thẩm định' WHERE id = pg_temp.id('notification_delivery')$q$, '2.80 lần gửi SENT');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_delivery SET read_at = now() WHERE id = pg_temp.id('notification_delivery')$q$, '2.81 người dùng đọc thông báo trong ứng dụng');
SELECT pg_temp.is_true($q$SELECT title = 'Kết quả thẩm định' AND read_at IS NOT NULL AND channels_sent = '["IN_APP"]'::jsonb FROM ph18_ops.notification WHERE id = pg_temp.id('notification_delivery')$q$, '2.82 khung nhìn notification (DD-13) đúng trường');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.suppression_entry (id, tenant_id, channel, address_hash, address_masked, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'EMAIL', repeat('d', 64), 'a***', 'COMPLAINT', 'a', 'a')$q$, '23505', '2.83 mỗi địa chỉ một dòng chặn đang hiệu lực');
-- 2.9 Việc, lịch, cửa sổ đóng băng
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_item (id, tenant_id, type_id, type_code, task_key, title, subject_ref, assignee_kind, assignee_ref, required_permission, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('task_type'), 'ph01.approve-onboarding', 'HS-0001', 'Trùng', 'HS-0001', 'ROLE', 'TA', 'PERM-01-approve', 'a', 'a')$q$, '23505', '2.84 tạo việc lũy đẳng theo task_key');
SELECT pg_temp.ok($q$UPDATE ph18_ops.task_item SET four_eyes = false, status = 'IN_PROGRESS', claimed_by = 'ta-an', started_at = now() WHERE id = pg_temp.id('task_item')$q$, '2.85 nhận việc');
SELECT pg_temp.expect($q$UPDATE ph18_ops.task_item SET status = 'DONE' WHERE id = pg_temp.id('task_item')$q$, '23514', '2.86 việc đóng phải có thời điểm đóng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.task_item SET status = 'DONE', closed_at = now(), closed_by = 'ta-an', outcome = 'APPROVED' WHERE id = pg_temp.id('task_item')$q$, '2.87 đóng việc');
SELECT pg_temp.expect($q$UPDATE ph18_ops.task_item SET status = 'OPEN', closed_at = NULL WHERE id = pg_temp.id('task_item')$q$, '55000', '2.88 việc DONE không mở lại');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_item (id, tenant_id, type_id, type_code, task_key, title, subject_ref, assignee_kind, assignee_ref, required_permission, requested_by, four_eyes, status, closed_at, closed_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('task_type'), 'ph01.approve-onboarding', 'HS-0002', 'Bốn mắt', 'HS-0002', 'ROLE', 'TA', 'PERM-01-approve', 'ta-an', true, 'DONE', now(), 'ta-an', 'a', 'a')$q$, '23514', '2.89 việc bốn mắt không do người đề nghị đóng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.maintenance_window (id, tenant_id, window_code, kind, starts_at, ends_at, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W2', 'FREEZE', now(), now() - interval '1 hour', 'Cửa sổ ngược thời gian', 'a', 'a')$q$, '23514', '2.90 cửa sổ kết thúc sau khi bắt đầu');
SELECT pg_temp.expect($q$UPDATE ph18_ops.maintenance_window SET status = 'ACTIVE' WHERE id = pg_temp.id('maintenance_window')$q$, '23514', '2.91 cửa sổ hiệu lực cần duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.work_calendar (id, tenant_id, calendar_code, name, working_days, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SAI', 'Sai ngày', '{0,8}', 'a', 'a')$q$, '23514', '2.92 ngày làm việc chỉ 1 đến 7');
-- 2.10 Sự cố
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now() WHERE id = pg_temp.id('incident')$q$, '55000', '2.93 OPEN không đóng thẳng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.incident SET status = 'INVESTIGATING', acknowledged_at = now(), has_personal_data = true WHERE id = pg_temp.id('incident')$q$, '2.94 điều tra sự cố');
SELECT pg_temp.ok($q$UPDATE ph18_ops.incident SET status = 'RESOLVED', resolved_at = now() WHERE id = pg_temp.id('incident')$q$, '2.95 đã khắc phục');
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now() WHERE id = pg_temp.id('incident')$q$, '23514', '2.96 đóng cần nguyên nhân gốc và bài học');
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now(), root_cause = 'Nguồn đổi lược đồ không báo trước', lessons_learned = 'Bắt buộc thông báo thay đổi lược đồ' WHERE id = pg_temp.id('incident')$q$, '23514', '2.97 sự cố có DLCN chưa chuyển PH-09 thì không đóng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now(), root_cause = 'Nguồn đổi lược đồ không báo trước', lessons_learned = 'Bắt buộc thông báo thay đổi lược đồ', ph09_breach_ref = 'BR-2026-0001', ph09_reported_at = now() WHERE id = pg_temp.id('incident')$q$, '2.98 đóng sự cố đủ điều kiện');
-- 2.11 Khôi phục tenant, xuất, sáp nhập
SELECT pg_temp.ok($q$UPDATE ph18_ops.tenant_restore_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('tenant_restore_request')$q$, '2.100 gửi duyệt khôi phục');
SELECT pg_temp.expect($q$UPDATE ph18_ops.tenant_restore_request SET status = 'APPROVED', approved_by = 'ta-an', approved_at = now() WHERE id = pg_temp.id('tenant_restore_request')$q$, '23514', '2.101 người yêu cầu không tự duyệt khôi phục');
SELECT pg_temp.ok($q$UPDATE ph18_ops.tenant_restore_request SET status = 'APPROVED', approved_by = 'pa-binh', approved_at = now() WHERE id = pg_temp.id('tenant_restore_request')$q$, '2.102 PA duyệt khôi phục');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_request (id, tenant_id, request_no, restore_point, scope, reason, requested_by, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RST-T90-0002', now() - interval '2 days', 'FULL_TENANT', 'Yêu cầu thứ hai khi yêu cầu một chưa xong', 'ta-an', 'PENDING_APPROVAL', 'a', 'a')$q$, '23505', '2.103 mỗi tenant một yêu cầu khôi phục đang hoạt động');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_request (id, tenant_id, request_no, restore_point, scope, schemas, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RST-T90-0003', now() - interval '2 days', 'SCHEMAS', '{ph13_audit}', 'Khôi phục kiểm toán về quá khứ là không được', 'ta-an', 'a', 'a')$q$, '23514', '2.104 không khôi phục schema kiểm toán ph13');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_step (id, tenant_id, request_id, step_no, step_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('tenant_restore_request'), 5, 'APPROVAL', 'a', 'a')$q$, '23514', '2.105 số bước khớp mã bước');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-X', 'PH-07', 'T91', 'T92', 'x', 'a', 'a')$q$, '23514', '2.106 dòng sáp nhập thuộc tenant đích');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-X', 'PH-07', 'T90', 'T90', 'x', 'a', 'a')$q$, '23514', '2.107 tenant nguồn khác tenant đích');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, dry_run, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-2026-0001', 'PH-07', 'T91', 'T90', 'mp/ph07', false, 'a', 'a')$q$, '2.108 lần chạy thật thứ nhất');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, dry_run, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-2026-0001', 'PH-07', 'T91', 'T90', 'mp/ph07', false, 'a', 'a')$q$, '23505', '2.109 mỗi kế hoạch, phân hệ một lần chạy thật');
SELECT pg_temp.expect($q$UPDATE ph18_ops.merge_transfer SET dry_run = false WHERE id = pg_temp.id('merge_transfer')$q$, '55000', '2.110 cờ chạy thử bất biến');
-- 2.12 Di trú, chạy song song, cắt chuyển
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.legacy_source (id, tenant_id, source_code, name, system_kind, jdbc_url, credential_ref, owner, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BUS-CU', 'Bus', 'BUS', 'jdbc:postgresql://bus:5432/bus?user=sa', 'kv/dh/t90/migration/bus', 'a', 'a', 'a')$q$, '23514', '2.111 URL JDBC không kèm thông tin đăng nhập');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.legacy_source (id, tenant_id, source_code, name, system_kind, jdbc_url, credential_ref, owner, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BUS-CU', 'Bus', 'BUS', 'jdbc:postgresql://bus:5432/bus', 'kv/dh/t91/migration/bus', 'a', 'a', 'a')$q$, '23514', '2.112 tham chiếu OpenBao chỉ trong nhánh của tenant');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_plan_item (id, tenant_id, plan_id, seq_no, object_kind, target_module, converter_code, source_query_ref, target_api, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('migration_plan'), 2, 'CATALOG', 'PH-01', 'c', 'q', 'API-01-080', 'a', 'a')$q$, '23514', '2.113 danh mục chỉ di trú sang PH-07');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_run (id, tenant_id, plan_id, run_no, run_mode, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('migration_plan'), 2, 'REAL', 'QUEUED', 'ie-an', 'a', 'a')$q$, '23514', '2.114 chạy thật cần duyệt trước khi xếp hàng');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_run (id, tenant_id, plan_id, run_no, run_mode, status, requested_by, created_by, updated_by) VALUES (md5('run-real')::uuid, 'T90', pg_temp.id('migration_plan'), 2, 'REAL', 'PENDING_APPROVAL', 'ie-an', 'a', 'a')$q$, '2.115 tạo lần chạy thật chờ duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_run SET status = 'QUEUED', approved_by = 'ie-an', approved_at = now() WHERE id = md5('run-real')::uuid$q$, '23514', '2.116 người yêu cầu không tự duyệt chạy thật');
SELECT pg_temp.ok($q$UPDATE ph18_ops.migration_run SET status = 'QUEUED', approved_by = 'ta-binh', approved_at = now() WHERE id = md5('run-real')::uuid$q$, '2.117 người thứ hai duyệt chạy thật');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_run SET status = 'SUCCEEDED' WHERE id = md5('run-real')::uuid$q$, '55000', '2.118 QUEUED không nhảy SUCCEEDED');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_reconciliation (id, tenant_id, run_id, plan_item_id, object_kind, source_count, target_count, source_checksum, target_checksum, matched, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'), 'API', 10, 9, repeat('e', 64), repeat('e', 64), true, 'a', 'a')$q$, '23514', '2.119 không ghi khớp khi số lượng lệch');
SELECT pg_temp.expect($q$UPDATE ph18_ops.parallel_run_group SET status = 'SHADOW_OK', match_rate = 98 WHERE id = pg_temp.id('parallel_run_group')$q$, '23514', '2.120 bóng đạt cần tỷ lệ khớp ≥ ngưỡng');
SELECT pg_temp.expect($q$UPDATE ph18_ops.parallel_run_group SET status = 'CUT_OVER', cutover_at = now(), rollback_deadline_at = now() + interval '15 minutes' WHERE id = pg_temp.id('parallel_run_group')$q$, '55000', '2.121 PARALLEL không cắt chuyển thẳng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.parallel_run_group SET status = 'SHADOW_OK', match_rate = 99.8 WHERE id = pg_temp.id('parallel_run_group')$q$, '2.122 bóng đạt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.parallel_run_group SET status = 'CUT_OVER' WHERE id = pg_temp.id('parallel_run_group')$q$, '23514', '2.123 cắt chuyển cần mốc và hạn quay lui');
SELECT pg_temp.ok($q$UPDATE ph18_ops.parallel_run_group SET status = 'CUT_OVER', cutover_at = now(), rollback_deadline_at = now() + interval '15 minutes' WHERE id = pg_temp.id('parallel_run_group')$q$, '2.124 cắt chuyển');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.cutover_log (id, tenant_id, group_id, action, actor, approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('parallel_run_group'), 'CUTOVER', 'po-an', 'po-an', 'a', 'a')$q$, '23514', '2.125 sổ cắt chuyển cần người duyệt khác người thực hiện');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.shadow_comparison_sample (id, tenant_id, group_id, route, request_fingerprint, matched, diff_kind, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('parallel_run_group'), '/x', repeat('f', 64), true, 'BODY', 'a', 'a')$q$, '23514', '2.126 mẫu lệch thân không ghi là khớp');
SELECT pg_temp.expect($q$UPDATE ph18_ops.credential_reissue_marker SET status = 'WAIVED' WHERE id = pg_temp.id('credential_reissue_marker')$q$, '23514', '2.127 miễn cấp lại cần lý do');
-- 2.13 Outbox
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.outbox_event (id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 't91.ops.param.changed.v1', 'a', 'a', 'a', '{}'::jsonb, 'a', 'a')$q$, '23514', '2.128 topic outbox mang tiền tố tenant của dòng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.outbox_event (id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 't90.ops.dlq.received.v1', 'a', 'a', 'a', '{"payload": {}}'::jsonb, 'a', 'a')$q$, '23514', '2.129 sự kiện không mang payload DLQ');
-- 2.14 Dòng COMMON: tenant không ghi; phiên COMMON ghi được
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_template (id, tenant_id, template_code, owner_module, title, category, channels, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'ph02.x', 'PH-02', 'x', 'INFO', '{EMAIL}', 'a', 'a')$q$, '42501', '2.130 phiên tenant không ghi mẫu COMMON');
SET app.tenant_id = 'COMMON';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_template (id, tenant_id, template_code, owner_module, title, category, channels, created_by, updated_by) VALUES (md5('tpl-common')::uuid, 'COMMON', 'ph02.change-notice', 'PH-02', 'Thông báo thay đổi API', 'INFO', '{EMAIL}', 'pa-an', 'pa-an')$q$, '2.131 phiên COMMON (PA) ghi mẫu nền tảng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'k', 'ph04-runtime', 'PH-04', 'X', 'PURGED', now(), 'a', 'a')$q$, '23514', '2.132 bảng theo tenant không nhận dòng COMMON');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_template WHERE template_code = 'ph02.change-notice'$q$, '2.133 T91 đọc được mẫu COMMON');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.backup_object$q$, '2.134 T91 không thấy đối tượng sao lưu cụm (COMMON không dùng chung ở bảng sao lưu)');
-- 2.15 Khởi tạo tenant
SELECT pg_temp.ok($q$CALL ph18_ops.p_seed_tenant('T91')$q$, '2.135 khởi tạo tenant T91');
SELECT pg_temp.ok($q$CALL ph18_ops.p_seed_tenant('T91')$q$, '2.136 chạy lại không lỗi');
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph18_ops.work_calendar$q$, '2.137 T91 thấy lịch của mình và lịch quốc gia, không nhân bản');
RESET ROLE;

-- ---------- 3. Bảng chỉ thêm: chủ đối tượng cũng không sửa, xóa ----------
SET ROLE ph18_owner;
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_audit SET updated_by = 'x' WHERE id = pg_temp.id('dlq_audit')$q$, '55000', '3.01 dlq_audit chỉ thêm: chặn UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.dlq_audit WHERE id = pg_temp.id('dlq_audit')$q$, '55000', '3.01 dlq_audit chỉ thêm: chặn DELETE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident_timeline SET updated_by = 'x' WHERE id = pg_temp.id('incident_timeline')$q$, '55000', '3.02 incident_timeline chỉ thêm: chặn UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.incident_timeline WHERE id = pg_temp.id('incident_timeline')$q$, '55000', '3.02 incident_timeline chỉ thêm: chặn DELETE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.restore_verification SET updated_by = 'x' WHERE id = pg_temp.id('restore_verification')$q$, '55000', '3.03 restore_verification chỉ thêm: chặn UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.restore_verification WHERE id = pg_temp.id('restore_verification')$q$, '55000', '3.03 restore_verification chỉ thêm: chặn DELETE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_reconciliation SET updated_by = 'x' WHERE id = pg_temp.id('migration_reconciliation')$q$, '55000', '3.04 migration_reconciliation chỉ thêm: chặn UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_reconciliation WHERE id = pg_temp.id('migration_reconciliation')$q$, '55000', '3.04 migration_reconciliation chỉ thêm: chặn DELETE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.shadow_comparison_sample SET updated_by = 'x' WHERE id = pg_temp.id('shadow_comparison_sample')$q$, '55000', '3.05 shadow_comparison_sample chỉ thêm: chặn UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.shadow_comparison_sample WHERE id = pg_temp.id('shadow_comparison_sample')$q$, '55000', '3.05 shadow_comparison_sample chỉ thêm: chặn DELETE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.cutover_log SET updated_by = 'x' WHERE id = pg_temp.id('cutover_log')$q$, '55000', '3.06 cutover_log chỉ thêm: chặn UPDATE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.cutover_log WHERE id = pg_temp.id('cutover_log')$q$, '55000', '3.06 cutover_log chỉ thêm: chặn DELETE');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_value_version WHERE id = pg_temp.id('param_value_version')$q$, '55000', '3.90 lịch sử tham số không xóa');
RESET ROLE;

-- ---------- 4. Vai readonly và worker ----------
SET ROLE dh_ops_ro;
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message')$q$, '4.01 readonly đọc siêu dữ liệu DLQ của tenant');
SELECT pg_temp.expect($q$SELECT payload_inline FROM ph18_ops.dlq_message$q$, '42501', '4.02 readonly không đọc payload DLQ');
SELECT pg_temp.expect($q$SELECT payload FROM ph18_ops.dlq_revision$q$, '42501', '4.03 readonly không đọc payload bản sửa');
SELECT pg_temp.expect($q$SELECT params FROM ph18_ops.notification_message$q$, '42501', '4.04 readonly không đọc biến mẫu thông báo');
SELECT pg_temp.expect($q$SELECT count(*) FROM ph18_batch.batch_job_instance$q$, '42501', '4.18 readonly không đọc kho lần chạy Spring Batch');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.ops_report (id, tenant_id, report_kind, period_kind, period_from, period_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'DLQ', 'DAY', current_date, current_date, 'a', 'a')$q$, '42501', '4.05 readonly không ghi');
SELECT pg_temp.is_true($q$SELECT count(*) >= 1 FROM ph18_ops.config_param$q$, '4.06 readonly đọc config_param');
RESET ROLE;
SET ROLE dh_ops_worker;
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$SELECT count(*) FROM ph18_ops.dlq_message$q$, '42501', '4.07 worker không đọc DLQ');
SELECT pg_temp.ok($q$INSERT INTO ph18_batch.batch_job_instance (job_instance_id, version, job_name, job_key) VALUES (nextval('ph18_batch.batch_job_seq'), 0, 'dh-migrate', md5('T90:run-real'))$q$, '4.17 worker ghi kho lần chạy Spring Batch ph18_batch');
SELECT pg_temp.expect($q$SELECT count(*) FROM ph18_ops.notification_message$q$, '42501', '4.08 worker không đọc thông báo');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '1'::jsonb$q$, '42501', '4.09 worker không ghi tham số');
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph18_ops.migration_run$q$, '4.10 worker đọc lần chạy di trú của tenant');
SELECT pg_temp.ok($q$UPDATE ph18_ops.migration_run SET status = 'RUNNING', started_at = now() WHERE id = md5('run-real')::uuid$q$, '4.11 worker cập nhật trạng thái lần chạy');
SELECT pg_temp.ok($q$UPDATE ph18_ops.migration_run SET heartbeat_at = now(), checkpoint = '{"step": "import", "lastKey": "api:1234"}'::jsonb WHERE id = md5('run-real')::uuid$q$, '4.11a worker ghi nhịp sống và điểm dừng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.merge_transfer SET status = 'RUNNING', progress_percent = 40, rows_total = 100, rows_copied = 40 WHERE id = pg_temp.id('merge_transfer')$q$, '4.12 worker báo tiến độ sáp nhập');
SELECT pg_temp.ok($q$UPDATE ph18_ops.tenant_restore_step SET status = 'RUNNING', started_at = now() WHERE id = pg_temp.id('tenant_restore_step')$q$, '4.13 worker cập nhật bước khôi phục');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_reconciliation SET matched = false$q$, '42501', '4.14 worker không sửa báo cáo đối chiếu (chỉ thêm)');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_run$q$, '42501', '4.15 worker không xóa');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_run$q$, '4.16 worker ở phiên T91 không thấy lần chạy của T90');
RESET ROLE;

-- ---------- 5. Lưu giữ: dọn mục DLQ hết hạn lan truyền bản sửa, tham chiếu, gán, mục phát lại ----------
SET ROLE dh_ops_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$DELETE FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message')$q$, '5.01 tác vụ lưu giữ xóa mục DLQ');
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM ph18_ops.dlq_revision) + (SELECT count(*) FROM ph18_ops.dlq_payload_ref) + (SELECT count(*) FROM ph18_ops.dlq_assignment) + (SELECT count(*) FROM ph18_ops.replay_item) = 0$q$, '5.02 bản sửa, tham chiếu payload, gán, mục phát lại bị xóa theo');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_audit$q$, '5.03 nhật ký thao tác DLQ vẫn giữ (tham chiếu logic)');
RESET ROLE;

SELECT 'PH18 ISOLATION TEST: ALL PASS' AS ket_qua;
