#!/usr/bin/env python3
"""Khung sinh DDL ph17_assist (D03-03-PH17): đọc Phụ lục A và §8.2, §9.3 của D02-03-PH17, khai báo bảng, hiển thị CREATE TABLE.
Chép khung từ csdl/ph09/tools/sinh_ddl.py, chỉnh cho PH-17: RLS có COMMON (nền tảng), RLS theo người dùng cho hội thoại,
trigger chuyển trạng thái, cổng phát hành, pgvector có điều kiện. Không chạy trực tiếp; sinh_ddl.py gọi tệp này."""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS_PATH = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH17-frs-tro-ly-ai.md")
FRS = open(FRS_PATH, encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]
S = "ph17_assist"
TENANT_RE = "^T[0-9]{2}$"
TENANT_COMMON_RE = "^(T[0-9]{2}|COMMON)$"


def enum_values(name):
    m = re.search(r"^\| `%s`[^|]*\| ([^|]+) \|" % name, APPX, re.M)
    if not m:
        raise SystemExit("Không có enum " + name)
    return re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(1)))


def E(name, only=None, skip=()):
    v = [x for x in enum_values(name) if x not in skip and (only is None or x in only)]
    if only:
        assert set(only) <= set(enum_values(name)), (name, only)
    return "(" + ", ".join("'%s'" % x for x in v) + ")"


def X(*vals):
    """Giá trị CHECK chưa có ở Phụ lục A (đề nghị bổ sung, mục 9 của D03-03-PH17)."""
    return "(" + ", ".join("'%s'" % x for x in vals) + ")"


def settings():
    """Khóa 17.* của FRS 8.2: (khóa, mặc định jsonb, sàn, trần)."""
    sec = FRS[FRS.index("### 8.2. Tham số theo tenant"):FRS.index("## 9. Mã lỗi")]

    def num(s):
        s = s.strip().replace(" ", "")
        if "," in s:
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(".", "")
        return float(s) if "." in s else int(s)

    out = []
    for m in re.finditer(r"^\| `(17\.[a-z0-9.\-]+)` \| ([^|]+) \| ([^|]+) \|", sec, re.M):
        k, d, dom = m.group(1), m.group(2).strip(), m.group(3).strip()
        if d == "rỗng":
            dv = '""'
        else:
            d = d.strip("`")
            if d in ("true", "false"):
                dv = d
            elif re.fullmatch(r"[\d.,]+", d):
                dv = str(num(d))
            else:
                dv = '"%s"' % d
        lo = hi = None
        r = re.match(r"([\d.,]+)…([\d.,]+)", dom)
        if r:
            lo, hi = str(num(r.group(1))), str(num(r.group(2)))
        if k == "17.redteam.min-pass-rate":
            lo = hi = "100"
        out.append((k, dv, lo, hi, k in ("17.enabled", "17.model.external-allowed", "17.log.retention-days")))
    return out


def topics():
    sec = FRS[FRS.index("### 9.3. Sự kiện"):FRS.index("### 9.4. Danh mục API")]
    return re.findall(r"^\| EVT-17-\d{2} \| `\{tenant\}\.(assist\.[a-z\-.]+\.v1)`", sec, re.M)


SETTINGS = settings()
TOPICS = topics()
assert len(SETTINGS) == 49 and len(TOPICS) == 28, (len(SETTINGS), len(TOPICS))


def T(name, comment, cols, cons=(), idx=(), part=None, std=True, tid=False, trig=(), post=(), pk=None, ccomment=None, nopk=False, rls="tenant"):
    """rls: 'tenant' (RLS theo tenant), 'common' (đọc thêm COMMON, vai nền tảng ghi COMMON), 'user' (theo người dùng), None."""
    return dict(name=name, comment=comment, cols=cols, cons=list(cons), idx=list(idx), part=part, std=std, tid=tid,
                trig=list(trig), post=list(post), pk=pk, cc=ccomment or {}, nopk=nopk, rls=rls)


def chk(table, what, expr):
    return (f"ck_{table}_{what}", f"CHECK ({expr})")


def fk(table, col, target, tcol="id", cascade=False):
    return (f"fk_{table}_{col.replace('_id', '').replace(', ', '_')}",
            f"FOREIGN KEY (tenant_id, {col}) REFERENCES {S}.{target} (tenant_id, {tcol})" + (" ON DELETE CASCADE" if cascade else ""))


def fk1(table, col, target, cascade=False):
    """Khóa ngoại một cột tới bảng dùng chung (COMMON): tenant của dòng con có thể khác dòng cha."""
    return (f"fk_{table}_{col.replace('_id', '')}", f"FOREIGN KEY ({col}) REFERENCES {S}.{target} (id)" + (" ON DELETE CASCADE" if cascade else ""))


def reason20(col="reason"):
    return f"char_length({col}) >= 20"


def four_eyes(table, who, by="created_by", also=None):
    e = f"{who} IS NULL OR ({who} <> {by}" + (f" AND {who} IS DISTINCT FROM {also}" if also else "") + ")"
    return chk(table, "four_eyes", e)


STD_COLS = ["id uuid NOT NULL", "tenant_id varchar(16) NOT NULL"]
AUDIT_COLS = ["created_at timestamptz NOT NULL DEFAULT now()", "created_by varchar(64) NOT NULL", "updated_at timestamptz NOT NULL DEFAULT now()",
              "updated_by varchar(64) NOT NULL"]


def render_table(t, seq):
    n = t["name"]
    cols = []
    if t["std"] or t["part"] or not t["nopk"]:
        cols += STD_COLS
    cols += t["cols"]
    if t["std"]:
        cols += AUDIT_COLS + ["version integer NOT NULL DEFAULT 0"]
    cons = []
    if t["part"]:
        cons.append((f"pk_{n}", f"PRIMARY KEY ({t['pk'][0]}, {t['pk'][1]})"))
    elif not t["nopk"]:
        cons.append((f"pk_{n}", "PRIMARY KEY (id)"))
    if t["tid"]:
        cons.append((f"uq_{n}_tid", "UNIQUE (tenant_id, id)"))
    if n not in ("outbox_event", "inbox_event"):
        cons.append((f"ck_{n}_tenant", f"CHECK (tenant_id ~ '{TENANT_COMMON_RE if t['rls'] == 'common' else TENANT_RE}')"))
    cons += t["cons"]
    w = max(len(c.split()[0]) for c in cols)
    lines = [f"  {c.split()[0]:<{w}} {c[len(c.split()[0]) + 1:]}" for c in cols]
    for cn, cd in cons:
        lines.append(f"  CONSTRAINT {cn} {cd}")
    o = [f"-- @changeset ph17-{seq:04d}-{n.replace('_', '-')}", f"CREATE TABLE {S}.{n} (", ",\n".join(lines),
         ")" + (f" PARTITION BY RANGE ({t['part'][0]})" if t["part"] else "") + ";"]
    if t["part"]:
        o.append(f"CALL {S}.p_ensure_partitions('{S}.{n}', current_date, {t['part'][2]});")
    o += t["idx"]
    if t["std"]:
        o.append(f"CREATE TRIGGER tg_{n}_touch BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_touch();")
    for kind, args in t["trig"]:
        a = ", ".join("'%s'" % x.replace("'", "''") for x in args)
        if kind == "immutable":
            o.append(f"CREATE TRIGGER tg_{n}_immutable BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_immutable({a});")
        elif kind == "frozen":
            o.append(f"CREATE TRIGGER tg_{n}_frozen BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_frozen({a});")
        elif kind == "append_only":
            o.append(f"CREATE TRIGGER tg_{n}_append_only BEFORE UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_append_only();")
        elif kind == "transition":
            o.append(f"CREATE TRIGGER tg_{n}_fsm_{args[0]} BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_transition({a});")
        elif kind == "gate":
            o.append(f"CREATE TRIGGER tg_{n}_gate BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_release_gate({a});")
        elif kind == "raw":
            o.append(args[0])
    if t["rls"] == "tenant":
        o.append(f"CALL {S}.p_enable_rls('{S}.{n}');")
    elif t["rls"] == "common":
        o.append(f"CALL {S}.p_enable_rls_common('{S}.{n}');")
    elif t["rls"] == "user":
        o.append(f"CALL {S}.p_enable_rls_user('{S}.{n}', '{t['user_grant']}', '{t['user_job_delete']}');")
    q = lambda s: s.replace("'", "''")
    o.append(f"COMMENT ON TABLE {S}.{n} IS '{q(t['comment'])}';")
    for c, txt in t["cc"].items():
        o.append(f"COMMENT ON COLUMN {S}.{n}.{c} IS '{q(txt)}';")
    o += t["post"]
    o.append(f"-- @rollback DROP TABLE IF EXISTS {S}.{n} CASCADE;")
    return "\n".join(o)
