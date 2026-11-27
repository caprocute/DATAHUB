#!/usr/bin/env python3
"""Sinh các khối giữa dấu <!-- gen:xxx:start/end --> của D03-04-PH18-api-van-hanh.md từ OpenAPI, AsyncAPI và FRS.
Khối: stats (tóm tắt), perm (2.1), catalog (4), events (5.1), consume (5.3), errors (7), fr (10), dac-ta (14, bằng
build/tools/sinh_dac_ta_api.py --vi-du cho đủ 180 operation).
Chạy từ thư mục tools: python3 gen_md.py   (không sửa tay các khối sinh)."""
import os
import re
import subprocess
import sys
import tempfile

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_openapi as G  # noqa: E402

OAP = os.path.join(HERE, '..', 'openapi-ops.yaml')
OA = yaml.safe_load(open(OAP, encoding='utf-8'))
AA = yaml.safe_load(open(os.path.join(HERE, '..', 'asyncapi-ops.yaml'), encoding='utf-8'))
MD = os.path.join(HERE, '..', '..', 'D03-04-PH18-api-van-hanh.md')
SINH = os.path.join(HERE, '..', '..', '..', '..', 'build', 'tools', 'sinh_dac_ta_api.py')


def ab(p):
    return p.replace('PERM-18-', '')


def short(path):
    return path[len(G.USER_BASE):] if path.startswith(G.USER_BASE) else path


def ops():
    out = []
    for path, item in OA['paths'].items():
        for m, op in item.items():
            out.append((op['x-datahub-id'], m.upper(), path, op))
    return sorted(out, key=lambda x: x[0])


def rng(nums):
    nums = sorted(set(nums))
    out, i = [], 0
    while i < len(nums):
        j = i
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1:
            j += 1
        out.append('%03d' % nums[i] if i == j else ('%03d, %03d' % (nums[i], nums[j]) if j == i + 1 else '%03d…%03d' % (nums[i], nums[j])))
        i = j + 1
    return ', '.join(out)


def stats():
    O = ops()
    meth = {}
    for _, m, _, _ in O:
        meth[m] = meth.get(m, 0) + 1
    internal = sum(1 for _, _, p, _ in O if p.startswith(G.INT_BASE))
    ifm = sum(1 for *_, op in O if any(p.get('$ref', '').endswith('/IfMatch') for p in op['parameters']))
    idr = sum(1 for *_, op in O if op.get('x-datahub-idempotent') == 'required')
    ido = sum(1 for *_, op in O if op.get('x-datahub-idempotent') == 'optional')
    four = sum(1 for *_, op in O if 'ERR-18-005' in op['x-datahub-errors'])
    send = sum(1 for o in AA['operations'].values() if o['action'] == 'send')
    recv = len(AA['operations']) - send
    errs = len(G.ERRS)
    rows = [('Operation', '%d (%d API người dùng `/api/ops/v1`, %d API nội bộ `/ops/internal/v1`), %d đường dẫn' % (len(O), len(O) - internal, internal, len(OA['paths']))),
            ('Phương thức', ', '.join('%d `%s`' % (meth[k], k) for k in ('GET', 'POST', 'PUT', 'PATCH', 'DELETE') if k in meth)),
            ('Có `If-Match`', '%d operation' % ifm), ('`Idempotency-Key`', '%d bắt buộc, %d tùy chọn (lũy đẳng theo khóa tự nhiên)' % (idr, ido)),
            ('Duyệt bốn mắt (ERR-18-005)', '%d operation' % four), ('Lược đồ thành phần', '%d' % len(OA['components']['schemas'])),
            ('Kênh AsyncAPI', '%d (%d sự kiện phát EVT-18-01…29, %d kênh tiêu thụ)' % (len(AA['channels']), send, recv)),
            ('Mã lỗi', '%d (ERR-18-001…072 trả qua HTTP, ERR-18-101…124 của worker); 401, 403, 428 dùng ERR-00' % errs)]
    L = ['| Chỉ số | Giá trị |', '|---|---|'] + ['| %s | %s |' % r for r in rows] + ['', ': Con số chính của hợp đồng API PH-18', '']
    return '\n'.join(L)


def catalog():
    L = []
    by = {}
    for aid, m, path, op in ops():
        by.setdefault(op['tags'][0], []).append((aid, m, path, op))
    for k, (tag, desc, a, b) in enumerate(G.TAGS, 1):
        rows = by[tag]
        L += ['### 4.%d. %s' % (k, tag), '', '%s Nhóm có %d operation (API-18-%03d…%03d).' % (desc, len(rows), a, b), '',
              '| Mã | Thao tác | Mục đích | FR | Quyền, scope | Idem. | TC | Lỗi riêng |', '|---|---|---|---|---|---|---|---|']
        for aid, m, path, op in rows:
            ok = ', '.join(c for c in op['responses'] if c[0] in '23')
            fr = ', '.join(x[-3:] for x in op['x-datahub-fr'])
            dom = ', '.join(c[-3:] for c in op['x-datahub-domain-errors'])
            idem = {'required': 'có', 'optional': 'tùy chọn'}.get(op.get('x-datahub-idempotent'), '')
            perm = ab(op['x-datahub-permission']['permission']).replace('Đăng nhập (mọi vai trò)', 'đăng nhập').replace('; mTLS SPIFFE', '')
            L.append('| %s | `%s %s` | %s | %s | %s | %s | %s | %s |' % (aid, m, short(path), op['summary'], fr, perm, idem, ok, dom))
        L += ['', ': Danh mục API nhóm %s' % tag, '']
    return '\n'.join(L)


def events():
    L = ['| Mã | Topic | Khóa | Trường dữ liệu | Bên nhận |', '|---|---|---|---|---|']
    for ch in AA['channels'].values():
        if 'x-datahub-id' not in ch:
            continue
        msg = list(ch['messages'].values())[0]['$ref'].split('/')[-1]
        data = AA['components']['schemas'][msg + 'Data']
        props = ', '.join('`%s`' % p for p in data['properties'])
        L.append('| %s | `%s` | `%s` | %s | %s |' % (ch['x-datahub-id'], ch['address'], ch['x-datahub-partition-key'], props, ch['x-datahub-consumers']))
    L += ['', ': Sự kiện PH-18 phát (AsyncAPI `send`)', '']
    return '\n'.join(L)


def consume():
    L = ['| Topic | Bên phát | PH-18 dùng để |', '|---|---|---|']
    for ch in AA['channels'].values():
        if 'x-datahub-producer' not in ch:
            continue
        L.append('| `%s` | %s | %s |' % (ch['address'], ch['x-datahub-producer'], ch['description'].split('. Bên phát')[0]))
    L += ['', ': Kênh PH-18 tiêu thụ (AsyncAPI `receive`)', '']
    return '\n'.join(L)


def errors():
    use = {}
    for aid, m, path, op in ops():
        for c in op['x-datahub-errors']:
            use.setdefault(c, []).append(int(aid[-3:]))
    general = {'ERR-18-001': 'Mọi operation có tham số đường dẫn', 'ERR-18-003': 'Mọi thao tác có thân hoặc bộ lọc', 'ERR-18-004': 'Mọi operation có `If-Match`',
               'ERR-18-005': 'Duyệt, từ chối bốn mắt', 'ERR-18-006': 'Mọi hành động chuyển trạng thái', 'ERR-18-007': 'Thao tác nhận lý do bắt buộc',
               'ERR-18-008': 'Mọi thao tác ghi', 'ERR-18-009': 'Mọi `POST` có `Idempotency-Key`', 'ERR-18-010': 'Mọi operation',
               'ERR-18-071': 'Mọi thao tác ghi nhóm tham số'}
    L = ['| Mã | HTTP | Ý nghĩa | Thông báo | Dùng ở API |', '|---|---|---|---|---|']
    for c, (st, meaning, text, frs) in G.ERRS.items():
        if c in general:
            u = general[c]
        elif st is None:
            u = 'Worker: trạng thái đối tượng, log, `dh_ops_errors_total{code}`'
        elif c in use:
            u = rng(use[c]) if len(use[c]) <= 8 else rng(use[c][:8]) + ' …'
        else:
            u = 'Theo FR liên quan'
        L.append('| %s | %s | %s | %s | %s |' % (c, st if st else 'Không (worker)', meaning, '"%s"' % text.replace('|', '/'), u))
    L += ['', ': Bảng mã lỗi ERR-18 và thông báo hiển thị', '']
    return '\n'.join(L)


def frmap():
    m = {}
    for aid, _, _, op in ops():
        for f in op['x-datahub-fr']:
            m.setdefault(int(f[-3:]), []).append(int(aid[-3:]))
    L = ['| FR | API | FR | API |', '|---|---|---|---|']
    half = 36
    for i in range(1, half + 1):
        def cell(n):
            return ('FR-18-%03d | %s' % (n, rng(m[n]))) if n in m else ('FR-18-%03d | Chạy nền, không có API riêng' % n)
        L.append('| %s | %s |' % (cell(i), cell(i + half)))
    L += ['', ': Truy vết FR-18-001…072 sang API-18', '']
    return '\n'.join(L)


def dac_ta():
    with tempfile.TemporaryDirectory() as td:
        t = os.path.join(td, 'a.md')
        open(t, 'w', encoding='utf-8').write('## Lịch sử phiên bản\n')
        subprocess.run([sys.executable, SINH, OAP, t, '--vi-du'], check=True, capture_output=True)
        s = open(t, encoding='utf-8').read()
    blk = s[s.index('<!-- gen:dac-ta-api:start -->'):s.index('<!-- gen:dac-ta-api:end -->')]
    blk = blk.replace('<!-- gen:dac-ta-api:start -->\n', '')
    desc = {t: dsc for t, dsc, _, _ in G.TAGS}
    n = 0

    def add(mo):
        nonlocal n
        n += 1
        tag = mo.group(1)
        return '### 14.%d. %s\n\n%s Mỗi operation một khối đặc tả 10 mục, kèm ví dụ yêu cầu và phản hồi sinh từ OpenAPI.' % (n, tag, desc[tag])
    blk = re.sub(r'(?m)^### ([^\n]+)$', add, blk)
    return blk.strip() + '\n'


def put(s, name, body):
    pat = re.compile(r'(<!-- gen:%s:start -->).*?(<!-- gen:%s:end -->)' % (name, name), re.S)
    if not pat.search(s):
        raise SystemExit('thiếu dấu gen:' + name)
    return pat.sub(lambda m: m.group(1) + '\n' + body.strip('\n') + '\n' + m.group(2), s)


def main():
    s = open(MD, encoding='utf-8').read()
    for name, fn in (('stats', stats), ('perm', perm), ('catalog', catalog), ('events', events), ('consume', consume), ('errors', errors), ('fr', frmap),
                     ('dac-ta', dac_ta)):
        s = put(s, name, fn())
    open(MD, 'w', encoding='utf-8').write(s)
    print('đã sinh các khối cho', MD, len(s.encode()), 'byte')


def perm():
    cnt = {}
    for aid, m, path, op in ops():
        for p in re.split(r'; | / ', op['x-datahub-permission']['permission']):
            p = p.strip()
            if p.startswith('scope '):
                for sc in p[6:].split(', '):
                    cnt.setdefault('scope ' + sc, []).append(int(aid[-3:]))
            elif p and p != 'mTLS SPIFFE':
                cnt.setdefault(p, []).append(int(aid[-3:]))
    L = ['| Quyền hoặc scope | Số operation | Operation |', '|---|---|---|']
    for k in sorted(cnt, key=lambda x: (x.startswith('scope'), x)):
        v = cnt[k]
        r = rng(v)
        L.append('| `%s` | %d | %s |' % (k, len(v), r if len(r) < 100 else rng(v[:14]) + ' …'))
    L += ['', ': Số operation theo quyền chức năng và scope máy', '']
    return '\n'.join(L)


if __name__ == '__main__':
    main()
