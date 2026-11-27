#!/usr/bin/env python3
"""Sinh ph01/asyncapi-onboarding.yaml (AsyncAPI 3.0) cho EVT-01-01…15. Không sửa tay YAML.

Nguồn: D02-03-PH01 §9.3 (mã, topic, bên tiêu thụ), D03-03-PH01 §6.2 (phân vùng, thời hạn giữ, khóa), D03-02-PH01 §4.11 (outbox).
"""
import os, yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
TS = S(format="date-time")
NTS = {"type": ["string", "null"], "format": "date-time"}
A = lambda it, **kw: {"type": "array", "items": it, **kw}


def obj(props, req=()):
    d = {"type": "object", "properties": props}
    if req:
        d["required"] = list(req)
    return d


TEN = S(pattern="^(T[0-9]{2}|COMMON)$", description="Mã tenant, ví dụ `T68`.")
SYS = S(maxLength=64, pattern="^[A-Z][A-Z0-9-]{2,63}$", description="Mã HTTT.")
STATUS = S(enum=["DRAFT", "SUBMITTED", "APPROVED", "ACTIVE", "SUSPENDED", "TERMINATED", "REJECTED"])
ENV = S(enum=["SANDBOX", "PRODUCTION"])
AUTH = S(enum=["CLIENT_SECRET", "PRIVATE_KEY_JWT", "MTLS", "API_KEY"])
STEP = S(enum=["TECHNICAL", "LEGAL", "SECURITY"])
LEVEL = S(enum=["L1", "L2", "L3", "L4", "L5"])
CLS = S(enum=["PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE"])
ACTOR = {"oneOf": [obj({"userId": S(), "type": S(enum=["USER", "SYSTEM"])}, ["userId", "type"]), {"type": "null"}]}

SCHEMAS = {
  "Actor": obj({"userId": S(), "type": S(enum=["USER", "SYSTEM"])}, ["userId", "type"]),
  "SystemSubmitted": obj({"tenantId": TEN, "systemCode": SYS, "applicationNo": S(), "ownerOrgId": S(), "revisionNo": {"type": "integer", "minimum": 1},
        "resubmitted": B, "submittedBy": S(), "submittedAt": TS,
        "steps": A(obj({"stepType": STEP, "dueAt": TS}, ["stepType", "dueAt"]))},
        ["tenantId", "systemCode", "applicationNo", "revisionNo", "submittedAt", "steps"]),
  "ReviewDecided": obj({"tenantId": TEN, "systemCode": SYS, "applicationNo": S(), "revisionNo": I,
        "kind": S(enum=["STEP_DONE", "ASSIGNED", "CONSULTED", "RESUMED", "RETURNED", "APPROVED", "REJECTED"]),
        "stepType": {"oneOf": [STEP, {"type": "null"}]}, "result": {"oneOf": [S(enum=["PASS", "FAIL"]), {"type": "null"}]},
        "assigneeId": {"type": ["string", "null"]}, "actor": R("Actor"), "at": TS},
        ["tenantId", "systemCode", "kind", "actor", "at"]),
  "SystemStateChanged": obj({"tenantId": TEN, "systemCode": SYS, "name": S(), "ownerOrgId": S(), "from": {"oneOf": [STATUS, {"type": "null"}]}, "to": STATUS,
        "reviewStage": {"type": ["string", "null"]}, "provisionStage": {"type": ["string", "null"]}, "reasonCode": {"type": ["string", "null"]},
        "reason": {"type": ["string", "null"], "maxLength": 1000}, "emergency": B, "snapshot": B,
        "roles": A(S(enum=["CONSUMER", "PROVIDER", "PUBLISHER", "SUBSCRIBER"])), "securityLevel": LEVEL, "group": {"type": ["integer", "null"]},
        "ceilingDataTypes": A(S(), description="Để bên nhận phát hiện lệch với EVT-01-11."), "version": I, "updatedAt": TS,
        "actor": {"oneOf": [R("Actor"), {"type": "null"}]}},
        ["tenantId", "systemCode", "to", "snapshot", "version", "updatedAt"]),
  "SystemUpdated": obj({"tenantId": TEN, "systemCode": SYS, "changedFields": A(S(enum=["securityLevel", "baseUrls", "ipAllowlist", "ownerOrgId", "roles", "name"]), minItems=1),
        "securityLevel": LEVEL, "ownerOrgId": S(), "roles": A(S()), "baseUrls": A(S(format="uri")),
        "ipAllowlist": {"type": ["array", "null"], "items": S(), "description": "Danh sách CIDR đầy đủ khi `ipAllowlist` nằm trong `changedFields`."},
        "version": I, "updatedAt": TS, "actor": R("Actor")},
        ["tenantId", "systemCode", "changedFields", "version", "updatedAt"]),
  "CredentialIssued": obj({"tenantId": TEN, "systemCode": SYS, "credentialId": S(), "environment": ENV, "authMethod": AUTH, "clientId": S(),
        "expiresAt": TS, "issuedAt": TS, "actor": R("Actor")}, ["tenantId", "systemCode", "credentialId", "environment", "authMethod", "clientId", "issuedAt"]),
  "CredentialRotated": obj({"tenantId": TEN, "systemCode": SYS, "credentialId": S(), "environment": ENV, "phase": S(enum=["STARTED", "FINISHED", "KEY_REGISTERED"]),
        "rotationEndsAt": NTS, "kid": {"type": ["string", "null"]}, "certFingerprint": {"type": ["string", "null"]}, "incident": B, "at": TS, "actor": R("Actor")},
        ["tenantId", "systemCode", "credentialId", "environment", "phase", "at"]),
  "CredentialRevoked": obj({"tenantId": TEN, "systemCode": SYS, "credentialId": S(), "environment": ENV, "to": S(enum=["REVOKED", "EXPIRED", "DISABLED"]),
        "reason": S(enum=["MANUAL", "SYSTEM_SUSPENDED", "SYSTEM_TERMINATED", "EMERGENCY", "EXPIRED", "INACTIVE", "ROTATION_FORCED"]),
        "reversible": B, "at": TS, "actor": R("Actor")}, ["tenantId", "systemCode", "credentialId", "environment", "to", "reason", "reversible", "at"]),
  "CredentialExpiring": obj({"tenantId": TEN, "systemCode": SYS, "credentialId": S(), "environment": ENV, "expiresAt": TS,
        "daysLeft": {"type": "integer", "enum": [30, 14, 7]}}, ["tenantId", "systemCode", "credentialId", "expiresAt", "daysLeft"]),
  "HandoverOpened": obj({"tenantId": TEN, "systemCode": SYS, "credentialId": S(), "handoverId": S(format="uuid"), "openedBy": S(), "openedAt": TS},
        ["tenantId", "systemCode", "handoverId", "openedBy", "openedAt"]),
  "HandoverSecurityAlert": obj({"tenantId": TEN, "systemCode": SYS, "credentialId": S(), "handoverId": S(format="uuid"),
        "alertType": S(enum=["WRONG_RECIPIENT", "REPEATED_FAILURE", "LOCKED"]), "failedAttempts": I, "attemptedBy": S(), "locked": B, "at": TS},
        ["tenantId", "systemCode", "handoverId", "alertType", "failedAttempts", "locked", "at"]),
  "ScopeCeilingChanged": obj({"tenantId": TEN, "systemCode": SYS, "change": S(enum=["CREATED", "EXPANDED", "NARROWED", "SUSPENDED", "REVOKED", "CLOSED"]),
        "ceiling": A(obj({"dataType": S(), "scopeApproved": S(maxLength=200), "classification": CLS, "validUntil": {"type": ["string", "null"], "format": "date"}},
                         ["dataType", "scopeApproved"])), "reason": {"type": ["string", "null"], "maxLength": 1000}, "version": I, "at": TS, "actor": R("Actor")},
        ["tenantId", "systemCode", "change", "ceiling", "version", "at"]),
  "AccessReviewCompleted": obj({"tenantId": TEN, "cycleCode": S(pattern="^RS-[0-9]{4}-[0-9]{2}$"), "kind": S(enum=["PERIODIC", "TOPIC"]), "itemCount": I,
        "kept": I, "narrowed": I, "revoked": I, "noResponseOrgs": I, "evidenceHash": S(pattern="^[0-9a-f]{64}$"), "closedAt": TS, "closedBy": S()},
        ["tenantId", "cycleCode", "itemCount", "evidenceHash", "closedAt"]),
  "ContactChanged": obj({"tenantId": TEN, "systemCode": SYS, "contactId": S(format="uuid"), "contactType": S(enum=["BUSINESS", "TECHNICAL", "SECURITY"]),
        "change": S(enum=["ADDED", "UPDATED", "REPLACED", "DEACTIVATED"]), "orgId": S(), "at": TS},
        ["tenantId", "systemCode", "contactType", "change", "at"]),
  "DirectoryGapDetected": obj({"tenantId": TEN, "orgId": S(), "systemCodes": A(SYS, minItems=1), "missing": S(enum=["TECHNICAL_CONTACT"]), "detectedAt": TS},
        ["tenantId", "orgId", "systemCodes", "missing", "detectedAt"]),
  "EmergencyActionRecorded": obj({"tenantId": TEN, "systemCode": SYS, "actionId": S(format="uuid"), "stage": S(enum=["PERFORMED", "CONFIRMED", "OVERDUE"]),
        "mode": S(enum=["SUSPEND", "TERMINATE"]), "performedBy": S(), "confirmBy": TS, "confirmedBy": {"type": ["string", "null"]},
        "incidentRef": {"type": ["string", "null"]}, "at": TS}, ["tenantId", "systemCode", "actionId", "stage", "mode", "performedBy", "confirmBy", "at"]),
}

CE_HEADERS = obj({"ce_specversion": S(const="1.0"), "ce_id": S(format="uuid", description="ULID/UUID duy nhất của sự kiện; bên nhận lũy đẳng theo `(systemCode, updatedAt)`."),
    "ce_source": S(description="`/tenants/{tenant}/onboarding`"), "ce_type": S(description="`vn.datahub.connect.{thực-thể}.{sự-kiện}.v1`"),
    "ce_time": TS, "ce_subject": S(description="Mã HTTT (hoặc mã kỳ, mã tổ chức)."), "ce_datacontenttype": S(const="application/json"), "traceparent": S()},
    ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time"])

T0 = "2026-11-26T09:00:00Z"
ACT = {"userId": "an.nv", "type": "USER"}
SYSACT = {"userId": "system:onboarding", "type": "SYSTEM"}
CEIL = [{"dataType": "THONG_TIN_CONG_DAN", "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC", "classification": "RESTRICTED", "validUntil": None}]
# key, mã, thực thể.sự kiện, schema, tóm tắt, khóa, bên nhận, ví dụ
EV = [
  ("systemSubmitted", "EVT-01-01", "system.submitted", "SystemSubmitted", "Hồ sơ được nộp hoặc nộp lại (FR-01-012).", "`systemCode`", "PH-13, PH-18",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "applicationNo": "KN-2026-000123", "ownerOrgId": "SO-TUPHAP", "revisionNo": 1, "resubmitted": False,
    "submittedBy": "an.nv", "submittedAt": T0, "steps": [{"stepType": "TECHNICAL", "dueAt": "2026-11-30T10:00:00Z"}, {"stepType": "SECURITY", "dueAt": "2026-11-30T10:00:00Z"}]}),
  ("reviewDecided", "EVT-01-02", "review.decided", "ReviewDecided", "Bước thẩm định hoàn tất, phân công, tham vấn, trả bổ sung, phê duyệt hoặc từ chối (FR-01-013…018).", "`systemCode`", "PH-13, PH-18",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "applicationNo": "KN-2026-000123", "revisionNo": 1, "kind": "STEP_DONE", "stepType": "TECHNICAL", "result": "PASS",
    "assigneeId": "ie.tranb", "actor": {"userId": "ie.tranb", "type": "USER"}, "at": "2026-11-27T03:00:00Z"}),
  ("systemStateChanged", "EVT-01-03", "system.state-changed", "SystemStateChanged", "Mọi chuyển trạng thái HTTT; ảnh chụp đối chiếu hằng giờ có `snapshot = true` (FR-01-037). Có hiệu lực ở bên nhận trong ≤ 60 giây (NFR-01-008).", "`systemCode`",
   "PH-10, PH-02, PH-04, PH-05, PH-03, PH-13",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "name": "Hệ thống quản lý hộ tịch", "ownerOrgId": "SO-TUPHAP", "from": "ACTIVE", "to": "SUSPENDED", "reviewStage": None,
    "provisionStage": None, "reasonCode": "OVERLOAD", "reason": "Tăng đột biến lưu lượng làm quá tải cổng", "emergency": False, "snapshot": False,
    "roles": ["CONSUMER", "PROVIDER"], "securityLevel": "L3", "group": 1, "ceilingDataTypes": ["THONG_TIN_CONG_DAN"], "version": 14, "updatedAt": "2026-12-12T02:00:00Z", "actor": ACT}),
  ("systemUpdated", "EVT-01-04", "system.updated", "SystemUpdated", "Đổi thuộc tính: cấp độ ATTT, địa chỉ, IP, chủ quản, vai trò (FR-01-034).", "`systemCode`", "PH-10, PH-04, PH-05, PH-03",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "changedFields": ["baseUrls", "ipAllowlist"], "securityLevel": "L3", "ownerOrgId": "SO-TUPHAP", "roles": ["CONSUMER", "PROVIDER"],
    "baseUrls": ["https://hotich.tinh.example.gov.vn/api/v2"], "ipAllowlist": ["10.20.0.0/24", "10.20.1.0/24"], "version": 15, "updatedAt": "2026-12-13T02:00:00Z", "actor": ACT}),
  ("credentialIssued", "EVT-01-05", "credential.issued", "CredentialIssued", "Cấp định danh SANDBOX, PRODUCTION (FR-01-020, 024). Không có `secret_ref`, không có bí mật.", "`systemCode`", "PH-03, PH-10, PH-13",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "environment": "SANDBOX", "authMethod": "PRIVATE_KEY_JWT", "clientId": "t68-ht-tuphap-sbx",
    "expiresAt": "2027-11-26T00:00:00Z", "issuedAt": "2026-11-27T04:00:20Z", "actor": SYSACT}),
  ("credentialRotated", "EVT-01-06", "credential.rotated", "CredentialRotated", "Bắt đầu, kết thúc xoay vòng; đăng ký khóa mới (FR-01-021, 025).", "`systemCode`", "PH-03, PH-10",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "environment": "PRODUCTION", "phase": "STARTED", "rotationEndsAt": "2026-12-05T00:00:00Z",
    "kid": None, "certFingerprint": None, "incident": False, "at": "2026-11-28T04:10:00Z", "actor": ACT}),
  ("credentialRevoked", "EVT-01-07", "credential.revoked", "CredentialRevoked", "Thu hồi, hết hạn, tự vô hiệu (FR-01-026, 027, 029, 036). `reversible` cho biết có bật lại được không.", "`systemCode`", "PH-03, PH-10, PH-13",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "environment": "PRODUCTION", "to": "REVOKED", "reason": "EMERGENCY", "reversible": False,
    "at": "2026-11-29T02:00:00Z", "actor": ACT}),
  ("credentialExpiring", "EVT-01-08", "credential.expiring", "CredentialExpiring", "Còn 30, 14, 7 ngày tới hạn (FR-01-027).", "`systemCode`", "PH-13, PH-18",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "environment": "PRODUCTION", "expiresAt": "2027-01-05T00:00:00Z", "daysLeft": 30}),
  ("handoverOpened", "EVT-01-09", "handover.opened", "HandoverOpened", "Đầu mối mở liên kết bàn giao thành công (FR-01-022).", "`systemCode`", "PH-13",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0", "openedBy": "an.nv", "openedAt": "2026-11-27T05:30:00Z"}),
  ("handoverSecurityAlert", "EVT-01-10", "handover.security-alert", "HandoverSecurityAlert", "Sai người mở liên kết, mở sai nhiều lần, liên kết bị khóa (FR-01-022).", "`systemCode`", "PH-13, SO",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0", "alertType": "WRONG_RECIPIENT",
    "failedAttempts": 1, "attemptedBy": "user.khac", "locked": False, "at": "2026-11-27T05:20:00Z"}),
  ("scopeCeilingChanged", "EVT-01-11", "scope-ceiling.changed", "ScopeCeilingChanged", "Trần phạm vi tạo, mở rộng, thu hẹp, tạm ngừng, thu hồi (FR-01-018, 031, 035, 042, 043). PH-02 hủy đăng ký vượt trần rồi gọi API-12-068 thay tập scope.", "`systemCode`", "PH-02, PH-13",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "change": "CREATED", "ceiling": CEIL, "reason": None, "version": 1, "at": "2026-11-27T04:00:00Z", "actor": ACT}),
  ("accessReviewCompleted", "EVT-01-12", "access-review.completed", "AccessReviewCompleted", "Kỳ rà soát quyền đóng (FR-01-042).", "Mã kỳ `RS-…`", "PH-13, PH-18",
   {"tenantId": "T68", "cycleCode": "RS-2026-02", "kind": "PERIODIC", "itemCount": 118, "kept": 90, "narrowed": 20, "revoked": 8, "noResponseOrgs": 2,
    "evidenceHash": "4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce", "closedAt": "2026-12-20T09:00:00Z", "closedBy": "ta.lethi"}),
  ("contactChanged", "EVT-01-13", "contact.changed", "ContactChanged", "Thêm, sửa, thay thế, vô hiệu đầu mối. **Không kèm dữ liệu liên hệ cá nhân**, chỉ mã HTTT, loại, mã đầu mối (FR-01-008).", "`systemCode`", "PH-18, PH-13",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "contactType": "TECHNICAL", "change": "ADDED", "orgId": "SO-TUPHAP", "at": T0}),
  ("directoryGapDetected", "EVT-01-14", "directory.gap-detected", "DirectoryGapDetected", "Phát hiện tổ chức thiếu đầu mối kỹ thuật (FR-01-046).", "Mã tổ chức", "PH-13, PH-18",
   {"tenantId": "T68", "orgId": "UBND-XA-A", "systemCodes": ["HT-XA-A"], "missing": "TECHNICAL_CONTACT", "detectedAt": "2026-12-01T01:00:00Z"}),
  ("emergencyActionRecorded", "EVT-01-15", "emergency-action.recorded", "EmergencyActionRecorded", "Thao tác khẩn của SO, xác nhận, quá hạn xác nhận (FR-01-032). Sự kiện an ninh.", "`systemCode`", "PH-13, TA, PO",
   {"tenantId": "T68", "systemCode": "HT-TUPHAP", "actionId": "0194f2c9-6070-7266-8faa-7d8e9fa0b1c2", "stage": "PERFORMED", "mode": "SUSPEND", "performedBy": "so.phamc",
    "confirmBy": "2026-11-30T02:00:00Z", "confirmedBy": None, "incidentRef": "INC-2026-0412", "at": "2026-11-29T02:00:00Z"}),
]


def cap(k):
    return k[0].upper() + k[1:]


def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, ent, payload, summ, kdesc, recv, example in EV:
        addr = "{tenant}.connect." + ent + ".v1"
        channels[key] = {"address": addr, "title": code, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
            "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
            "bindings": {"kafka": {"topic": addr, "partitions": 3, "replicas": 3,
                "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": 7 * 86400000}}}}
        ops[f"send{cap(key)}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — dh-connect phát (outbox)",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{cap(key)}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{recv} nhận"}
        msgs[key] = {"name": key, "title": code, "summary": summ, "payload": R(payload), "headers": CE_HEADERS,
            "bindings": {"kafka": {"key": S(description=kdesc)}},
            "examples": [{"name": "Ví dụ giả lập", "payload": example}]}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-01 Kết nạp hệ thống thông tin — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-01-01…15 (D03-04-PH01 §4, D02-03-PH01 §9.3), miền `connect` của `dh-connect`.\n\n"
          "Mọi sự kiện ghi vào `ph01_onboarding.outbox` cùng giao dịch với thay đổi (ADR-042), Debezium (hoặc `OutboxRelay` ở `QM-NHO`) đưa lên Kafka, "
          "CloudEvents 1.0 chế độ nhị phân; khóa bản ghi là `systemCode` (trừ EVT-01-12 khóa mã kỳ, EVT-01-14 khóa mã tổ chức) nên mọi thay đổi của một HTTT đến đúng thứ tự. "
          "Không sự kiện nào mang giá trị bí mật, `secret_ref`, liên kết bàn giao hay dữ liệu liên hệ cá nhân (kiểm thử canary `DH-CANARY-…`, NFR-01-009). "
          "Người nhận xử lý lũy đẳng theo `(systemCode, updatedAt)` hoặc `version`, bỏ qua bản cũ hơn bản đang giữ. Tương thích: chỉ thêm trường tùy chọn trong `v1`.\n\n"
          "PH-01 cũng tiêu thụ ba loại sự kiện của phân hệ khác (tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức của PH-12, thư bị trả lại của PH-18, tenant tạm ngừng của PH-20); "
          "tên topic của chúng do phân hệ phát chốt ở D03-04 của phân hệ đó (Q01-13) nên chưa có kênh `receive` ở tệp này. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`).", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}


if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-onboarding.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH01 · AsyncAPI PH-01. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(EV)} kênh → {out}")
