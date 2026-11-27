#!/usr/bin/env python3
"""Kiểm tra hợp đồng PH-18: YAML nạp được, mọi $ref có đích, ví dụ khớp lược đồ, mã API đủ 180, không trùng và khớp FRS §9.4
(phương thức, đường dẫn), mã lỗi gắn ở operation có ở FRS §9.1 và không là mã worker, AsyncAPI đủ 29 sự kiện EVT-18 đúng địa chỉ,
dữ liệu sự kiện không mang khóa payload, giá trị hay bí mật (BR-18-050).
Chạy: python3 check_contracts.py (từ thư mục tools). Thoát 1 nếu có lỗi."""
import os
import re
import sys

import yaml
from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

HERE = os.path.dirname(os.path.abspath(__file__))
OA = yaml.safe_load(open(os.path.join(HERE, '..', 'openapi-ops.yaml'), encoding='utf-8'))
AA = yaml.safe_load(open(os.path.join(HERE, '..', 'asyncapi-ops.yaml'), encoding='utf-8'))
FRS = open(os.path.join(HERE, '..', '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH18-frs-van-hanh.md'), encoding='utf-8').read()
errs = []


def walk(o, path=''):
    if isinstance(o, dict):
        for k, v in o.items():
            yield from walk(v, path + '/' + str(k))
        yield path, o
    elif isinstance(o, list):
        for i, v in enumerate(o):
            yield from walk(v, path + '/%d' % i)


def resolve(doc, r):
    cur = doc
    for p in r.lstrip('#/').split('/'):
        p = p.replace('~1', '/').replace('~0', '~')
        if not isinstance(cur, dict) or p not in cur:
            return None
        cur = cur[p]
    return cur


for name, doc in (('openapi', OA), ('asyncapi', AA)):
    for p, o in walk(doc):
        if isinstance(o, dict) and isinstance(o.get('$ref'), str) and o['$ref'].startswith('#/') and resolve(doc, o['$ref']) is None:
            errs.append('%s: $ref hỏng %s tại %s' % (name, o['$ref'], p))

# mã API khớp FRS
frs_rows = {('API-18-' + n): (m, (p if p.startswith('/ops/internal/v1') else '/api/ops/v1' + p))
            for n, m, p in re.findall(r'^\| API-18-(\d{3}) \| `(GET|POST|PUT|PATCH|DELETE) ([^`]+)` \|', FRS, re.M)}
ids, opids = [], []
for path, item in OA['paths'].items():
    for m, op in item.items():
        ids.append(op['x-datahub-id'])
        opids.append(op['operationId'])
        want = frs_rows.get(op['x-datahub-id'])
        if want != (m.upper(), path):
            errs.append('%s lệch FRS: %s %s, FRS %s' % (op['x-datahub-id'], m.upper(), path, want))
if len(ids) != 180 or len(set(ids)) != 180:
    errs.append('mã API không đủ 180 hoặc trùng: %d/%d' % (len(ids), len(set(ids))))
if len(set(opids)) != len(opids):
    errs.append('operationId trùng')
if set(frs_rows) != set(ids):
    errs.append('mã API lệch FRS: %s' % sorted(set(frs_rows) ^ set(ids))[:10])

# mã lỗi
sec91 = FRS[FRS.index('### 9.1. Mã lỗi'):FRS.index('### 9.2.')]
http = {c: h.strip() for c, h in re.findall(r'^\| (ERR-18-\d{3}) \| ([^|]+) \|', sec91, re.M)}
for path, item in OA['paths'].items():
    for m, op in item.items():
        for c in op.get('x-datahub-errors', []):
            if c not in http:
                errs.append('%s: mã lỗi %s không có ở FRS' % (op['x-datahub-id'], c))
            elif not http[c].isdigit():
                errs.append('%s: mã worker %s gắn vào HTTP' % (op['x-datahub-id'], c))
            elif http[c] not in op['responses']:
                errs.append('%s: thiếu phản hồi %s cho %s' % (op['x-datahub-id'], http[c], c))
        if m in ('post',) and op.get('x-datahub-idempotent') is None and op['operationId'] not in ('ops007', 'ops028', 'ops086', 'ops094', 'ops117'):
            errs.append('%s: POST thiếu Idempotency-Key' % op['x-datahub-id'])

reg = Registry().with_resource('urn:doc', Resource.from_contents({'components': OA['components']}, default_specification=DRAFT202012))


def fix(o):
    if isinstance(o, dict):
        return {k: (v.replace('#/components/', 'urn:doc#/components/') if k == '$ref' and isinstance(v, str) and v.startswith('#/') else fix(v)) for k, v in o.items()}
    if isinstance(o, list):
        return [fix(x) for x in o]
    return o


nex = 0
for path, item in OA['paths'].items():
    for m, op in item.items():
        bodies = list((op.get('requestBody') or {}).get('content', {}).values())
        for r in op['responses'].values():
            bodies += list((r.get('content') or {}).values())
        for c in bodies:
            if 'example' in c:
                nex += 1
                for e in Draft202012Validator(fix(c['schema']), registry=reg).iter_errors(c['example']):
                    errs.append('%s ví dụ không khớp %s: %s' % (op['x-datahub-id'], '/'.join(map(str, e.path)), e.message[:140]))
        for p in op.get('parameters', []):
            if 'example' in p and 'schema' in p:
                for e in Draft202012Validator(fix(p['schema']), registry=reg).iter_errors(p['example']):
                    errs.append('%s tham số %s: %s' % (op['x-datahub-id'], p['name'], e.message[:120]))

# AsyncAPI
evt = re.findall(r'^\| (EVT-18-\d{2}) \| `([^`]+)`', FRS, re.M)
chan = {c['x-datahub-id']: c['address'] for c in AA['channels'].values() if 'x-datahub-id' in c}
for e, t in evt:
    if chan.get(e) != t:
        errs.append('kênh %s thiếu hoặc sai địa chỉ' % e)
if len(chan) != len(evt) or len(evt) != 29:
    errs.append('số kênh phát %d, cần %d (29)' % (len(chan), len(evt)))
FORBID = re.compile(r'(?i)^(payload|content|body|value|values|secret|password|token|apiKey|address|email|phone|credentialRef)$')
for p, o in walk(AA['components']['schemas']):
    if isinstance(o, dict) and 'properties' in o and '/Ext' not in p and 'DlqRecord' not in p:
        allow = {'value'} if 'ThresholdCrossed' in p else set()
        for k in o['properties']:
            if FORBID.match(k) and k not in allow:
                errs.append('AsyncAPI: khóa nội dung hoặc bí mật %s ở %s' % (k, p))
areg = Registry().with_resource('urn:doc', Resource.from_contents({'components': AA['components']}, default_specification=DRAFT202012))
for name, msg in AA['components']['messages'].items():
    for ex in msg.get('examples', []):
        sch = fix(msg['payload'])
        for e in Draft202012Validator(sch, registry=areg).iter_errors(ex['payload']):
            errs.append('AsyncAPI ví dụ %s: %s' % (name, e.message[:120]))
nrecv = sum(1 for o in AA['operations'].values() if o['action'] == 'receive')
print('operation %d, ví dụ OpenAPI kiểm %d, kênh %d (phát %d, nhận %d), lược đồ %d' % (len(ids), nex, len(AA['channels']), len(chan), nrecv, len(OA['components']['schemas'])))
for e in errs:
    print('LỖI', e)
print('KẾT QUẢ:', 'sạch' if not errs else '%d lỗi' % len(errs))
sys.exit(1 if errs else 0)
