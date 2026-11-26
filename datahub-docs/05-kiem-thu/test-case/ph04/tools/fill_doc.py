#!/usr/bin/env python3
"""Ghi các phần sinh tự động vào D05-02-PH04: số kịch bản, số ca, cột "Số ca" của bảng kịch bản (mục 3.1),
bảng danh sách test case (mục 3.3) và ma trận truy vết (mục 8).
Chạy sau number_tcs.py. Mục 8 lấy từ gen_matrix.py; BR, ERR, NFR chưa có ca in ra stderr."""
import re, subprocess, sys, pathlib
from collections import Counter
import tc_parse as P

here = pathlib.Path(__file__).parent
tcs = P.parse(); tsn = P.ts_names()
doc = P.DOC.read_text(encoding='utf-8')
cnt = Counter(t['ts'] for t in tcs); p1 = sum(1 for t in tcs if t['prio'] == 'P1')


def put(tag, body, s):
    return re.sub(rf'(<!--gen:{tag}-->).*?(<!--/gen-->)', lambda m: m.group(1) + body + m.group(2), s, flags=re.S)


# Bảng kịch bản: giữ cột FR chính, UC đang có; tính lại cột Số ca
cur = re.search(r'<!--gen:ts-table-->(.*?)<!--/gen-->', doc, re.S).group(1)
keep = {m.group(1): (m.group(3).strip(), m.group(4).strip())
        for m in re.finditer(r'^\| (TS-04-\d{2}) \| ([^|]*) \| ([^|]*) \| ([^|]*) \|', cur, re.M)}
rows = ['| Kịch bản | Tên | FR chính | UC | Số ca |', '|---|---|---|---|---|']
for ts, name in tsn.items():
    fr, uc = keep.get(ts, ('—', '—'))
    rows.append(f'| {ts} | {name} | {fr} | {uc} | {cnt[ts]} |')
rows.append(f'| **Tổng** | | | | **{len(tcs)}** ({p1} ca P1) |')
doc = put('ts-table', '\n' + '\n'.join(rows) + '\n\n: Danh sách kịch bản kiểm thử\n', doc)

# Bảng danh sách test case
L = ['| Ca | Tên | Kịch bản | Loại | Ưu tiên | Tự động |', '|---|---|---|---|---|---|']
for t in sorted(tcs, key=lambda x: x['id']):
    L.append(f"| {t['id']} | {t['name']} | {t['ts'][-2:]} | {t['type']} | {t['prio']} | {t['auto']} |")
doc = put('tc-table', '\n' + '\n'.join(L) + '\n\n: Danh sách test case\n', doc)

doc = put('so-ts', str(len(tsn)), doc)
doc = put('so-tc', f'{len(tcs)} test case (TC-04-001…{max(t["id"] for t in tcs)[-3:]}; {p1} ca P1)', doc)
m8 = subprocess.run([sys.executable, str(here / 'gen_matrix.py')], capture_output=True, text=True, cwd=here)
sys.stderr.write(m8.stderr)
doc = put('matrix', '\n' + m8.stdout.rstrip() + '\n', doc)
P.DOC.write_text(doc, encoding='utf-8')
print(len(tsn), 'kịch bản,', len(tcs), 'ca,', p1, 'P1')
