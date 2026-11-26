#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH15 từ chính các test case. Chạy: python3 gen_matrix.py > /tmp/m8.md
In ra stderr các BR, ERR, NFR chưa có ca kiểm thử."""
import re, sys
from collections import defaultdict
import tc_parse as P

tcs = P.parse(); frs = P.fr_catalog()
frs_text = P.FRS.read_text(encoding='utf-8')
by = defaultdict(lambda: defaultdict(list))
for t in tcs:
    for r in t['refs']:
        by[r]['all'].append(t['id'])
        if 'Dương' in t['type']: by[r]['pos'].append(t['id'])
        if 'Âm' in t['type']: by[r]['neg'].append(t['id'])

def short(ids, n=12):
    ids = sorted(set(ids))
    s = ', '.join(i[-3:] for i in ids[:n])
    return (s + (f' (+{len(ids)-n})' if len(ids) > n else '')) if ids else '—'

UC_DOC = (P.ROOT / '02-yeu-cau/use-case/D02-04-PH15-use-case-cong-nha-phat-trien.md').read_text(encoding='utf-8')

def known(prefix):
    if prefix == 'UC':
        return sorted(set(re.findall(r'^\| (UC-15-\d{2}) \|', UC_DOC, re.M)))
    ks = set(re.findall(r'^\| (' + prefix + r'-15-\d{2,3}) \|', frs_text, re.M))
    if prefix == 'API':
        ks |= {f'API-15-{n}' for n in range(138, 143)}
    return sorted(ks)

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-15. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph15/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n')
O.append('| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |')
O.append('|---|---|---|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) or v['prio'] != 'M' else '**Không**'
    lg = ', '.join(v['lgc'][:3]) + ('…' if len(v['lgc']) > 3 else '') if v['lgc'] else 'mới'
    O.append(f"| {f} | {v['name'][:42]} | {v['prio']} | {lg} | {short(b['pos'])} | {short(b['neg'])} | {short(other, 6)} | {ok} |")
O.append('\n: Yêu cầu chức năng và test case')

O.append('\n### 8.2. Chức năng hệ cũ → yêu cầu → test case\n')
O.append('Mỗi chức năng portal hệ cũ (`LGC-APIM-006, 007, 017, 022`) và cấp credential tự phục vụ (`LGC-IAM-006`) được truy tới FR mới, ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.\n')
O.append('| LGC | FR | TC tự động | UAT |')
O.append('|---|---|---|---|')
uat = defaultdict(list)
doc = P.DOC.read_text(encoding='utf-8')
for m in re.finditer(r'^\| (UAT-\d{2}) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)):
        uat[r].append(m.group(1))
lgcs = sorted(set(l for v in frs.values() for l in v['lgc']) | set(uat))
for l in lgcs:
    fr = [f for f, v in frs.items() if l in v['lgc']]
    O.append(f"| {l} | {', '.join(x[-3:] for x in fr) or '—'} | {short(by[l]['all'] + [i for f in fr if len(frs[f]['lgc']) < 5 for i in by[f]['pos']], 8)} | {', '.join(uat[l]) or '—'} |")
O.append('\n: Chức năng hệ cũ, yêu cầu và test case')

missing = {}
titles = (('UC', 'Use case'), ('UI', 'Màn hình'), ('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('EVT', 'Sự kiện'), ('API', 'API'))
for i, (pre, title) in enumerate(titles):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    O.append(f'Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.\n')
    O.append('| Mã | Test case |'); O.append('|---|---|')
    for k in ks:
        O.append(f'| {k} | {short(by[k]["all"], 10)} |')
        if not by[k]['all']: missing.setdefault(pre, []).append(k)
    O.append(f'\n: {title} và test case')
print('\n'.join(O))
for k, v in missing.items():
    print(k, 'chưa có ca:', ' '.join(v), file=sys.stderr)
