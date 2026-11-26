#!/usr/bin/env python3
"""Sinh bảng mô tả cột (Markdown) từ ddl/ph15_portal.sql và chèn vào D03-03-PH15 giữa hai dấu
<!-- gen:tables:start --> và <!-- gen:tables:end -->.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph15/tools/gen_tables_md.py 03-thiet-ke/csdl/D03-03-PH15-csdl-cong-nha-phat-trien.md
Không có đối số thì in ra màn hình. Cột ngữ cảnh D00-01 §5.1 gộp một dòng; cột có CHECK ... IN (...) được thêm
"Giá trị: ..." vào ghi chú để enum trong tài liệu luôn khớp DDL (và Phụ lục A của FRS).
Đọc COMMENT ON TABLE, COMMENT ON COLUMN; sau đó chạy them_dac_ta_bang.py để thêm khối đặc tả 10 mục."""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sql = open(os.path.join(ROOT, "ddl", "ph15_portal.sql"), encoding="utf-8").read()

tables = []
for m in re.finditer(r"CREATE TABLE ph15_portal\.(\w+) \((.*?)\n\)(?: PARTITION BY RANGE \((\w+)\))?;", sql, re.S):
    name, body, part = m.group(1), m.group(2), m.group(3)
    cols = []
    for line in body.split("\n"):
        line = line.strip().rstrip(",")
        if not line or line.startswith("CONSTRAINT") or line.startswith("--"):
            continue
        cm = re.match(r"(\w+)\s+(.+)$", line)
        if not cm or cm.group(1) in ("CONSTRAINT",) or line.startswith(("OR ", "AND ")):
            continue
        col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
        nn = "NOT NULL" in rest
        default = re.search(r"DEFAULT (.+?)(?: NOT NULL)?$", rest)
        typ = re.sub(r" (NOT NULL|DEFAULT .+)$", "", rest).replace(" NOT NULL", "")
        typ = typ.replace("ph15_portal.t_tenant", "varchar(16)")
        cols.append((col, typ.strip(), "x" if nn else "", default.group(1) if default else ""))
    enums = {}
    for em in re.finditer(r"CHECK \((?:\w+ <> '[A-Z_]+' OR )?\(?(\w+) IN \(([^)]*)\)", body):
        enums.setdefault(em.group(1), em.group(2).replace("'", "").replace(", ", ", "))
    tables.append((name, cols, part, enums))

tcomment = dict(re.findall(r"COMMENT ON TABLE ph15_portal\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph15_portal\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
STD = {
    "id": "Khóa chính, UUID v7 sinh ở ứng dụng.",
    "tenant_id": "Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép.",
}
CTX = ["created_at", "created_by", "updated_at", "updated_by", "version"]


def render():
    out = []
    for i, (t, cols, part, enums) in enumerate(tables, 1):
        out.append(f"### 3.{i}. `{t}`\n")
        out.append(tcomment.get(t, "").replace("''", "'") + "\n")
        out.append("| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |")
        out.append("|---|---|---|---|")
        names = [c[0] for c in cols]
        collapse = all(c in names for c in CTX)
        for c, typ, nn, d in cols:
            if c == "tenant_id" and "id" in names:
                continue
            if c == "id" and "tenant_id" in names:
                out.append("| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |")
                continue
            if collapse and c in CTX:
                if c == "created_at":
                    out.append("| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |")
                continue
            note = ccomment.get((t, c), STD.get(c, "")).replace("''", "'")
            note = re.split(r"(?<=[a-zà-ỹ)]); |(?<=[a-zà-ỹ)])\. ", note)[0].rstrip(".")
            if len(note) > 50 and "Giá trị" not in note:
                note = re.split(r", | \(", note)[0].rstrip(".")
            note = (note + ".") if note else note
            if c in enums and "Giá trị" not in note:
                note = (note + " " if note else "") + "Giá trị: " + enums[c].replace(", ", ", ") + "."
            note = note.replace("|", "\\|")
            nd = ("x" if nn else "") + ((" `" + d + "`") if d else "")
            out.append(f"| `{c}` | `{typ}` | {nd} | {note} |")
        out.append("")
    return "\n".join(out)


txt = render()
if len(sys.argv) > 1:
    f = sys.argv[1]
    s = open(f, encoding="utf-8").read()
    a, b = "<!-- gen:tables:start -->", "<!-- gen:tables:end -->"
    i, j = s.index(a) + len(a), s.index(b)
    s = s[:i] + "\n" + txt + "\n" + s[j:]
    open(f, "w", encoding="utf-8").write(s)
    print("đã chèn", len(tables), "bảng")
else:
    sys.stdout.write(txt)
