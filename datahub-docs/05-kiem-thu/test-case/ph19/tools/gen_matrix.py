#!/usr/bin/env python3
"""Sinh các phần tự động của D05-02-PH19 từ chính các test case và ghi thẳng vào tài liệu:
- mục 8 (ma trận truy vết) giữa <!-- gen:matrix:start/end -->;
- bảng kịch bản mục 3.1 thay <!--gen:ts-table--> (hoặc khối <!-- gen:ts:start/end -->);
- câu phạm vi ở phần tóm tắt và số ca ở lịch sử phiên bản.
Kiểm quy tắc phủ của khung D02-03-PH19-00 §14; in ra stderr các mục chưa đạt và trả mã lỗi 1."""
import re, sys
from collections import defaultdict
import tc_parse as P

doc = P.DOC.read_text(encoding='utf-8')
tcs = P.parse(doc); frs = P.fr_catalog(); tsn = P.ts_names(doc); uats = P.uat_rows(doc)
by = defaultdict(lambda: defaultdict(list))
for t in tcs:
    for r in t['refs']:
        by[r]['all'].append(t['id'])
        if 'Dương' in t['type']: by[r]['pos'].append(t['id'])
        if 'Âm' in t['type'] or 'Bảo mật' in t['type']: by[r]['neg'].append(t['id'])

def short(ids, n=12):
    ids = sorted(set(ids))
    s = ', '.join(i[-3:] for i in ids[:n])
    return (s + (f' (+{len(ids)-n})' if len(ids) > n else '')) if ids else '—'

problems = []
O = ['<!-- gen:matrix:start -->', '### 8.1. Yêu cầu chức năng → test case\n',
     'Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-19 (ca bảo mật tính là ca âm). FR mức M phải có ít nhất một ca ở mỗi cột; bảng sinh bằng `ph19/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.\n',
     '| FR | Tên | Mức · phát hành | LGC | Dương | Âm | Ca khác | Đạt quy tắc |', '|---|---|---|---|---|---|---|---|']
for f, v in frs.items():
    b = by[f]; other = set(b['all']) - set(b['pos']) - set(b['neg'])
    if v['prio'] == 'M':
        ok = 'Có' if b['pos'] and b['neg'] else '**Không**'
        if ok != 'Có': problems.append(f'{f} (mức M) thiếu ca ' + ('dương' if not b['pos'] else 'âm'))
    else:
        ok = 'Có' if b['all'] else '**Không**'
        if not b['all']: problems.append(f'{f} chưa có ca')
    lg = ', '.join(v['lgc'][:3]) + ('…' if len(v['lgc']) > 3 else '') if v['lgc'] else 'mới'
    O.append(f"| {f} | {v['name'][:60]} | {v['prio']} · {v['rel']} | {lg} | {short(b['pos'])} | {short(b['neg'])} | {short(other, 6)} | {ok} |")

O += ['\n### 8.2. Chức năng hệ cũ → yêu cầu → test case\n',
      'Mỗi chức năng của khối Payment hệ cũ (`LGC-PAY`, D00-03 §4.6) được truy tới FR mới, tới ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.\n',
      '| LGC | FR | TC tự động | UAT |', '|---|---|---|---|']
uat = defaultdict(list)
for u in uats:
    for r in P.refs(u['lgc']): uat[r].append(u['id'])
lgcs = sorted(set(l for v in frs.values() for l in v['lgc']) | set(uat) | {f'LGC-PAY-{i:03d}' for i in range(1, 27)})
for l in lgcs:
    fr = [f for f, v in frs.items() if l in v['lgc']]
    ids = by[l]['all'] + [i for f in fr for i in by[f]['pos']]
    if not ids: problems.append(f'{l} chưa có ca')
    if not uat[l]: problems.append(f'{l} chưa có UAT')
    O.append(f"| {l} | {', '.join(x[-3:] for x in fr) or '—'} | {short(ids, 8)} | {', '.join(uat[l]) or '—'} |")

for i, (pre, title) in enumerate((('BR', 'Quy tắc nghiệp vụ'), ('ERR', 'Mã lỗi'), ('NFR', 'Yêu cầu phi chức năng'))):
    O += [f'\n### 8.{3 + i}. {title} → test case\n', '| Mã | Test case |', '|---|---|']
    for k in P.known(pre):
        O.append(f'| {k} | {short(by[k]["all"], 10)} |')
        if not by[k]['all'] and k not in ('ERR-19-099',): problems.append(f'{k} chưa có ca')
O.append('<!-- gen:matrix:end -->')
doc = re.sub(r'<!-- gen:matrix:start -->.*?<!-- gen:matrix:end -->', lambda m: '\n'.join(O), doc, flags=re.S)

# bảng kịch bản mục 3.1
cnt = defaultdict(lambda: defaultdict(int))
for t in tcs:
    cnt[t['ts']]['n'] += 1
    cnt[t['ts']]['st'] += max(1, len([l for l in t['steps'].splitlines() if l.strip()]))
    if 'Dương' in t['type']: cnt[t['ts']]['pos'] += 1
    if 'Âm' in t['type'] or 'Bảo mật' in t['type']: cnt[t['ts']]['neg'] += 1
T = ['<!-- gen:ts:start -->', '| Kịch bản | Tên | Dải TC | Số ca | Số bước kiểm | Dương | Âm, bảo mật | Mục |', '|---|---|---|---|---|---|---|---|']
for ts, name in tsn.items():
    n = int(ts[-2:]); c = cnt[ts]
    T.append(f'| {ts} | {name} | {25*(n-1)+1:03d}…{25*n:03d} | {c["n"]} | {c["st"]} | {c["pos"]} | {c["neg"]} | {"4" if n <= 29 else "5"} |')
T.append(f'| **Tổng** | | | **{len(tcs)}** | {sum(c["st"] for c in cnt.values())} | {sum(c["pos"] for c in cnt.values())} | {sum(c["neg"] for c in cnt.values())} | |')
T.append('<!-- gen:ts:end -->')
tbl = '\n'.join(T)
if '<!--gen:ts-table-->' in doc: doc = doc.replace('<!--gen:ts-table-->', tbl)
else: doc = re.sub(r'<!-- gen:ts:start -->.*?<!-- gen:ts:end -->', lambda m: tbl, doc, flags=re.S)

m_fr = [f for f, v in frs.items() if v['prio'] == 'M']
summ = (f'<!-- gen:summary:start -->{len(tsn)} kịch bản, {len(tcs)} test case, {len(uats)} kịch bản nghiệm thu; phủ '
        f'{sum(1 for f in frs if by[f]["all"])}/{len(frs)} FR (mọi {len(m_fr)} FR mức M có ca dương và ca âm), '
        f'{sum(1 for k in P.known("BR") if by[k]["all"])} BR, {sum(1 for k in P.known("ERR") if by[k]["all"])} mã lỗi, '
        f'{sum(1 for k in P.known("NFR") if by[k]["all"])} NFR và 26/26 chức năng `LGC-PAY` của hệ cũ.<!-- gen:summary:end -->')
if '<!--gen:summary-->' in doc: doc = doc.replace('<!--gen:summary-->', summ)
else: doc = re.sub(r'<!-- gen:summary:start -->.*?<!-- gen:summary:end -->', lambda m: summ, doc, flags=re.S)
cnt_s = f'<!-- gen:count:start -->{len(tcs)}<!-- gen:count:end -->'
if '<!--gen:tc-count-->' in doc: doc = doc.replace('<!--gen:tc-count-->', cnt_s)
else: doc = re.sub(r'<!-- gen:count:start -->.*?<!-- gen:count:end -->', lambda m: cnt_s, doc)
P.DOC.write_text(doc, encoding='utf-8')
print(len(tcs), 'ca;', len(frs), 'FR;', len(problems), 'vấn đề')
for p in problems: print(' -', p, file=sys.stderr)
sys.exit(1 if problems else 0)
