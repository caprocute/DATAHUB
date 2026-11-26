#!/usr/bin/env python3
"""Sinh ph10/asyncapi-event.yaml (AsyncAPI 3.0).

Gồm: EVT-10-01…16 (sự kiện của PH-10, CloudEvents 1.0 nhị phân trên Kafka); kênh giao ĐẨY webhook ký HMAC (ADR-044, ADR-071)
ở hai dạng CloudEvents có cấu trúc và nhị phân, kèm bắt tay xác minh; kênh mẫu topic nghiệp vụ `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}`
và topic DLQ `{topicName}.dlq`. Tên trường, enum theo Phụ lục A của FRS. Không sửa tay YAML.
"""
import os, yaml, copy
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
L = {"type": "integer", "format": "int64", "minimum": 0}
B = {"type": "boolean"}
TS = S(format="date-time")
NTS = {"type": ["string", "null"], "format": "date-time"}
A = lambda it, **kw: {"type": "array", "items": it, **kw}
E = lambda *v: S(enum=list(v))
def obj(props, req=()):
    d = {"type": "object", "properties": props, "additionalProperties": False}
    if req: d["required"] = list(req)
    return d

TOPIC = "t68.dkkd.doanh-nghiep.da-cap-phep.v1"
TEN = S(pattern="^(T[0-9]{2}|COMMON)$")
TOPICNAME = S(maxLength=204, pattern="^(t[0-9]{2}|dh)\\.[a-z][a-z0-9-]*(\\.[a-z][a-z0-9-]*){2,4}\\.v[1-9][0-9]*(\\.dlq)?$")
SUBSTATUS = E("PENDING_APPROVAL", "REJECTED", "PROVISIONING", "FAILED", "ACTIVE", "PAUSED", "SUSPENDED", "REVOKED")
PUBSTATUS = E("PENDING_APPROVAL", "REJECTED", "ACTIVE", "SUSPENDED", "REVOKED")
SUSP = {"type": ["string", "null"], "enum": ["MANUAL", "SECURITY", "PH01", "CIRCUIT_BREAKER", "DELIVERY_BLOCKED", None]}
ALERT = E("OK", "WARNING", "CRITICAL", "STALLED")
BRIDGE = E("PENDING_APPROVAL", "REJECTED", "RUNNING", "STOPPED", "ERROR", "EXPIRED")

SCHEMAS = {
  "TopicActivated": obj({"tenantId": TEN, "topicName": TOPICNAME, "projectCode": {"type": ["string", "null"]}, "topicKind": E("BUSINESS", "CDC", "SYSTEM", "DLQ"),
      "partitions": I, "retentionHours": I, "routingMode": E("KEY_HASH", "ROUND_ROBIN", "SINGLE_PARTITION"), "partitionKeyField": {"type": ["string", "null"]},
      "orderingRequired": B, "dataClass": E("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE"), "latestSchemaVersion": I, "activatedAt": TS,
      "ownerServiceCode": {"type": ["string", "null"]}, "configVersion": I},
      ["tenantId", "topicName", "topicKind", "partitions", "routingMode", "dataClass", "activatedAt", "configVersion"]),
  "TopicChanged": obj({"tenantId": TEN, "topicName": TOPICNAME, "changedFields": A(S(), minItems=1), "partitions": I, "retentionHours": I,
      "cleanupPolicy": E("DELETE", "COMPACT", "COMPACT_DELETE"), "maxMessageBytes": I,
      "compatibility": E("BACKWARD", "BACKWARD_TRANSITIVE", "FORWARD", "FORWARD_TRANSITIVE", "FULL", "FULL_TRANSITIVE", "NONE"),
      "enabledVersions": A(I), "configVersion": I}, ["tenantId", "topicName", "changedFields", "configVersion"]),
  "TopicDeprecated": obj({"tenantId": TEN, "topicName": TOPICNAME, "successorTopic": {"type": ["string", "null"]}, "sunsetAt": TS,
      "migrationNote": {"type": ["string", "null"], "maxLength": 2000}, "configVersion": I}, ["tenantId", "topicName", "sunsetAt", "configVersion"]),
  "TopicRetired": obj({"tenantId": TEN, "topicName": TOPICNAME, "retiredAt": TS, "configVersion": I}, ["tenantId", "topicName", "retiredAt", "configVersion"]),
  "SchemaVersionEnabled": obj({"tenantId": TEN, "topicName": TOPICNAME, "versionNo": I, "schemaFormat": E("AVRO", "JSON_SCHEMA"),
      "compatibility": E("BACKWARD", "BACKWARD_TRANSITIVE", "FORWARD", "FORWARD_TRANSITIVE", "FULL", "FULL_TRANSITIVE", "NONE"),
      "apicurioGroupId": S(), "apicurioArtifactId": TOPICNAME, "apicurioGlobalId": L, "apicurioContentId": L, "contentHash": S(pattern="^[0-9a-f]{64}$"),
      "enabledAt": TS}, ["tenantId", "topicName", "versionNo", "apicurioGlobalId", "apicurioContentId", "contentHash", "enabledAt"]),
  "PublicationActivated": obj({"tenantId": TEN, "publicationCode": S(pattern="^pub-[0-9a-hjkmnp-tv-z]{26}$"), "publisherCode": S(), "topicName": TOPICNAME,
      "grantedScope": S(), "approvedBy": S(), "approvedAt": TS}, ["tenantId", "publicationCode", "publisherCode", "topicName", "grantedScope"]),
  "PublicationStateChanged": obj({"tenantId": TEN, "publicationCode": S(), "publisherCode": S(), "topicName": TOPICNAME, "previousStatus": PUBSTATUS,
      "status": PUBSTATUS, "suspendSource": SUSP, "reason": {"type": ["string", "null"], "maxLength": 1000}},
      ["tenantId", "publicationCode", "topicName", "status"]),
  "SubscriptionActivated": obj({"tenantId": TEN, "subscriptionCode": S(), "subscriberCode": S(), "topicName": TOPICNAME,
      "deliveryMode": E("PUSH", "PULL_API", "PULL_KAFKA", "INTERNAL"), "consumerGroup": S(), "startPosition": E("LATEST", "EARLIEST", "TIMESTAMP"),
      "configVersion": I}, ["tenantId", "subscriptionCode", "subscriberCode", "topicName", "deliveryMode", "consumerGroup", "configVersion"]),
  "SubscriptionStateChanged": obj({"tenantId": TEN, "subscriptionCode": S(), "topicName": TOPICNAME, "previousStatus": SUBSTATUS, "status": SUBSTATUS,
      "suspendSource": SUSP, "suspendReason": {"type": ["string", "null"], "maxLength": 1000}, "changedFields": A(S()), "configVersion": I},
      ["tenantId", "subscriptionCode", "topicName", "status", "configVersion"]),
  "LagAlerted": obj({"tenantId": TEN, "subscriptionCode": S(), "topicName": TOPICNAME, "consumerGroup": S(), "previousAlertState": ALERT, "alertState": ALERT,
      "lagRecords": L, "lagSeconds": I, "sampledAt": TS}, ["tenantId", "subscriptionCode", "alertState", "lagRecords", "lagSeconds", "sampledAt"]),
  "DeadLettered": obj({"tenantId": TEN, "subscriptionCode": {"type": ["string", "null"]}, "bridgeCode": {"type": ["string", "null"]}, "sourceTopic": TOPICNAME,
      "newEntryCount": {"type": "integer", "minimum": 1}, "errorCodes": A(S(pattern="^ERR-10-1[0-9]{2}$")), "firstFailedAt": TS, "lastFailedAt": TS,
      "origin": E("PUSH", "PULL_NACK", "EXTERNAL_REPORT", "REPLAY", "BRIDGE")},
      ["tenantId", "sourceTopic", "newEntryCount", "errorCodes", "firstFailedAt", "lastFailedAt"]),
  "ReplayCompleted": obj({"tenantId": TEN, "replayCode": S(pattern="^rpl-[0-9a-hjkmnp-tv-z]{26}$"), "subscriptionCode": S(),
      "replayMode": E("REDELIVER_RANGE", "RESET_OFFSET", "DLQ_ENTRIES"), "status": E("COMPLETED", "FAILED", "CANCELLED"),
      "estimatedRecords": {"type": ["integer", "null"]}, "deliveredRecords": L, "failedRecords": L, "startedAt": NTS, "finishedAt": TS},
      ["tenantId", "replayCode", "subscriptionCode", "replayMode", "status", "deliveredRecords", "failedRecords", "finishedAt"]),
  "SigningKeyRotated": obj({"tenantId": TEN, "subscriptionCode": S(), "keyId": S(), "status": E("ACTIVE", "PREVIOUS", "REVOKED"),
      "previousKeyId": {"type": ["string", "null"]}, "previousUntil": NTS, "revokedAt": NTS},
      ["tenantId", "subscriptionCode", "keyId", "status"]),
  "ComplianceViolated": obj({"tenantId": TEN, "publicationCode": S(), "publisherCode": S(), "topicName": TOPICNAME, "violationCount": L,
      "lastErrorCode": S(pattern="^ERR-10-1[0-9]{2}$"), "windowStart": TS, "windowEnd": TS},
      ["tenantId", "publicationCode", "topicName", "violationCount", "windowStart", "windowEnd"]),
  "MigrationCutOver": obj({"tenantId": TEN, "mappingId": S(format="uuid"), "legacyType": E("PROJECT", "TOPIC", "PUBLISHER", "SUBSCRIBER", "PUBLICATION", "SUBSCRIPTION"),
      "legacyId": S(), "targetCode": {"type": ["string", "null"]}, "status": E("CUT_OVER", "ROLLED_BACK"), "cutOverAt": NTS, "rollbackUntil": NTS,
      "reason": {"type": ["string", "null"], "maxLength": 500}}, ["tenantId", "mappingId", "legacyType", "legacyId", "status"]),
  "BridgeStateChanged": obj({"tenantId": TEN, "bridgeCode": S(pattern="^brg-[0-9a-hjkmnp-tv-z]{26}$"), "direction": E("PULSAR_TO_KAFKA", "KAFKA_TO_PULSAR"),
      "pulsarTopic": S(), "kafkaTopic": TOPICNAME, "previousStatus": BRIDGE, "status": BRIDGE, "bridgedCount": L, "lagSeconds": {"type": ["integer", "null"]},
      "errorDetail": {"type": ["string", "null"], "maxLength": 2000}}, ["tenantId", "bridgeCode", "direction", "status"]),
  # ---- giao ĐẨY và topic nghiệp vụ
  "CloudEventStructured": {"type": "object", "description": "CloudEvents 1.0 JSON có cấu trúc (`application/cloudevents+json`).",
      "required": ["specversion", "id", "source", "type"], "additionalProperties": True,
      "properties": {"specversion": {"type": "string", "const": "1.0"}, "id": S(maxLength=255), "source": S(maxLength=512), "type": S(maxLength=255),
          "time": TS, "subject": S(maxLength=255), "dataschema": S(maxLength=1024), "datacontenttype": S(), "traceparent": S(), "dhtenant": S(), "data": {}}},
  "BusinessData": {"description": "Giá trị bản tin theo lược đồ Apicurio của topic (`groupId = {tenant}`, `artifactId = {topicName}`), Avro nhị phân hoặc JSON, "
                   "có tiền tố định danh lược đồ (byte 0 và 4 byte `contentId`, ADR-070). Lược đồ không lặp ở đây."},
}

CE_KAFKA = obj({"ce_specversion": S(const="1.0"), "ce_id": S(description="ULID duy nhất, dùng chống trùng."),
    "ce_source": S(description="`/{tenant}/services/dh-integration` cho sự kiện PH-10; `/{tenant}/systems/{systemCode}` cho HTTT."),
    "ce_type": S(pattern="^vn\\.datahub\\.[a-z0-9-]+(\\.[a-z0-9-]+)+$"), "ce_time": TS, "ce_subject": S(description="Khóa nghiệp vụ, mặc định là khóa phân vùng."),
    "ce_dataschema": S(), "ce_datacontenttype": S(), "traceparent": S(), "dhtenant": S(pattern="^T[0-9]{2}$")},
    ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time", "dhtenant"])
CE_KAFKA["additionalProperties"] = True
WEBHOOK_HDR = obj({
    "Content-Type": E("application/cloudevents+json", "application/json"),
    "Webhook-Id": S(description="Bằng `ce_id`; giữ nguyên khi thử lại và khi phát lại để bên nhận chống trùng (BR-10-009)."),
    "Webhook-Timestamp": S(pattern="^[0-9]{10}$", description="Giây Unix lúc ký; bên nhận từ chối lệch quá `10.push.signature-tolerance-seconds`."),
    "X-Datahub-Signature": S(pattern="^t=[0-9]{10},v1=[0-9a-f]{64}(,v1=[0-9a-f]{64})?$",
        description="`t={ts},v1={hex HMAC-SHA256(secret, \"{Webhook-Id}.{Webhook-Timestamp}.{body}\")}`; hai giá trị `v1` trong thời gian xoay khóa."),
    "X-Datahub-Subscription": S(), "X-Datahub-Attempt": S(pattern="^[1-9][0-9]*$"), "X-Datahub-Key-Id": S(),
    "X-Datahub-Replay": S(description="Chỉ có khi giao từ lượt phát lại: `replayCode`."), "traceparent": S()},
    ["Content-Type", "Webhook-Id", "Webhook-Timestamp", "X-Datahub-Signature", "X-Datahub-Subscription", "X-Datahub-Attempt", "X-Datahub-Key-Id"])
WEBHOOK_BIN_HDR = copy.deepcopy(WEBHOOK_HDR)
WEBHOOK_BIN_HDR["properties"].update({"ce-specversion": S(const="1.0"), "ce-id": S(), "ce-source": S(), "ce-type": S(), "ce-time": TS, "ce-subject": S(),
    "ce-dataschema": S()})
WEBHOOK_BIN_HDR["required"] = WEBHOOK_HDR["required"] + ["ce-specversion", "ce-id", "ce-source", "ce-type"]
HANDSHAKE_HDR = obj({"WebHook-Request-Origin": S(description="`event.{tenant}.datahub`"), "WebHook-Request-Rate": S(pattern="^[0-9]+$")},
    ["WebHook-Request-Origin"])
DLQ_HDR = obj({"dh_dlq_subscription": S(), "dh_dlq_source_partition": S(pattern="^[0-9]+$"), "dh_dlq_source_offset": S(pattern="^[0-9]+$"),
    "dh_dlq_error_code": S(pattern="^ERR-10-1[0-9]{2}$"), "dh_dlq_attempts": S(pattern="^[0-9]+$"), "dh_dlq_first_failed_at": TS,
    "dh_dlq_origin": E("PUSH", "PULL_NACK", "EXTERNAL_REPORT", "REPLAY", "BRIDGE"), "dh_dlq_bridge": S()},
    ["dh_dlq_source_partition", "dh_dlq_source_offset", "dh_dlq_error_code", "dh_dlq_attempts", "dh_dlq_first_failed_at", "dh_dlq_origin"])
DLQ_HDR["additionalProperties"] = True

T0 = "2026-11-26T09:15:02+07:00"
def ce_hdr(entity, ev, subject):
    return {"ce_specversion": "1.0", "ce_id": "01JD3Z5Q8R2S4T6V8W0X2Y4Z6A", "ce_source": "/t68/services/dh-integration",
            "ce_type": f"vn.datahub.event.{entity}.{ev}", "ce_time": T0, "ce_subject": subject,
            "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01", "dhtenant": "T68"}

SUB = "ht-thue-dn-cap-phep"
PUB = "pub-01jd3y8k2m9p3q7r4t6v8w0y2z"
# key, mã, thực thể, sự kiện, payload, tóm tắt, khóa, bên nhận, FR, ví dụ payload
EV = [
  ("topicActivated", "EVT-10-01", "topic", "activated", "TopicActivated", "Topic sang `ACTIVE`.", "topicName", "PH-04, PH-05, PH-02, PH-13", "FR-10-009, 066",
   {"tenantId": "T68", "topicName": TOPIC, "projectCode": "dang-ky-kinh-doanh", "topicKind": "BUSINESS", "partitions": 6, "retentionHours": 168,
    "routingMode": "KEY_HASH", "partitionKeyField": "maDoanhNghiep", "orderingRequired": True, "dataClass": "INTERNAL", "latestSchemaVersion": 1,
    "activatedAt": T0, "ownerServiceCode": None, "configVersion": 4180}),
  ("topicChanged", "EVT-10-02", "topic", "changed", "TopicChanged", "Cấu hình topic, mức tương thích, trạng thái phiên bản lược đồ đổi.", "topicName", "dh-runtime, PH-04, PH-13", "FR-10-011, 012, 021, 022",
   {"tenantId": "T68", "topicName": TOPIC, "changedFields": ["partitions"], "partitions": 12, "retentionHours": 168, "cleanupPolicy": "DELETE",
    "maxMessageBytes": 262144, "compatibility": "BACKWARD", "enabledVersions": [2, 3], "configVersion": 4185}),
  ("topicDeprecated", "EVT-10-03", "topic", "deprecated", "TopicDeprecated", "Topic sang `DEPRECATED` (kèm kế nhiệm, `sunsetAt`).", "topicName", "PH-04, PH-02, PH-18", "FR-10-014, 015, 068",
   {"tenantId": "T68", "topicName": TOPIC, "successorTopic": "t68.dkkd.doanh-nghiep.da-cap-phep.v2", "sunsetAt": "2027-02-24T00:00:00+07:00",
    "migrationNote": "Phiên bản 2 tách `diaChi` thành đối tượng.", "configVersion": 4190}),
  ("topicRetired", "EVT-10-04", "topic", "retired", "TopicRetired", "Topic sang `RETIRED`.", "topicName", "PH-04, PH-05, PH-02, PH-13", "FR-10-014",
   {"tenantId": "T68", "topicName": TOPIC, "retiredAt": "2027-02-24T00:00:05+07:00", "configVersion": 4301}),
  ("schemaVersionEnabled", "EVT-10-05", "schema", "version-enabled", "SchemaVersionEnabled", "Phiên bản lược đồ `ENABLED`.", "topicName", "dh-runtime, PH-04, PH-05, PH-15", "FR-10-009, 019, 068",
   {"tenantId": "T68", "topicName": TOPIC, "versionNo": 3, "schemaFormat": "AVRO", "compatibility": "BACKWARD", "apicurioGroupId": "t68",
    "apicurioArtifactId": TOPIC, "apicurioGlobalId": 1042, "apicurioContentId": 877,
    "contentHash": "ddb50afd73e0294218a32b2833f50bbcb1d8d3fc80ca8fab000baed40a691252", "enabledAt": T0}),
  ("publicationActivated", "EVT-10-06", "publication", "activated", "PublicationActivated", "Publication `ACTIVE`.", "publicationCode", "PH-04, PH-13", "FR-10-031",
   {"tenantId": "T68", "publicationCode": PUB, "publisherCode": "ht-dkkd", "topicName": TOPIC, "grantedScope": f"topic:{TOPIC}:publish",
    "approvedBy": "binh.tt", "approvedAt": T0}),
  ("publicationStateChanged", "EVT-10-07", "publication", "state-changed", "PublicationStateChanged", "Tạm ngừng, tiếp tục, thu hồi publication.", "publicationCode", "PH-04, PH-13, PH-18", "FR-10-028, 029, 032",
   {"tenantId": "T68", "publicationCode": PUB, "publisherCode": "ht-dkkd", "topicName": TOPIC, "previousStatus": "ACTIVE", "status": "SUSPENDED",
    "suspendSource": "SECURITY", "reason": "Nghi lộ thông tin xác thực của HTTT, chờ cấp lại."}),
  ("subscriptionActivated", "EVT-10-08", "subscription", "activated", "SubscriptionActivated", "Subscription `ACTIVE`.", "subscriptionCode", "dh-runtime, PH-04, PH-13", "FR-10-037",
   {"tenantId": "T68", "subscriptionCode": SUB, "subscriberCode": "ht-thue", "topicName": TOPIC, "deliveryMode": "PUSH",
    "consumerGroup": "dh-sub-t68-ht-thue-dn-cap-phep", "startPosition": "LATEST", "configVersion": 4182}),
  ("subscriptionStateChanged", "EVT-10-09", "subscription", "state-changed", "SubscriptionStateChanged", "Tạm dừng, tiếp tục, tạm ngừng, thu hồi, đổi tham số có hiệu lực.", "subscriptionCode", "dh-runtime, PH-04, PH-13, PH-18", "FR-10-039, 041, 046, 047",
   {"tenantId": "T68", "subscriptionCode": SUB, "topicName": TOPIC, "previousStatus": "ACTIVE", "status": "SUSPENDED", "suspendSource": "CIRCUIT_BREAKER",
    "suspendReason": "Tỷ lệ lỗi ≥ 50% liên tục 30 phút.", "changedFields": [], "configVersion": 4183}),
  ("lagAlerted", "EVT-10-10", "subscription", "lag-alerted", "LagAlerted", "`alertState` đổi mức (cả khi về `OK`).", "subscriptionCode", "PH-13, PH-18", "FR-10-055",
   {"tenantId": "T68", "subscriptionCode": SUB, "topicName": TOPIC, "consumerGroup": "dh-sub-t68-ht-thue-dn-cap-phep", "previousAlertState": "OK",
    "alertState": "WARNING", "lagRecords": 14200, "lagSeconds": 420, "sampledAt": T0}),
  ("deadLettered", "EVT-10-11", "delivery", "dead-lettered", "DeadLettered", "Có mục DLQ mới (gộp 1 phút theo subscription).", "subscriptionCode", "PH-18, PH-13", "FR-10-049",
   {"tenantId": "T68", "subscriptionCode": SUB, "bridgeCode": None, "sourceTopic": TOPIC, "newEntryCount": 3, "errorCodes": ["ERR-10-112"],
    "firstFailedAt": "2026-11-26T09:14:05+07:00", "lastFailedAt": "2026-11-26T09:14:58+07:00", "origin": "PUSH"}),
  ("replayCompleted", "EVT-10-12", "replay", "completed", "ReplayCompleted", "Lượt phát lại `COMPLETED`, `FAILED`, `CANCELLED`.", "replayCode", "PH-18, PH-13", "FR-10-052, 053",
   {"tenantId": "T68", "replayCode": "rpl-01jd3z0a1b2c3d4e5f6g7h8j9k", "subscriptionCode": SUB, "replayMode": "REDELIVER_RANGE", "status": "COMPLETED",
    "estimatedRecords": 3120, "deliveredRecords": 3120, "failedRecords": 0, "startedAt": "2026-11-26T10:00:00+07:00", "finishedAt": "2026-11-26T10:06:40+07:00"}),
  ("signingKeyRotated", "EVT-10-13", "signing-key", "rotated", "SigningKeyRotated", "Xoay, thu hồi khóa ký. Không mang giá trị khóa.", "subscriptionCode", "dh-runtime, PH-13", "FR-10-042",
   {"tenantId": "T68", "subscriptionCode": SUB, "keyId": "k-20261126", "status": "ACTIVE", "previousKeyId": "k-20251126",
    "previousUntil": "2026-12-03T09:15:02+07:00", "revokedAt": None}),
  ("complianceViolated", "EVT-10-14", "compliance", "violated", "ComplianceViolated", "Vi phạm lược đồ của bên phát Kafka trực tiếp vượt ngưỡng trong 15 phút.", "publicationCode", "PH-13, PH-18", "FR-10-023",
   {"tenantId": "T68", "publicationCode": PUB, "publisherCode": "ht-dkkd", "topicName": TOPIC, "violationCount": 14, "lastErrorCode": "ERR-10-119",
    "windowStart": "2026-11-26T09:00:00+07:00", "windowEnd": "2026-11-26T09:15:00+07:00"}),
  ("migrationCutOver", "EVT-10-15", "migration", "cut-over", "MigrationCutOver", "Ánh xạ di trú chuyển hẳn hoặc quay lui.", "mappingId", "PH-13, PH-18", "FR-10-075",
   {"tenantId": "T68", "mappingId": "01937b30-8e2f-7a10-b3c4-1d2e3f4a5b6c", "legacyType": "TOPIC", "legacyId": "persistent://lgsp/dkkd/doanh-nghiep-cap-phep",
    "targetCode": TOPIC, "status": "CUT_OVER", "cutOverAt": T0, "rollbackUntil": "2026-12-26T09:15:02+07:00", "reason": None}),
  ("bridgeStateChanged", "EVT-10-16", "bridge", "state-changed", "BridgeStateChanged", "Cầu nối di trú đổi trạng thái (`RUNNING`, `STOPPED`, `ERROR`, `EXPIRED`, `REJECTED`).", "bridgeCode", "PH-13, PH-18", "FR-10-073, 074",
   {"tenantId": "T68", "bridgeCode": "brg-01jd3z2a3b4c5d6e7f8g9h0j1k", "direction": "PULSAR_TO_KAFKA", "pulsarTopic": "persistent://lgsp/dkkd/doanh-nghiep-cap-phep",
    "kafkaTopic": TOPIC, "previousStatus": "PENDING_APPROVAL", "status": "RUNNING", "bridgedCount": 0, "lagSeconds": None, "errorDetail": None}),
]
RETENTION_DAYS = 7
PARTITIONS = 3

def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, entity, ev, payload, summ, kfield, receivers, fr, example in EV:
        addr = f"{{tenant}}.event.{entity}.{ev}.v1"
        channels[key] = {"address": addr, "title": code, "description": f"{summ} Truy vết {fr}. Bên nhận: {receivers}.",
            "messages": {key: {"$ref": f"#/components/messages/{key}"}}, "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
            "bindings": {"kafka": {"topic": addr, "partitions": PARTITIONS, "replicas": 3,
                "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": RETENTION_DAYS * 86400000, "min.insync.replicas": 2}}}}
        cap = key[0].upper() + key[1:]
        ops[f"send{cap}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code}: dh-integration phát qua outbox",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{cap}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{receivers} nhận",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        msgs[key] = {"name": key, "title": code, "summary": summ, "contentType": "application/json", "payload": R(payload), "headers": CE_KAFKA,
            "bindings": {"kafka": {"key": {"type": "string", "description": f"`{kfield}`"}}},
            "examples": [{"name": code, "headers": ce_hdr(entity, ev, example.get(kfield, "")), "payload": example}]}
    # ---- topic nghiệp vụ và DLQ (mẫu)
    biz_params = {"tenant": {"$ref": "#/components/parameters/tenant"}, "domain": {"description": "Miền, `^[a-z][a-z0-9-]{1,30}$`, không thuộc miền dành riêng."},
                  "entity": {"description": "Thực thể, `^[a-z][a-z0-9-]{1,40}$`."}, "eventName": {"description": "Sự kiện, động từ quá khứ."},
                  "majorVersion": {"description": "Phiên bản chính của topic (`majorVersion`)."}}
    channels["businessTopic"] = {"address": "{tenant}.{domain}.{entity}.{eventName}.v{majorVersion}", "title": "Topic nghiệp vụ (mẫu)",
        "description": ("Mọi topic do PH-10 cấp phát theo BR-10-002. Cấu hình (`partitions`, `retentionHours`, `cleanupPolicy`, `maxMessageBytes`) theo khai báo topic; "
                        "`replicas = 3`, `min.insync.replicas = 2` (BR-10-004). Bên phát `HTTP_PUBLISH` qua API-10-079; `KAFKA_NATIVE` qua listener `external` "
                        "(SASL OAUTHBEARER hoặc mTLS); `INTERNAL_KAFKA`, `OUTBOX_CDC`, `DB_CDC` qua listener `internal` mTLS. ACL theo tiền tố tenant, cấp khi "
                        "publication, subscription được duyệt. Khóa bản tin là giá trị `partitionKeyField` khi `KEY_HASH`."),
        "parameters": biz_params, "messages": {"businessEvent": {"$ref": "#/components/messages/businessEvent"}}}
    channels["deadLetterTopic"] = {"address": "{tenant}.{domain}.{entity}.{eventName}.v{majorVersion}.dlq", "title": "Topic DLQ `{topicName}.dlq` (mẫu)",
        "description": ("Tạo cùng topic gốc (BR-10-023), lưu giữ `10.dlq.topic-retention-hours`. Bộ giao nhận, cổng kéo, API-10-083, bộ phát lại, cầu nối ghi bản tin gốc "
                        "nguyên vẹn kèm tiêu đề `dh_dlq_*`; `DlqIngestor` (`dh-svc-dh-integration-{tenant}`) đọc và lưu bền ở `dlq_entry`, `dlq_payload`. HTTT không đọc trực tiếp."),
        "parameters": biz_params, "messages": {"deadLetter": {"$ref": "#/components/messages/deadLetter"}}}
    ops["publishBusinessEvent"] = {"action": "send", "channel": {"$ref": "#/channels/businessTopic"}, "title": "Bên phát có publication ACTIVE ghi (FR-10-033, 034)",
        "security": [{"$ref": "#/components/securitySchemes/saslOauth"}, {"$ref": "#/components/securitySchemes/mtls"}],
        "messages": [{"$ref": "#/channels/businessTopic/messages/businessEvent"}]}
    ops["consumeBusinessEvent"] = {"action": "receive", "channel": {"$ref": "#/channels/businessTopic"},
        "title": "Bộ giao nhận, cổng kéo, luồng PH-04, HTTT Kafka ngoài đọc theo nhóm tiêu thụ A.8 (FR-10-038, 043, 044, 045)",
        "security": [{"$ref": "#/components/securitySchemes/saslOauth"}, {"$ref": "#/components/securitySchemes/mtls"}],
        "messages": [{"$ref": "#/channels/businessTopic/messages/businessEvent"}]}
    ops["writeDeadLetter"] = {"action": "send", "channel": {"$ref": "#/channels/deadLetterTopic"}, "title": "dh-runtime ghi DLQ (FR-10-049)",
        "messages": [{"$ref": "#/channels/deadLetterTopic/messages/deadLetter"}]}
    ops["ingestDeadLetter"] = {"action": "receive", "channel": {"$ref": "#/channels/deadLetterTopic"}, "title": "DlqIngestor của dh-integration lưu bền",
        "messages": [{"$ref": "#/channels/deadLetterTopic/messages/deadLetter"}]}
    biz_ex_hdr = {"ce_specversion": "1.0", "ce_id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "ce_source": "/t68/systems/HT-DKKD", "ce_type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep",
                  "ce_time": T0, "ce_subject": "0312345678", "ce_dataschema": f"/apis/registry/v3/groups/t68/artifacts/{TOPIC}/versions/3",
                  "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01", "dhtenant": "T68"}
    biz_data = {"maDoanhNghiep": "0312345678", "loaiThayDoi": "CAP_MOI", "phienBan": 1}
    msgs["businessEvent"] = {"name": "businessEvent", "title": "Sự kiện nghiệp vụ", "summary": "CloudEvents 1.0 nhị phân: thuộc tính ở tiêu đề `ce_*`, giá trị theo lược đồ Apicurio.",
        "payload": R("BusinessData"), "headers": CE_KAFKA, "bindings": {"kafka": {"key": {"type": "string", "description": "Giá trị `partitionKeyField` (UTF-8) khi `KEY_HASH`; rỗng khi `ROUND_ROBIN`."}}},
        "examples": [{"name": "doanh-nghiep-da-cap-phep", "headers": biz_ex_hdr, "payload": biz_data}]}
    msgs["deadLetter"] = {"name": "deadLetter", "title": "Bản tin DLQ", "summary": "Bản tin gốc nguyên vẹn (khóa, tiêu đề `ce_*`, giá trị) kèm tiêu đề `dh_dlq_*` (A.8).",
        "payload": R("BusinessData"), "headers": DLQ_HDR,
        "examples": [{"name": "dlq-push", "headers": dict(biz_ex_hdr, dh_dlq_subscription=SUB, dh_dlq_source_partition="2", dh_dlq_source_offset="182311",
            dh_dlq_error_code="ERR-10-112", dh_dlq_attempts="9", dh_dlq_first_failed_at="2026-11-26T09:01:44+07:00", dh_dlq_origin="PUSH"), "payload": biz_data}]}
    # ---- webhook ĐẨY
    ce_struct = {"specversion": "1.0", "id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "source": "/t68/systems/HT-DKKD", "type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep",
                 "time": T0, "subject": "0312345678", "dataschema": f"/apis/registry/v3/groups/t68/artifacts/{TOPIC}/versions/3",
                 "datacontenttype": "application/json", "dhtenant": "T68", "data": biz_data}
    wh_hdr = {"Content-Type": "application/cloudevents+json", "Webhook-Id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "Webhook-Timestamp": "1795660502",
              "X-Datahub-Signature": "t=1795660502,v1=" + "5d41402abc4b2a76b9719d911017c592" * 2, "X-Datahub-Subscription": SUB,
              "X-Datahub-Attempt": "1", "X-Datahub-Key-Id": "k-20261126", "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"}
    channels["webhookDelivery"] = {"address": "{endpointUrl}", "title": "Giao ĐẨY webhook (PUSH)",
        "description": ("Bộ giao nhận webhook của `dh-runtime` (ADR-071) gửi `POST` tới `push.endpointUrl` đã xác minh, qua egress gateway, chỉ HTTPS TLS ≥ 1.2, "
                        "không theo chuyển hướng, ghim IP đã kiểm (BR-10-026). Ký HMAC-SHA256 theo ADR-044. Kết quả: `2xx` thành công; `408`, `425`, `429`, `5xx`, "
                        "quá `timeoutMs`, lỗi mạng là lỗi tạm thời, thử lại giãn dần (FR-10-039); `4xx` khác vào DLQ ngay (ERR-10-113); `410` vào DLQ và tạm ngừng "
                        "subscription. Mỗi phân vùng giao tuần tự (BR-10-025), at-least-once; bên nhận chống trùng theo `Webhook-Id`."),
        "parameters": {"endpointUrl": {"description": "`push.endpointUrl` của subscription, ví dụ `https://thue.t68.gov.vn/hooks/dh`."}},
        "servers": [{"$ref": "#/servers/webhook-endpoint"}],
        "messages": {"webhookStructured": {"$ref": "#/components/messages/webhookStructured"}, "webhookBinary": {"$ref": "#/components/messages/webhookBinary"}},
        "bindings": {"http": {"bindingVersion": "0.3.0"}}}
    channels["webhookHandshake"] = {"address": "{endpointUrl}", "title": "Bắt tay xác minh endpoint (OPTIONS)",
        "description": ("FR-10-036, API-10-051: `OPTIONS` theo CloudEvents HTTP Webhook (chống lạm dụng). Endpoint phải trả `200` hoặc `204` với "
                        "`WebHook-Allowed-Origin` khớp `WebHook-Request-Origin` (hoặc `*`) trong `push.timeoutMs`. Ngoại lệ API-10-091 thay bằng một `POST` "
                        "sự kiện `vn.datahub.event.subscription.verification` mà endpoint trả `2xx`."),
        "parameters": {"endpointUrl": {"description": "URL cần xác minh."}}, "servers": [{"$ref": "#/servers/webhook-endpoint"}],
        "messages": {"webhookHandshake": {"$ref": "#/components/messages/webhookHandshake"}}, "bindings": {"http": {"bindingVersion": "0.3.0"}}}
    ops["deliverWebhook"] = {"action": "send", "channel": {"$ref": "#/channels/webhookDelivery"}, "title": "dh-runtime giao sự kiện tới HTTT (FR-10-038)",
        "bindings": {"http": {"method": "POST", "bindingVersion": "0.3.0"}},
        "messages": [{"$ref": "#/channels/webhookDelivery/messages/webhookStructured"}, {"$ref": "#/channels/webhookDelivery/messages/webhookBinary"}]}
    ops["verifyWebhookEndpoint"] = {"action": "send", "channel": {"$ref": "#/channels/webhookHandshake"}, "title": "dh-runtime bắt tay xác minh endpoint (FR-10-036)",
        "bindings": {"http": {"method": "OPTIONS", "bindingVersion": "0.3.0"}}, "messages": [{"$ref": "#/channels/webhookHandshake/messages/webhookHandshake"}]}
    msgs["webhookStructured"] = {"name": "webhookStructured", "title": "Webhook `CLOUDEVENTS_STRUCTURED`", "contentType": "application/cloudevents+json",
        "summary": "Thân là CloudEvents JSON có cấu trúc; `data` giải mã từ lược đồ.", "headers": WEBHOOK_HDR, "payload": R("CloudEventStructured"),
        "examples": [{"name": "giao-lan-dau", "headers": wh_hdr, "payload": ce_struct},
                     {"name": "phat-lai-trong-thoi-gian-xoay-khoa", "headers": dict(wh_hdr, **{"X-Datahub-Attempt": "1", "X-Datahub-Replay": "rpl-01jd3z0a1b2c3d4e5f6g7h8j9k",
                        "X-Datahub-Signature": "t=1795660502,v1=" + "5d41402abc4b2a76b9719d911017c592" * 2 + ",v1=" + "7e240de74fb1ed08fa08d38063f6a6a9" * 2}), "payload": ce_struct}]}
    bin_hdr = dict(wh_hdr, **{"Content-Type": "application/json", "ce-specversion": "1.0", "ce-id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "ce-source": "/t68/systems/HT-DKKD",
                              "ce-type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep", "ce-time": T0, "ce-subject": "0312345678"})
    msgs["webhookBinary"] = {"name": "webhookBinary", "title": "Webhook `CLOUDEVENTS_BINARY`", "contentType": "application/json",
        "summary": "Thuộc tính CloudEvents ở tiêu đề `ce-*`; thân là `data` JSON.", "headers": WEBHOOK_BIN_HDR, "payload": {"type": "object"},
        "examples": [{"name": "giao-nhi-phan", "headers": bin_hdr, "payload": biz_data}]}
    msgs["webhookHandshake"] = {"name": "webhookHandshake", "title": "Bắt tay `OPTIONS`", "summary": "Không có thân.", "headers": HANDSHAKE_HDR,
        "payload": {"type": "null"}, "examples": [{"name": "bat-tay", "headers": {"WebHook-Request-Origin": "event.t68.datahub", "WebHook-Request-Rate": "120"}, "payload": None}]}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-10 Sự kiện: sự kiện và giao nhận", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-10-01…16 (D03-04-PH10 §4, FRS §8.2, A.7), kênh giao ĐẨY webhook ký HMAC (ADR-044, ADR-071) và kênh mẫu của topic "
          "nghiệp vụ, topic DLQ.\n\nEVT-10 ghi vào `ph10_event.outbox_event` cùng giao dịch nghiệp vụ, Debezium đưa lên Kafka; CloudEvents 1.0 nhị phân, "
          "`ce_type = vn.datahub.event.{thực-thể}.{sự-kiện}`. Lưu giữ 7 ngày, 3 phân vùng (giả định theo mức của PH-05, Q10-58). Người nhận xử lý lũy đẳng "
          "theo `ce_id` (inbox) và bỏ qua `configVersion` cũ hơn bản đang giữ. Tương thích: chỉ thêm trường tùy chọn trong `v1` (ADR-070, BACKWARD). "
          "Không sự kiện nào mang giá trị khóa ký hay nội dung sự kiện nghiệp vụ. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)"}},
      "defaultContentType": "application/json",
      "servers": {
        "kafka-internal": {"host": "dh-kafka-kafka-bootstrap.dh-kafka.svc:9093", "protocol": "kafka-secure",
            "description": "Listener `internal`: DU, `dh-runtime`, Kafka Connect; mTLS, ACL theo CN và tiền tố tenant (D03-09).",
            "security": [{"$ref": "#/components/securitySchemes/mtls"}]},
        "kafka-external": {"host": "kafka-ext.{tenantHost}.datahub.example.vn:9093", "protocol": "kafka-secure",
            "description": "Listener `external` cho HTTT khi `10.external-kafka.enabled`; SASL OAUTHBEARER (Keycloak, principal theo `azp`) hoặc mTLS.",
            "variables": {"tenantHost": {"default": "t68"}},
            "security": [{"$ref": "#/components/securitySchemes/saslOauth"}, {"$ref": "#/components/securitySchemes/mtls"}]},
        "webhook-endpoint": {"host": "thue.t68.gov.vn", "protocol": "https", "description": "Đầu nhận của HTTT (giả lập); chỉ HTTPS, FQDN trong danh sách egress."}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`); topic nền tảng dùng tiền tố `dh`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do CA nội bộ cấp (cert-manager, PH-12); ACL Kafka theo CN."},
            "saslOauth": {"type": "oauth2", "description": "SASL OAUTHBEARER, token client credentials từ Keycloak realm `dh-{tenant}`.",
                "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "availableScopes": {}}}}},
        "messages": msgs, "schemas": SCHEMAS}}

def _str_rep(dumper, v):
    # Chuỗi toàn chữ số (mã số thuế, offset) luôn đặt trong nháy để bộ đọc YAML 1.2 không hiểu thành số.
    style = "'" if v.isdigit() or v in ("true", "false", "null", "yes", "no", "on", "off") else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", v, style=style)
yaml.SafeDumper.add_representer(str, _str_rep)

if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-event.yaml")
    doc = build()
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH10 · AsyncAPI PH-10. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(doc['channels'])} kênh, {len(doc['operations'])} operation, {len(doc['components']['messages'])} thông điệp → {out}")
