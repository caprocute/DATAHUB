#!/usr/bin/env python3
"""Kiểm hợp đồng PH-20.

- Mọi ví dụ (thân yêu cầu, phản hồi thành công, phản hồi lỗi, tham số có example) khớp lược đồ (jsonschema 2020-12).
- Đủ 171 operation API-20-001…171 đúng phương thức, đường dẫn với bảng FRS §9.4; mỗi operation có x-datahub-id (duy nhất), x-datahub-fr,
  x-datahub-permission, x-datahub-errors, operationId duy nhất, security.
- POST có Idempotency-Key (trừ lệnh chỉ đọc), PUT, PATCH có If-Match; mã lỗi trong x-datahub-errors có ở FRS §9.1 và có mã HTTP tương ứng trong responses.
- Không lược đồ nào có trường bí mật (secret, password, token) và không ví dụ nào trông như khóa hay JWT.
- AsyncAPI: EVT-20-01…16 đúng topic ở FRS §9.3, mọi ví dụ thông điệp khớp payload, đủ kênh tiêu thụ.
Chạy: python3 tools/check_contracts.py (từ api/ph20). Cần PyYAML, jsonschema >= 4.18."""
import os
import re
import sys

import jsonschema
import yaml
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec_ops
from spec_ops import CAT, ERR, ROOT

bad = 0


def err(msg):
    global bad
    bad += 1
    print('LỖI', msg[:260])


def fix(x, base):
    if isinstance(x, dict):
        return {k: (base + v if k == '$ref' and isinstance(v, str) and v.startswith('#/') else fix(v, base)) for k, v in x.items()}
    if isinstance(x, list):
        return [fix(i, base) for i in x]
    return x


def checker(components, base):
    reg = Registry().with_resource(base, Resource.from_contents(fix({'components': components}, base), default_specification=DRAFT202012))

    def check(schema, inst, where):
        errs = list(jsonschema.Draft202012Validator(fix(schema, base), registry=reg, format_checker=jsonschema.FormatChecker()).iter_errors(inst))
        if errs:
            err(f'{where}: {errs[0].message[:240]} tại {list(errs[0].absolute_path)}')
    return check


SECRET = re.compile(r'(secret|password|passwd|token|apikey|api_key|privatekey)', re.I)
JWT = re.compile(r'eyJ[A-Za-z0-9_-]{10,}\.')


def scan_fields(sch, where):
    for n, s in sch.items():
        for p in (s.get('properties') or {}):
            if SECRET.search(p) and p not in ('secretRef', 'passwordMinLength'):
                err(f'{where}: lược đồ {n} có trường {p} gợi ý bí mật')


def walk_strings(node, where):
    if isinstance(node, dict):
        for k, v in node.items():
            walk_strings(v, where)
    elif isinstance(node, list):
        for v in node:
            walk_strings(v, where)
    elif isinstance(node, str):
        if JWT.search(node):
            err(f'{where}: có chuỗi giống JWT')


def media_examples(c):
    out = []
    for ct, m in (c or {}).items():
        if 'example' in m and 'examples' in m:
            err('media có cả example và examples')
        if 'example' in m and 'schema' in m and ct.startswith('application/') and 'octet' not in ct and 'sheet' not in ct and 'pdf' not in ct:
            out.append((ct, m['schema'], m['example']))
    return out


def check_openapi():
    seen_ids, seen_op = {}, set()
    for fn in ('openapi-platform.yaml', 'openapi-tenant.yaml', 'openapi-internal.yaml', 'openapi-ph20.yaml'):
        d = yaml.safe_load(open(os.path.join(ROOT, fn), encoding='utf-8'))
        comps = d['components']
        check = checker(comps, 'urn:oa')
        scan_fields(comps['schemas'], fn)
        walk_strings(d, fn)
        for n, p in comps['parameters'].items():
            if 'example' in p and 'schema' in p:
                check(p['schema'], p['example'], f'{fn} tham số {n}')
        for n, r in comps['responses'].items():
            for ct, sch, ex in media_examples(r.get('content')):
                check(sch, ex, f'{fn} phản hồi {n}')
        ops = 0
        for path, item in d['paths'].items():
            for m, op in item.items():
                if m not in ('get', 'post', 'put', 'patch', 'delete'):
                    continue
                ops += 1
                aid = op.get('x-datahub-id')
                where = f'{fn} {m.upper()} {path}'
                if not aid:
                    err(where + ': thiếu x-datahub-id'); continue
                if fn == 'openapi-ph20.yaml':
                    if aid in seen_ids:
                        err(f'{where}: trùng {aid}')
                    seen_ids[aid] = (m, path)
                    if op['operationId'] in seen_op:
                        err(f'{where}: trùng operationId')
                    seen_op.add(op['operationId'])
                for k in ('x-datahub-fr', 'x-datahub-permission', 'x-datahub-errors', 'security', 'responses', 'tags', 'summary', 'description'):
                    if k not in op:
                        err(f'{where}: thiếu {k}')
                names = {(p.get('$ref') or '').split('/')[-1] or p.get('name') for p in op.get('parameters', [])}
                if m == 'post' and 'IdempotencyKey' not in names and aid not in ('API-20-005', 'API-20-006', 'API-20-033', 'API-20-095', 'API-20-171'):
                    err(f'{where}: POST thiếu Idempotency-Key')
                if m in ('put', 'patch') and 'IfMatch' not in names:
                    err(f'{where}: thiếu If-Match')
                for e in op.get('x-datahub-errors', []):
                    if e.startswith('ERR-00-'):
                        continue
                    if e not in ERR:
                        err(f'{where}: {e} không có ở FRS 9.1')
                    elif ERR[e]['http'] is None:
                        err(f'{where}: {e} không có mã HTTP nhưng nằm ở operation')
                    elif str(ERR[e]['http']) not in op['responses']:
                        err(f'{where}: {e} cần phản hồi {ERR[e]["http"]}')
                rb = op.get('requestBody')
                if rb:
                    for ct, sch, ex in media_examples(rb['content']):
                        check(sch, ex, where + ' yêu cầu')
                    if 'multipart/form-data' in rb['content'] and 'example' not in rb['content']['multipart/form-data']:
                        err(where + ': thiếu ví dụ multipart')
                for code, r in op['responses'].items():
                    if '$ref' in r:
                        continue
                    for ct, sch, ex in media_examples(r.get('content')):
                        check(sch, ex, f'{where} phản hồi {code}')
                for p in op.get('parameters', []):
                    if 'name' in p and 'example' in p and 'schema' in p:
                        ex = p['example']
                        sch = p['schema']
                        if p.get('explode') and isinstance(ex, list):
                            sch = {'type': 'array', 'items': sch['items'] if sch.get('type') == 'array' else sch}
                        check(sch, ex, f'{where} tham số {p["name"]}')
        print(fn, ops, 'operation')
    want = {f'API-20-{r["id"]:03d}': (r['method'], r['path']) for r in CAT}
    if set(want) != set(seen_ids):
        err(f'thiếu hoặc thừa API: {sorted(set(want) ^ set(seen_ids))[:10]}')
    for k, v in want.items():
        if seen_ids.get(k) != v:
            err(f'{k} lệch với FRS: {seen_ids.get(k)} so với {v}')


def check_asyncapi():
    fn = os.path.join(ROOT, 'asyncapi-ph20.yaml')
    if not os.path.exists(fn):
        err('thiếu asyncapi-ph20.yaml'); return
    d = yaml.safe_load(open(fn, encoding='utf-8'))
    if not str(d.get('asyncapi', '')).startswith('3.0'):
        err('asyncapi không phải 3.0')
    walk_strings(d, 'asyncapi')
    comps = d['components']
    check = checker({'schemas': comps['schemas']}, 'urn:aa')
    evts = {}
    for cn, ch in d['channels'].items():
        evts[ch.get('title', cn)] = ch['address']
    frs = spec_ops.frs_text.split('### 9.3. Sự kiện')[1].split('### 9.4.')[0]
    want = dict(re.findall(r'^\| (EVT-20-\d{2}) \| `([^`]+)` \|', frs, re.M))
    for k, t in want.items():
        got = evts.get(k)
        if got is None:
            err(f'thiếu {k}')
        elif got != t:
            err(f'{k}: topic {got} khác FRS {t}')
    n = 0
    for mn, m in comps['messages'].items():
        for ex in m.get('examples', []):
            n += 1
            ref = m['payload']['$ref'].split('/')[-1]
            check(comps['schemas'][ref], ex['payload'], f'asyncapi {mn} payload')
            if 'headers' in ex and 'headers' in m:
                check(m['headers'], ex['headers'], f'asyncapi {mn} headers') if '$ref' not in m['headers'] else check(comps['schemas'][m['headers']['$ref'].split('/')[-1]], ex['headers'], f'asyncapi {mn} headers')
    print('asyncapi', len(d['channels']), 'kênh,', n, 'ví dụ')
    return d


if __name__ == '__main__':
    check_openapi()
    check_asyncapi()
    print('Kết quả:', 'SẠCH' if not bad else f'{bad} lỗi')
    sys.exit(1 if bad else 0)
