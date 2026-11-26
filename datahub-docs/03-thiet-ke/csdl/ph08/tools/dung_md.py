#!/usr/bin/env python3
"""Sinh các đoạn tự động của D03-03-PH08 từ ddl/ph08_dq.sql (gộp gen_tables_md, them_dac_ta_bang, gen_anh_xa của ph06).

Chạy từ thư mục csdl/ph08:  python3 tools/dung_md.py [--write]
Thay đoạn giữa các cặp <!-- gen:X:start --> ... <!-- gen:X:end --> (X = danh-muc, tables, en, fr) trong ../D03-03-PH08-csdl-chat-luong-du-lieu.md.
Khối đặc tả 10 mục mỗi bảng (K-TRINH-BAY §5) trích từ DDL: khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger; FR và EN lấy từ COMMENT ON TABLE.
Không có --write thì in ra màn hình. Sửa DDL ở sinh_ddl.py rồi sinh lại, không sửa tay các đoạn gen.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH08-csdl-chat-luong-du-lieu.md")
sql = open(os.path.join(ROOT, "ddl", "ph08_dq.sql"), encoding="utf-8").read()
S = "ph08_dq"
STD = ["id", "tenant_id", "created_at", "created_by", "updated_at", "updated_by", "version"]

order = re.findall(r"CREATE TABLE %s\.(\w+) \(" % S, sql)
tcomment = dict(re.findall(r"COMMENT ON TABLE %s\.(\w+) IS '((?:[^']|'')*)';" % S, sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN %s\.(\w+)\.(\w+) IS '((?:[^']|'')*)';" % S, sql)}
bodies, part = {}, {}
for m in re.finditer(r"CREATE TABLE %s\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;" % S, sql, re.S):
    bodies[m.group(1)] = m.group(2)
    if m.group(4):
        part[m.group(1)] = m.group(4)
EN_NAME = {}
GHI_CHU = {
    "shedlock": "Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.",
    "outbox_event": "Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (SAD 7.3).",
    "inbox_event": "Khử trùng sự kiện nhận từ phân hệ khác theo `event_id` (tiêu thụ lũy đẳng).",
}
# FR không nhắc trong COMMENT của bảng nào: ghi bảng phục vụ
FR_TAY = {
    7: ["dq_asset"], 10: ["dq_profile_column", "dq_rule", "dq_rule_template"], 11: ["dq_profile_run", "dq_profile_column"],
    19: ["dq_rule_set_version", "dq_rule"], 20: ["dq_rule_set", "dq_rule_set_version", "dq_rule"], 25: ["dq_scan_job", "inbox_event"],
    33: ["dq_rule", "dq_inline_stat"], 35: ["dq_rule", "dq_inline_stat", "dq_domain"], 45: ["dq_issue", "dq_issue_activity"],
    46: ["dq_issue", "dq_issue_activity"], 55: ["dq_report"], 57: ["outbox_event", "dq_score_snapshot"], 60: ["outbox_event", "dq_issue_activity"],
    50: ["dq_score_snapshot", "dq_scan_job", "dq_alert", "dq_issue"], 61: ["dq_score_snapshot"],
}


def expand(text):
    out = []
    for m in re.finditer(r"FR-08-(\d{3})((?:(?:, |…)\d{3})*)", text):
        nums, prev = [int(m.group(1))], int(m.group(1))
        for sep, n in re.findall(r"(, |…)(\d{3})", m.group(2)):
            n = int(n)
            nums += list(range(prev + 1, n + 1)) if sep == "…" else [n]
            prev = n
        out += nums
    return out


fr_tables, en_tables = {}, {}
for t in order:
    for n in expand(tcomment[t]):
        fr_tables.setdefault(n, []).append(t)
    for e in dict.fromkeys(re.findall(r"EN-08-\d{2}", tcomment[t])):
        en_tables.setdefault(e, []).append(t)
for n, ts in FR_TAY.items():
    for t in ts:
        if t not in fr_tables.setdefault(n, []):
            fr_tables[n].append(t)

code = lambda ts: ", ".join("`%s`" % t for t in ts)


def danh_muc():
    L = ["| Mục | Bảng | Thực thể | Phân vùng | FR chính |", "|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(dict.fromkeys(re.findall(r"EN-08-\d{2}", tcomment[t]))) or "Hạ tầng"
        fs = sorted(n for n, ts in fr_tables.items() if t in ts)
        ft = ", ".join("%03d" % n for n in fs[:5]) + ("…" if len(fs) > 5 else "") if fs else "Hạ tầng"
        L.append(f"| 3.{i} | `{t}` | {ens} | {'Tháng, ' + part[t] if t in part else 'Không'} | {ft} |")
    L += ["", ": Danh mục bảng của schema ph08_dq", ""]
    return "\n".join(L)


def parse_cols(name):
    cols, enums = [], {}
    body = bodies[name]
    for line in body.split("\n"):
        s = line.strip().rstrip(",")
        if not s or s.startswith(("--", "CONSTRAINT")):
            continue
        cm = re.match(r"(\w+)\s+(.+)$", s)
        if cm:
            col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
            nn = "NOT NULL" in rest
            d = re.search(r"DEFAULT (.+)$", rest)
            typ = re.sub(r" (NOT NULL|DEFAULT .+)$", "", rest).replace(" NOT NULL", "")
            cols.append((col, typ.strip(), nn, d.group(1) if d else ""))
    for col, vals in re.findall(r"CHECK \((\w+) IN \(([^)]*)\)", body):
        enums.setdefault(col, re.findall(r"'([A-Z0-9_]+)'", vals))
    for col, vals in re.findall(r"CHECK \(\w+ IS NULL OR (\w+) IN \(([^)]*)\)", body):
        enums.setdefault(col, re.findall(r"'([A-Z0-9_]+)'", vals))
    return cols, enums


def con(body, kind):
    out = []
    for c in re.finditer(r"CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK)\s*(.*?)(?=,\n\s*CONSTRAINT|$)", body, re.S):
        if c.group(2) == kind:
            out.append((c.group(1), re.sub(r"\s+", " ", c.group(3)).strip().rstrip(",")))
    return out


def khoi(t):
    b = bodies[t]
    mo_ta = tcomment[t].replace("''", "'").strip().rstrip(".")
    pk = [d for _, d in con(b, "PRIMARY KEY")]
    uq = ["`%s` %s" % (n, d) for n, d in con(b, "UNIQUE")]
    uq += ["`%s` %s%s" % (m.group(1), m.group(2), " có điều kiện" if m.group(3) else "") for m in re.finditer(
        r"CREATE UNIQUE INDEX (\w+) ON %s\.%s (?:USING \w+ )?(\([^;]*?\))( WHERE [^;]*)?;" % (S, t), sql)]
    fk = []
    for n, d in con(b, "FOREIGN KEY"):
        mm = re.match(r"\(([^)]*)\) REFERENCES %s\.(\w+)" % S, d)
        fk.append("(%s) → `%s`" % (mm.group(1), mm.group(2)) if mm else d)
    pre = "ck_%s_" % t
    ck = [n[len(pre):] if n.startswith(pre) else n for n, _ in con(b, "CHECK")]
    ix = ["`%s`" % m.group(1) for m in re.finditer(r"CREATE INDEX (\w+) ON %s\.%s\b" % (S, t), sql)]
    if re.search(r"CALL %s\.p_enable_rls_shared\('%s\.%s'\)" % (S, S, t), sql):
        cl = "RLS FORCE, mẫu S: mọi tenant đọc được dòng `COMMON`, chỉ phiên PLATFORM ghi `COMMON`."
    elif re.search(r"CALL %s\.p_enable_rls\('%s\.%s'\)" % (S, S, t), sql):
        cl = "RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên."
    else:
        cl = "Không bật RLS. " + GHI_CHU.get(t, "Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.")
    pv = []
    if t in part:
        pv.append("Phân vùng tháng theo `%s`" % part[t])
    im = re.search(r"CREATE TRIGGER (tg_%s_immutable) BEFORE UPDATE ON %s\.%s FOR EACH ROW EXECUTE FUNCTION %s\.tg_immutable\(([^)]*)\)" % (t, S, t, S), sql)
    if im:
        pv.append("Bất biến: %s (`%s`)" % (", ".join("`%s`" % c.strip(" '") for c in im.group(2).split(",")), im.group(1)))
    other = sorted(set(re.findall(r"CREATE TRIGGER (\w+) BEFORE [^;]*? ON %s\.%s " % (S, t), sql)) - {"tg_%s_touch" % t, "tg_%s_immutable" % t})
    if other:
        pv.append("Trigger: " + ", ".join("`%s`" % x for x in other))
    fs = sorted(n for n, ts in fr_tables.items() if t in ts)
    ens = list(dict.fromkeys(re.findall(r"EN-08-\d{2}", mo_ta)))
    fr = ("FR-08-" + ", ".join("%03d" % n for n in fs)) if fs else "Hạ tầng dùng chung"
    if ens:
        fr += "; " + ", ".join(ens)
    if re.search(r"(?m)^\s+version\s+integer", b):
        gc = GHI_CHU.get(t, "ETag là `version`.")
    else:
        gc = GHI_CHU.get(t, "Không có `version`.")
    muc = [("Mục đích", mo_ta), ("FR phục vụ", fr), ("Khóa chính", ", ".join(pk) or "Không"), ("Duy nhất", ", ".join(uq) or "Không"),
           ("Khóa ngoại", ", ".join(fk) or "Không"), ("Ràng buộc CHECK", ("`ck_%s_` + " % t + ", ".join("`%s`" % x for x in ck)) if ck else "Không"),
           ("Chỉ mục", ", ".join(ix) if ix else "Chỉ khóa chính và khóa duy nhất"), ("Cách ly tenant", cl), ("Phân vùng, bất biến", "; ".join(pv) or "Không"), ("Ghi chú", gc)]
    o = ["::: dac-ta"]
    for k, v in muc:
        v = v.strip()
        if v and not v.endswith("."):
            v += "."
        o += ["**%s.** %s" % (k, v), ""]
    o[-1] = ":::"
    return "\n".join(o)


def tables():
    out = []
    for i, t in enumerate(order, 1):
        cols, enums = parse_cols(t)
        out.append(f"### 3.{i}. `{t}`\n")
        out.append(khoi(t) + "\n")
        present = [c for c in STD if any(c == x[0] for x in cols)]
        rows, plain = [], []
        for c, typ, nn, d in cols:
            if c in STD and len(present) >= 6:
                continue
            note = ccomment.get((t, c), "").replace("''", "'")
            if c in enums and len(enums[c]) <= 24 and c not in ("dimension", "severity"):
                note = (note + " " if note else "") + "Giá trị: " + ", ".join(f"`{v}`" for v in enums[c]) + "."
            spec = typ + ("" if nn else ", NULL") + (f", mặc định {d}" if d else "")
            if note:
                rows.append(f"| `{c}` | `{spec}` | {note.replace('|', chr(92) + '|')} |")
            else:
                short = typ.replace("timestamptz", "tstz").replace("varchar", "v").replace("integer", "int").replace("boolean", "bool").replace("numeric", "num")
                plain.append(f"`{c}` {short}")
        if rows:
            out += ["| Cột | Kiểu | Ghi chú |", "|---|---|---|"] + rows + ["", f": Cột nổi bật của bảng `{t}`", ""]
        if plain:
            out.append("Cột khác: " + "; ".join(plain) + ".")
        out.append("")
    return "\n".join(out)


def en():
    L = ["| Thực thể | Bảng hiện thực |", "|---|---|"]
    for e in sorted(en_tables):
        L.append(f"| {e} | {code(en_tables[e])} |")
    L += ["", ": Ánh xạ thực thể EN-08 sang bảng", ""]
    infra = [t for t in order if not re.search(r"EN-08-\d{2}", tcomment[t])]
    L.append("Bảng hạ tầng không mang mã EN: " + code(infra) + ".")
    return "\n".join(L)


NHOM = {"A": range(1, 8), "B": range(8, 12), "C": range(12, 23), "D": range(23, 32), "E": range(32, 36), "F": range(36, 41), "G": range(41, 47),
        "H": range(47, 50), "I": range(50, 58), "J": range(58, 62)}


def fr():
    L = ["| Nhóm | FR | Bảng hiện thực |", "|---|---|---|"]
    for g, rg in NHOM.items():
        for n in rg:
            L.append(f"| {g} | FR-08-{n:03d} | {code(fr_tables[n])} |")
    L += ["", ": Ma trận FR-08 sang bảng", ""]
    return "\n".join(L)


BLOCKS = {"danh-muc": danh_muc, "tables": tables, "en": en, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 62) if n not in fr_tables]
    if miss:
        print("FR chưa có bảng:", miss)
        sys.exit(1)
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        for k, f in BLOCKS.items():
            doc, n = re.subn(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (k, k), lambda m: m.group(1) + f() + "\n" + m.group(2), doc, flags=re.S)
            print(k, "đã chèn" if n else "THIẾU cặp đánh dấu")
        open(DOC, "w", encoding="utf-8").write(doc)
    else:
        for k, f in BLOCKS.items():
            print(f"--- {k}\n{f()}")
