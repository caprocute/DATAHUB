--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_owner') THEN
    CREATE ROLE ph09_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_app') THEN
    CREATE ROLE ph09_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_readonly') THEN
    CREATE ROLE ph09_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_decide') THEN
    CREATE ROLE ph09_decide NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph09:ph09-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph09_privacy AUTHORIZATION ph09_owner;
COMMENT ON SCHEMA ph09_privacy IS 'PH-09 Quyền riêng tư (dh-data, package vn.datahub.data.privacy): phân loại dữ liệu, sổ hoạt động xử lý, mục đích và chấp thuận, chính sách che, giả danh hóa và ẩn danh hóa, lưu giữ, quyền chủ thể, đồng ý, DPIA, vi phạm DLCN. Không lưu giá trị DLCN rõ, không bảng ánh xạ bí danh.';
GRANT USAGE ON SCHEMA ph09_privacy TO ph09_app, ph09_readonly, ph09_decide;
--rollback DROP SCHEMA IF EXISTS ph09_privacy CASCADE;

--changeset ph09:ph09-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
