-- =============================================================================
-- D03-03-PH01 · Tệp 80: dữ liệu khởi tạo (mẫu văn bản mặc định của nền tảng, tenant COMMON).
-- Chạy sau ph01_50_infra.sql. Lũy đẳng (ON CONFLICT), chạy dưới app.tenant_id = 'PLATFORM'.
-- Siêu dữ liệu mẫu; tệp mẫu thật đóng gói trong bản phát hành và nạp lên kho đối tượng khi khởi tạo nền tảng
-- (file_sha256 dưới đây là băm giữ chỗ, được cập nhật bằng tác vụ nạp mẫu).
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0800-seed.sql
-- @changeset ph01-0800-seed-templates
INSERT INTO ph01_onboarding.template (id, tenant_id, template_code, title, content_version, status, file_name, content_type, file_ref, file_sha256, guide_md, published_at, created_by, updated_by)
SELECT md5('dh-template:' || t.code || ':1.0')::uuid, 'COMMON', t.code, t.title, '1.0', 'PUBLISHED',
       t.code || '-1.0.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
       'platform/onboarding/templates/' || t.code || '/1.0/' || t.code || '.docx',
       encode(sha256(convert_to('seed:' || t.code || ':1.0', 'UTF8')), 'hex'), t.guide, now(), 'system:seed', 'system:seed'
FROM (VALUES
  ('mau-van-ban-de-nghi-ket-noi', 'Mẫu văn bản đề nghị kết nối, chia sẻ dữ liệu',
   'Điền tên đơn vị, hệ thống, mục đích khai thác; văn bản do lãnh đạo đơn vị ký và tải lên dạng PDF ở bước Tài liệu.'),
  ('mau-ban-khai-can-cu-phap-ly', 'Mẫu bản khai căn cứ pháp lý khai thác dữ liệu',
   'Mỗi loại dữ liệu đề nghị khai thác cần nêu số, ngày, cơ quan ban hành văn bản và đính kèm bản văn bản.'),
  ('huong-dan-ket-noi-chuan', 'Hướng dẫn kết nối chuẩn cho HTTT thành viên',
   'Các bước kiểm thử ở môi trường thử SANDBOX, cách nhận thông tin xác thực qua liên kết một lần và cách xoay vòng.')
) AS t(code, title, guide)
ON CONFLICT (tenant_id, template_code, content_version) DO UPDATE SET title = EXCLUDED.title, guide_md = EXCLUDED.guide_md, updated_by = 'system:seed';
-- @rollback DELETE FROM ph01_onboarding.template WHERE tenant_id = 'COMMON' AND created_by = 'system:seed';
