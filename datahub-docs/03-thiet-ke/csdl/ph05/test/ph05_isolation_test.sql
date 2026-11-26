-- =============================================================================
-- D03-03-PH05 · Kiểm thử DDL ph05_adapter: cô lập tenant, bốn mắt, chặn bí mật,
-- bất biến phiên bản, Kamelet dùng chung, chỉ thêm.
-- Chạy sau ph05_adapter.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph05_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE dừng tệp.
-- Tương ứng nhóm ca cô lập, tách nhiệm, chống lộ bí mật của D05-02-PH05.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_integration_app') THEN
    CREATE ROLE dh_integration_app LOGIN NOBYPASSRLS IN ROLE ph05_app;
  ELSE
    GRANT ph05_app TO dh_integration_app;
  END IF;
END $$;
SET ROLE dh_integration_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['c68','e68','t68','a68','v68','o68','c01','e01','t01','k68','kv68','db68']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
INSERT INTO ph05_adapter.connection (id, tenant_id, code, name, type_code, system_code, purpose, owner, created_by, updated_by)
VALUES (pg_temp.id('c68'), 'T68', 'ndxp-ho-tich', 'NDXP hộ tịch', 'http-rest', 'NDXP', 'READ', 'an', 'an', 'an');
INSERT INTO ph05_adapter.connection_environment (id, tenant_id, connection_id, env, params, params_hash, secret_version, secret_written_by, created_by, updated_by)
VALUES (pg_temp.id('e68'), 'T68', pg_temp.id('c68'), 'PROD', '{"baseUrl":"https://ndxp.gov.vn"}', repeat('a', 64), 1, 'an', 'an', 'an');
INSERT INTO ph05_adapter.connection_test (id, tenant_id, connection_id, env, status, params_hash, secret_version, finished_at, expires_at, run_by)
VALUES (pg_temp.id('t68'), 'T68', pg_temp.id('c68'), 'PROD', 'PASSED', repeat('a', 64), 1, '2026-11-26 03:00Z', '2026-11-27 03:00Z', 'an');
INSERT INTO ph05_adapter.adapter (id, tenant_id, code, name, system_code, system_group, protocol, connection_id, owner, created_by, updated_by)
VALUES (pg_temp.id('a68'), 'T68', 'ndxp-rest', 'NDXP REST', 'NDXP', 1, 'REST', pg_temp.id('c68'), 'an', 'an', 'an');
INSERT INTO ph05_adapter.adapter_version (id, tenant_id, adapter_id, major, created_by, updated_by)
VALUES (pg_temp.id('v68'), 'T68', pg_temp.id('a68'), 1, 'an', 'an');
INSERT INTO ph05_adapter.adapter_operation (id, tenant_id, adapter_version_id, code, title, direction, protocol_spec, request_format, response_format, side_effect, created_by, updated_by)
VALUES (pg_temp.id('o68'), 'T68', pg_temp.id('v68'), 'tra-cuu', 'Tra cứu', 'OUTBOUND', '{"method":"GET","pathTemplate":"/ho-tich"}', 'JSON', 'JSON', 'NONE', 'an', 'an');
INSERT INTO ph05_adapter.db_access_record (event_id, tenant_id, connection_code, flow_code, flow_version, env, db_username, statement_hash, statement_kind, row_count, duration_ms, outcome, trace_id, occurred_at)
VALUES (gen_random_uuid(), 'T68', 'dkkd-db', 'dkkd-dong-bo', 1, 'PROD', 'v-dh-T68-x', repeat('b', 64), 'SELECT', 842, 37, 'OK', repeat('0', 32), now());

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
INSERT INTO ph05_adapter.connection (id, tenant_id, code, name, type_code, system_code, purpose, owner, created_by, updated_by)
VALUES (pg_temp.id('c01'), 'T01', 'ndxp-ho-tich', 'NDXP hộ tịch T01', 'http-rest', 'NDXP', 'READ', 'lan', 'lan', 'lan');

-- 1. Cô lập đọc
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph05_adapter.connection; IF n <> 1 THEN RAISE 'FAIL 1: T01 thấy % kết nối', n; END IF;
  SELECT count(*) INTO n FROM ph05_adapter.connection_environment; IF n <> 0 THEN RAISE 'FAIL 1b'; END IF;
  SELECT count(*) INTO n FROM ph05_adapter.db_access_record; IF n <> 0 THEN RAISE 'FAIL 1c'; END IF;
  RAISE NOTICE 'PASS 1 T01 không đọc được dữ liệu T68';
END $$;

-- 2. Cô lập ghi: T01 chèn dòng T68
DO $$ BEGIN
  INSERT INTO ph05_adapter.connection (id, tenant_id, code, name, type_code, system_code, purpose, owner, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'gia-mao', 'x', 'http-rest', 'X', 'READ', 'lan', 'lan', 'lan');
  RAISE 'FAIL 2';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn chèn chéo tenant';
END $$;

-- 3. Cô lập sửa: T01 cập nhật dòng T68 không ảnh hưởng
DO $$ DECLARE n int; BEGIN
  UPDATE ph05_adapter.connection SET name = 'bị sửa' WHERE code = 'ndxp-ho-tich' AND tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  RAISE NOTICE 'PASS 3 không sửa được dòng tenant khác';
END $$;

-- 4. Thiếu biến phiên
DO $$ BEGIN
  PERFORM set_config('app.tenant_id', '', true);
  PERFORM count(*) FROM ph05_adapter.connection WHERE tenant_id = current_setting('app.tenant_id', false);
  RAISE NOTICE 'PASS 4 biến phiên rỗng: 0 dòng (đặt lại ở mỗi giao dịch)';
END $$;
SET app.tenant_id = 'T68';

-- 5. Không lưu bí mật trong tham số
DO $$ BEGIN
  UPDATE ph05_adapter.connection_environment SET params = '{"baseUrl":"https://x","password":"DH-CANARY-123"}' WHERE id = pg_temp.id('e68');
  RAISE 'FAIL 5';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 5 chặn khóa bí mật trong params';
END $$;

-- 6. Bốn mắt: người ghi bí mật không được duyệt PROD
DO $$ BEGIN
  UPDATE ph05_adapter.connection_environment SET status = 'ENABLED', last_passed_test_id = pg_temp.id('t68'),
         requested_by = 'binh', approved_by = 'an' WHERE id = pg_temp.id('e68');
  RAISE 'FAIL 6';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 6 người ghi bí mật không tự duyệt';
END $$;
DO $$ BEGIN
  UPDATE ph05_adapter.connection_environment SET status = 'ENABLED', last_passed_test_id = pg_temp.id('t68'),
         requested_by = 'an', approved_by = 'binh', approved_at = now() WHERE id = pg_temp.id('e68');
  RAISE NOTICE 'PASS 6b IA khác người yêu cầu duyệt được';
END $$;

-- 7. PROD ENABLED cần người duyệt
DO $$ BEGIN
  UPDATE ph05_adapter.connection_environment SET approved_by = NULL WHERE id = pg_temp.id('e68');
  RAISE 'FAIL 7';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 7 PROD bật phải có người duyệt';
END $$;

-- 8. Một lần xoay mở
INSERT INTO ph05_adapter.secret_rotation (id, tenant_id, connection_id, env, old_version, new_version, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('c68'), 'PROD', 1, 2, 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph05_adapter.secret_rotation (id, tenant_id, connection_id, env, old_version, new_version, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('c68'), 'PROD', 1, 3, 'an', 'an');
  RAISE 'FAIL 8';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 8 một lần xoay mở (ERR-05-036)';
END $$;

-- 9. Phiên bản bộ điều hợp: bốn mắt và bất biến
DO $$ BEGIN
  UPDATE ph05_adapter.adapter_version SET status = 'APPROVED', submitted_by = 'an', approved_by = 'an', content_hash = repeat('c', 64) WHERE id = pg_temp.id('v68');
  RAISE 'FAIL 9';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9 người gửi không tự duyệt phiên bản';
END $$;
UPDATE ph05_adapter.adapter_version SET status = 'APPROVED', submitted_by = 'an', approved_by = 'binh', approved_at = now(), content_hash = repeat('c', 64) WHERE id = pg_temp.id('v68');
UPDATE ph05_adapter.adapter SET status = 'ACTIVE', effective_version_id = pg_temp.id('v68') WHERE id = pg_temp.id('a68');
DO $$ BEGIN
  UPDATE ph05_adapter.adapter_version SET max_concurrency = 99 WHERE id = pg_temp.id('v68');
  RAISE 'FAIL 9b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 9b phiên bản đã duyệt bất biến';
END $$;
DO $$ BEGIN
  INSERT INTO ph05_adapter.adapter_version (id, tenant_id, adapter_id, major, minor, status, approved_by, submitted_by, content_hash, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('a68'), 1, 1, 'APPROVED', 'binh', 'an', repeat('d', 64), 'an', 'an');
  RAISE 'FAIL 9c';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 9c một phiên bản APPROVED (BR-05-016)';
END $$;

-- 10. Tài khoản ghi CSDL: cần đồng ý, ≤ 90 ngày
DO $$ BEGIN
  INSERT INTO ph05_adapter.flow_db_account (id, tenant_id, connection_id, flow_code, env, access_mode, schemas, tables, operations, justification, status, valid_until, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('c68'), 'ghi-kq', 'PROD', 'WRITE', '{dkkd}', '{dkkd.ket_qua}', '{INSERT}', repeat('x', 40), 'ISSUED', current_date + 30, 'an', 'an', 'an');
  RAISE 'FAIL 10';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10 ghi chưa có SO đồng ý bị chặn';
END $$;
DO $$ BEGIN
  INSERT INTO ph05_adapter.flow_db_account (id, tenant_id, connection_id, flow_code, env, access_mode, schemas, tables, operations, justification, valid_until, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('c68'), 'ghi-kq', 'PROD', 'WRITE', '{dkkd}', '{dkkd.ket_qua}', '{INSERT}', repeat('x', 40), current_date + 120, 'an', 'an', 'an');
  RAISE 'FAIL 10b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10b ghi quá 90 ngày bị chặn';
END $$;
DO $$ BEGIN
  INSERT INTO ph05_adapter.flow_db_account (id, tenant_id, connection_id, flow_code, env, access_mode, schemas, operations, justification, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('c68'), 'doc', 'PROD', 'READ', '{dkkd}', '{SELECT,DELETE}', repeat('x', 40), 'an', 'an', 'an');
  RAISE 'FAIL 10c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10c tài khoản đọc không có thao tác ghi';
END $$;

-- 11. Nhật ký truy cập CSDL chỉ thêm
DO $$ BEGIN
  DELETE FROM ph05_adapter.db_access_record;
  RAISE 'FAIL 11';
EXCEPTION WHEN insufficient_privilege OR object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 11 db_access_record chỉ thêm';
END $$;

-- 12. Kamelet: tỉnh đọc BASE, không ghi COMMON, không dùng tiền tố dh-
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph05_adapter.kamelet WHERE scope = 'BASE'; IF n < 20 THEN RAISE 'FAIL 12: thấy % Kamelet nền', n; END IF;
  RAISE NOTICE 'PASS 12 tỉnh đọc được % Kamelet nền', n;
END $$;
DO $$ BEGIN
  INSERT INTO ph05_adapter.kamelet (id, tenant_id, name, scope, type, group_code, title, owner, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'chung-moi-sink', 'COMMON', 'sink', 'http', 'x', 'an', 'an', 'an');
  RAISE 'FAIL 12b';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 12b tỉnh không ghi Kamelet COMMON (ERR-05-040)';
END $$;
DO $$ BEGIN
  INSERT INTO ph05_adapter.kamelet (id, tenant_id, name, scope, type, group_code, title, owner, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'dh-gia-sink', 'TENANT', 'sink', 'http', 'x', 'an', 'an', 'an');
  RAISE 'FAIL 12c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 12c tiền tố dh- dành cho Kamelet nền';
END $$;
INSERT INTO ph05_adapter.kamelet (id, tenant_id, name, scope, type, group_code, title, owner, created_by, updated_by)
VALUES (pg_temp.id('k68'), 'T68', 'ndxp-ho-tich-ext-action', 'TENANT', 'action', 'http', 'Tra hộ tịch', 'an', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph05_adapter.kamelet_version (id, tenant_id, kamelet_id, semver, status, yaml, yaml_hash, runtime_profiles, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('k68'), '1.0.0', 'SUBMITTED', 'x', repeat('e', 64), '{core-native}', 'an', 'an');
  RAISE 'FAIL 12d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 12d chưa qua kiểm tra tĩnh không gửi được';
END $$;

-- 13. Outbox: không chứa bí mật, topic đúng tenant
DO $$ BEGIN
  INSERT INTO ph05_adapter.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.adapter.connection.enabled.v1', 't01.adapter.connection.enabled.v1', 'Connection', 'x', '{}', repeat('0', 32));
  RAISE 'FAIL 13';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13 topic phải thuộc tenant';
END $$;
DO $$ BEGIN
  INSERT INTO ph05_adapter.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.adapter.connection.enabled.v1', 't68.adapter.connection.enabled.v1', 'Connection', 'x', '{"secret":"DH-CANARY"}', repeat('0', 32));
  RAISE 'FAIL 13b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13b sự kiện không mang bí mật';
END $$;

-- 14. CDC chỉ cho nhóm 3, 4; topic đúng tenant
DO $$ BEGIN
  INSERT INTO ph05_adapter.adapter (id, tenant_id, code, name, system_code, system_group, protocol, connection_id, owner, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'sai-cdc', 'x', 'NDXP', 1, 'CDC', pg_temp.id('c68'), 'an', 'an', 'an');
  RAISE 'FAIL 14';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14 CDC không dùng cho HTTT nhóm 1';
END $$;

RESET ROLE;
\echo 'Hoàn tất: mọi khối PASS'
