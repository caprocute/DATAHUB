#!/usr/bin/env python3
"""Sinh ph12/asyncapi-iam.yaml (AsyncAPI 3.0) cho EVT-12-01…16. Không sửa tay YAML."""
import os, yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: {"$ref": f"#/components/schemas/{n}"}
S = lambda **kw: {"type": "string", **kw}
I = {"type": "integer"}
B = {"type": "boolean"}
TS = S(format="date-time")
NTS = {"type": ["string", "null"], "format": "date-time"}
A = lambda it: {"type": "array", "items": it}
def obj(props, req=()):
    d = {"type": "object", "properties": props}
    if req: d["required"] = list(req)
    return d
TEN = S(pattern="^(T[0-9]{2}|PLATFORM)$")
UID = S(format="uuid")
ACR = {"type": "integer", "enum": [1, 2, 3]}
USER_STATE = S(enum=["PENDING_ACTIVATION", "ACTIVE", "LOCKED", "BLOCKED", "DISABLED"])
CLIENT_STATE = S(enum=["ENABLED", "SUSPENDED", "REVOKED"])
GRANT_STATE = S(enum=["REQUESTED", "ACTIVE", "REJECTED", "CANCELLED", "EXPIRED", "REVOKED"])
SOD_STATE = S(enum=["REQUESTED", "ACTIVE", "REJECTED", "CANCELLED", "EXPIRED", "REVOKED"])
REALM_STATE = S(enum=["PROVISIONING", "ACTIVE", "SUSPENDED", "READ_ONLY", "DELETED"])
VER = {"type": "integer", "description": "Số phiên bản đối tượng; người nhận bỏ qua sự kiện có số thấp hơn trạng thái đang giữ."}

SCHEMAS = {
  "Actor": obj({"id": S(), "type": S(enum=["USER", "SERVICE", "SYSTEM"])}, ["id", "type"]),
  "UserCreated": obj({"tenantId": TEN, "userId": UID, "username": S(), "orgCode": S(), "authSource": S(enum=["LOCAL", "LDAP", "VNEID"]),
        "state": USER_STATE, "origin": S(enum=["CONSOLE", "IMPORT", "LDAP_SYNC", "SAGA"]), "actor": R("Actor"), "version": VER, "occurredAt": TS},
        ["tenantId", "userId", "username", "orgCode", "state", "version"]),
  "UserStateChanged": obj({"tenantId": TEN, "userId": UID, "from": USER_STATE, "to": USER_STATE, "orgCode": S(), "previousOrgCode": {"type": ["string", "null"]},
        "reason": S(maxLength=500), "actor": R("Actor"), "version": VER, "occurredAt": TS}, ["tenantId", "userId", "to", "version"]),
  "UserRoleChanged": obj({"tenantId": TEN, "userId": UID, "change": S(enum=["ASSIGNED", "REMOVED", "SCOPE_CHANGED", "EXPIRED"]), "assignmentId": UID, "roleCode": S(),
        "scopeType": S(enum=["TENANT", "ORG", "WORKSPACE"]), "scopeRef": {"type": ["string", "null"]}, "validTo": NTS, "sodExceptionId": {"type": ["string", "null"], "format": "uuid"},
        "actor": R("Actor"), "version": VER, "occurredAt": TS}, ["tenantId", "userId", "change", "roleCode", "scopeType", "version"]),
  "UserCredentialChanged": obj({"tenantId": TEN, "userId": UID, "kind": S(enum=["PASSWORD", "TOTP", "WEBAUTHN", "VNEID"]),
        "change": S(enum=["SET", "REGISTERED", "REMOVED", "RESET", "LINKED", "UNLINKED"]), "actor": R("Actor"), "version": VER, "occurredAt": TS},
        ["tenantId", "userId", "kind", "change", "version"]),
  "AccessRevoked": obj({"tenantId": TEN, "revocationId": UID, "kind": S(enum=["SUB", "CLIENT", "JTI", "SESSION"]), "subject": S(), "notBefore": TS, "expiresAt": TS,
        "blockAll": {"type": "boolean", "description": "`true` tới khi Keycloak xác nhận đã vô hiệu (SEC-25)."}, "reason": S(maxLength=500), "actor": R("Actor"), "feedVersion": I},
        ["tenantId", "revocationId", "kind", "subject", "notBefore", "expiresAt"]),
  "ClientProvisioned": obj({"tenantId": TEN, "clientId": S(), "systemCode": S(), "orgCode": S(), "authMethod": S(enum=["TLS_CLIENT_AUTH", "PRIVATE_KEY_JWT", "CLIENT_SECRET"]),
        "contractLevel": S(enum=["PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE"]), "scopeCount": I, "certThumbprint": S(), "actor": R("Actor"), "version": VER, "occurredAt": TS},
        ["tenantId", "clientId", "systemCode", "authMethod", "contractLevel", "version"]),
  "ClientStateChanged": obj({"tenantId": TEN, "clientId": S(), "from": CLIENT_STATE, "to": CLIENT_STATE, "reason": S(maxLength=500), "automatic": B,
        "actor": R("Actor"), "version": VER, "occurredAt": TS}, ["tenantId", "clientId", "to", "version"]),
  "ClientCredentialChanged": obj({"tenantId": TEN, "ownerKind": S(enum=["CLIENT", "SERVICE_ACCOUNT"]), "ownerId": S(), "change": S(enum=["CERTIFICATE", "JWKS", "SECRET", "SCOPES"]),
        "thumbprint": S(description="Dấu vân tay chứng thư hoặc `kid`; không có giá trị bí mật."), "scopesRevision": I, "overlapUntil": NTS, "actor": R("Actor"), "version": VER, "occurredAt": TS},
        ["tenantId", "ownerKind", "ownerId", "change", "version"]),
  "PolicyPublished": obj({"tenantId": TEN, "policyCode": S(), "versionNo": I, "scope": S(enum=["PLATFORM", "TENANT"]), "contentHash": S(), "bundleRevision": S(), "dataRevision": S(),
        "approvedBy": S(), "submittedBy": S(), "actor": R("Actor"), "occurredAt": TS}, ["tenantId", "bundleRevision"]),
  "PolicyRevoked": obj({"tenantId": TEN, "policyCode": S(), "versionNo": I, "kind": S(enum=["REVOKED", "ROLLED_BACK"]), "bundleRevision": S(), "previousBundleRevision": S(),
        "reason": S(maxLength=1000), "actor": R("Actor"), "occurredAt": TS}, ["tenantId", "kind", "bundleRevision"]),
  "GrantStateChanged": obj({"tenantId": TEN, "grantId": UID, "type": S(enum=["TENANT_ACCESS", "PRIVILEGE"]), "requesterId": UID, "homeTenant": TEN, "targetTenant": TEN, "roleCode": S(),
        "from": GRANT_STATE, "to": GRANT_STATE, "ticketRef": S(), "expiresAt": NTS, "actor": R("Actor"), "version": VER, "occurredAt": TS},
        ["tenantId", "grantId", "type", "targetTenant", "to", "version"]),
  "SodExceptionChanged": obj({"tenantId": TEN, "exceptionId": UID, "userId": UID, "roleA": S(), "roleB": S(), "from": SOD_STATE, "to": SOD_STATE, "expiresAt": TS,
        "actor": R("Actor"), "version": VER, "occurredAt": TS}, ["tenantId", "exceptionId", "userId", "to", "version"]),
  "RealmChanged": obj({"tenantId": TEN, "tenantCode": TEN, "change": S(enum=["STATE", "KEY_ROTATED", "DRIFT", "SECURITY_PARAMS"]), "from": REALM_STATE, "to": REALM_STATE,
        "signingKeyId": S(), "driftStatus": S(enum=["IN_SYNC", "DRIFTED", "HELD"]), "changedParams": A(S()), "actor": R("Actor"), "occurredAt": TS}, ["tenantId", "tenantCode", "change"]),
  "AlertRaised": obj({"tenantId": TEN, "alertId": UID, "ruleCode": S(pattern="^AN-[0-9]{2}$"), "severity": S(enum=["LOW", "MEDIUM", "HIGH", "CRITICAL"]), "subject": S(),
        "summary": S(maxLength=500), "raisedAt": TS}, ["tenantId", "alertId", "ruleCode", "severity", "raisedAt"]),
  "RecertCompleted": obj({"tenantId": TEN, "campaignId": UID, "scopeType": S(), "scopeRef": {"type": ["string", "null"]},
        "total": I, "kept": I, "removed": I, "escalated": I, "closedAt": TS, "actor": R("Actor")}, ["tenantId", "campaignId", "total", "closedAt"]),
  "AuthEventRecorded": obj({"tenantId": TEN, "eventId": UID, "type": S(enum=["LOGIN_SUCCESS", "LOGIN_FAILURE", "LOGOUT", "TOKEN_ISSUED", "TOKEN_REFRESHED", "TOKEN_REFRESH_REUSE", "STEPUP", "MFA_REGISTERED", "ACCOUNT_LOCKED"]),
        "userId": {"type": ["string", "null"]}, "clientId": {"type": ["string", "null"]}, "result": S(enum=["SUCCESS", "FAILURE"]), "errorCode": {"type": ["string", "null"], "pattern": "^ERR-12-[0-9]{3}$"},
        "ip": S(), "acr": ACR, "time": TS}, ["tenantId", "eventId", "type", "result", "time"]),
}

CE_HEADERS = obj({"ce_specversion": S(const="1.0"), "ce_id": S(format="uuid"), "ce_source": S(description="`/tenants/{tenant}/iam`"),
    "ce_type": S(description="`vn.datahub.iam.{đối tượng}.{sự kiện}.v1`"), "ce_time": TS, "ce_subject": S(description="Mã đối tượng chính."),
    "ce_datacontenttype": S(const="application/json"), "dhtenant": S(description="Phải khớp tiền tố topic; không khớp chuyển DLQ (D03-10 §3)."), "traceparent": S()},
    ["ce_specversion", "ce_id", "ce_source", "ce_type", "ce_time", "dhtenant"])

# key, mã, địa chỉ, payload, tóm tắt, ngày giữ, phân vùng, người phát, khóa, người nhận
EV = [
  ("userCreated", "EVT-12-01", "{tenant}.iam.user.created.v1", "UserCreated", "Tài khoản được tạo hoặc nhập (FR-12-003, 009, 026).", 7, 3, "outbox", "`userId`", "PH-13, bản chiếu `ph12_iam`"),
  ("userStateChanged", "EVT-12-02", "{tenant}.iam.user.state-changed.v1", "UserStateChanged", "Tài khoản đổi trạng thái hoặc đơn vị (FR-12-004, 005, 006, 008).", 7, 3, "outbox", "`userId`", "PH-13, bản chiếu `ph12_iam`"),
  ("userRoleChanged", "EVT-12-03", "{tenant}.iam.user.role-changed.v1", "UserRoleChanged", "Gán, gỡ vai trò, đổi phạm vi hoặc hạn (FR-12-012, 013).", 7, 3, "outbox", "`userId`", "Bộ ghi chính sách (FR-12-051), PH-13"),
  ("userCredentialChanged", "EVT-12-04", "{tenant}.iam.user.credential-changed.v1", "UserCredentialChanged", "Đổi mật khẩu, đăng ký hoặc đặt lại yếu tố thứ hai, liên kết VNeID. Không có giá trị bí mật.", 7, 3, "outbox", "`userId`", "PH-13"),
  ("accessRevoked", "EVT-12-05", "{tenant}.iam.access.revoked.v1", "AccessRevoked", "Thu hồi truy cập tức thời (FR-12-040); DU nhận ngay, APISIX kéo qua API-12-079.", 7, 3, "outbox", "`tenantCode`", "DU qua thư viện PEP, PH-13"),
  ("clientProvisioned", "EVT-12-06", "{tenant}.iam.client.provisioned.v1", "ClientProvisioned", "Client được cấp (FR-12-030, 032).", 7, 3, "outbox", "`clientId`", "PH-01, PH-03, PH-13"),
  ("clientStateChanged", "EVT-12-07", "{tenant}.iam.client.state-changed.v1", "ClientStateChanged", "Client tạm ngừng, tiếp tục, thu hồi (FR-12-008, 031).", 7, 3, "outbox", "`clientId`", "PH-01, PH-03, PH-13"),
  ("clientCredentialChanged", "EVT-12-08", "{tenant}.iam.client.credential-changed.v1", "ClientCredentialChanged", "Chứng thư, khóa, bí mật, scope của client hoặc tài khoản dịch vụ đổi (FR-12-033, 034, 036, 037).", 7, 3, "outbox", "`clientId` hoặc `accountCode`", "PH-03 (dấu vân tay), bộ ghi chính sách, PH-13"),
  ("policyPublished", "EVT-12-09", "{tenant}.iam.policy.published.v1", "PolicyPublished", "Phiên bản chính sách hoặc gói dữ liệu mới có hiệu lực (FR-12-051, 054).", 7, 3, "outbox", "`policyCode`", "DU (xóa bộ đệm), PH-13"),
  ("policyRevoked", "EVT-12-10", "{tenant}.iam.policy.revoked.v1", "PolicyRevoked", "Chính sách bị thu hồi hoặc gói bị quay lui (FR-12-055).", 7, 3, "outbox", "`policyCode`", "DU, PH-13"),
  ("grantStateChanged", "EVT-12-11", "{tenant}.iam.grant.state-changed.v1", "GrantStateChanged", "Quyền có thời hạn đổi trạng thái (FR-12-017). Phát ở tenant bị truy cập.", 7, 3, "outbox", "`grantId`", "PH-13, thông báo quản trị tỉnh bị truy cập"),
  ("sodExceptionChanged", "EVT-12-12", "{tenant}.iam.sod.exception-changed.v1", "SodExceptionChanged", "Ngoại lệ tách nhiệm vụ đổi trạng thái (FR-12-013).", 7, 3, "outbox", "`exceptionId`", "PH-13"),
  ("realmChanged", "EVT-12-13", "{tenant}.iam.realm.changed.v1", "RealmChanged", "Realm đổi trạng thái, xoay khóa ký, lệch cấu hình, đổi tham số bảo mật (FR-12-039, 041, 042, 043).", 7, 3, "outbox", "`tenantCode`", "PH-20, PH-13"),
  ("alertRaised", "EVT-12-14", "{tenant}.iam.alert.raised.v1", "AlertRaised", "Cảnh báo an ninh mới (FR-12-059).", 7, 3, "outbox", "`alertId`", "PH-13, kênh thông báo của SO"),
  ("recertCompleted", "EVT-12-15", "{tenant}.iam.recert.completed.v1", "RecertCompleted", "Chiến dịch rà soát quyền đóng (FR-12-018).", 7, 3, "outbox", "`tenantCode`", "PH-13"),
  ("authEventRecorded", "EVT-12-16", "{tenant}.iam.auth.event-recorded.v1", "AuthEventRecorded", "Sự kiện xác thực (đăng nhập, lỗi, đăng xuất, cấp token, làm mới) do Keycloak phát trực tiếp, không qua outbox (FR-12-056).", 3, 6, "keycloak", "`userId` hoặc `clientId`", "PH-13, bộ phát hiện bất thường"),
]

def build():
    channels, ops, msgs = {}, {}, {}
    for key, code, addr, payload, summ, days, parts, src, kdesc, recv in EV:
        ch = {"address": addr, "title": code, "description": summ, "messages": {key: {"$ref": f"#/components/messages/{key}"}},
              "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
              "bindings": {"kafka": {"topic": addr, "partitions": parts, "replicas": 3,
                  "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": days * 86400000}}}}
        channels[key] = ch
        sender = "dh-platform (module iam, outbox)" if src == "outbox" else "Keycloak (bộ lắng nghe `dh-keycloak-spi`, producer idempotent)"
        cap = key[0].upper() + key[1:]
        ops[f"send{cap}"] = {"action": "send", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{code} — {sender} phát",
            "messages": [{"$ref": f"#/channels/{key}/messages/{key}"}]}
        ops[f"receive{cap}"] = {"action": "receive", "channel": {"$ref": f"#/channels/{key}"}, "title": f"{recv} nhận"}
        msgs[key] = {"name": key, "title": code, "summary": summ, "payload": R(payload),
            "headers": CE_HEADERS if src == "outbox" else obj({"traceparent": S(), "ce_id": S(format="uuid"), "dhtenant": S()}, ["dhtenant"]),
            "bindings": {"kafka": {"key": S(description=kdesc)}}}
    return {
      "asyncapi": "3.0.0",
      "info": {"title": "Datahub PH-12 Định danh và phân quyền — sự kiện", "version": "1.0.0-draft",
        "description": ("Hợp đồng sự kiện EVT-12-01…16 (D03-04-PH12 §4, FRS §9.3).\n\n"
          "EVT-12-01…15 ghi vào `ph12_iam.outbox` cùng giao dịch với thay đổi trạng thái (ADR-042), Debezium outbox router đưa lên Kafka, CloudEvents 1.0 chế độ nhị phân. "
          "EVT-12-16 do Keycloak phát trực tiếp (không có giao dịch control plane). Tenant `PLATFORM` dùng tiền tố `platform`. "
          "Không sự kiện nào mang mật khẩu, bí mật client, khóa riêng hay mã bọc (ràng buộc `ck_outbox_no_secret`, kiểm thử canary). "
          "Người nhận xử lý lũy đẳng theo `ce_id`, bỏ qua sự kiện có `version` thấp hơn. Nhật ký quyết định ủy quyền không đi qua các topic này mà theo đường log (FR-12-057). "
          "Tương thích: BACKWARD ở Apicurio, chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`."),
        "license": {"name": "Tài liệu nội bộ dự án Datahub"}},
      "defaultContentType": "application/json",
      "servers": {"kafka-cum": {"host": "kafka-bootstrap.dh-platform.svc:9093", "protocol": "kafka-secure",
          "description": "Kafka (Strimzi) của cụm; mTLS, ACL theo principal và tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
      "channels": channels, "operations": ops,
      "components": {"parameters": {"tenant": {"description": "Mã tenant chữ thường (`t68`) hoặc `platform`.", "examples": ["t68"]}},
        "securitySchemes": {"mtls": {"type": "X509", "description": "Chứng thư do cert-manager cấp; ACL Kafka theo CN."}},
        "messages": msgs, "schemas": SCHEMAS}}

if __name__ == "__main__":
    out = os.path.join(ROOT, "asyncapi-iam.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH12 · AsyncAPI PH-12. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(build(), f, allow_unicode=True, sort_keys=False, width=140)
    print(f"{len(EV)} kênh → {out}")
