#!/usr/bin/env python3
"""Sinh openapi-platform.yaml, openapi-tenant.yaml, openapi-internal.yaml và openapi-ph20.yaml (gộp 171 operation) của PH-20.
Chạy từ api/ph20:  python3 tools/gen_openapi.py     Không sửa tay các tệp YAML sinh ra.
Nguồn: bảng API-20-001…171 ở FRS §9.4 (spec_ops.py đọc trực tiếp), lược đồ ở schemas1.py, schemas2.py, tham số và ghi chú ở ops_def.py."""
import copy
import os
import re
import sys

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsl
from dsl import SCH, ENUMS, ex_of, parse_type, default_ex, FEX, resolve
import schemas1, schemas2  # noqa: F401  (đăng ký lược đồ)
import spec_ops
from spec_ops import CAT, ERR, FRERR, tag_of, ROOT, sample_msg
from ops_def import O, IFM_POST, ERR_ADD, ERR_DROP, NOTES
from res_ex import RES_EX, REQ_EX


class NoAlias(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


def _str(dumper, v):
    if re.fullmatch(r'[0-9+.eE-]+', v) or v in ('true', 'false', 'null', 'yes', 'no', 'on', 'off', '~', ''):
        return dumper.represent_scalar('tag:yaml.org,2002:str', v, style="'")
    if '\n' in v:
        return dumper.represent_scalar('tag:yaml.org,2002:str', v, style='|')
    return dumper.represent_scalar('tag:yaml.org,2002:str', v)


NoAlias.add_representer(str, _str)

PATH_EX = {'tenantCode': ('tc', None), 'contactId': ('uuid', 'contactId'), 'contractId': ('uuid', 'contractId'), 'runId': ('uuid', 'runId'), 'stepCode': ('E:StepCode', 'S06_EVENTING'),
           'templateCode': ('code', None), 'version': ('int', 3), 'clusterCode': ('str', 'cl-t68-onprem'), 'versionNo': ('int', 7), 'driftId': ('uuid', 'driftId'),
           'requestId': ('uuid', 'requestId'), 'overrideId': ('uuid', 'overrideId'), 'alertId': ('uuid', 'alertId'), 'reportId': ('uuid', 'reportId'), 'moduleCode': ('mod', None),
           'flagCode': ('str', 'ph04.sql-direct'), 'packageId': ('uuid', 'packageId'), 'mergePlanId': ('str', 'SN-2026-001'), 'mappingId': ('uuid', 'mappingId'), 'module': ('mod', 'PH-01'),
           'conflictId': ('uuid', 'conflictId'), 'releaseVersion': ('ver', '2.4.0'), 'planId': ('uuid', 'planId'), 'orgCode': ('ocode', None), 'importId': ('uuid', 'importId'),
           'proposalId': ('uuid', 'proposalId'), 'testRunId': ('uuid', 'testRunId')}
PATH_DESC = {'tenantCode': 'Mã tenant, ví dụ `T68`.', 'runId': 'Mã lần chạy saga.', 'stepCode': 'Mã bước saga `S01_RECORD` … `S17_ACTIVATE`.', 'templateCode': 'Mã mẫu khởi tạo.',
             'version': 'Số phiên bản của mẫu.', 'versionNo': 'Số phiên bản cấu hình.', 'mergePlanId': 'Mã kế hoạch sáp nhập, ví dụ `SN-2026-001`.', 'module': 'Mã phân hệ `PH-nn`.',
             'releaseVersion': 'Phiên bản sản phẩm theo SemVer.', 'orgCode': 'Mã tổ chức trong tenant.', 'moduleCode': 'Mã phân hệ `PH-nn`.', 'clusterCode': 'Mã cụm đích.',
             'flagCode': 'Mã cờ tính năng.', 'planId': 'Mã kế hoạch nâng cấp.'}

ETAG_RES = {'Tenant', 'TenantDetail', 'Contact', 'Contract', 'ProvisioningRun', 'TemplateVersion', 'TemplateDetail', 'Cluster', 'PlatformConfig', 'ConfigVersion', 'ConfigDrift',
            'LifecycleRequest', 'QuotaChangeRequest', 'QuotaOverride', 'TenantQuotas', 'TenantModule', 'FeatureFlag', 'MergePlan', 'MappingItem', 'MergeConflict', 'Release',
            'ReleaseDetail', 'ReleaseSubscription', 'UpgradePlan', 'TenantUpgrade', 'Organization', 'TenantSettings', 'CrossTenantPolicy', 'MaintenanceWindow', 'ExportPackage',
            'UsageReport', 'QuotaAlert', 'SyncProposal', 'LeakTestRun', 'OrgImportJob', 'MergeParticipantRun'}
CODE_HTTP = {400: 'BadRequest', 401: 'Unauthorized', 403: 'Forbidden', 404: 'NotFound', 409: 'Conflict', 410: 'Gone', 412: 'PreconditionFailed', 422: 'Unprocessable',
             428: 'PreconditionRequired', 502: 'BadGateway', 503: 'ServiceUnavailable'}
RESP_DEF = {400: ('Dữ liệu không hợp lệ', 'ERR-20-004', 'Dữ liệu sai định dạng'), 401: ('Chưa xác thực', 'ERR-00-401', 'Chưa xác thực'), 403: ('Không đủ quyền hoặc bị chặn', 'ERR-00-403', 'Không đủ quyền'),
            404: ('Không tìm thấy (kể cả đối tượng của tenant khác)', 'ERR-20-002', 'Không tìm thấy'), 409: ('Xung đột trạng thái hoặc dữ liệu', 'ERR-20-006', 'Trạng thái không cho phép'),
            410: ('Đã không còn', 'ERR-20-039', 'Gói bàn giao hết hạn'), 412: ('Phiên bản lệch (`If-Match`)', 'ERR-20-005', 'Phiên bản lệch'),
            422: ('Không xử lý được do quy tắc nghiệp vụ', 'ERR-20-008', 'Thiếu lý do, phiếu'), 428: ('Thiếu `If-Match`', 'ERR-00-428', 'Thiếu If-Match'),
            502: ('Phụ thuộc bên ngoài lỗi', 'ERR-20-024', 'Ghi GitOps lỗi'), 503: ('Phụ thuộc không khả dụng', 'ERR-20-062', 'Phụ thuộc không khả dụng')}


def camel(s):
    return ''.join(w[:1].upper() + w[1:] for w in re.split(r'[-_.]', s) if w)


def operation_id(method, path, i):
    segs = [s for s in path.strip('/').split('/') if s not in ('api', 'platform', 'tenant', 'v1', 'internal')]
    parts = []
    for s in segs:
        m = re.match(r'^(\{\w+\})?:?([\w-]+)?$', s) if False else None
        if s.startswith('{'):
            tail = s.split('}')[1] if '}' in s else ''
            if tail.startswith(':'):
                parts.append(camel(tail[1:]))
            continue
        if ':' in s:
            a, b = s.split(':', 1)
            parts.append(camel(a)); parts.append(camel(b))
        else:
            parts.append(camel(s))
    return f"{method}{''.join(parts)}{i:03d}"


def scope_of(row):
    return row['path'].split('/')[1:3]


def group_of(row):
    p = row['path']
    return 'platform' if p.startswith('/api/platform/') else 'tenant' if p.startswith('/api/tenant/') else 'internal'


def perm_of(row):
    p = row['perm']
    m = re.search(r'PERM-20-[a-z-]+', p)
    sc = re.search(r'`(tenant:[a-z-]+)`', p)
    if sc:
        return {'permission': 'Scope ' + sc.group(1)}, [sc.group(1)], 'oauth2Service'
    if m:
        return {'permission': m.group(0)}, [m.group(0)], 'oauth2User'
    if 'Mọi người dùng' in p:
        return {'permission': 'Mọi người dùng đã đăng nhập'}, [], 'oauth2User'
    return {'permission': 'Vai trò TA hoặc AU của tỉnh (ROLE-TENANT_ADMIN, ROLE-AUDITOR)'}, [], 'oauth2User'


def q_params(qs, extra_page, maxsize):
    out = []
    for tok in qs.split():
        name, t = tok.split(':', 1)
        out.append((name, t))
    names = {n for n, _ in out}
    if extra_page:
        for n in ('page', 'size'):
            if n not in names:
                out.append((n, 'int'))
    ps = []
    for name, t in out:
        if name == 'page':
            sch = {'type': 'integer', 'minimum': 0, 'default': 0}; ex = 0
        elif name == 'size':
            sch = {'type': 'integer', 'minimum': 1, 'maximum': maxsize, 'default': 20}; ex = 20
        else:
            sch = parse_type(t)
            base_t = t[:-2] if t.endswith('[]') else t
            ex = resolve(default_ex(t, name))
            if base_t in ('str', 'tc', 'ts', 'int', 'bool', 'ocode', 'mod', 'ver', 'uuid') and name in EXQ:
                ex = EXQ[name]
                if t.endswith('[]') and not isinstance(ex, list):
                    ex = [ex]
                if not t.endswith('[]') and isinstance(ex, list):
                    ex = ex[0]
        p = {'name': name, 'in': 'query', 'schema': sch, 'example': ex}
        if t.endswith('[]'):
            p['style'] = 'form'; p['explode'] = True
            if not isinstance(ex, list):
                p['example'] = [ex]
        ps.append(p)
    return ps


EXQ = {'q': 'lam vien', 'from': '2026-11-01T00:00:00+07:00', 'to': '2026-11-27T00:00:00+07:00', 'sort': 'code', 'status': 'ACTIVE', 'tenantCode': 'T68', 'testTenant': False,
       'compareTo': 6, 'format': 'json', 'currentVersion': '2.3.1', 'environment': 'PROD', 'ticketRef': 'PT-2026-0412', 'actor': 'nguyen.thi.lan', 'wave': 1, 'core': False,
       'granularity': 'DAY', 'resource': ['API_RPS'], 'updatedSince': '2026-11-01T00:00:00+07:00', 'asOf': '2026-11-27', 'template': False, 'isDataOwner': True, 'reasonType': 'HO_TRO_VAN_HANH',
       'action': ['tenant.status.change'], 'module': 'PH-01', 'type': ['SUSPEND'], 'moduleCode': 'PH-17', 'waveNo': 1, 'scope': 'T68', 'parentCode': 'UBND-TINH', 'adminUnitId': '0193a000-1111-7000-8000-000000000068',
       'view': 'TABLE', 'state': 'OPEN', 'mappingType': 'MEMBER_SYSTEM', 'include': ['summary', 'config'], 'access': 'READ', 'alertLevel': 'WARN_80', 'requestType': ['SUSPEND']}


def err_set(row, opts, has_body, method, has_q, ifm, idem):
    i = row['id']
    base = set()
    for fr in row['frs']:
        base |= set(FRERR.get(fr, []))
    keep = {e for e in base if ERR.get(e, {}).get('http')}
    keep -= {'ERR-20-101', 'ERR-20-102', 'ERR-20-103', 'ERR-20-104', 'ERR-20-105', 'ERR-20-114'}
    internal = row['path'].startswith('/internal/')
    if method == 'get':
        keep = {e for e in keep if ERR[e]['http'] in (400, 404, 410, 503) and e != 'ERR-20-004'}
    if internal:
        keep = {e for e in keep if e in ('ERR-20-002', 'ERR-20-062')}
    if '{' in row['path']:
        keep.add('ERR-20-002')
    if has_body or has_q:
        keep.add('ERR-20-004')
    if method != 'get' and not internal:
        if idem:
            keep.add('ERR-20-009')
        if ifm:
            keep.add('ERR-20-005')
        if row['path'].startswith('/api/platform/v1/tenants/{tenantCode}') and has_body or i in (23, 22, 65, 66, 67, 68):
            keep.add('ERR-20-010')
        if has_body and 'ReasonTicket' in (O[i][0],) or O[i][0] in ('TenantUpdate', 'PlatformConfigUpdate', 'QuotaSetRequest', 'QuotaChangeCreate', 'OverrideCreate', 'ContactUpdate', 'ContractUpdate', 'FlagSetRequest', 'CompensateRequest', 'SkipStepRequest'):
            keep.add('ERR-20-008')
        if re.search(r':[a-z-]+$', row['path']) and i not in (5, 6, 171, 33, 166, 167, 168):
            keep.add('ERR-20-006')
    if row['path'].startswith('/api/tenant/v1') and method != 'get' and i != 142:
        keep.add('ERR-20-001')
    keep |= set(ERR_ADD.get(i, []))
    keep -= set(ERR_DROP.get(i, []))
    keep = {e for e in keep if ERR.get(e, {}).get('http')}
    return sorted(keep)


def problem_example(status, code, title, path):
    return {'type': f'https://datahub.example.vn/errors/{code}', 'title': title, 'status': status, 'code': code, 'traceId': '4bf92f3577b34da6a3ce929d0e0e4736',
            'detail': sample_msg(code) or (title + '.'), 'instance': path}


def build():
    ops = []
    for row in CAT:
        i = row['id']
        method, path = row['method'], row['path']
        reqn, resn, st, qs, opts = O[i]
        grp = group_of(row)
        perm, scopes, scheme = perm_of(row)
        summary = row['desc'].split(';')[0].strip()
        idem = method == 'post' and not opts.get('noidem')
        ifm = method in ('put', 'patch') or i in IFM_POST
        op = {'tags': [tag_of(i)], 'operationId': operation_id(method, path, i), 'summary': summary}
        desc = NOTES.get(i)
        if not desc:
            desc = row['desc'].rstrip('.') + '.'
            if ifm:
                desc += ' Cần `If-Match` theo `ETag` đã đọc.'
        elif False:
            pass
        if i in (137, 139):
            desc += ' Vai trò SO và AU của tỉnh đọc được (không ghi).'
        if i == 161:
            desc += ' Vai trò TA và AU của tỉnh đọc được.'
        op['description'] = desc
        op['x-datahub-id'] = f'API-20-{i:03d}'
        op['x-datahub-fr'] = [f'FR-20-{f:03d}' for f in row['frs']]
        op['x-datahub-permission'] = perm
        op['security'] = [{scheme: scopes}]
        if idem:
            op['x-datahub-idempotent'] = 'required'
        # tham số
        params = []
        for name in re.findall(r'\{(\w+)\}', path):
            params.append({'$ref': '#/components/parameters/' + name[:1].upper() + name[1:]})
        pg = resn.endswith('Page') or resn in ('MappingPage', 'ProvisioningMetrics')
        params += q_params(qs, pg, opts.get('maxsize', 200))
        params.append({'$ref': '#/components/parameters/Traceparent'})
        if idem:
            params.append({'$ref': '#/components/parameters/IdempotencyKey'})
        if ifm:
            params.append({'$ref': '#/components/parameters/IfMatch'})
        op['parameters'] = params
        # thân yêu cầu
        if reqn != '-':
            if reqn == 'OrgImportUpload':
                ex = {'file': 'to-chuc.xlsx', 'mode': 'UPSERT'}
                content = {'multipart/form-data': {'schema': {'$ref': '#/components/schemas/OrgImportUpload'}, 'encoding': {'file': {'contentType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, text/csv'}}, 'example': ex}}
            else:
                ex = ex_of(reqn)
                ex = {k: v for k, v in {**ex, **REQ_EX.get(i, {})}.items() if v is not None}
                content = {'application/json': {'schema': {'$ref': '#/components/schemas/' + reqn}, 'example': ex}}
            op['requestBody'] = {'required': not opts.get('opt_body', False), 'content': content}
        # phản hồi
        resp = {}
        headers = {}
        if resn in ETAG_RES:
            headers['ETag'] = {'description': 'Phiên bản của đối tượng để dùng cho `If-Match`.', 'schema': {'type': 'string'}, 'example': 'W/"3"'}
        if st == 201:
            headers['Location'] = {'description': 'Đường dẫn của đối tượng vừa tạo.', 'schema': {'type': 'string'}, 'example': 'Location-placeholder'}
        okdesc = {200: 'Thành công.', 201: 'Đã tạo.', 202: 'Đã nhận, xử lý bất đồng bộ.'}[st]
        if resn == 'SSE':
            content = {'text/event-stream': {'schema': {'type': 'string'}, 'example': 'id: 17\nevent: step-changed\ndata: {"stepCode":"S06_EVENTING","status":"WAITING_REPORT"}\n\n'}}
            headers = {}
        elif resn == 'FILE':
            if opts.get('file') == 'usage':
                content = {m: {'schema': {'type': 'string', 'format': 'binary'}} for m in ('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/csv', 'application/pdf')}
            else:
                content = {m: {'schema': {'type': 'string', 'format': 'binary'}} for m in ('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/csv')}
            headers = {'Content-Disposition': {'description': 'Tên tệp tải về.', 'schema': {'type': 'string'}, 'example': 'attachment; filename="tep-xuat.xlsx"'}}
        else:
            ex = ex_of(resn)
            for k, v in RES_EX.get(i, {}).items():
                if v is None:
                    ex.pop(k, None)
                else:
                    ex[k] = v
            content = {'application/json': {'schema': {'$ref': '#/components/schemas/' + resn}, 'example': ex}}
            if i == 1:
                content['text/csv'] = {'schema': {'type': 'string'}, 'example': 'tenantCode,name,status\nT68,Tỉnh Lâm Viên (giả định),ACTIVE\n'}
        r = {'description': okdesc, 'content': content}
        if st == 202:
            headers['Location'] = {'description': 'Đường dẫn để theo dõi tiến độ.', 'schema': {'type': 'string'}, 'example': 'Location-placeholder'}
        if headers:
            r['headers'] = headers
        resp[str(st)] = r
        errs = err_set(row, opts, reqn != '-', method, bool(qs), ifm, idem)
        https = {401, 403}
        for e in errs:
            https.add(ERR[e]['http'])
        if ifm and not row['path'].startswith('/internal'):
            https.add(428)
        for h in sorted(https):
            resp[str(h)] = {'$ref': '#/components/responses/' + CODE_HTTP[h]}
        op['responses'] = resp
        errs_out = list(errs) + (['ERR-00-428'] if ifm else [])
        op['x-datahub-errors'] = errs_out
        ops.append((row, op, grp, resn, st))
    return ops


def location(op_row, resn):
    """Ví dụ tiêu đề Location, dựng từ đường dẫn và ví dụ phản hồi."""
    path = op_row['path']
    ex = ex_of(resn) if resn in SCH and 'properties' in SCH[resn] else {}
    p = re.sub(r'\{(\w+)\}', lambda m: str(PATH_EXAMPLE.get(m.group(1), 'x')), path)
    ident = {'Tenant': 'tenantCode', 'Contact': 'contactId', 'Contract': 'contractId', 'ProvisioningRun': 'runId', 'TemplateVersion': 'version', 'Cluster': 'clusterCode',
             'LifecycleRequest': 'requestId', 'QuotaChangeRequest': 'requestId', 'QuotaOverride': 'overrideId', 'ExportPackage': 'packageId', 'MergePlan': 'mergePlanId',
             'Release': 'releaseVersion', 'UpgradePlan': 'planId', 'Organization': 'orgCode', 'LeakTestRun': 'testRunId', 'UsageReport': 'reportId', 'OrgImportJob': 'importId',
             'SupplementPlan': 'planId', 'SmokeRun': 'runId', 'DedicatedBundle': 'bundleId', 'ReconcileResult': 'reconcileId', 'TenantModule': 'moduleCode', 'ConfigVersion': 'versionNo',
             'ConfigDrift': 'driftId', 'TenantUpgrade': 'tenantCode', 'MergeParticipantRun': 'module', 'AnnounceResult': 'announcementId'}.get(resn)
    if op_row['method'] == 'post' and not re.search(r':[a-z-]+$', path) and ident and ex.get(ident) is not None:
        return p + '/' + str(ex[ident])
    return p


PATH_EXAMPLE = {k: (FEX.get(v[1]) if v[1] in FEX else v[1]) if v[1] else (FEX.get(k) or default_ex(v[0], k)) for k, v in PATH_EX.items()}
PATH_EXAMPLE['tenantCode'] = 'T68'
PATH_EXAMPLE['moduleCode'] = 'PH-17'
PATH_EXAMPLE['templateCode'] = 'tinh-chuan'
PATH_EXAMPLE['orgCode'] = 'SO-KHCN'


def used_schemas(node, acc):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == '$ref' and isinstance(v, str) and v.startswith('#/components/schemas/'):
                n = v.rsplit('/', 1)[1]
                if n not in acc:
                    acc.add(n)
                    used_schemas(SCH[n], acc)
            else:
                used_schemas(v, acc)
    elif isinstance(node, list):
        for x in node:
            used_schemas(x, acc)


def components(ops, grp_set):
    params = {
        'Traceparent': {'name': 'traceparent', 'in': 'header', 'required': False, 'description': 'Ngữ cảnh truy vết W3C.', 'schema': {'type': 'string'}, 'example': '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'},
        'IdempotencyKey': {'name': 'Idempotency-Key', 'in': 'header', 'required': True, 'description': 'Khóa chống trùng (UUID), giữ 24 giờ; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-20-009.',
                           'schema': {'type': 'string', 'format': 'uuid'}, 'example': '0193c2a0-7000-7000-8000-000000000001'},
        'IfMatch': {'name': 'If-Match', 'in': 'header', 'required': True, 'description': 'Giá trị `ETag` đã đọc; lệch trả `412` ERR-20-005, thiếu trả `428` ERR-00-428.', 'schema': {'type': 'string'}, 'example': 'W/"3"'},
    }
    paths_used = set()
    for row, op, grp, resn, st in ops:
        for name in re.findall(r'\{(\w+)\}', row['path']):
            paths_used.add(name)
    for name in sorted(paths_used):
        t, exv = PATH_EX[name]
        sch = parse_type(t)
        p = {'name': name, 'in': 'path', 'required': True, 'description': PATH_DESC.get(name, f'Mã `{name}`.'), 'schema': sch, 'example': PATH_EXAMPLE[name]}
        params[name[:1].upper() + name[1:]] = p
    used_refs = set(re.findall(r"'#/components/responses/(\w+)'", repr([op for _, op, _, _, _ in ops])))
    used_par = set(re.findall(r"'#/components/parameters/(\w+)'", repr([op for _, op, _, _, _ in ops])))
    params = {k: v for k, v in params.items() if k in used_par}
    resps = {}
    for h, n in CODE_HTTP.items():
        if n not in used_refs:
            continue
        d, code, title = RESP_DEF[h]
        resps[n] = {'description': d, 'content': {'application/problem+json': {'schema': {'$ref': '#/components/schemas/Problem'}, 'example': problem_example(h, code, title, '/api/platform/v1/tenants/T68')}}}
    acc = set()
    used_schemas([op for _, op, _, _, _ in ops], acc)
    used_schemas(params, acc)
    acc.add('Problem')
    used_schemas(SCH['Problem'], acc)
    schemas = {n: copy.deepcopy(SCH[n]) for n in sorted(acc)}
    sec = {}
    if 'oauth2User' in grp_set:
        scopes = {}
        for _, op, _, _, _ in ops:
            for s in (op['security'][0].get('oauth2User') or []):
                scopes[s] = 'Quyền chức năng ' + s + ' do Keycloak cấp qua vai trò (D02-08).'
        sec['oauth2User'] = {'type': 'oauth2', 'description': 'Người dùng đăng nhập OIDC (WebAuthn cho vai trò nền tảng), tenant lấy từ token (claim `tenant`); không nhận mã tenant từ thân yêu cầu.',
                             'flows': {'authorizationCode': {'authorizationUrl': 'https://sso.datahub.example.vn/realms/dh-platform/protocol/openid-connect/auth',
                                                             'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-platform/protocol/openid-connect/token', 'scopes': dict(sorted(scopes.items()))}}}
    if 'oauth2Service' in grp_set:
        sec['oauth2Service'] = {'type': 'oauth2', 'description': 'Tài khoản máy của phân hệ khác (client credentials, mTLS trong mesh, ADR-006).',
                                'flows': {'clientCredentials': {'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-platform/protocol/openid-connect/token',
                                                                'scopes': {'tenant:registry-read': 'Đọc registry tenant, cấu hình thực thi, chính sách liên tenant.', 'tenant:org-read': 'Đọc tổ chức của tenant ngữ cảnh.',
                                                                           'tenant:provision-report': 'Báo tiến độ bước saga, chuyển sáp nhập, xuất gói bàn giao.'}}}}
    return {'securitySchemes': sec, 'parameters': params, 'responses': resps, 'schemas': schemas}


TAGDESC = {
    'Hồ sơ tenant': 'Khai báo, xem, sửa hồ sơ hành chính, kiểm tra sẵn sàng (nhóm A).', 'Đầu mối và hợp đồng': 'Đầu mối và hợp đồng dịch vụ của tenant (FR-20-005).',
    'Saga khởi tạo': 'Chạy, theo dõi, thử lại, bù trừ, kiểm tra khói, kích hoạt (nhóm B).', 'Mẫu khởi tạo và khởi tạo bổ sung': 'Mẫu khởi tạo có phiên bản và đợt bổ sung (FR-20-015, 016).',
    'Cụm riêng': 'Cụm đích `DEDICATED_CLUSTER` (FR-20-017).', 'Cấu hình tenant': 'Cấu hình nền tảng, phiên bản GitOps, lệch cấu hình, đổi chế độ cách ly (nhóm C).',
    'Hạn mức và sử dụng': 'Hạn mức hợp đồng, đề nghị đổi, ghi đè, sử dụng, cảnh báo, báo cáo (nhóm D).', 'Phân hệ và tính năng': 'Danh mục phân hệ, bật tắt phân hệ, cờ tính năng (nhóm E).',
    'Vòng đời tenant': 'Tạm ngừng, khôi phục, chấm dứt, gói bàn giao, lịch sử (nhóm F).', 'Sáp nhập tenant': 'Kế hoạch, ánh xạ, chuyển dữ liệu, xung đột, cutover (nhóm G).',
    'Phát hành sản phẩm': 'Phiên bản, kênh, kế hoạch nâng cấp theo sóng (nhóm I).', 'Quản trị nền tảng': 'Bảng điều khiển, kiểm toán, tham số, kiểm thử rò rỉ (nhóm J).',
    'Cài đặt và ngữ cảnh tỉnh': 'Cài đặt, chính sách liên tenant, sử dụng, ngữ cảnh của tỉnh (`/api/tenant/v1`).', 'Tổ chức': 'Danh mục tổ chức của tỉnh (nhóm H).',
    'Phiên bản và kiểm toán của tỉnh': 'Phiên bản, bảo trì, kiểm toán của tỉnh.', 'Registry tenant': 'Registry và cấu hình thực thi cho phân hệ khác (`/internal`).',
    'Báo tiến độ': 'Phân hệ báo tiến độ bước saga, sáp nhập, xuất gói (`/internal`).', 'Đọc tổ chức': 'API đọc tổ chức cho phân hệ khác (`/internal`).'}

INFO = {
    'platform': ('Datahub · PH-20 Quản trị nền tảng', 'Nhóm `/api/platform/v1`: tenant, saga, hạn mức, phân hệ, vòng đời, sáp nhập, phát hành, quản trị nền tảng. Chỉ vai trò nền tảng, không mở ra cổng công khai.'),
    'tenant': ('Datahub · PH-20 Quản trị tỉnh', 'Nhóm `/api/tenant/v1`: cài đặt tỉnh, tổ chức, sử dụng, phiên bản của chính tenant gọi (tenant lấy từ token).'),
    'internal': ('Datahub · PH-20 API nội bộ', 'Nhóm `/internal/tenant/v1`: registry, tổ chức, báo tiến độ cho phân hệ khác; chỉ trong mesh, scope dịch vụ.'),
    'all': ('Datahub · PH-20 Quản trị tenant và phát hành sản phẩm', 'Gộp ba nhóm `/api/platform/v1` (134 operation), `/api/tenant/v1` (27) và `/internal/tenant/v1` (10).'),
}
SERVERS = {
    'platform': [{'url': 'https://nen-tang.datahub.example.vn', 'description': 'Console nền tảng qua BFF và cổng quản trị (giả lập); chỉ tenant `PLATFORM`.'}],
    'tenant': [{'url': 'https://console.{tenantHost}.datahub.example.vn', 'description': 'Console của tỉnh qua BFF (giả lập).', 'variables': {'tenantHost': {'default': 't68', 'description': 'Ví dụ `t68` (giả lập).'}}}],
    'internal': [{'url': 'http://dh-platform.dh-control.svc:8080', 'description': 'Trong mesh `dh-control`; mTLS và scope dịch vụ, không qua cổng công khai.'}],
}


def make_doc(ops, which):
    grp_set = {op['security'][0] and list(op['security'][0].keys())[0] for _, op, _, _, _ in ops}
    tags = []
    seen = []
    for _, op, _, _, _ in ops:
        t = op['tags'][0]
        if t not in seen:
            seen.append(t)
    tags = [{'name': t, 'description': TAGDESC[t]} for t in seen]
    title, desc = INFO[which]
    servers = SERVERS['platform'] + SERVERS['tenant'] + SERVERS['internal'] if which == 'all' else SERVERS[which]
    if which == 'all':
        servers = SERVERS['platform'] + SERVERS['tenant'] + SERVERS['internal']
    paths = {}
    for row, op, grp, resn, st in ops:
        op = copy.deepcopy(op)
        paths.setdefault(row['path'], {})[row['method']] = op
        # Location
        for code in ('201', '202'):
            r = op['responses'].get(code)
            if r and r.get('headers', {}).get('Location'):
                r['headers']['Location']['example'] = location(row, resn)
    comps = components(ops, grp_set)
    first = list(grp_set)[0]
    doc = {
        'openapi': '3.1.0',
        'info': {'title': title, 'version': '0.2.0-draft', 'summary': 'Hợp đồng REST của PH-20 Quản trị tenant và phát hành sản phẩm (D03-04-PH20).',
                 'description': desc + '\n\nQuy ước (D03-04-PH20 chương 1, 2): tenant lấy từ token, không từ thân hay đường dẫn (trừ API nền tảng nêu `tenantCode` của tenant bị tác động); `POST` nhận `Idempotency-Key`; `PUT`, `PATCH` và hành động trên đối tượng có phiên bản nhận `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 `application/problem+json` mã `ERR-20-nnn`; phân trang `page`, `size`. Mọi tên miền, mã, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.',
                 'contact': {'name': 'Nhóm phân hệ PH-20'}, 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)', 'identifier': 'LicenseRef-Datahub-Internal'},
                 'x-datahub-document': 'D03-04-PH20', 'x-datahub-phase': 'PH-20'},
        'servers': servers, 'tags': tags, 'paths': paths, 'components': comps,
    }
    if which != 'all':
        doc['security'] = [{first: []}]
    return doc


def dump(doc, name, head):
    out = os.path.join(ROOT, name)
    with open(out, 'w', encoding='utf-8') as f:
        f.write(head + '\n')
        yaml.dump(doc, f, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160, default_flow_style=False)
    print(name, len(doc['paths']), 'đường dẫn,', sum(len(v) for v in doc['paths'].values()), 'operation')


def main():
    ops = build()
    head = '# D03-04-PH20 · OpenAPI PH-20 (module tenant và release của dh-platform). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.'
    for which, fn in (('platform', 'openapi-platform.yaml'), ('tenant', 'openapi-tenant.yaml'), ('internal', 'openapi-internal.yaml')):
        sub = [x for x in ops if x[2] == which]
        dump(make_doc(sub, which), fn, head)
    dump(make_doc(ops, 'all'), 'openapi-ph20.yaml', head + ' Tệp gộp ba nhóm.')


if __name__ == '__main__':
    main()
