---
ma_tai_lieu: D03-04-PH09
ten: Đặc tả API và sự kiện phân hệ PH-09 Quyền riêng tư
phien_ban: 0.4
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư tích hợp, kỹ sư dh-data, ATTT, kiểm thử viên, hội đồng thẩm định
phan_he: PH-09
mo_ta: Hợp đồng REST và sự kiện của PH-09 Quyền riêng tư gồm 245 operation (234 ở control plane và 11 ở data plane quyết định, áp che, giả danh hóa) và 32 sự kiện EVT-09 cộng kênh kiểm toán, kèm quy ước chung, xác thực, phân quyền, mã lỗi RFC 9457, ví dụ JSON, đặc tả đầy đủ của 37 operation trọng yếu và kiểm tra hợp đồng trong CI, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 kèm theo.
tai_lieu_lien_quan: D02-03-PH09 FRS; D03-02-PH09 SDD; D03-03-PH09 CSDL; D03-06-PH09 Giao diện; D05-02-PH09 Test case
---

# D03-04-PH09 · Đặc tả API và sự kiện Quyền riêng tư

## Tóm tắt cho hội đồng thẩm định

PH-09 là nơi quản lý và cấp chính sách bảo vệ dữ liệu cá nhân (DLCN) cho cả nền tảng, nên API của nó chia hai mặt phẳng với yêu cầu khác nhau. **Control plane** `/api/privacy/v1` (234 operation) phục vụ cán bộ qua cổng quản trị và các HTTT gọi bằng token dịch vụ: phân loại dữ liệu, sổ hoạt động xử lý, mục đích và chấp thuận, chính sách che, giả danh và ẩn danh hóa, lưu giữ, quyền chủ thể, đồng ý, đánh giá tác động (DPIA), vi phạm dữ liệu, kiểm toán, tham số. **Data plane** `/privacy/v1` (11 operation) chỉ mở trong cụm cho điểm thực thi PH-03, 04, 06, 14, 19 gọi trên đường nóng (quyết định mục đích p95 ≤ 50 ms, kế hoạch che, áp che bản tin, giả danh hóa lô, băm chủ thể, bundle, báo lượt).

Có ba điểm cần hội đồng lưu ý.

1. **API không đưa giá trị DLCN ra ngoài trừ một chỗ.** Định danh chủ thể chỉ đi vào (yêu cầu API-09-165, 188, 230, 235) và đi ra dưới dạng băm HMAC; sự kiện chỉ mang mã, trạng thái, số lượng; chỉ phiếu xem đầy đủ (API-09-102) trả giá trị trong thân `no-store`, hết hạn sau 60 giây theo `expiresAt` của máy chủ. Khôi phục giá trị gốc từ token (API-09-124) trả tham chiếu Garage tải một lần, hết hạn sau 60 giây, không trả giá trị.
2. **Bốn mắt được cưỡng chế ở hợp đồng, không chỉ ở giao diện.** 39 operation gửi duyệt, duyệt, xác nhận, từ chối, hủy khóa, khôi phục giá trị gốc trả `403` ERR-09-005 khi người thực hiện trùng người đề nghị; khôi phục giá trị gốc cần ba người khác nhau và MFA; hủy khóa và xóa mật mã tenant cần hai người và thời gian chờ.
3. **Hợp đồng sinh từ một nguồn và kiểm tự động.** OpenAPI 3.1 ([`ph09/openapi-privacy.yaml`](ph09/openapi-privacy.yaml), 245 operation, 329 lược đồ) và AsyncAPI 3.0 ([`ph09/asyncapi-privacy.yaml`](ph09/asyncapi-privacy.yaml), 33 kênh) sinh bằng `ph09/tools/gen_openapi.py`, `gen_asyncapi.py` từ FRS; `check_contracts.py` kiểm mã, enum theo Phụ lục A, ví dụ khớp lược đồ, không có khóa giá trị DLCN trong sự kiện.

Mọi mã `API-09-001…245` của FRS 0.2 đều có mặt ở chương 3; 37 operation trọng yếu có đặc tả 10 mục ở chương 13 và 10 ví dụ yêu cầu, phản hồi ở chương 12. Chương 11 ghi kết quả của năm câu hỏi mở Q09-55…59 sau khi FRS 0.2 chốt, chương 10 các việc còn lại cho FRS.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả hợp đồng giao tiếp của PH-09 ở mức đủ để kỹ sư `dh-data` hiện thực, kỹ sư PH-03, 04, 06, 14, 19 viết lời gọi, kiểm thử viên viết ca kiểm thử hợp đồng và ATTT soát quyền. Phạm vi gồm các API REST của control plane và data plane, sự kiện Kafka phát ra, mã lỗi, quy ước chung và kiểm tra hợp đồng. Ngoài phạm vi: giao diện (D03-06-PH09), thiết kế bên trong (D03-02-PH09), bảng dữ liệu (D03-03-PH09). Nội dung nghiệp vụ lấy từ FRS D02-03-PH09 §9; tài liệu này thêm lược đồ, tham số, mã thành công, thân yêu cầu và phản hồi mà FRS để cho tập thiết kế.

### 0.2. Thuật ngữ

Các thuật ngữ dưới đây dùng xuyên suốt tài liệu.

| Thuật ngữ | Giải thích |
|---|---|
| Control plane, data plane | Hai mặt phẳng của PH-09: quản trị chính sách cho người dùng và HTTT; quyết định, áp che trên đường nóng cho điểm thực thi |
| PEP, PDP | Điểm thực thi (APISIX, PH-04, PH-06, PH-14, PH-19) và điểm quyết định (OPA ở PH-12) |
| Bundle | Gói chính sách đã ký (`purpose_grants`, `mask_policies`, `classification_index`) cho OPA |
| Phiếu xem đầy đủ | Phiếu ngắn hạn (60 giây) cho phép xem giá trị trường nhạy cảm không che, có lý do và nhật ký |
| `subjectHash` | HMAC-SHA256 của định danh chủ thể đã chuẩn hóa, khóa riêng từng tenant; không đảo ngược được |
| Bốn mắt | Người thực hiện khác người đề nghị (khác cả người xác nhận trước ở bước ba người) |
| ETag, `If-Match` | Số phiên bản đối tượng làm khóa lạc quan; lệch trả `409` ERR-09-004, thiếu trả `428` |
| RFC 9457 | Khuôn thân lỗi `application/problem+json` |

: Thuật ngữ của tập API PH-09

### 0.3. Tài liệu tham chiếu

Tập này dựa vào các tài liệu sau.

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH09 FRS §9.1, 9.3, 9.4, Phụ lục A | Danh mục lỗi, sự kiện, API, enum |
| D03-03-PH09 CSDL | Cột bảng ứng với trường JSON camelCase; ràng buộc mà API phải phản ánh |
| D03-07 ATTT §3.2, §6 | Bốn mức phân loại, vai trò kiểm soát, giả danh hóa, quyền chủ thể, vi phạm 72 giờ |
| D03-10 Thiết kế đa tenant | Tenant lấy từ token, không từ tham số |
| D02-08 Ma trận phân quyền | Quyền `PERM-09-*` (16 quyền; 13 quyền đề nghị mới ở FRS Phụ lục B) |
| ADR-041, 042, 046 | Chống trùng, outbox, bốn mắt |
| `docs/07-srs/SRS-PH-09-privacy.md` M5 | API cũ của SRS (mục 8.1) |

: Tài liệu tham chiếu của tập API PH-09

### 0.4. Người đọc

Kỹ sư tích hợp và `dh-data` đọc chương 1, 2, 3, 12, 13; ATTT đọc chương 2 và 6; kiểm thử viên đọc chương 3, 6, 7; hội đồng thẩm định đọc Tóm tắt, chương 1, 2 và 10, 11.

### 0.5. Cấu trúc tài liệu

Chương 1 quy ước chung, 2 xác thực và phân quyền, 3 danh mục 245 operation, 4 sự kiện, 5 hợp đồng với phân hệ khác, 6 mã lỗi, 7 kiểm tra hợp đồng, 8 ánh xạ từ hệ cũ, 9 truy vết FR sang API, 10 đề nghị cho FRS, 11 câu hỏi mở, 12 ví dụ JSON, 13 đặc tả endpoint trọng yếu. Vì tập có 245 operation và giới hạn dung lượng, chỉ operation trọng yếu (an toàn, đường nóng, bốn mắt, đặc quyền) có bảng 10 mục và ví dụ; phần còn lại theo quy tắc chung và đọc đầy đủ ở OpenAPI.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi operation, trừ khi bảng ở chương 3 hoặc đặc tả ở chương 13 ghi khác. Phần lớn lấy nguyên từ khung chung D03-04 và quy ước FRS §6.

| Mục | Quy ước |
|---|---|
| Đường gốc | Control plane `/api/privacy/v1` qua APISIX (người dùng đi qua BFF của cổng quản trị); trong cụm `dh-data.dh-data.svc`. Data plane `/privacy/v1`, chỉ trong cụm, Deployment riêng (vai CSDL `ph09_decide`), 3 bản sao. Đường dẫn ở chương 3 của control plane tính từ gốc, của data plane viết đầy đủ |
| Tenant | Lấy từ token (claim `tenant`), không bao giờ từ thân, đường dẫn hay tiêu đề; đối tượng của tenant khác trả `404` ERR-09-001, không lộ sự tồn tại; mọi bảng có RLS (NFR-09-019) |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên hoặc tập (`:approve`, `:submit`, `:publish`); hành động có thể đổi trạng thái là `POST` |
| Khóa lạc quan | `GET` đối tượng có phiên bản trả `ETag: W/"{version}"`; `PUT`, `PATCH` và hành động trên đối tượng đó bắt buộc `If-Match`; thiếu trả `428` (mã nền ERR-00-428), lệch trả `409` ERR-09-004. 93 operation có `If-Match` |
| Chống trùng | Mọi `POST` tạo hoặc chuyển trạng thái ở control plane (117 operation, trừ tra cứu API-09-245) bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ ở Valkey; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-09-081 (BR-09-061). Data plane và API-09-245 không dùng khóa |
| Phân trang | `page` (từ 0), `size` (1…100, mặc định 20), `sort` (tiền tố `-` giảm dần); phản hồi `items`, `page`, `size`, `totalElements`; lọc bằng tham số tên trường, tham số bắt buộc ghi ở OpenAPI |
| Thời gian, số | RFC 3339 có múi giờ (`+07:00`); thời lượng theo giây hoặc ngày ở tên trường (`ttlSeconds`, `periodDays`); mã nghiệp vụ chữ hoa `^[A-Z][A-Z0-9_-]{1,47}$` |
| Lỗi | RFC 9457 `application/problem+json`: `type` = `https://datahub.gov.vn/errors/{code}`, `title`, `status`, `code` (`ERR-09-nnn`), `traceId`, `errors[]` theo trường; thông báo tiếng Việt (mặc định) hoặc `en` theo `Accept-Language`; không lộ giá trị dữ liệu (mục 6.1) |
| Tác vụ dài | Xuất, quét, ẩn danh hóa, tra cứu chủ thể, báo cáo trả `202` kèm `jobId` hoặc đối tượng ở trạng thái `QUEUED`; theo dõi bằng `GET` đối tượng hoặc sự kiện |
| Phân loại dữ liệu | Mỗi operation và lược đồ nhạy cảm có `x-dh-classification` (`INTERNAL`, `RESTRICTED`, `SENSITIVE`); phản hồi `RESTRICTED` trở lên có `Cache-Control: no-store` và không ghi vào nhật ký truy cập dạng rõ |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên APISIX, BFF, `dh-data`, Kafka; `Accept-Language: vi` hoặc `en` |

: Quy ước chung của API PH-09

### 1.1. Hai mặt phẳng

Hai mặt phẳng khác nhau ở bên gọi, cách xác thực và yêu cầu hiệu năng, nên được tách Deployment và chỉ chung mã nguồn module `privacy`.

| Mục | Control plane | Data plane |
|---|---|---|
| Đường gốc | `/api/privacy/v1` | `/privacy/v1` |
| Bên gọi | Cán bộ qua BFF; HTTT, PH-02, PH-04, PH-10 và dịch vụ công của tỉnh bằng token dịch vụ | PH-03, PH-04, PH-06, PH-14, PH-19, PH-17 (điểm thực thi) |
| Xác thực | OIDC và PKCE ở BFF (quyền `PERM-09-*`); `client_credentials` với scope `privacy:register`, `privacy:consent` | `client_credentials`, mTLS và danh tính SPIFFE; scope `privacy:decide`, `apply`, `pseudonymize`, `consent` |
| Operation | 234 (API-09-001…226 và 238…245) | 11 (API-09-227…237) |
| Hiệu năng | Đọc p95 ≤ 500 ms; sẵn sàng ≥ 99,5% (NFR-09-006) | Quyết định p95 ≤ 50 ms, p99 ≤ 100 ms; áp che bản tin 10 KB ≤ 30 ms; 5.000 yêu cầu mỗi giây; sẵn sàng ≥ 99,95% (NFR-09-001…004, 006) |
| Khi không khả dụng | Giao diện báo lỗi, không ảnh hưởng đường nóng | Điểm thực thi dùng bản chụp đệm tối đa 5 phút rồi đóng an toàn (BR-09-027, NFR-09-007) |

: Hai mặt phẳng của API PH-09

### 1.2. Phiên bản hóa và tương thích

Phiên bản nằm ở đường dẫn (`v1`). Thay đổi tương thích ngược (thêm trường tùy chọn, thêm giá trị enum ở phản hồi, thêm operation) vào `v1`; thay đổi phá vỡ (xóa, đổi tên trường, đổi kiểu, thêm trường bắt buộc, đổi ngữ nghĩa mã lỗi) sang `v2` chạy song song tối thiểu 6 tháng. Bên tiêu thụ phải bỏ qua trường lạ. Thêm giá trị enum là thay đổi Phụ lục A của FRS rồi mới đến OpenAPI; bên nhận enum ở phản hồi xử lý giá trị lạ như `UNKNOWN` thay vì lỗi. `oasdiff` ở CI chặn thay đổi phá vỡ (chương 7); sự kiện theo cùng nguyên tắc ở 4.2.

### 1.3. Hạn mức gọi

Hạn mức của người dùng và của DU lấy từ khóa `09.api.rate-user-per-min` và `09.api.rate-du-per-sec` (FRS §8.2, mặc định 300 và 2.000); các giá trị còn lại là giả định theo GĐ-01.

| Mặt phẳng, đối tượng | Hạn mức | Khi vượt |
|---|---|---|
| Control plane, mỗi người dùng | 300 yêu cầu mỗi phút, bùng nổ 60 | `429` ERR-09-113, `Retry-After` |
| Control plane, mỗi token dịch vụ | 600 yêu cầu mỗi phút | như trên |
| Xem đầy đủ (API-09-102) | 20 phiếu mỗi người mỗi giờ (`09.mask.reveal-max-per-hour`) | `429` ERR-09-043 |
| Data plane, mỗi DU | 2.000 yêu cầu mỗi giây (toàn cụm 5.000) | `429` ERR-09-113; điểm thực thi lùi theo `Retry-After` |
| Báo lượt (API-09-237) | 1.000 sự kiện mỗi lời gọi, 10 lời gọi mỗi giây mỗi điểm | `413` ERR-09-107 hoặc `429` |

: Hạn mức gọi của API PH-09

## 2. Xác thực và phân quyền

PH-09 có hai nhóm bên gọi: người dùng (cán bộ) và máy (HTTT, phân hệ khác). Mỗi operation khai báo `security` trong OpenAPI: `oauth2User` cho người, `oauth2Machine` kèm scope cho máy, `mtlsSpiffe` cho data plane. Quyền và scope theo D02-08; thiếu quyền chức năng trả `403` (mã nền ERR-00-403), chưa xác thực trả `401` (ERR-00-401), phạm vi tổ chức sai trả `403` ERR-09-008.

### 2.1. Quyền người dùng

Quyền chức năng ghi `PERM-09-` rút gọn ở chương 3 (ví dụ `read` là quyền đọc, `policy-approve` là quyền duyệt chính sách), khớp FRS §3.2. Dấu `/` là "hoặc". Ba quyền đã có ở D02-08, mười ba quyền còn lại là đề nghị mới ở FRS Phụ lục B.

<!-- gen:perm:start -->
| Quyền hoặc scope | Số operation | Operation |
|---|---|---|
| `anonymize` | 9 | 126, 128, 130, 133, 136, 137, 142…144 |
| `audit-read` | 8 | 103, 120, 121, 181, 215…217, 241 |
| `breach` | 18 | 081…083, 202…214, 239, 240 |
| `classify` | 17 | 003…006, 008, 009, 012…018, 020, 024, 026, 243 |
| `config` | 5 | 085, 223…226 |
| `consent` | 11 | 182…185, 187…191, 238, 245 |
| `dsr` | 20 | 164…181, 242, 244 |
| `policy` | 15 | 002, 055…057, 091, 093, 095, 096, 101, 105, 107, 108, 110, 112, 113 |
| `policy-approve` | 17 | 076, 077, 097…099, 114, 116…118, 122, 123, 129, 135, 150, 151, 161, 186 |
| `purpose-approve` | 19 | 055…058, 060, 064…073, 081, 082, 122, 123 |
| `purpose-request` | 8 | 058…063, 067, 068 |
| `read` | 63 | 001, 007, 010, 011, 019, 021…023, 025, 027, 028, 030 … |
| `reidentify` | 4 | 119…121, 124 |
| `retention` | 9 | 146, 148, 149, 154, 155, 157…159, 162 |
| `ropa` | 22 | 033, 035…039, 042, 043, 046, 047, 049, 050, 192…201 |
| `unmask` | 1 | 102 |
| `scope privacy:apply` | 1 | 229 |
| `scope privacy:consent` | 3 | 188, 189, 234 |
| `scope privacy:decide` | 8 | 227, 228, 231…233, 235…237 |
| `scope privacy:pseudonymize` | 1 | 230 |
| `scope privacy:register` | 7 | 012, 029, 088, 137, 165, 172, 203 |

: Số operation theo quyền chức năng và scope máy
<!-- gen:perm:end -->

Vai trò (SO, TA, DS, DA, DO, OR, SV, TO, PA, AU, VW) và ma trận quyền nằm ở FRS §3.2, không lặp lại. Quyền `unmask` (API-09-102) được cấp riêng từng người; `reidentify` (API-09-119, 124) chỉ SO; `breach` có thêm TO để ghi nhận ban đầu nhưng chỉ TA, SO đóng được hồ sơ (BR-09-057).

### 2.2. Scope máy

Token dịch vụ lấy bằng `client_credentials` với mTLS hoặc `private_key_jwt`. Scope `purpose:{mã}` mang mục đích của lời gọi (D02-08 §5) và được kiểm riêng; năm scope của PH-09 như sau.

| Scope | Cho phép | Cấp cho | Operation |
|---|---|---|---|
| `privacy:decide` | Quyết định mục đích, kế hoạch che, chỉ mục phân loại, bundle, băm chủ thể, xác thực phiếu, báo lượt | PH-03, 04, 06, 14, 19 | 227, 228, 231, 232, 233, 235, 236, 237 |
| `privacy:apply` | Áp che bản tin | PH-03, 04, 06, 14, 19 | 229 |
| `privacy:pseudonymize` | Giả danh hóa lô giá trị | Chỉ PH-04 và PH-17 | 230 |
| `privacy:register` | Đăng ký phần tử, tính lại mức hợp đồng, kiểm tra kích hoạt, tiếp nhận yêu cầu chủ thể từ kênh công, báo hoàn tất tác vụ | PH-02, 04, 06, 10, 19; dịch vụ công của tỉnh | 012, 029, 088, 165, 172 và 137 (với quyền anonymize) |
| `privacy:consent` | Ghi, rút, tra sự đồng ý | HTTT có tiện ích đồng ý | 188, 189, 234 |

: Scope máy của PH-09

Data plane kiểm thêm danh tính DU theo SPIFFE ID của Istio (SEC-15): scope hợp lệ nhưng DU không được cấp thì `403` ERR-09-111. Job ARX dùng tài khoản CSDL riêng, không gọi API.

### 2.3. Tách nhiệm vụ

Các thao tác dưới đây cưỡng chế người thực hiện khác người đề nghị ở tầng dịch vụ (kiểm theo `createdBy`, `proposedBy`, `requestedBy`, `submittedBy`), phản ánh ở ràng buộc CSDL tương ứng (D03-03-PH09 §1.4); vi phạm trả `403` ERR-09-005.

| Thao tác | Operation | Quy tắc | BR |
|---|---|---|---|
| Xác nhận phân loại, hạ mức | 016, 018 | Khác người đề xuất; hạ mức cần thêm người xác nhận thứ hai | BR-09-002, 003 |
| Duyệt gỡ nhãn bí mật | 006 | Khác người đề nghị gỡ | BR-09-005 |
| Duyệt hoạt động, DPIA, chính sách che, lịch lưu giữ, cấu hình ẩn danh, mẫu đồng ý | 037, 097, 129, 150, 186, 197 | Khác người soạn và người gửi duyệt | BR-09-008, 021, 023, 035, 040, 050 |
| Quyết định yêu cầu khai thác | 065 | Khác người lập yêu cầu | BR-09-014 |
| Khôi phục giá trị gốc | 122, 124 | Người đề nghị, cấp một, cấp hai đôi một khác nhau; MFA | BR-09-032, 033 |
| Hủy khóa giả danh | 118 | Hai người khác nhau, chờ ≥ 7 ngày | BR-09-032 |
| Duyệt rủi ro MEDIUM | 135 | SO duyệt | BR-09-035 |
| Xóa mật mã tenant | 161 | Hai người duyệt khác người đề nghị, chờ ≥ 7 ngày | BR-09-041 |

: Thao tác bốn mắt và hơn của PH-09

### 2.4. Lỗi xác thực

Thân lỗi theo mục 6.1. Token hết hạn hoặc sai: `401`, tiêu đề `WWW-Authenticate: Bearer`. Token đúng nhưng thiếu quyền hoặc scope: `403`. Tenant của token khác tenant của đối tượng: `404`, không phân biệt với không tồn tại. Data plane thêm ERR-09-111 khi DU không được phép.

## 3. Danh mục endpoint

Mỗi operation có đúng một mã `API-09-nnn`, đồng bộ với FRS §9.4 (245 mã; 1…226 và 238…245 control plane, 227…237 data plane). Cột "Quyền, scope" dùng tên rút gọn (`s:` là scope máy); cột "Lỗi riêng" là các mã ERR-09 theo chức năng (số, bỏ tiền tố), còn lỗi cấu trúc (001 không thấy, 003 dữ liệu sai, 004 lệch phiên bản, 005 bốn mắt, 006 sai trạng thái, 007 thiếu lý do, 010 không ghi được kiểm toán) áp theo quy tắc ở chương 6 và không lặp ở đây. Cột TC là mã HTTP thành công. Chi tiết tham số, lược đồ thân yêu cầu và phản hồi nằm ở OpenAPI; operation trọng yếu có bảng 10 mục ở chương 13.

<!-- gen:catalog:start -->
### 3.1. Phân loại

Mức phân loại, nhãn chặn, loại DLCN, phần tử dữ liệu, phân loại và quét phát hiện, mức hợp đồng (FR-09-001…008). Nhóm có 32 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-001 | `GET /data-classes` | Liệt kê mức phân loại | 001 | read | 200 |  |
| API-09-002 | `PATCH /data-classes/{code}` | Sửa chính sách log, hiển thị của mức | 001 | policy | 200 |  |
| API-09-003 | `GET /secret-labels` | Liệt kê nhãn chặn | 007 | classify | 200 |  |
| API-09-004 | `POST /secret-labels` | Đề nghị gán nhãn STATE_SECRET | 007 | classify | 201 | 018, 019 |
| API-09-005 | `POST /secret-labels/{labelId}:request-release` | Đề nghị gỡ nhãn | 007 | classify | 200 | 018, 019 |
| API-09-006 | `POST /secret-labels/{labelId}:approve-release` | Duyệt gỡ nhãn (người thứ hai) | 007 | classify | 200 | 018, 019 |
| API-09-007 | `GET /personal-data-categories` | Liệt kê loại DLCN | 002 | read | 200 |  |
| API-09-008 | `POST /personal-data-categories` | Thêm loại DLCN | 002 | classify | 201 | 011 |
| API-09-009 | `PATCH /personal-data-categories/{code}` | Sửa, ngừng loại DLCN | 002 | classify | 200 | 011 |
| API-09-010 | `GET /data-elements` | Liệt kê phần tử dữ liệu | 003, 008 | read | 200 |  |
| API-09-011 | `GET /data-elements/{elementId}` | Chi tiết phần tử | 003 | read | 200 |  |
| API-09-012 | `POST /data-elements:register` | Đăng ký phần tử (hàng loạt) | 003 | classify; s:privacy:register | 200 | 014, 015 |
| API-09-013 | `POST /data-elements:import-schema` | Nhập lược đồ OpenAPI, JSON Schema, Avro | 003 | classify | 200 | 014, 015 |
| API-09-014 | `POST /data-elements:import-declarations` | Nhập khai báo MVP (@Classified, x-dh-classification) | 003 | classify | 200 | 014, 015 |
| API-09-015 | `PUT /data-elements/{elementId}/classification` | Đề xuất phân loại | 004 | classify | 200 | 005, 012, 013 |
| API-09-016 | `POST /classifications/{classificationId}:confirm` | Xác nhận phân loại | 004 | classify | 200 | 005, 012, 013 |
| API-09-017 | `POST /classifications/{classificationId}:reject` | Từ chối đề xuất | 004 | classify | 200 | 005, 012, 013 |
| API-09-018 | `POST /classifications:bulk-confirm` | Xác nhận hàng loạt | 004 | classify | 200 | 005, 012, 013 |
| API-09-019 | `GET /data-elements/{elementId}/history` | Lịch sử phân loại | 008 | read | 200 |  |
| API-09-020 | `POST /scans` | Tạo lượt quét phát hiện | 005 | classify | 202 | 015, 016, 017 |
| API-09-021 | `GET /scans` | Liệt kê lượt quét | 005 | read | 200 |  |
| API-09-022 | `GET /scans/{scanId}` | Chi tiết lượt quét | 005 | read | 200 |  |
| API-09-023 | `GET /scans/{scanId}/findings` | Kết quả phát hiện | 005 | read | 200 |  |
| API-09-024 | `POST /findings/{findingId}:resolve` | Xử lý kết quả: đề xuất phân loại hoặc loại trừ | 005 | classify | 200 | 015, 016, 017 |
| API-09-025 | `GET /detectors` | Liệt kê mẫu phát hiện | 005 | read | 200 |  |
| API-09-026 | `PUT /detectors/{detectorCode}` | Sửa mẫu phát hiện, ngưỡng | 005 | classify | 200 | 015, 016, 017 |
| API-09-027 | `GET /contract-levels` | Mức phân loại của hợp đồng | 006 | read | 200 |  |
| API-09-028 | `GET /contract-levels/{kind}/{contractId}` | Chi tiết mức một hợp đồng | 006 | read | 200 |  |
| API-09-029 | `POST /contract-levels:recompute` | Tính lại mức hợp đồng | 006 | s:privacy:register | 202 | 035 |
| API-09-030 | `POST /classification-exports` | Xuất danh mục phân loại (nền) | 008 | read | 202 |  |
| API-09-031 | `GET /classification-exports/{exportId}` | Trạng thái, tải tệp xuất | 008 | read | 200 |  |
| API-09-243 | `POST /data-elements/{elementId}:retire` | Ngừng phần tử dữ liệu | 003 | classify | 200 | 014, 015 |

: Danh mục API nhóm Phân loại

### 3.2. Sổ hoạt động xử lý

Hoạt động xử lý, liên kết, cơ sở pháp lý, văn bản căn cứ, xuất sổ (FR-09-009…013). Nhóm có 22 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-032 | `GET /processing-activities` | Liệt kê hoạt động xử lý | 009 | read | 200 |  |
| API-09-033 | `POST /processing-activities` | Tạo hoạt động xử lý | 009 | ropa | 201 | 020, 021, 024 |
| API-09-034 | `GET /processing-activities/{activityId}` | Chi tiết hoạt động | 009 | read | 200 |  |
| API-09-035 | `PUT /processing-activities/{activityId}` | Sửa bản nháp | 009 | ropa | 200 | 020, 021, 024 |
| API-09-036 | `POST /processing-activities/{activityId}:submit` | Gửi duyệt | 010 | ropa | 200 | 005, 020, 021, 023, 024 |
| API-09-037 | `POST /processing-activities/{activityId}:approve` | Duyệt, kích hoạt | 010 | ropa | 200 | 005, 020, 021, 023, 024 |
| API-09-038 | `POST /processing-activities/{activityId}:reject` | Từ chối | 010 | ropa | 200 | 005, 020, 021, 023, 024 |
| API-09-039 | `POST /processing-activities/{activityId}:retire` | Ngừng hoạt động | 010 | ropa | 200 | 005, 020, 021, 023, 024 |
| API-09-040 | `GET /processing-activities/{activityId}/versions` | Phiên bản và so sánh | 010 | read | 200 |  |
| API-09-041 | `GET /processing-activities/{activityId}/links` | Liên kết của hoạt động | 011 | read | 200 |  |
| API-09-042 | `POST /processing-activities/{activityId}/links` | Thêm liên kết | 011 | ropa | 201 | 022, 023 |
| API-09-043 | `DELETE /processing-activities/{activityId}/links/{linkId}` | Gỡ liên kết | 011 | ropa | 204 | 022, 023 |
| API-09-044 | `GET /processing-activities:unlinked-elements` | Trường DLCN chưa thuộc hoạt động nào | 011 | read | 200 |  |
| API-09-045 | `GET /legal-bases` | Cơ sở pháp lý | 012 | read | 200 |  |
| API-09-046 | `POST /legal-bases` | Thêm cơ sở pháp lý | 012 | ropa | 201 | 021 |
| API-09-047 | `PATCH /legal-bases/{code}` | Sửa, ngừng cơ sở | 012 | ropa | 200 | 021 |
| API-09-048 | `GET /legal-documents` | Danh mục văn bản căn cứ | 012 | read | 200 |  |
| API-09-049 | `POST /legal-documents` | Thêm văn bản căn cứ | 012 | ropa | 201 | 021 |
| API-09-050 | `PATCH /legal-documents/{documentId}` | Sửa hiệu lực văn bản | 012 | ropa | 200 | 021 |
| API-09-051 | `GET /ropa-templates` | Mẫu xuất sổ | 013 | read | 200 |  |
| API-09-052 | `POST /ropa-exports` | Xuất sổ theo mẫu (nền) | 013 | read | 202 | 025 |
| API-09-053 | `GET /ropa-exports/{exportId}` | Trạng thái, tải tệp | 013 | read | 200 |  |

: Danh mục API nhóm Sổ hoạt động xử lý

### 3.3. Mục đích và chấp thuận

Mục đích, yêu cầu khai thác, chấp thuận, bundle chính sách, cảnh báo khai thác, kiểm tra kích hoạt (FR-09-014…022). Nhóm có 36 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-054 | `GET /purposes` | Danh mục mục đích | 014 | read | 200 |  |
| API-09-055 | `POST /purposes` | Thêm mục đích | 014 | purpose-approve / policy | 201 | 026 |
| API-09-056 | `PATCH /purposes/{code}` | Sửa mục đích | 014 | purpose-approve / policy | 200 | 026 |
| API-09-057 | `POST /purposes/{code}:retire` | Ngừng mục đích | 014 | purpose-approve / policy | 200 | 026 |
| API-09-058 | `GET /access-requests` | Liệt kê yêu cầu khai thác | 015 | purpose-request / purpose-approve | 200 |  |
| API-09-059 | `POST /access-requests` | Tạo yêu cầu (nháp) | 015 | purpose-request | 201 | 027, 028 |
| API-09-060 | `GET /access-requests/{requestId}` | Chi tiết yêu cầu | 015 | purpose-request / purpose-approve | 200 |  |
| API-09-061 | `PUT /access-requests/{requestId}` | Sửa nháp | 015 | purpose-request | 200 | 027, 028 |
| API-09-062 | `POST /access-requests/{requestId}:submit` | Gửi thẩm định | 015 | purpose-request | 200 | 027, 028 |
| API-09-063 | `POST /access-requests/{requestId}:withdraw` | Rút yêu cầu | 015 | purpose-request | 200 | 027, 028 |
| API-09-064 | `GET /access-requests:inbox` | Hộp việc thẩm định của chủ quản | 016 | purpose-approve | 200 |  |
| API-09-065 | `POST /access-requests/{requestId}:decide` | Chấp thuận, chấp thuận có điều kiện, từ chối | 016 | purpose-approve | 200 | 005, 028, 029, 055 |
| API-09-066 | `POST /access-requests/{requestId}:request-info` | Yêu cầu bổ sung thông tin | 016 | purpose-approve | 200 | 005, 028, 029, 055 |
| API-09-067 | `GET /purpose-grants` | Liệt kê chấp thuận | 017 | purpose-request / purpose-approve | 200 |  |
| API-09-068 | `GET /purpose-grants/{grantId}` | Chi tiết chấp thuận | 017 | purpose-request / purpose-approve | 200 |  |
| API-09-069 | `POST /purpose-grants/{grantId}:renew` | Gia hạn | 017 | purpose-approve | 200 | 030, 031 |
| API-09-070 | `POST /purpose-grants/{grantId}:amend` | Sửa trường, điều kiện, hạn ngạch | 017 | purpose-approve | 200 | 030, 031 |
| API-09-071 | `POST /purpose-grants/{grantId}:suspend` | Tạm dừng | 017 | purpose-approve | 200 | 030, 031 |
| API-09-072 | `POST /purpose-grants/{grantId}:resume` | Khôi phục sau tạm dừng | 017 | purpose-approve | 200 | 030, 031 |
| API-09-073 | `POST /purpose-grants/{grantId}:revoke` | Thu hồi | 017 | purpose-approve | 200 | 030, 031 |
| API-09-074 | `GET /policy-bundles` | Lịch sử bundle | 018 | read | 200 |  |
| API-09-075 | `GET /policy-bundles/{bundleId}` | Chi tiết bundle, kết quả kiểm thử | 018 | read | 200 |  |
| API-09-076 | `POST /policy-bundles:publish` | Dựng và phát hành bundle thủ công | 018 | policy-approve | 201 | 032, 033 |
| API-09-077 | `POST /policy-bundles/{bundleId}:rollback` | Quay lại bundle trước | 018 | policy-approve | 200 | 032, 033 |
| API-09-078 | `GET /policy-bundles:sync-status` | Độ trễ đồng bộ của từng điểm thực thi | 018 | read | 200 |  |
| API-09-079 | `GET /usage-anomalies` | Liệt kê cảnh báo khai thác | 020 | read | 200 |  |
| API-09-080 | `GET /usage-anomalies/{anomalyId}` | Chi tiết cảnh báo | 020 | read | 200 |  |
| API-09-081 | `POST /usage-anomalies/{anomalyId}:acknowledge` | Ghi nhận đã xem | 020 | purpose-approve / breach | 200 | 034 |
| API-09-082 | `POST /usage-anomalies/{anomalyId}:dismiss` | Loại trừ có lý do | 020 | purpose-approve / breach | 200 | 034 |
| API-09-083 | `POST /usage-anomalies/{anomalyId}:escalate` | Chuyển thành vụ việc vi phạm | 020 | breach | 201 | 034 |
| API-09-084 | `GET /anomaly-rules` | Quy tắc, ngưỡng cảnh báo | 020 | read | 200 |  |
| API-09-085 | `PUT /anomaly-rules` | Sửa ngưỡng cảnh báo | 020 | config | 200 | 034 |
| API-09-086 | `GET /usage-reports` | Báo cáo khai thác theo mục đích | 021 | read | 200 | 036 |
| API-09-087 | `POST /usage-reports:export` | Xuất báo cáo khai thác (nền) | 021 | read | 202 | 036 |
| API-09-088 | `POST /activation-checks` | Kiểm tra điều kiện kích hoạt hợp đồng (PH-02, PH-04) | 022 | s:privacy:register | 200 | 035 |
| API-09-089 | `GET /activation-checks:blocked` | Hợp đồng đang bị chặn kích hoạt | 022 | read | 200 |  |

: Danh mục API nhóm Mục đích và chấp thuận

### 3.4. Che dữ liệu

Kiểu che, chính sách che, mô phỏng, xem đầy đủ, che log, rò rỉ log (FR-09-023…030). Nhóm có 20 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-090 | `GET /mask-types` | Kiểu che và mẫu che | 023 | read | 200 |  |
| API-09-091 | `PUT /mask-types/{code}/patterns` | Sửa mẫu che của kiểu | 023 | policy | 200 | 037 |
| API-09-092 | `GET /mask-policies` | Liệt kê chính sách che | 024 | read | 200 |  |
| API-09-093 | `POST /mask-policies` | Tạo chính sách (phiên bản nháp) | 024 | policy | 201 | 038 |
| API-09-094 | `GET /mask-policies/{policyId}` | Chi tiết, quy tắc, phiên bản | 024 | read | 200 |  |
| API-09-095 | `PUT /mask-policies/{policyId}/versions/{version}` | Sửa quy tắc bản nháp | 024 | policy | 200 | 038 |
| API-09-096 | `POST /mask-policies/{policyId}/versions/{version}:submit` | Gửi duyệt | 026 | policy | 200 | 005, 040 |
| API-09-097 | `POST /mask-policies/{policyId}/versions/{version}:approve` | Duyệt, kích hoạt | 026 | policy-approve | 200 | 005, 040 |
| API-09-098 | `POST /mask-policies/{policyId}/versions/{version}:reject` | Từ chối | 026 | policy-approve | 200 | 005, 040 |
| API-09-099 | `POST /mask-policies/{policyId}:rollback` | Quay lại phiên bản trước | 026 | policy-approve | 200 | 005, 040 |
| API-09-100 | `GET /mask-policies/{policyId}/versions/{version}/diff` | So sánh hai phiên bản | 026 | read | 200 |  |
| API-09-101 | `POST /mask-simulations` | Mô phỏng chính sách trên dữ liệu mẫu | 025 | policy | 200 | 039, 080 |
| API-09-102 | `POST /reveal-grants` | Xin xem giá trị đầy đủ có lý do | 029 | unmask | 201 | 041, 042, 043 |
| API-09-103 | `GET /reveal-grants` | Lịch sử xem đầy đủ | 029 | audit-read | 200 |  |
| API-09-104 | `GET /log-masking-config` | Cấu hình che log | 030 | read | 200 |  |
| API-09-105 | `PUT /log-masking-config` | Sửa cấu hình che log | 030 | policy | 200 | 044 |
| API-09-106 | `GET /leak-findings` | Kết quả quét rò rỉ log | 030 | read | 200 |  |
| API-09-107 | `POST /leak-findings/{findingId}:resolve` | Xử lý kết quả rò rỉ | 030 | policy | 200 | 044 |
| API-09-108 | `POST /leak-scans` | Chạy quét rò rỉ ngay | 030 | policy | 202 | 044 |
| API-09-241 | `GET /reveal-grants/{grantId}` | Chi tiết một phiếu xem đầy đủ (không kèm giá trị) | 029 | audit-read | 200 |  |

: Danh mục API nhóm Che dữ liệu

### 3.5. Giả danh và ẩn danh

Miền và khóa giả danh, khôi phục giá trị gốc, cấu hình và job ẩn danh, rủi ro, chuẩn bị dữ liệu, tập đã ẩn danh (FR-09-031…039). Nhóm có 36 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-109 | `GET /pseudonym-domains` | Liệt kê miền giả danh | 031 | read | 200 |  |
| API-09-110 | `POST /pseudonym-domains` | Tạo miền (kèm khóa đầu tiên) | 031 | policy | 201 | 045, 048 |
| API-09-111 | `GET /pseudonym-domains/{domainCode}` | Chi tiết miền | 031 | read | 200 |  |
| API-09-112 | `PATCH /pseudonym-domains/{domainCode}` | Sửa mô tả, chu kỳ xoay | 031 | policy | 200 | 045, 048 |
| API-09-113 | `POST /pseudonym-domains/{domainCode}:suspend` | Tạm dừng miền | 031 | policy | 200 | 045, 048 |
| API-09-114 | `POST /pseudonym-domains/{domainCode}:retire` | Ngừng miền | 031 | policy-approve | 200 | 045, 048 |
| API-09-115 | `GET /pseudonym-domains/{domainCode}/keys` | Phiên bản khóa của miền | 034 | read | 200 |  |
| API-09-116 | `POST /pseudonym-domains/{domainCode}/keys:rotate` | Xoay khóa | 034 | policy-approve | 201 | 046, 047 |
| API-09-117 | `POST /pseudonym-keys/{keyId}:disable` | Ngừng khóa (chỉ giải) | 034 | policy-approve | 200 | 046, 047 |
| API-09-118 | `POST /pseudonym-keys/{keyId}:destroy` | Hủy khóa (hai người) | 034 | policy-approve | 200 | 046, 047 |
| API-09-119 | `POST /reidentification-requests` | Đề nghị khôi phục giá trị gốc | 033 | reidentify | 201 | 005, 048, 049, 050 |
| API-09-120 | `GET /reidentification-requests` | Liệt kê đề nghị | 033 | reidentify / audit-read | 200 |  |
| API-09-121 | `GET /reidentification-requests/{requestId}` | Chi tiết đề nghị | 033 | reidentify / audit-read | 200 |  |
| API-09-122 | `POST /reidentification-requests/{requestId}:approve` | Duyệt cấp một, cấp hai | 033 | purpose-approve / policy-approve | 200 | 005, 048, 049, 050 |
| API-09-123 | `POST /reidentification-requests/{requestId}:reject` | Từ chối | 033 | purpose-approve / policy-approve | 200 | 005, 048, 049, 050 |
| API-09-124 | `POST /reidentification-requests/{requestId}:execute` | Thực hiện khôi phục (yêu cầu MFA) | 033 | reidentify | 200 | 005, 048, 049, 050 |
| API-09-125 | `GET /anonymization-configs` | Cấu hình ẩn danh | 035 | read | 200 |  |
| API-09-126 | `POST /anonymization-configs` | Tạo cấu hình | 035 | anonymize | 201 | 051 |
| API-09-127 | `GET /anonymization-configs/{configId}` | Chi tiết cấu hình | 035 | read | 200 |  |
| API-09-128 | `PUT /anonymization-configs/{configId}` | Sửa bản nháp | 035 | anonymize | 200 | 051 |
| API-09-129 | `POST /anonymization-configs/{configId}:approve` | Duyệt cấu hình (bốn mắt) | 035 | policy-approve | 200 | 051 |
| API-09-130 | `POST /anonymization-jobs` | Chạy ẩn danh hóa tập dữ liệu | 036 | anonymize | 202 | 052, 054 |
| API-09-131 | `GET /anonymization-jobs` | Liệt kê job | 036 | read | 200 |  |
| API-09-132 | `GET /anonymization-jobs/{jobId}` | Chi tiết job | 036 | read | 200 |  |
| API-09-133 | `POST /anonymization-jobs/{jobId}:cancel` | Hủy job | 036 | anonymize | 200 | 052, 054 |
| API-09-134 | `GET /anonymization-jobs/{jobId}/risk-report` | Báo cáo rủi ro của job | 037 | read | 200 |  |
| API-09-135 | `POST /anonymization-jobs/{jobId}:approve-risk` | Duyệt rủi ro mức MEDIUM | 037 | policy-approve | 200 | 053 |
| API-09-136 | `POST /risk-assessments` | Đánh giá rủi ro tập có sẵn | 037 | anonymize | 202 | 053 |
| API-09-137 | `POST /data-preparations` | Chuẩn bị dữ liệu cho AI, môi trường không phải PROD | 038 | anonymize; s:privacy:register | 202 | 055, 082 |
| API-09-138 | `GET /data-preparations/{preparationId}` | Trạng thái chuẩn bị | 038 | read | 200 |  |
| API-09-139 | `GET /data-preparations` | Liệt kê yêu cầu chuẩn bị | 038 | read | 200 |  |
| API-09-140 | `GET /anonymized-datasets` | Liệt kê tập đã ẩn danh | 039 | read | 200 |  |
| API-09-141 | `GET /anonymized-datasets/{datasetId}` | Chi tiết tập | 039 | read | 200 |  |
| API-09-142 | `POST /anonymized-datasets/{datasetId}:publish` | Phát hành tập | 039 | anonymize | 200 | 053, 056 |
| API-09-143 | `POST /anonymized-datasets/{datasetId}:withdraw` | Rút lại tập | 039 | anonymize | 200 | 053, 056 |
| API-09-144 | `PUT /anonymized-datasets/{datasetId}/terms` | Điều kiện sử dụng, hạn dùng | 039 | anonymize | 200 | 053, 056 |

: Danh mục API nhóm Giả danh và ẩn danh

### 3.6. Lưu giữ

Lịch lưu giữ, tác vụ xóa, giữ pháp lý, xóa mật mã tenant, báo cáo lưu giữ (FR-09-040…044). Nhóm có 19 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-145 | `GET /retention-schedules` | Lịch lưu giữ | 040 | read | 200 |  |
| API-09-146 | `POST /retention-schedules` | Tạo lịch (bản nháp) | 040 | retention | 201 | 005, 057 |
| API-09-147 | `GET /retention-schedules/{scheduleId}` | Chi tiết lịch | 040 | read | 200 |  |
| API-09-148 | `PUT /retention-schedules/{scheduleId}` | Sửa bản nháp | 040 | retention | 200 | 005, 057 |
| API-09-149 | `POST /retention-schedules/{scheduleId}:submit` | Gửi duyệt | 040 | retention | 200 | 005, 057 |
| API-09-150 | `POST /retention-schedules/{scheduleId}:approve` | Duyệt, kích hoạt | 040 | policy-approve | 200 | 005, 057 |
| API-09-151 | `POST /retention-schedules/{scheduleId}:reject` | Từ chối | 040 | policy-approve | 200 | 005, 057 |
| API-09-152 | `GET /retention-tasks` | Tác vụ xóa, giả danh hóa | 041 | read | 200 |  |
| API-09-153 | `GET /retention-tasks/{taskId}` | Chi tiết tác vụ | 041 | read | 200 |  |
| API-09-154 | `POST /retention-tasks:run` | Chạy ngay hoặc chạy thử (dry-run) | 041 | retention | 202 | 058, 061 |
| API-09-155 | `POST /retention-tasks/{taskId}:cancel` | Hủy tác vụ chưa chạy | 041 | retention | 200 | 058, 061 |
| API-09-156 | `GET /legal-holds` | Giữ pháp lý | 042 | read | 200 |  |
| API-09-157 | `POST /legal-holds` | Đặt giữ pháp lý | 042 | retention | 201 | 058, 059 |
| API-09-158 | `POST /legal-holds/{holdId}:release` | Gỡ giữ pháp lý | 042 | retention | 200 | 058, 059 |
| API-09-159 | `POST /tenant-shred-requests` | Đề nghị xóa mật mã tenant | 043 | retention | 201 | 005, 060 |
| API-09-160 | `GET /tenant-shred-requests/{requestId}` | Trạng thái xóa mật mã | 043 | read | 200 |  |
| API-09-161 | `POST /tenant-shred-requests/{requestId}:approve` | Duyệt xóa mật mã (hai người) | 043 | policy-approve | 200 | 005, 060 |
| API-09-162 | `POST /tenant-shred-requests/{requestId}:cancel` | Hủy trước khi thực hiện | 043 | retention | 200 | 005, 060 |
| API-09-163 | `GET /retention-reports` | Báo cáo tuân thủ thời hạn lưu | 044 | read | 200 |  |

: Danh mục API nhóm Lưu giữ

### 3.7. Quyền chủ thể

Yêu cầu của chủ thể dữ liệu từ tiếp nhận đến đóng, báo cáo (FR-09-045…051). Nhóm có 20 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-164 | `GET /subject-requests` | Liệt kê yêu cầu chủ thể | 045 | dsr | 200 |  |
| API-09-165 | `POST /subject-requests` | Tiếp nhận yêu cầu | 045 | dsr; s:privacy:register | 201 | 062, 064, 065 |
| API-09-166 | `GET /subject-requests/{requestId}` | Chi tiết yêu cầu | 045 | dsr | 200 |  |
| API-09-167 | `POST /subject-requests/{requestId}:verify` | Ghi kết quả xác minh danh tính | 046 | dsr | 200 | 063 |
| API-09-168 | `POST /subject-requests/{requestId}:search` | Tra cứu dữ liệu về chủ thể | 047 | dsr | 202 | 063 |
| API-09-169 | `GET /subject-requests/{requestId}/findings` | Kết quả tra cứu | 047 | dsr | 200 |  |
| API-09-170 | `POST /subject-requests/{requestId}/tasks` | Tạo, chuyển tác vụ | 048 | dsr | 201 | 066 |
| API-09-171 | `GET /subject-requests/{requestId}/tasks` | Liệt kê tác vụ | 048 | dsr | 200 |  |
| API-09-172 | `POST /subject-requests/{requestId}/tasks/{taskId}:complete` | Báo hoàn tất tác vụ | 048 | dsr; s:privacy:register | 200 | 066 |
| API-09-173 | `POST /subject-requests/{requestId}:assign` | Phân công người xử lý | 048 | dsr | 200 | 066 |
| API-09-174 | `GET /subject-requests:due` | Yêu cầu sắp đến hạn, quá hạn | 049 | dsr | 200 |  |
| API-09-175 | `POST /subject-requests/{requestId}:respond` | Soạn, gửi câu trả lời | 050 | dsr | 200 | 063, 067, 068 |
| API-09-176 | `POST /subject-requests/{requestId}:close` | Đóng yêu cầu | 050 | dsr | 200 | 063, 067, 068 |
| API-09-177 | `POST /subject-requests/{requestId}:reject` | Từ chối có căn cứ | 050 | dsr | 200 | 063, 067, 068 |
| API-09-178 | `POST /subject-requests/{requestId}:lift-restriction` | Gỡ hạn chế xử lý | 048 | dsr | 200 | 066 |
| API-09-179 | `POST /subject-requests/{requestId}:access-report` | Lập báo cáo ai đã truy cập dữ liệu | 051 | dsr | 202 |  |
| API-09-180 | `GET /subject-requests/{requestId}/access-report` | Tải báo cáo truy cập | 051 | dsr | 200 |  |
| API-09-181 | `GET /subject-request-reports` | Báo cáo xử lý yêu cầu, tuân thủ hạn | 051 | dsr / audit-read | 200 |  |
| API-09-242 | `POST /subject-requests/{requestId}:extend` | Gia hạn hạn trả lời kèm lý do | 049 | dsr | 200 |  |
| API-09-244 | `POST /subject-requests/{requestId}:withdraw` | Rút yêu cầu của chủ thể | 045 | dsr | 200 | 062, 064, 065 |

: Danh mục API nhóm Quyền chủ thể

### 3.8. Sự đồng ý

Mẫu đồng ý, bản ghi đồng ý, bằng chứng (FR-09-052…054). Nhóm có 12 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-182 | `GET /consent-templates` | Mẫu đồng ý | 052 | consent | 200 |  |
| API-09-183 | `POST /consent-templates` | Tạo mẫu | 052 | consent | 201 | 005, 069, 070 |
| API-09-184 | `PUT /consent-templates/{templateCode}/versions/{version}` | Sửa bản nháp | 052 | consent | 200 | 005, 069, 070 |
| API-09-185 | `POST /consent-templates/{templateCode}/versions/{version}:submit` | Gửi duyệt | 052 | consent | 200 | 005, 069, 070 |
| API-09-186 | `POST /consent-templates/{templateCode}/versions/{version}:approve` | Duyệt, kích hoạt | 052 | policy-approve | 200 | 005, 069, 070 |
| API-09-187 | `POST /consent-templates/{templateCode}:retire` | Ngừng mẫu | 052 | consent | 200 | 005, 069, 070 |
| API-09-188 | `POST /consents` | Ghi nhận đồng ý | 053 | consent; s:privacy:consent | 201 | 071, 072 |
| API-09-189 | `POST /consents/{consentId}:withdraw` | Rút đồng ý | 053 | consent; s:privacy:consent | 200 | 071, 072 |
| API-09-190 | `GET /consents` | Tra cứu đồng ý theo băm chủ thể, mẫu | 053 | consent | 200 |  |
| API-09-191 | `GET /consents/{consentId}/proof` | Bằng chứng đồng ý | 053 | consent | 200 |  |
| API-09-238 | `GET /consent-templates/{templateCode}` | Chi tiết mẫu đồng ý và các phiên bản | 052 | consent | 200 |  |
| API-09-245 | `POST /consents:search` | Tra đồng ý theo định danh trong thân, trả danh sách theo băm | 053 | consent | 200 | 071, 072 |

: Danh mục API nhóm Sự đồng ý

### 3.9. DPIA và vi phạm

Hồ sơ đánh giá tác động, vụ việc vi phạm dữ liệu cá nhân, đồng hồ 72 giờ (FR-09-055…060). Nhóm có 25 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-192 | `GET /dpia-records` | Liệt kê hồ sơ đánh giá tác động | 055 | ropa | 200 |  |
| API-09-193 | `POST /dpia-records` | Tạo hồ sơ | 055 | ropa | 201 | 073 |
| API-09-194 | `GET /dpia-records/{dpiaId}` | Chi tiết hồ sơ | 055 | ropa | 200 |  |
| API-09-195 | `PUT /dpia-records/{dpiaId}` | Sửa bản nháp | 055 | ropa | 200 | 073 |
| API-09-196 | `POST /dpia-records/{dpiaId}:submit` | Gửi duyệt | 056 | ropa | 200 | 005, 073 |
| API-09-197 | `POST /dpia-records/{dpiaId}:approve` | Duyệt | 056 | ropa | 200 | 005, 073 |
| API-09-198 | `POST /dpia-records/{dpiaId}:reject` | Từ chối | 056 | ropa | 200 | 005, 073 |
| API-09-199 | `GET /dpia-records:reviews-due` | Hồ sơ đến hạn rà soát | 056 | ropa | 200 |  |
| API-09-200 | `POST /dpia-records/{dpiaId}:export-a05` | Xuất hồ sơ gửi Cục A05 (nền) | 057 | ropa | 202 | 074 |
| API-09-201 | `POST /dpia-records/{dpiaId}:mark-submitted` | Ghi nhận đã gửi, số công văn | 057 | ropa | 200 | 074 |
| API-09-202 | `GET /breaches` | Liệt kê vụ việc | 058 | breach | 200 |  |
| API-09-203 | `POST /breaches` | Ghi nhận vi phạm (người dùng hoặc PH-18) | 058 | breach; s:privacy:register | 201 | 075 |
| API-09-204 | `GET /breaches/{breachId}` | Chi tiết vụ việc | 058 | breach | 200 |  |
| API-09-205 | `PATCH /breaches/{breachId}` | Cập nhật mô tả, phạm vi | 058 | breach | 200 | 075 |
| API-09-206 | `POST /breaches/{breachId}:assess` | Đánh giá ảnh hưởng, mức nghiêm trọng | 058 | breach | 200 | 075 |
| API-09-207 | `GET /breaches/{breachId}/clock` | Đồng hồ 72 giờ | 059 | breach | 200 |  |
| API-09-208 | `POST /breaches/{breachId}/notifications` | Soạn thông báo Cục A05, chủ thể | 059 | breach | 201 | 076, 077 |
| API-09-209 | `POST /breaches/{breachId}/notifications/{notificationId}:mark-sent` | Ghi nhận đã gửi | 059 | breach | 200 | 076, 077 |
| API-09-210 | `POST /breaches/{breachId}/affected-subjects` | Nhập danh sách chủ thể bị ảnh hưởng (băm) | 059 | breach | 200 | 076, 077 |
| API-09-211 | `POST /breaches/{breachId}/actions` | Ghi biện pháp khắc phục | 060 | breach | 201 | 076 |
| API-09-212 | `POST /breaches/{breachId}/lessons` | Ghi bài học | 060 | breach | 200 | 076 |
| API-09-213 | `POST /breaches/{breachId}:close` | Đóng hồ sơ | 060 | breach | 200 | 076 |
| API-09-214 | `GET /breaches/{breachId}/dossier` | Tải hồ sơ vi phạm | 060 | breach | 200 |  |
| API-09-239 | `GET /breaches/{breachId}/notifications` | Liệt kê thông báo của vụ việc | 059 | breach | 200 |  |
| API-09-240 | `GET /breaches/{breachId}/actions` | Liệt kê biện pháp khắc phục của vụ việc | 060 | breach | 200 |  |

: Danh mục API nhóm DPIA và vi phạm

### 3.10. Kiểm toán và tham số

Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo tuân thủ, tham số tenant (FR-09-061…064). Nhóm có 12 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-215 | `GET /audit-events` | Tra nhật ký bảo vệ dữ liệu | 061 | audit-read | 200 | 079 |
| API-09-216 | `GET /audit-events/{eventId}` | Chi tiết bản ghi | 061 | audit-read | 200 |  |
| API-09-217 | `POST /audit-exports` | Xuất nhật ký (nền) | 061 | audit-read | 202 | 079 |
| API-09-218 | `GET /compliance-dashboard` | Số liệu bảng điều khiển | 062 | read | 200 |  |
| API-09-219 | `GET /compliance-dashboard/metrics/{metric}` | Chi tiết một chỉ số | 062 | read | 200 |  |
| API-09-220 | `GET /compliance-reports` | Báo cáo tuân thủ đã lập | 063 | read | 200 |  |
| API-09-221 | `POST /compliance-reports` | Lập báo cáo theo kỳ | 063 | read | 202 |  |
| API-09-222 | `GET /compliance-reports/{reportId}` | Tải báo cáo | 063 | read | 200 |  |
| API-09-223 | `PUT /compliance-reports:schedule` | Lịch lập báo cáo | 063 | config | 200 |  |
| API-09-224 | `GET /settings` | Tham số tenant | 064 | config | 200 |  |
| API-09-225 | `PUT /settings` | Sửa tham số | 064 | config | 200 | 078 |
| API-09-226 | `GET /settings/history` | Lịch sử sửa tham số | 064 | config | 200 |  |

: Danh mục API nhóm Kiểm toán và tham số

### 3.11. Data plane

API quyết định và áp che cho điểm thực thi, đường nóng, chỉ trong cụm (FR-09-007, 018, 019, 020, 027…029, 032, 047, 054). Nhóm có 11 operation.

| Mã | Thao tác | Mục đích | FR | Quyền, scope | TC | Lỗi riêng |
|---|---|---|---|---|---|---|
| API-09-227 | `POST /privacy/v1/purpose:decide` | Quyết định mục đích trực tuyến | 019 | s:privacy:decide | 200 | 101, 102, 103, 104, 106, 111, 113 |
| API-09-228 | `POST /privacy/v1/mask-plans:resolve` | Kế hoạch che theo chủ thể, mục đích, kênh | 027 | s:privacy:decide | 200 | 101, 103, 105, 106, 111 |
| API-09-229 | `POST /privacy/v1/messages:apply` | Áp che bản tin cho luồng | 028 | s:privacy:apply | 200 | 101, 105, 106, 107, 110, 111 |
| API-09-230 | `POST /privacy/v1/pseudonyms:issue` | Giả danh hóa lô giá trị | 032 | s:privacy:pseudonymize | 200 | 106, 107, 108, 109, 110, 111 |
| API-09-231 | `POST /privacy/v1/classification:check` | Kiểm tra nhãn chặn và phân loại bản tin, lược đồ | 007, 028 | s:privacy:decide | 200 | 101, 106, 111 |
| API-09-232 | `GET /privacy/v1/classification-index` | Bản chụp chỉ mục phân loại (ETag) | 027 | s:privacy:decide | 200 | 111 |
| API-09-233 | `GET /privacy/v1/bundles/current` | Bundle OPA hiện hành (ETag) | 018 | s:privacy:decide | 200 | 111 |
| API-09-234 | `POST /privacy/v1/consents:check` | Tra trạng thái đồng ý | 054 | s:privacy:consent | 200 | 106, 111 |
| API-09-235 | `POST /privacy/v1/subject-hashes:compute` | Tính băm HMAC định danh chủ thể | 047, 053 | s:privacy:decide | 200 | 106, 108, 111 |
| API-09-236 | `POST /privacy/v1/reveal-grants/{grantId}:verify` | Xác thực phiếu xem đầy đủ | 029 | s:privacy:decide | 200 | 111, 112 |
| API-09-237 | `POST /privacy/v1/usage-events:report` | Điểm thực thi báo lượt khai thác theo lô | 020 | s:privacy:decide | 202 | 106, 107, 111, 113 |

: Danh mục API nhóm Data plane
<!-- gen:catalog:end -->

## 4. Danh mục sự kiện

PH-09 phát 32 sự kiện EVT-09-01…32 cộng bản ghi kiểm toán, qua bảng `outbox_event` và Debezium Outbox Event Router (ADR-042); đặc tả máy đọc ở [`ph09/asyncapi-privacy.yaml`](ph09/asyncapi-privacy.yaml). Topic có dạng `{tenant}.privacy.<tên>.v1` (`{tenant}` chữ thường, ví dụ `t68`); đăng ký topic qua FR-10-067. Cột "Trường dữ liệu" liệt kê thuộc tính của `data`; không trường nào mang giá trị DLCN (BR-09-025).

### 4.1. Sự kiện của PH-09

Bảng sau lấy từ AsyncAPI, bám FRS §9.3.

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Bên tiêu thụ | Trường dữ liệu |
|---|---|---|---|---|
| EVT-09-01 | `{tenant}.privacy.classification.changed.v1` | Phân loại trường được xác nhận, đổi hoặc hạ mức (kèm mức cũ, mới) | PH-02, PH-04, PH-06, PH-08, PH-13, PH-17 | `elementId`, `target`, `fromClass`, `toClass`, `personalDataType`, `downgrade`, `contractIds` |
| EVT-09-02 | `{tenant}.privacy.classification.scan-finished.v1` | Lượt quét phát hiện kết thúc | PH-13, UI-09-04 | `scanId`, `status`, `suspectCount` |
| EVT-09-03 | `{tenant}.privacy.contract-level.changed.v1` | Mức phân loại của hợp đồng API, topic, luồng đổi | PH-02, PH-03, PH-04, PH-10, PH-17 | `contractKind`, `contractId`, `fromClass`, `toClass`, `blocked` |
| EVT-09-04 | `{tenant}.privacy.activity.activated.v1` | Hoạt động xử lý được kích hoạt hoặc ngừng | PH-13 | `activityId`, `code`, `versionNo`, `status` |
| EVT-09-05 | `{tenant}.privacy.purpose-request.submitted.v1` | Yêu cầu khai thác được gửi thẩm định | PH-11 hoặc Việc của tôi, chủ quản dữ liệu | `requestId`, `requestKind`, `renewsGrantId`, `htttId`, `purposeCode`, `contractId`, `ownerOrgId`, `dueAt` |
| EVT-09-06 | `{tenant}.privacy.purpose-grant.approved.v1` | Chấp thuận được cấp hoặc sửa, gia hạn | PH-02, PH-03, PH-12, HTTT yêu cầu | `grantId`, `htttId`, `purposeCode`, `contractKind`, `contractId`, `validUntil`, `change` |
| EVT-09-07 | `{tenant}.privacy.purpose-grant.suspended.v1` | Chấp thuận bị tạm dừng hoặc khôi phục | PH-02, PH-03, PH-12 | `grantId`, `htttId`, `purposeCode`, `status` |
| EVT-09-08 | `{tenant}.privacy.purpose-grant.revoked.v1` | Chấp thuận bị thu hồi | PH-02, PH-03, PH-04, PH-12, PH-14 | `grantId`, `htttId`, `purposeCode`, `contractId`, `revokedAt` |
| EVT-09-09 | `{tenant}.privacy.purpose-grant.expired.v1` | Chấp thuận tự hết hạn | PH-02, PH-03, PH-12 | `grantId`, `htttId`, `purposeCode`, `expiredAt` |
| EVT-09-10 | `{tenant}.privacy.purpose-grant.expiring.v1` | Chấp thuận còn 30 ngày đến hạn | Thông báo cho HTTT và chủ quản | `grantId`, `htttId`, `purposeCode`, `validUntil`, `daysLeft` |
| EVT-09-11 | `{tenant}.privacy.bundle.published.v1` | Bundle chính sách quyền riêng tư được ký và phát hành | PH-12 (OPA), PH-03, PH-13 | `bundleNo`, `objectRef`, `sha256`, `validUntil`, `trigger` |
| EVT-09-12 | `{tenant}.privacy.mask-policy.activated.v1` | Chính sách che được kích hoạt hoặc thay phiên bản | PH-03, PH-04, PH-06, PH-14, PH-19 | `policyId`, `code`, `versionNo`, `scope`, `contractId` |
| EVT-09-13 | `{tenant}.privacy.usage.anomaly-detected.v1` | Phát hiện khai thác vượt mục đích hoặc vượt hạn ngạch | PH-13, PH-18, SO | `anomalyId`, `anomalyType`, `htttId`, `purposeCode` |
| EVT-09-14 | `{tenant}.privacy.secret-label.blocked.v1` | Phát hiện dữ liệu mang nhãn STATE_SECRET (cảnh báo an ninh nghiêm trọng) | PH-13, PH-18, SO | `targetKind`, `targetId`, `label`, `detectedBy` |
| EVT-09-15 | `{tenant}.privacy.reveal.granted.v1` | Cấp phiếu xem giá trị đầy đủ (chỉ phát khi vượt ngưỡng bất thường) | PH-13, SO | `grantId`, `requestedBy`, `elementId`, `expiresAt` |
| EVT-09-16 | `{tenant}.privacy.pseudonym-key.state-changed.v1` | Khóa giả danh hóa tạo, xoay, ngừng hoặc hủy | PH-13, PH-18 | `domainCode`, `keyVersion`, `from`, `to` |
| EVT-09-17 | `{tenant}.privacy.reidentification.executed.v1` | Khôi phục giá trị gốc đã thực hiện | PH-13, SO | `requestId`, `domainCode`, `tokenCount`, `executedBy` |
| EVT-09-18 | `{tenant}.privacy.dataset.status-changed.v1` | Tập đã ẩn danh phát hành, rút lại hoặc hết hạn | PH-17, PH-13 | `datasetId`, `status` |
| EVT-09-19 | `{tenant}.privacy.retention.task-finished.v1` | Tác vụ xóa hoặc giả danh hóa kết thúc | PH-13, PH-18 | `taskId`, `tableName`, `action`, `status`, `rowsProcessed`, `rowsSkippedHold` |
| EVT-09-20 | `{tenant}.privacy.legal-hold.changed.v1` | Giữ pháp lý đặt hoặc gỡ | PH-06, PH-13, PH-19 | `holdId`, `status` |
| EVT-09-21 | `{tenant}.privacy.crypto-shred.completed.v1` | Xóa mật mã tenant hoàn tất | PH-20, PH-13 | `requestId`, `executedAt` |
| EVT-09-22 | `{tenant}.privacy.dsr.received.v1` | Yêu cầu của chủ thể được tiếp nhận | PH-06, PH-19 (tác vụ), PH-13 | `requestId`, `requestType`, `channel`, `subjectHash`, `dueAt` |
| EVT-09-23 | `{tenant}.privacy.dsr.due-soon.v1` | Yêu cầu còn 3 ngày làm việc đến hạn | SO, Việc của tôi | `requestId`, `requestType`, `dueAt`, `daysLeft` |
| EVT-09-24 | `{tenant}.privacy.dsr.overdue.v1` | Yêu cầu quá hạn xử lý | SO, PH-13 | `requestId`, `requestType`, `dueAt`, `overdueDays` |
| EVT-09-25 | `{tenant}.privacy.dsr.closed.v1` | Yêu cầu được đóng kèm kết quả | PH-06, PH-13 | `requestId`, `outcome`, `closedAt` |
| EVT-09-26 | `{tenant}.privacy.dsr.restriction-changed.v1` | Hạn chế xử lý của chủ thể được đặt hoặc gỡ | PH-06, PH-19, PH-14 | `requestId`, `subjectHash`, `restrictionActive` |
| EVT-09-27 | `{tenant}.privacy.consent.given.v1` | Sự đồng ý được ghi nhận | HTTT có tiện ích liên quan | `consentId`, `templateCode`, `templateVersion`, `subjectHash`, `channel` |
| EVT-09-28 | `{tenant}.privacy.consent.withdrawn.v1` | Sự đồng ý bị rút | HTTT có tiện ích liên quan, PH-13 | `consentId`, `templateCode`, `subjectHash`, `withdrawnAt` |
| EVT-09-29 | `{tenant}.privacy.dpia.review-due.v1` | Hồ sơ đánh giá tác động đến hạn rà soát | SO, Việc của tôi | `dpiaId`, `dpiaCode`, `reviewOn` |
| EVT-09-30 | `{tenant}.privacy.breach.recorded.v1` | Vi phạm dữ liệu cá nhân được ghi nhận (đồng hồ 72 giờ bắt đầu) | SO, PH-13, PH-18 | `breachId`, `detectedAt`, `deadlineAt`, `source`, `estimatedSubjects` |
| EVT-09-31 | `{tenant}.privacy.breach.deadline-near.v1` | Đồng hồ vi phạm còn dưới mốc cảnh báo (24, 48, 60 giờ) | SO, TA, PH-18 | `breachId`, `deadlineAt`, `remainingHours`, `level` |
| EVT-09-32 | `{tenant}.privacy.breach.notified.v1` | Đã thông báo Cục A05 hoặc chủ thể | PH-13 | `breachId`, `recipient`, `sentAt` |
| Ngoài danh mục | `{tenant}.privacy.audit.recorded.v1` | Bản ghi kiểm toán bảo vệ dữ liệu được ghi (chuyển PH-13) | PH-13 | `eventId`, `occurredAt`, `actor`, `action`, `targetType`, `targetId`, `outcome`, `purposeCode`, `traceId` |

: Danh mục sự kiện của PH-09
<!-- gen:events:end -->

### 4.2. Quy tắc chung của sự kiện

Phong bì CloudEvents 1.0 (`application/cloudevents+json`) với `id` là `eventId`, `tenantid` là khóa phân vùng Kafka (thứ tự theo tenant), `time` RFC 3339, `traceparent` truyền truy vết. Phát ít nhất một lần; bên tiêu thụ khử trùng theo `id` (bảng `inbox_event` giữ 7 ngày). Thứ tự bảo đảm trong một tenant và một kênh; không bảo đảm giữa kênh. Tương thích: thêm trường tùy chọn vào `data` là tương thích ngược; xóa hoặc đổi kiểu trường cần topic `.v2` chạy song song 6 tháng. Sự kiện chỉ mang mã, trạng thái, thời điểm, số lượng và băm chủ thể (HMAC, khóa riêng tenant); bản tin, định danh và giá trị không bao giờ có trong sự kiện, và CSDL chặn khóa giá trị ở `outbox_event` (D03-03-PH09 §1.4). Sự kiện `purpose-grant.revoked` và `suspended` có hiệu lực ở điểm thực thi trong p95 ≤ 15 giây (NFR-09-005); `purpose-grant.expiring` phát 30 ngày trước hạn (`09.grant.expiring-notice-days`).

### 4.3. Sự kiện PH-09 tiêu thụ

PH-09 tiêu thụ ba loại sự kiện của phân hệ khác, khử trùng bằng `inbox_event`: đổi phân loại hoặc dữ liệu chủ từ PH-06, báo lượt khai thác từ PH-14 và PH-04 (song song với API-09-237), sự cố bảo mật từ PH-18 để mở vụ việc vi phạm (nguồn `INCIDENT_PH18`). Tên topic và lược đồ thuộc đặc tả của phân hệ phát; chưa có hợp đồng chốt, nên PH-09 chỉ cam kết khử trùng và bỏ qua trường lạ (Q09-59).

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-09 không gọi NDXP, NDOP hay PayGov và không có API công khai ra ngoài tổ chức. Bảng sau là hợp đồng với phân hệ nội bộ và hạ tầng; cột "Chiều" cho biết bên nào gọi.

| Bên | Chiều | Operation, sự kiện | Mục đích |
|---|---|---|---|
| PH-01 Quản lý HTTT | PH-09 gọi (giao diện module, không HTTP) | Tra HTTT `ACTIVE` | Kiểm HTTT khi tạo yêu cầu khai thác (ERR-09-027) |
| PH-02 Danh mục, đăng ký | PH-02 gọi PH-09; PH-09 nghe PH-02 | 012, 029, 088; EVT-09-03 | Đăng ký phần tử, mức hợp đồng, chặn kích hoạt hợp đồng chứa dữ liệu Nhạy cảm |
| PH-03 Gateway | PH-03 gọi | 227, 228, 232, 233; EVT-09-06…12 | Quyết định mục đích, kế hoạch che, bundle cho `forward-auth` |
| PH-04 Tích hợp | PH-04 gọi | 227…231, 237, 088; EVT-09-03, 12 | Chặng che, giả danh hóa trong luồng |
| PH-06 Dữ liệu chủ | Hai chiều | 228, 229, 235, 168 và tác vụ 172; EVT-09-20, 22, 25, 26 | Che bản ghi vàng, tra cứu và xử lý yêu cầu chủ thể |
| PH-10 Sự kiện | PH-10 gọi | 012, 014; EVT-09-03 | Phân loại hợp đồng topic, chặn luồng chứa dữ liệu Nhạy cảm |
| PH-12 Chính sách (OPA) | PH-12 gọi | 233; EVT-09-11 | Nạp bundle đã ký |
| PH-13 Kiểm toán | PH-09 phát | `audit.recorded.v1`, EVT-09-01, 14, 15, 17, 21, 28 | Chuyển nhật ký sang kho WORM |
| PH-14 Cung cấp dữ liệu | PH-14 gọi | 227…229, 237 | Quyết định, che khi chia sẻ dữ liệu; `purpose:decide` trả `ropaActivityId`, `classification:check` với `egressScope` là `OUT_OF_PROVINCE` kiểm cờ `noEgress` trước khi gửi ra ngoài tỉnh, p95 ≤ 200 ms (chủ đầu tư chốt 27/11/2026) |
| PH-17 Dữ liệu AI | PH-17 gọi | 230, 137; EVT-09-18 | Giả danh hóa, nhận tập đã ẩn danh |
| PH-18 Sự cố | Hai chiều | 203 (nguồn `INCIDENT_PH18`); EVT-09-13, 19, 30, 31 | Mở vụ việc vi phạm, cảnh báo đồng hồ |
| PH-19 Thanh toán | PH-19 gọi | 228, 229, 172; EVT-09-20, 22, 26 | Che dữ liệu thanh toán, xử lý yêu cầu chủ thể |
| PH-20 Tenant | PH-20 gọi, PH-09 phát | EVT-09-21 | Chấm dứt tenant, xóa mật mã |
| OpenBao | PH-09 gọi | Transit mã hóa, HMAC, ký bundle | ERR-09-032, 108 khi không khả dụng |
| Keycloak | Qua BFF, APISIX | OIDC, JWKS | Xác thực người dùng và máy |
| Cục A05 | Ngoài hệ thống | Không có API; văn bản hoặc kênh nghiệp vụ | Thông báo vi phạm; ghi nhận bằng API-09-209, hồ sơ xuất bằng 200 |

: Hợp đồng của PH-09 với phân hệ khác và hạ tầng

## 6. Bảng mã lỗi ERR-09

Mã lỗi theo khung D03-04: `ERR-09-001…078` cho control plane, `ERR-09-101…113` cho data plane, để người vận hành điểm thực thi phân biệt được nguồn. Lỗi `401`, `403` thiếu quyền và `428` dùng mã nền ERR-00-401, ERR-00-403, ERR-00-428; lỗi phạm vi tổ chức dùng ERR-09-008. Cột thông báo là câu hiển thị cho người dùng (control plane) hoặc người vận hành (data plane), viết tiếng Việt, nêu việc đã xảy ra và việc cần làm, không lộ giá trị dữ liệu. Cột "Dùng ở API" là các operation có mã đó trong `x-datahub-errors` ngoài lỗi cấu trúc.

<!-- gen:errors:start -->
| Mã | HTTP | Thông báo | Dùng ở API |
|---|---|---|---|
| ERR-09-001 | 404, 410 | Không tìm thấy {đối tượng} {mã}. | Mọi `GET` bản ghi và hành động theo mã |
| ERR-09-002 | 409 | Mã {mã} đã được dùng. Chọn mã khác. | Thao tác tạo có mã nghiệp vụ |
| ERR-09-003 | 400 | Dữ liệu không hợp lệ: {chi tiết}. | Mọi thao tác có thân |
| ERR-09-004 | 409 | Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới. | Mọi `PUT`, `PATCH`, hành động có `If-Match` |
| ERR-09-005 | 403 | Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này. | Thao tác duyệt, từ chối, xác nhận |
| ERR-09-006 | 409 | Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này. | Mọi hành động chuyển trạng thái |
| ERR-09-007 | 422 | Nhập lý do tối thiểu 20 ký tự. | Thao tác cần lý do |
| ERR-09-008 | 403 | Bạn chỉ thao tác được trên dữ liệu thuộc tổ chức của mình. | Mọi API có quyền theo tổ chức |
| ERR-09-009 | 503 | Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút. | Thao tác gọi dịch vụ ngoài |
| ERR-09-010 | 503 | Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau. | Mọi thao tác ghi |
| ERR-09-011 | 409 | Mục {mã} đang được {n} trường sử dụng nên không ngừng được. | 008, 009 |
| ERR-09-012 | 422 | Trường {tên} là dữ liệu cá nhân, cần chọn loại dữ liệu cá nhân phù hợp. | 015…018 |
| ERR-09-013 | 422 | Hạ mức phân loại cần nêu số văn bản căn cứ và lý do. | 015…018 |
| ERR-09-014 | 409 | Phần tử {đích} đã được đăng ký. | 012…014, 243 |
| ERR-09-015 | 422 | Không đọc được lược đồ: {lý do}. | 012…014, 020, 024, 026 … |
| ERR-09-016 | 422 | Mẫu phát hiện không hợp lệ hoặc có thể làm chậm hệ thống. | 020, 024, 026 |
| ERR-09-017 | 409 | Đang có lượt quét cho phạm vi này. Chờ lượt quét xong. | 020, 024, 026 |
| ERR-09-018 | 422 | Dữ liệu mang nhãn bí mật nhà nước không được đưa vào Datahub. | 004…006 |
| ERR-09-019 | 422 | Gỡ nhãn bí mật nhà nước cần số và ngày văn bản giải mật. | 004…006 |
| ERR-09-020 | 422 | Hoạt động xử lý còn thiếu: {danh sách mục}. | 033, 035…039 |
| ERR-09-021 | 422 | Văn bản căn cứ {mã} không còn hiệu lực. Chọn căn cứ khác. | 033, 035…039 … |
| ERR-09-022 | 409 | Hoạt động còn {n} liên kết đang hiệu lực. Gỡ liên kết trước khi ngừng. | 042, 043 |
| ERR-09-023 | 422 | Có {n} trường dữ liệu cá nhân chưa thuộc hoạt động xử lý nào. | 036…039, 042, 043 |
| ERR-09-024 | 422 | Hoạt động bắt buộc theo luật không dùng sự đồng ý làm cơ sở pháp lý. | 033, 035…039 |
| ERR-09-025 | 422 | Mẫu xuất {mã} không tồn tại. | 052 |
| ERR-09-026 | 422 | Mục đích {mã} không còn hiệu lực. | 055…057 |
| ERR-09-027 | 422 | HTTT {mã} chưa hoạt động hoặc chưa có đăng ký sử dụng hợp lệ. | 059, 061…063 |
| ERR-09-028 | 422 | Trường {tên} nằm ngoài phạm vi của mục đích {mã}. | 059, 061…063, 065, 066 |
| ERR-09-029 | 409 | Đã có chấp thuận còn hiệu lực cho HTTT, mục đích và hợp đồng này. | 065, 066 |
| ERR-09-030 | 422 | Thời hạn chấp thuận tối đa {n} ngày. | 069…073 |
| ERR-09-031 | 422 | Chấp thuận đã gia hạn tối đa {n} lần. Lập yêu cầu mới. | 069…073 |
| ERR-09-032 | 503 | Chưa ký được gói chính sách vì OpenBao không khả dụng. Gói cũ vẫn có hiệu lực. | 076, 077 |
| ERR-09-033 | 422 | Gói chính sách không qua kiểm thử: {lỗi}. Không phát hành. | 076, 077 |
| ERR-09-034 | 422 | Ngưỡng cảnh báo không hợp lệ. | 081…083, 085 |
| ERR-09-035 | 422 | Hợp đồng {mã} chứa dữ liệu Nhạy cảm, cần mục đích và chấp thuận của chủ quản trước khi kích hoạt. | 029, 088 |
| ERR-09-036 | 422 | Chọn khoảng thời gian tối đa 12 tháng. | 086, 087 |
| ERR-09-037 | 422 | Kiểu che {kiểu} không áp dụng được cho trường kiểu {kiểu dữ liệu}. | 091 |
| ERR-09-038 | 422 | Chính sách có quy tắc trùng ưu tiên hoặc thiếu quy tắc mặc định cho mức Nhạy cảm. | 093, 095 |
| ERR-09-039 | 413 | Dữ liệu mẫu tối đa 1.000 dòng. | 101 |
| ERR-09-040 | 422 | Cần mô phỏng đạt trên bộ dữ liệu mẫu trước khi gửi duyệt. | 096…099 |
| ERR-09-041 | 403 | Bạn chưa được cấp quyền xem giá trị đầy đủ. | 102 |
| ERR-09-042 | 422 | Trường {tên} không cho phép xem giá trị đầy đủ. | 102 |
| ERR-09-043 | 429 | Đã vượt số lần xem giá trị đầy đủ trong giờ. Thử lại sau. | 102 |
| ERR-09-044 | 422 | Cấu hình che log không hợp lệ: {lý do}. | 105, 107, 108 |
| ERR-09-045 | 409 | Đã có miền giả danh cho mục đích này. | 110, 112…114 |
| ERR-09-046 | 409 | Khóa còn được sử dụng, chưa hủy được. | 116…118 |
| ERR-09-047 | 409 | Vừa xoay khóa gần đây. Chờ tối thiểu {n} ngày. | 116…118 |
| ERR-09-048 | 422 | Miền {mã} dùng HMAC không đảo ngược, không khôi phục được giá trị gốc. | 110, 112…114, 119, 122 … |
| ERR-09-049 | 422 | Mỗi đề nghị khôi phục tối đa {n} giá trị. | 119, 122…124 |
| ERR-09-050 | 409 | Đề nghị khôi phục đã hết hiệu lực. Lập đề nghị mới. | 119, 122…124 |
| ERR-09-051 | 422 | Ngưỡng k phải từ {n} trở lên. | 126, 128, 129 |
| ERR-09-052 | 422 | Còn trường định danh trực tiếp {tên} chưa được loại bỏ hoặc xử lý. | 130, 133 |
| ERR-09-053 | 422 | Rủi ro tái định danh cao, không phát hành. Xem khuyến nghị của báo cáo. | 135, 136, 142…144 |
| ERR-09-054 | 422 | Sau xử lý chỉ còn {x}% bản ghi, dữ liệu không còn giá trị thống kê. | 130, 133 |
| ERR-09-055 | 422 | Mục đích {mã} không cho phép dùng dữ liệu có trường Nhạy cảm. | 065, 066, 137 |
| ERR-09-056 | 409 | Tập dữ liệu đã phát hành, không sửa được. Rút lại để tạo tập mới. | 142…144 |
| ERR-09-057 | 422 | Bảng {tên} chứa dữ liệu cá nhân nhưng chưa có thời hạn lưu. | 146, 148…151 |
| ERR-09-058 | 409 | Dữ liệu đang bị giữ pháp lý, không xóa được cho đến khi gỡ giữ. | 154, 155, 157, 158 |
| ERR-09-059 | 422 | Giữ pháp lý cần số văn bản và cơ quan yêu cầu. | 157, 158 |
| ERR-09-060 | 422 | Chưa đủ điều kiện xóa mật mã tenant: {lý do}. | 159, 161, 162 |
| ERR-09-061 | 409 | Tác vụ xóa đang chạy, không chạy chồng. | 154, 155 |
| ERR-09-062 | 422 | Yêu cầu thiếu loại yêu cầu hoặc thông tin định danh chủ thể. | 165, 244 |
| ERR-09-063 | 422 | Chưa xác minh danh tính chủ thể. Hoàn tất xác minh trước khi xử lý. | 167, 168, 175…177 |
| ERR-09-064 | 409 | Chủ thể đã có yêu cầu cùng loại đang xử lý. | 165, 244 |
| ERR-09-065 | 403 | Người gửi chưa chứng minh là chủ thể hoặc người đại diện hợp pháp. | 165, 244 |
| ERR-09-066 | 502 | Chưa chuyển được yêu cầu tới {đích}. Hệ thống sẽ thử lại. | 170, 172, 173, 178 |
| ERR-09-067 | 422 | Còn {n} tác vụ chưa hoàn tất, chưa đóng được yêu cầu. | 175…177 |
| ERR-09-068 | 422 | Câu trả lời thiếu kết quả hoặc bằng chứng đính kèm. | 175…177 |
| ERR-09-069 | 422 | Mẫu đồng ý cần nêu mục đích cụ thể, dữ liệu xử lý và cách rút lại. | 183…187 |
| ERR-09-070 | 409 | Mẫu đã có người đồng ý. Tạo phiên bản mới thay vì sửa. | 183…187 |
| ERR-09-071 | 422 | Thiếu bằng chứng đồng ý: kênh, thời điểm, phiên bản mẫu. | 188, 189, 245 |
| ERR-09-072 | 409 | Sự đồng ý đã được rút hoặc hết hiệu lực. | 188, 189, 245 |
| ERR-09-073 | 422 | Hồ sơ đánh giá tác động còn thiếu: {mục}. | 193, 195…198 |
| ERR-09-074 | 409 | Hồ sơ chưa được duyệt, chưa xuất gửi Cục A05 được. | 200, 201 |
| ERR-09-075 | 422 | Vụ việc cần có thời điểm phát hiện và mô tả. | 203, 205, 206 |
| ERR-09-076 | 409 | Còn nghĩa vụ thông báo chưa hoàn tất, chưa đóng được hồ sơ. | 208…213 |
| ERR-09-077 | 422 | Không thông báo chủ thể cần nêu căn cứ miễn trừ và lý do. | 208…210 |
| ERR-09-078 | 422 | Giá trị của {khóa} ngoài miền cho phép {miền}. | 225 |
| ERR-09-079 | 422 | Chọn khoảng thời gian tối đa {n} ngày. | 215, 217 |
| ERR-09-080 | 422 | Dữ liệu mẫu có dấu hiệu là dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả. | 101 |
| ERR-09-081 | 409 | Idempotency-Key đã dùng với thân khác. Dùng khóa mới. | — |
| ERR-09-082 | 422 | Dữ liệu Hạn chế chưa được phép dùng cho AI. Đề nghị TA bật tham số 09.ai.allow-restricted. | 137 |
| ERR-09-101 | 403 | Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước. | 227…229, 231 |
| ERR-09-102 | 403 | Không có chấp thuận mục đích còn hiệu lực cho yêu cầu này. | 227 |
| ERR-09-103 | 400 | Thiếu mã mục đích hợp lệ trong yêu cầu. | 227, 228 |
| ERR-09-104 | 403 | Chủ thể đang bị hạn chế xử lý, mục đích này không được phép. | 227 |
| ERR-09-105 | 503 | Chưa lập được kế hoạch che, đang dùng chế độ đóng an toàn. | 228, 229 |
| ERR-09-106 | 400 | Yêu cầu không đúng lược đồ. | 227…231, 234 … |
| ERR-09-107 | 413 | Bản tin hoặc lô vượt giới hạn cho phép. | 229, 230, 237 |
| ERR-09-108 | 503 | Không băm có khóa hoặc token hóa được vì OpenBao không khả dụng. | 230, 235 |
| ERR-09-109 | 422 | Miền giả danh không hoạt động cho mục đích này. | 230 |
| ERR-09-110 | 503 | Không ghi được nhật ký thao tác che, thao tác bị từ chối. | 229, 230 |
| ERR-09-111 | 403 | Bên gọi không được phép dùng API quyền riêng tư. | 227…232 … |
| ERR-09-112 | 403 | Phiếu xem giá trị đầy đủ không hợp lệ hoặc đã hết hạn. | 236 |
| ERR-09-113 | 429 | Vượt hạn mức gọi API quyền riêng tư. | 227, 237 |

: Bảng mã lỗi ERR-09
<!-- gen:errors:end -->

### 6.1. Thân lỗi

Mọi lỗi dùng `application/problem+json` theo RFC 9457, thêm `code`, `traceId` và `errors[]` cho lỗi theo trường. Thông báo lấy từ bảng trên, thay `{...}` bằng giá trị mã hoặc số (không bao giờ giá trị DLCN).

```json
{ "type": "https://datahub.gov.vn/errors/ERR-09-005", "title": "Không được duyệt bước này", "status": 403,
  "code": "ERR-09-005", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "detail": "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này." }
```

### 6.2. Quy tắc áp mã cấu trúc

Bảy mã cấu trúc áp cho nhiều operation theo quy tắc, nên không lặp ở từng dòng: 001 cho `GET` bản ghi và hành động theo mã không tồn tại hoặc của tenant khác; 003 cho thân hoặc tham chiếu sai lược đồ; 004 cho lệch `If-Match`; 005 cho thao tác bốn mắt; 006 cho hành động không hợp lệ ở trạng thái hiện tại; 007 cho thao tác cần lý do dưới 20 ký tự; 010 khi không ghi được nhật ký kiểm toán (thao tác ghi bị từ chối, NFR-09-013). Danh sách mã cấu trúc đầy đủ của từng operation nằm ở `x-datahub-errors` của OpenAPI.

### 6.3. Mã lỗi mới của bản 0.2

Bốn mã dưới đây do tập API đề xuất ở bản 0.1 và FRS 0.2 đã nhận vào §9.1 với câu thông báo giữ nguyên; D03-06-PH09 dùng chung câu này. Cột "Dùng ở API" ghi nơi OpenAPI gắn mã.

| Mã | HTTP | Thông báo | Dùng ở API |
|---|---|---|---|
| ERR-09-079 | 422 | "Chọn khoảng thời gian tối đa {n} ngày." (`09.audit.query-max-days`) | 215, 217 |
| ERR-09-080 | 422 | "Dữ liệu mẫu có dấu hiệu là dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả." | 101 |
| ERR-09-081 | 409 | "Idempotency-Key đã dùng với thân khác. Dùng khóa mới." | Mọi `POST` có `Idempotency-Key` |
| ERR-09-082 | 422 | "Dữ liệu Hạn chế chưa được phép dùng cho AI. Đề nghị TA bật tham số 09.ai.allow-restricted." | 137 |

: Mã lỗi mới của bản 0.2

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng được kiểm ở mỗi pull request sửa FRS, `gen_openapi.py`, `gen_asyncapi.py` hoặc mã module `privacy`.

| Kiểm tra | Công cụ | Ngưỡng |
|---|---|---|
| Lint OpenAPI, AsyncAPI | Spectral với bộ luật chung của dự án | Không lỗi; mọi operation có `x-datahub-id`, `security`, lỗi RFC 9457 |
| Thay đổi phá vỡ | `oasdiff breaking` với nhánh chính | Không có thay đổi phá vỡ trong `v1` |
| Sinh lại ổn định | `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` rồi `git diff --exit-code` | Không chênh lệch |
| Mã, enum, ví dụ | `ph09/tools/check_contracts.py` | 245 mã khớp FRS; enum khớp Phụ lục A; mọi ví dụ khớp lược đồ; đủ 33 kênh; không khóa giá trị DLCN ở sự kiện |
| Hợp đồng bên tiêu thụ | Pact (PH-03, 04, 06, 14, 19 là bên tiêu thụ data plane) | Mọi tương tác đạt |
| Ca chuẩn Rego | Bộ ca vàng ≥ 300 ca so OPA và `mask-plans:resolve` | 100% khớp (NFR-09-008) |
| Cô lập tenant | `TenantIsolationIT` cho mọi API đọc | 0 truy vấn đọc được dữ liệu tenant khác (NFR-09-019) |
| Tải data plane | k6 trên 227, 228, 229 | p95 ≤ 50, 50, 80 ms (NFR-09-001…003) |

: Kiểm tra hợp đồng của PH-09 trong CI

Trình tự chạy lại sau khi sửa nguồn: `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` (gọi `build/tools/sinh_dac_ta_api.py` cho chương 13), rồi `check_contracts.py`. Chưa chạy Spectral, oasdiff trong lần soạn này (không có trong máy soạn); kiểm bằng `check_contracts.py` và nạp YAML.

## 8. Ánh xạ từ hệ cũ

### 8.1. API của SRS cũ

SRS cũ của repo (`SRS-PH-09-privacy.md` M5) có hai nhóm API: xử lý `/api/v1/privacy` và quản trị `/api/admin/v1/privacy`. Thiết kế mới tách đúng hai mặt phẳng, đổi tiền tố và tách khôi phục giá trị gốc thành ba bước bốn mắt.

| API cũ | API mới | Thay đổi |
|---|---|---|
| `POST /api/v1/privacy/apply` | API-09-229 `POST /privacy/v1/messages:apply` | Kèm hợp đồng, mục đích, kênh; kế hoạch che lấy từ chính sách |
| `POST /api/v1/privacy/check-classification` | API-09-231 `classification:check` | Thêm kiểm nhãn STATE_SECRET |
| `POST /api/v1/privacy/pseudonymize` | API-09-230 `pseudonyms:issue` | Theo miền; lô ≤ 500; không lưu giá trị |
| `POST /api/v1/privacy/deanonymize` | API-09-119, 122, 124 | Ba bước, ba người, MFA; trả tham chiếu hết hạn, không trả giá trị |
| `POST /api/v1/privacy/anonymize` | API-09-130 | Bất đồng bộ (ARX), k ≥ 10 thay vì k ≥ 5 |
| `POST /api/v1/privacy/risk-assess` | API-09-136 | Ba mô hình rủi ro |
| `POST /api/v1/privacy/prepare-training` | API-09-137 | Mục tiêu `AI_TRAINING`, `NON_PROD_TEST`, `OPEN_DATA` |
| `GET`, `PUT /api/admin/v1/privacy/classifications` | API-09-010, 015 | Khóa là `elementId` thay cho `entity/field`; đề xuất rồi xác nhận |
| `GET /api/admin/v1/privacy/unclassified` | API-09-010 (lọc `status`), 044 | Thêm trường DLCN chưa thuộc hoạt động xử lý |
| `GET /domains`, `POST /domains/{id}/rotate-key` | API-09-109, 116 | Miền theo mã; xoay cần quyền duyệt |
| `GET`, `POST /anon-configs`, `GET /datasets` | API-09-125, 126, 140 | Cấu hình có phiên bản, bốn mắt |
| `GET /deanonymize-log` | API-09-120, 215 | Nhật ký ở `audit-events` |
| `GET /compliance-report` | API-09-220, 221 | Lập theo kỳ, bất đồng bộ |

: Ánh xạ API cũ của SRS sang API-09

### 8.2. Hệ Viettel 2021 và CSDL quốc gia

Hệ cũ (Viettel 2021) không có phân hệ quyền riêng tư tương ứng nên không có API cũ cần ánh xạ. Không có API nào của PH-09 gọi hoặc được gọi bởi CSDL quốc gia.

## 9. Truy vết FR sang API

Bảng cho biết mỗi chức năng FR-09 được hiện thực bởi các operation nào (rút từ cột FR của FRS §9.4). Chức năng không có operation là chức năng chạy nền hoặc chỉ ở giao diện.

<!-- gen:fr:start -->
| FR | API | FR | API |
|---|---|---|---|
| FR-09-001 | 001, 002 | FR-09-033 | 119…124 |
| FR-09-002 | 007…009 | FR-09-034 | 115…118 |
| FR-09-003 | 010…014, 243 | FR-09-035 | 125…129 |
| FR-09-004 | 015…018 | FR-09-036 | 130…133 |
| FR-09-005 | 020…026 | FR-09-037 | 134…136 |
| FR-09-006 | 027…029 | FR-09-038 | 137…139 |
| FR-09-007 | 003…006, 231 | FR-09-039 | 140…144 |
| FR-09-008 | 010, 019, 030, 031 | FR-09-040 | 145…151 |
| FR-09-009 | 032…035 | FR-09-041 | 152…155 |
| FR-09-010 | 036…040 | FR-09-042 | 156…158 |
| FR-09-011 | 041…044 | FR-09-043 | 159…162 |
| FR-09-012 | 045…050 | FR-09-044 | 163 |
| FR-09-013 | 051…053 | FR-09-045 | 164…166, 244 |
| FR-09-014 | 054…057 | FR-09-046 | 167 |
| FR-09-015 | 058…063 | FR-09-047 | 168, 169, 235 |
| FR-09-016 | 064…066 | FR-09-048 | 170…173, 178 |
| FR-09-017 | 067…073 | FR-09-049 | 174, 242 |
| FR-09-018 | 074…078, 233 | FR-09-050 | 175…177 |
| FR-09-019 | 227 | FR-09-051 | 179…181 |
| FR-09-020 | 079…085, 237 | FR-09-052 | 182…187, 238 |
| FR-09-021 | 086, 087 | FR-09-053 | 188…191, 235, 245 |
| FR-09-022 | 088, 089 | FR-09-054 | 234 |
| FR-09-023 | 090, 091 | FR-09-055 | 192…195 |
| FR-09-024 | 092…095 | FR-09-056 | 196…199 |
| FR-09-025 | 101 | FR-09-057 | 200, 201 |
| FR-09-026 | 096…100 | FR-09-058 | 202…206 |
| FR-09-027 | 228, 232 | FR-09-059 | 207…210, 239 |
| FR-09-028 | 229, 231 | FR-09-060 | 211…214, 240 |
| FR-09-029 | 102, 103, 236, 241 | FR-09-061 | 215…217 |
| FR-09-030 | 104…108 | FR-09-062 | 218, 219 |
| FR-09-031 | 109…114 | FR-09-063 | 220…223 |
| FR-09-032 | 230 | FR-09-064 | 224…226 |

: Truy vết FR-09 sang API-09
<!-- gen:fr:end -->

## 10. Đồng bộ với FRS 0.2

Bản 0.1 gửi FRS hai nhóm đề nghị (enum, trường chỉ có ở API; sáu thay đổi nên có). FRS 0.2 đã nhận cả hai nhóm (Phụ lục C của FRS, các dòng "API 10.1" và "API 10.2"), nên chương này ghi nơi từng đề nghị được thực hiện trong hợp đồng và các việc còn lại.

### 10.1. Nơi các đề nghị đã được thực hiện

Mỗi dòng nối một đề nghị của bản 0.1 với quyết định của FRS và vị trí trong hợp đồng, để người đọc kiểm được đề nghị nào đã khép.

| Đề nghị của bản 0.1 | Kết quả ở FRS 0.2 | Thực hiện ở hợp đồng |
|---|---|---|
| Enum `LogPolicy`, `DisplayPolicy`, `TargetKind`, `MaskPolicyScope`, `ReportFormat`, trạng thái nhãn chặn, `trigger` của bundle | Phụ lục A thêm cùng `SchemaFormat`, `FindingResolution`, `DecideReason`, `UsageGroupBy`, `ConsentCheckStatus`, `BreachClockLevel`, `AuditOutcome` | `gen_openapi.py` đọc toàn bộ enum từ Phụ lục A, `check_contracts.py` so khớp |
| Bốn `GET` còn thiếu | API-09-238 đến 241 | Chương 3.4, 3.8 và 3.9; chi tiết mẫu đồng ý, danh sách thông báo, biện pháp khắc phục, phiếu xem đầy đủ không kèm giá trị |
| Ba mã lỗi 079 đến 081 | Có ở §9.1; thêm ERR-09-082 cho AI khi cờ tắt | Mục 6.3 |
| Hạn mức `09.api.rate-*` | Có ở §8.2 | Mục 1.3 |
| `Idempotency-Key` của data plane | BR-09-061 loại data plane | Mục 1 và OpenAPI |
| Cách trả giá trị của API-09-102 và 124 | FR-09-029 và 033 | Mục 13.4, 13.5 và ví dụ 12.1 |
| Đề nghị của UC, MH, SDD về `:extend`, `:retire`, `:withdraw`, tra đồng ý theo định danh | API-09-242 đến 245 | Chương 3.1, 3.7, 3.8 và OpenAPI |
| Loại yêu cầu `RENEWAL` | `AccessRequestKind`, `requestKind`, `renewsGrantId` | `AccessRequest`, `AccessRequestInput`, `EVT-09-05` |

: Nơi các đề nghị của bản 0.1 được thực hiện

### 10.2. Việc còn lại cho FRS

Ba việc dưới đây là chỗ FRS 0.2 còn ghi trạng thái cũ hoặc chưa khớp với hợp đồng; tập API không sửa FRS nên chuyển lại để người phụ trách FRS xử lý.

| Số | Đề nghị | Lý do |
|---|---|---|
| 1 | Sửa dòng D03-04-PH09 ở Phụ lục B và các ô "OpenAPI chưa có", "API đang ghi 15 phút" ở Phụ lục C thành đã thực hiện ở bản 0.2 của tập API | Hai chỗ này mô tả trạng thái trước khi tập API đồng bộ |
| 2 | Bỏ chữ "đề xuất của FRS 0.2, cần thêm vào DDL và OpenAPI" ở dòng `AccessRequestKind` của Phụ lục A | DDL và OpenAPI đã có cột và trường tương ứng |
| 3 | Câu thông báo ERR-09-107 chưa nêu giới hạn 1 MiB và 500 giá trị như Phụ lục C ghi (ĐN-TC-07) | §9.1 vẫn là "Bản tin hoặc lô vượt giới hạn cho phép."; hợp đồng đang dùng nguyên văn §9.1 |

: Việc còn lại cho FRS từ tập API

## 11. Câu hỏi mở

Năm câu hỏi của bản 0.1 đã có quyết định ở FRS 0.2; bảng ghi kết quả để người đọc không phải tra lại. Chưa có câu hỏi mới của tập API.

| Mã | Câu hỏi | Trạng thái |
|---|---|---|
| Q09-55 | Hạn mức gọi control plane và data plane | Đã chốt: khóa `09.api.rate-user-per-min` và `09.api.rate-du-per-sec` ở FRS §8.2 |
| Q09-56 | `POST` tra cứu của data plane có cần `Idempotency-Key` | Đã chốt: không cần (BR-09-061); API-09-245 là tra cứu ở control plane nên cũng miễn |
| Q09-57 | API-09-102 trả giá trị trong thân hay qua `GET` một lần | Đã chốt: trong thân `no-store`; chi tiết phiếu không kèm giá trị đọc bằng API-09-241 |
| Q09-58 | API-09-124 giao kết quả qua tham chiếu hay trong thân | Đã chốt: tham chiếu Garage SSE-C, tải một lần, hết hạn sau 60 giây (FR-09-033) |
| Q09-59 | Phân trang `page` từ 0 đủ cho `audit-events` và `usage-reports`; hợp đồng sự kiện tiêu thụ | Còn mở: offset tối đa 10.000 dòng rồi buộc thu hẹp khoảng thời gian, thêm con trỏ `after` nếu cần; hợp đồng sự kiện chốt cùng chủ các phân hệ phát |

: Câu hỏi mở của tập API PH-09

## 12. Ví dụ JSON

Các ví dụ dưới đây ứng với operation có tính an toàn hoặc đường nóng, mỗi ví dụ gồm yêu cầu và phản hồi thành công; chúng đã được kiểm khớp lược đồ OpenAPI. Mọi tên, mã, băm là giả lập; bí mật (token, tham chiếu) là `<bi-mat-mau>`.

<!-- gen:examples:start -->
### 12.1. Xin xem giá trị đầy đủ có lý do

Ví dụ cho API-09-102 (`POST /reveal-grants`), phản hồi `201`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /api/privacy/v1/reveal-grants
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "elementId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c",
  "recordRef": "bgh-2026-001203",
  "reason": "Đối chiếu hồ sơ khiếu nại số 3318 của công dân"
}
```

```http
HTTP/1.1 201

{
  "grantId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d",
  "token": "<bi-mat-mau>",
  "status": "ISSUED",
  "issuedAt": "2026-11-26T09:15:02+07:00",
  "expiresAt": "2026-11-26T09:16:02+07:00",
  "serverTime": "2026-11-26T09:15:02+07:00",
  "remainingThisHour": 17,
  "value": "<gia-tri-ro-mau>"
}
```

### 12.2. Đề nghị khôi phục giá trị gốc

Ví dụ cho API-09-119 (`POST /reidentification-requests`), phản hồi `201`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /api/privacy/v1/reidentification-requests
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "domainCode": "DS-TOKEN",
  "tokens": [
    "tok_01HZX3Q8",
    "tok_01HZX3Q9"
  ],
  "purposeCode": "THANH-TRA-HS",
  "basis": "Quyết định thanh tra số 54/QĐ-TTr",
  "reason": "Xác định chủ thể để xử lý khiếu nại đã được thụ lý"
}
```

```http
HTTP/1.1 201

{
  "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
  "version": 3,
  "createdAt": "2026-11-20T09:00:00+07:00",
  "createdBy": "nguyen.van.an",
  "updatedAt": "2026-11-26T09:15:02+07:00",
  "updatedBy": "tran.thi.binh",
  "domainId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c",
  "tokenCount": 2,
  "purposeCode": "THANH-TRA-HS",
  "basis": "Quyết định thanh tra số 54/QĐ-TTr",
  "reason": "Xác định chủ thể để xử lý khiếu nại đã được thụ lý",
  "status": "PENDING_L1",
  "requestedBy": "pham.thi.dung",
  "mfaVerified": true
}
```

### 12.3. Tiếp nhận yêu cầu của chủ thể

Ví dụ cho API-09-165 (`POST /subject-requests`), phản hồi `201`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /api/privacy/v1/subject-requests
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "requestType": "ACCESS",
  "channel": "COUNTER",
  "identifierType": "NATIONAL_ID",
  "identifier": "<so-dinh-danh-mau>",
  "content": "Đề nghị cho biết dữ liệu cá nhân đang được xử lý"
}
```

```http
HTTP/1.1 201

{
  "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
  "version": 3,
  "createdAt": "2026-11-20T09:00:00+07:00",
  "createdBy": "nguyen.van.an",
  "updatedAt": "2026-11-26T09:15:02+07:00",
  "updatedBy": "tran.thi.binh",
  "requestType": "ACCESS",
  "status": "RECEIVED",
  "channel": "COUNTER",
  "identifierType": "NATIONAL_ID",
  "receivedAt": "2026-11-26T09:15:02+07:00",
  "dueAt": "2026-12-10T17:00:00+07:00",
  "overdue": false,
  "restrictionActive": false,
  "subjectHash": "q3Hk7mXw2RtY9bLz0Pv5nCj8sUeAd1GfOiMhT4yVxKo"
}
```

### 12.4. Ghi nhận sự đồng ý

Ví dụ cho API-09-188 (`POST /consents`), phản hồi `201`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /api/privacy/v1/consents
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "templateCode": "DY-THONG-BAO-SMS",
  "templateVersion": 2,
  "subjectIdentifierType": "PHONE",
  "subjectIdentifier": "<so-dien-thoai-mau>",
  "channel": "APP",
  "evidence": {
    "sessionRef": "ss-77a1",
    "ipHash": "q3Hk7mXw2RtY9bLz0Pv5nCj8sUeAd1GfOiMhT4yVxKo"
  }
}
```

```http
HTTP/1.1 201

{
  "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
  "version": 3,
  "createdAt": "2026-11-20T09:00:00+07:00",
  "createdBy": "nguyen.van.an",
  "updatedAt": "2026-11-26T09:15:02+07:00",
  "updatedBy": "tran.thi.binh",
  "templateCode": "DY-THONG-BAO-SMS",
  "templateVersion": 2,
  "subjectHash": "q3Hk7mXw2RtY9bLz0Pv5nCj8sUeAd1GfOiMhT4yVxKo",
  "status": "GIVEN",
  "channel": "APP",
  "givenAt": "2026-11-26T09:15:02+07:00",
  "recordedBy": "dich-vu-cong"
}
```

### 12.5. Ghi nhận vi phạm dữ liệu cá nhân

Ví dụ cho API-09-203 (`POST /breaches`), phản hồi `201`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /api/privacy/v1/breaches
Idempotency-Key: 6b1f0a52-3c7e-4d9a-8f21-5e0b9c1d7a44

{
  "detectedAt": "2026-11-26T08:40:00+07:00",
  "source": "INCIDENT_PH18",
  "description": "Tệp xuất danh sách hồ sơ bị gửi nhầm tới địa chỉ ngoài tổ chức",
  "dataTypes": [
    "FULL_NAME",
    "PHONE"
  ],
  "estimatedSubjects": 120,
  "incidentRef": "INC-2026-0481"
}
```

```http
HTTP/1.1 201

{
  "id": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b",
  "version": 3,
  "createdAt": "2026-11-20T09:00:00+07:00",
  "createdBy": "nguyen.van.an",
  "updatedAt": "2026-11-26T09:15:02+07:00",
  "updatedBy": "tran.thi.binh",
  "detectedAt": "2026-11-26T08:40:00+07:00",
  "deadlineAt": "2026-11-29T08:40:00+07:00",
  "source": "INCIDENT_PH18",
  "description": "Tệp xuất danh sách hồ sơ bị gửi nhầm tới địa chỉ ngoài tổ chức",
  "dataTypes": [
    "FULL_NAME",
    "PHONE"
  ],
  "estimatedSubjects": 120,
  "incidentRef": "INC-2026-0481",
  "status": "REPORTED",
  "reportedBy": "tran.thi.binh"
}
```

### 12.6. Quyết định mục đích trực tuyến

Ví dụ cho API-09-227 (`POST /privacy/v1/purpose:decide`), phản hồi `200`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /privacy/v1/purpose:decide
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "htttId": "httt-so-yte",
  "purposeCode": "TRA-CUU-BHYT",
  "contractKind": "API",
  "contractId": "api-tra-cuu-bhyt-v1",
  "fields": [
    "hoTen",
    "soThe"
  ],
  "channel": "API"
}
```

```http
HTTP/1.1 200

{
  "allow": true,
  "reason": "GRANTED",
  "grantId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a4d",
  "ropaActivityId": "0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c",
  "allowedFields": [
    "hoTen",
    "soThe"
  ],
  "conditions": [
    {
      "conditionType": "DAILY_QUOTA",
      "params": {
        "max": 2000
      }
    }
  ],
  "bundleNo": 412,
  "ttlSeconds": 60
}
```

### 12.7. Lấy kế hoạch che

Ví dụ cho API-09-228 (`POST /privacy/v1/mask-plans:resolve`), phản hồi `200`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /privacy/v1/mask-plans:resolve
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "contractKind": "API",
  "contractId": "api-tra-cuu-bhyt-v1",
  "purposeCode": "TRA-CUU-BHYT",
  "channel": "API",
  "roles": [
    "ROLE-SERVICE_OWNER"
  ],
  "fields": [
    "hoTen",
    "soCCCD"
  ]
}
```

```http
HTTP/1.1 200

{
  "planId": "plan-9c41",
  "bundleNo": 412,
  "failMode": "CLOSED",
  "ttlSeconds": 300,
  "rules": [
    {
      "field": "hoTen",
      "dataClass": "RESTRICTED",
      "maskType": "PARTIAL",
      "patternKind": "KEEP_FIRST_TOKEN"
    },
    {
      "field": "soCCCD",
      "dataClass": "SENSITIVE",
      "maskType": "TOKENIZE",
      "params": {
        "domainCode": "DS-TOKEN"
      }
    }
  ]
}
```

### 12.8. Áp che bản tin

Ví dụ cho API-09-229 (`POST /privacy/v1/messages:apply`), phản hồi `200`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /privacy/v1/messages:apply
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "contractKind": "TOPIC",
  "contractId": "chu-de-ho-so-moi",
  "purposeCode": "DONG-BO-HS",
  "channel": "FLOW",
  "message": {
    "hoTen": "Nguyễn Văn A",
    "soCCCD": "<so-dinh-danh-mau>",
    "maHoSo": "HS-0042"
  }
}
```

```http
HTTP/1.1 200

{
  "message": {
    "hoTen": "Nguyễn ***",
    "soCCCD": "tok_01HZX3Q8",
    "maHoSo": "HS-0042"
  },
  "appliedFields": [
    "hoTen",
    "soCCCD"
  ],
  "droppedFields": [],
  "pseudonymized": 1,
  "bundleNo": 412
}
```

### 12.9. Giả danh hóa lô giá trị

Ví dụ cho API-09-230 (`POST /privacy/v1/pseudonyms:issue`), phản hồi `200`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /privacy/v1/pseudonyms:issue
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "domainCode": "DS-TOKEN",
  "identifierKind": "NATIONAL_ID",
  "values": [
    "<so-dinh-danh-mau>"
  ]
}
```

```http
HTTP/1.1 200

{
  "domainCode": "DS-TOKEN",
  "keyVersion": 2,
  "method": "TOKEN_TRANSIT",
  "items": [
    {
      "index": 0,
      "pseudonym": "tok_01HZX3Q8"
    }
  ]
}
```

### 12.10. Tính băm HMAC của định danh chủ thể

Ví dụ cho API-09-235 (`POST /privacy/v1/subject-hashes:compute`), phản hồi `200`; dữ liệu giả lập, bí mật và giá trị riêng là chỗ giữ `<bi-mat-mau>`, `<gia-tri-ro-mau>`, `<so-dinh-danh-mau>`.

```http
POST /privacy/v1/subject-hashes:compute
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

{
  "identifierType": "NATIONAL_ID",
  "identifiers": [
    "<so-dinh-danh-mau>"
  ]
}
```

```http
HTTP/1.1 200

{
  "keyRef": "dh-t68-privacy-hmac:v3",
  "items": [
    {
      "index": 0,
      "subjectHash": "q3Hk7mXw2RtY9bLz0Pv5nCj8sUeAd1GfOiMhT4yVxKo"
    }
  ]
}
```
<!-- gen:examples:end -->

## 13. Đặc tả endpoint trọng yếu

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py` cho 35 operation trọng yếu (an toàn, bốn mắt, đường nóng, đặc quyền); 202 operation còn lại theo quy tắc chung của chương 1, 2, 6 và bảng chương 3. Sửa nguồn (`ph09/tools/gen_openapi.py`, `schemas09.py`) rồi chạy `gen_md.py`, không sửa tay. Mỗi endpoint một bảng 10 mục (mục đích, phương thức và đường dẫn, quyền, FR, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú); đường dẫn của control plane tính từ `/api/privacy/v1`, của data plane viết đầy đủ.

<!-- gen:dac-ta:start -->
### 13.1. Phân loại

Mức phân loại, nhãn chặn, loại DLCN, phần tử dữ liệu, phân loại và quét phát hiện, mức hợp đồng (FR-09-001…008). Các operation sau có đặc tả đầy đủ.

#### API-09-012 · Đăng ký phần tử (hàng loạt)

::: dac-ta
**Mục đích.** Đăng ký phần tử (hàng loạt).

**Phương thức, đường dẫn.** `POST /data-elements:register`.

**Quyền.** classify; scope privacy:register.

**FR hiện thực.** FR-09-003.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ElementRegisterInput`; trường bắt buộc: `items`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `BulkResult`; trường bắt buộc: `created`, `updated`, `skipped`, `errors`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-006, ERR-09-010, ERR-09-014, ERR-09-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đăng ký hàng loạt tối đa 1.000 phần tử mỗi lời gọi; phần tử đã có trả về `skipped`, không lỗi. Phần tử mới ở trạng thái `PROPOSED`, xử lý như `SENSITIVE` đến khi xác nhận (BR-09-001).
:::

#### API-09-016 · Xác nhận phân loại

::: dac-ta
**Mục đích.** Xác nhận phân loại.

**Phương thức, đường dẫn.** `POST /classifications/{classificationId}:confirm`.

**Quyền.** classify.

**FR hiện thực.** FR-09-004.

**Tham số.** `classificationId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ClassificationConfirmInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ClassificationChange`; trường bắt buộc: `version`, `id`, `elementId`, `toClass`, `toPersonalDataType`, `status`, `proposedBy`, `source`, `downgrade`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-012, ERR-09-013 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người xác nhận khác người đề xuất (ERR-09-005). Hạ mức hoặc hạ loại DLCN cần căn cứ và lý do (ERR-09-013) và người xác nhận thứ hai (BR-09-002, 003); phát EVT-09-01.
:::

### 13.2. Sổ hoạt động xử lý

Hoạt động xử lý, liên kết, cơ sở pháp lý, văn bản căn cứ, xuất sổ (FR-09-009…013). Các operation sau có đặc tả đầy đủ.

#### API-09-037 · Duyệt, kích hoạt

::: dac-ta
**Mục đích.** Duyệt, kích hoạt.

**Phương thức, đường dẫn.** `POST /processing-activities/{activityId}:approve`.

**Quyền.** ropa.

**FR hiện thực.** FR-09-010.

**Tham số.** `activityId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ProcessingActivity`; trường bắt buộc: `version`, `id`, `code`, `versionNo`, `status`, `purposeText`, `legalBasisCode`, `legalDocIds`, `categories`, `subjectGroups`, `controllerRole`, `retention`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-020, ERR-09-021, ERR-09-023, ERR-09-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người soạn (ERR-09-005). Hoạt động phải đủ mục, văn bản căn cứ còn hiệu lực, không dùng sự đồng ý khi luật bắt buộc; bản cũ chuyển `SUPERSEDED`; phát EVT-09-04.
:::

### 13.3. Mục đích và chấp thuận

Mục đích, yêu cầu khai thác, chấp thuận, bundle chính sách, cảnh báo khai thác, kiểm tra kích hoạt (FR-09-014…022). Các operation sau có đặc tả đầy đủ.

#### API-09-065 · Chấp thuận, chấp thuận có điều kiện, từ chối

::: dac-ta
**Mục đích.** Chấp thuận, chấp thuận có điều kiện, từ chối.

**Phương thức, đường dẫn.** `POST /access-requests/{requestId}:decide`.

**Quyền.** purpose-approve.

**FR hiện thực.** FR-09-016.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AccessDecisionInput`; trường bắt buộc: `decision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AccessRequest`; trường bắt buộc: `version`, `id`, `htttId`, `ownerOrgId`, `purposeCode`, `contractKind`, `contractId`, `fields`, `requestedDays`, `justification`, `status`, `requestKind`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-028, ERR-09-029, ERR-09-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chủ quản dữ liệu quyết định; `APPROVE` hoặc `APPROVE_WITH_CONDITIONS` sinh chấp thuận, tối đa `09.grant.max-days` ngày (ERR-09-030); người lập yêu cầu không tự duyệt (BR-09-014); dựng lại bundle trong 10 giây; phát EVT-09-06.
:::

#### API-09-073 · Thu hồi

::: dac-ta
**Mục đích.** Thu hồi.

**Phương thức, đường dẫn.** `POST /purpose-grants/{grantId}:revoke`.

**Quyền.** purpose-approve.

**FR hiện thực.** FR-09-017.

**Tham số.** `grantId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PurposeGrant`; trường bắt buộc: `version`, `id`, `htttId`, `purposeCode`, `contractKind`, `contractId`, `fields`, `validFrom`, `validUntil`, `status`, `renewCount`, `conditions`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-007, ERR-09-010, ERR-09-030, ERR-09-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hiệu lực trong ≤ 15 giây tại điểm thực thi; lý do tối thiểu 20 ký tự (ERR-09-007); phát EVT-09-08.
:::

#### API-09-076 · Dựng và phát hành bundle thủ công

::: dac-ta
**Mục đích.** Dựng và phát hành bundle thủ công.

**Phương thức, đường dẫn.** `POST /policy-bundles:publish`.

**Quyền.** policy-approve.

**FR hiện thực.** FR-09-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BundlePublishInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PolicyBundle`; trường bắt buộc: `version`, `id`, `bundleNo`, `objectRef`, `sizeBytes`, `sha256`, `testPassed`, `validUntil`, `signingKeyRef`, `trigger`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-006, ERR-09-010, ERR-09-032, ERR-09-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ phát hành khi bộ kiểm thử đạt (ERR-09-033) và ký được bằng OpenBao (ERR-09-032, bundle cũ vẫn hiệu lực); `validUntil` ≤ 240 phút, kích thước ≤ 5 MB; phát EVT-09-11.
:::

### 13.4. Che dữ liệu

Kiểu che, chính sách che, mô phỏng, xem đầy đủ, che log, rò rỉ log (FR-09-023…030). Các operation sau có đặc tả đầy đủ.

#### API-09-097 · Duyệt, kích hoạt

::: dac-ta
**Mục đích.** Duyệt, kích hoạt.

**Phương thức, đường dẫn.** `POST /mask-policies/{policyId}/versions/{version}:approve`.

**Quyền.** policy-approve.

**FR hiện thực.** FR-09-026.

**Tham số.** `policyId` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MaskPolicy`; trường bắt buộc: `version`, `id`, `code`, `versionNo`, `status`, `scope`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người soạn; chỉ duyệt phiên bản đã mô phỏng đạt (ERR-09-040); phiên bản trước chuyển `SUPERSEDED`; phát EVT-09-12.
:::

#### API-09-102 · Xin xem giá trị đầy đủ có lý do

::: dac-ta
**Mục đích.** Xin xem giá trị đầy đủ có lý do.

**Phương thức, đường dẫn.** `POST /reveal-grants`.

**Quyền.** unmask.

**FR hiện thực.** FR-09-029.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevealRequestInput`; trường bắt buộc: `elementId`, `recordRef`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RevealGrantIssued`; trường bắt buộc: `grantId`, `token`, `status`, `issuedAt`, `expiresAt`, `serverTime`, `remainingThisHour`, `value`; tiêu đề `Location`, `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-010, ERR-09-041, ERR-09-042, ERR-09-043 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiếu hết hạn sau `09.mask.reveal-seconds` (60) giây, không gia hạn; tối đa 20 phiếu mỗi người mỗi giờ (ERR-09-043); trường `neverReveal` bị từ chối (ERR-09-042); thân trả thêm `serverTime` và `remainingThisHour`, giao diện đếm ngược theo `expiresAt` của máy chủ; giá trị chỉ có trong thân phản hồi `no-store`, không ghi đĩa; ghi kiểm toán không giá trị (BR-09-026).
:::

### 13.5. Giả danh và ẩn danh

Miền và khóa giả danh, khôi phục giá trị gốc, cấu hình và job ẩn danh, rủi ro, chuẩn bị dữ liệu, tập đã ẩn danh (FR-09-031…039). Các operation sau có đặc tả đầy đủ.

#### API-09-118 · Hủy khóa (hai người)

::: dac-ta
**Mục đích.** Hủy khóa (hai người).

**Phương thức, đường dẫn.** `POST /pseudonym-keys/{keyId}:destroy`.

**Quyền.** policy-approve.

**FR hiện thực.** FR-09-034.

**Tham số.** `keyId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `KeyDestroyInput`; trường bắt buộc: `reason`, `confirmation`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `PseudonymKey`; trường bắt buộc: `version`, `id`, `domainId`, `keyVersion`, `status`, `openbaoRef`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-046, ERR-09-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần hai người khác nhau xác nhận và chờ tối thiểu 7 ngày (BR-09-032); khóa còn dùng thì từ chối (ERR-09-046); phát EVT-09-16; khóa bị hủy làm bí danh của miền không còn giải được.
:::

#### API-09-119 · Đề nghị khôi phục giá trị gốc

::: dac-ta
**Mục đích.** Đề nghị khôi phục giá trị gốc.

**Phương thức, đường dẫn.** `POST /reidentification-requests`.

**Quyền.** reidentify.

**FR hiện thực.** FR-09-033.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReidRequestInput`; trường bắt buộc: `domainCode`, `tokens`, `purposeCode`, `basis`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ReidentificationRequest`; trường bắt buộc: `version`, `id`, `domainId`, `tokenCount`, `purposeCode`, `basis`, `reason`, `status`, `requestedBy`, `mfaVerified`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-005, ERR-09-010, ERR-09-048, ERR-09-049, ERR-09-050 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tối đa 100 giá trị mỗi đề nghị (ERR-09-049); miền HMAC không khôi phục được (ERR-09-048); danh sách token chỉ lưu dạng băm tổng hợp `tokens_digest`.
:::

#### API-09-122 · Duyệt cấp một, cấp hai

::: dac-ta
**Mục đích.** Duyệt cấp một, cấp hai.

**Phương thức, đường dẫn.** `POST /reidentification-requests/{requestId}:approve`.

**Quyền.** purpose-approve / policy-approve.

**FR hiện thực.** FR-09-033.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReidApproveInput`; trường bắt buộc: `level`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReidentificationRequest`; trường bắt buộc: `version`, `id`, `domainId`, `tokenCount`, `purposeCode`, `basis`, `reason`, `status`, `requestedBy`, `mfaVerified`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-048, ERR-09-049, ERR-09-050 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cấp một do chủ quản, cấp hai do ATTT; ba người khác nhau (người đề nghị, cấp một, cấp hai); duyệt hết hiệu lực sau 24 giờ (ERR-09-050); đồng thời phải có MFA khi thực hiện.
:::

#### API-09-124 · Thực hiện khôi phục (yêu cầu MFA)

::: dac-ta
**Mục đích.** Thực hiện khôi phục (yêu cầu MFA).

**Phương thức, đường dẫn.** `POST /reidentification-requests/{requestId}:execute`.

**Quyền.** reidentify.

**FR hiện thực.** FR-09-033.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReidExecuteInput`; trường bắt buộc: `mfaAssertion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReidExecuteResult`; trường bắt buộc: `requestId`, `status`, `tokenCount`, `resultRef`, `expiresAt`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-048, ERR-09-049, ERR-09-050 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Yêu cầu MFA mới trong 5 phút và cửa sổ thực hiện 30 phút; kết quả giao qua `resultRef` (Garage, mã hóa SSE-C, tải một lần) hết hạn theo `expiresAt` của máy chủ sau 60 giây, không trả giá trị gốc trong thân; phát EVT-09-17.
:::

#### API-09-129 · Duyệt cấu hình (bốn mắt)

::: dac-ta
**Mục đích.** Duyệt cấu hình (bốn mắt).

**Phương thức, đường dẫn.** `POST /anonymization-configs/{configId}:approve`.

**Quyền.** policy-approve.

**FR hiện thực.** FR-09-035.

**Tham số.** `configId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AnonymizationConfig`; trường bắt buộc: `version`, `id`, `configCode`, `versionNo`, `status`, `privacyModel`, `k`, `rules`, `purposeCode`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-051 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bốn mắt; `k` phải ≥ `09.anon.k-min` (10, ERR-09-051); phiên bản `ACTIVE` bất biến.
:::

#### API-09-130 · Chạy ẩn danh hóa tập dữ liệu

::: dac-ta
**Mục đích.** Chạy ẩn danh hóa tập dữ liệu.

**Phương thức, đường dẫn.** `POST /anonymization-jobs`.

**Quyền.** anonymize.

**FR hiện thực.** FR-09-036.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AnonymizationJobInput`; trường bắt buộc: `configId`, `sourceRef`, `target`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `AnonymizationJob`; trường bắt buộc: `version`, `id`, `configId`, `sourceRef`, `status`, `target`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-010, ERR-09-052, ERR-09-054 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Job chạy bất đồng bộ (ARX); hoàn tất khi k thực tế ≥ k cấu hình; còn trường định danh trực tiếp thì từ chối (ERR-09-052); rủi ro `HIGH` không phát hành (ERR-09-053).
:::

#### API-09-143 · Rút lại tập

::: dac-ta
**Mục đích.** Rút lại tập.

**Phương thức, đường dẫn.** `POST /anonymized-datasets/{datasetId}:withdraw`.

**Quyền.** anonymize.

**FR hiện thực.** FR-09-039.

**Tham số.** `datasetId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonInput`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `AnonymizedDataset`; trường bắt buộc: `version`, `id`, `jobId`, `status`, `objectRef`, `rowCount`, `actualK`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-007, ERR-09-010, ERR-09-053, ERR-09-056 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Rút lại tập đã phát hành, lý do tối thiểu 20 ký tự; phát EVT-09-18.
:::

### 13.6. Lưu giữ

Lịch lưu giữ, tác vụ xóa, giữ pháp lý, xóa mật mã tenant, báo cáo lưu giữ (FR-09-040…044). Các operation sau có đặc tả đầy đủ.

#### API-09-161 · Duyệt xóa mật mã (hai người)

::: dac-ta
**Mục đích.** Duyệt xóa mật mã (hai người).

**Phương thức, đường dẫn.** `POST /tenant-shred-requests/{requestId}:approve`.

**Quyền.** policy-approve.

**FR hiện thực.** FR-09-043.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantShredRequest`; trường bắt buộc: `version`, `id`, `status`, `exportConfirmed`, `reason`, `requestedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-005, ERR-09-006, ERR-09-010, ERR-09-060 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hai người duyệt khác nhau và khác người đề nghị; chờ `09.shred.delay-days` (30, tối thiểu 7) ngày trước khi hủy khóa KEK của tenant (BR-09-041); phát EVT-09-21 khi hoàn tất.
:::

### 13.7. Quyền chủ thể

Yêu cầu của chủ thể dữ liệu từ tiếp nhận đến đóng, báo cáo (FR-09-045…051). Các operation sau có đặc tả đầy đủ.

#### API-09-165 · Tiếp nhận yêu cầu

::: dac-ta
**Mục đích.** Tiếp nhận yêu cầu.

**Phương thức, đường dẫn.** `POST /subject-requests`.

**Quyền.** dsr; scope privacy:register.

**FR hiện thực.** FR-09-045.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubjectRequestInput`; trường bắt buộc: `requestType`, `channel`, `identifierType`, `identifier`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SubjectRequest`; trường bắt buộc: `version`, `id`, `requestType`, `status`, `channel`, `identifierType`, `receivedAt`, `dueAt`, `overdue`, `restrictionActive`, `subjectHash`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-010, ERR-09-062, ERR-09-064, ERR-09-065 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Định danh chủ thể nhận một lần, mã hóa envelope ngay khi nhận, trả về chỉ có `subjectHash`; cùng `Idempotency-Key` trả lại phản hồi cũ; chủ thể đã có yêu cầu cùng loại đang xử lý thì ERR-09-064; phát EVT-09-22.
:::

#### API-09-167 · Ghi kết quả xác minh danh tính

::: dac-ta
**Mục đích.** Ghi kết quả xác minh danh tính.

**Phương thức, đường dẫn.** `POST /subject-requests/{requestId}:verify`.

**Quyền.** dsr.

**FR hiện thực.** FR-09-046.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubjectVerifyInput`; trường bắt buộc: `method`, `result`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SubjectRequest`; trường bắt buộc: `version`, `id`, `requestType`, `status`, `channel`, `identifierType`, `receivedAt`, `dueAt`, `overdue`, `restrictionActive`, `subjectHash`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-010, ERR-09-063 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chưa xác minh thì mọi thao tác xử lý bị từ chối (ERR-09-063, BR-09-042).
:::

#### API-09-242 · Gia hạn hạn trả lời kèm lý do

::: dac-ta
**Mục đích.** Gia hạn hạn trả lời kèm lý do.

**Phương thức, đường dẫn.** `POST /subject-requests/{requestId}:extend`.

**Quyền.** dsr.

**FR hiện thực.** FR-09-049.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExtendInput`; trường bắt buộc: `newDueAt`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SubjectRequest`; trường bắt buộc: `version`, `id`, `requestType`, `status`, `channel`, `identifierType`, `receivedAt`, `dueAt`, `overdue`, `restrictionActive`, `subjectHash`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-010 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gia hạn một lần, kèm lý do tối thiểu 20 ký tự; `newDueAt` không quá hạn pháp luật cho phép; thông báo chủ thể về hạn mới (FR-09-049).
:::

### 13.8. Sự đồng ý

Mẫu đồng ý, bản ghi đồng ý, bằng chứng (FR-09-052…054). Các operation sau có đặc tả đầy đủ.

#### API-09-188 · Ghi nhận đồng ý

::: dac-ta
**Mục đích.** Ghi nhận đồng ý.

**Phương thức, đường dẫn.** `POST /consents`.

**Quyền.** consent; scope privacy:consent.

**FR hiện thực.** FR-09-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConsentInput`; trường bắt buộc: `templateCode`, `templateVersion`, `subjectIdentifierType`, `subjectIdentifier`, `channel`, `evidence`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ConsentRecord`; trường bắt buộc: `version`, `id`, `templateCode`, `templateVersion`, `subjectHash`, `status`, `channel`, `givenAt`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-010, ERR-09-071, ERR-09-072 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bản ghi cần kênh, thời điểm, phiên bản mẫu (ERR-09-071); mẫu phải đang `ACTIVE`; một đồng ý `GIVEN` duy nhất cho mỗi (chủ thể, mẫu); phát EVT-09-27.
:::

#### API-09-189 · Rút đồng ý

::: dac-ta
**Mục đích.** Rút đồng ý.

**Phương thức, đường dẫn.** `POST /consents/{consentId}:withdraw`.

**Quyền.** consent; scope privacy:consent.

**FR hiện thực.** FR-09-053.

**Tham số.** `consentId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConsentWithdrawInput`; trường bắt buộc: `channel`, `evidence`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ConsentRecord`; trường bắt buộc: `version`, `id`, `templateCode`, `templateVersion`, `subjectHash`, `status`, `channel`, `givenAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-010, ERR-09-071, ERR-09-072 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đã rút hoặc hết hạn thì ERR-09-072; hiệu lực xử lý trong ≤ 60 giây (bộ đệm đồng ý); phát EVT-09-28.
:::

#### API-09-245 · Tra đồng ý theo định danh trong thân, trả danh sách theo băm

::: dac-ta
**Mục đích.** Tra đồng ý theo định danh trong thân, trả danh sách theo băm.

**Phương thức, đường dẫn.** `POST /consents:search`.

**Quyền.** consent.

**FR hiện thực.** FR-09-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ConsentSearchInput`; trường bắt buộc: `identifierType`, `identifier`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsentRecordPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-006, ERR-09-010, ERR-09-071, ERR-09-072 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tra theo định danh rõ trong thân (bên có quyền nhập): PH-09 tính băm HMAC rồi tra, không ghi định danh vào log, kết quả chỉ mang `subjectHash` (FR-09-053).
:::

### 13.9. DPIA và vi phạm

Hồ sơ đánh giá tác động, vụ việc vi phạm dữ liệu cá nhân, đồng hồ 72 giờ (FR-09-055…060). Các operation sau có đặc tả đầy đủ.

#### API-09-203 · Ghi nhận vi phạm (người dùng hoặc PH-18)

::: dac-ta
**Mục đích.** Ghi nhận vi phạm (người dùng hoặc PH-18).

**Phương thức, đường dẫn.** `POST /breaches`.

**Quyền.** breach; scope privacy:register.

**FR hiện thực.** FR-09-058.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BreachInput`; trường bắt buộc: `detectedAt`, `source`, `description`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `BreachCase`; trường bắt buộc: `version`, `id`, `detectedAt`, `deadlineAt`, `source`, `description`, `dataTypes`, `status`, `reportedBy`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-010, ERR-09-075 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `detectedAt` bắt đầu đồng hồ 72 giờ (`deadlineAt = detectedAt + 72 giờ`, không sửa được); phát EVT-09-30; TO được ghi nhận nhưng không đóng hồ sơ (BR-09-057).
:::

#### API-09-209 · Ghi nhận đã gửi

::: dac-ta
**Mục đích.** Ghi nhận đã gửi.

**Phương thức, đường dẫn.** `POST /breaches/{breachId}/notifications/{notificationId}:mark-sent`.

**Quyền.** breach.

**FR hiện thực.** FR-09-059.

**Tham số.** `breachId` (path, string, bắt buộc); `notificationId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NotificationSentInput`; trường bắt buộc: `sentAt`, `evidenceRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `BreachNotification`; trường bắt buộc: `version`, `id`, `breachId`, `recipient`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-010, ERR-09-076, ERR-09-077 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đã gửi thì không sửa; có `evidenceRef`; thông báo Cục A05 làm `notifiedA05At` của vụ việc; phát EVT-09-32.
:::

#### API-09-213 · Đóng hồ sơ

::: dac-ta
**Mục đích.** Đóng hồ sơ.

**Phương thức, đường dẫn.** `POST /breaches/{breachId}:close`.

**Quyền.** breach.

**FR hiện thực.** FR-09-060.

**Tham số.** `breachId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BreachCloseInput`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `BreachCase`; trường bắt buộc: `version`, `id`, `detectedAt`, `deadlineAt`, `source`, `description`, `dataTypes`, `status`, `reportedBy`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-001, ERR-09-003, ERR-09-004, ERR-09-006, ERR-09-010, ERR-09-076 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ đóng khi hết nghĩa vụ thông báo hoặc có căn cứ miễn trừ (ERR-09-076, 077) và đã ghi bài học.
:::

### 13.10. Kiểm toán và tham số

Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo tuân thủ, tham số tenant (FR-09-061…064). Các operation sau có đặc tả đầy đủ.

#### API-09-225 · Sửa tham số

::: dac-ta
**Mục đích.** Sửa tham số.

**Phương thức, đường dẫn.** `PUT /settings`.

**Quyền.** config.

**FR hiện thực.** FR-09-064.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsUpdate`; trường bắt buộc: `changes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `428`, `429`, `503`; mã lỗi của thao tác: ERR-09-003, ERR-09-004, ERR-09-010, ERR-09-078 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị ngoài sàn, trần PA đặt ra thì ERR-09-078; đổi `09.plan.cache-seconds`, `09.bundle.valid-minutes` có hiệu lực sau lần dựng bundle kế tiếp; ghi lịch sử.
:::

### 13.11. Data plane

API quyết định và áp che cho điểm thực thi, đường nóng, chỉ trong cụm (FR-09-007, 018, 019, 020, 027…029, 032, 047, 054). Các operation sau có đặc tả đầy đủ.

#### API-09-227 · Quyết định mục đích trực tuyến

::: dac-ta
**Mục đích.** Quyết định mục đích trực tuyến.

**Phương thức, đường dẫn.** `POST /privacy/v1/purpose:decide`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-019.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `PurposeDecideRequest`; trường bắt buộc: `htttId`, `purposeCode`, `contractKind`, `contractId`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PurposeDecideResponse`; trường bắt buộc: `allow`, `reason`, `bundleNo`, `ttlSeconds`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-09-101, ERR-09-102, ERR-09-103, ERR-09-104, ERR-09-106, ERR-09-111, ERR-09-113 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đường nóng: p95 ≤ 50 ms khi gọi trực tiếp; thiếu mục đích thì ERR-09-103; không có chấp thuận thì ERR-09-102; chủ thể bị hạn chế xử lý thì ERR-09-104; không khả dụng thì điểm thực thi đóng an toàn. Trả thêm `ropaActivityId` (hoạt động xử lý `ACTIVE` liên kết hợp đồng, vắng nếu chưa có) cho PH-14; trả `ropaActivityId` vẫn p95 ≤ 200 ms (NFR-09-027, chủ đầu tư chốt 27/11/2026).
:::

#### API-09-228 · Kế hoạch che theo chủ thể, mục đích, kênh

::: dac-ta
**Mục đích.** Kế hoạch che theo chủ thể, mục đích, kênh.

**Phương thức, đường dẫn.** `POST /privacy/v1/mask-plans:resolve`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-027.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `MaskPlanRequest`; trường bắt buộc: `contractKind`, `contractId`, `purposeCode`, `channel`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MaskPlanResponse`; trường bắt buộc: `planId`, `bundleNo`, `failMode`, `rules`, `ttlSeconds`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `503`; mã lỗi của thao tác: ERR-09-101, ERR-09-103, ERR-09-105, ERR-09-106, ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kế hoạch che theo trường cho (hợp đồng, mục đích, kênh); bộ đệm `09.plan.cache-seconds`; không lập được thì `failMode` `CLOSED` hoặc `PUBLIC_ONLY` (ERR-09-105).
:::

#### API-09-229 · Áp che bản tin cho luồng

::: dac-ta
**Mục đích.** Áp che bản tin cho luồng.

**Phương thức, đường dẫn.** `POST /privacy/v1/messages:apply`.

**Quyền.** scope privacy:apply.

**FR hiện thực.** FR-09-028.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `MessageApplyRequest`; trường bắt buộc: `contractKind`, `contractId`, `purposeCode`, `channel`, `message`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MessageApplyResponse`; trường bắt buộc: `message`, `appliedFields`, `droppedFields`, `pseudonymized`, `bundleNo`.

**Lỗi.** HTTP `400`, `401`, `403`, `413`, `429`, `503`; mã lỗi của thao tác: ERR-09-101, ERR-09-105, ERR-09-106, ERR-09-107, ERR-09-110, ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp kế hoạch che cho bản tin JSON ≤ 1 MiB; lô lớn hơn thì ERR-09-107; không ghi được nhật ký che thì từ chối (ERR-09-110); không lưu bản tin.
:::

#### API-09-230 · Giả danh hóa lô giá trị

::: dac-ta
**Mục đích.** Giả danh hóa lô giá trị.

**Phương thức, đường dẫn.** `POST /privacy/v1/pseudonyms:issue`.

**Quyền.** scope privacy:pseudonymize.

**FR hiện thực.** FR-09-032.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `PseudonymIssueRequest`; trường bắt buộc: `domainCode`, `identifierKind`, `values`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PseudonymIssueResponse`; trường bắt buộc: `domainCode`, `keyVersion`, `method`, `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `413`, `422`, `429`, `503`; mã lỗi của thao tác: ERR-09-106, ERR-09-107, ERR-09-108, ERR-09-109, ERR-09-110, ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giả danh hóa theo lô ≤ 500 giá trị; `HMAC_SHA256` tính cục bộ, `TOKEN_TRANSIT` dùng OpenBao (ERR-09-108 khi không khả dụng); không lưu giá trị vào, không lưu ánh xạ.
:::

#### API-09-231 · Kiểm tra nhãn chặn và phân loại bản tin, lược đồ

::: dac-ta
**Mục đích.** Kiểm tra nhãn chặn và phân loại bản tin, lược đồ.

**Phương thức, đường dẫn.** `POST /privacy/v1/classification:check`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-007, FR-09-028.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ClassificationCheckRequest`; trường bắt buộc: `contractKind`, `contractId`, `fields`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClassificationCheckResponse`; trường bắt buộc: `blocked`, `effectiveClass`, `egressBlocked`, `fields`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-09-101, ERR-09-106, ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm tra nhãn STATE_SECRET và mức phân loại hiệu lực của bản tin hoặc lược đồ; nhãn chặn trả `blocked` và ERR-09-101 ở điểm thực thi. Với `egressScope` là `OUT_OF_PROVINCE`, thêm kiểm thuộc tính `noEgress` của từng trường: trả `egressBlocked` và `egressBlockedFields`, bên gọi (PH-14) không gửi ra ngoài tỉnh; p95 ≤ 200 ms (BR-09-063, NFR-09-027, chủ đầu tư chốt 27/11/2026). `egressScope` ngoài `NONE`, `OUT_OF_PROVINCE` trả ERR-09-106 (400).
:::

#### API-09-232 · Bản chụp chỉ mục phân loại (ETag)

::: dac-ta
**Mục đích.** Bản chụp chỉ mục phân loại (ETag).

**Phương thức, đường dẫn.** `GET /privacy/v1/classification-index`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-027.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClassificationIndex`; trường bắt buộc: `bundleNo`, `generatedAt`, `entries`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bản chụp chỉ mục phân loại; hỗ trợ `If-None-Match` và `304`.
:::

#### API-09-233 · Bundle OPA hiện hành (ETag)

::: dac-ta
**Mục đích.** Bundle OPA hiện hành (ETag).

**Phương thức, đường dẫn.** `GET /privacy/v1/bundles/current`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-018.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bundle OPA đã ký hiện hành; `ETag` là `bundleNo`; hỗ trợ `If-None-Match` và `304`; dùng cho OPA (PH-12) và điểm thực thi.
:::

#### API-09-234 · Tra trạng thái đồng ý

::: dac-ta
**Mục đích.** Tra trạng thái đồng ý.

**Phương thức, đường dẫn.** `POST /privacy/v1/consents:check`.

**Quyền.** scope privacy:consent.

**FR hiện thực.** FR-09-054.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ConsentCheckRequest`; trường bắt buộc: `templateCode`, `subjectHash`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsentCheckResponse`; trường bắt buộc: `status`, `restrictionActive`, `cacheSeconds`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-09-106, ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả đệm `09.consent.cache-seconds` (60) giây; kèm cờ `restrictionActive` của chủ thể.
:::

#### API-09-235 · Tính băm HMAC định danh chủ thể

::: dac-ta
**Mục đích.** Tính băm HMAC định danh chủ thể.

**Phương thức, đường dẫn.** `POST /privacy/v1/subject-hashes:compute`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-047, FR-09-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SubjectHashRequest`; trường bắt buộc: `identifierType`, `identifiers`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubjectHashResponse`; trường bắt buộc: `keyRef`, `items`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `503`; mã lỗi của thao tác: ERR-09-106, ERR-09-108, ERR-09-111 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** HMAC-SHA256 khóa riêng tenant; không ghi giá trị vào (ERR-09-108 khi OpenBao không khả dụng); chỉ cho bên có `privacy:decide`.
:::

#### API-09-236 · Xác thực phiếu xem đầy đủ

::: dac-ta
**Mục đích.** Xác thực phiếu xem đầy đủ.

**Phương thức, đường dẫn.** `POST /privacy/v1/reveal-grants/{grantId}:verify`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-029.

**Tham số.** `grantId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevealVerifyRequest`; trường bắt buộc: `token`, `elementId`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RevealVerifyResponse`; trường bắt buộc: `valid`, `status`, `remainingSeconds`.

**Lỗi.** HTTP `401`, `403`, `429`; mã lỗi của thao tác: ERR-09-111, ERR-09-112 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xác thực phiếu xem đầy đủ do điểm thực thi gọi; phiếu hết hạn hoặc sai thì ERR-09-112.
:::

#### API-09-237 · Điểm thực thi báo lượt khai thác theo lô

::: dac-ta
**Mục đích.** Điểm thực thi báo lượt khai thác theo lô.

**Phương thức, đường dẫn.** `POST /privacy/v1/usage-events:report`.

**Quyền.** scope privacy:decide.

**FR hiện thực.** FR-09-020.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `UsageEventsRequest`; trường bắt buộc: `point`, `events`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `UsageEventsResponse`; trường bắt buộc: `accepted`, `rejected`.

**Lỗi.** HTTP `400`, `401`, `403`, `413`, `429`; mã lỗi của thao tác: ERR-09-106, ERR-09-107, ERR-09-111, ERR-09-113 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Báo lượt khai thác theo lô ≤ 1.000 sự kiện mỗi lời gọi, cộng dồn vào bộ đếm theo phút; trả `202`; vượt hạn mức gọi thì ERR-09-113.
:::
<!-- gen:dac-ta:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-API và K-TRINH-BAY: 237 operation (226 control plane, 11 data plane), 33 kênh sự kiện, 91 mã lỗi, OpenAPI 3.1 và AsyncAPI 3.0 sinh từ FRS, ví dụ kiểm khớp lược đồ, đặc tả 10 mục cho 35 operation trọng yếu, năm câu hỏi mở Q09-55…59 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: thêm API-09-238 đến 245 (245 operation, 234 control plane), ERR-09-082 và đưa 079 đến 081 về FRS, `requestKind`, `renewsGrantId`, `serverTime`, `remainingThisHour`, hạn 60 giây của kết quả khôi phục, giới hạn bản tin 1 MiB, 329 lược đồ, 37 operation trọng yếu, chốt bốn trong năm câu hỏi mở |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: API-09-203 thêm scope `privacy:register` cho PH-18; thân xoay khóa API-09-116 thêm `confirmInconsistency`; bên tiêu thụ EVT-09-01, EVT-09-03; chốt câu hỏi mở đợt đồng bộ: Q393 |
| 0.4 | 27/11/2026 | Nhóm viết tài liệu (Claude) | API-09-231: ghi `egressScope` ngoài `NONE`, `OUT_OF_PROVINCE` trả ERR-09-106 (400); sinh lại từ nguồn |
