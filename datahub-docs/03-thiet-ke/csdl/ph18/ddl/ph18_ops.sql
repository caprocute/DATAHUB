-- =============================================================================
-- D03-03-PH18 · DDL schema ph18_ops, PH-18 Vận hành và xử lý lỗi
-- Phiên bản 0.2 · 2026-11-27 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py từ danh mục bảng (tools/sinh_ddl_bang_a.py, sinh_ddl_bang_b.py); sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d ph18_test -f ph18_ops.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Cụm pg-core, DU dh-platform (package vn.datahub.platform.ops). Bốn vai: ph18_owner (NOLOGIN, chủ đối tượng), ph18_app (ứng dụng),
-- ph18_readonly (báo cáo, không đọc payload DLQ, biến mẫu thông báo), ph18_worker (Job K8s dh-ops-worker ở dh-batch: dh-migrate,
-- dh-tenant-restore, dh-tenant-export). RLS FORCE theo current_setting('app.tenant_id'); bảng dùng chung đọc thêm dòng COMMON.
-- Không lưu bí mật (chỉ tham chiếu OpenBao kv/dh/{tenant}/...), payload DLQ > 256 KB ở Garage bucket dh-{tenant}-ops.
-- Không cần extension (gen_random_uuid, sha256 có sẵn ở PostgreSQL 16).
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 18-0000-bootstrap.sql
-- @changeset ph18-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_owner') THEN
    CREATE ROLE ph18_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_app') THEN
    CREATE ROLE ph18_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_readonly') THEN
    CREATE ROLE ph18_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph18_worker') THEN
    CREATE ROLE ph18_worker NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph18-0001-schema context:bootstrap
CREATE SCHEMA IF NOT EXISTS ph18_ops AUTHORIZATION ph18_owner;
COMMENT ON SCHEMA ph18_ops IS 'PH-18 Vận hành và xử lý lỗi (dh-platform, package vn.datahub.platform.ops): kho tham số và cờ tính năng, DLQ hợp nhất và phát lại, thông báo, Việc của tôi, lịch làm việc và cửa sổ bảo trì, sự cố vận hành, sao lưu và khôi phục tenant, sáp nhập, di trú hệ cũ và chạy song song, báo cáo vận hành. Không lưu bí mật.';
REVOKE ALL ON SCHEMA ph18_ops FROM PUBLIC;
GRANT USAGE ON SCHEMA ph18_ops TO ph18_app, ph18_readonly, ph18_worker;
-- @rollback DROP SCHEMA IF EXISTS ph18_ops CASCADE;

SET ROLE ph18_owner;

-- @changeset ph18-0002-session-tenant runAlways:true
SET app.tenant_id = 'COMMON';
-- @rollback -- Không cần.

-- @file 18-0001-functions.sql
-- @changeset ph18-0010-fn-touch splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_touch();

-- @changeset ph18-0011-fn-immutable splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_immutable();

-- @changeset ph18-0012-fn-append-only splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_no_delete(); DROP FUNCTION IF EXISTS ph18_ops.tg_append_only();

-- @changeset ph18-0013-fn-frozen splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_frozen();

-- @changeset ph18-0014-fn-transition splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_transition();

-- @changeset ph18-0015-fn-rls splitStatements:false
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
-- @rollback DROP PROCEDURE IF EXISTS ph18_ops.p_enable_rls(regclass, boolean);

-- @changeset ph18-0016-fn-partitions splitStatements:false
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
-- @rollback DROP PROCEDURE IF EXISTS ph18_ops.p_drop_partitions_before(regclass, date); DROP PROCEDURE IF EXISTS ph18_ops.p_ensure_partitions(regclass, date, integer);

-- @changeset ph18-0017-fn-param splitStatements:false
-- Kiểm giá trị tham số theo lược đồ khóa (DD-14): kiểu, miền min/max, danh sách cho phép, trần nền tảng (chỉ áp cho giá trị của tenant).
CREATE OR REPLACE FUNCTION ph18_ops.fn_param_check(p_type text, p_min numeric, p_max numeric, p_allowed jsonb, p_ceiling jsonb, p_value jsonb, p_tenant_row boolean)
  RETURNS text LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
  jt text := jsonb_typeof(p_value);
  v numeric;
BEGIN
  IF p_type = 'BOOL' AND jt <> 'boolean' THEN RETURN 'cần kiểu boolean'; END IF;
  IF p_type IN ('INT', 'DECIMAL') THEN
    IF jt <> 'number' THEN RETURN 'cần kiểu số'; END IF;
    v := (p_value #>> '{}')::numeric;
    IF p_type = 'INT' AND v <> trunc(v) THEN RETURN 'cần số nguyên'; END IF;
    IF p_min IS NOT NULL AND v < p_min THEN RETURN format('nhỏ hơn miền %s', p_min); END IF;
    IF p_max IS NOT NULL AND v > p_max THEN RETURN format('lớn hơn miền %s', p_max); END IF;
    IF p_tenant_row AND p_ceiling IS NOT NULL AND jsonb_typeof(p_ceiling) = 'number' AND v > (p_ceiling #>> '{}')::numeric THEN
      RETURN format('vượt trần nền tảng %s', p_ceiling);
    END IF;
  END IF;
  IF p_type IN ('STRING', 'ENUM', 'DURATION', 'CRON') AND jt <> 'string' THEN RETURN 'cần kiểu chuỗi'; END IF;
  IF p_type IN ('LIST<STRING>', 'LIST<HOST>') THEN
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_param_value_check(); DROP FUNCTION IF EXISTS ph18_ops.tg_param_definition_check(); DROP FUNCTION IF EXISTS ph18_ops.fn_param_check(text, numeric, numeric, jsonb, jsonb, jsonb, boolean);

-- @changeset ph18-0018-fn-dlq splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph18_ops.tg_dlq_payload_guard();


-- @file 18-0010-core.sql
-- @changeset ph18-0100-outbox-event splitStatements:false
CREATE TABLE ph18_ops.outbox_event (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  event_type     varchar(128) NOT NULL,
  topic          varchar(249) NOT NULL,
  aggregate_type varchar(64) NOT NULL,
  aggregate_id   varchar(255) NOT NULL,
  partition_key  varchar(255) NOT NULL,
  payload        jsonb NOT NULL,
  trace_id       char(32),
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  published_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_outbox_event PRIMARY KEY (id),
  CONSTRAINT ck_outbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_outbox_event_prefix CHECK (split_part(topic, '.', 1) = lower(tenant_id)),
  CONSTRAINT ck_outbox_event_topic CHECK (topic ~ '^[a-z0-9]+\.ops\.[a-z0-9-]+(\.[a-z0-9-]+)*\.v[0-9]+$'),
  CONSTRAINT ck_outbox_event_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_outbox_event_no_content CHECK (NOT (payload ?| ARRAY['payload', 'payloadInline', 'value', 'values', 'email', 'phone', 'address', 'params']))
);
CREATE INDEX ix_outbox_event_occurred ON ph18_ops.outbox_event (occurred_at);
CREATE TRIGGER tg_outbox_event_touch BEFORE UPDATE ON ph18_ops.outbox_event FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.outbox_event', false);
COMMENT ON TABLE ph18_ops.outbox_event IS 'Bảng kỹ thuật (không có mã EN). Outbox (DD-11, ADR-042) cho sự kiện {tenant}.ops.*.v1 của PH-18: ops.param.changed, ops.dlq.threshold-crossed, ops.notification.bounced, ops.tenant.restored, sự cố, báo cáo vận hành. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm; CHECK chặn khóa payload DLQ, giá trị tham số, địa chỉ người nhận. Dọn sau 18.outbox.retention-days.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.outbox_event CASCADE;

-- @changeset ph18-0110-inbox-event splitStatements:false
CREATE TABLE ph18_ops.inbox_event (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  consumer     varchar(64) NOT NULL,
  event_id     varchar(255) NOT NULL,
  source_topic varchar(249) NOT NULL,
  event_type   varchar(255) NOT NULL,
  received_at  timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  outcome      varchar(2000),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_inbox_event PRIMARY KEY (id),
  CONSTRAINT ck_inbox_event_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_inbox_event_consumer UNIQUE (tenant_id, consumer, event_id),
  CONSTRAINT ck_inbox_event_consumer CHECK (consumer ~ '^[A-Z][A-Za-z0-9]+$'),
  CONSTRAINT ck_inbox_event_prefix CHECK (split_part(source_topic, '.', 1) IN (lower(tenant_id), 'platform'))
);
CREATE INDEX ix_inbox_event_received ON ph18_ops.inbox_event (received_at);
CREATE TRIGGER tg_inbox_event_touch BEFORE UPDATE ON ph18_ops.inbox_event FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.inbox_event', false);
COMMENT ON TABLE ph18_ops.inbox_event IS 'Bảng kỹ thuật (không có mã EN). Inbox khử trùng sự kiện PH-18 tiêu thụ (at-least-once): topic DLQ {tenant}.ops.dlq.v1 (khóa dlqKey, cửa sổ 18.dlq.dedup-window-days), sự kiện các PH sinh thông báo và việc (hợp đồng §1.3), EVT-10-11, 12, 15, 16, EVT-13-04, 05, sự kiện platform.tenant.* của PH-20. Khóa (consumer, event_id).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.inbox_event CASCADE;


-- @file 18-0020-param.sql
-- @changeset ph18-0120-param-namespace splitStatements:false
CREATE TABLE ph18_ops.param_namespace (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  code              varchar(32) NOT NULL,
  owner_module      varchar(8) NOT NULL,
  title             varchar(255) NOT NULL,
  description       text,
  approval_owner    varchar(8) NOT NULL DEFAULT 'PH-18',
  cache_ttl_seconds integer NOT NULL DEFAULT 60,
  status            varchar(12) NOT NULL DEFAULT 'ACTIVE',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_namespace PRIMARY KEY (id),
  CONSTRAINT uq_param_namespace_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_namespace_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT uq_param_namespace_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_param_namespace_code CHECK (code ~ '^[a-z0-9]+(\.[a-z0-9-]+)*$' AND code <> '19'),
  CONSTRAINT ck_param_namespace_owner CHECK (owner_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_param_namespace_approval CHECK (approval_owner ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_param_namespace_ttl CHECK (cache_ttl_seconds BETWEEN 1 AND 60),
  CONSTRAINT ck_param_namespace_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_param_namespace_touch BEFORE UPDATE ON ph18_ops.param_namespace FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_namespace_immutable BEFORE UPDATE ON ph18_ops.param_namespace FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('code');
CALL ph18_ops.p_enable_rls('ph18_ops.param_namespace', true);
COMMENT ON TABLE ph18_ops.param_namespace IS 'EN-18-01 Không gian tên tham số do từng PH đăng ký khi khởi động (onboarding, 00, 02, 04, 05, 07.rdm, 10, 12, 14, 15, 17, 18, 20, ff; mở cho 06, 08, 09, 11, 13, 16; 19 do PH-19 tự giữ). Chỉ dòng COMMON. approval_owner khác PH18 thì PH đó tự giữ bốn mắt (PH-14, PH-17).';
COMMENT ON COLUMN ph18_ops.param_namespace.cache_ttl_seconds IS 'Thời gian đệm tối đa ở PH đọc; trần 60 giây theo NFR-00-052 và CC-CFG-04.';
COMMENT ON COLUMN ph18_ops.param_namespace.approval_owner IS 'PH giữ quy trình bốn mắt cho tham số ★ của không gian tên này; mặc định PH-18.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.param_namespace CASCADE;

-- @changeset ph18-0130-param-definition splitStatements:false
CREATE TABLE ph18_ops.param_definition (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  namespace_code   varchar(32) NOT NULL,
  param_key        varchar(128) NOT NULL,
  value_type       varchar(16) NOT NULL,
  default_value    jsonb NOT NULL,
  json_schema      jsonb NOT NULL DEFAULT '{}',
  min_value        numeric,
  max_value        numeric,
  allowed_values   jsonb,
  platform_ceiling jsonb,
  unit             varchar(16),
  level            varchar(8) NOT NULL DEFAULT 'TENANT',
  secure           boolean NOT NULL DEFAULT false,
  display_group    varchar(64),
  display_order    integer NOT NULL DEFAULT 100,
  label            varchar(255) NOT NULL,
  description      text,
  deprecated_at    timestamptz,
  removal_date     date,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_definition PRIMARY KEY (id),
  CONSTRAINT uq_param_definition_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_definition_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT uq_param_definition_key UNIQUE (tenant_id, param_key),
  CONSTRAINT fk_param_definition_namespace FOREIGN KEY (tenant_id, namespace_code) REFERENCES ph18_ops.param_namespace (tenant_id, code),
  CONSTRAINT ck_param_definition_key CHECK (param_key ~ '^[a-z0-9]+(\.[A-Za-z0-9-]+)+$' AND left(param_key, char_length(namespace_code) + 1) = namespace_code || '.'),
  CONSTRAINT ck_param_definition_type CHECK (value_type IN ('INT', 'DECIMAL', 'BOOL', 'STRING', 'ENUM', 'DURATION', 'CRON', 'LIST<STRING>', 'LIST<HOST>', 'JSON')),
  CONSTRAINT ck_param_definition_level CHECK (level IN ('PLATFORM', 'TENANT')),
  CONSTRAINT ck_param_definition_range CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value),
  CONSTRAINT ck_param_definition_allowed CHECK (allowed_values IS NULL OR jsonb_typeof(allowed_values) = 'array'),
  CONSTRAINT ck_param_definition_enum CHECK (value_type <> 'ENUM' OR allowed_values IS NOT NULL),
  CONSTRAINT ck_param_definition_removal CHECK (removal_date IS NULL OR deprecated_at IS NOT NULL)
);
CREATE INDEX ix_param_definition_group ON ph18_ops.param_definition (namespace_code, display_group, display_order);
CREATE TRIGGER tg_param_definition_touch BEFORE UPDATE ON ph18_ops.param_definition FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_definition_immutable BEFORE UPDATE ON ph18_ops.param_definition FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('param_key', 'namespace_code', 'value_type');
CREATE TRIGGER tg_param_definition_validate BEFORE INSERT OR UPDATE ON ph18_ops.param_definition FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_param_definition_check();
CALL ph18_ops.p_enable_rls('ph18_ops.param_definition', true);
COMMENT ON TABLE ph18_ops.param_definition IS 'EN-18-02 Lược đồ một khóa tham số (DD-14 schema): kiểu, mặc định, miền, trần nền tảng, mức PLATFORM hay TENANT, cờ bảo mật ★, nhóm hiển thị. Chỉ dòng COMMON; PH sở hữu đăng ký qua scope ops:param-register. Khóa có ngày gỡ thì vẫn đọc được tới removal_date.';
COMMENT ON COLUMN ph18_ops.param_definition.value_type IS 'Trường type của FRS và OpenAPI (tên cột tránh từ khóa SQL).';
COMMENT ON COLUMN ph18_ops.param_definition.default_value IS 'Trường default của FRS và OpenAPI (tên cột tránh từ khóa SQL).';
COMMENT ON COLUMN ph18_ops.param_definition.display_group IS 'Trường group của FRS và OpenAPI (tên cột tránh từ khóa SQL).';
COMMENT ON COLUMN ph18_ops.param_definition.level IS 'PLATFORM: chỉ PA ghi giá trị (dòng COMMON), tenant chỉ đọc; TENANT: tenant ghi đè trong miền và trần.';
COMMENT ON COLUMN ph18_ops.param_definition.platform_ceiling IS 'Trần nền tảng: giá trị tenant không vượt (số: không lớn hơn; danh sách: là tập con).';
COMMENT ON COLUMN ph18_ops.param_definition.secure IS 'Trường secure của FRS (lược đồ khóa). Tham số ★ bảo mật: đổi cần bốn mắt (param_change_request) do approval_owner của không gian tên giữ.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.param_definition CASCADE;

-- @changeset ph18-0140-param-change-request splitStatements:false
CREATE TABLE ph18_ops.param_change_request (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  definition_id         uuid NOT NULL,
  param_key             varchar(128) NOT NULL,
  proposed_value        jsonb NOT NULL,
  current_value         jsonb,
  reason                text NOT NULL,
  status                varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
  requested_by          varchar(64) NOT NULL,
  requested_at          timestamptz NOT NULL DEFAULT now(),
  decided_by            varchar(64),
  decided_at            timestamptz,
  decision_note         varchar(1000),
  expires_at            timestamptz NOT NULL,
  approval_owner        varchar(8) NOT NULL DEFAULT 'PH-18',
  external_approval_ref varchar(128),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_change_request PRIMARY KEY (id),
  CONSTRAINT uq_param_change_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_change_request_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_param_change_request_definition FOREIGN KEY (definition_id) REFERENCES ph18_ops.param_definition (id),
  CONSTRAINT ck_param_change_request_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_param_change_request_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_param_change_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_param_change_request_decided CHECK (status IN ('PENDING_APPROVAL', 'EXPIRED', 'CANCELLED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL) OR external_approval_ref IS NOT NULL),
  CONSTRAINT ck_param_change_request_owner CHECK (approval_owner ~ '^PH-[0-9]{2}$')
);
CREATE UNIQUE INDEX uq_param_change_request_pending ON ph18_ops.param_change_request (tenant_id, param_key) WHERE status = 'PENDING_APPROVAL';
CREATE INDEX ix_param_change_request_status ON ph18_ops.param_change_request (tenant_id, status, requested_at);
CREATE TRIGGER tg_param_change_request_touch BEFORE UPDATE ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_change_request_immutable BEFORE UPDATE ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('definition_id', 'param_key', 'proposed_value', 'requested_by', 'reason');
CREATE TRIGGER tg_param_change_request_fsm_status BEFORE UPDATE ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED,PENDING_APPROVAL>EXPIRED');
CREATE TRIGGER tg_param_change_request_value BEFORE INSERT ON ph18_ops.param_change_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_param_value_check('proposed_value');
CALL ph18_ops.p_enable_rls('ph18_ops.param_change_request', true);
COMMENT ON TABLE ph18_ops.param_change_request IS 'EN-18-05 Đề nghị đổi tham số ★ chờ duyệt bốn mắt: giá trị đề xuất, giá trị hiện tại, lý do; người duyệt khác người đề nghị. Mỗi khóa chỉ một đề nghị PENDING_APPROVAL mỗi tenant. PH tự giữ bốn mắt (PH-14, PH-17) ghi external_approval_ref thay cho duyệt ở PH-18.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.param_change_request CASCADE;

-- @changeset ph18-0150-param-value splitStatements:false
CREATE TABLE ph18_ops.param_value (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  definition_id      uuid NOT NULL,
  param_key          varchar(128) NOT NULL,
  value              jsonb NOT NULL,
  scope              varchar(8) NOT NULL,
  current_version_no integer NOT NULL DEFAULT 1,
  effective_from     timestamptz NOT NULL DEFAULT now(),
  source             varchar(16) NOT NULL DEFAULT 'UI',
  changed_reason     varchar(1000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_value PRIMARY KEY (id),
  CONSTRAINT uq_param_value_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_value_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_param_value_key UNIQUE (tenant_id, param_key),
  CONSTRAINT fk_param_value_definition FOREIGN KEY (definition_id) REFERENCES ph18_ops.param_definition (id),
  CONSTRAINT ck_param_value_scope CHECK (scope IN ('PLATFORM', 'TENANT') AND (scope = 'PLATFORM') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_param_value_version_no CHECK (current_version_no >= 1),
  CONSTRAINT ck_param_value_source CHECK (source IN ('UI', 'API', 'SEED_TENANT', 'BUNDLE', 'ROLLBACK', 'REGISTER'))
);
CREATE INDEX ix_param_value_definition ON ph18_ops.param_value (definition_id);
CREATE TRIGGER tg_param_value_touch BEFORE UPDATE ON ph18_ops.param_value FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_value_immutable BEFORE UPDATE ON ph18_ops.param_value FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('definition_id', 'param_key', 'scope');
CREATE TRIGGER tg_param_value_validate BEFORE INSERT OR UPDATE ON ph18_ops.param_value FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_param_value_check('value');
CALL ph18_ops.p_enable_rls('ph18_ops.param_value', true);
COMMENT ON TABLE ph18_ops.param_value IS 'EN-18-03 Giá trị hiện hành của một khóa theo tenant (DD-14 value, scope). Dòng COMMON scope PLATFORM là giá trị nền tảng; dòng Tnn scope TENANT là ghi đè. Trigger kiểm kiểu, miền, danh sách cho phép, trần nền tảng và mức PLATFORM theo param_definition. Ghi có If-Match (version).';
COMMENT ON COLUMN ph18_ops.param_value.source IS 'SEED_TENANT: PH-20 ghi mặc định khi khởi tạo tenant (chỉ khóa chưa có); BUNDLE: nhập gói tham số; ROLLBACK: khôi phục phiên bản cũ.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.param_value CASCADE;

-- @changeset ph18-0160-param-value-version splitStatements:false
CREATE TABLE ph18_ops.param_value_version (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  definition_id          uuid NOT NULL,
  param_key              varchar(128) NOT NULL,
  version_no             integer NOT NULL,
  value                  jsonb NOT NULL,
  previous_value         jsonb,
  status                 varchar(20) NOT NULL,
  reason                 varchar(1000),
  change_request_id      uuid,
  rollback_of_version_no integer,
  effective_from         timestamptz NOT NULL DEFAULT now(),
  superseded_at          timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_value_version PRIMARY KEY (id),
  CONSTRAINT uq_param_value_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_value_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_param_value_version_no UNIQUE (tenant_id, param_key, version_no),
  CONSTRAINT fk_param_value_version_definition FOREIGN KEY (definition_id) REFERENCES ph18_ops.param_definition (id),
  CONSTRAINT fk_param_value_version_change_request FOREIGN KEY (tenant_id, change_request_id) REFERENCES ph18_ops.param_change_request (tenant_id, id),
  CONSTRAINT ck_param_value_version_status CHECK (status IN ('PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_param_value_version_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_param_value_version_superseded CHECK ((status = 'SUPERSEDED') = (superseded_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_param_value_version_active ON ph18_ops.param_value_version (tenant_id, param_key) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_param_value_version_touch BEFORE UPDATE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_value_version_immutable BEFORE UPDATE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('definition_id', 'param_key', 'version_no', 'value', 'previous_value', 'change_request_id', 'effective_from');
CREATE TRIGGER tg_param_value_version_fsm_status BEFORE UPDATE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING_APPROVAL>ACTIVE,PENDING_APPROVAL>REJECTED,ACTIVE>SUPERSEDED');
CREATE TRIGGER tg_param_value_version_no_delete BEFORE DELETE ON ph18_ops.param_value_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_no_delete();
CALL ph18_ops.p_enable_rls('ph18_ops.param_value_version', true);
COMMENT ON TABLE ph18_ops.param_value_version IS 'EN-18-04 Lịch sử phiên bản giá trị tham số (DD-14 có phiên bản): mỗi lần ghi thêm một dòng; nội dung bất biến, chỉ trạng thái chuyển PENDING_APPROVAL sang ACTIVE hoặc REJECTED, ACTIVE sang SUPERSEDED. Mỗi khóa một phiên bản ACTIVE. Không xóa; giữ 18.param.history-retention-days.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.param_value_version CASCADE;

-- @changeset ph18-0170-feature-flag splitStatements:false
CREATE TABLE ph18_ops.feature_flag (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  flag_key        varchar(128) NOT NULL,
  owner_ph        varchar(8) NOT NULL,
  owner_user      varchar(64) NOT NULL,
  description     text NOT NULL,
  enabled         boolean NOT NULL DEFAULT false,
  rollout_percent smallint NOT NULL DEFAULT 100,
  retire_by       date NOT NULL,
  status          varchar(12) NOT NULL DEFAULT 'ACTIVE',
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_feature_flag PRIMARY KEY (id),
  CONSTRAINT uq_feature_flag_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_feature_flag_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_feature_flag_key UNIQUE (tenant_id, flag_key),
  CONSTRAINT ck_feature_flag_key CHECK (flag_key ~ '^ff\.[a-z0-9-]+\.[a-z0-9-]+$'),
  CONSTRAINT ck_feature_flag_module CHECK (owner_ph ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_feature_flag_rollout CHECK (rollout_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_feature_flag_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE INDEX ix_feature_flag_retire ON ph18_ops.feature_flag (retire_by) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_feature_flag_touch BEFORE UPDATE ON ph18_ops.feature_flag FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_feature_flag_immutable BEFORE UPDATE ON ph18_ops.feature_flag FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('flag_key', 'owner_ph');
CALL ph18_ops.p_enable_rls('ph18_ops.feature_flag', true);
COMMENT ON TABLE ph18_ops.feature_flag IS 'EN-18-06 Cờ tính năng ff.{module}.{tính-năng} theo tenant (QT-BR-03, CC-CFG-04): chủ sở hữu, ngày gỡ bắt buộc. Dòng COMMON là mặc định nền tảng, dòng Tnn ghi đè. Hiệu lực ≤ 60 giây qua sự kiện đổi.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.feature_flag CASCADE;

-- @changeset ph18-0180-egress-allowlist-entry splitStatements:false
CREATE TABLE ph18_ops.egress_allowlist_entry (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  host        varchar(253) NOT NULL,
  port        integer NOT NULL DEFAULT 443,
  scheme      varchar(8) NOT NULL DEFAULT 'https',
  used_by     varchar(8) NOT NULL,
  purpose     varchar(24) NOT NULL,
  reason      varchar(500),
  enabled     boolean NOT NULL DEFAULT false,
  approved_by varchar(64),
  approved_at timestamptz,
  expires_at  timestamptz,
  revoked_at  timestamptz,
  revoked_by  varchar(64),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_egress_allowlist_entry PRIMARY KEY (id),
  CONSTRAINT uq_egress_allowlist_entry_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_egress_allowlist_entry_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_egress_allowlist_entry_host UNIQUE (tenant_id, host, port, used_by),
  CONSTRAINT ck_egress_allowlist_entry_host CHECK (host ~ '^(\*\.)?([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'),
  CONSTRAINT ck_egress_allowlist_entry_port CHECK (port BETWEEN 1 AND 65535),
  CONSTRAINT ck_egress_allowlist_entry_scheme CHECK (scheme = 'https'),
  CONSTRAINT ck_egress_allowlist_entry_module CHECK (used_by ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_egress_allowlist_entry_purpose CHECK (purpose IN ('DEV_PORTAL_BACKEND', 'GIT_REPO', 'WEBHOOK', 'MODEL_PROVIDER', 'OTHER')),
  CONSTRAINT ck_egress_allowlist_entry_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_egress_allowlist_entry_enabled CHECK (NOT enabled OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND revoked_at IS NULL))
);
CREATE TRIGGER tg_egress_allowlist_entry_touch BEFORE UPDATE ON ph18_ops.egress_allowlist_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_egress_allowlist_entry_immutable BEFORE UPDATE ON ph18_ops.egress_allowlist_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('host', 'port', 'used_by');
CALL ph18_ops.p_enable_rls('ph18_ops.egress_allowlist_entry', false);
COMMENT ON TABLE ph18_ops.egress_allowlist_entry IS 'EN-18-07 Danh sách đích egress cho phép theo tenant (kiểu LIST<HOST>, giải Q15-10): máy đích HTTPS, cổng, PH dùng (PH-15 backend thử và kho Git, PH-13 webhook). Không nhận địa chỉ IP trần; duyệt bốn mắt trước khi hiệu lực; PH dùng vẫn kiểm lại khi gọi và chặn dải nội bộ.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.egress_allowlist_entry CASCADE;

-- @changeset ph18-0190-param-bundle splitStatements:false
CREATE TABLE ph18_ops.param_bundle (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  bundle_code   varchar(64) NOT NULL,
  direction     varchar(8) NOT NULL,
  source_env    varchar(8) NOT NULL,
  target_env    varchar(8),
  namespaces    varchar(32)[] NOT NULL,
  item_count    integer NOT NULL DEFAULT 0,
  sha256        char(64),
  bucket        varchar(63),
  object_key    text,
  diff_summary  jsonb,
  status        varchar(20) NOT NULL DEFAULT 'DRAFT',
  approved_by   varchar(64),
  approved_at   timestamptz,
  applied_at    timestamptz,
  error_message varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_param_bundle PRIMARY KEY (id),
  CONSTRAINT uq_param_bundle_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_param_bundle_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_param_bundle_code UNIQUE (tenant_id, bundle_code),
  CONSTRAINT ck_param_bundle_direction CHECK (direction IN ('EXPORT', 'IMPORT')),
  CONSTRAINT ck_param_bundle_env CHECK (source_env IN ('DEV', 'TEST', 'STAGING', 'PROD') AND (target_env IS NULL OR target_env IN ('DEV', 'TEST', 'STAGING', 'PROD'))),
  CONSTRAINT ck_param_bundle_status CHECK (status IN ('DRAFT', 'VALIDATED', 'PENDING_APPROVAL', 'APPLIED', 'FAILED', 'REJECTED')),
  CONSTRAINT ck_param_bundle_count CHECK (item_count >= 0),
  CONSTRAINT ck_param_bundle_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_param_bundle_bucket CHECK (bucket IS NULL OR bucket = 'dh-' || lower(tenant_id) || '-ops'),
  CONSTRAINT ck_param_bundle_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_param_bundle_applied CHECK (status <> 'APPLIED' OR direction = 'EXPORT' OR approved_by IS NOT NULL)
);
CREATE TRIGGER tg_param_bundle_touch BEFORE UPDATE ON ph18_ops.param_bundle FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_param_bundle_immutable BEFORE UPDATE ON ph18_ops.param_bundle FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('bundle_code', 'direction');
CREATE TRIGGER tg_param_bundle_fsm_status BEFORE UPDATE ON ph18_ops.param_bundle FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>VALIDATED,DRAFT>FAILED,VALIDATED>PENDING_APPROVAL,VALIDATED>APPLIED,PENDING_APPROVAL>APPLIED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>FAILED,VALIDATED>FAILED');
CALL ph18_ops.p_enable_rls('ph18_ops.param_bundle', false);
COMMENT ON TABLE ph18_ops.param_bundle IS 'EN-18-08 Gói tham số xuất nhập giữa môi trường (DEV, TEST, STAGING, PROD): danh sách không gian tên, số khóa, tổng kiểm tra, khác biệt so với đích. Tệp gói ở Garage bucket dh-{tenant}-ops, không chứa tham số ★ ở dạng rõ (chỉ khóa, cần nhập lại). Áp gói cần bốn mắt.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.param_bundle CASCADE;


-- @file 18-0030-dlq.sql
-- @changeset ph18-0200-dlq-source splitStatements:false
CREATE TABLE ph18_ops.dlq_source (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  source_code      varchar(32) NOT NULL,
  source_module    varchar(8) NOT NULL,
  ingest_channel   varchar(12) NOT NULL,
  replay_mode      varchar(16) NOT NULL,
  replay_endpoint  varchar(255),
  callback_scope   varchar(64) NOT NULL DEFAULT 'ops:replay-callback',
  payload_viewable boolean NOT NULL DEFAULT true,
  enabled          boolean NOT NULL DEFAULT true,
  description      varchar(500),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_source PRIMARY KEY (id),
  CONSTRAINT uq_dlq_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_source_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_dlq_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_dlq_source_code CHECK (source_code ~ '^[a-z0-9-]{3,40}$'),
  CONSTRAINT ck_dlq_source_module CHECK (source_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_dlq_source_channel CHECK (ingest_channel IN ('KAFKA', 'API', 'FEDERATED')),
  CONSTRAINT ck_dlq_source_mode CHECK (replay_mode IN ('KAFKA_TOPIC', 'HTTP_PORT', 'EVENT_LAYER', 'NONE')),
  CONSTRAINT ck_dlq_source_event_layer CHECK ((replay_mode = 'EVENT_LAYER') = (ingest_channel = 'FEDERATED')),
  CONSTRAINT ck_dlq_source_endpoint CHECK (replay_endpoint IS NULL OR replay_endpoint ~ '^/[a-z0-9/_{}.:-]+$'),
  CONSTRAINT ck_dlq_source_federated CHECK (ingest_channel <> 'FEDERATED' OR (source_module = 'PH-10' AND NOT payload_viewable))
);
CREATE TRIGGER tg_dlq_source_touch BEFORE UPDATE ON ph18_ops.dlq_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_source_immutable BEFORE UPDATE ON ph18_ops.dlq_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('source_code', 'source_module');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_source', true);
COMMENT ON TABLE ph18_ops.dlq_source IS 'EN-18-18 Đăng ký nguồn DLQ: PH nguồn, kênh vào (KAFKA topic {tenant}.ops.dlq.v1, API ops:dlq-write, FEDERATED liên thông DLQ tầng sự kiện PH-10 qua API-10-060, 061 không sao chép nội dung), chế độ phát lại replayMode của FRS (KAFKA_TOPIC nghe EVT-18-09, HTTP_PORT gọi cổng ReplayPort của nguồn, EVENT_LAYER đề nghị PH-10 qua API-10-064, NONE). Dòng COMMON là đăng ký nền tảng, tenant có thể tắt nguồn bằng dòng riêng.';
COMMENT ON COLUMN ph18_ops.dlq_source.replay_endpoint IS 'Đường dẫn nội bộ (mTLS) của cổng phát lại ở PH nguồn; phát lại luôn qua lối vào của nguồn.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_source CASCADE;

-- @changeset ph18-0210-error-guide splitStatements:false
CREATE TABLE ph18_ops.error_guide (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  error_code    varchar(16) NOT NULL,
  locale        varchar(8) NOT NULL DEFAULT 'vi',
  title         varchar(255) NOT NULL,
  owner_ph      varchar(8) NOT NULL,
  causes        text[] NOT NULL,
  steps         text[] NOT NULL,
  replayable    varchar(10) NOT NULL,
  default_class varchar(12),
  links         text[] NOT NULL DEFAULT '{}',
  runbook_path  varchar(500),
  status        varchar(12) NOT NULL DEFAULT 'DRAFT',
  published_at  timestamptz,
  published_by  varchar(64),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_error_guide PRIMARY KEY (id),
  CONSTRAINT uq_error_guide_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_error_guide_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_error_guide_code UNIQUE (tenant_id, error_code, locale),
  CONSTRAINT ck_error_guide_code CHECK (error_code ~ '^ERR-[0-9]{2}-[0-9]{3}$'),
  CONSTRAINT ck_error_guide_replayable CHECK (replayable IN ('YES', 'AFTER_FIX', 'NO')),
  CONSTRAINT ck_error_guide_class CHECK (default_class IS NULL OR default_class IN ('TRANSIENT', 'BUSINESS', 'CONTRACT', 'POISON', 'UNKNOWN')),
  CONSTRAINT ck_error_guide_owner CHECK (owner_ph ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_error_guide_content CHECK (cardinality(causes) > 0 AND cardinality(steps) > 0),
  CONSTRAINT ck_error_guide_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_error_guide_published CHECK (status = 'DRAFT' OR (published_at IS NOT NULL AND published_by IS NOT NULL)),
  CONSTRAINT ck_error_guide_runbook CHECK (runbook_path IS NULL OR runbook_path ~ '^/[a-z0-9/_#.-]+$')
);
CREATE TRIGGER tg_error_guide_touch BEFORE UPDATE ON ph18_ops.error_guide FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_error_guide_immutable BEFORE UPDATE ON ph18_ops.error_guide FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('error_code', 'locale');
CREATE TRIGGER tg_error_guide_fsm_status BEFORE UPDATE ON ph18_ops.error_guide FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PUBLISHED,PUBLISHED>DRAFT,PUBLISHED>RETIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.error_guide', true);
COMMENT ON TABLE ph18_ops.error_guide IS 'EN-18-15 Sổ tay xử lý theo mã lỗi ERR (nguồn tri thức loại ERROR_CODE, GUIDE cho PH-17): nguyên nhân (causes), các bước xử lý (steps), khả năng phát lại replayable (YES, AFTER_FIX, NO), lớp lỗi mặc định, liên kết; tên trường theo FRS FR-18-025. Dòng COMMON là sổ tay nền tảng, tenant bổ sung ghi chú riêng. Bản PUBLISHED phát sự kiện đổi hướng dẫn để PH-17 lập chỉ mục lại.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.error_guide CASCADE;

-- @changeset ph18-0220-dlq-group splitStatements:false
CREATE TABLE ph18_ops.dlq_group (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  signature      char(64) NOT NULL,
  source_code    varchar(32) NOT NULL,
  flow_code      varchar(128),
  error_code     varchar(16),
  error_class    varchar(12) NOT NULL,
  sample_message varchar(500) NOT NULL,
  first_seen_at  timestamptz NOT NULL DEFAULT now(),
  last_seen_at   timestamptz NOT NULL DEFAULT now(),
  open_count     integer NOT NULL DEFAULT 0,
  total_count    integer NOT NULL DEFAULT 0,
  guide_id       uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_group PRIMARY KEY (id),
  CONSTRAINT uq_dlq_group_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_group_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dlq_group_signature UNIQUE (tenant_id, signature),
  CONSTRAINT fk_dlq_group_guide FOREIGN KEY (guide_id) REFERENCES ph18_ops.error_guide (id),
  CONSTRAINT ck_dlq_group_signature CHECK (signature ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_group_class CHECK (error_class IN ('TRANSIENT', 'BUSINESS', 'CONTRACT', 'POISON', 'UNKNOWN')),
  CONSTRAINT ck_dlq_group_counts CHECK (open_count >= 0 AND total_count >= open_count),
  CONSTRAINT ck_dlq_group_seen CHECK (last_seen_at >= first_seen_at)
);
CREATE INDEX ix_dlq_group_open ON ph18_ops.dlq_group (tenant_id, open_count DESC) WHERE open_count > 0;
CREATE TRIGGER tg_dlq_group_touch BEFORE UPDATE ON ph18_ops.dlq_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_group_immutable BEFORE UPDATE ON ph18_ops.dlq_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('signature', 'source_code');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_group', false);
COMMENT ON TABLE ph18_ops.dlq_group IS 'EN-18-13 Nhóm dấu hiệu lỗi: băm SHA-256 của (nguồn, luồng, mã lỗi, thông điệp đã chuẩn hóa) để gom mục DLQ giống nhau, đếm mục mở, tổng, lần đầu, lần cuối; gắn hướng dẫn xử lý.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_group CASCADE;

-- @changeset ph18-0230-dlq-message splitStatements:false
CREATE TABLE ph18_ops.dlq_message (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  dlq_key              varchar(255) NOT NULL,
  source_code          varchar(32) NOT NULL,
  source_module        varchar(8) NOT NULL,
  flow_code            varchar(128),
  flow_version         varchar(32),
  stage                varchar(64),
  reason_code          varchar(64) NOT NULL,
  error_code           varchar(16),
  error_class          varchar(12) NOT NULL DEFAULT 'UNKNOWN',
  error_message        varchar(2000),
  attempts             integer NOT NULL DEFAULT 0,
  trace_id             char(32),
  origin_topic         varchar(249),
  origin_partition     integer,
  origin_offset        bigint,
  dlq_partition        integer,
  dlq_offset           bigint,
  external_ref         varchar(128),
  first_failed_at      timestamptz,
  received_at          timestamptz NOT NULL DEFAULT now(),
  status               varchar(16) NOT NULL DEFAULT 'NEW',
  priority             varchar(2) NOT NULL DEFAULT 'P3',
  group_id             uuid,
  assignee             varchar(64),
  missing_context      varchar(32)[] NOT NULL DEFAULT '{}',
  context_headers      jsonb NOT NULL DEFAULT '{}',
  schema_ref           varchar(255),
  payload_location     varchar(10) NOT NULL,
  payload_inline       jsonb,
  payload_content_type varchar(127),
  payload_size_bytes   integer,
  payload_sha256       char(64),
  current_revision_no  integer NOT NULL DEFAULT 0,
  occurrence_count     integer NOT NULL DEFAULT 1,
  last_seen_at         timestamptz NOT NULL DEFAULT now(),
  discard_reason       varchar(2000),
  resolved_at          timestamptz,
  closed_at            timestamptz,
  retention_until      timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_message PRIMARY KEY (id, received_at),
  CONSTRAINT uq_dlq_message_tid UNIQUE (tenant_id, id, received_at),
  CONSTRAINT ck_dlq_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dlq_message_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.dlq_group (tenant_id, id),
  CONSTRAINT ck_dlq_message_status CHECK (status IN ('NEW', 'TRIAGED', 'REPLAY_PENDING', 'REPLAYING', 'RESOLVED', 'REPLAY_FAILED', 'DISCARDED', 'POISON', 'EXPIRED')),
  CONSTRAINT ck_dlq_message_class CHECK (error_class IN ('TRANSIENT', 'BUSINESS', 'CONTRACT', 'POISON', 'UNKNOWN')),
  CONSTRAINT ck_dlq_message_priority CHECK (priority IN ('P1', 'P2', 'P3', 'P4')),
  CONSTRAINT ck_dlq_message_module CHECK (source_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_dlq_message_attempts CHECK (attempts >= 0),
  CONSTRAINT ck_dlq_message_occurrence CHECK (occurrence_count >= 1 AND last_seen_at >= received_at),
  CONSTRAINT ck_dlq_message_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_dlq_message_location CHECK (payload_location IN ('INLINE', 'GARAGE', 'FEDERATED', 'PURGED')),
  CONSTRAINT ck_dlq_message_inline CHECK ((payload_location = 'INLINE') = (payload_inline IS NOT NULL)),
  CONSTRAINT ck_dlq_message_inline_size CHECK (payload_inline IS NULL OR (payload_size_bytes IS NOT NULL AND payload_size_bytes <= 262144)),
  CONSTRAINT ck_dlq_message_sha CHECK (payload_sha256 IS NULL OR payload_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_message_federated CHECK (payload_location <> 'FEDERATED' OR (source_module = 'PH-10' AND external_ref IS NOT NULL)),
  CONSTRAINT ck_dlq_message_poison CHECK (status <> 'POISON' OR cardinality(missing_context) > 0),
  CONSTRAINT ck_dlq_message_discard CHECK (status <> 'DISCARDED' OR coalesce(char_length(btrim(discard_reason)), 0) >= 10),
  CONSTRAINT ck_dlq_message_closed CHECK ((status IN ('RESOLVED', 'DISCARDED', 'EXPIRED')) = (closed_at IS NOT NULL)),
  CONSTRAINT ck_dlq_message_expired CHECK (status <> 'EXPIRED' OR payload_location IN ('PURGED', 'FEDERATED')),
  CONSTRAINT ck_dlq_message_headers CHECK (jsonb_typeof(context_headers) = 'object' AND NOT (context_headers ?| ARRAY['authorization', 'cookie', 'x-api-key']))
) PARTITION BY RANGE (received_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.dlq_message', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_dlq_message_status ON ph18_ops.dlq_message (tenant_id, status, received_at DESC);
CREATE INDEX ix_dlq_message_key ON ph18_ops.dlq_message (tenant_id, dlq_key);
CREATE INDEX ix_dlq_message_source ON ph18_ops.dlq_message (tenant_id, source_code, flow_code, error_code);
CREATE INDEX ix_dlq_message_group ON ph18_ops.dlq_message (tenant_id, group_id) WHERE group_id IS NOT NULL;
CREATE INDEX ix_dlq_message_trace ON ph18_ops.dlq_message (trace_id) WHERE trace_id IS NOT NULL;
CREATE INDEX ix_dlq_message_retention ON ph18_ops.dlq_message (retention_until) WHERE retention_until IS NOT NULL;
CREATE INDEX ix_dlq_message_assignee ON ph18_ops.dlq_message (tenant_id, assignee) WHERE assignee IS NOT NULL AND closed_at IS NULL;
CREATE TRIGGER tg_dlq_message_touch BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_message_immutable BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_key', 'source_code', 'source_module', 'flow_code', 'reason_code', 'first_failed_at', 'received_at', 'origin_topic', 'origin_offset', 'payload_sha256');
CREATE TRIGGER tg_dlq_message_payload BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_dlq_payload_guard();
CREATE TRIGGER tg_dlq_message_fsm_status BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'NEW>TRIAGED,NEW>POISON,NEW>REPLAY_PENDING,NEW>DISCARDED,TRIAGED>REPLAY_PENDING,TRIAGED>DISCARDED,REPLAY_PENDING>REPLAYING,REPLAY_PENDING>TRIAGED,REPLAYING>RESOLVED,REPLAYING>REPLAY_FAILED,REPLAY_FAILED>REPLAY_PENDING,REPLAY_FAILED>DISCARDED,DISCARDED>TRIAGED,POISON>DISCARDED,POISON>TRIAGED,RESOLVED>EXPIRED,DISCARDED>EXPIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_message', false);
COMMENT ON TABLE ph18_ops.dlq_message IS 'EN-18-09 Chỉ mục mục DLQ hợp nhất: hợp đồng ngữ cảnh chuẩn (dh-dlq-reason, dh-dlq-attempts, dh-dlq-stage, dh-dlq-error-code, dh-flow, dh-version, traceparent, dh-tenant, dh-source-ph), lớp lỗi, trạng thái, ưu tiên, nhóm. Payload ≤ 256 KB giữ ở payload_inline (trường nhạy cảm đã mã hóa bằng DEK tenant trước khi vào DLQ), lớn hơn ở Garage (dlq_payload_ref), FEDERATED không sao chép. Payload gốc không sửa; sửa tạo dlq_revision. Phân vùng tháng theo received_at; khử trùng dlqKey qua inbox_event trong 18.dlq.dedup-window-days (7 ngày) và theo mục chưa đóng cùng dlq_key (tăng occurrence_count).';
COMMENT ON COLUMN ph18_ops.dlq_message.payload_inline IS 'Payload gốc ≤ 256 KB (18.dlq.payload.inline-max-kb), trường nhạy cảm đã mã hóa ở PH-04; chỉ được đặt NULL khi dọn (PURGED). Vai readonly không đọc.';
COMMENT ON COLUMN ph18_ops.dlq_message.missing_context IS 'Tên header ngữ cảnh bị thiếu khi tiếp nhận; khác rỗng thì mục vào POISON.';
COMMENT ON COLUMN ph18_ops.dlq_message.occurrence_count IS 'Số lần gặp (BR-18-015): bản tin cùng dlqKey đến khi mục chưa đóng chỉ tăng bộ đếm, không tạo mục mới (ERR-18-105); cập nhật được, không thuộc tg_immutable.';
COMMENT ON COLUMN ph18_ops.dlq_message.last_seen_at IS 'Lần gặp cuối của dlqKey; cập nhật cùng occurrence_count.';
COMMENT ON COLUMN ph18_ops.dlq_message.payload_location IS 'INLINE chỉ cho payload JSON ≤ 18.dlq.payload.inline-max-kb; payload không phải JSON (ERR-18-101) luôn ở GARAGE dạng nhị phân, dù nhỏ.';
COMMENT ON COLUMN ph18_ops.dlq_message.retention_until IS 'Hạn giữ: đóng + 18.dlq.retention.closed-days; mục mở không có hạn.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_message CASCADE;

-- @changeset ph18-0240-dlq-payload-ref splitStatements:false
CREATE TABLE ph18_ops.dlq_payload_ref (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  dlq_id          uuid NOT NULL,
  dlq_received_at timestamptz NOT NULL,
  kind            varchar(10) NOT NULL,
  revision_no     integer NOT NULL DEFAULT 0,
  bucket          varchar(63) NOT NULL,
  object_key      text NOT NULL,
  size_bytes      bigint NOT NULL,
  sha256          char(64) NOT NULL,
  content_type    varchar(127) NOT NULL,
  encrypted       boolean NOT NULL DEFAULT true,
  purged_at       timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_payload_ref PRIMARY KEY (id),
  CONSTRAINT uq_dlq_payload_ref_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_payload_ref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dlq_payload_ref_kind UNIQUE (tenant_id, dlq_id, kind, revision_no),
  CONSTRAINT fk_dlq_payload_ref_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_payload_ref_kind CHECK (kind IN ('ORIGINAL', 'REVISION')),
  CONSTRAINT ck_dlq_payload_ref_revision CHECK ((kind = 'ORIGINAL') = (revision_no = 0)),
  CONSTRAINT ck_dlq_payload_ref_bucket CHECK (bucket = 'dh-' || lower(tenant_id) || '-ops'),
  CONSTRAINT ck_dlq_payload_ref_size CHECK (size_bytes > 0),
  CONSTRAINT ck_dlq_payload_ref_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_payload_ref_encrypted CHECK (encrypted)
);
CREATE TRIGGER tg_dlq_payload_ref_touch BEFORE UPDATE ON ph18_ops.dlq_payload_ref FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_payload_ref_immutable BEFORE UPDATE ON ph18_ops.dlq_payload_ref FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_id', 'kind', 'revision_no', 'bucket', 'object_key', 'sha256', 'size_bytes');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_payload_ref', false);
COMMENT ON TABLE ph18_ops.dlq_payload_ref IS 'EN-18-10 Tham chiếu payload lớn hơn 256 KB ở Garage bucket dh-{tenant}-ops (không phải MinIO): bản gốc hoặc bản sửa, kích thước, SHA-256, mã hóa phía máy chủ. Xóa đối tượng khi mục DLQ hết hạn (purged_at).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_payload_ref CASCADE;

-- @changeset ph18-0250-dlq-revision splitStatements:false
CREATE TABLE ph18_ops.dlq_revision (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  dlq_id              uuid NOT NULL,
  dlq_received_at     timestamptz NOT NULL,
  revision_no         integer NOT NULL,
  payload_location    varchar(10) NOT NULL,
  payload             jsonb,
  payload_sha256      char(64) NOT NULL,
  diff                jsonb NOT NULL,
  reason              text NOT NULL,
  contains_restricted boolean NOT NULL DEFAULT false,
  status              varchar(20) NOT NULL DEFAULT 'DRAFT',
  approved_by         varchar(64),
  approved_at         timestamptz,
  rejected_reason     varchar(1000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_revision PRIMARY KEY (id),
  CONSTRAINT uq_dlq_revision_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_revision_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dlq_revision_no UNIQUE (tenant_id, dlq_id, revision_no),
  CONSTRAINT fk_dlq_revision_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_revision_no CHECK (revision_no >= 1),
  CONSTRAINT ck_dlq_revision_location CHECK (payload_location IN ('INLINE', 'GARAGE')),
  CONSTRAINT ck_dlq_revision_inline CHECK ((payload_location = 'INLINE') = (payload IS NOT NULL)),
  CONSTRAINT ck_dlq_revision_sha CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_revision_diff CHECK (jsonb_typeof(diff) = 'array'),
  CONSTRAINT ck_dlq_revision_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_dlq_revision_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_dlq_revision_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_dlq_revision_restricted CHECK (NOT contains_restricted OR status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'CANCELLED') OR approved_by IS NOT NULL)
);
CREATE TRIGGER tg_dlq_revision_touch BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_revision_immutable BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_id', 'revision_no');
CREATE TRIGGER tg_dlq_revision_frozen BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_frozen('PENDING_APPROVAL,APPROVED,REJECTED', 'payload', 'payload_sha256', 'diff', 'reason', 'contains_restricted');
CREATE TRIGGER tg_dlq_revision_fsm_status BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PENDING_APPROVAL,DRAFT>APPROVED,DRAFT>CANCELLED,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_revision', false);
COMMENT ON TABLE ph18_ops.dlq_revision IS 'EN-18-11 Bản sửa payload có kiểm soát: payload mới (inline hoặc Garage), khác biệt JSON Patch so với bản trước, lý do; có dữ liệu mức Hạn chế thì bốn mắt. Từ PENDING_APPROVAL nội dung bất biến. Phát lại dùng khóa lũy đẳng dlqId:revision.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_revision CASCADE;

-- @changeset ph18-0260-dlq-assignment splitStatements:false
CREATE TABLE ph18_ops.dlq_assignment (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  dlq_id          uuid NOT NULL,
  dlq_received_at timestamptz NOT NULL,
  assignee        varchar(64) NOT NULL,
  assigned_by     varchar(64) NOT NULL,
  assigned_at     timestamptz NOT NULL DEFAULT now(),
  unassigned_at   timestamptz,
  priority        varchar(2) NOT NULL DEFAULT 'P3',
  note            varchar(500),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_assignment PRIMARY KEY (id),
  CONSTRAINT uq_dlq_assignment_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_assignment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dlq_assignment_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_assignment_priority CHECK (priority IN ('P1', 'P2', 'P3', 'P4')),
  CONSTRAINT ck_dlq_assignment_period CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at)
);
CREATE UNIQUE INDEX uq_dlq_assignment_active ON ph18_ops.dlq_assignment (tenant_id, dlq_id) WHERE unassigned_at IS NULL;
CREATE INDEX ix_dlq_assignment_assignee ON ph18_ops.dlq_assignment (tenant_id, assignee) WHERE unassigned_at IS NULL;
CREATE TRIGGER tg_dlq_assignment_touch BEFORE UPDATE ON ph18_ops.dlq_assignment FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_assignment_immutable BEFORE UPDATE ON ph18_ops.dlq_assignment FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_id', 'assignee', 'assigned_by', 'assigned_at');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_assignment', false);
COMMENT ON TABLE ph18_ops.dlq_assignment IS 'EN-18-14 Gán người xử lý mục DLQ: người được gán, người gán, ưu tiên, ghi chú; mỗi mục chỉ một lần gán đang hiệu lực (unassigned_at rỗng). Đồng bộ cột assignee của dlq_message.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_assignment CASCADE;

-- @changeset ph18-0270-replay-job splitStatements:false
CREATE TABLE ph18_ops.replay_job (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  mode              varchar(12) NOT NULL,
  filter            jsonb,
  reason            text NOT NULL,
  total_items       integer NOT NULL,
  succeeded         integer NOT NULL DEFAULT 0,
  failed            integer NOT NULL DEFAULT 0,
  skipped           integer NOT NULL DEFAULT 0,
  rate_per_second   integer NOT NULL DEFAULT 10,
  approval_required boolean NOT NULL DEFAULT false,
  status            varchar(20) NOT NULL DEFAULT 'DRAFT',
  approved_by       varchar(64),
  approved_at       timestamptz,
  rejected_reason   varchar(1000),
  started_at        timestamptz,
  paused_at         timestamptz,
  finished_at       timestamptz,
  cancelled_by      varchar(64),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_replay_job PRIMARY KEY (id),
  CONSTRAINT uq_replay_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_replay_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_replay_job_mode CHECK (mode IN ('SINGLE', 'BATCH_FILTER', 'BATCH_LIST')),
  CONSTRAINT ck_replay_job_single CHECK (mode <> 'SINGLE' OR total_items = 1),
  CONSTRAINT ck_replay_job_filter CHECK (mode <> 'BATCH_FILTER' OR filter IS NOT NULL),
  CONSTRAINT ck_replay_job_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_replay_job_rate CHECK (rate_per_second BETWEEN 1 AND 100),
  CONSTRAINT ck_replay_job_counts CHECK (total_items >= 1 AND succeeded >= 0 AND failed >= 0 AND skipped >= 0 AND succeeded + failed + skipped <= total_items),
  CONSTRAINT ck_replay_job_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'PAUSED', 'COMPLETED', 'PARTIAL', 'FAILED', 'CANCELLED', 'REJECTED')),
  CONSTRAINT ck_replay_job_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_replay_job_approved CHECK (NOT approval_required OR status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'CANCELLED') OR approved_by IS NOT NULL)
);
CREATE INDEX ix_replay_job_status ON ph18_ops.replay_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_replay_job_touch BEFORE UPDATE ON ph18_ops.replay_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_replay_job_immutable BEFORE UPDATE ON ph18_ops.replay_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('mode', 'filter', 'total_items', 'approval_required');
CREATE TRIGGER tg_replay_job_fsm_status BEFORE UPDATE ON ph18_ops.replay_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PENDING_APPROVAL,DRAFT>APPROVED,DRAFT>CANCELLED,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED,APPROVED>RUNNING,APPROVED>CANCELLED,RUNNING>PAUSED,PAUSED>RUNNING,RUNNING>COMPLETED,RUNNING>PARTIAL,RUNNING>FAILED,RUNNING>CANCELLED,PAUSED>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.replay_job', false);
COMMENT ON TABLE ph18_ops.replay_job IS 'EN-18-16 Lượt phát lại đơn hoặc loạt (theo bộ lọc hay danh sách, ≤ 18.dlq.replay.batch-max); vượt 18.dlq.replay.approval-threshold thì bốn mắt; tốc độ giới hạn; tạm dừng, hủy; bộ đếm kết quả. Phát lại luôn qua lối vào của nguồn.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.replay_job CASCADE;

-- @changeset ph18-0280-replay-item splitStatements:false
CREATE TABLE ph18_ops.replay_item (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  job_id            uuid NOT NULL,
  dlq_id            uuid NOT NULL,
  dlq_received_at   timestamptz NOT NULL,
  revision_no       integer NOT NULL DEFAULT 0,
  idempotency_key   varchar(80) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'PENDING',
  replay_trace_id   char(32),
  dispatched_at     timestamptz,
  result_at         timestamptz,
  result_error_code varchar(16),
  result_message    varchar(2000),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_replay_item PRIMARY KEY (id),
  CONSTRAINT uq_replay_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_replay_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_replay_item_dlq UNIQUE (tenant_id, job_id, dlq_id),
  CONSTRAINT fk_replay_item_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph18_ops.replay_job (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_replay_item_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_replay_item_idem CHECK (idempotency_key = dlq_id::text || ':' || revision_no::text),
  CONSTRAINT ck_replay_item_status CHECK (status IN ('PENDING', 'SENT', 'SUCCEEDED', 'FAILED', 'SKIPPED', 'SKIPPED_DUPLICATE', 'CANCELLED')),
  CONSTRAINT ck_replay_item_trace CHECK (replay_trace_id IS NULL OR replay_trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_replay_item_pending ON ph18_ops.replay_item (tenant_id, job_id, status);
CREATE INDEX ix_replay_item_idem ON ph18_ops.replay_item (tenant_id, idempotency_key);
CREATE TRIGGER tg_replay_item_touch BEFORE UPDATE ON ph18_ops.replay_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_replay_item_immutable BEFORE UPDATE ON ph18_ops.replay_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('job_id', 'dlq_id', 'revision_no', 'idempotency_key');
CREATE TRIGGER tg_replay_item_fsm_status BEFORE UPDATE ON ph18_ops.replay_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING>SENT,PENDING>CANCELLED,PENDING>SKIPPED_DUPLICATE,SENT>SUCCEEDED,SENT>FAILED,SENT>SKIPPED_DUPLICATE');
CALL ph18_ops.p_enable_rls('ph18_ops.replay_item', false);
COMMENT ON TABLE ph18_ops.replay_item IS 'EN-18-17 Một mục trong lượt phát lại: mục DLQ, số bản sửa, khóa lũy đẳng dlqId:revision gửi cho nguồn, trạng thái, trace phát lại, kết quả do nguồn báo (callback ops:replay-callback hoặc EVT-10-12).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.replay_item CASCADE;

-- @changeset ph18-0290-dlq-audit splitStatements:false
CREATE TABLE ph18_ops.dlq_audit (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  dlq_id        uuid,
  replay_job_id uuid,
  action        varchar(20) NOT NULL,
  actor         varchar(64) NOT NULL,
  actor_kind    varchar(8) NOT NULL DEFAULT 'USER',
  reason        text,
  before_status varchar(16),
  after_status  varchar(16),
  details       jsonb NOT NULL DEFAULT '{}',
  trace_id      char(32),
  occurred_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_audit PRIMARY KEY (id, occurred_at),
  CONSTRAINT uq_dlq_audit_tid UNIQUE (tenant_id, id, occurred_at),
  CONSTRAINT ck_dlq_audit_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_dlq_audit_action CHECK (action IN ('INGEST', 'VIEW_PAYLOAD', 'TRIAGE', 'ASSIGN', 'REVISE', 'APPROVE_REVISION', 'REPLAY_REQUEST', 'REPLAY_APPROVE', 'REPLAY_RESULT', 'DISCARD', 'REOPEN', 'EXPIRE', 'PURGE', 'EXPORT')),
  CONSTRAINT ck_dlq_audit_actor_kind CHECK (actor_kind IN ('USER', 'SERVICE')),
  CONSTRAINT ck_dlq_audit_reason CHECK (action NOT IN ('VIEW_PAYLOAD', 'DISCARD', 'REOPEN', 'REVISE') OR coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_dlq_audit_target CHECK (dlq_id IS NOT NULL OR replay_job_id IS NOT NULL),
  CONSTRAINT ck_dlq_audit_no_payload CHECK (NOT (details ?| ARRAY['payload', 'payloadInline', 'value']))
) PARTITION BY RANGE (occurred_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.dlq_audit', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_dlq_audit_dlq ON ph18_ops.dlq_audit (tenant_id, dlq_id, occurred_at);
CREATE INDEX ix_dlq_audit_actor ON ph18_ops.dlq_audit (tenant_id, actor, occurred_at);
CREATE TRIGGER tg_dlq_audit_touch BEFORE UPDATE ON ph18_ops.dlq_audit FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_audit_append_only BEFORE UPDATE OR DELETE ON ph18_ops.dlq_audit FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_audit', false);
COMMENT ON TABLE ph18_ops.dlq_audit IS 'EN-18-12 Nhật ký thao tác trên DLQ (xem payload có lý do, phân loại, gán, sửa, duyệt, phát lại, bỏ qua, mở lại, hết hạn, dọn): chỉ thêm, đồng thời gửi PH-13 kiểm toán. Phân vùng tháng theo occurred_at, giữ 18.dlq.audit.retention-months (mặc định 60 tháng). Tham chiếu logic tới dlq_message (không khóa ngoại để nhật ký sống lâu hơn mục).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dlq_audit CASCADE;


-- @file 18-0040-notify.sql
-- @changeset ph18-0300-notification-template splitStatements:false
CREATE TABLE ph18_ops.notification_template (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  template_code     varchar(64) NOT NULL,
  owner_module      varchar(8) NOT NULL,
  title             varchar(255) NOT NULL,
  description       varchar(1000),
  category          varchar(12) NOT NULL,
  channels          varchar(8)[] NOT NULL,
  mandatory         boolean NOT NULL DEFAULT false,
  urgent            boolean NOT NULL DEFAULT false,
  active_version_no integer,
  retired_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_template PRIMARY KEY (id),
  CONSTRAINT uq_notification_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_notification_template_code UNIQUE (tenant_id, template_code),
  CONSTRAINT ck_notification_template_code CHECK (template_code ~ '^[a-z0-9]+(\.[a-z0-9-]+)+$'),
  CONSTRAINT ck_notification_template_module CHECK (owner_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_notification_template_category CHECK (category IN ('TASK', 'JOB_RESULT', 'ALERT', 'INFO')),
  CONSTRAINT ck_notification_template_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['EMAIL', 'SMS', 'IN_APP']::varchar(8)[])
);
CREATE TRIGGER tg_notification_template_touch BEFORE UPDATE ON ph18_ops.notification_template FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_template_immutable BEFORE UPDATE ON ph18_ops.notification_template FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('template_code', 'owner_module');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_template', true);
COMMENT ON TABLE ph18_ops.notification_template IS 'EN-18-19 Mẫu thông báo (thư, SMS, trong ứng dụng) của các PH: mã mẫu, PH sở hữu, nhóm DD-13, thông báo bắt buộc (không tắt bằng tùy chọn), khẩn (bỏ qua giờ yên lặng). Dòng COMMON là mẫu mặc định nền tảng, tenant ghi đè cùng mã. Nội dung ở notification_template_version.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.notification_template CASCADE;

-- @changeset ph18-0310-notification-template-version splitStatements:false
CREATE TABLE ph18_ops.notification_template_version (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  template_id        uuid NOT NULL,
  version_no         integer NOT NULL,
  locale             varchar(8) NOT NULL DEFAULT 'vi',
  email_subject      varchar(255),
  body_text          text,
  body_html          text,
  sms_text           varchar(480),
  in_app_title       varchar(255),
  in_app_link        varchar(500),
  allowed_fields     varchar(64)[] NOT NULL DEFAULT '{}',
  field_check_passed boolean NOT NULL DEFAULT false,
  field_check_report jsonb,
  status             varchar(12) NOT NULL DEFAULT 'DRAFT',
  submitted_at       timestamptz,
  reviewed_by        varchar(64),
  reviewed_at        timestamptz,
  activated_at       timestamptz,
  retired_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_template_version PRIMARY KEY (id),
  CONSTRAINT uq_notification_template_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_template_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_notification_template_version_no UNIQUE (tenant_id, template_id, version_no, locale),
  CONSTRAINT fk_notification_template_version_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph18_ops.notification_template (tenant_id, id),
  CONSTRAINT ck_notification_template_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_notification_template_version_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'ACTIVE', 'RETIRED')),
  CONSTRAINT ck_notification_template_version_content CHECK (body_text IS NOT NULL OR sms_text IS NOT NULL OR in_app_title IS NOT NULL),
  CONSTRAINT ck_notification_template_version_link CHECK (in_app_link IS NULL OR in_app_link ~ '^/[a-z0-9/_{}?=&.-]*$'),
  CONSTRAINT ck_notification_template_version_four_eyes CHECK (reviewed_by IS NULL OR reviewed_by <> created_by),
  CONSTRAINT ck_notification_template_version_active CHECK (status NOT IN ('ACTIVE', 'RETIRED') OR (field_check_passed AND reviewed_by IS NOT NULL AND activated_at IS NOT NULL)),
  CONSTRAINT ck_notification_template_version_no_logic CHECK (coalesce(body_text, '') || coalesce(body_html, '') || coalesce(sms_text, '') !~ '\{\{[#^/>]')
);
CREATE UNIQUE INDEX uq_notification_template_version_active ON ph18_ops.notification_template_version (tenant_id, template_id, locale) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_notification_template_version_touch BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_template_version_immutable BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('template_id', 'version_no', 'locale');
CREATE TRIGGER tg_notification_template_version_frozen BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_frozen('IN_REVIEW,ACTIVE,RETIRED', 'email_subject', 'body_text', 'body_html', 'sms_text', 'in_app_title', 'in_app_link', 'allowed_fields');
CREATE TRIGGER tg_notification_template_version_fsm_status BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>IN_REVIEW,IN_REVIEW>DRAFT,IN_REVIEW>ACTIVE,ACTIVE>RETIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_template_version', true);
COMMENT ON TABLE ph18_ops.notification_template_version IS 'EN-18-20 Phiên bản nội dung mẫu Mustache không logic: tiêu đề thư, thân, SMS, tiêu đề và liên kết trong ứng dụng, danh sách biến cho phép. Duyệt (IN_REVIEW sang ACTIVE) chỉ khi kiểm tra cấm trường mức Hạn chế, Nhạy cảm đạt (FR-00-062); người duyệt khác người soạn. Từ IN_REVIEW nội dung bất biến; mỗi mẫu, ngôn ngữ một bản ACTIVE.';
COMMENT ON COLUMN ph18_ops.notification_template_version.body_text IS 'Mustache không logic: chỉ biến {{ten}} trong allowed_fields; CHECK chặn khối {{#}}, {{^}}, partial {{>}}.';
COMMENT ON COLUMN ph18_ops.notification_template_version.field_check_report IS 'Kết quả kiểm tra cấm trường mức Hạn chế, Nhạy cảm theo PH-09 (FR-00-062).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.notification_template_version CASCADE;

-- @changeset ph18-0320-notification-rule splitStatements:false
CREATE TABLE ph18_ops.notification_rule (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  rule_code        varchar(64) NOT NULL,
  source_module    varchar(8) NOT NULL,
  event_type       varchar(255) NOT NULL,
  condition        jsonb NOT NULL DEFAULT '{}',
  template_code    varchar(64) NOT NULL,
  recipient_kind   varchar(16) NOT NULL,
  recipient_expr   varchar(255) NOT NULL,
  channels         varchar(8)[] NOT NULL,
  create_task_type varchar(64),
  priority         varchar(8) NOT NULL DEFAULT 'NORMAL',
  enabled          boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_rule PRIMARY KEY (id),
  CONSTRAINT uq_notification_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_rule_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_notification_rule_code UNIQUE (tenant_id, rule_code),
  CONSTRAINT ck_notification_rule_module CHECK (source_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_notification_rule_event CHECK (event_type ~ '^[a-z0-9-]+(\.[a-z0-9-]+)+\.v[0-9]+$'),
  CONSTRAINT ck_notification_rule_recipient CHECK (recipient_kind IN ('USER', 'GROUP', 'ROLE', 'SYSTEM_CONTACT', 'EVENT_FIELD', 'ON_CALL')),
  CONSTRAINT ck_notification_rule_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['EMAIL', 'SMS', 'IN_APP']::varchar(8)[]),
  CONSTRAINT ck_notification_rule_priority CHECK (priority IN ('NORMAL', 'URGENT'))
);
CREATE INDEX ix_notification_rule_event ON ph18_ops.notification_rule (event_type) WHERE enabled;
CREATE TRIGGER tg_notification_rule_touch BEFORE UPDATE ON ph18_ops.notification_rule FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_rule_immutable BEFORE UPDATE ON ph18_ops.notification_rule FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('rule_code');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_rule', true);
COMMENT ON TABLE ph18_ops.notification_rule IS 'EN-18-21 Quy tắc thông báo theo sự kiện của các PH (hợp đồng §1.3): loại sự kiện, điều kiện lọc, mẫu, cách phân giải người nhận, kênh, loại việc tạo kèm. Dòng COMMON là quy tắc nền tảng, tenant thêm hoặc tắt.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.notification_rule CASCADE;

-- @changeset ph18-0330-notification-message splitStatements:false
CREATE TABLE ph18_ops.notification_message (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  caller_module       varchar(8) NOT NULL,
  message_key         varchar(128) NOT NULL,
  template_code       varchar(64) NOT NULL,
  template_version_no integer,
  rule_id             uuid,
  source_event_id     varchar(255),
  recipient_ref       jsonb NOT NULL,
  category            varchar(12) NOT NULL,
  channels            varchar(8)[] NOT NULL,
  params              jsonb NOT NULL DEFAULT '{}',
  link                varchar(500),
  mode                varchar(8) NOT NULL DEFAULT 'ASYNC',
  priority            varchar(8) NOT NULL DEFAULT 'NORMAL',
  status              varchar(12) NOT NULL DEFAULT 'QUEUED',
  requested_at        timestamptz NOT NULL DEFAULT now(),
  dispatched_at       timestamptz,
  expires_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_message PRIMARY KEY (id),
  CONSTRAINT uq_notification_message_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_notification_message_key UNIQUE (tenant_id, caller_module, message_key),
  CONSTRAINT fk_notification_message_rule FOREIGN KEY (rule_id) REFERENCES ph18_ops.notification_rule (id),
  CONSTRAINT ck_notification_message_module CHECK (caller_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_notification_message_recipient CHECK (jsonb_typeof(recipient_ref) = 'array' AND jsonb_array_length(recipient_ref) BETWEEN 1 AND 500),
  CONSTRAINT ck_notification_message_category CHECK (category IN ('TASK', 'JOB_RESULT', 'ALERT', 'INFO')),
  CONSTRAINT ck_notification_message_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['EMAIL', 'SMS', 'IN_APP']::varchar(8)[]),
  CONSTRAINT ck_notification_message_params CHECK (jsonb_typeof(params) = 'object' AND NOT (params ?| ARRAY['cccd', 'cmnd', 'so_dinh_danh', 'personal_id', 'bank_account', 'so_tai_khoan'])),
  CONSTRAINT ck_notification_message_link CHECK (link IS NULL OR link ~ '^/[a-z0-9/_{}?=&.-]*$'),
  CONSTRAINT ck_notification_message_mode CHECK (mode IN ('ASYNC', 'SYNC')),
  CONSTRAINT ck_notification_message_priority CHECK (priority IN ('NORMAL', 'URGENT')),
  CONSTRAINT ck_notification_message_status CHECK (status IN ('QUEUED', 'SENT', 'DELIVERED', 'BOUNCED', 'FAILED', 'SUPPRESSED'))
);
CREATE INDEX ix_notification_message_status ON ph18_ops.notification_message (tenant_id, status, requested_at);
CREATE INDEX ix_notification_message_requested ON ph18_ops.notification_message (requested_at);
CREATE TRIGGER tg_notification_message_touch BEFORE UPDATE ON ph18_ops.notification_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_message_immutable BEFORE UPDATE ON ph18_ops.notification_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('caller_module', 'message_key', 'template_code', 'recipient_ref', 'params');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_message', false);
COMMENT ON TABLE ph18_ops.notification_message IS 'EN-18-22 Thông báo logic (outbox của NotificationApi, DD-13): khóa lũy đẳng của bên gọi, mẫu và phiên bản, người nhận recipient_ref (người, nhóm, vai trò, đầu mối HTTT; PH-18 tự phân giải địa chỉ), biến mẫu (CHECK chặn trường định danh), chế độ ASYNC hoặc SYNC (thư mang liên kết, Q01-52), trạng thái tổng hợp từ các lần gửi.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.notification_message CASCADE;

-- @changeset ph18-0340-notification-delivery splitStatements:false
CREATE TABLE ph18_ops.notification_delivery (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  message_id          uuid NOT NULL,
  channel             varchar(8) NOT NULL,
  recipient_user_id   varchar(64),
  recipient_masked    varchar(64),
  recipient_hash      char(64),
  status              varchar(12) NOT NULL DEFAULT 'QUEUED',
  attempts            integer NOT NULL DEFAULT 0,
  provider_message_id varchar(255),
  rendered_title      varchar(255),
  last_error          varchar(1000),
  suppressed_reason   varchar(20),
  queued_at           timestamptz NOT NULL DEFAULT now(),
  sent_at             timestamptz,
  delivered_at        timestamptz,
  bounced_at          timestamptz,
  read_at             timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_delivery PRIMARY KEY (id, queued_at),
  CONSTRAINT uq_notification_delivery_tid UNIQUE (tenant_id, id, queued_at),
  CONSTRAINT ck_notification_delivery_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_notification_delivery_message FOREIGN KEY (tenant_id, message_id) REFERENCES ph18_ops.notification_message (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_notification_delivery_channel CHECK (channel IN ('EMAIL', 'SMS', 'IN_APP')),
  CONSTRAINT ck_notification_delivery_status CHECK (status IN ('QUEUED', 'SENT', 'DELIVERED', 'BOUNCED', 'FAILED', 'SUPPRESSED')),
  CONSTRAINT ck_notification_delivery_attempts CHECK (attempts BETWEEN 0 AND 20),
  CONSTRAINT ck_notification_delivery_recipient CHECK (recipient_user_id IS NOT NULL OR recipient_hash IS NOT NULL),
  CONSTRAINT ck_notification_delivery_hash CHECK (recipient_hash IS NULL OR recipient_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_notification_delivery_in_app CHECK (channel <> 'IN_APP' OR recipient_user_id IS NOT NULL),
  CONSTRAINT ck_notification_delivery_read CHECK (read_at IS NULL OR channel = 'IN_APP'),
  CONSTRAINT ck_notification_delivery_suppressed CHECK ((status = 'SUPPRESSED') = (suppressed_reason IS NOT NULL) AND (suppressed_reason IS NULL OR suppressed_reason IN ('USER_PREF', 'QUIET_HOURS', 'SUPPRESSION_LIST', 'DUPLICATE')))
) PARTITION BY RANGE (queued_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.notification_delivery', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_notification_delivery_message ON ph18_ops.notification_delivery (tenant_id, message_id);
CREATE INDEX ix_notification_delivery_inbox ON ph18_ops.notification_delivery (tenant_id, recipient_user_id, queued_at DESC) WHERE channel = 'IN_APP';
CREATE INDEX ix_notification_delivery_pending ON ph18_ops.notification_delivery (status, queued_at) WHERE status = 'QUEUED';
CREATE TRIGGER tg_notification_delivery_touch BEFORE UPDATE ON ph18_ops.notification_delivery FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_delivery_immutable BEFORE UPDATE ON ph18_ops.notification_delivery FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('message_id', 'channel', 'recipient_user_id', 'recipient_hash');
CREATE TRIGGER tg_notification_delivery_fsm_status BEFORE UPDATE ON ph18_ops.notification_delivery FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>SENT,QUEUED>FAILED,QUEUED>SUPPRESSED,SENT>DELIVERED,SENT>BOUNCED,SENT>FAILED,DELIVERED>BOUNCED');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_delivery', false);
COMMENT ON TABLE ph18_ops.notification_delivery IS 'EN-18-23 Lần gửi theo người nhận và kênh (nhật ký gửi): địa chỉ chỉ lưu dạng che và băm, trạng thái QUEUED sang SENT sang DELIVERED, BOUNCED hoặc FAILED; SUPPRESSED khi tùy chọn người dùng, giờ yên lặng, danh sách chặn. Kênh IN_APP là hộp thông báo DD-13 (read_at). Phân vùng tháng theo queued_at, giữ 18.notify.log-retention-days.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.notification_delivery CASCADE;

-- @changeset ph18-0350-user-notification-pref splitStatements:false
CREATE TABLE ph18_ops.user_notification_pref (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  user_id    varchar(64) NOT NULL,
  category   varchar(12) NOT NULL,
  channel    varchar(8) NOT NULL,
  enabled    boolean NOT NULL DEFAULT true,
  quiet_from time,
  quiet_to   time,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_user_notification_pref PRIMARY KEY (id),
  CONSTRAINT uq_user_notification_pref_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_user_notification_pref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_user_notification_pref UNIQUE (tenant_id, user_id, category, channel),
  CONSTRAINT ck_user_notification_pref_category CHECK (category IN ('TASK', 'JOB_RESULT', 'ALERT', 'INFO')),
  CONSTRAINT ck_user_notification_pref_channel CHECK (channel IN ('EMAIL', 'SMS', 'IN_APP')),
  CONSTRAINT ck_user_notification_pref_quiet CHECK ((quiet_from IS NULL) = (quiet_to IS NULL))
);
CREATE TRIGGER tg_user_notification_pref_touch BEFORE UPDATE ON ph18_ops.user_notification_pref FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.user_notification_pref', false);
COMMENT ON TABLE ph18_ops.user_notification_pref IS 'EN-18-24 Tùy chọn nhận thông báo của người dùng (FR-00-061) theo nhóm và kênh, giờ yên lặng; thông báo bắt buộc và khẩn không bị tắt bằng tùy chọn.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.user_notification_pref CASCADE;

-- @changeset ph18-0360-suppression-entry splitStatements:false
CREATE TABLE ph18_ops.suppression_entry (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  channel          varchar(8) NOT NULL,
  address_hash     char(64) NOT NULL,
  address_masked   varchar(64) NOT NULL,
  reason           varchar(12) NOT NULL,
  bounce_count     integer NOT NULL DEFAULT 1,
  first_bounced_at timestamptz NOT NULL DEFAULT now(),
  last_bounced_at  timestamptz NOT NULL DEFAULT now(),
  released_at      timestamptz,
  released_by      varchar(64),
  released_reason  varchar(500),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_suppression_entry PRIMARY KEY (id),
  CONSTRAINT uq_suppression_entry_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_suppression_entry_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_suppression_entry_channel CHECK (channel IN ('EMAIL', 'SMS')),
  CONSTRAINT ck_suppression_entry_hash CHECK (address_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_suppression_entry_reason CHECK (reason IN ('HARD_BOUNCE', 'COMPLAINT', 'INVALID', 'MANUAL')),
  CONSTRAINT ck_suppression_entry_count CHECK (bounce_count >= 1),
  CONSTRAINT ck_suppression_entry_released CHECK ((released_at IS NULL) = (released_by IS NULL))
);
CREATE UNIQUE INDEX uq_suppression_entry_active ON ph18_ops.suppression_entry (tenant_id, channel, address_hash) WHERE released_at IS NULL;
CREATE TRIGGER tg_suppression_entry_touch BEFORE UPDATE ON ph18_ops.suppression_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_suppression_entry_immutable BEFORE UPDATE ON ph18_ops.suppression_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('channel', 'address_hash');
CALL ph18_ops.p_enable_rls('ph18_ops.suppression_entry', false);
COMMENT ON TABLE ph18_ops.suppression_entry IS 'EN-18-25 Danh sách chặn gửi do thư trả lại cứng, khiếu nại, địa chỉ sai hoặc chặn tay: địa chỉ che và băm, số lần trả lại; thư trả lại phát ops.notification.bounced để PH-01 cập nhật đầu mối. Mỗi địa chỉ một dòng đang hiệu lực.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.suppression_entry CASCADE;


-- @file 18-0050-task.sql
-- @changeset ph18-0370-task-type splitStatements:false
CREATE TABLE ph18_ops.task_type (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  type_code              varchar(64) NOT NULL,
  owner_module           varchar(8) NOT NULL,
  title                  varchar(255) NOT NULL,
  description            varchar(1000),
  default_due_hours      integer,
  reminder_offsets_hours integer[] NOT NULL DEFAULT '{}',
  required_permission    varchar(64) NOT NULL,
  deep_link_pattern      varchar(500) NOT NULL,
  four_eyes              boolean NOT NULL DEFAULT false,
  enabled                boolean NOT NULL DEFAULT true,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_type PRIMARY KEY (id),
  CONSTRAINT uq_task_type_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_task_type_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_task_type_code UNIQUE (tenant_id, type_code),
  CONSTRAINT ck_task_type_code CHECK (type_code ~ '^ph[0-9]{2}\.[a-z0-9-]+$' AND 'PH-' || substr(type_code, 3, 2) = owner_module),
  CONSTRAINT ck_task_type_module CHECK (owner_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_task_type_perm CHECK (required_permission ~ '^PERM-[0-9]{2}-[a-z0-9-]+$'),
  CONSTRAINT ck_task_type_link CHECK (deep_link_pattern ~ '^/[a-z0-9/_{}?=&.-]*$'),
  CONSTRAINT ck_task_type_due CHECK (default_due_hours IS NULL OR default_due_hours BETWEEN 1 AND 8760)
);
CREATE TRIGGER tg_task_type_touch BEFORE UPDATE ON ph18_ops.task_type FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_task_type_immutable BEFORE UPDATE ON ph18_ops.task_type FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('type_code', 'owner_module');
CALL ph18_ops.p_enable_rls('ph18_ops.task_type', true);
COMMENT ON TABLE ph18_ops.task_type IS 'EN-18-26 Loại việc do PH đăng ký qua TaskInboxApi (ph01.approve-onboarding, ph02.review-subscription, ph16.approve-report…): tiêu đề, hạn mặc định, mốc nhắc, quyền cần có, mẫu liên kết sâu, cờ bốn mắt. Dòng COMMON; tenant có thể tắt loại việc bằng dòng riêng.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.task_type CASCADE;

-- @changeset ph18-0380-task-item splitStatements:false
CREATE TABLE ph18_ops.task_item (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  type_id             uuid NOT NULL,
  type_code           varchar(64) NOT NULL,
  task_key            varchar(128) NOT NULL,
  title               varchar(255) NOT NULL,
  subject_ref         varchar(255) NOT NULL,
  assignee_kind       varchar(8) NOT NULL,
  assignee_ref        varchar(128) NOT NULL,
  required_permission varchar(64) NOT NULL,
  requested_by        varchar(64),
  four_eyes           boolean NOT NULL DEFAULT false,
  priority            varchar(8) NOT NULL DEFAULT 'NORMAL',
  status              varchar(12) NOT NULL DEFAULT 'OPEN',
  due_at              timestamptz,
  claimed_by          varchar(64),
  started_at          timestamptz,
  closed_at           timestamptz,
  closed_by           varchar(64),
  outcome             varchar(32),
  link                varchar(500),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_item PRIMARY KEY (id),
  CONSTRAINT uq_task_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_task_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_task_item_key UNIQUE (tenant_id, type_code, task_key),
  CONSTRAINT fk_task_item_type FOREIGN KEY (type_id) REFERENCES ph18_ops.task_type (id),
  CONSTRAINT ck_task_item_assignee CHECK (assignee_kind IN ('USER', 'ROLE', 'GROUP')),
  CONSTRAINT ck_task_item_priority CHECK (priority IN ('NORMAL', 'HIGH', 'URGENT')),
  CONSTRAINT ck_task_item_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_task_item_closed CHECK ((status IN ('DONE', 'CANCELLED', 'EXPIRED')) = (closed_at IS NOT NULL)),
  CONSTRAINT ck_task_item_four_eyes CHECK (NOT four_eyes OR closed_by IS NULL OR closed_by IS DISTINCT FROM requested_by),
  CONSTRAINT ck_task_item_link CHECK (link IS NULL OR link ~ '^/[a-z0-9/_{}?=&.-]*$')
);
CREATE INDEX ix_task_item_inbox ON ph18_ops.task_item (tenant_id, assignee_kind, assignee_ref, status, due_at) WHERE status IN ('OPEN', 'IN_PROGRESS');
CREATE INDEX ix_task_item_due ON ph18_ops.task_item (due_at) WHERE status IN ('OPEN', 'IN_PROGRESS');
CREATE TRIGGER tg_task_item_touch BEFORE UPDATE ON ph18_ops.task_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_task_item_immutable BEFORE UPDATE ON ph18_ops.task_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('type_id', 'type_code', 'task_key', 'requested_by');
CREATE TRIGGER tg_task_item_fsm_status BEFORE UPDATE ON ph18_ops.task_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'OPEN>IN_PROGRESS,OPEN>DONE,OPEN>CANCELLED,OPEN>EXPIRED,IN_PROGRESS>OPEN,IN_PROGRESS>DONE,IN_PROGRESS>CANCELLED,IN_PROGRESS>EXPIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.task_item', false);
COMMENT ON TABLE ph18_ops.task_item IS 'EN-18-27 Việc trong "Việc của tôi" (FR-00-070…072): loại việc, khóa lũy đẳng của PH tạo việc, tiêu đề không chứa dữ liệu Hạn chế, đối tượng, người hoặc vai trò được giao, hạn, trạng thái; việc bốn mắt thì người đóng khác người đề nghị. Phụ thuộc mềm: PH nguồn vẫn giữ hàng đợi duyệt riêng khi PH-18 vắng.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.task_item CASCADE;

-- @changeset ph18-0390-task-reminder splitStatements:false
CREATE TABLE ph18_ops.task_reminder (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  task_id                 uuid NOT NULL,
  kind                    varchar(12) NOT NULL,
  remind_at               timestamptz NOT NULL,
  sent_at                 timestamptz,
  notification_message_id uuid,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_reminder PRIMARY KEY (id),
  CONSTRAINT uq_task_reminder_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_task_reminder_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_task_reminder UNIQUE (tenant_id, task_id, kind, remind_at),
  CONSTRAINT fk_task_reminder_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph18_ops.task_item (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_task_reminder_message FOREIGN KEY (tenant_id, notification_message_id) REFERENCES ph18_ops.notification_message (tenant_id, id),
  CONSTRAINT ck_task_reminder_kind CHECK (kind IN ('BEFORE_DUE', 'OVERDUE', 'ESCALATION'))
);
CREATE INDEX ix_task_reminder_due ON ph18_ops.task_reminder (remind_at) WHERE sent_at IS NULL;
CREATE TRIGGER tg_task_reminder_touch BEFORE UPDATE ON ph18_ops.task_reminder FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.task_reminder', false);
COMMENT ON TABLE ph18_ops.task_reminder IS 'EN-18-28 Lịch nhắc việc: trước hạn, quá hạn, leo thang; thời điểm gửi và thông báo đã tạo. Mỗi việc, loại nhắc, thời điểm một dòng.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.task_reminder CASCADE;

-- @changeset ph18-0400-work-calendar splitStatements:false
CREATE TABLE ph18_ops.work_calendar (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  calendar_code  varchar(32) NOT NULL DEFAULT 'DEFAULT',
  name           varchar(255) NOT NULL,
  timezone       varchar(64) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  working_days   smallint[] NOT NULL DEFAULT '{1,2,3,4,5}',
  work_start     time NOT NULL DEFAULT '07:30',
  work_end       time NOT NULL DEFAULT '17:00',
  inherit_common boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_work_calendar PRIMARY KEY (id),
  CONSTRAINT uq_work_calendar_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_work_calendar_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_work_calendar_code UNIQUE (tenant_id, calendar_code),
  CONSTRAINT ck_work_calendar_days CHECK (cardinality(working_days) BETWEEN 1 AND 7 AND working_days <@ ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  CONSTRAINT ck_work_calendar_hours CHECK (work_end > work_start),
  CONSTRAINT ck_work_calendar_code CHECK (calendar_code ~ '^[A-Z0-9_]+$')
);
CREATE TRIGGER tg_work_calendar_touch BEFORE UPDATE ON ph18_ops.work_calendar FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_work_calendar_immutable BEFORE UPDATE ON ph18_ops.work_calendar FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('calendar_code');
CALL ph18_ops.p_enable_rls('ph18_ops.work_calendar', true);
COMMENT ON TABLE ph18_ops.work_calendar IS 'EN-18-29 Lịch ngày làm việc theo tenant (WorkingCalendarApi, khóa 18.calendar.*): múi giờ, ngày làm việc trong tuần, giờ làm việc; dòng COMMON là lịch quốc gia, tenant kế thừa và bổ sung.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.work_calendar CASCADE;

-- @changeset ph18-0410-calendar-holiday splitStatements:false
CREATE TABLE ph18_ops.calendar_holiday (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  calendar_id  uuid NOT NULL,
  holiday_date date NOT NULL,
  name         varchar(255) NOT NULL,
  kind         varchar(16) NOT NULL DEFAULT 'HOLIDAY',
  legal_basis  varchar(255),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_calendar_holiday PRIMARY KEY (id),
  CONSTRAINT uq_calendar_holiday_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_calendar_holiday_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_calendar_holiday_date UNIQUE (tenant_id, calendar_id, holiday_date),
  CONSTRAINT fk_calendar_holiday_calendar FOREIGN KEY (tenant_id, calendar_id) REFERENCES ph18_ops.work_calendar (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_calendar_holiday_kind CHECK (kind IN ('HOLIDAY', 'COMPENSATORY_OFF', 'WORKING_SWAP'))
);
CREATE TRIGGER tg_calendar_holiday_touch BEFORE UPDATE ON ph18_ops.calendar_holiday FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.calendar_holiday', true);
COMMENT ON TABLE ph18_ops.calendar_holiday IS 'EN-18-30 Ngày lễ, ngày nghỉ bù, ngày làm bù của một lịch; căn cứ pháp lý (thông báo nghỉ lễ). Dòng COMMON cho lịch quốc gia.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.calendar_holiday CASCADE;

-- @changeset ph18-0420-maintenance-window splitStatements:false
CREATE TABLE ph18_ops.maintenance_window (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  window_code            varchar(64) NOT NULL,
  kind                   varchar(12) NOT NULL,
  scope_module           varchar(8),
  environment            varchar(8) NOT NULL DEFAULT 'PROD',
  starts_at              timestamptz NOT NULL,
  ends_at                timestamptz NOT NULL,
  reason                 text NOT NULL,
  announce_template_code varchar(64),
  release_ref            varchar(64),
  status                 varchar(12) NOT NULL DEFAULT 'PLANNED',
  approved_by            varchar(64),
  approved_at            timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_maintenance_window PRIMARY KEY (id),
  CONSTRAINT uq_maintenance_window_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_maintenance_window_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_maintenance_window_code UNIQUE (tenant_id, window_code),
  CONSTRAINT ck_maintenance_window_kind CHECK (kind IN ('MAINTENANCE', 'FREEZE')),
  CONSTRAINT ck_maintenance_window_module CHECK (scope_module IS NULL OR scope_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_maintenance_window_env CHECK (environment IN ('PROD', 'STAGING', 'TEST', 'ALL')),
  CONSTRAINT ck_maintenance_window_period CHECK (ends_at > starts_at),
  CONSTRAINT ck_maintenance_window_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_maintenance_window_status CHECK (status IN ('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_maintenance_window_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_maintenance_window_approved CHECK (status IN ('PLANNED', 'CANCELLED') OR approved_by IS NOT NULL)
);
CREATE INDEX ix_maintenance_window_time ON ph18_ops.maintenance_window (tenant_id, kind, starts_at, ends_at) WHERE status IN ('PLANNED', 'ACTIVE');
CREATE TRIGGER tg_maintenance_window_touch BEFORE UPDATE ON ph18_ops.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_maintenance_window_immutable BEFORE UPDATE ON ph18_ops.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('window_code', 'kind');
CREATE TRIGGER tg_maintenance_window_fsm_status BEFORE UPDATE ON ph18_ops.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PLANNED>ACTIVE,PLANNED>CANCELLED,ACTIVE>COMPLETED,ACTIVE>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.maintenance_window', true);
COMMENT ON TABLE ph18_ops.maintenance_window IS 'EN-18-31 Cửa sổ bảo trì và cửa sổ đóng băng thay đổi (PH-02 đọc cờ đóng băng môi trường thật; PH-04 giữ 04.freeze.windows riêng, đề nghị hợp nhất): phạm vi PH, môi trường, thời gian, lý do, mẫu thông báo, duyệt bốn mắt. Dòng COMMON áp cho mọi tenant (phát hành nền tảng).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.maintenance_window CASCADE;


-- @file 18-0060-incident.sql
-- @changeset ph18-0430-incident splitStatements:false
CREATE TABLE ph18_ops.incident (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  incident_no       varchar(20) NOT NULL,
  title             varchar(255) NOT NULL,
  severity          varchar(4) NOT NULL,
  category          varchar(16) NOT NULL,
  origin            varchar(8) NOT NULL,
  source_event_ref  varchar(255),
  status            varchar(16) NOT NULL DEFAULT 'OPEN',
  commander         varchar(64),
  assignee          varchar(64),
  detected_at       timestamptz NOT NULL DEFAULT now(),
  acknowledged_at   timestamptz,
  mitigated_at      timestamptz,
  resolved_at       timestamptz,
  closed_at         timestamptz,
  has_personal_data boolean NOT NULL DEFAULT false,
  ph09_breach_ref   varchar(64),
  ph09_reported_at  timestamptz,
  impact_summary    text,
  root_cause        text,
  lessons_learned   text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident PRIMARY KEY (id),
  CONSTRAINT uq_incident_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_incident_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_incident_no UNIQUE (tenant_id, incident_no),
  CONSTRAINT ck_incident_no CHECK (incident_no ~ '^INC-[0-9]{4}-[0-9]{6}$'),
  CONSTRAINT ck_incident_severity CHECK (severity IN ('SEV1', 'SEV2', 'SEV3', 'SEV4')),
  CONSTRAINT ck_incident_category CHECK (category IN ('AVAILABILITY', 'DATA_INTEGRITY', 'SECURITY', 'PERFORMANCE', 'OTHER')),
  CONSTRAINT ck_incident_origin CHECK (origin IN ('EVENT', 'MANUAL')),
  CONSTRAINT ck_incident_event CHECK (origin <> 'EVENT' OR source_event_ref IS NOT NULL),
  CONSTRAINT ck_incident_status CHECK (status IN ('OPEN', 'INVESTIGATING', 'MITIGATED', 'RESOLVED', 'CLOSED')),
  CONSTRAINT ck_incident_closed CHECK (status <> 'CLOSED' OR (closed_at IS NOT NULL AND coalesce(char_length(btrim(root_cause)), 0) >= 20 AND coalesce(char_length(btrim(lessons_learned)), 0) >= 20)),
  CONSTRAINT ck_incident_resolved CHECK (status NOT IN ('RESOLVED', 'CLOSED') OR resolved_at IS NOT NULL),
  CONSTRAINT ck_incident_ph09 CHECK (NOT has_personal_data OR status <> 'CLOSED' OR ph09_breach_ref IS NOT NULL)
);
CREATE INDEX ix_incident_open ON ph18_ops.incident (tenant_id, status, severity, detected_at DESC) WHERE status <> 'CLOSED';
CREATE TRIGGER tg_incident_touch BEFORE UPDATE ON ph18_ops.incident FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_incident_immutable BEFORE UPDATE ON ph18_ops.incident FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('incident_no', 'origin', 'detected_at');
CREATE TRIGGER tg_incident_fsm_status BEFORE UPDATE ON ph18_ops.incident FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'OPEN>INVESTIGATING,OPEN>RESOLVED,INVESTIGATING>MITIGATED,INVESTIGATING>RESOLVED,MITIGATED>RESOLVED,MITIGATED>INVESTIGATING,RESOLVED>INVESTIGATING,RESOLVED>CLOSED');
CALL ph18_ops.p_enable_rls('ph18_ops.incident', false);
COMMENT ON TABLE ph18_ops.incident IS 'EN-18-32 Hồ sơ sự cố vận hành mở từ sự kiện (EVT-13-04, 05, DLQ vượt ngưỡng, sao lưu lỗi) hoặc tạo tay: mức độ, nhóm, chỉ huy, người xử lý, mốc thời gian, cờ dữ liệu cá nhân và tham chiếu PH-09 (INCIDENT_PH18, PH-09 giữ đồng hồ 72 giờ), nguyên nhân gốc và bài học khi đóng. Dòng COMMON là sự cố nền tảng.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.incident CASCADE;

-- @changeset ph18-0440-incident-timeline splitStatements:false
CREATE TABLE ph18_ops.incident_timeline (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  incident_id uuid NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  entry_kind  varchar(16) NOT NULL,
  actor       varchar(64) NOT NULL,
  from_status varchar(16),
  to_status   varchar(16),
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident_timeline PRIMARY KEY (id),
  CONSTRAINT uq_incident_timeline_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_incident_timeline_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_incident_timeline_incident FOREIGN KEY (tenant_id, incident_id) REFERENCES ph18_ops.incident (tenant_id, id),
  CONSTRAINT ck_incident_timeline_kind CHECK (entry_kind IN ('STATUS_CHANGE', 'NOTE', 'ASSIGNMENT', 'NOTIFICATION', 'ESCALATION_PH09', 'LINK', 'ACTION')),
  CONSTRAINT ck_incident_timeline_status_change CHECK (entry_kind <> 'STATUS_CHANGE' OR (from_status IS NOT NULL AND to_status IS NOT NULL))
);
CREATE INDEX ix_incident_timeline_incident ON ph18_ops.incident_timeline (tenant_id, incident_id, occurred_at);
CREATE TRIGGER tg_incident_timeline_touch BEFORE UPDATE ON ph18_ops.incident_timeline FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_incident_timeline_append_only BEFORE UPDATE OR DELETE ON ph18_ops.incident_timeline FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.incident_timeline', false);
COMMENT ON TABLE ph18_ops.incident_timeline IS 'EN-18-33 Mốc thời gian của sự cố: đổi trạng thái, ghi chú, gán, thông báo, chuyển PH-09, liên kết, hành động. Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.incident_timeline CASCADE;

-- @changeset ph18-0450-incident-link splitStatements:false
CREATE TABLE ph18_ops.incident_link (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  incident_id   uuid NOT NULL,
  link_kind     varchar(16) NOT NULL,
  target_module varchar(8) NOT NULL,
  target_ref    varchar(255) NOT NULL,
  note          varchar(500),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident_link PRIMARY KEY (id),
  CONSTRAINT uq_incident_link_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_incident_link_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_incident_link UNIQUE (tenant_id, incident_id, link_kind, target_ref),
  CONSTRAINT fk_incident_link_incident FOREIGN KEY (tenant_id, incident_id) REFERENCES ph18_ops.incident (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_incident_link_kind CHECK (link_kind IN ('DLQ_MESSAGE', 'DLQ_GROUP', 'ALERT', 'BACKUP_RUN', 'MIGRATION_RUN', 'TRACE', 'PH09_BREACH', 'EXTERNAL')),
  CONSTRAINT ck_incident_link_module CHECK (target_module ~ '^PH-[0-9]{2}$' OR target_module = 'EXT')
);
CREATE TRIGGER tg_incident_link_touch BEFORE UPDATE ON ph18_ops.incident_link FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.incident_link', false);
COMMENT ON TABLE ph18_ops.incident_link IS 'EN-18-34 Liên kết sự cố với đối tượng: mục DLQ, nhóm lỗi, cảnh báo PH-13, bản sao lưu, lần di trú, trace, hồ sơ vi phạm PH-09, tham chiếu ngoài.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.incident_link CASCADE;


-- @file 18-0070-backup.sql
-- @changeset ph18-0460-backup-object splitStatements:false
CREATE TABLE ph18_ops.backup_object (
  id                         uuid NOT NULL,
  tenant_id                  varchar(16) NOT NULL,
  object_code                varchar(64) NOT NULL,
  name                       varchar(255) NOT NULL,
  object_kind                varchar(20) NOT NULL,
  tool                       varchar(20) NOT NULL,
  schedule                   varchar(64) NOT NULL,
  rpo_minutes                integer,
  rto_minutes                integer,
  retention_days             integer NOT NULL,
  target_location            varchar(255) NOT NULL,
  recovery_tier              varchar(8),
  verification_interval_days integer,
  enabled                    boolean NOT NULL DEFAULT true,
  created_at                 timestamptz NOT NULL DEFAULT now(),
  created_by                 varchar(64) NOT NULL,
  updated_at                 timestamptz NOT NULL DEFAULT now(),
  updated_by                 varchar(64) NOT NULL,
  version                    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_backup_object PRIMARY KEY (id),
  CONSTRAINT uq_backup_object_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_backup_object_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_backup_object_code UNIQUE (tenant_id, object_code),
  CONSTRAINT ck_backup_object_code CHECK (object_code ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  CONSTRAINT ck_backup_object_kind CHECK (object_kind IN ('POSTGRES_BASE', 'POSTGRES_WAL', 'TENANT_EXPORT', 'OBJECT_STORE', 'SECRET_STORE', 'K8S_RESOURCES', 'VOLUME', 'GIT', 'REGISTRY', 'CLICKHOUSE', 'KAFKA_CONFIG', 'AUDIT_WORM', 'OFFLINE_SHARES')),
  CONSTRAINT ck_backup_object_tool CHECK (tool IN ('CNPG_BARMAN', 'DH_TENANT_EXPORT', 'RCLONE', 'OPENBAO_RAFT', 'VELERO', 'VELERO_KOPIA', 'GIT_MIRROR', 'HARBOR_REPLICATION', 'CLICKHOUSE_BACKUP', 'PH13_WORM', 'SHAMIR_OFFLINE')),
  CONSTRAINT ck_backup_object_numbers CHECK ((rpo_minutes IS NULL OR rpo_minutes >= 0) AND (rto_minutes IS NULL OR rto_minutes > 0) AND retention_days >= 0),
  CONSTRAINT ck_backup_object_tier CHECK (recovery_tier IS NULL OR recovery_tier ~ '^TPH-[0-9]$'),
  CONSTRAINT ck_backup_object_location CHECK (target_location !~ '://[^/]*@')
);
CREATE TRIGGER tg_backup_object_touch BEFORE UPDATE ON ph18_ops.backup_object FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_backup_object_immutable BEFORE UPDATE ON ph18_ops.backup_object FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('object_code');
CALL ph18_ops.p_enable_rls('ph18_ops.backup_object', false);
COMMENT ON TABLE ph18_ops.backup_object IS 'EN-18-35 Đối tượng sao lưu theo D03-09 §8.2 (PostgreSQL cơ sở và WAL qua CNPG Barman Cloud, xuất logic theo tenant dh-tenant-export, Garage rclone, OpenBao Raft, Velero, ClickHouse, WORM kiểm toán…): công cụ, lịch, RPO, RTO, thời gian giữ, nơi lưu (chỉ tên kho, không thông tin xác thực), tầng phục hồi. Dòng COMMON là đối tượng cụm.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.backup_object CASCADE;

-- @changeset ph18-0470-backup-run splitStatements:false
CREATE TABLE ph18_ops.backup_run (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  object_id     uuid NOT NULL,
  run_ref       varchar(255) NOT NULL,
  started_at    timestamptz NOT NULL,
  finished_at   timestamptz,
  status        varchar(12) NOT NULL,
  size_bytes    bigint,
  location      varchar(500),
  checksum      char(64),
  error_message varchar(2000),
  collector     varchar(32) NOT NULL,
  collected_at  timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_backup_run PRIMARY KEY (id),
  CONSTRAINT uq_backup_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_backup_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_backup_run_ref UNIQUE (tenant_id, object_id, run_ref),
  CONSTRAINT fk_backup_run_object FOREIGN KEY (tenant_id, object_id) REFERENCES ph18_ops.backup_object (tenant_id, id),
  CONSTRAINT ck_backup_run_status CHECK (status IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED', 'EXPIRED')),
  CONSTRAINT ck_backup_run_finished CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT ck_backup_run_period CHECK (finished_at IS NULL OR finished_at >= started_at),
  CONSTRAINT ck_backup_run_failed CHECK (status <> 'FAILED' OR error_message IS NOT NULL),
  CONSTRAINT ck_backup_run_sha CHECK (checksum IS NULL OR checksum ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_backup_run_collector CHECK (collector IN ('CNPG', 'VELERO', 'RCLONE', 'OPENBAO', 'DH_TENANT_EXPORT', 'CLICKHOUSE', 'MANUAL'))
);
CREATE INDEX ix_backup_run_object ON ph18_ops.backup_run (tenant_id, object_id, started_at DESC);
CREATE TRIGGER tg_backup_run_touch BEFORE UPDATE ON ph18_ops.backup_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_backup_run_immutable BEFORE UPDATE ON ph18_ops.backup_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('object_id', 'run_ref', 'started_at');
CALL ph18_ops.p_enable_rls('ph18_ops.backup_run', false);
COMMENT ON TABLE ph18_ops.backup_run IS 'EN-18-36 Bản sao lưu thu từ nguồn (CNPG Backup CR, Velero Backup, nhật ký rclone, snapshot OpenBao, kết quả dh-tenant-export): mã bản ở nguồn, thời gian, trạng thái, kích thước, vị trí, tổng kiểm tra, lỗi. Lỗi phát sự kiện để mở sự cố và thông báo.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.backup_run CASCADE;

-- @changeset ph18-0480-restore-verification splitStatements:false
CREATE TABLE ph18_ops.restore_verification (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  object_id        uuid NOT NULL,
  backup_run_id    uuid,
  verified_at      timestamptz NOT NULL DEFAULT now(),
  method           varchar(20) NOT NULL,
  outcome          varchar(8) NOT NULL,
  duration_seconds integer NOT NULL,
  rto_met          boolean,
  rows_checked     bigint,
  details          jsonb NOT NULL DEFAULT '{}',
  job_ref          varchar(128),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_restore_verification PRIMARY KEY (id),
  CONSTRAINT uq_restore_verification_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_restore_verification_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_restore_verification_object FOREIGN KEY (tenant_id, object_id) REFERENCES ph18_ops.backup_object (tenant_id, id),
  CONSTRAINT fk_restore_verification_backup_run FOREIGN KEY (tenant_id, backup_run_id) REFERENCES ph18_ops.backup_run (tenant_id, id),
  CONSTRAINT ck_restore_verification_method CHECK (method IN ('RESTORE_LATEST', 'PITR_RANDOM', 'TENANT_IMPORT', 'SAMPLE_FILES', 'HASH_CHAIN')),
  CONSTRAINT ck_restore_verification_outcome CHECK (outcome IN ('PASSED', 'FAILED')),
  CONSTRAINT ck_restore_verification_duration CHECK (duration_seconds >= 0)
);
CREATE INDEX ix_restore_verification_object ON ph18_ops.restore_verification (tenant_id, object_id, verified_at DESC);
CREATE TRIGGER tg_restore_verification_touch BEFORE UPDATE ON ph18_ops.restore_verification FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_restore_verification_append_only BEFORE UPDATE OR DELETE ON ph18_ops.restore_verification FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.restore_verification', false);
COMMENT ON TABLE ph18_ops.restore_verification IS 'EN-18-37 Kết quả kiểm tra khôi phục tự động (điều kiện 0 lỗi của 3-2-1-1-0): đối tượng, bản sao lưu, phương pháp, kết quả, thời lượng, đạt RTO, số dòng kiểm. Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.restore_verification CASCADE;

-- @changeset ph18-0490-tenant-restore-request splitStatements:false
CREATE TABLE ph18_ops.tenant_restore_request (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  request_no          varchar(24) NOT NULL,
  restore_point       timestamptz NOT NULL,
  scope               varchar(12) NOT NULL,
  schemas             varchar(32)[] NOT NULL DEFAULT '{}',
  reason              text NOT NULL,
  status              varchar(20) NOT NULL DEFAULT 'DRAFT',
  requested_by        varchar(64) NOT NULL,
  approved_by         varchar(64),
  approved_at         timestamptz,
  rejected_reason     varchar(1000),
  current_step        smallint NOT NULL DEFAULT 0,
  estimated_size_gb   numeric(10,2),
  job_name            varchar(128),
  heartbeat_at        timestamptz,
  checkpoint          jsonb,
  tenant_suspended_at timestamptz,
  tenant_resumed_at   timestamptz,
  started_at          timestamptz,
  finished_at         timestamptz,
  rows_replaced       bigint,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_restore_request PRIMARY KEY (id),
  CONSTRAINT uq_tenant_restore_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_restore_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_restore_request_no UNIQUE (tenant_id, request_no),
  CONSTRAINT ck_tenant_restore_request_scope CHECK (scope IN ('FULL_TENANT', 'SCHEMAS')),
  CONSTRAINT ck_tenant_restore_request_schemas CHECK ((scope = 'SCHEMAS') = (cardinality(schemas) > 0)),
  CONSTRAINT ck_tenant_restore_request_schema_names CHECK (schemas <@ ARRAY['ph01_onboarding', 'ph02_catalog', 'ph03_gateway', 'ph04', 'ph05_adapter', 'ph06_mdm', 'ph07_rdm', 'ph08_dq', 'ph09_privacy', 'ph10_event', 'ph11_bpm', 'ph11_flowable', 'ph14_national', 'ph15_portal', 'ph16_kpi', 'ph17_assist', 'ph18_ops']::varchar(32)[]),
  CONSTRAINT ck_tenant_restore_request_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 20),
  CONSTRAINT ck_tenant_restore_request_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'ROLLED_BACK', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_tenant_restore_request_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_tenant_restore_request_approved CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'CANCELLED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_tenant_restore_request_step CHECK (current_step BETWEEN 0 AND 8),
  CONSTRAINT ck_tenant_restore_request_point CHECK (restore_point < created_at)
);
CREATE UNIQUE INDEX uq_tenant_restore_request_active ON ph18_ops.tenant_restore_request (tenant_id) WHERE status IN ('PENDING_APPROVAL', 'APPROVED', 'RUNNING');
CREATE TRIGGER tg_tenant_restore_request_touch BEFORE UPDATE ON ph18_ops.tenant_restore_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_tenant_restore_request_immutable BEFORE UPDATE ON ph18_ops.tenant_restore_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('request_no', 'restore_point', 'scope', 'schemas', 'requested_by');
CREATE TRIGGER tg_tenant_restore_request_fsm_status BEFORE UPDATE ON ph18_ops.tenant_restore_request FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PENDING_APPROVAL,DRAFT>CANCELLED,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED,APPROVED>RUNNING,APPROVED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>FAILED,RUNNING>ROLLED_BACK,FAILED>ROLLED_BACK');
CALL ph18_ops.p_enable_rls('ph18_ops.tenant_restore_request', false);
COMMENT ON TABLE ph18_ops.tenant_restore_request IS 'EN-18-38 Yêu cầu khôi phục một tenant (RBK-04, D03-09 §8.5): thời điểm đích, phạm vi (toàn tenant hay một số schema), lý do; TA tạo, PA duyệt bốn mắt; dh-tenant-restore chạy tám bước, tenant SUSPENDED khi thay, phát ops.tenant.restored; mục tiêu ≤ 4 giờ cho tenant ≤ 200 GB. Mỗi tenant một yêu cầu đang hoạt động.';
COMMENT ON COLUMN ph18_ops.tenant_restore_request.schemas IS 'Schema thuộc phạm vi khi scope = SCHEMAS; không gồm schema kiểm toán ph13 (kiểm toán không khôi phục về quá khứ, D03-09 §8.5 bước 7).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.tenant_restore_request CASCADE;

-- @changeset ph18-0500-tenant-restore-step splitStatements:false
CREATE TABLE ph18_ops.tenant_restore_step (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  request_id    uuid NOT NULL,
  step_no       smallint NOT NULL,
  step_code     varchar(24) NOT NULL,
  status        varchar(12) NOT NULL DEFAULT 'PENDING',
  started_at    timestamptz,
  finished_at   timestamptz,
  rows_affected bigint,
  message       varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_restore_step PRIMARY KEY (id),
  CONSTRAINT uq_tenant_restore_step_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_restore_step_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_restore_step_no UNIQUE (tenant_id, request_id, step_no),
  CONSTRAINT fk_tenant_restore_step_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph18_ops.tenant_restore_request (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_tenant_restore_step_code CHECK ((step_no, step_code) IN ((1, 'APPROVAL'), (2, 'BUILD_TEMP_CLUSTER'), (3, 'EXTRACT_TENANT'), (4, 'SUSPEND_TENANT'), (5, 'REPLACE_DATA'), (6, 'RESTORE_OTHER_STORES'), (7, 'AUDIT_RECORD'), (8, 'VERIFY_AND_REOPEN'))),
  CONSTRAINT ck_tenant_restore_step_status CHECK (status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED', 'ROLLED_BACK')),
  CONSTRAINT ck_tenant_restore_step_period CHECK (finished_at IS NULL OR (started_at IS NOT NULL AND finished_at >= started_at))
);
CREATE TRIGGER tg_tenant_restore_step_touch BEFORE UPDATE ON ph18_ops.tenant_restore_step FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_tenant_restore_step_immutable BEFORE UPDATE ON ph18_ops.tenant_restore_step FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('request_id', 'step_no', 'step_code');
CALL ph18_ops.p_enable_rls('ph18_ops.tenant_restore_step', false);
COMMENT ON TABLE ph18_ops.tenant_restore_step IS 'EN-18-39 Một trong tám bước của dh-tenant-restore (D03-09 §8.5): phê duyệt, dựng cụm tạm, trích dữ liệu, đặt tenant bảo trì, thay thế, kho khác, ghi kiểm toán, kiểm tra và mở lại; trạng thái, thời gian, số dòng.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.tenant_restore_step CASCADE;

-- @changeset ph18-0510-tenant-export-job splitStatements:false
CREATE TABLE ph18_ops.tenant_export_job (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  purpose             varchar(24) NOT NULL,
  requested_by_module varchar(8) NOT NULL DEFAULT 'PH-20',
  ph20_request_ref    varchar(64),
  export_format       varchar(8) NOT NULL DEFAULT 'PG_COPY',
  modules             varchar(8)[] NOT NULL DEFAULT '{}',
  status              varchar(24) NOT NULL DEFAULT 'QUEUED',
  output_location     varchar(500),
  sha256              char(64),
  size_bytes          bigint,
  expires_at          timestamptz,
  started_at          timestamptz,
  finished_at         timestamptz,
  job_name            varchar(128),
  heartbeat_at        timestamptz,
  checkpoint          jsonb,
  error_message       varchar(2000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_export_job PRIMARY KEY (id),
  CONSTRAINT uq_tenant_export_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_export_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_export_job_purpose CHECK (purpose IN ('HANDOVER', 'CELL_MOVE', 'DEDICATED_DB', 'ARCHIVE')),
  CONSTRAINT ck_tenant_export_job_module CHECK (requested_by_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_tenant_export_job_format CHECK (export_format IN ('PG_COPY', 'PG_DUMP')),
  CONSTRAINT ck_tenant_export_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_tenant_export_job_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_tenant_export_job_done CHECK (status <> 'SUCCEEDED' OR (output_location IS NOT NULL AND sha256 IS NOT NULL))
);
CREATE INDEX ix_tenant_export_job_status ON ph18_ops.tenant_export_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_tenant_export_job_touch BEFORE UPDATE ON ph18_ops.tenant_export_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_tenant_export_job_immutable BEFORE UPDATE ON ph18_ops.tenant_export_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('purpose', 'export_format');
CREATE TRIGGER tg_tenant_export_job_fsm_status BEFORE UPDATE ON ph18_ops.tenant_export_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,RUNNING>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.tenant_export_job', false);
COMMENT ON TABLE ph18_ops.tenant_export_job IS 'EN-18-40 Lần xuất dữ liệu tenant bằng dh-tenant-export: bàn giao khi DECOMMISSIONED, chuyển ô CSDL, SHARED sang DEDICATED_DB, sáp nhập (PH-20 gọi) hoặc theo yêu cầu; định dạng, phân hệ, tệp ra ở kho sao lưu, tổng kiểm tra, hạn tải.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.tenant_export_job CASCADE;

-- @changeset ph18-0520-dr-drill splitStatements:false
CREATE TABLE ph18_ops.dr_drill (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  drill_code           varchar(32) NOT NULL,
  drill_kind           varchar(20) NOT NULL,
  scheduled_at         timestamptz,
  performed_at         timestamptz NOT NULL,
  performed_by         varchar(64) NOT NULL,
  outcome              varchar(8) NOT NULL,
  rpo_achieved_minutes integer,
  rto_achieved_minutes integer,
  findings             text,
  actions              text,
  report_ref           varchar(255),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dr_drill PRIMARY KEY (id),
  CONSTRAINT uq_dr_drill_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dr_drill_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_dr_drill_code UNIQUE (tenant_id, drill_code),
  CONSTRAINT ck_dr_drill_kind CHECK (drill_kind IN ('DR_SWITCHOVER', 'RBK_03', 'PITR_CLUSTER', 'TABLETOP')),
  CONSTRAINT ck_dr_drill_outcome CHECK (outcome IN ('PASSED', 'PASSED_WITH_ISSUES', 'FAILED')),
  CONSTRAINT ck_dr_drill_findings CHECK (outcome = 'PASSED' OR coalesce(char_length(btrim(findings)), 0) >= 20)
);
CREATE TRIGGER tg_dr_drill_touch BEFORE UPDATE ON ph18_ops.dr_drill FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dr_drill_immutable BEFORE UPDATE ON ph18_ops.dr_drill FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('drill_code', 'drill_kind', 'performed_at');
CALL ph18_ops.p_enable_rls('ph18_ops.dr_drill', false);
COMMENT ON TABLE ph18_ops.dr_drill IS 'EN-18-41 Ghi nhận diễn tập DR và PITR toàn cụm (PA thực hiện ngoài ứng dụng, PH-18 chỉ ghi nhận): loại, thời điểm, kết quả, RPO và RTO đạt được, phát hiện, hành động khắc phục, biên bản ở kho tài liệu.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.dr_drill CASCADE;

-- @changeset ph18-0530-merge-transfer splitStatements:false
CREATE TABLE ph18_ops.merge_transfer (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  merge_plan_id    varchar(64) NOT NULL,
  module           varchar(8) NOT NULL,
  source_tenant    varchar(16) NOT NULL,
  target_tenant    varchar(16) NOT NULL,
  mapping_ref      varchar(255) NOT NULL,
  dry_run          boolean NOT NULL DEFAULT true,
  status           varchar(24) NOT NULL DEFAULT 'QUEUED',
  progress_percent numeric(5,2) NOT NULL DEFAULT 0,
  rows_total       bigint,
  rows_copied      bigint NOT NULL DEFAULT 0,
  rows_skipped     bigint NOT NULL DEFAULT 0,
  rows_failed      bigint NOT NULL DEFAULT 0,
  export_job_id    uuid,
  job_name         varchar(128),
  heartbeat_at     timestamptz,
  checkpoint       jsonb,
  started_at       timestamptz,
  finished_at      timestamptz,
  last_reported_at timestamptz,
  report_status    varchar(16) NOT NULL DEFAULT 'PENDING',
  error_message    varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_merge_transfer PRIMARY KEY (id),
  CONSTRAINT uq_merge_transfer_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_merge_transfer_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_merge_transfer_export_job FOREIGN KEY (tenant_id, export_job_id) REFERENCES ph18_ops.tenant_export_job (tenant_id, id),
  CONSTRAINT ck_merge_transfer_module CHECK (module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_merge_transfer_tenants CHECK (source_tenant ~ '^T[0-9]{2}$' AND target_tenant = tenant_id AND source_tenant <> target_tenant),
  CONSTRAINT ck_merge_transfer_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_merge_transfer_progress CHECK (progress_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_merge_transfer_rows CHECK (rows_copied >= 0 AND rows_skipped >= 0 AND rows_failed >= 0 AND (rows_total IS NULL OR rows_copied + rows_skipped + rows_failed <= rows_total)),
  CONSTRAINT ck_merge_transfer_report CHECK (report_status IN ('PENDING', 'REPORTED', 'REPORT_FAILED')),
  CONSTRAINT ck_merge_transfer_done CHECK (status <> 'SUCCEEDED' OR progress_percent = 100)
);
CREATE UNIQUE INDEX uq_merge_transfer_real ON ph18_ops.merge_transfer (tenant_id, merge_plan_id, module) WHERE NOT dry_run AND status NOT IN ('FAILED', 'CANCELLED');
CREATE INDEX ix_merge_transfer_plan ON ph18_ops.merge_transfer (tenant_id, merge_plan_id);
CREATE TRIGGER tg_merge_transfer_touch BEFORE UPDATE ON ph18_ops.merge_transfer FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_merge_transfer_immutable BEFORE UPDATE ON ph18_ops.merge_transfer FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('merge_plan_id', 'module', 'source_tenant', 'target_tenant', 'mapping_ref', 'dry_run');
CREATE TRIGGER tg_merge_transfer_fsm_status BEFORE UPDATE ON ph18_ops.merge_transfer FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,RUNNING>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.merge_transfer', false);
COMMENT ON TABLE ph18_ops.merge_transfer IS 'EN-18-55 Chuyển dữ liệu một phân hệ khi sáp nhập tenant (hợp đồng PH-20, BRIEF §7): PH-20 gọi POST /api/ops/v1/merge-transfers với mergePlanId, module, sourceTenant, targetTenant, mappingRef, dryRun; worker dh-tenant-export và nạp giữ id gốc, ghi origin_tenant_id ở PH đích; PH-18 báo tiến độ về PH-20 (participants/{module}:report). Dòng thuộc tenant đích. Mỗi kế hoạch, phân hệ chỉ một lần chạy thật đang hoạt động hoặc đã xong.';
COMMENT ON COLUMN ph18_ops.merge_transfer.mapping_ref IS 'Tham chiếu bảng ánh xạ mã của kế hoạch sáp nhập do PH-20 giữ (không chép nội dung).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.merge_transfer CASCADE;


-- @file 18-0080-migration.sql
-- @changeset ph18-0540-legacy-source splitStatements:false
CREATE TABLE ph18_ops.legacy_source (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  source_code        varchar(32) NOT NULL,
  name               varchar(255) NOT NULL,
  system_kind        varchar(12) NOT NULL,
  jdbc_url           varchar(500) NOT NULL,
  credential_ref     varchar(255) NOT NULL,
  read_only_verified boolean NOT NULL DEFAULT false,
  verified_at        timestamptz,
  status             varchar(12) NOT NULL DEFAULT 'DRAFT',
  owner              varchar(64) NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_source PRIMARY KEY (id),
  CONSTRAINT uq_legacy_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_legacy_source_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_legacy_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_legacy_source_kind CHECK (system_kind IN ('BUS', 'TOOLING', 'HUB', 'APIM', 'AITA', 'PAYGOV', 'NGSP', 'OTHER')),
  CONSTRAINT ck_legacy_source_jdbc CHECK (jdbc_url ~ '^jdbc:(postgresql|mysql|mariadb|oracle|sqlserver):' AND jdbc_url !~* '(user|pass)[a-z]*=' AND jdbc_url !~ '//[^/]*@'),
  CONSTRAINT ck_legacy_source_vault CHECK (credential_ref ~ ('^kv/dh/' || lower(tenant_id) || '/')),
  CONSTRAINT ck_legacy_source_status CHECK (status IN ('DRAFT', 'VERIFIED', 'DISABLED')),
  CONSTRAINT ck_legacy_source_verified CHECK (status <> 'VERIFIED' OR (read_only_verified AND verified_at IS NOT NULL))
);
CREATE TRIGGER tg_legacy_source_touch BEFORE UPDATE ON ph18_ops.legacy_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_legacy_source_immutable BEFORE UPDATE ON ph18_ops.legacy_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('source_code');
CALL ph18_ops.p_enable_rls('ph18_ops.legacy_source', false);
COMMENT ON TABLE ph18_ops.legacy_source IS 'EN-18-42 Nguồn hệ cũ (IF-07): loại hệ (Bus, Tooling, Hub, APIM, Danh mục Aita, PayGov, NGSP), URL JDBC không kèm thông tin đăng nhập, tham chiếu bí mật OpenBao kv/dh/{tenant}/..., xác nhận kết nối chỉ đọc. Thông tin xác thực không di trú (FR-00-093).';
COMMENT ON COLUMN ph18_ops.legacy_source.credential_ref IS 'Đường dẫn OpenBao kv/dh/{tenant}/migration/{nguồn}; PH-18 không lưu giá trị.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.legacy_source CASCADE;

-- @changeset ph18-0550-migration-plan splitStatements:false
CREATE TABLE ph18_ops.migration_plan (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  plan_code           varchar(32) NOT NULL,
  legacy_source_id    uuid NOT NULL,
  title               varchar(255) NOT NULL,
  description         text,
  status              varchar(8) NOT NULL DEFAULT 'DRAFT',
  ready_at            timestamptz,
  ready_by            varchar(64),
  target_cutover_date date,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_plan PRIMARY KEY (id),
  CONSTRAINT uq_migration_plan_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_plan_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_plan_code UNIQUE (tenant_id, plan_code),
  CONSTRAINT fk_migration_plan_legacy_source FOREIGN KEY (tenant_id, legacy_source_id) REFERENCES ph18_ops.legacy_source (tenant_id, id),
  CONSTRAINT ck_migration_plan_status CHECK (status IN ('DRAFT', 'READY')),
  CONSTRAINT ck_migration_plan_ready CHECK (status <> 'READY' OR (ready_at IS NOT NULL AND ready_by IS NOT NULL))
);
CREATE TRIGGER tg_migration_plan_touch BEFORE UPDATE ON ph18_ops.migration_plan FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_plan_immutable BEFORE UPDATE ON ph18_ops.migration_plan FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('plan_code', 'legacy_source_id');
CREATE TRIGGER tg_migration_plan_fsm_status BEFORE UPDATE ON ph18_ops.migration_plan FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>READY,READY>DRAFT');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_plan', false);
COMMENT ON TABLE ph18_ops.migration_plan IS 'EN-18-43 Kế hoạch di trú một nguồn: các loại đối tượng theo thứ tự phụ thuộc (danh mục, HTTT, API, gói, đăng ký, topic, luồng, giao dịch), ngày cắt chuyển dự kiến. DRAFT sang READY khi đủ mục và nguồn đã xác minh.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.migration_plan CASCADE;

-- @changeset ph18-0560-migration-plan-item splitStatements:false
CREATE TABLE ph18_ops.migration_plan_item (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  plan_id          uuid NOT NULL,
  seq_no           integer NOT NULL,
  object_kind      varchar(12) NOT NULL,
  target_module    varchar(8) NOT NULL,
  converter_code   varchar(64) NOT NULL,
  source_query_ref varchar(255) NOT NULL,
  target_api       varchar(16) NOT NULL,
  depends_on       varchar(12)[] NOT NULL DEFAULT '{}',
  batch_size       integer NOT NULL DEFAULT 500,
  enabled          boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_plan_item PRIMARY KEY (id),
  CONSTRAINT uq_migration_plan_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_plan_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_plan_item_seq UNIQUE (tenant_id, plan_id, seq_no),
  CONSTRAINT uq_migration_plan_item_kind UNIQUE (tenant_id, plan_id, object_kind),
  CONSTRAINT fk_migration_plan_item_plan FOREIGN KEY (tenant_id, plan_id) REFERENCES ph18_ops.migration_plan (tenant_id, id),
  CONSTRAINT ck_migration_plan_item_kind CHECK (object_kind IN ('CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION')),
  CONSTRAINT ck_migration_plan_item_target CHECK ((object_kind = 'CATALOG' AND target_module = 'PH-07') OR (object_kind = 'SYSTEM' AND target_module = 'PH-01') OR (object_kind IN ('API', 'PLAN', 'SUBSCRIPTION') AND target_module IN ('PH-02', 'PH-03')) OR (object_kind IN ('TOPIC', 'PUBLISHER', 'SUBSCRIBER') AND target_module = 'PH-10') OR (object_kind = 'FLOW' AND target_module = 'PH-04') OR (object_kind = 'TRANSACTION' AND target_module = 'PH-19')),
  CONSTRAINT ck_migration_plan_item_api CHECK (target_api ~ '^API-[0-9]{2}-[0-9]{3}$' AND substr(target_api, 5, 2) = substr(target_module, 4, 2)),
  CONSTRAINT ck_migration_plan_item_depends CHECK (depends_on <@ ARRAY['CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION']::varchar(12)[] AND NOT (object_kind = ANY (depends_on))),
  CONSTRAINT ck_migration_plan_item_batch CHECK (batch_size BETWEEN 1 AND 10000)
);
CREATE TRIGGER tg_migration_plan_item_touch BEFORE UPDATE ON ph18_ops.migration_plan_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_plan_item_immutable BEFORE UPDATE ON ph18_ops.migration_plan_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('plan_id', 'object_kind', 'target_module');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_plan_item', false);
COMMENT ON TABLE ph18_ops.migration_plan_item IS 'EN-18-44 Mục kế hoạch theo loại đối tượng: PH đích đúng cặp (CATALOG sang PH-07, SYSTEM sang PH-01, API, PLAN, SUBSCRIPTION sang PH-02 hoặc PH-03, TOPIC, PUBLISHER, SUBSCRIBER sang PH-10, FLOW sang PH-04 nháp, TRANSACTION sang PH-19 API nhập), bộ chuyển, truy vấn nguồn đóng gói, API nhập của PH đích, phụ thuộc, cỡ lô.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.migration_plan_item CASCADE;

-- @changeset ph18-0570-migration-run splitStatements:false
CREATE TABLE ph18_ops.migration_run (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  plan_id         uuid NOT NULL,
  run_no          integer NOT NULL,
  run_mode        varchar(8) NOT NULL,
  status          varchar(24) NOT NULL,
  requested_by    varchar(64) NOT NULL,
  approved_by     varchar(64),
  approved_at     timestamptz,
  rerun_of_run_id uuid,
  job_name        varchar(128),
  heartbeat_at    timestamptz,
  checkpoint      jsonb,
  started_at      timestamptz,
  finished_at     timestamptz,
  items_total     integer NOT NULL DEFAULT 0,
  items_succeeded integer NOT NULL DEFAULT 0,
  items_failed    integer NOT NULL DEFAULT 0,
  items_skipped   integer NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_run PRIMARY KEY (id),
  CONSTRAINT uq_migration_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_run_no UNIQUE (tenant_id, plan_id, run_no),
  CONSTRAINT fk_migration_run_plan FOREIGN KEY (tenant_id, plan_id) REFERENCES ph18_ops.migration_plan (tenant_id, id),
  CONSTRAINT fk_migration_run_rerun FOREIGN KEY (tenant_id, rerun_of_run_id) REFERENCES ph18_ops.migration_run (tenant_id, id),
  CONSTRAINT ck_migration_run_mode CHECK (run_mode IN ('DRY_RUN', 'REAL')),
  CONSTRAINT ck_migration_run_status CHECK (status IN ('PENDING_APPROVAL', 'QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_migration_run_dry CHECK (run_mode = 'REAL' OR status <> 'PENDING_APPROVAL'),
  CONSTRAINT ck_migration_run_real CHECK (run_mode = 'DRY_RUN' OR status IN ('PENDING_APPROVAL', 'CANCELLED') OR approved_by IS NOT NULL),
  CONSTRAINT ck_migration_run_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_migration_run_counts CHECK (items_succeeded + items_failed + items_skipped <= items_total)
);
CREATE UNIQUE INDEX uq_migration_run_active ON ph18_ops.migration_run (tenant_id, plan_id) WHERE run_mode = 'REAL' AND status IN ('QUEUED', 'RUNNING');
CREATE TRIGGER tg_migration_run_touch BEFORE UPDATE ON ph18_ops.migration_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_run_immutable BEFORE UPDATE ON ph18_ops.migration_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('plan_id', 'run_no', 'run_mode', 'requested_by');
CREATE TRIGGER tg_migration_run_fsm_status BEFORE UPDATE ON ph18_ops.migration_run FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING_APPROVAL>QUEUED,PENDING_APPROVAL>CANCELLED,QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,RUNNING>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_run', false);
COMMENT ON TABLE ph18_ops.migration_run IS 'EN-18-45 Lần chạy di trú: DRY_RUN không ghi, REAL ghi qua API nhập của PH đích và cần bốn mắt (PENDING_APPROVAL trước QUEUED); idempotent nên chạy lại không tạo bản trùng; worker dh-migrate là Job K8s ở dh-batch; bộ đếm mục. Mỗi kế hoạch một lần chạy thật đang chạy.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.migration_run CASCADE;

-- @changeset ph18-0580-migration-run-item-result splitStatements:false
CREATE TABLE ph18_ops.migration_run_item_result (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid NOT NULL,
  plan_item_id    uuid NOT NULL,
  status          varchar(24) NOT NULL DEFAULT 'QUEUED',
  source_count    bigint NOT NULL DEFAULT 0,
  migrated_count  bigint NOT NULL DEFAULT 0,
  unchanged_count bigint NOT NULL DEFAULT 0,
  skipped_count   bigint NOT NULL DEFAULT 0,
  error_count     bigint NOT NULL DEFAULT 0,
  source_checksum char(64),
  target_checksum char(64),
  started_at      timestamptz,
  finished_at     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_run_item_result PRIMARY KEY (id),
  CONSTRAINT uq_migration_run_item_result_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_run_item_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_migration_run_item_result UNIQUE (tenant_id, run_id, plan_item_id),
  CONSTRAINT fk_migration_run_item_result_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_migration_run_item_result_item FOREIGN KEY (tenant_id, plan_item_id) REFERENCES ph18_ops.migration_plan_item (tenant_id, id),
  CONSTRAINT ck_migration_run_item_result_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_migration_run_item_result_counts CHECK (migrated_count + unchanged_count + skipped_count + error_count <= source_count),
  CONSTRAINT ck_migration_run_item_result_sha CHECK ((source_checksum IS NULL OR source_checksum ~ '^[0-9a-f]{64}$') AND (target_checksum IS NULL OR target_checksum ~ '^[0-9a-f]{64}$'))
);
CREATE TRIGGER tg_migration_run_item_result_touch BEFORE UPDATE ON ph18_ops.migration_run_item_result FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_run_item_result_immutable BEFORE UPDATE ON ph18_ops.migration_run_item_result FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('run_id', 'plan_item_id');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_run_item_result', false);
COMMENT ON TABLE ph18_ops.migration_run_item_result IS 'EN-18-46 Kết quả một mục kế hoạch trong lần chạy: số bản ghi nguồn, đã chuyển, bỏ qua, lỗi, không đổi (chạy lại), tổng kiểm tra nguồn và đích.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.migration_run_item_result CASCADE;

-- @changeset ph18-0590-migration-error-record splitStatements:false
CREATE TABLE ph18_ops.migration_error_record (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  run_id            uuid NOT NULL,
  plan_item_id      uuid NOT NULL,
  source_record_ref varchar(255) NOT NULL,
  error_code        varchar(16) NOT NULL,
  error_message     varchar(2000) NOT NULL,
  field_path        varchar(255),
  source_snapshot   jsonb,
  fix_status        varchar(16) NOT NULL DEFAULT 'OPEN',
  fixed_by          varchar(64),
  fixed_at          timestamptz,
  fix_note          varchar(1000),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_error_record PRIMARY KEY (id),
  CONSTRAINT uq_migration_error_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_error_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_migration_error_record_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_migration_error_record_item FOREIGN KEY (tenant_id, plan_item_id) REFERENCES ph18_ops.migration_plan_item (tenant_id, id),
  CONSTRAINT ck_migration_error_record_code CHECK (error_code ~ '^ERR-[0-9]{2}-[0-9]{3}$'),
  CONSTRAINT ck_migration_error_record_fix CHECK (fix_status IN ('OPEN', 'FIXED_AT_SOURCE', 'RULE_ADDED', 'WONT_MIGRATE')),
  CONSTRAINT ck_migration_error_record_fixed CHECK ((fix_status = 'OPEN') = (fixed_at IS NULL)),
  CONSTRAINT ck_migration_error_record_wont CHECK (fix_status <> 'WONT_MIGRATE' OR coalesce(char_length(btrim(fix_note)), 0) >= 10),
  CONSTRAINT ck_migration_error_record_snapshot CHECK (source_snapshot IS NULL OR NOT (source_snapshot ?| ARRAY['passwd', 'credential', 'client_secret', 'api_key']))
);
CREATE INDEX ix_migration_error_record_run ON ph18_ops.migration_error_record (tenant_id, run_id, fix_status);
CREATE TRIGGER tg_migration_error_record_touch BEFORE UPDATE ON ph18_ops.migration_error_record FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_error_record_immutable BEFORE UPDATE ON ph18_ops.migration_error_record FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('run_id', 'plan_item_id', 'source_record_ref', 'error_code');
CALL ph18_ops.p_enable_rls('ph18_ops.migration_error_record', false);
COMMENT ON TABLE ph18_ops.migration_error_record IS 'EN-18-47 Bản ghi không chuyển được kèm lý do (FR-00-091, 092): mã bản ghi nguồn, mã lỗi, trường lỗi, ảnh chụp nguồn đã che (không thông tin xác thực), trạng thái sửa (OPEN, FIXED_AT_SOURCE sửa ở nguồn, RULE_ADDED thêm quy tắc, WONT_MIGRATE không di trú kèm lý do; theo FRS FR-18-063, ghi qua API-18-182).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.migration_error_record CASCADE;

-- @changeset ph18-0600-migration-reconciliation splitStatements:false
CREATE TABLE ph18_ops.migration_reconciliation (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid NOT NULL,
  plan_item_id    uuid NOT NULL,
  object_kind     varchar(12) NOT NULL,
  source_count    bigint NOT NULL,
  target_count    bigint NOT NULL,
  missing_count   bigint NOT NULL DEFAULT 0,
  extra_count     bigint NOT NULL DEFAULT 0,
  mismatch_count  bigint NOT NULL DEFAULT 0,
  source_checksum char(64) NOT NULL,
  target_checksum char(64) NOT NULL,
  checksum_algo   varchar(16) NOT NULL DEFAULT 'SHA-256',
  matched         boolean NOT NULL,
  computed_at     timestamptz NOT NULL DEFAULT now(),
  report_location varchar(500),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_migration_reconciliation PRIMARY KEY (id),
  CONSTRAINT uq_migration_reconciliation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_migration_reconciliation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_migration_reconciliation_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id),
  CONSTRAINT fk_migration_reconciliation_item FOREIGN KEY (tenant_id, plan_item_id) REFERENCES ph18_ops.migration_plan_item (tenant_id, id),
  CONSTRAINT ck_migration_reconciliation_kind CHECK (object_kind IN ('CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION')),
  CONSTRAINT ck_migration_reconciliation_counts CHECK (source_count >= 0 AND target_count >= 0 AND missing_count >= 0 AND extra_count >= 0 AND mismatch_count >= 0),
  CONSTRAINT ck_migration_reconciliation_matched CHECK (NOT matched OR (source_count = target_count AND missing_count = 0 AND extra_count = 0 AND mismatch_count = 0 AND source_checksum = target_checksum)),
  CONSTRAINT ck_migration_reconciliation_sha CHECK (source_checksum ~ '^[0-9a-f]{64}$' AND target_checksum ~ '^[0-9a-f]{64}$')
);
CREATE INDEX ix_migration_reconciliation_run ON ph18_ops.migration_reconciliation (tenant_id, run_id);
CREATE TRIGGER tg_migration_reconciliation_touch BEFORE UPDATE ON ph18_ops.migration_reconciliation FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_migration_reconciliation_append_only BEFORE UPDATE OR DELETE ON ph18_ops.migration_reconciliation FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.migration_reconciliation', false);
COMMENT ON TABLE ph18_ops.migration_reconciliation IS 'EN-18-48 Báo cáo đối chiếu số lượng và tổng kiểm tra theo loại đối tượng sau lần chạy (FR-00-092): số nguồn, số đích, thiếu, thừa, lệch, tổng kiểm tra hai phía, khớp hay không. Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.migration_reconciliation CASCADE;

-- @changeset ph18-0610-credential-reissue-marker splitStatements:false
CREATE TABLE ph18_ops.credential_reissue_marker (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  run_id          uuid,
  object_kind     varchar(12) NOT NULL,
  target_module   varchar(8) NOT NULL,
  target_ref      varchar(255) NOT NULL,
  legacy_ref      varchar(255) NOT NULL,
  credential_kind varchar(20) NOT NULL,
  status          varchar(12) NOT NULL DEFAULT 'PENDING',
  notified_at     timestamptz,
  reissued_at     timestamptz,
  reissued_ref    varchar(255),
  waived_reason   varchar(1000),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_credential_reissue_marker PRIMARY KEY (id),
  CONSTRAINT uq_credential_reissue_marker_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_credential_reissue_marker_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_credential_reissue_marker UNIQUE (tenant_id, target_module, target_ref, credential_kind),
  CONSTRAINT fk_credential_reissue_marker_run FOREIGN KEY (tenant_id, run_id) REFERENCES ph18_ops.migration_run (tenant_id, id),
  CONSTRAINT ck_credential_reissue_marker_kind CHECK (object_kind IN ('CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION')),
  CONSTRAINT ck_credential_reissue_marker_module CHECK (target_module IN ('PH-01', 'PH-02', 'PH-03', 'PH-04', 'PH-07', 'PH-10', 'PH-19')),
  CONSTRAINT ck_credential_reissue_marker_credential CHECK (credential_kind IN ('OAUTH_CLIENT', 'CLIENT_CERT', 'API_KEY_LEGACY', 'PASSWORD')),
  CONSTRAINT ck_credential_reissue_marker_status CHECK (status IN ('PENDING', 'NOTIFIED', 'REISSUED', 'WAIVED')),
  CONSTRAINT ck_credential_reissue_marker_reissued CHECK (status <> 'REISSUED' OR reissued_at IS NOT NULL),
  CONSTRAINT ck_credential_reissue_marker_waived CHECK (status <> 'WAIVED' OR coalesce(char_length(btrim(waived_reason)), 0) >= 10)
);
CREATE INDEX ix_credential_reissue_marker_open ON ph18_ops.credential_reissue_marker (tenant_id, status) WHERE status IN ('PENDING', 'NOTIFIED');
CREATE TRIGGER tg_credential_reissue_marker_touch BEFORE UPDATE ON ph18_ops.credential_reissue_marker FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_credential_reissue_marker_immutable BEFORE UPDATE ON ph18_ops.credential_reissue_marker FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('target_module', 'target_ref', 'credential_kind', 'legacy_ref');
CALL ph18_ops.p_enable_rls('ph18_ops.credential_reissue_marker', false);
COMMENT ON TABLE ph18_ops.credential_reissue_marker IS 'EN-18-49 Đánh dấu đối tượng đã di trú cần cấp lại thông tin xác thực ở PH đích (FR-00-093: không di trú bí mật): PH-01 (HTTT), PH-03 (đăng ký cổng), PH-02, PH-04, PH-07, PH-10, PH-19 (targetPh dạng PH-nn của FRS); trạng thái chờ, đã báo, đã cấp lại, miễn (WAIVED qua API-18-183 kèm lý do). Điều kiện cắt chuyển CREDENTIALS_REISSUED.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.credential_reissue_marker CASCADE;

-- @changeset ph18-0620-parallel-run-group splitStatements:false
CREATE TABLE ph18_ops.parallel_run_group (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  group_code              varchar(32) NOT NULL,
  plan_id                 uuid,
  title                   varchar(255) NOT NULL,
  service_scope           varchar(500) NOT NULL,
  legacy_endpoint_ref     varchar(255) NOT NULL,
  datahub_endpoint_ref    varchar(255) NOT NULL,
  mirror_ratio_percent    numeric(5,2) NOT NULL DEFAULT 100,
  match_threshold_percent numeric(6,3) NOT NULL DEFAULT 99.5,
  status                  varchar(16) NOT NULL DEFAULT 'PARALLEL',
  samples_total           bigint NOT NULL DEFAULT 0,
  samples_matched         bigint NOT NULL DEFAULT 0,
  match_rate              numeric(6,3),
  bridge_ref              varchar(128),
  ph10_cutover_event_id   varchar(255),
  cutover_at              timestamptz,
  rollback_deadline_at    timestamptz,
  rolled_back_at          timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_parallel_run_group PRIMARY KEY (id),
  CONSTRAINT uq_parallel_run_group_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_parallel_run_group_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_parallel_run_group_code UNIQUE (tenant_id, group_code),
  CONSTRAINT fk_parallel_run_group_plan FOREIGN KEY (tenant_id, plan_id) REFERENCES ph18_ops.migration_plan (tenant_id, id),
  CONSTRAINT ck_parallel_run_group_ratio CHECK (mirror_ratio_percent BETWEEN 0 AND 100 AND match_threshold_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_parallel_run_group_status CHECK (status IN ('PARALLEL', 'SHADOW_OK', 'PARTIAL_CUTOVER', 'CUT_OVER', 'ROLLED_BACK')),
  CONSTRAINT ck_parallel_run_group_samples CHECK (samples_matched BETWEEN 0 AND samples_total),
  CONSTRAINT ck_parallel_run_group_shadow_ok CHECK (status <> 'SHADOW_OK' OR match_rate >= match_threshold_percent),
  CONSTRAINT ck_parallel_run_group_cutover CHECK (status NOT IN ('PARTIAL_CUTOVER', 'CUT_OVER') OR (cutover_at IS NOT NULL AND rollback_deadline_at IS NOT NULL AND rollback_deadline_at > cutover_at)),
  CONSTRAINT ck_parallel_run_group_rollback CHECK (status <> 'ROLLED_BACK' OR rolled_back_at IS NOT NULL)
);
CREATE TRIGGER tg_parallel_run_group_touch BEFORE UPDATE ON ph18_ops.parallel_run_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_parallel_run_group_immutable BEFORE UPDATE ON ph18_ops.parallel_run_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('group_code');
CREATE TRIGGER tg_parallel_run_group_fsm_status BEFORE UPDATE ON ph18_ops.parallel_run_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PARALLEL>SHADOW_OK,SHADOW_OK>PARALLEL,SHADOW_OK>PARTIAL_CUTOVER,SHADOW_OK>CUT_OVER,PARTIAL_CUTOVER>CUT_OVER,PARTIAL_CUTOVER>ROLLED_BACK,CUT_OVER>ROLLED_BACK,ROLLED_BACK>PARALLEL');
CALL ph18_ops.p_enable_rls('ph18_ops.parallel_run_group', false);
COMMENT ON TABLE ph18_ops.parallel_run_group IS 'EN-18-50 Nhóm dịch vụ chạy song song và cắt chuyển: phạm vi route, điểm cuối cũ và mới (tên, không thông tin xác thực), tỷ lệ nhân bản lưu lượng APISIX, ngưỡng khớp (18.migration.parallel.match-threshold-percent), tỷ lệ khớp, cầu nối PH-10 (EVT-10-15, 16), mốc cắt chuyển và hạn quay lui 15 phút (18.migration.rollback-window-minutes).';
-- @rollback DROP TABLE IF EXISTS ph18_ops.parallel_run_group CASCADE;

-- @changeset ph18-0630-shadow-comparison-sample splitStatements:false
CREATE TABLE ph18_ops.shadow_comparison_sample (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  group_id            uuid NOT NULL,
  sampled_at          timestamptz NOT NULL DEFAULT now(),
  route               varchar(255) NOT NULL,
  request_fingerprint char(64) NOT NULL,
  legacy_status       integer,
  datahub_status      integer,
  legacy_latency_ms   integer,
  datahub_latency_ms  integer,
  legacy_body_sha256  char(64),
  datahub_body_sha256 char(64),
  matched             boolean NOT NULL,
  diff_kind           varchar(8) NOT NULL DEFAULT 'NONE',
  diff_paths          varchar(255)[] NOT NULL DEFAULT '{}',
  trace_id            char(32),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_shadow_comparison_sample PRIMARY KEY (id, sampled_at),
  CONSTRAINT uq_shadow_comparison_sample_tid UNIQUE (tenant_id, id, sampled_at),
  CONSTRAINT ck_shadow_comparison_sample_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_shadow_comparison_sample_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.parallel_run_group (tenant_id, id),
  CONSTRAINT ck_shadow_comparison_sample_fingerprint CHECK (request_fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_shadow_comparison_sample_diff CHECK (diff_kind IN ('NONE', 'STATUS', 'BODY', 'LATENCY', 'ERROR') AND (matched = (diff_kind IN ('NONE', 'LATENCY')))),
  CONSTRAINT ck_shadow_comparison_sample_status_code CHECK ((legacy_status IS NULL OR legacy_status BETWEEN 100 AND 599) AND (datahub_status IS NULL OR datahub_status BETWEEN 100 AND 599))
) PARTITION BY RANGE (sampled_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.shadow_comparison_sample', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_shadow_comparison_sample_group ON ph18_ops.shadow_comparison_sample (tenant_id, group_id, sampled_at DESC);
CREATE INDEX ix_shadow_comparison_sample_miss ON ph18_ops.shadow_comparison_sample (tenant_id, group_id, diff_kind) WHERE NOT matched;
CREATE TRIGGER tg_shadow_comparison_sample_touch BEFORE UPDATE ON ph18_ops.shadow_comparison_sample FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_shadow_comparison_sample_append_only BEFORE UPDATE OR DELETE ON ph18_ops.shadow_comparison_sample FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.shadow_comparison_sample', false);
COMMENT ON TABLE ph18_ops.shadow_comparison_sample IS 'EN-18-51 Mẫu so sánh phản hồi cũ và mới khi APISIX nhân bản lưu lượng sang Datahub: dấu vân tay yêu cầu, mã trạng thái, độ trễ, băm thân hai phía, khớp hay không, loại lệch và đường dẫn trường lệch (không lưu giá trị). Chỉ thêm; phân vùng tháng theo sampled_at, giữ 18.migration.shadow.sample-retention-days.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.shadow_comparison_sample CASCADE;

-- @changeset ph18-0640-cutover-checklist splitStatements:false
CREATE TABLE ph18_ops.cutover_checklist (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  group_id      uuid NOT NULL,
  item_code     varchar(24) NOT NULL,
  description   varchar(500) NOT NULL,
  check_kind    varchar(8) NOT NULL,
  status        varchar(8) NOT NULL DEFAULT 'PENDING',
  evidence      jsonb NOT NULL DEFAULT '{}',
  checked_by    varchar(64),
  checked_at    timestamptz,
  waived_reason varchar(1000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_cutover_checklist PRIMARY KEY (id),
  CONSTRAINT uq_cutover_checklist_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_cutover_checklist_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_cutover_checklist_item UNIQUE (tenant_id, group_id, item_code),
  CONSTRAINT fk_cutover_checklist_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.parallel_run_group (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_cutover_checklist_item CHECK (item_code IN ('DLQ_EMPTY', 'MATCH_RATE', 'RECONCILIATION_MATCHED', 'CREDENTIALS_REISSUED', 'BACKUP_VERIFIED', 'ROLLBACK_READY', 'STAKEHOLDER_SIGNOFF', 'FREEZE_WINDOW')),
  CONSTRAINT ck_cutover_checklist_kind CHECK (check_kind IN ('AUTO', 'MANUAL')),
  CONSTRAINT ck_cutover_checklist_status CHECK (status IN ('PENDING', 'PASSED', 'FAILED', 'WAIVED')),
  CONSTRAINT ck_cutover_checklist_checked CHECK (status = 'PENDING' OR (checked_by IS NOT NULL AND checked_at IS NOT NULL)),
  CONSTRAINT ck_cutover_checklist_waived CHECK (status <> 'WAIVED' OR coalesce(char_length(btrim(waived_reason)), 0) >= 10)
);
CREATE TRIGGER tg_cutover_checklist_touch BEFORE UPDATE ON ph18_ops.cutover_checklist FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_cutover_checklist_immutable BEFORE UPDATE ON ph18_ops.cutover_checklist FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('group_id', 'item_code');
CALL ph18_ops.p_enable_rls('ph18_ops.cutover_checklist', false);
COMMENT ON TABLE ph18_ops.cutover_checklist IS 'EN-18-52 Danh sách kiểm tra cắt chuyển của nhóm dịch vụ: DLQ rỗng, tỷ lệ khớp ≥ ngưỡng, đối chiếu khớp, thông tin xác thực đã cấp lại, sao lưu đã kiểm, sẵn sàng quay lui, xác nhận các bên, cửa sổ đóng băng; tự động hay thủ công, bằng chứng, người kiểm.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.cutover_checklist CASCADE;

-- @changeset ph18-0650-cutover-log splitStatements:false
CREATE TABLE ph18_ops.cutover_log (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  group_id    uuid NOT NULL,
  action      varchar(20) NOT NULL,
  actor       varchar(64) NOT NULL,
  approved_by varchar(64),
  occurred_at timestamptz NOT NULL DEFAULT now(),
  from_status varchar(16),
  to_status   varchar(16),
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_cutover_log PRIMARY KEY (id),
  CONSTRAINT uq_cutover_log_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_cutover_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_cutover_log_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.parallel_run_group (tenant_id, id),
  CONSTRAINT ck_cutover_log_action CHECK (action IN ('START_PARALLEL', 'SHADOW_CONFIRMED', 'PARTIAL_CUTOVER', 'CUTOVER', 'ROLLBACK', 'CHECKLIST_SIGNED', 'NOTE')),
  CONSTRAINT ck_cutover_log_four_eyes CHECK (action NOT IN ('PARTIAL_CUTOVER', 'CUTOVER', 'ROLLBACK') OR (approved_by IS NOT NULL AND approved_by <> actor))
);
CREATE INDEX ix_cutover_log_group ON ph18_ops.cutover_log (tenant_id, group_id, occurred_at);
CREATE TRIGGER tg_cutover_log_touch BEFORE UPDATE ON ph18_ops.cutover_log FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_cutover_log_append_only BEFORE UPDATE OR DELETE ON ph18_ops.cutover_log FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.cutover_log', false);
COMMENT ON TABLE ph18_ops.cutover_log IS 'EN-18-53 Sổ cắt chuyển: bắt đầu chạy song song, xác nhận bóng đạt, cắt chuyển một phần, cắt chuyển, quay lui, ký danh sách kiểm tra, ghi chú; cắt chuyển và quay lui cần người duyệt khác người thực hiện. Chỉ thêm.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.cutover_log CASCADE;


-- @file 18-0090-report.sql
-- @changeset ph18-0660-ops-report splitStatements:false
CREATE TABLE ph18_ops.ops_report (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  report_kind        varchar(12) NOT NULL,
  period_kind        varchar(8) NOT NULL,
  period_from        date NOT NULL,
  period_to          date NOT NULL,
  status             varchar(24) NOT NULL DEFAULT 'QUEUED',
  metrics            jsonb NOT NULL DEFAULT '{}',
  bucket             varchar(63),
  object_key         text,
  sha256             char(64),
  generated_at       timestamptz,
  published_event_id uuid,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_ops_report PRIMARY KEY (id),
  CONSTRAINT uq_ops_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_ops_report_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_ops_report_period UNIQUE (tenant_id, report_kind, period_kind, period_from),
  CONSTRAINT ck_ops_report_kind CHECK (report_kind IN ('DLQ', 'BACKUP', 'MIGRATION', 'INCIDENT', 'PARAMETER', 'SUMMARY')),
  CONSTRAINT ck_ops_report_period CHECK (period_kind IN ('DAY', 'WEEK', 'MONTH', 'QUARTER') AND period_to >= period_from),
  CONSTRAINT ck_ops_report_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_ops_report_bucket CHECK (bucket IS NULL OR bucket = 'dh-' || lower(tenant_id) || '-ops' OR (tenant_id = 'COMMON' AND bucket = 'dh-common-ops')),
  CONSTRAINT ck_ops_report_sha CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_ops_report_done CHECK (status <> 'SUCCEEDED' OR generated_at IS NOT NULL)
);
CREATE TRIGGER tg_ops_report_touch BEFORE UPDATE ON ph18_ops.ops_report FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_ops_report_immutable BEFORE UPDATE ON ph18_ops.ops_report FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('report_kind', 'period_kind', 'period_from', 'period_to');
CREATE TRIGGER tg_ops_report_fsm_status BEFORE UPDATE ON ph18_ops.ops_report FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>RUNNING,QUEUED>CANCELLED,RUNNING>SUCCEEDED,RUNNING>SUCCEEDED_WITH_ERRORS,RUNNING>FAILED,FAILED>QUEUED');
CALL ph18_ops.p_enable_rls('ph18_ops.ops_report', false);
COMMENT ON TABLE ph18_ops.ops_report IS 'EN-18-54 Báo cáo vận hành định kỳ (DLQ, sao lưu, di trú, sự cố, tham số, tổng hợp) gửi PH-16 qua sự kiện: kỳ, chỉ số tổng hợp, tệp ở Garage bucket dh-{tenant}-ops, tổng kiểm tra. Mỗi loại, kỳ một báo cáo; dòng COMMON là báo cáo nền tảng.';
-- @rollback DROP TABLE IF EXISTS ph18_ops.ops_report CASCADE;

-- @file 18-0085-batch.sql
-- @changeset ph18-0850-batch-schema splitStatements:false
-- Kho lần chạy Spring Batch (JobRepository) của dh-migrate, dh-tenant-restore, dh-tenant-export (ADR-183, SDD §13.5 điểm 9): schema riêng
-- ph18_batch theo lược đồ chuẩn schema-postgresql.sql của Spring Batch 5, không RLS (dữ liệu kỹ thuật, tham số Job mang mã tenant, không
-- dữ liệu nghiệp vụ); chỉ ph18_worker đọc ghi, ph18_app và ph18_readonly không có quyền. Trạng thái nghiệp vụ vẫn ở ph18_ops.
RESET ROLE;
CREATE SCHEMA IF NOT EXISTS ph18_batch AUTHORIZATION ph18_owner;
COMMENT ON SCHEMA ph18_batch IS 'PH-18 kho lần chạy Spring Batch (JobRepository) của dh-ops-worker; khởi động lại Job từ bước dừng. Không RLS, chỉ ph18_worker.';
REVOKE ALL ON SCHEMA ph18_batch FROM PUBLIC;
GRANT USAGE ON SCHEMA ph18_batch TO ph18_worker;
SET ROLE ph18_owner;
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_instance (job_instance_id bigint NOT NULL PRIMARY KEY, version bigint, job_name varchar(100) NOT NULL,
  job_key varchar(32) NOT NULL, CONSTRAINT job_inst_un UNIQUE (job_name, job_key));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_execution (job_execution_id bigint NOT NULL PRIMARY KEY, version bigint, job_instance_id bigint NOT NULL,
  create_time timestamp NOT NULL, start_time timestamp, end_time timestamp, status varchar(10), exit_code varchar(2500), exit_message varchar(2500),
  last_updated timestamp, CONSTRAINT job_inst_exec_fk FOREIGN KEY (job_instance_id) REFERENCES ph18_batch.batch_job_instance (job_instance_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_execution_params (job_execution_id bigint NOT NULL, parameter_name varchar(100) NOT NULL,
  parameter_type varchar(100) NOT NULL, parameter_value varchar(2500), identifying char(1) NOT NULL,
  CONSTRAINT job_exec_params_fk FOREIGN KEY (job_execution_id) REFERENCES ph18_batch.batch_job_execution (job_execution_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_step_execution (step_execution_id bigint NOT NULL PRIMARY KEY, version bigint NOT NULL, step_name varchar(100) NOT NULL,
  job_execution_id bigint NOT NULL, create_time timestamp NOT NULL, start_time timestamp, end_time timestamp, status varchar(10), commit_count bigint,
  read_count bigint, filter_count bigint, write_count bigint, read_skip_count bigint, write_skip_count bigint, process_skip_count bigint, rollback_count bigint,
  exit_code varchar(2500), exit_message varchar(2500), last_updated timestamp,
  CONSTRAINT job_exec_step_fk FOREIGN KEY (job_execution_id) REFERENCES ph18_batch.batch_job_execution (job_execution_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_step_execution_context (step_execution_id bigint NOT NULL PRIMARY KEY, short_context varchar(2500) NOT NULL,
  serialized_context text, CONSTRAINT step_exec_ctx_fk FOREIGN KEY (step_execution_id) REFERENCES ph18_batch.batch_step_execution (step_execution_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_execution_context (job_execution_id bigint NOT NULL PRIMARY KEY, short_context varchar(2500) NOT NULL,
  serialized_context text, CONSTRAINT job_exec_ctx_fk FOREIGN KEY (job_execution_id) REFERENCES ph18_batch.batch_job_execution (job_execution_id));
CREATE SEQUENCE IF NOT EXISTS ph18_batch.batch_step_execution_seq MAXVALUE 9223372036854775807 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS ph18_batch.batch_job_execution_seq MAXVALUE 9223372036854775807 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS ph18_batch.batch_job_seq MAXVALUE 9223372036854775807 NO CYCLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph18_batch TO ph18_worker;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ph18_batch TO ph18_worker;
-- @rollback DROP SCHEMA IF EXISTS ph18_batch CASCADE;

-- @file 18-0091-views.sql
-- @changeset ph18-0900-view-config-param splitStatements:false
-- Tương thích DD-14 (D02-07 dòng 151, FRS-07 nêu ph18_ops.config_param): khung nhìn giá trị hiệu lực theo tenant phiên. security_invoker nên RLS của bảng gốc áp cho người đọc.
CREATE OR REPLACE VIEW ph18_ops.config_param WITH (security_invoker = true) AS
SELECT d.param_key                                                     AS key,
       COALESCE(t.value, p.value, d.default_value)                     AS value,
       d.json_schema                                                   AS schema,
       CASE WHEN t.id IS NOT NULL THEN 'TENANT' ELSE 'PLATFORM' END    AS scope,
       COALESCE(t.effective_from, p.effective_from, d.created_at)      AS effective_from,
       current_setting('app.tenant_id', false)                         AS tenant_id,
       d.namespace_code, d.value_type, d.level, d.secure, d.display_group,
       COALESCE(t.current_version_no, p.current_version_no, 0)         AS version_no
  FROM ph18_ops.param_definition d
  LEFT JOIN ph18_ops.param_value p ON p.definition_id = d.id AND p.tenant_id = 'COMMON'
  LEFT JOIN ph18_ops.param_value t ON t.definition_id = d.id AND t.tenant_id = current_setting('app.tenant_id', false) AND t.tenant_id <> 'COMMON'
 WHERE d.removal_date IS NULL OR d.removal_date >= current_date;
COMMENT ON VIEW ph18_ops.config_param IS 'DD-14 Tham số cấu hình: key, value, schema, scope (PLATFORM hoặc TENANT), effective_from; giá trị hiệu lực = ghi đè tenant, nếu không thì giá trị nền tảng, nếu không thì mặc định của lược đồ khóa.';
-- @rollback DROP VIEW IF EXISTS ph18_ops.config_param;

-- @changeset ph18-0901-view-notification splitStatements:false
-- Tương thích DD-13 (D02-07 dòng 150): hộp thông báo trong ứng dụng.
CREATE OR REPLACE VIEW ph18_ops.notification WITH (security_invoker = true) AS
SELECT d.id, d.tenant_id, d.recipient_user_id, m.category, d.rendered_title AS title, m.link, d.read_at, to_jsonb(m.channels) AS channels_sent,
       d.status, d.queued_at AS created_at
  FROM ph18_ops.notification_delivery d
  JOIN ph18_ops.notification_message m ON m.tenant_id = d.tenant_id AND m.id = d.message_id
 WHERE d.channel = 'IN_APP';
COMMENT ON VIEW ph18_ops.notification IS 'DD-13 Thông báo: recipient_user_id, category, title, link, read_at, channels_sent; chỉ kênh IN_APP.';
-- @rollback DROP VIEW IF EXISTS ph18_ops.notification;

-- @file 18-0095-seed.sql
-- @changeset ph18-0950-seed-common splitStatements:false context:seed
-- Dữ liệu nền tảng (tenant COMMON): không gian tên, lược đồ khóa 18.*, nguồn DLQ, đối tượng sao lưu D03-09 §8.2, lịch quốc gia mặc định.
SET app.tenant_id = 'COMMON';
INSERT INTO ph18_ops.param_namespace (id, tenant_id, code, owner_module, title, approval_owner, created_by, updated_by)
SELECT md5('ph18-ns:' || s.c)::uuid, 'COMMON', s.c, s.m, s.t, s.a, 'system:seed', 'system:seed' FROM (VALUES
  ('00', 'PH-00', 'Tham số chung nền tảng', 'PH-18'),
  ('onboarding', 'PH-01', 'Kết nạp HTTT', 'PH-18'),
  ('02', 'PH-02', 'Danh mục dịch vụ', 'PH-18'),
  ('04', 'PH-04', 'Tích hợp', 'PH-18'),
  ('05', 'PH-05', 'Bộ điều hợp', 'PH-18'),
  ('06', 'PH-06', 'Dữ liệu chủ', 'PH-18'),
  ('07.rdm', 'PH-07', 'Danh mục dùng chung', 'PH-18'),
  ('08', 'PH-08', 'Chất lượng dữ liệu', 'PH-18'),
  ('09', 'PH-09', 'Quyền riêng tư', 'PH-18'),
  ('10', 'PH-10', 'Sự kiện', 'PH-18'),
  ('11', 'PH-11', 'Quy trình', 'PH-18'),
  ('12', 'PH-12', 'Định danh và phân quyền', 'PH-18'),
  ('13', 'PH-13', 'Giám sát và kiểm toán', 'PH-18'),
  ('14', 'PH-14', 'Kết nối quốc gia', 'PH-14'),
  ('15', 'PH-15', 'Cổng nhà phát triển', 'PH-18'),
  ('16', 'PH-16', 'Báo cáo chỉ tiêu', 'PH-18'),
  ('17', 'PH-17', 'Trợ lý AI', 'PH-17'),
  ('18', 'PH-18', 'Vận hành và xử lý lỗi', 'PH-18'),
  ('20', 'PH-20', 'Quản trị tenant', 'PH-18'),
  ('ff', 'PH-18', 'Cờ tính năng', 'PH-18')
) AS s(c, m, t, a)
ON CONFLICT (tenant_id, code) DO NOTHING;
INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, min_value, max_value, unit, level, secure, display_group, display_order, label, allowed_values, created_by, updated_by)
SELECT md5('ph18-def:' || s.k)::uuid, 'COMMON', '18', s.k, s.t, s.d::jsonb, s.lo, s.hi, s.u, s.l, s.f, s.g, s.o, s.lab, s.av::jsonb, 'system:seed', 'system:seed' FROM (VALUES
  ('18.param.cache-ttl-seconds', 'INT', '60', 10, 60, 's', 'PLATFORM', false, 'param', 10, 'Thời hạn bộ đệm tham số phía dh-ops-client', NULL::text),
  ('18.param.reason-min-length', 'INT', '10', 10, 200, NULL::text, 'TENANT', false, 'param', 20, 'Độ dài tối thiểu của lý do đổi tham số', NULL::text),
  ('18.param.history-retention-days', 'INT', '1825', 365, 3650, 'd', 'PLATFORM', false, 'param', 30, 'Thời gian giữ phiên bản tham số', NULL::text),
  ('18.param.change-request-ttl-hours', 'INT', '72', 1, 720, 'h', 'TENANT', false, 'param', 40, 'Đề nghị đổi khóa ★ chưa duyệt quá hạn thì tự hết hiệu lực', NULL::text),
  ('18.ff.retire-warning-days', 'INT', '14', 1, 90, 'd', 'TENANT', false, 'ff', 50, 'Số ngày trước ngày gỡ cờ thì nhắc chủ sở hữu', NULL::text),
  ('18.egress.allowlist', 'LIST<HOST>', '[]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'egress', 60, 'Danh sách đích egress cho phép (FR-18-010)', NULL::text),
  ('18.egress.max-entries', 'INT', '200', 1, 1000, 'item', 'PLATFORM', false, 'egress', 70, 'Số mục egress tối đa mỗi tenant', NULL::text),
  ('18.dlq.payload.inline-max-kb', 'INT', '256', 64, 256, 'KB', 'PLATFORM', false, 'dlq', 80, 'Ngưỡng payload lưu nội tuyến, lớn hơn lưu Garage', NULL::text),
  ('18.dlq.payload.max-mb', 'INT', '20', 1, 100, 'MB', 'PLATFORM', false, 'dlq', 90, 'Kích thước payload tối đa nhận vào DLQ', NULL::text),
  ('18.dlq.retention.closed-days', 'INT', '90', 30, 365, 'd', 'TENANT', false, 'dlq', 100, 'Thời gian giữ payload của mục đã đóng', NULL::text),
  ('18.dlq.retention.metadata-days', 'INT', '365', 90, 1825, 'd', 'TENANT', false, 'dlq', 110, 'Thời gian giữ siêu dữ liệu của mục EXPIRED', NULL::text),
  ('18.dlq.audit.retention-months', 'INT', '60', 12, 120, 'month', 'PLATFORM', false, 'dlq', 120, 'Thời gian giữ bản sao nhật ký thao tác DLQ (dlq_audit); bản chính thức ở PH-13', NULL::text),
  ('18.dlq.dedup-window-days', 'INT', '7', 1, 30, 'd', 'PLATFORM', false, 'dlq', 130, 'Cửa sổ khử trùng của inbox tiêu thụ DLQ', NULL::text),
  ('18.dlq.retention.open-max-days', 'INT', '365', 90, 1825, 'd', 'TENANT', false, 'dlq', 140, 'Tuổi mục mở thì nhắc và phát sự kiện AGE', NULL::text),
  ('18.dlq.reveal.ttl-minutes', 'INT', '15', 5, 60, 'min', 'TENANT', true, 'dlq', 150, 'Hạn phiếu xem payload', NULL::text),
  ('18.dlq.replay.batch-max', 'INT', '10000', 100, 50000, 'item', 'TENANT', false, 'dlq', 160, 'Số mục tối đa một lượt phát lại', NULL::text),
  ('18.dlq.replay.approval-threshold', 'INT', '500', 10, 10000, 'item', 'TENANT', true, 'dlq', 170, 'Lượt vượt số mục này cần bốn mắt', NULL::text),
  ('18.dlq.replay.rate-per-second', 'INT', '10', 1, 100, 'item/s', 'TENANT', false, 'dlq', 180, 'Tốc độ phát lại mặc định', NULL::text),
  ('18.dlq.replay.result-timeout-minutes', 'INT', '30', 1, 1440, 'min', 'TENANT', false, 'dlq', 190, 'Thời gian chờ kết quả phát lại', NULL::text),
  ('18.dlq.threshold.depth', 'INT', '1000', 10, 1000000, NULL::text, 'TENANT', false, 'dlq', 200, 'Ngưỡng số mục chưa xử lý để phát EVT-18-08', NULL::text),
  ('18.dlq.threshold.age-hours', 'INT', '24', 1, 720, 'h', 'TENANT', false, 'dlq', 210, 'Ngưỡng tuổi mục cũ nhất chưa xử lý', NULL::text),
  ('18.dlq.threshold.poison-per-hour', 'INT', '10', 1, 10000, 'item/h', 'TENANT', false, 'dlq', 220, 'Ngưỡng số mục POISON mỗi giờ', NULL::text),
  ('18.dlq.threshold.replay-failure-percent', 'INT', '20', 1, 100, '%', 'TENANT', false, 'dlq', 230, 'Tỷ lệ lỗi làm lượt phát lại tự dừng', NULL::text),
  ('18.dlq.group.window-hours', 'INT', '24', 1, 168, 'h', 'TENANT', false, 'dlq', 240, 'Cửa sổ gom nhóm dấu hiệu lỗi', NULL::text),
  ('18.dlq.reconcile.cron', 'CRON', '"0 30 2 * * *"', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'dlq', 250, 'Lịch đối soát chỉ mục với Kafka', NULL::text),
  ('18.dlq.diagnostics.timeout-ms', 'INT', '3000', 500, 5000, 'ms', 'PLATFORM', false, 'dlq', 260, 'Thời gian chờ ngữ cảnh chẩn đoán từ PH-13', NULL::text),
  ('18.notify.quiet-hours', 'STRING', '"22:00-06:00"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 270, 'Giờ yên lặng mặc định của tenant', NULL::text),
  ('18.notify.retry.max-attempts', 'INT', '5', 1, 10, NULL::text, 'PLATFORM', false, 'notify', 280, 'Số lần thử gửi tối đa', NULL::text),
  ('18.notify.retry.window-hours', 'INT', '24', 1, 72, 'h', 'PLATFORM', false, 'notify', 290, 'Khoảng thời gian thử gửi tối đa', NULL::text),
  ('18.notify.sync.timeout-ms', 'INT', '3000', 1000, 10000, 'ms', 'PLATFORM', false, 'notify', 300, 'Thời gian chờ ở chế độ gửi đồng bộ', NULL::text),
  ('18.notify.bounce.soft-limit', 'INT', '3', 1, 10, NULL::text, 'TENANT', false, 'notify', 310, 'Số lần trả lại mềm trong 30 ngày thì chặn', NULL::text),
  ('18.notify.log-retention-days', 'INT', '180', 30, 730, 'd', 'TENANT', false, 'notify', 320, 'Thời gian giữ nhật ký gửi', NULL::text),
  ('18.notify.sms.enabled', 'BOOL', 'false', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 330, 'Bật kênh SMS cho tenant', NULL::text),
  ('18.notify.sender-name', 'STRING', '"Datahub {tỉnh}"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 340, 'Tên người gửi hiển thị trên thư', NULL::text),
  ('18.task.reminder.before-hours', 'INT', '24', 1, 168, 'h', 'TENANT', false, 'task', 350, 'Nhắc trước hạn việc', NULL::text),
  ('18.task.overdue.escalate-hours', 'INT', '48', 1, 336, 'h', 'TENANT', false, 'task', 360, 'Quá hạn bao lâu thì leo thang', NULL::text),
  ('18.task.retention-days', 'INT', '365', 30, 1825, 'd', 'TENANT', false, 'task', 370, 'Thời gian giữ việc đã đóng', NULL::text),
  ('18.calendar.weekend-days', 'LIST<STRING>', '["SAT", "SUN"]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'calendar', 380, 'Ngày nghỉ cuối tuần', NULL::text),
  ('18.calendar.timezone', 'STRING', '"Asia/Ho_Chi_Minh"', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'calendar', 390, 'Múi giờ tính ngày làm việc', NULL::text),
  ('18.maintenance.notice-hours', 'INT', '72', 1, 336, 'h', 'TENANT', false, 'maintenance', 400, 'Báo trước bảo trì bao nhiêu giờ', NULL::text),
  ('18.freeze.default-envs', 'LIST<STRING>', '["PROD"]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'freeze', 410, 'Môi trường mặc định của cửa sổ đóng băng', '["DEV", "TEST", "STAGING", "PROD"]'),
  ('18.incident.sev1-ack-minutes', 'INT', '15', 5, 60, 'min', 'TENANT', false, 'incident', 420, 'Thời hạn nhận sự cố SEV1 trước khi leo thang', NULL::text),
  ('18.incident.sev2-ack-minutes', 'INT', '60', 15, 240, 'min', 'TENANT', false, 'incident', 430, 'Thời hạn nhận sự cố SEV2', NULL::text),
  ('18.incident.retention-years', 'INT', '5', 3, 10, 'y', 'PLATFORM', false, 'incident', 440, 'Thời gian giữ hồ sơ sự cố đã đóng', NULL::text),
  ('18.backup.stale-hours', 'INT', '26', 2, 72, 'h', 'PLATFORM', false, 'backup', 450, 'Bản sao lưu hằng ngày quá số giờ này là trễ', NULL::text),
  ('18.backup.freshness-max-minutes', 'INT', '15', 5, 60, 'min', 'PLATFORM', false, 'backup', 460, 'Độ trễ tối đa của trạng thái thu thập', NULL::text),
  ('18.backup.verification-interval-days', 'INT', '1', 1, 90, 'd', 'PLATFORM', false, 'backup', 470, 'Chu kỳ kiểm tra khôi phục tự động mỗi đối tượng', NULL::text),
  ('18.restore.max-duration-hours', 'INT', '4', 1, 24, 'h', 'PLATFORM', false, 'restore', 480, 'Chỉ tiêu thời gian khôi phục, vượt thì cảnh báo', NULL::text),
  ('18.restore.approval-required', 'BOOL', 'true', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', true, 'restore', 490, 'Khôi phục tenant bắt buộc bốn mắt (không tắt được)', '[true]'),
  ('18.export.link-ttl-hours', 'INT', '24', 1, 72, 'h', 'PLATFORM', false, 'export', 500, 'Hạn liên kết tải gói xuất', NULL::text),
  ('18.export.retention-days', 'INT', '30', 7, 90, 'd', 'PLATFORM', false, 'export', 510, 'Thời gian giữ gói xuất', NULL::text),
  ('18.migration.dry-run-valid-days', 'INT', '7', 1, 30, 'd', 'TENANT', false, 'migration', 520, 'Hạn hiệu lực của lần chạy thử', NULL::text),
  ('18.migration.batch-size', 'INT', '500', 50, 5000, NULL::text, 'TENANT', false, 'migration', 530, 'Kích thước lô đọc và nhập', NULL::text),
  ('18.migration.parallel.match-threshold-percent', 'DECIMAL', '99.5', 90, 100, '%', 'TENANT', false, 'migration', 540, 'Ngưỡng tỷ lệ khớp để sang SHADOW_OK', NULL::text),
  ('18.migration.shadow.sample-percent', 'INT', '5', 1, 100, '%', 'TENANT', false, 'migration', 550, 'Tỷ lệ lưu lượng nhân bản', NULL::text),
  ('18.migration.shadow.sample-retention-days', 'INT', '90', 7, 365, 'd', 'TENANT', false, 'migration', 560, 'Thời gian giữ mẫu so sánh chạy bóng (chỉ tổng kiểm tra)', NULL::text),
  ('18.migration.rollback-window-minutes', 'INT', '15', 5, 120, 'min', 'PLATFORM', false, 'migration', 570, 'Cửa sổ quay lui sau cắt chuyển', NULL::text),
  ('18.report.schedule', 'ENUM', '"MONTHLY"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'report', 580, 'Kỳ báo cáo vận hành tự động', '["MONTHLY", "QUARTERLY"]'),
  ('18.report.retention-months', 'INT', '24', 12, 120, 'month', 'TENANT', false, 'report', 590, 'Thời gian giữ báo cáo vận hành', NULL::text),
  ('18.degraded.read-only', 'BOOL', 'false', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'degraded', 600, 'Chế độ chỉ đọc của PH-18', NULL::text),
  ('18.outbox.retention-days', 'INT', '3', 1, 30, 'd', 'PLATFORM', false, 'outbox', 610, 'Thời gian giữ bản ghi outbox đã gửi', NULL::text)
) AS s(k, t, d, lo, hi, u, l, f, g, o, lab, av)
ON CONFLICT (tenant_id, param_key) DO NOTHING;
INSERT INTO ph18_ops.dlq_source (id, tenant_id, source_code, source_module, ingest_channel, replay_mode, replay_endpoint, payload_viewable, created_by, updated_by)
SELECT md5('ph18-src:' || s.c)::uuid, 'COMMON', s.c, s.m, s.ch, s.p, s.e, s.v, 'system:seed', 'system:seed' FROM (VALUES
  ('ph04-runtime', 'PH-04', 'KAFKA', 'KAFKA_TOPIC', '/integration/internal/v1/replays', true),
  ('ph10-event', 'PH-10', 'FEDERATED', 'EVENT_LAYER', '/event/internal/v1/replays', false),
  ('ph01-inbox', 'PH-01', 'API', 'HTTP_PORT', '/onboarding/internal/v1/replays', true),
  ('ph06-mdm-job', 'PH-06', 'API', 'HTTP_PORT', '/mdm/internal/v1/replays', true),
  ('ph08-dq', 'PH-08', 'API', 'HTTP_PORT', '/dq/internal/v1/replays', true),
  ('ph19-inbox', 'PH-19', 'API', 'HTTP_PORT', '/payment/internal/v1/replays', true)
) AS s(c, m, ch, p, e, v)
ON CONFLICT (tenant_id, source_code) DO NOTHING;
INSERT INTO ph18_ops.backup_object (id, tenant_id, object_code, name, object_kind, tool, schedule, rpo_minutes, rto_minutes, retention_days, target_location, recovery_tier, verification_interval_days, created_by, updated_by)
SELECT md5('ph18-bk:' || s.c)::uuid, 'COMMON', s.c, s.n, s.k, s.t, s.s, s.rpo, s.rto, s.ret, s.loc, s.tier, s.ver, 'system:seed', 'system:seed' FROM (VALUES
  ('pg-base', 'PostgreSQL mọi cụm, bản sao cơ sở', 'POSTGRES_BASE', 'CNPG_BARMAN', '0 1 * * *', 1440, 240, 35, 'kho-sao-luu-bat-bien/pg', 'TPH-1', 1),
  ('pg-wal', 'PostgreSQL WAL', 'POSTGRES_WAL', 'CNPG_BARMAN', 'lien-tuc-60s', 1, 240, 35, 'kho-sao-luu-bat-bien/pg-wal', 'TPH-1', 7),
  ('pg-tenant-export', 'Xuất logic theo tenant pg-core', 'TENANT_EXPORT', 'DH_TENANT_EXPORT', '0 2 * * *', 1440, 240, 35, 'kho-sao-luu-bat-bien/tenant-export', 'TPH-2', 30),
  ('garage-files', 'Garage, tệp nghiệp vụ', 'OBJECT_STORE', 'RCLONE', '0 * * * *', 60, 480, 35, 'kho-sao-luu-bat-bien/garage', 'TPH-2', 7),
  ('openbao-raft', 'OpenBao Raft snapshot', 'SECRET_STORE', 'OPENBAO_RAFT', '*/15 * * * *', 15, 60, 35, 'site-dr/openbao', 'TPH-0', 1),
  ('unseal-shares', 'Khóa transit niêm phong, mảnh khôi phục', 'OFFLINE_SHARES', 'SHAMIR_OFFLINE', 'khi-tao-va-xoay', NULL::integer, NULL::integer, 0, 'ngoai-tuyen-hai-noi', 'TPH-0', 365),
  ('k8s-resources', 'Tài nguyên Kubernetes', 'K8S_RESOURCES', 'VELERO', '0 3 * * *', 1440, 480, 35, 'kho-sao-luu-bat-bien/velero', 'TPH-1', 90),
  ('k8s-volumes', 'Volume không tự nhân bản', 'VOLUME', 'VELERO_KOPIA', '0 3 * * *', 1440, 480, 35, 'kho-sao-luu-bat-bien/kopia', 'TPH-2', 90),
  ('git-config', 'Kho Git cấu hình', 'GIT', 'GIT_MIRROR', 'theo-commit', 0, 120, 0, 'git-dr', 'TPH-0', 30),
  ('harbor-images', 'Harbor, ảnh và chữ ký', 'REGISTRY', 'HARBOR_REPLICATION', 'theo-phat-hanh', NULL::integer, 240, 0, 'harbor-dr', 'TPH-1', NULL::integer),
  ('clickhouse', 'ClickHouse', 'CLICKHOUSE', 'CLICKHOUSE_BACKUP', '0 4 * * *', 1440, 720, 35, 'kho-sao-luu/clickhouse', 'TPH-3', 30),
  ('audit-worm', 'Nhật ký kiểm toán WORM (PH-13)', 'AUDIT_WORM', 'PH13_WORM', '0 * * * *', 60, NULL::integer, 1825, 'kho-worm/audit', 'TPH-1', 30)
) AS s(c, n, k, t, s, rpo, rto, ret, loc, tier, ver)
ON CONFLICT (tenant_id, object_code) DO NOTHING;
INSERT INTO ph18_ops.work_calendar (id, tenant_id, calendar_code, name, inherit_common, created_by, updated_by)
VALUES (md5('ph18-cal:COMMON')::uuid, 'COMMON', 'DEFAULT', 'Lịch làm việc quốc gia', false, 'system:seed', 'system:seed')
ON CONFLICT (tenant_id, calendar_code) DO NOTHING;
-- @rollback DELETE FROM ph18_ops.work_calendar WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.backup_object WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.dlq_source WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.param_definition WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.param_namespace WHERE created_by = 'system:seed';

-- @changeset ph18-0951-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20 platform.tenant.created.v1): lịch DEFAULT kế thừa lịch quốc gia. Tham số dùng mặc định của param_definition, không chép dòng; chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph18_ops.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  IF p_tenant !~ '^T[0-9]{2}$' THEN
    RAISE EXCEPTION 'Mã tenant không hợp lệ: %', p_tenant USING ERRCODE = '22023';
  END IF;
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph18_ops.work_calendar (id, tenant_id, calendar_code, name, created_by, updated_by)
  VALUES (md5('ph18-cal:' || p_tenant)::uuid, p_tenant, 'DEFAULT', 'Lịch làm việc ' || p_tenant, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, calendar_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph18_ops.p_seed_tenant(text) IS 'Gọi khi PH-20 khởi tạo tenant: tạo lịch DEFAULT kế thừa COMMON; tham số đọc mặc định từ lược đồ khóa nên không chép.';
-- @rollback DROP PROCEDURE IF EXISTS ph18_ops.p_seed_tenant(text);

-- @file 18-0900-grants.sql
-- @changeset ph18-0990-grants runAlways:true splitStatements:false
-- Cấp theo bảng cha (không dùng ALL TABLES): phân vùng không có quyền trực tiếp, mọi truy cập qua bảng cha có RLS.
GRANT SELECT, INSERT, UPDATE ON ph18_ops.outbox_event, ph18_ops.inbox_event, ph18_ops.param_namespace, ph18_ops.param_definition, ph18_ops.param_change_request, ph18_ops.param_value, ph18_ops.param_value_version, ph18_ops.feature_flag, ph18_ops.egress_allowlist_entry, ph18_ops.param_bundle, ph18_ops.dlq_source, ph18_ops.error_guide, ph18_ops.dlq_group, ph18_ops.dlq_message, ph18_ops.dlq_payload_ref, ph18_ops.dlq_revision, ph18_ops.dlq_assignment, ph18_ops.replay_job, ph18_ops.replay_item, ph18_ops.notification_template, ph18_ops.notification_template_version, ph18_ops.notification_rule, ph18_ops.notification_message, ph18_ops.notification_delivery, ph18_ops.user_notification_pref, ph18_ops.suppression_entry, ph18_ops.task_type, ph18_ops.task_item, ph18_ops.task_reminder, ph18_ops.work_calendar, ph18_ops.calendar_holiday, ph18_ops.maintenance_window, ph18_ops.incident, ph18_ops.incident_link, ph18_ops.backup_object, ph18_ops.backup_run, ph18_ops.tenant_restore_request, ph18_ops.tenant_restore_step, ph18_ops.tenant_export_job, ph18_ops.dr_drill, ph18_ops.merge_transfer, ph18_ops.legacy_source, ph18_ops.migration_plan, ph18_ops.migration_plan_item, ph18_ops.migration_run, ph18_ops.migration_run_item_result, ph18_ops.migration_error_record, ph18_ops.credential_reissue_marker, ph18_ops.parallel_run_group, ph18_ops.cutover_checklist, ph18_ops.ops_report TO ph18_app;
-- Bảng chỉ thêm: ứng dụng chỉ đọc và thêm (trigger tg_*_append_only là lớp chặn thứ hai).
GRANT SELECT, INSERT ON ph18_ops.dlq_audit, ph18_ops.incident_timeline, ph18_ops.restore_verification, ph18_ops.migration_reconciliation, ph18_ops.shadow_comparison_sample, ph18_ops.cutover_log TO ph18_app;
-- Chỉ dọn dữ liệu kỹ thuật, tùy chọn, liên kết, mục DLQ hết hạn (xóa lan truyền bản sửa, tham chiếu, mục phát lại); đối tượng nghiệp vụ khác không xóa cứng.
GRANT DELETE ON ph18_ops.outbox_event, ph18_ops.inbox_event, ph18_ops.notification_message, ph18_ops.user_notification_pref, ph18_ops.task_reminder, ph18_ops.calendar_holiday, ph18_ops.incident_link, ph18_ops.dlq_message TO ph18_app;
REVOKE UPDATE ON ph18_ops.outbox_event FROM ph18_app;
GRANT SELECT ON ph18_ops.config_param, ph18_ops.notification TO ph18_app, ph18_readonly;
-- Vai worker (dh-migrate, dh-tenant-restore, dh-tenant-export): chỉ bảng di trú, khôi phục, xuất, sáp nhập, kết quả sao lưu; không đọc tham số ngoài lược đồ, không đọc DLQ, thông báo.
GRANT SELECT ON ph18_ops.backup_object, ph18_ops.legacy_source, ph18_ops.migration_plan, ph18_ops.migration_plan_item, ph18_ops.parallel_run_group, ph18_ops.param_definition, ph18_ops.param_value TO ph18_worker;
GRANT SELECT, INSERT, UPDATE ON ph18_ops.backup_run, ph18_ops.tenant_restore_request, ph18_ops.tenant_restore_step, ph18_ops.tenant_export_job, ph18_ops.merge_transfer, ph18_ops.migration_run, ph18_ops.migration_run_item_result, ph18_ops.migration_error_record, ph18_ops.credential_reissue_marker TO ph18_worker;
GRANT SELECT, INSERT ON ph18_ops.outbox_event, ph18_ops.restore_verification, ph18_ops.migration_reconciliation, ph18_ops.shadow_comparison_sample TO ph18_worker;
GRANT SELECT ON ph18_ops.config_param TO ph18_worker;
-- Báo cáo: đọc mọi bảng; không đọc payload DLQ, header ngữ cảnh, payload bản sửa, biến mẫu và người nhận thông báo, ảnh chụp bản ghi lỗi di trú.
GRANT SELECT ON ph18_ops.outbox_event, ph18_ops.inbox_event, ph18_ops.param_namespace, ph18_ops.param_definition, ph18_ops.param_change_request, ph18_ops.param_value, ph18_ops.param_value_version, ph18_ops.feature_flag, ph18_ops.egress_allowlist_entry, ph18_ops.param_bundle, ph18_ops.dlq_source, ph18_ops.error_guide, ph18_ops.dlq_group, ph18_ops.dlq_payload_ref, ph18_ops.dlq_assignment, ph18_ops.replay_job, ph18_ops.replay_item, ph18_ops.dlq_audit, ph18_ops.notification_template, ph18_ops.notification_template_version, ph18_ops.notification_rule, ph18_ops.notification_delivery, ph18_ops.user_notification_pref, ph18_ops.suppression_entry, ph18_ops.task_type, ph18_ops.task_item, ph18_ops.task_reminder, ph18_ops.work_calendar, ph18_ops.calendar_holiday, ph18_ops.maintenance_window, ph18_ops.incident, ph18_ops.incident_timeline, ph18_ops.incident_link, ph18_ops.backup_object, ph18_ops.backup_run, ph18_ops.restore_verification, ph18_ops.tenant_restore_request, ph18_ops.tenant_restore_step, ph18_ops.tenant_export_job, ph18_ops.dr_drill, ph18_ops.merge_transfer, ph18_ops.legacy_source, ph18_ops.migration_plan, ph18_ops.migration_plan_item, ph18_ops.migration_run, ph18_ops.migration_run_item_result, ph18_ops.migration_reconciliation, ph18_ops.credential_reissue_marker, ph18_ops.parallel_run_group, ph18_ops.shadow_comparison_sample, ph18_ops.cutover_checklist, ph18_ops.cutover_log, ph18_ops.ops_report TO ph18_readonly;
GRANT SELECT (id, tenant_id, dlq_key, source_code, source_module, flow_code, flow_version, stage, reason_code, error_code, error_class, error_message, attempts, trace_id, origin_topic, origin_partition, origin_offset, dlq_partition, dlq_offset, external_ref, first_failed_at, received_at, status, priority, group_id, assignee, missing_context, schema_ref, payload_location, payload_content_type, payload_size_bytes, payload_sha256, current_revision_no, occurrence_count, last_seen_at, discard_reason, resolved_at, closed_at, retention_until, created_at, created_by, updated_at, updated_by, version) ON ph18_ops.dlq_message TO ph18_readonly;
GRANT SELECT (id, tenant_id, dlq_id, dlq_received_at, revision_no, payload_location, payload_sha256, diff, reason, contains_restricted, status, approved_by, approved_at, rejected_reason, created_at, created_by, updated_at, updated_by, version) ON ph18_ops.dlq_revision TO ph18_readonly;
GRANT SELECT (id, tenant_id, caller_module, message_key, template_code, template_version_no, rule_id, source_event_id, category, channels, link, mode, priority, status, requested_at, dispatched_at, expires_at, created_at, created_by, updated_at, updated_by, version) ON ph18_ops.notification_message TO ph18_readonly;
GRANT SELECT (id, tenant_id, run_id, plan_item_id, source_record_ref, error_code, error_message, field_path, fix_status, fixed_by, fixed_at, fix_note, created_at, created_by, updated_at, updated_by, version) ON ph18_ops.migration_error_record TO ph18_readonly;
REVOKE EXECUTE ON PROCEDURE ph18_ops.p_ensure_partitions(regclass, date, integer), ph18_ops.p_drop_partitions_before(regclass, date) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE ph18_ops.p_ensure_partitions(regclass, date, integer), ph18_ops.p_drop_partitions_before(regclass, date) TO ph18_app;
GRANT EXECUTE ON PROCEDURE ph18_ops.p_seed_tenant(text) TO ph18_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
