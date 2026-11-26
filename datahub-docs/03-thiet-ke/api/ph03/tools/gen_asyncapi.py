#!/usr/bin/env python3
"""Sinh ph03/asyncapi-gateway.yaml (AsyncAPI 3.0) cho EVT-03-01…12. Không sửa tay YAML."""
import os, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
TS = S(format="date-time")
A = lambda it, **kw: {"type": "array", "items": it, **kw}
def obj(props, req=()):
    d = {"type": "object", "properties": props}
    if req: d["required"] = list(req)
    return d
TEN = S(pattern="^(T[0-9]{2}|COMMON)$", description="Mã tenant; `COMMON` cho phần dùng chung toàn nền tảng.")
SHA = S(pattern="^[0-9a-f]{64}$")
ROUTE_STATE = S(enum=["PENDING", "ACTIVE", "STOPPED", "SUSPENDED", "SUNSET", "RETIRED"])

SCHEMAS = {
  "Actor": obj({"userId": S(), "type": S(enum=["USER", "SYSTEM"])}, ["userId", "type"]),
  "SnapshotPublished": obj({"tenantId": TEN, "snapshotVersion": I, "site": S(), "scope": TEN, "contentHash": SHA, "signatureKeyId": S(),
        "trigger": S(enum=["AUTO", "MANUAL", "ROLLBACK", "IMPORT", "RECONCILE"]),
        "builtFrom": A(obj({"source": S(), "cursor": S()}, ["source"])),
        "routes": obj({"added": I, "changed": I, "removed": I}), "gitPending": B, "publishedAt": TS, "actor": R("Actor")},
        ["tenantId", "snapshotVersion", "site", "scope", "contentHash", "trigger", "publishedAt"]),
  "SnapshotRolledBack": obj({"tenantId": TEN, "snapshotVersion": I, "targetVersion": I, "site": S(), "scope": TEN, "holdUntil": TS,
        "reason": S(maxLength=500), "rolledBackAt": TS, "actor": R("Actor")},
        ["tenantId", "snapshotVersion", "targetVersion", "scope", "reason", "rolledBackAt"]),
  "RouteStateChanged": obj({"tenantId": TEN, "routeCode": S(), "apiCode": S(), "apiVersion": S(), "from": ROUTE_STATE, "to": ROUTE_STATE,
        "exposure": S(enum=["INT", "EXT"]), "exposureChangedFrom": S(enum=["INT", "EXT"]), "reason": S(maxLength=500), "sunsetAt": TS, "occurredAt": TS, "actor": R("Actor")},
        ["tenantId", "routeCode", "to", "occurredAt"]),
  "ConsumerStateChanged": obj({"tenantId": TEN, "consumerCode": S(), "systemCode": S(), "change": S(enum=["CREATED", "UPDATED", "SUSPENDED", "RESUMED", "REMOVED"]),
        "state": S(enum=["ACTIVE", "SUSPENDED", "REMOVED"]), "authMethod": S(enum=["OAUTH2", "MTLS", "API_KEY"]), "reason": S(maxLength=500),
        "occurredAt": TS, "actor": R("Actor")}, ["tenantId", "consumerCode", "change", "state", "occurredAt"]),
  "WafExceptionChanged": obj({"tenantId": TEN, "exceptionId": S(format="uuid"), "routeCode": S(), "ruleId": S(pattern="^9[0-9]{5}$"),
        "change": S(enum=["REQUESTED", "APPROVED", "REJECTED", "REVOKED", "EXPIRED"]), "expiresAt": TS, "requestedBy": S(), "decidedBy": S(),
        "occurredAt": TS}, ["tenantId", "exceptionId", "routeCode", "ruleId", "change", "occurredAt"]),
  "WafExceptionExpiring": obj({"tenantId": TEN, "exceptionId": S(format="uuid"), "routeCode": S(), "ruleId": S(), "expiresAt": TS, "daysLeft": I, "requestedBy": S()},
        ["tenantId", "exceptionId", "routeCode", "ruleId", "expiresAt", "daysLeft"]),
  "QuotaThresholdReached": obj({"tenantId": TEN, "kind": S(enum=["CONSUMER_QUOTA", "TENANT_LIMIT"]), "consumerCode": S(), "routeCode": S(),
        "period": S(enum=["HOUR", "DAY", "MONTH", "SECOND"]), "percent": {"type": "integer", "enum": [80, 100], "description": "Ngưỡng đạt: 80% hoặc 100%."},
        "limit": I, "used": I, "resetAt": TS, "occurredAt": TS},
        ["tenantId", "kind", "percent", "limit", "used", "occurredAt"]),
  "CertificateExpiring": obj({"tenantId": TEN, "certCode": S(), "hosts": A(S()), "notAfter": TS, "daysLeft": I,
        "severity": S(enum=["HIGH", "CRITICAL"], description="`CRITICAL` khi còn dưới 7 ngày."), "autoRenew": B, "renewalState": S()},
        ["tenantId", "certCode", "hosts", "notAfter", "daysLeft", "severity"]),
  "SecurityAlertRaised": obj({"tenantId": TEN, "alertId": S(format="uuid"), "ruleCode": S(pattern="^GW-A(0[1-9]|1[0-3])$"),
        "severity": S(enum=["MEDIUM", "HIGH", "CRITICAL"]), "source": S(enum=["GATEWAY", "CONTROL_PLANE"]), "kind": S(description="Loại sự kiện chi tiết, ví dụ `IP_AUTO_BLOCK`, `CROSS_TENANT`, `WAF_AUTO_DEGRADE`, `VALKEY_DOWN`, `BREAKER_OPEN`, `EMERGENCY_SUSPEND`."),
        "routeCode": S(), "consumerCode": S(), "node": S(), "srcIp": S(description="Địa chỉ nguồn, chỉ cho SIEM; không có nội dung yêu cầu."),
        "count": I, "windowSeconds": I, "detail": S(maxLength=1000), "traceId": S(pattern="^[0-9a-f]{32}$"), "occurredAt": TS},
        ["tenantId", "alertId", "ruleCode", "severity", "source", "kind", "occurredAt"]),
  "TenantRedirectChanged": obj({"tenantId": TEN, "redirectId": S(format="uuid"), "fromTenant": TEN, "toTenant": TEN, "change": S(enum=["STARTED", "ENDED"]),
        "startAt": TS, "endAt": TS, "routeCount": I, "occurredAt": TS, "actor": R("Actor")},
        ["tenantId", "redirectId", "fromTenant", "toTenant", "change", "occurredAt"]),
  "LimitChanged": obj({"tenantId": TEN, "scope": S(enum=["TENANT", "CONSUMER_ROUTE", "ROUTE", "CONSUMER", "PARAM"]), "scopeKey": S(description="Mã đối tượng hoặc khóa tham số `gw.*`."),
        "before": {}, "after": {}, "changeRequestId": S(format="uuid"), "occurredAt": TS, "actor": R("Actor")},
        ["tenantId", "scope", "scopeKey", "after", "occurredAt"]),
  "SnapshotRejected": obj({"tenantId": TEN, "scope": TEN, "candidateVersion": I, "triggeredBy": S(enum=["AUTO", "MANUAL", "IMPORT", "RECONCILE"]),
        "findings": A(obj({"checkId": S(pattern="^CHK-[0-9]{2}$"), "severity": S(enum=["ERROR", "WARNING"]), "objectType": S(), "objectCode": S(), "message": S(maxLength=500)}, ["checkId", "severity", "message"])),
        "rejectedAt": TS}, ["tenantId", "scope", "triggeredBy", "findings", "rejectedAt"]),
}

CE_HEADERS = obj({"ce_specversion": S(const="1.0"), "ce_id": S(format="uuid", description="UUID v7, khóa lũy đẳng của người tiêu thụ."),
    "ce_source": S(const="/datahub/dh-connect/gateway", description="Theo CC-API-04: `/datahub/{du}/{module}`."),
    "ce_type": S(pattern="^vn\\.datahub\\.gateway\\.[a-z-]+\\.[a-z-]+\\.v1$", description="`vn.datahub.gateway.{thực-thể}.{sự-kiện}.v1`"), "ce_time": TS,
    "ce_subject": S(description="Mã đối tượng."), "ce_dhtenant": TEN, "ce_dataschema": S(format="uri", description="Lược đồ ở Apicurio."),
    "ce_datacontenttype": S(const="application/json"), "traceparent": S()},
    ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time", "ce_dhtenant"])
LOG_HEADERS = obj({"traceparent": S(), "ce_id": S(format="uuid")})

EXAMPLES = {
  "SnapshotPublished": {"tenantId": "T68", "snapshotVersion": 48213, "site": "dc1", "scope": "T68", "contentHash": "9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a",
      "signatureKeyId": "dh-gateway-snapshot:3", "trigger": "AUTO", "builtFrom": [{"source": "catalog", "cursor": "e-1204455"}], "routes": {"added": 2, "changed": 1, "removed": 0},
      "gitPending": False, "publishedAt": "2026-11-26T09:14:08+07:00", "actor": {"userId": "system:dh-connect", "type": "SYSTEM"}},
  "RouteStateChanged": {"tenantId": "T68", "routeCode": "tra-cuu-ho-tich.v1", "apiCode": "tra-cuu-ho-tich", "apiVersion": "v1", "from": "ACTIVE", "to": "STOPPED",
      "exposure": "INT", "reason": "Backend nâng cấp cơ sở dữ liệu", "occurredAt": "2026-11-26T10:02:11+07:00", "actor": {"userId": "an.nv", "type": "USER"}},
  "ConsumerStateChanged": {"tenantId": "T68", "consumerCode": "ht-qlvb", "systemCode": "HT-QLVB", "change": "CREATED", "state": "ACTIVE", "authMethod": "MTLS",
      "occurredAt": "2026-11-26T09:14:03+07:00", "actor": {"userId": "system:dh-connect", "type": "SYSTEM"}},
  "WafExceptionChanged": {"tenantId": "T68", "exceptionId": "0193a1f2-6c1e-7b3a-9d51-3a1f0c2b7e44", "routeCode": "tra-cuu-ho-tich.v1", "ruleId": "942100", "change": "APPROVED",
      "expiresAt": "2027-01-20T00:00:00+07:00", "requestedBy": "an.nv", "decidedBy": "tuan.lm", "occurredAt": "2026-11-26T11:20:00+07:00"},
  "QuotaThresholdReached": {"tenantId": "T68", "kind": "CONSUMER_QUOTA", "consumerCode": "ht-qlvb", "routeCode": "tra-cuu-ho-tich.v1", "period": "DAY", "percent": 80,
      "limit": 200000, "used": 160002, "resetAt": "2026-11-27T00:00:00+07:00", "occurredAt": "2026-11-26T15:41:09+07:00"},
  "SecurityAlertRaised": {"tenantId": "T68", "alertId": "0193a1f2-8a77-7c0d-8e22-5b9d6e1f4a10", "ruleCode": "GW-A03", "severity": "CRITICAL", "source": "GATEWAY", "kind": "CROSS_TENANT",
      "routeCode": "tra-cuu-ho-tich.v1", "consumerCode": "ht-qlvb", "node": "apisix-int-2", "srcIp": "10.20.30.40", "count": 1, "windowSeconds": 60,
      "detail": "Token của tenant T71 gọi route của tenant T68", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "occurredAt": "2026-11-26T14:03:55+07:00"},
  "SnapshotRejected": {"tenantId": "T68", "scope": "T68", "triggeredBy": "AUTO", "findings": [{"checkId": "CHK-02", "severity": "ERROR", "objectType": "ROUTE",
      "objectCode": "tra-cuu-ho-tich.v2", "message": "Route thiếu lược đồ OpenAPI đã duyệt."}], "rejectedAt": "2026-11-26T09:14:05+07:00"},
}
for _k, _v in EXAMPLES.items():
    SCHEMAS[_k]["examples"] = [_v]


def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, addr, payload, summ, days, parts, sender, kdesc, receivers in spec.EVENTS:
        ch = {"address": addr, "title": code, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
              "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
              "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3,
                  "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        channels[key] = ch
        cap = key[0].upper() + key[1:]
        ops[f"send{cap}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code}: {sender} phát",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{cap}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{receivers} nhận"}
        msgs[key] = {"name": key, "title": code, "summary": summ, "payload": R(payload),
            "headers": LOG_HEADERS if key == "securityAlertRaised" else CE_HEADERS,
            "bindings": {"kafka": {"key": S(description=kdesc)}}}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-03 Cổng API, sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-03-01…12 (D03-04-PH03 §4, FRS §9.3).\n\n"
          "Mọi sự kiện, trừ nhánh gateway của EVT-03-09, do `dh-connect` ghi vào `ph03_gateway.outbox` cùng giao dịch với thay đổi trạng thái; Debezium outbox đưa lên Kafka "
          "(ADR-042), CloudEvents 1.0 chế độ nhị phân, khóa phân vùng là mã đối tượng nên sự kiện của một đối tượng giữ thứ tự. "
          "EVT-03-09 do APISIX phát qua plugin `kafka-logger` (không giao dịch, giao ít nhất một lần) và do `dh-connect` phát khi tạm ngừng khẩn cấp. "
          "Không sự kiện nào mang bí mật, thân yêu cầu hay giá trị tiêu đề xác thực. Người nhận xử lý lũy đẳng theo `ce_id`. "
          "Tương thích BACKWARD ở Apicurio (ADR-070): chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`) hoặc `common`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}


if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-gateway.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH03 · AsyncAPI PH-03. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(len(spec.EVENTS), "sự kiện →", out)
