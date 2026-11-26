--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph10_event TO ph10_app;
REVOKE INSERT, UPDATE, DELETE ON ph10_event.comm_type, ph10_event.routing_mode FROM ph10_app;
GRANT UPDATE (enabled, updated_at, updated_by, version) ON ph10_event.comm_type, ph10_event.routing_mode TO ph10_app;  -- PA bật tắt toàn quốc
REVOKE UPDATE ON ph10_event.outbox_event, ph10_event.delivery_failure, ph10_event.dlq_payload FROM ph10_app;            -- chỉ thêm, xóa khi dọn
REVOKE DELETE ON ph10_event.event_project, ph10_event.topic, ph10_event.event_schema, ph10_event.schema_version,
  ph10_event.publisher, ph10_event.subscriber, ph10_event.publication, ph10_event.subscription,
  ph10_event.signing_key, ph10_event.approval_request, ph10_event.replay_request, ph10_event.legacy_mapping,
  ph10_event.migration_bridge FROM ph10_app;                                                                            -- BR-10-003: không xóa cứng
GRANT SELECT ON ALL TABLES IN SCHEMA ph10_event TO ph10_readonly;
REVOKE SELECT ON ph10_event.dlq_payload FROM ph10_readonly;                                                             -- không đọc nội dung sự kiện
REVOKE SELECT ON ph10_event.delivery_failure FROM ph10_readonly;
GRANT SELECT (id, tenant_id, subscription_code, occurred_at, partition, record_offset, event_id, http_status, error_code, failure_class, attempt)
  ON ph10_event.delivery_failure TO ph10_readonly;                                                                      -- không đọc thân phản hồi
GRANT EXECUTE ON PROCEDURE ph10_event.p_ensure_partitions(regclass, date, integer, text) TO ph10_app;
--rollback empty
