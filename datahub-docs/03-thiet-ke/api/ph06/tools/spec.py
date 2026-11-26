#!/usr/bin/env python3
"""Nguồn duy nhất của hợp đồng API PH-06: đọc FRS §9.4 (mã, phương thức, đường dẫn), tách dòng gộp, bảng operation, lược đồ.

Không chạy trực tiếp; gen_openapi.py, gen_asyncapi.py, check_contracts.py, doi_chieu_frs.py nhập module này.
Enum lấy thẳng từ Phụ lục A của FRS (E('Tên')), nên không thể lệch FRS.
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS_PATH = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH06-frs-du-lieu-chu.md")
FRS = open(FRS_PATH, encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]

# ---------------------------------------------------------------- FRS
ERR = {}  # mã -> (danh sách HTTP, ý nghĩa)
_s91 = FRS[FRS.index("### 9.1."):FRS.index("### 9.2.")]
for m in re.finditer(r"^\| (ERR-06-\d{3}) \| ([^|]+?) \| ([^|]+?) \|", _s91, re.M):
    ERR[m.group(1)] = ([int(x) for x in re.findall(r"\d{3}", m.group(2))], m.group(3).strip())
EVT = [(m.group(1), m.group(2), m.group(3).strip(), m.group(4).strip()) for m in
       re.finditer(r"^\| (EVT-06-\d{2}) \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \|", FRS, re.M)]
PERMS = sorted(set(re.findall(r"PERM-06-[a-z-]+", FRS)))


def E(name):
    m = re.search(r"^\| `%s` \| ([^|]+) \|" % name, APPX, re.M)
    if not m:
        raise SystemExit("Không có enum %s ở Phụ lục A" % name)
    return re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(1)))


def fr_errs():
    """Với mỗi FR: tập (mã ERR, HTTP) ở mục Luồng ngoại lệ."""
    out = {}
    for m in re.finditer(r"#### (FR-06-\d{3}) · [^\n]+\n\n::: dac-ta\n(.*?)\n:::", FRS, re.S):
        x = re.search(r"\*\*Luồng ngoại lệ\.\*\*\s*(.*?)(?=\n\n\*\*|\Z)", m.group(2), re.S)
        out[m.group(1)] = sorted(set((a, int(b)) for a, b in re.findall(r"(ERR-06-\d{3}) \((\d{3})\)", x.group(1)))) if x else []
    return out


FRERR = fr_errs()

# ---------------------------------------------------------------- operation theo FRS §9.4, tách dòng gộp
ROWS = []  # (mã 3 số, phương thức, đường dẫn đã mở rộng, hành động hoặc None, [FR], mã gốc)
_sec = FRS[FRS.index("### 9.4."):FRS.index("## 10. Giao diện")]
_extra = 96
for m in re.finditer(r"^\| API-06-(\d{3}) \| `([A-Z]+) ([^`]+)` \| ([^|]+) \|", _sec, re.M):
    code, meth, path, frs_ = m.group(1), m.group(2), m.group(3), [f"FR-06-{x}" for x in re.findall(r"\d{3}", m.group(4))]
    g = re.search(r"\{([a-z,-]+)\}$", path)
    if g and ":" in path:
        acts = g.group(1).split(",")
        for i, a in enumerate(acts):
            if i == 0:
                c = code
            else:
                _extra += 1
                c = "%03d" % _extra
            ROWS.append((c, meth, path[:g.start()] + a, a, frs_, code))
    else:
        ROWS.append((code, meth, path, None, frs_, code))
ROWS.sort(key=lambda r: r[0])
assert len(ROWS) == 125, len(ROWS)
SPLIT = [(r[5], r[0]) for r in ROWS if r[0] > "096"]

# ---------------------------------------------------------------- bảng operation
# mã | tóm tắt | nhóm | quyền | thân yêu cầu | thân phản hồi | HTTP | truy vấn | cờ
# cờ: idem (Idempotency-Key), noifm, purpose (X-Purpose), m:scope (HTTT với scope), only:scope (chỉ HTTT), multipart, binary, also:HTTP
OPS_TXT = """
001|Danh sách, tìm kiếm domain|Domain và mô hình|read|-|DomainPage|200|status:E:DomainStatus,q:str,page,size|
002|Chi tiết domain|Domain và mô hình|read|-|DomainDetail|200|version:int|
003|Tạo domain|Domain và mô hình|config|DomainCreate|Domain|201|-|idem
004|Danh sách phiên bản mô hình|Domain và mô hình|read|-|ModelVersionPage|200|status:E:VersionStatus,page,size|
005|Tạo phiên bản mô hình nháp|Domain và mô hình|config|ModelVersionCreate|ModelVersion|201|-|idem
006|Sửa phiên bản mô hình nháp|Domain và mô hình|config|ModelVersionUpdate|ModelVersion|200|-|
007|So sánh hai phiên bản mô hình|Domain và mô hình|read|-|ModelDiff|200|with:int|
008|Gửi duyệt phiên bản mô hình|Domain và mô hình|config|CommentBody|ModelVersion|200|-|
009|Duyệt phiên bản mô hình|Domain và mô hình|approve|CommentBody|ModelVersion|200|-|
010|Từ chối phiên bản mô hình|Domain và mô hình|approve|RejectBody|ModelVersion|200|-|
011|Tạm ngừng domain|Domain và mô hình|config|ReasonBody|Domain|200|-|
097|Tiếp tục domain|Domain và mô hình|config|ReasonBody|Domain|200|-|
098|Ngừng domain|Domain và mô hình|config|ReasonBody|Domain|200|-|
012|Nạp gói domain nền|Domain và mô hình|config|InstallBaselineRequest|InstallBaselineResult|200|-|
013|Thử bộ kiểm tra khóa định danh|Domain và mô hình|config|IdentifierTestRequest|IdentifierTestResult|200|-|noifm
014|Danh sách nguồn|Nguồn và ưu tiên nguồn|read|-|SourcePage|200|status:E:SourceStatus,kind:E:SourceKind,domainCode:dcode,page,size|
015|Đăng ký nguồn|Nguồn và ưu tiên nguồn|config|SourceCreate|Source|201|-|idem
016|Sửa nguồn|Nguồn và ưu tiên nguồn|config|SourceUpdate|Source|200|-|
017|Tạm ngừng nguồn|Nguồn và ưu tiên nguồn|config|ReasonBody|Source|200|-|
099|Tiếp tục nguồn|Nguồn và ưu tiên nguồn|config|ReasonBody|Source|200|-|
100|Ngừng nguồn|Nguồn và ưu tiên nguồn|config|ReasonBody|Source|200|-|
018|Bảng ưu tiên nguồn hiện hành|Nguồn và ưu tiên nguồn|read|-|SourcePriorityTable|200|attribute:acode|
019|Đề nghị thứ tự ưu tiên nguồn|Nguồn và ưu tiên nguồn|config|PriorityProposalRequest|PriorityProposal|202|-|idem
020|Duyệt đề nghị ưu tiên nguồn|Nguồn và ưu tiên nguồn|approve|CommentBody|SourcePriorityTable|200|-|
101|Từ chối đề nghị ưu tiên nguồn|Nguồn và ưu tiên nguồn|approve|RejectBody|PriorityProposal|200|-|
021|Nạp bản ghi ứng viên qua API|Nạp ứng viên|ingest|CandidateIngestRequest|CandidateIngestResult|202|-|idem m:mdm:ingest also:207
022|Nạp bản ghi ứng viên qua luồng PH-04|Nạp ứng viên|-|InternalIngestRequest|CandidateIngestResult|202|-|idem only:mdm:ingest also:207
023|Tải tệp lô lên để xem trước|Nạp ứng viên|ingest|CandidateFileUpload|CandidateFile|202|-|idem multipart
024|Xác nhận nạp tệp lô|Nạp ứng viên|ingest|FileConfirm|CandidateFile|202|-|
025|Trạng thái tệp lô|Nạp ứng viên|ingest|-|CandidateFile|200|-|
026|Danh sách bản ghi ứng viên|Nạp ứng viên|read|-|CandidatePage|200|sourceCode:scode,status:E:CandidateStatus,warning:E:NormalizationWarning,tu:ts,den:ts,sourceKey:str,page,size|
027|Chi tiết bản ghi ứng viên|Nạp ứng viên|read|-|CandidateDetail|200|-|
028|Xử lý lại ứng viên|Nạp ứng viên|ingest|CandidateBulkRequest|BulkActionResult|200|-|
102|Loại bỏ ứng viên|Nạp ứng viên|ingest|CandidateBulkRequest|BulkActionResult|200|-|
029|Xem trước chuẩn hóa|Nạp ứng viên|read|NormalizePreviewRequest|NormalizePreviewResult|200|-|
030|Danh sách bộ quy tắc đối sánh|Quy tắc đối sánh|read|-|RuleSetPage|200|status:E:VersionStatus,page,size|
031|Tạo bộ quy tắc nháp|Quy tắc đối sánh|config|RuleSetCreate|RuleSet|201|-|idem
032|Sửa bộ quy tắc nháp|Quy tắc đối sánh|config|RuleSetUpdate|RuleSet|200|-|
033|Chạy thử bộ quy tắc trên mẫu|Quy tắc đối sánh|config|DryRunRequest|JobAccepted|202|-|idem
034|Đo precision, recall của bộ quy tắc|Quy tắc đối sánh|config|EvaluateRequest|JobAccepted|202|-|idem
035|Gửi duyệt bộ quy tắc|Quy tắc đối sánh|config|CommentBody|RuleSet|200|-|
103|Duyệt bộ quy tắc|Quy tắc đối sánh|approve|CommentBody|RuleSet|200|-|
104|Từ chối bộ quy tắc|Quy tắc đối sánh|approve|RejectBody|RuleSet|200|-|
036|Thống kê khóa gom nhóm|Quy tắc đối sánh|config|-|BlockingStats|200|-|
037|Danh sách tập nhãn|Quy tắc đối sánh|steward|-|LabelSetPage|200|purpose:E:LabelSetPurpose,page,size|
038|Tạo tập nhãn|Quy tắc đối sánh|steward|LabelSetCreate|LabelSet|201|-|idem
039|Thêm cặp nhãn vào tập|Quy tắc đối sánh|steward|LabelPairsRequest|LabelSet|201|-|idem
040|Danh sách báo cáo độ chính xác|Quy tắc đối sánh|read|-|AccuracyReportPage|200|ruleSetVersion:int,page,size|
041|Danh sách job|Job đối sánh|operate|-|MatchJobPage|200|domainCode:dcode,jobType:E:JobType,status:E:JobStatus,page,size|
042|Tạo job đối sánh lô|Job đối sánh|operate|MatchJobCreate|JobAccepted|202|-|idem
043|Chi tiết job|Job đối sánh|operate|-|MatchJob|200|-|
044|Hủy job|Job đối sánh|operate|ReasonBody|MatchJob|200|-|
105|Chạy lại job|Job đối sánh|operate|RerunRequest|JobAccepted|202|-|
106|Xác nhận job vượt ngưỡng an toàn|Job đối sánh|approve|JobConfirmRequest|MatchJob|200|-|
045|Danh sách mục hàng đợi|Hàng đợi người quản lý|steward|-|StewardItemPage|200|domainCode:dcode,reason:E:QueueReason,status:E:QueueItemStatus,assignee:str,riskLevel:E:RiskLevel,overdue:bool,sourceCode:scode,partition:str,page,size|
046|So sánh cạnh nhau hai bản ghi|Hàng đợi người quản lý|steward|-|StewardItemDetail|200|unmask:str,unmaskReason:str|
047|Nhận mục hàng đợi|Hàng đợi người quản lý|steward|-|StewardItem|200|-|
107|Trả mục hàng đợi|Hàng đợi người quản lý|steward|-|StewardItem|200|-|
108|Phân công mục hàng đợi|Hàng đợi người quản lý|steward|AssignRequest|StewardItem|200|-|
048|Quyết định khớp, không khớp, hoãn|Hàng đợi người quản lý|steward|DecideRequest|StewardItem|200|-|
049|Duyệt bốn mắt hợp nhất rủi ro cao|Hàng đợi người quản lý|approve|CommentBody|StewardItem|200|-|
109|Từ chối hợp nhất rủi ro cao|Hàng đợi người quản lý|approve|RejectBody|StewardItem|200|-|
050|Thống kê hàng đợi|Hàng đợi người quản lý|read|-|StewardStats|200|domainCode:dcode|
051|Cấu hình sống sót hiện hành|Quy tắc sống sót|read|-|SurvivorshipConfig|200|version:int|
052|Soạn cấu hình sống sót|Quy tắc sống sót|config|SurvivorshipPut|SurvivorshipConfig|200|-|
053|Gửi duyệt cấu hình sống sót|Quy tắc sống sót|config|CommentBody|SurvivorshipConfig|200|-|
110|Duyệt cấu hình sống sót|Quy tắc sống sót|approve|CommentBody|SurvivorshipConfig|200|-|
111|Từ chối cấu hình sống sót|Quy tắc sống sót|approve|RejectBody|SurvivorshipConfig|200|-|
054|Xem trước tác động của cấu hình sống sót|Quy tắc sống sót|config|SurvivorshipImpactRequest|SurvivorshipImpact|200|-|noifm
055|Áp lại sống sót hàng loạt|Quy tắc sống sót|config|ReapplyRequest|JobAccepted|202|-|idem noifm
056|Chi tiết bản ghi vàng|Bản ghi vàng|read|-|GoldenRecord|200|unmask:str,unmaskReason:str|
057|Sửa tay thuộc tính bản ghi vàng|Bản ghi vàng|update|AttributePatchRequest|GoldenOperationResult|200|-|
058|Hợp nhất bản ghi vàng thủ công|Bản ghi vàng|merge|MergeRequest|GoldenOperationResult|200|-|idem also:202
059|Tách bản ghi vàng|Bản ghi vàng|merge|SplitRequest|GoldenOperationResult|200|-|idem also:202
060|Hoàn tác thao tác|Bản ghi vàng|merge|UndoRequest|GoldenOperationResult|200|-|idem noifm also:202
061|Duyệt thao tác rủi ro cao|Bản ghi vàng|approve|CommentBody|GoldenOperationResult|200|-|
112|Từ chối thao tác rủi ro cao|Bản ghi vàng|approve|RejectBody|GoldenOperationResult|200|-|
062|Ngừng bản ghi vàng|Bản ghi vàng|merge|RetireRequest|GoldenRecord|200|-|
113|Khôi phục bản ghi vàng|Bản ghi vàng|merge|RestoreRequest|GoldenRecord|200|-|
063|Lịch sử phiên bản bản ghi vàng|Bản ghi vàng|read|-|HistoryPage|200|asOf:ts,page,size|
064|Một phiên bản lịch sử và so sánh|Bản ghi vàng|read|-|HistorySnapshot|200|compareWith:int|
065|Truy nguồn gốc thuộc tính|Bản ghi vàng|read|-|LineageResult|200|attribute:acode,tu:ts,den:ts|
066|Liên kết chéo của bản ghi vàng|Liên kết chéo và tra cứu|read|-|XrefList|200|-|
067|Gỡ liên kết chéo|Liên kết chéo và tra cứu|update|DetachRequest|GoldenOperationResult|200|-|
068|Tra ID vàng theo ID nguồn|Liên kết chéo và tra cứu|read|-|XrefLookupResult|200|-|purpose m:mdm:xref
069|Tra hàng loạt liên kết chéo|Liên kết chéo và tra cứu|read|BatchLookupRequest|XrefLookupResult|200|-|purpose m:mdm:xref noifm
070|Tra cứu bản ghi vàng theo ID hoặc khóa định danh|Liên kết chéo và tra cứu|read|GoldenLookupRequest|GoldenRecord|200|-|purpose m:mdm:read noifm
071|Giải quyết bản ghi trực tuyến (resolve)|Liên kết chéo và tra cứu|-|ResolveRequest|ResolveResult|200|-|purpose only:mdm:resolve noifm also:202
072|Tìm kiếm bản ghi vàng theo thuộc tính|Liên kết chéo và tra cứu|read|SearchRequest|SearchResult|200|-|purpose m:mdm:search noifm
073|Đề nghị xuất dữ liệu chủ|Cung cấp dữ liệu|export|ExportCreate|Export|202|-|idem
074|Trạng thái yêu cầu xuất|Cung cấp dữ liệu|export|-|Export|200|-|
075|Chấp thuận yêu cầu xuất|Cung cấp dữ liệu|export|CommentBody|Export|200|-|
114|Từ chối yêu cầu xuất|Cung cấp dữ liệu|export|RejectBody|Export|200|-|
076|Tải tệp xuất|Cung cấp dữ liệu|export|-|binary|200|-|
077|Danh sách đăng ký nhận cập nhật|Cung cấp dữ liệu|config|-|SubscriptionPage|200|domainCode:dcode,systemCode:str,status:E:SubscriptionStatus,page,size|
078|Đăng ký nhận cập nhật cho HTTT|Cung cấp dữ liệu|config|SubscriptionCreate|Subscription|201|-|idem
079|Chấp thuận đăng ký nhận cập nhật|Cung cấp dữ liệu|export|CommentBody|Subscription|200|-|
115|Tạm ngừng đăng ký nhận cập nhật|Cung cấp dữ liệu|config|ReasonBody|Subscription|200|-|
116|Tiếp tục đăng ký nhận cập nhật|Cung cấp dữ liệu|config|ReasonBody|Subscription|200|-|
117|Thu hồi đăng ký nhận cập nhật|Cung cấp dữ liệu|config|ReasonBody|Subscription|200|-|
080|Trạng thái đồng bộ quốc gia|Đồng bộ quốc gia|read|-|SyncStatus|200|domainCode:dcode|
081|Chạy đồng bộ quốc gia thủ công|Đồng bộ quốc gia|sync|SyncRunRequest|SyncRunAccepted|202|-|idem m:mdm:national-sync
082|Tạm dừng đồng bộ quốc gia|Đồng bộ quốc gia|sync|ReasonBody|SyncStatus|200|-|noifm
118|Tiếp tục đồng bộ quốc gia|Đồng bộ quốc gia|sync|SyncResumeRequest|SyncStatus|200|-|noifm
083|Danh sách lệch đồng bộ quốc gia|Đồng bộ quốc gia|sync|-|DiscrepancyPage|200|runId:uuid,attribute:acode,severity:E:DiscrepancySeverity,status:E:DiscrepancyStatus,page,size|
084|Xử lý lệch đồng bộ quốc gia|Đồng bộ quốc gia|sync|DiscrepancyResolveRequest|DiscrepancyResolveResult|200|-|noifm
085|Chỉ số dashboard dữ liệu chủ|Vận hành|read|-|DashboardMetrics|200|domainCode:dcode,khoang:str|
086|Danh sách lịch job|Vận hành|operate|-|JobSchedulePage|200|-|
087|Sửa lịch job|Vận hành|operate|JobSchedulePut|JobSchedule|200|-|
088|Nhật ký xử lý|Vận hành|read|-|ProcessingLogPage|200|jobId:uuid,candidateId:uuid,level:str,tu:ts,den:ts,page,size|
089|Nhật ký truy cập|Vận hành|audit-read|-|AccessLogPage|200|goldenId:uuid,actor:str,systemCode:str,purposeCode:str,tu:ts,den:ts,page,size|
090|Tiếp nhận yêu cầu của chủ thể dữ liệu|Chủ thể dữ liệu và lưu giữ|dsr|DsrCreate|Dsr|201|-|idem
091|Chi tiết yêu cầu của chủ thể dữ liệu|Chủ thể dữ liệu và lưu giữ|dsr|-|Dsr|200|-|
092|Hoàn tất yêu cầu của chủ thể dữ liệu|Chủ thể dữ liệu và lưu giữ|dsr|DsrComplete|Dsr|200|-|
119|Chuyển yêu cầu sửa tới nguồn|Chủ thể dữ liệu và lưu giữ|dsr|DsrForward|Dsr|200|-|
120|Từ chối yêu cầu của chủ thể dữ liệu|Chủ thể dữ liệu và lưu giữ|dsr|RejectBody|Dsr|200|-|
093|Danh sách chính sách lưu giữ|Chủ thể dữ liệu và lưu giữ|config|-|RetentionPolicyPage|200|-|
094|Sửa chính sách lưu giữ|Chủ thể dữ liệu và lưu giữ|config|RetentionPolicyPut|RetentionPolicy|200|-|
095|Danh sách tham số phân hệ|Chủ thể dữ liệu và lưu giữ|config|-|SettingsDoc|200|-|
096|Sửa tham số phân hệ|Chủ thể dữ liệu và lưu giữ|config|SettingsPut|SettingsDoc|200|-|
121|Mở lại quyết định hàng đợi|Hàng đợi người quản lý|steward|ReasonBody|StewardItem|200|-|
122|Danh sách thao tác của bản ghi vàng|Bản ghi vàng|read|-|GoldenOperationPage|200|status:E:OperationStatus,changeType:E:GoldenChangeType,undoable:bool,page,size|
123|Khóa tập nhãn kiểm chứng|Quy tắc đối sánh|steward|-|LabelSet|200|-|
124|Nhận mục hàng đợi tiếp theo|Hàng đợi người quản lý|steward|ClaimNextRequest|StewardItem|200|-|noifm also:204
125|Gỡ hạn chế xử lý dữ liệu|Chủ thể dữ liệu và lưu giữ|dsr|ReasonBody|Dsr|200|-|
"""
OPS = {}
for ln in OPS_TXT.strip().splitlines():
    c, s, tag, perm, rq, rs, st, q, fl = ln.split("|")
    OPS[c] = dict(code=c, summary=s, tag=tag, perm=perm, req=None if rq == "-" else rq, res=rs, status=int(st),
                  query=[] if q == "-" else q.split(","), flags=fl.split())
assert set(OPS) == {r[0] for r in ROWS}, set(OPS) ^ {r[0] for r in ROWS}
TAGS = list(dict.fromkeys(o["tag"] for o in OPS.values()))

# ---------------------------------------------------------------- lược đồ
CODE = "^[A-Za-z][A-Za-z0-9_.-]{0,63}$"
TYPES = {
    "str": ({"type": "string"}, "ví dụ"), "code": ({"type": "string", "pattern": CODE}, "ma-1"),
    "dcode": ({"type": "string", "pattern": "^[A-Z][A-Z0-9_]{1,31}$"}, "CITIZEN"),
    "scode": ({"type": "string", "pattern": "^[A-Z][A-Z0-9-]{2,31}$"}, "HT-YTE"),
    "acode": ({"type": "string", "pattern": "^[a-z][a-zA-Z0-9]{1,62}$"}, "fullName"),
    "int": ({"type": "integer"}, 1), "num": ({"type": "number"}, 0.9), "bool": ({"type": "boolean"}, False),
    "ts": ({"type": "string", "format": "date-time"}, "2026-11-20T08:00:00+07:00"),
    "date": ({"type": "string", "format": "date"}, "1990-05-14"),
    "uuid": ({"type": "string", "format": "uuid"}, "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"),
    "obj": ({"type": "object"}, {}), "any": ({}, "ví dụ"),
}
SCH = {}


def tschema(t, extra=None):
    """Chuyển kiểu rút gọn thành (lược đồ, ví dụ mặc định hoặc None khi dùng ví dụ của lược đồ tham chiếu)."""
    if t.startswith("[") and t.endswith("]"):
        s, ex = tschema(t[1:-1])
        out = {"type": "array", "items": s}
        if extra:
            out.update(extra); extra = None
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
LONG = "Theo dõi theo kỳ họp thẩm định, cần có biên bản và văn bản căn cứ."
ID = ("id!", "uuid")
AUD = [("createdAt", "ts"), ("updatedAt", "ts"), ("version", "int", 3)]

obj("FieldError", "Lỗi theo trường.", ("field!", "str", "attributes.fullName"), ("message!", "str", "Giá trị không hợp lệ."))
obj("Problem", "Lỗi theo RFC 9457.", ("type!", "str", "https://datahub.example.vn/errors/ERR-06-003"), ("title!", "str", "Dữ liệu không hợp lệ"),
    ("status!", "int", 400), ("detail", "str", "Trường sourceKey bắt buộc."), ("instance", "str", "/api/mdm/v1/domains"),
    ("code!", "str", "ERR-06-003"), ("traceId!", "str", "4bf92f3577b34da6a3ce929d0e0e4736"), ("errors", "[$FieldError]"))
obj("CommentBody", "Ý kiến kèm hành động.", ("comment", "str", "Đồng ý theo biên bản họp ngày 20/11/2026.", {"maxLength": 2000}))
obj("RejectBody", "Từ chối: bắt buộc nêu lý do từ 20 ký tự (BR-06-008).", ("comment!", "str", "Thiếu căn cứ văn bản phê duyệt, đề nghị bổ sung.", R20))
obj("ReasonBody", "Hành động kèm lý do từ 20 ký tự (BR-06-008).", ("reason!", "str", "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123.", R20))
obj("BulkActionResult", "Kết quả hành động hàng loạt.", ("accepted!", "int", 3), ("skipped", "[$SkippedItem]"))
obj("SkippedItem", "Phần tử bị bỏ qua.", ("id!", "str", "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"), ("reason!", "str", "Trạng thái không cho thao tác."))
obj("JobAccepted", "Job đã nhận, chạy bất đồng bộ.", ("jobId!", "uuid"), ("status!", "E:JobStatus", "QUEUED"), ("jobType", "E:JobType", "BATCH_MATCH"))
# --- domain, mô hình
obj("Domain", "Domain dữ liệu chủ.", ("domainCode!", "dcode"), ("name!", "str", "Công dân"), ("status!", "E:DomainStatus", "ACTIVE"),
    ("activeVersion", "int", 3), ("attributeCount", "int", 14), ("goldenCount", "int", 1200000), ("description", "str", "Công dân Việt Nam"), *AUD)
obj("ModelAttribute", "Thuộc tính của mô hình (FR-06-002).", ("name!", "acode"), ("label!", "str", "Dân tộc", {"minLength": 1, "maxLength": 255}),
    ("type!", "E:AttributeType", "CODE_REF"), ("codeListRef", "code", "DM_DAN_TOC"), ("required!", "bool", False), ("multiValued!", "bool", False),
    ("critical!", "bool", False), ("matchable!", "bool", True), ("dataClass!", "E:DataClass", "RESTRICTED"),
    ("personalData", "bool", True), ("legalBasis", "str", "Nghị định 13/2023/NĐ-CP"), ("classificationStatus", "E:ClassificationStatus", "PROPOSED"))
obj("IdentifierRule", "Khóa định danh và bộ kiểm tra (FR-06-003).", ("identifierType!", "E:IdentifierType", "CCCD_12"), ("attribute!", "acode", "nationalId"),
    ("validator!", "str", "CCCD_12"), ("pattern", "str", "^[0-9]{12}$"), ("deterministic!", "bool", True), ("uniqueAmongActive!", "bool", True))
obj("ModelVersion", "Phiên bản mô hình domain.", ("domainCode!", "dcode"), ("version!", "int", 4), ("status!", "E:VersionStatus", "DRAFT"),
    ("attributes!", "[$ModelAttribute]"), ("identifiers", "[$IdentifierRule]"), ("normalization", "obj", {"fullName": {"case": "TITLE"}}),
    ("compatLevel", "E:CompatLevel", "NON_BREAKING"), ("submittedBy", "str", "ts.nguyen"), ("approvedBy", "str", "da.tran"), ("activatedAt", "ts"), *AUD)
page("ModelVersionPage", "ModelVersion")
obj("ModelVersionCreate", "Tạo phiên bản nháp, kế thừa từ phiên bản nguồn.", ("basedOnVersion", "int", 3), ("attributes", "[$ModelAttribute]"), ("identifiers", "[$IdentifierRule]"))
obj("ModelVersionUpdate", "Sửa bản nháp; thay toàn bộ danh sách.", ("attributes!", "[$ModelAttribute]"), ("identifiers", "[$IdentifierRule]"), ("normalization", "obj", {}))
obj("DomainDetail", "Chi tiết domain.", ("domainCode!", "dcode"), ("name!", "str", "Công dân"), ("status!", "E:DomainStatus", "ACTIVE"),
    ("attributes!", "[$ModelAttribute]"), ("identifiers!", "[$IdentifierRule]"), ("schemaUrl", "str", "https://console.t68.datahub.example.vn/api/mdm/v1/domains/CITIZEN/schema"),
    ("versions!", "[$VersionSummary]"), ("activeVersion", "int", 3), *AUD)
obj("VersionSummary", "Tóm tắt phiên bản.", ("version!", "int", 3), ("status!", "E:VersionStatus", "ACTIVE"), ("activatedAt", "ts"))
page("DomainPage", "Domain")
obj("DomainCreate", "Tạo domain mới (bản nháp).", ("domainCode!", "dcode", "HOUSEHOLD"), ("name!", "str", "Hộ gia đình", {"minLength": 1, "maxLength": 255}), ("description", "str", "Hộ gia đình"))
obj("ModelChange", "Một thay đổi giữa hai phiên bản.", ("path!", "str", "attributes.ethnicity"), ("kind!", "str", "ADDED"), ("before", "any", None), ("after", "any", "CODE_REF"), ("compat!", "E:CompatLevel", "NON_BREAKING"))
obj("ModelDiff", "So sánh hai phiên bản mô hình (FR-06-005).", ("changes!", "[$ModelChange]"), ("affectedSources!", "[scode]"), ("affectedGoldenCount!", "int", 0))
obj("InstallBaselineRequest", "Nạp gói domain nền (FR-06-007).", ("packageVersion", "str", "1.0.0"), ("domains", "[dcode]"))
obj("InstallBaselineResult", "Kết quả nạp gói nền.", ("installed!", "[dcode]"), ("skipped!", "[dcode]", []), ("followUpTasks", "[str]", ["Gán phân loại PH-09 cho thuộc tính DLCN"]))
obj("IdentifierTestRequest", "Thử bộ kiểm tra khóa (FR-06-003).", ("validator!", "str", "CCCD_12"), ("pattern", "str", "^[0-9]{12}$"), ("values!", "[str]", ["079090001234"], {"maxItems": 50}))
obj("IdentifierTestItem", "Kết quả kiểm một giá trị.", ("value!", "str", "*********234"), ("verdict!", "E:IdentifierStatus", "VALID"), ("reason", "str", "Hợp lệ"))
obj("IdentifierTestResult", "Kết quả thử khóa; giá trị che, giữ 3 số cuối.", ("results!", "[$IdentifierTestItem]"))
# --- nguồn
obj("Source", "Nguồn dữ liệu chủ gắn HTTT.", ("sourceCode!", "scode"), ("systemCode", "str", "SYT-HSSK"), ("sourceKind!", "E:SourceKind", "SECTOR_RELATED"),
    ("domains!", "[dcode]"), ("channels!", "[E:IngestChannel]", ["API", "FLOW"]), ("attributeScope", "[acode]", ["fullName", "phone"]), ("ownerOrgCode!", "code", "SYT"),
    ("status!", "E:SourceStatus", "ACTIVE"), ("trustLevel", "int", 80, {"minimum": 0, "maximum": 100}), *AUD)
page("SourcePage", "Source")
obj("SourceCreate", "Đăng ký nguồn (FR-06-008).", ("sourceCode!", "scode"), ("systemCode", "str", "SYT-HSSK"), ("sourceKind!", "E:SourceKind", "SECTOR_RELATED"),
    ("domains!", "[dcode]"), ("channels!", "[E:IngestChannel]", ["API", "FLOW"]), ("attributeScope", "[acode]", ["fullName", "phone"]), ("ownerOrgCode!", "code", "SYT"), ("trustLevel", "int", 80, {"minimum": 0, "maximum": 100}))
obj("SourceUpdate", "Sửa nguồn; chỉ các trường gửi lên.", ("channels", "[E:IngestChannel]", ["API"]), ("attributeScope", "[acode]", ["fullName"]), ("trustLevel", "int", 70, {"minimum": 0, "maximum": 100}))
obj("PriorityEntry", "Một dòng ưu tiên nguồn.", ("sourceCode!", "scode"), ("attribute", "str", "*", {"description": "Rỗng hoặc * là mọi thuộc tính."}), ("priority!", "int", 1, {"minimum": 1, "maximum": 99}))
obj("SourcePriorityTable", "Bảng ưu tiên nguồn hiện hành.", ("items!", "[$PriorityEntry]"), ("effectiveFrom", "ts"), ("approvalRef", "str", "QĐ 45/QĐ-SKHĐT ngày 10/11/2026"))
obj("PriorityProposalRequest", "Đề nghị thứ tự ưu tiên nguồn (FR-06-009).", ("entries!", "[$PriorityEntry]"), ("approvalRef!", "str", "QĐ 45/QĐ-SKHĐT ngày 10/11/2026", {"minLength": 5}), ("justification", "str", "Nguồn y tế là nguồn chủ quản của thuộc tính ngày sinh."))
obj("PriorityProposal", "Đề nghị ưu tiên nguồn.", ("proposalId!", "uuid"), ("status!", "E:VersionStatus", "PENDING_APPROVAL"), ("entries!", "[$PriorityEntry]"), ("approvalRef!", "str", "QĐ 45/QĐ-SKHĐT ngày 10/11/2026"),
    ("impactPreview", "obj", {"affectedGoldenCount": 1200}), *AUD)
# --- ứng viên
obj("CandidateRecordIn", "Một bản ghi ứng viên (FR-06-010).", ("sourceKey!", "str", "BN-2026-000123", {"minLength": 1, "maxLength": 120}), ("sourceVersion!", "int", 7),
    ("sourceUpdatedAt!", "ts"), ("operation!", "E:CandidateOperation", "UPDATE"), ("attributes", "obj", {"fullName": "Nguyễn Văn A", "dateOfBirth": "1990-05-14"}))
obj("CandidateBatchIn", "Lô tối đa 500 bản ghi.", ("records!", "[$CandidateRecordIn]", None, {"minItems": 1, "maxItems": 500}))
SCH["CandidateIngestRequest"] = {"description": "Một bản ghi hoặc lô `records[]`.", "oneOf": [{"$ref": "#/components/schemas/CandidateRecordIn"}, {"$ref": "#/components/schemas/CandidateBatchIn"}],
                                 "x-ex": {"records": [{"sourceKey": "BN-2026-000123", "sourceVersion": 7, "sourceUpdatedAt": "2026-11-20T08:00:00+07:00", "operation": "UPDATE", "attributes": {"fullName": "Nguyễn Văn A"}}]}}
obj("InternalBatchIn", "Lô từ luồng PH-04.", ("records!", "[$CandidateRecordIn]", None, {"minItems": 1, "maxItems": 500}), ("flowCode!", "code", "luong-ho-so-y-te"), ("flowVersion!", "int", 2), ("exchangeId!", "str", "ex-0193b1d4"))
SCH["InternalIngestRequest"] = {"description": "Như FR-06-010 kèm `flowCode`, `flowVersion`, `exchangeId` (FR-06-011).", "$ref": "#/components/schemas/InternalBatchIn", "x-ex": {}}
obj("CandidateIngestItem", "Kết quả một bản ghi.", ("sourceKey!", "str", "BN-2026-000123"), ("candidateId", "uuid"), ("status!", "str", "RECEIVED", {"enum": ["RECEIVED", "DUPLICATE", "SUPERSEDED", "REJECTED"]}), ("errors", "[$FieldError]"))
obj("CandidateIngestResult", "Kết quả nạp; lỗi từng bản ghi không làm hỏng cả lô (207).", ("results!", "[$CandidateIngestItem]"))
obj("CandidateFileUpload", "Tải tệp lô (multipart).", ("file!", "str", "bệnh nhân.csv", {"format": "binary", "description": "`.xlsx` hoặc `.csv` UTF-8, ≤ 50 MB, ≤ 200.000 dòng."}),
    ("sourceCode!", "scode"), ("domainCode!", "dcode"), ("columnMapping", "obj", {"Họ tên": "fullName"}))
obj("CandidateFile", "Tệp lô đang nạp.", ("fileId!", "uuid"), ("phase!", "str", "PREVIEWED", {"enum": ["UPLOADED", "PREVIEWED", "CONFIRMED", "INGESTING", "DONE", "FAILED"], "description": "Pha suy từ cột của `candidate_file` (đề nghị 9 của tài liệu CSDL)."}),
    ("rows", "int", 1200), ("rowErrors", "int", 3), ("report", "str", "https://console.t68.datahub.example.vn/files/preview-0193.csv"), ("jobId", "uuid"), *AUD)
obj("FileConfirm", "Xác nhận nạp sau xem trước.", ("acceptWarnings", "bool", True))
obj("CandidateDetail", "Chi tiết ứng viên; giá trị DLCN đã che.", ("candidateId!", "uuid"), ("sourceCode!", "scode"), ("sourceKey!", "str", "BN-2026-000123"), ("status!", "E:CandidateStatus", "NORMALIZED"),
    ("warnings", "[E:NormalizationWarning]", ["DATE_PLACEHOLDER"]), ("raw", "obj", {"fullName": "Nguyễn Văn A"}), ("normalized", "obj", {"nameKey": "nguyen van a"}),
    ("matchOutcome", "E:MatchOutcome", "MATCH"), ("goldenId", "uuid"), ("receivedAt", "ts"))
page("CandidatePage", "CandidateDetail")
obj("CandidateBulkRequest", "Xử lý lại hoặc loại bỏ tối đa 1.000 ứng viên.", ("candidateIds!", "[uuid]", None, {"minItems": 1, "maxItems": 1000}), ("reason!", "str", "Nguồn đã gửi lại dữ liệu đúng khuôn, xử lý lại.", R20))
obj("NormalizePreviewRequest", "Xem trước chuẩn hóa (FR-06-014, 015).", ("domainCode!", "dcode"), ("attributes!", "obj", {"fullName": "nguyễn  văn a", "dateOfBirth": "14/05/1990"}))
obj("NormalizePreviewResult", "Kết quả xem trước.", ("raw!", "obj", {"fullName": "nguyễn  văn a"}), ("normalized!", "obj", {"fullName": "Nguyễn Văn A"}), ("warnings!", "[E:NormalizationWarning]", []))
# --- quy tắc đối sánh
obj("MatchRule", "Quy tắc đối sánh.", ("ruleType!", "E:MatchRuleType", "PROBABILISTIC"), ("attribute!", "acode"), ("comparator!", "E:Comparator", "JARO_WINKLER"), ("weight", "num", 2.5), ("levels", "[E:ComparisonLevel]", ["EXACT", "FUZZY_HIGH", "DIFFERENT"]))
obj("BlockingKey", "Khóa gom nhóm.", ("expression!", "str", "prefix(nameAscii.given,3)+year(dateOfBirth)"), ("enabled", "bool", True))
obj("Thresholds", "Ngưỡng ba vùng (BR-06-020).", ("autoMerge!", "num", 0.95, {"minimum": 0.9, "maximum": 1}), ("review!", "num", 0.8, {"minimum": 0, "maximum": 1}), ("autoMergeEnabled", "bool", True))
obj("RuleSet", "Bộ quy tắc đối sánh có phiên bản.", ("domainCode!", "dcode"), ("version!", "int", 2), ("status!", "E:VersionStatus", "DRAFT"), ("rules!", "[$MatchRule]"),
    ("blockingKeys!", "[$BlockingKey]"), ("thresholds!", "$Thresholds"), ("evaluation", "$AccuracyReport"), *AUD)
page("RuleSetPage", "RuleSet")
obj("RuleSetCreate", "Tạo bộ quy tắc nháp.", ("basedOnVersion", "int", 1), ("rules!", "[$MatchRule]"), ("blockingKeys!", "[$BlockingKey]"), ("thresholds!", "$Thresholds"))
obj("RuleSetUpdate", "Sửa bộ quy tắc nháp.", ("rules!", "[$MatchRule]"), ("blockingKeys!", "[$BlockingKey]"), ("thresholds!", "$Thresholds"))
obj("DryRunRequest", "Chạy thử trên mẫu (FR-06-024).", ("sampleSize", "int", 20000, {"minimum": 1000, "maximum": 100000}), ("sampleMode", "str", "RANDOM", {"enum": ["RANDOM", "RECENT_CANDIDATES", "QUEUE_HISTORY"]}), ("compareWith", "int", 1))
obj("EvaluateRequest", "Đo precision, recall (FR-06-026).", ("labelSetCode!", "code", "nhan-2026-q4"))
obj("AccuracyReport", "Báo cáo độ chính xác.", ("reportId!", "uuid"), ("ruleSetVersion!", "int", 2), ("labelSetCode!", "code", "nhan-2026-q4"), ("precision!", "num", 0.9993), ("recall!", "num", 0.985),
    ("reviewRate", "num", 0.04), ("confusion", "obj", {"TP": 980, "FP": 1, "TN": 9000, "FN": 15, "REVIEW": 400}), ("pairCount!", "int", 1200), ("verdict!", "E:EvaluationVerdict", "PASSED"), ("evaluatedAt", "ts"))
page("AccuracyReportPage", "AccuracyReport")
obj("BlockingStats", "Hiệu quả khóa gom nhóm (FR-06-019).", ("keys!", "[$BlockingKeyStat]"))
obj("BlockingKeyStat", "Thống kê một khóa.", ("expression!", "str", "adminUnitCode+year(dateOfBirth)"), ("avgBlockSize", "num", 12.4), ("p99BlockSize", "int", 310), ("oversizedBlocks", "int", 2), ("pairCoverage", "num", 0.97))
obj("LabelPair", "Cặp có nhãn.", ("leftRef!", "str", "gold:0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"), ("rightRef!", "str", "gold:0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f02"), ("label!", "E:PairLabel", "MATCH"))
obj("LabelSet", "Tập nhãn kiểm chứng.", ("labelSetCode!", "code", "nhan-2026-q4"), ("domainCode!", "dcode"), ("purpose!", "E:LabelSetPurpose", "EVALUATION"),
    ("stats", "obj", {"pairs": 1200, "match": 600, "noMatch": 600}), ("locked!", "bool", False), ("lockedAt", "ts"), ("lockedBy", "str", "ds.pham"), *AUD)
page("LabelSetPage", "LabelSet")
obj("LabelSetCreate", "Tạo tập nhãn.", ("labelSetCode!", "code", "nhan-2026-q4"), ("purpose!", "E:LabelSetPurpose", "EVALUATION"), ("description", "str", "Tập nhãn quý 4/2026"))
obj("LabelPairsRequest", "Thêm cặp nhãn.", ("pairs!", "[$LabelPair]", None, {"minItems": 1, "maxItems": 5000}))
# --- job
obj("MatchJob", "Job đối sánh, đánh giá, áp lại, đồng bộ.", ("jobId!", "uuid"), ("domainCode!", "dcode"), ("jobType!", "E:JobType", "BATCH_MATCH"), ("scope", "E:BatchScope", "CANDIDATES_SINCE"),
    ("status!", "E:JobStatus", "RUNNING"), ("counts", "obj", {"input": 5000, "pairs": 20000, "match": 120, "possible": 40, "noMatch": 19840, "applied": 100, "skipped": 20}),
    ("startedAt", "ts"), ("finishedAt", "ts"), ("requestedBy", "str", "to.le"), *AUD)
page("MatchJobPage", "MatchJob")
obj("MatchJobCreate", "Tạo job đối sánh lô (FR-06-022).", ("domainCode!", "dcode"), ("scope!", "E:BatchScope", "CANDIDATES_SINCE"), ("since", "ts"), ("trainOnly", "bool", False), ("dryRun", "bool", False), ("ruleSetVersion", "int", 2))
obj("JobConfirmRequest", "Quyết định của người duyệt với job vượt ngưỡng an toàn (FR-06-022 bước 5).", ("decision!", "E:ApprovalDecision", "APPROVE"), ("comment", "str", "Đồng ý áp kết quả theo biên bản họp ngày 20/11/2026.", {"maxLength": 2000}))
obj("SyncResumeRequest", "Tiếp tục đồng bộ quốc gia sau tạm dừng (FR-06-053).", ("cause!", "str", "Đã điều tra, lệch do đợt cập nhật danh mục ngày 20/11, áp bản quốc gia.", R20), ("applyDiscrepancies", "bool", True))
obj("ClaimNextRequest", "Bộ lọc khi nhận mục tiếp theo (FR-06-028); thân rỗng nghĩa là không lọc.", ("domainCode", "dcode"), ("reason", "[E:QueueReason]", ["POSSIBLE_MATCH"]), ("riskLevel", "E:RiskLevel", "LOW"), ("sourceCode", "[scode]"))
obj("RerunRequest", "Chạy lại job từ bước.", ("fromStep!", "str", "APPLYING", {"enum": ["PREPARING", "APPLYING"]}), ("reason!", "str", "Chạy lại sau khi khắc phục lỗi đọc staging.", R20))
# --- hàng đợi
obj("StewardItem", "Mục hàng đợi.", ("itemId!", "uuid"), ("domainCode!", "dcode"), ("reason!", "E:QueueReason", "POSSIBLE_MATCH"), ("status!", "E:QueueItemStatus", "OPEN"), ("riskLevel!", "E:RiskLevel", "LOW"),
    ("score", "num", 0.87), ("priority", "int", 40), ("assignee", "str", "ds.pham"), ("dueAt", "ts"), ("operationId", "uuid"), *AUD)
page("StewardItemPage", "StewardItem")
obj("AttributeComparison", "So sánh một thuộc tính.", ("name!", "acode", "fullName"), ("leftValue", "str", "Nguyễn Văn A"), ("rightValue", "str", "Nguyen Van A"), ("score", "num", 0.96), ("level!", "E:ComparisonLevel", "FUZZY_HIGH"))
obj("StewardItemDetail", "Hai bản ghi cạnh nhau; giá trị SENSITIVE che.", ("item!", "$StewardItem"), ("left!", "obj", {"ref": "gold:0193"}), ("right!", "obj", {"ref": "cand:0193"}),
    ("attributes!", "[$AttributeComparison]"), ("context", "obj", {}), ("mergeAllowed!", "bool", True), ("queueRemaining", "int", 12))
obj("AssignRequest", "Phân công mục.", ("assigneeId!", "str", "ds.pham"))
obj("DecideRequest", "Quyết định của người quản lý (FR-06-030).", ("decision!", "E:StewardDecision", "MATCH"), ("reason!", "str", "Cùng số CCCD và cùng ngày sinh, hai bản ghi là một người.", R20),
    ("survivorId", "uuid"), ("deferUntil", "ts"), ("addToLabelSet", "bool", True))
obj("StewardStats", "Thống kê hàng đợi (FR-06-032).", ("byStatus!", "obj", {"OPEN": 12, "ASSIGNED": 5}), ("byReason", "obj", {"POSSIBLE_MATCH": 10}), ("bySource", "obj", {"HT-YTE": 8}), ("overdue!", "int", 2), ("oldestOpenDays", "int", 5))
# --- sống sót
obj("SurvivorshipRule", "Chiến lược của một thuộc tính.", ("attribute!", "acode", "fullName"), ("strategies!", "[E:SurvivorshipStrategy]", ["SOURCE_PRIORITY", "MOST_RECENT"]), ("criticalConflictToQueue", "bool", False), ("nationalAuthority", "bool", False))
obj("SurvivorshipConfig", "Cấu hình sống sót của domain.", ("domainCode!", "dcode"), ("version!", "int", 2), ("status!", "E:VersionStatus", "DRAFT"), ("rules!", "[$SurvivorshipRule]"), *AUD)
obj("SurvivorshipPut", "Soạn cấu hình sống sót.", ("rules!", "[$SurvivorshipRule]"), ("comment", "str", "Ưu tiên nguồn quốc gia cho họ tên."))
obj("SurvivorshipImpactRequest", "Xem trước tác động (FR-06-042).", ("rules!", "[$SurvivorshipRule]"), ("sampleSize", "int", 1000, {"minimum": 100, "maximum": 10000}))
obj("SurvivorshipImpact", "Tác động ước tính.", ("sampleSize!", "int", 1000), ("changedGolden!", "int", 12), ("changedAttributes!", "obj", {"fullName": 8}), ("estimatedTotal", "int", 14400), ("requiresApproval!", "bool", True))
obj("ReapplyRequest", "Áp lại sống sót hàng loạt.", ("configVersion!", "int", 2), ("confirmLarge", "bool", False))
# --- bản ghi vàng
obj("GoldenAttributeValue", "Thuộc tính vàng.", ("name!", "acode", "fullName"), ("value", "any", "Nguyễn Văn A"), ("masked!", "bool", False), ("dataClass!", "E:DataClass", "RESTRICTED"),
    ("sourceCode", "scode"), ("strategy", "E:SurvivorshipStrategy", "SOURCE_PRIORITY"), ("updatedAt", "ts"))
obj("GoldenRecord", "Bản ghi vàng đã che theo phân loại và mục đích.", ("goldenId!", "uuid"), ("domainCode!", "dcode"), ("status!", "E:GoldenStatus", "ACTIVE"), ("displayName", "str", "Nguyễn Văn A"),
    ("attributes!", "[$GoldenAttributeValue]"), ("confidence", "num", 0.97), ("sourceCount", "int", 3), ("mergedInto", "uuid"), ("version!", "int", 5), ("updatedAt", "ts"))
obj("AttributePatchRequest", "Sửa tay thuộc tính (FR-06-036).", ("attribute!", "acode", "phone"), ("value!", "any", "0901234567"), ("reason!", "str", "Công dân xuất trình giấy xác nhận số điện thoại mới.", R20),
    ("evidenceRef!", "str", "BB-2026-114"), ("validUntil", "ts"))
obj("GoldenOperationResult", "Kết quả thao tác trên bản ghi vàng.", ("operationId!", "uuid"), ("changeType!", "E:GoldenChangeType", "MERGE"), ("status!", "E:OperationStatus", "APPLIED"), ("riskLevel", "E:RiskLevel", "LOW"),
    ("goldenId", "uuid"), ("survivorId", "uuid"), ("resultGoldenIds", "[uuid]"), ("sourceCorrectionRequestId", "uuid"), ("version", "int", 6))
obj("GoldenOperationItem", "Một thao tác trên bản ghi vàng (FR-06-035, FR-06-039).", ("operationId!", "uuid"), ("changeType!", "E:GoldenChangeType", "MERGE"), ("status!", "E:OperationStatus", "PENDING_APPROVAL"), ("riskLevel", "E:RiskLevel", "HIGH"),
    ("requestedBy", "str", "ds.pham"), ("requestedAt", "ts"), ("approvedBy", "str", "da.tran"), ("undoable!", "bool", True), ("undoDeadline", "ts"))
page("GoldenOperationPage", "GoldenOperationItem")
obj("MergeRequest", "Hợp nhất thủ công (FR-06-037).", ("goldenIds!", "[uuid]", ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f02"], {"minItems": 2, "maxItems": 10}),
    ("survivorId", "uuid"), ("reason!", "str", "Hai bản ghi cùng một người theo hồ sơ hộ tịch.", R20), ("attributeOverrides", "obj", {}))
obj("SplitGroup", "Nhóm liên kết tách.", ("xrefIds!", "[uuid]", None, {"minItems": 1}))
obj("SplitRequest", "Tách bản ghi vàng (FR-06-038).", ("groups!", "[$SplitGroup]", [{"xrefIds": ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f11"]}, {"xrefIds": ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f12"]}], {"minItems": 2}), ("reason!", "str", "Hai người khác nhau bị nhập nhầm cùng một bản ghi.", R20))
obj("UndoRequest", "Hoàn tác thao tác (FR-06-039).", ("reason!", "str", "Hợp nhất nhầm do hai người trùng tên và ngày sinh.", R20), ("confirmDependents", "bool", False))
obj("RetireRequest", "Ngừng bản ghi vàng (FR-06-040).", ("retireReason!", "E:RetireReason", "TEST_DATA"), ("reason!", "str", "Bản ghi dữ liệu thử còn sót sau đợt kiểm thử.", R20), ("evidenceRef", "str", "BB-2026-120"))
obj("RestoreRequest", "Khôi phục từ RETIRED.", ("reason!", "str", "Phát hiện bản ghi vẫn còn hoạt động ở hệ nguồn.", R20), ("evidenceRef", "str", "BB-2026-121"))
obj("HistoryVersion", "Một phiên bản trong lịch sử.", ("version!", "int", 5), ("changeType!", "E:GoldenChangeType", "UPDATE"), ("changedAt!", "ts"), ("changedBy", "str", "mdm-golden"), ("operationId", "uuid"))
obj("HistoryPage", "Lịch sử phiên bản.", ("items!", "[$HistoryVersion]"), ("page!", "int", 0), ("size!", "int", 20), ("totalElements!", "int", 5))
obj("DiffItem", "Khác biệt một thuộc tính.", ("attribute!", "acode", "phone"), ("before", "any", "0900000000"), ("after", "any", "0901234567"))
obj("HistorySnapshot", "Ảnh chụp một phiên bản; SENSITIVE che.", ("version!", "int", 5), ("snapshot!", "$GoldenRecord"), ("diff", "[$DiffItem]"))
obj("LineageEntry", "Một giá trị trong truy nguồn gốc.", ("sourceCode", "scode"), ("value", "any", "Nguyễn Văn A"), ("strategy", "E:SurvivorshipStrategy", "SOURCE_PRIORITY"), ("recordedAt", "ts"))
obj("LineageAttribute", "Nguồn gốc một thuộc tính.", ("attribute!", "acode", "fullName"), ("currentValue", "any", "Nguyễn Văn A"), ("history", "[$LineageEntry]"), ("perSourceValues", "[$LineageEntry]"))
obj("LineageResult", "Truy nguồn gốc thuộc tính (FR-06-043).", ("goldenId!", "uuid"), ("attributes!", "[$LineageAttribute]"))
obj("Xref", "Liên kết chéo nguồn.", ("xrefId!", "uuid"), ("sourceCode!", "scode"), ("sourceKey!", "str", "BN-2026-000123"), ("goldenId!", "uuid"), ("status!", "E:XrefStatus", "ACTIVE"), ("matchMethod", "E:MatchMethod", "DETERMINISTIC"), ("linkedAt", "ts"))
obj("XrefList", "Liên kết chéo của bản ghi vàng.", ("items!", "[$Xref]"))
obj("DetachRequest", "Gỡ liên kết chéo (FR-06-044).", ("reason!", "str", "Bản ghi nguồn thuộc người khác, gỡ khỏi bản ghi vàng.", R20), ("relink!", "E:RelinkMode", "NEW_GOLDEN"))
obj("XrefLookupItem", "Kết quả tra một khóa.", ("sourceCode", "scode"), ("sourceKey", "str", "BN-2026-000123"), ("goldenId!", "uuid"), ("status", "E:XrefStatus", "ACTIVE"), ("redirectedFrom", "uuid"), ("links", "[str]", []))
obj("XrefLookupResult", "Kết quả tra liên kết.", ("items!", "[$XrefLookupItem]"))
obj("XrefKey", "Khóa nguồn.", ("sourceCode!", "scode"), ("sourceKey!", "str", "BN-2026-000123"))
obj("BatchLookupRequest", "Tra hàng loạt, tối đa 500 khóa (ERR-06-018).", ("keys", "[$XrefKey]", None, {"maxItems": 500}), ("goldenIds", "[uuid]", None, {"maxItems": 500}), ("targetSources", "[scode]", ["HT-YTE"]))
obj("GoldenLookupRequest", "Tra bản ghi vàng; khóa định danh gửi trong thân, không lên đường dẫn.", ("goldenId", "uuid"), ("identifierType", "E:IdentifierType", "CCCD_12"), ("value", "str", "079090001234"), ("fields", "[acode]", ["fullName"]))
obj("ResolveRequest", "Giải quyết bản ghi trực tuyến (FR-06-047).", ("attributes!", "obj", {"fullName": "Nguyễn Văn A", "dateOfBirth": "1990-05-14"}), ("requestingSource!", "scode"), ("mode", "E:ResolveMode", "LOOKUP_ONLY"))
obj("ResolveCandidate", "Ứng viên khớp.", ("goldenId!", "uuid"), ("score!", "num", 0.91))
obj("ResolveResult", "Kết quả resolve.", ("outcome!", "E:MatchOutcome", "MATCH"), ("goldenId", "uuid"), ("score", "num", 0.97), ("method", "E:MatchMethod", "PROBABILISTIC_ONLINE"), ("attributeScores", "obj", {"fullName": 0.96}),
    ("candidates", "[$ResolveCandidate]"), ("queueItemId", "uuid"))
obj("SearchCriteria", "Tiêu chí tìm kiếm.", ("fullName", "str", "Nguyễn Văn A"), ("yearOfBirth", "int", 1990), ("adminUnitCode", "str", "79"), ("organizationName", "str", "Công ty Ánh Dương"), ("status", "E:GoldenStatus", "ACTIVE"))
obj("SearchRequest", "Tìm kiếm (FR-06-048).", ("criteria!", "$SearchCriteria"), ("page", "int", 0), ("size", "int", 20, {"maximum": 50}))
obj("SearchHit", "Kết quả rút gọn.", ("goldenId!", "uuid"), ("displayName!", "str", "Nguyễn Văn A"), ("yearOfBirth", "int", 1990), ("adminUnitName", "str", "Phường 1"), ("sourceCount", "int", 3), ("confidence", "num", 0.97), ("status!", "E:GoldenStatus", "ACTIVE"))
obj("SearchResult", "Trang kết quả; tổng số giới hạn hiển thị.", ("items!", "[$SearchHit]"), ("page!", "int", 0), ("size!", "int", 20), ("totalElements!", "int", 1), ("totalCapped", "bool", False))
# --- cung cấp
obj("ExportCreate", "Đề nghị xuất (FR-06-049).", ("domainCode!", "dcode"), ("filter", "obj", {"adminUnitCode": "79"}), ("fields!", "[acode]", ["fullName", "dateOfBirth"]), ("format!", "E:ExportFormat", "CSV"),
    ("purposeCode!", "code", "TK-THONG-KE"), ("legalBasis!", "str", "Nghị định 278/2025/NĐ-CP"), ("recipient!", "str", "Sở Kế hoạch và Đầu tư"), ("pseudonymize", "bool", True))
obj("Export", "Yêu cầu xuất.", ("exportId!", "uuid"), ("status!", "E:ExportStatus", "PENDING_APPROVAL"), ("format", "E:ExportFormat", "CSV"), ("rowCount", "int", 12000), ("downloadUrl", "str", "https://console.t68.datahub.example.vn/api/mdm/v1/exports/0193/file"), ("expiresAt", "ts"), *AUD)
obj("SubscriptionCreate", "Đăng ký nhận cập nhật (FR-06-051).", ("systemCode!", "str", "SYT-HSSK"), ("domainCode!", "dcode"), ("scope!", "E:SubscriptionScope", "LINKED_ONLY"),
    ("eventTypes!", "[str]", ["golden.updated"]), ("delivery!", "str", "PUSH", {"enum": ["PUSH", "PULL"]}), ("purposeCode!", "code", "TK-THONG-KE"))
obj("Subscription", "Đăng ký nhận cập nhật.", ("subscriptionId!", "uuid"), ("systemCode!", "str", "SYT-HSSK"), ("domainCode!", "dcode"), ("scope!", "E:SubscriptionScope", "LINKED_ONLY"), ("status!", "E:SubscriptionStatus", "PENDING_APPROVAL"),
    ("subscriptionRef", "str", "sub-0193"), ("delivery", "str", "PUSH", {"enum": ["PUSH", "PULL"]}), *AUD)
page("SubscriptionPage", "Subscription")
# --- đồng bộ quốc gia
obj("SyncStatus", "Trạng thái đồng bộ.", ("state!", "E:SyncState", "RUNNING"), ("lastRunAt", "ts"), ("checked", "int", 10000), ("discrepancies", "int", 12), ("ratio", "num", 0.0012), ("paused!", "bool", False), ("pauseReason", "str", "Chờ xử lý lệch vượt ngưỡng."))
obj("SyncRunRequest", "Chạy đồng bộ (FR-06-053).", ("direction!", "E:SyncDirection", "RECONCILE"), ("domainCode!", "dcode"), ("goldenIds", "[uuid]", None, {"maxItems": 10000}))
obj("SyncRunAccepted", "Lượt đồng bộ đã nhận.", ("runId!", "uuid"), ("status!", "E:JobStatus", "QUEUED"))
obj("Discrepancy", "Lệch giữa bản ghi vàng và CSDL quốc gia.", ("discrepancyId!", "uuid"), ("runId", "uuid"), ("goldenId!", "uuid"), ("attribute!", "acode", "fullName"), ("severity!", "E:DiscrepancySeverity", "MINOR"), ("status!", "E:DiscrepancyStatus", "OPEN"))
page("DiscrepancyPage", "Discrepancy")
obj("DiscrepancyResolveRequest", "Xử lý lệch (FR-06-054).", ("discrepancyIds!", "[uuid]", None, {"minItems": 1, "maxItems": 1000}), ("resolution!", "E:DiscrepancyResolution", "ACCEPT_NATIONAL"), ("reason!", "str", "Dữ liệu quốc gia mới hơn, chấp nhận giá trị quốc gia.", R20))
obj("DiscrepancyResolveResult", "Kết quả xử lý lệch.", ("processed!", "int", 3), ("skipped", "[$SkippedItem]"))
# --- vận hành
obj("DashboardMetrics", "Chỉ số dữ liệu chủ (FR-06-055).", ("metrics!", "obj", {"goldenCount": 1200000, "autoRate30d": 0.88, "queueOpen": 120, "queueOverdue": 4, "precision": 0.9993, "recall": 0.985}),
    ("series", "[obj]", [{"at": "2026-11-20T00:00:00+07:00", "autoRate": 0.88}]), ("bySource", "[obj]", [{"sourceCode": "HT-YTE", "candidates": 1000}]))
obj("JobSchedule", "Lịch job.", ("jobType!", "E:JobType", "BATCH_MATCH"), ("cron!", "str", "0 2 * * *"), ("enabled!", "bool", True), ("params", "obj", {}), ("maxDuration", "str", "PT4H"), ("nextRunAt", "ts"), *AUD)
page("JobSchedulePage", "JobSchedule")
obj("JobSchedulePut", "Sửa lịch job.", ("cron!", "str", "0 2 * * *"), ("enabled!", "bool", True), ("params", "obj", {}), ("maxDuration", "str", "PT4H"))
obj("ProcessingLog", "Dòng nhật ký xử lý.", ("loggedAt!", "ts"), ("level!", "str", "INFO", {"enum": ["INFO", "WARN", "ERROR"]}), ("jobId", "uuid"), ("candidateId", "uuid"), ("message!", "str", "Chuẩn hóa xong 500 bản ghi."))
page("ProcessingLogPage", "ProcessingLog")
obj("AccessLog", "Dòng nhật ký truy cập.", ("accessedAt!", "ts"), ("actor!", "str", "ds.pham"), ("systemCode", "str", "SYT-HSSK"), ("goldenId", "uuid"), ("purposeCode", "code", "TK-THONG-KE"), ("api!", "str", "API-06-056"), ("unmasked!", "bool", False))
page("AccessLogPage", "AccessLog")
obj("DsrCreate", "Tiếp nhận yêu cầu chủ thể (FR-06-058).", ("requestType!", "E:DsrType", "ACCESS"), ("subjectIdentifier!", "str", "079090001234"), ("verificationRef!", "str", "XM-2026-0456"), ("details", "str", "Yêu cầu xem dữ liệu cá nhân."), ("channel", "str", "COUNTER"), ("receivedAt", "ts"))
obj("Dsr", "Yêu cầu của chủ thể dữ liệu.", ("requestId!", "uuid"), ("requestType!", "E:DsrType", "ACCESS"), ("status!", "E:DsrStatus", "RECEIVED"), ("dueAt!", "ts"), ("reportUrl", "str", "https://console.t68.datahub.example.vn/api/mdm/v1/subject-requests/0193/report"), *AUD)
obj("DsrComplete", "Hoàn tất yêu cầu.", ("resultSummary!", "str", "Đã cung cấp bản trích xuất dữ liệu cho chủ thể.", {"minLength": 5}))
obj("DsrForward", "Chuyển yêu cầu sửa tới nguồn.", ("sourceCode!", "scode"), ("attributes!", "[acode]", ["phone"]), ("note", "str", "Chủ thể đề nghị đổi số điện thoại."))
obj("RetentionPolicy", "Chính sách lưu giữ.", ("objectType!", "str", "CANDIDATE_RECORD"), ("retentionDays!", "int", 365), ("action!", "E:RetentionAction", "ANONYMIZE"), ("legalHold!", "bool", False), *AUD)
page("RetentionPolicyPage", "RetentionPolicy")
obj("RetentionPolicyPut", "Sửa chính sách lưu giữ.", ("retentionDays!", "int", 365, {"minimum": 1}), ("action!", "E:RetentionAction", "ANONYMIZE"), ("legalHold!", "bool", False))
obj("Setting", "Một tham số.", ("key!", "str", "06.queue.sla-days", {"pattern": "^06\\.[a-z.-]+$"}), ("value!", "any", 7))
obj("SettingsDoc", "Tham số phân hệ theo tenant (FRS 8.2).", ("items!", "[$Setting]"), ("version", "int", 3))
obj("SettingsPut", "Sửa tham số.", ("items!", "[$Setting]"))
# enum dùng chung đã tham chiếu bằng $ref
for n in sorted(ENUMS):
    SCH[n] = enum_schema(n)
for n in ("MatchOutcome",):
    SCH.setdefault(n, enum_schema(n))

# ---------------------------------------------------------------- tham số đường dẫn
PATHP = {"domainCode": ("dcode", "CITIZEN"), "version": ("int", 3), "sourceCode": ("scode", "HT-YTE"), "proposalId": ("uuid", None), "fileId": ("uuid", None),
         "candidateId": ("uuid", None), "labelSetCode": ("code", "nhan-2026-q4"), "jobId": ("uuid", None), "itemId": ("uuid", None), "goldenId": ("uuid", None),
         "operationId": ("uuid", None), "xrefId": ("uuid", None), "sourceKey": ("str", "BN-2026-000123"), "exportId": ("uuid", None), "subscriptionId": ("uuid", None),
         "jobType": ("E:JobType", None), "requestId": ("uuid", None), "objectType": ("str", "CANDIDATE_RECORD")}
