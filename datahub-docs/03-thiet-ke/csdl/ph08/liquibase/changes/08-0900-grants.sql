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
