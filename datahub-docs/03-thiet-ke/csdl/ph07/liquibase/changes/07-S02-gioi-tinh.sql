--liquibase formatted sql
-- Nguồn: seed/07-S02-gioi-tinh.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-S02-gioi-tinh splitStatements:false context:seed-common runOnChange:true runInTransaction:false
-- =============================================================================
-- D03-03-PH07 · Dữ liệu nền S02 — Danh mục GIOI_TINH (COMMON)
-- Mẫu đầy đủ một vòng đời: tạo danh mục, phiên bản nháp 1, thuộc tính, bản
-- ghi, tính phân cấp, phát hành. Idempotent theo mã danh mục.
--
-- NGUỒN: danh mục giới tính dùng trong CSDL quốc gia về dân cư. Bộ mã dưới
-- đây là ĐỀ XUẤT, CẦN XÁC MINH với văn bản ban hành danh mục dùng chung hiện
-- hành trước khi đưa lên môi trường thật (Q07-51). Khi PH-14 kết nối được
-- NDXP DMDC, danh mục chuyển sang source_type NATIONAL và đồng bộ ghi đè.
-- =============================================================================
BEGIN;
SET LOCAL app.tenant_id = 'PLATFORM';

DO $seed$
DECLARE
  c_actor   constant uuid := '0192f000-0000-7000-8000-00000000a001';
  c_catalog constant uuid := '0192f000-0000-7000-8000-000000000201';
  c_version constant uuid := '0192f000-0000-7000-8000-000000000211';
BEGIN
  IF EXISTS (SELECT 1 FROM ph07_rdm.catalog WHERE tenant_id = 'COMMON' AND code = 'GIOI_TINH' AND deleted_at IS NULL) THEN
    RAISE NOTICE 'GIOI_TINH đã có, bỏ qua';
    RETURN;
  END IF;

  INSERT INTO ph07_rdm.catalog (id, tenant_id, code, name, description, group_id, source_type, classification,
                                status, is_hierarchical, max_depth, require_approval, created_by, updated_by)
  VALUES (c_catalog, 'COMMON', 'GIOI_TINH', 'Giới tính',
          'Danh mục giới tính dùng chung cho các HTTT (mẫu dữ liệu nền; bộ mã cần xác minh với nguồn quốc gia).',
          '0192f000-0000-7000-8000-000000000102', 'LOCAL', 'PUBLIC', 'DRAFT', false, 1, true, c_actor, c_actor);

  INSERT INTO ph07_rdm.catalog_version (id, tenant_id, catalog_id, version_no, status, legal_basis, change_note, origin,
                                        created_by, updated_by, last_edited_by, last_edited_at)
  VALUES (c_version, 'COMMON', c_catalog, 1, 'DRAFT', 'Cần xác minh: văn bản ban hành danh mục dùng chung về dân cư',
          'Dữ liệu nền khởi tạo', 'MIGRATION', c_actor, c_actor, c_actor, now());

  INSERT INTO ph07_rdm.attribute_def (id, tenant_id, version_id, code, label, data_type, required, max_length,
                                      sort_order, queryable, created_by, updated_by)
  VALUES ('0192f000-0000-7000-8000-000000000221', 'COMMON', c_version, 'ten_tieng_anh', 'Tên tiếng Anh', 'STRING', false, 64, 10, false, c_actor, c_actor);

  INSERT INTO ph07_rdm.catalog_item (id, tenant_id, catalog_id, version_id, code, name, sort_order, attrs, created_by, updated_by)
  VALUES
    ('0192f000-0000-7000-8000-000000000231', 'COMMON', c_catalog, c_version, '0', 'Chưa có thông tin', 0, '{"ten_tieng_anh":"Unknown"}', c_actor, c_actor),
    ('0192f000-0000-7000-8000-000000000232', 'COMMON', c_catalog, c_version, '1', 'Nam',               1, '{"ten_tieng_anh":"Male"}',    c_actor, c_actor),
    ('0192f000-0000-7000-8000-000000000233', 'COMMON', c_catalog, c_version, '2', 'Nữ',                2, '{"ten_tieng_anh":"Female"}',  c_actor, c_actor),
    ('0192f000-0000-7000-8000-000000000234', 'COMMON', c_catalog, c_version, '3', 'Khác',              3, '{"ten_tieng_anh":"Other"}',   c_actor, c_actor);

  PERFORM * FROM ph07_rdm.f_recompute_hierarchy(c_version);

  -- Phát hành (origin MIGRATION nên được hồi tố ngày hiệu lực, BR-07-027).
  UPDATE ph07_rdm.catalog_version
     SET status = 'PUBLISHED', effective_from = DATE '2025-07-01',
         item_count = 4, stats = '{"added":4,"changed":0,"deprecated":0,"removed":0,"breaking":false}',
         published_by = c_actor, published_at = now(), updated_by = c_actor
   WHERE id = c_version;
  UPDATE ph07_rdm.catalog SET status = 'ACTIVE', current_version_id = c_version, updated_by = c_actor
   WHERE id = c_catalog;
  INSERT INTO ph07_rdm.version_review (id, tenant_id, version_id, action, actor, comment)
  VALUES (ph07_rdm.f_uuid_v7(), 'COMMON', c_version, 'PUBLISH', c_actor, 'Dữ liệu nền');
END
$seed$;

COMMIT;
--rollback empty
