--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph09_privacy TO ph09_app;
-- Đối tượng nghiệp vụ không xóa cứng (nhãn, phân loại, hoạt động, chấp thuận, chính sách, khóa, yêu cầu chủ thể, đồng ý, vi phạm): chỉ dọn bảng tạm, bảng con DRAFT, bảng theo lịch lưu giữ.
REVOKE DELETE ON ph09_privacy.data_class, ph09_privacy.block_label, ph09_privacy.personal_data_category, ph09_privacy.data_element, ph09_privacy.element_classification, ph09_privacy.classification_change, ph09_privacy.detector_rule, ph09_privacy.contract_level, ph09_privacy.legal_document, ph09_privacy.legal_basis, ph09_privacy.processing_activity, ph09_privacy.purpose, ph09_privacy.access_request, ph09_privacy.purpose_grant, ph09_privacy.usage_anomaly, ph09_privacy.mask_type, ph09_privacy.mask_policy, ph09_privacy.log_mask_config, ph09_privacy.pseudonym_domain, ph09_privacy.pseudonym_key, ph09_privacy.reidentification_request, ph09_privacy.anonymization_config, ph09_privacy.anonymization_job, ph09_privacy.risk_report, ph09_privacy.anonymized_dataset, ph09_privacy.retention_schedule, ph09_privacy.retention_task, ph09_privacy.legal_hold, ph09_privacy.tenant_shred_request, ph09_privacy.subject_request, ph09_privacy.subject_verification, ph09_privacy.subject_task, ph09_privacy.consent_template, ph09_privacy.consent_record, ph09_privacy.dpia_record, ph09_privacy.breach_case, ph09_privacy.breach_notification, ph09_privacy.breach_action, ph09_privacy.privacy_audit_event, ph09_privacy.compliance_report, ph09_privacy.tenant_setting FROM ph09_app;
-- Nhật ký kiểm toán chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph09_owner.
REVOKE UPDATE, DELETE ON ph09_privacy.privacy_audit_event FROM ph09_app;
REVOKE UPDATE ON ph09_privacy.outbox_event FROM ph09_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph09_privacy TO ph09_readonly;
-- Báo cáo không đọc cột mã hóa của phiếu yêu cầu chủ thể, nội dung thông báo vi phạm.
REVOKE SELECT ON ph09_privacy.subject_request, ph09_privacy.breach_notification, ph09_privacy.reveal_grant FROM ph09_readonly;
GRANT SELECT (id, tenant_id, request_type, status, channel, identifier_type, received_at, due_at, overdue, verified_at, assigned_to, outcome, responded_at, closed_at, restriction_active)
  ON ph09_privacy.subject_request TO ph09_readonly;
-- Vai data plane /privacy/v1 (quyết định mục đích, kế hoạch che): chỉ đọc chính sách và chỉ mục, ghi bộ đếm; không đọc định danh chủ thể, bằng chứng, hồ sơ vi phạm.
GRANT SELECT ON ph09_privacy.data_class, ph09_privacy.data_element, ph09_privacy.element_classification, ph09_privacy.contract_level, ph09_privacy.purpose, ph09_privacy.purpose_element, ph09_privacy.purpose_grant, ph09_privacy.grant_condition, ph09_privacy.mask_type, ph09_privacy.mask_policy, ph09_privacy.mask_rule, ph09_privacy.policy_bundle, ph09_privacy.personal_data_category, ph09_privacy.block_label, ph09_privacy.legal_hold TO ph09_decide;
GRANT SELECT (tenant_id, subject_hash, restriction_active) ON ph09_privacy.subject_request TO ph09_decide;
GRANT SELECT (tenant_id, subject_hash, template_code, status, expires_at) ON ph09_privacy.consent_record TO ph09_decide;
GRANT SELECT, INSERT, UPDATE ON ph09_privacy.usage_counter TO ph09_decide;
GRANT INSERT ON ph09_privacy.privacy_audit_event TO ph09_decide;
GRANT EXECUTE ON PROCEDURE ph09_privacy.p_ensure_partitions(regclass, date, integer) TO ph09_app;
GRANT EXECUTE ON PROCEDURE ph09_privacy.p_seed_tenant(text) TO ph09_app;
--rollback empty
