-- =============================================================================
-- D03-03-PH01 · Kiểm thử di trú schema ph01 cũ (apps/control, W1) sang ph01_onboarding.
-- Chạy sau ph01_isolation_test.sql, bằng siêu người dùng (mô phỏng vai trò sở hữu cả hai schema):
--   psql -v ON_ERROR_STOP=1 -v ddl_dir=../ddl -f ph01_migrate_test.sql
-- Dựng lại schema ph01 như các changeset 002, 004, 005 của apps/control, nạp dữ liệu giả phủ mọi trạng thái cũ.
-- =============================================================================
\set ON_ERROR_STOP on
\set QUIET on
\t on
CREATE SCHEMA ph01;
CREATE TABLE ph01.application (
  id uuid PRIMARY KEY, system_code varchar(64) NOT NULL UNIQUE, system_name varchar(255) NOT NULL, owner_org varchar(255) NOT NULL,
  status varchar(32) NOT NULL, client_id varchar(128), client_secret_sealed varchar(512),
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL,
  submitted_by varchar(128), approved_by varchar(128), legal_basis text, tech_profile text,
  contact_name varchar(255), contact_email varchar(255), contact_phone varchar(64),
  legal_review_status varchar(32), legal_review_by varchar(128), legal_review_note text, legal_review_at timestamptz,
  tech_review_status varchar(32), tech_review_by varchar(128), tech_review_note text, tech_review_at timestamptz,
  status_reason text, last_access_review_at timestamptz, last_access_review_by varchar(128), next_access_review_at timestamptz);
CREATE TABLE ph01.application_audit (id uuid PRIMARY KEY, application_id uuid NOT NULL, action varchar(32) NOT NULL, from_status varchar(32), to_status varchar(32),
  actor varchar(128) NOT NULL, note text, created_at timestamptz NOT NULL);
CREATE TABLE ph01.application_attachment (id uuid PRIMARY KEY, application_id uuid NOT NULL, file_name varchar(255) NOT NULL, content_type varchar(128) NOT NULL,
  size_bytes bigint NOT NULL, object_key varchar(512) NOT NULL, sha256 varchar(64) NOT NULL, uploaded_by varchar(128) NOT NULL, created_at timestamptz NOT NULL);
CREATE TABLE ph01.outbox_event (id uuid PRIMARY KEY, topic varchar(128) NOT NULL, payload_json text NOT NULL, created_at timestamptz NOT NULL, published_at timestamptz);

INSERT INTO ph01.application (id, system_code, system_name, owner_org, status, client_id, client_secret_sealed, created_at, updated_at, submitted_by, approved_by,
                              legal_basis, contact_name, contact_email, contact_phone, legal_review_status, legal_review_by, legal_review_note, tech_review_status, tech_review_by, status_reason)
SELECT md5('a' || n)::uuid, c, 'HTTT ' || c, 'Sở Nội vụ', s, 'client-' || n, 'DH-CANARY-sealed-' || n, now() - interval '100 days', now() - interval '10 days', 'an', ab,
       'NĐ 47/2020', 'Nguyễn An', CASE WHEN n = 3 THEN 'khong-hop-le' ELSE 'an' || n || '@noivu.gov.vn' END, CASE WHEN n = 1 THEN '+84911111111' ELSE '0911111111' END,
       'PASS', 'cuong', 'Đạt', 'PASS', 'binh', sr
FROM (VALUES (1, 'qlvb', 'SUBMITTED', NULL, NULL), (2, 'hoso-cb', 'REVIEWED', NULL, NULL), (3, 'tthc', 'APPROVED', 'binh', NULL),
             (4, 'cstt', 'ACTIVE', 'binh', NULL), (5, 'kt-nsnn', 'SUSPENDED', 'binh', 'Nghi ngờ'), (6, 'bhxh', 'REJECTED', NULL, NULL),
             (7, 'dat-dai', 'REVOKED', 'binh', 'Ngừng dùng'), (8, 'cu-vi-pham', 'ACTIVE', 'an', NULL), (9, '1-so tt', 'DRAFT', NULL, NULL)) AS x(n, c, s, ab, sr);
UPDATE ph01.application SET submitted_by = 'an' WHERE true;
INSERT INTO ph01.application_audit (id, application_id, action, from_status, to_status, actor, note, created_at)
VALUES (md5('u1')::uuid, md5('a4')::uuid, 'APPROVE', 'REVIEWED', 'APPROVED', 'binh', 'duyệt', now() - interval '30 days'),
       (md5('u2')::uuid, md5('a4')::uuid, 'ACTIVATE', 'APPROVED', 'ACTIVE', 'cuong', NULL, now() - interval '20 days'),
       (md5('u3')::uuid, md5('a1')::uuid, 'SUBMIT', NULL, 'SUBMITTED', 'an', NULL, now() - interval '90 days'),
       (md5('u4')::uuid, md5('a1')::uuid, 'REVIEW', 'SUBMITTED', 'SUBMITTED', 'binh', 'không đổi trạng thái', now() - interval '80 days');
INSERT INTO ph01.application_attachment (id, application_id, file_name, content_type, size_bytes, object_key, sha256, uploaded_by, created_at)
VALUES (md5('f1')::uuid, md5('a1')::uuid, 'cv.pdf', 'application/pdf', 1000, 'qlvb/f1', repeat('A', 64), 'an', now()),
       (md5('f2')::uuid, md5('a1')::uuid, 'rong.pdf', 'application/pdf', 0, 'qlvb/f2', repeat('b', 64), 'an', now());
INSERT INTO ph01.outbox_event VALUES (md5('o1')::uuid, 'ph01.application', '{}', now(), NULL), (md5('o2')::uuid, 'ph01.application', '{}', now(), now());

SET app.migrate_tenant = 'T01';
\i :ddl_dir/ph01_99_migrate_legacy.sql

CREATE FUNCTION pg_temp.assert(label text, cond boolean) RETURNS void LANGUAGE plpgsql AS $f$
BEGIN
  IF cond IS NOT TRUE THEN RAISE EXCEPTION 'FAIL %', label; END IF;
  RAISE NOTICE 'PASS %', label;
END $f$;
SET ROLE dh_connect_app;
SET app.tenant_id = 'T01';
SELECT pg_temp.assert('M1 di trú 8 HTTT (bỏ bản nháp không thuộc tập trạng thái cũ)', (SELECT count(*) FROM ph01_onboarding.member_system WHERE legacy_ref LIKE 'w1:%') = 8);
SELECT pg_temp.assert('M2 SUBMITTED, REVIEWED thành DRAFT có return_reason', (SELECT count(*) FROM ph01_onboarding.member_system WHERE status = 'DRAFT' AND revision_no = 1 AND return_reason IS NOT NULL) = 2);
SELECT pg_temp.assert('M3 APPROVED giữ APPROVED, chờ chạy lại saga (PROVISION_FAILED)', (SELECT count(*) FROM ph01_onboarding.member_system WHERE status = 'APPROVED' AND provision_stage = 'PROVISION_FAILED') = 1);
SELECT pg_temp.assert('M4 ACTIVE giữ ACTIVE, 2 hồ sơ', (SELECT count(*) FROM ph01_onboarding.member_system WHERE status = 'ACTIVE') = 2);
SELECT pg_temp.assert('M5 REVOKED thành TERMINATED có terminated_at, lý do đủ dài', (SELECT count(*) FROM ph01_onboarding.member_system WHERE status = 'TERMINATED' AND terminated_at IS NOT NULL AND char_length(status_reason) >= 10) = 1);
SELECT pg_temp.assert('M6 SUSPENDED, REJECTED có lý do đủ dài', (SELECT count(*) FROM ph01_onboarding.member_system WHERE status IN ('SUSPENDED', 'REJECTED') AND char_length(status_reason) >= 10) = 2);
SELECT pg_temp.assert('M7 người kích hoạt lấy từ nhật ký ACTIVATE', (SELECT activated_by FROM ph01_onboarding.member_system WHERE legacy_ref = 'w1:ph01.application/' || md5('a4')::uuid) = 'cuong');
SELECT pg_temp.assert('M8 hồ sơ cũ vi phạm bốn mắt được đánh dấu legacy:, không dừng di trú', (SELECT approved_by FROM ph01_onboarding.member_system WHERE legacy_ref = 'w1:ph01.application/' || md5('a8')::uuid) = 'legacy:an');
SELECT pg_temp.assert('M9 mã HTTT sai mẫu được sinh lại theo id', (SELECT count(*) FROM ph01_onboarding.member_system WHERE code ~ '^HT-[0-9A-F]{8}$') = 0
                                                              AND (SELECT count(*) FROM ph01_onboarding.member_system WHERE code IN ('QLVB', 'HOSO-CB', 'TTHC', 'CSTT', 'KT-NSNN', 'BHXH', 'DAT-DAI', 'CU-VI-PHAM')) = 8);
SELECT pg_temp.assert('M10 mọi HTTT di trú có cấp độ ATTT L1 chờ khai lại, chủ quản CHUA-GAN', (SELECT count(*) FROM ph01_onboarding.member_system WHERE legacy_ref LIKE 'w1:%' AND security_level = 'L1' AND owner_org_id = 'CHUA-GAN') = 8);
SELECT pg_temp.assert('M11 đầu mối chỉ lấy khi thư điện tử hợp lệ; điện thoại sai chuẩn bỏ', (SELECT count(*) FROM ph01_onboarding.contact WHERE created_by = 'system:migrate') = 7 AND (SELECT count(*) FROM ph01_onboarding.contact WHERE created_by = 'system:migrate' AND phone IS NOT NULL) = 1);
SELECT pg_temp.assert('M12 tệp hợp lệ chuyển, tệp rỗng bị bỏ, chờ quét lại', (SELECT count(*) FROM ph01_onboarding.attachment WHERE created_by = 'system:migrate' AND scan_status = 'PENDING') = 1);
SELECT pg_temp.assert('M13 lịch sử giữ tên trạng thái cũ làm bằng chứng, bỏ dòng không đổi trạng thái', (SELECT count(*) FROM ph01_onboarding.state_history WHERE reason LIKE '%di trú từ ph01 cũ, hành động%') = 3);
SELECT pg_temp.assert('M14 mỗi HTTT có một dòng tóm tắt thẩm định và căn cứ pháp lý cũ', (SELECT count(*) FROM ph01_onboarding.state_history WHERE reason LIKE 'Di trú từ ph01.application%') = 8);
SET app.tenant_id = 'T68';
SELECT pg_temp.assert('M15 T68 không thấy dữ liệu di trú của T01', (SELECT count(*) FROM ph01_onboarding.member_system WHERE legacy_ref LIKE 'w1:%') = 0);
RESET ROLE;
SELECT pg_temp.assert('M16 cột bí mật cũ đã bị xóa, không cột nào giống bí mật còn lại', NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'ph01' AND column_name ~* '(secret|passw|private_?key)'));
SELECT pg_temp.assert('M17 không còn giá trị bí mật mẫu ở bất kỳ bảng nào của hai schema', (
  SELECT count(*) FROM ph01.application_legacy_w1 t WHERE t::text LIKE '%DH-CANARY%') = 0
  AND (SELECT count(*) FROM ph01_onboarding.state_history h WHERE h.reason LIKE '%DH-CANARY%') = 0);
SELECT pg_temp.assert('M18 bảng cũ đổi tên *_legacy_w1 để giữ bằng chứng', to_regclass('ph01.application') IS NULL AND to_regclass('ph01.application_legacy_w1') IS NOT NULL
                                                                     AND to_regclass('ph01.application_audit_legacy_w1') IS NOT NULL AND to_regclass('ph01.outbox_event_legacy_w1') IS NOT NULL);
\i :ddl_dir/ph01_99_migrate_legacy.sql
SELECT pg_temp.assert('M19 chạy lại không nhân đôi (lũy đẳng)', (SELECT count(*) FROM ph01_onboarding.member_system WHERE legacy_ref LIKE 'w1:%') = 8);
\echo 'Hoàn tất: mọi khối PASS'
