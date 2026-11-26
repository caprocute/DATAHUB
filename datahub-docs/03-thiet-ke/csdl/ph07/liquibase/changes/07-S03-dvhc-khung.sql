--liquibase formatted sql
-- Nguồn: seed/07-S03-dvhc-khung.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-S03-dvhc-khung splitStatements:false context:seed-common runOnChange:true runInTransaction:false
-- =============================================================================
-- D03-03-PH07 · Dữ liệu nền S03 — KHUNG danh mục DVHC (COMMON) + DỮ LIỆU MẪU
--
-- !!! CẢNH BÁO: CÁC DÒNG BẢN GHI DƯỚI ĐÂY LÀ MẪU MINH HỌA, KHÔNG PHẢI DỮ LIỆU THẬT.
--   * Mã tỉnh 60, 67, 68 và tên tỉnh dùng để minh họa sắp xếp cấp tỉnh 2025
--     (Lâm Đồng, Đắk Nông, Bình Thuận hợp thành tỉnh Lâm Đồng) — cần đối chiếu
--     Nghị quyết 202/2025/QH15 và Quyết định 19/2025/QĐ-TTg trước khi dùng.
--   * Mã huyện 990–991 và mã xã 99xxx là MÃ GIẢ LẬP, tên "Mẫu …" là giả lập.
--   * Dữ liệu đầy đủ (34 tỉnh, 3.321 xã; lịch sử 63 tỉnh, ~705 huyện, ~10.6 nghìn
--     xã) nạp bằng tác vụ nhập tệp (API-07-033, khuôn STANDARD) từ tệp Bảng danh
--     mục và mã số ĐVHC ban hành kèm QĐ 19/2025/QĐ-TTg, KHÔNG nạp bằng tệp này.
--
-- Cấu trúc tạo ra:
--   catalog DVHC (COMMON, phân cấp, max_depth 3, level_names ["Tỉnh","Huyện","Xã"])
--   v1 (lịch sử 3 cấp) [2004-08-01, 2025-07-01)  — ngày bắt đầu là MẪU, cần xác minh
--   v2 (hiện hành 2 cấp) [2025-07-01, ∞)
--   item_succession của v2: MERGE tỉnh, ABOLISH huyện, MERGE xã, RECODE xã
--   admin_unit làm mới sau mỗi lần phát hành.
-- =============================================================================
BEGIN;
SET LOCAL app.tenant_id = 'PLATFORM';

DO $seed$
DECLARE
  c_actor   constant uuid := '0192f000-0000-7000-8000-00000000a001';
  c_catalog constant uuid := '0192f000-0000-7000-8000-000000000301';
  c_v1      constant uuid := '0192f000-0000-7000-8000-000000000311';
  c_v2      constant uuid := '0192f000-0000-7000-8000-000000000312';
  v_bad     record;
BEGIN
  IF EXISTS (SELECT 1 FROM ph07_rdm.catalog WHERE tenant_id = 'COMMON' AND code = 'DVHC' AND deleted_at IS NULL) THEN
    RAISE NOTICE 'DVHC đã có, bỏ qua';
    RETURN;
  END IF;

  INSERT INTO ph07_rdm.catalog (id, tenant_id, code, name, description, group_id, source_type, classification, status,
                                is_hierarchical, max_depth, level_names, require_approval, created_by, updated_by)
  VALUES (c_catalog, 'COMMON', 'DVHC', 'Đơn vị hành chính Việt Nam',
          'Bảng danh mục và mã số đơn vị hành chính. Hai cấp (Tỉnh, Xã) từ 01/7/2025; cấp Huyện chỉ trong phiên bản lịch sử.',
          '0192f000-0000-7000-8000-000000000101', 'LOCAL', 'PUBLIC', 'DRAFT',
          true, 3, '["Tỉnh","Huyện","Xã"]', true, c_actor, c_actor);

  -- ---------------------------------------------------------------- v1 lịch sử
  INSERT INTO ph07_rdm.catalog_version (id, tenant_id, catalog_id, version_no, status, legal_basis, change_note, origin,
                                        created_by, updated_by, last_edited_by, last_edited_at)
  VALUES (c_v1, 'COMMON', c_catalog, 1, 'DRAFT',
          'MẪU — cần xác minh: Quyết định 124/2004/QĐ-TTg và các văn bản sửa đổi đến 30/6/2025',
          'Ảnh chụp lịch sử ba cấp trước sắp xếp 2025 (dữ liệu mẫu)', 'MIGRATION', c_actor, c_actor, c_actor, now());

  -- Lược đồ thuộc tính DVHC (giống nhau ở v1 và v2; v2 sao chép copy-on-write).
  INSERT INTO ph07_rdm.attribute_def (id, tenant_id, version_id, code, label, data_type, required, enum_values,
                                      max_length, sort_order, queryable, searchable, description, created_by, updated_by)
  VALUES
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'level', 'Cấp', 'ENUM', true, '["PROVINCE","DISTRICT","COMMUNE"]', NULL, 10, true, false,
     'Cấp hành chính theo DD-07; DISTRICT chỉ có trong dữ liệu lịch sử.', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'unit_type', 'Loại đơn vị', 'ENUM', true,
     '["TINH","THANH_PHO","QUAN","HUYEN","THI_XA","XA","PHUONG","DAC_KHU","THI_TRAN"]', NULL, 20, true, false,
     'Tỉnh, thành phố, quận, huyện, thị xã, xã, phường, đặc khu, thị trấn.', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'ten_tieng_anh', 'Tên tiếng Anh', 'STRING', false, NULL, 255, 30, false, true, NULL, c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'ma_cu', 'Mã trước sắp xếp', 'STRING', false, NULL, 500, 40, true, false,
     'Danh sách mã đơn vị trước sắp xếp, phân cách dấu phẩy (thông tin tham khảo; quan hệ chuẩn ở item_succession).', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'can_cu_phap_ly', 'Căn cứ thành lập, sắp xếp', 'STRING', false, NULL, 500, 50, false, false, NULL, c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'dien_tich_km2', 'Diện tích (km²)', 'DECIMAL', false, NULL, NULL, 60, true, false, NULL, c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_v1, 'dan_so', 'Dân số', 'INTEGER', false, NULL, NULL, 70, true, false, NULL, c_actor, c_actor);

  INSERT INTO ph07_rdm.catalog_item (id, tenant_id, catalog_id, version_id, code, name, parent_code, level_name, sort_order, attrs, created_by, updated_by)
  VALUES
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '60',    'Tỉnh Bình Thuận',      NULL,  'Tỉnh',  60, '{"level":"PROVINCE","unit_type":"TINH"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '67',    'Tỉnh Đắk Nông',        NULL,  'Tỉnh',  67, '{"level":"PROVINCE","unit_type":"TINH"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '68',    'Tỉnh Lâm Đồng',        NULL,  'Tỉnh',  68, '{"level":"PROVINCE","unit_type":"TINH"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '990',   'Huyện Mẫu A',          '68',  'Huyện', 1,  '{"level":"DISTRICT","unit_type":"HUYEN"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '991',   'Thành phố Mẫu B',      '68',  'Huyện', 2,  '{"level":"DISTRICT","unit_type":"THANH_PHO"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '99001', 'Phường Mẫu Một',       '991', 'Xã',    1,  '{"level":"COMMUNE","unit_type":"PHUONG"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '99002', 'Phường Mẫu Hai',       '991', 'Xã',    2,  '{"level":"COMMUNE","unit_type":"PHUONG"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '99003', 'Xã Mẫu Ba',            '990', 'Xã',    3,  '{"level":"COMMUNE","unit_type":"XA"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '99004', 'Thị trấn Mẫu Bốn',     '990', 'Xã',    4,  '{"level":"COMMUNE","unit_type":"THI_TRAN"}', c_actor, c_actor);
  -- Ví dụ bản ghi lịch sử đã kết thúc bên trong v1 (valid_to): xã giải thể năm 2020 (MẪU).
  INSERT INTO ph07_rdm.catalog_item (id, tenant_id, catalog_id, version_id, code, name, parent_code, level_name, sort_order,
                                     status, valid_to, attrs, created_by, updated_by)
  VALUES (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v1, '99009', 'Xã Mẫu Chín (đã giải thể)', '990', 'Xã', 9,
          'DEPRECATED', DATE '2020-01-01', '{"level":"COMMUNE","unit_type":"XA"}', c_actor, c_actor);

  FOR v_bad IN SELECT * FROM ph07_rdm.f_recompute_hierarchy(c_v1) LOOP
    RAISE EXCEPTION 'Phân cấp v1 lỗi: % %', v_bad.problem, v_bad.item_code;
  END LOOP;

  UPDATE ph07_rdm.catalog_version
     SET status = 'PUBLISHED', effective_from = DATE '2004-08-01', item_count = 10,
         stats = '{"added":10,"changed":0,"deprecated":1,"removed":0,"breaking":false}',
         published_by = c_actor, published_at = now(), updated_by = c_actor
   WHERE id = c_v1;
  UPDATE ph07_rdm.catalog SET status = 'ACTIVE', current_version_id = c_v1, updated_by = c_actor WHERE id = c_catalog;
  PERFORM ph07_rdm.f_refresh_admin_unit(c_v1, c_actor);

  -- ---------------------------------------------------------------- v2 hiện hành
  -- Tạo bản nháp copy-on-write từ v1 (đúng mẫu truy vấn §8.5 của tài liệu).
  INSERT INTO ph07_rdm.catalog_version (id, tenant_id, catalog_id, version_no, status, legal_basis, change_note, origin,
                                        created_by, updated_by, last_edited_by, last_edited_at)
  VALUES (c_v2, 'COMMON', c_catalog, 2, 'DRAFT',
          'MẪU — cần xác minh: Nghị quyết 202/2025/QH15; các nghị quyết UBTVQH năm 2025 về sắp xếp ĐVHC cấp xã; Quyết định 19/2025/QĐ-TTg',
          'Chuyển sang mô hình hai cấp từ 01/7/2025 (dữ liệu mẫu)', 'MIGRATION', c_actor, c_actor, c_actor, now());
  INSERT INTO ph07_rdm.attribute_def (id, tenant_id, version_id, code, label, data_type, required, unique_in_version, max_length,
         pattern, min_value, max_value, enum_values, ref_catalog_code, default_value, sort_order, status, queryable, searchable,
         classification, description, legacy_field_id, created_by, updated_by)
  SELECT ph07_rdm.f_uuid_v7(), tenant_id, c_v2, code, label, data_type, required, unique_in_version, max_length,
         pattern, min_value, max_value, enum_values, ref_catalog_code, default_value, sort_order, status, queryable, searchable,
         classification, description, legacy_field_id, c_actor, c_actor
    FROM ph07_rdm.attribute_def WHERE version_id = c_v1;
  -- v2 không sao chép bản ghi v1 (sắp xếp thay toàn bộ); nạp danh sách mới.
  INSERT INTO ph07_rdm.catalog_item (id, tenant_id, catalog_id, version_id, code, name, parent_code, level_name, sort_order, attrs, created_by, updated_by)
  VALUES
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, '68',    'Tỉnh Lâm Đồng',   NULL, 'Tỉnh', 68,
     '{"level":"PROVINCE","unit_type":"TINH","ma_cu":"60,67,68"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, '99101', 'Phường Mẫu Mười Một', '68', 'Xã', 1,
     '{"level":"COMMUNE","unit_type":"PHUONG","ma_cu":"99001,99002"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, '99102', 'Xã Mẫu Mười Hai',  '68', 'Xã', 2,
     '{"level":"COMMUNE","unit_type":"XA","ma_cu":"99003"}', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, '99103', 'Xã Mẫu Mười Ba',   '68', 'Xã', 3,
     '{"level":"COMMUNE","unit_type":"XA","ma_cu":"99004"}', c_actor, c_actor);

  INSERT INTO ph07_rdm.item_succession (id, tenant_id, catalog_id, version_id, event_type, from_codes, to_codes,
                                        effective_date, legal_basis, note, created_by, updated_by)
  VALUES
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, 'MERGE',   ARRAY['60','67','68'], ARRAY['68'],
     DATE '2025-07-01', 'MẪU — cần xác minh: Nghị quyết 202/2025/QH15', 'Hợp nhất ba tỉnh, giữ mã 68', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, 'ABOLISH', ARRAY['990','991'], ARRAY[]::text[],
     DATE '2025-07-01', 'MẪU — cần xác minh: luật, nghị quyết về kết thúc hoạt động cấp huyện', 'Không tổ chức cấp huyện', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, 'MERGE',   ARRAY['99001','99002'], ARRAY['99101'],
     DATE '2025-07-01', 'MẪU — nghị quyết UBTVQH sắp xếp ĐVHC cấp xã tỉnh Lâm Đồng', NULL, c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, 'RECODE',  ARRAY['99003'], ARRAY['99102'],
     DATE '2025-07-01', 'MẪU — nghị quyết UBTVQH sắp xếp ĐVHC cấp xã tỉnh Lâm Đồng', 'Giữ địa giới, đổi mã và tên', c_actor, c_actor),
    (ph07_rdm.f_uuid_v7(), 'COMMON', c_catalog, c_v2, 'SPLIT',   ARRAY['99004'], ARRAY['99102','99103'],
     DATE '2025-07-01', 'MẪU — nghị quyết UBTVQH sắp xếp ĐVHC cấp xã tỉnh Lâm Đồng', 'Một phần nhập 99102, phần còn lại lập 99103', c_actor, c_actor);

  FOR v_bad IN SELECT * FROM ph07_rdm.f_recompute_hierarchy(c_v2) LOOP
    RAISE EXCEPTION 'Phân cấp v2 lỗi: % %', v_bad.problem, v_bad.item_code;
  END LOOP;

  -- Phát hành v2: chốt effective_to của v1 trước, rồi chuyển v2 sang PUBLISHED.
  UPDATE ph07_rdm.catalog_version SET effective_to = DATE '2025-07-01', updated_by = c_actor
   WHERE catalog_id = c_catalog AND status = 'PUBLISHED' AND effective_to IS NULL;
  UPDATE ph07_rdm.catalog_version
     SET status = 'PUBLISHED', effective_from = DATE '2025-07-01', item_count = 4,
         stats = '{"added":3,"changed":1,"deprecated":0,"removed":9,"breaking":true}',
         published_by = c_actor, published_at = now(), updated_by = c_actor
   WHERE id = c_v2;
  UPDATE ph07_rdm.catalog SET current_version_id = c_v2, updated_by = c_actor WHERE id = c_catalog;
  PERFORM ph07_rdm.f_refresh_admin_unit(c_v2, c_actor);
END
$seed$;

COMMIT;
--rollback empty
