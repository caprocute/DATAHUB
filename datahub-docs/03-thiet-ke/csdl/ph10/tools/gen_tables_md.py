#!/usr/bin/env python3
"""Sinh đặc tả bảng (Markdown) từ ddl/ph10_event.sql và chèn vào D03-03-PH10 §3.

Chạy từ thư mục csdl/ph10:  python3 tools/gen_tables_md.py [--write]
Đọc CREATE TABLE, COMMENT ON TABLE/COLUMN, CHECK có liệt kê giá trị (IN (...)).
Bảy cột ngữ cảnh chuẩn (id, tenant_id, created_*, updated_*, version) gộp một dòng
để tài liệu gọn. Với --write thay đoạn giữa <!-- gen:tables:start --> và
<!-- gen:tables:end --> trong ../D03-03-PH10-csdl-su-kien.md; không có thì in ra.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH10-csdl-su-kien.md")
sql = open(os.path.join(ROOT, "ddl", "ph10_event.sql"), encoding="utf-8").read()
STD = ["id", "tenant_id", "created_at", "created_by", "updated_at", "updated_by", "version"]

tcomment = dict(re.findall(r"COMMENT ON TABLE ph10_event\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph10_event\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
indexes = {}
for uq, name, t in re.findall(r"CREATE (UNIQUE )?INDEX (\w+) ON ph10_event\.(\w+)", sql):
    indexes.setdefault(t, []).append(name)


def parse():
    tables = []
    for m in re.finditer(r"CREATE TABLE ph10_event\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;", sql, re.S):
        name, body, part = m.group(1), m.group(2), m.group(4)
        cols, enums = [], {}
        for line in body.split("\n"):
            s = line.strip().rstrip(",")
            if not s or s.startswith("--"):
                continue
            if s.startswith("CONSTRAINT"):
                continue
            cm = re.match(r"(\w+)\s+(.+)$", s)
            if cm and cm.group(1) not in ("OR", "AND"):
                col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
                nn = "NOT NULL" in rest
                d = re.search(r"DEFAULT (.+)$", rest)
                typ = re.sub(r" (NOT NULL|DEFAULT .+)$", "", rest).replace(" NOT NULL", "")
                cols.append((col, typ.strip(), nn, d.group(1) if d else ""))
        for col, vals in re.findall(r"CHECK \(\(?(\w+) IN \(([^)]*)\)", body):
            enums[col] = re.findall(r"'([A-Z_]+)'", vals)
        for col, vals in re.findall(r"CHECK \(\w+ IS NULL OR (\w+) IN \(([^)]*)\)", body):
            enums[col] = re.findall(r"'([A-Za-z_-]+)'", vals)
        tables.append((name, cols, enums, part))
    return tables


def render(tables):
    out = []
    for i, (t, cols, enums, part) in enumerate(tables, 1):
        out.append(f"### 3.{i}. `{t}`\n")
        if t in tcomment:
            out.append(tcomment[t].replace("''", "'") + "\n")
        out.append("| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |")
        out.append("|---|---|---|---|---|")
        present = [c for c in STD if any(c == x[0] for x in cols)]
        for c, typ, nn, d in cols:
            if c in STD and len(present) >= 6:
                continue
            note = ccomment.get((t, c), "").replace("''", "'")
            if c in enums and not note:
                note = "Một trong " + ", ".join(f"`{v}`" for v in enums[c])
            elif c in enums:
                note += " Giá trị: " + ", ".join(f"`{v}`" for v in enums[c]) + "."
            note = note.replace("|", "\\|")
            dd = f"`{d}`" if d else ""
            out.append(f"| `{c}` | `{typ}` | {'x' if nn else ''} | {dd} | {note} |")
        if len(present) >= 6:
            out.append(f"| {', '.join('`' + c + '`' for c in present)} | | x | | Cột ngữ cảnh chuẩn (§1.3) |")
        extra = []
        if part:
            extra.append(f"Phân vùng `RANGE ({part})`")
        if t in indexes:
            extra.append("Chỉ mục: " + ", ".join(f"`{x}`" for x in indexes[t]))
        if extra:
            out.append("\n" + ". ".join(extra) + ".")
        out.append("")
    return "\n".join(out)


if __name__ == "__main__":
    md = render(parse())
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        new = re.sub(r"(<!-- gen:tables:start -->\n).*?(<!-- gen:tables:end -->)", lambda m: m.group(1) + md + m.group(2), doc, flags=re.S)
        open(DOC, "w", encoding="utf-8").write(new)
        print(f"Đã chèn {md.count('### 3.')} bảng vào {DOC}")
    else:
        sys.stdout.write(md)
