#!/usr/bin/env python3
"""Sinh ph04/asyncapi-integration.yaml (AsyncAPI 3.0) cho EVT-04-01…14. Không sửa tay YAML."""
import os, yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
TS = S(format="date-time")
def obj(props, req=()):
    d = {"type": "object", "properties": props}
    if req: d["required"] = list(req)
    return d
ENV = S(enum=["TEST", "STAGING", "PROD"])

SCHEMAS = {
  "FlowRef": obj({"tenantId": S(pattern="^T[0-9]{2}$"), "flowId": S(format="uuid"), "flowCode": S(), "workspaceCode": S()}, ["tenantId", "flowId", "flowCode"]),
  "Actor": obj({"userId": S(), "type": S(enum=["USER", "SYSTEM"])}, ["userId", "type"]),
  "FlowCreated": {"allOf": [R("FlowRef"), obj({"name": S(), "resourceKind": S(enum=["ROUTE", "KAMELET", "PIPE", "TEST"]), "origin": S(), "transport": S(), "exposure": S(), "actor": R("Actor")}, ["name", "resourceKind"])]},
  "FlowUpdated": {"allOf": [R("FlowRef"), obj({"changedFields": {"type": "array", "items": S()}, "actor": R("Actor")}, ["changedFields"])]},
  "VersionEvent": {"allOf": [R("FlowRef"), obj({"versionNo": I, "contentHash": S(pattern="^sha256:[0-9a-f]{64}$"), "status": S(),
        "actor": R("Actor"), "changeNote": S(maxLength=2000), "comment": S(maxLength=4000), "nodeCommentCount": I,
        "contributors": {"type": "array", "items": S()}}, ["versionNo", "contentHash", "status"])]},
  "DeploymentRequested": {"allOf": [R("FlowRef"), obj({"deploymentId": S(format="uuid"), "versionNo": I, "environment": ENV,
        "kind": S(enum=["RELEASE", "PROMOTE", "ROLLBACK", "RETIRE"]), "contentHash": S(), "runtimeProfile": S(), "actor": R("Actor")}, ["deploymentId", "versionNo", "environment", "kind"])]},
  "DeploymentStatusChanged": {"allOf": [R("FlowRef"), obj({"deploymentId": S(format="uuid"), "versionNo": I, "environment": ENV,
        "from": S(), "to": S(enum=["PENDING", "SYNCING", "SYNCED", "OUT_OF_SYNC", "FAILED"]), "healthStatus": S(), "gitCommit": S(), "errorCode": S()}, ["deploymentId", "environment", "to"])]},
  "RuntimeStateChanged": {"allOf": [R("FlowRef"), obj({"environment": ENV, "commandId": S(format="uuid"), "action": S(enum=["PAUSE", "RESUME", "EMERGENCY_STOP"]),
        "routeIds": {"type": "array", "items": S()}, "state": S(enum=["RUNNING", "PAUSED", "STOPPED"]), "reason": S(maxLength=1000), "actor": R("Actor")}, ["environment", "action", "state"])]},
  "FlowRetired": {"allOf": [R("FlowRef"), obj({"reason": S(maxLength=1000), "actor": R("Actor")}, ["reason"])]},
  "TestRunCompleted": {"allOf": [R("FlowRef"), obj({"runId": S(format="uuid"), "versionNo": I, "definitionHash": S(), "mode": S(enum=["MOCK", "SANDBOX_LIVE", "SIMULATED"]),
        "status": S(enum=["PASSED", "FAILED", "TIMED_OUT", "CANCELLED"]), "testCaseId": {"type": ["string", "null"], "format": "uuid"}, "durationMs": I}, ["runId", "versionNo", "definitionHash", "status"])]},
  "RuntimeCommand": obj({
        "commandId": S(format="uuid"), "tenantId": S(pattern="^T[0-9]{2}$"), "environment": ENV, "flowCode": S(),
        "action": S(enum=["PAUSE", "RESUME", "EMERGENCY_STOP"]), "routeIds": {"type": "array", "items": S()}, "drain": B,
        "issuedBy": S(), "issuedAt": TS, "expiresAt": TS, "resendOf": {"type": ["string", "null"], "format": "uuid"},
        "keyId": S(description="Khóa OpenBao transit, ví dụ `dh-runtime-cmd:3`."),
        "signature": S(description="Ed25519 base64url trên JCS (RFC 8785) của toàn bộ trường trừ `signature`.")},
        ["commandId", "tenantId", "environment", "flowCode", "action", "issuedAt", "expiresAt", "keyId", "signature"]),
  "Heartbeat": obj({"replica": S(), "tenantId": S(), "environment": ENV, "profile": S(enum=["core-native", "files-native", "soap-jvm", "legacy-jvm"]),
        "catalogVersion": S(), "libVersion": S(), "sentAt": TS,
        "flows": {"type": "array", "items": obj({"flowCode": S(), "versionNo": I, "contentHash": S(), "loaded": B, "loadError": S(maxLength=1000),
            "localOverride": B, "routes": {"type": "array", "items": obj({"routeId": S(), "state": S(enum=["Started", "Suspended", "Stopped"]), "inflight": I}, ["routeId", "state"])}}, ["flowCode", "versionNo", "contentHash", "loaded"])}},
        ["replica", "tenantId", "environment", "sentAt", "flows"]),
  "CommandAck": obj({"commandId": S(format="uuid"), "replica": S(), "tenantId": S(), "environment": ENV, "result": S(enum=["APPLIED", "REJECTED"]),
        "reason": S(enum=["BAD_SIGNATURE", "EXPIRED", "TENANT_MISMATCH", "UNKNOWN_FLOW", "UNKNOWN_ROUTE", "DUPLICATE", "INTERNAL"]), "ackedAt": TS}, ["commandId", "replica", "result", "ackedAt"]),
  "ConnectionLog": obj({"tenantId": S(), "flowCode": S(), "versionNo": I, "routeId": S(), "environment": ENV, "traceId": S(pattern="^[0-9a-f]{32}$"),
        "messageId": S(), "sourceSystem": S(), "targetSystem": S(), "consumerClientId": S(), "operation": S(), "httpStatus": I,
        "outcome": S(enum=["SUCCESS", "BUSINESS_ERROR", "TECHNICAL_ERROR", "REJECTED"]), "errorCode": S(pattern="^ERR-04-1[0-9]{2}$"),
        "receivedAt": TS, "respondedAt": TS, "durationMs": I, "requestBytes": I, "responseBytes": I,
        "legalBasisRef": S(), "dataSubjectsCount": I, "maskedFields": {"type": "array", "items": S()}},
        ["tenantId", "flowCode", "traceId", "outcome", "receivedAt"]),
}

CE_HEADERS = obj({"ce_specversion": S(const="1.0"), "ce_id": S(format="uuid"), "ce_source": S(description="`/tenants/{tenant}/integration`"),
    "ce_type": S(), "ce_time": TS, "ce_subject": S(description="Mã luồng."), "ce_datacontenttype": S(const="application/json"),
    "traceparent": S()}, ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time"])

#  key, code, address, payload schema, summary, tenant?, retention days, partitions, cleanup, key desc
EV = [
  ("flowCreated", "EVT-04-01", "{tenant}.integration.flow.created.v1", "FlowCreated", "Tạo luồng (FR-04-003, FR-04-005).", True, 7, 6),
  ("flowUpdated", "EVT-04-02", "{tenant}.integration.flow.updated.v1", "FlowUpdated", "Sửa thông tin luồng (FR-04-004).", True, 7, 6),
  ("versionSubmitted", "EVT-04-03", "{tenant}.integration.version.submitted.v1", "VersionEvent", "Gửi duyệt (FR-04-040).", True, 7, 6),
  ("versionApproved", "EVT-04-04", "{tenant}.integration.version.approved.v1", "VersionEvent", "Duyệt (FR-04-041).", True, 7, 6),
  ("versionChangesRequested", "EVT-04-05", "{tenant}.integration.version.changes-requested.v1", "VersionEvent", "Yêu cầu sửa (FR-04-041).", True, 7, 6),
  ("deploymentRequested", "EVT-04-06", "{tenant}.integration.deployment.requested.v1", "DeploymentRequested", "Yêu cầu phát hành, nâng, quay lui, gỡ (FR-04-042, 044, 045, 006).", True, 7, 6),
  ("deploymentStatusChanged", "EVT-04-07", "{tenant}.integration.deployment.status-changed.v1", "DeploymentStatusChanged", "Trạng thái triển khai đổi.", True, 7, 6),
  ("flowRuntimeStateChanged", "EVT-04-08", "{tenant}.integration.flow.runtime-state-changed.v1", "RuntimeStateChanged", "Tạm dừng, tiếp tục, dừng khẩn đã được xác nhận (FR-04-050).", True, 7, 6),
  ("flowRetired", "EVT-04-09", "{tenant}.integration.flow.retired.v1", "FlowRetired", "Luồng đã gỡ (FR-04-006).", True, 7, 6),
  ("testRunCompleted", "EVT-04-10", "{tenant}.integration.testrun.completed.v1", "TestRunCompleted", "Lần chạy thử kết thúc (FR-04-030).", True, 7, 6),
  ("runtimeCommand", "EVT-04-11", "dh.integration.runtime.command.v1", "RuntimeCommand", "Lệnh điều khiển runtime có ký (ADR-065). Không qua outbox: dh-integration ghi trực tiếp sau khi lưu runtime_command.", False, 1, 12),
  ("runtimeHeartbeat", "EVT-04-12", "dh.integration.runtime.heartbeat.v1", "Heartbeat", "Nhịp tim mỗi 30 giây của bản sao runtime.", False, 1, 12),
  ("runtimeCommandAck", "EVT-04-13", "dh.integration.runtime.command-ack.v1", "CommandAck", "Xác nhận lệnh của từng bản sao.", False, 1, 12),
  ("connectionLog", "EVT-04-14", "{tenant}.audit.connection-log.v1", "ConnectionLog", "Nhật ký kết nối từ chặng audit (BR-04-002). Chủ quản topic: PH-13; giữ online 12 tháng, WORM 5 năm ở PH-13.", True, 30, 12),
]
KEYDESC = {"runtimeCommand": "`{tenant}:{environment}`", "runtimeHeartbeat": "`{replica}`", "runtimeCommandAck": "`{commandId}`", "connectionLog": "`{tenant}:{flowCode}`"}

def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, addr, payload, summ, ten, days, parts in EV:
        ch = {"address": addr, "title": code, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
              "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3,
                  "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        if ten: ch["parameters"] = {"tenant": {"$ref": "#/components/parameters/tenant"}}
        channels[key] = ch
        sender = "dh-runtime" if key in ("runtimeHeartbeat", "runtimeCommandAck", "connectionLog") else "dh-integration"
        ops[f"publish{key[0].upper()}{key[1:]}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — {sender} phát",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        msgs[key] = {"name": key, "title": code, "summary": summ, "payload": R(payload),
            "headers": CE_HEADERS if ten and key != "connectionLog" else obj({"traceparent": S(), "ce_id": S(format="uuid")}),
            "bindings": {"kafka": {"key": S(description=KEYDESC.get(key, "`{tenant}:{flowId}` để giữ thứ tự theo luồng."))}}}
    # consumer
    for key, who in [("runtimeCommand", "dh-runtime"), ("runtimeHeartbeat", "dh-integration"), ("runtimeCommandAck", "dh-integration"), ("testRunCompleted", "PH-18 thông báo")]:
        ops[f"receive{key[0].upper()}{key[1:]}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{who} nhận"}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-04 Lõi tích hợp — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-04-01…14 (D03-04-PH04 §4, FRS §8.2).\n\n"
          "EVT-04-01…10 ghi vào outbox `ph04.outbox` trong cùng giao dịch, Debezium đưa lên Kafka, CloudEvents 1.0 chế độ nhị phân (tiêu đề `ce_*`). "
          "EVT-04-11…13 là topic hệ thống `dh.*`, chỉ `dh-integration` và `dh-runtime` có ACL; EVT-04-11 có chữ ký Ed25519 và hạn 60 giây. "
          "EVT-04-14 do runtime phát, PH-13 sở hữu. Sự kiện không mang định nghĩa luồng hay thân bản tin. "
          "Tương thích: chỉ thêm trường tùy chọn trong `v1`; thay đổi phá vỡ sang `v2`, phát song song ≥ 6 tháng (Apicurio BACKWARD). "
          "Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường, ví dụ `t68`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}

if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-integration.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH04 · AsyncAPI PH-04. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(EV)} kênh → {out}")
