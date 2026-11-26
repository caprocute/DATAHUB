#!/usr/bin/env python3
"""Sinh ph10/openapi-event.yaml (OpenAPI 3.1) từ spec.OPS và lược đồ trong tệp này.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph10)
Mọi enum, tên trường lấy theo Phụ lục A của D02-03-PH10 (FRS 0.2); trường chỉ có ở API mà phụ lục chưa có
được liệt kê ở D03-04-PH10 §10 (đề nghị bổ sung cho FRS). Mỗi operation có ví dụ yêu cầu (khi có thân) và
ví dụ phản hồi; ví dụ sinh từ lược đồ (examples.py) rồi ghi đè bằng ví dụ viết tay. YAML là hợp đồng; không sửa tay.
"""
import os, re, sys, copy, yaml
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
def nul(x):
    """Cho phép null."""
    x = copy.deepcopy(x)
    if "$ref" in x: return {"oneOf": [x, {"type": "null"}]}
    x["type"] = [x["type"], "null"]; return x
def ext(base, props, req=()):
    return {"allOf": [R(base), obj(props, req)]}

STR = lambda mx=None, **kw: s("string", **({"maxLength": mx} if mx else {}), **kw)
INT = lambda **kw: s("integer", **kw)
LONG = s("integer", format="int64", minimum=0)
NUM = s("number")
BOOL = s("boolean")
TS = s("string", format="date-time")
UUID = s("string", format="uuid")
ANYOBJ = {"type": "object", "additionalProperties": True}
CNT = {"type": "object", "additionalProperties": INT(minimum=0), "description": "Đếm theo giá trị enum."}
TEXT = STR(2000)
USER = STR(64, description="Tên đăng nhập hoặc `system:auto`, `svc:{client}`.")
CODE_RE = "^[a-z][a-z0-9-]{2,62}$"
ULID = "[0-9a-hjkmnp-tv-z]{26}"
AUDIT = {"createdAt": TS, "createdBy": USER, "updatedAt": TS, "updatedBy": USER, "version": INT(minimum=0)}

def code(desc, ex, pattern=CODE_RE, mx=63):
    return STR(mx, pattern=pattern, description=desc, examples=[ex])

SCHEMAS = {
  # ---------------- mã, định danh (A.1, A.8)
  "ProjectCode": code("Mã dự án, T-CODE chữ thường; không dùng từ dành riêng `moi`, `tong-quan`, `nhap`, `di-tru`, `ben-phat`, `ben-nhan` (ERR-10-003).", "dang-ky-kinh-doanh"),
  "PublisherCode": code("Mã bên phát (T-CODE).", "ht-dkkd"),
  "SubscriberCode": code("Mã bên nhận (T-CODE).", "ht-thue"),
  "SubscriptionCode": code("Mã subscription; mặc định `{subscriberCode}-{entity}-{eventName}` (FR-10-035).", "ht-thue-dn-cap-phep"),
  "FlowCode": code("Mã luồng PH-04.", "dkkd-dong-bo-thue"),
  "PublicationCode": code("Sinh tự động `pub-{ULID}`.", "pub-01jd3y8k2m9p3q7r4t6v8w0y2z", f"^pub-{ULID}$", 30),
  "RequestCode": code("Sinh tự động `apr-{ULID}`.", "apr-01jd3y9b4c6d8e0f2g4h6j8k0m", f"^apr-{ULID}$", 30),
  "ReplayCode": code("Sinh tự động `rpl-{ULID}`.", "rpl-01jd3z0a1b2c3d4e5f6g7h8j9k", f"^rpl-{ULID}$", 30),
  "JobCode": code("Sinh tự động `imp-{ULID}`.", "imp-01jd3z1m2n3p4q5r6s7t8v9w0x", f"^imp-{ULID}$", 30),
  "BridgeCode": code("Sinh tự động `brg-{ULID}`.", "brg-01jd3z2a3b4c5d6e7f8g9h0j1k", f"^brg-{ULID}$", 30),
  "TopicName": STR(204, pattern="^(t[0-9]{2}|dh)\\.[a-z][a-z0-9-]*(\\.[a-z][a-z0-9-]*){2,4}\\.v[1-9][0-9]*(\\.dlq)?$",
      description="`{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}` chữ thường (BR-10-002), ≤ 200 ký tự; topic DLQ thêm `.dlq` (≤ 204); topic nền tảng tiền tố `dh.`.",
      examples=["t68.dkkd.doanh-nghiep.da-cap-phep.v1"]),
  "SystemCode": STR(63, description="Mã HTTT ở PH-01.", examples=["HT-DKKD"]),
  "OrgCode": STR(63, description="Mã tổ chức.", examples=["SO-KHDT"]),
  "ServiceCode": enum("dh-connect", "dh-integration", "dh-runtime", "dh-data", "dh-platform", "dh-payment", "dh-assist", "dh-portal", "dh-cdc", desc="DU nội bộ (A.2.12)."),
  "Reason": STR(500, minLength=10, description="Lý do 10…500 ký tự; thiếu trả ERR-10-009.", examples=["Hệ thống thuế bảo trì theo kế hoạch 26/11/2026."]),
  # ---------------- enum A.2
  "ProjectStatus": enum("ACTIVE", "ARCHIVED"),
  "TopicStatus": enum("DRAFT", "PENDING_APPROVAL", "PROVISIONING", "FAILED", "ACTIVE", "DEPRECATED", "RETIRED"),
  "TopicKind": enum("BUSINESS", "CDC", "SYSTEM", "DLQ"),
  "DataClass": enum("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE", desc="DD-08."),
  "CleanupPolicy": enum("DELETE", "COMPACT", "COMPACT_DELETE"),
  "SchemaVersionStatus": enum("DRAFT", "PENDING_APPROVAL", "REJECTED", "ENABLED", "DEPRECATED", "DISABLED"),
  "SchemaFormat": enum("AVRO", "JSON_SCHEMA"),
  "Compatibility": enum("BACKWARD", "BACKWARD_TRANSITIVE", "FORWARD", "FORWARD_TRANSITIVE", "FULL", "FULL_TRANSITIVE", "NONE"),
  "PiiSeverity": enum("INFO", "WARNING", "BLOCKING"),
  "PartyType": enum("SYSTEM", "FLOW", "INTERNAL_SERVICE", "LEGACY_BRIDGE"),
  "PartyStatus": enum("ACTIVE", "SUSPENDED", "RETIRED"),
  "SuspendSource": enum("MANUAL", "SECURITY", "PH01", "CIRCUIT_BREAKER", "DELIVERY_BLOCKED"),
  "PublicationStatus": enum("PENDING_APPROVAL", "REJECTED", "ACTIVE", "SUSPENDED", "REVOKED"),
  "SubscriptionStatus": enum("PENDING_APPROVAL", "REJECTED", "PROVISIONING", "FAILED", "ACTIVE", "PAUSED", "SUSPENDED", "REVOKED"),
  "DeliveryMode": enum("PUSH", "PULL_API", "PULL_KAFKA", "INTERNAL"),
  "StartPosition": enum("LATEST", "EARLIEST", "TIMESTAMP"),
  "FailurePolicy": enum("DEAD_LETTER", "BLOCK"),
  "PayloadFormat": enum("CLOUDEVENTS_STRUCTURED", "CLOUDEVENTS_BINARY"),
  "AlertState": enum("OK", "WARNING", "CRITICAL", "STALLED"),
  "SigningKeyStatus": enum("ACTIVE", "PREVIOUS", "REVOKED"),
  "VerificationResult": enum("PASSED", "FAILED", "WAIVED"),
  "CommTypeCode": enum("HTTP_PUBLISH", "KAFKA_NATIVE", "INTERNAL_KAFKA", "OUTBOX_CDC", "DB_CDC", "WEBHOOK_PUSH", "HTTP_PULL", "PULSAR_BRIDGE"),
  "Direction": enum("PUBLISH", "SUBSCRIBE", "BOTH"),
  "RoutingModeCode": enum("KEY_HASH", "ROUND_ROBIN", "SINGLE_PARTITION"),
  "Ordering": enum("PER_KEY", "NONE", "TOTAL"),
  "RequestType": enum("TOPIC_CREATE", "TOPIC_CHANGE", "TOPIC_RETIRE", "SCHEMA_VERSION", "PUBLICATION", "SUBSCRIPTION", "REPLAY", "BRIDGE", "CUTOVER"),
  "RequestStatus": enum("PENDING", "APPROVED", "REJECTED", "WITHDRAWN", "EXPIRED"),
  "TargetType": enum("TOPIC", "SCHEMA_VERSION", "PUBLICATION", "SUBSCRIPTION", "REPLAY", "BRIDGE", "MAPPING"),
  "DlqStatus": enum("NEW", "REPLAY_PENDING", "REPLAYED", "DISCARDED", "PURGED"),
  "DlqOrigin": enum("PUSH", "PULL_NACK", "EXTERNAL_REPORT", "REPLAY", "BRIDGE"),
  "ReplayStatus": enum("PENDING_APPROVAL", "REJECTED", "APPROVED", "RUNNING", "COMPLETED", "FAILED", "CANCELLED"),
  "ReplayMode": enum("REDELIVER_RANGE", "RESET_OFFSET", "DLQ_ENTRIES"),
  "RangeType": enum("OFFSET", "TIME", "ENTRIES"),
  "FailureClass": enum("TRANSIENT", "PERMANENT", "DESERIALIZATION", "SECURITY"),
  "ImportSourceKind": enum("EVENT_MANIFEST", "PULSAR_HUB"),
  "ImportStatus": enum("VALIDATING", "PREVIEW", "APPLYING", "APPLIED", "FAILED", "CANCELLED"),
  "ChangeKind": enum("CREATE", "UPDATE", "UNCHANGED", "CONFLICT", "SKIP"),
  "LegacyType": enum("PROJECT", "TOPIC", "PUBLISHER", "SUBSCRIBER", "PUBLICATION", "SUBSCRIPTION"),
  "MappingStatus": enum("PROPOSED", "PLANNED", "BRIDGING", "CUT_OVER", "ROLLED_BACK", "CLOSED", "SKIPPED"),
  "Confidence": enum("HIGH", "MEDIUM", "LOW"),
  "BridgeDirection": enum("PULSAR_TO_KAFKA", "KAFKA_TO_PULSAR"),
  "BridgeStartFrom": enum("LATEST", "EARLIEST"),
  "BridgeStatus": enum("PENDING_APPROVAL", "REJECTED", "RUNNING", "STOPPED", "ERROR", "EXPIRED"),
  "PermissionAction": enum("PUBLISH", "SUBSCRIBE"),
  "PermissionResult": enum("ALLOWED", "PENDING", "DENIED"),
  "PermissionReason": enum("TOPIC_NOT_FOUND", "TOPIC_NOT_ACTIVE", "NO_GRANT", "GRANT_SUSPENDED"),
  "GraphOverlay": enum("NONE", "LAG", "TRAFFIC", "DLQ"),
  # ---------------- chung
  "ProblemDetails": {
      "type": "object", "description": "RFC 9457 (`application/problem+json`), mở rộng theo D03-04-PH10 §6.3.",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {
          "type": STR(format="uri"), "title": STR(255), "status": INT(minimum=400, maximum=599), "detail": STR(2000), "instance": STR(512),
          "code": STR(pattern="^ERR-10-[0-9]{3}$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(obj({"field": STR(255), "rule": STR(64), "message": STR(500)})),
          "dependents": arr(obj({"kind": STR(32), "code": STR(204), "status": STR(32)}), description="Kèm ERR-10-010."),
          "failedIndex": INT(minimum=0, description="Chỉ mục sự kiện lỗi trong lô (API-10-079)."),
          "availableRange": arr(obj({"partition": INT(minimum=0), "fromOffset": LONG, "toOffset": LONG}), description="Kèm ERR-10-031, 033: khoảng còn dữ liệu."),
          "currentEtag": STR(64), "retryAfterSeconds": INT(minimum=1)},
      "additionalProperties": True},
  "StateChangeRequest": obj({"reason": R("Reason")}, req=["reason"]),
  "Labels": arr(STR(63, pattern=CODE_RE), maxItems=10),
  # ---------------- A. dự án
  "Project": obj({
      "projectCode": R("ProjectCode"), "name": STR(255), "description": TEXT, "ownerOrgCode": R("OrgCode"), "ownerUser": STR(63),
      "status": R("ProjectStatus"), "labels": R("Labels"), "archivedAt": nul(TS), "archiveReason": nul(TEXT),
      "topicCount": INT(minimum=0), "publisherCount": INT(minimum=0), "subscriberCount": INT(minimum=0), "maxLagSeconds": nul(INT(minimum=0)), **AUDIT},
      req=["projectCode", "name", "ownerOrgCode", "status", "version"]),
  "ProjectPage": obj({"items": arr(R("Project")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "ownerOrgCode": CNT})}, req=["items", "page", "size", "totalElements"]),
  "ProjectCreate": obj({"projectCode": R("ProjectCode"), "name": STR(255, minLength=3), "description": TEXT, "ownerOrgCode": R("OrgCode"),
      "ownerUser": STR(63), "labels": R("Labels")}, req=["projectCode", "name", "ownerOrgCode"]),
  "ProjectUpdate": obj({"name": STR(255, minLength=3), "description": TEXT, "ownerOrgCode": R("OrgCode"), "ownerUser": STR(63), "labels": R("Labels")},
      desc="Mã dự án bất biến."),
  # ---------------- sơ đồ
  "GraphNode": obj({"id": STR(255), "kind": enum("PUBLISHER", "TOPIC", "SUBSCRIBER"), "code": STR(204), "label": STR(255), "status": STR(32),
      "partyType": R("PartyType"), "systemCode": R("SystemCode"), "lagSeconds": nul(INT(minimum=0)), "ratePerMinute": nul(NUM), "dlqNewCount": INT(minimum=0)},
      req=["id", "kind", "code", "label", "status"]),
  "GraphEdge": obj({"from": STR(255), "to": STR(255), "kind": enum("PUBLICATION", "SUBSCRIPTION"), "code": STR(63), "status": STR(32),
      "deliveryMode": R("DeliveryMode"), "alertState": R("AlertState"), "lagSeconds": nul(INT(minimum=0)), "ratePerMinute": nul(NUM)},
      req=["from", "to", "kind", "code", "status"]),
  "Graph": obj({"nodes": arr(R("GraphNode")), "edges": arr(R("GraphEdge")), "overlay": R("GraphOverlay"), "generatedAt": TS},
      req=["nodes", "edges", "overlay"]),
  # ---------------- B. topic
  "SchemaDraft": obj({"schemaFormat": R("SchemaFormat"), "content": STR(262144, description="Nội dung Avro (`.avsc`) hoặc JSON Schema; ≤ 256 KiB."),
      "compatibility": R("Compatibility"), "changeNote": STR(1000)}, req=["schemaFormat", "content"]),
  "Topic": obj({
      "topicName": R("TopicName"), "projectCode": nul(R("ProjectCode")), "topicKind": R("TopicKind"), "domain": STR(63), "entity": STR(63),
      "eventName": STR(63), "majorVersion": INT(minimum=1), "description": TEXT, "partitions": INT(minimum=1, maximum=200),
      "replicationFactor": INT(const=3), "minInsyncReplicas": INT(const=2), "retentionHours": INT(minimum=1, maximum=2160),
      "cleanupPolicy": R("CleanupPolicy"), "maxMessageBytes": INT(minimum=1024, maximum=1048576), "routingMode": R("RoutingModeCode"),
      "partitionKeyField": nul(STR(255)), "orderingRequired": BOOL, "dataClass": R("DataClass"), "status": R("TopicStatus"),
      "predecessorTopic": nul(R("TopicName")), "successorTopic": nul(R("TopicName")), "sunsetAt": nul(TS),
      "provisioningCommit": nul(STR(64, pattern="^[0-9a-f]{7,64}$")), "provisioningError": nul(TEXT), "activatedAt": nul(TS), "retiredAt": nul(TS),
      "ownerServiceCode": nul(R("ServiceCode")), "sourceRef": nul(ANYOBJ), "latestSchemaVersion": nul(INT(minimum=1)),
      "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["topicName", "topicKind", "partitions", "retentionHours", "cleanupPolicy", "routingMode", "dataClass", "status", "version"]),
  "TopicPage": obj({"items": arr(R("Topic")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "topicKind": CNT, "dataClass": CNT})}, req=["items", "page", "size", "totalElements"]),
  "TopicCreate": obj({
      "projectCode": R("ProjectCode"), "domain": STR(31, pattern="^[a-z][a-z0-9-]{1,30}$"), "entity": STR(41, pattern="^[a-z][a-z0-9-]{1,40}$"),
      "eventName": STR(41, pattern="^[a-z][a-z0-9-]{1,40}$"), "description": STR(2000, minLength=10), "partitions": INT(minimum=1, maximum=200),
      "retentionHours": INT(minimum=1, maximum=2160), "cleanupPolicy": R("CleanupPolicy"), "routingMode": R("RoutingModeCode"),
      "partitionKeyField": STR(255, description="Đường dẫn trường trong `data` hoặc `$subject`."), "orderingRequired": BOOL, "dataClass": R("DataClass"),
      "maxMessageBytes": INT(minimum=1024, maximum=1048576), "schema": R("SchemaDraft"), "submit": BOOL,
      "topicKind": enum("BUSINESS", "CDC", "SYSTEM", desc="Chỉ tài khoản dịch vụ (`event:topic-register`) gửi `CDC`, `SYSTEM`; người dùng luôn `BUSINESS`."),
      "topicName": R("TopicName"), "onBehalfOf": STR(63, description="Người chịu trách nhiệm khi máy đăng ký (FR-10-066)."),
      "sourceRef": ANYOBJ},
      req=["description", "dataClass", "schema"],
      desc="Người dùng gửi `projectCode`, `domain`, `entity`, `eventName`; máy gửi `topicKind` và `topicName` đầy đủ (FR-10-066, 067)."),
  "TopicUpdate": obj({"description": STR(2000, minLength=10), "partitions": INT(minimum=1, maximum=200), "retentionHours": INT(minimum=1, maximum=2160),
      "cleanupPolicy": R("CleanupPolicy"), "routingMode": R("RoutingModeCode"), "partitionKeyField": STR(255), "orderingRequired": BOOL,
      "dataClass": R("DataClass"), "maxMessageBytes": INT(minimum=1024, maximum=1048576)},
      desc="Topic `ACTIVE`, `DEPRECATED` chỉ sửa `description`; trường khác chỉ khi `DRAFT` (ngược lại ERR-10-006, dùng API-10-015)."),
  "TopicChangeRequest": obj({"partitions": INT(minimum=1, maximum=200), "retentionHours": INT(minimum=1, maximum=2160), "cleanupPolicy": R("CleanupPolicy"),
      "maxMessageBytes": INT(minimum=1024, maximum=1048576), "routingMode": R("RoutingModeCode"), "partitionKeyField": STR(255),
      "compatibility": R("Compatibility"), "acknowledgeOrderingImpact": BOOL, "acknowledgeDataLoss": BOOL, "plannedAt": TS, "reason": R("Reason")},
      req=["reason"], desc="Ít nhất một trường cấu hình. Tăng lưu giữ, tăng `maxMessageBytes` áp dụng ngay; phần còn lại tạo yêu cầu `TOPIC_CHANGE`."),
  "ImpactedSubscription": obj({"subscriptionCode": R("SubscriptionCode"), "subscriberCode": R("SubscriberCode"), "lagSeconds": INT(minimum=0)},
      req=["subscriptionCode", "lagSeconds"]),
  "TopicChangeResult": obj({"topic": R("Topic"), "approvalRequest": nul(R("ApprovalRequest")), "impactedSubscriptions": arr(R("ImpactedSubscription"))},
      req=["topic"]),
  "DeprecateRequest": obj({"reason": R("Reason"), "successorTopic": R("TopicName"), "sunsetAt": TS, "migrationNote": STR(2000)}, req=["reason"]),
  "NewMajorVersionRequest": obj({"schema": R("SchemaDraft"), "partitions": INT(minimum=1, maximum=200), "migrationNote": STR(2000),
      "sunsetDays": INT(minimum=14, maximum=365), "reason": R("Reason"), "onBehalfOf": STR(63)}, req=["schema", "reason"]),
  "MigrationStatusItem": obj({"subscriptionCode": R("SubscriptionCode"), "subscriberCode": R("SubscriberCode"), "deliveryMode": R("DeliveryMode"),
      "status": R("SubscriptionStatus"), "lagSeconds": nul(INT(minimum=0)), "successorSubscriptionCode": nul(R("SubscriptionCode")),
      "successorStatus": nul(R("SubscriptionStatus"))}, req=["subscriptionCode", "subscriberCode", "status"]),
  "MigrationStatus": obj({"topicName": R("TopicName"), "successorTopic": nul(R("TopicName")), "sunsetAt": nul(TS),
      "items": arr(R("MigrationStatusItem"))}, req=["topicName", "items"]),
  "ConnectionInfo": obj({"topicName": R("TopicName"), "httpPublishUrl": STR(2048, format="uri"), "httpPullUrlTemplate": STR(2048),
      "kafkaBootstrap": nul(STR(512)), "kafkaListener": enum("internal", "external"), "saslMechanism": enum("OAUTHBEARER", "MTLS"),
      "tokenUrl": STR(2048, format="uri"), "registryUrl": STR(2048, format="uri"), "apicurioGroupId": STR(63), "apicurioArtifactId": R("TopicName"),
      "consumerGroupTemplate": STR(255), "sampleConfigs": {"type": "object", "additionalProperties": STR(8192),
          "description": "Khóa `java`, `dotnet`, `python`, `nodejs`; không chứa bí mật."}},
      req=["topicName", "httpPublishUrl", "registryUrl", "apicurioGroupId", "apicurioArtifactId"]),
  # ---------------- C. lược đồ
  "PiiFinding": obj({"field": STR(255), "severity": R("PiiSeverity"), "rule": STR(64), "message": STR(500)}, req=["field", "severity"]),
  "CompatibilityReport": obj({"compatible": BOOL, "compatibility": R("Compatibility"), "comparedVersions": arr(INT(minimum=1)),
      "messages": arr(STR(1000))}, req=["compatible"]),
  "EventSchema": obj({"topicName": R("TopicName"), "schemaFormat": R("SchemaFormat"), "compatibility": R("Compatibility"),
      "apicurioGroupId": STR(63), "apicurioArtifactId": R("TopicName"), "latestVersionNo": INT(minimum=0), **AUDIT},
      req=["topicName", "schemaFormat", "compatibility", "apicurioGroupId", "apicurioArtifactId", "latestVersionNo"]),
  "SchemaVersion": obj({"topicName": R("TopicName"), "versionNo": INT(minimum=1), "content": STR(262144), "contentHash": STR(64, pattern="^[0-9a-f]{64}$"),
      "status": R("SchemaVersionStatus"), "apicurioGlobalId": nul(LONG), "apicurioContentId": nul(LONG),
      "compatibilityReport": nul(R("CompatibilityReport")), "piiFindings": arr(R("PiiFinding")), "changeNote": nul(STR(1000)),
      "checkedAt": nul(TS), "enabledAt": nul(TS), "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["topicName", "versionNo", "status", "contentHash"]),
  "SchemaVersionList": obj({"items": arr(R("SchemaVersion")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG},
      req=["items", "page", "size", "totalElements"]),
  "SchemaVersionCreate": obj({"content": STR(262144), "changeNote": STR(1000), "submit": BOOL, "onBehalfOf": STR(63)}, req=["content"],
      desc="Định dạng theo `EventSchema.schemaFormat` của topic (khác định dạng trả ERR-10-020)."),
  "SchemaVersionUpdate": obj({"content": STR(262144), "changeNote": STR(1000)}, req=["content"]),
  "SchemaDiffChange": obj({"path": STR(512), "change": enum("ADDED", "REMOVED", "CHANGED"), "before": {}, "after": {}, "breaking": BOOL},
      req=["path", "change"]),
  "SchemaDiff": obj({"topicName": R("TopicName"), "from": INT(minimum=1), "to": INT(minimum=1), "compatible": BOOL, "changes": arr(R("SchemaDiffChange"))},
      req=["topicName", "from", "to", "changes"]),
  "ComplianceItem": obj({"publicationCode": R("PublicationCode"), "publisherCode": R("PublisherCode"), "sampledCount": LONG, "violationCount": LONG,
      "lastViolationAt": nul(TS), "lastErrorCode": nul(STR(16, pattern="^ERR-10-1[0-9]{2}$"))}, req=["publicationCode", "sampledCount", "violationCount"]),
  "Compliance": obj({"topicName": R("TopicName"), "windowStart": TS, "windowEnd": TS, "sampleRatio": NUM, "items": arr(R("ComplianceItem"))},
      req=["topicName", "items"]),
  # ---------------- D. bên phát, bên nhận
  "PartyBase": obj({"name": STR(255), "description": nul(TEXT), "partyType": R("PartyType"), "systemCode": nul(R("SystemCode")), "flowCode": nul(R("FlowCode")),
      "serviceCode": nul(R("ServiceCode")), "commType": R("CommTypeCode"), "referenceKey": nul(STR(255)), "clientId": nul(STR(255)),
      "kafkaPrincipal": nul(STR(255, pattern="^User:")), "status": R("PartyStatus"), "suspendSource": nul(R("SuspendSource")),
      "suspendReason": nul(STR(1000)), "lastActiveAt": nul(TS), **AUDIT}, req=["name", "partyType", "commType", "status", "version"]),
  "Publisher": ext("PartyBase", {"publisherCode": R("PublisherCode"), "publicationCounts": CNT}, req=["publisherCode"]),
  "Subscriber": ext("PartyBase", {"subscriberCode": R("SubscriberCode"), "isFlow": BOOL, "subscriptionCounts": CNT}, req=["subscriberCode"]),
  "PublisherPage": obj({"items": arr(R("Publisher")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "partyType": CNT, "commType": CNT})}, req=["items", "page", "size", "totalElements"]),
  "SubscriberPage": obj({"items": arr(R("Subscriber")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "partyType": CNT, "commType": CNT})}, req=["items", "page", "size", "totalElements"]),
  "PartyCreateBase": obj({"name": STR(255, minLength=3), "description": TEXT, "partyType": enum("SYSTEM", "FLOW", "INTERNAL_SERVICE"),
      "systemCode": R("SystemCode"), "flowCode": R("FlowCode"), "serviceCode": R("ServiceCode"), "commType": R("CommTypeCode"),
      "referenceKey": STR(255)}, req=["name", "partyType", "commType"],
      desc="Đúng một trong `systemCode`, `flowCode`, `serviceCode` theo `partyType`; tổ hợp với `commType` theo A.2.8 (ERR-10-003). `LEGACY_BRIDGE` chỉ hệ thống tạo (FR-10-073)."),
  "PublisherCreate": {"allOf": [R("PartyCreateBase"), obj({"publisherCode": R("PublisherCode")}, req=["publisherCode"])]},
  "SubscriberCreate": {"allOf": [R("PartyCreateBase"), obj({"subscriberCode": R("SubscriberCode")}, req=["subscriberCode"])]},
  "PartyUpdate": obj({"name": STR(255, minLength=3), "description": TEXT, "referenceKey": STR(255)},
      desc="Mã, `partyType`, đối tượng gắn, `commType` bất biến (FR-10-028)."),
  # ---------------- E. publication
  "Publication": obj({"publicationCode": R("PublicationCode"), "publisherCode": R("PublisherCode"), "topicName": R("TopicName"), "purpose": TEXT,
      "expectedRatePerMinute": nul(INT(minimum=0)), "quotaBytesPerSecond": nul(INT(minimum=262144)), "status": R("PublicationStatus"),
      "grantedScope": nul(STR(255, pattern="^topic:.+:publish$")), "aclRef": nul(STR(512)), "suspendSource": nul(R("SuspendSource")),
      "approvedBy": nul(USER), "approvedAt": nul(TS), "revokedAt": nul(TS), "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["publicationCode", "publisherCode", "topicName", "purpose", "status", "version"]),
  "PublicationPage": obj({"items": arr(R("Publication")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT})}, req=["items", "page", "size", "totalElements"]),
  "PublicationCreate": obj({"publisherCode": R("PublisherCode"), "topicName": R("TopicName"), "purpose": STR(500, minLength=10),
      "expectedRatePerMinute": INT(minimum=0), "quotaBytesPerSecond": INT(minimum=262144)}, req=["publisherCode", "topicName", "purpose"]),
  # ---------------- F. subscription
  "RetryBackoff": obj({"initialMs": INT(minimum=100, maximum=60000), "multiplier": {"type": "number", "minimum": 1, "maximum": 5}, "maxMs": INT(minimum=1000, maximum=3600000)},
      req=["initialMs", "multiplier", "maxMs"], desc="Giãn cách thử lại (FR-10-035, 039); `maxMs` ≥ `initialMs`, sai trả ERR-10-012."),
  "VerificationStep": obj({"name": enum("DNS", "TLS", "HANDSHAKE", "TEST_EVENT"), "result": enum("PASSED", "FAILED", "SKIPPED"),
      "detail": STR(1000)}, req=["name", "result"]),
  "EndpointVerification": obj({"result": R("VerificationResult"), "checkedAt": TS, "steps": arr(R("VerificationStep"))}, req=["result", "checkedAt"],
      desc="Cấu trúc `push.lastVerification` (A.3)."),
  "PushConfig": obj({"endpointUrl": STR(2048, pattern="^https://[^/@\\s]+(/[^\\s]*)?$"), "workerCount": INT(minimum=1, maximum=64),
      "maxRetries": INT(minimum=0, maximum=50), "retryBackoff": R("RetryBackoff"), "timeoutMs": INT(minimum=1000, maximum=30000),
      "failurePolicy": R("FailurePolicy"), "payloadFormat": R("PayloadFormat"), "endpointVerifiedAt": nul(TS),
      "verificationWaiverUntil": nul(TS), "verificationWaiverReason": nul(STR(500)), "lastVerification": nul(R("EndpointVerification"))},
      req=["endpointUrl"], desc="Không bao giờ chứa bí mật ký (BR-10-027)."),
  "PullConfig": obj({"maxBatch": INT(minimum=1, maximum=1000), "leaseSeconds": INT(minimum=10, maximum=300)}),
  "SigningKey": obj({"keyId": STR(64, pattern="^[a-z0-9][a-z0-9-]{2,63}$"), "status": R("SigningKeyStatus"), "activatedAt": TS,
      "previousUntil": nul(TS), "revokedAt": nul(TS)}, req=["keyId", "status"], desc="Chỉ siêu dữ liệu; giá trị khóa nằm ở OpenBao."),
  "Subscription": obj({"subscriptionCode": R("SubscriptionCode"), "subscriberCode": R("SubscriberCode"), "topicName": R("TopicName"),
      "deliveryMode": R("DeliveryMode"), "purpose": TEXT, "legalBasis": nul(TEXT), "consumerGroup": STR(255), "startPosition": R("StartPosition"),
      "startAt": nul(TS), "status": R("SubscriptionStatus"), "suspendSource": nul(R("SuspendSource")), "suspendReason": nul(STR(1000)),
      "lagWarnSeconds": INT(minimum=30, maximum=86400), "lagCriticalSeconds": INT(minimum=60, maximum=604800), "alertState": R("AlertState"),
      "alertAcknowledgedBy": nul(USER), "alertAcknowledgedAt": nul(TS), "alertAckNote": nul(STR(1000)), "approvedBy": nul(USER), "approvedAt": nul(TS),
      "push": nul(R("PushConfig")), "pull": nul(R("PullConfig")), "quotaBytesPerSecond": nul(INT(minimum=262144)),
      "signingKeys": arr(R("SigningKey")), "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["subscriptionCode", "subscriberCode", "topicName", "deliveryMode", "consumerGroup", "status", "alertState", "version"]),
  "SubscriptionPage": obj({"items": arr(R("Subscription")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "deliveryMode": CNT, "alertState": CNT})}, req=["items", "page", "size", "totalElements"]),
  "PushInput": obj({"endpointUrl": STR(2048, pattern="^https://[^/@\\s]+(/[^\\s]*)?$"), "workerCount": INT(minimum=1, maximum=64),
      "maxRetries": INT(minimum=0, maximum=50), "retryBackoff": R("RetryBackoff"), "timeoutMs": INT(minimum=1000, maximum=30000),
      "failurePolicy": R("FailurePolicy"), "payloadFormat": R("PayloadFormat")}, req=["endpointUrl"]),
  "SubscriptionCreate": obj({"subscriptionCode": R("SubscriptionCode"), "subscriberCode": R("SubscriberCode"), "topicName": R("TopicName"),
      "deliveryMode": R("DeliveryMode"), "purpose": STR(500, minLength=10), "legalBasis": STR(1000, minLength=10),
      "startPosition": R("StartPosition"), "startAt": TS, "push": R("PushInput"), "pull": R("PullConfig"),
      "lagWarnSeconds": INT(minimum=30, maximum=86400), "lagCriticalSeconds": INT(minimum=60, maximum=604800), "quotaBytesPerSecond": INT(minimum=262144)},
      req=["subscriberCode", "topicName", "deliveryMode", "purpose"]),
  "SubscriptionUpdate": obj({"purpose": STR(500, minLength=10), "push": {"allOf": [R("PushInput")], "description": "Đổi `endpointUrl` chạy lại xác minh (FR-10-036)."},
      "pull": R("PullConfig"), "lagWarnSeconds": INT(minimum=30, maximum=86400), "lagCriticalSeconds": INT(minimum=60, maximum=604800),
      "quotaBytesPerSecond": INT(minimum=262144)}, desc="Chế độ giao nhận, topic, bên nhận bất biến."),
  "EndpointVerificationRequest": obj({"endpointUrl": STR(2048, pattern="^https://[^/@\\s]+(/[^\\s]*)?$"), "subscriptionCode": R("SubscriptionCode"),
      "timeoutMs": INT(minimum=1000, maximum=30000)}, req=["endpointUrl"]),
  "WaiverRequest": obj({"reason": R("Reason"), "waiverUntil": TS}, req=["reason", "waiverUntil"],
      desc="`waiverUntil` ≤ 180 ngày từ hiện tại (ERR-10-012); ghi `push.verificationWaiverUntil`, `push.verificationWaiverReason`."),
  "DeliveryStat": obj({"windowStart": TS, "successCount": LONG, "transientErrorCount": LONG, "retryCount": LONG, "deadLetterCount": LONG,
      "latencyP50Ms": nul(INT(minimum=0)), "latencyP95Ms": nul(INT(minimum=0))}, req=["windowStart", "successCount"]),
  "WorkerState": obj({"worker": INT(minimum=0), "partitions": arr(INT(minimum=0)), "committedOffsets": {"type": "object", "additionalProperties": LONG},
      "lastDeliveredAt": nul(TS)}, req=["worker", "partitions"]),
  "DeliveryStats": obj({"subscriptionCode": R("SubscriptionCode"), "window": enum("1h", "24h", "7d"), "items": arr(R("DeliveryStat")),
      "workers": arr(R("WorkerState"))}, req=["subscriptionCode", "window", "items"]),
  "DeliveryFailure": obj({"subscriptionCode": R("SubscriptionCode"), "occurredAt": TS, "partition": INT(minimum=0), "offset": LONG,
      "eventId": STR(255), "httpStatus": nul(INT(minimum=100, maximum=599)), "errorCode": STR(16, pattern="^ERR-10-1[0-9]{2}$"),
      "failureClass": R("FailureClass"), "attempt": INT(minimum=1), "responseSnippet": nul(STR(512))},
      req=["occurredAt", "partition", "offset", "errorCode", "failureClass", "attempt"]),
  "DeliveryFailurePage": obj({"items": arr(R("DeliveryFailure")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG},
      req=["items", "page", "size", "totalElements"]),
  "SigningKeyRotateRequest": obj({"reason": STR(500)}),
  "SigningKeyIssued": obj({"subscriptionCode": R("SubscriptionCode"), "keyId": STR(64), "status": R("SigningKeyStatus"), "activatedAt": TS,
      "previousUntil": nul(TS),
      "secret": STR(128, pattern="^whsec_", readOnly=True, description="Khóa ký, hiển thị một lần duy nhất trong phản hồi này; không lưu ở PostgreSQL, không ghi log (BR-10-027).")},
      req=["subscriptionCode", "keyId", "status", "secret"]),
  "LagSample": obj({"partition": INT(minimum=0), "lagRecords": LONG, "lagSeconds": INT(minimum=0), "committedOffset": nul(LONG), "endOffset": LONG,
      "sampledAt": TS}, req=["partition", "lagRecords", "lagSeconds", "endOffset", "sampledAt"]),
  "Lag": obj({"subscriptionCode": R("SubscriptionCode"), "consumerGroup": STR(255), "alertState": R("AlertState"), "lagRecords": LONG,
      "lagSeconds": INT(minimum=0), "lagWarnSeconds": INT(minimum=30), "lagCriticalSeconds": INT(minimum=60),
      "retentionRemainingSeconds": nul(INT()), "partitions": arr(R("LagSample")),
      "series": arr(obj({"sampledAt": TS, "lagRecords": LONG, "lagSeconds": INT(minimum=0)}))},
      req=["subscriptionCode", "consumerGroup", "alertState", "lagRecords", "lagSeconds", "partitions"]),
  "LagAckRequest": obj({"alertAckNote": STR(1000, minLength=5)}, req=["alertAckNote"]),
  # ---------------- yêu cầu duyệt
  "ApprovalRequest": obj({"requestCode": R("RequestCode"), "requestType": R("RequestType"), "targetType": R("TargetType"), "targetCode": STR(204),
      "payloadDiff": ANYOBJ, "checks": ANYOBJ, "status": R("RequestStatus"), "requestedBy": USER, "requestedAt": TS, "decidedBy": nul(USER),
      "decidedAt": nul(TS), "decisionComment": nul(STR(2000)), "autoApproved": BOOL, "version": INT(minimum=0)},
      req=["requestCode", "requestType", "targetType", "targetCode", "status", "requestedBy", "requestedAt", "autoApproved"]),
  "ApprovalRequestPage": obj({"items": arr(R("ApprovalRequest")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"requestType": CNT, "status": CNT})}, req=["items", "page", "size", "totalElements"]),
  "ApproveRequest": obj({"comment": STR(2000, minLength=1), "acknowledgePii": BOOL, "acknowledgeDataLoss": BOOL}, req=["comment"],
      desc="`comment` ghi vào `decisionComment`. `acknowledgePii` bắt buộc khi có phát hiện mức WARNING; `acknowledgeDataLoss` khi `impactedSubscriptions` khác rỗng."),
  "RejectRequest": obj({"comment": STR(2000, minLength=10)}, req=["comment"]),
  # ---------------- G. DLQ, phát lại
  "DlqEntry": obj({"dlqEntryId": UUID, "subscriptionCode": nul(R("SubscriptionCode")), "sourceTopic": R("TopicName"), "sourcePartition": nul(INT(minimum=0)),
      "sourceOffset": nul(LONG), "eventId": nul(STR(255)), "eventType": nul(STR(255)), "eventSubject": nul(STR(255)), "origin": R("DlqOrigin"),
      "bridgeCode": nul(R("BridgeCode")), "errorCode": STR(16, pattern="^ERR-10-1[0-9]{2}$"), "errorDetail": nul(TEXT), "attempts": INT(minimum=1),
      "firstFailedAt": TS, "lastFailedAt": TS, "status": R("DlqStatus"), "resolvedBy": nul(USER), "resolvedAt": nul(TS), "resolveReason": nul(TEXT),
      "replayCode": nul(R("ReplayCode")), "payloadRef": nul(STR(255)), "payloadPurgedAt": nul(TS), "version": INT(minimum=0)},
      req=["dlqEntryId", "sourceTopic", "origin", "errorCode", "attempts", "firstFailedAt", "lastFailedAt", "status"]),
  "DlqEntryPage": obj({"items": arr(R("DlqEntry")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "errorCode": CNT})}, req=["items", "page", "size", "totalElements"]),
  "DlqEntryList": obj({"items": arr(R("DlqEntry"))}, req=["items"]),
  "DlqPayload": obj({"dlqEntryId": UUID, "key": nul(STR(1024)), "headers": {"type": "object", "additionalProperties": STR(4096)},
      "data": {"description": "`data` đã giải mã theo lược đồ (JSON); null khi không giải được (ERR-10-116)."},
      "dataBase64": nul(STR(contentEncoding="base64", description="Giá trị nhị phân gốc khi không giải mã được.")), "masked": BOOL},
      req=["dlqEntryId", "headers"]),
  "DiscardRequest": obj({"dlqEntryIds": arr(UUID, minItems=1, maxItems=1000, uniqueItems=True), "reason": R("Reason")}, req=["dlqEntryIds", "reason"]),
  "ReplayPartition": obj({"partition": INT(minimum=0), "fromOffset": LONG, "toOffset": LONG}, req=["partition", "fromOffset"]),
  "ReplayRequest": obj({"replayCode": R("ReplayCode"), "subscriptionCode": R("SubscriptionCode"), "replayMode": R("ReplayMode"), "rangeType": R("RangeType"),
      "fromTime": nul(TS), "toTime": nul(TS), "partitions": nul(arr(R("ReplayPartition"))), "dlqEntryIds": nul(arr(UUID)),
      "targetEndpointUrl": nul(STR(2048)), "ratePerSecond": INT(minimum=1, maximum=10000), "estimatedRecords": nul(LONG), "deliveredRecords": LONG,
      "failedRecords": LONG, "previousOffsets": nul(ANYOBJ), "reason": TEXT, "status": R("ReplayStatus"), "startedAt": nul(TS), "finishedAt": nul(TS),
      "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["replayCode", "subscriptionCode", "replayMode", "rangeType", "ratePerSecond", "reason", "status", "version"]),
  "ReplayPage": obj({"items": arr(R("ReplayRequest")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "replayMode": CNT})}, req=["items", "page", "size", "totalElements"]),
  "ReplayCreate": obj({"subscriptionCode": R("SubscriptionCode"), "replayMode": R("ReplayMode"), "rangeType": R("RangeType"), "fromTime": TS, "toTime": TS,
      "partitions": arr(R("ReplayPartition"), minItems=1), "dlqEntryIds": arr(UUID, minItems=1, uniqueItems=True),
      "targetEndpointUrl": STR(2048, pattern="^https://"), "ratePerSecond": INT(minimum=1, maximum=10000), "reason": R("Reason"),
      "acknowledgeDuplicates": BOOL, "acknowledgeSkip": BOOL},
      req=["subscriptionCode", "replayMode", "rangeType", "reason", "acknowledgeDuplicates"],
      desc="`TIME` cần `fromTime` (và `toTime` trừ `RESET_OFFSET`); `OFFSET` cần `partitions`; `DLQ_ENTRIES` đi với `rangeType = ENTRIES` và `dlqEntryIds`."),
  # ---------------- H. dashboard
  "Dashboard": obj({
      "counts": obj({"publishers": CNT, "subscribers": CNT, "projects": CNT, "topics": CNT}),
      "traffic": nul(obj({"inPerMinute": NUM, "outPerMinute": NUM, "topTopics": arr(obj({"topicName": R("TopicName"), "inPerMinute": NUM}), maxItems=10)})),
      "lag": obj({"byAlertState": CNT, "top": arr(obj({"subscriptionCode": R("SubscriptionCode"), "lagSeconds": INT(minimum=0), "alertState": R("AlertState")}), maxItems=10)}),
      "dlq": obj({"newByTopic": arr(obj({"topicName": R("TopicName"), "count": INT(minimum=0)})), "trend7d": arr(obj({"day": s("string", format="date"), "count": INT(minimum=0)}))}),
      "pendingApprovals": CNT,
      "deprecatedSoon": arr(obj({"topicName": R("TopicName"), "sunsetAt": TS})),
      "failedTopics": arr(R("TopicName")),
      "quotaUsage": {"type": "object", "additionalProperties": NUM, "description": "Tỷ lệ dùng 0…1 theo khóa của TenantEventQuota."},
      "generatedAt": TS}, req=["counts", "lag", "dlq", "pendingApprovals", "generatedAt"]),
  # ---------------- I. danh mục, hạn mức, tham số
  "CommType": obj({"commTypeCode": R("CommTypeCode"), "name": STR(255), "direction": R("Direction"), "allowedPartyTypes": arr(R("PartyType"), minItems=1),
      "deliveryMode": nul(R("DeliveryMode")), "legacyCode": nul(STR(32)), "enabled": BOOL, "inUseCount": INT(minimum=0)},
      req=["commTypeCode", "name", "direction", "allowedPartyTypes", "enabled"]),
  "CommTypeList": obj({"items": arr(R("CommType"))}, req=["items"]),
  "RoutingMode": obj({"routingModeCode": R("RoutingModeCode"), "name": STR(255), "ordering": R("Ordering"), "legacyCode": nul(STR(32)), "enabled": BOOL,
      "inUseCount": INT(minimum=0)}, req=["routingModeCode", "name", "ordering", "enabled"]),
  "RoutingModeList": obj({"items": arr(R("RoutingMode"))}, req=["items"]),
  "CatalogToggle": obj({"enabled": BOOL, "reason": R("Reason")}, req=["enabled", "reason"]),
  "QuotaValues": obj({"maxProjects": INT(minimum=1), "maxTopics": INT(minimum=1), "maxPartitionsTotal": INT(minimum=1),
      "produceBytesPerSecond": INT(minimum=1048576), "consumeBytesPerSecond": INT(minimum=1048576), "maxRetentionHours": INT(minimum=24, maximum=2160),
      "maxSubscriptions": INT(minimum=1), "maxPushWorkersTotal": INT(minimum=1)}),
  "TenantEventQuota": {"allOf": [R("QuotaValues"), obj({"ceilingSetBy": nul(USER), "usage": R("QuotaValues"), "version": INT(minimum=0)})]},
  "QuotaUpdate": {"allOf": [R("QuotaValues"), obj({"reason": R("Reason")}, req=["reason"])],
      "description": "PA đặt trần; TA chỉ phân bổ trong trần (vượt trần ERR-10-012, thấp hơn mức đang dùng ERR-10-011)."},
  "Settings": obj({"params": {"type": "object", "additionalProperties": {"type": ["string", "number", "integer", "boolean"]},
      "description": "Tham số `10.*` hiệu lực (FRS A.5), khóa đủ tên, ví dụ `10.push.max-retries`."}, "version": INT(minimum=0)}, req=["params"]),
  "SettingsUpdate": obj({"params": {"type": "object", "minProperties": 1, "propertyNames": {"pattern": "^10\\.[a-z-]+(\\.[a-z-]+)+$"},
      "additionalProperties": {"type": ["string", "number", "integer", "boolean"]}}, "reason": R("Reason")}, req=["params", "reason"]),
  # ---------------- J. máy với máy
  "PermissionCheckItem": obj({"flowCode": R("FlowCode"), "topicName": R("TopicName"), "action": R("PermissionAction")}, req=["flowCode", "topicName", "action"]),
  "PermissionCheckRequest": obj({"environment": STR(16, description="Môi trường của PH-04 (`TEST`, `STAGING`, `PROD`)."),
      "items": arr(R("PermissionCheckItem"), minItems=1, maxItems=200)}, req=["items"]),
  "PermissionCheckResultItem": {"allOf": [R("PermissionCheckItem"), obj({"result": R("PermissionResult"), "reason": nul(R("PermissionReason")),
      "consumerGroup": nul(STR(255)), "publicationCode": nul(R("PublicationCode")), "subscriptionCode": nul(R("SubscriptionCode"))}, req=["result"])]},
  "PermissionCheckResponse": obj({"items": arr(R("PermissionCheckResultItem"))}, req=["items"]),
  "EnsurePartyRequest": obj({"items": arr(obj({"topicName": R("TopicName"), "action": R("PermissionAction")}, req=["topicName", "action"]), minItems=1, maxItems=100),
      "onBehalfOf": STR(63)}, req=["items", "onBehalfOf"]),
  "EnsurePartyResponse": obj({"flowCode": R("FlowCode"), "publisherCode": nul(R("PublisherCode")), "subscriberCode": nul(R("SubscriberCode")),
      "items": arr(R("PermissionCheckResultItem")), "approvalRequestCodes": arr(R("RequestCode"))}, req=["flowCode", "items"]),
  "FlowDependencies": obj({"flowCode": R("FlowCode"), "publications": arr(R("Publication")), "subscriptions": arr(R("Subscription"))},
      req=["flowCode", "publications", "subscriptions"]),
  "RuntimeTopic": obj({"topicName": R("TopicName"), "status": R("TopicStatus"), "routingMode": R("RoutingModeCode"), "partitionKeyField": nul(STR(255)),
      "orderingRequired": BOOL, "maxMessageBytes": INT(minimum=1024), "apicurioGroupId": STR(63), "apicurioArtifactId": R("TopicName"),
      "enabledVersions": arr(INT(minimum=1), description="Phiên bản lược đồ `ENABLED`, `DEPRECATED`."),
      "publishers": arr(obj({"publicationCode": R("PublicationCode"), "clientId": nul(STR(255)), "sources": arr(STR(512))}, req=["publicationCode"])),
      "configVersion": INT(minimum=0)}, req=["topicName", "status", "routingMode", "configVersion"]),
  "RuntimeSubscription": obj({"subscriptionCode": R("SubscriptionCode"), "topicName": R("TopicName"), "deliveryMode": R("DeliveryMode"),
      "status": R("SubscriptionStatus"), "suspendSource": nul(R("SuspendSource")), "consumerGroup": STR(255),
      "push": nul(R("PushInput")), "pull": nul(R("PullConfig")), "signingKeys": arr(R("SigningKey")), "configVersion": INT(minimum=0)},
      req=["subscriptionCode", "topicName", "deliveryMode", "status", "consumerGroup", "configVersion"]),
  "RuntimeConfig": obj({"tenant": STR(3, pattern="^T[0-9]{2}$"), "configVersion": INT(minimum=0), "generatedAt": TS, "full": BOOL,
      "topics": arr(R("RuntimeTopic")), "subscriptions": arr(R("RuntimeSubscription")), "replays": arr(R("ReplayRequest"))},
      req=["tenant", "configVersion", "generatedAt", "topics", "subscriptions", "replays"]),
  # ---------------- K. xuất nhập, di trú
  "ExportRequest": obj({"projectCodes": arr(R("ProjectCode"), maxItems=100), "topicNames": arr(R("TopicName"), maxItems=1000)},
      desc="Không có trường nào thì xuất toàn tenant; trên 10.000 đối tượng chạy nền (202)."),
  "ImportPreviewRow": obj({"changeKind": R("ChangeKind"), "targetType": R("LegacyType"), "targetCode": STR(204), "message": nul(STR(1000))},
      req=["changeKind", "targetType", "targetCode"]),
  "ManifestImportJob": obj({"jobCode": R("JobCode"), "sourceKind": R("ImportSourceKind"), "fileRef": STR(512), "status": R("ImportStatus"),
      "validationErrors": arr(obj({"path": STR(512), "code": STR(16), "message": STR(1000)})), "preview": arr(R("ImportPreviewRow")),
      "appliedAt": nul(TS), **AUDIT}, req=["jobCode", "sourceKind", "status", "validationErrors", "preview"]),
  "ImportMeta": obj({"sourceKind": R("ImportSourceKind"), "rewriteTenantPrefix": BOOL, "defaultProjectCode": R("ProjectCode")}, req=["sourceKind"]),
  "LegacyMapping": obj({"mappingId": UUID, "jobCode": R("JobCode"), "legacyType": R("LegacyType"), "legacyId": STR(512), "legacyName": nul(STR(512)),
      "targetType": nul(R("LegacyType")), "targetCode": nul(STR(204)), "confidence": R("Confidence"), "issues": arr(obj({"code": STR(32), "message": STR(1000)})),
      "status": R("MappingStatus"), "cutOverAt": nul(TS), "rollbackUntil": nul(TS), "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["mappingId", "jobCode", "legacyType", "legacyId", "confidence", "status", "version"]),
  "LegacyMappingPage": obj({"items": arr(R("LegacyMapping")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "legacyType": CNT})}, req=["items", "page", "size", "totalElements"]),
  "LegacyMappingUpdate": obj({"targetType": R("LegacyType"), "targetCode": STR(204), "status": enum("PROPOSED", "SKIPPED"), "reason": R("Reason")},
      desc="Chỉ khi ánh xạ `PROPOSED` hoặc `SKIPPED`; `status` chỉ nhận `PROPOSED` (bỏ đánh dấu) hoặc `SKIPPED` (bỏ qua)."),
  "MigrationBridge": obj({"bridgeCode": R("BridgeCode"), "direction": R("BridgeDirection"), "pulsarTopic": STR(512), "kafkaTopic": R("TopicName"),
      "pulsarSubscriptionName": STR(255), "startFrom": R("BridgeStartFrom"), "status": R("BridgeStatus"), "expiresAt": TS,
      "lastPulsarMessageId": nul(STR(255)), "bridgedCount": LONG, "lagSeconds": nul(INT(minimum=0)), "approvalRequestCode": nul(R("RequestCode")), **AUDIT},
      req=["bridgeCode", "direction", "pulsarTopic", "kafkaTopic", "status", "expiresAt", "version"]),
  "MigrationBridgePage": obj({"items": arr(R("MigrationBridge")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG,
      "facets": obj({"status": CNT, "direction": CNT})}, req=["items", "page", "size", "totalElements"]),
  "BridgeCreate": obj({"direction": R("BridgeDirection"), "pulsarTopic": STR(512, pattern="^persistent://"), "kafkaTopic": R("TopicName"),
      "pulsarSubscriptionName": STR(255), "startFrom": R("BridgeStartFrom"), "expiresAt": TS, "reason": R("Reason")},
      req=["direction", "pulsarTopic", "kafkaTopic", "expiresAt", "reason"]),
  "Reconciliation": obj({"bridgeCode": R("BridgeCode"), "windowStart": TS, "windowEnd": TS, "pulsarCount": LONG, "kafkaCount": LONG,
      "difference": INT(), "sampleMismatches": INT(minimum=0), "reportRef": STR(512)}, req=["bridgeCode", "windowStart", "windowEnd", "pulsarCount", "kafkaCount", "difference"]),
  "ReconciliationPage": obj({"items": arr(R("Reconciliation")), "page": INT(minimum=0), "size": INT(minimum=1), "totalElements": LONG},
      req=["items", "page", "size", "totalElements"]),
  "MigrationProgress": obj({"mappingsByStatus": {"type": "object", "additionalProperties": CNT, "description": "Theo `legacyType`, rồi theo `status`."},
      "legacySystems": arr(obj({"systemCode": R("SystemCode"), "publishesViaPulsar": BOOL, "subscribesViaPulsar": BOOL})),
      "bridges": arr(R("MigrationBridge")), "lastReconciliation": nul(R("Reconciliation")), "plannedShutdownAt": nul(s("string", format="date"))},
      req=["mappingsByStatus", "bridges"]),
  # ---------------- data plane
  "CloudEvent": {
      "type": "object", "description": "CloudEvents 1.0 dạng JSON có cấu trúc (`application/cloudevents+json`), FRS §4.9.",
      "required": ["specversion", "id", "source", "type"],
      "properties": {"specversion": {"type": "string", "const": "1.0"}, "id": STR(255, minLength=1, description="Duy nhất theo bên phát; dùng chống trùng 24 giờ."),
          "source": STR(512, description="URI bên phát, ví dụ `/t68/systems/HT-DKKD`; phải thuộc HTTT của token (BR-10-021)."),
          "type": STR(255, pattern="^vn\\.datahub\\.[a-z0-9-]+(\\.[a-z0-9-]+)+$"), "time": TS, "subject": STR(255),
          "dataschema": STR(1024, description="URI phiên bản lược đồ ở Apicurio; mặc định phiên bản ENABLED mới nhất."),
          "datacontenttype": STR(127), "traceparent": STR(55), "dhtenant": STR(3, pattern="^T[0-9]{2}$", description="Cổng ghi đè theo token."),
          "data": {"description": "Dữ liệu theo lược đồ của topic."}},
      "additionalProperties": True},
  "CloudEventBatch": arr(R("CloudEvent"), minItems=1, maxItems=500, description="`application/cloudevents-batch+json`; ≤ `10.publish.max-batch`, ≤ 1 MiB; tất cả hoặc không."),
  "PublishResultItem": obj({"id": STR(255), "partition": INT(minimum=0), "offset": LONG, "schemaVersion": INT(minimum=1)}, req=["id", "partition", "offset", "schemaVersion"]),
  "PublishResult": obj({"results": arr(R("PublishResultItem"), minItems=1)}, req=["results"]),
  "PullResponse": obj({"events": arr(R("CloudEvent")), "cursor": STR(4096, description="Mờ, ký HMAC phía máy chủ; chỉ dùng cho đúng subscription và lease này."),
      "leaseExpiresAt": TS}, req=["events", "cursor", "leaseExpiresAt"]),
  "AckRequest": obj({"cursor": STR(4096)}, req=["cursor"]),
  "NackRequest": obj({"cursor": STR(4096), "eventIds": arr(STR(255), minItems=1, maxItems=1000), "reason": STR(1000, minLength=3)}, req=["cursor", "eventIds", "reason"]),
  "DeadLetterReport": obj({"items": arr(obj({"eventId": STR(255), "sourcePartition": INT(minimum=0), "sourceOffset": LONG, "errorDetail": STR(2000)},
      req=["eventId", "sourcePartition", "sourceOffset", "errorDetail"]), minItems=1, maxItems=100)}, req=["items"]),
  # ---------------- nội bộ runtime
  "DeliveryReportItem": {"allOf": [R("DeliveryStat"), obj({"subscriptionCode": R("SubscriptionCode"), "failures": arr(R("DeliveryFailure"), maxItems=100)}, req=["subscriptionCode"])]},
  "DeliveryReport": obj({"items": arr(R("DeliveryReportItem"), minItems=1, maxItems=1000)}, req=["items"]),
  "RuntimeSuspendRequest": obj({"suspendSource": enum("CIRCUIT_BREAKER", "DELIVERY_BLOCKED"), "suspendReason": STR(1000, minLength=5)},
      req=["suspendSource", "suspendReason"]),
  "RuntimeResumeRequest": obj({"probeEventId": STR(255, description="`ce_id` của bản tin thăm dò giao thành công.")}, req=["probeEventId"]),
  "ReplayStartRequest": obj({"runner": STR(255, description="Tên bản sao chạy lượt (pod).")}, req=["runner"]),
  "ReplayProgress": obj({"deliveredRecords": LONG, "failedRecords": LONG,
      "entries": arr(obj({"dlqEntryId": UUID, "status": enum("REPLAYED", "NEW"), "errorCode": nul(STR(16))}, req=["dlqEntryId", "status"]), maxItems=100),
      "status": enum("COMPLETED", "FAILED", "CANCELLED", desc="Chỉ gửi ở báo cáo cuối.")}, req=["deliveredRecords", "failedRecords"]),
  "FetchPayloadsRequest": obj({"replayCode": R("ReplayCode"), "dlqEntryIds": arr(UUID, minItems=1, maxItems=100, uniqueItems=True)}, req=["replayCode", "dlqEntryIds"]),
  "DlqPayloadList": obj({"items": arr(R("DlqPayload"))}, req=["items"]),
  "BridgeStatusReport": obj({"status": enum("RUNNING", "STOPPED", "ERROR", "EXPIRED"), "bridgedCount": LONG, "lagSeconds": nul(INT(minimum=0)),
      "lastPulsarMessageId": nul(STR(255)), "errorDetail": nul(STR(2000))}, req=["status", "bridgedCount"]),
}

# allOf: phần ghép không được đóng (additionalProperties: false) mà đóng ở lược đồ ghép bằng unevaluatedProperties.
def _close_allof():
    def walk(x):
        if isinstance(x, dict):
            if "allOf" in x:
                for part in x["allOf"]:
                    if "$ref" in part:
                        SCHEMAS[part["$ref"].split("/")[-1]].pop("additionalProperties", None)
                    else:
                        part.pop("additionalProperties", None)
                x["unevaluatedProperties"] = False
            for v in x.values(): walk(v)
        elif isinstance(x, list):
            for v in x: walk(v)
    walk(SCHEMAS)
# Bổ sung theo Phụ lục B của D03-06-PH10 (tập màn hình); tên trường mới ghi ở §10.1 của D03-04-PH10
for _n in ("Project", "Topic", "PartyBase", "Publication", "Subscription", "ApprovalRequest", "ReplayRequest"):
    SCHEMAS[_n]["properties"]["allowedActions"] = arr(STR(32, pattern="^[a-z][a-z-]{1,31}$"), uniqueItems=True,
        description="Hành động người gọi được làm lúc này (theo quyền, trạng thái, bốn mắt), tên theo hậu tố hành động hoặc `update`, `delete`. Chỉ để giao diện ẩn nút; máy chủ vẫn kiểm lại.")
SCHEMAS["Subscription"]["properties"]["signingKeyPending"] = {**BOOL, "description": "Khóa ký đầu tiên chưa được nhận qua API-10-120."}
SCHEMAS["EndpointVerification"]["properties"]["validUntil"] = nul(TS)
SCHEMAS["GraphEdge"]["properties"].update({"dlqNewCount": INT(minimum=0), "commType": nul(R("CommTypeCode"))})
SCHEMAS["Graph"]["properties"]["metricsCollectedAt"] = nul(TS)
SCHEMAS["ReplayEstimate"] = obj({"estimatedRecords": LONG, "estimatedDurationSeconds": INT(minimum=0),
    "availableRange": arr(obj({"partition": INT(minimum=0), "fromOffset": LONG, "toOffset": LONG}))},
    req=["estimatedRecords", "estimatedDurationSeconds", "availableRange"], desc="Kết quả chạy thử API-10-064 (`dryRun=true`); không tạo yêu cầu.")
_close_allof()

# ---------------- lỗi: nạp từ FRS §8.1 để không lệch
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH10-frs-su-kien.md")
ERRS = {c: (h.strip(), m.strip()) for c, h, m in re.findall(r"^\| (ERR-10-\d{3}) \| ([^|]+) \| ([^|]+) \|$", open(FRS, encoding="utf-8").read(), re.M)}
STATUS_NAME = {400: "BadRequest", 401: "Unauthorized", 403: "Forbidden", 404: "NotFound", 409: "Conflict", 412: "PreconditionFailed",
               413: "PayloadTooLarge", 422: "Unprocessable", 423: "Locked", 429: "TooManyRequests", 503: "ServiceUnavailable"}
TRACE = "4bf92f3577b34da6a3ce929d0e0e4736"
def problem(c):
    http, m = ERRS[c]
    ex = {"type": f"https://datahub.gov.vn/errors/{c}", "title": m.split(" (")[0][:120], "status": int(http), "code": c, "traceId": TRACE}
    extra = {"ERR-10-003": {"errors": [{"field": "projectCode", "rule": "reserved-word", "message": "`moi` là từ dành riêng của route."}]},
             "ERR-10-007": {"currentEtag": "W/\"7\""},
             "ERR-10-010": {"dependents": [{"kind": "TOPIC", "code": "t68.dkkd.doanh-nghiep.da-cap-phep.v1", "status": "ACTIVE"}]},
             "ERR-10-033": {"availableRange": [{"partition": 0, "fromOffset": 120400, "toOffset": 182311}]},
             "ERR-10-105": {"failedIndex": 2, "errors": [{"field": "data.maDoanhNghiep", "rule": "required", "message": "Thiếu trường khóa phân vùng."}]},
             "ERR-10-107": {"retryAfterSeconds": 5}, "ERR-10-121": {"retryAfterSeconds": 5}, "ERR-10-029": {"retryAfterSeconds": 10}}
    ex.update(extra.get(c, {}))
    return ex
RESPONSES = {}
for st, name in STATUS_NAME.items():
    codes = [c for c, (h, _) in sorted(ERRS.items()) if h == str(st)]
    RESPONSES[name] = {"description": f"Lỗi {st}: " + ", ".join(codes) + ".",
        "content": {"application/problem+json": {"schema": R("ProblemDetails"),
            "examples": {c.replace("-", "_"): {"summary": ERRS[c][1][:200], "value": problem(c)} for c in codes}}}}
    if st in (429, 503): RESPONSES[name]["headers"] = {"Retry-After": {"schema": INT(minimum=1)}}
RESPONSES["NotModified"] = {"description": "Không đổi (`If-None-Match` khớp)."}

PARAMS = {
  "ProjectCodePath": {"name": "projectCode", "in": "path", "required": True, "schema": R("ProjectCode")},
  "TopicNamePath": {"name": "topicName", "in": "path", "required": True, "schema": R("TopicName")},
  "VersionNoPath": {"name": "versionNo", "in": "path", "required": True, "schema": INT(minimum=1)},
  "PublisherCodePath": {"name": "publisherCode", "in": "path", "required": True, "schema": R("PublisherCode")},
  "SubscriberCodePath": {"name": "subscriberCode", "in": "path", "required": True, "schema": R("SubscriberCode")},
  "PublicationCodePath": {"name": "publicationCode", "in": "path", "required": True, "schema": R("PublicationCode")},
  "SubscriptionCodePath": {"name": "subscriptionCode", "in": "path", "required": True, "schema": R("SubscriptionCode")},
  "RequestCodePath": {"name": "requestCode", "in": "path", "required": True, "schema": R("RequestCode")},
  "DlqEntryIdPath": {"name": "dlqEntryId", "in": "path", "required": True, "schema": UUID},
  "ReplayCodePath": {"name": "replayCode", "in": "path", "required": True, "schema": R("ReplayCode")},
  "CommTypeCodePath": {"name": "commTypeCode", "in": "path", "required": True, "schema": R("CommTypeCode")},
  "RoutingModeCodePath": {"name": "routingModeCode", "in": "path", "required": True, "schema": R("RoutingModeCode")},
  "FlowCodePath": {"name": "flowCode", "in": "path", "required": True, "schema": R("FlowCode")},
  "JobCodePath": {"name": "jobCode", "in": "path", "required": True, "schema": R("JobCode")},
  "MappingIdPath": {"name": "mappingId", "in": "path", "required": True, "schema": UUID},
  "BridgeCodePath": {"name": "bridgeCode", "in": "path", "required": True, "schema": R("BridgeCode")},
  "RegistryPath": {"name": "registryPath", "in": "path", "required": True, "schema": STR(1024),
      "description": "Phần đường sau `/registry/`, có thể chứa `/` (APISIX chuyển nguyên), ví dụ `apis/registry/v3/groups/t68/artifacts/{topicName}/versions/3/content` hoặc `apis/ccompat/v7/schemas/ids/1042`."},
  "Page": {"name": "page", "in": "query", "schema": INT(minimum=0, default=0), "description": "Số trang từ 0."},
  "Size": {"name": "size", "in": "query", "schema": INT(minimum=1, maximum=200, default=20), "description": "Vượt 200 trả ERR-10-049."},
  "Sort": {"name": "sort", "in": "query", "schema": STR(64, pattern="^[a-zA-Z]+(,(asc|desc))?$"), "description": "`truong,asc|desc`, ví dụ `updatedAt,desc`."},
  "Q": {"name": "q", "in": "query", "schema": STR(100, minLength=1), "description": "Tìm không dấu trên mã, tên, mô tả."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(64), "description": "ETag hiện tại (`W/\"{version}\"`); lệch trả ERR-10-007 (412)."},
  "IfNoneMatch": {"name": "If-None-Match", "in": "header", "schema": STR(64)},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16),
      "description": "Lưu 24 giờ ở Valkey `dh:{tenant}:evt:idem:{chủ thể}:{khóa}`; cùng khóa khác thân trả ERR-10-037; cùng khóa cùng thân trả lại phản hồi cũ."},
  "IdempotencyKeyOptional": {"name": "Idempotency-Key", "in": "header", "schema": STR(128, minLength=1),
      "description": "Tùy chọn; mặc định dùng `id` của CloudEvents (chống trùng 24 giờ theo bên phát)."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
}
PATH_PARAM = {"projectCode": "ProjectCodePath", "topicName": "TopicNamePath", "versionNo": "VersionNoPath", "publisherCode": "PublisherCodePath",
    "subscriberCode": "SubscriberCodePath", "publicationCode": "PublicationCodePath", "subscriptionCode": "SubscriptionCodePath",
    "requestCode": "RequestCodePath", "dlqEntryId": "DlqEntryIdPath", "replayCode": "ReplayCodePath", "commTypeCode": "CommTypeCodePath",
    "routingModeCode": "RoutingModeCodePath", "flowCode": "FlowCodePath", "jobCode": "JobCodePath", "mappingId": "MappingIdPath",
    "bridgeCode": "BridgeCodePath", "registryPath": "RegistryPath"}

Q = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": schema, "description": desc}.items() if v is not None}
QA = lambda name, schema: {"name": name, "in": "query", "schema": arr(schema), "style": "form", "explode": False}
PG = ["Page", "Size", "Sort"]

# code → (operationId, thân yêu cầu, phản hồi, mô tả, tham số query thêm)
X = {
  "001": ("listProjects", None, "ProjectPage", "OR chỉ thấy dự án có HTTT của tổ chức mình. Mặc định `status=ACTIVE`; `sort` theo `projectCode`, `name`, `updatedAt`, `topicCount`.",
          ["Q", QA("status", R("ProjectStatus")), Q("ownerOrgCode", R("OrgCode")), Q("label", STR(63))] + PG),
  "002": ("createProject", "ProjectCreate", "Project", "Từ dành riêng của route ERR-10-003; mã trùng kể cả dự án đã lưu trữ ERR-10-002; vượt `maxProjects` ERR-10-011.", []),
  "003": ("getProject", None, "Project", None, []),
  "004": ("updateProject", "ProjectUpdate", "Project", "Dự án `ARCHIVED` không sửa được (ERR-10-006).", []),
  "005": ("archiveProject", "StateChangeRequest", "Project", "Còn topic `PENDING_APPROVAL`, `PROVISIONING`, `ACTIVE`, `DEPRECATED` trả ERR-10-010 kèm `dependents`. Topic `DRAFT` còn lại bị xóa mềm.", []),
  "006": ("restoreProject", "StateChangeRequest", "Project", None, []),
  "007": ("getGraph", None, "Graph", "Dựng ba lớp bên phát, topic, bên nhận; vượt `10.graph.max-nodes` trả ERR-10-049, đề nghị lọc theo dự án. Bố cục làm ở trình duyệt.",
          [Q("projectCode", R("ProjectCode")), Q("topicName", R("TopicName")), Q("systemCode", R("SystemCode"), "Lân cận một bước quanh một HTTT."),
           Q("includeRetired", BOOL), Q("overlay", R("GraphOverlay"))]),
  "008": ("listTopics", None, "TopicPage", "Mặc định ẩn topic `DLQ`. `usableBy=flow:{flowCode}` kèm `action` trả topic luồng dùng được (bảng chọn của trình thiết kế PH-04, scope `event:permission-check` hoặc `PERM-10-read`).",
          ["Q", Q("projectCode", R("ProjectCode")), QA("status", R("TopicStatus")), QA("topicKind", R("TopicKind")), QA("dataClass", R("DataClass")),
           Q("domain", STR(63)), Q("usableBy", STR(70, pattern="^flow:[a-z][a-z0-9-]{2,62}$")), Q("action", R("PermissionAction"))] + PG),
  "009": ("createTopic", "TopicCreate", "Topic", "Người dùng: topic `DRAFT` (hoặc `PENDING_APPROVAL` khi `submit`), 201. Tài khoản dịch vụ `event:topic-register` với `topicKind` `CDC`, `SYSTEM`: idempotent theo `topicName` (đã có cùng cấu hình trả 200, khác cấu hình ERR-10-002), tự duyệt theo BR-10-031 và trả 202 với `PROVISIONING` hoặc `PENDING_APPROVAL` trong ≤ 2 giây. Miền dành riêng với người dùng ERR-10-004; tiền tố khác tenant ERR-10-005.", []),
  "010": ("getTopic", None, "Topic", None, []),
  "011": ("updateTopic", "TopicUpdate", "Topic", "Topic `CDC`, `SYSTEM` chỉ tài khoản dịch vụ chủ quản sửa ngoài mô tả (ERR-10-045).", []),
  "012": ("submitTopic", None, "Topic", "Tạo yêu cầu `TOPIC_CREATE`; topic và phiên bản lược đồ 1 sang `PENDING_APPROVAL`. Trả `approvalRequestCode`.", []),
  "013": ("retryTopicProvisioning", None, "Topic", "Chỉ topic `FAILED`: sinh lại tài nguyên, commit mới, sang `PROVISIONING`.", []),
  "014": ("cancelTopicProvisioning", None, "Topic", "Topic `FAILED` hoặc `PROVISIONING` quá hạn: về `DRAFT`, xóa artifact Apicurio nếu chưa có bản tin.", []),
  "015": ("requestTopicChange", "TopicChangeRequest", "TopicChangeResult", "Giảm phân vùng ERR-10-013; tăng phân vùng ở topic có khóa thiếu `acknowledgeOrderingImpact` ERR-10-014; đổi định tuyến, khóa hoặc thứ tự cần phiên bản topic mới ERR-10-047; `NONE` với topic đã từng `ACTIVE` ERR-10-019. Áp dụng ngay trả 200 (`approvalRequest` null); cần duyệt trả 201 với `approvalRequest` `TOPIC_CHANGE` và `impactedSubscriptions`. `dryRun=true` chỉ kiểm và trả 200 với `impactedSubscriptions`, cảnh báo thứ tự, không ghi gì.", [Q("dryRun", BOOL)]),
  "016": ("deprecateTopic", "DeprecateRequest", "Topic", "Topic `ACTIVE` sang `DEPRECATED`; `sunsetAt` mặc định theo `10.topic.deprecation-days`. Phát EVT-10-03.", []),
  "017": ("retireTopic", "StateChangeRequest", "Topic", "Tạo yêu cầu `TOPIC_RETIRE`; còn subscription chưa `REVOKED` trả ERR-10-010. Khi duyệt: `RETIRED`, phát EVT-10-04, xóa khỏi cụm sau `10.topic.delete-after-retire-days`.", []),
  "018": ("createTopicMajorVersion", "NewMajorVersionRequest", "Topic", "Tạo topic `.v{n+1}` (`predecessorTopic`), topic cũ `DEPRECATED` với `successorTopic` khi topic mới `ACTIVE`. Đã có kế nhiệm ERR-10-047. Máy (PH-05, FR-10-068) tự duyệt.", []),
  "019": ("getTopicMigrationStatus", None, "MigrationStatus", None, []),
  "020": ("getTopicConnectionInfo", None, "ConnectionInfo", "Không chứa bí mật; listener `external` chỉ khi `10.external-kafka.enabled`.", []),
  "021": ("getTopicSchema", None, "EventSchema", None, []),
  "022": ("listSchemaVersions", None, "SchemaVersionList", None, [QA("status", R("SchemaVersionStatus"))] + PG),
  "023": ("createSchemaVersion", "SchemaVersionCreate", "SchemaVersion", "Người dùng: phiên bản `DRAFT`. PH-05 (`event:topic-register`): kiểm tương thích theo mức của topic và tự duyệt khi đạt, không đạt ERR-10-016 (FR-10-068).", []),
  "024": ("getSchemaVersion", None, "SchemaVersion", "`Accept: application/json` cho siêu dữ liệu; `Accept: application/octet-stream` tải nội dung lược đồ.", []),
  "025": ("updateSchemaVersion", "SchemaVersionUpdate", "SchemaVersion", "Chỉ phiên bản `DRAFT` hoặc `REJECTED` (về `DRAFT`).", []),
  "026": ("checkSchemaVersion", None, "SchemaVersion", "Không đổi trạng thái; ghi `compatibilityReport`, `piiFindings`, `checkedAt`. Không tương thích trả 200 với `compatibilityReport.compatible = false` (không phải lỗi).", []),
  "027": ("submitSchemaVersion", None, "SchemaVersion", "Chạy lại kiểm tra; không tương thích ERR-10-016; PII `BLOCKING` ERR-10-018. Tạo yêu cầu `SCHEMA_VERSION`.", []),
  "028": ("deprecateSchemaVersion", "StateChangeRequest", "SchemaVersion", "`ENABLED` sang `DEPRECATED`; bên phát vẫn dùng được. Phát EVT-10-02.", []),
  "029": ("disableSchemaVersion", "StateChangeRequest", "SchemaVersion", "Sang `DISABLED`; cổng từ chối `dataschema` trỏ phiên bản này (ERR-10-105). Không vô hiệu được phiên bản `ENABLED` duy nhất (ERR-10-006).", []),
  "030": ("diffSchemaVersions", None, "SchemaDiff", None, [Q("from", INT(minimum=1)), Q("to", INT(minimum=1))]),
  "031": ("getTopicCompliance", None, "Compliance", None, [Q("from", TS), Q("to", TS)]),
  "032": ("listPublishers", None, "PublisherPage", "OR chỉ thấy bên phát của tổ chức mình.",
          ["Q", QA("partyType", R("PartyType")), QA("commType", R("CommTypeCode")), QA("status", R("PartyStatus")), Q("systemCode", R("SystemCode")),
           Q("projectCode", R("ProjectCode"))] + PG),
  "033": ("createPublisher", "PublisherCreate", "Publisher", "HTTT không `ACTIVE` ở PH-01 ERR-10-021; luồng không hợp lệ ERR-10-022; DU ngoài danh sách ERR-10-023; cặp (HTTT, kiểu giao tiếp) đã có ERR-10-024.", []),
  "034": ("getPublisher", None, "Publisher", None, []),
  "035": ("updatePublisher", "PartyUpdate", "Publisher", None, []),
  "036": ("suspendPublisher", "StateChangeRequest", "Publisher", "Mọi publication `ACTIVE` sang `SUSPENDED` (FR-10-032); phát EVT-10-07 cho từng quan hệ.", []),
  "092": ("resumePublisher", "StateChangeRequest", "Publisher", "SO chỉ tiếp tục khi chính SO đã tạm ngừng (`suspendSource = SECURITY`); quan hệ về trạng thái trước.", []),
  "093": ("retirePublisher", "StateChangeRequest", "Publisher", "Thu hồi mọi publication; mã không dùng lại.", []),
  "037": ("listSubscribers", None, "SubscriberPage", None,
          ["Q", QA("partyType", R("PartyType")), QA("commType", R("CommTypeCode")), QA("status", R("PartyStatus")), Q("systemCode", R("SystemCode")),
           Q("projectCode", R("ProjectCode"))] + PG),
  "038": ("createSubscriber", "SubscriberCreate", "Subscriber", "`partyType = FLOW` thay chức năng \"đánh dấu là luồng\" của hệ cũ.", []),
  "039": ("getSubscriber", None, "Subscriber", None, []),
  "040": ("updateSubscriber", "PartyUpdate", "Subscriber", None, []),
  "041": ("suspendSubscriber", "StateChangeRequest", "Subscriber", "Mọi subscription `ACTIVE` sang `SUSPENDED`; phát EVT-10-09.", []),
  "094": ("resumeSubscriber", "StateChangeRequest", "Subscriber", None, []),
  "095": ("retireSubscriber", "StateChangeRequest", "Subscriber", "Thu hồi mọi subscription.", []),
  "042": ("listPublications", None, "PublicationPage", None,
          [Q("publisherCode", R("PublisherCode")), Q("topicName", R("TopicName")), QA("status", R("PublicationStatus")), Q("projectCode", R("ProjectCode"))] + PG),
  "043": ("createPublication", "PublicationCreate", "Publication", "Topic `DEPRECATED` hoặc bên phát không `ACTIVE` ERR-10-025; cặp đã có ERR-10-024; topic `RESTRICTED`, `SENSITIVE` với bên phát chưa đạt cấp độ ATTT ERR-10-051. Tự duyệt theo BR-10-031 với bên `INTERNAL_SERVICE`.", []),
  "044": ("getPublication", None, "Publication", None, []),
  "045": ("suspendPublication", "StateChangeRequest", "Publication", "Gỡ dữ liệu OPA (≤ 60 giây), scope, ACL `WRITE`. Phát EVT-10-07.", []),
  "096": ("resumePublication", "StateChangeRequest", "Publication", "Cấp lại không cần duyệt nếu topic, bên phát còn hợp lệ (ngược lại ERR-10-025).", []),
  "097": ("revokePublication", "StateChangeRequest", "Publication", "Sang `REVOKED`, không tiếp tục được.", []),
  "046": ("listSubscriptions", None, "SubscriptionPage", None,
          ["Q", Q("subscriberCode", R("SubscriberCode")), Q("topicName", R("TopicName")), QA("status", R("SubscriptionStatus")),
           QA("deliveryMode", R("DeliveryMode")), QA("alertState", R("AlertState")), Q("projectCode", R("ProjectCode"))] + PG),
  "047": ("createSubscription", "SubscriptionCreate", "Subscription", "`PUSH` cần endpoint đã xác minh trong 24 giờ (chưa có thì chạy xác minh, lỗi ERR-10-027); `PULL_KAFKA` khi tenant chưa bật ERR-10-028; `workerCount` vượt phân vùng ERR-10-030; `startAt` ngoài lưu giữ ERR-10-031; topic `RESTRICTED`, `SENSITIVE` bắt buộc `legalBasis`. Gán `consumerGroup` theo A.8. Không gửi `failurePolicy` thì mặc định `BLOCK` với topic `orderingRequired`, `DEAD_LETTER` với topic còn lại; `lagWarnSeconds` phải nhỏ hơn `lagCriticalSeconds` (ERR-10-012).", []),
  "048": ("getSubscription", None, "Subscription", None, []),
  "049": ("updateSubscription", "SubscriptionUpdate", "Subscription", "Không cần duyệt lại: `workerCount`, `maxRetries`, `retryBackoff`, `timeoutMs`, `payloadFormat`, `pull`, ngưỡng lag (áp dụng ≤ 60 giây). Đổi `endpointUrl` (phải xác minh trước), `failurePolicy` tạo yêu cầu `SUBSCRIPTION`, trả `approvalRequestCode`, subscription chạy tham số cũ tới khi duyệt. Thay đổi có hiệu lực phát EVT-10-09.", []),
  "050": ("pauseSubscription", "StateChangeRequest", "Subscription", "`ACTIVE` sang `PAUSED`; bộ giao nhận dừng ≤ 10 giây. Subscription `INTERNAL` trả ERR-10-052.", []),
  "098": ("resumeSubscription", "StateChangeRequest", "Subscription", "Từ `PAUSED` hoặc `SUSPENDED` (cần lý do khắc phục). `INTERNAL` trả ERR-10-052.", []),
  "099": ("revokeSubscription", "StateChangeRequest", "Subscription", "Thu hồi khóa ký, gỡ ACL, xóa nhóm tiêu thụ sau `10.subscription.group-delete-delay-hours`; hủy lượt phát lại đang chạy.", []),
  "051": ("verifyEndpoint", "EndpointVerificationRequest", "EndpointVerification", "Bắt tay `OPTIONS` theo CloudEvents HTTP Webhook (`WebHook-Request-Origin: event.{tenant}.datahub`), kiểm TLS, DNS. Có `subscriptionCode` thì ghi `push.lastVerification`. Thất bại trả 200 với `result = FAILED` khi gọi riêng; trả ERR-10-027 khi dùng trong API-10-047, 049.", []),
  "091": ("waiveEndpointVerification", "WaiverRequest", "Subscription", "Ngoại lệ ≤ 180 ngày cho HTTT cũ không trả lời được bắt tay; thay bằng một `POST` sự kiện kiểm tra `vn.datahub.event.subscription.verification`. Ghi `push.lastVerification.result = WAIVED`.", []),
  "052": ("getSubscriptionStats", None, "DeliveryStats", None, [Q("window", enum("1h", "24h", "7d"))]),
  "053": ("listSubscriptionFailures", None, "DeliveryFailurePage", "Không có thân sự kiện; `responseSnippet` ≤ 512 byte đã che.",
          [Q("from", TS), Q("to", TS), QA("failureClass", R("FailureClass"))] + PG),
  "054": ("rotateSigningKey", "SigningKeyRotateRequest", "SigningKeyIssued", "Khóa mới `ACTIVE`, khóa cũ `PREVIOUS` trong `10.push.key-rotation-overlap-days`; trả `secret` một lần. Quyền: `PERM-10-operate` hoặc `PERM-10-subscribe`. Phát EVT-10-13.", []),
  "100": ("revokeSigningKey", "StateChangeRequest", "SigningKeyIssued", "Khóa hiện tại `REVOKED` ngay, sinh khóa mới, không chồng lấn (SO, TA). Phát EVT-10-13.", []),
  "120": ("claimSigningKey", None, "SigningKeyIssued", "FR-10-037 bước 6: người đề nghị (hoặc người có `PERM-10-subscribe` trên bên nhận) nhận khóa ký đầu tiên đúng một lần sau khi subscription `ACTIVE`; gọi lại khi `signingKeyPending = false` trả ERR-10-006, khi đó dùng API-10-054. Không có `Idempotency-Key` để phản hồi chứa khóa không bị lưu đệm. Phát EVT-10-13.", []),
  "055": ("getSubscriptionLag", None, "Lag", None, [Q("window", enum("1h", "24h", "7d"))]),
  "056": ("acknowledgeLagAlert", "LagAckRequest", "Subscription", "Tắt thông báo lặp 4 giờ; không tắt đánh giá. Ba trường xác nhận bị xóa khi `alertState` đổi mức.", []),
  "057": ("listApprovalRequests", None, "ApprovalRequestPage", "Nguồn của \"Việc của tôi\" (UI-10-13) với `status=PENDING`.",
          [QA("requestType", R("RequestType")), QA("status", R("RequestStatus")), QA("targetType", R("TargetType")), Q("targetCode", STR(204)),
           Q("requestedBy", USER), Q("mine", BOOL, "Chỉ yêu cầu người gọi được duyệt (loại trừ yêu cầu của chính mình).")] + PG),
  "058": ("getApprovalRequest", None, "ApprovalRequest", "`payloadDiff` là khác biệt cấu hình; `checks` gồm kết quả kiểm tra hạn mức, tên, dữ liệu cá nhân, tương thích.", []),
  "059": ("approveRequest", "ApproveRequest", "ApprovalRequest", "Bốn mắt: người duyệt khác người tạo đối tượng và người gửi (ERR-10-008). Chạy lại kiểm tra hạn mức (ERR-10-011), tương thích (ERR-10-016), cấp độ ATTT (ERR-10-051). Apicurio, Git, Keycloak không khả dụng ERR-10-029 (yêu cầu giữ `PENDING`).", []),
  "101": ("rejectRequest", "RejectRequest", "ApprovalRequest", "Đối tượng về trạng thái trước khi gửi (topic, lược đồ về `DRAFT`; publication, subscription, lượt phát lại, cầu nối sang `REJECTED`).", []),
  "102": ("withdrawRequest", "StateChangeRequest", "ApprovalRequest", "Chỉ người gửi, khi `PENDING`; đối tượng về trạng thái trước khi gửi.", []),
  "060": ("listDlqEntries", None, "DlqEntryPage", "Siêu dữ liệu, không nội dung. PH-18 gọi bằng scope `event:dlq-read`. `Accept: text/csv` xuất danh sách.",
          [Q("topicName", R("TopicName")), Q("subscriptionCode", R("SubscriptionCode")), QA("status", R("DlqStatus")), Q("errorCode", STR(16)),
           QA("origin", R("DlqOrigin")), Q("bridgeCode", R("BridgeCode")), Q("from", TS, "`firstFailedAt` từ."), Q("to", TS), Q("eventId", STR(255)), Q("eventSubject", STR(255))] + PG),
  "061": ("getDlqEntry", None, "DlqEntry", None, []),
  "103": ("getDlqEntryPayload", None, "DlqPayload", "Topic `RESTRICTED`, `SENSITIVE` bắt buộc `reason` (ERR-10-009), ghi kiểm toán xem dữ liệu nhạy cảm. Nội dung đã xóa (`PURGED`) trả ERR-10-001.",
          [Q("reason", STR(500, minLength=10))]),
  "062": ("discardDlqEntries", "DiscardRequest", "DlqEntryList", "≤ 1.000 mục `NEW` mỗi lệnh, tất cả hoặc không; mục đã xử lý ERR-10-036.", []),
  "063": ("listReplays", None, "ReplayPage", None, [Q("subscriptionCode", R("SubscriptionCode")), QA("status", R("ReplayStatus")), QA("replayMode", R("ReplayMode"))] + PG),
  "104": ("getReplay", None, "ReplayRequest", "Tiến độ cập nhật mỗi 5 giây.", []),
  "064": ("createReplay", "ReplayCreate", "ReplayRequest", "`RESET_OFFSET` khi subscription chưa `PAUSED` ERR-10-032; khoảng ngoài lưu giữ ERR-10-033 kèm `availableRange`; vượt `10.replay.max-records` ERR-10-034; đã có lượt `APPROVED`, `RUNNING` ERR-10-035; mục DLQ không `NEW` ERR-10-036; `targetEndpointUrl` chưa xác minh ERR-10-027. PH-18 gọi bằng scope `event:replay`. Tạo yêu cầu `REPLAY` (tự duyệt khi số mục DLQ ≤ `10.replay.dlq-auto-approve-max`). `dryRun=true` chỉ kiểm và trả 200 `ReplayEstimate`, không tạo yêu cầu.", [Q("dryRun", BOOL)]),
  "065": ("cancelReplay", "StateChangeRequest", "ReplayRequest", "Dừng sau bản tin đang giao; sang `CANCELLED`, phát EVT-10-12.", []),
  "066": ("getDashboard", None, "Dashboard", "Đếm từ `ph10_event`, làm mới 30 giây. `traffic` null khi PH-13 không khả dụng.", [Q("projectCode", R("ProjectCode"))]),
  "067": ("listCommTypes", None, "CommTypeList", None, []),
  "105": ("updateCommType", "CatalogToggle", "CommType", "Không tắt được mục đang có bên tham gia `ACTIVE` dùng (ERR-10-043).", []),
  "068": ("listRoutingModes", None, "RoutingModeList", None, []),
  "106": ("updateRoutingMode", "CatalogToggle", "RoutingMode", "`KEY_HASH` không tắt được; mục đang dùng ERR-10-043.", []),
  "069": ("getQuota", None, "TenantEventQuota", None, []),
  "107": ("putQuota", "QuotaUpdate", "TenantEventQuota", None, []),
  "070": ("getSettings", None, "Settings", None, []),
  "108": ("updateSettings", "SettingsUpdate", "Settings", "Ngoài miền A.5 ERR-10-012; `10.external-kafka.enabled` và tham số phạm vi N chỉ PA.", []),
  "071": ("checkPermissions", "PermissionCheckRequest", "PermissionCheckResponse", "Không ném lỗi theo từng bộ; PH-04 ánh xạ `DENIED` thành WARN hoặc ERROR theo môi trường.", []),
  "072": ("ensureFlowParty", "EnsurePartyRequest", "EnsurePartyResponse", "Idempotent; tạo bên phát, bên nhận `FLOW` nếu chưa có và đề nghị publication, subscription (`INTERNAL`) qua duyệt.", []),
  "109": ("getFlowDependencies", None, "FlowDependencies", None, []),
  "073": ("getRuntimeConfig", None, "RuntimeConfig", "`dh-runtime` gọi mỗi 30 giây và khi nhận EVT-10-02, 05, 08, 09, 13. `since` trả phần đổi (`full = false`). Không chứa bí mật ký; chỉ `keyId`.",
          [Q("since", INT(minimum=0), "`configVersion` đang giữ."), "IfNoneMatch"]),
  "074": ("exportManifest", "ExportRequest", None, "Trả `application/yaml` (`kind: EventManifest`, `apiVersion: event.datahub.vn/v1`); không có bí mật ký, không có `clientId` nội bộ.", []),
  "075": ("startImport", None, "ManifestImportJob", "`multipart/form-data`: `file` và `meta` (ImportMeta). `PULSAR_HUB` cần `PERM-10-admin`. Sai cấu trúc ERR-10-040; tham chiếu không có ở tenant đích ERR-10-050.", []),
  "110": ("getImport", None, "ManifestImportJob", None, []),
  "121": ("cancelImport", None, "ManifestImportJob", "Chỉ người tạo tác vụ, khi `VALIDATING` hoặc `PREVIEW` (A.2.13); trạng thái khác ERR-10-006. Không tạo đối tượng nào.", []),
  "111": ("applyImport", None, "ManifestImportJob", "Chỉ ở `PREVIEW`; tạo đối tượng ở trạng thái đầu (`DRAFT`, `PENDING_APPROVAL`), không bao giờ `ACTIVE` (BR-10-032). `PULSAR_HUB`: ánh xạ sang `PLANNED`.", []),
  "076": ("listLegacyMappings", None, "LegacyMappingPage", None,
          [Q("jobCode", R("JobCode")), QA("legacyType", R("LegacyType")), QA("status", R("MappingStatus")), QA("confidence", R("Confidence"))] + PG),
  "112": ("updateLegacyMapping", "LegacyMappingUpdate", "LegacyMapping", None, []),
  "077": ("listBridges", None, "MigrationBridgePage", None, [QA("status", R("BridgeStatus")), QA("direction", R("BridgeDirection"))] + PG),
  "113": ("createBridge", "BridgeCreate", "MigrationBridge", "Tạo yêu cầu `BRIDGE`; `expiresAt` quá `10.migration.bridge-max-days` ERR-10-012; đã có cầu nối cho topic hoặc cầu nối ngược chiều ERR-10-042; topic đích không `ACTIVE` ERR-10-025.", []),
  "114": ("stopBridge", "StateChangeRequest", "MigrationBridge", "Phát EVT-10-16 khi runtime xác nhận dừng (API-10-090).", []),
  "115": ("resumeBridge", "StateChangeRequest", "MigrationBridge", "Chỉ cầu nối `STOPPED` chưa hết hạn.", []),
  "078": ("requestCutOver", "StateChangeRequest", "LegacyMapping", "Tạo yêu cầu `CUTOVER` khi đủ điều kiện FR-10-075 (song song ≥ `10.migration.min-parallel-days`, đối chiếu 72 giờ không chênh); thiếu điều kiện ERR-10-041. Duyệt xong: dừng cầu nối, `CUT_OVER`, phát EVT-10-15.", []),
  "116": ("rollbackMapping", "StateChangeRequest", "LegacyMapping", "Không qua duyệt (khẩn cấp) nhưng bắt buộc lý do, thông báo IA; trong `10.migration.rollback-window-days`. Bật lại cầu nối chiều cũ; `ROLLED_BACK`; phát EVT-10-15.", []),
  "117": ("listReconciliations", None, "ReconciliationPage", "Báo cáo chi tiết ở kho đối tượng (`reportRef`).", [Q("bridgeCode", R("BridgeCode")), Q("from", TS), Q("to", TS)] + PG),
  "118": ("getMigrationProgress", None, "MigrationProgress", "`Accept` XLSX để xuất.", []),
  "079": ("publishEvents", None, "PublishResult", "Thân `application/cloudevents+json` (một sự kiện) hoặc `application/cloudevents-batch+json` (lô, tất cả hoặc không). Ghi `acks=all`, producer idempotent. Chống trùng 24 giờ theo (publication, `id`): lần gọi lặp trả lại kết quả cũ. Lỗi một sự kiện trong lô trả `failedIndex`.", []),
  "080": ("pullEvents", None, "PullResponse", "Một lease mỗi subscription; kéo lại khi lease chưa ack và chưa hết hạn trả đúng lô cũ. Không có sự kiện sau `waitSeconds` trả 204.",
          [Q("max", INT(minimum=1, maximum=1000), "≤ `pull.maxBatch`."), Q("waitSeconds", INT(minimum=0, maximum=60), "≤ `10.pull.long-poll-max-seconds`.")]),
  "081": ("ackEvents", "AckRequest", None, "Commit offset, xóa lease. Cursor hết hạn hoặc không khớp lease ERR-10-109.", []),
  "082": ("nackEvents", "NackRequest", None, "Các `eventIds` vào DLQ (`origin = PULL_NACK`, ERR-10-113) rồi coi như ack cả lô. Phát EVT-10-11 (gộp 1 phút).", []),
  "083": ("reportDeadLetters", "DeadLetterReport", None, "Chỉ subscription `PULL_KAFKA`; mục DLQ `origin = EXTERNAL_REPORT` để PH-18 theo dõi.", []),
  "084": ("getRegistryResource", None, None, "Chuyển tiếp chỉ đọc tới Apicurio Registry 3 (`apis/registry/v3/...`, `apis/ccompat/v7/...`). Plugin APISIX kiểm bằng OPA: chỉ artifact của topic mà token có scope `publish` hoặc `subscribe`; phương thức khác GET trả 405.", []),
  "085": ("postDeliveryReports", "DeliveryReport", None, "Một dòng `delivery_stat` mỗi (subscription, phút), gửi lặp ghi đè cùng giá trị; `failures` ghi `delivery_failure`.", []),
  "086": ("runtimeSuspendSubscription", "RuntimeSuspendRequest", "RuntimeSubscription", "`ACTIVE` sang `SUSPENDED` với `suspendSource` do runtime báo; phát EVT-10-09.", []),
  "119": ("runtimeResumeSubscription", "RuntimeResumeRequest", "RuntimeSubscription", "Chỉ khi `suspendSource = CIRCUIT_BREAKER` (ngược lại ERR-10-006); về `ACTIVE`, phát EVT-10-09.", []),
  "087": ("runtimeStartReplay", "ReplayStartRequest", "ReplayRequest", "`APPROVED` sang `RUNNING`; lượt đã có bản sao khác nhận trả ERR-10-006.", []),
  "088": ("runtimeReportReplay", "ReplayProgress", "ReplayRequest", "Báo mỗi 5 giây; kết quả từng mục DLQ chuyển `REPLAY_PENDING` sang `REPLAYED` hoặc về `NEW`. Báo cuối có `status`; phát EVT-10-12.", []),
  "089": ("runtimeFetchDlqPayloads", "FetchPayloadsRequest", "DlqPayloadList", "Chỉ mục thuộc lượt phát lại `RUNNING` có `replayCode` đã cho; nội dung giải mã phong bì qua OpenBao transit (ERR-10-029 khi không khả dụng).", []),
  "090": ("runtimeReportBridgeStatus", "BridgeStatusReport", None, "Đổi trạng thái thì phát EVT-10-16; ánh xạ `PLANNED` sang `BRIDGING` khi `RUNNING`.", []),
}

ANY_PERM = {
  "008": ["PERM-10-read", "scope:event:permission-check"], "009": ["PERM-10-create", "scope:event:topic-register"],
  "010": ["PERM-10-read", "scope:event:topic-register"], "018": ["PERM-10-update", "scope:event:topic-register"],
  "023": ["PERM-10-create", "scope:event:topic-register"], "054": ["PERM-10-operate", "PERM-10-subscribe"],
  "060": ["PERM-10-read", "scope:event:dlq-read"], "061": ["PERM-10-read", "scope:event:dlq-read"],
  "063": ["PERM-10-read", "scope:event:replay"], "104": ["PERM-10-read", "scope:event:replay"],
  "064": ["PERM-10-operate", "scope:event:replay"], "075": ["PERM-10-create", "PERM-10-admin"],
  "102": ["PERM-10-create", "PERM-10-update", "PERM-10-subscribe", "PERM-10-operate"],
  "066": ["PERM-10-read", "scope:event:metrics-read"], "055": ["PERM-10-read", "scope:event:metrics-read"],
}
TAGS = {"project": "Dự án tích hợp", "topic": "Topic", "schema": "Lược đồ sự kiện", "party": "Bên phát, bên nhận", "publication": "Publication",
        "subscription": "Subscription và giao nhận", "approval": "Yêu cầu duyệt", "dlq": "DLQ và phát lại", "monitor": "Giám sát, dashboard, sơ đồ",
        "config": "Danh mục, hạn mức, tham số", "machine": "Máy với máy (PH-04)", "runtime": "Nội bộ dh-runtime", "migration": "Xuất nhập, di trú Pulsar",
        "data": "Data plane: phát, kéo, lược đồ"}
NO_IFMATCH = {"026", "051", "071", "072", "064", "113", "111"}  # hành động không sửa bản ghi có phiên bản, hoặc tạo mới
DATA_GROUPS = {"data"}

def perm_of(code, perm):
    if code in ANY_PERM:
        return {"anyOf": ANY_PERM[code]}
    if perm.startswith("svc:"): return {"serviceScope": perm[4:]}
    if perm == "topic:publish": return {"topicScope": "topic:{topicName}:publish"}
    if perm == "topic:subscribe": return {"topicScope": "topic:{topicName}:subscribe"}
    if perm == "topic:any": return {"topicScope": "topic:{topicName}:publish | topic:{topicName}:subscribe"}
    if perm == "requester": return {"anyOf": ANY_PERM[code]}
    return {"permission": f"PERM-10-{perm}"}

def security_of(code, perm):
    if perm.startswith("svc:"): return [{"oauth2Service": [perm[4:]]}]
    if perm.startswith("topic:"): return [{"oauth2System": []}, {"mtlsSystem": []}]
    sec = [{"oauth2User": []}]
    for p in ANY_PERM.get(code, []):
        if p.startswith("scope:"): sec.append({"oauth2Service": [p[6:]]})
    return sec

def frs_list(fr):
    out = []
    for part in fr.split(","):
        part = part.strip()
        out.append(f"FR-10-{part}")
    return out

def errs_of(code, method, path, body, own, idem, ifmatch):
    lst = ["101", "102"] if spec_group(code) in DATA_GROUPS else ["053", "054"]
    if "{" in path: lst.append("001")
    if body: lst.append("003")
    if ifmatch: lst.append("007")
    if method == "GET" and ("Page" in str(X[code][2]) or code in ("007", "066")): lst.append("049")
    if idem == "x": lst.append("037")
    if method != "GET" and code not in ("071", "072", "109", "073", "085", "086", "087", "088", "089", "090", "119") and spec_group(code) not in DATA_GROUPS: lst.append("039")
    lst += own.split()
    seen, out = set(), []
    for e in lst:
        if e not in seen: seen.add(e); out.append(e)
    if spec_group(code) in DATA_GROUPS:
        out = [e for e in out if e.startswith("1")]
    return out

def spec_group(code):
    return next(o[8] for o in spec.OPS if o[0] == code)

import examples as EX
COMP_EX = {}
def xref(key, value, summary=None):
    """Ví dụ dùng chung ở components/examples; trùng tên khác nội dung thì thêm hậu tố."""
    k, i = key, 2
    while k in COMP_EX and COMP_EX[k]["value"] != value:
        k = f"{key}{i}"; i += 1
    COMP_EX[k] = {"summary": summary or key, "value": value}
    return {"vi-du": {"$ref": f"#/components/examples/{k}"}}

def build():
    assert set(X) == {o[0] for o in spec.OPS}, set(X) ^ {o[0] for o in spec.OPS}
    assert len({o[0] for o in spec.OPS}) == len(spec.OPS)
    paths = {}
    EX.init(SCHEMAS)
    for code, method, path, summary, fr, perm, idem, success, group, own in spec.OPS:
        opid, body, resp, desc, extra = X[code]
        m = method.lower()
        op = {"tags": [TAGS[group]], "operationId": opid, "summary": summary, "x-datahub-id": f"API-10-{code}", "x-datahub-fr": frs_list(fr),
              "x-datahub-permission": perm_of(code, perm), "security": security_of(code, perm)}
        if desc: op["description"] = desc
        if idem: op["x-datahub-idempotent"] = "required" if idem == "x" else "optional"
        params = [P(PATH_PARAM[n]) for n in re.findall(r"\{(\w+)\}", path)]
        mutating = group not in DATA_GROUPS and group != "runtime" and (m in ("put", "patch", "delete") or (m == "post" and ":" in path.split("/")[-1]))
        ifmatch = mutating and code not in NO_IFMATCH
        if ifmatch: params.append(P("IfMatch"))
        for e in extra: params.append(P(e) if isinstance(e, str) else e)
        if idem == "x": params.append(P("IdempotencyKey"))
        if idem == "o": params.append(P("IdempotencyKeyOptional"))
        params += [P("Traceparent")]
        if group not in DATA_GROUPS: params.append(P("AcceptLanguage"))
        op["parameters"] = params
        errs = errs_of(code, method, path, body or code in ("075", "079"), own, idem, ifmatch)
        op["x-datahub-errors"] = [f"ERR-10-{e}" for e in errs]
        # thân yêu cầu
        if body:
            op["requestBody"] = {"required": True, "content": {"application/json": {"schema": R(body), "examples": xref(body, EX.request(code, body), f"Yêu cầu {body}")}}}
        elif code == "075":
            op["requestBody"] = {"required": True, "content": {"multipart/form-data": {"schema": {"type": "object", "required": ["file", "meta"],
                "properties": {"file": {"type": "string", "contentEncoding": "binary", "description": "YAML EventManifest, hoặc ZIP kiểm kê Pulsar theo mẫu (≤ 50 MiB)."},
                               "meta": R("ImportMeta")}}, "example": {"file": "(nhị phân)", "meta": EX.request("075m", "ImportMeta")}}}}
        elif code == "079":
            op["requestBody"] = {"required": True, "content": {
                "application/cloudevents+json": {"schema": R("CloudEvent"), "examples": xref("CloudEvent", EX.request("079", "CloudEvent"))},
                "application/cloudevents-batch+json": {"schema": R("CloudEventBatch"), "examples": xref("CloudEventBatch", EX.request("079b", "CloudEventBatch"))}}}
        # phản hồi thành công
        okr = {"description": "Thành công."}
        if code == "074":
            okr["content"] = {"application/yaml": {"schema": STR(), "example": EX.MANIFEST}}
        elif code == "084":
            okr["content"] = {"application/json": {"schema": ANYOBJ, "examples": xref("RegistryArtifact", EX.response("084", None))},
                              "application/vnd.schemaregistry.v1+json": {"schema": ANYOBJ}}
        elif code == "060":
            okr["content"] = {"application/json": {"schema": R(resp), "examples": xref(resp, EX.response(code, resp), resp)}, "text/csv": {"schema": STR()}}
        elif code == "118":
            okr["content"] = {"application/json": {"schema": R(resp), "examples": xref(resp, EX.response(code, resp), resp)},
                              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": {"schema": {"type": "string", "contentEncoding": "binary"}}}
        elif code == "024":
            okr["content"] = {"application/json": {"schema": R(resp), "examples": xref(resp, EX.response(code, resp), resp)}, "application/octet-stream": {"schema": STR()}}
        elif code == "080":
            okr["content"] = {"application/json": {"schema": R(resp), "examples": xref(resp, EX.response(code, resp), resp)}}
        elif resp and success != "204":
            okr["content"] = {"application/json": {"schema": R(resp), "examples": xref(resp, EX.response(code, resp), resp)}}
        hdr = {}
        if resp and code not in ("074", "084") and group not in DATA_GROUPS and ("Page" not in resp and "List" not in resp):
            hdr["ETag"] = {"schema": STR(), "description": "`W/\"{version}\"`."}
        if success in ("201", "202") and group not in DATA_GROUPS: hdr["Location"] = {"schema": STR(), "description": "Đường dẫn tài nguyên mới hoặc tác vụ."}
        if resp == "SigningKeyIssued": hdr["Cache-Control"] = {"schema": {"const": "no-store"}, "description": "Phản hồi chứa khóa ký; không lưu đệm."}
        if hdr: okr["headers"] = hdr
        resps = {success: okr}
        if code == "009":
            resps["202"] = {"description": "Máy đăng ký topic mới: đã tự duyệt hoặc chờ duyệt, đang cấp phát.", "content": {"application/json": {"schema": R("Topic"), "examples": xref("TopicCdc", EX.response("009m", "Topic"), "Topic CDC do PH-05 đăng ký")}}}
            resps["200"] = {"description": "Máy đăng ký lại topic đã có cùng cấu hình (idempotent).", "content": {"application/json": {"schema": R("Topic")}}}
        if code == "015":
            resps["200"] = {"description": "Áp dụng ngay, không cần duyệt.", "content": {"application/json": {"schema": R("TopicChangeResult")}}}
        if code == "064":
            resps["200"] = {"description": "Chạy thử (`dryRun=true`).", "content": {"application/json": {"schema": R("ReplayEstimate"), "examples": xref("ReplayEstimate", EX.response("064d", "ReplayEstimate"), "Ước lượng phát lại")}}}
        if code == "023":
            resps["200"] = {"description": "Máy gửi lại cùng nội dung (idempotent theo `contentHash`).", "content": {"application/json": {"schema": R("SchemaVersion")}}}
        if code == "074":
            resps["202"] = {"description": "Trên 10.000 đối tượng: chạy nền, `Location` tới tác vụ xuất (FR-00-031)."}
        if code == "080":
            resps["204"] = {"description": "Không có sự kiện sau `waitSeconds`."}
        if code == "073":
            resps["304"] = RESP("NotModified")
        for e in errs:
            st = ERRS[f"ERR-10-{e}"][0]
            if st.isdigit():
                resps[st] = RESP(STATUS_NAME[int(st)])
        op["responses"] = dict(sorted(resps.items()))
        item = paths.setdefault(path, {})
        if group in DATA_GROUPS and "servers" not in item:
            item["servers"] = [{"url": "https://event.{tenantHost}.datahub.example.vn" + spec.DATA_BASE, "description": "Cổng sự kiện qua `apisix-ext` (giả lập)",
                                "variables": {"tenantHost": {"default": "t68"}}},
                               {"url": "https://apisix-int.dh-edge.svc" + spec.DATA_BASE, "description": "Qua `apisix-int` cho HTTT trong TTDL"}]
        if group == "runtime" and "servers" not in item:
            item["servers"] = [{"url": "https://apisix-int.dh-edge.svc" + spec.BASE, "description": "Chỉ `dh-runtime` qua `apisix-int`, mTLS và token máy; không qua BFF"}]
        item[m] = op
    return {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-10 Sự kiện API", "version": "1.0.0-draft",
               "summary": "Dự án, topic, lược đồ, bên phát, bên nhận, publication, subscription, DLQ, phát lại, di trú Pulsar; cổng phát, kéo sự kiện.",
               "description": ("Control plane: module `event` của `dh-integration`, gốc `/api/event/v1` (người dùng qua BFF; PH-04, PH-05, PH-13, PH-18 "
                   "và `dh-runtime` bằng token máy). Data plane: cổng sự kiện của `dh-runtime`, gốc `/event/v1` qua `apisix-ext`, `apisix-int` cho HTTT "
                   "(scope `topic:{topicName}:publish|subscribe`). Giao ĐẨY webhook ký HMAC mô tả ở `asyncapi-event.yaml`.\n\nQuy ước (D03-04-PH10 §1): "
                   "tenant lấy từ token; tạo nhận `Idempotency-Key`; sửa và hành động bắt buộc `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-10-nnn`; "
                   "phân trang `page`, `size`. Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-10"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH10", "x-datahub-phase": "PH-10"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn" + spec.BASE, "description": "Qua BFF console của tenant (giả lập)",
                   "variables": {"tenantHost": {"default": "t68", "description": "Ví dụ `t68` (giả lập)."}}},
                  {"url": "http://dh-integration.dh-control.svc:8080" + spec.BASE, "description": "Trong cụm, cho PH-04, PH-05, PH-13, PH-18"},
                  {"url": "http://localhost:8081" + spec.BASE, "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": v, "description": f"Nhóm {v}; bảng mã ở D03-04-PH10 §3."} for v in TAGS.values()],
      "paths": paths,
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm `dh-{tenant}`, Authorization Code + PKCE qua BFF; vai trò ánh xạ PERM-10-* (D02-08, FRS §3.2).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Tài khoản dịch vụ (`client_credentials` + `private_key_jwt`, mTLS mesh). Scope không cấp cho người.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"event:topic-register": "PH-05, DU nội bộ đăng ký topic CDC, SYSTEM và phiên bản lược đồ",
                           "event:permission-check": "PH-04 kiểm tra quyền phát, nhận và tra cứu topic",
                           "event:runtime-config": "dh-runtime đọc cấu hình, báo giao nhận, ngắt mạch, cầu nối",
                           "event:dlq-read": "PH-18 đọc siêu dữ liệu DLQ", "event:replay": "PH-18 đề nghị phát lại; dh-runtime chạy phát lại",
                           "event:metrics-read": "PH-13 đọc lag, dashboard"}}}},
          "oauth2System": {"type": "oauth2", "description": "Token HTTT (`client_credentials`), scope `topic:{topicName}:publish`, `topic:{topicName}:subscribe` cấp khi publication, subscription được duyệt.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"topic:{topicName}:publish": "Phát lên topic", "topic:{topicName}:subscribe": "Nhận từ topic"}}}},
          "mtlsSystem": {"type": "mutualTLS", "description": "Chứng thư khách do CA nội bộ cấp qua PH-12; principal `CN={systemCode}.{tenant}`."}},
        "parameters": PARAMS, "responses": RESPONSES, "examples": COMP_EX, "schemas": SCHEMAS}}

def _str_rep(dumper, v):
    # Chuỗi toàn chữ số (mã số thuế, offset) luôn đặt trong nháy để bộ đọc YAML 1.2 không hiểu thành số.
    style = "'" if v.isdigit() or v in ("true", "false", "null", "yes", "no", "on", "off") else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", v, style=style)
yaml.SafeDumper.add_representer(str, _str_rep)

if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-event.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH10 · OpenAPI PH-10 (dh-integration module event; cổng sự kiện dh-runtime). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(1 for v in doc["paths"].values() for k in v if k != "servers")
    print(f"{n} operation, {len(SCHEMAS)} lược đồ, {len(doc['paths'])} đường dẫn → {out}")
