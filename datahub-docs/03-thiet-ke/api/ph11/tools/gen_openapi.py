#!/usr/bin/env python3
"""Sinh openapi-bpm.yaml (OpenAPI 3.1) của PH-11 từ spec.py. Chạy từ thư mục api/ph11:  python3 tools/gen_openapi.py
Không sửa tay tệp YAML. Mọi operation có x-datahub-id, x-datahub-fr, x-datahub-permission, x-datahub-errors."""
import copy, os, re, sys
import yaml


class NoAlias(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

OUT = os.path.join(spec.ROOT, "openapi-bpm.yaml")
SC = spec.SCH
TID = "4bf92f3577b34da6a3ce929d0e0e4736"
STATUS = {400: ("BadRequest", "Dữ liệu không hợp lệ", "ERR-11-003"), 401: ("Unauthorized", "Chưa xác thực", "ERR-00-401"),
          403: ("Forbidden", "Không đủ quyền hoặc ngoài phạm vi", "ERR-11-034"), 404: ("NotFound", "Không tìm thấy", "ERR-11-001"),
          409: ("Conflict", "Xung đột trạng thái hoặc ETag", "ERR-11-004"), 410: ("Gone", "Đã hết lưu giữ", "ERR-11-001"),
          413: ("PayloadTooLarge", "Vượt giới hạn cỡ", "ERR-11-009"), 422: ("Unprocessable", "Không xử lý được", "ERR-11-007"),
          429: ("TooManyRequests", "Vượt hạn mức gọi", "ERR-11-041"), 503: ("ServiceUnavailable", "Dịch vụ phụ thuộc không khả dụng", "ERR-11-046")}
NOTE = {
    "004": "Tệp BPMN 2.0 XML hoặc gói; phần tử ngoài bảng 6.2-a bị gỡ và nêu trong `report`. Quá `11.model.maxXmlKb`: ERR-11-009.",
    "010": "`If-Match` theo `ETag` của phiên bản; chỉ người giữ khóa soạn thảo được lưu (ERR-11-016). Giao diện tự lưu mỗi `11.designer.autosaveSeconds` giây (30). Mỗi lần lưu chạy kiểm tra tĩnh nhanh.",
    "012": "Khóa hết hạn sau `11.designer.lockMinutes` phút không thao tác; người khác khóa trả ERR-11-016 kèm tên người giữ.",
    "014": "`QUICK` chỉ phần tử đổi; `FULL` kiểm thêm ánh xạ ý định sang luồng PH-04 trên `targetEnvironment` và bù trừ. Có lỗi `ERROR` thì `blocking = true`.",
    "016": "Chuyển phiên bản sang `IN_REVIEW`, tạo việc duyệt `PUBLISH_REVIEW`; kiểm tra tĩnh `FULL` phải không còn lỗi `ERROR` (ERR-11-010).",
    "020": "Bốn mắt: người duyệt khác người gửi (ERR-11-005). Hệ thống triển khai lên engine Flowable; lỗi triển khai đưa đề nghị về `DEPLOY_FAILED` (ERR-11-046). `waiverDecisions[]` quyết định từng miễn bù trừ `NONE_APPROVED` của đề nghị; đề nghị `RESTORE` (API-11-131) duyệt cũng qua operation này, không triển khai lại.",
    "022": "`DEPRECATED`: không khởi tạo phiên mới, phiên đang chạy chạy tiếp. Phiên bản `PUBLISHED` duy nhất cần `confirmSolePublished = true` (ERR-11-038).",
    "023": "`RETIRED`: còn phiên chạy hoặc tham chiếu thì ERR-11-037; cần bốn mắt.",
    "024": "`format` là `bpmn` (mặc định) hoặc `package`; trả `Content-Disposition` kèm tên tệp.",
    "043": "Bốn mắt: người phát hành khác người soạn mẫu; mẫu `COMMON` chỉ PA sửa (ERR-11-036).",
    "049": "Gửi lại cùng `businessKey` và cùng nội dung trả `200` kèm phiên cũ; khác nội dung trả ERR-11-018. `Idempotency-Key` dùng lại trong 24 giờ trả đúng phản hồi lần đầu. Biến `SENSITIVE` được mã hóa, không ghi vào nhật ký.",
    "051": "Biến không có trong phản hồi; lấy qua API-11-055. Cán bộ xử lý chỉ xem phiên có việc của mình hoặc đơn vị mình (ERR-11-034).",
    "052": "Dùng khi hệ gọi chỉ giữ `businessKey` (mã hồ sơ). Client chỉ thấy phiên do mình khởi tạo (scope `bpm.instance.read`).",
    "055": "Giá trị biến `SENSITIVE` luôn che; xem đầy đủ cần `PERM-09-unmask`, `unmask=true` và tiêu đề `X-Unmask-Reason`, có ghi nhật ký truy cập; giao diện che lại sau `11.task.unmaskSeconds` giây (60).",
    "056": "`pauseDue = true` chỉ khi lý do pháp lý (`LEGAL_SUSPENSION`) và tạm dừng đồng hồ hạn. Phiên đang bù trừ: ERR-11-030.",
    "058": "`compensate = AUTO` chạy Saga theo bù trừ đã đăng ký: `202` kèm `sagaId`; `NONE` hủy ngay `200`. Hồ sơ giữ pháp lý: ERR-11-047.",
    "059": "Bốn mắt: người đề nghị khác người duyệt (API-11-061). `type = VARIABLE_UPDATE` chỉ biến có `editableBy`; `MOVE_TOKEN` cần `targetElementId` hợp lệ (ERR-11-032, 033).",
    "061": "Bốn mắt (ERR-11-005): người duyệt khác người đề nghị; duyệt xong thay đổi được áp ngay và ghi kiểm toán.",
    "064": "Kiểm tra mọi bước đang chờ đã ánh xạ sang phiên bản đích (ERR-11-031); không đổi dữ liệu phiên.",
    "066": "Bốn mắt; di trú theo lô `11.migration.batchSize` phiên, bất đồng bộ (`202`); phiên lỗi ghi sự cố ERR-11-119.",
    "069": "Tương quan theo (`messageName`, `businessKey`). Thông điệp đến sớm được đệm `11.message.bufferMinutes` phút; không có phiên chờ: ERR-11-049.",
    "071": "Chỉ cho lệnh `FAILED` hoặc `TIMED_OUT`; dùng lại `commandId` cũ để PH-04 chống trùng, tăng `attempt`.",
    "072": "`view`: `mine` (của tôi), `candidate` (nhóm, đơn vị của tôi), `unit`, `all` (chỉ `PERM-11-task-admin`). Scope `bpm.task.read` đọc việc của đơn vị, không có biến `SENSITIVE`.",
    "074": "Nhận việc nguyên tử: người đến sau gặp ERR-11-021 kèm tên người nhận và giờ nhận.",
    "076": "`decision` thuộc `decisions` của biểu mẫu; `comment` từ 20 ký tự khi `REJECT`, `RETURN`, `REQUEST_SUPPLEMENT` (ERR-11-007). Việc duyệt kiểm tách nhiệm vụ `separateFrom` (ERR-11-005).",
    "077": "Nháp không kiểm bắt buộc; trường `SENSITIVE` được mã hóa. Giao diện lưu sau `11.task.draftDebounceSeconds` giây (5) kể từ lần sửa cuối.",
    "078": "Người chuyển phải còn ở nhóm ứng viên hoặc có quyền `PERM-11-task-admin` (ERR-11-024).",
    "082": "Tối đa `11.task.bulkMax` việc mỗi lần (ERR-11-050); việc không giao lại được nằm ở `skipped`.",
    "085": "Quá `11.task.attachmentMaxMb` MB hoặc sai loại: ERR-11-027; tệp được quét mã độc trước khi nhận (`scanStatus`).",
    "086": "Tải qua liên kết có hạn; tệp mang phân loại dữ liệu của lúc tải lên.",
    "089": "Gỡ trạng thái `WAITING_SUPPLEMENT`, tiếp tục đồng hồ hạn (hoặc tính lại theo `11.supplement.resetDue`); phiên không chờ bổ sung: ERR-11-049.",
    "091": "Sửa lịch năm đã qua hạn tính lại hạn các phiên đang chạy; kết quả nêu `recalculatedDues`.",
    "093": "Tính thử theo lịch tenant, không ghi dữ liệu; `explain[]` nêu ngày bị bỏ qua. Lịch thiếu năm: ERR-11-028.",
    "095": "Khoảng thời gian tối đa theo FRS 8.1 (ERR-11-039); kết quả tải qua liên kết có hạn.",
    "098": "Chỉ khi phiên `RUNNING` hoặc `SUSPENDED` (ERR-11-006); trả ERR-11-030 nếu Saga đang chạy.",
    "101": "Chỉ là đề nghị: bước vẫn `MANUAL`, tạo việc `MANUAL_COMPENSATION` cho TA khác; không truyền người duyệt. Người duyệt dùng API-11-132 hoặc 133; người đề nghị không tự duyệt (ERR-11-005). Ghi kiểm toán, cảnh báo P1 nếu bước ghi dữ liệu ngoài.",
    "099": "`RETRY`: gửi lại lệnh bù trừ; bước `RUNNING`.",
    "100": "`RESOLVE_MANUAL`: bắt buộc `evidence[]` (tệp theo quy tắc FR-11-043, ERR-11-027); bước thành `DONE`.",
    "128": "Bộ lọc như API-11-050, tối đa 50.000 dòng; tạo tác vụ nền (`202`), tải qua liên kết có hạn. Khoảng thời gian quá 366 ngày: ERR-11-039.",
    "129": "Bộ lọc như API-11-096, tối đa 50.000 dòng; tác vụ nền, tệp CSV có checksum.",
    "130": "Khoảng thời gian tối đa 366 ngày (ERR-11-039); không có giá trị `SENSITIVE`; tác vụ nền.",
    "131": "Chỉ bản `DEPRECATED` khi mô hình không còn bản `PUBLISHED` (ERR-11-006). Tạo đề nghị `kind = RESTORE`; người khác duyệt bằng API-11-020 (ERR-11-005), bản về `PUBLISHED`, không triển khai lại.",
    "132": "Người duyệt khác người đề nghị (ERR-11-005); bước `MANUAL` thành `SKIPPED`, ghi kiểm toán; hết bước thủ công thì Saga kết thúc theo FR-11-051.",
    "133": "Từ chối bỏ qua: bước về `MANUAL`; `comment` từ 20 ký tự (ERR-11-007); người đề nghị không tự từ chối (ERR-11-005).",
    "134": "Danh sách giữ pháp lý của tenant; `released = true` gồm cả bản đã gỡ.",
    "135": "Gỡ kèm lý do; từ lúc gỡ, phiên lại thuộc lịch dọn dẹp lưu giữ.",
    "136": "Gửi thông báo (EVT-11-20) cho người giữ khóa; không tự nhả khóa. Người giữ khóa là chính người gọi: ERR-11-006.",
    "137": "Danh sách lần chạy mẫu `MAU_TUAN_THU_BPMN`; tải gói qua API-11-122.",
    "104": "Chỉ tiến độ rút gọn: bước có `publicName`, trạng thái công khai, thông điệp theo mẫu; không biến, không tên cán bộ, không lỗi kỹ thuật. Đệm 30 giây (`Cache-Control: max-age=30`). Không có quan hệ client với hồ sơ trả như không tồn tại (ERR-11-035).",
    "105": "Lịch sử đầy đủ gồm người, quyết định, ý kiến; mỗi lượt đọc ghi nhật ký truy cập.",
    "113": "Tối đa 100 sự cố mỗi lần; mỗi sự cố xử lý riêng, kết quả ở `results[]`.",
    "115": "Thay toàn bộ danh sách quy tắc; ngoài miền: ERR-11-029.",
    "117": "Mỗi khóa theo miền ở FRS 8.2; ngoài miền hoặc vượt trần `COMMON` trả ERR-11-029.",
    "119": "Giá trị ngoài miền: ERR-11-029. Đang giữ pháp lý không bị dọn (ERR-11-047).",
    "120": "Hồ sơ giữ pháp lý không bị dọn lịch sử cho tới khi gỡ giữ.",
    "122": "Gói ZIP gồm BPMN, lịch sử mẫu, kết quả kiểm tra; liên kết ký có hạn.",
    "124": "Chỉ gợi ý, cán bộ quyết định; quá `11.ai.timeoutSeconds` giây trả `200` với `suggestions` rỗng (ERR-11-124 chỉ ghi nhật ký). Ghi nhận `ai_assisted` khi hoàn thành việc.",
    "125": "Nhà cung cấp việc cho hộp \"Việc của tôi\" (FR-00-070): chỉ tiêu đề, hạn, đường dẫn; không có giá trị biến.",
    "126": "Liên kết sự kiện PH-10 đang bật; sửa ở PH-10, PH-11 chỉ đọc.",
    "127": "Dùng cho khởi tạo thủ công trên giao diện (FR-11-020); client máy dùng API-11-049.",
}


# mã lỗi FRS nêu trong luồng nhưng không kèm mã HTTP ở dòng ngoại lệ
EXTRA_ERR = {"122": [("ERR-11-006", 409)], "014": [("ERR-11-010", 422), ("ERR-11-013", 422)], "016": [("ERR-11-010", 422), ("ERR-11-013", 422)], "020": [("ERR-11-005", 403), ("ERR-11-010", 422)], "094": [("ERR-11-003", 400), ("ERR-11-039", 422)], "095": [("ERR-11-039", 422)], "123": [("ERR-11-039", 422)], "128": [("ERR-11-039", 422)], "129": [("ERR-11-039", 422)], "130": [("ERR-11-039", 422)], "112": [("ERR-11-007", 422)], "056": [("ERR-11-007", 422)], "057": [("ERR-11-007", 422)], "058": [("ERR-11-007", 422)], "101": [("ERR-11-007", 422)], "069": [("ERR-11-019", 422)], "127": [("ERR-11-019", 422)], "077": [("ERR-11-023", 422)], "051": [("ERR-11-001", 410)], "032": [("ERR-11-015", 422)]}


def ref(n):
    return {"$ref": "#/components/schemas/" + n}


def ref_p(n):
    return {"$ref": "#/components/parameters/" + n}


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
        if e is not None:
            out[k] = e
    return out


def clean(s):
    s = copy.deepcopy(s)
    s.pop("x-ex", None)
    return s


def opid(code, meth, path):
    segs = [s for s in re.split(r"/", path) if s and not s.startswith("{")]
    base = "".join(re.sub(r"[^A-Za-z0-9]", " ", x).title().replace(" ", "") for x in segs)
    return meth.lower() + base + code


def build():
    params = {
        "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": {"type": "string", "format": "uuid"},
                           "description": "UUID do bên gọi sinh; gửi lại cùng khóa trong 24 giờ trả đúng phản hồi lần đầu; dùng lại với nội dung khác trả `409` (ERR-11-051)."},
        "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": {"type": "string"},
                    "description": "`ETag` của tài nguyên (`W/\"{version}\"`); không khớp trả ERR-11-004. Thiếu tiêu đề trả `428` (ERR-00-428)."},
        "Traceparent": {"name": "traceparent", "in": "header", "required": False, "schema": {"type": "string"}, "description": "W3C Trace Context."},
        "AcceptLanguage": {"name": "Accept-Language", "in": "header", "required": False, "schema": {"type": "string", "default": "vi", "enum": ["vi", "en"]}},
        "UnmaskReason": {"name": "X-Unmask-Reason", "in": "header", "required": False, "schema": {"type": "string", "minLength": 20, "maxLength": 500},
                         "description": "Lý do xem giá trị `SENSITIVE` đầy đủ, bắt buộc khi `unmask=true`; ở tiêu đề để không vào log đường dẫn."},
    }
    for n, (t, ex) in spec.PATHP.items():
        sch, _ = spec.tschema(t)
        p = {"name": n, "in": "path", "required": True, "schema": sch}
        if ex is not None:
            p["example"] = ex
        params[n[0].upper() + n[1:]] = p
    responses = {}
    for st, (n, title, code) in STATUS.items():
        responses[n] = {"description": title + ".", "content": {"application/problem+json": {"schema": ref("Problem"), "examples": {"vi-du": {"value": {
            "type": "https://datahub.example.vn/errors/" + code, "title": title, "status": st, "detail": title + ".", "code": code, "traceId": TID}}}}}}
    responses["PreconditionRequired"] = {"description": "Thiếu `If-Match`.", "content": {"application/problem+json": {"schema": ref("Problem"), "examples": {"vi-du": {"value": {
        "type": "https://datahub.example.vn/errors/ERR-00-428", "title": "Thiếu If-Match", "status": 428, "code": "ERR-00-428", "traceId": TID}}}}}}
    paths = {}
    for code, meth, path, frs_, pm in spec.ROWS:
        o = spec.OPS[code]
        fl = o["flags"]
        m = meth.lower()
        ifm = (m in ("put", "patch") or (m == "post" and re.search(r"\}:[a-z-]+$", path) is not None)) and "noifm" not in fl
        idem = "idem" in fl
        pnames = re.findall(r"\{(\w+)\}", path)
        P = [ref_p("IdempotencyKey")] if idem else []
        if ifm:
            P.append(ref_p("IfMatch"))
        P += [ref_p(n[0].upper() + n[1:]) for n in pnames]
        for q in o["query"]:
            if q == "page":
                P.append({"name": "page", "in": "query", "schema": {"type": "integer", "minimum": 0, "default": 0}})
            elif q == "size":
                P.append({"name": "size", "in": "query", "schema": {"type": "integer", "minimum": 1, "maximum": 100, "default": 20}})
            else:
                n, t = q.split(":", 1)
                sch, ex = spec.tschema(t)
                pp = {"name": n, "in": "query", "schema": sch}
                if ex is not None:
                    pp["example"] = ex
                if n in ("processKey", "businessKey") and code in ("052",):
                    pp["required"] = True
                P.append(pp)
        if any(q.startswith("unmask:") for q in o["query"]):
            P.append(ref_p("UnmaskReason"))
        P += [ref_p("Traceparent"), ref_p("AcceptLanguage")]
        errs, stat = [], set()
        for f in frs_:
            for e, st in spec.FRERR.get(f, []):
                if int(e[-3:]) < 100:
                    errs.append(e)
                    stat.add(st)
        for e, st in EXTRA_ERR.get(code, []):
            errs.append(e)
            stat.add(st)
        if o["req"] or any(q.split(":")[0] in ("page", "size") for q in o["query"]):
            errs.append("ERR-11-003")
            stat.add(400)
        if ifm:
            errs.append("ERR-11-004")
            stat.add(409)
        if pnames and code != "104" and m in ("get", "put", "patch", "post"):
            errs.append("ERR-11-001")
            stat.add(404)
        if code == "104":
            errs.append("ERR-11-035")
            stat.add(404)
        errs = list(dict.fromkeys(errs))
        stat |= {401, 403}
        if ifm:
            stat.add(428)
        if idem:
            stat.add(409)
        rs = {}
        ok = o["status"]
        if o["res"] == "binary":
            okc = {"application/octet-stream": {"schema": {"type": "string", "format": "binary"}}}
        else:
            okc = {"application/json": {"schema": ref(o["res"]), "examples": {"vi-du": {"value": ex_of(o["res"])}}}}
        hdr = {}
        if o["res"] != "binary" and not o["res"].endswith("Page"):
            hdr["ETag"] = {"schema": {"type": "string"}, "description": "`W/\"{version}\"`."}
        if ok == 201:
            hdr["Location"] = {"schema": {"type": "string"}, "description": "Đường dẫn tài nguyên mới."}
        if "cache30" in fl:
            hdr["Cache-Control"] = {"schema": {"type": "string"}, "description": "`max-age=30` (tham số `11.progress.cacheSeconds`)."}
        rs[str(ok)] = {"description": "Thành công.", "content": okc}
        if hdr:
            rs[str(ok)]["headers"] = hdr
        for f in fl:
            if f.startswith("also:"):
                rs[f[5:]] = {"description": "Thành công theo nhánh khác (xem ghi chú).", "content": okc}
        for st in sorted(stat):
            rs[str(st)] = {"$ref": "#/components/responses/" + ("PreconditionRequired" if st == 428 else STATUS[st][0])}
        op = {"tags": [o["tag"]], "operationId": opid(code, meth, path), "summary": o["summary"], "x-datahub-id": "API-11-" + code, "x-datahub-fr": frs_}
        op["x-datahub-permission"] = {"permission": pm["text"]}
        if pm["scopes"]:
            op["x-datahub-scope"] = pm["scopes"][0]
        sec = []
        if pm["user"] or pm["extra"]:
            sec.append({"oauth2User": []})
        for s_ in pm["scopes"]:
            sec.append({"oauth2Machine": [s_]})
        op["security"] = sec
        if idem:
            op["x-datahub-idempotent"] = "required"
        if ifm:
            op["x-datahub-if-match"] = "required"
        desc = NOTE.get(code, "")
        if pm["note"]:
            desc = (desc + " " if desc else "") + "Ghi chú quyền theo FRS 9.4: " + pm["note"] + "."
        op["description"] = desc.strip() or "Theo FRS 9.4."
        op["parameters"] = P
        op["x-datahub-errors"] = errs
        if o["req"]:
            ct = "multipart/form-data" if "multipart" in fl else "application/json"
            op["requestBody"] = {"required": True, "content": {ct: {"schema": ref(o["req"]), "examples": {"vi-du": {"value": ex_of(o["req"])}}}}}
        op["responses"] = rs
        paths.setdefault(path, {})[m] = op
    schemas = {k: clean(v) for k, v in SC.items()}
    scopes = {"bpm.instance.start": "Khởi tạo phiên, gửi thông điệp, báo đã bổ sung hồ sơ", "bpm.instance.read": "Đọc phiên do chính client khởi tạo (đã che)",
              "bpm.task.read": "Đọc việc của đơn vị, không có biến SENSITIVE", "bpm.progress.read": "Tra tiến độ hồ sơ cho kênh DVC (đã che)",
              "bpm.service.worker": "PH-04 tiêu thụ lệnh service task qua Kafka (không có REST)"}
    d = {"openapi": "3.1.0", "info": {
        "title": "Datahub · PH-11 Quy trình liên thông API", "version": "1.0.0-draft",
        "summary": "Mô hình quy trình, phiên bản, duyệt phát hành, phiên, việc, hạn, Saga, tiến độ cho kênh DVC, giám sát, cấu hình.",
        "description": "Module `bpm` của `dh-platform` (Flowable nhúng), gốc `/api/bpm/v1`. Người dùng gọi qua BFF; Cổng DVC, HTTT một cửa, PH-01, PH-07, PH-19 gọi bằng token máy qua PH-03.\n\n"
                       "Quy ước (D03-04-PH11 §1): tenant lấy từ token; tạo và khởi tạo nhận `Idempotency-Key`; sửa và hành động có `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-11-nnn`; phân trang `page`, `size`.\n\n"
                       "Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.",
        "contact": {"name": "Nhóm phân hệ PH-11"}, "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
        "x-datahub-document": "D03-04-PH11", "x-datahub-phase": "PH-11"},
        "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn/api/bpm/v1", "description": "Qua BFF console của tenant (giả lập)", "variables": {"tenantHost": {"default": "t68", "description": "Mã tenant chữ thường."}}},
                    {"url": "https://api.{tenantHost}.datahub.example.vn/api/bpm/v1", "description": "Cổng API cho Cổng DVC, HTTT, PH-01, PH-07, PH-19 (token máy)", "variables": {"tenantHost": {"default": "t68"}}},
                    {"url": "http://dh-platform.dh-platform.svc:8080/api/bpm/v1", "description": "Trong cụm"}],
        "security": [{"oauth2User": []}],
        "tags": [{"name": t, "description": "Nhóm " + t + "; bảng mã ở D03-04-PH11 §3."} for t in spec.TAGS],
        "paths": paths,
        "components": {"securitySchemes": {
            "oauth2User": {"type": "oauth2", "description": "Người dùng qua Keycloak (OIDC, PKCE qua BFF); quyền `PERM-11-*`.", "flows": {"authorizationCode": {
                "authorizationUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/auth", "tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": {}}}},
            "oauth2Machine": {"type": "oauth2", "description": "Máy với máy (client_credentials, mTLS hoặc private_key_jwt).", "flows": {"clientCredentials": {
                "tokenUrl": "https://sso.datahub.example.vn/realms/datahub/protocol/openid-connect/token", "scopes": scopes}}}},
            "parameters": params, "responses": responses, "schemas": schemas}}
    return d


if __name__ == "__main__":
    d = build()
    txt = "# D03-04-PH11 · OpenAPI PH-11 (module bpm của dh-platform). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("operation:", sum(1 for p in d["paths"].values() for _ in p), "đường dẫn:", len(d["paths"]), "lược đồ:", len(d["components"]["schemas"]), "->", OUT)
