-- =============================================================================
-- D03-03-PH03 · Kiểm thử DDL ph03_gateway: cô lập tenant, bốn mắt, máy trạng thái,
-- bất biến mã và ảnh chụp, không lưu bí mật, chỉ thêm, quyền theo vai trò.
-- Chạy sau ph03_gateway.sql trên CSDL có schema (dữ liệu giả, tự hoàn tác):
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph03_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE dừng tệp.
-- Toàn bộ dữ liệu thử nằm trong một giao dịch và bị ROLLBACK ở cuối.
-- Tương ứng nhóm ca cô lập tenant, tách nhiệm, chống lộ bí mật của D05-02-PH03.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_connect_app') THEN
    CREATE ROLE dh_connect_app NOLOGIN NOBYPASSRLS IN ROLE ph03_app;
  ELSE
    GRANT ph03_app TO dh_connect_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_gateway_report') THEN
    CREATE ROLE dh_gateway_report NOLOGIN NOBYPASSRLS IN ROLE ph03_readonly;
  ELSE
    GRANT ph03_readonly TO dh_gateway_report;
  END IF;
END $$;

BEGIN;
SET ROLE dh_connect_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
GRANT SELECT ON ids TO PUBLIC;   -- để phiên SET LOCAL ROLE ph03_owner cũng tra được
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY[
  'h68','u68','n68','r68','c68','k68','p68','s68','x68','cr68ok','cr68pend','snap68','ev68','vp68',
  'h01','u01','r01','c01','snap01','h68b','r68ext']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
INSERT INTO ph03_gateway.edge_host (id, tenant_id, host_pattern, created_by, updated_by)
VALUES (pg_temp.id('h68'), 'T68', 't68.api.datahub.gov.vn', 'an', 'an');
INSERT INTO ph03_gateway.upstream (id, tenant_id, upstream_code, name, created_by, updated_by)
VALUES (pg_temp.id('u68'), 'T68', 'up.t68.ho-tich', 'Backend hộ tịch', 'an', 'an');
INSERT INTO ph03_gateway.upstream_node (id, tenant_id, upstream_id, host, port, created_by, updated_by)
VALUES (pg_temp.id('n68'), 'T68', pg_temp.id('u68'), 'ho-tich.t68.svc', 8443, 'an', 'an');
INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, created_by, updated_by)
VALUES (pg_temp.id('r68'), 'T68', 'tra-cuu-ho-tich.v1', 'tra-cuu-ho-tich', 'v1', pg_temp.id('h68'), '/ho-tich/v1/*', '{GET}', pg_temp.id('u68'), 'RESTRICTED', 'an', 'an');
INSERT INTO ph03_gateway.consumer (id, tenant_id, consumer_code, system_code, auth_method, created_by, updated_by)
VALUES (pg_temp.id('c68'), 'T68', 'ht-qlvb', 'HT-QLVB', 'MTLS', 'an', 'an');
INSERT INTO ph03_gateway.consumer_credential (id, tenant_id, consumer_id, kind, cert_thumbprint, cert_not_after, created_by, updated_by)
VALUES (pg_temp.id('k68'), 'T68', pg_temp.id('c68'), 'CERT', repeat('a', 64), now() + interval '300 days', 'an', 'an');
INSERT INTO ph03_gateway.plan_policy (id, tenant_id, policy_code, plan_code, api_code, security_mode, rate_limits, quotas, created_by, updated_by)
VALUES (pg_temp.id('p68'), 'T68', 'ho-tich-goi-chuan', 'goi-chuan', 'tra-cuu-ho-tich', 'MTLS', '{"second":20,"minute":600}', '{"hour":20000,"day":200000}', 'an', 'an');
INSERT INTO ph03_gateway.subscription_ref (id, tenant_id, consumer_id, route_id, plan_policy_id, source_ref, created_by, updated_by)
VALUES (pg_temp.id('s68'), 'T68', pg_temp.id('c68'), pg_temp.id('r68'), pg_temp.id('p68'), 'sub-001', 'an', 'an');
INSERT INTO ph03_gateway.waf_exception (id, tenant_id, route_id, rule_id, reason, requested_by, expires_at, created_by, updated_by)
VALUES (pg_temp.id('x68'), 'T68', pg_temp.id('r68'), '942100', 'Tham số tìm kiếm chứa dấu nháy hợp lệ', 'to1', now() + interval '30 days', 'to1', 'to1');
INSERT INTO ph03_gateway.config_snapshot (id, tenant_id, site, scope, trigger_type, content_hash, requested_by, created_by, updated_by)
VALUES (pg_temp.id('snap68'), 'T68', 'dc1', 'TENANT', 'EVENT', repeat('c', 64), 'system:build', 'system:build', 'system:build');
INSERT INTO ph03_gateway.change_request (id, tenant_id, change_type, target_type, target_code, reason, requested_by, created_by, updated_by)
VALUES (pg_temp.id('cr68pend'), 'T68', 'ROUTE_EXPOSURE_EXT', 'ROUTE', 'tra-cuu-ho-tich.v1', 'Mở cho nhà cung cấp thanh toán gọi callback', 'so1', 'so1', 'so1');
INSERT INTO ph03_gateway.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
VALUES (gen_random_uuid(), 'T68', 'vn.datahub.gateway.route.state-changed.v1', 't68.gateway.route.state-changed.v1', 'Route', 'tra-cuu-ho-tich.v1', '{"to":"ACTIVE"}', repeat('0', 32));

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
INSERT INTO ph03_gateway.edge_host (id, tenant_id, host_pattern, created_by, updated_by)
VALUES (pg_temp.id('h01'), 'T01', 't01.api.datahub.gov.vn', 'lan', 'lan');
INSERT INTO ph03_gateway.upstream (id, tenant_id, upstream_code, name, created_by, updated_by)
VALUES (pg_temp.id('u01'), 'T01', 'up.t01.ho-tich', 'Backend hộ tịch T01', 'lan', 'lan');
INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, created_by, updated_by)
VALUES (pg_temp.id('r01'), 'T01', 'tra-cuu-ho-tich.v1', 'tra-cuu-ho-tich', 'v1', pg_temp.id('h01'), '/ho-tich/v1/*', '{GET}', pg_temp.id('u01'), 'INTERNAL', 'lan', 'lan');
INSERT INTO ph03_gateway.consumer (id, tenant_id, consumer_code, system_code, auth_method, created_by, updated_by)
VALUES (pg_temp.id('c01'), 'T01', 'ht-qlvb', 'HT-QLVB', 'OAUTH2', 'lan', 'lan');

-- ============ A. Cô lập tenant ============
-- 1. Cô lập đọc: T01 chỉ thấy dòng của mình trên mọi bảng đã nhập
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph03_gateway.route; IF n <> 1 THEN RAISE 'FAIL 1: T01 thấy % route', n; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.edge_host; IF n <> 1 THEN RAISE 'FAIL 1b: % host', n; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.upstream; IF n <> 1 THEN RAISE 'FAIL 1c'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.upstream_node; IF n <> 0 THEN RAISE 'FAIL 1d'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.consumer; IF n <> 1 THEN RAISE 'FAIL 1e'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.consumer_credential; IF n <> 0 THEN RAISE 'FAIL 1f'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.plan_policy; IF n <> 0 THEN RAISE 'FAIL 1g'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.subscription_ref; IF n <> 0 THEN RAISE 'FAIL 1h'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.waf_exception; IF n <> 0 THEN RAISE 'FAIL 1i'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.config_snapshot; IF n <> 0 THEN RAISE 'FAIL 1j'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.change_request; IF n <> 0 THEN RAISE 'FAIL 1k'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.outbox; IF n <> 0 THEN RAISE 'FAIL 1l'; END IF;
  RAISE NOTICE 'PASS 1 T01 không đọc được dữ liệu T68 ở 12 bảng';
END $$;

-- 2. Cô lập ghi: T01 chèn dòng mang tenant T68
DO $$ BEGIN
  INSERT INTO ph03_gateway.consumer (id, tenant_id, consumer_code, system_code, auth_method, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'gia-mao', 'X', 'OAUTH2', 'lan', 'lan');
  RAISE 'FAIL 2';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn chèn chéo tenant';
END $$;

-- 3. Cô lập sửa: UPDATE dòng T68 từ phiên T01 không ảnh hưởng dòng nào
DO $$ DECLARE n int; BEGIN
  UPDATE ph03_gateway.route SET priority = 9 WHERE route_code = 'tra-cuu-ho-tich.v1' AND tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  RAISE NOTICE 'PASS 3 không sửa được dòng tenant khác';
END $$;

-- 4. Biến phiên rỗng: không thấy dòng nào
DO $$ DECLARE n int; BEGIN
  PERFORM set_config('app.tenant_id', '', true);
  SELECT count(*) INTO n FROM ph03_gateway.route; IF n <> 0 THEN RAISE 'FAIL 4'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.consumer; IF n <> 0 THEN RAISE 'FAIL 4b'; END IF;
  RAISE NOTICE 'PASS 4 biến phiên rỗng: 0 dòng';
END $$;
SET app.tenant_id = 'T01';

-- 5. Tenant COMMON không ghi được dòng COMMON ở bảng riêng (mẫu P) và không đọc được
DO $$ BEGIN
  INSERT INTO ph03_gateway.edge_host (id, tenant_id, host_pattern, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'nen-tang.datahub.gov.vn', 'lan', 'lan');
  RAISE 'FAIL 5';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 5 tenant không ghi được dòng COMMON';
END $$;

-- 6. Mẫu S: tenant đọc 66 tham số COMMON nhưng không ghi được
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph03_gateway.param_definition; IF n <> 66 THEN RAISE 'FAIL 6: thấy % tham số', n; END IF;
  RAISE NOTICE 'PASS 6 T01 đọc 66 tham số gw.* của nền tảng';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.param_definition (id, tenant_id, param_key, value_type, default_value, description, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'gw.gia.mao', 'INT', '1', 'x', 'lan', 'lan');
  RAISE 'FAIL 6b';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 6b tenant không thêm được tham số nền tảng';
END $$;
DO $$ DECLARE n int; BEGIN
  UPDATE ph03_gateway.param_definition SET default_value = '1' WHERE param_key = 'gw.ip.maxConnections';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 6c'; END IF;
  RAISE NOTICE 'PASS 6c tenant không sửa được mặc định nền tảng';
END $$;

-- 7. Chứng thư dùng chung (mẫu S): PLATFORM ghi ở COMMON, tenant đọc không ghi
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph03_gateway.edge_certificate (id, tenant_id, cert_code, subject, hosts, issuer, fingerprint, not_before, not_after, source, secret_ref, created_by, updated_by)
VALUES (gen_random_uuid(), 'COMMON', 'wildcard-datahub', 'CN=*.datahub.gov.vn', '{*.datahub.gov.vn}', 'CA Quốc gia', repeat('d', 64),
        now() - interval '30 days', now() + interval '335 days', 'CERT_MANAGER', 'kv/dh/common/edge-cert/wildcard', 'platform', 'platform');
INSERT INTO ph03_gateway.waf_virtual_patch (id, tenant_id, patch_code, scope, rule_text, reason, requested_by, expires_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'COMMON', 'vp-chung-001', 'PLATFORM', 'SecRule REQUEST_URI "@contains /actuator" "id:9900001,phase:1,deny,status:403"', 'Chặn đường dẫn quản trị lộ ra ngoài', 'pa1', now() + interval '30 days', 'pa1', 'pa1');
SET app.tenant_id = 'T01';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph03_gateway.edge_certificate WHERE tenant_id = 'COMMON'; IF n <> 1 THEN RAISE 'FAIL 7'; END IF;
  SELECT count(*) INTO n FROM ph03_gateway.waf_virtual_patch WHERE tenant_id = 'COMMON'; IF n <> 1 THEN RAISE 'FAIL 7b'; END IF;
  UPDATE ph03_gateway.edge_certificate SET state = 'EXPIRING' WHERE tenant_id = 'COMMON';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 7c'; END IF;
  RAISE NOTICE 'PASS 7 tenant đọc chứng thư và luật vá dùng chung, không sửa được';
END $$;

-- 8. Host duy nhất toàn cục (BR-03-026): T01 không đăng ký host của T68, route không trỏ host của tenant khác
DO $$ BEGIN
  INSERT INTO ph03_gateway.edge_host (id, tenant_id, host_pattern, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 't68.api.datahub.gov.vn', 'lan', 'lan');
  RAISE 'FAIL 8';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 8 một host chỉ thuộc một tenant';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'khac.v1', 'khac', 'v1', pg_temp.id('h68'), '/khac/*', '{GET}', pg_temp.id('u01'), 'INTERNAL', 'lan', 'lan');
  RAISE 'FAIL 8b';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 8b route không trỏ được host của tenant khác (khóa ngoại kèm tenant_id)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'khac.v1', 'khac', 'v1', pg_temp.id('h01'), '/khac/*', '{GET}', pg_temp.id('u68'), 'INTERNAL', 'lan', 'lan');
  RAISE 'FAIL 8c';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 8c route không trỏ được upstream của tenant khác';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'trung.v1', 'tra-cuu-ho-tich', 'v1', pg_temp.id('h01'), '/ho-tich/v1/*', '{GET}', pg_temp.id('u01'), 'INTERNAL', 'lan', 'lan');
  RAISE 'FAIL 8d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 8d hai route cùng host, đường dẫn, phương thức bị chặn (CHK-05)';
END $$;

-- ============ B. Mã bất biến, xóa mềm ============
DO $$ BEGIN
  UPDATE ph03_gateway.route SET route_code = 'doi-ten.v1' WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 9';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 9 mã route bất biến';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.consumer SET consumer_code = 'doi-ten' WHERE id = pg_temp.id('c01');
  RAISE 'FAIL 9b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 9b mã consumer bất biến';
END $$;
DO $$ BEGIN
  DELETE FROM ph03_gateway.route WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 9c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 9c ứng dụng không có quyền DELETE route (xóa mềm, BR-03-029)';
END $$;
DO $$ BEGIN
  SET LOCAL ROLE ph03_owner;
  DELETE FROM ph03_gateway.route WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 9d';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 9d chủ schema cũng bị trigger tg_no_delete chặn';
END $$;
SET ROLE dh_connect_app;
SET app.tenant_id = 'T01';

-- ============ C. Máy trạng thái route ============
DO $$ BEGIN
  UPDATE ph03_gateway.route SET state = 'STOPPED', state_reason = 'Dừng thử nghiệm bảo trì' WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 10';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 10 PENDING không chuyển thẳng STOPPED';
END $$;
UPDATE ph03_gateway.route SET state = 'ACTIVE' WHERE id = pg_temp.id('r01');
DO $$ BEGIN
  UPDATE ph03_gateway.route SET state = 'STOPPED' WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 10b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10b dừng route phải có lý do 10…500 ký tự (FR-03-036)';
END $$;
UPDATE ph03_gateway.route SET state = 'STOPPED', state_reason = 'Dừng để bảo trì backend' WHERE id = pg_temp.id('r01');
DO $$ BEGIN
  UPDATE ph03_gateway.route SET state = 'SUSPENDED', state_reason = 'Tạm ngừng khẩn cấp sự cố' WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 10c';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 10c STOPPED không chuyển thẳng SUSPENDED';
END $$;
UPDATE ph03_gateway.route SET state = 'ACTIVE' WHERE id = pg_temp.id('r01');
DO $$ DECLARE v int; BEGIN
  SELECT version INTO v FROM ph03_gateway.route WHERE id = pg_temp.id('r01');
  IF v < 3 THEN RAISE 'FAIL 10d: version = %', v; END IF;
  RAISE NOTICE 'PASS 10d trigger tg_touch tăng version mỗi lần sửa (ETag)';
END $$;

-- ============ D. Ràng buộc route ============
DO $$ BEGIN
  INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, require_mtls, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'nhay-cam.v1', 'nhay-cam', 'v1', pg_temp.id('h01'), '/nhay-cam/*', '{GET}', pg_temp.id('u01'), 'SENSITIVE', false, 'lan', 'lan');
  RAISE 'FAIL 11';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11 API mức Nhạy cảm bắt buộc mTLS (BR-03-004)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.route (id, tenant_id, route_code, api_code, api_version, host_id, path_pattern, methods, upstream_id, data_class, cors, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'cors.v1', 'cors', 'v1', pg_temp.id('h01'), '/cors/*', '{GET}', pg_temp.id('u01'), 'INTERNAL', '{"allowedOrigins":["*"]}', 'lan', 'lan');
  RAISE 'FAIL 12';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 12 CORS cấm ký tự đại diện (BR-03-012)';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.route SET deprecated_at = now(), sunset_at = now() + interval '90 days' WHERE id = pg_temp.id('r01');
  RAISE 'FAIL 13';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13 SUNSET cách ngày ngừng dùng dưới 180 ngày bị chặn (BR-03-030)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.upstream_node (id, tenant_id, upstream_id, host, port, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('u01'), '169.254.169.254', 80, 'lan', 'lan');
  RAISE 'FAIL 14';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14 upstream không trỏ link-local, loopback (CHK-10)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.upstream (id, tenant_id, upstream_code, name, connect_timeout_ms, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'up.t01.cham', 'Chậm', 45000, 'lan', 'lan');
  RAISE 'FAIL 14b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14b thời hạn chờ tối đa 30.000 ms (CV 631)';
END $$;

-- ============ E. Mở route ra Internet cần bốn mắt (BR-03-015, BR-03-019) ============
SET app.tenant_id = 'T68';
DO $$ BEGIN
  UPDATE ph03_gateway.route SET exposure = 'EXT' WHERE id = pg_temp.id('r68');
  RAISE 'FAIL 15';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15 route EXT cần yêu cầu thay đổi';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.route SET exposure = 'EXT', exposure_request_id = pg_temp.id('cr68pend') WHERE id = pg_temp.id('r68');
  RAISE 'FAIL 15b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15b yêu cầu đang chờ chưa đủ để mở ra Internet';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.change_request SET state = 'APPROVED', decided_by = 'so1', decided_at = now() WHERE id = pg_temp.id('cr68pend');
  RAISE 'FAIL 15c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15c người đề nghị tự duyệt bị chặn (bốn mắt)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.change_request (id, tenant_id, change_type, target_type, target_code, reason, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ROUTE_EXPOSURE_EXT', 'ROUTE', 'tra-cuu-ho-tich.v1', 'Yêu cầu trùng đang chờ cho cùng route', 'so2', 'so2', 'so2');
  RAISE 'FAIL 15d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 15d chỉ một yêu cầu đang chờ cho cùng đối tượng';
END $$;
UPDATE ph03_gateway.change_request SET state = 'APPROVED', decided_by = 'so2', decided_at = now() WHERE id = pg_temp.id('cr68pend');
UPDATE ph03_gateway.route SET exposure = 'EXT', exposure_request_id = pg_temp.id('cr68pend') WHERE id = pg_temp.id('r68');
DO $$ BEGIN
  UPDATE ph03_gateway.change_request SET target_code = 'route-khac.v1' WHERE id = pg_temp.id('cr68pend');
  RAISE 'FAIL 15e';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 15e đối tượng của yêu cầu bất biến sau khi tạo';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.change_request SET state = 'PENDING' WHERE id = pg_temp.id('cr68pend');
  RAISE 'FAIL 15f';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 15f yêu cầu đã duyệt không quay về chờ';
END $$;

-- ============ F. Consumer, thông tin xác thực công khai ============
SET app.tenant_id = 'T01';
DO $$ BEGIN
  UPDATE ph03_gateway.consumer SET trusted_source = true WHERE id = pg_temp.id('c01');
  RAISE 'FAIL 16';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16 miễn giới hạn IP phải có SO duyệt';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.consumer_credential (id, tenant_id, consumer_id, kind, api_key_hash, api_key_not_after, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('c01'), 'API_KEY', 'khoa-api-dang-ro-DH-CANARY', now() + interval '30 days', 'lan', 'lan');
  RAISE 'FAIL 17';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17 khóa API dạng rõ bị chặn, chỉ nhận băm SHA-256 hex (SEC-24)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.consumer_credential (id, tenant_id, consumer_id, kind, api_key_hash, api_key_not_after, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('c01'), 'API_KEY', repeat('e', 64), now() + interval '200 days', 'lan', 'lan');
  RAISE 'FAIL 17b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17b khóa API tối đa 180 ngày';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.consumer_credential (id, tenant_id, consumer_id, kind, slot, cert_thumbprint, cert_not_after, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('c01'), 'CERT', 3, repeat('f', 64), now() + interval '300 days', 'lan', 'lan');
  RAISE 'FAIL 17c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17c tối đa hai vân tay cùng lúc';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.consumer_credential (id, tenant_id, consumer_id, kind, cert_thumbprint, cert_not_after, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('c01'), 'CERT', repeat('a', 64), now() + interval '300 days', 'lan', 'lan');
  RAISE 'FAIL 17d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 17d vân tay chứng thư không trùng giữa hai tenant';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.consumer SET state = 'DELETED' WHERE id = pg_temp.id('c01');
  RAISE 'FAIL 18';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 18 xóa mềm phải đặt deleted_at';
END $$;
UPDATE ph03_gateway.consumer SET state = 'DELETED', deleted_at = now() WHERE id = pg_temp.id('c01');
DO $$ BEGIN
  UPDATE ph03_gateway.consumer SET state = 'ACTIVE', deleted_at = NULL WHERE id = pg_temp.id('c01');
  RAISE 'FAIL 18b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 18b consumer đã xóa mềm không khôi phục (mã không dùng lại)';
END $$;

-- ============ G. Ngoại lệ WAF, chế độ WAF ============
SET app.tenant_id = 'T68';
DO $$ BEGIN
  UPDATE ph03_gateway.waf_exception SET state = 'ACTIVE', approved_by = 'to1', approved_at = now() WHERE id = pg_temp.id('x68');
  RAISE 'FAIL 19';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 19 người đề nghị không tự duyệt ngoại lệ WAF (BR-03-006)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.waf_exception (id, tenant_id, route_id, rule_id, reason, requested_by, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('r68'), '942200', 'Ngoại lệ dài hạn không được phép', 'to1', now() + interval '120 days', 'to1', 'to1');
  RAISE 'FAIL 20';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 20 ngoại lệ WAF tối đa 90 ngày';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.waf_exception (id, tenant_id, route_id, rule_id, reason, requested_by, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('r68'), '942100', 'Đề nghị trùng cặp route và mã luật', 'to2', now() + interval '10 days', 'to2', 'to2');
  RAISE 'FAIL 21';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 21 không hai ngoại lệ còn hiệu lực cho cùng route và mã luật';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.waf_exception SET state = 'EXPIRED' WHERE id = pg_temp.id('x68');
  RAISE 'FAIL 22';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 22 REQUESTED không nhảy sang EXPIRED';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.waf_exception SET expires_at = now() + interval '80 days' WHERE id = pg_temp.id('x68');
  RAISE 'FAIL 22b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 22b không kéo dài hạn ngoại lệ tại chỗ (phải đề nghị lại)';
END $$;
UPDATE ph03_gateway.waf_exception SET state = 'ACTIVE', approved_by = 'so1', approved_at = now() WHERE id = pg_temp.id('x68');
DO $$ BEGIN
  UPDATE ph03_gateway.waf_exception SET state = 'REVOKED', revoked_by = 'so1', revoked_at = now() WHERE id = pg_temp.id('x68');
  RAISE 'FAIL 22c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 22c thu hồi ngoại lệ phải có lý do';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.waf_mode (id, tenant_id, mode, blocked_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'BLOCK', now(), 'so1', 'so1');
  RAISE 'FAIL 23';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 23 BLOCK cần yêu cầu thay đổi (bốn mắt)';
END $$;
INSERT INTO ph03_gateway.change_request (id, tenant_id, change_type, target_type, target_code, payload, reason, requested_by, state, decided_by, decided_at, created_by, updated_by)
VALUES (pg_temp.id('cr68ok'), 'T68', 'WAF_MODE', 'TENANT', 'T68', '{"mode":"BLOCK"}', 'Đủ 14 ngày phát hiện, chuyển sang chặn', 'so1', 'APPROVED', 'so2', now(), 'so1', 'so1');
DO $$ BEGIN
  INSERT INTO ph03_gateway.waf_mode (id, tenant_id, mode, detect_since, blocked_at, change_request_id, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'BLOCK', now() - interval '5 days', now(), pg_temp.id('cr68ok'), 'so1', 'so1');
  RAISE 'FAIL 23b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 23b chưa đủ 14 ngày chạy DETECT thì không chuyển BLOCK (ERR-03-027)';
END $$;
INSERT INTO ph03_gateway.waf_mode (id, tenant_id, mode, detect_since, blocked_at, change_request_id, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', 'BLOCK', now() - interval '20 days', now(), pg_temp.id('cr68ok'), 'so1', 'so1');
DO $$ BEGIN
  INSERT INTO ph03_gateway.waf_mode (id, tenant_id, mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'DETECT', 'so1', 'so1');
  RAISE 'FAIL 23c';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 23c một chế độ WAF cho mỗi phạm vi';
END $$;

-- ============ H. Hạn mức ============
SET app.tenant_id = 'T01';
DO $$ BEGIN
  INSERT INTO ph03_gateway.rate_limit_override (id, tenant_id, scope, window_seconds, limit_value, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'ROUTE', 1, 100, 'Thiếu route cho phạm vi ROUTE', 'lan', 'lan');
  RAISE 'FAIL 24';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 24 phạm vi ROUTE bắt buộc có route';
END $$;
INSERT INTO ph03_gateway.rate_limit_override (id, tenant_id, scope, window_seconds, limit_value, burst_percent, reason, created_by, updated_by)
VALUES (gen_random_uuid(), 'T01', 'TENANT', 1, 500, 20, 'Hạn mức toàn tenant theo hợp đồng', 'lan', 'lan');
DO $$ BEGIN
  INSERT INTO ph03_gateway.rate_limit_override (id, tenant_id, scope, window_seconds, limit_value, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'TENANT', 1, 300, 'Hạn mức tenant thứ hai cùng cửa sổ', 'lan', 'lan');
  RAISE 'FAIL 25';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 25 một hạn mức toàn tenant đang hiệu lực (NULLS NOT DISTINCT)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.plan_policy (id, tenant_id, policy_code, plan_code, api_code, security_mode, rate_limits, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'sai-khoa', 'g', 'a', 'OAUTH2', '{"hour":5}', 'lan', 'lan');
  RAISE 'FAIL 26';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 26 rate_limits chỉ nhận second, minute; hạn ngạch mới nhận hour, day, month';
END $$;

-- ============ I. Ảnh chụp cấu hình ============
SET app.tenant_id = 'T68';
DO $$ BEGIN
  UPDATE ph03_gateway.config_snapshot SET state = 'SIGNED' WHERE id = pg_temp.id('snap68');
  RAISE 'FAIL 27';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 27 SIGNED phải có số phiên bản, băm manifest, khóa ký';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.config_snapshot SET state = 'PUBLISHED', published_at = now() WHERE id = pg_temp.id('snap68');
  RAISE 'FAIL 27b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 27b BUILT không nhảy thẳng PUBLISHED';
END $$;
UPDATE ph03_gateway.config_snapshot SET state = 'SIGNED', snapshot_version = 48213, manifest_hash = repeat('9', 64), signature_key_id = 'dh-gateway-snapshot:3', signed_at = now()
 WHERE id = pg_temp.id('snap68');
DO $$ BEGIN
  UPDATE ph03_gateway.config_snapshot SET snapshot_version = 48100 WHERE id = pg_temp.id('snap68');
  RAISE 'FAIL 28';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 28 số phiên bản đã cấp không đổi (BR-03-018)';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.config_snapshot SET content_hash = repeat('0', 64) WHERE id = pg_temp.id('snap68');
  RAISE 'FAIL 28b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 28b nội dung đã ký (băm) bất biến';
END $$;
SET app.tenant_id = 'T01';
DO $$ BEGIN
  INSERT INTO ph03_gateway.config_snapshot (id, tenant_id, site, scope, snapshot_version, state, trigger_type, content_hash, manifest_hash, signature_key_id, signed_at, requested_by, created_by, updated_by)
  VALUES (pg_temp.id('snap01'), 'T01', 'dc1', 'TENANT', 48213, 'SIGNED', 'EVENT', repeat('b', 64), repeat('8', 64), 'dh-gateway-snapshot:3', now(), 'system:build', 'system:build', 'system:build');
  RAISE 'FAIL 28c';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 28c số phiên bản duy nhất trên mỗi site (hai tenant không cùng số)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.config_snapshot (id, tenant_id, site, scope, trigger_type, content_hash, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'dc1', 'PLATFORM', 'EVENT', repeat('b', 64), 'system:build', 'system:build', 'system:build');
  RAISE 'FAIL 28d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 28d phạm vi PLATFORM chỉ ở tenant COMMON';
END $$;
DO $$ BEGIN
  UPDATE ph03_gateway.snapshot_counter SET last_issued = 0 WHERE site = 'dc1';
  UPDATE ph03_gateway.snapshot_counter SET last_issued = 100 WHERE site = 'dc1';
  UPDATE ph03_gateway.snapshot_counter SET last_issued = 50 WHERE site = 'dc1';
  RAISE 'FAIL 29';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 29 bộ đếm phiên bản chỉ tăng';
END $$;

-- ============ J. Tham số gw.* ============
SET app.tenant_id = 'T01';
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'gw.ip.maxConnections', '5000', 'lan', 'lan');
  RAISE 'FAIL 30';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 30 tham số ngoài miền nền tảng bị chặn';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'gw.waf.mode', '"BLOCK"', 'lan', 'lan');
  RAISE 'FAIL 30b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 30b gw.waf.mode chỉ đổi qua waf_mode (bốn mắt), không ghi thẳng tham số';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'gw.degrade.localDivisorMode', '"MOT_NUA"', 'lan', 'lan');
  RAISE 'FAIL 30c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 30c tham số ENUM chỉ nhận giá trị liệt kê';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'gw.ip.maxConnections', '"nhieu"', 'lan', 'lan');
  RAISE 'FAIL 30d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 30d sai kiểu giá trị bị chặn';
END $$;
INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
VALUES (gen_random_uuid(), 'T01', 'gw.ip.maxConnections', '250', 'lan', 'lan');
INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
VALUES (gen_random_uuid(), 'T01', 'gw.rate.essentialFactor', '2.0', 'lan', 'lan');
INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
VALUES (gen_random_uuid(), 'T01', 'gw.ip.trustedCidrs', '["10.20.0.0/16"]', 'lan', 'lan');
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_param (id, tenant_id, param_key, param_value, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'gw.ip.trustedCidrs', '["khong-phai-cidr"]', 'lan', 'lan');
  RAISE 'FAIL 30e';
EXCEPTION WHEN check_violation OR unique_violation THEN RAISE NOTICE 'PASS 30e CIDR sai dạng hoặc trùng khóa bị chặn';
END $$;

-- ============ K. Không lưu bí mật, outbox, chứng thư ============
DO $$ BEGIN
  INSERT INTO ph03_gateway.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T01', 'vn.datahub.gateway.route.state-changed.v1', 't68.gateway.route.state-changed.v1', 'Route', 'x', '{}', repeat('0', 32));
  RAISE 'FAIL 31';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 31 topic outbox phải thuộc tenant của dòng';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id)
  VALUES (gen_random_uuid(), 'T01', 'vn.datahub.gateway.consumer.state-changed.v1', 't01.gateway.consumer.state-changed.v1', 'Consumer', 'x', '{"apiKey":"DH-CANARY"}', repeat('0', 32));
  RAISE 'FAIL 31b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 31b sự kiện không mang bí mật';
END $$;
SET app.tenant_id = 'PLATFORM';
DO $$ BEGIN
  INSERT INTO ph03_gateway.client_ca (id, tenant_id, ca_code, subject, fingerprint, not_after, public_pem, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'ca-sai', 'CN=Sai', repeat('1', 64), now() + interval '1 year', E'-----BEGIN CERTIFICATE-----\nAAA\n-----END CERTIFICATE-----\n-----BEGIN PRIVATE KEY-----\nBBB', 'pa1', 'pa1');
  RAISE 'FAIL 32';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 32 bộ CA khách không chứa khóa riêng';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.edge_certificate (id, tenant_id, cert_code, subject, hosts, issuer, fingerprint, not_before, not_after, source, secret_ref, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'cert-sai', 'CN=x', '{x.datahub.gov.vn}', 'CA', repeat('2', 64), now(), now() + interval '90 days', 'MANUAL', 'PRIVATE-KEY-DAN-NHAM', 'pa1', 'pa1');
  RAISE 'FAIL 32b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 32b chứng thư biên chỉ lưu đường dẫn kho bí mật, không lưu khóa';
END $$;
SET app.tenant_id = 'T68';

-- ============ L. Chặn nhanh, thu hồi, chuyển tiếp ============
DO $$ BEGIN
  INSERT INTO ph03_gateway.revoked_token (id, tenant_id, kind, jti, sub, token_expires_at, reason, revoked_by)
  VALUES (gen_random_uuid(), 'T68', 'JTI', 'abc', 'ht-qlvb', now() + interval '5 minutes', 'Nghi lộ token', 'so1');
  RAISE 'FAIL 33';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 33 thu hồi theo jti không kèm sub';
END $$;
INSERT INTO ph03_gateway.revoked_token (id, tenant_id, kind, sub, not_before, token_expires_at, reason, revoked_by)
VALUES (gen_random_uuid(), 'T68', 'SUB', 'ht-qlvb', now(), now() + interval '5 minutes', 'Xoay khóa client', 'so1');
DO $$ BEGIN
  INSERT INTO ph03_gateway.emergency_block (id, tenant_id, target_type, route_id, target_code, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ROUTE', pg_temp.id('r68'), 'tra-cuu-ho-tich.v1', 'ngắn', 'so1', 'so1');
  RAISE 'FAIL 34';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 34 tạm ngừng khẩn cấp phải có lý do 10…500 ký tự';
END $$;
INSERT INTO ph03_gateway.emergency_block (id, tenant_id, target_type, route_id, target_code, reason, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', 'ROUTE', pg_temp.id('r68'), 'tra-cuu-ho-tich.v1', 'Nghi ngờ rò rỉ dữ liệu qua route', 'so1', 'so1');
DO $$ BEGIN
  INSERT INTO ph03_gateway.emergency_block (id, tenant_id, target_type, route_id, target_code, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'ROUTE', pg_temp.id('r68'), 'tra-cuu-ho-tich.v1', 'Tạm ngừng lần hai cùng route', 'so1', 'so1');
  RAISE 'FAIL 34b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 34b một khối đang hoạt động cho mỗi đối tượng (ERR-03-019)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_redirect (id, tenant_id, from_tenant, to_tenant, end_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'T09', 'T68', now() + interval '180 days', 'pa1', 'pa1');
  RAISE 'FAIL 35';
EXCEPTION WHEN insufficient_privilege OR check_violation THEN RAISE NOTICE 'PASS 35 chuyển tiếp thuộc tenant đích (tenant_id = to_tenant)';
END $$;
INSERT INTO ph03_gateway.tenant_redirect (id, tenant_id, from_tenant, to_tenant, end_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', 'T09', 'T68', now() + interval '180 days', 'pa1', 'pa1');
DO $$ BEGIN
  INSERT INTO ph03_gateway.tenant_redirect (id, tenant_id, from_tenant, to_tenant, end_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'T09', 'T68', now() + interval '90 days', 'pa1', 'pa1');
  RAISE 'FAIL 35b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 35b mỗi tenant nguồn một chuyển tiếp đang chạy (ERR-03-025)';
END $$;
DO $$ BEGIN
  INSERT INTO ph03_gateway.ip_block (id, tenant_id, cidr, source, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', '10.0.0.0/8', 'MANUAL', 'Chặn cả dải lớn', 'ta1', 'ta1');
  RAISE 'FAIL 36';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 36 không chặn dải rộng hơn /16';
END $$;

-- ============ M. Chỉ thêm, quyền vai trò ============
INSERT INTO ph03_gateway.route_state_event (id, tenant_id, route_id, from_state, to_state, actor, trace_id)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('r68'), 'PENDING', 'ACTIVE', 'system', repeat('a', 32));
DO $$ BEGIN
  UPDATE ph03_gateway.route_state_event SET actor = 'sua' WHERE tenant_id = 'T68';
  RAISE 'FAIL 37';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 37 lịch sử trạng thái chỉ thêm (ứng dụng không có UPDATE)';
END $$;
DO $$ BEGIN
  SET LOCAL ROLE ph03_owner;
  DELETE FROM ph03_gateway.route_state_event WHERE tenant_id = 'T68';
  RAISE 'FAIL 37b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 37b chủ schema cũng bị trigger append-only chặn';
END $$;
SET ROLE dh_connect_app;
SET app.tenant_id = 'T68';
DO $$ BEGIN
  INSERT INTO ph03_gateway.state_transition (entity, from_state, to_state, command) VALUES ('ROUTE', 'ACTIVE', 'PENDING', 'lui');
  RAISE 'FAIL 38';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 38 ứng dụng không sửa được bảng chuyển trạng thái';
END $$;
SET app.tenant_id = 'T68';
RESET ROLE;
SET ROLE dh_gateway_report;
SET app.tenant_id = 'T68';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph03_gateway.route; IF n <> 1 THEN RAISE 'FAIL 39: báo cáo thấy % route', n; END IF;
  UPDATE ph03_gateway.route SET priority = 1;
  RAISE 'FAIL 39b';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 39 vai trò báo cáo đọc theo tenant, không ghi';
END $$;
DO $$ BEGIN
  PERFORM rule_text FROM ph03_gateway.waf_virtual_patch;
  RAISE 'FAIL 39c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 39c vai trò báo cáo không đọc được nội dung luật vá WAF';
END $$;
DO $$ BEGIN
  PERFORM public_pem FROM ph03_gateway.client_ca;
  RAISE 'FAIL 39d';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 39d vai trò báo cáo chỉ đọc cột siêu dữ liệu của bộ CA';
END $$;
RESET ROLE;

-- ============ N. Toàn vẹn cấu trúc (không phụ thuộc dữ liệu) ============
DO $$ DECLARE n int; m text; BEGIN
  SELECT string_agg(c.relname, ',') INTO m FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph03_gateway' AND c.relkind = 'r' AND NOT c.relforcerowsecurity
     AND c.relname NOT IN ('state_transition', 'shedlock', 'snapshot_counter');
  IF m IS NOT NULL THEN RAISE 'FAIL 40: bảng thiếu FORCE RLS: %', m; END IF;
  SELECT string_agg(c.relname, ',') INTO m FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph03_gateway' AND c.relkind = 'r' AND c.relforcerowsecurity
     AND NOT EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped);
  IF m IS NOT NULL THEN RAISE 'FAIL 40b: bảng RLS thiếu cột tenant_id: %', m; END IF;
  SELECT string_agg(c.relname, ',') INTO m FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
   WHERE s.nspname = 'ph03_gateway' AND c.relkind = 'r'
     AND c.relname IN (SELECT tablename FROM pg_policies WHERE schemaname = 'ph03_gateway' GROUP BY tablename HAVING count(*) <> 4);
  IF m IS NOT NULL THEN RAISE 'FAIL 40c: bảng không đủ 4 chính sách: %', m; END IF;
  SELECT string_agg(r.rolname, ',') INTO m FROM pg_roles r WHERE r.rolname IN ('ph03_owner', 'ph03_app', 'ph03_readonly', 'dh_connect_app') AND r.rolbypassrls;
  IF m IS NOT NULL THEN RAISE 'FAIL 40d: vai trò BYPASSRLS: %', m; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace WHERE s.nspname = 'ph03_gateway' AND c.relkind = 'r';
  RAISE NOTICE 'PASS 40 % bảng: 32 bảng FORCE RLS đủ 4 chính sách và có tenant_id, 3 bảng kỹ thuật; không vai trò nào BYPASSRLS', n;
END $$;

ROLLBACK;
\echo 'Hoàn tất: mọi khối PASS (dữ liệu thử đã hoàn tác)'
