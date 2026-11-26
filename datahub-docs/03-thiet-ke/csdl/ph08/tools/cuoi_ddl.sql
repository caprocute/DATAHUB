-- @file 08-0090-seed.sql
-- @changeset ph08-0910-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: tham số 08.* mặc định, chính sách lưu giữ, cấu hình trọng số mặc định đã ACTIVE, lịch đo tháng cho cả tenant.
CREATE OR REPLACE PROCEDURE ph08_dq.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph08_dq.dq_tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by)
  SELECT md5('ph08-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES @@SET@@) AS s(k, v)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph08_dq.dq_retention_policy (id, tenant_id, object_type, retention_days, action, created_by, updated_by)
  SELECT md5('ph08-retention:' || p_tenant || ':' || r.t)::uuid, p_tenant, r.t, r.d, r.a, 'system:seed', 'system:seed'
  FROM (VALUES @@RET@@) AS r(t, d, a)
  ON CONFLICT (tenant_id, object_type) DO NOTHING;
  INSERT INTO ph08_dq.dq_weight_config (id, tenant_id, config_code, version_no, status, activated_at, change_note, created_by, updated_by)
  VALUES (md5('ph08-weight:' || p_tenant)::uuid, p_tenant, 'DEFAULT', 1, 'ACTIVE', now(), 'Trọng số mặc định 0,20/0,20/0,15/0,10/0,15/0,20', 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, config_code, version_no) DO NOTHING;
  INSERT INTO ph08_dq.dq_schedule (id, tenant_id, schedule_code, cron, scan_mode, enabled, created_by, updated_by)
  VALUES (md5('ph08-schedule:' || p_tenant)::uuid, p_tenant, 'MONTHLY-ALL', '0 0 2 1 * *', 'FULL', true, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, schedule_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): 19 tham số 08.*, 12 chính sách lưu giữ, trọng số mặc định, lịch đo tháng. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph08_dq.p_seed_tenant(text);

-- @changeset ph08-0920-fn-seed-common splitStatements:false
-- Bộ quy tắc mẫu dùng chung (tenant COMMON, FR-08-015). Chạy dưới phiên PLATFORM.
CREATE OR REPLACE PROCEDURE ph08_dq.p_seed_common()
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph08_dq.dq_rule_template (id, tenant_id, template_code, name, dimension, operator, default_severity, params, expression_template, description, created_by, updated_by)
  SELECT md5('ph08-template:' || t.c)::uuid, 'COMMON', t.c, t.n, t.d, t.o, t.s, t.p::jsonb, t.e, t.n, 'system:seed', 'system:seed'
  FROM (VALUES
    ('VN-CCCD-12', 'Số CCCD gồm 12 chữ số', 'VALIDITY', 'REGEX', 'MAJOR', '{"pattern":"^[0-9]{12}$"}', NULL),
    ('VN-MST-FORMAT', 'Mã số thuế 10 số hoặc 13 số có gạch', 'VALIDITY', 'REGEX', 'MAJOR', '{"pattern":"^[0-9]{10}(-[0-9]{3})?$"}', NULL),
    ('VN-MST-CHECKSUM', 'Chữ số kiểm tra của mã số thuế', 'ACCURACY', 'CHECKSUM', 'MAJOR', '{"algorithm":"MST_VN"}', NULL),
    ('VN-SDT', 'Số điện thoại di động Việt Nam', 'VALIDITY', 'REGEX', 'MINOR', '{"pattern":"^(0|\\+84)[0-9]{9}$"}', NULL),
    ('VN-EMAIL', 'Địa chỉ email đúng cú pháp', 'VALIDITY', 'REGEX', 'MINOR', '{"pattern":"^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"}', NULL),
    ('VN-DVHC-IN-RDM', 'Mã đơn vị hành chính có trong danh mục PH-07', 'VALIDITY', 'IN_RDM', 'MAJOR', '{"catalogCode":"${catalog}"}', NULL),
    ('NOT-NULL-CDE', 'Phần tử dữ liệu trọng yếu không để trống', 'COMPLETENESS', 'NOT_NULL', 'CRITICAL', '{}', NULL),
    ('NOT-EMPTY-TEXT', 'Chuỗi không rỗng sau khi cắt khoảng trắng', 'COMPLETENESS', 'NOT_EMPTY', 'MINOR', '{}', NULL),
    ('UNIQUE-KEY', 'Khóa nghiệp vụ không trùng trong đối tượng đo', 'UNIQUENESS', 'UNIQUE_IN_ASSET', 'CRITICAL', '{}', NULL),
    ('FRESH-30D', 'Bản ghi cập nhật trong 30 ngày', 'TIMELINESS', 'MAX_AGE_DAYS', 'MINOR', '{"days":30}', NULL),
    ('DOB-RANGE', 'Ngày sinh từ 1900 đến hôm nay', 'VALIDITY', 'RANGE', 'MAJOR', '{"min":"1900-01-01","max":"today"}', NULL),
    ('DATE-ORDER', 'Ngày bắt đầu không sau ngày kết thúc', 'CONSISTENCY', 'CEL_EXPRESSION', 'MAJOR', '{}', 'record.from_date <= record.to_date')
  ) AS t(c, n, d, o, s, p, e)
  ON CONFLICT (tenant_id, template_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_seed_common() IS 'Nạp 12 quy tắc mẫu COMMON (CCCD, MST, SĐT, email, ĐVHC, CDE, trùng khóa, độ tươi, ngày sinh, thứ tự ngày). Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph08_dq.p_seed_common();

-- @changeset ph08-0930-seed-common-run
CALL ph08_dq.p_seed_common();
-- @rollback DELETE FROM ph08_dq.dq_rule_template WHERE tenant_id = 'COMMON';

-- @file 08-0900-grants.sql
-- @changeset ph08-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph08_dq TO ph08_app;
-- Đối tượng nghiệp vụ không xóa cứng: chỉ ngừng. Dòng con của bản nháp, bảng tạm và bảng kỹ thuật mới được xóa.
REVOKE DELETE ON ph08_dq.dq_domain, ph08_dq.dq_asset, ph08_dq.dq_profile_run, ph08_dq.dq_rule_template, ph08_dq.dq_weight_config, ph08_dq.dq_rule_set,
  ph08_dq.dq_rule_set_version, ph08_dq.dq_schedule, ph08_dq.dq_scan_job, ph08_dq.dq_score_snapshot, ph08_dq.dq_score_dimension, ph08_dq.dq_waiver,
  ph08_dq.dq_issue, ph08_dq.dq_alert_rule, ph08_dq.dq_report, ph08_dq.dq_tenant_setting, ph08_dq.dq_retention_policy FROM ph08_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph08_owner.
REVOKE UPDATE, DELETE ON ph08_dq.dq_rule_result, ph08_dq.dq_issue_activity FROM ph08_app;
REVOKE DELETE ON ph08_dq.dq_finding, ph08_dq.dq_inline_stat FROM ph08_app;
REVOKE UPDATE ON ph08_dq.outbox_event FROM ph08_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph08_dq TO ph08_readonly;
-- Báo cáo, BI chỉ đọc không thấy giá trị đã che, băm giá trị, khóa bản ghi che.
REVOKE SELECT ON ph08_dq.dq_finding FROM ph08_readonly;
GRANT SELECT (id, tenant_id, last_seen_at, asset_id, rule_id, dimension, severity, fingerprint, field_name, data_class, status, owner_org_code, first_seen_at,
  first_scan_job_id, last_scan_job_id, seen_count, resolved_at, issue_id, waiver_id) ON ph08_dq.dq_finding TO ph08_readonly;
GRANT EXECUTE ON PROCEDURE ph08_dq.p_ensure_partitions(regclass, date, integer) TO ph08_app;
GRANT EXECUTE ON PROCEDURE ph08_dq.p_seed_tenant(text) TO ph08_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
