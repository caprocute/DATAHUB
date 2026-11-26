-- @file 16-0090-seed.sql
-- @changeset ph16-0910-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: 25 tham số 16.*, năm nhóm chỉ tiêu, bộ tiêu chí tuân thủ tối thiểu và mẫu báo cáo mặc định, sao chép từ COMMON. Chỉ tiêu mẫu do người dùng kế thừa (FR-16-008), không seed.
CREATE OR REPLACE PROCEDURE ph16_kpi.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by)
  SELECT md5('ph16-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES @@SET@@) AS s(k, v)
  ON CONFLICT (tenant_id, param_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_indicator_group (id, tenant_id, group_code, name, description, weight, display_order, enabled, created_by, updated_by)
  SELECT md5('ph16-group:' || p_tenant || ':' || g.group_code)::uuid, p_tenant, g.group_code, g.name, g.description, g.weight, g.display_order, g.enabled, 'system:seed', 'system:seed'
  FROM ph16_kpi.kpi_indicator_group g WHERE g.tenant_id = 'COMMON'
  ON CONFLICT (tenant_id, group_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_compliance_criterion (id, tenant_id, criterion_code, version_no, name, description, applies_to, mandatory, weight, framework_ref, state, activated_at, created_by, updated_by)
  SELECT md5('ph16-criterion:' || p_tenant || ':' || c.criterion_code || ':' || c.version_no)::uuid, p_tenant, c.criterion_code, c.version_no, c.name, c.description, c.applies_to,
         c.mandatory, c.weight, c.framework_ref, c.state, c.activated_at, 'system:seed', 'system:seed'
  FROM ph16_kpi.kpi_compliance_criterion c WHERE c.tenant_id = 'COMMON' AND c.state = 'ACTIVE'
  ON CONFLICT (tenant_id, criterion_code, version_no) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, version_no, name, state, sections, formats, layout, description, activated_at, created_by, updated_by)
  SELECT md5('ph16-template:' || p_tenant || ':' || t.template_code || ':' || t.version_no)::uuid, p_tenant, t.template_code, t.version_no, t.name, t.state, t.sections, t.formats, t.layout,
         t.description, t.activated_at, 'system:seed', 'system:seed'
  FROM ph16_kpi.kpi_report_template t WHERE t.tenant_id = 'COMMON' AND t.state = 'ACTIVE'
  ON CONFLICT (tenant_id, template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): 25 tham số 16.*, 5 nhóm chỉ tiêu, 6 tiêu chí tuân thủ, 1 mẫu báo cáo sao chép từ COMMON. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph16_kpi.p_seed_tenant(text);

-- @changeset ph16-0920-fn-seed-common splitStatements:false
-- Bộ chỉ tiêu mẫu toàn quốc (tenant COMMON): 5 nhóm, 24 chỉ tiêu (brief PH-16 mục 5), 6 tiêu chí tuân thủ tối thiểu, 1 mẫu báo cáo. Chạy dưới phiên PLATFORM.
-- Chỉ tiêu mẫu chưa có phiên bản định nghĩa: công thức chờ chốt hợp đồng chỉ số với phân hệ nguồn (Q16-51).
CREATE OR REPLACE PROCEDURE ph16_kpi.p_seed_common()
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph16_kpi.kpi_indicator_group (id, tenant_id, group_code, name, description, weight, display_order, created_by, updated_by)
  SELECT md5('ph16-group:COMMON:' || g.c)::uuid, 'COMMON', g.c, g.n, g.d, 20.00, g.o, 'system:seed', 'system:seed'
  FROM (VALUES @@GRP@@) AS g(c, n, d, o)
  ON CONFLICT (tenant_id, group_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, aggregation, scope, mandatory, brd_ref, display_order, created_by, updated_by)
  SELECT md5('ph16-indicator:COMMON:' || i.c)::uuid, 'COMMON', i.c, i.g, i.n, i.k, i.d, i.m, i.u, i.a, 'COMMON', i.mand, i.brd, i.o, 'system:seed', 'system:seed'
  FROM (VALUES @@IND@@) AS i(c, g, n, k, d, m, u, a, mand, brd, o)
  ON CONFLICT (tenant_id, indicator_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_compliance_criterion (id, tenant_id, criterion_code, version_no, name, description, applies_to, mandatory, weight, state, activated_at, created_by, updated_by)
  SELECT md5('ph16-criterion:COMMON:' || c.c || ':1')::uuid, 'COMMON', c.c, 1, c.n, c.d, c.t::text[], c.m, c.w, 'ACTIVE', now(), 'system:seed', 'system:seed'
  FROM (VALUES @@CRIT@@) AS c(c, n, d, t, m, w)
  ON CONFLICT (tenant_id, criterion_code, version_no) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, version_no, name, state, sections, formats, description, activated_at, created_by, updated_by)
  VALUES (md5('ph16-template:COMMON:bao-cao-chi-tieu-ky:1')::uuid, 'COMMON', 'bao-cao-chi-tieu-ky', 1, 'Báo cáo chỉ tiêu theo kỳ', 'ACTIVE',
          '{SUMMARY,GROUP,INDICATOR_TABLE,CHART,NARRATIVE,ANNEX}', '{PDF,XLSX}', 'Mẫu mặc định: tóm tắt, năm nhóm, bảng chỉ tiêu, biểu đồ, thuyết minh, phụ lục.', now(), 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_seed_common() IS 'Nạp bộ mẫu COMMON: 5 nhóm, 24 chỉ tiêu, 6 tiêu chí tuân thủ tối thiểu, 1 mẫu báo cáo. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph16_kpi.p_seed_common();

-- @changeset ph16-0930-seed-common-run
CALL ph16_kpi.p_seed_common();
-- @rollback DELETE FROM ph16_kpi.kpi_report_template WHERE tenant_id = 'COMMON'; DELETE FROM ph16_kpi.kpi_compliance_criterion WHERE tenant_id = 'COMMON'; DELETE FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON'; DELETE FROM ph16_kpi.kpi_indicator_group WHERE tenant_id = 'COMMON';

-- @file 16-0900-grants.sql
-- @changeset ph16-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph16_kpi TO ph16_app;
-- Dữ liệu cấu hình, phiên bản, báo cáo, nhật ký không xóa cứng: chỉ ngừng, thay thế hoặc dọn theo phân vùng. Dòng con của bản nháp, lệnh xuất, bảng kỹ thuật mới được xóa.
REVOKE DELETE ON @@NODEL@@ FROM ph16_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph16_owner.
REVOKE UPDATE, DELETE ON @@APPEND@@ FROM ph16_app;
REVOKE UPDATE ON ph16_kpi.outbox_event FROM ph16_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph16_kpi TO ph16_readonly;
REVOKE EXECUTE ON PROCEDURE ph16_kpi.p_seed_common(), ph16_kpi.p_seed_tenant(text), ph16_kpi.p_ensure_partitions(regclass, date, integer) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE ph16_kpi.p_ensure_partitions(regclass, date, integer) TO ph16_app;
GRANT EXECUTE ON PROCEDURE ph16_kpi.p_seed_tenant(text) TO ph16_app;
-- @rollback -- Không thu hồi tự động.

-- @changeset ph16-0995-compare
-- Ngoại lệ RLS duy nhất: vai ph16_compare đọc giá trị chỉ tiêu hiện hành đã có số của mọi tenant qua khung nhìn security_invoker, chỉ cột cần để so sánh.
-- Ẩn danh tenant và nhóm tối thiểu 16.compare.min-tenants do dịch vụ làm trước khi trả (FR-16-041); PH-16 không trả tên tenant cho tenant khác.
CREATE POLICY rls_kpi_indicator_value_compare ON ph16_kpi.kpi_indicator_value FOR SELECT TO ph16_compare USING (is_current AND completeness <> 'NO_DATA');
CREATE VIEW ph16_kpi.v_compare_value WITH (security_invoker = true) AS
  SELECT tenant_id, period_code, indicator_code, group_code, value, completeness
  FROM ph16_kpi.kpi_indicator_value WHERE is_current AND completeness <> 'NO_DATA';
COMMENT ON VIEW ph16_kpi.v_compare_value IS 'Giá trị chỉ tiêu hiện hành đã có số, dùng cho so sánh liên tenant ẩn danh (FR-16-041); chỉ vai ph16_compare đọc.';
GRANT SELECT ON ph16_kpi.v_compare_value TO ph16_compare;
GRANT SELECT (tenant_id, period_code, indicator_code, group_code, value, completeness, is_current) ON ph16_kpi.kpi_indicator_value TO ph16_compare;
-- @rollback DROP VIEW IF EXISTS ph16_kpi.v_compare_value; DROP POLICY IF EXISTS rls_kpi_indicator_value_compare ON ph16_kpi.kpi_indicator_value;

RESET ROLE;
