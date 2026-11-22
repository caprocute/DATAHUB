-- =============================================================================
-- D03-03-PH07 · DDL schema ph07_rdm — PH-07 Danh mục dùng chung (RDM)
-- Phiên bản 0.1 · 2026-11-21 · Dự thảo · Nhóm phân hệ PH-07
--
-- Mục đích: tạo đầy đủ schema ph07_rdm trên một CSDL PostgreSQL trống
-- (đích PostgreSQL 18; tương thích ngược tới PostgreSQL 16 nhờ các khối DO
-- có điều kiện theo server_version_num).
--
-- Cách chạy độc lập (môi trường phát triển):
--   psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph07_rdm.sql
-- Người chạy phải là superuser hoặc chủ CSDL có CREATEROLE. Ở môi trường
-- thật, vai trò do CloudNativePG (managed roles) tạo trước và phần còn lại
-- chạy qua Liquibase (xem liquibase/db.changelog-ph07.yaml).
--
-- Tệp này là NGUỒN DUY NHẤT: các changeset Liquibase trong liquibase/changes/
-- được sinh tự động từ các dấu "-- @changeset" / "-- @rollback" / "-- @file"
-- dưới đây. Không sửa tay tệp changeset; sửa tệp này rồi sinh lại.
--
-- Quy ước dấu:
--   -- @file <tên>.sql                     : bắt đầu một tệp changeset mới
--   -- @changeset <id> [splitStatements:false] [context:<ctx>]
--   -- @rollback <câu lệnh SQL>              : có thể lặp nhiều dòng
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 07-0000-bootstrap.sql
-- @changeset ph07-0000-roles splitStatements:false context:bootstrap
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
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback: vai trò có thể đang được schema khác hoặc tài khoản đăng nhập dùng.

-- @changeset ph07-0001-extensions context:bootstrap
-- unaccent, pg_trgm, btree_gist là extension "trusted" từ PostgreSQL 13:
-- chủ CSDL có quyền CREATE tạo được mà không cần superuser.
CREATE EXTENSION IF NOT EXISTS unaccent   WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm    WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;
-- @rollback -- Không gỡ extension: có thể đang được schema khác dùng.

-- @changeset ph07-0002-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph07_rdm AUTHORIZATION ph07_owner;
COMMENT ON SCHEMA ph07_rdm IS 'PH-07 Danh mục dùng chung (RDM): danh mục có phiên bản, thuộc tính động, ĐVHC, ánh xạ mã, đồng bộ quốc gia. Chủ sở hữu ph07_owner; ứng dụng kết nối bằng ph07_app (không BYPASSRLS).';
GRANT USAGE ON SCHEMA ph07_rdm TO ph07_app, ph07_readonly;
-- @rollback DROP SCHEMA IF EXISTS ph07_rdm CASCADE;

-- Từ đây mọi đối tượng do ph07_owner sở hữu (khi chạy độc lập bằng superuser).
-- Liquibase kết nối bằng dh_data_migrator (thành viên ph07_owner) và đặt
-- defaultSchemaName=ph07_rdm; dòng SET ROLE dưới đây chỉ dùng khi chạy psql.
SET ROLE ph07_owner;

-- @file 07-0001-functions.sql
-- @changeset ph07-0010-fn-unaccent splitStatements:false
-- Hàm bỏ dấu bất biến. unaccent() gốc chỉ STABLE (phụ thuộc search_path để
-- tìm từ điển) nên không dùng được trong cột sinh và index biểu thức. Ta cố
-- định từ điển public.unaccent và khai báo IMMUTABLE. Thân BEGIN ATOMIC
-- (PostgreSQL 14+) được phân giải lúc tạo hàm, không phụ thuộc search_path
-- lúc chạy. Nếu sửa tệp unaccent.rules thì phải REINDEX và cập nhật lại cột
-- name_search (xem tài liệu §5.3).
CREATE OR REPLACE FUNCTION ph07_rdm.f_unaccent_immutable(p_text text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT public.unaccent('public.unaccent'::regdictionary, p_text);
END;
COMMENT ON FUNCTION ph07_rdm.f_unaccent_immutable(text) IS 'Bỏ dấu tiếng Việt (kể cả đ/Đ) với từ điển cố định public.unaccent; IMMUTABLE để dùng cho cột sinh name_search và index biểu thức.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.f_unaccent_immutable(text);

-- @changeset ph07-0011-fn-search-norm splitStatements:false
CREATE OR REPLACE FUNCTION ph07_rdm.f_search_norm(p_text text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT lower(regexp_replace(ph07_rdm.f_unaccent_immutable(normalize(p_text, NFC)), '\s+', ' ', 'g'));
END;
COMMENT ON FUNCTION ph07_rdm.f_search_norm(text) IS 'Chuẩn hóa chuỗi tìm kiếm: NFC, bỏ dấu, chữ thường, gộp khoảng trắng. Ứng dụng gọi cùng hàm này cho chuỗi người dùng nhập để so khớp với name_search.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.f_search_norm(text);

-- @changeset ph07-0012-fn-uuid-v7 splitStatements:false
-- UUID v7 sinh ở ứng dụng là quy tắc chung (D00-01 §5). Ngoại lệ có chủ đích:
-- thao tác sao chép hàng loạt bằng INSERT … SELECT (tạo bản nháp copy-on-write)
-- cần sinh khóa trong CSDL. PostgreSQL 18 có sẵn uuidv7(); bản 16/17 dùng
-- hàm thay thế cùng định dạng RFC 9562.
DO $uuid$
BEGIN
  IF current_setting('server_version_num')::int >= 180000 THEN
    EXECUTE $f$
      CREATE OR REPLACE FUNCTION ph07_rdm.f_uuid_v7() RETURNS uuid
        LANGUAGE sql VOLATILE PARALLEL SAFE
        AS 'SELECT uuidv7()'
    $f$;
  ELSE
    EXECUTE $f$
      CREATE OR REPLACE FUNCTION ph07_rdm.f_uuid_v7() RETURNS uuid
        LANGUAGE sql VOLATILE PARALLEL SAFE
        AS $b$
          SELECT encode(
                   set_bit(set_bit(
                     overlay(uuid_send(gen_random_uuid())
                             PLACING substring(int8send((extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3)
                             FROM 1 FOR 6),
                   52, 1), 53, 1),
                 'hex')::uuid
        $b$
    $f$;
  END IF;
END
$uuid$;
COMMENT ON FUNCTION ph07_rdm.f_uuid_v7() IS 'UUID phiên bản 7 sinh trong CSDL; chỉ dùng cho sao chép hàng loạt (copy-on-write, di trú). Đường ghi thông thường sinh UUID v7 ở ứng dụng.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.f_uuid_v7();

-- @changeset ph07-0013-fn-touch splitStatements:false
-- Trigger chung: cập nhật updated_at và tăng version (khóa lạc quan) khi
-- ứng dụng quên. Ứng dụng (JPA @Version) vẫn là nơi so sánh version.
CREATE OR REPLACE FUNCTION ph07_rdm.tg_touch()
  RETURNS trigger
  LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$$;
COMMENT ON FUNCTION ph07_rdm.tg_touch() IS 'BEFORE UPDATE: đặt updated_at = now() và tăng version nếu ứng dụng chưa tăng.';
-- @rollback DROP FUNCTION IF EXISTS ph07_rdm.tg_touch();
