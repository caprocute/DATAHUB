#!/usr/bin/env python3
"""Sinh phần cột của chương 3 (Markdown) từ ddl/ph01_*.sql của PH-01.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph01/tools/gen_tables_md.py > /tmp/tables.md
Đọc CREATE TABLE theo thứ tự tệp và COMMENT ON TABLE/COLUMN; cột không có COMMENT lấy mô tả chuẩn của cột ngữ cảnh
(D00-01 §5.1) hoặc để trống. Kết quả đặt giữa <!-- gen:tables:start --> và <!-- gen:tables:end --> của D03-03-PH01,
rồi chạy them_dac_ta_bang.py để thêm khối đặc tả 10 mục. Bỏ tệp 99 (di trú) vì không tạo bảng.
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL = ''.join(open(f, encoding='utf-8').read() + '\n' for f in sorted(glob.glob(os.path.join(ROOT, 'ddl', 'ph01_[0-9]*.sql'))) if 'ph01_99_' not in f)

tables = []
for m in re.finditer(r'CREATE TABLE ph01_onboarding\.(\w+) \((.*?)\n\)( PARTITION BY [^;]+)?;', SQL, re.S):
    name, body = m.group(1), m.group(2)
    cols = []
    for line in body.split('\n'):
        line = line.strip().rstrip(',')
        if not line or line.startswith('--'):
            continue
        if line.startswith('CONSTRAINT'):
            break  # cột luôn đứng trước ràng buộc; dòng sau là phần tiếp của ràng buộc
        cm = re.match(r'(\w+)\s+(.+)$', line)
        if not cm:
            continue
        col, rest = cm.group(1), re.sub(r'\s+', ' ', cm.group(2))
        nn = 'NOT NULL' in rest
        gen = re.search(r'GENERATED ALWAYS AS', rest)
        default = re.search(r'DEFAULT (.+)$', rest)
        if gen:
            typ, dflt = rest.split(' GENERATED')[0], 'cột sinh'
        else:
            typ = re.sub(r' (NOT NULL|DEFAULT .+)$', '', rest).replace(' NOT NULL', '').strip()
            dflt = default.group(1) if default else ''
            dflt = re.sub(r' NOT NULL$', '', dflt)
        cols.append((col, typ, 'x' if nn else '', dflt))
    tables.append((name, cols))

tcomment = dict(re.findall(r"COMMENT ON TABLE ph01_onboarding\.(\w+) IS '((?:[^']|'')*)';", SQL))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph01_onboarding\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", SQL)}
STD = {
    'id': 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).',
    'tenant_id': 'Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS.',
    'created_at': 'Thời điểm tạo.', 'created_by': 'Người tạo (mã người dùng hoặc `system:*`).',
    'updated_at': 'Thời điểm sửa cuối (trigger `tg_touch`).', 'updated_by': 'Người sửa cuối.',
    'version': 'Khóa lạc quan; thành phần của ETag (`If-Match`).',
}

out = []
for i, (t, cols) in enumerate(tables, 1):
    out.append(f'### 3.{i}. `{t}`\n')
    if t in tcomment:
        out.append(tcomment[t].replace("''", "'") + '\n')
    out.append('| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |')
    out.append('|---|---|---|---|---|')
    for c, typ, nn, d in cols:
        note = ccomment.get((t, c), STD.get(c, '')).replace("''", "'").replace('|', '\\|')
        dd = ('`' + d.replace('|', '\\|') + '`') if d and d != 'cột sinh' else d
        out.append(f'| `{c}` | `{typ}` | {nn} | {dd} | {note} |')
    out.append('')
sys.stdout.write('\n'.join(out))
