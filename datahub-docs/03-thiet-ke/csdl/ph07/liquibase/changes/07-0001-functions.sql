--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0010-fn-unaccent splitStatements:false
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
--rollback DROP FUNCTION IF EXISTS ph07_rdm.f_unaccent_immutable(text);

--changeset ph07:ph07-0011-fn-search-norm splitStatements:false
CREATE OR REPLACE FUNCTION ph07_rdm.f_search_norm(p_text text)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT lower(regexp_replace(ph07_rdm.f_unaccent_immutable(normalize(p_text, NFC)), '\s+', ' ', 'g'));
END;
COMMENT ON FUNCTION ph07_rdm.f_search_norm(text) IS 'Chuẩn hóa chuỗi tìm kiếm: NFC, bỏ dấu, chữ thường, gộp khoảng trắng. Ứng dụng gọi cùng hàm này cho chuỗi người dùng nhập để so khớp với name_search.';
--rollback DROP FUNCTION IF EXISTS ph07_rdm.f_search_norm(text);

--changeset ph07:ph07-0012-fn-uuid-v7 splitStatements:false
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
--rollback DROP FUNCTION IF EXISTS ph07_rdm.f_uuid_v7();

--changeset ph07:ph07-0013-fn-touch splitStatements:false
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

-- =============================================================================
-- MẪU CHÍNH SÁCH RLS (tài liệu §6)
--   Mẫu S (SHARED, bảng có thể chứa COMMON và mọi tenant được đọc COMMON):
--     SELECT : tenant_id IN (current_setting('app.tenant_id', false), 'COMMON')
--     GHI    : (tenant_id = cur AND tenant_id ~ '^T[0-9]{2}$')
--              OR (tenant_id = 'COMMON' AND cur = 'PLATFORM')
--   Mẫu P (PRIVATE, dữ liệu tác nghiệp; COMMON chỉ PLATFORM thấy):
--     SELECT = GHI = biểu thức GHI ở trên.
--   cur = current_setting('app.tenant_id', false): quên đặt biến phiên thì lỗi.
-- =============================================================================
--rollback DROP FUNCTION IF EXISTS ph07_rdm.tg_touch();
