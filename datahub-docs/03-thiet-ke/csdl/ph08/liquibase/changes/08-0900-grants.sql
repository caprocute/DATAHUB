--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0990-grants runAlways:true
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
--rollback empty

--changeset ph08:ph08-0995-benchmark
-- Ngoại lệ RLS duy nhất: vai ph08_benchmark đọc điểm chiều của ảnh chụp chính thức mọi tenant qua khung nhìn security_invoker, chỉ cột cần để tổng hợp.
-- Việc kiểm tenant đã bật 08.benchmark.opt-in và nhóm tối thiểu 5 tenant do dịch vụ làm trước khi trả (BR-08-030).
CREATE POLICY rls_dq_score_snapshot_benchmark ON ph08_dq.dq_score_snapshot FOR SELECT TO ph08_benchmark USING (official);
CREATE POLICY rls_dq_score_dimension_benchmark ON ph08_dq.dq_score_dimension FOR SELECT TO ph08_benchmark USING (status = 'MEASURED');
CREATE VIEW ph08_dq.v_benchmark_dimension WITH (security_invoker = true) AS
  SELECT s.tenant_id, s.period_code, d.dimension, d.score
  FROM ph08_dq.dq_score_dimension d JOIN ph08_dq.dq_score_snapshot s ON s.tenant_id = d.tenant_id AND s.id = d.snapshot_id;
COMMENT ON VIEW ph08_dq.v_benchmark_dimension IS 'Điểm chiều của ảnh chụp chính thức, dùng cho so sánh liên tenant ẩn danh (FR-08-061); chỉ vai ph08_benchmark đọc.';
GRANT SELECT ON ph08_dq.v_benchmark_dimension TO ph08_benchmark;
GRANT SELECT (tenant_id, id, period_code, official) ON ph08_dq.dq_score_snapshot TO ph08_benchmark;
GRANT SELECT (tenant_id, snapshot_id, dimension, score, status) ON ph08_dq.dq_score_dimension TO ph08_benchmark;
--rollback DROP VIEW IF EXISTS ph08_dq.v_benchmark_dimension; DROP POLICY IF EXISTS rls_dq_score_dimension_benchmark ON ph08_dq.dq_score_dimension; DROP POLICY IF EXISTS rls_dq_score_snapshot_benchmark ON ph08_dq.dq_score_snapshot;
