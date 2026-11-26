-- =============================================================================
-- D03-03-PH04 · Kiểm thử DDL schema ph04: cô lập tenant, chính sách dùng chung,
-- một phiên bản mở, bất biến phiên bản, duyệt gắn băm, triển khai hiện hành,
-- chạy thử mô phỏng, lệnh có hạn, nhật ký chỉ thêm, outbox đúng tenant.
-- Chạy sau ph04_int.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph04_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE dừng tệp.
-- Tương ứng nhóm ca cô lập và tách nhiệm của D05-02-PH04 (TenantIsolationIT).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_integration_app') THEN
    CREATE ROLE dh_integration_app LOGIN NOBYPASSRLS IN ROLE ph04_app;
  ELSE
    GRANT ph04_app TO dh_integration_app;
  END IF;
END $$;
SET ROLE dh_integration_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['w68','f68','v68','v68b','d68','d68b','c68','r68','w01','tc68']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.h(text) RETURNS char(71) LANGUAGE sql AS $$ SELECT ('sha256:' || encode(sha256(convert_to($1, 'UTF8')), 'hex'))::char(71) $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
INSERT INTO ph04.workspace (id, tenant_id, code, name, created_by, updated_by)
VALUES (pg_temp.id('w68'), 'T68', 'DEFAULT', 'Mặc định', 'u.ie01', 'u.ie01');
INSERT INTO ph04.flow (id, tenant_id, workspace_id, code, name, resource_kind, origin, created_by, updated_by)
VALUES (pg_temp.id('f68'), 'T68', pg_temp.id('w68'), 'ho-tich-khai-sinh', 'Hộ tịch khai sinh', 'ROUTE', 'TEMPLATE', 'u.ie01', 'u.ie01');
INSERT INTO ph04.flow_version (id, tenant_id, flow_id, version_no, definition_yaml, content_hash, catalog_version, created_by, updated_by)
VALUES (pg_temp.id('v68'), 'T68', pg_temp.id('f68'), 1, '- route: {}', pg_temp.h('v1'), 'camel-quarkus-3.33.2', 'u.ie01', 'u.ie01');
INSERT INTO ph04.test_case (id, tenant_id, flow_id, name, assertions, created_by, updated_by)
VALUES (pg_temp.id('tc68'), 'T68', pg_temp.id('f68'), 'ks-hop-le', '[{"type":"STATUS","value":200}]', 'u.ie01', 'u.ie01');

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
INSERT INTO ph04.workspace (id, tenant_id, code, name, created_by, updated_by)
VALUES (pg_temp.id('w01'), 'T01', 'DEFAULT', 'Mặc định', 'u.x', 'u.x');

-- 1. Cô lập đọc
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph04.workspace; IF n <> 1 THEN RAISE 'FAIL 1: T01 thấy % không gian', n; END IF;
  SELECT count(*) INTO n FROM ph04.flow; IF n <> 0 THEN RAISE 'FAIL 1b'; END IF;
  SELECT count(*) INTO n FROM ph04.flow_version; IF n <> 0 THEN RAISE 'FAIL 1c'; END IF;
  RAISE NOTICE 'PASS 1 T01 không đọc được dữ liệu T68';
END $$;

-- 2. Cô lập ghi: T01 chèn dòng T68
DO $$ BEGIN
  INSERT INTO ph04.flow (id, tenant_id, workspace_id, code, name, resource_kind, origin, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('w68'), 'gia-mao', 'x', 'ROUTE', 'BLANK', 'u.x', 'u.x');
  RAISE 'FAIL 2';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn chèn chéo tenant';
END $$;

-- 3. Cô lập sửa: T01 sửa dòng T68 không tác dụng
DO $$ DECLARE n int; BEGIN
  UPDATE ph04.flow SET name = 'x' WHERE id = pg_temp.id('f68'); GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  RAISE NOTICE 'PASS 3 T01 không sửa được dòng T68';
END $$;

-- 4. Khóa ngoại kèm tenant: luồng T01 không trỏ được không gian T68
DO $$ BEGIN
  INSERT INTO ph04.flow (id, tenant_id, workspace_id, code, name, resource_kind, origin, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('w68'), 'tro-cheo', 'x', 'ROUTE', 'BLANK', 'u.x', 'u.x');
  RAISE 'FAIL 4';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 4 khóa ngoại kèm tenant_id chặn trỏ chéo';
END $$;

-- 5. Tỉnh chỉ thu hẹp chính sách (ck_component_policy_narrow)
DO $$ BEGIN
  INSERT INTO ph04.component_policy (id, tenant_id, component_kind, component_name, decision, reason, policy_version, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'COMPONENT', 'exec', 'ALLOWED', 'thử mở rộng', 1, 'u.x', 'u.x');
  RAISE 'FAIL 5';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 5 tỉnh không cho phép thêm thành phần';
END $$;

-- 6. Tỉnh không ghi được dòng COMMON
DO $$ BEGIN
  INSERT INTO ph04.component_policy (id, tenant_id, component_kind, component_name, decision, reason, policy_version, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'COMPONENT', 'exec', 'ALLOWED', 'thử ghi nền', 1, 'u.x', 'u.x');
  RAISE 'FAIL 6';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 6 tỉnh không ghi chính sách nền';
END $$;

-- 7. PLATFORM ghi dòng COMMON; tỉnh đọc được dòng COMMON (mẫu S)
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph04.component_policy (id, tenant_id, component_kind, component_name, decision, reason, policy_version, created_by, updated_by)
VALUES (gen_random_uuid(), 'COMMON', 'COMPONENT', 'exec', 'DENIED', 'Cấm chạy lệnh hệ điều hành', 1, 'system:seed', 'system:seed');
SET app.tenant_id = 'T01';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph04.component_policy WHERE tenant_id = 'COMMON'; IF n <> 1 THEN RAISE 'FAIL 7'; END IF;
  RAISE NOTICE 'PASS 7 tỉnh đọc chính sách nền COMMON';
END $$;

SET app.tenant_id = 'T68';
-- 8. BR-04-016: tối đa một phiên bản mở
DO $$ BEGIN
  INSERT INTO ph04.flow_version (id, tenant_id, flow_id, version_no, definition_yaml, content_hash, catalog_version, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('f68'), 2, '- route: {}', pg_temp.h('v2'), 'camel-quarkus-3.33.2', 'u.ie01', 'u.ie01');
  RAISE 'FAIL 8';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 8 một phiên bản mở mỗi luồng';
END $$;

-- 9. Duyệt khi băm không khớp băm gửi duyệt bị chặn (ck_flow_version_approved)
UPDATE ph04.flow_version SET status = 'PENDING_REVIEW', submitted_hash = content_hash, submitted_by = 'u.ie01', submitted_at = now()
 WHERE id = pg_temp.id('v68');
DO $$ BEGIN
  UPDATE ph04.flow_version SET status = 'APPROVED', submitted_hash = pg_temp.h('khac') WHERE id = pg_temp.id('v68');
  RAISE 'FAIL 9';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9 duyệt phải gắn băm gửi duyệt';
END $$;

-- 10. Duyệt thiếu người duyệt bị chặn
DO $$ BEGIN
  UPDATE ph04.flow_version SET status = 'APPROVED' WHERE id = pg_temp.id('v68');
  RAISE 'FAIL 10';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10 trạng thái đã duyệt cần approved_by';
END $$;

-- 11. Nội dung phiên bản đã gửi duyệt là bất biến (tg_flow_version_immutable)
DO $$ BEGIN
  UPDATE ph04.flow_version SET definition_yaml = '- route: {id: x}' WHERE id = pg_temp.id('v68');
  RAISE 'FAIL 11';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11 phiên bản PENDING_REVIEW bất biến';
END $$;

UPDATE ph04.flow_version SET status = 'APPROVED', approved_by = 'u.ia01', approved_at = now() WHERE id = pg_temp.id('v68');

-- 12. Một triển khai hiện hành mỗi môi trường (uq_deployment_current)
INSERT INTO ph04.deployment (id, tenant_id, flow_id, flow_version_id, environment, kind, runtime_profile, requested_by, current, created_by, updated_by)
VALUES (pg_temp.id('d68'), 'T68', pg_temp.id('f68'), pg_temp.id('v68'), 'PROD', 'RELEASE', 'core-native', 'u.ia01', true, 'u.ia01', 'u.ia01');
DO $$ BEGIN
  INSERT INTO ph04.deployment (id, tenant_id, flow_id, flow_version_id, environment, kind, runtime_profile, requested_by, current, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('f68'), pg_temp.id('v68'), 'PROD', 'RELEASE', 'core-native', 'u.ia01', true, 'u.ia01', 'u.ia01');
  RAISE 'FAIL 12';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 12 một triển khai hiện hành mỗi môi trường';
END $$;

-- 13. Quay lui cần lý do ≥ 10 ký tự
DO $$ BEGIN
  INSERT INTO ph04.deployment (id, tenant_id, flow_id, flow_version_id, environment, kind, runtime_profile, requested_by, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('f68'), pg_temp.id('v68'), 'PROD', 'ROLLBACK', 'core-native', 'u.ia01', 'ngắn', 'u.ia01', 'u.ia01');
  RAISE 'FAIL 13';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13 quay lui cần lý do';
END $$;

-- 14. Lần chạy mô phỏng không mang trạng thái chạy thật (ck_test_run_sim)
DO $$ BEGIN
  INSERT INTO ph04.test_run (id, tenant_id, flow_version_id, definition_hash, mode, status, timeout_seconds, run_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), pg_temp.h('v1'), 'SIMULATED', 'PASSED', 30, 'u.ie01');
  RAISE 'FAIL 14';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14 lần chạy SIMULATED không thể PASSED';
END $$;

-- 15. Ca kiểm thử cần 1–20 khẳng định (VR-20)
DO $$ BEGIN
  INSERT INTO ph04.test_case (id, tenant_id, flow_id, name, assertions, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('f68'), 'khong-khang-dinh', '[]', 'u.ie01', 'u.ie01');
  RAISE 'FAIL 15';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15 ca kiểm thử có khẳng định';
END $$;

-- 16. Lệnh hết hạn quá 5 phút bị chặn
DO $$ BEGIN
  INSERT INTO ph04.runtime_command (id, tenant_id, flow_id, deployment_id, environment, action, scope, reason, expected_replicas, key_id, signature, issued_by, expires_at)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('f68'), pg_temp.id('d68'), 'PROD', 'PAUSE', 'FLOW', 'Bảo trì hệ đích NDXP', 3, 'k1', 'sig', 'u.to01', now() + interval '10 minutes');
  RAISE 'FAIL 16';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16 lệnh có hạn ≤ 5 phút';
END $$;

-- 17. Lệnh phạm vi ROUTES phải có route_ids
DO $$ BEGIN
  INSERT INTO ph04.runtime_command (id, tenant_id, flow_id, deployment_id, environment, action, scope, reason, expected_replicas, key_id, signature, issued_by, expires_at)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('f68'), pg_temp.id('d68'), 'PROD', 'PAUSE', 'ROUTES', 'Bảo trì hệ đích NDXP', 3, 'k1', 'sig', 'u.to01', now() + interval '1 minute');
  RAISE 'FAIL 17';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17 phạm vi ROUTES cần route_ids';
END $$;

-- 18. Nhật ký duyệt chỉ thêm
INSERT INTO ph04.review (id, tenant_id, flow_version_id, action, actor, content_hash)
VALUES (pg_temp.id('r68'), 'T68', pg_temp.id('v68'), 'APPROVE', 'u.ia01', pg_temp.h('v1'));
DO $$ BEGIN
  UPDATE ph04.review SET actor = 'u.ie01' WHERE id = pg_temp.id('r68');
  RAISE 'FAIL 18';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 18 review không sửa được';
END $$;

-- 19. Yêu cầu sửa cần ý kiến ≥ 10 ký tự
DO $$ BEGIN
  INSERT INTO ph04.review (id, tenant_id, flow_version_id, action, actor, content_hash, comment)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), 'REQUEST_CHANGES', 'u.ia01', pg_temp.h('v1'), 'sửa đi');
  RAISE 'FAIL 19';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 19 yêu cầu sửa cần ý kiến';
END $$;

-- 20. Outbox: topic phải cùng tenant
DO $$ BEGIN
  INSERT INTO ph04.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.integration.flow.created.v1', 't01.integration.flow.created.v1', 'flow', 'x', '{}', repeat('0', 32));
  RAISE 'FAIL 20';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20 outbox sai tenant bị chặn';
END $$;

-- 21. Mã luồng trùng trong tenant bị chặn khi chưa giải phóng (BR-04-001)
DO $$ BEGIN
  INSERT INTO ph04.flow (id, tenant_id, workspace_id, code, name, resource_kind, origin, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('w68'), 'ho-tich-khai-sinh', 'Trùng', 'ROUTE', 'BLANK', 'u.ie01', 'u.ie01');
  RAISE 'FAIL 21';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 21 mã luồng duy nhất trong tenant';
END $$;

-- 22. Tài khoản đọc không đọc được nội dung định nghĩa
RESET ROLE;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph04_readonly;
  ELSE
    GRANT ph04_readonly TO dh_report_ro;
  END IF;
END $$;
SET ROLE dh_report_ro;
DO $$ BEGIN
  PERFORM definition_yaml FROM ph04.flow_version LIMIT 1;
  RAISE 'FAIL 22';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 22 ph04_readonly không đọc definition_yaml';
END $$;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM (SELECT id, status, content_hash FROM ph04.flow_version) t;
  RAISE NOTICE 'PASS 23 ph04_readonly đọc cột siêu dữ liệu của flow_version (% dòng theo RLS)', n;
END $$;
RESET ROLE;
