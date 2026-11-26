#!/usr/bin/env python3
"""Cấp số TC-05-nnn cho ca `TC-05-###` (theo thứ tự xuất hiện) và thay `[[tc:khóa]]` bằng số.
Khóa ca nằm trong chú thích `<!--k:khóa-->` ở dòng tiêu đề ca (hoặc ô tên trong bảng hiệu năng).
Số đã cấp không đổi; chạy lại an toàn."""
import re, pathlib, sys
DOC = pathlib.Path(__file__).resolve().parents[2] / 'D05-02-PH05-test-case.md'
s = DOC.read_text(encoding='utf-8')
used = [int(x) for x in re.findall(r'TC-05-(\d{3})(?=[^<\n]*<!--k:)', s)]
nxt = max(used, default=0) + 1
def assign(m):
    global nxt
    v = f'TC-05-{nxt:03d}'; nxt += 1
    return v
s = re.sub(r'TC-05-###', assign, s)
keys = {}
for m in re.finditer(r'(TC-05-\d{3})[^\n]*?<!--k:([a-z0-9-]+)-->', s):
    if m.group(2) in keys: sys.exit(f'khóa trùng: {m.group(2)}')
    keys[m.group(2)] = m.group(1)
miss = sorted(set(re.findall(r'\[\[tc:([a-z0-9-]+)\]\]', s)) - set(keys))
if miss: sys.exit('khóa chưa có ca: ' + ', '.join(miss))
s = re.sub(r'\[\[tc:([a-z0-9-]+)\]\]', lambda m: keys[m.group(1)], s)
DOC.write_text(s, encoding='utf-8')
print(len(keys), 'ca; số lớn nhất', f'TC-05-{nxt-1:03d}')
