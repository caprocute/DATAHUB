#!/usr/bin/env python3
"""Sinh ph05/openapi-adapter.yaml từ spec.OPS (bảng mã API) và lược đồ trong tệp này.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph05)
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
def allow(*schemas):
    return {"allOf": list(schemas) + [R("AllowedActions")]}

STR = lambda mx=None, **kw: s("string", **({"maxLength": mx} if mx else {}), **kw)
INT = lambda **kw: s("integer", **kw)
NUM = s("number")
BOOL = s("boolean")
TS = s("string", format="date-time")
DATE = s("string", format="date")
UUID = s("string", format="uuid")
ANYOBJ = {"type": "object", "additionalProperties": True}
CNT = {"type": "object", "additionalProperties": INT()}

SCHEMAS = {
  # ---- chung
  "ConnectionCode": STR(63, pattern="^[a-z][a-z0-9-]{2,62}$", description="Mã kết nối, bất biến, không dùng lại (BR-05-004)."),
  "AdapterCode": STR(40, pattern="^[a-z][a-z0-9-]{2,39}$"),
  "OperationCode": STR(41, pattern="^[a-z][a-z0-9-]{1,40}$"),
  "KameletName": STR(100, pattern="^[a-z][a-z0-9-]{2,90}-(sink|source|action)$"),
  "TypeCode": STR(32, pattern="^[a-z][a-z0-9-]{1,31}$"),
  "SystemCode": STR(64, description="Mã HTTT ở PH-01."),
  "Environment": enum("TEST", "STAGING", "PROD"),
  "ConnectionStatus": enum("DRAFT", "ACTIVE", "SUSPENDED", "RETIRED"),
  "EnvStatus": enum("CONFIGURED", "PENDING_APPROVAL", "ENABLED", "DISABLED"),
  "Purpose": enum("READ", "READ_WRITE"),
  "Protocol": enum("REST", "SOAP", "MESSAGING", "FILE", "DATABASE", "MAIL", "DIRECTORY", "CDC"),
  "ProtocolGroup": enum("HTTP", "SOAP", "JDBC", "FILE", "MESSAGING", "MAIL", "DIRECTORY", "CDC"),
  "AdapterStatus": enum("DRAFT", "ACTIVE", "SUSPENDED", "RETIRED"),
  "VersionStatus": enum("DRAFT", "SUBMITTED", "APPROVED", "SUPERSEDED"),
  "HealthLevel": enum("HEALTHY", "DEGRADED", "UNHEALTHY", "UNKNOWN"),
  "CdcState": enum("STOPPED", "SNAPSHOTTING", "STREAMING", "PAUSED", "PAUSED_SCHEMA", "FAILED"),
  "KameletScope": enum("BASE", "COMMON", "TENANT"),
  "KameletType": enum("source", "sink", "action"),
  "KameletStatus": enum("DRAFT", "SUBMITTED", "APPROVED", "DEPRECATED", "WITHDRAWN"),
  "AccountStatus": enum("REQUESTED", "CONSENTED", "ISSUED", "REJECTED", "REVOKED", "EXPIRED"),
  "AccessMode": enum("READ", "WRITE"),
  "Format": enum("JSON", "XML", "SOAP", "CSV", "FIXED_WIDTH", "TEXT", "BINARY"),
  "Reason": STR(1000, minLength=10, description="Lý do 10…1.000 ký tự (ERR-05-038 khi thiếu)."),
  "AllowedActions": obj({
      "allowedActions": arr(STR(), description="Hành động người gọi được làm ngay bây giờ."),
      "disabledReasons": {"type": "object", "additionalProperties": STR(), "description": "Hành động có quyền nhưng trạng thái chưa cho phép → lý do tiếng Việt."}}),
  "CursorMeta": obj({"next": {"type": ["string", "null"], "maxLength": 2048}, "hasMore": BOOL}, req=["hasMore"]),
  "ProblemDetails": {
      "type": "object", "description": "RFC 9457, mở rộng theo D03-04-PH05 §1.",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {
          "type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(), "instance": STR(),
          "code": STR(pattern="^ERR-05-[0-9]{3}$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(obj({"path": STR(), "rule": STR(), "message": STR()})),
          "usages": arr(R("Usage"), description="Kèm ERR-05-010."),
          "findings": arr(R("StaticFinding"), description="Kèm ERR-05-020…022."),
          "currentEtag": STR(), "retryAfterSeconds": INT()},
      "additionalProperties": True},
  # ---- loại kết nối
  "ConnectionType": obj({
      "typeCode": R("TypeCode"), "title": STR(255), "group": R("ProtocolGroup"), "supportLevel": enum("STABLE", "PREVIEW", "DEPRECATED"),
      "secretKeys": arr(STR(64), description="Khóa bí mật khai qua API-05-012; không bao giờ trả giá trị."),
      "kamelets": arr(R("KameletName")), "probeSteps": arr(STR(32)), "runtimeProfiles": arr(STR(16)),
      "enabledForTenant": BOOL, "blockNew": BOOL, "ceilings": ANYOBJ}, req=["typeCode", "title", "group", "secretKeys"]),
  "ConnectionTypeDetail": {"allOf": [R("ConnectionType"), obj({"paramsSchema": ANYOBJ, "example": ANYOBJ}, req=["paramsSchema"])]},
  "ConnectionTypeList": obj({"items": arr(R("ConnectionType"))}, req=["items"]),
  # ---- kết nối
  "EnvSummary": obj({"env": R("Environment"), "status": R("EnvStatus"), "secretVersion": INT(), "hasPendingChange": BOOL,
      "lastPassedAt": {"type": ["string", "null"], "format": "date-time"}, "health": R("HealthLevel")}, req=["env", "status"]),
  "ConnectionSummary": allow(obj({
      "code": R("ConnectionCode"), "name": STR(255), "typeCode": R("TypeCode"), "systemCode": R("SystemCode"), "systemName": STR(255),
      "purpose": R("Purpose"), "status": R("ConnectionStatus"), "owner": STR(64), "labels": arr(STR(32), maxItems=10),
      "environments": arr(R("EnvSummary")), "usageCount": INT(), "secretAgeDays": INT(), "updatedAt": TS},
      req=["code", "name", "typeCode", "systemCode", "status"])),
  "ConnectionPage": obj({"items": arr(R("ConnectionSummary")), "page": R("CursorMeta"),
      "facets": obj({"status": CNT, "typeCode": CNT, "health": CNT})}, req=["items", "page"]),
  "ConnectionDetail": {"allOf": [R("ConnectionSummary"), obj({
      "description": STR(2000), "configVersion": INT(), "legacyRef": STR(255), "createdAt": TS, "createdBy": STR(64),
      "statusReason": STR(1000), "retiredAt": TS, "grantsCount": INT(), "flowAccountsCount": INT()})]},
  "ConnectionCreate": obj({"connectionCode": R("ConnectionCode"), "name": STR(255, minLength=3), "typeCode": R("TypeCode"),
      "systemCode": R("SystemCode"), "purpose": R("Purpose"), "description": STR(2000), "owner": STR(64), "labels": arr(STR(32), maxItems=10)},
      req=["connectionCode", "name", "typeCode", "systemCode", "purpose"]),
  "ConnectionUpdate": obj({"name": STR(255, minLength=3), "description": STR(2000), "owner": STR(64), "labels": arr(STR(32), maxItems=10),
      "purpose": R("Purpose")}, desc="Không đổi được mã, loại, HTTT (tạo kết nối mới)."),
  "StateChangeRequest": obj({"reason": R("Reason"), "incidentRef": STR(128)}, req=["reason"]),
  "Environment_": obj({"env": R("Environment"), "status": R("EnvStatus"), "params": ANYOBJ, "paramsHash": STR(64),
      "pendingParams": ANYOBJ, "secretVersion": INT(), "secretKeysSet": arr(STR(64), description="Khóa đã có giá trị (không trả giá trị)."),
      "secretWrittenBy": STR(64), "secretWrittenAt": TS, "lastPassedTestId": UUID, "lastPassedAt": TS, "testValidUntil": TS,
      "requestedBy": STR(64), "approvedBy": STR(64), "approvedAt": TS}, req=["env", "status", "params", "secretVersion"]),
  "EnvironmentList": obj({"items": arr({"allOf": [R("Environment_"), R("AllowedActions")]})}, req=["items"]),
  "EnvironmentParams": obj({"params": ANYOBJ}, req=["params"], desc="Kiểm theo `paramsSchema` của loại; khóa bí mật trả ERR-05-006."),
  "SecretPayload": obj({"secrets": {"type": "object", "maxProperties": 16, "additionalProperties": STR(16384), "writeOnly": True}},
      req=["secrets"], desc="Chỉ ghi. Giá trị không bao giờ được trả lại, không vào log, không vào sự kiện (BR-05-001)."),
  "EnableRequest": obj({"note": STR(1000)}),
  "ApprovalDecision": obj({"comment": STR(2000)}),
  "RejectRequest": obj({"reason": R("Reason")}, req=["reason"]),
  "RotateRequest": obj({"secrets": {"type": "object", "maxProperties": 16, "additionalProperties": STR(16384), "writeOnly": True},
      "transitionMinutes": INT(minimum=5, maximum=10080, default=1440), "reason": STR(1000)}, req=["secrets"]),
  "Rotation": obj({"id": UUID, "env": R("Environment"), "oldVersion": INT(), "newVersion": INT(),
      "status": enum("TESTING", "TRANSITION", "COMPLETED", "FAILED"), "testId": UUID, "transitionUntil": TS, "completedAt": TS,
      "createdBy": STR(64), "createdAt": TS}, req=["id", "env", "status"]),
  "RotationList": obj({"items": arr(R("Rotation"))}, req=["items"]),
  # ---- kiểm tra
  "TestStep": obj({"name": STR(32), "status": enum("PASSED", "FAILED", "SKIPPED", "TIMEOUT"), "durationMs": INT(),
      "causeCode": STR(32), "hint": STR(1000, description="Hướng dẫn khắc phục tiếng Việt; không chứa bí mật.")}, req=["name", "status"]),
  "TestRequest": obj({"probeOverride": STR(255, description="Đường dẫn thăm dò khác mặc định (chỉ GET, HEAD, OPTIONS)."), "timeoutMs": INT(minimum=1000, maximum=60000)}),
  "ConnectionTest": obj({"id": UUID, "env": R("Environment"), "kind": enum("MANUAL", "ROTATION", "PRIVILEGE", "CDC_PREREQ"),
      "status": enum("RUNNING", "PASSED", "FAILED"), "steps": arr(R("TestStep")), "causeCode": STR(32), "latencyMs": INT(),
      "secretVersion": INT(), "paramsHash": STR(64), "startedAt": TS, "finishedAt": TS, "expiresAt": TS, "runBy": STR(64)}, req=["id", "env", "status"]),
  "ConnectionTestPage": obj({"items": arr(R("ConnectionTest")), "page": R("CursorMeta")}, req=["items", "page"]),
  # ---- cấp, nơi dùng, lịch sử
  "Grant": obj({"id": UUID, "scope": enum("WORKSPACE", "FLOW"), "targetCode": STR(63), "environments": arr(R("Environment"), minItems=1),
      "validUntil": DATE, "reason": STR(1000), "createdBy": STR(64), "createdAt": TS}, req=["id", "scope", "targetCode", "environments"]),
  "GrantCreate": obj({"scope": enum("WORKSPACE", "FLOW"), "targetCode": STR(63), "environments": arr(R("Environment"), minItems=1, maxItems=3),
      "validUntil": DATE, "reason": STR(1000)}, req=["scope", "targetCode", "environments"]),
  "GrantList": obj({"items": arr(R("Grant"))}, req=["items"]),
  "Usage": obj({"kind": enum("FLOW_VERSION", "ADAPTER_VERSION", "KAMELET"), "code": STR(100), "version": INT(),
      "workspaceCode": STR(63), "env": R("Environment"), "deployed": BOOL, "keysUsed": arr(STR(64))}, req=["kind", "code"]),
  "UsageList": obj({"items": arr(R("Usage")), "total": INT()}, req=["items"]),
  "HistoryEntry": obj({"at": TS, "action": STR(64), "actor": STR(64), "env": R("Environment"), "reason": STR(1000),
      "before": {}, "after": {}, "traceId": STR()}, req=["at", "action", "actor"]),
  "HistoryPage": obj({"items": arr(R("HistoryEntry")), "page": R("CursorMeta")}, req=["items", "page"]),
  # ---- nhập hệ cũ
  "LegacyImportJob": obj({"id": UUID, "status": enum("SCANNING", "REVIEW", "APPLIED", "FAILED", "CANCELLED"), "fileName": STR(255),
      "findings": arr(obj({"file": STR(255), "line": INT(), "column": INT(), "kind": enum("SECRET_REMOVED", "INLINE_PASSWORD_URI", "UNKNOWN_SCHEME", "DUPLICATE"),
          "key": STR(64), "message": STR(500)})),
      "proposals": arr(obj({"proposalId": STR(32), "typeCode": R("TypeCode"), "suggestedCode": R("ConnectionCode"), "params": ANYOBJ,
          "secretKeysNeeded": arr(STR(64)), "occurrences": INT(), "legacyRefs": arr(STR(255))})),
      "createdConnections": arr(R("ConnectionCode")), "startedAt": TS, "finishedAt": TS}, req=["id", "status"]),
  "LegacyCommit": obj({"items": arr(obj({"proposalId": STR(32), "connectionCode": R("ConnectionCode"), "name": STR(255),
      "systemCode": R("SystemCode"), "env": R("Environment")}, req=["proposalId", "connectionCode", "systemCode"]), minItems=1, maxItems=200)}, req=["items"]),
  # ---- nội bộ cho PH-04, runtime
  "VerifyRequest": obj({"workspaceCode": STR(63), "flowCode": STR(63), "flowVersion": INT(minimum=1),
      "stage": enum("DESIGN", "SUBMIT", "PUBLISH"), "targetEnv": R("Environment"),
      "references": arr(obj({"kind": enum("CONNECTION", "ADAPTER", "KAMELET"), "code": STR(100), "operationCode": STR(41),
          "keysUsed": arr(STR(64)), "accessMode": R("AccessMode")}, req=["kind", "code"]), maxItems=200)},
      req=["workspaceCode", "flowCode", "stage", "references"]),
  "VerifyResult": obj({"allOk": BOOL, "results": arr(obj({"index": INT(), "status": enum("OK", "NOT_FOUND", "NOT_GRANTED", "NOT_ENABLED",
      "SUSPENDED", "UNKNOWN_KEY", "MODE_MISMATCH", "WITHDRAWN", "DEPRECATED"), "code": STR(), "message": STR()}, req=["index", "status"]))}, req=["allOk", "results"]),
  "RuntimeConfig": obj({"tenant": STR(16), "env": R("Environment"), "generatedAt": TS, "configVersion": INT(),
      "connections": arr(obj({"code": R("ConnectionCode"), "typeCode": R("TypeCode"), "status": R("EnvStatus"), "params": ANYOBJ,
          "secretPath": STR(255, description="Đường dẫn KV, không phải giá trị."), "secretVersion": INT(), "fallbackSecretVersion": {"type": ["integer", "null"]},
          "dbRole": STR(63), "limits": obj({"maxConcurrencyPerReplica": INT(), "acquireTimeoutMs": INT()})}, req=["code", "status", "secretPath", "secretVersion"])),
      "adapters": arr(obj({"code": R("AdapterCode"), "status": R("AdapterStatus"), "version": STR(16), "maxConcurrency": INT(), "replicas": INT()}))},
      req=["tenant", "env", "configVersion", "connections"]),
  "HealthStateList": obj({"items": arr(R("HealthState"))}, req=["items"]),
  "KameletCatalog": obj({"tenant": STR(16), "runtimeProfile": STR(16), "catalogHash": STR(71),
      "items": arr(obj({"name": R("KameletName"), "scope": R("KameletScope"), "type": R("KameletType"), "version": STR(20),
          "status": R("KameletStatus"), "yamlHash": STR(64), "title": STR(255), "group": STR(32),
          "parameters": arr(R("KameletParam"))}, req=["name", "version", "yamlHash"]))}, req=["items", "catalogHash"]),
  # ---- sức khỏe
  "HealthState": obj({"kind": enum("CONNECTION", "ADAPTER"), "code": STR(63), "env": R("Environment"), "level": R("HealthLevel"),
      "reasonCode": STR(32), "reasonDetail": STR(1000), "since": TS, "evaluatedAt": TS,
      "metrics": obj({"calls5m": INT(), "errorRate5m": NUM, "p95Ms": INT(), "baselineP95Ms": INT(), "poolWaitP95Ms": INT(), "lastProbeOk": BOOL})},
      req=["kind", "code", "env", "level"]),
  "HealthDetail": {"allOf": [R("HealthState"), obj({"series": arr(obj({"name": enum("calls", "errors", "p95Ms", "poolWaitMs", "level"),
      "points": arr(arr(NUM, minItems=2, maxItems=2))})), "transitions": arr(obj({"at": TS, "from": R("HealthLevel"), "to": R("HealthLevel"), "reasonCode": STR(32)}))})]},
  "HealthOverview": obj({"totals": obj({"connections": CNT, "adapters": CNT}), "attention": arr(R("HealthState"), maxItems=50),
      "secretsOverdue": INT(), "secretsDueIn14d": INT(), "writeAccountsActive": INT(), "cdcLagging": INT(), "pendingSchemaChanges": INT(),
      "pendingApprovals": INT()}, req=["totals", "attention"]),
  # ---- tài khoản CSDL
  "FlowAccount": allow(obj({"id": UUID, "flowCode": STR(63), "env": R("Environment"), "accessMode": R("AccessMode"),
      "provisioning": enum("DYNAMIC", "STATIC"), "schemas": arr(STR(63)), "tables": arr(STR(127)),
      "operations": arr(enum("SELECT", "INSERT", "UPDATE", "DELETE")), "status": R("AccountStatus"), "validUntil": DATE,
      "openbaoRole": STR(63), "ttlSeconds": INT(), "justification": STR(2000), "requestedBy": STR(64), "consentedBy": STR(64),
      "approvedBy": STR(64), "revokedAt": TS, "lastPrivilegeTest": R("PrivilegeReport")}, req=["id", "flowCode", "env", "accessMode", "status"])),
  "FlowAccountList": obj({"items": arr(R("FlowAccount"))}, req=["items"]),
  "FlowAccountRequest": obj({"flowCode": STR(63), "environments": arr(R("Environment"), minItems=1, maxItems=3),
      "schemas": arr(STR(63), minItems=1), "tables": arr(STR(127)), "accessMode": R("AccessMode"),
      "operations": arr(enum("SELECT", "INSERT", "UPDATE", "DELETE")), "validUntil": DATE,
      "justification": STR(2000, minLength=30), "ownerConsentRef": STR(255)}, req=["flowCode", "environments", "schemas", "accessMode", "justification"]),
  "ConsentRequest": obj({"opinion": STR(2000, minLength=10), "ownerConsentRef": STR(255)}, req=["opinion"]),
  "PrivilegeReport": obj({"testedAt": TS, "username": STR(128), "verdict": enum("OK", "EXCESSIVE", "INSUFFICIENT"),
      "grants": arr(obj({"schema": STR(63), "table": STR(127), "privilege": STR(32), "expected": BOOL})),
      "attributes": arr(STR(32), description="SUPERUSER, CREATEROLE, BYPASSRLS… nếu có.")}, req=["verdict", "grants"]),
  "DbAccessRecord": obj({"eventId": UUID, "occurredAt": TS, "connectionCode": STR(63), "flowCode": STR(63), "flowVersion": INT(),
      "env": R("Environment"), "dbUsername": STR(128), "statementHash": STR(64), "statementKind": enum("SELECT", "INSERT", "UPDATE", "DELETE", "CALL"),
      "rowCount": INT(), "durationMs": INT(), "outcome": enum("OK", "DENIED", "ERROR"), "traceId": STR(32)}, req=["eventId", "occurredAt", "flowCode", "statementHash"]),
  "DbAccessPage": obj({"items": arr(R("DbAccessRecord")), "page": R("CursorMeta"), "summary": obj({"statements": INT(), "rows": INT(), "denied": INT()})}, req=["items", "page"]),
  # ---- bộ điều hợp
  "AdapterSummary": allow(obj({"code": R("AdapterCode"), "name": STR(255), "systemCode": R("SystemCode"), "systemGroup": INT(minimum=1, maximum=4),
      "protocol": R("Protocol"), "connectionCode": R("ConnectionCode"), "status": R("AdapterStatus"), "effectiveVersion": {"type": ["string", "null"]},
      "hasDraft": BOOL, "health": R("HealthLevel"), "p95Ms1h": INT(), "errorRate1h": NUM, "calls24h": INT(),
      "cdcLagSeconds": {"type": ["integer", "null"]}, "pendingSchemaChanges": INT(), "updatedAt": TS}, req=["code", "name", "protocol", "status"])),
  "AdapterPage": obj({"items": arr(R("AdapterSummary")), "page": R("CursorMeta"),
      "facets": obj({"protocol": CNT, "status": CNT, "health": CNT, "systemGroup": CNT}),
      "cards": obj({"total": INT(), "active": INT(), "degraded": INT(), "unhealthy": INT()})}, req=["items", "page"]),
  "AdapterDetail": {"allOf": [R("AdapterSummary"), obj({"description": STR(2000), "owner": STR(64), "effective": R("AdapterVersion"),
      "draft": R("AdapterVersion"), "lastTest": R("AdapterTest"), "usageCount": INT()})]},
  "AdapterCreate": obj({"adapterCode": R("AdapterCode"), "name": STR(255, minLength=3), "systemCode": R("SystemCode"),
      "systemGroup": INT(minimum=1, maximum=4), "protocol": R("Protocol"), "connectionCode": R("ConnectionCode"),
      "description": STR(2000), "owner": STR(64)}, req=["adapterCode", "name", "systemCode", "systemGroup", "protocol", "connectionCode"]),
  "AdapterUpdate": obj({"name": STR(255, minLength=3), "description": STR(2000), "owner": STR(64)}),
  "VersionLimits": obj({"maxConcurrency": INT(minimum=1, maximum=500, default=20, description="Tổng trên mọi bản sao (BR-05-029); trần tenant 05.adapter.max-concurrency."), "poolMinIdle": INT(minimum=0, default=1), "acquireTimeoutMs": INT(minimum=100, maximum=30000, default=3000),
      "idleTimeoutSeconds": INT(minimum=10, maximum=3600, default=300), "rateLimit": obj({"permits": INT(minimum=1), "periodSeconds": INT(minimum=1)})}),
  "AdapterVersion": allow(obj({"version": STR(16, pattern="^[0-9]+\\.[0-9]+$"), "status": R("VersionStatus"), "limits": R("VersionLimits"),
      "spec": obj({"kind": enum("OPENAPI", "WSDL", "XSD", "CSV_HDR"), "hash": STR(64), "fetchedAt": TS, "downloadUrl": STR(format="uri")}),
      "contentHash": STR(64), "operations": arr(R("Operation")), "changeNote": STR(2000), "lastTestId": UUID,
      "submittedBy": STR(64), "submittedAt": TS, "approvedBy": STR(64), "approvedAt": TS, "rejectReason": STR(2000)}, req=["version", "status", "operations"])),
  "AdapterVersionList": obj({"items": arr(obj({"version": STR(16), "status": R("VersionStatus"), "operations": INT(), "approvedAt": TS, "approvedBy": STR(64)}))}, req=["items"]),
  "NewVersionRequest": obj({"fromVersion": STR(16), "bump": enum("MINOR", "MAJOR"), "changeNote": STR(2000)}, req=["bump"]),
  "Pagination": obj({"mode": enum("NONE", "PAGE_NUMBER", "OFFSET_LIMIT", "CURSOR", "LINK_HEADER"), "pageParam": STR(64), "sizeParam": STR(64),
      "startAt": INT(minimum=0), "pageSize": INT(minimum=1, maximum=1000), "cursorParam": STR(64), "cursorPath": STR(255), "itemsPath": STR(255),
      "hasMorePath": STR(255), "maxPages": INT(minimum=1, maximum=500, default=50)}, req=["mode"]),
  "Normalization": obj({"fields": arr(obj({"path": STR(255), "type": enum("STRING", "INTEGER", "DECIMAL", "BOOLEAN", "DATE", "DATETIME"),
      "sourceFormat": STR(64), "required": BOOL, "missingValues": arr(STR(64), maxItems=20, description="Giá trị coi là thiếu thêm cho trường (ngoài mặc định chung)."),
      "onMissing": enum("DEFAULT", "REJECT", "PASS_NULL"), "default": {}}, req=["path", "type"]), maxItems=500),
      "missingValues": arr(STR(64), maxItems=20, description="Mặc định chung: \"\", \"null\", \"NULL\", \"N/A\", \"-\"."),
      "namespaces": {"type": "object", "additionalProperties": STR(255)}, "arrays": arr(STR(255)), "encoding": enum("UTF-8", "windows-1258", "TCVN3")}),
  "Operation": obj({"operationCode": R("OperationCode"), "title": STR(255), "direction": enum("OUTBOUND", "INBOUND"),
      "protocolSpec": ANYOBJ, "requestFormat": R("Format"), "responseFormat": R("Format"),
      "requestSchemaRef": STR(255), "responseSchemaRef": STR(255), "normalization": R("Normalization"), "pagination": R("Pagination"),
      "timeoutMs": INT(minimum=100, maximum=120000), "idempotent": BOOL, "sideEffect": enum("NONE", "WRITE", desc="WRITE chỉ khi kết nối READ_WRITE (ERR-05-017)."),
      "sampleRequest": STR(1048576), "sampleResponse": STR(1048576), "kameletName": R("KameletName")},
      req=["operationCode", "title", "direction", "protocolSpec", "requestFormat", "responseFormat", "timeoutMs", "sideEffect"]),
  "AdapterTestRequest": obj({"env": enum("TEST", "STAGING"), "operations": arr(R("OperationCode")), "inputs": {"type": "object", "additionalProperties": ANYOBJ}}, req=["env"]),
  "AdapterTest": obj({"id": UUID, "version": STR(16), "env": enum("TEST", "STAGING"), "mode": enum("SINGLE", "COMPARE"), "status": enum("RUNNING", "PASSED", "FAILED"),
      "results": arr(obj({"operationCode": STR(41), "status": enum("PASSED", "FAILED", "SKIPPED"), "latencyMs": INT(), "outputPreview": STR(65536, description="Đã che (DH-MASK)."),
          "errors": arr(obj({"code": STR(16), "path": STR(255), "message": STR(500)}), maxItems=20)})),
      "startedAt": TS, "finishedAt": TS, "runBy": STR(64), "validUntil": TS}, req=["id", "status"]),
  "TransformPreviewRequest": obj({"operationCode": R("OperationCode"), "direction": enum("RESPONSE", "REQUEST"), "sample": STR(1048576),
      "normalization": R("Normalization")}, req=["operationCode", "sample"]),
  "TransformPreview": obj({"output": {}, "warnings": arr(obj({"path": STR(255), "message": STR(500)})),
      "errors": arr(obj({"path": STR(255), "message": STR(500)}), maxItems=20), "missingFields": arr(STR(255)), "durationMs": INT()}, req=["output"]),
  "SubmitRequest": obj({"changeNote": STR(2000, minLength=10)}, req=["changeNote"]),
  "CompareRequest": obj({"baseVersion": STR(16), "sampleRatePercent": INT(minimum=1, maximum=20, default=5), "durationMinutes": INT(minimum=5, maximum=1440, default=60),
      "ignorePaths": arr(STR(255))}, req=["baseVersion"]),
  "Comparison": obj({"id": UUID, "baseVersion": STR(16), "candidateVersion": STR(16), "status": enum("RUNNING", "PASSED", "FAILED"),
      "samples": INT(), "identical": INT(), "different": INT(), "diffs": arr(obj({"operationCode": STR(41), "path": STR(255), "count": INT(), "example": STR(2000)}), maxItems=100),
      "startedAt": TS, "finishedAt": TS}, req=["id", "status"]),
  "FromSpecRequest": obj({"adapterCode": R("AdapterCode"), "name": STR(255), "systemCode": R("SystemCode"), "systemGroup": INT(minimum=1, maximum=4),
      "connectionCode": R("ConnectionCode"), "specKind": enum("OPENAPI", "WSDL"), "specUrl": STR(2048, format="uri"),
      "includeOperations": arr(STR(255), description="operationId hoặc tên thao tác WSDL; rỗng = tất cả (tối đa 200).")},
      req=["adapterCode", "name", "systemCode", "systemGroup", "connectionCode", "specKind"]),
  # ---- CDC
  "CdcConfig": allow(obj({"env": R("Environment"), "engine": enum("POSTGRESQL", "MYSQL", "ORACLE", "SQLSERVER"),
      "tables": arr(STR(127), minItems=1), "columnExcludes": arr(STR(255)), "columnHashes": arr(STR(255)),
      "snapshotMode": enum("INITIAL", "NO_DATA", "WHEN_NEEDED"), "topicPrefix": STR(200), "connectorName": STR(200),
      "state": R("CdcState"), "stateReason": STR(1000), "lastPosition": STR(255), "positionAt": TS, "lagSeconds": INT(),
      "snapshotProgress": NUM, "retainedWalBytes": INT(), "pendingSchemaChanges": INT(),
      "perTable": arr(obj({"table": STR(127), "topic": STR(249), "events24h": obj({"c": INT(), "u": INT(), "d": INT()}), "lastEventAt": TS})),
      "prerequisites": R("ConnectionTest")}, req=["env", "engine", "tables", "state"])),
  "CdcConfigUpdate": obj({"env": R("Environment"), "tables": arr(STR(127), minItems=1, maxItems=500), "columnExcludes": arr(STR(255)),
      "columnHashes": arr(STR(255)), "snapshotMode": enum("INITIAL", "NO_DATA", "WHEN_NEEDED")}, req=["env", "tables"]),
  "CdcAction": obj({"env": R("Environment"), "reason": R("Reason")}, req=["env", "reason"]),
  "SchemaChange": allow(obj({"id": UUID, "adapterCode": R("AdapterCode"), "env": R("Environment"), "table": STR(127),
      "changeKind": enum("ADD_COLUMN", "DROP_COLUMN", "RENAME_COLUMN", "ALTER_TYPE", "ALTER_PK", "DROP_TABLE", "RENAME_TABLE", "OTHER"),
      "severity": enum("COMPATIBLE", "BREAKING"), "ddl": STR(), "diff": arr(obj({"column": STR(127), "before": STR(), "after": STR()})),
      "affectedFlows": arr(STR(63)), "detectedAt": TS, "status": enum("PENDING", "RESOLVED", "AUTO"),
      "resolution": enum("ACCEPT", "MAP_COLUMN", "EXCLUDE_TABLE", "RESNAPSHOT"), "resolvedBy": STR(64), "resolvedAt": TS}, req=["id", "table", "changeKind", "severity", "status"])),
  "SchemaChangePage": obj({"items": arr(R("SchemaChange")), "page": R("CursorMeta")}, req=["items", "page"]),
  "SchemaResolve": obj({"resolution": enum("ACCEPT", "MAP_COLUMN", "EXCLUDE_TABLE", "RESNAPSHOT"),
      "columnMap": {"type": "object", "additionalProperties": STR(127)}, "comment": STR(2000, minLength=10)}, req=["resolution", "comment"]),
  # ---- Kamelet
  "KameletParam": obj({"name": STR(64), "title": STR(255), "type": enum("string", "boolean", "integer", "long", "binary"), "required": BOOL,
      "default": {}, "secret": BOOL, "description": STR(1000)}, req=["name", "type"]),
  "KameletSummary": allow(obj({"name": R("KameletName"), "scope": R("KameletScope"), "type": R("KameletType"), "group": STR(32), "title": STR(255),
      "latestVersion": STR(20), "status": R("KameletStatus"), "generated": BOOL, "owner": STR(64), "usageCount": INT(),
      "runtimeProfiles": arr(STR(16))}, req=["name", "scope", "type", "status"])),
  "KameletPage": obj({"items": arr(R("KameletSummary")), "page": R("CursorMeta"), "facets": obj({"scope": CNT, "type": CNT, "status": CNT, "group": CNT})}, req=["items", "page"]),
  "KameletDetail": {"allOf": [R("KameletSummary"), obj({"versions": arr(obj({"version": STR(20), "status": R("KameletStatus"), "origin": enum("EDITOR", "DESIGNER", "GENERATED", "PLATFORM"),
      "yamlHash": STR(64), "approvedBy": STR(64), "approvedAt": TS})), "parameters": arr(R("KameletParam")), "sourceAdapter": STR(40)})]},
  "KameletVersion": allow(obj({"name": R("KameletName"), "version": STR(20), "status": R("KameletStatus"), "yaml": STR(262144), "yamlHash": STR(64),
      "parameters": arr(R("KameletParam")), "runtimeProfiles": arr(STR(16)), "staticCheck": R("StaticCheckResult"),
      "origin": enum("EDITOR", "DESIGNER", "GENERATED", "PLATFORM"), "submittedBy": STR(64), "approvedBy": STR(64), "soOpinion": STR(2000), "statusReason": STR(1000)},
      req=["name", "version", "status", "yaml", "yamlHash"])),
  "KameletCreate": obj({"name": R("KameletName"), "version": STR(20, pattern="^[0-9]+\\.[0-9]+\\.[0-9]+$"), "title": STR(255), "group": STR(32),
      "yaml": STR(262144), "runtimeProfiles": arr(STR(16), minItems=1)}, req=["name", "version", "yaml", "runtimeProfiles"]),
  "KameletDraftUpdate": obj({"yaml": STR(262144), "runtimeProfiles": arr(STR(16), minItems=1)}, req=["yaml"]),
  "StaticFinding": obj({"rule": STR(pattern="^KR-[0-9]{2}$"), "level": enum("ERROR", "WARN"), "line": INT(), "message": STR(500)}, req=["rule", "level", "message"]),
  "StaticCheckResult": obj({"passed": BOOL, "checkedAt": TS, "camelVersion": STR(16), "findings": arr(R("StaticFinding"))}, req=["passed", "findings"]),
  "KameletDecision": obj({"comment": STR(2000), "soOpinion": STR(2000)}),
  "ProposeCommon": obj({"justification": STR(2000, minLength=30)}, req=["justification"]),
  # ---- tham số, báo cáo
  "Settings": obj({"params": {"type": "object", "additionalProperties": {}, "description": "Tham số 05.* hiệu lực (FRS §7.2)."},
      "connectionTypes": arr(R("ConnectionType"))}, req=["params", "connectionTypes"]),
  "ConnectionTypeSetting": obj({"enabled": BOOL, "blockNew": BOOL, "ceilings": ANYOBJ}, req=["enabled"]),
  "UsageReport": obj({"month": STR(7, pattern="^[0-9]{4}-[0-9]{2}$"), "systemsByGroup": CNT, "connectionsByType": CNT, "adaptersByProtocol": CNT,
      "calls": INT(), "errorRate": NUM, "unhealthyMinutesBySystem": CNT, "secretsOverdue": INT(), "writeAccountsActive": INT(), "kameletsByScope": CNT}, req=["month"]),
}

EXAMPLES = {
  "ConnectionCreate": {"connectionCode": "ndxp-ho-tich", "name": "NDXP tra cứu hộ tịch", "typeCode": "http-rest", "systemCode": "NDXP",
      "purpose": "READ", "description": "Kết nối tới Nền tảng chia sẻ, điều phối dữ liệu quốc gia cho nghiệp vụ hộ tịch.", "owner": "an.nv", "labels": ["ndxp", "ho-tich"]},
  "EnvironmentParams": {"params": {"baseUrl": "https://ndxp.example.gov.vn/api", "auth": "OAUTH2_CLIENT_CREDENTIALS",
      "tokenUrl": "https://sso.ndxp.example.gov.vn/token", "probe": "/health", "timeoutMs": 10000, "tlsMin": "TLSv1.2"}},
  "SecretPayload": {"secrets": {"clientId": "dh-t68", "clientSecret": "<giá trị bí mật, không bao giờ trả lại>"}},
  "Operation": {"operationCode": "tra-cuu-khai-sinh", "title": "Tra cứu khai sinh theo số định danh", "direction": "OUTBOUND",
      "protocolSpec": {"method": "GET", "pathTemplate": "/ho-tich/khai-sinh", "query": {"soDinhDanh": "${param.soDinhDanh}"}},
      "requestFormat": "JSON", "responseFormat": "JSON", "responseSchemaRef": "apicurio:t68/ho-tich-khai-sinh/1",
      "normalization": {"fields": [{"path": "$.ngaySinh", "type": "DATE", "sourceFormat": "dd/MM/yyyy", "required": True, "onMissing": "REJECT", "missingValues": ["01/01/1900"]},
                                   {"path": "$.noiSinh", "type": "STRING", "onMissing": "PASS_NULL"}]},
      "pagination": {"mode": "NONE"}, "timeoutMs": 8000, "idempotent": True, "sideEffect": "NONE"},
  "FlowAccountRequest": {"flowCode": "dkkd-dong-bo", "environments": ["TEST", "PROD"], "schemas": ["dkkd"], "tables": ["dkkd.doanh_nghiep", "dkkd.nganh_nghe"],
      "accessMode": "READ", "operations": ["SELECT"], "justification": "Đồng bộ danh sách doanh nghiệp mới đăng ký mỗi 15 phút sang trục dữ liệu tỉnh."},
  "VerifyRequest": {"workspaceCode": "DEFAULT", "flowCode": "ho-tich-tra-cuu", "flowVersion": 3, "stage": "PUBLISH", "targetEnv": "PROD",
      "references": [{"kind": "CONNECTION", "code": "ndxp-ho-tich", "keysUsed": ["baseUrl", "clientId", "clientSecret"]},
                     {"kind": "ADAPTER", "code": "ndxp-rest", "operationCode": "tra-cuu-khai-sinh"}]},
  "VerifyResult": {"allOk": False, "results": [{"index": 0, "status": "OK", "code": "ndxp-ho-tich"},
      {"index": 1, "status": "NOT_ENABLED", "code": "ndxp-rest", "message": "Bộ điều hợp ndxp-rest chưa có phiên bản được duyệt."}]},
  "CdcConfigUpdate": {"env": "PROD", "tables": ["QLDD.THUA_DAT", "QLDD.CHU_SU_DUNG"], "columnExcludes": ["QLDD.CHU_SU_DUNG.SO_CMND"],
      "columnHashes": ["QLDD.CHU_SU_DUNG.DIEN_THOAI"], "snapshotMode": "INITIAL"},
  "SchemaResolve": {"resolution": "MAP_COLUMN", "columnMap": {"DIEN_TICH_M2": "DIEN_TICH"}, "comment": "Cột đổi tên ở bản nâng cấp phần mềm đất đai 3.2; giữ tên cũ ở topic."},
  "KameletCreate": {"name": "qlvb-gui-van-ban-action", "version": "1.0.0", "title": "Gửi văn bản tới QLVB", "group": "soap",
      "yaml": "apiVersion: camel.apache.org/v1\nkind: Kamelet\nmetadata:\n  name: qlvb-gui-van-ban-action\n", "runtimeProfiles": ["soap-jvm"]},
  "FromSpecRequest": {"adapterCode": "dvc-rest", "name": "Cổng dịch vụ công tỉnh", "systemCode": "DVC", "systemGroup": 1, "connectionCode": "dvc-api",
      "specKind": "OPENAPI", "specUrl": "https://dvc.example.gov.vn/openapi.json", "includeOperations": ["traCuuHoSo", "capNhatTrangThai"]},
}
for _k, _v in EXAMPLES.items():
    SCHEMAS[_k]["examples"] = [_v]

PARAMS = {
  "ConnectionCodePath": {"name": "connectionCode", "in": "path", "required": True, "schema": R("ConnectionCode")},
  "EnvPath": {"name": "env", "in": "path", "required": True, "schema": R("Environment")},
  "TypeCodePath": {"name": "typeCode", "in": "path", "required": True, "schema": R("TypeCode")},
  "TestIdPath": {"name": "testId", "in": "path", "required": True, "schema": UUID},
  "GrantIdPath": {"name": "grantId", "in": "path", "required": True, "schema": UUID},
  "JobIdPath": {"name": "jobId", "in": "path", "required": True, "schema": UUID},
  "AccountIdPath": {"name": "accountId", "in": "path", "required": True, "schema": UUID},
  "AdapterCodePath": {"name": "adapterCode", "in": "path", "required": True, "schema": R("AdapterCode")},
  "VersionPath": {"name": "version", "in": "path", "required": True, "schema": STR(20, pattern="^[0-9]+\\.[0-9]+(\\.[0-9]+)?$"), "description": "`major.minor` (bộ điều hợp) hoặc SemVer (Kamelet)."},
  "OperationCodePath": {"name": "operationCode", "in": "path", "required": True, "schema": R("OperationCode")},
  "ComparisonIdPath": {"name": "comparisonId", "in": "path", "required": True, "schema": UUID},
  "ChangeIdPath": {"name": "changeId", "in": "path", "required": True, "schema": UUID},
  "KameletNamePath": {"name": "kameletName", "in": "path", "required": True, "schema": R("KameletName")},
  "Cursor": {"name": "cursor", "in": "query", "schema": STR(2048), "description": "Con trỏ mờ từ `page.next`."},
  "Limit": {"name": "limit", "in": "query", "schema": INT(minimum=1, maximum=100, default=25)},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại; lệch trả ERR-05-007 (412)."},
  "IfNoneMatch": {"name": "If-None-Match", "in": "header", "schema": STR(128)},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16), "description": "Lưu 24 giờ; cùng khóa khác thân trả ERR-05-039."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
}
PATH_PARAM = {"connectionCode": "ConnectionCodePath", "env": "EnvPath", "typeCode": "TypeCodePath", "testId": "TestIdPath",
    "grantId": "GrantIdPath", "jobId": "JobIdPath", "accountId": "AccountIdPath", "adapterCode": "AdapterCodePath",
    "version": "VersionPath", "operationCode": "OperationCodePath", "comparisonId": "ComparisonIdPath",
    "changeId": "ChangeIdPath", "kameletName": "KameletNamePath"}

ERR = {
  "BadRequest": (400, "ERR-05-003", "Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do)."),
  "Unauthorized": (401, "ERR-05-012", "Thiếu token hoặc token hết hạn."),
  "Forbidden": (403, "ERR-05-012", "Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON)."),
  "NotFound": (404, "ERR-05-001", "Không tìm thấy hoặc thuộc tenant khác (không phân biệt)."),
  "Conflict": (409, "ERR-05-008", "Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036)."),
  "PreconditionFailed": (412, "ERR-05-007", "ETag không khớp; kèm `currentEtag`."),
  "PayloadTooLarge": (413, "ERR-05-035", "Dữ liệu mẫu vượt 1 MiB hoặc tệp nhập quá lớn (ERR-05-024)."),
  "Unprocessable": (422, "ERR-05-032", "Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039)."),
  "Locked": (423, "ERR-05-031", "Đang đóng băng thay đổi PROD."),
  "TooManyRequests": (429, "ERR-05-019", "Vượt số lần kiểm tra cho phép; kèm `retryAfterSeconds`."),
  "ServiceUnavailable": (503, "ERR-05-029", "Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao)."),
}
RESPONSES = {k: {"description": d, "content": {"application/problem+json": {"schema": R("ProblemDetails"),
    "example": {"type": f"https://datahub.gov.vn/problems/adapter/{c.lower()}", "title": d.split(";")[0].split("(")[0].strip().rstrip("."), "status": st,
                "code": c, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}} for k, (st, c, d) in ERR.items()}
RESPONSES["NotModified"] = {"description": "Không đổi (If-None-Match khớp)."}

# code → (operationId, body, response, lỗi thêm, mô tả, tham số query thêm)
Q = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": schema, "description": desc}.items() if v is not None}
QA = lambda name, schema: {"name": name, "in": "query", "schema": arr(schema), "style": "form", "explode": False}
X = {
  "001": ("listConnectionTypes", None, "ConnectionTypeList", [], None, [Q("group", R("ProtocolGroup"))]),
  "002": ("getConnectionType", None, "ConnectionTypeDetail", [], "Trả `paramsSchema` (JSON Schema 2020-12) để giao diện dựng biểu mẫu; trần đã áp theo tenant.", []),
  "003": ("listConnections", None, "ConnectionPage", ["BadRequest"], "Kèm `facets`. Kết nối có môi trường UNHEALTHY xếp đầu khi không chỉ định `sort` (BR-05-014).",
          [Q("q", STR(100, minLength=2), "Tìm không dấu trên mã, tên, HTTT."), QA("status", R("ConnectionStatus")), QA("typeCode", R("TypeCode")),
           Q("systemCode", R("SystemCode")), QA("health", R("HealthLevel")), Q("env", R("Environment")), Q("label", STR(32)),
           Q("secretOverdue", BOOL), Q("sort", STR(pattern="^-?(code|name|updatedAt|health)$")), "Cursor", "Limit"]),
  "004": ("createConnection", "ConnectionCreate", "ConnectionDetail", ["Conflict", "Unprocessable"], "Mã trùng ERR-05-002; loại tắt ERR-05-004; HTTT không ACTIVE ERR-05-005. Trạng thái DRAFT.", []),
  "005": ("getConnection", None, "ConnectionDetail", [], None, []),
  "006": ("updateConnection", "ConnectionUpdate", "ConnectionDetail", ["Conflict"], "Đổi mục đích sang READ khi còn tài khoản ghi hiệu lực trả ERR-05-010.", []),
  "007": ("suspendConnection", "StateChangeRequest", "ConnectionDetail", ["Conflict"], "Phát EVT-05-04; runtime từ chối lượt gọi mới bằng ERR-05-118.", []),
  "008": ("resumeConnection", "StateChangeRequest", "ConnectionDetail", ["Conflict"], "Kết nối do SO tạm ngừng chỉ SO tiếp tục (ERR-05-011).", []),
  "009": ("retireConnection", "StateChangeRequest", "ConnectionDetail", ["Conflict"], "Còn nơi dùng trả ERR-05-010 kèm `usages`. Thu hồi cấp, tài khoản CSDL; hủy bí mật sau 30 ngày.", []),
  "010": ("listEnvironments", None, "EnvironmentList", [], None, []),
  "011": ("putEnvironmentParams", "EnvironmentParams", "Environment_", ["Unprocessable", "Locked"], "Sai lược đồ ERR-05-003; khóa bí mật ERR-05-006; vượt trần ERR-05-030; đích ngoài egress cho phép ERR-05-027. PROD đang ENABLED: lưu bản chờ (BR-05-010).", []),
  "012": ("putEnvironmentSecret", "SecretPayload", None, ["Unprocessable", "ServiceUnavailable", "Locked"], "Ghi một chiều vào OpenBao (cas theo phiên bản). Khóa ngoài `secretKeys` ERR-05-003. Trả 204, không trả giá trị; ghi giá trị trùng phiên bản hiện tại vẫn tạo phiên bản mới.", []),
  "013": ("enableEnvironment", "EnableRequest", "Environment_", ["Conflict", "Unprocessable"], "Không có kiểm tra đạt 24 giờ khớp tham số và bí mật ERR-05-009; thiếu bí mật ERR-05-014. PROD chuyển PENDING_APPROVAL và tạo việc cho IA.", []),
  "014": ("disableEnvironment", "StateChangeRequest", "Environment_", ["Conflict"], None, []),
  "015": ("approveEnvironment", "ApprovalDecision", "Environment_", ["Conflict"], "Bốn mắt: người duyệt khác người yêu cầu và người ghi bí mật (ERR-05-011, 403). Kiểm tra hết hạn trong lúc chờ trả ERR-05-009.", []),
  "016": ("rejectEnvironment", "RejectRequest", "Environment_", ["Conflict"], None, []),
  "017": ("startConnectionTest", "TestRequest", "ConnectionTest", ["Conflict", "TooManyRequests", "ServiceUnavailable"], "Chạy ở bộ chạy `probe-jvm` vùng Z4. Đang chạy cho cùng giá trị ERR-05-018; quá 10 lần/5 phút ERR-05-019. Theo dõi qua API-05-019 hoặc SSE (`Accept: text/event-stream`).", []),
  "018": ("listConnectionTests", None, "ConnectionTestPage", [], None, [Q("env", R("Environment")), "Cursor", "Limit"]),
  "019": ("getConnectionTest", None, "ConnectionTest", [], "Với `Accept: text/event-stream` trả sự kiện `step` và `completed`.", []),
  "020": ("rotateSecret", "RotateRequest", "Rotation", ["Conflict", "ServiceUnavailable"], "Đang có lần xoay mở ERR-05-036. Kiểm tra phiên bản mới thất bại thì hủy phiên bản mới, lần xoay FAILED.", []),
  "021": ("listRotations", None, "RotationList", [], None, [Q("env", R("Environment"))]),
  "022": ("listGrants", None, "GrantList", [], None, []),
  "023": ("createGrant", "GrantCreate", "Grant", ["Conflict", "Unprocessable"], "Không gian hoặc luồng không tồn tại ở PH-04 ERR-05-033. Phát EVT-05-05.", []),
  "024": ("revokeGrant", None, None, ["Conflict"], "Luồng đang chạy dùng cấp này được cảnh báo; thu hồi có hiệu lực ở lần phát hành kế tiếp của luồng.", []),
  "025": ("listConnectionUsages", None, "UsageList", [], None, []),
  "026": ("getConnectionHistory", None, "HistoryPage", ["ServiceUnavailable"], "Đọc từ PH-13; `before`, `after` không bao giờ chứa bí mật.", ["Cursor", "Limit"]),
  "027": ("exportConnections", None, None, [], "CSV UTF-8 có BOM, không có bí mật; cùng bộ lọc với API-05-003.", [Q("q", STR(100)), QA("status", R("ConnectionStatus"))]),
  "028": ("startLegacyImport", None, "LegacyImportJob", ["PayloadTooLarge", "Unprocessable"], "multipart/form-data `file` (XML Context, ZIP gói xuất Bus, .properties; ≤ 10 MiB). Sai định dạng ERR-05-024. Không thực thi, không lưu tệp; bí mật thay bằng vị trí (BR-05-025).", []),
  "029": ("getLegacyImport", None, "LegacyImportJob", [], None, []),
  "030": ("commitLegacyImport", "LegacyCommit", "LegacyImportJob", ["Conflict", "Unprocessable"], "Tạo kết nối DRAFT; người dùng khai lại bí mật.", []),
  "031": ("verifyReferences", "VerifyRequest", "VerifyResult", ["ServiceUnavailable"], "Gọi bởi PH-04 ở mức DESIGN, SUBMIT, PUBLISH (VR-07). Không ném lỗi nghiệp vụ theo từng tham chiếu; cập nhật chỉ mục nơi dùng.", []),
  "032": ("getRuntimeConnections", None, "RuntimeConfig", [], "Gọi bởi `dh-runtime` của tenant (scope `adapter:runtime-config`). Có `ETag`; `If-None-Match` khớp trả 304.", [Q("env", R("Environment")), "IfNoneMatch"]),
  "033": ("getHealthOverview", None, "HealthOverview", [], None, [Q("env", R("Environment"))]),
  "034": ("getConnectionHealth", None, "HealthDetail", [], None, [Q("env", R("Environment")), Q("window", enum("1h", "24h", "7d"))]),
  "035": ("listFlowAccounts", None, "FlowAccountList", [], None, [Q("flowCode", STR(63)), QA("status", R("AccountStatus"))]),
  "036": ("requestFlowAccount", "FlowAccountRequest", "FlowAccountList", ["Conflict", "Unprocessable", "ServiceUnavailable"],
          "Một dòng mỗi môi trường. READ: cấp ngay (ISSUED) với kết nối `db-flow` DYNAMIC. WRITE: REQUESTED, tạo việc cho SO. Kết nối READ mà xin WRITE ERR-05-017; phạm vi CSDL control plane ERR-05-016; ngoài `allowedSchemas` ERR-05-027; hạn > 90 ngày ERR-05-037.", []),
  "037": ("consentFlowAccount", "ConsentRequest", "FlowAccount", ["Conflict"], "Chỉ SO (`PERM-05-db-write-consent`).", []),
  "038": ("approveFlowAccount", "ApprovalDecision", "FlowAccount", ["Conflict", "ServiceUnavailable"], "IA khác người yêu cầu và SO (ERR-05-011). Ghi role OpenBao, ISSUED.", []),
  "039": ("revokeFlowAccount", "StateChangeRequest", "FlowAccount", ["Conflict"], "Xóa role, thu hồi lease; tài khoản động bị xóa ở CSDL nguồn ≤ 60 giây (NFR-05-007).", []),
  "040": ("inspectPrivileges", None, "PrivilegeReport", ["Unprocessable", "ServiceUnavailable"], "Tài khoản khai chỉ đọc mà có quyền ghi trả 200 với `verdict = EXCESSIVE` và chặn bật môi trường (ERR-05-015).", []),
  "041": ("listDbAccessLogs", None, "DbAccessPage", ["BadRequest"], "Khoảng thời gian tối đa 31 ngày mỗi truy vấn.",
          [Q("flowCode", STR(63)), Q("connectionCode", R("ConnectionCode")), Q("from", TS), Q("to", TS), QA("outcome", enum("OK", "DENIED", "ERROR")), "Cursor", "Limit"]),
  "043": ("listAdapters", None, "AdapterPage", ["BadRequest"], "Kèm `facets`, `cards`. UNHEALTHY xếp đầu khi không chỉ định `sort`.",
          [Q("q", STR(100, minLength=2)), Q("systemCode", R("SystemCode")), QA("systemGroup", INT(minimum=1, maximum=4)), QA("protocol", R("Protocol")),
           QA("status", R("AdapterStatus")), QA("versionStatus", R("VersionStatus")), QA("health", R("HealthLevel")), Q("hasPendingSchemaChange", BOOL),
           Q("sort", STR(pattern="^-?(code|name|updatedAt|health|calls24h)$")), "Cursor", "Limit"]),
  "044": ("createAdapter", "AdapterCreate", "AdapterDetail", ["Conflict", "Unprocessable"], "Tạo bộ điều hợp DRAFT và phiên bản 1.0 DRAFT. Kết nối khác HTTT ERR-05-013 (BR-05-015).", []),
  "045": ("getAdapter", None, "AdapterDetail", [], None, []),
  "046": ("updateAdapter", "AdapterUpdate", "AdapterDetail", [], None, []),
  "047": ("listAdapterVersions", None, "AdapterVersionList", [], None, []),
  "048": ("createAdapterVersion", "NewVersionRequest", "AdapterVersion", ["Conflict"], "Đã có bản nháp ERR-05-008 (BR-05-016). MAJOR khi đổi không tương thích; giao diện gợi ý theo khác biệt.", []),
  "049": ("getAdapterVersion", None, "AdapterVersion", [], None, []),
  "050": ("putOperation", "Operation", "AdapterVersion", ["Conflict", "Unprocessable", "PayloadTooLarge"], "Chỉ ở DRAFT. `sideEffect = WRITE` với kết nối READ ERR-05-017. Câu lệnh SQL ghép chuỗi, phương thức không hợp lệ, mã hóa VNI trả ERR-05-032; mẫu có mã độc ERR-05-034.", []),
  "051": ("deleteOperation", None, "AdapterVersion", ["Conflict"], None, []),
  "052": ("startAdapterTest", "AdapterTestRequest", "AdapterTest", ["Conflict", "ServiceUnavailable"], "Chạy ở TEST hoặc STAGING, không bao giờ PROD. Kết quả hiệu lực 24 giờ cho gửi duyệt.", []),
  "053": ("getAdapterTest", None, "AdapterTest", [], None, []),
  "054": ("previewTransform", "TransformPreviewRequest", "TransformPreview", ["Unprocessable", "PayloadTooLarge"], "Không gọi hệ đích; chạy chuyển đổi trên dữ liệu mẫu trong tiến trình cô lập, ≤ 2 giây.", []),
  "055": ("submitAdapterVersion", "SubmitRequest", "AdapterVersion", ["Conflict"], "Mọi thao tác có kiểm thử đạt 24 giờ trên đúng băm nội dung (ERR-05-009).", []),
  "056": ("approveAdapterVersion", "ApprovalDecision", "AdapterVersion", ["Conflict"], "Bốn mắt. Sinh Kamelet theo thao tác (FR-05-047), phát EVT-05-07, EVT-05-09; phiên bản trước SUPERSEDED.", []),
  "057": ("rejectAdapterVersion", "RejectRequest", "AdapterVersion", ["Conflict"], None, []),
  "058": ("suspendAdapter", "StateChangeRequest", "AdapterDetail", ["Conflict"], "Phát EVT-05-08.", []),
  "059": ("resumeAdapter", "StateChangeRequest", "AdapterDetail", ["Conflict"], None, []),
  "060": ("retireAdapter", "StateChangeRequest", "AdapterDetail", ["Conflict"], "Còn nơi dùng ERR-05-010. Kamelet sinh chuyển DEPRECATED.", []),
  "061": ("getAdapterHealth", None, "HealthDetail", [], None, [Q("env", R("Environment")), Q("window", enum("1h", "24h", "7d"))]),
  "062": ("listAdapterUsages", None, "UsageList", [], None, []),
  "063": ("startComparison", "CompareRequest", "Comparison", ["Conflict"], "Chế độ bóng: sao chép lượt gọi thật của phiên bản hiệu lực sang phiên bản ứng viên với thao tác `sideEffect = NONE`; thao tác ghi bị loại (cờ `adapter.compare.enabled`).", []),
  "064": ("getComparison", None, "Comparison", [], None, []),
  "065": ("createAdapterFromSpec", "FromSpecRequest", "AdapterDetail", ["Conflict", "Unprocessable", "PayloadTooLarge"], "Nhận `specUrl` (tải qua egress của tenant) hoặc multipart `file`. Không phân tích được ERR-05-023.", []),
  "066": ("getAdapterHistory", None, "HistoryPage", ["ServiceUnavailable"], None, ["Cursor", "Limit"]),
  "067": ("getCdc", None, "CdcConfig", [], None, [Q("env", R("Environment"))]),
  "068": ("putCdc", "CdcConfigUpdate", "CdcConfig", ["Conflict", "Unprocessable", "ServiceUnavailable"], "Bảng ngoài `allowedSchemas` ERR-05-027; vượt `05.cdc.max-tables` ERR-05-030; PH-10 không khả dụng ERR-05-029. Chỉ sửa khi STOPPED.", []),
  "069": ("checkCdcPrerequisites", None, "ConnectionTest", ["ServiceUnavailable"], "Kết quả kiểm từng mục theo engine (FR-05-049).", [Q("env", R("Environment"))]),
  "070": ("startCdc", "CdcAction", "CdcConfig", ["Conflict", "Unprocessable"], "Điều kiện chưa đạt 24 giờ ERR-05-025; chưa có phiên bản APPROVED ERR-05-008.", []),
  "071": ("pauseCdc", "CdcAction", "CdcConfig", ["Conflict"], None, []),
  "072": ("resumeCdc", "CdcAction", "CdcConfig", ["Conflict"], "Từ PAUSED_SCHEMA còn thay đổi chưa xử lý ERR-05-026.", []),
  "073": ("resnapshotCdc", "CdcAction", "CdcConfig", ["Conflict"], "Từ FAILED hoặc theo yêu cầu; bảng đích nhận lại toàn bộ dữ liệu (phía tiêu thụ phải lũy đẳng theo khóa).", []),
  "074": ("listSchemaChanges", None, "SchemaChangePage", [], None, [Q("adapterCode", R("AdapterCode")), QA("status", enum("PENDING", "RESOLVED", "AUTO")), QA("severity", enum("COMPATIBLE", "BREAKING")), "Cursor", "Limit"]),
  "075": ("resolveSchemaChange", "SchemaResolve", "SchemaChange", ["Conflict", "Unprocessable"], "MAP_COLUMN cần `columnMap`; RESNAPSHOT xếp lịch chụp ảnh lại.", []),
  "076": ("listKamelets", None, "KameletPage", [], None, [Q("q", STR(100)), QA("scope", R("KameletScope")), QA("type", R("KameletType")), QA("status", R("KameletStatus")), Q("group", STR(32)), Q("generated", BOOL), "Cursor", "Limit"]),
  "077": ("getKamelet", None, "KameletDetail", [], None, []),
  "078": ("getKameletVersion", None, "KameletVersion", [], "Với `Accept: application/yaml` trả YAML thô (runtime tải theo băm).", []),
  "079": ("createKamelet", "KameletCreate", "KameletVersion", ["Conflict", "Unprocessable"], "Tên trùng trên BASE ∪ COMMON ∪ TENANT ERR-05-002; tiền tố `dh-` dành riêng ERR-05-003; tỉnh tạo ở phạm vi COMMON ERR-05-040. Chạy kiểm tra tĩnh ngay, lưu kết quả.", []),
  "080": ("updateKameletDraft", "KameletDraftUpdate", "KameletVersion", ["Conflict", "Unprocessable"], "Chỉ ở DRAFT.", []),
  "081": ("validateKamelet", None, "StaticCheckResult", [], "Chạy KR-01…14 (SDD §4.9); không đổi trạng thái.", []),
  "082": ("submitKamelet", None, "KameletVersion", ["Conflict", "Unprocessable"], "Kiểm tra tĩnh còn lỗi ERR-05-020…022.", []),
  "083": ("approveKamelet", "KameletDecision", "KameletVersion", ["Conflict"], "TENANT: IA; COMMON: PA kèm ý kiến SO (`soOpinion` bắt buộc). Bốn mắt. Phát EVT-05-09.", []),
  "084": ("rejectKamelet", "RejectRequest", "KameletVersion", ["Conflict"], None, []),
  "085": ("deprecateKamelet", "StateChangeRequest", "KameletVersion", ["Conflict"], "Phát EVT-05-10.", []),
  "086": ("withdrawKamelet", "StateChangeRequest", "KameletVersion", ["Conflict"], "Chặn ở lần phát hành luồng kế tiếp; cảnh báo cao cho mọi luồng đang dùng (BR-05-027).", []),
  "087": ("listKameletUsages", None, "UsageList", [], None, []),
  "088": ("proposeCommonKamelet", "ProposeCommon", "KameletVersion", ["Conflict"], "Chỉ Kamelet TENANT đã APPROVED; tạo bản sao ở COMMON trạng thái SUBMITTED cho PA (cờ `adapter.kamelet.common-proposal`).", []),
  "089": ("getKameletCatalog", None, "KameletCatalog", [], "Gọi bởi PH-04 và runtime; có `ETag`.", [Q("runtimeProfile", STR(16)), "IfNoneMatch"]),
  "090": ("getSettings", None, "Settings", [], "Chỉ đọc; sửa tham số qua PH-18.", []),
  "091": ("putConnectionTypeSetting", "ConnectionTypeSetting", "ConnectionType", ["Conflict", "Unprocessable"], "Tắt loại còn kết nối ACTIVE ERR-05-010 trừ khi `blockNew`; trần chỉ thu hẹp (ERR-05-030).", []),
  "092": ("getUsageReport", None, "UsageReport", [], "`Accept: text/csv` hoặc XLSX để xuất.", [Q("month", STR(7, pattern="^[0-9]{4}-[0-9]{2}$"))]),
  "093": ("listHealthStates", None, "HealthStateList", [], "Gọi bởi PH-04, PH-13 (scope `adapter:health-read`).", [Q("env", R("Environment")), QA("level", R("HealthLevel")), Q("since", TS)]),
}
TAGS = {"type": "Loại kết nối", "conn": "Kết nối nguồn", "env": "Giá trị môi trường và bí mật", "test": "Kiểm tra kết nối",
        "grant": "Cấp kết nối", "legacy": "Nhập hệ cũ", "internal": "Nội bộ (PH-04, runtime)", "health": "Sức khỏe",
        "dbacc": "Tài khoản CSDL cho luồng", "adapter": "Bộ điều hợp", "cdc": "CDC", "kamelet": "Kamelet", "admin": "Tham số và báo cáo"}
SERVICE_SCOPE = {"031": "adapter:verify", "032": "adapter:runtime-config", "089": "adapter:runtime-config", "093": "adapter:health-read"}

def build():
    assert set(X) == {o[0] for o in spec.OPS}, set(X) ^ {o[0] for o in spec.OPS}
    paths = {}
    for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
        opid, body, resp, errs, desc, extra = X[code]
        m = method.lower()
        frs = []
        for part in fr.split(","):
            part = part.strip()
            if "-" in part:
                a, b = part.split("-"); frs += [f"FR-05-{i:03d}" for i in range(int(a), int(b) + 1)]
            else:
                frs.append(f"FR-05-{part}")
        op = {"tags": [TAGS[group]], "operationId": opid, "summary": summary, "x-datahub-id": f"API-05-{code}", "x-datahub-fr": frs}
        if perm == "service":
            op["x-datahub-permission"] = {"serviceScope": SERVICE_SCOPE[code]}
            op["security"] = [{"oauth2Service": [SERVICE_SCOPE[code]]}]
        else:
            op["x-datahub-permission"] = {"permission": f"PERM-05-{perm}"}
        if desc: op["description"] = desc
        if idem: op["x-datahub-idempotent"] = True
        params = [P(PATH_PARAM[n]) for n in re.findall(r"\{(\w+)\}", path)]
        mutating = m in ("put", "patch", "delete") or (m == "post" and ":" in path.split("/")[-1])
        if mutating and code not in ("031", "040", "054", "069", "081"): params.append(P("IfMatch"))
        for e in extra: params.append(P(e) if isinstance(e, str) else e)
        if idem: params.append(P("IdempotencyKey"))
        params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = params
        if body:
            op["requestBody"] = {"required": True, "content": {"application/json": {"schema": R(body)}}}
        elif code in ("028", "065"):
            props = {"file": {"type": "string", "contentEncoding": "binary"}}
            if code == "065": props["meta"] = R("FromSpecRequest")
            op["requestBody"] = {"required": code == "028", "content": {"multipart/form-data": {"schema": {"type": "object", "properties": props, **({"required": ["file"]} if code == "028" else {})}}}}
            if code == "065": op["requestBody"]["content"]["application/json"] = {"schema": R("FromSpecRequest")}
        okr = {"description": "Thành công."}
        if code == "027":
            okr["content"] = {"text/csv": {"schema": STR()}}
        elif code == "092":
            okr["content"] = {"application/json": {"schema": R(resp)}, "text/csv": {"schema": STR()},
                              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": {"schema": {"type": "string", "contentEncoding": "binary"}}}
        elif code == "078":
            okr["content"] = {"application/json": {"schema": R(resp)}, "application/yaml": {"schema": STR()}}
        elif code in ("017", "019"):
            okr["content"] = {"application/json": {"schema": R(resp)}, "text/event-stream": {"schema": STR(description="Sự kiện `step` (TestStep), `completed` (ConnectionTest).")}}
        elif resp and success != "204":
            okr["content"] = {"application/json": {"schema": R(resp)}}
        hdr = {}
        if m == "get" and resp and code not in ("027",): hdr["ETag"] = {"schema": STR()}
        if success == "202": hdr["Location"] = {"schema": STR(), "description": "Tài nguyên theo dõi tiến trình."}
        if hdr: okr["headers"] = hdr
        resps = {success: okr}
        if code in ("032", "089"): resps["304"] = RESP("NotModified")
        for r in ["Unauthorized"] + errs:
            resps[str(ERR[r][0])] = RESP(r)
        if path.count("{") and "404" not in resps: resps["404"] = RESP("NotFound")
        if m != "get" and "403" not in resps: resps["403"] = RESP("Forbidden")
        if body and "400" not in resps: resps["400"] = RESP("BadRequest")
        if "IfMatch" in str(params) and "412" not in resps: resps["412"] = RESP("PreconditionFailed")
        op["responses"] = dict(sorted(resps.items()))
        paths.setdefault(path, {})[m] = op
    return {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-05 Bộ điều hợp và kết nối API", "version": "1.0.0-draft",
               "summary": "Kết nối nguồn, bí mật một chiều, kiểm tra, sức khỏe, tài khoản CSDL cho luồng, bộ điều hợp, CDC, Kamelet.",
               "description": ("API của module `adapter` trong `dh-integration` (control plane PH-05). Người dùng gọi qua BFF console "
                   "(Authorization Code + PKCE); `/internal/*` do PH-04 và `dh-runtime` gọi bằng token dịch vụ (client credentials). "
                   "HTTT thành viên không gọi API này.\n\nQuy ước (D03-04-PH05 §1): tenant lấy từ token; tạo nhận `Idempotency-Key`; "
                   "sửa và đổi trạng thái bắt buộc `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-05-nnn`; phân trang con trỏ. "
                   "Không API nào trả giá trị bí mật. Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-05"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH05", "x-datahub-phase": "PH-05"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn" + spec.BASE, "description": "Qua BFF console của tenant — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
                  {"url": "http://dh-integration.dh-control.svc:8080" + spec.BASE, "description": "Trong cụm, cho PH-04 và runtime"},
                  {"url": "http://localhost:8081" + spec.BASE, "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": v} for v in TAGS.values()],
      "paths": paths,
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-05-* (D02-08).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Token dịch vụ của PH-04 (`dh-integration` khi tách DU), `dh-runtime` của tenant.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"adapter:verify": "Xác minh tham chiếu", "adapter:runtime-config": "Đọc cấu hình kết nối không bí mật và catalog Kamelet",
                           "adapter:health-read": "Đọc trạng thái sức khỏe"}}}}},
        "parameters": PARAMS, "responses": RESPONSES, "schemas": SCHEMAS}}

if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-adapter.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH05 · OpenAPI PH-05 (dh-integration, module adapter). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(len(v) for v in doc["paths"].values())
    print(f"{n} operation, {len(SCHEMAS)} lược đồ → {out}")
