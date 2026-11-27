"""Lược đồ OpenAPI và ví dụ của PH-01 (module `onboarding` trong `dh-connect`).

Nguồn: D02-03-PH01 §4.2 (thực thể), §6 (bảng dữ liệu vào), D03-03-PH01 (kiểu, độ dài, enum ở CSDL).
Mọi tên miền, mã, dữ liệu trong ví dụ là giả lập (tenant T68, tổ chức SO-TUPHAP…).
"""
R = lambda n: {"$ref": f"#/components/schemas/{n}"}


def s(t, **kw):
    d = {"type": t}
    d.update(kw)
    return d


def obj(props, req=(), desc=None, **kw):
    d = {"type": "object", "properties": props, "additionalProperties": False}
    if req:
        d["required"] = list(req)
    if desc:
        d["description"] = desc
    d.update(kw)
    return d


def arr(items, **kw):
    d = {"type": "array", "items": items}
    d.update(kw)
    return d


def enum(*v, desc=None):
    d = {"type": "string", "enum": list(v)}
    if desc:
        d["description"] = desc
    return d


def nul(sch):
    return {"oneOf": [sch, {"type": "null"}]}


def fld(props, req=(), desc=None):
    """Đối tượng mở (không đóng) để ghép bằng allOf; lược đồ ghép đóng bằng `unevaluatedProperties: false`."""
    d = {"type": "object", "properties": props}
    if req:
        d["required"] = list(req)
    if desc:
        d["description"] = desc
    return d


def ext(*parts, desc=None):
    d = {"allOf": list(parts), "unevaluatedProperties": False}
    if desc:
        d["description"] = desc
    return d


def allow(part):
    return ext(part, R("AllowedActions"))


STR = lambda mx=None, **kw: s("string", **({"maxLength": mx} if mx else {}), **kw)
INT = lambda **kw: s("integer", **kw)
BOOL = s("boolean")
TS = s("string", format="date-time")
DATE = s("string", format="date")
UUID = s("string", format="uuid")
ANYOBJ = {"type": "object", "additionalProperties": True}
CNT = {"type": "object", "additionalProperties": INT()}
NTS = {"type": ["string", "null"], "format": "date-time"}
NSTR = lambda mx=None: {"type": ["string", "null"], **({"maxLength": mx} if mx else {})}

SCHEMAS = {
  # ---- kiểu dùng chung
  "SystemCode": STR(64, pattern="^[A-Z][A-Z0-9-]{2,63}$", description="Mã HTTT, bất biến, không dùng lại kể cả khi đã chấm dứt hoặc bị từ chối (BR-01-018)."),
  "OrgId": STR(64, description="Mã tổ chức ở PH-20 (DD-02)."),
  "Reason": STR(1000, minLength=10, description="Lý do ≥ 10 ký tự. Thiếu hoặc rỗng trả ERR-01-033."),
  "ReasonAny": STR(1000, minLength=1, description="Lý do bắt buộc, không rỗng. Thiếu trả ERR-01-033."),
  "SystemStatus": enum("DRAFT", "SUBMITTED", "APPROVED", "ACTIVE", "SUSPENDED", "TERMINATED", "REJECTED"),
  "ReviewStage": enum("WAITING_ASSIGN", "IN_REVIEW", "CONSULTING", "WAITING_APPROVAL", desc="Chỉ có khi `status = SUBMITTED`."),
  "ProvisionStage": enum("PROVISIONING", "AWAITING_KEY", "SANDBOX_READY", "PROVISION_FAILED", desc="Chỉ có khi `status = APPROVED`."),
  "SystemType": enum("PROVINCIAL", "NATIONAL", "MINISTRY", "LEGACY", "EXTERNAL"),
  "SystemRole": enum("CONSUMER", "PROVIDER", "PUBLISHER", "SUBSCRIBER"),
  "SecurityLevel": enum("L1", "L2", "L3", "L4", "L5"),
  "Classification": enum("PUBLIC", "INTERNAL", "RESTRICTED", "SENSITIVE", desc="Công khai (CK), Nội bộ (NB), Hạn chế (HC), Nhạy cảm (NC)."),
  "Direction": enum("CONSUME", "PROVIDE"),
  "ContactType": enum("BUSINESS", "TECHNICAL", "SECURITY"),
  "StepType": enum("TECHNICAL", "LEGAL", "SECURITY"),
  "StepResult": enum("PASS", "FAIL"),
  "Verdict": enum("APPROVED", "NARROWED", "REJECTED"),
  "CredentialEnv": enum("SANDBOX", "PRODUCTION"),
  "AuthMethod": enum("CLIENT_SECRET", "PRIVATE_KEY_JWT", "MTLS", "API_KEY", desc="`API_KEY` chỉ cho API dữ liệu mở."),
  "CredentialStatus": enum("PENDING", "ACTIVE", "ROTATING", "REVOKED", "EXPIRED"),
  "HandoverStatus": enum("PENDING", "OPENED", "EXPIRED", "CANCELLED", desc="Trạng thái kỹ thuật `OPENING` không lộ ra API (SDD §4.7)."),
  "CycleStatus": enum("OPEN", "WAITING", "DECIDING", "CLOSED"),
  "ChangeClass": enum("TECHNICAL", "OWNER_CHANGE", "FULL", "TERMINATE"),
  "ChangeStatus": enum("PENDING", "APPROVED", "REJECTED", "CANCELLED"),
  "AttachmentKind": enum("REQUEST_LETTER", "LEGAL_BASIS", "SECURITY_APPROVAL", "TECH_DOC", "OTHER"),
  "Period": enum("SECOND", "MINUTE", "HOUR", "DAY"),
  "ExportFormat": enum("CSV", "XLSX"),
  "SystemFlag": enum("REVIEW_OVERDUE", "CREDENTIAL_EXPIRING", "SANDBOX_TOO_LONG", "NO_TECH_CONTACT"),
  "AllowedActions": fld({
      "allowedActions": arr(STR(), description="Hành động người gọi được làm ngay bây giờ (đã tính quyền, trạng thái, bốn mắt)."),
      "disabledReasons": {"type": "object", "additionalProperties": STR(), "description": "Hành động có quyền nhưng trạng thái chưa cho phép → lý do tiếng Việt."}}),
  "PageMeta": obj({"number": INT(minimum=0), "size": INT(minimum=1, maximum=500), "totalElements": INT(minimum=0), "totalPages": INT(minimum=0)},
                  req=["number", "size", "totalElements", "totalPages"]),
  "ProblemDetails": {
      "type": "object", "description": "RFC 9457, mở rộng theo D03-04-PH01 §1.",
      "required": ["type", "title", "status", "code", "traceId"],
      "properties": {
          "type": STR(format="uri"), "title": STR(), "status": INT(), "detail": STR(), "instance": STR(),
          "code": STR(pattern="^ERR-(01|00)-[0-9]{3}$"), "traceId": STR(pattern="^[0-9a-f]{32}$"),
          "errors": arr(obj({"path": STR(), "rule": STR(), "message": STR()})),
          "issues": arr(R("ValidationIssue"), description="Kèm ERR-01-008."),
          "dependents": arr(R("Dependent"), description="Kèm ERR-01-034."),
          "currentEtag": STR(description="Kèm ERR-01-007."), "retryAfterSeconds": INT(description="Kèm ERR-01-026, 045, 054."),
          "lockedUntil": TS},
      "additionalProperties": True},
  "OrgRef": obj({"id": R("OrgId"), "name": STR(255)}, req=["id"]),
  "ValidationIssue": obj({"path": STR(), "code": STR(pattern="^ERR-01-[0-9]{3}$"), "severity": enum("ERROR", "WARNING"),
      "message": STR(), "guidance": STR()}, req=["path", "code", "severity", "message"]),
  "Dependent": obj({"type": enum("SUBSCRIPTION", "FLOW", "PUBLICATION", "CONNECTION", "SERVICE", "TOPIC"),
      "ref": STR(128), "name": STR(255), "orgName": STR(255), "ownerContactHint": STR(255, description="Tên tổ chức, không kèm thư điện tử, điện thoại.")},
      req=["type", "ref"]),

  # ---- HTTT thành viên
  "SystemSummaryFields": fld({
      "code": R("SystemCode"), "name": STR(255), "ownerOrg": R("OrgRef"), "status": R("SystemStatus"),
      "reviewStage": nul(R("ReviewStage")), "provisionStage": nul(R("ProvisionStage")), "group": nul(INT(minimum=1, maximum=4)),
      "roles": arr(R("SystemRole"), minItems=1), "securityLevel": R("SecurityLevel"), "scopeCount": INT(),
      "calls30d": {"type": ["integer", "null"], "description": "Từ PH-13; null nếu PH-13 không khả dụng."},
      "lastReviewAt": NTS, "flags": arr(R("SystemFlag")), "updatedAt": TS},
      req=["code", "name", "ownerOrg", "status", "roles", "securityLevel", "updatedAt"]),
  "SystemSummary": allow(R("SystemSummaryFields")),
  "SystemPage": obj({"items": arr(R("SystemSummary")), "page": R("PageMeta"),
      "facets": obj({"status": CNT, "group": CNT, "securityLevel": CNT, "ownerOrgId": CNT})}, req=["items", "page"]),
  "SystemFields": fld({
      "name": STR(255, minLength=3), "description": STR(2000), "ownerOrgId": R("OrgId"), "operatorName": STR(255),
      "systemType": R("SystemType"), "roles": arr(R("SystemRole"), minItems=1, uniqueItems=True), "securityLevel": R("SecurityLevel"),
      "securityApprovalRef": STR(255, description="Bắt buộc từ `L3` trở lên khi nộp."),
      "baseUrls": arr(STR(2048, format="uri", pattern="^https://"), maxItems=20, description="Chỉ `https` (ERR-01-049)."),
      "ipAllowlist": arr(STR(43, description="CIDR IPv4 hoặc IPv6; mức Hạn chế."), maxItems=100),
      "legacyRef": STR(255)}),
  "SystemCreate": {"allOf": [R("SystemFields"), fld({"code": R("SystemCode")}, req=["code"])],
      "required": ["code", "name", "description", "ownerOrgId", "systemType", "roles", "securityLevel"],
      "unevaluatedProperties": False},
  "SystemUpdate": ext(R("SystemFields"),
      desc="JSON Merge Patch (RFC 7396), chỉ trường được phép; không có `code`. Chỉ khi `status = DRAFT`."),
  "SystemDetail": {"allOf": [R("SystemSummaryFields"), R("AllowedActions"), fld({
      "description": STR(2000), "operatorName": NSTR(255), "systemType": R("SystemType"), "securityApprovalRef": NSTR(255),
      "baseUrls": arr(STR(2048)), "ipAllowlist": arr(STR(43)), "applicationNo": STR(32), "revisionNo": INT(minimum=0),
      "returnReason": NSTR(1000), "statusReason": NSTR(1000), "enforcement": enum("NONE", "PENDING", "DONE"),
      "technicalProfile": nul(R("TechnicalProfileView")), "dataDemands": arr(R("DataDemand")), "ceiling": arr(R("ScopeCeiling")),
      "contacts": arr(R("Contact")), "credentials": arr(R("Credential")), "legacyRef": NSTR(255),
      "submittedAt": NTS, "approvedAt": NTS, "activatedAt": NTS, "terminatedAt": NTS, "createdAt": TS, "createdBy": STR(64)})],
      "unevaluatedProperties": False},
  "StateHistoryItem": obj({"fromStatus": nul(R("SystemStatus")), "toStatus": R("SystemStatus"), "reason": NSTR(1000), "actor": STR(64),
      "emergency": BOOL, "at": TS, "traceId": STR(pattern="^[0-9a-f]{32}$")}, req=["toStatus", "actor", "at"]),
  "HistoryPage": obj({"items": arr(R("StateHistoryItem")), "page": R("PageMeta")}, req=["items", "page"]),
  "WithdrawRequest": obj({"reason": R("ReasonAny")}, req=["reason"]),
  "ProgressView": obj({
      "timeline": arr(obj({"event": STR(64), "at": TS, "actor": STR(64), "note": NSTR(1000)}, req=["event", "at"])),
      "waitingOn": nul(obj({"role": STR(32), "dueAt": TS, "overdue": BOOL}, req=["role"])),
      "returnRequests": arr(R("ReturnItem"))}, req=["timeline"]),
  "ReturnItem": obj({"path": STR(256), "requirement": STR(2000)}, req=["path", "requirement"]),

  # ---- tài liệu, mẫu
  "Attachment": obj({"attachmentId": UUID, "kind": R("AttachmentKind"), "title": NSTR(255), "fileName": STR(255), "sizeBytes": INT(minimum=1),
      "sha256": STR(pattern="^[0-9a-f]{64}$"), "scanStatus": enum("PENDING", "CLEAN"), "uploadedBy": STR(64), "uploadedAt": TS},
      req=["attachmentId", "kind", "fileName", "sizeBytes", "sha256", "scanStatus"]),
  "AttachmentList": obj({"items": arr(R("Attachment"))}, req=["items"]),
  "AttachmentUpload": obj({"file": {"type": "string", "contentEncoding": "binary", "description": "Tệp ≤ `onboarding.attachment.maxSizeMb` (mặc định 20 MB); PDF, DOCX, XLSX, PNG, JPG; kiểm theo nội dung (Tika), quét mã độc."},
      "kind": R("AttachmentKind"), "title": STR(255)}, req=["file", "kind"]),
  "Template": obj({"templateCode": STR(64), "title": STR(255), "version": STR(16), "updatedAt": TS}, req=["templateCode", "title", "version"]),
  "TemplateList": obj({"items": arr(R("Template"))}, req=["items"]),

  # ---- kỹ thuật và nhu cầu
  "TechnicalProfileFields": fld({
      "systemKind": enum("WEB", "DESKTOP", "MOBILE_BACKEND", "BATCH", "OTHER"), "technology": STR(255), "hasApi": BOOL,
      "apiSpecKind": enum("OPENAPI", "WSDL", "NONE", "OTHER", desc="Bắt buộc khi `hasApi`."),
      "protocols": arr(enum("REST", "SOAP", "JMS", "AMQP", "MQTT", "SFTP", "DB", "OTHER"), minItems=1, uniqueItems=True),
      "dbType": enum("POSTGRESQL", "MYSQL", "SQLSERVER", "ORACLE", "OTHER", "NONE", desc="Bắt buộc khi không `hasApi`."),
      "cdcLogEnabled": enum("YES", "NO", "UNKNOWN", desc="Bắt buộc khi nhóm 3."),
      "underMaintenance": BOOL, "replacementPlanned": BOOL, "replacementDate": DATE,
      "criticality": enum("NORMAL", "CRITICAL"), "maxConcurrentConnections": INT(minimum=1), "expectedDailyCalls": INT(minimum=0),
      "operatingHours": STR(255)},
      req=["systemKind", "technology", "hasApi", "protocols", "underMaintenance", "replacementPlanned", "criticality",
           "maxConcurrentConnections", "expectedDailyCalls"]),
  "TechnicalProfile": ext(R("TechnicalProfileFields")),
  "TechnicalProfileView": ext(R("TechnicalProfileFields"), fld({
      "proposedGroup": INT(minimum=1, maximum=4), "confirmedGroup": nul(INT(minimum=1, maximum=4)),
      "explanation": arr(STR(500), description="Quy tắc đã khớp, theo thứ tự ưu tiên (FR-01-006).")}, req=["proposedGroup"])),
  "LegalBasis": obj({"docNo": STR(255), "issuedOn": DATE, "issuer": STR(255), "validUntil": DATE, "attachmentId": UUID},
      req=["docNo", "issuedOn", "issuer", "attachmentId"]),
  "DataDemandFields": fld({
      "direction": R("Direction"), "dataType": STR(64, pattern="^[A-Z][A-Z0-9_]{1,63}$"), "scopeRequested": STR(200),
      "classification": R("Classification"), "purpose": STR(500), "legalBasis": R("LegalBasis")},
      req=["direction", "dataType", "scopeRequested", "classification", "purpose"],
      desc="`legalBasis` bắt buộc khi `direction = CONSUME` (ERR-01-015)."),
  "DataDemandInput": ext(R("DataDemandFields")),
  "DataDemandsPut": obj({"demands": arr(R("DataDemandInput"), maxItems=200)}, req=["demands"]),
  "DataDemand": {"allOf": [R("DataDemandFields"), fld({
      "demandId": UUID, "verdict": nul(R("Verdict")), "scopeApproved": NSTR(200), "opinion": NSTR(2000), "missingLegalBasis": BOOL})],
      "required": ["demandId"], "unevaluatedProperties": False},
  "ScopeCeiling": obj({"dataType": STR(64), "scopeApproved": STR(200), "classification": R("Classification"), "legalBasis": nul(R("LegalBasis")),
      "validUntil": nul(DATE), "inUse": BOOL, "lastUsedAt": NTS, "status": enum("ACTIVE", "SUSPENDED", "CLOSED")},
      req=["dataType", "scopeApproved", "status"]),
  "DataDemandList": obj({"demands": arr(R("DataDemand")), "ceiling": arr(R("ScopeCeiling"))}, req=["demands", "ceiling"]),

  # ---- đầu mối
  "ContactInput": obj({
      "contactType": R("ContactType"), "fullName": STR(255), "position": STR(255),
      "email": STR(254, format="email"), "phone": STR(16, pattern="^\\+[1-9][0-9]{7,14}$"), "isPublic": BOOL,
      "replaceContactId": UUID},
      req=["contactType", "fullName", "position", "email"]),
  "ContactUpdate": obj({"fullName": STR(255), "position": STR(255), "email": STR(254, format="email"),
      "phone": STR(16, pattern="^\\+[1-9][0-9]{7,14}$"), "isPublic": BOOL}),
  "Contact": obj({"contactId": UUID, "contactType": R("ContactType"), "fullName": STR(255), "position": STR(255), "email": STR(254),
      "phone": NSTR(16), "isPublic": BOOL, "hasAccount": BOOL, "lastConfirmedAt": NTS, "status": enum("ACTIVE", "INACTIVE")},
      req=["contactId", "contactType", "fullName", "email", "status"], desc="Dữ liệu cá nhân mức Hạn chế (HC); `SECURITY` chỉ TA, SO thấy."),
  "ContactList": obj({"items": arr(R("Contact"))}, req=["items"]),

  # ---- kiểm tra, nộp, thẩm định
  "ValidateResult": obj({"valid": BOOL, "errorCount": INT(minimum=0), "warningCount": INT(minimum=0), "issues": arr(R("ValidationIssue"))},
      req=["valid", "errorCount", "warningCount", "issues"]),
  "SubmitRequest": obj({"note": STR(2000)}),
  "StateChangeResult": obj({"code": R("SystemCode"), "status": R("SystemStatus"), "reviewStage": nul(R("ReviewStage")),
      "provisionStage": nul(R("ProvisionStage")), "revisionNo": INT(minimum=0), "enforcement": enum("NONE", "PENDING", "DONE"),
      "steps": arr(obj({"stepType": R("StepType"), "dueAt": TS, "status": STR(16)}, req=["stepType"])),
      "ceiling": arr(R("ScopeCeiling")), "progressUrl": STR(description="Có khi trả `202`."), "updatedAt": TS},
      req=["code", "status"]),
  "TechnicalReviewRequest": obj({
      "result": R("StepResult"), "confirmedGroup": INT(minimum=1, maximum=4), "adapterTypes": arr(enum("REST", "SOAP", "MQ", "FILE", "DB", "CDC")),
      "authMethod": enum("CLIENT_SECRET", "PRIVATE_KEY_JWT", "MTLS"),
      "proposedQuota": obj({"limit": INT(minimum=1), "period": R("Period")}, req=["limit", "period"]),
      "cdcFeasible": enum("YES", "NO", "FALLBACK"), "effortDays": INT(minimum=0), "opinion": STR(4000)},
      req=["result", "confirmedGroup", "authMethod", "proposedQuota"], desc="`opinion` bắt buộc khi `FAIL`; `adapterTypes` bắt buộc khi nhóm 2, 3."),
  "LegalReviewRequest": obj({
      "items": arr(obj({"demandId": UUID, "verdict": R("Verdict"), "scopeApproved": STR(200), "opinion": STR(2000)}, req=["demandId", "verdict"]), minItems=1),
      "overallOpinion": STR(4000)}, req=["items"],
      desc="`scopeApproved` bắt buộc khi `NARROWED` và phải hẹp hơn phạm vi đề nghị (ERR-01-037 khi mở rộng); `opinion` bắt buộc khi `NARROWED`, `REJECTED`."),
  "SecurityReviewRequest": obj({"result": R("StepResult"), "securityLevelConfirmed": R("SecurityLevel"), "opinion": STR(4000)},
      req=["result", "securityLevelConfirmed"], desc="`opinion` bắt buộc khi `FAIL`."),
  "LegalSecurityReviewRequest": {"oneOf": [R("LegalReviewRequest"), R("SecurityReviewRequest")],
      "description": "`reviewKind = legal` dùng `LegalReviewRequest`; `reviewKind = security` dùng `SecurityReviewRequest`."},
  "ReviewStepResult": obj({
      "stepType": R("StepType"), "result": R("StepResult"), "confirmedGroup": INT(minimum=1, maximum=4), "minAuthMethod": R("AuthMethod"),
      "summary": obj({"approved": INT(minimum=0), "narrowed": INT(minimum=0), "rejected": INT(minimum=0)}),
      "ceilingPreview": arr(obj({"dataType": STR(64), "scopeApproved": STR(200)}, req=["dataType", "scopeApproved"])),
      "reviewStage": nul(R("ReviewStage")), "finishedAt": TS}, req=["stepType", "result"]),
  "QuotaImpactRequest": obj({"services": arr(STR(128), maxItems=50, description="Dịch vụ quốc gia cần đánh giá; bỏ trống thì lấy từ nhu cầu."),
      "expectedDailyCalls": INT(minimum=0)}),
  "QuotaImpactResult": obj({"impact": arr(obj({"service": STR(128), "remaining": INT(minimum=0), "projected": INT(minimum=0),
      "level": enum("LOW", "MEDIUM", "HIGH"), "suggestion": STR(500)}, req=["service", "level"])), "partial": BOOL}, req=["impact"]),
  "ReviewQueueItem": obj({"systemCode": R("SystemCode"), "systemName": STR(255), "applicationNo": STR(32), "stepType": R("StepType"),
      "dueAt": TS, "overdue": BOOL, "assignee": nul(obj({"userId": STR(64), "displayName": STR(255)})), "status": enum("OPEN", "CONSULTING")},
      req=["systemCode", "stepType", "dueAt", "overdue"]),
  "ReviewQueuePage": obj({"items": arr(R("ReviewQueueItem")), "page": R("PageMeta")}, req=["items", "page"]),
  "AssignRequest": obj({"stepType": R("StepType"), "assigneeId": STR(64, description="Người được giao. Bỏ trống: người gọi tự nhận bước (cần `PERM-01-review-claim` và đúng vai trò của bước); giao cho người khác cần `PERM-01-approve`.")},
      req=["stepType"]),
  "ConsultRequest": obj({"stepType": R("StepType"), "consulteeId": STR(64), "question": STR(2000), "expectedBy": DATE},
      req=["stepType", "consulteeId", "question"]),
  "ResumeConsultRequest": obj({"stepType": R("StepType"), "note": STR(2000)}, req=["stepType"]),
  "ReviewStep": obj({"stepType": R("StepType"), "status": enum("OPEN", "CONSULTING", "DONE", "RETURNED", "WITHDRAWN", "CARRIED"),
      "assigneeId": NSTR(64), "dueAt": NTS, "finishedAt": NTS, "pausedMillis": INT(minimum=0)}, req=["stepType", "status"]),
  "ReturnRequest": obj({"requests": arr(R("ReturnItem"), minItems=1, maxItems=50), "note": STR(2000)}, req=["requests"]),
  "ApproveRequest": obj({"comment": STR(2000), "authCode": STR(16, description="Mã xác thực lại hai yếu tố khi hệ thống yêu cầu (ERR-01-035).")}),
  "RejectRequest": obj({"comment": STR(2000, minLength=1), "authCode": STR(16)}, req=["comment"]),

  # ---- định danh, bàn giao
  "Credential": allow(fld({
      "credentialId": STR(64), "environment": R("CredentialEnv"), "authMethod": R("AuthMethod"), "clientId": STR(128),
      "certFingerprint": NSTR(128), "status": R("CredentialStatus"), "disabled": BOOL, "disabledReason": NSTR(32),
      "expiresAt": NTS, "lastUsedAt": NTS, "rotationEndsAt": NTS, "secretAgeDays": INT(minimum=0), "keyRegistered": BOOL, "createdAt": TS},
      req=["credentialId", "environment", "authMethod", "clientId", "status"],
      desc="Không có giá trị bí mật và không có `secret_ref`.")),
  "CredentialList": obj({"credentials": arr(R("Credential"))}, req=["credentials"]),
  "ExpiringPage": obj({"items": arr(obj({"systemCode": R("SystemCode"), "credentialId": STR(64), "environment": R("CredentialEnv"),
      "expiresAt": TS, "daysLeft": INT(), "ownerOrg": R("OrgRef")}, req=["systemCode", "credentialId", "expiresAt", "daysLeft"])),
      "page": R("PageMeta")}, req=["items", "page"]),
  "SagaStatus": obj({"sagaId": UUID, "stage": R("ProvisionStage"), "startedAt": TS, "nextRetryAt": NTS, "attempt": INT(minimum=0),
      "steps": arr(obj({"name": enum("RECORD", "CREATE_CLIENT", "STORE_SECRET", "CREATE_CONSUMER", "ACTIVATE", "HANDOVER", "NOTIFY"),
          "status": enum("PENDING", "RUNNING", "ACCEPTED", "DONE", "FAILED", "COMPENSATED", "SKIPPED"), "at": NTS, "errorCode": NSTR(16)},
          req=["name", "status"]))}, req=["sagaId", "stage", "steps"]),
  "ProvisionRequest": obj({"note": STR(1000)}),
  "PublicKeyRequest": obj({"kind": enum("JWKS", "CSR", "CERT"), "payload": STR(16384, description="JWKS hoặc JWK dạng JSON; CSR, chứng thư dạng PEM; ≤ 16 KB. Chỉ khóa công khai."),
      "kid": STR(64, pattern="^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$"), "notAfterRequested": DATE}, req=["kind", "payload"],
      desc="`kid` bắt buộc với `JWKS`; khóa ES256 (P-256) hoặc PS256 (RSA ≥ 3072 bit) (ERR-01-027)."),
  "SignCsrRequest": obj({"notAfterRequested": DATE}),
  "CredentialKeyResult": obj({"credentialId": STR(64), "kid": NSTR(64), "certFingerprint": NSTR(128), "certificatePem": NSTR(16384), "expiresAt": TS,
      "provisionStage": nul(R("ProvisionStage"))}, req=["credentialId", "expiresAt"]),
  "HandoverCreate": obj({"recipientContactId": UUID, "ttlHours": INT(minimum=1, maximum=72)},
      desc="`recipientContactId` mặc định là đầu mối `TECHNICAL` chính; phải có tài khoản (ERR-01-003)."),
  "HandoverCreated": obj({"handoverId": UUID, "status": R("HandoverStatus"), "expiresAt": TS,
      "recipient": obj({"contactId": UUID, "fullName": STR(255), "emailMasked": STR(254)}, req=["contactId"])},
      req=["handoverId", "status", "expiresAt", "recipient"], desc="Không có liên kết gốc; liên kết chỉ gửi qua thư (SEC-33)."),
  "HandoverOpenRequest": obj({"token": STR(128, minLength=43, writeOnly=True, description="Mã trong liên kết `/ket-noi/ban-giao/{token}`; 256 bit, base64url.")}, req=["token"]),
  "HandoverOpenResult": obj({
      "maHeThong": R("SystemCode"),
      "thongTinKetNoi": obj({"clientId": STR(128), "clientSecret": STR(512, readOnly=True, description="Chỉ có ở lược đồ này, hiển thị đúng một lần; không bao giờ ghi log, vết, đệm."),
          "tokenEndpoint": STR(2048, format="uri"), "apiBaseUrl": STR(2048, format="uri"), "authMethod": R("AuthMethod"),
          "scopes": arr(STR(128)), "quota": obj({"limit": INT(), "period": R("Period")})},
          req=["clientId", "tokenEndpoint", "apiBaseUrl", "authMethod"]),
      "canhBao": STR(500), "huongDan": STR(2048, format="uri")},
      req=["maHeThong", "thongTinKetNoi"], desc="Đi kèm `Cache-Control: no-store`; sau lần mở bản sao bí mật bị hủy (BR-01-006)."),
  "SandboxTestResult": obj({"authOk": BOOL, "apiOk": BOOL, "callCount": INT(minimum=0), "successCount": INT(minimum=0), "required": INT(minimum=1),
      "errors": arr(obj({"code": STR(64), "count": INT(minimum=1), "guidance": STR(1000)}, req=["code", "count"])),
      "readyToActivate": BOOL, "source": enum("PH03", "PH13", "MANUAL"), "observedAt": TS, "partial": BOOL},
      req=["authOk", "apiOk", "callCount", "required", "readyToActivate"]),
  "SandboxTestList": obj({"items": arr(R("SandboxTestResult")), "readyToActivate": BOOL}, req=["items", "readyToActivate"]),
  "ActivateRequest": obj({"note": STR(2000), "authCode": STR(16)}),
  "RotateRequest": obj({"reason": STR(1000), "overlapDays": INT(minimum=0, maximum=14, default=7, description="0 chỉ khi do sự cố (vô hiệu bí mật cũ ngay).")}),
  "RotateResult": obj({"credentialId": STR(64), "status": R("CredentialStatus"), "rotationEndsAt": NTS,
      "handover": nul(obj({"handoverId": UUID, "expiresAt": TS}, req=["handoverId"]))}, req=["credentialId", "status"]),
  "FinishRotationRequest": obj({"note": STR(1000)}),
  "RevokeRequest": obj({"reason": R("ReasonAny"), "confirmImpact": BOOL, "authCode": STR(16)}, req=["reason"]),
  "RevokeResult": obj({"credentialId": STR(64), "status": R("CredentialStatus"), "enforcement": enum("DONE", "PENDING"), "revokedAt": TS},
      req=["credentialId", "status", "enforcement"]),
  "EnableCredentialRequest": obj({"reason": R("ReasonAny")}, req=["reason"]),

  # ---- vòng đời
  "SuspendRequest": obj({"reasonCode": enum("SECURITY_SUSPECT", "OVERLOAD", "OWNER_REQUEST", "LEGAL_EXPIRED", "OTHER"),
      "reason": R("Reason"), "expectedUntil": DATE, "confirmImpact": BOOL, "authCode": STR(16)}, req=["reasonCode", "reason"]),
  "ResumeRequest": obj({"reason": R("Reason"), "confirmCredentialsRotated": BOOL, "authCode": STR(16)}, req=["reason"]),
  "TerminateRequest": obj({"reason": R("Reason"), "legalBasis": STR(1000), "confirmImpact": BOOL}, req=["reason"]),
  "EmergencyRequest": obj({"mode": enum("SUSPEND", "TERMINATE"), "reason": R("Reason"), "incidentRef": STR(128), "authCode": STR(16)},
      req=["mode", "reason"]),
  "EmergencyResult": obj({"actionId": UUID, "status": enum("PENDING_CONFIRM", "CONFIRMED", "OVERDUE"), "systemStatus": R("SystemStatus"),
      "confirmBy": TS, "enforcement": enum("NONE", "PENDING", "DONE")}, req=["actionId", "status", "confirmBy"]),
  "ConfirmEmergencyRequest": obj({"comment": STR(2000), "authCode": STR(16)}),
  "ImpactResult": obj({"impactLevel": enum("NONE", "LOW", "MEDIUM", "HIGH"), "partial": BOOL, "computedAt": TS,
      "dependents": arr(R("Dependent"))}, req=["impactLevel", "partial", "dependents"]),
  "ChangeRequestCreate": obj({"changes": {"allOf": [R("SystemFields")], "description": "Trường cần đổi (như `SystemCreate` trừ `code`) và/hoặc hồ sơ kỹ thuật."},
      "technicalProfile": R("TechnicalProfile"), "reason": R("Reason")}, req=["reason"],
      desc="Thay đổi mức `NONE` được áp dụng ngay (200); các mức khác tạo đề nghị chờ duyệt (202), phân loại theo bảng ở FRS §6.5."),
  "ChangeRequest": obj({"id": UUID, "changeClass": R("ChangeClass"), "status": R("ChangeStatus"), "reason": STR(1000), "diff": ANYOBJ,
      "requestedBy": STR(64), "requestedAt": TS, "decidedBy": NSTR(64), "decidedAt": NTS, "decisionComment": NSTR(2000)},
      req=["id", "changeClass", "status", "requestedBy", "requestedAt"]),
  "ChangeRequestOutcome": obj({"applied": BOOL, "changeRequest": nul(R("ChangeRequest")), "system": nul(R("SystemSummary"))}, req=["applied"]),
  "ChangeRequestList": obj({"items": arr(R("ChangeRequest"))}, req=["items"]),
  "ChangeDecision": obj({"decision": enum("APPROVE", "REJECT"), "comment": STR(2000), "authCode": STR(16)}, req=["decision"],
      desc="`comment` bắt buộc khi `REJECT`; duyệt chấm dứt phải do TA khác người đề nghị (ERR-01-017)."),
  "ScopeExpansionCreate": obj({"demands": arr(R("DataDemandInput"), minItems=1, maxItems=200), "reason": R("Reason")}, req=["demands", "reason"]),

  # ---- nội bộ
  "ReconcileRequest": obj({"systemCodes": arr(R("SystemCode"), maxItems=500, description="Bỏ trống: toàn bộ HTTT của tenant."), "reason": STR(500)}),
  "ReconcileAccepted": obj({"reconciliationId": UUID, "batches": INT(minimum=0), "acceptedAt": TS}, req=["reconciliationId", "batches"]),
  "ReplicaSystem": obj({
      "code": R("SystemCode"), "name": STR(255), "ownerOrgId": R("OrgId"), "status": R("SystemStatus"), "roles": arr(R("SystemRole")),
      "securityLevel": R("SecurityLevel"), "group": nul(INT(minimum=1, maximum=4)), "baseUrls": arr(STR(2048)),
      "clientIds": obj({"SANDBOX": NSTR(128), "PRODUCTION": NSTR(128)}), "activatedAt": NTS, "updatedAt": TS,
      "ceilingDataTypes": arr(STR(64))},
      req=["code", "name", "ownerOrgId", "status", "roles", "securityLevel", "updatedAt"],
      desc="Bản ghi rút gọn: không có liên hệ cá nhân, bí mật, `secret_ref`, nội dung hồ sơ (BR-01-030)."),
  "ReplicaPage": obj({"items": arr(R("ReplicaSystem")), "nextUpdatedSince": NTS, "page": R("PageMeta")}, req=["items", "nextUpdatedSince", "page"]),
  "ProvisioningCallback": obj({"sagaId": UUID, "step": enum("CREATE_CLIENT", "STORE_SECRET", "CREATE_CONSUMER"),
      "outcome": enum("DONE", "FAILED"), "externalRef": STR(256), "errorCode": STR(64), "errorDetail": STR(1000)},
      req=["sagaId", "step", "outcome"]),
  "CallbackAck": obj({"sagaId": UUID, "step": STR(32), "accepted": BOOL, "duplicate": BOOL}, req=["sagaId", "step", "accepted", "duplicate"]),
  "SuspensionProposal": obj({"systemCode": R("SystemCode"), "alertId": UUID, "severity": enum("HIGH", "CRITICAL"), "reason": STR(1000, minLength=10),
      "evidenceUrl": STR(2048, format="uri"), "incidentRef": STR(64)}, req=["systemCode", "alertId", "reason"],
      desc="Đề xuất của PH-13 từ cảnh báo an ninh (`alertId`); `incidentRef` chuyển thành `incidentRef` của FR-01-032 khi SO quyết định. PH-13 chỉ đề xuất, không tạm ngừng."),
  "SuspensionProposalAck": obj({"systemCode": R("SystemCode"), "alertId": UUID, "taskId": nul(UUID), "accepted": BOOL, "duplicate": BOOL},
      req=["systemCode", "alertId", "accepted", "duplicate"], desc="`duplicate = true` khi đã nhận đề xuất cùng `alertId` cho HTTT này (không tạo việc thứ hai)."),

  # ---- rà soát quyền
  "AccessReviewCreate": obj({"name": STR(255, minLength=3), "scope": {"oneOf": [enum("ALL_ACTIVE"), arr(R("OrgId"), minItems=1, maxItems=200)]},
      "periodFrom": DATE, "periodTo": DATE}, req=["name"],
      desc="`scope` mặc định `ALL_ACTIVE` (kỳ định kỳ, cập nhật mốc rà soát toàn tenant); danh sách tổ chức tạo kỳ theo chủ đề."),
  "AccessReviewCycle": obj({"cycleCode": STR(32), "name": STR(255), "kind": enum("PERIODIC", "TOPIC"), "status": R("CycleStatus"),
      "periodFrom": DATE, "periodTo": DATE, "itemCount": INT(minimum=0), "confirmationsSent": INT(minimum=0), "confirmationsResponded": INT(minimum=0),
      "openedBy": STR(64), "openedAt": TS, "closedAt": NTS},
      req=["cycleCode", "name", "kind", "status", "itemCount", "openedAt"]),
  "AccessReviewPage": obj({"items": arr(R("AccessReviewCycle")), "page": R("PageMeta")}, req=["items", "page"]),
  "AccessReviewItem": obj({"itemId": UUID, "systemCode": R("SystemCode"), "ownerOrgId": R("OrgId"), "dataType": STR(64), "scopeApproved": STR(200),
      "usageInPeriod": INT(minimum=0), "unusedDays": INT(minimum=0), "legalExpired": BOOL, "flags": arr(STR(32)),
      "proposal": nul(enum("REVOKE_SCOPE", "NARROW", "KEEP")), "ownerResponse": nul(enum("KEEP", "REDUCE", "RELEASE")),
      "decision": nul(enum("KEEP", "NARROW", "REVOKE_SCOPE")), "usagePartial": BOOL},
      req=["itemId", "systemCode", "dataType", "scopeApproved", "usageInPeriod", "unusedDays"]),
  "AccessReviewItemPage": obj({"items": arr(R("AccessReviewItem")), "page": R("PageMeta"), "usagePartial": BOOL}, req=["items", "page"]),
  "SendConfirmationsRequest": obj({"orgIds": arr(R("OrgId"), maxItems=500, description="Bỏ trống: mọi tổ chức có mục.")}),
  "SendConfirmationsAccepted": obj({"sent": INT(minimum=0), "skipped": INT(minimum=0), "orgsWithoutContact": arr(R("OrgId"))}, req=["sent"]),
  "ConfirmationView": obj({"orgId": R("OrgId"), "orgName": STR(255), "cycleCode": STR(32), "expiresAt": TS,
      "items": arr(obj({"itemId": UUID, "systemCode": R("SystemCode"), "dataType": STR(64), "scopeApproved": STR(200),
          "usageInPeriod": INT(minimum=0), "unusedDays": INT(minimum=0)}, req=["itemId", "systemCode", "dataType", "scopeApproved"]))},
      req=["orgId", "cycleCode", "expiresAt", "items"]),
  "ConfirmationRespond": obj({"answers": arr(obj({"itemId": UUID, "answer": enum("KEEP", "REDUCE", "RELEASE"),
      "scopeReduced": STR(200), "note": STR(1000)}, req=["itemId", "answer"]), minItems=1)}, req=["answers"],
      desc="`scopeReduced` bắt buộc khi `REDUCE`."),
  "ConfirmationRespondResult": obj({"answered": INT(minimum=0), "kept": INT(minimum=0), "reduced": INT(minimum=0), "released": INT(minimum=0)},
      req=["answered"]),
  "ItemDecisionRequest": obj({"items": arr(obj({"itemId": UUID, "decision": enum("KEEP", "NARROW", "REVOKE_SCOPE"), "scopeNew": STR(200),
      "reason": R("ReasonAny")}, req=["itemId", "decision", "reason"]), minItems=1, maxItems=500)}, req=["items"],
      desc="`scopeNew` bắt buộc khi `NARROW` và phải là tập con phạm vi đã duyệt; mục có `legalExpired` không được `KEEP` (ERR-01-041)."),
  "ItemDecisionResult": obj({"decided": INT(minimum=0), "kept": INT(minimum=0), "narrowed": INT(minimum=0), "revoked": INT(minimum=0),
      "cycleStatus": R("CycleStatus")}, req=["decided", "cycleStatus"]),
  "MarkLegalExpiredRequest": obj({"docNo": STR(255), "repealedOn": DATE, "note": STR(1000)}, req=["docNo", "repealedOn"]),
  "MarkLegalExpiredResult": obj({"affectedCeilings": INT(minimum=0), "suspendedSystems": INT(minimum=0)}, req=["affectedCeilings"]),
  "ReviewReport": obj({"cycleCode": STR(32), "status": R("CycleStatus"), "summary": obj({"items": INT(), "kept": INT(), "narrowed": INT(),
      "revoked": INT(), "noResponseOrgs": INT()}), "evidenceHash": nul(STR(pattern="^[0-9a-f]{64}$")), "closedAt": NTS},
      req=["cycleCode", "status", "summary"]),
  "ExportRequest": obj({"format": R("ExportFormat"), "purpose": STR(500), "columns": arr(STR(32), maxItems=30),
      "filters": {"type": "object", "additionalProperties": True, "description": "Bộ lọc như API liệt kê tương ứng."}}, req=["format"],
      desc="`purpose` bắt buộc với xuất danh bạ (ERR-01-033); xuất toàn bộ tenant chỉ TA, AU, PA."),
  "ReportExportRequest": obj({"format": enum("PDF", "XLSX")}, req=["format"]),
  "JobAccepted": obj({"jobId": UUID, "status": enum("QUEUED", "RUNNING"), "statusUrl": STR()}, req=["jobId", "status"]),
  "Job": obj({"jobId": UUID, "kind": enum("EXPORT_SYSTEMS", "EXPORT_CONTACTS", "EXPORT_REVIEW_REPORT"),
      "status": enum("QUEUED", "RUNNING", "DONE", "FAILED", "EXPIRED"), "createdAt": TS, "finishedAt": NTS,
      "downloadUrl": nul(STR(2048, format="uri", description="Liên kết ký, hết hạn sau 15 phút.")), "rowCount": INT(minimum=0), "errorCode": NSTR(16)},
      req=["jobId", "kind", "status", "createdAt"]),

  # ---- danh bạ
  "DirectoryContact": obj({"contactId": UUID, "fullName": STR(255), "position": STR(255), "phone": NSTR(16), "email": STR(254), "orgId": R("OrgId"),
      "orgName": STR(255), "systemCode": R("SystemCode"), "systemName": STR(255), "contactType": enum("BUSINESS", "TECHNICAL"),
      "lastConfirmedAt": NTS}, req=["contactId", "fullName", "email", "orgName", "contactType"]),
  "DirectoryPage": obj({"items": arr(R("DirectoryContact")), "page": R("PageMeta")}, req=["items", "page"],
      desc="Chỉ đầu mối công khai; đầu mối `SECURITY` không có ở đây (BR-01-027)."),
  "DirectoryGaps": obj({"orgsWithoutTechnicalContact": arr(obj({"orgId": R("OrgId"), "orgName": STR(255), "systemCodes": arr(R("SystemCode"))},
      req=["orgId", "systemCodes"])),
      "staleContacts": arr(obj({"contactId": UUID, "systemCode": R("SystemCode"), "orgId": R("OrgId"), "lastConfirmedAt": NTS}, req=["contactId", "systemCode"])),
      "page": R("PageMeta")}, req=["orgsWithoutTechnicalContact", "staleContacts"]),

  # ---- di trú, tham số, thống kê
  "LegacyImportUpload": obj({"file": {"type": "string", "contentEncoding": "binary", "description": "CSV, XLSX hoặc JSON; ≤ `onboarding.legacyImport.maxRows` dòng (mặc định 5.000)."},
      "source": enum("APIM_APPLICATION", "HUB_PUBLISHER", "HUB_SUBSCRIBER")}, req=["file", "source"]),
  "LegacyImportJob": obj({"jobId": UUID, "source": enum("APIM_APPLICATION", "HUB_PUBLISHER", "HUB_SUBSCRIBER"),
      "status": enum("UPLOADED", "PARSING", "PREVIEWED", "CONFIRMED", "DONE", "FAILED", "CANCELLED"),
      "rowCount": INT(minimum=0), "created": INT(minimum=0), "skipped": INT(minimum=0), "warnings": INT(minimum=0), "secretsDropped": INT(minimum=0),
      "preview": arr(obj({"row": INT(minimum=1), "legacyRef": STR(255), "code": STR(64), "name": STR(255), "matchedOrgId": NSTR(64),
          "action": enum("CREATE", "SKIP_DUPLICATE", "NEEDS_REVIEW"), "warning": NSTR(500)}, req=["row", "action"])),
      "errorCode": NSTR(16), "createdAt": TS, "finishedAt": NTS}, req=["jobId", "status", "rowCount"],
      desc="Cột bí mật của hệ cũ bị bỏ khi đọc, chỉ đếm vào `secretsDropped` (không bao giờ trả giá trị)."),
  "LegacyImportConfirm": obj({"skipRows": arr(INT(minimum=1), maxItems=20000, description="Số dòng bỏ qua, mặc định không bỏ dòng nào.")}),
  "Setting": obj({"key": STR(64, pattern="^[a-zA-Z][a-zA-Z0-9.]{2,63}$"), "value": {}, "default": {}, "min": {}, "max": {}, "platformCeiling": {},
      "securityRelated": {"type": "boolean", "description": "Tham số liên quan an toàn thông tin (FRS §8.2); giao diện nhắc người sửa và ghi kiểm toán mức cao."},
      "description": STR(500), "version": INT(minimum=0), "updatedAt": NTS, "updatedBy": NSTR(64)}, req=["key", "value", "default", "version"]),
  "SettingList": obj({"items": arr(R("Setting"))}, req=["items"]),
  "SettingPut": obj({"value": {}, "reason": R("ReasonAny")}, req=["value", "reason"], desc="Giá trị kiểm theo kiểu, miền và trần PA (ERR-01-044)."),
  "StatisticsView": obj({"from": DATE, "to": DATE, "byStatus": CNT,
      "stageDurations": obj({"median": INT(), "p90": INT()}, desc="Giờ làm việc theo từng bước."),
      "endToEnd": obj({"median": INT(), "p90": INT(), "kpi05Met": BOOL}),
      "returnRate": {"type": "number", "minimum": 0, "maximum": 1}, "backlog": INT(minimum=0),
      "weekly": arr(obj({"week": STR(10), "submitted": INT(), "approved": INT(), "returned": INT(), "rejected": INT()}, req=["week"]))},
      req=["from", "to", "byStatus"]),
}

EXAMPLES = {
  "SystemCreate": {"code": "HT-TUPHAP", "name": "Hệ thống quản lý hộ tịch", "description": "Cấp, quản lý giấy khai sinh, kết hôn, khai tử của sở Tư pháp.",
      "ownerOrgId": "SO-TUPHAP", "operatorName": "Công ty ABC", "systemType": "PROVINCIAL", "roles": ["CONSUMER", "PROVIDER"], "securityLevel": "L3",
      "securityApprovalRef": "QĐ 1234/QĐ-UBND ngày 12/03/2026", "baseUrls": ["https://hotich.tinh.example.gov.vn/api"], "ipAllowlist": ["10.20.0.0/24"],
      "legacyRef": "APIM-APP-0042"},
  "SystemUpdate": {"description": "Cấp, quản lý giấy khai sinh, kết hôn, khai tử, nhận cha mẹ con.", "baseUrls": ["https://hotich.tinh.example.gov.vn/api/v2"]},
  "SystemDetail": {"code": "HT-TUPHAP", "name": "Hệ thống quản lý hộ tịch", "ownerOrg": {"id": "SO-TUPHAP", "name": "Sở Tư pháp"}, "status": "DRAFT",
      "reviewStage": None, "provisionStage": None, "group": None, "roles": ["CONSUMER", "PROVIDER"], "securityLevel": "L3", "scopeCount": 0, "calls30d": None,
      "lastReviewAt": None, "flags": [], "updatedAt": "2026-11-26T08:30:00Z", "allowedActions": ["edit", "delete", "validate", "submit"],
      "disabledReasons": {}, "description": "Cấp, quản lý giấy khai sinh, kết hôn, khai tử của sở Tư pháp.", "operatorName": "Công ty ABC",
      "systemType": "PROVINCIAL", "securityApprovalRef": "QĐ 1234/QĐ-UBND ngày 12/03/2026", "baseUrls": ["https://hotich.tinh.example.gov.vn/api"],
      "ipAllowlist": ["10.20.0.0/24"], "applicationNo": "KN-2026-000123", "revisionNo": 0, "returnReason": None, "statusReason": None, "enforcement": "NONE",
      "technicalProfile": None, "dataDemands": [], "ceiling": [], "contacts": [], "credentials": [], "legacyRef": "APIM-APP-0042", "submittedAt": None,
      "approvedAt": None, "activatedAt": None, "terminatedAt": None, "createdAt": "2026-11-26T08:30:00Z", "createdBy": "an.nv"},
  "SystemPage": {"items": [{"code": "HT-TUPHAP", "name": "Hệ thống quản lý hộ tịch", "ownerOrg": {"id": "SO-TUPHAP", "name": "Sở Tư pháp"}, "status": "SUBMITTED",
      "reviewStage": "IN_REVIEW", "provisionStage": None, "group": 1, "roles": ["CONSUMER", "PROVIDER"], "securityLevel": "L3", "scopeCount": 0,
      "calls30d": None, "lastReviewAt": None, "flags": ["REVIEW_OVERDUE"], "updatedAt": "2026-11-26T09:10:00Z", "allowedActions": ["view"], "disabledReasons": {}}],
      "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}, "facets": {"status": {"SUBMITTED": 1}, "group": {"1": 1}}},
  "TechnicalProfile": {"systemKind": "WEB", "technology": "Java 8, Spring 4", "hasApi": True, "apiSpecKind": "OPENAPI", "protocols": ["REST"],
      "underMaintenance": False, "replacementPlanned": False, "criticality": "NORMAL", "maxConcurrentConnections": 20, "expectedDailyCalls": 5000,
      "operatingHours": "24/7, bảo trì CN 22:00"},
  "TechnicalProfileView": {"systemKind": "WEB", "technology": "Java 8, Spring 4", "hasApi": True, "apiSpecKind": "OPENAPI", "protocols": ["REST"],
      "underMaintenance": False, "replacementPlanned": False, "criticality": "NORMAL", "maxConcurrentConnections": 20, "expectedDailyCalls": 5000,
      "proposedGroup": 1, "confirmedGroup": None, "explanation": ["Có API OpenAPI và giao thức REST → nhóm 1 (điều hợp REST)"]},
  "DataDemandsPut": {"demands": [{"direction": "CONSUME", "dataType": "THONG_TIN_CONG_DAN", "scopeRequested": "Tra cứu phục vụ giải quyết TTHC",
      "classification": "RESTRICTED", "purpose": "Xác minh nhân thân khi cấp giấy khai sinh",
      "legalBasis": {"docNo": "Luật 91/2025/QH15", "issuedOn": "2025-06-26", "issuer": "Quốc hội", "validUntil": "2028-12-31",
                     "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d"}}]},
  "DataDemandList": {"demands": [{"demandId": "0194f2c3-1b20-7d11-8a55-2e3f4a5b6c7d", "direction": "CONSUME", "dataType": "THONG_TIN_CONG_DAN",
      "scopeRequested": "Tra cứu phục vụ giải quyết TTHC", "classification": "RESTRICTED", "purpose": "Xác minh nhân thân khi cấp giấy khai sinh",
      "legalBasis": {"docNo": "Luật 91/2025/QH15", "issuedOn": "2025-06-26", "issuer": "Quốc hội", "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d"},
      "verdict": None, "scopeApproved": None, "opinion": None, "missingLegalBasis": False}], "ceiling": []},
  "ContactInput": {"contactType": "TECHNICAL", "fullName": "Nguyễn Văn An", "position": "Chuyên viên CNTT", "email": "an.nv@tuphap.tinh.example.gov.vn",
      "phone": "+84912345678", "isPublic": True},
  "Contact": {"contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "contactType": "TECHNICAL", "fullName": "Nguyễn Văn An", "position": "Chuyên viên CNTT",
      "email": "an.nv@tuphap.tinh.example.gov.vn", "phone": "+84912345678", "isPublic": True, "hasAccount": True, "lastConfirmedAt": None, "status": "ACTIVE"},
  "Attachment": {"attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d", "kind": "LEGAL_BASIS", "title": "Luật BVDLCN 91/2025", "fileName": "luat-91-2025.pdf",
      "sizeBytes": 1048576, "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "scanStatus": "CLEAN",
      "uploadedBy": "an.nv", "uploadedAt": "2026-11-26T08:45:00Z"},
  "ValidateResult": {"valid": False, "errorCount": 1, "warningCount": 1, "issues": [
      {"path": "dataDemands[1].legalBasis", "code": "ERR-01-015", "severity": "ERROR", "message": "Mục 'Thông tin thửa đất' chưa có căn cứ pháp lý",
       "guidance": "Bổ sung số, ngày, cơ quan ban hành văn bản cho phép khai thác dữ liệu."},
      {"path": "contacts", "code": "ERR-01-050", "severity": "WARNING", "message": "Nên có thêm một đầu mối kỹ thuật dự phòng", "guidance": "Thêm đầu mối thứ hai."}]},
  "SubmitRequest": {"note": "Đề nghị kết nối để cấp giấy khai sinh điện tử."},
  "StateChangeResult": {"code": "HT-TUPHAP", "status": "SUBMITTED", "reviewStage": "IN_REVIEW", "provisionStage": None, "revisionNo": 1, "enforcement": "NONE",
      "steps": [{"stepType": "TECHNICAL", "dueAt": "2026-11-30T10:00:00Z"}, {"stepType": "LEGAL", "dueAt": "2026-11-30T10:00:00Z"},
                {"stepType": "SECURITY", "dueAt": "2026-11-30T10:00:00Z"}], "updatedAt": "2026-11-26T09:00:00Z"},
  "TechnicalReviewRequest": {"result": "PASS", "confirmedGroup": 1, "adapterTypes": [], "authMethod": "PRIVATE_KEY_JWT",
      "proposedQuota": {"limit": 5000, "period": "DAY"}, "effortDays": 10},
  "LegalReviewRequest": {"items": [{"demandId": "0194f2c3-1b20-7d11-8a55-2e3f4a5b6c7d", "verdict": "NARROWED",
      "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC", "opinion": "Đề nghị rộng hơn nhu cầu thực tế"}], "overallOpinion": "Bổ sung căn cứ nếu cần dữ liệu đất đai"},
  "SecurityReviewRequest": {"result": "PASS", "securityLevelConfirmed": "L3"},
  "ReviewStepResult": {"stepType": "LEGAL", "result": "PASS", "summary": {"approved": 0, "narrowed": 1, "rejected": 0},
      "ceilingPreview": [{"dataType": "THONG_TIN_CONG_DAN", "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC"}], "reviewStage": "WAITING_APPROVAL",
      "finishedAt": "2026-11-27T03:20:00Z"},
  "QuotaImpactResult": {"impact": [{"service": "CSDLQG-DANCU-TRACUU", "remaining": 120000, "projected": 5000, "level": "LOW", "suggestion": "Không cần xin thêm hạn mức"}],
      "partial": False},
  "AssignRequest": {"stepType": "TECHNICAL", "assigneeId": "ie.tranb"},
  "ReturnRequest": {"requests": [{"path": "technicalProfile.protocols", "requirement": "Khai rõ giao thức; hệ thống có cả SOAP lẫn REST."}], "note": "Bổ sung trong 5 ngày."},
  "ApproveRequest": {"comment": "Đủ điều kiện, đã thẩm định ba bước.", "authCode": "482910"},
  "RejectRequest": {"comment": "Dữ liệu đề nghị thuộc danh mục bí mật nhà nước."},
  "SagaStatus": {"sagaId": "0194f2c5-3d40-7f33-8c77-4a5b6c7d8e9f", "stage": "PROVISIONING", "startedAt": "2026-11-27T04:00:00Z", "nextRetryAt": "2026-11-27T04:02:00Z",
      "attempt": 1, "steps": [{"name": "RECORD", "status": "DONE", "at": "2026-11-27T04:00:01Z", "errorCode": None},
      {"name": "CREATE_CLIENT", "status": "FAILED", "at": "2026-11-27T04:00:12Z", "errorCode": "ERR-01-021"}]},
  "PublicKeyRequest": {"kind": "JWKS", "kid": "2026-12-a", "payload": "{\"keys\":[{\"kty\":\"EC\",\"crv\":\"P-256\",\"x\":\"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU\",\"y\":\"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0\",\"use\":\"sig\",\"kid\":\"2026-12-a\"}]}"},
  "CredentialKeyResult": {"credentialId": "cr-0194f2c6", "kid": "2026-12-a", "certFingerprint": None, "certificatePem": None, "expiresAt": "2027-11-26T00:00:00Z",
      "provisionStage": "SANDBOX_READY"},
  "HandoverCreate": {"recipientContactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "ttlHours": 24},
  "HandoverCreated": {"handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0", "status": "PENDING", "expiresAt": "2026-11-28T04:05:00Z",
      "recipient": {"contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "fullName": "Nguyễn Văn An", "emailMasked": "a***@tuphap.tinh.example.gov.vn"}},
  "HandoverOpenRequest": {"token": "VIDU000000000000000000000000000000000000000"},
  "HandoverOpenResult": {"maHeThong": "HT-TUPHAP", "thongTinKetNoi": {"clientId": "t68-ht-tuphap-sbx", "clientSecret": "DEMO-ONLY-NOT-A-SECRET",
      "tokenEndpoint": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "apiBaseUrl": "https://api-sandbox.t68.datahub.example.vn",
      "authMethod": "CLIENT_SECRET", "scopes": ["sandbox:invoke"], "quota": {"limit": 1000, "period": "DAY"}},
      "canhBao": "Thông tin này chỉ hiển thị MỘT LẦN. Lưu vào nơi an toàn ngay.", "huongDan": "https://docs.datahub.example.vn/ket-noi/sandbox"},
  "SandboxTestResult": {"authOk": True, "apiOk": False, "callCount": 2, "successCount": 1, "required": 3,
      "errors": [{"code": "invalid_scope", "count": 4, "guidance": "Dùng scope môi trường thử, ví dụ sandbox:invoke."}], "readyToActivate": False,
      "source": "PH03", "observedAt": "2026-11-27T05:00:00Z", "partial": False},
  "ActivateRequest": {"note": "Đã kiểm thử đạt, đề nghị bật PRODUCTION.", "authCode": "130557"},
  "RotateRequest": {"reason": "Định kỳ 180 ngày", "overlapDays": 7},
  "RotateResult": {"credentialId": "cr-0194f2c6", "status": "ROTATING", "rotationEndsAt": "2026-12-05T00:00:00Z",
      "handover": {"handoverId": "0194f2c8-5f60-7155-9e99-6c7d8e9fa0b1", "expiresAt": "2026-11-28T04:10:00Z"}},
  "RevokeRequest": {"reason": "Nghi lộ thông tin xác thực trên kho mã nguồn", "confirmImpact": True},
  "RevokeResult": {"credentialId": "cr-0194f2c6", "status": "REVOKED", "enforcement": "DONE", "revokedAt": "2026-11-29T02:00:00Z"},
  "SuspendRequest": {"reasonCode": "OVERLOAD", "reason": "Tăng đột biến lưu lượng làm quá tải cổng", "expectedUntil": "2026-12-01", "confirmImpact": True},
  "ResumeRequest": {"reason": "Đã xử lý nguyên nhân quá tải và giảm hạn mức", "confirmCredentialsRotated": False},
  "TerminateRequest": {"reason": "Hệ thống ngừng vận hành theo quyết định của sở", "legalBasis": "QĐ 88/QĐ-SO ngày 01/10/2026", "confirmImpact": True},
  "EmergencyRequest": {"mode": "SUSPEND", "reason": "Phát hiện bí mật client lộ trên kho mã công khai", "incidentRef": "INC-2026-0412"},
  "EmergencyResult": {"actionId": "0194f2c9-6070-7266-8faa-7d8e9fa0b1c2", "status": "PENDING_CONFIRM", "systemStatus": "SUSPENDED",
      "confirmBy": "2026-11-30T02:00:00Z", "enforcement": "PENDING"},
  "ImpactResult": {"impactLevel": "MEDIUM", "partial": False, "computedAt": "2026-11-26T10:00:00Z",
      "dependents": [{"type": "SUBSCRIPTION", "ref": "SUB-0099", "name": "Tra cứu hộ tịch cho dịch vụ công", "orgName": "Sở Thông tin và Truyền thông"}]},
  "ChangeRequestCreate": {"changes": {"securityLevel": "L4", "securityApprovalRef": "QĐ 2210/QĐ-UBND ngày 05/11/2026"}, "reason": "Nâng cấp độ ATTT theo quyết định mới"},
  "ChangeRequestOutcome": {"applied": False, "changeRequest": {"id": "0194f2ca-7180-7377-90bb-8e9fa0b1c2d3", "changeClass": "FULL", "status": "PENDING",
      "reason": "Nâng cấp độ ATTT theo quyết định mới", "diff": {"securityLevel": {"from": "L3", "to": "L4"}}, "requestedBy": "an.nv",
      "requestedAt": "2026-11-26T11:00:00Z"}, "system": None},
  "ChangeDecision": {"decision": "APPROVE", "comment": "Đã đối chiếu quyết định phê duyệt cấp độ."},
  "ScopeExpansionCreate": {"demands": [{"direction": "CONSUME", "dataType": "THONG_TIN_DAT_DAI", "scopeRequested": "Tra cứu thửa đất phục vụ hộ tịch",
      "classification": "RESTRICTED", "purpose": "Xác minh nơi cư trú", "legalBasis": {"docNo": "NĐ 101/2024/NĐ-CP", "issuedOn": "2024-07-29",
      "issuer": "Chính phủ", "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d"}}], "reason": "Bổ sung nhu cầu dữ liệu đất đai cho hộ tịch"},
  "ReconcileRequest": {"systemCodes": ["HT-TUPHAP"], "reason": "Đối chiếu sau sự cố Kafka"},
  "ReconcileAccepted": {"reconciliationId": "0194f2cb-8290-7488-91cc-9fa0b1c2d3e4", "batches": 1, "acceptedAt": "2026-11-26T12:00:00Z"},
  "ReplicaPage": {"items": [{"code": "HT-TUPHAP", "name": "Hệ thống quản lý hộ tịch", "ownerOrgId": "SO-TUPHAP", "status": "ACTIVE", "roles": ["CONSUMER", "PROVIDER"],
      "securityLevel": "L3", "group": 1, "baseUrls": ["https://hotich.tinh.example.gov.vn/api"],
      "clientIds": {"SANDBOX": "t68-ht-tuphap-sbx", "PRODUCTION": "t68-ht-tuphap-prd"}, "activatedAt": "2026-12-10T03:00:00Z",
      "updatedAt": "2026-12-10T03:00:00Z", "ceilingDataTypes": ["THONG_TIN_CONG_DAN"]}], "nextUpdatedSince": "2026-12-10T03:00:00Z",
      "page": {"number": 0, "size": 200, "totalElements": 1, "totalPages": 1}},
  "ProvisioningCallback": {"sagaId": "0194f2c5-3d40-7f33-8c77-4a5b6c7d8e9f", "step": "CREATE_CLIENT", "outcome": "DONE", "externalRef": "kc-client-7f3a"},
  "SuspensionProposal": {"systemCode": "HT-QLVB", "alertId": "0194f2d0-6a10-7c11-9e22-3b4c5d6e7f80", "severity": "HIGH",
      "reason": "Tra cứu bất thường 1.240 khóa trong 1 giờ, nghi lộ tài khoản dịch vụ", "incidentRef": "SEC-ALERT-2026-0142"},
  "SuspensionProposalAck": {"systemCode": "HT-QLVB", "alertId": "0194f2d0-6a10-7c11-9e22-3b4c5d6e7f80", "taskId": "0194f2d1-0b32-7d44-8a55-6c7d8e9fa0b1", "accepted": True, "duplicate": False},
  "CallbackAck": {"sagaId": "0194f2c5-3d40-7f33-8c77-4a5b6c7d8e9f", "step": "CREATE_CLIENT", "accepted": True, "duplicate": False},
  "AccessReviewCreate": {"name": "Rà soát quyền định kỳ 6 tháng cuối 2026", "scope": "ALL_ACTIVE", "periodFrom": "2026-06-01", "periodTo": "2026-11-30"},
  "AccessReviewCycle": {"cycleCode": "RS-2026-02", "name": "Rà soát quyền định kỳ 6 tháng cuối 2026", "kind": "PERIODIC", "status": "OPEN",
      "periodFrom": "2026-06-01", "periodTo": "2026-11-30", "itemCount": 118, "confirmationsSent": 0, "confirmationsResponded": 0,
      "openedBy": "ta.lethi", "openedAt": "2026-12-01T01:00:00Z", "closedAt": None},
  "AccessReviewItemPage": {"items": [{"itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5", "systemCode": "HT-TUPHAP", "ownerOrgId": "SO-TUPHAP",
      "dataType": "THONG_TIN_CONG_DAN", "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC", "usageInPeriod": 0, "unusedDays": 210, "legalExpired": False,
      "flags": ["UNUSED"], "proposal": "NARROW", "ownerResponse": None, "decision": None, "usagePartial": False}],
      "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}, "usagePartial": False},
  "SendConfirmationsAccepted": {"sent": 14, "skipped": 0, "orgsWithoutContact": []},
  "ConfirmationView": {"orgId": "SO-TUPHAP", "orgName": "Sở Tư pháp", "cycleCode": "RS-2026-02", "expiresAt": "2027-01-02T00:00:00Z",
      "items": [{"itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5", "systemCode": "HT-TUPHAP", "dataType": "THONG_TIN_CONG_DAN",
                 "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC", "usageInPeriod": 0, "unusedDays": 210}]},
  "ConfirmationRespond": {"answers": [{"itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5", "answer": "REDUCE", "scopeReduced": "Chỉ tra cứu theo mã định danh",
      "note": "Chỉ còn dùng cho cấp giấy khai sinh"}]},
  "ConfirmationRespondResult": {"answered": 1, "kept": 0, "reduced": 1, "released": 0},
  "ItemDecisionRequest": {"items": [{"itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5", "decision": "NARROW", "scopeNew": "Chỉ tra cứu theo mã định danh",
      "reason": "Đơn vị xác nhận thu hẹp, không dùng 210 ngày"}]},
  "ItemDecisionResult": {"decided": 1, "kept": 0, "narrowed": 1, "revoked": 0, "cycleStatus": "DECIDING"},
  "MarkLegalExpiredRequest": {"docNo": "NĐ 47/2020/NĐ-CP", "repealedOn": "2026-01-01", "note": "Bị thay thế bởi NĐ 278/2025"},
  "ExportRequest": {"format": "XLSX", "purpose": "Báo cáo kiểm tra đầu mối quý IV", "filters": {"orgId": "SO-TUPHAP"}},
  "JobAccepted": {"jobId": "0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506", "status": "QUEUED", "statusUrl": "/api/onboarding/v1/jobs/0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506"},
  "Job": {"jobId": "0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506", "kind": "EXPORT_CONTACTS", "status": "DONE", "createdAt": "2026-12-02T02:00:00Z",
      "finishedAt": "2026-12-02T02:00:09Z", "downloadUrl": "https://files.t68.datahub.example.vn/exports/0194f2cd.xlsx?sig=demo", "rowCount": 842, "errorCode": None},
  "DirectoryPage": {"items": [{"contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "fullName": "Nguyễn Văn An", "position": "Chuyên viên CNTT",
      "phone": "+84912345678", "email": "an.nv@tuphap.tinh.example.gov.vn", "orgId": "SO-TUPHAP", "orgName": "Sở Tư pháp", "systemCode": "HT-TUPHAP",
      "systemName": "Hệ thống quản lý hộ tịch", "contactType": "TECHNICAL", "lastConfirmedAt": "2026-10-01T00:00:00Z"}],
      "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}},
  "DirectoryGaps": {"orgsWithoutTechnicalContact": [{"orgId": "UBND-XA-A", "orgName": "UBND xã A", "systemCodes": ["HT-XA-A"]}], "staleContacts": [],
      "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}},
  "LegacyImportJob": {"jobId": "0194f2ce-b5c0-77bb-94ff-c2d3e4f50617", "source": "APIM_APPLICATION", "status": "PREVIEWED", "rowCount": 122, "created": 0,
      "skipped": 4, "warnings": 6, "secretsDropped": 120,
      "preview": [{"row": 2, "legacyRef": "APIM-APP-0042", "code": "HT-TUPHAP", "name": "Hệ thống quản lý hộ tịch", "matchedOrgId": "SO-TUPHAP", "action": "CREATE",
                   "warning": None}], "errorCode": None, "createdAt": "2026-12-03T02:00:00Z", "finishedAt": None},
  "LegacyImportConfirm": {"skipRows": [5, 9]},
  "SettingList": {"items": [{"key": "onboarding.review.slaWorkingDays", "value": 2, "default": 2, "min": 1, "max": 10, "platformCeiling": None, "securityRelated": False,
      "description": "Hạn mỗi bước thẩm định (ngày làm việc)", "version": 3, "updatedAt": "2026-10-01T00:00:00Z", "updatedBy": "ta.lethi"}]},
  "SettingPut": {"value": 3, "reason": "Quy chế tiếp nhận hồ sơ của tỉnh quy định 3 ngày"},
  "StatisticsView": {"from": "2026-09-01", "to": "2026-11-30", "byStatus": {"ACTIVE": 96, "SUBMITTED": 7, "DRAFT": 12}, "stageDurations": {"median": 9, "p90": 22},
      "endToEnd": {"median": 40, "p90": 71, "kpi05Met": True}, "returnRate": 0.18, "backlog": 7,
      "weekly": [{"week": "2026-W47", "submitted": 6, "approved": 4, "returned": 1, "rejected": 0}]},
  "RevokeRequest_": None,
}
EXAMPLES.pop("RevokeRequest_")
for _k, _v in EXAMPLES.items():
    SCHEMAS[_k].setdefault("examples", [_v]) if isinstance(SCHEMAS[_k], dict) else None
