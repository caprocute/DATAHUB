-- =============================================================================
-- D03-03-PH12 · DDL schema ph12_iam
-- Tệp 06: dữ liệu khởi tạo (COMMON) và quyền của vai trò (chạy lại mỗi lần)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- =============================================================================

\set ON_ERROR_STOP on
RESET ROLE;
SET ROLE ph12_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 12-0800-seed.sql
-- @changeset ph12-8000-seed-sod-pair runOnChange:true
-- Cặp vai trò xung đột của D02-08 §4: sáu cặp tường minh và bốn cặp khai triển của dòng
-- "AUDITOR với mọi vai trò có quyền ghi của PH-19" (PAYMENT_ADMIN, APPROVER, ACCOUNTANT, OPERATOR).
-- role_a < role_b theo thứ tự chữ cái. Id tất định theo cặp nên chạy lại không nhân đôi.
INSERT INTO ph12_iam.sod_pair (id, tenant_id, role_a, role_b, allow_exception, reason, source_ref, created_by, updated_by)
SELECT md5('ph12:sod:' || a || ':' || b)::uuid, 'COMMON', a, b, ok, why, src, 'system:seed', 'system:seed'
FROM (VALUES
  ('INTEGRATION_APPROVER', 'INTEGRATION_ENGINEER', true,  'Người thiết kế không tự duyệt phát hành', 'D02-08 §4 dòng 1'),
  ('CATALOG_APPROVER',     'SERVICE_OWNER',        true,  'Chủ dịch vụ không tự duyệt công bố', 'D02-08 §4 dòng 2'),
  ('DATA_APPROVER',        'DATA_STEWARD',         true,  'Người soạn danh mục không tự duyệt phát hành', 'D02-08 §4 dòng 3'),
  ('PAYMENT_ACCOUNTANT',   'PAYMENT_APPROVER',     true,  'Người lập hoàn tiền, đề xuất xử lý chênh lệch không tự duyệt', 'D02-08 §4 dòng 4'),
  ('AUDITOR',              'TENANT_ADMIN',         true,  'Người quản trị không tự kiểm toán mình', 'D02-08 §4 dòng 5'),
  ('PAYMENT_ADMIN',        'PAYMENT_APPROVER',     true,  'Người cấu hình kênh không duyệt kích hoạt kênh', 'D02-08 §4 dòng 6'),
  ('AUDITOR',              'PAYMENT_ADMIN',        false, 'Độc lập kiểm toán với quyền ghi của PH-19 (không có ngoại lệ, BR-12-030)', 'D02-08 §4 dòng 7'),
  ('AUDITOR',              'PAYMENT_APPROVER',     false, 'Độc lập kiểm toán với quyền ghi của PH-19 (không có ngoại lệ, BR-12-030)', 'D02-08 §4 dòng 7'),
  ('AUDITOR',              'PAYMENT_ACCOUNTANT',   false, 'Độc lập kiểm toán với quyền ghi của PH-19 (không có ngoại lệ, BR-12-030)', 'D02-08 §4 dòng 7'),
  ('AUDITOR',              'PAYMENT_OPERATOR',     false, 'Độc lập kiểm toán với quyền ghi của PH-19 (không có ngoại lệ, BR-12-030)', 'D02-08 §4 dòng 7')
) AS v(a, b, ok, why, src)
ON CONFLICT (role_a, role_b) DO UPDATE SET allow_exception = EXCLUDED.allow_exception, reason = EXCLUDED.reason, source_ref = EXCLUDED.source_ref;
-- @rollback DELETE FROM ph12_iam.sod_pair WHERE created_by = 'system:seed';

-- @changeset ph12-8010-seed-legacy-role-map runOnChange:true
-- Ánh xạ mặc định vai trò hệ cũ sang vai trò chuẩn (FRS §11.4); role_code rỗng là chưa có vai trò (Q12-05).
INSERT INTO ph12_iam.legacy_role_map (id, tenant_id, legacy_role, role_code, source, note, created_by, updated_by)
SELECT md5('ph12:legacy-role:' || legacy)::uuid, 'COMMON', legacy, std, src, note, 'system:seed', 'system:seed'
FROM (VALUES
  ('PLATFORM_ADMIN',       'PLATFORM_ADMIN',       'SRS_REPO',      'Chỉ ở tenant PLATFORM; cũng có ở realm lgsp của compose'),
  ('IAM_ADMIN',            'TENANT_ADMIN',         'SRS_REPO',      'Quản trị người dùng, vai trò, client của tỉnh'),
  ('SECURITY_OFFICER',     'SECURITY_OFFICER',     'SRS_REPO',      NULL),
  ('INTEGRATION_DEV',      'INTEGRATION_ENGINEER', 'SRS_REPO',      NULL),
  ('INTEGRATION_REVIEWER', 'INTEGRATION_APPROVER', 'SRS_REPO',      'Cặp loại trừ với kỹ sư tích hợp; cũng có ở realm lgsp của compose'),
  ('INTEGRATION_APPROVER', 'INTEGRATION_APPROVER', 'SRS_REPO',      'Bí danh cũ của INTEGRATION_REVIEWER'),
  ('DATA_STEWARD',         'DATA_STEWARD',         'SRS_REPO',      NULL),
  ('OPERATOR',             'TENANT_OPERATOR',      'SRS_REPO',      'Cũng có ở realm lgsp của compose'),
  ('VIEWER',               'VIEWER',               'SRS_REPO',      NULL),
  ('DATA_OWNER',           'DATA_OWNER',           'SRS_REPO',      NULL),
  ('DQ_ANALYST',           'DATA_STEWARD',         'SRS_REPO',      'Tạm thời tới khi PH-08 (Đợt 3) có vai trò riêng'),
  ('LEGAL_REVIEWER',       NULL,                   'SRS_REPO',      'Chưa có vai trò chuẩn: hồ sơ kết nạp do TA duyệt ở bản này (Q12-05)'),
  ('ARCHITECT',            NULL,                   'SRS_REPO',      'Chưa có vai trò chuẩn (Q12-05)'),
  ('AI_GOVERNOR',          NULL,                   'SRS_REPO',      'Thuộc PH-17, Đợt 3 (Q12-05)'),
  ('LEADERSHIP',           'VIEWER',               'SRS_REPO',      'Tạm ánh xạ người xem nếu chỉ xem; xác nhận ở Q12-05'),
  ('INTEGRATION_DEVELOPER','INTEGRATION_ENGINEER', 'COMPOSE_REALM', 'Tên vai trò ở realm lgsp của compose, tương đương INTEGRATION_DEV'),
  ('INTEGRATION_ADMIN',    NULL,                   'COMPOSE_REALM', 'Vai trò của realm lgsp (compose) không có trong SRS-19 và FRS §11.4; chờ xác nhận (Q12-05)')
) AS v(legacy, std, src, note)
ON CONFLICT (legacy_role) DO UPDATE SET role_code = EXCLUDED.role_code, source = EXCLUDED.source, note = EXCLUDED.note;
-- @rollback DELETE FROM ph12_iam.legacy_role_map WHERE created_by = 'system:seed';

-- @file 12-0900-grants.sql
-- @changeset ph12-9000-grants runAlways:true splitStatements:false
DO $g$
DECLARE
  t text;
  -- Bảng app được xóa dòng: dọn dữ liệu hết hạn, thay thế theo nguồn, hoàn tác thao tác chưa có hiệu lực.
  deletable text[] := ARRAY['user_import', 'user_import_row', 'org_group', 'org_group_member', 'custom_role_permission',
                            'client_scope', 'revocation_entry', 'policy_dryrun_report', 'bundle_ack',
                            'account_report_daily', 'mfa_coverage_daily', 'sync_task', 'idempotency_key', 'outbox', 'shedlock'];
  -- Bảng chỉ thêm, bất biến: app không được UPDATE.
  insert_only text[] := ARRAY['policy_version_contributor', 'policy_test_run', 'alert_ack'];
  -- Bảng app chỉ đọc: dữ liệu COMMON do Liquibase, ph12_owner ghi.
  read_only text[] := ARRAY['sod_pair', 'legacy_role_map'];
  -- Bảng ph12_readonly (báo cáo, kiểm toán) không đọc được: dữ liệu cá nhân, tham chiếu bí mật, nội dung nhập.
  no_readonly text[] := ARRAY['user_import_row', 'vneid_link', 'client_credential', 'federation', 'saml_client',
                              'idempotency_key', 'outbox', 'sync_task'];
BEGIN
  REVOKE ALL ON ALL TABLES IN SCHEMA ph12_iam FROM PUBLIC, ph12_app, ph12_readonly;
  REVOKE ALL ON ALL FUNCTIONS IN SCHEMA ph12_iam FROM PUBLIC;
  REVOKE ALL ON ALL PROCEDURES IN SCHEMA ph12_iam FROM PUBLIC;
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ph12_iam TO ph12_app, ph12_readonly;
  FOR t IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'ph12_iam' AND c.relkind = 'r' LOOP
    IF t = ANY (read_only) THEN
      EXECUTE format('GRANT SELECT ON ph12_iam.%I TO ph12_app', t);
    ELSIF t = ANY (insert_only) THEN
      EXECUTE format('GRANT SELECT, INSERT ON ph12_iam.%I TO ph12_app', t);
    ELSE
      EXECUTE format('GRANT SELECT, INSERT, UPDATE ON ph12_iam.%I TO ph12_app', t);
    END IF;
    IF t = ANY (deletable) THEN
      EXECUTE format('GRANT DELETE ON ph12_iam.%I TO ph12_app', t);
    END IF;
    IF NOT (t = ANY (no_readonly)) AND t <> 'user_account' THEN
      EXECUTE format('GRANT SELECT ON ph12_iam.%I TO ph12_readonly', t);
    END IF;
  END LOOP;
  -- user_account: ph12_readonly không đọc email và họ tên (quyền theo cột).
  GRANT SELECT (id, tenant_id, keycloak_id, username, org_code, title, manager_user_id, auth_source, federation_id, state,
                disabled_reason, mfa_level, sync_state, activated_at, last_login_at, disabled_at, origin_tenant_id,
                origin_user_id, created_at, created_by, updated_at, updated_by, version)
    ON ph12_iam.user_account TO ph12_readonly;
  -- Danh sách chặn dùng chung: cổng chỉ cần tăng số thứ tự.
  REVOKE INSERT ON ph12_iam.revocation_feed_version FROM ph12_app;
END
$g$;
-- @rollback -- Không cần.
