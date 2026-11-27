"""Khung DSL lược đồ cho bộ sinh OpenAPI và AsyncAPI của PH-20 (dùng chung bởi spec.py, gen_openapi.py, gen_asyncapi.py).

Trường khai báo bằng chuỗi `ten[!]:kieu` hoặc bộ ba (`ten[!]:kieu`, ví dụ, ràng buộc). Dấu `!` là bắt buộc.
Kiểu: str int num bool ts date uuid obj map:int map:num map:bool; mã chuẩn (tc, code, mod, ocode, email, ver, sha, period, url);
E:TênLiệtKê; R:TênLượcĐồ; hậu tố [] là mảng. Ví dụ lấy theo thứ tự: bộ ba, bảng FEX theo tên trường, mặc định theo kiểu."""
import copy
import re

ENUMS = {}
SCH = {}
EX = {}      # ví dụ ghi đè theo lược đồ (tên trường -> giá trị)
DESC = {}    # mô tả theo trường: (lược đồ, trường)

T0 = '2026-11-27T09:15:00+07:00'
UUID0 = '0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01'
SHA0 = '0123456789abcdef' * 4

TYPES = {
    'str': ({'type': 'string'}, 'Nội dung'),
    'int': ({'type': 'integer'}, 1),
    'num': ({'type': 'number'}, 1.5),
    'bool': ({'type': 'boolean'}, True),
    'ts': ({'type': 'string', 'format': 'date-time'}, T0),
    'date': ({'type': 'string', 'format': 'date'}, '2026-11-27'),
    'uuid': ({'type': 'string', 'format': 'uuid'}, UUID0),
    'obj': ({'type': 'object', 'additionalProperties': True}, {}),
    'tc': ({'type': 'string', 'pattern': r'^T[0-9]{2}$', 'description': 'Mã tenant dạng `T` và hai chữ số.'}, 'T68'),
    'code': ({'type': 'string', 'pattern': r'^[a-z][a-z0-9-]{2,62}$'}, 'tinh-chuan'),
    'mod': ({'type': 'string', 'pattern': r'^PH-[0-9]{2}$', 'description': 'Mã phân hệ dạng `PH-nn`.'}, 'PH-17'),
    'ocode': ({'type': 'string', 'pattern': r'^[A-Z0-9][A-Z0-9-]{1,49}$'}, 'SO-KHCN'),
    'email': ({'type': 'string', 'format': 'email'}, 'cong-vu@t68.example.vn'),
    'ver': ({'type': 'string', 'pattern': r'^[0-9]+\.[0-9]+\.[0-9]+$', 'description': 'Phiên bản theo SemVer.'}, '2.4.0'),
    'sha': ({'type': 'string', 'pattern': r'^[0-9a-f]{64}$'}, SHA0),
    'period': ({'type': 'string', 'pattern': r'^(M-[0-9]{4}-[0-9]{2}|Q-[0-9]{4}-Q[1-4]|Y-[0-9]{4})$'}, 'M-2026-10'),
    'url': ({'type': 'string', 'format': 'uri'}, 'https://nen-tang.datahub.example.vn/tai-ve/goi-t68'),
    'bin': ({'type': 'string', 'format': 'binary'}, 'to-chuc.xlsx'),
}

# ví dụ mặc định theo tên trường
FEX = {
    'reason': 'Theo biên bản họp của Ban điều hành ngày 20/11/2026.',
    'reasonText': 'Theo quyết định của lãnh đạo UBND tỉnh về việc tạm ngừng dịch vụ.',
    'ticketRef': 'PT-2026-0412', 'comment': 'Đồng ý theo hồ sơ đính kèm.',
    'name': 'Tỉnh Lâm Viên (giả định)', 'note': 'Tỉnh thí điểm đợt 2.',
    'createdAt': T0, 'updatedAt': T0, 'createdBy': 'nguyen.thi.lan', 'updatedBy': 'nguyen.thi.lan',
    'requestedBy': 'nguyen.thi.lan', 'approvedBy': 'tran.van.nam', 'actor': 'nguyen.thi.lan',
    'requestedAt': T0, 'approvedAt': T0, 'decidedBy': 'tran.van.nam',
    'tenantCode': 'T68', 'sourceTenant': 'T90', 'targetTenant': 'T91', 'targetTenant_': 'T90',
    'adminUnitId': '0193a000-1111-7000-8000-000000000068', 'decisionFileId': '0193a000-1111-7000-8000-000000000069',
    'fileId': '0193a000-1111-7000-8000-000000000070', 'logoFileId': '0193a000-1111-7000-8000-000000000071',
    'handoverDocFileId': '0193a000-1111-7000-8000-000000000072',
    'runId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e01', 'requestId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e02',
    'packageId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e03', 'planId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e04',
    'reportId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e05', 'alertId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e06',
    'overrideId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e07', 'contactId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e08',
    'contractId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e09', 'driftId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0a',
    'conflictId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0b', 'mappingId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0c',
    'importId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0d', 'proposalId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0e',
    'testRunId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0f', 'bundleId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e10',
    'tenantId': '0193a000-1111-7000-8000-000000000001', 'eventId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e11',
    'traceId': '4bf92f3577b34da6a3ce929d0e0e4736', 'announcementId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e12',
    'mergePlanId': 'SN-2026-001', 'releaseVersion': '2.4.0', 'currentVersion': '2.3.1', 'minFromVersion': '2.2.0',
    'templateCode': 'tinh-chuan', 'clusterCode': 'cl-t68-onprem', 'moduleCode': 'PH-17', 'flagCode': 'ph04.sql-direct',
    'orgCode': 'SO-KHCN', 'parentCode': 'UBND-TINH', 'successorCode': 'SO-TTTT', 'electronicId': 'H68.07',
    'decisionDocNo': '1234/QĐ-TTg', 'decisionDocDate': '2026-10-15', 'effectiveFrom': '2025-07-01', 'effectiveDate': '2026-12-15',
    'realm': 'dh-t68', 'publicHost': 'api.t68.datahub.example.vn', 'apiPathPrefix': '/t68', 'drRegion': 'dr-mien-nam',
    'supportContactEmail': 'ho-tro@t68.example.vn', 'officialEmail': 'nguyen.thi.lan@t68.example.vn', 'recipientEmail': 'nguyen.thi.lan@t68.example.vn',
    'fullName': 'Nguyễn Thị Lan', 'position': 'Giám đốc Sở Khoa học và Công nghệ', 'phone': '0912345678', 'hotline': '1900123456',
    'contractNo': 'HĐ-15/2026/DH', 'contractRef': 'HĐ-15/2026/DH', 'title': 'Hợp đồng dịch vụ Datahub năm 2026',
    'displayName': 'Datahub tỉnh T68', 'itOwnerOrgCode': 'SO-KHCN', 'rdmPackageVersion': '2026.11', 'kpiSetVersion': '2026.1',
    'commitSha': 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678', 'git_commit': 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678',
    'contentHash': SHA0, 'manifestSha256': SHA0, 'sha256': SHA0, 'digest': 'sha256:' + SHA0, 'mappingHash': SHA0,
    'image': 'registry.datahub.example.vn/dh/dh-platform:2.4.0', 'chartVersion': '2.4.0', 'duCode': 'dh-platform',
    'du': 'dh-platform', 'module': 'PH-01', 'confirmTenantCode': 'T68', 'confirmCode': 'SN-2026-001',
    'startTime': '22:00', 'timezone': 'Asia/Ho_Chi_Minh', 'rrule': 'FREQ=WEEKLY;BYDAY=SA',
    'locale': 'vi-VN', 'message': 'Nâng cấp phiên bản 2.4.0 vào đêm thứ Bảy, dự kiến 4 giờ.', 'detail': 'Xem chi tiết ở sổ bước.',
    'period': 'M-2026-10', 'scope': 'T68', 'resource': 'API_RPS', 'unit': 'req/s', 'q': 'lam vien',
    'secretRef': 'kv/dh/platform/clusters/cl-t68-onprem', 'apiEndpoint': 'https://api.cl-t68.example.vn:6443',
    'argoCdEndpoint': 'https://argocd.cl-t68.example.vn', 'ownerTenant': 'T68', 'checkCode': 'CODE_UNIQUE',
    'errorCode': 'ERR-20-107', 'errorMessage': 'Bên thực hiện báo lỗi ở bước này.', 'outputRef': 'kv/dh/t68/realm',
    'downloadUrl': 'https://nen-tang.datahub.example.vn/tai-ve/goi-t68', 'newClientId': 'httt-qlvb-t90-m1',
    'memberSystemCode': 'httt-qlvb', 'sourceCode': 'httt-qlvb', 'targetCode': 'httt-qlvb', 'newCode': 'httt-qlvb-t91',
    'dedupe': 1, 'deliveredTo': 'Văn phòng UBND tỉnh T68', 'cluster': 'dh-control', 'environment': 'PROD',
    'ruleName': 'rule-1', 'apiCode': 'API-20-003', 'method': 'GET', 'path': '/api/platform/v1/tenants/T91',
    'page': 0, 'size': 20, 'totalElements': 1, 'httpStatus': 404, 'result': 'PASS', 'action': 'tenant.status.change',
    'objectType': 'tenant', 'objectId': 'T68', 'actorRole': 'ROLE-PLATFORM_ADMIN', 'status_': 'ACTIVE',
    'paramName': '20.quota.warn-percent', 'defaultValue': 80, 'effectiveValue': 500, 'domain': '50…95',
    'usedBy': 'FR-20-029', 'description': 'Mô tả ngắn của đối tượng.', 'detail_': '',
    'version': 1, 'attempt': 1, 'attempts': 1, 'order': 1, 'durationSeconds': 42, 'durationMs': 850,
}

PAGE_FIELDS = [('page!:int', 0, {'minimum': 0}), ('size!:int', 20, {'minimum': 1, 'maximum': 200}), ('totalElements!:int', 1, {'minimum': 0})]


def parse_type(t):
    arr = t.endswith('[]')
    if arr:
        t = t[:-2]
    if t.startswith('E:'):
        base = {'$ref': '#/components/schemas/' + t[2:]}
    elif t.startswith('R:'):
        base = {'$ref': '#/components/schemas/' + t[2:]}
    elif t.startswith('map:'):
        base = {'type': 'object', 'additionalProperties': {'type': {'int': 'integer', 'num': 'number', 'bool': 'boolean', 'str': 'string'}[t[4:]]}}
    elif t in TYPES:
        base = copy.deepcopy(TYPES[t][0])
    else:
        raise KeyError(t)
    return {'type': 'array', 'items': base} if arr else base


def default_ex(t, name):
    arr = t.endswith('[]')
    b = t[:-2] if arr else t
    if b.startswith('E:'):
        v = ENUMS[b[2:]][0]
    elif b.startswith('R:'):
        v = ('REF', b[2:])
    elif b.startswith('map:'):
        v = {'A': 1}
    else:
        v = TYPES[b][1]
    return [v] if arr else v


def enum(name, desc, *vals):
    ENUMS[name] = list(vals)
    SCH[name] = {'type': 'string', 'enum': list(vals), 'description': desc}


def obj(name, desc, *fields, ex=None, extra=False, one_of=None):
    props, req, exs = {}, [], {}
    for f in fields:
        if isinstance(f, str):
            f = (f,)
        spec = f[0]
        m = re.match(r'^([A-Za-z0-9_]+)(!?):(.+)$', spec)
        fname, rq, ftype = m.group(1), m.group(2) == '!', m.group(3)
        p = parse_type(ftype)
        cons = f[2] if len(f) > 2 else {}
        for k, v in cons.items():
            if p.get('type') == 'array' and k not in ('minItems', 'maxItems', 'uniqueItems', 'description'):
                p['items'][k] = v
            else:
                p[k] = v
        if len(f) > 1 and f[1] is not None:
            exs[fname] = f[1]
        elif fname in FEX and not (ftype.rstrip('[]').startswith('E:') and FEX[fname] not in ENUMS[ftype.rstrip('[]')[2:]]) and not ftype.startswith('R:'):
            exs[fname] = FEX[fname]
        else:
            exs[fname] = default_ex(ftype, fname)
        if ftype == 'ts' and isinstance(exs[fname], str) and re.fullmatch(r'\d{4}-\d\d-\d\d', exs[fname]):
            exs[fname] += 'T00:00:00+07:00'
        if ftype == 'date' and isinstance(exs[fname], str) and re.fullmatch(r'\d{4}-\d\d-\d\dT.*', exs[fname]):
            exs[fname] = exs[fname][:10]
        # nếu ví dụ lấy từ FEX nhưng trường là mảng, bọc mảng
        if ftype.endswith('[]') and not isinstance(exs[fname], list):
            exs[fname] = [exs[fname]]
        if ftype.startswith('R:') or ftype == 'obj' or ftype == 'obj[]':
            if ftype == 'obj' and (len(f) < 2 or f[1] is None) and fname not in FEX:
                exs[fname] = {}
        props[fname] = p
        if rq:
            req.append(fname)
    s = {'type': 'object', 'description': desc, 'properties': props}
    if req:
        s['required'] = req
    if ex:
        exs.update(ex)
    SCH[name] = s
    EX[name] = exs
    return s


def page(item, name=None, *extra):
    name = name or item + 'Page'
    obj(name, f'Trang `{item}`.', ('items!:R:' + item + '[]',), *PAGE_FIELDS, *extra)
    return name


def ex_of(name, depth=0):
    s = SCH[name]
    if 'enum' in s:
        return s['enum'][0]
    if 'properties' not in s:
        return None
    out = {}
    for k, p in s['properties'].items():
        if k not in EX[name]:
            continue
        v = EX[name][k]
        if v is None:
            continue
        out[k] = resolve(v, depth)
    return out


def resolve(v, depth=0):
    if isinstance(v, tuple) and len(v) == 2 and v[0] == 'REF':
        return ex_of(v[1], depth + 1)
    if isinstance(v, list):
        return [resolve(x, depth) for x in v]
    if isinstance(v, dict):
        return {k: resolve(x, depth) for k, x in v.items()}
    return v
