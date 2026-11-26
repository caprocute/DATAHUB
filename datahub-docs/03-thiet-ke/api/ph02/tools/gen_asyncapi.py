#!/usr/bin/env python3
"""Sinh asyncapi-catalog.yaml (AsyncAPI 3.0) của PH-02: EVT-02-01…16 (phát) và sáu sự kiện nhận từ PH-04, PH-10.
Chạy: python3 tools/gen_asyncapi.py. Cũng xuất EVENTS cho gen_md.py."""
import os

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "asyncapi-catalog.yaml")

T = {"type": "string"}


def en(*v):
    return {"type": "string", "enum": list(v)}


def sch(props, req, ex):
    base = {
        "tenantId": {"type": "string", "pattern": "^(T[0-9]{2}|COMMON)$", "description": "Mã tenant."},
        "eventId": {"type": "string", "format": "uuid"},
        "occurredAt": {"type": "string", "format": "date-time"},
    }
    base.update(props)
    ex = {"tenantId": "T68", "eventId": "0192d3a1-9b00-7c11-8d22-3e4f5a6b7c8d", "occurredAt": "2026-11-26T03:15:00Z", **ex}
    return {"type": "object", "properties": base, "required": ["tenantId", "eventId", "occurredAt"] + req, "examples": [ex]}


API = {"$ref": "#/components/schemas/ApiCodeStr"}
VER = {"type": "string", "pattern": r"^[0-9]+\.[0-9]+\.[0-9]+$"}
ENV = en("TEST", "STAGING", "PROD")
VS = en("DRAFT", "PENDING", "PUBLISHED", "SUSPENDED", "DEPRECATED", "RETIRED")
CE = {"type": "integer", "minimum": 0, "description": "Số phiên bản nguồn cấu hình (`config_epoch`); người nhận lũy đẳng, bỏ qua số nhỏ hơn số đang giữ."}

# (mã, kênh, topic, entity-event, FR, người nhận, khóa, giữ(ngày), mô tả, schema, ví dụ)
EVENTS = [
    ("01", "apiRegistered", "api.registered", "10, 13, 61", "PH-13, PH-15", "apiCode", 7, "API được đăng ký.",
     sch({"apiCode": API, "name": T, "providerSystemCode": T, "ownerOrgCode": T, "dataClass": en("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE"), "visibility": en("TENANT", "NATIONAL", "PUBLIC"),
          "origin": en("MANUAL", "OPENAPI", "FLOW", "LEGACY"), "versionNo": VER}, ["apiCode", "name", "dataClass", "visibility", "origin", "versionNo"],
         {"apiCode": "tra-cuu-ho-tich", "name": "Tra cứu thông tin hộ tịch", "providerSystemCode": "HT-HOTICH", "ownerOrgCode": "SO-TUPHAP", "dataClass": "RESTRICTED", "visibility": "TENANT", "origin": "OPENAPI", "versionNo": "1.0.0"})),
    ("02", "apiUpdated", "api.updated", "07, 08, 14, 22, 23, 26, 41, 42, 45, 55, 61", "PH-03, PH-15, PH-13", "apiCode", 7, "Đổi thông tin, phân loại, mức hiển thị, chủ quản, backend, SLA (kèm `changedFields`).",
     sch({"apiCode": API, "changedFields": {"type": "array", "items": T, "minItems": 1}, "visibility": en("TENANT", "NATIONAL", "PUBLIC"), "portalPublished": {"type": "boolean"}, "configEpoch": CE},
         ["apiCode", "changedFields"], {"apiCode": "tra-cuu-ho-tich", "changedFields": ["category", "tags"], "visibility": "TENANT", "portalPublished": False, "configEpoch": 9317})),
    ("03", "apiDeleted", "api.deleted", "40", "PH-15, PH-13, PH-14", "apiCode", 7, "API bị xóa mềm.",
     sch({"apiCode": API, "deletedBy": T}, ["apiCode"], {"apiCode": "tra-cuu-ho-tich", "deletedBy": "u-0192d3a1"})),
    ("04", "versionSubmitted", "version.submitted", "34", "PH-18, PH-13", "apiCode", 7, "Phiên bản gửi duyệt công bố.",
     sch({"apiCode": API, "versionNo": VER, "reviewRequestId": {"type": "string", "format": "uuid"}, "requestedBy": T, "dueAt": {"type": "string", "format": "date-time"}},
         ["apiCode", "versionNo", "reviewRequestId"], {"apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "reviewRequestId": "0192d3a1-8a10-7b22-8c4d-2e3f4a5b6c7d", "requestedBy": "u-0192d3a1", "dueAt": "2026-12-03T03:15:00Z"})),
    ("05", "versionPublished", "version.published", "36", "PH-03, PH-15, PH-13, PH-16", "apiCode", 7, "Phiên bản sang `PUBLISHED` (gateway đã xác nhận nạp).",
     sch({"apiCode": API, "versionNo": VER, "major": {"type": "integer"}, "environment": ENV, "contextPath": T, "visibility": en("TENANT", "NATIONAL", "PUBLIC"),
          "dataClass": en("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE"), "gatewayConfigVersion": {"type": "integer"}, "configEpoch": CE},
         ["apiCode", "versionNo", "environment", "contextPath", "configEpoch"],
         {"apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "major": 1, "environment": "PROD", "contextPath": "/ho-tich/tra-cuu-ho-tich/v1", "visibility": "TENANT", "dataClass": "RESTRICTED", "gatewayConfigVersion": 4182, "configEpoch": 9317})),
    ("06", "versionStateChanged", "version.state-changed", "36, 37, 38, 39", "PH-03, PH-15, PH-13, PH-18", "apiCode", 7, "Tạm ngừng, tiếp tục, ngừng khuyến nghị, ngừng hẳn (kể cả phiên bản cũ bị thay thế).",
     sch({"apiCode": API, "versionNo": VER, "from": VS, "to": VS, "reason": en("SUSPEND", "RESUME", "DEPRECATE", "RETIRE", "SUPERSEDED", "SUSPEND_EXPIRED"), "sunsetAt": {"type": "string", "format": "date-time"},
          "successorVersionNo": VER, "securityHold": {"type": "boolean"}, "configEpoch": CE},
         ["apiCode", "versionNo", "from", "to", "reason", "configEpoch"],
         {"apiCode": "ho-so-dat-dai", "versionNo": "1.2.0", "from": "PUBLISHED", "to": "DEPRECATED", "reason": "DEPRECATE", "sunsetAt": "2027-06-30T00:00:00Z", "successorVersionNo": "2.0.0", "securityHold": False, "configEpoch": 9420})),
    ("07", "versionSpecSourceChanged", "version.spec-source-changed", "12", "PH-18", "apiCode", 7, "Đặc tả nguồn URL thay đổi (PH-18 nhắc chủ dịch vụ).",
     sch({"apiCode": API, "versionNo": VER, "sourceUrl": {"type": "string", "format": "uri"}, "previousSha256": {"type": "string", "pattern": "^[0-9a-f]{64}$"},
          "newSha256": {"type": "string", "pattern": "^[0-9a-f]{64}$"}, "breakingCount": {"type": "integer", "minimum": 0}},
         ["apiCode", "versionNo", "newSha256", "breakingCount"],
         {"apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "sourceUrl": "https://ht-hotich.t68.example.vn/openapi.yaml", "previousSha256": "b" * 64, "newSha256": "c" * 64, "breakingCount": 1})),
    ("08", "planStateChanged", "plan.state-changed", "27, 29, 30, 31, 32, 33", "PH-03, PH-15", "apiCode", 7, "Gói đổi trạng thái hoặc khai báo.",
     sch({"apiCode": API, "versionNo": VER, "planCode": T, "from": en("STAGING", "PUBLISHED", "DEPRECATED", "CLOSED"), "to": en("STAGING", "PUBLISHED", "DEPRECATED", "CLOSED"),
          "changedFields": {"type": "array", "items": T}, "configEpoch": CE},
         ["apiCode", "versionNo", "planCode", "to"], {"apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "planCode": "co-ban", "from": "STAGING", "to": "PUBLISHED", "changedFields": ["status"], "configEpoch": 9318})),
    ("09", "subscriptionRequested", "subscription.requested", "46", "PH-18", "apiCode", 7, "Đăng ký sử dụng chờ duyệt.",
     sch({"subscriptionId": {"type": "string", "format": "uuid"}, "apiCode": API, "versionNo": VER, "planCode": T, "systemCode": T, "reviewRequestId": {"type": "string", "format": "uuid"},
          "dueAt": {"type": "string", "format": "date-time"}}, ["subscriptionId", "apiCode", "versionNo", "planCode", "systemCode", "reviewRequestId"],
         {"subscriptionId": "0192d3a1-a000-7d33-9e44-4f5a6b7c8d9e", "apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "planCode": "co-ban", "systemCode": "HT-MOTCUA", "reviewRequestId": "0192d3a1-a001-7d33-9e44-4f5a6b7c8d9f", "dueAt": "2026-12-03T03:15:00Z"})),
    ("10", "subscriptionActivated", "subscription.activated", "47, 48", "PH-03, PH-13, PH-15", "apiCode", 7, "Đăng ký được cấp phạm vi (consumer hợp lệ ở gateway).",
     sch({"subscriptionId": {"type": "string", "format": "uuid"}, "apiCode": API, "versionNo": VER, "planCode": T, "systemCode": T, "scopes": {"type": "array", "items": T},
          "expiresAt": {"type": "string", "format": "date-time"}, "configEpoch": CE}, ["subscriptionId", "apiCode", "versionNo", "planCode", "systemCode", "scopes", "configEpoch"],
         {"subscriptionId": "0192d3a1-a000-7d33-9e44-4f5a6b7c8d9e", "apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "planCode": "co-ban", "systemCode": "HT-MOTCUA", "scopes": ["api:tra-cuu-ho-tich:co-ban"], "expiresAt": "2027-11-26T00:00:00Z", "configEpoch": 9330})),
    ("11", "subscriptionStateChanged", "subscription.state-changed", "47, 51, 52", "PH-03, PH-12, PH-13", "apiCode", 7, "Từ chối, tạm ngừng, thu hồi, hủy, hết hạn.",
     sch({"subscriptionId": {"type": "string", "format": "uuid"}, "apiCode": API, "versionNo": VER, "planCode": T, "systemCode": T,
          "from": en("PENDING", "ACTIVE", "SUSPENDED"), "to": en("REJECTED", "CANCELLED", "SUSPENDED", "ACTIVE", "REVOKED", "EXPIRED"),
          "reason": en("REJECT", "SUSPEND", "RESUME", "REVOKE", "CANCEL", "EXPIRE", "SYSTEM_SUSPENDED"), "configEpoch": CE},
         ["subscriptionId", "apiCode", "versionNo", "planCode", "systemCode", "from", "to", "reason"],
         {"subscriptionId": "0192d3a1-a000-7d33-9e44-4f5a6b7c8d9e", "apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "planCode": "co-ban", "systemCode": "HT-MOTCUA", "from": "ACTIVE", "to": "SUSPENDED", "reason": "SUSPEND", "configEpoch": 9341})),
    ("12", "changeNoticeIssued", "change.notice-issued", "31, 36, 37, 38, 39, 55, 57", "PH-15, PH-18", "apiCode", 7, "Thông báo thay đổi đã phát cho bên khai thác.",
     sch({"noticeId": {"type": "string", "format": "uuid"}, "kind": en("ANNOUNCEMENT", "MAINTENANCE", "INCIDENT", "DEPRECATION", "SLA_WORSENED", "PUBLISHED", "SUSPENDED", "RETIRED"), "apiCode": API, "versionNo": VER,
          "recipientCount": {"type": "integer", "minimum": 0}, "mandatory": {"type": "boolean"}}, ["noticeId", "kind", "apiCode", "recipientCount"],
         {"noticeId": "0192d3a1-b000-7e55-8f66-5a6b7c8d9e0f", "kind": "MAINTENANCE", "apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "recipientCount": 6, "mandatory": False})),
    ("13", "slaPeriodClosed", "sla.period-closed", "56", "PH-13, PH-16", "apiCode", 30, "Chốt kỳ tuân thủ SLA (hằng tháng).",
     sch({"apiCode": API, "versionNo": VER, "period": {"type": "string", "pattern": "^[0-9]{4}-[0-9]{2}$"}, "status": en("MET", "BREACHED", "INSUFFICIENT_DATA"), "consecutiveBreaches": {"type": "integer", "minimum": 0}},
         ["apiCode", "versionNo", "period", "status"], {"apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "period": "2026-10", "status": "MET", "consecutiveBreaches": 0})),
    ("14", "nationalSyncStateChanged", "national-sync.state-changed", "53, 54", "PH-13", "apiCode", 7, "Trạng thái đồng bộ danh mục quốc gia đổi.",
     sch({"syncId": {"type": "string", "format": "uuid"}, "apiCode": API, "versionNo": VER, "action": en("UPSERT", "WITHDRAW"),
          "from": en("QUEUED", "SENT", "ACKED", "REJECTED", "FAILED", "NOT_CONFIGURED"), "to": en("QUEUED", "SENT", "ACKED", "REJECTED", "FAILED", "NOT_CONFIGURED"), "nationalRef": T, "attempts": {"type": "integer", "minimum": 0}},
         ["syncId", "apiCode", "action", "to"], {"syncId": "0192d3a1-c000-7f66-9077-6b7c8d9e0f1a", "apiCode": "tra-cuu-ho-tich", "versionNo": "1.0.0", "action": "UPSERT", "from": "SENT", "to": "ACKED", "nationalRef": "NQG-2026-000412", "attempts": 1})),
    ("15", "gatewayDriftDetected", "gateway.drift-detected", "60", "PH-13, PH-18", "environment", 7, "Phát hiện cấu hình gateway lệch với dữ liệu công bố.",
     sch({"environment": ENV, "driftCount": {"type": "integer", "minimum": 1}, "kinds": {"type": "object", "additionalProperties": {"type": "integer"}}, "gatewayConfigVersion": {"type": "integer"}, "expectedVersion": {"type": "integer"}},
         ["environment", "driftCount"], {"environment": "PROD", "driftCount": 2, "kinds": {"MISSING": 1, "STALE": 1}, "gatewayConfigVersion": 4181, "expectedVersion": 4182})),
    ("16", "reviewOverdue", "review.overdue", "35, 47", "PH-18", "reviewRequestId", 7, "Yêu cầu duyệt quá hạn (PH-18 nhắc và leo thang).",
     sch({"reviewRequestId": {"type": "string", "format": "uuid"}, "kind": T, "apiCode": API, "dueAt": {"type": "string", "format": "date-time"}, "ageDays": {"type": "integer", "minimum": 0}},
         ["reviewRequestId", "kind", "dueAt", "ageDays"], {"reviewRequestId": "0192d3a1-8a10-7b22-8c4d-2e3f4a5b6c7d", "kind": "VERSION_PUBLISH", "apiCode": "tra-cuu-ho-tich", "dueAt": "2026-12-03T03:15:00Z", "ageDays": 6})),
]

# Sự kiện PH-02 nhận (không phát): mã, kênh, topic, phát bởi, FR, ghi chú, trường dùng
INBOUND = [
    ("EVT-04-02", "flowUpdated", "{tenant}.integration.flow.updated.v1", "PH-04", "013", "Đồng bộ nhãn, chủ quản của luồng REST.", {"flowCode": T, "restOperations": {"type": "array", "items": {"type": "object"}}}),
    ("EVT-04-04", "flowVersionApproved", "{tenant}.integration.version.approved.v1", "PH-04", "013", "Phiên bản luồng đã duyệt; cập nhật khung route và đặc tả sinh từ luồng.", {"flowCode": T, "versionNo": T, "restOperations": {"type": "array", "items": {"type": "object"}}}),
    ("EVT-04-07", "deploymentStatusChanged", "{tenant}.integration.deployment.status-changed.v1", "PH-04", "013", "Bật, tắt luồng; PH-02 cập nhật `flowSyncStatus` và cảnh báo API công bố sinh từ luồng đã tắt.", {"flowCode": T, "status": T}),
    ("EVT-10-01", "topicActivated", "{tenant}.event.topic.activated.v1", "PH-10", "009", "Topic `ACTIVE`; PH-02 cập nhật bản sao `topic_replica` cho dịch vụ sự kiện.", {"topicName": T}),
    ("EVT-10-03", "topicDeprecated", "{tenant}.event.topic.deprecated.v1", "PH-10", "009", "Topic `DEPRECATED` kèm kế nhiệm, `sunsetAt`.", {"topicName": T, "sunsetAt": {"type": "string", "format": "date-time"}}),
    ("EVT-10-04", "topicRetired", "{tenant}.event.topic.retired.v1", "PH-10", "009", "Topic `RETIRED`; dịch vụ sự kiện hiện nhãn đã ngừng ở PH-10.", {"topicName": T}),
]

HEAD = {
    "type": "object",
    "properties": {
        "ce_specversion": {"type": "string", "const": "1.0"}, "ce_id": {"type": "string", "format": "uuid"},
        "ce_source": {"type": "string", "description": "`/tenants/{tenant}/catalog`"},
        "ce_type": {"type": "string", "description": "`vn.datahub.catalog.{thực-thể}.{sự-kiện}.v1`"},
        "ce_time": {"type": "string", "format": "date-time"}, "ce_subject": {"type": "string", "description": "Mã API hoặc mã yêu cầu."},
        "ce_datacontenttype": {"type": "string", "const": "application/json"}, "traceparent": {"type": "string"},
    },
    "required": ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time"],
}


def camel(s):
    return s


def build():
    channels, ops, msgs, schemas = {}, {}, {}, {"ApiCodeStr": {"type": "string", "pattern": "^[a-z][a-z0-9-]{2,62}$"}}
    for x in EVENTS:
        n, key, ev, fr, cons, pkey, days, desc, schema = x
        pl = key[0].upper() + key[1:]
        topic = "{tenant}.catalog." + ev + ".v1"
        channels[key] = {
            "address": topic, "title": f"EVT-02-{n}", "description": f"{desc} (FR-02-{fr.replace(', ', ', FR-02-')}). Khóa phân vùng: `{pkey}`. Người nhận: {cons}.",
            "messages": {key: {"$ref": f"#/components/messages/{key}"}},
            "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
            "bindings": {"kafka": {"topic": topic, "partitions": 3, "replicas": 3, "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}},
        }
        msgs[key] = {"name": key, "title": f"EVT-02-{n}", "summary": desc, "payload": {"$ref": f"#/components/schemas/{pl}"}, "headers": {"$ref": "#/components/schemas/CloudEventsHeaders"},
                     "bindings": {"kafka": {"key": {"type": "string", "description": f"`{pkey}`"}}}}
        schemas[pl] = schema
        ops["send" + pl] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"EVT-02-{n} — dh-connect phát (outbox)", "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
    for (code, key, topic, frm, fr, desc, props) in INBOUND:
        pl = key[0].upper() + key[1:]
        channels["in" + pl] = {
            "address": topic, "title": f"{code} ({frm}) — PH-02 nhận", "description": f"{desc} (FR-02-{fr}). Chỉ liệt kê trường PH-02 đọc; hợp đồng đầy đủ ở D03-04-{'PH04' if frm == 'PH-04' else 'PH10'}.",
            "messages": {"in" + pl: {"$ref": f"#/components/messages/in{pl}"}}, "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
        }
        msgs["in" + pl] = {"name": "in" + pl, "title": code, "summary": desc, "payload": {"$ref": f"#/components/schemas/In{pl}"}}
        schemas["In" + pl] = {"type": "object", "properties": props, "additionalProperties": True}
        ops["receive" + pl] = {"action": "receive", "channel": {"$ref": f"#/channels/in{pl}"}, "title": f"{code} — dh-connect nhận ({frm})", "messages": [{"$ref": f"#/channels/in{pl}/messages/in{pl}"}]}
    schemas["CloudEventsHeaders"] = HEAD
    doc = {
        "asyncapi": "3.0.0",
        "info": {"title": "Datahub PH-02 Danh mục dịch vụ — sự kiện", "version": "1.0.0-draft",
                 "description": ("Hợp đồng sự kiện EVT-02-01…16 (D03-04-PH02 §4, FRS §9.3) và sáu sự kiện PH-02 nhận từ PH-04, PH-10. Sự kiện phát ghi vào `ph02_catalog.outbox_event` cùng giao dịch, "
                                "Debezium đưa lên Kafka, CloudEvents 1.0 chế độ nhị phân. Không sự kiện nào mang đặc tả, khóa, bí mật hay giá trị dữ liệu cá nhân. Người nhận xử lý lũy đẳng theo `eventId` và `configEpoch`. "
                                "Tương thích BACKWARD ở Apicurio: chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
                 "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
        "defaultContentType": "application/json",
        "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure", "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant.",
                                  "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
        "channels": channels, "operations": ops,
        "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`).", "examples": ["t68"]}},
                       "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
                       "messages": msgs, "schemas": schemas},
    }
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH02 · AsyncAPI PH-02. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=160)
    print(len(EVENTS), "sự kiện phát,", len(INBOUND), "sự kiện nhận ->", os.path.relpath(OUT))


if __name__ == "__main__":
    build()
