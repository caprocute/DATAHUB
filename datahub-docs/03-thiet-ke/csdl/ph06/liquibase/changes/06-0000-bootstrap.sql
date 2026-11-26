--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_owner') THEN
    CREATE ROLE ph06_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_app') THEN
    CREATE ROLE ph06_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_readonly') THEN
    CREATE ROLE ph06_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_splink') THEN
    CREATE ROLE ph06_splink NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph06:ph06-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE SCHEMA IF NOT EXISTS ph06_mdm AUTHORIZATION ph06_owner;
COMMENT ON SCHEMA ph06_mdm IS 'PH-06 Dữ liệu chủ (dh-data, package vn.datahub.data.mdm): domain, nguồn, ứng viên, đối sánh, hàng đợi, bản ghi vàng, liên kết chéo, lịch sử, nguồn gốc, đồng bộ quốc gia, yêu cầu chủ thể, nhật ký truy cập. Số định danh và giá trị SENSITIVE chỉ ở dạng mã hóa envelope và HMAC.';
GRANT USAGE ON SCHEMA ph06_mdm TO ph06_app, ph06_readonly, ph06_splink;
--rollback DROP SCHEMA IF EXISTS ph06_mdm CASCADE;

--changeset ph06:ph06-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
