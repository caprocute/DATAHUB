--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0000-bootstrap.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_owner') THEN
    CREATE ROLE ph08_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_app') THEN
    CREATE ROLE ph08_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_readonly') THEN
    CREATE ROLE ph08_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph08_benchmark') THEN
    CREATE ROLE ph08_benchmark NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dq_reader') THEN
    CREATE ROLE dq_reader NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
--rollback empty

--changeset ph08:ph08-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph08_dq AUTHORIZATION ph08_owner;
COMMENT ON SCHEMA ph08_dq IS 'PH-08 Chất lượng dữ liệu (dh-data, package vn.datahub.data.dq): miền, đối tượng đo, hồ sơ dữ liệu, bộ quy tắc có phiên bản, lần đo, kết quả, điểm, bản ghi lỗi có dấu vân tay, ngoại lệ, phiếu khắc phục, cảnh báo, báo cáo. Không lưu giá trị gốc trường Nhạy cảm.';
GRANT USAGE ON SCHEMA ph08_dq TO ph08_app, ph08_readonly, ph08_benchmark;
COMMENT ON ROLE dq_reader IS 'Vai chỉ đọc cho bộ thực thi đo (dq-worker): PH-06 cấp SELECT trên khung nhìn hợp đồng ph06_mdm.v_dq_{domain}; không có quyền gì trên ph08_dq và không đọc CSDL control (ADR đề xuất 087).';
COMMENT ON ROLE ph08_benchmark IS 'Vai so sánh liên tenant ẩn danh (FR-08-061): đọc điểm chiều của ảnh chụp chính thức qua khung nhìn v_benchmark_dimension, là ngoại lệ RLS duy nhất của PH-08; không đọc bảng khác.';
--rollback DROP SCHEMA IF EXISTS ph08_dq CASCADE;

--changeset ph08:ph08-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
--rollback empty
