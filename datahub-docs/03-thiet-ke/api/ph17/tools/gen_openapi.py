#!/usr/bin/env python3
"""Sinh ../openapi-assist.yaml (OpenAPI 3.1) cho PH-17 từ FRS D02-03-PH17: §9.4 (API-17-001…194), §9.1 (ERR), Phụ lục A (enum),
các khối FR §6 (mã lỗi riêng theo FR). Control plane `/api/assist/v1` (đường dẫn tương đối), data plane `/assist/v1`
(đường dẫn đầy đủ, máy chủ riêng). Lược đồ viết ở schemas17.py. Chạy từ thư mục tools: python3 gen_openapi.py
Không sửa tay tệp YAML; sửa FRS hoặc các tệp này rồi sinh lại."""
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsl17  # noqa: E402
import schemas17 as S17  # noqa: E402

FRS = open(os.path.join(HERE, '..', '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH17-frs-tro-ly-ai.md'), encoding='utf-8').read()
APPX = FRS[FRS.index('## Phụ lục A.'):FRS.index('## Phụ lục B.')]
SEC94 = FRS[FRS.index('### 9.4. Danh mục API'):FRS.index('## 10. Giao diện')]
SEC91 = FRS[FRS.index('### 9.1. Mã lỗi'):FRS.index('### 9.2.')]
SEC6 = FRS[FRS.index('## 6. Đặc tả chi tiết'):FRS.index('## 7. Quy tắc')]

ROWS = re.findall(r'^\| API-17-(\d{3}) \| `(GET|POST|PUT|PATCH|DELETE) ([^`]+)` \| ([^|]+) \| ([^|]+) \| (.+) \|$', SEC94, re.M)
ERRS = {c: (int(h.split(',')[0]), [int(x) for x in h.split(',')], t.strip().strip('"')) for c, h, t in re.findall(r'^\| (ERR-17-\d{3}) \| ([0-9, ]+) \| (.+) \|$', SEC91, re.M)}
assert len(ROWS) == 194, len(ROWS)
assert len(ERRS) == 105, len(ERRS)

# mã lỗi riêng theo FR, lấy từ khối đặc tả §6
ERRFR = {}
_b = re.split(r'(?m)^#### (FR-17-\d{3}) · ', SEC6)
for _i in range(1, len(_b), 2):
    ERRFR[int(_b[_i][-3:])] = sorted(set(re.findall(r'ERR-17-\d{3}', _b[_i + 1])))


def expand_fr(txt):
    out = []
    for part in txt.split(','):
        part = part.strip()
        m = re.fullmatch(r'(\d{3}) đến (\d{3})', part)
        if m:
            out += list(range(int(m.group(1)), int(m.group(2)) + 1))
        elif re.fullmatch(r'\d{3}', part):
            out.append(int(part))
    return out


def enums():
    out = {}
    for m in re.finditer(r'^\| `(\w+)`( \([^)]*\))? \| ([^|]+) \|', APPX, re.M):
        out[m.group(1)] = re.findall(r'`([A-Z][A-Z0-9_]+)`', re.sub(r'\([^()]*\)', '', m.group(3)))
    out['ClassLevel'] = ['PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE']
    return out


ENUMS = enums()
SCH = S17.build(ENUMS)

TAGS = [
    ('Chính sách', 'Trạng thái, chính sách theo tenant, đề nghị đổi bốn mắt, năng lực, danh sách trắng nhà cung cấp, hạn mức, điều khoản, tắt khẩn (FR-17-001…006).',
     'status policy usage notices kill-switch platform'),
    ('Cổng mô hình', 'Nhà cung cấp, cam kết, mô hình, phiên bản, mô hình của tenant, tuyến egress, giới hạn cổng, cầu dao, vết lời gọi, sức khỏe (FR-17-007…014).',
     'model-providers models model-versions tenant-models routes gateway invocations model-health'),
    ('Kho tri thức', 'Nguồn, lập chỉ mục, kiểm mức phân loại, tài liệu, xóa lan truyền, tài liệu tải lên, tình trạng chỉ mục (FR-17-015…021).', 'knowledge'),
    ('Hội thoại và tìm kiếm', 'Hội thoại, tin nhắn (đầy đủ và phát trực tuyến), tìm dịch vụ, câu hỏi gợi ý, ngữ cảnh màn hình (FR-17-022…029).',
     'conversations search suggested-questions screen-contexts'),
    ('Gợi ý ánh xạ', 'Gợi ý ánh xạ trường và mã, kiểm biểu thức, xem trước, áp dụng, sửa, từ chối (FR-17-030…035).', 'mapping-suggestions code-mapping-suggestions suggestions'),
    ('Giải thích sự cố', 'Giải thích mã lỗi, vết, bản tin DLQ, danh sách kiểm khắc phục, tóm tắt sự cố, xem trước che log (FR-17-036…041).',
     'explanations remediation-checklists incident-summaries redaction'),
    ('Công cụ và an toàn', 'Công cụ chỉ đọc, nhật ký gọi công cụ, giới hạn, quy tắc lọc, danh sách trắng liên kết (FR-17-042…047).', 'tools guardrails'),
    ('Quản trị AI', 'Chỉ dẫn hệ thống, bộ đánh giá, ca đỏ, cổng phát hành, phản hồi, chất lượng, sổ hệ thống AI, tập ẩn danh (FR-17-049…054, 062).',
     'prompt-templates prompt-versions eval-sets eval-cases eval-runs redteam-cases redteam-runs release-gates feedback quality ai-system-records eval-datasets'),
    ('Nhật ký và báo cáo', 'Nhật ký hội thoại đã che, phiếu truy cập, hạn lưu, gói bằng chứng, báo cáo sử dụng, tham số (FR-17-055…059).', 'logs compliance-exports reports settings'),
    ('Data plane', 'Suy luận nội bộ cho PH-04, gợi ý bước quy trình cho PH-11, cấu hình hiệu lực, sẵn sàng; chỉ trong cụm (FR-17-060, 061).', ''),
]
SEG_TAG = {s: t for t, _, ss in TAGS for s in ss.split()}

# khóa tài nguyên (đoạn đầu, hoặc hai đoạn đầu với nhóm lồng) -> lược đồ bản ghi
SEG = {
    'policy': 'TenantPolicy', 'policy/changes': 'PolicyChange', 'policy/capabilities': 'CapabilityPolicySet', 'policy/provider-grants': 'ProviderGrant', 'policy/quotas': 'QuotaSettings',
    'notices': 'AiNotice', 'kill-switch': 'KillSwitchState', 'platform/kill-switch': 'KillSwitchRecord',
    'model-providers': 'ModelProvider', 'models': 'Model', 'model-versions': 'ModelVersion', 'tenant-models': 'TenantModel', 'routes': 'ModelRoute', 'routes/sync-runs': 'RouteSyncRun',
    'gateway/limits': 'GatewayLimits', 'gateway/breakers': 'ModelBreaker', 'invocations': 'InvocationRecord', 'model-health': 'ModelHealth',
    'knowledge/sources': 'KnowledgeSource', 'knowledge/classification-skips': 'ClassificationSkip', 'knowledge/index-jobs': 'IndexJob', 'knowledge/documents': 'KnowledgeDocument',
    'knowledge/deletions': 'KnowledgeDeletion', 'knowledge/uploads': 'UploadDocument',
    'conversations': 'Conversation', 'suggested-questions': 'SuggestedQuestion', 'suggestions': 'Suggestion', 'explanations': 'Explanation',
    'tools': 'ToolDefinition', 'tools/calls': 'ToolCall', 'guardrails': 'GuardrailRule',
    'prompt-templates': 'PromptTemplate', 'prompt-versions': 'PromptVersion', 'eval-sets': 'EvalSet', 'eval-cases': 'EvalCase', 'eval-runs': 'EvalRun', 'redteam-cases': 'RedteamCase',
    'redteam-runs': 'EvalRun', 'feedback': 'Feedback', 'quality/metrics': 'QualityMetric', 'quality/alerts': 'QualityAlert', 'ai-system-records': 'AiSystemRecord',
    'logs/conversations': 'LogConversation', 'logs/access-grants': 'LogAccessGrant', 'compliance-exports': 'ComplianceExport', 'eval-datasets': 'EvalDatasetLink',
    'settings': 'SettingItem',
}
NEST = {'policy', 'knowledge', 'platform', 'gateway', 'routes', 'tools', 'quality', 'logs', 'reports'}

VERB = {'approve': 'ApproveInput', 'reject': 'ReasonInput', 'retire': 'ReasonInput', 'suspend': 'ReasonInput', 'disable': 'ReasonInput', 'activate': 'KillSwitchInput',
        'release': 'ReasonInput', 'approve-release': 'ApproveInput', 'resume': None, 'pause': None, 'reindex': None, 'cancel': None, 'reset': None, 'probe': None,
        'submit': None, 'enable': None, 'accept': None, 'test-connection': None, 'sync': 'RouteSyncInput', 'triage': 'FeedbackTriageInput', 'resolve': 'FeedbackResolveInput',
        'promote-to-redteam': None, 'review': 'AiSystemRecordReviewInput', 'apply': None, 'record-edit': 'SuggestionEditInput', 'full-reindex': 'FullReindexInput', 'check-class': 'CheckClassInput',
        'record-decision': 'DecisionInput'}

# (thân yêu cầu, mã thành công, lược đồ phản hồi); chỉ thao tác khác quy tắc mặc định
OV = {
    1: (None, 200, 'AssistStatus'), 3: ('PolicyChangeInput', 201, 'PolicyChange'), 4: (None, 200, 'PolicyChangePage'), 6: ('ApproveInput', 200, 'PolicyChange'),
    7: ('ReasonInput', 200, 'PolicyChange'), 8: ('ReasonInput', 200, 'TenantPolicy'), 9: ('CapabilityPolicySet', 200, 'CapabilityPolicySet'), 10: (None, 200, 'ProviderGrantPage'),
    11: ('ProviderGrantInput', 201, 'ProviderGrant'), 12: (None, 204, None), 13: (None, 200, 'QuotaSettings'), 14: ('QuotaSettings', 200, 'QuotaSettings'), 15: (None, 200, 'UsageMe'),
    16: (None, 200, 'AiNotice'), 17: (None, 200, 'AiNotice'), 19: ('AiNoticeInput', 201, 'AiNotice'), 20: ('KillSwitchInput', 200, 'KillSwitchRecord'), 21: (None, 200, 'KillSwitchState'),
    22: ('KillSwitchInput', 200, 'KillSwitchRecord'), 23: ('ReasonInput', 200, 'KillSwitchRecord'), 24: ('ApproveInput', 200, 'KillSwitchRecord'), 25: (None, 200, 'KillSwitchRecord'),
    30: (None, 200, 'ProbeResult'), 32: ('ProviderCommitmentInput', 201, 'ProviderCommitment'), 35: (None, 200, 'ModelDetail'), 37: ('ModelVersionInput', 201, 'ModelVersion'),
    38: (None, 200, 'ModelVersionDetail'), 40: (None, 202, 'EvalRun'), 41: ('ApproveInput', 200, 'ModelVersion'), 42: ('ReasonInput', 200, 'ModelVersion'), 43: ('ReasonInput', 200, 'ModelVersion'),
    44: (None, 200, 'TenantModelPage'), 45: ('TenantModelDefaultsInput', 200, 'TenantModelPage'), 46: (None, 200, 'TenantModel'), 47: ('ReasonInput', 200, 'TenantModel'),
    49: ('RouteSyncInput', 202, 'RouteSyncRun'), 52: (None, 200, 'GatewayLimits'), 53: ('GatewayLimitsInput', 200, 'GatewayLimits'), 54: (None, 200, 'ModelBreakerPage'),
    55: (None, 200, 'ModelBreaker'), 56: (None, 200, 'InvocationRecordPage'), 58: (None, 200, 'InvocationStats'), 59: (None, 200, 'ModelHealthPage'), 60: (None, 202, 'HealthProbe'),
    61: (None, 200, 'HealthProbePage'), 66: (None, 200, 'KnowledgeSource'), 67: (None, 200, 'KnowledgeSource'), 68: ('ReasonInput', 200, 'KnowledgeSource'), 69: (None, 202, 'IndexJob'),
    70: ('CheckClassInput', 200, 'ClassificationSkipPage'), 71: (None, 200, 'ClassificationSkipPage'), 74: ('FullReindexInput', 202, 'IndexJob'), 75: (None, 200, 'IndexJob'),
    77: (None, 200, 'KnowledgeDocumentDetail'), 78: (None, 202, 'IndexJob'), 79: (None, 204, None), 81: ('UploadInput', 201, 'UploadDocument'), 84: (None, 200, 'UploadDocument'),
    85: ('ApproveInput', 200, 'UploadDocument'), 86: ('ReasonInput', 200, 'UploadDocument'), 87: ('ReasonInput', 200, 'UploadDocument'), 88: (None, 200, 'KnowledgeStatus'),
    89: (None, 200, 'SourceHealth'), 90: ('ConversationInput', 201, 'Conversation'), 93: (None, 204, None), 94: (None, 204, None), 95: ('MessageInput', 200, 'MessageAnswer'),
    96: ('MessageInput', 200, 'SseStream'), 97: (None, 200, 'Message'), 98: (None, 200, 'MessagePage'), 99: ('SearchInput', 200, 'SearchResult'), 100: (None, 200, 'SuggestedQuestionPage'),
    101: ('SuggestedQuestionInput', 201, 'SuggestedQuestion'), 102: ('SuggestedQuestionInput', 200, 'SuggestedQuestion'), 103: ('ScreenContextInput', 200, 'ScreenContextResult'),
    104: ('MappingSuggestionInput', 201, 'MappingSuggestionResult'), 105: ('ExpressionCheckInput', 200, 'ExpressionCheckResult'), 106: ('CodeMappingInput', 201, 'MappingSuggestionResult'),
    109: (None, 200, 'SuggestionPreview'), 110: (None, 200, 'ApplyResult'), 111: ('SuggestionEditInput', 200, 'ApplyResult'), 112: ('ReasonInput', 200, 'Suggestion'),
    113: ('ErrorCodeInput', 201, 'Explanation'), 114: ('TraceInput', 201, 'Explanation'), 115: ('DlqMessageInput', 201, 'Explanation'), 117: ('RemediationInput', 201, 'Explanation'),
    118: ('IncidentSummaryInput', 201, 'Explanation'), 119: ('RedactionInput', 200, 'RedactionPreview'), 121: (None, 200, 'ToolDefinition'), 122: ('ToolEnablementInput', 200, 'ToolDefinition'),
    124: ('ToolLimitsInput', 200, 'ToolLimits'), 126: ('GuardrailRuleInput', 201, 'GuardrailRule'), 127: ('GuardrailRulePatch', 200, 'GuardrailRule'), 128: ('GuardrailTestInput', 200, 'GuardrailTestResult'),
    129: (None, 200, 'LinkAllowlist'), 130: ('LinkAllowlistInput', 200, 'LinkAllowlist'), 134: ('PromptVersionInput', 201, 'PromptVersion'), 135: (None, 200, 'PromptVersion'),
    136: ('ApproveInput', 200, 'PromptVersion'), 137: ('ReasonInput', 200, 'PromptVersion'), 138: ('ReasonInput', 200, 'PromptVersion'), 141: (None, 200, 'EvalSet'), 142: ('EvalCaseInput', 201, 'EvalCase'),
    143: ('EvalCasePatch', 200, 'EvalCase'), 144: (None, 204, None), 145: ('EvalRunInput', 202, 'EvalRun'), 148: (None, 200, 'EvalResultPage'), 152: ('RedteamRunInput', 202, 'EvalRun'),
    153: (None, 200, 'EvalRun'), 154: (None, 200, 'ReleaseGate'), 155: ('FeedbackInput', 201, 'Feedback'), 158: ('FeedbackTriageInput', 200, 'Feedback'), 159: ('FeedbackResolveInput', 200, 'Feedback'),
    160: (None, 200, 'RedteamCase'), 161: (None, 200, 'QualityMetricPage'), 162: (None, 200, 'QualityAlertPage'), 163: ('QualityThresholdsInput', 200, 'QualityThresholds'),
    167: ('AiSystemRecordReviewInput', 200, 'AiSystemRecord'), 168: (None, 200, 'LogConversationPage'), 169: ('LogAccessGrantInput', 201, 'LogAccessGrant'), 171: (None, 200, 'LogConversationDetail'),
    172: (None, 200, 'LogRetention'), 173: ('ComplianceExportInput', 202, 'ComplianceExport'), 176: (None, 200, 'BinaryFile'), 177: (None, 200, 'UsageReport'), 178: (None, 202, 'ComplianceExport'),
    179: (None, 200, 'UsageReport'), 180: (None, 200, 'SettingList'), 181: (None, 200, 'SettingSchema'), 182: ('SettingValueInput', 200, 'SettingItem'), 183: (None, 200, 'SettingItem'),
    184: (None, 200, 'EvalDatasetLinkPage'), 185: ('EvalDatasetLinkInput', 201, 'EvalDatasetLink'), 186: (None, 204, None),
    187: ('ClassifyInput', 200, 'ClassifyResult'), 188: ('ExtractInput', 200, 'ExtractResult'), 189: (None, 200, 'InferenceTaskList'), 190: ('ProcessSuggestionInput', 201, 'ProcessSuggestionResult'),
    191: ('DecisionInput', 200, 'ProcessSuggestionResult'), 192: (None, 200, 'EffectiveConfig'), 193: (None, 200, 'ReadyStatus'),
    194: ('FeedbackUpdateInput', 200, 'Feedback'),
}
# thao tác chỉ đọc dùng POST: không cần Idempotency-Key
SAFE_POST = {70, 99, 103, 105, 119, 128, 187, 188}
# phản hồi lược đồ bổ sung (không sinh từ READ/PLAIN)
EXTRA = {
    'ProbeResult': 'ok!:b, latencyMs:i, errorCode:s, checkedAt!:ts',
    'SseStream': None,
    'BinaryFile': None,
}
for _n, _s in EXTRA.items():
    if _s:
        SCH[_n] = dsl17.obj(_s)
SCH['SseStream'] = {'type': 'string', 'description': 'Luồng `text/event-stream`: các sự kiện `message.delta`, `message.citation`, `message.done`, `message.error`; xem mô tả thao tác.'}
SCH['BinaryFile'] = {'type': 'string', 'format': 'binary'}
for _n, _s in [('PolicyChange', 0), ('ProviderGrant', 0), ('TenantModel', 0), ('ModelBreaker', 0), ('ModelHealth', 0), ('ClassificationSkip', 0), ('Message', 0), ('SuggestedQuestion', 0),
               ('EvalResult', 0), ('QualityMetric', 0), ('QualityAlert', 0), ('LogConversation', 0), ('EvalDatasetLink', 0), ('InvocationRecord', 0), ('HealthProbe', 0)]:
    pass

# bộ lọc truy vấn của danh sách: khóa tài nguyên -> mô tả DSL
FILT = {
    'policy/changes': 'state:#PolicyChangeState, changeType:#PolicyChangeType', 'model-providers': 'providerKind:#ProviderKind, status:#ProviderStatus',
    'models': 'modelKind:#ModelKind, modelScope:#ModelScope', 'tenant-models': 'modelKind:#ModelKind, enabled:b', 'routes': 'status:#RouteStatus',
    'invocations': 'from!:ts, to!:ts, capability:#Capability, result:#InvocationResult, modelVersionId:u', 'model-health': 'state:#HealthState',
    'knowledge/sources': 'sourceType:#SourceType, state:e(ACTIVE|PAUSED|RETIRED)', 'knowledge/index-jobs': 'status:#IndexJobStatus, jobKind:#IndexJobKind, sourceId:u',
    'knowledge/documents': 'sourceId:u, indexStatus:#DocumentIndexStatus, q:s', 'knowledge/uploads': 'uploadStatus:#UploadStatus', 'knowledge/deletions': 'sourceId:u, from:ts, to:ts',
    'knowledge/classification-skips': 'sourceId:u, classLevel:#ClassLevel', 'conversations': 'state:#ConversationState, q:s',
    'suggestions': 'status:#SuggestionStatus, suggestionKind:#SuggestionKind', 'tools': 'enabled:b', 'tools/calls': 'toolCode:code, outcome:e(OK|DENIED|TIMEOUT|ERROR), from:ts, to:ts',
    'guardrails': 'guardrailKind:#GuardrailKind, action:#GuardrailAction', 'prompt-templates': 'capability:#Capability', 'eval-sets': 'capability:#Capability',
    'eval-runs': 'status:#EvalRunStatus, runKind:e(EVAL|REDTEAM)', 'redteam-cases': 'category:#RedteamCategory, status:e(ACTIVE|RETIRED)',
    'feedback': 'status:#FeedbackStatus, feedbackKind:#FeedbackKind, assignedTo:s', 'quality/metrics': 'from!:ts, to!:ts, capability:#Capability, metricCode:s',
    'quality/alerts': 'status:e(OPEN|ACKNOWLEDGED)', 'ai-system-records': 'status:e(ACTIVE|REVIEW_DUE|RETIRED)',
    'logs/conversations': 'from!:ts, to!:ts, userId:s', 'logs/access-grants': 'state:#LogAccessGrantState', 'compliance-exports': 'state:#ExportState',
    'eval-datasets': 'evalSetId:u', 'redteam-runs': 'status:#EvalRunStatus',
}
STAT_FILT = {58: 'from!:ts, to!:ts, groupBy:e(MODEL|CAPABILITY|RESULT)', 177: 'from!:ts, to!:ts, groupBy:e(DAY|CAPABILITY|MODEL)', 178: 'from!:ts, to!:ts, format:e(XLSX|CSV)',
             179: 'from!:ts, to!:ts', 172: ''}
PATH_P = {'key': '#SettingKey', 'toolCode': '#Code', 'subjectType': 'e(MODEL_VERSION|PROMPT_VERSION)', 'subjectId': 'u'}
KEY = [3, 6, 8, 20, 41, 46, 68, 79, 85, 90, 95, 96, 99, 104, 110, 113, 122, 126, 136, 145, 152, 154, 155, 169, 171, 173, 182, 187, 190, 191]
KEY_NOTE = {
    3: 'Cần bốn mắt: người đề nghị khác người duyệt (ERR-17-005); mỗi loại chỉ một đề nghị đang chờ (ERR-17-013). `ENABLE` cần số quyết định và lý do tối thiểu 20 ký tự, phát EVT-17-04 khi được quyết định.',
    8: 'Tắt ngay, không cần bốn mắt; phát EVT-17-02. Chỉ mục giữ 90 ngày rồi xóa nếu không bật lại (Q17-21).',
    20: 'Tắt khẩn trong tối đa 60 giây (SEC-49), phát EVT-17-03; gỡ cần đề nghị bốn mắt.',
    41: 'Duyệt bốn mắt; cổng phát hành kiểm tại thời điểm duyệt: đánh giá chuẩn đạt ngưỡng, ca đỏ chặn 100%, bộ ca đỏ có ít nhất 50 ca đang hoạt động (ERR-17-072 đến 075); phát EVT-17-07.',
    46: 'Mô hình ngoài chỉ bật khi tenant cho phép, nhà cung cấp trong danh sách trắng, có cam kết còn hiệu lực và phiên bản đã `APPROVED`.',
    79: 'Xóa đoạn liên quan vật lý trong cùng giao dịch và ghi nhật ký xóa lan truyền; phát EVT-17-16.',
    85: 'Người duyệt khác người tải lên; chỉ tài liệu mức `PUBLIC` hoặc `INTERNAL` được lập chỉ mục (BR-17-026, 030).',
    95: 'Trả câu trả lời đầy đủ trong một phản hồi; nội dung do AI tạo luôn có nhãn `aiGenerated` (FR-17-048). Không có hành động ghi tự động.',
    96: 'Phản hồi `text/event-stream` với các sự kiện `message.delta` (đoạn văn bản), `message.citation` (trích dẫn), `message.done` (kết thúc kèm `messageId`), `message.error` (lỗi RFC 9457). Hủy bằng API-17-097.',
    99: 'Truy hồi lai (vector và từ khóa không dấu, RRF), kết quả có trích dẫn, không sinh văn bản; chỉ trả đoạn người gọi có quyền đọc (BR-17-027).',
    110: 'Áp dụng vào bản nháp bằng quyền của chính người dùng (token exchange); trợ lý không có quyền ghi riêng (BR-17-056, 057).',
    136: 'Duyệt bốn mắt kích hoạt chỉ dẫn; một phiên bản `ACTIVE` mỗi mẫu; phát EVT-17-20.',
    169: 'Chỉ SO, AUDITOR; lý do tối thiểu 20 ký tự; phiếu hiệu lực tối đa 60 phút, khoảng xem tối đa 92 ngày; phát EVT-17-25.',
    171: 'Chỉ xem được khi có phiếu còn hiệu lực; trả nội dung đã che.',
    176: 'Tải gói bằng chứng đã ký (zip); URL hết hạn theo `expiresAt`.',
    182: 'Giá trị ngoài sàn, trần thì ERR-17-018 hoặc ERR-17-082; hạn lưu nhật ký dưới 90 ngày thì ERR-17-083; khóa nhạy cảm cần đề nghị bốn mắt (`SENSITIVE_PARAM`).',
    187: 'Data plane: danh tính DU qua mTLS, scope `assist:infer`; thiếu mục đích hoặc mức dữ liệu thì ERR-17-102; dữ liệu mức cao không gửi tới mô hình ngoài (ERR-17-107).',
    190: 'Gợi ý bước quy trình luôn cần người quyết định (ERR-17-114).',
    194: 'Chỉ người đã gửi phản hồi được sửa, trong 10 phút kể từ lúc gửi và khi phản hồi còn `NEW`; quá hạn hoặc đã được phân loại thì trả ERR-17-006. Bắt buộc `If-Match`. Đổi loại hoặc ghi chú trên cùng bản ghi, không tạo phản hồi mới nên không bị ERR-17-077; ghi chú vẫn được che DLCN.',
}
CLS = {'conversations': 'RESTRICTED', 'logs/conversations': 'RESTRICTED', 'feedback': 'INTERNAL', 'knowledge/documents': 'INTERNAL'}
HTTP_NAME = {400: 'BadRequest', 401: 'Unauthorized', 403: 'Forbidden', 404: 'NotFound', 409: 'Conflict', 410: 'Gone', 422: 'Unprocessable', 428: 'PreconditionRequired',
             429: 'TooManyRequests', 502: 'BadGateway', 503: 'ServiceUnavailable', 504: 'GatewayTimeout'}
SC = {'assist:infer': 'Suy luận nội bộ cho DU gọi (PH-04, PH-11)', 'assist:report': 'Nguồn số liệu sử dụng cho PH-16'}
TRACE = '4bf92f3577b34da6a3ce929d0e0e4736'
U1, U2, U3 = '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b', '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c', '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d'
CTXV = {'id': U1, 'version': 3, 'createdAt': '2026-11-20T09:00:00+07:00', 'createdBy': 'nguyen.van.an', 'updatedAt': '2026-11-26T09:15:02+07:00', 'updatedBy': 'tran.thi.binh'}
CIT = {'rank': 1, 'chunkId': U2, 'sourceId': U3, 'objectRef': 'api/tra-cuu-thue/v1', 'title': 'API tra cứu thuế', 'linkRoute': '/dich-vu/api/tra-cuu-thue?tab=mo-ta', 'score': 0.8123}

EX = {
    3: ({'changeType': 'ENABLE', 'decisionNumber': '112/QĐ-UBND ngày 20/11/2026', 'reason': 'Triển khai trợ lý tìm dịch vụ cho cán bộ các sở theo kế hoạch đợt 3', 'capabilities': [{'capability': 'SEARCH', 'roleGroup': 'ALL_READERS', 'enabled': True}]},
        {**CTXV, 'changeType': 'ENABLE', 'state': 'PENDING', 'decisionNumber': '112/QĐ-UBND ngày 20/11/2026', 'reason': 'Triển khai trợ lý tìm dịch vụ cho cán bộ các sở theo kế hoạch đợt 3',
         'requestedBy': 'nguyen.van.an', 'requestedAt': '2026-11-26T09:15:02+07:00'}),
    95: ({'content': 'Dịch vụ nào tra cứu mã số thuế của tổ chức', 'capability': 'SEARCH', 'clientMessageId': '0190a1b2-0000-7000-8000-000000000001'},
         {'message': {**CTXV, 'conversationId': U3, 'seq': 2, 'role': 'ASSISTANT', 'content': 'API tra cứu thuế (xem mô tả). Nội dung do AI tạo, cần kiểm tra lại.', 'outcome': 'ANSWERED',
                      'capability': 'SEARCH', 'aiGenerated': True, 'citations': [CIT]}, 'aiGenerated': True}),
    99: ({'query': 'tra cứu mã số thuế', 'limit': 5},
         {'results': [{'objectRef': 'api/tra-cuu-thue/v1', 'title': 'API tra cứu thuế', 'snippet': 'API tra cứu thuế của tổ chức, trả mã số thuế và tình trạng hoạt động.',
                       'linkRoute': '/dich-vu/api/tra-cuu-thue?tab=mo-ta', 'score': 0.8123, 'sourceType': 'API_SPEC'}], 'aiGenerated': False}),
    104: ({'sourceSchemaRef': 'schema/ho-so-nguon/v2', 'targetSchemaRef': 'schema/ho-so-dich/v1', 'sourceFields': ['ho_ten', 'ngay_sinh'], 'targetFields': ['fullName', 'dateOfBirth']},
          {'suggestion': {**CTXV, 'suggestionKind': 'FIELD_MAPPING', 'status': 'PROPOSED', 'content': {'items': 2}, 'aiGenerated': True},
           'items': [{'sourceField': 'ho_ten', 'targetField': 'fullName', 'expression': '.ho_ten', 'confidence': 0.93, 'reason': 'Tên trường và kiểu trùng nghĩa'}], 'aiGenerated': True}),
    169: ({'reason': 'Điều tra khiếu nại về câu trả lời của trợ lý', 'scopeKind': 'CONVERSATION', 'conversationId': U3},
          {**CTXV, 'grantee': 'le.thi.chi', 'granteeRole': 'SO', 'reason': 'Điều tra khiếu nại về câu trả lời của trợ lý', 'scopeKind': 'CONVERSATION', 'conversationId': U3,
           'grantedAt': '2026-11-26T09:15:02+07:00', 'expiresAt': '2026-11-26T10:15:02+07:00', 'state': 'ACTIVE'}),
    187: ({'taskCode': 'PHAN-LOAI-VAN-BAN', 'text': 'Công văn đề nghị cấp phép xây dựng công trình nhà ở riêng lẻ', 'labels': ['CAP-PHEP', 'KHIEU-NAI'], 'purposeCode': 'XU-LY-HO-SO', 'dataClass': 'INTERNAL'},
          {'label': 'CAP-PHEP', 'confidence': 0.91, 'modelVersionId': U2, 'requestRef': 'req-0001', 'aiGenerated': True}),
    190: ({'stepType': 'APPROVAL', 'processRef': 'quy-trinh/cap-phep-xay-dung/v3', 'context': {'soHoSo': 'HS-0042'}, 'purposeCode': 'XU-LY-HO-SO'},
          {'suggestionId': U2, 'summary': 'Hồ sơ đủ thành phần, đề nghị chuyển bước thẩm định.', 'options': [{'code': 'CHUYEN-THAM-DINH', 'label': 'Chuyển thẩm định', 'rationale': 'Đủ giấy tờ'}],
           'requiresHumanDecision': True, 'modelVersionId': U3, 'aiGenerated': True}),
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
    return {'name': name.rstrip('!'), 'in': 'query', 'required': req, 'schema': dsl17.ty(t)}


def res_key(path):
    segs = [s for s in re.sub(r':[a-z0-9-]+$', '', path).strip('/').split('/') if not s.startswith('{')]
    if segs and segs[0] == 'assist':
        return 'dp'
    if len(segs) >= 2 and segs[0] in NEST:
        return segs[0] + '/' + segs[1]
    return segs[0]


def plan(n, m, path):
    act = re.search(r':([a-z0-9-]+)$', path)
    verb = act.group(1) if act else None
    if n in OV:
        r, c, s = OV[n]
        return r, c, s, verb
    key = res_key(path)
    s = SEG[key]
    parts = [p for p in path.strip('/').split('/')]
    is_item = parts[-1].endswith('}')
    if m == 'GET':
        return None, 200, (s if is_item else s + 'Page'), verb
    if m == 'POST' and not act and not is_item:
        return s + 'Input', 201, s, verb
    if m == 'PUT':
        return s + 'Input', 200, s, verb
    if m == 'PATCH':
        return s + 'Patch', 200, s, verb
    if m == 'DELETE':
        return None, 204, None, verb
    if m == 'POST' and act and verb in VERB:
        return VERB[verb], 200, s, verb
    raise SystemExit('Thiếu quy tắc cho API-17-%03d %s %s' % (n, m, path))


def build_paths():
    paths = {}
    for num, m, path, frs, perm, summ in ROWS:
        n = int(num)
        dp = path.startswith('/assist/v1')
        key = res_key(path)
        seg = key.split('/')[0]
        req_s, code, resp_s, verb = plan(n, m, path)
        perms = [p.strip() for p in perm.split(',')]
        pm = ['PERM-17-' + p for p in perms if not p.startswith('scope ') and p != 'mTLS DU']
        sc = [p[6:].strip() for p in perms if p.startswith('scope ')]
        fr = expand_fr(frs)
        op = {'tags': ['Data plane' if dp else SEG_TAG[seg]], 'operationId': 'assist%03d' % n, 'summary': summ.strip(), 'x-datahub-id': 'API-17-%03d' % n,
              'x-datahub-fr': ['FR-17-%03d' % f for f in fr]}
        px = [x for x in (' / '.join(pm), ('scope ' + ', '.join(sc)) if sc else '', 'mTLS DU' if 'mTLS DU' in perms else '') if x]
        op['x-datahub-permission'] = {'permission': '; '.join(px)}
        op['description'] = KEY_NOTE.get(n) or ('%s Quyền %s; FR-17-%s.' % (summ.strip().rstrip('.'), op['x-datahub-permission']['permission'] or 'theo token', ', '.join('%03d' % f for f in fr)))
        if dp:
            op['security'] = [{'oauth2Machine': sc, 'mtlsSpiffe': []}] if sc else [{'mtlsSpiffe': []}]
            op['servers'] = [{'url': 'https://assist-infer.dh-assist.svc:8443', 'description': 'Data plane `ph17_infer` (3 bản sao, mTLS, danh tính SPIFFE); không qua APISIX người dùng.'}]
        else:
            sec = []
            if pm:
                sec.append({'oauth2User': []})
            for s_ in sc:
                assert s_ in SC, s_
                sec.append({'oauth2Machine': [s_]})
            op['security'] = sec
        if key in CLS:
            op['x-dh-classification'] = CLS[key]
        ps = []
        for pn in re.findall(r'\{(\w+)\}', path):
            if pn in PATH_P:
                sch = dsl17.ty(PATH_P[pn])
            else:
                sch = {'type': 'string', 'format': 'uuid'} if pn.endswith('Id') else {'type': 'string'}
            ps.append({'name': pn, 'in': 'path', 'required': True, 'schema': sch})
        is_list = m == 'GET' and resp_s and resp_s.endswith('Page')
        if is_list:
            ps += [ref('parameters', 'Page'), ref('parameters', 'Size'), ref('parameters', 'Sort')]
            for tok in dsl17.split_top(FILT.get(key, '')):
                ps.append(qparam(tok))
        elif m == 'GET' and n in STAT_FILT:
            for tok in dsl17.split_top(STAT_FILT[n]):
                ps.append(qparam(tok))
        ifm = (m in ('PUT', 'PATCH') or (m == 'DELETE' and path.rstrip('/').endswith('}')) or
               (m == 'POST' and verb in ('approve', 'reject', 'retire', 'suspend', 'resume', 'pause', 'submit', 'enable', 'disable', 'release', 'approve-release', 'triage', 'resolve', 'review', 'apply'))) and not dp
        if ifm:
            ps.append(ref('parameters', 'IfMatch'))
        idem = m == 'POST' and not dp and n not in SAFE_POST
        if idem:
            ps.append(ref('parameters', 'IdempotencyKey'))
            op['x-datahub-idempotent'] = 'required'
        ps += [ref('parameters', 'Traceparent'), ref('parameters', 'AcceptLanguage')]
        op['parameters'] = ps
        if req_s:
            body = {'schema': schema_of(req_s)}
            if n in EX:
                body['example'] = EX[n][0]
            op['requestBody'] = {'required': True, 'content': {'application/json': body}}
        rs = {}
        if resp_s is None:
            rs[str(code)] = {'description': 'Thành công, không có nội dung.'}
        elif n == 96:
            rs['200'] = {'description': 'Luồng sự kiện máy chủ (SSE).', 'headers': {'Cache-Control': {'schema': {'type': 'string', 'const': 'no-store'}}},
                         'content': {'text/event-stream': {'schema': schema_of('SseStream'),
                                                           'example': 'event: message.delta\ndata: {"text":"API tra cứu thuế"}\n\nevent: message.done\ndata: {"messageId":"%s"}\n\n' % U2}}}
        elif n == 176:
            rs['200'] = {'description': 'Gói bằng chứng đã ký.', 'content': {'application/zip': {'schema': schema_of('BinaryFile')}}}
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
            if hd:
                r['headers'] = hd
            rs[str(code)] = r
        # lỗi
        errs = set()
        for f in fr:
            for e in ERRFR.get(f, []):
                num_e = int(e[-3:])
                if dp != (num_e >= 101):
                    continue
                errs.add(e)
        if m == 'GET':
            errs = {e for e in errs if ERRS[e][0] in (403, 404, 410, 422)}
        domain = sorted(errs)
        structural = set()
        if not dp:
            if req_s:
                structural.add('ERR-17-003')
            if re.search(r'\}', path):
                structural.add('ERR-17-001')
            if ifm:
                structural.add('ERR-17-004')
            if verb and verb not in ('record-decision',):
                structural.add('ERR-17-006')
            if verb in ('approve', 'approve-release') or (verb == 'reject' and 'ReasonInput' == req_s) and verb == 'approve':
                structural.add('ERR-17-005')
            if verb in ('approve', 'approve-release', 'reject'):
                structural.add('ERR-17-005')
            if req_s == 'ReasonInput':
                structural.add('ERR-17-007')
            if m != 'GET':
                structural.add('ERR-17-010')
            if idem:
                structural.add('ERR-17-087')
        allerr = sorted(set(domain) | structural)
        for c in allerr:
            if c not in ERRS:
                raise SystemExit('Mã lỗi không có ở FRS: %s (API-17-%03d)' % (c, n))
            for st in ERRS[c][1]:
                rs.setdefault(str(st), ref('responses', HTTP_NAME[st]))
        for st in (401, 403):
            rs.setdefault(str(st), ref('responses', HTTP_NAME[st]))
        if ifm:
            rs.setdefault('428', ref('responses', 'PreconditionRequired'))
        if idem:
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
        'oauth2User': {'type': 'oauth2', 'description': 'Người dùng đăng nhập Keycloak (realm của tenant), Authorization Code với PKCE qua BFF; quyền chức năng `PERM-17-*` ở claim `permissions`.',
                       'flows': {'authorizationCode': {'authorizationUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth',
                                                       'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token', 'scopes': {}}}},
        'oauth2Machine': {'type': 'oauth2', 'description': 'Token dịch vụ (client_credentials với mTLS hoặc private_key_jwt) của DU gọi.',
                          'flows': {'clientCredentials': {'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token', 'scopes': dict(SC)}}},
        'mtlsSpiffe': {'type': 'mutualTLS', 'description': 'Danh tính DU theo SPIFFE ID của Istio; data plane kiểm DU nào có scope nào (SEC-15).'}}
    C['parameters'] = {
        'Page': {'name': 'page', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0, 'default': 0}, 'description': 'Số trang, từ 0.'},
        'Size': {'name': 'size', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100, 'default': 20}, 'description': 'Cỡ trang, 1…100.'},
        'Sort': {'name': 'sort', 'in': 'query', 'schema': {'type': 'string'}, 'description': 'Khóa sắp xếp; tiền tố `-` là giảm dần.'},
        'IdempotencyKey': {'name': 'Idempotency-Key', 'in': 'header', 'required': True, 'schema': {'type': 'string', 'format': 'uuid'}, 'description': 'Khóa chống trùng (BR-17-087); giữ 24 giờ; cùng khóa và thân trả lại phản hồi cũ.'},
        'IfMatch': {'name': 'If-Match', 'in': 'header', 'required': True, 'schema': {'type': 'string'}, 'description': '`ETag` của đối tượng; thiếu trả `428`, lệch trả `409` ERR-17-004.'},
        'Traceparent': {'name': 'traceparent', 'in': 'header', 'schema': {'type': 'string', 'pattern': '^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'}, 'description': 'W3C Trace Context.'},
        'AcceptLanguage': {'name': 'Accept-Language', 'in': 'header', 'schema': {'type': 'string', 'enum': ['vi', 'en']}, 'description': 'Ngôn ngữ thông báo lỗi.'}}
    resp = {}
    for st, name in HTTP_NAME.items():
        exs = {}
        for c, (h, _, t) in ERRS.items():
            if h == st and len(exs) < 3:
                exs[c.replace('-', '_')] = {'summary': t, 'value': {'type': 'https://datahub.gov.vn/errors/' + c, 'title': t, 'status': st, 'code': c, 'traceId': TRACE}}
        codes = sorted(c for c, (h, _, _) in ERRS.items() if h == st)
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
        'info': {'title': 'Datahub · PH-17 Trợ lý AI và quản trị AI', 'version': '1.0.0-draft',
                 'summary': 'Chính sách bật tắt theo tenant, cổng và sổ mô hình, kho tri thức, hỏi đáp tìm dịch vụ, gợi ý ánh xạ, giải thích sự cố, công cụ chỉ đọc, chặn an toàn, đánh giá và ca đỏ, nhật ký, báo cáo, dịch vụ AI cho phân hệ khác.',
                 'description': ('Module `assist` của `dh-assist` (package `vn.datahub.assist`): control plane `/api/assist/v1` qua APISIX và BFF; data plane `/assist/v1` chỉ trong cụm (mTLS, SPIFFE).\n\n'
                                 'Quy ước (D03-04-PH17 §1): tenant lấy từ token, không từ tham số; mọi `POST` đổi dữ liệu nhận `Idempotency-Key`; `PUT`, `PATCH`, hành động có `If-Match`; hậu tố `:{hành-động}`; '
                                 'phân trang `page`, `size`, `sort`; lỗi RFC 9457 mã `ERR-17-nnn`; câu trả lời phát trực tuyến bằng SSE. Không có nội dung hội thoại chưa che, bí mật nhà cung cấp hay vector ở phản hồi. '
                                 'Mọi tên, mã, số trong ví dụ là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.'),
                 'contact': {'name': 'Nhóm phân hệ PH-17'}, 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)', 'identifier': 'LicenseRef-Datahub-Internal'},
                 'x-datahub-document': 'D03-04-PH17', 'x-datahub-phase': 'PH-17'},
        'servers': [{'url': 'https://api.{tenantHost}.datahub.example.vn/api/assist/v1', 'description': 'Control plane qua APISIX (giả lập)',
                     'variables': {'tenantHost': {'default': 't68', 'description': 'Ví dụ `t68` (giả lập).'}}},
                    {'url': 'http://dh-assist.dh-assist.svc:8080/api/assist/v1', 'description': 'Control plane trong cụm'},
                    {'url': 'http://localhost:8087/api/assist/v1', 'description': 'Phát triển cục bộ'}],
        'security': [{'oauth2User': []}],
        'tags': [{'name': t, 'description': d} for t, d, _ in TAGS],
        'paths': paths, 'components': components()}


def main():
    d = doc()
    # Bỏ lược đồ enum không được $ref ở đâu (enum Phụ lục A chỉ dùng ở CSDL), tránh cảnh báo oas3-unused-component
    sch = d['components']['schemas']
    for _ in range(3):
        blob = yaml.safe_dump({k: v for k, v in d.items() if k != 'components'}, allow_unicode=True) + yaml.safe_dump({k: v for k, v in d['components'].items() if k != 'schemas'}, allow_unicode=True)
        for k, v in list(sch.items()):
            if set(v) <= {'type', 'enum', 'description'} and 'enum' in v:
                ref = "#/components/schemas/%s'" % k
                used = ref in blob or ("#/components/schemas/%s\n" % k) in blob or any(ref in yaml.safe_dump(o) or ("#/components/schemas/%s\n" % k) in yaml.safe_dump(o) for kk, o in sch.items() if kk != k)
                if not used:
                    del sch[k]
    out = os.path.join(HERE, '..', 'openapi-assist.yaml')
    head = '# D03-04-PH17 · OpenAPI PH-17 (module assist của dh-assist). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n'
    open(out, 'w', encoding='utf-8').write(head + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    n = sum(len(v) for v in d['paths'].values())
    print('ghi', out, len(d['paths']), 'đường dẫn,', n, 'operation,', len(d['components']['schemas']), 'lược đồ')


if __name__ == '__main__':
    main()
