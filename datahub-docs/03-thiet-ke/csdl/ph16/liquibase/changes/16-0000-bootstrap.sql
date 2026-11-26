--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph16_owner') THEN
    CREATE ROLE ph16_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph16_app') THEN
    CREATE ROLE ph16_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph16_readonly') THEN
    CREATE ROLE ph16_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph16_compare') THEN
    CREATE ROLE ph16_compare NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph16:ph16-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph16_kpi AUTHORIZATION ph16_owner;
COMMENT ON SCHEMA ph16_kpi IS 'PH-16 Báo cáo chỉ tiêu và sổ kiến trúc (dh-platform, package vn.datahub.platform.kpi và vn.datahub.platform.arch): nhóm chỉ tiêu, định nghĩa có phiên bản, nguồn số liệu, quan sát, số liệu nhập tay, kỳ, lần tổng hợp, giá trị chỉ tiêu, báo cáo bất biến khi công bố, sổ kiến trúc, đánh giá tuân thủ, gói gửi quốc gia. Không lưu dữ liệu thô của phân hệ nguồn.';
GRANT USAGE ON SCHEMA ph16_kpi TO ph16_app, ph16_readonly, ph16_compare;
COMMENT ON ROLE ph16_compare IS 'Vai so sánh liên tenant ẩn danh (FR-16-041): đọc giá trị chỉ tiêu hiện hành qua khung nhìn v_compare_value, là ngoại lệ RLS duy nhất của PH-16; không đọc bảng khác.';
--rollback DROP SCHEMA IF EXISTS ph16_kpi CASCADE;

--changeset ph16:ph16-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
