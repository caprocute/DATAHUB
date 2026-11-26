#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH01 từ chính các test case. Chạy: python3 gen_matrix.py > /tmp/m8.md
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

API_DOC = (P.ROOT / '03-thiet-ke/api/D03-04-PH01-api-ket-nap-httt.md').read_text(encoding='utf-8')

def known(prefix):
    if prefix == 'UC':
        return sorted(set(re.findall(r'^\| (UC-01-\d{2}) \|', P.UCD.read_text(encoding='utf-8'), re.M)))
    if prefix == 'API':
        return sorted(set(re.findall(r'^\| (API-01-\d{3}) \|', API_DOC, re.M)))
    if prefix == 'ERR':  # danh sách chuẩn ở D03-04-PH01 §6
        return sorted(set(re.findall(r'^\| (ERR-01-\d{3}) \|', API_DOC, re.M)))
    return sorted(set(re.findall(r'^\| (' + prefix + r'-01-\d{2,3}) \|', frs_text, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-01. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph01/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n')
O.append('| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |')
O.append('|---|---|---|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) or v['prio'] != 'M' else '**Không**'
    lg = ', '.join(v['lgc'][:3]) + ('…' if len(v['lgc']) > 3 else '') if v['lgc'] else 'mới'
    O.append(f"| {f} | {v['name'][:60]} | {v['prio']} | {lg} | {short(b['pos'])} | {short(b['neg'])} | {short(other, 6)} | {ok} |")
O.append('\n: Ma trận yêu cầu chức năng với test case của PH-01')

O.append('\n### 8.2. Chức năng hệ cũ → yêu cầu → test case\n')
O.append('Bốn chức năng hệ cũ do PH-01 chịu trách nhiệm (Application của APIM `LGC-APIM`, publisher và subscriber của Hub `LGC-HUB`) được truy tới FR mới, ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.\n')
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
O.append('\n: Truy vết chức năng hệ cũ tới yêu cầu và test case')

missing = {}
for pre, title in (('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('UC', 'Use case'), ('API', 'API'), ('UI', 'Màn hình'), ('EVT', 'Sự kiện')):
    ks = known(pre)
    O.append(f'\n### 8.{3 + ("BR","ERR","NFR","UC","API","UI","EVT").index(pre)}. {title} → test case\n')
    O.append(f'Bảng dưới liệt kê từng {title.lower()} của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.\n')
    O.append(f'| Mã | Test case |'); O.append('|---|---|')
    rows = []
    for k in ks:
        rows.append(f'| {k} | {short(by[k]["all"], 8)} |')
        if not by[k]['all']: missing.setdefault(pre, []).append(k)
    O += rows
    O.append(f'\n: Ma trận {title.lower()} với test case của PH-01')
print('\n'.join(O))
for k, v in missing.items():
    print(k, 'chưa có ca:', ' '.join(v), file=sys.stderr)
