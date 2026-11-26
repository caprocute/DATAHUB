#!/usr/bin/env python3
"""Sinh các đoạn tự động của D03-03-PH16 từ ddl/ph16_kpi.sql (gộp gen_tables_md, them_dac_ta_bang, gen_anh_xa của ph06).

Chạy từ thư mục csdl/ph16:  python3 tools/dung_md.py [--write]
Thay đoạn giữa các cặp <!-- gen:X:start --> ... <!-- gen:X:end --> (X = danh-muc, tables, en, fr) trong ../D03-03-PH16-csdl-bao-cao-chi-tieu.md.
Khối đặc tả 10 mục mỗi bảng (K-TRINH-BAY §5) trích từ DDL: khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger; FR và EN lấy từ COMMENT ON TABLE.
Không có --write thì in ra màn hình. Sửa DDL ở sinh_ddl.py rồi sinh lại, không sửa tay các đoạn gen.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH16-csdl-bao-cao-chi-tieu.md")
sql = open(os.path.join(ROOT, "ddl", "ph16_kpi.sql"), encoding="utf-8").read()
S = "ph16_kpi"
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
    21: ["kpi_indicator_value", "outbox_event"], 23: ["kpi_aggregation_run", "kpi_observation"], 24: ["kpi_reporting_period", "kpi_aggregation_run"],
    35: ["kpi_indicator_value", "kpi_report_version"], 36: ["kpi_report_version", "kpi_report_signature", "kpi_export_job"],
    37: ["kpi_indicator_value", "kpi_group_score"], 41: ["kpi_indicator_value"], 42: ["kpi_aggregation_run", "kpi_data_source"],
    48: ["kpi_arch_component", "inbox_event"], 54: ["kpi_national_submission", "kpi_arch_component", "kpi_report_version"],
    56: ["outbox_event"], 57: ["kpi_tenant_setting", "kpi_observation", "kpi_report_version"], 58: ["kpi_aggregation_run", "kpi_data_source", "outbox_event"],
}


def expand(text):
    out = []
    for m in re.finditer(r"FR-16-(\d{3})((?:(?:, |…)\d{3})*)", text):
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
    for e in dict.fromkeys(re.findall(r"EN-16-\d{2}", tcomment[t])):
        en_tables.setdefault(e, []).append(t)
for n, ts in FR_TAY.items():
    for t in ts:
        if t not in fr_tables.setdefault(n, []):
            fr_tables[n].append(t)

code = lambda ts: ", ".join("`%s`" % t for t in ts)


def danh_muc():
    L = ["| Mục | Bảng | Thực thể | Phân vùng | FR chính |", "|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(dict.fromkeys(re.findall(r"EN-16-\d{2}", tcomment[t]))) or "Hạ tầng"
        fs = sorted(n for n, ts in fr_tables.items() if t in ts)
        ft = ", ".join("%03d" % n for n in fs[:5]) + ("…" if len(fs) > 5 else "") if fs else "Hạ tầng"
        L.append(f"| 3.{i} | `{t}` | {ens} | {'Tháng, ' + part[t] if t in part else 'Không'} | {ft} |")
    L += ["", ": Danh mục bảng của schema ph16_kpi", ""]
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
    uq = ["`%s` %s" % (n, d) for n, d in con(b, "UNIQUE") if not n.endswith("_tid")]  # uq_*_tid (tenant_id, id) có ở mọi bảng là đích khóa ngoại, nêu ở 1.2
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
        cl = "Mẫu S (1.2): đọc thêm dòng `COMMON`."
    elif re.search(r"CALL %s\.p_enable_rls\('%s\.%s'\)" % (S, S, t), sql):
        cl = "Mẫu P (1.2)."
    else:
        cl = "Không bật RLS. " + GHI_CHU.get(t, "Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.")
    pv = []
    if t in part:
        pv.append("Phân vùng tháng theo `%s`" % part[t])
    im = re.search(r"CREATE TRIGGER (tg_%s_immutable) BEFORE UPDATE ON %s\.%s FOR EACH ROW EXECUTE FUNCTION %s\.tg_immutable\(([^)]*)\)" % (t, S, t, S), sql)
    if im:
        pv.append("Bất biến: %s" % ", ".join("`%s`" % c.strip(" '") for c in im.group(2).split(",")))
    other = sorted(set(re.findall(r"CREATE TRIGGER (\w+) BEFORE [^;]*? ON %s\.%s " % (S, t), sql)) - {"tg_%s_touch" % t, "tg_%s_immutable" % t})
    if other:
        pv.append("Trigger: " + ", ".join("`%s`" % x for x in other))
    fs = sorted(n for n, ts in fr_tables.items() if t in ts)
    ens = list(dict.fromkeys(re.findall(r"EN-16-\d{2}", mo_ta)))
    fr = ("FR-16-" + ", ".join("%03d" % n for n in fs)) if fs else "Hạ tầng dùng chung"
    if ens:
        fr += "; " + ", ".join(ens)
    if re.search(r"(?m)^\s+version\s+integer", b):
        gc = GHI_CHU.get(t, "ETag `version`.")
    else:
        gc = GHI_CHU.get(t, "Không có `version`.")
    muc = [("Mục đích", mo_ta), ("FR phục vụ", fr), ("Khóa chính", ", ".join(pk) or "Không"), ("Duy nhất", ", ".join(uq) or "Không"),
           ("Khóa ngoại", ", ".join(fk) or "Không"), ("Ràng buộc CHECK", ("`ck_%s_` + " % t + ", ".join("`%s`" % x for x in ck)) if ck else "Không"),
           ("Chỉ mục", ", ".join(ix) if ix else "Không thêm"), ("Cách ly tenant", cl), ("Phân vùng, bất biến", "; ".join(pv) or "Không"), ("Ghi chú", gc)]
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
    L += ["", ": Ánh xạ thực thể EN-16 sang bảng", ""]
    infra = [t for t in order if not re.search(r"EN-16-\d{2}", tcomment[t])]
    L.append("Bảng hạ tầng không mang mã EN: " + code(infra) + ".")
    return "\n".join(L)


NHOM = {"A Bộ chỉ tiêu": range(1, 9), "B Nguồn số liệu": range(9, 17), "C Tính toán": range(17, 25), "D Báo cáo": range(25, 33), "E Xuất, phân phối": range(33, 38),
        "F Bảng điều khiển": range(38, 43), "G Sổ kiến trúc": range(43, 50), "H Gửi quốc gia": range(50, 55), "I Quản trị": range(55, 59)}


def fr():
    L = ["| FR | Bảng hiện thực |", "|---|---|"]
    for g, rg in NHOM.items():
        for n in rg:
            L.append(f"| FR-16-{n:03d} ({g[0]}) | {code(fr_tables[n])} |")
    L += ["", ": Ma trận FR-16 sang bảng", ""]
    return "\n".join(L)


BLOCKS = {"danh-muc": danh_muc, "tables": tables, "en": en, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 59) if n not in fr_tables]
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
