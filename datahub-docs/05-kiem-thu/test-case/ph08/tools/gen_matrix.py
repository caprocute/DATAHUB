#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH08 từ chính các test case. In ra stdout; thiếu phủ in ra stderr."""
import re, sys
from collections import defaultdict
import tc_parse as P

tcs = P.parse(); frs = P.fr_catalog()
frs_text = P.FRS.read_text(encoding='utf-8')
mh_text = frs_text  # UI-08 lấy từ FRS mục 10.1 (tập D03-06-PH08 viết song song)
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
    return sorted(set(re.findall(r'^\| (' + prefix + r'-08-\d{2,3}) \|', src, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-08. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph08/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n')
O.append('| FR | Tên | Mức | Dương | Âm | Đạt |')
O.append('|---|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) else '**Không**'
    O.append(f"| {f} | {v['name'][:44]} | {v['prio']} | {short(b['pos'])} | {short(b['neg'])} | {ok} |")
O.append('\n: Yêu cầu chức năng tới ca dương, ca âm')

O.append('\n### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case\n')
O.append('Hệ cũ không có chức năng chất lượng dữ liệu; sáu mục `LGC` dưới do PH-07, PH-13, PH-14 làm chính, PH-08 chỉ đo chất lượng sau nhập, thống kê lỗi hoặc dùng làm nguồn đối chiếu. Ca ở cột "TC" kiểm phần PH-08 bổ sung, không kiểm chức năng của hệ cũ (FRS mục 11.1).\n')
O.append('| LGC | FR của PH-08 | TC | UAT |')
O.append('|---|---|---|---|')
doc = P.DOC.read_text(encoding='utf-8')
uat = defaultdict(list)
for m in re.finditer(r'^\| (UAT-\d{2}) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)): uat[r].append(m.group(1))
LG = {'LGC-DMDC-006': ['FR-08-003', 'FR-08-025', 'FR-08-027'], 'LGC-DMDC-007': ['FR-08-003', 'FR-08-025', 'FR-08-027'],
      'LGC-DMDC-008': ['FR-08-003', 'FR-08-025', 'FR-08-027'], 'LGC-BUS-027': ['FR-08-034'],
      'LGC-NGSP-003': ['FR-08-013'], 'LGC-NGSP-005': ['FR-08-013', 'FR-08-015']}
for l, fl in LG.items():
    O.append(f"| {l} | {', '.join(x[-3:] for x in fl)} | {short([i for f in fl for i in by[f]['pos']] + by[l]['all'], 8)} | {', '.join(uat[l]) or '—'} |")
O.append('\n: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT')

missing = {}
sections = (('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('EVT', 'Sự kiện'), ('API', 'API'), ('UI', 'Màn hình'))
for i, (pre, title) in enumerate(sections):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    if pre == 'ERR':
        O.append('Mã `ERR-08-106…119` là lỗi vận hành của đo lô, báo cáo, sự kiện, không có mã HTTP; ca kiểm ở trạng thái lần đo, cờ ảnh chụp, nhật ký, cảnh báo thay cho mã HTTP.\n')
    O.append(f'Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ {title.lower()} này.\n')
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
