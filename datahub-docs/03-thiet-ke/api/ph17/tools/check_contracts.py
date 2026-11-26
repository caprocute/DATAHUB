#!/usr/bin/env python3
"""Kiểm tra hợp đồng PH-17: YAML nạp được, mọi $ref có đích, ví dụ khớp lược đồ, mã API đủ 193 và không trùng,
enum khớp Phụ lục A, AsyncAPI có đủ 28 sự kiện EVT-17 và không mang khóa nội dung hoặc bí mật.
Chạy: python3 check_contracts.py (từ thư mục tools). Thoát 1 nếu có lỗi."""
import json
import os
import re
import sys

import yaml
from jsonschema import Draft202012Validator
from referencing import Registry, Resource

HERE = os.path.dirname(os.path.abspath(__file__))
OA = yaml.safe_load(open(os.path.join(HERE, '..', 'openapi-assist.yaml'), encoding='utf-8'))
AA = yaml.safe_load(open(os.path.join(HERE, '..', 'asyncapi-assist.yaml'), encoding='utf-8'))
FRS = open(os.path.join(HERE, '..', '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH17-frs-tro-ly-ai.md'), encoding='utf-8').read()
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
        if p not in cur:
            return None
        cur = cur[p]
    return cur


for name, doc in (('openapi', OA), ('asyncapi', AA)):
    for p, o in walk(doc):
        if isinstance(o, dict) and '$ref' in o and isinstance(o['$ref'], str) and o['$ref'].startswith('#/') and resolve(doc, o['$ref']) is None:
            errs.append('%s: $ref hỏng %s tại %s' % (name, o['$ref'], p))

ids, opids = [], []
for path, item in OA['paths'].items():
    for m, op in item.items():
        ids.append(op['x-datahub-id'])
        opids.append(op['operationId'])
if len(ids) != 193 or len(set(ids)) != 193:
    errs.append('mã API không đủ 193 hoặc trùng: %d/%d' % (len(ids), len(set(ids))))
if len(set(opids)) != len(opids):
    errs.append('operationId trùng')
frs_ids = set(re.findall(r'^\| (API-17-\d{3}) \|', FRS, re.M))
if frs_ids != set(ids):
    errs.append('mã API lệch FRS: %s' % sorted(frs_ids ^ set(ids))[:10])


def validator(doc, schema):
    reg = Registry().with_resource('urn:doc', Resource.from_contents({'components': doc['components']}, default_specification=__import__('referencing.jsonschema', fromlist=['x']).DRAFT202012))
    return Draft202012Validator({'$ref': 'urn:doc#/components/schemas/X'}, registry=reg) if False else Draft202012Validator(schema, registry=reg)


def fix(o):
    if isinstance(o, dict):
        return {k: (v.replace('#/components/', 'urn:doc#/components/') if k == '$ref' and isinstance(v, str) and v.startswith('#/') else fix(v)) for k, v in o.items()}
    if isinstance(o, list):
        return [fix(x) for x in o]
    return o


nex = 0
for path, item in OA['paths'].items():
    for m, op in item.items():
        bodies = []
        for c in (op.get('requestBody') or {}).get('content', {}).values():
            bodies.append(c)
        for r in op['responses'].values():
            for c in (r.get('content') or {}).values():
                bodies.append(c)
        for c in bodies:
            if 'example' in c:
                nex += 1
                v = validator(OA, fix(c['schema']))
                for e in v.iter_errors(c['example']):
                    errs.append('%s ví dụ không khớp %s: %s' % (op['x-datahub-id'], '/'.join(map(str, e.path)), e.message[:120]))
for path, o in walk(OA['components'].get('responses', {})):
    pass

# enum khớp Phụ lục A
appx = FRS[FRS.index('## Phụ lục A.'):FRS.index('## Phụ lục B.')]
for m in re.finditer(r'^\| `(\w+)`( \([^)]*\))? \| ([^|]+) \|', appx, re.M):
    n = m.group(1)
    if n in OA['components']['schemas']:
        v = re.findall(r'`([A-Z][A-Z0-9_]+)`', re.sub(r'\([^()]*\)', '', m.group(3)))
        if OA['components']['schemas'][n].get('enum') != v:
            errs.append('enum %s lệch Phụ lục A' % n)

# AsyncAPI
evt = re.findall(r'^\| (EVT-17-\d{2}) \| `([^`]+)`', FRS, re.M)
chan = {c['x-datahub-id']: c['address'] for c in AA['channels'].values() if 'x-datahub-id' in c}
for e, t in evt:
    if chan.get(e) != t:
        errs.append('kênh %s thiếu hoặc sai địa chỉ' % e)
if len(AA['channels']) != len(evt):
    errs.append('số kênh %d, cần %d' % (len(AA['channels']), len(evt)))
FORBID = re.compile(r'(?i)^(content|prompt|answer|question|text|chunk|embedding|secret|secretRef|password|apiKey|token|value)$')
for p, o in walk(AA['components']['schemas']):
    if isinstance(o, dict) and 'properties' in o:
        for k in o['properties']:
            if FORBID.match(k):
                errs.append('AsyncAPI: khóa nội dung hoặc bí mật %s ở %s' % (k, p))
for p, o in walk(AA):
    if isinstance(o, dict) and 'examples' in o and isinstance(o['examples'], list):
        pass
print('operation %d, ví dụ OpenAPI kiểm %d, kênh %d, lược đồ %d' % (len(ids), nex, len(AA['channels']), len(OA['components']['schemas'])))
for e in errs:
    print('LỖI', e)
print('KẾT QUẢ:', 'sạch' if not errs else '%d lỗi' % len(errs))
sys.exit(1 if errs else 0)
