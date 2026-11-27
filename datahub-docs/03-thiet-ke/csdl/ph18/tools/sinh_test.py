#!/usr/bin/env python3
"""Sinh test/ph18_isolation_test.sql (D03-03-PH18): kiểm cô lập tenant cho MỌI bảng của ph18_ops và các quy tắc chốt ở CSDL.

Chạy từ thư mục csdl/ph18:  python3 tools/sinh_test.py
Phần 1 sinh tự động từ danh mục bảng: mỗi bảng có một dòng mẫu (tenant T90, hoặc COMMON với bảng chỉ dòng COMMON), rồi phiên T91
kiểm không đọc (trừ dòng COMMON dùng chung), không chèn thay, không sửa, không xóa được dòng đó; quay lại T90 thấy đúng một dòng.
Phần 0 kiểm danh mục hệ thống (FORCE RLS, bốn chính sách, phân vùng không cấp quyền). Phần 2 viết tay: chỉ thêm, máy trạng thái,
bốn mắt, kiểm miền tham số, payload DLQ, vai readonly, worker, khung nhìn DD-13, DD-14. Mẫu ph17_isolation_test.sql.
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sinh_ddl_core import *
from sinh_ddl import ALL, BY_NAME

APP_DELETE = {t["name"] for t in ALL if t["app_delete"]} | {"dlq_message"}
SKIP_AUTO = {"id", "tenant_id", "created_at", "created_by", "updated_at", "updated_by", "version"}


def enum_first(t):
    out = {}
    for _, cd in t["cons"]:
        for col, val in re.findall(r"\b(\w+) IN \('([^']+)'", cd):
            out.setdefault(col, "'%s'" % val)
    return out


def fk_fill(t):
    out = {}
    for _, cd in t["cons"]:
        m = re.match(r"FOREIGN KEY \(([^)]*)\) REFERENCES %s\.(\w+) \(([^)]*)\)" % S, cd)
        if not m:
            continue
        cols = [c.strip() for c in m.group(1).split(",")]
        tcols = [c.strip() for c in m.group(3).split(",")]
        for c, tc in zip(cols, tcols):
            if c == "tenant_id":
                continue
            if tc == "id":
                out[c] = f"pg_temp.id('{m.group(2)}')"
            elif tc in ("received_at", "queued_at", "occurred_at", "sampled_at"):
                out[c] = "pg_temp.ts()"
            else:
                out[c] = BY_NAME[m.group(2)]["sample"][tc]
    return out


def auto(typ):
    if typ.startswith("uuid"):
        return "gen_random_uuid()"
    if typ.startswith("char(64)"):
        return "repeat('0', 64)"
    if typ.startswith("char(32)"):
        return "repeat('0', 32)"
    if typ.endswith("[]"):
        return "'{}'"
    if typ.startswith(("varchar", "text")):
        m = re.match(r"varchar\((\d+)\)", typ)
        return "'Giá trị kiểm thử mẫu'" if not m or int(m.group(1)) >= 24 else "'x'"
    if typ.startswith(("integer", "bigint", "smallint", "numeric")):
        return "1"
    if typ.startswith("boolean"):
        return "false"
    if typ.startswith("timestamptz"):
        return "now()"
    if typ.startswith("date"):
        return "current_date"
    if typ.startswith("time"):
        return "'08:00'"
    if typ.startswith("jsonb"):
        return "'{}'::jsonb"
    raise SystemExit("Không tự điền được kiểu " + typ)


def row_values(t, tenant, rid):
    en, fkv = enum_first(t), fk_fill(t)
    cols, vals = ["id", "tenant_id", "created_by", "updated_by"], [rid, f"'{tenant}'", "'kiem-thu'", "'kiem-thu'"]
    for c, typ, nn, has_def in parse_cols(t):
        if c in SKIP_AUTO:
            continue
        if c in t["sample"]:
            v = t["sample"][c]
        elif c in fkv and (nn or c.endswith("_received_at")):
            v = fkv[c]
        elif nn and not has_def:
            v = en.get(c) or auto(typ)
        else:
            continue
        cols.append(c)
        vals.append(v)
    return cols, vals


def insert(t, tenant, rid):
    cols, vals = row_values(t, tenant, rid)
    return f"INSERT INTO {S}.{t['name']} ({', '.join(cols)}) VALUES ({', '.join(vals)})"


def has_update(t):
    return not t["append_only"] and t["name"] != "outbox_event"


def esc(s):
    return s.replace("$q$", "")


HEAD = """-- =============================================================================
-- D03-03-PH18 · Kiểm thử DDL ph18_ops: cô lập tenant (RLS) cho mọi bảng, dòng COMMON dùng chung chỉ phiên COMMON ghi, bảng chỉ thêm,
-- máy trạng thái DLQ, phát lại, tham số, mẫu thông báo, việc, sự cố, khôi phục, di trú, cắt chuyển; bốn mắt; kiểm miền và trần tham số;
-- payload DLQ gốc không sửa; vai readonly không đọc payload; vai worker chỉ bảng di trú, khôi phục; phân vùng không truy cập trực tiếp;
-- khung nhìn tương thích DD-13 notification, DD-14 config_param. TỆP SINH bởi tools/sinh_test.py; sửa ở đó rồi sinh lại.
-- Chạy sau ph18_ops.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d ph18_test -f ph18_isolation_test.sql
-- pg_temp.expect chạy SQL động, mong đúng SQLSTATE (23514 check, 23505 unique, 23503 khóa ngoại, 42501 quyền hoặc RLS,
-- 55000 bất biến, chỉ thêm hoặc chuyển trạng thái sai) và ghi PASS; sai thì RAISE dừng tệp. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- =============================================================================
\\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_ops_app') THEN CREATE ROLE dh_ops_app LOGIN NOBYPASSRLS; END IF;
  GRANT ph18_app TO dh_ops_app;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_ops_ro') THEN CREATE ROLE dh_ops_ro LOGIN NOBYPASSRLS; END IF;
  GRANT ph18_readonly TO dh_ops_ro;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_ops_worker') THEN CREATE ROLE dh_ops_worker LOGIN NOBYPASSRLS; END IF;
  GRANT ph18_worker TO dh_ops_worker;
END $$;

CREATE FUNCTION pg_temp.expect(p_sql text, p_state text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE ok boolean := false;
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = p_state THEN ok := true;
    ELSE RAISE EXCEPTION 'FAIL %: SQLSTATE % (mong %): %', p_label, SQLSTATE, p_state, SQLERRM; END IF;
  END;
  IF NOT ok THEN RAISE EXCEPTION 'FAIL %: không bị chặn', p_label; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE FUNCTION pg_temp.is_true(p_sql text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE r boolean;
BEGIN
  EXECUTE p_sql INTO r;
  IF r IS NOT TRUE THEN RAISE EXCEPTION 'FAIL %', p_label; END IF;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE FUNCTION pg_temp.ok(p_sql text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RAISE NOTICE 'PASS %', p_label;
END $$;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
CREATE TEMP TABLE ts0 (v timestamptz);
INSERT INTO ts0 VALUES (date_trunc('second', now()));
@@IDS@@
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;
CREATE FUNCTION pg_temp.ts() RETURNS timestamptz LANGUAGE sql AS $$ SELECT v FROM ts0 $$;
GRANT SELECT ON pg_temp.ids, pg_temp.ts0 TO PUBLIC;
"""


def catalog_checks():
    o = ["", "-- ---------- 0. Danh mục hệ thống: FORCE RLS, bốn chính sách, phân vùng không cấp quyền, không extension trong schema ----------"]
    n = len(ALL)
    names = ", ".join("'%s'" % t["name"] for t in ALL)
    o.append(f"SELECT pg_temp.is_true($q$SELECT count(*) = {n} FROM pg_class c WHERE c.relnamespace = '{S}'::regnamespace AND c.relkind IN ('r', 'p') AND NOT c.relispartition$q$, '0.01 schema có đúng {n} bảng cha');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT bool_and(c.relrowsecurity AND c.relforcerowsecurity) FROM pg_class c WHERE c.relnamespace = '{S}'::regnamespace AND c.relname IN ({names})$q$, '0.02 mọi bảng bật và FORCE RLS');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT bool_and(k = 4) FROM (SELECT c.relname, count(p.polname) k FROM pg_class c LEFT JOIN pg_policy p ON p.polrelid = c.oid WHERE c.relnamespace = '{S}'::regnamespace AND c.relname IN ({names}) GROUP BY c.relname) x$q$, '0.03 mọi bảng có bốn chính sách RLS');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT bool_and(a.attnotnull) AND count(*) = {n} * 7 FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid WHERE c.relnamespace = '{S}'::regnamespace AND c.relname IN ({names}) AND a.attname IN ('id', 'tenant_id', 'created_at', 'created_by', 'updated_at', 'updated_by', 'version')$q$, '0.04 mọi bảng có bảy cột ngữ cảnh NOT NULL');")
    parts = [t["name"] for t in ALL if t["part"]]
    o.append(f"SELECT pg_temp.is_true($q$SELECT count(*) = {len(parts)} FROM pg_partitioned_table p JOIN pg_class c ON c.oid = p.partrelid WHERE c.relnamespace = '{S}'::regnamespace$q$, '0.05 có {len(parts)} bảng phân vùng ({', '.join(parts)})');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT bool_and(NOT has_table_privilege('ph18_app', c.oid, 'SELECT') AND NOT has_table_privilege('ph18_readonly', c.oid, 'SELECT') AND NOT has_table_privilege('ph18_worker', c.oid, 'SELECT')) AND count(*) >= {len(parts) * 4} FROM pg_class c WHERE c.relnamespace = '{S}'::regnamespace AND c.relispartition$q$, '0.06 phân vùng không cấp quyền trực tiếp cho vai nào, mỗi bảng phân vùng có sẵn ≥ 4 tháng');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT NOT EXISTS (SELECT 1 FROM pg_extension WHERE extnamespace = '{S}'::regnamespace)$q$, '0.07 không có extension trong schema {S}');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT NOT rolcanlogin AND NOT rolbypassrls FROM pg_roles WHERE rolname = 'ph18_owner'$q$, '0.08 ph18_owner NOLOGIN, không BYPASSRLS');")
    o.append(f"SELECT pg_temp.is_true($q$SELECT count(*) = 4 FROM pg_roles WHERE rolname IN ('ph18_owner', 'ph18_app', 'ph18_readonly', 'ph18_worker') AND NOT rolbypassrls$q$, '0.09 bốn vai ph18_* không BYPASSRLS');")
    return o


def isolation():
    o = ["", "-- ---------- 1. Cô lập tenant từng bảng (sinh tự động) ----------", "SET ROLE dh_ops_app;"]
    k = 0
    for t in ALL:
        n = t["name"]
        own = "COMMON" if t["only_common"] else "T90"
        k += 1
        lab = f"1.{k:02d} {n}"
        o.append(f"-- {n} ({t['en']})")
        o.append(f"SET app.tenant_id = '{own}';")
        o.append(f"SELECT pg_temp.ok($q${insert(t, own, f'pg_temp.id(' + chr(39) + n + chr(39) + ')')}$q$, '{lab} a chèn dòng mẫu {own}');")
        o.append("SET app.tenant_id = 'T91';")
        seen = 1 if t["only_common"] else 0
        o.append(f"SELECT pg_temp.is_true($q$SELECT count(*) = {seen} FROM {S}.{n} WHERE id = pg_temp.id('{n}')$q$, '{lab} b T91 {'đọc được dòng COMMON dùng chung' if seen else 'không đọc dòng ' + own}');")
        o.append(f"SELECT pg_temp.expect($q${insert(t, own, 'gen_random_uuid()')}$q$, '42501', '{lab} c T91 không chèn dòng của {own}');")
        if has_update(t):
            o.append(f"SELECT pg_temp.is_true($q$WITH u AS (UPDATE {S}.{n} SET updated_by = 't91-x' WHERE id = pg_temp.id('{n}') RETURNING 1) SELECT count(*) = 0 FROM u$q$, '{lab} d T91 sửa không được dòng nào');")
        else:
            o.append(f"SELECT pg_temp.expect($q$UPDATE {S}.{n} SET updated_by = 't91-x' WHERE id = pg_temp.id('{n}')$q$, '42501', '{lab} d vai ứng dụng không có quyền UPDATE');")
        if n in APP_DELETE:
            o.append(f"SELECT pg_temp.is_true($q$WITH d AS (DELETE FROM {S}.{n} WHERE id = pg_temp.id('{n}') RETURNING 1) SELECT count(*) = 0 FROM d$q$, '{lab} e T91 xóa không được dòng nào');")
        else:
            o.append(f"SELECT pg_temp.expect($q$DELETE FROM {S}.{n} WHERE id = pg_temp.id('{n}')$q$, '42501', '{lab} e vai ứng dụng không có quyền DELETE');")
        o.append(f"SET app.tenant_id = '{own}';")
        o.append(f"SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM {S}.{n} WHERE id = pg_temp.id('{n}') AND updated_by = 'kiem-thu'$q$, '{lab} f {own} vẫn thấy đúng một dòng, không bị sửa');")
    o.append("SET app.tenant_id = 'T90';")
    o.append(f"SELECT pg_temp.expect(format('SELECT count(*) FROM {S}.dlq_message_%s', to_char(now(), 'YYYYMM')), '42501', '1.99 không đọc trực tiếp phân vùng, chỉ qua bảng cha có RLS');")
    return o, k


BEHAVIOR = r"""
-- ---------- 2. Quy tắc chốt ở CSDL ----------
SET app.tenant_id = 'T90';
-- 2.1 Tham số: kiểu, miền, trần nền tảng, mức PLATFORM, dòng COMMON
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '600'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.01 giá trị vượt trần nền tảng 500 bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '0'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.02 giá trị dưới miền 1 bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '"ba trăm"'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.03 sai kiểu bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '12.5'::jsonb WHERE id = pg_temp.id('param_value')$q$, '23514', '2.04 kiểu INTEGER không nhận số lẻ');
SELECT pg_temp.ok($q$UPDATE ph18_ops.param_value SET value = '450'::jsonb, current_version_no = 2 WHERE id = pg_temp.id('param_value')$q$, '2.05 giá trị trong miền và trần ghi được');
SELECT pg_temp.is_true($q$SELECT version = 1 FROM ph18_ops.param_value WHERE id = pg_temp.id('param_value')$q$, '2.06 version tăng khi sửa (ETag)');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.param.cache-seconds')::uuid, '18.param.cache-seconds', '30'::jsonb, 'TENANT', 'ta-an', 'ta-an')$q$, '23514', '2.07 tham số mức PLATFORM tenant không ghi');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.batch-max')::uuid, '18.dlq.replay.khac', '30'::jsonb, 'TENANT', 'ta-an', 'ta-an')$q$, '23514', '2.08 param_key phải khớp lược đồ');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.batch-max')::uuid, '18.dlq.replay.batch-max', '30'::jsonb, 'PLATFORM', 'ta-an', 'ta-an')$q$, '23514', '2.09 dòng tenant không mang scope PLATFORM');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_value (id, tenant_id, definition_id, param_key, value, scope, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.batch-max')::uuid, '18.dlq.replay.batch-max', '500'::jsonb, 'TENANT', 'ta-an', 'ta-an')$q$, '2.10 ghi đè 18.dlq.replay.batch-max cho T90');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, label, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 't90test', 't90test.khac', 'INTEGER', '1'::jsonb, 'x', 'a', 'a')$q$, '23514', '2.11 tenant không đăng ký lược đồ khóa (chỉ COMMON)');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_definition SET label = 'Sửa nhãn' WHERE param_key = '18.dlq.replay.batch-max'$q$, '42501', '2.12 phiên tenant không sửa lược đồ khóa COMMON') WHERE false;
SELECT pg_temp.is_true($q$WITH u AS (UPDATE ph18_ops.param_definition SET label = 'Sửa nhãn' WHERE param_key = '18.dlq.replay.batch-max' RETURNING 1) SELECT count(*) = 0 FROM u$q$, '2.12 phiên tenant không sửa được lược đồ khóa COMMON');
SELECT pg_temp.is_true($q$SELECT value = '450'::jsonb AND scope = 'TENANT' FROM ph18_ops.config_param WHERE key = 't90test.batch-max'$q$, '2.13 config_param (DD-14) trả giá trị ghi đè của T90');
SELECT pg_temp.is_true($q$SELECT value = '500'::jsonb FROM ph18_ops.config_param WHERE key = '18.dlq.replay.batch-max'$q$, '2.14 config_param trả ghi đè 18.dlq.replay.batch-max');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT value = '100'::jsonb AND scope = 'PLATFORM' FROM ph18_ops.config_param WHERE key = 't90test.batch-max'$q$, '2.15 T91 thấy mặc định, không thấy ghi đè của T90');
SELECT pg_temp.is_true($q$SELECT count(*) = 30 FROM ph18_ops.config_param WHERE namespace_code = '18'$q$, '2.16 T91 đọc đủ 30 khóa 18.* từ lược đồ COMMON');
SET app.tenant_id = 'COMMON';
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, min_value, max_value, label, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '18', '18.x.bad-default', 'INTEGER', '5000'::jsonb, 1, 100, 'x', 'a', 'a')$q$, '23514', '2.17 mặc định ngoài miền của chính lược đồ bị chặn');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, label, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '18', '17.lac.khoa', 'INTEGER', '1'::jsonb, 'x', 'a', 'a')$q$, '23514', '2.18 khóa phải mang tiền tố không gian tên');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_namespace (id, tenant_id, code, owner_module, title, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', '19', 'PH19', 'Thanh toán', 'a', 'a')$q$, '23514', '2.19 không gian tên 19 do PH-19 tự giữ');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_definition SET value_type = 'STRING' WHERE param_key = '18.dlq.replay.batch-max'$q$, '55000', '2.20 kiểu của khóa bất biến');
SET app.tenant_id = 'T90';
-- 2.2 Đề nghị đổi tham số ★: một đề nghị chờ, bốn mắt, máy trạng thái
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_change_request (id, tenant_id, definition_id, param_key, proposed_value, reason, requested_by, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('param_definition'), 't90test.batch-max', '250'::jsonb, 'Đề nghị thứ hai cùng khóa', 'to-an', now() + interval '1 day', 'to-an', 'to-an')$q$, '23505', '2.21 mỗi khóa một đề nghị chờ duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_change_request (id, tenant_id, definition_id, param_key, proposed_value, reason, requested_by, expires_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', md5('ph18-def:18.dlq.replay.approval-threshold')::uuid, '18.dlq.replay.approval-threshold', '20000'::jsonb, 'Giá trị đề xuất ngoài miền', 'to-an', now() + interval '1 day', 'to-an', 'to-an')$q$, '23514', '2.22 giá trị đề xuất cũng kiểm miền');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET status = 'APPROVED', decided_by = 'to-an', decided_at = now() WHERE id = pg_temp.id('param_change_request')$q$, '23514', '2.23 người đề nghị tự duyệt bị chặn');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET status = 'APPROVED' WHERE id = pg_temp.id('param_change_request')$q$, '23514', '2.24 duyệt cần người và thời điểm duyệt');
SELECT pg_temp.ok($q$UPDATE ph18_ops.param_change_request SET status = 'APPROVED', decided_by = 'ta-binh', decided_at = now() WHERE id = pg_temp.id('param_change_request')$q$, '2.25 người thứ hai duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('param_change_request')$q$, '55000', '2.26 đề nghị đã duyệt không quay lại chờ');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_change_request SET proposed_value = '1'::jsonb WHERE id = pg_temp.id('param_change_request')$q$, '55000', '2.27 giá trị đề xuất bất biến');
-- 2.3 Lịch sử phiên bản tham số
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value_version SET value = '1'::jsonb WHERE id = pg_temp.id('param_value_version')$q$, '55000', '2.28 nội dung phiên bản bất biến');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.param_value_version (id, tenant_id, definition_id, param_key, version_no, value, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('param_definition'), 't90test.batch-max', 2, '450'::jsonb, 'ACTIVE', 'a', 'a')$q$, '23505', '2.29 mỗi khóa một phiên bản ACTIVE');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value_version SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('param_value_version')$q$, '55000', '2.30 ACTIVE không quay lại PENDING_APPROVAL');
SELECT pg_temp.ok($q$UPDATE ph18_ops.param_value_version SET status = 'SUPERSEDED', superseded_at = now() WHERE id = pg_temp.id('param_value_version')$q$, '2.31 ACTIVE sang SUPERSEDED');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.param_value_version (id, tenant_id, definition_id, param_key, version_no, value, previous_value, status, change_request_id, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('param_definition'), 't90test.batch-max', 2, '450'::jsonb, '300'::jsonb, 'ACTIVE', pg_temp.id('param_change_request'), 'ta-binh', 'ta-binh')$q$, '2.32 phiên bản 2 ACTIVE gắn đề nghị đã duyệt');
-- 2.4 Cờ tính năng, egress
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.feature_flag (id, tenant_id, flag_key, module, owner, description, removal_date, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '07.rdm.feature.hybrid', 'PH07', 'a', 'b', current_date, 'a', 'a')$q$, '23514', '2.33 cờ tính năng phải dạng ff.{module}.{tính-năng}');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.egress_allowlist_entry (id, tenant_id, host, purpose_module, purpose, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', '10.20.30.40', 'PH15', 'IP trần', 'a', 'a')$q$, '23514', '2.34 egress không nhận địa chỉ IP trần');
SELECT pg_temp.expect($q$UPDATE ph18_ops.egress_allowlist_entry SET enabled = true, approved_by = 'kiem-thu', approved_at = now() WHERE id = pg_temp.id('egress_allowlist_entry')$q$, '23514', '2.35 người tạo không tự duyệt egress');
SELECT pg_temp.ok($q$UPDATE ph18_ops.egress_allowlist_entry SET enabled = true, approved_by = 'so-binh', approved_at = now() WHERE id = pg_temp.id('egress_allowlist_entry')$q$, '2.36 người thứ hai duyệt egress');
-- 2.5 DLQ: máy trạng thái, payload gốc, bỏ qua có lý do
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET status = 'RESOLVED', closed_at = now() WHERE id = pg_temp.id('dlq_message')$q$, '55000', '2.37 NEW không nhảy thẳng RESOLVED');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET payload_inline = '{"maHoSo": "SUA"}'::jsonb WHERE id = pg_temp.id('dlq_message')$q$, '55000', '2.38 payload gốc không sửa');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET dlq_key = 'khac' WHERE id = pg_temp.id('dlq_message')$q$, '55000', '2.39 dlqKey bất biến');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET status = 'TRIAGED', error_class = 'CONTRACT', priority = 'P2' WHERE id = pg_temp.id('dlq_message')$q$, '2.40 NEW sang TRIAGED');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_message SET status = 'DISCARDED', closed_at = now(), discard_reason = 'ngắn' WHERE id = pg_temp.id('dlq_message')$q$, '23514', '2.41 bỏ qua cần lý do ≥ 10 ký tự');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET status = 'DISCARDED', closed_at = now(), discard_reason = 'Bản tin thử nghiệm, không cần xử lý' WHERE id = pg_temp.id('dlq_message')$q$, '2.42 bỏ qua có lý do');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_message SET status = 'TRIAGED', closed_at = NULL WHERE id = pg_temp.id('dlq_message')$q$, '2.43 mở lại mục đã bỏ qua');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, status, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k2', 'PH04-RUNTIME', 'PH04', 'MISSING', 'PURGED', 'POISON', now(), 'a', 'a')$q$, '23514', '2.44 POISON phải ghi header ngữ cảnh thiếu');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, payload_inline, payload_size_bytes, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k3', 'PH04-RUNTIME', 'PH04', 'X', 'INLINE', '{}'::jsonb, 300000, now(), 'a', 'a')$q$, '23514', '2.45 payload inline quá 256 KB bị chặn');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k4', 'PH04-RUNTIME', 'PH04', 'X', 'INLINE', now(), 'a', 'a')$q$, '23514', '2.46 INLINE phải có payload');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, context_headers, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'k5', 'PH10-EVENT', 'PH10', 'X', 'FEDERATED', '{"authorization": "x"}'::jsonb, now(), 'a', 'a')$q$, '23514', '2.47 header ngữ cảnh không giữ authorization, FEDERATED cần external_ref');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_payload_ref (id, tenant_id, dlq_id, dlq_received_at, kind, bucket, object_key, size_bytes, sha256, content_type, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('dlq_message'), pg_temp.ts(), 'REVISION', 'dh-t91-ops', 'x', 1, repeat('b', 64), 'application/json', 'a', 'a')$q$, '23514', '2.48 payload lớn chỉ ở bucket dh-{tenant}-ops của chính tenant');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_assignment (id, tenant_id, dlq_id, dlq_received_at, assignee, assigned_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('dlq_message'), pg_temp.ts(), 'to-c', 'to-binh', 'a', 'a')$q$, '23505', '2.49 mỗi mục một lần gán đang hiệu lực');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_assignment (id, tenant_id, dlq_id, dlq_received_at, assignee, assigned_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', gen_random_uuid(), pg_temp.ts(), 'to-c', 'to-binh', 'a', 'a')$q$, '23503', '2.50 gán cho mục DLQ không tồn tại bị chặn');
-- 2.6 Bản sửa payload: bốn mắt với dữ liệu Hạn chế, nội dung đóng băng
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_revision SET contains_restricted = true, status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('dlq_revision')$q$, '2.51 bản sửa có dữ liệu Hạn chế gửi duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_revision SET diff = '[]'::jsonb WHERE id = pg_temp.id('dlq_revision')$q$, '55000', '2.52 bản sửa chờ duyệt không đổi nội dung');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_revision SET status = 'APPROVED' WHERE id = pg_temp.id('dlq_revision')$q$, '23514', '2.53 duyệt bản sửa Hạn chế cần người duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.dlq_revision SET status = 'APPROVED', approved_by = 'kiem-thu', approved_at = now() WHERE id = pg_temp.id('dlq_revision')$q$, '23514', '2.54 người soạn không tự duyệt bản sửa');
SELECT pg_temp.ok($q$UPDATE ph18_ops.dlq_revision SET status = 'APPROVED', approved_by = 'so-binh', approved_at = now() WHERE id = pg_temp.id('dlq_revision')$q$, '2.55 người thứ hai duyệt bản sửa');
-- 2.7 Phát lại: bốn mắt, lũy đẳng, máy trạng thái
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, mode, reason, total_items, approval_required, status, approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BATCH_LIST', 'Phát lại loạt lớn sau sự cố', 500, true, 'APPROVED', 'to-an', 'to-an', 'to-an')$q$, '23514', '2.56 người tạo loạt không tự duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, mode, reason, total_items, approval_required, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BATCH_LIST', 'Phát lại loạt lớn sau sự cố', 500, true, 'RUNNING', 'to-an', 'to-an')$q$, '23514', '2.57 loạt cần duyệt không chạy khi chưa duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_job (id, tenant_id, mode, reason, total_items, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BATCH_FILTER', 'Phát lại theo bộ lọc', 10, 'to-an', 'to-an')$q$, '23514', '2.58 loạt theo bộ lọc phải có bộ lọc');
SELECT pg_temp.expect($q$UPDATE ph18_ops.replay_job SET status = 'RUNNING' WHERE id = pg_temp.id('replay_job')$q$, '55000', '2.59 DRAFT không chạy thẳng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'APPROVED' WHERE id = pg_temp.id('replay_job')$q$, '2.60 lượt đơn dưới ngưỡng tự duyệt');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'RUNNING', started_at = now() WHERE id = pg_temp.id('replay_job')$q$, '2.61 APPROVED sang RUNNING');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'PAUSED', paused_at = now() WHERE id = pg_temp.id('replay_job')$q$, '2.62 tạm dừng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_job SET status = 'RUNNING' WHERE id = pg_temp.id('replay_job')$q$, '2.63 chạy tiếp');
SELECT pg_temp.expect($q$UPDATE ph18_ops.replay_job SET succeeded = 2 WHERE id = pg_temp.id('replay_job')$q$, '23514', '2.64 bộ đếm không vượt tổng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.replay_item (id, tenant_id, job_id, dlq_id, dlq_received_at, revision_no, idempotency_key, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('replay_job'), pg_temp.id('dlq_message'), pg_temp.ts(), 1, 'sai-khoa', 'a', 'a')$q$, '23514', '2.65 khóa lũy đẳng phải là dlqId:revision');
SELECT pg_temp.expect($q$UPDATE ph18_ops.replay_item SET status = 'SUCCEEDED' WHERE id = pg_temp.id('replay_item')$q$, '55000', '2.66 mục phát lại PENDING không nhảy SUCCEEDED');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_item SET status = 'SENT', dispatched_at = now() WHERE id = pg_temp.id('replay_item')$q$, '2.67 mục phát lại đã gửi');
SELECT pg_temp.ok($q$UPDATE ph18_ops.replay_item SET status = 'SUCCEEDED', result_at = now() WHERE id = pg_temp.id('replay_item')$q$, '2.68 nguồn báo thành công');
-- 2.8 Thông báo
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, caller_module, message_key, template_code, recipient_ref, category, channels, params, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH01', 'msg-x', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-1"}]'::jsonb, 'INFO', '{EMAIL}', '{"cccd": "001"}'::jsonb, 'a', 'a')$q$, '23514', '2.69 biến mẫu không chứa số định danh (FR-00-062)');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, caller_module, message_key, template_code, recipient_ref, category, channels, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH01', 'msg-0001', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-1"}]'::jsonb, 'INFO', '{EMAIL}', 'a', 'a')$q$, '23505', '2.70 khóa lũy đẳng của bên gọi không nhân bản thông báo');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_message (id, tenant_id, caller_module, message_key, template_code, recipient_ref, category, channels, link, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'PH01', 'msg-y', 'ph01.review-decided', '[{"kind": "USER", "ref": "u-1"}]'::jsonb, 'INFO', '{EMAIL}', 'https://ngoai.example/x', 'a', 'a')$q$, '23514', '2.71 liên kết chỉ là đường dẫn nội bộ');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_template_version (id, tenant_id, template_id, version_no, body_text, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('notification_template'), 2, '{{#ds}}{{ten}}{{/ds}}', 'a', 'a')$q$, '23514', '2.72 mẫu Mustache không logic');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_template_version SET status = 'IN_REVIEW', submitted_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '2.73 gửi duyệt mẫu');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_template_version SET body_text = 'Sửa sau khi gửi duyệt' WHERE id = pg_temp.id('notification_template_version')$q$, '55000', '2.74 mẫu đang duyệt không đổi nội dung');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_template_version SET status = 'ACTIVE', reviewed_by = 'so-binh', reviewed_at = now(), activated_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '23514', '2.75 kích hoạt cần kiểm tra cấm trường đạt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_template_version SET status = 'ACTIVE', field_check_passed = true, reviewed_by = 'kiem-thu', reviewed_at = now(), activated_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '23514', '2.76 người soạn không tự duyệt mẫu');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_template_version SET status = 'ACTIVE', field_check_passed = true, reviewed_by = 'so-binh', reviewed_at = now(), activated_at = now() WHERE id = pg_temp.id('notification_template_version')$q$, '2.77 người thứ hai kích hoạt mẫu');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_delivery SET status = 'DELIVERED' WHERE id = pg_temp.id('notification_delivery')$q$, '55000', '2.78 QUEUED không nhảy DELIVERED');
SELECT pg_temp.expect($q$UPDATE ph18_ops.notification_delivery SET status = 'SUPPRESSED' WHERE id = pg_temp.id('notification_delivery')$q$, '23514', '2.79 SUPPRESSED phải có lý do');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_delivery SET status = 'SENT', sent_at = now(), rendered_title = 'Kết quả thẩm định' WHERE id = pg_temp.id('notification_delivery')$q$, '2.80 lần gửi SENT');
SELECT pg_temp.ok($q$UPDATE ph18_ops.notification_delivery SET read_at = now() WHERE id = pg_temp.id('notification_delivery')$q$, '2.81 người dùng đọc thông báo trong ứng dụng');
SELECT pg_temp.is_true($q$SELECT title = 'Kết quả thẩm định' AND read_at IS NOT NULL AND channels_sent = '["IN_APP"]'::jsonb FROM ph18_ops.notification WHERE id = pg_temp.id('notification_delivery')$q$, '2.82 khung nhìn notification (DD-13) đúng trường');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.suppression_entry (id, tenant_id, channel, address_hash, address_masked, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'EMAIL', repeat('d', 64), 'a***', 'COMPLAINT', 'a', 'a')$q$, '23505', '2.83 mỗi địa chỉ một dòng chặn đang hiệu lực');
-- 2.9 Việc, lịch, cửa sổ đóng băng
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_item (id, tenant_id, type_id, type_code, task_key, title, subject_ref, assignee_kind, assignee_ref, required_permission, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('task_type'), 'ph01.approve-onboarding', 'HS-0001', 'Trùng', 'HS-0001', 'ROLE', 'TA', 'PERM-01-approve', 'a', 'a')$q$, '23505', '2.84 tạo việc lũy đẳng theo task_key');
SELECT pg_temp.ok($q$UPDATE ph18_ops.task_item SET four_eyes = false, status = 'IN_PROGRESS', claimed_by = 'ta-an', started_at = now() WHERE id = pg_temp.id('task_item')$q$, '2.85 nhận việc');
SELECT pg_temp.expect($q$UPDATE ph18_ops.task_item SET status = 'DONE' WHERE id = pg_temp.id('task_item')$q$, '23514', '2.86 việc đóng phải có thời điểm đóng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.task_item SET status = 'DONE', closed_at = now(), closed_by = 'ta-an', outcome = 'APPROVED' WHERE id = pg_temp.id('task_item')$q$, '2.87 đóng việc');
SELECT pg_temp.expect($q$UPDATE ph18_ops.task_item SET status = 'OPEN', closed_at = NULL WHERE id = pg_temp.id('task_item')$q$, '55000', '2.88 việc DONE không mở lại');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.task_item (id, tenant_id, type_id, type_code, task_key, title, subject_ref, assignee_kind, assignee_ref, required_permission, requested_by, four_eyes, status, closed_at, closed_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('task_type'), 'ph01.approve-onboarding', 'HS-0002', 'Bốn mắt', 'HS-0002', 'ROLE', 'TA', 'PERM-01-approve', 'ta-an', true, 'DONE', now(), 'ta-an', 'a', 'a')$q$, '23514', '2.89 việc bốn mắt không do người đề nghị đóng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.maintenance_window (id, tenant_id, window_code, kind, starts_at, ends_at, reason, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'W2', 'FREEZE', now(), now() - interval '1 hour', 'Cửa sổ ngược thời gian', 'a', 'a')$q$, '23514', '2.90 cửa sổ kết thúc sau khi bắt đầu');
SELECT pg_temp.expect($q$UPDATE ph18_ops.maintenance_window SET status = 'ACTIVE' WHERE id = pg_temp.id('maintenance_window')$q$, '23514', '2.91 cửa sổ hiệu lực cần duyệt');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.work_calendar (id, tenant_id, calendar_code, name, working_days, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'SAI', 'Sai ngày', '{0,8}', 'a', 'a')$q$, '23514', '2.92 ngày làm việc chỉ 1 đến 7');
-- 2.10 Sự cố
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now() WHERE id = pg_temp.id('incident')$q$, '55000', '2.93 OPEN không đóng thẳng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.incident SET status = 'INVESTIGATING', acknowledged_at = now(), involves_personal_data = true WHERE id = pg_temp.id('incident')$q$, '2.94 điều tra sự cố');
SELECT pg_temp.ok($q$UPDATE ph18_ops.incident SET status = 'RESOLVED', resolved_at = now() WHERE id = pg_temp.id('incident')$q$, '2.95 đã khắc phục');
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now() WHERE id = pg_temp.id('incident')$q$, '23514', '2.96 đóng cần nguyên nhân gốc và bài học');
SELECT pg_temp.expect($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now(), root_cause = 'Nguồn đổi lược đồ không báo trước', lessons_learned = 'Bắt buộc thông báo thay đổi lược đồ' WHERE id = pg_temp.id('incident')$q$, '23514', '2.97 sự cố có DLCN chưa chuyển PH-09 thì không đóng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.incident SET status = 'CLOSED', closed_at = now(), root_cause = 'Nguồn đổi lược đồ không báo trước', lessons_learned = 'Bắt buộc thông báo thay đổi lược đồ', ph09_breach_ref = 'BR-2026-0001', ph09_reported_at = now() WHERE id = pg_temp.id('incident')$q$, '2.98 đóng sự cố đủ điều kiện');
-- 2.11 Khôi phục tenant, xuất, sáp nhập
SELECT pg_temp.expect($q$UPDATE ph18_ops.tenant_restore_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('tenant_restore_request') AND false$q$, '00000', '2.99 bỏ qua') WHERE false;
SELECT pg_temp.ok($q$UPDATE ph18_ops.tenant_restore_request SET status = 'PENDING_APPROVAL' WHERE id = pg_temp.id('tenant_restore_request')$q$, '2.100 gửi duyệt khôi phục');
SELECT pg_temp.expect($q$UPDATE ph18_ops.tenant_restore_request SET status = 'APPROVED', approved_by = 'ta-an', approved_at = now() WHERE id = pg_temp.id('tenant_restore_request')$q$, '23514', '2.101 người yêu cầu không tự duyệt khôi phục');
SELECT pg_temp.ok($q$UPDATE ph18_ops.tenant_restore_request SET status = 'APPROVED', approved_by = 'pa-binh', approved_at = now() WHERE id = pg_temp.id('tenant_restore_request')$q$, '2.102 PA duyệt khôi phục');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_request (id, tenant_id, request_no, restore_point, scope, reason, requested_by, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RST-T90-0002', now() - interval '2 days', 'FULL_TENANT', 'Yêu cầu thứ hai khi yêu cầu một chưa xong', 'ta-an', 'PENDING_APPROVAL', 'a', 'a')$q$, '23505', '2.103 mỗi tenant một yêu cầu khôi phục đang hoạt động');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_request (id, tenant_id, request_no, restore_point, scope, schemas, reason, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'RST-T90-0003', now() - interval '2 days', 'SCHEMAS', '{ph13_audit}', 'Khôi phục kiểm toán về quá khứ là không được', 'ta-an', 'a', 'a')$q$, '23514', '2.104 không khôi phục schema kiểm toán ph13');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.tenant_restore_step (id, tenant_id, request_id, step_no, step_code, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('tenant_restore_request'), 5, 'APPROVAL', 'a', 'a')$q$, '23514', '2.105 số bước khớp mã bước');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-X', 'PH07', 'T91', 'T92', 'x', 'a', 'a')$q$, '23514', '2.106 dòng sáp nhập thuộc tenant đích');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-X', 'PH07', 'T90', 'T90', 'x', 'a', 'a')$q$, '23514', '2.107 tenant nguồn khác tenant đích');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, dry_run, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-2026-0001', 'PH07', 'T91', 'T90', 'mp/ph07', false, 'a', 'a')$q$, '2.108 lần chạy thật thứ nhất');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.merge_transfer (id, tenant_id, merge_plan_id, module, source_tenant, target_tenant, mapping_ref, dry_run, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'MP-2026-0001', 'PH07', 'T91', 'T90', 'mp/ph07', false, 'a', 'a')$q$, '23505', '2.109 mỗi kế hoạch, phân hệ một lần chạy thật');
SELECT pg_temp.expect($q$UPDATE ph18_ops.merge_transfer SET dry_run = false WHERE id = pg_temp.id('merge_transfer')$q$, '55000', '2.110 cờ chạy thử bất biến');
-- 2.12 Di trú, chạy song song, cắt chuyển
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.legacy_source (id, tenant_id, source_code, name, system_kind, jdbc_url, credential_ref, owner, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BUS-CU', 'Bus', 'BUS', 'jdbc:postgresql://bus:5432/bus?user=sa', 'kv/dh/t90/migration/bus', 'a', 'a', 'a')$q$, '23514', '2.111 URL JDBC không kèm thông tin đăng nhập');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.legacy_source (id, tenant_id, source_code, name, system_kind, jdbc_url, credential_ref, owner, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'BUS-CU', 'Bus', 'BUS', 'jdbc:postgresql://bus:5432/bus', 'kv/dh/t91/migration/bus', 'a', 'a', 'a')$q$, '23514', '2.112 tham chiếu OpenBao chỉ trong nhánh của tenant');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_plan_item (id, tenant_id, plan_id, seq_no, object_kind, target_module, converter_code, source_query_ref, target_api, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('migration_plan'), 2, 'CATALOG', 'PH01', 'c', 'q', 'API-01-080', 'a', 'a')$q$, '23514', '2.113 danh mục chỉ di trú sang PH-07');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_run (id, tenant_id, plan_id, run_no, run_mode, status, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('migration_plan'), 2, 'REAL', 'QUEUED', 'ie-an', 'a', 'a')$q$, '23514', '2.114 chạy thật cần duyệt trước khi xếp hàng');
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.migration_run (id, tenant_id, plan_id, run_no, run_mode, status, requested_by, created_by, updated_by) VALUES (md5('run-real')::uuid, 'T90', pg_temp.id('migration_plan'), 2, 'REAL', 'PENDING_APPROVAL', 'ie-an', 'a', 'a')$q$, '2.115 tạo lần chạy thật chờ duyệt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_run SET status = 'QUEUED', approved_by = 'ie-an', approved_at = now() WHERE id = md5('run-real')::uuid$q$, '23514', '2.116 người yêu cầu không tự duyệt chạy thật');
SELECT pg_temp.ok($q$UPDATE ph18_ops.migration_run SET status = 'QUEUED', approved_by = 'ta-binh', approved_at = now() WHERE id = md5('run-real')::uuid$q$, '2.117 người thứ hai duyệt chạy thật');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_run SET status = 'SUCCEEDED' WHERE id = md5('run-real')::uuid$q$, '55000', '2.118 QUEUED không nhảy SUCCEEDED');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.migration_reconciliation (id, tenant_id, run_id, plan_item_id, object_kind, source_count, target_count, source_checksum, target_checksum, matched, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('migration_run'), pg_temp.id('migration_plan_item'), 'API', 10, 9, repeat('e', 64), repeat('e', 64), true, 'a', 'a')$q$, '23514', '2.119 không ghi khớp khi số lượng lệch');
SELECT pg_temp.expect($q$UPDATE ph18_ops.parallel_run_group SET status = 'SHADOW_OK', match_rate = 98 WHERE id = pg_temp.id('parallel_run_group')$q$, '23514', '2.120 bóng đạt cần tỷ lệ khớp ≥ ngưỡng');
SELECT pg_temp.expect($q$UPDATE ph18_ops.parallel_run_group SET status = 'CUT_OVER', cutover_at = now(), rollback_deadline_at = now() + interval '15 minutes' WHERE id = pg_temp.id('parallel_run_group')$q$, '55000', '2.121 PARALLEL không cắt chuyển thẳng');
SELECT pg_temp.ok($q$UPDATE ph18_ops.parallel_run_group SET status = 'SHADOW_OK', match_rate = 99.8 WHERE id = pg_temp.id('parallel_run_group')$q$, '2.122 bóng đạt');
SELECT pg_temp.expect($q$UPDATE ph18_ops.parallel_run_group SET status = 'CUT_OVER' WHERE id = pg_temp.id('parallel_run_group')$q$, '23514', '2.123 cắt chuyển cần mốc và hạn quay lui');
SELECT pg_temp.ok($q$UPDATE ph18_ops.parallel_run_group SET status = 'CUT_OVER', cutover_at = now(), rollback_deadline_at = now() + interval '15 minutes' WHERE id = pg_temp.id('parallel_run_group')$q$, '2.124 cắt chuyển');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.cutover_log (id, tenant_id, group_id, action, actor, approved_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('parallel_run_group'), 'CUTOVER', 'po-an', 'po-an', 'a', 'a')$q$, '23514', '2.125 sổ cắt chuyển cần người duyệt khác người thực hiện');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.shadow_comparison_sample (id, tenant_id, group_id, route, request_fingerprint, matched, diff_kind, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', pg_temp.id('parallel_run_group'), '/x', repeat('f', 64), true, 'BODY', 'a', 'a')$q$, '23514', '2.126 mẫu lệch thân không ghi là khớp');
SELECT pg_temp.expect($q$UPDATE ph18_ops.credential_reissue_marker SET status = 'WAIVED' WHERE id = pg_temp.id('credential_reissue_marker')$q$, '23514', '2.127 miễn cấp lại cần lý do');
-- 2.13 Outbox
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.outbox_event (id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 't91.ops.param.changed.v1', 'a', 'a', 'a', '{}'::jsonb, 'a', 'a')$q$, '23514', '2.128 topic outbox mang tiền tố tenant của dòng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.outbox_event (id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'x', 't90.ops.dlq.received.v1', 'a', 'a', 'a', '{"payload": {}}'::jsonb, 'a', 'a')$q$, '23514', '2.129 sự kiện không mang payload DLQ');
-- 2.14 Dòng COMMON: tenant không ghi; phiên COMMON ghi được
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.notification_template (id, tenant_id, template_code, owner_module, title, category, channels, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'ph02.x', 'PH02', 'x', 'INFO', '{EMAIL}', 'a', 'a')$q$, '42501', '2.130 phiên tenant không ghi mẫu COMMON');
SET app.tenant_id = 'COMMON';
SELECT pg_temp.ok($q$INSERT INTO ph18_ops.notification_template (id, tenant_id, template_code, owner_module, title, category, channels, created_by, updated_by) VALUES (md5('tpl-common')::uuid, 'COMMON', 'ph02.change-notice', 'PH02', 'Thông báo thay đổi API', 'INFO', '{EMAIL}', 'pa-an', 'pa-an')$q$, '2.131 phiên COMMON (PA) ghi mẫu nền tảng');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.dlq_message (id, tenant_id, dlq_key, source_code, source_module, reason_code, payload_location, received_at, created_by, updated_by) VALUES (gen_random_uuid(), 'COMMON', 'k', 'PH04-RUNTIME', 'PH04', 'X', 'PURGED', now(), 'a', 'a')$q$, '23514', '2.132 bảng theo tenant không nhận dòng COMMON');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.notification_template WHERE template_code = 'ph02.change-notice'$q$, '2.133 T91 đọc được mẫu COMMON');
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.backup_object$q$, '2.134 T91 không thấy đối tượng sao lưu cụm (COMMON không dùng chung ở bảng sao lưu)');
-- 2.15 Khởi tạo tenant
SELECT pg_temp.ok($q$CALL ph18_ops.p_seed_tenant('T91')$q$, '2.135 khởi tạo tenant T91');
SELECT pg_temp.ok($q$CALL ph18_ops.p_seed_tenant('T91')$q$, '2.136 chạy lại không lỗi');
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph18_ops.work_calendar$q$, '2.137 T91 thấy lịch của mình và lịch quốc gia, không nhân bản');
RESET ROLE;

-- ---------- 3. Bảng chỉ thêm: chủ đối tượng cũng không sửa, xóa ----------
SET ROLE ph18_owner;
SET app.tenant_id = 'T90';
@@APPEND@@
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.param_value_version WHERE id = pg_temp.id('param_value_version')$q$, '55000', '3.90 lịch sử tham số không xóa');
RESET ROLE;

-- ---------- 4. Vai readonly và worker ----------
SET ROLE dh_ops_ro;
SET app.tenant_id = 'T90';
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message')$q$, '4.01 readonly đọc siêu dữ liệu DLQ của tenant');
SELECT pg_temp.expect($q$SELECT payload_inline FROM ph18_ops.dlq_message$q$, '42501', '4.02 readonly không đọc payload DLQ');
SELECT pg_temp.expect($q$SELECT payload FROM ph18_ops.dlq_revision$q$, '42501', '4.03 readonly không đọc payload bản sửa');
SELECT pg_temp.expect($q$SELECT params FROM ph18_ops.notification_message$q$, '42501', '4.04 readonly không đọc biến mẫu thông báo');
SELECT pg_temp.expect($q$INSERT INTO ph18_ops.ops_report (id, tenant_id, report_kind, period_kind, period_from, period_to, created_by, updated_by) VALUES (gen_random_uuid(), 'T90', 'DLQ', 'DAY', current_date, current_date, 'a', 'a')$q$, '42501', '4.05 readonly không ghi');
SELECT pg_temp.is_true($q$SELECT count(*) >= 1 FROM ph18_ops.config_param$q$, '4.06 readonly đọc config_param');
RESET ROLE;
SET ROLE dh_ops_worker;
SET app.tenant_id = 'T90';
SELECT pg_temp.expect($q$SELECT count(*) FROM ph18_ops.dlq_message$q$, '42501', '4.07 worker không đọc DLQ');
SELECT pg_temp.expect($q$SELECT count(*) FROM ph18_ops.notification_message$q$, '42501', '4.08 worker không đọc thông báo');
SELECT pg_temp.expect($q$UPDATE ph18_ops.param_value SET value = '1'::jsonb$q$, '42501', '4.09 worker không ghi tham số');
SELECT pg_temp.is_true($q$SELECT count(*) = 2 FROM ph18_ops.migration_run$q$, '4.10 worker đọc lần chạy di trú của tenant');
SELECT pg_temp.ok($q$UPDATE ph18_ops.migration_run SET status = 'RUNNING', started_at = now() WHERE id = md5('run-real')::uuid$q$, '4.11 worker cập nhật trạng thái lần chạy');
SELECT pg_temp.ok($q$UPDATE ph18_ops.merge_transfer SET status = 'RUNNING', progress_percent = 40, rows_total = 100, rows_copied = 40 WHERE id = pg_temp.id('merge_transfer')$q$, '4.12 worker báo tiến độ sáp nhập');
SELECT pg_temp.ok($q$UPDATE ph18_ops.tenant_restore_step SET status = 'RUNNING', started_at = now() WHERE id = pg_temp.id('tenant_restore_step')$q$, '4.13 worker cập nhật bước khôi phục');
SELECT pg_temp.expect($q$UPDATE ph18_ops.migration_reconciliation SET matched = false$q$, '42501', '4.14 worker không sửa báo cáo đối chiếu (chỉ thêm)');
SELECT pg_temp.expect($q$DELETE FROM ph18_ops.migration_run$q$, '42501', '4.15 worker không xóa');
SET app.tenant_id = 'T91';
SELECT pg_temp.is_true($q$SELECT count(*) = 0 FROM ph18_ops.migration_run$q$, '4.16 worker ở phiên T91 không thấy lần chạy của T90');
RESET ROLE;

-- ---------- 5. Lưu giữ: dọn mục DLQ hết hạn lan truyền bản sửa, tham chiếu, gán, mục phát lại ----------
SET ROLE dh_ops_app;
SET app.tenant_id = 'T90';
SELECT pg_temp.ok($q$DELETE FROM ph18_ops.dlq_message WHERE id = pg_temp.id('dlq_message')$q$, '5.01 tác vụ lưu giữ xóa mục DLQ');
SELECT pg_temp.is_true($q$SELECT (SELECT count(*) FROM ph18_ops.dlq_revision) + (SELECT count(*) FROM ph18_ops.dlq_payload_ref) + (SELECT count(*) FROM ph18_ops.dlq_assignment) + (SELECT count(*) FROM ph18_ops.replay_item) = 0$q$, '5.02 bản sửa, tham chiếu payload, gán, mục phát lại bị xóa theo');
SELECT pg_temp.is_true($q$SELECT count(*) = 1 FROM ph18_ops.dlq_audit$q$, '5.03 nhật ký thao tác DLQ vẫn giữ (tham chiếu logic)');
RESET ROLE;
"""


def main():
    ids = "INSERT INTO ids VALUES " + ", ".join("('%s', gen_random_uuid())" % t["name"] for t in ALL) + ";"
    o = [HEAD.replace("@@IDS@@", ids)]
    o += catalog_checks()
    iso, n = isolation()
    o += iso
    ap = []
    for i, t in enumerate([t for t in ALL if t["append_only"]], 1):
        ap.append(f"SELECT pg_temp.expect($q$UPDATE {S}.{t['name']} SET updated_by = 'x' WHERE id = pg_temp.id('{t['name']}')$q$, '55000', '3.{i:02d} {t['name']} chỉ thêm: chặn UPDATE');")
        ap.append(f"SELECT pg_temp.expect($q$DELETE FROM {S}.{t['name']} WHERE id = pg_temp.id('{t['name']}')$q$, '55000', '3.{i:02d} {t['name']} chỉ thêm: chặn DELETE');")
    beh = BEHAVIOR.replace("@@APPEND@@", "\n".join(ap))
    # bỏ hai dòng giữ chỗ (WHERE false)
    beh = "\n".join(l for l in beh.split("\n") if not l.endswith("WHERE false;"))
    o.append(beh)
    o.append("SELECT 'PH18 ISOLATION TEST: ALL PASS' AS ket_qua;")
    sql = "\n".join(o)
    open(os.path.join(ROOT, "test", "ph18_isolation_test.sql"), "w", encoding="utf-8").write(sql + "\n")
    print(f"{n} bảng kiểm cô lập, {sql.count('pg_temp.expect(') + sql.count('pg_temp.is_true(') + sql.count('pg_temp.ok(') - 3} khối kiểm → test/ph18_isolation_test.sql")


if __name__ == "__main__":
    main()
