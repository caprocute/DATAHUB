#!/usr/bin/env python3
"""Sinh các khối giữa dấu <!-- gen:xxx:start/end --> của D03-04-PH17-api-tro-ly-ai.md từ OpenAPI, AsyncAPI và FRS.
Khối: catalog (chương 3), events (4), errors (6), fr (9), examples (12), perm (2.1), dac-ta-api (13, bằng build/tools/sinh_dac_ta_api.py).
Chạy từ thư mục tools: python3 gen_md.py   (không sửa tay các khối sinh)."""
import copy
import json
import os
import re
import subprocess
import sys
import tempfile

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_openapi as G  # noqa: E402

OA = yaml.safe_load(open(os.path.join(HERE, '..', 'openapi-assist.yaml'), encoding='utf-8'))
AA = yaml.safe_load(open(os.path.join(HERE, '..', 'asyncapi-assist.yaml'), encoding='utf-8'))
MD = os.path.join(HERE, '..', '..', 'D03-04-PH17-api-tro-ly-ai.md')
SINH = os.path.join(HERE, '..', '..', '..', '..', 'build', 'tools', 'sinh_dac_ta_api.py')


def ab(p):
    return p.replace('PERM-17-', '')


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


def catalog():
    L = []
    by = {}
    for aid, m, path, op in ops():
        by.setdefault(op['tags'][0], []).append((aid, m, path, op))
    for k, (tag, desc, _) in enumerate(G.TAGS, 1):
        rows = by[tag]
        L += ['### 3.%d. %s' % (k, tag), '', '%s Nhóm có %d operation.' % (desc, len(rows)), '',
              '| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |', '|---|---|---|---|---|---|---|']
        for aid, m, path, op in rows:
            ok = next(c for c in op['responses'] if c.startswith('2'))
            fr = ', '.join(x[-3:] for x in op['x-datahub-fr'])
            dom = ', '.join(c[-3:] for c in op['x-datahub-domain-errors'])
            L.append('| %s | `%s %s` | %s | %s | %s | %s | %s |' % (aid, m, path, op['summary'], fr, ab(op['x-datahub-permission']['permission']).replace('scope ', 's:'), ok, dom))
        L += ['', ': Danh mục API nhóm %s' % tag, '']
    return '\n'.join(L)


def events():
    L = ['| Mã | Topic | Khi nào | Bên tiêu thụ | Trường dữ liệu |', '|---|---|---|---|---|']
    for ch in AA['channels'].values():
        msg = list(ch['messages'].values())[0]['$ref'].split('/')[-1]
        data = AA['components']['schemas'][msg + 'Data']
        props = ', '.join(('`%s`' % p if p not in data.get('required', []) else '`%s`' % p) for p in data['properties'])
        L.append('| %s | `%s` | %s | %s | %s |' % (ch['x-datahub-id'], ch['address'], ch['title'], ch['x-datahub-consumers'], props))
    L += ['', ': Danh mục sự kiện của PH-17', '']
    return '\n'.join(L)


def errors():
    use = {}
    for aid, m, path, op in ops():
        for c in op['x-datahub-domain-errors']:
            use.setdefault(c, []).append(int(aid[-3:]))
    raw = {c: h for c, h in re.findall(r'^\| (ERR-17-\d{3}) \| ([0-9, ]+) \|', G.SEC91, re.M)}
    general = {'ERR-17-001': 'Mọi `GET` bản ghi và hành động theo mã', 'ERR-17-003': 'Mọi thao tác có thân', 'ERR-17-004': 'Mọi `PUT`, `PATCH`, hành động có `If-Match`',
               'ERR-17-005': 'Thao tác duyệt, từ chối bốn mắt', 'ERR-17-006': 'Mọi hành động chuyển trạng thái', 'ERR-17-007': 'Thao tác cần lý do',
               'ERR-17-010': 'Mọi thao tác ghi', 'ERR-17-087': 'Mọi `POST` đổi dữ liệu có `Idempotency-Key`', 'ERR-17-002': 'Thao tác tạo có mã nghiệp vụ',
               'ERR-17-009': 'Thao tác gọi dịch vụ ngoài'}
    L = ['| Mã | HTTP | Thông báo | Dùng ở API |', '|---|---|---|---|']
    for c, (st, _hs, text) in G.ERRS.items():
        u = general.get(c) or ((rng(use[c]) if len(use.get(c, [])) <= 6 else rng(use[c][:6]) + ' …') if c in use else 'Theo FR liên quan')
        L.append('| %s | %s | %s | %s |' % (c, raw[c].strip(), text.replace('|', '/'), u))
    L += ['', ': Bảng mã lỗi ERR-17', '']
    return '\n'.join(L)


def frmap():
    m = {}
    for aid, _, _, op in ops():
        for f in op['x-datahub-fr']:
            m.setdefault(int(f[-3:]), []).append(int(aid[-3:]))
    L = ['| FR | API | FR | API |', '|---|---|---|---|']
    half = 31
    for i in range(1, half + 1):
        def cell(n):
            if n > 62:
                return ' | '
            return ('FR-17-%03d | %s' % (n, rng(m[n]))) if n in m else ('FR-17-%03d | Chỉ giao diện hoặc chạy nền' % n)
        L.append('| %s | %s |' % (cell(i), cell(i + half)))
    L += ['', ': Truy vết FR-17-001…062 sang API-17', '']
    return '\n'.join(L)


def perm():
    cnt = {}
    for aid, m, path, op in ops():
        for p in re.split(r'; | / ', op['x-datahub-permission']['permission']):
            p = p.strip()
            if p:
                cnt.setdefault(ab(p).replace('scope ', 'scope '), []).append(int(aid[-3:]))
    L = ['| Quyền hoặc scope | Số operation | Operation |', '|---|---|---|']
    for k in sorted(cnt, key=lambda x: (x.startswith('scope'), x)):
        v = cnt[k]
        L.append('| `%s` | %d | %s |' % (k, len(v), rng(v) if len(rng(v)) < 90 else rng(v[:12]) + ' …'))
    L += ['', ': Số operation theo quyền chức năng và scope máy', '']
    return '\n'.join(L)


def examples():
    L = []
    titles = {3: 'Đề nghị bật trợ lý có số quyết định', 95: 'Gửi câu hỏi và nhận câu trả lời có trích dẫn', 99: 'Tìm dịch vụ bằng truy hồi lai', 104: 'Gợi ý ánh xạ trường',
              169: 'Xin phiếu truy cập nhật ký hội thoại', 187: 'Phân loại văn bản qua data plane', 190: 'Gợi ý bước quy trình cho PH-11'}
    byid = {int(a[-3:]): (m, p, op) for a, m, p, op in ops()}
    for k, n in enumerate(titles, 1):
        m, p, op = byid[n]
        rq, rs = G.EX[n]
        base = '' if p.startswith('/assist/v1') else '/api/assist/v1'
        code = [c for c in op['responses'] if c.startswith('2')][0]
        L += ['### 12.%d. %s' % (k, titles[n]), '',
              'Ví dụ cho API-17-%03d (`%s %s`), phản hồi `%s`; dữ liệu giả lập.' % (n, m, p, code), '',
              '```http', '%s %s%s' % (m, base, p), 'Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44' if (not p.startswith('/assist/v1') and m == 'POST' and n not in G.SAFE_POST) else 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01', '',
              json.dumps(rq, ensure_ascii=False, indent=2), '```', '', '```http', 'HTTP/1.1 %s' % code, '', json.dumps(rs, ensure_ascii=False, indent=2), '```', '']
    return '\n'.join(L)


def dac_ta():
    d = copy.deepcopy(OA)
    keep = {}
    for path, item in d['paths'].items():
        for m, op in item.items():
            if int(op['x-datahub-id'][-3:]) in G.KEY:
                op['x-datahub-permission']['permission'] = ab(op['x-datahub-permission']['permission'])
                keep.setdefault(path, {})[m] = op
    d['paths'] = keep
    with tempfile.TemporaryDirectory() as td:
        y, t = os.path.join(td, 'a.yaml'), os.path.join(td, 'a.md')
        yaml.safe_dump(d, open(y, 'w', encoding='utf-8'), allow_unicode=True, sort_keys=False, width=160)
        open(t, 'w', encoding='utf-8').write('## Lịch sử phiên bản\n')
        subprocess.run([sys.executable, SINH, y, t], check=True, capture_output=True)
        s = open(t, encoding='utf-8').read()
    blk = s[s.index('<!-- gen:dac-ta-api:start -->'):s.index('<!-- gen:dac-ta-api:end -->')]
    blk = blk.replace('<!-- gen:dac-ta-api:start -->\n', '')
    desc = {t: dsc for t, dsc, _ in G.TAGS}
    n = 0

    def add(mo):
        nonlocal n
        n += 1
        tag = mo.group(1)
        return '### 13.%d. %s\n\n%s Các operation sau có đặc tả đầy đủ.' % (n, tag, desc[tag])
    blk = re.sub(r'(?m)^### ([^\n]+)$', add, blk)
    return blk.strip() + '\n'


def put(s, name, body):
    pat = re.compile(r'(<!-- gen:%s:start -->).*?(<!-- gen:%s:end -->)' % (name, name), re.S)
    if not pat.search(s):
        raise SystemExit('thiếu dấu gen:' + name)
    return pat.sub(lambda m: m.group(1) + '\n' + body.strip('\n') + '\n' + m.group(2), s)


def main():
    s = open(MD, encoding='utf-8').read()
    for name, fn in (('perm', perm), ('catalog', catalog), ('events', events), ('errors', errors), ('fr', frmap), ('examples', examples), ('dac-ta', dac_ta)):
        s = put(s, name, fn())
    open(MD, 'w', encoding='utf-8').write(s)
    print('đã sinh các khối cho', MD, len(s.encode()), 'byte')


if __name__ == '__main__':
    main()
