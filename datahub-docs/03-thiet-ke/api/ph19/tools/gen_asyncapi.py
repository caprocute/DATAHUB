#!/usr/bin/env python3
"""Sinh ph19/asyncapi-payment.yaml (AsyncAPI 3.0) cho EVT-19-01…18 từ khung §10.4 và lược đồ dưới đây. Không sửa tay YAML.

Chạy: python3 tools/gen_asyncapi.py   (từ thư mục api/ph19)
"""
import os, re, sys, yaml
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.abspath(os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "ph19", "tools")))
from schemas import SCHEMAS as API_SCHEMAS  # noqa: E402
from khung import Khung  # noqa: E402

R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
TS = S(format="date-time")
UUID = S(format="uuid")
def obj(props, req=()):
    d = {"type": "object", "properties": props, "additionalProperties": False}
    if req: d["required"] = list(req)
    return d
def en(name): return {"type": "string", "enum": API_SCHEMAS[name]["enum"]}
MONEY = {"type": "integer", "minimum": 1, "maximum": 999999999999}
MONEY0 = {"type": "integer", "minimum": 0, "maximum": 999999999999}
NUL = lambda x: {**x, "type": [x["type"], "null"]}
BASE = {"eventId": UUID, "occurredAt": TS, "tenantId": S(pattern="^T[0-9]{2}$"), "traceId": S(pattern="^[0-9a-f]{32}$"), "sequence": {"type": "integer", "minimum": 1}}
BREQ = ["eventId", "occurredAt", "tenantId", "traceId", "sequence"]
def ev(props, req=()):
    return obj({**BASE, **props}, BREQ + list(req))
TXN = {"transactionId": UUID, "transactionCode": S(pattern="^T[0-9]{2}[0-9]{6}[0-9A-HJKMNP-TV-Z]{10}$"), "partnerCode": S(maxLength=64),
       "partnerOrderId": S(maxLength=64), "serviceCode": S(maxLength=64), "isTest": B}
TREQ = ["transactionId", "transactionCode", "partnerOrderId"]
SCHEMAS = {
  "ProviderStatusChanged": ev({"providerId": UUID, "providerCode": S(), "fromStatus": NUL(en("ProviderStatus")), "toStatus": en("ProviderStatus"), "reason": S(maxLength=1000)},
                              ["providerId", "providerCode", "toStatus"]),
  "ProviderHealthChanged": ev({"providerId": UUID, "providerCode": S(), "healthStatus": en("HealthStatus"), "circuitState": en("CircuitState"),
                               "errorRate": {"type": "number", "minimum": 0, "maximum": 100}, "p95LatencyMs": I}, ["providerId", "providerCode", "healthStatus", "circuitState"]),
  "ServiceStatusChanged": ev({"serviceId": UUID, "serviceCode": S(), "fromStatus": NUL(en("ServiceStatus")), "toStatus": en("ServiceStatus"), "catalogInvalid": B},
                             ["serviceId", "serviceCode", "toStatus"]),
  "PartnerStatusChanged": ev({"partnerId": UUID, "partnerCode": S(), "fromStatus": NUL(en("PartnerStatus")), "toStatus": en("PartnerStatus"),
                              "routingMode": en("RoutingMode"), "legacyAppCode": NUL(S())}, ["partnerId", "partnerCode", "toStatus", "routingMode"]),
  "TransactionCreated": ev({**TXN, "amount": MONEY, "expiresAt": TS, "isShadow": B}, TREQ + ["amount", "expiresAt"]),
  "TransactionPending": ev({**TXN, "providerCode": S(), "providerReference": NUL(S(maxLength=128))}, TREQ + ["providerCode"]),
  "TransactionSucceeded": ev({**TXN, "amount": MONEY, "paidAt": TS, "providerReference": S(maxLength=128), "channelCode": NUL(S()), "bankCode": NUL(S()),
                              "latePaid": B, "metadata": {"type": "object", "additionalProperties": S(maxLength=255)}}, TREQ + ["amount", "paidAt", "latePaid"]),
  "TransactionFailed": ev({**TXN, "reasonCode": S(), "reasonMessage": S(maxLength=500), "providerResultCode": NUL(S())}, TREQ + ["reasonCode"]),
  "TransactionCancelled": ev({**TXN, "cancelledBy": S(enum=["PARTNER", "USER", "PAYER"])}, TREQ + ["cancelledBy"]),
  "TransactionExpired": ev({**TXN, "needsReconciliation": B}, TREQ + ["needsReconciliation"]),
  "RefundRequested": ev({"transactionId": UUID, "refundCode": S(pattern="^R[0-9A-HJKMNP-TV-Z]{14}$"), "transactionCode": S(), "amount": MONEY,
                         "reasonCode": S(), "requestedByType": S(enum=["USER", "PARTNER"]), "partnerRefundId": NUL(S(maxLength=64))},
                        ["transactionId", "refundCode", "transactionCode", "amount", "reasonCode", "requestedByType"]),
  "RefundDecided": ev({"transactionId": UUID, "refundCode": S(), "transactionCode": S(), "decision": S(enum=["APPROVED", "REJECTED"]), "approvalLevel": {"type": "integer", "enum": [1, 2]},
                       "partnerRefundId": NUL(S(maxLength=64))}, ["transactionId", "refundCode", "decision", "approvalLevel"]),
  "RefundSucceeded": ev({"transactionId": UUID, "refundCode": S(), "transactionCode": S(), "amount": MONEY, "completedAt": TS,
                         "transactionStatus": S(enum=["PARTIALLY_REFUNDED", "REFUNDED"]), "refundedAmount": MONEY, "partnerRefundId": NUL(S(maxLength=64))},
                        ["transactionId", "refundCode", "transactionCode", "amount", "completedAt", "transactionStatus"]),
  "RefundFailed": ev({"transactionId": UUID, "refundCode": S(), "transactionCode": S(), "reasonCode": S(), "executionCount": {"type": "integer", "minimum": 1, "maximum": 3},
                      "partnerRefundId": NUL(S(maxLength=64))}, ["transactionId", "refundCode", "reasonCode", "executionCount"]),
  "ReconciliationMatched": ev({"sessionId": UUID, "providerCode": S(), "businessDate": S(format="date"), "runNo": I, "dhCount": I, "providerCount": I,
                               "dhAmount": MONEY0, "providerAmount": MONEY0, "matchedCount": I, "discrepancyCount": I},
                              ["sessionId", "providerCode", "businessDate", "runNo", "discrepancyCount"]),
  "ReconciliationClosed": ev({"sessionId": UUID, "providerCode": S(), "businessDate": S(format="date"), "runNo": I, "minutesFileSha256": S(pattern="^[0-9a-f]{64}$"),
                              "supersedes": NUL(UUID)}, ["sessionId", "providerCode", "businessDate", "runNo", "minutesFileSha256"]),
  "DiscrepancyDetected": ev({"discrepancyId": UUID, "type": en("DiscrepancyType"), "transactionCode": NUL(S()), "businessDate": S(format="date"),
                             "dhAmount": NUL(MONEY0), "providerAmount": NUL(MONEY0), "dueAt": TS}, ["discrepancyId", "type", "businessDate", "dueAt"]),
  "DiscrepancyResolved": ev({"discrepancyId": UUID, "type": en("DiscrepancyType"), "resolutionType": en("ResolutionType"), "transactionCode": NUL(S())},
                            ["discrepancyId", "type", "resolutionType"]),
}
# EVT → (khóa message, lược đồ, giữ ngày, số phân vùng)
META = {
  "EVT-19-01": ("providerStatusChanged", "ProviderStatusChanged", 7, 3), "EVT-19-02": ("providerHealthChanged", "ProviderHealthChanged", 7, 3),
  "EVT-19-03": ("serviceStatusChanged", "ServiceStatusChanged", 7, 3), "EVT-19-04": ("partnerStatusChanged", "PartnerStatusChanged", 7, 3),
  "EVT-19-05": ("transactionCreated", "TransactionCreated", 30, 12), "EVT-19-06": ("transactionPending", "TransactionPending", 30, 12),
  "EVT-19-07": ("transactionSucceeded", "TransactionSucceeded", 30, 12), "EVT-19-08": ("transactionFailed", "TransactionFailed", 30, 12),
  "EVT-19-09": ("transactionCancelled", "TransactionCancelled", 30, 12), "EVT-19-10": ("transactionExpired", "TransactionExpired", 30, 12),
  "EVT-19-11": ("refundRequested", "RefundRequested", 30, 6), "EVT-19-12": ("refundDecided", "RefundDecided", 30, 6),
  "EVT-19-13": ("refundSucceeded", "RefundSucceeded", 30, 6), "EVT-19-14": ("refundFailed", "RefundFailed", 30, 6),
  "EVT-19-15": ("reconciliationMatched", "ReconciliationMatched", 30, 3), "EVT-19-16": ("reconciliationClosed", "ReconciliationClosed", 30, 3),
  "EVT-19-17": ("discrepancyDetected", "DiscrepancyDetected", 30, 3), "EVT-19-18": ("discrepancyResolved", "DiscrepancyResolved", 30, 3),
}
WEBHOOK = {"EVT-19-07", "EVT-19-08", "EVT-19-09", "EVT-19-10", "EVT-19-12", "EVT-19-13", "EVT-19-14", "EVT-19-16"}
CE_HEADERS = obj({
  "ce_specversion": S(const="1.0"), "ce_id": UUID, "ce_type": S(pattern="^vn\\.datahub\\.payment\\.[a-z-]+\\.[a-z-]+\\.v1$"),
  "ce_source": S(pattern="^/t[0-9]{2}/payment$"), "ce_subject": S(description="Mã nghiệp vụ: transactionCode, refundCode, providerCode…"),
  "ce_time": TS, "ce_tenantid": S(pattern="^T[0-9]{2}$"), "ce_sequence": S(pattern="^[0-9]+$"), "dhtenant": S(pattern="^T[0-9]{2}$"),
  "traceparent": S(), "content-type": S(const="application/json")}, ["ce_specversion", "ce_id", "ce_type", "ce_source", "ce_time", "ce_tenantid", "dhtenant"])

def build():
    k = Khung()
    channels, ops, msgs = {}, {}, {}
    rows = [r for r in k.rows("10.4") if r.get("Mã", "").startswith("EVT-19-")]
    assert len(rows) == 18, len(rows)
    for r in rows:
        code = r["Mã"]; key, payload, days, parts = META[code]
        suffix = r["Topic (sau `{tenant}.payment.`)"].strip("`")
        addr = "{tenant}.payment." + suffix
        entity, event = suffix.rsplit(".v1", 1)[0].split(".", 1)
        fr = r["FR"]; who = r["Bên tiêu thụ"]
        summ = f"{who}. {fr}."
        channels[key] = {"address": addr, "title": code, "description": f"Khóa phân vùng `{r['Khóa phân vùng'].strip('`')}`. Bên tiêu thụ: {who}."
                         + (" Cũng gửi qua webhook tới đối tác (cùng `id`, cùng `data`)." if code in WEBHOOK else ""),
                         "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
                         "messages": {key: {"$ref": f"#/components/messages/{key}"}},
                         "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3,
                                                "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        ops["publish" + key[0].upper() + key[1:]] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — dh-payment phát qua outbox",
                                                      "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        msgs[key] = {"name": key, "title": code, "summary": summ, "contentType": "application/json",
                     "headers": R("CloudEventHeaders"), "payload": R(payload),
                     "x-datahub-cloudevents-type": f"vn.datahub.payment.{entity}.{event}.v1",
                     "x-datahub-webhook": code in WEBHOOK,
                     "bindings": {"kafka": {"key": S(description=f"`{r['Khóa phân vùng'].strip('`')}` (UUID)")}}}
    SCHEMAS["CloudEventHeaders"] = CE_HEADERS
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-19 Thanh toán — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-19-01…18 (khung D02-03-PH19-00 §10.4, D03-04-PH19 §4).\n\n"
          "Sự kiện ghi vào `ph19_payment.outbox_event` cùng giao dịch CSDL với thay đổi trạng thái, Debezium (hoặc `OutboxRelay`) đưa lên Kafka; "
          "CloudEvents 1.0 chế độ nhị phân (tiêu đề `ce_*`, `dhtenant`), thân là `data`. Mỗi sự kiện một topic `{tenant}.payment.{thực-thể}.{sự-kiện}.v1`, "
          "`{tenant}` viết thường. Mọi payload có `eventId`, `occurredAt`, `tenantId`, `traceId`, `sequence` (BR-19-021), không chứa dữ liệu cá nhân người nộp. "
          "Webhook tới đối tác dùng cùng `eventId`, cùng `data` nhưng ở dạng cấu trúc (OpenAPI đối tác, mục `webhooks`) và không đi qua Kafka (NFR-19-013). "
          "Tương thích: chỉ thêm trường tùy chọn trong `v1`; thay đổi phá vỡ sang `v2`, phát song song ≥ 6 tháng (Apicurio BACKWARD). "
          "Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố topic của tenant (PH-10).", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường, ví dụ `t68`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}

if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-payment.yaml")
    doc = build()
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH19 · AsyncAPI PH-19. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(doc['channels'])} kênh → {out}")
