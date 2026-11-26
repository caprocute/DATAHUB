#!/usr/bin/env python3
"""Nguồn duy nhất của hợp đồng API PH-08: đọc FRS §9.4 (mã, phương thức, đường dẫn), bảng operation, lược đồ.

Không chạy trực tiếp; gen_openapi.py, gen_asyncapi.py, gen_md.py, check_contracts.py, doi_chieu_frs.py nhập module này.
Enum lấy thẳng từ Phụ lục A của FRS (E('Tên')), tên trường camelCase theo cột DDL ph08_dq.sql.
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS_PATH = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH08-frs-chat-luong-du-lieu.md")
FRS = open(FRS_PATH, encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]

# ---------------------------------------------------------------- FRS
ERR = {}  # mã -> (danh sách HTTP, ý nghĩa)
_s91 = FRS[FRS.index("### 9.1."):FRS.index("### 9.2.")]
for m in re.finditer(r"^\| (ERR-08-\d{3}) \| ([^|]+?) \| ([^|]+?) \|", _s91, re.M):
    ERR[m.group(1)] = ([int(x) for x in re.findall(r"\d{3}", m.group(2))], m.group(3).strip())
MSG = {m.group(1): m.group(2) for m in re.finditer(r'^\| (ERR-08-\d{3}) \| "([^|]+)" \| ([^|]+) \|', FRS[FRS.index("### 9.2."):FRS.index("### 9.3.")], re.M)}
MSG_POS = {m.group(1): m.group(3).strip() for m in re.finditer(r'^\| (ERR-08-\d{3}) \| "([^|]+)" \| ([^|]+) \|', FRS[FRS.index("### 9.2."):FRS.index("### 9.3.")], re.M)}
_s93 = FRS[FRS.index("### 9.3."):FRS.index("### 9.4.")]
EVT = [(m.group(1), m.group(2), m.group(3).strip(), m.group(4).strip()) for m in
       re.finditer(r"^\| (EVT-08-\d{2}) \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \|", _s93, re.M)]
EVT_IN = [(m.group(1), m.group(2), m.group(3).strip()) for m in
          re.finditer(r"^\| (EVT-0[67]-\d{2}) \| `([^`]+)` \| ([^|]+?) \|", _s93, re.M)]
PERMS = sorted(set(re.findall(r"PERM-08-[a-z-]+", FRS)))

ALIAS = {
    "Dimension": "dimension", "Severity": "severity", "AssetType": "asset_type", "AssetStatus": "asset_status", "DomainStatus": "domain_status",
    "VersionStatus": "rule_set_version.status", "WeightStatus": "weight_config.status", "WeightScope": "weight_config.scope",
    "ExecMode": "rule.exec_mode", "RuleSource": "rule.source", "Operator": "operator", "ChecksumAlgorithm": "checksum_algorithm",
    "ScanMode": "scan_mode", "ScanTrigger": "scan_trigger", "ScanStatus": "scan_status", "TaskStatus": "scan_task.status",
    "ScheduleStatus": "schedule.status", "RuleResultStatus": "rule_result.status", "Verdict": "verdict", "Trend": "trend",
    "SnapshotFlag": "Cờ ảnh chụp, lần đo", "FindingStatus": "finding.status", "ResolutionReason": "finding.resolution_reason",
    "DataClass": "data_class", "WaiverStatus": "waiver.status", "WaiverScope": "waiver.scope", "IssueStatus": "issue.status",
    "RejectType": "issue.reject_type", "ActivityType": "issue_activity.type", "StewardAction": "steward_action",
    "InlineMode": "inline_mode", "OnDependencyFailure": "on_dependency_failure", "KameletOnFail": "kamelet_on_fail",
    "AlertCondition": "alert.condition", "AlertSeverity": "alert.severity", "AlertStatus": "alert.status", "ReportType": "report_type",
    "ReportStatus": "report.status", "AnnualMethod": "annual_snapshot_method", "ScorecardScope": "scorecard_scope",
    "ExportFormat": "export.format", "SubscriptionChannel": "subscription.channel", "ProfileStatus": "profile_run.status",
    "ProfileMode": "profile_run.mode", "DimensionMethod": "score.dimension_method",
}
# enum không có dòng riêng ở Phụ lục A (lấy từ DDL ph08_dq.sql hoặc chỉ có ở API; ghi ở mục đề nghị bổ sung)
LOCAL = {
    "FieldType": ["STRING", "INTEGER", "DECIMAL", "DATE", "TIMESTAMP", "BOOLEAN", "CODE", "JSON"],
    "ClassificationStatus": ["PROPOSED", "CONFIRMED"],
    "ValueMode": ["MASKED", "HASH_ONLY", "PLAIN"],
    "TemplateStatus": ["ACTIVE", "RETIRED"],
    "VersionDecision": ["APPROVE", "REJECT"],
    "DimensionStatus": ["MEASURED", "SKIPPED"],
    "RecipientType": ["USER", "ROLE", "ORG"],
    "ReportFileFormat": ["PDF", "XLSX"],
    "RuleFileFormat": ["YAML", "JSON"],
    "ExportKind": ["FINDINGS", "REPORT"],
    "ExportStatus": ["PENDING_APPROVAL", "APPROVED", "RUNNING", "READY", "FAILED", "EXPIRED", "REJECTED"],
    "Granularity": ["MINUTE", "HOUR", "DAY"],
    "ObjectType": ["TABLE", "VIEW"],
    "RetentionAction": ["DROP_PARTITION", "DELETE", "ARCHIVE_COLD", "ANONYMIZE"],
    "RetentionRunStatus": ["RUNNING", "SUCCEEDED", "FAILED"],
    "BreachKind": ["VERDICT_FAIL", "BELOW_WARN"],
    "StatusChangeKind": ["STATUS_CHANGE", "OVERDUE", "ESCALATED"],
    "KpiKind": ["SCAN_SNAPSHOT", "REPORT", "ISSUE_DAILY"],
    "VerifyMode": ["SCAN", "MANUAL"],
    "ExportDecisionValue": ["APPROVE", "REJECT"],
    "AuditOutcome": ["SUCCESS", "DENIED", "FAILED"],
}


def E(name):
    if name in LOCAL:
        return LOCAL[name]
    key = ALIAS[name]
    m = re.search(r"^\| (?:`%s`|%s)(?: \([^)]*\))? \| ([^|]+) \|" % (re.escape(key), re.escape(key)), APPX, re.M)
    if not m:
        raise SystemExit("Không có enum %s ở Phụ lục A" % key)
    return re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(1)))


def fr_errs():
    """Với mỗi FR: tập (mã ERR, HTTP) ở mục Luồng ngoại lệ."""
    out = {}
    for m in re.finditer(r"#### (FR-08-\d{3}) · [^\n]+\n\n::: dac-ta\n(.*?)\n:::", FRS, re.S):
        x = re.search(r"\*\*Luồng ngoại lệ\.\*\*\s*(.*?)(?=\n\n\*\*|\Z)", m.group(2), re.S)
        out[m.group(1)] = sorted(set((a, int(b)) for a, b in re.findall(r"(ERR-08-\d{3}) \((\d{3})\)", x.group(1)))) if x else []
    return out


FRERR = fr_errs()
FR_TITLE = dict(re.findall(r"^\| (FR-08-\d{3}) \| [A-J] \| ([^|]+?) \|", FRS, re.M))

# ---------------------------------------------------------------- operation theo FRS §9.4
ROWS = []  # (mã 3 số, phương thức, đường dẫn, [FR])
_sec = FRS[FRS.index("### 9.4."):FRS.index("## 10. Giao diện")]
for m in re.finditer(r"^\| API-08-(\d{3}) \| `([A-Z]+) ([^`]+)`(?: \([^)]*\))? \| ([^|]+) \|", _sec, re.M):
    ROWS.append((m.group(1), m.group(2), m.group(3), [f"FR-08-{x}" for x in re.findall(r"\d{3}", m.group(4))]))
# API-08-073 trong FRS dùng chung mã cho GET /findings và POST /findings:search; tập này cấp mã riêng 129 (đề nghị FRS cập nhật)
ROWS.append(("129", "POST", "/findings:search", ["FR-08-037"]))
ROWS.sort(key=lambda r: r[0])
assert len(ROWS) == 129, len(ROWS)

# ---------------------------------------------------------------- bảng operation
# mã | tóm tắt | nhóm | quyền (a/b = hoặc) | thân yêu cầu | thân phản hồi | HTTP | truy vấn | cờ
# cờ: idem, noifm, m:scope (máy có scope), only:scope (chỉ máy), also:HTTP, internal
OPS_TXT = """
001|Danh sách miền chất lượng|Miền và đối tượng đo|read|-|DomainPage|200|status:E:DomainStatus,q:str,page,size|
002|Khai báo miền chất lượng|Miền và đối tượng đo|asset|DomainCreate|Domain|201|-|idem
003|Chi tiết miền chất lượng|Miền và đối tượng đo|read|-|Domain|200|-|
004|Sửa miền chất lượng|Miền và đối tượng đo|asset|DomainUpdate|Domain|200|-|
005|Danh sách đối tượng đo|Miền và đối tượng đo|read|-|AssetPage|200|domainCode:dcode,assetType:E:AssetType,status:E:AssetStatus,verdict:E:Verdict,ownerOrgCode:org,q:str,page,size|
006|Đăng ký đối tượng đo|Miền và đối tượng đo|asset|AssetCreate|Asset|201|-|idem
007|Chi tiết đối tượng đo|Miền và đối tượng đo|read|-|Asset|200|-|
008|Sửa đối tượng đo|Miền và đối tượng đo|asset|AssetUpdate|Asset|200|-|
009|Kích hoạt đối tượng đo|Miền và đối tượng đo|asset|CommentBody|Asset|200|-|
010|Tạm ngừng đối tượng đo|Miền và đối tượng đo|asset|ReasonBody|Asset|200|-|
011|Tiếp tục đối tượng đo|Miền và đối tượng đo|asset|ReasonBody|Asset|200|-|
012|Ngừng đối tượng đo|Miền và đối tượng đo|asset|ReasonBody|Asset|200|-|
013|Danh sách trường và CDE của đối tượng|Miền và đối tượng đo|read|-|AssetFieldPage|200|cde:bool,page,size|
014|Khai báo trường và CDE|Miền và đối tượng đo|asset|AssetFieldPut|AssetField|200|-|
015|Đồng bộ phân loại trường từ PH-09|Miền và đối tượng đo|asset|-|ClassificationSyncResult|200|-|noifm
016|Domain PH-06 có thể đo|Nguồn đối tượng đo|asset|-|MdmDomainSourcePage|200|q:str,page,size|
017|Danh mục PH-07 có thể đo|Nguồn đối tượng đo|asset|-|RdmCatalogSourcePage|200|q:str,page,size|
018|Khám phá bảng của kết nối PH-05|Nguồn đối tượng đo|asset|DiscoverRequest|DiscoverResult|200|-|noifm
019|Chạy hồ sơ dữ liệu|Hồ sơ dữ liệu|asset|ProfileRunCreate|ProfileRun|202|-|idem
020|Danh sách lần hồ sơ của đối tượng|Hồ sơ dữ liệu|read|-|ProfileRunPage|200|status:E:ProfileStatus,page,size|
021|Chi tiết lần hồ sơ|Hồ sơ dữ liệu|read|-|ProfileRun|200|-|
022|Thống kê cột của lần hồ sơ|Hồ sơ dữ liệu|read|-|ProfileColumnPage|200|fieldName:fpath,page,size|
023|Gợi ý quy tắc từ hồ sơ|Hồ sơ dữ liệu|rule-admin|SuggestRulesRequest|SuggestRulesResult|200|-|noifm
024|Nhận chỉ số hồ sơ từ PH-05|Hồ sơ dữ liệu|-|ProfileMetricsIn|ProfileMetricsResult|202|-|only:dq.ingest internal
025|Danh sách bộ quy tắc|Bộ quy tắc|read|-|RuleSetPage|200|assetCode:acode,status:E:VersionStatus,q:str,page,size|
026|Tạo bộ quy tắc|Bộ quy tắc|rule-admin|RuleSetCreate|RuleSet|201|-|idem
027|Chi tiết bộ quy tắc|Bộ quy tắc|read|-|RuleSet|200|-|
028|Danh sách phiên bản bộ quy tắc|Bộ quy tắc|read|-|RuleSetVersionPage|200|status:E:VersionStatus,page,size|
029|Tạo phiên bản nháp|Bộ quy tắc|rule-admin|VersionCreate|RuleSetVersion|201|-|idem
030|Chi tiết phiên bản kèm quy tắc|Bộ quy tắc|read|-|RuleSetVersion|200|-|
031|Thêm quy tắc vào phiên bản nháp|Quy tắc|rule-admin|RuleUpsert|Rule|201|-|idem
032|Sửa quy tắc trong phiên bản nháp|Quy tắc|rule-admin|RuleUpsert|Rule|200|-|
033|Xóa quy tắc khỏi phiên bản nháp|Quy tắc|rule-admin|-|-|204|-|
034|Kiểm biểu thức CEL, vị từ SQL|Quy tắc|rule-admin|ExpressionValidateRequest|ExpressionValidateResult|200|-|
035|Danh sách quy tắc mẫu|Quy tắc|read|-|RuleTemplatePage|200|dimension:E:Dimension,operator:E:Operator,page,size|
036|Tạo quy tắc mẫu|Quy tắc|rule-admin|RuleTemplateCreate|RuleTemplate|201|-|idem
037|Chạy thử phiên bản trên mẫu|Bộ quy tắc|rule-admin|DryRunRequest|DryRunResult|200|-|noifm
038|Gửi duyệt phiên bản|Bộ quy tắc|rule-admin|CommentBody|RuleSetVersion|200|-|
039|Duyệt phiên bản|Bộ quy tắc|approve|CommentBody|RuleSetVersion|200|-|
040|Từ chối phiên bản|Bộ quy tắc|approve|RejectBody|RuleSetVersion|200|-|
041|Kích hoạt phiên bản|Bộ quy tắc|approve|ActivateRequest|RuleSetVersion|200|-|
042|Ngừng bộ quy tắc|Bộ quy tắc|rule-admin|ReasonBody|RuleSet|200|-|
043|So sánh hai phiên bản|Bộ quy tắc|read|-|VersionDiff|200|with:int|
044|Sao chép bộ quy tắc|Bộ quy tắc|rule-admin|RuleSetCopyRequest|RuleSet|201|-|idem noifm
045|Xuất phiên bản YAML, JSON|Bộ quy tắc|rule-admin|-|RuleSetExport|200|format:E:RuleFileFormat|
046|Nhập bộ quy tắc từ tệp|Bộ quy tắc|rule-admin|RuleSetImportRequest|RuleSet|201|-|idem
047|Danh sách cấu hình trọng số|Trọng số và ngưỡng|read|-|WeightConfigPage|200|scope:E:WeightScope,status:E:WeightStatus,page,size|
048|Tạo cấu hình trọng số nháp|Trọng số và ngưỡng|rule-admin|WeightConfigCreate|WeightConfig|201|-|idem
049|Sửa cấu hình trọng số nháp|Trọng số và ngưỡng|rule-admin|WeightConfigUpdate|WeightConfig|200|-|
050|Gửi duyệt cấu hình trọng số|Trọng số và ngưỡng|rule-admin|CommentBody|WeightConfig|200|-|
051|Duyệt cấu hình trọng số|Trọng số và ngưỡng|approve|CommentBody|WeightConfig|200|-|
052|Từ chối cấu hình trọng số|Trọng số và ngưỡng|approve|RejectBody|WeightConfig|200|-|
053|Tìm quy tắc trong toàn tenant|Quy tắc|read|-|RuleListItemPage|200|assetCode:acode,dimension:E:Dimension,operator:E:Operator,severity:E:Severity,enabled:bool,q:str,page,size|
054|Danh sách lịch đo|Lịch và lần đo|read|-|SchedulePage|200|assetCode:acode,status:E:ScheduleStatus,page,size|
055|Tạo lịch đo|Lịch và lần đo|run|ScheduleCreate|Schedule|201|-|idem
056|Sửa lịch đo|Lịch và lần đo|run|ScheduleUpdate|Schedule|200|-|
057|Tạm dừng lịch đo|Lịch và lần đo|run|CommentBody|Schedule|200|-|
058|Tiếp tục lịch đo|Lịch và lần đo|run|CommentBody|Schedule|200|-|
059|Chạy đo theo yêu cầu|Lịch và lần đo|run|ScanCreate|ScanJob|202|-|idem
060|Danh sách lần đo|Lịch và lần đo|read|-|ScanJobPage|200|assetCode:acode,status:E:ScanStatus,scanTrigger:E:ScanTrigger,periodCode:period,from:ts,to:ts,page,size|
061|Chi tiết lần đo|Lịch và lần đo|read|-|ScanJob|200|-|
062|Hủy lần đo|Lịch và lần đo|run|ReasonBody|ScanJob|200|-|
063|Chạy lại lần đo|Lịch và lần đo|run|RerunRequest|ScanJob|202|-|idem noifm
064|Kết quả theo quy tắc của lần đo|Lịch và lần đo|read|-|RuleResultPage|200|status:E:RuleResultStatus,dimension:E:Dimension,page,size|
065|Điểm và điểm chiều của lần đo|Điểm và thẻ điểm|read|-|ScoreSnapshot|200|-|m:dq.read
066|Lịch sử điểm của đối tượng|Điểm và thẻ điểm|read|-|ScorePointPage|200|from:ts,to:ts,official:bool,page,size|m:dq.read
067|Tác vụ phân mảnh của lần đo|Lịch và lần đo|read|-|ScanTaskPage|200|status:E:TaskStatus,page,size|
068|Kiểm tra trực tuyến một bản ghi|Kiểm tra trực tuyến|-|CheckRequest|CheckResult|200|-|only:dq.check
069|Kiểm tra trực tuyến lô bản ghi|Kiểm tra trực tuyến|-|CheckBatchRequest|CheckBatchResult|200|-|only:dq.check
070|Thống kê kiểm tra trực tuyến|Kiểm tra trực tuyến|read|-|InlineStats|200|assetCode:acode,caller:str,from:ts,to:ts,granularity:E:Granularity|
071|Cấu hình kiểm tra trực tuyến|Kiểm tra trực tuyến|rule-admin|InlineConfigPut|InlineConfig|200|-|
072|Xem cấu hình kiểm tra trực tuyến|Kiểm tra trực tuyến|read|-|InlineConfig|200|-|
073|Danh sách bản ghi lỗi|Bản ghi lỗi|finding-read|-|FindingPage|200|assetCode:acode,ruleCode:rcode,dimension:E:Dimension,severity:E:Severity,status:E:FindingStatus,ownerOrgCode:org,scanId:uuid,fieldName:fpath,from:ts,to:ts,page,size|
074|Chi tiết bản ghi lỗi|Bản ghi lỗi|finding-read|-|FindingDetail|200|-|
075|Đề nghị xuất bản ghi lỗi|Bản ghi lỗi|export|FindingExportCreate|ExportRequest|202|-|idem
076|Chấp thuận hoặc từ chối xuất|Bản ghi lỗi|export/finding-read|ExportDecision|ExportRequest|200|-|
077|Trạng thái và liên kết tải tệp xuất|Bản ghi lỗi|export|-|ExportRequest|200|-|
078|Nhóm bản ghi lỗi|Bản ghi lỗi|finding-read|-|FindingGroupPage|200|assetCode:acode,severity:E:Severity,ownerOrgCode:org,page,size|
079|Đề nghị ngoại lệ chấp nhận|Ngoại lệ|rule-admin|WaiverCreate|Waiver|201|-|idem
080|Danh sách ngoại lệ|Ngoại lệ|finding-read|-|WaiverPage|200|assetCode:acode,status:E:WaiverStatus,page,size|
081|Duyệt ngoại lệ|Ngoại lệ|approve|CommentBody|Waiver|200|-|
082|Từ chối ngoại lệ|Ngoại lệ|approve|RejectBody|Waiver|200|-|
083|Thu hồi ngoại lệ|Ngoại lệ|approve|ReasonBody|Waiver|200|-|
084|Mở phiếu khắc phục|Phiếu khắc phục|remediate|IssueCreate|Issue|201|-|idem
085|Danh sách phiếu khắc phục|Phiếu khắc phục|read|-|IssuePage|200|assetCode:acode,status:E:IssueStatus,severity:E:Severity,ownerOrgCode:org,assignee:str,overdue:bool,page,size|
086|Chi tiết phiếu khắc phục|Phiếu khắc phục|read|-|Issue|200|-|
087|Phân công phiếu|Phiếu khắc phục|remediate|IssueAssign|Issue|200|-|
088|Bắt đầu xử lý phiếu|Phiếu khắc phục|remediate|CommentBody|Issue|200|-|
089|Thêm trao đổi vào phiếu|Phiếu khắc phục|remediate|IssueActivityCreate|IssueActivity|201|-|idem
090|Báo đã sửa|Phiếu khắc phục|remediate|IssueMarkFixed|Issue|200|-|
091|Xác nhận, đo kiểm chứng|Phiếu khắc phục|remediate|IssueVerify|Issue|200|-|
092|Từ chối phiếu|Phiếu khắc phục|remediate|IssueReject|Issue|200|-|
093|Chuyển phiếu sang tổ chức khác|Phiếu khắc phục|remediate|IssueTransfer|Issue|200|-|
094|Leo thang phiếu|Phiếu khắc phục|remediate|IssueEscalate|Issue|200|-|
095|Chuyển lỗi bản ghi vàng sang steward PH-06|Phiếu khắc phục|remediate|IssueSendToSteward|StewardTransfer|200|-|
096|Hủy phiếu|Phiếu khắc phục|remediate|ReasonBody|Issue|200|-|
097|Lịch sử trao đổi của phiếu|Phiếu khắc phục|read|-|IssueActivityPage|200|activityType:E:ActivityType,page,size|
098|Danh sách quy tắc cảnh báo|Cảnh báo|read|-|AlertRulePage|200|assetCode:acode,enabled:bool,page,size|
099|Tạo quy tắc cảnh báo|Cảnh báo|rule-admin|AlertRuleUpsert|AlertRule|201|-|idem
100|Sửa quy tắc cảnh báo|Cảnh báo|rule-admin|AlertRuleUpsert|AlertRule|200|-|
101|Danh sách cảnh báo|Cảnh báo|read|-|AlertPage|200|status:E:AlertStatus,severity:E:AlertSeverity,assetCode:acode,page,size|
102|Xác nhận cảnh báo|Cảnh báo|run/rule-admin|CommentBody|Alert|200|-|
103|Tắt tiếng cảnh báo|Cảnh báo|run/rule-admin|AlertSilence|Alert|200|-|
104|Bảng điều khiển chất lượng|Bảng điều khiển và thẻ điểm|read|-|Dashboard|200|periodCode:period,domainCode:dcode|
105|Thẻ điểm theo phạm vi|Bảng điều khiển và thẻ điểm|read|-|ScorecardPage|200|scope:E:ScorecardScope,periodCode:period,verdict:E:Verdict,page,size|m:dq.read
106|Thẻ điểm của một đối tượng đo|Bảng điều khiển và thẻ điểm|read|-|AssetScorecard|200|periodCode:period|m:dq.read
107|Tạo báo cáo|Báo cáo|report|ReportCreate|Report|201|-|idem
108|Danh sách báo cáo|Báo cáo|read|-|ReportPage|200|reportType:E:ReportType,status:E:ReportStatus,periodCode:period,page,size|
109|Chi tiết báo cáo|Báo cáo|read|-|Report|200|-|
110|Sửa báo cáo nháp|Báo cáo|report|ReportUpdate|Report|200|-|
111|Gửi duyệt báo cáo|Báo cáo|report|CommentBody|Report|200|-|
112|Duyệt và công bố báo cáo|Báo cáo|approve|CommentBody|Report|200|-|
113|Từ chối báo cáo|Báo cáo|approve|RejectBody|Report|200|-|
114|Thu hồi báo cáo|Báo cáo|approve|ReasonBody|Report|200|-|
115|Kiểm điều kiện báo cáo năm|Báo cáo|report|AnnualReadinessRequest|AnnualReadinessResult|200|-|
116|Xuất báo cáo PDF, XLSX|Báo cáo|report|ReportExportCreate|ExportRequest|202|-|idem
117|Tải tệp xuất báo cáo|Báo cáo|read|-|ExportRequest|200|-|
118|Ký số báo cáo|Báo cáo|approve|ReportSignRequest|Report|200|-|
119|Danh sách đăng ký nhận báo cáo|Báo cáo|read|-|SubscriptionPage|200|reportType:E:ReportType,page,size|
120|Đăng ký nhận báo cáo|Báo cáo|read|SubscriptionCreate|Subscription|201|-|idem
121|Hủy đăng ký nhận báo cáo|Báo cáo|read|-|-|204|-|
122|Ảnh chụp KPI đã đẩy sang PH-16|Bảng điều khiển và thẻ điểm|read|-|KpiSnapshotPage|200|periodCode:period,kind:E:KpiKind,page,size|m:dq.read
123|Xem tham số chất lượng của tenant|Quản trị|read|-|TenantSettings|200|-|
124|Sửa tham số chất lượng của tenant|Quản trị|config|TenantSettingsPut|TenantSettings|200|-|
125|Lịch sử chạy dọn dữ liệu|Quản trị|config|-|RetentionRunPage|200|status:E:RetentionRunStatus,page,size|
126|Xem trước dọn dữ liệu|Quản trị|config|RetentionPreviewRequest|RetentionPreview|200|-|
127|Nhật ký kiểm toán PH-08|Quản trị|audit-read|-|AuditEventPage|200|objectType:str,objectCode:str,actor:str,from:ts,to:ts,page,size|
128|So sánh liên tenant ẩn danh|Quản trị|read|-|BenchmarkResult|200|periodCode:period,domainCode:dcode|
129|Tìm bản ghi lỗi theo khóa bản ghi|Bản ghi lỗi|finding-read|FindingSearchRequest|FindingPage|200|page,size|
"""
OPS = {}
for ln in OPS_TXT.strip().splitlines():
    c, s, tag, perm, rq, rs, st, q, fl = ln.split("|")
    OPS[c] = dict(code=c, summary=s, tag=tag, perm=perm, req=None if rq == "-" else rq, res=None if rs == "-" else rs, status=int(st),
                  query=[] if q == "-" else q.split(","), flags=fl.split())
assert set(OPS) == {r[0] for r in ROWS}, set(OPS) ^ {r[0] for r in ROWS}
TAGS = list(dict.fromkeys(o["tag"] for o in OPS.values()))

# ---------------------------------------------------------------- lược đồ
TYPES = {
    "str": ({"type": "string"}, "ví dụ"),
    "dcode": ({"type": "string", "pattern": "^[A-Z][A-Z0-9_]{1,31}$"}, "HO_TICH"),
    "acode": ({"type": "string", "pattern": "^[a-z][a-z0-9-]{2,62}$"}, "mdm-cong-dan"),
    "fpath": ({"type": "string", "pattern": "^[A-Za-z][A-Za-z0-9_.]{0,62}$"}, "citizenId"),
    "rcode": ({"type": "string", "pattern": "^[A-Z][A-Z0-9-]{2,62}$"}, "CD-ACC-001"),
    "rscode": ({"type": "string", "pattern": "^[a-z][a-z0-9-]{2,62}$"}, "bq-cong-dan"),
    "ccode": ({"type": "string", "pattern": "^[a-z][a-z0-9-]{2,62}$"}, "kn-ho-tich"),
    "org": ({"type": "string", "pattern": "^[a-z][a-z0-9-]{1,62}$"}, "so-tu-phap"),
    "icode": ({"type": "string", "pattern": "^DQI-[0-9]{4}-[0-9]{6}$"}, "DQI-2026-000123"),
    "rpcode": ({"type": "string", "pattern": "^BC-[0-9]{4}(-[0-9]{2})?(-[A-Z0-9]+)?$"}, "BC-2026-11"),
    "period": ({"type": "string", "pattern": "^[0-9]{4}-(0[1-9]|1[0-2])$"}, "2026-11"),
    "hex": ({"type": "string", "pattern": "^[0-9a-f]{16,64}$"}, "9f86d081884c7d659a2feaa0c55ad015"),
    "int": ({"type": "integer"}, 1), "num": ({"type": "number"}, 0.9), "bool": ({"type": "boolean"}, False),
    "score": ({"type": "number", "minimum": 0, "maximum": 100}, 92.5),
    "w": ({"type": "number", "minimum": 0, "maximum": 1}, 0.2),
    "ts": ({"type": "string", "format": "date-time"}, "2026-11-20T08:00:00+07:00"),
    "date": ({"type": "string", "format": "date"}, "2026-12-31"),
    "uuid": ({"type": "string", "format": "uuid"}, "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"),
    "obj": ({"type": "object"}, {}), "any": ({}, "ví dụ"),
}
SCH = {}
CODE = TYPES["rcode"][0]["pattern"]


def tschema(t, extra=None):
    """Chuyển kiểu rút gọn thành (lược đồ, ví dụ mặc định hoặc None khi dùng ví dụ của lược đồ tham chiếu)."""
    if t.startswith("[") and t.endswith("]"):
        s, ex = tschema(t[1:-1])
        out = {"type": "array", "items": s}
        if extra:
            out.update(extra)
        return out, [ex] if ex is not None else None
    if t.startswith("E:"):
        v = E(t[2:])
        return {"$ref": "#/components/schemas/" + t[2:]}, v[0]
    if t.startswith("$"):
        return {"$ref": "#/components/schemas/" + t[1:]}, None
    s, ex = TYPES[t]
    return dict(s), ex


ENUMS = set()


def obj(name, desc, *fields, req_all=False, extra=None):
    props, req, exs = {}, [], {}
    for f in fields:
        fn, ft = f[0], f[1]
        ex = f[2] if len(f) > 2 else None
        fx = f[3] if len(f) > 3 else None
        r = fn.endswith("!")
        fn = fn.rstrip("!")
        if ft.startswith("E:") or ft.startswith("[E:"):
            ENUMS.add(ft.strip("[]")[2:])
        s, dex = tschema(ft, fx)
        if fx and "$ref" not in s and s.get("type") != "array":
            s.update(fx)
        props[fn] = s
        if r or req_all:
            req.append(fn)
        if ex is not None:
            exs[fn] = ex
        elif dex is not None:
            exs[fn] = dex
    sc = {"type": "object", "description": desc, "properties": props}
    if req:
        sc["required"] = req
    if extra:
        sc.update(extra)
    sc["x-ex"] = exs
    SCH[name] = sc


def page(name, item):
    obj(name, "Trang kết quả.", ("items!", "[$%s]" % item), ("page!", "int", 0), ("size!", "int", 20), ("totalElements!", "int", 1))


def enum_schema(name):
    return {"type": "string", "enum": E(name)}


R20 = {"minLength": 20, "maxLength": 2000}
ID = ("id", "uuid")
AUD = [("createdAt", "ts"), ("createdBy", "str", "nguyen.thi.lan"), ("updatedAt", "ts"), ("updatedBy", "str", "nguyen.thi.lan"), ("version!", "int", 3)]
A = "mdm-cong-dan"

obj("FieldError", "Lỗi theo trường.", ("field!", "str", "record.citizenId"), ("message!", "str", "Giá trị không hợp lệ."))
obj("Problem", "Lỗi theo RFC 9457.", ("type!", "str", "https://datahub.example.vn/errors/ERR-08-003"), ("title!", "str", "Dữ liệu không hợp lệ"),
    ("status!", "int", 400), ("detail", "str", "Trường name bắt buộc."), ("instance", "str", "/api/dq/v1/assets"),
    ("code!", "str", "ERR-08-003"), ("traceId!", "str", "4bf92f3577b34da6a3ce929d0e0e4736"), ("errors", "[$FieldError]"))
obj("CommentBody", "Ý kiến kèm hành động.", ("comment", "str", "Đồng ý theo biên bản họp ngày 20/11/2026.", {"maxLength": 2000}))
obj("RejectBody", "Từ chối: bắt buộc nêu lý do từ 20 ký tự.", ("comment!", "str", "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại.", R20))
obj("ReasonBody", "Hành động kèm lý do từ 20 ký tự (ERR-08-007).", ("reason!", "str", "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123.", R20))

# --- miền, đối tượng
obj("Domain", "Miền chất lượng (dq_domain).", ("domainCode!", "dcode"), ("name!", "str", "Hộ tịch"), ("description", "str", "Dữ liệu đăng ký hộ tịch của tỉnh"),
    ("ownerOrgCode!", "org"), ("stewardUser!", "str", "tran.van.nam"), ("status!", "E:DomainStatus", "ACTIVE"), ("statusReason", "str", "Chuyển giao chủ quản"),
    ("onDependencyFailure", "E:OnDependencyFailure", "FAIL_OPEN"), *AUD)
obj("DomainCreate", "Khai báo miền (FR-08-001).", ("domainCode!", "dcode"), ("name!", "str", "Hộ tịch", {"maxLength": 255}), ("description", "str", "Dữ liệu đăng ký hộ tịch", {"maxLength": 2000}),
    ("ownerOrgCode!", "org"), ("stewardUser!", "str", "tran.van.nam"), ("onDependencyFailure", "E:OnDependencyFailure", "FAIL_OPEN"))
obj("DomainUpdate", "Sửa miền; gửi các trường cần đổi.", ("name", "str", "Hộ tịch và quốc tịch"), ("description", "str", "Dữ liệu hộ tịch"), ("ownerOrgCode", "org"),
    ("stewardUser", "str", "le.thi.hoa"), ("onDependencyFailure", "E:OnDependencyFailure", "FAIL_CLOSED"))
page("DomainPage", "Domain")
obj("Asset", "Đối tượng đo (dq_asset).", ("assetCode!", "acode"), ("name!", "str", "Bản ghi vàng công dân"), ("domainCode!", "dcode"), ("assetType!", "E:AssetType", "MDM_DOMAIN"),
    ("status!", "E:AssetStatus", "ACTIVE"), ("statusReason", "str", "Chờ nâng cấp nguồn"), ("ownerOrgCode!", "org"), ("mdmDomainCode", "str", "CITIZEN"), ("rdmCatalogCode", "str", "DM_DAN_TOC"),
    ("connectionId", "uuid"), ("objectName", "str", "public.ho_so_cong_dan"), ("flowCode", "str", "luong-dang-ky-khai-sinh"), ("keyColumns", "[fpath]", ["citizenId"]),
    ("defaultScanMode", "E:ScanMode", "FULL"), ("sampleRatio", "num", 0.1), ("highestDataClass", "E:DataClass", "SENSITIVE"), ("description", "str", "Đo chất lượng bản ghi vàng công dân"),
    ("incrementalEnabled", "bool", False), ("lastScore", "score"), ("lastVerdict", "E:Verdict", "PASS"), *AUD)
obj("AssetCreate", "Đăng ký đối tượng đo (FR-08-002, 003, 004).", ("assetCode!", "acode"), ("name!", "str", "Bản ghi vàng công dân", {"maxLength": 255}), ("domainCode!", "dcode"),
    ("assetType!", "E:AssetType", "MDM_DOMAIN"), ("ownerOrgCode", "org"), ("mdmDomainCode", "str", "CITIZEN"), ("rdmCatalogCode", "str", "DM_DAN_TOC"), ("connectionId", "uuid"),
    ("objectName", "str", "public.ho_so_cong_dan"), ("flowCode", "str", "luong-dang-ky-khai-sinh"), ("keyColumns", "[fpath]", ["citizenId"]), ("defaultScanMode", "E:ScanMode", "FULL"),
    ("sampleRatio", "num", 0.1, {"minimum": 0.0001, "maximum": 1}), ("description", "str", "Đo chất lượng bản ghi vàng công dân", {"maxLength": 2000}))
obj("AssetUpdate", "Sửa đối tượng đo; gửi các trường cần đổi.", ("name", "str", "Bản ghi vàng công dân"), ("ownerOrgCode", "org"), ("keyColumns", "[fpath]", ["citizenId"]),
    ("defaultScanMode", "E:ScanMode", "SAMPLE"), ("sampleRatio", "num", 0.1), ("incrementalEnabled", "bool", True), ("description", "str", "Cập nhật mô tả"))
page("AssetPage", "Asset")
obj("AssetField", "Trường của đối tượng đo, CDE (dq_asset_field).", ("fieldName!", "fpath"), ("label", "str", "Số định danh công dân"), ("fieldType!", "E:FieldType", "STRING"),
    ("cde!", "bool", True), ("dataClass!", "E:DataClass", "SENSITIVE"), ("classificationStatus!", "E:ClassificationStatus", "CONFIRMED"), ("valueMode!", "E:ValueMode", "HASH_ONLY"),
    ("rdmCatalogCode", "str", "DM_DAN_TOC"), ("sortOrder", "int", 1), *AUD)
obj("AssetFieldPut", "Khai báo trường, CDE (FR-08-005). Phân loại lấy từ PH-09, `valueMode` không lỏng hơn phân loại (ERR-08-003).", ("label", "str", "Số định danh công dân"),
    ("fieldType!", "E:FieldType", "STRING"), ("cde!", "bool", True), ("valueMode", "E:ValueMode", "HASH_ONLY"), ("rdmCatalogCode", "str", "DM_DAN_TOC"), ("sortOrder", "int", 1))
page("AssetFieldPage", "AssetField")
obj("ClassificationSyncResult", "Kết quả đồng bộ phân loại (FR-08-005).", ("assetCode!", "acode"), ("updated!", "int", 12), ("unconfirmed!", "[fpath]", ["permanentAddress"]))
obj("MdmDomainSource", "Domain PH-06 có khung nhìn hợp đồng.", ("mdmDomainCode!", "str", "CITIZEN"), ("name!", "str", "Công dân"), ("status!", "str", "ACTIVE"),
    ("hasContractView!", "bool", True), ("attributeCount", "int", 14))
page("MdmDomainSourcePage", "MdmDomainSource")
obj("RdmCatalogSource", "Danh mục PH-07 đã phát hành.", ("rdmCatalogCode!", "str", "DM_DAN_TOC"), ("name!", "str", "Danh mục dân tộc"), ("publishedVersion", "int", 3), ("itemCount", "int", 54))
page("RdmCatalogSourcePage", "RdmCatalogSource")
obj("DiscoverRequest", "Khám phá bảng của kết nối chỉ đọc (FR-08-004).", ("schemaName", "str", "public"), ("namePattern", "str", "ho_so_%"))
obj("DiscoveredObject", "Bảng hoặc khung nhìn tìm thấy.", ("objectName!", "str", "public.ho_so_cong_dan"), ("objectType!", "E:ObjectType", "TABLE"), ("columnCount", "int", 18), ("estimatedRows", "int", 1200000))
obj("DiscoverResult", "Kết quả khám phá.", ("connectionCode!", "ccode"), ("objects!", "[$DiscoveredObject]"))

# --- hồ sơ dữ liệu
obj("ProfileRunCreate", "Chạy hồ sơ dữ liệu (FR-08-008).", ("scanMode", "E:ProfileMode", "SAMPLE"), ("sampleRows", "int", 100000, {"minimum": 100, "maximum": 1000000}))
obj("ProfileRun", "Lần hồ sơ (dq_profile_run).", ("runId!", "uuid"), ("assetCode!", "acode"), ("status!", "E:ProfileStatus", "SUCCEEDED"), ("scanMode", "E:ProfileMode", "SAMPLE"),
    ("sampleRows", "int", 100000), ("rowCount", "int", 1200000), ("requestedBy", "str", "nguyen.thi.lan"), ("startedAt", "ts"), ("finishedAt", "ts"), ("sourceSnapshotAt", "ts"),
    ("errorCode", "str", "ERR-08-111"), ("errorMessage", "str", "Hết thời gian truy vấn nguồn"), *AUD)
page("ProfileRunPage", "ProfileRun")
obj("ProfileColumn", "Thống kê cột (dq_profile_column); giá trị phổ biến chỉ có khi trường không Nhạy cảm.", ("fieldName!", "fpath"), ("inferredType", "E:FieldType", "STRING"),
    ("sensitive!", "bool", False), ("rowCount!", "int", 100000), ("nullCount!", "int", 120), ("emptyCount", "int", 30), ("distinctEstimate", "int", 99800), ("minMasked", "str", "A"),
    ("maxMasked", "str", "Z"), ("quantiles", "obj", {"p50": 12, "p95": 40}), ("topValues", "[obj]", [{"value": "Kinh", "count": 81000}]), ("patternStats", "obj", {"^[0-9]{12}$": 0.998}))
page("ProfileColumnPage", "ProfileColumn")
obj("SuggestRulesRequest", "Gợi ý quy tắc (FR-08-010).", ("fieldNames", "[fpath]", ["citizenId"]), ("dimensions", "[E:Dimension]", ["COMPLETENESS"]))
obj("RuleSuggestion", "Quy tắc gợi ý.", ("ruleCode!", "rcode"), ("dimension!", "E:Dimension", "COMPLETENESS"), ("operator!", "E:Operator", "NOT_NULL"), ("severity!", "E:Severity", "MAJOR"),
    ("fieldName!", "fpath"), ("params", "obj", {}), ("rationale", "str", "Tỷ lệ rỗng 0,1 phần trăm ở lần hồ sơ gần nhất"))
obj("SuggestRulesResult", "Danh sách gợi ý.", ("suggestions!", "[$RuleSuggestion]"))
obj("ProfileColumnMetric", "Chỉ số cột do PH-05 gửi (FR-08-011).", ("fieldName!", "fpath"), ("nullCount", "int", 12), ("distinctEstimate", "int", 9900), ("minMasked", "str", "A"), ("maxMasked", "str", "Z"))
obj("ProfileMetricsIn", "Lô chỉ số hồ sơ từ PH-05, API nội bộ.", ("connectionCode!", "ccode"), ("objectName!", "str", "public.ho_so_cong_dan"), ("collectedAt!", "ts"),
    ("rowCount!", "int", 1200000), ("columns!", "[$ProfileColumnMetric]"))
obj("ProfileMetricsResult", "Đã nhận lô chỉ số.", ("accepted!", "int", 18), ("profileRunId", "uuid"))

# --- bộ quy tắc, quy tắc
obj("Rule", "Quy tắc (dq_rule).", ("ruleCode!", "rcode"), ("name!", "str", "Số định danh đủ 12 chữ số"), ("description", "str", "Kiểm số định danh công dân"), ("dimension!", "E:Dimension", "VALIDITY"),
    ("operator!", "E:Operator", "REGEX"), ("severity!", "E:Severity", "CRITICAL"), ("execMode!", "E:ExecMode", "BOTH"), ("inlineMode", "E:InlineMode", "STRICT"), ("fieldName", "fpath"),
    ("params", "obj", {"pattern": "^[0-9]{12}$"}), ("expression", "str", "record.citizenId.size() == 12"), ("message", "str", "Số định danh không đủ 12 chữ số", {"maxLength": 500}),
    ("weight", "num", 1.0), ("templateCode", "str", "CCCD_12"), ("source", "E:RuleSource", "TEMPLATE"), ("enabled!", "bool", True), *AUD)
obj("RuleUpsert", "Tạo hoặc sửa quy tắc (FR-08-013, 014). Toán tử phải thuộc chiều (ERR-08-015); tham số đúng kiểu (ERR-08-016).", ("ruleCode!", "rcode"),
    ("name!", "str", "Số định danh đủ 12 chữ số", {"maxLength": 255}), ("description", "str", "Kiểm số định danh công dân"), ("dimension!", "E:Dimension", "VALIDITY"),
    ("operator!", "E:Operator", "REGEX"), ("severity!", "E:Severity", "CRITICAL"), ("execMode!", "E:ExecMode", "BOTH"), ("inlineMode", "E:InlineMode", "STRICT"), ("fieldName", "fpath"),
    ("params", "obj", {"pattern": "^[0-9]{12}$"}), ("expression", "str", "record.citizenId.size() == 12"), ("message", "str", "Số định danh không đủ 12 chữ số", {"maxLength": 500}),
    ("weight", "num", 1.0), ("templateCode", "str", "CCCD_12"), ("source", "E:RuleSource", "TEMPLATE"), ("enabled", "bool", True))
obj("RuleSet", "Bộ quy tắc (dq_rule_set).", ("ruleSetCode!", "rscode"), ("name!", "str", "Bộ quy tắc công dân"), ("assetCode!", "acode"), ("description", "str", "Bộ quy tắc cho bản ghi vàng công dân"),
    ("currentVersionNo", "int", 4), ("activeVersionNo", "int", 3), *AUD)
obj("RuleSetCreate", "Tạo bộ quy tắc kèm phiên bản nháp 1 (FR-08-012).", ("ruleSetCode!", "rscode"), ("name!", "str", "Bộ quy tắc công dân", {"maxLength": 255}), ("assetCode!", "acode"),
    ("description", "str", "Bộ quy tắc cho bản ghi vàng công dân", {"maxLength": 2000}))
page("RuleSetPage", "RuleSet")
obj("RuleSetVersion", "Phiên bản bộ quy tắc (dq_rule_set_version).", ("ruleSetCode!", "rscode"), ("versionNo!", "int", 4), ("status!", "E:VersionStatus", "DRAFT"),
    ("weightConfigId", "uuid"), ("contentHash", "hex"), ("ruleCount", "int", 18), ("changeNote", "str", "Thêm quy tắc đối chiếu danh mục dân tộc"), ("submittedBy", "str", "nguyen.thi.lan"),
    ("submittedAt", "ts"), ("decision", "E:VersionDecision", "APPROVE"), ("decidedBy", "str", "pham.minh.duc"), ("decidedAt", "ts"), ("decisionComment", "str", "Đồng ý theo biên bản họp"),
    ("activatedAt", "ts"), ("supersededAt", "ts"), ("rules", "[$Rule]"), *AUD)
page("RuleSetVersionPage", "RuleSetVersion")
obj("VersionCreate", "Tạo phiên bản nháp từ phiên bản trước (FR-08-012).", ("basedOnVersionNo", "int", 3), ("changeNote", "str", "Thêm quy tắc đối chiếu danh mục dân tộc", {"maxLength": 2000}))
obj("ActivateRequest", "Kích hoạt sớm phiên bản `APPROVED` (FR-08-018).", ("comment", "str", "Kích hoạt trước kỳ đo tháng 12.", {"maxLength": 2000}))
obj("ExpressionValidateRequest", "Kiểm biểu thức (FR-08-014).", ("assetCode!", "acode"), ("operator!", "E:Operator", "CEL_EXPRESSION"), ("expression!", "str", "record.citizenId.size() == 12", {"maxLength": 4000}))
obj("ExpressionIssue", "Lỗi biểu thức theo vị trí.", ("line!", "int", 1), ("column!", "int", 12), ("message!", "str", "Trường không tồn tại."))
obj("ExpressionValidateResult", "Kết quả kiểm biểu thức.", ("valid!", "bool", True), ("costEstimate", "int", 12), ("referencedFields", "[fpath]", ["citizenId"]), ("issues", "[$ExpressionIssue]"))
obj("RuleTemplate", "Quy tắc mẫu (dq_rule_template); tenant `COMMON` dùng chung.", ("templateCode!", "str", "CCCD_12"), ("name!", "str", "Số định danh công dân 12 chữ số"), ("dimension!", "E:Dimension", "VALIDITY"),
    ("operator!", "E:Operator", "REGEX"), ("defaultSeverity!", "E:Severity", "CRITICAL"), ("params", "obj", {"pattern": "^[0-9]{12}$"}), ("expressionTemplate", "str", "record.{field}.size() == 12"),
    ("description", "str", "Dùng cho trường số định danh"), ("status!", "E:TemplateStatus", "ACTIVE"), ("common", "bool", True), *AUD)
obj("RuleTemplateCreate", "Tạo quy tắc mẫu (FR-08-015).", ("templateCode!", "str", "MST_10"), ("name!", "str", "Mã số thuế 10 chữ số", {"maxLength": 255}), ("dimension!", "E:Dimension", "VALIDITY"),
    ("operator!", "E:Operator", "CHECKSUM"), ("defaultSeverity!", "E:Severity", "MAJOR"), ("params", "obj", {"algorithm": "MST_10"}), ("expressionTemplate", "str"), ("description", "str", "Kiểm chữ số kiểm của mã số thuế"))
page("RuleTemplatePage", "RuleTemplate")
obj("RuleListItem", "Dòng danh sách quy tắc toàn tenant (FR-08-022).", ("ruleCode!", "rcode"), ("ruleSetCode!", "rscode"), ("versionNo!", "int", 4), ("versionStatus!", "E:VersionStatus", "ACTIVE"),
    ("assetCode!", "acode"), ("name!", "str", "Số định danh đủ 12 chữ số"), ("dimension!", "E:Dimension", "VALIDITY"), ("operator!", "E:Operator", "REGEX"), ("severity!", "E:Severity", "CRITICAL"), ("enabled!", "bool", True))
page("RuleListItemPage", "RuleListItem")
obj("DryRunRequest", "Chạy thử trên mẫu (FR-08-016).", ("sampleSize", "int", 1000, {"minimum": 100, "maximum": 50000}), ("ruleCodes", "[rcode]", ["CD-ACC-001"]))
obj("DryRunExample", "Ví dụ lỗi đã che.", ("recordKeyMasked", "str", "*******12345"), ("fieldName", "fpath"), ("maskedValue", "str", "****"))
obj("DryRunRuleResult", "Kết quả chạy thử của một quy tắc.", ("ruleCode!", "rcode"), ("status!", "E:RuleResultStatus", "FAILED"), ("rowsEvaluated!", "int", 1000), ("rowsFailed!", "int", 12),
    ("passRate", "num", 0.988), ("examples", "[$DryRunExample]"))
obj("DryRunResult", "Kết quả chạy thử.", ("sampleSize!", "int", 1000), ("durationMs!", "int", 840), ("estimatedScore", "score"), ("results!", "[$DryRunRuleResult]"))
obj("RuleChange", "Một thay đổi trường của quy tắc.", ("field!", "str", "severity"), ("from", "str", "MAJOR"), ("to", "str", "CRITICAL"))
obj("RuleDiffItem", "Quy tắc đổi giữa hai phiên bản.", ("ruleCode!", "rcode"), ("changes!", "[$RuleChange]"))
obj("VersionDiff", "So sánh hai phiên bản (FR-08-019).", ("ruleSetCode!", "rscode"), ("fromVersionNo!", "int", 3), ("toVersionNo!", "int", 4), ("added!", "[rcode]", ["CD-VAL-010"]),
    ("removed!", "[rcode]", []), ("changed!", "[$RuleDiffItem]"))
obj("RuleSetCopyRequest", "Sao chép sang bộ mới (FR-08-020).", ("newRuleSetCode!", "rscode"), ("name!", "str", "Bộ quy tắc công dân bản sao"), ("targetAssetCode!", "acode"), ("fieldMapping", "obj", {"citizenId": "personalId"}))
obj("RuleSetExport", "Nội dung xuất.", ("format!", "E:RuleFileFormat", "YAML"), ("content!", "str", "ruleSet: bq-cong-dan\nrules: []\n"), ("contentSha256", "hex"))
obj("RuleSetImportRequest", "Nhập bộ quy tắc từ nội dung tệp (FR-08-020); tối đa 2 MB.", ("format!", "E:RuleFileFormat", "YAML"), ("content!", "str", "ruleSet: bq-cong-dan\nrules: []\n", {"maxLength": 2097152}),
    ("ruleSetCode!", "rscode"), ("targetAssetCode!", "acode"))
obj("WeightSet", "Sáu trọng số chiều, tổng bằng 1 (dung sai 0,001).", ("completeness!", "w", 0.2), ("accuracy!", "w", 0.2), ("consistency!", "w", 0.15), ("timeliness!", "w", 0.1), ("uniqueness!", "w", 0.15), ("validity!", "w", 0.2))
obj("WeightConfig", "Cấu hình trọng số và ngưỡng (dq_weight_config).", ("configCode!", "str", "tm-mac-dinh"), ("versionNo!", "int", 2), ("scope!", "E:WeightScope", "TENANT"),
    ("domainCode", "dcode"), ("assetCode", "acode"), ("status!", "E:WeightStatus", "ACTIVE"), ("weights!", "$WeightSet"), ("passMin!", "num", 90), ("warnMin!", "num", 75),
    ("submittedBy", "str", "nguyen.thi.lan"), ("submittedAt", "ts"), ("decidedBy", "str", "pham.minh.duc"), ("decidedAt", "ts"), ("decisionComment", "str", "Đồng ý"), ("activatedAt", "ts"),
    ("supersededAt", "ts"), ("changeNote", "str", "Tăng trọng số chiều hợp lệ"), *AUD)
page("WeightConfigPage", "WeightConfig")
obj("WeightConfigCreate", "Tạo cấu hình nháp (FR-08-021); ERR-08-023 khi tổng khác 1, ERR-08-024 khi ngưỡng sai.", ("configCode!", "str", "tm-mac-dinh"), ("scope!", "E:WeightScope", "TENANT"),
    ("domainCode", "dcode"), ("assetCode", "acode"), ("weights!", "$WeightSet"), ("passMin!", "num", 90, {"minimum": 0, "maximum": 100}), ("warnMin!", "num", 75, {"minimum": 0, "maximum": 100}),
    ("changeNote", "str", "Tăng trọng số chiều hợp lệ", {"maxLength": 2000}))
obj("WeightConfigUpdate", "Sửa cấu hình nháp.", ("weights", "$WeightSet"), ("passMin", "num", 90), ("warnMin", "num", 75), ("changeNote", "str", "Điều chỉnh ngưỡng"))

# --- lịch, lần đo
obj("Schedule", "Lịch đo (dq_schedule).", ("scheduleId!", "uuid"), ("scheduleCode!", "rscode", "lich-cong-dan-thang"), ("domainCode", "dcode"), ("assetCode!", "acode"), ("cron!", "str", "0 0 2 1 * ?"),
    ("timezone!", "str", "Asia/Ho_Chi_Minh"), ("scanMode!", "E:ScanMode", "FULL"), ("enabled!", "bool", True), ("status!", "E:ScheduleStatus", "ACTIVE"), ("nextRunAt", "ts"), ("lastRunAt", "ts"),
    ("lastJobId", "uuid"), *AUD)
page("SchedulePage", "Schedule")
obj("ScheduleCreate", "Tạo lịch (FR-08-023); ERR-08-029 khi cron sai hoặc quá dày, ERR-08-049 khi trùng.", ("scheduleCode!", "rscode", "lich-cong-dan-thang"), ("assetCode!", "acode"),
    ("cron!", "str", "0 0 2 1 * ?"), ("timezone", "str", "Asia/Ho_Chi_Minh"), ("scanMode!", "E:ScanMode", "FULL"))
obj("ScheduleUpdate", "Sửa lịch.", ("cron", "str", "0 0 2 1 * ?"), ("timezone", "str", "Asia/Ho_Chi_Minh"), ("scanMode", "E:ScanMode", "FULL"))
obj("ScanCreate", "Chạy đo theo yêu cầu hoặc năm (FR-08-024, 054).", ("assetCode!", "acode"), ("scanMode!", "E:ScanMode", "FULL"), ("scanTrigger", "E:ScanTrigger", "MANUAL"),
    ("sampleSize", "int", 10000, {"minimum": 100, "maximum": 1000000}), ("periodCode", "period"), ("note", "str", "Đo trước kỳ báo cáo", {"maxLength": 500}))
obj("ScanJob", "Lần đo (dq_scan_job).", ("scanId!", "uuid"), ("assetCode!", "acode"), ("ruleSetVersionId", "uuid"), ("weightConfigId", "uuid"), ("scheduleId", "uuid"), ("scanTrigger!", "E:ScanTrigger", "MANUAL"),
    ("scanMode!", "E:ScanMode", "FULL"), ("status!", "E:ScanStatus", "RUNNING"), ("periodCode", "period"), ("requestedBy", "str", "nguyen.thi.lan"), ("verifyIssueCode", "icode"),
    ("sourceEventId", "uuid"), ("rerunOf", "uuid"), ("sourceSnapshotAt", "ts"), ("startedAt", "ts"), ("finishedAt", "ts"), ("taskTotal", "int", 6), ("taskDone", "int", 2),
    ("rowsScanned", "int", 400000), ("rowsFailed", "int", 3100), ("skippedRules", "int", 0), ("sampleSize", "int", 10000), ("sampleSeed", "int", 20261126),
    ("flags", "[E:SnapshotFlag]", []), ("errorCode", "str", "ERR-08-105"), ("errorMessage", "str", "Không kết nối được nguồn"), ("cancelReason", "str", "Hủy theo yêu cầu của chủ quản dữ liệu"), *AUD)
page("ScanJobPage", "ScanJob")
obj("RerunRequest", "Chạy lại lần đo (FR-08-030).", ("reason", "str", "Chạy lại sau khi nguồn khôi phục.", {"maxLength": 500}))
obj("RuleResult", "Kết quả quy tắc của lần đo (dq_rule_result).", ("ruleCode!", "rcode"), ("dimension!", "E:Dimension", "VALIDITY"), ("severity!", "E:Severity", "CRITICAL"),
    ("status!", "E:RuleResultStatus", "FAILED"), ("rowsEvaluated", "int", 400000), ("rowsFailed", "int", 3100), ("passRate", "num", 0.992), ("skipReason", "str", "RDM_UNAVAILABLE"),
    ("errorCode", "str", "ERR-08-107"), ("durationMs", "int", 1840), ("executedAt", "ts"))
page("RuleResultPage", "RuleResult")
obj("DimensionScore", "Điểm một chiều (dq_score_dimension).", ("dimension!", "E:Dimension", "COMPLETENESS"), ("status!", "E:DimensionStatus", "MEASURED"), ("score", "score"), ("weight!", "w", 0.2),
    ("rulesTotal!", "int", 5), ("rulesPassed!", "int", 4), ("rulesFailed!", "int", 1), ("rulesSkipped!", "int", 0), ("rowsFailed", "int", 3100))
obj("ScoreSnapshot", "Ảnh chụp điểm (dq_score_snapshot).", ("snapshotId!", "uuid"), ("scanId!", "uuid"), ("assetCode!", "acode"), ("domainCode", "dcode"), ("ownerOrgCode", "org"),
    ("periodCode", "period"), ("scanMode!", "E:ScanMode", "FULL"), ("score!", "score"), ("verdict!", "E:Verdict", "PASS"), ("trend!", "E:Trend", "IMPROVED"), ("flags", "[E:SnapshotFlag]", []),
    ("prevScore", "score", 90.1), ("delta", "num", 2.4), ("weightConfigId", "uuid"), ("ruleSetVersionId", "uuid"), ("rowCount", "int", 1200000), ("official", "bool", False), ("measuredAt", "ts"),
    ("dimensions!", "[$DimensionScore]"))
obj("ScorePoint", "Một điểm của chuỗi lịch sử.", ("snapshotId!", "uuid"), ("scanId!", "uuid"), ("periodCode", "period"), ("measuredAt!", "ts"), ("score!", "score"), ("verdict!", "E:Verdict", "PASS"),
    ("trend", "E:Trend", "STABLE"), ("flags", "[E:SnapshotFlag]", []), ("official", "bool", False))
page("ScorePointPage", "ScorePoint")
obj("ScanTask", "Tác vụ phân mảnh (dq_scan_task).", ("taskId!", "uuid"), ("shardNo!", "int", 1), ("shardCount!", "int", 6), ("status!", "E:TaskStatus", "SUCCEEDED"), ("keyFrom", "str", "000000000001"),
    ("keyTo", "str", "000000200000"), ("attempt", "int", 1), ("workerId", "str", "dq-worker-0"), ("rowsScanned", "int", 200000), ("rowsFailed", "int", 1500), ("startedAt", "ts"), ("finishedAt", "ts"), ("errorCode", "str", "ERR-08-105"))
page("ScanTaskPage", "ScanTask")

# --- kiểm tra trực tuyến
obj("CheckRequest", "Kiểm tra trực tuyến một bản ghi (FR-08-032); bản ghi ≤ 64 KB.", ("assetCode!", "acode"), ("record!", "obj", {"citizenId": "0791234567", "fullName": "Nguyễn Văn A", "ethnicCode": "01"}),
    ("mode", "E:InlineMode", "STRICT"), ("dimensions", "[E:Dimension]", ["VALIDITY", "COMPLETENESS"]), ("correlationId", "str", "msg-20261126-0001", {"maxLength": 64}), ("caller!", "str", "luong-dang-ky-khai-sinh"))
obj("Violation", "Vi phạm; không chứa giá trị của bản ghi.", ("ruleCode!", "rcode"), ("dimension!", "E:Dimension", "VALIDITY"), ("severity!", "E:Severity", "CRITICAL"), ("fieldPath!", "fpath"),
    ("message!", "str", "Số định danh không đủ 12 chữ số"))
obj("CheckResult", "Kết luận kiểm tra.", ("verdict!", "E:Verdict", "FAIL"), ("degraded!", "bool", False), ("violations!", "[$Violation]"), ("evaluatedRules!", "int", 14), ("durationMs!", "int", 12),
    ("ruleSetVersion!", "int", 4), ("correlationId", "str", "msg-20261126-0001"))
obj("CheckBatchItem", "Một bản ghi trong lô.", ("correlationId!", "str", "msg-20261126-0001"), ("record!", "obj", {"citizenId": "079123456789"}))
obj("CheckBatchRequest", "Kiểm tra lô tối đa 100 bản ghi (FR-08-032).", ("assetCode!", "acode"), ("records!", "[$CheckBatchItem]", None, {"minItems": 1, "maxItems": 100}), ("mode", "E:InlineMode", "ADVISORY"),
    ("dimensions", "[E:Dimension]", ["VALIDITY"]), ("caller!", "str", "PH-06"))
obj("CheckBatchResultItem", "Kết luận của một bản ghi trong lô.", ("correlationId!", "str", "msg-20261126-0001"), ("verdict!", "E:Verdict", "PASS"), ("violations!", "[$Violation]", []))
obj("CheckBatchResult", "Kết quả kiểm tra lô.", ("results!", "[$CheckBatchResultItem]"), ("degraded!", "bool", False), ("durationMs!", "int", 31), ("ruleSetVersion!", "int", 4))
obj("InlineSeriesPoint", "Một điểm của chuỗi thống kê (dq_inline_stat).", ("bucketAt!", "ts"), ("assetCode!", "acode"), ("caller", "str", "luong-dang-ky-khai-sinh"), ("checkCount!", "int", 1200),
    ("passCount!", "int", 1130), ("warnCount", "int", 40), ("failCount!", "int", 30), ("blockedCount", "int", 30), ("errorCount", "int", 0), ("failOpenCount", "int", 0), ("failClosedCount", "int", 0),
    ("p50Ms", "int", 6), ("p95Ms", "int", 18), ("maxMs", "int", 41))
obj("TopRule", "Quy tắc vi phạm nhiều nhất.", ("ruleCode!", "rcode"), ("failCount!", "int", 21))
obj("InlineStats", "Thống kê kiểm tra trực tuyến (FR-08-034).", ("granularity!", "E:Granularity", "MINUTE"), ("series!", "[$InlineSeriesPoint]"), ("topRules!", "[$TopRule]"), ("p95Ms", "int", 18))
obj("InlineConfig", "Cấu hình kiểm tra trực tuyến của đối tượng (FR-08-032, 035).", ("assetCode!", "acode"), ("inlineEnabled!", "bool", True), ("inlineMode!", "E:InlineMode", "STRICT"),
    ("onDependencyFailure!", "E:OnDependencyFailure", "FAIL_OPEN"), ("timeoutMs!", "int", 40, {"minimum": 10, "maximum": 50}), ("gateEnabled", "bool", False), ("version!", "int", 2))
obj("InlineConfigPut", "Đặt cấu hình trực tuyến.", ("inlineEnabled!", "bool", True), ("inlineMode!", "E:InlineMode", "STRICT"), ("onDependencyFailure!", "E:OnDependencyFailure", "FAIL_OPEN"),
    ("timeoutMs", "int", 40, {"minimum": 10, "maximum": 50}), ("gateEnabled", "bool", False))

# --- bản ghi lỗi
obj("Finding", "Bản ghi lỗi (dq_finding); giá trị trường Nhạy cảm chỉ có băm.", ("findingId!", "uuid"), ("assetCode!", "acode"), ("ruleCode!", "rcode"), ("dimension!", "E:Dimension", "VALIDITY"),
    ("severity!", "E:Severity", "CRITICAL"), ("fingerprint!", "hex"), ("recordKeyMasked", "str", "*******12345"), ("fieldName", "fpath"), ("dataClass!", "E:DataClass", "SENSITIVE"),
    ("valueMode!", "E:ValueMode", "HASH_ONLY"), ("maskedValue", "str", "****"), ("expectedHint", "str", "12 chữ số"), ("status!", "E:FindingStatus", "OPEN"), ("ownerOrgCode", "org"),
    ("firstSeenAt!", "ts"), ("lastSeenAt!", "ts"), ("firstScanId", "uuid"), ("lastScanId", "uuid"), ("seenCount!", "int", 3), ("resolvedAt", "ts"), ("resolutionReason", "E:ResolutionReason", "CLEARED"),
    ("issueCode", "icode"), ("waiverId", "uuid"))
page("FindingPage", "Finding")
obj("FindingHistoryItem", "Một lần thấy lỗi.", ("scanId!", "uuid"), ("seenAt!", "ts"), ("status!", "E:FindingStatus", "OPEN"))
obj("GoldenRecordRef", "Tham chiếu bản ghi vàng ở PH-06, mở cần `PERM-06-read`.", ("domainCode!", "str", "CITIZEN"), ("goldenId!", "uuid"))
obj("FindingDetail", "Chi tiết bản ghi lỗi (FR-08-038).", ("finding!", "$Finding"), ("history!", "[$FindingHistoryItem]"), ("goldenRecord", "$GoldenRecordRef"))
obj("FindingSearchRequest", "Tìm lỗi theo khóa bản ghi; khóa định danh cá nhân gửi trong thân để không vào log đường dẫn (FR-08-037).", ("assetCode!", "acode"),
    ("recordKey!", "str", "079123456789", {"maxLength": 255}))
obj("FindingGroup", "Nhóm lỗi theo đối tượng, quy tắc, chủ quản (FR-08-037, 041).", ("groupKey!", "str", "mdm-cong-dan|CD-ACC-001|so-tu-phap"), ("assetCode!", "acode"), ("ruleCode!", "rcode"),
    ("dimension!", "E:Dimension", "VALIDITY"), ("severity!", "E:Severity", "CRITICAL"), ("ownerOrgCode", "org"), ("findingCount!", "int", 312), ("openIssueCode", "icode"), ("firstSeenAt", "ts"), ("lastSeenAt", "ts"))
page("FindingGroupPage", "FindingGroup")
obj("FindingExportCreate", "Đề nghị xuất lỗi (FR-08-039).", ("assetCode!", "acode"), ("filter", "obj", {"severity": "CRITICAL", "status": "OPEN"}), ("format!", "E:ExportFormat", "XLSX"),
    ("reason", "str", "Gửi danh sách lỗi cho chủ quản xử lý.", {"maxLength": 500}))
obj("ExportRequest", "Yêu cầu xuất (dq_export_request).", ("exportId!", "uuid"), ("kind", "E:ExportKind", "FINDINGS"), ("assetCode", "acode"), ("reportCode", "rpcode"), ("filter", "obj", {"severity": "CRITICAL"}),
    ("format!", "E:ExportFormat", "XLSX"), ("status!", "E:ExportStatus", "READY"), ("containsRestricted!", "bool", False), ("requestedBy", "str", "nguyen.thi.lan"), ("decidedBy", "str", "pham.minh.duc"),
    ("decidedAt", "ts"), ("decisionComment", "str", "Đồng ý xuất"), ("rowCount", "int", 312), ("downloadUrl", "str", "https://api.t68.datahub.example.vn/api/dq/v1/exports/0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01/file?sig=abc"),
    ("expiresAt", "ts"), ("downloadCount", "int", 0), ("errorCode", "str", "ERR-08-112"), *AUD)
obj("ExportDecision", "Quyết định chấp thuận xuất; DO chấp thuận khi có trường Nhạy cảm.", ("decision!", "E:ExportDecisionValue", "APPROVE"), ("comment", "str", "Đồng ý, tệp chỉ gửi cho đầu mối của sở.", {"maxLength": 2000}))
obj("Waiver", "Ngoại lệ chấp nhận (dq_waiver).", ("waiverId!", "uuid"), ("assetCode!", "acode"), ("ruleCode", "rcode"), ("scope!", "E:WaiverScope", "FINDINGS"), ("fingerprint", "hex"),
    ("status!", "E:WaiverStatus", "PENDING_APPROVAL"), ("reason!", "str", "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.", R20), ("requestedBy", "str", "nguyen.thi.lan"),
    ("decidedBy", "str", "pham.minh.duc"), ("decidedAt", "ts"), ("decisionComment", "str", "Đồng ý có thời hạn"), ("validFrom", "date", "2026-11-26"), ("validTo", "date", "2027-05-25"),
    ("revokedBy", "str"), ("revokedAt", "ts"), ("revokeReason", "str"), ("expiredAt", "ts"), *AUD)
page("WaiverPage", "Waiver")
obj("WaiverCreate", "Đề nghị ngoại lệ (FR-08-040); hạn tối đa theo `08.waiver.max-days` (ERR-08-033).", ("assetCode!", "acode"), ("ruleCode", "rcode"), ("scope!", "E:WaiverScope", "FINDINGS"),
    ("findingIds", "[uuid]"), ("filter", "obj", {"ownerOrgCode": "so-tu-phap"}), ("reason!", "str", "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.", R20), ("validFrom!", "date", "2026-11-26"),
    ("validTo!", "date", "2027-05-25"))

# --- phiếu khắc phục
obj("Issue", "Phiếu khắc phục (dq_issue).", ("issueCode!", "icode"), ("assetCode!", "acode"), ("ruleCode", "rcode"), ("groupKey", "str", "mdm-cong-dan|CD-ACC-001|so-tu-phap"), ("title!", "str", "Số định danh sai mẫu ở hộ tịch"),
    ("description", "str", "312 bản ghi có số định danh không đủ 12 chữ số"), ("severity!", "E:Severity", "CRITICAL"), ("findingCount!", "int", 312), ("ownerOrgCode!", "org"), ("assignee", "str", "le.thi.hoa"),
    ("status!", "E:IssueStatus", "ASSIGNED"), ("slaDays", "int", 5), ("slaDueAt", "ts"), ("overdue", "bool", False), ("escalationLevel", "int", 0), ("escalatedAt", "ts"), ("assignedAt", "ts"), ("fixedAt", "ts"),
    ("fixNote", "str", "Đã rà soát và sửa số định danh theo sổ hộ tịch"), ("verifiedAt", "ts"), ("verifyScanId", "uuid"), ("reopenCount", "int", 0), ("rejectType", "E:RejectType", "NOT_A_DEFECT"),
    ("rejectReason", "str"), ("stewardItemRef", "uuid"), ("forwardedToStewardAt", "ts"), ("cancelReason", "str"), *AUD)
page("IssuePage", "Issue")
obj("IssueCreate", "Mở phiếu từ nhóm lỗi (FR-08-041); ERR-08-034 khi lỗi đã thuộc phiếu mở khác.", ("assetCode!", "acode"), ("ruleCode!", "rcode"), ("findingIds", "[uuid]"), ("groupKey", "str", "mdm-cong-dan|CD-ACC-001|so-tu-phap"),
    ("title!", "str", "Số định danh sai mẫu ở hộ tịch", {"maxLength": 255}), ("description", "str", "312 bản ghi có số định danh không đủ 12 chữ số", {"maxLength": 4000}),
    ("severity!", "E:Severity", "CRITICAL"), ("ownerOrgCode!", "org"), ("slaDays", "int", 5, {"minimum": 1, "maximum": 90}))
obj("IssueAssign", "Phân công (FR-08-042).", ("ownerOrgCode", "org"), ("assignee", "str", "le.thi.hoa"), ("slaDays", "int", 5), ("comment", "str", "Đề nghị xử lý trong 5 ngày làm việc.", {"maxLength": 2000}))
obj("IssueActivityCreate", "Trao đổi trên phiếu (FR-08-043).", ("activityType!", "E:ActivityType", "COMMENT"), ("comment!", "str", "Đã đối chiếu với sổ gốc, đang sửa lô đầu.", {"maxLength": 4000}), ("attachmentRef", "str"))
obj("IssueActivity", "Hoạt động của phiếu (dq_issue_activity).", ("activityId!", "uuid"), ("activityType!", "E:ActivityType", "COMMENT"), ("actor!", "str", "le.thi.hoa"), ("fromStatus", "E:IssueStatus", "ASSIGNED"),
    ("toStatus", "E:IssueStatus", "IN_PROGRESS"), ("comment", "str", "Đã bắt đầu xử lý"), ("payload", "obj", {}), ("occurredAt!", "ts"))
page("IssueActivityPage", "IssueActivity")
obj("IssueMarkFixed", "Báo đã sửa; ≥ 20 ký tự (ERR-08-036).", ("fixNote!", "str", "Đã rà soát và sửa số định danh theo sổ hộ tịch, lô 312 bản ghi.", R20))
obj("IssueVerify", "Xác nhận: đo kiểm chứng hoặc xác nhận thủ công của DS (ERR-08-035 khi DO tự xác nhận).", ("mode!", "E:VerifyMode", "SCAN"), ("comment", "str", "Đo lại sau khi PH-06 nhận cập nhật.", {"maxLength": 2000}))
obj("IssueReject", "Từ chối phiếu.", ("rejectType!", "E:RejectType", "WRONG_OWNER"), ("reason!", "str", "Dữ liệu này do sở khác quản lý theo quyết định số 45.", R20))
obj("IssueTransfer", "Chuyển phiếu.", ("ownerOrgCode!", "org"), ("assignee", "str"), ("reason!", "str", "Chuyển sang sở chủ quản đúng theo quyết định số 45.", R20))
obj("IssueEscalate", "Leo thang thủ công.", ("reason!", "str", "Quá hạn 6 ngày làm việc, chưa có phản hồi.", R20), ("toLevel", "int", 1, {"minimum": 1, "maximum": 2}))
obj("IssueSendToSteward", "Chuyển lỗi bản ghi vàng (FR-08-046); ERR-08-051 khi lỗi không thuộc bản ghi vàng.", ("action", "E:StewardAction", "REVIEW_VALUE"), ("comment", "str", "Hai bản ghi vàng nghi trùng."))
obj("StewardTransfer", "Kết quả chuyển sang hàng đợi PH-06.", ("issueCode!", "icode"), ("stewardItemRef!", "uuid"), ("status!", "E:IssueStatus", "IN_PROGRESS"), ("forwardedAt", "ts"))

# --- cảnh báo
obj("Recipient", "Người nhận.", ("recipientType!", "E:RecipientType", "ROLE"), ("recipientRef!", "str", "DS"))
obj("AlertRule", "Quy tắc cảnh báo (dq_alert_rule).", ("alertRuleCode!", "rscode", "cb-diem-duoi-ngung"), ("name!", "str", "Điểm dưới ngưỡng cảnh báo"), ("domainCode", "dcode"), ("assetCode", "acode"),
    ("conditionType!", "E:AlertCondition", "SCORE_BELOW"), ("dimension", "E:Dimension", "VALIDITY"), ("threshold", "num", 75), ("severity!", "E:AlertSeverity", "HIGH"),
    ("channels!", "[E:SubscriptionChannel]", ["IN_APP"]), ("recipients!", "[$Recipient]"), ("cooldownMinutes", "int", 240), ("enabled!", "bool", True), *AUD)
page("AlertRulePage", "AlertRule")
obj("AlertRuleUpsert", "Tạo hoặc sửa quy tắc cảnh báo (FR-08-047).", ("alertRuleCode!", "rscode", "cb-diem-duoi-ngung"), ("name!", "str", "Điểm dưới ngưỡng cảnh báo", {"maxLength": 255}), ("domainCode", "dcode"),
    ("assetCode", "acode"), ("conditionType!", "E:AlertCondition", "SCORE_BELOW"), ("dimension", "E:Dimension", "VALIDITY"), ("threshold", "num", 75), ("severity!", "E:AlertSeverity", "HIGH"),
    ("channels!", "[E:SubscriptionChannel]", ["IN_APP"]), ("recipients!", "[$Recipient]"), ("cooldownMinutes", "int", 240), ("enabled", "bool", True))
obj("Alert", "Cảnh báo (dq_alert).", ("alertId!", "uuid"), ("alertRuleCode!", "rscode", "cb-diem-duoi-ngung"), ("assetCode", "acode"), ("scanId", "uuid"), ("snapshotId", "uuid"), ("severity!", "E:AlertSeverity", "HIGH"),
    ("status!", "E:AlertStatus", "FIRING"), ("dedupKey", "str", "cb-diem-duoi-ngung|mdm-cong-dan"), ("message!", "str", "Điểm chất lượng 71,2 thấp hơn ngưỡng cảnh báo 75."), ("firedAt!", "ts"), ("notifiedAt", "ts"),
    ("notificationRef", "str", "ntf-0193b1d4"), ("acknowledgedBy", "str"), ("acknowledgedAt", "ts"), ("silencedUntil", "ts"), ("silenceReason", "str"), ("resolvedAt", "ts"), *AUD)
page("AlertPage", "Alert")
obj("AlertSilence", "Tắt tiếng có thời hạn (FR-08-049).", ("silencedUntil!", "ts"), ("reason!", "str", "Đang bảo trì nguồn dữ liệu, tắt trong 24 giờ.", {"minLength": 5, "maxLength": 500}))

# --- bảng điều khiển, thẻ điểm
obj("DomainCard", "Thẻ miền trên bảng điều khiển.", ("domainCode!", "dcode"), ("name!", "str", "Hộ tịch"), ("score", "score"), ("verdict", "E:Verdict", "PASS"), ("trend", "E:Trend", "IMPROVED"),
    ("assetCount!", "int", 6), ("openFindings", "int", 4120))
obj("DimensionAverage", "Điểm trung bình một chiều.", ("dimension!", "E:Dimension", "VALIDITY"), ("score", "score"))
obj("TrendPoint", "Điểm theo kỳ.", ("periodCode!", "period"), ("score!", "score"))
obj("IssueSummary", "Tổng hợp phiếu.", ("open!", "int", 18), ("overdue!", "int", 3), ("bySeverity", "obj", {"CRITICAL": 2, "MAJOR": 9, "MINOR": 7}))
obj("Dashboard", "Bảng điều khiển tenant (FR-08-050).", ("periodCode", "period"), ("tenantScore", "score"), ("verdict", "E:Verdict", "PASS"), ("trend", "E:Trend", "IMPROVED"), ("flags", "[E:SnapshotFlag]", []),
    ("domains!", "[$DomainCard]"), ("dimensions!", "[$DimensionAverage]"), ("trendSeries!", "[$TrendPoint]"), ("issues!", "$IssueSummary"), ("firingAlerts", "int", 2), ("measuredAt", "ts"))
obj("Scorecard", "Thẻ điểm theo phạm vi (FR-08-051).", ("scope!", "E:ScorecardScope", "DOMAIN"), ("key!", "str", "HO_TICH"), ("name", "str", "Hộ tịch"), ("score", "score"), ("verdict", "E:Verdict", "PASS"),
    ("trend", "E:Trend", "IMPROVED"), ("delta", "num", 2.4), ("flags", "[E:SnapshotFlag]", []), ("periodCode", "period"), ("official", "bool", False), ("measuredAt", "ts"), ("dimensions", "[$DimensionScore]"))
page("ScorecardPage", "Scorecard")
obj("CdeScore", "Điểm của trường CDE.", ("fieldName!", "fpath"), ("score", "score"), ("failedRules", "int", 1))
obj("AssetScorecard", "Thẻ điểm một đối tượng đo.", ("assetCode!", "acode"), ("snapshot!", "$ScoreSnapshot"), ("openFindings!", "int", 312), ("openFindingsBySeverity", "obj", {"CRITICAL": 12, "MAJOR": 150, "MINOR": 150}),
    ("openIssues", "int", 2), ("cde", "[$CdeScore]"), ("history", "[$ScorePoint]"))
obj("KpiSnapshot", "Ảnh chụp KPI đã đẩy sang PH-16 (EVT-08-14).", ("snapshotId!", "uuid"), ("kind!", "E:KpiKind", "SCAN_SNAPSHOT"), ("periodCode", "period"), ("kpiSchemaVersion!", "int", 1), ("tenantScore", "score"),
    ("domainScores", "[$DomainCard]"), ("issues", "$IssueSummary"), ("official", "bool", False), ("publishedAt!", "ts"))
page("KpiSnapshotPage", "KpiSnapshot")

# --- báo cáo
obj("Report", "Báo cáo chất lượng (dq_report).", ("reportCode!", "rpcode"), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode!", "period"), ("title!", "str", "Báo cáo chất lượng dữ liệu tháng 11/2026"),
    ("status!", "E:ReportStatus", "DRAFT"), ("scope", "obj", {"domainCodes": ["HO_TICH"]}), ("summary", "obj", {"tenantScore": 91.2, "recommendations": ["Bổ sung số định danh cho hồ sơ trước 2015"]}),
    ("snapshotCount", "int", 6), ("incompleteSnapshotCount", "int", 0), ("generatedAt", "ts"), ("submittedBy", "str", "nguyen.thi.lan"), ("submittedAt", "ts"), ("reviewedBy", "str", "pham.minh.duc"),
    ("reviewedAt", "ts"), ("reviewComment", "str", "Đồng ý công bố"), ("publishedBy", "str"), ("publishedAt", "ts"), ("withdrawnReason", "str"), ("hasPdf", "bool", False), ("hasXlsx", "bool", False),
    ("contentSha256", "hex"), ("signed", "bool", False), ("signatureRef", "str"), *AUD)
page("ReportPage", "Report")
obj("ReportCreate", "Tạo báo cáo (FR-08-052, 054); báo cáo năm cần đo `FULL` đủ chiều (ERR-08-038).", ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode!", "period"), ("title", "str", "Báo cáo chất lượng dữ liệu tháng 11/2026"),
    ("scope", "obj", {"domainCodes": ["HO_TICH"]}), ("annualMethod", "E:AnnualMethod", "FULL_DECEMBER"))
obj("ReportUpdate", "Sửa báo cáo nháp; cần ít nhất một khuyến nghị trước khi gửi duyệt (ERR-08-039).", ("title", "str", "Báo cáo chất lượng dữ liệu tháng 11/2026"),
    ("summary", "obj", {"narrative": "Điểm toàn tỉnh tăng 2,4 điểm.", "recommendations": ["Bổ sung số định danh cho hồ sơ trước 2015"]}), ("scope", "obj", {"domainCodes": ["HO_TICH"]}))
obj("AnnualReadinessRequest", "Kiểm điều kiện báo cáo năm (FR-08-054).", ("year!", "int", 2026, {"minimum": 2025, "maximum": 2100}), ("annualMethod", "E:AnnualMethod", "FULL_DECEMBER"))
obj("ReadinessBlocker", "Đối tượng chưa đủ điều kiện.", ("assetCode!", "acode"), ("reason!", "str", "Thiếu lần đo toàn bộ trong kỳ"))
obj("AnnualReadinessResult", "Kết quả kiểm.", ("year!", "int", 2026), ("ready!", "bool", False), ("blockers!", "[$ReadinessBlocker]"))
obj("ReportExportCreate", "Xuất báo cáo (FR-08-055).", ("format!", "E:ReportFileFormat", "PDF"))
obj("ReportSignRequest", "Ký số báo cáo đã công bố hoặc chờ công bố (FR-08-055, Q08-06).", ("certificateRef", "str", "chung-thu-co-quan-so-tttt", {"maxLength": 255}), ("comment", "str", "Ký xác nhận báo cáo năm 2026."))
obj("Subscription", "Đăng ký nhận báo cáo (dq_report_subscription).", ("subscriptionId!", "uuid"), ("reportType!", "E:ReportType", "PERIODIC"), ("domainCode", "dcode"), ("recipientType!", "E:RecipientType", "USER"),
    ("recipientRef!", "str", "tran.van.nam"), ("format!", "E:ReportFileFormat", "PDF"), ("enabled!", "bool", True), *AUD)
page("SubscriptionPage", "Subscription")
obj("SubscriptionCreate", "Đăng ký nhận báo cáo (FR-08-056).", ("reportType!", "E:ReportType", "PERIODIC"), ("domainCode", "dcode"), ("recipientType!", "E:RecipientType", "USER"),
    ("recipientRef!", "str", "tran.van.nam"), ("format!", "E:ReportFileFormat", "PDF"))

# --- quản trị
obj("TenantSettings", "Tham số chất lượng của tenant (dq_tenant_setting, FR-08-058); 40 khóa ở FRS 8.2.", ("values!", "obj", {"08.scan.default-cron": "0 0 2 1 * ?", "08.inline.timeout-ms": 40}),
    ("ceilings", "obj", {"08.inline.timeout-ms": {"min": 10, "max": 50}}), ("version!", "int", 5), ("updatedAt", "ts"), ("updatedBy", "str", "le.van.tuan"))
obj("TenantSettingsPut", "Đặt giá trị; chỉ gửi khóa cần đổi (ERR-08-042 khi ngoài miền).", ("values!", "obj", {"08.inline.timeout-ms": 45}))
obj("RetentionRun", "Lần dọn dữ liệu lưu giữ (FR-08-059).", ("runId!", "uuid"), ("status!", "E:RetentionRunStatus", "SUCCEEDED"), ("startedAt!", "ts"), ("finishedAt", "ts"), ("droppedPartitions", "int", 1),
    ("deletedRows", "int", 0), ("errorCode", "str", "ERR-08-117"))
page("RetentionRunPage", "RetentionRun")
obj("RetentionPreviewRequest", "Xem trước dọn dữ liệu.", ("objectTypes", "[str]", ["dq_finding"]), ("asOf", "ts"))
obj("RetentionPreviewItem", "Tác động theo loại đối tượng.", ("objectType!", "str", "dq_finding"), ("retentionDays!", "int", 395), ("action!", "E:RetentionAction", "DROP_PARTITION"),
    ("partitions", "int", 1), ("rowsAffected", "int", 2400000))
obj("RetentionPreview", "Kết quả xem trước, không xóa gì.", ("items!", "[$RetentionPreviewItem]"))
obj("AuditEvent", "Sự kiện kiểm toán PH-08 (FR-08-060).", ("eventId!", "uuid"), ("occurredAt!", "ts"), ("actor!", "str", "nguyen.thi.lan"), ("action!", "str", "RULESET_SUBMIT"), ("objectType!", "str", "RULE_SET_VERSION"),
    ("objectCode", "str", "bq-cong-dan/4"), ("outcome!", "E:AuditOutcome", "SUCCESS"), ("traceId", "str", "4bf92f3577b34da6a3ce929d0e0e4736"), ("detail", "obj", {"fromStatus": "DRAFT", "toStatus": "PENDING_APPROVAL"}))
page("AuditEventPage", "AuditEvent")
obj("BenchmarkPoint", "Một nhóm so sánh ẩn danh.", ("domainCode", "dcode"), ("groupSize!", "int", 7), ("p25", "score", 78.4), ("median", "score", 84.0), ("p75", "score", 90.2), ("ownScore", "score", 88.1))
obj("BenchmarkResult", "So sánh liên tenant (FR-08-061); ERR-08-044 khi nhóm nhỏ hơn `08.benchmark.min-group`.", ("periodCode!", "period"), ("minGroup!", "int", 5), ("items!", "[$BenchmarkPoint]"))

for n in sorted(ENUMS):
    SCH.setdefault(n, enum_schema(n))

# ---------------------------------------------------------------- tham số đường dẫn
PATHP = {"domainCode": ("dcode", "HO_TICH"), "assetCode": ("acode", A), "fieldPath": ("fpath", "citizenId"), "connectionCode": ("ccode", "kn-ho-tich"), "runId": ("uuid", None),
         "ruleSetCode": ("rscode", "bq-cong-dan"), "version": ("int", 4), "ruleCode": ("rcode", "CD-ACC-001"), "configId": ("uuid", None), "scheduleId": ("uuid", None),
         "scanId": ("uuid", None), "findingId": ("uuid", None), "exportId": ("uuid", None), "waiverId": ("uuid", None), "issueCode": ("icode", "DQI-2026-000123"),
         "alertRuleCode": ("rscode", "cb-diem-duoi-ngung"), "alertId": ("uuid", None), "reportCode": ("rpcode", "BC-2026-11"), "subscriptionId": ("uuid", None)}
