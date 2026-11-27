--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph10_event.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
--rollback DROP FUNCTION IF EXISTS ph10_event.tg_touch();

--changeset ph10:ph10-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến (BR-10-003)', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph10_event.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, tên topic, khóa tham chiếu (BR-10-003).';
--rollback DROP FUNCTION IF EXISTS ph10_event.tg_immutable();

--changeset ph10:ph10-0012-fn-rls splitStatements:false
-- Hai mẫu như PH-04, PH-05: 'P' riêng tenant (dòng COMMON chỉ phiên PLATFORM đọc, ghi);
-- 'S' dùng chung (tenant đọc thêm dòng COMMON, chỉ phiên PLATFORM ghi COMMON).
CREATE OR REPLACE PROCEDURE ph10_event.p_enable_rls(p_table regclass, p_mode char)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
            OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))$w$;
  r text;
BEGIN
  IF p_mode NOT IN ('P', 'S') THEN RAISE EXCEPTION 'p_mode phải là P hoặc S'; END IF;
  r := CASE p_mode WHEN 'S' THEN $r$(tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'))$r$ ELSE w END;
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph10_event.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10 §4).';
--rollback DROP PROCEDURE IF EXISTS ph10_event.p_enable_rls(regclass, char);

--changeset ph10:ph10-0013-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph10_event.p_ensure_partitions(p_table regclass, p_from date, p_count integer, p_unit text)
  LANGUAGE plpgsql AS $p$
DECLARE
  step interval := CASE p_unit WHEN 'day' THEN interval '1 day' WHEN 'month' THEN interval '1 month' END;
  d timestamptz := date_trunc(p_unit, p_from::timestamptz);
  i integer;
  part text;
BEGIN
  IF step IS NULL THEN RAISE EXCEPTION 'p_unit phải là day hoặc month'; END IF;
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text,
                   to_char(d + step * i, CASE p_unit WHEN 'day' THEN 'YYYYMMDD' ELSE 'YYYYMM' END));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + step * i, d + step * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph10_event.p_ensure_partitions(regclass, date, integer, text) IS 'Tạo trước phân vùng ngày (lag_sample) hoặc tháng (delivery_stat, delivery_failure, lag_sample_5m). PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph10_owner.';
--rollback DROP PROCEDURE IF EXISTS ph10_event.p_ensure_partitions(regclass, date, integer, text);

--changeset ph10:ph10-0014-fn-helpers splitStatements:false
CREATE OR REPLACE FUNCTION ph10_event.f_topic_prefix(p_tenant text) RETURNS text
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE WHEN p_tenant = 'COMMON' THEN 'dh' ELSE lower(p_tenant) END
$f$;
COMMENT ON FUNCTION ph10_event.f_topic_prefix(text) IS 'Tiền tố topic của tenant: t68 cho T68, dh cho COMMON (topic nền tảng, FR-10-067); topic cấp nền tảng của COMMON còn được dùng tiền tố platform theo D00-04 §4, kiểm ở ck_topic_prefix.';
--rollback DROP FUNCTION IF EXISTS ph10_event.f_topic_prefix(text);
