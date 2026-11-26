--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_owner') THEN
    CREATE ROLE ph17_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_app') THEN
    CREATE ROLE ph17_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_platform') THEN
    CREATE ROLE ph17_platform NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_infer') THEN
    CREATE ROLE ph17_infer NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_job') THEN
    CREATE ROLE ph17_job NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph17_readonly') THEN
    CREATE ROLE ph17_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  GRANT ph17_app TO ph17_job;
END
$roles$;
--rollback empty

--changeset ph17:ph17-0001-schema splitStatements:false context:bootstrap
-- pgvector có điều kiện: CI (postgres:16) không có extension; môi trường thật có (ADR-170, pgvector 0.8).
DO $ext$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'vector') THEN
    CREATE EXTENSION IF NOT EXISTS vector;
  ELSE
    RAISE NOTICE 'Không có pgvector: cột embedding giữ real[] (chỉ để CI).';
  END IF;
END
$ext$;
CREATE SCHEMA IF NOT EXISTS ph17_assist AUTHORIZATION ph17_owner;
COMMENT ON SCHEMA ph17_assist IS 'PH-17 Trợ lý AI và quản trị AI (dh-assist, package vn.datahub.assist): chính sách bật tắt theo tenant, sổ mô hình, cổng mô hình, kho tri thức và chỉ mục vector, hội thoại đã che, công cụ chỉ đọc, bộ lọc, đánh giá và ca đỏ, nhật ký, bằng chứng tuân thủ. Không lưu bí mật nhà cung cấp, không lưu nội dung chưa che.';
GRANT USAGE ON SCHEMA ph17_assist TO ph17_app, ph17_platform, ph17_infer, ph17_job, ph17_readonly;
--rollback DROP SCHEMA IF EXISTS ph17_assist CASCADE;

--changeset ph17:ph17-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
