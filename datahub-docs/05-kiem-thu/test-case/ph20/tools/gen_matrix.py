#!/usr/bin/env python3
"""Sinh mục 8 (ma trận truy vết) của D05-02-PH20 từ chính các test case. In ra stdout; thiếu phủ in ra stderr."""
import re, sys
from collections import defaultdict
import tc_parse as P

tcs = P.parse(); frs = P.fr_catalog()
frs_text = P.FRS.read_text(encoding='utf-8')
uc_text = P.UC.read_text(encoding='utf-8')
doc = P.DOC.read_text(encoding='utf-8')
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
    src = uc_text if prefix == 'UC' else frs_text
    return sorted(set(re.findall(r'^\| (' + prefix + r'-20-\d{2,3}) \|', src, re.M)))

O = []
O.append('### 8.1. Yêu cầu chức năng → test case\n')
O.append('Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-20. FR mức M phải có ít nhất một ca ở mỗi cột; FR mức S chỉ cần một ca (dấu "—" ở cột Đạt nghĩa là chưa có ca âm, không bắt buộc).\n')
O.append('| FR | Mức | Dương | Âm | Đạt |')
O.append('|---|---|---|---|---|')
for f, v in frs.items():
    b = by[f]
    ok = 'Có' if (b['pos'] and b['neg']) else ('**Không**' if v['prio'] == 'M' else '—')
    O.append(f"| {f} | {v['prio']} | {short(b['pos'])} | {short(b['neg'])} | {ok} |")
O.append('\n: Yêu cầu chức năng tới ca dương, ca âm')

O.append('\n### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case\n')
O.append('PH-20 là năng lực mới (hệ cũ không có khái niệm tenant), không có `LGC` do PH-20 làm chính. Hai mục dưới là chức năng hệ cũ mà PH-20 phủ hoặc tham gia gián tiếp (FRS mục 2.6, 11.1). Ca ở cột "TC" kiểm phần PH-20 bổ sung, không kiểm chức năng của hệ cũ.\n')
O.append('| LGC | FR của PH-20 | TC | UAT |')
O.append('|---|---|---|---|')
uat = defaultdict(list)
for m in re.finditer(r'^\| (UAT-\d{2}) \| [^|]+ \| ([^|]+) \| [^|]+ \| ([^|]+) \|', doc, re.M):
    for r in P.refs(m.group(2)): uat[r].append(m.group(1))
LG = {'LGC-IAM-002': ['FR-20-018', 'FR-20-053', 'FR-20-054', 'FR-20-055', 'FR-20-008'],
      'LGC-BUS-031': ['FR-20-001', 'FR-20-008', 'FR-20-019', 'FR-20-020']}
for l, fl in LG.items():
    O.append(f"| {l} | {', '.join(x[-3:] for x in fl)} | {short([i for f in fl for i in by[f]['pos']] + by[l]['all'], 10)} | {', '.join(uat[l]) or '—'} |")
O.append('\n: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT')

missing = {}
sections = (('UC', 'Use case'), ('UI', 'Màn hình'), ('API', 'API'), ('ERR', 'Mã lỗi'), ('EVT', 'Sự kiện'),
            ('BR', 'Quy tắc nghiệp vụ'), ('NFR', 'Yêu cầu phi chức năng'))
for i, (pre, title) in enumerate(sections):
    ks = known(pre)
    O.append(f'\n### 8.{3 + i}. {title} → test case\n')
    if pre == 'ERR':
        O.append('Mã `ERR-20-106…113`, `116`, `117` là lỗi chạy nền không có mã HTTP (FRS mục 9.1); ca kiểm ở sổ bước, trạng thái lần chạy, cảnh báo và thông báo thay cho mã HTTP.\n')
    if pre == 'API':
        O.append('Nhóm API và ca rò rỉ chéo tenant (SEC-87) xem thêm TS-20-37.\n')
    O.append(f'Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ {title.lower()} này.\n')
    O.append('| Mã | Test case |'); O.append('|---|---|')
    for k in ks:
        O.append(f'| {k} | {short(by[k]["all"], 10)} |')
        if not by[k]['all']: missing.setdefault(pre, []).append(k)
    O.append(f'\n: {title} tới test case')

# Quyền PERM-20 và tham số 20.*
alltext = {t['id']: ' '.join([t['trace'], t['data'], t['steps'], t['expect']]) for t in tcs}
perms = sorted(set(re.findall(r'PERM-20-[a-z-]+', frs_text)))
O.append(f'\n### 8.{3 + len(sections)}. Quyền PERM-20 → test case\n')
O.append('Cột "Test case" liệt kê ca có nhắc quyền trong truy vết, dữ liệu hoặc kết quả; ca phân quyền âm nằm ở TS-20-38.\n')
O.append('| Quyền | Test case |'); O.append('|---|---|')
for p in perms:
    ids = [i for i, tx in alltext.items() if re.search(re.escape(p) + r'(?![a-z-])', tx)]
    O.append(f'| `{p}` | {short(ids, 10)} |')
    if not ids: missing.setdefault('PERM', []).append(p)
O.append('\n: Quyền PERM-20 tới test case')
params = sorted(set(re.findall(r'^\| `(20\.[a-z.-]+)` \|', frs_text, re.M)))
O.append(f'\n### 8.{4 + len(sections)}. Tham số 20.* → test case\n')
O.append('Cột "Test case" liệt kê ca có dùng hoặc đổi tham số.\n')
O.append('| Tham số | Test case |'); O.append('|---|---|')
for p in params:
    ids = [i for i, tx in alltext.items() if p in tx]
    O.append(f'| `{p}` | {short(ids, 10)} |')
    if not ids: missing.setdefault('PARAM', []).append(p)
O.append('\n: Tham số 20.* tới test case')
print('\n'.join(O))
for f, v in frs.items():
    if v['prio'] == 'M' and not (by[f]['pos'] and by[f]['neg']):
        print('FR thiếu', 'dương' if not by[f]['pos'] else '', 'âm' if not by[f]['neg'] else '', f, file=sys.stderr)
    elif not by[f]['all']:
        print('FR chưa có ca', f, file=sys.stderr)
for k, v in missing.items():
    print(k, 'chưa có ca:', ' '.join(v), file=sys.stderr)
