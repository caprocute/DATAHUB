#!/usr/bin/env python3
"""Sinh ph14/asyncapi-national.yaml (AsyncAPI 3.0) cho EVT-14-01…17 và ba topic nội bộ. Không sửa tay YAML."""
import os, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
N = {"type": "number"}
TS = S(format="date-time")
A = lambda it: {"type": "array", "items": it}


def obj(props, req=()):
    d = {"type": "object", "properties": props}
    if req: d["required"] = list(req)
    return d


def alloc(base, props, req=()):
    return {"allOf": [R(base), obj(props, req)]}


TEN = S(pattern="^(T[0-9]{2}|COMMON)$")
ENV = S(enum=["TEST", "STAGING", "PROD"])
HEALTH = S(enum=["HEALTHY", "DEGRADED", "UNHEALTHY", "UNKNOWN"])
PSTATE = S(enum=["DRAFT", "TESTED", "PENDING_ACTIVATION", "ACTIVE", "SUSPENDED", "RETIRED"])
CSTATE = S(enum=["UPLOADED", "PENDING_ACTIVATION", "ACTIVE", "EXPIRING", "EXPIRED", "SUPERSEDED", "REVOKED"])
PERIOD = S(enum=["HOUR", "DAY", "MONTH"])

SCHEMAS = {
  "Actor": obj({"userId": S(), "type": S(enum=["USER", "SYSTEM"])}, ["userId", "type"]),
  "Base": obj({"tenantId": TEN, "configVersion": I, "occurredAt": TS, "actor": R("Actor")}, ["tenantId", "occurredAt"]),
  "PlatformChanged": alloc("Base", {"platformCode": S(), "platformType": S(enum=["NDXP", "NDOP", "REGISTRY"]), "from": PSTATE, "to": PSTATE,
      "securityHold": B, "change": S(enum=["STATE", "CREDENTIAL_ROTATION", "SECURITY_HOLD", "CONNECTION", "SETTINGS"]),
      "rotationPhase": S(enum=["TESTING", "TRANSITION", "COMPLETED", "FAILED"]), "reason": S(maxLength=1000)}, ["platformCode", "change"]),
  "ServiceChanged": alloc("Base", {"serviceCode": S(), "platformCode": S(), "change": S(enum=["CREATED", "UPDATED", "LABEL_CHANGED", "SPEC_ACTIVATED", "STATE_CHANGED", "IMPORTED"]),
      "state": S(enum=["DRAFT", "ACTIVE", "DEPRECATED", "RETIRED"]), "reconcileLabel": S(enum=["STILL", "SPEC_CHANGED", "DISCONTINUED", "UNKNOWN"]),
      "contractVersion": S(), "specVersion": S(), "sensitivity": S(enum=["PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE"])}, ["serviceCode", "change"]),
  "RoutingChanged": alloc("Base", {"ruleId": S(format="uuid"), "change": S(enum=["ACTIVATED", "UPDATED", "DISABLED"]), "primaryServiceCode": S(),
      "fallbackServiceCode": {"type": ["string", "null"]}, "priority": I}, ["ruleId", "change"]),
  "CertificateChanged": alloc("Base", {"certCode": S(), "purpose": S(enum=["SIGNING", "TLS_CLIENT", "BOTH"]), "from": CSTATE, "to": CSTATE,
      "notAfter": TS, "signingBlocked": B, "trustAnchorChange": B, "supersedes": {"type": ["string", "null"]}}, ["certCode"]),
  "CertificateExpiring": alloc("Base", {"certCode": S(), "purpose": S(enum=["SIGNING", "TLS_CLIENT", "BOTH"]), "daysLeft": {"type": "integer", "enum": [60, 30, 7]}, "notAfter": TS,
      "replacementReady": B}, ["certCode", "daysLeft", "notAfter"]),
  "SignatureIncidentOpened": alloc("Base", {"incidentId": S(format="uuid"), "kind": S(enum=["SIGNATURE_INVALID", "CHAIN_UNTRUSTED", "SIGNED_AT_SKEW", "REPLAY", "KEY_MISMATCH"]),
      "transactionCode": S(), "platformCode": S(), "securityHold": B, "recentCount10m": I}, ["incidentId", "kind", "platformCode"]),
  "QuotaThresholdReached": alloc("Base", {"quotaId": S(format="uuid"), "platformCode": S(), "serviceCode": {"type": ["string", "null"]}, "period": PERIOD,
      "level": {"type": "integer", "enum": [70, 85, 95]}, "used": I, "limit": I, "resetAt": TS}, ["quotaId", "level", "used", "limit"]),
  "QuotaChanged": alloc("Base", {"quotaId": S(format="uuid"), "platformCode": S(), "serviceCode": {"type": ["string", "null"]}, "period": PERIOD,
      "limit": I, "systemCode": {"type": ["string", "null"], "description": "Có khi là phân bổ cho HTTT."}, "basisDocument": S(), "scope": S(enum=["POLICY", "ALLOCATION"])}, ["quotaId", "scope"]),
  "CacheInvalidated": alloc("Base", {"serviceCode": S(), "scope": S(enum=["SERVICE", "SUBJECT"]), "invalidated": I, "reason": S(maxLength=500)}, ["serviceCode", "scope"]),
  "BreakerChanged": alloc("Base", {"platformCode": S(), "from": S(), "to": S(enum=["CLOSED", "OPEN", "HALF_OPEN", "FORCED_OPEN", "FORCED_CLOSED"]),
      "failureRatio": N, "calls": I, "queueDepth": I, "reason": S(maxLength=500)}, ["platformCode", "to"]),
  "TransactionRecorded": obj({"transactionCode": S(), "tenantId": TEN, "direction": S(enum=["OUTBOUND", "INBOUND"]), "serviceCode": S(), "platformCode": S(),
      "systemCode": S(), "purposeCode": {"type": ["string", "null"]}, "procedureCode": {"type": ["string", "null"]}, "state": S(enum=["REJECTED", "COMPLETED_CACHE", "QUOTA_EXCEEDED", "SUCCEEDED", "FAILED", "TIMEOUT", "UNKNOWN_RESULT", "SIGNATURE_FAILED"]),
      "errorCode": {"type": ["string", "null"], "pattern": "^ERR-14-[0-9]{3}$"}, "fromCache": B, "stale": B, "durationMs": I, "certCode": {"type": ["string", "null"]},
      "payloadRef": {"type": ["string", "null"], "description": "Tham chiếu nội dung mã hóa; không mang nội dung."}, "payloadHash": S(pattern="^sha256:[0-9a-f]{64}$"),
      "traceId": S(pattern="^[0-9a-f]{32}$"), "startedAt": TS, "finishedAt": TS}, ["transactionCode", "tenantId", "direction", "serviceCode", "state", "startedAt"]),
  "SyncRunFinished": alloc("Base", {"runId": S(format="uuid"), "kind": S(enum=["SERVICE_CATALOG", "MASTER_DATA", "OPEN_DATA", "SERVICE_RECONCILE"]),
      "state": S(enum=["SUCCEEDED", "PARTIAL", "FAILED", "TIMED_OUT"]), "sent": I, "accepted": I, "rejected": I, "error": I, "receiptRef": {"type": ["string", "null"]}}, ["runId", "kind", "state"]),
  "InboundChanged": alloc("Base", {"endpointCode": S(), "path": S(), "state": S(enum=["DRAFT", "PENDING_CONFIRM", "ACTIVE", "DISABLED"]),
      "clientCertFingerprints": A(S(pattern="^[0-9a-f]{64}$")), "senders": A(obj({"senderCode": S(), "serviceCodes": A(S())}))}, ["endpointCode", "state"]),
  "ExposureChanged": alloc("Base", {"serviceCode": S(), "apiCode": {"type": ["string", "null"]}, "change": S(enum=["CREATED", "UPDATED", "PUBLISHED", "WITHDRAWN"]), "path": S(), "contractVersion": S(),
      "requestId": S(format="uuid")}, ["serviceCode", "change"]),
  "HealthChanged": obj({"tenantId": TEN, "platformCode": S(), "from": HEALTH, "to": HEALTH, "reasonCode": S(), "reasonDetail": S(maxLength=1000),
      "evaluatedAt": TS, "metrics": obj({"calls5m": I, "errorRate5m": N, "p95Ms": I, "tokenOk": B, "crlAgeDays": I})}, ["tenantId", "platformCode", "to"]),
  "AnomalyDetected": alloc("Base", {"alertId": S(format="uuid"), "rule": S(enum=["LOOKUPS_PER_HOUR", "OFF_HOURS_CALLS", "SUBJECTS_PER_CASE", "SPIKE", "REVEAL_OVER_LIMIT"]),
      "systemCode": S(), "serviceCode": S(), "evidenceSummary": S(maxLength=1000, description="Số liệu tổng hợp, không có dữ liệu cá nhân.")}, ["alertId", "rule"]),
  "NotificationReceived": obj({"notificationId": S(format="uuid"), "tenantId": TEN, "endpointCode": S(), "notificationType": S(enum=["CATALOG_CHANGED", "SERVICE_SPEC_CHANGED", "SERVICE_DISCONTINUED", "OTHER"]),
      "subjectRef": S(), "transactionCode": S(), "receivedAt": TS}, ["notificationId", "tenantId", "notificationType", "receivedAt"]),
  "WorkerCommand": obj({"commandId": S(format="uuid"), "tenantId": TEN, "kind": S(enum=["probe", "cert.selftest", "token.test", "sync.run", "spec.fetch", "catalog.fetch"]),
      "platformCode": S(), "environment": ENV, "args": {"type": "object", "additionalProperties": True, "description": "Tham số lệnh; không có bí mật, worker tự đọc OpenBao."},
      "deadline": TS}, ["commandId", "tenantId", "kind", "deadline"]),
  "WorkerResult": obj({"commandId": S(format="uuid"), "tenantId": TEN, "status": S(enum=["OK", "FAILED", "TIMEOUT"]),
      "result": {"type": "object", "additionalProperties": True}, "causeCode": S(), "hint": S(maxLength=1000), "finishedAt": TS}, ["commandId", "tenantId", "status"]),
  "QuotaUsage": obj({"tenantId": TEN, "quotaId": S(format="uuid"), "bucket": S(), "used": I, "windowStart": TS, "reportedAt": TS, "replica": S()}, ["tenantId", "quotaId", "used", "reportedAt"]),
}

EXAMPLES = {
  "PlatformChanged": {"tenantId": "T68", "configVersion": 1842, "occurredAt": "2026-11-26T08:15:00Z", "platformCode": "ndxp-t68", "change": "STATE", "from": "TESTED", "to": "ACTIVE",
      "actor": {"userId": "u-ia-0017", "type": "USER"}},
  "CertificateExpiring": {"tenantId": "T68", "occurredAt": "2026-11-26T01:00:00Z", "certCode": "ky-so-t68-2026", "purpose": "SIGNING", "daysLeft": 30,
      "notAfter": "2026-12-26T00:00:00Z", "replacementReady": False},
  "TransactionRecorded": {"transactionCode": "T68-20261126-0000184320", "tenantId": "T68", "direction": "OUTBOUND", "serviceCode": "lltp-tra-trang-thai", "platformCode": "ndxp-t68",
      "systemCode": "DVC", "purposeCode": "GIAI_QUYET_TTHC", "procedureCode": "1.001234", "state": "SUCCEEDED", "errorCode": None, "fromCache": False, "stale": False, "durationMs": 842,
      "certCode": "ky-so-t68-2026", "payloadRef": "dh-nat-payload/T68/20261126/0000184320", "payloadHash": "sha256:" + "ab" * 32,
      "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "startedAt": "2026-11-26T08:15:01Z", "finishedAt": "2026-11-26T08:15:02Z"},
  "QuotaThresholdReached": {"tenantId": "T68", "occurredAt": "2026-11-26T09:40:00Z", "quotaId": "0b1d2c3e-4f50-4a6b-8c7d-9e0f1a2b3c4d", "platformCode": "ndxp-t68",
      "period": "DAY", "level": 85, "used": 4250, "limit": 5000, "resetAt": "2026-11-27T00:00:00Z"},
}
for _k, _v in EXAMPLES.items():
    SCHEMAS[_k]["examples"] = [_v]

CE_HEADERS = obj({"ce_specversion": S(const="1.0"), "ce_id": S(format="uuid"), "ce_source": S(description="`/tenants/{tenant}/national`"),
    "ce_type": S(description="`vn.datahub.national.{đối tượng}.{sự kiện}.v1`"), "ce_time": TS, "ce_subject": S(description="Mã đối tượng."),
    "ce_datacontenttype": S(const="application/json"), "traceparent": S()}, ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time"])
SPOOL_HEADERS = obj({"traceparent": S(), "ce_id": S(format="uuid"), "ce_type": S(), "ce_time": TS})


def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, addr, payload, summ, days, parts, sender, via, kdesc, recv in spec.EVTS:
        ch = {"address": addr, "title": code, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
              "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
              "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3,
                  "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        channels[key] = ch
        cap = key[0].upper() + key[1:]
        ops[f"send{cap}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — {sender} phát ({via})",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{cap}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{recv} nhận"}
        msgs[key] = {"name": key, "title": code, "summary": summ, "payload": R(payload),
            "headers": CE_HEADERS if via == "Outbox" else SPOOL_HEADERS, "bindings": {"kafka": {"key": S(description=kdesc)}}}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-14 Kết nối quốc gia — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-14-01…17 (D03-04-PH14 §4, FRS §9.3) và ba topic nội bộ giữa `dh-integration` và hồ sơ `national-gateway`.\n\n"
          "Sự kiện phát từ `dh-integration` ghi vào `ph14_national.outbox` cùng giao dịch, Debezium hoặc bộ quét 500 ms đưa lên Kafka, CloudEvents 1.0 chế độ nhị phân. "
          "Sự kiện phát từ cổng (`gateway`, `worker`) đi qua `LedgerSpool` (ghi đĩa rồi đẩy Kafka, ít nhất một lần). "
          "Không sự kiện nào mang nội dung bản tin, thông tin xác thực, khóa hay dữ liệu cá nhân; chỉ siêu dữ liệu và mã tham chiếu. "
          "Bên nhận xử lý lũy đẳng theo `configVersion`, `transactionCode` hoặc `commandId`. Lược đồ đăng ký ở Apicurio, chế độ BACKWARD: chỉ thêm trường tùy chọn trong `v1` (ADR-070). "
          "Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`).", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN và tiền tố `{tenant}.national.`."}},
        "messages": msgs, "schemas": SCHEMAS}}


if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-national.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH14 · AsyncAPI PH-14. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(spec.EVTS)} kênh → {out}")
