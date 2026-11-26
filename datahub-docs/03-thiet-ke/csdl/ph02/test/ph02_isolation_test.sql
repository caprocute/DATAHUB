-- =============================================================================
-- D03-03-PH02 · Kiểm thử DDL ph02_catalog: cô lập tenant, chốt chặn máy trạng thái,
-- bốn mắt, kiểu xác thực theo mức phân loại, bất biến đặc tả, chỉ thêm, hộp gửi.
-- Chạy sau ph02_all.sql trên CSDL rỗng, bằng người dùng có quyền tạo vai trò:
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph02_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt qua pg_temp.ok (kiểm cả SQLSTATE lẫn
-- đoạn thông báo), đúng thì ghi PASS, sai thì RAISE dừng tệp. Tương ứng nhóm ca cô lập
-- tenant (NFR-02-013), bốn mắt (BR-02-008), vòng đời (FRS 4.3) của D05-02-PH02.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_connect_app') THEN
    CREATE ROLE dh_connect_app LOGIN NOBYPASSRLS IN ROLE ph02_app;
  ELSE
    GRANT ph02_app TO dh_connect_app;
  END IF;
END $$;
SET ROLE dh_connect_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY[
  'c68','a68','v68','v68b','v68c','s68','s68b','s68c','o68','b68','p68','sub68','aR','vR','aP','vP','pR','a01','v01','rq1','rq2','n68','sp68']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.ok(n text, st text, frag text, got_st text, got_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF got_st <> st OR position(frag in got_msg) = 0 THEN
    RAISE EXCEPTION 'FAIL %: mong % chứa "%", nhận % "%"', n, st, frag, got_st, got_msg;
  END IF;
  RAISE NOTICE 'PASS % (%)', n, frag;
END $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
INSERT INTO ph02_catalog.category (id, tenant_id, category_code, name, path, created_by, updated_by)
VALUES (pg_temp.id('c68'), 'T68', 'dat-dai', 'Đất đai', 'dat-dai', 'an', 'an');
INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, visibility, category_id, base_path, created_by, updated_by) VALUES
  (pg_temp.id('a68'), 'T68', 'tra-cuu-ho-tich', 'Tra cứu hộ tịch', 'QLHT', 'SOTP', 'INTERNAL', 'TENANT', pg_temp.id('c68'), '/dat-dai/tra-cuu-ho-tich', 'an', 'an'),
  (pg_temp.id('aR'),  'T68', 'tra-cuu-bat-dong-san', 'Tra cứu bất động sản', 'QLBDS', 'SOTNMT', 'RESTRICTED', 'TENANT', NULL, '/dat-dai/tra-cuu-bat-dong-san', 'an', 'an'),
  (pg_temp.id('aP'),  'T68', 'danh-muc-don-vi', 'Danh mục đơn vị', 'DMDC', 'SONV', 'PUBLIC', 'TENANT', NULL, '/dung-chung/danh-muc-don-vi', 'an', 'an');
INSERT INTO ph02_catalog.api_version (id, tenant_id, api_id, version_no, major, created_by, updated_by) VALUES
  (pg_temp.id('v68'),  'T68', pg_temp.id('a68'), '1.0.0', 1, 'an', 'an'),
  (pg_temp.id('v68b'), 'T68', pg_temp.id('a68'), '1.1.0', 1, 'an', 'an'),
  (pg_temp.id('v68c'), 'T68', pg_temp.id('a68'), '2.0.0', 2, 'an', 'an'),
  (pg_temp.id('vR'),   'T68', pg_temp.id('aR'),  '1.0.0', 1, 'an', 'an'),
  (pg_temp.id('vP'),   'T68', pg_temp.id('aP'),  '1.0.0', 1, 'an', 'an');
INSERT INTO ph02_catalog.api_spec (id, tenant_id, api_version_id, seq, format, source, sha256, size_bytes, operation_count, object_key, created_by) VALUES
  (pg_temp.id('s68'),  'T68', pg_temp.id('v68'),  1, 'OPENAPI31', 'UPLOAD', repeat('a', 64), 1000, 2, 'specs/tra-cuu-ho-tich/1.0.0/' || repeat('a', 64), 'an'),
  (pg_temp.id('s68b'), 'T68', pg_temp.id('v68b'), 1, 'OPENAPI31', 'UPLOAD', repeat('b', 64), 1200, 3, 'specs/tra-cuu-ho-tich/1.1.0/' || repeat('b', 64), 'an'),
  (pg_temp.id('s68c'), 'T68', pg_temp.id('v68c'), 1, 'OPENAPI31', 'UPLOAD', repeat('c', 64), 1500, 3, 'specs/tra-cuu-ho-tich/2.0.0/' || repeat('c', 64), 'an');
INSERT INTO ph02_catalog.api_operation (id, tenant_id, api_version_id, spec_id, operation_id, method, path_template, summary, created_by)
VALUES (pg_temp.id('o68'), 'T68', pg_temp.id('v68'), pg_temp.id('s68'), 'getCivilRecord', 'GET', '/ho-tich/{id}', 'Lấy hồ sơ hộ tịch', 'an');
INSERT INTO ph02_catalog.backend (id, tenant_id, api_version_id, backend_code, kind, target_ref, created_by, updated_by)
VALUES (pg_temp.id('b68'), 'T68', pg_temp.id('v68'), 'chinh', 'SYSTEM', '{"connectionCode":"qlht-rest","basePath":"/api"}', 'an', 'an');
INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, created_by, updated_by)
VALUES (pg_temp.id('p68'), 'T68', pg_temp.id('v68'), 'goi-chuan', 'Gói chuẩn', 'API_KEY', 'an', 'an');
INSERT INTO ph02_catalog.subscription (id, tenant_id, plan_id, api_version_id, system_code, requester_org_code, purpose, expected_volume, data_class, requested_by, created_by, updated_by)
VALUES (pg_temp.id('sub68'), 'T68', pg_temp.id('p68'), pg_temp.id('v68'), 'DKKD', 'SOKHDT', 'Đối chiếu hồ sơ đăng ký kinh doanh', '2.000 lượt mỗi ngày', 'INTERNAL', 'an', 'an', 'an');
INSERT INTO ph02_catalog.api_search_doc (id, tenant_id, api_id, api_code, has_published, tsv, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('a68'), 'tra-cuu-ho-tich', false, to_tsvector('ph02_catalog.vn_unaccent', 'Hồ sơ đất đai tra cứu'), 'an', 'an');
INSERT INTO ph02_catalog.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
VALUES (gen_random_uuid(), 'T68', 'vn.datahub.catalog.version.published.v1', 't68.catalog.version.published.v1', 'ApiVersion', 'tra-cuu-ho-tich@1.0.0', 'tra-cuu-ho-tich', '{"apiCode":"tra-cuu-ho-tich","versionNo":"1.0.0"}', repeat('0', 32));
INSERT INTO ph02_catalog.config_change_log (id, tenant_id, env, source_version, change_kind, subject_kind, subject_id, created_by)
VALUES (gen_random_uuid(), 'T68', 'PROD', 1, 'PUBLISH', 'API_VERSION', pg_temp.id('v68'), 'an');
INSERT INTO ph02_catalog.lint_finding (id, tenant_id, api_version_id, spec_id, run_id, layer, severity, rule_id, location, message, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), pg_temp.id('s68'), gen_random_uuid(), 'CONVENTION', 'ERROR', 'LINT-02-03', '#/paths/~1ho-tich/get', 'Thiếu mã lỗi 429', 'an');
INSERT INTO ph02_catalog.usage_daily (tenant_id, api_version_id, usage_date, operation_id, consumer_system_code, calls, errors)
VALUES ('T68', pg_temp.id('v68'), current_date, 'getCivilRecord', 'DKKD', 100, 2);

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, base_path, created_by, updated_by)
VALUES (pg_temp.id('a01'), 'T01', 'tra-cuu-ho-tich', 'Tra cứu hộ tịch T01', 'QLHT', 'SOTP', 'INTERNAL', '/dat-dai/tra-cuu-ho-tich', 'lan', 'lan');
INSERT INTO ph02_catalog.api_version (id, tenant_id, api_id, version_no, major, created_by, updated_by)
VALUES (pg_temp.id('v01'), 'T01', pg_temp.id('a01'), '1.0.0', 1, 'lan', 'lan');

-- 1. Cô lập đọc, mọi nhóm bảng (kể cả bảng phân vùng)
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph02_catalog.api; IF n <> 1 THEN RAISE 'FAIL 1: T01 thấy % API', n; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.api_version; IF n <> 1 THEN RAISE 'FAIL 1a: % phiên bản', n; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.api_spec; IF n <> 0 THEN RAISE 'FAIL 1b'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.plan; IF n <> 0 THEN RAISE 'FAIL 1c'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.subscription; IF n <> 0 THEN RAISE 'FAIL 1d'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.category; IF n <> 0 THEN RAISE 'FAIL 1e'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.outbox_event; IF n <> 0 THEN RAISE 'FAIL 1f'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.lint_finding; IF n <> 0 THEN RAISE 'FAIL 1g (phân vùng)'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.usage_daily; IF n <> 0 THEN RAISE 'FAIL 1h (phân vùng)'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.config_change_log; IF n <> 0 THEN RAISE 'FAIL 1i (phân vùng)'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.api_search_doc; IF n <> 0 THEN RAISE 'FAIL 1j'; END IF;
  SELECT count(*) INTO n FROM ph02_catalog.code_registry; IF n <> 0 THEN RAISE 'FAIL 1k'; END IF;
  RAISE NOTICE 'PASS 1 T01 không đọc được dữ liệu T68 ở 12 bảng, cùng mã API ở hai tenant không xung đột';
END $$;

-- 2. Cô lập ghi: T01 chèn dòng T68
DO $$ BEGIN
  INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, base_path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'gia-mao', 'x', 'X', 'X', 'INTERNAL', '/nhom/gia-mao', 'lan', 'lan');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('2 chặn chèn chéo tenant', '42501', 'row-level security', SQLSTATE, SQLERRM);
END $$;

-- 3. Cô lập sửa, xóa: T01 không tác động được dòng T68
DO $$ DECLARE n int; BEGIN
  UPDATE ph02_catalog.api SET name = 'bị sửa' WHERE api_code = 'tra-cuu-ho-tich' AND tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  DELETE FROM ph02_catalog.plan WHERE tenant_id = 'T68';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3b'; END IF;
  RAISE NOTICE 'PASS 3 không sửa, không xóa được dòng tenant khác';
END $$;

-- 4. Khóa ngoại kèm tenant: không trỏ chéo tenant dù biết id
DO $$ BEGIN
  INSERT INTO ph02_catalog.api_version (id, tenant_id, api_id, version_no, major, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', pg_temp.id('a68'), '9.0.0', 9, 'lan', 'lan');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('4 khóa ngoại kép chặn trỏ chéo tenant', '23503', 'fk_api_version_api', SQLSTATE, SQLERRM);
END $$;

-- 5. Biến phiên rỗng: không thấy dòng nào; chưa đặt: lỗi
DO $$ DECLARE n int; BEGIN
  PERFORM set_config('app.tenant_id', '', true);
  SELECT count(*) INTO n FROM ph02_catalog.api; IF n <> 0 THEN RAISE 'FAIL 5: % dòng khi biến rỗng', n; END IF;
  RAISE NOTICE 'PASS 5 biến phiên rỗng: 0 dòng';
END $$;
SET app.tenant_id = 'T68';

-- 6. Phân vùng chỉ truy cập qua bảng cha
DO $$ DECLARE p text := 'ph02_catalog.lint_finding_' || to_char(now(), 'YYYYMM'); BEGIN
  EXECUTE format('SELECT count(*) FROM %s', p);
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('6 không đọc trực tiếp phân vùng', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;

-- 7. Bộ luật dùng chung: tỉnh đọc 24 luật COMMON, không ghi COMMON
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph02_catalog.lint_rule; IF n <> 24 THEN RAISE 'FAIL 7: thấy % luật', n; END IF;
  RAISE NOTICE 'PASS 7 tỉnh đọc được % luật (15 LINT, 9 SCAN)', n;
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.lint_rule SET default_severity = 'INFO' WHERE rule_id = 'LINT-02-01';
  IF FOUND THEN RAISE EXCEPTION 'KHONG-CHAN'; END IF;
  RAISE NOTICE 'PASS 7b tỉnh không sửa được luật COMMON (0 dòng)';
EXCEPTION WHEN OTHERS THEN IF SQLERRM = 'KHONG-CHAN' THEN RAISE 'FAIL 7b'; END IF; RAISE;
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.lint_rule (id, tenant_id, rule_id, layer, default_severity, title, created_by, updated_by)
  VALUES (gen_random_uuid(), 'COMMON', 'LINT-02-99', 'CONVENTION', 'ERROR', 'x', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('7c tỉnh không thêm luật COMMON', '42501', 'row-level security', SQLSTATE, SQLERRM);
END $$;

-- 8. Chỉnh mức luật theo chính sách (FR-02-021)
DO $$ BEGIN
  INSERT INTO ph02_catalog.lint_rule_override (id, tenant_id, rule_id, severity, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'LINT-02-01', 'WARNING', 'hạ', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('8 luật cấu trúc không hạ mức', '23514', 'luật cấu trúc', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.lint_rule_override (id, tenant_id, rule_id, severity, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'LINT-02-05', 'INFO', 'hạ', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('8b luật RAISE chỉ nâng', '23514', 'chỉ được nâng', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.lint_rule_override (id, tenant_id, rule_id, severity, reason, created_by, updated_by) VALUES
  (gen_random_uuid(), 'T68', 'LINT-02-05', 'ERROR', 'Tỉnh yêu cầu mô tả đầy đủ', 'an', 'an'),
  (gen_random_uuid(), 'T68', 'LINT-02-02', 'WARNING', 'Hạ phần cảnh báo ngôn ngữ', 'an', 'an');
DO $$ BEGIN RAISE NOTICE 'PASS 8c nâng LINT-02-05 và hạ LINT-02-02 hợp lệ'; END $$;

-- 9. Mức hiển thị theo mức phân loại (BR-02-037)
DO $$ BEGIN
  INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, visibility, base_path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'cong-khai-sai', 'x', 'X', 'X', 'INTERNAL', 'PUBLIC', '/nhom/cong-khai-sai', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('9 PUBLIC chỉ với dữ liệu PUBLIC', '23514', 'ck_api_visibility_class', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, visibility, base_path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'quoc-gia-sai', 'x', 'X', 'X', 'SENSITIVE', 'NATIONAL', '/nhom/quoc-gia-sai', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('9b NATIONAL không với SENSITIVE', '23514', 'ck_api_visibility_class', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, origin, base_path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'tu-luong', 'x', 'X', 'X', 'INTERNAL', 'FLOW', '/nhom/tu-luong', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('9c API từ luồng phải có flow_ref', '23514', 'ck_api_flow_ref', SQLSTATE, SQLERRM);
END $$;

-- 10. Máy trạng thái phiên bản: cạnh hợp lệ, đặc tả và số hiệu bất biến
DO $$ BEGIN
  UPDATE ph02_catalog.api_version SET status = 'PUBLISHED', published_at = now(), current_spec_id = pg_temp.id('s68'), updated_by = 'an' WHERE id = pg_temp.id('v68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('10 DRAFT không sang PUBLISHED thẳng', '55000', 'không hợp lệ', SQLSTATE, SQLERRM);
END $$;
UPDATE ph02_catalog.api_version SET status = 'PENDING', current_spec_id = pg_temp.id('s68'), submitted_at = now(), submitted_by = 'an', updated_by = 'an' WHERE id = pg_temp.id('v68');
UPDATE ph02_catalog.api_version SET status = 'PENDING', current_spec_id = pg_temp.id('s68b'), submitted_at = now(), submitted_by = 'an', updated_by = 'an' WHERE id = pg_temp.id('v68b');
UPDATE ph02_catalog.api_version SET status = 'PUBLISHED', published_at = now(), updated_by = 'binh' WHERE id = pg_temp.id('v68');
DO $$ BEGIN
  UPDATE ph02_catalog.api_version SET current_spec_id = pg_temp.id('s68b'), updated_by = 'an' WHERE id = pg_temp.id('v68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('10b đặc tả bất biến khi không còn DRAFT', '55000', 'bất biến', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.api_version SET version_no = '1.0.1', updated_by = 'an' WHERE id = pg_temp.id('v68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('10c số hiệu phiên bản bất biến', '55000', 'BR-02-021', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.api_version SET status = 'DEPRECATED', updated_by = 'an' WHERE id = pg_temp.id('v68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('10d DEPRECATED cần hạn sunset_at', '23514', 'ck_api_version_deprecated', SQLSTATE, SQLERRM);
END $$;

-- 11. Một phiên bản đang chạy mỗi số chính; thay thế cùng số chính trong một giao dịch (BR-02-035)
DO $$ BEGIN
  SET CONSTRAINTS ph02_catalog.ex_api_version_one_live_per_major IMMEDIATE;
  UPDATE ph02_catalog.api_version SET status = 'PUBLISHED', published_at = now(), updated_by = 'binh' WHERE id = pg_temp.id('v68b');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('11 hai phiên bản PUBLISHED cùng số chính bị chặn', '23P01', 'ex_api_version_one_live_per_major', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  SET CONSTRAINTS ph02_catalog.ex_api_version_one_live_per_major DEFERRED;
  UPDATE ph02_catalog.api_version SET status = 'PUBLISHED', published_at = now(), updated_by = 'binh' WHERE id = pg_temp.id('v68b');
  UPDATE ph02_catalog.api_version SET status = 'RETIRED', retired_at = now(), updated_by = 'system:supersede' WHERE id = pg_temp.id('v68');
  SET CONSTRAINTS ph02_catalog.ex_api_version_one_live_per_major IMMEDIATE;
  RAISE NOTICE 'PASS 11b thay thế cùng số chính: bản mới PUBLISHED và bản cũ RETIRED trong một giao dịch';
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.api_version SET status = 'PUBLISHED', updated_by = 'an' WHERE id = pg_temp.id('v68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('11c RETIRED là trạng thái cuối', '55000', 'không hợp lệ', SQLSTATE, SQLERRM);
END $$;

-- 12. Context-path
INSERT INTO ph02_catalog.context_path_reservation (id, tenant_id, api_id, major, path, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('a68'), 1, '/dat-dai/tra-cuu-ho-tich/v1', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph02_catalog.context_path_reservation (id, tenant_id, api_id, major, path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('aP'), 1, '/dat-dai/tra-cuu-ho-tich/v1', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('12 context-path duy nhất trong tenant', '23505', 'uq_context_path', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.context_path_reservation (id, tenant_id, api_id, major, path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('a68'), 2, '/dat-dai/tra-cuu-ho-tich/v1', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('12b số chính khớp hậu tố đường dẫn', '23514', 'ck_context_path_major_suffix', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.context_path_reservation (id, tenant_id, api_id, major, path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('aP'), 1, '/DatDai/layHoSo/v1', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('12c đúng quy ước /{nhóm}/{mã API}/v{n}', '23514', 'ck_context_path_format', SQLSTATE, SQLERRM);
END $$;

-- 13. Đặc tả bất biến và chỉ thêm (BR-02-014); sổ mã chỉ thêm (BR-02-021)
DO $$ BEGIN
  UPDATE ph02_catalog.api_spec SET size_bytes = 5 WHERE id = pg_temp.id('s68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('13 api_spec không sửa được', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  DELETE FROM ph02_catalog.api_spec WHERE id = pg_temp.id('s68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('13b api_spec không xóa được', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.api_spec (id, tenant_id, api_version_id, seq, format, source, sha256, size_bytes, operation_count, object_key, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('vP'), 1, 'OPENAPI31', 'UPLOAD', repeat('d', 64), 60000000, 1, 'x', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('13c đặc tả quá 50 MiB bị chặn', '23514', 'ck_api_spec_size', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.code_registry (id, tenant_id, kind, code, created_by) VALUES (gen_random_uuid(), 'T68', 'API', 'tra-cuu-ho-tich', 'an');
DO $$ BEGIN
  INSERT INTO ph02_catalog.code_registry (id, tenant_id, kind, code, created_by) VALUES (gen_random_uuid(), 'T68', 'API', 'tra-cuu-ho-tich', 'binh');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('13d mã API không dùng lại', '23505', 'uq_code_registry', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  DELETE FROM ph02_catalog.code_registry WHERE code = 'tra-cuu-ho-tich';
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('13e sổ mã không xóa được', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;

-- 14. Backend: không có URL tự do (BR-02-023)
DO $$ BEGIN
  INSERT INTO ph02_catalog.backend (id, tenant_id, api_version_id, backend_code, kind, target_ref, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'tu-do', 'SYSTEM', '{"connectionCode":"x","basePath":"/","url":"http://10.0.0.5"}', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('14 backend không nhận URL tự do', '23514', 'ck_backend_no_free_url', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.backend (id, tenant_id, api_version_id, backend_code, kind, target_ref, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'thieu', 'SYSTEM', '{"basePath":"/"}', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('14b SYSTEM phải trỏ kết nối PH-05', '23514', 'ck_backend_target_shape', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.backend (id, tenant_id, api_version_id, backend_code, kind, target_ref, status, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'chuyen', 'SYSTEM', '{"connectionCode":"x","basePath":"/"}', 'PLACEHOLDER', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('14c PLACEHOLDER chỉ cho backend FLOW', '23514', 'ck_backend_placeholder', SQLSTATE, SQLERRM);
END $$;

-- 15. Kiểu xác thực theo mức phân loại (BR-02-016, SEC-24)
DO $$ BEGIN
  INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'khong-khoa', 'x', 'KEYLESS', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('15 INTERNAL không dùng KEYLESS', '23514', 'yếu hơn mức tối thiểu', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('vR'), 'bi-mat', 'x', 'OAUTH2_SECRET', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('15b RESTRICTED cấm client_secret', '23514', 'yếu hơn mức tối thiểu', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, created_by, updated_by)
VALUES (pg_temp.id('pR'), 'T68', pg_temp.id('vR'), 'pkjwt', 'Private key JWT', 'OAUTH2_PKJWT', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('vP'), 'khong-khoa', 'x', 'KEYLESS', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('15c KEYLESS cần mức hiển thị PUBLIC', '23514', 'KEYLESS chỉ với', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, needs_auth_upgrade, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('vR'), 'nhap-cu', 'Nhập từ hệ cũ', 'API_KEY', true, 'system:migrate', 'system:migrate');
DO $$ BEGIN RAISE NOTICE 'PASS 15d gói nhập từ hệ cũ được đánh dấu Cần nâng xác thực thay vì bị chặn'; END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.plan (id, tenant_id, api_version_id, plan_code, name, auth_type, unit_price_vnd, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'gia-am', 'x', 'API_KEY', -1, 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('15e đơn giá không âm', '23514', 'ck_plan_price', SQLSTATE, SQLERRM);
END $$;

-- 16. Đăng ký sử dụng (BR-02-011, 012, 027)
DO $$ BEGIN
  INSERT INTO ph02_catalog.subscription (id, tenant_id, plan_id, api_version_id, system_code, requester_org_code, purpose, expected_volume, data_class, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('p68'), pg_temp.id('v68'), 'DKKD', 'SOKHDT', 'trùng', '1', 'INTERNAL', 'an', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('16 mỗi HTTT một đăng ký hiệu lực cho một phiên bản', '23505', 'uq_subscription_one_effective', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.subscription (id, tenant_id, plan_id, api_version_id, system_code, requester_org_code, purpose, expected_volume, data_class, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('p68'), pg_temp.id('vR'), 'KHAC', 'SOKHDT', 'sai phiên bản', '1', 'INTERNAL', 'an', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('16b gói và phiên bản phải khớp', '23503', 'fk_subscription_plan', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.subscription (id, tenant_id, plan_id, api_version_id, system_code, requester_org_code, purpose, expected_volume, data_class, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('pR'), pg_temp.id('vR'), 'DKKD', 'SOKHDT', 'cần căn cứ', '1', 'RESTRICTED', 'an', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('16c từ mức Hạn chế phải nêu căn cứ pháp lý', '23514', 'ck_subscription_legal_basis', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.subscription SET status = 'ACTIVE', decided_by = 'an', decided_at = now() WHERE id = pg_temp.id('sub68');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('16d người gửi không tự duyệt', '23514', 'ck_subscription_four_eyes', SQLSTATE, SQLERRM);
END $$;
UPDATE ph02_catalog.subscription SET status = 'ACTIVE', grant_status = 'GRANTING', decided_by = 'binh', decided_at = now() WHERE id = pg_temp.id('sub68');
UPDATE ph02_catalog.subscription SET status = 'REVOKED', grant_status = 'DETACH_PENDING', status_reason = 'Thu hồi theo đề nghị' WHERE id = pg_temp.id('sub68');
INSERT INTO ph02_catalog.subscription (id, tenant_id, plan_id, api_version_id, system_code, requester_org_code, purpose, expected_volume, data_class, requested_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('p68'), pg_temp.id('v68'), 'DKKD', 'SOKHDT', 'Đăng ký lại sau thu hồi', '1.000 lượt mỗi ngày', 'INTERNAL', 'an', 'an', 'an');
DO $$ BEGIN RAISE NOTICE 'PASS 16e sau khi đăng ký cũ REVOKED, HTTT được đăng ký lại'; END $$;

-- 17. Duyệt bốn mắt (BR-02-008)
INSERT INTO ph02_catalog.version_contributor (id, tenant_id, api_version_id, contributor_role, user_id, created_by, updated_by) VALUES
  (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'SPEC_EDITOR', 'tuan', 'tuan', 'tuan'),
  (gen_random_uuid(), 'T68', pg_temp.id('v68c'), 'SUBMITTER', 'an', 'an', 'an');
INSERT INTO ph02_catalog.review_request (id, tenant_id, kind, subject_kind, subject_id, api_version_id, requested_by, created_by, updated_by)
VALUES (pg_temp.id('rq1'), 'T68', 'PUBLISH', 'API_VERSION', pg_temp.id('v68c'), pg_temp.id('v68c'), 'an', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph02_catalog.review_request (id, tenant_id, kind, subject_kind, subject_id, api_version_id, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'PUBLISH', 'API_VERSION', pg_temp.id('v68c'), pg_temp.id('v68c'), 'an', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17 một yêu cầu OPEN mỗi đối tượng', '23505', 'uq_review_request_one_open', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('rq1'), 'an', 'APPROVE', 'an', 'CA', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17b người gửi không tự duyệt', '23514', 'không được là người gửi', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('rq1'), 'an', 'APPROVE', 'tuan', 'CA', 'tuan');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17c người sửa gần nhất đặc tả không duyệt', '23514', 'người sửa gần nhất', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('rq1'), 'an', 'APPROVE', 'hoa', 'SV', 'hoa');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17d SV không duyệt công bố', '23514', 'SV không giữ vai trò', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.review_request SET status = 'APPROVED', decided_at = now() WHERE id = pg_temp.id('rq1');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17e chưa có quyết định thì không APPROVED', '23514', 'chưa đủ', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('rq1'), 'an', 'APPROVE', 'binh', 'CA', 'binh');
UPDATE ph02_catalog.review_request SET status = 'APPROVED', decided_at = now() WHERE id = pg_temp.id('rq1');
DO $$ BEGIN RAISE NOTICE 'PASS 17f CA khác người gửi, khác người sửa duyệt được'; END $$;
DO $$ BEGIN
  DELETE FROM ph02_catalog.review_decision;
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17g quyết định duyệt chỉ thêm', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;
-- Đăng ký sử dụng: CHECK bốn mắt ở chính bảng quyết định (không qua trigger người sửa)
INSERT INTO ph02_catalog.review_request (id, tenant_id, kind, subject_kind, subject_id, requested_by, created_by, updated_by, api_version_id)
VALUES (pg_temp.id('n68'), 'T68', 'SUBSCRIBE', 'SUBSCRIPTION', pg_temp.id('sub68'), 'an', 'an', 'an', pg_temp.id('v68'));
DO $$ BEGIN
  INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('n68'), 'an', 'APPROVE', 'an', 'SV', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17b2 CHECK bốn mắt ở review_decision', '23514', 'ck_review_decision_four_eyes', SQLSTATE, SQLERRM);
END $$;
-- API SENSITIVE: hai người CA và TA
INSERT INTO ph02_catalog.review_request (id, tenant_id, kind, subject_kind, subject_id, api_version_id, requested_by, required_approvals, created_by, updated_by)
VALUES (pg_temp.id('rq2'), 'T68', 'PUBLISH', 'API_VERSION', pg_temp.id('vR'), pg_temp.id('vR'), 'an', 2, 'an', 'an');
INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('rq2'), 'an', 'APPROVE', 'binh', 'CA', 'binh');
DO $$ BEGIN
  UPDATE ph02_catalog.review_request SET status = 'APPROVED', decided_at = now() WHERE id = pg_temp.id('rq2');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('17h API SENSITIVE cần hai chữ ký', '23514', 'chưa đủ 2', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.review_decision (id, tenant_id, review_request_id, requested_by, decision, decided_by, decider_role, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('rq2'), 'an', 'APPROVE', 'chi', 'TA', 'chi');
UPDATE ph02_catalog.review_request SET status = 'APPROVED', decided_at = now() WHERE id = pg_temp.id('rq2');
DO $$ BEGIN RAISE NOTICE 'PASS 17i đủ CA và TA là hai người khác nhau thì APPROVED'; END $$;

-- 18. Lịch sử trạng thái chỉ thêm, lý do bắt buộc (BR-02-028)
INSERT INTO ph02_catalog.version_state_history (id, tenant_id, api_version_id, from_status, to_status, command, reason, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), 'PUBLISHED', 'RETIRED', 'supersede', 'Thay bằng 1.1.0', 'system:supersede');
DO $$ BEGIN
  INSERT INTO ph02_catalog.version_state_history (id, tenant_id, api_version_id, from_status, to_status, command, reason, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), 'PUBLISHED', 'SUSPENDED', 'suspend', '  ', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('18 chuyển trạng thái bắt buộc lý do', '23514', 'ck_version_state_history_reason', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.version_state_history SET reason = 'sửa';
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('18b lịch sử không sửa được', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;

-- 19. SLA, thông báo
DO $$ BEGIN
  INSERT INTO ph02_catalog.sla_commitment (id, tenant_id, api_version_id, latency_p99_ms, availability_pct, worsening, effective_from, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 800, 99.5, true, now(), 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('19 SLA kém đi cần thông báo và hiệu lực sau 7 ngày', '23514', 'ck_sla_commitment_worsen', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.sla_commitment (id, tenant_id, api_version_id, latency_p99_ms, availability_pct, effective_from, created_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 500, 99.9, now(), 'an');
DO $$ BEGIN
  UPDATE ph02_catalog.sla_commitment SET latency_p99_ms = 900;
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('19b cam kết SLA chỉ thêm', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.sla_period (id, tenant_id, api_version_id, period, status, met, actual, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), '2026-10', 'MET', true, '{"calls":5000}', 'system', 'system');
DO $$ BEGIN
  INSERT INTO ph02_catalog.sla_period (id, tenant_id, api_version_id, period, result_version, status, met, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), '2026-10', 2, 'BREACHED', true, 'system', 'system');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('19c kết luận khớp met', '23514', 'ck_sla_period_met', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.sla_period (id, tenant_id, api_version_id, period, result_version, status, recalculated_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), '2026-10', 2, 'PENDING', now(), 'system', 'system');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('19d mỗi kỳ chỉ một kết quả hiện hành', '23505', 'uq_sla_period_current', SQLSTATE, SQLERRM);
END $$;
INSERT INTO ph02_catalog.sla_maintenance_window (id, tenant_id, api_version_id, starts_at, ends_at, reason, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), '2026-12-01 18:00+07', '2026-12-01 22:00+07', 'Nâng cấp CSDL', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph02_catalog.sla_maintenance_window (id, tenant_id, api_version_id, starts_at, ends_at, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), '2026-12-01 21:00+07', '2026-12-01 23:00+07', 'Chồng', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('19e cửa sổ bảo trì không chồng nhau', '23P01', 'ex_sla_maintenance_window_overlap', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.change_notice (id, tenant_id, api_version_id, kind, mandatory, subject, body, issued_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 'DEPRECATION', false, 'x', 'y', 'an', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('19f thông báo bắt buộc không tắt được', '23514', 'ck_change_notice_mandatory', SQLSTATE, SQLERRM);
END $$;

-- 20. Hàng đợi đồng bộ quốc gia (BR-02-009)
INSERT INTO ph02_catalog.national_sync_record (id, tenant_id, api_version_id, action, payload_hash, created_by, updated_by)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 'UPSERT', repeat('1', 64), 'system', 'system');
DO $$ BEGIN
  INSERT INTO ph02_catalog.national_sync_record (id, tenant_id, api_version_id, action, payload_hash, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 'UPSERT', repeat('1', 64), 'system', 'system');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('20 xếp hàng lặp cùng nội dung vô hại', '23505', 'uq_national_sync_record_pending', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.national_sync_record (id, tenant_id, api_version_id, action, payload_hash, status, sent_at, acked_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 'UPSERT', repeat('2', 64), 'ACKED', now(), now(), 'system', 'system');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('20b ACKED phải có mã quốc gia', '23514', 'ck_national_sync_record_acked', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.national_sync_record (id, tenant_id, api_version_id, action, payload_hash, status, sent_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68b'), 'UPSERT', repeat('3', 64), 'REJECTED', now(), 'system', 'system');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('20c REJECTED phải có lý do', '23514', 'ck_national_sync_record_rejected', SQLSTATE, SQLERRM);
END $$;

-- 21. Hộp gửi: đúng tenant, không bí mật, không nội dung đặc tả
DO $$ BEGIN
  INSERT INTO ph02_catalog.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.catalog.api.updated.v1', 't01.catalog.api.updated.v1', 'Api', 'x', 'x', '{}', repeat('0', 32));
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('21 topic phải thuộc tenant', '23514', 'ck_outbox_event_topic_tenant', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'vn.datahub.catalog.api.updated.v1', 't68.catalog.api.updated.v1', 'Api', 'x', 'x', '{"specContent":"openapi: 3.1.0"}', repeat('0', 32));
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('21b sự kiện không mang nội dung đặc tả', '23514', 'ck_outbox_event_no_secret', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  UPDATE ph02_catalog.outbox_event SET payload = '{}';
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('21c outbox không sửa được nội dung', '42501', 'permission denied', SQLSTATE, SQLERRM);
END $$;
UPDATE ph02_catalog.outbox_event SET published_at = now();
DO $$ BEGIN RAISE NOTICE 'PASS 21d chỉ đánh dấu đã phát (published_at) được phép'; END $$;

-- 22. Bộ đếm cấu hình chỉ tăng
INSERT INTO ph02_catalog.config_epoch (id, tenant_id, env, source_version, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'PROD', 5, 'system', 'system');
UPDATE ph02_catalog.config_epoch SET source_version = source_version + 1 WHERE tenant_id = 'T68' AND env = 'PROD';
DO $$ BEGIN
  UPDATE ph02_catalog.config_epoch SET source_version = 1 WHERE tenant_id = 'T68' AND env = 'PROD';
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('22 source_version chỉ tăng', '55000', 'chỉ tăng', SQLSTATE, SQLERRM);
END $$;

-- 23. Phân loại, API hệ cũ, lũy đẳng nhập
DO $$ BEGIN
  INSERT INTO ph02_catalog.category (id, tenant_id, category_code, name, path, parent_id, created_by, updated_by)
  VALUES (pg_temp.id('n68'), 'T68', 'dat-dai-2', 'x', 'x', pg_temp.id('n68'), 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('23 nhóm không là cha của chính nó', '23514', 'ck_category_self', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, system_code, owner_org_code, data_class, origin, base_path, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T68', 'tu-apim', 'x', 'X', 'X', 'INTERNAL', 'LEGACY', '/nhom/tu-apim', 'an', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('23b API hệ cũ phải có legacy_id', '23514', 'ck_api_legacy', SQLSTATE, SQLERRM);
END $$;

-- 24. Tìm kiếm toàn văn không dấu (FR-02-003)
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph02_catalog.api_search_doc WHERE tsv @@ websearch_to_tsquery('ph02_catalog.vn_unaccent', 'ho so dat dai');
  IF n <> 1 THEN RAISE 'FAIL 24: % kết quả', n; END IF;
  RAISE NOTICE 'PASS 24 "ho so dat dai" khớp "Hồ sơ đất đai" (vn_unaccent)';
END $$;

-- 25. Nhật ký tác vụ lũy đẳng, TTL
DO $$ BEGIN
  INSERT INTO ph02_catalog.idempotency_record (id, tenant_id, principal, idem_key, request_hash, expires_at, created_by)
  VALUES (gen_random_uuid(), 'T68', 'an', 'k1', repeat('a', 64), now() + interval '30 days', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('25 hạn lũy đẳng tối đa 48 giờ', '23514', 'ck_idempotency_record_ttl', SQLSTATE, SQLERRM);
END $$;

-- 26. Bí mật trong kết quả quét: chỉ dấu vân tay
DO $$ BEGIN
  INSERT INTO ph02_catalog.lint_finding (id, tenant_id, api_version_id, spec_id, run_id, layer, severity, rule_id, message, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), pg_temp.id('s68'), gen_random_uuid(), 'SECRET', 'ERROR', 'SCAN-02-03', 'Khóa đám mây', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('26 phát hiện bí mật phải có dấu vân tay, không có chuỗi khớp', '23514', 'ck_lint_finding_secret', SQLSTATE, SQLERRM);
END $$;
DO $$ BEGIN
  INSERT INTO ph02_catalog.lint_finding (id, tenant_id, api_version_id, spec_id, run_id, layer, severity, rule_id, message, fingerprint, status, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('v68'), pg_temp.id('s68'), gen_random_uuid(), 'SECRET', 'ERROR', 'SCAN-02-03', 'Khóa đám mây', repeat('f', 16), 'ACKNOWLEDGED', 'an');
  RAISE EXCEPTION 'KHONG-CHAN';
EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('26b xác nhận "không phải bí mật" cần người và lý do', '23514', 'ck_lint_finding_ack', SQLSTATE, SQLERRM);
END $$;

-- 27. Vai trò chỉ đọc không đọc được bảng nhạy cảm
RESET ROLE;
SET ROLE ph02_readonly;
SET app.tenant_id = 'T68';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph02_catalog.api; IF n <> 3 THEN RAISE 'FAIL 27: % API', n; END IF;
  BEGIN
    PERFORM count(*) FROM ph02_catalog.idempotency_record;
    RAISE EXCEPTION 'KHONG-CHAN';
  EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.ok('27 ph02_readonly không đọc idempotency_record', '42501', 'permission denied', SQLSTATE, SQLERRM);
  END;
END $$;
RESET ROLE;
\echo 'Hoàn tất: mọi khối PASS'
