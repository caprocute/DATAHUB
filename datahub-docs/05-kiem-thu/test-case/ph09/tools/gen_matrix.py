#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH09 từ chính các test case. In ra stdout; thiếu phủ in ra stderr."""
import re, sys
from collections import defaultdict
import tc_parse as P

tcs = P.parse(); frs = P.fr_catalog()
frs_text = P.FRS.read_text(encoding='utf-8')
mh_text = (P.ROOT / '03-thiet-ke/uiux/D03-06-PH09-man-hinh-quyen-rieng-tu.md').read_text(encoding='utf-8')
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
    src = frs_text
    return sorted(set(re.findall(r'^\| (' + prefix + r'-09-\d{2,3}) \|', src, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-09. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph09/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n')
O.append('| FR | Tên | Mức | Dương | Âm | Đạt |')
O.append('|---|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) else '**Không**'
    O.append(f"| {f} | {v['name'][:44]} | {v['prio']} | {short(b['pos'], 9)} | {short(b['neg'], 9)} | {ok} |")
O.append('\n: Yêu cầu chức năng tới ca dương, ca âm')

O.append('\n### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case\n')
O.append('Hai mã chức năng hệ cũ được PH-09 phủ theo FRS mục 11.1: LGC-TOOL-012 (nâng cấp che dữ liệu nhạy cảm thành chính sách tập trung) và LGC-NGSP-003 (tra cứu BHXH giữ nguyên ở PH-14, PH-09 thêm kiểm soát mục đích). Chức năng cũ FR-09-001…011 của SRS repo xem ở mục 7.2.\n')
O.append('| LGC | FR của PH-09 | TC | UAT |')
O.append('|---|---|---|---|')
doc = P.DOC.read_text(encoding='utf-8')
uat = defaultdict(list)
for m in re.finditer(r'^\| (UAT-\d{2}) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)): uat[r].append(m.group(1))
LG = {'LGC-TOOL-012': ['FR-09-023', 'FR-09-024', 'FR-09-027', 'FR-09-028', 'FR-09-030', 'FR-09-031', 'FR-09-032', 'FR-09-036'],
      'LGC-NGSP-003': ['FR-09-014', 'FR-09-015', 'FR-09-016', 'FR-09-017', 'FR-09-018', 'FR-09-019', 'FR-09-020', 'FR-09-021', 'FR-09-022']}
for l, fl in LG.items():
    O.append(f"| {l} | {', '.join(x[-3:] for x in fl)} | {short([i for f in fl for i in by[f]['pos']] + by[l]['all'], 8)} | {', '.join(uat[l]) or '—'} |")
O.append('\n: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT')

missing = {}
sections = (('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('EVT', 'Sự kiện'), ('API', 'API'), ('UI', 'Màn hình'))
for i, (pre, title) in enumerate(sections):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    if pre == 'ERR':
        O.append('Mã `ERR-09-001…078` thuộc control plane, `ERR-09-101…113` thuộc data plane; lỗi `401`, `403` do thiếu quyền dùng ERR-00-401, ERR-00-403.\n')
    O.append(f'Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ {title.lower()} này.\n')
    O.append('| Mã | Test case |'); O.append('|---|---|')
    nocase = []; grp = []
    for k in ks:
        if not by[k]['all']:
            missing.setdefault(pre, []).append(k); nocase.append(k)
            if pre != 'API': O.append(f'| {k} | — |')
            continue
        grp.append((k, short(by[k]["all"], 10)))
    rows, i = [], 0
    while i < len(grp):
        j = i
        while j + 1 < len(grp) and grp[j + 1][1] == grp[i][1] and int(grp[j + 1][0].split('-')[-1]) == int(grp[j][0].split('-')[-1]) + 1: j += 1
        rows.append(f'| {grp[i][0]} | {grp[i][1]} |' if j == i else f'| {grp[i][0]}…{grp[j][0].split("-")[-1]} | {grp[i][1]} |')
        i = j + 1
    O.extend(rows)
    if pre == 'API' and nocase:
        O.append(f'\n: {title} tới test case (chỉ liệt kê API có ca)')
        O.append(f'\nAPI không có ca riêng ({len(nocase)}/{len(ks)}), thuộc nhóm đọc, liệt kê, tải hoặc sửa bản nháp được kiểm cùng API cùng tài nguyên: ' + ', '.join(x[-3:] for x in nocase) + '.')
        continue
    O.append(f'\n: {title} tới test case')
print('\n'.join(O))
for f, v in frs.items():
    if not (by[f]['pos'] and by[f]['neg']):
        print('FR thiếu', 'dương' if not by[f]['pos'] else '', 'âm' if not by[f]['neg'] else '', f, file=sys.stderr)
for k, v in missing.items():
    print(k, 'chưa có ca:', ' '.join(v), file=sys.stderr)
