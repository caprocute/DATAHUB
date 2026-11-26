--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph11_bpm.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
--rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_touch();

--changeset ph11:ph11-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph11_bpm.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph11_bpm.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, mốc thời gian đã chốt.';
--rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_immutable();

--changeset ph11:ph11-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph11_bpm.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (task_comment).';
--rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_append_only();

--changeset ph11:ph11-0013-fn-frozen splitStatements:false
-- Nội dung phiên bản bất biến khi không còn là bản nháp. Tham số đầu: danh sách trạng thái đóng băng, cách nhau dấu phẩy;
-- các tham số sau: cột nội dung. Chuyển trạng thái (ví dụ từ chối về DRAFT) không đổi nội dung nên được phép.
CREATE OR REPLACE FUNCTION ph11_bpm.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  i integer;
  c text;
BEGIN
  IF OLD.status = ANY (string_to_array(TG_ARGV[0], ',')) THEN
    FOR i IN 1 .. TG_NARGS - 1 LOOP
      c := TG_ARGV[i];
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION '%: không sửa cột % khi trạng thái %', TG_TABLE_NAME, c, OLD.status USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_frozen() IS 'Phiên bản mô hình, biểu mẫu, bảng quyết định đã gửi duyệt, phát hành hoặc ngừng dùng không đổi nội dung; thay đổi cần phiên bản mới.';
--rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_frozen();

--changeset ph11:ph11-0014-fn-child-frozen splitStatements:false
-- Dòng con của phiên bản mô hình (biến, hành động bù trừ): chỉ thêm, sửa, xóa khi phiên bản cha còn DRAFT.
CREATE OR REPLACE FUNCTION ph11_bpm.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
  tn text;
  vid uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; vid := OLD.version_id;
  ELSE
    tn := NEW.tenant_id; vid := NEW.version_id;
  END IF;
  SELECT status INTO st FROM ph11_bpm.process_version WHERE tenant_id = tn AND id = vid;
  IF st IS NOT NULL AND st <> 'DRAFT' THEN
    RAISE EXCEPTION 'Phiên bản % đang %: không sửa nội dung con (%)', vid, st, TG_TABLE_NAME USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph11_bpm.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản mô hình cha không còn là DRAFT.';
--rollback DROP FUNCTION IF EXISTS ph11_bpm.tg_child_frozen();

--changeset ph11:ph11-0015-fn-rls splitStatements:false
-- Hai mẫu như PH-04, 05, 10: 'P' riêng tenant (dòng COMMON chỉ phiên PLATFORM đọc, ghi);
-- 'S' dùng chung (tenant đọc thêm dòng COMMON, chỉ phiên PLATFORM ghi COMMON).
CREATE OR REPLACE PROCEDURE ph11_bpm.p_enable_rls(p_table regclass, p_mode char)
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
COMMENT ON PROCEDURE ph11_bpm.p_enable_rls(regclass, char) IS 'Bật FORCE RLS và 4 chính sách theo mẫu P hoặc S (D03-10 §4, ADR-003).';
--rollback DROP PROCEDURE IF EXISTS ph11_bpm.p_enable_rls(regclass, char);

--changeset ph11:ph11-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph11_bpm.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
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
COMMENT ON PROCEDURE ph11_bpm.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho instance_step. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph11_owner.';
--rollback DROP PROCEDURE IF EXISTS ph11_bpm.p_ensure_partitions(regclass, date, integer);
