-- =============================================================================
-- D03-03-PH02 · Tệp 90: di trú bảng W1 ph02.api_service (apps/control) sang schema mới
-- KHÔNG nằm trong ph02_all.sql. Chạy riêng khi môi trường còn bảng W1 (context migrate-w1):
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -v tenant=T01 -f ph02_90_migrate_w1.sql
-- Mỗi dòng cũ thành một API ở trạng thái DRAFT, phiên bản 1.0.0, chưa có đặc tả:
-- openapi_yaml (TEXT) phải đẩy lên kho đối tượng, nên bước này do W1SpecMigrator (dh-connect)
-- đọc bảng ph02.api_service_legacy_w1, ghi đặc tả vào Garage rồi tạo api_spec. Bảng cũ được
-- đổi tên, không xóa, cho tới khi đối soát xong (SDD 2.4, GAP-02-01).
-- Chạy bằng dh_connect_migrator: thành viên ph02_owner và có quyền trên schema ph02 của W1
-- (cần quyền ALTER bảng cũ). FORCE RLS vẫn áp dụng nên app.tenant_id được đặt ở đầu giao dịch.
-- =============================================================================
\set ON_ERROR_STOP on
\if :{?tenant}
\else
  \set tenant T01
\endif

-- @changeset ph02-9000-migrate-w1 context:migrate-w1 splitStatements:false
BEGIN;
SELECT set_config('app.tenant_id', :'tenant', true) \gset
DO $mig$
DECLARE
  v_tenant text := current_setting('app.tenant_id');
  n integer;
BEGIN
  IF to_regclass('ph02.api_service') IS NULL THEN
    RAISE NOTICE 'Không có bảng ph02.api_service của W1, bỏ qua';
    RETURN;
  END IF;
  CREATE TEMP TABLE w1_map ON COMMIT DROP AS
    SELECT s.id AS old_id, md5('w1:api:' || s.id::text)::uuid AS api_id, md5('w1:ver:' || s.id::text)::uuid AS ver_id,
           CASE WHEN left(regexp_replace(lower(s.service_code), '[^a-z0-9-]', '-', 'g'), 63) ~ '^[a-z][a-z0-9-]{2,62}$'
                THEN left(regexp_replace(lower(s.service_code), '[^a-z0-9-]', '-', 'g'), 63)
                ELSE 'w1-' || left(md5(s.service_code), 12) END AS code,
           s.title, s.status, s.route_file, s.public_path, s.created_at
      FROM ph02.api_service s;
  INSERT INTO ph02_catalog.api (id, tenant_id, api_code, name, description, system_code, owner_org_code, data_class, visibility,
                                base_path, origin, legacy_id, created_by, updated_by)
  SELECT m.api_id, v_tenant, m.code, left(m.title, 255),
         'Chuyển từ W1 ph02.api_service (trạng thái cũ ' || m.status || '); cần nạp lại đặc tả và gửi duyệt.',
         'CHUA-GAN', 'CHUA-GAN', 'INTERNAL', 'TENANT', '/w1/' || m.code, 'LEGACY', 'w1:ph02.api_service/' || m.old_id::text,
         'system:migrate', 'system:migrate'
    FROM w1_map m
  ON CONFLICT (tenant_id, api_code) DO NOTHING;
  GET DIAGNOSTICS n = ROW_COUNT;
  INSERT INTO ph02_catalog.api_version (id, tenant_id, api_id, version_no, major, status, release_notes, created_by, updated_by)
  SELECT m.ver_id, v_tenant, m.api_id, '1.0.0', 1, 'DRAFT',
         'Chuyển từ W1; route_file cũ: ' || coalesce(m.route_file, '(không có)') || '; public_path cũ: ' || coalesce(m.public_path, '(không có)'),
         'system:migrate', 'system:migrate'
    FROM w1_map m JOIN ph02_catalog.api a ON a.id = m.api_id AND a.tenant_id = v_tenant
  ON CONFLICT (tenant_id, api_id, version_no) DO NOTHING;
  INSERT INTO ph02_catalog.code_registry (id, tenant_id, kind, code, subject_id, created_by)
  SELECT md5('w1:reg:api:' || m.code)::uuid, v_tenant, 'API', m.code, m.api_id, 'system:migrate'
    FROM w1_map m JOIN ph02_catalog.api a ON a.id = m.api_id AND a.tenant_id = v_tenant
  ON CONFLICT (tenant_id, kind, code) DO NOTHING;
  INSERT INTO ph02_catalog.code_registry (id, tenant_id, kind, code, subject_id, created_by)
  SELECT md5('w1:reg:ver:' || m.code)::uuid, v_tenant, 'VERSION', m.code || '@1.0.0', m.ver_id, 'system:migrate'
    FROM w1_map m JOIN ph02_catalog.api a ON a.id = m.api_id AND a.tenant_id = v_tenant
  ON CONFLICT (tenant_id, kind, code) DO NOTHING;
  RAISE NOTICE 'Đã chuyển % API từ W1 sang tenant %', n, v_tenant;
  EXECUTE 'ALTER TABLE ph02.api_service RENAME TO api_service_legacy_w1';
END
$mig$;
COMMIT;
-- @rollback ALTER TABLE IF EXISTS ph02.api_service_legacy_w1 RENAME TO api_service;
