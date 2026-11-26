#!/usr/bin/env python3
"""Sinh ph01/openapi-onboarding.yaml từ spec.OPS, schemas.SCHEMAS và errors.ERRORS.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph01)
YAML sinh ra là hợp đồng; sửa spec.py, schemas.py, errors.py hoặc tệp này rồi sinh lại, không sửa tay YAML.
"""
import copy, os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from errors import ERR
from schemas import *  # noqa: F401,F403  (R, s, obj, arr, enum, STR, INT, … SCHEMAS, EXAMPLES)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = lambda n: {"$ref": f"#/components/parameters/{n}"}
RESP = lambda n: {"$ref": f"#/components/responses/{n}"}

# ---- ví dụ bổ sung cho lược đồ con (dựng từ ví dụ đã có, bảo đảm khớp lược đồ)
_sd = EXAMPLES["SystemDetail"]
EXAMPLES.update({
    "ReviewStep": {"stepType": "TECHNICAL", "status": "OPEN", "assigneeId": "ie.tranb", "dueAt": "2026-11-30T10:00:00Z", "finishedAt": None, "pausedMillis": 0},
    "Credential": {"credentialId": "cr-0194f2c6", "environment": "SANDBOX", "authMethod": "PRIVATE_KEY_JWT", "clientId": "t68-ht-tuphap-sbx",
        "certFingerprint": None, "status": "ACTIVE", "disabled": False, "disabledReason": None, "expiresAt": "2027-11-26T00:00:00Z", "lastUsedAt": None,
        "rotationEndsAt": None, "secretAgeDays": 0, "keyRegistered": True, "createdAt": "2026-11-27T04:00:20Z",
        "allowedActions": ["rotate", "revoke"], "disabledReasons": {}},
    "CredentialList": {"credentials": [{"credentialId": "cr-0194f2c6", "environment": "SANDBOX", "authMethod": "PRIVATE_KEY_JWT", "clientId": "t68-ht-tuphap-sbx",
        "certFingerprint": None, "status": "ACTIVE", "disabled": False, "disabledReason": None, "expiresAt": "2027-11-26T00:00:00Z", "lastUsedAt": None,
        "rotationEndsAt": None, "secretAgeDays": 0, "keyRegistered": True, "createdAt": "2026-11-27T04:00:20Z", "allowedActions": ["rotate", "revoke"],
        "disabledReasons": {}}]},
    "Setting": {"key": "onboarding.review.slaWorkingDays", "value": 3, "default": 2, "min": 1, "max": 10, "platformCeiling": None,
        "description": "Hạn mỗi bước thẩm định (ngày làm việc)", "version": 4, "updatedAt": "2026-12-03T03:00:00Z", "updatedBy": "ta.lethi"},
    "ReplicaSystem": EXAMPLES["ReplicaPage"]["items"][0],
    "ChangeRequest": EXAMPLES["ChangeRequestOutcome"]["changeRequest"],
    "ChangeRequestList": {"items": [EXAMPLES["ChangeRequestOutcome"]["changeRequest"]]},
    "ContactList": {"items": [EXAMPLES["Contact"]]},
    "AttachmentList": {"items": [EXAMPLES["Attachment"]]},
    "TemplateList": {"items": [{"templateCode": "VAN-BAN-DE-NGHI-KET-NOI", "title": "Mẫu văn bản đề nghị kết nối", "version": "1.2", "updatedAt": "2026-10-01T00:00:00Z"}]},
    "ReviewQueuePage": {"items": [{"systemCode": "HT-TUPHAP", "systemName": "Hệ thống quản lý hộ tịch", "applicationNo": "KN-2026-000123", "stepType": "TECHNICAL",
        "dueAt": "2026-11-30T10:00:00Z", "overdue": False, "assignee": {"userId": "ie.tranb", "displayName": "Trần Văn B"}, "status": "OPEN"}],
        "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}},
    "ExpiringPage": {"items": [{"systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "environment": "PRODUCTION", "expiresAt": "2027-01-05T00:00:00Z",
        "daysLeft": 29, "ownerOrg": {"id": "SO-TUPHAP", "name": "Sở Tư pháp"}}], "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}},
    "ReviewReport": {"cycleCode": "RS-2026-02", "status": "CLOSED", "summary": {"items": 118, "kept": 90, "narrowed": 20, "revoked": 8, "noResponseOrgs": 2},
        "evidenceHash": "4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce", "closedAt": "2026-12-20T09:00:00Z"},
    "MarkLegalExpiredResult": {"affectedCeilings": 3, "suspendedSystems": 1},
    "SandboxTestList": {"items": [EXAMPLES["SandboxTestResult"]], "readyToActivate": False},
    "HistoryPage": {"items": [{"fromStatus": "DRAFT", "toStatus": "SUBMITTED", "reason": None, "actor": "an.nv", "emergency": False, "at": "2026-11-26T09:00:00Z",
        "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}], "page": {"number": 0, "size": 20, "totalElements": 1, "totalPages": 1}},
    "ProgressView": {"timeline": [{"event": "SUBMITTED", "at": "2026-11-26T09:00:00Z", "actor": "an.nv", "note": None}],
        "waitingOn": {"role": "ROLE-INTEGRATION_ENGINEER", "dueAt": "2026-11-30T10:00:00Z", "overdue": False},
        "returnRequests": []},
    "Template": {"templateCode": "VAN-BAN-DE-NGHI-KET-NOI", "title": "Mẫu văn bản đề nghị kết nối", "version": "1.2", "updatedAt": "2026-10-01T00:00:00Z"},
})
for _k in ("ReviewStep", "Credential", "CredentialList", "Setting", "ReplicaSystem", "ChangeRequest", "ChangeRequestList", "ContactList", "AttachmentList",
           "TemplateList", "ReviewQueuePage", "ExpiringPage", "ReviewReport", "MarkLegalExpiredResult", "SandboxTestList", "HistoryPage", "ProgressView", "Template"):
    SCHEMAS[_k].setdefault("examples", [EXAMPLES[_k]])

PARAMS = {
  "SystemCodePath": {"name": "systemCode", "in": "path", "required": True, "schema": R("SystemCode")},
  "AttachmentIdPath": {"name": "attachmentId", "in": "path", "required": True, "schema": UUID},
  "ContactIdPath": {"name": "contactId", "in": "path", "required": True, "schema": UUID},
  "CredentialIdPath": {"name": "credentialId", "in": "path", "required": True, "schema": STR(64, pattern="^cr-[0-9a-f-]{4,60}$")},
  "HandoverIdPath": {"name": "handoverId", "in": "path", "required": True, "schema": UUID},
  "ActionIdPath": {"name": "actionId", "in": "path", "required": True, "schema": UUID},
  "ChangeRequestIdPath": {"name": "changeRequestId", "in": "path", "required": True, "schema": UUID},
  "CycleCodePath": {"name": "cycleCode", "in": "path", "required": True, "schema": STR(32, pattern="^RS-[0-9]{4}-[0-9]{2}$")},
  "TokenPath": {"name": "token", "in": "path", "required": True, "schema": STR(128, minLength=43),
                "description": "Mã trong liên kết gửi qua thư (256 bit, base64url). Cổng API che đoạn này trong log truy cập (Q01-55)."},
  "OrgIdPath": {"name": "orgId", "in": "path", "required": True, "schema": R("OrgId")},
  "JobIdPath": {"name": "jobId", "in": "path", "required": True, "schema": UUID},
  "TemplateCodePath": {"name": "templateCode", "in": "path", "required": True, "schema": STR(64, pattern="^[A-Z][A-Z0-9-]{2,63}$")},
  "KeyPath": {"name": "key", "in": "path", "required": True, "schema": STR(64, pattern="^onboarding\\.[a-zA-Z][a-zA-Z0-9.]{2,55}$"),
              "description": "Khóa đầy đủ có tiền tố `onboarding.` (FRS §8.2)."},
  "ReviewKindPath": {"name": "reviewKind", "in": "path", "required": True, "schema": enum("legal", "security")},
  "Page": {"name": "page", "in": "query", "schema": INT(minimum=0, default=0), "description": "Số trang, bắt đầu từ 0."},
  "Size": {"name": "size", "in": "query", "schema": INT(minimum=1, maximum=100, default=20), "description": "Số dòng mỗi trang (FR-00-021); 10, 20, 50 hoặc 100 trên giao diện."},
  "ReplicaSize": {"name": "size", "in": "query", "schema": INT(minimum=1, maximum=500, default=200), "description": "Số dòng mỗi trang, ≤ 500 (`dh.onboarding.replica.max-page`); vượt trả ERR-01-003."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại (giá trị `version`); lệch trả ERR-01-007 (412)."},
  "IfMatchOptional": {"name": "If-Match", "in": "header", "schema": STR(128),
                      "description": "Tùy chọn: có thì kiểm, lệch trả ERR-01-007. Không bắt buộc để thao tác khẩn không bị chặn bởi bản ghi cũ."},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16),
                     "description": "Giữ 24 giờ; cùng khóa khác thân trả ERR-01-051; cùng khóa đang xử lý trả ERR-01-054."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
}
PATH_PARAM = {"systemCode": "SystemCodePath", "attachmentId": "AttachmentIdPath", "contactId": "ContactIdPath", "credentialId": "CredentialIdPath",
    "handoverId": "HandoverIdPath", "actionId": "ActionIdPath", "changeRequestId": "ChangeRequestIdPath", "cycleCode": "CycleCodePath",
    "token": "TokenPath", "orgId": "OrgIdPath", "jobId": "JobIdPath", "templateCode": "TemplateCodePath", "key": "KeyPath", "reviewKind": "ReviewKindPath"}

# ---- phản hồi lỗi dùng chung theo mã HTTP (mã cụ thể nằm ở `code`)
HTTP_RESP = {
  "400": ("BadRequest", "Dữ liệu không hợp lệ hoặc thiếu lý do, tệp sai cấu trúc (ERR-01-003, 033, 042); kèm `errors` theo trường.", "ERR-01-003"),
  "401": ("Unauthorized", "Thiếu hoặc hết hạn thông tin xác thực (ERR-01-052).", "ERR-01-052"),
  "403": ("Forbidden", "Không đủ quyền hoặc scope, người nộp ngoài tổ chức, bốn mắt, không phải người nhận, cần xác thực lại (ERR-01-052, 006, 017, 025, 035).", "ERR-01-052"),
  "404": ("NotFound", "Không tìm thấy hoặc thuộc tenant khác, ngoài phạm vi vai trò (không phân biệt; ERR-01-001).", "ERR-01-001"),
  "409": ("Conflict", "Trạng thái không cho phép, trùng, đang xử lý; mã cụ thể trong `code` (ERR-01-002, 005, 009, 020, 022, 029, 030, 034, 036, 038, 039, 043, 048, 050, 051, 053, 054).", "ERR-01-005"),
  "410": ("Gone", "Liên kết hoặc phiếu đã dùng, hết hạn, bị hủy; thân giống nhau cho mọi nguyên nhân (ERR-01-024, 040).", "ERR-01-024"),
  "412": ("PreconditionFailed", "ETag không khớp; kèm `currentEtag` (ERR-01-007).", "ERR-01-007"),
  "413": ("PayloadTooLarge", "Tệp vượt cỡ cho phép (ERR-01-012).", "ERR-01-012"),
  "415": ("UnsupportedMediaType", "Định dạng tệp không được phép (ERR-01-013).", "ERR-01-013"),
  "422": ("Unprocessable", "Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-01-004, 008, 010, 011, 014…016, 018, 019, 027, 028, 031, 032, 037, 041, 044, 047, 049).", "ERR-01-008"),
  "429": ("TooManyRequests", "Vượt giới hạn tốc độ hoặc liên kết bị khóa; kèm `Retry-After` (ERR-01-026, 045).", "ERR-01-045"),
  "503": ("ServiceUnavailable", "Phụ thuộc chưa sẵn sàng (ERR-01-021, 023, 046); không đổi trạng thái đã đặt, không tiêu hao liên kết bàn giao.", "ERR-01-046"),
}
RESPONSES = {}
for _st, (_name, _d, _c) in HTTP_RESP.items():
    _hdr = {"Retry-After": {"schema": INT(), "description": "Giây phải chờ."}} if _st in ("429", "503") else None
    RESPONSES[_name] = {"description": _d, "content": {"application/problem+json": {"schema": R("ProblemDetails"),
        "example": {"type": f"https://datahub.gov.vn/errors/{_c}", "title": ERR[_c[-3:]][2], "status": int(_st), "code": _c,
                    "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}
    if _hdr:
        RESPONSES[_name]["headers"] = _hdr

Q = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": schema, "description": desc}.items() if v is not None}
QA = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": arr(schema), "style": "form", "explode": False, "description": desc}.items() if v is not None}
PG = ["Page", "Size"]

# mã → (operationId, thân, phản hồi, mã lỗi riêng của thao tác, ghi chú, tham số query thêm)
X = {
  "001": ("listSystems", None, "SystemPage", ["003"], "OR chỉ thấy HTTT của tổ chức mình; DO chỉ thấy HTTT có dữ liệu của tổ chức mình (OPA). Kèm `facets`. `calls30d` rỗng khi PH-13 không khả dụng.",
          [Q("q", STR(100, minLength=1), "Tìm không dấu trên mã, tên, tổ chức."), QA("status", R("SystemStatus")), Q("ownerOrgId", R("OrgId")),
           Q("group", INT(minimum=1, maximum=4)), QA("role", R("SystemRole")), QA("securityLevel", R("SecurityLevel")), QA("flag", R("SystemFlag")),
           Q("sort", STR(pattern="^(code|name|updatedAt|status|securityLevel):(asc|desc)$", default="updatedAt:desc")), *PG]),
  "002": ("getSystem", None, "SystemDetail", ["046"], "Trả toàn bộ thuộc tính DD-03, hồ sơ kỹ thuật, nhu cầu, trần, đầu mối, định danh (không bí mật) và `allowedActions`. Có `ETag`. Đầu mối `SECURITY` chỉ TA, SO thấy.", []),
  "003": ("listSystemHistory", None, "HistoryPage", [], "Lịch sử chuyển trạng thái, lý do, người thực hiện, `traceId`; giữ vĩnh viễn.", PG),
  "004": ("createSystem", "SystemCreate", "SystemDetail", ["002", "004", "006", "049"],
          "Tạo hồ sơ `DRAFT`, sinh `applicationNo`, `revisionNo = 0`. Mã trùng (kể cả HTTT đã chấm dứt, bị từ chối) trả ERR-01-002; tổ chức không có hoặc không hoạt động ở PH-20 trả ERR-01-004; OR chỉ lập cho tổ chức của mình (ERR-01-006). Phát EVT-01-03 (`∅ → DRAFT`).", []),
  "005": ("updateSystem", "SystemUpdate", "SystemDetail", ["003", "005", "049"],
          "JSON Merge Patch, chỉ khi `DRAFT`; không đổi `code`. Tự lưu từng nhóm trường; trả `ETag` mới. HTTT đã kết nạp sửa qua API-01-057, không qua đây (ERR-01-005).", []),
  "018": ("deleteDraftSystem", None, None, ["005"], "Xóa mềm hồ sơ `DRAFT` chưa từng nộp (`revisionNo = 0`); giữ 30 ngày để khôi phục, sau đó xóa cứng và giải phóng mã. Hồ sơ đã từng nộp không xóa được (ERR-01-005): dùng rút hồ sơ.", []),
  "019": ("withdrawSystem", "WithdrawRequest", "StateChangeResult", ["005", "033"], "Đơn vị rút hồ sơ `SUBMITTED` về `DRAFT`; hủy các bước thẩm định đang mở (`WITHDRAWN`). Phát EVT-01-03.", []),
  "034": ("getSystemProgress", None, "ProgressView", [], "Dòng thời gian, bên đang chờ và hạn, các yêu cầu bổ sung đang mở.", []),
  "006": ("listAttachments", None, "AttachmentList", [], "Mọi tài liệu của hồ sơ, kèm trạng thái quét mã độc (`scanStatus`).", []),
  "007": ("uploadAttachment", "AttachmentUpload", "Attachment", ["005", "012", "013", "014", "046"],
          "Kiểm kiểu theo nội dung (Tika), cỡ ≤ `onboarding.attachment.maxSizeMb`, quét mã độc đồng bộ ≤ 20 giây (quá hạn: `scanStatus = PENDING`, không nộp được tới khi sạch). Mã hóa SSE-C, bucket theo tenant.", []),
  "008": ("downloadAttachment", None, None, ["046"], "Tệp nhị phân (`Content-Disposition: attachment`), hoặc `302` tới liên kết ký 5 phút của kho tệp. Ghi kiểm toán lượt tải.", []),
  "009": ("deleteAttachment", None, None, ["005"], "Chỉ khi `DRAFT`; tệp đang được dùng làm căn cứ pháp lý của nhu cầu thì gỡ liên kết trước (ERR-01-015 ở lần kiểm tra kế tiếp).", []),
  "020": ("listTemplates", None, "TemplateList", [], "Mẫu của tenant và mẫu mặc định ở `COMMON`; mọi người dùng đã đăng nhập thuộc tenant.", []),
  "021": ("downloadTemplate", None, None, [], "Tệp mẫu (DOCX, PDF).", []),
  "010": ("putTechnicalProfile", "TechnicalProfile", "TechnicalProfileView", ["003", "005"],
          "Ghi đè hồ sơ năng lực; hệ thống tính `proposedGroup` theo bảng quy tắc ưu tiên (FRS §6.2) và trả `explanation`. Chỉ khi `DRAFT`.", []),
  "011": ("getTechnicalProfile", None, "TechnicalProfileView", [], "Có `ETag`; `confirmedGroup` chỉ có sau thẩm định kỹ thuật.", []),
  "012": ("putDataDemands", "DataDemandsPut", "DataDemandList", ["003", "005", "015", "016"],
          "Thay cả danh sách. Mục `CONSUME` thiếu căn cứ pháp lý đầy đủ trả ERR-01-015 (kèm `errors[].path`); dữ liệu thuộc danh mục bí mật nhà nước trả ERR-01-016. Giữ `demandId` của dòng không đổi.", []),
  "013": ("getDataDemands", None, "DataDemandList", [], "Kèm `ceiling` (trần phạm vi) sau khi duyệt.", []),
  "014": ("listContacts", None, "ContactList", [], "Đầu mối `SECURITY` chỉ TA, SO thấy.", []),
  "015": ("createContact", "ContactInput", "ContactList", ["003", "011", "050"],
          "Thêm đầu mối; có `replaceContactId` thì thay thế đầu mối cũ (cũ chuyển `INACTIVE`, không xóa). Thư điện tử phải thuộc `onboarding.contact.allowedEmailDomains`. Phát EVT-01-13.", []),
  "016": ("updateContact", "ContactUpdate", "ContactList", ["003", "011", "050"], "Merge Patch. Đổi thư điện tử kiểm lại miền công vụ. Phát EVT-01-13.", []),
  "017": ("deleteContact", None, None, ["050"], "Vô hiệu đầu mối (`INACTIVE`). Không bỏ được đầu mối kỹ thuật cuối cùng (ERR-01-050). Phát EVT-01-13.", []),
  "022": ("validateSystem", None, "ValidateResult", ["005"],
          "Chạy toàn bộ danh sách kiểm tra trước khi nộp (FRS §6.3); luôn trả `200`, thiếu sót nằm ở `issues[]` với `code` là ERR-01-004, 008, 009, 010, 011, 015, 016, 047, 049, 050. Không đổi dữ liệu.", []),
  "023": ("submitSystem", "SubmitRequest", "StateChangeResult", ["005", "008", "009", "010", "046"],
          "`DRAFT → SUBMITTED`, `revisionNo + 1`, tạo ba bước `TECHNICAL`, `LEGAL`, `SECURITY` với hạn `onboarding.review.slaWorkingDays`. Chưa đủ điều kiện trả ERR-01-008 kèm `issues` đầy đủ. Cùng giao dịch ghi kiểm toán, outbox EVT-01-01, EVT-01-03 và việc cho hộp việc.", []),
  "024": ("reviewTechnical", "TechnicalReviewRequest", "ReviewStepResult", ["017", "019", "020", "047"],
          "Chỉ người được TA phân công bước `TECHNICAL` (IE, SO). `authMethod` không được yếu hơn `minAuthMethod` suy từ mức phân loại cao nhất trong nhu cầu (ERR-01-047). Phát EVT-01-02.", []),
  "025": ("reviewLegalOrSecurity", "LegalSecurityReviewRequest", "ReviewStepResult", ["016", "017", "018", "019", "020"],
          "`legal`: kết luận từng mục (phải đánh giá hết, ERR-01-018; thiếu ý kiến hoặc phạm vi duyệt trả ERR-01-019). `security`: xác nhận cấp độ ATTT. Người đã lập, nộp hay đề nghị bị loại (ERR-01-017). Phát EVT-01-02.", []),
  "026": ("assessQuotaImpact", "QuotaImpactRequest", "QuotaImpactResult", ["046"],
          "Hỏi PH-14 hạn mức quốc gia còn lại; PH-14 không khả dụng thì trả `partial = true` thay vì lỗi. Không đổi dữ liệu.", []),
  "027": ("listReviewQueue", None, "ReviewQueuePage", ["003"], "Người thẩm định thấy việc của mình; TA thấy toàn bộ. Việc quá hạn xếp đầu.",
          [Q("stepType", R("StepType")), Q("overdue", BOOL), Q("mine", BOOL), *PG]),
  "028": ("assignReviewer", "AssignRequest", "ReviewStep", ["003", "017", "020"], "TA phân công; người được phân công không được là người lập hoặc nộp (ERR-01-017). Phát EVT-01-02.", []),
  "029": ("consultReview", "ConsultRequest", "ReviewStep", ["003", "020"], "Đưa bước sang `CONSULTING`, đồng hồ hạn dừng (`pausedMillis` cộng dồn).", []),
  "030": ("resumeReview", "ResumeConsultRequest", "ReviewStep", ["020"], "Người được phân công hoặc TA kết thúc tham vấn; đồng hồ chạy lại.", []),
  "031": ("returnSystem", "ReturnRequest", "SystemDetail", ["017", "020", "033"], "`SUBMITTED → DRAFT` kèm `returnReason` và danh sách yêu cầu theo từng trường; các bước đã `PASS` sao chép sang vòng sau (`CARRIED`). Phát EVT-01-02, EVT-01-03.", []),
  "032": ("approveSystem", "ApproveRequest", "StateChangeResult", ["005", "017", "020", "035"],
          "`SUBMITTED → APPROVED`, `provisionStage = PROVISIONING`; sinh trần phạm vi từ mục được duyệt, đặt dòng saga `PENDING` trong cùng giao dịch. Người đã lập, nộp, thẩm định bị loại (ERR-01-017). Phát EVT-01-02, EVT-01-03, EVT-01-11.", []),
  "033": ("rejectSystem", "RejectRequest", "StateChangeResult", ["005", "017", "020", "033", "035"], "`SUBMITTED → REJECTED` (cuối); mã HTTT không dùng lại. Bắt buộc `comment`.", []),
  "035": ("retryProvisioning", "ProvisionRequest", "SagaStatus", ["005", "021", "022", "023"],
          "TA thử lại cấp định danh khi `provisionStage = PROVISION_FAILED`; tạo saga mới, bước đã `DONE` được bỏ qua. Trả `202` kèm `Location` tới API-01-036.", []),
  "036": ("getProvisioning", None, "SagaStatus", [], "Tiến độ từng bước (`RECORD`, `CREATE_CLIENT`, `STORE_SECRET`, `CREATE_CONSUMER`, `ACTIVATE`, `HANDOVER`, `NOTIFY`); không có `secret_ref` hay giá trị bí mật.", []),
  "037": ("putPublicKey", "PublicKeyRequest", "CredentialKeyResult", ["021", "023", "027", "028", "030"],
          "`JWKS`: chỉ khóa công khai, ES256 (P-256) hoặc PS256 (RSA ≥ 3072 bit), `kid` duy nhất trong client. `CSR`: nộp yêu cầu chứng thư (ký bằng API-01-038). `CERT`: nộp chứng thư do CA hợp lệ cấp. Với `AWAITING_KEY` chuyển `SANDBOX_READY`. Phát EVT-01-05, EVT-01-06.", []),
  "038": ("signCsr", "SignCsrRequest", "CredentialKeyResult", ["021", "023", "028", "030"], "Ký CSR đã nộp bằng `pki-clients` của OpenBao; hạn chứng thư không quá `credential.maxLifetimeDays`. Trả chứng thư PEM công khai.", []),
  "039": ("createHandover", "HandoverCreate", "HandoverCreated", ["003", "023", "030", "048"],
          "Tạo bản bọc phản hồi ở OpenBao, lưu băm SHA-256 của liên kết và `wrapAccessor`; thư chỉ chứa liên kết dạng `/ket-noi/ban-giao/{token}`. Người nhận phải là đầu mối `TECHNICAL` đang hoạt động có tài khoản (ERR-01-003). **Không có liên kết gốc trong phản hồi.**", []),
  "040": ("openHandover", "HandoverOpenRequest", "HandoverOpenResult", ["023", "024", "025", "026", "035", "048"],
          "API duy nhất của PH-01 trả giá trị bí mật. Người gọi phải là tài khoản của đúng đầu mối nhận, vừa xác thực hai yếu tố (`acr`); mở một lần (chiếm chỗ bằng `UPDATE` có điều kiện), thân phản hồi `Cache-Control: no-store`, không vào log, vết, đệm. Sai người: ERR-01-025 và EVT-01-10. Sai quá `handover.maxFailedOpens` lần: ERR-01-026. OpenBao lỗi: ERR-01-023, liên kết chưa tiêu hao. **Không áp dụng `Idempotency-Key`** vì mã chỉ dùng được một lần, không thử lại.", []),
  "041": ("reissueHandover", None, "HandoverCreated", ["003", "023", "030", "048"], "Hủy bàn giao cũ (`CANCELLED`) và tạo bản bọc mới từ bí mật còn lưu; chỉ khi bí mật chưa từng được mở. Đã mở thì dùng xoay vòng (API-01-045).", []),
  "042": ("refreshSandboxTests", None, "SandboxTestResult", ["046"], "Hỏi PH-03, PH-13 nhật ký truy cập theo định danh SANDBOX và tổng hợp lượt gọi thành công. PH-13 không khả dụng: `partial = true`.", []),
  "043": ("listSandboxTests", None, "SandboxTestList", [], "Kết quả các lần kiểm thử đã ghi (giữ 1 năm); `readyToActivate` khi đủ `sandbox.requiredSuccessfulCalls`.", []),
  "045": ("rotateCredential", "RotateRequest", "RotateResult", ["021", "023", "029", "030", "033", "035"],
          "`ACTIVE → ROTATING`, hai bí mật cùng hiệu lực tới `rotationEndsAt`. `CLIENT_SECRET` tạo bàn giao mới. Do sự cố: `overlapDays = 0` vô hiệu bí mật cũ ngay, bắt buộc `reason`. SO được gọi với `PERM-01-suspend`. Phát EVT-01-06.", []),
  "046": ("finishRotation", "FinishRotationRequest", "RotateResult", ["030"], "Kết thúc sớm thời gian chuyển tiếp: vô hiệu bí mật cũ, `ROTATING → ACTIVE`. Phát EVT-01-06.", []),
  "047": ("revokeCredential", "RevokeRequest", "RevokeResult", ["030", "033", "034", "035"],
          "`ACTIVE | ROTATING → REVOKED` (cuối). Chặn ở cổng trước, đặt trạng thái trước, thử lại cắt quyền tới khi xong (`enforcement` `PENDING` rồi `DONE`, mục tiêu ≤ 60 giây). Cần `confirmImpact = true` khi còn phụ thuộc. Phát EVT-01-07.", []),
  "048": ("listExpiringCredentials", None, "ExpiringPage", ["003"], "Định danh còn tới `withinDays` ngày; mặc định mốc nhắc đầu (30 ngày).", [Q("withinDays", INT(minimum=1, maximum=90, default=30)), *PG]),
  "049": ("listCredentials", None, "CredentialList", [], "Không bí mật, không `secret_ref`; kèm `allowedActions`.", [Q("environment", R("CredentialEnv"))]),
  "050": ("getCredential", None, "Credential", [], "Có `ETag`.", []),
  "061": ("enableCredential", "EnableCredentialRequest", "Credential", ["030"], "Bật lại định danh bị tự vô hiệu vì không hoạt động (`disabledReason = INACTIVE`); không bật được định danh `REVOKED`, `EXPIRED`.", []),
  "044": ("activateSystem", "ActivateRequest", "StateChangeResult", ["005", "017", "021", "031", "032", "035"],
          "`APPROVED → ACTIVE`: kiểm đủ kiểm thử SANDBOX (ERR-01-031), yêu cầu xác thực lại hai yếu tố; người kích hoạt không là người nộp (ERR-01-017). Cấp định danh PRODUCTION qua saga: xong trong 10 giây trả `200`, chưa xong trả `202` kèm `progressUrl` (API-01-036). Phát EVT-01-03, EVT-01-05.", []),
  "051": ("suspendSystem", "SuspendRequest", "StateChangeResult", ["005", "033", "034", "035"],
          "`ACTIVE → SUSPENDED`. Cần `confirmImpact = true` khi còn phụ thuộc (ERR-01-034 kèm `dependents`). Chặn ở cổng trước rồi vô hiệu client; mục tiêu ≤ 60 giây (`enforcement`). `If-Match` tùy chọn để SO không bị chặn bởi bản ghi cũ. Phát EVT-01-03, EVT-01-07.", []),
  "052": ("resumeSystem", "ResumeRequest", "StateChangeResult", ["005", "032", "033", "035", "036"],
          "`SUSPENDED → ACTIVE`. Tạm ngừng do `SECURITY_SUSPECT` phải có đồng ý của SO và `confirmCredentialsRotated` (ERR-01-036). Phát EVT-01-03.", []),
  "053": ("requestTermination", "TerminateRequest", "ChangeRequest", ["005", "033", "034"], "Tạo đề nghị `TERMINATE` chờ TA khác duyệt qua API-01-059 (bốn mắt, ERR-01-017). Chưa đổi trạng thái HTTT.", []),
  "054": ("emergencyAction", "EmergencyRequest", "EmergencyResult", ["005", "033", "035", "036"],
          "SO tạm ngừng hoặc chấm dứt ngay, TA phải xác nhận trong `emergency.confirmHours` (API-01-055). Chặn cổng trước. `If-Match` tùy chọn. Phát EVT-01-15, EVT-01-03, EVT-01-07.", []),
  "055": ("confirmEmergencyAction", "ConfirmEmergencyRequest", "EmergencyResult", ["017", "035", "036"], "TA xác nhận thao tác khẩn của SO (không phải người đã thực hiện). Phát EVT-01-15.", []),
  "056": ("getImpact", None, "ImpactResult", ["046"], "Tổng hợp phụ thuộc từ PH-02, PH-04, PH-05, PH-10, PH-14 (hạn 3 giây mỗi nơi); nơi nào lỗi thì `partial = true`. Không trả liên hệ cá nhân.", []),
  "057": ("createChangeRequest", "ChangeRequestCreate", "ChangeRequestOutcome", ["003", "037", "038", "049"],
          "Phân loại thay đổi theo bảng mức duyệt (FRS §6.5): mức `NONE` áp dụng ngay (`200`, phát EVT-01-04); `TECHNICAL`, `OWNER_CHANGE`, `FULL` tạo đề nghị chờ duyệt (`202`). Thay đổi làm rộng trần phải đi qua API-01-060 (ERR-01-037).", []),
  "058": ("listChangeRequests", None, "ChangeRequestList", [], "Các đề nghị thay đổi của HTTT theo trạng thái, gồm đề nghị chấm dứt (`TERMINATE`) và mở rộng phạm vi (`FULL`).", [QA("status", R("ChangeStatus"))]),
  "059": ("decideChangeRequest", "ChangeDecision", "ChangeRequestOutcome", ["005", "017", "033", "035"], "TA khác người đề nghị duyệt hoặc từ chối (SO thêm khi thay đổi cấp độ ATTT). Duyệt `TERMINATE` thực hiện chấm dứt: thu hồi định danh, trần về rỗng. Phát EVT-01-03, 04, 07, 11 tùy loại.", []),
  "060": ("createScopeExpansion", "ScopeExpansionCreate", "ChangeRequest", ["015", "016", "038", "047"], "Tạo đề nghị `FULL`: đi lại bước thẩm định pháp lý rồi TA duyệt. Duyệt xong trần mở rộng, phát EVT-01-11.", []),
  "062": ("startReconciliation", "ReconcileRequest", "ReconcileAccepted", [], "Phát ảnh chụp trạng thái theo lô (`snapshot = true`, EVT-01-03) cho phân hệ tiêu thụ đối chiếu. Hằng giờ có tác vụ tự chạy; API này để chạy theo yêu cầu sau sự cố.", []),
  "063": ("listReplicaSystems", None, "ReplicaPage", ["003"], "Đồng bộ gia tăng bằng `updatedSince`; dùng khi khởi tạo bản sao và đối chiếu, còn lại nghe EVT-01-03. Không có liên hệ cá nhân, bí mật.",
          [Q("updatedSince", TS), QA("status", R("SystemStatus")), Q("systemCode", R("SystemCode")), "Page", "ReplicaSize"]),
  "064": ("getReplicaSystem", None, "ReplicaSystem", [], "Tra một HTTT (cùng trường rút gọn với API-01-063).", []),
  "087": ("receiveProvisioningCallback", "ProvisioningCallback", "CallbackAck", ["053"],
          "PH-12, PH-03 trả kết quả bước saga ở trạng thái `ACCEPTED` khi `onboarding.saga.async-callback = true` (SDD §4.6). Kiểm token dịch vụ, `sagaId` và tenant của token; lũy đẳng theo `(sagaId, step)` (lặp trả `duplicate = true`). Quá 5 phút không có callback thì bước coi như thất bại.", []),
  "065": ("openAccessReview", "AccessReviewCreate", "AccessReviewCycle", ["003", "039", "044"], "Chụp danh sách mục (cặp HTTT, phạm vi) của HTTT `ACTIVE`; kỳ định kỳ cập nhật mốc rà soát toàn tenant. Chỉ một kỳ mở một lúc (ERR-01-039).", []),
  "066": ("listAccessReviews", None, "AccessReviewPage", [], "Các kỳ rà soát của tenant, kỳ mới nhất trước.", [QA("status", R("CycleStatus")), Q("kind", enum("PERIODIC", "TOPIC")), *PG]),
  "067": ("getAccessReview", None, "AccessReviewCycle", [], "Chi tiết kỳ rà soát, số phiếu đã gửi và đã trả lời.", []),
  "068": ("listAccessReviewItems", None, "AccessReviewItemPage", ["046"], "Mức sử dụng mỗi phạm vi lấy từ PH-13 (đồng thời ≤ `dh.onboarding.usage.concurrency`); PH-13 lỗi thì `usagePartial = true`.",
          [QA("flag", STR(32)), Q("ownerOrgId", R("OrgId")), Q("systemCode", R("SystemCode")), Q("decided", BOOL), *PG]),
  "069": ("sendAccessReviewConfirmations", "SendConfirmationsRequest", "SendConfirmationsAccepted", ["020"], "Gửi phiếu xác nhận (liên kết 256 bit, hạn `accessReview.confirmLinkTtlDays`) tới đầu mối của từng tổ chức; kỳ `OPEN → WAITING`. Tổ chức không có đầu mối được liệt kê ở `orgsWithoutContact`.", []),
  "070": ("getAccessReviewConfirmation", None, "ConfirmationView", ["025", "040"], "Đầu mối của đúng tổ chức, đã đăng nhập, mở phiếu. Phiếu đã trả lời hoặc hết hạn trả ERR-01-040 (thân giống nhau cho mọi nguyên nhân). `Cache-Control: no-store`.", []),
  "071": ("respondAccessReviewConfirmation", "ConfirmationRespond", "ConfirmationRespondResult", ["003", "025", "040"], "Mỗi mục trả lời `KEEP`, `REDUCE` (kèm `scopeReduced`) hoặc `RELEASE`; trả lời một lần.", []),
  "072": ("decideAccessReviewItems", "ItemDecisionRequest", "ItemDecisionResult", ["020", "033", "035", "041"], "Quyết định `KEEP`, `NARROW`, `REVOKE_SCOPE`; mục có văn bản hết hiệu lực không được `KEEP` (ERR-01-041). Đủ quyết định thì kỳ `CLOSED`, ghi băm bằng chứng, phát EVT-01-11, EVT-01-12.", []),
  "073": ("markLegalExpired", "MarkLegalExpiredRequest", "MarkLegalExpiredResult", ["003"], "Đánh dấu thủ công văn bản bị bãi bỏ: các trần dẫn văn bản đó chuyển `SUSPENDED`, HTTT bị ảnh hưởng nhận thông báo. Phát EVT-01-11.", []),
  "074": ("getAccessReviewReport", None, "ReviewReport", ["020"], "`Accept: application/pdf` hoặc XLSX để tải tệp; mặc định JSON tóm tắt.", [Q("format", enum("JSON", "PDF", "XLSX"))]),
  "075": ("exportAccessReviewReport", "ReportExportRequest", "JobAccepted", ["020"], "Chạy nền, trả `202` kèm `Location` tới API-01-088.", []),
  "076": ("searchDirectoryContacts", None, "DirectoryPage", ["003", "045"], "Chỉ đầu mối công khai (BR-01-027); giới hạn `directory.rateLimitPerMinute` mỗi người dùng.",
          [Q("q", STR(100, minLength=1)), Q("orgId", R("OrgId")), Q("systemCode", R("SystemCode")), Q("contactType", enum("BUSINESS", "TECHNICAL")), *PG]),
  "077": ("listOrganizationContacts", None, "DirectoryPage", ["045"], "Đầu mối công khai của một tổ chức (BR-01-027); cùng giới hạn tốc độ với API-01-076.", PG),
  "078": ("listDirectoryGaps", None, "DirectoryGaps", ["003"], "Tổ chức có HTTT thiếu đầu mối kỹ thuật hoạt động, và đầu mối quá `directory.staleMonths` chưa xác nhận.", [Q("kind", enum("ORG_GAP", "STALE", "ALL")), *PG]),
  "079": ("exportDirectoryContacts", "ExportRequest", "JobAccepted", ["033", "045"], "Xuất toàn bộ danh bạ chỉ TA, AU; bắt buộc `purpose`, ghi kiểm toán xuất. Nhỏ: `200` tệp; lớn: `202` kèm `Location`.", []),
  "080": ("uploadLegacyImport", "LegacyImportUpload", "LegacyImportJob", ["042", "044"], "Đọc tệp, bỏ mọi cột bí mật (chỉ đếm `secretsDropped`), đối chiếu tổ chức, trả bản xem trước. Chưa tạo hồ sơ nào.", []),
  "081": ("getLegacyImport", None, "LegacyImportJob", [], "Trạng thái tác vụ nhập, bản xem trước và số dòng tạo, bỏ qua, cảnh báo.", []),
  "082": ("confirmLegacyImport", "LegacyImportConfirm", "LegacyImportJob", ["043", "044"], "Tạo hồ sơ `DRAFT` cho dòng `CREATE` (chỉ mục duy nhất `(tenant, legacy_ref)` chặn nhân đôi); HTTT cũ chưa có định danh mới phải được cấp lại qua quy trình thường.", []),
  "083": ("listSettings", None, "SettingList", [], "30 khóa `onboarding.*` (FRS §8.2) kèm mặc định, miền, trần PA.", []),
  "084": ("putSetting", "SettingPut", "Setting", ["007", "033", "035", "044"], "TA, PA; vượt miền hoặc trần PA trả ERR-01-044. Chỉ áp cho thao tác mới.", []),
  "085": ("exportSystems", "ExportRequest", "JobAccepted", ["003"], "Xuất toàn bộ tenant chỉ TA, AU, PA; không có cột bí mật. Nhỏ: `200` tệp; lớn: `202` kèm `Location`.", []),
  "086": ("getStatistics", None, "StatisticsView", ["003"], "Mặc định 90 ngày gần nhất.", [Q("from", DATE), Q("to", DATE), Q("ownerOrgId", R("OrgId"))]),
  "088": ("getJob", None, "Job", [], "Chỉ người tạo tác vụ hoặc TA, AU. `downloadUrl` là liên kết ký, hết hạn 15 phút.", []),
}

ETAG_SCHEMAS = {"SystemDetail", "StateChangeResult", "TechnicalProfileView", "DataDemandList", "Credential", "Setting", "ReplicaSystem", "ChangeRequest"}
TAGS = {"sys": "Hồ sơ HTTT", "attach": "Tài liệu và mẫu", "tech": "Hồ sơ kỹ thuật và nhu cầu", "contact": "Đầu mối", "review": "Nộp, thẩm định, phê duyệt",
        "cred": "Định danh và bàn giao", "life": "Vòng đời thành viên", "internal": "Nội bộ (phân hệ khác)", "ar": "Rà soát quyền định kỳ",
        "dir": "Danh bạ đầu mối", "admin": "Di trú, tham số, thống kê"}
PERM_TEXT = {"base": "Quyền cơ sở người dùng nội bộ tenant (không cần mã quyền riêng)",
             "assigned": "Người được phân công bước thẩm định (`PERM-01-read` kèm phân công của TA)",
             "link": "Đầu mối nhận liên kết, đã đăng nhập và xác thực hai yếu tố"}
BODY_MEDIA = {"005": "application/merge-patch+json", "016": "application/merge-patch+json", "007": "multipart/form-data", "080": "multipart/form-data"}
OPTIONAL_BODY = {"023", "026", "032", "035", "038", "039", "041", "044", "045", "046", "055", "062", "069", "082"}
FILE_RESP = {"008": ["application/octet-stream"], "021": ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/pdf"]}
FILE_ALT = {"074": ["application/pdf", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
            "079": ["text/csv", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
            "085": ["text/csv", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]}


def fr_list(fr):
    out = []
    for part in fr.split(","):
        part = part.strip()
        out.append(f"FR-01-{part}")
    return out


def err_set(code, method, path, body_present, params, idem, extra):
    codes = set(extra)
    if "{" in path:
        codes.add("001")
    if body_present:
        codes.add("003")
    if any("If-Match" in str(p) for p in params):
        codes.add("007")
    if idem:
        codes |= {"051", "054"}
    codes.add("052")
    return sorted(codes)


def build():
    assert set(X) == {o[0] for o in spec.OPS}, set(X) ^ {o[0] for o in spec.OPS}
    paths, all_errs = {}, set()
    for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
        opid, body, resp, errs, desc, extra = X[code]
        m = method.lower()
        op = {"tags": [TAGS[group]], "operationId": opid, "summary": summary, "x-datahub-id": f"API-01-{code}", "x-datahub-fr": fr_list(fr)}
        if perm == "service":
            sc = spec.SERVICE_SCOPE[code]
            op["x-datahub-permission"] = {"permission": f"Token dịch vụ, scope `{sc}`", "serviceScope": sc}
            op["security"] = [{"oauth2Service": [sc]}]
        else:
            if code in spec.ANY_PERM:
                txt = " hoặc ".join(f"`{x.split(' ')[0]}`" + (" (được phân công)" if "phân công" in x else "") for x in spec.ANY_PERM[code])
                op["x-datahub-permission"] = {"permission": txt, "anyOf": [x.split(" ")[0] for x in spec.ANY_PERM[code]]}
            elif perm in PERM_TEXT:
                op["x-datahub-permission"] = {"permission": PERM_TEXT[perm], "kind": perm}
            else:
                name = perm if perm.startswith("PERM-") else f"PERM-01-{perm}"
                op["x-datahub-permission"] = {"permission": name}
        if desc:
            op["description"] = desc
        if idem:
            op["x-datahub-idempotent"] = True
        params = [P(PATH_PARAM[n]) for n in re.findall(r"\{(\w+)\}", path)]
        versioned = m in ("put", "patch", "delete") or (m == "post" and ":" in path.split("/")[-1])
        if versioned and code not in spec.NO_IF_MATCH and perm != "service":
            params.append(P("IfMatchOptional" if code in spec.IF_MATCH_OPTIONAL else "IfMatch"))
        elif code in spec.IF_MATCH_OPTIONAL:
            params.append(P("IfMatchOptional"))
        for e in extra:
            params.append(P(e) if isinstance(e, str) else e)
        if idem:
            params.append(P("IdempotencyKey"))
        params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = params
        if body:
            media = BODY_MEDIA.get(code, "application/json")
            rb = {"required": code not in OPTIONAL_BODY, "content": {media: {"schema": R(body)}}}
            if body in EXAMPLES:
                rb["content"][media]["example"] = copy.deepcopy(EXAMPLES[body])
            op["requestBody"] = rb
        succ = success.split("|")
        main = succ[0]
        okr = {"description": "Thành công."}
        if code in FILE_RESP:
            okr["content"] = {ct: {"schema": {"type": "string", "contentEncoding": "binary"}} for ct in FILE_RESP[code]}
        elif resp:
            okr["content"] = {"application/json": {"schema": R(resp)}}
            if resp in EXAMPLES:
                okr["content"]["application/json"]["example"] = copy.deepcopy(EXAMPLES[resp])
            for ct in FILE_ALT.get(code, []):
                okr["content"][ct] = {"schema": {"type": "string", "contentEncoding": "binary"}}
        if code in ("040", "070"):
            okr.setdefault("headers", {})["Cache-Control"] = {"schema": STR(), "description": "`no-store`."}
        hdr = okr.setdefault("headers", {})
        if resp in ETAG_SCHEMAS or (m == "get" and resp in ETAG_SCHEMAS):
            hdr["ETag"] = {"schema": STR(), "description": "Giá trị `version`."}
        if main in ("201", "202"):
            hdr["Location"] = {"schema": STR(), "description": "Tài nguyên vừa tạo hoặc nơi theo dõi tiến trình."}
        if not hdr:
            okr.pop("headers")
        resps = {main: okr}
        if main == "204":
            resps["204"] = {"description": "Đã xử lý, không có nội dung."}
        if "202" in succ[1:]:
            alt = {"description": "Đã nhận, xử lý bất đồng bộ.", "headers": {"Location": {"schema": STR(), "description": "Nơi theo dõi tiến trình."}}}
            alt_schema = {"044": "StateChangeResult", "057": "ChangeRequestOutcome"}.get(code, "JobAccepted")
            alt["content"] = {"application/json": {"schema": R(alt_schema)}}
            resps["202"] = alt
        if code == "008":
            resps["302"] = {"description": "Chuyển tới liên kết ký 5 phút của kho tệp.", "headers": {"Location": {"schema": STR(2048, format="uri")}}}
        codes = err_set(code, method, path, bool(body), params, idem, errs)
        # `ProblemDetails` theo mã HTTP của từng mã lỗi
        statuses = set()
        for c in codes:
            for st in ERR[c][0].split(","):
                statuses.add(st.strip())
        statuses.add("401")
        if m != "get":
            statuses.add("403")
        for st in sorted(statuses):
            resps[st] = RESP(HTTP_RESP[st][0])
        op["x-datahub-errors"] = [f"ERR-01-{c}" for c in codes if c != "052"] + ["ERR-01-052"]
        all_errs |= set(codes)
        op["responses"] = dict(sorted(resps.items()))
        paths.setdefault(path, {})[m] = op
    return {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-01 Kết nạp hệ thống thông tin API", "version": "1.0.0-draft",
               "summary": "Hồ sơ kết nạp, thẩm định, định danh ứng dụng, bàn giao một lần, vòng đời thành viên, rà soát quyền, danh bạ đầu mối.",
               "description": ("API của module `onboarding` trong `dh-connect` (control plane PH-01). Người dùng gọi qua BFF console của tenant "
                   "(Authorization Code + PKCE); `/internal/*` do phân hệ khác gọi bằng token dịch vụ (client credentials). "
                   "HTTT thành viên không gọi API này; HTTT chỉ nhận thông tin xác thực qua trang bàn giao (API-01-040).\n\n"
                   "Quy ước (D03-04-PH01 §1): tenant lấy từ token, không từ đường dẫn hay thân; tạo và lệnh có tác dụng phụ nhận `Idempotency-Key`; "
                   "sửa và đổi trạng thái bắt buộc `If-Match` (ETag là `version`) trừ thao tác khẩn; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-01-nnn`; "
                   "phân trang `page`, `size`. **Chỉ một operation (API-01-040) trả giá trị bí mật**, một lần, `no-store`. Mọi tên miền, dữ liệu là giả lập.\n\n"
                   "Tệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-01"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH01", "x-datahub-phase": "PH-01"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn" + spec.BASE, "description": "Qua BFF console của tenant — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
                  {"url": "http://dh-connect.dh-control.svc:8080" + spec.BASE, "description": "Trong cụm, cho phân hệ khác (`/internal/*`)"},
                  {"url": "http://localhost:8082" + spec.BASE, "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": v} for v in TAGS.values()],
      "paths": paths,
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-01-*, PERM-18-* (D02-08). Thao tác nhạy cảm cần `acr` hai yếu tố trong `mfa.stepUpMinutes`.",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Token dịch vụ của phân hệ khác; kiểm `azp` và `tenant`, không cấp cho người.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
                "scopes": {"onboarding:internal-read": "Đọc bản sao HTTT (PH-02, 03, 04, 05, 10, 13, 14, 15)",
                           "onboarding:provision-callback": "Trả kết quả bất đồng bộ của saga (PH-12, PH-03)",
                           "onboarding:reconcile": "Chạy đối chiếu trạng thái"}}}}},
        "parameters": PARAMS, "responses": RESPONSES, "schemas": SCHEMAS}}


if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-onboarding.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH01 · OpenAPI PH-01 (dh-connect, module onboarding). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay. Dữ liệu ví dụ là giả lập.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(len(v) for v in doc["paths"].values())
    print(f"{n} operation, {len(SCHEMAS)} lược đồ → {out}")
