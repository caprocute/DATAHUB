#!/usr/bin/env python3
"""Sinh openapi-catalog.yaml (OpenAPI 3.1) của PH-02 từ spec.OPS và schemas.S. Chạy: python3 tools/gen_openapi.py"""
import os
import re
import sys

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import schemas as sc  # noqa: E402
import spec  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH02-frs-danh-muc-dich-vu.md")
OUT = os.path.join(ROOT, "openapi-catalog.yaml")

# ---- Mã lỗi: nguồn là FRS §9.1 (đã chốt); không lặp lại bảng ở nơi khác
ERRS = {}
for line in open(FRS, encoding="utf-8"):
    m = re.match(r"^\| ERR-02-(\d{3}) \| (\d{3}) \| ([^|]+) \|$", line.strip())
    if m:
        ERRS[m.group(1)] = (int(m.group(2)), m.group(3).strip())
assert len(ERRS) == 45, len(ERRS)

PERM = {
    "read": "PERM-02-read", "create": "PERM-02-create", "submit": "PERM-02-submit", "publish": "PERM-02-publish", "subscribe": "PERM-02-subscribe",
    "approve-subscription": "PERM-02-approve-subscription", "operate": "PERM-02-operate", "admin": "Quyền quản trị phân hệ (đề nghị, động từ admin)",
}
ANY_PERM = {"045": "PERM-02-publish hoặc PERM-02-approve-subscription", "046": "PERM-02-publish hoặc PERM-02-approve-subscription",
            "047": "PERM-02-create hoặc PERM-02-operate", "051": "PERM-02-submit hoặc PERM-02-create", "053": "PERM-02-create hoặc PERM-02-submit",
            "065": "PERM-02-subscribe", "027": "PERM-02-create", "004": "PERM-02-read", "005": "PERM-02-read"}
IFM_OFF = {"017", "040", "082", "086", "092", "093", "094"}
IFM_ON_POST_ACTION = re.compile(r":[a-z-]+$")
NO_IDEM_BODY = set()

QUERY = {
    "page": ("page", {"type": "integer", "minimum": 1, "default": 1}, "Trang, bắt đầu từ 1.", False),
    "size": ("size", {"type": "integer", "minimum": 1, "maximum": 100, "default": 20}, "Số dòng mỗi trang; quá 100 trả ERR-02-003.", False),
    "sort": ("sort", {"type": "string", "pattern": r"^[a-zA-Z]+:(asc|desc)$"}, "`trường:asc|desc`, ví dụ `updatedAt:desc`.", False),
    "status": ("status", {"type": "string"}, "Danh sách trạng thái phiên bản, phân tách dấu phẩy (ví dụ `PUBLISHED,DEPRECATED`).", False),
    "planStatus": ("status", {"type": "string"}, "Danh sách trạng thái gói, phân tách dấu phẩy.", False),
    "topicStatus": ("status", {"type": "string"}, "Trạng thái topic ở PH-10.", False),
    "reviewStatus": ("status", {"type": "string"}, "Trạng thái yêu cầu duyệt, phân tách dấu phẩy (mặc định `PENDING`).", False),
    "subStatus": ("status", {"type": "string"}, "Trạng thái đăng ký, phân tách dấu phẩy.", False),
    "syncStatus": ("status", {"type": "string"}, "Trạng thái bản ghi đồng bộ, phân tách dấu phẩy.", False),
    "findingStatus": ("status", {"type": "string"}, "Trạng thái phát hiện, phân tách dấu phẩy.", False),
    "dataClass": ("dataClass", {"type": "string"}, "Danh sách mức phân loại dữ liệu.", False),
    "visibility": ("visibility", {"type": "string"}, "Danh sách mức hiển thị.", False),
    "origin": ("origin", {"type": "string"}, "Nguồn gốc API.", False),
    "categoryCode": ("categoryCode", {"$ref": "#/components/schemas/CategoryCode"}, "Nhóm phân loại (gồm nhóm con).", False),
    "tag": ("tag", {"type": "string", "maxLength": 40}, "Thẻ.", False),
    "providerSystemCode": ("providerSystemCode", {"$ref": "#/components/schemas/SystemCode"}, "HTTT cung cấp.", False),
    "ownerOrgCode": ("ownerOrgCode", {"$ref": "#/components/schemas/OrgCode"}, "Đơn vị chủ quản.", False),
    "attention": ("attention", {"type": "boolean"}, "Chỉ API có cờ cảnh báo (thẻ \"Cần chú ý\").", False),
    "versionNo": ("versionNo", {"$ref": "#/components/schemas/VersionNo"}, "Mở đúng phiên bản; mặc định `PUBLISHED` mới nhất.", False),
    "qreq": ("q", {"type": "string", "minLength": 2, "maxLength": 200}, "Từ khóa.", True),
    "q": ("q", {"type": "string", "maxLength": 200}, "Từ khóa.", False),
    "updatedSince": ("updatedSince", {"type": "string", "format": "date-time"}, "Chỉ trả mục đổi sau thời điểm này, kèm `removed[]`.", False),
    "resolved": ("resolved", {"type": "boolean", "default": True}, "Gộp tham chiếu ngoài.", False),
    "moveTo": ("moveTo", {"$ref": "#/components/schemas/CategoryCode"}, "Nhóm đích nhận API (bắt buộc khi nhóm còn API).", False),
    "dryRun": ("dryRun", {"type": "boolean", "default": False}, "Chỉ tính tác động, không ghi.", False),
    "layer": ("layer", {"$ref": "#/components/schemas/Layer"}, "Lớp kiểm tra.", False),
    "severity": ("severity", {"$ref": "#/components/schemas/Severity"}, "Mức.", False),
    "contextPath": ("contextPath", {"type": "string", "pattern": "^/[a-z0-9/-]{3,120}$"}, "Context-path cần kiểm tra.", True),
    "apiCodeOpt": ("apiCode", {"$ref": "#/components/schemas/ApiCode"}, "Lọc theo API.", False),
    "environment": ("environment", {"$ref": "#/components/schemas/Environment"}, "Môi trường (mặc định `PROD`).", False),
    "sinceConfigVersion": ("sinceConfigVersion", {"type": "integer", "minimum": 0}, "Chỉ trả thay đổi sau số phiên bản cấu hình này.", False),
    "limit": ("limit", {"type": "integer", "minimum": 1, "maximum": 1000, "default": 500}, "Số bản ghi tối đa mỗi lượt.", False),
    "months": ("months", {"type": "integer", "minimum": 1, "maximum": 36, "default": 12}, "Số kỳ gần nhất.", False),
    "from": ("from", {"type": "string", "format": "date-time"}, "Từ thời điểm.", False),
    "to": ("to", {"type": "string", "format": "date-time"}, "Đến thời điểm.", False),
    "fromVersion": ("from", {"$ref": "#/components/schemas/VersionNo"}, "Phiên bản gốc.", True),
    "toVersion": ("to", {"$ref": "#/components/schemas/VersionNo"}, "Phiên bản đích.", True),
    "granularity": ("granularity", {"type": "string", "enum": ["HOUR", "DAY", "MONTH"], "default": "DAY"}, "Độ mịn chuỗi thời gian.", False),
    "kind": ("kind", {"$ref": "#/components/schemas/ReviewKind"}, "Loại yêu cầu duyệt.", False),
    "historyKind": ("kind", {"type": "string"}, "Loại sự kiện lịch sử.", False),
    "noticeKind": ("kind", {"type": "string"}, "Loại thông báo.", False),
    "mine": ("mine", {"type": "boolean"}, "Chỉ yêu cầu do người gọi gửi hoặc được giao.", False),
    "overdue": ("overdue", {"type": "boolean"}, "Chỉ yêu cầu quá hạn.", False),
    "systemCode": ("systemCode", {"$ref": "#/components/schemas/SystemCode"}, "HTTT khai thác.", False),
    "authTypeQ": ("authType", {"$ref": "#/components/schemas/AuthType"}, "Kiểu xác thực của gói.", False),
    "planCode": ("planCode", {"$ref": "#/components/schemas/PlanCode"}, "Gói.", False),
    "action": ("action", {"type": "string", "enum": ["UPSERT", "WITHDRAW"]}, "Hành động đồng bộ.", False),
    "expand": ("expand", {"type": "string", "enum": ["recipients"]}, "Mở rộng.", False),
    "againstVersionNo": ("againstVersionNo", {"$ref": "#/components/schemas/VersionNo"}, "So với phiên bản này (mặc định phiên bản kế nhiệm).", False),
    "scope": ("scope", {"type": "string", "enum": ["REGISTER", "VIEW"], "default": "VIEW"}, "Đăng ký hay chỉ xem.", False),
}
# `systemCode` bắt buộc ở API-02-059 khi không có apiCode: kiểm ở máy chủ (ERR-02-003)

PATHP = {
    "apiCode": "ApiCode", "versionNo": "VersionNo", "planCode": "PlanCode", "backendCode": "BackendCode", "categoryCode": "CategoryCode", "flowCode": "FlowCode",
    "subscriptionId": None, "reviewRequestId": None, "syncId": None, "findingId": None, "operationId": None, "importId": None,
}
ETAG_RES = {"ApiDetail", "VersionDetail", "Plan", "Backend", "Subscription", "SlaCommitment", "Category", "RuleSet", "SettingList", "Spec", "CatalogApi", "PublishedConfig", "CatalogPage"}
STATUS_RESP = {400: "BadRequest", 401: "Unauthorized", 403: "Forbidden", 404: "NotFound", 409: "Conflict", 412: "PreconditionFailed", 413: "PayloadTooLarge",
               422: "Unprocessable", 423: "Locked", 429: "TooManyRequests", 503: "Unavailable"}


def tag(g):
    return spec.TAGS[g]


def build_op(code, method, path, summary, fr, perm, idem, success, group, x):
    op = {"tags": [tag(group)], "operationId": None, "summary": summary}
    op["x-datahub-id"] = f"API-02-{code}"
    op["x-datahub-fr"] = [f"FR-02-{n.strip()}" for n in fr.split(",")]
    scopes = x.get("svc")
    if perm == "service":
        op["x-datahub-permission"] = {"permission": f"Token dịch vụ, phạm vi {scopes}"}
    else:
        op["x-datahub-permission"] = {"permission": ANY_PERM.get(code, PERM[perm])}
        if scopes:
            op["x-datahub-permission"]["scopes"] = [s.strip() for s in scopes.split(",")]
    if x.get("wave"):
        op["x-datahub-wave"] = x["wave"]
    errs = x.get("errs", [])
    desc = x.get("desc", "")
    if errs:
        desc = (desc + " " if desc else "") + "Mã lỗi riêng: " + ", ".join(f"ERR-02-{e}" for e in errs) + "."
    if desc:
        op["description"] = desc
    is_action = method == "POST" and bool(IFM_ON_POST_ACTION.search(path)) and code not in IFM_OFF
    ifm = x.get("ifm", method in ("PATCH", "PUT", "DELETE") or is_action)
    if code in IFM_OFF:
        ifm = False
    if x.get("ifm") is False:
        ifm = False
    params = []
    for name in re.findall(r"\{(\w+)\}", path):
        params.append({"$ref": f"#/components/parameters/{name[0].upper() + name[1:]}Path"})
    for qk in x.get("q", []):
        params.append({"$ref": f"#/components/parameters/Q_{qk}"})
    if idem:
        params.append({"$ref": "#/components/parameters/IdempotencyKey"})
        op["x-datahub-idempotent"] = True
    if ifm:
        params.append({"$ref": "#/components/parameters/IfMatch"})
    if x.get("ok2") and "304" in x["ok2"]:
        params.append({"$ref": "#/components/parameters/IfNoneMatch"})
    params += [{"$ref": "#/components/parameters/Traceparent"}, {"$ref": "#/components/parameters/AcceptLanguage"}]
    op["parameters"] = params
    # thân yêu cầu
    req = x.get("req")
    if req:
        if code == "015":
            content = {"application/json": {"schema": {"$ref": "#/components/schemas/SpecUpload"}},
                       "multipart/form-data": {"schema": {"$ref": "#/components/schemas/SpecUploadForm"}}}
        elif code == "085":
            content = {"multipart/form-data": {"schema": {"$ref": f"#/components/schemas/{req}"}}}
        else:
            content = {"application/json": {"schema": {"$ref": f"#/components/schemas/{req}"}}}
            if code in sc.EXAMPLES:
                content["application/json"]["example"] = sc.EXAMPLES[code]
        op["requestBody"] = {"required": True, "content": content}
    # phản hồi
    res = x.get("res")
    ct = x.get("ct")
    resp = {}

    def okresp(status):
        r = {"description": {"200": "Thành công.", "201": "Đã tạo.", "202": "Đã nhận, xử lý bất đồng bộ hoặc chờ duyệt.", "204": "Không có nội dung.", "304": "Không đổi so với `If-None-Match`."}[status]}
        headers = {}
        if status == "304":
            return r
        if status == "201":
            headers["Location"] = {"schema": {"type": "string", "format": "uri-reference"}}
        if res in ETAG_RES and status in ("200", "201"):
            headers["ETag"] = {"schema": {"type": "string"}}
        if status == "202" and res in (None, "OperationAccepted", "ReviewAccepted"):
            headers["Location"] = {"schema": {"type": "string", "format": "uri-reference"}}
        if headers:
            r["headers"] = headers
        if status in ("204",):
            return r
        if status == "202" and code in ("027", "028", "029", "047", "051", "053", "065"):
            schema = {"$ref": "#/components/schemas/ReviewAccepted"} if code != "047" else {"$ref": "#/components/schemas/PublishResult"}
            r["content"] = {"application/json": {"schema": schema}}
            return r
        if code in ("068", "069", "071") and status == "202":
            r["content"] = {"application/json": {"schema": {"$ref": f"#/components/schemas/{res}"}}}
            return r
        if status == "200" and code == "012":
            r["content"] = {"application/json": {"schema": {"$ref": "#/components/schemas/CategoryImpact"}}}
            return r
        if status == "200" and code == "051":
            r["content"] = {"application/json": {"schema": {"$ref": "#/components/schemas/VersionDetail"}}}
            return r
        if res:
            schema = {"$ref": f"#/components/schemas/{res}"}
            if ct == "application/yaml":
                r["content"] = {"application/yaml": {"schema": {"type": "string"}}, "application/json": {"schema": schema}}
            elif ct == "application/sarif+json":
                r["content"] = {"application/json": {"schema": schema}, "application/sarif+json": {"schema": {"type": "object", "description": "SARIF 2.1.0."}}}
            elif ct == "application/x-ndjson":
                r["content"] = {"application/json": {"schema": schema}, "application/x-ndjson": {"schema": {"type": "string", "description": "Mỗi dòng một đối tượng JSON: dòng đầu là đầu bản (`PublishedConfig` không có `apis`), tiếp theo `PublishedApi`, `PublishedConsumer`."}}}
            else:
                r["content"] = {"application/json": {"schema": schema}}
        elif status == "202":
            r["content"] = {"application/json": {"schema": {"$ref": "#/components/schemas/OperationAccepted"}}}
        return r

    for s in [success] + list(x.get("ok2", [])):
        if code == "082" and s == "204":
            resp["204"] = {"description": "Đã ghi nhận (lũy đẳng)."}
        else:
            resp[s] = okresp(s)
    if code in ("016", "032", "084") and "202" in resp:
        resp["202"]["content"] = {"application/json": {"schema": {"$ref": "#/components/schemas/OperationAccepted"}}}
    # lỗi
    codes = {401, 403}
    if re.search(r"\{\w+\}", path) or "001" in errs:
        codes.add(404)
    if req or x.get("q") or "003" in errs or "041" in errs:
        codes.add(400)
    if ifm:
        codes.add(412)
    for e in errs:
        codes.add(ERRS[e][0])
    for st in sorted(codes):
        resp[str(st)] = {"$ref": f"#/components/responses/{STATUS_RESP[st]}"}
    op["responses"] = resp
    op["operationId"] = oid(code, method, path)
    return op


OPID = {}


def oid(code, method, path):
    segs = [s for s in re.split(r"[/:]", path) if s and not s.startswith("{")]
    segs = [s for s in segs if s not in ("internal",)]
    name = method.lower() + "".join(w.capitalize() for s in segs for w in re.split(r"[-_]", s))
    if name in OPID.values():
        name += code
    OPID[code] = name
    return name


def parameters():
    P = {}
    P["IdempotencyKey"] = {"name": "Idempotency-Key", "in": "header", "required": True, "schema": {"type": "string", "minLength": 16, "maxLength": 128},
                           "description": "Khóa chống trùng, giữ 24 giờ theo (tenant, người gọi, khóa); cùng khóa khác thân trả ERR-02-042 (422)."}
    P["IfMatch"] = {"name": "If-Match", "in": "header", "required": True, "schema": {"type": "string", "maxLength": 128}, "description": "`ETag` hiện tại; lệch trả ERR-02-015 (412)."}
    P["IfNoneMatch"] = {"name": "If-None-Match", "in": "header", "required": False, "schema": {"type": "string", "maxLength": 128}, "description": "`ETag` lần trước; khớp thì trả `304`."}
    P["Traceparent"] = {"name": "traceparent", "in": "header", "required": False, "schema": {"type": "string", "pattern": "^[0-9a-f]{2}-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$"}, "description": "Truy vết W3C."}
    P["AcceptLanguage"] = {"name": "Accept-Language", "in": "header", "required": False, "schema": {"type": "string", "enum": ["vi", "en"], "default": "vi"}, "description": "Ngôn ngữ của `title`, `detail`."}
    for name, tname in PATHP.items():
        sch = {"$ref": f"#/components/schemas/{tname}"} if tname else {"type": "string", "format": "uuid"}
        P[name[0].upper() + name[1:] + "Path"] = {"name": name, "in": "path", "required": True, "schema": sch}
    for k, (name, sch, desc, req) in QUERY.items():
        P[f"Q_{k}"] = {"name": name, "in": "query", "required": req, "schema": sch, "description": desc}
    return P


def problem_resp(desc, status, err):
    num = err
    title = ERRS[num][1] if num in ERRS else desc
    return {"description": desc, "content": {"application/problem+json": {"schema": {"$ref": "#/components/schemas/ProblemDetails"}, "example": {
        "type": f"https://datahub.gov.vn/errors/ERR-02-{num}", "title": title, "status": status, "code": f"ERR-02-{num}", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}


def responses():
    return {
        "BadRequest": problem_resp("Dữ liệu không hợp lệ theo lược đồ (ERR-02-003, kèm `errors[]` theo trường) hoặc thiếu lý do (ERR-02-041).", 400, "003"),
        "Unauthorized": problem_resp("Thiếu token hoặc token hết hạn (ERR-02-014).", 401, "014"),
        "Forbidden": problem_resp("Không có quyền (ERR-02-014) hoặc vi phạm bốn mắt (ERR-02-013).", 403, "014"),
        "NotFound": problem_resp("Không tìm thấy hoặc thuộc tenant khác, cùng thân (ERR-02-001).", 404, "001"),
        "Conflict": problem_resp("Trùng mã, trạng thái không cho phép, thiếu điều kiện hoặc còn đối tượng phụ thuộc: ERR-02-002, 011, 012, 017, 024, 025, 027, 030, 035, 038, 044.", 409, "011"),
        "PreconditionFailed": problem_resp("Đối tượng đã thay đổi, `If-Match` không khớp (ERR-02-015).", 412, "015"),
        "PayloadTooLarge": problem_resp("Đặc tả hoặc tệp vượt kích thước tối đa (ERR-02-009).", 413, "009"),
        "Unprocessable": problem_resp("Nghiệp vụ không hợp lệ: ERR-02-004…008, 010, 016, 018…023, 026, 028, 029, 031, 032, 037, 040, 042, 043, 045 (kèm `findings[]` hoặc `errors[]` khi có).", 422, "006"),
        "Locked": problem_resp("Đang đóng băng thay đổi môi trường thật (ERR-02-039).", 423, "039"),
        "TooManyRequests": problem_resp("Vượt số lần kiểm tra, nạp URL hoặc thông báo tay cho phép (ERR-02-036, kèm `retryAfterSeconds`).", 429, "036"),
        "Unavailable": problem_resp("Cổng API hoặc dịch vụ phụ thuộc không khả dụng: ERR-02-033, 034.", 503, "034"),
    }


def main():
    paths = {}
    for code, method, path, summary, fr, perm, idem, success, group, x in spec.OPS:
        paths.setdefault(path, {})[method.lower()] = build_op(code, method, path, summary, fr, perm, bool(idem), success, group, x)
    doc = {
        "openapi": "3.1.0",
        "info": {
            "title": "Datahub · PH-02 Danh mục dịch vụ API",
            "version": "1.0.0-draft",
            "summary": "Danh mục, đăng ký, kiểm tra đặc tả, gói sử dụng, vòng đời, đăng ký sử dụng, đồng bộ quốc gia, SLA, giao diện nội bộ cho cổng API.",
            "description": ("API của module `catalog` trong `dh-connect` (control plane PH-02). Người dùng gọi qua BFF console (Authorization Code + PKCE); HTTT khai thác đọc danh mục bằng token máy "
                            "(`catalog:read`); PH-03, PH-04, PH-15 gọi `/internal/*` bằng token dịch vụ. Tenant lấy từ token. Tạo và lệnh đổi trạng thái nhận `Idempotency-Key`; sửa và đổi trạng thái bắt buộc `If-Match`; "
                            "hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-02-nnn`; phân trang `page`/`size`. Không API nào trả khóa, bí mật hay giá trị thật của dữ liệu cá nhân. Mọi tên miền, dữ liệu là giả lập. "
                            "Tệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
            "contact": {"name": "Nhóm phân hệ PH-02"},
            "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
            "x-datahub-document": "D03-04-PH02",
            "x-datahub-phase": "PH-02",
        },
        "servers": [
            {"url": "https://console.{tenantHost}.datahub.example.vn/api/catalog/v1", "description": "Qua BFF console của tenant, giả lập",
             "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
            {"url": "http://dh-connect.dh-control.svc:8080/api/catalog/v1", "description": "Trong cụm, cho PH-03, PH-04, PH-15"},
            {"url": "http://localhost:8082/api/catalog/v1", "description": "Phát triển cục bộ"},
        ],
        "security": [{"oauth2User": []}],
        "tags": [{"name": t} for t in spec.TAGS.values()],
        "paths": paths,
        "components": {
            "securitySchemes": {
                "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-02-* (D02-08). Người dùng qua BFF, token không ra trình duyệt.",
                               "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                                                "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
                "oauth2Service": {"type": "oauth2", "description": "Token máy: PH-03, PH-04, PH-15, PH-13, PH-16 (`private_key_jwt` hoặc mTLS) và HTTT khai thác (`catalog:read`).",
                                  "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {
                                      "catalog:read": "HTTT khai thác đọc danh mục công khai trong tenant, tải đặc tả",
                                      "catalog:gateway-read": "PH-03 đọc dữ liệu công bố",
                                      "catalog:gateway-ack": "PH-03 xác nhận đã nạp cấu hình (đề nghị bổ sung ở FRS §3.3)",
                                      "catalog:portal-read": "PH-15 đọc danh mục cho cổng nhà phát triển",
                                      "catalog:flow-sync": "PH-04 đăng ký API từ luồng và đọc đặc tả đã gộp",
                                      "catalog:metrics-read": "PH-13, PH-16 đọc số liệu tuân thủ và thống kê"}}}},
            },
            "parameters": parameters(),
            "responses": responses(),
            "schemas": sc.S,
        },
    }
    # API nội bộ và danh mục máy dùng token dịch vụ
    for path, item in paths.items():
        for m, op in item.items():
            perm = op["x-datahub-permission"]
            if path.startswith("/internal") or path.startswith("/catalog/") or path == "/usage-stats/summary":
                op["security"] = [{"oauth2Service": []}] if path.startswith("/internal") else [{"oauth2User": []}, {"oauth2Service": []}]
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH02 · OpenAPI PH-02 (dh-connect, module catalog). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=160)
    print(len(spec.OPS), "operation,", len(sc.S), "lược đồ ->", os.path.relpath(OUT))


if __name__ == "__main__":
    main()
