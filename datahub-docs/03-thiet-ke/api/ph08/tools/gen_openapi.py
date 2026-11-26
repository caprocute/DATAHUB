#!/usr/bin/env python3
"""Sinh openapi-dq.yaml (OpenAPI 3.1) của PH-08 từ spec.py. Chạy từ thư mục api/ph06:  python3 tools/gen_openapi.py
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

OUT = os.path.join(spec.ROOT, "openapi-dq.yaml")
SC = spec.SCH
STATUS = {400: ("BadRequest", "Dữ liệu không hợp lệ", "ERR-08-003"), 401: ("Unauthorized", "Chưa xác thực", "ERR-00-401"),
          403: ("Forbidden", "Không đủ quyền", "ERR-00-403"), 404: ("NotFound", "Không tìm thấy", "ERR-08-001"),
          409: ("Conflict", "Xung đột", "ERR-08-006"), 410: ("Gone", "Đã không còn", "ERR-08-041"),
          413: ("PayloadTooLarge", "Vượt giới hạn", "ERR-08-046"), 422: ("Unprocessable", "Không xử lý được", "ERR-08-045"),
          429: ("TooManyRequests", "Vượt hạn mức", "ERR-08-052"), 503: ("ServiceUnavailable", "Dịch vụ phụ thuộc không khả dụng", "ERR-08-054"),
          504: ("GatewayTimeout", "Vượt ngân sách thời gian", "ERR-08-103")}
GET_ERRS = {"ERR-08-001", "ERR-08-027", "ERR-08-032", "ERR-08-041", "ERR-08-044", "ERR-08-045"}
# mã lỗi của FR gộp không áp cho operation này (FR có nhiều bước, operation chỉ thực hiện một bước)
DROP = {"059": ("ERR-08-038", "ERR-08-039"), "087": ("ERR-08-046",), "088": ("ERR-08-046",), "090": ("ERR-08-046",), "091": ("ERR-08-046",), "092": ("ERR-08-046",), "093": ("ERR-08-046",),
        "094": ("ERR-08-046",), "096": ("ERR-08-046",), "084": ("ERR-08-046",)}
# trạng thái trả về của ví dụ phản hồi theo operation (mặc định ví dụ lấy giá trị enum đầu tiên)
EX_STATUS = {"009": "ACTIVE", "010": "SUSPENDED", "011": "ACTIVE", "012": "RETIRED", "019": "QUEUED", "038": "PENDING_APPROVAL", "039": "APPROVED", "040": "DRAFT", "041": "ACTIVE", "050": "PENDING_APPROVAL",
             "051": "ACTIVE", "052": "DRAFT", "057": "PAUSED", "058": "ACTIVE", "059": "QUEUED", "062": "CANCELLED", "063": "QUEUED", "075": "PENDING_APPROVAL", "076": "APPROVED", "081": "ACTIVE",
             "082": "REJECTED", "083": "REVOKED", "084": "ASSIGNED", "087": "ASSIGNED", "088": "IN_PROGRESS", "090": "FIXED", "091": "FIXED", "092": "REJECTED", "093": "ASSIGNED", "096": "CANCELLED",
             "102": "ACKNOWLEDGED", "103": "SILENCED", "111": "IN_REVIEW", "112": "PUBLISHED", "113": "DRAFT", "114": "WITHDRAWN", "116": "RUNNING"}
NOTE = {
    "006": "Loại `MDM_DOMAIN` cần `mdmDomainCode` có khung nhìn hợp đồng (ERR-08-009); `RDM_CATALOG` cần `rdmCatalogCode` đã phát hành (ERR-08-010); `SOURCE_DATASET` cần `connectionId` chỉ đọc và `objectName` (ERR-08-011, 012); `FLOW_MESSAGE` cần `flowCode`.",
    "009": "Cần miền có tổ chức chủ quản và cán bộ phụ trách (ERR-08-008); sinh lịch mặc định theo `08.scan.default-cron`.",
    "014": "Phân loại lấy từ PH-09; trường chưa có phân loại xác nhận bị che như Nhạy cảm (cảnh báo ERR-08-047, không chặn). Chưa có trường thì gửi `If-Match: *` để tạo.",
    "015": "Gọi API tra phân loại của PH-09, cập nhật `dataClass` và `classificationStatus`; không đổi `valueMode` lỏng hơn.",
    "018": "Dùng kết nối PH-05 chỉ đọc; không bao giờ đọc CSDL control của Datahub (ERR-08-012).",
    "019": "Đối tượng `FLOW_MESSAGE` không chạy hồ sơ (ERR-08-050); đang có lần hồ sơ chạy trả ERR-08-028.",
    "024": "Chỉ qua `/internal` trong mạng nội bộ, token máy của PH-05 (scope `dq.ingest`); không có ở BFF. Lô sai định dạng ERR-08-118.",
    "037": "Đồng bộ, tối đa `08.dryrun.max-rows` bản ghi (ERR-08-031); không ghi bản ghi lỗi; ví dụ lỗi đã che.",
    "038": "Phải có kết quả chạy thử của đúng nội dung hiện tại (ERR-08-053) và ít nhất một quy tắc bật (ERR-08-021).",
    "039": "Người duyệt khác người gửi (ERR-08-005, bốn mắt).",
    "041": "Phiên bản phải `APPROVED`; thay phiên bản `ACTIVE` cũ (chuyển `SUPERSEDED`), phát EVT-08-01.",
    "059": "Hạn mức `08.scan.manual-per-hour` (ERR-08-052); đang có lần đo chạy trả ERR-08-028; báo cáo năm bắt buộc `FULL` (ERR-08-030).",
    "063": "Tạo lần đo mới có `rerunOf` trỏ lần cũ; lần cũ phải ở trạng thái cuối.",
    "065": "Điểm có cờ `INCOMPLETE_DIMENSIONS` khi một chiều `SKIPPED` (ERR-08-108).",
    "068": "Scope `dq.check`; ngân sách `08.inline.timeout-ms` (mặc định 40 ms, p95 ≤ 50 ms). Không có tiêu đề `If-Match`. `FAIL_OPEN` trả `200` kèm `degraded = true`; `FAIL_CLOSED` trả `503` hoặc `504`. Phản hồi không chứa giá trị bản ghi.",
    "069": "Tối đa 100 bản ghi mỗi lần; kết luận từng bản ghi, cùng chính sách phụ thuộc lỗi như API-08-068.",
    "071": "Bật hoặc tắt kiểm tra trực tuyến, chế độ `STRICT` hoặc `ADVISORY`, chính sách khi phụ thuộc lỗi; chưa có cấu hình thì gửi `If-Match: *`.",
    "073": "Giá trị trường Nhạy cảm chỉ là băm; DO chỉ thấy lỗi của tổ chức mình (ERR-08-032). Tìm theo khóa cá nhân dùng API-08-129.",
    "075": "Có trường Nhạy cảm thì `status = PENDING_APPROVAL` đến khi DO chấp thuận (API-08-076).",
    "076": "Tệp chưa chấp thuận trả `409`, hết hạn tải `410` (ERR-08-041).",
    "095": "Chỉ lỗi của bản ghi vàng (ERR-08-051); PH-06 nhận qua API nội bộ, tạo mục hàng đợi lý do `DQ_FINDING`.",
    "091": "Chế độ `SCAN` tạo lần đo trigger `VERIFY`; DO không tự xác nhận (ERR-08-035).",
    "112": "Công bố phát EVT-08-11; người duyệt khác người gửi (ERR-08-005).",
    "115": "Chỉ đọc, không tạo báo cáo; trả danh sách đối tượng chưa đủ điều kiện (ERR-08-038).",
    "116": "`202` khi tạo tệp bất đồng bộ; theo dõi ở API-08-117; ký số tách ở API-08-118 (ERR-08-048).",
    "122": "Chỉ đọc lại bản tin KPI đã phát (EVT-08-14); PH-16 dùng scope `dq.read`.",
    "124": "Giá trị ngoài miền hoặc vượt trần của PA trả ERR-08-042, lưu giữ dưới sàn ERR-08-043.",
    "128": "Chỉ PLATFORM (PA) và TA của tenant bật `08.benchmark.opt-in`; nhóm nhỏ hơn ngưỡng ẩn danh trả ERR-08-044.",
    "129": "Mã API cấp thêm vì FRS dùng chung API-08-073 cho GET và POST; khóa bản ghi gửi trong thân để không lọt vào log của cổng.",
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


def build():
    params = {
        "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": {"type": "string", "format": "uuid"}, "example": "0193b1d4-0000-7000-8000-0000000000a1",
                           "description": "UUID do bên gọi sinh; dùng lại với thân khác trả ERR-08-004 (xung đột). Lưu 24 giờ."},
        "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": {"type": "string"}, "example": "W/\"3\"",
                    "description": "`ETag` của tài nguyên (`W/\"{version}\"`); không khớp trả ERR-08-004. Thiếu tiêu đề trả 428 (ERR-00-428)."},
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
        act = re.search(r"\}:[a-z-]+$", path) is not None
        ifm = (m in ("put", "patch", "delete") or (m == "post" and act)) and "noifm" not in fl
        idem = "idem" in fl
        scope = next((f[2:] for f in fl if f.startswith("m:")), None)
        only = next((f[5:] for f in fl if f.startswith("only:")), None)
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
                P.append({"name": "size", "in": "query", "schema": {"type": "integer", "minimum": 1, "maximum": 100, "default": 20}})
            else:
                n, t = q.split(":", 1)
                sch, dex = spec.tschema(t)
                pr = {"name": n, "in": "query", "schema": sch}
                if n == "with":
                    pr["required"] = True
                    pr["example"] = 3
                    pr["description"] = "Số phiên bản đối chiếu."
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
        for f in frs_:
            for e, st in spec.FRERR.get(f, []):
                if m == "get" and e not in GET_ERRS:
                    continue  # GET chỉ giữ mã liên quan đọc; lỗi ghi của FR không áp cho lệnh đọc
                add(e, st)
        if o["req"]:
            add("ERR-08-003")
        if filt:
            add("ERR-08-045")
        if ifm:
            add("ERR-08-004")
        if idem:
            add("ERR-08-004")
        if pnames:
            add("ERR-08-001")
        if act and "noifm" not in fl:
            add("ERR-08-006")
        if code in ("076", "077"):
            add("ERR-08-041", 410)
            add("ERR-08-041", 409)
        errs = [e for e in dict.fromkeys(errs) if e not in DROP.get(code, ())]
        stat = {s_ for e, s_ in pairs if e in errs} | {401, 403}
        if ifm:
            stat.add(428)
        rs = {}
        ok = o["status"]
        okc = {}
        if o["res"]:
            exr = ex_of(o["res"])
            if code in EX_STATUS and isinstance(exr, dict) and "status" in exr:
                exr["status"] = EX_STATUS[code]
            okc = {"application/json": {"schema": ref(o["res"]), "example": exr}}
        rs[str(ok)] = {"description": "Thành công." if ok != 204 else "Đã xóa, không có nội dung."}
        if okc:
            rs[str(ok)]["content"] = okc
        if o["res"] and not o["res"].endswith("Page") and o["res"] not in ("Dashboard", "InlineStats", "CheckResult", "CheckBatchResult"):
            hdr = {"ETag": {"schema": {"type": "string"}, "example": "W/\"3\"", "description": "`W/\"{version}\"`."}}
            if ok == 201:
                hdr["Location"] = {"schema": {"type": "string"}, "example": "/api/dq/v1/" + path.strip("/").split("/")[0] + "/ma-moi", "description": "Đường dẫn tài nguyên mới."}
            rs[str(ok)]["headers"] = hdr
        for st in sorted(stat):
            rs[str(st)] = {"$ref": "#/components/responses/" + ("PreconditionRequired" if st == 428 else STATUS[st][0])}
        op = {"tags": [o["tag"]], "operationId": opid(code, meth, path), "summary": o["summary"], "x-datahub-id": "API-08-" + code, "x-datahub-fr": frs_}
        perm = o["perm"]
        if only:
            pm = f"scope `{only}`"
        elif perm == "-":
            pm = "Token máy"
        else:
            pm = " hoặc ".join("PERM-08-" + p for p in perm.split("/")) + (f" hoặc scope `{scope}`" if scope else "")
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
            op["requestBody"] = {"required": True, "content": {"application/json": {"schema": ref(o["req"]), "example": ex_of(o["req"])}}}
        op["responses"] = rs
        paths.setdefault(path, {})[m] = op
    schemas = {k: clean(v) for k, v in SC.items()}
    d = {"openapi": "3.1.0", "info": {
        "title": "Datahub · PH-08 Chất lượng dữ liệu API", "version": "1.0.0-draft",
        "summary": "Miền và đối tượng đo, hồ sơ dữ liệu, bộ quy tắc, lịch và lần đo, kiểm tra trực tuyến, bản ghi lỗi, ngoại lệ, phiếu khắc phục, cảnh báo, báo cáo, quản trị.",
        "description": "Module `dq` của `dh-data`, gốc `/api/dq/v1` (người dùng qua BFF; PH-04, PH-06, PH-16, HTTT bằng token máy; `/internal` chỉ trong mạng nội bộ).\n\n"
                       "Quy ước (D03-04-PH08 mục 1): tenant lấy từ token; tạo nhận `Idempotency-Key`; sửa và hành động có `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-08-nnn`; phân trang `page`, `size`. "
                       "Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.",
        "contact": {"name": "Nhóm phân hệ PH-08"}, "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
        "x-datahub-document": "D03-04-PH08", "x-datahub-phase": "PH-08"},
        "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn/api/dq/v1", "description": "Qua BFF console của tenant (giả lập)", "variables": {"tenantHost": {"default": "t68", "description": "Ví dụ `t68` (giả lập)."}}},
                    {"url": "https://api.{tenantHost}.datahub.example.vn/api/dq/v1", "description": "Cổng API cho PH-04, PH-06, PH-16, HTTT (token máy)", "variables": {"tenantHost": {"default": "t68"}}},
                    {"url": "http://dh-data.dh-data.svc:8080/api/dq/v1", "description": "Trong cụm; chỉ nơi này có `/internal`"}],
        "security": [{"oauth2User": []}],
        "tags": [{"name": t, "description": "Nhóm " + t + "; bảng mã ở D03-04-PH08 mục 3."} for t in spec.TAGS],
        "paths": paths,
        "components": {"securitySchemes": {
            "oauth2User": {"type": "oauth2", "description": "Người dùng qua Keycloak; quyền `PERM-08-*`.", "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/auth", "tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {"openid": "Định danh người dùng"}}}},
            "oauth2Machine": {"type": "oauth2", "description": "Máy với máy (PH-04, PH-06, PH-05, PH-16, HTTT).", "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {
                "dq.check": "Kiểm tra chất lượng trực tuyến (PH-04, PH-06)", "dq.read": "Đọc điểm, thẻ điểm, KPI (PH-16, HTTT)", "dq.ingest": "Nhận chỉ số hồ sơ từ PH-05 (đề nghị bổ sung)"}}}}},
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
    txt = "# D03-04-PH08 · OpenAPI PH-08 (module dq của dh-data). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("operation:", sum(1 for p in d["paths"].values() for _ in p), "đường dẫn:", len(d["paths"]), "lược đồ:", len(d["components"]["schemas"]), "->", OUT)
