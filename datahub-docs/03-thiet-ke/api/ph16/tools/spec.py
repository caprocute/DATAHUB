#!/usr/bin/env python3
"""Nguồn duy nhất của hợp đồng API PH-16: đọc FRS §9.4 (mã, phương thức, đường dẫn), bảng operation, lược đồ.

Không chạy trực tiếp; gen_openapi.py, gen_asyncapi.py, gen_md.py, check_contracts.py, doi_chieu_frs.py nhập module này.
Enum lấy thẳng từ Phụ lục A của FRS (E('Tên')), tên trường camelCase theo FRS 6.x và cột DDL ph16_kpi.sql.
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS_PATH = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH16-frs-bao-cao-chi-tieu.md")
FRS = open(FRS_PATH, encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]

# ---------------------------------------------------------------- FRS
ERR = {}  # mã -> (danh sách HTTP, ý nghĩa)
_s91 = FRS[FRS.index("### 9.1."):FRS.index("### 9.2.")]
for m in re.finditer(r"^\| (ERR-16-\d{3}) \| ([^|]+?) \| ([^|]+?) \|", _s91, re.M):
    ERR[m.group(1)] = ([int(x) for x in re.findall(r"\d{3}", m.group(2))], m.group(3).strip())
_s92 = FRS[FRS.index("### 9.2."):FRS.index("### 9.3.")]
MSG = {m.group(1): m.group(2) for m in re.finditer(r'^\| (ERR-16-\d{3}) \| "([^|]+)" \| ([^|]+) \|', _s92, re.M)}
MSG_POS = {m.group(1): m.group(3).strip() for m in re.finditer(r'^\| (ERR-16-\d{3}) \| "([^|]+)" \| ([^|]+) \|', _s92, re.M)}
_s93 = FRS[FRS.index("### 9.3."):FRS.index("### 9.4.")]
EVT = [(m.group(1), m.group(2), m.group(3).strip(), m.group(4).strip()) for m in
       re.finditer(r"^\| (EVT-16-\d{2}) \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \|", _s93, re.M)]
EVT_IN_CODES = re.findall(r"EVT-\d{2}-\d{2}", _s93[_s93.index("PH-16 tiêu thụ:"):])
PERMS = sorted(set(re.findall(r"PERM-16-[a-z-]+", FRS)))

ALIAS = {
    "GroupCode": "groupCode", "IndicatorKind": "indicator.kind", "Direction": "indicator.direction", "Measurement": "indicator.measurement",
    "Aggregation": "indicator.aggregation", "IndicatorScope": "indicator.scope", "IndicatorState": "indicator.state", "VersionState": "indicator_version.state",
    "TargetMode": "target.targetMode", "ThresholdLevel": "threshold", "ValueStatus": "indicator_value.status", "Completeness": "indicator_value.completeness",
    "Trend": "indicator_value.trend", "SourceType": "data_source.sourceType", "SourceState": "data_source.state", "IngestOutcome": "ingest.result",
    "ManualState": "manual_value.state", "ImportRowStatus": "manual_import.rowStatus", "PeriodType": "reporting_period.periodType", "PeriodState": "reporting_period.state",
    "RunState": "aggregation_run.state", "RunTrigger": "aggregation_run.trigger", "RunFlag": "aggregation_run.flags", "ReportType": "report.reportType",
    "ReportState": "report.state", "SectionType": "report_template.section.type", "TemplateState": "report_template.state", "Format": "format",
    "ExportSubject": "export_job.subject", "ExportState": "export_job.state", "DeliveryState": "delivery.state", "DistributionAttach": "distribution.attach",
    "ComponentType": "arch_component.componentType", "Lifecycle": "arch_component.lifecycle", "OpsStatus": "arch_component.opsStatus", "Origin": "arch_component.origin",
    "DependencyKind": "arch_dependency.kind", "ComplianceLevel": "complianceLevel", "CriterionResult": "compliance_criterion.result",
    "AssessmentState": "compliance_assessment.state", "CriteriaSetState": "compliance_criteria_set.state", "ReconItemKind": "arch_reconciliation.itemKind",
    "SubmissionType": "national_submission.submissionType", "SubmissionState": "national_submission.state", "SubmissionMode": "national_submission.mode",
    "NationalTemplateState": "national_template.state", "CommonDecisionState": "common_update.decision", "SettingScope": "kpi_setting.scope",
    "DashboardView": "dashboard.view", "ReviewItemType": "review_item.type", "ArchIngestStatus": "arch_ingest.status", "NationalReconScope": "national_recon.scope",
    "RecipientType": "distribution.recipientType", "ReceiptStatus": "national_receipt.status", "DependencyType": "arch_dependency.dependencyType",
    "ObservationChannel": "observation.channel", "LineageSourceKind": "value_lineage.sourceKind", "WaiverState": "compliance_waiver.state",
    "ArchChange": "arch_component.change", "ComplianceEventKind": "arch_compliance.eventKind", "ReconState": "arch_reconciliation.state", "ReconResolution": "arch_reconciliation.resolution", "SubmissionLogEvent": "national_submission_log.event",
}
# dòng `decision` của Phụ lục A gộp ba tập giá trị theo ngữ cảnh; tách ở đây và kiểm lại với dòng đó trong check_contracts.py
LOCAL = {
    "DefinitionDecision": ["APPROVE", "REQUEST_CHANGES"], "ManualDecision": ["ACCEPT", "REJECT"], "CommonDecision": ["ACCEPT", "DISMISS"],
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
    for m in re.finditer(r"#### (FR-16-\d{3}) · [^\n]+\n\n::: dac-ta\n(.*?)\n:::", FRS, re.S):
        x = re.search(r"\*\*Luồng ngoại lệ\.\*\*\s*(.*?)(?=\n\n\*\*|\Z)", m.group(2), re.S)
        out[m.group(1)] = sorted(set((a, int(b)) for a, b in re.findall(r"(ERR-16-\d{3}) \((\d{3})\)", x.group(1)))) if x else []
    return out


FRERR = fr_errs()
FR_TITLE = dict(re.findall(r"^\| (FR-16-\d{3}) \| [^|]+ \| ([^|]+?) \| [MSC] \|", FRS, re.M))

# ---------------------------------------------------------------- operation theo FRS §9.4
ROWS = []  # (mã 3 số, phương thức, đường dẫn, [FR])
_sec = FRS[FRS.index("### 9.4."):FRS.index("## 10. Giao diện")]
for m in re.finditer(r"^\| API-16-(\d{3}) \| `([A-Z]+)` \| `([^`]+)` \| ([^|]+) \|", _sec, re.M):
    ROWS.append((m.group(1), m.group(2), m.group(3), [f"FR-16-{x}" for x in re.findall(r"(?<!\d)\d{3}(?!\d)", m.group(4))]))
ROWS.sort(key=lambda r: r[0])
assert len(ROWS) == 130, len(ROWS)

# ---------------------------------------------------------------- bảng operation
# mã | tóm tắt | nhóm | quyền (a/b = hoặc) | thân yêu cầu | thân phản hồi | HTTP | truy vấn | cờ
# truy vấn: tên:kiểu (đuôi ! là bắt buộc), page, size; cờ: idem, noifm, only:scope, m:scope, also:HTTP, mp (thân multipart), bin:loại (phản hồi nhị phân), internal
T1, T2, T3, T4, T5, T6, T7, T8, T9, T10 = ("Bộ chỉ tiêu", "Nguồn số liệu", "Số liệu nhập tay", "Kỳ báo cáo và tổng hợp", "Mẫu báo cáo", "Báo cáo", "Xuất và phân phối",
                                            "Cung cấp số liệu", "Bảng điều khiển", "Sổ kiến trúc")
T11, T12, T13 = "Tuân thủ kiến trúc", "Gửi quốc gia", "Quản trị"
OPS_TXT = f"""
001|Danh sách chỉ tiêu|{T1}|read|-|IndicatorPage|200|scope:E:IndicatorScope,q:str,groupCode:E:GroupCode,state:E:IndicatorState,measurement:E:Measurement,mandatory:bool,sort:str,page,size|
002|Tạo chỉ tiêu và phiên bản nháp đầu tiên|{T1}|admin|IndicatorCreate|Indicator|201|-|idem
003|Chi tiết chỉ tiêu|{T1}|read|-|Indicator|200|-|
004|Danh sách phiên bản định nghĩa|{T1}|read|-|IndicatorVersionPage|200|page,size|
005|Mở phiên bản định nghĩa mới|{T1}|admin|VersionCreate|IndicatorVersion|201|-|idem
006|Chi tiết phiên bản, so sánh với phiên bản khác|{T1}|read|-|IndicatorVersion|200|compareTo:int|
007|Sửa công thức, mục tiêu, ngưỡng của phiên bản nháp|{T1}|admin|VersionPatch|IndicatorVersion|200|-|
008|Kiểm cú pháp công thức|{T1}|admin|-|ValidateResult|200|-|
009|Thử tính trên dữ liệu kỳ trước|{T1}|admin|DryRunRequest|DryRunResult|200|-|
010|Danh sách biến quan sát có thể dùng|{T1}|read|-|MetricPage|200|q:str,sourceCode:code,page,size|
011|Gửi duyệt phiên bản định nghĩa|{T1}|admin|VersionSubmit|IndicatorVersion|200|-|
012|Duyệt phiên bản định nghĩa|{T1}|approve|CommentBody|IndicatorVersion|200|-|
013|Yêu cầu sửa phiên bản định nghĩa|{T1}|approve|RejectBody|IndicatorVersion|200|-|
014|Rút phiên bản khỏi hàng chờ duyệt|{T1}|admin|ReasonBody|IndicatorVersion|200|-|
015|Ngừng, thay thế chỉ tiêu|{T1}|admin|IndicatorRetire|Indicator|200|-|
016|Danh sách nhóm chỉ tiêu và trọng số|{T1}|read|-|GroupSet|200|-|
017|Đặt nhóm chỉ tiêu và trọng số|{T1}|admin|GroupSet|GroupSet|200|-|
018|Kế thừa chỉ tiêu mẫu COMMON|{T1}|admin|AdoptRequest|AdoptResult|201|-|idem noifm
019|Danh sách cập nhật mẫu chờ quyết định|{T1}|read|-|CommonUpdatePage|200|page,size|
020|Chấp nhận hoặc bỏ qua cập nhật mẫu|{T1}|admin|CommonDecisionBody|CommonDecisionResult|200|-|noifm
021|Danh sách nguồn số liệu|{T2}|read|-|SourcePage|200|q:str,state:E:SourceState,sourceType:E:SourceType,providerModule:str,page,size|
022|Đăng ký nguồn số liệu|{T2}|source|SourceCreate|DataSource|201|-|idem
023|Chi tiết nguồn số liệu, độ tươi|{T2}|read|-|DataSource|200|-|
024|Sửa nguồn số liệu|{T2}|source|SourcePatch|DataSource|200|-|
025|Thử đọc nguồn|{T2}|source|-|SourceTestResult|200|-|noifm
026|Tạm dừng nguồn|{T2}|source|SourcePause|DataSource|200|-|
027|Tiếp tục nguồn|{T2}|source|-|DataSource|200|-|
028|Ngừng nguồn|{T2}|source|ReasonBody|DataSource|200|-|
029|Kéo số liệu ngay hoặc đọc bù|{T2}|source|PullRequest|IngestTask|202|-|idem noifm
030|Nhận quan sát qua API đẩy|{T2}|-|ObservationBatch|IngestBatchResult|202|-|idem only:kpi.ingest also:207
031|Danh sách số liệu nhập tay|{T3}|read|-|ManualValuePage|200|indicatorCode:code,periodCode:pcode,state:E:ManualState,page,size|
032|Tạo số liệu nhập tay|{T3}|manual|ManualCreate|ManualValue|201|-|idem
033|Chi tiết số liệu nhập tay|{T3}|read|-|ManualValue|200|-|
034|Sửa số liệu nhập tay nháp|{T3}|manual|ManualUpdate|ManualValue|200|-|
035|Đính kèm bằng chứng|{T3}|manual|ManualEvidenceUpload|ManualValue|201|-|idem mp noifm
036|Tải tệp mẫu nhập số liệu|{T3}|manual|-|-|200|periodCode:pcode|noifm bin:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
037|Tải tệp nhập số liệu lên xem trước|{T3}|manual|ManualImportUpload|ManualImport|200|-|idem mp noifm
038|Chốt nhập tệp đã xem trước|{T3}|manual|-|ManualImport|200|-|noifm
039|Gửi số liệu nhập tay chờ xác nhận|{T3}|manual|-|ManualValue|200|-|
040|Xác nhận số liệu nhập tay|{T3}|manual|CommentBody|ManualValue|200|-|
041|Từ chối số liệu nhập tay|{T3}|manual|RejectBody|ManualValue|200|-|
042|Nhật ký tiếp nhận của nguồn|{T2}|source|-|IngestLogPage|200|result:E:IngestOutcome,metricCode:mcode,periodCode:pcode,code:str,from:ts,to:ts,page,size|
043|Danh sách quan sát|{T2}|read|-|ObservationPage|200|sourceCode:code,metricCode:mcode,periodCode:pcode,late:bool,from:ts,to:ts,page,size|
044|Danh sách quan sát bị loại|{T2}|source|-|RejectedObservationPage|200|sourceCode:code,metricCode:mcode,periodCode:pcode,code:str,from:ts,to:ts,page,size|
045|Xử lý lại quan sát bị loại|{T2}|source|ReprocessRequest|ReprocessResult|200|-|noifm
046|Danh sách kỳ báo cáo|{T4}|read|-|PeriodPage|200|periodType:E:PeriodType,state:E:PeriodState,year:int,page,size|
047|Tạo kỳ báo cáo|{T4}|run|PeriodCreate|ReportingPeriod|201|-|idem
048|Chi tiết kỳ báo cáo|{T4}|read|-|ReportingPeriod|200|-|
049|Danh sách lần tổng hợp|{T4}|read|-|RunPage|200|periodCode:pcode,state:E:RunState,trigger:E:RunTrigger,from:ts,to:ts,page,size|
050|Chạy tổng hợp kỳ|{T4}|run|RunCreate|Run|202|-|idem noifm
051|Chi tiết lần tổng hợp|{T4}|read|-|Run|200|-|
052|Hủy lần tổng hợp|{T4}|run|ReasonBody|Run|200|-|noifm
053|Giá trị chỉ tiêu của lần tổng hợp|{T4}|read|-|ValuePage|200|indicatorCode:code,groupCode:E:GroupCode,status:E:ValueStatus,completeness:E:Completeness,page,size|
054|Dòng truy nguồn của giá trị|{T4}|read|-|Lineage|200|-|
055|Tính lại kỳ chưa chốt|{T4}|run|RecomputeRequest|Run|202|-|idem noifm
056|Lịch sử đổi trạng thái chỉ tiêu trong kỳ|{T4}|read|-|StatusChangePage|200|indicatorCode:code,page,size|
057|Chốt kỳ|{T4}|run|PeriodClose|ReportingPeriod|200|-|
058|Mở lại kỳ đã chốt|{T4}|run|PeriodReopen|ReportingPeriod|200|-|
059|Danh sách mẫu báo cáo|{T5}|read|-|TemplatePage|200|reportType:E:ReportType,state:E:TemplateState,page,size|
060|Tạo mẫu báo cáo|{T5}|admin|TemplateCreate|ReportTemplate|201|-|idem
061|Chi tiết mẫu báo cáo|{T5}|read|-|ReportTemplate|200|-|
062|Sửa mẫu báo cáo|{T5}|admin|TemplatePatch|ReportTemplate|200|-|
063|Xem trước mẫu báo cáo|{T5}|admin|TemplatePreviewRequest|TemplatePreview|200|-|noifm
064|Danh sách báo cáo|{T6}|read|-|ReportPage|200|q:str,reportType:E:ReportType,periodCode:pcode,state:E:ReportState,from:date,to:date,page,size|
065|Lập bản nháp báo cáo|{T6}|report|ReportCreate|Report|201|-|idem
066|Chi tiết báo cáo|{T6}|read|-|Report|200|-|
067|Sửa tiêu đề, thuyết minh báo cáo nháp|{T6}|report|ReportPatch|Report|200|-|
068|Lưu giải trình chỉ tiêu chệch|{T6}|report|ExplanationPut|ExplanationResult|200|-|
069|Làm mới số liệu của bản nháp|{T6}|report|RefreshRequest|Run|202|-|idem
070|Xem trước báo cáo|{T6}|report|-|ReportPreview|200|-|
071|Gửi duyệt báo cáo|{T6}|report|SubmitNote|Report|200|-|
072|Duyệt báo cáo|{T6}|approve|CommentBody|Report|200|-|
073|Yêu cầu sửa báo cáo|{T6}|approve|RejectBody|Report|200|-|
074|Công bố báo cáo chính thức|{T6}|approve|PublishRequest|Report|200|-|
075|Đính chính báo cáo đã công bố|{T6}|approve|CorrectRequest|Report|201|-|idem
076|Rút báo cáo đã công bố|{T6}|approve|Reason50Body|Report|200|-|
077|Lịch sử phiên bản báo cáo|{T6}|read|-|ReportVersionPage|200|page,size|
078|Hàng đợi chờ duyệt, chờ xác nhận|{T6}|approve/manual|-|ReviewQueuePage|200|itemType:E:ReviewItemType,page,size|
079|Yêu cầu xuất tệp|{T7}|export|ExportCreate|ExportJob|202|-|idem
080|Trạng thái việc xuất|{T7}|export|-|ExportJob|200|-|
081|Tải tệp đã xuất|{T7}|export|-|-|200|-|bin:application/octet-stream
082|Danh sách phân phối|{T7}|export|-|DistributionPage|200|page,size|
083|Tạo danh sách phân phối|{T7}|export|DistributionCreate|Distribution|201|-|idem
084|Sửa danh sách phân phối|{T7}|export|DistributionPatch|Distribution|200|-|
085|Lịch sử gửi của danh sách phân phối|{T7}|export|-|DeliveryPage|200|state:E:DeliveryState,page,size|
086|Đọc giá trị chỉ tiêu cho hệ khác|{T8}|-|-|FeedValuePage|200|periodCode:pcode,from:date,to:date,indicatorCodes:[code],groupCode:E:GroupCode,onlyOfficial:bool,page,size|only:kpi.read
087|Đọc báo cáo đã công bố cho hệ khác|{T8}|-|-|FeedReportPage|200|periodCode:pcode,reportType:E:ReportType,from:date,to:date,page,size|only:kpi.read
088|Bằng chứng công bố báo cáo|{T6}|read|-|PublishEvidence|200|version:int|
089|Thẻ chỉ tiêu cho trang Tổng quan|{T8}|read|-|CardSet|200|limit:int|m:kpi.read
090|Bảng điều khiển năm nhóm|{T9}|read|-|Dashboard|200|periodCode:pcode,compareTo:pcode,view:E:DashboardView,groupCode:E:GroupCode,status:E:ValueStatus|
091|Chuỗi thời gian của chỉ tiêu|{T9}|read|-|Series|200|periodType:E:PeriodType,from:date,to:date,compareTo:pcode,lineage:bool|
092|So sánh liên tenant ẩn danh|{T9}|compare|-|Comparison|200|indicatorCode!:code,periodCode!:pcode|
093|Tình trạng thu thập, tính toán|{T9}|read|-|OpsOverview|200|tenantId:str,from:ts,to:ts|
094|Danh sách thành phần kiến trúc|{T10}|read|-|ArchComponentPage|200|q:str,componentType:E:ComponentType,lifecycle:E:Lifecycle,opsStatus:E:OpsStatus,complianceLevel:E:ComplianceLevel,origin:E:Origin,ownerOrgId:str,page,size|
095|Khai báo thành phần kiến trúc|{T10}|arch|ComponentCreate|ArchComponent|201|-|idem
096|Chi tiết thành phần kiến trúc|{T10}|read|-|ArchComponent|200|-|
097|Sửa thành phần kiến trúc|{T10}|arch|ComponentPatch|ArchComponent|200|-|
098|Thêm phiên bản thành phần|{T10}|arch|ComponentVersionAdd|ArchComponent|201|-|idem noifm
099|Đặt phụ thuộc của thành phần|{T10}|arch|DependenciesPut|ComponentDependencies|200|-|
100|Chuyển vòng đời thành phần|{T10}|arch|LifecycleChange|ArchComponent|200|-|
101|Tự đăng ký thành phần qua API|{T10}|-|ArchIngestBatch|ArchIngestResult|202|-|idem only:arch.register
102|Danh sách bộ tiêu chí tuân thủ|{T11}|read|-|CriteriaSetPage|200|state:E:CriteriaSetState,page,size|
103|Tạo phiên bản bộ tiêu chí|{T11}|admin|CriteriaSetCreate|CriteriaSet|201|-|idem
104|Kích hoạt phiên bản bộ tiêu chí|{T11}|admin|-|CriteriaSet|200|-|
105|Lập đánh giá tuân thủ|{T11}|arch-assess|AssessmentCreate|Assessment|201|-|idem
106|Sửa đánh giá nháp|{T11}|arch-assess|AssessmentPatch|Assessment|200|-|
107|Gửi đánh giá chờ xác nhận|{T11}|arch-assess|-|Assessment|200|-|
108|Xác nhận đánh giá|{T11}|arch-assess|CommentBody|Assessment|200|-|
109|Từ chối đánh giá|{T11}|arch-assess|RejectBody|Assessment|200|-|
110|Cấp miễn trừ có hạn|{T11}|arch-assess|WaiverCreate|Waiver|201|-|idem
111|Đối chiếu sổ kiến trúc với phân hệ nguồn|{T11}|arch|ReconRequest|Reconciliation|202|-|idem noifm
112|Kết quả đối chiếu sổ kiến trúc|{T11}|read|-|Reconciliation|200|page,size|
113|Xử lý một mục lệch|{T11}|arch|ReconResolve|Reconciliation|200|-|noifm
114|Danh sách mẫu gói quốc gia|{T12}|read|-|NationalTemplatePage|200|submissionType:E:SubmissionType,state:E:NationalTemplateState,page,size|
115|Tạo phiên bản mẫu gói quốc gia|{T12}|national/admin|NationalTemplateCreate|NationalTemplate|201|-|idem
116|Chi tiết mẫu gói quốc gia|{T12}|read|-|NationalTemplate|200|version:int|
117|Kích hoạt phiên bản mẫu gói|{T12}|national/admin|-|NationalTemplate|200|-|
118|Lập gói quốc gia|{T12}|national|SubmissionCreate|Submission|201|-|idem
119|Danh sách gói quốc gia|{T12}|read|-|SubmissionPage|200|submissionType:E:SubmissionType,state:E:SubmissionState,reportCode:code,from:ts,to:ts,page,size|
120|Chi tiết gói quốc gia|{T12}|read|-|Submission|200|-|
121|Gửi gói quốc gia|{T12}|national|-|Submission|202|-|
122|Gửi lại gói quốc gia|{T12}|national|ReasonBody|Submission|202|-|
123|Nhật ký nộp của gói|{T12}|read|-|SubmissionLogPage|200|page,size|
124|Nhận biên nhận từ PH-14|{T12}|-|ReceiptIn|-|204|-|only:kpi.national-receipt internal noifm
125|Đối soát sổ kiến trúc, gói đã nộp, chỉ tiêu|{T12}|national|NationalReconRequest|NationalRecon|202|-|idem noifm
126|Kết quả đối soát quốc gia|{T12}|read|-|NationalRecon|200|-|
127|Đọc tham số 16.*|{T13}|read|-|Settings|200|-|
128|Sửa tham số 16.*|{T13}|config|SettingsPatch|Settings|200|-|
129|Nhật ký kiểm toán PH-16|{T13}|audit-read|-|AuditPage|200|actor:str,action:str,objectType:str,objectRef:str,from:ts,to:ts,page,size|
130|Tình trạng lưu giữ, dọn dữ liệu|{T13}|config/audit-read|-|RetentionStatus|200|-|
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
    "code": ({"type": "string", "pattern": "^[a-z][a-z0-9-]{2,62}$"}, "httt-ket-noi-ty-le"),
    "pcode": ({"type": "string", "pattern": r"^(M|Q|Y)-[0-9]{4}(-[0-9]{2}|-Q[1-4])?$"}, "M-2026-10"),
    "mcode": ({"type": "string", "pattern": r"^ph[0-9]{2}(\.[a-z0-9-]+){2,}$"}, "ph08.dq.score"),
    "rcode": ({"type": "string", "pattern": "^bc-[a-z0-9-]{2,60}$"}, "bc-thang-2026-10"),
    "int": ({"type": "integer"}, 1), "num": ({"type": "number"}, 0.9), "bool": ({"type": "boolean"}, False),
    "pct": ({"type": "number", "minimum": 0, "maximum": 100}, 82.5),
    "ratio": ({"type": "number", "minimum": 0, "maximum": 1}, 0.96),
    "ts": ({"type": "string", "format": "date-time"}, "2026-11-26T08:00:00+07:00"),
    "date": ({"type": "string", "format": "date"}, "2026-12-31"),
    "uuid": ({"type": "string", "format": "uuid"}, "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"),
    "sha": ({"type": "string", "pattern": "^[0-9a-f]{64}$"}, "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"),
    "url": ({"type": "string", "format": "uri"}, "https://console.t68.datahub.example.vn/tai/0193b1d4"),
    "bin": ({"type": "string", "format": "binary"}, "(nội dung tệp)"),
    "obj": ({"type": "object"}, {}), "any": ({}, "ví dụ"),
}
SCH = {}


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
R50 = {"minLength": 50, "maxLength": 2000}
AUD = [("createdAt", "ts"), ("createdBy", "str", "nguyen.thi.lan"), ("updatedAt", "ts"), ("updatedBy", "str", "nguyen.thi.lan")]
IND = ("indicatorCode!", "code")
RC = ("reportCode!", "rcode")
SC_ = ("sourceCode!", "code", "ph08-dq-kpi")
CC = ("componentCode!", "code", "httt-qlvb")
PC = ("periodCode!", "pcode")

obj("FieldError", "Lỗi theo trường.", ("field!", "str", "formula"), ("message!", "str", "Giá trị không hợp lệ."))
obj("Problem", "Lỗi theo RFC 9457.", ("type!", "str", "https://datahub.example.vn/errors/ERR-16-003"), ("title!", "str", "Dữ liệu không hợp lệ"),
    ("status!", "int", 400), ("detail", "str", "Trường indicatorCode không đúng mẫu."), ("instance", "str", "/api/kpi/v1/indicators"),
    ("code!", "str", "ERR-16-003"), ("traceId!", "str", "4bf92f3577b34da6a3ce929d0e0e4736"), ("errors", "[$FieldError]"))
obj("CommentBody", "Ý kiến kèm hành động (tùy chọn).", ("comment", "str", "Đồng ý theo biên bản họp ngày 20/11/2026.", {"maxLength": 2000}))
obj("RejectBody", "Từ chối, yêu cầu sửa: bắt buộc nêu lý do từ 20 ký tự (ERR-16-007).", ("comment!", "str", "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại.", R20))
obj("ReasonBody", "Hành động kèm lý do từ 20 ký tự (ERR-16-007).", ("reason!", "str", "Nguồn đã ngừng cung cấp theo công văn số 123 ngày 10/11/2026.", R20))
obj("Reason50Body", "Hành động kèm lý do từ 50 ký tự (ERR-16-007).", ("reason!", "str", "Phát hiện sai số liệu ở chỉ tiêu bắt buộc sau khi công bố, cần rút để đính chính theo quy trình.", R50))
obj("SubmitNote", "Ghi chú khi gửi duyệt (tùy chọn).", ("note", "str", "Gửi duyệt báo cáo tháng 10.", {"maxLength": 2000}))

# --- bộ chỉ tiêu (nhóm A)
obj("DerivedFrom", "Chỉ tiêu mẫu COMMON mà chỉ tiêu của tỉnh kế thừa.", ("indicatorCode!", "code"), ("version!", "int", 2))
obj("Target", "Mục tiêu (FR-16-004).", ("baseline", "num", 40), ("target!", "num", 90), ("targetDate", "date", "2027-12-31"), ("targetMode", "E:TargetMode", "ABSOLUTE"))
obj("Range", "Khoảng đích của chỉ tiêu `TARGET_RANGE`.", ("low!", "num", 0), ("high!", "num", 0), ("tolerance", "num", 0))
obj("Thresholds", "Ngưỡng ba mức GREEN, AMBER, RED; đơn điệu theo chiều tốt (ERR-16-010).", ("greenFrom", "num", 90), ("amberFrom", "num", 70), ("range", "$Range"))
obj("Variable", "Bí danh biến trong công thức.", ("alias!", "str", "tong"), ("metricCode!", "mcode", "ph01.httt.total"))
obj("Indicator", "Chỉ tiêu (kpi_indicator).", IND, ("name!", "str", "Tỷ lệ HTTT kết nối nền tảng"), ("description", "str", "Số HTTT đã kết nối trên tổng số HTTT cần kết nối"),
    ("groupCode!", "E:GroupCode", "KET_NOI"), ("kind!", "E:IndicatorKind", "RATIO"), ("direction!", "E:Direction", "HIGHER_BETTER"), ("measurement!", "E:Measurement", "AUTO"),
    ("unit!", "str", "%"), ("aggregation!", "E:Aggregation", "LAST"), ("mandatory!", "bool", True), ("scope!", "E:IndicatorScope", "TENANT"), ("state!", "E:IndicatorState", "ACTIVE"),
    ("activeVersion", "int", 2), ("pendingVersion", "int", 3), ("derivedFrom", "$DerivedFrom"), ("confirmerRoles", "[str]", ["SO"]), ("brdRef", "str", "KPI-01"),
    ("replacedBy", "code", "httt-ket-noi-ty-le-v2"), ("activeDefinition", "$IndicatorVersion"), *AUD)
obj("IndicatorCreate", "Tạo chỉ tiêu và phiên bản 1 nháp (FR-16-002).", ("indicatorCode!", "code", "api-dat-sla-ty-le"), ("name!", "str", "Tỷ lệ API đạt SLA", {"minLength": 1, "maxLength": 255}),
    ("description", "str", "Số API đạt SLA tháng trên số API công bố", {"maxLength": 4000}), ("groupCode!", "E:GroupCode", "CHIA_SE"), ("kind!", "E:IndicatorKind", "RATIO"),
    ("direction!", "E:Direction", "HIGHER_BETTER"), ("measurement!", "E:Measurement", "AUTO"), ("unit!", "str", "%"), ("aggregation!", "E:Aggregation", "AVG"),
    ("mandatory", "bool", True), ("confirmerRoles", "[str]", ["SO"]))
obj("Facets", "Số đếm theo nhóm, trạng thái, cách đo.", ("byGroup", "obj", {"KET_NOI": 5, "CHIA_SE": 7}), ("byState", "obj", {"ACTIVE": 22, "DRAFT": 2}), ("byMeasurement", "obj", {"AUTO": 18, "MANUAL": 4, "MIXED": 2}))
obj("IndicatorPage", "Trang chỉ tiêu kèm số đếm.", ("items!", "[$Indicator]"), ("page!", "int", 0), ("size!", "int", 20), ("totalElements!", "int", 1), ("facets", "$Facets"), ("hasCommonUpdate", "bool", False))
obj("DiffItem", "Một trường khác nhau giữa hai phiên bản.", ("field!", "str", "target.target"), ("from", "str", "85"), ("to", "str", "90"))
obj("IndicatorVersion", "Phiên bản định nghĩa chỉ tiêu (kpi_indicator_version).", IND, ("version!", "int", 3), ("state!", "E:VersionState", "DRAFT"),
    ("formula", "str", 'obs("ph01.httt.connected") / obs("ph01.httt.total") * 100', {"maxLength": 2000}), ("variables", "[$Variable]"), ("dryRunHash", "str", "d41d8cd98f00b204"),
    ("direction", "E:Direction", "HIGHER_BETTER"), ("unit", "str", "%"), ("target", "$Target"), ("thresholds", "$Thresholds"), ("decimals", "int", 1, {"minimum": 0, "maximum": 4}),
    ("effectiveFrom", "date", "2026-12-01"), ("changeNote", "str", "Nâng mục tiêu năm 2027 lên 90%."), ("submittedBy", "str", "nguyen.thi.lan"), ("submittedAt", "ts"),
    ("approvedBy", "str", "tran.van.nam"), ("approvedAt", "ts"), ("decisionComment", "str", "Đồng ý theo biên bản họp ngày 20/11/2026."), ("diff", "[$DiffItem]"), *AUD)
page("IndicatorVersionPage", "IndicatorVersion")
obj("VersionCreate", "Mở phiên bản mới, sao từ phiên bản `ACTIVE` hoặc `baseVersion` (FR-16-002).", ("baseVersion", "int", 2), ("changeNote", "str", "Đổi mục tiêu năm 2027.", {"maxLength": 2000}))
obj("VersionPatch", "Sửa phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`; gửi các trường cần đổi (FR-16-003, 004). Sửa xong phải thử tính lại (ERR-16-011).",
    ("formula", "str", 'obs("ph01.httt.connected") / obs("ph01.httt.total") * 100', {"maxLength": 2000}), ("variables", "[$Variable]"), ("target", "$Target"), ("thresholds", "$Thresholds"),
    ("direction", "E:Direction", "HIGHER_BETTER"), ("unit", "str", "%"), ("decimals", "int", 1, {"minimum": 0, "maximum": 4}), ("changeNote", "str", "Nâng mục tiêu."))
obj("ValidateResult", "Kết quả kiểm cú pháp, kiểu, biến (FR-16-003).", ("valid!", "bool", True), ("referencedMetrics!", "[mcode]", ["ph01.httt.connected", "ph01.httt.total"]), ("warnings", "[str]", []))
obj("DryRunRequest", "Thử tính trên 1…6 kỳ đã qua; bỏ trống thì dùng ba kỳ tháng gần nhất.", ("dryRunPeriods", "[pcode]", ["M-2026-08", "M-2026-09", "M-2026-10"], {"minItems": 1, "maxItems": 6}))
obj("DryRunItem", "Kết quả thử tính một kỳ.", ("periodCode!", "pcode", "M-2026-08"), ("value", "num", 78.5), ("completeness!", "E:Completeness", "COMPLETE"), ("missingMetrics", "[mcode]", []), ("elapsedMs", "int", 12))
obj("DryRunResult", "Kết quả thử tính; `dryRunHash` gắn với nội dung hiện tại của phiên bản (FR-16-003).", ("results!", "[$DryRunItem]"), ("dryRunHash!", "str", "d41d8cd98f00b204"))
obj("Metric", "Biến quan sát đã có trong hợp đồng của một nguồn.", ("metricCode!", "mcode"), SC_, ("unit", "str", "điểm"), ("periodType", "E:PeriodType", "MONTH"), ("lastObservedAt", "ts"))
page("MetricPage", "Metric")
obj("VersionSubmit", "Gửi duyệt phiên bản (FR-16-005).", ("changeNote!", "str", "Nâng mục tiêu 2027 lên 90% theo kế hoạch của tỉnh.", R20), ("effectiveFrom", "date", "2026-12-01"))
obj("IndicatorRetire", "Ngừng, thay thế chỉ tiêu (FR-16-006).", ("reason!", "str", "Thay bằng chỉ tiêu đo theo khung mới của Bộ.", R20), ("replacedBy", "code", "httt-ket-noi-ty-le-v2"), ("effectivePeriod!", "pcode", "M-2027-01"))
obj("GroupItem", "Nhóm chỉ tiêu và trọng số điểm nhóm.", ("groupCode!", "E:GroupCode", "KET_NOI"), ("displayName!", "str", "Kết nối, tích hợp", {"minLength": 1, "maxLength": 100}),
    ("order", "int", 1), ("weight!", "num", 20, {"minimum": 0, "maximum": 100}))
obj("GroupSet", "Năm nhóm cố định; tổng trọng số bằng 100 (ERR-16-012).", ("groups!", "[$GroupItem]", [
    {"groupCode": "KET_NOI", "displayName": "Kết nối, tích hợp", "order": 1, "weight": 20}, {"groupCode": "CHIA_SE", "displayName": "Chia sẻ, khai thác dữ liệu", "order": 2, "weight": 20},
    {"groupCode": "DU_LIEU", "displayName": "Chất lượng, danh mục dữ liệu", "order": 3, "weight": 20}, {"groupCode": "VAN_HANH", "displayName": "Vận hành, an toàn", "order": 4, "weight": 20},
    {"groupCode": "KIEN_TRUC", "displayName": "Tuân thủ kiến trúc, triển khai", "order": 5, "weight": 20}]), ("effectiveFrom", "date", "2026-12-01"))
obj("AdoptRequest", "Kế thừa chỉ tiêu mẫu; để trống là kế thừa toàn bộ (FR-16-008).", ("indicatorCodes", "[code]", ["httt-ket-noi-ty-le"]))
obj("SkippedItem", "Chỉ tiêu bị bỏ qua khi kế thừa.", IND, ("reason!", "str", "Đã kế thừa trước đó (ERR-16-002)."))
obj("AdoptResult", "Kết quả kế thừa.", ("adopted!", "[code]", ["httt-ket-noi-ty-le", "mttd"]), ("skipped!", "[$SkippedItem]", []))
obj("CommonUpdate", "Cập nhật mẫu COMMON đang chờ tenant quyết định.", IND, ("templateVersion!", "int", 3), ("derivedVersion", "int", 2), ("changedFields", "[str]", ["formula", "target.target"]),
    ("conflictFields", "[str]", ["target.target"]), ("publishedAt", "ts"), ("decision", "E:CommonDecisionState", "ACCEPTED"))
page("CommonUpdatePage", "CommonUpdate")
obj("CommonDecisionBody", "Chấp nhận hoặc bỏ qua cập nhật mẫu (FR-16-008).", ("decision!", "E:CommonDecision", "ACCEPT"), ("comment", "str", "Nhận bản cập nhật, giữ mục tiêu riêng của tỉnh.", {"maxLength": 2000}))
obj("CommonDecisionResult", "Kết quả quyết định cập nhật mẫu.", IND, ("newDraftVersion", "int", 3), ("dismissed", "bool", False))

# --- nguồn số liệu (nhóm B)
obj("Freshness", "Độ tươi của nguồn (FR-16-013).", ("lastObservedAt", "ts"), ("ageHours!", "num", 3.5), ("state!", "E:SourceState", "ACTIVE"))
obj("SourceContract", "Hợp đồng chỉ số của nguồn.", ("metricCodes!", "[mcode]", ["ph08.dq.score", "ph08.dq.issues-open"]))
obj("DataSource", "Nguồn số liệu (kpi_data_source).", SC_, ("name", "str", "Điểm chất lượng dữ liệu PH-08"), ("sourceType!", "E:SourceType", "EVENT"), ("providerModule", "str", "PH-08", {"pattern": "^PH-[0-9]{2}$"}),
    ("state!", "E:SourceState", "ACTIVE"), ("topic", "str", "t68.dq.kpi.published.v1"), ("schemaRef", "str", "dq-kpi@kpiSchemaVersion=1"), ("endpoint", "str", "/api/catalog/v1/stats/usage"),
    ("scope", "str", "catalog:metrics-read"), ("cron", "str", "0 0 2 * * ?"), ("clientId", "str", "svc-ph19"), ("contract!", "$SourceContract"), ("priority", "int", 5, {"minimum": 1, "maximum": 9}),
    ("staleAfterHours", "int", 26), ("freshness", "$Freshness"), ("stateReason", "str", "Tạm dừng bảo trì PH-08."), ("description", "str", "Bản tin KPI chất lượng dữ liệu"), *AUD)
obj("SourceCreate", "Đăng ký nguồn (FR-16-009); trường bắt buộc theo `sourceType` (ERR-16-015).", ("sourceCode!", "code", "ph02-catalog-stats"), ("name", "str", "Thống kê danh mục API PH-02"),
    ("sourceType!", "E:SourceType", "PULL_API"), ("providerModule", "str", "PH-02", {"pattern": "^PH-[0-9]{2}$"}), ("topic", "str", "t68.dq.kpi.published.v1"), ("schemaRef", "str", "dq-kpi@kpiSchemaVersion=1"),
    ("endpoint", "str", "/api/catalog/v1/stats/usage"), ("scope", "str", "catalog:metrics-read"), ("cron", "str", "0 0 2 * * ?"), ("clientId", "str", "svc-ph19"),
    ("contract!", "$SourceContract"), ("priority", "int", 5, {"minimum": 1, "maximum": 9}), ("staleAfterHours", "int", 26), ("description", "str", "Số API công bố, lượt khai thác"))
obj("SourcePatch", "Sửa nguồn; gửi các trường cần đổi.", ("name", "str", "Thống kê danh mục API PH-02"), ("cron", "str", "0 0 3 * * ?"), ("contract", "$SourceContract"),
    ("priority", "int", 3), ("staleAfterHours", "int", 30), ("description", "str", "Cập nhật mô tả"))
page("SourcePage", "DataSource")
obj("SourceTestResult", "Kết quả thử đọc nguồn (FR-16-009); lỗi trả ERR-16-016.", ("ok!", "bool", True), ("elapsedMs", "int", 180), ("sampleMetrics", "[mcode]", ["ph02.api.published"]), ("message", "str", "Đọc được 3 chỉ số."))
obj("SourcePause", "Tạm dừng nguồn (FR-16-013).", ("reason!", "str", "PH-08 bảo trì lược đồ KPI đến hết ngày 28/11.", R20), ("until", "ts"))
obj("PullRequest", "Đọc bù khi lỡ sự kiện; bỏ trống thân là kéo ngay (FR-16-011).", ("from", "date", "2026-10-01"), ("to", "date", "2026-10-31"), ("reason", "str", "Đọc bù do mất sự kiện tháng 10.", {"maxLength": 2000}))
obj("IngestTask", "Việc kéo hoặc đọc bù đã nhận.", ("ingestLogId!", "uuid"), SC_, ("state!", "E:RunState", "QUEUED"), ("requestedAt", "ts"))
obj("Observation", "Quan sát đã chuẩn hóa (kpi_observation).", ("id!", "uuid"), SC_, ("metricCode!", "mcode"), ("value!", "num", 92.5), ("unit", "str", "điểm"), ("periodStart!", "date", "2026-10-01"),
    ("periodEnd!", "date", "2026-10-31"), ("dimensions", "obj", {"don-vi": "so-tttt"}), ("sourceRef", "str", "t68.dq.kpi.published.v1/0/1842"), ("idempotencyRef!", "str", "snap-2026-10-31-T68"),
    ("channel", "E:ObservationChannel", "EVENT"), ("late", "bool", False), ("receivedAt", "ts"))
page("ObservationPage", "Observation")
obj("ObservationIn", "Một quan sát đẩy vào (FR-16-012).", ("metricCode!", "mcode"), ("value!", "num", 92.5), ("periodStart!", "date", "2026-10-01"), ("periodEnd!", "date", "2026-10-31"),
    ("dimensions", "obj", {"don-vi": "so-tttt"}), ("idempotencyRef!", "str", "snap-2026-10-31-T68", {"minLength": 1, "maxLength": 200}))
obj("ObservationBatch", "Lô quan sát từ phân hệ nguồn; scope `kpi.ingest`.", SC_, ("observations!", "[$ObservationIn]", None, {"minItems": 1, "maxItems": 500}))
obj("IngestItemResult", "Kết quả từng quan sát.", ("index!", "int", 0), ("status!", "E:IngestOutcome", "ACCEPTED"), ("code", "str", "ERR-16-101", {"pattern": "^ERR-16-[0-9]{3}$"}))
obj("IngestBatchResult", "Kết quả lô: `202` khi mọi phần tử được nhận, `207` khi có phần tử lỗi.", ("accepted!", "int", 1), ("duplicate!", "int", 0), ("rejected!", "int", 0), ("results!", "[$IngestItemResult]", [{"index": 0, "status": "ACCEPTED"}]))
obj("IngestLog", "Dòng nhật ký tiếp nhận (kpi_ingest_log).", ("id!", "uuid"), SC_, ("channel", "E:ObservationChannel", "EVENT"), ("result!", "E:IngestOutcome", "ACCEPTED"), ("metricCode", "mcode"),
    ("idempotencyRef", "str", "snap-2026-10-31-T68"), ("code", "str", "ERR-16-101"), ("detail", "str", "Thiếu trường periodEnd."), ("receivedAt!", "ts"))
page("IngestLogPage", "IngestLog")
obj("RejectedObservation", "Quan sát bị loại, chờ xử lý lại (FR-16-016).", ("id!", "uuid"), SC_, ("metricCode", "mcode"), ("idempotencyRef", "str", "snap-2026-10-31-T68"),
    ("code!", "str", "ERR-16-102", {"pattern": "^ERR-16-[0-9]{3}$"}), ("detail", "str", "Chỉ số ngoài hợp đồng của nguồn."), ("result!", "E:IngestOutcome", "REJECTED"), ("receivedAt!", "ts"))
page("RejectedObservationPage", "RejectedObservation")
obj("ReprocessRequest", "Xử lý lại tối đa 500 quan sát bị loại (FR-16-016).", ("ids!", "[uuid]", None, {"minItems": 1, "maxItems": 500}), ("reason!", "str", "Đã bổ sung chỉ số vào hợp đồng nguồn.", R20))
obj("StillRejected", "Quan sát vẫn bị loại.", ("id!", "uuid"), ("code!", "str", "ERR-16-102", {"pattern": "^ERR-16-[0-9]{3}$"}))
obj("ReprocessResult", "Kết quả xử lý lại.", ("reprocessed!", "int", 1), ("stillRejected!", "[$StillRejected]", []))

# --- số liệu nhập tay
obj("Evidence", "Bằng chứng của số liệu tay (kpi_manual_evidence).", ("evidenceId", "uuid"), ("fileName", "str", "qd-phe-duyet.pdf"), ("sha256", "sha"), ("docNumber", "str", "123/QĐ-UBND"), ("docDate", "date", "2026-09-15"))
obj("EvidenceIn", "Bằng chứng theo số văn bản; tệp gửi riêng ở API-16-035.", ("docNumber!", "str", "123/QĐ-UBND"), ("docDate!", "date", "2026-09-15"))
obj("ManualValue", "Số liệu nhập tay (kpi_manual_value).", ("manualId!", "uuid"), IND, PC, ("value!", "num", 1), ("dimensions", "obj", {"don-vi": "so-tttt"}),
    ("method!", "str", "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.", {"minLength": 20, "maxLength": 2000}), ("state!", "E:ManualState", "DRAFT"), ("evidence", "[$Evidence]"),
    ("enteredBy", "str", "nguyen.thi.lan"), ("enteredAt", "ts"), ("submittedAt", "ts"), ("decidedBy", "str", "tran.van.nam"), ("decidedAt", "ts"), ("decisionComment", "str", "Đã đối chiếu quyết định."))
page("ManualValuePage", "ManualValue")
obj("ManualCreate", "Tạo số liệu nhập tay (FR-16-014).", ("indicatorCode!", "code", "ho-so-cap-do-phe-duyet"), ("periodCode!", "pcode", "Q-2026-Q3"), ("value!", "num", 1), ("dimensions", "obj", {"don-vi": "so-tttt"}),
    ("method!", "str", "Quyết định phê duyệt hồ sơ cấp độ 3 do Sở TT&TT ban hành.", {"minLength": 20, "maxLength": 2000}), ("evidence", "[$EvidenceIn]"))
obj("ManualUpdate", "Sửa số liệu nháp; gửi các trường cần đổi.", ("value", "num", 1), ("dimensions", "obj", {"don-vi": "so-tttt"}), ("method", "str", "Bổ sung phương pháp thu số liệu theo mẫu.", {"maxLength": 2000}), ("evidence", "[$EvidenceIn]"))
obj("ManualEvidenceUpload", "Tải tệp bằng chứng (PDF, ảnh, XLSX, DOCX, tối đa `16.manual.max-file-mb`).", ("file!", "bin"), ("docNumber", "str", "123/QĐ-UBND"), ("docDate", "date", "2026-09-15"), ("description", "str", "Quyết định phê duyệt"))
obj("ManualImportUpload", "Tải tệp XLSX theo mẫu (tối đa 2.000 dòng, 10 MB).", ("file!", "bin"))
obj("ImportRow", "Một dòng của tệp nhập.", ("row!", "int", 2), ("status!", "E:ImportRowStatus", "VALID"), ("errors", "[str]", []), ("indicatorCode", "code", "ho-so-cap-do-phe-duyet"), ("periodCode", "pcode", "Q-2026-Q3"), ("value", "num", 1))
obj("ManualImport", "Phiên nhập tệp (xem trước rồi chốt).", ("importId!", "uuid"), ("fileName", "str", "nhap-so-lieu-q3.xlsx"), ("rows!", "[$ImportRow]"), ("validCount", "int", 1), ("invalidCount", "int", 0), ("expiresAt", "ts"))

# --- kỳ, tổng hợp (nhóm C)
obj("LastRun", "Lần tổng hợp gần nhất của kỳ.", ("runId!", "uuid"), ("state!", "E:RunState", "SUCCEEDED"), ("finishedAt", "ts"), ("completeness", "ratio"))
obj("ReportingPeriod", "Kỳ báo cáo (kpi_reporting_period).", PC, ("periodType!", "E:PeriodType", "MONTH"), ("startDate!", "date", "2026-10-01"), ("endDate!", "date", "2026-10-31"),
    ("state!", "E:PeriodState", "COMPUTED"), ("closeDueDate", "date", "2026-11-05"), ("lastRun", "$LastRun"), ("completeness", "ratio"), ("flags", "[E:RunFlag]", []), ("closedBy", "str", "tran.van.nam"),
    ("closedAt", "ts"), ("officialRunId", "uuid"), ("reopenReason", "str", "Phát hiện số trễ của PH-19 ngày 29/10."))
page("PeriodPage", "ReportingPeriod")
obj("PeriodCreate", "Tạo kỳ ngoài lịch tự sinh (FR-16-017); mã sai mẫu, trùng, ở tương lai trả ERR-16-024.", ("periodCode!", "pcode", "Q-2026-Q3"), ("reason", "str", "Kỳ quý cho báo cáo gửi Bộ.", {"maxLength": 500}))
obj("RunCounts", "Số đếm của lần tổng hợp.", ("indicatorTotal!", "int", 24), ("indicatorComputed!", "int", 22), ("noData", "int", 2))
obj("RunStage", "Một bước của lần tổng hợp (sáu bước), dùng cho lưới tác vụ.", ("stage!", "str", "COLLECT", {"maxLength": 32}), ("state!", "str", "SUCCEEDED", {"maxLength": 16}), ("durationMs", "int", 1200))
obj("Run", "Lần tổng hợp (kpi_aggregation_run).", ("runId!", "uuid"), PC, ("trigger!", "E:RunTrigger", "MANUAL"), ("state!", "E:RunState", "SUCCEEDED"), ("requestedBy", "str", "nguyen.thi.lan"),
    ("reason", "str", "Chạy lại sau khi PH-19 đẩy số trễ."), ("startedAt", "ts"), ("finishedAt", "ts"), ("completeness", "ratio"), ("flags", "[E:RunFlag]", ["MANUAL_PENDING"]), ("counts", "$RunCounts"),
    ("errorCode", "str", "ERR-16-110", {"pattern": "^ERR-16-[0-9]{3}$"}), ("stages", "[$RunStage]"))
page("RunPage", "Run")
obj("RunCreate", "Chạy tổng hợp thủ công (FR-16-018); kỳ đã chốt trả ERR-16-022, đang chạy trả ERR-16-023.", ("trigger", "E:RunTrigger", "MANUAL"), ("indicatorCodes", "[code]", ["mttd", "mttr-muc-1"]),
    ("reason", "str", "Chạy lại sau khi PH-13 bổ sung chỉ số sự cố.", {"maxLength": 2000}))
obj("IndicatorValue", "Giá trị chỉ tiêu trong kỳ (kpi_indicator_value).", ("valueId!", "uuid"), IND, PC, ("value", "num", 82.5), ("displayValue", "str", "82,5"), ("unit", "str", "%"),
    ("versionUsed!", "int", 2), ("status!", "E:ValueStatus", "AT_RISK"), ("completeness!", "E:Completeness", "COMPLETE"), ("flags", "[E:RunFlag]", []), ("missingMetrics", "[mcode]", []),
    ("threshold", "E:ThresholdLevel", "AMBER"), ("delta", "num", -3.5), ("deltaYoY", "num", 12.0), ("trend", "E:Trend", "DOWN"), ("runId", "uuid"), ("computedAt", "ts"), ("provisional", "bool", False))
page("ValuePage", "IndicatorValue")
obj("LineageInput", "Một đầu vào của giá trị.", ("variable!", "str", "tong"), ("sourceKind!", "E:LineageSourceKind", "OBSERVATION"),
    ("metricCode", "mcode", "ph01.httt.total"), ("observationId", "uuid"), ("manualId", "uuid"), ("value!", "num", 200))
obj("Lineage", "Dòng truy nguồn của một giá trị (FR-16-019).", ("valueId!", "uuid"), IND, ("versionUsed!", "int", 2), ("formula!", "str", 'obs("ph01.httt.connected") / obs("ph01.httt.total") * 100'), ("inputs!", "[$LineageInput]"))
obj("StatusChange", "Đổi trạng thái chỉ tiêu trong kỳ.", IND, PC, ("from", "E:ValueStatus", "ON_TRACK"), ("to!", "E:ValueStatus", "AT_RISK"), ("runId", "uuid"), ("at!", "ts"), ("value", "num", 82.5))
page("StatusChangePage", "StatusChange")
obj("RecomputeRequest", "Tính lại kỳ chưa chốt (FR-16-023).", ("reason!", "str", "Đổi công thức chỉ tiêu api-dat-sla-ty-le đã duyệt ngày 25/11.", R20), ("indicatorCodes", "[code]", ["api-dat-sla-ty-le"]))
obj("PeriodClose", "Chốt kỳ; `confirmPartial` khi còn chỉ tiêu `PARTIAL` (FR-16-024).", ("confirmPartial", "bool", False))
obj("PeriodReopen", "Mở lại kỳ đã chốt; lý do từ 50 ký tự (FR-16-024).", ("reason!", "str", "Phát hiện số liệu trễ của PH-19 ảnh hưởng chỉ tiêu bắt buộc, cần tính lại trước khi công bố.", R50), ("indicatorCodes", "[code]", ["doi-soat-tu-dong-khop"]))

# --- mẫu báo cáo, báo cáo (nhóm D)
obj("Section", "Phần của mẫu báo cáo.", ("sectionId", "str", "s1"), ("type!", "E:SectionType", "INDICATOR_TABLE"), ("title", "str", "Chỉ tiêu nhóm Kết nối"), ("indicatorCodes", "[code]", ["httt-ket-noi-ty-le"]),
    ("groupCode", "E:GroupCode", "KET_NOI"), ("chartType", "str", "bar"))
obj("Letterhead", "Tiêu đề thể thức (NĐ 30/2020).", ("issuer", "str", "UBND tỉnh T68"), ("formNo", "str", "BM-KPI-01"), ("recipients", "str", "Bộ Khoa học và Công nghệ"))
obj("ReportTemplate", "Mẫu báo cáo (kpi_report_template).", ("templateCode!", "code", "bao-cao-thang-mau"), ("name!", "str", "Báo cáo chỉ tiêu tháng"), ("reportType!", "E:ReportType", "PERIODIC"),
    ("periodTypes", "[E:PeriodType]", ["MONTH"]), ("sections!", "[$Section]"), ("formats!", "[E:Format]", ["PDF", "XLSX"]), ("letterhead", "$Letterhead"), ("state!", "E:TemplateState", "ACTIVE"),
    ("version!", "int", 1), *AUD)
page("TemplatePage", "ReportTemplate")
obj("TemplateCreate", "Tạo mẫu báo cáo (FR-16-025); phần không hợp lệ trả ERR-16-027.", ("templateCode!", "code", "bao-cao-thang-mau"), ("name!", "str", "Báo cáo chỉ tiêu tháng"), ("reportType!", "E:ReportType", "PERIODIC"),
    ("periodTypes", "[E:PeriodType]", ["MONTH"]), ("sections!", "[$Section]"), ("formats!", "[E:Format]", ["PDF", "XLSX"]), ("letterhead", "$Letterhead"))
obj("TemplatePatch", "Sửa mẫu; gửi các trường cần đổi.", ("name", "str", "Báo cáo chỉ tiêu tháng"), ("sections", "[$Section]"), ("formats", "[E:Format]", ["PDF"]), ("letterhead", "$Letterhead"))
obj("TemplatePreviewRequest", "Xem trước mẫu với một kỳ đã tính; bỏ trống thì dùng kỳ gần nhất.", ("periodCode", "pcode", "M-2026-10"))
obj("TemplatePreview", "Liên kết PDF tạm, hết hạn sau 1 giờ.", ("templateCode!", "code", "bao-cao-thang-mau"), ("previewUrl!", "url"), ("expiresAt!", "ts"))
obj("ReportSectionText", "Thuyết minh một phần báo cáo.", ("sectionId!", "str", "s1"), ("content!", "str", "Trong tháng 10, số HTTT kết nối tăng 6 hệ thống.", {"maxLength": 20000}))
obj("Explanation", "Giải trình chỉ tiêu chệch (FR-16-027).", IND, ("cause!", "str", "Hai HTTT chưa hoàn tất nâng cấp giao thức kết nối."), ("action!", "str", "Hoàn tất nâng cấp trước ngày 15/12."), ("dueDate", "date", "2026-12-15"))
obj("Signature", "Chữ ký số của bản công bố.", ("signer!", "str", "tran.van.nam"), ("signedAt!", "ts"), ("certificateSerial", "str", "5F3A9C01"), ("format", "str", "PAdES-B-LT"))
obj("SubmitCheck", "Một điều kiện gửi duyệt của báo cáo.", ("check!", "str", "completeness", {"maxLength": 32}), ("passed!", "bool", True), ("message", "str", "Đủ giải trình cho chỉ tiêu bắt buộc."))
obj("Report", "Báo cáo (kpi_report và phiên bản hiện hành).", RC, ("title!", "str", "Báo cáo chỉ tiêu tháng 10/2026"), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode", "pcode"),
    ("rangeFrom", "date", "2026-05-01"), ("rangeTo", "date", "2026-10-31"), ("templateCode", "code", "bao-cao-thang-mau"), ("state!", "E:ReportState", "DRAFT"), ("latestVersion!", "int", 1),
    ("publishedVersion", "int", 1), ("runId", "uuid"), ("completeness", "E:Completeness", "COMPLETE"), ("requiredExplanations", "[code]", ["api-dat-sla-ty-le"]), ("missingExplanations", "[code]", []),
    ("sections", "[$ReportSectionText]"), ("explanations", "[$Explanation]"), ("preparedBy", "str", "nguyen.thi.lan"), ("submittedBy", "str", "nguyen.thi.lan"), ("reviewedBy", "str", "tran.van.nam"),
    ("comment", "str", "Đồng ý công bố."), ("publishedAt", "ts"), ("contentHash", "sha"), ("signature", "$Signature"), ("wormRef", "str", "kpi-reports/t68/bc-thang-2026-10/v1.pdf"), ("newerRunId", "uuid"), ("submitChecks", "[$SubmitCheck]"),
    ("documentNumber", "str", "125/BC-STTTT", {"maxLength": 64}), ("recipientsNote", "str", "UBND tỉnh; Bộ KH&CN.", {"maxLength": 2000}), ("needsCorrection", "bool", False), *AUD)
obj("ReportSummary", "Dòng danh sách báo cáo.", RC, ("title!", "str", "Báo cáo chỉ tiêu tháng 10/2026"), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode", "pcode"),
    ("state!", "E:ReportState", "PUBLISHED"), ("latestVersion!", "int", 1), ("publishedAt", "ts"), ("needsCorrection", "bool", False))
page("ReportPage", "ReportSummary")
obj("ReportCreate", "Lập bản nháp báo cáo định kỳ (FR-16-026) hoặc đột xuất (FR-16-032, `reportType = AD_HOC`).", ("reportCode!", "rcode"), ("templateCode", "code", "bao-cao-thang-mau"),
    ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode", "pcode", "M-2026-10"), ("title!", "str", "Báo cáo chỉ tiêu tháng 10/2026", {"maxLength": 255}),
    ("from", "date", "2026-05-01"), ("to", "date", "2026-10-31"), ("indicatorCodes", "[code]", ["httt-ket-noi-ty-le", "mttd"], {"minItems": 1, "maxItems": 50}))
obj("ReportPatch", "Sửa báo cáo `DRAFT` hoặc `CHANGES_REQUESTED` (FR-16-027); báo cáo đã công bố trả ERR-16-032.", ("title", "str", "Báo cáo chỉ tiêu tháng 10/2026"), ("sections", "[$ReportSectionText]"),
    ("documentNumber", "str", "125/BC-STTTT", {"maxLength": 64}), ("recipientsNote", "str", "UBND tỉnh; Bộ KH&CN.", {"maxLength": 2000}))
obj("ExplanationPut", "Lưu giải trình (FR-16-027).", ("cause!", "str", "Hai HTTT chưa hoàn tất nâng cấp giao thức kết nối.", {"minLength": 1, "maxLength": 2000}),
    ("action!", "str", "Hoàn tất nâng cấp trước ngày 15/12.", {"minLength": 1, "maxLength": 2000}), ("dueDate", "date", "2026-12-15"))
obj("ExplanationResult", "Giải trình đã lưu và danh sách còn thiếu.", ("explanation!", "$Explanation"), ("missingExplanations!", "[code]", []))
obj("RefreshRequest", "Làm mới số liệu bản nháp từ lần tổng hợp mới nhất (FR-16-023).", ("reason", "str", "Làm mới sau khi tính lại kỳ.", {"maxLength": 2000}))
obj("ReportPreview", "Xem trước báo cáo nháp.", RC, ("version!", "int", 1), ("previewUrl!", "url"), ("expiresAt!", "ts"), ("provisional", "bool", True), ("missingExplanations", "[code]", []))
obj("PublishRequest", "Công bố: chụp bất biến, ký số, lưu WORM (FR-16-029).", ("publishNote", "str", "Công bố báo cáo tháng 10.", {"maxLength": 2000}))
obj("CorrectRequest", "Đính chính bằng phiên bản mới (FR-16-030).", ("reason!", "str", "Sửa số liệu chỉ tiêu mttd do PH-13 hiệu chỉnh lại số sự cố tháng 10.", R50),
    ("correctionNote!", "str", "Bản này thay thế bản 1: sửa chỉ tiêu mttd từ 42 phút còn 38 phút.", {"minLength": 1, "maxLength": 2000}))
obj("ReportVersion", "Phiên bản báo cáo.", ("version!", "int", 1), ("state!", "E:ReportState", "PUBLISHED"), ("runId", "uuid"), ("preparedBy", "str", "nguyen.thi.lan"), ("publishedAt", "ts"),
    ("contentHash", "sha"), ("correctionOf", "int", 1), ("correctionReason", "str", "Sửa số liệu mttd."))
page("ReportVersionPage", "ReportVersion")
obj("ReviewItem", "Việc chờ duyệt hoặc xác nhận của người dùng.", ("itemType!", "E:ReviewItemType", "REPORT"), ("ref!", "str", "bc-thang-2026-10"), ("title!", "str", "Báo cáo chỉ tiêu tháng 10/2026"),
    ("submittedBy", "str", "nguyen.thi.lan"), ("submittedAt", "ts"), ("periodCode", "pcode", "M-2026-10"), ("link", "str", "/giam-sat/chi-tieu/duyet"), ("ownedByMe", "bool", False))
obj("ReviewFacets", "Số việc chờ theo loại.", ("INDICATOR_VERSION", "int", 2), ("MANUAL_VALUE", "int", 5), ("REPORT", "int", 1))
obj("ReviewQueuePage", "Trang việc chờ duyệt; `facets` đếm theo loại việc, `ownedByMe` khóa nút bốn mắt ngay ở danh sách.", ("items!", "[$ReviewItem]"), ("page!", "int", 0), ("size!", "int", 20), ("totalElements!", "int", 1), ("facets", "$ReviewFacets"))

# --- xuất, phân phối (nhóm E)
obj("ExportRef", "Đối tượng cần xuất.", ("reportCode", "rcode"), ("version", "int", 1), ("periodCode", "pcode", "M-2026-10"), ("filter", "obj", {"groupCode": "KET_NOI"}),
    ("rootComponent", "code", "httt-qlvb"), ("depth", "int", 2, {"minimum": 1, "maximum": 5}))
obj("ExportCreate", "Yêu cầu xuất (FR-16-033, 049); vượt `16.export.max-rows` trả ERR-16-034.", ("subject!", "E:ExportSubject", "REPORT"), ("subjectRef!", "$ExportRef"), ("format!", "E:Format", "PDF"))
obj("ExportJob", "Việc xuất (kpi_export_job).", ("exportId!", "uuid"), ("subject!", "E:ExportSubject", "REPORT"), ("format!", "E:Format", "PDF"), ("state!", "E:ExportState", "SUCCEEDED"),
    ("requestedBy", "str", "nguyen.thi.lan"), ("rowCount", "int", 24), ("sha256", "sha"), ("downloadUrl", "url"), ("expiresAt", "ts"), ("errorCode", "str", "ERR-16-115", {"pattern": "^ERR-16-[0-9]{3}$"}), *AUD)
obj("Recipient", "Người nhận phân phối.", ("type!", "E:RecipientType", "EMAIL"), ("ref!", "str", "lanh-dao@t68.gov.vn"))
obj("Distribution", "Danh sách phân phối (kpi_distribution).", ("distributionCode!", "code", "lanh-dao-tinh"), ("name!", "str", "Lãnh đạo UBND tỉnh"), ("reportTypes", "[E:ReportType]", ["PERIODIC"]),
    ("periodTypes", "[E:PeriodType]", ["MONTH", "QUARTER"]), ("recipients!", "[$Recipient]"), ("attach", "E:DistributionAttach", "LINK"), ("active!", "bool", True), *AUD)
page("DistributionPage", "Distribution")
obj("DistributionCreate", "Tạo danh sách phân phối (FR-16-034); thư ngoài miền công vụ trả ERR-16-036.", ("distributionCode!", "code", "lanh-dao-tinh"), ("name!", "str", "Lãnh đạo UBND tỉnh"),
    ("reportTypes", "[E:ReportType]", ["PERIODIC"]), ("periodTypes", "[E:PeriodType]", ["MONTH", "QUARTER"]), ("recipients!", "[$Recipient]"), ("attach", "E:DistributionAttach", "LINK"), ("active", "bool", True))
obj("DistributionPatch", "Sửa danh sách phân phối; gửi các trường cần đổi.", ("name", "str", "Lãnh đạo UBND tỉnh"), ("reportTypes", "[E:ReportType]", ["PERIODIC"]), ("periodTypes", "[E:PeriodType]", ["MONTH"]),
    ("recipients", "[$Recipient]"), ("attach", "E:DistributionAttach", "PDF"), ("active", "bool", False))
obj("Delivery", "Lần gửi phân phối (kpi_delivery).", RC, ("version", "int", 1), ("recipient!", "str", "lanh-dao@t68.gov.vn"), ("state!", "E:DeliveryState", "SENT"), ("attempt", "int", 1), ("sentAt", "ts"),
    ("errorCode", "str", "ERR-16-116", {"pattern": "^ERR-16-[0-9]{3}$"}))
page("DeliveryPage", "Delivery")
obj("FeedValue", "Giá trị chỉ tiêu cung cấp cho hệ khác (`kpi.read`).", IND, PC, ("value", "num", 82.5), ("unit", "str", "%"), ("status!", "E:ValueStatus", "AT_RISK"), ("completeness!", "E:Completeness", "COMPLETE"),
    ("version", "int", 2), ("reportCode", "rcode"), ("provisional!", "bool", False))
page("FeedValuePage", "FeedValue")
obj("FeedReport", "Báo cáo đã công bố cung cấp cho hệ khác.", RC, ("title", "str", "Báo cáo chỉ tiêu tháng 10/2026"), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode", "pcode"),
    ("version!", "int", 1), ("publishedAt!", "ts"), ("contentHash", "sha"), ("downloadUrl", "url"))
page("FeedReportPage", "FeedReport")
obj("PublishEvidence", "Bằng chứng công bố (FR-16-036); mã băm hoặc chữ ký không khớp ghi ERR-16-124.", RC, ("version!", "int", 1), ("verified!", "bool", True), ("contentHash!", "sha"), ("signature", "$Signature"),
    ("downloadUrl", "url"), ("expiresAt", "ts"))

# --- bảng điều khiển (nhóm F)
obj("Card", "Thẻ chỉ tiêu (FR-16-037).", IND, ("name!", "str", "Tỷ lệ HTTT kết nối nền tảng"), ("displayValue!", "str", "82,5"), ("unit", "str", "%"), ("status!", "E:ValueStatus", "AT_RISK"),
    ("trend", "E:Trend", "UP"), PC, ("link", "str", "/giam-sat/chi-tieu/chi-so/httt-ket-noi-ty-le"))
obj("CardSet", "Thẻ chỉ tiêu cho trang `/tong-quan`; `limit` 1…8, mặc định 4.", ("cards!", "[$Card]"))
obj("GroupScore", "Điểm nhóm (kpi_group_score).", ("groupCode!", "E:GroupCode", "KET_NOI"), ("score", "pct"), ("coverage", "ratio"), ("weight!", "num", 20), ("delta", "num", 2.1), ("trend", "E:Trend", "UP"))
obj("StatusCounts", "Số chỉ tiêu theo trạng thái.", ("ON_TRACK!", "int", 12), ("AT_RISK!", "int", 6), ("OFF_TRACK!", "int", 2), ("NO_DATA!", "int", 4))
obj("AttentionItem", "Chỉ tiêu cần chú ý.", IND, ("name!", "str", "Tỷ lệ API đạt SLA"), ("status!", "E:ValueStatus", "OFF_TRACK"), ("displayValue", "str", "71,0"), ("targetDisplay", "str", "90"))
obj("SeriesPoint", "Điểm chuỗi thời gian.", PC, ("value", "num", 82.5), ("status", "E:ValueStatus", "AT_RISK"), ("completeness", "E:Completeness", "COMPLETE"), ("version", "int", 2))
obj("CompareItem", "So sánh hai kỳ (FR-16-040).", IND, ("valueA", "num", 82.5), ("valueB", "num", 78.0), ("delta", "num", 4.5), ("deltaPct", "num", 5.8), ("statusA", "E:ValueStatus", "AT_RISK"),
    ("statusB", "E:ValueStatus", "AT_RISK"), ("definitionChanged", "bool", False))
obj("Dashboard", "Bảng điều khiển năm nhóm (FR-16-038); `view` `OFFICIAL` chỉ kỳ đã chốt, `LATEST` gồm số tạm.", PC, ("view!", "E:DashboardView", "LATEST"), ("overallScore", "pct", 76.4),
    ("groups!", "[$GroupScore]"), ("statusCounts!", "$StatusCounts"), ("attention", "[$AttentionItem]"), ("series", "[$SeriesPoint]"), ("flags", "[E:RunFlag]", ["MANUAL_PENDING"]), ("provisional!", "bool", True),
    ("comparison", "[$CompareItem]"), ("periodState", "E:PeriodState", "COMPUTED"), ("staleSources", "[code]", ["ph08-dq-kpi"]), ("yoy", "[$CompareItem]"))
obj("Series", "Chuỗi thời gian một chỉ tiêu (FR-16-039).", IND, ("definition", "$IndicatorVersion"), ("series!", "[$SeriesPoint]"), ("targetLine", "num", 90), ("lineage", "[$Lineage]"))
obj("ComparisonDistribution", "Phân bố giá trị giữa các tenant.", ("min", "num", 40), ("p25", "num", 55), ("median", "num", 68), ("p75", "num", 80), ("max", "num", 92))
obj("ComparisonTenant", "Giá trị một tenant, ẩn danh.", ("alias!", "str", "Tỉnh A"), ("value", "num", 68), ("status", "E:ValueStatus", "AT_RISK"))
obj("Comparison", "So sánh liên tenant ẩn danh (FR-16-041); dưới `16.compare.min-tenants` trả ERR-16-038.", IND, PC, ("distribution!", "$ComparisonDistribution"), ("tenants!", "[$ComparisonTenant]"), ("tenantCount!", "int", 5), ("rank", "int", 2), ("peerCount", "int", 4))
obj("StatusTally", "Số đếm theo trạng thái.", ("ACTIVE", "int", 20), ("STALE", "int", 1), ("FAILED", "int", 0), ("PAUSED", "int", 1))
obj("ExportTally", "Số đếm việc xuất.", ("running", "int", 0), ("failed24h", "int", 0))
obj("NationalTally", "Số đếm gói quốc gia.", ("pending", "int", 0), ("failed", "int", 0), ("lastAcknowledgedAt", "ts"))
obj("OpsOverview", "Tình trạng thu thập, tính toán (FR-16-042).", ("sources!", "$StatusTally"), ("runs!", "[$Run]"), ("exports", "$ExportTally"), ("national", "$NationalTally"), ("outboxLagSeconds!", "int", 2))

# --- sổ kiến trúc (nhóm G)
obj("DependencyRef", "Phụ thuộc của thành phần.", CC, ("dependencyType!", "E:DependencyType", "CALLS"), ("kind", "E:DependencyKind", "MANUAL"))
obj("ComponentVersion", "Phiên bản thành phần.", ("version!", "str", "2.3.0", {"description": "Nhãn phiên bản (`version_label`)."}), ("lifecycle", "E:Lifecycle", "ACTIVE"), ("releasedOn", "date", "2026-10-15"),
    ("specRef", "str", "https://git.t68.example.vn/specs/qlvb"), ("contentHash", "sha"), ("origin", "E:Origin", "AUTO"), ("changeNote", "str", "Nâng cấp giao thức kết nối."))
obj("ArchComponent", "Thành phần kiến trúc (kpi_arch_component).", CC, ("name!", "str", "Hệ thống quản lý văn bản tỉnh"), ("componentType!", "E:ComponentType", "HTTT"), ("lifecycle!", "E:Lifecycle", "ACTIVE"),
    ("opsStatus!", "E:OpsStatus", "UP"), ("opsStatusAt", "ts"), ("origin!", "E:Origin", "MANUAL"), ("complianceLevel!", "E:ComplianceLevel", "PARTIAL"), ("currentVersion", "str", "2.3.0"),
    ("ownerOrgId", "str", "org-vp-ubnd"), ("ownerOrgName", "str", "Văn phòng UBND tỉnh"), ("description", "str", "Phục vụ văn bản điện tử liên thông"), ("externalRef", "str", "000.00.68.H01"),
    ("sourceRef", "str", "ph01:httt-qlvb"), ("reconFlag", "str", "OK"), ("versions", "[$ComponentVersion]"), ("dependencies", "[$DependencyRef]"), ("lastSyncedAt", "ts"), *AUD)
obj("ArchComponentPage", "Trang thành phần kèm số đếm.", ("items!", "[$ArchComponent]"), ("page!", "int", 0), ("size!", "int", 20), ("totalElements!", "int", 1), ("facets", "$Facets"))
obj("ComponentCreate", "Khai báo thành phần thủ công (FR-16-045).", CC, ("name!", "str", "Hệ thống quản lý văn bản tỉnh", {"minLength": 1, "maxLength": 255}), ("componentType!", "E:ComponentType", "HTTT"),
    ("lifecycle!", "E:Lifecycle", "ACTIVE"), ("ownerOrgId!", "str", "org-vp-ubnd"), ("description", "str", "Phục vụ văn bản điện tử liên thông", {"maxLength": 4000}),
    ("externalRef", "str", "000.00.68.H01"), ("dependsOn", "[code]", ["api-tra-cuu-ho-tich"]))
obj("ComponentPatch", "Sửa thành phần; trường do phân hệ nguồn quản lý trả ERR-16-040.", ("name", "str", "Hệ thống quản lý văn bản tỉnh"), ("ownerOrgId", "str", "org-vp-ubnd"),
    ("description", "str", "Phục vụ văn bản điện tử liên thông"), ("externalRef", "str", "000.00.68.H01"))
obj("ComponentVersionAdd", "Thêm phiên bản thành phần.", ("version!", "str", "2.4.0"), ("releasedOn", "date", "2026-11-20"), ("specRef", "str", "https://git.t68.example.vn/specs/qlvb"), ("contentHash", "sha"),
    ("changeNote", "str", "Thêm chức năng ký số."))
obj("DependenciesPut", "Thay toàn bộ phụ thuộc; vòng hoặc tới thành phần đã ngừng trả ERR-16-041.", ("dependsOn!", "[$DependencyRef]"))
obj("ComponentDependencies", "Phụ thuộc sau khi đặt.", CC, ("dependencies!", "[$DependencyRef]"))
obj("LifecycleChange", "Chuyển vòng đời (FR-16-045); còn thành phần hoạt động phụ thuộc trả ERR-16-042.", ("lifecycle!", "E:Lifecycle", "DEPRECATED"), ("reason", "str", "Chuyển sang hệ thống mới từ 01/2027.", {"maxLength": 2000}))
obj("ArchIngestItem", "Thành phần đẩy vào qua `arch.register` (FR-16-044).", CC, ("componentType!", "E:ComponentType", "API"), ("name!", "str", "API tra cứu hộ tịch"), ("version", "str", "1.4.0"),
    ("lifecycle", "E:Lifecycle", "ACTIVE"), ("sourceRef", "str", "ph02:api-tra-cuu-ho-tich"), ("dependsOn", "[code]", ["httt-ho-tich"]), ("contentHash", "sha"))
obj("ArchIngestBatch", "Lô thành phần từ PH-01, PH-02, PH-04, PH-10, CI/GitOps.", ("components!", "[$ArchIngestItem]", None, {"minItems": 1, "maxItems": 500}))
obj("ArchIngestItemResult", "Kết quả từng thành phần.", CC, ("status!", "E:ArchIngestStatus", "CREATED"), ("code", "str", "ERR-16-039", {"pattern": "^ERR-16-[0-9]{3}$"}))
obj("ArchIngestResult", "Kết quả lô thành phần.", ("results!", "[$ArchIngestItemResult]", [{"componentCode": "api-tra-cuu-ho-tich", "status": "CREATED"}]))

# --- tuân thủ kiến trúc
obj("Criterion", "Tiêu chí tuân thủ (kpi_compliance_criterion).", ("criterionCode!", "str", "KT-ATTT-01"), ("name!", "str", "Có hồ sơ cấp độ an toàn thông tin"), ("description", "str", "Theo Khung KT CPĐT 3.0"),
    ("appliesTo", "[E:ComponentType]", ["HTTT"]), ("mandatory", "bool", True), ("weight", "num", 10), ("frameworkRef", "str", "CMP-LAW-10"))
obj("CriteriaSet", "Phiên bản bộ tiêu chí.", ("version!", "int", 2), ("name", "str", "Bộ tiêu chí theo Khung KT CPĐT 3.0"), ("state!", "E:CriteriaSetState", "ACTIVE"), ("criteria!", "[$Criterion]"), ("activatedAt", "ts"), *AUD)
page("CriteriaSetPage", "CriteriaSet")
obj("CriteriaSetCreate", "Tạo phiên bản bộ tiêu chí `DRAFT` (FR-16-047); sai trả ERR-16-045.", ("name", "str", "Bộ tiêu chí theo Khung KT CPĐT 3.0"), ("criteria!", "[$Criterion]"))
obj("AssessmentItem", "Kết quả một tiêu chí.", ("criterionCode!", "str", "KT-ATTT-01"), ("result!", "E:CriterionResult", "PASS"), ("evidence", "str", "Quyết định cấp độ 3 số 123/QĐ-UBND"), ("note", "str", "Đạt."))
obj("Assessment", "Đánh giá tuân thủ (kpi_compliance_assessment).", ("assessmentId!", "uuid"), CC, ("criteriaSetVersion!", "int", 2), ("state!", "E:AssessmentState", "DRAFT"), ("results!", "[$AssessmentItem]"),
    ("proposedLevel", "E:ComplianceLevel", "PARTIAL"), ("confirmedLevel", "E:ComplianceLevel", "PARTIAL"), ("score", "pct", 70), ("assessedBy", "str", "nguyen.thi.lan"), ("submittedAt", "ts"),
    ("confirmedBy", "str", "tran.van.nam"), ("confirmedAt", "ts"), ("comment", "str", "Đã kiểm hồ sơ."), *AUD)
obj("AssessmentCreate", "Lập đánh giá nháp (FR-16-047).", ("criteriaSetVersion!", "int", 2), ("results", "[$AssessmentItem]"), ("proposedLevel", "E:ComplianceLevel", "PARTIAL"))
obj("AssessmentPatch", "Sửa đánh giá `DRAFT`; thiếu kết quả tiêu chí bắt buộc trả ERR-16-043 khi gửi.", ("results", "[$AssessmentItem]"), ("proposedLevel", "E:ComplianceLevel", "COMPLIANT"))
obj("WaiverCreate", "Miễn trừ có hạn (FR-16-047); quá `16.compliance.waiver-max-days` trả ERR-16-044.", ("criterionCode", "str", "KT-ATTT-01"), ("reason!", "str", "Hệ thống sẽ ngừng ngày 30/06/2027, không nâng cấp để đạt tiêu chí này.", R50),
    ("until!", "date", "2027-03-31"), ("planNote", "str", "Chuyển sang hệ thống mới trước hạn."))
obj("Waiver", "Miễn trừ (kpi_compliance_waiver).", ("waiverId!", "uuid"), CC, ("criterionCode", "str", "KT-ATTT-01"), ("reason!", "str", "Hệ thống sẽ ngừng ngày 30/06/2027."), ("until!", "date", "2027-03-31"),
    ("planNote", "str", "Chuyển sang hệ thống mới trước hạn."), ("state!", "E:WaiverState", "ACTIVE"), ("approvedBy", "str", "tran.van.nam"), ("approvedAt", "ts"))
obj("ReconRequest", "Đối chiếu sổ với phân hệ nguồn (FR-16-048); để trống là mọi loại.", ("componentTypes", "[E:ComponentType]", ["HTTT", "API"]))
obj("ReconItem", "Một mục lệch.", ("itemId!", "uuid"), ("kind!", "E:ReconItemKind", "MISSING"), CC, ("sourceRef", "str", "ph02:api-tra-cuu-ho-tich"), ("diff", "obj", {"version": {"registry": "1.3.0", "source": "1.4.0"}}),
    ("resolution!", "E:ReconResolution", "OPEN"), ("resolutionReason", "str", "Đã bổ sung vào sổ."))
obj("Reconciliation", "Lần đối chiếu sổ kiến trúc.", ("reconId!", "uuid"), ("state!", "E:ReconState", "SUCCEEDED"), ("items", "[$ReconItem]"), ("itemCount", "int", 1), ("requestedAt", "ts"), ("finishedAt", "ts"))
obj("ReconResolve", "Xử lý một mục lệch (FR-16-048 bước 4); `IGNORED` cần `reason` từ 20 ký tự.", ("resolution!", "E:ReconResolution", "REGISTERED"), ("reason", "str", "Nhận thành phần vào sổ theo dữ liệu của PH-02.", R20))

# --- gửi quốc gia (nhóm H)
obj("NationalTemplate", "Mẫu gói quốc gia có phiên bản (kpi_national_template).", ("templateCode!", "code", "goi-bao-cao-chi-tieu"), ("submissionType!", "E:SubmissionType", "KPI_REPORT"), ("version!", "int", 1),
    ("state!", "E:NationalTemplateState", "ACTIVE"), ("schema", "obj", {"type": "object"}), ("mapping", "obj", {"httt-ket-noi-ty-le": "chiSo01"}), ("channelRef", "str", "ndop-bao-cao"),
    ("effectiveFrom", "date", "2026-12-01"), ("testResult", "obj", {"passed": True}), *AUD)
page("NationalTemplatePage", "NationalTemplate")
obj("NationalTemplateCreate", "Tạo phiên bản mẫu gói (FR-16-050); lược đồ, ánh xạ sai trả ERR-16-047.", ("templateCode!", "code", "goi-bao-cao-chi-tieu"), ("submissionType!", "E:SubmissionType", "KPI_REPORT"),
    ("version", "int", 2), ("schema!", "obj", {"type": "object"}), ("mapping!", "obj", {"httt-ket-noi-ty-le": "chiSo01"}), ("channelRef!", "str", "ndop-bao-cao"), ("effectiveFrom", "date", "2026-12-01"))
obj("SubmissionCreate", "Lập gói (FR-16-051, 052); `16.national.enabled = false` trả ERR-16-046, báo cáo chưa công bố trả ERR-16-052.", ("submissionType!", "E:SubmissionType", "KPI_REPORT"),
    ("reportCode", "rcode"), ("version", "int", 1), ("templateCode", "code", "goi-bao-cao-chi-tieu"), ("mode", "E:SubmissionMode", "FULL"), ("componentTypes", "[E:ComponentType]", ["HTTT"]))
obj("Submission", "Gói gửi quốc gia (kpi_national_submission).", ("submissionId!", "uuid"), ("submissionType!", "E:SubmissionType", "KPI_REPORT"), ("state!", "E:SubmissionState", "PENDING"), ("reportCode", "rcode"),
    ("version", "int", 1), ("templateCode", "code", "goi-bao-cao-chi-tieu"), ("mode", "E:SubmissionMode", "FULL"), ("componentCount", "int", 12), ("contentHash", "sha"), ("preview", "obj", {"chiSo01": 82.5}),
    ("attemptCount", "int", 0), ("channelRef", "str", "ndop-bao-cao"), ("receiptNo", "str", "BN-2026-001234"), ("sentAt", "ts"), ("ackAt", "ts"), ("lastErrorCode", "str", "ERR-16-117", {"pattern": "^ERR-16-[0-9]{3}$"}),
    ("lastErrorDetail", "str", "Hệ quốc gia từ chối: thiếu trường chiSo03."), *AUD)
page("SubmissionPage", "Submission")
obj("SubmissionLog", "Dòng nhật ký nộp (kpi_national_submission_log).", ("at!", "ts"), ("event!", "E:SubmissionLogEvent", "SENDING"), ("channelMessageId", "str", "msg-0001"), ("status", "E:SubmissionState", "SENDING"), ("code", "str", "ERR-16-118"))
page("SubmissionLogPage", "SubmissionLog")
obj("ReceiptIn", "Biên nhận PH-14 trả về (FR-16-053).", ("submissionId!", "uuid"), ("channelMessageId!", "str", "msg-0001"), ("status!", "E:ReceiptStatus", "ACKNOWLEDGED"), ("receiptNo", "str", "BN-2026-001234"),
    ("contentHash", "sha"), ("rejectCode", "str", "E102"), ("rejectMessage", "str", "Thiếu trường chiSo03."))
obj("NationalReconRequest", "Đối soát sổ, gói đã nộp và chỉ tiêu (FR-16-054).", ("scope!", "E:NationalReconScope", "ALL"), ("asOf", "ts"))
obj("NationalReconItem", "Một mục lệch khi đối soát.", ("kind!", "str", "SUBMISSION_MISMATCH"), ("ref!", "str", "bc-thang-2026-10"), ("expected", "str", "82,5"), ("actual", "str", "82,0"), ("suggestion", "str", "Gửi lại gói."))
obj("NationalRecon", "Lần đối soát quốc gia.", ("reconId!", "uuid"), ("scope!", "E:NationalReconScope", "ALL"), ("state!", "E:RunState", "SUCCEEDED"), ("items", "[$NationalReconItem]"), ("requestedAt", "ts"))

# --- quản trị (nhóm I)
obj("Setting", "Tham số `16.*` của tenant.", ("key!", "str", "16.source.stale-hours", {"pattern": r"^16\.[a-z][a-z.-]*$"}), ("value!", "any", 26), ("default", "any", 26), ("ceiling", "any", 168),
    ("scope", "E:SettingScope", "TENANT"), ("updatedBy", "str", "nguyen.thi.lan"), ("updatedAt", "ts"))
obj("Settings", "Danh sách tham số.", ("settings!", "[$Setting]"))
obj("SettingPatchItem", "Một tham số cần đổi; ngoài miền hoặc vượt trần trả ERR-16-051.", ("key!", "str", "16.source.stale-hours", {"pattern": r"^16\.[a-z][a-z.-]*$"}), ("value!", "any", 30))
obj("SettingsPatch", "Sửa tham số (FR-16-055).", ("settings!", "[$SettingPatchItem]"))
obj("AuditEvent", "Sự kiện kiểm toán PH-16 (đọc từ kho kiểm toán PH-13).", ("at!", "ts"), ("actor!", "str", "nguyen.thi.lan"), ("role", "str", "ROLE-TENANT_OPERATOR"), ("action!", "str", "REPORT_PUBLISH"),
    ("objectType!", "str", "report"), ("objectRef!", "str", "bc-thang-2026-10"), ("before", "obj", {}), ("after", "obj", {"state": "PUBLISHED"}), ("traceId", "str", "4bf92f3577b34da6a3ce929d0e0e4736"))
page("AuditPage", "AuditEvent")
obj("Partition", "Phân vùng bảng quan sát.", ("name!", "str", "kpi_observation_2026_10"), ("rowCount", "int", 184000), ("rangeFrom", "date", "2026-10-01"), ("rangeTo", "date", "2026-11-01"))
obj("RetentionStatus", "Tình trạng lưu giữ và dọn dữ liệu (FR-16-057).", ("partitions!", "[$Partition]"), ("lastPurgeAt", "ts"), ("nextPurgeAt", "ts"), ("bytesFreed", "int", 0))

# ---------------------------------------------------------------- tham số đường dẫn
PATHP = {"indicatorCode": ("code", "httt-ket-noi-ty-le"), "version": ("int", 3), "sourceCode": ("code", "ph08-dq-kpi"), "manualId": ("uuid", None), "importId": ("uuid", None),
         "periodCode": ("pcode", "M-2026-10"), "runId": ("uuid", None), "valueId": ("uuid", None), "templateCode": ("code", "bao-cao-thang-mau"), "reportCode": ("rcode", "bc-thang-2026-10"),
         "exportId": ("uuid", None), "distributionCode": ("code", "lanh-dao-tinh"), "componentCode": ("code", "httt-qlvb"), "assessmentId": ("uuid", None), "reconId": ("uuid", None),
         "itemId": ("uuid", None), "submissionId": ("uuid", None)}

for n in sorted(ENUMS):
    SCH.setdefault(n, enum_schema(n))
