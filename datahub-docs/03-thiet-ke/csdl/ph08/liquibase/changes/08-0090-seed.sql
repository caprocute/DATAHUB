--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0090-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0910-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: tham số 08.* mặc định, chính sách lưu giữ, cấu hình trọng số mặc định đã ACTIVE, lịch đo tháng cho cả tenant.
CREATE OR REPLACE PROCEDURE ph08_dq.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph08_dq.dq_tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by)
  SELECT md5('ph08-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('08.scan.default-cron', '"0 0 2 1 * *"'), ('08.scan.sample-ratio', '0.1'), ('08.scan.shard-rows', '1000000'), ('08.scan.timeout-minutes', '120'), ('08.finding.retention-months', '13'), ('08.finding.max-per-rule', '10000'), ('08.inline.timeout-ms', '50'), ('08.inline.cache-ttl-seconds', '60'), ('08.inline.default-mode', '"ADVISORY"'), ('08.inline.on-failure', '"FAIL_OPEN"'), ('08.sla.critical-days', '5'), ('08.sla.major-days', '15'), ('08.sla.minor-days', '30'), ('08.waiver.max-days', '180'), ('08.export.max-rows', '100000'), ('08.score.pass-min', '90'), ('08.score.warn-min', '75'), ('08.alert.cooldown-minutes', '60'), ('08.score.history-months', '24')) AS s(k, v)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph08_dq.dq_retention_policy (id, tenant_id, object_type, retention_days, action, created_by, updated_by)
  SELECT md5('ph08-retention:' || p_tenant || ':' || r.t)::uuid, p_tenant, r.t, r.d, r.a, 'system:seed', 'system:seed'
  FROM (VALUES ('dq_finding', 395, 'DROP_PARTITION'), ('dq_rule_result', 395, 'DROP_PARTITION'), ('dq_inline_stat', 90, 'DROP_PARTITION'), ('dq_scan_task', 90, 'DELETE'), ('dq_profile_column', 395, 'DELETE'), ('dq_score_snapshot', 1825, 'ARCHIVE_COLD'), ('dq_issue', 1825, 'ARCHIVE_COLD'), ('dq_alert', 395, 'DELETE'), ('dq_report', 3650, 'ARCHIVE_COLD'), ('dq_export_request', 30, 'DELETE'), ('outbox_event', 3, 'DELETE'), ('inbox_event', 30, 'DELETE')) AS r(t, d, a)
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
--rollback DROP PROCEDURE IF EXISTS ph08_dq.p_seed_tenant(text);

--changeset ph08:ph08-0920-fn-seed-common splitStatements:false
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
--rollback DROP PROCEDURE IF EXISTS ph08_dq.p_seed_common();

--changeset ph08:ph08-0930-seed-common-run
CALL ph08_dq.p_seed_common();
--rollback DELETE FROM ph08_dq.dq_rule_template WHERE tenant_id = 'COMMON';
