#!/usr/bin/env python3
"""Kiểm hợp đồng PH-15: OpenAPI 3.1 hợp lệ; ví dụ khớp lược đồ; mọi API-15-001…137 có đúng phương thức, đường dẫn, FR theo FRS §9.3;
mọi ERR-15 của FRS có trong tệp; AsyncAPI 3.0 có đủ EVT-15-01…14 và các EVT-02 tiêu thụ, ví dụ khớp lược đồ.
Chạy: python3 tools/check_contracts.py  (từ thư mục api/ph15). Cần: openapi-spec-validator, jsonschema ≥ 4.18, PyYAML."""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = os.path.join(ROOT, '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH15-frs-cong-nha-phat-trien.md')
ftxt = open(FRS, encoding='utf-8').read()
ERRS = dict((c, int(h)) for c, h in re.findall(r'^\| (ERR-15-\d{3}) \| (\d{3}) \|', ftxt, re.M))
ROWS = {a: (m, p, sorted('FR-15-' + f.strip() for f in fr.split(','))) for a, m, p, fr in re.findall(r'^\| (API-15-\d{3}) \| (\w+) \| `([^`]+)` \| ([0-9, ]+) \|$', ftxt, re.M)}
EVTS = re.findall(r'^\| (EVT-15-\d{2}) \| `([^`]+)`', ftxt, re.M)
bad = 0


def err(msg):
    global bad
    bad += 1
    print('LỖI', msg)


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


fn = 'openapi-portal.yaml'
d = yaml.safe_load(open(os.path.join(ROOT, fn), encoding='utf-8'))
validate(d)
check = checker(d['components'], 'urn:oa')


def exval(e):
    return e['value'] if 'value' in e else d['components']['examples'][e['$ref'].split('/')[-1]]['value']


n_ex = n_op = 0
ids = {}
used_err = set()
for p, item in d['paths'].items():
    for meth, o in item.items():
        if meth in ('servers', 'parameters'):
            continue
        n_op += 1
        oid = o.get('x-datahub-id', '?')
        for k in ('x-datahub-id', 'x-datahub-fr', 'x-datahub-permission', 'x-datahub-errors'):
            if k not in o:
                err(f'{o["operationId"]}: thiếu {k}')
        if oid in ids:
            err(f'{oid} trùng')
        ids[oid] = (meth.upper(), p, sorted(o['x-datahub-fr']))
        decl = {x['name'] for x in o.get('parameters', []) if x.get('in') == 'path'}
        for ph in re.findall(r'\{(\w+)\}', p):
            if ph not in decl:
                err(f'{oid}: thiếu tham số đường dẫn {ph}')
        names = {x.get('$ref', '').split('/')[-1] for x in o.get('parameters', [])}
        if o.get('x-datahub-idempotent') == 'required' and 'IdempotencyKey' not in names:
            err(f'{oid}: thiếu Idempotency-Key')
        if meth == 'post' and '201' in o['responses'] and 'IdempotencyKey' not in names:
            err(f'{oid}: tạo (201) thiếu Idempotency-Key')
        for e in o.get('x-datahub-errors', []):
            used_err.add(e)
            if e not in ERRS:
                err(f'{oid}: {e} không có ở FRS §9.1')
            elif str(ERRS[e]) not in o['responses']:
                err(f'{oid}: {e} ({ERRS[e]}) không có trong responses')
        for ct, c in o.get('requestBody', {}).get('content', {}).items():
            exs = [exval(e) for e in c.get('examples', {}).values()]
            if not exs:
                err(f'{oid}: thân {ct} thiếu ví dụ')
            for ex in exs:
                check(c['schema'], ex, f'{oid} yêu cầu {ct}')
                n_ex += 1
        has_ex = has_c = False
        for st, r in o['responses'].items():
            if '$ref' in r or not st.startswith('2'):
                continue
            for ct, c in r.get('content', {}).items():
                has_c = True
                if 'json' in ct:
                    for e in c.get('examples', {}).values():
                        has_ex = True
                        check(c['schema'], exval(e), f'{oid} phản hồi {st}')
                        n_ex += 1
                else:
                    has_ex = has_ex or 'example' in c
        if has_c and not has_ex:
            err(f'{oid}: thiếu ví dụ phản hồi')
for a_, (m, p, fr) in ROWS.items():
    if a_ not in ids:
        err(f'{a_} có ở FRS nhưng thiếu ở OpenAPI')
    elif ids[a_] != (m, p, fr):
        err(f'{a_}: FRS {m} {p} {fr} khác OpenAPI {ids[a_]}')
for a_ in ids:
    if a_ not in ROWS:
        err(f'{a_} có ở OpenAPI nhưng không có ở FRS')
if len(ROWS) != 137:
    err(f'FRS có {len(ROWS)} dòng API, cần 137')
chua = sorted(set(ERRS) - used_err)
for c in chua:
    if not any(c.replace('-', '_') in r.get('content', {}).get('application/problem+json', {}).get('examples', {}) for r in d['components']['responses'].values()):
        err(f'{c} không có trong OpenAPI')
for k, sch in d['components']['schemas'].items():
    for pk in sch.get('properties', {}) if isinstance(sch, dict) else {}:
        if re.search(r'secret|password|token$|apikey', pk, re.I) and not (k == 'CredentialIssued' and pk in ('clientSecret', 'apiKey')) and not (k == 'GitSourceInput' and pk == 'accessToken'):
            err(f'{k}.{pk}: trường bí mật ngoài CredentialIssued, GitSourceInput')
if not d['components']['schemas']['CredentialIssued']['properties']['clientSecret'].get('readOnly'):
    err('CredentialIssued.clientSecret thiếu readOnly')
print(f'{fn}: hợp lệ OpenAPI 3.1; {n_op} operation, {len(ids)} mã API; {n_ex} ví dụ đã kiểm; ERR chưa gắn operation: {len(chua)} {chua}')

fn = 'asyncapi-portal.yaml'
if not os.path.exists(os.path.join(ROOT, fn)):
    print('chưa có', fn)
    sys.exit(1 if bad else 0)
a = yaml.safe_load(open(os.path.join(ROOT, fn), encoding='utf-8'))
if a.get('asyncapi') != '3.0.0':
    err('AsyncAPI không phải 3.0.0')
checka = checker(a['components'], 'urn:aa')
n_ax = 0
for mk, msg in a['components']['messages'].items():
    for i, ex in enumerate(msg.get('examples', [])):
        if 'payload' in ex:
            checka(msg['payload'], ex['payload'], f'{mk} ví dụ {i} payload')
            n_ax += 1
        if 'headers' in ex and 'headers' in msg:
            checka(msg['headers'], ex['headers'], f'{mk} ví dụ {i} headers')
            n_ax += 1
    if not msg.get('examples'):
        err(f'{mk}: thiếu ví dụ')
titles = {ch.get('title') for ch in a['channels'].values()}
for e, _ in EVTS:
    if e not in titles:
        err(f'{e} có ở FRS nhưng thiếu kênh AsyncAPI')
for e in ('EVT-02-01', 'EVT-02-02', 'EVT-02-03', 'EVT-02-05', 'EVT-02-06', 'EVT-02-08', 'EVT-02-09', 'EVT-02-10', 'EVT-02-11', 'EVT-02-12'):
    if e not in titles:
        err(f'{e} (PH-15 tiêu thụ) thiếu kênh AsyncAPI')
for ck, ch in a['channels'].items():
    for mk, mr in ch.get('messages', {}).items():
        if mr['$ref'].split('/')[-1] not in a['components']['messages']:
            err(f'kênh {ck}: thiếu thông điệp')
for ok_, op in a['operations'].items():
    if op['channel']['$ref'].split('/')[-1] not in a['channels']:
        err(f'operation {ok_}: kênh không có')
print(f'{fn}: {len(a["channels"])} kênh, {len(a["operations"])} operation, {len(a["components"]["messages"])} thông điệp; {n_ax} ví dụ đã kiểm')
sys.exit(1 if bad else 0)
