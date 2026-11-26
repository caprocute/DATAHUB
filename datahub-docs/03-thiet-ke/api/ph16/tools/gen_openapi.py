#!/usr/bin/env python3
"""Sinh openapi-kpi.yaml (OpenAPI 3.1) của PH-16 từ spec.py. Chạy từ thư mục api/ph16:  python3 tools/gen_openapi.py
Không sửa tay tệp YAML. Mọi operation có x-datahub-id, x-datahub-fr, x-datahub-permission, x-datahub-errors."""
import copy, os, re, sys
import yaml


class NoAlias(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


def _str(dumper, v):
    # chuỗi toàn chữ số (số định danh) luôn đặt trong nháy để YAML 1.2 không hiểu thành số
    if re.fullmatch(r"[0-9+.eE-]+", v):
        return dumper.represent_scalar("tag:yaml.org,2002:str", v, style="'")
    return dumper.represent_scalar("tag:yaml.org,2002:str", v)


NoAlias.add_representer(str, _str)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

OUT = os.path.join(spec.ROOT, "openapi-kpi.yaml")
SC = spec.SCH
STATUS = {400: ("BadRequest", "Dữ liệu không hợp lệ", "ERR-16-003"), 401: ("Unauthorized", "Chưa xác thực", "ERR-00-401"),
          403: ("Forbidden", "Không đủ quyền", "ERR-00-403"), 404: ("NotFound", "Không tìm thấy", "ERR-16-001"),
          409: ("Conflict", "Xung đột", "ERR-16-006"), 410: ("Gone", "Đã không còn", "ERR-16-035"),
          422: ("Unprocessable", "Không xử lý được", "ERR-16-007"), 503: ("ServiceUnavailable", "Dịch vụ phụ thuộc không khả dụng", "ERR-16-031")}
GET_ERRS = {"ERR-16-001", "ERR-16-035", "ERR-16-037", "ERR-16-038", "ERR-16-057"}
# mã lỗi của FR gộp không áp cho operation này (FR có nhiều bước hoặc nhiều operation, operation chỉ thực hiện một bước)
DROP = {}
# mã lỗi bổ sung cho operation (mã nêu ở FRS nhưng FR không gắn)
ADD = {}
OWN = {"002": "002", "005": "006 014", "007": "006 008 009 010 014", "008": "008 009", "009": "008 009", "011": "007 011", "012": "005", "013": "005 007", "014": "007",
       "015": "007 013 054", "017": "012", "018": "002", "020": "055", "022": "002 015", "024": "015 016", "025": "015 016", "026": "007", "027": "", "028": "007 017", "029": "006",
       "030": "101 102 103 104", "032": "019 021 022", "034": "019 022", "035": "053 022", "037": "020 022", "038": "021 022", "039": "018 019 022", "040": "005 021", "041": "005 007",
       "045": "006", "047": "024", "050": "022 023", "052": "007", "055": "007 022 023", "057": "025", "058": "007 026", "060": "002 027", "062": "027", "063": "027",
       "065": "002 028 033", "067": "032", "068": "032", "069": "022 023 028", "071": "029 030", "072": "005", "073": "005 007", "074": "005 031", "075": "006 007", "076": "007",
       "079": "034 037", "083": "036", "084": "036", "095": "002 039 041", "097": "040", "098": "002", "099": "041", "100": "042", "101": "039", "103": "045", "104": "045",
       "105": "", "106": "", "107": "043", "108": "005 043", "109": "005 007", "110": "044 007", "111": "056", "113": "", "115": "047", "117": "047", "118": "046 048 049 052",
       "121": "046", "122": "050 007", "124": "001 003 006", "125": "056", "128": "051"}
KEEP001 = {"090", "093"}
EX_STATUS = {"011": "PENDING_APPROVAL", "012": "ACTIVE", "013": "CHANGES_REQUESTED", "014": "DRAFT", "015": "RETIRED", "026": "PAUSED", "027": "ACTIVE", "028": "RETIRED",
             "029": "QUEUED", "039": "SUBMITTED", "040": "ACCEPTED", "041": "REJECTED", "050": "QUEUED", "052": "CANCELLED", "055": "QUEUED", "057": "CLOSED", "058": "REOPENED",
             "069": "QUEUED", "071": "IN_REVIEW", "072": "APPROVED", "073": "CHANGES_REQUESTED", "074": "PUBLISHED", "075": "DRAFT", "076": "WITHDRAWN", "079": "QUEUED",
             "100": "DEPRECATED", "107": "SUBMITTED", "108": "CONFIRMED", "109": "REJECTED", "111": "QUEUED", "121": "SENDING", "122": "SENDING", "125": "QUEUED"}
NOTE = {
    "002": "Tạo chỉ tiêu `scope = TENANT` và phiên bản 1 `DRAFT` chưa có công thức. `BOOLEAN` chỉ đi với `TARGET_RANGE` và `LAST`; `RATIO` có đơn vị `%` (ERR-16-003).",
    "007": "Chỉ sửa được phiên bản `DRAFT` hoặc `CHANGES_REQUESTED`. Sửa chỉ tiêu mẫu `COMMON` trực tiếp trả ERR-16-014. Sửa công thức làm mất kết quả thử tính cũ (ERR-16-011 khi gửi duyệt).",
    "008": "Kiểm cú pháp CEL, kiểu và biến đã có nguồn; không tính giá trị. Sai cú pháp trả ERR-16-008 kèm `line`, `column`; biến chưa có nguồn trả ERR-16-009.",
    "009": "Đồng bộ, tính trên quan sát và số liệu tay đã có của 1…6 kỳ đã qua; không ghi giá trị chỉ tiêu. Kết quả gắn `dryRunHash` của nội dung hiện tại.",
    "011": "Phải có kết quả thử tính của đúng nội dung hiện tại (ERR-16-011); người gửi không được tự duyệt (ERR-16-005 ở API-16-012).",
    "012": "Người duyệt khác người soạn, gửi (bốn mắt, ERR-16-005). Duyệt xong phiên bản `ACTIVE`, phiên bản cũ chuyển `SUPERSEDED`; phát EVT-16-01.",
    "015": "Chỉ tiêu đang có trong báo cáo chờ duyệt trả ERR-16-013; `replacedBy` phải đang hiệu lực, cùng loại giá trị (ERR-16-054). Phát EVT-16-02.",
    "017": "Gồm đủ năm nhóm cố định; tổng `weight` phải bằng 100 (ERR-16-012). Trọng số mới có hiệu lực từ `effectiveFrom` cho kỳ chưa chốt.",
    "018": "Sao chỉ tiêu mẫu `COMMON` sang tenant ở `DRAFT`; chỉ tiêu đã có bị bỏ qua và nêu ở `skipped`. Để trống `indicatorCodes` là kế thừa toàn bộ bộ mẫu.",
    "020": "`ACCEPT` tạo phiên bản nháp mới từ mẫu; trường tenant đã tùy biến mà mẫu cũng đổi thì trả ERR-16-055.",
    "025": "Thử đọc một lượt, không ghi quan sát. Cấu hình thiếu trường theo loại trả ERR-16-015; không đọc được trả ERR-16-016.",
    "026": "Nguồn `PAUSED` không bị chuyển `STALE`, `FAILED`; chỉ tiêu dùng nguồn này ghi `MISSING_SOURCE` khi tổng hợp.",
    "028": "Nguồn là nguồn duy nhất của chỉ tiêu đang hiệu lực thì trả ERR-16-017.",
    "029": "Không thân: kéo ngay. Có `from`, `to` (tối đa 12 tháng): đọc bù. Chỉ với nguồn `PULL_API`; kết quả xem ở API-16-042.",
    "030": "Scope `kpi.ingest`, 1…500 quan sát mỗi lô. `202` khi mọi phần tử được nhận, `207` khi có phần tử lỗi (ERR-16-101…104 ở `results[].code`). Cùng `idempotencyRef` khác giá trị trả ERR-16-103; thuộc kỳ đã chốt thì lưu làm số trễ (ERR-16-104).",
    "032": "Bắt buộc bằng chứng khi `16.manual.evidence-required = true` (ERR-16-018 khi gửi xác nhận); giá trị ngoài miền trả ERR-16-019; kỳ đã chốt trả ERR-16-022.",
    "035": "`multipart/form-data`; PDF, PNG, JPG, XLSX, DOCX tối đa `16.manual.max-file-mb` (ERR-16-053). Chỉ khi số liệu `DRAFT`.",
    "036": "Trả tệp XLSX mẫu mới nhất của các chỉ tiêu `MANUAL`, `MIXED`.",
    "037": "`multipart/form-data`, tối đa 2.000 dòng và 10 MB; sai mẫu trả ERR-16-020. Chưa ghi số liệu: trả bản xem trước theo dòng.",
    "038": "Ghi các dòng `VALID` thành số liệu `DRAFT`; dòng `INVALID` bị bỏ.",
    "040": "Người xác nhận khác người nhập (ERR-16-005); đã có số liệu `ACCEPTED` cho chỉ tiêu và kỳ trả ERR-16-021. Phát EVT-16-04.",
    "041": "Từ chối bắt buộc lý do từ 20 ký tự (ERR-16-007). Phát EVT-16-04.",
    "042": "Nhật ký theo lô, theo sự kiện và theo lần kéo; không chứa nội dung quan sát nhạy cảm.",
    "045": "Chỉ quan sát bị loại do lỗi sửa được (ví dụ thiếu hợp đồng chỉ số); xử lý lại tối đa 500 mỗi lần.",
    "050": "`trigger` chỉ nhận `MANUAL`; `SCHEDULE`, `LATE_DATA` do hệ thống đặt, `RECOMPUTE` qua API-16-055. Mỗi kỳ một lần chạy tại một thời điểm (ERR-16-023); kỳ `CLOSED` trả ERR-16-022. Lần chạy bắt đầu ở `QUEUED`, theo dõi ở API-16-051; phát EVT-16-05 khi xong.",
    "052": "Chỉ hủy lần `QUEUED` hoặc `RUNNING`; PO được hủy lần treo của mọi tenant. Kết quả lần trước được giữ.",
    "054": "Truy từng giá trị về quan sát, số liệu tay và phiên bản công thức đã dùng.",
    "055": "Chỉ cho kỳ chưa chốt (ERR-16-022); gom yêu cầu trong cửa sổ `16.late-data.debounce-minutes`.",
    "057": "Còn chỉ tiêu `PARTIAL` thì cần `confirmPartial = true`, chỉ tiêu bắt buộc thiếu số thì ERR-16-025. Chỉ TA chốt.",
    "058": "Chỉ TA; kỳ còn báo cáo đang duyệt trả ERR-16-026. Lý do từ 50 ký tự (ERR-16-007).",
    "063": "Trả liên kết PDF tạm hết hạn sau 1 giờ; không tạo báo cáo.",
    "065": "`PERIODIC` và `NATIONAL` cần kỳ đã tính và chốt khi báo cáo chính thức (ERR-16-028); `AD_HOC` dùng `from`, `to` tối đa 24 tháng (ERR-16-033) và `indicatorCodes` 1…50. Trả danh sách `requiredExplanations`.",
    "068": "Giải trình cho chỉ tiêu `AT_RISK`, `OFF_TRACK` hoặc thiếu số; báo cáo đã công bố trả ERR-16-032.",
    "069": "Nạp lại số liệu của lần tổng hợp mới nhất vào bản nháp; có thể tạo lần tổng hợp mới (`202`).",
    "071": "Thiếu số chỉ tiêu bắt buộc trả ERR-16-029; còn chỉ tiêu chệch chưa giải trình trả ERR-16-030. Phát EVT-16-07.",
    "072": "Người duyệt khác người lập, gửi (bốn mắt, ERR-16-005; `16.report.four-eyes` chỉ ảnh hưởng báo cáo `AD_HOC`).",
    "073": "Báo cáo về `CHANGES_REQUESTED`, người lập sửa rồi gửi lại. Phát EVT-16-09.",
    "074": "Chụp bất biến, dựng PDF, ký số, lưu WORM rồi mới chuyển `PUBLISHED`. Ký số lỗi trả ERR-16-031 (báo cáo vẫn `APPROVED`). Phát EVT-16-08.",
    "075": "Tạo phiên bản mới `DRAFT` mang `correctionNote`; bản cũ chuyển `SUPERSEDED` khi bản mới được công bố.",
    "076": "Báo cáo chuyển `WITHDRAWN`, vẫn tra được; phát EVT-16-09.",
    "078": "Việc của người dùng: định nghĩa chờ duyệt, số liệu tay chờ xác nhận, báo cáo chờ duyệt, loại trừ việc do chính người dùng gửi.",
    "079": "Bất đồng bộ; vượt `16.export.max-rows` trả ERR-16-034. Người yêu cầu nhận EVT-16-13. AU chỉ xuất báo cáo đã công bố và nhật ký.",
    "081": "Liên kết hết hạn sau `16.export.link-hours` trả `410` ERR-16-035.",
    "086": "Chỉ scope `kpi.read`. `onlyOfficial` mặc định `true` (kỳ đã chốt); `false` kèm `provisional`. `Cache-Control: max-age=300`.",
    "087": "Chỉ scope `kpi.read`, chỉ báo cáo `PUBLISHED`.",
    "088": "Trả kết quả kiểm lại mã băm và chữ ký; không khớp ghi ERR-16-124 và báo SO.",
    "089": "Người dùng cần `PERM-16-read`, hệ khác cần scope `kpi.read`; số liệu theo kỳ đã chốt gần nhất, có số tạm thì `provisional`.",
    "090": "`view = OFFICIAL` chỉ kỳ đã chốt, `LATEST` gồm số tạm; có `compareTo` thì thêm `comparison`.",
    "092": "Chỉ chỉ tiêu mẫu `COMMON`; dưới `16.compare.min-tenants` trả ERR-16-038. Tên tỉnh được thay bằng bí danh.",
    "101": "Scope `arch.register`. `202` kèm kết quả từng thành phần; thiếu trường hoặc sai loại trả ERR-16-039 ở `results[].code`.",
    "104": "Phiên bản đang `ACTIVE` chuyển `SUPERSEDED`; đánh giá đã xác nhận giữ phiên bản tiêu chí cũ.",
    "108": "Người xác nhận khác người lập (ERR-16-005). Mức tuân thủ của thành phần đổi; phát EVT-16-11.",
    "110": "Hạn tối đa `16.compliance.waiver-max-days` (ERR-16-044); hết hạn thì thành phần trở lại mức trước, phát EVT-16-11.",
    "111": "Bất đồng bộ; đang có lần đối chiếu chạy trả ERR-16-056.",
    "117": "Mẫu phải đạt lược đồ và kiểm thử (ERR-16-047); phiên bản `ACTIVE` cũ chuyển `SUPERSEDED`.",
    "118": "Gói chưa đạt lược đồ mẫu trả ERR-16-048; nội dung trùng lần nộp trước trả ERR-16-049; chỉ gói của báo cáo `PUBLISHED` (ERR-16-052). Trả bản xem trước.",
    "121": "Gửi qua PH-14; phát EVT-16-12. Lỗi kênh được thử lại tối đa `16.national.retry-max` lần.",
    "122": "Chỉ gói `FAILED` hoặc `REJECTED` còn lượt gửi lại (ERR-16-050).",
    "124": "Chỉ qua `/internal` trong mạng nội bộ, scope `kpi.national-receipt` của PH-14. Mã băm không khớp ghi ERR-16-124.",
    "125": "Bất đồng bộ; đang có lần đối soát chạy trả ERR-16-056.",
    "128": "Giá trị ngoài miền hoặc vượt trần của PA trả ERR-16-051.",
    "129": "Đọc từ kho kiểm toán PH-13; khoảng thời gian tối đa 12 tháng mỗi lần (ERR-16-057).",
}


def ex_of(name, d=0):
    s = SC[name]
    if "properties" not in s:
        if "$ref" in s:
            return ex_of(s["$ref"].split("/")[-1], d + 1)
        return s.get("x-ex")
    out = {}
    for k, v in s["properties"].items():
        e = s["x-ex"].get(k)
        if e is None and "$ref" in v:
            r = v["$ref"].split("/")[-1]
            e = ex_of(r, d + 1) if "enum" not in SC[r] else SC[r]["enum"][0]
        elif e is None and v.get("type") == "array" and "$ref" in v["items"]:
            r = v["items"]["$ref"].split("/")[-1]
            e = [ex_of(r, d + 1)] if "enum" not in SC[r] else [SC[r]["enum"][0]]
        elif e is None and v.get("type") == "array":
            e = []
        out[k] = e
    return out


def clean(s):
    s = copy.deepcopy(s)
    s.pop("x-ex", None)
    return s


def ref(n):
    return {"$ref": "#/components/schemas/" + n}


ETAGGED = {"Indicator", "IndicatorVersion", "DataSource", "ManualValue", "ReportingPeriod", "ReportTemplate", "Report", "Distribution", "ArchComponent", "CriteriaSet", "Assessment",
           "NationalTemplate", "Submission", "Settings", "GroupSet"}


def build():
    params = {
        "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": {"type": "string", "format": "uuid"}, "example": "0193b1d4-0000-7000-8000-0000000000a1",
                           "description": "UUID do bên gọi sinh; cùng khóa cùng thân trả lại phản hồi cũ, dùng lại với thân khác trả ERR-16-004 (409). Lưu 24 giờ."},
        "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": {"type": "string"}, "example": "W/\"3\"",
                    "description": "`ETag` của tài nguyên (`W/\"{n}\"`); không khớp trả ERR-16-004. Thiếu tiêu đề trả 428 (ERR-00-428)."},
        "Traceparent": {"name": "traceparent", "in": "header", "required": False, "schema": {"type": "string"}, "description": "W3C Trace Context."},
        "AcceptLanguage": {"name": "Accept-Language", "in": "header", "required": False, "schema": {"type": "string", "default": "vi", "enum": ["vi", "en"]}},
    }
    for n, (t, ex) in spec.PATHP.items():
        sch, dex = spec.tschema(t)
        params[n[0].upper() + n[1:]] = {"name": n, "in": "path", "required": True, "schema": sch, "example": ex if ex is not None else dex}
    responses = {}
    for st, (n, title, code) in STATUS.items():
        responses[n] = {"description": title + ".", "content": {"application/problem+json": {"schema": ref("Problem"), "examples": {"vi-du": {"value": {
            "type": "https://datahub.example.vn/errors/" + code, "title": title, "status": st, "detail": title + ".", "code": code,
            "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}}}
    responses["PreconditionRequired"] = {"description": "Thiếu `If-Match`.", "content": {"application/problem+json": {"schema": ref("Problem"), "examples": {"vi-du": {"value": {
        "type": "https://datahub.example.vn/errors/ERR-00-428", "title": "Thiếu If-Match", "status": 428, "code": "ERR-00-428", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}}}
    paths = {}
    for code, meth, path, frs_ in spec.ROWS:
        o = spec.OPS[code]
        fl = o["flags"]
        m = meth.lower()
        act = re.search(r"\}?:[a-z-]+$", path) is not None
        ifm = (m in ("put", "patch", "delete") or (m == "post" and act)) and "noifm" not in fl
        idem = "idem" in fl
        scope = next((f[2:] for f in fl if f.startswith("m:")), None)
        only = next((f[5:] for f in fl if f.startswith("only:")), None)
        also = [int(f[5:]) for f in fl if f.startswith("also:")]
        binct = next((f[4:] for f in fl if f.startswith("bin:")), None)
        mp = "mp" in fl
        pnames = re.findall(r"\{(\w+)\}", path)
        P = [ref_p("IdempotencyKey")] if idem else []
        if ifm:
            P.append(ref_p("IfMatch"))
        P += [ref_p(n[0].upper() + n[1:]) for n in pnames]
        filt = False
        for q in o["query"]:
            if q == "page":
                P.append({"name": "page", "in": "query", "schema": {"type": "integer", "minimum": 0, "default": 0}})
            elif q == "size":
                P.append({"name": "size", "in": "query", "schema": {"type": "integer", "minimum": 1, "maximum": 200, "default": 20}})
            else:
                n, t = q.split(":", 1)
                req_q = n.endswith("!")
                n = n.rstrip("!")
                sch, dex = spec.tschema(t)
                pr = {"name": n, "in": "query", "schema": sch}
                if req_q:
                    pr["required"] = True
                    pr["example"] = dex[0] if isinstance(dex, list) else dex
                if n == "limit":
                    pr["schema"] = {"type": "integer", "minimum": 1, "maximum": 8, "default": 4}
                if n == "version":
                    pr["description"] = "Số phiên bản."
                P.append(pr)
                filt = True
        P += [ref_p("Traceparent"), ref_p("AcceptLanguage")]
        errs, pairs = [], []

        def add(e, st=None):
            if e not in spec.ERR:
                raise SystemExit("ERR lạ " + e)
            tb = spec.ERR[e][0]
            if not tb:
                return
            s_ = st if st in tb else tb[0]
            errs.append(e)
            pairs.append((e, s_))
        if code in OWN:
            for x in OWN[code].split():
                add("ERR-16-" + x)
        else:
            for f in frs_:
                for e, st in spec.FRERR.get(f, []):
                    if m == "get" and e not in GET_ERRS:
                        continue  # GET chỉ giữ mã liên quan đọc; lỗi ghi của FR không áp cho lệnh đọc
                    if m == "get" and not pnames and e == "ERR-16-001" and code not in KEEP001:
                        continue
                    add(e, st)
        for e, st in ADD.get(code, ()):
            add(e, st)
        if o["req"]:
            add("ERR-16-003")
        if filt:
            add("ERR-16-057")
        if ifm or idem:
            add("ERR-16-004")
        if pnames:
            add("ERR-16-001")
        if act and "noifm" not in fl:
            add("ERR-16-006")
        errs = [e for e in dict.fromkeys(errs) if e not in DROP.get(code, ())]
        stat = {s_ for e, s_ in pairs if e in errs} | {401, 403}
        if ifm:
            stat.add(428)
        rs = {}
        ok = o["status"]
        okc = {}
        if o["res"]:
            exr = ex_of(o["res"])
            if code in EX_STATUS and isinstance(exr, dict):
                for k in ("state", "status"):
                    if k in exr and isinstance(exr[k], str):
                        exr[k] = EX_STATUS[code]
                        break
            okc = {"application/json": {"schema": ref(o["res"]), "example": exr}}
        elif binct:
            okc = {binct: {"schema": {"type": "string", "format": "binary"}, "example": "(nội dung tệp)"}}
        rs[str(ok)] = {"description": "Thành công." if ok != 204 else "Đã ghi, không có nội dung."}
        if okc:
            rs[str(ok)]["content"] = okc
        for a in also:
            rs[str(a)] = {"description": "Một phần thành công: có phần tử lỗi, xem `results[]`.", "content": copy.deepcopy(okc)}
            if code == "030":
                rs[str(a)]["content"]["application/json"]["example"] = {"accepted": 1, "duplicate": 0, "rejected": 1,
                                                                        "results": [{"index": 0, "status": "ACCEPTED"}, {"index": 1, "status": "REJECTED", "code": "ERR-16-102"}]}
        if o["res"] in ETAGGED:
            hdr = {"ETag": {"schema": {"type": "string"}, "example": "W/\"3\"", "description": "`W/\"{n}\"`."}}
            if ok == 201:
                hdr["Location"] = {"schema": {"type": "string"}, "example": "/api/kpi/v1/" + path.strip("/").split("/")[0] + "/ma-moi", "description": "Đường dẫn tài nguyên mới."}
            rs[str(ok)]["headers"] = hdr
        for st in sorted(stat):
            rs[str(st)] = {"$ref": "#/components/responses/" + ("PreconditionRequired" if st == 428 else STATUS[st][0])}
        op = {"tags": [o["tag"]], "operationId": opid(code, meth, path), "summary": o["summary"], "x-datahub-id": "API-16-" + code, "x-datahub-fr": frs_}
        perm = o["perm"]
        if only:
            pm = f"scope `{only}`"
        else:
            pm = " hoặc ".join("PERM-16-" + p for p in perm.split("/")) + (f" hoặc scope `{scope}`" if scope else "")
        op["x-datahub-permission"] = {"permission": pm}
        if scope or only:
            op["x-datahub-scope"] = scope or only
        sec = []
        if not only:
            sec.append({"oauth2User": []})
        if scope or only:
            sec.append({"oauth2Machine": [scope or only]})
        op["security"] = sec
        if idem:
            op["x-datahub-idempotent"] = "required"
        if ifm:
            op["x-datahub-if-match"] = "required"
        if path.startswith("/internal"):
            op["x-datahub-internal"] = True
        op["description"] = NOTE.get(code, "Theo FRS 9.4.")
        op["parameters"] = P
        op["x-datahub-errors"] = errs
        if o["req"]:
            op["requestBody"] = {"required": True, "content": {("multipart/form-data" if mp else "application/json"): {"schema": ref(o["req"]), "example": ex_of(o["req"])}}}
        elif m in ("put", "patch") or (m == "post" and False):
            pass
        op["responses"] = rs
        paths.setdefault(path, {})[m] = op
    schemas = {k: clean(v) for k, v in SC.items()}
    d = {"openapi": "3.1.0", "info": {
        "title": "Datahub · PH-16 Báo cáo chỉ tiêu và sổ kiến trúc API", "version": "1.0.0-draft",
        "summary": "Bộ chỉ tiêu, nguồn số liệu, số liệu nhập tay, kỳ và lần tổng hợp, mẫu và báo cáo, xuất và phân phối, bảng điều khiển, sổ kiến trúc, tuân thủ, gửi quốc gia, quản trị.",
        "description": "Module `kpi` và `arch` của `dh-platform` (control plane), gốc `/api/kpi/v1` (người dùng qua BFF; PH-17, cổng tỉnh, HTTT, phân hệ nguồn, PH-14 bằng tài khoản máy; `/internal` chỉ trong mạng nội bộ).\n\n"
                       "Quy ước (D03-04-PH16 mục 1): tenant lấy từ phiên hoặc thông tin xác thực máy; tạo nhận `Idempotency-Key`; sửa và hành động có `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-16-nnn`; phân trang `page`, `size`. "
                       "Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.",
        "contact": {"name": "Nhóm phân hệ PH-16"}, "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
        "x-datahub-document": "D03-04-PH16", "x-datahub-phase": "PH-16"},
        "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn/api/kpi/v1", "description": "Qua BFF console của tenant (giả lập)", "variables": {"tenantHost": {"default": "t68", "description": "Ví dụ `t68` (giả lập)."}}},
                    {"url": "https://api.{tenantHost}.datahub.example.vn/api/kpi/v1", "description": "Cổng API cho PH-17, cổng tỉnh, HTTT, phân hệ nguồn (tài khoản máy)", "variables": {"tenantHost": {"default": "t68"}}},
                    {"url": "http://dh-platform.dh-platform.svc:8080/api/kpi/v1", "description": "Trong cụm; chỉ nơi này có `/internal`"}],
        "security": [{"oauth2User": []}],
        "tags": [{"name": t, "description": "Nhóm " + t + "; bảng mã ở D03-04-PH16 mục 3."} for t in spec.TAGS],
        "paths": paths,
        "components": {"securitySchemes": {
            "oauth2User": {"type": "oauth2", "description": "Người dùng qua Keycloak; quyền `PERM-16-*`.", "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/auth", "tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {"openid": "Định danh người dùng"}}}},
            "oauth2Machine": {"type": "oauth2", "description": "Máy với máy (PH-17, cổng tỉnh, HTTT, phân hệ nguồn, CI/GitOps, PH-14).", "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {
                "kpi.read": "Đọc chỉ tiêu, báo cáo đã công bố (PH-17, cổng tỉnh, HTTT được cấp)", "kpi.ingest": "Đẩy quan sát (phân hệ nguồn)", "arch.register": "Tự đăng ký thành phần kiến trúc (PH-01, PH-02, PH-04, PH-10, CI/GitOps)",
                "kpi.national-receipt": "Nhận biên nhận gói quốc gia (PH-14; đề nghị bổ sung)"}}}}},
            "parameters": params, "responses": responses, "schemas": schemas}}
    return d


def ref_p(n):
    return {"$ref": "#/components/parameters/" + n}


def opid(code, meth, path):
    segs = [s for s in re.split(r"/", path) if s and not s.startswith("{")]
    base = "".join(re.sub(r"[^A-Za-z0-9]", " ", x).title().replace(" ", "") for x in segs)
    return meth.lower() + base + code


if __name__ == "__main__":
    d = build()
    txt = "# D03-04-PH16 · OpenAPI PH-16 (module kpi, arch của dh-platform). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("operation:", sum(1 for p in d["paths"].values() for _ in p), "đường dẫn:", len(d["paths"]), "lược đồ:", len(d["components"]["schemas"]), "->", OUT)
