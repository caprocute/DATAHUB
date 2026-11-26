--liquibase formatted sql
-- Nguồn: seed/07-S01-nhom-danh-muc.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-S01-nhom-danh-muc splitStatements:false context:seed-common runOnChange:true runInTransaction:false
-- =============================================================================
-- D03-03-PH07 · Dữ liệu nền S01 — Nhóm danh mục mặc định (COMMON)
-- Chạy bởi tenant PLATFORM (RLS chỉ cho PLATFORM ghi COMMON). Idempotent.
-- Liquibase: changeset ph07-S01-nhom-danh-muc, context seed-common.
-- =============================================================================
BEGIN;
SET LOCAL app.tenant_id = 'PLATFORM';

-- Người dùng hệ thống dùng cho created_by/updated_by của dữ liệu nền (giả lập).
-- 0192f000-0000-7000-8000-00000000a001 = "system:seed"

INSERT INTO ph07_rdm.catalog_group (id, tenant_id, code, name, parent_id, sort_order, description, created_by, updated_by)
VALUES
  ('0192f000-0000-7000-8000-000000000101', 'COMMON', 'HANH_CHINH', 'Hành chính, địa giới',        NULL, 10, 'Đơn vị hành chính, địa bàn, cơ quan nhà nước.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000102', 'COMMON', 'DAN_CU',     'Dân cư, nhân thân',           NULL, 20, 'Giới tính, dân tộc, tôn giáo, quốc tịch, giấy tờ tùy thân, quan hệ gia đình.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000103', 'COMMON', 'TO_CHUC',    'Tổ chức, doanh nghiệp',       NULL, 30, 'Loại hình tổ chức, loại hình doanh nghiệp.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000104', 'COMMON', 'KINH_TE',    'Kinh tế, ngành nghề',         NULL, 40, 'Ngành kinh tế, nghề nghiệp, sản phẩm.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000105', 'COMMON', 'DICH_VU_CONG','Thủ tục hành chính, dịch vụ công', NULL, 50, 'Lĩnh vực, thủ tục, kết quả giải quyết.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000106', 'COMMON', 'Y_TE_GIAO_DUC','Y tế, giáo dục',           NULL, 60, 'Cơ sở khám chữa bệnh, trường học, trình độ.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000107', 'COMMON', 'TAI_NGUYEN', 'Đất đai, tài nguyên, môi trường', NULL, 70, 'Loại đất, mục đích sử dụng đất.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000108', 'COMMON', 'TAI_CHINH',  'Tài chính, thanh toán',       NULL, 80, 'Ngân hàng, loại phí, lệ phí, tiền tệ.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001'),
  ('0192f000-0000-7000-8000-000000000199', 'COMMON', 'KHAC',       'Khác',                        NULL, 999, 'Danh mục chưa phân nhóm.', '0192f000-0000-7000-8000-00000000a001', '0192f000-0000-7000-8000-00000000a001')
ON CONFLICT (tenant_id, code) DO NOTHING;

COMMIT;
--rollback empty
