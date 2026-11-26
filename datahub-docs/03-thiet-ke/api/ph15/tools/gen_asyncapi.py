#!/usr/bin/env python3
"""Sinh asyncapi-portal.yaml (AsyncAPI 3.0) cho PH-15: EVT-15-01…14 (phát qua outbox) và các EVT-02-* mà cổng tiêu thụ.
Chạy: python3 gen_asyncapi.py (từ thư mục tools; ghi ../asyncapi-portal.yaml)."""
import os
import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
TS = '2026-11-26T09:15:02+07:00'
U = '0b5f3c1e-7d2a-4c8e-9a10-3f6e1d2b4a55'
TENANT = {'type': 'string', 'pattern': '^T[0-9]{2}$'}
ST = {'type': 'string'}
TSF = {'type': 'string', 'format': 'date-time'}
APP = {'$ref': '#/components/schemas/AppCode'}
API = {'$ref': '#/components/schemas/ApiCode'}
APPST = {'type': 'string', 'enum': ['ACTIVE', 'SUSPENDED', 'ARCHIVED']}
DEVST = {'type': 'string', 'enum': ['PENDING_EMAIL', 'PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'LOCKED', 'DISABLED', 'EXPIRED', 'ERASED']}
ROLE = {'type': 'string', 'enum': ['OWNER', 'DEVELOPER', 'VIEWER']}
SYNCST = {'type': 'string', 'enum': ['IDLE', 'RUNNING', 'FAILED', 'STALE']}
TRYST = {'type': 'string', 'enum': ['OFF', 'PENDING', 'ENABLED', 'EXPIRED']}

# (mã, tên kênh camelCase, hậu tố chủ đề, thực thể khóa phân vùng, FR, bên nhận, tóm tắt, thuộc tính, bắt buộc, ví dụ)
E15 = [
    ('EVT-15-01', 'appCreated', 'app.created', 'appCode', '025', 'PH-13', 'Ứng dụng sandbox được tạo.',
     {'appCode': APP, 'ownerType': {'type': 'string', 'enum': ['USER', 'TEAM']}, 'ownerId': ST}, ['appCode', 'ownerType', 'ownerId'],
     {'appCode': 'app-tra-cuu-ho-tich', 'ownerType': 'USER', 'ownerId': U}),
    ('EVT-15-02', 'appStateChanged', 'app.state-changed', 'appCode', '026, 059', 'PH-13, PH-03', 'Ứng dụng đổi trạng thái; PH-03 và `forward-auth` xóa bộ đệm.',
     {'appCode': APP, 'from': APPST, 'to': APPST, 'reason': ST}, ['appCode', 'from', 'to'],
     {'appCode': 'app-tra-cuu-ho-tich', 'from': 'ACTIVE', 'to': 'SUSPENDED', 'reason': 'Nghi lạm dụng hạn mức'}),
    ('EVT-15-03', 'credentialIssued', 'credential.issued', 'appCode', '027, 028', 'PH-13', 'Cấp thông tin xác thực sandbox; không mang bí mật.',
     {'appCode': APP, 'credentialId': ST, 'kind': {'type': 'string', 'enum': ['CLIENT_CREDENTIALS', 'API_KEY']}, 'expiresAt': TSF}, ['appCode', 'credentialId', 'kind', 'expiresAt'],
     {'appCode': 'app-tra-cuu-ho-tich', 'credentialId': U, 'kind': 'CLIENT_CREDENTIALS', 'expiresAt': '2027-02-24T09:00:00+07:00'}),
    ('EVT-15-04', 'credentialRotated', 'credential.rotated', 'appCode', '030', 'PH-13', 'Xoay vòng thông tin xác thực; bản cũ còn hiệu lực đến `graceUntil`.',
     {'appCode': APP, 'credentialId': ST, 'newCredentialId': ST, 'graceUntil': TSF}, ['appCode', 'credentialId', 'newCredentialId', 'graceUntil'],
     {'appCode': 'app-tra-cuu-ho-tich', 'credentialId': U, 'newCredentialId': '7c1d9a42-5b3e-4f60-8d17-2a9c0e5f6b31', 'graceUntil': '2026-11-27T09:00:00+07:00'}),
    ('EVT-15-05', 'credentialRevoked', 'credential.revoked', 'appCode', '031', 'PH-03, PH-13', 'Thu hồi hoặc hết hạn thông tin xác thực; `forward-auth` chặn trong ≤ 5 giây.',
     {'appCode': APP, 'credentialId': ST, 'reason': {'type': 'string', 'enum': ['REVOKED_BY_OWNER', 'EXPIRED', 'APP_ARCHIVED', 'ADMIN_LOCK']}}, ['appCode', 'credentialId', 'reason'],
     {'appCode': 'app-tra-cuu-ho-tich', 'credentialId': U, 'reason': 'REVOKED_BY_OWNER'}),
    ('EVT-15-06', 'devAccountRegistered', 'devaccount.registered', 'userId', '020', 'PH-13', 'Tài khoản dh-dev tự đăng ký; đã xác minh thư, chờ duyệt.',
     {'userId': ST, 'organization': ST}, ['userId', 'organization'], {'userId': U, 'organization': 'Công ty Giải pháp Số Việt'}),
    ('EVT-15-07', 'devAccountStateChanged', 'devaccount.state-changed', 'userId', '024, 058, 059', 'PH-13', 'Tài khoản dh-dev đổi trạng thái.',
     {'userId': ST, 'from': DEVST, 'to': DEVST}, ['userId', 'from', 'to'], {'userId': U, 'from': 'PENDING_APPROVAL', 'to': 'ACTIVE'}),
    ('EVT-15-08', 'contentPublished', 'content.published', 'pageCode', '015', 'PH-13', 'Trang nội dung được đăng sau duyệt bốn mắt.',
     {'pageCode': {'$ref': '#/components/schemas/PageCode'}, 'versionNo': {'type': 'integer'}, 'audience': {'type': 'string', 'enum': ['PUBLIC', 'LOGGED_IN', 'TENANT']}}, ['pageCode', 'versionNo', 'audience'],
     {'pageCode': 'bat-dau-nhanh', 'versionNo': 4, 'audience': 'PUBLIC'}),
    ('EVT-15-09', 'contentUnpublished', 'content.unpublished', 'pageCode', '016', 'PH-13', 'Trang nội dung bị gỡ đăng.',
     {'pageCode': {'$ref': '#/components/schemas/PageCode'}, 'versionNo': {'type': 'integer'}}, ['pageCode', 'versionNo'], {'pageCode': 'bat-dau-nhanh', 'versionNo': 4}),
    ('EVT-15-10', 'tryProductionStateChanged', 'try.production-state-changed', 'apiCode', '042', 'PH-13', 'Trạng thái thử production của một dịch vụ đổi.',
     {'apiCode': API, 'from': TRYST, 'to': TRYST, 'expiresAt': TSF}, ['apiCode', 'from', 'to'],
     {'apiCode': 'tra-cuu-ho-tich', 'from': 'PENDING', 'to': 'ENABLED', 'expiresAt': '2027-02-24T09:00:00+07:00'}),
    ('EVT-15-11', 'tryExecuted', 'try.executed', 'appCode', '035, 043', 'PH-13', 'Một lượt thử đã chạy; không mang thân yêu cầu hay phản hồi (BR-15-024).',
     {'tryId': ST, 'appCode': APP, 'env': {'type': 'string', 'enum': ['SANDBOX', 'PRODUCTION']}, 'apiCode': API,
      'result': {'type': 'string', 'enum': ['OK', 'UPSTREAM_ERROR', 'DENIED', 'THROTTLED', 'TIMEOUT']}, 'latencyMs': {'type': 'integer'}, 'traceId': ST}, ['tryId', 'env', 'apiCode', 'result', 'latencyMs'],
     {'tryId': 'TRY-20261126-000123', 'appCode': 'app-tra-cuu-ho-tich', 'env': 'SANDBOX', 'apiCode': 'tra-cuu-ho-tich', 'result': 'OK', 'latencyMs': 131, 'traceId': '4bf92f3577b34da6a3ce929d0e0e4736'}),
    ('EVT-15-12', 'supportTicketOpened', 'support.ticket-opened', 'ticketCode', '053, 054, 055', 'PH-13, PH-10', 'Phiếu hỗ trợ hoặc hỏi đáp mới; PH-10 dùng cho dịch vụ sự kiện.',
     {'ticketCode': {'$ref': '#/components/schemas/TicketCode'}, 'kind': {'type': 'string', 'enum': ['QUESTION', 'DOC_ERROR', 'SUPPORT_REQUEST', 'ACCESS_REQUEST', 'FEEDBACK']},
      'status': {'type': 'string', 'enum': ['OPEN', 'ANSWERED', 'RESOLVED', 'CLOSED']}, 'apiCode': API}, ['ticketCode', 'kind', 'status'],
     {'ticketCode': 'HT-2026-0042', 'kind': 'SUPPORT_REQUEST', 'status': 'OPEN', 'apiCode': 'tra-cuu-ho-tich'}),
    ('EVT-15-13', 'teamMemberChanged', 'team.member-changed', 'userId', '022, 033', 'PH-13', 'Thành viên nhóm hoặc ứng dụng đổi; đúng một trong `teamCode`, `appCode`.',
     {'teamCode': {'$ref': '#/components/schemas/TeamCode'}, 'appCode': APP, 'userId': ST, 'role': ROLE, 'change': {'type': 'string', 'enum': ['ADDED', 'ROLE_CHANGED', 'REMOVED']}}, ['userId', 'role', 'change'],
     {'appCode': 'app-tra-cuu-ho-tich', 'userId': '7c1d9a42-5b3e-4f60-8d17-2a9c0e5f6b31', 'role': 'DEVELOPER', 'change': 'ADDED'}),
    ('EVT-15-14', 'syncStateChanged', 'sync.state-changed', 'tenantId', '001, 061', 'PH-13', 'Trạng thái đồng bộ danh mục với PH-02 đổi (kể cả `STALE` khi trễ > 900 giây).',
     {'from': SYNCST, 'to': SYNCST, 'lagSeconds': {'type': 'integer'}}, ['from', 'to', 'lagSeconds'], {'from': 'IDLE', 'to': 'STALE', 'lagSeconds': 1260}),
]

# EVT-02 tiêu thụ: (mã, kênh, hậu tố thực thể.sự-kiện, FR dùng, tóm tắt, thuộc tính thêm, bắt buộc thêm, ví dụ thêm, khóa)
V = {'$ref': '#/components/schemas/SemVer'}
E02 = [
    ('EVT-02-01', 'catalogApiRegistered', 'api.registered', '001', 'API được đăng ký; kích hoạt kéo gia tăng.', {}, [], {}, 'apiCode'),
    ('EVT-02-02', 'catalogApiUpdated', 'api.updated', '001, 002', 'Đổi thông tin, phân loại, mức hiển thị, chủ quản, SLA; `visibility` hoặc `portalPublished` đổi thì cổng cập nhật chỉ mục ngay.',
     {'changedFields': {'type': 'array', 'items': ST}}, ['changedFields'], {'changedFields': ['visibility', 'sla']}, 'apiCode'),
    ('EVT-02-03', 'catalogApiDeleted', 'api.deleted', '001', 'API bị xóa mềm; cổng gỡ khỏi bản sao và chỉ mục.', {}, [], {}, 'apiCode'),
    ('EVT-02-05', 'catalogVersionPublished', 'version.published', '001, 013', 'Phiên bản sang `PUBLISHED`; cổng nạp đặc tả.', {'versionNo': V}, ['versionNo'], {'versionNo': '1.0.0'}, 'apiCode'),
    ('EVT-02-06', 'catalogVersionStateChanged', 'version.state-changed', '001, 013', 'Tạm ngừng, tiếp tục, ngừng khuyến nghị, ngừng hẳn; cổng hiện banner `DEPRECATED`.',
     {'versionNo': V, 'from': {'type': 'string'}, 'to': {'type': 'string'}, 'sunsetAt': TSF}, ['versionNo', 'to'], {'versionNo': '1.0.0', 'from': 'PUBLISHED', 'to': 'DEPRECATED', 'sunsetAt': '2027-06-30T00:00:00Z'}, 'apiCode'),
    ('EVT-02-08', 'catalogPlanStateChanged', 'plan.state-changed', '001, 006', 'Gói đổi trạng thái hoặc khai báo; cổng cập nhật danh sách gói.', {'planCode': ST}, ['planCode'], {'planCode': 'co-ban'}, 'apiCode'),
    ('EVT-02-09', 'catalogSubscriptionRequested', 'subscription.requested', '045', 'Đăng ký chờ duyệt; cổng chỉ làm mới bộ đệm đăng ký của người dùng, không phát lại (BR-15-014).',
     {'subscriptionId': ST, 'systemCode': ST}, ['subscriptionId'], {'subscriptionId': U, 'systemCode': 'HT-DATDAI'}, 'subscriptionId'),
    ('EVT-02-10', 'catalogSubscriptionActivated', 'subscription.activated', '043, 045', 'Đăng ký được cấp phạm vi; cổng làm mới điều kiện thử production.',
     {'subscriptionId': ST, 'systemCode': ST}, ['subscriptionId', 'systemCode'], {'subscriptionId': U, 'systemCode': 'HT-DATDAI'}, 'subscriptionId'),
    ('EVT-02-11', 'catalogSubscriptionStateChanged', 'subscription.state-changed', '043, 045', 'Từ chối, tạm ngừng, thu hồi, hủy, hết hạn; cổng thu hồi quyền thử production nếu cần.',
     {'subscriptionId': ST, 'systemCode': ST, 'to': ST}, ['subscriptionId', 'to'], {'subscriptionId': U, 'systemCode': 'HT-DATDAI', 'to': 'REVOKED'}, 'subscriptionId'),
    ('EVT-02-12', 'catalogChangeNoticeIssued', 'change.notice-issued', '013, 051, 052', 'Thông báo thay đổi đã phát; cổng tra người theo dõi rồi ghi hộp thông báo.',
     {'noticeId': ST, 'kind': {'type': 'string'}, 'mandatory': {'type': 'boolean'}, 'title': ST, 'versionNo': V}, ['noticeId', 'kind', 'title'],
     {'noticeId': 'tb-2026-0007', 'kind': 'DEPRECATED', 'mandatory': True, 'title': 'tra-cuu-ho-tich 1.0.0 ngừng khuyến nghị', 'versionNo': '1.0.0'}, 'apiCode'),
]


def headers(ev_type):
    return {'type': 'object', 'additionalProperties': True, 'required': ['ce_specversion', 'ce_id', 'ce_source', 'ce_type', 'ce_time', 'dhtenant'],
            'properties': {'ce_specversion': {'type': 'string', 'const': '1.0'}, 'ce_id': ST, 'ce_source': ST, 'ce_type': {'type': 'string', 'pattern': r'^vn\.datahub\.[a-z0-9-]+(\.[a-z0-9-]+)+$'},
                           'ce_time': TSF, 'ce_subject': ST, 'dhtenant': TENANT, 'traceparent': ST}}


def main():
    ch, op, msgs, sch = {}, {}, {}, {}
    sch['AppCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9-]{2,40}$'}
    sch['ApiCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9-]{2,63}$'}
    sch['PageCode'] = {'type': 'string', 'pattern': '^[a-z0-9][a-z0-9-]{1,62}$'}
    sch['TeamCode'] = {'type': 'string', 'pattern': '^[a-z][a-z0-9-]{2,40}$'}
    sch['TicketCode'] = {'type': 'string', 'pattern': '^HT-[0-9]{4}-[0-9]{4,}$'}
    sch['SemVer'] = {'type': 'string', 'pattern': '^[0-9]+\\.[0-9]+\\.[0-9]+$'}
    for i, (code, name, suffix, key, fr, to, summ, props, req, ex) in enumerate(E15):
        sn = name[0].upper() + name[1:]
        sch[sn] = {'type': 'object', 'additionalProperties': False, 'required': ['tenantId', 'occurredAt'] + req,
                   'properties': dict({'tenantId': TENANT, 'occurredAt': TSF}, **props)}
        address = '{tenant}.portal.%s.v1' % suffix
        ch[name] = {'address': address, 'title': code, 'description': '%s Truy vết FR-15-%s. Bên nhận: %s. Khóa phân vùng: `%s`.' % (summ, fr.replace(', ', ', FR-15-'), to, key),
                    'messages': {name: {'$ref': '#/components/messages/' + name}}, 'parameters': {'tenant': {'$ref': '#/components/parameters/tenant'}},
                    'bindings': {'kafka': {'topic': address, 'partitions': 3, 'replicas': 3, 'topicConfiguration': {'cleanup.policy': ['delete'], 'retention.ms': 604800000, 'min.insync.replicas': 2}}}}
        msgs[name] = {'name': name, 'title': code, 'summary': summ, 'contentType': 'application/json', 'payload': {'$ref': '#/components/schemas/' + sn}, 'headers': headers(None),
                      'bindings': {'kafka': {'key': {'type': 'string', 'description': '`%s`' % key}}},
                      'examples': [{'name': code, 'headers': {'ce_specversion': '1.0', 'ce_id': '01JD3Z5Q8R2S4T6V8W0X2Y4Z%02d' % (i + 10), 'ce_source': '/t68/services/dh-connect-portal',
                                                               'ce_type': 'vn.datahub.portal.' + suffix, 'ce_time': TS, 'ce_subject': str(ex.get(key, 'T68')), 'dhtenant': 'T68',
                                                               'traceparent': '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'},
                                    'payload': dict({'tenantId': 'T68', 'occurredAt': TS}, **ex)}]}
        op['send' + name[0].upper() + name[1:]] = {'action': 'send', 'channel': {'$ref': '#/channels/' + name}, 'messages': [{'$ref': '#/channels/%s/messages/%s' % (name, name)}],
                                                   'title': '%s: PH-15 phát qua outbox' % code}
    for code, name, suffix, fr, summ, props, req, ex, key in E02:
        sn = name[0].upper() + name[1:]
        base = {'tenantId': TENANT, 'occurredAt': TSF}
        if key == 'apiCode':
            base['apiCode'] = API
        sch[sn] = {'type': 'object', 'additionalProperties': True, 'required': ['tenantId', 'occurredAt'] + (['apiCode'] if key == 'apiCode' else []) + req,
                   'properties': dict(base, **props), 'description': 'Tập con trường PH-15 dùng; bên đọc bỏ qua trường lạ (tolerant reader). Hợp đồng đầy đủ do PH-02 giữ (D03-04-PH02).'}
        address = '{tenant}.catalog.%s.v1' % suffix
        ch[name] = {'address': address, 'title': code, 'description': '%s PH-15 là bên nhận (nhóm consumer `portal-catalog`, inbox lũy đẳng theo `ce_id`). Truy vết FR-15-%s.' % (summ, fr.replace(', ', ', FR-15-')),
                    'messages': {name: {'$ref': '#/components/messages/' + name}}, 'parameters': {'tenant': {'$ref': '#/components/parameters/tenant'}},
                    'bindings': {'kafka': {'topic': address}}}
        pl = dict({'tenantId': 'T68', 'occurredAt': TS}, **({'apiCode': 'tra-cuu-ho-tich'} if key == 'apiCode' else {}), **ex)
        msgs[name] = {'name': name, 'title': code, 'summary': summ, 'contentType': 'application/json', 'payload': {'$ref': '#/components/schemas/' + sn}, 'headers': headers(None),
                      'bindings': {'kafka': {'key': {'type': 'string', 'description': '`%s`' % key}}},
                      'examples': [{'name': code, 'headers': {'ce_specversion': '1.0', 'ce_id': '01JD3Y0A1B2C3D4E5F6G7H8J%02d' % len(msgs), 'ce_source': '/t68/services/dh-catalog', 'ce_type': 'vn.datahub.catalog.' + suffix,
                                                               'ce_time': TS, 'dhtenant': 'T68'}, 'payload': pl}]}
        op['receive' + sn[0].upper() + sn[1:]] = {'action': 'receive', 'channel': {'$ref': '#/channels/' + name}, 'messages': [{'$ref': '#/channels/%s/messages/%s' % (name, name)}],
                                                  'title': '%s: PH-15 tiêu thụ' % code}
    doc = {
        'asyncapi': '3.0.0',
        'info': {'title': 'Datahub PH-15 Cổng nhà phát triển: sự kiện', 'version': '1.0.0-draft',
                 'description': ('Hợp đồng sự kiện EVT-15-01…14 do PH-15 phát (outbox `ph15_portal.outbox_event`, Debezium, Kafka) và các sự kiện EVT-02-* do PH-02 phát mà cổng tiêu thụ (D03-04-PH15 §4, FRS §9.2). '
                                 'CloudEvents 1.0 nhị phân, `ce_type = vn.datahub.portal.{thực-thể}.{sự-kiện}`; lược đồ Avro tương ứng ở Apicurio, chế độ BACKWARD (ở đây mô tả bằng JSON Schema). '
                                 'Sự kiện không mang bí mật hay thân yêu cầu. Lưu giữ 7 ngày, 3 phân vùng (giả định theo mức của PH-10, Q15-58). Người nhận xử lý lũy đẳng theo `ce_id` (inbox). '
                                 'Tương thích: chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`.'),
                 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)'}},
        'defaultContentType': 'application/json',
        'servers': {'kafka-internal': {'host': 'dh-kafka-kafka-bootstrap.dh-kafka.svc:9093', 'protocol': 'kafka-secure',
                                       'description': 'Listener `internal`: DU `dh-connect` (vai trò `worker`), Kafka Connect; mTLS, ACL theo CN và tiền tố tenant (D03-09).',
                                       'security': [{'$ref': '#/components/securitySchemes/mtls'}]}},
        'channels': ch, 'operations': op,
        'components': {'parameters': {'tenant': {'description': 'Mã tenant chữ thường (`t68`).', 'examples': ['t68']}},
                       'securitySchemes': {'mtls': {'type': 'X509', 'description': 'Chứng thư do CA nội bộ cấp (cert-manager, PH-12); ACL Kafka theo CN.'}},
                       'messages': msgs, 'schemas': sch}}
    out = os.path.join(HERE, '..', 'asyncapi-portal.yaml')
    open(out, 'w', encoding='utf-8').write('# D03-04-PH15 · AsyncAPI PH-15. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n' + yaml.safe_dump(doc, allow_unicode=True, sort_keys=False, width=160))
    print('ghi', out, len(ch), 'kênh')


if __name__ == '__main__':
    main()
