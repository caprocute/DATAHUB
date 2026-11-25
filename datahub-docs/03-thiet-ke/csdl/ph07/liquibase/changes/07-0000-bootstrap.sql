--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0000-roles splitStatements:false context:bootstrap
-- Vai trò nhóm (NOLOGIN). Tài khoản đăng nhập thật (dh_data_app,
-- dh_data_migrator, dh_report) là thành viên của các vai trò này và do
-- CloudNativePG quản lý mật khẩu qua OpenBao; không đặt mật khẩu ở đây.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_owner') THEN
    CREATE ROLE ph07_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_app') THEN
    CREATE ROLE ph07_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_readonly') THEN
    CREATE ROLE ph07_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  -- ph07_worker: chỉ dùng bằng SET LOCAL ROLE trong giao dịch ngắn để nhận
  -- tác vụ nền liên tenant (D03-02-PH07 §4.7.3, §6.3); không có quyền đọc dữ liệu nghiệp vụ.
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph07_worker') THEN
    CREATE ROLE ph07_worker NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph07:ph07-0001-extensions context:bootstrap
-- unaccent, pg_trgm, btree_gist là extension "trusted" từ PostgreSQL 13:
-- chủ CSDL có quyền CREATE tạo được mà không cần superuser.
CREATE EXTENSION IF NOT EXISTS unaccent   WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm    WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;
--rollback empty

--changeset ph07:ph07-0002-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph07_rdm AUTHORIZATION ph07_owner;
COMMENT ON SCHEMA ph07_rdm IS 'PH-07 Danh mục dùng chung (RDM): danh mục có phiên bản, thuộc tính động, ĐVHC, ánh xạ mã, đồng bộ quốc gia. Chủ sở hữu ph07_owner; ứng dụng kết nối bằng ph07_app (không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph07_rdm TO ph07_app, ph07_readonly;

-- Từ đây mọi đối tượng do ph07_owner sở hữu (khi chạy độc lập bằng superuser).
-- Liquibase kết nối bằng dh_data_migrator (thành viên ph07_owner) và đặt
-- defaultSchemaName=ph07_rdm; dòng SET ROLE dưới đây chỉ dùng khi chạy psql.
--rollback DROP SCHEMA IF EXISTS ph07_rdm CASCADE;

--changeset ph07:ph07-0003-session-tenant runAlways:true
-- Phiên migration cũng chịu FORCE RLS: kiểm tra khóa ngoại khi ALTER TABLE và
-- dữ liệu nền COMMON cần biến app.tenant_id. Đặt PLATFORM cho phiên Liquibase.
SET app.tenant_id = 'PLATFORM';
--rollback empty
