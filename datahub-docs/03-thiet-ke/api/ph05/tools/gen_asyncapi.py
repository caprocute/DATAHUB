#!/usr/bin/env python3
"""Sinh ph05/asyncapi-adapter.yaml (AsyncAPI 3.0) cho EVT-05-01…15 và hai topic nội bộ kiểm tra. Không sửa tay YAML."""
import os, yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
TS = S(format="date-time")
A = lambda it: {"type": "array", "items": it}
def obj(props, req=()):
    d = {"type": "object", "properties": props}
    if req: d["required"] = list(req)
    return d
ENV = S(enum=["TEST", "STAGING", "PROD"])
TEN = S(pattern="^(T[0-9]{2}|COMMON)$")

SCHEMAS = {
  "Actor": obj({"userId": S(), "type": S(enum=["USER", "SYSTEM"])}, ["userId", "type"]),
  "ConnRef": obj({"tenantId": TEN, "connectionCode": S(), "typeCode": S(), "configVersion": I}, ["tenantId", "connectionCode", "configVersion"]),
  "ConnectionEnabled": {"allOf": [R("ConnRef"), obj({"env": ENV, "secretVersion": I, "paramsHash": S(), "approvedBy": S(), "actor": R("Actor")}, ["env", "secretVersion"])]},
  "ConnectionChanged": {"allOf": [R("ConnRef"), obj({"env": ENV, "changedKeys": A(S()), "paramsHash": S(), "actor": R("Actor")}, ["env", "changedKeys"])]},
  "SecretRotated": {"allOf": [R("ConnRef"), obj({"env": ENV, "secretVersion": I, "fallbackVersion": {"type": ["integer", "null"]},
        "transitionUntil": TS, "phase": S(enum=["TRANSITION", "COMPLETED"])}, ["env", "secretVersion", "phase"])]},
  "ConnectionStateChanged": {"allOf": [R("ConnRef"), obj({"scope": S(enum=["CONNECTION", "ENVIRONMENT"]), "env": ENV,
        "from": S(), "to": S(enum=["ACTIVE", "SUSPENDED", "RETIRED", "DISABLED", "ENABLED"]), "reason": S(maxLength=1000), "actor": R("Actor")}, ["scope", "to"])]},
  "GrantChanged": {"allOf": [R("ConnRef"), obj({"grantId": S(format="uuid"), "change": S(enum=["GRANTED", "REVOKED", "EXPIRED"]),
        "scope": S(enum=["WORKSPACE", "FLOW"]), "targetCode": S(), "environments": A(ENV)}, ["grantId", "change", "scope", "targetCode"])]},
  "HealthChanged": obj({"tenantId": TEN, "kind": S(enum=["CONNECTION", "ADAPTER"]), "code": S(), "env": ENV,
        "from": S(enum=["HEALTHY", "DEGRADED", "UNHEALTHY", "UNKNOWN"]), "to": S(enum=["HEALTHY", "DEGRADED", "UNHEALTHY", "UNKNOWN"]),
        "reasonCode": S(), "reasonDetail": S(maxLength=1000), "evaluatedAt": TS,
        "metrics": obj({"calls5m": I, "errorRate5m": {"type": "number"}, "p95Ms": I, "poolWaitP95Ms": I})}, ["tenantId", "kind", "code", "env", "to"]),
  "AdapterVersionApproved": obj({"tenantId": TEN, "adapterCode": S(), "version": S(), "contentHash": S(), "maxConcurrency": I,
        "operations": A(obj({"operationCode": S(), "kameletName": S(), "yamlHash": S()}, ["operationCode", "kameletName"])),
        "supersededVersion": {"type": ["string", "null"]}, "actor": R("Actor")}, ["tenantId", "adapterCode", "version", "operations"]),
  "AdapterStateChanged": obj({"tenantId": TEN, "adapterCode": S(), "from": S(), "to": S(enum=["ACTIVE", "SUSPENDED", "RETIRED"]),
        "reason": S(maxLength=1000), "actor": R("Actor")}, ["tenantId", "adapterCode", "to"]),
  "KameletPublished": obj({"tenantId": TEN, "name": S(), "version": S(), "scope": S(enum=["BASE", "COMMON", "TENANT"]),
        "type": S(enum=["source", "sink", "action"]), "yamlHash": S(), "origin": S(enum=["EDITOR", "DESIGNER", "GENERATED", "PLATFORM"]),
        "runtimeProfiles": A(S()), "actor": R("Actor")}, ["tenantId", "name", "version", "yamlHash"]),
  "KameletLifecycleChanged": obj({"tenantId": TEN, "name": S(), "version": S(), "to": S(enum=["DEPRECATED", "WITHDRAWN"]),
        "reason": S(maxLength=1000), "affectedFlows": I, "actor": R("Actor")}, ["tenantId", "name", "version", "to"]),
  "CdcSchemaChanged": obj({"tenantId": TEN, "adapterCode": S(), "env": ENV, "changeId": S(format="uuid"), "table": S(),
        "changeKind": S(), "severity": S(enum=["COMPATIBLE", "BREAKING"]), "sourcePosition": S(), "cdcPaused": B, "detectedAt": TS},
        ["tenantId", "adapterCode", "changeId", "table", "severity"]),
  "CdcStateChanged": obj({"tenantId": TEN, "adapterCode": S(), "env": ENV, "from": S(),
        "to": S(enum=["STOPPED", "SNAPSHOTTING", "STREAMING", "PAUSED", "PAUSED_SCHEMA", "FAILED"]), "reason": S(maxLength=1000),
        "lastPosition": S(), "actor": R("Actor")}, ["tenantId", "adapterCode", "env", "to"]),
  "CdcChangeRecord": obj({
        "before": {"type": ["object", "null"]}, "after": {"type": ["object", "null"]},
        "source": obj({"connector": S(enum=["postgresql", "mysql", "oracle", "sqlserver"]), "db": S(), "schema": S(), "table": S(),
                       "ts_ms": I, "lsn": S(), "scn": S(), "gtid": S(), "snapshot": S()}, ["connector", "table", "ts_ms"]),
        "op": S(enum=["c", "u", "d", "r", "t"]), "ts_ms": I},
        ["op", "source", "ts_ms"]),
  "DbAccessRecorded": obj({"eventId": S(format="uuid"), "tenantId": TEN, "connectionCode": S(), "flowCode": S(), "flowVersion": I, "env": ENV,
        "dbUsername": S(), "statementHash": S(pattern="^[0-9a-f]{64}$"), "statementKind": S(enum=["SELECT", "INSERT", "UPDATE", "DELETE", "CALL"]),
        "rowCount": I, "durationMs": I, "outcome": S(enum=["OK", "DENIED", "ERROR"]), "traceId": S(pattern="^[0-9a-f]{32}$"), "occurredAt": TS},
        ["eventId", "tenantId", "flowCode", "statementHash", "statementKind", "outcome", "occurredAt"]),
  "FlowAccountChanged": obj({"tenantId": TEN, "accountId": S(format="uuid"), "connectionCode": S(), "flowCode": S(), "env": ENV,
        "accessMode": S(enum=["READ", "WRITE"]), "to": S(enum=["ISSUED", "REVOKED", "EXPIRED", "REJECTED"]), "openbaoRole": S(),
        "validUntil": S(format="date"), "actor": R("Actor")}, ["tenantId", "accountId", "flowCode", "env", "to"]),
  "ProbeCommand": obj({"testId": S(format="uuid"), "tenantId": TEN, "connectionCode": S(), "typeCode": S(), "env": ENV, "kind": S(enum=["MANUAL", "ROTATION", "PRIVILEGE", "CDC_PREREQ", "HEALTH"]),
        "secretVersion": I, "paramsHash": S(), "params": obj({}), "steps": A(S()), "deadline": TS},
        ["testId", "tenantId", "connectionCode", "env", "kind", "secretVersion", "deadline"]),
  "ProbeResult": obj({"testId": S(format="uuid"), "tenantId": TEN, "final": B,
        "step": obj({"name": S(), "status": S(enum=["PASSED", "FAILED", "SKIPPED", "TIMEOUT"]), "durationMs": I, "causeCode": S(), "hint": S()}),
        "status": S(enum=["PASSED", "FAILED"]), "latencyMs": I, "worker": S()}, ["testId", "tenantId", "final"]),
}

CE_HEADERS = obj({"ce_specversion": S(const="1.0"), "ce_id": S(format="uuid"), "ce_source": S(description="`/tenants/{tenant}/adapter`"),
    "ce_type": S(description="`vn.datahub.adapter.{đối tượng}.{sự kiện}.v1`"), "ce_time": TS, "ce_subject": S(description="Mã kết nối hoặc bộ điều hợp."),
    "ce_datacontenttype": S(const="application/json"), "traceparent": S()}, ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time"])

# key, mã, địa chỉ, payload, tóm tắt, ngày giữ, phân vùng, người phát, khóa, cleanup
EV = [
  ("connectionEnabled", "EVT-05-01", "{tenant}.adapter.connection.enabled.v1", "ConnectionEnabled", "Giá trị môi trường được bật (FR-05-007).", 7, 3, "dh-integration", "`{connectionCode}`"),
  ("connectionChanged", "EVT-05-02", "{tenant}.adapter.connection.changed.v1", "ConnectionChanged", "Tham số không bí mật đổi ở giá trị đang bật (FR-05-006).", 7, 3, "dh-integration", "`{connectionCode}`"),
  ("secretRotated", "EVT-05-03", "{tenant}.adapter.connection.secret-rotated.v1", "SecretRotated", "Bí mật mới có hiệu lực, hoặc kết thúc chuyển tiếp (FR-05-012). Không mang giá trị bí mật.", 7, 3, "dh-integration", "`{connectionCode}`"),
  ("connectionStateChanged", "EVT-05-04", "{tenant}.adapter.connection.state-changed.v1", "ConnectionStateChanged", "Tạm ngừng, tiếp tục, ngừng dùng kết nối; tắt môi trường (FR-05-007, 008).", 7, 3, "dh-integration", "`{connectionCode}`"),
  ("grantChanged", "EVT-05-05", "{tenant}.adapter.connection.grant-changed.v1", "GrantChanged", "Cấp, thu hồi, hết hạn cấp kết nối (FR-05-009).", 7, 3, "dh-integration", "`{connectionCode}`"),
  ("healthChanged", "EVT-05-06", "{tenant}.adapter.health.changed.v1", "HealthChanged", "Mức sức khỏe đổi sau chống dao động (FR-05-021).", 7, 3, "dh-integration", "`{kind}:{code}`"),
  ("adapterVersionApproved", "EVT-05-07", "{tenant}.adapter.adapter.version-approved.v1", "AdapterVersionApproved", "Phiên bản bộ điều hợp được duyệt, kèm Kamelet sinh (FR-05-044, 047).", 7, 3, "dh-integration", "`{adapterCode}`"),
  ("adapterStateChanged", "EVT-05-08", "{tenant}.adapter.adapter.state-changed.v1", "AdapterStateChanged", "Tạm dừng, tiếp tục, ngừng dùng bộ điều hợp.", 7, 3, "dh-integration", "`{adapterCode}`"),
  ("kameletPublished", "EVT-05-09", "{tenant}.adapter.kamelet.published.v1", "KameletPublished", "Kamelet được duyệt. Kamelet dùng chung phát ở `common.adapter.kamelet.published.v1` (tenant = `common`).", 7, 3, "dh-integration", "`{name}`"),
  ("kameletLifecycleChanged", "EVT-05-10", "{tenant}.adapter.kamelet.lifecycle-changed.v1", "KameletLifecycleChanged", "Ngừng khuyến nghị, thu hồi Kamelet (FR-05-058).", 7, 3, "dh-integration", "`{name}`"),
  ("cdcSchemaChanged", "EVT-05-11", "{tenant}.adapter.cdc.schema-changed.v1", "CdcSchemaChanged", "Phát hiện thay đổi lược đồ nguồn (FR-05-051).", 30, 3, "dh-integration", "`{adapterCode}`"),
  ("cdcStateChanged", "EVT-05-12", "{tenant}.adapter.cdc.state-changed.v1", "CdcStateChanged", "Trạng thái CDC đổi (FR-05-050).", 7, 3, "dh-integration", "`{adapterCode}`"),
  ("cdcChange", "EVT-05-13", "{tenant}.cdc.{adapterCode}.{schema}.{table}.v1", "CdcChangeRecord", "Bản ghi thay đổi Debezium (khung chuẩn, Avro qua Apicurio; lược đồ JSON tương đương ở đây). Topic do PH-10 đăng ký.", 7, 6, "Kafka Connect (Debezium)", "Khóa chính bảng nguồn"),
  ("dbAccessRecorded", "EVT-05-14", "{tenant}.adapter.db.access-recorded.v1", "DbAccessRecorded", "Mỗi câu lệnh CSDL của luồng (FR-05-027). Không có câu lệnh đầy đủ, chỉ băm.", 3, 6, "dh-runtime", "`{flowCode}`"),
  ("flowAccountChanged", "EVT-05-15", "{tenant}.adapter.flow-account.changed.v1", "FlowAccountChanged", "Cấp, thu hồi, hết hạn tài khoản CSDL cho luồng (FR-05-024, 028).", 7, 3, "dh-integration", "`{connectionCode}:{flowCode}`"),
  ("probeCommand", "nội bộ", "{tenant}.adapter.probe.command.v1", "ProbeCommand", "Lệnh kiểm tra, thăm dò gửi `probe-jvm` (SDD §4.4). Không có bí mật; worker tự đọc OpenBao.", 1, 3, "dh-integration", "`{connectionCode}`"),
  ("probeResult", "nội bộ", "{tenant}.adapter.probe.result.v1", "ProbeResult", "Kết quả từng bước và kết quả cuối.", 1, 3, "dh-runtime probe-jvm", "`{testId}`"),
]
RECEIVERS = {"connectionEnabled": "dh-runtime, PH-04", "connectionChanged": "dh-runtime", "secretRotated": "dh-runtime",
    "connectionStateChanged": "dh-runtime, PH-04, PH-13", "grantChanged": "PH-04", "healthChanged": "PH-04, PH-13",
    "adapterVersionApproved": "PH-04, dh-runtime", "adapterStateChanged": "dh-runtime, PH-04", "kameletPublished": "PH-04",
    "kameletLifecycleChanged": "PH-04, PH-13", "cdcSchemaChanged": "PH-10, PH-13", "cdcStateChanged": "PH-13",
    "cdcChange": "Luồng PH-04, PH-06", "dbAccessRecorded": "dh-integration, PH-13", "flowAccountChanged": "PH-04, PH-13",
    "probeCommand": "dh-runtime probe-jvm", "probeResult": "dh-integration"}

def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, addr, payload, summ, days, parts, sender, kdesc in EV:
        ch = {"address": addr, "title": code, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
              "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
              "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3,
                  "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        if key == "cdcChange":
            ch["parameters"].update({"adapterCode": {"description": "Mã bộ điều hợp CDC."}, "schema": {"description": "Schema nguồn, chữ thường."},
                                     "table": {"description": "Bảng nguồn, chữ thường."}})
        channels[key] = ch
        ops[f"send{key[0].upper()}{key[1:]}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — {sender} phát",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{key[0].upper()}{key[1:]}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{RECEIVERS[key]} nhận"}
        msgs[key] = {"name": key, "title": code, "summary": summ, "payload": R(payload),
            "headers": CE_HEADERS if sender == "dh-integration" else obj({"traceparent": S(), "ce_id": S(format="uuid")}),
            "bindings": {"kafka": {"key": S(description=kdesc)}}}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-05 Bộ điều hợp và kết nối — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-05-01…15 (D03-04-PH05 §4, FRS §8.2) và hai topic nội bộ của bộ chạy kiểm tra.\n\n"
          "EVT-05-01…12, 15 ghi vào `ph05_adapter.outbox` cùng giao dịch, Debezium đưa lên Kafka, CloudEvents 1.0 chế độ nhị phân. "
          "EVT-05-13 do Kafka Connect (Debezium) phát vào topic PH-10 đăng ký; EVT-05-14 do runtime phát trực tiếp. "
          "Không sự kiện nào mang giá trị bí mật (ràng buộc `ck_outbox_no_secret`, kiểm thử canary). "
          "Người nhận xử lý lũy đẳng theo `configVersion` hoặc `secretVersion`. Tương thích: chỉ thêm trường tùy chọn trong `v1`. "
          "Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`) hoặc `common`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}

if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-adapter.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH05 · AsyncAPI PH-05. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(EV)} kênh → {out}")
