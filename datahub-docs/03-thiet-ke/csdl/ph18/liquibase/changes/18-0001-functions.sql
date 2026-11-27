--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph18_ops.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag, If-Match).';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_touch();

--changeset ph18:ph18-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph18_ops.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph18_ops.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, khóa lũy đẳng, nội dung đã chốt.';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_immutable();

--changeset ph18:ph18-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph18_ops.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký, mốc thời gian, mẫu so sánh)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (dlq_audit, incident_timeline, cutover_log, shadow_comparison_sample, migration_reconciliation, restore_verification). Dọn bằng DETACH, DROP phân vùng dưới ph18_owner.';

CREATE OR REPLACE FUNCTION ph18_ops.tg_no_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % là lịch sử, không xóa dòng', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_no_delete() IS 'Chặn DELETE dòng lịch sử (param_value_version); dọn theo hạn giữ do ph18_owner thực hiện có kiểm toán.';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_no_delete(); DROP FUNCTION IF EXISTS ph18_ops.tg_append_only();

--changeset ph18:ph18-0013-fn-frozen splitStatements:false
-- Đối số đầu là danh sách trạng thái đã chốt (ngăn cách bằng dấu phẩy), các đối số sau là tên cột không đổi khi OLD ở các trạng thái đó.
CREATE OR REPLACE FUNCTION ph18_ops.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text[] := string_to_array(TG_ARGV[0], ',');
  i integer;
BEGIN
  IF (to_jsonb(OLD) ->> 'status') = ANY (st) THEN
    FOR i IN 1 .. array_length(TG_ARGV, 1) - 1 LOOP
      IF (to_jsonb(NEW) -> TG_ARGV[i]) IS DISTINCT FROM (to_jsonb(OLD) -> TG_ARGV[i]) THEN
        RAISE EXCEPTION 'Đối tượng ở trạng thái % không sửa được cột % (tạo phiên bản hoặc bản sửa mới)', OLD.status, TG_ARGV[i] USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_frozen() IS 'Phiên bản mẫu thông báo từ IN_REVIEW, bản sửa payload DLQ từ PENDING_APPROVAL không đổi nội dung.';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_frozen();

--changeset ph18:ph18-0014-fn-transition splitStatements:false
-- Chuyển trạng thái chỉ theo máy trạng thái BRIEF-PH18 §4: đối số một là tên cột, đối số hai là danh sách 'TỪ>ĐẾN' ngăn cách bằng dấu phẩy.
CREATE OR REPLACE FUNCTION ph18_ops.tg_transition() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  o text := to_jsonb(OLD) ->> TG_ARGV[0];
  n text := to_jsonb(NEW) ->> TG_ARGV[0];
BEGIN
  IF o IS DISTINCT FROM n AND NOT (COALESCE(o, '') || '>' || COALESCE(n, '')) = ANY (string_to_array(TG_ARGV[1], ',')) THEN
    RAISE EXCEPTION '% không chuyển được từ % sang % (cột %)', TG_TABLE_NAME, o, n, TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_transition() IS 'Cưỡng chế máy trạng thái: dlq_message, replay_job, replay_item, param_value_version, param_change_request, notification_template_version, notification_delivery, task_item, incident, tenant_restore_request, migration_plan, migration_run, parallel_run_group và các bảng có vòng đời.';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_transition();

--changeset ph18:ph18-0015-fn-rls splitStatements:false
-- Đọc: dòng của tenant phiên (bảng dùng chung đọc thêm dòng COMMON). Ghi: chỉ dòng của tenant phiên; dòng COMMON chỉ ghi được khi phiên app.tenant_id = COMMON (PA).
CREATE OR REPLACE PROCEDURE ph18_ops.p_enable_rls(p_table regclass, p_common boolean)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text := CASE WHEN p_common THEN $w$(tenant_id = current_setting('app.tenant_id', false) OR tenant_id = 'COMMON')$w$
                 ELSE $w$(tenant_id = current_setting('app.tenant_id', false))$w$ END;
  w text := $w$(tenant_id = current_setting('app.tenant_id', false))$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph18_ops.p_enable_rls(regclass, boolean) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003); p_common = true thì mọi tenant đọc thêm dòng COMMON (lược đồ khóa, mẫu, lịch quốc gia).';
--rollback DROP PROCEDURE IF EXISTS ph18_ops.p_enable_rls(regclass, boolean);

--changeset ph18:ph18-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph18_ops.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, ph18_ops AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  IF (SELECT relnamespace FROM pg_class WHERE oid = p_table) <> 'ph18_ops'::regnamespace THEN
    RAISE EXCEPTION 'Chỉ tạo phân vùng cho bảng của ph18_ops' USING ERRCODE = '42501';
  END IF;
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('ph18_ops.%s_%s', (SELECT relname FROM pg_class WHERE oid = p_table), to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph18_ops.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho dlq_message, dlq_audit, notification_delivery, shadow_comparison_sample. PartitionMaintenanceJob gọi hằng ngày (SECURITY DEFINER, chủ ph18_owner). Phân vùng không cấp quyền trực tiếp cho vai nào: mọi truy cập qua bảng cha có RLS.';

CREATE OR REPLACE PROCEDURE ph18_ops.p_drop_partitions_before(p_table regclass, p_before date)
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, ph18_ops AS $p$
DECLARE
  r record;
BEGIN
  IF (SELECT relnamespace FROM pg_class WHERE oid = p_table) <> 'ph18_ops'::regnamespace THEN
    RAISE EXCEPTION 'Chỉ dọn phân vùng của ph18_ops' USING ERRCODE = '42501';
  END IF;
  FOR r IN SELECT c.oid::regclass AS part, pg_get_expr(c.relpartbound, c.oid) AS bound
             FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid WHERE i.inhparent = p_table LOOP
    IF substring(r.bound FROM 'TO \(''([^'']+)''\)')::timestamptz <= p_before::timestamptz THEN
      EXECUTE format('ALTER TABLE %s DETACH PARTITION %s', p_table, r.part);
      EXECUTE format('DROP TABLE %s', r.part);
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph18_ops.p_drop_partitions_before(regclass, date) IS 'Dọn phân vùng có cận trên trước p_before theo hạn giữ tham số 18.*; với dlq_message, tác vụ lưu giữ xóa trước mục còn được tham chiếu.';
--rollback DROP PROCEDURE IF EXISTS ph18_ops.p_drop_partitions_before(regclass, date); DROP PROCEDURE IF EXISTS ph18_ops.p_ensure_partitions(regclass, date, integer);

--changeset ph18:ph18-0017-fn-param splitStatements:false
-- Kiểm giá trị tham số theo lược đồ khóa (DD-14): kiểu, miền min/max, danh sách cho phép, trần nền tảng (chỉ áp cho giá trị của tenant).
CREATE OR REPLACE FUNCTION ph18_ops.fn_param_check(p_type text, p_min numeric, p_max numeric, p_allowed jsonb, p_ceiling jsonb, p_value jsonb, p_tenant_row boolean)
  RETURNS text LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
  jt text := jsonb_typeof(p_value);
  v numeric;
BEGIN
  IF p_type = 'BOOLEAN' AND jt <> 'boolean' THEN RETURN 'cần kiểu boolean'; END IF;
  IF p_type IN ('INTEGER', 'DECIMAL') THEN
    IF jt <> 'number' THEN RETURN 'cần kiểu số'; END IF;
    v := (p_value #>> '{}')::numeric;
    IF p_type = 'INTEGER' AND v <> trunc(v) THEN RETURN 'cần số nguyên'; END IF;
    IF p_min IS NOT NULL AND v < p_min THEN RETURN format('nhỏ hơn miền %s', p_min); END IF;
    IF p_max IS NOT NULL AND v > p_max THEN RETURN format('lớn hơn miền %s', p_max); END IF;
    IF p_tenant_row AND p_ceiling IS NOT NULL AND jsonb_typeof(p_ceiling) = 'number' AND v > (p_ceiling #>> '{}')::numeric THEN
      RETURN format('vượt trần nền tảng %s', p_ceiling);
    END IF;
  END IF;
  IF p_type IN ('STRING', 'ENUM', 'DURATION', 'CRON', 'TIME_RANGE') AND jt <> 'string' THEN RETURN 'cần kiểu chuỗi'; END IF;
  IF p_type IN ('LIST_STRING', 'LIST_HOST') THEN
    IF jt <> 'array' THEN RETURN 'cần danh sách'; END IF;
    IF p_tenant_row AND p_ceiling IS NOT NULL AND jsonb_typeof(p_ceiling) = 'array' AND NOT p_ceiling @> p_value THEN
      RETURN 'danh sách vượt trần nền tảng';
    END IF;
  END IF;
  IF p_allowed IS NOT NULL AND jt <> 'array' AND NOT p_allowed @> jsonb_build_array(p_value) THEN RETURN 'không thuộc danh sách cho phép'; END IF;
  IF p_allowed IS NOT NULL AND jt = 'array' AND NOT p_allowed @> p_value THEN RETURN 'có phần tử không thuộc danh sách cho phép'; END IF;
  RETURN NULL;
END
$f$;
COMMENT ON FUNCTION ph18_ops.fn_param_check(text, numeric, numeric, jsonb, jsonb, jsonb, boolean) IS 'Trả NULL khi giá trị hợp lệ, ngược lại trả lý do (thông điệp miền cho lỗi kiểm tra tham số).';

CREATE OR REPLACE FUNCTION ph18_ops.tg_param_definition_check() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  e text := ph18_ops.fn_param_check(NEW.value_type, NEW.min_value, NEW.max_value, NEW.allowed_values, NEW.platform_ceiling, NEW.default_value, false);
BEGIN
  IF e IS NOT NULL THEN
    RAISE EXCEPTION 'Mặc định của % không hợp lệ: %', NEW.param_key, e USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;

CREATE OR REPLACE FUNCTION ph18_ops.tg_param_value_check() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  d record;
  val jsonb := to_jsonb(NEW) -> TG_ARGV[0];
  e text;
BEGIN
  SELECT * INTO d FROM ph18_ops.param_definition WHERE id = NEW.definition_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Khóa tham số chưa được đăng ký' USING ERRCODE = '23503';
  END IF;
  IF d.param_key <> NEW.param_key THEN
    RAISE EXCEPTION 'param_key % không khớp lược đồ %', NEW.param_key, d.param_key USING ERRCODE = '23514';
  END IF;
  IF d.level = 'PLATFORM' AND NEW.tenant_id <> 'COMMON' THEN
    RAISE EXCEPTION 'Tham số % mức PLATFORM, tenant chỉ đọc', d.param_key USING ERRCODE = '23514';
  END IF;
  e := ph18_ops.fn_param_check(d.value_type, d.min_value, d.max_value, d.allowed_values, d.platform_ceiling, val, NEW.tenant_id <> 'COMMON');
  IF e IS NOT NULL THEN
    RAISE EXCEPTION 'Giá trị của % không hợp lệ: %', d.param_key, e USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_param_value_check() IS 'Kiểm giá trị param_value, param_change_request theo param_definition (dòng COMMON đọc được nhờ RLS dùng chung); mức PLATFORM thì tenant không ghi.';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_param_value_check(); DROP FUNCTION IF EXISTS ph18_ops.tg_param_definition_check(); DROP FUNCTION IF EXISTS ph18_ops.fn_param_check(text, numeric, numeric, jsonb, jsonb, jsonb, boolean);

--changeset ph18:ph18-0018-fn-dlq splitStatements:false
-- Payload gốc không sửa: payload_inline chỉ được đặt NULL khi dọn, cùng lúc payload_location chuyển PURGED.
CREATE OR REPLACE FUNCTION ph18_ops.tg_dlq_payload_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.payload_inline IS DISTINCT FROM OLD.payload_inline AND NOT (NEW.payload_inline IS NULL AND NEW.payload_location = 'PURGED') THEN
    RAISE EXCEPTION 'Payload gốc của mục DLQ không sửa được; tạo bản sửa (dlq_revision)' USING ERRCODE = '55000';
  END IF;
  IF NEW.payload_location IS DISTINCT FROM OLD.payload_location AND NEW.payload_location <> 'PURGED' THEN
    RAISE EXCEPTION 'payload_location chỉ chuyển sang PURGED' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph18_ops.tg_dlq_payload_guard() IS 'Bảo vệ payload gốc của dlq_message.';
--rollback DROP FUNCTION IF EXISTS ph18_ops.tg_dlq_payload_guard();
