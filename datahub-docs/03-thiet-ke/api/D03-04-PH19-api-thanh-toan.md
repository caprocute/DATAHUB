---
ma_tai_lieu: D03-04-PH19
ten: Đặc tả API và sự kiện phân hệ PH-19 Thanh toán điện tử
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Lập trình viên L-PAY, lập trình viên HTTT đối tác, kiểm thử viên, nhóm tích hợp PayGov, kiến trúc sư
phan_he: PH-19
nguoi_lap: Nhóm phân hệ PH-19
mo_ta: Đặc tả 107 endpoint REST của ba nhóm quản trị, đối tác và callback, 8 webhook, 18 sự kiện Kafka và mã lỗi ERR-19 của phân hệ Thanh toán điện tử, sinh từ OpenAPI và AsyncAPI đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH19 FRS; D02-03-PH19-00 Khung truy vết; D03-02-PH19 SDD; D03-03-PH19 CSDL; D03-06-PH19 Màn hình; D05-02-PH19 Test case; D04-01 Quy ước mã
---

# D03-04-PH19 · Đặc tả API và sự kiện phân hệ PH-19 Thanh toán điện tử

## Tóm tắt cho hội đồng thẩm định

PH-19 có bốn loại giao diện lập trình, cho bốn đối tượng gọi khác nhau:

1. **API quản trị** `/api/payment/v1` (API-19-001…092): cán bộ quản trị, kế toán, người duyệt, kiểm toán dùng qua giao diện Datahub. Gồm nhà cung cấp (NCC), dịch vụ, đối tác, phê duyệt bốn mắt, giao dịch, thông báo kết quả (IPN), hoàn tiền, đối soát, chênh lệch, nhật ký, webhook, dashboard, báo cáo, cấu hình, di trú.
2. **API đối tác** `/api/payment-partner/v1` (API-19-101…110): HTTT dịch vụ công, một cửa, hộ tịch… gọi để thu phí, lệ phí và tra kết quả. Đây là hợp đồng mà các đơn vị phát triển HTTT của tỉnh cần đọc đầu tiên. Kết quả được đẩy về bằng **webhook** ký HMAC, dự phòng kéo bằng API-19-109.
3. **API callback** `/api/payment-callback/v1` (API-19-201…204): PayGov gọi về; thêm API-19-205 cho trang kết quả người nộp (UI-19-28) thăm dò trạng thái. Tên trường, thuật toán ký, mã phản hồi là **giả định** chờ Tài liệu kỹ thuật kết nối do VPCP cấp (OQ-19-01…07); phần phụ thuộc PayGov nằm gọn trong adapter (ADR-040).
4. **Sự kiện Kafka** EVT-19-01…18 cho PH-13, PH-16, PH-18 và lớp dữ liệu dùng chung.

So với Payment cũ, hợp đồng mới thêm những bảo đảm mà hệ cũ không có: chống trùng bắt buộc bằng `Idempotency-Key` và chống trùng mã hồ sơ; số tiền là số nguyên đồng (không còn `int(10)`); kết quả về đối tác có chữ ký, có số thứ tự, có gửi lại và có kéo dự phòng; hoàn tiền, xử lý chênh lệch đều qua phê duyệt bốn mắt; mọi lỗi có mã `ERR-19-nnn` và câu tiếng Việt.

Tài liệu này là văn xuôi giải thích các tệp hợp đồng. Khi văn xuôi và tệp hợp đồng khác nhau, **tệp hợp đồng là nguồn sự thật**:

| Tệp | Nội dung | Quy mô |
|---|---|---|
| [`ph19/openapi-payment-admin.yaml`](ph19/openapi-payment-admin.yaml) | API quản trị (OpenAPI 3.1) | 92 operation API-19-001…092 |
| [`ph19/openapi-payment-partner.yaml`](ph19/openapi-payment-partner.yaml) | API đối tác và 8 webhook (OpenAPI 3.1, mục `webhooks`) | 10 operation API-19-101…110 |
| [`ph19/openapi-payment-callback.yaml`](ph19/openapi-payment-callback.yaml) | API callback PayGov (OpenAPI 3.1, giả định) | 5 operation API-19-201…205 |
| [`ph19/asyncapi-payment.yaml`](ph19/asyncapi-payment.yaml) | Sự kiện Kafka (AsyncAPI 3.0) | 18 kênh EVT-19-01…18 |
| [`ph19/tools/`](ph19/tools/) | `schemas.py` (lược đồ chung), `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` (bảng §3, §4, §6), `check_contracts.py` | — |

: Tệp hợp đồng API và sự kiện của PH-19

Danh sách endpoint, quyền, FR và bảng mã lỗi được **đọc từ khung truy vết** [D02-03-PH19-00](../../02-yeu-cau/frs/D02-03-PH19-00-khung-truy-vet.md) §10, §12 khi sinh, nên không thể lệch khung. Bốn tệp YAML do script sinh, không sửa tay. Mọi tên miền, máy chủ, dữ liệu là giả lập; tenant ví dụ `T68`, topic chữ thường `t68`.

Căn cứ: FRS [D02-03-PH19](../../02-yeu-cau/frs/D02-03-PH19-frs-thanh-toan.md) §5, §8; SDD [D03-02-PH19](../sdd/D03-02-PH19-sdd-thanh-toan.md) §4…§12; CSDL [D03-03-PH19](../csdl/D03-03-PH19-csdl-thanh-toan.md); màn hình [D03-06-PH19](../uiux/D03-06-PH19-man-hinh-thanh-toan.md).

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả toàn bộ giao diện lập trình của PH-19 Thanh toán điện tử: 92 endpoint quản trị, 10 endpoint đối tác kèm 8 webhook, 5 endpoint callback cho PayGov, 18 sự kiện Kafka, hợp đồng với phân hệ khác và bảng mã lỗi ERR-19. Mục đích là để lập trình viên L-PAY hiện thực đúng hợp đồng, để đơn vị phát triển HTTT đối tác tích hợp thu phí mà không phải hỏi lại, và để kiểm thử viên viết ca kiểm thử hợp đồng. Nguồn chuẩn là bốn tệp máy đọc nêu ở phần Tóm tắt; chương 10 đặc tả từng endpoint theo 10 mục, sinh tự động từ OpenAPI nên luôn khớp hợp đồng.

Phạm vi gồm mọi endpoint có mã API-19-nnn trong khung truy vết §10. Ngoài phạm vi: giao thức nội bộ của adapter PayGov (D03-02-PH19 §4), lược đồ bảng (D03-03-PH19) và hành vi màn hình (D03-06-PH19).

### 0.2. Người đọc và cách đọc

| Người đọc | Phần cần đọc | Mục đích |
|---|---|---|
| Lập trình viên L-PAY, giao diện | Chương 1, 2, 3, 6, 10 | Hiện thực bộ điều khiển, kiểm quyền, mã lỗi đúng hợp đồng |
| Đơn vị phát triển HTTT đối tác | Chương 1, 2.1, 3.1, 4, 10 (nhóm Thanh toán, Hoàn tiền đối tác, Đối soát đối tác) | Tích hợp thu phí, nhận webhook, đối chiếu |
| Nhóm tích hợp PayGov | Chương 3.2, 10 (nhóm Callback PayGov), 9 | Đối chiếu giả định với tài liệu kỹ thuật của VPCP |
| Kiểm thử viên | Chương 6, 7, 10 | Viết ca kiểm thử hợp đồng và ca lỗi |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5 | Đánh giá xác thực, tách nhiệm, bảo vệ dữ liệu cá nhân |

: Người đọc và phần cần đọc của tập API PH-19

### 0.3. Thuật ngữ và chữ viết tắt

| Thuật ngữ | Giải thích |
|---|---|
| Endpoint, operation | Một cặp phương thức HTTP và đường dẫn, có mã API-19-nnn |
| Webhook | Lời gọi HTTP do Datahub chủ động gửi tới đối tác để báo kết quả, ký HMAC |
| Callback, IPN | Lời gọi do PayGov gửi về Datahub để báo kết quả thanh toán (Instant Payment Notification, thông báo thanh toán tức thời) |
| `connectionKey` | Khóa 32 ký tự gắn với một kết nối nhà cung cấp, nằm trong đường dẫn callback, dùng để xác định tenant và khóa xác minh chữ ký |
| Idempotency, lũy đẳng | Gửi lại cùng yêu cầu nhiều lần chỉ tạo một kết quả, nhờ tiêu đề `Idempotency-Key` |
| ETag, `If-Match` | Dấu phiên bản của đối tượng và tiêu đề bắt buộc khi sửa để chống ghi đè (khóa lạc quan) |
| RFC 9457 | Chuẩn định dạng lỗi `application/problem+json` |
| OpenAPI 3.1, AsyncAPI 3.0 | Chuẩn mô tả máy đọc được cho API REST và cho sự kiện |
| NCC | Nhà cung cấp thanh toán (PayGov là NCC đầu tiên) |
| HTTT | Hệ thống thông tin của tỉnh, trong tập này là đối tác gọi API thanh toán |

: Thuật ngữ và chữ viết tắt của tập API PH-19

Thuật ngữ còn lại dùng chung với [D02-03-PH19](../../02-yeu-cau/frs/D02-03-PH19-frs-thanh-toan.md) và D00-01. Câu thông báo người dùng thấy theo từng mã lỗi ở FRS chương 9 và D03-06-PH19.

### 0.4. Tài liệu tham chiếu

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH19-00 Khung truy vết | Danh sách endpoint, quyền, mã lỗi (nguồn sinh hợp đồng) |
| D02-03-PH19 FRS | FR được mỗi endpoint hiện thực, quy tắc nghiệp vụ |
| D03-02-PH19 SDD | Thành phần xử lý, adapter PayGov, inbox, outbox |
| D03-03-PH19 CSDL | Bảng và cột ánh xạ với trường JSON |
| D03-06-PH19 Màn hình | Màn hình gọi endpoint quản trị, câu thông báo |
| D05-02-PH19 Test case | Ca kiểm thử hợp đồng |
| ADR-040…049 | Quyết định kiến trúc thanh toán (adapter, inbox, bốn mắt, mã hóa trường, strangler) |
| RFC 9457, RFC 9110, W3C Trace Context | Định dạng lỗi, ngữ nghĩa HTTP, truy vết |

: Tài liệu tham chiếu của tập API PH-19

### 0.5. Cấu trúc tài liệu

Chương 1 nêu quy ước chung của mọi endpoint. Chương 2 nói về xác thực, phân quyền và tách nhiệm. Chương 3 là danh mục endpoint kèm luồng đối tác thu tiền và cách phản hồi callback. Chương 4 là danh mục sự kiện Kafka. Chương 5 là hợp đồng với phân hệ khác và bên ngoài. Chương 6 là bảng mã lỗi ERR-19. Chương 7 mô tả kiểm tra hợp đồng trong CI. Chương 8 ánh xạ API hệ cũ sang API mới. Chương 9 là câu hỏi mở. Chương 10 đặc tả từng endpoint theo 10 mục, sinh từ OpenAPI.

## 1. Quy ước chung

| Chủ đề | Quy ước | Trong hợp đồng |
|---|---|---|
| Đường dẫn gốc | Ba nhóm `/api/payment/v1`, `/api/payment-partner/v1`, `/api/payment-callback/v1` (D00-01 §6), mỗi nhóm một tệp OpenAPI và một tuyến APISIX riêng (`apisix-int` cho quản trị; `apisix-ext` cho đối tác ngoài mạng nội bộ và callback) | `servers` |
| Phiên bản | Số chính trong đường dẫn; trong `v1` chỉ thêm trường tùy chọn và endpoint mới; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng. Đối tác phải bỏ qua trường lạ (đọc khoan dung) | `info.version` |
| Tenant | Lấy từ token (quản trị, đối tác) hoặc từ `connectionKey` (callback); không bao giờ từ tham số. Đối tượng ngoài phạm vi trả ERR-19-020 như không tồn tại | Mô tả |
| Định danh | Quản trị dùng UUID v7 trong đường dẫn. Đối tác dùng mã nghiệp vụ `transactionCode`, `refundCode`, `partnerOrderId` để HTTT không phải lưu UUID của Datahub | `parameters` |
| Đặt tên | Danh từ số nhiều, chữ thường, gạch nối; thao tác đổi trạng thái là tài nguyên con số nhiều (`/suspensions`, `/lifecycle-requests`, `/decisions`) (khung §10.1) | `paths` |
| JSON | camelCase, ánh xạ 1–1 với cột snake_case của D03-03-PH19. Số tiền là số nguyên đồng (`Money`, 1…999.999.999.999), không có số thập phân, không có chuỗi | `Money` |
| Thời gian | ISO 8601 có múi giờ, máy chủ trả UTC (`Z`); ngày đối soát `date` theo giờ Việt Nam (BR-19-025) | `format: date-time` |
| Phân trang | Con trỏ mờ `cursor`, `limit` mặc định 20, tối đa 200; trả `page.next`, `page.hasMore`, `page.total` (chính xác tới 10.000) hoặc `page.totalApprox` | `CursorMeta` |
| Chống trùng | `Idempotency-Key` 16…64 ký tự `[A-Za-z0-9_-]`: **bắt buộc** cho mọi `POST` của API đối tác (BR-19-006), khuyến nghị cho lệnh tạo của giao diện. Lưu 24 giờ (Valkey + `idempotency_record`); cùng khóa khác nội dung ERR-19-003, đang xử lý ERR-19-004; trả lại thì có tiêu đề `Idempotent-Replayed: true` | `IdempotencyKey` |
| Khóa lạc quan | `ETag: W/"{version}"`; mọi `PATCH`, `PUT`, `DELETE` và thao tác đổi trạng thái của API quản trị bắt buộc `If-Match`, lệch trả ERR-19-045 (412) | `IfMatch`, `ETag` |
| Hành động được phép | Đối tượng có vòng đời trả `allowedActions`, `disabledReasons` để giao diện bật, tắt nút đúng trạng thái và quyền (D03-06-PH19 §2) | `AllowedActions` |
| Xử lý nền | Thao tác chưa xong ngay (kiểm tra kết nối, đối soát, chốt phiên, xuất, di trú, xử lý lại IPN, gửi lại webhook) trả `202` kèm `Location` | `202` |
| Lỗi | RFC 9457 `application/problem+json`: `type` = `/problems/ERR-19-nnn`, `title` cố định, `status`, `detail` tiếng Việt không chứa dữ liệu cá nhân hay bí mật, `code`, `traceId`, `errors[]` (ERR-19-001), `missing[]` (ERR-19-035), `existingTransactionCode` (ERR-19-015) | `ProblemDetails` |
| Truy vết | `traceparent` W3C xuyên suốt tới lời gọi PayGov, outbox, webhook (`traceparent` trong CloudEvent) | `Traceparent` |
| Dữ liệu cá nhân | Đối tác gửi thông tin người nộp ở `payer`; PH-19 mã hóa ngay khi nhận (ADR-048) và **không bao giờ** trả lại qua API đối tác, sự kiện hay webhook. API quản trị trả bản che, bản đầy đủ chỉ khi `reveal=true` + quyền `transaction-read-pii` + lý do | `Payer`, `PayerMasked` |

: Quy ước chung của API PH-19

## 2. Xác thực và phân quyền

### 2.1. Ba cách xác thực

| Nhóm | Người gọi | Xác thực | Kiểm tra ở `dh-payment` |
|---|---|---|---|
| Quản trị | Cán bộ qua `dh-console` (BFF) | OIDC Authorization Code + PKCE, realm `dh-{tenant}` | Tenant của token; quyền `PERM-19-*` qua OPA (ADR-006); tách nhiệm §2.3 |
| Đối tác | HTTT đối tác (máy) | OAuth 2.0 client credentials; xác thực client bằng mTLS (RFC 8705) hoặc `private_key_jwt`; token ≤ 5 phút, ràng buộc chứng thư (NFR-19-019) | Client thuộc đối tác `ACTIVE`, chế độ `DATAHUB` hoặc `SHADOW` (ERR-19-005, 006); dữ liệu giới hạn trong đối tác của client |
| Callback | PayGov | Không token. APISIX: allowlist IP nguồn, mTLS nếu PayGov dùng. `dh-payment`: `connectionKey` → NCC → tenant (`callback_route`), chữ ký bằng chứng thư `ACTIVE` hoặc `NEXT`, dấu thời gian ±5 phút, nonce (NFR-19-020, ADR-045) | Mã đơn vị trong nội dung đã ký phải khớp NCC (`TENANT_MISMATCH`) |

: Ba cách xác thực

APISIX kiểm chữ ký token, hạn và giới hạn tần suất (ERR-19-048) trước; `dh-payment` kiểm lại tenant và quyền, nên cấu hình biên sai cũng không mở được dữ liệu tỉnh khác.

### 2.2. Quyền

48 quyền `PERM-19-*` định nghĩa ở khung §13.2; cột "Quyền" của §3 ghi phần sau tiền tố. Bốn quyền dùng riêng cho client đối tác: `partner-pay-create`, `partner-pay-read`, `partner-refund-create`, `partner-recon-read`. API-19-050 (quyết định đề nghị) kiểm quyền theo `approvalType`:

| `approvalType` | Quyền quyết định |
|---|---|
| `PROVIDER_ACTIVATE`, `PROVIDER_RETIRE` | `provider-activate` |
| `PARTNER_ONBOARD`, `PARTNER_TERMINATE` | `partner-approve` |
| `REFUND` | `refund-approve` |
| `DISCREPANCY_RESOLUTION` | `discrepancy-approve` |
| `RECON_REOPEN` | `recon-reopen-approve` |
| `ROUTING_MODE_CHANGE` | `migration-switch` (người quyết định khác người lập) |
| `RESULT_MAPPING_CHANGE` (đề xuất) | `provider-activate` |

: Quyền theo nhóm endpoint của PH-19

### 2.3. Tách nhiệm và kiểm tra đặc biệt

- **Bốn mắt** (khung §13.4 quy tắc 1–5): API-19-050 từ chối người lập; hoàn hai cấp cần ba người khác nhau; `RECORD_MANUAL` ở API-19-062 từ chối người đã duyệt; người chốt phiên không duyệt mở lại phiên đó. Vi phạm trả ERR-19-033 và ghi sự kiện an ninh. CSDL chặn lần nữa bằng `CHECK` (D03-03-PH19 §3.39).
- **Xem dữ liệu cá nhân** (quy tắc 6): API-19-052 với `reveal=true` cần `transaction-read-pii` và tiêu đề `X-Datahub-Reveal-Reason`; mỗi lần ghi kiểm toán.
- **Xác thực lại** khi quyết định đề nghị có giá trị tiền (`REFUND`, `DISCREPANCY_RESOLUTION`): token phải có `auth_time` trong 5 phút, nếu không trả 401 với `WWW-Authenticate: Bearer error="insufficient_user_authentication", max_age=300` (RFC 9470).
- **Phân hệ chưa bật**: mọi API của tenant chưa bật PH-19 (PH-20 đặt `module_enabled`) trả ERR-19-049.

## 3. Danh mục endpoint

Bảng sinh từ `ph19/tools/gen_openapi.py` bằng `gen_md.py`. Cột "FR" ghi số FR-19 bỏ tiền tố; "Khóa" ghi `If-Match`, `Idem` (khuyến nghị), `Idem bắt buộc`. Mọi operation quản trị, đối tác có thể trả 401 (PH-12, PH-03), ERR-19-046, 048, 049, 099; lệnh ghi có thể trả ERR-19-050. Các mã này có trong hợp đồng, không nhắc lại ở bảng.

<!-- gen:endpoints:start -->
#### API quản trị `/api/payment/v1`


**Nhà cung cấp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-001 | `GET /providers` | Danh sách NCC, lọc trạng thái, sức khỏe, từ khóa | 007 | provider-read |  | 200 |
| API-19-002 | `POST /providers` | Khai báo NCC (`DRAFT`) | 001 | provider-write | Idem | 201 |
| API-19-003 | `GET /providers/{providerId}` | Chi tiết NCC kèm sức khỏe, mạch ngắt, hạn chứng thư, số dịch vụ | 008, 011 | provider-read |  | 200 |
| API-19-004 | `PATCH /providers/{providerId}` | Sửa NCC (BR-19-026) | 009 | provider-write | If-Match | 200 |
| API-19-005 | `DELETE /providers/{providerId}` | Xóa cứng NCC `DRAFT` | 010 | provider-delete | If-Match | 204 |
| API-19-006 | `GET /providers/{providerId}/credentials` | Danh sách tham chiếu bí mật (chỉ siêu dữ liệu) | 002 | provider-read |  | 200 |
| API-19-007 | `PUT /providers/{providerId}/credentials/{environment}` | Gắn tham chiếu bí mật của một môi trường | 002 | credential-manage | If-Match | 200 |
| API-19-008 | `POST /providers/{providerId}/credentials/{environment}/rotations` | Xoay khóa, chứng thư (tạo bản `NEXT`, chuyển tiếp) | 012 | credential-manage | If-Match | 200 |
| API-19-009 | `POST /providers/{providerId}/connection-tests` | Chạy kiểm tra kết nối | 003 | provider-test | Idem | 202 |
| API-19-010 | `POST /providers/{providerId}/test-transactions` | Tạo giao dịch thử | 004 | provider-test | Idem | 202 |
| API-19-011 | `GET /providers/{providerId}/check-runs` | Kết quả kiểm tra, giao dịch thử, trạng thái checklist | 003, 004, 005 | provider-read |  | 200 |
| API-19-012 | `POST /providers/{providerId}/lifecycle-requests` | Đề nghị `ACTIVATE` hoặc `RETIRE` (tạo `approval_request`) | 005, 010 | provider-write (ACTIVATE); provider-delete (RETIRE) | If-Match | 201 |
| API-19-013 | `POST /providers/{providerId}/suspensions` | Tạm dừng NCC | 006 | provider-suspend | If-Match | 200 |
| API-19-014 | `POST /providers/{providerId}/resumptions` | Mở lại NCC | 006 | provider-suspend | If-Match | 200 |

: API quản trị /api/payment/v1 · Nhà cung cấp

**Nhóm dịch vụ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-015 | `GET /service-groups` | Danh sách nhóm dịch vụ | 013 | service-read |  | 200 |
| API-19-016 | `POST /service-groups` | Thêm nhóm dịch vụ | 013, 016 | service-write | Idem | 201 |
| API-19-017 | `GET /service-groups/{groupId}` | Chi tiết nhóm dịch vụ | 013 | service-read |  | 200 |
| API-19-018 | `PATCH /service-groups/{groupId}` | Sửa nhóm dịch vụ | 013, 016 | service-write | If-Match | 200 |
| API-19-019 | `DELETE /service-groups/{groupId}` | Xóa mềm nhóm (không còn dịch vụ) | 013 | service-write | If-Match | 204 |

: API quản trị /api/payment/v1 · Nhóm dịch vụ

**Dịch vụ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-020 | `GET /services` | Danh sách, tìm dịch vụ | 014 | service-read |  | 200 |
| API-19-021 | `POST /services` | Thêm dịch vụ | 014, 016 | service-write | Idem | 201 |
| API-19-022 | `GET /services/{serviceId}` | Chi tiết dịch vụ | 014 | service-read |  | 200 |
| API-19-023 | `PATCH /services/{serviceId}` | Sửa dịch vụ | 014, 016 | service-write | If-Match | 200 |
| API-19-024 | `DELETE /services/{serviceId}` | Xóa cứng dịch vụ `DRAFT` chưa có giao dịch | 015 | service-activate | If-Match | 204 |
| API-19-025 | `POST /services/{serviceId}/activations` | Kích hoạt hoặc mở lại dịch vụ | 015 | service-activate | If-Match | 200 |
| API-19-026 | `POST /services/{serviceId}/suspensions` | Tạm dừng dịch vụ | 015 | service-activate | If-Match | 200 |
| API-19-027 | `POST /services/{serviceId}/retirements` | Ngừng hẳn dịch vụ | 015 | service-activate | If-Match | 200 |
| API-19-028 | `GET /catalog-lookups/{catalogCode}/items` | Tra mục danh mục PH-07 cho biểu mẫu (có đệm, chỉ các danh mục ở mục 1.5) | 016 | service-read |  | 200 |

: API quản trị /api/payment/v1 · Dịch vụ

**Đối tác**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-029 | `GET /partners` | Danh sách, tìm đối tác | 017 | partner-read |  | 200 |
| API-19-030 | `POST /partners` | Đăng ký đối tác (`DRAFT`) | 017 | partner-write | Idem | 201 |
| API-19-031 | `GET /partners/{partnerId}` | Chi tiết đối tác | 017 | partner-read |  | 200 |
| API-19-032 | `PATCH /partners/{partnerId}` | Sửa hồ sơ đối tác | 017 | partner-write | If-Match | 200 |
| API-19-033 | `POST /partners/{partnerId}/lifecycle-requests` | Đề nghị `ONBOARD` hoặc `TERMINATE` | 018 | partner-write | If-Match | 201 |
| API-19-034 | `POST /partners/{partnerId}/suspensions` | Tạm dừng đối tác | 018 | partner-suspend | If-Match | 200 |
| API-19-035 | `POST /partners/{partnerId}/resumptions` | Mở lại đối tác | 018 | partner-suspend | If-Match | 200 |
| API-19-036 | `GET /partners/{partnerId}/clients` | Danh sách client của đối tác | 019 | partner-read |  | 200 |
| API-19-037 | `POST /partners/{partnerId}/clients` | Cấp client tại PH-12 | 019 | partner-client-manage | Idem | 201 |
| API-19-038 | `DELETE /partners/{partnerId}/clients/{clientId}` | Thu hồi client | 019 | partner-client-manage |  | 204 |
| API-19-039 | `GET /partners/{partnerId}/service-grants` | Dịch vụ được gán và hạn mức | 020 | partner-read |  | 200 |
| API-19-040 | `PUT /partners/{partnerId}/service-grants/{serviceId}` | Gán dịch vụ, đặt hạn mức | 020 | partner-write |  | 200 |
| API-19-041 | `DELETE /partners/{partnerId}/service-grants/{serviceId}` | Bỏ gán dịch vụ | 020 | partner-write | If-Match | 204 |
| API-19-042 | `GET /partners/{partnerId}/webhook-endpoints` | Danh sách đầu nhận webhook | 021 | partner-read |  | 200 |
| API-19-043 | `POST /partners/{partnerId}/webhook-endpoints` | Thêm đầu nhận | 021 | partner-webhook-manage | Idem | 201 |
| API-19-044 | `PATCH /partners/{partnerId}/webhook-endpoints/{endpointId}` | Sửa, vô hiệu đầu nhận | 021 | partner-webhook-manage | If-Match | 200 |
| API-19-045 | `POST /partners/{partnerId}/webhook-endpoints/{endpointId}/test-deliveries` | Gửi thử webhook | 021 | partner-webhook-manage |  | 200 |
| API-19-046 | `POST /partners/{partnerId}/webhook-endpoints/{endpointId}/secret-rotations` | Xoay bí mật ký | 021 | partner-webhook-manage | If-Match | 200 |
| API-19-047 | `POST /partners/{partnerId}/routing-mode-requests` | Đề nghị đổi chế độ định tuyến | 066 | migration-switch | If-Match | 201 |

: API quản trị /api/payment/v1 · Đối tác

**Phê duyệt**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-048 | `GET /approval-requests` | Hộp phê duyệt: đề nghị người dùng lập hoặc có quyền quyết định | 005, 010, 018, 039, 046, 047, 066 | (theo loại đề nghị) |  | 200 |
| API-19-049 | `GET /approval-requests/{approvalId}` | Chi tiết đề nghị kèm bằng chứng |  | (theo loại đề nghị) |  | 200 |
| API-19-050 | `POST /approval-requests/{approvalId}/decisions` | Duyệt, từ chối, hoặc người lập rút đề nghị |  | provider-activate; partner-approve; refund-approve; discrepancy-approve; recon-reopen-approve; migration-switch (theo loại) | If-Match | 200 |

: API quản trị /api/payment/v1 · Phê duyệt

**Giao dịch**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-051 | `GET /transactions` | Danh sách, tìm từ khóa, tra cứu nâng cao | 049, 050 | transaction-read |  | 200 |
| API-19-052 | `GET /transactions/{transactionId}` | Chi tiết giao dịch (PII che theo quyền) | 051, 055 | transaction-read; transaction-read-pii |  | 200 |
| API-19-053 | `POST /transactions/{transactionId}/status-syncs` | Đồng bộ trạng thái thủ công | 037 | transaction-sync |  | 200 |
| API-19-054 | `GET /transactions/{transactionId}/events` | Dòng thời gian trạng thái | 028, 051 | transaction-read |  | 200 |
| API-19-055 | `POST /transactions/{transactionId}/cancellations` | Cán bộ hủy giao dịch | 026 | transaction-cancel | If-Match | 200 |

: API quản trị /api/payment/v1 · Giao dịch

**Thông báo IPN**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-056 | `GET /callbacks` | Danh sách IPN theo trạng thái xử lý, kết quả xác minh | 032 | callback-read |  | 200 |
| API-19-057 | `GET /callbacks/{callbackId}` | Chi tiết IPN (nguyên văn đã che) | 032 | callback-read |  | 200 |
| API-19-058 | `POST /callbacks/{callbackId}/replays` | Xử lý lại IPN | 032 | callback-replay |  | 202 |

: API quản trị /api/payment/v1 · Thông báo IPN

**Hoàn tiền**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-059 | `POST /refunds` | Kế toán lập yêu cầu hoàn | 038 | refund-create | Idem | 201 |
| API-19-060 | `GET /refunds` | Danh sách yêu cầu hoàn | 041 | refund-read |  | 200 |
| API-19-061 | `GET /refunds/{refundId}` | Chi tiết, lịch sử yêu cầu hoàn | 041 | refund-read |  | 200 |
| API-19-062 | `POST /refunds/{refundId}/executions` | Thực thi lại, chuyển thủ công, hoặc ghi nhận chứng từ hoàn thủ công | 040 | refund-execute | If-Match | 200 |

: API quản trị /api/payment/v1 · Hoàn tiền

**Đối soát**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-063 | `POST /reconciliation-sessions` | Tạo phiên thủ công cho một ngày | 042 | recon-run | Idem | 201 |
| API-19-064 | `GET /reconciliation-sessions` | Danh sách phiên | 042, 047 | discrepancy-read |  | 200 |
| API-19-065 | `POST /reconciliation-sessions/{sessionId}/files` | Tải file đối soát lên | 043 | recon-upload | If-Match | 202 |
| API-19-066 | `POST /reconciliation-sessions/{sessionId}/runs` | Thu thập lại, chạy lại so khớp | 043, 044 | recon-run | If-Match | 202 |
| API-19-067 | `GET /reconciliation-sessions/{sessionId}` | Chi tiết phiên, tổng hợp hai phía | 044, 047 | discrepancy-read |  | 200 |
| API-19-068 | `POST /reconciliation-sessions/{sessionId}/closures` | Chốt phiên | 047, 048 | recon-close | If-Match | 202 |
| API-19-069 | `POST /reconciliation-sessions/{sessionId}/reopen-requests` | Đề nghị mở lại phiên | 047 | recon-close | If-Match | 201 |
| API-19-070 | `GET /reconciliation-sessions/{sessionId}/items` | Dòng đối soát của lần chạy | 044 | discrepancy-read |  | 200 |

: API quản trị /api/payment/v1 · Đối soát

**Chênh lệch**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-071 | `GET /discrepancies` | Danh sách chênh lệch, lọc loại, tuổi, người phụ trách | 045 | discrepancy-read |  | 200 |
| API-19-072 | `PATCH /discrepancies/{discrepancyId}` | Giao việc, nhận việc, chuyển cấp NCC, ghi chú | 045 | discrepancy-handle | If-Match | 200 |
| API-19-073 | `POST /discrepancies/{discrepancyId}/resolution-proposals` | Đề xuất cách xử lý (tạo đề nghị phê duyệt) | 046 | discrepancy-handle | If-Match | 201 |
| API-19-074 | `GET /discrepancies/{discrepancyId}` | Chi tiết chênh lệch | 045 | discrepancy-read |  | 200 |

: API quản trị /api/payment/v1 · Chênh lệch

**Nhật ký và webhook**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-075 | `GET /integration-logs` | Danh sách nhật ký tích hợp | 054 | log-read |  | 200 |
| API-19-076 | `GET /integration-logs/{logId}` | Chi tiết một lượt trao đổi, liên kết vết PH-13 | 054, 055 | log-read |  | 200 |
| API-19-077 | `GET /webhook-deliveries` | Danh sách lượt gửi webhook | 062 | webhook-read |  | 200 |
| API-19-078 | `POST /webhook-deliveries/{deliveryId}/resends` | Gửi lại thủ công | 062 | webhook-resend | If-Match | 202 |
| API-19-079 | `GET /webhook-deliveries/{deliveryId}` | Chi tiết lượt gửi và các lần thử | 062 | webhook-read |  | 200 |

: API quản trị /api/payment/v1 · Nhật ký và webhook

**Dashboard và báo cáo**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-080 | `GET /dashboards/overview` | Số liệu dashboard tổng quan | 056 | dashboard-read |  | 200 |
| API-19-081 | `GET /dashboards/channels` | Số liệu dashboard kênh thanh toán 30 ngày | 057 | dashboard-read |  | 200 |
| API-19-082 | `GET /reports/{reportCode}` | Dữ liệu một báo cáo định kỳ theo kỳ | 058 | report-read |  | 200 |
| API-19-083 | `POST /export-jobs` | Tạo tác vụ xuất: danh sách giao dịch, báo cáo, biên bản đối soát | 048, 052, 058 | transaction-export; report-export (theo loại) | Idem | 202 |
| API-19-084 | `GET /export-jobs/{jobId}` | Tiến độ và đường tải kết quả (chỉ người tạo) | 048, 052, 058 | transaction-export; report-export |  | 200 |

: API quản trị /api/payment/v1 · Dashboard và báo cáo

**Cấu hình, tệp, di trú**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-085 | `GET /config` | Cấu hình hiện hành và lịch sử phiên bản | 063 | config-read |  | 200 |
| API-19-086 | `POST /config/versions` | Tạo phiên bản cấu hình mới có ngày hiệu lực | 063 | config-write | If-Match | 201 |
| API-19-087 | `POST /files` | Tải lên tệp đính kèm (chứng từ, tài liệu hoàn tiền, chênh lệch) | 038, 040, 045 | refund-create; refund-execute; discrepancy-handle (theo mục đích) | Idem | 201 |
| API-19-088 | `GET /files/{fileId}` | Siêu dữ liệu và đường tải có hạn của tệp | 040, 045, 048, 065 | theo đối tượng sở hữu |  | 200 |
| API-19-089 | `POST /migration-runs` | Chạy lô nhập dữ liệu hệ cũ hoặc đối chiếu sau di trú | 065, 068 | migration-run | Idem | 202 |
| API-19-090 | `GET /migration-runs` | Danh sách lần chạy di trú, kết quả đối chiếu, đường tải báo cáo lỗi | 065, 068 | migration-run |  | 200 |

: API quản trị /api/payment/v1 · Cấu hình, tệp, di trú

**Nhà cung cấp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-091 | `GET /providers/{providerId}/result-mappings` | Xem bảng ánh xạ mã kết quả hiện hành, lịch sử, mã chưa ánh xạ (đề xuất) | 069 | provider-read |  | 200 |
| API-19-092 | `POST /providers/{providerId}/result-mapping-changes` | Lập đề nghị đổi bảng ánh xạ mã kết quả (đề xuất) | 069 | provider-write | If-Match | 201 |

: API quản trị /api/payment/v1 · Nhà cung cấp

#### API đối tác `/api/payment-partner/v1`


**Thanh toán**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-101 | `POST /payments` | Tạo giao dịch, trả `transactionCode`, `paymentUrl`, `expiresAt` | 022, 023, 024, 033, 034 | partner-pay-create | Idem bắt buộc | 201 |
| API-19-102 | `GET /payments/{transactionCode}` | Truy vấn trạng thái theo mã giao dịch | 035 | partner-pay-read |  | 200 |
| API-19-103 | `GET /payments?partnerOrderId=` | Truy vấn theo mã đơn hàng (mọi lượt giao dịch của mã đó) | 035 | partner-pay-read |  | 200 |
| API-19-104 | `POST /payments/{transactionCode}/cancellations` | Đối tác hủy giao dịch chưa thanh toán | 026 | partner-pay-create | Idem bắt buộc | 200 |

: API đối tác /api/payment-partner/v1 · Thanh toán

**Hoàn tiền đối tác**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-105 | `POST /refunds` | Đối tác lập yêu cầu hoàn | 038 | partner-refund-create | Idem bắt buộc | 201 |
| API-19-106 | `GET /refunds/{refundCode}` | Truy vấn yêu cầu hoàn | 041 | partner-pay-read |  | 200 |

: API đối tác /api/payment-partner/v1 · Hoàn tiền đối tác

**Đối soát đối tác**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-107 | `GET /reconciliation-reports?date=` | Tải kết quả đối soát phần của đối tác cho phiên đã chốt | 048 | partner-recon-read |  | 200 |
| API-19-108 | `GET /services` | Danh sách dịch vụ được gán và hạn mức còn lại trong ngày | 020, 022 | partner-pay-read |  | 200 |
| API-19-109 | `GET /notifications?after=` | Kéo các thông báo đã phát (dự phòng khi webhook lỡ), theo con trỏ | 060, 062 | partner-pay-read |  | 200 |

: API đối tác /api/payment-partner/v1 · Đối soát đối tác

**Tương thích hệ cũ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-110 | `POST /legacy-compat/{operation}` | Mặt nạ tương thích hợp đồng API hệ cũ, ánh xạ sang API-19-101…103 (đường dẫn thật theo hợp đồng cũ, OQ-19-17) | 067 | partner-pay-create | Idem | 200 |

: API đối tác /api/payment-partner/v1 · Tương thích hệ cũ

#### API callback `/api/payment-callback/v1`


**Callback PayGov**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |
|---|---|---|---|---|---|---|
| API-19-201 | `POST /paygov/{connectionKey}/ipn` | Nhận IPN kết quả thanh toán | 029, 030, 031 | — |  | 200 |
| API-19-202 | `GET /paygov/{connectionKey}/return` | Người nộp quay về: xác minh tham số, hiển thị UI-19-28, chuyển về đối tác | 025 | — |  | 200 |
| API-19-203 | `POST /paygov/{connectionKey}/refund-ipn` | Nhận kết quả hoàn tiền (nếu PayGov hỗ trợ, OQ-19-06) | 041 | — |  | 200 |
| API-19-204 | `POST /paygov/{connectionKey}/reconciliation-notices` | Nhận thông báo dữ liệu đối soát sẵn sàng (nếu PayGov hỗ trợ, OQ-19-07) | 043 | — |  | 200 |
| API-19-205 | `GET /result-status` | Trạng thái rút gọn cho trang UI-19-28 thăm dò (bổ sung 0.2) | 025 | — |  | 200 |

: API callback /api/payment-callback/v1 · Callback PayGov
<!-- gen:endpoints:end -->

### 3.1. Luồng đối tác thu tiền

Luồng dưới đây là con đường chính của một khoản thu, từ lúc HTTT đối tác tạo giao dịch tới lúc nhận webhook kết quả. Đơn vị phát triển HTTT cần nắm luồng này trước khi đọc đặc tả từng endpoint.

```{.mermaid caption="Trình tự đối tác thu tiền qua PH-19 và PayGov"}
sequenceDiagram
    autonumber
    participant HT as HTTT đối tác
    participant GW as APISIX (apisix-ext)
    participant PAY as dh-payment
    participant PG as PayGov
    HT->>GW: POST /payments (Idempotency-Key, token mTLS)
    GW->>PAY: chuyển tiếp, traceparent
    PAY->>PAY: kiểm tra BR-19-004, ghi giao dịch CREATED, outbox
    PAY->>PG: khởi tạo thanh toán
    PG-->>PAY: paymentUrl
    PAY-->>HT: 201 transactionCode, status PENDING, paymentUrl
    HT->>HT: chuyển người nộp tới paymentUrl
    PG->>PAY: POST /paygov/{connectionKey}/ipn (ký)
    PAY-->>PG: 200 responseCode 00 (sau khi ghi callback_inbox)
    PAY->>PAY: InboxProcessor: SUCCEEDED, outbox EVT-19-07
    PAY->>HT: webhook transaction.succeeded (X-Datahub-Signature, sequence)
    HT-->>PAY: 2xx
    Note over HT,PAY: Lỡ webhook: GET /payments/{transactionCode} hoặc GET /notifications?after=
```

Điểm cần thấy ở hình: PH-19 trả lời PayGov ngay sau khi ghi nguyên văn IPN vào hộp nhận, xử lý nghiệp vụ chạy sau, và đối tác chỉ biết kết quả qua webhook có chữ ký hoặc qua truy vấn chủ động, không qua việc người nộp quay về.

Hướng dẫn cho đơn vị phát triển HTTT:

1. Sinh `Idempotency-Key` mới cho mỗi **ý định** thu tiền và giữ lại; gửi lại đúng khóa khi gặp timeout, ERR-19-004, ERR-19-019 hoặc lỗi mạng. Không sinh khóa mới khi thử lại.
2. Không coi người nộp quay về `returnUrl` là đã thanh toán. Kết quả cuối là webhook `transaction.succeeded` hoặc truy vấn API-19-102 có `status = SUCCEEDED`.
3. Webhook có thể đến trùng hoặc lệch thứ tự: bỏ trùng theo `Webhook-Id`, bỏ qua sự kiện có `sequence` nhỏ hơn hoặc bằng số đã xử lý cho cùng `transactionCode`.
4. Kiểm chữ ký trước khi đọc thân: `HMAC_SHA256(secret, Webhook-Id + "." + t + "." + thân_nguyên_văn)` so với mọi giá trị `v1` trong `X-Datahub-Signature`; từ chối khi `|now − t| > 300` giây.
5. Một `partnerOrderId` chỉ có một giao dịch đang hiệu lực (ERR-19-015 kèm `existingTransactionCode`); muốn thu lại sau khi giao dịch `FAILED`, `EXPIRED`, `CANCELLED` thì gọi API-19-101 với khóa mới.

### 3.2. Phản hồi callback

PH-19 trả lời PayGov **sau khi** đã ghi nguyên văn vào `callback_inbox`, trước khi xử lý nghiệp vụ (ADR-042). Ánh xạ mã HTTP dưới đây áp dụng khi đặc tả PayGov không quy định khác (giả định, OQ-19-03):

| Tình huống | HTTP | Thân | Mã nội bộ |
|---|---|---|---|
| Hợp lệ, đã tiếp nhận (kể cả trùng nguyên văn, kể cả bị cách ly) | 200 | `{"responseCode": "00"}` | — hoặc ERR-19-028 |
| Chữ ký sai | 401 | `{"responseCode": "97"}` | ERR-19-024 |
| Dấu thời gian lệch quá ±5 phút | 401 | `{"responseCode": "97"}` | ERR-19-025 |
| Nonce đã gặp, nội dung khác | 409 | `{"responseCode": "02"}` | ERR-19-026 |
| `connectionKey` không tồn tại, IP hoặc chứng thư không được phép | 403 | không thân | ERR-19-027 |

: Phản hồi callback

API-19-202 (người nộp quay về) không bao giờ đổi trạng thái giao dịch thành công chỉ dựa trên tham số trình duyệt; nếu chữ ký hợp lệ và kết quả là thành công, PH-19 chỉ lên lịch truy vấn bù ngay (FR-19-025).

## 4. Danh mục sự kiện

Sự kiện ghi vào `outbox_event` cùng giao dịch CSDL với thay đổi trạng thái, phát lên Kafka bằng Debezium hoặc `OutboxRelay` (OQ-19-29). CloudEvents 1.0 chế độ nhị phân: tiêu đề `ce_id`, `ce_type` (`vn.datahub.payment.{thực-thể}.{sự-kiện}.v1`), `ce_source` (`/t68/payment`), `ce_subject` (mã nghiệp vụ), `ce_time`, `ce_tenantid`, `ce_sequence`, `dhtenant`, `traceparent`; thân là `data`. Mỗi payload có `eventId`, `occurredAt`, `tenantId`, `traceId`, `sequence` (BR-19-021), không có dữ liệu cá nhân người nộp.

<!-- gen:events:start -->
| Mã | Topic | Thân | Giữ, phân vùng | Webhook |
|---|---|---|---|---|
| EVT-19-01 | `{tenant}.payment.provider.status-changed.v1` | `ProviderStatusChanged` | 7 ngày, 3 |  |
| EVT-19-02 | `{tenant}.payment.provider.health-changed.v1` | `ProviderHealthChanged` | 7 ngày, 3 |  |
| EVT-19-03 | `{tenant}.payment.service.status-changed.v1` | `ServiceStatusChanged` | 7 ngày, 3 |  |
| EVT-19-04 | `{tenant}.payment.partner.status-changed.v1` | `PartnerStatusChanged` | 7 ngày, 3 |  |
| EVT-19-05 | `{tenant}.payment.transaction.created.v1` | `TransactionCreated` | 30 ngày, 12 |  |
| EVT-19-06 | `{tenant}.payment.transaction.pending.v1` | `TransactionPending` | 30 ngày, 12 |  |
| EVT-19-07 | `{tenant}.payment.transaction.succeeded.v1` | `TransactionSucceeded` | 30 ngày, 12 | có |
| EVT-19-08 | `{tenant}.payment.transaction.failed.v1` | `TransactionFailed` | 30 ngày, 12 | có |
| EVT-19-09 | `{tenant}.payment.transaction.cancelled.v1` | `TransactionCancelled` | 30 ngày, 12 | có |
| EVT-19-10 | `{tenant}.payment.transaction.expired.v1` | `TransactionExpired` | 30 ngày, 12 | có |
| EVT-19-11 | `{tenant}.payment.refund.requested.v1` | `RefundRequested` | 30 ngày, 6 |  |
| EVT-19-12 | `{tenant}.payment.refund.decided.v1` | `RefundDecided` | 30 ngày, 6 | có |
| EVT-19-13 | `{tenant}.payment.refund.succeeded.v1` | `RefundSucceeded` | 30 ngày, 6 | có |
| EVT-19-14 | `{tenant}.payment.refund.failed.v1` | `RefundFailed` | 30 ngày, 6 | có |
| EVT-19-15 | `{tenant}.payment.reconciliation.matched.v1` | `ReconciliationMatched` | 30 ngày, 3 |  |
| EVT-19-16 | `{tenant}.payment.reconciliation.closed.v1` | `ReconciliationClosed` | 30 ngày, 3 | có |
| EVT-19-17 | `{tenant}.payment.discrepancy.detected.v1` | `DiscrepancyDetected` | 30 ngày, 3 |  |
| EVT-19-18 | `{tenant}.payment.discrepancy.resolved.v1` | `DiscrepancyResolved` | 30 ngày, 3 |  |

: Danh mục sự kiện
<!-- gen:events:end -->

Tám sự kiện cột "Webhook" cũng được gửi tới đầu nhận của đối tác sở hữu giao dịch ở dạng CloudEvent cấu trúc (`application/cloudevents+json`), cùng `id` và `data` với sự kiện Kafka; định nghĩa ở mục `webhooks` của `openapi-payment-partner.yaml`. Việc HTTT đối tác đọc trực tiếp topic Kafka (qua ACL tiền tố của PH-10) hay chỉ nhận webhook chờ OQ-19-15; thiết kế hiện tại chỉ cam kết webhook.

Ví dụ webhook `transaction.succeeded` (giả lập):

```json
{
  "specversion": "1.0",
  "id": "019379a2-7c41-7d3e-9a52-6f1c0b8e2d44",
  "type": "vn.datahub.payment.transaction.succeeded.v1",
  "source": "/t68/payment",
  "subject": "T68261126K7M2Q9XW4P",
  "time": "2026-11-26T03:07:12Z",
  "datacontenttype": "application/json",
  "tenantid": "T68",
  "sequence": 3,
  "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
  "data": {
    "eventId": "019379a2-7c41-7d3e-9a52-6f1c0b8e2d44",
    "occurredAt": "2026-11-26T03:07:12Z",
    "tenantId": "T68",
    "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
    "sequence": 3,
    "transactionId": "019379a0-11b2-7c55-8f0e-2a9b7c6d5e41",
    "transactionCode": "T68261126K7M2Q9XW4P",
    "partnerCode": "MCDT-T68",
    "partnerOrderId": "H68.12-261121-0042",
    "serviceCode": "LPTB-OTO",
    "amount": 2350000000,
    "paidAt": "2026-11-26T03:07:05Z",
    "providerReference": "PG-7781234",
    "channelCode": "ATM",
    "bankCode": "VCB",
    "latePaid": false,
    "metadata": {"hoSoId": "42"}
  }
}
```

Tiêu đề đi kèm: `Webhook-Id: 019379a2-7c41-7d3e-9a52-6f1c0b8e2d44`, `Webhook-Timestamp: 1795662432`, `X-Datahub-Signature: t=1795662432,v1=5d1f…` (64 ký tự hex).

## 5. Hợp đồng với phân hệ khác và bên ngoài

| Bên | Hướng | Giao diện | Ghi chú |
|---|---|---|---|
| PayGov (VPCP) | Ra | Adapter `adapter.paygov` qua `apisix-int` cửa ra: khởi tạo, truy vấn, hủy, hoàn, lấy dữ liệu đối soát | Giả định chờ OQ-19-01…08; timeout khởi tạo 10 giây, mạch ngắt (SDD §4.4) |
| PayGov | Vào | API-19-201…204 | §3.2 |
| HTTT đối tác | Vào, ra | API-19-101…110; webhook | §3.1 |
| PH-03 (APISIX) | — | Tuyến `/api/payment-partner/v1` định tuyến strangler theo `routingMode` của đối tác (EVT-19-04): `LEGACY` sang hệ cũ, `SHADOW` sang hệ cũ và bản sao tới PH-19, `DATAHUB` sang PH-19 (ADR-049) | `legacyAppCode` ánh xạ ứng dụng cũ |
| PH-07 | Ra | Tra mã `DM_LOAI_PHI`, `DM_CO_QUAN_THU`, `DM_LINH_VUC_TTHC`, `DM_THU_TUC_HANH_CHINH`, `DM_NGAN_HANG`, `DM_LY_DO_HOAN_TIEN` (API-19-028 là mặt tiền cho giao diện) | Đệm 10 phút; PH-07 không phản hồi thì tạo mới bị chặn ERR-19-039 |
| PH-12 | Ra | Cấp, thu hồi client đối tác (API-19-037, 038); vai trò, quyền | Realm `dh-{tenant}` |
| PH-13 | Ra | Kiểm toán `t68.audit.recorded.v1` qua outbox; vết OTLP | Ghi kiểm toán lỗi thì thao tác hủy (ERR-19-050) |
| PH-16, lớp dữ liệu dùng chung | Ra | EVT-19-05, 07, 13, 15, 16 | Không có dữ liệu cá nhân |
| PH-18 | Ra | Cảnh báo từ EVT-19-02, 17 và metric | Kênh thông báo do PH-18 quản |
| PH-20 | Vào | Sự kiện vòng đời tenant: khởi tạo cấu hình, bật, tắt phân hệ (FR-19-064) | Không có API REST |

: Hợp đồng với phân hệ khác và bên ngoài

## 6. Bảng mã lỗi ERR-19

Bảng chính thức, sinh từ khung §12. Câu hiển thị cho người dùng nằm ở D03-06-PH19; `detail` của máy chủ có thể cụ thể hơn `title` nhưng không chứa dữ liệu cá nhân, bí mật hay thông tin nội bộ. Thứ tự kiểm tra khi nhiều lỗi cùng xảy ra theo BR-19-004. Với lỗi "Có" thể thử lại, phản hồi có `Retry-After` khi máy chủ biết thời điểm phù hợp.

<!-- gen:errors:start -->
| Mã | HTTP | Tiêu đề | Khi nào | Thử lại |
|---|---|---|---|---|
| ERR-19-001 | 400 | Yêu cầu không hợp lệ | Thiếu trường bắt buộc, sai kiểu, sai định dạng, vượt độ dài | Sau khi sửa |
| ERR-19-002 | 400 | Thiếu Idempotency-Key | API ghi của đối tác không có header hoặc header sai định dạng (BR-19-006) | Sau khi sửa |
| ERR-19-003 | 422 | Idempotency-Key đã dùng cho nội dung khác | Cùng khóa nhưng băm nội dung khác bản ghi cũ | Không |
| ERR-19-004 | 409 | Yêu cầu cùng Idempotency-Key đang được xử lý | Yêu cầu trước với cùng khóa chưa xong | Có |
| ERR-19-005 | 403 | Đối tác không ở trạng thái hoạt động | Đối tác `DRAFT`, `PENDING_APPROVAL`, `SUSPENDED` hoặc `TERMINATED` gọi API tạo giao dịch, hoàn tiền | Không |
| ERR-19-006 | 409 | Đối tác chưa chuyển sang Datahub | Đối tác ở chế độ `LEGACY` gọi trực tiếp API của PH-19 (BR-19-034) | Không |
| ERR-19-007 | 404 | Dịch vụ không tồn tại | Mã dịch vụ không có trong tenant | Sau khi sửa |
| ERR-19-008 | 422 | Dịch vụ không hoạt động | Dịch vụ không `ACTIVE` | Không |
| ERR-19-009 | 403 | Dịch vụ chưa được gán cho đối tác | Không có `partner_service_grant` còn hiệu lực | Sau khi sửa |
| ERR-19-010 | 422 | Số tiền không hợp lệ | Số tiền ≤ 0, không nguyên, vượt trần BR-19-001 | Sau khi sửa |
| ERR-19-011 | 422 | Số tiền ngoài khoảng cho phép của dịch vụ | Ngoài `[min_amount, max_amount]` | Sau khi sửa |
| ERR-19-012 | 422 | Vượt hạn mức mỗi giao dịch | Lớn hơn `max_amount_per_txn` của đối tác | Sau khi sửa |
| ERR-19-013 | 422 | Vượt hạn mức trong ngày | Vượt số giao dịch hoặc tổng tiền trong ngày (BR-19-005) | Có (ngày hôm sau) |
| ERR-19-014 | 422 | Loại tiền không được hỗ trợ | `currency` khác `VND` | Sau khi sửa |
| ERR-19-015 | 409 | Mã đơn hàng đã có giao dịch | Trùng `partner_order_id` theo BR-19-007; `detail` kèm mã giao dịch hiện có | Không |
| ERR-19-016 | 422 | Địa chỉ quay về không được phép | `return_url` không thuộc danh sách đăng ký của đối tác | Sau khi sửa |
| ERR-19-017 | 503 | Kênh thanh toán tạm thời không khả dụng | NCC `SUSPENDED` hoặc mạch ngắt đang mở (BR-19-009, 013); không ghi giao dịch | Có |
| ERR-19-018 | 502 | Nhà cung cấp từ chối khởi tạo thanh toán | NCC trả lỗi xác định; giao dịch `FAILED`; `detail` kèm mã kết quả đã ánh xạ | Không |
| ERR-19-019 | 504 | Chưa xác định được kết quả khởi tạo | Timeout hoặc lỗi không xác định khi gọi NCC; giao dịch giữ `CREATED` (BR-19-012) | Có (cùng khóa; hoặc truy vấn API-19-102) |
| ERR-19-020 | 404 | Không tìm thấy tài nguyên | Tài nguyên không tồn tại hoặc nằm ngoài phạm vi truy cập của bên gọi (khác tenant, khác đối tác); không phân biệt hai trường hợp để không lộ thông tin | Không |
| ERR-19-021 | 409 | Chuyển trạng thái không hợp lệ | Thao tác không được máy trạng thái (mục 7) cho phép ở trạng thái hiện tại | Không |
| ERR-19-022 | 422 | Thông tin xác thực NCC thiếu hoặc hết hạn | Kiểm tra kết nối, giao dịch thử hoặc kích hoạt khi chưa gắn đủ tham chiếu bí mật hoặc đã hết hạn | Sau khi sửa |
| ERR-19-023 | 429 | Vượt tần suất đồng bộ thủ công | Đồng bộ một giao dịch quá 1 lần mỗi 60 giây hoặc 10 lần mỗi ngày | Có |
| ERR-19-024 | 401 | Chữ ký callback không hợp lệ | Chữ ký IPN không xác minh được bằng chứng thư `ACTIVE` hoặc `NEXT` | Không |
| ERR-19-025 | 401 | Callback quá hạn | Dấu thời gian lệch quá ±5 phút (NFR-19-020) | Không |
| ERR-19-026 | 409 | Callback bị phát lại | Nonce đã gặp nhưng nội dung khác (IPN lặp đúng nội dung được trả thành công, không dùng mã này) | Không |
| ERR-19-027 | 403 | Nguồn callback không được phép | IP nguồn hoặc chứng thư mTLS không thuộc danh sách cho phép; `connectionKey` không tồn tại | Không |
| ERR-19-028 | 200 | Callback bị cách ly | IPN hợp lệ nhưng sai số tiền, sai tham chiếu, không tìm thấy giao dịch hoặc trái trạng thái (BR-19-015); NCC nhận phản hồi đã tiếp nhận, mã này chỉ ghi nội bộ | Không |
| ERR-19-029 | 409 | Giao dịch không đủ điều kiện hoàn tiền | Trạng thái không phải `SUCCEEDED`/`PARTIALLY_REFUNDED`, là giao dịch thử, hoặc đang có yêu cầu hoàn chưa kết thúc | Không |
| ERR-19-030 | 422 | Số tiền hoàn vượt số còn được hoàn | Tổng hoàn vượt số tiền gốc (BR-19-022) | Sau khi sửa |
| ERR-19-031 | 422 | Quá hạn hoàn tiền | Quá số ngày cho phép kể từ `paid_at` | Không |
| ERR-19-032 | 422 | Hoàn tiền chưa được bật | Tenant tắt hoàn tiền, hoặc chế độ thực thi không phù hợp thao tác | Không |
| ERR-19-033 | 403 | Vi phạm nguyên tắc tách nhiệm | Người duyệt trùng người lập, trùng người duyệt cấp trước, hoặc người xác nhận hoàn thủ công trùng người duyệt (mục 13.4) | Không |
| ERR-19-034 | 409 | Đề nghị phê duyệt không còn chờ quyết định | Đề nghị đã được duyệt, từ chối, rút hoặc hết hạn | Không |
| ERR-19-035 | 422 | Checklist kích hoạt chưa đạt | Gửi đề nghị kích hoạt hoặc duyệt khi BR-19-010 không đạt; `detail` liệt kê mục thiếu | Sau khi sửa |
| ERR-19-036 | 409 | Còn giao dịch hoặc phiên đối soát dở | Ngừng hẳn NCC, dịch vụ khi vi phạm BR-19-027 | Có (khi hết việc dở) |
| ERR-19-037 | 409 | Còn dữ liệu phụ thuộc | Xóa NCC, dịch vụ đã có giao dịch; xóa nhóm còn dịch vụ | Không |
| ERR-19-038 | 409 | Mã đã tồn tại | Trùng mã NCC, nhóm, dịch vụ, đối tác trong tenant | Sau khi sửa |
| ERR-19-039 | 422 | Mã danh mục không hợp lệ | Mã PH-07 không tồn tại hoặc hết hiệu lực; hoặc PH-07 không kiểm tra được khi tạo mới (mục 1.5) | Sau khi sửa |
| ERR-19-040 | 409 | Phiên đối soát đã tồn tại | Tạo phiên cho (NCC, ngày) đã có phiên | Không |
| ERR-19-041 | 422 | File đối soát không hợp lệ | Sai định dạng, sai mã băm, sai NCC hoặc sai ngày | Sau khi sửa |
| ERR-19-042 | 409 | Còn chênh lệch chưa xử lý | Chốt phiên khi còn chênh lệch chưa `RESOLVED` | Sau khi sửa |
| ERR-19-043 | 409 | Phiên đối soát đã chốt | Thay đổi dữ liệu của phiên `CLOSED` | Không |
| ERR-19-044 | 422 | Địa chỉ webhook không hợp lệ | Không dùng `https`, trỏ tới địa chỉ nội bộ, riêng hoặc loopback | Sau khi sửa |
| ERR-19-045 | 412 | Dữ liệu đã bị thay đổi | `If-Match` không khớp `version` hiện tại | Sau khi tải lại |
| ERR-19-046 | 403 | Không có quyền thực hiện | OPA từ chối: thiếu `PERM-19-*` cần thiết | Không |
| ERR-19-047 | 422 | Kết quả xuất vượt giới hạn | Kết quả lọc vượt 1.000.000 dòng (NFR-19-009) | Sau khi sửa |
| ERR-19-048 | 429 | Vượt giới hạn tốc độ | Vượt hạn mức gọi API của client hoặc tenant | Có |
| ERR-19-049 | 503 | Phân hệ thanh toán chưa bật cho tenant | PH-20 chưa bật hoặc đã tạm ngừng PH-19 cho tenant (FR-19-064) | Không |
| ERR-19-050 | 503 | Không ghi được nhật ký kiểm toán | Không ghi được bản ghi kiểm toán vào outbox; thao tác bị hủy (BR-19-029) | Có |
| ERR-19-099 | 500 | Lỗi hệ thống | Lỗi không lường trước; `detail` không chứa thông tin nội bộ, chỉ có `traceId` | Có |

: Bảng mã lỗi ERR-19
<!-- gen:errors:end -->

## 7. Kiểm tra hợp đồng trong CI

Bốn tệp hợp đồng được kiểm ở cổng CI-5 của D04-02:

- `ph19/tools/check_contracts.py`: hợp lệ OpenAPI 3.1 (`openapi-spec-validator`); mọi ví dụ (thân yêu cầu, lỗi, lược đồ) khớp lược đồ bằng JSON Schema 2020-12; mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission` (trừ callback); lệnh `PATCH`, `PUT`, `DELETE` có `If-Match`; mọi `POST` đối tác có `Idempotency-Key`.
- `@asyncapi/parser` 3 cho `asyncapi-payment.yaml`.
- Spectral với bộ luật dự án khi bộ luật được đưa vào repo; `oasdiff` so với `main`, chặn thay đổi phá vỡ trong `v1`.
- Sinh lại bằng `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` rồi `git diff --exit-code`: phát hiện YAML bị sửa tay hoặc khung đổi mà chưa sinh lại.
- Lược đồ sự kiện kiểm tương thích ngược ở Apicurio.

Kiểm thử hợp đồng phía máy chủ (sinh từ OpenAPI) chạy ở CI-3 trên `dh-payment` với Testcontainers; client TypeScript của console sinh bằng `openapi-typescript` ở CI-6. Bộ kiểm thử mẫu cho đối tác (Postman/Bruno) và bộ giả lập PayGov (adapter `MOCK`, sinh IPN ký thật) sinh từ cùng hợp đồng, phát hành cùng sandbox cho đơn vị phát triển HTTT.

Tại thời điểm viết (26/11/2026), ba tệp OpenAPI qua `openapi-spec-validator` và `check_contracts.py` (107 ví dụ khớp lược đồ), `asyncapi-payment.yaml` qua `@asyncapi/parser` 3 không lỗi, không cảnh báo.

## 8. Ánh xạ từ hệ cũ

Hợp đồng API của Payment cũ chưa có trong bộ tài liệu được cung cấp; bảng dưới dựa trên tên trường hệ cũ ở D00-03 §4.6 và BRD D02-01-PH19 §3 (giả định, OQ-19-32). Mặt nạ tương thích API-19-110 (đợt Sau, FR-19-067) dùng đúng bảng này.

| Hệ cũ | API mới | Ghi chú |
|---|---|---|
| Nhận yêu cầu thanh toán (`order_id`, `amount`, `order_info`, `return_url`, `ip_address`, `app_code`) | API-19-101: `partnerOrderId`, `amount`, `description`, `returnUrl`, `clientIp`; đối tác lấy từ token | `app_code` thành `legacyAppCode` của đối tác; bắt buộc thêm `Idempotency-Key`, `serviceCode` |
| Tra cứu giao dịch theo mã | API-19-102, 103 | Thêm tra theo `partnerOrderId` (mọi lượt) |
| Nhận kết quả từ PayGov | API-19-201 | Ghi nguyên văn trước, xác minh, xử lý bất đồng bộ |
| Trả kết quả cho ứng dụng (gọi lại không ký) | Webhook ký HMAC + API-19-109 | Có số thứ tự, gửi lại, kéo dự phòng |
| Hoàn tiền (trạng thái `REFUND_*`) | API-19-105, 106 (đối tác); API-19-059…062 (cán bộ) | Có phê duyệt bốn mắt |
| Màn tra cứu giao dịch, dashboard | API-19-051, 052, 080, 081 | Thêm lọc nâng cao, xuất 1 triệu dòng |
| Quản lý provider, service group, service, partner | API-19-001…047 | Thêm vòng đời, checklist kích hoạt, gán dịch vụ và hạn mức |

: Ánh xạ API Payment hệ cũ sang API PH-19

## 9. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| OQ-19-34 | `PUT /partners/{partnerId}/service-grants/{serviceId}` vừa tạo vừa thay: có tách `POST` tạo để `If-Match` luôn bắt buộc không | Giữ `PUT` như khung; bắt buộc `If-Match` khi đã có gán, ghi trong mô tả |
| OQ-19-35 | Có cần cho đối tác đăng ký đầu nhận webhook qua API đối tác (tự phục vụ) không | Không ở MVP; cán bộ ADM đăng ký qua API-19-043 sau khi đối tác gửi văn bản |
| OQ-19-36 | Có công bố hợp đồng API đối tác lên PH-02 (cổng API) như các API dùng chung khác không | Có, khi PH-02 sẵn sàng; tới lúc đó phát hành tệp OpenAPI kèm sandbox |

: Câu hỏi mở của tập API PH-19

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI, không sửa tay. PH-19 có ba tệp OpenAPI nên trước tiên gộp chúng thành một tệp tạm (đường dẫn kèm tiền tố nhóm, quyền viết đủ `PERM-19-*`) rồi sinh:

```bash
python3 03-thiet-ke/api/ph19/tools/gop_openapi.py /tmp/ph19.yaml 03-thiet-ke/api/ph19/openapi-payment-{admin,partner,callback}.yaml
python3 build/tools/sinh_dac_ta_api.py /tmp/ph19.yaml 03-thiet-ke/api/D03-04-PH19-api-thanh-toan.md
```

Mỗi endpoint một bảng đặc tả 10 mục: mục đích, phương thức và đường dẫn, quyền, FR hiện thực, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú. Câu thông báo người dùng nhìn thấy cho từng mã lỗi ở D03-06-PH19 và FRS chương 9.

<!-- gen:dac-ta-api:start -->

### Nhà cung cấp

#### API-19-001 · Danh sách NCC, lọc trạng thái, sức khỏe, từ khóa

::: dac-ta
**Mục đích.** Danh sách NCC, lọc trạng thái, sức khỏe, từ khóa.

**Phương thức, đường dẫn.** `GET /api/payment/v1/providers`.

**Quyền.** `PERM-19-provider-read`.

**FR hiện thực.** FR-19-007.

**Tham số.** `status` (query, array, tùy chọn); `health` (query, array, tùy chọn); `q` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProviderPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-002 · Khai báo NCC (`DRAFT`)

::: dac-ta
**Mục đích.** Khai báo NCC (`DRAFT`).

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers`.

**Quyền.** `PERM-19-provider-write`.

**FR hiện thực.** FR-19-001.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ProviderCreate`; trường bắt buộc: `code`, `name`, `adapterType`, `techContact`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ProviderDetail`; tiêu đề `ETag`, `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-038` Mã đã tồn tại; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tạo NCC `DRAFT`, sinh `connectionKey` (lưu OpenBao, CSDL chỉ giữ băm) và dòng `callback_route`; với adapter `PAYGOV` nạp bảng ánh xạ mã mặc định phiên bản 1 (giả định, SDD §7.3).
:::

#### API-19-003 · Chi tiết NCC kèm sức khỏe, mạch ngắt, hạn chứng thư, số dịch vụ

::: dac-ta
**Mục đích.** Chi tiết NCC kèm sức khỏe, mạch ngắt, hạn chứng thư, số dịch vụ.

**Phương thức, đường dẫn.** `GET /api/payment/v1/providers/{providerId}`.

**Quyền.** `PERM-19-provider-read`.

**FR hiện thực.** FR-19-008, FR-19-011.

**Tham số.** `providerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProviderDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-004 · Sửa NCC (BR-19-026)

::: dac-ta
**Mục đích.** Sửa NCC (BR-19-026).

**Phương thức, đường dẫn.** `PATCH /api/payment/v1/providers/{providerId}`.

**Quyền.** `PERM-19-provider-write`.

**FR hiện thực.** FR-19-009.

**Tham số.** `providerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProviderUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProviderDetail`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** NCC `ACTIVE`: trường kỹ thuật vào `pendingChange` và tạo đề nghị phê duyệt (BR-19-026); trường liên hệ áp ngay.
:::

#### API-19-005 · Xóa cứng NCC `DRAFT`

::: dac-ta
**Mục đích.** Xóa cứng NCC `DRAFT`.

**Phương thức, đường dẫn.** `DELETE /api/payment/v1/providers/{providerId}`.

**Quyền.** `PERM-19-provider-delete`.

**FR hiện thực.** FR-19-010.

**Tham số.** `providerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-037` Còn dữ liệu phụ thuộc; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Chỉ NCC `DRAFT` chưa có dịch vụ, giao dịch.
:::

#### API-19-006 · Danh sách tham chiếu bí mật (chỉ siêu dữ liệu)

::: dac-ta
**Mục đích.** Danh sách tham chiếu bí mật (chỉ siêu dữ liệu).

**Phương thức, đường dẫn.** `GET /api/payment/v1/providers/{providerId}/credentials`.

**Quyền.** `PERM-19-provider-read`.

**FR hiện thực.** FR-19-002.

**Tham số.** `providerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-007 · Gắn tham chiếu bí mật của một môi trường

::: dac-ta
**Mục đích.** Gắn tham chiếu bí mật của một môi trường.

**Phương thức, đường dẫn.** `PUT /api/payment/v1/providers/{providerId}/credentials/{environment}`.

**Quyền.** `PERM-19-credential-manage`.

**FR hiện thực.** FR-19-002.

**Tham số.** `providerId` (path, string, bắt buộc); `environment` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CredentialBind`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialList`; trường bắt buộc: `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-022` Thông tin xác thực NCC thiếu hoặc hết hạn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Chỉ nhận tham chiếu OpenBao; giá trị bí mật nạp bằng quy trình riêng của SEC (NFR-19-022).
:::

#### API-19-008 · Xoay khóa, chứng thư (tạo bản `NEXT`, chuyển tiếp)

::: dac-ta
**Mục đích.** Xoay khóa, chứng thư (tạo bản `NEXT`, chuyển tiếp).

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/credentials/{environment}/rotations`.

**Quyền.** `PERM-19-credential-manage`.

**FR hiện thực.** FR-19-012.

**Tham số.** `providerId` (path, string, bắt buộc); `environment` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CredentialRotation`; trường bắt buộc: `purpose`, `nextSecretRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialList`; trường bắt buộc: `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-022` Thông tin xác thực NCC thiếu hoặc hết hạn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Khóa mới ở `NEXT`, khóa cũ hợp lệ tới `transitionUntil` (BR-19-026, `19.provider.credential-transition-days`).
:::

#### API-19-009 · Chạy kiểm tra kết nối

::: dac-ta
**Mục đích.** Chạy kiểm tra kết nối.

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/connection-tests`.

**Quyền.** `PERM-19-provider-test`.

**FR hiện thực.** FR-19-003.

**Tham số.** `providerId` (path, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ConnectionTestRequest`; trường bắt buộc: `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CheckRun`; trường bắt buộc: `id`, `checkType`, `environment`, `result`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `422` `ERR-19-022` Thông tin xác thực NCC thiếu hoặc hết hạn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-010 · Tạo giao dịch thử

::: dac-ta
**Mục đích.** Tạo giao dịch thử.

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/test-transactions`.

**Quyền.** `PERM-19-provider-test`.

**FR hiện thực.** FR-19-004.

**Tham số.** `providerId` (path, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `TestTransactionRequest`; trường bắt buộc: `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CheckRun`; trường bắt buộc: `id`, `checkType`, `environment`, `result`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `422` `ERR-19-022` Thông tin xác thực NCC thiếu hoặc hết hạn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Giao dịch thử thuộc đối tác ẩn `__TEST__`, không vào số liệu (BR-19-033).
:::

#### API-19-011 · Kết quả kiểm tra, giao dịch thử, trạng thái checklist

::: dac-ta
**Mục đích.** Kết quả kiểm tra, giao dịch thử, trạng thái checklist.

**Phương thức, đường dẫn.** `GET /api/payment/v1/providers/{providerId}/check-runs`.

**Quyền.** `PERM-19-provider-read`.

**FR hiện thực.** FR-19-003, FR-19-004, FR-19-005.

**Tham số.** `providerId` (path, string, bắt buộc); `checkType` (query, array, tùy chọn); `environment` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CheckRunList`; trường bắt buộc: `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-012 · Đề nghị `ACTIVATE` hoặc `RETIRE` (tạo `approval_request`)

::: dac-ta
**Mục đích.** Đề nghị `ACTIVATE` hoặc `RETIRE` (tạo `approval_request`).

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/lifecycle-requests`.

**Quyền.** Provider-write (ACTIVATE); provider-delete (RETIRE).

**FR hiện thực.** FR-19-005, FR-19-010.

**Tham số.** `providerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProviderLifecycleRequest`; trường bắt buộc: `action`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ApprovalRef`; trường bắt buộc: `approvalId`, `approvalType`, `status`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-036` Còn giao dịch hoặc phiên đối soát dở; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-035` Checklist kích hoạt chưa đạt; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** `ACTIVATE` cần `provider-write`, `RETIRE` cần `provider-delete`. Checklist BR-19-010 chụp vào `payload` của đề nghị.
:::

#### API-19-013 · Tạm dừng NCC

::: dac-ta
**Mục đích.** Tạm dừng NCC.

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/suspensions`.

**Quyền.** `PERM-19-provider-suspend`.

**FR hiện thực.** FR-19-006.

**Tham số.** `providerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StatusChange`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProviderDetail`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Hiệu lực ngay; giao dịch mới tới dịch vụ của NCC trả ERR-19-017.
:::

#### API-19-014 · Mở lại NCC

::: dac-ta
**Mục đích.** Mở lại NCC.

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/resumptions`.

**Quyền.** `PERM-19-provider-suspend`.

**FR hiện thực.** FR-19-006.

**Tham số.** `providerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StatusChange`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProviderDetail`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-022` Thông tin xác thực NCC thiếu hoặc hết hạn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-091 · Xem bảng ánh xạ mã kết quả hiện hành, lịch sử, mã chưa ánh xạ (đề xuất)

::: dac-ta
**Mục đích.** Xem bảng ánh xạ mã kết quả hiện hành, lịch sử, mã chưa ánh xạ (đề xuất).

**Phương thức, đường dẫn.** `GET /api/payment/v1/providers/{providerId}/result-mappings`.

**Quyền.** `PERM-19-provider-read`.

**FR hiện thực.** FR-19-069.

**Tham số.** `providerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ResultMappingView`; trường bắt buộc: `currentVersion`, `rows`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-092 · Lập đề nghị đổi bảng ánh xạ mã kết quả (đề xuất)

::: dac-ta
**Mục đích.** Lập đề nghị đổi bảng ánh xạ mã kết quả (đề xuất).

**Phương thức, đường dẫn.** `POST /api/payment/v1/providers/{providerId}/result-mapping-changes`.

**Quyền.** `PERM-19-provider-write`.

**FR hiện thực.** FR-19-069.

**Tham số.** `providerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResultMappingChange`; trường bắt buộc: `changes`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ApprovalRef`; trường bắt buộc: `approvalId`, `approvalType`, `status`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tạo bản nháp phiên bản n+1 và đề nghị `RESULT_MAPPING_CHANGE`; hiệu lực khi duyệt (SDD §7.4).
:::

### Nhóm dịch vụ

#### API-19-015 · Danh sách nhóm dịch vụ

::: dac-ta
**Mục đích.** Danh sách nhóm dịch vụ.

**Phương thức, đường dẫn.** `GET /api/payment/v1/service-groups`.

**Quyền.** `PERM-19-service-read`.

**FR hiện thực.** FR-19-013.

**Tham số.** `q` (query, string, tùy chọn); `includeDeleted` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceGroupList`; trường bắt buộc: `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-016 · Thêm nhóm dịch vụ

::: dac-ta
**Mục đích.** Thêm nhóm dịch vụ.

**Phương thức, đường dẫn.** `POST /api/payment/v1/service-groups`.

**Quyền.** `PERM-19-service-write`.

**FR hiện thực.** FR-19-013, FR-19-016.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ServiceGroupCreate`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ServiceGroup`; tiêu đề `ETag`, `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-038` Mã đã tồn tại; `422` `ERR-19-039` Mã danh mục không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-017 · Chi tiết nhóm dịch vụ

::: dac-ta
**Mục đích.** Chi tiết nhóm dịch vụ.

**Phương thức, đường dẫn.** `GET /api/payment/v1/service-groups/{groupId}`.

**Quyền.** `PERM-19-service-read`.

**FR hiện thực.** FR-19-013.

**Tham số.** `groupId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceGroup`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-018 · Sửa nhóm dịch vụ

::: dac-ta
**Mục đích.** Sửa nhóm dịch vụ.

**Phương thức, đường dẫn.** `PATCH /api/payment/v1/service-groups/{groupId}`.

**Quyền.** `PERM-19-service-write`.

**FR hiện thực.** FR-19-013, FR-19-016.

**Tham số.** `groupId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ServiceGroupUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceGroup`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-039` Mã danh mục không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-019 · Xóa mềm nhóm (không còn dịch vụ)

::: dac-ta
**Mục đích.** Xóa mềm nhóm (không còn dịch vụ).

**Phương thức, đường dẫn.** `DELETE /api/payment/v1/service-groups/{groupId}`.

**Quyền.** `PERM-19-service-write`.

**FR hiện thực.** FR-19-013.

**Tham số.** `groupId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-037` Còn dữ liệu phụ thuộc; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

### Dịch vụ

#### API-19-020 · Danh sách, tìm dịch vụ

::: dac-ta
**Mục đích.** Danh sách, tìm dịch vụ.

**Phương thức, đường dẫn.** `GET /api/payment/v1/services`.

**Quyền.** `PERM-19-service-read`.

**FR hiện thực.** FR-19-014.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `groupId` (query, string, tùy chọn); `providerId` (query, string, tùy chọn); `catalogInvalid` (query, boolean, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServicePage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-021 · Thêm dịch vụ

::: dac-ta
**Mục đích.** Thêm dịch vụ.

**Phương thức, đường dẫn.** `POST /api/payment/v1/services`.

**Quyền.** `PERM-19-service-write`.

**FR hiện thực.** FR-19-014, FR-19-016.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ServiceCreate`; trường bắt buộc: `code`, `name`, `groupId`, `providerId`, `feeTypeCode`, `collectingAgencyCode`, `minAmount`, `maxAmount`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Service`; tiêu đề `ETag`, `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-038` Mã đã tồn tại; `422` `ERR-19-039` Mã danh mục không hợp lệ; `ERR-19-010` Số tiền không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-022 · Chi tiết dịch vụ

::: dac-ta
**Mục đích.** Chi tiết dịch vụ.

**Phương thức, đường dẫn.** `GET /api/payment/v1/services/{serviceId}`.

**Quyền.** `PERM-19-service-read`.

**FR hiện thực.** FR-19-014.

**Tham số.** `serviceId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Service`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-023 · Sửa dịch vụ

::: dac-ta
**Mục đích.** Sửa dịch vụ.

**Phương thức, đường dẫn.** `PATCH /api/payment/v1/services/{serviceId}`.

**Quyền.** `PERM-19-service-write`.

**FR hiện thực.** FR-19-014, FR-19-016.

**Tham số.** `serviceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ServiceUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Service`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-039` Mã danh mục không hợp lệ; `ERR-19-010` Số tiền không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-024 · Xóa cứng dịch vụ `DRAFT` chưa có giao dịch

::: dac-ta
**Mục đích.** Xóa cứng dịch vụ `DRAFT` chưa có giao dịch.

**Phương thức, đường dẫn.** `DELETE /api/payment/v1/services/{serviceId}`.

**Quyền.** `PERM-19-service-activate`.

**FR hiện thực.** FR-19-015.

**Tham số.** `serviceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-037` Còn dữ liệu phụ thuộc; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-025 · Kích hoạt hoặc mở lại dịch vụ

::: dac-ta
**Mục đích.** Kích hoạt hoặc mở lại dịch vụ.

**Phương thức, đường dẫn.** `POST /api/payment/v1/services/{serviceId}/activations`.

**Quyền.** `PERM-19-service-activate`.

**FR hiện thực.** FR-19-015.

**Tham số.** `serviceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Service`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-039` Mã danh mục không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Cần NCC `ACTIVE` và mã danh mục còn hiệu lực.
:::

#### API-19-026 · Tạm dừng dịch vụ

::: dac-ta
**Mục đích.** Tạm dừng dịch vụ.

**Phương thức, đường dẫn.** `POST /api/payment/v1/services/{serviceId}/suspensions`.

**Quyền.** `PERM-19-service-activate`.

**FR hiện thực.** FR-19-015.

**Tham số.** `serviceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StatusChange`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Service`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-027 · Ngừng hẳn dịch vụ

::: dac-ta
**Mục đích.** Ngừng hẳn dịch vụ.

**Phương thức, đường dẫn.** `POST /api/payment/v1/services/{serviceId}/retirements`.

**Quyền.** `PERM-19-service-activate`.

**FR hiện thực.** FR-19-015.

**Tham số.** `serviceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StatusChange`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Service`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-036` Còn giao dịch hoặc phiên đối soát dở; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-028 · Tra mục danh mục PH-07 cho biểu mẫu (có đệm, chỉ các danh mục ở mục 1.5)

::: dac-ta
**Mục đích.** Tra mục danh mục PH-07 cho biểu mẫu (có đệm, chỉ các danh mục ở mục 1.5).

**Phương thức, đường dẫn.** `GET /api/payment/v1/catalog-lookups/{catalogCode}/items`.

**Quyền.** `PERM-19-service-read`.

**FR hiện thực.** FR-19-016.

**Tham số.** `catalogCode` (path, string, bắt buộc); `q` (query, string, tùy chọn); `parentCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemList`; trường bắt buộc: `catalogCode`, `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Đọc qua PH-07, đệm 10 phút; PH-07 không phản hồi trả dữ liệu đệm kèm `cachedAt`.
:::

### Đối tác

#### API-19-029 · Danh sách, tìm đối tác

::: dac-ta
**Mục đích.** Danh sách, tìm đối tác.

**Phương thức, đường dẫn.** `GET /api/payment/v1/partners`.

**Quyền.** `PERM-19-partner-read`.

**FR hiện thực.** FR-19-017.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `routingMode` (query, array, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PartnerPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-030 · Đăng ký đối tác (`DRAFT`)

::: dac-ta
**Mục đích.** Đăng ký đối tác (`DRAFT`).

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners`.

**Quyền.** `PERM-19-partner-write`.

**FR hiện thực.** FR-19-017.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `PartnerCreate`; trường bắt buộc: `code`, `name`, `agencyCode`, `allowedReturnUrls`, `techContact`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Partner`; tiêu đề `ETag`, `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-038` Mã đã tồn tại; `422` `ERR-19-039` Mã danh mục không hợp lệ; `ERR-19-016` Địa chỉ quay về không được phép; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-031 · Chi tiết đối tác

::: dac-ta
**Mục đích.** Chi tiết đối tác.

**Phương thức, đường dẫn.** `GET /api/payment/v1/partners/{partnerId}`.

**Quyền.** `PERM-19-partner-read`.

**FR hiện thực.** FR-19-017.

**Tham số.** `partnerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Partner`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-032 · Sửa hồ sơ đối tác

::: dac-ta
**Mục đích.** Sửa hồ sơ đối tác.

**Phương thức, đường dẫn.** `PATCH /api/payment/v1/partners/{partnerId}`.

**Quyền.** `PERM-19-partner-write`.

**FR hiện thực.** FR-19-017.

**Tham số.** `partnerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PartnerUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Partner`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-039` Mã danh mục không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-033 · Đề nghị `ONBOARD` hoặc `TERMINATE`

::: dac-ta
**Mục đích.** Đề nghị `ONBOARD` hoặc `TERMINATE`.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/lifecycle-requests`.

**Quyền.** `PERM-19-partner-write`.

**FR hiện thực.** FR-19-018.

**Tham số.** `partnerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PartnerLifecycleRequest`; trường bắt buộc: `action`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ApprovalRef`; trường bắt buộc: `approvalId`, `approvalType`, `status`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-035` Checklist kích hoạt chưa đạt; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-034 · Tạm dừng đối tác

::: dac-ta
**Mục đích.** Tạm dừng đối tác.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/suspensions`.

**Quyền.** `PERM-19-partner-suspend`.

**FR hiện thực.** FR-19-018.

**Tham số.** `partnerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StatusChange`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Partner`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Hiệu lực ngay; API đối tác trả ERR-19-005. Giao dịch đang chờ vẫn nhận IPN và webhook.
:::

#### API-19-035 · Mở lại đối tác

::: dac-ta
**Mục đích.** Mở lại đối tác.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/resumptions`.

**Quyền.** `PERM-19-partner-suspend`.

**FR hiện thực.** FR-19-018.

**Tham số.** `partnerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StatusChange`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Partner`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-036 · Danh sách client của đối tác

::: dac-ta
**Mục đích.** Danh sách client của đối tác.

**Phương thức, đường dẫn.** `GET /api/payment/v1/partners/{partnerId}/clients`.

**Quyền.** `PERM-19-partner-read`.

**FR hiện thực.** FR-19-019.

**Tham số.** `partnerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PartnerClientList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-037 · Cấp client tại PH-12

::: dac-ta
**Mục đích.** Cấp client tại PH-12.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/clients`.

**Quyền.** `PERM-19-partner-client-manage`.

**FR hiện thực.** FR-19-019.

**Tham số.** `partnerId` (path, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `PartnerClientCreate`; trường bắt buộc: `authMethod`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PartnerClient`; trường bắt buộc: `id`, `idpClientId`, `authMethod`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tạo client tại PH-12 (realm `dh-{tenant}`) với vai trò `ROLE-PARTNER_SYSTEM`; không phát hành bí mật dùng chung.
:::

#### API-19-038 · Thu hồi client

::: dac-ta
**Mục đích.** Thu hồi client.

**Phương thức, đường dẫn.** `DELETE /api/payment/v1/partners/{partnerId}/clients/{clientId}`.

**Quyền.** `PERM-19-partner-client-manage`.

**FR hiện thực.** FR-19-019.

**Tham số.** `partnerId` (path, string, bắt buộc); `clientId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Thu hồi tại PH-12 trong ≤ 60 giây (token hiện có hết hiệu lực khi hết hạn ≤ 5 phút).
:::

#### API-19-039 · Dịch vụ được gán và hạn mức

::: dac-ta
**Mục đích.** Dịch vụ được gán và hạn mức.

**Phương thức, đường dẫn.** `GET /api/payment/v1/partners/{partnerId}/service-grants`.

**Quyền.** `PERM-19-partner-read`.

**FR hiện thực.** FR-19-020.

**Tham số.** `partnerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceGrantList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-040 · Gán dịch vụ, đặt hạn mức

::: dac-ta
**Mục đích.** Gán dịch vụ, đặt hạn mức.

**Phương thức, đường dẫn.** `PUT /api/payment/v1/partners/{partnerId}/service-grants/{serviceId}`.

**Quyền.** `PERM-19-partner-write`.

**FR hiện thực.** FR-19-020.

**Tham số.** `partnerId` (path, string, bắt buộc); `serviceId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ServiceGrantPut`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceGrant`; trường bắt buộc: `serviceId`, `serviceCode`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `422` `ERR-19-010` Số tiền không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tạo hoặc thay gán; khi đã có gán thì bắt buộc `If-Match`.
:::

#### API-19-041 · Bỏ gán dịch vụ

::: dac-ta
**Mục đích.** Bỏ gán dịch vụ.

**Phương thức, đường dẫn.** `DELETE /api/payment/v1/partners/{partnerId}/service-grants/{serviceId}`.

**Quyền.** `PERM-19-partner-write`.

**FR hiện thực.** FR-19-020.

**Tham số.** `partnerId` (path, string, bắt buộc); `serviceId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-042 · Danh sách đầu nhận webhook

::: dac-ta
**Mục đích.** Danh sách đầu nhận webhook.

**Phương thức, đường dẫn.** `GET /api/payment/v1/partners/{partnerId}/webhook-endpoints`.

**Quyền.** `PERM-19-partner-read`.

**FR hiện thực.** FR-19-021.

**Tham số.** `partnerId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WebhookEndpointList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-043 · Thêm đầu nhận

::: dac-ta
**Mục đích.** Thêm đầu nhận.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/webhook-endpoints`.

**Quyền.** `PERM-19-partner-webhook-manage`.

**FR hiện thực.** FR-19-021.

**Tham số.** `partnerId` (path, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `WebhookEndpointCreate`; trường bắt buộc: `url`, `eventTypes`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `WebhookEndpointCreated`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `422` `ERR-19-044` Địa chỉ webhook không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Bí mật HMAC sinh ở máy chủ, trả một lần, lưu `kv/dh/{tenant}/payment/partners/{partnerCode}/webhooks/{endpointId}`.
:::

#### API-19-044 · Sửa, vô hiệu đầu nhận

::: dac-ta
**Mục đích.** Sửa, vô hiệu đầu nhận.

**Phương thức, đường dẫn.** `PATCH /api/payment/v1/partners/{partnerId}/webhook-endpoints/{endpointId}`.

**Quyền.** `PERM-19-partner-webhook-manage`.

**FR hiện thực.** FR-19-021.

**Tham số.** `partnerId` (path, string, bắt buộc); `endpointId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WebhookEndpointUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WebhookEndpoint`; trường bắt buộc: `id`, `url`, `eventTypes`, `endpointStatus`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-044` Địa chỉ webhook không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** `DISABLED` hủy các lượt gửi `PENDING`, `RETRY_SCHEDULED` của đầu nhận.
:::

#### API-19-045 · Gửi thử webhook

::: dac-ta
**Mục đích.** Gửi thử webhook.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/webhook-endpoints/{endpointId}/test-deliveries`.

**Quyền.** `PERM-19-partner-webhook-manage`.

**FR hiện thực.** FR-19-021.

**Tham số.** `partnerId` (path, string, bắt buộc); `endpointId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WebhookTestResult`; trường bắt buộc: `deliveryId`, `result`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Gửi sự kiện `webhook.test` ký thật; kết quả đồng bộ (timeout 10 giây).
:::

#### API-19-046 · Xoay bí mật ký

::: dac-ta
**Mục đích.** Xoay bí mật ký.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/webhook-endpoints/{endpointId}/secret-rotations`.

**Quyền.** `PERM-19-partner-webhook-manage`.

**FR hiện thực.** FR-19-021.

**Tham số.** `partnerId` (path, string, bắt buộc); `endpointId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WebhookSecretRotation`; trường bắt buộc: `secret`, `transitionUntil`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Hai chữ ký `v1` trong 7 ngày chuyển tiếp (ADR-044).
:::

#### API-19-047 · Đề nghị đổi chế độ định tuyến

::: dac-ta
**Mục đích.** Đề nghị đổi chế độ định tuyến.

**Phương thức, đường dẫn.** `POST /api/payment/v1/partners/{partnerId}/routing-mode-requests`.

**Quyền.** `PERM-19-migration-switch`.

**FR hiện thực.** FR-19-066.

**Tham số.** `partnerId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RoutingModeRequest`; trường bắt buộc: `targetMode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ApprovalRef`; trường bắt buộc: `approvalId`, `approvalType`, `status`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-035` Checklist kích hoạt chưa đạt; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

### Phê duyệt

#### API-19-048 · Hộp phê duyệt: đề nghị người dùng lập hoặc có quyền quyết định

::: dac-ta
**Mục đích.** Hộp phê duyệt: đề nghị người dùng lập hoặc có quyền quyết định.

**Phương thức, đường dẫn.** `GET /api/payment/v1/approval-requests`.

**Quyền.** (theo loại đề nghị).

**FR hiện thực.** FR-19-005, FR-19-010, FR-19-018, FR-19-039, FR-19-046, FR-19-047, FR-19-066.

**Tham số.** `box` (query, string, tùy chọn); `approvalType` (query, array, tùy chọn); `status` (query, array, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApprovalPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-049 · Chi tiết đề nghị kèm bằng chứng

::: dac-ta
**Mục đích.** Chi tiết đề nghị kèm bằng chứng.

**Phương thức, đường dẫn.** `GET /api/payment/v1/approval-requests/{approvalId}`.

**Quyền.** (theo loại đề nghị).

**FR hiện thực.** Không.

**Tham số.** `approvalId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Approval`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-050 · Duyệt, từ chối, hoặc người lập rút đề nghị

::: dac-ta
**Mục đích.** Duyệt, từ chối, hoặc người lập rút đề nghị.

**Phương thức, đường dẫn.** `POST /api/payment/v1/approval-requests/{approvalId}/decisions`.

**Quyền.** Provider-activate; partner-approve; refund-approve; discrepancy-approve; recon-reopen-approve; migration-switch (theo loại).

**FR hiện thực.** Không.

**Tham số.** `approvalId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Approval`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-033` Vi phạm nguyên tắc tách nhiệm; `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-034` Đề nghị phê duyệt không còn chờ quyết định; `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-035` Checklist kích hoạt chưa đạt; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Quyền theo loại đề nghị (khung §13.4). Áp thay đổi lên đối tượng đích trong cùng giao dịch CSDL; điều kiện không còn đúng thì trả mã lỗi của module (SDD §12).
:::

### Giao dịch

#### API-19-051 · Danh sách, tìm từ khóa, tra cứu nâng cao

::: dac-ta
**Mục đích.** Danh sách, tìm từ khóa, tra cứu nâng cao.

**Phương thức, đường dẫn.** `GET /api/payment/v1/transactions`.

**Quyền.** `PERM-19-transaction-read`.

**FR hiện thực.** FR-19-049, FR-19-050.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `reconStatus` (query, array, tùy chọn); `serviceCode` (query, array, tùy chọn); `groupCode` (query, array, tùy chọn); `partnerCode` (query, array, tùy chọn); `providerCode` (query, array, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `paidFrom` (query, string, tùy chọn); `paidTo` (query, string, tùy chọn); `amountMin` (query, Money, tùy chọn); `amountMax` (query, Money, tùy chọn); `payerName` (query, string, tùy chọn); `payerPhone` (query, string, tùy chọn); `payerIdNumber` (query, string, tùy chọn); `includeTest` (query, boolean, tùy chọn); `includeShadow` (query, boolean, tùy chọn); `needsReconciliation` (query, boolean, tùy chọn); `latePaid` (query, boolean, tùy chọn); `initUncertain` (query, boolean, tùy chọn); `sort` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransactionPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Đọc bản sao `pg-payment-ro`. Tìm theo người nộp cần `transaction-read-pii`. Trang ≤ 1,5 giây p95 với 10 triệu giao dịch (NFR-19-007).
:::

#### API-19-052 · Chi tiết giao dịch (PII che theo quyền)

::: dac-ta
**Mục đích.** Chi tiết giao dịch (PII che theo quyền).

**Phương thức, đường dẫn.** `GET /api/payment/v1/transactions/{transactionId}`.

**Quyền.** Transaction-read; transaction-read-pii.

**FR hiện thực.** FR-19-051, FR-19-055.

**Tham số.** `transactionId` (path, string, bắt buộc); `reveal` (query, boolean, tùy chọn); `X-Datahub-Reveal-Reason` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransactionDetail`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-053 · Đồng bộ trạng thái thủ công

::: dac-ta
**Mục đích.** Đồng bộ trạng thái thủ công.

**Phương thức, đường dẫn.** `POST /api/payment/v1/transactions/{transactionId}/status-syncs`.

**Quyền.** `PERM-19-transaction-sync`.

**FR hiện thực.** FR-19-037.

**Tham số.** `transactionId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StatusSyncResult`; trường bắt buộc: `before`, `after`, `changed`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-023` Vượt tần suất đồng bộ thủ công; `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-017` Kênh thanh toán tạm thời không khả dụng; `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Gọi truy vấn NCC; tối đa 1 lần/60 giây, 10 lần/ngày mỗi giao dịch.
:::

#### API-19-054 · Dòng thời gian trạng thái

::: dac-ta
**Mục đích.** Dòng thời gian trạng thái.

**Phương thức, đường dẫn.** `GET /api/payment/v1/transactions/{transactionId}/events`.

**Quyền.** `PERM-19-transaction-read`.

**FR hiện thực.** FR-19-028, FR-19-051.

**Tham số.** `transactionId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransactionEventList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-055 · Cán bộ hủy giao dịch

::: dac-ta
**Mục đích.** Cán bộ hủy giao dịch.

**Phương thức, đường dẫn.** `POST /api/payment/v1/transactions/{transactionId}/cancellations`.

**Quyền.** `PERM-19-transaction-cancel`.

**FR hiện thực.** FR-19-026.

**Tham số.** `transactionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AdminCancellation`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransactionDetail`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

### Thông báo IPN

#### API-19-056 · Danh sách IPN theo trạng thái xử lý, kết quả xác minh

::: dac-ta
**Mục đích.** Danh sách IPN theo trạng thái xử lý, kết quả xác minh.

**Phương thức, đường dẫn.** `GET /api/payment/v1/callbacks`.

**Quyền.** `PERM-19-callback-read`.

**FR hiện thực.** FR-19-032.

**Tham số.** `processingStatus` (query, array, tùy chọn); `verificationResult` (query, array, tùy chọn); `callbackType` (query, array, tùy chọn); `providerId` (query, string, tùy chọn); `transactionCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CallbackPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-057 · Chi tiết IPN (nguyên văn đã che)

::: dac-ta
**Mục đích.** Chi tiết IPN (nguyên văn đã che).

**Phương thức, đường dẫn.** `GET /api/payment/v1/callbacks/{callbackId}`.

**Quyền.** `PERM-19-callback-read`.

**FR hiện thực.** FR-19-032.

**Tham số.** `callbackId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CallbackDetail`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-058 · Xử lý lại IPN

::: dac-ta
**Mục đích.** Xử lý lại IPN.

**Phương thức, đường dẫn.** `POST /api/payment/v1/callbacks/{callbackId}/replays`.

**Quyền.** `PERM-19-callback-replay`.

**FR hiện thực.** FR-19-032.

**Tham số.** `callbackId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CallbackReplay`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CallbackDetail`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Chỉ IPN `QUARANTINED`, `FAILED` đã `VERIFIED`; xử lý lại bằng bảng ánh xạ hiện hành.
:::

### Hoàn tiền

#### API-19-059 · Kế toán lập yêu cầu hoàn

::: dac-ta
**Mục đích.** Kế toán lập yêu cầu hoàn.

**Phương thức, đường dẫn.** `POST /api/payment/v1/refunds`.

**Quyền.** `PERM-19-refund-create`.

**FR hiện thực.** FR-19-038.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `RefundCreate`; trường bắt buộc: `transactionCode`, `amount`, `reasonCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Refund`; tiêu đề `ETag`, `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-029` Giao dịch không đủ điều kiện hoàn tiền; `422` `ERR-19-030` Số tiền hoàn vượt số còn được hoàn; `ERR-19-031` Quá hạn hoàn tiền; `ERR-19-032` Hoàn tiền chưa được bật; `ERR-19-039` Mã danh mục không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tạo yêu cầu `PENDING_APPROVAL` và đề nghị `REFUND` (1 hoặc 2 cấp theo `19.refund.two-level-threshold`).
:::

#### API-19-060 · Danh sách yêu cầu hoàn

::: dac-ta
**Mục đích.** Danh sách yêu cầu hoàn.

**Phương thức, đường dẫn.** `GET /api/payment/v1/refunds`.

**Quyền.** `PERM-19-refund-read`.

**FR hiện thực.** FR-19-041.

**Tham số.** `status` (query, array, tùy chọn); `mode` (query, array, tùy chọn); `transactionCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RefundPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-061 · Chi tiết, lịch sử yêu cầu hoàn

::: dac-ta
**Mục đích.** Chi tiết, lịch sử yêu cầu hoàn.

**Phương thức, đường dẫn.** `GET /api/payment/v1/refunds/{refundId}`.

**Quyền.** `PERM-19-refund-read`.

**FR hiện thực.** FR-19-041.

**Tham số.** `refundId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Refund`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-062 · Thực thi lại, chuyển thủ công, hoặc ghi nhận chứng từ hoàn thủ công

::: dac-ta
**Mục đích.** Thực thi lại, chuyển thủ công, hoặc ghi nhận chứng từ hoàn thủ công.

**Phương thức, đường dẫn.** `POST /api/payment/v1/refunds/{refundId}/executions`.

**Quyền.** `PERM-19-refund-execute`.

**FR hiện thực.** FR-19-040.

**Tham số.** `refundId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RefundExecution`; trường bắt buộc: `action`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Refund`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-033` Vi phạm nguyên tắc tách nhiệm; `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-032` Hoàn tiền chưa được bật; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** `RETRY` tối đa 3 lần; `RECORD_MANUAL` cần chứng từ, người ghi khác người duyệt.
:::

### Đối soát

#### API-19-063 · Tạo phiên thủ công cho một ngày

::: dac-ta
**Mục đích.** Tạo phiên thủ công cho một ngày.

**Phương thức, đường dẫn.** `POST /api/payment/v1/reconciliation-sessions`.

**Quyền.** `PERM-19-recon-run`.

**FR hiện thực.** FR-19-042.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `SessionCreate`; trường bắt buộc: `providerId`, `businessDate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SessionDetail`; tiêu đề `ETag`, `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-040` Phiên đối soát đã tồn tại; `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-064 · Danh sách phiên

::: dac-ta
**Mục đích.** Danh sách phiên.

**Phương thức, đường dẫn.** `GET /api/payment/v1/reconciliation-sessions`.

**Quyền.** `PERM-19-discrepancy-read`.

**FR hiện thực.** FR-19-042, FR-19-047.

**Tham số.** `providerId` (query, string, tùy chọn); `status` (query, array, tùy chọn); `dateFrom` (query, string, tùy chọn); `dateTo` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SessionPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-065 · Tải file đối soát lên

::: dac-ta
**Mục đích.** Tải file đối soát lên.

**Phương thức, đường dẫn.** `POST /api/payment/v1/reconciliation-sessions/{sessionId}/files`.

**Quyền.** `PERM-19-recon-upload`.

**FR hiện thực.** FR-19-043.

**Tham số.** `sessionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `ReconFileUpload`; trường bắt buộc: `file`, `sha256`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SessionDetail`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-043` Phiên đối soát đã chốt; `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-041` File đối soát không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tệp lưu Garage trước (`RECON_SOURCE`), kiểm băm, rồi chuyển `COLLECTING`.
:::

#### API-19-066 · Thu thập lại, chạy lại so khớp

::: dac-ta
**Mục đích.** Thu thập lại, chạy lại so khớp.

**Phương thức, đường dẫn.** `POST /api/payment/v1/reconciliation-sessions/{sessionId}/runs`.

**Quyền.** `PERM-19-recon-run`.

**FR hiện thực.** FR-19-043, FR-19-044.

**Tham số.** `sessionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SessionRun`; trường bắt buộc: `action`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SessionDetail`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-043` Phiên đối soát đã chốt; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-067 · Chi tiết phiên, tổng hợp hai phía

::: dac-ta
**Mục đích.** Chi tiết phiên, tổng hợp hai phía.

**Phương thức, đường dẫn.** `GET /api/payment/v1/reconciliation-sessions/{sessionId}`.

**Quyền.** `PERM-19-discrepancy-read`.

**FR hiện thực.** FR-19-044, FR-19-047.

**Tham số.** `sessionId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SessionDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-068 · Chốt phiên

::: dac-ta
**Mục đích.** Chốt phiên.

**Phương thức, đường dẫn.** `POST /api/payment/v1/reconciliation-sessions/{sessionId}/closures`.

**Quyền.** `PERM-19-recon-close`.

**FR hiện thực.** FR-19-047, FR-19-048.

**Tham số.** `sessionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SessionClosure`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SessionDetail`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-042` Còn chênh lệch chưa xử lý; `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Sinh biên bản PDF, XLSX, lưu WORM; phiên `CLOSED` khi biên bản lưu xong (`closingJobId`).
:::

#### API-19-069 · Đề nghị mở lại phiên

::: dac-ta
**Mục đích.** Đề nghị mở lại phiên.

**Phương thức, đường dẫn.** `POST /api/payment/v1/reconciliation-sessions/{sessionId}/reopen-requests`.

**Quyền.** `PERM-19-recon-close`.

**FR hiện thực.** FR-19-047.

**Tham số.** `sessionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReopenRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ApprovalRef`; trường bắt buộc: `approvalId`, `approvalType`, `status`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-070 · Dòng đối soát của lần chạy

::: dac-ta
**Mục đích.** Dòng đối soát của lần chạy.

**Phương thức, đường dẫn.** `GET /api/payment/v1/reconciliation-sessions/{sessionId}/items`.

**Quyền.** `PERM-19-discrepancy-read`.

**FR hiện thực.** FR-19-044.

**Tham số.** `sessionId` (path, string, bắt buộc); `runNo` (query, integer, tùy chọn); `matchResult` (query, array, tùy chọn); `itemKind` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReconItemPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

### Chênh lệch

#### API-19-071 · Danh sách chênh lệch, lọc loại, tuổi, người phụ trách

::: dac-ta
**Mục đích.** Danh sách chênh lệch, lọc loại, tuổi, người phụ trách.

**Phương thức, đường dẫn.** `GET /api/payment/v1/discrepancies`.

**Quyền.** `PERM-19-discrepancy-read`.

**FR hiện thực.** FR-19-045.

**Tham số.** `type` (query, array, tùy chọn); `status` (query, array, tùy chọn); `assigneeId` (query, string, tùy chọn); `overdue` (query, boolean, tùy chọn); `sessionId` (query, string, tùy chọn); `providerId` (query, string, tùy chọn); `dateFrom` (query, string, tùy chọn); `dateTo` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiscrepancyPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-072 · Giao việc, nhận việc, chuyển cấp NCC, ghi chú

::: dac-ta
**Mục đích.** Giao việc, nhận việc, chuyển cấp NCC, ghi chú.

**Phương thức, đường dẫn.** `PATCH /api/payment/v1/discrepancies/{discrepancyId}`.

**Quyền.** `PERM-19-discrepancy-handle`.

**FR hiện thực.** FR-19-045.

**Tham số.** `discrepancyId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DiscrepancyPatch`; trường bắt buộc: `action`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiscrepancyDetail`; tiêu đề `ETag`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-043` Phiên đối soát đã chốt; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Ghi chú chỉ nối thêm (`append_discrepancy_note`).
:::

#### API-19-073 · Đề xuất cách xử lý (tạo đề nghị phê duyệt)

::: dac-ta
**Mục đích.** Đề xuất cách xử lý (tạo đề nghị phê duyệt).

**Phương thức, đường dẫn.** `POST /api/payment/v1/discrepancies/{discrepancyId}/resolution-proposals`.

**Quyền.** `PERM-19-discrepancy-handle`.

**FR hiện thực.** FR-19-046.

**Tham số.** `discrepancyId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResolutionProposal`; trường bắt buộc: `resolutionType`, `targetTransactionVersion`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ApprovalRef`; trường bắt buộc: `approvalId`, `approvalType`, `status`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-043` Phiên đối soát đã chốt; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `422` `ERR-19-030` Số tiền hoàn vượt số còn được hoàn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-074 · Chi tiết chênh lệch

::: dac-ta
**Mục đích.** Chi tiết chênh lệch.

**Phương thức, đường dẫn.** `GET /api/payment/v1/discrepancies/{discrepancyId}`.

**Quyền.** `PERM-19-discrepancy-read`.

**FR hiện thực.** FR-19-045.

**Tham số.** `discrepancyId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiscrepancyDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

### Nhật ký và webhook

#### API-19-075 · Danh sách nhật ký tích hợp

::: dac-ta
**Mục đích.** Danh sách nhật ký tích hợp.

**Phương thức, đường dẫn.** `GET /api/payment/v1/integration-logs`.

**Quyền.** `PERM-19-log-read`.

**FR hiện thực.** FR-19-054.

**Tham số.** `direction` (query, array, tùy chọn); `operation` (query, array, tùy chọn); `providerId` (query, string, tùy chọn); `partnerId` (query, string, tùy chọn); `transactionCode` (query, string, tùy chọn); `traceId` (query, string, tùy chọn); `httpStatusMin` (query, integer, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IntegrationLogPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Trực tuyến 12 tháng (NFR-19-015).
:::

#### API-19-076 · Chi tiết một lượt trao đổi, liên kết vết PH-13

::: dac-ta
**Mục đích.** Chi tiết một lượt trao đổi, liên kết vết PH-13.

**Phương thức, đường dẫn.** `GET /api/payment/v1/integration-logs/{logId}`.

**Quyền.** `PERM-19-log-read`.

**FR hiện thực.** FR-19-054, FR-19-055.

**Tham số.** `logId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IntegrationLogDetail`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-077 · Danh sách lượt gửi webhook

::: dac-ta
**Mục đích.** Danh sách lượt gửi webhook.

**Phương thức, đường dẫn.** `GET /api/payment/v1/webhook-deliveries`.

**Quyền.** `PERM-19-webhook-read`.

**FR hiện thực.** FR-19-062.

**Tham số.** `partnerId` (query, string, tùy chọn); `status` (query, array, tùy chọn); `eventType` (query, string, tùy chọn); `transactionCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WebhookDeliveryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-078 · Gửi lại thủ công

::: dac-ta
**Mục đích.** Gửi lại thủ công.

**Phương thức, đường dẫn.** `POST /api/payment/v1/webhook-deliveries/{deliveryId}/resends`.

**Quyền.** `PERM-19-webhook-resend`.

**FR hiện thực.** FR-19-062.

**Tham số.** `deliveryId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WebhookResend`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `WebhookDelivery`; trường bắt buộc: `id`, `eventId`, `eventType`, `status`, `attemptCount`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** `EXHAUSTED → PENDING` trên chính lượt gửi, giữ `eventId`; đầu nhận phải `ACTIVE`.
:::

#### API-19-079 · Chi tiết lượt gửi và các lần thử

::: dac-ta
**Mục đích.** Chi tiết lượt gửi và các lần thử.

**Phương thức, đường dẫn.** `GET /api/payment/v1/webhook-deliveries/{deliveryId}`.

**Quyền.** `PERM-19-webhook-read`.

**FR hiện thực.** FR-19-062.

**Tham số.** `deliveryId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WebhookDeliveryDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

### Dashboard và báo cáo

#### API-19-080 · Số liệu dashboard tổng quan

::: dac-ta
**Mục đích.** Số liệu dashboard tổng quan.

**Phương thức, đường dẫn.** `GET /api/payment/v1/dashboards/overview`.

**Quyền.** `PERM-19-dashboard-read`.

**FR hiện thực.** FR-19-056.

**Tham số.** `range` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `providerId` (query, string, tùy chọn); `serviceCode` (query, Code, tùy chọn); `fields` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DashboardOverview`; trường bắt buộc: `asOf`, `kpis`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-081 · Số liệu dashboard kênh thanh toán 30 ngày

::: dac-ta
**Mục đích.** Số liệu dashboard kênh thanh toán 30 ngày.

**Phương thức, đường dẫn.** `GET /api/payment/v1/dashboards/channels`.

**Quyền.** `PERM-19-dashboard-read`.

**FR hiện thực.** FR-19-057.

**Tham số.** `days` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DashboardChannels`; trường bắt buộc: `asOf`, `channels`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-082 · Dữ liệu một báo cáo định kỳ theo kỳ

::: dac-ta
**Mục đích.** Dữ liệu một báo cáo định kỳ theo kỳ.

**Phương thức, đường dẫn.** `GET /api/payment/v1/reports/{reportCode}`.

**Quyền.** `PERM-19-report-read`.

**FR hiện thực.** FR-19-058.

**Tham số.** `reportCode` (path, ReportCode, bắt buộc); `periodType` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `groupBy` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; trường bắt buộc: `reportCode`, `period`, `columns`, `rows`, `provisional`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-083 · Tạo tác vụ xuất: danh sách giao dịch, báo cáo, biên bản đối soát

::: dac-ta
**Mục đích.** Tạo tác vụ xuất: danh sách giao dịch, báo cáo, biên bản đối soát.

**Phương thức, đường dẫn.** `POST /api/payment/v1/export-jobs`.

**Quyền.** Transaction-export; report-export (theo loại).

**FR hiện thực.** FR-19-048, FR-19-052, FR-19-058.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ExportJobCreate`; trường bắt buộc: `jobType`, `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Job`; trường bắt buộc: `id`, `jobType`, `jobStatus`, `progressPct`, `requestedAt`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `422` `ERR-19-047` Kết quả xuất vượt giới hạn; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Tối đa 3 tác vụ đồng thời mỗi người; 1 triệu dòng ≤ 10 phút (NFR-19-009); tệp giữ 7 ngày.
:::

#### API-19-084 · Tiến độ và đường tải kết quả (chỉ người tạo)

::: dac-ta
**Mục đích.** Tiến độ và đường tải kết quả (chỉ người tạo).

**Phương thức, đường dẫn.** `GET /api/payment/v1/export-jobs/{jobId}`.

**Quyền.** Transaction-export; report-export.

**FR hiện thực.** FR-19-048, FR-19-052, FR-19-058.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Job`; trường bắt buộc: `id`, `jobType`, `jobStatus`, `progressPct`, `requestedAt`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

### Cấu hình, tệp, di trú

#### API-19-085 · Cấu hình hiện hành và lịch sử phiên bản

::: dac-ta
**Mục đích.** Cấu hình hiện hành và lịch sử phiên bản.

**Phương thức, đường dẫn.** `GET /api/payment/v1/config`.

**Quyền.** `PERM-19-config-read`.

**FR hiện thực.** FR-19-063.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConfigView`; trường bắt buộc: `current`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-086 · Tạo phiên bản cấu hình mới có ngày hiệu lực

::: dac-ta
**Mục đích.** Tạo phiên bản cấu hình mới có ngày hiệu lực.

**Phương thức, đường dẫn.** `POST /api/payment/v1/config/versions`.

**Quyền.** `PERM-19-config-write`.

**FR hiện thực.** FR-19-063.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConfigVersionCreate`; trường bắt buộc: `effectiveFrom`, `settings`, `changeNote`.

**Chống trùng.** Không.

**Phản hồi thành công.** `201` đã tạo, `ConfigVersion`; trường bắt buộc: `configVersion`, `effectiveFrom`, `settings`, `moduleEnabled`; tiêu đề `Location`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `412` `ERR-19-045` Dữ liệu đã bị thay đổi; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** `If-Match` là ETag của phiên bản hiện hành; `effectiveFrom` ≥ hiện tại.
:::

#### API-19-087 · Tải lên tệp đính kèm (chứng từ, tài liệu hoàn tiền, chênh lệch)

::: dac-ta
**Mục đích.** Tải lên tệp đính kèm (chứng từ, tài liệu hoàn tiền, chênh lệch).

**Phương thức, đường dẫn.** `POST /api/payment/v1/files`.

**Quyền.** Refund-create; refund-execute; discrepancy-handle (theo mục đích).

**FR hiện thực.** FR-19-038, FR-19-040, FR-19-045.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** multipart/form-data: `FileUpload`; trường bắt buộc: `file`, `purpose`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `StoredFile`; trường bắt buộc: `id`, `purpose`, `fileName`, `sizeBytes`, `sha256`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-088 · Siêu dữ liệu và đường tải có hạn của tệp

::: dac-ta
**Mục đích.** Siêu dữ liệu và đường tải có hạn của tệp.

**Phương thức, đường dẫn.** `GET /api/payment/v1/files/{fileId}`.

**Quyền.** Theo đối tượng sở hữu.

**FR hiện thực.** FR-19-040, FR-19-045, FR-19-048, FR-19-065.

**Tham số.** `fileId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StoredFile`; trường bắt buộc: `id`, `purpose`, `fileName`, `sizeBytes`, `sha256`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Quyền theo đối tượng sở hữu; đường tải ký có hạn 5 phút.
:::

#### API-19-089 · Chạy lô nhập dữ liệu hệ cũ hoặc đối chiếu sau di trú

::: dac-ta
**Mục đích.** Chạy lô nhập dữ liệu hệ cũ hoặc đối chiếu sau di trú.

**Phương thức, đường dẫn.** `POST /api/payment/v1/migration-runs`.

**Quyền.** `PERM-19-migration-run`.

**FR hiện thực.** FR-19-065, FR-19-068.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `MigrationRunCreate`; trường bắt buộc: `jobType`, `source`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Job`; trường bắt buộc: `id`, `jobType`, `jobStatus`, `progressPct`, `requestedAt`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-090 · Danh sách lần chạy di trú, kết quả đối chiếu, đường tải báo cáo lỗi

::: dac-ta
**Mục đích.** Danh sách lần chạy di trú, kết quả đối chiếu, đường tải báo cáo lỗi.

**Phương thức, đường dẫn.** `GET /api/payment/v1/migration-runs`.

**Quyền.** `PERM-19-migration-run`.

**FR hiện thực.** FR-19-065, FR-19-068.

**Tham số.** `jobType` (query, array, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `JobPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

### Thanh toán

#### API-19-101 · Tạo giao dịch, trả `transactionCode`, `paymentUrl`, `expiresAt`

::: dac-ta
**Mục đích.** Tạo giao dịch, trả `transactionCode`, `paymentUrl`, `expiresAt`.

**Phương thức, đường dẫn.** `POST /api/payment-partner/v1/payments`.

**Quyền.** `PERM-19-partner-pay-create`.

**FR hiện thực.** FR-19-022, FR-19-023, FR-19-024, FR-19-033, FR-19-034.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PaymentCreate`; trường bắt buộc: `serviceCode`, `partnerOrderId`, `amount`, `description`, `returnUrl`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Payment`; trường bắt buộc: `transactionCode`, `status`, `serviceCode`, `partnerOrderId`, `amount`, `expiresAt`, `createdAt`, `sequence`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `ERR-19-002` Thiếu Idempotency-Key; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-005` Đối tác không ở trạng thái hoạt động; `ERR-19-009` Dịch vụ chưa được gán cho đối tác; `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-007` Dịch vụ không tồn tại; `409` `ERR-19-006` Đối tác chưa chuyển sang Datahub; `ERR-19-015` Mã đơn hàng đã có giao dịch; `ERR-19-004` Yêu cầu cùng Idempotency-Key đang được xử lý; `422` `ERR-19-008` Dịch vụ không hoạt động; `ERR-19-010` Số tiền không hợp lệ; `ERR-19-011` Số tiền ngoài khoảng cho phép của dịch vụ; `ERR-19-012` Vượt hạn mức mỗi giao dịch; `ERR-19-013` Vượt hạn mức trong ngày; `ERR-19-014` Loại tiền không được hỗ trợ; `ERR-19-016` Địa chỉ quay về không được phép; `ERR-19-039` Mã danh mục không hợp lệ; `ERR-19-003` Idempotency-Key đã dùng cho nội dung khác; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `502` `ERR-19-018` Nhà cung cấp từ chối khởi tạo thanh toán; `503` `ERR-19-017` Kênh thanh toán tạm thời không khả dụng; `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán; `504` `ERR-19-019` Chưa xác định được kết quả khởi tạo.

**Ghi chú.** Kiểm tra theo thứ tự BR-19-004, dừng ở lỗi đầu tiên. Chế độ `SHADOW` không gọi NCC, trả `CREATED`, `paymentUrl = null`. Header `Location`; `Idempotent-Replayed: true` khi trả lại kết quả cũ.
:::

#### API-19-102 · Truy vấn trạng thái theo mã giao dịch

::: dac-ta
**Mục đích.** Truy vấn trạng thái theo mã giao dịch.

**Phương thức, đường dẫn.** `GET /api/payment-partner/v1/payments/{transactionCode}`.

**Quyền.** `PERM-19-partner-pay-read`.

**FR hiện thực.** FR-19-035.

**Tham số.** `transactionCode` (path, TransactionCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Payment`; trường bắt buộc: `transactionCode`, `status`, `serviceCode`, `partnerOrderId`, `amount`, `expiresAt`, `createdAt`, `sequence`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Đọc bản chính, nhất quán ngay.
:::

#### API-19-103 · Truy vấn theo mã đơn hàng (mọi lượt giao dịch của mã đó)

::: dac-ta
**Mục đích.** Truy vấn theo mã đơn hàng (mọi lượt giao dịch của mã đó).

**Phương thức, đường dẫn.** `GET /api/payment-partner/v1/payments`.

**Quyền.** `PERM-19-partner-pay-read`.

**FR hiện thực.** FR-19-035.

**Tham số.** `partnerOrderId` (query, PartnerOrderId, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PaymentList`; trường bắt buộc: `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-104 · Đối tác hủy giao dịch chưa thanh toán

::: dac-ta
**Mục đích.** Đối tác hủy giao dịch chưa thanh toán.

**Phương thức, đường dẫn.** `POST /api/payment-partner/v1/payments/{transactionCode}/cancellations`.

**Quyền.** `PERM-19-partner-pay-create`.

**FR hiện thực.** FR-19-026.

**Tham số.** `transactionCode` (path, TransactionCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PartnerCancel`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Payment`; trường bắt buộc: `transactionCode`, `status`, `serviceCode`, `partnerOrderId`, `amount`, `expiresAt`, `createdAt`, `sequence`; tiêu đề `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `ERR-19-002` Thiếu Idempotency-Key; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-005` Đối tác không ở trạng thái hoạt động; `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-021` Chuyển trạng thái không hợp lệ; `ERR-19-004` Yêu cầu cùng Idempotency-Key đang được xử lý; `422` `ERR-19-003` Idempotency-Key đã dùng cho nội dung khác; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

### Hoàn tiền đối tác

#### API-19-105 · Đối tác lập yêu cầu hoàn

::: dac-ta
**Mục đích.** Đối tác lập yêu cầu hoàn.

**Phương thức, đường dẫn.** `POST /api/payment-partner/v1/refunds`.

**Quyền.** `PERM-19-partner-refund-create`.

**FR hiện thực.** FR-19-038.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PartnerRefundCreate`; trường bắt buộc: `transactionCode`, `partnerRefundId`, `amount`, `reasonCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PartnerRefund`; trường bắt buộc: `refundCode`, `partnerRefundId`, `transactionCode`, `amount`, `status`, `createdAt`; tiêu đề `Location`, `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `ERR-19-002` Thiếu Idempotency-Key; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-005` Đối tác không ở trạng thái hoạt động; `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `409` `ERR-19-029` Giao dịch không đủ điều kiện hoàn tiền; `ERR-19-004` Yêu cầu cùng Idempotency-Key đang được xử lý; `422` `ERR-19-030` Số tiền hoàn vượt số còn được hoàn; `ERR-19-031` Quá hạn hoàn tiền; `ERR-19-032` Hoàn tiền chưa được bật; `ERR-19-039` Mã danh mục không hợp lệ; `ERR-19-003` Idempotency-Key đã dùng cho nội dung khác; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Không.
:::

#### API-19-106 · Truy vấn yêu cầu hoàn

::: dac-ta
**Mục đích.** Truy vấn yêu cầu hoàn.

**Phương thức, đường dẫn.** `GET /api/payment-partner/v1/refunds/{refundCode}`.

**Quyền.** `PERM-19-partner-pay-read`.

**FR hiện thực.** FR-19-041.

**Tham số.** `refundCode` (path, RefundCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PartnerRefund`; trường bắt buộc: `refundCode`, `partnerRefundId`, `transactionCode`, `amount`, `status`, `createdAt`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

### Đối soát đối tác

#### API-19-107 · Tải kết quả đối soát phần của đối tác cho phiên đã chốt

::: dac-ta
**Mục đích.** Tải kết quả đối soát phần của đối tác cho phiên đã chốt.

**Phương thức, đường dẫn.** `GET /api/payment-partner/v1/reconciliation-reports`.

**Quyền.** `PERM-19-partner-recon-read`.

**FR hiện thực.** FR-19-048.

**Tham số.** `date` (query, string, bắt buộc); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PartnerReconReport`; trường bắt buộc: `date`, `provisional`, `items`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Chỉ giao dịch của đối tác gọi; `provisional = true` khi phiên chưa `CLOSED`.
:::

#### API-19-108 · Danh sách dịch vụ được gán và hạn mức còn lại trong ngày

::: dac-ta
**Mục đích.** Danh sách dịch vụ được gán và hạn mức còn lại trong ngày.

**Phương thức, đường dẫn.** `GET /api/payment-partner/v1/services`.

**Quyền.** `PERM-19-partner-pay-read`.

**FR hiện thực.** FR-19-020, FR-19-022.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PartnerServiceList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Không.
:::

#### API-19-109 · Kéo các thông báo đã phát (dự phòng khi webhook lỡ), theo con trỏ

::: dac-ta
**Mục đích.** Kéo các thông báo đã phát (dự phòng khi webhook lỡ), theo con trỏ.

**Phương thức, đường dẫn.** `GET /api/payment-partner/v1/notifications`.

**Quyền.** `PERM-19-partner-pay-read`.

**FR hiện thực.** FR-19-060, FR-19-062.

**Tham số.** `after` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NotificationPage`; trường bắt buộc: `items`, `hasMore`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-046` Không có quyền thực hiện; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant.

**Ghi chú.** Dự phòng khi lỡ webhook; giữ 7 ngày (A-19-10).
:::

### Tương thích hệ cũ

#### API-19-110 · Mặt nạ tương thích hợp đồng API hệ cũ, ánh xạ sang API-19-101…103 (đường dẫn thật theo hợp đồng cũ, OQ-19-17)

::: dac-ta
**Mục đích.** Mặt nạ tương thích hợp đồng API hệ cũ, ánh xạ sang API-19-101…103 (đường dẫn thật theo hợp đồng cũ, OQ-19-17).

**Phương thức, đường dẫn.** `POST /api/payment-partner/v1/legacy-compat/{operation}`.

**Quyền.** `PERM-19-partner-pay-create`.

**FR hiện thực.** FR-19-067.

**Tham số.** `operation` (path, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `LegacyCompatRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `LegacyCompatResponse`; tiêu đề `Idempotent-Replayed`.

**Lỗi.** `400` `ERR-19-001` Yêu cầu không hợp lệ; `401` Thiếu hoặc sai token (PH-12, PH-03 trả; không thuộc dải ERR-19); `403` `ERR-19-005` Đối tác không ở trạng thái hoạt động; `ERR-19-046` Không có quyền thực hiện; `404` `ERR-19-020` Không tìm thấy tài nguyên; `429` `ERR-19-048` Vượt giới hạn tốc độ; `500` `ERR-19-099` Lỗi hệ thống; `503` `ERR-19-049` Phân hệ thanh toán chưa bật cho tenant; `ERR-19-050` Không ghi được nhật ký kiểm toán.

**Ghi chú.** Ưu tiên C, đợt Sau (FR-19-067). Mặt nạ cho HTTT chưa sửa được mã; `Idempotency-Key` sinh từ mã đơn hàng nếu thiếu.
:::

### Callback PayGov

#### API-19-201 · Nhận IPN kết quả thanh toán

::: dac-ta
**Mục đích.** Nhận IPN kết quả thanh toán.

**Phương thức, đường dẫn.** `POST /api/payment-callback/v1/paygov/{connectionKey}/ipn`.

**Quyền.** Không dùng token; xác thực bằng chữ ký của nhà cung cấp trên `connectionKey`.

**FR hiện thực.** FR-19-029, FR-19-030, FR-19-031.

**Tham số.** `connectionKey` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `PaygovIpn`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CallbackAck`; trường bắt buộc: `responseCode`.

**Lỗi.** `401` `ERR-19-024` Chữ ký callback không hợp lệ; `ERR-19-025` Callback quá hạn; `403` `ERR-19-027` Nguồn callback không được phép; `409` `ERR-19-026` Callback bị phát lại.

**Ghi chú.** **Giả định – cần đối chiếu Tài liệu kỹ thuật kết nối của VPCP (OQ-19-01…07).** Thứ tự: tra `callback_route` theo `sha256(connectionKey)` → allowlist IP, mTLS → ghi nguyên văn `callback_inbox` → xác minh chữ ký (`ACTIVE`/`NEXT`), dấu thời gian ±5 phút, nonce → trả xác nhận → xử lý bất đồng bộ.
:::

#### API-19-202 · Người nộp quay về: xác minh tham số, hiển thị UI-19-28, chuyển về đối tác

::: dac-ta
**Mục đích.** Người nộp quay về: xác minh tham số, hiển thị UI-19-28, chuyển về đối tác.

**Phương thức, đường dẫn.** `GET /api/payment-callback/v1/paygov/{connectionKey}/return`.

**Quyền.** Không dùng token; xác thực bằng chữ ký của nhà cung cấp trên `connectionKey`.

**FR hiện thực.** FR-19-025.

**Tham số.** `connectionKey` (path, string, bắt buộc); `orderId` (query, string, tùy chọn); `responseCode` (query, string, tùy chọn); `signature` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** `403` `ERR-19-027` Nguồn callback không được phép.

**Ghi chú.** Người nộp quay về: xác minh chữ ký tham số, trả trang UI-19-28 hiển thị trạng thái **theo CSDL** (không theo tham số); trang tự chuyển về `returnUrl` đã lưu của giao dịch kèm `transactionCode`, `status`, `ts`, `sig` sau 5 giây. Không đổi trạng thái giao dịch (BR-19-014, FR-19-025). Sai chữ ký: 400, trang không chuyển tới đối tác.
:::

#### API-19-203 · Nhận kết quả hoàn tiền (nếu PayGov hỗ trợ, OQ-19-06)

::: dac-ta
**Mục đích.** Nhận kết quả hoàn tiền (nếu PayGov hỗ trợ, OQ-19-06).

**Phương thức, đường dẫn.** `POST /api/payment-callback/v1/paygov/{connectionKey}/refund-ipn`.

**Quyền.** Không dùng token; xác thực bằng chữ ký của nhà cung cấp trên `connectionKey`.

**FR hiện thực.** FR-19-041.

**Tham số.** `connectionKey` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `PaygovIpn`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CallbackAck`; trường bắt buộc: `responseCode`.

**Lỗi.** `401` `ERR-19-024` Chữ ký callback không hợp lệ; `ERR-19-025` Callback quá hạn; `403` `ERR-19-027` Nguồn callback không được phép; `409` `ERR-19-026` Callback bị phát lại.

**Ghi chú.** **Giả định – cần đối chiếu Tài liệu kỹ thuật kết nối của VPCP (OQ-19-01…07).** Thứ tự: tra `callback_route` theo `sha256(connectionKey)` → allowlist IP, mTLS → ghi nguyên văn `callback_inbox` → xác minh chữ ký (`ACTIVE`/`NEXT`), dấu thời gian ±5 phút, nonce → trả xác nhận → xử lý bất đồng bộ.
:::

#### API-19-204 · Nhận thông báo dữ liệu đối soát sẵn sàng (nếu PayGov hỗ trợ, OQ-19-07)

::: dac-ta
**Mục đích.** Nhận thông báo dữ liệu đối soát sẵn sàng (nếu PayGov hỗ trợ, OQ-19-07).

**Phương thức, đường dẫn.** `POST /api/payment-callback/v1/paygov/{connectionKey}/reconciliation-notices`.

**Quyền.** Không dùng token; xác thực bằng chữ ký của nhà cung cấp trên `connectionKey`.

**FR hiện thực.** FR-19-043.

**Tham số.** `connectionKey` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `PaygovIpn`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CallbackAck`; trường bắt buộc: `responseCode`.

**Lỗi.** `401` `ERR-19-024` Chữ ký callback không hợp lệ; `ERR-19-025` Callback quá hạn; `403` `ERR-19-027` Nguồn callback không được phép.

**Ghi chú.** **Giả định – cần đối chiếu Tài liệu kỹ thuật kết nối của VPCP (OQ-19-01…07).** Thứ tự: tra `callback_route` theo `sha256(connectionKey)` → allowlist IP, mTLS → ghi nguyên văn `callback_inbox` → xác minh chữ ký (`ACTIVE`/`NEXT`), dấu thời gian ±5 phút, nonce → trả xác nhận → xử lý bất đồng bộ.
:::

#### API-19-205 · Trạng thái rút gọn cho trang UI-19-28 thăm dò (bổ sung 0.2)

::: dac-ta
**Mục đích.** Trạng thái rút gọn cho trang UI-19-28 thăm dò (bổ sung 0.2).

**Phương thức, đường dẫn.** `GET /api/payment-callback/v1/result-status`.

**Quyền.** Không dùng token; xác thực bằng chữ ký của nhà cung cấp trên `connectionKey`.

**FR hiện thực.** FR-19-025.

**Tham số.** `t` (query, string, tùy chọn); `s` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PublicResultStatus`; trường bắt buộc: `status`, `final`.

**Lỗi.** `404` `ERR-19-020` Không tìm thấy tài nguyên.

**Ghi chú.** Trang UI-19-28 thăm dò trạng thái khi giao dịch còn `CREATED`, `PENDING` (mỗi 3 giây, tối đa 20 giây). Chỉ trả trạng thái rút gọn, không có dữ liệu cá nhân; giới hạn tốc độ theo IP ở APISIX.
:::

<!-- gen:dac-ta-api:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 26/11/2026 | Bản đầu: 107 operation (gồm API-19-205 bổ sung khi thiết kế UI-19-28; API-19-202 trả trang HTML thay cho chuyển hướng 302; khối `badges` của API-19-080) ở ba tệp OpenAPI, 8 webhook, 18 kênh AsyncAPI, bảng ERR-19 chính thức; đã qua kiểm tra hợp đồng | Nhóm phân hệ PH-19 |
| 0.2 | 26/11/2026 | Nâng theo quy chuẩn trình bày K-TRINH-BAY: chương 0 Giới thiệu (mục đích, phạm vi, người đọc, thuật ngữ, tham chiếu, cấu trúc); chương 10 đặc tả 107 endpoint theo 10 mục sinh từ OpenAPI; chú thích bảng, hình | Nhóm phân hệ PH-19 |
