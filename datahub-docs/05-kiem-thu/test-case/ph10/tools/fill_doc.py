#!/usr/bin/env python3
"""Ghi các phần sinh tự động vào D05-02-PH10: bảng kịch bản (mục 3.1), số kịch bản, số ca, ma trận (mục 8).
Chạy sau number_tcs.py. Mục 8 lấy từ gen_matrix.py; BR, ERR, NFR chưa có ca in ra stderr."""
import re, subprocess, sys, pathlib
from collections import Counter
import tc_parse as P

here = pathlib.Path(__file__).parent
tcs = P.parse(); tsn = P.ts_names()
doc = P.DOC.read_text(encoding='utf-8')
cnt = Counter(t['ts'] for t in tcs); p1 = sum(1 for t in tcs if t['prio'] == 'P1')
ucs = {}
for m in re.finditer(r'^### (TS-10-\d{2}) · .*?\n\n\*\*Mục tiêu\.\*\* (.*?)\n\n\*\*Phủ\.\*\* (.*?)\n', doc, re.M | re.S):
    uc = re.findall(r'UC-10-\d{2}(?:\s*,\s*\d{2}(?!\d))*', m.group(3))
    ucs[m.group(1)] = (m.group(2), ', '.join(uc) or '—')
rows = ['| Kịch bản | Tên | Mục tiêu | UC | Số ca |', '|---|---|---|---|---|']
for ts, name in tsn.items():
    goal, uc = ucs.get(ts, ('', '—'))
    goal = goal.split('. ')[0].rstrip('.')
    rows.append(f'| {ts} | {name} | {goal} | {uc} | {cnt[ts]} |')
rows.append(f'| **Tổng** | | | | **{len(tcs)}** ({p1} ca P1) |')
def put(tag, body, s):
    return re.sub(rf'(<!--gen:{tag}-->).*?(<!--/gen-->)', lambda m: m.group(1) + body + m.group(2), s, flags=re.S)
doc = put('ts-table', '\n' + '\n'.join(rows) + '\n', doc)
doc = put('so-ts', str(len(tsn)), doc)
doc = put('so-tc', f'{len(tcs)} (TC-10-001…{len(tcs):03d}; {p1} ca P1)', doc)
m8 = subprocess.run([sys.executable, str(here / 'gen_matrix.py')], capture_output=True, text=True, cwd=here)
sys.stderr.write(m8.stderr)
doc = put('matrix', '\n' + m8.stdout.rstrip() + '\n', doc)
P.DOC.write_text(doc, encoding='utf-8')
print(len(tsn), 'kịch bản,', len(tcs), 'ca,', p1, 'P1')
