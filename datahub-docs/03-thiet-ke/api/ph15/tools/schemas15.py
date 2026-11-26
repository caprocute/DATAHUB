"""Lược đồ và ví dụ dùng chung của OpenAPI PH-15 (D03-04-PH15). Dữ liệu ví dụ là giả lập: tenant T68, HTTT cung cấp HT-TUPHAP,
HTTT khai thác HT-DATDAI, nhà phát triển nguyen.van.an."""

SCH = {}   # tên -> lược đồ JSON Schema 2020-12
EX = {}    # tên ví dụ -> giá trị

_B = {'s': 'string', 'i': 'integer', 'b': 'boolean', 'n': 'number'}


def T(x):
    """Viết tắt kiểu: 's', 'i', 'b', 'n', 'ts' (date-time), 'o' (đối tượng tự do), 's:uri', '#Ten' ($ref), '[X]' mảng, list = enum chuỗi."""
    if isinstance(x, dict):
        return x
    if isinstance(x, list):
        return {'type': 'string', 'enum': x}
    if x.startswith('#'):
        return {'$ref': '#/components/schemas/' + x[1:]}
    if x.startswith('['):
        return {'type': 'array', 'items': T(x[1:-1])}
    if x == 'ts':
        return {'type': 'string', 'format': 'date-time'}
    if x == 'o':
        return {'type': 'object', 'additionalProperties': True}
    base, _, fmt = x.partition(':')
    r = {'type': _B[base]}
    if fmt:
        r['format'] = fmt
    return r


def obj(props, req=None, desc=None, free=False):
    r = {'type': 'object', 'properties': {k: T(v) for k, v in props.items()}}
    if req:
        r['required'] = list(req)
    if not free:
        r['additionalProperties'] = False
    if desc:
        r['description'] = desc
    return r


def d(name, props, req=None, ex=None, desc=None, free=False):
    SCH[name] = obj(props, req if req is not None else list(props)[:0], desc, free)
    if ex is not None:
        EX[name] = ex


def enum(name, vals, desc):
    SCH[name] = {'type': 'string', 'enum': vals, 'description': desc}


def page(item, name=None, ex_items=None, total=None):
    n = name or item + 'Page'
    d(n, {'items': '[#%s]' % item, 'page': 'i', 'size': 'i', 'totalElements': 'i'}, ['items', 'page', 'size', 'totalElements'])
    if ex_items is not None:
        EX[n] = {'items': ex_items, 'page': 1, 'size': 20, 'totalElements': total if total is not None else len(ex_items)}


TRACE = '4bf92f3577b34da6a3ce929d0e0e4736'
TS1 = '2026-11-20T08:15:30Z'
TS2 = '2026-11-26T02:00:00Z'
U1 = '0b5f3c1e-7d2a-4c8e-9a10-3f6e1d2b4a55'
U2 = '7c1d9a42-5b3e-4f60-8d17-2a9c0e5f6b31'
U3 = 'e4a2b6d8-1c3f-4e57-9b08-6d7a8c9e0f12'

# ---- Mã định danh, enum
SCH['ApiCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9-]{2,63}$', 'description': 'Mã API do PH-02 cấp, bất biến.', 'examples': ['tra-cuu-ho-tich']}
SCH['AppCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9-]{2,40}$', 'description': 'Mã ứng dụng sandbox (Phụ lục A.1), bất biến trong tenant.', 'examples': ['app-tra-cuu-ho-tich']}
SCH['PageCode'] = {'type': 'string', 'pattern': '^[a-z0-9][a-z0-9-]{1,62}$', 'description': 'Mã trang nội dung (A.1).', 'examples': ['bat-dau-nhanh']}
SCH['TeamCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9-]{2,40}$', 'description': 'Mã nhóm phát triển (A.1).', 'examples': ['nhom-thau-a']}
SCH['TicketCode'] = {'type': 'string', 'pattern': '^HT-[0-9]{4}-[0-9]{4,}$', 'description': 'Mã phiếu hỗ trợ (A.1).', 'examples': ['HT-2026-0042']}
SCH['TopicCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9.-]{2,120}$', 'description': 'Tên topic sự kiện của PH-10 hiển thị ở cổng.', 'examples': ['ho-tich.khai-sinh.da-dang-ky']}
SCH['SemVer'] = {'type': 'string', 'pattern': '^[0-9]+\\.[0-9]+\\.[0-9]+$', 'description': 'Số phiên bản đặc tả theo SemVer.', 'examples': ['1.0.0']}
SCH['Uuid'] = {'type': 'string', 'format': 'uuid'}
SCH['TraceId'] = {'type': 'string', 'pattern': '^[0-9a-f]{32}$'}
enum('ViewerClass', ['ANONYMOUS', 'TENANT_USER', 'DEV_USER', 'OTHER_TENANT_USER'], 'Hạng người xem (Phụ lục A.2); suy từ phiên BFF, không nhận từ tham số.')
enum('Visibility', ['TENANT', 'NATIONAL', 'PUBLIC'], 'Mức hiển thị do PH-02 giữ.')
enum('DataClass', ['PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE'], 'Nhãn dữ liệu của API.')
enum('ServiceKind', ['API', 'EVENT'], 'Kiểu dịch vụ.')
enum('VersionStatus', ['PUBLISHED', 'DEPRECATED', 'SUSPENDED', 'RETIRED'], 'Trạng thái phiên bản API.')
enum('MemberRole', ['OWNER', 'DEVELOPER', 'VIEWER'], 'Vai trò trên ứng dụng và nhóm.')
enum('OwnerType', ['USER', 'TEAM'], 'Loại chủ ứng dụng.')
enum('AppStatus', ['ACTIVE', 'SUSPENDED', 'ARCHIVED'], 'Trạng thái ứng dụng sandbox.')
enum('CredKind', ['CLIENT_CREDENTIALS', 'API_KEY'], 'Loại thông tin xác thực sandbox.')
enum('CredStatus', ['ACTIVE', 'ROTATING', 'REVOKED', 'EXPIRED'], 'Trạng thái thông tin xác thực sandbox.')
enum('ProdRefStatus', ['ACTIVE', 'EXPIRING', 'REVOKED'], 'Trạng thái tham chiếu thông tin xác thực production.')
enum('ProdMethod', ['tls_client_auth', 'private_key_jwt', 'client_secret_basic'], 'Phương thức xác thực production.')
enum('DevStatus', ['PENDING_EMAIL', 'PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'LOCKED', 'DISABLED', 'EXPIRED', 'ERASED'], 'Trạng thái tài khoản nhà phát triển.')
enum('DevSource', ['TENANT_SSO', 'DH_DEV'], 'Nguồn tài khoản.')
enum('PageType', ['GUIDE', 'QUICKSTART', 'FAQ', 'ANNOUNCEMENT', 'TERMS'], 'Loại trang nội dung.')
enum('Audience', ['PUBLIC', 'LOGGED_IN', 'TENANT'], 'Đối tượng xem trang.')
enum('Lang', ['vi', 'en'], 'Ngôn ngữ.')
enum('PageStatus', ['DRAFT', 'PUBLISHED', 'UNPUBLISHED', 'ARCHIVED'], 'Trạng thái trang.')
enum('PageVersionStatus', ['DRAFT', 'IN_REVIEW', 'REJECTED', 'PUBLISHED', 'SUPERSEDED', 'UNPUBLISHED'], 'Trạng thái phiên bản trang.')
enum('SandboxMode', ['MOCK', 'BACKEND', 'OFF'], 'Chế độ sandbox của một phiên bản API.')
enum('ExamplePolicy', ['FIRST', 'RANDOM'], 'Chính sách chọn ví dụ ở chế độ MOCK.')
enum('TryEnv', ['SANDBOX', 'PRODUCTION'], 'Môi trường thử.')
enum('TryProdState', ['OFF', 'PENDING', 'ENABLED', 'EXPIRED'], 'Trạng thái cho phép thử production.')
enum('TryResultCode', ['OK', 'UPSTREAM_ERROR', 'DENIED', 'THROTTLED', 'TIMEOUT'], 'Kết quả lượt thử.')
enum('TicketKind', ['QUESTION', 'DOC_ERROR', 'SUPPORT_REQUEST', 'ACCESS_REQUEST', 'FEEDBACK'], 'Loại phiếu hỗ trợ.')
enum('TicketStatus', ['OPEN', 'ANSWERED', 'RESOLVED', 'CLOSED'], 'Trạng thái phiếu.')
enum('SyncState', ['IDLE', 'RUNNING', 'FAILED', 'STALE'], 'Trạng thái đồng bộ danh mục.')
enum('Channel', ['IN_APP', 'EMAIL'], 'Kênh thông báo.')
enum('InviteStatus', ['PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED'], 'Trạng thái lời mời.')
enum('SampleLang', ['curl', 'java', 'python', 'javascript', 'csharp', 'go'], 'Ngôn ngữ mẫu mã.')
enum('ExportFormat', ['postman', 'bruno', 'http'], 'Định dạng xuất bộ sưu tập.')
enum('AuthKind', ['OAUTH2', 'MTLS', 'API_KEY'], 'Kiểu xác thực của API.')

# ---- Lỗi RFC 9457
d('FieldError', {'field': 's', 'message': 's', 'rule': 's'}, ['field', 'message'])
d('ProblemDetails', {'type': 's:uri', 'title': 's', 'status': 'i', 'code': {'type': 'string', 'pattern': '^ERR-15-[0-9]{3}$'}, 'detail': 's', 'instance': 's',
                     'traceId': '#TraceId', 'errors': '[#FieldError]', 'retryAfterSeconds': 'i'},
  ['type', 'title', 'status', 'code', 'traceId'], desc='Lỗi theo RFC 9457 (`application/problem+json`); `code` là mã ERR-15-nnn.')

# ---- Nhóm A: danh mục
d('CatalogItemSummary', {'apiCode': '#ApiCode', 'name': 's', 'kind': '#ServiceKind', 'ownerOrg': 's', 'systemCode': 's', 'dataClass': '#DataClass', 'visibility': '#Visibility',
                         'latestVersion': '#SemVer', 'status': '#VersionStatus', 'authKinds': '[#AuthKind]', 'tags': '[s]', 'deprecated': 'b', 'syncedAt': 'ts'},
  ['apiCode', 'name', 'kind', 'ownerOrg', 'dataClass', 'visibility', 'latestVersion', 'status', 'syncedAt'])
CI1 = {'apiCode': 'tra-cuu-ho-tich', 'name': 'Tra cứu hộ tịch', 'kind': 'API', 'ownerOrg': 'Sở Tư pháp', 'systemCode': 'HT-TUPHAP', 'dataClass': 'INTERNAL', 'visibility': 'TENANT',
       'latestVersion': '1.0.0', 'status': 'PUBLISHED', 'authKinds': ['OAUTH2', 'MTLS'], 'tags': ['hộ tịch', 'tư pháp'], 'deprecated': False, 'syncedAt': TS2}
CI2 = dict(CI1, apiCode='xac-thuc-cong-dan', name='Xác thực công dân', systemCode='HT-CONGDAN', ownerOrg='Công an tỉnh', tags=['định danh'], latestVersion='2.1.0')
EX['CatalogItemSummary'] = CI1
page('CatalogItemSummary', 'CatalogItemPage', [CI1, CI2])
d('PlanInfo', {'planCode': 's', 'name': 's', 'quotaPerDay': 'i', 'state': 's'}, ['planCode', 'name'])
d('SlaInfo', {'availabilityPct': 'n', 'p95Ms': 'i', 'supportHours': 's'}, ['availabilityPct', 'p95Ms'])
d('VersionSummary', {'versionNo': '#SemVer', 'status': '#VersionStatus', 'publishedAt': 'ts', 'sunsetAt': 'ts', 'hasSandbox': 'b', 'specKinds': [['OPENAPI', 'ASYNCAPI']] and '[s]'},
  ['versionNo', 'status'])
d('UsageInfo', {'baseUrl': 's:uri', 'tokenUrl': 's:uri', 'scopes': '[s]', 'authKinds': '[#AuthKind]', 'samples': '[#CodeSample]'}, ['baseUrl', 'scopes'])
d('CodeSample', {'lang': '#SampleLang', 'title': 's', 'code': 's'}, ['lang', 'code'])
d('CatalogItemDetail', {'apiCode': '#ApiCode', 'name': 's', 'kind': '#ServiceKind', 'description': 's', 'ownerOrg': 's', 'systemCode': 's', 'dataClass': '#DataClass',
                        'visibility': '#Visibility', 'contactOrg': 's', 'versions': '[#VersionSummary]', 'selectedVersion': '#SemVer', 'plans': '[#PlanInfo]', 'sla': '#SlaInfo',
                        'tags': '[s]', 'syncedAt': 'ts', 'sourceVersion': 'i'},
  ['apiCode', 'name', 'kind', 'description', 'ownerOrg', 'dataClass', 'visibility', 'versions', 'syncedAt'])
CD1 = {'apiCode': 'tra-cuu-ho-tich', 'name': 'Tra cứu hộ tịch', 'kind': 'API', 'description': 'Tra cứu thông tin giấy khai sinh, kết hôn theo số định danh hồ sơ.',
       'ownerOrg': 'Sở Tư pháp', 'systemCode': 'HT-TUPHAP', 'dataClass': 'INTERNAL', 'visibility': 'TENANT', 'contactOrg': 'Sở Tư pháp',
       'versions': [{'versionNo': '1.0.0', 'status': 'PUBLISHED', 'publishedAt': TS1, 'hasSandbox': True, 'specKinds': ['OPENAPI']}],
       'selectedVersion': '1.0.0', 'plans': [{'planCode': 'co-ban', 'name': 'Cơ bản', 'quotaPerDay': 10000, 'state': 'ACTIVE'}],
       'sla': {'availabilityPct': 99.5, 'p95Ms': 400, 'supportHours': '8x5'}, 'tags': ['hộ tịch'], 'syncedAt': TS2, 'sourceVersion': 17}
EX['CatalogItemDetail'] = CD1
EX['CatalogItemDetailPublic'] = dict(CD1, visibility='PUBLIC', dataClass='PUBLIC', plans=[])
SCH['CatalogItemDetail']['properties']['usage'] = T('#UsageInfo')
d('FacetValue', {'value': 's', 'count': 'i'}, ['value', 'count'])
d('CatalogFacets', {'facets': {'type': 'object', 'additionalProperties': {'type': 'array', 'items': T('#FacetValue')}}}, ['facets'])
EX['CatalogFacets'] = {'facets': {'linh-vuc': [{'value': 'tu-phap', 'count': 12}], 'chu-quan': [{'value': 'so-tu-phap', 'count': 9}], 'xac-thuc': [{'value': 'OAUTH2', 'count': 30}]}}
EX['UsageInfo'] = {'baseUrl': 'https://api.t68.datahub.example.vn/tra-cuu-ho-tich/v1', 'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token',
                   'scopes': ['api:tra-cuu-ho-tich:co-ban'], 'authKinds': ['OAUTH2', 'MTLS'],
                   'samples': [{'lang': 'curl', 'title': 'Gọi bằng curl', 'code': 'curl -H "Authorization: Bearer <ACCESS_TOKEN>" https://api.t68.datahub.example.vn/tra-cuu-ho-tich/v1/ho-tich/HT-0001'}]}
d('SyncStatus', {'state': '#SyncState', 'lastSyncAt': 'ts', 'lagSeconds': 'i', 'itemCount': 'i', 'lastRunId': 's'}, ['state', 'lagSeconds', 'itemCount'])
EX['SyncStatus'] = {'state': 'IDLE', 'lastSyncAt': TS2, 'lagSeconds': 12, 'itemCount': 214, 'lastRunId': 'run-20261126-0200'}
d('SearchHit', {'type': ['api', 'huong-dan', 'su-kien'], 'code': 's', 'title': 's', 'snippet': 's', 'score': 'n'}, ['type', 'code', 'title'])
d('SearchResultPage', {'results': '[#SearchHit]', 'page': 'i', 'size': 'i', 'totalElements': 'i'}, ['results', 'page', 'size', 'totalElements'])
EX['SearchResultPage'] = {'results': [{'type': 'api', 'code': 'tra-cuu-ho-tich', 'title': 'Tra cứu hộ tịch', 'snippet': 'Tra cứu giấy **khai sinh**, kết hôn theo mã hồ sơ.', 'score': 7.4},
                                       {'type': 'huong-dan', 'code': 'bat-dau-nhanh', 'title': 'Bắt đầu nhanh', 'snippet': 'Lấy token và gọi API đầu tiên.', 'score': 3.1}],
                          'page': 1, 'size': 20, 'totalElements': 2}
d('Suggestions', {'suggestions': '[s]'}, ['suggestions'])
EX['Suggestions'] = {'suggestions': ['tra cứu hộ tịch', 'tra cứu đất đai']}
d('TopicSummary', {'topicName': '#TopicCode', 'description': 's', 'dataClass': '#DataClass', 'visibility': '#Visibility', 'ownerOrg': 's', 'systemCode': 's', 'portalUrl': 's'},
  ['topicName', 'description', 'dataClass', 'visibility'])
TP1 = {'topicName': 'ho-tich.khai-sinh.da-dang-ky', 'description': 'Phát khi một giấy khai sinh được đăng ký.', 'dataClass': 'INTERNAL', 'visibility': 'TENANT', 'ownerOrg': 'Sở Tư pháp', 'systemCode': 'HT-TUPHAP'}
EX['TopicSummary'] = TP1
page('TopicSummary', 'TopicPage', [TP1])
d('TopicDetail', {'topicName': '#TopicCode', 'description': 's', 'dataClass': '#DataClass', 'visibility': '#Visibility', 'ownerOrg': 's', 'systemCode': 's',
                  'partitions': 'i', 'schemaFormat': ['AVRO', 'JSON_SCHEMA'], 'schemaVersions': '[s]', 'pubsubUrl': 's'}, ['topicName', 'description', 'dataClass', 'visibility'])
EX['TopicDetail'] = dict(TP1, partitions=3, schemaFormat='AVRO', schemaVersions=['1', '2'], pubsubUrl='/su-kien/ho-tich.khai-sinh.da-dang-ky')
d('VersionList', {'items': '[#VersionSummary]'}, ['items'])
EX['VersionList'] = {'items': [{'versionNo': '2.0.0', 'status': 'PUBLISHED', 'publishedAt': TS2, 'hasSandbox': True, 'specKinds': ['OPENAPI']},
                               {'versionNo': '1.0.0', 'status': 'DEPRECATED', 'publishedAt': TS1, 'sunsetAt': '2027-06-30T00:00:00Z', 'hasSandbox': True, 'specKinds': ['OPENAPI']}]}
d('SpecDocument', {'kind': ['OPENAPI', 'ASYNCAPI'], 'versionNo': '#SemVer', 'hash': 's', 'syncedAt': 'ts', 'content': 'o'}, ['kind', 'versionNo', 'hash', 'content'],
  desc='Đặc tả gốc của PH-02, đã gộp `$ref`; `format=yaml` trả `application/yaml`.')
EX['SpecDocument'] = {'kind': 'OPENAPI', 'versionNo': '1.0.0', 'hash': 'sha256:9f2c61b0', 'syncedAt': TS2,
                      'content': {'openapi': '3.1.0', 'info': {'title': 'Tra cứu hộ tịch', 'version': '1.0.0'}, 'paths': {'/ho-tich/{id}': {'get': {'operationId': 'getBirthCertificate'}}}}}
d('OperationItem', {'operationId': 's', 'method': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'], 'path': 's', 'summary': 's', 'tags': '[s]', 'deprecated': 'b', 'dataClass': '#DataClass'},
  ['operationId', 'method', 'path'])
d('OperationPage', {'items': '[#OperationItem]', 'schemas': 'o', 'servers': '[s]', 'hash': 's', 'syncedAt': 'ts', 'page': 'i', 'size': 'i', 'totalElements': 'i'},
  ['items', 'hash', 'page', 'size', 'totalElements'])
EX['OperationPage'] = {'items': [{'operationId': 'getBirthCertificate', 'method': 'GET', 'path': '/ho-tich/{id}', 'summary': 'Tra cứu giấy khai sinh', 'tags': ['Hộ tịch'], 'deprecated': False}],
                       'schemas': {'BirthCertificate': {'type': 'object'}}, 'servers': ['https://api.t68.datahub.example.vn/tra-cuu-ho-tich/v1'], 'hash': 'sha256:9f2c61b0', 'syncedAt': TS2,
                       'page': 1, 'size': 50, 'totalElements': 1}
d('EventChannel', {'channel': 's', 'operation': ['send', 'receive'], 'message': 's', 'payloadSchema': 'o'}, ['channel', 'operation'])
d('TopicEvents', {'topicName': '#TopicCode', 'versionNo': '#SemVer', 'channels': '[#EventChannel]', 'messages': '[s]', 'schemas': 'o'}, ['topicName', 'channels'])
EX['TopicEvents'] = {'topicName': 'ho-tich.khai-sinh.da-dang-ky', 'versionNo': '1.0.0',
                     'channels': [{'channel': 'ho-tich.khai-sinh.da-dang-ky', 'operation': 'receive', 'message': 'KhaiSinhDaDangKy', 'payloadSchema': {'type': 'object'}}],
                     'messages': ['KhaiSinhDaDangKy'], 'schemas': {}}
d('SampleList', {'samples': '[#CodeSample]'}, ['samples'])
EX['SampleList'] = {'samples': [{'lang': 'curl', 'title': 'getBirthCertificate bằng curl', 'code': 'curl -H "Authorization: Bearer <ACCESS_TOKEN>" "https://sandbox-api.t68.datahub.example.vn/tra-cuu-ho-tich/1.0.0/ho-tich/HT-0001"'},
                              {'lang': 'python', 'title': 'getBirthCertificate bằng Python', 'code': 'import requests\nr = requests.get(url, headers={"Authorization": "Bearer <ACCESS_TOKEN>"})'}]}
d('DiffEntry', {'operationId': 's', 'change': ['ADDED', 'REMOVED', 'CHANGED'], 'breaking': 'b', 'detail': 's'}, ['operationId', 'change', 'breaking'])
d('SpecDiff', {'base': '#SemVer', 'target': '#SemVer', 'added': '[#DiffEntry]', 'removed': '[#DiffEntry]', 'changed': '[#DiffEntry]'}, ['base', 'target', 'added', 'removed', 'changed'])
EX['SpecDiff'] = {'base': '1.0.0', 'target': '2.0.0', 'added': [{'operationId': 'listBirthCertificates', 'change': 'ADDED', 'breaking': False}], 'removed': [],
                  'changed': [{'operationId': 'getBirthCertificate', 'change': 'CHANGED', 'breaking': True, 'detail': 'Trường `fatherName` đổi thành bắt buộc.'}]}
d('TimelineItem', {'kind': ['PUBLISHED', 'DEPRECATED', 'SUSPENDED', 'RETIRED', 'SLA', 'NOTICE'], 'date': 'ts', 'description': 's', 'link': 's'}, ['kind', 'date', 'description'])
d('Changelog', {'timeline': '[#TimelineItem]', 'deprecationBanner': 'o'}, ['timeline'])
EX['Changelog'] = {'timeline': [{'kind': 'DEPRECATED', 'date': '2026-11-01T00:00:00Z', 'description': 'Phiên bản 1.0.0 ngừng khuyến nghị; ngừng hẳn ngày 30/06/2027.', 'link': '/dich-vu/tra-cuu-ho-tich/thay-doi'},
                              {'kind': 'PUBLISHED', 'date': TS1, 'description': 'Phát hành 2.0.0.'}],
                   'deprecationBanner': {'sunsetAt': '2027-06-30T00:00:00Z', 'successor': '2.0.0'}}
d('FeaturedLink', {'pageCode': '#PageCode', 'title': 's', 'publishedAt': 'ts'}, ['pageCode', 'title'])
d('MyWork', {'apps': 'i', 'tries': 'i', 'unread': 'i', 'expiringCredentials': 'i'}, ['apps', 'unread'])
d('HomeView', {'portalName': 's', 'tagline': 's', 'featured': '[#CatalogItemSummary]', 'quickstart': '#FeaturedLink', 'announcements': '[#FeaturedLink]', 'myWork': '#MyWork', 'syncState': '#SyncState'},
  ['portalName', 'featured', 'announcements'])
EX['HomeView'] = {'portalName': 'Cổng nhà phát triển Datahub T68', 'tagline': 'Kết nối dữ liệu liên thông cấp tỉnh', 'featured': [CI1],
                  'quickstart': {'pageCode': 'bat-dau-nhanh', 'title': 'Bắt đầu nhanh trong 10 phút'}, 'announcements': [{'pageCode': 'bao-tri-thang-12', 'title': 'Bảo trì ngày 05/12', 'publishedAt': TS1}],
                  'myWork': {'apps': 2, 'tries': 14, 'unread': 3, 'expiringCredentials': 1}, 'syncState': 'IDLE'}
EX['HomeViewPublic'] = {k: v for k, v in EX['HomeView'].items() if k != 'myWork'}

# ---- Nhóm C: nội dung
d('PageSummary', {'pageCode': '#PageCode', 'type': '#PageType', 'lang': '#Lang', 'title': 's', 'status': '#PageStatus', 'audience': '#Audience', 'apiCode': '#ApiCode',
                  'publishedVersionNo': 'i', 'draftVersionNo': 'i', 'tags': '[s]', 'updatedAt': 'ts'}, ['pageCode', 'type', 'lang', 'title', 'status', 'audience'])
PG1 = {'pageCode': 'bat-dau-nhanh', 'type': 'QUICKSTART', 'lang': 'vi', 'title': 'Bắt đầu nhanh trong 10 phút', 'status': 'PUBLISHED', 'audience': 'PUBLIC', 'publishedVersionNo': 3,
       'draftVersionNo': 4, 'tags': ['sandbox'], 'updatedAt': TS1}
EX['PageSummary'] = PG1
page('PageSummary', 'PageList', [PG1])
d('PageInput', {'pageCode': '#PageCode', 'type': '#PageType', 'lang': '#Lang', 'title': 's', 'audience': '#Audience', 'apiCode': '#ApiCode', 'tags': '[s]',
                'markdown': {'type': 'string', 'maxLength': 204800}}, ['pageCode', 'type', 'lang', 'title', 'audience', 'markdown'])
EX['PageInput'] = {'pageCode': 'xu-ly-loi-rfc9457', 'type': 'GUIDE', 'lang': 'vi', 'title': 'Xử lý lỗi theo RFC 9457', 'audience': 'PUBLIC', 'tags': ['lỗi'],
                   'markdown': '# Xử lý lỗi\n\nMọi lỗi trả về `application/problem+json` với trường `code`.'}
d('PageEdit', {'title': 's', 'audience': '#Audience', 'tags': '[s]', 'markdown': {'type': 'string', 'maxLength': 204800}, 'changeNote': 's'}, ['markdown'])
EX['PageEdit'] = {'title': 'Xử lý lỗi theo RFC 9457 (cập nhật)', 'markdown': '# Xử lý lỗi\n\nBổ sung bảng mã `ERR-15-nnn`.', 'changeNote': 'Thêm bảng mã lỗi'}
d('PageDetail', {'pageCode': '#PageCode', 'type': '#PageType', 'lang': '#Lang', 'title': 's', 'status': '#PageStatus', 'audience': '#Audience', 'apiCode': '#ApiCode',
                 'publishedVersionNo': 'i', 'currentVersion': '#PageVersion', 'tags': '[s]', 'updatedAt': 'ts'}, ['pageCode', 'type', 'lang', 'title', 'status', 'audience', 'currentVersion'])
d('PageVersion', {'versionNo': 'i', 'status': '#PageVersionStatus', 'markdown': 's', 'changeNote': 's', 'createdBy': 's', 'submittedBy': 's', 'approvedBy': 's', 'comment': 's',
                  'commit': 's', 'createdAt': 'ts'}, ['versionNo', 'status', 'createdBy', 'createdAt'])
PV1 = {'versionNo': 4, 'status': 'DRAFT', 'markdown': '# Bắt đầu nhanh\n\nCập nhật địa chỉ lấy token.', 'changeNote': 'Đổi tokenUrl', 'createdBy': 'bien.tap.01', 'createdAt': TS2}
EX['PageVersion'] = PV1
EX['PageDetail'] = dict({k: v for k, v in PG1.items() if k != 'draftVersionNo'}, currentVersion=PV1)
EX['PageDetailNew'] = dict(EX['PageDetail'], pageCode='xu-ly-loi-rfc9457', type='GUIDE', title='Xử lý lỗi theo RFC 9457', status='DRAFT', publishedVersionNo=None) and \
    {'pageCode': 'xu-ly-loi-rfc9457', 'type': 'GUIDE', 'lang': 'vi', 'title': 'Xử lý lỗi theo RFC 9457', 'status': 'DRAFT', 'audience': 'PUBLIC', 'tags': ['lỗi'], 'updatedAt': TS2,
     'currentVersion': {'versionNo': 1, 'status': 'DRAFT', 'markdown': '# Xử lý lỗi', 'createdBy': 'bien.tap.01', 'createdAt': TS2}}
d('PageDecision', {'comment': {'type': 'string', 'maxLength': 2000}}, [])
EX['PageDecisionReject'] = {'comment': 'Thiếu ví dụ phản hồi lỗi; bổ sung rồi gửi lại.'}
EX['PageDecision'] = {'comment': 'Đạt yêu cầu.'}
d('PageSubmit', {'versionNo': 'i', 'note': 's'}, ['versionNo'])
EX['PageSubmit'] = {'versionNo': 4, 'note': 'Đề nghị duyệt đăng'}
d('PageUnpublish', {'reason': {'type': 'string', 'maxLength': 2000}}, ['reason'])
EX['PageUnpublish'] = {'reason': 'Nội dung đã lỗi thời so với phiên bản API 2.0.0'}
d('PageVersionList', {'items': '[#PageVersion]'}, ['items'])
EX['PageVersionList'] = {'items': [PV1, {'versionNo': 3, 'status': 'PUBLISHED', 'createdBy': 'bien.tap.01', 'submittedBy': 'bien.tap.01', 'approvedBy': 'quan.tri.02', 'createdAt': TS1}]}
d('AttachmentUploaded', {'attachmentId': '#Uuid', 'url': 's', 'contentType': ['image/png', 'image/jpeg', 'image/webp'], 'size': 'i', 'width': 'i', 'height': 'i'}, ['attachmentId', 'url', 'contentType', 'size'])
EX['AttachmentUploaded'] = {'attachmentId': U1, 'url': '/api/portal/v1/content/attachments/' + U1, 'contentType': 'image/png', 'size': 48213, 'width': 1280, 'height': 720}
d('AttachmentUpload', {'file': {'type': 'string', 'contentMediaType': 'image/png', 'contentEncoding': 'base64'}, 'alt': 's'}, ['file'])
EX['AttachmentUpload'] = {'file': 'iVBORw0KGgo=', 'alt': 'Sơ đồ luồng lấy token'}
d('TocItem', {'id': 's', 'title': 's', 'level': 'i'}, ['id', 'title', 'level'])
d('PublicPage', {'pageCode': '#PageCode', 'type': '#PageType', 'lang': '#Lang', 'title': 's', 'html': 's', 'toc': '[#TocItem]', 'versionNo': 'i', 'updatedAt': 'ts', 'audience': '#Audience'},
  ['pageCode', 'title', 'html', 'versionNo', 'updatedAt'])
EX['PublicPage'] = {'pageCode': 'bat-dau-nhanh', 'type': 'QUICKSTART', 'lang': 'vi', 'title': 'Bắt đầu nhanh trong 10 phút', 'html': '<h1 id="bat-dau">Bắt đầu</h1><p>Lấy token rồi gọi API.</p>',
                    'toc': [{'id': 'bat-dau', 'title': 'Bắt đầu', 'level': 1}], 'versionNo': 3, 'updatedAt': TS1, 'audience': 'PUBLIC'}
d('GitSource', {'sourceId': '#Uuid', 'repoUrl': 's:uri', 'branch': 's', 'path': 's', 'lastRunAt': 'ts', 'lastRunState': ['OK', 'FAILED', 'RUNNING'], 'createdAt': 'ts'}, ['sourceId', 'repoUrl', 'branch', 'path'])
GS1 = {'sourceId': U1, 'repoUrl': 'https://git.t68.datahub.example.vn/tichhop/tai-lieu.git', 'branch': 'main', 'path': 'docs/', 'lastRunAt': TS1, 'lastRunState': 'OK', 'createdAt': TS1}
EX['GitSource'] = GS1
d('GitSourceList', {'items': '[#GitSource]'}, ['items'])
EX['GitSourceList'] = {'items': [GS1]}
d('GitSourceInput', {'repoUrl': 's:uri', 'branch': 's', 'path': 's', 'accessToken': {'type': 'string', 'writeOnly': True, 'description': 'Mã truy cập chỉ đọc; ghi một chiều vào OpenBao, không bao giờ trả lại.'}},
  ['repoUrl', 'branch'])
EX['GitSourceInput'] = {'repoUrl': 'https://git.t68.datahub.example.vn/tichhop/tai-lieu.git', 'branch': 'main', 'path': 'docs/', 'accessToken': '<MA-TRUY-CAP-DOC>'}
d('RunAccepted', {'runId': 's', 'state': ['RUNNING', 'OK', 'FAILED', 'QUEUED'], 'newFiles': 'i', 'changedFiles': 'i', 'skippedFiles': 'i'}, ['runId', 'state'])
EX['RunAccepted'] = {'runId': 'git-20261126-0001', 'state': 'RUNNING', 'newFiles': 0, 'changedFiles': 0, 'skippedFiles': 0}
EX['GitSyncAccepted'] = {'runId': 'git-20261126-0002', 'state': 'OK', 'newFiles': 3, 'changedFiles': 5, 'skippedFiles': 1}

# ---- Nhóm D: tài khoản
d('Me', {'userId': '#Uuid', 'username': 's', 'source': '#DevSource', 'email': 's:email', 'fullName': 's', 'orgName': 's', 'phone': 's', 'lang': '#Lang', 'notifyChannels': '[#Channel]',
         'status': '#DevStatus', 'viewerClass': '#ViewerClass', 'roles': '[s]', 'tenant': 's', 'termsVersionAccepted': 's', 'termsUpToDate': 'b'},
  ['userId', 'source', 'fullName', 'status', 'viewerClass', 'tenant', 'termsUpToDate'])
ME1 = {'userId': U1, 'username': 'nguyen.van.an', 'source': 'TENANT_SSO', 'email': 'an.nguyen@example.gov.vn', 'fullName': 'Nguyễn Văn An', 'orgName': 'Sở Tài nguyên và Môi trường',
       'phone': '0900000123', 'lang': 'vi', 'notifyChannels': ['IN_APP', 'EMAIL'], 'status': 'ACTIVE', 'viewerClass': 'TENANT_USER', 'roles': ['ROLE-DEVELOPER'], 'tenant': 'T68',
       'termsVersionAccepted': '2026-10', 'termsUpToDate': True}
EX['Me'] = ME1
d('MeUpdate', {'fullName': 's', 'orgName': 's', 'phone': 's', 'lang': '#Lang', 'notifyChannels': '[#Channel]'}, [])
EX['MeUpdate'] = {'fullName': 'Nguyễn Văn An', 'phone': '0900000124', 'lang': 'vi', 'notifyChannels': ['IN_APP']}
d('SessionItem', {'sessionId': '#Uuid', 'device': 's', 'ipMasked': 's', 'startedAt': 'ts', 'lastSeenAt': 'ts', 'current': 'b'}, ['sessionId', 'startedAt', 'current'])
d('SessionList', {'items': '[#SessionItem]'}, ['items'])
EX['SessionList'] = {'items': [{'sessionId': U2, 'device': 'Firefox 140 trên Linux', 'ipMasked': '10.20.x.x', 'startedAt': TS1, 'lastSeenAt': TS2, 'current': True}]}
d('DevRegistrationInput', {'email': 's:email', 'fullName': 's', 'orgName': 's', 'contractNo': 's', 'sponsorOrg': 's', 'phone': 's', 'tenant': 's', 'termsVersion': 's', 'termsAccepted': 'b',
                           'captchaProof': 's'}, ['email', 'fullName', 'orgName', 'contractNo', 'sponsorOrg', 'termsVersion', 'termsAccepted'])
EX['DevRegistrationInput'] = {'email': 'minh.tran@example.gov.vn', 'fullName': 'Trần Quang Minh', 'orgName': 'Công ty Giải pháp Số Việt', 'contractNo': 'HD-2026-045', 'sponsorOrg': 'Sở Thông tin và Truyền thông',
                              'phone': '0900000456', 'tenant': 'T68', 'termsVersion': '2026-10', 'termsAccepted': True, 'captchaProof': 'cap-demo'}
d('RegistrationAccepted', {'registrationId': '#Uuid', 'status': '#DevStatus', 'emailExpiresAt': 'ts'}, ['registrationId', 'status'])
EX['RegistrationAccepted'] = {'registrationId': U2, 'status': 'PENDING_EMAIL', 'emailExpiresAt': '2026-11-27T02:00:00Z'}
d('VerifyEmailInput', {'registrationId': '#Uuid', 'code': {'type': 'string', 'pattern': '^[0-9]{6}$'}}, ['registrationId', 'code'])
EX['VerifyEmailInput'] = {'registrationId': U2, 'code': '482913'}
d('RegistrationState', {'registrationId': '#Uuid', 'status': '#DevStatus'}, ['registrationId', 'status'])
EX['RegistrationState'] = {'registrationId': U2, 'status': 'PENDING_APPROVAL'}
d('Terms', {'termsVersion': 's', 'effectiveFrom': 'ts', 'title': 's', 'html': 's', 'accepted': 'b'}, ['termsVersion', 'effectiveFrom', 'title', 'html'])
EX['Terms'] = {'termsVersion': '2026-10', 'effectiveFrom': '2026-10-01T00:00:00Z', 'title': 'Điều khoản sử dụng Cổng nhà phát triển', 'html': '<h1>Điều khoản</h1><p>Chỉ dùng dữ liệu giả ở sandbox.</p>', 'accepted': False}
d('TermsAcceptInput', {'termsVersion': 's', 'accepted': 'b'}, ['termsVersion', 'accepted'])
EX['TermsAcceptInput'] = {'termsVersion': '2026-10', 'accepted': True}
d('TermsAcceptance', {'termsVersion': 's', 'acceptedAt': 'ts'}, ['termsVersion', 'acceptedAt'])
EX['TermsAcceptance'] = {'termsVersion': '2026-10', 'acceptedAt': TS2}
d('TeamMember', {'userId': '#Uuid', 'fullName': 's', 'role': '#MemberRole', 'joinedAt': 'ts'}, ['userId', 'role'])
d('Team', {'teamCode': '#TeamCode', 'name': 's', 'members': '[#TeamMember]', 'appCount': 'i', 'createdAt': 'ts'}, ['teamCode', 'name', 'members'])
TM1 = {'teamCode': 'nhom-thau-a', 'name': 'Nhóm nhà thầu A', 'members': [{'userId': U1, 'fullName': 'Nguyễn Văn An', 'role': 'OWNER', 'joinedAt': TS1}], 'appCount': 2, 'createdAt': TS1}
EX['Team'] = TM1
d('TeamList', {'items': '[#Team]'}, ['items'])
EX['TeamList'] = {'items': [TM1]}
d('TeamInput', {'teamCode': '#TeamCode', 'name': 's'}, ['teamCode', 'name'])
EX['TeamInput'] = {'teamCode': 'nhom-thau-a', 'name': 'Nhóm nhà thầu A'}
d('InvitationInput', {'email': 's:email', 'role': ['DEVELOPER', 'VIEWER']}, ['email', 'role'])
EX['InvitationInput'] = {'email': 'minh.tran@example.gov.vn', 'role': 'DEVELOPER'}
d('Invitation', {'invitationId': '#Uuid', 'teamCode': '#TeamCode', 'email': 's:email', 'role': '#MemberRole', 'status': '#InviteStatus', 'expiresAt': 'ts'}, ['invitationId', 'teamCode', 'status'])
EX['Invitation'] = {'invitationId': U3, 'teamCode': 'nhom-thau-a', 'email': 'minh.tran@example.gov.vn', 'role': 'DEVELOPER', 'status': 'PENDING', 'expiresAt': '2026-12-03T02:00:00Z'}
d('InvitationRespond', {'accept': 'b'}, ['accept'])
EX['InvitationRespond'] = {'accept': True}
EX['InvitationAccepted'] = dict(EX['Invitation'], status='ACCEPTED')
d('ErasureInput', {'confirmPhrase': ['XOA TAI KHOAN'], 'reauthProof': 's'}, ['confirmPhrase', 'reauthProof'])
EX['ErasureInput'] = {'confirmPhrase': 'XOA TAI KHOAN', 'reauthProof': 'reauth-demo'}
d('ErasureAccepted', {'userId': '#Uuid', 'status': '#DevStatus', 'erasedAt': 'ts'}, ['userId', 'status'])
EX['ErasureAccepted'] = {'userId': U2, 'status': 'ERASED', 'erasedAt': TS2}

# ---- Nhóm E: ứng dụng, thông tin xác thực
d('AppSummary', {'appCode': '#AppCode', 'name': 's', 'ownerType': '#OwnerType', 'ownerId': 's', 'status': '#AppStatus', 'role': '#MemberRole', 'credentialCount': 'i', 'lastUsedAt': 'ts'},
  ['appCode', 'name', 'ownerType', 'status'])
AP1 = {'appCode': 'app-tra-cuu-ho-tich', 'name': 'Ứng dụng tra cứu hộ tịch', 'ownerType': 'USER', 'ownerId': U1, 'status': 'ACTIVE', 'role': 'OWNER', 'credentialCount': 1, 'lastUsedAt': TS2}
EX['AppSummary'] = AP1
page('AppSummary', 'AppPage', [AP1])
d('AppDetail', {'appCode': '#AppCode', 'name': 's', 'description': 's', 'ownerType': '#OwnerType', 'ownerId': 's', 'systemCode': 's', 'status': '#AppStatus', 'role': '#MemberRole',
                'credentialCount': 'i', 'memberCount': 'i', 'archivedAt': 'ts', 'restorableUntil': 'ts', 'createdAt': 'ts'}, ['appCode', 'name', 'ownerType', 'status', 'createdAt'])
AD1 = {'appCode': 'app-tra-cuu-ho-tich', 'name': 'Ứng dụng tra cứu hộ tịch', 'description': 'Thử tích hợp tra cứu hộ tịch cho hệ thống đất đai.', 'ownerType': 'USER', 'ownerId': U1,
       'systemCode': 'HT-DATDAI', 'status': 'ACTIVE', 'role': 'OWNER', 'credentialCount': 1, 'memberCount': 1, 'createdAt': TS1}
EX['AppDetail'] = AD1
EX['AppDetailArchived'] = dict(AD1, status='ARCHIVED', archivedAt=TS2, restorableUntil='2026-12-26T02:00:00Z', credentialCount=0)
EX['AppDetailSuspended'] = dict(AD1, status='SUSPENDED')
d('AppInput', {'appCode': '#AppCode', 'name': 's', 'description': 's', 'ownerType': '#OwnerType', 'teamCode': '#TeamCode', 'systemCode': 's'}, ['appCode', 'name', 'ownerType'])
EX['AppInput'] = {'appCode': 'app-tra-cuu-ho-tich', 'name': 'Ứng dụng tra cứu hộ tịch', 'description': 'Thử tích hợp tra cứu hộ tịch cho hệ thống đất đai.', 'ownerType': 'USER', 'systemCode': 'HT-DATDAI'}
d('AppPatch', {'name': 's', 'description': 's'}, [])
EX['AppPatch'] = {'name': 'Ứng dụng tra cứu hộ tịch (bản 2)', 'description': 'Bổ sung thử sự kiện.'}
d('Credential', {'credentialId': '#Uuid', 'kind': '#CredKind', 'label': 's', 'status': '#CredStatus', 'prefix': 's', 'clientId': 's', 'tokenUrl': 's:uri', 'expiresAt': 'ts', 'rotatingUntil': 'ts',
                 'revokedAt': 'ts', 'createdAt': 'ts', 'lastUsedAt': 'ts'}, ['credentialId', 'kind', 'status', 'expiresAt', 'createdAt'])
CR1 = {'credentialId': U2, 'kind': 'CLIENT_CREDENTIALS', 'label': 'Máy chủ thử', 'status': 'ACTIVE', 'prefix': 'q8Zk3mPa', 'clientId': 'sbx-t68-app-tra-cuu-ho-tich-1',
       'expiresAt': '2027-02-24T02:00:00Z', 'createdAt': TS2}
EX['Credential'] = CR1
d('CredentialList', {'items': '[#Credential]'}, ['items'])
EX['CredentialList'] = {'items': [CR1, dict(CR1, credentialId=U3, kind='API_KEY', clientId=None, prefix='dhsk_t68', label='Khóa thử CI') and
                                  {'credentialId': U3, 'kind': 'API_KEY', 'label': 'Khóa thử CI', 'status': 'ROTATING', 'prefix': 'dhsk_t68', 'expiresAt': '2027-01-10T02:00:00Z',
                                   'rotatingUntil': '2026-11-29T02:00:00Z', 'createdAt': TS1}]}
d('CredentialIssueInput', {'kind': '#CredKind', 'label': 's', 'ttlDays': {'type': 'integer', 'minimum': 1, 'maximum': 180}, 'jwks': 'o'}, ['kind'])
EX['CredentialIssueInput'] = {'kind': 'CLIENT_CREDENTIALS', 'label': 'Máy chủ thử', 'ttlDays': 90}
EX['CredentialIssueInputKey'] = {'kind': 'API_KEY', 'label': 'Khóa thử CI', 'ttlDays': 30}
d('CredentialIssued', {'credentialId': '#Uuid', 'kind': '#CredKind', 'label': 's', 'status': '#CredStatus', 'prefix': 's', 'clientId': 's', 'tokenUrl': 's:uri',
                       'clientSecret': {'type': 'string', 'readOnly': True, 'description': 'Chỉ có ở lần cấp hoặc xoay này (FR-15-029); không xem lại được (ERR-15-019).'},
                       'apiKey': {'type': 'string', 'readOnly': True, 'description': 'Chỉ có ở lần cấp này; dạng `dhsk_{tenant}_{base64url}`.'}, 'expiresAt': 'ts', 'createdAt': 'ts', 'samples': '[#CodeSample]'},
  ['credentialId', 'kind', 'status', 'prefix', 'expiresAt', 'createdAt'])
EX['CredentialIssued'] = dict(CR1, clientSecret='sbxs_9mXqT2vLw8Rk5HfA3yNcD7bZ', tokenUrl='https://sso.datahub.example.vn/realms/dh-dev/protocol/openid-connect/token',
                              samples=[{'lang': 'curl', 'title': 'Lấy token', 'code': 'curl -u sbx-t68-app-tra-cuu-ho-tich-1:<CLIENT_SECRET> -d grant_type=client_credentials <TOKEN_URL>'}])
EX['CredentialIssuedKey'] = {'credentialId': U3, 'kind': 'API_KEY', 'label': 'Khóa thử CI', 'status': 'ACTIVE', 'prefix': 'dhsk_t68', 'apiKey': 'dhsk_t68_Zm9vYmFyYmF6cXV4MTIzNDU2Nzg5',
                             'expiresAt': '2026-12-26T02:00:00Z', 'createdAt': TS2}
d('RotateInput', {'graceHours': {'type': 'integer', 'minimum': 1, 'maximum': 72}}, [])
EX['RotateInput'] = {'graceHours': 24}
d('RotateResult', {'current': '#CredentialIssued', 'previous': '#Credential'}, ['current', 'previous'])
EX['RotateResult'] = {'current': dict(EX['CredentialIssued'], credentialId=U3, clientId='sbx-t68-app-tra-cuu-ho-tich-2', clientSecret='sbxs_Pq7Lw2Xv9Tn4KcM8aRf6HdB3',
                                      prefix='Pq7Lw2Xv'),
                      'previous': dict(CR1, status='ROTATING', rotatingUntil='2026-11-27T02:00:00Z')}
d('RevokeInput', {'reason': {'type': 'string', 'maxLength': 500}}, [])
EX['RevokeInput'] = {'reason': 'Lộ khóa trong kho mã nguồn thử nghiệm'}
EX['CredentialRevoked'] = dict(CR1, status='REVOKED', revokedAt=TS2)
d('ProdCredentialRef', {'systemCode': 's', 'clientId': 's', 'method': '#ProdMethod', 'certThumbprintPrefix': {'type': 'string', 'maxLength': 16}, 'expiresAt': 'ts', 'status': '#ProdRefStatus',
                        'lastUsedAt': 'ts'}, ['systemCode', 'clientId', 'method', 'status'])
d('ProdCredentialRefList', {'items': '[#ProdCredentialRef]'}, ['items'])
EX['ProdCredentialRefList'] = {'items': [{'systemCode': 'HT-DATDAI', 'clientId': 'ht-datdai.t68', 'method': 'tls_client_auth', 'certThumbprintPrefix': '9F2C61B0A47D83E1', 'expiresAt': '2027-05-01T00:00:00Z',
                                          'status': 'ACTIVE', 'lastUsedAt': TS2}]}
d('Member', {'userId': '#Uuid', 'fullName': 's', 'email': 's:email', 'role': '#MemberRole', 'addedAt': 'ts'}, ['userId', 'role'])
d('MemberList', {'items': '[#Member]'}, ['items'])
EX['MemberList'] = {'items': [{'userId': U1, 'fullName': 'Nguyễn Văn An', 'role': 'OWNER', 'addedAt': TS1}, {'userId': U2, 'fullName': 'Trần Quang Minh', 'role': 'DEVELOPER', 'addedAt': TS2}]}
d('MemberInput', {'role': '#MemberRole', 'email': 's:email'}, ['role'])
EX['MemberInput'] = {'role': 'DEVELOPER'}
EX['Member'] = {'userId': U2, 'fullName': 'Trần Quang Minh', 'role': 'DEVELOPER', 'addedAt': TS2}
SCH['Member']  # giữ tham chiếu

# ---- Nhóm F: sandbox và thử API
d('SandboxProfile', {'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'mode': '#SandboxMode', 'backendUrl': 's:uri', 'examplePolicy': '#ExamplePolicy', 'mockLatencyMs': {'type': 'integer', 'minimum': 0, 'maximum': 5000},
                     'tryProduction': '#TryProdState', 'lastHealthCheck': 'ts', 'profileVersion': 'i'}, ['apiCode', 'versionNo', 'mode', 'examplePolicy'])
EX['SandboxProfile'] = {'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'mode': 'MOCK', 'examplePolicy': 'FIRST', 'mockLatencyMs': 120, 'tryProduction': 'OFF', 'profileVersion': 3}
d('SandboxProfileInput', {'versionNo': '#SemVer', 'mode': '#SandboxMode', 'backendUrl': 's:uri', 'examplePolicy': '#ExamplePolicy', 'mockLatencyMs': {'type': 'integer', 'minimum': 0, 'maximum': 5000}},
  ['versionNo', 'mode'])
EX['SandboxProfileInput'] = {'versionNo': '1.0.0', 'mode': 'BACKEND', 'backendUrl': 'https://thu-nghiem.t68.example.gov.vn/ho-tich', 'examplePolicy': 'FIRST', 'mockLatencyMs': 0}
EX['SandboxProfileBackend'] = {'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'mode': 'BACKEND', 'backendUrl': 'https://thu-nghiem.t68.example.gov.vn/ho-tich', 'examplePolicy': 'FIRST',
                               'mockLatencyMs': 0, 'tryProduction': 'OFF', 'lastHealthCheck': TS2, 'profileVersion': 4}
d('TryRequestInput', {'appCode': '#AppCode', 'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'operationId': 's', 'environment': '#TryEnv', 'systemCode': 's', 'confirmRealSystem': 'b',
                      'pathParams': 'o', 'query': 'o', 'headers': 'o', 'body': {}}, ['appCode', 'apiCode', 'versionNo', 'operationId', 'environment'])
EX['TryRequestInput'] = {'appCode': 'app-tra-cuu-ho-tich', 'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'operationId': 'getBirthCertificate', 'environment': 'SANDBOX',
                         'pathParams': {'id': 'HT-0001'}, 'query': {}, 'headers': {'Accept': 'application/json'}}
EX['TryRequestProd'] = dict(EX['TryRequestInput'], environment='PRODUCTION', systemCode='HT-DATDAI', confirmRealSystem=True)
EX['TryRequestMock'] = dict(EX['TryRequestInput'], headers={'Accept': 'application/json', 'X-DH-Mock-Status': '404'})
d('TryValidation', {'valid': 'b', 'violations': '[#FieldError]', 'warnings': '[s]'}, ['valid', 'violations', 'warnings'])
EX['TryValidation'] = {'valid': True, 'violations': [], 'warnings': ['Trường `fullName` giống tên thật; chỉ dùng dữ liệu giả (PII-15-05).']}
d('TryResponse', {'tryId': 's', 'environment': '#TryEnv', 'mode': ['MOCK', 'BACKEND', 'PRODUCTION'], 'result': '#TryResultCode', 'status': 'i', 'latencyMs': 'i', 'headers': 'o', 'body': {},
                  'bodyTruncated': 'b', 'warnings': '[s]', 'traceId': '#TraceId'}, ['tryId', 'environment', 'mode', 'result', 'status', 'latencyMs', 'headers', 'warnings'])
EX['TryResponse'] = {'tryId': 'TRY-20261126-000123', 'environment': 'SANDBOX', 'mode': 'MOCK', 'result': 'OK', 'status': 200, 'latencyMs': 131,
                     'headers': {'content-type': 'application/json', 'x-dh-sandbox': 'mock', 'x-dh-try-id': 'TRY-20261126-000123'},
                     'body': {'id': 'HT-0001', 'fullName': 'Nguyen Van Mau', 'birthDate': '2020-01-01'}, 'bodyTruncated': False, 'warnings': [], 'traceId': TRACE}
EX['TryResponseProd'] = {'tryId': 'TRY-20261126-000124', 'environment': 'PRODUCTION', 'mode': 'PRODUCTION', 'result': 'OK', 'status': 200, 'latencyMs': 212,
                         'headers': {'content-type': 'application/json'}, 'body': {'id': 'HT-0001', 'status': 'DA_DANG_KY'}, 'bodyTruncated': False, 'warnings': ['Thử trên hệ thống thật.'], 'traceId': TRACE}
d('TryRecord', {'tryId': 's', 'appCode': '#AppCode', 'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'operationId': 's', 'environment': '#TryEnv', 'result': '#TryResultCode', 'status': 'i',
                'latencyMs': 'i', 'userId': '#Uuid', 'traceId': '#TraceId', 'createdAt': 'ts'}, ['tryId', 'appCode', 'apiCode', 'operationId', 'environment', 'result', 'createdAt'])
TR1 = {'tryId': 'TRY-20261126-000123', 'appCode': 'app-tra-cuu-ho-tich', 'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'operationId': 'getBirthCertificate', 'environment': 'SANDBOX',
       'result': 'OK', 'status': 200, 'latencyMs': 131, 'userId': U1, 'traceId': TRACE, 'createdAt': TS2}
EX['TryRecord'] = TR1
page('TryRecord', 'TryRecordPage', [TR1])
d('QuotaWindow', {'limit': 'i', 'remaining': 'i', 'resetAt': 'ts'}, ['limit', 'remaining', 'resetAt'])
d('TryQuota', {'perUserPerMinute': '#QuotaWindow', 'perAppPerDay': '#QuotaWindow', 'perTenantPerMinute': '#QuotaWindow', 'maxBodyKb': 'i'}, ['perUserPerMinute', 'perAppPerDay', 'maxBodyKb'])
EX['TryQuota'] = {'perUserPerMinute': {'limit': 30, 'remaining': 27, 'resetAt': '2026-11-26T02:01:00Z'}, 'perAppPerDay': {'limit': 5000, 'remaining': 4870, 'resetAt': '2026-11-27T00:00:00Z'},
                  'perTenantPerMinute': {'limit': 3000, 'remaining': 2990, 'resetAt': '2026-11-26T02:01:00Z'}, 'maxBodyKb': 256}
d('HistoryDeleted', {'deleted': 'i'}, ['deleted'])
EX['HistoryDeleted'] = {'deleted': 14}
d('CollectionRequest', {'name': 's', 'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'operationId': 's', 'environment': '#TryEnv', 'pathParams': 'o', 'query': 'o', 'headers': 'o', 'body': {}},
  ['name', 'apiCode', 'versionNo', 'operationId'])
d('Collection', {'collectionId': '#Uuid', 'name': 's', 'requests': '[#CollectionRequest]', 'updatedAt': 'ts'}, ['collectionId', 'name', 'requests'])
d('CollectionInput', {'name': 's', 'requests': '[#CollectionRequest]'}, ['name', 'requests'])
CO_REQ = {'name': 'Tra cứu HT-0001', 'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'operationId': 'getBirthCertificate', 'environment': 'SANDBOX', 'pathParams': {'id': 'HT-0001'}}
EX['CollectionInput'] = {'name': 'Luồng tra cứu hộ tịch', 'requests': [CO_REQ]}
EX['Collection'] = {'collectionId': U3, 'name': 'Luồng tra cứu hộ tịch', 'requests': [CO_REQ], 'updatedAt': TS2}
d('CollectionList', {'items': '[#Collection]'}, ['items'])
EX['CollectionList'] = {'items': [EX['Collection']]}
d('ExportFile', {'format': '#ExportFormat', 'fileName': 's', 'content': {}}, ['format', 'fileName', 'content'], desc='Tệp xuất; `Content-Disposition: attachment`. Bí mật luôn là chỗ giữ `<ACCESS_TOKEN>`.')
EX['ExportFile'] = {'format': 'postman', 'fileName': 'luong-tra-cuu-ho-tich.postman_collection.json',
                    'content': {'info': {'name': 'Luồng tra cứu hộ tịch', 'schema': 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json'}, 'item': []}}
d('AuthorizeDecision', {'allowed': 'b', 'tenant': 's', 'appCode': '#AppCode', 'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'mode': '#SandboxMode', 'profileVersion': 'i',
                        'rateLimit': '#QuotaWindow'}, ['allowed', 'tenant', 'appCode', 'mode'])
EX['AuthorizeDecision'] = {'allowed': True, 'tenant': 't68', 'appCode': 'app-tra-cuu-ho-tich', 'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'mode': 'MOCK', 'profileVersion': 3,
                           'rateLimit': {'limit': 5000, 'remaining': 4869, 'resetAt': '2026-11-27T00:00:00Z'}}
d('TryProdItem', {'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'state': '#TryProdState', 'dataClass': '#DataClass', 'allowWrite': 'b', 'validUntil': 'ts', 'proposedBy': 's', 'approvedBy': 's',
                  'reason': 's', 'updatedAt': 'ts'}, ['apiCode', 'state'])
TP2 = {'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'state': 'ENABLED', 'dataClass': 'INTERNAL', 'allowWrite': False, 'validUntil': '2027-02-24T00:00:00Z', 'proposedBy': 'quan.tri.01',
       'approvedBy': 'quan.tri.02', 'reason': 'Thử nghiệm liên thông với HT-DATDAI', 'updatedAt': TS2}
EX['TryProdItem'] = TP2
page('TryProdItem', 'TryProdPage', [TP2])
d('TryProdInput', {'versionNo': '#SemVer', 'validDays': {'type': 'integer', 'minimum': 1, 'maximum': 90}, 'reason': 's'}, ['validDays', 'reason'])
EX['TryProdInput'] = {'versionNo': '1.0.0', 'validDays': 90, 'reason': 'Thử nghiệm liên thông với HT-DATDAI'}
EX['TryProdPending'] = dict(TP2, state='PENDING', approvedBy=None) and {k: v for k, v in dict(TP2, state='PENDING').items() if k != 'approvedBy'}
d('TryProdDecision', {'comment': {'type': 'string', 'maxLength': 2000}}, [])
EX['TryProdDecision'] = {'comment': 'Đồng ý, chỉ GET và HEAD.'}
d('TryProdDisable', {'reason': 's'}, ['reason'])
EX['TryProdDisable'] = {'reason': 'Kết thúc đợt thử nghiệm'}
EX['TryProdOff'] = dict(TP2, state='OFF')

# ---- Nhóm G: ủy thác
d('SubscriptionInput', {'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'planCode': 's', 'systemCode': 's', 'purpose': 's', 'expectedDailyCalls': 'i', 'operations': '[s]', 'legalBasis': 's',
                        'termsAccepted': 'b'}, ['apiCode', 'versionNo', 'planCode', 'systemCode', 'purpose', 'expectedDailyCalls', 'legalBasis', 'termsAccepted'])
EX['SubscriptionInput'] = {'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'planCode': 'co-ban', 'systemCode': 'HT-DATDAI', 'purpose': 'Đối chiếu hộ tịch khi cấp giấy chứng nhận quyền sử dụng đất',
                           'expectedDailyCalls': 2000, 'operations': ['getBirthCertificate'], 'legalBasis': 'Nghị định 47/2020/NĐ-CP', 'termsAccepted': True}
d('Subscription', {'subscriptionId': '#Uuid', 'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'planCode': 's', 'systemCode': 's', 'status': ['PENDING_REVIEW', 'ACTIVE', 'REJECTED', 'SUSPENDED', 'REVOKED', 'CANCELLED', 'EXPIRED'],
                   'reviewRequestId': 's', 'submittedBy': 's', 'submittedAt': 'ts', 'warnings': '[s]'}, ['subscriptionId', 'apiCode', 'status', 'submittedAt'])
SU1 = {'subscriptionId': U1, 'apiCode': 'tra-cuu-ho-tich', 'versionNo': '1.0.0', 'planCode': 'co-ban', 'systemCode': 'HT-DATDAI', 'status': 'PENDING_REVIEW', 'reviewRequestId': 'YC-2026-0312',
       'submittedBy': 'nguyen.van.an', 'submittedAt': TS2, 'warnings': []}
EX['Subscription'] = SU1
page('Subscription', 'SubscriptionPage', [SU1])
d('SubscriptionDetail', {'subscriptionId': '#Uuid', 'apiCode': '#ApiCode', 'versionNo': '#SemVer', 'planCode': 's', 'systemCode': 's', 'status': 's', 'reviewRequestId': 's', 'submittedBy': 's',
                         'submittedAt': 'ts', 'timeline': '[#TimelineItem]', 'warnings': '[s]'}, ['subscriptionId', 'apiCode', 'status', 'timeline'])
EX['SubscriptionDetail'] = dict(SU1, timeline=[{'kind': 'NOTICE', 'date': TS2, 'description': 'Đã gửi, chờ chủ dịch vụ duyệt (PH-02).'}])
d('SubscriptionCancelInput', {'reason': 's'}, [])
EX['SubscriptionCancelInput'] = {'reason': 'Không còn nhu cầu'}
EX['SubscriptionCancelled'] = dict(SU1, status='CANCELLED')
d('OnboardingInput', {'orgCode': 's', 'systemName': 's', 'systemCode': 's', 'contactName': 's', 'contactEmail': 's:email', 'securityLevel': {'type': 'integer', 'minimum': 1, 'maximum': 5}, 'purpose': 's',
                      'legalBasis': 's'}, ['orgCode', 'systemName', 'contactName', 'contactEmail', 'securityLevel', 'purpose', 'legalBasis'])
EX['OnboardingInput'] = {'orgCode': 'SO-TNMT', 'systemName': 'Hệ thống quản lý đất đai', 'systemCode': 'HT-DATDAI', 'contactName': 'Nguyễn Văn An', 'contactEmail': 'an.nguyen@example.gov.vn',
                         'securityLevel': 3, 'purpose': 'Kết nối liên thông hộ tịch', 'legalBasis': 'Nghị định 47/2020/NĐ-CP'}
d('Onboarding', {'applicationId': '#Uuid', 'systemCode': 's', 'status': ['SUBMITTED', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'RETURNED'], 'submittedAt': 'ts', 'updatedAt': 'ts'},
  ['applicationId', 'status', 'submittedAt'])
OB1 = {'applicationId': U2, 'systemCode': 'HT-DATDAI', 'status': 'SUBMITTED', 'submittedAt': TS2}
EX['Onboarding'] = OB1
page('Onboarding', 'OnboardingPage', [OB1])
d('PublicationInput', {'systemCode': 's', 'dataClass': '#DataClass', 'description': 's', 'specUrl': 's:uri', 'specContent': 'o'}, ['systemCode', 'dataClass', 'description'])
EX['PublicationInput'] = {'systemCode': 'HT-TUPHAP', 'dataClass': 'INTERNAL', 'description': 'API tra cứu hộ tịch', 'specUrl': 'https://git.t68.datahub.example.vn/tuphap/api/raw/main/ho-tich.yaml'}
d('LintResult', {'rule': 's', 'severity': ['error', 'warning', 'info'], 'path': 's', 'message': 's'}, ['rule', 'severity', 'message'])
d('Publication', {'publicationId': '#Uuid', 'systemCode': 's', 'status': ['LINTING', 'SUBMITTED', 'IN_REVIEW', 'PUBLISHED', 'REJECTED'], 'lintResults': '[#LintResult]', 'submittedAt': 'ts'},
  ['publicationId', 'status', 'lintResults'])
PB1 = {'publicationId': U3, 'systemCode': 'HT-TUPHAP', 'status': 'SUBMITTED', 'lintResults': [{'rule': 'operation-description', 'severity': 'warning', 'path': '$.paths./ho-tich/{id}.get', 'message': 'Thiếu mô tả thao tác.'}], 'submittedAt': TS2}
EX['Publication'] = PB1
page('Publication', 'PublicationPage', [PB1])

# ---- Nhóm H: theo dõi
d('DashboardCards', {'apps': 'i', 'credentialsExpiring': 'i', 'triesLast7d': 'i', 'subscriptions': 'i', 'followed': 'i', 'unread': 'i', 'openTickets': 'i'}, [])
d('Dashboard', {'cards': '#DashboardCards', 'partial': '[s]', 'generatedAt': 'ts'}, ['cards', 'generatedAt'])
EX['Dashboard'] = {'cards': {'apps': 2, 'credentialsExpiring': 1, 'triesLast7d': 42, 'subscriptions': 1, 'followed': 5, 'unread': 3, 'openTickets': 0}, 'partial': [], 'generatedAt': TS2}
d('SeriesPoint', {'t': 'ts', 'calls': 'i', 'errors': 'i'}, ['t', 'calls', 'errors'])
d('ApiStat', {'apiCode': '#ApiCode', 'calls': 'i', 'errors': 'i', 'p95Ms': 'i'}, ['apiCode', 'calls', 'errors'])
d('AppStats', {'range': ['24h', '7d', '30d'], 'series': '[#SeriesPoint]', 'totals': 'o', 'byApi': '[#ApiStat]'}, ['range', 'series', 'totals', 'byApi'])
EX['AppStats'] = {'range': '7d', 'series': [{'t': '2026-11-25T00:00:00Z', 'calls': 320, 'errors': 4}, {'t': '2026-11-26T00:00:00Z', 'calls': 180, 'errors': 1}],
                  'totals': {'calls': 500, 'errors': 5}, 'byApi': [{'apiCode': 'tra-cuu-ho-tich', 'calls': 500, 'errors': 5, 'p95Ms': 310}]}
d('AppLog', {'logId': 's', 'time': 'ts', 'apiCode': '#ApiCode', 'method': 's', 'path': 's', 'status': 'i', 'latencyMs': 'i', 'traceId': '#TraceId', 'credentialPrefix': 's'},
  ['logId', 'time', 'apiCode', 'method', 'path', 'status', 'latencyMs'])
AL1 = {'logId': 'log-01JD7K2', 'time': TS2, 'apiCode': 'tra-cuu-ho-tich', 'method': 'GET', 'path': '/ho-tich/{id}', 'status': 200, 'latencyMs': 131, 'traceId': TRACE, 'credentialPrefix': 'q8Zk3mPa'}
EX['AppLog'] = AL1
page('AppLog', 'AppLogPage', [AL1])
d('NotifSub', {'apiCode': '#ApiCode', 'channels': '[#Channel]', 'kinds': '[s]', 'updatedAt': 'ts'}, ['apiCode', 'channels'])
NS1 = {'apiCode': 'tra-cuu-ho-tich', 'channels': ['IN_APP', 'EMAIL'], 'kinds': ['DEPRECATED', 'SLA'], 'updatedAt': TS2}
EX['NotifSub'] = NS1
d('NotifSubList', {'items': '[#NotifSub]'}, ['items'])
EX['NotifSubList'] = {'items': [NS1]}
d('NotifSubInput', {'channels': '[#Channel]', 'kinds': '[s]'}, ['channels'])
EX['NotifSubInput'] = {'channels': ['IN_APP', 'EMAIL'], 'kinds': ['DEPRECATED', 'SLA']}
d('InboxMessage', {'messageId': '#Uuid', 'kind': 's', 'mandatory': 'b', 'title': 's', 'body': 's', 'link': 's', 'apiCode': '#ApiCode', 'read': 'b', 'createdAt': 'ts'}, ['messageId', 'kind', 'title', 'read', 'createdAt'])
IM1 = {'messageId': U1, 'kind': 'DEPRECATED', 'mandatory': True, 'title': 'tra-cuu-ho-tich 1.0.0 ngừng khuyến nghị', 'body': 'Ngừng hẳn ngày 30/06/2027; chuyển sang 2.0.0.', 'link': '/dich-vu/tra-cuu-ho-tich/thay-doi',
       'apiCode': 'tra-cuu-ho-tich', 'read': False, 'createdAt': TS2}
EX['InboxMessage'] = IM1
d('InboxPage', {'items': '[#InboxMessage]', 'unreadCount': 'i', 'page': 'i', 'size': 'i', 'totalElements': 'i'}, ['items', 'unreadCount', 'page', 'size', 'totalElements'])
EX['InboxPage'] = {'items': [IM1], 'unreadCount': 1, 'page': 1, 'size': 20, 'totalElements': 1}
d('ReadAllResult', {'updated': 'i'}, ['updated'])
EX['ReadAllResult'] = {'updated': 3}

# ---- Nhóm I: hỗ trợ
d('QuestionInput', {'subject': {'type': 'string', 'maxLength': 150}, 'body': {'type': 'string', 'maxLength': 2000}, 'kind': ['QUESTION', 'DOC_ERROR'], 'operationId': 's'}, ['subject', 'body', 'kind'])
EX['QuestionInput'] = {'subject': 'Trường `fatherName` có bắt buộc không?', 'body': 'Ở phiên bản 2.0.0 trường này bắt buộc, nhưng ví dụ chưa có.', 'kind': 'QUESTION', 'operationId': 'getBirthCertificate'}
d('Question', {'questionId': '#Uuid', 'apiCode': '#ApiCode', 'kind': '#TicketKind', 'subject': 's', 'body': 's', 'author': 's', 'answer': 's', 'answeredBy': 's', 'status': '#TicketStatus', 'createdAt': 'ts'},
  ['questionId', 'apiCode', 'subject', 'status', 'createdAt'])
QU1 = {'questionId': U2, 'apiCode': 'tra-cuu-ho-tich', 'kind': 'QUESTION', 'subject': 'Trường `fatherName` có bắt buộc không?', 'body': 'Ở phiên bản 2.0.0 trường này bắt buộc, nhưng ví dụ chưa có.',
       'author': 'nguyen.van.an', 'status': 'OPEN', 'createdAt': TS2}
EX['Question'] = QU1
page('Question', 'QuestionPage', [QU1])
d('FeedbackInput', {'targetType': ['PAGE', 'API', 'OPERATION'], 'targetCode': 's', 'rating': ['up', 'down'], 'comment': {'type': 'string', 'maxLength': 2000}}, ['targetType', 'targetCode', 'rating'])
EX['FeedbackInput'] = {'targetType': 'PAGE', 'targetCode': 'bat-dau-nhanh', 'rating': 'down', 'comment': 'Thiếu ví dụ lấy token bằng private_key_jwt.'}
d('FeedbackAck', {'feedbackId': '#Uuid', 'createdAt': 'ts'}, ['feedbackId', 'createdAt'])
EX['FeedbackAck'] = {'feedbackId': U3, 'createdAt': TS2}
d('TicketInput', {'kind': ['QUESTION', 'DOC_ERROR', 'SUPPORT_REQUEST', 'ACCESS_REQUEST'], 'apiCode': '#ApiCode', 'subject': {'type': 'string', 'maxLength': 150}, 'body': {'type': 'string', 'maxLength': 4000}},
  ['kind', 'subject', 'body'])
EX['TicketInput'] = {'kind': 'SUPPORT_REQUEST', 'apiCode': 'tra-cuu-ho-tich', 'subject': 'Sandbox trả 503 khi gọi lúc 14:00', 'body': 'Ứng dụng app-tra-cuu-ho-tich gọi getBirthCertificate nhận ERR-15-111 nhiều lần.'}
d('Ticket', {'ticketCode': '#TicketCode', 'kind': '#TicketKind', 'status': '#TicketStatus', 'apiCode': '#ApiCode', 'subject': 's', 'assignee': 's', 'createdBy': 's', 'createdAt': 'ts', 'updatedAt': 'ts'},
  ['ticketCode', 'kind', 'status', 'subject', 'createdAt'])
TK1 = {'ticketCode': 'HT-2026-0042', 'kind': 'SUPPORT_REQUEST', 'status': 'OPEN', 'apiCode': 'tra-cuu-ho-tich', 'subject': 'Sandbox trả 503 khi gọi lúc 14:00', 'createdBy': 'nguyen.van.an', 'createdAt': TS2}
EX['Ticket'] = TK1
page('Ticket', 'TicketPage', [TK1])
d('TicketMessage', {'messageId': '#Uuid', 'author': 's', 'authorRole': ['REQUESTER', 'SUPPORT'], 'body': 's', 'internal': 'b', 'createdAt': 'ts'}, ['messageId', 'author', 'body', 'createdAt'])
TMG1 = {'messageId': U3, 'author': 'nguyen.van.an', 'authorRole': 'REQUESTER', 'body': 'Ứng dụng gọi getBirthCertificate nhận ERR-15-111 nhiều lần.', 'createdAt': TS2}
EX['TicketMessage'] = TMG1
d('TicketDetail', {'ticketCode': '#TicketCode', 'kind': '#TicketKind', 'status': '#TicketStatus', 'apiCode': '#ApiCode', 'subject': 's', 'assignee': 's', 'createdBy': 's', 'createdAt': 'ts',
                   'updatedAt': 'ts', 'messages': '[#TicketMessage]'}, ['ticketCode', 'kind', 'status', 'subject', 'messages'])
EX['TicketDetail'] = dict(TK1, messages=[TMG1])
d('TicketMessageInput', {'body': {'type': 'string', 'maxLength': 4000}}, ['body'])
EX['TicketMessageInput'] = {'body': 'Bổ sung: lỗi lặp lại lúc 14:05 và 14:10.'}
d('TicketTransition', {'status': ['ANSWERED', 'RESOLVED', 'CLOSED'], 'reply': {'type': 'string', 'maxLength': 4000}, 'assignee': 's', 'internalNote': {'type': 'string', 'maxLength': 2000}}, ['status'])
EX['TicketTransition'] = {'status': 'ANSWERED', 'reply': 'Đã khắc phục gateway sandbox lúc 14:20; vui lòng thử lại.', 'assignee': 'ho.tro.01', 'internalNote': 'Nguyên nhân: Pod portal-sandbox khởi động lại.'}
EX['TicketAnswered'] = dict(TK1, status='ANSWERED', assignee='ho.tro.01', updatedAt=TS2)

# ---- Nhóm J: quản trị
d('FooterLink', {'label': 's', 'url': 's:uri'}, ['label', 'url'])
d('Branding', {'portalName': {'type': 'string', 'minLength': 3, 'maxLength': 80}, 'tagline': {'type': 'string', 'maxLength': 160}, 'logoUrl': 's', 'supportEmail': 's:email', 'supportPhone': 's',
               'footerLinks': {'type': 'array', 'maxItems': 8, 'items': T('#FooterLink')}, 'welcomeText': {'type': 'string', 'maxLength': 2048}, 'publicEnabled': 'b'}, ['portalName'])
BR1 = {'portalName': 'Cổng nhà phát triển Datahub T68', 'tagline': 'Kết nối dữ liệu liên thông cấp tỉnh', 'logoUrl': '/static/branding/t68/logo.png', 'supportEmail': 'hotro@example.gov.vn',
       'supportPhone': '0900000789', 'footerLinks': [{'label': 'Chính sách bảo mật', 'url': 'https://t68.datahub.example.vn/bao-mat'}], 'welcomeText': 'Chào mừng đến với cổng.', 'publicEnabled': True}
EX['Branding'] = BR1
d('BrandingInput', {k: v for k, v in SCH['Branding']['properties'].items() if k not in ('logoUrl', 'publicEnabled')}, ['portalName'])
EX['BrandingInput'] = {k: v for k, v in BR1.items() if k not in ('logoUrl', 'publicEnabled')}
d('LogoUpload', {'file': {'type': 'string', 'contentMediaType': 'image/png', 'contentEncoding': 'base64'}}, ['file'])
EX['LogoUpload'] = {'file': 'iVBORw0KGgo='}
d('LogoUploaded', {'logoUrl': 's', 'width': 'i', 'height': 'i', 'size': 'i'}, ['logoUrl', 'size'])
EX['LogoUploaded'] = {'logoUrl': '/static/branding/t68/logo.png?v=7', 'width': 256, 'height': 256, 'size': 31200}
d('SettingItem', {'key': {'type': 'string', 'pattern': '^15\\.[a-z0-9.-]+$'}, 'value': {}, 'default': {}, 'ceiling': {}, 'description': 's'}, ['key', 'value'])
d('Settings', {'items': '[#SettingItem]', 'version': 'i'}, ['items'])
EX['Settings'] = {'items': [{'key': '15.try.max-body-kb', 'value': 256, 'default': 256, 'ceiling': 256, 'description': 'Cỡ thân yêu cầu thử tối đa (KB)'},
                            {'key': '15.try.prod-enabled', 'value': False, 'default': False, 'description': 'Bật thử production của tenant'}], 'version': 5}
d('SettingsInput', {'items': {'type': 'array', 'minItems': 1, 'items': T(obj({'key': 's', 'value': {}}, ['key', 'value']))}, 'reason': 's'}, ['items', 'reason'])
EX['SettingsInput'] = {'items': [{'key': '15.try.prod-enabled', 'value': True}], 'reason': 'Mở thử production cho đợt tích hợp Đợt 2'}
d('DevAccount', {'userId': '#Uuid', 'email': 's:email', 'fullName': 's', 'orgName': 's', 'contractNo': 's', 'sponsorOrg': 's', 'status': '#DevStatus', 'tenantGrants': '[s]', 'lockedReason': 's',
                 'createdAt': 'ts', 'lastActiveAt': 'ts'}, ['userId', 'email', 'fullName', 'status', 'createdAt'])
DA1 = {'userId': U2, 'email': 'minh.tran@example.gov.vn', 'fullName': 'Trần Quang Minh', 'orgName': 'Công ty Giải pháp Số Việt', 'contractNo': 'HD-2026-045', 'sponsorOrg': 'Sở Thông tin và Truyền thông',
       'status': 'PENDING_APPROVAL', 'tenantGrants': [], 'createdAt': TS1}
EX['DevAccount'] = DA1
page('DevAccount', 'DevAccountPage', [DA1])
d('ApproveInput', {'tenantGrants': '[s]', 'comment': {'type': 'string', 'maxLength': 2000}}, [])
EX['ApproveInput'] = {'tenantGrants': ['T68'], 'comment': 'Đã đối chiếu hợp đồng HD-2026-045.'}
d('RejectInput', {'comment': {'type': 'string', 'maxLength': 2000}}, ['comment'])
EX['RejectInput'] = {'comment': 'Số hợp đồng không khớp đơn vị bảo lãnh.'}
d('LockInput', {'reason': {'type': 'string', 'maxLength': 2000}}, ['reason'])
EX['LockInput'] = {'reason': 'Nghi lạm dụng hạn mức sandbox, 20.000 lượt gọi trong 10 phút.'}
d('UnlockInput', {'reason': {'type': 'string', 'maxLength': 2000}}, ['reason'])
EX['UnlockInput'] = {'reason': 'Đã xác minh, hạn chế đã gỡ.'}
EX['DevAccountApproved'] = dict(DA1, status='ACTIVE', tenantGrants=['T68'])
EX['DevAccountRejected'] = dict(DA1, status='REJECTED')
EX['DevAccountLocked'] = dict(DA1, status='LOCKED', lockedReason='Nghi lạm dụng hạn mức sandbox')
EX['DevAccountUnlocked'] = dict(DA1, status='ACTIVE')
d('AuditRecord', {'auditId': 's', 'time': 'ts', 'action': ['VIEW_SENSITIVE_DOCS', 'DOWNLOAD_SPEC', 'TRY_API', 'TRY_PRODUCTION', 'SECRET_ISSUED', 'SUBMIT_SUBSCRIPTION', 'SUBMIT_ONBOARDING',
                                                            'SUBMIT_PUBLICATION', 'LOCK_ACCOUNT', 'UNLOCK_ACCOUNT', 'CHANGE_SETTING', 'VIEW_AUDIT', 'EXPORT_AUDIT'],
                  'actor': 's', 'apiCode': '#ApiCode', 'appCode': '#AppCode', 'result': 's', 'traceId': '#TraceId', 'detail': 'o'}, ['auditId', 'time', 'action', 'actor', 'result'])
AU1 = {'auditId': 'aud-01JD7M3', 'time': TS2, 'action': 'TRY_API', 'actor': 'nguyen.van.an', 'apiCode': 'tra-cuu-ho-tich', 'appCode': 'app-tra-cuu-ho-tich', 'result': 'OK', 'traceId': TRACE, 'detail': {'environment': 'SANDBOX', 'latencyMs': 131}}
EX['AuditRecord'] = AU1
page('AuditRecord', 'AuditPage', [AU1])
d('UsageReport', {'from': 'ts', 'to': 'ts', 'summary': 'o', 'topApis': '[#ApiStat]', 'topApps': '[s]'}, ['from', 'to', 'summary'])
EX['UsageReport'] = {'from': '2026-11-01T00:00:00Z', 'to': '2026-11-26T00:00:00Z', 'summary': {'visitors': 1200, 'developers': 84, 'apps': 61, 'tries': 5230, 'tryProduction': 12},
                     'topApis': [{'apiCode': 'tra-cuu-ho-tich', 'calls': 2100, 'errors': 30}], 'topApps': ['app-tra-cuu-ho-tich']}
d('AuditExportInput', {'format': ['csv', 'xlsx'], 'from': 'ts', 'to': 'ts', 'action': 's', 'actor': 's', 'apiCode': '#ApiCode', 'appCode': '#AppCode', 'result': 's'}, ['format', 'from', 'to'])
EX['AuditExportInput'] = {'format': 'csv', 'from': '2026-11-01T00:00:00Z', 'to': '2026-11-26T00:00:00Z', 'action': 'TRY_PRODUCTION'}
d('ExportAccepted', {'exportId': '#Uuid', 'state': ['QUEUED', 'RUNNING', 'DONE', 'FAILED'], 'downloadUrl': 's'}, ['exportId', 'state'])
EX['ExportAccepted'] = {'exportId': U1, 'state': 'QUEUED'}
d('SyncRunInput', {'scope': ['ALL', 'API'], 'apiCode': '#ApiCode'}, ['scope'])
EX['SyncRunInput'] = {'scope': 'API', 'apiCode': 'tra-cuu-ho-tich'}
d('SyncRun', {'runId': 's', 'kind': ['INCREMENTAL', 'FULL', 'RECONCILE'], 'state': ['QUEUED', 'RUNNING', 'OK', 'FAILED'], 'itemCount': 'i', 'errorCount': 'i', 'startedAt': 'ts', 'finishedAt': 'ts', 'lastError': 's'},
  ['runId', 'kind', 'state'])
SR1 = {'runId': 'run-20261126-0200', 'kind': 'INCREMENTAL', 'state': 'OK', 'itemCount': 3, 'errorCount': 0, 'startedAt': TS2, 'finishedAt': '2026-11-26T02:00:04Z'}
EX['SyncRun'] = dict(SR1, state='RUNNING', kind='FULL') and {'runId': 'run-20261126-0900', 'kind': 'FULL', 'state': 'RUNNING', 'startedAt': '2026-11-26T09:00:00Z'}
page('SyncRun', 'SyncRunPage', [SR1])
d('ReconcileInput', {'scope': ['ALL', 'API'], 'apiCode': '#ApiCode', 'fix': 'b'}, ['scope'])
EX['ReconcileInput'] = {'scope': 'ALL', 'fix': False}
d('ReconcileReport', {'runId': 's', 'state': ['RUNNING', 'OK', 'FAILED'], 'missing': '[s]', 'extra': '[s]', 'stale': '[s]', 'fixed': 'b', 'finishedAt': 'ts'}, ['runId', 'state'])
EX['ReconcileReport'] = {'runId': 'rec-20261126-0001', 'state': 'OK', 'missing': ['xac-thuc-cong-dan'], 'extra': [], 'stale': ['tra-cuu-ho-tich'], 'fixed': False, 'finishedAt': TS2}
EX['ReconcileAccepted'] = {'runId': 'rec-20261126-0001', 'state': 'RUNNING', 'missing': [], 'extra': [], 'stale': [], 'fixed': False}
d('MigrationUpload', {'file': {'type': 'string', 'contentMediaType': 'application/zip', 'contentEncoding': 'base64'}, 'note': 's'}, ['file'])
EX['MigrationUpload'] = {'file': 'UEsDBBQAAAAIAA==', 'note': 'Gói nội dung Gravitee portal đợt 1'}
d('Migration', {'migrationId': '#Uuid', 'state': ['SCANNING', 'PREVIEW_READY', 'CONFIRMED', 'APPLYING', 'DONE', 'REJECTED', 'FAILED'], 'preview': 'o', 'pagesCreated': 'i', 'attachments': 'i', 'skipped': 'i',
                'warnings': '[s]', 'createdAt': 'ts'}, ['migrationId', 'state', 'createdAt'])
EX['Migration'] = {'migrationId': U3, 'state': 'PREVIEW_READY', 'preview': {'pages': 24, 'attachments': 11, 'swaggerDocsDropped': 6}, 'warnings': ['6 tài liệu Swagger gắn API bị bỏ (đã có ở PH-02).'], 'createdAt': TS2}
d('MigrationConfirm', {'confirm': {'const': True}}, ['confirm'])
EX['MigrationConfirm'] = {'confirm': True}
EX['MigrationConfirmed'] = {'migrationId': U3, 'state': 'APPLYING', 'pagesCreated': 0, 'createdAt': TS2}
SCH['Migration']['properties']['preview']  # giữ

# lược đồ kiểm: dùng tại gen

# ---- Bổ sung 0.2: API-15-138…142 (đề nghị của tập màn hình và API, FRS 0.2)
d('PublicBranding', {k: v for k, v in SCH['Branding']['properties'].items() if k not in ('publicEnabled',)}, ['portalName'],
  desc='Nhận diện công khai của cổng (BR-15-032); không chứa tham số quản trị.')
EX['PublicBranding'] = {k: v for k, v in BR1.items() if k != 'publicEnabled'}
d('UnreadCount', {'unread': 'i', 'mandatoryUnread': 'i'}, ['unread'], ex={'unread': 3, 'mandatoryUnread': 1})
d('AppCodeCheck', {'appCode': '#AppCode', 'available': 'b', 'reason': ['IN_USE', 'ARCHIVED']}, ['appCode', 'available'],
  ex={'appCode': 'app-tra-cuu-ho-tich', 'available': False, 'reason': 'IN_USE'},
  desc='`reason` chỉ có khi `available = false`; `ARCHIVED` là mã của ứng dụng đã lưu trữ (vẫn không dùng lại được).')
d('PageDiffHunk', {'op': ['ADD', 'DEL', 'EQ'], 'baseLine': 'i', 'toLine': 'i', 'text': 's'}, ['op', 'text'])
d('PageDiff', {'pageCode': '#PageCode', 'base': 'i', 'to': 'i', 'added': 'i', 'removed': 'i', 'hunks': '[#PageDiffHunk]'}, ['pageCode', 'base', 'to', 'added', 'removed', 'hunks'],
  ex={'pageCode': 'bat-dau-nhanh', 'base': 2, 'to': 3, 'added': 1, 'removed': 1,
      'hunks': [{'op': 'EQ', 'baseLine': 1, 'toLine': 1, 'text': '# Bắt đầu nhanh'}, {'op': 'DEL', 'baseLine': 2, 'text': 'Gọi `GET /ho-tich`.'}, {'op': 'ADD', 'toLine': 2, 'text': 'Gọi `GET /ho-tich/{id}` kèm token.'}]},
  desc='Khác biệt theo dòng của Markdown nguồn; `text` là văn bản thuần, không phải HTML.')
