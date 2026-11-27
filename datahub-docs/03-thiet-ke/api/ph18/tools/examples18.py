#!/usr/bin/env python3
"""Sinh ví dụ yêu cầu và phản hồi cho OpenAPI PH-18 từ lược đồ (theo tên trường), ghi đè tay vài thao tác chính ở EX.

Quy tắc an toàn (gitleaks, BR-18-050): không ví dụ nào mang chuỗi giống khóa bí mật; trường có chữ `key` dùng giá trị có dấu
hai chấm hoặc dấu chấm ngắn; tổng kiểm tra dùng mẫu hex lặp; bí mật chỉ là đường dẫn OpenBao; địa chỉ thư luôn đã che.
Mọi tên, mã, số là giả lập (tenant `T68`)."""
import hashlib

TS = '2026-11-27T09:15:02+07:00'
HEX64 = 'e3b0c442' * 8
TRACE = '4bf92f3577b34da6a3ce929d0e0e4736'


def uid(name):
    h = hashlib.md5(name.encode()).hexdigest()
    return '0190a1b2-c3d4-7e5f-8a6b-' + h[:12]


PAT = {'ParamKey': '18.dlq.replay.batch-max', 'FlagKey': 'ff.ph04.moi', 'SourceCode': 'ph04-runtime', 'ModuleCode': 'PH-04', 'TenantCode': 'T68',
       'ErrorCode': 'ERR-04-101', 'TemplateCode': 'ph01.ho-so.da-duyet', 'TaskTypeCode': 'ph01.approve-onboarding', 'TraceId': TRACE,
       'VaultRef': 'kv/dh/t68/legacy/esb-bus', 'Sha256': HEX64, 'ReplayIdempotencyKey': uid('dlqId') + ':1', 'MergePlanId': 'SN-2026-001'}
# giá trị theo (lược đồ cha, trường) rồi theo trường
PF = {
    ('DlqMessage', 'reason'): 'TARGET_UNAVAILABLE', ('DlqMessageDetail', 'reason'): 'TARGET_UNAVAILABLE', ('DlqMessageInput', 'reason'): 'TARGET_UNAVAILABLE',
    ('TenantRestoreInput', 'reason'): 'Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026',
    ('TenantRestore', 'reason'): 'Khôi phục dữ liệu bị xóa nhầm theo Công văn 245/STTTT-CNTT ngày 26/11/2026',
    ('Incident', 'title'): 'Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt', ('IncidentDetail', 'title'): 'Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt',
    ('IncidentInput', 'title'): 'Luồng đồng bộ hồ sơ một cửa lỗi hàng loạt', ('IncidentReportInput', 'title'): 'Độ sâu DLQ nguồn ph04-runtime vượt ngưỡng',
    ('NotificationTemplate', 'title'): 'Hồ sơ kết nạp đã được duyệt', ('TemplateInput', 'title'): 'Hồ sơ kết nạp đã được duyệt',
    ('ParamNamespace', 'title'): 'Vận hành và xử lý lỗi', ('NamespaceSchemaInput', 'title'): 'Vận hành và xử lý lỗi',
    ('MigrationPlan', 'title'): 'Di trú Bus cũ đợt 1', ('MigrationPlanDetail', 'title'): 'Di trú Bus cũ đợt 1', ('MigrationPlanInput', 'title'): 'Di trú Bus cũ đợt 1',
    ('ParallelGroup', 'title'): 'Nhóm dịch vụ tra cứu hộ tịch', ('ParallelGroupDetail', 'title'): 'Nhóm dịch vụ tra cứu hộ tịch',
    ('ErrorGuide', 'title'): 'Hệ đích không phản hồi', ('ErrorGuideInput', 'title'): 'Hệ đích không phản hồi', ('ErrorGuideSummary', 'title'): 'Hệ đích không phản hồi',
    ('MeNotification', 'title'): 'Bạn có hồ sơ kết nạp chờ duyệt', ('TaskType', 'title'): 'Duyệt hồ sơ kết nạp HTTT', ('TaskTypeInput', 'title'): 'Duyệt hồ sơ kết nạp HTTT',
    ('IncidentAction', 'title'): 'Bổ sung cảnh báo chứng thư sắp hết hạn',
    ('LegacySource', 'name'): 'Bus tích hợp cũ', ('LegacySourceInput', 'name'): 'Bus tích hợp cũ', ('BackupObject', 'name'): 'Sao lưu cơ sở cụm pg-core',
    ('CalendarHoliday', 'name'): 'Tết Dương lịch', ('CalendarHolidayInput', 'name'): 'Tết Dương lịch', ('DiagMetric', 'name'): 'dh_ops_dlq_depth',
    ('TemplateVariable', 'name'): 'maHoSo', ('LegacySource', 'sourceCode'): 'esb-bus-cu', ('LegacySourceInput', 'sourceCode'): 'esb-bus-cu',
    ('MigrationPlan', 'sourceCode'): 'esb-bus-cu', ('MigrationPlanDetail', 'sourceCode'): 'esb-bus-cu', ('MigrationPlanInput', 'sourceCode'): 'esb-bus-cu',
    ('DiagLog', 'message'): 'Gọi hệ đích quá thời gian 30 giây', ('ParamValidateItemResult', 'message'): 'Giá trị nằm trong miền',
    ('MigrationErrorRecord', 'message'): 'Thiếu đơn vị cha của mã H68.12', ('FieldError', 'message'): 'Lý do quá ngắn',
    ('TemplateSyntaxError', 'message'): 'Thẻ chưa đóng', ('EscalatePrivacyInput', 'summary'): 'Tệp xuất danh sách hồ sơ bị gửi nhầm địa chỉ',
    ('EventDeadLetter', 'status'): 'OPEN', ('EventDeadLetter', 'reason'): 'MAX_ATTEMPTS', ('FacetCount', 'value'): 'ph04-runtime',
    ('NotificationRule', 'eventType'): 'integration.version.submitted.v1', ('NotificationRuleInput', 'eventType'): 'integration.version.submitted.v1',
    ('MigrationErrorRecord', 'reasonCode'): 'MISSING_PARENT', ('AuditEntry', 'action'): 'PARAM_VALUE_CHANGED', ('AuditEntry', 'objectType'): 'param_value',
    ('CutoverLogEntry', 'action'): 'PARTIAL_CUTOVER', ('DlqReconciliation', 'status'): 'COMPLETED',
}
STR = {
    'ns': '18.', 'label': 'Số mục tối đa một lượt phát lại', 'group': 'Phát lại', 'unit': 'mục', 'description': 'Mô tả ngắn phục vụ vận hành tỉnh',
    'reason': 'Đích đã phục hồi sau sự cố mạng, xử lý theo phiếu VH-2026-118', 'comment': 'Đã đối chiếu với quy trình vận hành của tỉnh',
    'note': 'Đã liên hệ chủ quản HTTT', 'stage': 'goi-he-dich', 'flow': 'hs-mot-cua-dong-bo', 'flowVersion': '3', 'version': '3',
    'dlqKey': 'ph04-runtime:hs-mot-cua-dong-bo:msg-0123', 'messageId': 'msg-2026-000123', 'errorMessage': 'Hệ đích trả 503 sau 3 lần thử',
    'contentType': 'application/json', 'schemaRef': 'schema/ho-so-mot-cua/v3', 'assignee': 'tran.thi.binh', 'requestedBy': 'nguyen.van.an',
    'approvedBy': 'le.thi.chi', 'decidedBy': 'le.thi.chi', 'reviewedBy': 'le.thi.chi', 'actor': 'tran.thi.binh', 'createdBy': 'nguyen.van.an',
    'updatedBy': 'tran.thi.binh', 'changedBy': 'nguyen.van.an', 'publishedBy': 'le.thi.chi', 'ownerUser': 'pham.van.duc', 'claimedBy': 'tran.thi.binh',
    'readyBy': 'nguyen.van.an', 'checkedBy': 'le.thi.chi', 'recordedBy': 'nguyen.van.an', 'approver': 'le.thi.chi', 'recipientUser': 'tran.thi.binh',
    'userId': 'tran.thi.binh', 'owner': 'pham.van.duc', 'title': 'Tiêu đề ngắn', 'host': 'webhook.so-tttt.t68.gov.vn',
    'url': 'https://ops.t68.datahub.example.vn/tai-ve/XT-2026-0003', 'downloadUrl': 'https://ops.t68.datahub.example.vn/tai-ve/BC-2026-11',
    'downloadPdf': '/api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-000000000011/reconciliation?format=pdf', 'downloadCsv': '/api/ops/v1/migration-runs/0190a1b2-c3d4-7e5f-8a6b-000000000011/reconciliation?format=csv',
    'link': '/ket-noi/ho-so/HS-0042', 'linkTemplate': '/ket-noi/ho-so/{ref}', 'linkRoute': '/su-kien/dlq/ENTRY-77', 'replayTarget': 't68.integration.replay.v1',
    'sourceRef': 'onboarding:HS-0042', 'typeGroup': 'TASK', 'condition': "data.decision == 'REJECTED'", 'jobCode': 'RJ-2026-0031', 'bundleCode': 'PB-2026-0004',
    'windowCode': 'MW-2026-0012', 'incidentCode': 'SC-2026-0007', 'requestNo': 'KP-2026-0002', 'exportCode': 'XT-2026-0003', 'drillCode': 'DT-2026-0001',
    'planCode': 'DT-BUS-01', 'groupCode': 'NHOM-HO-TICH', 'reportCode': 'BC-2026-11', 'ruleCode': 'qt-ho-so-duyet', 'replayCode': 'RP-0091', 'entryRef': 'ENTRY-77',
    'subscriptionCode': 'sub-ho-tich', 'topic': 't68.civil.birth.registered.v1', 'objectCode': 'pg-core-base', 'objectKind': 'POSTGRES_BASE', 'name': 'Tên mẫu',
    'jdbcUrl': 'jdbc:postgresql://bus-cu.t68.local:5432/esb', 'networkZone': 'VUNG-HE-CU', 'converter': 'bus-flow-xml-v1', 'filter': "trang_thai = 'HOAT_DONG'",
    'systemCode': 'HTTT-QLVB', 'applicationRef': 'app-qlvb', 'route': '/api/ho-tich/v1/khai-sinh', 'diffKind': 'BODY', 'module': 'ph01_onboarding',
    'mappingRef': 'ph20/merge-plans/MP-0003/mappings/ph01', 'stepCode': 'SUSPEND_TENANT', 'table': 'ph01_onboarding.application', 'jobName': 'dh-tenant-restore-t68-0002',
    'location': 'garage://dh-backup/pg-core/2026-11-27', 'evidenceRef': 'garage://dh-t68-ops/bien-ban/DT-2026-0001.pdf', 'schedule': '0 0 1 * * *',
    'timezone': 'Asia/Ho_Chi_Minh', 'locale': 'vi', 'subject': 'Hồ sơ {{maHoSo}} đã được duyệt', 'body': 'Hồ sơ {{maHoSo}} đã được duyệt. Xem chi tiết tại {{lienKet}}.',
    'renderedSubject': 'Hồ sơ HS-0042 đã được duyệt', 'renderedBody': 'Hồ sơ HS-0042 đã được duyệt. Xem chi tiết tại /ket-noi/ho-so/HS-0042.',
    'example': 'HS-0042', 'recipientMasked': 'ng***@t68.gov.vn', 'addressMasked': 'ng***@t68.gov.vn', 'ref': 'tran.thi.binh', 'providerMessageId': 'smtp-7f3a91',
    'lastErrorCode': 'ERR-18-110', 'errorCode': 'ERR-04-101', 'resultErrorCode': 'ERR-04-105', 'smtpCode': '550', 'messageRef': 'smtp-7f3a91',
    'quietHours': '22:00-06:00', 'summary': 'Duyệt hồ sơ kết nạp HTTT quản lý văn bản', 'content': 'Đã tạm dừng luồng để chặn lỗi lan rộng',
    'rootCause': 'Hệ đích hết hạn chứng thư TLS nên từ chối mọi kết nối từ 02:10', 'lessonsLearned': 'Cần cảnh báo chứng thư sắp hết hạn trước 14 ngày cho mọi hệ đích',
    'impactSummary': 'Chậm đồng bộ 1.240 hồ sơ trong 3 giờ', 'profile': 'QM-VUA', 'status': 'ACTIVE', 'origin': 'SUBSCRIBER', 'reasonCode': 'MISSING_PARENT',
    'action': 'TRIAGE', 'objectType': 'param_value', 'objectId': '18.dlq.replay.batch-max', 'sampleMessage': 'Hệ đích trả 503', 'window': 'PT5M', 'service': 'dh-runtime',
    'operation': 'POST /ho-so', 'message': 'Đã xử lý', 'unavailableReason': 'PH-13 quá thời gian', 'path': '$.trangThai', 'field': 'reason', 'code': 'ERR-18-003',
    'detail': 'Trường reason cần ít nhất 10 ký tự', 'component': 'dlq-ingest', 'readOnlyReason': 'Bảo trì cụm pg-core', 'legalBasis': 'Bộ luật Lao động 2019, Điều 112',
    'viewPermission': 'PERM-01-review', 'sourceType': 'ALERT', 'resultMessage': 'Hệ đích nhận bản tin', 'evidence': 'Biên bản họp ngày 25/11/2026',
    'variable': 'soDinhDanh', 'sourceRecordRef': 'dm_don_vi:H68.12', 'fieldPath': '$.maDonViCha', 'errorCodeText': 'ERR-04-101', 'privacyCaseRef': 'VP-2026-0005',
    'eventType': 'integration.version.submitted.v1', 'cancelReason': 'Hệ đích chưa phục hồi', 'rejectComment': 'Bộ lọc quá rộng, cần thu hẹp theo luồng',
    'waivedReason': 'HTTT đã ngừng', 'errorMessageText': 'Hệ đích trả 503', 'type': 'ph01.ho-so.da-duyet', 'instance': '/api/ops/v1/dlq/messages',
}
INT = {'version': 3, 'versionNo': 4, 'page': 0, 'size': 20, 'totalElements': 1, 'port': 443, 'attempts': 3, 'year': 2026, 'ratePerSecond': 10,
       'maxRatePerSecond': 50, 'stopOnFailurePercent': 20, 'httpStatus': 201, 'legacyStatus': 200, 'datahubStatus': 200, 'stepNo': 1, 'order': 1,
       'schemaVersion': 7, 'revision': 1, 'revisionNo': 1, 'currentRevisionNo': 1, 'runNo': 2, 'line': 4, 'index': 0, 'status': 503, 'trafficPercent': 20,
       'workingDays': 5, 'defaultDueWorkingDays': 2, 'sourceVersion': 3, 'estimatedSubjects': 120, 'windowHours': 24, 'activeVersionNo': 2, 'keyCount': 61,
       'cacheTtlSeconds': 60, 'unreadCount': 3, 'count': 37, 'occurrences': 4, 'ageMinutes': 95, 'total': 1240, 'succeeded': 1180, 'failed': 12, 'skipped': 48}
NUM = {'matchRate': 99.6, 'matchThresholdPercent': 99.5, 'mirrorPercent': 5, 'progressPercent': 42.5, 'sizeGb': 38.5, 'groupMatchRate': 99.7, 'value': 37, 'min': 1, 'max': 50000}
TRUE = {'enabled', 'valid', 'ok', 'readOnly', 'passed', 'matched', 'supportsRevision', 'mandatory', 'includeObjects', 'dryRun', 'notify', 'defaultValue',
        'readOnlyVerified', 'approvalRequired', 'createTask', 'hashChainValid', 'fourEyes', 'secure'}
OBJ = {'bundle': {'format': 'dh-param-bundle/1', 'namespaces': ['18.'], 'items': 61}, 'contextHeaders': {'dh-flow': 'hs-mot-cua-dong-bo', 'dh-dlq-stage': 'goi-he-dich'},
       'variables': {'maHoSo': 'HS-0042', 'lienKet': '/ket-noi/ho-so/HS-0042'}, 'sampleData': {'maHoSo': 'HS-0042', 'lienKet': '/ket-noi/ho-so/HS-0042'},
       'metrics': {'dlqOpen': 37, 'backupFreshPercent': 100}}
ANY = {'value': 10000, 'default': 10000, 'previousValue': 5000, 'proposedValue': 10000, 'currentValue': 5000, 'before': 5000, 'after': 10000,
       'payload': {'soHoSo': 'HS-2026-000123', 'trangThai': 'DA_TIEP_NHAN'}, 'content': {'soHoSo': 'HS-2026-000123', 'trangThai': 'DA_TIEP_NHAN'}}
ARR = {'groups': ['Phát lại', 'Lưu giữ'], 'namespaces': ['18.'], 'causes': ['Hệ đích quá tải hoặc đang bảo trì'], 'steps': ['Kiểm tra trạng thái hệ đích', 'Phát lại khi hệ đích phục hồi'],
       'links': ['/van-hanh/dlq?ma-loi=ERR-04-101'], 'issues': ['Chuyển DNS lâu hơn dự kiến'], 'exemptions': ['VA_ATTT_KHAN'], 'affectedSystems': ['HTTT-QLVB'],
       'owners': ['nhom-van-hanh-t68'], 'maskedFields': ['$.congDan.soDinhDanh'], 'maskedPaths': ['$.congDan.soDinhDanh'], 'missingFields': ['dh-flow'],
       'dataCategories': ['Họ tên', 'Số định danh cá nhân'], 'schemas': ['esb'], 'fixRules': ['chuan-hoa-ma-don-vi'], 'routes': ['/api/ho-tich/v1/khai-sinh'],
       'diffPaths': ['$.data.ngayCap'], 'modules': ['ph01_onboarding'], 'unknown': [], 'unresolved': [], 'excludeUsers': ['nguyen.van.an'], 'flow': ['hs-mot-cua-dong-bo'],
       'added': ['18.dlq.replay.batch-max'], 'changed': [], 'deprecated': [], 'enum': ['MONTHLY', 'QUARTERLY'], 'days': ['2026-12-01', '2026-12-02'],
       'skippedDates': ['2026-12-05', '2026-12-06'], 'weekendDays': ['SAT', 'SUN'], 'environments': ['PROD'], 'channels': ['EMAIL']}
DATE = {'retireBy': '2027-03-31', 'removalDate': '2027-06-30', 'expiresAt': '2027-11-27', 'date': '2027-01-01', 'from': '2026-11-01', 'to': '2026-11-30',
        'targetCutoverDate': '2027-03-01', 'retireBefore': '2027-01-01', 'dueAt': '2026-12-15'}
TSV = {'from': '2026-11-26T00:00:00+07:00', 'to': '2026-11-27T00:00:00+07:00', 'startsAt': '2026-12-06T22:00:00+07:00', 'endsAt': '2026-12-07T02:00:00+07:00',
       'targetTime': '2026-11-26T08:00:00+07:00', 'startedAt': '2026-11-27T02:00:00+07:00', 'finishedAt': '2026-11-27T02:40:00+07:00'}
ENUM_PICK = {'ParamType': 'INT', 'DlqStatus': 'TRIAGED', 'Priority': 'P2', 'ReplayJobStatus': 'APPROVED', 'IncidentStatus': 'INVESTIGATING', 'Severity': 'SEV2',
             'ErrorClass': 'TRANSIENT', 'ReplayMode': 'KAFKA_TOPIC', 'ParamLevel': 'TENANT', 'DeliveryStatus': 'SENT', 'RecipientKind': 'USER', 'Channel': 'EMAIL',
             'JobStatus': 'RUNNING', 'CutoverStatus': 'SHADOW_OK', 'RestoreStatus': 'PENDING_APPROVAL', 'MigrationRunStatus': 'QUEUED', 'TemplateVersionStatus': 'DRAFT',
             'ClassLevel': 'INTERNAL', 'ParamVersionStatus': 'ACTIVE', 'ChangeRequestStatus': 'PENDING_APPROVAL', 'TaskStatus': 'OPEN', 'BackupTool': 'CNPG_BARMAN',
             'BackupResult': 'SUCCEEDED', 'Freshness': 'FRESH', 'ObjectType': 'FLOW', 'RunMode': 'DRY_RUN', 'UseRevision': 'LATEST_APPROVED', 'Replayable': 'YES',
             'HealthState': 'UP', 'NotifyPriority': 'NORMAL', 'LegacySystem': 'BUS', 'ExportPurpose': 'HANDOVER', 'DrillKind': 'DR_SWITCHOVER',
             'DiscardReasonCode': 'HANDLED_AT_SOURCE', 'RevisionStatus': 'APPROVED', 'EgressPurpose': 'WEBHOOK', 'Environment': 'PROD', 'Weekday': 'SAT'}
UID = {'id': uid('id')}


def resolve(s, S):
    while '$ref' in s:
        s = S[s['$ref'].split('/')[-1]]
    return s


def gen(s, S, parent, field, depth, full):
    name = s['$ref'].split('/')[-1] if '$ref' in s else None
    if name in PAT:
        if (parent, field) in PF:
            return PF[(parent, field)]
        return PAT[name]
    if name and 'enum' in S[name]:
        return ENUM_PICK.get(name, S[name]['enum'][0])
    if name:
        return obj(S[name], S, name, depth, full)
    if (parent, field) in PF:
        return PF[(parent, field)]
    if 'enum' in s:
        return s['enum'][0]
    t = s.get('type')
    if t is None:
        return ANY.get(field, 10)
    if t == 'array':
        it = resolve(s['items'], S)
        if field in ARR and it.get('type') != 'object':
            return ARR[field]
        return [gen(s['items'], S, parent, field, depth + 1, full and field == 'items')]
    if t == 'object':
        if 'properties' in s:
            return obj(s, S, parent, depth, full)
        return OBJ.get(field, {'ghiChu': 'giả lập'})
    if t == 'boolean':
        return field in TRUE
    if t == 'integer':
        v = INT.get(field, 12)
        lo, hi = s.get('minimum'), s.get('maximum')
        if lo is not None and v < lo:
            v = lo
        if hi is not None and v > hi:
            v = hi
        return v
    if t == 'number':
        return NUM.get(field, 12.5)
    fmt = s.get('format')
    if fmt == 'uuid':
        return UID.get(field) or uid(field)
    if fmt == 'date-time':
        return TSV.get(field, TS)
    if fmt == 'date':
        return DATE.get(field, '2026-12-31')
    if fmt == 'uri':
        return 'https://datahub.gov.vn/errors/ERR-18-003'
    if s.get('pattern') == '^([01][0-9]|2[0-3]):[0-5][0-9]$':
        return '22:00'
    v = STR.get(field, 'giá trị mẫu')
    if s.get('minLength') and len(v) < s['minLength']:
        v = STR['reason'] if s['minLength'] <= 60 else v
    return v


def obj(s, S, name, depth, full):
    out = {}
    req = s.get('required', [])
    for f, fs in s.get('properties', {}).items():
        if f in req or (full and depth <= 1):
            if depth > 3 and f not in req:
                continue
            out[f] = gen(fs, S, name, f, depth + 1, False)
    return out


EX = {
    6: ({'value': 10000, 'reason': 'Tăng giới hạn để xử lý tồn đọng sau sự cố mạng ngày 26/11'},
        {'key': '18.dlq.replay.batch-max', 'ns': '18.', 'value': 10000, 'version': 5, 'source': 'TENANT', 'level': 'TENANT', 'secure': False, 'status': 'ACTIVE',
         'effectiveFrom': TS, 'updatedAt': TS, 'updatedBy': 'nguyen.van.an'}),
    35: ({'tenant': 'T68', 'sourceCode': 'ph19-inbox', 'sourcePh': 'PH-19', 'messageId': 'pay-cb-2026-0091', 'reason': 'TARGET_UNAVAILABLE', 'errorCode': 'ERR-19-104',
          'stage': 'xu-ly-callback', 'attempts': 5, 'errorClass': 'TRANSIENT', 'traceId': TRACE, 'contentType': 'application/json',
          'payload': {'maGiaoDich': 'GD-2026-000045', 'trangThai': 'THANH_CONG'}},
         {'dlqId': uid('dlqId'), 'status': 'NEW', 'duplicate': False, 'occurrences': 1, 'storage': 'INLINE'}),
    65: ({'filter': {'sourceCode': ['ph04-runtime'], 'errorCode': ['ERR-04-101'], 'status': ['TRIAGED', 'REPLAY_FAILED']}, 'useRevision': 'LATEST_APPROVED',
          'ratePerSecond': 10, 'reason': 'Hệ đích đã phục hồi lúc 08:30, phát lại tồn đọng theo phiếu VH-2026-118'},
         None),
    91: ({'type': 'ph01.ho-so.da-duyet', 'recipients': [{'kind': 'SYSTEM_CONTACT', 'ref': 'HTTT-QLVB:CHU_QUAN'}], 'variables': {'maHoSo': 'HS-0042', 'lienKet': '/ket-noi/ho-so/HS-0042'},
          'priority': 'NORMAL', 'sourceRef': 'onboarding:HS-0042'},
         {'messageId': uid('messageId'), 'status': 'QUEUED', 'duplicate': False, 'recipients': 2}),
    175: ({'action': 'REQUEST', 'target': 'PARTIAL_CUTOVER', 'trafficPercent': 20, 'reason': 'Đạt ngưỡng khớp 7 ngày, cắt chuyển 20% theo kế hoạch tuần 49'}, None),
    150: ({'mergePlanId': 'SN-2026-001', 'module': 'PH-01', 'sourceTenant': 'T67', 'targetTenant': 'T68', 'mappingRef': 'ph20/merge-plans/MP-0003/mappings/ph01',
           'dryRun': True}, None),
}


def examples(n, req_s, resp_s, S):
    rq = obj(S[req_s], S, req_s, 0, True) if req_s else None
    rs = None
    if resp_s and resp_s in S and resp_s != 'CsvFile':
        rs = obj(S[resp_s], S, resp_s, 0, True)
    if n in EX:
        a, b = EX[n]
        rq = a if a is not None else rq
        rs = b if b is not None else rs
    if rs and 'items' in rs and 'page' in rs:
        rs['page'], rs['size'], rs['totalElements'] = 0, 20, len(rs['items'])
    return rq, rs


PATHX = {'key': '18.dlq.replay.batch-max', 'versionNo': 4, 'revisionNo': 1, 'year': 2026, 'flagKey': 'ff.ph04.moi', 'tenant': 'T68', 'errCode': 'ERR-04-101',
         'templateCode': 'ph01.ho-so.da-duyet', 'ns': '18.', 'entryRef': 'ENTRY-77', 'notificationId': 'all', 'sourceRef': 'onboarding:HS-0042',
         'incidentCode': 'SC-2026-0007', 'planCode': 'DT-BUS-01', 'groupCode': 'NHOM-HO-TICH',
         'itemCode': 'STAKEHOLDER_SIGNOFF', 'revision': 1}


def path_example(pn, path):
    if pn == 'sourceCode':
        return 'ph04-runtime' if 'dlq-sources' in path else 'esb-bus-cu'
    return PATHX.get(pn) or uid(pn)


def query_example(name, n):
    if n == 14 and name == 'from':
        return 3
    return {'from': '2026-11-01' if n == 116 else '2026-11-26T00:00:00+07:00', 'to': '2026-11-30' if n == 116 else '2026-11-27T00:00:00+07:00',
            'year': 2026, 'updatedSince': '2026-11-20T00:00:00+07:00', 'mergePlanId': 'SN-2026-001', 'planCode': 'DT-BUS-01', 'reason': 'Đích không còn dùng',
            }.get(name, 'giá trị mẫu')


def location(full, n):
    import re
    base = re.sub(r'\{(\w+)\}', lambda m: str(path_example(m.group(1), full)), full)
    tail = {21: 'ff.ph04.moi', 83: 'ph01.ho-so.da-duyet', 85: '2', 124: 'SC-2026-0007', 157: 'esb-bus-cu', 160: 'DT-BUS-01', 32: 'ph19-inbox'}.get(n, uid('id'))
    return base + '/' + tail


CSV_DLQ = 'dlqId,sourceCode,errorCode,errorClass,status,receivedAt\n%s,ph04-runtime,ERR-04-101,TRANSIENT,TRIAGED,%s\n' % (uid('dlqId'), TS)
CSV_MIG = 'objectType,sourceRecordRef,reasonCode,status\nCATALOG,dm_don_vi:H68.12,MISSING_PARENT,OPEN\n'
CSV_RECON = 'objectType,sourceCount,targetCount,missing,extra,mismatched,matched\nFLOW,412,412,0,0,0,true\n'
