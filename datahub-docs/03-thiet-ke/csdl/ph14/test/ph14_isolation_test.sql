-- =============================================================================
-- D03-03-PH14 · Kiểm thử DDL ph14_national: cô lập tenant (đọc, ghi, sửa, xóa, COMMON, phân vùng),
-- bốn mắt, chặn bí mật, bất biến (đặc tả, chứng thư, sổ giao dịch), ràng buộc nghiệp vụ,
-- quyền theo vai trò.
-- Chạy sau các tệp ddl/ph14_*.sql trên CSDL rỗng:
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph14_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE dừng tệp.
-- Tương ứng nhóm ca cô lập tenant, tách nhiệm, chống lộ bí mật của D05-02-PH14 (NFR-14-024, SEC-87).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_integration_app') THEN
    CREATE ROLE dh_integration_app LOGIN NOBYPASSRLS IN ROLE ph14_app;
  ELSE
    GRANT ph14_app TO dh_integration_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph14_readonly;
  ELSE
    GRANT ph14_readonly TO dh_report_ro;
  END IF;
END $$;
SET ROLE dh_integration_app;

CREATE FUNCTION pg_temp.u(text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT md5('ph14-test:' || $1)::uuid $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, connection_code, auth_mode, created_by, updated_by)
VALUES (pg_temp.u('p68'), 'T68', 'ndxp-t68', 'NDXP của T68', 'NDXP', 'ndxp-oauth', 'PRIVATE_KEY_JWT', 'an', 'an');
INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, connection_code, auth_mode, created_by, updated_by)
VALUES (pg_temp.u('p68b'), 'T68', 'ndop-t68', 'NDOP của T68', 'NDOP', 'ndop-oauth', 'CLIENT_SECRET', 'an', 'an');
INSERT INTO ph14_national.national_service (id, tenant_id, platform_id, code, national_service_code, name, service_group, protocol, operation_type,
                                            sensitivity, purpose_required, created_by, updated_by)
VALUES (pg_temp.u('s68'), 'T68', pg_temp.u('p68'), 'lltp-tra-trang-thai', 'LLTP_TRA_TRANG_THAI', 'Tra trạng thái', 'LLTP', 'REST', 'READ', 'SENSITIVE', true, 'an', 'an');
INSERT INTO ph14_national.national_service (id, tenant_id, platform_id, code, national_service_code, name, service_group, protocol, operation_type, idempotent,
                                            sensitivity, purpose_required, created_by, updated_by)
VALUES (pg_temp.u('s68w'), 'T68', pg_temp.u('p68'), 'hotich-dang-ky-khai-sinh', 'HOTICH_DKKS', 'Đăng ký khai sinh', 'HO_TICH', 'SOAP', 'WRITE', false, 'SENSITIVE', true, 'an', 'an');
INSERT INTO ph14_national.service_spec (id, tenant_id, service_id, spec_version, kind, checksum, contract_version, content, created_by, updated_by)
VALUES (pg_temp.u('sp68'), 'T68', pg_temp.u('s68'), '1.0.0', 'OPENAPI', repeat('a', 64), '1.0', '{"openapi":"3.1.0"}', 'an', 'an');
INSERT INTO ph14_national.national_certificate (id, tenant_id, code, platform_id, purpose, subject, issuer, serial_number, fingerprint_sha256, not_before, not_after,
                                                key_ref, public_chain, state, uploaded_by, created_by, updated_by)
VALUES (pg_temp.u('c68'), 'T68', 'tinh-t68-2026', pg_temp.u('p68'), 'SIGNING', 'CN=T68', 'CN=CA công vụ', '01', repeat('b', 64), '2026-01-01Z', '2028-01-01Z',
        'transit/keys/dh-t68-national-sign', '-----BEGIN CERTIFICATE-----x-----END CERTIFICATE-----', 'UPLOADED', 'an', 'an', 'an');
INSERT INTO ph14_national.quota_policy (id, tenant_id, platform_id, period, env, limit_count, basis_document, created_by, updated_by)
VALUES (pg_temp.u('q68'), 'T68', pg_temp.u('p68'), 'DAY', 'TEST', 1000, 'Văn bản số 12/2026 ngày 01/06/2026 về hạn mức', 'an', 'an');
INSERT INTO ph14_national.national_transaction (tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, state, trace_id,
                                                case_code, lookup_key_hash)
VALUES ('T68', 'NAT-20261126-0000A1', now(), 'OUTBOUND', 'ndxp-t68', 'lltp-tra-trang-thai', 'READ', 'HT-MOTCUA', 'RECEIVED', repeat('0', 32), 'HS-1', repeat('c', 64));
INSERT INTO ph14_national.approval_request (id, tenant_id, request_type, object_type, object_code, proposed_change, last_modified_by, requested_by, expires_at, created_by, updated_by)
VALUES (pg_temp.u('ar68'), 'T68', 'PLATFORM_ACTIVATE', 'PLATFORM', 'ndxp-t68', '{"state":"ACTIVE"}', 'an', 'an', now() + interval '7 days', 'an', 'an');
INSERT INTO ph14_national.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
VALUES (gen_random_uuid(), 'T68', 'vn.datahub.national.platform.changed.v1', 't68.national.platform.changed.v1', 'NationalPlatform', 'ndxp-t68', '{"state":"DRAFT"}', repeat('0', 32));

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, connection_code, auth_mode, created_by, updated_by)
VALUES (pg_temp.u('p01'), 'T01', 'ndxp-t68', 'NDXP của T01 (cùng mã với T68 vẫn hợp lệ)', 'NDXP', 'ndxp-oauth', 'PRIVATE_KEY_JWT', 'lan', 'lan');

-- ---------- Dữ liệu COMMON (phiên PLATFORM) ----------
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, scope, connection_code, auth_mode, created_by, updated_by)
VALUES (pg_temp.u('pc'), 'COMMON', 'ndxp-dmdc-common', 'NDXP danh mục dùng chung', 'NDXP', 'COMMON', 'ndxp-dmdc', 'PRIVATE_KEY_JWT', 'pa', 'pa');
INSERT INTO ph14_national.national_service (id, tenant_id, platform_id, code, national_service_code, name, service_group, protocol, operation_type,
                                            sensitivity, purpose_required, created_by, updated_by)
VALUES (pg_temp.u('sc'), 'COMMON', pg_temp.u('pc'), 'dmdc-lay-du-lieu', 'DMDC_LAY_DU_LIEU', 'Lấy dữ liệu danh mục', 'DMDC', 'REST', 'READ', 'PUBLIC', false, 'pa', 'pa');

SET app.tenant_id = 'T01';

-- 1. Cô lập đọc (bảng thường và bảng phân vùng)
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph14_national.national_platform WHERE code <> 'ndxp-dmdc-common'; IF n <> 1 THEN RAISE 'FAIL 1: T01 thấy % nền tảng', n; END IF;
  SELECT count(*) INTO n FROM ph14_national.national_service WHERE tenant_id <> 'COMMON'; IF n <> 0 THEN RAISE 'FAIL 1b'; END IF;
  SELECT count(*) INTO n FROM ph14_national.service_spec; IF n <> 0 THEN RAISE 'FAIL 1c'; END IF;
  SELECT count(*) INTO n FROM ph14_national.national_certificate; IF n <> 0 THEN RAISE 'FAIL 1d'; END IF;
  SELECT count(*) INTO n FROM ph14_national.quota_policy; IF n <> 0 THEN RAISE 'FAIL 1e'; END IF;
  SELECT count(*) INTO n FROM ph14_national.national_transaction; IF n <> 0 THEN RAISE 'FAIL 1f (phân vùng)'; END IF;
  SELECT count(*) INTO n FROM ph14_national.approval_request; IF n <> 0 THEN RAISE 'FAIL 1g'; END IF;
  SELECT count(*) INTO n FROM ph14_national.outbox; IF n <> 0 THEN RAISE 'FAIL 1h'; END IF;
  RAISE NOTICE 'PASS 1 T01 không đọc được dữ liệu T68 ở 8 nhóm bảng';
END $$;

-- 2. Cô lập ghi: T01 chèn dòng T68
DO $$ BEGIN
  INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, connection_code, auth_mode, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'gia-mao', 'x', 'NDXP', 'c', 'CLIENT_SECRET', 'lan', 'lan');
  RAISE 'FAIL 2';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn chèn chéo tenant';
END $$;

-- 2b. Cô lập ghi vào bảng phân vùng
DO $$ BEGIN
  INSERT INTO ph14_national.national_transaction (tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, state, trace_id)
  VALUES ('T68', 'NAT-20261126-GIAMAO1', now(), 'OUTBOUND', 'ndxp-t68', 'x', 'READ', 'HT', 'RECEIVED', repeat('0', 32));
  RAISE 'FAIL 2b';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2b chặn chèn sổ giao dịch chéo tenant';
END $$;

-- 3. Cô lập sửa
DO $$ DECLARE n int; BEGIN
  UPDATE ph14_national.national_platform SET name = 'bị sửa' WHERE code = 'ndxp-t68' AND tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  UPDATE ph14_national.national_transaction SET state = 'SENT' WHERE tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3b'; END IF;
  RAISE NOTICE 'PASS 3 không sửa được dòng tenant khác';
END $$;

-- 4. Cô lập xóa
DO $$ DECLARE n int; BEGIN
  DELETE FROM ph14_national.national_service WHERE tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 4'; END IF;
  DELETE FROM ph14_national.quota_policy WHERE tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 4b'; END IF;
  RAISE NOTICE 'PASS 4 không xóa được dòng tenant khác';
END $$;

-- 5. Biến phiên rỗng: không thấy gì
DO $$ DECLARE n int; BEGIN
  PERFORM set_config('app.tenant_id', '', true);
  SELECT count(*) INTO n FROM ph14_national.national_platform WHERE tenant_id <> 'COMMON'; IF n <> 0 THEN RAISE 'FAIL 5'; END IF;
  SELECT count(*) INTO n FROM ph14_national.national_transaction; IF n <> 0 THEN RAISE 'FAIL 5b'; END IF;
  RAISE NOTICE 'PASS 5 biến phiên rỗng: không thấy dòng của tenant nào (chỉ dòng COMMON của bảng dùng chung)';
END $$;
SET app.tenant_id = 'T01';

-- 6. COMMON: tenant tỉnh đọc được dịch vụ và nền tảng COMMON nhưng không ghi được (BR-14-029)
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph14_national.national_platform WHERE tenant_id = 'COMMON'; IF n <> 1 THEN RAISE 'FAIL 6: không thấy nền tảng COMMON'; END IF;
  SELECT count(*) INTO n FROM ph14_national.national_service WHERE tenant_id = 'COMMON'; IF n <> 1 THEN RAISE 'FAIL 6b: không thấy dịch vụ COMMON'; END IF;
  UPDATE ph14_national.national_platform SET name = 'T01 sửa COMMON' WHERE tenant_id = 'COMMON';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 6c: sửa được nền tảng COMMON'; END IF;
  RAISE NOTICE 'PASS 6 tenant tỉnh đọc, không sửa được nền tảng và dịch vụ COMMON';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.national_platform (id, tenant_id, code, name, platform_type, scope, connection_code, auth_mode, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'gia-mao-common', 'x', 'NDXP', 'COMMON', 'c', 'CLIENT_SECRET', 'lan', 'lan');
  RAISE 'FAIL 6d';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 6d tenant tỉnh không tạo được nền tảng COMMON';
END $$;
DO $$ DECLARE n int; BEGIN
  -- Bảng chỉ P (không S): COMMON không hiện cho tenant tỉnh, kể cả dòng COMMON của chứng thư
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph14_national.national_certificate (id, tenant_id, code, purpose, subject, issuer, serial_number, fingerprint_sha256, not_before, not_after, key_ref, public_chain, uploaded_by, created_by, updated_by)
  VALUES (pg_temp.u('ccommon'), 'COMMON', 'common-2026', 'SIGNING', 'CN=COMMON', 'CN=CA', '09', repeat('d', 64), '2026-01-01Z', '2028-01-01Z', 'transit/keys/dh-common-national-sign', 'x', 'pa', 'pa', 'pa');
  PERFORM set_config('app.tenant_id', 'T01', true);
  SELECT count(*) INTO n FROM ph14_national.national_certificate; IF n <> 0 THEN RAISE 'FAIL 6e: T01 thấy chứng thư COMMON'; END IF;
  RAISE NOTICE 'PASS 6e chứng thư COMMON chỉ phiên PLATFORM thấy';
END $$;
SET app.tenant_id = 'T68';

-- 7. Mọi bảng nghiệp vụ bật FORCE ROW LEVEL SECURITY (trừ bảng kỹ thuật shedlock)
RESET ROLE;
DO $$ DECLARE r record; n int := 0; BEGIN
  FOR r IN SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
            WHERE s.nspname = 'ph14_national' AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname <> 'shedlock' LOOP
    n := n + 1;
    IF NOT (r.relrowsecurity AND r.relforcerowsecurity) THEN RAISE 'FAIL 7: % thiếu FORCE RLS', r.relname; END IF;
  END LOOP;
  IF n <> 35 THEN RAISE 'FAIL 7: có % bảng nghiệp vụ, mong đợi 35', n; END IF;
  RAISE NOTICE 'PASS 7 % bảng nghiệp vụ đều FORCE RLS', n;
END $$;
-- 7b. Mọi bảng có tenant_id đều có CHECK dạng tenant
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT t.table_name FROM information_schema.columns t
            WHERE t.table_schema = 'ph14_national' AND t.column_name = 'tenant_id'
              AND t.table_name IN (SELECT relname FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph14_national' AND c.relkind IN ('r', 'p') AND NOT c.relispartition) LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = ('ph14_national.' || r.table_name)::regclass AND k.contype = 'c' AND pg_get_constraintdef(k.oid) ~ 'tenant_id.*\^\(?T\[0-9\]') THEN
      RAISE 'FAIL 7b: % thiếu CHECK dạng tenant_id', r.table_name;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS 7b mọi bảng có CHECK dạng tenant_id';
END $$;
SET ROLE dh_integration_app;
SET app.tenant_id = 'T68';

-- 8. Chặn bí mật: lệnh worker, outbox, chứng thư, sự cố
DO $$ BEGIN
  INSERT INTO ph14_national.worker_command (id, tenant_id, command_type, target_type, target_code, params, requested_by, deadline_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'token.test', 'PLATFORM', 'ndxp-t68', '{"clientSecret":"DH-CANARY-123"}', 'an', now() + interval '1 minute', 'an', 'an');
  RAISE 'FAIL 8';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8 chặn khóa bí mật trong tham số lệnh worker';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.national.platform.changed.v1', 't68.national.platform.changed.v1', 'NationalPlatform', 'x', '{"token":"DH-CANARY"}', repeat('0', 32));
  RAISE 'FAIL 8b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8b sự kiện không mang bí mật';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.national.platform.changed.v1', 't01.national.platform.changed.v1', 'NationalPlatform', 'x', '{}', repeat('0', 32));
  RAISE 'FAIL 8c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8c topic phải thuộc đúng tenant (SEC-82)';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.national_certificate (id, tenant_id, code, purpose, subject, issuer, serial_number, fingerprint_sha256, not_before, not_after, key_ref, public_chain, uploaded_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'co-khoa-rieng', 'SIGNING', 'CN=x', 'CN=y', '02', repeat('e', 64), '2026-01-01Z', '2028-01-01Z', 'transit/keys/dh-t68-national-sign',
          '-----BEGIN PRIVATE KEY-----DH-CANARY-----END PRIVATE KEY-----', 'an', 'an', 'an');
  RAISE 'FAIL 8d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8d chứng thư không chứa khóa riêng (BR-14-004)';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.national_certificate (id, tenant_id, code, purpose, subject, issuer, serial_number, fingerprint_sha256, not_before, not_after, key_ref, public_chain, uploaded_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'tro-khoa-tenant-khac', 'SIGNING', 'CN=x', 'CN=y', '03', repeat('f', 64), '2026-01-01Z', '2028-01-01Z', 'transit/keys/dh-t01-national-sign', 'x', 'an', 'an', 'an');
  RAISE 'FAIL 8e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8e keyRef không trỏ sang khóa tenant khác (SEC-88)';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.signature_incident (id, tenant_id, platform_id, kind, direction, detail, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('p68'), 'SIGNATURE_MISMATCH', 'OUTBOUND', '{"body":"<xml/>"}', 'system', 'system');
  RAISE 'FAIL 8f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8f sự cố chữ ký không mang thân bản tin';
END $$;

-- 9. Bốn mắt
DO $$ BEGIN
  UPDATE ph14_national.national_platform SET state = 'ACTIVE', tested_at = now(), tested_connection_version = 1,
         activation_requested_by = 'an', activated_by = 'an', activated_at = now() WHERE id = pg_temp.u('p68');
  RAISE 'FAIL 9';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9 người duyệt bật nền tảng phải khác người đề nghị';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_platform SET state = 'ACTIVE', tested_at = now(), tested_connection_version = 1,
         activation_requested_by = 'an', activated_by = 'binh', activated_at = now() WHERE id = pg_temp.u('p68');
  RAISE NOTICE 'PASS 9b duyệt bởi người thứ hai thành công';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.approval_request SET status = 'APPROVED', decided_by = 'an', decided_at = now() WHERE id = pg_temp.u('ar68');
  RAISE 'FAIL 9c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9c người quyết định khác người đề nghị (ERR-14-007)';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.approval_request SET status = 'APPROVED', decided_by = 'an', decided_at = now(), requested_by = 'chi' WHERE id = pg_temp.u('ar68');
  RAISE 'FAIL 9d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9d người quyết định khác người sửa gần nhất (BR-14-022)';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.approval_request SET status = 'APPROVED', decided_by = 'binh', decided_at = now() WHERE id = pg_temp.u('ar68');
  UPDATE ph14_national.approval_request SET decision_note = 'sửa lại' WHERE id = pg_temp.u('ar68');
  RAISE 'FAIL 9e';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 9e yêu cầu đã quyết định thì bất biến';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.routing_rule (id, tenant_id, match_service_code, primary_service_code, priority, basis, state, requested_by, approved_by, approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'lltp-tra-trang-thai', 'lltp-tra-trang-thai', 100, 'Công văn hướng dẫn số 1', 'ACTIVE', 'an', 'an', now(), 'an', 'an');
  RAISE 'FAIL 9f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9f luật định tuyến ACTIVE cần người duyệt khác người đề nghị';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.quota_policy (id, tenant_id, platform_id, period, env, limit_count, basis_document, state, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('p68'), 'MONTH', 'PROD', 5000, 'Văn bản số 99/2026 ngày 02/06/2026', 'ACTIVE', 'an', 'an', 'an');
  RAISE 'FAIL 9g';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9g hạn mức môi trường thật cần người thứ hai duyệt';
END $$;

-- 10. Chính sách dịch vụ (BR-14-014, BR-14-008, BR-14-024)
DO $$ BEGIN
  UPDATE ph14_national.national_service SET cacheable = true, cache_ttl_seconds = 300 WHERE id = pg_temp.u('s68');
  RAISE 'FAIL 10';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10 không đệm dịch vụ SENSITIVE';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_service SET sensitivity = 'RESTRICTED', purpose_required = false WHERE id = pg_temp.u('s68');
  RAISE 'FAIL 10b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10b dịch vụ trả dữ liệu cá nhân bắt buộc mục đích';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_service SET reconcile_label = 'DISCONTINUED' WHERE id = pg_temp.u('s68w');
  RAISE 'FAIL 10c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10c nhãn Ngừng không đi cùng dịch vụ DRAFT hoặc ACTIVE';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_service SET state = 'RETIRED', retired_at = now() WHERE id = pg_temp.u('s68w');
  UPDATE ph14_national.national_service SET state = 'ACTIVE', retired_at = NULL WHERE id = pg_temp.u('s68w');
  RAISE 'FAIL 10d';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 10d RETIRED không đảo ngược';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.national_service (id, tenant_id, platform_id, code, national_service_code, name, service_group, protocol, operation_type, idempotent,
                                              sensitivity, purpose_required, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('p01'), 'sai-nen-tang', 'X', 'x', 'LLTP', 'REST', 'READ', NULL, 'PUBLIC', false, 'an', 'an');
  RAISE 'FAIL 10e';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 10e khóa ngoại kèm tenant: không trỏ nền tảng của tenant khác';
END $$;

-- 11. Đặc tả bất biến sau khi ACTIVE (ERR-14-010)
UPDATE ph14_national.service_spec SET state = 'ACTIVE', activated_by = 'an', activated_at = now() WHERE id = pg_temp.u('sp68');
DO $$ BEGIN
  UPDATE ph14_national.service_spec SET content = '{"openapi":"sửa"}' WHERE id = pg_temp.u('sp68');
  RAISE 'FAIL 11';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 11 đặc tả ACTIVE không sửa được nội dung';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.service_spec (id, tenant_id, service_id, spec_version, kind, checksum, contract_version, content, state, activated_by, activated_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('s68'), '1.1.0', 'OPENAPI', repeat('9', 64), '1.1', '{}', 'ACTIVE', 'an', now(), 'an', 'an');
  RAISE 'FAIL 11b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 11b mỗi dịch vụ một đặc tả ACTIVE';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.service_spec (id, tenant_id, service_id, spec_version, kind, checksum, contract_version, content, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('s68'), '1.0.0', 'OPENAPI', repeat('8', 64), '1.0', '{}', 'an', 'an');
  RAISE 'FAIL 11c';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 11c cùng specVersion khác nội dung bị từ chối';
END $$;
UPDATE ph14_national.service_spec SET state = 'SUPERSEDED', superseded_at = now() WHERE id = pg_temp.u('sp68');
DO $$ BEGIN
  INSERT INTO ph14_national.service_spec (id, tenant_id, service_id, spec_version, kind, checksum, contract_version, breaking, content, state, activated_by, activated_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('s68'), '2.0.0', 'OPENAPI', repeat('7', 64), '2.0', true, '{}', 'ACTIVE', 'an', now(), 'an', 'an');
  RAISE 'FAIL 11d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11d thay đổi phá vỡ chưa duyệt không ACTIVE được (ERR-14-012); chuyển SUPERSEDED thành công';
END $$;

-- 12. Chứng thư: một chứng thư ký hiện hành, bất biến, không xóa (BR-14-017, 019)
UPDATE ph14_national.national_certificate SET state = 'ACTIVE', activation_requested_by = 'an', activation_requested_at = now(),
       activation_approved_by = 'binh', activation_approved_at = now() WHERE id = pg_temp.u('c68');
DO $$ BEGIN
  INSERT INTO ph14_national.national_certificate (id, tenant_id, code, platform_id, purpose, subject, issuer, serial_number, fingerprint_sha256, not_before, not_after, key_ref, public_chain,
                                                  state, uploaded_by, activation_requested_by, activation_requested_at, activation_approved_by, activation_approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'tinh-t68-2027', pg_temp.u('p68'), 'BOTH', 'CN=T68', 'CN=CA', '04', repeat('1', 64), '2026-06-01Z', '2029-01-01Z', 'transit/keys/dh-t68-national-sign-2', 'x',
          'ACTIVE', 'an', 'an', now(), 'binh', now(), 'an', 'an');
  RAISE 'FAIL 12';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 12 mỗi (nền tảng, mục đích) một chứng thư ký hiện hành';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_certificate SET supersede_at = now() + interval '72 hours' WHERE id = pg_temp.u('c68');
  INSERT INTO ph14_national.national_certificate (id, tenant_id, code, platform_id, purpose, subject, issuer, serial_number, fingerprint_sha256, not_before, not_after, key_ref, public_chain,
                                                  state, uploaded_by, activation_requested_by, activation_requested_at, activation_approved_by, activation_approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'tinh-t68-2028', pg_temp.u('p68'), 'SIGNING', 'CN=T68', 'CN=CA', '05', repeat('2', 64), '2026-06-01Z', '2029-01-01Z', 'transit/keys/dh-t68-national-sign-3', 'x',
          'ACTIVE', 'an', 'an', now(), 'binh', now(), 'an', 'an');
  RAISE NOTICE 'PASS 12b chứng thư cũ đã đặt supersede_at nhường chỗ cho chứng thư mới trong thời gian chuyển tiếp';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_certificate SET subject = 'CN=Giả mạo' WHERE id = pg_temp.u('c68');
  RAISE 'FAIL 12c';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 12c không đổi chủ thể, khóa, chuỗi của chứng thư';
END $$;
DO $$ BEGIN
  DELETE FROM ph14_national.national_certificate WHERE id = pg_temp.u('c68');
  RAISE 'FAIL 12d';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 12d vai trò ứng dụng không xóa được chứng thư (BR-14-019)';
END $$;

-- 13. Hạn mức: tổng phân bổ không vượt hạn mức (ERR-14-018), căn cứ văn bản (BR-14-011)
DO $$ BEGIN
  INSERT INTO ph14_national.quota_policy (id, tenant_id, platform_id, period, env, limit_count, basis_document, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('p68'), 'HOUR', 'TEST', 100, 'ngắn', 'an', 'an');
  RAISE 'FAIL 13';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13 hạn mức phải có căn cứ văn bản ≥ 10 ký tự';
END $$;
BEGIN;
INSERT INTO ph14_national.quota_allocation (id, tenant_id, policy_id, system_code, service_code, limit_count, created_by, updated_by)
VALUES (pg_temp.u('qa1'), 'T68', pg_temp.u('q68'), 'HT-MOTCUA', 'lltp-tra-trang-thai', 600, 'an', 'an');
INSERT INTO ph14_national.quota_allocation (id, tenant_id, policy_id, system_code, service_code, limit_count, created_by, updated_by)
VALUES (pg_temp.u('qa2'), 'T68', pg_temp.u('q68'), 'HT-TUPHAP', 'lltp-tra-trang-thai', 400, 'an', 'an');
COMMIT;
DO $$ BEGIN
  INSERT INTO ph14_national.quota_allocation (id, tenant_id, policy_id, system_code, service_code, limit_count, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('q68'), 'HT-QLVB', 'lltp-tra-trang-thai', 1, 'an', 'an');
  SET CONSTRAINTS ALL IMMEDIATE;
  RAISE 'FAIL 13b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13b tổng phân bổ 1001 vượt hạn mức 1000';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.quota_allocation (id, tenant_id, policy_id, system_code, service_code, limit_count, unlimited, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('q68'), 'HT-QLVB', 'lltp-tra-trang-thai', 5, true, 'an', 'an');
  RAISE 'FAIL 13c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13c UNLIMITED không đi cùng giá trị trần';
END $$;

DO $$ BEGIN
  UPDATE ph14_national.quota_policy SET limit_count = 900 WHERE id = pg_temp.u('q68');
  SET CONSTRAINTS ALL IMMEDIATE;
  RAISE 'FAIL 13d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13d không hạ hạn mức xuống dưới tổng đã phân bổ (1000)';
END $$;

-- 14. Sổ giao dịch: chỉ đi tiến, không xóa, bất biến định danh (BR-14-020, BR-14-030)
DO $$ DECLARE v_state text; BEGIN
  UPDATE ph14_national.national_transaction SET state = 'SENT' WHERE tenant_id = 'T68' AND transaction_code = 'NAT-20261126-0000A1';
  UPDATE ph14_national.national_transaction SET state = 'SUCCEEDED', finished_at = now(), duration_ms = 120, sign_result = 'OK', verify_result = 'OK'
   WHERE tenant_id = 'T68' AND transaction_code = 'NAT-20261126-0000A1';
  SELECT state INTO v_state FROM ph14_national.national_transaction WHERE transaction_code = 'NAT-20261126-0000A1';
  IF v_state <> 'SUCCEEDED' THEN RAISE 'FAIL 14'; END IF;
  RAISE NOTICE 'PASS 14 giao dịch chuyển RECEIVED, SENT, SUCCEEDED';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_transaction SET state = 'SENT', finished_at = NULL WHERE transaction_code = 'NAT-20261126-0000A1';
  RAISE 'FAIL 14b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 14b giao dịch không lùi trạng thái';
END $$;
INSERT INTO ph14_national.national_transaction (tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, state, trace_id)
VALUES ('T68', 'NAT-20261126-0000D4', now(), 'OUTBOUND', 'ndxp-t68', 'lltp-tra-trang-thai', 'READ', 'HT-MOTCUA', 'RECEIVED', repeat('0', 32));
DO $$ BEGIN
  UPDATE ph14_national.national_transaction SET system_code = 'HT-KHAC', state = 'SENT' WHERE transaction_code = 'NAT-20261126-0000D4';
  RAISE 'FAIL 14c';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 14c HTTT và mục đích của giao dịch bất biến';
END $$;
DO $$ BEGIN
  DELETE FROM ph14_national.national_transaction WHERE transaction_code = 'NAT-20261126-0000A1';
  RAISE 'FAIL 14d';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 14d vai trò ứng dụng không xóa được giao dịch';
END $$;
DO $$ DECLARE v_state text; v_n int; BEGIN
  -- UPSERT của LedgerConsumer: bản ghi RECEIVED giao lại muộn không kéo giao dịch lùi
  INSERT INTO ph14_national.national_transaction (tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, state, trace_id)
  SELECT tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, 'RECEIVED', trace_id
    FROM ph14_national.national_transaction WHERE transaction_code = 'NAT-20261126-0000A1'
  ON CONFLICT (tenant_id, transaction_code, started_at) DO UPDATE SET state = EXCLUDED.state
    WHERE EXCLUDED.state_rank > ph14_national.national_transaction.state_rank;
  SELECT state, (SELECT count(*) FROM ph14_national.national_transaction WHERE transaction_code = 'NAT-20261126-0000A1')
    INTO v_state, v_n FROM ph14_national.national_transaction WHERE transaction_code = 'NAT-20261126-0000A1';
  IF v_state <> 'SUCCEEDED' OR v_n <> 1 THEN RAISE 'FAIL 14e: % %', v_state, v_n; END IF;
  RAISE NOTICE 'PASS 14e UPSERT theo hạng: bản đến muộn bị bỏ, không nhân đôi dòng';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.national_transaction (tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, state, trace_id)
  VALUES ('T68', 'NAT-20261126-0000B2', now(), 'OUTBOUND', 'ndxp-t68', 'lltp-tra-trang-thai', 'READ', 'HT-MOTCUA', 'UNKNOWN_RESULT', repeat('0', 32));
  RAISE 'FAIL 14f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14f UNKNOWN_RESULT chỉ cho thao tác ghi';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.national_transaction (tenant_id, transaction_code, started_at, direction, platform_code, service_code, operation_type, system_code, state, from_cache, finished_at, trace_id)
  VALUES ('T68', 'NAT-20261126-0000C3', now(), 'OUTBOUND', 'ndxp-t68', 'hotich-dang-ky-khai-sinh', 'WRITE', 'HT-MOTCUA', 'COMPLETED_CACHE', true, now(), repeat('0', 32));
  RAISE 'FAIL 14g';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14g không đệm thao tác ghi (BR-14-014)';
END $$;

-- 15. Chiều vào (BR-14-027)
DO $$ BEGIN
  INSERT INTO ph14_national.inbound_endpoint (id, tenant_id, code, platform_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ndxp-vao-t01', pg_temp.u('p68'), 'an', 'an');
  RAISE 'FAIL 15';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15 mã điểm cuối phải kết thúc bằng mã tenant của chính nó';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.inbound_endpoint (id, tenant_id, code, platform_id, signature_required, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ndxp-vao-khong-ky-t68', pg_temp.u('p68'), false, 'an', 'an');
  RAISE 'FAIL 15b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15b tắt yêu cầu chữ ký cần lý do và SO đồng ý';
END $$;
INSERT INTO ph14_national.inbound_endpoint (id, tenant_id, code, platform_id, created_by, updated_by)
VALUES (pg_temp.u('ie68'), 'T68', 'ndxp-vao-t68', pg_temp.u('p68'), 'an', 'an');
DO $$ BEGIN
  UPDATE ph14_national.inbound_endpoint SET state = 'ACTIVE', activation_requested_by = 'an', activation_approved_by = 'binh', activation_approved_at = now() WHERE id = pg_temp.u('ie68');
  RAISE 'FAIL 15c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15c bật điểm cuối khi chưa có nguồn được phép bị chặn (ERR-14-024)';
END $$;
INSERT INTO ph14_national.allowed_sender (id, tenant_id, endpoint_id, sender_code, cert_fingerprint, service_codes, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.u('ie68'), 'NDXP-QG', repeat('a', 64), ARRAY['nhan-ho-so-lltp'], 'an', 'an');
INSERT INTO ph14_national.inbound_route (id, tenant_id, endpoint_id, service_code, flow_code, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.u('ie68'), 'nhan-ho-so-lltp', 'lltp-nhan-ho-so', 'an', 'an');
DO $$ BEGIN
  UPDATE ph14_national.inbound_endpoint SET state = 'ACTIVE', activation_requested_by = 'an', activation_approved_by = 'binh', activation_approved_at = now() WHERE id = pg_temp.u('ie68');
  IF (SELECT path FROM ph14_national.inbound_endpoint WHERE id = pg_temp.u('ie68')) <> '/inbound/v1/ndxp-vao-t68' THEN RAISE 'FAIL 15d'; END IF;
  RAISE NOTICE 'PASS 15d đủ nguồn và tuyến thì bật được; đường dẫn sinh /inbound/v1/{mã}';
END $$;

-- 16. Đồng bộ (ERR-14-026), đối soát số liệu
INSERT INTO ph14_national.sync_run (id, tenant_id, platform_id, kind, trigger_kind, state, triggered_by, created_by, updated_by)
VALUES (pg_temp.u('sr1'), 'T68', pg_temp.u('p68b'), 'SERVICE_CATALOG', 'MANUAL', 'RUNNING', 'an', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph14_national.sync_run (id, tenant_id, platform_id, kind, trigger_kind, state, triggered_by, created_by, updated_by)
  VALUES (pg_temp.u('sr2'), 'T68', pg_temp.u('p68b'), 'SERVICE_CATALOG', 'SCHEDULE', 'PLANNED', 'system', 'system', 'system');
  RAISE 'FAIL 16';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 16 mỗi (tenant, loại) tối đa một phiên chưa kết thúc';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.sync_run SET state = 'COMPLETED', sent = 10, accepted = 9, rejected = 0, pending = 0, finished_at = now() WHERE id = pg_temp.u('sr1');
  RAISE 'FAIL 16b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16b phiên kết thúc phải đối soát gửi = nhận + từ chối + chờ';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.sync_run SET state = 'COMPLETED_WITH_ERRORS', sent = 10, accepted = 8, rejected = 2, pending = 0, error_count = 1, finished_at = now() WHERE id = pg_temp.u('sr1');
  RAISE NOTICE 'PASS 16c phiên có lỗi đối soát khớp được ghi nhận';
END $$;

-- 17. Chạy song song chỉ thao tác đọc (BR-14-033), đóng phiên cần xác nhận thu hồi khóa cũ (BR-14-034)
DO $$ BEGIN
  INSERT INTO ph14_national.parallel_run (id, tenant_id, service_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'hotich-dang-ky-khai-sinh', 'an', 'an');
  RAISE 'FAIL 17';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17 không chạy song song cho thao tác ghi (ERR-14-033)';
END $$;
INSERT INTO ph14_national.parallel_run (id, tenant_id, service_code, created_by, updated_by) VALUES (pg_temp.u('pr68'), 'T68', 'lltp-tra-trang-thai', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph14_national.parallel_run (id, tenant_id, service_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'lltp-tra-trang-thai', 'an', 'an');
  RAISE 'FAIL 17b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 17b mỗi dịch vụ một phiên chạy song song đang chạy';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.parallel_run SET state = 'CLOSED', closed_by = 'an', closed_at = now() WHERE id = pg_temp.u('pr68');
  RAISE 'FAIL 17c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17c đóng phiên khi chưa xác nhận thu hồi khóa cũ bị chặn (ERR-14-004)';
END $$;
DO $$ DECLARE v numeric; BEGIN
  UPDATE ph14_national.parallel_run SET samples = 1000, matched = 995 WHERE id = pg_temp.u('pr68');
  SELECT match_ratio INTO v FROM ph14_national.parallel_run WHERE id = pg_temp.u('pr68');
  IF v <> 0.995 THEN RAISE 'FAIL 17d: %', v; END IF;
  RAISE NOTICE 'PASS 17d tỷ lệ khớp sinh tự động 0,995';
END $$;

-- 18. Cảnh báo bất thường: không lưu định danh, kết thúc cần lý do (FR-14-053)
DO $$ BEGIN
  INSERT INTO ph14_national.anomaly_alert (id, tenant_id, system_code, service_code, rule, window_start, window_end, evidence, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'HT-MOTCUA', 'bhxh-tra-ho-gia-dinh', 'MASS_LOOKUP', now() - interval '1 hour', now(), '{"citizenId":"012345678901"}', 'system', 'system');
  RAISE 'FAIL 18';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18 bằng chứng cảnh báo không mang định danh đối tượng';
END $$;
INSERT INTO ph14_national.anomaly_alert (id, tenant_id, system_code, service_code, rule, window_start, window_end, evidence, created_by, updated_by)
VALUES (pg_temp.u('al68'), 'T68', 'HT-MOTCUA', 'bhxh-tra-ho-gia-dinh', 'MASS_LOOKUP', now() - interval '1 hour', now(), '{"distinctSubjects":812}', 'system', 'system');
DO $$ BEGIN
  INSERT INTO ph14_national.anomaly_alert (id, tenant_id, system_code, service_code, rule, window_start, window_end, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'HT-MOTCUA', 'bhxh-tra-ho-gia-dinh', 'MASS_LOOKUP', now() - interval '1 hour', now(), 'system', 'system');
  RAISE 'FAIL 18b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 18b mỗi (HTTT, dịch vụ, luật) một cảnh báo OPEN';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.anomaly_alert SET state = 'RESOLVED', decision = 'CONFIRMED_LEGITIMATE', decided_by = 'so1', decided_at = now(), decision_reason = 'ngắn' WHERE id = pg_temp.u('al68');
  RAISE 'FAIL 18c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18c kết thúc cảnh báo cần lý do ≥ 10 ký tự (ERR-14-003)';
END $$;

-- 19. Xoay thông tin xác thực: một lần xoay mở mỗi (nền tảng, môi trường); DONE cần biên nhận thu hồi
INSERT INTO ph14_national.credential_rotation (id, tenant_id, platform_id, env, started_by, created_by, updated_by)
VALUES (pg_temp.u('cr1'), 'T68', pg_temp.u('p68'), 'PROD', 'an', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph14_national.credential_rotation (id, tenant_id, platform_id, env, started_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('p68'), 'PROD', 'binh', 'binh', 'binh');
  RAISE 'FAIL 19';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 19 một lần xoay mở mỗi (nền tảng, môi trường)';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.credential_rotation SET state = 'DONE', done_at = now(), pending_secret_version = 3, tested_at = now(), switched_at = now() - interval '1 day',
         overlap_until = now() WHERE id = pg_temp.u('cr1');
  RAISE 'FAIL 19b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 19b hoàn tất xoay phải có biên nhận thu hồi khóa cũ';
END $$;

-- 20. Luật định tuyến: chuyển hướng dự phòng chỉ cho thao tác đọc (BR-14-023); không trùng (điều kiện, priority)
DO $$ BEGIN
  INSERT INTO ph14_national.routing_rule (id, tenant_id, match_group, operation_type, primary_service_code, fallback_service_code, allow_fallback, priority, basis, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'HO_TICH', 'WRITE', 'a-dich-vu', 'b-dich-vu', true, 10, 'Công văn hướng dẫn số 2', 'an', 'an');
  RAISE 'FAIL 20';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20 không chuyển hướng dự phòng cho thao tác ghi';
END $$;
DO $$ BEGIN
  INSERT INTO ph14_national.routing_rule (id, tenant_id, match_group, operation_type, primary_service_code, priority, basis, state, requested_by, approved_by, approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'LLTP', 'READ', 'lltp-a', 100, 'Công văn hướng dẫn số 3', 'ACTIVE', 'an', 'binh', now(), 'an', 'an');
  INSERT INTO ph14_national.routing_rule (id, tenant_id, match_group, operation_type, primary_service_code, priority, basis, state, requested_by, approved_by, approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'LLTP', 'READ', 'lltp-b', 100, 'Công văn hướng dẫn số 4', 'ACTIVE', 'an', 'binh', now(), 'an', 'an');
  RAISE 'FAIL 20b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 20b không trùng (điều kiện, priority) trong luật ACTIVE (ERR-14-013)';
END $$;

-- 21. Chuỗi tin cậy: tệp CRL phải ở tiền tố tenant
DO $$ BEGIN
  INSERT INTO ph14_national.trust_anchor (id, tenant_id, code, name, anchor_kind, subject, issuer, fingerprint_sha256, not_after, pem, crl_ref, crl_sha256, created_by, updated_by, uploaded_by)
  VALUES (gen_random_uuid(), 'T68', 'ca-goc', 'CA gốc', 'ROOT', 'CN=Root', 'CN=Root', repeat('3', 64), '2036-01-01Z', 'x', 't01/crl/root.crl', repeat('4', 64), 'an', 'an', 'an');
  RAISE 'FAIL 21';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 21 khóa đối tượng CRL phải bắt đầu bằng tiền tố tenant';
END $$;

-- 22. Sự cố chữ ký: không kết thúc khi chưa xác nhận; kết luận ≥ 10 ký tự
INSERT INTO ph14_national.signature_incident (id, tenant_id, platform_id, kind, direction, transaction_code, created_by, updated_by)
VALUES (pg_temp.u('si68'), 'T68', pg_temp.u('p68'), 'SIGNATURE_MISMATCH', 'OUTBOUND', 'NAT-20261126-0000A1', 'system', 'system');
DO $$ BEGIN
  UPDATE ph14_national.signature_incident SET state = 'RESOLVED', resolved_by = 'so1', resolved_at = now(), conclusion = 'Đã làm mới chuỗi tin cậy' WHERE id = pg_temp.u('si68');
  RAISE 'FAIL 22';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22 kết thúc sự cố chữ ký phải qua bước xác nhận';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.signature_incident SET kind = 'REPLAY' WHERE id = pg_temp.u('si68');
  RAISE 'FAIL 22b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 22b loại sự cố bất biến';
END $$;

-- 23. Cung cấp lại: mỗi dịch vụ một cung cấp lại, đường dẫn đúng mẫu
INSERT INTO ph14_national.service_exposure (id, tenant_id, service_id, path, contract_version, response_fields, request_id, created_by, updated_by)
VALUES (pg_temp.u('ex68'), 'T68', pg_temp.u('s68'), '/quoc-gia/tu-phap/lltp/trang-thai', '1.0', ARRAY['trangThai', 'ngayCapNhat'], gen_random_uuid(), 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph14_national.service_exposure (id, tenant_id, service_id, path, contract_version, response_fields, request_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('s68'), '/quoc-gia/tu-phap/lltp/khac', '1.0', ARRAY['a'], gen_random_uuid(), 'an', 'an');
  RAISE 'FAIL 23';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 23 mỗi dịch vụ tối đa một cung cấp lại';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.service_exposure SET state = 'ACTIVE' WHERE id = pg_temp.u('ex68');
  RAISE 'FAIL 23b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 23b cung cấp lại ACTIVE phải có mã API của PH-02';
END $$;

-- 24. Bất đồng bộ: khóa chống trùng ULID
DO $$ BEGIN
  INSERT INTO ph14_national.async_request (id, tenant_id, service_code, system_code, priority, idempotency_key, payload_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'hotich-dang-ky-khai-sinh', 'HT-MOTCUA', 'ESSENTIAL', 'khong-phai-ulid', repeat('a', 64), now() + interval '72 hours', 'system', 'system');
  RAISE 'FAIL 24';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 24 Idempotency-Key phải là ULID';
END $$;
INSERT INTO ph14_national.async_request (id, tenant_id, service_code, system_code, priority, idempotency_key, payload_hash, expires_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', 'hotich-dang-ky-khai-sinh', 'HT-MOTCUA', 'ESSENTIAL', '01JD8Z3K9Q4R5T6V7W8X9Y0ABC', repeat('a', 64), now() + interval '72 hours', 'system', 'system');
DO $$ BEGIN
  INSERT INTO ph14_national.async_request (id, tenant_id, service_code, system_code, priority, idempotency_key, payload_hash, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'hotich-dang-ky-khai-sinh', 'HT-MOTCUA', 'ESSENTIAL', '01JD8Z3K9Q4R5T6V7W8X9Y0ABC', repeat('b', 64), now() + interval '72 hours', 'system', 'system');
  RAISE 'FAIL 24b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 24b cùng khóa chống trùng của cùng HTTT bị từ chối (ERR-14-116)';
END $$;

-- 24c. Bẫy NULL trong CHECK: giá trị thiếu không được lọt qua
DO $$ BEGIN
  INSERT INTO ph14_national.national_service (id, tenant_id, platform_id, code, national_service_code, name, service_group, protocol, operation_type, sensitivity, cacheable, purpose_required, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.u('p68'), 'tra-cuu-cong-khai', 'TRA_CUU', 'Tra cứu công khai', 'VBQPPL', 'REST', 'READ', 'PUBLIC', true, false, 'an', 'an');
  RAISE 'FAIL 24c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 24c dịch vụ cacheable bắt buộc có cacheTtlSeconds';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.signature_incident SET state = 'RESOLVED', acknowledged_by = 'so1', acknowledged_at = now(), resolved_by = 'so1', resolved_at = now(), conclusion = NULL
   WHERE id = pg_temp.u('si68');
  RAISE 'FAIL 24d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 24d kết thúc sự cố chữ ký thiếu kết luận bị chặn (ERR-14-003)';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.credential_rotation SET state = 'DONE', done_at = now(), pending_secret_version = 3, tested_at = now(), switched_at = now() - interval '1 day',
         overlap_until = now(), revocation_confirmed_by = 'an', revocation_confirmed_at = now(), revocation_receipt = NULL WHERE id = pg_temp.u('cr1');
  RAISE 'FAIL 24e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 24e hoàn tất xoay thiếu biên nhận bị chặn dù đã có người xác nhận';
END $$;

-- 25. Quyền theo vai trò: ứng dụng không xóa sổ giao dịch, không sửa outbox; phân vùng không đọc trực tiếp
DO $$ BEGIN
  UPDATE ph14_national.outbox SET aggregate_id = 'x';
  RAISE 'FAIL 25';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 25 outbox chỉ thêm, ứng dụng không sửa';
END $$;
DO $$ DECLARE p text; n bigint; BEGIN
  SELECT c.oid::regclass::text INTO p FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid JOIN pg_class pa ON pa.oid = i.inhparent
   WHERE pa.relname = 'national_transaction' ORDER BY c.relname LIMIT 1;
  EXECUTE 'SELECT count(*) FROM ' || p INTO n;
  RAISE 'FAIL 25b: đọc được phân vùng %', p;
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 25b không đọc thẳng phân vùng (chỉ qua bảng cha, có RLS)';
END $$;
DO $$ DECLARE n_before int; n_after int; BEGIN
  SELECT count(*) INTO n_before FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'quota_usage';
  CALL ph14_national.p_ensure_month_partitions('ph14_national.quota_usage', current_date, 9);
  SELECT count(*) INTO n_after FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'quota_usage';
  IF n_after <= n_before THEN RAISE 'FAIL 25c: % → %', n_before, n_after; END IF;
  INSERT INTO ph14_national.quota_usage (tenant_id, platform_id, env, service_key, period, bucket_start, used, reset_at)
  VALUES ('T68', pg_temp.u('p68'), 'TEST', '', 'DAY', date_trunc('day', now()), 10, date_trunc('day', now()) + interval '1 day');
  RAISE NOTICE 'PASS 25c ứng dụng tạo được phân vùng mới qua thủ tục có quyền chủ sở hữu (% → % phân vùng)', n_before, n_after;
END $$;
DO $$ BEGIN
  CALL ph14_national.p_enable_rls('ph14_national.shedlock', 'P');
  RAISE 'FAIL 25d';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 25d ứng dụng không gọi được thủ tục bật RLS';
END $$;

-- 26. Vai trò báo cáo: đọc được, không ghi, không đọc lookup_key_hash và nội dung đặc tả
RESET ROLE;
SET ROLE dh_report_ro;
SET app.tenant_id = 'T68';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph14_national.national_transaction; IF n < 1 THEN RAISE 'FAIL 26: báo cáo không đọc được sổ giao dịch'; END IF;
  SELECT count(transaction_code) INTO n FROM ph14_national.national_transaction;
  RAISE NOTICE 'PASS 26 vai trò báo cáo đọc được sổ giao dịch (đã lọc RLS)';
END $$;
DO $$ BEGIN
  PERFORM lookup_key_hash FROM ph14_national.national_transaction;
  RAISE 'FAIL 26b';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 26b báo cáo không đọc được lookup_key_hash';
END $$;
DO $$ BEGIN
  PERFORM content FROM ph14_national.service_spec;
  RAISE 'FAIL 26c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 26c báo cáo không đọc được nội dung đặc tả';
END $$;
DO $$ BEGIN
  UPDATE ph14_national.national_platform SET name = 'x';
  RAISE 'FAIL 26d';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 26d vai trò báo cáo không ghi được';
END $$;
SET app.tenant_id = 'T01';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph14_national.national_transaction; IF n <> 0 THEN RAISE 'FAIL 26e'; END IF;
  RAISE NOTICE 'PASS 26e vai trò báo cáo cũng bị RLS theo tenant';
END $$;

RESET ROLE;
\echo 'Hoàn tất: mọi khối PASS'
