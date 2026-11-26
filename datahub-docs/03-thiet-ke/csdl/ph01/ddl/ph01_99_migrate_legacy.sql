-- =============================================================================
-- D03-03-PH01 · Tệp 99: di trú schema ph01 cũ của apps/control (W1) sang ph01_onboarding.
-- Chạy sau khi đã chạy ph01_00 … ph01_90, bằng vai trò sở hữu cả bảng cũ và bảng mới
-- (dh_connect_migrator sau khi nhận quyền sở hữu bảng ph01.*); context migrate-w1.
-- Tham số: SET app.migrate_tenant = 'T01' (mặc định T01). Lũy đẳng: chạy lại không nhân đôi.
--
-- Quy tắc (GAP-01-02, GAP-01-03 của SDD §2.4):
--  * SUBMITTED, REVIEWED cũ thành DRAFT (đã nộp 1 lần, có return_reason) vì hồ sơ cũ không có hồ sơ
--    kỹ thuật, nhu cầu khai thác, đầu mối đủ để qua bộ kiểm nộp mới; APPROVED giữ APPROVED nhưng
--    provision_stage = PROVISION_FAILED để TA chạy lại saga cấp định danh; ACTIVE, SUSPENDED giữ nguyên;
--    REJECTED giữ; REVOKED thành TERMINATED.
--  * Không mang bí mật: cột client_secret_sealed bị đặt NULL rồi xóa; client_id cũ không chuyển (định danh
--    cấp lại qua saga, D02-07 §5). Sau di trú quét schema ph01, còn cột tên giống bí mật thì dừng.
--  * Bảng cũ đổi tên *_legacy_w1 để giữ bằng chứng (căn cứ pháp lý văn bản, ghi chú thẩm định).
-- =============================================================================
\set ON_ERROR_STOP on

-- @file 01-9000-migrate-w1.sql
-- @changeset ph01-9000-migrate-w1 context:migrate-w1 splitStatements:false
DO $mig$
DECLARE
  v_tenant text := coalesce(nullif(current_setting('app.migrate_tenant', true), ''), 'T01');
  v_total integer; v_member integer; v_contact integer; v_att integer; v_att_skipped integer; v_hist integer;
  v_secret integer; v_unpub integer; v_active_nocred integer; v_conflict integer; v_bad text;
BEGIN
  IF to_regclass('ph01.application') IS NULL THEN
    RAISE NOTICE 'Không có bảng ph01.application của W1, bỏ qua di trú';
    RETURN;
  END IF;
  PERFORM set_config('app.tenant_id', v_tenant, true);
  SELECT count(*) INTO v_total FROM ph01.application;

  -- 1. HTTT thành viên
  WITH src AS (
    SELECT a.*,
           (SELECT max(u.created_at) FROM ph01.application_audit u WHERE u.application_id = a.id AND u.action = 'ACTIVATE') AS act_at,
           (SELECT u.actor FROM ph01.application_audit u WHERE u.application_id = a.id AND u.action = 'ACTIVATE' ORDER BY u.created_at DESC LIMIT 1) AS act_by,
           CASE a.status WHEN 'SUBMITTED' THEN 'DRAFT' WHEN 'REVIEWED' THEN 'DRAFT' WHEN 'REVOKED' THEN 'TERMINATED' ELSE a.status END AS new_status
      FROM ph01.application a
     WHERE a.status IN ('SUBMITTED', 'REVIEWED', 'APPROVED', 'ACTIVE', 'SUSPENDED', 'REJECTED', 'REVOKED')
  )
  INSERT INTO ph01_onboarding.member_system (
    id, tenant_id, code, name, description, owner_org_id, security_level, system_type, roles, status, provision_stage,
    revision_no, return_reason, status_reason, suspend_reason_code, legacy_ref,
    submitted_by, submitted_at, approved_by, approved_at, sandbox_passed_at, activated_by, activated_at, terminated_at,
    last_access_review_at, created_at, created_by, updated_at, updated_by)
  SELECT s.id, v_tenant,
         CASE WHEN upper(regexp_replace(s.system_code, '[^A-Za-z0-9-]', '-', 'g')) ~ '^[A-Z][A-Z0-9-]{2,63}$'
              THEN upper(regexp_replace(s.system_code, '[^A-Za-z0-9-]', '-', 'g'))
              ELSE 'HT-' || upper(substr(md5(s.id::text), 1, 8)) END,
         CASE WHEN char_length(s.system_name) >= 3 THEN left(s.system_name, 255) ELSE s.system_name || ' (HTTT)' END,
         left('Chủ quản (hệ cũ): ' || coalesce(s.owner_org, 'không rõ'), 2000),
         'CHUA-GAN', 'L1', 'PROVINCIAL', ARRAY['CONSUMER']::varchar[], s.new_status,
         CASE WHEN s.new_status = 'APPROVED' THEN 'PROVISION_FAILED' END,
         1,
         CASE WHEN s.new_status = 'DRAFT' THEN 'Di trú từ schema ph01 cũ: cần khai lại hồ sơ kỹ thuật, nhu cầu khai thác, đầu mối và nộp lại' END,
         CASE WHEN s.new_status IN ('SUSPENDED', 'TERMINATED', 'REJECTED')
              THEN left(coalesce(s.status_reason, '') || ' [di trú từ ph01 cũ]', 1000) ELSE s.status_reason END,
         CASE WHEN s.new_status = 'SUSPENDED' THEN 'OTHER' END,
         'w1:ph01.application/' || s.id,
         coalesce(s.submitted_by, 'legacy:unknown'), s.created_at,
         CASE WHEN s.new_status IN ('APPROVED', 'ACTIVE', 'SUSPENDED')
              THEN CASE WHEN s.approved_by IS NOT DISTINCT FROM s.submitted_by THEN 'legacy:' || coalesce(s.approved_by, 'unknown') ELSE coalesce(s.approved_by, 'legacy:unknown') END END,
         CASE WHEN s.new_status IN ('APPROVED', 'ACTIVE', 'SUSPENDED') THEN s.updated_at END,
         CASE WHEN s.new_status IN ('ACTIVE', 'SUSPENDED') THEN coalesce(s.act_at, s.updated_at) END,
         CASE WHEN s.new_status IN ('ACTIVE', 'SUSPENDED')
              THEN CASE WHEN coalesce(s.act_by, s.approved_by) IS NOT DISTINCT FROM s.submitted_by THEN 'legacy:' || coalesce(s.act_by, s.approved_by, 'unknown') ELSE coalesce(s.act_by, s.approved_by, 'legacy:unknown') END END,
         CASE WHEN s.new_status IN ('ACTIVE', 'SUSPENDED') THEN coalesce(s.act_at, s.updated_at) END,
         CASE WHEN s.new_status = 'TERMINATED' THEN s.updated_at END,
         s.last_access_review_at, s.created_at, 'system:migrate', s.updated_at, 'system:migrate'
    FROM src s
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_member = ROW_COUNT;

  -- 2. Đầu mối: một đầu mối kỹ thuật từ contact_* nếu thư điện tử hợp lệ
  INSERT INTO ph01_onboarding.contact (id, tenant_id, member_system_id, contact_type, full_name, job_title, email, phone, is_public, created_by, updated_by, created_at, updated_at)
  SELECT md5('w1contact:' || a.id)::uuid, v_tenant, a.id, 'TECHNICAL', left(a.contact_name, 255), 'Chưa khai (di trú)', left(a.contact_email, 255),
         CASE WHEN a.contact_phone ~ '^\+[1-9][0-9]{7,14}$' THEN a.contact_phone END, true, 'system:migrate', 'system:migrate', a.created_at, a.updated_at
    FROM ph01.application a
    JOIN ph01_onboarding.member_system m ON m.id = a.id AND m.tenant_id = v_tenant
   WHERE nullif(a.contact_name, '') IS NOT NULL AND a.contact_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_contact = ROW_COUNT;

  -- 3. Tài liệu đính kèm (kind OTHER, quét lại vì hệ cũ không quét; tệp ở kho cũ phải sao sang bucket mới)
  INSERT INTO ph01_onboarding.attachment (id, tenant_id, member_system_id, kind, file_name, content_type, size_bytes, object_key, sha256, scan_status, uploaded_by, created_by, updated_by, created_at, updated_at)
  SELECT t.id, v_tenant, t.application_id, 'OTHER', left(t.file_name, 255), left(t.content_type, 128), t.size_bytes, t.object_key, lower(t.sha256), 'PENDING',
         left(t.uploaded_by, 64), 'system:migrate', 'system:migrate', t.created_at, t.created_at
    FROM ph01.application_attachment t
    JOIN ph01_onboarding.member_system m ON m.id = t.application_id AND m.tenant_id = v_tenant
   WHERE t.size_bytes BETWEEN 1 AND 52428800 AND lower(t.sha256) ~ '^[0-9a-f]{64}$' AND t.object_key !~ '^staging/' AND t.object_key !~ '\.\.'
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_att = ROW_COUNT;
  SELECT count(*) - v_att INTO v_att_skipped FROM ph01.application_attachment;

  -- 4. Lịch sử trạng thái: giữ nguyên tên trạng thái cũ làm bằng chứng, thêm một dòng tóm tắt thẩm định
  INSERT INTO ph01_onboarding.state_history (id, tenant_id, member_system_id, subject_type, subject_id, from_status, to_status, revision_no, reason, actor, emergency, occurred_at, trace_id)
  SELECT u.id, v_tenant, u.application_id, 'MEMBER', u.application_id, u.from_status, u.to_status, 1,
         left(coalesce(u.note, '') || ' [di trú từ ph01 cũ, hành động ' || u.action || ']', 1000), left(u.actor, 64), false, u.created_at, md5(u.id::text)
    FROM ph01.application_audit u
    JOIN ph01_onboarding.member_system m ON m.id = u.application_id AND m.tenant_id = v_tenant
   WHERE u.to_status IS NOT NULL AND u.from_status IS DISTINCT FROM u.to_status
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_hist = ROW_COUNT;
  INSERT INTO ph01_onboarding.state_history (id, tenant_id, member_system_id, subject_type, subject_id, from_status, to_status, revision_no, reason, actor, emergency, occurred_at, trace_id)
  SELECT md5('w1review:' || a.id)::uuid, v_tenant, a.id, 'MEMBER', a.id, NULL, m.status, 1,
         left('Di trú từ ph01.application. Căn cứ pháp lý: ' || coalesce(a.legal_basis, '(trống)')
              || '. Thẩm định pháp lý: ' || coalesce(a.legal_review_status, '-') || ' bởi ' || coalesce(a.legal_review_by, '-') || ': ' || coalesce(a.legal_review_note, '')
              || '. Thẩm định kỹ thuật: ' || coalesce(a.tech_review_status, '-') || ' bởi ' || coalesce(a.tech_review_by, '-') || ': ' || coalesce(a.tech_review_note, ''), 1000),
         'system:migrate', false, now(), md5('w1review:' || a.id)
    FROM ph01.application a
    JOIN ph01_onboarding.member_system m ON m.id = a.id AND m.tenant_id = v_tenant
  ON CONFLICT (id) DO NOTHING;

  -- 5. Bí mật: xóa cột, rồi quét xác nhận (GAP-01-03, BR-01-007)
  SELECT count(*) INTO v_secret FROM ph01.application WHERE client_secret_sealed IS NOT NULL;
  UPDATE ph01.application SET client_secret_sealed = NULL WHERE client_secret_sealed IS NOT NULL;
  ALTER TABLE ph01.application DROP COLUMN IF EXISTS client_secret_sealed;
  SELECT string_agg(table_name || '.' || column_name, ', ') INTO v_bad FROM information_schema.columns
   WHERE table_schema = 'ph01' AND column_name ~* '(secret|passw|private_?key)';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'Còn cột có tên giống bí mật trong schema ph01 cũ: %', v_bad;
  END IF;

  -- 6. Sự kiện outbox cũ chưa phát: không chuyển (sự kiện mới theo EVT-01-*), chỉ báo số lượng
  SELECT count(*) INTO v_unpub FROM ph01.outbox_event WHERE published_at IS NULL;

  -- 7. Đổi tên bảng cũ để giữ bằng chứng
  EXECUTE 'ALTER TABLE ph01.application RENAME TO application_legacy_w1';
  EXECUTE 'ALTER TABLE ph01.application_audit RENAME TO application_audit_legacy_w1';
  EXECUTE 'ALTER TABLE ph01.application_attachment RENAME TO application_attachment_legacy_w1';
  EXECUTE 'ALTER TABLE ph01.outbox_event RENAME TO outbox_event_legacy_w1';

  SELECT count(*) INTO v_active_nocred FROM ph01_onboarding.member_system m
   WHERE m.tenant_id = v_tenant AND m.legacy_ref LIKE 'w1:%' AND m.status = 'ACTIVE'
     AND NOT EXISTS (SELECT 1 FROM ph01_onboarding.app_credential c WHERE c.member_system_id = m.id);
  v_conflict := v_total - v_member;
  RAISE NOTICE 'Di trú PH-01 W1 → tenant %: %/% HTTT, % đầu mối, % tệp (bỏ % tệp không hợp lệ), % dòng lịch sử, % bí mật đã xóa, % sự kiện outbox chưa phát bị bỏ, % HTTT ACTIVE chưa có định danh mới',
    v_tenant, v_member, v_total, v_contact, v_att, v_att_skipped, v_hist, v_secret, v_unpub, v_active_nocred;
END
$mig$;
-- @rollback -- Không tự động: cột bí mật đã xóa không khôi phục được; gỡ bản nháp, từ chối và đổi tên lại bảng *_legacy_w1 do DBA làm thủ công.
