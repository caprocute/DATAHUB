--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0900-grants.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-9000-grants splitStatements:false
-- Quyền tối thiểu. ph07_app: DML theo nhu cầu nghiệp vụ, không DDL, không
-- TRUNCATE, không REFERENCES. ph07_readonly: chỉ SELECT (vẫn chịu RLS).
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.catalog_group        TO ph07_app;
GRANT SELECT, INSERT, UPDATE         ON ph07_rdm.catalog              TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.catalog_version      TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.attribute_def        TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.catalog_item         TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.item_succession      TO ph07_app;
GRANT SELECT, INSERT                 ON ph07_rdm.version_review       TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.file_object          TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.import_job           TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.import_row           TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.sync_source          TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.sync_run             TO ph07_app;
GRANT SELECT, INSERT, DELETE         ON ph07_rdm.sync_change          TO ph07_app;
GRANT SELECT, INSERT, UPDATE         ON ph07_rdm.code_system          TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.code_mapping         TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.catalog_access_grant TO ph07_app;
GRANT SELECT, INSERT, DELETE         ON ph07_rdm.outbox               TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.idempotency_key      TO ph07_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.shedlock             TO ph07_app;
GRANT SELECT, INSERT, UPDATE         ON ph07_rdm.admin_unit           TO ph07_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph07_rdm TO ph07_readonly;
-- Phân vùng con của import_row: thu hồi để chỉ truy cập qua bảng cha (có RLS).
REVOKE ALL ON ph07_rdm.import_row_default FROM ph07_app, ph07_readonly;
GRANT EXECUTE ON FUNCTION ph07_rdm.f_unaccent_immutable(text), ph07_rdm.f_search_norm(text),
  ph07_rdm.f_uuid_v7(), ph07_rdm.f_recompute_hierarchy(uuid, uuid),
  ph07_rdm.f_refresh_admin_unit(uuid, uuid), ph07_rdm.f_import_row_maintain(integer, integer) TO ph07_app;
GRANT EXECUTE ON FUNCTION ph07_rdm.f_unaccent_immutable(text), ph07_rdm.f_search_norm(text) TO ph07_readonly;
-- PostgreSQL 17+: quyền MAINTAIN cho phép ứng dụng chạy ANALYZE sau lô nhập lớn.
DO $m$
BEGIN
  IF current_setting('server_version_num')::int >= 170000 THEN
    EXECUTE 'GRANT MAINTAIN ON ph07_rdm.catalog_item, ph07_rdm.import_row TO ph07_app';
  END IF;
END
$m$;

-- Hết DDL.
--rollback REVOKE ALL ON ALL TABLES IN SCHEMA ph07_rdm FROM ph07_app, ph07_readonly;
--rollback REVOKE ALL ON ALL FUNCTIONS IN SCHEMA ph07_rdm FROM ph07_app, ph07_readonly;
