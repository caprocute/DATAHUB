#!/usr/bin/env python3
"""Sinh ph12/openapi-iam.yaml (OpenAPI 3.1) từ spec.OPS và lược đồ trong tệp này.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph12)
YAML sinh ra là hợp đồng; sửa spec.py hoặc tệp này rồi sinh lại, không sửa tay YAML.
Mã lỗi và HTTP đọc từ FRS §9.1 để không lệch.
"""
import os, re, sys, glob, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = glob.glob(os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH12-*.md"))[0]
ERRS = {c: (int(h), m.strip()) for c, h, m in re.findall(r"^\| (ERR-12-\d{3}) \| (\d{3}) \| ([^|]+) \|$", open(FRS, encoding="utf-8").read(), re.M)}

R = lambda n: {"$ref": f"#/components/schemas/{n}"}
P = lambda n: {"$ref": f"#/components/parameters/{n}"}
def s(t, **kw):
    d = {"type": t}; d.update(kw); return d
def obj(props, req=(), desc=None, **kw):
    d = {"type": "object", "properties": props, "additionalProperties": False}
    if req: d["required"] = list(req)
    if desc: d["description"] = desc
    d.update(kw); return d
def arr(items, **kw):
    d = {"type": "array", "items": items}; d.update(kw); return d
def enum(*v, desc=None):
    d = {"type": "string", "enum": list(v)}
    if desc: d["description"] = desc
    return d
def items(n, extra=None):
    props = {"items": arr(R(n)), "page": R("PageMeta")}
    if extra: props.update(extra)
    return obj(props, req=["items", "page"])
STR = lambda mx=None, **kw: s("string", **({"maxLength": mx} if mx else {}), **kw)
INT = lambda **kw: s("integer", **kw)
NUM = s("number"); BOOL = s("boolean")
TS = s("string", format="date-time"); DATE = s("string", format="date"); UUID = s("string", format="uuid")
NTS = {"type": ["string", "null"], "format": "date-time"}
ANYOBJ = {"type": "object", "additionalProperties": True}
CNT = {"type": "object", "additionalProperties": INT()}
CODE = lambda mx=63: STR(mx, pattern="^[a-z0-9][a-z0-9._-]{1,%d}$" % (mx - 1))
REASON = lambda lo=10, hi=500: STR(hi, minLength=lo, description=f"Lý do {lo}…{hi} ký tự (ERR-12-014 khi thiếu).")
AUDIT = {"createdAt": TS, "createdBy": STR(64), "updatedAt": TS, "version": INT(description="Số phiên bản đối tượng, trùng `ETag`.")}
ALLOWED = {"allowedActions": arr(STR(), description="Hành động người gọi được làm ngay (giao diện bật, tắt nút đúng như máy chủ sẽ kiểm)."),
           "disabledReasons": {"type": "object", "additionalProperties": STR(), "description": "Hành động có quyền nhưng trạng thái chưa cho phép → lý do tiếng Việt."}}
def ent(props, req=()):
    return obj({**props, **AUDIT, **ALLOWED}, req=req)
def sc_state(name, *v): return {name: enum(*v)}

CLS = enum("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE", desc="Mức phân loại dữ liệu: Công khai, Nội bộ, Hạn chế, Nhạy cảm.")
SCOPE_TYPE = enum("TENANT", "ORG", "WORKSPACE")
ACR = {"type": "integer", "enum": [1, 2, 3], "description": "Mức xác thực (FRS §4.8)."}

SCHEMAS = {
  # ---- chung
  "TenantCode": STR(16, pattern="^(T[0-9]{2}|PLATFORM)$", description="Mã tenant; `PLATFORM` là tenant nền tảng."),
  "PageMeta": obj({"page": INT(minimum=1), "size": INT(minimum=1, maximum=100), "totalElements": INT(), "totalPages": INT()}, req=["page", "size", "totalElements"]),
  "StateChangeRequest": obj({"reason": REASON(), "incidentRef": STR(64)}, req=["reason"]),
  "DecisionComment": obj({"comment": STR(2000)}),
  "RejectRequest": obj({"reason": REASON()}, req=["reason"]),
  "Accepted": obj({"taskId": UUID, "status": enum("PENDING", "RUNNING", "DONE", "FAILED"), "statusUrl": STR(512), "estimatedSeconds": INT()}, req=["taskId", "status"],
                  desc="Phản hồi 202: tác vụ chạy nền; theo dõi bằng `Location` hoặc sự kiện."),
  "ProblemDetails": {
      "type": "object", "description": "RFC 9457 (`application/problem+json`), mở rộng theo D03-04-PH12 §1.",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {
          "type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(), "instance": STR(),
          "code": STR(pattern="^ERR-12-[0-9]{3}$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(obj({"field": STR(), "rule": STR(), "message": STR(), "max": INT(), "min": INT()}, req=["field"])),
          "conflictingRoles": arr(STR(), description="Kèm ERR-12-009: hai vai trò xung đột."),
          "currentVersion": INT(description="Kèm ERR-12-044."),
          "retryAfterSeconds": INT(description="Kèm ERR-12-037, ERR-12-125.")},
      "additionalProperties": True,
      "examples": [{"type": "https://datahub.gov.vn/errors/ERR-12-009", "title": "Cặp vai trò xung đột tách nhiệm vụ", "status": 409,
                    "detail": "Không được giữ cùng lúc INTEGRATION_ENGINEER và INTEGRATION_APPROVER.", "code": "ERR-12-009",
                    "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "conflictingRoles": ["INTEGRATION_ENGINEER", "INTEGRATION_APPROVER"]}]},
  "OAuthError": obj({"error": enum("invalid_request", "invalid_grant", "invalid_client", "unauthorized_client", "unsupported_grant_type", "invalid_scope",
                                    "access_denied", "insufficient_user_authentication", "temporarily_unavailable", "invalid_token"),
                     "error_description": STR(500), "error_uri": STR(format="uri")}, req=["error"],
                    desc="RFC 6749 §5.2 cho điểm cuối OIDC của Keycloak; mã `ERR-12-1xx` tương ứng chỉ ghi vào nhật ký (FRS §9.1)."),
  # ---- người dùng
  "UserState": enum("PENDING_ACTIVATION", "ACTIVE", "LOCKED", "BLOCKED", "DISABLED"),
  "AuthSource": enum("LOCAL", "LDAP", "VNEID"),
  "RoleAssignmentBrief": obj({"assignmentId": UUID, "roleCode": STR(64), "scopeType": SCOPE_TYPE, "scopeRef": STR(64), "validFrom": TS, "validTo": NTS,
                              "effective": BOOL}, req=["assignmentId", "roleCode", "scopeType"]),
  "FactorInfo": obj({"type": enum("TOTP", "WEBAUTHN"), "label": STR(100), "registeredAt": TS, "lastUsedAt": NTS}, req=["type"],
                    desc="Chỉ loại và nhãn; không bao giờ có bí mật hay khóa của yếu tố."),
  "UserSummary": ent({"userId": UUID, "username": STR(64), "fullName": STR(160), "email": STR(254, format="email"), "orgCode": STR(64), "orgName": STR(255),
                      "state": R("UserState"), "authSource": R("AuthSource"), "roles": arr(STR(64)), "mfaEnabled": BOOL, "lastLoginAt": NTS},
                     req=["userId", "username", "fullName", "state"]),
  "UserPage": items("UserSummary", {"facets": obj({"state": CNT, "orgCode": CNT, "mfaRequiredMissing": INT(), "inactivitySoon": INT()})}),
  "UserDetail": None,  # ghép từ UserSummary bên dưới (additionalProperties=false không dùng được với allOf)
  "UserCreate": obj({
      "username": STR(64, pattern="^[a-z0-9._-]{3,64}$"), "fullName": STR(160, minLength=2), "email": STR(254, format="email"), "orgCode": STR(64),
      "title": STR(120), "managerUserId": UUID, "authSource": enum("LOCAL", "LDAP"),
      "roles": arr(R("RoleAssignmentCreateInline"), maxItems=10)}, req=["username", "fullName", "email", "orgCode"],
      examples=[{"username": "nguyen.vana", "fullName": "Nguyễn Văn A", "email": "vana@sokhcn.gov.vn", "orgCode": "SKHCN", "title": "Chuyên viên",
                 "roles": [{"roleCode": "INTEGRATION_ENGINEER", "scopeType": "ORG", "scopeRef": "SKHCN"}]}]),
  "RoleAssignmentCreateInline": obj({"roleCode": STR(64), "scopeType": SCOPE_TYPE, "scopeRef": STR(64), "validTo": TS}, req=["roleCode", "scopeType"]),
  "UserUpdate": obj({"fullName": STR(160, minLength=2), "email": STR(254, format="email"), "orgCode": STR(64), "title": STR(120),
                     "managerUserId": {"type": ["string", "null"], "format": "uuid"}}, desc="Trường do LDAP quản lý trả ERR-12-047."),
  "ResetMfaRequest": obj({"reason": REASON(), "verificationMethod": enum("IN_PERSON", "VIDEO_CALL", "MANAGER_CONFIRM"),
                          "verificationNote": STR(500)}, req=["reason", "verificationMethod"]),
  "Session": obj({"sessionId": STR(64), "startedAt": TS, "lastAccessAt": TS, "ip": STR(45), "userAgent": STR(255), "acr": ACR, "clientIds": arr(STR(64))},
                 req=["sessionId", "startedAt"]),
  "SessionList": obj({"items": arr(R("Session")), "maxConcurrent": INT()}, req=["items"]),
  "UserImport": obj({"importId": UUID, "status": enum("PREVIEW", "CONFIRMED", "RUNNING", "DONE", "FAILED", "EXPIRED"),
                     "fileName": STR(255), "totalRows": INT(), "validRows": INT(), "errorRows": INT(),
                     "errors": arr(obj({"row": INT(), "field": STR(), "code": STR(pattern="^ERR-12-[0-9]{3}$"), "message": STR()}, req=["row", "code"]), maxItems=200),
                     "createdCount": INT(), "createdAt": TS, "createdBy": STR(64)}, req=["importId", "status"]),
  "UserImportFile": obj({"file": {"type": "string", "contentEncoding": "base64", "description": "CSV hoặc XLSX UTF-8, tối đa 5 MiB, `12.import.max-rows` dòng."},
                         "fileName": STR(255), "legacyRoleMap": ANYOBJ, "defaultOrgCode": STR(64)}, req=["file"],
                        desc="Gửi dạng `multipart/form-data` (một phần `file`, một phần `meta` JSON) hoặc JSON base64."),
  "UserImportCommit": obj({"skipErrorRows": BOOL, "sendActivation": BOOL}),
  # ---- vai trò, quyền
  "Permission": obj({"code": STR(64, pattern="^PERM-[0-9]{2}-[a-z-]+$"), "phase": STR(8), "description": STR(500),
                     "roles": arr(STR(64)), "kind": enum("USER", "SERVICE_SCOPE")}, req=["code", "description"]),
  "PermissionList": obj({"items": arr(R("Permission"))}, req=["items"]),
  "Role": ent({"roleCode": STR(64), "name": STR(160), "kind": enum("STANDARD", "CUSTOM"), "description": STR(1000), "permissions": arr(STR(64)),
               "scopeTypes": arr(SCOPE_TYPE), "mfaLevel": ACR, "state": enum("DRAFT", "PENDING_REVIEW", "ACTIVE", "DISABLED"), "assignedCount": INT(), "conflictsWith": arr(STR(64))},
              req=["roleCode", "name", "kind", "permissions"]),
  "RolePage": items("Role"),
  "RoleCreate": obj({"roleCode": STR(64, pattern="^[A-Z][A-Z0-9_]{2,63}$"), "name": STR(160), "description": STR(1000),
                     "permissions": arr(STR(64), minItems=1, maxItems=50), "scopeTypes": arr(SCOPE_TYPE, minItems=1)}, req=["roleCode", "name", "permissions", "scopeTypes"]),
  "RoleUpdate": obj({"name": STR(160), "description": STR(1000), "permissions": arr(STR(64), minItems=1, maxItems=50)}),
  "RoleAssignment": ent({"assignmentId": UUID, "userId": UUID, "username": STR(64), "roleCode": STR(64), "scopeType": SCOPE_TYPE, "scopeRef": STR(64),
                         "validFrom": TS, "validTo": NTS, "state": enum("ACTIVE", "EXPIRED", "REVOKED"), "reason": STR(500), "sodExceptionId": UUID},
                        req=["assignmentId", "userId", "roleCode", "scopeType", "state"]),
  "RoleAssignmentPage": items("RoleAssignment"),
  "RoleAssignmentCreate": obj({"userId": UUID, "roleCode": STR(64), "scopeType": SCOPE_TYPE, "scopeRef": STR(64), "validFrom": TS, "validTo": TS,
                               "reason": REASON(), "sodExceptionId": UUID}, req=["userId", "roleCode", "scopeType", "reason"],
                              examples=[{"userId": "0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b", "roleCode": "TENANT_ADMIN", "scopeType": "TENANT",
                                         "reason": "Bổ nhiệm quản trị tỉnh thay người nghỉ việc"}]),
  "EffectivePermissions": obj({"userId": UUID, "tenant": R("TenantCode"), "computedAt": TS, "bundleRevision": STR(64),
      "items": arr(obj({"permission": STR(64), "viaRole": STR(64), "scopeType": SCOPE_TYPE, "scopeRef": STR(64), "source": enum("ASSIGNMENT", "GROUP", "PRIVILEGED_GRANT", "SOD_EXCEPTION"),
                        "validTo": NTS}, req=["permission", "viaRole"])),
      "denied": arr(obj({"permission": STR(64), "reason": STR(500)}))}, req=["userId", "items"]),
  # ---- tách nhiệm vụ
  "SodRule": obj({"ruleId": STR(32), "roleA": STR(64), "roleB": STR(64), "reason": STR(500), "source": STR(64)}, req=["roleA", "roleB"]),
  "SodRuleList": obj({"items": arr(R("SodRule"))}, req=["items"]),
  "SodExceptionCreate": obj({"userId": UUID, "roleToAssign": STR(64), "roleToRemove": STR(64), "scopeType": SCOPE_TYPE, "scopeRef": STR(64),
                             "expiresAt": TS, "reason": REASON(20, 1000)}, req=["userId", "roleToAssign", "roleToRemove", "expiresAt", "reason"]),
  "SodException": ent({"exceptionId": UUID, "userId": UUID, "roleA": STR(64), "roleB": STR(64), "state": enum("REQUESTED", "ACTIVE", "REJECTED", "CANCELLED", "EXPIRED", "REVOKED"),
                       "requestedBy": STR(64), "decidedBy": STR(64), "decidedAt": NTS, "expiresAt": TS, "reason": STR(1000)},
                      req=["exceptionId", "userId", "state", "expiresAt"]),
  "SodDecision": obj({"decision": enum("APPROVE", "REJECT"), "comment": STR(2000)}, req=["decision"]),
  # ---- nhóm
  "Group": ent({"groupId": UUID, "code": CODE(64), "name": STR(160), "kind": enum("ORG", "CUSTOM"), "parentGroupId": {"type": ["string", "null"], "format": "uuid"},
                "orgCode": STR(64), "memberCount": INT(), "active": BOOL}, req=["groupId", "code", "name", "kind"]),
  "GroupPage": items("Group"),
  "GroupCreate": obj({"code": CODE(64), "name": STR(160), "kind": enum("ORG", "CUSTOM"), "parentGroupId": UUID, "orgCode": STR(64)}, req=["code", "name", "kind"]),
  "GroupUpdate": obj({"name": STR(160), "parentGroupId": {"type": ["string", "null"], "format": "uuid"}, "active": BOOL}),
  "GroupMembers": obj({"userIds": arr(UUID, maxItems=5000, uniqueItems=True)}, req=["userIds"], desc="Danh sách thay thế toàn bộ thành viên."),
  # ---- quyền có thời hạn, rà soát, sáp nhập
  "PrivilegedGrantCreate": obj({"type": enum("TENANT_ACCESS", "PRIVILEGE"), "targetTenant": R("TenantCode"), "roleCode": STR(64),
                                "durationMinutes": INT(minimum=15, maximum=240), "reason": REASON(20, 1000), "ticketRef": STR(16, pattern="^[A-Z]{2,6}-[0-9]{1,8}$")},
                               req=["type", "targetTenant", "roleCode", "durationMinutes", "reason", "ticketRef"],
                               examples=[{"type": "TENANT_ACCESS", "targetTenant": "T68", "roleCode": "PLATFORM_OPERATOR", "durationMinutes": 120,
                                          "reason": "Điều tra sự cố Kafka theo phiếu hỗ trợ của tỉnh", "ticketRef": "HT-20431"}]),
  "PrivilegedGrant": ent({"grantId": UUID, "type": enum("TENANT_ACCESS", "PRIVILEGE"), "requesterId": UUID, "homeTenant": R("TenantCode"), "targetTenant": R("TenantCode"),
                          "roleCode": STR(64), "state": enum("REQUESTED", "ACTIVE", "REJECTED", "CANCELLED", "EXPIRED", "REVOKED"), "durationMinutes": INT(), "ticketRef": STR(16),
                          "reason": STR(1000), "approverId": UUID, "decidedAt": NTS, "activeFrom": NTS, "expiresAt": NTS, "remainingSeconds": {"type": ["integer", "null"], "minimum": 0, "description": "Số giây còn lại tới `expiresAt`, tính ở máy chủ để giao diện đếm ngược không phụ thuộc đồng hồ máy."}},
                         req=["grantId", "type", "targetTenant", "roleCode", "state"]),
  "PrivilegedGrantPage": items("PrivilegedGrant"),
  "CampaignCreate": obj({"scopeType": enum("TENANT", "ORG", "ROLE_GROUP"), "scopeRef": STR(64), "deadlineDays": INT(minimum=7, maximum=30),
                         "onTimeout": enum("REMOVE", "ESCALATE")}, req=["scopeType"]),
  "Campaign": ent({"campaignId": UUID, "scopeType": STR(16), "scopeRef": STR(64), "state": enum("OPEN", "CLOSED"), "deadline": TS, "onTimeout": STR(16),
                   "stats": obj({"total": INT(), "kept": INT(), "removed": INT(), "pending": INT(), "escalated": INT()}),
                   "items": arr(R("CampaignItem"), maxItems=500)}, req=["campaignId", "state"]),
  "CampaignItem": obj({"itemId": UUID, "userId": UUID, "username": STR(64), "roleCode": STR(64), "scopeRef": STR(64), "reviewerId": UUID,
                       "decision": {"type": ["string", "null"], "enum": ["KEEP", "REMOVE", None]}, "decidedAt": NTS}, req=["itemId", "userId", "roleCode"]),
  "CampaignItemDecision": obj({"decision": enum("KEEP", "REMOVE"), "comment": STR(500, minLength=5)}, req=["decision"]),
  "MergePlan": obj({"mergeId": UUID, "sourceTenants": arr(R("TenantCode")), "targetTenant": R("TenantCode"),
                    "usersToMove": INT(), "conflicts": arr(obj({"kind": enum("USERNAME", "EMAIL", "ROLE", "CLIENT"), "ref": STR(128), "resolution": STR(500)}, req=["kind", "ref"])),
                    "clientsToMove": INT(), "estimatedMinutes": INT(), "planHash": STR(64)}, req=["mergeId", "targetTenant", "usersToMove"]),
  "MergeExecute": obj({"planHash": STR(64), "readOnlySource": BOOL}, req=["planHash"]),
  # ---- liên kết ngoài
  "LdapFederation": ent({"federationCode": CODE(63), "url": STR(255), "baseDn": STR(512), "bindDn": STR(512), "attributeMap": ANYOBJ, "mode": enum("IMPORT", "AUTH_ONLY"),
                         "state": enum("DRAFT", "PENDING_APPROVAL", "ACTIVE", "DISABLED"), "lastSyncAt": NTS, "lastTestAt": NTS, "secretSet": BOOL,
                         "passwordPolicyAck": BOOL, "approvedBy": STR(64)}, req=["federationCode", "url", "mode", "state"]),
  "LdapFederationList": obj({"items": arr(R("LdapFederation"))}, req=["items"]),
  "LdapFederationPut": obj({"url": STR(255, pattern="^ldaps://"), "baseDn": STR(512), "bindDn": STR(512),
                            "bindSecret": STR(1024, writeOnly=True, description="Ghi một chiều vào OpenBao; không bao giờ trả lại."),
                            "attributeMap": ANYOBJ, "mode": enum("IMPORT", "AUTH_ONLY"), "passwordPolicyAck": BOOL},
                           req=["url", "baseDn", "bindDn", "attributeMap", "mode", "passwordPolicyAck"]),
  "LdapTestResult": obj({"status": enum("PASSED", "FAILED"), "steps": arr(obj({"name": STR(32), "status": enum("PASSED", "FAILED", "SKIPPED"), "hint": STR(500)}, req=["name", "status"])),
                         "sampleCount": INT(), "testedAt": TS}, req=["status", "steps"]),
  "SamlClient": ent({"samlClientCode": CODE(63), "entityId": STR(512), "acsUrls": arr(STR(512)), "attributeMap": arr(STR(32)), "encryptAssertion": BOOL,
                     "certNotAfter": TS, "systemCode": STR(64), "state": enum("DRAFT", "PENDING_APPROVAL", "ENABLED", "DISABLED")}, req=["samlClientCode", "entityId", "state"]),
  "SamlClientList": obj({"items": arr(R("SamlClient"))}, req=["items"]),
  "SamlClientCreate": obj({"samlClientCode": CODE(63), "entityId": STR(512, format="uri"), "metadataXml": STR(1048576), "metadataUrl": STR(512, format="uri"),
                           "attributeMap": arr(enum("username", "email", "fullName", "orgCode", "roles")), "encryptAssertion": BOOL, "systemCode": STR(64)},
                          req=["samlClientCode", "entityId"], desc="Một trong `metadataXml` hoặc `metadataUrl`."),
  "SamlClientUpdate": obj({"metadataXml": STR(1048576), "metadataUrl": STR(512, format="uri"), "attributeMap": arr(STR(32)), "encryptAssertion": BOOL, "state": enum("ENABLED", "DISABLED")}),
  "VneidConfirm": obj({"linkToken": STR(512, description="Mã dùng một lần do trang xác nhận VNeID trả về.")}, req=["linkToken"]),
  # ---- client
  "AuthMethod": enum("TLS_CLIENT_AUTH", "PRIVATE_KEY_JWT", "CLIENT_SECRET"),
  "ScopeSource": enum("API_REGISTRATION", "PURPOSE", "PUBLICATION", "SUBSCRIPTION", "PLATFORM"),
  "ScopeGrant": obj({"scope": STR(128, pattern="^[a-z][a-z0-9:._-]{2,127}$"), "source": R("ScopeSource"), "sourceRef": STR(128)}, req=["scope", "source", "sourceRef"]),
  "SecretHandover": obj({"wrapAddress": STR(512, format="uri", description="Địa chỉ bọc dùng một lần (OpenBao cubbyhole); giá trị bí mật không có trong phản hồi."),
                         "expiresAt": TS, "deliveredTo": STR(64)}, req=["wrapAddress", "expiresAt"]),
  "Client": ent({"clientId": STR(64), "systemCode": STR(64), "systemName": STR(200), "orgCode": STR(64), "state": enum("PROVISIONING", "ENABLED", "SUSPENDED", "REVOKED", "FAILED"),
                 "authMethod": R("AuthMethod"), "contractLevel": CLS, "credentialReady": BOOL, "scopes": arr(R("ScopeGrant")), "scopeCount": INT(),
                 "certThumbprint": STR(128), "certNotAfter": NTS, "secretExpiresAt": NTS, "lastTokenAt": NTS, "technicalContact": STR(64),
                 "secretHandover": R("SecretHandover"), "stateReason": STR(500)}, req=["clientId", "systemCode", "state", "authMethod", "contractLevel"]),
  "ClientPage": items("Client", {"facets": obj({"state": CNT, "authMethod": CNT})}),
  "ClientProvision": obj({"systemCode": STR(64), "systemName": STR(200, minLength=2), "orgCode": STR(64), "contractLevel": CLS, "authMethod": R("AuthMethod"),
                          "scopes": arr(R("ScopeGrant"), maxItems=500), "technicalContact": STR(64), "publicKeyJwk": ANYOBJ},
                         req=["systemCode", "systemName", "orgCode", "contractLevel", "authMethod", "scopes", "technicalContact"],
                         examples=[{"systemCode": "ht-qlvb", "systemName": "Quản lý văn bản Sở KH&CN", "orgCode": "SKHCN", "contractLevel": "INTERNAL",
                                    "authMethod": "PRIVATE_KEY_JWT", "scopes": [{"scope": "api:van-ban:read", "source": "API_REGISTRATION", "sourceRef": "REG-2026-0113"}],
                                    "technicalContact": "tran.vanb", "publicKeyJwk": {"kty": "EC", "crv": "P-256", "x": "f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU",
                                                                                      "y": "x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0", "use": "sig", "alg": "ES256"}}]),
  "ClientUpdate": obj({"systemName": STR(200), "technicalContact": STR(64), "authMethod": R("AuthMethod"), "contractLevel": CLS}),
  "DevClientCreate": obj({"appCode": CODE(63), "appName": STR(200), "ownerUserId": STR(64), "sandboxProject": STR(64), "authMethod": enum("PRIVATE_KEY_JWT", "CLIENT_SECRET"),
                          "scopes": arr(R("ScopeGrant"), maxItems=100), "expiresAt": TS}, req=["appCode", "appName", "ownerUserId", "authMethod"]),
  "CertificatePut": obj({"certificatePem": STR(16384, description="Chuỗi chứng thư PEM; còn hạn ≥ 30 ngày; khóa ≥ 2048 RSA hoặc P-256."), "subjectDn": STR(512)}, req=["certificatePem"]),
  "JwksPut": obj({"keys": arr(ANYOBJ, minItems=1, maxItems=5, description="JWK công khai ES256 hoặc PS256; không có thành phần riêng (`d`).")}, req=["keys"]),
  "SecretRotateRequest": obj({"reason": REASON(), "overlapHours": INT(minimum=1, maximum=72)}, req=["reason"]),
  "SecretRotateResult": obj({"rotationId": UUID, "status": enum("TRANSITION", "COMPLETED"), "overlapUntil": TS, "secretHandover": R("SecretHandover")}, req=["rotationId", "status", "secretHandover"]),
  "ScopeList": obj({"clientId": STR(64), "items": arr(R("ScopeGrant")), "revision": INT()}, req=["clientId", "items"]),
  "ScopeReplace": obj({"source": R("ScopeSource"), "sourceRef": STR(128), "scopes": arr(R("ScopeGrant"), maxItems=500)}, req=["source", "scopes"],
                      desc="Ghi đè tập scope của một nguồn; scope của nguồn khác giữ nguyên."),
  "ServiceAccount": ent({"accountCode": CODE(63), "du": STR(32), "authMethod": enum("SPIFFE_MTLS", "PRIVATE_KEY_JWT"), "scopes": arr(STR(64)), "rotationDays": INT(),
                         "state": enum("PENDING", "ENABLED", "SUSPENDED", "REVOKED"), "nextRotationAt": NTS}, req=["accountCode", "du", "authMethod", "state"]),
  "ServiceAccountList": obj({"items": arr(R("ServiceAccount"))}, req=["items"]),
  "ServiceAccountCreate": obj({"accountCode": CODE(63), "du": STR(32), "authMethod": enum("SPIFFE_MTLS", "PRIVATE_KEY_JWT"),
                               "scopes": arr(STR(64), minItems=1, maxItems=50), "rotationDays": INT(minimum=30, maximum=90)}, req=["accountCode", "du", "authMethod", "scopes"]),
  # ---- thu hồi
  "RevokeAccessRequest": obj({"targetType": enum("USER", "CLIENT", "JTI"), "targetId": STR(128), "reason": REASON(), "scopeOfRevoke": enum("ALL", "TOKENS_ONLY")},
                             req=["reason"], desc="`targetType` và `targetId` bắt buộc ở `/clients/{clientId}:revoke` được suy từ đường dẫn; chỉ cần khi thu hồi theo `JTI`."),
  "RevocationAccepted": obj({"revocationId": UUID, "state": enum("RECORDED", "APPLIED_PARTIAL", "APPLIED"), "appliedNodes": INT(), "totalNodes": INT(), "estimatedAppliedAt": TS},
                            req=["revocationId", "state"]),
  "RevocationEntry": obj({"entryId": UUID, "kind": enum("SUB", "CLIENT", "JTI"), "subject": STR(128), "notBefore": TS, "expiresAt": TS, "blockAll": BOOL,
                          "reason": STR(500)}, req=["entryId", "kind", "subject", "notBefore", "expiresAt"]),
  "RevocationFeed": obj({"version": INT(description="Số phiên bản danh sách, trùng `ETag`."), "generatedAt": TS, "entries": arr(R("RevocationEntry"))}, req=["version", "entries"],
                        desc="Không có thông tin cá nhân ngoài mã chủ thể. Trả 304 khi `If-None-Match` khớp."),
  # ---- realm
  "RealmState": enum("PROVISIONING", "ACTIVE", "SUSPENDED", "READ_ONLY", "DELETED"),
  "RealmProvision": obj({"tenantCode": R("TenantCode"), "displayName": STR(200), "emailDomains": arr(STR(128), minItems=1), "template": STR(32), "adminEmail": STR(254, format="email"),
                         "adminFullName": STR(160), "orgCode": STR(64), "maxUsers": INT(minimum=1)}, req=["tenantCode", "displayName", "emailDomains", "adminEmail", "adminFullName"],
                        examples=[{"tenantCode": "T68", "displayName": "Tỉnh Lâm Đồng (giả lập)", "emailDomains": ["lamdong.gov.vn"], "adminEmail": "admin@lamdong.gov.vn",
                                   "adminFullName": "Lê Thị C", "maxUsers": 2000}]),
  "Realm": ent({"tenantCode": R("TenantCode"), "realmName": STR(64), "state": R("RealmState"), "templateVersion": STR(32), "driftStatus": enum("IN_SYNC", "DRIFTED", "HELD", "UNKNOWN"),
                "signingKeyId": STR(64), "signingKeyRotatedAt": NTS, "steps": arr(obj({"name": STR(64), "status": enum("PENDING", "RUNNING", "DONE", "FAILED"), "finishedAt": NTS}, req=["name", "status"])),
                "userCount": INT(), "clientCount": INT()}, req=["tenantCode", "state"]),
  "RealmDrift": obj({"tenantCode": R("TenantCode"), "status": enum("IN_SYNC", "DRIFTED", "HELD"), "checkedAt": TS,
                     "differences": arr(obj({"path": STR(255), "expected": {}, "actual": {}, "severity": enum("INFO", "WARNING", "CRITICAL")}, req=["path"]))}, req=["tenantCode", "status"]),
  # ---- quyết định ủy quyền
  "Subject": obj({"type": enum("USER", "CLIENT", "SERVICE"), "id": STR(128), "roles": arr(STR(64)), "scopes": arr(STR(128)), "org": STR(64), "acr": ACR,
                  "authTime": TS, "grantId": STR(64, description="Chỉ để ghi vết; OPA tra theo dữ liệu gói.")}, req=["type", "id"]),
  "Resource": obj({"id": STR(128), "type": STR(64), "tenant": R("TenantCode"), "org": STR(64), "classification": CLS, "state": STR(32), "createdBy": STR(128), "submittedBy": STR(128)},
                  req=["id", "type", "tenant", "classification"]),
  "DecisionContext": obj({"purpose": STR(128), "caseRef": STR(64), "sourceIp": STR(45), "time": TS}),
  "DecisionRequest": obj({"traceId": STR(32, pattern="^[0-9a-f]{32}$"), "tenant": R("TenantCode"), "subject": R("Subject"), "resource": R("Resource"),
                          "action": STR(32), "permission": STR(64, pattern="^PERM-[0-9]{2}-[a-z-]+$"), "context": R("DecisionContext")},
                         req=["traceId", "tenant", "subject", "resource", "action", "permission"],
                         examples=[{"traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "tenant": "T68",
                                    "subject": {"type": "USER", "id": "nguyen.vana", "roles": ["INTEGRATION_ENGINEER"], "scopes": [], "org": "SKHCN", "acr": 2, "authTime": "2026-11-26T08:30:00Z"},
                                    "resource": {"id": "luong-hosoxd", "type": "flow", "tenant": "T68", "org": "SKHCN", "classification": "INTERNAL", "state": "DRAFT", "createdBy": "nguyen.vana"},
                                    "action": "publish", "permission": "PERM-04-publish", "context": {"sourceIp": "10.20.30.40", "time": "2026-11-26T09:00:00Z"}}]),
  "DecisionReason": enum("MATCHED_POLICY", "NO_MATCHING_POLICY", "TENANT_MISMATCH", "DATA_CLASSIFIED_SECRET", "PURPOSE_NOT_DECLARED", "SCOPE_MISSING", "ROLE_MISSING",
                         "ORG_SCOPE_MISMATCH", "SELF_APPROVAL", "STEPUP_REQUIRED", "CLIENT_SUSPENDED", "TENANT_SUSPENDED", "GRANT_EXPIRED", "AUDIT_UNAVAILABLE", "POLICY_ERROR"),
  "Obligation": obj({"type": enum("AUDIT", "STEPUP", "MASK", "TTL"), "params": ANYOBJ}, req=["type"]),
  "DecisionResult": obj({"allow": BOOL, "reason": R("DecisionReason"), "matchedPolicy": {"type": ["string", "null"]}, "bundleRevision": {"type": ["string", "null"]},
                         "fieldMask": {"type": "object", "additionalProperties": enum("FULL", "MASKED", "HIDDEN")},
                         "privacyMode": enum("NONE", "PURPOSE_BOUND", "PSEUDONYMIZED"), "obligations": arr(R("Obligation")), "evaluationTimeMs": INT()},
                        req=["allow", "reason"], desc="Từ chối là kết quả hợp lệ (`200`, `allow=false`); bên thực thi đổi thành 401, 403 hoặc 404 (FRS §9.1)."),
  "DecisionBatchRequest": obj({"traceId": STR(32, pattern="^[0-9a-f]{32}$"), "requests": arr(R("DecisionRequest"), minItems=1, maxItems=100)}, req=["traceId", "requests"]),
  "DecisionBatchResult": obj({"results": arr(R("DecisionResult"), description="Cùng thứ tự với `requests`.")}, req=["results"]),
  "XacmlRequest": obj({"Request": ANYOBJ}, req=["Request"], desc="XACML 3.0 JSON Profile (OASIS), ánh xạ sang `input` của OPA (FR-12-048)."),
  "XacmlResponse": obj({"Response": arr(obj({"Decision": enum("Permit", "Deny", "NotApplicable", "Indeterminate"), "Status": ANYOBJ, "Obligations": arr(ANYOBJ)}, req=["Decision"]))}, req=["Response"]),
  # ---- chính sách
  "PolicyScope": enum("PLATFORM", "TENANT"),
  "Policy": ent({"policyCode": CODE(63), "scope": R("PolicyScope"), "description": STR(500), "tags": arr(STR(32)), "publishedVersion": {"type": ["integer", "null"]},
                 "latestVersion": INT(), "isRoot": BOOL}, req=["policyCode", "scope"]),
  "PolicyPage": items("Policy"),
  "PolicyCreate": obj({"policyCode": CODE(63), "scope": R("PolicyScope"), "description": STR(500, minLength=10), "tags": arr(STR(32), maxItems=10),
                       "content": STR(204800, description="Rego, qua `opa check` và `opa fmt`, ≤ 200 KiB."), "tests": arr(R("PolicyTestCase"), minItems=2)},
                      req=["policyCode", "scope", "description", "content", "tests"]),
  "PolicyTestCase": obj({"name": STR(128), "kind": enum("POSITIVE", "NEGATIVE"), "input": ANYOBJ, "expected": obj({"allow": BOOL, "reason": R("DecisionReason")}, req=["allow"])},
                        req=["name", "kind", "input", "expected"]),
  "PolicyVersionCreate": obj({"content": STR(204800), "changeNote": STR(2000), "tests": arr(R("PolicyTestCase"))}, req=["content"]),
  "PolicyVersionState": enum("DRAFT", "PENDING_REVIEW", "CHANGES_REQUESTED", "APPROVED", "PUBLISHED", "SUPERSEDED", "REVOKED", "DISCARDED"),
  "PolicyVersion": ent({"policyCode": CODE(63), "versionNo": INT(minimum=1), "state": R("PolicyVersionState"), "contentHash": STR(64), "content": STR(204800), "changeNote": STR(2000),
                        "contributors": arr(STR(64)), "submittedBy": STR(64), "approvedBy": STR(64), "testPassedForHash": BOOL, "dryRunDoneForHash": BOOL,
                        "publishedAt": NTS, "bundleRevision": STR(64)}, req=["policyCode", "versionNo", "state", "contentHash"]),
  "TestRun": obj({"runId": UUID, "versionNo": INT(), "contentHash": STR(64), "passed": INT(), "failed": INT(), "positiveCount": INT(), "negativeCount": INT(),
                  "failures": arr(obj({"name": STR(128), "expected": STR(64), "actual": STR(64)}, req=["name"])), "ranAt": TS}, req=["runId", "passed", "failed"]),
  "DryRunRequest": obj({"windowHours": INT(minimum=1, maximum=168), "maxSamples": INT(minimum=1000, maximum=1000000)}),
  "DryRunReport": obj({"reportId": UUID, "versionNo": INT(), "contentHash": STR(64), "status": enum("RUNNING", "DONE", "FAILED"), "samples": INT(), "changed": INT(), "changeRatio": NUM,
                       "newDenies": INT(), "newAllows": INT(), "needsExtraConfirm": BOOL, "topChanges": arr(obj({"permission": STR(64), "from": STR(16), "to": STR(16), "count": INT()}))},
                      req=["reportId", "status"]),
  "PolicyApprove": obj({"comment": STR(2000, minLength=10), "extraConfirm": BOOL, "extraConfirmComment": STR(1000)}, req=["comment"],
                       desc="`extraConfirm=true` và ý kiến bắt buộc khi tỷ lệ đổi quyết định của chạy khô vượt ngưỡng (ERR-12-029)."),
  "BundleRelease": obj({"revision": STR(64), "scope": R("PolicyScope"), "tenant": R("TenantCode"), "state": enum("BUILDING", "SIGNED", "PUBLISHED", "SUPERSEDED", "FAILED"),
                        "policyVersions": arr(obj({"policyCode": STR(63), "versionNo": INT()}, req=["policyCode", "versionNo"])), "dataRevision": STR(64),
                        "signedAt": NTS, "activatedAt": NTS, "ackedNodes": INT(), "totalNodes": INT()}, req=["revision", "state"]),
  "BundleReleasePage": items("BundleRelease"),
  "BundleRollback": obj({"targetRevision": STR(64), "reason": REASON(20, 1000), "scope": R("PolicyScope")}, req=["targetRevision", "reason"]),
  "PolicyDataRegenerate": obj({"reason": STR(500), "dryRun": BOOL}),
  # ---- nhật ký, cảnh báo, báo cáo
  "DecisionLogEntry": obj({"decisionId": UUID, "time": TS, "traceId": STR(32), "subjectType": STR(16), "subjectId": STR(128), "action": STR(32), "permission": STR(64),
                           "resourceType": STR(64), "resourceId": STR(128), "classification": CLS, "allow": BOOL, "reason": R("DecisionReason"), "matchedPolicy": STR(64),
                           "bundleRevision": STR(64), "sampled": BOOL, "maskedFields": arr(STR(64), description="Tên trường đã che trong bản ghi trả về.")}, req=["decisionId", "time", "allow", "reason"]),
  "DecisionPage": items("DecisionLogEntry"),
  "SecurityEvent": obj({"eventId": UUID, "time": TS, "type": STR(48), "userId": STR(64), "clientId": STR(64), "result": enum("SUCCESS", "FAILURE"), "errorCode": STR(16, pattern="^ERR-12-[0-9]{3}$"),
                        "ip": STR(45), "acr": ACR, "detail": ANYOBJ}, req=["eventId", "time", "type"]),
  "SecurityEventPage": items("SecurityEvent"),
  "Alert": ent({"alertId": UUID, "ruleCode": STR(8, pattern="^AN-[0-9]{2}$"), "severity": enum("LOW", "MEDIUM", "HIGH", "CRITICAL"), "state": enum("OPEN", "ACKNOWLEDGED"),
                "subject": STR(128), "summary": STR(500), "raisedAt": TS, "ackedBy": STR(64), "ackedAt": NTS}, req=["alertId", "ruleCode", "severity", "state"]),
  "AlertPage": items("Alert", {"facets": obj({"severity": CNT, "state": CNT})}),
  "AlertAck": obj({"comment": STR(1000)}),
  "AccountReport": obj({"date": DATE, "byState": CNT, "byOrg": CNT, "inactive30": INT(), "neverLoggedIn": INT(), "total": INT(),
                        "series": arr(obj({"date": DATE, "active": INT(), "locked": INT(), "disabled": INT()}, req=["date"]))}, req=["date", "total"]),
  "MfaCoverageReport": obj({"date": DATE, "coverage": NUM, "byRole": arr(obj({"roleCode": STR(64), "users": INT(), "withMfa": INT(), "required": BOOL, "ratio": NUM}, req=["roleCode", "users"])),
                            "withoutMfaAdmins": INT()}, req=["date", "coverage"]),
  # ---- tham số, danh bạ
  "Settings": obj({"values": {"type": "object", "additionalProperties": True, "description": "Khóa `12.*` → giá trị hiện hành."},
                   "ceilings": {"type": "object", "additionalProperties": obj({"min": {}, "max": {}, "allowed": arr({})}), "description": "Trần do nền tảng đặt cho từng khóa."},
                   "version": INT()}, req=["values", "version"],
                  examples=[{"values": {"12.password.min-length": 14, "12.lockout.max-failures": 5, "12.jit.max-hours": 4}, "ceilings": {"12.password.min-length": {"min": 14, "max": 128}}, "version": 7}]),
  "SettingsUpdate": obj({"values": {"type": "object", "additionalProperties": True, "minProperties": 1}, "reason": STR(500)}, req=["values"],
                        desc="Giá trị ngoài trần: ERR-12-043; yếu hơn mức bắt buộc TCVN 14423:2026 cũng ERR-12-043."),
  "DirectoryEntry": obj({"userId": UUID, "username": STR(64), "fullName": STR(160), "email": STR(254), "orgCode": STR(64), "title": STR(120), "state": R("UserState")},
                        req=["userId", "username", "fullName"], desc="Thông tin tối thiểu (BR-12-042): không có yếu tố xác thực, phiên, vai trò."),
  "DirectoryPage": items("DirectoryEntry"),
}

_extra = {"title": STR(120), "managerUserId": UUID, "roleAssignments": arr(R("RoleAssignmentBrief")), "groups": arr(obj({"groupId": UUID, "name": STR(160)})),
          "factors": arr(R("FactorInfo")), "sessionsCount": INT(), "mfaRequired": BOOL, "ldapManagedFields": arr(STR(32)),
          "vneidLinked": BOOL, "activatedAt": NTS, "stateReason": STR(500)}
SCHEMAS["UserDetail"] = obj({**SCHEMAS["UserSummary"]["properties"], **_extra}, req=SCHEMAS["UserSummary"]["required"],
    examples=[{"userId": "0b6d3c1e-5e4a-4b0e-9a3a-1c2d3e4f5a6b", "username": "nguyen.vana", "fullName": "Nguyễn Văn A", "email": "vana@sokhcn.gov.vn", "orgCode": "SKHCN",
               "orgName": "Sở Khoa học và Công nghệ", "state": "PENDING_ACTIVATION", "authSource": "LOCAL", "roles": ["INTEGRATION_ENGINEER"], "mfaEnabled": False,
               "lastLoginAt": None, "version": 1, "createdAt": "2026-11-26T08:30:00Z", "createdBy": "tran.thib", "allowedActions": ["resend-activation", "disable"],
               "disabledReasons": {"unlock": "Tài khoản chưa bị khóa."}}])
PARAMS = {
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55, pattern="^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$"), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en"), "description": "Ngôn ngữ của `title`, `detail`; mặc định `vi`."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "`ETag` của lần đọc gần nhất; lệch trả ERR-12-044 (412)."},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16), "description": "16…128 ký tự, giữ 24 giờ; cùng khóa khác thân trả ERR-12-045 (422)."},
  "Page": {"name": "page", "in": "query", "schema": INT(minimum=1, default=1)},
  "Size": {"name": "size", "in": "query", "schema": INT(minimum=1, maximum=100, default=20), "description": "10, 20, 50, 100; ngoài miền trả ERR-12-003."},
  "Sort": {"name": "sort", "in": "query", "schema": STR(64, pattern="^[a-zA-Z]+:(asc|desc)$"), "description": "`truong:asc|desc`."},
  "Q": {"name": "q", "in": "query", "schema": STR(100, minLength=1), "description": "Tìm không dấu."},
  "TenantRealm": {"name": "tenant", "in": "path", "required": True, "schema": STR(16, pattern="^[a-z0-9]+$"), "description": "Mã tenant chữ thường, ví dụ `t68`; realm là `dh-{tenant}`."},
}
PATHP = {"userId": UUID, "importId": UUID, "roleCode": STR(64), "assignmentId": UUID, "exceptionId": UUID, "groupId": UUID, "grantId": UUID, "campaignId": UUID,
         "itemId": UUID, "mergeId": UUID, "federationCode": CODE(63), "samlClientCode": CODE(63), "clientId": STR(64), "accountCode": CODE(63), "tenantCode": R("TenantCode"),
         "policyCode": CODE(63), "versionNo": INT(minimum=1), "decisionId": UUID, "alertId": UUID}
for k, v in PATHP.items():
    PARAMS[k + "Path"] = {"name": k, "in": "path", "required": True, "schema": v}

def Q(name, schema, desc=None):
    d = {"name": name, "in": "query", "schema": schema}
    if desc: d["description"] = desc
    return d
LISTQ = {  # tham số lọc riêng từng danh sách
  "001": [Q("state", R("UserState")), Q("orgCode", STR(64)), Q("roleCode", STR(64)), Q("mfa", enum("on", "off")), Q("authSource", R("AuthSource")), Q("inactiveDays", INT(minimum=1))],
  "014": [Q("orgCode", STR(64)), Q("state", R("UserState"))],
  "019": [Q("kind", enum("STANDARD", "CUSTOM"))], "021": [Q("roleCode", STR(64))],
  "025": [Q("userId", UUID), Q("roleCode", STR(64)), Q("state", enum("ACTIVE", "EXPIRED", "REVOKED"))],
  "032": [Q("kind", enum("ORG", "CUSTOM")), Q("parentGroupId", UUID)],
  "037": [Q("state", enum("REQUESTED", "ACTIVE", "REJECTED", "CANCELLED", "EXPIRED", "REVOKED")), Q("requesterId", UUID), Q("targetTenant", R("TenantCode"))],
  "056": [Q("state", enum("ENABLED", "SUSPENDED", "REVOKED")), Q("orgCode", STR(64)), Q("authMethod", R("AuthMethod")), Q("contractLevel", CLS)],
  "089": [Q("scope", R("PolicyScope")), Q("tag", STR(32))],
  "101": [Q("scope", R("PolicyScope")), Q("state", enum("BUILDING", "SIGNED", "PUBLISHED", "SUPERSEDED", "FAILED"))],
  "103": [Q("from", TS, "Từ thời điểm."), Q("to", TS), Q("subjectId", STR(128)), Q("allow", BOOL), Q("reason", R("DecisionReason")), Q("permission", STR(64)), Q("resourceId", STR(128)), Q("classification", CLS)],
  "105": [Q("from", TS), Q("to", TS), Q("type", STR(48)), Q("userId", STR(64)), Q("clientId", STR(64)), Q("result", enum("SUCCESS", "FAILURE")), Q("errorCode", STR(16))],
  "106": [Q("severity", enum("LOW", "MEDIUM", "HIGH", "CRITICAL")), Q("state", enum("OPEN", "ACKNOWLEDGED")), Q("ruleCode", STR(8))],
  "108": [Q("date", DATE), Q("orgCode", STR(64)), Q("days", INT(minimum=1, maximum=365))], "109": [Q("date", DATE), Q("orgCode", STR(64))],
}
PAGED = {"001", "014", "019", "025", "032", "037", "056", "089", "101", "103", "105", "106"}

# mã: (operationId, body, resp, [ERR số], mô tả)
X = {
 "001": ("listUsers", None, "UserPage", [], "`facets` kèm số người dùng thuộc nhóm bắt buộc MFA mà chưa có (`mfaRequiredMissing`) và số tài khoản sắp bị vô hiệu vì không dùng (`inactivitySoon`); lọc theo MFA bằng tham số `mfa`. Bản chiếu `ph12_iam` của tenant hiện hành; có thể chậm so với Keycloak, kèm tiêu đề `X-DH-Projection-Lag` (giây). `BLOCKED`, `LOCKED` xếp đầu khi không có `sort`."),
 "002": ("getUser", None, "UserDetail", [], "Trả `factors[]` chỉ gồm loại và nhãn; quyền `PERM-12-read` không xem được bí mật yếu tố xác thực."),
 "003": ("createUser", "UserCreate", "UserDetail", [2, 4, 5, 10, 37, 38, 40, 43], "Tạo ở Keycloak (`PENDING_ACTIVATION`) và gửi liên kết kích hoạt hiệu lực 24 giờ; phản hồi không có mật khẩu hay liên kết."),
 "004": ("updateUser", "UserUpdate", "UserDetail", [4, 5, 38, 40, 47], "Đổi đơn vị làm vai trò phạm vi đơn vị cũ hết hiệu lực; phát EVT-12-02."),
 "005": ("lockUser", "StateChangeRequest", "UserDetail", [6, 13, 14, 38, 46], "Khóa hẳn (`BLOCKED`), hủy mọi phiên. Không tự khóa chính mình."),
 "006": ("unlockUser", "StateChangeRequest", "UserDetail", [6, 13, 14, 38], "Mở khóa `LOCKED` hoặc `BLOCKED`."),
 "007": ("disableUser", "StateChangeRequest", "UserDetail", [6, 13, 14, 38, 46], "Vô hiệu (`DISABLED`), không xóa vật lý (BR-12-035). Quản trị tỉnh cuối cùng không vô hiệu được."),
 "008": ("enableUser", "StateChangeRequest", "UserDetail", [6, 14, 38], "Kích hoạt lại từ `DISABLED` về `PENDING_ACTIVATION` hoặc `ACTIVE` theo lịch sử kích hoạt."),
 "009": ("resendActivation", None, "Accepted", [6, 37, 38], "Chỉ khi `PENDING_ACTIVATION`; liên kết cũ vô hiệu."),
 "010": ("createUserImport", "UserImportFile", "UserImport", [3, 35, 36, 37, 43], "Pha 1: kiểm tra toàn bộ tệp, chưa tạo tài khoản; trả báo cáo lỗi theo dòng (tối đa 200 lỗi). Quá 5 MiB trả 413 kèm ERR-12-035."),
 "011": ("getUserImport", None, "UserImport", [], "Theo dõi pha kiểm tra và pha ghi nhận."),
 "012": ("commitUserImport", "UserImportCommit", "Accepted", [6, 36, 37, 38, 43], "Pha 2: tạo tài khoản; từng dòng độc lập, dòng lỗi không chặn dòng đúng khi `skipErrorRows=true`."),
 "013": ("getEffectivePermissions", None, "EffectivePermissions", [], "Quyền hiệu lực tính từ vai trò, nhóm, quyền có thời hạn, ngoại lệ; giải thích nguồn từng quyền."),
 "014": ("searchDirectory", None, "DirectoryPage", [37], "Tenant lấy từ token dịch vụ. Chỉ thông tin tối thiểu (BR-12-042)."),
 "015": ("resetMfa", "ResetMfaRequest", "UserDetail", [13, 14, 17, 37, 38], "Quản trị cấp trên đặt lại yếu tố thứ hai; tài khoản quản trị cần SO duyệt (ERR-12-017)."),
 "016": ("listUserSessions", None, "SessionList", [], "Phiên đang mở của người dùng từ Keycloak."),
 "017": ("signOutUser", "StateChangeRequest", "UserDetail", [13, 14, 38], "Hủy mọi phiên; token đã cấp còn tối đa 5 phút trừ khi thu hồi tức thời (API-12-018)."),
 "018": ("revokeUserAccess", "RevokeAccessRequest", "RevocationAccepted", [13, 14, 37, 38], "Vô hiệu, hủy phiên, thu hồi refresh token và ghi mục danh sách chặn; hiệu lực ở cổng ≤ 60 giây."),
 "019": ("listRoles", None, "RolePage", [], "Vai trò chuẩn và vai trò tùy biến của tenant."),
 "020": ("getRole", None, "Role", [], ""),
 "021": ("listPermissions", None, "PermissionList", [], "Ma trận quyền D02-08; sinh từ cùng nguồn với dữ liệu OPA."),
 "022": ("createRole", "RoleCreate", "Role", [2, 10, 43], "Đợt 2; cần `12.role.custom-enabled`. Vai trò tùy biến không được chứa quyền của vai trò quản trị nền tảng."),
 "023": ("updateRole", "RoleUpdate", "Role", [10, 11], "Đợt 2. Vai trò chuẩn không sửa được."),
 "024": ("retireRole", "StateChangeRequest", "Role", [10, 11, 14], "Đợt 2. Còn gán thì ERR-12-011."),
 "025": ("listRoleAssignments", None, "RoleAssignmentPage", [], ""),
 "026": ("createRoleAssignment", "RoleAssignmentCreate", "RoleAssignment", [9, 10, 13, 14, 38], "Chặn cặp xung đột tách nhiệm vụ (ERR-12-009) trừ khi có `sodExceptionId` còn hiệu lực; không tự gán cho mình."),
 "027": ("deleteRoleAssignment", None, None, [13, 14, 38, 46], "Gỡ vai trò; yêu cầu `reason` ở tham số truy vấn."),
 "028": ("listSodRules", None, "SodRuleList", [], "Bảy cặp xung đột ở D02-08 §4."),
 "029": ("createSodException", "SodExceptionCreate", "SodException", [10, 14, 30], "Quản trị tỉnh đề nghị; SO duyệt; tối đa 90 ngày."),
 "030": ("decideSodException", "SodDecision", "SodException", [8, 14, 27], "Người duyệt khác người đề nghị (bốn mắt)."),
 "031": ("revokeSodException", "StateChangeRequest", "SodException", [14, 27], "Vai trò đã gán nhờ ngoại lệ bị gỡ."),
 "032": ("listGroups", None, "GroupPage", [], ""),
 "033": ("createGroup", "GroupCreate", "Group", [2, 4, 10, 12], ""),
 "034": ("updateGroup", "GroupUpdate", "Group", [10, 11, 12], "Đổi cha không được tạo vòng lặp (ERR-12-012)."),
 "035": ("replaceGroupMembers", "GroupMembers", "Group", [10, 43], "Thay thế toàn bộ danh sách thành viên."),
 "036": ("createPrivilegedGrant", "PrivilegedGrantCreate", "PrivilegedGrant", [10, 30, 37], "Tối đa `12.jit.max-hours`; kèm mã phiếu hỗ trợ. Người đề nghị không được tự duyệt."),
 "037": ("listPrivilegedGrants", None, "PrivilegedGrantPage", [], "Người dùng nền tảng chỉ thấy quyền của mình; quản trị tỉnh thấy quyền vào tenant của mình."),
 "038": ("approvePrivilegedGrant", "DecisionComment", "PrivilegedGrant", [8, 30], "Hiệu lực ngay khi duyệt; tự hết hạn."),
 "039": ("rejectPrivilegedGrant", "RejectRequest", "PrivilegedGrant", [8, 14], ""),
 "040": ("revokePrivilegedGrant", "StateChangeRequest", "PrivilegedGrant", [14], "Thu hồi sớm; cắt phiên của người được cấp ở tenant đích."),
 "041": ("createRecertCampaign", "CampaignCreate", "Campaign", [31, 43], "Đợt 2."),
 "042": ("getRecertCampaign", None, "Campaign", [], ""),
 "043": ("decideRecertItem", "CampaignItemDecision", "CampaignItem", [14, 31], "Chỉ người rà soát được giao (quản lý trực tiếp) gọi được."),
 "044": ("closeRecertCampaign", "StateChangeRequest", "Campaign", [31], "Mục chưa trả lời xử lý theo `onTimeout`."),
 "045": ("planIdentityMerge", None, "MergePlan", [41, 40], "Chỉ tính toán, không đổi dữ liệu."),
 "046": ("executeIdentityMerge", "MergeExecute", "Accepted", [41, 40, 38], "Lũy đẳng theo `Idempotency-Key` (khóa tìm lại tiến trình dở)."),
 "047": ("listLdapFederations", None, "LdapFederationList", [], ""),
 "048": ("putLdapFederation", "LdapFederationPut", "LdapFederation", [32, 39, 43], "Kích hoạt cần SO duyệt (`PERM-12-approve`). `bindSecret` ghi một chiều vào OpenBao."),
 "049": ("testLdapFederation", None, "LdapTestResult", [32], "Kết nối LDAPS, bind, tìm mẫu; không ghi dữ liệu."),
 "050": ("syncLdapFederation", None, "Accepted", [32, 37], ""),
 "051": ("listSamlClients", None, "SamlClientList", [], ""),
 "052": ("createSamlClient", "SamlClientCreate", "SamlClient", [2, 33], ""),
 "053": ("updateSamlClient", "SamlClientUpdate", "SamlClient", [33], ""),
 "054": ("confirmVneidLink", "VneidConfirm", "UserDetail", [34, 14], "Chỉ chính chủ tài khoản; số định danh đã liên kết tài khoản khác thì ERR-12-034."),
 "055": ("unlinkVneid", None, None, [10], "Chính chủ hoặc quản trị; không gỡ nếu là phương thức đăng nhập duy nhất."),
 "056": ("listClients", None, "ClientPage", [], ""),
 "057": ("getClient", None, "Client", [], "Không trả bí mật; chỉ dấu vân tay chứng thư và hạn."),
 "058": ("provisionClient", "ClientProvision", "Client", [2, 18, 19, 21, 22, 37, 38, 39, 40], "Do PH-01 gọi (saga). Bí mật, nếu có, giao qua địa chỉ bọc dùng một lần `secretHandover`."),
 "059": ("updateClient", "ClientUpdate", "Client", [20, 22], ""),
 "060": ("suspendClient", "StateChangeRequest", "Client", [14, 20, 38], "Client bị từ chối cấp token ngay, ghi vào danh sách chặn."),
 "061": ("resumeClient", "StateChangeRequest", "Client", [14, 20, 38], ""),
 "062": ("revokeClient", "StateChangeRequest", "RevocationAccepted", [14, 20, 38], "Thu hồi vĩnh viễn, mã client không dùng lại."),
 "063": ("createDevClient", "DevClientCreate", "Client", [2, 19, 37, 38, 39], "Chỉ ở sandbox; hạn tối đa theo cấu hình PH-15."),
 "064": ("putClientCertificate", "CertificatePut", "Client", [20, 21, 22, 38], "Dấu vân tay mới phát qua EVT-12-08 cho PH-03."),
 "065": ("putClientJwks", "JwksPut", "Client", [20, 21, 22, 38], "Từ chối khóa có thành phần riêng."),
 "066": ("rotateClientSecret", "SecretRotateRequest", "SecretRotateResult", [20, 22, 23, 37, 39], "Chỉ client `CLIENT_SECRET` ở hợp đồng thấp; bí mật cũ giữ trong thời gian chuyển tiếp."),
 "067": ("listClientScopes", None, "ScopeList", [], ""),
 "068": ("replaceClientScopes", "ScopeReplace", "ScopeList", [19, 20, 43], "Chỉ nhận scope có nguồn đã duyệt (PH-02, PH-09, PH-10, PH-19)."),
 "069": ("listServiceAccounts", None, "ServiceAccountList", [], ""),
 "070": ("createServiceAccount", "ServiceAccountCreate", "Accepted", [2, 19, 39, 41], "Áp qua GitOps (`keycloak-config-cli`) sau duyệt."),
 "071": ("rotateServiceAccountCredentials", "StateChangeRequest", "Accepted", [20, 39], ""),
 "072": ("getOidcDiscovery", None, "OidcDiscovery", [], "Chuẩn OpenID Connect Discovery 1.0; Keycloak trả."),
 "073": ("authorize", None, None, [114, 121, 122], "Chỉ `response_type=code` với PKCE `S256`; thiếu PKCE là ERR-12-114. Người dùng đi qua BFF."),
 "074": ("issueToken", "TokenRequest", "TokenResponse", [111, 112, 113, 114, 115, 117, 118, 119, 120, 121, 122, 125], "`grant_type` ∈ `authorization_code`, `client_credentials`, `refresh_token`; mọi grant khác bị cấm (ERR-12-122)."),
 "075": ("getJwks", None, "Jwks", [], "Khóa ký xoay 90 ngày, giữ khóa cũ trong thời gian chuyển tiếp."),
 "076": ("logout", "LogoutRequest", None, [116], "RP-Initiated Logout."),
 "077": ("revokeToken", "RevokeTokenRequest", None, [117], "RFC 7009; luôn trả 200 với token hợp lệ hay không để không lộ thông tin."),
 "078": ("getUserinfo", None, "Userinfo", [116], ""),
 "079": ("getRevocationFeed", None, "RevocationFeed", [], "APISIX kéo mỗi 10 giây; báo phiên bản đã áp dụng bằng tiêu đề `X-DH-Applied-Version` và nút bằng `X-DH-Node`. `ETag` là `version`."),
 "080": ("provisionRealm", "RealmProvision", "Accepted", [2, 41, 43, 38, 39, 40], "PH-20 gọi ở bước `S03_REALM` của saga; hoàn tất ≤ 5 phút. Lũy đẳng: gọi lại cùng khóa thì tiếp tục từ bước dở."),
 "081": ("getRealm", None, "Realm", [], ""),
 "082": ("getRealmDrift", None, "RealmDrift", [41], ""),
 "083": ("reconcileRealm", None, "Accepted", [41, 42, 38], "Áp lại mẫu cấu hình; ghi đè thay đổi lệch."),
 "084": ("suspendRealm", "StateChangeRequest", "Realm", [14, 41, 42], "Chỉ quản trị tỉnh đăng nhập chỉ-đọc; người dùng khác và mọi client bị từ chối."),
 "085": ("resumeRealm", "StateChangeRequest", "Realm", [14, 41, 42], ""),
 "086": ("decide", "DecisionRequest", "DecisionResult", [101, 102, 103, 104], "Đường đầy đủ `/api/authz/v1/decide`. Mục tiêu p99 ≤ 10 ms ở OPA cục bộ; gọi qua API chỉ cho bên không có OPA cục bộ (Q12-26). Mọi lỗi → bên gọi xử lý như từ chối (BR-12-006)."),
 "087": ("decideBatch", "DecisionBatchRequest", "DecisionBatchResult", [101, 102, 103, 104], "Đường đầy đủ `/api/authz/v1/decide:batch`. Tối đa 100 yêu cầu; kết quả cùng thứ tự."),
 "088": ("decideXacml", "XacmlRequest", "XacmlResponse", [123, 102, 103, 104], "Đường đầy đủ `/api/authz/v1/xacml`. Yêu cầu sai lược đồ trả `Indeterminate` kèm `Status`."),
 "089": ("listPolicies", None, "PolicyPage", [], ""),
 "090": ("getPolicy", None, "Policy", [], ""),
 "091": ("createPolicy", "PolicyCreate", "PolicyVersion", [2, 24, 28, 43], "Tối thiểu một ca dương và một ca âm. Chính sách tenant không được có luật cho phép hay nới quyền (ERR-12-028)."),
 "092": ("createPolicyVersion", "PolicyVersionCreate", "PolicyVersion", [24, 27, 28, 43], "Sửa nội dung làm mất hiệu lực kết quả kiểm thử và chạy khô đã có."),
 "093": ("getPolicyVersion", None, "PolicyVersion", [], ""),
 "094": ("testPolicyVersion", None, "TestRun", [24, 25], "Chạy trong `policy-runner` cô lập, không gọi mạng."),
 "095": ("dryRunPolicyVersion", "DryRunRequest", "DryRunReport", [24, 27, 37, 40], "Phát lại lưu lượng mẫu ở cửa sổ `12.policy.dryrun.window-hours`; chạy nền, theo dõi bằng `Location`."),
 "096": ("submitPolicyVersion", "DecisionComment", "PolicyVersion", [25, 26, 27], "Cần kiểm thử đạt và chạy khô trên đúng băm nội dung hiện tại."),
 "097": ("approvePolicyVersion", "PolicyApprove", "PolicyVersion", [8, 27, 29, 40], "Bốn mắt: khác người soạn, người đóng góp, người gửi. Yêu cầu xác thực mức 3 (`acr`=3)."),
 "098": ("rejectPolicyVersion", "RejectRequest", "PolicyVersion", [8, 14, 27], ""),
 "099": ("revokePolicyVersion", "StateChangeRequest", "BundleRelease", [14, 27], "Không thu hồi được chính sách gốc (ERR-12-027)."),
 "100": ("rollbackPolicyBundle", "BundleRollback", "BundleRelease", [14, 27], "Quay lui về gói đã từng chạy; ký lại và phát hành."),
 "101": ("listPolicyBundles", None, "BundleReleasePage", [], "Kèm số nút OPA đã xác nhận nạp."),
 "102": ("regeneratePolicyData", "PolicyDataRegenerate", "Accepted", [24, 40], "Sinh lại `data.dh.roles`, `assignments`… từ ma trận D02-08 và gán vai trò hiện tại."),
 "103": ("listDecisions", None, "DecisionPage", [], "Quyết định từ chối và mức Hạn chế, Nhạy cảm ghi 100%; mức Công khai, Nội bộ lấy mẫu theo `12.decision.sample-ratio`."),
 "104": ("getDecision", None, "DecisionLogEntry", [], "Mỗi lượt xem dữ liệu đã che được ghi vết sang PH-13 (FR-12-057); phản hồi liệt kê `maskedFields`."),
 "105": ("listSecurityEvents", None, "SecurityEventPage", [], "Sự kiện xác thực và quản trị định danh (EVT-12-16 và kiểm toán)."),
 "106": ("listAlerts", None, "AlertPage", [], ""),
 "107": ("acknowledgeAlert", "AlertAck", "Alert", [14], ""),
 "108": ("getAccountReport", None, "AccountReport", [], ""),
 "109": ("getMfaCoverageReport", None, "MfaCoverageReport", [], ""),
 "110": ("getSettings", None, "Settings", [], ""),
 "111": ("putSettings", "SettingsUpdate", "Settings", [43], "Tham số bảo mật của realm được áp bằng GitOps (FR-12-042)."),
}
STEPUP_EXCLUDE = {"091", "092", "094", "095", "096", "102", "107", "043", "054"}
ACR3 = {"097", "098", "099", "100", "083", "084", "085", "070", "071", "038", "039", "040", "062"}
# Lược đồ chỉ dùng ở điểm cuối OIDC
SCHEMAS.update({
  "OidcDiscovery": {"type": "object", "additionalProperties": True, "required": ["issuer", "authorization_endpoint", "token_endpoint", "jwks_uri"],
                    "properties": {"issuer": STR(), "authorization_endpoint": STR(), "token_endpoint": STR(), "jwks_uri": STR(), "userinfo_endpoint": STR(),
                                   "code_challenge_methods_supported": arr(STR()), "grant_types_supported": arr(STR())}},
  "TokenRequest": obj({"grant_type": enum("authorization_code", "client_credentials", "refresh_token"), "code": STR(512), "redirect_uri": STR(512, format="uri"),
                       "code_verifier": STR(128, minLength=43), "refresh_token": STR(4096), "scope": STR(2048), "client_id": STR(64),
                       "client_assertion_type": STR(128, const="urn:ietf:params:oauth:client-assertion-type:jwt-bearer"), "client_assertion": STR(8192),
                       "client_secret": STR(512, writeOnly=True)}, req=["grant_type"], desc="`application/x-www-form-urlencoded`. Máy gọi máy ưu tiên mTLS hoặc `private_key_jwt`."),
  "TokenResponse": obj({"access_token": STR(8192), "token_type": enum("Bearer"), "expires_in": INT(maximum=300), "refresh_token": STR(4096), "scope": STR(2048), "id_token": STR(8192)},
                       req=["access_token", "token_type", "expires_in"], desc="`expires_in` ≤ 300 giây (`12.token.access-seconds`)."),
  "Jwks": obj({"keys": arr(ANYOBJ)}, req=["keys"]),
  "LogoutRequest": obj({"id_token_hint": STR(8192), "post_logout_redirect_uri": STR(512, format="uri"), "state": STR(256)}),
  "RevokeTokenRequest": obj({"token": STR(8192), "token_type_hint": enum("access_token", "refresh_token"), "client_id": STR(64)}, req=["token"]),
  "Userinfo": {"type": "object", "additionalProperties": True, "required": ["sub"], "properties": {"sub": STR(), "preferred_username": STR(), "name": STR(), "email": STR(), "tenant": STR(), "org": STR(), "roles": arr(STR())}},
})
# 4 lược đồ phát hành trong EXAMPLES bổ sung
IFM = {"004", "005", "006", "007", "008", "023", "024", "027", "030", "031", "034", "035", "038", "039", "040", "048", "053", "055", "059", "060", "061", "062",
       "064", "065", "068", "084", "085", "097", "098", "099", "111"}
NOIDEM = {"074", "076", "077", "086", "087", "088", "094", "049", "054", "043", "045", "107", "044", "042"}
FORMBODY = {"074", "076", "077"}
PUBLIC = {"072", "073", "075"}
STATUS = {200: "OK", 201: "Created", 202: "Accepted", 204: "No Content", 302: "Found", 304: "Not Modified"}
HTTP_RESP = {400: "BadRequest", 401: "Unauthorized", 403: "Forbidden", 404: "NotFound", 409: "Conflict", 410: "Gone", 412: "PreconditionFailed", 413: "TooLarge",
             422: "Unprocessable", 423: "Locked", 429: "TooManyRequests", 500: "ServerError", 503: "Unavailable"}

def build_responses():
    out = {}
    for http, name in HTTP_RESP.items():
        desc = {400: "Yêu cầu không hợp lệ", 401: "Chưa xác thực hoặc token không hợp lệ", 403: "Không có quyền hoặc bị từ chối", 404: "Không tìm thấy hoặc thuộc tenant khác",
                409: "Xung đột trạng thái", 410: "Liên kết hết hạn", 412: "Phiên bản đối tượng đã đổi", 413: "Tệp quá lớn", 422: "Không xử lý được về nghiệp vụ", 423: "Tài khoản bị khóa tạm",
                429: "Vượt tần suất", 500: "Lỗi nội bộ", 503: "Dịch vụ phụ thuộc không khả dụng"}[http]
        out[name] = {"description": desc, "content": {"application/problem+json": {"schema": R("ProblemDetails")}}}
    out["NotModified"] = {"description": "Không đổi (`If-None-Match` khớp `ETag`)."}
    out["OAuthError"] = {"description": "Lỗi theo RFC 6749 §5.2.", "content": {"application/json": {"schema": R("OAuthError")}}}
    return out

def err_ref(code, oauth):
    n = int(code[-3:]) if isinstance(code, str) else code
    c = f"ERR-12-{n:03d}"
    return c, ERRS[c][0]

def build():
    paths = {}
    ops_used = set()
    for code, method, path, summary, fr, perm, success, group, server in spec.OPS:
        opid, body, resp, errs, desc = X[code]
        m = method.lower()
        frs = []
        for part in fr.split(","):
            part = part.strip()
            frs.append(f"FR-12-{int(part):03d}")
        op = {"tags": [spec.TAGS[group]], "operationId": opid, "summary": summary, "x-datahub-id": f"API-12-{code}", "x-datahub-fr": frs}
        # quyền
        pt = perm
        pt = re.sub(r"scope:(iam:[a-z-]+)", r"scope `\1`", pt)
        pm = {"PUBLIC": "Công khai", "CLIENTAUTH": "Xác thực client (mTLS, private_key_jwt hoặc refresh token)", "SESSION": "Phiên đăng nhập (`id_token_hint`)",
              "BEARER": "Bearer token", "SELF": "Chính chủ tài khoản", "ASSIGNED": "Người rà soát được giao"}
        for k, v in pm.items(): pt = re.sub(r"\b%s\b" % k, v, pt)
        pt = re.sub(r"(PERM-12-[a-z-]+)", r"`\1`", pt) if not re.fullmatch(r"PERM-12-[a-z-]+", pt) else pt
        pt = pt.replace("scope `", "scope `")
        op["x-datahub-permission"] = {"permission": pt, "perms": re.findall(r"PERM-12-[a-z-]+", perm), "scopes": re.findall(r"iam:[a-z-]+", perm)}
        if server == "authz":
            op["servers"] = [{"url": "https://api.{tenantHost}.datahub.example.vn" + spec.AUTHZ_BASE, "variables": {"tenantHost": {"default": "lamdong"}}},
                             {"url": "http://dh-platform.dh-control.svc:8080" + spec.AUTHZ_BASE, "description": "Trong cụm"}]
            op["security"] = [{"oauth2Service": ["iam:decide"]}]
        elif server == "sso":
            op["servers"] = [{"url": "https://sso.datahub.example.vn", "description": "Keycloak (giả lập)"}]
            op["security"] = [] if code in PUBLIC else ([{"oauth2User": []}] if code in ("076", "078") else [{"mtlsClient": []}, {"privateKeyJwt": []}])
        else:
            sc = re.findall(r"iam:[a-z-]+", perm)
            if sc and not re.search(r"PERM-12", perm):
                op["security"] = [{"oauth2Service": sc}]
            elif sc:
                op["security"] = [{"oauth2User": []}, {"oauth2Service": sc}]
        if desc: op["description"] = desc
        params = [P(n + "Path") for n in re.findall(r"\{(\w+)\}", path) if n != "tenant"]
        if "{tenant}" in path: params.append(P("TenantRealm"))
        if m == "get" and (code in PAGED):
            params += [P("Page"), P("Size"), P("Sort")]
            if code in ("001", "014", "019", "032", "056", "089"): params.append(P("Q"))
        params += LISTQ.get(code, [])
        if code == "027": params.append(Q("reason", STR(500, minLength=10), "Lý do gỡ (bắt buộc)."))
        if code == "079": params += [{"name": "If-None-Match", "in": "header", "schema": STR(64)}, {"name": "X-DH-Applied-Version", "in": "header", "schema": INT(), "description": "Phiên bản APISIX đã áp dụng."},
                                     {"name": "X-DH-Node", "in": "header", "schema": STR(64)}]
        if code in IFM: params.append(P("IfMatch"))
        idem = m == "post" and code not in IFM and code not in NOIDEM and server == "iam"
        if idem:
            params.append(P("IdempotencyKey")); op["x-datahub-idempotent"] = True
        if server != "sso": params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = params
        if body:
            if code in FORMBODY:
                op["requestBody"] = {"required": True, "content": {"application/x-www-form-urlencoded": {"schema": R(body)}}}
            elif code == "010":
                op["requestBody"] = {"required": True, "content": {"multipart/form-data": {"schema": {"type": "object", "required": ["file"], "properties": {"file": {"type": "string", "contentEncoding": "binary"}, "meta": R("UserImportFile")}}},
                                                                   "application/json": {"schema": R(body)}}}
            else:
                op["requestBody"] = {"required": code not in ("012", "095"), "content": {"application/json": {"schema": R(body)}}}
        okr = {"description": "Thành công."}
        if success == "302":
            okr = {"description": "Chuyển hướng tới trang đăng nhập hoặc `redirect_uri` kèm `code` và `state`.", "headers": {"Location": {"schema": STR()}}}
        elif resp and success != "204":
            okr["content"] = {"application/json": {"schema": R(resp)}}
            hdr = {}
            if m == "get" and code not in ("072", "075") and resp not in ("DirectoryPage",) and "{" in path or code in ("079", "110"): hdr["ETag"] = {"schema": STR()}
            if m in ("post",) and success == "201": hdr["Location"] = {"schema": STR()}
            if success == "202": hdr["Location"] = {"schema": STR(), "description": "Tài nguyên theo dõi tiến trình."}
            if code == "001": hdr["X-DH-Projection-Lag"] = {"schema": INT(), "description": "Độ trễ bản chiếu so với Keycloak (giây)."}
            if hdr: okr["headers"] = hdr
        resps = {success: okr}
        if code == "079": resps["304"] = {"$ref": "#/components/responses/NotModified"}
        codes = list(errs)
        oauth = server == "sso"
        if not oauth:
            codes += [116, 7] if code not in PUBLIC else []
            if "{" in path: codes.append(1)
            if body or code in LISTQ or code in PAGED: codes.append(3)
            if code in IFM: codes.append(44)
            if idem: codes.append(45)
            if code in ("086", "087", "088"): codes = [c for c in codes if c not in (116, 7, 3)] + [102]
        if (not oauth and server == "iam" and m != "get" and "PERM-12" in perm and code not in STEPUP_EXCLUDE) or code in ACR3:
            codes.append(120); op["x-datahub-acr"] = 3 if code in ACR3 else 2
        codes = sorted(set(codes))
        for c in codes:
            cc, http = err_ref(c, oauth)
            name = "OAuthError" if oauth else HTTP_RESP[http]
            resps.setdefault(str(http), {"$ref": f"#/components/responses/{name}"})
        if code == "010": resps["413"] = {"$ref": "#/components/responses/TooLarge"}
        if not oauth: op["x-datahub-errors"] = [err_ref(c, False)[0] for c in codes]
        else: op["x-datahub-errors"] = [err_ref(c, True)[0] for c in codes]
        op["responses"] = dict(sorted(resps.items()))
        paths.setdefault(path, {})[m] = op
    return paths

def doc():
    return {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-12 Định danh và phân quyền API", "version": "1.0.0-draft",
               "summary": "Người dùng, vai trò, client của HTTT, token, realm theo tenant, chính sách OPA, quyết định ủy quyền, nhật ký và cảnh báo.",
               "description": ("API quản trị của module `iam` trong `dh-platform` (`/api/iam/v1`), API quyết định (`/api/authz/v1`) và các điểm cuối OIDC chuẩn của Keycloak "
                   "(`/realms/dh-{tenant}/protocol/openid-connect/*`, lỗi theo RFC 6749). Người dùng gọi qua BFF console (Authorization Code + PKCE); "
                   "PH-01, PH-15, PH-20, APISIX và DU gọi bằng token dịch vụ với scope `iam:*`.\n\nQuy ước (D03-04-PH12 §1): tenant lấy từ token; mọi `POST` tạo hoặc có tác dụng phụ nhận `Idempotency-Key`; "
                   "sửa và đổi trạng thái bắt buộc `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-12-nnn`; phân trang `page`/`size`. "
                   "Không API nào trả mật khẩu, bí mật client hay khóa riêng; bí mật giao qua địa chỉ bọc dùng một lần. Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-12"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH12", "x-datahub-phase": "PH-12"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn" + spec.BASE, "description": "Qua BFF console của tenant — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
                  {"url": "http://dh-platform.dh-control.svc:8080" + spec.BASE, "description": "Trong cụm, cho phân hệ khác và APISIX"},
                  {"url": "http://localhost:8082" + spec.BASE, "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": v} for v in spec.TAGS.values()],
      "paths": build(),
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-12-* (D02-08).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Token dịch vụ (`client_credentials` + mTLS hoặc `private_key_jwt`).",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"iam:client-provision": "PH-01 tạo, sửa scope, thu hồi client", "iam:dev-client": "PH-15 cấp client sandbox",
                           "iam:realm-provision": "PH-20 tạo realm, tạm ngừng, chuyển định danh", "iam:revocation-read": "APISIX, DU đọc danh sách chặn",
                           "iam:directory-read": "Tra danh bạ người dùng", "iam:decide": "Quyết định ủy quyền qua API", "iam:policy-data-read": "OPA kéo dữ liệu vai trò–quyền"}}}},
          "mtlsClient": {"type": "mutualTLS", "description": "Xác thực client bằng chứng thư (RFC 8705)."},
          "privateKeyJwt": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT", "description": "`client_assertion` ký bằng khóa riêng của client (RFC 7523)."}},
        "parameters": PARAMS, "responses": build_responses(), "schemas": SCHEMAS}}

if __name__ == "__main__":
    d = doc()
    out = os.path.join(ROOT, "openapi-iam.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH12 · OpenAPI PH-12 (dh-platform, module iam). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(d, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(len(v) for v in d["paths"].values())
    print(f"{n} operation, {len(SCHEMAS)} lược đồ → {out}")
