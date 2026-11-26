#!/usr/bin/env python3
"""Sinh openapi-mdm.yaml (OpenAPI 3.1) của PH-06 từ spec.py. Chạy từ thư mục api/ph06:  python3 tools/gen_openapi.py
Không sửa tay tệp YAML. Mọi operation có x-datahub-id, x-datahub-fr, x-datahub-permission, x-datahub-errors."""
import copy, os, re, sys
import yaml


class NoAlias(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

OUT = os.path.join(spec.ROOT, "openapi-mdm.yaml")
SC = spec.SCH
FR_TITLE = dict(re.findall(r"#### (FR-06-\d{3}) · ([^\n]+)", spec.FRS))
STATUS = {400: ("BadRequest", "Dữ liệu không hợp lệ", "ERR-06-003"), 401: ("Unauthorized", "Chưa xác thực", "ERR-00-401"),
          403: ("Forbidden", "Không đủ quyền", "ERR-06-005"), 404: ("NotFound", "Không tìm thấy", "ERR-06-001"),
          409: ("Conflict", "Xung đột", "ERR-06-004"), 410: ("Gone", "Đã không còn", "ERR-06-042"),
          413: ("PayloadTooLarge", "Vượt giới hạn", "ERR-06-018"), 422: ("Unprocessable", "Không xử lý được", "ERR-06-007"),
          429: ("TooManyRequests", "Vượt hạn mức gọi", "ERR-06-048"), 503: ("ServiceUnavailable", "Dịch vụ phụ thuộc không khả dụng", "ERR-06-021")}
NOTE = {
    "021": "Mỗi bản ghi xử lý riêng; có bản ghi lỗi trả `207` kèm `results[]`, bản ghi tốt vẫn được nhận. `Idempotency-Key` dùng lại với nội dung khác: ERR-06-015.",
    "022": "Chỉ qua `/internal` trong mạng nội bộ, token máy gắn nguồn; không có ở BFF.",
    "046": "Xem giá trị `SENSITIVE` đầy đủ cần `PERM-09-unmask` và tiêu đề `X-Unmask-Reason`; không có thì giá trị che.",
    "056": "Xem giá trị `SENSITIVE` đầy đủ cần `PERM-09-unmask` và tiêu đề `X-Unmask-Reason`; `410` khi bản ghi `RETIRED`. Mọi lượt đọc ghi nhật ký truy cập (BR-06-010), không ghi được thì từ chối (ERR-06-039).",
    "058": "`200` khi thực hiện ngay, `202` khi rủi ro cao chờ duyệt bốn mắt (`status = PENDING_APPROVAL`).",
    "059": "`200` hoặc `202` khi bản ghi có từ 3 liên kết chờ duyệt.",
    "060": "Trong 90 ngày không cần duyệt; quá hạn chờ duyệt (ERR-06-034).",
    "068": "`sourceKey` nằm trên đường dẫn vì không phải DLCN; khóa định danh cá nhân luôn gửi trong thân (API-06-070).",
    "070": "Khóa định danh gửi trong thân `POST` để không lọt vào log của cổng; `ETag` và `Cache-Control: private, max-age=0` trong phản hồi.",
    "071": "`200` khớp, `202` đã tạo mục hàng đợi (`LOOKUP_OR_QUEUE`), `404` ERR-06-050 khi `NO_MATCH`.",
    "076": "Liên kết ký có hạn; hết hạn trả `410` (ERR-06-042). Tệp có thủy vân.",
    "012": "Gói nền cài với phiên bản `ACTIVE` không qua duyệt bốn mắt (cột người gửi bỏ trống), có đề nghị bổ sung cho FRS.",
    "052": "Bản nháp cấu hình sống sót; cần duyệt bốn mắt trước khi `ACTIVE` (BR-06-019).",
    "121": "Trong `06.queue.reopen-hours` (24 giờ) và chưa có thao tác phụ thuộc; quá hạn ERR-06-053. Hoàn tác thay đổi bản ghi vàng của quyết định cũ rồi đưa mục về `ASSIGNED`.",
    "122": "Thao tác chờ duyệt và thao tác hoàn tác được của một bản ghi vàng; dùng cho tab Thao tác.",
    "123": "Khóa rồi không mở lại; thêm cặp sau đó tạo tập nhãn phiên bản mới. Ghi kiểm toán.",
    "124": "Một lệnh nguyên tử (`SKIP LOCKED`); hết mục phù hợp trả `204`, không lỗi. Mục gán `ASSIGNED` giữ `06.queue.hold-minutes`.",
    "125": "Bỏ cờ `restricted`, bản ghi `LOCKED` về `ACTIVE`; yêu cầu `RESTRICTION` giữ `COMPLETED`; phát EVT-06-02.",
    "106": "Thân có `decision` (`ApprovalDecision`): `REJECT` chuyển job `AWAITING_CONFIRMATION` sang `CANCELLED`, không áp cặp nào.",
    "118": "Bắt buộc `cause` (nguyên nhân đã điều tra, từ 20 ký tự), lưu ở `national_sync_state`, kiểm toán và đưa vào EVT-06-13.",
    "045": "Lọc `partition`: `mine`, `unclaimed`, `overdue`, `pending-approval`.",
    "096": "Mỗi khóa theo miền ở FRS 8.2; ngoài miền ERR-06-047.",
}
ACT_NOTE = {"suspend": "Tạm ngừng", "resume": "Tiếp tục", "retire": "Ngừng", "approve": "Duyệt", "reject": "Từ chối"}


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
        "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": {"type": "string", "format": "uuid"}, "description": "UUID do bên gọi sinh; dùng lại với nội dung khác trả ERR-06-015. Lưu 24 giờ."},
        "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": {"type": "string"}, "description": "`ETag` của tài nguyên (`W/\"{version}\"`); không khớp trả ERR-06-004. Thiếu tiêu đề trả 428."},
        "Traceparent": {"name": "traceparent", "in": "header", "required": False, "schema": {"type": "string"}, "description": "W3C Trace Context."},
        "AcceptLanguage": {"name": "Accept-Language", "in": "header", "required": False, "schema": {"type": "string", "default": "vi", "enum": ["vi", "en"]}},
        "XPurpose": {"name": "X-Purpose", "in": "header", "required": True, "schema": {"type": "string", "pattern": spec.CODE}, "description": "Mã mục đích khai thác đã được PH-09 chấp thuận; thiếu hoặc không được phép trả ERR-06-037."},
    }
    for n, (t, ex) in spec.PATHP.items():
        sch, _ = spec.tschema(t)
        params[n[0].upper() + n[1:]] = {"name": n, "in": "path", "required": True, "schema": sch}
    responses = {}
    for st, (n, title, code) in STATUS.items():
        responses[n] = {"description": title + ".", "content": {"application/problem+json": {"schema": ref("Problem"), "examples": {"vi-du": {"value": {
            "type": "https://datahub.example.vn/errors/" + code, "title": title, "status": st, "detail": title + ".", "code": code,
            "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}}}
    responses["PreconditionRequired"] = {"description": "Thiếu `If-Match`.", "content": {"application/problem+json": {"schema": ref("Problem"), "examples": {"vi-du": {"value": {
        "type": "https://datahub.example.vn/errors/ERR-00-428", "title": "Thiếu If-Match", "status": 428, "code": "ERR-00-428", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}}}
    paths = {}
    for code, meth, path, act, frs_, _g in spec.ROWS:
        o = spec.OPS[code]
        fl = o["flags"]
        m = meth.lower()
        ifm = m in ("put", "patch") or (m == "post" and re.search(r"\}:[a-z-]+$", path) is not None and "noifm" not in fl)
        idem = "idem" in fl
        scope = next((f[2:] for f in fl if f.startswith("m:")), None)
        only = next((f[5:] for f in fl if f.startswith("only:")), None)
        purpose = "purpose" in fl
        pnames = re.findall(r"\{(\w+)\}", path)
        P = [ref_p("IdempotencyKey")] if idem else []
        if ifm:
            P.append(ref_p("IfMatch"))
        if purpose:
            P.append(ref_p("XPurpose"))
        P += [ref_p(n[0].upper() + n[1:]) for n in pnames]
        for q in o["query"]:
            if q == "page":
                P.append({"name": "page", "in": "query", "schema": {"type": "integer", "minimum": 0, "default": 0}})
            elif q == "size":
                P.append({"name": "size", "in": "query", "schema": {"type": "integer", "minimum": 1, "maximum": 100, "default": 20}})
            elif q.startswith("unmaskReason"):
                P.append({"name": "X-Unmask-Reason", "in": "header", "schema": {"type": "string", "minLength": 20, "maxLength": 500},
                          "description": "Lý do xem giá trị `SENSITIVE` đầy đủ, bắt buộc khi có `unmask`; gửi ở tiêu đề để không vào log đường dẫn."})
            else:
                n, t = q.split(":", 1)
                sch, _ = spec.tschema(t)
                P.append({"name": n, "in": "query", "schema": sch, **({"description": "Danh sách thuộc tính cần xem đầy đủ, cách nhau dấu phẩy; cần `PERM-09-unmask` và `X-Unmask-Reason`."} if n == "unmask" else {})})
        P += [ref_p("Traceparent"), ref_p("AcceptLanguage")]
        # lỗi
        errs, stat = [], set()
        for f in frs_:
            for e, st in spec.FRERR.get(f, []):
                if int(e[-3:]) < 100:
                    errs.append(e); stat.add(st)
        if o["req"]:
            errs.append("ERR-06-003"); stat.add(400)
        if ifm:
            errs.append("ERR-06-004"); stat.add(409)
        if idem:
            errs.append("ERR-06-015"); stat.add(409)
        if pnames and "ERR-06-001" not in errs and m in ("get", "put", "patch", "post"):
            errs.append("ERR-06-001"); stat.add(404)
        if code == "006":
            errs.append("ERR-06-008"); stat.add(422)
        if code == "071":
            errs.append("ERR-06-050"); stat.add(404)
        errs = list(dict.fromkeys(errs))
        stat |= {401, 403}
        if ifm:
            stat.add(428)
        rs = {}
        ok = o["status"]
        sc = ok
        okc = {}
        if o["res"] == "binary":
            okc = {"application/octet-stream": {"schema": {"type": "string", "format": "binary"}}}
        else:
            okc = {"application/json": {"schema": ref(o["res"]), "examples": {"vi-du": {"value": ex_of(o["res"])}}}}
        hdr = {"ETag": {"schema": {"type": "string"}, "description": "`W/\"{version}\"`."}}
        if sc == 201:
            hdr["Location"] = {"schema": {"type": "string"}, "description": "Đường dẫn tài nguyên mới."}
        rs[str(ok)] = {"description": "Thành công.", "content": okc}
        if o["res"] != "binary" and o["res"].endswith("Page") is False and o["res"] not in ("DashboardMetrics",):
            rs[str(ok)]["headers"] = hdr
        for f in fl:
            if f.startswith("also:"):
                rs[f[5:]] = {"description": "Không có mục phù hợp, không phải lỗi."} if f == "also:204" else {"description": "Thành công một phần hoặc chờ xử lý.", "content": okc}
        for st in sorted(stat):
            if st == 428:
                rs["428"] = {"$ref": "#/components/responses/PreconditionRequired"}
            else:
                rs[str(st)] = {"$ref": "#/components/responses/" + STATUS[st][0]}
        op = {"tags": [o["tag"]], "operationId": opid(code, meth, path, act), "summary": o["summary"], "x-datahub-id": "API-06-" + code,
              "x-datahub-fr": frs_}
        perm = o["perm"]
        if only:
            pm = f"scope `{only}`"
        elif perm == "-":
            pm = "Token máy"
        else:
            pm = "PERM-06-" + perm + (f" hoặc scope `{scope}`" if scope else "")
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
        desc = ("Hành động `%s` tách từ dòng gộp API-06-%s của FRS 9.4. " % (act, next(r[5] for r in spec.ROWS if r[0] == code)) if act and code > "096" else "") + (NOTE[code] if code in NOTE else "")
        desc = desc.strip() or "Theo FRS 9.4."
        op["description"] = desc
        op["parameters"] = P
        op["x-datahub-errors"] = errs
        if o["req"]:
            ct = "multipart/form-data" if "multipart" in fl else "application/json"
            op["requestBody"] = {"required": True, "content": {ct: {"schema": ref(o["req"]), "examples": {"vi-du": {"value": ex_of(o["req"])}}}}}
        op["responses"] = rs
        paths.setdefault(path, {})[m] = op
    schemas = {k: clean(v) for k, v in SC.items()}
    d = {"openapi": "3.1.0", "info": {
        "title": "Datahub · PH-06 Dữ liệu chủ API", "version": "1.0.0-draft",
        "summary": "Domain, nguồn, nạp ứng viên, đối sánh, hàng đợi, sống sót, bản ghi vàng, liên kết chéo, tra cứu, cung cấp, đồng bộ quốc gia, vận hành.",
        "description": "Module `mdm` của `dh-data`, gốc `/api/mdm/v1` (người dùng qua BFF; HTTT, PH-04, PH-08, PH-14 bằng token máy; `/internal` chỉ trong mạng nội bộ).\n\n"
                       "Quy ước (D03-04-PH06 §1): tenant lấy từ token; tạo nhận `Idempotency-Key`; sửa và hành động có `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-06-nnn`; phân trang `page`, `size`. "
                       "Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.",
        "contact": {"name": "Nhóm phân hệ PH-06"}, "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
        "x-datahub-document": "D03-04-PH06", "x-datahub-phase": "PH-06"},
        "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn/api/mdm/v1", "description": "Qua BFF console của tenant (giả lập)", "variables": {"tenantHost": {"default": "t68", "description": "Ví dụ `t68` (giả lập)."}}},
                    {"url": "https://api.{tenantHost}.datahub.example.vn/api/mdm/v1", "description": "Cổng API cho HTTT, PH-04, PH-08, PH-14 (token máy)", "variables": {"tenantHost": {"default": "t68"}}},
                    {"url": "http://dh-data.dh-data.svc:8080/api/mdm/v1", "description": "Trong cụm; chỉ nơi này có `/internal`"}],
        "security": [{"oauth2User": []}],
        "tags": [{"name": t, "description": "Nhóm " + t + "; bảng mã ở D03-04-PH06 §3."} for t in spec.TAGS],
        "paths": paths,
        "components": {"securitySchemes": {
            "oauth2User": {"type": "oauth2", "description": "Người dùng qua Keycloak; quyền `PERM-06-*`.", "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/auth", "tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {"openid": "Định danh người dùng"}}}},
            "oauth2Machine": {"type": "oauth2", "description": "Máy với máy (HTTT, PH-04, PH-08, PH-14).", "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {
                "mdm:ingest": "Nạp ứng viên", "mdm:read": "Tra cứu bản ghi vàng đã che", "mdm:xref": "Tra liên kết chéo", "mdm:resolve": "Giải quyết trực tuyến", "mdm:search": "Tìm kiếm hạn chế", "mdm:national-sync": "Đồng bộ quốc gia (PH-14)"}}}}},
            "parameters": params, "responses": responses, "schemas": schemas}}
    return d


def ref_p(n):
    return {"$ref": "#/components/parameters/" + n}


def opid(code, meth, path, act):
    segs = [s for s in re.split(r"/", path) if s and not s.startswith("{")]
    base = "".join(re.sub(r"[^A-Za-z0-9]", " ", x).title().replace(" ", "") for x in segs)
    return meth.lower() + base + code


if __name__ == "__main__":
    d = build()
    txt = "# D03-04-PH06 · OpenAPI PH-06 (module mdm của dh-data). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("operation:", sum(1 for p in d["paths"].values() for _ in p), "đường dẫn:", len(d["paths"]), "lược đồ:", len(d["components"]["schemas"]), "->", OUT)
