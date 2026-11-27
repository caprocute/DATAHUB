#!/usr/bin/env python3
"""Sinh ../openapi-ops.yaml (OpenAPI 3.1) cho PH-18 từ FRS D02-03-PH18: §9.4 (API-18-001…188), §9.1 (ERR-18, cột FR).
API người dùng `/api/ops/v1` qua APISIX; API nội bộ `/ops/internal/v1` chỉ trong cụm (mTLS, SPIFFE, scope máy).
Mọi đường dẫn trong tệp viết đầy đủ (kể cả tiền tố) để hai mặt API không đụng nhau. Lược đồ ở schemas18.py,
ví dụ sinh từ lược đồ bằng examples18.py (ghi đè tay vài thao tác chính ở EX).
Chạy từ thư mục tools: python3 gen_openapi.py. Không sửa tay tệp YAML; sửa FRS hoặc các tệp này rồi sinh lại."""
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsl18  # noqa: E402
import examples18 as X  # noqa: E402
import schemas18 as S18  # noqa: E402

FRS = open(os.path.join(HERE, '..', '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH18-frs-van-hanh.md'), encoding='utf-8').read()
SEC94 = FRS[FRS.index('### 9.4. Danh mục API'):FRS.index('## 10. Giao diện')]
SEC91 = FRS[FRS.index('### 9.1. Mã lỗi'):FRS.index('### 9.2.')]
USER_BASE, INT_BASE = '/api/ops/v1', '/ops/internal/v1'

ROWS = re.findall(r'^\| API-18-(\d{3}) \| `(GET|POST|PUT|PATCH|DELETE) ([^`]+)` \| ([^|]+) \| ([^|]+) \| (.+) \|$', SEC94, re.M)
_er = re.findall(r'^\| (ERR-18-\d{3}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', SEC91, re.M)
ERRS = {c: ((int(h) if h.strip().isdigit() else None), m.strip(), t.strip().strip('"'), [int(x) for x in re.findall(r'\d{3}', fr)]) for c, h, m, t, fr in _er}
assert len(ROWS) == 188, len(ROWS)
assert len(ERRS) == 96, len(ERRS)
FR_ERR = {}
for _c, (_h, _m, _t, _frs) in ERRS.items():
    if _h is None:
        continue
    for _f in _frs:
        FR_ERR.setdefault(_f, set()).add(_c)
STRUCT = {'ERR-18-%03d' % i for i in range(1, 11)}
READ_ONLY_TOGGLE = 187

SCH = S18.build()

TAGS = [
    ('Tham số và cờ tính năng', 'Không gian tên và lược đồ khóa, giá trị theo tenant có kiểm miền và trần, đề nghị bốn mắt cho khóa ★, phiên bản, '
     'gói tham số, cờ tính năng, egress, API nội bộ `ParameterApi` (FR-18-001…011).', 1, 30),
    ('Tiếp nhận DLQ', 'Nguồn DLQ và cổng phát lại, ghi DLQ qua API cho phân hệ khác, đối soát chỉ mục với Kafka, liên thông DLQ tầng sự kiện của PH-10 (FR-18-012…018).', 31, 40),
    ('Phân loại và xử lý DLQ', 'Danh sách có `facets`, nhóm dấu hiệu lỗi, chi tiết và chẩn đoán từ PH-13, xem payload có lý do, phân loại, gán, bản sửa payload, '
     'sổ tay mã lỗi, API đọc cho PH-17 và PH-13 (FR-18-019…026).', 41, 63),
    ('Phát lại, bỏ qua và lưu giữ', 'Phát lại một mục, lượt phát lại loạt có bốn mắt, điều khiển tốc độ, kết quả lũy đẳng, bỏ qua, mở lại, lưu giữ, thống kê (FR-18-027…034).', 64, 81),
    ('Thông báo', 'Mẫu thông báo có phiên bản và kiểm trường cấm, `NotificationApi` bất đồng bộ và đồng bộ, người nhận, tùy chọn nhận, quy tắc theo sự kiện, '
     'nhật ký gửi, thư trả lại, danh sách chặn (FR-18-035…041).', 82, 106),
    ('Việc của tôi và lịch', '`TaskInboxApi` (loại việc, tạo, đóng việc lũy đẳng, Việc của tôi), `WorkingCalendarApi` (lịch năm, tính hạn), cửa sổ bảo trì và đóng băng '
     '(FR-18-042…046).', 107, 122),
    ('Sự cố vận hành', 'Hồ sơ sự cố từ sự kiện hoặc tạo tay, vòng đời, mốc thời gian, liên kết, chuyển PH-09, đóng có nguyên nhân và bài học (FR-18-047…051).', 123, 132),
    ('Sao lưu, khôi phục và sáp nhập', 'Bảng sao lưu, kiểm tra khôi phục, khôi phục tenant tám bước có bốn mắt, xuất tenant, chuyển dữ liệu khi sáp nhập (PH-20), '
     'ghi nhận diễn tập DR (FR-18-052…058).', 133, 155),
    ('Di trú và chạy song song', 'Nguồn hệ cũ chỉ đọc, kế hoạch di trú, chạy thử và chạy thật có bốn mắt, bản ghi lỗi, đối chiếu, cấp lại thông tin xác thực, '
     'chạy song song, mẫu so sánh bóng, cắt chuyển và quay lui (FR-18-059…068).', 156, 176),
    ('Quản trị và báo cáo', 'Nhật ký thao tác vận hành, báo cáo định kỳ, sức khỏe phân hệ và chế độ suy giảm (FR-18-069…072).', 177, 180),
]


# API bổ sung ở FRS 0.2 (đồng bộ nội bộ PH-18) mang số 181 trở đi, gắn vào nhóm theo FR
TAG_EXTRA = {181: 'Việc của tôi và lịch', 182: 'Di trú và chạy song song', 183: 'Di trú và chạy song song', 184: 'Di trú và chạy song song',
             185: 'Di trú và chạy song song', 186: 'Quản trị và báo cáo', 187: 'Quản trị và báo cáo', 188: 'Phát lại, bỏ qua và lưu giữ'}


def tag_of(n):
    if n in TAG_EXTRA:
        return TAG_EXTRA[n]
    return next(t for t, _, a, b in TAGS if a <= n <= b)


# (thân yêu cầu, mã thành công, lược đồ phản hồi) cho mọi operation
OP = {
    1: (None, 200, 'ParamNamespacePage'), 2: (None, 200, 'ParamDefinitionPage'), 3: (None, 200, 'ParamDefinition'), 4: (None, 200, 'ParamValuePage'),
    5: (None, 200, 'ParamValue'), 6: ('ParamValueInput', 200, 'ParamValue'), 7: ('ParamValidateInput', 200, 'ParamValidateResult'),
    8: (None, 200, 'ParamChangeRequestPage'), 9: (None, 200, 'ParamChangeRequest'), 10: ('ApproveInput', 200, 'ParamValueVersion'),
    11: ('RejectInput', 200, 'ParamChangeRequest'), 12: ('CancelInput', 200, 'ParamChangeRequest'), 13: (None, 200, 'ParamValueVersionPage'),
    14: (None, 200, 'ParamVersionCompare'), 15: ('ReasonInput', 200, 'ParamValue'), 16: (None, 200, 'ParamChangePage'),
    17: ('BundleExportInput', 201, 'ParamBundle'), 18: ('BundleImportInput', 200, 'ParamBundle'), 19: ('ReasonInput', 200, 'ParamBundle'),
    20: (None, 200, 'FeatureFlagPage'), 21: ('FeatureFlagInput', 201, 'FeatureFlag'), 22: ('FeatureFlagPatch', 200, 'FeatureFlag'),
    23: ('ReasonInput', 200, 'FeatureFlag'), 24: (None, 200, 'EgressEntryPage'), 25: ('EgressInput', 201, 'EgressEntry'), 26: (None, 204, None),
    27: ('NamespaceSchemaInput', 200, 'NamespaceRegistration'), 28: ('ParamBatchGetInput', 200, 'ParamBatchResult'), 29: (None, 200, 'ParamSnapshot'),
    30: ('SeedDefaultsInput', 200, 'SeedResult'),
    31: (None, 200, 'DlqSourcePage'), 32: ('DlqSourceInput', 201, 'DlqSource'), 33: ('DlqSourcePatch', 200, 'DlqSource'), 34: ('DlqSourceInput', 200, 'DlqSource'),
    35: ('DlqMessageInput', 201, 'DlqIngestResult'), 36: ('DlqBatchInput', 207, 'DlqBatchResult'), 37: (None, 200, 'DlqReconciliation'),
    38: ('ReconcileInput', 202, 'DlqReconciliation'), 39: (None, 200, 'EventDeadLetterPage'), 40: ('ReasonInput', 202, 'EventReplayRequest'),
    41: (None, 200, 'DlqMessagePage'), 42: (None, 200, 'CsvFile'), 43: (None, 200, 'DlqGroupPage'), 44: ('GroupAssignInput', 200, 'DlqGroup'),
    45: (None, 200, 'DlqMessageDetail'), 46: (None, 200, 'DlqDiagnostics'), 47: ('PayloadRevealInput', 200, 'PayloadReveal'), 48: (None, 200, 'PayloadSkeleton'),
    49: ('TriageInput', 200, 'DlqMessage'), 50: ('AssignInput', 200, 'DlqMessage'), 51: ('BulkTriageInput', 207, 'BulkResult'), 52: (None, 200, 'DlqRevisionPage'),
    53: ('RevisionInput', 201, 'DlqRevision'), 54: (None, 200, 'RevisionDiff'), 55: ('ApproveInput', 200, 'DlqRevision'), 56: ('RejectInput', 200, 'DlqRevision'),
    57: (None, 200, 'ErrorGuidePage'), 58: (None, 200, 'ErrorGuide'), 59: ('ErrorGuideInput', 200, 'ErrorGuide'), 60: (None, 200, 'DlqMessagePage'),
    61: (None, 200, 'DlqMessageDetail'), 62: (None, 200, 'ErrorGuideFeed'), 63: (None, 200, 'DlqAuditEntryPage'),
    64: ('ReplayInput', 202, 'ReplayAccepted'), 65: ('ReplayJobInput', 201, 'ReplayJob'), 66: (None, 200, 'ReplayJobPage'), 67: (None, 200, 'ReplayJob'),
    68: (None, 200, 'ReplayItemPage'), 69: (None, 200, 'ReplayJob'), 70: ('ApproveInput', 200, 'ReplayJob'), 71: ('RejectInput', 200, 'ReplayJob'),
    72: (None, 200, 'ReplayJob'), 73: (None, 200, 'ReplayJob'), 74: ('CancelInput', 200, 'ReplayJob'), 75: ('ReplayJobPatch', 200, 'ReplayJob'),
    76: ('ReplayResultInput', 200, 'ReplayResultAck'), 77: ('DiscardInput', 200, 'DlqMessage'), 78: ('BulkDiscardInput', 207, 'BulkResult'),
    79: ('ReasonInput', 200, 'DlqMessage'), 80: (None, 200, 'DlqRetention'), 81: (None, 200, 'DlqStats'),
    82: (None, 200, 'NotificationTemplatePage'), 83: ('TemplateInput', 201, 'NotificationTemplate'), 84: (None, 200, 'NotificationTemplate'),
    85: ('TemplateVersionInput', 201, 'TemplateVersion'), 86: ('PreviewInput', 200, 'TemplatePreview'), 87: (None, 200, 'TemplateVersion'),
    88: ('ApproveInput', 200, 'TemplateVersion'), 89: ('RejectInput', 200, 'TemplateVersion'), 90: ('ReasonInput', 200, 'NotificationTemplate'),
    91: ('NotificationInput', 202, 'NotificationAccepted'), 92: ('NotificationInput', 200, 'NotificationSyncResult'), 93: (None, 200, 'NotificationStatus'),
    94: ('RecipientResolveInput', 200, 'RecipientResolveResult'), 95: (None, 200, 'NotificationPreferences'),
    96: ('NotificationPreferencesInput', 200, 'NotificationPreferences'), 97: (None, 200, 'MeNotificationPage'), 98: (None, 200, 'ReadResult'),
    99: (None, 200, 'NotificationRulePage'), 100: ('NotificationRuleInput', 201, 'NotificationRule'), 101: ('NotificationRulePatch', 200, 'NotificationRule'),
    102: (None, 200, 'NotificationDeliveryPage'), 103: ('ReasonInput', 202, 'NotificationDelivery'), 104: (None, 200, 'SuppressionPage'), 105: (None, 204, None),
    106: ('BounceInput', 202, 'BounceAck'),
    107: ('TaskTypeInput', 200, 'TaskType'), 108: (None, 200, 'TaskTypePage'), 109: ('TaskUpsertInput', 200, 'TaskItem'), 110: ('TaskCloseInput', 200, 'TaskItem'),
    111: (None, 200, 'MyTaskPage'), 112: (None, 200, 'TaskItem'), 113: (None, 200, 'WorkCalendar'), 114: ('WorkCalendarInput', 200, 'WorkCalendar'),
    115: ('CalendarHolidayInput', 201, 'CalendarHoliday'), 116: (None, 200, 'WorkingDaysResult'), 117: ('AddWorkingDaysInput', 200, 'AddWorkingDaysResult'),
    118: (None, 200, 'MaintenanceWindowPage'), 119: ('MaintenanceWindowInput', 201, 'MaintenanceWindow'), 120: ('MaintenanceWindowPatch', 200, 'MaintenanceWindow'),
    121: ('ReasonInput', 200, 'MaintenanceWindow'), 122: (None, 200, 'FreezeStatus'),
    123: (None, 200, 'IncidentPage'), 124: ('IncidentInput', 201, 'Incident'), 125: (None, 200, 'IncidentDetail'), 126: ('IncidentPatch', 200, 'Incident'),
    127: ('IncidentTransitionInput', 200, 'Incident'), 128: ('TimelineInput', 201, 'IncidentTimelineEntry'), 129: ('IncidentLinkInput', 201, 'IncidentLink'),
    130: ('EscalatePrivacyInput', 200, 'EscalationResult'), 131: ('IncidentCloseInput', 200, 'Incident'), 132: ('IncidentReportInput', 201, 'Incident'),
    133: (None, 200, 'BackupObjectPage'), 134: (None, 200, 'BackupRunPage'), 135: ('BackupRunReport', 202, 'BackupRunAck'), 136: (None, 200, 'RestoreVerificationPage'),
    137: ('VerificationReport', 202, 'VerificationAck'), 138: ('TenantRestoreInput', 201, 'TenantRestore'), 139: (None, 200, 'TenantRestorePage'),
    140: (None, 200, 'TenantRestore'), 141: (None, 200, 'TenantRestore'), 142: ('RestoreApproveInput', 200, 'TenantRestore'), 143: ('RejectInput', 200, 'TenantRestore'),
    144: ('CancelInput', 200, 'TenantRestore'), 145: (None, 200, 'TenantRestoreStepList'), 146: ('ReasonInput', 202, 'TenantRestore'),
    147: ('TenantExportInput', 201, 'TenantExport'), 148: (None, 200, 'TenantExport'), 149: (None, 200, 'DownloadLink'), 150: ('MergeTransferInput', 202, 'MergeTransfer'),
    151: (None, 200, 'MergeTransferPage'), 152: (None, 200, 'MergeTransfer'), 153: ('CancelInput', 200, 'MergeTransfer'), 154: (None, 200, 'DrDrillPage'),
    155: ('DrDrillInput', 201, 'DrDrill'),
    156: (None, 200, 'LegacySourcePage'), 157: ('LegacySourceInput', 201, 'LegacySource'), 158: (None, 200, 'ConnectionTestResult'), 159: (None, 200, 'MigrationPlanPage'),
    160: ('MigrationPlanInput', 201, 'MigrationPlan'), 161: (None, 200, 'MigrationPlanDetail'), 162: ('MigrationPlanItemsInput', 200, 'MigrationPlanDetail'),
    163: (None, 200, 'MigrationPlanDetail'), 164: ('MigrationRunInput', 202, 'MigrationRun'), 165: (None, 200, 'MigrationRunPage'), 166: (None, 200, 'MigrationRun'),
    167: ('ApproveInput', 200, 'MigrationRun'), 168: ('RejectInput', 200, 'MigrationRun'), 169: ('CancelInput', 200, 'MigrationRun'),
    170: (None, 200, 'MigrationErrorRecordPage'), 171: (None, 200, 'MigrationReconciliationReport'), 172: (None, 200, 'CredentialReissuePage'),
    173: (None, 200, 'ParallelGroupPage'), 174: (None, 200, 'ParallelGroupDetail'), 175: ('CutoverTransitionInput', 200, 'ParallelGroup'),
    176: ('ShadowSampleBatch', 202, 'ShadowAck'),
    177: (None, 200, 'AuditEntryPage'), 178: (None, 200, 'OpsReportPage'), 179: ('ReportGenerateInput', 202, 'OpsReport'), 180: (None, 200, 'Health'),
    181: (None, 200, 'TaskItem'), 182: ('MigrationErrorFixInput', 200, 'BulkResult'), 183: ('ReasonInput', 200, 'CredentialReissue'),
    184: ('NormalizationRulesInput', 200, 'NormalizationRuleSet'), 185: ('ChecklistConfirmInput', 200, 'CutoverChecklistItem'), 186: (None, 200, 'InboxFailurePage'),
    187: ('DegradedModeInput', 200, 'Health'), 188: (None, 200, 'ReplayPayload'),
}
# phản hồi thành công thêm (mã, lược đồ, mô tả)
EXTRA_OK = {
    6: (202, 'ParamChangeRequest', 'Khóa ★: đã tạo đề nghị chờ duyệt (`PENDING_APPROVAL`), giá trị hiệu lực chưa đổi.'),
    28: (304, None, 'Ảnh chụp không đổi so với `If-None-Match`.'), 29: (304, None, 'Ảnh chụp không đổi so với `If-None-Match`.'),
    46: (206, 'DlqDiagnostics', 'PH-13 trả một phần hoặc quá thời gian (ERR-18-106); `partial = true`.'),
    132: (200, 'Incident', 'Đã có sự cố cùng `sourceRef`: cập nhật mốc, không tạo mới.'),
}
DLQ_FILT = 'sourceCode:[scode], flow:s, errorCode:err, errorClass:#ErrorClass, status:#DlqStatus, age:e(1h|24h|7d), assignee:s, priority:#Priority, groupId:u, from:ts, to:ts, q:s'
FILT = {
    1: 'ownerPh:ph, status:e(ACTIVE|RETIRED)', 2: 'ns:s, group:s, secure:b, level:#ParamLevel, q:s', 4: 'ns:s, group:s, q:s, changedOnly:b',
    8: 'status:#ChangeRequestStatus, key:pkey', 13: 'status:#ParamVersionStatus', 14: 'from!:i, to:i, compareToDefault:b',
    16: 'ns:s, key:pkey, changedBy:s, from:ts, to:ts', 20: 'ownerPh:ph, status:e(ACTIVE|RETIRED), retireBefore:d', 24: 'purpose:#EgressPurpose, usedBy:ph',
    26: 'reason!:s', 31: 'sourcePh:ph, replayMode:#ReplayMode, status:e(ACTIVE|PAUSED)',
    39: 'subscriptionCode:s, topic:s, errorCode:s, from:ts, to:ts', 41: DLQ_FILT, 42: DLQ_FILT,
    43: 'sourceCode:scode, errorClass:#ErrorClass, windowHours:i', 52: 'status:#RevisionStatus', 57: 'q:s, ownerPh:ph, errorClass:#ErrorClass, replayable:#Replayable',
    60: DLQ_FILT, 61: 'includePayload:b', 62: 'updatedSince!:ts', 63: 'action:#DlqAuditAction',
    66: 'status:#ReplayJobStatus, requestedBy:s, from:ts, to:ts', 68: 'status:#ReplayItemStatus',
    81: 'interval:e(24h|7d|30d|90d), sourceCode:scode, groupBy:e(SOURCE|FLOW|ERROR_CLASS|STATUS)',
    82: 'channel:#Channel, ownerPh:ph, status:e(ACTIVE|RETIRED), q:s', 97: 'unreadOnly:b', 99: 'eventType:s, templateCode:tcode, enabled:b',
    102: 'type:tcode, channel:#Channel, status:#DeliveryStatus, recipientUser:s, callerPh:ph, from:ts, to:ts', 104: 'channel:e(EMAIL|SMS), reason:e(HARD_BOUNCE|COMPLAINT|INVALID|MANUAL)',
    105: 'reason!:s', 108: 'ownerPh:ph', 111: 'taskType:ttype, ownerPh:ph, due:e(OVERDUE|TODAY|THIS_WEEK), status:#TaskStatus, summary:b',
    113: 'year!:i', 116: 'from!:d, to!:d', 118: 'kind:e(MAINTENANCE|FREEZE), environment:#Environment, from:ts, to:ts',
    123: 'severity:#Severity, status:#IncidentStatus, assignee:s, from:ts, to:ts', 133: 'tool:#BackupTool, freshness:#Freshness',
    134: 'objectCode:s, result:#BackupResult, from:ts, to:ts', 136: 'objectCode:s, result:e(PASSED|FAILED), from:ts, to:ts', 139: 'status:#RestoreStatus',
    151: 'mergePlanId!:u, module:s', 154: 'kind:#DrillKind, from:ts, to:ts', 156: 'legacySystem:#LegacySystem, status:e(DRAFT|VERIFIED|DISABLED)',
    159: 'sourceCode:s, status:e(DRAFT|READY)', 165: 'planCode!:s, mode:#RunMode, status:#MigrationRunStatus',
    170: 'objectType:#ObjectType, reasonCode:s, status:#MigrationErrorStatus', 172: 'systemCode:s, status:e(PENDING|NOTIFIED|REISSUED|WAIVED), credentialKind:#CredentialKind',
    173: 'status:#CutoverStatus, q:s', 186: 'module:s, consumer:s, from:ts, to:ts', 177: 'action:s, objectType:s, actor:s, from!:ts, to!:ts', 178: 'period:e(MONTH|QUARTER), from:d, to:d',
}
PATH_P = {'key': 'pkey', 'versionNo': 'i', 'revisionNo': 'i', 'year': 'i', 'flagKey': 'fkey', 'tenant': 'tn', 'errCode': 'err', 'templateCode': 'tcode',
          'ns': 's', 'entryRef': 's', 'notificationId': 's', 'sourceRef': 's', 'incidentCode': 's', 'planCode': 's', 'groupCode': 's',
          'itemCode': '#ChecklistItemCode', 'revision': 'i'}
# mã nguồn DLQ ở /dlq-sources dùng mẫu SourceCode; ở /legacy-sources là chuỗi
IFM_VERBS = {'approve', 'reject', 'withdraw', 'restore', 'apply', 'retire', 'triage', 'assign', 'discard', 'reopen', 'submit', 'pause', 'resume', 'cancel',
             'transition', 'close', 'escalate-privacy', 'rollback', 'mark-ready', 'claim', 'waive', 'confirm'}
NO_IFM = {44}
# ví dụ có cả khóa `type` và `default` (tên trường FRS của lược đồ khóa) bị Spectral hiểu nhầm là lược đồ: bỏ ví dụ, xem D03-04-PH18 §12
NO_EX = {3, 27}
SAFE_POST = {7, 28, 86, 94, 117}
IDEM_OPT = {76, 98, 106, 135, 137, 176}
STATE_VERBS = IFM_VERBS | {'replay', 'request-replay', 'run', 'resend', 'read', 'download-link', 'test-connection', 'generate'}
FOUR_EYES = {10, 11, 55, 56, 70, 71, 88, 89, 142, 143, 167, 168, 175}
# lỗi miền: lấy từ cột FR của §9.1; ghi đè khi FR gắn nhiều thao tác khác nhau
ONLY = {28: [], 32: ['ERR-18-002'], 33: [], 34: ['ERR-18-017'], 55: [], 56: [], 70: [], 71: [], 72: [], 73: [], 74: [], 83: ['ERR-18-002'], 88: [], 89: [], 90: [],
        105: [], 106: [], 110: ['ERR-18-048'], 117: [], 121: [], 127: [], 135: [], 137: [], 142: [], 143: [], 144: [], 146: [], 149: [], 153: [], 158: ['ERR-18-062'],
        160: ['ERR-18-002'], 167: ['ERR-18-051', 'ERR-18-064'], 168: [], 169: [], 23: [], 26: [], 12: [], 11: [], 22: ['ERR-18-021'], 15: ['ERR-18-023'],
        10: ['ERR-18-013', 'ERR-18-019'], 59: [], 61: [], 115: ['ERR-18-049'], 131: ['ERR-18-052'], 130: ['ERR-18-053', 'ERR-18-054'], 98: [], 87: ['ERR-18-039', 'ERR-18-040'],
        141: ['ERR-18-056', 'ERR-18-057', 'ERR-18-058'], 181: ['ERR-18-048'], 182: ['ERR-18-036'], 183: [], 184: [], 185: ['ERR-18-067'], 187: [], 188: ['ERR-18-038'], 163: ['ERR-18-063'], 162: ['ERR-18-063'], 76: ['ERR-18-038'], 128: [], 129: [], 124: [], 126: []}
EXCL = {64: {'ERR-18-038'}, 91: {'ERR-18-044', 'ERR-18-046'}, 92: {'ERR-18-046'}, 164: {'ERR-18-069'}, 109: {'ERR-18-039'}}
ADD = {3: {'ERR-18-011'}, 5: {'ERR-18-011'}, 6: {'ERR-18-011'}, 13: {'ERR-18-011'}, 14: {'ERR-18-011'}, 15: {'ERR-18-011'}, 46: set(), 64: {'ERR-18-027'},
       47: {'ERR-18-027'}, 41: {'ERR-18-003'}, 60: {'ERR-18-003'}, 164: {'ERR-18-065'}, 182: {'ERR-18-007'}}
SC = {'ops:param-read': 'Đọc lô giá trị tham số, cờ, egress (mọi DU)', 'ops:param-register': 'Đăng ký lược đồ không gian tên của mình (mọi DU)',
      'ops:param-write': 'Ghi mặc định khi khởi tạo tenant (PH-20)', 'ops:dlq-write': 'Ghi DLQ qua API, đăng ký nguồn (PH-01, PH-06, PH-08, PH-19, dh-runtime)',
      'ops:dlq-read': 'Đọc siêu dữ liệu DLQ và sổ tay ERR bằng token đổi từ người dùng (PH-17, PH-13)', 'ops:replay-callback': 'Nguồn báo kết quả phát lại',
      'ops:notify': 'Gửi thông báo, tra trạng thái, báo thư trả lại', 'ops:task': 'Đăng ký loại việc, tạo, đóng việc', 'ops:calendar-read': 'Tính ngày làm việc, trạng thái đóng băng',
      'ops:incident-write': 'Mở, cập nhật sự cố (PH-13, PH-09)', 'ops:migration-import': 'Phân hệ đích nhận lô di trú từ dh-migrate (PH-18 gọi ra)',
      'ops:backup-report': 'Báo bản sao lưu, kết quả kiểm tra khôi phục', 'ops:merge-transfer': 'Yêu cầu, hủy chuyển dữ liệu sáp nhập (PH-20)',
      'ops:shadow-ingest': 'Bộ so sánh bóng gửi cặp phản hồi đã băm'}
KEY_NOTE = {
    10: 'Duyệt bốn mắt: người duyệt khác người đề nghị (ERR-18-005); giá trị thành `ACTIVE`, phiên bản cũ `SUPERSEDED`, phát EVT-18-01.',
    27: 'PH chủ đăng ký lược đồ khi khởi động; lũy đẳng theo `schemaVersion`. Không gian tên không thuộc phân hệ gọi: ERR-18-017; lược đồ mới xung đột giá trị đang dùng: ERR-18-016.',
    28: 'Đọc lô cho `dh-ops-client` (bộ đệm Caffeine ≤ 60 giây, BR-18-006); gửi `If-None-Match` để nhận `304` khi không đổi (NFR-18-004).',
    30: 'PH-20 gọi khi nhận `platform.tenant.created.v1` hoặc khi khởi tạo; chỉ thêm khóa chưa có, không ghi đè giá trị tenant đã đặt (FR-18-011).',
    35: 'Ghi một mục DLQ theo hợp đồng ngữ cảnh chuẩn (FRS bảng 4.1b). Thiếu trường bắt buộc: từ chối `422` với ERR-18-024, mục không được ghi (BR-18-013; đường topic mới ghi `POISON`); '
        'payload > `18.dlq.payload.inline-max-kb` lưu ở Garage, > `18.dlq.payload.max-mb` trả ERR-18-025; khử trùng theo `dlqKey` (trùng trả `duplicate = true`).',
    36: 'Ghi lô tới 500 mục; phản hồi `207` với kết quả từng mục theo `index`, không hủy cả lô khi một mục lỗi.',
    40: 'PH-18 không tự phát lại mục tầng sự kiện; gọi API-10-064 với scope `event:replay`, PH-10 duyệt theo quy tắc của mình (ADR-181, Q18-03).',
    41: 'Danh sách có khối `facets` (đếm theo nguồn, lớp lỗi, trạng thái, mã lỗi) cho bộ lọc UI-18-01; p95 ≤ 1,5 s cho trang 50 dòng (NFR-18-003). Không trả payload.',
    46: 'Gọi API-13-069 của PH-13 trong `18.dlq.diagnostics.timeout-ms` (3.000 ms); PH-13 vắng hoặc chậm thì trả `206` với phần đã có (fail-soft).',
    47: 'Cần `PERM-18-dlq-payload` và lý do ≥ 10 ký tự; trả nội dung trong phiếu xem 15 phút, trường đã mã hóa vẫn che; ghi kiểm toán PH-13 trước khi trả (ERR-18-008).',
    53: 'Tạo bản sửa, không sửa bản gốc (ADR-181). Bản sửa có trường mức Hạn chế hoặc Nhạy cảm chờ duyệt bốn mắt (API-18-055); bản sửa thường `APPROVED` ngay.',
    64: 'Phát lại qua lối vào của nguồn (ADR-182), khóa lũy đẳng `dlqId:revision`; mục `POISON` trả ERR-18-028, mục đang trong lượt khác ERR-18-031, nguồn không có cổng ERR-18-033.',
    65: 'Lượt `DRAFT` theo bộ lọc hoặc danh sách (≤ `18.dlq.replay.batch-max`); trả `excluded[]` cho mục không phát lại được. Gửi bằng API-18-069.',
    69: 'Số mục ≤ `18.dlq.replay.approval-threshold` (500) thì `APPROVED` và chạy ngay; lớn hơn thì `PENDING_APPROVAL`, tạo việc duyệt trong Việc của tôi.',
    76: 'Nguồn báo kết quả theo `idempotencyKey`; lặp lại cùng khóa trả `duplicate = true`, không đổi trạng thái lần hai. Danh tính gọi phải khớp nguồn của mục (ERR-18-038).',
    91: 'Gửi bất đồng bộ qua outbox, lũy đẳng theo `Idempotency-Key` và bên gọi; mẫu dùng biến mức Hạn chế hoặc Nhạy cảm bị chặn (ERR-18-039, FR-00-062). '
        'Phân hệ gọi không gửi địa chỉ; PH-18 tự phân giải `recipientRef`.',
    92: 'Gửi thư mang liên kết ở chế độ đồng bộ (Q01-52): chờ máy chủ thư nhận trong `18.notify.sync.timeout-ms`; kênh gián đoạn trả ERR-18-044.',
    109: 'Tạo hoặc cập nhật việc lũy đẳng theo `sourceRef` và `sourceVersion` tăng dần; bản cũ hơn bị bỏ qua. `summary` không chứa dữ liệu Hạn chế.',
    117: 'Tính hạn theo lịch của tenant (ngày nghỉ cuối tuần, ngày lễ, ngày làm bù); trả `skippedDates[]` để giải thích.',
    122: 'PH-02, PH-04 đọc trước khi phát hành lên môi trường thật; PH-18 vắng thì bên gọi coi là không đóng băng và ghi cảnh báo (BR-18 về suy giảm).',
    130: 'Chuyển hồ sơ sang PH-09 (`INCIDENT_PH18`); PH-09 giữ đồng hồ 72 giờ. PH-09 không nhận thì thử lại mỗi 5 phút (ERR-18-054).',
    142: 'PA duyệt (người thứ hai, ERR-18-005), tạo Job `dh-tenant-restore` trong `dh-batch`; tenant chuyển `SUSPENDED` trong khi chạy tám bước (RBK-04).',
    150: 'PH-20 gọi khi điều phối sáp nhập (hợp đồng 27/11). Chạy `dh-tenant-export` và nạp cho `module`, giữ `id` gốc và `origin_tenant_id`; báo tiến độ về '
         '`POST /internal/tenant/v1/merge-plans/{id}/participants/{module}:report` của PH-20. Trùng `mergePlanId` và `module` với thân khác: ERR-18-061.',
    164: 'Lần chạy `DRY_RUN` vào hàng đợi ngay; `REAL` cần lần chạy thử thành công trong `18.migration.dry-run-valid-days` (ERR-18-064), ở `PENDING_APPROVAL` chờ API-18-167. '
         '`retryOf` và `errorIds[]` chạy lại bản ghi lỗi.',
    167: 'Duyệt chạy thật (người thứ hai); không chạy được trong cửa sổ đóng băng (ERR-18-051).',
    176: 'Bộ so sánh gửi cặp băm của phản hồi đã chuẩn hóa, không gửi thân phản hồi hay dữ liệu cá nhân (Q18-14).',
    180: 'Trạng thái từng thành phần (tiếp nhận DLQ, outbox, gửi thông báo, worker), độ trễ tiêu thụ, cờ chỉ đọc `18.degraded.read-only`.',
    6: 'Ghi giá trị theo tenant: kiểm kiểu (ERR-18-012), miền (ERR-18-013), trần nền tảng (ERR-18-014), mức `PLATFORM` (ERR-18-015), lý do tối thiểu `18.param.reason-min-length`. '
       'Khóa thường trả `200` và phát EVT-18-01; khóa ★ có `approvalOwner = PH-18` trả `202` kèm đề nghị và phát EVT-18-02; khóa do phân hệ khác giữ duyệt trả ERR-18-019. '
       'Khóa `18.degraded.read-only` không ghi qua API này (ERR-18-003), chỉ đổi qua API-18-187.',
    175: 'Thân `action` quyết định thao tác và quyền: `REQUEST` (đề nghị cắt chuyển một phần hoặc toàn phần theo `target`, `PERM-18-migration`), `APPROVE`, `REJECT` '
         '(bốn mắt, `PERM-18-approve`, người duyệt khác người đề nghị ERR-18-005), `ROLLBACK` (quay lui trong `18.migration.rollback-window-minutes`, ERR-18-068, không cần duyệt). '
         'Kiểm danh sách cắt chuyển (ERR-18-067) và tỷ lệ khớp (ERR-18-066); phát EVT-18-27 để PH-03 đổi tuyến APISIX.',
    181: 'Người nhận việc báo người cùng nhận: việc `OPEN` chuyển `IN_PROGRESS`, ghi người nhận, phát EVT-18-14; việc đã đóng trả ERR-18-048; gọi lại khi đã nhận trả `200` không đổi.',
    182: 'Đánh dấu cách xử lý cho tối đa 1.000 bản ghi lỗi của lần chạy; `WONT_MIGRATE` cần `reason` ≥ 10 ký tự (ERR-18-007) và được đưa vào báo cáo đối chiếu như chênh lệch đã giải trình. '
         'Phản hồi kết quả từng bản ghi.',
    183: 'Dấu `PENDING` hoặc `NOTIFIED` chuyển `WAIVED` kèm lý do; dấu đã `REISSUED` trả ERR-18-006. Mục danh sách cắt chuyển `CREDENTIALS_REISSUED` tính `WAIVED` như đã đạt.',
    184: 'Thay toàn bộ bộ quy tắc chuẩn hóa của nhóm (`If-Match`, lý do); bộ so sánh nhận quy tắc mới, mẫu trong cửa sổ 7 ngày được tính lại và tỷ lệ khớp cập nhật.',
    185: 'Xác nhận mục kiểm tay (`checkKind = MANUAL`) kèm bằng chứng; mục tự động trả ERR-18-006; mục chuyển `PASSED`, ghi người xác nhận vào sổ cắt chuyển.',
    186: 'Sự kiện inbox `FAILED` theo mô-đun để người vận hành biết sự kiện nào chưa xử lý được (FR-18-072 bước 4); chỉ siêu dữ liệu, không nội dung sự kiện.',
    187: 'PA bật hoặc tắt chế độ chỉ đọc kèm lý do; là API ghi duy nhất không bị chặn bởi chế độ chỉ đọc (ERR-18-071 không áp dụng). Ghi khóa `18.degraded.read-only`, phát EVT-18-29, ghi kiểm toán.',
    188: 'Nguồn có cổng `KAFKA_TOPIC` lấy nội dung cần phát lại theo `payloadRef` của EVT-18-09: `revision = 0` là bản gốc, lớn hơn là bản sửa đã duyệt. '
         'Danh tính gọi phải khớp nguồn của mục (ERR-18-038); payload lớn trả `downloadUrl` Garage có hạn thay cho `payload`.',
}
CLS = {47: 'RESTRICTED', 53: 'RESTRICTED', 54: 'RESTRICTED', 45: 'INTERNAL', 61: 'INTERNAL'}
HTTP_NAME = {400: 'BadRequest', 401: 'Unauthorized', 403: 'Forbidden', 404: 'NotFound', 409: 'Conflict', 412: 'PreconditionFailed', 413: 'PayloadTooLarge',
             422: 'Unprocessable', 428: 'PreconditionRequired', 429: 'TooManyRequests', 503: 'ServiceUnavailable'}
BASE_ERR = {401: 'ERR-00-401', 403: 'ERR-00-403', 428: 'ERR-00-428'}
TRACE = '4bf92f3577b34da6a3ce929d0e0e4736'


def ref(kind, name):
    return {'$ref': '#/components/%s/%s' % (kind, name)}


PAGE_EXTRA = {'DlqMessagePage': ('facets', 'DlqFacets'), 'MeNotificationPage': ('unreadCount', None), 'MyTaskPage': ('summary', 'TaskSummary')}
PAGE_BASE = {'MyTaskPage': 'TaskItem'}


def schema_of(name):
    if name.endswith('Page') and name not in SCH:
        base = PAGE_BASE.get(name, name[:-4])
        if base not in SCH:
            raise SystemExit('Thiếu lược đồ nền cho ' + name)
        s = {'type': 'object', 'required': ['items', 'page', 'size', 'totalElements'],
             'properties': {'items': {'type': 'array', 'items': ref('schemas', base)}, 'page': {'type': 'integer', 'minimum': 0},
                            'size': {'type': 'integer', 'minimum': 1, 'maximum': 100}, 'totalElements': {'type': 'integer', 'minimum': 0}}}
        if name in PAGE_EXTRA:
            f, r = PAGE_EXTRA[name]
            s['properties'][f] = ref('schemas', r) if r else {'type': 'integer', 'minimum': 0}
        SCH[name] = s
    if name == 'CsvFile' and name not in SCH:
        SCH[name] = {'type': 'string', 'description': 'Tệp CSV UTF-8 có dòng tiêu đề, chỉ siêu dữ liệu, không payload.'}
    if name not in SCH:
        raise SystemExit('Thiếu lược đồ ' + name)
    return ref('schemas', name)


def qparam(tok, n):
    name, t = tok.split(':', 1)
    req = name.endswith('!')
    name = name.rstrip('!')
    p = {'name': name, 'in': 'query', 'required': req, 'schema': dsl18.ty(t)}
    if p['schema'].get('type') == 'array':
        p['explode'] = True
    if req:
        p['example'] = X.query_example(name, n)
    return p


def perm_of(perm):
    out, scopes = [], []
    for p in [x.strip() for x in perm.split(',')]:
        m = re.fullmatch(r'`?(ops:[a-z-]+)`?', p)
        if m:
            scopes.append(m.group(1))
        elif p == 'đăng nhập':
            out.append('LOGIN')
        else:
            out.append('PERM-18-' + p)
    return out, scopes


def expand_fr(txt):
    return [int(x) for x in re.findall(r'\d{3}', txt)]


def build_paths():
    paths = {}
    for num, m, path, frs, perm, summ in ROWS:
        n = int(num)
        internal = path.startswith(INT_BASE)
        full = path if internal else USER_BASE + path
        act = re.search(r':([a-z-]+)$', path)
        verb = act.group(1) if act else None
        req_s, code, resp_s = OP[n]
        perms, scopes = perm_of(perm)
        fr = expand_fr(frs)
        machine_only = not [p for p in perms if p != 'LOGIN'] and scopes and 'LOGIN' not in perms
        op = {'tags': [tag_of(n)], 'operationId': 'ops%03d' % n, 'summary': summ.strip(), 'x-datahub-id': 'API-18-%03d' % n,
              'x-datahub-fr': ['FR-18-%03d' % f for f in fr]}
        ptxt = ' / '.join('Đăng nhập (mọi vai trò)' if p == 'LOGIN' else p for p in perms)
        if scopes:
            ptxt = (ptxt + '; ' if ptxt else '') + 'scope ' + ', '.join(scopes) + ('; mTLS SPIFFE' if internal else '')
        op['x-datahub-permission'] = {'permission': ptxt}
        op['description'] = KEY_NOTE.get(n) or ('%s. Quyền %s; FR-18-%s.' % (summ.strip().rstrip('.'), ptxt, ', '.join('%03d' % f for f in fr)))
        if internal:
            op['servers'] = [{'url': 'https://dh-platform.dh-platform.svc:8443', 'description': 'API nội bộ trong cụm (mTLS Istio, danh tính SPIFFE); không qua APISIX.'}]
        sec = []
        if [p for p in perms]:
            sec.append({'oauth2User': []})
        for s_ in scopes:
            assert s_ in SC, s_
            sec.append({'oauth2Machine': [s_], **({'mtlsSpiffe': []} if internal else {})})
        op['security'] = sec
        if n in CLS:
            op['x-dh-classification'] = CLS[n]
        ps = []
        for pn in re.findall(r'\{(\w+)\}', path):
            if pn == 'sourceCode':
                sch = dsl18.ty('scode' if 'dlq-sources' in path else 's')
            else:
                sch = dsl18.ty(PATH_P.get(pn, 'u' if pn.endswith('Id') else 's'))
            ps.append({'name': pn, 'in': 'path', 'required': True, 'schema': sch, 'example': X.path_example(pn, path)})
        is_list = m == 'GET' and resp_s and resp_s.endswith('Page')
        if is_list:
            ps += [ref('parameters', 'Page'), ref('parameters', 'Size'), ref('parameters', 'Sort')]
        for tok in dsl18.split_top(FILT.get(n, '')):
            ps.append(qparam(tok, n))
        item_path = path.rstrip('/').endswith('}')
        ifm = not internal and not machine_only and n not in NO_IFM and (
            m in ('PUT', 'PATCH') or (m == 'DELETE' and item_path) or (m == 'POST' and verb in IFM_VERBS))
        if ifm:
            ps.append(ref('parameters', 'IfMatch'))
        if n in (28, 29):
            ps.append(ref('parameters', 'IfNoneMatch'))
        idem = m == 'POST' and n not in SAFE_POST
        if idem:
            ps.append(ref('parameters', 'IdempotencyKeyOptional' if n in IDEM_OPT else 'IdempotencyKey'))
            op['x-datahub-idempotent'] = 'optional' if n in IDEM_OPT else 'required'
        ps += [ref('parameters', 'Traceparent'), ref('parameters', 'AcceptLanguage')]
        op['parameters'] = ps
        for _s in (req_s, resp_s):
            if _s:
                schema_of(_s)
        ex_req, ex_res = X.examples(n, req_s, resp_s, SCH)
        if req_s:
            op['requestBody'] = {'required': True, 'content': {'application/json': {'schema': schema_of(req_s), **({'example': ex_req} if n not in NO_EX else {})}}}
        rs = {}
        if resp_s is None:
            rs[str(code)] = {'description': 'Thành công, không có nội dung.'}
        elif resp_s == 'CsvFile':
            rs['200'] = {'description': 'Tệp CSV của danh sách đang lọc.', 'content': {'text/csv': {'schema': schema_of('CsvFile'), 'example': X.CSV_DLQ}}}
        else:
            desc = {200: 'Thành công.', 201: 'Đã tạo.', 202: 'Đã nhận, xử lý bất đồng bộ.', 207: 'Kết quả từng phần tử (đa trạng thái).'}[code]
            r = {'description': desc}
            cont = {'application/json': {'schema': schema_of(resp_s), **({'example': ex_res} if n not in NO_EX else {})}}
            if n == 170:
                cont['text/csv'] = {'schema': schema_of('CsvFile'), 'example': X.CSV_MIG}
            if n == 171:
                cont['application/pdf'] = {'schema': {'type': 'string', 'format': 'binary'}}
                cont['text/csv'] = {'schema': schema_of('CsvFile'), 'example': X.CSV_RECON}
            r['content'] = cont
            hd = {}
            if code == 201:
                hd['Location'] = {'schema': {'type': 'string'}, 'example': X.location(full, n)}
            if 'version' in SCH[resp_s].get('properties', {}) or n in (28, 29):
                hd['ETag'] = {'schema': {'type': 'string'}, 'example': 'W/"3"' if n not in (28, 29) else 'W/"t68-18-42"'}
            if hd:
                r['headers'] = hd
            rs[str(code)] = r
        if n in EXTRA_OK:
            c2, s2, d2 = EXTRA_OK[n]
            rs[str(c2)] = {'description': d2}
            if s2:
                rs[str(c2)]['content'] = {'application/json': {'schema': schema_of(s2)}}
        # lỗi miền theo FR
        if n in ONLY:
            dom = set(ONLY[n])
        else:
            dom = set()
            for f in fr:
                dom |= FR_ERR.get(f, set())
            dom -= STRUCT
            if m == 'GET':
                dom = {e for e in dom if ERRS[e][0] in (404, 503) and e not in ('ERR-18-071', 'ERR-18-044', 'ERR-18-069')}
            dom -= EXCL.get(n, set())
        dom |= ADD.get(n, set())
        dom = {e for e in dom if e not in STRUCT}
        structural = set()
        if req_s or (m == 'GET' and FILT.get(n)):
            structural.add('ERR-18-003')
        if '{' in path:
            structural.add('ERR-18-001')
        if ifm:
            structural.add('ERR-18-004')
        if n in FOUR_EYES:
            structural.add('ERR-18-005')
        if verb in STATE_VERBS and n not in SAFE_POST:
            structural.add('ERR-18-006')
        rq = SCH.get(req_s or '', {})
        if any(f in rq.get('required', []) and rq['properties'][f].get('minLength') for f in ('reason', 'comment', 'rootCause')):
            structural.add('ERR-18-007')
        if m != 'GET' and n not in SAFE_POST:
            structural.add('ERR-18-008')
        if idem:
            structural.add('ERR-18-009')
        structural.add('ERR-18-010')
        # chế độ chỉ đọc (FR-18-072) chặn mọi API ghi của người dùng, trừ API-18-187 dùng để tắt chính chế độ này
        if m != 'GET' and not internal and not machine_only and n not in SAFE_POST and n != READ_ONLY_TOGGLE:
            structural.add('ERR-18-071')
        allerr = sorted(dom | structural)
        for c in allerr:
            if c not in ERRS or ERRS[c][0] is None:
                raise SystemExit('Mã lỗi không hợp lệ: %s (API-18-%03d)' % (c, n))
            rs.setdefault(str(ERRS[c][0]), ref('responses', HTTP_NAME[ERRS[c][0]]))
        for st in (401, 403):
            rs.setdefault(str(st), ref('responses', HTTP_NAME[st]))
        if ifm:
            rs.setdefault('428', ref('responses', 'PreconditionRequired'))
        rs.setdefault('429', ref('responses', 'TooManyRequests'))
        op['responses'] = dict(sorted(rs.items()))
        op['x-datahub-errors'] = allerr
        op['x-datahub-domain-errors'] = sorted(dom - {'ERR-18-071'})
        paths.setdefault(full, {})[m.lower()] = op
    return paths


def components():
    C = {}
    kc = 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect'
    C['securitySchemes'] = {
        'oauth2User': {'type': 'oauth2', 'description': 'Người dùng đăng nhập Keycloak (realm của tenant), Authorization Code với PKCE qua BFF; quyền `PERM-18-*` ở claim `permissions` (PH-12).',
                       'flows': {'authorizationCode': {'authorizationUrl': kc + '/auth', 'tokenUrl': kc + '/token', 'scopes': {}}}},
        'oauth2Machine': {'type': 'oauth2', 'description': 'Token dịch vụ của DU gọi (client_credentials với mTLS hoặc private_key_jwt); scope máy cấp khi triển khai, không gán cho người.',
                          'flows': {'clientCredentials': {'tokenUrl': kc + '/token', 'scopes': dict(SC)}}},
        'mtlsSpiffe': {'type': 'mutualTLS', 'description': 'Danh tính DU theo SPIFFE ID của Istio; bắt buộc cho mọi đường dẫn `/ops/internal/v1`.'}}
    C['parameters'] = {
        'Page': {'name': 'page', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0, 'default': 0}, 'description': 'Số trang, từ 0.'},
        'Size': {'name': 'size', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100, 'default': 20}, 'description': 'Cỡ trang, 1…100.'},
        'Sort': {'name': 'sort', 'in': 'query', 'schema': {'type': 'string'}, 'description': 'Khóa sắp xếp; tiền tố `-` là giảm dần, ví dụ `-receivedAt`.'},
        'IdempotencyKey': {'name': 'Idempotency-Key', 'in': 'header', 'required': True, 'schema': {'type': 'string', 'minLength': 8, 'maxLength': 64},
                           'example': 'dh-2026-11-27-0001', 'description': 'Khóa chống trùng (BR-18-049); giữ 24 giờ; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-18-009.'},
        'IdempotencyKeyOptional': {'name': 'Idempotency-Key', 'in': 'header', 'required': False, 'schema': {'type': 'string', 'minLength': 8, 'maxLength': 64},
                                   'description': 'Tùy chọn; thao tác đã lũy đẳng theo khóa tự nhiên trong thân (ví dụ `idempotencyKey`, `messageRef`).'},
        'IfMatch': {'name': 'If-Match', 'in': 'header', 'required': True, 'schema': {'type': 'string'}, 'example': 'W/"3"',
                    'description': '`ETag` của đối tượng; thiếu trả `428` ERR-00-428, lệch trả `412` ERR-18-004.'},
        'IfNoneMatch': {'name': 'If-None-Match', 'in': 'header', 'required': False, 'schema': {'type': 'string'}, 'description': '`ETag` của ảnh chụp trước; không đổi thì trả `304`.'},
        'Traceparent': {'name': 'traceparent', 'in': 'header', 'schema': {'type': 'string', 'pattern': '^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'}, 'description': 'W3C Trace Context.'},
        'AcceptLanguage': {'name': 'Accept-Language', 'in': 'header', 'schema': {'type': 'string', 'enum': ['vi', 'en']}, 'description': 'Ngôn ngữ thông báo lỗi.'}}
    resp = {}
    for st, name in HTTP_NAME.items():
        codes = sorted(c for c, v in ERRS.items() if v[0] == st)
        if st in BASE_ERR:
            codes = [BASE_ERR[st]] + codes
        exs = {}
        for c in codes[:3]:
            t = ERRS[c][2] if c in ERRS else {401: 'Phiên đăng nhập đã hết hạn. Đăng nhập lại.', 403: 'Bạn không có quyền thực hiện thao tác này.',
                                               428: 'Thiếu phiên bản đối tượng. Tải lại rồi thử lại.'}[st]
            exs[c.replace('-', '_')] = {'summary': t, 'value': {'type': 'https://datahub.gov.vn/errors/' + c, 'title': t, 'status': st, 'code': c, 'traceId': TRACE}}
        desc = 'Lỗi %d (RFC 9457): %s.' % (st, ', '.join(codes[:6]) + (' …' if len(codes) > 6 else ''))
        r = {'description': desc, 'content': {'application/problem+json': {'schema': schema_of('ProblemDetails'), 'examples': exs}}}
        if st == 429:
            r['headers'] = {'Retry-After': {'schema': {'type': 'integer'}, 'description': 'Số giây nên đợi.'}}
        resp[name] = r
    C['responses'] = resp
    C['schemas'] = SCH
    return C


def doc():
    paths = build_paths()
    return {
        'openapi': '3.1.0',
        'info': {'title': 'Datahub · PH-18 Vận hành và xử lý lỗi', 'version': '1.0.0-draft',
                 'summary': 'Kho tham số và cờ tính năng, DLQ hợp nhất và phát lại, thông báo, Việc của tôi và lịch, sự cố vận hành, sao lưu và khôi phục tenant, di trú hệ cũ và cắt chuyển.',
                 'description': ('Module `ops` của `dh-platform` (package `vn.datahub.platform.ops`): API người dùng `/api/ops/v1` qua APISIX và BFF; API nội bộ `/ops/internal/v1` '
                                 'chỉ trong cụm (mTLS, SPIFFE, scope máy). Đường dẫn trong tệp viết đầy đủ cả tiền tố.\n\n'
                                 'Quy ước (D03-04-PH18 §1): tenant lấy từ token (API nội bộ nhận `tenant` trong đường dẫn hoặc thân và đối chiếu danh tính gọi); '
                                 'mọi `POST` đổi dữ liệu nhận `Idempotency-Key`; `PUT`, `PATCH`, hành động chuyển trạng thái có `If-Match`; hậu tố `:{hành-động}`; '
                                 'phân trang `page`, `size`, `sort`; lỗi RFC 9457 mã `ERR-18-nnn` (401, 403, 428 dùng ERR-00-401, 403, 428). Không có payload DLQ ở danh sách hay sự kiện, '
                                 'không có địa chỉ người nhận chưa che, không có giá trị bí mật (chỉ tham chiếu OpenBao). Mọi tên, mã, số trong ví dụ là giả lập.\n\n'
                                 'Tệp sinh bởi `tools/gen_openapi.py`; không sửa tay.'),
                 'contact': {'name': 'Nhóm phân hệ PH-18'}, 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)', 'identifier': 'LicenseRef-Datahub-Internal'},
                 'x-datahub-document': 'D03-04-PH18', 'x-datahub-phase': 'PH-18'},
        'servers': [{'url': 'https://api.{tenantHost}.datahub.example.vn', 'description': 'API người dùng qua APISIX (giả lập)',
                     'variables': {'tenantHost': {'default': 't68', 'description': 'Ví dụ `t68` (giả lập).'}}},
                    {'url': 'http://localhost:8080', 'description': 'Phát triển cục bộ (`dh-platform`)'}],
        'security': [{'oauth2User': []}],
        'tags': [{'name': t, 'description': d} for t, d, _, _ in TAGS],
        'paths': paths, 'components': components()}


def main():
    d = doc()
    sch = d['components']['schemas']

    def refs(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k == '$ref' and isinstance(v, str) and v.startswith('#/components/schemas/'):
                    yield v.split('/')[-1]
                else:
                    yield from refs(v)
        elif isinstance(o, list):
            for v in o:
                yield from refs(v)
    used = set(refs({k: v for k, v in d.items() if k != 'components'})) | set(refs({k: v for k, v in d['components'].items() if k != 'schemas'}))
    todo = list(used)
    while todo:
        k = todo.pop()
        for r in refs(sch[k]):
            if r not in used:
                used.add(r)
                todo.append(r)
    for k in list(sch):
        if k not in used:
            del sch[k]
    out = os.path.join(HERE, '..', 'openapi-ops.yaml')
    head = '# D03-04-PH18 · OpenAPI PH-18 (module ops của dh-platform). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n'
    open(out, 'w', encoding='utf-8').write(head + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    n = sum(len(v) for v in d['paths'].values())
    print('ghi', out, len(d['paths']), 'đường dẫn,', n, 'operation,', len(sch), 'lược đồ')


if __name__ == '__main__':
    main()
