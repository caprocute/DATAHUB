--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph17_assist TO ph17_app;
-- Đối tượng nghiệp vụ không xóa cứng (chính sách, mô hình, phiên bản, ca đỏ, phản hồi, phiếu, gói bằng chứng, hội thoại): chỉ dọn dữ liệu tạm và đoạn tri thức.
REVOKE DELETE ON ph17_assist.file_object, ph17_assist.tenant_setting, ph17_assist.ai_notice, ph17_assist.policy_change, ph17_assist.tenant_policy, ph17_assist.capability_policy, ph17_assist.kill_switch_record, ph17_assist.model_provider, ph17_assist.provider_commitment, ph17_assist.model, ph17_assist.model_version, ph17_assist.model_route, ph17_assist.route_sync_run, ph17_assist.tenant_model, ph17_assist.provider_grant, ph17_assist.model_breaker, ph17_assist.knowledge_source, ph17_assist.index_job, ph17_assist.tool_definition, ph17_assist.suggested_question, ph17_assist.guardrail_rule, ph17_assist.prompt_template, ph17_assist.prompt_version, ph17_assist.eval_set, ph17_assist.eval_dataset_link, ph17_assist.eval_case, ph17_assist.eval_run, ph17_assist.redteam_case, ph17_assist.feedback, ph17_assist.quality_metric, ph17_assist.ai_system_record, ph17_assist.log_access_grant, ph17_assist.compliance_export, ph17_assist.conversation, ph17_assist.message, ph17_assist.citation, ph17_assist.tool_call, ph17_assist.explanation, ph17_assist.suggestion FROM ph17_app;
-- Vết, nhật ký, xác nhận điều khoản: chỉ thêm (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph17_owner.
REVOKE UPDATE, DELETE ON ph17_assist.invocation_log, ph17_assist.model_health_probe, ph17_assist.notice_acceptance, ph17_assist.knowledge_deletion FROM ph17_app;
REVOKE UPDATE ON ph17_assist.outbox_event FROM ph17_app;
-- Vai job: đọc, xóa hội thoại và dòng con hết hạn (lịch lưu giữ), dọn bộ đếm; RLS theo hạn ở p_enable_rls_user.
GRANT SELECT, DELETE ON ph17_assist.conversation, ph17_assist.message, ph17_assist.citation, ph17_assist.tool_call, ph17_assist.explanation TO ph17_job;
GRANT DELETE ON ph17_assist.quota_usage, ph17_assist.model_health_probe TO ph17_job;
-- Vai nền tảng (PA): ghi dòng COMMON của bảng dùng chung; không đọc bảng của tenant.
GRANT SELECT, INSERT, UPDATE ON ph17_assist.model_provider, ph17_assist.provider_commitment, ph17_assist.model, ph17_assist.model_version, ph17_assist.model_route, ph17_assist.route_sync_run, ph17_assist.kill_switch_record, ph17_assist.knowledge_source, ph17_assist.knowledge_document, ph17_assist.knowledge_chunk, ph17_assist.knowledge_deletion, ph17_assist.prompt_template, ph17_assist.prompt_version, ph17_assist.eval_set, ph17_assist.eval_case, ph17_assist.eval_run, ph17_assist.eval_result, ph17_assist.redteam_case, ph17_assist.file_object, ph17_assist.model_health_probe TO ph17_platform;
GRANT DELETE ON ph17_assist.knowledge_chunk, ph17_assist.knowledge_document, ph17_assist.eval_result TO ph17_platform;
REVOKE UPDATE, DELETE ON ph17_assist.knowledge_deletion, ph17_assist.model_health_probe FROM ph17_platform;
GRANT SELECT ON ph17_assist.tenant_setting TO ph17_platform;
-- Vai data plane /assist/v1 (DU gọi, mTLS): đọc cấu hình, ghi vết và bộ đếm, tạo gợi ý bước quy trình; không đọc hội thoại, đoạn tri thức, nhật ký.
GRANT SELECT ON ph17_assist.tenant_policy, ph17_assist.capability_policy, ph17_assist.tenant_model, ph17_assist.model, ph17_assist.model_version, ph17_assist.model_route, ph17_assist.model_provider, ph17_assist.model_breaker, ph17_assist.tenant_setting, ph17_assist.kill_switch_record, ph17_assist.prompt_template, ph17_assist.prompt_version, ph17_assist.guardrail_rule, ph17_assist.link_allowlist, ph17_assist.tool_definition TO ph17_infer;
GRANT INSERT ON ph17_assist.invocation_log TO ph17_infer;
GRANT SELECT, INSERT, UPDATE ON ph17_assist.quota_usage TO ph17_infer;
GRANT SELECT, INSERT, UPDATE ON ph17_assist.suggestion TO ph17_infer;
GRANT INSERT ON ph17_assist.outbox_event TO ph17_infer;
-- Báo cáo: đọc mọi bảng trừ hội thoại và nội dung; phản hồi chỉ cột không có lý do đã che.
GRANT SELECT ON ALL TABLES IN SCHEMA ph17_assist TO ph17_readonly;
REVOKE SELECT ON ph17_assist.conversation, ph17_assist.message, ph17_assist.citation, ph17_assist.tool_call, ph17_assist.explanation, ph17_assist.suggestion, ph17_assist.feedback, ph17_assist.knowledge_chunk FROM ph17_readonly;
GRANT SELECT (id, tenant_id, message_id, kind, status, due_at, closed_at, created_at) ON ph17_assist.feedback TO ph17_readonly;
GRANT SELECT (id, tenant_id, source_id, document_id, chunk_no, class_level, embed_version_id, token_count, created_at) ON ph17_assist.knowledge_chunk TO ph17_readonly;
GRANT EXECUTE ON PROCEDURE ph17_assist.p_ensure_partitions(regclass, date, integer) TO ph17_app, ph17_job;
GRANT EXECUTE ON PROCEDURE ph17_assist.p_seed_tenant(text) TO ph17_app;
--rollback empty
