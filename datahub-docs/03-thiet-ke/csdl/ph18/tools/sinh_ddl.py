#!/usr/bin/env python3
"""Sinh ddl/ph18_ops.sql (schema ph18_ops, D03-03-PH18) từ danh mục bảng khai báo ở sinh_ddl_bang_a|b.py.

Chạy từ thư mục csdl/ph18:  python3 tools/sinh_ddl.py
Chép khung từ csdl/ph17/tools/sinh_ddl.py. Trạng thái lấy từ BRIEF-PH18 §4 (sinh_ddl_core.ST_*), giá trị ngoài §4 liệt kê ở
D03-03-PH18 mục 10 (Đề nghị đồng bộ). Kết quả có dấu @file, @changeset, @rollback để tools/gen_liquibase.py sinh changelog.
DDL là nguồn chuẩn cho gen_tables_md.py, them_dac_ta_bang.py, gen_erd.py, sinh_test.py; không sửa tay tệp sinh ra.
Không cần extension: gen_random_uuid(), sha256() có sẵn ở PostgreSQL 16 (extension, nếu có, chỉ cài ở schema public).
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sinh_ddl_core import *
from sinh_ddl_bang_a import G_CORE, G_PARAM, G_DLQ, G_NOTIFY
from sinh_ddl_bang_b import G_TASK, G_INC, G_BACKUP, G_MIG, G_REPORT

FILE_GROUPS = [("18-0010-core.sql", G_CORE), ("18-0020-param.sql", G_PARAM), ("18-0030-dlq.sql", G_DLQ), ("18-0040-notify.sql", G_NOTIFY),
               ("18-0050-task.sql", G_TASK), ("18-0060-incident.sql", G_INC), ("18-0070-backup.sql", G_BACKUP), ("18-0080-migration.sql", G_MIG),
               ("18-0090-report.sql", G_REPORT)]
ALL = [t for _, g in FILE_GROUPS for t in g]
BY_NAME = {t["name"]: t for t in ALL}

HEAD = r"""-- =============================================================================
-- D03-03-PH18 · DDL schema ph18_ops, PH-18 Vận hành và xử lý lỗi
-- Phiên bản 0.1 · 2026-11-27 · Dự thảo
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
"""

SEED_NS = [("00", "PH00", "Tham số chung nền tảng"), ("onboarding", "PH01", "Kết nạp HTTT"), ("02", "PH02", "Danh mục dịch vụ"), ("04", "PH04", "Tích hợp"),
           ("05", "PH05", "Bộ điều hợp"), ("06", "PH06", "Dữ liệu chủ"), ("07.rdm", "PH07", "Danh mục dùng chung"), ("08", "PH08", "Chất lượng dữ liệu"),
           ("09", "PH09", "Quyền riêng tư"), ("10", "PH10", "Sự kiện"), ("11", "PH11", "Quy trình"), ("12", "PH12", "Định danh và phân quyền"),
           ("13", "PH13", "Giám sát và kiểm toán"), ("14", "PH14", "Kết nối quốc gia"), ("15", "PH15", "Cổng nhà phát triển"), ("16", "PH16", "Báo cáo chỉ tiêu"),
           ("17", "PH17", "Trợ lý AI"), ("18", "PH18", "Vận hành và xử lý lỗi"), ("20", "PH20", "Quản trị tenant"), ("ff", "PH18", "Cờ tính năng")]
APPROVAL_OWNER = {"14": "PH14", "17": "PH17"}

# Tham số 18.* (nguồn: BRIEF-PH18 §3, đối chiếu FRS PH-18 §8.2 khi có). (khóa, kiểu, mặc định, min, max, đơn vị, mức, ★, nhóm, nhãn)
SEED_18 = [
    ("18.param.cache-seconds", "INTEGER", "60", 1, 60, "s", "PLATFORM", False, "param", "Thời gian đệm tham số ở PH đọc"),
    ("18.param.change-request-ttl-hours", "INTEGER", "72", 1, 720, "h", "TENANT", False, "param", "Hạn đề nghị đổi tham số chờ duyệt"),
    ("18.param.history-retention-years", "INTEGER", "5", 1, 10, "y", "PLATFORM", False, "param", "Thời gian giữ lịch sử tham số"),
    ("18.dlq.payload.inline-max-kb", "INTEGER", "256", 16, 256, "KB", "PLATFORM", False, "dlq", "Ngưỡng payload giữ trong CSDL"),
    ("18.dlq.dedup-window-days", "INTEGER", "30", 1, 90, "d", "PLATFORM", False, "dlq", "Cửa sổ khử trùng dlqKey"),
    ("18.dlq.retention.closed-days", "INTEGER", "90", 30, 365, "d", "TENANT", True, "dlq", "Thời gian giữ mục DLQ đã đóng"),
    ("18.dlq.retention.metadata-days", "INTEGER", "365", 90, 1825, "d", "TENANT", False, "dlq", "Thời gian giữ siêu dữ liệu mục hết hạn"),
    ("18.dlq.audit.retention-months", "INTEGER", "60", 60, 120, "month", "PLATFORM", False, "dlq", "Thời gian giữ nhật ký thao tác DLQ"),
    ("18.dlq.replay.batch-max", "INTEGER", "1000", 1, 10000, "item", "TENANT", False, "dlq", "Số mục tối đa một lượt phát lại"),
    ("18.dlq.replay.approval-threshold", "INTEGER", "100", 1, 10000, "item", "TENANT", True, "dlq", "Ngưỡng phát lại cần bốn mắt"),
    ("18.dlq.replay.rate-per-minute", "INTEGER", "60", 1, 6000, "item/min", "TENANT", False, "dlq", "Tốc độ phát lại mặc định"),
    ("18.dlq.threshold.open-count", "INTEGER", "50", 1, 100000, "item", "TENANT", False, "dlq", "Ngưỡng mục mở phát sự kiện vượt ngưỡng"),
    ("18.dlq.discard.reason-min-chars", "INTEGER", "10", 10, 200, "char", "PLATFORM", False, "dlq", "Độ dài tối thiểu lý do bỏ qua"),
    ("18.notify.delivery-retention-days", "INTEGER", "180", 30, 730, "d", "TENANT", False, "notify", "Thời gian giữ nhật ký gửi"),
    ("18.notify.retry.max-attempts", "INTEGER", "5", 1, 20, "lần", "PLATFORM", False, "notify", "Số lần thử gửi tối đa"),
    ("18.notify.quiet-hours", "TIME_RANGE", '"22:00-06:00"', None, None, None, "TENANT", False, "notify", "Giờ yên lặng mặc định"),
    ("18.notify.sms.enabled", "BOOLEAN", "false", None, None, None, "TENANT", False, "notify", "Bật kênh SMS"),
    ("18.task.retention-days", "INTEGER", "365", 90, 1825, "d", "TENANT", False, "task", "Thời gian giữ việc đã đóng"),
    ("18.task.reminder-before-hours", "INTEGER", "24", 1, 168, "h", "TENANT", False, "task", "Nhắc trước hạn"),
    ("18.calendar.timezone", "STRING", '"Asia/Ho_Chi_Minh"', None, None, None, "PLATFORM", False, "calendar", "Múi giờ lịch"),
    ("18.calendar.working-days", "LIST_STRING", '["MON", "TUE", "WED", "THU", "FRI"]', None, None, None, "TENANT", False, "calendar", "Ngày làm việc trong tuần"),
    ("18.incident.retention-years", "INTEGER", "5", 3, 10, "y", "PLATFORM", False, "incident", "Thời gian giữ hồ sơ sự cố"),
    ("18.backup.verification-interval-days", "INTEGER", "1", 1, 90, "d", "PLATFORM", False, "backup", "Chu kỳ kiểm tra khôi phục"),
    ("18.restore.target-hours", "INTEGER", "4", 1, 24, "h", "PLATFORM", False, "backup", "Mục tiêu thời gian khôi phục tenant"),
    ("18.export.download-ttl-days", "INTEGER", "7", 1, 30, "d", "TENANT", False, "backup", "Hạn tải tệp xuất tenant"),
    ("18.migration.shadow.match-threshold-percent", "DECIMAL", "99.5", 90, 100, "%", "TENANT", True, "migration", "Ngưỡng khớp chạy song song"),
    ("18.migration.shadow.sample-retention-days", "INTEGER", "90", 7, 365, "d", "TENANT", False, "migration", "Thời gian giữ mẫu so sánh"),
    ("18.migration.cutover.rollback-minutes", "INTEGER", "15", 5, 120, "min", "PLATFORM", False, "migration", "Cửa sổ quay lui sau cắt chuyển"),
    ("18.report.retention-months", "INTEGER", "24", 12, 120, "month", "TENANT", False, "report", "Thời gian giữ báo cáo vận hành"),
    ("18.outbox.retention-days", "INTEGER", "3", 1, 30, "d", "PLATFORM", False, "core", "Thời gian giữ outbox đã phát"),
]

SEED_BACKUP = [
    ("pg-base", "PostgreSQL mọi cụm, bản sao cơ sở", "POSTGRES_BASE", "CNPG_BARMAN", "0 1 * * *", 1440, 240, 35, "kho-sao-luu-bat-bien/pg", "TPH-1", 1),
    ("pg-wal", "PostgreSQL WAL", "POSTGRES_WAL", "CNPG_BARMAN", "lien-tuc-60s", 1, 240, 35, "kho-sao-luu-bat-bien/pg-wal", "TPH-1", 7),
    ("pg-tenant-export", "Xuất logic theo tenant pg-core", "TENANT_EXPORT", "DH_TENANT_EXPORT", "0 2 * * *", 1440, 240, 35, "kho-sao-luu-bat-bien/tenant-export", "TPH-2", 30),
    ("garage-files", "Garage, tệp nghiệp vụ", "OBJECT_STORE", "RCLONE", "0 * * * *", 60, 480, 35, "kho-sao-luu-bat-bien/garage", "TPH-2", 7),
    ("openbao-raft", "OpenBao Raft snapshot", "SECRET_STORE", "OPENBAO_RAFT", "*/15 * * * *", 15, 60, 35, "site-dr/openbao", "TPH-0", 1),
    ("unseal-shares", "Khóa transit niêm phong, mảnh khôi phục", "OFFLINE_SHARES", "SHAMIR_OFFLINE", "khi-tao-va-xoay", None, None, 0, "ngoai-tuyen-hai-noi", "TPH-0", 365),
    ("k8s-resources", "Tài nguyên Kubernetes", "K8S_RESOURCES", "VELERO", "0 3 * * *", 1440, 480, 35, "kho-sao-luu-bat-bien/velero", "TPH-1", 90),
    ("k8s-volumes", "Volume không tự nhân bản", "VOLUME", "VELERO_KOPIA", "0 3 * * *", 1440, 480, 35, "kho-sao-luu-bat-bien/kopia", "TPH-2", 90),
    ("git-config", "Kho Git cấu hình", "GIT", "GIT_MIRROR", "theo-commit", 0, 120, 0, "git-dr", "TPH-0", 30),
    ("harbor-images", "Harbor, ảnh và chữ ký", "REGISTRY", "HARBOR_REPLICATION", "theo-phat-hanh", None, 240, 0, "harbor-dr", "TPH-1", None),
    ("clickhouse", "ClickHouse", "CLICKHOUSE", "CLICKHOUSE_BACKUP", "0 4 * * *", 1440, 720, 35, "kho-sao-luu/clickhouse", "TPH-3", 30),
    ("audit-worm", "Nhật ký kiểm toán WORM (PH-13)", "AUDIT_WORM", "PH13_WORM", "0 * * * *", 60, None, 1825, "kho-worm/audit", "TPH-1", 30),
]

SEED_SOURCES = [("PH04-RUNTIME", "PH04", "KAFKA", "PH04_RUNTIME", "/integration/internal/v1/replays", True),
                ("PH10-EVENT", "PH10", "FEDERATED", "PH10_EVENT", "/event/internal/v1/replays", False),
                ("PH01-INBOX", "PH01", "API", "REPLAY_PORT", "/onboarding/internal/v1/replays", True),
                ("PH06-MDM-JOB", "PH06", "API", "REPLAY_PORT", "/mdm/internal/v1/replays", True),
                ("PH08-DQ", "PH08", "API", "REPLAY_PORT", "/dq/internal/v1/replays", True),
                ("PH19-INBOX", "PH19", "API", "REPLAY_PORT", "/payment/internal/v1/replays", True)]


def q(s):
    return s.replace("'", "''")


def lit(v):
    return "NULL" if v is None else ("'%s'" % q(str(v)))


def seed_sql():
    P = S
    L = ["-- @file 18-0095-seed.sql",
         "-- @changeset ph18-0950-seed-common splitStatements:false context:seed",
         "-- Dữ liệu nền tảng (tenant COMMON): không gian tên, lược đồ khóa 18.*, nguồn DLQ, đối tượng sao lưu D03-09 §8.2, lịch quốc gia mặc định.",
         "SET app.tenant_id = 'COMMON';"]
    L.append(f"INSERT INTO {P}.param_namespace (id, tenant_id, code, owner_module, title, approval_owner, created_by, updated_by)\nSELECT md5('ph18-ns:' || s.c)::uuid, 'COMMON', s.c, s.m, s.t, s.a, 'system:seed', 'system:seed' FROM (VALUES\n  "
             + ",\n  ".join("('%s', '%s', '%s', '%s')" % (c, m, q(t), APPROVAL_OWNER.get(c, "PH18")) for c, m, t in SEED_NS)
             + "\n) AS s(c, m, t, a)\nON CONFLICT (tenant_id, code) DO NOTHING;")
    rows = []
    for i, (k, typ, d, lo, hi, unit, lvl, star, grp, lab) in enumerate(SEED_18):
        rows.append("('%s', '%s', '%s', %s, %s, %s, '%s', %s, '%s', %d, '%s')" % (k, typ, q(d), "NULL::numeric" if lo is None else lo, "NULL::numeric" if hi is None else hi,
                                                                               "NULL::text" if unit is None else "'%s'" % unit, lvl, str(star).lower(), grp, (i + 1) * 10, q(lab)))
    L.append(f"INSERT INTO {P}.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, min_value, max_value, unit, level, security_flag, display_group, display_order, label, created_by, updated_by)\n"
             f"SELECT md5('ph18-def:' || s.k)::uuid, 'COMMON', '18', s.k, s.t, s.d::jsonb, s.lo, s.hi, s.u, s.l, s.f, s.g, s.o, s.lab, 'system:seed', 'system:seed' FROM (VALUES\n  "
             + ",\n  ".join(rows) + "\n) AS s(k, t, d, lo, hi, u, l, f, g, o, lab)\nON CONFLICT (tenant_id, param_key) DO NOTHING;")
    L.append(f"INSERT INTO {P}.dlq_source (id, tenant_id, source_code, source_module, ingest_channel, replay_port, replay_endpoint, payload_viewable, created_by, updated_by)\n"
             f"SELECT md5('ph18-src:' || s.c)::uuid, 'COMMON', s.c, s.m, s.ch, s.p, s.e, s.v, 'system:seed', 'system:seed' FROM (VALUES\n  "
             + ",\n  ".join("('%s', '%s', '%s', '%s', '%s', %s)" % (c, m, ch, p, e, str(v).lower()) for c, m, ch, p, e, v in SEED_SOURCES)
             + "\n) AS s(c, m, ch, p, e, v)\nON CONFLICT (tenant_id, source_code) DO NOTHING;")
    rows = []
    for c, n, k, tool, sch, rpo, rto, ret, loc, tier, ver in SEED_BACKUP:
        rows.append("('%s', '%s', '%s', '%s', '%s', %s, %s, %d, '%s', '%s', %s)" % (c, q(n), k, tool, sch, "NULL::integer" if rpo is None else rpo,
                                                                               "NULL::integer" if rto is None else rto, ret, loc, tier, "NULL::integer" if ver is None else ver))
    L.append(f"INSERT INTO {P}.backup_object (id, tenant_id, object_code, name, object_kind, tool, schedule, rpo_minutes, rto_minutes, retention_days, target_location, recovery_tier, verification_interval_days, created_by, updated_by)\n"
             f"SELECT md5('ph18-bk:' || s.c)::uuid, 'COMMON', s.c, s.n, s.k, s.t, s.s, s.rpo, s.rto, s.ret, s.loc, s.tier, s.ver, 'system:seed', 'system:seed' FROM (VALUES\n  "
             + ",\n  ".join(rows) + "\n) AS s(c, n, k, t, s, rpo, rto, ret, loc, tier, ver)\nON CONFLICT (tenant_id, object_code) DO NOTHING;")
    L.append(f"INSERT INTO {P}.work_calendar (id, tenant_id, calendar_code, name, inherit_common, created_by, updated_by)\n"
             f"VALUES (md5('ph18-cal:COMMON')::uuid, 'COMMON', 'DEFAULT', 'Lịch làm việc quốc gia', false, 'system:seed', 'system:seed')\nON CONFLICT (tenant_id, calendar_code) DO NOTHING;")
    L.append("-- @rollback DELETE FROM ph18_ops.work_calendar WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.backup_object WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.dlq_source WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.param_definition WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.param_namespace WHERE created_by = 'system:seed';")
    L.append("")
    L.append("-- @changeset ph18-0951-fn-seed-tenant splitStatements:false")
    L.append("-- Khởi tạo tenant (PH-20 platform.tenant.created.v1): lịch DEFAULT kế thừa lịch quốc gia. Tham số dùng mặc định của param_definition, không chép dòng; chạy lại không nhân bản.")
    L.append(f"""CREATE OR REPLACE PROCEDURE {P}.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  IF p_tenant !~ '^T[0-9]{{2}}$' THEN
    RAISE EXCEPTION 'Mã tenant không hợp lệ: %', p_tenant USING ERRCODE = '22023';
  END IF;
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO {P}.work_calendar (id, tenant_id, calendar_code, name, created_by, updated_by)
  VALUES (md5('ph18-cal:' || p_tenant)::uuid, p_tenant, 'DEFAULT', 'Lịch làm việc ' || p_tenant, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, calendar_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE {P}.p_seed_tenant(text) IS 'Gọi khi PH-20 khởi tạo tenant: tạo lịch DEFAULT kế thừa COMMON; tham số đọc mặc định từ lược đồ khóa nên không chép.';
-- @rollback DROP PROCEDURE IF EXISTS {P}.p_seed_tenant(text);""")
    return "\n".join(L)


VIEWS = f"""-- @file 18-0091-views.sql
-- @changeset ph18-0900-view-config-param splitStatements:false
-- Tương thích DD-14 (D02-07 dòng 151, FRS-07 nêu ph18_ops.config_param): khung nhìn giá trị hiệu lực theo tenant phiên. security_invoker nên RLS của bảng gốc áp cho người đọc.
CREATE OR REPLACE VIEW {S}.config_param WITH (security_invoker = true) AS
SELECT d.param_key                                                     AS key,
       COALESCE(t.value, p.value, d.default_value)                     AS value,
       d.json_schema                                                   AS schema,
       CASE WHEN t.id IS NOT NULL THEN 'TENANT' ELSE 'PLATFORM' END    AS scope,
       COALESCE(t.effective_from, p.effective_from, d.created_at)      AS effective_from,
       current_setting('app.tenant_id', false)                         AS tenant_id,
       d.namespace_code, d.value_type, d.level, d.security_flag, d.display_group,
       COALESCE(t.current_version_no, p.current_version_no, 0)         AS version_no
  FROM {S}.param_definition d
  LEFT JOIN {S}.param_value p ON p.definition_id = d.id AND p.tenant_id = 'COMMON'
  LEFT JOIN {S}.param_value t ON t.definition_id = d.id AND t.tenant_id = current_setting('app.tenant_id', false) AND t.tenant_id <> 'COMMON'
 WHERE d.removal_date IS NULL OR d.removal_date >= current_date;
COMMENT ON VIEW {S}.config_param IS 'DD-14 Tham số cấu hình: key, value, schema, scope (PLATFORM hoặc TENANT), effective_from; giá trị hiệu lực = ghi đè tenant, nếu không thì giá trị nền tảng, nếu không thì mặc định của lược đồ khóa.';
-- @rollback DROP VIEW IF EXISTS {S}.config_param;

-- @changeset ph18-0901-view-notification splitStatements:false
-- Tương thích DD-13 (D02-07 dòng 150): hộp thông báo trong ứng dụng.
CREATE OR REPLACE VIEW {S}.notification WITH (security_invoker = true) AS
SELECT d.id, d.tenant_id, d.recipient_user_id, m.category, d.rendered_title AS title, m.link, d.read_at, to_jsonb(m.channels) AS channels_sent,
       d.status, d.queued_at AS created_at
  FROM {S}.notification_delivery d
  JOIN {S}.notification_message m ON m.tenant_id = d.tenant_id AND m.id = d.message_id
 WHERE d.channel = 'IN_APP';
COMMENT ON VIEW {S}.notification IS 'DD-13 Thông báo: recipient_user_id, category, title, link, read_at, channels_sent; chỉ kênh IN_APP.';
-- @rollback DROP VIEW IF EXISTS {S}.notification;
"""


def grants():
    names = [t["name"] for t in ALL]
    full = lambda ns: ", ".join(f"{S}.{n}" for n in ns)
    app_rw = [t["name"] for t in ALL if not t["append_only"]]
    app_del = [t["name"] for t in ALL if t["app_delete"]]
    app_ins = [t["name"] for t in ALL if t["append_only"]]
    w_r = [t["name"] for t in ALL if t["worker"] == "r"] + ["param_definition", "param_value"]
    w_rw = [t["name"] for t in ALL if t["worker"] == "rw"]
    w_i = [t["name"] for t in ALL if t["worker"] == "i"]
    ro_full = [t["name"] for t in ALL if not t["ro_hide"]]
    o = ["-- @file 18-0900-grants.sql", "-- @changeset ph18-0990-grants runAlways:true splitStatements:false",
         "-- Cấp theo bảng cha (không dùng ALL TABLES): phân vùng không có quyền trực tiếp, mọi truy cập qua bảng cha có RLS.",
         f"GRANT SELECT, INSERT, UPDATE ON {full(app_rw)} TO ph18_app;",
         "-- Bảng chỉ thêm: ứng dụng chỉ đọc và thêm (trigger tg_*_append_only là lớp chặn thứ hai).",
         f"GRANT SELECT, INSERT ON {full(app_ins)} TO ph18_app;",
         "-- Chỉ dọn dữ liệu kỹ thuật, tùy chọn, liên kết, mục DLQ hết hạn (xóa lan truyền bản sửa, tham chiếu, mục phát lại); đối tượng nghiệp vụ khác không xóa cứng.",
         f"GRANT DELETE ON {full(app_del + ['dlq_message'])} TO ph18_app;",
         f"REVOKE UPDATE ON {S}.outbox_event FROM ph18_app;",
         f"GRANT SELECT ON {S}.config_param, {S}.notification TO ph18_app, ph18_readonly;",
         "-- Vai worker (dh-migrate, dh-tenant-restore, dh-tenant-export): chỉ bảng di trú, khôi phục, xuất, sáp nhập, kết quả sao lưu; không đọc tham số ngoài lược đồ, không đọc DLQ, thông báo.",
         f"GRANT SELECT ON {full(w_r)} TO ph18_worker;",
         f"GRANT SELECT, INSERT, UPDATE ON {full(w_rw)} TO ph18_worker;",
         f"GRANT SELECT, INSERT ON {full(w_i)} TO ph18_worker;",
         f"GRANT SELECT ON {S}.config_param TO ph18_worker;",
         "-- Báo cáo: đọc mọi bảng; không đọc payload DLQ, header ngữ cảnh, payload bản sửa, biến mẫu và người nhận thông báo, ảnh chụp bản ghi lỗi di trú.",
         f"GRANT SELECT ON {full(ro_full)} TO ph18_readonly;"]
    for t in ALL:
        if t["ro_hide"]:
            cols = [c for c, *_ in parse_cols(t) if c not in t["ro_hide"]]
            o.append(f"GRANT SELECT ({', '.join(cols)}) ON {S}.{t['name']} TO ph18_readonly;")
    o += [f"REVOKE EXECUTE ON PROCEDURE {S}.p_ensure_partitions(regclass, date, integer), {S}.p_drop_partitions_before(regclass, date) FROM PUBLIC;",
          f"GRANT EXECUTE ON PROCEDURE {S}.p_ensure_partitions(regclass, date, integer), {S}.p_drop_partitions_before(regclass, date) TO ph18_app;",
          f"GRANT EXECUTE ON PROCEDURE {S}.p_seed_tenant(text) TO ph18_app;",
          "-- @rollback -- Không thu hồi tự động.", "", "RESET ROLE;", ""]
    return "\n".join(o)


def render_all():
    names = set(BY_NAME)
    for t in ALL:
        for cn, cd in t["cons"]:
            for m in re.finditer(r"REFERENCES %s\.(\w+) \(tenant_id, (\w+)\)" % S, cd):
                tgt = BY_NAME[m.group(1)]
                if m.group(2) == "id" and not tgt["tid"]:
                    raise SystemExit(f"{t['name']} -> {m.group(1)} cần tid=True")
    out = [HEAD]
    seq = 100
    for fname, grp in FILE_GROUPS:
        out.append(f"\n-- @file {fname}")
        for t in grp:
            out.append(render_table(t, seq))
            out.append("")
            seq += 10
    out.append(VIEWS)
    out.append(seed_sql())
    out.append("")
    out.append(grants())
    return "\n".join(out), len(ALL)


def main():
    sql, n = render_all()
    open(os.path.join(ROOT, "ddl", "ph18_ops.sql"), "w", encoding="utf-8").write(sql)
    print(f"{n} bảng → ddl/ph18_ops.sql")


if __name__ == "__main__":
    main()
