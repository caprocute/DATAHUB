--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph10_owner') THEN
    CREATE ROLE ph10_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph10_app') THEN
    CREATE ROLE ph10_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph10_readonly') THEN
    CREATE ROLE ph10_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph10:ph10-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph10_event AUTHORIZATION ph10_owner;
COMMENT ON SCHEMA ph10_event IS 'PH-10 Sự kiện (control plane trong dh-integration, package vn.datahub.integration.event): dự án, topic, lược đồ, bên phát, bên nhận, publication, subscription, khóa ký, duyệt, DLQ, phát lại, lag, danh mục, hạn mức, di trú Pulsar. Không có giá trị bí mật.';
GRANT USAGE ON SCHEMA ph10_event TO ph10_app, ph10_readonly;
--rollback DROP SCHEMA IF EXISTS ph10_event CASCADE;

--changeset ph10:ph10-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
