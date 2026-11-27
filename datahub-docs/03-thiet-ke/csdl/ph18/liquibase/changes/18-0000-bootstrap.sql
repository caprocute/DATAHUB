--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_owner') THEN
    CREATE ROLE ph18_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_app') THEN
    CREATE ROLE ph18_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_readonly') THEN
    CREATE ROLE ph18_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_worker') THEN
    CREATE ROLE ph18_worker NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph18:ph18-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph18_ops AUTHORIZATION ph18_owner;
COMMENT ON SCHEMA ph18_ops IS 'PH-18 Vận hành và xử lý lỗi (dh-platform, package vn.datahub.platform.ops): kho tham số và cờ tính năng, DLQ hợp nhất và phát lại, thông báo, Việc của tôi, lịch làm việc và cửa sổ bảo trì, sự cố vận hành, sao lưu và khôi phục tenant, sáp nhập, di trú hệ cũ và chạy song song, báo cáo vận hành. Không lưu bí mật.';
REVOKE ALL ON SCHEMA ph18_ops FROM PUBLIC;
GRANT USAGE ON SCHEMA ph18_ops TO ph18_app, ph18_readonly, ph18_worker;
--rollback DROP SCHEMA IF EXISTS ph18_ops CASCADE;

--changeset ph18:ph18-0002-session-tenant runAlways:true
SET app.tenant_id = 'COMMON';
--rollback empty
