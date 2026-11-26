"""Sinh chương đặc tả từng endpoint (khối ::: dac-ta) từ OpenAPI có x-datahub-id.

Chạy: python3 build/tools/sinh_dac_ta_api.py <openapi.yaml> <tệp.md>
Nội dung nằm giữa <!-- gen:dac-ta-api:start --> và <!-- gen:dac-ta-api:end -->;
chưa có cặp đánh dấu thì chèn trước "## Lịch sử phiên bản" dưới tiêu đề chương mới."""
import re
import sys

import yaml

oa, md = sys.argv[1], sys.argv[2]
d = yaml.safe_load(open(oa, encoding='utf-8'))
C = d.get('components', {})
BO_QUA = {'Traceparent', 'AcceptLanguage'}
TEN_HTTP = {'200': 'thành công', '201': 'đã tạo', '202': 'đã nhận, xử lý bất đồng bộ', '204': 'không có nội dung', '304': 'không đổi'}


def ref_name(r):
    return r.split('/')[-1]


def tham_so(params):
    out, idem = [], False
    for p in params or []:
        if '$ref' in p:
            n = ref_name(p['$ref'])
            if n in BO_QUA:
                continue
            p = C['parameters'][n]
        if p['name'] == 'Idempotency-Key':
            idem = True
        kieu = p.get('schema', {}).get('type', '')
        if '$ref' in p.get('schema', {}):
            kieu = ref_name(p['schema']['$ref'])
        bb = 'bắt buộc' if p.get('required') else 'tùy chọn'
        out.append(f"`{p['name']}` ({p['in']}, {kieu}, {bb})")
    return out, idem


def schema_txt(sch):
    if not sch:
        return ''
    if '$ref' in sch:
        n = ref_name(sch['$ref'])
        s = C['schemas'].get(n, {})
        req = s.get('required') or []
        t = f"`{n}`"
        if req:
            t += '; trường bắt buộc: ' + ', '.join(f'`{x}`' for x in req)
        return t
    if sch.get('type') == 'array' and '$ref' in sch.get('items', {}):
        return f"mảng `{ref_name(sch['items']['$ref'])}`"
    return sch.get('type', '')


def body(rb):
    if not rb:
        return 'Không'
    if '$ref' in rb:
        rb = C['requestBodies'][ref_name(rb['$ref'])]
    for ct, v in rb.get('content', {}).items():
        return f"{ct}: {schema_txt(v.get('schema', {}))}"
    return 'Không'


def resp(rs):
    ok, loi = [], []
    for code, r in rs.items():
        if '$ref' in r:
            r = C['responses'][ref_name(r['$ref'])]
        if str(code).startswith(('2', '3')):
            t = f"`{code}` {TEN_HTTP.get(str(code), '')}".rstrip()
            for ct, v in (r.get('content') or {}).items():
                st = schema_txt(v.get('schema', {}))
                if st:
                    t += f", {st}"
                break
            if r.get('headers'):
                t += '; tiêu đề ' + ', '.join(f'`{h}`' for h in r['headers'])
            ok.append(t)
        else:
            loi.append(f"`{code}` {r.get('description', '').rstrip('.')}")
    return ok, loi


def loi_txt(op, loi):
    # OpenAPI có x-datahub-errors (mã lỗi riêng của thao tác) thì chỉ liệt kê mã HTTP và các mã đó,
    # tránh chép mọi mã của phản hồi lỗi dùng chung.
    ma = op.get('x-datahub-errors')
    if not ma:
        return '; '.join(loi) or 'Không'
    http = ', '.join(x.split(' ')[0] for x in loi)
    return f"HTTP {http}; mã lỗi của thao tác: {', '.join(ma)} (ý nghĩa ở chương mã lỗi)"


nhom = {}
for path, item in d['paths'].items():
    for m, op in item.items():
        if m not in ('get', 'post', 'put', 'patch', 'delete') or 'x-datahub-id' not in op:
            continue
        nhom.setdefault((op.get('tags') or ['Khác'])[0], []).append((op['x-datahub-id'], m.upper(), path, op))
L = ['<!-- gen:dac-ta-api:start -->', '']
da_gap = set()  # một mã dùng cho nhiều phương thức trên cùng tài nguyên (vd GET và PUT)
for tag, ops in nhom.items():
    L += [f'### {tag}', '']
    for aid, m, path, op in sorted(ops):
        ps, idem = tham_so(op.get('parameters'))
        ok, loi = resp(op.get('responses', {}))
        quyen = (op.get('x-datahub-permission') or {}).get('permission', 'Token dịch vụ')
        fr = ', '.join(op.get('x-datahub-fr') or []) or 'Không'
        muc = op.get('summary', '')
        mota = (op.get('description') or '').strip().replace('\n', ' ')
        rows = [('Mục đích', muc), ('Phương thức, đường dẫn', f'`{m} {path}`'), ('Quyền', f'`{quyen}`' if quyen.startswith('PERM') else quyen),
                ('FR hiện thực', fr), ('Tham số', '; '.join(ps) or 'Không'), ('Thân yêu cầu', body(op.get('requestBody'))),
                ('Chống trùng', 'Có, tiêu đề `Idempotency-Key`' if idem else 'Không'), ('Phản hồi thành công', '; '.join(ok) or 'Không'),
                ('Lỗi', loi_txt(op, loi)), ('Ghi chú', mota or 'Không')]
        tieu_de = f'#### {aid} · {muc}' if aid not in da_gap else f'#### {muc} ({aid}, {m})'
        da_gap.add(aid)
        L += [tieu_de, '', '::: dac-ta']
        L += [f"**{a}.** {b.rstrip('.')}.\n" for a, b in rows]
        L[-1] = L[-1].rstrip('\n')
        L += [':::', '']
L += ['<!-- gen:dac-ta-api:end -->']
gen = '\n'.join(L)
s = open(md, encoding='utf-8').read()
if '<!-- gen:dac-ta-api:start -->' in s:
    s = re.sub(r'<!-- gen:dac-ta-api:start -->.*?<!-- gen:dac-ta-api:end -->', lambda _: gen, s, flags=re.S)
else:
    so = max([int(x) for x in re.findall(r'^## (\d+)\. ', s, re.M)] or [0]) + 1
    i = s.index('## Lịch sử phiên bản')
    s = s[:i] + f'## {so}. Đặc tả từng endpoint\n\nChương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục.\n\n' + gen + '\n\n' + s[i:]
open(md, 'w', encoding='utf-8').write(s)
print('Số endpoint:', sum(len(v) for v in nhom.values()))
