--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0010-domain
CREATE DOMAIN ph15_portal.t_tenant AS varchar(16) CHECK (VALUE ~ '^T[0-9]{2}$');
COMMENT ON DOMAIN ph15_portal.t_tenant IS 'T-TENANT (D00-01): mã tenant dạng T{nn}, ví dụ T68.';
--rollback DROP DOMAIN IF EXISTS ph15_portal.t_tenant;

--changeset ph15:ph15-0011-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_touch() IS 'Cập nhật updated_at và tăng version (ETag, If-Match; BR-15-034) khi ứng dụng không tự tăng.';
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_touch();

--changeset ph15:ph15-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % là chỉ-ghi-thêm: không được %', TG_TABLE_NAME, TG_OP USING ERRCODE = 'P1500';
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_append_only() IS 'Chặn UPDATE, DELETE trên bảng bất biến (bằng chứng chấp nhận điều khoản, tin nhắn hỗ trợ).';
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_append_only();

--changeset ph15:ph15-0013-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_immutable_cols() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF to_jsonb(NEW)->c IS DISTINCT FROM to_jsonb(OLD)->c THEN
      RAISE EXCEPTION 'Cột %.% bất biến (BR-15-007)', TG_TABLE_NAME, c USING ERRCODE = 'P1501';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph15_portal.tg_immutable_cols() IS 'Chặn sửa các cột mã định danh bất biến (appCode, pageCode, teamCode, ticketCode, apiCode); tên cột truyền qua TG_ARGV.';
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_immutable_cols();

--changeset ph15:ph15-0014-fn-rls splitStatements:false
CREATE OR REPLACE PROCEDURE ph15_portal.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false))$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_all ON %s FOR ALL USING %s WITH CHECK %s', n, t, w, w);
END
$p$;
COMMENT ON PROCEDURE ph15_portal.p_enable_rls(regclass) IS 'Bật FORCE RLS và một chính sách FOR ALL theo tenant (mẫu P của D03-10, ADR-003). PH-15 không có dữ liệu COMMON.';
--rollback DROP PROCEDURE IF EXISTS ph15_portal.p_enable_rls(regclass);

--changeset ph15:ph15-0015-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph15_portal.p_ensure_month_partitions(p_table regclass, p_from date, p_months integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_months - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + make_interval(months => i), 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, (d + make_interval(months => i))::timestamptz,
                     (d + make_interval(months => i + 1))::timestamptz);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph15_portal.p_ensure_month_partitions(regclass, date, integer) IS 'Tạo phân vùng tháng (ADR-047). PartitionMaintenanceJob gọi hằng ngày để luôn có 3 tháng tới.';
--rollback DROP PROCEDURE IF EXISTS ph15_portal.p_ensure_month_partitions(regclass, date, integer);

--changeset ph15:ph15-0016-fn-unaccent splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.f_unaccent(p_text text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS
$f$ SELECT ph15_portal.unaccent('ph15_portal.unaccent'::regdictionary, p_text) $f$;
COMMENT ON FUNCTION ph15_portal.f_unaccent(text) IS 'Bỏ dấu tiếng Việt, đánh dấu IMMUTABLE để dùng được trong trigger tsvector và chỉ mục (dự phòng PG FTS, tham số 15.search.engine).';
--rollback DROP FUNCTION IF EXISTS ph15_portal.f_unaccent(text);
