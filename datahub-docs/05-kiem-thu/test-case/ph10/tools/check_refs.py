#!/usr/bin/env python3
"""Đối chiếu mã và enum trong D05-02-PH10 với các tập nguồn PH-10 (FRS, UC, API, màn hình, D02-08).
In mã có trong tập kiểm thử mà nguồn không định nghĩa; mã thoát 1 nếu có lệch."""
import re, sys
import tc_parse as P
R = P.ROOT
doc = P.DOC.read_text(encoding='utf-8')
src = {
    'FRS': P.FRS.read_text(encoding='utf-8'),
    'UC': (R / '02-yeu-cau/use-case/D02-04-PH10-use-case-su-kien.md').read_text(encoding='utf-8'),
    'API': (R / '03-thiet-ke/api/D03-04-PH10-api-su-kien.md').read_text(encoding='utf-8'),
    'MH': (R / '03-thiet-ke/uiux/D03-06-PH10-man-hinh-su-kien.md').read_text(encoding='utf-8'),
    'PQ': (R / '02-yeu-cau/D02-08-ma-tran-phan-quyen.md').read_text(encoding='utf-8'),
}
# Mã của FRS 0.3 (đang gộp ở luồng khác); chấp nhận tạm, xóa khi FRS 0.3 vào nhánh.
PENDING_03 = {'ERR-10-053', 'ERR-10-054', 'API-10-121'}
def defined(pat, text):
    return set(re.findall(r'^\|\s*(' + pat + r')\s*\|', text, re.M)) | set(re.findall(r'^#+\s*(' + pat + r')\b', text, re.M))
def used(prefix, width):
    out = set()
    for m in re.finditer(r'\b' + prefix + r'-10-(\d{%d})((?:\s*(?:,|…)\s*\d{%d}(?!\d))*)' % (width, width), doc):
        nums = [int(m.group(1))]
        for sep, n in re.findall(r'(,|…)\s*(\d{%d})' % width, m.group(2)):
            nums += [int(n)] if sep == ',' else list(range(nums[-1] + 1, int(n) + 1))
        out |= {f'{prefix}-10-{n:0{width}d}' for n in nums}
    return out
checks = [('FR', 3, 'FRS', r'FR-10-\d{3}'), ('NFR', 3, 'FRS', r'NFR-10-\d{3}'), ('BR', 3, 'FRS', r'BR-10-\d{3}'),
          ('UC', 2, 'UC', r'UC-10-\d{2}'), ('API', 3, 'API', r'API-10-\d{3}'), ('ERR', 3, 'API', r'ERR-10-\d{3}'),
          ('EVT', 2, 'API', r'EVT-10-\d{2}'), ('UI', 2, 'MH', r'UI-10-\d{2}')]
bad = 0
for pre, w, s, pat in checks:
    miss = sorted(used(pre, w) - defined(pat, src[s]) - PENDING_03)
    if miss: bad += len(miss); print(f'{pre} không có ở {s}:', ', '.join(miss))
perms = set(re.findall(r'PERM-10-[a-z]+', doc)) - set(re.findall(r'PERM-10-[a-z]+', src['PQ']))
if perms: bad += len(perms); print('PERM không có ở D02-08:', ', '.join(sorted(perms)))
enum_src = src['FRS'] + src['API']
enums = set(re.findall(r'`([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+|[A-Z]{4,})`', doc))
ignore = {'OPTIONS', 'POST', 'GET', 'PATCH', 'PUT', 'DELETE', 'OAUTHBEARER', 'COMMON', 'PLATFORM', 'PROTOBUF', 'UUID', 'INSERT', 'SELECT', 'LITERAL', 'PREFIXED', 'NOBYPASSRLS'}  # từ khóa SQL, kiểu ACL Kafka
miss = sorted(e for e in enums - ignore if f'`{e}`' not in enum_src and not re.search(r'\b' + e + r'\b', enum_src))
if miss: bad += len(miss); print('Enum không có ở FRS/API:', ', '.join(miss))
print('Lệch:', bad, '(tạm chấp nhận mã FRS 0.3:', ', '.join(sorted(PENDING_03)) + ')')
sys.exit(1 if bad else 0)
