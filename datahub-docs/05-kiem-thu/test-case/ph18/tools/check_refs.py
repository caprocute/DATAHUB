#!/usr/bin/env python3
"""Đối chiếu mã trong D05-02-PH18 với FRS, UC, màn hình. Thoát 1 nếu có mã không được định nghĩa."""
import re, sys
import tc_parse as P
R = P.ROOT
doc = P.DOC.read_text(encoding='utf-8')
frs = P.FRS.read_text(encoding='utf-8')
uc = (R / '02-yeu-cau/use-case/D02-04-PH18-use-case-van-hanh.md').read_text(encoding='utf-8')
mh = (R / '03-thiet-ke/uiux/D03-06-PH18-man-hinh-van-hanh.md').read_text(encoding='utf-8')
bad = 0
for pre, src in (('FR', frs), ('NFR', frs), ('BR', frs), ('ERR', frs), ('EVT', frs), ('API', frs), ('UI', mh), ('UC', uc)):
    used = {m for m in P.refs(doc) if m.startswith(pre + '-18-')}
    defined = set(re.findall(r'\b' + pre + r'-18-\d{2,3}\b', src))
    miss = sorted(used - defined)
    if miss: bad += len(miss); print(pre, 'không có ở nguồn:', ', '.join(miss))
perms = set(re.findall(r'PERM-18-[a-z-]+', doc)) - set(re.findall(r'PERM-18-[a-z-]+', frs))
if perms: bad += len(perms); print('PERM lạ:', ', '.join(sorted(perms)))
print('Lệch:', bad); sys.exit(1 if bad else 0)
