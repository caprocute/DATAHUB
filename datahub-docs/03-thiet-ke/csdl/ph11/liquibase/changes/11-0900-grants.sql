--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph11_bpm TO ph11_app;
-- Cấu hình, phiên bản, bằng chứng phê duyệt, can thiệp phiên và nhật ký Saga không xóa cứng; chỉ dọn bản chiếu, bảng trung gian, chạy thử và ngày lịch theo chính sách lưu giữ.
REVOKE DELETE ON ph11_bpm.process_model, ph11_bpm.process_version, ph11_bpm.form_definition, ph11_bpm.service_intent, ph11_bpm.compensation_action,
  ph11_bpm.process_template, ph11_bpm.variable_definition, ph11_bpm.decision_table, ph11_bpm.publish_request, ph11_bpm.migration_plan,
  ph11_bpm.instance_change, ph11_bpm.business_calendar, ph11_bpm.saga_log, ph11_bpm.saga_step, ph11_bpm.tenant_setting,
  ph11_bpm.delegation, ph11_bpm.saga_skip_request, ph11_bpm.legal_hold, ph11_bpm.compliance_sample_run FROM ph11_app;
-- Bảng chỉ thêm: ý kiến trên việc không sửa, không xóa (trigger là lớp chặn thứ hai); lịch sử bước dọn bằng DETACH phân vùng dưới ph11_owner.
REVOKE UPDATE, DELETE ON ph11_bpm.task_comment FROM ph11_app;
REVOKE DELETE ON ph11_bpm.instance_step FROM ph11_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph11_bpm TO ph11_readonly;
-- Báo cáo không đọc kết quả biểu mẫu, nháp, ý kiến, tệp đính kèm, thông điệp nhận, nội dung đề nghị can thiệp và kết quả chạy thử: thu hồi ở bảng nhạy cảm rồi cấp lại theo cột an toàn.
REVOKE SELECT ON ph11_bpm.task_index, ph11_bpm.task_comment, ph11_bpm.task_attachment, ph11_bpm.inbox_message, ph11_bpm.instance_change, ph11_bpm.test_run FROM ph11_readonly;
GRANT SELECT (id, tenant_id, engine_task_id, instance_id, element_id, task_kind, name, form_key, status, assignee, priority, due_at, claimed_at, closed_at, decision, created_at, updated_at)
  ON ph11_bpm.task_index TO ph11_readonly;
GRANT EXECUTE ON PROCEDURE ph11_bpm.p_ensure_partitions(regclass, date, integer) TO ph11_app;
GRANT EXECUTE ON PROCEDURE ph11_bpm.p_seed_tenant(text) TO ph11_app;
-- Engine Flowable: ph11_engine là chủ schema ph11_flowable nên toàn quyền; schema mới không cấp gì cho PUBLIC, ph11_app và ph11_readonly không truy cập.
--rollback empty
