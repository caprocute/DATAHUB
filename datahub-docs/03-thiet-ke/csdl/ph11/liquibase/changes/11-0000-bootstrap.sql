--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_owner') THEN
    CREATE ROLE ph11_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_app') THEN
    CREATE ROLE ph11_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_readonly') THEN
    CREATE ROLE ph11_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph11_engine') THEN
    CREATE ROLE ph11_engine NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph11:ph11-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph11_bpm AUTHORIZATION ph11_owner;
COMMENT ON SCHEMA ph11_bpm IS 'PH-11 Quy trình liên thông (dh-platform, package vn.datahub.platform.bpm): mô hình và phiên bản BPMN, chạy thử, biểu mẫu, ý định nghiệp vụ, bù trừ, bản chiếu phiên và việc, can thiệp phiên, ủy quyền, lịch làm việc, hạn, Saga, sự cố, outbox, inbox. Engine Flowable nằm ở schema ph11_flowable.';
GRANT USAGE ON SCHEMA ph11_bpm TO ph11_app, ph11_readonly;
-- Schema engine: Flowable tự tạo bảng ACT_*, FLW_* khi khởi động (databaseSchemaUpdate), nên chỉ tạo vỏ và cấp quyền cho ph11_engine.
CREATE SCHEMA IF NOT EXISTS ph11_flowable AUTHORIZATION ph11_engine;
COMMENT ON SCHEMA ph11_flowable IS 'Bảng engine Flowable 7.x (ACT_*, FLW_*), do Flowable tự tạo bằng tài khoản ph11_engine; không RLS, cô lập bằng tenantId của Flowable; chỉ dịch vụ PH-11 truy cập; history level audit; dọn lịch sử theo chính sách lưu giữ (ADR 110).';
--rollback DROP SCHEMA IF EXISTS ph11_bpm CASCADE;

--changeset ph11:ph11-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
