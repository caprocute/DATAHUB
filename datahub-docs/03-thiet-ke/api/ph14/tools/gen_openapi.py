#!/usr/bin/env python3
"""Sinh ph14/openapi-national.yaml từ spec.OPS và schemas14.SCHEMAS.

Chạy: python3 tools/gen_openapi.py   (từ thư mục api/ph14). Không sửa tay YAML sinh ra; sửa spec.py, schemas14.py hoặc tệp này.
"""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from schemas14 import SCHEMAS, R, s, obj, arr, enum, STR, INT, BOOL, TS, UUID

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = lambda n: {"$ref": f"#/components/parameters/{n}"}
RESP = lambda n: {"$ref": f"#/components/responses/{n}"}
Q = lambda name, schema, desc=None: {k: v for k, v in {"name": name, "in": "query", "schema": schema, "description": desc}.items() if v is not None}
QA = lambda name, schema: {"name": name, "in": "query", "schema": arr(schema), "style": "form", "explode": False}
PG = ["Page", "Size"]
ENVQ = Q("environment", enum("TEST", "STAGING", "PROD"))

PARAMS = {
  "PlatformCodePath": {"name": "platformCode", "in": "path", "required": True, "schema": R("PlatformCode")},
  "ServiceCodePath": {"name": "serviceCode", "in": "path", "required": True, "schema": R("ServiceCode")},
  "CertCodePath": {"name": "certCode", "in": "path", "required": True, "schema": R("CertCode")},
  "EndpointCodePath": {"name": "endpointCode", "in": "path", "required": True, "schema": R("EndpointCode")},
  "SystemCodePath": {"name": "systemCode", "in": "path", "required": True, "schema": R("SystemCode")},
  "RunIdPath": {"name": "runId", "in": "path", "required": True, "schema": UUID},
  "RuleIdPath": {"name": "ruleId", "in": "path", "required": True, "schema": UUID},
  "IncidentIdPath": {"name": "incidentId", "in": "path", "required": True, "schema": UUID},
  "AlertIdPath": {"name": "alertId", "in": "path", "required": True, "schema": UUID},
  "RequestIdPath": {"name": "requestId", "in": "path", "required": True, "schema": UUID},
  "ProposalIdPath": {"name": "proposalId", "in": "path", "required": True, "schema": UUID},
  "SpecVersionPath": {"name": "specVersion", "in": "path", "required": True, "schema": STR(16, pattern="^[0-9]+\\.[0-9]+(\\.[0-9]+)?$")},
  "TransactionCodePath": {"name": "transactionCode", "in": "path", "required": True, "schema": STR(64)},
  "DatasetCodePath": {"name": "datasetCode", "in": "path", "required": True, "schema": STR(63)},
  "RemoteCodePath": {"name": "remoteCode", "in": "path", "required": True, "schema": STR(64)},
  "Page": {"name": "page", "in": "query", "schema": INT(minimum=1, default=1)},
  "Size": {"name": "size", "in": "query", "schema": INT(minimum=1, maximum=100, default=25), "description": "Vượt 100 trả ERR-14-003 kèm `max`."},
  "IfMatch": {"name": "If-Match", "in": "header", "required": True, "schema": STR(128), "description": "ETag hiện tại; lệch trả ERR-14-004 (409) kèm `currentEtag`."},
  "IfNoneMatch": {"name": "If-None-Match", "in": "header", "schema": STR(128)},
  "IdempotencyKey": {"name": "Idempotency-Key", "in": "header", "required": True, "schema": STR(128, minLength=16), "description": "Lưu 24 giờ; cùng khóa khác thân trả ERR-14-116."},
  "IdempotencyKeyOpt": {"name": "Idempotency-Key", "in": "header", "schema": STR(128, minLength=16), "description": "Bắt buộc khi dịch vụ có `operationType = WRITE` (thiếu: ERR-14-003); cùng khóa khác nội dung trả ERR-14-116."},
  "Traceparent": {"name": "traceparent", "in": "header", "schema": STR(55), "description": "W3C Trace Context."},
  "AcceptLanguage": {"name": "Accept-Language", "in": "header", "schema": enum("vi", "en")},
  "AcceptStale": {"name": "X-DH-Accept-Stale", "in": "header", "schema": BOOL, "description": "`true`: chấp nhận dữ liệu đệm quá hạn khi nền tảng lỗi (FR-14-037)."},
  "ParallelRunHeader": {"name": "X-DH-Parallel-Run", "in": "header", "schema": UUID, "description": "Gắn lượt gọi vào phiên chạy song song (FR-14-055)."},
  "OnBehalfOf": {"name": "X-DH-On-Behalf-Of", "in": "header", "schema": STR(64), "description": "Mã HTTT gốc khi luồng PH-04 gọi thay HTTT; cổng đối chiếu với đăng ký của luồng."},
  "ServiceHeader": {"name": "X-DH-Service", "in": "header", "schema": R("ServiceCode"), "description": "APISIX gắn khi viết lại tuyến cung cấp lại (FR-14-009)."},
  "OperationHeader": {"name": "X-DH-Operation", "in": "header", "schema": STR(41), "description": "Thao tác của bộ điều hợp khi dịch vụ có nhiều thao tác."},
  "TenantHeader": {"name": "X-DH-Tenant", "in": "header", "schema": STR(16), "description": "APISIX gắn từ điểm cuối (BR-14-027); lệch claim: 403 và sự kiện an ninh."},
  "ServiceCodeHeader": {"name": "Service-code", "in": "header", "schema": STR(64), "description": "Mã dịch vụ quốc gia do trung ương gửi."},
}
PATH_PARAM = {"platformCode": "PlatformCodePath", "serviceCode": "ServiceCodePath", "certCode": "CertCodePath", "endpointCode": "EndpointCodePath",
    "systemCode": "SystemCodePath", "runId": "RunIdPath", "ruleId": "RuleIdPath", "incidentId": "IncidentIdPath", "alertId": "AlertIdPath",
    "requestId": "RequestIdPath", "proposalId": "ProposalIdPath", "specVersion": "SpecVersionPath", "transactionCode": "TransactionCodePath",
    "datasetCode": "DatasetCodePath", "remoteCode": "RemoteCodePath"}

HTTP_RESP = {  # HTTP → (tên response dùng chung, mô tả)
  "400": ("BadRequest", "Dữ liệu không hợp lệ (ERR-14-003, 121, theo trường trong `errors`)."),
  "401": ("Unauthorized", "Thiếu token hoặc token hết hạn; chứng thư mTLS sai (ERR-14-120)."),
  "403": ("Forbidden", "Không đủ quyền, sai tenant, bốn mắt (ERR-14-007), chưa xác thực lại (ERR-14-030), mục đích hoặc nguồn bị chặn (ERR-14-106, 119, 126)."),
  "404": ("NotFound", "Không tìm thấy hoặc thuộc tenant khác (ERR-14-001, 031, 129, 102)."),
  "409": ("Conflict", "Trạng thái không cho phép, trùng mã, `ETag` lệch, chạy trùng (ERR-14-002, 004, 006, 010, 013, 023, 026, 033, 116, 122, 130)."),
  "422": ("Unprocessable", "Lỗi nghiệp vụ theo dữ liệu; mã cụ thể trong `code`."),
  "429": ("TooManyRequests", "Vượt giới hạn tần suất hoặc hạn mức (ERR-14-029, 104, 123); kèm `retryAfterSeconds` hoặc `resetAt`."),
  "500": ("InternalError", "Lỗi nội bộ (ERR-14-127), kèm `traceId`; `detail` chung chung."),
  "502": ("BadGateway", "Nền tảng quốc gia hoặc phân hệ phụ thuộc lỗi (ERR-14-027, 101, 109…111, 114, 124, 128, 131)."),
  "503": ("ServiceUnavailable", "Phụ thuộc chưa sẵn sàng hoặc dịch vụ tạm ngừng (ERR-14-035, 103, 112, 113, 117, 118, 132, 133); có thể kèm `Retry-After`."),
  "504": ("GatewayTimeout", "Quá hạn chờ phản hồi của nền tảng (ERR-14-115)."),
}
RESPONSES = {n: {"description": d, "content": {"application/problem+json": {"schema": R("ProblemDetails"),
    "example": {"type": f"https://datahub.gov.vn/errors/ERR-14-{ex}", "title": d.split("(")[0].strip().rstrip(";,."), "status": int(st), "code": f"ERR-14-{ex}", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}}}}
    for st, (n, d), ex in [(k, v, {"400": "003", "401": "003", "403": "007", "404": "001", "409": "004", "422": "016", "429": "104", "500": "127", "502": "101", "503": "103", "504": "115"}[k]) for k, v in HTTP_RESP.items()]}
RESPONSES["Unauthorized"]["content"]["application/problem+json"]["example"] = {"type": "about:blank", "title": "Chưa xác thực", "status": 401, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}
RESPONSES["NotModified"] = {"description": "Không đổi (If-None-Match khớp)."}
ERR_HTTP = {c: [x.strip() for x in h.split(",")] for c, h, _ in spec.ERRS}

IFM = {"004", "005", "006", "007", "008", "009", "013", "016", "017", "020", "022", "026", "027", "032", "033", "034", "038", "045", "050", "052", "068", "071", "090", "092"}
SVC_ALSO = {"054": "national.sync.trigger", "056": "national.sync.trigger", "058": "national.health-read", "060": "national.health-read", "073": "national.health-read"}
SCOPES = {"national.invoke": "Gọi dịch vụ quốc gia; thực tế dùng `national.invoke.{nhóm}` (vd `national.invoke.lltp`)",
          "national.runtime-config": "Đọc ảnh chụp cấu hình không bí mật (`dh-runtime`)",
          "national.health-read": "Đọc chỉ số sức khỏe (PH-13)",
          "national.catalog.read": "Đọc danh mục dùng chung quốc gia (PH-07)",
          "national.catalog.propose": "Gửi đề xuất bổ sung danh mục (PH-07)",
          "national.sync.trigger": "Kích hoạt đồng bộ (PH-02, PH-06)",
          "national.parallel-observe": "Gửi quan sát chạy song song (luồng PH-04; scope đề xuất, Q14-55)"}
MULTI_RESP = {"064": "ZIP", "066": "CSV"}

# mã → (operationId, thân yêu cầu, lược đồ phản hồi, mã lỗi riêng, mô tả, tham số thêm)
X = {
  "001": ("listPlatforms", None, "PlatformList", [], "Kèm trạng thái, mức sức khỏe và `allowedActions`.", [QA("state", R("PlatformState")), QA("platformType", R("PlatformType")), Q("scope", R("PlatformScope")), Q("q", STR(100, minLength=2)), *PG]),
  "002": ("createPlatform", "PlatformCreate", "PlatformDetail", ["002", "005"], "Tạo ở `DRAFT`. Kết nối PH-05 phải là loại `oauth2-client` hoặc `mtls-client` phù hợp `authMode` (ERR-14-005). `scope = COMMON` chỉ PA.", []),
  "003": ("getPlatform", None, "PlatformDetail", [], "Trả `ETag`. Không bao giờ trả thông tin xác thực.", []),
  "004": ("updatePlatform", "PlatformUpdate", "PlatformDetail", ["004", "005"], "Nền tảng `ACTIVE` đổi kết nối thì quay về `TESTED` và phải kiểm tra lại.", []),
  "005": ("suspendPlatform", "StateChangeRequest", "PlatformDetail", ["004"], "Cổng từ chối lượt mới trong 30 giây, lượt đang chạy kết thúc (BR-14-032); phát EVT-14-01.", []),
  "006": ("resumePlatform", "StateChangeRequest", "PlatformDetail", ["004"], "Phát EVT-14-01.", []),
  "007": ("retirePlatform", "StateChangeRequest", "PlatformDetail", ["004"], "Trạng thái cuối, mã không dùng lại. Còn dịch vụ `ACTIVE` trả ERR-14-004.", []),
  "008": ("requestPlatformActivation", "ActivationRequest", "PlatformDetail", ["004", "006", "008", "037"], "Yêu cầu có kiểm tra kết nối đạt trong 24 giờ (ERR-14-008) và, nếu nền tảng có dịch vụ cần ký, có chứng thư đang dùng đúng mục đích (ERR-14-037). Môi trường thật tạo việc cho người duyệt.", []),
  "009": ("decidePlatformActivation", "ApprovalDecision", "PlatformDetail", ["004", "007"], "Bốn mắt: người duyệt khác người đề nghị và người sửa gần nhất (ERR-14-007). Duyệt thì `ACTIVE`, phát EVT-14-01.", []),
  "010": ("listServices", None, "ServiceList", [], "Kèm `facets`.", [Q("q", STR(100, minLength=2)), Q("platformCode", R("PlatformCode")), QA("group", R("ServiceGroup")), QA("state", R("ServiceState")), QA("reconcileLabel", R("ReconcileLabel")), Q("operationType", R("OperationType")), Q("exposed", BOOL), *PG]),
  "011": ("createService", "ServiceCreate", "ServiceDetail", ["002", "038"], "Tạo ở `DRAFT`. Mức `SENSITIVE` hoặc `WRITE` mà bật đệm trả ERR-14-038. Chuyển `ACTIVE` khi có hợp đồng, đặc tả `ACTIVE` và nền tảng `ACTIVE` (ERR-14-009).", []),
  "012": ("getService", None, "ServiceDetail", [], "Trả hợp đồng, nhãn đối chiếu, trạng thái cung cấp lại. Có `ETag`.", []),
  "013": ("updateService", "ServiceUpdate", "ServiceDetail", ["004", "009", "016", "036", "038"], "Giảm kiểm soát (bỏ mục đích, tăng thời hạn đệm, bật đệm) cần `basis` và người duyệt (ERR-14-016, BR-14-022). Phát EVT-14-02.", []),
  "014": ("startServiceReconciliation", "ReconcileRequest", "ReconcileRun", ["026", "027", "131"], "Chạy ở `worker`, tải danh mục hiện hành của NDXP và so sánh; mỗi nền tảng một phiên cùng lúc (ERR-14-026). Theo dõi bằng API-14-015.", []),
  "015": ("getServiceReconciliation", None, "ReconcileRun", [], "Mỗi mục có nhãn `STILL`, `SPEC_CHANGED`, `DISCONTINUED`, kèm danh sách thay đổi.", []),
  "016": ("applyServiceReconciliation", "ReconcileApply", "ReconcileRun", ["004", "012"], "Áp nhãn, tạo bản nháp đặc tả. Thay đổi phá vỡ chưa `acknowledgeBreaking` trả ERR-14-012. Phát EVT-14-02.", []),
  "017": ("setServiceLabel", "SetLabelRequest", "ServiceDetail", ["004"], "Đặt nhãn bằng tay khi đối chiếu tự động không dùng được; ghi lý do và kiểm toán. Nhãn `DISCONTINUED` chuyển dịch vụ sang `RETIRED` sau duyệt.", []),
  "018": ("listServiceSpecs", None, "ServiceSpecList", [], "Mới nhất trước; mỗi phiên bản có `breaking`, `diffSummary`.", []),
  "019": ("createServiceSpec", "SpecCreate", "ServiceSpec", ["010", "011", "131"], "Phiên bản cùng số cùng nội dung trả lại bản đã có (lũy đẳng); cùng số khác nội dung ERR-14-010. Đặc tả vượt giới hạn hoặc không an toàn (DTD, thực thể ngoài) ERR-14-011.", []),
  "020": ("activateServiceSpec", "SpecActivate", "ServiceSpec", ["004", "012"], "Phiên bản `ACTIVE` bất biến; phiên bản trước thành `SUPERSEDED`. Thay đổi phá vỡ cần `acknowledgeBreaking` và tăng số chính hợp đồng.", []),
  "021": ("getServiceExposure", None, "Exposure", [], None, []),
  "022": ("putServiceExposure", "ExposureUpdate", "Exposure", ["004", "025"], "Chỉ dịch vụ `ACTIVE`, hướng `OUTBOUND`, đường dẫn không xung đột (ERR-14-025). Mỗi dịch vụ tối đa một cung cấp lại.", []),
  "023": ("publishServiceExposure", None, "JobAccepted", ["004", "025", "027"], "Lưu `requestId` rồi tạo API nháp ở PH-02 với chính `requestId` làm khóa chống trùng; PH-02 lỗi để lại `FAILED_CREATE`. Phát EVT-14-14.", []),
  "024": ("listRoutingRules", None, "RoutingRuleList", [], None, [QA("state", enum("DRAFT", "PENDING_APPROVAL", "ACTIVE", "DISABLED")), Q("group", R("ServiceGroup")), Q("serviceCode", R("ServiceCode")), *PG]),
  "025": ("createRoutingRule", "RoutingRuleCreate", "RoutingRule", ["013", "014", "015", "016"], "Tạo ở `PENDING_APPROVAL` khi gửi duyệt, hoặc `DRAFT`. Dự phòng chỉ cho thao tác `READ` cùng nhóm (ERR-14-015). Trùng điều kiện và ưu tiên ERR-14-013.", []),
  "026": ("updateRoutingRule", "RoutingRuleUpdate", "RoutingRule", ["004", "013", "015", "016"], "Sửa luật `ACTIVE` tạo bản chờ duyệt, luật cũ vẫn chạy tới khi duyệt.", []),
  "027": ("decideRoutingRule", "ApprovalDecision", "RoutingRule", ["004", "007"], "Duyệt thì `ACTIVE`, phát EVT-14-03; cổng nạp trong 30 giây.", []),
  "028": ("simulateRouting", "SimulateRequest", "SimulateResult", ["105"], "Không gọi ra quốc gia, không tiêu hạn mức, không ghi giao dịch. Luật trùng hiện `conflict = true`.", []),
  "029": ("listCertificates", None, "CertificateList", [], "Không trả khóa; trả `daysLeft`.", [QA("state", R("CertState")), Q("purpose", R("CertPurpose")), Q("platformCode", R("PlatformCode")), *PG]),
  "030": ("uploadCertificate", "CertificateUpload", "CertificateDetail", ["002", "019", "020", "021", "035"], "Cần xác thực nhiều yếu tố (SEC-23). Kiểm chuỗi tin cậy (ERR-14-019), ký thử qua `worker` để khớp khóa ở OpenBao (ERR-14-020, Q14-25), còn hiệu lực (ERR-14-021). Trạng thái `UPLOADED`.", []),
  "031": ("getCertificate", None, "CertificateDetail", [], "Không trả khóa; `keyRef` chỉ là tham chiếu.", []),
  "032": ("requestCertificateActivation", "CertActivationRequest", "CertificateDetail", ["004", "006", "021"], "Cần xác thực nhiều yếu tố. Chuyển `PENDING_ACTIVATION` và tạo việc cho người duyệt.", []),
  "033": ("decideCertificateActivation", "ApprovalDecision", "CertificateDetail", ["004", "007", "021"], "Bốn mắt và xác thực nhiều yếu tố. Duyệt thì `ACTIVE`; chứng thư cũ cùng mục đích sang `SUPERSEDED` sau `14.cert.overlap-hours`. Phát EVT-14-04.", []),
  "034": ("revokeCertificate", "RevokeRequest", "CertificateDetail", ["004"], "Chứng thư `REVOKED` không ký được; hết chứng thư cùng mục đích thì nền tảng bị chặn ký (ERR-14-113). Phát EVT-14-04.", []),
  "092": ("deleteCertificate", None, None, ["004", "022"], "Chỉ xóa chứng thư `UPLOADED` chưa từng `ACTIVE`; còn giao dịch trong thời hạn lưu cần xác minh trả ERR-14-022. Chứng thư đã dùng chỉ thu hồi (API-14-034), không xóa (BR-14-019).", []),
  "035": ("getTrustStore", None, "TrustStore", [], "Neo tin cậy và CRL; CRL quá `14.crl.max-age-days` hiện `STALE`.", []),
  "036": ("refreshTrustStore", None, "JobAccepted", ["026", "027", "131"], "Tải chuỗi tin cậy và CRL ở `worker`. Thay đổi neo tin cậy cần duyệt bốn mắt (BR-14-022).", []),
  "037": ("listSignatureIncidents", None, "SignatureIncidentList", [], None, [QA("state", enum("OPEN", "ACKNOWLEDGED", "RESOLVED")), Q("platformCode", R("PlatformCode")), *PG]),
  "038": ("transitionSignatureIncident", "IncidentTransition", "SignatureIncident", ["004"], "`RELEASE_HOLD` giải trừ `securityHold` của nền tảng; chỉ SO (`PERM-14-operate` và vai trò SO).", []),
  "039": ("rotatePlatformCredentials", "RotateCredentialRequest", "RotationStatus", ["004", "034", "035"], "Điều phối chuyển tiếp ở cổng; bí mật mới ghi ở PH-05. Kiểm tra token bằng thông tin mới trước khi chuyển; thất bại thì hủy (FR-14-025).", []),
  "040": ("testPlatformToken", None, "TokenTestResult", ["004", "029", "034", "035"], "Lấy token ở `worker`, không lưu. Tối đa `14.test.max-per-hour` lần mỗi giờ (ERR-14-029).", [ENVQ]),
  "041": ("listQuotas", None, "QuotaList", [], None, [Q("platformCode", R("PlatformCode")), Q("serviceCode", R("ServiceCode"))]),
  "042": ("createQuota", "QuotaCreate", "Quota", ["016", "017"], "Môi trường thật tạo yêu cầu duyệt (hộp \"Việc của tôi\"). Thiếu căn cứ văn bản ERR-14-016 (BR-14-011). Phát EVT-14-08.", []),
  "043": ("getQuotaUsage", None, "QuotaUsage", [], "Đọc từ bộ đếm ở Valkey; ngưỡng cảnh báo theo `14.quota.warn-levels`.", [Q("platformCode", R("PlatformCode"))]),
  "044": ("listQuotaAllocations", None, "AllocationList", [], None, [Q("serviceCode", R("ServiceCode")), Q("period", enum("HOUR", "DAY", "MONTH"))]),
  "045": ("putQuotaAllocation", "AllocationPut", "Allocation", ["004", "017", "018"], "Tổng phân bổ cho mọi HTTT không vượt hạn mức (ERR-14-018). Dịch vụ `ESSENTIAL` được vượt trần HTTT nếu không vượt hạn mức toàn cục (Q14-24).", []),
  "046": ("getCacheStats", None, "CacheStats", [], None, [Q("window", enum("1h", "24h", "7d")), Q("serviceCode", R("ServiceCode"))]),
  "047": ("invalidateCache", "CacheInvalidateRequest", "CacheInvalidateResult", ["004"], "Phát EVT-14-09. Có `subjectKeyHash` chỉ vô hiệu một đối tượng.", []),
  "048": ("listInboundEndpoints", None, "InboundEndpointList", [], None, [QA("state", enum("DRAFT", "PENDING_CONFIRM", "ACTIVE", "DISABLED")), Q("platformCode", R("PlatformCode")), *PG]),
  "049": ("createInboundEndpoint", "InboundEndpointCreate", "InboundEndpoint", ["023", "039"], "Tạo ở `DRAFT`. Luồng PH-04 xử lý chiều vào phải đã phát hành (ERR-14-039). Bật cần bốn mắt (BR-14-022) và xác nhận vân tay (API-14-090).", []),
  "050": ("updateInboundEndpoint", "InboundEndpointUpdate", "InboundEndpoint", ["004", "039"], "Đổi ánh xạ luồng hoặc tắt; phát EVT-14-13.", []),
  "051": ("listAllowedSenders", None, "AllowedSenderList", [], None, []),
  "052": ("putAllowedSenders", "AllowedSenderPut", "AllowedSenderList", ["004", "024"], "Thay toàn bộ danh sách; nguồn mới ở `PENDING_CONFIRM` tới khi SO xác nhận vân tay (API-14-090). Phát EVT-14-13.", []),
  "090": ("confirmInboundEndpoint", "ConfirmRequest", "InboundEndpoint", ["004", "007", "024"], "SO xác nhận vân tay chứng thư của nguồn; điểm cuối chuyển `ACTIVE` sau duyệt bốn mắt (BR-14-022). Phát EVT-14-13 để PH-03 nạp tuyến.", []),
  "053": ("listSyncRuns", None, "SyncRunList", [], None, [QA("kind", enum("SERVICE_CATALOG", "MASTER_DATA", "OPEN_DATA", "SERVICE_RECONCILE")), QA("state", enum("QUEUED", "RUNNING", "SUCCEEDED", "PARTIAL", "FAILED", "TIMED_OUT")), Q("from", TS), Q("to", TS), *PG]),
  "054": ("startCatalogSync", "SyncCatalogRequest", "SyncRun", ["026", "027", "028"], "Đồng bộ danh mục dịch vụ lên hệ thống của Bộ; mỗi loại một phiên cùng lúc (ERR-14-026). Bên nhận từ chối từng bản ghi ghi ERR-14-028. Phát EVT-14-12.", []),
  "055": ("getSyncRun", None, "SyncRunDetail", [], "Kèm bản ghi theo trang; không có nội dung dữ liệu.", [*PG]),
  "056": ("startMasterDataSync", "SyncMasterDataRequest", "SyncRun", ["026", "027", "125", "126"], "Đợt 3 (PH-06). Thiếu ánh xạ ở PH-07 ERR-14-125; PH-09 chặn ERR-14-126.", []),
  "057": ("retrySyncRun", "SyncRetryRequest", "SyncRun", ["004", "026"], "Chỉ bản ghi `ERROR` hoặc `REJECTED`; tối đa `14.sync.max-retries` lần mỗi bản ghi (ERR-14-004).", []),
  "087": ("publishOpenDataset", "OpenDatasetPublish", "SyncRun", ["026", "027", "126"], "Đợt 3. Lần công bố đầu của một tập cần duyệt bốn mắt (BR-14-022). PH-09 chặn trường không được công bố (ERR-14-126).", []),
  "088": ("withdrawOpenDataset", "OpenDatasetWithdraw", "SyncRun", ["004", "027"], "Gỡ tập đã công bố trên NDOP.", []),
  "058": ("getHealth", None, "HealthList", [], "PH-13 gọi bằng token dịch vụ `national.health-read`. Có `ETag`.", [Q("platformCode", R("PlatformCode"))]),
  "059": ("probePlatform", None, "ProbeResult", ["004", "029", "035"], "Chạy ở `worker`: DNS, TLS, token, gọi thăm dò, chữ ký. Không quá `14.test.max-per-hour` lần mỗi giờ (ERR-14-029).", [ENVQ]),
  "060": ("getDashboard", None, "Dashboard", [], "Một lời gọi dựng màn tổng quan (UI-14-01).", []),
  "061": ("listTransactions", None, "TransactionPage", [], "Khoảng thời gian tối đa 31 ngày (ERR-14-003). Nội dung bản tin đã che.",
          [Q("from", TS), Q("to", TS), Q("systemCode", R("SystemCode")), Q("serviceCode", R("ServiceCode")), QA("state", R("TxnState")), Q("direction", R("Direction")), Q("caseCode", STR(64)), Q("transactionCode", STR(64)), Q("fromCache", BOOL), *PG]),
  "062": ("getTransaction", None, "TransactionDetail", ["031"], "Siêu dữ liệu và dòng thời gian; không có nội dung (dùng API-14-063).", []),
  "063": ("revealTransactionPayload", "RevealRequest", "RevealResult", ["030", "031", "035"], "Chỉ SO, bắt buộc lý do và `acr` nhiều yếu tố trong 15 phút. Mỗi lần xem ghi vết; vượt `14.reveal.max-per-day` sinh EVT-14-16. Hết hạn lưu ERR-14-031.", []),
  "064": ("exportTransactionEvidence", "ExportEvidenceRequest", "JobAccepted", ["030", "031"], "Gói bằng chứng có chữ ký, giữ 7 ngày; giao cho AU qua kênh có kiểm soát.", []),
  "065": ("listUsage", None, "UsagePage", [], "Tổng hợp theo giờ từ `usage_hourly`.", [Q("from", TS), Q("to", TS), Q("systemCode", R("SystemCode")), Q("serviceCode", R("ServiceCode")), *PG]),
  "066": ("exportUsage", "UsageExportRequest", "JobAccepted", [], "CSV UTF-8 có BOM hoặc XLSX; tạo bất đồng bộ, tải qua `statusUrl`.", []),
  "067": ("listAnomalyAlerts", None, "AnomalyAlertList", [], "Đợt 2.", [QA("state", enum("OPEN", "RESOLVED")), Q("systemCode", R("SystemCode")), *PG]),
  "068": ("resolveAnomalyAlert", "AnomalyResolve", "AnomalyAlert", ["004"], "`WAIVED` tạo miễn trừ có thời hạn; ghi quyết định và kiểm toán.", []),
  "069": ("createQuotaEfficiencyReport", "QuotaEfficiencyRequest", "JobAccepted", [], "Đợt 3.", []),
  "086": ("setBreaker", "BreakerSetRequest", "BreakerState", ["004"], "Ép đóng hoặc mở tay, tự hết hạn; phát EVT-14-10.", []),
  "070": ("getSettings", None, "Settings", [], "Giá trị `14.*` của tenant kèm mặc định, miền, cờ bảo mật (★).", []),
  "071": ("putSettings", "SettingsUpdate", "Settings", ["004", "036"], "Ngoài miền hoặc vượt trần ERR-14-036. Tham số bảo mật (★) tạo yêu cầu duyệt bốn mắt (BR-14-022). Cổng làm mới trong 30 giây.", []),
  "072": ("createParallelRun", "ParallelRunCreate", "ParallelRun", ["033"], "Chỉ dịch vụ `READ`; mỗi dịch vụ một phiên (ERR-14-033).", []),
  "073": ("getParallelRun", None, "ParallelRun", [], "`readyForCutover` khi đạt `14.parallel.match-ratio` liên tục `14.parallel.min-days` ngày và đủ `14.parallel.min-samples` mẫu.", []),
  "089": ("addParallelObservation", "ParallelObservation", None, ["003"], "Luồng cắt chuyển của PH-04 gửi băm kết quả; không nhận dữ liệu. Lũy đẳng theo `observationId`.", []),
  "074": ("importLegacyServices", "LegacyImportRequest", "LegacyImportResult", ["032"], "Phân tích cấu hình NGSP cũ; bí mật dạng rõ bị loại và báo SO. Tệp lỗi theo dòng, cột (ERR-14-032), chưa áp dụng gì.", []),
  "075": ("invokeNationalService", "InvocationRequest", "InvocationResult", ["001", "003", "101", "102", "103", "104", "105", "106", "107", "108", "109", "110", "111", "112", "113", "114", "115", "116", "117", "128", "132", "133"],
          "Điểm gọi chung (chín chặng, SDD §4.4). Phản hồi kèm `X-DH-Transaction`, `X-DH-Cache` (`HIT`, `MISS`, `STALE`). Thao tác `WRITE` bắt buộc `Idempotency-Key`; cùng khóa cùng nội dung đang chạy trả `202` kèm `Retry-After`.", [P("IdempotencyKeyOpt"), "AcceptStale", "ParallelRunHeader", "OnBehalfOf", "ServiceHeader", "OperationHeader"]),
  "076": ("submitAsyncInvocation", "InvocationRequest", "AsyncAccepted", ["003", "104", "106", "107", "108", "116", "118", "133"], "Kiểm tra như API-14-075 rồi ghi hàng chờ bền; trả `202` kèm `requestId`. Hàng chờ đầy ERR-14-118.", []),
  "077": ("getAsyncInvocation", None, "AsyncStatus", ["129"], "Kết quả lưu mã hóa tối đa 72 giờ.", []),
  "078": ("cancelAsyncInvocation", "AsyncCancel", "AsyncStatus", ["129", "130"], "Chỉ hủy được yêu cầu còn `QUEUED`; đã gửi trả ERR-14-130.", []),
  "079": ("listNationalCatalogs", None, "NationalCatalogList", ["027", "101", "103", "104"], "Chỉ PH-07 gọi (BR-14-036). Lỗi sau thử lại được che và PH-07 ánh xạ sang ERR-07-028.", []),
  "080": ("getNationalCatalogStructure", None, "NationalCatalogStructure", ["102"], None, []),
  "081": ("getNationalCatalogData", None, "NationalCatalogData", ["102", "104"], "Phân trang phía nguồn (mặc định 1.000 bản ghi mỗi trang). `ifVersionNot` khớp phiên bản hiện hành thì trả `304`.",
          [Q("ifVersionNot", STR(32), "Phiên bản PH-07 đã có; khớp thì `304` (trả lời Q07-40)."), Q("page", STR(128), "Con trỏ `nextPage` của lần trước."), Q("pageSize", INT(minimum=1, maximum=5000, default=1000))]),
  "082": ("submitNationalCatalogProposal", "ProposalRequest", "ProposalStatus", ["102", "116"], "Bắt buộc `Idempotency-Key`; trả `202` kèm `proposalId`.", []),
  "083": ("getNationalCatalogProposal", None, "ProposalStatus", [], None, []),
  "091": ("getRuntimeConfig", None, "RuntimeConfig", [], "`dh-runtime` của tenant gọi (hoặc nhận qua EVT-14-01, 02, 03, 04, 08, 13 rồi gọi). Có `ETag`; `If-None-Match` khớp trả `304`. Không chứa bí mật; chữ ký ảnh chụp do `dh-integration` ký.", ["IfNoneMatch", Q("sinceVersion", INT(minimum=0))]),
  "084": ("receiveInboundRequest", "InboundEnvelope", "InboundResponse", ["119", "120", "121", "122", "123", "124", "109", "110", "111"], "Biên chấm dứt mTLS, kiểm vân tay, giới hạn tần suất; cổng xác minh chữ ký và chống phát lại trong `14.inbound.replay-window-seconds`; chuyển luồng PH-04 và trả phản hồi có ký. Cùng `messageId` gửi lại thì trả kết quả đã có.", ["TenantHeader", "ServiceCodeHeader"]),
  "085": ("receiveInboundNotification", "NotificationRequest", "NotificationAccepted", ["119", "120", "121", "122", "123"], "Đợt 2. Ghi nhận và phát EVT-14-17; không chạy luồng.", ["TenantHeader"]),
}
assert set(X) == {o[0] for o in spec.OPS}, set(X) ^ {o[0] for o in spec.OPS}


def frs_of(fr):
    out = []
    for part in fr.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-"); out += [f"FR-14-{i:03d}" for i in range(int(a), int(b) + 1)]
        else:
            out.append(f"FR-14-{int(part):03d}")
    return out


def build():
    paths, used_err = {}, set()
    for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
        opid, body, resp, errs, desc, extra = X[code]
        m = method.lower()
        op = {"tags": [spec.TAGS[group]], "operationId": opid, "summary": summary, "x-datahub-id": f"API-14-{code}", "x-datahub-fr": frs_of(fr)}
        plane = "edge" if group == "edge" else "data" if path.startswith(spec.I) else "control"
        if perm.startswith("svc:"):
            sc = perm[4:]
            op["x-datahub-permission"] = {"permission": f"Token dịch vụ, scope `{sc}`" + (" (PERM-14-invoke)" if sc == "national.invoke" else ""), "serviceScope": sc}
            op["security"] = [{"oauth2Service": [sc]}]
        elif perm == "edge":
            op["x-datahub-permission"] = {"permission": "mTLS của nguồn được phép (chiều vào)"}
            op["security"] = [{"mtlsEdge": []}]
        else:
            op["x-datahub-permission"] = {"permission": f"PERM-14-{perm}"}
            if code in SVC_ALSO:
                op["security"] = [{"oauth2User": []}, {"oauth2Service": [SVC_ALSO[code]]}]
                op["x-datahub-permission"]["serviceScope"] = SVC_ALSO[code]
        if not desc:
            desc = ("Đối tượng thuộc tenant khác trả 404 như không tồn tại (ERR-14-001)." if "{" in path and m == "get"
                    else "Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).")
        op["description"] = desc.strip()
        if idem: op["x-datahub-idempotent"] = True
        params = [P(PATH_PARAM[n]) for n in re.findall(r"\{(\w+)\}", path) if n in PATH_PARAM]
        if code in IFM: params.append(P("IfMatch"))
        for e in extra: params.append(P(e) if isinstance(e, str) else e)
        if idem == "x": params.append(P("IdempotencyKey"))
        params += [P("Traceparent"), P("AcceptLanguage")]
        op["parameters"] = [p for p in params if not (isinstance(p, dict) and p.get("$ref") == "#/components/parameters/IdempotencyKeyOpt" and False)]
        if body:
            op["requestBody"] = {"required": True, "content": {"application/json": {"schema": R(body)}}}
        okr = {"description": "Thành công."}
        if code == "066":
            okr["description"] = "Đã nhận; tạo tệp bất đồng bộ."
        if resp:
            okr["content"] = {"application/json": {"schema": R(resp)}}
        if code == "081":
            okr["content"]["application/x-ndjson"] = {"schema": STR(description="Luồng bản ghi, mỗi dòng một đối tượng JSON.")}
        hdr = {}
        if m == "get" and resp and plane != "edge": hdr["ETag"] = {"schema": STR()}
        if code == "075":
            hdr["X-DH-Transaction"] = {"schema": STR(), "description": "Mã giao dịch."}
            hdr["X-DH-Cache"] = {"schema": enum("HIT", "MISS", "STALE")}
        if success == "202" and plane == "control": hdr["Location"] = {"schema": STR(), "description": "Tài nguyên theo dõi tiến trình."}
        if success == "201": hdr["Location"] = {"schema": STR()}; hdr["ETag"] = {"schema": STR()}
        if hdr: okr["headers"] = hdr
        resps = {success: okr}
        if code in ("081", "091"): resps["304"] = RESP("NotModified")
        if code == "075": resps["202"] = {"description": "Cùng `Idempotency-Key` và cùng nội dung đang chạy; kèm `Retry-After` và `transactionCode` cũ.", "content": {"application/json": {"schema": R("AsyncAccepted")}}}
        if plane != "edge": resps["401"] = RESP("Unauthorized")
        auto = []
        if path.count("{") and plane == "control": auto.append("001")
        if body or any(isinstance(e, dict) and e.get("in") == "query" for e in extra): auto.append("003")
        if code in IFM: auto.append("004")
        if plane in ("data", "edge") or code in ("091",): auto.append("127")
        allerr = sorted(set(auto + errs))
        for c in allerr:
            used_err.add(c)
            for st in ERR_HTTP[c]:
                resps[st] = RESP(HTTP_RESP[st][0])
        if m != "get" and plane == "control": resps["403"] = RESP("Forbidden")
        if plane == "control" and "403" not in resps and perm != "read": resps["403"] = RESP("Forbidden")
        if plane == "control": resps["500"] = RESP("InternalError")
        op["responses"] = dict(sorted(resps.items()))
        op["x-datahub-errors"] = [f"ERR-14-{c}" for c in allerr]
        paths.setdefault(path, {})[m] = op
    return {
      "openapi": "3.1.0",
      "info": {"title": "Datahub · PH-14 Kết nối quốc gia API", "version": "1.0.0-draft",
               "summary": "Nền tảng và dịch vụ quốc gia, định tuyến, chứng thư và chữ ký số, hạn mức và đệm, chiều vào, đồng bộ, giám sát; cổng gọi nội bộ và cổng danh mục dùng chung.",
               "description": ("API của PH-14 (module `national` ở `dh-integration` và hồ sơ `national-gateway` ở `dh-runtime`), ba mặt phẳng:\n\n"
                   "1. **Điều khiển** `/api/national/v1`: người dùng gọi qua BFF console (Authorization Code + PKCE); PH-02, PH-06, PH-13 và luồng PH-04 gọi bằng token dịch vụ ở vài endpoint.\n"
                   "2. **Dữ liệu nội bộ** `/internal/national/v1`: HTTT, luồng PH-04, PH-07 gọi qua mesh hoặc APISIX bằng token dịch vụ; `dh-runtime` đọc cấu hình.\n"
                   "3. **Chiều vào** `/inbound/v1`: nền tảng quốc gia gọi vào tỉnh qua APISIX vùng biên bằng mTLS.\n\n"
                   "Quy ước (D03-04-PH14 §1): tenant lấy từ token hoặc điểm cuối; tạo nhận `Idempotency-Key`; sửa và đổi trạng thái bắt buộc `If-Match`; hậu tố `:{hành-động}`; lỗi RFC 9457 mã `ERR-14-nnn`; phân trang `page`/`size`. "
                   "Không API nào trả thông tin xác thực, khóa riêng hay nội dung bản tin thô (trừ API-14-063 của SO). Mọi tên miền và dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay."),
               "contact": {"name": "Nhóm phân hệ PH-14"},
               "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)", "identifier": "LicenseRef-Datahub-Internal"},
               "x-datahub-document": "D03-04-PH14", "x-datahub-phase": "PH-14"},
      "servers": [{"url": "https://console.{tenantHost}.datahub.example.vn", "description": "Qua BFF console của tenant (điều khiển) — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong", "description": "Ví dụ `lamdong` cho T68 (giả lập)."}}},
                  {"url": "http://dh-national-gateway.dh-runtime.svc:8080", "description": "Trong cụm, mặt phẳng dữ liệu nội bộ (`/internal/national/v1`)"},
                  {"url": "https://edge.{tenantHost}.datahub.example.vn", "description": "Vùng biên, chiều vào (`/inbound/v1`) — giả lập",
                   "variables": {"tenantHost": {"default": "lamdong"}}},
                  {"url": "http://localhost:8091", "description": "Phát triển cục bộ"}],
      "security": [{"oauth2User": []}],
      "tags": [{"name": v} for v in spec.TAGS.values()],
      "paths": paths,
      "components": {
        "securitySchemes": {
          "oauth2User": {"type": "oauth2", "description": "Keycloak realm dh-{tenant}; vai trò ánh xạ PERM-14-* (D02-08).",
            "flows": {"authorizationCode": {"authorizationUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth",
                                            "tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": {}}}},
          "oauth2Service": {"type": "oauth2", "description": "Token dịch vụ (client credentials + `private_key_jwt`); tenant ở claim `tenant`, mã HTTT ở `azp`.",
            "flows": {"clientCredentials": {"tokenUrl": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token", "scopes": SCOPES}}},
          "mtlsEdge": {"type": "mutualTLS", "description": "Chứng thư mTLS của nền tảng quốc gia; vân tay phải khớp nguồn được phép của điểm cuối (SEC-10, 11)."}},
        "parameters": PARAMS, "responses": RESPONSES, "schemas": SCHEMAS}}


if __name__ == "__main__":
    doc = build()
    out = os.path.join(ROOT, "openapi-national.yaml")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# D03-04-PH14 · OpenAPI PH-14 (điều khiển, dữ liệu nội bộ, chiều vào). SINH TỰ ĐỘNG bởi tools/gen_openapi.py — không sửa tay.\n")
        yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False, width=140)
    n = sum(len(v) for v in doc["paths"].values())
    print(f"{n} operation, {len(SCHEMAS)} lược đồ → {out}")
