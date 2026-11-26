#!/usr/bin/env python3
"""Nguồn duy nhất của hợp đồng API PH-11: đọc FRS §9.4 (mã, phương thức, đường dẫn, FR, quyền), §9.1 (mã lỗi), §9.3 (sự kiện),
Phụ lục A (enum), bảng operation và lược đồ. Không chạy trực tiếp; gen_openapi, gen_asyncapi, gen_md, check_contracts, doi_chieu_frs nhập module này.
Enum lấy thẳng từ Phụ lục A của FRS (E('Tên')), nên không thể lệch FRS."""
import json, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS_PATH = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH11-frs-quy-trinh.md")
FRS = open(FRS_PATH, encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]

# ---------------------------------------------------------------- FRS
ERR = {}  # mã -> (danh sách HTTP, ý nghĩa)
_s91 = FRS[FRS.index("### 9.1."):FRS.index("### 9.2.")]
for m in re.finditer(r"^\| (ERR-11-\d{3}) \| ([^|]+?) \| ([^|]+?) \|", _s91, re.M):
    ERR[m.group(1)] = ([int(x) for x in re.findall(r"\d{3}", m.group(2))], m.group(3).strip())
_s93 = FRS[FRS.index("### 9.3."):FRS.index("### 9.4.")]
EVT = [(m.group(1), m.group(2), m.group(3).strip(), m.group(4).strip(), m.group(5).strip()) for m in
       re.finditer(r"^\| (EVT-11-\d{2}) \| `([^`]+)` \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \|", _s93, re.M)]  # mã, topic, khóa, trường, bên nhận
PERMS = sorted(set(re.findall(r"PERM-11-[a-z-]+", FRS)))
_s92 = FRS[FRS.index("### 9.2."):FRS.index("### 9.3.")]
MSG = {m.group(1): m.group(2) for m in re.finditer(r"^\| (ERR-11-\d{3}) \| \"([^|]+)\" \|", _s92, re.M)}

_ENUM = {}
for _m in re.finditer(r"^\| ((?:`\w+`(?:, )?)+) \| ([^|]+) \|", APPX, re.M):
    names = re.findall(r"`(\w+)`", _m.group(1))
    parts = [p for p in _m.group(2).split(";")]
    for i, n in enumerate(names):
        p = _m.group(2) if len(names) == 1 else parts[i]
        _ENUM[n] = re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", p))
_t = FRS[FRS.index("| Nhóm | Phần tử BPMN (`StepType`)"):FRS.index(": Bảng 6.2-a.")]
_ENUM["StepType"] = [x for ln in _t.splitlines() if "Không hỗ trợ" not in ln and "StepType" not in ln for x in re.findall(r"`([A-Z][A-Z_]+)`", ln.split("|")[2] if ln.count("|") > 3 else "")]
_ENUM["StepType"] = list(dict.fromkeys(_ENUM["StepType"]))


def E(name):
    if not _ENUM.get(name):
        raise SystemExit("Không có enum %s ở Phụ lục A" % name)
    return _ENUM[name]


def fr_errs():
    """Với mỗi FR: tập (mã ERR, HTTP) ở mục Luồng ngoại lệ."""
    out = {}
    for m in re.finditer(r"#### (FR-11-\d{3}) · [^\n]+\n\n::: dac-ta\n(.*?)\n:::", FRS, re.S):
        x = re.search(r"\*\*Luồng ngoại lệ\.\*\*\s*(.*?)(?=\n\n\*\*|\Z)", m.group(2), re.S)
        out[m.group(1)] = sorted(set((a, int(c)) for a, b in re.findall(r"(ERR-11-\d{3}) \(((?:\d{3}(?:,| hoặc)? ?)+)\)", x.group(1)) for c in re.findall(r"\d{3}", b))) if x else []
    return out


FRERR = fr_errs()

# ---------------------------------------------------------------- operation theo FRS §9.4
def parse_perm(txt):
    """'task, `PERM-17-use`' -> dict(user=[...], scopes=[...], text, note)"""
    note = " ".join(re.findall(r"\(([^)]*)\)", txt))
    t = re.sub(r"\([^)]*\)", "", txt).strip()
    user, scopes, extra = [], [], []
    for part in t.split(";"):
        for tok in [x.strip() for x in part.split(",") if x.strip()]:
            b = re.match(r"`([^`]+)`$", tok)
            if b and b.group(1).startswith("bpm."):
                scopes.append(b.group(1))
            elif b and b.group(1).startswith("PERM-"):
                extra.append(b.group(1))
            else:
                user.append("PERM-11-" + tok.strip("`"))
    text = " hoặc ".join(user)
    if extra:
        text = (text + " và " + " và ".join(extra)) if text else " và ".join(extra)
    if scopes:
        text = (text + " hoặc scope " if text else "scope ") + " hoặc ".join(scopes)
    return dict(user=user, scopes=scopes, extra=extra, text=text, note=note)


ROWS = []  # (mã 3 số, phương thức, đường dẫn, [FR], phân tích quyền)
_sec = FRS[FRS.index("### 9.4."):FRS.index("## 10. Giao diện")]
for m in re.finditer(r"^\| API-11-(\d{3}) \| `([A-Z]+) ([^`]+)`[^|]*\| ([^|]+) \| ([^|]+) \|", _sec, re.M):
    ROWS.append((m.group(1), m.group(2), m.group(3), [f"FR-11-{x}" for x in re.findall(r"\d{3}", m.group(4))], parse_perm(m.group(5).strip())))
assert len(ROWS) == 137, len(ROWS)

# ---------------------------------------------------------------- bảng operation
# mã | tóm tắt | nhóm | thân yêu cầu | thân phản hồi | HTTP | truy vấn | cờ
# cờ: idem (Idempotency-Key), noifm (không If-Match), multipart, binary, also:HTTP, cache30 (Cache-Control)
TAGNAME = {
    "MH": "Mô hình quy trình", "PB": "Phiên bản và thiết kế", "PH": "Duyệt phát hành", "CT": "Chạy thử", "BM": "Biểu mẫu, ý định, bù trừ",
    "TL": "Mẫu, biến, bảng quyết định", "KT": "Khởi tạo và tra cứu phiên", "DK": "Điều khiển phiên", "TA": "Service task và thông điệp",
    "VI": "Việc của người dùng", "UQ": "Ủy quyền và phân công", "LH": "Lịch làm việc và hạn", "SG": "Saga và bù trừ", "TD": "Tiến độ và lịch sử",
    "GS": "Giám sát và sự cố", "CH": "Cấu hình và tuân thủ"}
OPS_TXT = """
001|Danh sách, tìm kiếm mô hình|MH|-|ModelPage|200|q:str,group:str,status:E:VersionStatus,archived:bool,page,size|
002|Chi tiết mô hình|MH|-|ModelDetail|200|-|
003|Tạo mô hình|MH|ModelCreate|ModelCreated|201|-|idem
004|Nhập mô hình từ tệp BPMN|MH|ModelImportRequest|ModelImported|201|-|idem noifm multipart
005|Sửa thuộc tính mô hình|MH|ModelUpdate|ModelDetail|200|-|
006|Lưu trữ mô hình|MH|ReasonBody|ModelDetail|200|-|
007|Danh sách phiên bản mô hình|PB|-|VersionPage|200|status:E:VersionStatus,page,size|
008|Tạo phiên bản nháp|PB|VersionCreate|VersionDetail|201|-|idem noifm
009|Chi tiết phiên bản và BPMN XML|PB|-|VersionDetail|200|-|
010|Lưu sơ đồ BPMN của bản nháp|PB|BpmnPut|BpmnSaved|200|-|
011|Cấu hình thuộc tính một phần tử|PB|ElementConfig|ElementSaved|200|-|
012|Khóa soạn thảo bản nháp|PB|-|LockResult|200|-|noifm
013|Mở khóa soạn thảo bản nháp|PB|-|LockResult|200|-|noifm
014|Kiểm tra tĩnh phiên bản|PB|ValidateRequest|ValidationReport|200|-|noifm
015|So sánh hai phiên bản|PB|-|VersionDiff|200|with:int|
016|Gửi duyệt phát hành|PH|PublishSubmit|PublishRequestAccepted|202|-|idem
017|Rút lại đề nghị phát hành|PH|CommentBody|PublishRequest|200|-|
018|Danh sách đề nghị phát hành|PH|-|PublishRequestPage|200|status:E:PublishRequestStatus,processKey:pkey,page,size|
019|Chi tiết đề nghị phát hành|PH|-|PublishRequest|200|-|
020|Duyệt phát hành và triển khai|PH|PublishApprove|PublishDecisionResult|200|-|
021|Từ chối phát hành|PH|RejectBody|PublishDecisionResult|200|-|
022|Ngừng dùng phiên bản|PH|DeprecateBody|VersionStatusResult|200|-|
023|Thu hồi phiên bản|PH|DeprecateBody|VersionStatusResult|200|-|
024|Xuất tệp BPMN hoặc gói quy trình|PB|-|binary|200|format:str|noifm binary
025|Tạo phiên chạy thử|CT|TestRunCreate|TestRun|201|-|idem noifm
026|Chi tiết phiên chạy thử|CT|-|TestRun|200|-|
027|Chạy bước tiếp của phiên chạy thử|CT|TestStepBody|TestRun|200|-|noifm
028|Danh mục phần tử BPMN hỗ trợ|PB|-|ElementCatalog|200|-|
029|Danh sách biểu mẫu|BM|-|FormPage|200|status:E:ResourceStatus,q:str,page,size|
030|Tạo biểu mẫu|BM|FormCreate|FormDetail|201|-|idem
031|Chi tiết biểu mẫu|BM|-|FormDetail|200|-|
032|Lưu phiên bản biểu mẫu|BM|FormVersionPut|FormVersion|200|-|
033|Phát hành phiên bản biểu mẫu|BM|-|FormVersion|200|-|
034|Danh sách ý định nghiệp vụ|BM|-|IntentPage|200|status:E:ResourceStatus,q:str,page,size|
035|Đăng ký ý định nghiệp vụ|BM|IntentUpsert|Intent|201|-|idem
036|Sửa ý định và ánh xạ luồng|BM|IntentUpsert|Intent|200|-|
037|Ngừng dùng ý định|BM|ReasonBody|Intent|200|-|
038|Ánh xạ ý định sang luồng PH-04|BM|-|IntentBindingList|200|environment:E:Environment|
039|Danh sách hành động bù trừ|BM|-|CompensationList|200|processKey:pkey,version:int|
040|Lưu hành động bù trừ của phiên bản|BM|CompensationPut|CompensationList|200|-|
041|Danh sách mẫu quy trình|TL|-|TemplatePage|200|status:E:ResourceStatus,q:str,page,size|
042|Tạo mẫu quy trình|TL|TemplateCreate|Template|201|-|idem
043|Phát hành mẫu quy trình|TL|CommentBody|Template|200|-|
044|Danh sách biến của phiên bản|TL|-|VariableList|200|-|
045|Lưu biến của phiên bản|TL|VariablePut|VariableList|200|-|
046|Danh sách bảng quyết định|TL|-|DecisionTablePage|200|q:str,page,size|
047|Lưu bảng quyết định|TL|DecisionTablePut|DecisionTable|200|-|
048|Thử bảng quyết định|TL|DecisionEvalRequest|DecisionEvalResult|200|-|noifm
049|Khởi tạo phiên|KT|InstanceStart|InstanceStarted|201|-|idem also:200
050|Danh sách, tìm kiếm phiên|KT|-|InstancePage|200|processKey:pkey,businessKey:str,status:E:InstanceStatus,waitState:E:WaitState,dueStatus:E:DueStatus,startChannel:E:StartChannel,tu:ts,den:ts,hasIncident:bool,page,size|
051|Chi tiết phiên|KT|-|InstanceDetail|200|-|
052|Tra phiên theo mã hồ sơ|KT|-|InstanceDetail|200|processKey:pkey,businessKey:bkey|
053|Dòng thời gian bước của phiên|KT|-|Timeline|200|page,size|
054|Sơ đồ tiến độ của phiên|KT|-|Diagram|200|-|
055|Biến của phiên|KT|-|VariableValues|200|unmask:bool|
056|Tạm dừng phiên|DK|SuspendBody|InstanceStateResult|200|-|
057|Tiếp tục phiên|DK|ReasonBody|InstanceStateResult|200|-|
058|Hủy phiên|DK|CancelBody|InstanceCancelResult|200|-|also:202
059|Đề nghị sửa biến hoặc chuyển bước|DK|InstanceChangeCreate|InstanceChangeAccepted|202|-|idem noifm
060|Chi tiết đề nghị thay đổi phiên|DK|-|InstanceChange|200|-|
061|Duyệt đề nghị thay đổi phiên|DK|CommentBody|InstanceChange|200|-|
062|Từ chối đề nghị thay đổi phiên|DK|RejectBody|InstanceChange|200|-|
063|Tạo kế hoạch di trú|DK|MigrationPlanCreate|MigrationPlan|201|-|idem
064|Kiểm tra kế hoạch di trú|DK|-|MigrationPlan|200|-|noifm
065|Gửi duyệt kế hoạch di trú|DK|CommentBody|MigrationPlan|200|-|
066|Duyệt và chạy di trú|DK|CommentBody|MigrationPlan|202|-|
067|Từ chối kế hoạch di trú|DK|RejectBody|MigrationPlan|200|-|
068|Chi tiết kế hoạch di trú|DK|-|MigrationPlan|200|-|
069|Gửi thông điệp tương quan vào phiên|TA|MessageCorrelate|MessageResult|202|-|idem
070|Danh sách lệnh service task của phiên|TA|-|ServiceCallPage|200|status:E:ServiceCallStatus,page,size|
071|Gửi lại lệnh service task|TA|ResendBody|ResendAccepted|202|-|idem noifm
072|Danh sách việc|VI|-|TaskPage|200|view:str,status:E:TaskStatus,kind:E:TaskKind,processKey:pkey,dueStatus:E:DueStatus,assignee:str,q:str,page,size|
073|Chi tiết việc|VI|-|TaskDetail|200|-|
074|Nhận việc|VI|-|TaskAssignResult|200|-|
075|Trả lại việc|VI|ReasonBody|TaskAssignResult|200|-|
076|Hoàn thành việc|VI|TaskComplete|TaskCompleted|200|-|idem
077|Lưu nháp kết quả việc|VI|TaskDraft|DraftSaved|200|-|
078|Chuyển việc cho người khác|VI|TransferBody|TaskAssignResult|200|-|
079|Danh sách ủy quyền|UQ|-|DelegationPage|200|status:E:DelegationStatus,user:str,page,size|
080|Tạo ủy quyền|UQ|DelegationCreate|Delegation|201|-|idem
081|Thu hồi ủy quyền|UQ|ReasonBody|Delegation|200|-|
082|Phân công lại hàng loạt|UQ|BulkReassign|BulkReassignResult|202|-|idem noifm
083|Danh sách ý kiến trên việc|VI|-|CommentPage|200|page,size|
084|Thêm ý kiến trên việc|VI|CommentCreate|TaskComment|201|-|idem
085|Đính kèm tệp vào việc|VI|AttachmentUpload|TaskAttachment|201|-|idem noifm multipart
086|Tải tệp đính kèm|VI|-|binary|200|-|binary
087|Trả về bước trước|VI|TaskReturnBody|TaskReturned|200|-|
088|Yêu cầu bổ sung hồ sơ|VI|SupplementRequest|SupplementRequested|200|-|
089|Báo hồ sơ đã bổ sung|TA|SupplementReceived|SupplementAccepted|202|-|idem noifm
090|Xem lịch làm việc|LH|-|CalendarList|200|year:int|
091|Lưu lịch làm việc theo năm|LH|CalendarYearPut|CalendarSaved|200|-|
092|Nhập lịch làm việc từ tệp|LH|CalendarImport|CalendarSaved|200|-|multipart
093|Tính thử hạn xử lý|LH|DueComputeRequest|DueComputed|200|-|noifm
094|Báo cáo đúng hạn, trễ hạn|LH|-|DueReport|200|groupBy:str,processKey:pkey,tu:ts,den:ts|
095|Xuất báo cáo hạn|LH|DueExportRequest|ExportAccepted|202|-|idem noifm
096|Danh sách Saga|SG|-|SagaPage|200|status:E:SagaStatus,processKey:pkey,businessKey:str,tu:ts,den:ts,page,size|
097|Chi tiết Saga|SG|-|SagaDetail|200|-|
098|Kích hoạt bù trừ thủ công|SG|CompensateRequest|SagaAccepted|202|-|idem noifm
099|Thử lại bước bù trừ|SG|ReasonBody|SagaStepResult|200|-|noifm
100|Xác nhận đã xử lý thủ công bước bù trừ|SG|ManualResolveBody|SagaStepResult|200|-|noifm
101|Đề nghị bỏ qua bước bù trừ|SG|SkipBody|SkipRequested|200|-|noifm
102|Danh sách lượt đối soát bù trừ|SG|-|ReconciliationPage|200|page,size|
103|Chạy đối soát bù trừ|SG|ReconcileRequest|Reconciliation|202|-|idem
104|Tiến độ hồ sơ cho kênh DVC|TD|-|Progress|200|processKey:pkey|cache30
105|Lịch sử bước đầy đủ của phiên|TD|-|HistoryPage|200|page,size|
106|Xuất lịch sử bước|TD|HistoryExportRequest|ExportAccepted|202|-|idem noifm
107|Bảng điều khiển giám sát|GS|-|MonitoringSummary|200|processKey:pkey,tu:ts,den:ts|
108|Bước tắc nghẽn|GS|-|BottleneckList|200|processKey:pkey|
109|Danh sách sự cố engine|GS|-|IncidentPage|200|type:E:IncidentType,status:E:IncidentStatus,processKey:pkey,page,size|
110|Chi tiết sự cố|GS|-|Incident|200|-|
111|Thử lại sự cố|GS|ReasonBody|Incident|200|-|noifm
112|Bỏ qua sự cố|GS|ReasonBody|Incident|200|-|noifm
113|Thử lại sự cố hàng loạt|GS|BulkRetryRequest|BulkRetryResult|200|-|idem noifm
114|Xem quy tắc cảnh báo|GS|-|AlertRuleList|200|-|
115|Lưu quy tắc cảnh báo|GS|AlertRulePut|AlertRuleList|200|-|
116|Xem tham số tenant|CH|-|SettingsDoc|200|prefix:str|
117|Lưu tham số tenant|CH|SettingsPut|SettingsDoc|200|-|
118|Xem chính sách lưu giữ|CH|-|RetentionPolicy|200|-|
119|Sửa chính sách lưu giữ|CH|RetentionPut|RetentionPolicy|200|-|
120|Đặt giữ pháp lý cho hồ sơ|CH|LegalHoldCreate|LegalHold|201|-|idem
121|Chạy mẫu bằng chứng tuân thủ|CH|SampleRunRequest|EvidencePackAccepted|202|-|idem
122|Tải gói bằng chứng tuân thủ|CH|-|binary|200|-|binary
123|Nhật ký kiểm toán phân hệ|TD|-|AuditLogPage|200|actor:str,action:str,objectType:str,objectId:str,tu:ts,den:ts,page,size|
124|Gợi ý xử lý việc bằng AI|VI|AiSuggestRequest|AiSuggestions|200|-|noifm
125|Hộp việc cho Việc của tôi|VI|-|InboxItemPage|200|updatedSince:ts,page,size|
126|Danh sách liên kết sự kiện khởi tạo|KT|-|EventStartBindingPage|200|processKey:pkey,page,size|
127|Biểu mẫu khởi tạo thủ công|KT|-|StartForm|200|version:int|
128|Xuất danh sách phiên ra CSV|KT|InstanceExportRequest|ExportAccepted|202|-|idem noifm
129|Xuất danh sách Saga ra CSV|SG|SagaExportRequest|ExportAccepted|202|-|idem noifm
130|Xuất nhật ký kiểm toán ra CSV|TD|AuditLogExportRequest|ExportAccepted|202|-|idem noifm
131|Đề nghị khôi phục phiên bản ngừng dùng|PH|ReasonBody|PublishRequestAccepted|202|-|idem
132|Duyệt bỏ qua bước bù trừ|SG|CommentBody|SagaStepResult|200|-|noifm
133|Từ chối bỏ qua bước bù trừ|SG|RejectBody|SagaStepResult|200|-|noifm
134|Danh sách giữ pháp lý|CH|-|LegalHoldPage|200|businessKey:str,released:bool,page,size|
135|Gỡ giữ pháp lý|CH|ReasonBody|LegalHold|200|-|
136|Yêu cầu quyền sửa bản nháp|PB|LockRequestBody|LockRequestResult|200|-|noifm
137|Danh sách lần chạy mẫu tuân thủ|CH|-|SampleRunPage|200|environment:E:Environment,page,size|
"""
ENUMS = set()
OPS = {}
for ln in OPS_TXT.strip().splitlines():
    c, s, tag, rq, rs, st, q, fl = ln.split("|")
    OPS[c] = dict(code=c, summary=s, tag=TAGNAME[tag], req=None if rq == "-" else rq, res=rs, status=int(st),
                  query=[] if q == "-" else q.split(","), flags=fl.split())
assert set(OPS) == {r[0] for r in ROWS}, set(OPS) ^ {r[0] for r in ROWS}
for _o in OPS.values():
    for _q in _o["query"]:
        if ":E:" in _q:
            ENUMS.add(_q.split(":E:")[1])
TAGS = list(dict.fromkeys(o["tag"] for o in sorted(OPS.values(), key=lambda o: list(TAGNAME.values()).index(o["tag"]))))

# ---------------------------------------------------------------- lược đồ
PKEY = "^[A-Z][A-Z0-9_]{2,63}$"
CODE = "^[A-Za-z][A-Za-z0-9_.-]{0,63}$"
TYPES = {
    "str": ({"type": "string"}, "ví dụ"), "code": ({"type": "string", "pattern": CODE}, "ma-1"),
    "pkey": ({"type": "string", "pattern": PKEY}, "LT_KHAI_SINH"),
    "bkey": ({"type": "string", "minLength": 3, "maxLength": 100}, "HS-T68-2026-000142"),
    "user": ({"type": "string", "minLength": 1, "maxLength": 100}, "cb.nguyenvana"),
    "int": ({"type": "integer"}, 1), "num": ({"type": "number"}, 0.9), "bool": ({"type": "boolean"}, False),
    "ts": ({"type": "string", "format": "date-time"}, "2026-11-26T08:00:00+07:00"),
    "date": ({"type": "string", "format": "date"}, "2026-11-26"),
    "uuid": ({"type": "string", "format": "uuid"}, "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"),
    "bin": ({"type": "string", "format": "binary"}, "(tệp)"),
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


_FS = re.compile(r"^(\w+)(!?):([^=]+)(?:=(.*))?$")


def obj(name, desc, *fields, extra=None):
    """Mỗi trường: chuỗi 'tên[!]:kiểu[=ví dụ JSON]' hoặc bộ (chuỗi, ràng buộc dict)."""
    props, req, exs = {}, [], {}
    for f in fields:
        cons = None
        if isinstance(f, tuple):
            f, cons = f
        m = _FS.match(f)
        fn, r, ft, ex = m.group(1), m.group(2), m.group(3), m.group(4)
        if ex is not None:
            try:
                ex = json.loads(ex)
            except ValueError:
                ex = ex
        if ft.startswith("E:") or ft.startswith("[E:"):
            ENUMS.add(ft.strip("[]")[2:])
        s, dex = tschema(ft, cons if ft.startswith("[") else None)
        if cons and not ft.startswith("["):
            if "$ref" in s:
                s = {"allOf": [s], **cons}
            else:
                s.update(cons)
        props[fn] = s
        if r:
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


def page(name, item, desc="Trang kết quả."):
    obj(name, desc, "items!:[$%s]" % item, "page!:int=0", "size!:int=20", "totalElements!:int=1")


def enum_schema(name):
    return {"type": "string", "enum": E(name)}


R10 = {"minLength": 10, "maxLength": 2000}
R20 = {"minLength": 20, "maxLength": 2000}
AUD = ["createdAt:ts", "updatedAt:ts"]
UID = "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"
PK = "LT_KHAI_SINH"

obj("FieldError", "Lỗi theo trường.", "field!:str=variables.maXa", "message!:str=Giá trị không hợp lệ.")
obj("Problem", "Lỗi theo RFC 9457.", "type!:str=https://datahub.example.vn/errors/ERR-11-003", "title!:str=Dữ liệu không hợp lệ", "status!:int=400",
    "detail:str=Thiếu hoặc sai kiểu biến.", "instance:str=/api/bpm/v1/instances", "code!:str=ERR-11-003", "traceId!:str=4bf92f3577b34da6a3ce929d0e0e4736", "errors:[$FieldError]")
obj("CommentBody", "Ý kiến kèm hành động.", ("comment:str=Đồng ý theo biên bản họp ngày 20/11/2026.", {"maxLength": 2000}))
obj("WaiverDecision", "Quyết định một miễn bù trừ `NONE_APPROVED` (khác người đề nghị, ERR-11-005).", "elementId!:str=Task_CapTheBHYT", "decision!:E:Decision=APPROVE", "reason:str=Bước chỉ đọc, không phát sinh dữ liệu cần hủy.")
obj("PublishApprove", "Duyệt phát hành; `waiverDecisions[]` quyết định từng miễn bù trừ (mỗi giá trị `decision` là `APPROVE` hoặc `REJECT`).", ("comment:str=Đồng ý theo biên bản họp ngày 20/11/2026.", {"maxLength": 2000}), "waiverDecisions:[$WaiverDecision]")
obj("RejectBody", "Từ chối: bắt buộc nêu lý do từ 20 ký tự (BR-11-016).", ("comment!:str=Thiếu căn cứ pháp lý của bước thu phí, đề nghị bổ sung.", R20))
obj("ReasonBody", "Hành động kèm lý do từ 10 ký tự.", ("reason!:str=Cơ quan BHXH bảo trì hệ thống đến 17 giờ.", R10))
obj("SkippedItem", "Phần tử bị bỏ qua.", "id!:str=0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "reason!:str=Trạng thái không cho thao tác.")
obj("Due", "Hạn xử lý (kiểu T-DUE: giá trị và đơn vị).", ("value!:int=5", {"minimum": 1, "maximum": 3650}), "unit!:E:DueUnit=WORKING_DAY")
obj("DueInfo", "Hạn của phiên hoặc việc.", "status!:E:DueStatus=ON_TIME", "dueAt:ts", "dueSoonAt:ts", "pausedAt:ts", "pauseReason:E:PauseReason", "escalationLevel:int=0", "result:E:DueResult")
obj("ExportAccepted", "Yêu cầu xuất đã nhận, chạy bất đồng bộ.", "exportId!:uuid", "status!:str=QUEUED", ("expiresAt:ts", None))
obj("CheckItem", "Một kết quả kiểm tra tĩnh (FR-11-005).", "ruleCode!:str=MISSING_INTENT", "severity!:E:CheckSeverity=ERROR", "elementId:str=Task_CapTheBHYT", "message!:str=Bước tự động chưa có ý định.")
obj("ValidationReport", "Kết quả kiểm tra tĩnh.", "blocking!:bool=false", "errors!:[$CheckItem]", "checkedAt!:ts")
obj("ValidationSummary", "Tóm tắt kiểm tra tĩnh.", "blocking!:bool=false", "errorCount:int=0", "warningCount:int=1", "checkedAt:ts")
# --- mô hình
obj("ModelSummary", "Mô hình quy trình (dòng danh sách).", "processKey!:pkey", "name!:str=Liên thông khai sinh, thường trú, BHYT", "group!:str=TTHC_LIEN_THONG",
    "latestVersion:int=3", "latestStatus:E:VersionStatus=PUBLISHED", "publishedVersion:int=3", "runningInstances:int=42", "updatedAt:ts")
page("ModelPage", "ModelSummary")
obj("ModelDetail", "Chi tiết mô hình quy trình.", "processKey!:pkey", "name!:str=Liên thông khai sinh, thường trú, BHYT", "group!:str=TTHC_LIEN_THONG", "description:str=Liên thông ba thủ tục cho trẻ dưới 6 tuổi.",
    "ownerOrgCode:str=SO-TP", "defaultDue:$Due", "allowedStarters:[str]=[\"DVC-T68\"]", "allowManualStart:bool=true", "archived!:bool=false", "latestVersion:int=3", "publishedVersion:int=3", *AUD)
obj("ModelCreate", "Tạo mô hình: trống, từ mẫu (`templateCode`) hoặc nhập tệp (API-11-004).", "processKey!:pkey", "name!:str=Duyệt kết nạp HTTT hai cấp", "group!:str=DUYET_TICH_HOP",
    "description:str", "templateCode:code=MAU_LIEN_THONG_3_CO_QUAN", "defaultDue:$Due", "allowedStarters:[str]=[\"PH-01\"]", "allowManualStart:bool=false")
obj("ModelCreated", "Mô hình vừa tạo kèm bản nháp 1.", "processKey!:pkey", "version!:int=1", "status!:E:VersionStatus=DRAFT", "validation:$ValidationSummary")
obj("ModelImportRequest", "Nhập tệp BPMN 2.0 (multipart).", "file!:bin", "processKey!:pkey", "name!:str=Duyệt kết nạp HTTT hai cấp", "group!:str=DUYET_TICH_HOP")
obj("ImportReport", "Báo cáo nhập: phần tử bị gỡ, cảnh báo, ý định thiếu.", "removed:[str]=[]", "warnings:[str]=[]", "missingIntents:[str]=[]")
obj("ModelImported", "Kết quả nhập tệp BPMN.", "processKey!:pkey", "version!:int=1", "report!:$ImportReport")
obj("ModelUpdate", "Sửa thuộc tính mô hình.", "name:str=Liên thông khai sinh, thường trú, BHYT", "group:str=TTHC_LIEN_THONG", "description:str", "defaultDue:$Due", "allowedStarters:[str]=[\"DVC-T68\"]", "allowManualStart:bool=true")
# --- phiên bản
obj("VersionSummary", "Phiên bản mô hình.", "processKey!:pkey", "version!:int=3", "status!:E:VersionStatus=DRAFT", "checksum:str=sha256:3f2a9c", "basedOn:int=2",
    "lockOwner:str=ie.tranvanc", "lockUntil:ts", "validation:$ValidationSummary", "publishedAt:ts", *AUD)
page("VersionPage", "VersionSummary")
obj("VersionDetail", "Phiên bản kèm BPMN XML.", "processKey!:pkey", "version!:int=3", "status!:E:VersionStatus=DRAFT", "checksum:str=sha256:3f2a9c", "basedOn:int=2",
    "changeSummary:str=Thêm bước cấp thẻ BHYT.", "bpmnXml:str=<definitions/>", "lockOwner:str", "lockUntil:ts", "deploymentId:str", "validation:$ValidationSummary", "publishedAt:ts", *AUD)
obj("VersionCreate", "Tạo bản nháp mới từ phiên bản có sẵn.", "basedOn:int=2", ("changeSummary:str=Thêm bước cấp thẻ BHYT.", {"maxLength": 2000}))
obj("BpmnPut", "Lưu sơ đồ BPMN do bpmn-js sinh (`If-Match` theo ETag phiên bản).", ("bpmnXml!:str=<definitions/>", {"minLength": 1}))
obj("BpmnSaved", "Kết quả lưu sơ đồ.", "version!:int=3", "checksum!:str=sha256:3f2a9c", "validation!:$ValidationReport")
obj("Assignment", "Phân công việc người dùng.", "type!:E:AssignmentType=CANDIDATE_GROUP", "value!:str=CB_TU_PHAP_XA")
obj("ElementConfig", "Thuộc tính một phần tử (bảng 6.2-b của FRS).", "stepType!:E:StepType=USER_TASK", "name:str=Tiếp nhận hồ sơ", ("publicName:str=Đăng ký khai sinh", {"maxLength": 120}),
    "assignment:$Assignment", "formKey:code=BM_TIEP_NHAN", "taskKind:E:TaskKind=STANDARD", "due:$Due", "intentCode:code=DK_KHAI_SINH", "inputMapping:obj", "outputMapping:obj",
    "timeoutMinutes:int=2880", "businessErrors:[str]=[]", "timerType:str=DURATION", "timerExpression:str=PT30M", "messageName:str", "correlationKey:str", "calledProcessKey:pkey",
    "separateFrom:[str]=[]", "allowReturnTo:[str]=[]", "allowSupplement:bool=false")
obj("ElementSaved", "Phần tử đã cập nhật.", "elementId!:str=Task_TiepNhan", "config!:$ElementConfig", "validation:$ValidationReport")
obj("LockResult", "Trạng thái khóa soạn thảo.", "locked!:bool=true", "lockOwner:str=ie.tranvanc", "lockUntil:ts")
obj("ValidateRequest", "Yêu cầu kiểm tra tĩnh.", "mode:E:ValidateMode=FULL", "targetEnvironment:E:Environment=TEST")
obj("FieldChange", "Thay đổi một trường.", "path!:str=assignment.value", "before:any=CB_A", "after:any=CB_B")
obj("ElementChange", "Phần tử khác nhau.", "elementId!:str=Task_TiepNhan", "fields!:[$FieldChange]")
obj("VersionDiff", "So sánh hai phiên bản.", "added!:[str]=[\"Task_CapTheBHYT\"]", "removed!:[str]=[]", "changed!:[$ElementChange]", "variables:obj", "compensations:obj")
obj("ElementCatalogItem", "Phần tử hỗ trợ ở bản MVP.", "stepType!:E:StepType=USER_TASK", "group!:str=Việc", "properties:[str]=[\"assignment\"]")
obj("ElementCatalog", "Danh mục phần tử BPMN (bảng 6.2-a).", "items!:[$ElementCatalogItem]", "unsupported:[str]=[\"SCRIPT_TASK\"]")
# --- duyệt phát hành
obj("PublishSubmit", "Gửi duyệt phát hành.", ("releaseNote!:str=Thêm bước cấp thẻ BHYT theo thông báo của BHXH tỉnh.", {"minLength": 10, "maxLength": 2000}), "targetEnvironment:E:Environment=PROD", "requestedApprover:user")
obj("PublishRequestAccepted", "Đề nghị đã nhận.", "publishRequestId!:uuid", "status!:E:PublishRequestStatus=PENDING", "taskId:uuid")
obj("PublishRequest", "Đề nghị phát hành (EN-11-20).", "id!:uuid", "processKey!:pkey", "version!:int=3", "kind!:E:PublishKind=PUBLISH", "releaseNote:str=Thêm bước cấp thẻ BHYT.", "checksum:str=sha256:3f2a9c",
    "status!:E:PublishRequestStatus=PENDING", "requestedBy:user", "requestedAt:ts", "decidedBy:user", "decidedAt:ts", "comment:str", "deploymentId:str", "taskId:uuid")
page("PublishRequestPage", "PublishRequest")
obj("PublishDecisionResult", "Kết quả duyệt hoặc từ chối.", "publishRequestId!:uuid", "status!:E:PublishRequestStatus=APPROVED", "version:int=3", "deploymentId:str", "publishedAt:ts")
obj("DeprecateBody", "Ngừng dùng hoặc thu hồi phiên bản.", ("reason!:str=Thay bằng phiên bản 4 theo văn bản 123/BC-SNV.", R10), "confirmSolePublished:bool=false")
obj("VersionStatusResult", "Trạng thái phiên bản sau thao tác.", "version!:int=3", "status!:E:VersionStatus=DEPRECATED", "runningInstances:int=0")
# --- chạy thử
obj("TestRunCreate", "Kịch bản chạy thử (service task giả lập).", "scenario!:obj={\"variables\":{\"maXa\":\"26734\"},\"serviceResults\":{\"Task_DangKyKhaiSinh\":{\"outcome\":\"OK\"}}}")
obj("TestStepBody", "Cho chạy bước tiếp.", "elementId:str=Task_TiepNhan", "decision:str=APPROVE", "result:obj")
obj("TestRun", "Phiên chạy thử.", "testRunId!:uuid", "status!:E:TestRunStatus=RUNNING", "timeline:[$TimelineItem]", "variables:obj", "tasks:[$TaskSummary]", "saga:obj")
# --- biểu mẫu, ý định, bù trừ
obj("FormSummary", "Biểu mẫu việc người dùng.", "formKey!:code=BM_TIEP_NHAN", "name!:str=Tiếp nhận hồ sơ", "latestVersion:int=2", "status!:E:ResourceStatus=PUBLISHED", "updatedAt:ts")
page("FormPage", "FormSummary")
obj("FormCreate", "Tạo biểu mẫu.", "formKey!:code=BM_TIEP_NHAN", "name!:str=Tiếp nhận hồ sơ", "description:str", "schema!:obj={\"type\":\"object\"}", "uiSchema:obj", "decisions:[str]=[\"APPROVE\",\"REJECT\"]", "fieldClassification:obj")
obj("FormVersionPut", "Lưu phiên bản biểu mẫu (JSON Schema).", "schema!:obj={\"type\":\"object\"}", "uiSchema:obj", "decisions:[str]=[\"APPROVE\",\"REJECT\"]", "fieldClassification:obj")
obj("FormVersion", "Phiên bản biểu mẫu.", "formKey!:code=BM_TIEP_NHAN", "version!:int=2", "status!:E:ResourceStatus=DRAFT", "schema:obj", "uiSchema:obj", "decisions:[str]=[\"APPROVE\",\"REJECT\"]", "fieldClassification:obj")
obj("FormDetail", "Chi tiết biểu mẫu.", "formKey!:code=BM_TIEP_NHAN", "name!:str=Tiếp nhận hồ sơ", "description:str", "status!:E:ResourceStatus=DRAFT", "versions:[$FormVersion]", *AUD)
obj("IntentBinding", "Ánh xạ ý định sang luồng PH-04 theo môi trường.", "environment!:E:Environment=PROD", "flowCode!:str=dk-khai-sinh", "flowVersion:int=2", "flowPublished:bool=true")
obj("IntentUpsert", "Đăng ký hoặc sửa ý định nghiệp vụ.", "intentCode!:code=DK_KHAI_SINH", "name!:str=Đăng ký khai sinh", "description:str", "inputSchema:obj", "outputSchema:obj", "writesExternal!:bool=true",
    "businessErrors:[str]=[\"HO_SO_TRUNG\"]", "timeoutSeconds:int=172800", "bindings:[$IntentBinding]")
obj("Intent", "Ý định nghiệp vụ.", "intentCode!:code=DK_KHAI_SINH", "name!:str=Đăng ký khai sinh", "status!:E:ResourceStatus=ACTIVE", "writesExternal!:bool=true", "bindings:[$IntentBinding]", *AUD)
page("IntentPage", "Intent")
obj("IntentBindingList", "Danh sách ánh xạ của một ý định.", "items!:[$IntentBinding]")
obj("Compensation", "Hành động bù trừ của một bước (EN-11-05).", "elementId!:str=Task_DangKyKhaiSinh", "policy!:E:CompensationPolicy=AUTO", "compensationIntentCode:code=HUY_KHAI_SINH",
    "inputMapping:obj", "businessNote:str=Hủy giấy khai sinh đã cấp số.", "verifyIntentCode:code", "waiverApprovedBy:user")
obj("CompensationList", "Hành động bù trừ của phiên bản.", "items!:[$Compensation]")
obj("CompensationPut", "Lưu hành động bù trừ.", "items!:[$Compensation]")
# --- mẫu, biến, bảng quyết định
obj("Template", "Mẫu quy trình dùng chung (`COMMON`).", "templateCode!:code=MAU_LIEN_THONG_3_CO_QUAN", "name!:str=Liên thông ba cơ quan", "status!:E:ResourceStatus=DRAFT", "placeholders:[str]=[\"ORG_1\"]", "updatedAt:ts")
page("TemplatePage", "Template")
obj("TemplateCreate", "Tạo mẫu quy trình.", "templateCode!:code=MAU_LIEN_THONG_3_CO_QUAN", "name!:str=Liên thông ba cơ quan", "description:str", "sourceXml!:str=<definitions/>", "placeholders:[str]=[\"ORG_1\"]")
obj("VariableDef", "Khai báo biến quy trình (EN-11-07).", "name!:str=hoTenTre", "type!:E:VariableType=STRING", "requiredAtStart:bool=true", "dataClass!:E:DataClass=RESTRICTED", "encrypt:bool=true", "mask:bool=true", "editableBy:[str]=[]")
obj("VariableList", "Biến của phiên bản.", "variables!:[$VariableDef]")
obj("VariablePut", "Lưu biến.", "variables!:[$VariableDef]")
obj("DecisionTableSummary", "Bảng quyết định.", "code!:code=BANG_RE_NHANH_HO_SO", "version!:int=1", "name!:str=Rẽ nhánh theo loại hồ sơ", "hitPolicy:str=FIRST", "updatedAt:ts")
page("DecisionTablePage", "DecisionTableSummary")
obj("DecisionTablePut", "Lưu bảng quyết định.", "name!:str=Rẽ nhánh theo loại hồ sơ", "hitPolicy!:str=FIRST", "inputs!:[str]=[\"loaiTTHC\"]", "outputs!:[str]=[\"nhanh\"]", "rules!:[obj]=[{\"when\":[\"LT_KS_TT_BHYT\"],\"then\":[\"BA_CO_QUAN\"]}]")
obj("DecisionTable", "Bảng quyết định đã lưu.", "code!:code=BANG_RE_NHANH_HO_SO", "version!:int=1", "name!:str=Rẽ nhánh theo loại hồ sơ", "hitPolicy!:str=FIRST", "inputs!:[str]=[\"loaiTTHC\"]", "outputs!:[str]=[\"nhanh\"]", "rules:[obj]=[]")
obj("DecisionEvalRequest", "Đầu vào thử.", "inputs!:obj={\"loaiTTHC\":\"LT_KS_TT_BHYT\"}")
obj("DecisionEvalResult", "Kết quả thử.", "matchedRules!:[int]=[1]", "outputs!:obj={\"nhanh\":\"BA_CO_QUAN\"}")
# --- phiên
obj("InstanceStart", "Khởi tạo phiên (FR-11-018).", "processKey!:pkey", "businessKey!:bkey", "version:int=3", "variables:obj={\"loaiTTHC\":\"LT_KS_TT_BHYT\",\"maXa\":\"26734\"}", "startChannel:E:StartChannel=API", "callbackTopic:str=t68.motcua.hoso.ketqua.v1")
obj("InstanceStarted", "Phiên đã khởi tạo.", "instanceId!:uuid", "processKey!:pkey", "version!:int=3", "businessKey!:bkey", "status!:E:InstanceStatus=RUNNING", "dueAt:ts", "progressUrl!:str=/api/bpm/v1/progress/HS-T68-2026-000142")
obj("InstanceSummary", "Phiên (dòng danh sách).", "instanceId!:uuid", "businessKey!:bkey", "processKey!:pkey", "version!:int=3", "status!:E:InstanceStatus=RUNNING", "waitState:E:WaitState=WAITING_USER",
    "currentElements:[str]=[\"Task_DangKyThuongTru\"]", "dueAt:ts", "dueStatus:E:DueStatus=ON_TIME", "startedAt:ts", "incidentCount:int=0")
page("InstancePage", "InstanceSummary")
obj("InstanceDetail", "Chi tiết phiên (biến lấy qua API-11-055).", "instanceId!:uuid", "businessKey!:bkey", "processKey!:pkey", "version!:int=3", "status!:E:InstanceStatus=RUNNING", "waitState:E:WaitState=WAITING_USER",
    "currentElements:[str]=[\"Task_DangKyThuongTru\"]", "startChannel:E:StartChannel=API", "initiator:str=dvc-t68", "parentInstanceId:uuid", "traceId:str=4bf92f3577b34da6a3ce929d0e0e4736", "startedAt:ts", "endedAt:ts",
    "due:$DueInfo", "openTasks:[$TaskSummary]", "sagaId:uuid", "incidentIds:[uuid]")
obj("TimelineItem", "Một mốc trên dòng thời gian.", "at!:ts", "elementId!:str=Task_DangKyKhaiSinh", "name:str=Đăng ký khai sinh", "type:E:StepType=SERVICE_TASK", "status:str=DONE", "actor:str=system", "decision:str", "durationMs:int=1200")
obj("Timeline", "Dòng thời gian bước.", "items!:[$TimelineItem]", "page!:int=0", "size!:int=20", "totalElements!:int=1")
obj("ElementState", "Trạng thái phần tử trên sơ đồ.", "elementId!:str=Task_DangKyKhaiSinh", "state!:E:PublicStepStatus=DONE")
obj("Diagram", "Sơ đồ kèm trạng thái.", "xml!:str=<definitions/>", "elementStates!:[$ElementState]")
obj("VariableValue", "Giá trị biến (đã che theo phân loại).", "name!:str=hoTenTre", "type:E:VariableType=STRING", "dataClass:E:DataClass=RESTRICTED", "value:any=N** V** B", "masked!:bool=true")
obj("VariableValues", "Biến của phiên.", "items!:[$VariableValue]")
obj("SuspendBody", "Tạm dừng phiên.", ("reason!:str=Chờ công văn trả lời của Công an tỉnh.", R10), "pauseDue:bool=false")
obj("InstanceStateResult", "Trạng thái phiên sau thao tác.", "instanceId!:uuid", "status!:E:InstanceStatus=SUSPENDED", "suspendedAt:ts", "resumedAt:ts")
obj("CancelBody", "Hủy phiên.", ("reason!:str=Công dân rút hồ sơ theo đề nghị ngày 26/11/2026.", R10), "compensate:E:CancelCompensate=AUTO")
obj("InstanceCancelResult", "Kết quả hủy: `200` hủy ngay, `202` đang bù trừ.", "instanceId!:uuid", "status!:E:InstanceStatus=CANCELLED", "sagaId:uuid")
obj("InstanceChangeCreate", "Đề nghị sửa biến hoặc chuyển bước (bốn mắt).", "type!:E:ChangeType=VARIABLE_UPDATE", ("reason!:str=Sửa mã xã nhập sai khi tiếp nhận hồ sơ.", R20), "variables:obj={\"maXa\":\"26735\"}", "targetElementId:str")
obj("InstanceChangeAccepted", "Đề nghị đã nhận.", "changeId!:uuid", "status!:E:ChangeStatus=PENDING")
obj("InstanceChange", "Đề nghị thay đổi phiên (EN-11-27).", "changeId!:uuid", "instanceId!:uuid", "type!:E:ChangeType=VARIABLE_UPDATE", "status!:E:ChangeStatus=PENDING", "reason:str=Sửa mã xã nhập sai.", "requestedBy:user", "approvedBy:user", "appliedAt:ts")
obj("MappingItem", "Ánh xạ bước cũ sang bước mới.", "fromElementId!:str=Task_TiepNhan", "toElementId!:str=Task_TiepNhanV4")
obj("MigrationPlanCreate", "Kế hoạch di trú phiên.", "processKey!:pkey", "fromVersion!:int=3", "toVersion!:int=4", "filter:obj={\"status\":\"RUNNING\"}", "mappings:[$MappingItem]", "reason:str=Sửa bước thu phí theo thông tư mới.")
obj("MigrationSummary", "Tổng hợp di trú.", "total!:int=42", "migrated!:int=0", "failed!:int=0")
obj("MigrationPlan", "Kế hoạch di trú (EN-11-19).", "planId!:uuid", "processKey!:pkey", "fromVersion!:int=3", "toVersion!:int=4", "status!:E:MigrationStatus=DRAFT", "mappings:[$MappingItem]", "unmappedElements:[str]=[]",
    "requestedBy:user", "approvedBy:user", "summary:$MigrationSummary")
obj("MessageCorrelate", "Thông điệp tương quan.", "messageName!:str=KET_QUA_CONG_AN", "businessKey!:bkey", "processKey:pkey", "variables:obj")
obj("MessageResult", "Kết quả gửi thông điệp.", "instanceId!:uuid", "delivered!:bool=true")
obj("ServiceCall", "Lệnh service task (EN-11-25).", "commandId!:uuid", "elementId!:str=Task_DangKyKhaiSinh", "intentCode!:code=DK_KHAI_SINH", "status!:E:ServiceCallStatus=COMPLETED", "attempt!:int=1",
    "requestedAt:ts", "timeoutAt:ts", "completedAt:ts", "errorKind:E:ErrorKind", "errorCode:str")
page("ServiceCallPage", "ServiceCall")
obj("ResendBody", "Gửi lại lệnh.", ("reason!:str=Kết quả không về trước hạn, gửi lại sau khi PH-04 khôi phục.", R10))
obj("ResendAccepted", "Lệnh đã gửi lại.", "commandId!:uuid", "attempt!:int=2")
# --- việc
obj("TaskSummary", "Việc (dòng danh sách, không có giá trị biến).", "taskId!:uuid", "instanceId!:uuid", "businessKey!:bkey", "processKey!:pkey", "elementId!:str=Task_DangKyThuongTru", "name!:str=Đăng ký thường trú",
    "kind!:E:TaskKind=STANDARD", "status!:E:TaskStatus=UNASSIGNED", "assignee:user", "candidates:[str]=[\"CB_CONG_AN_XA\"]", "dueAt:ts", "dueStatus:E:DueStatus=ON_TIME", "priority:int=50", "createdAt:ts")
page("TaskPage", "TaskSummary")
obj("FormRef", "Biểu mẫu của việc.", "formKey!:code=BM_TIEP_NHAN", "version!:int=2", "schema!:obj={\"type\":\"object\"}", "uiSchema:obj", "decisions!:[str]=[\"APPROVE\",\"REJECT\"]")
obj("TaskComment", "Ý kiến trên việc.", "commentId!:uuid", "author!:user", "text!:str=Đã đối chiếu giấy tờ.", "mentions:[user]=[]", "createdAt:ts")
obj("TaskAttachment", "Tệp đính kèm.", "attachmentId!:uuid", "fileName!:str=giay-chung-sinh.pdf", "size!:int=204800", "checksum:str=sha256:7be1", "dataClass:E:DataClass=RESTRICTED", "scanStatus:str=CLEAN", "createdAt:ts")
obj("TaskHistoryItem", "Mốc xử lý trước của việc.", "at!:ts", "actor:user", "action!:str=CLAIM", "comment:str")
obj("TaskDetail", "Chi tiết việc.", "task!:$TaskSummary", "form:$FormRef", "data:obj", "history:[$TaskHistoryItem]", "comments:[$TaskComment]", "attachments:[$TaskAttachment]", "due:$DueInfo", "allowedActions:[str]=[\"CLAIM\"]", "draft:obj")
obj("TaskAssignResult", "Người nhận sau thao tác.", "taskId!:uuid", "status!:E:TaskStatus=ASSIGNED", "assignee:user")
obj("TaskComplete", "Hoàn thành việc (FR-11-038).", "decision!:E:Decision=APPROVE", "data:obj={\"ketLuan\":\"Đủ điều kiện\"}", ("comment:str=Hồ sơ đủ điều kiện theo kiểm tra ngày 26/11/2026.", {"maxLength": 2000}))
obj("TaskCompleted", "Việc đã hoàn thành.", "taskId!:uuid", "status!:E:TaskStatus=COMPLETED", "nextTasks:[$TaskSummary]")
obj("TaskDraft", "Nháp kết quả việc.", "data!:obj={\"ghiChu\":\"Chờ tra cứu thêm\"}", "comment:str")
obj("DraftSaved", "Đã lưu nháp.", "savedAt!:ts")
obj("TransferBody", "Chuyển việc.", "toUser!:user=cb.lethib", ("reason!:str=Chuyển cho cán bộ phụ trách địa bàn xã.", R10))
obj("Delegation", "Ủy quyền khi vắng mặt (EN-11-12).", "delegationId!:uuid", "fromUser!:user=cb.nguyenvana", "toUser!:user=cb.lethib", "validFrom!:ts", "validTo!:ts", "status!:E:DelegationStatus=SCHEDULED",
    "scope:obj={\"processKeys\":[\"LT_KHAI_SINH\"]}", "includeExisting:bool=false", "reason:str=Nghỉ phép năm.")
page("DelegationPage", "Delegation")
obj("DelegationCreate", "Tạo ủy quyền.", "fromUser:user=cb.nguyenvana", "toUser!:user=cb.lethib", "validFrom!:ts", "validTo!:ts", "scope:obj", "includeExisting:bool=false", "reason:str=Nghỉ phép năm.")
obj("BulkReassign", "Giao lại hàng loạt (tối đa `11.task.bulkMax`).", ("taskIds!:[uuid]", {"minItems": 1, "maxItems": 2000}), "toUser:user=cb.lethib", "toGroup:str", ("reason!:str=Cán bộ nghỉ việc, giao lại cho tổ tiếp nhận.", R10))
obj("BulkReassignResult", "Kết quả giao lại.", "jobId!:uuid", "succeeded!:int=3", "skipped:[$SkippedItem]")
page("CommentPage", "TaskComment")
obj("CommentCreate", "Thêm ý kiến.", ("text!:str=Đã gọi điện xác nhận với công dân.", {"minLength": 1, "maxLength": 4000}), "mentions:[user]=[]")
obj("AttachmentUpload", "Tải tệp lên (multipart).", "file!:bin", "dataClass:E:DataClass=RESTRICTED")
obj("TaskReturnBody", "Trả về bước trước.", "targetElementId:str=Task_TiepNhan", ("comment!:str=Thiếu bản sao giấy chứng sinh, trả về tiếp nhận.", R20))
obj("TaskReturned", "Việc đã trả về.", "taskId!:uuid", "status!:E:TaskStatus=COMPLETED", "targetElementId:str=Task_TiepNhan")
obj("SupplementRequest", "Yêu cầu bổ sung hồ sơ.", ("comment!:str=Cần bổ sung giấy chứng sinh bản sao có chứng thực.", R20), "supplementDays:int=15", "items:[str]=[\"Giấy chứng sinh\"]")
obj("SupplementRequested", "Đã yêu cầu bổ sung.", "taskId!:uuid", "status!:E:InstanceStatus=RUNNING", "pausedDueAt:ts", "supplementDueAt:ts")
obj("SupplementReceived", "Báo đã nhận bổ sung.", "receivedAt:ts", "comment:str=Công dân nộp bổ sung qua Cổng DVC.")
obj("SupplementAccepted", "Đã nhận báo bổ sung.", "instanceId!:uuid", "dueAt:ts")
obj("AiSuggestRequest", "Yêu cầu gợi ý (PH-17).", "fields:[str]=[\"ketLuan\"]")
obj("Suggestion", "Một gợi ý.", "field!:str=ketLuan", "value:any=Đủ điều kiện", "rationale:str=Giấy tờ khớp thông tin công dân.")
obj("AiSuggestions", "Gợi ý xử lý việc; cán bộ vẫn quyết định.", "suggestions!:[$Suggestion]")
obj("InboxItem", "Mục hộp việc cho FR-00-070 (không có giá trị biến).", "taskId!:uuid", "title!:str=Đăng ký thường trú", "processKey!:pkey", "businessKey!:bkey", "assignee:user", "candidates:[str]=[\"CB_CONG_AN_XA\"]", "dueAt:ts", "dueStatus:E:DueStatus=ON_TIME", "priority:int=50", "link!:str=/quy-trinh/viec/0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01")
page("InboxItemPage", "InboxItem")
# --- lịch, hạn
obj("CalendarDay", "Ngày nghỉ hoặc làm bù.", "date!:date=2026-12-25", "type!:E:CalendarDayType=SPECIAL_OFF", "name:str=Nghỉ theo quyết định của tỉnh", "legalRef:str")
obj("WorkHours", "Giờ làm việc.", "start!:str=07:30", "end!:str=17:00", "breakStart:str=11:30", "breakEnd:str=13:00")
obj("CalendarYear", "Lịch làm việc một năm.", "year!:int=2026", "timezone!:str=Asia/Ho_Chi_Minh", "workDays!:[str]=[\"MON\",\"TUE\",\"WED\",\"THU\",\"FRI\"]", "workHours!:$WorkHours", "days:[$CalendarDay]", "inheritedFrom:str=COMMON")
obj("CalendarList", "Lịch làm việc theo năm.", "items!:[$CalendarYear]")
obj("CalendarYearPut", "Lưu lịch năm.", "workDays!:[str]=[\"MON\",\"TUE\",\"WED\",\"THU\",\"FRI\"]", "workHours!:$WorkHours", "days:[$CalendarDay]")
obj("CalendarImport", "Nhập lịch từ tệp CSV (multipart).", "file!:bin")
obj("CalendarSaved", "Lịch đã lưu.", "calendar!:$CalendarYear", "recalculatedDues!:int=0")
obj("DueComputeRequest", "Tính thử hạn.", "startAt!:ts", "amount!:int=5", "unit!:E:DueUnit=WORKING_DAY", "calendarYear:int=2026")
obj("DueExplain", "Ngày bỏ qua và lý do.", "date!:date=2026-12-05", "reason!:str=Thứ Bảy")
obj("DueComputed", "Hạn tính được.", "dueAt!:ts", "dueSoonAt:ts", "explain:[$DueExplain]")
obj("DueRow", "Một dòng báo cáo hạn.", "key!:str=LT_KHAI_SINH", "met!:int=120", "missed!:int=6", "overdueOpen!:int=3", "onTimeRate!:num=0.95", "p50Hours:num=20.5", "p90Hours:num=62")
obj("DueReport", "Báo cáo đúng hạn, trễ hạn.", "rows!:[$DueRow]")
obj("DueExportRequest", "Xuất báo cáo hạn.", "groupBy:str=processKey", "processKey:pkey", "from!:ts", "to!:ts", "format:str=CSV")
# --- Saga
obj("SagaSummary", "Saga bù trừ (dòng danh sách).", "sagaId!:uuid", "businessKey!:bkey", "instanceId!:uuid", "trigger!:E:CompensationTrigger=STEP_FAILURE", "status!:E:SagaStatus=RUNNING", "stepCount!:int=3", "manualCount:int=0", "startedAt:ts", "endedAt:ts")
page("SagaPage", "SagaSummary")
obj("ManualEvidence", "Bằng chứng xử lý thủ công (FR-11-053; tệp theo quy tắc FR-11-043).", "note!:str=Đã gọi Sở Tư pháp hủy giấy khai sinh số 123.", "docNumber:str=45/BB-STP", "objectRef:str=s3://dh-bpm/t68/evidence/0193b1d4.pdf", "confirmedBy:str=Nguyễn Văn B, Sở Tư pháp")
obj("SagaStep", "Bước bù trừ (EN-11-17).", "stepId!:uuid", "seq!:int=1", "forwardElementId!:str=Task_DangKyKhaiSinh", "compensationIntentCode:code=HUY_KHAI_SINH", "status!:E:SagaStepStatus=PENDING",
    "attempt:int=0", "commandId:uuid", "responseCode:str", "evidence:str", "resolvedBy:user", "lastError:str")
obj("SagaDetail", "Chi tiết Saga.", "saga!:$SagaSummary", "failedElementId:str=Task_CapTheBHYT", "errorCode:str=ERR-11-105", "steps!:[$SagaStep]")
obj("CompensateRequest", "Kích hoạt bù trừ thủ công.", ("reason!:str=Phát hiện hồ sơ khai sinh cấp nhầm xã, cần hủy.", R10))
obj("SagaAccepted", "Saga đã bắt đầu.", "sagaId!:uuid", "steps:[$SagaStep]")
obj("SagaStepResult", "Trạng thái sau xử lý bước.", "stepStatus!:E:SagaStepStatus=DONE", "sagaStatus!:E:SagaStatus=RUNNING")
obj("ManualResolveBody", "Xác nhận đã xử lý thủ công, kèm bằng chứng.", ("reason!:str=Đã gọi Sở Tư pháp hủy giấy khai sinh số 123.", R20), ("evidence!:[$ManualEvidence]", {"minItems": 1}))
obj("SkipBody", "Đề nghị bỏ qua bước; TA khác duyệt qua API-11-132, 133 (không truyền người duyệt).", ("reason!:str=Bên nhận xác nhận không phát sinh dữ liệu cần hủy.", R20), "evidence:[$ManualEvidence]")
obj("SkipRequested", "Đề nghị bỏ qua đã ghi; bước còn `MANUAL` đến khi duyệt.", "stepStatus!:E:SagaStepStatus=MANUAL", "sagaStatus!:E:SagaStatus=PARTIAL", "taskId:uuid")
obj("Reconciliation", "Lượt đối soát bù trừ.", "reconciliationId!:uuid", "status!:E:ReconcileStatus=RUNNING", "checked:int=0", "mismatched:int=0", "startedAt:ts", "finishedAt:ts")
page("ReconciliationPage", "Reconciliation")
obj("ReconcileRequest", "Chạy đối soát.", "processKey:pkey", "from:ts", "to:ts")
# --- tiến độ, lịch sử
obj("PublicStep", "Bước công khai cho công dân.", "publicName!:str=Đăng ký khai sinh", "status!:E:PublicStepStatus=DONE", "at:ts")
obj("Progress", "Tiến độ rút gọn cho kênh DVC; không có biến, không tên cán bộ.", "businessKey!:bkey", "displayStatus!:E:DisplayStatus=IN_PROGRESS", "percentEstimate:int=66", "dueAt:ts", "steps!:[$PublicStep]", "message:str=Hồ sơ đang được cơ quan BHXH xử lý cấp thẻ BHYT.")
obj("HistoryEvent", "Mốc lịch sử bước.", "at!:ts", "elementId!:str=Task_DangKyKhaiSinh", "name:str=Đăng ký khai sinh", "type:E:StepType=SERVICE_TASK", "actor:str=system", "decision:str", "comment:str", "durationWorkingHours:num=1.5")
obj("HistoryPage", "Lịch sử bước đầy đủ.", "events!:[$HistoryEvent]", "page!:int=0", "size!:int=20", "totalElements!:int=1")
obj("HistoryExportRequest", "Xuất lịch sử.", "format:str=PDF", "includeComments:bool=true")
obj("AuditLog", "Dòng nhật ký kiểm toán.", "at!:ts", "actor!:str=ta.phamvand", "action!:str=MODEL_PUBLISH", "objectType!:str=process_version", "objectId!:str=LT_KHAI_SINH:3", "detail:str", "hashRef:str=h:0193b1d4")
page("AuditLogPage", "AuditLog")
# --- giám sát, cấu hình
obj("Card", "Thẻ chỉ số.", "code!:str=running", "label!:str=Phiên đang chạy", "value!:num=42", "unit:str=phiên")
obj("TrendPoint", "Điểm xu hướng.", "date!:date=2026-11-25", "started!:int=30", "completed!:int=28", "overdue!:int=2")
obj("Bottleneck", "Bước tắc nghẽn.", "processKey!:pkey", "elementId!:str=Task_CapTheBHYT", "waiting!:int=12", "p95Hours:num=40", "oldestHours:num=96")
obj("BottleneckList", "Bước tắc nghẽn.", "items!:[$Bottleneck]")
obj("MonitoringSummary", "Bảng điều khiển giám sát.", "cards!:[$Card]", "trends:[$TrendPoint]", "bottlenecks:[$Bottleneck]")
obj("Incident", "Sự cố engine (EN-11-18).", "incidentId!:uuid", "type!:E:IncidentType=JOB_FAILED", "status!:E:IncidentStatus=OPEN", "instanceId:uuid", "businessKey:bkey", "elementId:str=Task_CapTheBHYT",
    "message:str=Job hết lượt thử.", "errorCode:str=ERR-11-107", "retriesDone:int=3", "openedAt:ts", "resolvedAt:ts", "handledBy:user", "reason:str", "traceId:str=4bf92f3577b34da6a3ce929d0e0e4736")
page("IncidentPage", "Incident")
obj("BulkRetryRequest", "Thử lại hàng loạt.", ("incidentIds!:[uuid]", {"minItems": 1, "maxItems": 100}), ("reason!:str=PH-04 đã khôi phục sau bảo trì.", R10))
obj("BulkRetryItem", "Kết quả một sự cố.", "incidentId!:uuid", "status!:E:IncidentStatus=RETRYING")
obj("BulkRetryResult", "Kết quả thử lại hàng loạt.", "results!:[$BulkRetryItem]")
obj("AlertRule", "Quy tắc cảnh báo vận hành.", "code!:code=OUTBOX_BACKLOG", "metric!:str=outbox.pending", "operator!:str=GT", "threshold!:num=1000", "severity!:str=P2", "channel:str=PH-13", "enabled!:bool=true")
obj("AlertRuleList", "Quy tắc cảnh báo.", "items!:[$AlertRule]")
obj("AlertRulePut", "Lưu quy tắc cảnh báo.", "items!:[$AlertRule]")
obj("Setting", "Tham số `11.*` theo tenant.", "key!:str=11.task.dueSoonHours", "value!:any=8")
obj("SettingsDoc", "Tham số của tenant.", "settings!:[$Setting]")
obj("SettingsPut", "Sửa tham số; ngoài miền trả ERR-11-029.", "settings!:[$Setting]")
obj("RetentionPolicy", "Chính sách lưu giữ.", "instanceYears!:int=5", "sagaYears!:int=5", "progressEventYears!:int=2", "engineHistoryMonths!:int=12", "cleanupCron!:str=0 0 1 * * *", "testRetentionDays:int=7", "lastCleanup:obj")
obj("RetentionPut", "Sửa chính sách lưu giữ (miền theo FRS 8.2).", "instanceYears:int=5", "sagaYears:int=5", "progressEventYears:int=2", "engineHistoryMonths:int=12", "cleanupCron:str=0 0 1 * * *", "testRetentionDays:int=7")
obj("LegalHoldCreate", "Đặt giữ pháp lý.", "businessKey!:bkey", ("reason!:str=Theo yêu cầu của Thanh tra tỉnh số 56/YC-TTT.", R20), "holdUntil:ts")
obj("LegalHold", "Giữ pháp lý.", "holdId!:uuid", "businessKey!:bkey", "reason:str", "holdUntil:ts", "createdBy:user", "createdAt:ts", "releasedAt:ts", "releasedBy:user", "releaseReason:str")
page("LegalHoldPage", "LegalHold")
obj("SampleRunRequest", "Chạy mẫu bằng chứng tuân thủ BPMN 2.0 (FR-11-064).", "environment!:E:Environment=TEST", "includeModels:[pkey]=[\"LT_KHAI_SINH\"]", "from:ts", "to:ts")
obj("SampleRun", "Một lần chạy mẫu tuân thủ.", "evidencePackId!:uuid", "environment!:E:Environment=TEST", "status!:E:TestRunStatus=PASSED", "requestedBy:user", "startedAt:ts", "finishedAt:ts", "checksum:str=sha256:5d0e")
page("SampleRunPage", "SampleRun")
obj("LockRequestBody", "Yêu cầu quyền sửa; không tự nhả khóa của người giữ.", ("message:str=Cần sửa bước thu phí trước 15 giờ.", {"maxLength": 500}))
obj("LockRequestResult", "Đã báo người giữ khóa (EVT-11-20).", "notified!:bool=true", "lockOwner:str=ie.tranvanc", "requestedAt:ts")
obj("InstanceExportRequest", "Xuất CSV kết quả lọc phiên (≤ 50.000 dòng; bộ lọc như API-11-050).", "status:E:InstanceStatus", "processKey:pkey", "businessKey:str", "from:ts", "to:ts", ("format:str=CSV", {"enum": ["CSV"]}))
obj("SagaExportRequest", "Xuất CSV danh sách Saga (≤ 50.000 dòng).", "status:E:SagaStatus", "processKey:pkey", "businessKey:str", "from:ts", "to:ts", ("format:str=CSV", {"enum": ["CSV"]}))
obj("AuditLogExportRequest", "Xuất CSV nhật ký kiểm toán (khoảng tối đa 366 ngày, ERR-11-039).", "actor:str", "action:str", "objectType:str", "objectId:str", "from!:ts", "to!:ts", ("format:str=CSV", {"enum": ["CSV"]}))
obj("EvidencePackAccepted", "Gói bằng chứng đang dựng.", "evidencePackId!:uuid", "status!:str=QUEUED")
obj("EventStartBinding", "Liên kết sự kiện PH-10 khởi tạo phiên (FR-11-019).", "processKey!:pkey", "topic!:str=t68.motcua.hoso.tiepnhan.v1", "eventType:str=hoso.tiepnhan", "mapping:obj", "enabled!:bool=true", "lastReceivedAt:ts")
page("EventStartBindingPage", "EventStartBinding")
obj("StartForm", "Biểu mẫu khởi tạo thủ công.", "processKey!:pkey", "version!:int=3", "formKey:code=BM_KHOI_TAO", "schema:obj={\"type\":\"object\"}", "uiSchema:obj", "variables:[$VariableDef]")

for n in sorted(ENUMS):
    SCH[n] = enum_schema(n)

# ---------------------------------------------------------------- tham số đường dẫn
PATHP = {"processKey": ("pkey", "LT_KHAI_SINH"), "version": ("int", 3), "elementId": ("str", "Task_DangKyKhaiSinh"), "id": ("uuid", None), "formKey": ("code", "BM_TIEP_NHAN"),
         "intentCode": ("code", "DK_KHAI_SINH"), "templateCode": ("code", "MAU_LIEN_THONG_3_CO_QUAN"), "code": ("code", "BANG_RE_NHANH_HO_SO"), "instanceId": ("uuid", None),
         "taskId": ("uuid", None), "attachmentId": ("uuid", None), "commandId": ("uuid", None), "year": ("int", 2026), "sagaId": ("uuid", None), "stepId": ("uuid", None),
         "businessKey": ("bkey", "HS-T68-2026-000142"), "incidentId": ("uuid", None), "holdId": ("uuid", None)}
