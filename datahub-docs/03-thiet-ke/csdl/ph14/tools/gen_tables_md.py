#!/usr/bin/env python3
"""Sinh bảng mô tả cột (Markdown) từ ddl/ph14_*.sql cho chương 3 của D03-03-PH14.

Chạy từ datahub-docs:
  python3 03-thiet-ke/csdl/ph14/tools/gen_tables_md.py > /tmp/tables.md            # in ra màn hình
  python3 03-thiet-ke/csdl/ph14/tools/gen_tables_md.py --ghi <tệp D03-03-PH14.md>   # thay vùng giữa hai dấu gen
Đọc CREATE TABLE và COMMENT ON TABLE/COLUMN; cột không có COMMENT lấy ghi chú từ ràng buộc CHECK
(danh sách giá trị, mẫu, miền số) để bảng cột tự giải thích. Sau đó chạy them_dac_ta_bang.py.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ddl_doc as D  # noqa: E402

STD = {
    'id': 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).',
    'created_at': 'Thời điểm tạo.', 'created_by': 'Người tạo (mã người dùng hoặc `system:*`).',
    'updated_at': 'Thời điểm sửa cuối (trigger `tg_touch`).', 'updated_by': 'Người sửa cuối.',
    'version': 'Khóa lạc quan; thành phần của ETag (`If-Match`).',
}


def derived_note(col, cons):
    """Ghi chú rút từ CHECK: danh sách giá trị, mẫu regex, miền số."""
    notes = []
    for c in cons:
        if c['kind'] != 'CHECK':
            continue
        d = c['def']
        m = re.search(r'\b%s IN \(((?:\'[^\']*\'(?:, )?)+)\)' % re.escape(col), d)
        if m and not notes:
            vals = re.findall(r"'([^']*)'", m.group(1))
            notes.append('Giá trị: ' + ', '.join('`%s`' % v for v in vals) + '.')
            continue
        m = re.search(r'\(%s\)::text ~ \'([^\']+)\'' % re.escape(col), d) or re.search(r'\b%s ~ \'([^\']+)\'' % re.escape(col), d)
        if m and not notes:
            notes.append('Mẫu: `%s`.' % m.group(1))
            continue
        m = re.search(r'\b%s BETWEEN (\d+) AND (\d+)' % re.escape(col), d)
        if m and not notes:
            notes.append('Miền: %s đến %s.' % (m.group(1), m.group(2)))
    return ' '.join(notes)


def esc(s):
    return s.replace('|', '\\|')


def build():
    sql = D.read_sql()
    tables = D.parse_tables(sql)
    tcom, ccom = D.parse_comments(sql)
    out = []
    for i, (t, info) in enumerate(tables.items(), 2):  # 3.1 là danh sách bảng nên đặc tả từ 3.2
        out.append('### 3.%d. `%s`\n' % (i, t))
        if t in tcom:
            out.append(tcom[t] + '\n')
        out.append('| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |')
        out.append('|---|---|---|---|---|')
        for c in info['cols']:
            note = ccom.get((t, c['name']))
            if note is None:
                note = STD.get(c['name'])
            if note is None:
                note = derived_note(c['name'], info['cons'])
            if not note:
                n = c['name']
                if n.endswith('_by'):
                    note = 'Mã người dùng thực hiện (hoặc `system:*`).'
                elif n.endswith('_at') or n.endswith('_start') or n.endswith('_until'):
                    note = 'Thời điểm (T-TS, lưu UTC).'
                elif n == 'trace_id':
                    note = 'Trace ID theo W3C Trace Context, 32 ký tự hexa (T-TRACE).'
                elif n.endswith('_hash') or n.endswith('_sha256') or n == 'checksum':
                    note = 'Giá trị băm SHA-256 dạng hexa 64 ký tự.'
            if c['name'] == 'tenant_id':
                has_common = any('COMMON' in k['def'] for k in info['cons'] if k['name'].endswith('_tenant'))
                note = ('Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép.' if has_common
                        else 'Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép.')
            d = ('`' + c['default'] + '`') if c['default'] else ''
            out.append('| `%s` | `%s` | %s | %s | %s |' % (c['name'], esc(c['type']), 'x' if c['notnull'] else '', esc(d), esc(note or '')))
        out.append('')
    return '\n'.join(out)


if __name__ == '__main__':
    text = build()
    if len(sys.argv) > 2 and sys.argv[1] == '--ghi':
        f = sys.argv[2]
        s = open(f, encoding='utf-8').read()
        a, b = '<!-- gen:tables:start -->', '<!-- gen:tables:end -->'
        i, j = s.index(a) + len(a), s.index(b)
        open(f, 'w', encoding='utf-8').write(s[:i] + '\n' + text + '\n' + s[j:])
        print('đã ghi %d bảng vào %s' % (text.count('\n### 3.') + 1, f))
    else:
        sys.stdout.write(text)
