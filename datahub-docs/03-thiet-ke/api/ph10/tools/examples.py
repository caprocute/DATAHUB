"""Ví dụ yêu cầu, phản hồi cho openapi-event.yaml.

Ví dụ dựng từ lược đồ theo bảng giá trị mẫu FIELD (dữ liệu giả lập tenant T68), rồi ghi đè bằng ví dụ viết tay
REQ, RESP cho các operation chính. check_contracts.py kiểm mọi ví dụ khớp lược đồ.
Khóa idempotency trong tài liệu không dùng dạng UUID để không giống bí mật (gitleaks).
"""
import copy

TOPIC = "t68.dkkd.doanh-nghiep.da-cap-phep.v1"
TS0 = "2026-11-26T09:15:02+07:00"
FIELD = {
  "projectCode": "dang-ky-kinh-doanh", "name": "Đăng ký kinh doanh", "description": "Sự kiện vòng đời doanh nghiệp do Sở KH&ĐT phát cho các sở, ngành.",
  "ownerOrgCode": "SO-KHDT", "ownerUser": "an.nv", "labels": ["doanh-nghiep"], "topicName": TOPIC, "sourceTopic": TOPIC, "kafkaTopic": TOPIC,
  "successorTopic": "t68.dkkd.doanh-nghiep.da-cap-phep.v2", "predecessorTopic": None, "domain": "dkkd", "entity": "doanh-nghiep", "eventName": "da-cap-phep",
  "majorVersion": 1, "partitions": 6, "replicationFactor": 3, "minInsyncReplicas": 2, "retentionHours": 168, "maxMessageBytes": 262144,
  "partitionKeyField": "maDoanhNghiep", "orderingRequired": True, "submit": True, "publisherCode": "ht-dkkd", "subscriberCode": "ht-thue",
  "subscriptionCode": "ht-thue-dn-cap-phep", "publicationCode": "pub-01jd3y8k2m9p3q7r4t6v8w0y2z", "requestCode": "apr-01jd3y9b4c6d8e0f2g4h6j8k0m",
  "approvalRequestCode": "apr-01jd3y9b4c6d8e0f2g4h6j8k0m", "replayCode": "rpl-01jd3z0a1b2c3d4e5f6g7h8j9k", "jobCode": "imp-01jd3z1m2n3p4q5r6s7t8v9w0x",
  "bridgeCode": "brg-01jd3z2a3b4c5d6e7f8g9h0j1k", "dlqEntryId": "01937b2e-4c1a-7d3e-9f20-6a8b5c4d3e21", "mappingId": "01937b30-8e2f-7a10-b3c4-1d2e3f4a5b6c",
  "systemCode": "HT-DKKD", "flowCode": "dkkd-dong-bo-thue", "serviceCode": "dh-integration", "referenceKey": "DKKD_PUB_01",
  "clientId": "ht-dkkd-t68", "kafkaPrincipal": "User:ht-dkkd-t68", "purpose": "Thông báo doanh nghiệp được cấp đăng ký cho cơ quan thuế xử lý mã số thuế.",
  "legalBasis": "Quyết định 12/QĐ-UBND ngày 01/10/2026 về chia sẻ dữ liệu doanh nghiệp.", "consumerGroup": "dh-sub-t68-ht-thue-dn-cap-phep",
  "endpointUrl": "https://thue.t68.gov.vn/hooks/dh", "targetEndpointUrl": "https://thue-dr.t68.gov.vn/hooks/dh", "workerCount": 3, "maxRetries": 8,
  "timeoutMs": 10000, "initialMs": 1000, "multiplier": 2, "maxMs": 300000, "maxBatch": 100, "leaseSeconds": 60, "lagWarnSeconds": 300,
  "lagCriticalSeconds": 1800, "reason": "Hệ thống thuế bảo trì theo kế hoạch 26/11/2026.", "comment": "Đã rà soát lược đồ và phân loại dữ liệu.",
  "decisionComment": "Đã rà soát lược đồ và phân loại dữ liệu.", "keyId": "k-20261126", "versionNo": 3, "latestVersionNo": 3, "latestSchemaVersion": 3,
  "schemaVersion": 3, "contentHash": "ddb50afd73e0294218a32b2833f50bbcb1d8d3fc80ca8fab000baed40a691252",
  "apicurioGroupId": "t68", "apicurioArtifactId": TOPIC, "apicurioGlobalId": 1042, "apicurioContentId": 877, "changeNote": "Thêm trường `nganhNgheChinh` (tùy chọn).",
  "targetCode": TOPIC, "eventId": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "eventType": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep", "eventSubject": "0312345678",
  "errorCode": "ERR-10-112", "errorDetail": "Đầu nhận trả 503 sau 8 lần thử.", "httpStatus": 503, "attempts": 9, "attempt": 9, "partition": 2,
  "offset": 182311, "sourcePartition": 2, "sourceOffset": 182311, "fromOffset": 182000, "toOffset": 182311, "ratePerSecond": 500,
  "estimatedRecords": 3120, "estimatedDurationSeconds": 7, "signingKeyPending": False, "allowedActions": ["update", "pause", "rotate"], "deliveredRecords": 0, "failedRecords": 0, "lagRecords": 42, "lagSeconds": 18, "committedOffset": 182269, "endOffset": 182311,
  "responseSnippet": "{\"error\":\"service unavailable\"}", "commTypeCode": "WEBHOOK_PUSH", "routingModeCode": "KEY_HASH", "legacyCode": "HTTP_PUSH",
  "pulsarTopic": "persistent://lgsp/dkkd/doanh-nghiep-cap-phep", "pulsarSubscriptionName": "dh-bridge", "legacyId": "persistent://lgsp/dkkd/doanh-nghiep-cap-phep",
  "legacyName": "doanh-nghiep-cap-phep", "expiresAt": "2027-05-25T00:00:00+07:00", "bridgedCount": 120455, "fileRef": "t68/import/imp-01jd3z1m2n3p4q5r6s7t8v9w0x/manifest.yaml",
  "onBehalfOf": "an.nv", "environment": "PROD", "cursor": "eyJzIjoiaHQtdGh1ZS1kbi1jYXAtcGhlcCIsImwiOiIwMUpEM1oiLCJvIjp7IjIiOjE4MjMxMn19.c2lnbmF0dXJl",
  "runner": "dh-runtime-event-t68-1", "probeEventId": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "suspendReason": "Tỷ lệ lỗi ≥ 50% liên tục 30 phút.",
  "alertAckNote": "Đã liên hệ đầu mối Cục Thuế, đang xử lý.", "waiverUntil": "2027-05-25T00:00:00+07:00", "sunsetAt": "2027-02-24T00:00:00+07:00",
  "sunsetDays": 90, "migrationNote": "Phiên bản 2 tách `diaChi` thành đối tượng.", "tenant": "T68", "configVersion": 4182, "expectedRatePerMinute": 120,
  "quotaBytesPerSecond": 524288, "httpPublishUrl": f"https://event.t68.datahub.example.vn/event/v1/topics/{TOPIC}/events",
  "registryUrl": "https://event.t68.datahub.example.vn/event/v1/registry/apis/registry/v3", "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
  "kafkaBootstrap": "kafka-ext.t68.datahub.example.vn:9093", "label": "Hệ thống đăng ký kinh doanh", "code": "ht-dkkd", "id": "pub:ht-dkkd",
  "from": 2, "to": 3, "secret": "whsec_VI-DU-CHI-HIEN-MOT-LAN", "content": "{\"type\":\"record\",\"name\":\"DoanhNghiepDaCapPhep\",\"namespace\":\"vn.t68.dkkd\",\"fields\":[{\"name\":\"maDoanhNghiep\",\"type\":\"string\"},{\"name\":\"loaiThayDoi\",\"type\":\"string\"},{\"name\":\"phienBan\",\"type\":\"int\"}]}",
  "field": "nguoiDaiDien.soDinhDanh", "message": "Trường có dạng số định danh cá nhân trong topic INTERNAL.", "rule": "pii-cccd",
  "path": "fields.nganhNgheChinh", "worker": 0, "createdBy": "an.nv", "updatedBy": "an.nv", "requestedBy": "an.nv", "decidedBy": "binh.tt",
  "approvedBy": "binh.tt", "resolvedBy": None, "version": 3, "inUseCount": 4, "count": 12, "difference": 0, "pulsarCount": 120455, "kafkaCount": 120455,
  "sampleMismatches": 0, "reportRef": "t68/reconcile/brg-01jd3z2a3b4c5d6e7f8g9h0j1k/2026112609.json", "sampledCount": 1830, "violationCount": 0,
  "sampleRatio": 0.01, "successCount": 7140, "transientErrorCount": 12, "retryCount": 12, "deadLetterCount": 1, "latencyP50Ms": 85, "latencyP95Ms": 240,
  "topicCount": 4, "publisherCount": 2, "subscriberCount": 5, "maxLagSeconds": 18, "dlqNewCount": 1, "ratePerMinute": 120.0, "retentionRemainingSeconds": 604782,
  "inPerMinute": 640.0, "outPerMinute": 1920.0, "page": 0, "size": 20, "totalElements": 1, "type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep",
  "source": "/t68/systems/HT-DKKD", "specversion": "1.0", "subject": "0312345678", "time": TS0, "datacontenttype": "application/json",
  "dataschema": f"/apis/registry/v3/groups/t68/artifacts/{TOPIC}/versions/3", "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
  "dhtenant": "T68", "data": {"maDoanhNghiep": "0312345678", "loaiThayDoi": "CAP_MOI", "phienBan": 1},
  "grantedScope": f"topic:{TOPIC}:publish", "aclRef": "dh-config-t68/kafka/users/ht-dkkd-t68.yaml", "provisioningCommit": "3f9a2c1",
  "provisioningError": None, "suspendSource": None, "httpPullUrlTemplate": "https://event.t68.datahub.example.vn/event/v1/subscriptions/{subscriptionCode}/events",
  "consumerGroupTemplate": "dh-ext-t68-{subscriptionCode}", "kafkaListener": "external", "legacyCodeR": None, "payloadRef": "dlq_payload:01937b2e",
  "statusReason": None, "pulsarTopicName": None, "lastPulsarMessageId": "CAEQ0gEYACAA", "detail": "Endpoint trả 204 với WebHook-Allowed-Origin khớp.",
  "alertAcknowledgedBy": None, "alertAcknowledgedAt": None, "alertAckNote": None, "archiveReason": None, "archivedAt": None, "ceilingSetBy": "pa.admin",
  "dataBase64": None, "resolveReason": None, "resolvedAt": None, "verificationWaiverReason": None, "verificationWaiverUntil": None,
  "key": "0312345678", "masked": False, "previousOffsets": None, "partitionKeyFieldR": None, "systemCodeLegacy": None, "plannedShutdownAt": "2027-06-30", "day": "2026-11-26", "generatedAt": TS0,
}
ENUM_PICK = {"status": None}

def init(schemas):
    global S
    S = schemas

def _resolve(sch):
    while "$ref" in sch:
        sch = S[sch["$ref"].split("/")[-1]]
    return sch

def _nullable(sch):
    if "oneOf" in sch and any(x.get("type") == "null" for x in sch["oneOf"]): return True
    t = sch.get("type")
    return isinstance(t, list) and "null" in t

def gen(sch, name=None, full=True, depth=0):
    if name in FIELD and FIELD[name] is None and _nullable(sch): return None
    if "$ref" in sch:
        tgt = S[sch["$ref"].split("/")[-1]]
        if "examples" in tgt and (name is None or name not in FIELD): return copy.deepcopy(tgt["examples"][0])
        return gen(tgt, name, full, depth)
    if "oneOf" in sch:
        return gen(sch["oneOf"][0], name, full, depth)
    if "allOf" in sch:
        out = {}
        for part in sch["allOf"]:
            v = gen(part, name, full, depth)
            if isinstance(v, dict): out.update(v)
        return out
    if "const" in sch: return sch["const"]
    if "enum" in sch:
        v = FIELD.get(name)
        return v if v in sch["enum"] else sch["enum"][0]
    t = sch.get("type")
    if isinstance(t, list):
        t = [x for x in t if x != "null"][0]
    if t == "array" and isinstance(FIELD.get(name), list): return copy.deepcopy(FIELD[name])
    if name in FIELD and FIELD[name] is not None and t != "object" and t != "array":
        v = FIELD[name]
        if t == "integer" and isinstance(v, bool): pass
        elif t == "integer" and isinstance(v, int): return max(v, sch.get("minimum", v))
        elif t == "number" and isinstance(v, (int, float)): return v
        elif t == "string" and isinstance(v, str): return v
        elif t == "boolean" and isinstance(v, bool): return v
    if t == "object":
        props = sch.get("properties")
        if props is None:
            ap = sch.get("additionalProperties")
            if isinstance(ap, dict) and ap.get("type") == "integer": return {"ACTIVE": 3}
            if isinstance(ap, dict) and ap.get("type") == "number": return {"maxTopics": 0.42}
            if isinstance(ap, dict) and ap.get("type") == "string": return {"java": "bootstrap.servers=..."}
            if name == "data": return FIELD["data"]
            return {}
        req = set(sch.get("required", []))
        out = {}
        for k, v in props.items():
            if full or k in req or (k in FIELD and FIELD[k] is not None):
                if depth > 3 and k not in req: continue
                out[k] = gen(v, k, full, depth + 1)
        return out
    if t == "array":
        if name in FIELD and isinstance(FIELD[name], list): return list(FIELD[name])
        it = gen(sch["items"], name[:-1] if name and name.endswith("s") else name, full, depth + 1)
        return [it]
    if t == "integer":
        return sch.get("minimum", 1) if sch.get("minimum", 0) > 0 else 1
    if t == "number": return 1.0
    if t == "boolean": return False
    if t == "string":
        f = sch.get("format")
        if f == "date-time": return TS0
        if f == "date": return "2026-11-26"
        if f == "uuid": return FIELD["dlqEntryId"]
        if f == "uri": return "https://datahub.example.vn/"
        if "pattern" in sch and sch["pattern"].startswith("^ERR-10-1"): return "ERR-10-112"
        if "pattern" in sch and sch["pattern"] == "^https://": return FIELD["targetEndpointUrl"]
        mn = sch.get("minLength", 0)
        v = "Giá trị mẫu"
        return v if len(v) >= mn else (v + " " * mn)[:max(mn, len(v))].replace(" ", ".")
    if "description" in sch and name == "data": return FIELD["data"]
    return FIELD.get(name, "mẫu")

TOPIC_RESP = None

REQ = {
  "002": {"projectCode": "dang-ky-kinh-doanh", "name": "Đăng ký kinh doanh", "description": "Sự kiện vòng đời doanh nghiệp do Sở KH&ĐT phát cho các sở, ngành.",
          "ownerOrgCode": "SO-KHDT", "ownerUser": "an.nv", "labels": ["doanh-nghiep"]},
  "009": {"projectCode": "dang-ky-kinh-doanh", "domain": "dkkd", "entity": "doanh-nghiep", "eventName": "da-cap-phep",
          "description": "Phát khi Sở KH&ĐT cấp mới giấy chứng nhận đăng ký doanh nghiệp.", "partitions": 6, "retentionHours": 168,
          "cleanupPolicy": "DELETE", "routingMode": "KEY_HASH", "partitionKeyField": "maDoanhNghiep", "orderingRequired": True, "dataClass": "INTERNAL",
          "schema": {"schemaFormat": "AVRO", "content": FIELD["content"], "compatibility": "BACKWARD"}, "submit": True},
  "015": {"partitions": 12, "acknowledgeOrderingImpact": True, "plannedAt": "2026-11-28T22:00:00+07:00", "reason": "Lưu lượng tăng gấp đôi sau khi mở thêm hai huyện."},
  "023": {"content": FIELD["content"].replace("]}", ",{\"name\":\"nganhNgheChinh\",\"type\":[\"null\",\"string\"],\"default\":null}]}"),
          "changeNote": "Thêm trường `nganhNgheChinh` (tùy chọn).", "submit": False},
  "033": {"publisherCode": "ht-dkkd", "name": "Hệ thống đăng ký kinh doanh", "partyType": "SYSTEM", "systemCode": "HT-DKKD", "commType": "HTTP_PUBLISH", "referenceKey": "DKKD_PUB_01"},
  "038": {"subscriberCode": "ht-thue", "name": "Hệ thống quản lý thuế", "partyType": "SYSTEM", "systemCode": "HT-THUE", "commType": "WEBHOOK_PUSH"},
  "043": {"publisherCode": "ht-dkkd", "topicName": TOPIC, "purpose": "Phát sự kiện cấp mới đăng ký doanh nghiệp.", "expectedRatePerMinute": 120},
  "047": {"subscriberCode": "ht-thue", "topicName": TOPIC, "deliveryMode": "PUSH", "purpose": FIELD["purpose"], "startPosition": "LATEST",
          "push": {"endpointUrl": "https://thue.t68.gov.vn/hooks/dh", "workerCount": 3, "maxRetries": 8,
                   "retryBackoff": {"initialMs": 1000, "multiplier": 2, "maxMs": 300000}, "timeoutMs": 10000, "failurePolicy": "BLOCK", "payloadFormat": "CLOUDEVENTS_STRUCTURED"},
          "lagWarnSeconds": 300, "lagCriticalSeconds": 1800},
  "051": {"endpointUrl": "https://thue.t68.gov.vn/hooks/dh", "subscriptionCode": "ht-thue-dn-cap-phep", "timeoutMs": 10000},
  "059": {"comment": "Đã rà soát lược đồ và phân loại dữ liệu.", "acknowledgePii": True},
  "064": {"subscriptionCode": "ht-thue-dn-cap-phep", "replayMode": "REDELIVER_RANGE", "rangeType": "TIME", "fromTime": "2026-11-20T00:00:00+07:00",
          "toTime": "2026-11-21T23:59:59+07:00", "ratePerSecond": 500, "reason": "Hệ thống thuế lỗi xử lý 20–21/11, cần nhận lại.", "acknowledgeDuplicates": True},
  "071": {"environment": "PROD", "items": [{"flowCode": "dkkd-dong-bo-thue", "topicName": TOPIC, "action": "SUBSCRIBE"},
                                           {"flowCode": "dkkd-dong-bo-thue", "topicName": "t68.thue.ma-so-thue.da-cap.v1", "action": "PUBLISH"}]},
  "079": {"specversion": "1.0", "id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "source": "/t68/systems/HT-DKKD", "type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep",
          "time": TS0, "subject": "0312345678", "datacontenttype": "application/json", "data": {"maDoanhNghiep": "0312345678", "loaiThayDoi": "CAP_MOI", "phienBan": 1}},
  "081": {"cursor": FIELD["cursor"]},
  "082": {"cursor": FIELD["cursor"], "eventIds": ["01JD3Y8K2M9P3Q7R4T6V8W0Y2Z"], "reason": "Mã số doanh nghiệp không có trong CSDL thuế."},
  "113": {"direction": "PULSAR_TO_KAFKA", "pulsarTopic": FIELD["pulsarTopic"], "kafkaTopic": TOPIC, "startFrom": "LATEST",
          "expiresAt": "2027-05-25T00:00:00+07:00", "reason": "Chạy song song Hub cũ trong giai đoạn chuyển bên nhận."},
  "086": {"suspendSource": "CIRCUIT_BREAKER", "suspendReason": "Tỷ lệ lỗi ≥ 50% liên tục 30 phút."},
  "108": {"params": {"10.push.max-retries": 10, "10.lag.warn-seconds": 600}, "reason": "Điều chỉnh theo kết quả vận hành tháng 11/2026."},
  "107": {"maxProjects": 200, "maxTopics": 500, "maxPartitionsTotal": 3000, "produceBytesPerSecond": 10485760, "consumeBytesPerSecond": 20971520,
          "maxRetentionHours": 720, "maxSubscriptions": 2000, "maxPushWorkersTotal": 400, "reason": "Phân bổ theo hợp đồng dịch vụ năm 2027 của tỉnh."},
  "075m": {"sourceKind": "PULSAR_HUB", "rewriteTenantPrefix": False, "defaultProjectCode": "di-tru-hub"},
}
REQ["079b"] = [REQ["079"], dict(REQ["079"], id="01JD3Y8K2M9P3Q7R4T6V8W0Y30", subject="0312345679", data={"maDoanhNghiep": "0312345679", "loaiThayDoi": "CAP_MOI", "phienBan": 1})]

RESP = {
  "007": {"overlay": "LAG", "generatedAt": TS0,
          "nodes": [{"id": "pub:ht-dkkd", "kind": "PUBLISHER", "code": "ht-dkkd", "label": "Hệ thống đăng ký kinh doanh", "status": "ACTIVE", "partyType": "SYSTEM", "systemCode": "HT-DKKD"},
                    {"id": f"topic:{TOPIC}", "kind": "TOPIC", "code": TOPIC, "label": "Doanh nghiệp đã cấp phép", "status": "ACTIVE", "dlqNewCount": 1},
                    {"id": "sub:ht-thue", "kind": "SUBSCRIBER", "code": "ht-thue", "label": "Hệ thống quản lý thuế", "status": "ACTIVE", "partyType": "SYSTEM", "systemCode": "HT-THUE"},
                    {"id": "sub:dkkd-dong-bo-thue", "kind": "SUBSCRIBER", "code": "dkkd-dong-bo-thue", "label": "Luồng đồng bộ DKKD sang thuế", "status": "ACTIVE", "partyType": "FLOW"}],
          "edges": [{"from": "pub:ht-dkkd", "to": f"topic:{TOPIC}", "kind": "PUBLICATION", "code": "pub-01jd3y8k2m9p3q7r4t6v8w0y2z", "status": "ACTIVE", "ratePerMinute": 120.0},
                    {"from": f"topic:{TOPIC}", "to": "sub:ht-thue", "kind": "SUBSCRIPTION", "code": "ht-thue-dn-cap-phep", "status": "ACTIVE", "deliveryMode": "PUSH", "alertState": "OK", "lagSeconds": 18},
                    {"from": f"topic:{TOPIC}", "to": "sub:dkkd-dong-bo-thue", "kind": "SUBSCRIPTION", "code": "dkkd-dong-bo-thue-dn-cap-phep", "status": "ACTIVE", "deliveryMode": "INTERNAL", "alertState": "OK", "lagSeconds": 0}]},
  "079": {"results": [{"id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "partition": 2, "offset": 182312, "schemaVersion": 3}]},
  "080": {"events": [dict(REQ["079"], dataschema=FIELD["dataschema"], traceparent=FIELD["traceparent"], dhtenant="T68")],
          "cursor": FIELD["cursor"], "leaseExpiresAt": "2026-11-26T09:16:02+07:00"},
  "071": {"items": [{"flowCode": "dkkd-dong-bo-thue", "topicName": TOPIC, "action": "SUBSCRIBE", "result": "ALLOWED", "reason": None,
                     "consumerGroup": "dh-flow-t68-dkkd-dong-bo-thue", "publicationCode": None, "subscriptionCode": "dkkd-dong-bo-thue-dn-cap-phep"},
                    {"flowCode": "dkkd-dong-bo-thue", "topicName": "t68.thue.ma-so-thue.da-cap.v1", "action": "PUBLISH", "result": "DENIED", "reason": "NO_GRANT",
                     "consumerGroup": None, "publicationCode": None, "subscriptionCode": None}]},
  "084": {"type": "record", "name": "DoanhNghiepDaCapPhep", "namespace": "vn.t68.dkkd",
          "fields": [{"name": "maDoanhNghiep", "type": "string"}, {"name": "loaiThayDoi", "type": "string"}, {"name": "phienBan", "type": "int"}]},
}

MANIFEST = ("apiVersion: event.datahub.vn/v1\nkind: EventManifest\nmetadata:\n  tenant: T68\n  exportedAt: 2026-11-26T09:15:02+07:00\n"
            "projects:\n  - projectCode: dang-ky-kinh-doanh\n    name: Đăng ký kinh doanh\ntopics:\n  - topicName: " + TOPIC + "\n    partitions: 6\n"
            "    retentionHours: 168\n    routingMode: KEY_HASH\n    partitionKeyField: maDoanhNghiep\n    dataClass: INTERNAL\n")

def request(code, schema_name):
    if code in REQ: return copy.deepcopy(REQ[code])
    return gen({"$ref": "#/components/schemas/" + schema_name}, full=False)

def response(code, schema_name):
    if code in RESP: return copy.deepcopy(RESP[code])
    if schema_name is None: return {}
    v = gen({"$ref": "#/components/schemas/" + schema_name}, full=True)
    if code == "009m" and isinstance(v, dict):
        v.update({"topicName": "t68.cdc.qldd-oracle.qldd.thua-dat.v1", "topicKind": "CDC", "projectCode": "cdc-qldd-oracle", "domain": "cdc",
                  "entity": "qldd-oracle", "eventName": "thua-dat", "status": "PROVISIONING", "ownerServiceCode": "dh-cdc",
                  "sourceRef": {"adapterCode": "qldd-oracle", "table": "QLDD.THUA_DAT"}, "partitionKeyField": "ID_THUA"})
    return v
