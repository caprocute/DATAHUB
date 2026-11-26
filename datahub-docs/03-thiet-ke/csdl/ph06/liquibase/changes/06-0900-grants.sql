--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph06_mdm TO ph06_app;
-- Bản ghi vàng và đối tượng nghiệp vụ không xóa cứng (BR-06-007): chỉ dọn bảng trung gian, nhật ký quá hạn theo retention_policy.
REVOKE DELETE ON ph06_mdm.mdm_domain, ph06_mdm.domain_model, ph06_mdm.model_attribute, ph06_mdm.identifier_rule, ph06_mdm.mdm_source,
  ph06_mdm.source_priority_proposal, ph06_mdm.source_priority, ph06_mdm.match_rule_set, ph06_mdm.match_rule, ph06_mdm.evaluation_report,
  ph06_mdm.golden_record, ph06_mdm.golden_attribute, ph06_mdm.golden_identifier, ph06_mdm.source_xref, ph06_mdm.golden_operation,
  ph06_mdm.survivorship_rule_set, ph06_mdm.survivorship_rule, ph06_mdm.steward_item, ph06_mdm.update_subscription, ph06_mdm.export_request,
  ph06_mdm.national_sync_state, ph06_mdm.national_sync_run, ph06_mdm.national_discrepancy, ph06_mdm.source_correction, ph06_mdm.subject_request,
  ph06_mdm.label_set, ph06_mdm.job_schedule, ph06_mdm.retention_policy, ph06_mdm.tenant_setting, ph06_mdm.match_job FROM ph06_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph06_owner.
REVOKE UPDATE, DELETE ON ph06_mdm.golden_history, ph06_mdm.attribute_lineage, ph06_mdm.access_log, ph06_mdm.processing_log FROM ph06_app;
REVOKE UPDATE ON ph06_mdm.outbox_event FROM ph06_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph06_mdm TO ph06_readonly;
-- Báo cáo, Job Splink không đọc dữ liệu mã hóa và nhật ký truy cập: cột *_enc bị thu hồi ở bảng nhạy cảm.
REVOKE SELECT ON ph06_mdm.access_log, ph06_mdm.golden_history, ph06_mdm.subject_request, ph06_mdm.golden_identifier FROM ph06_readonly;
GRANT SELECT (id, tenant_id, accessed_at, actor, system_code, domain_code, golden_id, api_code, purpose_code, result_count, bulk_flag, trace_id)
  ON ph06_mdm.access_log TO ph06_readonly;
-- Vai Job Splink (FR-06-022): chỉ đọc match_staging, chỉ thêm match_result; không đọc bảng nào khác.
GRANT SELECT ON ph06_mdm.match_staging TO ph06_splink;
GRANT INSERT ON ph06_mdm.match_result TO ph06_splink;
GRANT EXECUTE ON PROCEDURE ph06_mdm.p_ensure_partitions(regclass, date, integer) TO ph06_app;
GRANT EXECUTE ON PROCEDURE ph06_mdm.p_seed_tenant(text) TO ph06_app;
--rollback empty
