--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0100-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-1000-grants splitStatements:false runOnChange:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph15_portal TO ph15_app;
-- Chỉ-ghi-thêm: bằng chứng chấp nhận điều khoản, tin nhắn hỗ trợ.
REVOKE UPDATE, DELETE ON ph15_portal.dev_terms_acceptance, ph15_portal.support_message FROM ph15_app;
-- Không xóa vật lý: mã định danh không dùng lại, lịch sử nội dung, bản sao danh mục (xóa mềm).
REVOKE DELETE ON ph15_portal.catalog_api, ph15_portal.content_page, ph15_portal.content_page_version, ph15_portal.dev_account,
  ph15_portal.dev_team, ph15_portal.app, ph15_portal.app_credential, ph15_portal.support_ticket, ph15_portal.dev_terms,
  ph15_portal.portal_setting, ph15_portal.legacy_mapping, ph15_portal.content_migration, ph15_portal.try_prod_grant FROM ph15_app;
GRANT EXECUTE ON FUNCTION ph15_portal.next_ticket_code(), ph15_portal.seed_tenant(varchar, varchar), ph15_portal.f_unaccent(text) TO ph15_app, ph15_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA ph15_portal TO ph15_readonly;
-- Đọc kiểm toán, báo cáo: không thấy cột bí mật, mã hóa, băm xác minh; không thấy bảng kỹ thuật.
REVOKE SELECT ON ph15_portal.idempotency_record, ph15_portal.shedlock, ph15_portal.app_credential, ph15_portal.dev_account FROM ph15_readonly;
DO $g$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM (VALUES ('app_credential', 'key_hash'), ('dev_account', 'phone_enc,dek_wrapped,verification_token_hash')) v(t, excl) LOOP
    EXECUTE format('GRANT SELECT (%s) ON ph15_portal.%I TO ph15_readonly',
      (SELECT string_agg(quote_ident(column_name), ',') FROM information_schema.columns
        WHERE table_schema = 'ph15_portal' AND table_name = r.t AND column_name <> ALL (string_to_array(r.excl, ','))), r.t);
  END LOOP;
END
$g$;
--rollback REVOKE ALL ON ALL TABLES IN SCHEMA ph15_portal FROM ph15_app, ph15_readonly;
