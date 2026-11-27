#!/usr/bin/env python3
"""Sinh đặc tả bảng (Markdown) từ ddl/ph18_ops.sql và chèn vào D03-03-PH18 §3.

Chạy từ thư mục csdl/ph18:  python3 tools/gen_tables_md.py [--write]
Đọc CREATE TABLE, COMMENT ON TABLE/COLUMN, CHECK có liệt kê giá trị (IN (...)).
Cột có ghi chú hoặc enum thành dòng bảng; cột còn lại và bảy cột ngữ cảnh chuẩn
(id, tenant_id, created_*, updated_*, version) gộp một dòng để tài liệu gọn. Kiểu ghi
NULL khi cột cho phép rỗng. Với --write thay đoạn giữa <!-- gen:tables:start --> và
<!-- gen:tables:end --> trong ../D03-03-PH18-csdl-van-hanh.md; không có thì in ra.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH18-csdl-van-hanh.md")
sql = open(os.path.join(ROOT, "ddl", "ph18_ops.sql"), encoding="utf-8").read()
ENUMS = {}  # PH-18: trạng thái lấy từ BRIEF-PH18 §4, in trực tiếp danh sách giá trị
STD = ["id", "tenant_id", "created_at", "created_by", "updated_at", "updated_by", "version"]

tcomment = dict(re.findall(r"COMMENT ON TABLE ph18_ops\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph18_ops\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
indexes = {}
for uq, name, t in re.findall(r"CREATE (UNIQUE )?INDEX (\w+) ON ph18_ops\.(\w+)", sql):
    indexes.setdefault(t, []).append(name)


def parse():
    tables = []
    for m in re.finditer(r"CREATE TABLE ph18_ops\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;", sql, re.S):
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
        for col, vals in re.findall(r"CHECK \((\w+) IN \(([^)]*)\)", body):
            enums.setdefault(col, re.findall(r"'([A-Z0-9_]+)'", vals))
        for col, vals in re.findall(r"CHECK \(\w+ IS NULL OR (\w+) IN \(([^)]*)\)", body):
            enums.setdefault(col, re.findall(r"'([A-Za-z0-9_-]+)'", vals))
        tables.append((name, cols, enums, part))
    return tables


def rut_gon(text, gioi_han=150):
    """Giữ các câu đầu của COMMENT ON TABLE tới ~200 ký tự (đủ nêu thực thể, FR, quy tắc chính); phần còn lại ở DDL."""
    cau = re.split(r"(?<=\.)\s+(?=[A-ZĐÂÊÔƠƯ])", text)
    out = cau[0]
    for c in cau[1:]:
        if len(out) + len(c) + 1 > gioi_han:
            break
        out += " " + c
    return out


def render(tables):
    """Gọn: cột có ghi chú hoặc enum thành dòng bảng; cột còn lại liệt kê một dòng."""
    out = []
    for i, (t, cols, enums, part) in enumerate(tables, 1):
        out.append(f"### 3.{i}. `{t}`\n")
        if t in tcomment:
            out.append(rut_gon(tcomment[t].replace("''", "'")) + "\n")
        present = [c for c in STD if any(c == x[0] for x in cols)]
        rows, plain = [], []
        short = lambda typ: typ.replace("timestamptz", "tstz").replace("varchar", "v").replace("integer", "int").replace("boolean", "bool")
        for c, typ, nn, d in cols:
            if c in STD and len(present) >= 6:
                continue
            note = ccomment.get((t, c), "").replace("''", "'")
            tag = ""
            if c in enums:
                nm = [k for k, v in ENUMS.items() if v == frozenset(enums[c])]
                tag = " " + (nm[0] if nm else "{" + ", ".join(enums[c]) + "}")
            spec = typ + ("" if nn else ", NULL") + (f", mặc định {d}" if d else "")
            if note:
                rows.append(f"| `{c}` | `{spec}` | {(note + (' Enum `%s`.' % tag.strip() if tag and tag.strip()[0] != '{' else '')).replace('|', chr(92) + '|')} |")
            else:
                plain.append(f"`{c}` {short(typ)}{tag}")
        if rows:
            out.append("| Cột | Kiểu | Ghi chú |")
            out.append("|---|---|---|")
            out.extend(rows)
            out.append("")
        extra = []
        if plain:
            extra.append(("Cột khác: " if rows else "Cột: ") + "; ".join(plain))
        if part:
            extra.append(f"phân vùng `RANGE ({part})`")
        if extra:
            line = ", ".join(extra[:2]) + (". " + "; ".join(extra[2:]).capitalize() if extra[2:] else "")
            out.append(line.rstrip(".") + ".")
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
