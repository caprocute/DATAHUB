#!/usr/bin/env python3
"""Sinh bảng mô tả cột (Markdown) từ ddl/ph05_adapter.sql.

Chạy: python3 tools/gen_tables_md.py > /tmp/tables.md (từ thư mục csdl/ph05).
Đọc CREATE TABLE và COMMENT ON TABLE/COLUMN; cột không có COMMENT để trống.
Kết quả được dán vào D03-03-PH05 §3 giữa hai dấu <!-- gen:tables:start/end -->.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sql = open(os.path.join(ROOT, "ddl", "ph05_adapter.sql"), encoding="utf-8").read()

tables = []
for m in re.finditer(r"CREATE TABLE ph05_adapter\.(\w+) \((.*?)\n\)( PARTITION BY [^;]+)?;", sql, re.S):
    name, body = m.group(1), m.group(2)
    cols = []
    for line in body.split("\n"):
        line = line.strip().rstrip(",")
        if not line or line.startswith("CONSTRAINT") or line.startswith("--"):
            continue
        cm = re.match(r"(\w+)\s+(.+)$", line)
        if not cm:
            continue
        col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
        nn = "NOT NULL" in rest
        default = re.search(r"DEFAULT (.+)$", rest)
        typ = re.sub(r" (NOT NULL|DEFAULT .+)$", "", rest).replace(" NOT NULL", "")
        cols.append((col, typ.strip(), "x" if nn else "", default.group(1) if default else ""))
    tables.append((name, cols))

tcomment = dict(re.findall(r"COMMENT ON TABLE ph05_adapter\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph05_adapter\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
STD = {
    "id": "Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).",
    "tenant_id": "Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS.",
    "created_at": "Thời điểm tạo.", "created_by": "Người tạo (mã người dùng hoặc `system:*`).",
    "updated_at": "Thời điểm sửa cuối (trigger `tg_touch`).", "updated_by": "Người sửa cuối.",
    "version": "Khóa lạc quan; thành phần của ETag (`If-Match`).",
}

out = []
for i, (t, cols) in enumerate(tables, 1):
    out.append(f"### 3.{i}. `{t}`\n")
    if t in tcomment:
        out.append(tcomment[t].replace("''", "'") + "\n")
    out.append("| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |")
    out.append("|---|---|---|---|---|")
    for c, typ, nn, d in cols:
        note = ccomment.get((t, c), STD.get(c, "")).replace("''", "'").replace("|", "\\|")
        out.append(f"| `{c}` | `{typ}` | {nn} | {('`' + d + '`') if d else ''} | {note} |")
    out.append("")
sys.stdout.write("\n".join(out))
