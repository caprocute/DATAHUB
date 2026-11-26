#!/usr/bin/env python3
"""Sinh ph13/openapi-giam-sat-kiem-toan.yaml từ spec.OPS và schemas.SCHEMAS.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph13). YAML sinh ra là hợp đồng; sửa spec.py hoặc schemas.py rồi sinh lại.
"""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from schemas import SCHEMAS, EXAMPLES, R, s, arr, enum, INT, STR, UUID, TS, BOOL

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = lambda n: {"$ref": f"#/components/parameters/{n}"}
RESP = lambda n: {"$ref": f"#/components/responses/{n}"}

# ---- tham số
CODE = lambda mx=63: STR(mx, pattern="^[a-z][a-z0-9-]{2,%d}$" % (mx - 1))
PATHP = {
  "deploymentCode": CODE(), "flowCode": CODE(), "routeId": STR(128), "systemCode": STR(64), "nodeId": STR(64), "setCode": CODE(),
  "logId": STR(128), "traceId": R("TraceId"), "recordId": STR(64), "queryId": UUID, "alertId": UUID, "ruleCode": CODE(), "runbookCode": CODE(),
  "scheduleCode": CODE(), "channelCode": CODE(), "targetCode": CODE(), "reportId": UUID, "tenantCode": R("TenantCode"), "auditId": UUID,
  "objectType": STR(64, pattern="^[a-z][a-z0-9_.-]*$"), "objectId": STR(128), "verificationId": UUID, "anchorId": UUID, "exportId": UUID,
}
QP = {
  "from": (TS, "Đầu khoảng thời gian (ISO 8601, UTC). Thiếu hoặc sai trả ERR-13-004."), "to": (TS, "Cuối khoảng thời gian; vượt giới hạn mỗi lần tra trả ERR-13-005."),
  "step": (STR(8, pattern="^[0-9]+[smhd]$"), "Bước thời gian, ví dụ `1m`, `1h`."),
  "page": (INT(minimum=1, default=1), "Trang, từ 1."), "size": (INT(minimum=1, maximum=200, default=50), "Số dòng mỗi trang, tối đa 200 (ERR-13-038)."),
  "q": (STR(255), "Tìm theo tên hoặc mã, không dấu."), "sort": (STR(64, pattern="^[a-zA-Z]+:(asc|desc)$"), "`trường:asc|desc`."),
  "cursor": (STR(2048), "Con trỏ mờ từ `page.next` của lần trước."),
  "layer": (STR(32), "Lớp thành phần."), "status": (STR(64), "Lọc trạng thái, nhiều giá trị cách nhau dấu phẩy."), "scope": (enum("PLATFORM", "TENANT"), "Luật chuẩn nền tảng hoặc luật của tenant."),
  "severity": (R("Severity"), "Mức độ."), "ruleCode": (STR(63), "Mã luật."), "groupKey": (STR(128), "Nhãn gom nhóm."),
  "api": (STR(64), "Mã API."), "system": (STR(64), "Mã HTTT."), "service": (STR(64), "Tên dịch vụ."), "du": (STR(32), "Mã DU."), "flow": (STR(63), "Mã luồng."),
  "level": (enum("DEBUG", "INFO", "WARN", "ERROR"), "Mức log."), "minDurationMs": (INT(minimum=0), "Thời gian tối thiểu (ms)."), "kind": (STR(16), "Loại."),
  "enabled": (BOOL, "Đang bật."), "actorId": (STR(128), "Mã người hoặc client thao tác."), "before": (INT(minimum=0, maximum=200, default=20), "Số dòng trước."),
  "after": (INT(minimum=0, maximum=200, default=20), "Số dòng sau."), "query": (STR(4096), "Biểu thức lọc log (LogQL rút gọn)."),
}
PARAMS = {f"{k.capitalize()}Path": {"name": k, "in": "path", "required": True, "schema": v} for k, v in PATHP.items()}
PARAMS.update({f"Q_{k}": {"name": k, "in": "query", "schema": v[0], "description": v[1]} for k, v in QP.items()})
PARAMS.update({
  "TargetTenant": {"name": "targetTenant", "in": "query", "schema": R("TenantCode"), "description": "Tenant đích, chỉ dành cho người dùng nền tảng có phiên liên tenant còn hiệu lực (FR-00-012); thiếu phiên trả ERR-13-036."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại; lệch trả ERR-13-007 (412)."},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16), "description": "Lưu 24 giờ; cùng khóa khác nội dung trả ERR-13-037."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
})
pname = lambda k: f"{k.capitalize()}Path"

ERR = {  # HTTP → (mã mặc định, mô tả)
  400: ("BadRequest", 3, "Dữ liệu không hợp lệ theo lược đồ hoặc tham số ngoài miền; mã cụ thể trong `code` (ERR-13-003, 004, 006, 008, 038)."),
  401: ("Unauthorized", 10, "Thiếu token hoặc phiên hết hạn (ERR-13-010)."),
  403: ("Forbidden", 9, "Không đủ quyền hoặc cần xác thực lại, hoặc truy cập tenant khác (ERR-13-009, 019, 028, 036, 044)."),
  404: ("NotFound", 1, "Không tìm thấy hoặc thuộc tenant khác, không phân biệt (ERR-13-001, 030)."),
  409: ("Conflict", 2, "Xung đột mã hoặc trạng thái (ERR-13-002, 020, 025, 032, 037, 042, 043)."),
  410: ("Gone", 27, "Tệp bằng chứng đã hết hạn tải (ERR-13-027)."),
  412: ("PreconditionFailed", 7, "ETag không khớp; kèm `currentEtag` (ERR-13-007)."),
  422: ("Unprocessable", 5, "Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-13-005, 012, 013, 017, 018, 021…024, 029, 031, 033…035, 039…041)."),
  423: ("Locked", 16, "Tenant đang tạm ngừng, chỉ đọc (ERR-13-016)."),
  429: ("TooManyRequests", 11, "Quá nhiều truy vấn đồng thời; kèm `retryAfterSeconds` (ERR-13-011)."),
  503: ("ServiceUnavailable", 14, "Phụ thuộc không khả dụng hoặc không ký số được (ERR-13-014, 026)."),
  504: ("GatewayTimeout", 15, "Truy vấn quá thời gian chờ (ERR-13-015)."),
}
ERRNAME = {h: v[0] for h, v in ERR.items()}
RESPONSES = {v[0]: {"description": v[2], "content": {"application/problem+json": {"schema": R("ProblemDetails"),
    "example": {"type": f"https://datahub.gov.vn/errors/ERR-13-{v[1]:03d}", "title": v[2].split(";")[0].split("(")[0].strip().rstrip("."), "status": h,
                "code": f"ERR-13-{v[1]:03d}", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}} for h, v in ERR.items()}

IFM_EXCL = {"018", "029", "039", "051", "064"}
NO_423 = {"019", "025", "039", "051", "064", "067", "074", "089", "090", "072", "073", "077", "082"}  # đọc, hoặc nền tảng, hoặc phải chạy khi tenant tạm ngừng
RESP_HDR_ETAG_SKIP = {"021", "084", "090", "029", "066"}
SSE, ZIP = {"021"}, {"084"}

def perm_info(perm):
    if perm.startswith("svc:"):
        return {"serviceScope": perm[4:]}
    if perm == "mtls":
        return {"mtls": "Chứng thư client của Alertmanager (SPIFFE ID), không phải người dùng"}
    if "|" in perm:
        return {"anyOf": [f"PERM-13-{p}" for p in perm.split("|")]}
    return {"permission": f"PERM-13-{perm}"}

def frs(fr):
    out = []
    for p in fr.split(","):
        p = p.strip()
        out.append(f"FR-13-{p}")
    return out

def build():
    paths, tags_used = {}, []
    for (code, method, path, summary, fr, perm, idem, success, group, opid, body, resp, errs, extra, desc) in spec.OPS:
        base, tag = spec.GROUPS[group]
        full = spec.BASES[base] + path
        m = method.lower()
        op = {"tags": [tag], "operationId": opid, "summary": summary, "x-datahub-id": f"API-13-{code}", "x-datahub-fr": frs(fr)}
        pi = perm_info(perm)
        if code == "002": pi = {"permission": "PERM-13-dashboard", "serviceScope": "obs:health-read"}
        op["x-datahub-permission"] = pi
        if "serviceScope" in pi and code != "002": op["security"] = [{"oauth2Service": [pi["serviceScope"]]}]
        if code == "002": op["security"] = [{"oauth2User": []}, {"oauth2Service": ["obs:health-read"]}]
        if perm == "mtls": op["security"] = [{"mtlsAlertmanager": []}]
        d = (desc + " ") if desc else ""
        if "serviceScope" in pi and code != "002": d = f"Token dịch vụ, scope `{pi['serviceScope']}`. " + d
        if perm == "mtls": d = "Chỉ Alertmanager gọi, xác thực mTLS. " + d
        if tag not in tags_used: tags_used.append(tag)
        human = perm not in ("mtls",) and not perm.startswith("svc:")
        # tham số
        params = [P(pname(n)) for n in re.findall(r"\{(\w+)\}", path)]
        qn = list(extra)
        for n in qn: params.append(P(f"Q_{n}"))
        has_tt = (m == "get" and human and group in ("dash", "logs", "aud", "ver") and perm != "admin") or code in ("019", "025", "074")
        if has_tt and code not in ("019", "025", "074"): params.append(P("TargetTenant"))
        mutating_ifm = (m in ("put", "patch", "delete") or (m == "post" and re.search(r"\}:[a-z-]+$", path))) and code not in IFM_EXCL
        if mutating_ifm: params.append(P("IfMatch"))
        if idem: params.append(P("IdempotencyKey"))
        params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = params
        # mã lỗi riêng
        e = {int(x) for x in errs.replace(" ", "").split(",") if x}
        e.add(10)
        if human: e.add(9)
        if "{" in path: e.add(1)
        if "size" in qn: e.add(38)
        if body or qn: e.add(3)
        if m != "get" and human and code not in NO_423: e.add(16)
        if mutating_ifm: e.add(7)
        if idem: e.add(37)
        if has_tt: e.add(36)
        if code in ("090",): e.discard(10)
        op["x-datahub-errors"] = [f"ERR-13-{n:03d}" for n in sorted(e)]
        if idem: op["x-datahub-idempotent"] = True
        if d.strip(): op["description"] = d.strip()
        # thân yêu cầu
        if body:
            ct = {"application/json": {"schema": R(body)}}
            op["requestBody"] = {"required": True, "content": ct}
        # phản hồi
        okr = {"description": "Thành công."}
        if code in SSE: okr["content"] = {"text/event-stream": {"schema": R(resp)}}
        elif code in ZIP:
            okr["content"] = {"application/zip": {"schema": {"type": "string", "contentEncoding": "binary"}}}
            okr["headers"] = {"Content-Disposition": {"schema": STR()}, "X-Evidence-Signature": {"schema": STR(), "description": "Chữ ký số của tệp (base64)."}}
        elif code == "066": okr["content"] = {"application/json": {"schema": R(resp)}, "application/pdf": {"schema": {"type": "string", "contentEncoding": "binary"}}}
        elif resp and success != "204": okr["content"] = {"application/json": {"schema": R(resp)}}
        hdr = okr.get("headers", {})
        if m == "get" and resp and code not in RESP_HDR_ETAG_SKIP: hdr["ETag"] = {"schema": STR()}
        if success == "202": hdr["Location"] = {"schema": STR(), "description": "Tài nguyên theo dõi tiến trình."}
        if success == "201": hdr["Location"] = {"schema": STR()}; hdr["ETag"] = {"schema": STR()}
        if hdr: okr["headers"] = hdr
        resps = {success: okr}
        for n in sorted(e):
            h = spec.ERR_HTTP[n]; resps[str(h)] = RESP(ERRNAME[h])
        op["responses"] = dict(sorted(resps.items()))
        paths.setdefault(full, {})[m] = op
    # ví dụ thân yêu cầu cho các lược đồ có ví dụ
    schemas = {k: dict(v) for k, v in SCHEMAS.items()}
    for k, ex in EXAMPLES.items():
        assert k in schemas, k
        schemas[k]["examples"] = ex
    return {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-13 Giám sát và kiểm toán API", "version": "1.0.0-draft",
               "summary": "Bảng điều khiển, log, trace, cảnh báo, phát hiện bất thường an ninh, SIEM; tra cứu, xác minh toàn vẹn, xuất bằng chứng kiểm toán; vòng đời tenant.",
               "description": ("API của hai module `observability` và `audit` trong `dh-platform` (control plane PH-13), chia ba nhóm đường gốc: "
                   "`/api/observability/v1` (quan sát), `/api/audit/v1` (kiểm toán), `/api/platform/v1` (vòng đời tenant do PH-20 gọi). "
                   "Người dùng gọi qua BFF console (Authorization Code + PKCE); phân hệ khác và DU gọi bằng token dịch vụ (client credentials) với scope riêng; "
                   "Alertmanager gọi webhook bằng mTLS.\n\nQuy ước (D03-04-PH13 §1): tenant lấy từ token (`targetTenant` chỉ cho phiên liên tenant có lý do); "
                   "tạo mới nhận `Idempotency-Key`; sửa và đổi trạng thái bắt buộc `If-Match`; hậu tố `:{hành-động}`; phân trang `page`/`size` (≤ 200) hoặc con trỏ `cursor`; "
                   "lỗi RFC 9457 mã `ERR-13-nnn`. Không API nào ghi, sửa, xóa bản ghi kiểm toán qua đường người dùng; chỉ có đường ghi dự phòng của DU (API-13-089). "
                   "Không API nào trả bí mật (kênh thông báo, SIEM chỉ ghi một chiều). Dữ liệu ví dụ là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-13"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH13", "x-datahub-phase": "PH-13"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn", "description": "Qua BFF console của tenant — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
                  {"url": "http://dh-platform.dh-control.svc:8080", "description": "Trong cụm, cho PH-16, PH-18, PH-20, DU nguồn và Alertmanager"},
                  {"url": "http://localhost:8082", "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": t} for t in tags_used],
      "paths": paths,
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-13-* (D02-08). Thao tác nhạy cảm cần xác thực lại phiên (step-up, ERR-13-028).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Token dịch vụ cấp khi triển khai, không cấp cho người hay cho HTTT thành viên.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"audit:write": "DU nguồn ghi bản ghi kiểm toán dự phòng", "audit:history-read": "BFF của DU lấy lịch sử đối tượng",
                           "obs:metrics-read": "PH-16 truy vấn số liệu tổng hợp", "obs:diagnostics-read": "PH-18 lấy ngữ cảnh chẩn đoán",
                           "obs:health-read": "Phân hệ khác đọc sức khỏe thành phần", "obs:tenant-provision": "PH-20 khởi tạo và đóng chuỗi kiểm toán theo tenant"}}}},
          "mtlsAlertmanager": {"type": "mutualTLS", "description": "Alertmanager gọi webhook bằng chứng thư client do cert-manager cấp; PH-13 kiểm SPIFFE ID (SEC-15)."}},
        "parameters": PARAMS, "responses": RESPONSES, "schemas": schemas}}

if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-giam-sat-kiem-toan.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH13 · OpenAPI PH-13 (dh-platform, module observability và audit). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(len(v) for v in doc["paths"].values())
    print(f"{n} operation, {len(SCHEMAS)} lược đồ → {out}")
