"""Lược đồ dữ liệu (components.schemas) của OpenAPI PH-02. Dữ liệu ví dụ là giả lập (tenant T68, miền .example)."""


def R(n):
    return {"$ref": f"#/components/schemas/{n}"}


def A(x, **kw):
    return {"type": "array", "items": x, **kw}


def st(desc=None, **kw):
    d = {"type": "string"}
    if desc:
        d["description"] = desc
    d.update(kw)
    return d


def it(desc=None, **kw):
    d = {"type": "integer"}
    if desc:
        d["description"] = desc
    d.update(kw)
    return d


def nu(desc=None, **kw):
    d = {"type": "number"}
    if desc:
        d["description"] = desc
    d.update(kw)
    return d


def bo(desc=None, **kw):
    d = {"type": "boolean"}
    if desc:
        d["description"] = desc
    d.update(kw)
    return d


def ts(desc=None, **kw):
    return st(desc, format="date-time", **kw)


def uid(desc=None, **kw):
    return st(desc, format="uuid", **kw)


def en(*v, desc=None, **kw):
    d = {"type": "string", "enum": list(v)}
    if desc:
        d["description"] = desc
    d.update(kw)
    return d


def ob(props, req=(), desc=None, strict=False, **kw):
    d = {"type": "object"}
    if desc:
        d["description"] = desc
    d["properties"] = props
    if req:
        d["required"] = list(req)
    if strict:
        d["additionalProperties"] = False
    d.update(kw)
    return d


def pg(item, extra=None, req=("items", "page", "size", "totalElements")):
    p = {"items": A(item), "page": it(minimum=1), "size": it(minimum=1, maximum=100), "totalElements": it(minimum=0)}
    p.update(extra or {})
    return ob(p, req)


OBJ = {"type": "object", "additionalProperties": True}

S = {}

# ---- Kiểu cơ bản
S["ApiCode"] = st("Mã API duy nhất trong tenant (T-CODE chữ thường).", pattern="^[a-z][a-z0-9-]{2,62}$", example="tra-cuu-ho-tich")
S["VersionNo"] = st("Số hiệu `MAJOR.MINOR.PATCH`.", pattern=r"^[0-9]+\.[0-9]+\.[0-9]+$", example="1.0.0")
S["PlanCode"] = st(pattern="^[a-z][a-z0-9-]{1,31}$", example="co-ban")
S["BackendCode"] = st(pattern="^[a-z][a-z0-9-]{1,31}$", example="ho-tich-a")
S["CategoryCode"] = st(pattern="^[a-z][a-z0-9-]{1,63}$", example="ho-tich")
S["FlowCode"] = st(pattern="^[a-z][a-z0-9-]{2,62}$", example="flow-tra-cuu-ho-tich")
S["SystemCode"] = st("Mã HTTT ở PH-01 (T-CODE).", pattern="^[A-Z0-9][A-Z0-9_.-]{0,63}$", example="HT-MOTCUA")
S["OrgCode"] = st("Mã đơn vị.", pattern="^[A-Z0-9][A-Z0-9_.-]{0,63}$", example="SO-TUPHAP")
S["Environment"] = en("TEST", "STAGING", "PROD")
S["DataClass"] = en("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE", desc="Mức phân loại dữ liệu (SAD §8.2).")
S["Visibility"] = en("TENANT", "NATIONAL", "PUBLIC")
S["Origin"] = en("MANUAL", "OPENAPI", "FLOW", "LEGACY")
S["VersionStatus"] = en("DRAFT", "PENDING", "PUBLISHED", "SUSPENDED", "DEPRECATED", "RETIRED")
S["PlanStatus"] = en("STAGING", "PUBLISHED", "DEPRECATED", "CLOSED")
S["SubscriptionStatus"] = en("PENDING", "ACTIVE", "REJECTED", "CANCELLED", "SUSPENDED", "REVOKED", "EXPIRED")
S["AuthType"] = en("KEYLESS", "API_KEY", "OAUTH2_SECRET", "OAUTH2_PKJWT", "OAUTH2_MTLS")
S["GrantStatus"] = en("PENDING", "GRANTED", "AWAITING_CREDENTIAL", "FAILED")
S["Severity"] = en("ERROR", "WARNING", "INFO")
S["Layer"] = en("STANDARD", "CONVENTION", "SECRET")
S["FindingStatus"] = en("OPEN", "RESOLVED", "ACKNOWLEDGED")
S["ReviewKind"] = en("VERSION_PUBLISH", "VERSION_DEPRECATE", "VERSION_RETIRE", "PLAN_PUBLISH", "PLAN_DEPRECATE", "PLAN_CLOSE", "BACKEND_CHANGE", "VISIBILITY_RAISE", "SUBSCRIPTION", "SUBSCRIPTION_RENEW")
S["ReviewStatus"] = en("PENDING", "APPROVED", "REJECTED", "WITHDRAWN")
S["SyncStatus"] = en("QUEUED", "SENT", "ACKED", "REJECTED", "FAILED", "NOT_CONFIGURED")
S["GatewayState"] = en("APPLYING", "SYNCED", "FAILED", desc="Trạng thái đẩy cấu hình xuống gateway (lớp dịch vụ, không phải trạng thái vòng đời).")
S["Reason"] = st(minLength=1, maxLength=1000, example="Hết căn cứ pháp lý sử dụng dịch vụ.")

S["ProblemDetails"] = ob({
    "type": st(format="uri"), "title": st(), "status": it(), "detail": st(), "instance": st(),
    "code": st(pattern="^ERR-02-[0-9]{3}$"), "traceId": st(pattern="^[0-9a-f]{32}$"),
    "errors": A(ob({"path": st(), "rule": st(), "message": st()}, strict=True)),
    "missing": A(st(), description="ERR-02-012: điều kiện còn thiếu."),
    "findings": A(ob({"ruleId": st(), "severity": R("Severity"), "location": st(), "message": st()}), description="ERR-02-006, 007, 008."),
    "usages": A(ob({"kind": st(), "ref": st()}), description="ERR-02-024, 030: nơi còn dùng."),
    "retryAfterSeconds": it(minimum=0),
}, ("type", "title", "status", "code", "traceId"), desc="RFC 9457, mở rộng theo D03-04-PH02 §1.")

S["LintSummary"] = ob({"errors": it(minimum=0), "warnings": it(minimum=0), "infos": it(minimum=0)}, ("errors", "warnings", "infos"))
S["OperationAccepted"] = ob({"operationId": uid(), "status": en("QUEUED", "RUNNING"), "location": st(format="uri-reference")}, ("operationId", "status"),
                            examples=[{"operationId": "0192d3a1-7c20-7a31-9b5e-1f2e3a4b5c6d", "status": "QUEUED", "location": "/api/catalog/v1/operations/0192d3a1-7c20-7a31-9b5e-1f2e3a4b5c6d"}])
S["ReasonRequest"] = ob({"reason": R("Reason")}, ("reason",), strict=True)
S["NoteRequest"] = ob({"note": st(maxLength=1000)}, strict=True)

# ---- Danh mục
S["ApiSummary"] = ob({
    "apiCode": R("ApiCode"), "name": st(maxLength=200), "providerSystemCode": R("SystemCode"), "ownerOrgCode": R("OrgCode"),
    "dataClass": R("DataClass"), "visibility": R("Visibility"), "origin": R("Origin"), "categoryCode": R("CategoryCode"),
    "tags": A(st(maxLength=40), maxItems=20), "latestVersionNo": R("VersionNo"), "latestVersionStatus": R("VersionStatus"),
    "activeSubscriptions": it(minimum=0), "slaIndicator": en("MET", "BREACHED", "INSUFFICIENT_DATA", "NONE"),
    "attention": bo(desc="Có cảnh báo: SLA không đạt, đồng bộ quốc gia quá hạn, phiên bản sắp hết hạn mà còn bên dùng."), "updatedAt": ts(),
}, ("apiCode", "name", "dataClass", "visibility", "origin", "latestVersionNo", "latestVersionStatus"))
S["ApiPage"] = pg(R("ApiSummary"), {"facets": OBJ})
S["VersionSummary"] = ob({
    "versionNo": R("VersionNo"), "major": it(minimum=0), "status": R("VersionStatus"), "sunsetAt": ts(), "successorVersionNo": R("VersionNo"),
    "breaking": bo(), "publishedAt": ts(), "activeSubscriptions": it(minimum=0), "gatewayState": R("GatewayState"),
}, ("versionNo", "major", "status"))
S["VersionList"] = ob({"items": A(R("VersionSummary"))}, ("items",))
S["AllowedActions"] = A(st(), description="Hành động hợp lệ ở trạng thái hiện tại và với người gọi (ví dụ `submit`, `suspend`).")
S["VersionDetail"] = {"allOf": [R("VersionSummary"), ob({
    "apiCode": R("ApiCode"), "specId": uid(), "specSha256": st(pattern="^[0-9a-f]{64}$"), "contextPath": st(example="/ho-tich/tra-cuu-ho-tich/v1"),
    "publishedUrl": st(format="uri"), "suspendDeadline": ts(), "lintSummary": R("LintSummary"),
    "subscriptionCounts": ob({}, additionalProperties={"type": "integer"}),
    "allowedActions": R("AllowedActions"), "disabledReasons": ob({}, additionalProperties={"type": "string"}),
}, ("apiCode",))]}
S["ApiDetail"] = {"allOf": [R("ApiSummary"), ob({
    "description": st(maxLength=4000), "technicalContact": ob({"name": st(), "email": st(format="email")}), "portalPublished": bo(),
    "versions": A(R("VersionSummary")), "selectedVersion": R("VersionDetail"), "allowedActions": R("AllowedActions"), "flowSyncStatus": en("SYNCED", "PENDING_OWNER", "ERROR"),
}, ())]}
S["SearchHit"] = {"allOf": [R("ApiSummary"), ob({"highlights": OBJ, "score": nu()})]}
S["SearchPage"] = pg(R("SearchHit"), {"suggestions": A(st()), "degraded": bo()})
S["PlanBrief"] = ob({"planCode": R("PlanCode"), "name": st(), "authType": R("AuthType"), "status": R("PlanStatus"), "autoApprove": bo()}, ("planCode", "authType", "status"))
S["CatalogApi"] = ob({
    "apiCode": R("ApiCode"), "name": st(), "description": st(), "dataClass": R("DataClass"), "visibility": R("Visibility"), "categoryCode": R("CategoryCode"),
    "tags": A(st()), "ownerOrgCode": R("OrgCode"), "versions": A(R("VersionSummary")), "plans": A(R("PlanBrief")), "specUrl": st(format="uri-reference"),
    "portalPublished": bo(), "updatedAt": ts(),
}, ("apiCode", "name", "dataClass", "visibility"))
S["CatalogPage"] = pg(R("CatalogApi"), {"removed": A(R("ApiCode"), description="Mã đã gỡ từ `updatedSince`.")})
S["UsageGuide"] = ob({
    "baseUrl": st(format="uri", example="https://api.t68.example.vn"), "contextPath": st(), "tokenUrl": st(format="uri"), "scopes": A(st()),
    "operations": A(ob({"method": st(), "path": st(), "summary": st(), "scope": st()}, ("method", "path"))),
    "samples": A(ob({"language": en("curl", "javascript", "java"), "code": st()}, ("language", "code"))),
}, ("baseUrl", "contextPath", "operations"))
S["Spec"] = ob({}, desc="Tài liệu OpenAPI 3.1; thân là YAML hoặc JSON.", additionalProperties=True)

# ---- Phân loại, thẻ
S["ClassificationUpdate"] = ob({"categoryCode": R("CategoryCode"), "tags": A(st(maxLength=40), maxItems=20, uniqueItems=True), "dataClass": R("DataClass")}, ("categoryCode",), strict=True)
S["Category"] = ob({"categoryCode": R("CategoryCode"), "name": st(maxLength=100), "parentCode": R("CategoryCode"), "order": it(minimum=0), "apiCount": it(minimum=0)}, ("categoryCode", "name"))
S["CategoryCreate"] = ob({"categoryCode": R("CategoryCode"), "name": st(maxLength=100), "parentCode": R("CategoryCode"), "order": it(minimum=0)}, ("categoryCode", "name"), strict=True)
S["CategoryUpdate"] = ob({"name": st(maxLength=100), "parentCode": R("CategoryCode"), "order": it(minimum=0)}, strict=True, minProperties=1)
S["CategoryNode"] = ob({"categoryCode": R("CategoryCode"), "name": st(), "order": it(), "apiCount": it(), "children": A({"$ref": "#/components/schemas/CategoryNode"})}, ("categoryCode", "name"))
S["CategoryTree"] = ob({"items": A(R("CategoryNode")), "tags": A(ob({"tag": st(), "count": it()}, ("tag", "count")))}, ("items",))
S["CategoryImpact"] = ob({"affectedApis": it(minimum=0), "moveTo": R("CategoryCode")}, ("affectedApis",))
S["EventService"] = ob({
    "topicName": st(example="t68.rdm.catalog.published.v1"), "description": st(), "status": en("ACTIVE", "DEPRECATED", "RETIRED"), "dataClass": R("DataClass"),
    "publisherSystemCode": R("SystemCode"), "portalUrl": st(format="uri-reference"),
}, ("topicName", "status"))
S["EventServicePage"] = pg(R("EventService"), {"stale": bo()})

# ---- Đăng ký, nạp đặc tả
S["SpecInfo"] = ob({
    "specId": uid(), "sha256": st(pattern="^[0-9a-f]{64}$"), "sizeBytes": it(minimum=0), "openapiVersion": st(example="3.1.0"), "operationCount": it(minimum=0),
    "converted": bo(desc="Đã chuyển từ OpenAPI 3.0 hoặc Swagger 2.0 sang 3.1."), "lintSummary": R("LintSummary"), "expiresAt": ts(desc="Đặc tả chưa gắn API bị dọn sau 24 giờ."),
}, ("specId", "sha256", "sizeBytes", "openapiVersion", "operationCount", "lintSummary"))
S["SpecUpload"] = ob({"source": en("PASTE", "URL"), "content": st(maxLength=10485760), "url": st(format="uri")}, ("source",), strict=True,
                     desc="`source = PASTE` kèm `content`; `source = URL` kèm `url` (https, trong danh sách FQDN cho phép).")
S["SpecUploadForm"] = ob({"file": st(format="binary", description="Tệp `.yaml`, `.yml` hoặc `.json`, tối đa `02.spec.max-size-mib`.")}, ("file",))
S["ApiCreate"] = ob({
    "apiCode": R("ApiCode"), "name": st(minLength=3, maxLength=200), "description": st(maxLength=4000), "providerSystemCode": R("SystemCode"), "ownerOrgCode": R("OrgCode"),
    "dataClass": R("DataClass"), "visibility": R("Visibility"), "categoryCode": R("CategoryCode"), "tags": A(st(maxLength=40), maxItems=20),
    "contextPath": st(pattern="^/[a-z0-9/-]{3,120}$"), "specId": uid(), "technicalContact": ob({"name": st(), "email": st(format="email")}),
}, ("apiCode", "name", "providerSystemCode", "dataClass", "contextPath", "specId"), strict=True)
S["ApiUpdate"] = ob({
    "name": st(minLength=3, maxLength=200), "description": st(maxLength=4000), "technicalContact": ob({"name": st(), "email": st(format="email")}),
    "contextPath": st(pattern="^/[a-z0-9/-]{3,120}$"), "versionNo": R("VersionNo"), "specId": uid(desc="Thay đặc tả của `versionNo` (phiên bản `DRAFT`)."),
}, strict=True, minProperties=1)
S["FlowApiUpsert"] = ob({
    "workspaceCode": st(), "name": st(maxLength=200), "description": st(), "providerSystemCode": R("SystemCode"), "dataClass": R("DataClass"), "basePath": st(),
    "flowVersion": it(minimum=1), "restOperations": A(ob({"operationId": st(), "method": st(), "path": st(), "summary": st()}, ("operationId", "method", "path")), minItems=1),
}, ("workspaceCode", "name", "restOperations"), strict=True)
S["FlowApiResult"] = ob({"apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "flowSyncStatus": en("SYNCED", "PENDING_OWNER", "ERROR"), "created": bo()}, ("apiCode", "versionNo", "flowSyncStatus"))

# ---- Kiểm tra
S["Finding"] = ob({
    "findingId": uid(), "layer": R("Layer"), "severity": R("Severity"), "ruleId": st(example="LINT-02-08"), "location": st(description="Con trỏ JSON trong đặc tả."),
    "message": st(), "hint": st(), "status": R("FindingStatus"), "maskedTail": st(desc="Lớp `SECRET`: chỉ 4 ký tự cuối đã che, không bao giờ giá trị đầy đủ."),
    "reason": st(), "disputeRequested": bo(), "docUrl": st(format="uri-reference"),
    "line": it(minimum=1, desc="Dòng trong tệp đặc tả (từ 1) để giao diện nhảy tới."), "column": it(minimum=1),
}, ("findingId", "layer", "severity", "ruleId", "location", "message", "status"))
S["LintResult"] = ob({"valid": bo(), "summary": R("LintSummary"), "findings": A(R("Finding")), "checkedAt": ts(), "specSha256": st(pattern="^[0-9a-f]{64}$"), "rulesetVersion": it(minimum=1)},
                     ("valid", "summary", "findings", "checkedAt", "specSha256"))
S["LintPreviewRequest"] = ob({"content": st(maxLength=10485760), "specId": uid(), "dataClass": R("DataClass"), "authType": R("AuthType")}, strict=True, minProperties=1)
S["LintPreviewResult"] = ob({"valid": bo(), "canContinue": bo(), "summary": R("LintSummary"), "findings": A(R("Finding"))}, ("valid", "canContinue", "summary", "findings"))
S["DuplicateList"] = ob({"threshold": nu(), "items": A(ob({"apiCode": R("ApiCode"), "score": nu(minimum=0, maximum=1), "reasons": A(st()), "ownerOrgCode": R("OrgCode"), "status": R("VersionStatus")}, ("apiCode", "score")))}, ("items",))
S["Rule"] = ob({"ruleId": st(), "layer": R("Layer"), "defaultSeverity": R("Severity"), "severity": R("Severity"), "enabled": bo(), "description": st(), "hint": st(), "readOnly": bo()}, ("ruleId", "layer", "severity", "enabled"))
S["RuleSet"] = ob({"rulesetVersion": it(minimum=1), "rules": A(R("Rule"))}, ("rulesetVersion", "rules"))
S["RuleSetUpdate"] = ob({"reason": R("Reason"), "overrides": A(ob({"ruleId": st(pattern="^LINT-02-[0-9]{2}$"), "severity": R("Severity"), "enabled": bo()}, ("ruleId",), strict=True), minItems=1)}, ("reason", "overrides"), strict=True)
S["DisputeDecision"] = ob({"decision": en("ACCEPT", "REJECT"), "comment": R("Reason")}, ("decision", "comment"), strict=True)

# ---- Backend, đường dẫn
S["HealthCheck"] = ob({"path": st(example="/health"), "intervalSeconds": it(minimum=5, maximum=300), "timeoutMs": it(minimum=100, maximum=10000),
                       "healthyThreshold": it(minimum=1, maximum=10), "unhealthyThreshold": it(minimum=1, maximum=10)}, strict=True)
S["BackendTarget"] = ob({"type": en("SYSTEM", "FLOW"), "connectionCode": st(desc="Mã kết nối ở PH-05 khi `type = SYSTEM`."), "flowCode": R("FlowCode"), "path": st(desc="Tiền tố đường dẫn phía backend.")}, ("type",), strict=True)
S["Backend"] = ob({
    "backendCode": R("BackendCode"), "kind": en("SYSTEM", "FLOW"), "target": R("BackendTarget"), "weight": it(minimum=0, maximum=1000), "balancer": en("ROUND_ROBIN", "LEAST_CONN", "CONSISTENT_HASH"),
    "connectTimeoutMs": it(), "readTimeoutMs": it(), "retries": it(minimum=0, maximum=5), "healthCheck": R("HealthCheck"), "status": en("ACTIVE", "DISABLED"), "version": it(),
}, ("backendCode", "kind", "target", "weight", "status"))
S["BackendCreate"] = ob({"backendCode": R("BackendCode"), "target": R("BackendTarget"), "weight": it(minimum=0, maximum=1000, default=100), "healthCheck": R("HealthCheck")}, ("backendCode", "target"), strict=True)
S["BackendUpdate"] = ob({"weight": it(minimum=0, maximum=1000), "balancer": en("ROUND_ROBIN", "LEAST_CONN", "CONSISTENT_HASH"), "connectTimeoutMs": it(minimum=100, maximum=120000),
                         "readTimeoutMs": it(minimum=100, maximum=120000), "retries": it(minimum=0, maximum=5), "healthCheck": R("HealthCheck"), "status": en("ACTIVE", "DISABLED")}, strict=True, minProperties=1)
S["BackendList"] = ob({"items": A(R("Backend"))}, ("items",))
S["BackendHealthReport"] = ob({"overall": en("HEALTHY", "DEGRADED", "UNHEALTHY", "UNKNOWN"), "asOf": ts(), "backends": A(ob({
    "backendCode": R("BackendCode"), "status": en("HEALTHY", "UNHEALTHY", "UNKNOWN"), "since": ts(), "errorRate": nu(minimum=0, maximum=1), "p95Ms": it(),
    "nodes": A(ob({"node": st(), "status": en("HEALTHY", "UNHEALTHY")}))}, ("backendCode", "status")))}, ("overall", "asOf", "backends"))
S["ContextPathCheck"] = ob({"contextPath": st(), "available": bo(), "conflicts": A(ob({"contextPath": st(), "apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "reason": en("DUPLICATE", "PREFIX_OVERLAP", "RESERVED")}, ("contextPath", "reason")))}, ("contextPath", "available"))
S["SkeletonRequest"] = ob({"workspaceCode": st(), "flowCode": R("FlowCode")}, ("workspaceCode", "flowCode"), strict=True)

# ---- Gói
S["Quota"] = ob({"perSecond": it(minimum=1), "perMinute": it(minimum=1), "dailyCalls": it(minimum=1), "monthlyCalls": it(minimum=1)}, strict=True, minProperties=1)
S["Audience"] = ob({"mode": en("ALL", "GROUPS"), "systemGroups": A(st())}, ("mode",), strict=True)
S["Plan"] = ob({
    "planCode": R("PlanCode"), "name": st(), "description": st(), "status": R("PlanStatus"), "authType": R("AuthType"), "autoApprove": bo(), "audience": R("Audience"),
    "validityMonths": it(minimum=0, maximum=60), "quota": R("Quota"), "operationScopes": A(ob({"operationId": st(), "scope": st(example="api:tra-cuu-ho-tich:co-ban")}, ("operationId", "scope"))),
    "scopeTemplate": st(example="api:{apiCode}:{planCode}"), "unitPriceInfo": nu(minimum=0, desc="Đơn giá thông tin (đồng), không thu tiền ở PH-02."),
    "successorPlanCode": R("PlanCode"), "sunsetAt": ts(), "subscriptionCount": it(minimum=0), "version": it(),
}, ("planCode", "name", "status"))
S["PlanList"] = ob({"items": A(R("Plan"))}, ("items",))
S["PlanRow"] = ob({"apiCode": R("ApiCode"), "apiName": st(), "versionNo": R("VersionNo"), "versionStatus": R("VersionStatus"), "plan": R("Plan")}, ("apiCode", "versionNo", "versionStatus", "plan"))
S["PlanPage"] = pg(R("PlanRow"), {"counts": ob({}, additionalProperties={"type": "integer"})})
S["PlanCreate"] = ob({"planCode": R("PlanCode"), "name": st(minLength=2, maxLength=100), "description": st(maxLength=2000), "audience": R("Audience"), "autoApprove": bo(default=False),
                      "validityMonths": it(minimum=0, maximum=60, default=12)}, ("planCode", "name"), strict=True)
S["PlanUpdate"] = ob({"name": st(minLength=2, maxLength=100), "description": st(maxLength=2000), "audience": R("Audience"), "autoApprove": bo(), "validityMonths": it(minimum=0, maximum=60)}, strict=True, minProperties=1)
S["AccessPolicy"] = ob({"authType": R("AuthType"), "quota": R("Quota"), "operationScopes": A(ob({"operationId": st(), "scope": st()}, ("operationId",), strict=True))}, ("authType", "quota"), strict=True)
S["PlanDeprecateRequest"] = ob({"successorPlanCode": R("PlanCode"), "sunsetAt": ts(), "reason": R("Reason")}, ("sunsetAt", "reason"), strict=True)
S["PlanCopyRequest"] = ob({"fromVersionNo": R("VersionNo"), "planCodes": A(R("PlanCode"), minItems=1)}, ("fromVersionNo",), strict=True)
S["PlanCopyResult"] = ob({"plans": A(R("Plan")), "warnings": A(ob({"planCode": R("PlanCode"), "message": st()}, ("planCode", "message")))}, ("plans", "warnings"))

# ---- Vòng đời, duyệt
S["SubmitRequest"] = ob({"note": st(maxLength=1000), "acknowledgedFindingIds": A(uid())}, strict=True)
S["ReviewAccepted"] = ob({"reviewRequestId": uid(), "kind": R("ReviewKind"), "status": R("ReviewStatus")}, ("reviewRequestId", "kind", "status"),
                         examples=[{"reviewRequestId": "0192d3a1-8a10-7b22-8c4d-2e3f4a5b6c7d", "kind": "VERSION_PUBLISH", "status": "PENDING"}])
S["DeprecateRequest"] = ob({"sunsetAt": ts(), "successorVersionNo": R("VersionNo"), "reason": R("Reason"), "notifyNote": st(maxLength=1000), "urgentReason": st(maxLength=1000)}, ("sunsetAt", "reason"), strict=True)
S["SuspendRequest"] = ob({"reason": R("Reason"), "securityHold": bo(desc="SO tạm ngừng vì an ninh; chỉ SO được tiếp tục.")}, ("reason",), strict=True)
S["ReviewRequest"] = ob({
    "reviewRequestId": uid(), "kind": R("ReviewKind"), "status": R("ReviewStatus"),
    "subject": ob({"apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "planCode": R("PlanCode"), "subscriptionId": uid()}),
    "requestedBy": uid(), "requestedAt": ts(), "note": st(), "requiredApprovals": it(minimum=1, maximum=2, desc="2 với API `SENSITIVE`."), "approvals": it(minimum=0, maximum=2),
    "decidedBy": uid(), "decidedAt": ts(), "comment": st(), "ageDays": it(minimum=0), "overdue": bo(), "canDecide": bo(), "context": OBJ, "etag": st(),
}, ("reviewRequestId", "kind", "status", "requestedAt"))
S["ReviewPage"] = pg(R("ReviewRequest"), {"counts": ob({}, additionalProperties={"type": "integer"})})
S["ReviewRequestDetail"] = ob({
    "request": R("ReviewRequest"),
    "conditions": A(ob({"code": st(example="HAS_ACTIVE_BACKEND"), "met": bo(), "message": st()}, ("code", "met"))),
    "history": A(ob({"at": ts(), "by": uid(), "action": en("SUBMITTED", "APPROVED", "REJECTED", "CLARIFICATION_ASKED", "ANSWERED", "WITHDRAWN", "REMINDED"), "comment": st()}, ("at", "action"))),
}, ("request", "conditions", "history"))
S["ReviewDecision"] = ob({"comment": st(maxLength=1000), "conditions": ob({"approvedDailyCalls": it(minimum=1), "expiresAt": ts()}, strict=True)}, strict=True)
S["PublishRequest"] = ob({"environment": R("Environment"), "reviewRequestId": uid()}, ("environment",), strict=True)
S["PublishResult"] = ob({"status": R("VersionStatus"), "gatewayState": R("GatewayState"), "publishedAt": ts(), "gatewayConfigVersion": it(minimum=0), "publishedUrl": st(format="uri")}, ("status", "gatewayState"))
S["VisibilityUpdate"] = ob({"visibility": R("Visibility"), "portalPublished": bo(), "reason": R("Reason")}, ("visibility",), strict=True)
S["VersionCreate"] = ob({"versionNo": R("VersionNo"), "baseVersionNo": R("VersionNo"), "note": st(maxLength=1000)}, ("versionNo", "baseVersionNo"), strict=True)
S["Change"] = ob({"class": en("BREAKING", "NON_BREAKING", "UNCERTAIN"), "kind": st(example="RESPONSE_FIELD_REMOVED"), "location": st(), "description": st(), "impact": st()}, ("class", "kind", "location"))
S["VersionDiff"] = ob({"from": R("VersionNo"), "to": R("VersionNo"), "breaking": bo(), "versionViolation": bo(desc="Có thay đổi phá vỡ nhưng giữ số chính (ERR-02-017 khi gửi duyệt)."),
                       "suggestedVersion": R("VersionNo"), "uncertainCount": it(minimum=0), "changes": A(R("Change"))}, ("from", "to", "breaking", "versionViolation", "changes"))
S["ImpactAnalysis"] = ob({
    "summary": ob({"registered": it(), "active": it(), "callers": it(), "affected": it()}, ("registered", "active", "callers", "affected")),
    "affected": A(ob({"systemCode": R("SystemCode"), "orgCode": R("OrgCode"), "planCode": R("PlanCode"), "calls": it(), "errorRate": nu(), "operations": A(st()), "contact": st()}, ("systemCode", "planCode"))),
    "recommendation": st(),
}, ("summary", "affected"))
S["OwnerTransfer"] = ob({"ownerOrgCode": R("OrgCode"), "providerSystemCode": R("SystemCode"), "reason": R("Reason")}, ("ownerOrgCode", "providerSystemCode", "reason"), strict=True)

# ---- Đăng ký sử dụng
S["SubscriptionCreate"] = ob({
    "apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "planCode": R("PlanCode"), "systemCode": R("SystemCode"), "purpose": st(minLength=10, maxLength=1000),
    "expectedVolume": ob({"dailyCalls": it(minimum=1)}, ("dailyCalls",), strict=True), "legalBasis": st(maxLength=500), "acceptedTerms": bo(const=True),
}, ("apiCode", "versionNo", "planCode", "systemCode", "purpose", "expectedVolume", "acceptedTerms"), strict=True)
S["Subscription"] = ob({
    "subscriptionId": uid(), "apiCode": R("ApiCode"), "apiName": st(), "versionNo": R("VersionNo"), "versionStatus": R("VersionStatus"), "sunsetAt": ts(), "successorVersionNo": R("VersionNo"),
    "planCode": R("PlanCode"), "systemCode": R("SystemCode"), "orgCode": R("OrgCode"), "status": R("SubscriptionStatus"), "grantStatus": R("GrantStatus"),
    "purpose": st(), "expectedVolume": ob({"dailyCalls": it()}), "approvedDailyCalls": it(), "reviewRequestId": uid(), "activatedAt": ts(), "expiresAt": ts(), "renewedAt": ts(),
    "calls30d": it(minimum=0), "lastCallAt": ts(), "warnings": A(st()), "allowedActions": R("AllowedActions"), "version": it(),
}, ("subscriptionId", "apiCode", "versionNo", "planCode", "systemCode", "status"))
S["SubscriptionPage"] = pg(R("Subscription"), {"facets": OBJ, "totalsOnly": bo(desc="Người gọi chỉ được thấy số tổng.")})
S["SubscriberSystemList"] = ob({"items": A(ob({"systemCode": R("SystemCode"), "name": st(), "orgCode": R("OrgCode"), "canRegister": bo(), "canView": bo()}, ("systemCode", "orgCode")))}, ("items",))
S["RenewRequest"] = ob({"purpose": st(minLength=10, maxLength=1000), "expectedVolume": ob({"dailyCalls": it(minimum=1)}, strict=True)}, strict=True)
S["GrantState"] = ob({"subscriptionId": uid(), "grantStatus": R("GrantStatus"), "scopes": A(st()), "grantedAt": ts(), "failures": A(ob({"step": st(), "reason": st(), "at": ts()}, ("step", "reason")))}, ("subscriptionId", "grantStatus"))

# ---- Đồng bộ quốc gia
S["SyncRunRequest"] = ob({"scope": en("ALL_PENDING", "LIST"), "apiCodes": A(R("ApiCode"), maxItems=200)}, ("scope",), strict=True)
S["SyncRunAccepted"] = ob({"syncRunId": uid(), "operationId": uid(), "queued": it(minimum=0)}, ("syncRunId", "operationId"))
S["SyncSummary"] = ob({"acked": it(), "queued": it(), "failed": it(), "rejected": it(), "overdue": it(), "notConfigured": it(), "lastSuccessAt": ts()}, ("acked", "queued", "failed", "rejected", "overdue"))
S["SyncRecord"] = ob({"syncId": uid(), "apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "action": en("UPSERT", "WITHDRAW"), "status": R("SyncStatus"), "attempts": it(minimum=0),
                      "reason": st(), "nationalRef": st(), "payloadHash": st(pattern="^[0-9a-f]{64}$"), "sentAt": ts(), "ackedAt": ts(), "updatedAt": ts()}, ("syncId", "apiCode", "action", "status"))
S["SyncRecordPage"] = pg(R("SyncRecord"))

# ---- SLA, thông báo, thống kê
S["SlaTerms"] = ob({"latencyP99Ms": it(minimum=1), "availability": nu(minimum=90, maximum=100), "hourlyLimit": it(minimum=1), "serviceHours": st(example="24x7"),
                    "maintenanceWindows": A(st(example="CN 00:00-04:00")), "supportContact": st()}, ("latencyP99Ms", "availability"))
S["SlaUpdate"] = {"allOf": [R("SlaTerms"), ob({"reason": R("Reason")}, ())], "unevaluatedProperties": False}
S["SlaCommitment"] = ob({"current": R("SlaTerms"), "pending": ob({"terms": R("SlaTerms"), "effectiveFrom": ts()}, ("terms", "effectiveFrom")), "version": it()})
S["SlaPeriods"] = ob({"compliance": nu(minimum=0, maximum=1, desc="Tỷ lệ kỳ đạt 12 tháng gần nhất."), "asOf": ts(), "periods": A(ob({
    "period": st(pattern="^[0-9]{4}-[0-9]{2}$"), "committed": R("SlaTerms"), "actual": ob({"latencyP99Ms": it(), "availability": nu(), "calls": it()}),
    "met": {"type": ["boolean", "null"]}, "status": en("MET", "BREACHED", "INSUFFICIENT_DATA"), "consecutiveBreaches": it(minimum=0)}, ("period", "status")))}, ("periods", "asOf"))
S["SlaSummary"] = ob({
    "asOf": ts(), "period": st(pattern="^[0-9]{4}-[0-9]{2}$"), "apisWithCommitment": it(minimum=0), "apisWithoutCommitment": it(minimum=0),
    "compliance": nu(minimum=0, maximum=1, desc="Tỷ lệ API đạt cam kết ở kỳ gần nhất có đủ dữ liệu."),
    "breachedApis": it(minimum=0), "consecutiveBreachApis": it(minimum=0, desc="API không đạt từ `02.sla.breach-periods` kỳ liên tiếp."), "totalCalls": it(minimum=0),
    "groups": A(ob({"key": st(example="RESTRICTED"), "label": st(), "apis": it(minimum=0), "compliance": nu(minimum=0, maximum=1)}, ("key", "apis"))),
    "worstApis": A(ob({"apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "consecutiveBreaches": it(minimum=1)}, ("apiCode", "versionNo", "consecutiveBreaches"))),
}, ("asOf", "period", "apisWithCommitment", "breachedApis"))
S["NoticeCreate"] = ob({"kind": en("ANNOUNCEMENT", "MAINTENANCE", "INCIDENT"), "title": st(maxLength=200), "body": st(maxLength=2000), "audience": en("ALL_ACTIVE", "PLAN"), "planCodes": A(R("PlanCode"))},
                       ("kind", "title", "body", "audience"), strict=True)
S["NoticeAccepted"] = ob({"noticeId": uid(), "recipients": it(minimum=0)}, ("noticeId", "recipients"))
S["Notice"] = ob({"noticeId": uid(), "kind": en("ANNOUNCEMENT", "MAINTENANCE", "INCIDENT", "DEPRECATION", "SLA_WORSENED", "PUBLISHED", "SUSPENDED", "RETIRED"), "apiCode": R("ApiCode"), "versionNo": R("VersionNo"),
                  "title": st(), "recipientCount": it(), "channelStatus": OBJ, "createdAt": ts(),
                  "recipients": A(ob({"systemCode": R("SystemCode"), "channel": en("IN_APP", "EMAIL"), "status": en("SENT", "READ", "FAILED")}))}, ("noticeId", "kind", "apiCode", "createdAt"))
S["NoticePage"] = pg(R("Notice"))
S["UsageSeries"] = ob({"series": A(ob({"time": ts(), "calls": it(), "consumers": it(), "errorRate4xx": nu(), "errorRate5xx": nu(), "p95Ms": it()}, ("time", "calls"))),
                       "topConsumers": A(ob({"systemCode": R("SystemCode"), "calls": it()})), "unused": bo(), "trend": en("UP", "FLAT", "DOWN")}, ("series",))
S["UsageSummary"] = ob({"apisByStatus": ob({}, additionalProperties={"type": "integer"}), "totalCalls": it(), "topApis": A(ob({"apiCode": R("ApiCode"), "calls": it()})), "slaCompliantRatio": nu(minimum=0, maximum=1)}, ("apisByStatus", "totalCalls"))

# ---- Nội bộ
S["PublishedConsumer"] = ob({"subscriptionId": uid(), "systemCode": R("SystemCode"), "clientId": st(), "apiCode": R("ApiCode"), "planCode": R("PlanCode"), "scopes": A(st()), "quota": R("Quota")}, ("subscriptionId", "clientId", "apiCode", "planCode"))
S["PublishedApi"] = ob({
    "apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "status": R("VersionStatus"), "contextPath": st(), "deprecation": ob({"sunsetAt": ts()}),
    "backends": A(R("Backend")), "plans": A(R("Plan")), "operations": A(ob({"operationId": st(), "method": st(), "path": st()}, ("operationId", "method", "path"))),
}, ("apiCode", "versionNo", "status", "contextPath", "backends", "plans", "operations"))
S["PublishedConfig"] = ob({
    "environment": R("Environment"), "configVersion": it(minimum=0), "sourceVersion": it(minimum=0), "gap": bo(desc="`true` khi `sinceConfigVersion` quá cũ; PH-03 lấy toàn bộ."), "configHash": st(pattern="^[0-9a-f]{64}$"),
    "apis": A(R("PublishedApi")), "removedRoutes": A(st()), "consumers": A(R("PublishedConsumer")), "removedConsumers": A(uid()),
}, ("environment", "configVersion", "sourceVersion", "gap", "apis", "consumers"))
S["PortalCatalogPage"] = pg(R("CatalogApi"), {"removed": A(R("ApiCode"))})
S["ApplyAck"] = ob({"environment": R("Environment"), "configVersion": it(minimum=0), "sourceVersion": it(minimum=0), "configHash": st(pattern="^[0-9a-f]{64}$"), "result": en("APPLIED", "FAILED"), "reason": st(maxLength=1000)},
                   ("environment", "sourceVersion", "result"), strict=True)
S["DriftReport"] = ob({"environment": R("Environment"), "inSync": bo(), "gatewayConfigVersion": it(), "expectedVersion": it(), "checkedAt": ts(),
                       "drifts": A(ob({"kind": en("MISSING", "EXTRA", "STALE"), "apiCode": R("ApiCode"), "versionNo": R("VersionNo"), "detail": st()}, ("kind",)))}, ("environment", "inSync", "drifts", "checkedAt"))
S["ReconcileRequest"] = ob({"environment": R("Environment"), "repair": bo(default=False)}, ("environment",), strict=True)

# ---- Di trú, tham số, tác vụ
S["LegacyImportUpload"] = ob({"package": st(format="binary", description="Gói xuất từ APIM cũ (`.zip` hoặc `.json`)."), "defaultSystemCode": R("SystemCode")}, ("package",))
S["ImportPreview"] = ob({"importId": uid(), "counts": ob({"apis": it(), "plans": it(), "subscriptions": it()}, ("apis", "plans", "subscriptions")),
                         "items": A(ob({"legacyId": st(), "proposedApiCode": R("ApiCode"), "name": st(), "versionNo": R("VersionNo"), "plans": it(), "subscriptions": it(), "issues": A(st())}, ("legacyId", "proposedApiCode"))),
                         "issues": A(ob({"legacyId": st(), "severity": R("Severity"), "message": st()}, ("severity", "message")))}, ("importId", "counts", "items", "issues"))
S["ImportCommit"] = ob({"mappings": A(ob({"legacyId": st(), "apiCode": R("ApiCode")}, ("legacyId", "apiCode"), strict=True)), "skip": A(st()), "acceptIssues": bo()}, ("acceptIssues",), strict=True)
S["ImportCommitResult"] = ob({"importId": uid(), "created": ob({"apis": it(), "plans": it(), "subscriptions": it()}, ("apis", "plans", "subscriptions"))}, ("importId", "created"))
S["ImportReport"] = ob({"importId": uid(), "source": ob({"apis": it(), "plans": it(), "subscriptions": it()}), "imported": ob({"apis": it(), "plans": it(), "subscriptions": it()}),
                        "skipped": A(ob({"legacyId": st(), "reason": st()}, ("legacyId", "reason"))), "checksum": st(pattern="^[0-9a-f]{64}$")}, ("importId", "source", "imported", "skipped", "checksum"))
S["Setting"] = ob({"key": st(pattern=r"^02\.[a-z.-]+$"), "default": {}, "domain": st(), "effective": {}, "description": st()}, ("key", "effective"))
S["SettingList"] = ob({"items": A(R("Setting")), "effectiveAt": ts(), "impact": st()}, ("items",))
S["SettingPatch"] = ob({"values": ob({}, additionalProperties=True, minProperties=1), "reason": R("Reason")}, ("values", "reason"), strict=True)
S["HistoryPage"] = pg(ob({"at": ts(), "kind": st(example="VERSION_STATE_CHANGED"), "actor": st(), "summary": st(), "versionNo": R("VersionNo"), "details": OBJ}, ("at", "kind", "actor", "summary")))
S["OperationStatus"] = ob({"operationId": uid(), "kind": st(example="SPEC_REFRESH", desc="Loại tác vụ, khớp `async_operation.kind` ở D03-03-PH02: `SPEC_REFRESH`, `ROUTE_SKELETON`, `DIFF`, `IMPACT_ANALYSIS`, `LEGACY_IMPORT_COMMIT`, `NATIONAL_SYNC_RUN`, `GATEWAY_RECONCILE` (Q02-61 đã chốt 27/11/2026)."), "status": en("QUEUED", "RUNNING", "SUCCEEDED", "FAILED", "CANCELLED"), "progress": it(minimum=0, maximum=100),
                           "result": OBJ, "error": R("ProblemDetails"), "startedAt": ts(), "finishedAt": ts()}, ("operationId", "kind", "status"))

# ---- Ví dụ thân yêu cầu (kiểm khớp lược đồ ở check_contracts.py)
EXAMPLES = {
    "014": {"apiCode": "tra-cuu-ho-tich", "name": "Tra cứu thông tin hộ tịch", "description": "Tra cứu giấy khai sinh theo số định danh (dữ liệu giả lập).",
            "providerSystemCode": "HT-HOTICH", "ownerOrgCode": "SO-TUPHAP", "dataClass": "RESTRICTED", "visibility": "TENANT", "categoryCode": "ho-tich",
            "tags": ["khai-sinh", "tra-cuu"], "contextPath": "/ho-tich/tra-cuu-ho-tich/v1", "specId": "0192d3a1-6f10-7a00-8a11-0a1b2c3d4e5f"},
    "027": {"backendCode": "ho-tich-a", "target": {"type": "SYSTEM", "connectionCode": "ht-hotich-rest", "path": "/api"}, "weight": 100,
            "healthCheck": {"path": "/health", "intervalSeconds": 30, "timeoutMs": 2000, "healthyThreshold": 2, "unhealthyThreshold": 3}},
    "034": {"planCode": "co-ban", "name": "Gói cơ bản", "audience": {"mode": "ALL"}, "autoApprove": False, "validityMonths": 12},
    "036": {"authType": "OAUTH2_PKJWT", "quota": {"perSecond": 20, "dailyCalls": 50000}, "operationScopes": [{"operationId": "getBirthCertificate", "scope": "api:tra-cuu-ho-tich:co-ban"}]},
    "042": {"note": "API cho Cổng một cửa dùng."},
    "045": {"comment": "Đủ điều kiện công bố.", "conditions": {"approvedDailyCalls": 2000, "expiresAt": "2027-11-26T00:00:00Z"}},
    "050": {"sunsetAt": "2027-06-30T00:00:00Z", "successorVersionNo": "2.0.0", "reason": "Chuyển sang lược đồ mới theo thông tư."},
    "058": {"apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "planCode": "co-ban", "systemCode": "HT-MOTCUA", "purpose": "Tra cứu hộ tịch phục vụ giải quyết thủ tục một cửa.",
            "expectedVolume": {"dailyCalls": 3000}, "legalBasis": "Quyết định số 12/QĐ-UBND (giả lập)", "acceptedTerms": True},
    "069": {"scope": "ALL_PENDING"},
    "073": {"latencyP99Ms": 800, "availability": 99.5, "hourlyLimit": 5000, "serviceHours": "T2-T6 07:00-17:00", "maintenanceWindows": ["CN 00:00-04:00"], "supportContact": "ht.sotuphap@t68.example.vn", "reason": "Điều chỉnh theo năng lực hạ tầng mới."},
    "076": {"kind": "MAINTENANCE", "title": "Bảo trì 02/12/2026 00:00-04:00", "body": "Dịch vụ tạm ngừng trong khung giờ bảo trì định kỳ.", "audience": "ALL_ACTIVE"},
    "082": {"environment": "PROD", "configVersion": 4182, "sourceVersion": 9317, "configHash": "a" * 64, "result": "APPLIED"},
    "086": {"mappings": [{"legacyId": "svc-0042", "apiCode": "tra-cuu-dat-dai"}], "skip": ["svc-0099"], "acceptIssues": True},
}
