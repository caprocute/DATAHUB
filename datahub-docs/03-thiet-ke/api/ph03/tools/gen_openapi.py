#!/usr/bin/env python3
"""Sinh ph03/openapi-gateway.yaml (OpenAPI 3.1) từ spec.OPS và các lược đồ trong tệp này.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph03)
YAML sinh ra là hợp đồng; sửa spec.py hoặc tệp này rồi sinh lại, không sửa tay YAML.
"""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
P = lambda n: {"$ref": f"#/components/parameters/{n}"}
RESP = lambda n: {"$ref": f"#/components/responses/{n}"}


def s(t, **kw):
    d = {"type": t}; d.update(kw); return d
def obj(props, req=(), desc=None, **kw):
    d = {"type": "object", "properties": props, "additionalProperties": False}
    if req: d["required"] = list(req)
    if desc: d["description"] = desc
    d.update(kw); return d
def arr(items, **kw):
    d = {"type": "array", "items": items}; d.update(kw); return d
def enum(*v, desc=None):
    d = {"type": "string", "enum": list(v)}
    if desc: d["description"] = desc
    return d
def ienum(*v):
    return {"type": "integer", "enum": list(v)}
def allow(*schemas):
    return {"allOf": list(schemas) + [R("AllowedActions")]}
def page(item):
    return obj({"items": arr(R(item)), "page": INT(minimum=1), "size": INT(minimum=1, maximum=100), "totalElements": INT(minimum=0)},
               req=["items", "page", "size", "totalElements"])

STR = lambda mx=None, **kw: s("string", **({"maxLength": mx} if mx else {}), **kw)
INT = lambda **kw: s("integer", **kw)
NUM = s("number")
BOOL = s("boolean")
TS = s("string", format="date-time")
UUID = s("string", format="uuid")
ANYOBJ = {"type": "object", "additionalProperties": True}
CNT = {"type": "object", "additionalProperties": INT()}
SERIES = arr(obj({"name": STR(64), "points": arr(arr(NUM, minItems=2, maxItems=2), description="[mốc giây epoch, giá trị]")}, req=["name", "points"]))

SCHEMAS = {
  # ---- chung
  "RouteCode": STR(127, pattern="^[a-z][a-z0-9.-]{2,126}$", description="Mã route = mã API ở PH-02 kèm phiên bản, bất biến, không dùng lại (BR-03-026). Ví dụ `tra-cuu-ho-tich.v1`."),
  "UpstreamCode": STR(63, pattern="^[a-z][a-z0-9.-]{2,62}$"),
  "ConsumerCode": STR(63, pattern="^[a-z][a-z0-9-]{2,62}$", description="Trùng `clientId` ở Keycloak (BR-03-022)."),
  "SystemCode": STR(64, description="Mã HTTT ở PH-01."),
  "Sha256Hex": STR(64, pattern="^[0-9a-f]{64}$"),
  "TenantCode": STR(16, pattern="^(T[0-9]{2}|COMMON)$"),
  "Cidr": STR(43, description="Địa chỉ hoặc dải CIDR IPv4, IPv6."),
  "Reason": STR(500, minLength=10, description="Lý do 10…500 ký tự."),
  "Exposure": enum("INT", "EXT", desc="`INT` chỉ nạp ở `apisix-int`; `EXT` nạp thêm ở `apisix-ext` sau khi SO duyệt (BR-03-015)."),
  "RouteState": enum("PENDING", "ACTIVE", "STOPPED", "SUSPENDED", "SUNSET", "RETIRED"),
  "PriorityGroup": enum("ESSENTIAL", "NORMAL", "LOW"),
  "ConsumerState": enum("ACTIVE", "SUSPENDED"),
  "AuthMethod": enum("OAUTH2", "MTLS", "API_KEY"),
  "SecurityMode": enum("KEYLESS", "API_KEY", "OAUTH2", "MTLS"),
  "SyncState": enum("PENDING", "IN_SYNC", "PARTIAL", "FAILED"),
  "WafModeValue": enum("DETECT", "BLOCK"),
  "Period": enum("HOUR", "DAY", "MONTH"),
  "Severity": enum("MEDIUM", "HIGH", "CRITICAL"),
  "AllowedActions": obj({
      "allowedActions": arr(STR(), description="Hành động người gọi được làm ngay bây giờ."),
      "disabledReasons": {"type": "object", "additionalProperties": STR(), "description": "Hành động có quyền nhưng trạng thái chưa cho phép, kèm lý do tiếng Việt."}}),
  "Finding": obj({"checkId": STR(16, pattern="^CHK-[0-9]{2}$"), "severity": enum("ERROR", "WARNING"), "objectType": STR(32), "objectCode": STR(127),
      "message": STR(500)}, req=["checkId", "severity", "message"]),
  "FieldError": obj({"field": STR(), "rule": STR(), "message": STR(), "max": INT(), "min": INT()}, req=["field"]),
  "ProblemDetails": {
      "type": "object", "description": "RFC 9457 `application/problem+json`, mở rộng theo D03-04-PH03 §1. Mã `ERR-03-001…027` (control plane).",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {
          "type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(), "instance": STR(),
          "code": STR(pattern="^ERR-03-0[0-9]{2}$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(R("FieldError")), "findings": arr(R("Finding"), description="Kèm ERR-03-005, 012, 013."),
          "currentEtag": STR(description="Kèm ERR-03-004."), "retryAfterSeconds": INT(),
          "ceiling": INT(description="Kèm ERR-03-018: trần cho phép."), "ruleId": STR(description="Kèm ERR-03-010."),
          "existingExpiresAt": TS, "activeSubscriptions": INT(description="Kèm ERR-03-017."),
          "detectDays": INT(description="Kèm ERR-03-027: số ngày đã chạy phát hiện."), "requiredDays": INT()},
      "additionalProperties": True},
  "GenericProblem": {"type": "object", "description": "Lỗi do lớp hạ tầng của `dh-connect` trả (401 xác thực, 500 nội bộ), chưa tới lớp nghiệp vụ nên chưa có mã ERR-03 (Q03-55).",
      "required": ["type", "title", "status", "traceId"],
      "properties": {"type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(), "traceId": STR(pattern="^[0-9a-f]{32}$")}, "additionalProperties": True},
  "GatewayProblem": {"type": "object", "description": "Thân RFC 9457 mà APISIX trả cho bên gọi API qua cổng (`ERR-03-101…130`), dựng bởi plugin `dh-problem`. Không phải phản hồi của API này, đưa vào đây để bên gọi và kiểm thử có một lược đồ.",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {"type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(), "instance": STR(),
          "code": STR(pattern="^ERR-03-1[0-3][0-9]$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(R("FieldError")), "retryAfterSeconds": INT(),
          "rateLimit": obj({"window": STR(8), "limit": INT(), "remaining": INT(), "resetAt": TS})}, "additionalProperties": True},
  # ---- route, upstream
  "RouteSummary": allow(obj({
      "routeCode": R("RouteCode"), "apiCode": STR(100), "apiVersion": STR(16), "hostPattern": STR(255), "pathPattern": STR(500),
      "methods": arr(STR(10)), "exposure": R("Exposure"), "state": R("RouteState"), "upstreamCode": R("UpstreamCode"), "policySetCode": STR(64),
      "securityMode": R("SecurityMode"), "requiredScopes": arr(STR(100)), "requireMtls": BOOL, "deprecatedAt": TS, "sunsetAt": TS,
      "snapshotVersion": INT(description="Ảnh chụp mới nhất có chứa route."), "updatedAt": TS, "version": INT()},
      req=["routeCode", "apiCode", "apiVersion", "exposure", "state"])),
  "RouteDetail": {"allOf": [R("RouteSummary"), obj({
      "priority": INT(), "bodyMaxBytes": INT(minimum=1024, maximum=10485760), "requestLimits": R("RequestLimits"), "timeouts": R("TimeoutsUpdate"),
      "protocols": arr(enum("HTTP", "HTTPS", "WEBSOCKET", "GRPC")), "corsEnabled": BOOL, "wafParanoia": INT(minimum=1, maximum=3),
      "ipAllowCidrs": arr(R("Cidr")), "successorRoute": R("RouteCode"), "stateReason": STR(500), "stateChangedBy": STR(64), "stateChangedAt": TS,
      "rateLimits": arr(R("RateLimitRule")), "quotas": arr(R("QuotaRule")), "pathAllow": arr(STR(500)), "pathDeny": arr(STR(500)),
      "policyPackage": STR(128, description="Gói chính sách OPA gắn với route."),
      "impact": R("ImpactEstimate"),
      "eligibility": arr(obj({"code": STR(32), "met": BOOL, "reason": STR(300)}, req=["code", "met"]),
          description="Danh sách điều kiện mở route ra cửa Internet (FR-03-038), đạt hoặc chưa; chỉ trả khi gọi với `eligibility=true`.")})]},
  "ImpactEstimate": obj({"consumersLast15m": INT(), "routesAffected": INT(), "evaluatedAt": TS},
      desc="Ước lượng hậu quả của thao tác dừng, tạm ngừng hoặc gỡ để giao diện nêu bằng số trước khi xác nhận; lấy từ PH-13, không có thì bỏ trường."),
  "RoutePage": page("RouteSummary"),
  "RateLimitRule": obj({"windowSeconds": INT(minimum=1), "limit": INT(minimum=1), "burst": INT(minimum=0)}, req=["windowSeconds", "limit"]),
  "QuotaRule": obj({"period": R("Period"), "limit": INT(minimum=1)}, req=["period", "limit"]),
  "RouteStopRequest": obj({"reason": STR(300, minLength=10), "message": STR(500, description="Câu hiển thị cho bên gọi trong `detail` của ERR-03-123.")}, req=["reason"]),
  "ReasonRequest": obj({"reason": R("Reason")}, req=["reason"]),
  "OptionalReason": obj({"reason": R("Reason")}),
  "RouteVersionList": obj({"items": arr(obj({"routeCode": R("RouteCode"), "apiVersion": STR(16), "state": R("RouteState"), "deprecatedAt": TS, "sunsetAt": TS,
      "successorRoute": R("RouteCode"), "callsLast7d": INT()}, req=["routeCode", "apiVersion", "state"]))}, req=["items"]),
  "ExposureUpdate": obj({"exposure": R("Exposure"), "reason": R("Reason"), "wafParanoia": INT(minimum=1, maximum=3),
      "ipAllowCidrs": arr(R("Cidr"), maxItems=50)}, req=["exposure", "reason"],
      desc="Đặt `EXT` tạo yêu cầu thay đổi chờ SO duyệt (trả 202); đặt `INT` có hiệu lực ngay (200)."),
  "RequestLimits": obj({"bodyMaxBytes": INT(minimum=1024, maximum=10485760), "jsonMaxDepth": INT(minimum=8, maximum=64),
      "jsonMaxArrayItems": INT(minimum=100, maximum=100000), "schemaValidation": BOOL}),
  "TimeoutsUpdate": obj({"connectMs": INT(minimum=100, maximum=30000), "readMs": INT(minimum=100, maximum=30000), "sendMs": INT(minimum=100, maximum=30000),
      "breaker": obj({"failures": INT(minimum=2, maximum=50), "openSeconds": INT(minimum=5, maximum=60), "halfOpenProbes": INT(minimum=1, maximum=5),
                      "unhealthyStatuses": arr(INT(minimum=500, maximum=599))})}),
  "UpstreamNode": obj({"address": STR(255), "port": INT(minimum=1, maximum=65535), "weight": INT(minimum=1), "health": enum("HEALTHY", "UNHEALTHY", "UNKNOWN")}, req=["address", "port"]),
  "UpstreamSummary": obj({"upstreamCode": R("UpstreamCode"), "scheme": enum("http", "https", "grpc"), "balancer": enum("roundrobin", "chash"),
      "nodeCount": INT(), "healthyCount": INT(), "routeCount": INT(), "tlsVerify": BOOL, "version": INT()}, req=["upstreamCode", "scheme"]),
  "UpstreamDetail": {"allOf": [R("UpstreamSummary"), obj({"nodes": arr(R("UpstreamNode")), "retries": INT(minimum=0, maximum=3),
      "healthCheck": obj({"active": obj({"path": STR(255), "intervalSeconds": INT(), "timeoutMs": INT(), "healthyStatuses": arr(INT())}),
          "passive": obj({"failThreshold": INT(), "successThreshold": INT(), "unhealthyStatuses": arr(INT())})}),
      "timeouts": R("TimeoutsUpdate"), "routes": arr(R("RouteCode"))})]},
  "UpstreamPage": page("UpstreamSummary"),
  # ---- consumer
  "ConsumerSummary": allow(obj({
      "consumerCode": R("ConsumerCode"), "systemCode": R("SystemCode"), "priorityGroup": R("PriorityGroup"), "trustedSource": BOOL,
      "authMethod": R("AuthMethod"), "state": R("ConsumerState"), "syncState": R("SyncState"), "certNotAfter": TS, "apiKeyNotAfter": TS,
      "subscriptionCount": INT(), "updatedAt": TS, "version": INT()}, req=["consumerCode", "systemCode", "state", "authMethod"])),
  "ConsumerDetail": {"allOf": [R("ConsumerSummary"), obj({"impact": R("ImpactEstimate"),
      "subscriptions": arr(obj({"apiCode": STR(100), "planCode": STR(64), "state": STR(16), "validFrom": TS, "validTo": TS}, req=["apiCode", "state"]),
          description="Đăng ký sử dụng của consumer (API, gói, hiệu lực) lấy từ bản chiếu PH-02, để tab Đăng ký ở UI-03-05."),
      "emergencyBlock": obj({"blockId": UUID, "reason": STR(500), "createdBy": STR(64), "createdAt": TS}),
      "lastSyncedSnapshot": INT(), "createdAt": TS})]},
  "ConsumerPage": page("ConsumerSummary"),
  "ConsumerUpsert": obj({"systemCode": R("SystemCode"), "state": R("ConsumerState"), "priorityGroup": R("PriorityGroup"),
      "trustedSource": BOOL, "authMethod": R("AuthMethod"),
      "certThumbprints": arr(R("Sha256Hex"), maxItems=2, description="Vân tay SHA-256 chứng thư khách, khi `MTLS`."), "certNotAfter": TS,
      "apiKeyHash": R("Sha256Hex"), "apiKeyNotAfter": TS},
      req=["systemCode", "state", "authMethod"],
      desc="Không có trường bí mật: `SecretFieldGuard` từ chối khóa riêng, `client_secret`, khóa API dạng rõ bằng ERR-03-003 (FR-03-046 bước 4)."),
  "CredentialsUpsert": obj({"authMethod": R("AuthMethod"), "certThumbprints": arr(R("Sha256Hex"), maxItems=2), "certNotAfter": TS,
      "apiKeyHash": R("Sha256Hex"), "apiKeyNotAfter": TS}, req=["authMethod"]),
  "CredentialsPublic": obj({"consumerCode": R("ConsumerCode"), "authMethod": R("AuthMethod"),
      "certThumbprints": arr(STR(20, description="Băm cắt ngắn: 16 ký tự đầu cộng dấu chấm lửng.")), "certNotAfter": TS, "certDaysLeft": INT(),
      "apiKeyFingerprint": STR(8, description="8 ký tự đầu của băm; không bao giờ trả khóa."), "apiKeyNotAfter": TS, "version": INT()},
      req=["consumerCode", "authMethod"]),
  # ---- chính sách chiếu từ gói
  "PlanPolicy": obj({"policyCode": STR(64), "planCode": STR(64), "apiCode": STR(100), "securityMode": R("SecurityMode"),
      "rateLimits": arr(R("RateLimitRule")), "quotas": arr(R("QuotaRule")), "pathAllow": arr(STR(500)), "pathDeny": arr(STR(500)),
      "subscriptionCount": INT(), "sourceUpdatedAt": TS, "version": INT()}, req=["policyCode", "planCode", "securityMode"]),
  "PlanPolicyPage": page("PlanPolicy"),
  # ---- hạn mức
  "TenantLimits": obj({"limitPerSecond": INT(minimum=10), "burst": INT(minimum=0), "warnPercent": INT(minimum=50, maximum=95), "ceiling": INT(description="Trần theo hợp đồng (PH-20)."),
      "pendingChangeRequestId": UUID, "updatedAt": TS, "version": INT()}, req=["limitPerSecond", "ceiling", "version"]),
  "TenantLimitsUpdate": obj({"limitPerSecond": INT(minimum=10), "burst": INT(minimum=0), "warnPercent": INT(minimum=50, maximum=95), "reason": R("Reason")},
      req=["limitPerSecond", "reason"], desc="Tăng có hiệu lực ngay (200); hạ cần bốn mắt, tạo yêu cầu thay đổi (202)."),
  "RateLimitOverride": obj({"overrideId": UUID, "scope": enum("CONSUMER_ROUTE", "ROUTE", "CONSUMER"), "consumerCode": R("ConsumerCode"), "routeCode": R("RouteCode"),
      "limit": INT(minimum=1), "windowSeconds": ienum(1, 60, 3600), "burst": INT(minimum=0), "validTo": TS, "reason": STR(500), "createdBy": STR(64), "createdAt": TS, "version": INT()},
      req=["overrideId", "scope", "limit", "windowSeconds"]),
  "RateLimitOverrideWrite": obj({"scope": enum("CONSUMER_ROUTE", "ROUTE", "CONSUMER"), "consumerCode": R("ConsumerCode"), "routeCode": R("RouteCode"),
      "limit": INT(minimum=1), "windowSeconds": ienum(1, 60, 3600), "burst": INT(minimum=0), "validTo": TS, "reason": R("Reason")},
      req=["scope", "limit", "windowSeconds", "reason"], desc="`consumerCode` bắt buộc khi scope có consumer, `routeCode` khi scope có route; `validTo` tối đa 365 ngày."),
  "RateLimitOverridePage": page("RateLimitOverride"),
  "ConsumerUsage": obj({"consumerCode": R("ConsumerCode"), "evaluatedAt": TS, "degraded": BOOL,
      "rates": arr(obj({"routeCode": R("RouteCode"), "windowSeconds": INT(), "limit": INT(), "used": INT(), "source": enum("PLAN", "OVERRIDE", "TENANT")}, req=["routeCode", "windowSeconds", "limit"])),
      "quotas": arr(obj({"routeCode": R("RouteCode"), "period": R("Period"), "limit": INT(), "used": INT(), "percent": NUM, "resetAt": TS}, req=["routeCode", "period", "limit"]))},
      req=["consumerCode", "rates", "quotas"]),
  "QuotaAlert": obj({"consumerCode": R("ConsumerCode"), "routeCode": R("RouteCode"), "period": R("Period"), "percent": ienum(80, 100), "limit": INT(), "used": INT(),
      "raisedAt": TS, "resetAt": TS}, req=["consumerCode", "routeCode", "period", "percent"]),
  "QuotaAlertPage": page("QuotaAlert"),
  # ---- lớp biên
  "TlsProfile": obj({"gates": arr(obj({"gate": enum("EXT", "INT"), "minVersion": enum("TLSv1.2", "TLSv1.3"), "ciphers": arr(STR(64)), "alpn": arr(STR(16)),
      "hsts": BOOL, "ocspStapling": BOOL, "ipv6": BOOL, "mtlsMode": enum("OFF", "OPTIONAL", "REQUIRED")}, req=["gate", "minVersion"])),
      "activeExceptions": INT()}, req=["gates"]),
  "TlsException": obj({"exceptionId": UUID, "hostPattern": STR(255), "minVersion": enum("TLSv1.2"), "reason": STR(500), "expiresAt": TS,
      "state": enum("ACTIVE", "EXPIRED", "REVOKED"), "createdBy": STR(64), "createdAt": TS, "version": INT()}, req=["exceptionId", "hostPattern", "state", "expiresAt"]),
  "TlsExceptionCreate": obj({"hostPattern": STR(255), "reason": R("Reason"), "expiresAt": TS}, req=["hostPattern", "reason", "expiresAt"],
      desc="`expiresAt` tối đa `gw.tls.exceptionMaxDays` (180 ngày) kể từ nay."),
  "TlsExceptionPage": page("TlsException"),
  "ClientCaBundle": obj({"items": arr(obj({"caCode": STR(64), "subject": STR(500), "source": enum("DATAHUB_PKI", "TENANT_CA"), "notAfter": TS,
      "crlUpdatedAt": TS, "crlAgeHours": INT()}, req=["caCode", "source"]))}, req=["items"]),
  "IpBlock": obj({"blockId": UUID, "cidr": R("Cidr"), "source": enum("AUTO", "MANUAL"), "reason": STR(500), "createdBy": STR(64), "createdAt": TS, "expiresAt": TS},
      req=["blockId", "cidr", "source", "expiresAt"]),
  "IpBlockCreate": obj({"cidr": R("Cidr"), "durationMinutes": INT(minimum=1, maximum=10080), "reason": R("Reason")}, req=["cidr", "durationMinutes", "reason"],
      desc="Dải không rộng hơn /24 (IPv4) hoặc /56 (IPv6); địa chỉ tin cậy hoặc hạ tầng bị từ chối (ERR-03-024)."),
  "IpBlockPage": page("IpBlock"),
  # ---- WAF
  "WafEvent": obj({"eventId": STR(32), "ts": TS, "routeCode": R("RouteCode"), "ruleId": STR(6, pattern="^9[0-9]{5}$"), "ruleMessage": STR(500),
      "severity": STR(16), "anomalyScore": INT(), "mode": R("WafModeValue"), "action": enum("LOGGED", "BLOCKED"), "consumerCode": R("ConsumerCode"),
      "srcIp": STR(45, description="Chỉ trả khi người gọi có `PERM-03-waf-request`."), "traceId": STR(32), "exceptionId": UUID},
      req=["eventId", "ts", "ruleId", "action"], desc="Không chứa nội dung yêu cầu; chỉ mã luật, điểm và siêu dữ liệu (BR-03-007)."),
  "WafEventPage": page("WafEvent"),
  "WafModeInfo": obj({"scopes": arr(obj({"scope": STR(127, description="`TENANT` hoặc mã route."), "mode": R("WafModeValue"), "detectSince": TS, "detectDays": INT(),
      "autoDegradedAt": TS}, req=["scope", "mode"])),
      "eligibleForBlock": obj({"eligible": BOOL, "detectDays": INT(), "requiredDays": INT(), "openFalsePositives": INT(), "maxFalsePositives": INT()}, req=["eligible"]),
      "paranoia": obj({"ui": INT(minimum=1, maximum=3), "api": INT(minimum=1, maximum=3)}), "anomalyThreshold": INT(), "version": INT()}, req=["scopes", "eligibleForBlock"]),
  "WafModeUpdate": obj({"mode": R("WafModeValue"), "scope": STR(127, description="`TENANT` hoặc mã route."), "reason": R("Reason")}, req=["mode", "scope", "reason"],
      desc="Chuyển giữa `DETECT` và `BLOCK` cần bốn mắt: trả 202 kèm yêu cầu thay đổi. Sang `BLOCK` ở PROD phải đủ 14 ngày phát hiện (ERR-03-027)."),
  "WafException": obj({"exceptionId": UUID, "routeCode": R("RouteCode"), "ruleId": STR(6, pattern="^9[0-9]{5}$"), "reason": STR(1000),
      "state": enum("REQUESTED", "ACTIVE", "EXPIRING", "REJECTED", "EXPIRED", "REVOKED"), "requestedBy": STR(64), "approvedBy": STR(64), "decidedAt": TS,
      "decisionComment": STR(1000), "expiresAt": TS, "evidenceEventId": STR(32), "appliedSnapshotVersion": INT(), "createdAt": TS, "version": INT()},
      req=["exceptionId", "routeCode", "ruleId", "state", "expiresAt"]),
  "WafExceptionCreate": obj({"routeCode": R("RouteCode"), "ruleId": STR(6, pattern="^9[0-9]{5}$"), "reason": STR(1000, minLength=20), "expiresAt": TS,
      "evidenceEventId": STR(32)}, req=["routeCode", "ruleId", "reason", "expiresAt"], desc="`expiresAt` sau thời điểm hiện tại, tối đa 90 ngày."),
  "WafExceptionPage": page("WafException"),
  "ApprovalDecision": obj({"comment": STR(1000)}),
  "VirtualPatch": obj({"patchId": UUID, "ruleText": STR(4096), "appliesTo": enum("TENANT", "ROUTE"), "routeCodes": arr(R("RouteCode")), "reason": STR(1000),
      "reference": STR(64), "state": enum("ACTIVE", "RETIRED", "EXPIRED"), "expiresAt": TS, "createdBy": STR(64), "createdAt": TS, "version": INT()},
      req=["patchId", "ruleText", "state", "expiresAt"]),
  "VirtualPatchCreate": obj({"ruleText": STR(4096, description="Cú pháp SecLang."), "appliesTo": enum("TENANT", "ROUTE"), "routeCodes": arr(R("RouteCode")),
      "reason": R("Reason"), "reference": STR(64, description="Mã CVE hoặc số cảnh báo."), "expiresAt": TS}, req=["ruleText", "appliesTo", "reason", "expiresAt"]),
  "VirtualPatchPage": page("VirtualPatch"),
  # ---- CORS
  "CorsPolicy": obj({"routeCode": R("RouteCode"), "allowedOrigins": arr(STR(255, pattern="^https?://[^*]+$"), maxItems=20, description="Không dùng ký tự đại diện `*` (BR-03-012)."),
      "allowedMethods": arr(STR(10)), "allowedHeaders": arr(STR(100)), "exposedHeaders": arr(STR(100)), "allowCredentials": BOOL, "maxAgeSeconds": INT(minimum=0, maximum=86400),
      "version": INT()}, req=["routeCode", "allowedOrigins"]),
  "CorsPolicyWrite": obj({"allowedOrigins": arr(STR(255, pattern="^https?://[^*]+$"), minItems=1, maxItems=20), "allowedMethods": arr(STR(10)), "allowedHeaders": arr(STR(100)),
      "exposedHeaders": arr(STR(100)), "allowCredentials": BOOL, "maxAgeSeconds": INT(minimum=0, maximum=86400, default=600)}, req=["allowedOrigins"]),
  "CorsPolicyPage": page("CorsPolicy"),
  # ---- xác thực, thu hồi, ủy quyền
  "JwksStatus": obj({"realm": STR(64), "maxStaleHours": INT(), "nodes": arr(obj({"nodeId": STR(64), "gate": enum("EXT", "INT"), "jwksAgeSeconds": INT(), "kidCount": INT(),
      "lastRefreshAt": TS, "state": enum("OK", "STALE", "EXPIRED")}, req=["nodeId", "state"]))}, req=["nodes"]),
  "RevocationCreate": obj({"kind": enum("JTI", "SUBJECT"), "jti": STR(128), "sub": STR(128), "notBefore": TS, "tokenExpiresAt": TS, "reason": R("Reason")},
      req=["kind", "tokenExpiresAt", "reason"], desc="`JTI` cần `jti`; `SUBJECT` cần `sub` (và `notBefore`, mặc định thời điểm gọi). Hiệu lực ≤ 60 giây (SEC-25)."),
  "Revocation": obj({"revocationId": UUID, "kind": enum("JTI", "SUBJECT"), "jti": STR(128), "sub": STR(128), "notBefore": TS, "tokenExpiresAt": TS, "reason": STR(500),
      "createdBy": STR(64), "createdAt": TS, "expiresAt": TS, "propagatedAt": TS}, req=["revocationId", "kind", "tokenExpiresAt"]),
  "RevocationPage": page("Revocation"),
  "AuthorizationBinding": obj({"routeCode": R("RouteCode"), "policyPath": STR(255), "policyBundleVersion": STR(64), "apiClassification": STR(32), "requiresPurpose": BOOL},
      req=["routeCode", "policyPath"]),
  "AuthorizationBindingPage": page("AuthorizationBinding"),
  # ---- ảnh chụp cấu hình
  "Snapshot": obj({"snapshotVersion": INT(minimum=1), "site": STR(16), "scope": R("TenantCode"),
      "state": enum("BUILT", "REJECTED", "SIGNED", "PUBLISHED", "PARTIAL", "APPLIED", "SUPERSEDED"), "contentHash": R("Sha256Hex"), "signatureKeyId": STR(64),
      "builtFrom": arr(obj({"source": STR(32), "cursor": STR(64)}, req=["source"])), "routeCount": INT(), "consumerCount": INT(), "sizeBytes": INT(),
      "trigger": enum("AUTO", "MANUAL", "ROLLBACK", "IMPORT", "RECONCILE"), "rollbackOf": INT(description="Phiên bản đích khi ảnh chụp sinh ra do quay lui."), "gitPending": BOOL, "nodesApplied": INT(), "nodesTotal": INT(),
      "createdBy": STR(64), "createdAt": TS, "publishedAt": TS, "appliedAt": TS, "version": INT()},
      req=["snapshotVersion", "scope", "state", "contentHash"]),
  "SnapshotDetail": {"allOf": [R("Snapshot"), obj({"bundles": arr(obj({"gate": enum("EXT", "INT"), "file": STR(64), "sha256": R("Sha256Hex")}, req=["gate", "file"])),
      "shards": arr(obj({"tenant": R("TenantCode"), "gate": enum("EXT", "INT"), "sha256": R("Sha256Hex")}, req=["tenant", "gate"])),
      "findings": arr(R("Finding")), "rollbackOf": INT(description="Phiên bản đích khi ảnh chụp sinh ra do quay lui.")})]},
  "SnapshotPage": page("Snapshot"),
  "ValidateRequest": obj({"scope": enum("TENANT", "PLATFORM"), "tenant": R("TenantCode")}, req=["scope"]),
  "BuildRequest": obj({"scope": enum("TENANT", "PLATFORM"), "tenant": R("TenantCode"), "trigger": enum("MANUAL", "IMPORT"), "dryRun": BOOL,
      "reason": STR(500)}, req=["scope"], desc="`PLATFORM` chỉ dành cho PA. `dryRun=true` chỉ tổng hợp và kiểm tra, trả `ValidationReport`, không ký."),
  "ValidationReport": obj({"valid": BOOL, "routeCount": INT(), "checkedAt": TS, "findings": arr(R("Finding"))}, req=["valid", "findings"]),
  "RollbackRequest": obj({"scope": enum("TENANT", "PLATFORM"), "reason": STR(500, minLength=10), "holdHours": INT(minimum=1, maximum=168, default=24)},
      req=["scope", "reason"], desc="Phiên bản đích nằm ở đường dẫn. Sinh ảnh chụp mới mang nội dung bản đích (BR-03-018); giữ tổng hợp tự động `holdHours` giờ."),
  "SnapshotDiff": obj({"fromVersion": INT(), "toVersion": INT(), "summary": obj({"added": INT(), "changed": INT(), "removed": INT()}, req=["added", "changed", "removed"]),
      "changes": arr(obj({"objectType": enum("ROUTE", "UPSTREAM", "CONSUMER", "PLUGIN_CONFIG", "CERTIFICATE", "OTHER"), "objectCode": STR(127),
          "change": enum("ADDED", "CHANGED", "REMOVED"), "fields": arr(STR(64))}, req=["objectType", "objectCode", "change"]))}, req=["fromVersion", "toVersion", "summary", "changes"]),
  # ---- nút
  "Node": obj({"nodeId": STR(64), "gate": enum("EXT", "INT"), "site": STR(16), "runningVersion": INT(), "desiredVersion": INT(),
      "syncState": enum("IN_SYNC", "LAGGING", "FAILED", "UNKNOWN"), "lastSeenAt": TS, "jwksAgeSeconds": INT(), "valkeyUp": BOOL, "wafMode": R("WafModeValue"),
      "cpuPercent": NUM, "memoryMiB": INT(), "connections": INT(), "image": STR(64)}, req=["nodeId", "gate", "syncState"]),
  "NodeDetail": {"allOf": [R("Node"), obj({"lastErrors": arr(obj({"at": TS, "code": STR(32), "message": STR(500)})), "series": SERIES})]},
  "NodePage": page("Node"),
  # ---- mẫu chính sách
  "PolicyTemplate": obj({"templateCode": STR(64), "title": STR(255), "description": STR(1000), "version": STR(16), "enabled": BOOL,
      "params": arr(obj({"name": STR(64), "type": enum("integer", "string", "boolean", "enum"), "min": NUM, "max": NUM, "default": {}}, req=["name", "type"])),
      "inUseCount": INT(), "plugins": arr(STR(64)), "version_": INT()}, req=["templateCode", "title", "enabled"]),
  "PolicyTemplatePage": page("PolicyTemplate"),
  "TemplateEnablement": obj({"enabled": BOOL, "params": ANYOBJ, "reason": R("Reason")}, req=["enabled", "reason"]),
  # ---- chứng thư biên
  "Certificate": obj({"certCode": STR(64), "subject": STR(500), "hosts": arr(STR(255)), "notAfter": TS, "issuer": STR(500),
      "state": enum("VALID", "EXPIRING", "EXPIRED", "RENEWING", "FAILED"), "daysLeft": INT(), "autoRenew": BOOL, "version": INT()}, req=["certCode", "hosts", "notAfter", "state"]),
  "CertificatePage": page("Certificate"),
  # ---- yêu cầu thay đổi
  "ChangeRequest": obj({"requestId": UUID, "changeType": enum("EXPOSURE_EXT", "WAF_MODE", "TENANT_LIMIT_LOWER", "SETTINGS_FOUR_EYES"), "targetCode": STR(127),
      "payload": ANYOBJ, "state": enum("PENDING", "APPROVED", "REJECTED", "EXPIRED", "APPLIED"), "reason": STR(500), "requestedBy": STR(64), "requestedAt": TS,
      "decidedBy": STR(64), "decidedAt": TS, "decisionComment": STR(1000), "expiresAt": TS, "version": INT()},
      req=["requestId", "changeType", "state", "requestedBy"]),
  "ChangeRequestPage": page("ChangeRequest"),
  # ---- nhật ký lượt gọi
  "AccessLogEntry": obj({"logId": STR(64), "ts": TS, "tenant": R("TenantCode"), "traceId": STR(32), "spanId": STR(16), "routeCode": R("RouteCode"), "apiVersion": STR(16),
      "consumerCode": R("ConsumerCode"), "method": STR(10), "pathTemplate": STR(500, description="Theo mẫu route, không có giá trị tham số."),
      "queryNames": arr(STR(64), description="Chỉ tên tham số truy vấn."), "status": INT(), "errorCode": STR(16, pattern="^ERR-03-1[0-3][0-9]$"),
      "latencyMs": INT(), "upstreamMs": INT(), "bytesIn": INT(), "bytesOut": INT(), "srcIp": STR(45), "authResult": STR(24), "limitResult": STR(24),
      "wafResult": STR(24), "opaResult": STR(24), "node": STR(64), "upstreamNode": STR(255), "snapshotVersion": INT(), "synthetic": BOOL},
      req=["logId", "ts", "tenant", "traceId", "status"], desc="Siêu dữ liệu, tuyệt đối không có thân, tiêu đề xác thực, cookie, giá trị tham số (BR-03-007)."),
  "AccessLogPage": page("AccessLogEntry"),
  "AccessLogExportRequest": obj({"from": TS, "to": TS, "consumerCode": R("ConsumerCode"), "routeCode": R("RouteCode"), "statusClass": enum("2xx", "3xx", "4xx", "5xx"),
      "errorCode": STR(16), "format": enum("CSV", "JSONL"), "reason": R("Reason")}, req=["from", "to", "format", "reason"],
      desc="Tối đa 31 ngày mỗi lần, trong 12 tháng; tối đa `gw.accessLog.export.maxRows` dòng (ERR-03-021)."),
  "ExportJob": obj({"exportId": UUID, "kind": enum("ACCESS_LOG", "USAGE_REPORT"), "status": enum("QUEUED", "RUNNING", "DONE", "FAILED", "EXPIRED"), "rowCount": INT(),
      "downloadUrl": STR(2048, description="Có khi `DONE`; liên kết có chữ ký, hết hạn sau 24 giờ."), "requestedBy": STR(64), "createdAt": TS, "expiresAt": TS},
      req=["exportId", "status"]),
  # ---- tổng quan
  "Overview": obj({"window": enum("15m", "1h", "24h", "7d"), "dataAvailable": BOOL, "generatedAt": TS,
      "totals": obj({"calls": INT(), "status4xx": INT(), "status5xx": INT(), "rateLimited": INT(), "wafBlocked": INT(), "authFailed": INT()}),
      "latencyMs": obj({"p50": INT(), "p95": INT(), "p99": INT()}),
      "nodes": obj({"total": INT(), "inSync": INT(), "lagging": INT(), "failed": INT(), "unknown": INT()}),
      "degraded": obj({"valkey": BOOL, "waf": BOOL, "jwks": BOOL}), "runningSnapshotVersion": INT(), "series": SERIES,
      "kpis": arr(obj({"code": STR(32), "value": NUM, "previous": NUM, "trend": enum("UP", "DOWN", "FLAT")}, req=["code", "value"]),
          description="Chỉ số tổng quan kèm xu hướng so với kỳ liền trước cùng độ dài.")},
      req=["window", "dataAvailable"], desc="Khi PH-13 không trả số liệu: ERR-03-026, không trả số 0 giả."),
  "TopConsumers": obj({"window": STR(8), "items": arr(obj({"consumerCode": R("ConsumerCode"), "calls": INT(), "errorRate": NUM, "rateLimited": INT()}, req=["consumerCode", "calls"]))}, req=["items"]),
  "TopRoutes": obj({"window": STR(8), "items": arr(obj({"routeCode": R("RouteCode"), "calls": INT(), "errorRate": NUM, "p95Ms": INT()}, req=["routeCode", "calls"]))}, req=["items"]),
  # ---- kiểm tra tổng hợp
  "SyntheticCheck": obj({"checkId": UUID, "checkCode": STR(63, pattern="^[a-z][a-z0-9-]{2,62}$"), "routeCode": R("RouteCode"), "method": enum("GET", "HEAD", "POST"),
      "path": STR(500), "expectedStatus": arr(INT(minimum=100, maximum=599)), "expectedBodyJsonPath": STR(255), "timeoutMs": INT(maximum=10000), "intervalSeconds": INT(minimum=30),
      "enabled": BOOL, "lastResult": obj({"status": enum("PASSED", "FAILED"), "at": TS, "latencyMs": INT(), "errorCode": STR(16)}), "version": INT()},
      req=["checkId", "checkCode", "routeCode", "method", "path"]),
  "SyntheticCheckWrite": obj({"checkCode": STR(63, pattern="^[a-z][a-z0-9-]{2,62}$"), "routeCode": R("RouteCode"), "method": enum("GET", "HEAD", "POST"), "path": STR(500),
      "expectedStatus": arr(INT(minimum=100, maximum=599), minItems=1), "expectedBodyJsonPath": STR(255), "timeoutMs": INT(minimum=100, maximum=10000, default=10000),
      "intervalSeconds": INT(minimum=30, default=60), "enabled": BOOL}, req=["checkCode", "routeCode", "method", "path", "expectedStatus"]),
  "SyntheticCheckPage": page("SyntheticCheck"),
  # ---- cảnh báo an ninh
  "SecurityAlert": obj({"alertId": UUID, "ruleCode": STR(8, pattern="^GW-A(0[1-9]|1[0-3])$"), "severity": enum("MEDIUM", "HIGH", "CRITICAL"), "state": enum("OPEN", "ACKNOWLEDGED"),
      "routeCode": R("RouteCode"), "consumerCode": R("ConsumerCode"), "srcIp": STR(45), "count": INT(), "detail": STR(1000), "raisedAt": TS, "acknowledgedBy": STR(64),
      "acknowledgedAt": TS, "version": INT()}, req=["alertId", "ruleCode", "severity", "state", "raisedAt"]),
  "SecurityAlertPage": page("SecurityAlert"),
  # ---- tham số
  "Settings": obj({"items": arr(obj({"key": STR(64, pattern="^gw\\.[A-Za-z0-9.]+$"), "value": {}, "default": {}, "min": NUM, "max": NUM, "unit": STR(16),
      "requiresFourEyes": BOOL, "contractCeiling": NUM, "updatedAt": TS, "updatedBy": STR(64)}, req=["key", "value"]))}, req=["items"]),
  "SettingsUpdate": obj({"params": {"type": "object", "minProperties": 1, "maxProperties": 50, "additionalProperties": True, "propertyNames": {"pattern": "^gw\\.[A-Za-z0-9.]+$"}},
      "reason": R("Reason")}, req=["params", "reason"],
      desc="Khóa ngoài miền hoặc vượt trần hợp đồng: ERR-03-018. Khóa có bốn mắt (`gw.waf.mode`, hạ `gw.tenantRateLimit.perSecond`, `gw.ip.trustedCidrs`) trả 202 kèm yêu cầu thay đổi."),
  # ---- chạy thử
  "SimulationRequest": obj({"host": STR(255), "method": STR(10), "path": STR(2048), "consumerCode": R("ConsumerCode"),
      "claims": ANYOBJ, "headers": {"type": "object", "additionalProperties": STR(1024), "description": "Tiêu đề không nhạy cảm; `Authorization`, `Cookie` bị từ chối (ERR-03-003)."},
      "bodySample": STR(32768, description="Chỉ để thử WAF và lược đồ; không lưu."), "snapshotVersion": INT()}, req=["host", "method", "path"]),
  "SimulationResult": obj({"snapshotVersion": INT(), "matchedRoute": R("RouteCode"), "finalStatus": INT(), "finalErrorCode": STR(16),
      "stages": arr(obj({"stage": enum("TLS", "IP", "WAF", "SCHEMA", "AUTH", "SUBSCRIPTION", "SCOPE", "PATH", "OPA", "LIMIT", "ROUTE"),
          "result": enum("PASS", "REJECT", "SKIPPED"), "errorCode": STR(16), "detail": STR(500)}, req=["stage", "result"])),
      "problem": R("GatewayProblem"), "logged": BOOL}, req=["snapshotVersion", "finalStatus", "stages"], desc="Mô phỏng không gọi backend, không ghi nhật ký lượt gọi (`logged` luôn `false`). `problem` là thân RFC 9457 mà gateway sẽ trả cho bên gọi khi bị từ chối."),
  # ---- báo cáo
  "UsageReport": obj({"period": obj({"from": TS, "to": TS}), "groupBy": enum("CONSUMER", "ROUTE", "PLAN"), "generatedAt": TS,
      "rows": arr(obj({"key": STR(127), "name": STR(255), "calls": INT(), "errors": INT(), "rateLimited": INT(), "quotaUsedPercent": NUM, "p95Ms": INT()}, req=["key", "calls"]))},
      req=["groupBy", "rows"]),
  "UsageExportRequest": obj({"period": enum("DAY", "MONTH"), "from": TS, "to": TS, "groupBy": enum("CONSUMER", "ROUTE", "PLAN"), "consumerCode": R("ConsumerCode"),
      "routeCode": R("RouteCode"), "format": enum("CSV", "XLSX")}, req=["period", "from", "to", "groupBy", "format"]),
  # ---- nhập hệ cũ
  "LegacyImportJob": obj({"importId": UUID, "status": enum("SCANNING", "REVIEW", "APPLIED", "FAILED"), "fileName": STR(255), "fileSizeBytes": INT(),
      "findings": arr(obj({"file": STR(255), "kind": enum("SECRET_REMOVED", "UNSUPPORTED_PLUGIN", "UNKNOWN_SCHEME", "DUPLICATE", "PARSE_ERROR"), "key": STR(64), "message": STR(500)},
          req=["kind", "message"])),
      "proposals": arr(obj({"proposalId": STR(32), "objectType": enum("ROUTE", "UPSTREAM", "CONSUMER"), "suggestedCode": STR(127), "mapping": ANYOBJ,
          "legacyRef": STR(255), "needsReview": BOOL}, req=["proposalId", "objectType", "suggestedCode"])),
      "startedAt": TS, "finishedAt": TS}, req=["importId", "status"]),
  "LegacyApplyRequest": obj({"proposalIds": arr(STR(32), minItems=1, maxItems=500), "reason": R("Reason")}, req=["proposalIds", "reason"]),
  # ---- chuyển tiếp tenant
  "TenantRedirect": obj({"redirectId": UUID, "fromTenant": R("TenantCode"), "toTenant": R("TenantCode"), "startAt": TS, "endAt": TS,
      "state": enum("SCHEDULED", "ACTIVE", "ENDED"), "identityMode": enum("TOKEN_OF_TARGET"), "routeMap": arr(obj({"fromRoute": R("RouteCode"), "toRoute": R("RouteCode")}, req=["fromRoute", "toRoute"])),
      "createdBy": STR(64), "createdAt": TS, "version": INT()}, req=["redirectId", "fromTenant", "toTenant", "state", "startAt", "endAt"]),
  "TenantRedirectCreate": obj({"fromTenant": R("TenantCode"), "toTenant": R("TenantCode"), "startAt": TS, "endAt": TS, "identityMode": enum("TOKEN_OF_TARGET"),
      "routeMap": arr(obj({"fromRoute": R("RouteCode"), "toRoute": R("RouteCode")}, req=["fromRoute", "toRoute"]), minItems=1, maxItems=5000)},
      req=["fromTenant", "toTenant", "startAt", "routeMap"], desc="`endAt` mặc định 180 ngày sau `startAt` (`gw.redirect.defaultDays`). Tenant nguồn phải `MERGED` ở PH-20 (ERR-03-025)."),
  "TenantRedirectPage": page("TenantRedirect"),
}
def _open_allof():
    """Lược đồ nằm trong allOf không được đóng (additionalProperties false) vì các nhánh cùng mô tả một đối tượng."""
    used = set()
    for sch in SCHEMAS.values():
        for part in sch.get("allOf", []):
            if "$ref" in part: used.add(part["$ref"].split("/")[-1])
            else: part.pop("additionalProperties", None)
    for n in used:
        SCHEMAS[n].pop("additionalProperties", None)
        for part in SCHEMAS[n].get("allOf", []):
            if "$ref" not in part: part.pop("additionalProperties", None)
_open_allof()
SCHEMAS["PolicyTemplate"]["properties"]["version_"] = INT(description="Số phiên bản bản ghi (khóa lạc quan).")

EXAMPLES = {
  "ConsumerUpsert": {"systemCode": "HT-QLVB", "state": "ACTIVE", "priorityGroup": "NORMAL", "trustedSource": False, "authMethod": "MTLS",
      "certThumbprints": ["9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a"], "certNotAfter": "2027-06-30T00:00:00+07:00"},
  "CredentialsUpsert": {"authMethod": "MTLS", "certThumbprints": ["9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a"],
      "certNotAfter": "2027-06-30T00:00:00+07:00"},
  "RouteStopRequest": {"reason": "Backend tra cứu hộ tịch đang nâng cấp cơ sở dữ liệu", "message": "Dịch vụ tạm dừng để bảo trì, dự kiến mở lại 18:00."},
  "ExposureUpdate": {"exposure": "EXT", "reason": "Nhà cung cấp thanh toán gọi callback từ Internet", "wafParanoia": 1, "ipAllowCidrs": ["203.0.113.0/28"]},
  "RateLimitOverrideWrite": {"scope": "CONSUMER_ROUTE", "consumerCode": "ht-qlvb", "routeCode": "tra-cuu-ho-tich.v1", "limit": 100, "windowSeconds": 60, "burst": 10,
      "validTo": "2026-12-31T23:59:59+07:00", "reason": "Giảm tạm do HT-QLVB gọi lặp lỗi"},
  "TenantLimitsUpdate": {"limitPerSecond": 400, "burst": 20, "warnPercent": 80, "reason": "Hạ theo hợp đồng gia hạn quý IV"},
  "IpBlockCreate": {"cidr": "198.51.100.17/32", "durationMinutes": 120, "reason": "Quét lỗ hổng liên tục vào cửa Internet"},
  "WafModeUpdate": {"mode": "BLOCK", "scope": "TENANT", "reason": "Đã chạy phát hiện 16 ngày, cảnh báo giả đã xử lý hết"},
  "WafExceptionCreate": {"routeCode": "tra-cuu-ho-tich.v1", "ruleId": "942100", "reason": "Trường ghiChu chứa dấu nháy hợp lệ trong văn bản hành chính",
      "expiresAt": "2027-01-20T00:00:00+07:00", "evidenceEventId": "01JD7K2Q9XW4M3N5P6R8S0T1VA"},
  "VirtualPatchCreate": {"ruleText": "SecRule REQUEST_URI \"@contains /actuator/\" \"id:1900001,phase:1,deny,status:403,msg:'chặn actuator'\"", "appliesTo": "TENANT",
      "reason": "Chặn đường dẫn quản trị của thư viện bị lỗ hổng chưa có bản vá", "reference": "CVE-2026-0001", "expiresAt": "2026-12-26T00:00:00+07:00"},
  "CorsPolicyWrite": {"allowedOrigins": ["https://console.t68.datahub.example.vn"], "allowedMethods": ["GET", "POST"], "allowedHeaders": ["Content-Type", "Authorization"],
      "allowCredentials": False, "maxAgeSeconds": 600},
  "RevocationCreate": {"kind": "SUBJECT", "sub": "9b1d2c3e-4f50-4a6b-8c7d-0e1f2a3b4c5d", "notBefore": "2026-11-26T09:20:00+07:00", "tokenExpiresAt": "2026-11-26T09:25:00+07:00",
      "reason": "Tài khoản dịch vụ nghi bị lộ khóa"},
  "BuildRequest": {"scope": "TENANT", "tenant": "T68", "trigger": "MANUAL", "dryRun": False, "reason": "Phát thủ công sau đợt nhập hệ cũ"},
  "RollbackRequest": {"scope": "TENANT", "reason": "Bản 48213 làm tăng lỗi 5xx ở ba route", "holdHours": 24},
  "AccessLogExportRequest": {"from": "2026-11-26T08:00:00+07:00", "to": "2026-11-26T09:00:00+07:00", "consumerCode": "ht-qlvb", "statusClass": "4xx", "format": "CSV",
      "reason": "Điều tra HTTT báo bị chặn lúc 8 giờ"},
  "SyntheticCheckWrite": {"checkCode": "ho-tich-khai-sinh", "routeCode": "tra-cuu-ho-tich.v1", "method": "GET", "path": "/ho-tich/v1/khai-sinh/health-probe",
      "expectedStatus": [200], "timeoutMs": 10000, "intervalSeconds": 60, "enabled": True},
  "SettingsUpdate": {"params": {"gw.ip.apiReqPerSecond": 300, "gw.waf.anomalyThreshold": 5}, "reason": "Ba sở dùng chung địa chỉ NAT, nâng giới hạn theo IP"},
  "SimulationRequest": {"host": "api.t68.datahub.example.vn", "method": "GET", "path": "/ho-tich/v1/khai-sinh/123", "consumerCode": "ht-qlvb",
      "claims": {"scope": "ho-tich.read", "tenant": "T68"}, "headers": {"Content-Type": "application/json"}},
  "TenantRedirectCreate": {"fromTenant": "T71", "toTenant": "T68", "startAt": "2026-12-01T00:00:00+07:00",
      "routeMap": [{"fromRoute": "tra-cuu-ho-tich.v1", "toRoute": "tra-cuu-ho-tich.v1"}], "identityMode": "TOKEN_OF_TARGET"},
  "TlsExceptionCreate": {"hostPattern": "legacy.api.t68.datahub.example.vn", "reason": "HTTT cũ chưa hỗ trợ TLS 1.3, hẹn nâng cấp quý I", "expiresAt": "2027-03-31T00:00:00+07:00"},
  "WafExceptionCreate_": None,
  "TimeoutsUpdate": {"connectMs": 3000, "readMs": 10000, "breaker": {"failures": 5, "openSeconds": 10, "halfOpenProbes": 1, "unhealthyStatuses": [500, 502, 503, 504]}},
  "Snapshot": {"snapshotVersion": 48213, "site": "dc1", "scope": "T68", "state": "APPLIED", "contentHash": "9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a",
      "signatureKeyId": "dh-gateway-snapshot:3", "builtFrom": [{"source": "catalog", "cursor": "e-1204455"}, {"source": "onboarding", "cursor": "e-98812"}],
      "routeCount": 1042, "consumerCount": 187, "sizeBytes": 412880, "trigger": "AUTO", "gitPending": False, "nodesApplied": 6, "nodesTotal": 6,
      "createdAt": "2026-11-26T09:14:03+07:00", "publishedAt": "2026-11-26T09:14:08+07:00", "appliedAt": "2026-11-26T09:14:21+07:00", "version": 4},
  "ConsumerSummary": {"consumerCode": "ht-qlvb", "systemCode": "HT-QLVB", "priorityGroup": "NORMAL", "trustedSource": False, "authMethod": "MTLS", "state": "ACTIVE",
      "syncState": "IN_SYNC", "certNotAfter": "2027-06-30T00:00:00+07:00", "subscriptionCount": 6, "updatedAt": "2026-11-26T09:14:03+07:00", "version": 3,
      "allowedActions": ["suspend"], "disabledReasons": {"resume": "Consumer đang hoạt động."}},
}
EXAMPLES.pop("WafExceptionCreate_")
for _k, _v in EXAMPLES.items():
    SCHEMAS[_k]["examples"] = [_v]

PARAMS = {
  "RouteCodePath": {"name": "routeCode", "in": "path", "required": True, "schema": R("RouteCode")},
  "UpstreamCodePath": {"name": "upstreamCode", "in": "path", "required": True, "schema": R("UpstreamCode")},
  "ConsumerCodePath": {"name": "consumerCode", "in": "path", "required": True, "schema": R("ConsumerCode")},
  "PolicyCodePath": {"name": "policyCode", "in": "path", "required": True, "schema": STR(64)},
  "OverrideIdPath": {"name": "overrideId", "in": "path", "required": True, "schema": UUID},
  "ExceptionIdPath": {"name": "exceptionId", "in": "path", "required": True, "schema": UUID},
  "BlockIdPath": {"name": "blockId", "in": "path", "required": True, "schema": UUID},
  "PatchIdPath": {"name": "patchId", "in": "path", "required": True, "schema": UUID},
  "SnapshotVersionPath": {"name": "version", "in": "path", "required": True, "schema": INT(minimum=1), "description": "Số phiên bản ảnh chụp, tăng đơn điệu theo site."},
  "NodeIdPath": {"name": "nodeId", "in": "path", "required": True, "schema": STR(64)},
  "TemplateCodePath": {"name": "templateCode", "in": "path", "required": True, "schema": STR(64)},
  "CertCodePath": {"name": "certCode", "in": "path", "required": True, "schema": STR(64)},
  "RequestIdPath": {"name": "requestId", "in": "path", "required": True, "schema": UUID},
  "LogIdPath": {"name": "logId", "in": "path", "required": True, "schema": STR(64)},
  "CheckIdPath": {"name": "checkId", "in": "path", "required": True, "schema": UUID},
  "AlertIdPath": {"name": "alertId", "in": "path", "required": True, "schema": UUID},
  "ImportIdPath": {"name": "importId", "in": "path", "required": True, "schema": UUID},
  "RedirectIdPath": {"name": "redirectId", "in": "path", "required": True, "schema": UUID},
  "Page": {"name": "page", "in": "query", "schema": INT(minimum=1, default=1)},
  "Size": {"name": "size", "in": "query", "schema": INT(minimum=1, maximum=100, default=20), "description": "Tối đa 100."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại của đối tượng; lệch trả ERR-03-004 (412) kèm `currentEtag`."},
  "IfMatchOptional": {"name": "If-Match", "in": "header", "schema": STR(128), "description": "ETag hiện tại; có thì kiểm, lệch trả ERR-03-004."},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16),
      "description": "Lưu 24 giờ: cùng khóa cùng thân trả đúng phản hồi cũ; cùng khóa khác thân trả ERR-03-003."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
}
PATH_PARAM = {"routeCode": "RouteCodePath", "upstreamCode": "UpstreamCodePath", "consumerCode": "ConsumerCodePath", "policyCode": "PolicyCodePath",
    "overrideId": "OverrideIdPath", "exceptionId": "ExceptionIdPath", "blockId": "BlockIdPath", "patchId": "PatchIdPath", "version": "SnapshotVersionPath",
    "nodeId": "NodeIdPath", "templateCode": "TemplateCodePath", "certCode": "CertCodePath", "requestId": "RequestIdPath", "logId": "LogIdPath",
    "checkId": "CheckIdPath", "alertId": "AlertIdPath", "importId": "ImportIdPath", "redirectId": "RedirectIdPath"}

HTTP_RESP = {400: "BadRequest", 403: "Forbidden", 404: "NotFound", 409: "Conflict", 412: "PreconditionFailed", 422: "Unprocessable", 502: "BadGateway", 503: "ServiceUnavailable"}


def _codes(status):
    return [c for c, v in spec.ERR_CP.items() if v[0] == status]


def _problem_example(code):
    st, title, _ = spec.ERR_CP[code]
    ex = {"type": f"https://datahub.gov.vn/errors/ERR-03-{code}", "title": title, "status": st, "code": f"ERR-03-{code}", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}
    if code == "004": ex["currentEtag"] = "\"4\""
    if code == "003": ex["errors"] = [{"field": "certThumbprints[0]", "rule": "pattern", "message": "Phải là SHA-256 dạng hex 64 ký tự."}]
    return ex


RESPONSES = {
    "BadRequest": (400, "003", "Dữ liệu không hợp lệ (ERR-03-003, 021); kèm `errors` theo trường."),
    "Forbidden": (403, "022", "Không đủ quyền (ERR-03-022) hoặc vi phạm bốn mắt (ERR-03-008)."),
    "NotFound": (404, "001", "Không tìm thấy hoặc thuộc tenant khác, không phân biệt (ERR-03-001)."),
    "Conflict": (409, "019", "Trạng thái hoặc dữ liệu xung đột; mã cụ thể trong `code` (ERR-03-002, 006, 010, 017, 019, 023, 025)."),
    "PreconditionFailed": (412, "004", "`If-Match` không khớp (ERR-03-004); kèm `currentEtag`."),
    "Unprocessable": (422, "005", "Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-03-005, 007, 009, 011, 012, 013, 016, 018, 020, 024, 027)."),
    "BadGateway": (502, "014", "Không ghi được ảnh chụp tới Git hoặc bucket (ERR-03-014)."),
    "ServiceUnavailable": (503, "015", "Phụ thuộc chưa sẵn sàng (ERR-03-015 ký, ERR-03-026 số liệu PH-13)."),
}
RESPONSES_OBJ = {k: {"description": d, "content": {"application/problem+json": {"schema": R("ProblemDetails"), "example": _problem_example(c)}}}
                 for k, (st, c, d) in RESPONSES.items()}
RESPONSES_OBJ["ServiceUnavailable"]["headers"] = {"Retry-After": {"schema": INT(minimum=1), "description": "Số giây chờ trước khi thử lại."}}
HEADERS = {
  "RateLimitLimit": {"description": "Giới hạn chặt nhất đang áp cho bên gọi (FR-03-025). API quản trị là một route của chính cổng nên chịu cùng cơ chế.", "schema": INT(minimum=0)},
  "RateLimitRemaining": {"description": "Số lượt còn lại trong cửa sổ hiện tại.", "schema": INT(minimum=0)},
  "RateLimitReset": {"description": "Thời điểm đặt lại, giây Unix.", "schema": INT(minimum=0, format="int64", maximum=4102444800)},
  "RetryAfter": {"description": "Số giây nên chờ trước khi thử lại.", "schema": INT(minimum=0, maximum=86400)},
}
RL_HEADERS = {"X-RateLimit-Limit": {"$ref": "#/components/headers/RateLimitLimit"}, "X-RateLimit-Remaining": {"$ref": "#/components/headers/RateLimitRemaining"},
              "X-RateLimit-Reset": {"$ref": "#/components/headers/RateLimitReset"}}
RESPONSES_OBJ["TooManyRequests"] = {"description": "Vượt hạn mức do gateway áp trước khi tới `dh-connect` (ERR-03-116 theo HTTT, ERR-03-118 toàn tenant).",
    "headers": {**RL_HEADERS, "Retry-After": {"$ref": "#/components/headers/RetryAfter"}},
    "content": {"application/problem+json": {"schema": R("GatewayProblem"), "example": {"type": "https://datahub.gov.vn/errors/ERR-03-116", "title": "Vượt tần suất của HTTT",
        "status": 429, "code": "ERR-03-116", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "retryAfterSeconds": 1}}}}
RESPONSES_OBJ["InternalError"] = {"description": "Lỗi nội bộ của `dh-connect` chưa có mã ERR-03 (Q03-55); không kèm vết ngăn xếp hay tên nội bộ.",
    "content": {"application/problem+json": {"schema": R("GenericProblem"), "example": {"type": "https://datahub.gov.vn/errors/internal", "title": "Lỗi nội bộ", "status": 500,
        "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}
RESPONSES_OBJ["Problem"] = {"description": "Lỗi theo RFC 9457 (CC-API-02); mã cụ thể ở `code`, danh sách mã của thao tác ở `x-datahub-errors`.",
    "content": {"application/problem+json": {"schema": R("ProblemDetails"), "example": _problem_example("003")}}}
RESPONSES_OBJ["Unauthorized"] = {"description": "Thiếu token hoặc token hết hạn (lớp xác thực của `dh-connect`).",
    "content": {"application/problem+json": {"schema": R("GenericProblem"), "example": {"type": "https://datahub.gov.vn/errors/unauthorized", "title": "Chưa xác thực", "status": 401,
        "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}

Q = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": schema, "description": desc}.items() if v is not None}
QA = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": arr(schema), "style": "form", "explode": False, "description": desc}.items() if v is not None}
SORT = lambda fields: Q("sort", STR(pattern=f"^-?({'|'.join(fields)})$"), "Tên trường, thêm `-` phía trước để giảm dần.")
FROM_TO = [Q("from", TS, "Mốc bắt đầu."), Q("to", TS, "Mốc kết thúc; tối đa 31 ngày giữa hai mốc, trong 12 tháng (ERR-03-021).")]
WIN = Q("window", enum("15m", "1h", "24h", "7d"), "Khoảng thời gian, mặc định `1h`.")

# code -> (operationId, thân yêu cầu, thân phản hồi, mã lỗi riêng của thao tác, mô tả, tham số query thêm)
X = {
  "001": ("listRoutes", None, "RoutePage", [], "Danh sách route của tenant theo lọc; mặc định sắp theo `routeCode`.",
          [Q("q", STR(100, minLength=2), "Tìm không dấu trên mã route, mã API."), QA("state", R("RouteState")), Q("exposure", R("Exposure")), Q("apiCode", STR(100)), Q("upstreamCode", R("UpstreamCode")), SORT(["routeCode", "state", "updatedAt"]), "Page", "Size"]),
  "002": ("getRoute", None, "RouteDetail", [], "Trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm. Có `impact` để nêu hậu quả bằng số trước khi xác nhận; có `eligibility` khi gọi với `eligibility=true`. Có `ETag`.", [Q("eligibility", BOOL, "Trả thêm danh sách điều kiện mở cửa Internet, đạt hoặc chưa (UI-03-03 tab Cửa vào).")]),
  "003": ("stopRoute", "RouteStopRequest", "RouteDetail", ["019", "023"], "Chuyển `ACTIVE` sang `STOPPED`; lượt gọi nhận ERR-03-123 (503) kèm `Retry-After`. Phát EVT-03-03 và ghi kiểm toán.", []),
  "004": ("startRoute", "OptionalReason", "RouteDetail", ["019", "023"], "Chuyển `STOPPED` sang `ACTIVE`. Route `SUSPENDED` không mở ở đây mà ở API-03-020.", []),
  "005": ("listUpstreams", None, "UpstreamPage", [], None, [Q("q", STR(100, minLength=2)), Q("unhealthyOnly", BOOL), "Page", "Size"]),
  "006": ("getUpstream", None, "UpstreamDetail", [], "Trả danh sách nút kèm tình trạng kiểm tra sức khỏe mới nhất.", []),
  "007": ("listRouteVersions", None, "RouteVersionList", [], "Các route cùng `apiCode` khác phiên bản đang phục vụ song song, kèm ngày ngừng dùng và route kế nhiệm.", []),
  "008": ("setRouteExposure", "ExposureUpdate", "RouteDetail", ["011", "023"], "Đặt `INT` có hiệu lực ngay (200). Đặt `EXT` tạo yêu cầu thay đổi bốn mắt, trả 202 kèm `ChangeRequest`; SO duyệt ở API-03-072 (BR-03-015, 019).", []),
  "009": ("setRouteRequestLimits", "RequestLimits", "RouteDetail", ["018"], "Giới hạn kích thước thân và cấu trúc JSON theo route; vượt trần tenant (`gw.body.maxBytes`) trả ERR-03-018.", []),
  "010": ("setRouteTimeouts", "TimeoutsUpdate", "RouteDetail", ["018"], "Thời hạn chờ và ngắt mạch; trần 30.000 ms theo CV 631 (ERR-03-018 khi vượt).", []),
  "011": ("listConsumers", None, "ConsumerPage", [], "PH-13 đọc bằng scope `gateway:read-state`.",
          [Q("q", STR(100, minLength=2)), QA("state", R("ConsumerState")), QA("authMethod", R("AuthMethod")), QA("syncState", R("SyncState")), Q("systemCode", R("SystemCode")), Q("certExpiringDays", INT(minimum=1, maximum=365), "Chứng thư còn dưới số ngày này."), SORT(["consumerCode", "updatedAt", "certNotAfter"]), "Page", "Size"]),
  "012": ("getConsumer", None, "ConsumerDetail", [], "Không có bí mật. Có `impact` và `subscriptions` (API, gói, hiệu lực lấy từ bản chiếu PH-02). Có `ETag`.", []),
  "013": ("upsertConsumer", "ConsumerUpsert", "ConsumerDetail", ["002", "003"], "Scope `gateway:sync` (PH-01 trong saga kết nạp). Tạo mới trả 201, cập nhật trả 200. Lũy đẳng theo `Idempotency-Key`. Thân chứa trường dạng bí mật bị từ chối bằng ERR-03-003.", []),
  "014": ("putConsumerCredentials", "CredentialsUpsert", "CredentialsPublic", ["003", "016"], "Scope `gateway:sync`. Chỉ phần công khai: vân tay SHA-256 chứng thư, ngày hết hạn, băm khóa API. Gateway không lưu bí mật của client.", []),
  "015": ("deleteConsumer", None, None, ["017"], "Scope `gateway:sync` (bù trừ saga). Còn đăng ký sử dụng hiệu lực: ERR-03-017 kèm `activeSubscriptions`. Xóa mềm (BR-03-029).", []),
  "016": ("getConsumerCredentials", None, "CredentialsPublic", [], "Vân tay cắt ngắn, không bao giờ trả khóa API hay bí mật.", []),
  "017": ("suspendConsumer", "ReasonRequest", "ConsumerDetail", ["019"], "Có hiệu lực qua đường nhanh Valkey ≤ 30 giây (`gw.emergency.propagateSeconds`), không chờ ảnh chụp và không cần người duyệt. `If-Match` tùy chọn để không chậm trong sự cố. Lượt gọi nhận ERR-03-127.", []),
  "018": ("resumeConsumer", "OptionalReason", "ConsumerDetail", ["019"], "Mở lại consumer đã tạm ngừng; ghi lý do và kiểm toán.", []),
  "019": ("suspendRoute", "ReasonRequest", "RouteDetail", ["019", "023"], "Chuyển route sang `SUSPENDED` qua đường nhanh Valkey; lượt gọi nhận ERR-03-123. `If-Match` tùy chọn.", []),
  "020": ("resumeRoute", "OptionalReason", "RouteDetail", ["019", "023"], "Mở lại route `SUSPENDED`.", []),
  "021": ("listPlanPolicies", None, "PlanPolicyPage", [], "Bản chiếu từ gói của PH-02; PH-03 chỉ đọc.", [Q("planCode", STR(64)), Q("apiCode", STR(100)), QA("securityMode", R("SecurityMode")), "Page", "Size"]),
  "022": ("getPlanPolicy", None, "PlanPolicy", [], None, []),
  "023": ("getTenantLimits", None, "TenantLimits", [], "Hạn mức toàn tenant, mặc định 500 lượt/giây; nhóm `ESSENTIAL` không được miễn.", []),
  "024": ("putTenantLimits", "TenantLimitsUpdate", "TenantLimits", ["018"], "Tăng hiệu lực ngay (200). Hạ cần bốn mắt: trả 202 kèm yêu cầu thay đổi. Vượt trần hợp đồng ERR-03-018 kèm `ceiling`. Phát EVT-03-11.", []),
  "025": ("listRateLimitOverrides", None, "RateLimitOverridePage", [], None, [Q("consumerCode", R("ConsumerCode")), Q("routeCode", R("RouteCode")), Q("scope", enum("CONSUMER_ROUTE", "ROUTE", "CONSUMER")), "Page", "Size"]),
  "026": ("createRateLimitOverride", "RateLimitOverrideWrite", "RateLimitOverride", ["018", "023"], "Tính năng Đợt 2 (cờ `gateway.overrides.enabled`). Thứ tự ưu tiên ở FR-03-024. Phát EVT-03-11.", []),
  "027": ("updateRateLimitOverride", "RateLimitOverrideWrite", "RateLimitOverride", ["018"], None, []),
  "028": ("deleteRateLimitOverride", None, None, [], "Xóa mềm; phát EVT-03-11.", []),
  "029": ("getConsumerUsage", None, "ConsumerUsage", ["026"], "Mức dùng đọc từ Valkey và ClickHouse; `degraded=true` khi bộ đếm đang suy giảm theo FR-03-026.", []),
  "030": ("listQuotaAlerts", None, "QuotaAlertPage", ["026"], None, [Q("consumerCode", R("ConsumerCode")), Q("percent", ienum(80, 100)), "Page", "Size"]),
  "031": ("getTlsProfile", None, "TlsProfile", [], "Hồ sơ TLS 1.3 mặc định, nhóm mã, HSTS, OCSP stapling cho `apisix-ext` và `apisix-int`.", []),
  "032": ("listTlsExceptions", None, "TlsExceptionPage", [], None, [QA("state", enum("ACTIVE", "EXPIRED", "REVOKED")), "Page", "Size"]),
  "033": ("createTlsException", "TlsExceptionCreate", "TlsException", ["018"], "Cho phép TLS 1.2 tạm thời cho một host; tối đa 180 ngày (`gw.tls.exceptionMaxDays`).", []),
  "034": ("revokeTlsException", "OptionalReason", "TlsException", ["019"], None, []),
  "035": ("listClientCaBundles", None, "ClientCaBundle", [], "Bộ CA tin cậy và tuổi CRL (làm mới mỗi giờ).", []),
  "036": ("listIpBlocks", None, "IpBlockPage", [], None, [Q("source", enum("AUTO", "MANUAL")), Q("cidr", R("Cidr")), "Page", "Size"]),
  "037": ("createIpBlock", "IpBlockCreate", "IpBlock", ["003", "024"], "Ghi khóa chặn vào Valkey sau khi commit cơ sở dữ liệu; phát EVT-03-09.", []),
  "038": ("deleteIpBlock", None, None, [], None, []),
  "039": ("listWafEvents", None, "WafEventPage", ["021", "026"], "Sự kiện chặn của WAF (đọc từ PH-13). Không có nội dung yêu cầu.",
          FROM_TO + [Q("routeCode", R("RouteCode")), Q("ruleId", STR(6)), Q("action", enum("LOGGED", "BLOCKED")), "Page", "Size"]),
  "040": ("getWafMode", None, "WafModeInfo", [], "Kèm điều kiện chuyển sang `BLOCK`: 14 ngày phát hiện và số cảnh báo giả chưa xử lý dưới `gw.waf.fpReviewMax`.", []),
  "041": ("putWafMode", "WafModeUpdate", "WafModeInfo", ["019", "027"], "Cần bốn mắt: trả 202 kèm `ChangeRequest`; người duyệt (API-03-072) khác người đề nghị.", []),
  "042": ("listWafExceptions", None, "WafExceptionPage", [], None, [QA("state", enum("REQUESTED", "ACTIVE", "EXPIRING", "REJECTED", "EXPIRED", "REVOKED")), Q("routeCode", R("RouteCode")), Q("ruleId", STR(6)), "Page", "Size"]),
  "043": ("createWafException", "WafExceptionCreate", "WafException", ["009", "010"], "Trạng thái `REQUESTED`, chưa có hiệu lực ở gateway. TA, TO, SO đề nghị; chỉ SO duyệt. Phát EVT-03-05.", []),
  "044": ("approveWafException", "ApprovalDecision", "WafException", ["008", "019"], "Người duyệt khác người đề nghị (ERR-03-008). Chuyển `ACTIVE` và kích hoạt tổng hợp ảnh chụp mới.", []),
  "045": ("rejectWafException", "ReasonRequest", "WafException", ["008", "019"], None, []),
  "046": ("revokeWafException", "ReasonRequest", "WafException", ["019"], "Gỡ khỏi ảnh chụp kế tiếp.", []),
  "047": ("listVirtualPatches", None, "VirtualPatchPage", [], "Tính năng Đợt 2 (cờ `gateway.virtualPatch.enabled`).", [QA("state", enum("ACTIVE", "RETIRED", "EXPIRED")), "Page", "Size"]),
  "048": ("createVirtualPatch", "VirtualPatchCreate", "VirtualPatch", ["009"], "Luật SecLang tối đa 4 KiB, có lý do và hạn.", []),
  "049": ("retireVirtualPatch", "OptionalReason", "VirtualPatch", ["019"], None, []),
  "050": ("listCorsPolicies", None, "CorsPolicyPage", [], "Tính năng Đợt 2 (cờ `gateway.cors.enabled`).", [Q("routeCode", R("RouteCode")), "Page", "Size"]),
  "051": ("putCorsPolicy", "CorsPolicyWrite", "CorsPolicy", ["003"], "Không dùng ký tự đại diện cho nguồn gốc (BR-03-012).", []),
  "052": ("getJwksStatus", None, "JwksStatus", [], None, []),
  "053": ("createRevocation", "RevocationCreate", "Revocation", ["003"], "Scope `gateway:revoke` (PH-12). `dh-connect` ghi cơ sở dữ liệu rồi Valkey; hiệu lực ≤ 60 giây (SEC-25).", []),
  "054": ("listRevocations", None, "RevocationPage", [], None, [Q("sub", STR(128)), Q("jti", STR(128)), "Page", "Size"]),
  "055": ("listAuthorizationBindings", None, "AuthorizationBindingPage", [], None, [Q("routeCode", R("RouteCode")), "Page", "Size"]),
  "056": ("listSnapshots", None, "SnapshotPage", [], "PH-13 đọc bằng scope `gateway:read-state`.", [QA("state", enum("BUILT", "REJECTED", "SIGNED", "PUBLISHED", "PARTIAL", "APPLIED", "SUPERSEDED")), Q("scope", R("TenantCode")), SORT(["snapshotVersion", "createdAt"]), "Page", "Size"]),
  "057": ("getSnapshot", None, "SnapshotDetail", [], None, []),
  "058": ("validateSnapshot", "ValidateRequest", "ValidationReport", [], "Tổng hợp thử và kiểm tra 18 quy tắc CHK (CHK-01…15 mức lỗi, CHK-16…18 mức cảnh báo), không ký, không phát. Luôn trả 200; xem `valid` và `findings`.", []),
  "059": ("buildSnapshot", "BuildRequest", "Snapshot", ["005", "006", "012", "013", "015"], "Tổng hợp, kiểm tra, ký. Kiểm tra không đạt: ERR-03-005 kèm `findings` và phát EVT-03-12. Với `dryRun=true` trả 200 `ValidationReport` thay cho 201.", []),
  "060": ("publishSnapshot", None, "Snapshot", ["006", "014", "015", "019"], "Chỉ ảnh chụp `SIGNED` mới phát được: ghi bucket rồi Git (Git lỗi thì xếp hàng, cờ `gitPending`). Phát EVT-03-01.", []),
  "061": ("rollbackSnapshot", "RollbackRequest", "Snapshot", ["006", "007", "015", "019"], "Phiên bản trong đường dẫn là đích. Sinh ảnh chụp mới mang nội dung bản đích nên số phiên bản vẫn tăng. Phát EVT-03-02 và EVT-03-01. `PLATFORM` chỉ PA.", []),
  "062": ("diffSnapshot", None, "SnapshotDiff", [], "So với bản đang chạy hoặc bản chỉ định ở `against`.", [Q("against", INT(minimum=1), "Phiên bản đối chiếu, mặc định bản đang chạy.")]),
  "063": ("listNodes", None, "NodePage", [], "PH-13 đọc bằng scope `gateway:read-state`. Trạng thái suy ra từ chỉ số, không do nút gọi về.", [Q("gate", enum("EXT", "INT")), Q("site", STR(16)), QA("syncState", enum("IN_SYNC", "LAGGING", "FAILED", "UNKNOWN")), "Page", "Size"]),
  "064": ("getNode", None, "NodeDetail", [], None, []),
  "065": ("listPolicyTemplates", None, "PolicyTemplatePage", [], None, [Q("enabled", BOOL), "Page", "Size"]),
  "066": ("getPolicyTemplate", None, "PolicyTemplate", [], None, []),
  "067": ("putTemplateEnablement", "TemplateEnablement", "PolicyTemplate", ["013", "018", "019"], "Tắt mẫu đang được route dùng trả ERR-03-019.", []),
  "068": ("listCertificates", None, "CertificatePage", [], None, [QA("state", enum("VALID", "EXPIRING", "EXPIRED", "RENEWING", "FAILED")), Q("expiringDays", INT(minimum=1, maximum=365)), "Page", "Size"]),
  "069": ("getCertificate", None, "Certificate", [], None, []),
  "070": ("renewCertificate", "OptionalReason", "Certificate", ["015", "016"], "Yêu cầu cert-manager cấp lại; trả 202 và theo dõi bằng API-03-069. Chứng thư hiện tại giữ nguyên tới khi cấp xong.", []),
  "071": ("listChangeRequests", None, "ChangeRequestPage", [], None, [QA("state", enum("PENDING", "APPROVED", "REJECTED", "EXPIRED", "APPLIED")), Q("changeType", enum("EXPOSURE_EXT", "WAF_MODE", "TENANT_LIMIT_LOWER", "SETTINGS_FOUR_EYES")), "Page", "Size"]),
  "072": ("approveChangeRequest", "ApprovalDecision", "ChangeRequest", ["008", "019"], "Người duyệt khác người đề nghị, so theo tài khoản (ERR-03-008). Thay đổi được áp ngay khi duyệt.", []),
  "073": ("rejectChangeRequest", "ReasonRequest", "ChangeRequest", ["008", "019"], None, []),
  "074": ("listAccessLogs", None, "AccessLogPage", ["021", "026"], "Chỉ siêu dữ liệu; đọc từ ClickHouse của PH-13, p95 ≤ 3 giây. Có `srcIp` nên cần `PERM-03-log-read`.",
          FROM_TO + [Q("consumerCode", R("ConsumerCode")), Q("routeCode", R("RouteCode")), Q("statusClass", enum("2xx", "3xx", "4xx", "5xx")), Q("errorCode", STR(16)), Q("traceId", STR(32, pattern="^[0-9a-f]{32}$")),
                     Q("srcIp", STR(45)), SORT(["ts", "latencyMs"]), "Page", "Size"]),
  "075": ("getAccessLog", None, "AccessLogEntry", ["026"], "Ghi kiểm toán khi xem chi tiết có `srcIp`.", []),
  "076": ("exportAccessLogs", "AccessLogExportRequest", "ExportJob", ["021", "026"], "Tạo tệp xuất bất đồng bộ; trả 202 kèm `Location` tới `exportId`. Ghi kiểm toán: người dùng, bộ lọc, số dòng.", []),
  "077": ("getOverview", None, "Overview", ["026"], "Tổng quan lưu lượng, độ trễ, nút, suy giảm. PH-13 không trả số liệu thì ERR-03-026, không trả số 0 giả.", [WIN]),
  "078": ("getTopConsumers", None, "TopConsumers", ["026"], None, [WIN, Q("limit", INT(minimum=1, maximum=50, default=10))]),
  "079": ("getTopRoutes", None, "TopRoutes", ["026"], None, [WIN, Q("orderBy", enum("calls", "errorRate", "p95Ms"), "Mặc định `calls`."), Q("limit", INT(minimum=1, maximum=50, default=10))]),
  "080": ("listSyntheticChecks", None, "SyntheticCheckPage", [], None, [Q("routeCode", R("RouteCode")), Q("enabled", BOOL), "Page", "Size"]),
  "081": ("createSyntheticCheck", "SyntheticCheckWrite", "SyntheticCheck", ["002"], "Cờ `gateway.syntheticChecks.enabled`.", []),
  "082": ("updateSyntheticCheck", "SyntheticCheckWrite", "SyntheticCheck", [], None, []),
  "083": ("deleteSyntheticCheck", None, None, [], None, []),
  "084": ("listSecurityAlerts", None, "SecurityAlertPage", [], "Cảnh báo theo luật GW-A01…A13 (FR-03-054).", [QA("state", enum("OPEN", "ACKNOWLEDGED")), Q("ruleCode", STR(8)), Q("severity", R("Severity")), "Page", "Size"]),
  "085": ("acknowledgeSecurityAlert", "OptionalReason", "SecurityAlert", ["019"], None, []),
  "086": ("getSettings", None, "Settings", [], "Giá trị hiệu lực, mặc định, miền và trần hợp đồng của từng khóa `gw.*`.", [Q("prefix", STR(64), "Lọc theo họ khóa, ví dụ `gw.waf`.")]),
  "087": ("putSettings", "SettingsUpdate", "Settings", ["018", "019"], "Có hiệu lực khi ảnh chụp mới được nạp. Khóa có bốn mắt trả 202 kèm `ChangeRequest`. Phát EVT-03-11 khi đổi tham số hạn mức.", []),
  "088": ("runSimulation", "SimulationRequest", "SimulationResult", [], "Chạy mô phỏng trên ảnh chụp, không gọi backend, không ghi nhật ký lượt gọi. Cờ `gateway.simulation.enabled`.", []),
  "089": ("getUsageReport", None, "UsageReport", ["021", "026"], "Cờ `gateway.usageReport.enabled`.", [Q("groupBy", enum("CONSUMER", "ROUTE", "PLAN"), "Mặc định `CONSUMER`."), Q("period", enum("DAY", "MONTH")), Q("from", TS), Q("to", TS), Q("consumerCode", R("ConsumerCode")), Q("routeCode", R("RouteCode"))]),
  "090": ("exportUsageReport", "UsageExportRequest", "ExportJob", ["021", "026"], None, []),
  "091": ("importLegacyGateway", None, "LegacyImportJob", ["020"], "Tải tệp gói xuất của gateway cũ (≤ 50 MiB, multipart). Bộ quét loại bí mật; kết quả `PROPOSE_ONLY` để người duyệt từng đề xuất.", []),
  "092": ("getLegacyImport", None, "LegacyImportJob", [], None, []),
  "093": ("applyLegacyImport", "LegacyApplyRequest", "LegacyImportJob", ["020", "019"], "Tạo cấu hình nháp từ các đề xuất đã chọn; không tự phát (phải qua API-03-059, 060).", []),
  "094": ("listTenantRedirects", None, "TenantRedirectPage", [], None, [QA("state", enum("SCHEDULED", "ACTIVE", "ENDED")), "Page", "Size"]),
  "095": ("createTenantRedirect", "TenantRedirectCreate", "TenantRedirect", ["003", "025"], "Cờ `gateway.redirect.enabled`. Phát EVT-03-10 khi bắt đầu.", []),
  "096": ("endTenantRedirect", "OptionalReason", "TenantRedirect", ["019"], "Phát EVT-03-10.", []),
}
# POST hành động không cần If-Match (tạo mới, chạy thử, gọi hệ thống)
NO_404 = {"013"}  # PUT tạo hoặc cập nhật: không có "không tìm thấy"
NO_IFMATCH = {"058", "059", "061", "070", "076", "088", "090", "091"}
IFMATCH_OPTIONAL = {"013", "014", "017", "019"}
MULTI_SUCCESS = {"008": {"202": "ChangeRequest"}, "024": {"202": "ChangeRequest"}, "041": {"202": "ChangeRequest"}, "087": {"202": "ChangeRequest"},
                 "013": {"201": "ConsumerDetail"}, "059": {"200": "ValidationReport"}}
STATUS_OF = {c: v[0] for c, v in spec.ERR_CP.items()}


for _n, _r in RESPONSES_OBJ.items():
    if _n not in ("TooManyRequests",):
        _r.setdefault("headers", {}).update(RL_HEADERS)


def _limits(node):
    """CC-API-02: mọi chuỗi có maxLength, mọi mảng có maxItems, mọi số có minimum và maximum. Bỏ qua example, examples."""
    if isinstance(node, dict):
        t = node.get("type")
        if isinstance(t, str) and "$ref" not in node:
            if t == "string" and not ({"enum", "const", "maxLength"} & set(node)):
                node["maxLength"] = {"date-time": 40, "uuid": 36, "uri": 2048, "date": 10}.get(node.get("format"), 255)
            elif t == "array" and "maxItems" not in node:
                node["maxItems"] = 1000
            elif t == "integer":
                node.setdefault("format", "int32")
                node.setdefault("minimum", 0)
                node.setdefault("maximum", 2147483647)
            elif t == "number":
                node.setdefault("minimum", 0)
                node.setdefault("maximum", 1000000000000)
        for k, v in node.items():
            if k not in ("example", "examples"):
                _limits(v)
    elif isinstance(node, list):
        for v in node:
            _limits(v)


def build():
    assert set(X) == {o[0] for o in spec.OPS}, set(X) ^ {o[0] for o in spec.OPS}
    paths = {}
    for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
        opid, body, resp, errs, desc, extra = X[code]
        m = method.lower()
        frs = []
        for part in fr.split(","):
            frs.append(f"FR-03-{part.strip()}")
        op = {"tags": [spec.TAGS[group]], "operationId": opid, "summary": summary, "x-datahub-id": f"API-03-{code}", "x-datahub-fr": frs}
        if perm in spec.SERVICE_SCOPE:
            op["x-datahub-permission"] = {"serviceScope": spec.SERVICE_SCOPE[perm]}
            op["security"] = [{"oauth2Service": [spec.SERVICE_SCOPE[perm]]}]
        else:
            op["x-datahub-permission"] = {"permission": f"PERM-03-{perm}"}
            op["security"] = [{"oauth2User": []}]
        op["description"] = desc or (summary + ".")
        if idem: op["x-datahub-idempotent"] = True
        params = [P(PATH_PARAM[n]) for n in re.findall(r"\{(\w+)\}", path)]
        action = m == "post" and ":" in path.split("/")[-1]
        mutating = (m in ("put", "patch", "delete") or action) and code not in NO_IFMATCH
        auto = {"022"}
        if mutating:
            params.append(P("IfMatchOptional" if code in IFMATCH_OPTIONAL else "IfMatch"))
            if code not in IFMATCH_OPTIONAL: auto.add("004")
        for e in extra: params.append(P(e) if isinstance(e, str) else e)
        if idem: params.append(P("IdempotencyKey"))
        params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = params
        if path.count("{"): auto.update({"003"} if code in NO_404 else {"001", "003"})
        if body or any(isinstance(e, dict) and e["in"] == "query" for e in extra): auto.add("003")
        if code == "091":
            op["requestBody"] = {"required": True, "content": {"multipart/form-data": {"schema": {"type": "object", "required": ["file"], "properties": {
                "file": {"type": "string", "contentEncoding": "application/octet-stream", "description": "Tệp gói xuất, tối đa 50 MiB."}, "mappingMode": enum("PROPOSE_ONLY")}}}}}
        elif body:
            op["requestBody"] = {"required": body not in ("OptionalReason",), "content": {"application/json": {"schema": R(body)}}}
        okr = {"description": "Thành công."}
        if code == "091": auto.add("003")
        if resp and success != "204":
            okr["content"] = {"application/json": {"schema": R(resp)}}
        hdr = {}
        if m == "get" and resp: hdr["ETag"] = {"schema": STR(), "description": "Phiên bản bản ghi, dùng cho `If-Match`."}
        if success in ("202",) or code in ("059", "061"): hdr["Location"] = {"schema": STR(), "description": "Tài nguyên theo dõi hoặc tài nguyên mới tạo."}
        if success == "201": hdr["Location"] = {"schema": STR(), "description": "Tài nguyên mới tạo."}
        if hdr: okr["headers"] = hdr
        resps = {success: okr}
        for st, rn in MULTI_SUCCESS.get(code, {}).items():
            resps[st] = {"description": "Thành công, nhánh khác của cùng thao tác (xem mô tả).", "content": {"application/json": {"schema": R(rn)}},
                         **({"headers": {"Location": {"schema": STR()}}} if st == "201" else {})}
        errset = set(errs) | auto
        statuses = {401}
        for c in errset:
            statuses.add(STATUS_OF[c])
        for st in statuses:
            resps[str(st)] = RESP("Unauthorized") if st == 401 else RESP(HTTP_RESP[st])
        for st, r in resps.items():
            if st.startswith("2"):
                r.setdefault("headers", {}).update(RL_HEADERS)
        resps["429"] = RESP("TooManyRequests")
        resps["500"] = RESP("InternalError")
        resps["default"] = RESP("Problem")
        op["responses"] = dict(sorted(resps.items(), key=lambda kv: (kv[0] == "default", kv[0])))
        op["x-datahub-errors"] = [f"ERR-03-{c}" for c in sorted(errset)]
        paths.setdefault(path, {})[m] = op
    doc = {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-03 Cổng API, API quản trị cổng", "version": "1.0.0-draft",
               "summary": "Route, consumer, hạn mức, WAF, ảnh chụp cấu hình, nút, nhật ký lượt gọi và tham số của mặt phẳng điều khiển cổng API.",
               "description": ("API của module `gateway` trong `dh-connect` (control plane PH-03). Người dùng gọi qua BFF console "
                   "(Authorization Code + PKCE, quyền `PERM-03-*`); PH-01, PH-12 gọi một số thao tác bằng token dịch vụ (scope `gateway:sync`, `gateway:revoke`), "
                   "PH-13 đọc trạng thái bằng `gateway:read-state`. API này **không** nằm trên đường chuyển tiếp lượt gọi: APISIX (mặt phẳng dữ liệu) chỉ đọc ảnh chụp cấu hình đã ký, "
                   "không gọi vào đây.\n\nQuy ước (D03-04-PH03 §1): tenant lấy từ token; lệnh ghi consumer, tạo và xuất nhận `Idempotency-Key`; "
                   "sửa và đổi trạng thái bắt buộc `If-Match`; hậu tố `:{hành-động}`; phân trang `page`/`size`; lỗi RFC 9457 mã `ERR-03-nnn`. "
                   "Không API nào nhận hay trả bí mật. Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-03"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH03", "x-datahub-phase": "PH-03"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn" + spec.BASE, "description": "Production: qua BFF console của tenant, giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}, "x-internal": False, "x-environment": "production"},
                  {"url": "https://dh-connect.dh-control.svc:8443" + spec.BASE, "description": "Production: trong cụm (mesh mTLS), cho PH-01, PH-12, PH-13", "x-internal": True, "x-environment": "production"},
                  {"url": "https://localhost:8443" + spec.BASE, "description": "Local: phát triển cục bộ", "x-internal": True, "x-environment": "development"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": v} for v in spec.TAGS.values()],
      "paths": paths,
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}, JWT theo RFC8725 (JWT BCP), token truy cập sống ngắn (5 phút) làm mới bằng refresh token ở BFF; vai trò ánh xạ PERM-03-* (D02-08).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                                            "refreshUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Token dịch vụ theo RFC8725 (JWT BCP), sống ngắn (5 phút): PH-01 (`gateway:sync`), PH-12 (`gateway:revoke`), PH-13 (`gateway:read-state`).",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "refreshUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"gateway:sync": "Tạo, cập nhật, gỡ consumer", "gateway:revoke": "Đẩy danh sách chặn token",
                           "gateway:read-state": "Đọc cấu hình và trạng thái nút"}}}}},
        "parameters": PARAMS, "headers": HEADERS, "responses": RESPONSES_OBJ, "schemas": SCHEMAS},
      "x-datahub-error-catalog": {
        "controlPlane": {f"ERR-03-{c}": {"status": v[0], "title": v[1]} for c, v in spec.ERR_CP.items()},
        "gateway": {f"ERR-03-{c}": {"status": v[0], "title": v[1], "retryable": v[4]} for c, v in spec.ERR_GW.items()}}}
    _limits(doc["paths"]); _limits(doc["components"])
    return doc


if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-gateway.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH03 · OpenAPI PH-03 (dh-connect, module gateway). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(len(v) for v in doc["paths"].values())
    print(f"{n} operation, {len(doc['components']['schemas'])} lược đồ → {out}")
