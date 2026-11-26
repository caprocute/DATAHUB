#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH06 từ chính các test case. In ra stdout; thiếu phủ in ra stderr."""
import re, sys
from collections import defaultdict
import tc_parse as P

tcs = P.parse(); frs = P.fr_catalog()
frs_text = P.FRS.read_text(encoding='utf-8')
mh_text = (P.ROOT / '03-thiet-ke/uiux/D03-06-PH06-man-hinh-du-lieu-chu.md').read_text(encoding='utf-8')
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

def known(prefix):
    src = mh_text if prefix == 'UI' else frs_text
    return sorted(set(re.findall(r'^\| (' + prefix + r'-06-\d{2,3}) \|', src, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-06. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph06/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n')
O.append('| FR | Tên | Mức | Dương | Âm | Ca khác | Đạt |')
O.append('|---|---|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) else '**Không**'
    O.append(f"| {f} | {v['name'][:56]} | {v['prio']} | {short(b['pos'])} | {short(b['neg'])} | {short(other, 6)} | {ok} |")
O.append('\n: Yêu cầu chức năng tới ca dương, ca âm')

O.append('\n### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case\n')
O.append('Hệ cũ không có chức năng dữ liệu chủ; bốn mục `LGC` dưới do PH-14 và PH-07 làm chính, PH-06 chỉ dùng dữ liệu. Ca ở cột "TC" kiểm chỗ PH-06 nhận dữ liệu đó, không kiểm chức năng của hệ cũ (FRS mục 11.1).\n')
O.append('| LGC | FR của PH-06 | TC | UAT |')
O.append('|---|---|---|---|')
doc = P.DOC.read_text(encoding='utf-8')
uat = defaultdict(list)
for m in re.finditer(r'^\| (UAT-\d{2}) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)): uat[r].append(m.group(1))
LG = {'LGC-NGSP-003': ['FR-06-008', 'FR-06-045', 'FR-06-046'], 'LGC-NGSP-005': ['FR-06-007', 'FR-06-053', 'FR-06-054'],
      'LGC-DMDC-015': ['FR-06-015'], 'LGC-DMDC-019': ['FR-06-015']}
for l, fl in LG.items():
    O.append(f"| {l} | {', '.join(x[-3:] for x in fl)} | {short([i for f in fl for i in by[f]['pos']] + by[l]['all'], 8)} | {', '.join(uat[l]) or '—'} |")
O.append('\n: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT')

missing = {}
sections = (('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('EVT', 'Sự kiện'), ('API', 'API'), ('UI', 'Màn hình'))
for i, (pre, title) in enumerate(sections):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    if pre == 'ERR':
        O.append('Mã `ERR-06-101…114` là lỗi nền (job, đồng bộ), kiểm ở trạng thái job, nhật ký, cảnh báo thay cho mã HTTP.\n')
    O.append(f'Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ {title.lower()} này.\n')
    O.append('| Mã | Test case |'); O.append('|---|---|')
    for k in ks:
        O.append(f'| {k} | {short(by[k]["all"], 10)} |')
        if not by[k]['all']: missing.setdefault(pre, []).append(k)
    O.append(f'\n: {title} tới test case')
print('\n'.join(O))
for f, v in frs.items():
    if not (by[f]['pos'] and by[f]['neg']):
        print('FR thiếu', 'dương' if not by[f]['pos'] else '', 'âm' if not by[f]['neg'] else '', f, file=sys.stderr)
for k, v in missing.items():
    print(k, 'chưa có ca:', ' '.join(v), file=sys.stderr)
