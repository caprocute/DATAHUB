"""Sinh chương đặc tả từng endpoint (khối ::: dac-ta) từ OpenAPI có x-datahub-id.

Chạy: python3 build/tools/sinh_dac_ta_api.py <openapi.yaml> <tệp.md> [--vi-du]
Nội dung nằm giữa <!-- gen:dac-ta-api:start --> và <!-- gen:dac-ta-api:end -->;
chưa có cặp đánh dấu thì chèn trước "## Lịch sử phiên bản" dưới tiêu đề chương mới.

Cột "Quyền": ưu tiên chuỗi `x-datahub-permission.permission`; nếu thiếu thì đọc `anyOf` (nối bằng "hoặc")
rồi `serviceScope` (in "Token dịch vụ, scope `…`"); không có cả ba thì in "Token dịch vụ".

--vi-du: sau mỗi khối in "Ví dụ yêu cầu và phản hồi" (hai khối HTTP), dựng từ `example` của tham số,
thân yêu cầu, thân và tiêu đề phản hồi thành công trong OpenAPI (không có cờ thì đầu ra như cũ).
Dòng `Content-Type` chỉ in khi khác `application/json` (mặc định của API) để ví dụ gọn.
Khi nhiều operation dùng chung một mã API (hợp đồng cũ), mã chỉ nằm ở một tiêu đề `####`, mỗi operation
là một tiêu đề `#####` theo phương thức và đường dẫn, để kiem_tra_ma.py không báo trùng."""
import json
import re
import sys

import yaml

VI_DU = '--vi-du' in sys.argv
sys.argv = [a for a in sys.argv if a != '--vi-du']
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


TRANG_THAI = {'200': 'OK', '201': 'Created', '202': 'Accepted', '204': 'No Content', '304': 'Not Modified'}
RONG = 92


def gon(v, thut=0):
    """JSON gọn: một dòng nếu vừa RONG ký tự, không thì xếp các phần tử cấp ngoài thành nhiều dòng."""
    mot = json.dumps(v, ensure_ascii=False)
    if len(mot) + thut <= RONG or not isinstance(v, (dict, list)) or not v:
        return mot
    mo, dong = ('{', '}') if isinstance(v, dict) else ('[', ']')
    if isinstance(v, dict):
        cap = [(json.dumps(k, ensure_ascii=False) + ': ', x) for k, x in v.items()]
    else:
        cap = [('', x) for x in v]
    dong_ra, cur = [], mo
    for i, (k, x) in enumerate(cap):
        t = k + gon(x, thut + 1)
        t += ', ' if i < len(cap) - 1 else ''
        dau = t.split('\n')[0]
        if cur.strip() != mo and len(cur) + len(dau) > RONG:
            dong_ra.append(cur.rstrip())
            cur = ' ' * (thut + 1)
        if '\n' in t:
            phan = t.split('\n')
            dong_ra.append(cur + phan[0])
            dong_ra += phan[1:-1]
            cur = phan[-1]
        else:
            cur += t
    dong_ra.append(cur.rstrip() + dong)
    return '\n'.join(dong_ra)


def tim_tham_so(op):
    out = []
    for p in op.get('parameters') or []:
        if '$ref' in p:
            p = C['parameters'][ref_name(p['$ref'])]
        out.append(p)
    return out


def vi_du(m, path, op):
    base = re.sub(r'^https?://[^/]+', '', (d.get('servers') or [{}])[-1].get('url', ''))
    ps = tim_tham_so(op)
    url = path
    for p in ps:
        if p['in'] == 'path' and 'example' in p:
            url = url.replace('{' + p['name'] + '}', str(p['example']))
    q = []
    for p in ps:
        if p['in'] == 'query' and 'example' in p:
            v = p['example']
            if isinstance(v, list) and p.get('explode', True):
                q += [f"{p['name']}={x}" for x in v]
                continue
            if isinstance(v, list):
                v = ','.join(map(str, v))
            q.append(f"{p['name']}={str(v).lower() if isinstance(v, bool) else v}")
    yc = [f"{m} {base}{url}" + ('?' + '&'.join(q) if q else '')]
    if op.get('responses', {}).get('200', {}).get('content', {}).get('text/event-stream'):
        yc.append('Accept: text/event-stream')
    for p in ps:
        if p['in'] == 'header' and 'example' in p:
            yc.append(f"{p['name']}: {p['example']}")
    for ct, c in (op.get('requestBody') or {}).get('content', {}).items():
        if c.get('example') is not None:
            ex = c['example']
            if ct.startswith('multipart/'):
                yc += [f'Content-Type: {ct}; boundary=ranh-gioi', '']
                for k, v in ex.items():
                    yc += ['--ranh-gioi', f'Content-Disposition: form-data; name="{k}"', '', str(v)]
                yc.append('--ranh-gioi--')
            else:
                yc += ([] if ct == 'application/json' else [f'Content-Type: {ct}']) + ['', gon(ex)]
        break
    ph = []
    for code, r in op.get('responses', {}).items():
        if not str(code).startswith('2'):
            continue
        ph.append(f"HTTP/1.1 {code} {TRANG_THAI.get(str(code), '')}".rstrip())
        for h, hv in (r.get('headers') or {}).items():
            if hv.get('example'):
                ph.append(f"{h}: {hv['example']}")
        for ct, c in (r.get('content') or {}).items():
            if c.get('example') is not None:
                ex = c['example']
                ph += ([] if ct == 'application/json' else [f'Content-Type: {ct}']) + ['', ex.rstrip('\n') if isinstance(ex, str) else gon(ex)]
                break
        break
    return ['**Ví dụ yêu cầu và phản hồi.**', '', '```http', *yc, '```', '', '```http', *ph, '```', '']


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
    for aid, m, path, op in sorted(ops, key=lambda x: x[:3]):
        ps, idem = tham_so(op.get('parameters'))
        ok, loi = resp(op.get('responses', {}))
        xdp = op.get('x-datahub-permission') or {}
        if xdp.get('permission'):
            quyen = xdp['permission']
        elif xdp.get('anyOf'):
            quyen = ' hoặc '.join(f'`{q}`' for q in xdp['anyOf'])
        elif xdp.get('serviceScope'):
            quyen = f"Token dịch vụ, scope `{xdp['serviceScope']}`"
        else:
            quyen = 'Token dịch vụ'
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
        if VI_DU:
            L += vi_du(m, path, op)
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
