#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH16 từ chính các test case. In ra stdout; thiếu phủ in ra stderr."""
import re, sys
from collections import defaultdict
import tc_parse as P

tcs = P.parse(); frs = P.fr_catalog()
frs_text = P.FRS.read_text(encoding='utf-8')
mh_text = frs_text  # UI-16 lấy từ FRS mục 10.1 (tập D03-06-PH16 viết song song)
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
    return sorted(set(re.findall(r'^\| (' + prefix + r'-16-\d{2,3}) \|', src, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-16. FR mức M phải có ít nhất một ca ở mỗi cột; FR mức S, C chỉ cần một ca (dấu "—" ở cột Đạt nghĩa là chưa có ca âm, không bắt buộc).\n')
O.append('| FR | Mức | Dương | Âm | Đạt |')
O.append('|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) else ('**Không**' if v['prio'] == 'M' else '—')
    O.append(f"| {f} | {v['prio']} | {short(b['pos'])} | {short(b['neg'])} | {ok} |")
O.append('\n: Yêu cầu chức năng tới ca dương, ca âm')

O.append('\n### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case\n')
O.append('PH-16 là năng lực mới, không có `LGC` do PH-16 làm chính; chín mục dưới là bảng thống kê rời của hệ cũ mà PH-16 nâng thành chỉ tiêu định kỳ (FRS mục 11.1). Ca ở cột "TC" kiểm phần PH-16 bổ sung (chỉ tiêu, báo cáo, sổ kiến trúc), không kiểm chức năng của hệ cũ.\n')
O.append('| LGC | FR của PH-16 | TC | UAT |')
O.append('|---|---|---|---|')
doc = P.DOC.read_text(encoding='utf-8')
uat = defaultdict(list)
for m in re.finditer(r'^\| (UAT-\d{2}) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)): uat[r].append(m.group(1))
LG = {'LGC-APIM-026': ['FR-16-010', 'FR-16-011', 'FR-16-038'], 'LGC-PAY-013': ['FR-16-010', 'FR-16-038'],
      'LGC-PAY-020': ['FR-16-010', 'FR-16-038'], 'LGC-HUB-001': ['FR-16-010', 'FR-16-044'],
      'LGC-HUB-002': ['FR-16-010', 'FR-16-044'], 'LGC-HUB-003': ['FR-16-010', 'FR-16-044'],
      'LGC-HUB-004': ['FR-16-010', 'FR-16-044'], 'LGC-BUS-027': ['FR-16-011', 'FR-16-038'],
      'LGC-NGSP-004': ['FR-16-051', 'FR-16-053']}
for l, fl in LG.items():
    O.append(f"| {l} | {', '.join(x[-3:] for x in fl)} | {short([i for f in fl for i in by[f]['pos']] + by[l]['all'], 8)} | {', '.join(uat[l]) or '—'} |")
O.append('\n: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT')

missing = {}
sections = (('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('EVT', 'Sự kiện'), ('API', 'API'), ('UI', 'Màn hình'))
for i, (pre, title) in enumerate(sections):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    if pre == 'ERR':
        O.append('Mã `ERR-16-105…125` là lỗi vận hành (thu thập, tính toán, gửi, dọn dữ liệu), không có mã HTTP; ca kiểm ở trạng thái nguồn, cờ lần tổng hợp, nhật ký tiếp nhận, thông báo PH-13 thay cho mã HTTP.\n')
    O.append(f'Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ {title.lower()} này.\n')
    O.append('| Mã | Test case |'); O.append('|---|---|')
    for k in ks:
        O.append(f'| {k} | {short(by[k]["all"], 10)} |')
        if not by[k]['all']: missing.setdefault(pre, []).append(k)
    O.append(f'\n: {title} tới test case')
print('\n'.join(O))
for f, v in frs.items():
    if frs[f]['prio'] == 'M' and not (by[f]['pos'] and by[f]['neg']):
        print('FR thiếu', 'dương' if not by[f]['pos'] else '', 'âm' if not by[f]['neg'] else '', f, file=sys.stderr)
for k, v in missing.items():
    print(k, 'chưa có ca:', ' '.join(v), file=sys.stderr)
