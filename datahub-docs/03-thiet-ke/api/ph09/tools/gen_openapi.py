#!/usr/bin/env python3
"""Sinh ../openapi-privacy.yaml (OpenAPI 3.1) cho PH-09 từ FRS D02-03-PH09: §9.4 (API-09-001…245), §9.1 (ERR),
Phụ lục A (enum). Control plane `/api/privacy/v1` (đường dẫn tương đối), data plane `/privacy/v1` (đường dẫn đầy đủ,
máy chủ riêng). Lược đồ viết ở schemas09.py. Chạy từ thư mục tools: python3 gen_openapi.py
Không sửa tay tệp YAML; sửa FRS hoặc tệp này rồi sinh lại."""
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import schemas09 as S9  # noqa: E402

FRS = open(os.path.join(HERE, '..', '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH09-frs-quyen-rieng-tu.md'), encoding='utf-8').read()
APPX = FRS[FRS.index('## Phụ lục A.'):FRS.index('## Phụ lục B.')]
SEC94 = FRS[FRS.index('### 9.4. Danh mục API'):FRS.index('## 10. Giao diện')]
SEC91 = FRS[FRS.index('### 9.1. Mã lỗi'):FRS.index('### 9.2.')]

ROWS = re.findall(r'^\| API-09-(\d{3}) \| `(GET|POST|PUT|PATCH|DELETE) ([^`]+)` \| ([0-9, ]+) \| ([^|]+?) \| ([^|]+?) \|$', SEC94, re.M)
ERRS = {c: (int(h.split(',')[0]), t.strip().strip('"')) for c, h, t in re.findall(r'^\| (ERR-09-\d{3}) \| ([0-9, ]+) \| ([^|]+?) \|$', SEC91, re.M)}
ERRX = {}
# mã lỗi gắn thêm theo API (FRS 9.1, 9.2): 079 khoảng thời gian, 080 dữ liệu mẫu giống DLCN thật, 082 AI khi cờ tắt
DOMX = {215: ['ERR-09-079'], 217: ['ERR-09-079'], 101: ['ERR-09-080'], 137: ['ERR-09-082']}
assert len(ROWS) == 245, len(ROWS)
assert len(ERRS) >= 91, len(ERRS)


def enums():
    out = {}
    for m in re.finditer(r'^\| `(\w+)`( \([^)]*\))? \| ([^|]+) \|', APPX, re.M):
        name, vals = m.group(1), m.group(3)
        if name == 'PersonalDataCategory':
            continue
        v = re.findall(r'`([A-Z][A-Z0-9_]+)`', re.sub(r'\([^()]*\)', '', vals))
        if name == 'DpiaStatus':
            v = out['VersionStatus'] + ['SUBMITTED_A05']
        out[name] = v
    # giá trị CHECK ở DDL nhưng chưa có ở Phụ lục A (đề nghị bổ sung; Q09-50, D03-03-PH09 §9)
    out.update({'LogPolicy': ['FULL', 'PARTIAL_MASK', 'NO_VALUE'], 'DisplayPolicy': ['FULL', 'MASK_BY_ROLE', 'MASK_DEFAULT'],
                'TargetKind': ['ELEMENT', 'API', 'TOPIC', 'FLOW'], 'MaskPolicyScope': ['TENANT', 'CONTRACT'], 'ReportFormat': ['PDF', 'XLSX', 'DOCX']})
    return out


ENUMS = enums()
SCH = S9.build_schemas(ENUMS)

TAGS = [
    ('Phân loại', 'Mức phân loại, nhãn chặn, loại DLCN, phần tử dữ liệu, phân loại và quét phát hiện, mức hợp đồng (FR-09-001…008).',
     'data-classes secret-labels personal-data-categories data-elements classifications scans findings detectors contract-levels classification-exports'),
    ('Sổ hoạt động xử lý', 'Hoạt động xử lý, liên kết, cơ sở pháp lý, văn bản căn cứ, xuất sổ (FR-09-009…013).',
     'processing-activities legal-bases legal-documents ropa-templates ropa-exports'),
    ('Mục đích và chấp thuận', 'Mục đích, yêu cầu khai thác, chấp thuận, bundle chính sách, cảnh báo khai thác, kiểm tra kích hoạt (FR-09-014…022).',
     'purposes access-requests purpose-grants policy-bundles usage-anomalies anomaly-rules usage-reports activation-checks'),
    ('Che dữ liệu', 'Kiểu che, chính sách che, mô phỏng, xem đầy đủ, che log, rò rỉ log (FR-09-023…030).',
     'mask-types mask-policies mask-simulations reveal-grants log-masking-config leak-findings leak-scans'),
    ('Giả danh và ẩn danh', 'Miền và khóa giả danh, khôi phục giá trị gốc, cấu hình và job ẩn danh, rủi ro, chuẩn bị dữ liệu, tập đã ẩn danh (FR-09-031…039).',
     'pseudonym-domains pseudonym-keys reidentification-requests anonymization-configs anonymization-jobs risk-assessments data-preparations anonymized-datasets'),
    ('Lưu giữ', 'Lịch lưu giữ, tác vụ xóa, giữ pháp lý, xóa mật mã tenant, báo cáo lưu giữ (FR-09-040…044).',
     'retention-schedules retention-tasks legal-holds tenant-shred-requests retention-reports'),
    ('Quyền chủ thể', 'Yêu cầu của chủ thể dữ liệu từ tiếp nhận đến đóng, báo cáo (FR-09-045…051).', 'subject-requests subject-request-reports'),
    ('Sự đồng ý', 'Mẫu đồng ý, bản ghi đồng ý, bằng chứng (FR-09-052…054).', 'consent-templates consents'),
    ('DPIA và vi phạm', 'Hồ sơ đánh giá tác động, vụ việc vi phạm dữ liệu cá nhân, đồng hồ 72 giờ (FR-09-055…060).', 'dpia-records breaches'),
    ('Kiểm toán và tham số', 'Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo tuân thủ, tham số tenant (FR-09-061…064).',
     'audit-events audit-exports compliance-dashboard compliance-reports settings'),
    ('Data plane', 'API quyết định và áp che cho điểm thực thi, đường nóng, chỉ trong cụm (FR-09-007, 018, 019, 020, 027…029, 032, 047, 054).', ''),
]
SEG_TAG = {s: t for t, _, ss in TAGS for s in ss.split()}

SEG = {'data-classes': 'DataClassPolicy', 'secret-labels': 'BlockLabelRecord', 'personal-data-categories': 'PersonalDataCategory', 'data-elements': 'DataElement',
       'classifications': 'ClassificationChange', 'scans': 'ScanRun', 'findings': 'ScanFinding', 'detectors': 'DetectorRule', 'contract-levels': 'ContractLevel',
       'classification-exports': 'ExportJob', 'processing-activities': 'ProcessingActivity', 'legal-bases': 'LegalBasis', 'legal-documents': 'LegalDocument',
       'ropa-templates': 'RopaTemplate', 'ropa-exports': 'ExportJob', 'purposes': 'Purpose', 'access-requests': 'AccessRequest', 'purpose-grants': 'PurposeGrant',
       'policy-bundles': 'PolicyBundle', 'usage-anomalies': 'UsageAnomaly', 'anomaly-rules': 'AnomalyRules', 'usage-reports': 'UsageReport',
       'activation-checks': 'ActivationCheck', 'mask-types': 'MaskTypeDef', 'mask-policies': 'MaskPolicy', 'mask-simulations': 'MaskSimulation',
       'reveal-grants': 'RevealGrant', 'log-masking-config': 'LogMaskConfig', 'leak-findings': 'LeakFinding', 'leak-scans': 'LeakScan',
       'pseudonym-domains': 'PseudonymDomain', 'pseudonym-keys': 'PseudonymKey', 'reidentification-requests': 'ReidentificationRequest',
       'anonymization-configs': 'AnonymizationConfig', 'anonymization-jobs': 'AnonymizationJob', 'risk-assessments': 'RiskReport',
       'data-preparations': 'DataPreparation', 'anonymized-datasets': 'AnonymizedDataset', 'retention-schedules': 'RetentionSchedule',
       'retention-tasks': 'RetentionTask', 'legal-holds': 'LegalHold', 'tenant-shred-requests': 'TenantShredRequest', 'retention-reports': 'RetentionReport',
       'subject-requests': 'SubjectRequest', 'subject-request-reports': 'SubjectRequestReport', 'consent-templates': 'ConsentTemplate', 'consents': 'ConsentRecord',
       'dpia-records': 'DpiaRecord', 'breaches': 'BreachCase', 'audit-events': 'AuditEvent', 'audit-exports': 'ExportJob', 'compliance-dashboard': 'ComplianceDashboard',
       'compliance-reports': 'ComplianceReport', 'settings': 'SettingList'}

VERB = {'submit': 'SubmitInput', 'approve': 'ApproveInput', 'reject': 'RejectInput', 'retire': 'RetireInput', 'withdraw': 'CommentInput', 'suspend': 'ReasonInput',
        'resume': 'CommentInput', 'revoke': 'ReasonInput', 'rollback': 'ReasonInput', 'cancel': 'ReasonInput', 'release': 'ReasonInput', 'disable': 'ReasonInput',
        'acknowledge': 'CommentInput', 'dismiss': 'ReasonInput', 'close': 'CommentInput', 'lift-restriction': 'ReasonInput'}

# (thân yêu cầu, mã thành công, lược đồ phản hồi); chỉ những thao tác khác quy tắc mặc định
OV = {
    2: ('DataClassPatch', 200, 'DataClassPolicy'), 4: ('BlockLabelInput', 201, 'BlockLabelRecord'),
    5: ('ReleaseRequestInput', 200, 'BlockLabelRecord'), 6: ('ReleaseApproveInput', 200, 'BlockLabelRecord'),
    12: ('ElementRegisterInput', 200, 'BulkResult'), 13: ('ImportSchemaInput', 200, 'ImportResult'), 14: ('ImportDeclarationsInput', 200, 'ImportResult'),
    15: ('ClassificationProposalInput', 200, 'ClassificationChange'), 16: ('ClassificationConfirmInput', 200, 'ClassificationChange'),
    17: ('RejectInput', 200, 'ClassificationChange'), 18: ('ClassificationBulkConfirmInput', 200, 'BulkResult'), 19: (None, 200, 'ClassificationChangePage'),
    20: ('ScanRunInput', 202, 'ScanRun'), 23: (None, 200, 'ScanFindingPage'), 24: ('FindingResolveInput', 200, 'ScanFinding'),
    28: (None, 200, 'ContractLevel'), 29: ('RecomputeInput', 202, 'JobAccepted'), 30: ('ExportInput', 202, 'ExportJob'),
    40: (None, 200, 'ProcessingActivityPage'), 41: (None, 200, 'ActivityLinkPage'), 42: ('ActivityLinkInput', 201, 'ActivityLink'), 43: (None, 204, None),
    44: (None, 200, 'DataElementPage'), 52: ('ExportInput', 202, 'ExportJob'),
    65: ('AccessDecisionInput', 200, 'AccessRequest'), 66: ('InfoRequestInput', 200, 'AccessRequest'),
    69: ('GrantRenewInput', 200, 'PurposeGrant'), 70: ('GrantAmendInput', 200, 'PurposeGrant'),
    76: ('BundlePublishInput', 201, 'PolicyBundle'), 78: (None, 200, 'BundleSyncStatus'),
    83: ('EscalateInput', 201, 'BreachCase'), 84: (None, 200, 'AnomalyRules'), 85: ('AnomalyRulesInput', 200, 'AnomalyRules'),
    86: (None, 200, 'UsageReport'), 87: ('ExportInput', 202, 'ExportJob'), 88: ('ActivationCheckInput', 200, 'ActivationCheck'), 89: (None, 200, 'ContractLevelPage'),
    91: ('MaskPatternsInput', 200, 'MaskTypeDef'), 95: ('MaskPolicyVersionInput', 200, 'MaskPolicy'), 96: ('SubmitInput', 200, 'MaskPolicy'),
    97: ('ApproveInput', 200, 'MaskPolicy'), 98: ('RejectInput', 200, 'MaskPolicy'), 100: (None, 200, 'MaskPolicyDiff'), 101: ('MaskSimulationInput', 200, 'MaskSimulation'),
    102: ('RevealRequestInput', 201, 'RevealGrantIssued'), 104: (None, 200, 'LogMaskConfig'), 105: ('LogMaskConfigInput', 200, 'LogMaskConfig'),
    107: ('FindingResolveInput', 200, 'LeakFinding'), 108: ('LeakScanInput', 202, 'JobAccepted'),
    115: (None, 200, 'PseudonymKeyPage'), 116: ('KeyRotateInput', 201, 'PseudonymKey'), 118: ('KeyDestroyInput', 200, 'PseudonymKey'),
    119: ('ReidRequestInput', 201, 'ReidentificationRequest'), 122: ('ReidApproveInput', 200, 'ReidentificationRequest'), 124: ('ReidExecuteInput', 200, 'ReidExecuteResult'),
    130: ('AnonymizationJobInput', 202, 'AnonymizationJob'), 134: (None, 200, 'RiskReport'), 135: ('ApproveInput', 200, 'AnonymizationJob'),
    136: ('RiskAssessmentInput', 202, 'JobAccepted'), 137: ('DataPreparationInput', 202, 'DataPreparation'),
    142: ('DatasetPublishInput', 200, 'AnonymizedDataset'), 143: ('ReasonInput', 200, 'AnonymizedDataset'), 144: ('DatasetTermsInput', 200, 'AnonymizedDataset'),
    154: ('RetentionRunInput', 202, 'RetentionTask'), 159: ('ShredRequestInput', 201, 'TenantShredRequest'), 163: (None, 200, 'RetentionReport'),
    167: ('SubjectVerifyInput', 200, 'SubjectRequest'), 168: ('SubjectSearchInput', 202, 'JobAccepted'), 169: (None, 200, 'SubjectFindingPage'),
    170: ('SubjectTaskInput', 201, 'SubjectTask'), 171: (None, 200, 'SubjectTaskPage'), 172: ('TaskCompleteInput', 200, 'SubjectTask'),
    173: ('AssignInput', 200, 'SubjectRequest'), 175: ('SubjectRespondInput', 200, 'SubjectRequest'), 177: ('SubjectRejectInput', 200, 'SubjectRequest'),
    179: ('AccessReportInput', 202, 'AccessReport'), 180: (None, 200, 'AccessReport'), 181: (None, 200, 'SubjectRequestReport'),
    184: ('ConsentTemplateVersionInput', 200, 'ConsentTemplate'), 185: ('SubmitInput', 200, 'ConsentTemplate'), 186: ('ApproveInput', 200, 'ConsentTemplate'),
    188: ('ConsentInput', 201, 'ConsentRecord'), 189: ('ConsentWithdrawInput', 200, 'ConsentRecord'), 191: (None, 200, 'ConsentProof'),
    200: ('ExportInput', 202, 'ExportJob'), 201: ('DpiaSubmittedInput', 200, 'DpiaRecord'),
    203: ('BreachInput', 201, 'BreachCase'), 205: ('BreachPatch', 200, 'BreachCase'), 206: ('BreachAssessInput', 200, 'BreachCase'), 207: (None, 200, 'BreachClock'),
    208: ('BreachNotificationInput', 201, 'BreachNotification'), 209: ('NotificationSentInput', 200, 'BreachNotification'),
    210: ('AffectedSubjectsInput', 200, 'BreachCase'), 211: ('BreachActionInput', 201, 'BreachAction'), 212: ('LessonInput', 200, 'BreachCase'),
    213: ('BreachCloseInput', 200, 'BreachCase'), 214: (None, 200, 'DossierFile'), 217: ('ExportInput', 202, 'ExportJob'),
    218: (None, 200, 'ComplianceDashboard'), 219: (None, 200, 'DashboardMetric'), 221: ('ComplianceReportInput', 202, 'ComplianceReport'),
    223: ('ReportScheduleInput', 200, 'ReportSchedule'), 224: (None, 200, 'SettingList'), 225: ('SettingsUpdate', 200, 'SettingList'), 226: (None, 200, 'SettingChangePage'),
    227: ('PurposeDecideRequest', 200, 'PurposeDecideResponse'), 228: ('MaskPlanRequest', 200, 'MaskPlanResponse'), 229: ('MessageApplyRequest', 200, 'MessageApplyResponse'),
    230: ('PseudonymIssueRequest', 200, 'PseudonymIssueResponse'), 231: ('ClassificationCheckRequest', 200, 'ClassificationCheckResponse'),
    232: (None, 200, 'ClassificationIndex'), 233: (None, 200, 'OpaBundle'), 234: ('ConsentCheckRequest', 200, 'ConsentCheckResponse'),
    239: (None, 200, 'BreachNotificationPage'), 240: (None, 200, 'BreachActionPage'), 242: ('ExtendInput', 200, 'SubjectRequest'),
    244: ('ReasonInput', 200, 'SubjectRequest'), 245: ('ConsentSearchInput', 200, 'ConsentRecordPage'),
    235: ('SubjectHashRequest', 200, 'SubjectHashResponse'), 236: ('RevealVerifyRequest', 200, 'RevealVerifyResponse'), 237: ('UsageEventsRequest', 202, 'UsageEventsResponse'),
}
# 5 thao tác trên tài nguyên nhưng phản hồi không phải bản ghi cùng tên: đã liệt kê ở OV

# bộ lọc truy vấn của danh sách
FILT = {
    'data-elements': 'q:s, scope:#ElementScope, dataClass:#DataClass, personalDataType:#PersonalDataType, status:#ClassificationStatus, contractId:s, ownerOrgId:s',
    'scans': 'status:#ScanStatus', 'findings': 'status:#FindingStatus', 'detectors': 'enabled:b', 'contract-levels': 'contractKind:#ContractKind, dataClass:#DataClass, blocked:b',
    'processing-activities': 'q:s, status:#VersionStatus, purposeCode:code', 'legal-bases': 'status:#ElementStatus', 'legal-documents': 'status:#ElementStatus',
    'purposes': 'status:#PurposeStatus', 'access-requests': 'status:#AccessRequestStatus, htttId:s, purposeCode:code',
    'purpose-grants': 'status:#GrantStatus, htttId:s, purposeCode:code, contractId:s', 'policy-bundles': 'from:ts, to:ts',
    'usage-anomalies': 'status:#AnomalyStatus, anomalyType:#AnomalyType, htttId:s', 'usage-reports': 'from!:ts, to!:ts, purposeCode:code, htttId:s, groupBy:e(PURPOSE|HTTT|CONTRACT|DAY)',
    'mask-policies': 'status:#VersionStatus, scope:#MaskPolicyScope', 'reveal-grants': 'requestedBy:s, from:ts, to:ts', 'leak-findings': 'status:#FindingStatus',
    'pseudonym-domains': 'status:#PseudonymDomainStatus', 'reidentification-requests': 'status:#ReidStatus', 'anonymization-configs': 'status:#VersionStatus',
    'anonymization-jobs': 'status:#AnonJobStatus', 'data-preparations': 'status:#AnonJobStatus, target:#DataPrepTarget', 'anonymized-datasets': 'status:#DatasetStatus',
    'retention-schedules': 'status:#VersionStatus', 'retention-tasks': 'status:#RetentionTaskStatus', 'legal-holds': 'status:#LegalHoldStatus',
    'subject-requests': 'status:#DsrStatus, requestType:#DsrType, overdue:b, assignedTo:s', 'subject-request-reports': 'from!:ts, to!:ts',
    'consent-templates': 'status:#VersionStatus, purposeCode:code', 'consents': 'templateCode:code, subjectHash:hash, status:#ConsentStatus',
    'dpia-records': 'status:#DpiaStatus', 'breaches': 'status:#BreachStatus, severity:#BreachSeverity',
    'audit-events': 'actor:s, action:s, targetType:s, targetId:s, from!:ts, to!:ts', 'compliance-reports': 'period:s', 'retention-reports': 'asOf:ts',
}
PATH_P = {'code': '#Code', 'domainCode': '#Code', 'templateCode': '#Code', 'detectorCode': '#Code', 'version': 'i', 'kind': '#ContractKind', 'contractId': 's',
          'metric': 's', 'grantId': 'u'}

# mã lỗi riêng theo FR (ngoài mã cấu trúc 001, 003, 004, 006, 007, 010)
ERRFR = {2: '011', 3: '014 015', 4: '005 012 013', 5: '015 016 017', 6: '035', 7: '018 019', 9: '020 021 024', 10: '005 020 021 023 024', 11: '022 023', 12: '021', 13: '025',
         14: '026', 15: '027 028', 16: '005 028 029 055', 17: '030 031', 18: '032 033', 20: '034', 21: '036', 22: '035', 23: '037', 24: '038', 25: '039', 26: '005 040',
         29: '041 042 043', 30: '044', 31: '045 048', 33: '005 048 049 050', 34: '046 047', 35: '051', 36: '052 054', 37: '053', 38: '055', 39: '053 056', 40: '005 057',
         41: '058 061', 42: '058 059', 43: '005 060', 45: '062 064 065', 46: '063', 47: '063', 48: '066', 50: '063 067 068', 52: '005 069 070', 53: '071 072', 55: '073',
         56: '005 073', 57: '074', 58: '075', 59: '076 077', 60: '076', 64: '078'}
DPERR = {227: '101 102 103 104 106 111 113', 228: '101 103 105 106 111', 229: '101 105 106 107 110 111', 230: '106 107 108 109 110 111', 231: '101 106 111',
         232: '111', 233: '111', 234: '106 111', 235: '106 108 111', 236: '112 111', 237: '106 107 111 113'}
FOUR_EYES = {'approve', 'reject', 'confirm', 'approve-release', 'approve-risk', 'decide', 'destroy'}

KEY = [12, 16, 37, 65, 73, 76, 97, 102, 118, 119, 122, 124, 129, 130, 143, 161, 165, 167, 188, 189, 203, 209, 213, 225] + list(range(227, 238)) + [242, 245]
NOTE = {
    12: 'Đăng ký hàng loạt tối đa 1.000 phần tử mỗi lời gọi; phần tử đã có trả về `skipped`, không lỗi. Phần tử mới ở trạng thái `PROPOSED`, xử lý như `SENSITIVE` đến khi xác nhận (BR-09-001).',
    16: 'Người xác nhận khác người đề xuất (ERR-09-005). Hạ mức hoặc hạ loại DLCN cần căn cứ và lý do (ERR-09-013) và người xác nhận thứ hai (BR-09-002, 003); phát EVT-09-01.',
    37: 'Người duyệt khác người soạn (ERR-09-005). Hoạt động phải đủ mục, văn bản căn cứ còn hiệu lực, không dùng sự đồng ý khi luật bắt buộc; bản cũ chuyển `SUPERSEDED`; phát EVT-09-04.',
    65: 'Chủ quản dữ liệu quyết định; `APPROVE` hoặc `APPROVE_WITH_CONDITIONS` sinh chấp thuận, tối đa `09.grant.max-days` ngày (ERR-09-030); người lập yêu cầu không tự duyệt (BR-09-014); dựng lại bundle trong 10 giây; phát EVT-09-06.',
    73: 'Hiệu lực trong ≤ 15 giây tại điểm thực thi; lý do tối thiểu 20 ký tự (ERR-09-007); phát EVT-09-08.',
    76: 'Chỉ phát hành khi bộ kiểm thử đạt (ERR-09-033) và ký được bằng OpenBao (ERR-09-032, bundle cũ vẫn hiệu lực); `validUntil` ≤ 240 phút, kích thước ≤ 5 MB; phát EVT-09-11.',
    97: 'Người duyệt khác người soạn; chỉ duyệt phiên bản đã mô phỏng đạt (ERR-09-040); phiên bản trước chuyển `SUPERSEDED`; phát EVT-09-12.',
    102: 'Phiếu hết hạn sau `09.mask.reveal-seconds` (60) giây, không gia hạn; tối đa 20 phiếu mỗi người mỗi giờ (ERR-09-043); trường `neverReveal` bị từ chối (ERR-09-042); thân trả thêm `serverTime` và `remainingThisHour`, giao diện đếm ngược theo `expiresAt` của máy chủ; giá trị chỉ có trong thân phản hồi `no-store`, không ghi đĩa; ghi kiểm toán không giá trị (BR-09-026).',
    116: 'Xoay khóa làm bí danh mới khác bí danh cũ cho cùng giá trị (phá nhất quán): `confirmInconsistency` phải là `true`, nếu không trả ERR-09-003 kèm cảnh báo; xoay trong khoảng `09.pseudo.min-rotate-days` thì ERR-09-047.',
    118: 'Cần hai người khác nhau xác nhận và chờ tối thiểu 7 ngày (BR-09-032); khóa còn dùng thì từ chối (ERR-09-046); phát EVT-09-16; khóa bị hủy làm bí danh của miền không còn giải được.',
    119: 'Tối đa 100 giá trị mỗi đề nghị (ERR-09-049); miền HMAC không khôi phục được (ERR-09-048); danh sách token chỉ lưu dạng băm tổng hợp `tokens_digest`.',
    122: 'Cấp một do chủ quản, cấp hai do ATTT; ba người khác nhau (người đề nghị, cấp một, cấp hai); duyệt hết hiệu lực sau 24 giờ (ERR-09-050); đồng thời phải có MFA khi thực hiện.',
    124: 'Yêu cầu MFA mới trong 5 phút và cửa sổ thực hiện 30 phút; kết quả giao qua `resultRef` (Garage, mã hóa SSE-C, tải một lần) hết hạn theo `expiresAt` của máy chủ sau 60 giây, không trả giá trị gốc trong thân; phát EVT-09-17.',
    129: 'Bốn mắt; `k` phải ≥ `09.anon.k-min` (10, ERR-09-051); phiên bản `ACTIVE` bất biến.',
    130: 'Job chạy bất đồng bộ (ARX); hoàn tất khi k thực tế ≥ k cấu hình; còn trường định danh trực tiếp thì từ chối (ERR-09-052); rủi ro `HIGH` không phát hành (ERR-09-053).',
    143: 'Rút lại tập đã phát hành, lý do tối thiểu 20 ký tự; phát EVT-09-18.',
    161: 'Hai người duyệt khác nhau và khác người đề nghị; chờ `09.shred.delay-days` (30, tối thiểu 7) ngày trước khi hủy khóa KEK của tenant (BR-09-041); phát EVT-09-21 khi hoàn tất.',
    165: 'Định danh chủ thể nhận một lần, mã hóa envelope ngay khi nhận, trả về chỉ có `subjectHash`; cùng `Idempotency-Key` trả lại phản hồi cũ; chủ thể đã có yêu cầu cùng loại đang xử lý thì ERR-09-064; phát EVT-09-22.',
    167: 'Chưa xác minh thì mọi thao tác xử lý bị từ chối (ERR-09-063, BR-09-042).',
    188: 'Bản ghi cần kênh, thời điểm, phiên bản mẫu (ERR-09-071); mẫu phải đang `ACTIVE`; một đồng ý `GIVEN` duy nhất cho mỗi (chủ thể, mẫu); phát EVT-09-27.',
    189: 'Đã rút hoặc hết hạn thì ERR-09-072; hiệu lực xử lý trong ≤ 60 giây (bộ đệm đồng ý); phát EVT-09-28.',
    203: '`detectedAt` bắt đầu đồng hồ 72 giờ (`deadlineAt = detectedAt + 72 giờ`, không sửa được); phát EVT-09-30; TO được ghi nhận nhưng không đóng hồ sơ (BR-09-057).',
    209: 'Đã gửi thì không sửa; có `evidenceRef`; thông báo Cục A05 làm `notifiedA05At` của vụ việc; phát EVT-09-32.',
    213: 'Chỉ đóng khi hết nghĩa vụ thông báo hoặc có căn cứ miễn trừ (ERR-09-076, 077) và đã ghi bài học.',
    242: 'Gia hạn một lần, kèm lý do tối thiểu 20 ký tự; `newDueAt` không quá hạn pháp luật cho phép; thông báo chủ thể về hạn mới (FR-09-049).',
    245: 'Tra theo định danh rõ trong thân (bên có quyền nhập): PH-09 tính băm HMAC rồi tra, không ghi định danh vào log, kết quả chỉ mang `subjectHash` (FR-09-053).',
    225: 'Giá trị ngoài sàn, trần PA đặt ra thì ERR-09-078; đổi `09.plan.cache-seconds`, `09.bundle.valid-minutes` có hiệu lực sau lần dựng bundle kế tiếp; ghi lịch sử.',
    227: 'Đường nóng: p95 ≤ 50 ms khi gọi trực tiếp; thiếu mục đích thì ERR-09-103; không có chấp thuận thì ERR-09-102; chủ thể bị hạn chế xử lý thì ERR-09-104; không khả dụng thì điểm thực thi đóng an toàn. Trả thêm `ropaActivityId` (hoạt động xử lý `ACTIVE` liên kết hợp đồng, vắng nếu chưa có) cho PH-14; trả `ropaActivityId` vẫn p95 ≤ 200 ms (NFR-09-027, chủ đầu tư chốt 27/11/2026).',
    228: 'Kế hoạch che theo trường cho (hợp đồng, mục đích, kênh); bộ đệm `09.plan.cache-seconds`; không lập được thì `failMode` `CLOSED` hoặc `PUBLIC_ONLY` (ERR-09-105).',
    229: 'Áp kế hoạch che cho bản tin JSON ≤ 1 MiB; lô lớn hơn thì ERR-09-107; không ghi được nhật ký che thì từ chối (ERR-09-110); không lưu bản tin.',
    230: 'Giả danh hóa theo lô ≤ 500 giá trị; `HMAC_SHA256` tính cục bộ, `TOKEN_TRANSIT` dùng OpenBao (ERR-09-108 khi không khả dụng); không lưu giá trị vào, không lưu ánh xạ.',
    231: 'Kiểm tra nhãn STATE_SECRET và mức phân loại hiệu lực của bản tin hoặc lược đồ; nhãn chặn trả `blocked` và ERR-09-101 ở điểm thực thi. Với `egressScope` là `OUT_OF_PROVINCE`, thêm kiểm thuộc tính `noEgress` của từng trường: trả `egressBlocked` và `egressBlockedFields`, bên gọi (PH-14) không gửi ra ngoài tỉnh; p95 ≤ 200 ms (BR-09-063, NFR-09-027, chủ đầu tư chốt 27/11/2026). `egressScope` ngoài `NONE`, `OUT_OF_PROVINCE` trả ERR-09-106 (400).',
    232: 'Bản chụp chỉ mục phân loại; hỗ trợ `If-None-Match` và `304`.',
    233: 'Bundle OPA đã ký hiện hành; `ETag` là `bundleNo`; hỗ trợ `If-None-Match` và `304`; dùng cho OPA (PH-12) và điểm thực thi.',
    234: 'Kết quả đệm `09.consent.cache-seconds` (60) giây; kèm cờ `restrictionActive` của chủ thể.',
    235: 'HMAC-SHA256 khóa riêng tenant; không ghi giá trị vào (ERR-09-108 khi OpenBao không khả dụng); chỉ cho bên có `privacy:decide`.',
    236: 'Xác thực phiếu xem đầy đủ do điểm thực thi gọi; phiếu hết hạn hoặc sai thì ERR-09-112.',
    237: 'Báo lượt khai thác theo lô ≤ 1.000 sự kiện mỗi lời gọi, cộng dồn vào bộ đếm theo phút; trả `202`; vượt hạn mức gọi thì ERR-09-113.',
}
CLS = {'subject-requests': 'RESTRICTED', 'consents': 'RESTRICTED', 'reveal-grants': 'SENSITIVE', 'reidentification-requests': 'RESTRICTED', 'breaches': 'RESTRICTED',
       'audit-events': 'RESTRICTED', 'pseudonym-keys': 'RESTRICTED', 'pseudonym-domains': 'RESTRICTED', 'tenant-shred-requests': 'RESTRICTED', 'access-requests': 'INTERNAL'}
HTTP_NAME = {400: 'BadRequest', 401: 'Unauthorized', 403: 'Forbidden', 404: 'NotFound', 409: 'Conflict', 413: 'PayloadTooLarge', 422: 'Unprocessable', 428: 'PreconditionRequired',
             429: 'TooManyRequests', 502: 'BadGateway', 503: 'ServiceUnavailable'}
SC = {'privacy:decide', 'privacy:apply', 'privacy:pseudonymize', 'privacy:register', 'privacy:consent'}
TRACE = '4bf92f3577b34da6a3ce929d0e0e4736'
H = 'q3Hk7mXw2RtY9bLz0Pv5nCj8sUeAd1GfOiMhT4yVxKo'
U1, U2, U3 = '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b', '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c', '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d'
CTXV = {'id': U1, 'version': 3, 'createdAt': '2026-11-20T09:00:00+07:00', 'createdBy': 'nguyen.van.an', 'updatedAt': '2026-11-26T09:15:02+07:00', 'updatedBy': 'tran.thi.binh'}

# ví dụ (thân yêu cầu, thân phản hồi); khóa là số API; bí mật là <bi-mat-mau>
EX = {
    102: ({'elementId': U2, 'recordRef': 'bgh-2026-001203', 'reason': 'Đối chiếu hồ sơ khiếu nại số 3318 của công dân'},
          {'grantId': U3, 'token': '<bi-mat-mau>', 'status': 'ISSUED', 'issuedAt': '2026-11-26T09:15:02+07:00', 'expiresAt': '2026-11-26T09:16:02+07:00', 'serverTime': '2026-11-26T09:15:02+07:00', 'remainingThisHour': 17, 'value': '<gia-tri-ro-mau>'}),
    242: ({'newDueAt': '2026-12-24T17:00:00+07:00', 'reason': 'Yêu cầu phức tạp, cần đối chiếu dữ liệu ở ba hệ thống nguồn'},
          {**CTXV, 'requestType': 'ACCESS', 'status': 'IN_PROGRESS', 'channel': 'COUNTER', 'identifierType': 'NATIONAL_ID', 'receivedAt': '2026-11-26T09:15:02+07:00',
           'dueAt': '2026-12-24T17:00:00+07:00', 'overdue': False, 'restrictionActive': False, 'subjectHash': H}),
    245: ({'identifierType': 'PHONE', 'identifier': '<so-dien-thoai-mau>', 'templateCode': 'DY-THONG-BAO-SMS'},
          {'items': [{**CTXV, 'templateCode': 'DY-THONG-BAO-SMS', 'templateVersion': 2, 'subjectHash': H, 'status': 'GIVEN', 'channel': 'APP', 'givenAt': '2026-11-26T09:15:02+07:00',
                      'recordedBy': 'dich-vu-cong'}], 'page': 0, 'size': 20, 'totalElements': 1}),
    118: ({'reason': 'Miền hết mục đích sử dụng, xóa theo quyết định số 112/QĐ-SO', 'confirmation': 'DESTROY'},
          {**CTXV, 'domainId': U2, 'keyVersion': 2, 'status': 'DECRYPT_ONLY', 'openbaoRef': 'dh-t68-pseudo-DS-NOIBO', 'destroyRequestedBy': 'le.van.cuong'}),
    119: ({'domainCode': 'DS-TOKEN', 'tokens': ['tok_01HZX3Q8', 'tok_01HZX3Q9'], 'purposeCode': 'THANH-TRA-HS', 'basis': 'Quyết định thanh tra số 54/QĐ-TTr',
           'reason': 'Xác định chủ thể để xử lý khiếu nại đã được thụ lý'},
          {**CTXV, 'domainId': U2, 'tokenCount': 2, 'purposeCode': 'THANH-TRA-HS', 'basis': 'Quyết định thanh tra số 54/QĐ-TTr', 'reason': 'Xác định chủ thể để xử lý khiếu nại đã được thụ lý',
           'status': 'PENDING_L1', 'requestedBy': 'pham.thi.dung', 'mfaVerified': True}),
    165: ({'requestType': 'ACCESS', 'channel': 'COUNTER', 'identifierType': 'NATIONAL_ID', 'identifier': '<so-dinh-danh-mau>', 'content': 'Đề nghị cho biết dữ liệu cá nhân đang được xử lý'},
          {**CTXV, 'requestType': 'ACCESS', 'status': 'RECEIVED', 'channel': 'COUNTER', 'identifierType': 'NATIONAL_ID', 'receivedAt': '2026-11-26T09:15:02+07:00',
           'dueAt': '2026-12-10T17:00:00+07:00', 'overdue': False, 'restrictionActive': False, 'subjectHash': H}),
    188: ({'templateCode': 'DY-THONG-BAO-SMS', 'templateVersion': 2, 'subjectIdentifierType': 'PHONE', 'subjectIdentifier': '<so-dien-thoai-mau>', 'channel': 'APP',
           'evidence': {'sessionRef': 'ss-77a1', 'ipHash': H}},
          {**CTXV, 'templateCode': 'DY-THONG-BAO-SMS', 'templateVersion': 2, 'subjectHash': H, 'status': 'GIVEN', 'channel': 'APP', 'givenAt': '2026-11-26T09:15:02+07:00', 'recordedBy': 'dich-vu-cong'}),
    203: ({'detectedAt': '2026-11-26T08:40:00+07:00', 'source': 'INCIDENT_PH18', 'description': 'Tệp xuất danh sách hồ sơ bị gửi nhầm tới địa chỉ ngoài tổ chức', 'dataTypes': ['FULL_NAME', 'PHONE'],
           'estimatedSubjects': 120, 'incidentRef': 'INC-2026-0481'},
          {**CTXV, 'detectedAt': '2026-11-26T08:40:00+07:00', 'deadlineAt': '2026-11-29T08:40:00+07:00', 'source': 'INCIDENT_PH18',
           'description': 'Tệp xuất danh sách hồ sơ bị gửi nhầm tới địa chỉ ngoài tổ chức', 'dataTypes': ['FULL_NAME', 'PHONE'], 'estimatedSubjects': 120, 'incidentRef': 'INC-2026-0481',
           'status': 'REPORTED', 'reportedBy': 'tran.thi.binh'}),
    227: ({'htttId': 'httt-so-yte', 'purposeCode': 'TRA-CUU-BHYT', 'contractKind': 'API', 'contractId': 'api-tra-cuu-bhyt-v1', 'fields': ['hoTen', 'soThe'], 'channel': 'API'},
          {'allow': True, 'reason': 'GRANTED', 'grantId': U3, 'ropaActivityId': U2, 'allowedFields': ['hoTen', 'soThe'], 'conditions': [{'conditionType': 'DAILY_QUOTA', 'params': {'max': 2000}}], 'bundleNo': 412, 'ttlSeconds': 60}),
    228: ({'contractKind': 'API', 'contractId': 'api-tra-cuu-bhyt-v1', 'purposeCode': 'TRA-CUU-BHYT', 'channel': 'API', 'roles': ['ROLE-SERVICE_OWNER'], 'fields': ['hoTen', 'soCCCD']},
          {'planId': 'plan-9c41', 'bundleNo': 412, 'failMode': 'CLOSED', 'ttlSeconds': 300,
           'rules': [{'field': 'hoTen', 'dataClass': 'RESTRICTED', 'maskType': 'PARTIAL', 'patternKind': 'KEEP_FIRST_TOKEN'},
                     {'field': 'soCCCD', 'dataClass': 'SENSITIVE', 'maskType': 'TOKENIZE', 'params': {'domainCode': 'DS-TOKEN'}}]}),
    229: ({'contractKind': 'TOPIC', 'contractId': 'chu-de-ho-so-moi', 'purposeCode': 'DONG-BO-HS', 'channel': 'FLOW', 'message': {'hoTen': 'Nguyễn Văn A', 'soCCCD': '<so-dinh-danh-mau>', 'maHoSo': 'HS-0042'}},
          {'message': {'hoTen': 'Nguyễn ***', 'soCCCD': 'tok_01HZX3Q8', 'maHoSo': 'HS-0042'}, 'appliedFields': ['hoTen', 'soCCCD'], 'droppedFields': [], 'pseudonymized': 1, 'bundleNo': 412}),
    230: ({'domainCode': 'DS-TOKEN', 'identifierKind': 'NATIONAL_ID', 'values': ['<so-dinh-danh-mau>']},
          {'domainCode': 'DS-TOKEN', 'keyVersion': 2, 'method': 'TOKEN_TRANSIT', 'items': [{'index': 0, 'pseudonym': 'tok_01HZX3Q8'}]}),
    234: ({'templateCode': 'DY-THONG-BAO-SMS', 'subjectHash': H}, {'status': 'GIVEN', 'templateVersion': 2, 'givenAt': '2026-11-26T09:15:02+07:00', 'restrictionActive': False, 'cacheSeconds': 60}),
    235: ({'identifierType': 'NATIONAL_ID', 'identifiers': ['<so-dinh-danh-mau>']}, {'keyRef': 'dh-t68-privacy-hmac:v3', 'items': [{'index': 0, 'subjectHash': H}]}),
    237: ({'point': 'apisix-ext-0', 'events': [{'bucket': '2026-11-26T09:15:00+07:00', 'htttId': 'httt-so-yte', 'purposeCode': 'TRA-CUU-BHYT', 'contractKind': 'API', 'contractId': 'api-tra-cuu-bhyt-v1',
                                                   'allowed': 118, 'denied': 2, 'offPurpose': 0}]}, {'accepted': 1, 'rejected': 0}),
}


def ref(kind, name):
    return {'$ref': '#/components/%s/%s' % (kind, name)}


def schema_of(name):
    if name.endswith('Page') and name not in SCH:
        base = name[:-4]
        if base not in SCH:
            raise SystemExit('Thiếu lược đồ nền cho ' + name)
        SCH[name] = {'type': 'object', 'required': ['items', 'page', 'size', 'totalElements'],
                     'properties': {'items': {'type': 'array', 'items': ref('schemas', base)}, 'page': {'type': 'integer', 'minimum': 0}, 'size': {'type': 'integer', 'minimum': 1, 'maximum': 100},
                                    'totalElements': {'type': 'integer', 'minimum': 0}}}
    if name not in SCH:
        raise SystemExit('Thiếu lược đồ ' + name)
    return ref('schemas', name)


def qparam(tok):
    name, t = tok.split(':', 1)
    req = name.endswith('!')
    name = name.rstrip('!')
    p = {'name': name, 'in': 'query', 'required': req, 'schema': S9.ty(t)}
    return p


def plan(n, m, path):
    """(thân yêu cầu, mã thành công, lược đồ phản hồi, verb)."""
    parts = path.strip('/').split('/')
    last = parts[-1]
    act = re.search(r':([a-z0-9-]+)$', last)
    verb = act.group(1) if act else None
    if n in OV:
        r, c, s = OV[n]
        return r, c, s, verb
    seg = parts[0].split(':')[0]
    s = SEG[seg]
    is_item = last.endswith('}') and len(parts) == 2
    if m == 'GET':
        return None, 200, (s if is_item else s + 'Page'), verb
    if m == 'POST' and len(parts) == 1 and not act:
        return s + 'Input', 201, s, verb
    if m == 'PUT':
        return s + 'Input', 200, s, verb
    if m == 'PATCH':
        return s + 'Patch', 200, s, verb
    if m == 'DELETE':
        return None, 204, None, verb
    if m == 'POST' and act and verb in VERB:
        return VERB[verb], 200, s, verb
    raise SystemExit('Thiếu quy tắc cho API-09-%03d %s %s' % (n, m, path))


def build_paths():
    paths = {}
    for num, m, path, frs, perm, summ in ROWS:
        n = int(num)
        dp = path.startswith('/privacy/v1')
        parts = path.strip('/').split('/')
        seg = (parts[2] if dp else parts[0]).split(':')[0]
        req_s, code, resp_s, verb = plan(n, m, path)
        perms = [p.strip() for p in perm.split(' / ')]
        pm = ['PERM-09-' + p for p in perms if not p.startswith('scope ')]
        sc = [p[6:].strip() for p in perms if p.startswith('scope ')]
        fr = [int(x) for x in re.findall(r'\d{3}', frs)]
        op = {'tags': ['Data plane' if dp else SEG_TAG[seg]], 'operationId': 'api09%03d' % n, 'summary': summ.strip(), 'x-datahub-id': 'API-09-%03d' % n,
              'x-datahub-fr': ['FR-09-%03d' % f for f in fr]}
        px = [x for x in (' / '.join(pm), ('scope ' + ', '.join(sc)) if sc else '') if x]
        op['x-datahub-permission'] = {'permission': '; '.join(px)}
        if n in NOTE:
            op['description'] = NOTE[n]
        if dp:
            op['security'] = [{'oauth2Machine': sc, 'mtlsSpiffe': []}]
            op['servers'] = [{'url': 'https://privacy-decide.dh-data.svc:8443', 'description': 'Data plane `ph09_decide` (3 bản sao, mTLS, danh tính SPIFFE); không qua APISIX người dùng.'}]
        else:
            sec = []
            if pm:
                sec.append({'oauth2User': []})
            for s in sc:
                assert s in SC, s
                sec.append({'oauth2Machine': [s]})
            op['security'] = sec
        if seg in CLS:
            op['x-dh-classification'] = CLS[seg]
        # tham số
        ps = []
        for pn in re.findall(r'\{(\w+)\}', path):
            sch = S9.ty(PATH_P[pn]) if pn in PATH_P else ({'type': 'string', 'format': 'uuid'} if pn.endswith('Id') else {'type': 'string'})
            ps.append({'name': pn, 'in': 'path', 'required': True, 'schema': sch})
        is_list = m == 'GET' and resp_s and resp_s.endswith('Page')
        if is_list:
            ps += [ref('parameters', 'Page'), ref('parameters', 'Size'), ref('parameters', 'Sort')]
            for tok in S9.split_top(FILT.get(seg, '') if len(parts) == 1 else ''):
                ps.append(qparam(tok))
        elif m == 'GET' and seg in FILT and resp_s and not resp_s.endswith('Page') and n in (86, 163, 181, 215):
            for tok in S9.split_top(FILT[seg]):
                ps.append(qparam(tok))
        if m == 'GET' and n in (86, 181, 215):
            pass
        ifm = m in ('PUT', 'PATCH', 'DELETE') or (m == 'POST' and verb and re.search(r'\}(/versions/\{version\})?:[a-z-]+$', path) and n not in (88,))
        if ifm and not dp:
            ps.append(ref('parameters', 'IfMatch'))
        if m == 'POST' and not dp and n != 245:
            ps.append(ref('parameters', 'IdempotencyKey'))
            op['x-datahub-idempotent'] = 'required'
        if m == 'GET' and n in (232, 233):
            ps.append(ref('parameters', 'IfNoneMatch'))
        ps += [ref('parameters', 'Traceparent'), ref('parameters', 'AcceptLanguage')]
        op['parameters'] = ps
        if req_s:
            body = {'schema': schema_of(req_s)}
            if n in EX:
                body['example'] = EX[n][0]
            op['requestBody'] = {'required': True, 'content': {'application/json': body}}
        # phản hồi
        rs = {}
        if resp_s is None:
            rs[str(code)] = {'description': 'Thành công, không có nội dung.'}
        elif n == 233:
            rs['200'] = {'description': 'Bundle OPA đã ký.', 'headers': {'ETag': {'schema': {'type': 'string'}}},
                         'content': {'application/vnd.openpolicyagent.bundle+gzip': {'schema': {'type': 'string', 'format': 'binary'}}}}
            rs['304'] = {'description': 'Không đổi (`If-None-Match` khớp).'}
        else:
            r = {'description': {200: 'Thành công.', 201: 'Đã tạo.', 202: 'Đã nhận, xử lý bất đồng bộ.'}[code]}
            cont = {'schema': schema_of(resp_s)}
            if n in EX:
                cont['example'] = EX[n][1]
            r['content'] = {'application/json': cont}
            hd = {}
            if code == 201 and not dp:
                hd['Location'] = {'schema': {'type': 'string'}}
            if resp_s in SCH and 'version' in SCH[resp_s].get('properties', {}) and not dp:
                hd['ETag'] = {'schema': {'type': 'string'}}
            if n in (102, 124, 227, 235):
                hd['Cache-Control'] = {'schema': {'type': 'string', 'const': 'no-store'}}
            if n == 232:
                hd['ETag'] = {'schema': {'type': 'string'}}
            if hd:
                r['headers'] = hd
            rs[str(code)] = r
            if n == 232:
                rs['304'] = {'description': 'Không đổi (`If-None-Match` khớp).'}
        # lỗi
        errs = []
        if dp:
            errs += ['ERR-09-' + c for c in DPERR[n].split()]
        else:
            for f in fr:
                errs += ['ERR-09-' + c for c in ERRFR.get(f, '').split()]
        if m == 'GET' and not dp:
            errs = [c for c in errs if c == 'ERR-09-036']
        errs += DOMX.get(n, [])
        domain = sorted(set(errs))
        structural = set()
        if not dp:
            if req_s:
                structural.add('ERR-09-003')
            if re.search(r'\}', path) and m != 'POST' or (verb and '{' in path):
                structural.add('ERR-09-001')
            if ifm:
                structural.add('ERR-09-004')
            if verb:
                structural.add('ERR-09-006')
            if verb in FOUR_EYES or verb in ('reject',):
                structural.add('ERR-09-005')
            if req_s in ('ReasonInput', 'RejectInput', 'RetireInput') or (req_s or '').endswith('ReasonInput'):
                structural.add('ERR-09-007')
            if m != 'GET':
                structural.add('ERR-09-010')
        allerr = sorted(set(domain) | structural)
        for c in allerr:
            if c not in ERRS and c not in ERRX:
                raise SystemExit('Mã lỗi không có ở FRS: %s (API-09-%03d)' % (c, n))
            st = (ERRS.get(c) or ERRX[c])[0]
            rs.setdefault(str(st), ref('responses', HTTP_NAME[st]))
        for st in ((401, 403) if not dp else (401, 403)):
            rs.setdefault(str(st), ref('responses', HTTP_NAME[st]))
        if ifm and not dp:
            rs.setdefault('428', ref('responses', 'PreconditionRequired'))
        if m == 'POST' and not dp and n != 245:
            rs.setdefault('409', ref('responses', 'Conflict'))
        rs.setdefault('429', ref('responses', 'TooManyRequests'))
        op['responses'] = dict(sorted(rs.items()))
        op['x-datahub-errors'] = allerr
        op['x-datahub-domain-errors'] = domain
        paths.setdefault(path, {})[m.lower()] = op
    return paths


def components():
    C = {}
    C['securitySchemes'] = {
        'oauth2User': {'type': 'oauth2', 'description': 'Người dùng đăng nhập Keycloak (realm của tenant), Authorization Code với PKCE qua BFF; quyền chức năng `PERM-09-*` ở claim `permissions`, phạm vi tổ chức ở claim `org`.',
                       'flows': {'authorizationCode': {'authorizationUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth',
                                                       'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token', 'scopes': {}}}},
        'oauth2Machine': {'type': 'oauth2', 'description': 'Token dịch vụ (client_credentials với mTLS hoặc private_key_jwt); kèm scope `purpose:{mã}` mang mục đích của lời gọi.',
                          'flows': {'clientCredentials': {'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token',
                                                          'scopes': {'privacy:decide': 'Quyết định, kế hoạch che, chỉ mục phân loại, bundle, băm chủ thể, báo lượt',
                                                                     'privacy:apply': 'Áp che bản tin', 'privacy:pseudonymize': 'Giả danh hóa lô giá trị',
                                                                     'privacy:register': 'Đăng ký phần tử, mức hợp đồng, kiểm tra kích hoạt, tiếp nhận yêu cầu chủ thể',
                                                                     'privacy:consent': 'Ghi và tra sự đồng ý'}}}},
        'mtlsSpiffe': {'type': 'mutualTLS', 'description': 'Danh tính DU theo SPIFFE ID của Istio; data plane kiểm DU nào có scope nào (SEC-15).'}}
    C['parameters'] = {
        'Page': {'name': 'page', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0, 'default': 0}, 'description': 'Số trang, từ 0.'},
        'Size': {'name': 'size', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100, 'default': 20}, 'description': 'Cỡ trang, 1…100.'},
        'Sort': {'name': 'sort', 'in': 'query', 'schema': {'type': 'string'}, 'description': 'Khóa sắp xếp; tiền tố `-` là giảm dần.'},
        'IdempotencyKey': {'name': 'Idempotency-Key', 'in': 'header', 'required': True, 'schema': {'type': 'string', 'format': 'uuid'}, 'description': 'Khóa chống trùng (BR-09-061); giữ 24 giờ; cùng khóa và thân trả lại phản hồi cũ.'},
        'IfMatch': {'name': 'If-Match', 'in': 'header', 'required': True, 'schema': {'type': 'string'}, 'description': '`ETag` của đối tượng; thiếu trả `428`, lệch trả `409` ERR-09-004.'},
        'IfNoneMatch': {'name': 'If-None-Match', 'in': 'header', 'schema': {'type': 'string'}, 'description': 'Trả `304` nếu nội dung không đổi.'},
        'Traceparent': {'name': 'traceparent', 'in': 'header', 'schema': {'type': 'string', 'pattern': '^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'}, 'description': 'W3C Trace Context.'},
        'AcceptLanguage': {'name': 'Accept-Language', 'in': 'header', 'schema': {'type': 'string', 'enum': ['vi', 'en']}, 'description': 'Ngôn ngữ thông báo lỗi.'}}
    resp = {}
    for st, name in HTTP_NAME.items():
        exs = {}
        for c, (h, t) in ERRS.items():
            if h == st and len(exs) < 3:
                exs[c.replace('-', '_')] = {'summary': t, 'value': {'type': 'https://datahub.gov.vn/errors/' + c, 'title': t, 'status': st, 'code': c, 'traceId': TRACE}}
        codes = sorted(c for c, (h, _) in ERRS.items() if h == st)
        desc = 'Lỗi %d (RFC 9457)%s.' % (st, ': ' + ', '.join(codes[:6]) + (' …' if len(codes) > 6 else '') if codes else ' theo mã nền ERR-00-%03d' % st)
        r = {'description': desc, 'content': {'application/problem+json': {'schema': schema_of('ProblemDetails'), **({'examples': exs} if exs else {})}}}
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
        'info': {'title': 'Datahub · PH-09 Quyền riêng tư', 'version': '1.0.0-draft',
                 'summary': 'Phân loại dữ liệu, sổ hoạt động xử lý, mục đích và chấp thuận, che dữ liệu, giả danh và ẩn danh, lưu giữ, quyền chủ thể, đồng ý, DPIA, vi phạm, kiểm toán.',
                 'description': ('Module `privacy` của `dh-data` (package `vn.datahub.data.privacy`): control plane `/api/privacy/v1` qua APISIX và BFF; data plane `/privacy/v1` chỉ trong cụm (mTLS, SPIFFE).\n\n'
                                 'Quy ước (D03-04-PH09 §1): tenant lấy từ token, không từ tham số; mọi `POST` nhận `Idempotency-Key`; `PUT`, `PATCH`, hành động có `If-Match`; hậu tố `:{hành-động}`; '
                                 'phân trang `page`, `size`, `sort`; lỗi RFC 9457 mã `ERR-09-nnn`. Không có giá trị DLCN rõ ở phản hồi trừ phiếu xem đầy đủ (`RevealGrantIssued`); '
                                 'định danh chủ thể chỉ vào, không ra. Mọi tên, mã, số trong ví dụ là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.'),
                 'contact': {'name': 'Nhóm phân hệ PH-09'}, 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)', 'identifier': 'LicenseRef-Datahub-Internal'},
                 'x-datahub-document': 'D03-04-PH09', 'x-datahub-phase': 'PH-09'},
        'servers': [{'url': 'https://api.{tenantHost}.datahub.example.vn/api/privacy/v1', 'description': 'Control plane qua APISIX (giả lập)',
                     'variables': {'tenantHost': {'default': 't68', 'description': 'Ví dụ `t68` (giả lập).'}}},
                    {'url': 'http://dh-data.dh-data.svc:8080/api/privacy/v1', 'description': 'Control plane trong cụm'},
                    {'url': 'http://localhost:8083/api/privacy/v1', 'description': 'Phát triển cục bộ'}],
        'security': [{'oauth2User': []}],
        'tags': [{'name': t, 'description': d} for t, d, _ in TAGS],
        'paths': paths, 'components': components()}


def main():
    d = doc()
    out = os.path.join(HERE, '..', 'openapi-privacy.yaml')
    head = '# D03-04-PH09 · OpenAPI PH-09 (module privacy của dh-data). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n'
    open(out, 'w', encoding='utf-8').write(head + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    n = sum(len(v) for v in d['paths'].values())
    print('ghi', out, len(d['paths']), 'đường dẫn,', n, 'operation,', len(d['components']['schemas']), 'lược đồ')


if __name__ == '__main__':
    main()
