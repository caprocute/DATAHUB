--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_owner') THEN
    CREATE ROLE ph20_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_app') THEN
    CREATE ROLE ph20_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_platform_app') THEN
    CREATE ROLE ph20_platform_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph20_ro') THEN
    CREATE ROLE ph20_ro NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph20:ph20-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph20_tenant AUTHORIZATION ph20_owner;
COMMENT ON SCHEMA ph20_tenant IS 'PH-20 Quản trị tenant và phát hành sản phẩm (dh-platform, package vn.datahub.platform.tenant và vn.datahub.platform.release): hồ sơ tenant, tổ chức, saga khởi tạo, cấu hình, hạn mức và sử dụng, phân hệ, vòng đời, sáp nhập, phát hành và nâng cấp. Không lưu bí mật hay khóa: chỉ tham chiếu đường dẫn.';
GRANT USAGE ON SCHEMA ph20_tenant TO ph20_app, ph20_platform_app, ph20_ro;
COMMENT ON ROLE ph20_app IS 'Vai kết nối của nhóm API /api/tenant/v1 và các luồng theo tenant: chỉ DML trên bảng theo tenant, không BYPASSRLS, không là chủ bảng.';
COMMENT ON ROLE ph20_platform_app IS 'Vai kết nối riêng của nhóm /api/platform/v1, /internal/tenant/v1 và saga (FR-00-012): đọc, ghi liên tenant khi phiên đặt app.tenant_id = PLATFORM; không BYPASSRLS, không là chủ bảng.';
COMMENT ON ROLE ph20_ro IS 'Vai chỉ đọc cho kiểm toán nền tảng, báo cáo, BI: chỉ SELECT, vẫn chịu RLS (đọc liên tenant khi phiên là PLATFORM).';
--rollback DROP SCHEMA IF EXISTS ph20_tenant CASCADE;

--changeset ph20:ph20-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
