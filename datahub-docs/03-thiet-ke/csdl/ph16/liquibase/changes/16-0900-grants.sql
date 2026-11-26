--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph16_kpi TO ph16_app;
-- Dữ liệu cấu hình, phiên bản, báo cáo, nhật ký không xóa cứng: chỉ ngừng, thay thế hoặc dọn theo phân vùng. Dòng con của bản nháp, lệnh xuất, bảng kỹ thuật mới được xóa.
REVOKE DELETE ON ph16_kpi.kpi_indicator_group,
  ph16_kpi.kpi_indicator,
  ph16_kpi.kpi_indicator_version,
  ph16_kpi.kpi_data_source,
  ph16_kpi.kpi_source_contract,
  ph16_kpi.kpi_ingest_log,
  ph16_kpi.kpi_reporting_period,
  ph16_kpi.kpi_manual_value,
  ph16_kpi.kpi_aggregation_run,
  ph16_kpi.kpi_indicator_value,
  ph16_kpi.kpi_group_score,
  ph16_kpi.kpi_report_template,
  ph16_kpi.kpi_report,
  ph16_kpi.kpi_report_version,
  ph16_kpi.kpi_distribution,
  ph16_kpi.kpi_delivery,
  ph16_kpi.kpi_arch_component,
  ph16_kpi.kpi_arch_component_version,
  ph16_kpi.kpi_arch_dependency,
  ph16_kpi.kpi_compliance_criterion,
  ph16_kpi.kpi_compliance_assessment,
  ph16_kpi.kpi_compliance_waiver,
  ph16_kpi.kpi_national_template,
  ph16_kpi.kpi_national_submission,
  ph16_kpi.kpi_tenant_setting FROM ph16_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph16_owner.
REVOKE UPDATE, DELETE ON ph16_kpi.kpi_observation, ph16_kpi.kpi_value_lineage, ph16_kpi.kpi_report_approval, ph16_kpi.kpi_report_signature, ph16_kpi.kpi_national_submission_log FROM ph16_app;
REVOKE UPDATE ON ph16_kpi.outbox_event FROM ph16_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph16_kpi TO ph16_readonly;
REVOKE EXECUTE ON PROCEDURE ph16_kpi.p_seed_common(), ph16_kpi.p_seed_tenant(text), ph16_kpi.p_ensure_partitions(regclass, date, integer) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE ph16_kpi.p_ensure_partitions(regclass, date, integer) TO ph16_app;
GRANT EXECUTE ON PROCEDURE ph16_kpi.p_seed_tenant(text) TO ph16_app;
--rollback empty

--changeset ph16:ph16-0995-compare
-- Ngoại lệ RLS duy nhất: vai ph16_compare đọc giá trị chỉ tiêu hiện hành đã có số của mọi tenant qua khung nhìn security_invoker, chỉ cột cần để so sánh.
-- Ẩn danh tenant và nhóm tối thiểu 16.compare.min-tenants do dịch vụ làm trước khi trả (FR-16-041); PH-16 không trả tên tenant cho tenant khác.
CREATE POLICY rls_kpi_indicator_value_compare ON ph16_kpi.kpi_indicator_value FOR SELECT TO ph16_compare USING (is_current AND completeness <> 'NO_DATA');
CREATE VIEW ph16_kpi.v_compare_value WITH (security_invoker = true) AS
  SELECT tenant_id, period_code, indicator_code, group_code, value, completeness
  FROM ph16_kpi.kpi_indicator_value WHERE is_current AND completeness <> 'NO_DATA';
COMMENT ON VIEW ph16_kpi.v_compare_value IS 'Giá trị chỉ tiêu hiện hành đã có số, dùng cho so sánh liên tenant ẩn danh (FR-16-041); chỉ vai ph16_compare đọc.';
GRANT SELECT ON ph16_kpi.v_compare_value TO ph16_compare;
GRANT SELECT (tenant_id, period_code, indicator_code, group_code, value, completeness, is_current) ON ph16_kpi.kpi_indicator_value TO ph16_compare;
--rollback DROP VIEW IF EXISTS ph16_kpi.v_compare_value; DROP POLICY IF EXISTS rls_kpi_indicator_value_compare ON ph16_kpi.kpi_indicator_value;
