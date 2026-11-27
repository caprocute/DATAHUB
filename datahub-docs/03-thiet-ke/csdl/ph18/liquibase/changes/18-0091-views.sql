--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0091-views.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0900-view-config-param splitStatements:false
-- Tương thích DD-14 (D02-07 dòng 151, FRS-07 nêu ph18_ops.config_param): khung nhìn giá trị hiệu lực theo tenant phiên. security_invoker nên RLS của bảng gốc áp cho người đọc.
CREATE OR REPLACE VIEW ph18_ops.config_param WITH (security_invoker = true) AS
SELECT d.param_key                                                     AS key,
       COALESCE(t.value, p.value, d.default_value)                     AS value,
       d.json_schema                                                   AS schema,
       CASE WHEN t.id IS NOT NULL THEN 'TENANT' ELSE 'PLATFORM' END    AS scope,
       COALESCE(t.effective_from, p.effective_from, d.created_at)      AS effective_from,
       current_setting('app.tenant_id', false)                         AS tenant_id,
       d.namespace_code, d.value_type, d.level, d.secure, d.display_group,
       COALESCE(t.current_version_no, p.current_version_no, 0)         AS version_no
  FROM ph18_ops.param_definition d
  LEFT JOIN ph18_ops.param_value p ON p.definition_id = d.id AND p.tenant_id = 'COMMON'
  LEFT JOIN ph18_ops.param_value t ON t.definition_id = d.id AND t.tenant_id = current_setting('app.tenant_id', false) AND t.tenant_id <> 'COMMON'
 WHERE d.removal_date IS NULL OR d.removal_date >= current_date;
COMMENT ON VIEW ph18_ops.config_param IS 'DD-14 Tham số cấu hình: key, value, schema, scope (PLATFORM hoặc TENANT), effective_from; giá trị hiệu lực = ghi đè tenant, nếu không thì giá trị nền tảng, nếu không thì mặc định của lược đồ khóa.';
--rollback DROP VIEW IF EXISTS ph18_ops.config_param;

--changeset ph18:ph18-0901-view-notification splitStatements:false
-- Tương thích DD-13 (D02-07 dòng 150): hộp thông báo trong ứng dụng.
CREATE OR REPLACE VIEW ph18_ops.notification WITH (security_invoker = true) AS
SELECT d.id, d.tenant_id, d.recipient_user_id, m.category, d.rendered_title AS title, m.link, d.read_at, to_jsonb(m.channels) AS channels_sent,
       d.status, d.queued_at AS created_at
  FROM ph18_ops.notification_delivery d
  JOIN ph18_ops.notification_message m ON m.tenant_id = d.tenant_id AND m.id = d.message_id
 WHERE d.channel = 'IN_APP';
COMMENT ON VIEW ph18_ops.notification IS 'DD-13 Thông báo: recipient_user_id, category, title, link, read_at, channels_sent; chỉ kênh IN_APP.';
--rollback DROP VIEW IF EXISTS ph18_ops.notification;
