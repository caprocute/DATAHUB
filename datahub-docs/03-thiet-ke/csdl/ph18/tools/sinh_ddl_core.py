#!/usr/bin/env python3
"""Khung sinh DDL ph18_ops (D03-03-PH18): khai báo bảng, hiển thị CREATE TABLE, RLS, trigger.
Chép khung từ csdl/ph17/tools/sinh_ddl_core.py, chỉnh cho PH-18: bốn vai (owner, app, readonly, worker), bảng dùng chung
đọc thêm dòng COMMON, bảng chỉ dòng COMMON (lược đồ khóa tham số), bảng chỉ thêm, phân vùng tháng, dữ liệu mẫu cho bài kiểm
cô lập. Không chạy trực tiếp; sinh_ddl.py và sinh_test.py gọi tệp này."""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = "ph18_ops"
TENANT_RE = "^T[0-9]{2}$"
TENANT_COMMON_RE = "^(T[0-9]{2}|COMMON)$"


def X(*vals):
    """Danh sách giá trị CHECK. Trạng thái lấy đúng BRIEF-PH18 §4; giá trị ngoài §4 ghi ở D03-03-PH18 mục 10."""
    return "(" + ", ".join("'%s'" % x for x in vals) + ")"


# Trạng thái chuẩn (BRIEF-PH18 §4)
ST_DLQ = ("NEW", "TRIAGED", "REPLAY_PENDING", "REPLAYING", "RESOLVED", "REPLAY_FAILED", "DISCARDED", "POISON", "EXPIRED")
ST_REPLAY = ("DRAFT", "PENDING_APPROVAL", "APPROVED", "RUNNING", "PAUSED", "COMPLETED", "PARTIAL", "FAILED", "CANCELLED", "REJECTED")
ST_PARAM_VER = ("PENDING_APPROVAL", "ACTIVE", "SUPERSEDED", "REJECTED")
ST_TEMPLATE = ("DRAFT", "IN_REVIEW", "ACTIVE", "RETIRED")
ST_NOTIFY = ("QUEUED", "SENT", "DELIVERED", "BOUNCED", "FAILED", "SUPPRESSED")
ST_TASK = ("OPEN", "IN_PROGRESS", "DONE", "CANCELLED", "EXPIRED")
ST_INCIDENT = ("OPEN", "INVESTIGATING", "MITIGATED", "RESOLVED", "CLOSED")
ST_RESTORE = ("DRAFT", "PENDING_APPROVAL", "APPROVED", "RUNNING", "SUCCEEDED", "FAILED", "ROLLED_BACK", "REJECTED", "CANCELLED")
ST_PLAN = ("DRAFT", "READY")
ST_RUN = ("PENDING_APPROVAL", "QUEUED", "RUNNING", "SUCCEEDED", "SUCCEEDED_WITH_ERRORS", "FAILED", "CANCELLED")
ST_JOB = ("QUEUED", "RUNNING", "SUCCEEDED", "SUCCEEDED_WITH_ERRORS", "FAILED", "CANCELLED")
ST_CUTOVER = ("PARALLEL", "SHADOW_OK", "PARTIAL_CUTOVER", "CUT_OVER", "ROLLED_BACK")
ERROR_CLASS = ("TRANSIENT", "BUSINESS", "CONTRACT", "POISON", "UNKNOWN")
MODULE_RE = "^PH-[0-9]{2}$"


def T(name, en, comment, cols, cons=(), idx=(), part=None, tid=True, trig=(), ccomment=None, rls="tenant", common_ok=False,
      only_common=False, append_only=False, app_delete=False, worker=None, sample=None, pk=None, ro_hide=()):
    """rls: 'tenant' (đọc, ghi dòng của tenant phiên) hoặc 'common' (đọc thêm dòng COMMON).
    common_ok: CHECK tenant nhận COMMON (dòng mức nền tảng). only_common: chỉ dòng COMMON (lược đồ khóa).
    part: (cột phân vùng, số tháng tạo trước). worker: quyền vai ph18_worker ('r' đọc, 'rw' đọc ghi, 'i' chỉ thêm).
    sample: giá trị mẫu cho bài kiểm cô lập (cột -> biểu thức SQL). ro_hide: cột vai readonly không đọc được."""
    return dict(name=name, en=en, comment=comment, cols=cols, cons=list(cons), idx=list(idx), part=part, tid=tid, trig=list(trig),
                cc=ccomment or {}, rls=rls, common_ok=common_ok or only_common or rls == "common", only_common=only_common,
                append_only=append_only, app_delete=app_delete, worker=worker, sample=sample or {}, pk=pk, ro_hide=list(ro_hide))


def chk(table, what, expr):
    return (f"ck_{table}_{what}", f"CHECK ({expr})")


def fk(table, col, target, tcol="id", cascade=False, name=None):
    """Khóa ngoại kèm tenant_id: dòng con và dòng cha cùng tenant."""
    nm = name or f"fk_{table}_{col.replace('_id', '').replace(', ', '_')}"
    return (nm, f"FOREIGN KEY (tenant_id, {col}) REFERENCES {S}.{target} (tenant_id, {tcol})" + (" ON DELETE CASCADE" if cascade else ""))


def fk1(table, col, target, cascade=False):
    """Khóa ngoại một cột tới bảng dùng chung (dòng cha có thể là COMMON)."""
    return (f"fk_{table}_{col.replace('_id', '')}", f"FOREIGN KEY ({col}) REFERENCES {S}.{target} (id)" + (" ON DELETE CASCADE" if cascade else ""))


def four_eyes(table, who, by="created_by", what="four_eyes"):
    return chk(table, what, f"{who} IS NULL OR {who} <> {by}")


def reason(col, n=10, nullable=False):
    return f"{col} IS NULL OR coalesce(char_length(btrim({col})), 0) >= {n}" if nullable else f"coalesce(char_length(btrim({col})), 0) >= {n}"


def trans(col, pairs):
    return ("transition", [col, ",".join(pairs)])


STD_COLS = ["id uuid NOT NULL", "tenant_id varchar(16) NOT NULL"]
AUDIT_COLS = ["created_at timestamptz NOT NULL DEFAULT now()", "created_by varchar(64) NOT NULL", "updated_at timestamptz NOT NULL DEFAULT now()",
              "updated_by varchar(64) NOT NULL", "version integer NOT NULL DEFAULT 0"]


def all_cols(t):
    return STD_COLS + t["cols"] + AUDIT_COLS


def render_table(t, seq):
    n = t["name"]
    cols = all_cols(t)
    cons = []
    if t["part"]:
        cons.append((f"pk_{n}", f"PRIMARY KEY (id, {t['part'][0]})"))
        cons.append((f"uq_{n}_tid", f"UNIQUE (tenant_id, id, {t['part'][0]})"))
    else:
        cons.append((f"pk_{n}", "PRIMARY KEY (id)"))
        if t["tid"]:
            cons.append((f"uq_{n}_tid", "UNIQUE (tenant_id, id)"))
    if t["only_common"]:
        cons.append((f"ck_{n}_tenant", "CHECK (tenant_id = 'COMMON')"))
    else:
        cons.append((f"ck_{n}_tenant", f"CHECK (tenant_id ~ '{TENANT_COMMON_RE if t['common_ok'] else TENANT_RE}')"))
    cons += t["cons"]
    w = max(len(c.split()[0]) for c in cols)
    lines = [f"  {c.split()[0]:<{w}} {c[len(c.split()[0]) + 1:]}" for c in cols]
    for cn, cd in cons:
        lines.append(f"  CONSTRAINT {cn} {cd}")
    o = [f"-- @changeset ph18-{seq:04d}-{n.replace('_', '-')} splitStatements:false", f"CREATE TABLE {S}.{n} (", ",\n".join(lines),
         ")" + (f" PARTITION BY RANGE ({t['part'][0]})" if t["part"] else "") + ";"]
    if t["part"]:
        o.append(f"CALL {S}.p_ensure_partitions('{S}.{n}', (current_date - interval '1 month')::date, {t['part'][1]});")
    o += [i.replace("@", f"{S}.") for i in t["idx"]]
    o.append(f"CREATE TRIGGER tg_{n}_touch BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_touch();")
    if t["append_only"]:
        o.append(f"CREATE TRIGGER tg_{n}_append_only BEFORE UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_append_only();")
    for kind, args in t["trig"]:
        a = ", ".join("'%s'" % x.replace("'", "''") for x in args)
        if kind == "immutable":
            o.append(f"CREATE TRIGGER tg_{n}_immutable BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_immutable({a});")
        elif kind == "frozen":
            o.append(f"CREATE TRIGGER tg_{n}_frozen BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_frozen({a});")
        elif kind == "no_delete":
            o.append(f"CREATE TRIGGER tg_{n}_no_delete BEFORE DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_no_delete();")
        elif kind == "transition":
            o.append(f"CREATE TRIGGER tg_{n}_fsm_{args[0]} BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_transition({a});")
        elif kind == "raw":
            o.append(args[0].replace("@", f"{S}."))
    o.append(f"CALL {S}.p_enable_rls('{S}.{n}', {'true' if t['rls'] == 'common' else 'false'});")
    q = lambda s: s.replace("'", "''")
    o.append(f"COMMENT ON TABLE {S}.{n} IS '{q(t['en'] + ' ' + t['comment'])}';")
    for c, txt in t["cc"].items():
        o.append(f"COMMENT ON COLUMN {S}.{n}.{c} IS '{q(txt)}';")
    o.append(f"-- @rollback DROP TABLE IF EXISTS {S}.{n} CASCADE;")
    return "\n".join(o)


def parse_cols(t):
    """[(tên, kiểu, not null, có mặc định)] của mọi cột."""
    out = []
    for c in all_cols(t):
        p = c.split()
        name = p[0]
        rest = c[len(name) + 1:]
        typ = re.split(r" (NOT NULL|DEFAULT|GENERATED)", rest)[0].strip()
        out.append((name, typ, "NOT NULL" in rest, "DEFAULT" in rest or "GENERATED" in rest))
    return out
