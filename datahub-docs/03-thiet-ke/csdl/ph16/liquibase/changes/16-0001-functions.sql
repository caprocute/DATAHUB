--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_touch();

--changeset ph16:ph16-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, dữ kiện đã ghi.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_immutable();

--changeset ph16:ph16-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (quan sát, dòng truy nguồn, duyệt báo cáo, chữ ký, nhật ký nộp). Dọn bằng DETACH, DROP phân vùng dưới ph16_owner.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_append_only();

--changeset ph16:ph16-0013-fn-frozen splitStatements:false
-- Bất biến theo trạng thái: đối số 1 là tên cột trạng thái, đối số 2 là danh sách trạng thái (cách nhau dấu phẩy), các đối số sau là cột không được đổi khi dòng cũ ở các trạng thái đó.
CREATE OR REPLACE FUNCTION ph16_kpi.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
  st text := to_jsonb(OLD) ->> TG_ARGV[0];
  frozen text[] := string_to_array(TG_ARGV[1], ',');
  i integer;
BEGIN
  IF st = ANY (frozen) THEN
    FOR i IN 3 .. TG_NARGS LOOP
      c := TG_ARGV[i - 1];
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Bản ghi % ở trạng thái % không sửa được cột %', TG_TABLE_NAME, st, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_frozen() IS 'Phiên bản định nghĩa ACTIVE, báo cáo đã duyệt hoặc công bố, đánh giá đã xác nhận không đổi nội dung; thay đổi cần phiên bản mới.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_frozen();

--changeset ph16:ph16-0014-fn-child-frozen splitStatements:false
-- Dòng con chỉ ghi khi bản ghi cha ở trạng thái cho phép. Đối số: bảng cha, cột khóa tới cha, danh sách trạng thái được ghi.
CREATE OR REPLACE FUNCTION ph16_kpi.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
  tn text;
  pid uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; pid := (to_jsonb(OLD) ->> TG_ARGV[1])::uuid;
  ELSE
    tn := NEW.tenant_id; pid := (to_jsonb(NEW) ->> TG_ARGV[1])::uuid;
  END IF;
  EXECUTE format('SELECT state FROM ph16_kpi.%I WHERE tenant_id = $1 AND id = $2', TG_ARGV[0]) INTO st USING tn, pid;
  IF st IS NOT NULL AND NOT (st = ANY (string_to_array(TG_ARGV[2], ','))) THEN
    RAISE EXCEPTION 'Bản ghi cha % ở trạng thái %: không sửa dòng con %', TG_ARGV[0], st, TG_TABLE_NAME USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con (ngưỡng, biến, bằng chứng, mục đánh giá) khi bản ghi cha đã gửi duyệt hoặc chốt.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_child_frozen();

--changeset ph16:ph16-0015-fn-transition splitStatements:false
-- Máy trạng thái: đối số 1 là tên cột, đối số 2 là bản đồ JSON {trạng thái cũ: [trạng thái mới được phép]}.
CREATE OR REPLACE FUNCTION ph16_kpi.tg_transition() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  o text := to_jsonb(OLD) ->> TG_ARGV[0];
  n text := to_jsonb(NEW) ->> TG_ARGV[0];
BEGIN
  IF o IS DISTINCT FROM n AND NOT COALESCE((TG_ARGV[1]::jsonb -> o) @> to_jsonb(n), false) THEN
    RAISE EXCEPTION 'Bảng %: không chuyển % từ % sang %', TG_TABLE_NAME, TG_ARGV[0], o, n USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_transition() IS 'Chỉ cho chuyển trạng thái theo bản đồ khai báo ở tham số trigger (vòng đời ở FRS Phụ lục A).';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_transition();

--changeset ph16:ph16-0016-fn-no-delete-state splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.tg_no_delete_state() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF (to_jsonb(OLD) ->> TG_ARGV[0]) = ANY (string_to_array(TG_ARGV[1], ',')) THEN
    RAISE EXCEPTION 'Bản ghi % ở trạng thái % không xóa được', TG_TABLE_NAME, to_jsonb(OLD) ->> TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN OLD;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.tg_no_delete_state() IS 'Chặn xóa dòng đã công bố hoặc đã chốt, kể cả chủ schema.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.tg_no_delete_state();

--changeset ph16:ph16-0017-fn-setting splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_setting_bool(p_tenant text, p_code text, p_default boolean) RETURNS boolean
  LANGUAGE plpgsql STABLE AS $f$
DECLARE
  v boolean;
BEGIN
  SELECT (value #>> '{}')::boolean INTO v FROM ph16_kpi.kpi_tenant_setting WHERE tenant_id = p_tenant AND param_code = p_code;
  RETURN COALESCE(v, p_default);
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_setting_bool(text, text, boolean) IS 'Đọc tham số 16.* kiểu boolean của tenant, không có thì lấy mặc định; dùng trong trigger bốn mắt, bằng chứng, ký số, gửi quốc gia.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_setting_bool(text, text, boolean);

--changeset ph16:ph16-0018-fn-rls splitStatements:false
-- Mẫu P: chỉ thấy, ghi dòng của tenant phiên (dạng Tnn). Mẫu S: thêm quyền đọc dòng COMMON, ghi COMMON chỉ khi phiên là PLATFORM (cách PH-07, PH-08).
CREATE OR REPLACE PROCEDURE ph16_kpi.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003).';

CREATE OR REPLACE PROCEDURE ph16_kpi.p_enable_rls_shared(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  cur text := $c$current_setting('app.tenant_id', false)$c$;
  w text := format($w$((tenant_id = %s AND tenant_id ~ '^T[0-9]{2}$') OR (tenant_id = 'COMMON' AND %s = 'PLATFORM'))$w$, cur, cur);
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING (tenant_id IN (%s, ''COMMON''))', n, t, cur);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_enable_rls_shared(regclass) IS 'Mẫu RLS S cho bảng có dòng COMMON dùng chung (nhóm chỉ tiêu, chỉ tiêu mẫu, mẫu báo cáo, tiêu chí tuân thủ, mẫu gói quốc gia).';
--rollback DROP PROCEDURE IF EXISTS ph16_kpi.p_enable_rls_shared(regclass); DROP PROCEDURE IF EXISTS ph16_kpi.p_enable_rls(regclass);

--changeset ph16:ph16-0019-fn-partitions splitStatements:false
-- Phân vùng tháng. Cột phân vùng kiểu date: biên là ngày; kiểu timestamptz: biên 00:00 giờ Việt Nam (UTC+7, không có giờ mùa hè).
CREATE OR REPLACE PROCEDURE ph16_kpi.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d date := date_trunc('month', p_from)::date;
  i integer;
  part text;
  ctype text;
  lo text;
  hi text;
BEGIN
  SELECT format_type(a.atttypid, NULL) INTO ctype
    FROM pg_partitioned_table p JOIN pg_attribute a ON a.attrelid = p.partrelid AND a.attnum = p.partattrs[0]
   WHERE p.partrelid = p_table;
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    lo := to_char(d + interval '1 month' * i, 'YYYY-MM-DD') || CASE WHEN ctype = 'date' THEN '' ELSE ' 00:00:00+07' END;
    hi := to_char(d + interval '1 month' * (i + 1), 'YYYY-MM-DD') || CASE WHEN ctype = 'date' THEN '' ELSE ' 00:00:00+07' END;
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)', part, p_table, lo, hi);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho kpi_observation, kpi_ingest_log, kpi_indicator_value, kpi_value_lineage. PartitionMaintenanceJob (PH-18) gọi hằng ngày; dọn bằng DETACH, DROP dưới ph16_owner.';
--rollback DROP PROCEDURE IF EXISTS ph16_kpi.p_ensure_partitions(regclass, date, integer);
