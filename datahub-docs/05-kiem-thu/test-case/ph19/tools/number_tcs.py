#!/usr/bin/env python3
"""Cấp số TC-19-nnn cho ca `TC-19-###` trong dải của từng kịch bản (khung D02-03-PH19-00 §14:
TS-19-nn dùng 25×(nn−1)+1 … 25×nn) và thay `[[tc:khóa]]` bằng số.
Khóa ca nằm trong chú thích `<!--k:khóa-->` ở dòng tiêu đề ca (hoặc ô tên trong bảng hiệu năng).
Số đã cấp không đổi; chạy lại an toàn."""
import re, pathlib, sys
DOC = pathlib.Path(__file__).resolve().parents[2] / 'D05-02-PH19-test-case.md'
s = DOC.read_text(encoding='utf-8')
CASE = re.compile(r'^(#### |\| )TC-19-(\d{3}|###)( · | \| )(.*<!--k:[a-z0-9-]+-->.*)$', re.M)
TS = re.compile(r'^### (TS-19-(\d{2})) · ', re.M)
# vị trí bắt đầu từng kịch bản
marks = [(m.start(), int(m.group(2))) for m in TS.finditer(s)]
def ts_at(pos):
    cur = None
    for p, n in marks:
        if p > pos: break
        cur = n
    if cur is None: sys.exit(f'ca nằm ngoài kịch bản ở vị trí {pos}')
    return cur
used = {}
for m in CASE.finditer(s):
    if m.group(2) != '###':
        n = ts_at(m.start()); used.setdefault(n, set()).add(int(m.group(2)))
nxt = {}
def assign(m):
    if m.group(2) != '###': return m.group(0)
    n = ts_at(m.start()); lo, hi = 25 * (n - 1) + 1, 25 * n
    k = nxt.get(n, max(used.get(n, {lo - 1}) | {lo - 1}) + 1)
    if k > hi: sys.exit(f'TS-19-{n:02d} vượt dải {lo}…{hi}')
    nxt[n] = k + 1
    return f'{m.group(1)}TC-19-{k:03d}{m.group(3)}{m.group(4)}'
s = CASE.sub(assign, s)
keys = {}
for m in re.finditer(r'(TC-19-\d{3})[^\n]*?<!--k:([a-z0-9-]+)-->', s):
    if m.group(2) in keys: sys.exit(f'khóa trùng: {m.group(2)}')
    keys[m.group(2)] = m.group(1)
miss = sorted(set(re.findall(r'\[\[tc:([a-z0-9-]+)\]\]', s)) - set(keys))
if miss: sys.exit('khóa chưa có ca: ' + ', '.join(miss))
s = re.sub(r'\[\[tc:([a-z0-9-]+)\]\]', lambda m: keys[m.group(1)], s)
# kiểm số nằm đúng dải (tính lại vị trí kịch bản sau khi thay khóa)
marks = [(m.start(), int(m.group(2))) for m in TS.finditer(s)]
for m in CASE.finditer(s):
    n = ts_at(m.start()); v = int(m.group(2))
    if not 25 * (n - 1) < v <= 25 * n: sys.exit(f'TC-19-{v:03d} không thuộc dải của TS-19-{n:02d}')
DOC.write_text(s, encoding='utf-8')
print(len(keys), 'ca')
