--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph08_dq.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
--rollback DROP FUNCTION IF EXISTS ph08_dq.tg_touch();

--changeset ph08:ph08-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph08_dq.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph08_dq.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, kết quả đã chốt.';
--rollback DROP FUNCTION IF EXISTS ph08_dq.tg_immutable();

--changeset ph08:ph08-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph08_dq.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (dq_rule_result, dq_issue_activity). Dọn bằng DETACH, DROP phân vùng dưới ph08_owner.';
--rollback DROP FUNCTION IF EXISTS ph08_dq.tg_append_only();

--changeset ph08:ph08-0013-fn-frozen splitStatements:false
-- Bất biến theo trạng thái: đối số đầu là danh sách trạng thái (cách nhau dấu phẩy), các đối số sau là cột không được đổi khi dòng cũ ở các trạng thái đó.
CREATE OR REPLACE FUNCTION ph08_dq.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
  frozen text[] := string_to_array(TG_ARGV[0], ',');
  i integer;
BEGIN
  IF OLD.status = ANY (frozen) THEN
    FOR i IN 2 .. TG_NARGS LOOP
      c := TG_ARGV[i - 1];
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Bản ghi % ở trạng thái % không sửa được cột %', TG_TABLE_NAME, OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_frozen() IS 'Phiên bản bộ quy tắc, cấu hình trọng số đã ACTIVE hoặc SUPERSEDED, báo cáo đã công bố không đổi nội dung; thay đổi cần phiên bản mới.';
--rollback DROP FUNCTION IF EXISTS ph08_dq.tg_frozen();

--changeset ph08:ph08-0014-fn-child-frozen splitStatements:false
-- Quy tắc con (dq_rule) chỉ ghi khi phiên bản cha là DRAFT.
CREATE OR REPLACE FUNCTION ph08_dq.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
  tn text;
  vid uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; vid := OLD.rule_set_version_id;
  ELSE
    tn := NEW.tenant_id; vid := NEW.rule_set_version_id;
  END IF;
  SELECT status INTO st FROM ph08_dq.dq_rule_set_version WHERE tenant_id = tn AND id = vid;
  IF st IS NOT NULL AND st <> 'DRAFT' THEN
    RAISE EXCEPTION 'Phiên bản bộ quy tắc ở trạng thái %: không sửa quy tắc con (cần phiên bản mới)', st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph08_dq.tg_child_frozen() IS 'Chặn thêm, sửa, xóa quy tắc khi phiên bản cha không phải DRAFT (FR-08-012, 017, 018).';
--rollback DROP FUNCTION IF EXISTS ph08_dq.tg_child_frozen();

--changeset ph08:ph08-0015-fn-rls splitStatements:false
-- Mẫu P: chỉ thấy, ghi dòng của tenant phiên (dạng Tnn). Mẫu S: thêm quyền đọc dòng COMMON, ghi COMMON chỉ khi phiên là PLATFORM (cách PH-07).
CREATE OR REPLACE PROCEDURE ph08_dq.p_enable_rls(p_table regclass)
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
COMMENT ON PROCEDURE ph08_dq.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003).';

CREATE OR REPLACE PROCEDURE ph08_dq.p_enable_rls_shared(p_table regclass)
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
COMMENT ON PROCEDURE ph08_dq.p_enable_rls_shared(regclass) IS 'Mẫu RLS S cho bảng có dòng COMMON dùng chung (dq_rule_template).';
--rollback DROP PROCEDURE IF EXISTS ph08_dq.p_enable_rls_shared(regclass); DROP PROCEDURE IF EXISTS ph08_dq.p_enable_rls(regclass);

--changeset ph08:ph08-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph08_dq.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph08_dq.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho dq_finding, dq_rule_result, dq_inline_stat. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph08_owner.';
--rollback DROP PROCEDURE IF EXISTS ph08_dq.p_ensure_partitions(regclass, date, integer);
