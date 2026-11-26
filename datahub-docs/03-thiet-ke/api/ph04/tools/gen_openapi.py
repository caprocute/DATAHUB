#!/usr/bin/env python3
"""Sinh ph04/openapi-integration.yaml từ bảng endpoint và lược đồ trong tệp này.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph04)
Sau khi sinh, kiểm tra bằng openapi-spec-validator (CI-5 dùng Spectral).
Tệp YAML sinh ra là hợp đồng; sửa tệp này rồi sinh lại, không sửa tay YAML.
"""
import copy, os, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bo_sung as BS

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
P = lambda n: {"$ref": f"#/components/parameters/{n}"}
RESP = lambda n: {"$ref": f"#/components/responses/{n}"}

def s(type_, **kw):
    d = {"type": type_}; d.update(kw); return d
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

STR = lambda mx=None, **kw: s("string", **({"maxLength": mx} if mx else {}), **kw)
INT = lambda **kw: s("integer", **kw)
BOOL = s("boolean")
TS = s("string", format="date-time")
UUID = s("string", format="uuid")
ANYOBJ = {"type": "object", "additionalProperties": True}

SCHEMAS = {
  # ---- chung
  "TenantId": STR(16, pattern="^T[0-9]{2}$", description="Mã tenant T-TENANT (D00-01)."),
  "FlowCode": STR(63, pattern="^[a-z][a-z0-9-]{2,62}$", description="Mã luồng, duy nhất trong tenant, không đổi (BR-04-001)."),
  "WorkspaceCode": STR(63, pattern="^([a-z][a-z0-9-]{1,62}|DEFAULT)$"),
  "Environment": enum("TEST", "STAGING", "PROD"),
  "ResourceKind": enum("ROUTE", "KAMELET", "PIPE", "TEST"),
  "Transport": enum("SYNC", "ASYNC", "SCHEDULED", "MIXED"),
  "Exposure": enum("EXTERNAL", "INTERNAL"),
  "FlowStatus": enum("DRAFT", "IN_REVIEW", "APPROVED", "ACTIVE", "PAUSED", "DEGRADED", "RETIRED"),
  "VersionStatus": enum("DRAFT", "CHANGES_REQUESTED", "PENDING_REVIEW", "APPROVED", "SUPERSEDED", "ROLLED_BACK", "DISCARDED"),
  "SyncStatus": enum("PENDING", "SYNCING", "SYNCED", "OUT_OF_SYNC", "FAILED"),
  "HealthStatus": enum("HEALTHY", "DEGRADED", "DOWN", "UNKNOWN"),
  "TestMode": enum("MOCK", "SANDBOX_LIVE"),
  "TestRunStatus": enum("QUEUED", "RUNNING", "PASSED", "FAILED", "TIMED_OUT", "CANCELLED", "SIMULATED"),
  "CommandAction": enum("PAUSE", "RESUME", "EMERGENCY_STOP"),
  "CommandStatus": enum("ISSUED", "DELIVERED", "ACKNOWLEDGED", "PARTIAL", "REJECTED", "RECONCILED"),
  "ValidationLevel": enum("DESIGN", "SUBMIT", "PUBLISH"),
  "Severity": enum("ERROR", "WARN", "INFO"),
  "AccessLevel": enum("VIEW", "EDIT", "MAINTAIN"),
  "FlowOrigin": enum("BLANK", "TEMPLATE", "OPENAPI", "YAML_FILE", "CLONE", "LEGACY_XML"),
  "Labels": {"type": "object", "maxProperties": 20, "propertyNames": {"maxLength": 63}, "additionalProperties": STR(63)},
  "ContentHash": STR(71, pattern="^sha256:[0-9a-f]{64}$"),
  "Reason": STR(1000, minLength=10, description="Lý do 10…1.000 ký tự (BR-04-017)."),
  "AllowedActions": obj({
      "allowedActions": arr(STR(), description="Hành động người gọi được làm ngay bây giờ."),
      "disabledReasons": {"type": "object", "additionalProperties": STR(), "description": "Hành động có quyền nhưng trạng thái chưa cho phép → lý do tiếng Việt (D03-06-PH04 §2.4)."}}),
  "CursorMeta": obj({"next": STR(2048, nullable=None) if False else {"type": ["string", "null"], "maxLength": 2048}, "hasMore": BOOL}, req=["hasMore"]),
  "ProblemDetails": {
      "type": "object", "description": "RFC 9457, mở rộng theo D03-04-PH04 §1.",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {
          "type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(),
          "instance": STR(), "code": STR(pattern="^ERR-04-[0-9]{3}$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(obj({"path": STR(), "nodeId": STR(), "rule": STR(), "message": STR()})),
          "findings": arr(R("Finding")),
          "currentEtag": STR(), "savedBy": STR(), "savedAt": TS,
          "retryAfterSeconds": INT(), "dependencies": arr(R("DependencyItem"))},
      "additionalProperties": True},
  "Finding": obj({
      "rule": STR(pattern="^(VR-[0-9]{2}|LINT-04-[0-9]{2})$"), "severity": R("Severity"),
      "path": STR(description="Đường dẫn JSON Pointer trong cây tài nguyên."), "nodeId": STR(),
      "messageKey": STR(), "message": STR(description="Câu tiếng Việt đã điền tham số; không lặp giá trị bí mật."),
      "args": ANYOBJ}, req=["rule", "severity", "message"]),
  "ValidationResult": obj({
      "level": R("ValidationLevel"), "validatedAt": TS, "catalogVersion": STR(64),
      "contentHash": R("ContentHash"), "errorCount": INT(), "warnCount": INT(), "infoCount": INT(),
      "findings": arr(R("Finding"))}, req=["level", "findings", "errorCount"]),
  # ---- workspace
  "Workspace": {"allOf": [obj({
      "id": UUID, "code": R("WorkspaceCode"), "name": STR(255), "description": STR(4000),
      "ownerOrgCode": STR(64), "status": enum("ACTIVE", "ARCHIVED"), "flowCount": INT(),
      "myAccess": R("AccessLevel"), "updatedAt": TS}, req=["id", "code", "name", "status"]), R("AllowedActions")]},
  "WorkspaceCreate": obj({"code": R("WorkspaceCode"), "name": STR(255, minLength=1), "description": STR(4000), "ownerOrgCode": STR(64)}, req=["code", "name"]),
  "WorkspaceUpdate": obj({"name": STR(255, minLength=1), "description": STR(4000), "ownerOrgCode": STR(64)}),
  "WorkspaceList": obj({"items": arr(R("Workspace"))}, req=["items"]),
  "WorkspaceMember": obj({"principalType": enum("USER", "GROUP"), "principalId": STR(128), "displayName": STR(255), "accessLevel": R("AccessLevel")}, req=["principalType", "principalId", "accessLevel"]),
  "WorkspaceMembers": obj({"members": arr(R("WorkspaceMember"), maxItems=500)}, req=["members"]),
  # ---- flow
  "EnvState": obj({"environment": R("Environment"), "versionNo": INT(), "syncStatus": R("SyncStatus"), "healthStatus": R("HealthStatus"),
      "desiredState": enum("RUNNING", "PAUSED", "REMOVED"), "readyReplicas": INT(), "replicas": INT(), "lastHeartbeatAt": TS, "emergency": BOOL}, req=["environment"]),
  "FlowSummary": {"allOf": [obj({
      "id": UUID, "code": R("FlowCode"), "name": STR(255), "workspaceCode": R("WorkspaceCode"), "resourceKind": R("ResourceKind"),
      "transport": R("Transport"), "exposure": R("Exposure"), "status": R("FlowStatus"), "sourceSystem": STR(64),
      "targetSystems": arr(STR(64)), "labels": R("Labels"), "openVersionNo": {"type": ["integer", "null"]},
      "environments": arr(R("EnvState")), "updatedAt": TS, "updatedBy": STR(64)},
      req=["id", "code", "name", "status", "resourceKind"]), R("AllowedActions")]},
  "FlowPage": obj({"items": arr(R("FlowSummary")), "page": R("CursorMeta"),
      "facets": obj({"status": {"type": "object", "additionalProperties": INT()}, "environment": {"type": "object", "additionalProperties": INT()}})}, req=["items", "page"]),
  "FlowDetail": {"allOf": [R("FlowSummary"), obj({
      "description": STR(4000), "legalBasisRef": STR(128), "origin": R("FlowOrigin"), "templateCode": STR(64),
      "clonedFrom": STR(), "routes": arr(obj({"routeId": STR(128), "fromUri": STR(2048), "description": STR(1000), "stepCount": INT()})),
      "createdAt": TS, "createdBy": STR(64), "retiredAt": TS, "retireReason": STR(1000)})]},
  "FlowCreate": obj({
      "code": R("FlowCode"), "name": STR(255, minLength=1), "description": STR(4000), "workspaceCode": R("WorkspaceCode"),
      "resourceKind": R("ResourceKind"), "origin": R("FlowOrigin"),
      "templateCode": STR(64, pattern="^tpl-[a-z0-9-]{2,60}$"), "templateParams": ANYOBJ,
      "apiRef": STR(255, description="Mã API PH-02 khi origin = OPENAPI."),
      "yaml": STR(524288, description="Nội dung khi origin = YAML_FILE (≤ 512 KiB)."),
      "sourceSystem": STR(64), "targetSystems": arr(STR(64), maxItems=20), "labels": R("Labels"), "legalBasisRef": STR(128)},
      req=["code", "name", "workspaceCode", "resourceKind", "origin"]),
  "FlowUpdate": obj({"name": STR(255, minLength=1), "description": STR(4000), "workspaceCode": R("WorkspaceCode"),
      "sourceSystem": STR(64), "targetSystems": arr(STR(64), maxItems=20), "labels": R("Labels"), "legalBasisRef": STR(128)}),
  "CloneRequest": obj({"code": R("FlowCode"), "name": STR(255, minLength=1), "workspaceCode": R("WorkspaceCode"),
      "sourceVersionNo": INT(minimum=1), "includeTestCases": {"type": "boolean", "default": True}}, req=["code", "name"]),
  "RetireRequest": obj({"reason": R("Reason"), "force": {"type": "boolean", "default": False, "description": "Bỏ qua phụ thuộc mềm (chỉ TA)."}}, req=["reason"]),
  "DependencyItem": obj({"type": enum("API", "FLOW", "TEST_CASE", "DRAFT_FLOW", "TOPIC", "CONNECTION"), "hard": BOOL, "ref": STR(255), "label": STR(255), "environment": R("Environment")}, req=["type", "hard", "ref"]),
  "Dependencies": obj({"hard": arr(R("DependencyItem")), "soft": arr(R("DependencyItem"))}, req=["hard", "soft"]),
  # ---- version
  "Contributor": obj({"userId": STR(64), "displayName": STR(255), "firstAt": TS, "lastAt": TS}),
  "VersionSummary": obj({"versionNo": INT(minimum=1), "status": R("VersionStatus"), "contentHash": R("ContentHash"), "catalogVersion": STR(64),
      "changeNote": STR(2000), "createdBy": STR(64), "createdAt": TS, "submittedBy": STR(64), "submittedAt": TS,
      "approvedBy": STR(64), "approvedAt": TS, "environments": arr(R("Environment"))}, req=["versionNo", "status"]),
  "VersionList": obj({"items": arr(R("VersionSummary"))}, req=["items"]),
  "VersionDetail": {"allOf": [R("VersionSummary"), obj({
      "definitionYaml": STR(524288), "canvasLayout": ANYOBJ, "samples": ANYOBJ,
      "mappings": arr(R("MappingDoc")), "contributors": arr(R("Contributor")),
      "lastValidation": R("ValidationResult"), "needsRevalidation": BOOL,
      "lastPassedTestRunId": {"type": ["string", "null"], "format": "uuid"},
      "runtimeProfile": STR(32)}, req=["definitionYaml", "canvasLayout", "samples"]), R("AllowedActions")]},
  "MappingDoc": obj({"name": STR(128, pattern="^[a-z0-9][a-z0-9-]{0,127}$"), "nodeId": STR(128),
      "dhmap": {"type": "object", "required": ["format"], "properties": {"format": {"const": "dhmap/1"}}, "additionalProperties": True},
      "jq": STR(200000)}, req=["name", "dhmap"]),
  "NewVersionRequest": obj({"baseVersionNo": INT(minimum=1, description="Mặc định: phiên bản đang chạy ở PROD, nếu không có thì mới nhất.")}),
  "DraftUpdate": obj({"definitionYaml": STR(524288), "canvasLayout": ANYOBJ, "samples": ANYOBJ,
      "catalogVersion": STR(64), "mappings": arr(R("MappingDoc"), maxItems=50)},
      req=["definitionYaml", "canvasLayout", "samples", "catalogVersion"]),
  "DraftSaved": obj({"versionNo": INT(), "contentHash": R("ContentHash"), "savedAt": TS, "validation": R("ValidationResult")}, req=["versionNo", "contentHash", "validation"]),
  "ImportYamlRequest": obj({"yaml": STR(524288), "keepLayout": {"type": "boolean", "default": True}}, req=["yaml"]),
  "DiffResult": obj({"baseVersionNo": INT(), "versionNo": INT(),
      "nodes": arr(obj({"nodeId": STR(), "change": enum("ADDED", "REMOVED", "MODIFIED", "MOVED"), "fields": arr(STR())})),
      "yamlUnifiedDiff": STR(), "summary": obj({"added": INT(), "removed": INT(), "modified": INT()})}, req=["nodes", "summary"]),
  "LegacyImportJob": obj({"id": UUID, "status": enum("RUNNING", "COMPLETED", "FAILED"), "fileName": STR(255),
      "report": obj({"routes": INT(), "stepsConverted": INT(), "stepsManual": INT(), "forbiddenComponents": arr(STR()),
          "connectionsToDeclare": arr(STR()), "recommendations": arr(STR())}),
      "createdFlows": arr(R("FlowCode")), "errorCode": STR()}, req=["id", "status"]),
  # ---- validation, expression, mapping, session
  "ValidateRequest": obj({"level": R("ValidationLevel"), "targetEnvironment": R("Environment")}, req=["level"]),
  "StatelessValidateRequest": obj({"yaml": STR(524288), "resourceKind": R("ResourceKind"), "exposure": R("Exposure"), "workspaceCode": R("WorkspaceCode")}, req=["yaml", "resourceKind"]),
  "ExpressionCheckRequest": obj({"language": enum("simple", "jsonpath", "jq", "xpath", "header", "constant", "exchangeProperty"),
      "expression": STR(20000), "predicate": BOOL, "evaluate": BOOL, "sample": R("SampleMessage")}, req=["language", "expression"]),
  "ExpressionCheckResult": obj({"valid": BOOL, "error": obj({"line": INT(), "column": INT(), "message": STR()}),
      "result": {}, "resultType": STR(), "simulated": BOOL}, req=["valid"]),
  "SampleMessage": obj({"body": STR(262144), "headers": {"type": "object", "maxProperties": 50, "additionalProperties": STR(8192)}, "properties": ANYOBJ}),
  "MappingPreviewRequest": obj({"mapping": R("MappingDoc"), "sample": R("SampleMessage")}, req=["mapping", "sample"]),
  "MappingPreviewResult": obj({"jq": STR(), "output": {}, "targetValid": BOOL, "findings": arr(R("Finding")), "simulated": BOOL}, req=["jq"]),
  "SessionState": obj({"others": arr(obj({"userId": STR(64), "displayName": STR(255), "since": TS})), "catalogVersion": STR(64),
      "expiresInSeconds": INT(), "freeze": obj({"active": BOOL, "until": TS})}, req=["others", "catalogVersion"]),
  # ---- test
  "Assertion": obj({"kind": enum("STATUS", "BODY_JQ", "HEADER", "STEP_VISITED", "STEP_NOT_VISITED", "ENDPOINT_CALLED", "DURATION_LT", "ERROR_CODE", "DLQ_SENT"),
      "expected": {"description": "Giá trị mong đợi theo kiểu khẳng định."}, "expression": STR(4000), "nodeId": STR(128), "header": STR(255),
      "times": INT(minimum=0), "description": STR(500)}, req=["kind"]),
  "TestRunRequest": obj({"mode": R("TestMode"), "testCaseId": UUID, "body": STR(262144),
      "headers": {"type": "object", "maxProperties": 50, "additionalProperties": STR(8192)}, "fromNodeId": STR(128),
      "timeoutSeconds": INT(minimum=1, maximum=120, default=30), "captureBodies": {"type": "boolean", "default": False},
      "assertions": arr(R("Assertion"), maxItems=20)}, req=["mode"]),
  "TestRunStep": obj({"seqNo": INT(), "nodeId": STR(128), "routeId": STR(128), "stage": STR(16), "status": enum("OK", "FAILED", "SKIPPED", "HUNG"),
      "offsetMs": INT(), "durationMs": INT(), "headers": ANYOBJ, "bodyInPreview": STR(65536), "bodyOutPreview": STR(65536),
      "bodyAvailable": BOOL, "errorClass": STR(16), "errorText": STR(1000)}, req=["seqNo", "nodeId", "status"]),
  "TestRun": {"allOf": [obj({"id": UUID, "versionNo": INT(), "testCaseId": {"type": ["string", "null"], "format": "uuid"},
      "definitionHash": R("ContentHash"), "mode": enum("MOCK", "SANDBOX_LIVE", "SIMULATED"), "status": R("TestRunStatus"),
      "durationMs": INT(), "traceId": STR(), "errorCode": STR(), "errorSummary": STR(1000), "hungNodeId": STR(128),
      "assertionResults": arr(obj({"index": INT(), "kind": STR(), "passed": BOOL, "actual": {}, "message": STR()})),
      "steps": arr(R("TestRunStep")), "runBy": STR(64), "queuedAt": TS, "startedAt": TS, "finishedAt": TS,
      "matchesCurrentHash": BOOL}, req=["id", "status", "mode", "definitionHash"]), R("AllowedActions")]},
  "TestRunPage": obj({"items": arr(R("TestRun")), "page": R("CursorMeta")}, req=["items", "page"]),
  "TestCase": obj({"id": UUID, "name": STR(255), "description": STR(2000), "mode": R("TestMode"), "body": STR(262144),
      "headers": ANYOBJ, "fromNodeId": STR(128), "mocks": ANYOBJ, "assertions": arr(R("Assertion"), minItems=1, maxItems=20),
      "timeoutSeconds": INT(minimum=1, maximum=120), "active": BOOL,
      "lastResult": obj({"status": R("TestRunStatus"), "runId": UUID, "onCurrentHash": BOOL})}, req=["name", "mode", "assertions"]),
  "TestCaseList": obj({"items": arr(R("TestCase"))}, req=["items"]),
  # ---- review, release
  "SubmitRequest": obj({"changeNote": STR(2000, minLength=10), "suggestedReviewers": arr(STR(64), maxItems=5)}, req=["changeNote"]),
  "WithdrawRequest": obj({"reason": R("Reason")}, req=["reason"]),
  "ReviewDecision": obj({"decision": enum("APPROVE", "REQUEST_CHANGES"), "comment": STR(4000),
      "checklist": {"type": "object", "additionalProperties": BOOL, "description": "Khóa theo 04.review.checklist."},
      "nodeComments": arr(obj({"nodeId": STR(128), "text": STR(2000)}, req=["nodeId", "text"]), maxItems=100),
      "publishTo": {"allOf": [R("Environment")], "description": "Phát hành ngay sau khi duyệt (tùy chọn)."}}, req=["decision"]),
  "ReviewQueueItem": obj({"flowCode": R("FlowCode"), "flowName": STR(255), "workspaceCode": R("WorkspaceCode"), "versionNo": INT(),
      "submittedBy": STR(64), "submittedAt": TS, "waitingHours": s("number"), "overdue": BOOL, "exposure": R("Exposure"),
      "changeSummary": obj({"added": INT(), "removed": INT(), "modified": INT()}), "canDecide": BOOL}, req=["flowCode", "versionNo", "submittedAt"]),
  "ReviewQueue": obj({"items": arr(R("ReviewQueueItem")), "page": R("CursorMeta")}, req=["items", "page"]),
  "ReleaseRequest": obj({"versionNo": INT(minimum=1), "environment": R("Environment"), "note": STR(1000), "replicas": INT(minimum=1, maximum=20)}, req=["versionNo", "environment"]),
  "PromoteRequest": obj({"versionNo": INT(minimum=1), "fromEnvironment": R("Environment"), "toEnvironment": R("Environment"), "note": STR(1000)}, req=["versionNo", "toEnvironment"]),
  "RollbackRequest": obj({"environment": R("Environment"), "targetVersionNo": INT(minimum=1), "reason": R("Reason")}, req=["environment", "targetVersionNo", "reason"]),
  "Deployment": {"allOf": [obj({"id": UUID, "versionNo": INT(), "environment": R("Environment"), "kind": enum("RELEASE", "PROMOTE", "ROLLBACK", "RETIRE"),
      "desiredState": enum("RUNNING", "PAUSED", "REMOVED"), "syncStatus": R("SyncStatus"), "healthStatus": R("HealthStatus"),
      "runtimeProfile": STR(32), "replicas": INT(), "gitCommit": STR(40), "requestedBy": STR(64), "requestedAt": TS,
      "syncedAt": TS, "current": BOOL, "errorCode": STR(), "note": STR(1000)}, req=["id", "versionNo", "environment", "syncStatus"]), R("AllowedActions")]},
  "DeploymentList": obj({"items": arr(R("Deployment"))}, req=["items"]),
  # ---- runtime
  "RouteState": obj({"routeId": STR(128), "state": enum("Started", "Suspended", "Stopped", "Mixed"), "replicas": arr(obj({"replica": STR(128), "state": STR(), "inflight": INT()})),
      "exchanges1m": INT(), "failures1m": INT(), "p95ms": INT(), "pausedBy": STR(64), "pausedAt": TS, "pauseReason": STR(1000)}),
  "RuntimeStatus": obj({"environments": arr({"allOf": [R("EnvState"), obj({"routes": arr(R("RouteState")), "loadError": STR(1000), "runtimeProfile": STR(32), "namespace": STR(63)})]})}, req=["environments"]),
  "CommandRequest": obj({"environment": R("Environment"), "action": R("CommandAction"), "scope": enum("FLOW", "ROUTES"),
      "routeIds": arr(STR(128), maxItems=100), "reason": R("Reason"), "drain": {"type": "boolean", "default": True}, "incidentRef": STR(128)},
      req=["environment", "action", "scope", "reason"]),
  "Command": obj({"id": UUID, "environment": R("Environment"), "action": R("CommandAction"), "scope": STR(), "routeIds": arr(STR()),
      "status": R("CommandStatus"), "expectedReplicas": INT(), "ackedReplicas": INT(),
      "acks": arr(obj({"replica": STR(128), "result": enum("APPLIED", "REJECTED"), "reason": STR(32), "ackedAt": TS})),
      "issuedBy": STR(64), "issuedAt": TS, "expiresAt": TS, "reconciledAt": TS}, req=["id", "status", "action"]),
  "EndpointList": obj({"items": arr(obj({"nodeId": STR(128), "direction": enum("IN", "OUT"), "scheme": STR(64), "uri": STR(2048, description="Đã che tham số nhạy cảm."),
      "httpMethod": STR(8), "httpPath": STR(1024), "connectionCode": STR(64), "topic": STR(249),
      "metrics": obj({"exchanges1h": INT(), "failures1h": INT(), "p95ms": INT()})}))}, req=["items"]),
  "FlowMetrics": obj({"environment": R("Environment"), "from": TS, "to": TS, "step": STR(),
      "series": arr(obj({"name": enum("exchanges", "failures", "p95ms", "dlq"), "points": arr(arr(s("number"), minItems=2, maxItems=2))})),
      "dashboardUrl": STR(format="uri")}, req=["series"]),
  # ---- catalog
  "CatalogIndex": obj({"catalogVersion": STR(64), "runtime": STR(), "runtimeVersion": STR(), "camelVersion": STR(), "generatedAt": TS, "sha256": STR(64),
      "paletteRulesVersion": INT(), "entries": arr(R("CatalogEntry")), "frequentlyUsed": arr(STR())}, req=["catalogVersion", "entries"]),
  "CatalogEntry": obj({"kind": enum("COMPONENT", "EIP", "KAMELET", "DATAFORMAT", "LANGUAGE", "BEAN_CLASS"), "name": STR(128), "title": STR(255),
      "titleVi": STR(255), "description": STR(), "groups": arr(STR(32)), "supportLevel": enum("stable", "preview", "deprecated"),
      "native": enum("SUPPORTED", "JVM_ONLY", "NOT_APPLICABLE"), "policy": enum("ALLOWED", "PER_FLOW", "DENIED"),
      "needsConnection": BOOL, "consumerOnly": BOOL, "producerOnly": BOOL, "source": enum("CAMEL", "DATAHUB_BASE", "TENANT")}, req=["kind", "name", "policy"]),
  "ComponentSchema": obj({"entry": R("CatalogEntry"), "syntax": STR(), "license": STR(), "maven": STR(),
      "properties": arr(obj({"name": STR(), "kind": enum("path", "parameter", "property", "header"), "group": STR(), "type": STR(),
          "required": BOOL, "default": {}, "enum": arr({}), "secret": BOOL, "description": STR(), "descriptionVi": STR(), "deprecated": BOOL})),
      "flowsUsing": INT()}, req=["entry", "properties"]),
  "PolicyEntry": obj({"kind": STR(12), "name": STR(128), "decision": enum("ALLOWED", "PER_FLOW", "DENIED"), "reason": STR(1000),
      "scope": enum("PLATFORM", "TENANT"), "approvedBySo": STR(64), "policyVersion": INT(), "updatedAt": TS}, req=["kind", "name", "decision", "scope"]),
  "PolicyList": obj({"items": arr(R("PolicyEntry")), "policyVersion": INT()}, req=["items"]),
  "PolicyUpdate": obj({"changes": arr(obj({"kind": STR(12), "name": STR(128), "decision": enum("ALLOWED", "PER_FLOW", "DENIED", "INHERIT"), "reason": R("Reason")}, req=["kind", "name", "decision", "reason"]), minItems=1, maxItems=200),
      "soApprovalRef": STR(128)}, req=["changes"]),
  "CatalogVersions": obj({"tenantCatalogVersion": STR(64), "profiles": arr(obj({"profile": STR(32), "quarkusVersion": STR(), "camelQuarkusVersion": STR(),
      "camelVersion": STR(), "libVersion": STR(), "imageDigest": STR(), "extensions": INT()})), "match": BOOL,
      "pendingUpgrade": obj({"toVersion": STR(64), "affectedFlows": INT()})}, req=["tenantCatalogVersion", "profiles", "match"]),
  "Proposal": obj({"id": UUID, "kind": STR(12), "name": STR(128), "type": enum("ALLOW", "NEW_COMPONENT"), "justification": STR(4000),
      "status": enum("OPEN", "ACCEPTED", "REJECTED", "WITHDRAWN"), "createdBy": STR(64), "createdAt": TS, "decidedBy": STR(64), "decisionNote": STR(2000)}, req=["id", "kind", "name", "type", "status"]),
  "ProposalCreate": obj({"kind": STR(12), "name": STR(128), "type": enum("ALLOW", "NEW_COMPONENT"), "justification": STR(4000, minLength=20)}, req=["kind", "name", "type", "justification"]),
  "ProposalDecision": obj({"decision": enum("ACCEPTED", "REJECTED"), "note": STR(2000, minLength=10), "policyDecision": enum("ALLOWED", "PER_FLOW")}, req=["decision", "note"]),
  "ProposalList": obj({"items": arr(R("Proposal"))}, req=["items"]),
  # ---- templates, params, history
  "Template": obj({"code": STR(64, pattern="^tpl-[a-z0-9-]{2,60}$"), "name": STR(255), "description": STR(4000), "category": STR(32),
      "resourceKind": R("ResourceKind"), "scope": enum("PLATFORM", "TENANT"), "status": enum("ACTIVE", "DEPRECATED"), "catalogVersion": STR(64)}, req=["code", "name", "scope"]),
  "TemplateDetail": {"allOf": [R("Template"), obj({"bodyYaml": STR(524288), "paramSchema": ANYOBJ, "previewLayout": ANYOBJ})]},
  "TemplateList": obj({"items": arr(R("Template"))}, req=["items"]),
  "TemplateCreate": obj({"code": STR(64, pattern="^tpl-[a-z0-9-]{2,60}$"), "name": STR(255), "description": STR(4000), "category": STR(32),
      "fromFlow": R("FlowCode"), "fromVersionNo": INT(minimum=1), "paramSchema": ANYOBJ}, req=["code", "name", "fromFlow", "fromVersionNo", "paramSchema"]),
  "Settings": obj({"params": arr(obj({"key": STR(pattern="^04\\.[a-z0-9.-]+(\\.[A-Z]+)?$"), "value": {}, "default": {}, "domain": STR(), "updatedBy": STR(64), "updatedAt": TS})),
      "freezeWindows": arr(obj({"from": TS, "to": TS, "reason": STR(500), "createdBy": STR(64)})),
      "envVars": arr(R("EnvVar"))}, req=["params"]),
  "EnvVar": obj({"name": STR(63, pattern="^[a-z][a-z0-9-]{1,62}$"), "description": STR(500),
      "values": obj({"TEST": STR(2000), "STAGING": STR(2000), "PROD": STR(2000)}), "usedBy": INT()}, req=["name", "values"]),
  "EnvVarList": obj({"items": arr(R("EnvVar"), maxItems=500)}, req=["items"]),
  "HistoryEntry": obj({"at": TS, "action": STR(64), "actor": STR(64), "actorName": STR(255), "target": STR(255), "versionNo": INT(),
      "environment": R("Environment"), "reason": STR(1000), "before": {}, "after": {}, "traceId": STR()}, req=["at", "action", "actor"]),
  "HistoryPage": obj({"items": arr(R("HistoryEntry")), "page": R("CursorMeta")}, req=["items", "page"]),
}
# CursorMeta viết lại gọn
SCHEMAS["CursorMeta"] = obj({"next": {"type": ["string", "null"], "maxLength": 2048}, "hasMore": BOOL}, req=["hasMore"])

PARAMS = {
  "FlowCodePath": {"name": "flowCode", "in": "path", "required": True, "schema": R("FlowCode")},
  "VersionNoPath": {"name": "versionNo", "in": "path", "required": True, "schema": INT(minimum=1)},
  "WorkspacePath": {"name": "workspaceCode", "in": "path", "required": True, "schema": R("WorkspaceCode")},
  "RunIdPath": {"name": "runId", "in": "path", "required": True, "schema": UUID},
  "CaseIdPath": {"name": "caseId", "in": "path", "required": True, "schema": UUID},
  "DeploymentIdPath": {"name": "deploymentId", "in": "path", "required": True, "schema": UUID},
  "CommandIdPath": {"name": "commandId", "in": "path", "required": True, "schema": UUID},
  "Cursor": {"name": "cursor", "in": "query", "schema": STR(2048), "description": "Con trỏ mờ từ `page.next`."},
  "Limit": {"name": "limit", "in": "query", "schema": INT(minimum=1, maximum=100, default=25), "description": "Vượt 100 trả ERR-04-026."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại; thiếu trả ERR-04-007 (428), lệch trả ERR-04-006 (412)."},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16), "description": "16…128 ký tự, lưu 24 giờ; cùng khóa khác nội dung trả ERR-04-018."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
}

ERR = {  # mô tả ngắn: in vào cột "Lỗi" của đặc tả từng endpoint (chương 10); mã chi tiết ở §6
  "BadRequest": (400, "ERR-04-049", "Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026)."),
  "Unauthorized": (401, "ERR-04-044", "Thiếu hoặc hết hạn token (ERR-04-044)."),
  "Forbidden": (403, "ERR-04-045", "Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015)."),
  "NotFound": (404, "ERR-04-001", "Không tìm thấy hoặc không được xem (ERR-04-001)."),
  "Conflict": (409, "ERR-04-005", "Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005)."),
  "PreconditionFailed": (412, "ERR-04-006", "ETag lệch (ERR-04-006)."),
  "PreconditionRequired": (428, "ERR-04-007", "Thiếu If-Match (ERR-04-007)."),
  "PayloadTooLarge": (413, "ERR-04-033", "Thân quá lớn (ERR-04-033; bản tin ERR-04-021)."),
  "UnsupportedMediaType": (415, "ERR-04-046", "Kiểu nội dung không hỗ trợ (ERR-04-046)."),
  "Unprocessable": (422, "ERR-04-009", "Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009)."),
  "Locked": (423, "ERR-04-041", "Đóng băng thay đổi (ERR-04-041)."),
  "TooManyRequests": (429, "ERR-04-048", "Vượt tần suất (ERR-04-048) hoặc hạn mức chạy thử (ERR-04-019)."),
  "BadGateway": (502, "ERR-04-022", "Không ghi được kho cấu hình (ERR-04-022)."),
  "ServiceUnavailable": (503, "ERR-04-047", "Phụ thuộc chưa sẵn sàng (ERR-04-047; sandbox ERR-04-019)."),
}
RESPONSES = {k: {"description": d, "content": {"application/problem+json": {"schema": R("ProblemDetails"),
    "example": {"type": f"https://datahub.gov.vn/problems/integration/{c.lower()}", "title": d.split(";")[0].split("(")[0].strip().rstrip("."), "status": st,
                "code": c, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}} for k, (st, c, d) in ERR.items()}
RESPONSES["NotModified"] = {"description": "Không đổi (If-None-Match khớp)."}

SSE = {"text/event-stream": {"schema": STR(description="Luồng sự kiện SSE; mỗi sự kiện `event: <tên>` và `data: <JSON>`.")}}

def J(schema, example=None):
    c = {"schema": R(schema)}
    if example is not None: c["example"] = example
    return {"application/json": c}

# (method, path, id, operationId, tag, summary, FR, perm, wsLevel, params, body, success(code, schema|None), errors, extra)
E = []
def ep(method, path, aid, op, tag, summary, fr, perm, ws=None, params=(), body=None, ok=(200, None), errs=(), idem=False, desc=None, etag_out=False, sse=False):
    E.append(dict(method=method, path=path, aid=aid, op=op, tag=tag, summary=summary, fr=fr, perm=perm, ws=ws, params=list(params),
                  body=body, ok=ok, errs=list(errs), idem=idem, desc=desc, etag_out=etag_out, sse=sse))

F, V = "FlowCodePath", "VersionNoPath"
# ---- Workspace
ep("get", "/workspaces", "API-04-001", "listWorkspaces", "Không gian làm việc", "Danh sách không gian làm việc", ["FR-04-007"], "PERM-04-read", ok=(200, "WorkspaceList"))
ep("post", "/workspaces", "API-04-002", "createWorkspace", "Không gian làm việc", "Tạo không gian làm việc", ["FR-04-007"], "PERM-04-admin", body="WorkspaceCreate", ok=(201, "Workspace"), errs=["Conflict"], idem=True, desc="Mã trùng trả ERR-04-028.")
ep("patch", "/workspaces/{workspaceCode}", "API-04-002", "updateWorkspace", "Không gian làm việc", "Sửa không gian làm việc", ["FR-04-007"], "PERM-04-admin", ws="MAINTAIN", params=["WorkspacePath", "IfMatch"], body="WorkspaceUpdate", ok=(200, "Workspace"), errs=["NotFound", "PreconditionFailed", "PreconditionRequired"])
ep("post", "/workspaces/{workspaceCode}:archive", "API-04-003", "archiveWorkspace", "Không gian làm việc", "Lưu trữ không gian làm việc", ["FR-04-007"], "PERM-04-admin", params=["WorkspacePath", "IfMatch"], ok=(200, "Workspace"), errs=["NotFound", "Conflict", "PreconditionFailed"], desc="Không gian còn luồng chưa gỡ vẫn lưu trữ được (ẩn khỏi ô chọn khi tạo luồng). Xóa hẳn không có API; xóa khi còn luồng trả ERR-04-017.")
ep("get", "/workspaces/{workspaceCode}/members", "API-04-004", "listWorkspaceMembers", "Không gian làm việc", "Danh sách thành viên", ["FR-04-007"], "PERM-04-read", ws="VIEW", params=["WorkspacePath"], ok=(200, "WorkspaceMembers"), errs=["NotFound"])
ep("put", "/workspaces/{workspaceCode}/members", "API-04-004", "replaceWorkspaceMembers", "Không gian làm việc", "Thay danh sách thành viên", ["FR-04-007"], "PERM-04-admin", ws="MAINTAIN", params=["WorkspacePath", "IfMatch"], body="WorkspaceMembers", ok=(200, "WorkspaceMembers"), errs=["NotFound", "PreconditionFailed", "PreconditionRequired"], desc="TA hoặc thành viên mức MAINTAIN. Kiểm toán ghi danh sách thêm, bớt.")
# ---- Flow
ep("get", "/flows", "API-04-010", "listFlows", "Luồng", "Danh sách luồng", ["FR-04-001"], "PERM-04-read",
   params=[{"name": "q", "in": "query", "schema": STR(100, minLength=2), "description": "Tìm không dấu trên mã, tên, mô tả."},
           {"name": "workspace", "in": "query", "schema": arr(R("WorkspaceCode")), "style": "form", "explode": False},
           {"name": "status", "in": "query", "schema": arr(R("FlowStatus")), "style": "form", "explode": False},
           {"name": "environment", "in": "query", "schema": R("Environment")},
           {"name": "health", "in": "query", "schema": arr(R("HealthStatus")), "style": "form", "explode": False},
           {"name": "resourceKind", "in": "query", "schema": arr(R("ResourceKind")), "style": "form", "explode": False},
           {"name": "exposure", "in": "query", "schema": R("Exposure")},
           {"name": "endpoint", "in": "query", "schema": STR(255), "description": "Chuỗi con của URI điểm kết nối đã chuẩn hóa (EN-04-04b)."},
           {"name": "label", "in": "query", "schema": arr(STR(127)), "style": "form", "explode": True, "description": "`khóa:giá-trị`."},
           {"name": "sort", "in": "query", "schema": STR(pattern="^-?(code|name|updatedAt|status)$", default="-updatedAt")},
           "Cursor", "Limit"], ok=(200, "FlowPage"), errs=["BadRequest"], desc="Lọc theo phạm vi không gian làm việc ở SQL khi `04.workspace.enforce` bật. Kèm `facets` đếm theo trạng thái, môi trường.")
ep("post", "/flows", "API-04-011", "createFlow", "Luồng", "Tạo luồng và phiên bản 1", ["FR-04-003", "FR-04-025"], "PERM-04-create", ws="EDIT", body="FlowCreate", ok=(201, "FlowDetail"),
   errs=["Conflict", "NotFound", "Forbidden", "Unprocessable", "PayloadTooLarge"], idem=True, etag_out=True,
   desc="Ghi luồng, phiên bản 1 `DRAFT`, chỉ mục, outbox EVT-04-01 trong một giao dịch. Mã trùng ERR-04-002; không gian không tồn tại ERR-04-027; khuôn không tồn tại ERR-04-039; YAML lỗi ERR-04-008; loại tài nguyên không khớp ERR-04-009; vượt kích thước ERR-04-033.")
ep("get", "/flows/{flowCode}", "API-04-012", "getFlow", "Luồng", "Chi tiết luồng", ["FR-04-002"], "PERM-04-read", ws="VIEW", params=[F], ok=(200, "FlowDetail"), errs=["NotFound"], etag_out=True)
ep("patch", "/flows/{flowCode}", "API-04-013", "updateFlow", "Luồng", "Sửa thông tin luồng", ["FR-04-004"], "PERM-04-update", ws="EDIT", params=[F, "IfMatch"], body="FlowUpdate", ok=(200, "FlowDetail"),
   errs=["NotFound", "Conflict", "PreconditionFailed", "PreconditionRequired"], etag_out=True, desc="Chuyển không gian cần mức EDIT ở cả hai nơi. Luồng đã gỡ ERR-04-034.")
ep("post", "/flows/{flowCode}:clone", "API-04-014", "cloneFlow", "Luồng", "Nhân bản luồng", ["FR-04-005"], "PERM-04-create", ws="EDIT", params=[F], body="CloneRequest", ok=(201, "FlowDetail"), errs=["NotFound", "Conflict"], idem=True)
ep("post", "/flows/{flowCode}:retire", "API-04-015", "retireFlow", "Luồng", "Gỡ luồng", ["FR-04-006"], "PERM-04-delete", params=[F, "IfMatch"], body="RetireRequest", ok=(202, "FlowDetail"),
   errs=["NotFound", "Conflict", "BadRequest", "PreconditionFailed"], desc="Rút luồng khỏi các môi trường theo thứ tự PROD → TEST qua Git rồi chuyển RETIRED. Còn phụ thuộc cứng ERR-04-017 kèm `dependencies`; thiếu lý do ERR-04-025.")
ep("get", "/flows/{flowCode}/dependencies", "API-04-016", "getFlowDependencies", "Luồng", "Phụ thuộc của luồng", ["FR-04-006", "FR-04-002"], "PERM-04-read", ws="VIEW", params=[F], ok=(200, "Dependencies"), errs=["NotFound"])
# ---- Version
ep("get", "/flows/{flowCode}/versions", "API-04-024", "listVersions", "Phiên bản", "Danh sách phiên bản", ["FR-04-011"], "PERM-04-read", ws="VIEW", params=[F], ok=(200, "VersionList"), errs=["NotFound"])
ep("post", "/flows/{flowCode}/versions", "API-04-021", "createVersion", "Phiên bản", "Tạo phiên bản mới từ phiên bản có sẵn", ["FR-04-011"], "PERM-04-update", ws="EDIT", params=[F], body="NewVersionRequest", ok=(201, "VersionDetail"),
   errs=["NotFound", "Conflict"], idem=True, etag_out=True, desc="Sao chép định nghĩa, bố cục, bản tin mẫu, ánh xạ. Đã có phiên bản mở ERR-04-016.")
ep("get", "/flows/{flowCode}/versions/{versionNo}", "API-04-020", "getVersion", "Phiên bản", "Lấy phiên bản (định nghĩa, bố cục, bản tin mẫu)", ["FR-04-010"], "PERM-04-read", ws="VIEW", params=[F, V], ok=(200, "VersionDetail"), errs=["NotFound"], etag_out=True,
   desc="Trả ETag để lưu nháp. ERR-04-004 khi phiên bản không tồn tại.")
ep("put", "/flows/{flowCode}/versions/{versionNo}/draft", "API-04-022", "saveDraft", "Phiên bản", "Lưu nháp", ["FR-04-024", "FR-04-010", "FR-04-022"], "PERM-04-update", ws="EDIT", params=[F, V, "IfMatch"], body="DraftUpdate", ok=(200, "DraftSaved"),
   errs=["NotFound", "Conflict", "PreconditionFailed", "PreconditionRequired", "PayloadTooLarge", "Unprocessable", "Locked"], etag_out=True,
   desc="Chỉ ở DRAFT, CHANGES_REQUESTED (ERR-04-005). Chạy kiểm tra mức DESIGN (không chặn lưu) trừ VR-01 cú pháp (ERR-04-008) và VR-03 bí mật (ERR-04-010). Thêm người gọi vào danh sách người đóng góp. ERR-04-041 chỉ khi tỉnh đóng băng cả việc soạn.")
ep("post", "/flows/{flowCode}/versions/{versionNo}:discard", "API-04-023", "discardVersion", "Phiên bản", "Hủy bản nháp", ["FR-04-006"], "PERM-04-update", ws="EDIT", params=[F, V, "IfMatch"], ok=(200, "VersionSummary"), errs=["NotFound", "Conflict", "PreconditionFailed"])
ep("get", "/flows/{flowCode}/versions/{versionNo}/diff", "API-04-025", "diffVersion", "Phiên bản", "So sánh với phiên bản khác", ["FR-04-043"], "PERM-04-read", ws="VIEW",
   params=[F, V, {"name": "base", "in": "query", "schema": INT(minimum=1), "description": "Mặc định: phiên bản đang chạy ở PROD."}, {"name": "markViewed", "in": "query", "schema": {"type": "boolean", "default": False}, "description": "Người duyệt ghi nhận đã xem khác biệt (review.action = DIFF_VIEWED)."}],
   ok=(200, "DiffResult"), errs=["NotFound"])
ep("get", "/flows/{flowCode}/versions/{versionNo}/download", "API-04-026", "downloadVersion", "Phiên bản", "Tải định nghĩa", ["FR-04-027"], "PERM-04-read", ws="VIEW",
   params=[F, V, {"name": "format", "in": "query", "schema": enum("yaml", "yaml+layout", "bundle"), "required": True}], ok=(200, None), errs=["NotFound"])
ep("post", "/flows/{flowCode}/versions/{versionNo}:import-yaml", "API-04-027", "importYaml", "Phiên bản", "Nhập YAML thay định nghĩa", ["FR-04-027"], "PERM-04-update", ws="EDIT", params=[F, V, "IfMatch"], body="ImportYamlRequest", ok=(200, "DraftSaved"),
   errs=["NotFound", "Conflict", "PreconditionFailed", "Unprocessable", "PayloadTooLarge"], etag_out=True)
ep("post", "/legacy-imports", "API-04-028", "startLegacyImport", "Di trú", "Chuyển Camel XML của Bus cũ", ["FR-04-082"], "PERM-04-create", ws="EDIT", body=None, ok=(202, "LegacyImportJob"),
   errs=["Unprocessable", "PayloadTooLarge", "UnsupportedMediaType"], idem=True, desc="multipart/form-data: `file` (≤ 2 MiB, XML hoặc ZIP gói xuất Context), `workspaceCode`, `connectionMap` (JSON). Tệp không hợp lệ ERR-04-032.")
ep("get", "/legacy-imports/{jobId}", "API-04-028", "getLegacyImport", "Di trú", "Kết quả chuyển đổi", ["FR-04-082"], "PERM-04-read", params=[{"name": "jobId", "in": "path", "required": True, "schema": UUID}], ok=(200, "LegacyImportJob"), errs=["NotFound"])
ep("put", "/flows/{flowCode}/versions/{versionNo}/session", "API-04-034", "heartbeatSession", "Phiên bản", "Nhịp phiên soạn", ["FR-04-024"], "PERM-04-update", ws="EDIT", params=[F, V], ok=(200, "SessionState"), errs=["NotFound"],
   desc="Gọi mỗi 30 giây khi tab đang hiện; hết hạn sau 120 giây. Không khóa; chỉ thông tin người khác đang mở và catalogVersion hiện hành.")
ep("delete", "/flows/{flowCode}/versions/{versionNo}/session", "API-04-034", "endSession", "Phiên bản", "Kết thúc phiên soạn", ["FR-04-024"], "PERM-04-update", params=[F, V], ok=(204, None), errs=["NotFound"])
# ---- Validation & tools
ep("post", "/flows/{flowCode}/versions/{versionNo}:validate", "API-04-030", "validateVersion", "Kiểm tra hợp lệ", "Kiểm tra hợp lệ phiên bản", ["FR-04-023"], "PERM-04-read", ws="VIEW", params=[F, V], body="ValidateRequest", ok=(200, "ValidationResult"), errs=["NotFound"])
ep("post", "/validation:check", "API-04-031", "validateYaml", "Kiểm tra hợp lệ", "Kiểm tra YAML chưa lưu", ["FR-04-023", "FR-04-003"], "PERM-04-create", body="StatelessValidateRequest", ok=(200, "ValidationResult"), errs=["PayloadTooLarge"],
   desc="Dùng ở UI-04-03 bước 3 và khi nhập YAML; không ghi gì.")
ep("post", "/expressions:check", "API-04-032", "checkExpression", "Kiểm tra hợp lệ", "Biên dịch, xem trước biểu thức", ["FR-04-015"], "PERM-04-update", body="ExpressionCheckRequest", ok=(200, "ExpressionCheckResult"), errs=["Unprocessable", "PayloadTooLarge", "ServiceUnavailable"],
   desc="Biên dịch bằng engine Camel đúng phiên bản; `evaluate = true` chạy trên sandbox. Lỗi biên dịch trả 200 với `valid = false` (giao diện tô vị trí); ERR-04-037 chỉ khi gọi ở chế độ chặt. Sandbox không sẵn sàng ERR-04-019 (503).")
ep("post", "/mappings:preview", "API-04-033", "previewMapping", "Kiểm tra hợp lệ", "Xem trước ánh xạ (JQ) trên bản tin mẫu", ["FR-04-020"], "PERM-04-update", body="MappingPreviewRequest", ok=(200, "MappingPreviewResult"), errs=["Unprocessable", "PayloadTooLarge", "ServiceUnavailable"],
   desc="Sinh JQ từ dhmap ở máy chủ, chạy trên sandbox có hàm dh_map. ERR-04-038 khi ánh xạ không hợp lệ; tài liệu mẫu ≤ 1 MiB (ERR-04-021).")
# ---- Test
ep("post", "/flows/{flowCode}/versions/{versionNo}/test-runs", "API-04-040", "startTestRun", "Chạy thử", "Bắt đầu chạy thử", ["FR-04-030", "FR-04-032"], "PERM-04-update", ws="EDIT", params=[F, V], body="TestRunRequest", ok=(202, "TestRun"),
   errs=["NotFound", "Unprocessable", "PayloadTooLarge", "TooManyRequests", "ServiceUnavailable"], idem=True,
   desc="Kiểm tra mức DESIGN (ERR-04-009). Hạn mức `04.test.max-concurrent` (ERR-04-019, 429). SANDBOX_LIVE cần kết nối có giá trị TEST (ERR-04-013). Trả `Location` tới API-04-042.")
ep("get", "/flows/{flowCode}/test-runs", "API-04-041", "listTestRuns", "Chạy thử", "Lịch sử chạy thử", ["FR-04-030"], "PERM-04-read", ws="VIEW",
   params=[F, {"name": "versionNo", "in": "query", "schema": INT(minimum=1)}, {"name": "status", "in": "query", "schema": arr(R("TestRunStatus")), "style": "form", "explode": False},
           {"name": "testCaseId", "in": "query", "schema": UUID}, "Cursor", "Limit"], ok=(200, "TestRunPage"), errs=["NotFound"])
ep("get", "/flows/{flowCode}/test-runs/{runId}", "API-04-042", "getTestRun", "Chạy thử", "Kết quả lần chạy thử", ["FR-04-030"], "PERM-04-read", ws="VIEW", params=[F, "RunIdPath"], ok=(200, "TestRun"), errs=["NotFound"])
ep("get", "/flows/{flowCode}/test-runs/{runId}/events", "API-04-042", "streamTestRun", "Chạy thử", "Luồng sự kiện lần chạy thử (SSE)", ["FR-04-030"], "PERM-04-read", ws="VIEW", params=[F, "RunIdPath"], ok=(200, None), errs=["NotFound"], sse=True,
   desc="Sự kiện `status` (TestRun rút gọn), `step` (TestRunStep), `completed` (TestRun đầy đủ), `heartbeat` mỗi 15 giây. Đóng sau `completed`. Mất kết nối thì client hỏi API-04-042 mỗi 2 giây.")
ep("get", "/flows/{flowCode}/test-runs/{runId}/steps/{seqNo}/body", "API-04-042", "getTestRunBody", "Chạy thử", "Thân bản tin đầy đủ của một chặng", ["FR-04-030"], "PERM-04-update", ws="EDIT",
   params=[F, "RunIdPath", {"name": "seqNo", "in": "path", "required": True, "schema": INT(minimum=0)}, {"name": "side", "in": "query", "required": True, "schema": enum("in", "out")}], ok=(200, None), errs=["NotFound"],
   desc="Chỉ khi lần chạy bật captureBodies và chưa quá 04.test.body-retention-days; trả 404 khi đã xóa. Nội dung đã che theo BR-04-013.")
ep("post", "/flows/{flowCode}/test-runs/{runId}:cancel", "API-04-043", "cancelTestRun", "Chạy thử", "Hủy lần chạy thử", ["FR-04-030"], "PERM-04-update", ws="EDIT", params=[F, "RunIdPath"], ok=(200, "TestRun"), errs=["NotFound", "Conflict"])
ep("get", "/flows/{flowCode}/test-cases", "API-04-044", "listTestCases", "Chạy thử", "Danh sách ca kiểm thử", ["FR-04-031"], "PERM-04-read", ws="VIEW", params=[F], ok=(200, "TestCaseList"), errs=["NotFound"])
ep("post", "/flows/{flowCode}/test-cases", "API-04-044", "createTestCase", "Chạy thử", "Tạo ca kiểm thử", ["FR-04-031"], "PERM-04-update", ws="EDIT", params=[F], body="TestCase", ok=(201, "TestCase"), errs=["NotFound", "Conflict", "Unprocessable", "PayloadTooLarge"], idem=True, etag_out=True)
ep("put", "/flows/{flowCode}/test-cases/{caseId}", "API-04-044", "updateTestCase", "Chạy thử", "Sửa ca kiểm thử", ["FR-04-031"], "PERM-04-update", ws="EDIT", params=[F, "CaseIdPath", "IfMatch"], body="TestCase", ok=(200, "TestCase"), errs=["NotFound", "PreconditionFailed", "Unprocessable"], etag_out=True)
ep("delete", "/flows/{flowCode}/test-cases/{caseId}", "API-04-044", "deleteTestCase", "Chạy thử", "Xóa (ngừng dùng) ca kiểm thử", ["FR-04-031"], "PERM-04-update", ws="EDIT", params=[F, "CaseIdPath", "IfMatch"], ok=(204, None), errs=["NotFound", "PreconditionFailed"])
# ---- Review
ep("post", "/flows/{flowCode}/versions/{versionNo}:submit", "API-04-050", "submitVersion", "Duyệt", "Gửi duyệt", ["FR-04-040"], "PERM-04-submit", ws="EDIT", params=[F, V, "IfMatch"], body="SubmitRequest", ok=(200, "VersionDetail"),
   errs=["NotFound", "Conflict", "Unprocessable", "PreconditionFailed", "PreconditionRequired", "BadRequest"], etag_out=True,
   desc="Kiểm tra mức SUBMIT (ERR-04-009), lần chạy thử đạt trên đúng băm và mọi ca đạt (ERR-04-014), catalog hiện hành (ERR-04-042), ghi chú (ERR-04-025). Phát EVT-04-03.")
ep("post", "/flows/{flowCode}/versions/{versionNo}:withdraw", "API-04-051", "withdrawVersion", "Duyệt", "Rút lại yêu cầu duyệt", ["FR-04-040"], "PERM-04-submit", ws="EDIT", params=[F, V, "IfMatch"], body="WithdrawRequest", ok=(200, "VersionDetail"), errs=["NotFound", "Conflict", "PreconditionFailed"], etag_out=True)
ep("post", "/flows/{flowCode}/versions/{versionNo}:review", "API-04-052", "reviewVersion", "Duyệt", "Quyết định duyệt", ["FR-04-041", "FR-04-043"], "PERM-04-publish", ws="VIEW", params=[F, V, "IfMatch"], body="ReviewDecision", ok=(200, "VersionDetail"),
   errs=["NotFound", "Forbidden", "Conflict", "BadRequest", "PreconditionFailed"], etag_out=True,
   desc="Bốn mắt (ERR-04-015, 403); thiếu ý kiến hoặc checklist ERR-04-025. Khi `04.review.require-reauth` bật cần token có `auth_time` ≤ 5 phút (acr theo PH-12), nếu không trả 401 kèm `WWW-Authenticate: ... max_age=300`. Phát EVT-04-04 hoặc EVT-04-05.")
ep("get", "/reviews", "API-04-053", "listReviewQueue", "Duyệt", "Hàng đợi duyệt", ["FR-04-041"], "PERM-04-publish",
   params=[{"name": "workspace", "in": "query", "schema": arr(R("WorkspaceCode")), "style": "form", "explode": False}, {"name": "overdue", "in": "query", "schema": BOOL},
           {"name": "mine", "in": "query", "schema": BOOL, "description": "Chỉ yêu cầu gợi ý tôi duyệt."}, "Cursor", "Limit"], ok=(200, "ReviewQueue"))
# ---- Deploy
ep("get", "/flows/{flowCode}/deployments", "API-04-054", "listDeployments", "Triển khai", "Lịch sử triển khai", ["FR-04-042"], "PERM-04-read", ws="VIEW", params=[F, {"name": "environment", "in": "query", "schema": R("Environment")}], ok=(200, "DeploymentList"), errs=["NotFound"])
ep("post", "/flows/{flowCode}/deployments", "API-04-054", "releaseVersion", "Triển khai", "Phát hành phiên bản lên môi trường", ["FR-04-042", "FR-04-075"], "PERM-04-publish", ws="VIEW", params=[F], body="ReleaseRequest", ok=(202, "Deployment"),
   errs=["NotFound", "Conflict", "Unprocessable", "Locked", "BadGateway"], idem=True,
   desc="Chỉ APPROVED (BR-04-012). Kiểm tra mức PUBLISH (ERR-04-009), thứ tự môi trường (ERR-04-023), đóng băng với PROD (ERR-04-041), hồ sơ runtime (ERR-04-029). Ghi Git sau giao dịch; lỗi ghi Git thành triển khai FAILED ERR-04-022. Phát EVT-04-06.")
ep("get", "/flows/{flowCode}/deployments/{deploymentId}", "API-04-054", "getDeployment", "Triển khai", "Chi tiết triển khai", ["FR-04-042"], "PERM-04-read", ws="VIEW", params=[F, "DeploymentIdPath"], ok=(200, "Deployment"), errs=["NotFound"])
ep("get", "/flows/{flowCode}/deployments/{deploymentId}/events", "API-04-054", "streamDeployment", "Triển khai", "Tiến trình triển khai (SSE)", ["FR-04-042"], "PERM-04-read", ws="VIEW", params=[F, "DeploymentIdPath"], ok=(200, None), errs=["NotFound"], sse=True,
   desc="Sự kiện `status` (Deployment), `replica` (bản sao báo phiên bản), `completed`. Đóng khi SYNCED, FAILED hoặc sau 04.deploy.timeout-minutes.")
ep("post", "/flows/{flowCode}/deployments:rollback", "API-04-055", "rollbackDeployment", "Triển khai", "Quay lui về phiên bản đã duyệt trước", ["FR-04-044"], "PERM-04-publish", params=[F], body="RollbackRequest", ok=(202, "Deployment"),
   errs=["NotFound", "Conflict", "BadRequest", "BadGateway"], idem=True, desc="Không cần duyệt lại; vẫn kiểm tra mức PUBLISH. Được phép khi đóng băng. Thành phần nay bị cấm ERR-04-040.")
ep("post", "/flows/{flowCode}/deployments:promote", "API-04-056", "promoteDeployment", "Triển khai", "Nâng phiên bản lên môi trường kế tiếp", ["FR-04-045"], "PERM-04-promote", params=[F], body="PromoteRequest", ok=(202, "Deployment"),
   errs=["NotFound", "Conflict", "Unprocessable", "Locked", "BadGateway"], idem=True, desc="Môi trường trước phải SYNCED, HEALTHY và đủ thời gian ổn định (ERR-04-023).")
# ---- Runtime
ep("get", "/flows/{flowCode}/runtime", "API-04-060", "getRuntimeStatus", "Vận hành", "Tình trạng runtime theo môi trường", ["FR-04-051"], "PERM-04-read", ws="VIEW", params=[F], ok=(200, "RuntimeStatus"), errs=["NotFound"])
ep("post", "/flows/{flowCode}/runtime/commands", "API-04-061", "issueCommand", "Vận hành", "Tạm dừng, tiếp tục, dừng khẩn", ["FR-04-050"], "PERM-04-operate", params=[F], body="CommandRequest", ok=(202, "Command"),
   errs=["NotFound", "Conflict", "BadRequest", "Forbidden"], idem=True,
   desc="EMERGENCY_STOP cần PERM-04-emergency-stop. Thiếu lý do ERR-04-025; chưa triển khai ở môi trường ERR-04-023. Lệnh khẩn đi trước Git (ADR-065).")
ep("get", "/flows/{flowCode}/runtime/commands/{commandId}", "API-04-061", "getCommand", "Vận hành", "Trạng thái lệnh", ["FR-04-050"], "PERM-04-read", ws="VIEW", params=[F, "CommandIdPath"], ok=(200, "Command"), errs=["NotFound"])
ep("post", "/flows/{flowCode}/runtime/commands/{commandId}:resend", "API-04-061", "resendCommand", "Vận hành", "Gửi lại lệnh chưa đủ xác nhận", ["FR-04-050"], "PERM-04-operate", params=[F, "CommandIdPath"], ok=(202, "Command"), errs=["NotFound", "Conflict"],
   desc="Chỉ với PARTIAL; ký lại với hạn mới, cùng commandId gốc trong `resendOf`.")
ep("get", "/flows/{flowCode}/endpoints", "API-04-062", "listEndpoints", "Vận hành", "Điểm kết nối và số liệu", ["FR-04-052"], "PERM-04-read", ws="VIEW", params=[F, {"name": "environment", "in": "query", "schema": R("Environment")}], ok=(200, "EndpointList"), errs=["NotFound"])
ep("get", "/flows/{flowCode}/metrics", "API-04-063", "getFlowMetrics", "Vận hành", "Số liệu theo luồng (từ PH-13)", ["FR-04-053"], "PERM-04-read", ws="VIEW",
   params=[F, {"name": "environment", "in": "query", "required": True, "schema": R("Environment")}, {"name": "from", "in": "query", "schema": TS}, {"name": "to", "in": "query", "schema": TS},
           {"name": "step", "in": "query", "schema": STR(pattern="^[0-9]+[smh]$", default="1m")}], ok=(200, "FlowMetrics"), errs=["NotFound", "ServiceUnavailable"])
# ---- Catalog
ep("get", "/catalog", "API-04-070", "getCatalogIndex", "Danh mục thành phần", "Chỉ mục catalog đã lọc chính sách", ["FR-04-012", "FR-04-080"], "PERM-04-read",
   params=[{"name": "If-None-Match", "in": "header", "schema": STR(128)}], ok=(200, "CatalogIndex"), errs=[], desc="ETag theo catalogVersion + policyVersion + paletteRulesVersion; hỗ trợ 304.")
ep("get", "/catalog/{kind}/{name}", "API-04-071", "getComponentSchema", "Danh mục thành phần", "Lược đồ thuộc tính của thành phần", ["FR-04-014", "FR-04-080"], "PERM-04-read",
   params=[{"name": "kind", "in": "path", "required": True, "schema": enum("components", "eips", "kamelets", "dataformats", "languages", "beans")},
           {"name": "name", "in": "path", "required": True, "schema": STR(128)}, {"name": "catalogVersion", "in": "query", "schema": STR(64)}],
   ok=(200, "ComponentSchema"), errs=["NotFound"], desc="ERR-04-035 khi không có trong catalog của phiên bản yêu cầu.")
ep("get", "/catalog/policies", "API-04-072", "listPolicies", "Danh mục thành phần", "Chính sách thành phần (nền + tỉnh)", ["FR-04-080"], "PERM-04-read", ok=(200, "PolicyList"))
ep("patch", "/catalog/policies", "API-04-072", "updatePolicies", "Danh mục thành phần", "Sửa chính sách thành phần", ["FR-04-080"], "PERM-04-catalog-admin", params=["IfMatch"], body="PolicyUpdate", ok=(200, "PolicyList"),
   errs=["Forbidden", "PreconditionFailed", "Unprocessable"], desc="PA sửa chính sách nền (phiên PLATFORM); TA (PERM-04-admin) chỉ thu hẹp cho tỉnh: ALLOWED từ tỉnh bị từ chối (403). Luồng dùng thành phần vừa cấm được đánh dấu.")
ep("get", "/catalog/versions", "API-04-073", "getCatalogVersions", "Danh mục thành phần", "Phiên bản catalog và hồ sơ runtime", ["FR-04-081", "FR-04-075"], "PERM-04-read", ok=(200, "CatalogVersions"))
ep("get", "/catalog/proposals", "API-04-074", "listProposals", "Danh mục thành phần", "Đề xuất thành phần", ["FR-04-080"], "PERM-04-read", params=[{"name": "status", "in": "query", "schema": enum("OPEN", "ACCEPTED", "REJECTED", "WITHDRAWN")}], ok=(200, "ProposalList"))
ep("post", "/catalog/proposals", "API-04-074", "createProposal", "Danh mục thành phần", "Đề xuất cho phép hoặc bổ sung thành phần", ["FR-04-080"], "PERM-04-read", body="ProposalCreate", ok=(201, "Proposal"), errs=["Conflict"], idem=True)
ep("post", "/catalog/proposals/{proposalId}:decide", "API-04-074", "decideProposal", "Danh mục thành phần", "Quyết định đề xuất", ["FR-04-080"], "PERM-04-catalog-admin", params=[{"name": "proposalId", "in": "path", "required": True, "schema": UUID}], body="ProposalDecision", ok=(200, "Proposal"), errs=["NotFound", "Conflict"])
# ---- Templates
ep("get", "/templates", "API-04-080", "listTemplates", "Khuôn mẫu", "Danh sách khuôn mẫu", ["FR-04-025"], "PERM-04-read", params=[{"name": "resourceKind", "in": "query", "schema": R("ResourceKind")}], ok=(200, "TemplateList"))
ep("get", "/templates/{templateCode}", "API-04-081", "getTemplate", "Khuôn mẫu", "Chi tiết khuôn và lược đồ tham số", ["FR-04-025"], "PERM-04-read", params=[{"name": "templateCode", "in": "path", "required": True, "schema": STR(64)}], ok=(200, "TemplateDetail"), errs=["NotFound"])
ep("post", "/templates", "API-04-082", "createTemplate", "Khuôn mẫu", "Tạo khuôn của tỉnh từ phiên bản đã duyệt", ["FR-04-025"], "PERM-04-admin", body="TemplateCreate", ok=(201, "TemplateDetail"), errs=["Conflict", "NotFound", "Unprocessable"], idem=True)
ep("post", "/templates/{templateCode}:deprecate", "API-04-082", "deprecateTemplate", "Khuôn mẫu", "Ngừng dùng khuôn của tỉnh", ["FR-04-025"], "PERM-04-admin", params=[{"name": "templateCode", "in": "path", "required": True, "schema": STR(64)}, "IfMatch"], ok=(200, "Template"), errs=["NotFound", "Forbidden"])
# ---- Params, history
ep("get", "/settings", "API-04-090", "getSettings", "Tham số", "Tham số 04.*, khoảng đóng băng, biến môi trường", ["FR-04-084"], "PERM-04-read", ok=(200, "Settings"),
   desc="Chỉ đọc; sửa tham số qua màn tham số chung của PH-18 (UI-04-20 nhúng).")
ep("put", "/settings/env-vars", "API-04-090", "replaceEnvVars", "Tham số", "Thay biến môi trường {{dh.env.*}}", ["FR-04-084"], "PERM-04-admin", params=["IfMatch"], body="EnvVarList", ok=(200, "EnvVarList"), errs=["PreconditionFailed", "Unprocessable"],
   desc="Giá trị giống bí mật bị từ chối (ERR-04-010); bí mật dùng {{vault:}}.")
ep("get", "/flows/{flowCode}/history", "API-04-091", "getFlowHistory", "Tham số", "Lịch sử thao tác của luồng (từ PH-13)", ["FR-04-083"], "PERM-04-read", ws="VIEW",
   params=[F, {"name": "action", "in": "query", "schema": arr(STR(64)), "style": "form", "explode": False}, {"name": "actor", "in": "query", "schema": STR(64)}, "Cursor", "Limit"],
   ok=(200, "HistoryPage"), errs=["NotFound", "ServiceUnavailable"], desc="`before`, `after` chỉ trả cho AU, SO, TA.")

def flatten(x, schemas):
    """Gộp allOf thành một đối tượng phẳng: các phần đều đóng (additionalProperties: false) nên allOf
    nguyên dạng sẽ từ chối mọi bản ghi hợp lệ. Gộp properties, required; giữ additionalProperties: false."""
    if isinstance(x, list): return [flatten(i, schemas) for i in x]
    if not isinstance(x, dict): return x
    if "allOf" in x and len(x) == 1:
        props, req, extra = {}, [], {}
        for part in x["allOf"]:
            if "$ref" in part: part = schemas[part["$ref"].split("/")[-1]]
            part = flatten(part, schemas)
            props.update(part.get("properties", {}))
            req += [r for r in part.get("required", []) if r not in req]
            if part.get("description"): extra["description"] = part["description"]
        d = {"type": "object", "properties": props, "additionalProperties": False}
        if req: d["required"] = req
        d.update(extra); return d
    return {k: flatten(v, schemas) for k, v in x.items()}

def ex_param(p, ex):
    """Gắn ví dụ cho tham số: đường dẫn theo BS.PATH_EX, truy vấn theo ex['q'], tiêu đề theo BS.HDR_EX."""
    p = copy.deepcopy(p)
    n = p["name"]
    if p["in"] == "path" and n in BS.PATH_EX: p["example"] = BS.PATH_EX[n]
    if p["in"] == "query" and n in ex.get("q", {}): p["example"] = ex["q"][n]
    if p["in"] == "header" and n in BS.HDR_EX: p["example"] = BS.HDR_EX[n]
    return p

def build():
    paths = {}
    for k in ("FlowCodePath", "VersionNoPath", "WorkspacePath", "RunIdPath", "CaseIdPath", "DeploymentIdPath", "CommandIdPath", "IfMatch", "IdempotencyKey"):
        PARAMS[k] = ex_param(PARAMS[k], {})
    for e in E:
        ex = BS.EX.get(e["op"], {})
        if not e["desc"]: e["desc"] = BS.DESC.get(e["op"])
        op = {"tags": [e["tag"]], "operationId": e["op"], "summary": e["summary"],
              "x-datahub-id": e["aid"], "x-datahub-fr": e["fr"],
              "x-datahub-permission": {"permission": e["perm"], **({"workspaceLevel": e["ws"]} if e["ws"] else {})}}
        if e["desc"]: op["description"] = e["desc"]
        if e["idem"]: op["x-datahub-idempotent"] = True
        params = []
        for p in e["params"]:
            params.append(P(p) if isinstance(p, str) else ex_param(p, ex))
        if e["idem"]: params.append(P("IdempotencyKey"))
        params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = params
        if e["body"]:
            op["requestBody"] = {"required": True, "content": J(e["body"], ex.get("req"))}
        elif e["op"] == "startLegacyImport":
            op["requestBody"] = {"required": True, "content": {"multipart/form-data": {"schema": {"type": "object", "required": ["file", "workspaceCode"],
                "properties": {"file": {"type": "string", "contentEncoding": "binary"}, "workspaceCode": R("WorkspaceCode"),
                               "connectionMap": STR(20000, description="JSON: mã kết nối cũ → mã kết nối PH-05.")}}, "example": ex.get("req")}}}
        code, sch = e["ok"]
        okr = {"description": "Thành công."}
        if e["sse"]:
            okr["content"] = {"text/event-stream": {**SSE["text/event-stream"], "example": ex.get("res")}}
        elif e["op"] == "downloadVersion":
            okr["content"] = {"application/yaml": {"schema": STR(), "example": ex.get("res")}, "application/zip": {"schema": {"type": "string", "contentEncoding": "binary"}}}
        elif e["op"] == "getTestRunBody":
            okr["content"] = {"application/json": {"schema": {}, "example": ex.get("res")}, "text/plain": {"schema": STR()}}
        elif sch:
            okr["content"] = J(sch, ex.get("res"))
        hdr = {}
        if e["etag_out"]: hdr["ETag"] = {"schema": STR(), "description": "W/\"{version}-{contentHash[0..8]}\"", "example": BS.ETAG}
        if code == 202: hdr["Location"] = {"schema": STR(), "description": "Tài nguyên theo dõi tiến trình.", "example": ex.get("loc", "")}
        if e["op"] == "getCatalogIndex": hdr["ETag"] = {"schema": STR(), "example": BS.HDR_EX["If-None-Match"]}
        if hdr: okr["headers"] = hdr
        resps = {str(code): okr}
        if e["op"] == "getCatalogIndex": resps["304"] = RESP("NotModified")
        for r in ["Unauthorized"] + e["errs"]:
            resps[str(ERR[r][0])] = RESP(r)
        if e["method"] != "get" and "403" not in resps: resps["403"] = RESP("Forbidden")
        op["responses"] = dict(sorted(resps.items()))
        paths.setdefault(e["path"], {})[e["method"]] = op
    doc = {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-04 Lõi tích hợp và trình thiết kế luồng API", "version": "1.0.0-draft",
               "summary": "Quản lý luồng Camel: không gian, luồng, phiên bản, kiểm tra hợp lệ, chạy thử, duyệt, triển khai GitOps, điều khiển runtime, catalog.",
               "description": ("API của module `flow` trong `dh-integration` (control plane PH-04). Chỉ người dùng giao diện Datahub gọi "
                   "(token Authorization Code + PKCE qua BFF của console); HTTT thành viên không gọi API này mà gọi **luồng** qua APISIX.\n\n"
                   "Quy ước (D03-04-PH04 §1): tenant lấy từ token; lệnh tạo nhận `Idempotency-Key`; lệnh sửa, đổi trạng thái bắt buộc `If-Match`; "
                   "hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-04-nnn`; phân trang con trỏ; `traceparent` xuyên suốt. "
                   "Mọi tên miền, máy chủ, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-04"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH04", "x-datahub-phase": "PH-04"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn/api/integration/v1", "description": "Qua BFF console của tenant — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
                  {"url": "http://localhost:8081/api/integration/v1", "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": t} for t in dict.fromkeys(e["tag"] for e in E)],
      "paths": paths,
      "components": {
        "securitySchemes": {"oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-04-* (D02-08).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}}},
        "parameters": PARAMS, "responses": RESPONSES, "schemas": {k: flatten(v, SCHEMAS) for k, v in SCHEMAS.items()}}}
    return doc

if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-integration.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH04 · OpenAPI PH-04 (dh-integration, module flow). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    ids = sorted({e["aid"] for e in E})
    print(f"{len(E)} operation, {len(ids)} mã API, {len(SCHEMAS)} lược đồ → {out}")
