-- G1 · kiểm DDL chạy thật: RLS bảng catalog_group (F-07-010, D03-10, CC-TEST-03).
-- Chạy SAU ddl + seed, bằng superuser; tự tạo vai trò đăng nhập thử thành viên ph07_app.
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'g1_app') THEN
    CREATE ROLE g1_app LOGIN IN ROLE ph07_app;
  END IF;
END $$;
SET ROLE g1_app;
BEGIN; SET LOCAL app.tenant_id = 'T68'; DELETE FROM ph07_rdm.catalog_group WHERE code = 'G1_T68'; COMMIT;

BEGIN;
SET LOCAL app.tenant_id = 'T68';
INSERT INTO ph07_rdm.catalog_group (id, tenant_id, code, name, created_by, updated_by)
VALUES ('0192f000-0000-7000-8000-0000000068a1', 'T68', 'G1_T68', 'Nhóm T68',
        '0192f000-0000-7000-8000-00000000b001', '0192f000-0000-7000-8000-00000000b001');
-- T68 thấy nhóm của mình và COMMON
DO $$ BEGIN
  IF (SELECT count(*) FROM ph07_rdm.catalog_group WHERE tenant_id = 'T68') <> 1 THEN RAISE 'T68 không thấy nhóm của mình'; END IF;
  IF (SELECT count(*) FROM ph07_rdm.catalog_group WHERE tenant_id = 'COMMON') < 1 THEN RAISE 'T68 không thấy nhóm COMMON'; END IF;
END $$;
-- T68 không sửa được COMMON (0 dòng, không lỗi)
DO $$ DECLARE n int; BEGIN
  UPDATE ph07_rdm.catalog_group SET name = 'x' WHERE tenant_id = 'COMMON';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE 'T68 sửa được nhóm COMMON (%)', n; END IF;
END $$;
COMMIT;

BEGIN;
SET LOCAL app.tenant_id = 'T01';
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM ph07_rdm.catalog_group WHERE tenant_id = 'T68') THEN RAISE 'Rò rỉ chéo tenant: T01 thấy nhóm T68'; END IF;
END $$;
-- T01 ghi giả tenant khác bị chặn
DO $$ BEGIN
  BEGIN
    INSERT INTO ph07_rdm.catalog_group (id, tenant_id, code, name, created_by, updated_by)
    VALUES ('0192f000-0000-7000-8000-0000000001a1', 'T68', 'GIA_MAO', 'x',
            '0192f000-0000-7000-8000-00000000b001', '0192f000-0000-7000-8000-00000000b001');
    RAISE 'T01 chèn được dòng tenant T68';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
COMMIT;

-- Quên đặt app.tenant_id trên kết nối đã dùng (pool): biến về '' nên không thấy dòng tenant nào
-- (SS-07-07: chỉ kết nối MỚI mới báo lỗi; nhóm COMMON vẫn thấy vì là dữ liệu dùng chung).
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM ph07_rdm.catalog_group WHERE tenant_id <> 'COMMON') THEN RAISE 'Lộ dữ liệu tenant khi chưa đặt app.tenant_id'; END IF;
END $$;

-- Dọn
BEGIN; SET LOCAL app.tenant_id = 'T68';
DELETE FROM ph07_rdm.catalog_group WHERE code = 'G1_T68';
COMMIT;
RESET ROLE;
\echo 'OK 10-rls-catalog-group'
