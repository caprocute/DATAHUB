#!/usr/bin/env python3
"""Sinh ba tệp OpenAPI 3.1 của PH-19 từ khung truy vết (danh sách endpoint, mã lỗi) và bảng chi tiết dưới đây.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph19)
  → openapi-payment-admin.yaml    /api/payment/v1            API-19-001…092
  → openapi-payment-partner.yaml  /api/payment-partner/v1    API-19-101…110 + webhooks
  → openapi-payment-callback.yaml /api/payment-callback/v1   API-19-201…204
Phương thức, đường dẫn, tóm tắt, quyền, FR đọc từ khung §10.2, §10.3 (một nguồn); mã lỗi, HTTP đọc từ khung §12.
Tệp YAML là hợp đồng sinh ra: sửa tệp này hoặc khung rồi sinh lại, không sửa tay YAML.
"""
import copy, os, re, sys, yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.abspath(os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "ph19", "tools")))
from schemas import SCHEMAS, R, STR, INT, BOOL, TS, DATE, UUID, arr, enum, obj  # noqa: E402
from khung import Khung  # noqa: E402

K = Khung()

# ------------------------------------------------------------------ đọc khung
def _strip(x): return x.strip().strip("`")
ENDPOINTS = []
for sec in ("10.2", "10.3"):
    for t in K.tables(sec):
        for r in t["rows"]:
            if not r.get("Mã", "").startswith("API-19-"): continue
            path = _strip(r.get("Đường dẫn (sau `/api/payment/v1`)") or r.get("Đường dẫn"))
            ENDPOINTS.append({"aid": r["Mã"], "method": r["Method"].lower(), "path": path, "summary": r["Mô tả"],
                              "perm": r["PERM"], "fr": r["FR"]})
# hai API đề xuất của FRS (FR-19-069, Phụ lục A)
ENDPOINTS += [
  {"aid": "API-19-091", "method": "get", "path": "/providers/{providerId}/result-mappings", "summary": "Xem bảng ánh xạ mã kết quả hiện hành, lịch sử, mã chưa ánh xạ (đề xuất)", "perm": "provider-read", "fr": "FR-19-069"},
  {"aid": "API-19-092", "method": "post", "path": "/providers/{providerId}/result-mapping-changes", "summary": "Lập đề nghị đổi bảng ánh xạ mã kết quả (đề xuất)", "perm": "provider-write", "fr": "FR-19-069"},
]
ERRS = {}
for r in K.rows("12"):
    if r.get("Mã", "").startswith("ERR-19-"):
        ERRS[r["Mã"]] = (int(r["HTTP"]), r["Tiêu đề"], r["Khi nào"], r["Thử lại"])

def expand_fr(s):
    out, last = [], None
    for part in re.split(r",\s*", s.replace("như trên", "")):
        part = part.strip()
        m = re.match(r"FR-19-(\d{3})", part)
        if m: out.append(f"FR-19-{m.group(1)}"); continue
        m = re.match(r"(\d{3})$", part)
        if m: out.append(f"FR-19-{m.group(1)}")
    return out

# ------------------------------------------------------------------ tham số
def pp(name, schema=UUID, desc=None):
    d = {"name": name, "in": "path", "required": True, "schema": schema}
    if desc: d["description"] = desc
    return d
PARAMS = {
  "Cursor": {"name": "cursor", "in": "query", "schema": STR(2048), "description": "Con trỏ mờ từ `page.next`."},
  "Limit": {"name": "limit", "in": "query", "schema": INT(minimum=1, maximum=200, default=20), "description": "Mặc định 20, tối đa 200 (khung §10.1)."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại (`W/\"{version}\"`); lệch trả ERR-19-045 (412)."},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(64, minLength=16, pattern="^[A-Za-z0-9_-]{16,64}$"),
                     "description": "16…64 ký tự `[A-Za-z0-9_-]`, lưu 24 giờ (BR-19-006); thiếu ERR-19-002, khác nội dung ERR-19-003, đang xử lý ERR-19-004."},
  "IdempotencyKeyOpt": {"name": "Idempotency-Key", "in": "header", "required": False, "schema": STR(64, minLength=16, pattern="^[A-Za-z0-9_-]{16,64}$"),
                     "description": "Khuyến nghị cho thao tác tạo của giao diện (chống bấm hai lần)."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "providerId": pp("providerId"), "groupId": pp("groupId"), "serviceId": pp("serviceId"), "partnerId": pp("partnerId"),
  "clientId": pp("clientId"), "endpointId": pp("endpointId"), "approvalId": pp("approvalId"), "transactionId": pp("transactionId"),
  "callbackId": pp("callbackId"), "refundId": pp("refundId"), "sessionId": pp("sessionId"), "discrepancyId": pp("discrepancyId"),
  "logId": pp("logId"), "deliveryId": pp("deliveryId"), "jobId": pp("jobId"), "fileId": pp("fileId"),
  "environment": pp("environment", R("Environment")), "catalogCode": pp("catalogCode", STR(64, pattern="^DM_[A-Z0-9_]+$"), "Ví dụ `DM_LOAI_PHI`, `DM_CO_QUAN_THU`, `DM_NGAN_HANG`."),
  "reportCode": pp("reportCode", R("ReportCode")), "transactionCode": pp("transactionCode", R("TransactionCode")),
  "refundCode": pp("refundCode", R("RefundCode")),
  "connectionKey": pp("connectionKey", STR(32, pattern="^[0-9A-HJKMNP-TV-Z]{32}$"), "Khóa kết nối 160 bit, Base32 Crockford (ADR-045)."),
  "operation": pp("operation", enum("create", "query", "refund", "query-refund")),
}
def q(name, schema, desc=None, explode=None):
    d = {"name": name, "in": "query", "schema": schema}
    if desc: d["description"] = desc
    if explode is not None: d["style"] = "form"; d["explode"] = explode
    return d
def qa(name, item, desc=None): return q(name, arr(item), desc, explode=False)

FROM_TO = [q("from", TS, "Từ thời điểm (bao gồm)."), q("to", TS, "Tới thời điểm (không bao gồm).")]
TXN_FILTERS = [q("q", STR(100, minLength=2), "Tìm theo mã giao dịch, mã đơn hàng, tham chiếu NCC (khớp chính xác hoặc tiền tố)."),
               qa("status", R("TransactionStatus")), qa("reconStatus", R("ReconStatus")), qa("serviceCode", R("Code")), qa("groupCode", R("Code"), "Nhóm dịch vụ (lĩnh vực), chọn nhiều (LGC-PAY-016)."),
               qa("partnerCode", R("Code")), qa("providerCode", R("Code")), *FROM_TO,
               q("paidFrom", TS), q("paidTo", TS), q("amountMin", R("Money")), q("amountMax", R("Money")),
               q("payerName", STR(255), "Khớp chính xác sau chuẩn hóa (băm HMAC, ADR-048)."), q("payerPhone", STR(20)), q("payerIdNumber", STR(20)),
               q("includeTest", {"type": "boolean", "default": False}), q("includeShadow", {"type": "boolean", "default": False}),
               q("needsReconciliation", BOOL), q("latePaid", BOOL), q("initUncertain", BOOL), q("sort", STR(pattern="^-?(createdAt|paidAt|amount)$", default="-createdAt")), "Cursor", "Limit"]

# ------------------------------------------------------------------ chi tiết từng API
# op, tag, params, body, ok(code, schema), errs (mã ERR riêng), idem ('req'|'opt'|None), ifm (If-Match), desc, mp (multipart), etag
D = {}
def d(aid, op, tag, ok=(200, None), params=(), body=None, errs=(), idem=None, ifm=False, desc=None, mp=None, etag=False, ex=None):
    D[aid] = dict(op=op, tag=tag, ok=ok, params=list(params), body=body, errs=list(errs), idem=idem, ifm=ifm, desc=desc, mp=mp, etag=etag, ex=ex)

T = "Nhà cung cấp"
d("API-19-001", "listProviders", T, (200, "ProviderPage"), [qa("status", R("ProviderStatus")), qa("health", R("HealthStatus")), q("q", STR(100, minLength=2)), "Cursor", "Limit"])
d("API-19-002", "createProvider", T, (201, "ProviderDetail"), body="ProviderCreate", errs=["ERR-19-038"], idem="opt", etag=True,
  desc="Tạo NCC `DRAFT`, sinh `connectionKey` (lưu OpenBao, CSDL chỉ giữ băm) và dòng `callback_route`; với adapter `PAYGOV` nạp bảng ánh xạ mã mặc định phiên bản 1 (giả định, SDD §7.3).")
d("API-19-003", "getProvider", T, (200, "ProviderDetail"), ["providerId"], etag=True)
d("API-19-004", "updateProvider", T, (200, "ProviderDetail"), ["providerId"], "ProviderUpdate", ["ERR-19-021"], ifm=True, etag=True,
  desc="NCC `ACTIVE`: trường kỹ thuật vào `pendingChange` và tạo đề nghị phê duyệt (BR-19-026); trường liên hệ áp ngay.")
d("API-19-005", "deleteProvider", T, (204, None), ["providerId"], errs=["ERR-19-021", "ERR-19-037"], ifm=True, desc="Chỉ NCC `DRAFT` chưa có dịch vụ, giao dịch.")
d("API-19-006", "listProviderCredentials", T, (200, "CredentialList"), ["providerId"])
d("API-19-007", "bindProviderCredentials", T, (200, "CredentialList"), ["providerId", "environment"], "CredentialBind", ["ERR-19-022"], ifm=True,
  desc="Chỉ nhận tham chiếu OpenBao; giá trị bí mật nạp bằng quy trình riêng của SEC (NFR-19-022).")
d("API-19-008", "rotateProviderCredential", T, (200, "CredentialList"), ["providerId", "environment"], "CredentialRotation", ["ERR-19-022"], ifm=True,
  desc="Khóa mới ở `NEXT`, khóa cũ hợp lệ tới `transitionUntil` (BR-19-026, `19.provider.credential-transition-days`).")
d("API-19-009", "runConnectionTest", T, (202, "CheckRun"), ["providerId"], "ConnectionTestRequest", ["ERR-19-022", "ERR-19-021"], idem="opt")
d("API-19-010", "createTestTransaction", T, (202, "CheckRun"), ["providerId"], "TestTransactionRequest", ["ERR-19-022", "ERR-19-021"], idem="opt",
  desc="Giao dịch thử thuộc đối tác ẩn `__TEST__`, không vào số liệu (BR-19-033).")
d("API-19-011", "listProviderCheckRuns", T, (200, "CheckRunList"), ["providerId", qa("checkType", R("CheckType")), q("environment", R("Environment"))])
d("API-19-012", "requestProviderLifecycle", T, (201, "ApprovalRef"), ["providerId"], "ProviderLifecycleRequest", ["ERR-19-021", "ERR-19-035", "ERR-19-036"], ifm=True,
  desc="`ACTIVATE` cần `provider-write`, `RETIRE` cần `provider-delete`. Checklist BR-19-010 chụp vào `payload` của đề nghị.")
d("API-19-013", "suspendProvider", T, (200, "ProviderDetail"), ["providerId"], "StatusChange", ["ERR-19-021"], ifm=True, etag=True,
  desc="Hiệu lực ngay; giao dịch mới tới dịch vụ của NCC trả ERR-19-017.")
d("API-19-014", "resumeProvider", T, (200, "ProviderDetail"), ["providerId"], "StatusChange", ["ERR-19-021", "ERR-19-022"], ifm=True, etag=True)
d("API-19-091", "getResultMappings", T, (200, "ResultMappingView"), ["providerId"])
d("API-19-092", "requestResultMappingChange", T, (201, "ApprovalRef"), ["providerId"], "ResultMappingChange", ["ERR-19-021"], ifm=True,
  desc="Tạo bản nháp phiên bản n+1 và đề nghị `RESULT_MAPPING_CHANGE`; hiệu lực khi duyệt (SDD §7.4).")

T = "Nhóm dịch vụ"
d("API-19-015", "listServiceGroups", T, (200, "ServiceGroupList"), [q("q", STR(100, minLength=2)), q("includeDeleted", {"type": "boolean", "default": False})])
d("API-19-016", "createServiceGroup", T, (201, "ServiceGroup"), body="ServiceGroupCreate", errs=["ERR-19-038", "ERR-19-039"], idem="opt", etag=True)
d("API-19-017", "getServiceGroup", T, (200, "ServiceGroup"), ["groupId"], etag=True)
d("API-19-018", "updateServiceGroup", T, (200, "ServiceGroup"), ["groupId"], "ServiceGroupUpdate", ["ERR-19-039"], ifm=True, etag=True)
d("API-19-019", "deleteServiceGroup", T, (204, None), ["groupId"], errs=["ERR-19-037"], ifm=True)

T = "Dịch vụ"
d("API-19-020", "listServices", T, (200, "ServicePage"), [q("q", STR(100, minLength=2)), qa("status", R("ServiceStatus")), q("groupId", UUID), q("providerId", UUID),
  q("catalogInvalid", BOOL), "Cursor", "Limit"])
d("API-19-021", "createService", T, (201, "Service"), body="ServiceCreate", errs=["ERR-19-038", "ERR-19-039", "ERR-19-010"], idem="opt", etag=True)
d("API-19-022", "getService", T, (200, "Service"), ["serviceId"], etag=True)
d("API-19-023", "updateService", T, (200, "Service"), ["serviceId"], "ServiceUpdate", ["ERR-19-039", "ERR-19-021", "ERR-19-010"], ifm=True, etag=True)
d("API-19-024", "deleteService", T, (204, None), ["serviceId"], errs=["ERR-19-021", "ERR-19-037"], ifm=True)
d("API-19-025", "activateService", T, (200, "Service"), ["serviceId"], errs=["ERR-19-021", "ERR-19-039"], ifm=True, etag=True,
  desc="Cần NCC `ACTIVE` và mã danh mục còn hiệu lực.")
d("API-19-026", "suspendService", T, (200, "Service"), ["serviceId"], "StatusChange", ["ERR-19-021"], ifm=True, etag=True)
d("API-19-027", "retireService", T, (200, "Service"), ["serviceId"], "StatusChange", ["ERR-19-021", "ERR-19-036"], ifm=True, etag=True)
d("API-19-028", "lookupCatalogItems", T, (200, "CatalogItemList"), ["catalogCode", q("q", STR(100)), q("parentCode", STR(64))],
  desc="Đọc qua PH-07, đệm 10 phút; PH-07 không phản hồi trả dữ liệu đệm kèm `cachedAt`.")

T = "Đối tác"
d("API-19-029", "listPartners", T, (200, "PartnerPage"), [q("q", STR(100, minLength=2)), qa("status", R("PartnerStatus")), qa("routingMode", R("RoutingMode")), "Cursor", "Limit"])
d("API-19-030", "createPartner", T, (201, "Partner"), body="PartnerCreate", errs=["ERR-19-038", "ERR-19-039", "ERR-19-016"], idem="opt", etag=True)
d("API-19-031", "getPartner", T, (200, "Partner"), ["partnerId"], etag=True)
d("API-19-032", "updatePartner", T, (200, "Partner"), ["partnerId"], "PartnerUpdate", ["ERR-19-021", "ERR-19-039"], ifm=True, etag=True)
d("API-19-033", "requestPartnerLifecycle", T, (201, "ApprovalRef"), ["partnerId"], "PartnerLifecycleRequest", ["ERR-19-021", "ERR-19-035"], ifm=True)
d("API-19-034", "suspendPartner", T, (200, "Partner"), ["partnerId"], "StatusChange", ["ERR-19-021"], ifm=True, etag=True,
  desc="Hiệu lực ngay; API đối tác trả ERR-19-005. Giao dịch đang chờ vẫn nhận IPN và webhook.")
d("API-19-035", "resumePartner", T, (200, "Partner"), ["partnerId"], "StatusChange", ["ERR-19-021"], ifm=True, etag=True)
d("API-19-036", "listPartnerClients", T, (200, "PartnerClientList"), ["partnerId"])
d("API-19-037", "createPartnerClient", T, (201, "PartnerClient"), ["partnerId"], "PartnerClientCreate", ["ERR-19-021"], idem="opt",
  desc="Tạo client tại PH-12 (realm `dh-{tenant}`) với vai trò `ROLE-PARTNER_SYSTEM`; không phát hành bí mật dùng chung.")
d("API-19-038", "revokePartnerClient", T, (204, None), ["partnerId", "clientId"], desc="Thu hồi tại PH-12 trong ≤ 60 giây (token hiện có hết hiệu lực khi hết hạn ≤ 5 phút).")
d("API-19-039", "listServiceGrants", T, (200, "ServiceGrantList"), ["partnerId"])
d("API-19-040", "putServiceGrant", T, (200, "ServiceGrant"), ["partnerId", "serviceId"], "ServiceGrantPut", ["ERR-19-021", "ERR-19-010"],
  desc="Tạo hoặc thay gán; khi đã có gán thì bắt buộc `If-Match`.")
d("API-19-041", "deleteServiceGrant", T, (204, None), ["partnerId", "serviceId"], ifm=True)
d("API-19-042", "listWebhookEndpoints", T, (200, "WebhookEndpointList"), ["partnerId"])
d("API-19-043", "createWebhookEndpoint", T, (201, "WebhookEndpointCreated"), ["partnerId"], "WebhookEndpointCreate", ["ERR-19-044"], idem="opt",
  desc="Bí mật HMAC sinh ở máy chủ, trả một lần, lưu `kv/dh/{tenant}/payment/partners/{partnerCode}/webhooks/{endpointId}`.")
d("API-19-044", "updateWebhookEndpoint", T, (200, "WebhookEndpoint"), ["partnerId", "endpointId"], "WebhookEndpointUpdate", ["ERR-19-044"], ifm=True, etag=True,
  desc="`DISABLED` hủy các lượt gửi `PENDING`, `RETRY_SCHEDULED` của đầu nhận.")
d("API-19-045", "testWebhookEndpoint", T, (200, "WebhookTestResult"), ["partnerId", "endpointId"], errs=["ERR-19-021"],
  desc="Gửi sự kiện `webhook.test` ký thật; kết quả đồng bộ (timeout 10 giây).")
d("API-19-046", "rotateWebhookSecret", T, (200, "WebhookSecretRotation"), ["partnerId", "endpointId"], ifm=True,
  desc="Hai chữ ký `v1` trong 7 ngày chuyển tiếp (ADR-044).")
d("API-19-047", "requestRoutingModeChange", T, (201, "ApprovalRef"), ["partnerId"], "RoutingModeRequest", ["ERR-19-021", "ERR-19-035"], ifm=True)

T = "Phê duyệt"
d("API-19-048", "listApprovals", T, (200, "ApprovalPage"), [q("box", enum("TO_DECIDE", "MINE", "ALL"), "Hộp: cần tôi quyết định, tôi lập, tất cả (theo quyền)."),
  qa("approvalType", R("ApprovalType")), qa("status", R("ApprovalStatus")), *FROM_TO, "Cursor", "Limit"])
d("API-19-049", "getApproval", T, (200, "Approval"), ["approvalId"], etag=True)
d("API-19-050", "decideApproval", T, (200, "Approval"), ["approvalId"], "ApprovalDecision", ["ERR-19-033", "ERR-19-034", "ERR-19-035", "ERR-19-021"], ifm=True, etag=True,
  desc="Quyền theo loại đề nghị (khung §13.4). Áp thay đổi lên đối tượng đích trong cùng giao dịch CSDL; điều kiện không còn đúng thì trả mã lỗi của module (SDD §12).")

T = "Giao dịch"
d("API-19-051", "listTransactions", T, (200, "TransactionPage"), TXN_FILTERS,
  desc="Đọc bản sao `pg-payment-ro`. Tìm theo người nộp cần `transaction-read-pii`. Trang ≤ 1,5 giây p95 với 10 triệu giao dịch (NFR-19-007).")
d("API-19-052", "getTransaction", T, (200, "TransactionDetail"), ["transactionId", q("reveal", {"type": "boolean", "default": False},
  "Hiện dữ liệu người nộp đầy đủ; cần `transaction-read-pii`, mỗi lần ghi kiểm toán (BR-19-031)."),
  {"name": "X-Datahub-Reveal-Reason", "in": "header", "schema": STR(500, minLength=10),
   "description": "Lý do tra cứu, bắt buộc khi `reveal=true` (khung §13.4 quy tắc 6); thiếu trả ERR-19-001. Đặt ở tiêu đề để không lọt vào nhật ký URL."}], etag=True)
d("API-19-053", "syncTransactionStatus", T, (200, "StatusSyncResult"), ["transactionId"], errs=["ERR-19-021", "ERR-19-023", "ERR-19-017"],
  desc="Gọi truy vấn NCC; tối đa 1 lần/60 giây, 10 lần/ngày mỗi giao dịch.")
d("API-19-054", "listTransactionEvents", T, (200, "TransactionEventList"), ["transactionId"])
d("API-19-055", "cancelTransaction", T, (200, "TransactionDetail"), ["transactionId"], "AdminCancellation", ["ERR-19-021"], ifm=True, etag=True)

T = "Thông báo IPN"
d("API-19-056", "listCallbacks", T, (200, "CallbackPage"), [qa("processingStatus", R("ProcessingStatus")), qa("verificationResult", R("VerificationResult")),
  qa("callbackType", R("CallbackType")), q("providerId", UUID), q("transactionCode", STR(32)), *FROM_TO, "Cursor", "Limit"])
d("API-19-057", "getCallback", T, (200, "CallbackDetail"), ["callbackId"])
d("API-19-058", "replayCallback", T, (202, "CallbackDetail"), ["callbackId"], "CallbackReplay", ["ERR-19-021"],
  desc="Chỉ IPN `QUARANTINED`, `FAILED` đã `VERIFIED`; xử lý lại bằng bảng ánh xạ hiện hành.")

T = "Hoàn tiền"
d("API-19-059", "createRefund", T, (201, "Refund"), body="RefundCreate", errs=["ERR-19-020", "ERR-19-029", "ERR-19-030", "ERR-19-031", "ERR-19-032", "ERR-19-039"], idem="opt", etag=True,
  desc="Tạo yêu cầu `PENDING_APPROVAL` và đề nghị `REFUND` (1 hoặc 2 cấp theo `19.refund.two-level-threshold`).")
d("API-19-060", "listRefunds", T, (200, "RefundPage"), [qa("status", R("RefundStatus")), qa("mode", R("RefundMode")), q("transactionCode", STR(32)), *FROM_TO, "Cursor", "Limit"])
d("API-19-061", "getRefund", T, (200, "Refund"), ["refundId"], etag=True)
d("API-19-062", "executeRefund", T, (200, "Refund"), ["refundId"], "RefundExecution", ["ERR-19-021", "ERR-19-033", "ERR-19-032"], ifm=True, etag=True,
  desc="`RETRY` tối đa 3 lần; `RECORD_MANUAL` cần chứng từ, người ghi khác người duyệt.")

T = "Đối soát"
d("API-19-063", "createReconSession", T, (201, "SessionDetail"), body="SessionCreate", errs=["ERR-19-040", "ERR-19-021"], idem="opt", etag=True)
d("API-19-064", "listReconSessions", T, (200, "SessionPage"), [q("providerId", UUID), qa("status", R("SessionStatus")), q("dateFrom", DATE), q("dateTo", DATE), "Cursor", "Limit"])
d("API-19-065", "uploadReconFile", T, (202, "SessionDetail"), ["sessionId"], errs=["ERR-19-041", "ERR-19-043", "ERR-19-021"], ifm=True, mp="ReconFileUpload",
  desc="Tệp lưu Garage trước (`RECON_SOURCE`), kiểm băm, rồi chuyển `COLLECTING`.")
d("API-19-066", "runReconSession", T, (202, "SessionDetail"), ["sessionId"], "SessionRun", ["ERR-19-021", "ERR-19-043"], ifm=True)
d("API-19-067", "getReconSession", T, (200, "SessionDetail"), ["sessionId"], etag=True)
d("API-19-068", "closeReconSession", T, (202, "SessionDetail"), ["sessionId"], "SessionClosure", ["ERR-19-042", "ERR-19-021"], ifm=True,
  desc="Sinh biên bản PDF, XLSX, lưu WORM; phiên `CLOSED` khi biên bản lưu xong (`closingJobId`).")
d("API-19-069", "requestReconReopen", T, (201, "ApprovalRef"), ["sessionId"], "ReopenRequest", ["ERR-19-021"], ifm=True)
d("API-19-070", "listReconItems", T, (200, "ReconItemPage"), ["sessionId", q("runNo", INT(minimum=1)), qa("matchResult", R("MatchResult")), q("itemKind", enum("PAYMENT", "REFUND")), "Cursor", "Limit"])

T = "Chênh lệch"
d("API-19-071", "listDiscrepancies", T, (200, "DiscrepancyPage"), [qa("type", R("DiscrepancyType")), qa("status", R("DiscrepancyStatus")), q("assigneeId", STR(64)),
  q("overdue", BOOL), q("sessionId", UUID), q("providerId", UUID), q("dateFrom", DATE), q("dateTo", DATE), "Cursor", "Limit"])
d("API-19-072", "updateDiscrepancy", T, (200, "DiscrepancyDetail"), ["discrepancyId"], "DiscrepancyPatch", ["ERR-19-021", "ERR-19-043"], ifm=True, etag=True,
  desc="Ghi chú chỉ nối thêm (`append_discrepancy_note`).")
d("API-19-073", "proposeResolution", T, (201, "ApprovalRef"), ["discrepancyId"], "ResolutionProposal", ["ERR-19-021", "ERR-19-043", "ERR-19-030"], ifm=True)
d("API-19-074", "getDiscrepancy", T, (200, "DiscrepancyDetail"), ["discrepancyId"], etag=True)

T = "Nhật ký và webhook"
d("API-19-075", "listIntegrationLogs", T, (200, "IntegrationLogPage"), [qa("direction", R("LogDirection")), qa("operation", R("LogOperation")),
  q("providerId", UUID), q("partnerId", UUID), q("transactionCode", STR(32)), q("traceId", STR(32, pattern="^[0-9a-f]{32}$")),
  q("httpStatusMin", INT()), *FROM_TO, "Cursor", "Limit"], desc="Trực tuyến 12 tháng (NFR-19-015).")
d("API-19-076", "getIntegrationLog", T, (200, "IntegrationLogDetail"), ["logId"])
d("API-19-077", "listWebhookDeliveries", T, (200, "WebhookDeliveryPage"), [q("partnerId", UUID), qa("status", R("WebhookDeliveryStatus")), q("eventType", STR(64)),
  q("transactionCode", STR(32)), *FROM_TO, "Cursor", "Limit"])
d("API-19-078", "resendWebhookDelivery", T, (202, "WebhookDelivery"), ["deliveryId"], "WebhookResend", ["ERR-19-021"], ifm=True,
  desc="`EXHAUSTED → PENDING` trên chính lượt gửi, giữ `eventId`; đầu nhận phải `ACTIVE`.")
d("API-19-079", "getWebhookDelivery", T, (200, "WebhookDeliveryDetail"), ["deliveryId"], etag=True)

T = "Dashboard và báo cáo"
d("API-19-080", "getDashboardOverview", T, (200, "DashboardOverview"), [q("range", enum("TODAY", "7D", "30D", "CUSTOM"), default=None) if False else q("range", enum("TODAY", "7D", "30D", "CUSTOM")),
  *FROM_TO, q("providerId", UUID), q("serviceCode", R("Code")),
  q("fields", enum("ALL", "badges"), "`badges`: chỉ trả khối đếm cho huy hiệu menu, nhẹ, gọi mỗi 60 giây.")])
d("API-19-081", "getDashboardChannels", T, (200, "DashboardChannels"), [q("days", INT(minimum=1, maximum=30, default=30))])
d("API-19-082", "getReport", T, (200, "Report"), ["reportCode", q("periodType", enum("DAY", "MONTH", "QUARTER", "YEAR")), q("from", DATE), q("to", DATE),
  q("groupBy", STR(64))])
d("API-19-083", "createExportJob", T, (202, "Job"), body="ExportJobCreate", errs=["ERR-19-047", "ERR-19-048"], idem="opt",
  desc="Tối đa 3 tác vụ đồng thời mỗi người; 1 triệu dòng ≤ 10 phút (NFR-19-009); tệp giữ 7 ngày.")
d("API-19-084", "getExportJob", T, (200, "Job"), ["jobId"])

T = "Cấu hình, tệp, di trú"
d("API-19-085", "getPaymentConfig", T, (200, "ConfigView"))
d("API-19-086", "createConfigVersion", T, (201, "ConfigVersion"), body="ConfigVersionCreate", errs=["ERR-19-021"], ifm=True,
  desc="`If-Match` là ETag của phiên bản hiện hành; `effectiveFrom` ≥ hiện tại.")
d("API-19-087", "uploadFile", T, (201, "StoredFile"), errs=["ERR-19-021"], mp="FileUpload", idem="opt")
d("API-19-088", "getFile", T, (200, "StoredFile"), ["fileId"], desc="Quyền theo đối tượng sở hữu; đường tải ký có hạn 5 phút.")
d("API-19-089", "createMigrationRun", T, (202, "Job"), body="MigrationRunCreate", errs=["ERR-19-021"], idem="opt")
d("API-19-090", "listMigrationRuns", T, (200, "JobPage"), [qa("jobType", enum("MIGRATION_IMPORT", "MIGRATION_COMPARE")), "Cursor", "Limit"])

T = "Thanh toán"
d("API-19-101", "createPayment", T, (201, "Payment"), body="PaymentCreate", idem="req",
  errs=["ERR-19-005", "ERR-19-006", "ERR-19-007", "ERR-19-008", "ERR-19-009", "ERR-19-010", "ERR-19-011", "ERR-19-012", "ERR-19-013", "ERR-19-014",
        "ERR-19-015", "ERR-19-016", "ERR-19-017", "ERR-19-018", "ERR-19-019", "ERR-19-039"],
  desc="Kiểm tra theo thứ tự BR-19-004, dừng ở lỗi đầu tiên. Chế độ `SHADOW` không gọi NCC, trả `CREATED`, `paymentUrl = null`. Header `Location`; `Idempotent-Replayed: true` khi trả lại kết quả cũ.",
  ex={"serviceCode": "LPTB-OTO", "partnerOrderId": "H68.12-261121-0042", "amount": 2350000000, "description": "Lệ phí trước bạ hồ sơ H68.12-261121-0042",
      "returnUrl": "https://dichvucong.t68.gov.vn/thanh-toan/ket-qua", "payer": {"name": "Nguyễn Văn An", "phone": "+84912345678"},
      "expiryMinutes": 15, "metadata": {"hoSoId": "42"}})
d("API-19-102", "getPayment", T, (200, "Payment"), ["transactionCode"], desc="Đọc bản chính, nhất quán ngay.")
d("API-19-103", "listPaymentsByOrder", T, (200, "PaymentList"), [q("partnerOrderId", R("PartnerOrderId"))])
D["API-19-103"]["params"][0]["required"] = True
d("API-19-104", "cancelPayment", T, (200, "Payment"), ["transactionCode"], "PartnerCancel", ["ERR-19-005", "ERR-19-021"], idem="req")
T = "Hoàn tiền đối tác"
d("API-19-105", "createPartnerRefund", T, (201, "PartnerRefund"), body="PartnerRefundCreate", idem="req",
  errs=["ERR-19-005", "ERR-19-020", "ERR-19-029", "ERR-19-030", "ERR-19-031", "ERR-19-032", "ERR-19-039"])
d("API-19-106", "getPartnerRefund", T, (200, "PartnerRefund"), ["refundCode"])
T = "Đối soát đối tác"
d("API-19-107", "getPartnerReconReport", T, (200, "PartnerReconReport"), [q("date", DATE), "Cursor", "Limit"],
  desc="Chỉ giao dịch của đối tác gọi; `provisional = true` khi phiên chưa `CLOSED`.")
D["API-19-107"]["params"][0]["required"] = True
d("API-19-108", "listPartnerServices", T, (200, "PartnerServiceList"))
d("API-19-109", "listNotifications", T, (200, "NotificationPage"), [q("after", STR(64), "`id` CloudEvent cuối đã đọc; bỏ trống lấy từ 7 ngày trước."),
  q("limit", INT(minimum=1, maximum=200, default=50))], desc="Dự phòng khi lỡ webhook; giữ 7 ngày (A-19-10).")
T = "Tương thích hệ cũ"
d("API-19-110", "legacyCompat", T, (200, "LegacyCompatResponse"), ["operation"], "LegacyCompatRequest", ["ERR-19-005"], idem="opt",
  desc="Ưu tiên C, đợt Sau (FR-19-067). Mặt nạ cho HTTT chưa sửa được mã; `Idempotency-Key` sinh từ mã đơn hàng nếu thiếu.")

T = "Callback PayGov"
CB_DESC = ("**Giả định – cần đối chiếu Tài liệu kỹ thuật kết nối của VPCP (OQ-19-01…07).** Thứ tự: tra `callback_route` theo `sha256(connectionKey)` → "
           "allowlist IP, mTLS → ghi nguyên văn `callback_inbox` → xác minh chữ ký (`ACTIVE`/`NEXT`), dấu thời gian ±5 phút, nonce → trả xác nhận → xử lý bất đồng bộ.")
d("API-19-201", "receivePaygovIpn", T, (200, "CallbackAck"), ["connectionKey"], "PaygovIpn", ["ERR-19-024", "ERR-19-025", "ERR-19-026", "ERR-19-027", "ERR-19-028"], desc=CB_DESC)
d("API-19-202", "paygovReturn", T, (200, "HTML"), ["connectionKey", q("orderId", STR(32)), q("responseCode", STR(8)), q("signature", STR(1024))],
  errs=["ERR-19-027"], desc="Người nộp quay về: xác minh chữ ký tham số, trả trang UI-19-28 hiển thị trạng thái **theo CSDL** (không theo tham số); "
  "trang tự chuyển về `returnUrl` đã lưu của giao dịch kèm `transactionCode`, `status`, `ts`, `sig` sau 5 giây. "
  "Không đổi trạng thái giao dịch (BR-19-014, FR-19-025). Sai chữ ký: 400, trang không chuyển tới đối tác.")
d("API-19-205", "getPublicResultStatus", T, (200, "PublicResultStatus"), [q("t", STR(64), "Mã phiên trang kết quả do API-19-202 cấp."), q("s", STR(128), "Chữ ký phiên trang, hạn 2 phút.")],
  errs=["ERR-19-020"], desc="Trang UI-19-28 thăm dò trạng thái khi giao dịch còn `CREATED`, `PENDING` (mỗi 3 giây, tối đa 20 giây). Chỉ trả trạng thái rút gọn, không có dữ liệu cá nhân; giới hạn tốc độ theo IP ở APISIX.")
d("API-19-203", "receivePaygovRefundIpn", T, (200, "CallbackAck"), ["connectionKey"], "PaygovIpn", ["ERR-19-024", "ERR-19-025", "ERR-19-026", "ERR-19-027", "ERR-19-028"], desc=CB_DESC)
d("API-19-204", "receivePaygovReconNotice", T, (200, "CallbackAck"), ["connectionKey"], "PaygovIpn", ["ERR-19-024", "ERR-19-025", "ERR-19-027"], desc=CB_DESC)

# ------------------------------------------------------------------ dựng tài liệu
RESP_COMPONENTS = {}
def problem(codes):
    st = ERRS[codes[0]][0]
    lines = "; ".join(f"`{c}` {ERRS[c][1]}" for c in codes)
    ex = {c: {"summary": ERRS[c][1], "value": {"type": f"/problems/{c}", "title": ERRS[c][1], "status": ERRS[c][0], "code": c,
              "detail": ERRS[c][2].split(";")[0][:200], "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}} for c in codes}
    return {"description": lines, "content": {"application/problem+json": {"schema": R("ProblemDetails"), "examples": ex}}}

def group(api):
    n = int(api["aid"][-3:])
    return "admin" if n < 100 else ("partner" if n < 200 else "callback")

def build_op(e, det):
    g = group(e)
    op = {"tags": [det["tag"]], "operationId": det["op"], "summary": e["summary"], "x-datahub-id": e["aid"], "x-datahub-fr": expand_fr(e["fr"])}
    if g != "callback":
        op["x-datahub-permission"] = e["perm"]
    if det["desc"]: op["description"] = det["desc"]
    params = []
    for p in det["params"]:
        params.append({"$ref": f"#/components/parameters/{p}"} if isinstance(p, str) else p)
    if det["ifm"]: params.append({"$ref": "#/components/parameters/IfMatch"})
    if det["idem"] == "req": params.append({"$ref": "#/components/parameters/IdempotencyKey"})
    elif det["idem"] == "opt": params.append({"$ref": "#/components/parameters/IdempotencyKeyOpt"})
    params.append({"$ref": "#/components/parameters/Traceparent"})
    op["parameters"] = params
    if det["body"]:
        c = {"schema": R(det["body"])}
        if det["ex"]: c["example"] = det["ex"]
        ctype = "application/json"
        op["requestBody"] = {"required": True, "content": {ctype: c}}
    elif det["mp"]:
        op["requestBody"] = {"required": True, "content": {"multipart/form-data": {"schema": R(det["mp"])}}}
    code, sch = det["ok"]
    okr = {"description": {200: "Thành công.", 201: "Đã tạo.", 202: "Đã tiếp nhận, xử lý bất đồng bộ.", 204: "Đã xóa.", 302: "Chuyển hướng tới `returnUrl`."}[code]}
    if sch == "HTML": okr["content"] = {"text/html": {"schema": STR(description="Trang UI-19-28 (D03-06-PH19 §34) do dh-payment vai trò callback dựng sẵn.")}}
    elif sch: okr["content"] = {"application/json": {"schema": R(sch)}}
    hdr = {}
    if det["etag"]: hdr["ETag"] = {"schema": STR(), "description": "`W/\"{version}\"`"}
    if code in (201, 202) and g != "callback": hdr["Location"] = {"schema": STR()}
    if code == 302: hdr["Location"] = {"schema": STR(), "description": "`returnUrl` của đối tác kèm `transactionCode`, `status`."}
    if det["idem"]: hdr["Idempotent-Replayed"] = {"schema": BOOL, "description": "`true` khi trả lại phản hồi đã lưu."}
    if hdr: okr["headers"] = hdr
    resps = {str(code): okr}
    codes = list(det["errs"])
    if g == "callback":
        pass
    else:
        if det["body"] or det["mp"] or any(isinstance(p, dict) and p.get("in") == "query" for p in det["params"]): codes.append("ERR-19-001")
        if any(isinstance(p, str) and p in PARAMS and PARAMS[p].get("in") == "path" for p in det["params"]): codes.append("ERR-19-020")
        if det["ifm"]: codes.append("ERR-19-045")
        if g == "partner" and det["idem"] == "req": codes += ["ERR-19-002", "ERR-19-003", "ERR-19-004"]
        codes += ["ERR-19-046", "ERR-19-048", "ERR-19-049"]
        if e["method"] != "get": codes.append("ERR-19-050")
        codes.append("ERR-19-099")
    by = {}
    for c in dict.fromkeys(codes):
        by.setdefault(ERRS[c][0], []).append(c)
    for st, cs in sorted(by.items()):
        if str(st) == str(code):   # ERR-19-028 trả 200 như xác nhận
            resps[str(code)]["description"] += " Kể cả khi cách ly (" + ", ".join(f"`{c}`" for c in cs) + ", chỉ ghi nội bộ)."
            continue
        name = "Err" + "_".join(c[-3:] for c in cs)
        RESP_COMPONENTS[name] = problem(cs)
        resps[str(st)] = {"$ref": f"#/components/responses/{name}"}
    if g != "callback": resps["401"] = {"description": "Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19)."}
    op["responses"] = dict(sorted(resps.items()))
    return op

INFO = {
  "admin": ("Datahub · PH-19 Thanh toán · API quản trị", "/api/payment/v1",
            "API quản trị của `dh-payment` (vai trò `api`) cho `dh-console`: NCC, dịch vụ, đối tác, phê duyệt bốn mắt, giao dịch, IPN, hoàn tiền, đối soát, chênh lệch, nhật ký, webhook, dashboard, báo cáo, cấu hình, di trú. "
            "Token OIDC người dùng (Authorization Code + PKCE qua BFF), quyền `PERM-19-*` kiểm ở OPA, dữ liệu giới hạn trong tenant của token (RLS).",
            [{"oauth2User": []}]),
  "partner": ("Datahub · PH-19 Thanh toán · API đối tác", "/api/payment-partner/v1",
              "API cho HTTT đối tác thu phí, lệ phí qua PH-19 và nhận kết quả. Token máy-máy (client credentials với mTLS hoặc `private_key_jwt`, NFR-19-019) vai trò `ROLE-PARTNER_SYSTEM`; "
              "mọi truy vấn chỉ thấy dữ liệu của chính đối tác. Mọi `POST` bắt buộc `Idempotency-Key`. Kết quả thanh toán đến qua **webhook** ký HMAC (mục `webhooks`), dự phòng kéo bằng API-19-109.",
              [{"oauth2Client": []}]),
  "callback": ("Datahub · PH-19 Thanh toán · API callback nhà cung cấp", "/api/payment-callback/v1",
               "Đầu nhận cho PayGov gọi về. Không token; xác minh bằng allowlist IP tại APISIX, mTLS nếu PayGov dùng, chữ ký nội dung, dấu thời gian, nonce (NFR-19-020, ADR-045). "
               "**Tên trường, thuật toán ký, mã phản hồi là giả định – cần đối chiếu Tài liệu kỹ thuật kết nối Nền tảng thanh toán của Cổng DVCQG do VPCP cấp (OQ-19-01…07).**",
               []),
}
WEBHOOK_EVENTS = [("transaction.succeeded", "EVT-19-07"), ("transaction.failed", "EVT-19-08"), ("transaction.cancelled", "EVT-19-09"),
                  ("transaction.expired", "EVT-19-10"), ("refund.decided", "EVT-19-12"), ("refund.succeeded", "EVT-19-13"),
                  ("refund.failed", "EVT-19-14"), ("reconciliation.closed", "EVT-19-16")]

def refs(node, acc):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "$ref" and v.startswith("#/components/schemas/"): acc.add(v.split("/")[-1])
            else: refs(v, acc)
    elif isinstance(node, list):
        for v in node: refs(v, acc)

def closure(names):
    seen, todo = set(), list(names)
    while todo:
        n = todo.pop()
        if n in seen: continue
        seen.add(n); acc = set(); refs(SCHEMAS[n], acc); todo += list(acc - seen)
    return seen

def build(g):
    title, base, desc, sec = INFO[g]
    RESP_COMPONENTS.clear()
    paths = {}
    eps = [e for e in ENDPOINTS if group(e) == g]
    for e in eps:
        det = D[e["aid"]]
        path = e["path"]
        if g != "admin": path = path.replace(base, "") or "/"
        path = path.split("?")[0]
        paths.setdefault(path, {})[e["method"]] = build_op(e, det)
    doc = {"openapi": "3.1.0",
           "info": {"title": title, "version": "1.0.0-draft", "summary": desc.split(". ")[0] + ".",
                    "description": desc + "\n\nQuy ước chung, bảng mã lỗi: D03-04-PH19 §1, §6. Mọi tên miền, dữ liệu là giả lập. Tệp sinh bởi `tools/gen_openapi.py`; không sửa tay.",
                    "contact": {"name": "Nhóm phân hệ PH-19"},
                    "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
                    "x-datahub-document": "D03-04-PH19", "x-datahub-phase": "PH-19"},
           "servers": [{"url": f"https://{{host}}{base}", "description": "Qua APISIX — giả lập",
                        "variables": {"host": {"default": {"admin": "console.t68.datahub.example.vn", "partner": "api.t68.datahub.example.vn",
                                                           "callback": "pay-cb.datahub.example.vn"}[g]}}},
                       {"url": f"http://localhost:8089{base}", "description": "Phát triển cục bộ"}],
           "security": sec,
           "tags": [{"name": t} for t in dict.fromkeys(D[e["aid"]]["tag"] for e in eps)],
           "paths": paths}
    if g == "partner":
        wh = {}
        for et, evt in WEBHOOK_EVENTS:
            wh[et] = {"post": {"summary": f"Webhook `{et}` ({evt})", "operationId": "webhook_" + et.replace(".", "_"),
                "x-datahub-id": evt, "description": "Datahub gọi đầu nhận của đối tác. Kiểm `X-Datahub-Signature` = `t={unix},v1={hex(HMAC_SHA256(secret, id + \".\" + t + \".\" + body))}` (có thể hai `v1` khi xoay bí mật), lệch thời gian ≤ 5 phút, bỏ trùng theo `Webhook-Id`, sắp theo `sequence` (ADR-044, BR-19-021). Trả 2xx trong 10 giây.",
                "parameters": [{"name": "Webhook-Id", "in": "header", "required": True, "schema": UUID},
                               {"name": "Webhook-Timestamp", "in": "header", "required": True, "schema": INT()},
                               {"name": "X-Datahub-Signature", "in": "header", "required": True, "schema": STR(300, pattern="^t=[0-9]+(,v1=[0-9a-f]{64})+$")}],
                "requestBody": {"required": True, "content": {"application/cloudevents+json": {"schema": R("CloudEvent")}}},
                "responses": {"2XX": {"description": "Đã nhận."}, "default": {"description": "Lỗi: 408, 425, 429, 5xx thử lại theo `19.webhook.retry-schedule`; 4xx khác dừng (EXHAUSTED)."}}}}
        doc["webhooks"] = wh
    used = set(); refs(doc, used); used |= {"ProblemDetails"}
    comps = {"parameters": {}, "responses": dict(sorted(RESP_COMPONENTS.items())), "schemas": {}}
    prefs = set()
    def pr(node):
        if isinstance(node, dict):
            for k, v in node.items():
                if k == "$ref" and v.startswith("#/components/parameters/"): prefs.add(v.split("/")[-1])
                else: pr(v)
        elif isinstance(node, list):
            for v in node: pr(v)
    pr(doc)
    comps["parameters"] = {k: PARAMS[k] for k in PARAMS if k in prefs}
    for p in comps["parameters"].values(): refs(p, used)
    comps["schemas"] = {k: copy.deepcopy(SCHEMAS[k]) for k in sorted(closure(used))}
    if g == "admin":
        comps["securitySchemes"] = {"oauth2User": {"type": "oauth2", "description": "Keycloak realm `dh-{tenant}`; vai trò ánh xạ `PERM-19-*` (khung §13, D02-08).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}}}
    elif g == "partner":
        comps["securitySchemes"] = {"oauth2Client": {"type": "oauth2", "description": "Client credentials, xác thực client bằng mTLS (RFC 8705) hoặc `private_key_jwt`; token ≤ 5 phút, ràng buộc chứng thư.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}}}
    doc["components"] = comps
    return doc

OUT = {"admin": "openapi-payment-admin.yaml", "partner": "openapi-payment-partner.yaml", "callback": "openapi-payment-callback.yaml"}
if __name__ == "__main__":
    missing = [e["aid"] for e in ENDPOINTS if e["aid"] not in D]
    extra = sorted(set(D) - {e["aid"] for e in ENDPOINTS})
    assert not missing and not extra, (missing, extra)
    for g, fn in OUT.items():
        doc = build(g)
        with open(os.path.join(ROOT, fn), "w", encoding="utf-8") as f:
            f.write(f"# D03-04-PH19 · {INFO[g][0]}. SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
            yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
        nops = sum(len(v) for v in doc["paths"].values())
        print(f"{fn}: {nops} operation, {len(doc['components']['schemas'])} lược đồ")
