#!/usr/bin/env python3
"""Sinh ph13/asyncapi-giam-sat-kiem-toan.yaml (AsyncAPI 3.0) cho EVT-13-01…14 và hai topic vào. Không sửa tay YAML."""
import os, yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
N = {"type": "number"}
B = {"type": "boolean"}
TS = S(format="date-time")
UUID = S(format="uuid")
A = lambda it, **kw: {"type": "array", "items": it, **kw}
def obj(props, req=(), **kw):
    d = {"type": "object", "properties": props}
    if req: d["required"] = list(req)
    d.update(kw); return d
TEN = S(pattern="^(T[0-9]{2}|COMMON|PLATFORM)$")
SEV = S(enum=["CRITICAL", "WARNING", "INFO"])
TRACE = S(pattern="^[0-9a-f]{32}$")
HASH = S(pattern="^[0-9a-f]{64}$")
ACTOR = obj({"userId": S(), "type": S(enum=["USER", "CLIENT", "SYSTEM"])}, ["userId", "type"])

SCHEMAS = {
  "Actor": ACTOR,
  "AlertFired": obj({"tenantId": TEN, "alertId": UUID, "ruleCode": S(), "name": S(), "severity": SEV, "summary": S(maxLength=1000), "labels": {"type": "object", "additionalProperties": S()},
      "groupKey": S(), "runbookCode": S(), "startedAt": TS}, ["tenantId", "alertId", "ruleCode", "severity", "startedAt"],
      examples=[{"tenantId": "T68", "alertId": "0192f3b0-2222-7000-8000-000000000002", "ruleCode": "api-loi-5xx-qlvb", "name": "Tỷ lệ lỗi 5xx của API QLVB vượt 2%", "severity": "CRITICAL",
                 "summary": "Tỷ lệ lỗi 5xx của API QLVB 3,4%", "labels": {"system": "QLVB"}, "groupKey": "system=QLVB", "runbookCode": "rb-api-loi-5xx", "startedAt": "2026-11-26T03:10:00Z"}]),
  "AlertResolved": obj({"tenantId": TEN, "alertId": UUID, "ruleCode": S(), "severity": SEV, "resolution": S(enum=["MANUAL", "AUTO"]), "cause": S(maxLength=1000), "measure": S(maxLength=1000),
      "startedAt": TS, "endedAt": TS, "actor": ACTOR}, ["tenantId", "alertId", "ruleCode", "resolution", "endedAt"]),
  "AlertEscalated": obj({"tenantId": TEN, "alertId": UUID, "ruleCode": S(), "severity": SEV, "fromLevel": I, "toLevel": I, "recipients": A(S()), "escalatedAt": TS,
      "exhausted": B}, ["tenantId", "alertId", "toLevel", "escalatedAt"]),
  "SecurityAlertRaised": obj({"tenantId": TEN, "alertId": UUID, "ruleCode": S(pattern="^UC-SEC-[0-9]{2}$"), "severity": SEV, "subject": S(), "kind": S(enum=["ALERT", "SUSPENSION_PROPOSAL"]),
      "systemCode": S(), "proposedBy": S(), "detectedAt": TS}, ["tenantId", "alertId", "ruleCode", "severity", "kind", "detectedAt"],
      description="Không mang bằng chứng; người nhận đọc chi tiết qua API-13-057."),
  "ChainBroken": obj({"tenantId": TEN, "kind": S(enum=["CHAIN_BREAK", "ANCHOR_MISMATCH"]), "seq": I, "anchorId": UUID, "verificationId": UUID, "detectedAt": TS},
      ["tenantId", "kind", "detectedAt"]),
  "AnchorCreated": obj({"tenantId": TEN, "anchorId": UUID, "kind": S(enum=["HOURLY", "BOUNDARY", "FINAL"]), "seqLast": I, "hashLast": HASH, "keyVersion": I, "signature": S(), "anchoredAt": TS},
      ["tenantId", "anchorId", "seqLast", "hashLast", "keyVersion", "signature", "anchoredAt"]),
  "VerificationCompleted": obj({"tenantId": TEN, "verificationId": UUID, "scope": S(enum=["DAILY", "ON_DEMAND", "INCREMENTAL"]), "status": S(enum=["PASSED", "FAILED"]),
      "firstBreakSeq": {"type": ["integer", "null"]}, "checkedCount": I, "requestedBy": S(), "finishedAt": TS}, ["tenantId", "verificationId", "scope", "status", "finishedAt"]),
  "ExportReady": obj({"tenantId": TEN, "exportId": UUID, "requestedBy": S(), "recordCount": I, "expiresAt": TS, "readyAt": TS}, ["tenantId", "exportId", "requestedBy", "expiresAt"]),
  "ReconciliationMismatch": obj({"tenantId": TEN, "duCode": S(), "day": S(format="date"), "emitted": I, "received": I, "diff": I, "checkedAt": TS},
      ["tenantId", "duCode", "day", "emitted", "received", "diff"]),
  "RuleChanged": obj({"tenantId": TEN, "ruleCode": S(), "ruleKind": S(enum=["ALERT", "DETECTION", "PLATFORM", "SETTINGS"]), "change": S(enum=["CREATED", "UPDATED", "DISABLED", "ENABLED", "RETIRED"]),
      "version": I, "actor": ACTOR, "changedAt": TS}, ["tenantId", "ruleCode", "ruleKind", "change", "version"]),
  "PartitionArchived": obj({"tenantId": S(description="`PLATFORM` khi phân vùng chung."), "month": S(pattern="^[0-9]{4}-[0-9]{2}$"), "recordCount": I, "wormVerifiedAt": TS, "archivedAt": TS},
      ["month", "recordCount", "archivedAt"]),
  "CrossTenantAccess": obj({"tenantId": TEN, "sessionId": UUID, "actorId": S(), "actorHomeTenant": TEN, "reason": S(maxLength=500), "openedAt": TS, "expiresAt": TS},
      ["tenantId", "sessionId", "actorId", "actorHomeTenant", "reason", "openedAt", "expiresAt"], description="`tenantId` là tenant bị truy cập."),
  "ProbeFailed": obj({"tenantId": TEN, "probeCode": S(), "targetApi": S(), "consecutiveFailures": I, "lastStatus": I, "lastError": S(maxLength=500), "failedAt": TS},
      ["tenantId", "probeCode", "consecutiveFailures", "failedAt"]),
  "CapacityWarning": obj({"tenantId": TEN, "resource": S(enum=["ACTIVE_SERIES", "LOKI", "CLICKHOUSE", "AUDIT_DB", "WORM", "SIEM_QUEUE"]), "usedPercent": N, "limit": N, "threshold": N, "at": TS},
      ["tenantId", "resource", "usedPercent", "at"]),
  # ---- vào
  "AuditEventV1": obj({"id": UUID, "tenantId": TEN, "occurredAt": TS, "actorType": S(enum=["USER", "CLIENT", "SYSTEM"]), "actorId": S(), "actorName": S(), "actorHomeTenant": TEN,
      "sourceIp": S(), "userAgent": S(), "sessionHash": S(), "action": S(pattern="^[A-Z][A-Z0-9_]*(\\.[A-Z0-9_]+)+$"), "objectType": S(), "objectId": S(), "objectKeyHmac": S(),
      "before": {"type": ["object", "null"]}, "after": {"type": ["object", "null"]}, "outcome": S(enum=["SUCCESS", "DENIED", "FAILED"]), "errorCode": S(), "reason": S(maxLength=500),
      "purpose": S(), "traceId": TRACE}, ["id", "tenantId", "occurredAt", "actorType", "actorId", "action", "objectType", "objectId", "outcome", "traceId"],
      description="Lược đồ `audit-event.v1` (D03-02-PH13 §4.2); `before`, `after` ≤ 64 KB, đã che giá trị Nhạy cảm.",
      examples=[{"id": "0192f3a4-7b1c-7d2e-9a10-5c3e8f1b2a44", "tenantId": "T68", "occurredAt": "2026-11-26T03:15:00Z", "actorType": "USER", "actorId": "u-an.nv", "actorName": "Nguyễn Văn An",
                 "action": "CATALOG.PUBLISH", "objectType": "catalog", "objectId": "DM_GIOI_TINH", "outcome": "SUCCESS", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}]),
  "AccessLogged": obj({"ts": TS, "tenantId": TEN, "route": S(), "apiCode": S(), "method": S(), "status": I, "latencyMs": I, "gatewayLatencyMs": I, "systemCode": S(), "clientId": S(),
      "bytesIn": I, "bytesOut": I, "traceId": TRACE, "node": S()}, ["ts", "tenantId", "route", "method", "status", "latencyMs"],
      description="Chỉ siêu dữ liệu: không `Authorization`, không chuỗi truy vấn, không thân (BR-13-015).",
      examples=[{"ts": "2026-11-26T03:15:02Z", "tenantId": "T68", "route": "qlvb-van-ban-get", "apiCode": "qlvb-van-ban", "method": "GET", "status": 200, "latencyMs": 84, "gatewayLatencyMs": 6,
                 "systemCode": "QLVB", "clientId": "cli-so-tttt", "bytesIn": 0, "bytesOut": 2048, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "node": "apisix-int-1"}]),
}

CE = obj({"ce_specversion": S(const="1.0"), "ce_id": UUID, "ce_source": S(description="`/tenants/{tenant}/obs`"), "ce_type": S(description="`vn.datahub.obs.{đối tượng}.{sự kiện}.v1`"),
          "ce_time": TS, "ce_subject": S(description="Mã đối tượng, trùng khóa phân vùng."), "ce_datacontenttype": S(const="application/json"), "traceparent": S()},
         ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time"])
AUDIT_HDR = obj({"dh-du": S(description="DU nguồn, ví dụ `dh-data`."), "dh-kid": S(description="Mã phiên bản khóa nguồn."),
                 "dh-mac": S(description="HMAC-SHA256(khóa nguồn của DU, tenant ‖ id ‖ SHA-256(payload)), base64."), "traceparent": S()}, ["dh-du", "dh-kid", "dh-mac"])

# key, mã, địa chỉ, payload, tóm tắt, ngày giữ, phân vùng, khóa, người nhận, FR
EV = [
  ("alertFired", "EVT-13-01", "{tenant}.obs.alert.fired.v1", "AlertFired", "Cảnh báo sang `FIRING` (FR-13-044).", 7, 3, "`alertId`", "PH-18, trung tâm thông báo"),
  ("alertResolved", "EVT-13-02", "{tenant}.obs.alert.resolved.v1", "AlertResolved", "Cảnh báo sang `RESOLVED`, tự động hoặc thủ công (FR-13-044, 047).", 7, 3, "`alertId`", "PH-18, trung tâm thông báo"),
  ("alertEscalated", "EVT-13-03", "{tenant}.obs.alert.escalated.v1", "AlertEscalated", "Cảnh báo leo thang lên cấp mới hoặc hết cấp (FR-13-046).", 7, 3, "`alertId`", "PH-18"),
  ("securityAlertRaised", "EVT-13-04", "{tenant}.obs.security-alert.raised.v1", "SecurityAlertRaised", "Cảnh báo an ninh phát hiện (FR-13-052); đề xuất tạm ngừng HTTT đi bằng API-01-089 của PH-01, không qua topic này (FR-13-053).", 30, 3, "`alertId`", "PH-18, bộ xuất SIEM"),
  ("chainBroken", "EVT-13-05", "{tenant}.obs.audit.chain-broken.v1", "ChainBroken", "Phát hiện đứt chuỗi kiểm toán hoặc neo không khớp (FR-13-015).", 30, 3, "`tenantId`", "PH-18, bộ xuất SIEM"),
  ("anchorCreated", "EVT-13-06", "{tenant}.obs.audit.anchor-created.v1", "AnchorCreated", "Neo băm mới được ký (FR-13-012).", 7, 3, "`anchorId`", "Bộ xuất SIEM"),
  ("verificationCompleted", "EVT-13-07", "{tenant}.obs.audit.verification-completed.v1", "VerificationCompleted", "Kiểm tra toàn vẹn xong (FR-13-014).", 7, 3, "`verificationId`", "PH-18, UI-13-14"),
  ("exportReady", "EVT-13-08", "{tenant}.obs.audit.export-ready.v1", "ExportReady", "Gói bằng chứng sẵn sàng tải (FR-13-024).", 7, 3, "`exportId`", "Trung tâm thông báo của người yêu cầu"),
  ("reconciliationMismatch", "EVT-13-09", "{tenant}.obs.audit.reconciliation-mismatch.v1", "ReconciliationMismatch", "Đối chiếu số bản ghi theo DU lệch (FR-13-017).", 7, 3, "`duCode`", "PH-18, DU nguồn"),
  ("ruleChanged", "EVT-13-10", "{tenant}.obs.rule.changed.v1", "RuleChanged", "Luật cảnh báo, luật phát hiện, luật chuẩn hoặc tham số đổi (FR-13-042, 043, 051, 061).", 7, 3, "`ruleCode`", "Module `observability` (nạp Ruler), PH-18"),
  ("partitionArchived", "EVT-13-11", "{tenant}.obs.audit.partition-archived.v1", "PartitionArchived", "Phân vùng kiểm toán được lưu trữ (FR-13-018).", 7, 3, "`month`", "PH-18"),
  ("crossTenantAccess", "EVT-13-12", "{tenant}.obs.audit.cross-tenant-access.v1", "CrossTenantAccess", "Mở phiên truy cập liên tenant (FR-13-025). Phát vào tenant bị truy cập.", 30, 3, "`sessionId`", "Trung tâm thông báo của quản trị tỉnh bị truy cập, bộ xuất SIEM"),
  ("probeFailed", "EVT-13-13", "{tenant}.obs.probe.failed.v1", "ProbeFailed", "Kiểm tra tổng hợp thất bại liên tiếp (FR-13-008).", 7, 3, "`probeCode`", "PH-18"),
  ("capacityWarning", "EVT-13-14", "{tenant}.obs.capacity.warning.v1", "CapacityWarning", "Số chuỗi hoặc dung lượng kho đạt 85% (FR-13-007, 061).", 7, 3, "`resource`", "PH-20, PH-18"),
]
IN = [  # key, tiêu đề, địa chỉ, payload, tóm tắt, ngày, phân vùng, khóa, người phát, tiêu đề
  ("auditRecorded", "Topic vào: audit.recorded", "{tenant}.obs.audit.recorded.v1", "AuditEventV1", "Bản ghi kiểm toán từ `dh-audit` của mọi DU (FR-13-010). Tenant `PLATFORM` dùng `platform.obs.audit.recorded.v1`.", 7, 6, "`id` (UUID v7)", "`dh-audit` của DU nguồn", AUDIT_HDR),
  ("accessLogged", "Topic vào: access.logged", "{tenant}.obs.access.logged.v1", "AccessLogged", "Siêu dữ liệu lượt gọi từ plugin `kafka-logger` của APISIX (FR-13-006).", 3, 6, "`route`", "APISIX (PH-03)", obj({"traceparent": S()})),
]

def build():
    channels, ops, msgs = {}, {}, {}
    def add(key, title, addr, payload, summ, days, parts, kdesc, sender, recv, headers, code):
        channels[key] = {"address": addr, "title": title, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
            "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
            "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3, "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        cap = key[0].upper() + key[1:]
        ops[f"send{cap}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — {sender} phát", "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{cap}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{recv} nhận"}
        msgs[key] = {"name": key, "title": title, "summary": summ, "payload": R(payload), "headers": headers, "bindings": {"kafka": {"key": S(description=kdesc)}}}
    for key, code, addr, payload, summ, days, parts, kdesc, recv in EV:
        add(key, code, addr, payload, summ, days, parts, kdesc, "`dh-platform` (outbox)", recv, CE, code)
    for key, title, addr, payload, summ, days, parts, kdesc, sender, hdr in IN:
        add(key, title, addr, payload, summ, days, parts, kdesc, sender, "`dh-platform` (module `audit`)" if key == "auditRecorded" else "ClickHouse (bảng động cơ Kafka)", hdr, title)
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-13 Giám sát và kiểm toán — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-13-01…14 (D03-04-PH13 §4, FRS §9.3) và hai topic vào của PH-13.\n\n"
          "Sự kiện EVT-13 ghi vào `outbox` của `dh-platform` cùng giao dịch với thay đổi, Debezium đưa lên Kafka, CloudEvents 1.0 chế độ nhị phân. "
          "Tenant `PLATFORM` dùng tiền tố `platform`. Không sự kiện nào mang bằng chứng kiểm toán, giá trị Nhạy cảm hay bí mật; người nhận đọc chi tiết qua API. "
          "Người nhận xử lý lũy đẳng theo khóa phân vùng và thời điểm. Hai topic vào do DU và APISIX phát: `audit.recorded` mang chữ ký nguồn (`dh-du`, `dh-kid`, `dh-mac`) "
          "và PH-13 gán `seq`, `hash` khi ghi chuỗi; `access.logged` chỉ có siêu dữ liệu lượt gọi. Tương thích: chỉ thêm trường tùy chọn trong `v1` (Apicurio, BACKWARD). "
          "Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant (ADR-072).", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`) hoặc `platform`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}

if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-giam-sat-kiem-toan.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH13 · AsyncAPI PH-13. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(EV)} sự kiện + {len(IN)} topic vào → {out}")
