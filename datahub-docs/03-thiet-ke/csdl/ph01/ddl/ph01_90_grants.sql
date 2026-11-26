-- =============================================================================
-- D03-03-PH01 · Tệp 90: quyền (chạy lại mỗi lần, runAlways).
-- Chạy sau ph01_80_seed.sql.
-- ph01_app: DML cần thiết, không BYPASSRLS, không là chủ bảng; dh_connect_app, dh_connect_migrator
-- do hạ tầng tạo và gán thành viên (D03-09). ph01_readonly: báo cáo, kiểm toán, không đọc dữ liệu cá nhân,
-- mã bàn giao, đường dẫn bí mật (mặc định từ chối, chỉ mở cột được liệt kê).
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0900-grants.sql
-- @changeset ph01-0990-grants runAlways:true splitStatements:false
DO $g$
DECLARE
  r record;
BEGIN
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph01_onboarding TO ph01_app;

  -- Bảng giữ vĩnh viễn hoặc là bằng chứng: không cho xóa (xóa theo thời hạn lưu giữ do DBA, mục 7 của tài liệu)
  REVOKE DELETE ON ph01_onboarding.review_step, ph01_onboarding.scope_ceiling, ph01_onboarding.app_credential,
                   ph01_onboarding.change_request, ph01_onboarding.emergency_action, ph01_onboarding.state_history,
                   ph01_onboarding.access_review_cycle, ph01_onboarding.access_review_item, ph01_onboarding.review_confirmation
    FROM ph01_app;
  -- Chỉ thêm
  REVOKE UPDATE, DELETE ON ph01_onboarding.state_history FROM ph01_app;
  REVOKE UPDATE ON ph01_onboarding.sandbox_test FROM ph01_app;          -- chỉ thêm; dọn theo lô sau 1 năm
  REVOKE UPDATE ON ph01_onboarding.outbox FROM ph01_app;                -- chỉ thêm; xóa khi dọn
  GRANT UPDATE (relayed_at) ON ph01_onboarding.outbox TO ph01_app;      -- đường dự phòng OutboxRelay
  -- Bảng kỹ thuật không có tenant: chỉ ShedLock cần ghi
  -- (shedlock không bật RLS nên chỉ cấp cho ph01_app, không cho ph01_readonly)

  -- ph01_readonly: mặc định chỉ đọc cột không nhạy cảm
  GRANT SELECT ON ALL TABLES IN SCHEMA ph01_onboarding TO ph01_readonly;
  REVOKE SELECT ON ph01_onboarding.outbox, ph01_onboarding.inbox, ph01_onboarding.notify_outbox,
                   ph01_onboarding.idempotency_record, ph01_onboarding.shedlock FROM ph01_readonly;
  FOR r IN SELECT * FROM (VALUES
      ('contact',            ARRAY['full_name', 'job_title', 'email', 'phone', 'user_account_id', 'search_text']),
      ('handover',           ARRAY['link_hash', 'wrap_accessor', 'wrap_token_sealed', 'opened_ip']),
      ('app_credential',     ARRAY['secret_ref', 'cert_fingerprint', 'jwks_ref']),
      ('attachment',         ARRAY['object_key', 'file_name']),
      ('review_confirmation', ARRAY['link_hash']),
      ('legacy_import_job',  ARRAY['preview', 'warnings', 'file_object_key', 'file_name']),
      ('member_system',      ARRAY['ip_allowlist'])
    ) AS x(tbl, excluded)
  LOOP
    EXECUTE format('REVOKE SELECT ON ph01_onboarding.%I FROM ph01_readonly', r.tbl);
    EXECUTE format('GRANT SELECT (%s) ON ph01_onboarding.%I TO ph01_readonly',
      (SELECT string_agg(quote_ident(c.column_name), ', ' ORDER BY c.ordinal_position)
         FROM information_schema.columns c
        WHERE c.table_schema = 'ph01_onboarding' AND c.table_name = r.tbl AND c.column_name <> ALL (r.excluded)),
      r.tbl);
  END LOOP;
END
$g$;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
