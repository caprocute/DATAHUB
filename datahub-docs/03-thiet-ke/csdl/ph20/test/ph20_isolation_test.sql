-- =============================================================================
-- D03-03-PH20 · Kiểm thử DDL ph20_tenant: cô lập tenant (T90, T91, T92), RLS đặc thù bảng tenant, phiên PLATFORM,
-- ràng buộc nghiệp vụ (bốn mắt, duy nhất có điều kiện, máy trạng thái), bất biến, phân vùng, thiếu biến phiên.
-- Chạy sau ph20_tenant.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph20_isolation_test.sql
-- Mỗi khối kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE làm dừng tệp.
-- Vai kiểm thử: dh_platform_app (thành viên ph20_app), dh_platform_ctl (ph20_platform_app), dh_report_ro (ph20_ro).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_app') THEN
    CREATE ROLE dh_platform_app LOGIN NOBYPASSRLS IN ROLE ph20_app;
  ELSE
    GRANT ph20_app TO dh_platform_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_ctl') THEN
    CREATE ROLE dh_platform_ctl LOGIN NOBYPASSRLS IN ROLE ph20_platform_app;
  ELSE
    GRANT ph20_platform_app TO dh_platform_ctl;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph20_ro;
  ELSE
    GRANT ph20_ro TO dh_report_ro;
  END IF;
  GRANT ph20_owner TO CURRENT_USER;
END $$;
\o /dev/null

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
CREATE FUNCTION pg_temp.rows(p_sql text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  EXECUTE p_sql;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;
CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['t90','t91','t92','au90','au91','au92','o1','o2','o3','o4','o5','c1','ct1','pc1','run1','run2','st1','sm1','qcr1','qcr2','lc1','lc2','lc3','lc4','sh1','cv1','cd1','us1','us2','us3','qa1',
  'ur1','ur2','fo1','fo2','fo3','tm1','tm2','ff1','ts1','cp1','cp2','mw1','mw2','oij1','oij2','ori1','ori2','ori3','mp1','mp2','mm1','mm2','mpr1','mc1','mc2','rel1','rel2','rc1','sub1','up1','uw1','tu1','tu2','lt1','lt2',
  'ob1','ob2','ob3','pkg1','pki1','qo1','ib1','tq1']) k;
GRANT SELECT ON ids TO PUBLIC;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

-- ---------- 0. Dữ liệu nền sau DDL ----------
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant), 2, 'nền: hai tenant đặc biệt PLATFORM và COMMON');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.platform_module), 20, 'nền: 20 phân hệ PH-01…20');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.platform_module WHERE wave = 1), 12, 'nền: 12 phân hệ đợt 1 (MVP)');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.platform_module WHERE is_core), 4, 'nền: bốn phân hệ lõi PH-12, 13, 18, 20');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.module_dependency WHERE module_code = depends_on_code), 0, 'nền: không phân hệ nào phụ thuộc chính mình');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.provisioning_template WHERE template_code = 'tinh-chuan' AND status = 'PUBLISHED'), 1, 'nền: mẫu khởi tạo tinh-chuan PUBLISHED');
SELECT pg_temp.eq((SELECT count(*) FROM jsonb_object_keys((SELECT default_quota FROM ph20_tenant.provisioning_template WHERE template_code = 'tinh-chuan'))), 12, 'nền: mẫu tinh-chuan có 12 hạn mức mặc định');
SELECT pg_temp.eq((SELECT jsonb_array_length(step_plan) FROM ph20_tenant.provisioning_template WHERE template_code = 'tinh-chuan'), 17, 'nền: mẫu tinh-chuan có 17 bước saga');
RESET ROLE;
CALL ph20_tenant.p_seed_platform();
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.platform_module), 20, 'p_seed_platform chạy lại không nhân bản');

-- ---------- 1. Bảng tenant: tạo T90, T91, T92 và ràng buộc ----------
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, status, realm, scale_profile, template_id, config_path, created_by, updated_by)
SELECT pg_temp.id(x.k), x.c, 'PROVINCE', x.n, pg_temp.id(x.au), 'PROVISIONING', 'dh-' || lower(x.c), 'QM-VUA', (SELECT id FROM ph20_tenant.provisioning_template WHERE template_code = 'tinh-chuan'),
       'tenants/' || x.c || '/', 'pa1', 'pa1'
FROM (VALUES ('t90', 'T90', 'Tỉnh thử nghiệm 90', 'au90'), ('t91', 'T91', 'Tỉnh thử nghiệm 91', 'au91'), ('t92', 'T92', 'Tỉnh thử nghiệm 92', 'au92')) AS x(k, c, n, au);
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant), 5, 'PLATFORM thấy mọi tenant: 5 dòng');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'T93', 'PROVINCE', 'Trùng ĐVHC', (SELECT admin_unit_id FROM ph20_tenant.tenant WHERE code = 'T90'), 'dh-t93', 'pa1', 'pa1')$$, '23505', 'một ĐVHC cấp tỉnh chỉ một tenant đang hoạt động');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'T9', 'PROVINCE', 'x', gen_random_uuid(), 'dh-t9', 'pa1', 'pa1')$$, '23514', 'mã tenant sai dạng T9');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'X90', 'PROVINCE', 'x', gen_random_uuid(), 'dh-x90', 'pa1', 'pa1')$$, '23514', 'mã tenant sai dạng X90');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM2', 'PLATFORM', 'x', 'dh-platform2', 'pa1', 'pa1')$$, '23514', 'mã đặc biệt phải đúng PLATFORM hoặc COMMON');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'T94', 'PLATFORM', 'x', gen_random_uuid(), 'dh-t94', 'pa1', 'pa1')$$, '23514', 'kind PLATFORM không đi với mã Tnn');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T95', 'PROVINCE', 'x', 'pa1', 'pa1')$$, '23514', 'tenant tỉnh bắt buộc có ĐVHC và realm');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'T96', 'PROVINCE', 'x', gen_random_uuid(), 'dh-sai', 'pa1', 'pa1')$$, '23514', 'realm phải là dh-{mã thường}');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, isolation_mode, created_by, updated_by) VALUES (gen_random_uuid(), 'T97', 'PROVINCE', 'x', gen_random_uuid(), 'dh-t97', 'SEPARATE', 'pa1', 'pa1')$$, '23514', 'chế độ cách ly ngoài danh sách');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET status = 'SUSPENDED' WHERE code = 'T90'$$, '55000', 'PROVISIONING không sang SUSPENDED trực tiếp');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET status = 'ACTIVE' WHERE code = 'T90'$$, '23514', 'ACTIVE bắt buộc có activated_at');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET code = 'T98' WHERE code = 'T90'$$, '55000', 'mã tenant bất biến');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET status = 'MERGED' WHERE code = 'COMMON'$$, '55000', 'tenant COMMON không đổi trạng thái');
SELECT pg_temp.expect($$DELETE FROM ph20_tenant.tenant WHERE code = 'T92'$$, '42501', 'ứng dụng không có quyền xóa tenant');
UPDATE ph20_tenant.tenant SET status = 'ACTIVE', activated_at = now(), status_reason = 'Khởi tạo xong' WHERE code IN ('T90', 'T91', 'T92');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant WHERE status = 'ACTIVE'), 5, 'T90, T91, T92 sang ACTIVE theo máy trạng thái');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET status = 'DECOMMISSIONED' WHERE code = 'T92'$$, '55000', 'ACTIVE không chấm dứt trực tiếp, phải qua SUSPENDED');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET status = 'MERGED' WHERE code = 'T92'$$, '55000', 'ACTIVE không sang MERGED trực tiếp');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET merged_into_id = id WHERE code = 'T92'$$, '23514', 'tenant không tự sáp nhập vào chính mình');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant), 1, 'vai nền tảng với phiên T90 chỉ thấy dòng T90');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'T99', 'PROVINCE', 'x', gen_random_uuid(), 'dh-t99', 'pa1', 'pa1')$$, '42501', 'chỉ phiên PLATFORM được ghi bảng tenant');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.provisioning_template), 0, 'phiên T90 không thấy mẫu khởi tạo (dữ liệu nền tảng)');
RESET ROLE;

-- Vai tenant (ph20_app): chỉ thấy dòng của mình, không ghi tenant
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant), 1, 'tenant T90 chỉ thấy một dòng tenant');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant WHERE code = 'T91'), 0, 'tenant T90 không thấy T91');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant WHERE code = 'T90'), 0, 'tenant T91 không thấy T90');
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant), 1, 'vai ph20_app giả phiên PLATFORM chỉ thấy dòng PLATFORM, không thấy tenant khác');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant SET name = 'x' WHERE code = 'PLATFORM'$$, '42501', 'vai ph20_app không có quyền sửa tenant');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant (id, code, kind, name, admin_unit_id, realm, created_by, updated_by) VALUES (gen_random_uuid(), 'T99', 'PROVINCE', 'x', gen_random_uuid(), 'dh-t99', 'x', 'x')$$, '42501', 'vai ph20_app không có quyền thêm tenant');
RESET ROLE;

-- Trigger bảo vệ tenant: kiểm dưới chủ schema
SET ROLE ph20_owner;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.expect($$DELETE FROM ph20_tenant.tenant WHERE code = 'COMMON'$$, '55000', 'trigger chặn xóa dòng tenant kể cả chủ schema');
RESET ROLE;

-- ---------- 2. Tổ chức (bảng theo tenant, tenant tự ghi) ----------
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';
INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES
  (pg_temp.id('o1'), 'T90', 'UBND', 'Ủy ban nhân dân tỉnh T90', 'PROVINCE_PC', pg_temp.id('au90'), '2025-07-01', 'ta90', 'ta90');
INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, parent_id, admin_unit_id, is_data_owner, effective_from, created_by, updated_by) VALUES
  (pg_temp.id('o2'), 'T90', 'SO-NV', 'Sở Nội vụ', 'DEPARTMENT', pg_temp.id('o1'), pg_temp.id('au90'), true, '2025-07-01', 'ta90', 'ta90'),
  (pg_temp.id('o3'), 'T90', 'SO-TC', 'Sở Tài chính', 'DEPARTMENT', pg_temp.id('o1'), pg_temp.id('au90'), false, '2025-07-01', 'ta90', 'ta90');
SET app.tenant_id = 'T91';
INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES
  (pg_temp.id('o4'), 'T91', 'UBND', 'Ủy ban nhân dân tỉnh T91', 'PROVINCE_PC', pg_temp.id('au91'), '2025-07-01', 'ta91', 'ta91');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 1, 'T91 chỉ thấy tổ chức của mình');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'X1', 'x', 'OTHER', gen_random_uuid(), '2025-07-01', 'ta91', 'ta91')$$, '42501', 'WITH CHECK: không ghi tổ chức mang tenant khác');
SELECT pg_temp.eq(pg_temp.rows($$UPDATE ph20_tenant.organization SET name = 'đổi' WHERE tenant_id = 'T90'$$), 0, 'không sửa được tổ chức của tenant khác (0 dòng)');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, parent_id, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'SO-X', 'x', 'DEPARTMENT', pg_temp.id('o1'), gen_random_uuid(), '2025-07-01', 'ta91', 'ta91')$$, '23503', 'khóa ngoại kép chặn cấp trên thuộc tenant khác');
SELECT pg_temp.expect($$DELETE FROM ph20_tenant.organization WHERE code = 'UBND'$$, '42501', 'tổ chức không xóa cứng (quyền DELETE bị thu)');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 3, 'T90 thấy ba tổ chức của mình');
SELECT pg_temp.expect($$UPDATE ph20_tenant.organization SET parent_id = id WHERE code = 'SO-NV'$$, '23514', 'tổ chức không tự làm cấp trên của mình');
SELECT pg_temp.expect($$UPDATE ph20_tenant.organization SET successor_id = id WHERE code = 'SO-NV'$$, '23514', 'tổ chức không tự kế thừa chính mình');
SELECT pg_temp.expect($$UPDATE ph20_tenant.organization SET parent_id = (SELECT id FROM ph20_tenant.organization WHERE code = 'SO-NV') WHERE code = 'UBND'$$, '23514', 'chặn chu trình cấp trên UBND → SO-NV → UBND');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, effective_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SO-Z', 'x', 'DEPARTMENT', gen_random_uuid(), '2026-01-01', '2025-12-31', 'ta90', 'ta90')$$, '23514', 'effective_to không nhỏ hơn effective_from');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, status, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SO-Y', 'x', 'DEPARTMENT', 'DISSOLVED', gen_random_uuid(), '2025-01-01', 'ta90', 'ta90')$$, '23514', 'giải thể phải có ngày hết hiệu lực');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, status, admin_unit_id, effective_from, effective_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SO-W', 'x', 'DEPARTMENT', 'MERGED', gen_random_uuid(), '2025-01-01', '2025-12-31', 'ta90', 'ta90')$$, '23514', 'sáp nhập tổ chức phải có tổ chức kế thừa');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SO-NV', 'trùng mã', 'DEPARTMENT', gen_random_uuid(), '2025-01-01', 'ta90', 'ta90')$$, '23505', 'mã tổ chức duy nhất trong tenant');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SO-V', 'x', 'KHAC', gen_random_uuid(), '2025-01-01', 'ta90', 'ta90')$$, '23514', 'org_type ngoài danh sách');
SELECT pg_temp.expect($$UPDATE ph20_tenant.organization SET code = 'SO-NV2' WHERE code = 'SO-NV'$$, '55000', 'mã tổ chức bất biến');
UPDATE ph20_tenant.organization SET status = 'DISSOLVED', effective_to = '2026-06-30', successor_id = pg_temp.id('o2') WHERE code = 'SO-TC';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization WHERE status = 'DISSOLVED' AND successor_id = pg_temp.id('o2')), 1, 'giải thể tổ chức có tổ chức kế thừa');
RESET ROLE;

-- Phiên PLATFORM đọc tổ chức mọi tenant bằng vai nền tảng, không ghi được
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 4, 'PLATFORM (vai nền tảng) đọc tổ chức của mọi tenant');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SO-P', 'x', 'DEPARTMENT', gen_random_uuid(), '2025-01-01', 'pa1', 'pa1')$$, '42501', 'PLATFORM không ghi dữ liệu tổ chức của tỉnh');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 1, 'vai nền tảng với phiên T91 chỉ thấy tổ chức T91');
RESET ROLE;
SET ROLE dh_platform_app;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 0, 'vai ph20_app giả phiên PLATFORM không đọc được dữ liệu tổ chức tenant');
RESET ROLE;
SET ROLE dh_report_ro;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 4, 'vai chỉ đọc với phiên PLATFORM đọc liên tenant (kiểm toán nền tảng)');
SELECT pg_temp.expect($$DELETE FROM ph20_tenant.organization$$, '42501', 'vai chỉ đọc không xóa được');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.organization), 3, 'vai chỉ đọc với phiên T90 chỉ thấy tổ chức T90');
RESET ROLE;

-- ---------- 3. Bảng tenant tự quản: cài đặt, chính sách liên tenant, bảo trì, nhập tổ chức ----------
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';
INSERT INTO ph20_tenant.tenant_settings (id, tenant_id, display_name, it_owner_org_id, created_by, updated_by) VALUES (pg_temp.id('ts1'), 'T90', 'Tỉnh T90', pg_temp.id('o2'), 'ta90', 'ta90');
INSERT INTO ph20_tenant.cross_tenant_policy (id, tenant_id, allow_write, max_hours, created_by, updated_by) VALUES (pg_temp.id('cp1'), 'T90', false, 4, 'ta90', 'ta90');
INSERT INTO ph20_tenant.maintenance_window (id, tenant_id, name, window_type, day_of_week, start_time, duration_minutes, created_by, updated_by) VALUES (pg_temp.id('mw1'), 'T90', 'Chủ nhật hằng tuần', 'RECURRING', 7, '01:00', 180, 'ta90', 'ta90');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_settings (id, tenant_id, display_name, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'Trùng', 'ta90', 'ta90')$$, '23505', 'mỗi tenant một dòng cài đặt tỉnh');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_settings (id, tenant_id, display_name, idle_session_minutes, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'x', 2, 'ta90', 'ta90')$$, '42501', 'không ghi cài đặt cho tenant khác');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant_settings SET idle_session_minutes = 2 WHERE tenant_id = 'T90'$$, '23514', 'thời gian rảnh phiên ngoài khoảng 5…480 phút');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.cross_tenant_policy (id, tenant_id, max_hours, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 4, 'ta90', 'ta90')$$, '23505', 'mỗi tenant một chính sách liên tenant');
SELECT pg_temp.expect($$UPDATE ph20_tenant.cross_tenant_policy SET max_hours = 0 WHERE tenant_id = 'T90'$$, '23514', 'thời hạn liên tenant tối thiểu 1 giờ');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.maintenance_window (id, tenant_id, name, window_type, duration_minutes, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 'RECURRING', 120, 'ta90', 'ta90')$$, '23514', 'cửa sổ định kỳ cần thứ và giờ bắt đầu');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.maintenance_window (id, tenant_id, name, window_type, starts_at, ends_at, duration_minutes, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 'ONE_OFF', '2026-12-01 20:00+07', '2026-12-01 19:00+07', 120, 'ta90', 'ta90')$$, '23514', 'cửa sổ một lần phải kết thúc sau khi bắt đầu');
INSERT INTO ph20_tenant.file_object (id, tenant_id, bucket, object_path, file_name, content_type, size_bytes, sha256, scan_status, data_class_id, purpose, created_by, updated_by)
VALUES (pg_temp.id('fo1'), 'T90', 'dh-t90-import', 'org/2026/to-chuc.xlsx', 'to-chuc.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 20480, repeat('a', 64), 'CLEAN', gen_random_uuid(), 'ORG_IMPORT', 'ta90', 'ta90');
INSERT INTO ph20_tenant.org_import_job (id, tenant_id, file_id, format, mode, status, total_rows, valid_rows, error_rows, created_by, updated_by) VALUES (pg_temp.id('oij1'), 'T90', pg_temp.id('fo1'), 'XLSX', 'UPSERT', 'PREVIEWED', 3, 2, 1, 'ta90', 'ta90');
INSERT INTO ph20_tenant.org_import_row (id, tenant_id, job_id, row_no, org_code, action, status, data, created_by, updated_by) VALUES
  (pg_temp.id('ori1'), 'T90', pg_temp.id('oij1'), 1, 'SO-YT', 'CREATE', 'VALID', '{"name": "Sở Y tế"}', 'ta90', 'ta90'),
  (pg_temp.id('ori2'), 'T90', pg_temp.id('oij1'), 2, 'SO-GD', 'CREATE', 'VALID', '{"name": "Sở Giáo dục"}', 'ta90', 'ta90'),
  (pg_temp.id('ori3'), 'T90', pg_temp.id('oij1'), 3, NULL, 'ERROR', 'ERROR', '{}', 'ta90', 'ta90');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.org_import_job (id, tenant_id, file_id, format, total_rows, valid_rows, error_rows, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('fo1'), 'CSV', 3, 3, 1, 'ta90', 'ta90')$$, '23514', 'số dòng hợp lệ cộng dòng lỗi không vượt tổng');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.org_import_row (id, tenant_id, job_id, row_no, action, status, data, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('oij1'), 4, 'CREATE', 'ERROR', '{}', 'ta90', 'ta90')$$, '23514', 'dòng lỗi phải có hành động ERROR');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.org_import_row (id, tenant_id, job_id, row_no, action, status, data, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('oij1'), 1, 'SKIP', 'VALID', '{}', 'ta90', 'ta90')$$, '23505', 'số dòng duy nhất trong lô nhập');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_settings) + (SELECT count(*) FROM ph20_tenant.cross_tenant_policy) + (SELECT count(*) FROM ph20_tenant.maintenance_window) + (SELECT count(*) FROM ph20_tenant.org_import_job) + (SELECT count(*) FROM ph20_tenant.org_import_row) + (SELECT count(*) FROM ph20_tenant.file_object), 0, 'T91 không thấy cài đặt, chính sách, bảo trì, lô nhập, tệp của T90');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.org_import_job (id, tenant_id, file_id, format, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('fo1'), 'XLSX', 'ta91', 'ta91')$$, '23503', 'khóa ngoại kép chặn dùng tệp của tenant khác');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.file_object (id, tenant_id, bucket, object_path, file_name, content_type, size_bytes, sha256, data_class_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'Bucket_Sai', 'a', 'a', 'text/csv', 1, repeat('b', 64), gen_random_uuid(), 'x', 'x')$$, '23514', 'tên bucket phải dạng dh-...');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.file_object (id, tenant_id, bucket, object_path, file_name, content_type, size_bytes, sha256, data_class_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'dh-t91-export', 'a', 'a', 'text/csv', 1, 'xyz', gen_random_uuid(), 'x', 'x')$$, '23514', 'sha256 phải là 64 ký tự hex');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.file_object (id, tenant_id, bucket, object_path, file_name, content_type, size_bytes, sha256, scan_status, data_class_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'dh-t91-export', 'a', 'a', 'text/csv', 1, repeat('b', 64), 'UNKNOWN', gen_random_uuid(), 'x', 'x')$$, '23514', 'scan_status ngoài PENDING, CLEAN, INFECTED');
RESET ROLE;
-- PLATFORM chỉ đọc nhóm bảng tự quản
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_settings), 1, 'PLATFORM đọc cài đặt tỉnh');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.cross_tenant_policy (id, tenant_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'pa1', 'pa1')$$, '42501', 'PLATFORM không ghi chính sách liên tenant thay tỉnh');
RESET ROLE;

-- ---------- 4. Bản ghi điều khiển về tenant (PLATFORM ghi, tenant đọc) ----------
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph20_tenant.file_object (id, tenant_id, bucket, object_path, file_name, content_type, size_bytes, sha256, scan_status, data_class_id, purpose, created_by, updated_by)
VALUES (pg_temp.id('fo2'), 'T90', 'dh-t90-contract', 'hop-dong/hd-001.pdf', 'hd-001.pdf', 'application/pdf', 102400, repeat('c', 64), 'CLEAN', gen_random_uuid(), 'CONTRACT', 'pa1', 'pa1'),
       (pg_temp.id('fo3'), 'T91', 'dh-t91-contract', 'hop-dong/hd-002.pdf', 'hd-002.pdf', 'application/pdf', 102400, repeat('d', 64), 'CLEAN', gen_random_uuid(), 'CONTRACT', 'pa1', 'pa1');
INSERT INTO ph20_tenant.tenant_contact (id, tenant_id, contact_type, full_name, email, is_primary, created_by, updated_by) VALUES (pg_temp.id('c1'), 'T90', 'LEADER', 'Nguyễn Văn A', 'a@example.vn', true, 'pa1', 'pa1');
INSERT INTO ph20_tenant.tenant_contract (id, tenant_id, contract_no, title, status, signed_at, valid_from, valid_to, file_id, created_by, updated_by)
VALUES (pg_temp.id('ct1'), 'T90', 'HD-T90-2026', 'Hợp đồng dịch vụ Datahub năm 2026', 'ACTIVE', '2026-01-05', '2026-01-10', '2026-12-31', pg_temp.id('fo2'), 'pa1', 'pa1');
INSERT INTO ph20_tenant.tenant_platform_config (id, tenant_id, realm_code, api_host, api_path_prefix, kafka_prefix, bucket_prefix, created_by, updated_by) VALUES (pg_temp.id('pc1'), 'T90', 'dh-t90', 'api.t90.example.vn', '/t90', 't90.', 'dh-t90-', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_contact (id, tenant_id, contact_type, full_name, email, is_primary, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'LEADER', 'Người khác', 'b@example.vn', true, 'pa1', 'pa1')$$, '23505', 'mỗi loại đầu mối một đầu mối chính đang hoạt động');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_contact (id, tenant_id, contact_type, full_name, email, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TECHNICAL', 'x', 'khong-hop-le', 'pa1', 'pa1')$$, '23514', 'thư điện tử đầu mối sai dạng');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_contract (id, tenant_id, contract_no, title, valid_from, valid_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HD-X', 'x', '2026-06-01', '2026-05-01', 'pa1', 'pa1')$$, '23514', 'hợp đồng hết hạn trước khi bắt đầu');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_contract (id, tenant_id, contract_no, title, valid_from, file_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'HD-Y', 'x', '2026-06-01', pg_temp.id('fo3'), 'pa1', 'pa1')$$, '23503', 'hợp đồng không trỏ tệp của tenant khác');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_platform_config (id, tenant_id, realm_code, kafka_prefix, bucket_prefix, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'dh-t90', 't91.', 'dh-t91-', 'pa1', 'pa1')$$, '23505', 'realm không trùng giữa các tenant');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_platform_config (id, tenant_id, realm_code, last_commit_sha, kafka_prefix, bucket_prefix, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'dh-t91', 'khong-phai-sha', 't91.', 'dh-t91-', 'pa1', 'pa1')$$, '23514', 'mã commit phải là 40 ký tự hex');
-- Kế hoạch mô-đun, cờ tính năng
INSERT INTO ph20_tenant.tenant_module (id, tenant_id, module_code, state, enabled_at, created_by, updated_by) VALUES (pg_temp.id('tm1'), 'T90', 'PH-12', 'ENABLED', now(), 'pa1', 'pa1'),
  (pg_temp.id('tm2'), 'T90', 'PH-19', 'DISABLED', NULL, 'pa1', 'pa1');
INSERT INTO ph20_tenant.tenant_feature_flag (id, tenant_id, module_code, flag_code, enabled, created_by, updated_by) VALUES (pg_temp.id('ff1'), 'T90', 'PH-17', 'ph17.assistant', false, 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_module (id, tenant_id, module_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-12', 'pa1', 'pa1')$$, '23505', 'mỗi (tenant, phân hệ) một dòng');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_module (id, tenant_id, module_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-99', 'pa1', 'pa1')$$, '23503', 'phân hệ phải có trong danh mục nền tảng');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_module (id, tenant_id, module_code, state, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'PH-12', 'ENABLED', 'pa1', 'pa1')$$, '23514', 'ENABLED phải có enabled_at');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_feature_flag (id, tenant_id, flag_code, rollout_percent, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'ph17.x', 150, 'pa1', 'pa1')$$, '23514', 'tỷ lệ phát hành cờ 0…100');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_feature_flag (id, tenant_id, flag_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'ph17.assistant', 'pa1', 'pa1')$$, '23505', 'mỗi tenant một cờ theo flag_code');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.module_dependency (id, tenant_id, module_code, depends_on_code, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'PH-03', 'PH-03', 'pa1', 'pa1')$$, '23514', 'phân hệ không phụ thuộc chính mình');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.module_dependency (id, tenant_id, module_code, depends_on_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-03', 'PH-04', 'pa1', 'pa1')$$, '42501', 'phụ thuộc phân hệ là dữ liệu nền tảng, RLS chặn dòng mang tenant_id khác PLATFORM');
-- Hạn mức từ mẫu
CALL ph20_tenant.p_init_tenant_quota('T90', 'system:saga');
CALL ph20_tenant.p_init_tenant_quota('T90', 'system:saga');
CALL ph20_tenant.p_init_tenant_quota('T91', 'system:saga');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_quota WHERE tenant_id = 'T90'), 12, 'p_init_tenant_quota: 12 hạn mức cho T90, chạy lại không nhân bản');
SELECT pg_temp.eq((SELECT limit_value FROM ph20_tenant.tenant_quota WHERE tenant_id = 'T90' AND resource_code = 'API_RPS')::bigint, 500, 'hạn mức mặc định API_RPS = 500');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant_quota SET limit_value = -1 WHERE tenant_id = 'T90' AND resource_code = 'USERS'$$, '23514', 'hạn mức không âm');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_quota (id, tenant_id, resource_code, limit_value, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'GPU', 1, 'x', 'pa1', 'pa1')$$, '23514', 'loại hạn mức ngoài 12 giá trị');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_quota (id, tenant_id, resource_code, limit_value, unit, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'USERS', 1, 'user', 'pa1', 'pa1')$$, '23505', 'mỗi (tenant, tài nguyên) một hạn mức');
-- Đề nghị đổi hạn mức: bốn mắt
INSERT INTO ph20_tenant.quota_change_request (id, tenant_id, resource_code, current_value, requested_value, status, reason, ticket_code, requested_by, created_by, updated_by)
VALUES (pg_temp.id('qcr1'), 'T90', 'API_RPS', 500, 800, 'DRAFT', 'Tăng tải dịch vụ công trực tuyến cuối năm', 'PT-001', 'pa1', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.quota_change_request (id, tenant_id, resource_code, current_value, requested_value, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API_RPS', 500, 900, 'x', 'PT-002', 'pa1', 'pa1', 'pa1')$$, '23505', 'mỗi (tenant, tài nguyên) một đề nghị đổi hạn mức đang mở');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.quota_change_request (id, tenant_id, resource_code, current_value, requested_value, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'USERS', 500, 500, 'x', 'PT-003', 'pa1', 'pa1', 'pa1')$$, '23514', 'giá trị đề nghị phải khác giá trị hiện tại');
UPDATE ph20_tenant.quota_change_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('qcr1');
SELECT pg_temp.expect($$UPDATE ph20_tenant.quota_change_request SET status = 'APPROVED', approved_by = 'pa1', approved_at = now() WHERE id = pg_temp.id('qcr1')$$, '23514', 'bốn mắt: người duyệt không được trùng người đề nghị (hạn mức)');
SELECT pg_temp.expect($$UPDATE ph20_tenant.quota_change_request SET status = 'APPROVED' WHERE id = pg_temp.id('qcr1')$$, '23514', 'APPROVED bắt buộc có người duyệt');
SELECT pg_temp.expect($$UPDATE ph20_tenant.quota_change_request SET status = 'DONE' WHERE id = pg_temp.id('qcr1')$$, '55000', 'PENDING_APPROVAL không sang DONE trực tiếp');
SELECT pg_temp.expect($$UPDATE ph20_tenant.quota_change_request SET requested_value = 999 WHERE id = pg_temp.id('qcr1')$$, '55000', 'giá trị đề nghị bất biến sau khi lập');
UPDATE ph20_tenant.quota_change_request SET status = 'APPROVED', approved_by = 'pa2', approved_at = now() WHERE id = pg_temp.id('qcr1');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.quota_change_request WHERE status = 'APPROVED' AND approved_by <> requested_by), 1, 'duyệt bốn mắt đạt khi hai PA khác nhau');
-- Ghi đè tạm thời
INSERT INTO ph20_tenant.quota_override (id, tenant_id, resource_code, override_value, valid_from, valid_to, reason, ticket_code, requested_by, approved_by, created_by, updated_by)
VALUES (pg_temp.id('qo1'), 'T90', 'API_RPS', 1000, '2026-12-01', '2026-12-15', 'Cao điểm cuối năm', 'PT-010', 'pa1', 'pa2', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.quota_override (id, tenant_id, resource_code, override_value, valid_from, valid_to, reason, ticket_code, requested_by, approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'USERS', 3000, '2026-12-01', '2026-12-15', 'x', 'PT-011', 'pa1', 'pa1', 'pa1', 'pa1')$$, '23514', 'bốn mắt: người duyệt ghi đè không trùng người đề nghị');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.quota_override (id, tenant_id, resource_code, override_value, valid_from, valid_to, reason, ticket_code, requested_by, approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'USERS', 3000, '2026-12-15', '2026-12-01', 'x', 'PT-012', 'pa1', 'pa2', 'pa1', 'pa1')$$, '23514', 'valid_to phải sau valid_from');
RESET ROLE;

-- ---------- 5. Saga khởi tạo: lần chạy, bước, kiểm tra khói ----------
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph20_tenant.provisioning_run (id, tenant_id, run_kind, status, template_id, requested_by, started_at, created_by, updated_by)
VALUES (pg_temp.id('run1'), 'T90', 'INITIAL', 'RUNNING', (SELECT template_id FROM ph20_tenant.tenant WHERE code = 'T90'), 'pa1', now(), 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_run (id, tenant_id, run_kind, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SUPPLEMENT', 'RUNNING', 'pa1', 'pa1', 'pa1')$$, '23505', 'một tenant chỉ một lần chạy saga RUNNING');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_run (id, tenant_id, run_kind, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SUPPLEMENT', 'WAITING', 'pa1', 'pa1', 'pa1')$$, '23505', 'lần chạy WAITING cũng chiếm chỗ lần chạy đang hoạt động');
INSERT INTO ph20_tenant.provisioning_run (id, tenant_id, run_kind, status, requested_by, created_by, updated_by) VALUES (pg_temp.id('run2'), 'T91', 'INITIAL', 'RUNNING', 'pa1', 'pa1', 'pa1');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.provisioning_run WHERE status = 'RUNNING'), 2, 'hai tenant khác nhau chạy saga song song được');
SELECT pg_temp.expect($$UPDATE ph20_tenant.provisioning_run SET status = 'SUCCEEDED' WHERE id = pg_temp.id('run1')$$, '23514', 'SUCCEEDED bắt buộc có finished_at');
SELECT pg_temp.expect($$UPDATE ph20_tenant.provisioning_run SET current_step_code = 'S99_X' WHERE id = pg_temp.id('run1')$$, '23514', 'mã bước ngoài 17 bước S01…S17');
SELECT pg_temp.expect($$UPDATE ph20_tenant.provisioning_run SET run_kind = 'SUPPLEMENT' WHERE id = pg_temp.id('run1')$$, '55000', 'loại lần chạy bất biến');
INSERT INTO ph20_tenant.provisioning_step (id, tenant_id, run_id, step_code, step_order, status, executor, idempotency_ref, created_by, updated_by)
SELECT gen_random_uuid(), 'T90', pg_temp.id('run1'), s.c, s.o, 'SUCCEEDED', 'PH-20', pg_temp.id('run1')::text || ':' || s.c, 'saga', 'saga'
FROM (VALUES ('S01_RECORD', 1), ('S02_CONFIG_REPO', 2), ('S03_REALM', 3)) AS s(c, o);
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.provisioning_step WHERE run_id = pg_temp.id('run1')), 3, 'ba bước saga đầu ghi vào sổ bước');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_step (id, tenant_id, run_id, step_code, step_order, executor, idempotency_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('run1'), 'S01_RECORD', 1, 'PH-20', pg_temp.id('run1')::text || ':S01_RECORD', 's', 's')$$, '23505', 'mỗi lần chạy một dòng cho mỗi mã bước');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_step (id, tenant_id, run_id, step_code, step_order, executor, idempotency_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('run1'), 'S18_EXTRA', 18, 'PH-20', 'x', 's', 's')$$, '23514', 'mã bước ngoài danh sách');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_step (id, tenant_id, run_id, step_code, step_order, executor, idempotency_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('run1'), 'S04_SECRETS', 4, 'PH-20', 'khong-dung-dang', 's', 's')$$, '23514', 'khóa lũy đẳng bước phải dạng {runId}:{stepCode}');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_step (id, tenant_id, run_id, step_code, step_order, executor, idempotency_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('run1'), 'S04_SECRETS', 4, 'PH-20', pg_temp.id('run1')::text || ':S04_SECRETS', 's', 's')$$, '23503', 'khóa ngoại kép chặn bước của tenant khác trỏ vào lần chạy T90');
INSERT INTO ph20_tenant.smoke_test_result (id, tenant_id, run_id, check_code, result, duration_ms, created_by, updated_by) VALUES (pg_temp.id('sm1'), 'T90', pg_temp.id('run1'), 'CROSS_TENANT_LEAK', 'PASS', 850, 'saga', 'saga');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.smoke_test_result (id, tenant_id, run_id, check_code, result, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('run1'), 'PING', 'PASS', 's', 's')$$, '23514', 'ca kiểm tra khói ngoài bốn ca chuẩn');
SELECT pg_temp.expect($$UPDATE ph20_tenant.smoke_test_result SET result = 'FAIL' WHERE id = pg_temp.id('sm1')$$, '42501', 'ứng dụng không có quyền sửa kết quả kiểm tra khói');
RESET ROLE;
SET ROLE ph20_owner;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.expect($$UPDATE ph20_tenant.smoke_test_result SET result = 'FAIL' WHERE id = pg_temp.id('sm1')$$, '55000', 'trigger chặn sửa kết quả kiểm tra khói (chỉ thêm)');
SELECT pg_temp.expect($$DELETE FROM ph20_tenant.smoke_test_result WHERE id = pg_temp.id('sm1')$$, '55000', 'trigger chặn xóa kết quả kiểm tra khói');
RESET ROLE;
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
UPDATE ph20_tenant.provisioning_run SET status = 'WAITING', current_step_code = 'S06_EVENTING' WHERE id = pg_temp.id('run1');
UPDATE ph20_tenant.provisioning_run SET status = 'RUNNING' WHERE id = pg_temp.id('run1');
UPDATE ph20_tenant.provisioning_run SET status = 'SUCCEEDED', finished_at = now(), duration_seconds = 2400 WHERE id = pg_temp.id('run1');
SELECT pg_temp.expect($$UPDATE ph20_tenant.provisioning_run SET status = 'RUNNING' WHERE id = pg_temp.id('run1')$$, '55000', 'SUCCEEDED là trạng thái cuối, không chạy lại');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.provisioning_run WHERE status = 'SUCCEEDED' AND duration_seconds <= 3600), 1, 'thời gian khởi tạo T90 không quá 1 giờ (NFR-00-057)');

-- ---------- 6. Vòng đời, lịch sử, gói bàn giao ----------
INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, status, suspend_reason, reason, ticket_code, requested_by, created_by, updated_by)
VALUES (pg_temp.id('lc1'), 'T90', 'SUSPEND', 'DRAFT', 'CONTRACT_EXPIRED', 'Hợp đồng hết hạn, chờ gia hạn', 'PT-100', 'pa1', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'SUSPEND', 'x', 'PT-101', 'pa1', 'pa1', 'pa1')$$, '23514', 'tạm ngừng bắt buộc có lý do SuspendReason');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, suspend_reason, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SUSPEND', 'OTHER', 'trùng loại đang mở', 'PT-102', 'pa1', 'pa1', 'pa1')$$, '23505', 'mỗi (tenant, loại) một đề nghị vòng đời đang mở');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, status, reason, ticket_code, requested_by, approved_by, approved_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'TERMINATE', 'APPROVED', 'x', 'PT-103', 'pa1', 'pa1', now(), 'pa1', 'pa1')$$, '23514', 'bốn mắt: chấm dứt tenant do cùng một người đề nghị và duyệt bị chặn');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, status, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'TERMINATE', 'APPROVED', 'x', 'PT-104', 'pa1', 'pa1', 'pa1')$$, '23514', 'chấm dứt tenant đã APPROVED phải có người duyệt');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'QUOTA_DECREASE', 'x', 'PT-105', 'pa1', 'pa1', 'pa1')$$, '23514', 'hạ hạn mức phải gắn đề nghị đổi hạn mức');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, reason, ticket_code, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'ISOLATION_CHANGE', 'x', 'PT-106', 'pa1', 'pa1', 'pa1')$$, '23514', 'đổi cách ly phải nêu chế độ đích');
SELECT pg_temp.expect($$UPDATE ph20_tenant.lifecycle_request SET status = 'DONE' WHERE id = pg_temp.id('lc1')$$, '55000', 'DRAFT không sang DONE trực tiếp');
SELECT pg_temp.expect($$UPDATE ph20_tenant.lifecycle_request SET request_type = 'TERMINATE' WHERE id = pg_temp.id('lc1')$$, '55000', 'loại đề nghị bất biến');
INSERT INTO ph20_tenant.lifecycle_request (id, tenant_id, request_type, status, reason, ticket_code, requested_by, approved_by, approved_at, created_by, updated_by)
VALUES (pg_temp.id('lc2'), 'T91', 'TERMINATE', 'APPROVED', 'Sáp nhập hoàn tất, hết thời gian lưu giữ', 'PT-107', 'pa1', 'pa2', now(), 'pa1', 'pa1');
SELECT pg_temp.expect($$SELECT 1/0$$, '22012', 'kiểm chứng công cụ expect bắt đúng SQLSTATE');
UPDATE ph20_tenant.lifecycle_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('lc1');
UPDATE ph20_tenant.lifecycle_request SET status = 'APPROVED', approved_by = 'pa2', approved_at = now() WHERE id = pg_temp.id('lc1');
UPDATE ph20_tenant.lifecycle_request SET status = 'EXECUTING' WHERE id = pg_temp.id('lc1');
UPDATE ph20_tenant.lifecycle_request SET status = 'DONE', executed_at = now() WHERE id = pg_temp.id('lc1');
INSERT INTO ph20_tenant.tenant_status_history (id, tenant_id, from_status, to_status, reason, ticket_code, request_id, changed_by, created_by, updated_by)
VALUES (pg_temp.id('sh1'), 'T90', 'ACTIVE', 'SUSPENDED', 'Hợp đồng hết hạn', 'PT-100', pg_temp.id('lc1'), 'pa2', 'pa2', 'pa2');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_status_history (id, tenant_id, from_status, to_status, changed_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'ACTIVE', 'ACTIVE', 'pa1', 'pa1', 'pa1')$$, '23514', 'lịch sử trạng thái phải đổi trạng thái thật');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_status_history (id, tenant_id, to_status, request_id, changed_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'SUSPENDED', pg_temp.id('lc1'), 'pa1', 'pa1', 'pa1')$$, '23503', 'lịch sử không trỏ đề nghị của tenant khác');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant_status_history SET reason = 'sửa' WHERE id = pg_temp.id('sh1')$$, '42501', 'ứng dụng không sửa lịch sử trạng thái');
UPDATE ph20_tenant.tenant SET status = 'SUSPENDED', suspended_at = now(), status_reason = 'Hợp đồng hết hạn' WHERE code = 'T90';
UPDATE ph20_tenant.tenant SET status = 'ACTIVE', status_reason = 'Gia hạn hợp đồng' WHERE code = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant WHERE code = 'T90' AND status = 'ACTIVE'), 1, 'tạm ngừng rồi khôi phục T90 theo máy trạng thái');
INSERT INTO ph20_tenant.data_export_package (id, tenant_id, request_id, status, requested_by, created_by, updated_by) VALUES (pg_temp.id('pkg1'), 'T91', pg_temp.id('lc2'), 'COLLECTING', 'pa1', 'pa1', 'pa1');
INSERT INTO ph20_tenant.data_export_item (id, tenant_id, package_id, module_code, item_type, status, created_by, updated_by) VALUES (pg_temp.id('pki1'), 'T91', pg_temp.id('pkg1'), 'PH-07', 'catalog', 'PENDING', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.data_export_package (id, tenant_id, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'REQUESTED', 'pa1', 'pa1', 'pa1')$$, '23505', 'mỗi tenant một gói bàn giao đang thu thập');
SELECT pg_temp.expect($$UPDATE ph20_tenant.data_export_package SET status = 'READY' WHERE id = pg_temp.id('pkg1')$$, '23514', 'gói READY bắt buộc có tệp và mã băm');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.data_export_item (id, tenant_id, package_id, module_code, item_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('pkg1'), 'PH-07', 'catalog', 'x', 'x')$$, '23505', 'mỗi gói một mục cho mỗi (phân hệ, loại dữ liệu)');
INSERT INTO ph20_tenant.tenant_config_version (id, tenant_id, version_no, git_commit_sha, content_hash, snapshot, created_by, updated_by) VALUES (pg_temp.id('cv1'), 'T90', 1, repeat('a', 40), repeat('b', 64), '{"realm": "dh-t90"}', 'saga', 'saga');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_config_version (id, tenant_id, version_no, git_commit_sha, content_hash, snapshot, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 1, repeat('c', 40), repeat('d', 64), '{}', 's', 's')$$, '23505', 'số phiên bản cấu hình duy nhất trong tenant');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant_config_version SET snapshot = '{"realm": "khac"}' WHERE id = pg_temp.id('cv1')$$, '55000', 'ảnh chụp cấu hình bất biến');
UPDATE ph20_tenant.tenant_config_version SET apply_status = 'APPLIED', applied_at = now() WHERE id = pg_temp.id('cv1');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_config_version WHERE apply_status = 'APPLIED'), 1, 'chỉ trạng thái áp được cập nhật trên phiên bản cấu hình');
INSERT INTO ph20_tenant.config_drift (id, tenant_id, status, differences, created_by, updated_by) VALUES (pg_temp.id('cd1'), 'T90', 'DRIFTED', '[{"path": "spec.quota", "type": "changed"}]', 'drift', 'drift');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.config_drift (id, tenant_id, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RECONCILING', 'd', 'd')$$, '23505', 'mỗi tenant một lệch cấu hình đang mở');
SELECT pg_temp.expect($$UPDATE ph20_tenant.config_drift SET status = 'IN_SYNC', resolution = 'RECONCILED' WHERE id = pg_temp.id('cd1')$$, '23514', 'lệch đã xử lý phải có người và thời điểm xử lý');
UPDATE ph20_tenant.config_drift SET status = 'IN_SYNC', resolution = 'RECONCILED', resolved_by = 'pa1', resolved_at = now() WHERE id = pg_temp.id('cd1');

-- ---------- 7. Sử dụng tài nguyên: phân vùng tháng, cảnh báo, báo cáo ----------
INSERT INTO ph20_tenant.usage_snapshot (id, tenant_id, resource_code, captured_at, used_value, limit_value, percent_used, source, created_by, updated_by) VALUES
  (pg_temp.id('us1'), 'T90', 'API_RPS', '2026-11-15 10:00:00+07', 320, 500, 64, 'APISIX', 'collector', 'collector'),
  (pg_temp.id('us2'), 'T90', 'API_RPS', '2026-10-15 10:00:00+07', 300, 500, 60, 'APISIX', 'collector', 'collector'),
  (pg_temp.id('us3'), 'T91', 'USERS', '2027-02-01 00:00:00+07', 150, 2000, 7.5, 'IAM', 'collector', 'collector');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.usage_snapshot WHERE tableoid::regclass::text = 'ph20_tenant.usage_snapshot_202611'), 1, 'ảnh chụp tháng 11/2026 nằm đúng phân vùng 202611 (giờ Việt Nam)');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.usage_snapshot WHERE tableoid::regclass::text = 'ph20_tenant.usage_snapshot_default'), 1, 'ảnh chụp tháng 10/2026 chưa có phân vùng, vào phân vùng mặc định');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.usage_snapshot WHERE tableoid::regclass::text = 'ph20_tenant.usage_snapshot_202702'), 1, 'phân vùng mẫu 202702 nhận ảnh chụp tháng 2/2027');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.usage_snapshot (id, tenant_id, resource_code, captured_at, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API_RPS', '2026-11-15 10:00:00+07', 1, 'c', 'c')$$, '23505', 'một ảnh chụp duy nhất cho (tenant, tài nguyên, thời điểm)');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.usage_snapshot (id, tenant_id, resource_code, captured_at, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API_RPS', now(), -5, 'c', 'c')$$, '23514', 'mức dùng không âm');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.usage_snapshot (id, tenant_id, resource_code, captured_at, used_value, source, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API_RPS', now(), 1, 'EXCEL', 'c', 'c')$$, '23514', 'nguồn số liệu ngoài danh sách');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.usage_snapshot (id, tenant_id, resource_code, captured_at, used_value, created_by, updated_by) VALUES (gen_random_uuid(), 'T77', 'API_RPS', now(), 1, 'c', 'c')$$, '23503', 'ảnh chụp phải thuộc tenant có thật');
INSERT INTO ph20_tenant.quota_alert (id, tenant_id, resource_code, alert_level, used_value, limit_value, percent_used, created_by, updated_by) VALUES (pg_temp.id('qa1'), 'T90', 'API_RPS', 'WARN_80', 410, 500, 82, 'alert', 'alert');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.quota_alert (id, tenant_id, resource_code, alert_level, used_value, limit_value, percent_used, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API_RPS', 'WARN_80', 420, 500, 84, 'a', 'a')$$, '23505', 'mỗi (tenant, tài nguyên, mức) một cảnh báo đang mở');
INSERT INTO ph20_tenant.quota_alert (id, tenant_id, resource_code, alert_level, used_value, limit_value, percent_used, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'API_RPS', 'LIMIT_100', 500, 500, 100, 'a', 'a');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.quota_alert (id, tenant_id, resource_code, alert_level, used_value, limit_value, percent_used, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'USERS', 'WARN_90', 1, 2, 90, 'a', 'a')$$, '23514', 'mức cảnh báo chỉ WARN_80 hoặc LIMIT_100');
INSERT INTO ph20_tenant.usage_report (id, tenant_id, report_scope, period_from, period_to, status, requested_by, created_by, updated_by) VALUES (pg_temp.id('ur1'), 'T90', 'TENANT', '2026-10-01', '2026-10-31', 'REQUESTED', 'ta90', 'ta90', 'ta90');
INSERT INTO ph20_tenant.usage_report (id, tenant_id, report_scope, period_from, period_to, status, requested_by, created_by, updated_by) VALUES (pg_temp.id('ur2'), 'PLATFORM', 'PLATFORM', '2026-10-01', '2026-10-31', 'REQUESTED', 'pa1', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.usage_report (id, tenant_id, report_scope, period_from, period_to, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PLATFORM', '2026-10-01', '2026-10-31', 'x', 'x', 'x')$$, '23514', 'báo cáo toàn nền tảng phải mang tenant_id PLATFORM');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.usage_report (id, tenant_id, report_scope, period_from, period_to, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'TENANT', '2026-11-01', '2026-10-01', 'x', 'x', 'x')$$, '23514', 'kỳ báo cáo đến ngày không nhỏ hơn từ ngày');
SELECT pg_temp.expect($$UPDATE ph20_tenant.usage_report SET status = 'READY' WHERE id = pg_temp.id('ur1')$$, '23514', 'báo cáo READY bắt buộc có tệp');
RESET ROLE;
-- Phân vùng: tạo thêm, chạy lại không nhân bản
SET ROLE ph20_owner;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'usage_snapshot'), 7, 'usage_snapshot có phân vùng mặc định và sáu phân vùng tháng mẫu');
CALL ph20_tenant.p_ensure_partitions('ph20_tenant.usage_snapshot', date '2026-11-01', 6);
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'usage_snapshot'), 7, 'p_ensure_partitions chạy lại không nhân bản');
CALL ph20_tenant.p_ensure_partitions('ph20_tenant.usage_snapshot', date '2027-07-01', 2);
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'usage_snapshot'), 9, 'p_ensure_partitions tạo thêm hai phân vùng 202707, 202708');
ALTER TABLE ph20_tenant.usage_snapshot DETACH PARTITION ph20_tenant.usage_snapshot_202708;
DROP TABLE ph20_tenant.usage_snapshot_202708;
SELECT pg_temp.eq((SELECT count(*) FROM pg_inherits i JOIN pg_class p ON p.oid = i.inhparent WHERE p.relname = 'usage_snapshot'), 8, 'dọn phân vùng hết hạn bằng DETACH và DROP');
RESET ROLE;

-- Tenant chỉ đọc bản ghi điều khiển về mình
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_quota), 12, 'T90 đọc 12 hạn mức của mình');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.usage_snapshot), 2, 'T90 đọc ảnh chụp sử dụng của mình, không thấy của T91');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.lifecycle_request) + (SELECT count(*) FROM ph20_tenant.tenant_status_history) + (SELECT count(*) FROM ph20_tenant.provisioning_run) + (SELECT count(*) FROM ph20_tenant.tenant_module), 5, 'T90 đọc vòng đời, lịch sử, lần chạy saga, phân hệ của mình');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.usage_report), 1, 'T90 chỉ thấy báo cáo sử dụng của mình, không thấy báo cáo toàn nền tảng');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant_quota SET limit_value = 999999 WHERE resource_code = 'API_RPS'$$, '42501', 'tenant không tự đổi hạn mức (chỉ PLATFORM ghi)');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_module (id, tenant_id, module_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-04', 'ta90', 'ta90')$$, '42501', 'tenant không tự bật phân hệ');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_quota), 12, 'T91 chỉ thấy 12 hạn mức của mình');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_quota WHERE tenant_id = 'T90'), 0, 'T91 không thấy hạn mức T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.quota_alert) + (SELECT count(*) FROM ph20_tenant.config_drift) + (SELECT count(*) FROM ph20_tenant.tenant_config_version) + (SELECT count(*) FROM ph20_tenant.tenant_contact) + (SELECT count(*) FROM ph20_tenant.tenant_contract), 0, 'T91 không thấy cảnh báo, lệch, phiên bản cấu hình, đầu mối, hợp đồng của T90');
RESET ROLE;

-- ---------- 8. Dữ liệu nền tảng: chỉ PLATFORM, một số bảng mọi tenant đọc ----------
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.platform_module), 20, 'tenant đọc danh mục 20 phân hệ để dựng menu');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.provisioning_template) + (SELECT count(*) FROM ph20_tenant.upgrade_plan) + (SELECT count(*) FROM ph20_tenant.leak_test_run), 0, 'tenant không thấy mẫu khởi tạo, kế hoạch nâng cấp, kết quả rò rỉ');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'PH-21', 'x', 1, 'x', 'x', 'x')$$, '42501', 'tenant không ghi danh mục phân hệ');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-21', 'x', 1, 'x', 'x', 'x')$$, '42501', 'tenant không ghi dữ liệu nền tảng mang tenant_id của mình');
RESET ROLE;
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-21', 'x', 1, 'x', 'x', 'x')$$, '42501', 'phiên PLATFORM không ghi dòng dữ liệu nền tảng mang tenant_id khác PLATFORM');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'PH-3', 'x', 1, 'x', 'x', 'x')$$, '23514', 'mã phân hệ sai dạng PH-nn');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'PH-21', 'x', 4, 'x', 'x', 'x')$$, '23514', 'đợt phát triển chỉ 1…3');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_template (id, tenant_id, template_code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'Mau_X', 'x', 'x', 'x')$$, '23514', 'mã mẫu khởi tạo phải dạng chữ thường gạch nối');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.provisioning_template (id, tenant_id, template_code, version_no, name, status, activated_at, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'tinh-chuan', 2, 'bản 2', 'PUBLISHED', now(), 'x', 'x')$$, '23505', 'mỗi mã mẫu một bản PUBLISHED');
SELECT pg_temp.expect($$UPDATE ph20_tenant.provisioning_template SET default_quota = '{}' WHERE template_code = 'tinh-chuan'$$, '55000', 'mẫu PUBLISHED bất biến, đổi bằng phiên bản mới');
SELECT pg_temp.expect($$UPDATE ph20_tenant.platform_module SET module_code = 'PH-99' WHERE module_code = 'PH-01'$$, '55000', 'mã phân hệ bất biến');
RESET ROLE;

SET ROLE ph20_owner;
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.platform_module (id, tenant_id, module_code, name, wave, du_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH-21', 'x', 1, 'x', 'x', 'x')$$, '23514', 'CHECK ck_platform_module_tenant: dữ liệu nền tảng bắt buộc tenant_id = PLATFORM');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.organization (id, tenant_id, code, name, org_type, admin_unit_id, effective_from, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'X', 'x', 'OTHER', gen_random_uuid(), '2025-01-01', 'x', 'x')$$, '42501', 'tổ chức không mang tenant_id PLATFORM (RLS và FK chặn)');
RESET ROLE;

-- ---------- 9. Sáp nhập ----------
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph20_tenant.merge_plan (id, tenant_id, plan_code, name, status, source_tenant_code, target_tenant_code, legal_basis, requested_by, created_by, updated_by)
VALUES (pg_temp.id('mp1'), 'PLATFORM', 'sap-nhap-t91-t90', 'Sáp nhập T91 vào T90', 'DRAFT', 'T91', 'T90', 'Nghị quyết giả định về sắp xếp đơn vị hành chính', 'pa1', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_plan (id, tenant_id, plan_code, name, source_tenant_code, target_tenant_code, legal_basis, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'sap-nhap-t91-t92', 'x', 'T91', 'T92', 'x', 'pa1', 'x', 'x')$$, '23505', 'một tenant chỉ một kế hoạch sáp nhập đang mở (theo tenant nguồn)');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_plan (id, tenant_id, plan_code, name, source_tenant_code, target_tenant_code, legal_basis, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'sap-nhap-tu-minh', 'x', 'T92', 'T92', 'x', 'pa1', 'x', 'x')$$, '23514', 'tenant nguồn và đích phải khác nhau');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_plan (id, tenant_id, plan_code, name, source_tenant_code, target_tenant_code, legal_basis, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'sap-nhap-t77', 'x', 'T77', 'T92', 'x', 'pa1', 'x', 'x')$$, '23503', 'tenant nguồn phải có trong registry');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_plan (id, tenant_id, plan_code, name, source_tenant_code, target_tenant_code, legal_basis, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'SAI MA', 'x', 'T92', 'T90', 'x', 'pa1', 'x', 'x')$$, '23514', 'mã kế hoạch sáp nhập chỉ chữ thường, số, gạch ngang');
SELECT pg_temp.expect($$UPDATE ph20_tenant.merge_plan SET status = 'COMPLETED' WHERE id = pg_temp.id('mp1')$$, '55000', 'DRAFT không sang COMPLETED trực tiếp');
UPDATE ph20_tenant.merge_plan SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('mp1');
SELECT pg_temp.expect($$UPDATE ph20_tenant.merge_plan SET status = 'APPROVED', approved_by = 'pa1', approved_at = now() WHERE id = pg_temp.id('mp1')$$, '23514', 'bốn mắt: người duyệt sáp nhập khác người lập');
SELECT pg_temp.expect($$UPDATE ph20_tenant.merge_plan SET status = 'APPROVED' WHERE id = pg_temp.id('mp1')$$, '23514', 'kế hoạch APPROVED phải có người duyệt');
SELECT pg_temp.expect($$UPDATE ph20_tenant.merge_plan SET source_tenant_code = 'T92' WHERE id = pg_temp.id('mp1')$$, '55000', 'tenant nguồn của kế hoạch bất biến');
UPDATE ph20_tenant.merge_plan SET status = 'APPROVED', approved_by = 'pa2', approved_at = now() WHERE id = pg_temp.id('mp1');
INSERT INTO ph20_tenant.merge_mapping (id, tenant_id, plan_id, mapping_type, source_ref, target_ref, status, created_by, updated_by) VALUES (pg_temp.id('mm1'), 'PLATFORM', pg_temp.id('mp1'), 'ORGANIZATION', 'UBND', 'UBND-91', 'CONFIRMED', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_mapping (id, tenant_id, plan_id, mapping_type, source_ref, status, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.id('mp1'), 'USER', 'u-1', 'CONFIRMED', 'x', 'x')$$, '23514', 'ánh xạ CONFIRMED phải có đối tượng đích');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_mapping (id, tenant_id, plan_id, mapping_type, source_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.id('mp1'), 'ORGANIZATION', 'UBND', 'x', 'x')$$, '23505', 'mỗi kế hoạch một ánh xạ cho mỗi đối tượng nguồn');
INSERT INTO ph20_tenant.merge_participant_run (id, tenant_id, plan_id, module_code, phase, status, created_by, updated_by) VALUES (pg_temp.id('mpr1'), 'PLATFORM', pg_temp.id('mp1'), 'PH-07', 'DRY_RUN', 'SUCCEEDED', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.merge_participant_run (id, tenant_id, plan_id, module_code, phase, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.id('mp1'), 'PH-07', 'DRY_RUN', 'x', 'x')$$, '23505', 'mỗi (kế hoạch, phân hệ, pha) một lần chuyển');
INSERT INTO ph20_tenant.merge_conflict (id, tenant_id, plan_id, participant_run_id, mapping_type, source_ref, target_ref, conflict_kind, created_by, updated_by) VALUES (pg_temp.id('mc1'), 'PLATFORM', pg_temp.id('mp1'), pg_temp.id('mpr1'), 'CATALOG_CODE', 'LOAI-DAT', 'LOAI-DAT', 'DUPLICATE_CODE', 'pa1', 'pa1');
SELECT pg_temp.expect($$UPDATE ph20_tenant.merge_conflict SET state = 'RESOLVED' WHERE id = pg_temp.id('mc1')$$, '23514', 'xung đột RESOLVED phải có cách xử lý, người và thời điểm');
UPDATE ph20_tenant.merge_conflict SET state = 'RESOLVED', resolution = 'RENAME_SOURCE', resolved_by = 'cb1', resolved_at = now() WHERE id = pg_temp.id('mc1');
RESET ROLE;
-- Bên tham gia đọc kế hoạch của mình
SET ROLE dh_platform_app;
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.merge_plan), 1, 'tenant nguồn T91 đọc kế hoạch sáp nhập của mình');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.merge_plan), 1, 'tenant đích T90 đọc kế hoạch sáp nhập của mình');
SET app.tenant_id = 'T92';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.merge_plan), 0, 'tenant ngoài cuộc T92 không thấy kế hoạch');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.merge_mapping) + (SELECT count(*) FROM ph20_tenant.merge_participant_run) + (SELECT count(*) FROM ph20_tenant.merge_conflict), 0, 'tenant ngoài cuộc không thấy ánh xạ, lần chuyển, xung đột');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.merge_mapping), 0, 'bên tham gia chỉ đọc kế hoạch, chi tiết ánh xạ qua API của PLATFORM');
SELECT pg_temp.expect($$UPDATE ph20_tenant.merge_plan SET status = 'CANCELLED' WHERE id = pg_temp.id('mp1')$$, '42501', 'tenant bên tham gia không sửa kế hoạch sáp nhập');
RESET ROLE;

-- ---------- 10. Phát hành, nâng cấp, kiểm thử rò rỉ ----------
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph20_tenant.product_release (id, tenant_id, version_code, name, status, release_notes, created_by, updated_by) VALUES (pg_temp.id('rel1'), 'PLATFORM', '1.0.0', 'Datahub 1.0.0', 'DRAFT', 'Bản đầu tiên', 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.product_release (id, tenant_id, version_code, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', '1.0', 'x', 'x')$$, '23514', 'số phiên bản phải dạng major.minor.patch');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.product_release (id, tenant_id, version_code, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', '1.0.0', 'x', 'x')$$, '23505', 'số phiên bản duy nhất');
SELECT pg_temp.expect($$UPDATE ph20_tenant.product_release SET status = 'STABLE', stable_at = now() WHERE id = pg_temp.id('rel1')$$, '55000', 'DRAFT không sang STABLE trực tiếp, phải qua PREVIEW');
SELECT pg_temp.expect($$UPDATE ph20_tenant.product_release SET status = 'PREVIEW' WHERE id = pg_temp.id('rel1')$$, '23514', 'PREVIEW phải có preview_at');
UPDATE ph20_tenant.product_release SET status = 'PREVIEW', preview_at = '2026-11-01 08:00+07' WHERE id = pg_temp.id('rel1');
SELECT pg_temp.expect($$UPDATE ph20_tenant.product_release SET status = 'STABLE', stable_at = '2026-10-01' WHERE id = pg_temp.id('rel1')$$, '23514', 'stable_at không trước preview_at');
UPDATE ph20_tenant.product_release SET status = 'STABLE', stable_at = '2026-11-20 08:00+07' WHERE id = pg_temp.id('rel1');
SELECT pg_temp.expect($$UPDATE ph20_tenant.product_release SET status = 'WITHDRAWN', withdrawn_at = now() WHERE id = pg_temp.id('rel1')$$, '23514', 'rút bản phải nêu lý do');
SELECT pg_temp.expect($$UPDATE ph20_tenant.product_release SET version_code = '9.9.9' WHERE id = pg_temp.id('rel1')$$, '55000', 'số phiên bản bất biến');
INSERT INTO ph20_tenant.release_component (id, tenant_id, release_id, component_code, component_type, digest, created_by, updated_by) VALUES (pg_temp.id('rc1'), 'PLATFORM', pg_temp.id('rel1'), 'dh-platform', 'SERVICE', 'sha256:' || repeat('e', 64), 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.release_component (id, tenant_id, release_id, component_code, component_type, digest, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.id('rel1'), 'dh-console', 'CONSOLE', 'md5:abc', 'x', 'x')$$, '23514', 'mã băm ảnh phải dạng sha256:...');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.release_component (id, tenant_id, release_id, component_code, component_type, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.id('rel1'), 'dh-platform', 'SERVICE', 'x', 'x')$$, '23505', 'mỗi bản phát hành một dòng cho mỗi thành phần');
INSERT INTO ph20_tenant.tenant_release_subscription (id, tenant_id, channel, current_release_id, is_pilot, created_by, updated_by) VALUES (pg_temp.id('sub1'), 'T90', 'PREVIEW', pg_temp.id('rel1'), true, 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_release_subscription (id, tenant_id, channel, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', 'BETA', 'x', 'x')$$, '23514', 'kênh phát hành chỉ STABLE hoặc PREVIEW');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_release_subscription (id, tenant_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 'x')$$, '23505', 'mỗi tenant một đăng ký kênh');
INSERT INTO ph20_tenant.upgrade_plan (id, tenant_id, plan_code, release_id, status, created_by, updated_by) VALUES (pg_temp.id('up1'), 'PLATFORM', 'nang-cap-1-0-0', pg_temp.id('rel1'), 'DRAFT', 'pa1', 'pa1');
INSERT INTO ph20_tenant.upgrade_wave (id, tenant_id, plan_id, wave_no, name, tenant_selector, tenant_count, created_by, updated_by) VALUES (pg_temp.id('uw1'), 'PLATFORM', pg_temp.id('up1'), 1, 'Sóng 1: tenant thí điểm', '{"pilot": true}', 1, 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.upgrade_plan (id, tenant_id, plan_code, release_id, error_threshold_percent, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'nang-cap-sai', pg_temp.id('rel1'), 150, 'x', 'x')$$, '23514', 'ngưỡng lỗi dừng sóng 0…100');
SELECT pg_temp.expect($$UPDATE ph20_tenant.upgrade_plan SET status = 'RUNNING' WHERE id = pg_temp.id('up1')$$, '23514', 'kế hoạch RUNNING phải có started_at');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.upgrade_wave (id, tenant_id, plan_id, wave_no, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', pg_temp.id('up1'), 1, 'x', 'x')$$, '23505', 'mỗi kế hoạch một sóng cho mỗi số thứ tự');
INSERT INTO ph20_tenant.tenant_upgrade (id, tenant_id, plan_id, wave_id, release_id, status, maintenance_window_id, created_by, updated_by) VALUES (pg_temp.id('tu1'), 'T90', pg_temp.id('up1'), pg_temp.id('uw1'), pg_temp.id('rel1'), 'PENDING', pg_temp.id('mw1'), 'pa1', 'pa1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_upgrade (id, tenant_id, plan_id, wave_id, release_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('up1'), pg_temp.id('uw1'), pg_temp.id('rel1'), 'x', 'x')$$, '23505', 'mỗi sóng một nâng cấp cho mỗi tenant');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.tenant_upgrade (id, tenant_id, plan_id, wave_id, release_id, maintenance_window_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T91', pg_temp.id('up1'), pg_temp.id('uw1'), pg_temp.id('rel1'), pg_temp.id('mw1'), 'x', 'x')$$, '23503', 'nâng cấp không dùng cửa sổ bảo trì của tenant khác');
SELECT pg_temp.expect($$UPDATE ph20_tenant.tenant_upgrade SET status = 'ROLLED_BACK' WHERE id = pg_temp.id('tu1')$$, '23514', 'quay lui phải nêu phiên bản quay lui');
INSERT INTO ph20_tenant.leak_test_run (id, tenant_id, trigger_type, status, tenant_codes, tenants_tested, cases_total, cases_failed, finished_at, created_by, updated_by) VALUES (pg_temp.id('lt1'), 'PLATFORM', 'SCHEDULE', 'PASSED', '{T90,T91,T92}', 3, 120, 0, now(), 'job', 'job');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.leak_test_run (id, tenant_id, status, cases_total, cases_failed, finished_at, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'PASSED', 10, 2, now(), 'x', 'x')$$, '23514', 'lần kiểm PASSED không được có ca lỗi');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.leak_test_run (id, tenant_id, status, cases_total, cases_failed, created_by, updated_by) VALUES (gen_random_uuid(), 'PLATFORM', 'RUNNING', 5, 6, 'x', 'x')$$, '23514', 'số ca lỗi không vượt tổng số ca');
RESET ROLE;
SET ROLE dh_platform_app;
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.product_release) + (SELECT count(*) FROM ph20_tenant.release_component), 2, 'tenant đọc phiên bản sản phẩm và thành phần (ghi chú phát hành)');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_upgrade) + (SELECT count(*) FROM ph20_tenant.tenant_release_subscription), 0, 'T91 không thấy nâng cấp, đăng ký kênh của T90');
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.upgrade_plan) + (SELECT count(*) FROM ph20_tenant.upgrade_wave), 0, 'tenant không thấy kế hoạch nâng cấp và sóng');
SET app.tenant_id = 'T90';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.tenant_upgrade), 1, 'T90 đọc nâng cấp của mình');
RESET ROLE;

-- ---------- 11. Bảng kỹ thuật: outbox, inbox, lũy đẳng ----------
SET ROLE dh_platform_app;
SET app.tenant_id = 'T90';
INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES
  ('T90', pg_temp.id('ob1'), 'vn.datahub.tenant.org.changed.v1', 't90.tenant.org.changed.v1', 'organization', pg_temp.id('o1'), '{"code": "UBND"}', repeat('a', 32));
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 'x', 't91.tenant.org.changed.v1', 'organization', gen_random_uuid(), '{}', repeat('a', 32))$$, '23514', 'topic sự kiện tổ chức phải mang tiền tố đúng tenant');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 'x', 'platform.tenant.khong-co.v1', 'tenant', gen_random_uuid(), '{}', repeat('a', 32))$$, '23514', 'topic ngoài 16 sự kiện EVT-20');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T91', gen_random_uuid(), 'x', 't91.tenant.org.changed.v1', 'organization', gen_random_uuid(), '{}', repeat('a', 32))$$, '42501', 'WITH CHECK: không ghi outbox mang tenant khác');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 'x', 't90.tenant.org.changed.v1', 'organization', gen_random_uuid(), '[]', repeat('a', 32))$$, '23514', 'payload outbox phải là đối tượng JSON');
INSERT INTO ph20_tenant.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'org-sync', pg_temp.id('ib1'), 'common.rdm.adminunit.reorganized.v1');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.inbox_event (tenant_id, consumer, event_id, source_topic) VALUES ('T90', 'org-sync', pg_temp.id('ib1'), 'common.rdm.adminunit.reorganized.v1')$$, '23505', 'inbox khử trùng theo (tenant, bộ tiêu thụ, sự kiện)');
INSERT INTO ph20_tenant.idempotency_key (tenant_id, client_id, request_method, request_path, idempotency_ref, request_hash, expires_at) VALUES ('T90', 'dh-console', 'POST', '/api/tenant/v1/organizations', 'khoa-luy-dang-0000001', repeat('f', 64), now() + interval '24 hours');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.idempotency_key (tenant_id, client_id, request_method, request_path, idempotency_ref, request_hash, expires_at) VALUES ('T90', 'dh-console', 'POST', '/api/tenant/v1/organizations', 'ngan', repeat('f', 64), now())$$, '23514', 'khóa lũy đẳng 16…128 ký tự hợp lệ');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.idempotency_key (tenant_id, client_id, request_method, request_path, idempotency_ref, request_hash, expires_at) VALUES ('T90', 'dh-console', 'POST', '/api/tenant/v1/organizations', 'khoa-luy-dang-0000001', repeat('f', 64), now())$$, '23505', 'cùng khóa lũy đẳng không ghi hai lần');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.idempotency_key (tenant_id, client_id, request_method, request_path, idempotency_ref, request_hash, state, expires_at) VALUES ('T90', 'dh-console', 'POST', '/a', 'khoa-luy-dang-0000002', repeat('f', 64), 'COMPLETED', now())$$, '23514', 'yêu cầu COMPLETED phải có mã HTTP đã trả');
SET app.tenant_id = 'T91';
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.outbox) + (SELECT count(*) FROM ph20_tenant.inbox_event) + (SELECT count(*) FROM ph20_tenant.idempotency_key), 0, 'T91 không thấy outbox, inbox, khóa lũy đẳng của T90');
RESET ROLE;
SET ROLE dh_platform_ctl;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES
  ('T90', pg_temp.id('ob2'), 'vn.datahub.platform.tenant.status-changed.v1', 'platform.tenant.status-changed.v1', 'tenant', pg_temp.id('t90'), '{"tenant": "T90", "to": "SUSPENDED"}', repeat('b', 32));
SELECT pg_temp.eq((SELECT count(*) FROM ph20_tenant.outbox), 2, 'PLATFORM ghi và đọc outbox của mọi tenant (sự kiện vòng đời đi trên platform.*)');
RESET ROLE;

-- ---------- 12. Tổng kiểm cấu trúc ----------
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM pg_roles WHERE rolname IN ('ph20_owner', 'ph20_app', 'ph20_platform_app', 'ph20_ro', 'dh_platform_app', 'dh_platform_ctl', 'dh_report_ro') AND (rolbypassrls OR rolsuper);
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % vai trò có BYPASSRLS hoặc SUPERUSER', n; END IF;
  SELECT count(*) INTO n FROM pg_class c JOIN pg_roles r ON r.oid = c.relowner WHERE c.relnamespace = 'ph20_tenant'::regnamespace AND c.relkind IN ('r', 'p') AND r.rolname IN ('ph20_app', 'ph20_platform_app', 'ph20_ro', 'dh_platform_app', 'dh_platform_ctl', 'dh_report_ro');
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng thuộc sở hữu vai ứng dụng', n; END IF;
  SELECT count(*) INTO n FROM pg_class c WHERE c.relnamespace = 'ph20_tenant'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND NOT c.relforcerowsecurity;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng chưa FORCE RLS', n; END IF;
  SELECT count(*) INTO n FROM pg_class c WHERE c.relnamespace = 'ph20_tenant'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition
     AND NOT EXISTS (SELECT 1 FROM pg_policies p WHERE p.schemaname = 'ph20_tenant' AND p.tablename = c.relname AND p.policyname = 'tenant_isolation');
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng thiếu chính sách tenant_isolation', n; END IF;
  SELECT count(*) INTO n FROM pg_class c WHERE c.relnamespace = 'ph20_tenant'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname NOT IN ('outbox', 'inbox_event', 'idempotency_key')
     AND (SELECT count(*) FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname IN ('id', 'created_at', 'created_by', 'updated_at', 'updated_by', 'version') AND NOT a.attisdropped) <> 6;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng nghiệp vụ thiếu cột ngữ cảnh', n; END IF;
  SELECT count(*) INTO n FROM pg_class c WHERE c.relnamespace = 'ph20_tenant'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition AND c.relname <> 'tenant'
     AND NOT EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped);
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: % bảng (ngoài tenant) thiếu tenant_id', n; END IF;
  SELECT count(*) INTO n FROM pg_class c WHERE c.relnamespace = 'ph20_tenant'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition;
  IF n <> 45 THEN RAISE EXCEPTION 'FAIL: % bảng, mong 45', n; END IF;
  RAISE NOTICE 'PASS tổng kiểm: % bảng, mọi bảng FORCE RLS, có tenant_isolation, vai trò không BYPASSRLS và không sở hữu bảng', n;
END $$;

-- ---------- 13. Thiếu biến phiên app.tenant_id thì lỗi (kết nối mới) ----------
\o
\connect :DBNAME
\o /dev/null
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
SET ROLE dh_platform_app;
SELECT pg_temp.expect($$SELECT count(*) FROM ph20_tenant.organization$$, '42704', 'quên đặt app.tenant_id thì truy vấn tổ chức lỗi (current_setting không có tham số thứ hai)');
SELECT pg_temp.expect($$SELECT count(*) FROM ph20_tenant.tenant$$, '42704', 'quên đặt app.tenant_id thì truy vấn tenant lỗi');
SELECT pg_temp.expect($$INSERT INTO ph20_tenant.outbox (tenant_id, event_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES ('T90', gen_random_uuid(), 'x', 't90.tenant.org.changed.v1', 'organization', gen_random_uuid(), '{}', repeat('a', 32))$$, '42704', 'quên đặt app.tenant_id thì ghi outbox lỗi');
RESET ROLE;
SET ROLE dh_platform_ctl;
SELECT pg_temp.expect($$SELECT count(*) FROM ph20_tenant.tenant_quota$$, '42704', 'vai nền tảng quên đặt app.tenant_id cũng lỗi');
RESET ROLE;
\o
