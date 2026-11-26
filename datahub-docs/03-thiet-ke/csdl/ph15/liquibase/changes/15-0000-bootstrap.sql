--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph15_owner') THEN
    CREATE ROLE ph15_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph15_app') THEN
    CREATE ROLE ph15_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph15_readonly') THEN
    CREATE ROLE ph15_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph15:ph15-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph15_portal AUTHORIZATION ph15_owner;
COMMENT ON SCHEMA ph15_portal IS 'PH-15 Cổng nhà phát triển: bản sao danh mục, đặc tả, nội dung, tài khoản và ứng dụng sandbox, lượt thử, hỗ trợ, cấu hình cổng, di trú. Chủ ph15_owner; module portal của dh-connect kết nối bằng dh_portal_app (thành viên ph15_app, không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph15_portal TO ph15_app, ph15_readonly;
--rollback DROP SCHEMA IF EXISTS ph15_portal CASCADE;

--changeset ph15:ph15-0002-unaccent context:bootstrap
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA ph15_portal;

-- Phiên migration: tạo đối tượng dưới ph15_owner; app.tenant_id đặt giá trị giữ chỗ vì FORCE RLS áp cả cho chủ bảng
-- khi ALTER TABLE ... ADD CONSTRAINT quét bảng. Chạy lại mỗi lần (runAlways), cùng kết nối với các changeset sau.
--rollback DROP EXTENSION IF EXISTS unaccent;

--changeset ph15:ph15-0003-session runAlways:true context:bootstrap
SET ROLE ph15_owner;
SET app.tenant_id = 'PLATFORM';
--rollback RESET ROLE;
