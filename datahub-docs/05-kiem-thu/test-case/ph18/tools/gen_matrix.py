#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH18 từ chính các test case. In ra stdout; thiếu phủ in ra stderr."""
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

def known(prefix):
    src = frs_text
    return sorted(set(re.findall(r'^\| (' + prefix + r'-18-\d{2,3}) \|', src, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-18. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph18/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n')
O.append('| FR | Tên | Mức | Dương | Âm | Đạt |')
O.append('|---|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    ok = 'Có' if (b['pos'] and b['neg']) else '**Không**'
    O.append(f"| {f} | {v['name'][:44]} | {v['prio']} | {short(b['pos'], 9)} | {short(b['neg'], 9)} | {ok} |")
O.append('\n: Yêu cầu chức năng tới ca dương, ca âm')

O.append('\n### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case\n')
O.append('Bảng lấy các mã hệ cũ liên quan PH-18 ở FRS mục 11.1 (cột FR) và nối với ca dương của các FR đó cùng các ca ghi trực tiếp mã LGC; mã ghi "Gián tiếp" là đối tượng di trú, nối với khung di trú FR-18-059…068. Chức năng cũ của SRS repo xem ở mục 7.2.\n')
O.append('| LGC | FR của PH-18 | TC | UAT |')
O.append('|---|---|---|---|')
doc = P.DOC.read_text(encoding='utf-8')
uat = defaultdict(list)
for m in re.finditer(r'^\| (UAT-18-\d{2}) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)): uat[r].append(m.group(1))
LG = {}
sec = frs_text[frs_text.index('### 11.1.'):frs_text.index('### 11.2.')]
for m in re.finditer(r'^\| (LGC-[A-Z]+-\d{3}) \| [^|]+ \| ([^|]+) \|', sec, re.M):
    nums = re.findall(r'\d{3}', m.group(2)) or [f'{x:03d}' for x in range(59, 69)]
    LG[m.group(1)] = ([m.group(1)], [f'FR-18-{n}' for n in nums])
for label, (ls, fl) in LG.items():
    ids = [i for f in fl for i in by[f]['pos']] + [i for l in ls for i in by[l]['all']]
    O.append(f"| {label} | {', '.join(x[-3:] for x in fl)} | {short(ids, 8)} | {', '.join(sorted({u for l in ls for u in uat[l]})) or '—'} |")
O.append('\n: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT')

missing = {}
sections = (('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'), ('EVT', 'Sự kiện'), ('API', 'API'), ('UI', 'Màn hình'))
for i, (pre, title) in enumerate(sections):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    if pre == 'ERR':
        O.append('Mã `ERR-18-001…072` là lỗi control plane trả cho người dùng hoặc phân hệ gọi, `ERR-18-101…124` là lỗi của worker, tiếp nhận DLQ và gửi thông báo ghi vào trạng thái đối tượng; lỗi `401`, `403`, `428` dùng ERR-00-401, ERR-00-403, ERR-00-428.\n')
    O.append(f'Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ {title.lower()} này.\n')
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
