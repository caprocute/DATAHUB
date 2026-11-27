---
ma_tai_lieu: D03-04-PH14
ten: Đặc tả API và sự kiện phân hệ PH-14 Kết nối quốc gia
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration, dh-runtime, APISIX; đơn vị kết nối (PH-02, PH-04, PH-07); ATTT; hội đồng thẩm định
phan_he: PH-14
mo_ta: Đặc tả 94 endpoint REST ở ba mặt phẳng (điều khiển, dữ liệu nội bộ, chiều vào), 17 sự kiện Kafka và 72 mã lỗi của phân hệ Kết nối quốc gia, sinh từ OpenAPI và AsyncAPI đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH14 FRS; D02-04-PH14 Use case; D03-02-PH14 SDD; D03-03-PH14 CSDL; D03-04-PH05 API Bộ điều hợp; D04-01 Quy ước mã
---

# D03-04-PH14 · Đặc tả API và sự kiện Kết nối quốc gia

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-14 là cổng duy nhất để HTTT của tỉnh gọi các dịch vụ do nền tảng cấp quốc gia (NDXP, NDOP, hệ thống đăng ký danh mục dịch vụ) cung cấp và để trung ương gọi vào tỉnh. Tài liệu này chốt hợp đồng giao diện của phân hệ: 94 operation REST (API-14-001…094), 17 sự kiện Kafka (EVT-14-01…17) cùng ba chủ đề nội bộ giữa hai mặt phẳng, và 72 mã lỗi (ERR-14-001…039, 101…133). Hợp đồng máy đọc được nằm ở hai tệp:

- [`ph14/openapi-national.yaml`](ph14/openapi-national.yaml): OpenAPI 3.1, 145 lược đồ, 25 ví dụ đã kiểm khớp lược đồ bằng [`check_contracts.py`](ph14/tools/check_contracts.py), đã qua `openapi-spec-validator` và Spectral `spectral:oas` (0 lỗi, 0 cảnh báo).
- [`ph14/asyncapi-national.yaml`](ph14/asyncapi-national.yaml): AsyncAPI 3.0, 20 kênh (17 sự kiện công bố, 3 nội bộ), 4 ví dụ đã kiểm, đã qua `@asyncapi/cli validate` (0 lỗi, 0 cảnh báo).

Cả hai sinh từ bảng mã [`ph14/tools/spec.py`](ph14/tools/spec.py); các bảng ở chương 3, 4, 6, 11 sinh bằng `gen_md.py` và chương 10 bằng `build/tools/sinh_dac_ta_api.py`, nên tài liệu không lệch hợp đồng.

**Phạm vi.** Ba mặt phẳng với ba cách xác thực khác nhau: mặt phẳng **điều khiển** `/api/national/v1` (người dùng qua BFF, 80 operation), mặt phẳng **dữ liệu nội bộ** `/internal/national/v1` (HTTT, luồng PH-04, PH-07 và `dh-runtime` bằng token dịch vụ, 10 operation) và mặt phẳng **chiều vào** `/inbound/v1` (nền tảng quốc gia bằng mTLS, 2 operation). Tài liệu không mô tả API của nền tảng quốc gia (do trung ương công bố, đang chờ ở Q14-01) mà chỉ mô tả cách PH-14 trình bày chúng thành một hợp đồng thống nhất cho tỉnh.

**Căn cứ.** Nghị định 331/2026 và Nghị định 278/2025 về kết nối, chia sẻ dữ liệu; Luật Bảo vệ dữ liệu cá nhân 91/2025 với Nghị định 356/2025 (kiểm tra mục đích, che nội dung); TCVN 14423:2026 (xác thực nhiều yếu tố, nhật ký); các quyết định ADR-002 (Camel Quarkus), ADR-057 (đồng bộ quốc gia qua PH-14), ADR-061, ADR-070 (tương thích lược đồ sự kiện).

**Những điểm hội đồng cần lưu ý.**

1. **HTTT không giữ thông tin xác thực quốc gia.** Tài khoản của tỉnh với NDXP dùng chung cho mọi HTTT nên không API nào trả hoặc nhận bí mật, khóa riêng hay chứng thư kèm khóa; kiểm tra hợp đồng chặn các trường này ở mọi lược đồ. Bí mật đi qua PH-05 (API-05-012, 020), khóa ký nằm ở OpenBao `transit`.
2. **Kiểm soát mục đích đứng trước đệm và hạn mức.** Mỗi lượt gọi dữ liệu cá nhân phải kèm mục đích và mã hồ sơ (ERR-14-106, 107); không đạt thì từ chối an toàn và vẫn ghi giao dịch (ERR-14-132 khi không kiểm tra được).
3. **Bốn mắt ở tám loại thay đổi nhạy cảm** (bật nền tảng, luật định tuyến, hạn mức môi trường thật, chứng thư, điểm cuối chiều vào, công bố dữ liệu mở lần đầu, giảm kiểm soát dịch vụ, tham số bảo mật), cùng xác thực nhiều yếu tố khi nạp, kích hoạt chứng thư và xem nội dung bản tin đầy đủ.
4. **Lỗi chữ ký là sự cố an ninh**, không phải lỗi nghiệp vụ: ERR-14-109…111 mở sự cố, báo Cán bộ ATTT và có thể đưa nền tảng vào `SECURITY_HOLD`.
5. **Có điểm cần xác nhận với đơn vị bên ngoài hoặc phân hệ khác** (chương 9 và Đề nghị đồng bộ), đáng kể nhất là định dạng thân và chữ ký của chiều vào (Q14-58) và quy ước `type` của RFC 9457 (Q14-56, đã chốt: `If-Match` lệch trả 412).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Operation REST | 94 (điều khiển 82, dữ liệu nội bộ 10, chiều vào 2) |
| Phủ FR | 57/57 FR có API hoặc ghi rõ cách hiện thực (chương 11) |
| Sự kiện công bố, nội bộ | 17, 3 |
| Mã lỗi | 72 (39 điều khiển, 33 dữ liệu) |
| Lược đồ OpenAPI, ví dụ đã kiểm | 147, 25 |
| Câu hỏi mở mới | 5 (Q14-55…Q14-59) |

: Con số chính của tập API PH-14

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả giao diện lập trình của PH-14: các endpoint REST ở ba mặt phẳng, sự kiện Kafka, hợp đồng với phân hệ khác và với nền tảng quốc gia, bảng mã lỗi ERR-14. Nguồn chuẩn là hai tệp máy đọc được; bảng danh mục ở chương 3 và đặc tả từng endpoint ở chương 10 (mỗi endpoint một bảng 10 mục) đều sinh từ OpenAPI. Tài liệu không lặp lại nghiệp vụ của FRS (D02-03-PH14) hay thiết kế bên trong của SDD (D03-02-PH14); khi cần hiểu vì sao một endpoint có điều kiện nào thì mở chức năng FR tương ứng ở cột FR.

### 0.2. Người đọc và phần cần đọc

Bảng dưới chỉ ra mỗi nhóm người đọc nên đọc chương nào của tài liệu này, vì phần lớn nội dung là danh mục tra cứu theo từng endpoint.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-integration`, giao diện console | Chương 1, 2, 3, 10 |
| Kỹ sư `dh-runtime` (cổng quốc gia), PH-04 | Chương 3 (API-14-075…083, 091), 4, 5, 6.2 |
| Kỹ sư PH-02, PH-03, PH-07, PH-09, PH-13 | Chương 5 |
| APISIX, ATTT | Chương 2, 3 (chiều vào), 5 |
| Kiểm thử viên | Chương 6, 7, 10, 11 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 9 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng chung theo D00-01 §2 và FRS D02-03-PH14 §1.4. Riêng tài liệu này dùng thêm các từ sau.

| Thuật ngữ | Nghĩa |
|---|---|
| Mặt phẳng điều khiển | `dh-integration` (module `national`): khai báo, duyệt, tra cứu; ghi PostgreSQL |
| Mặt phẳng dữ liệu | `dh-runtime` hồ sơ `national-gateway`, vai trò `gateway` và `worker`: gọi ra, nhận vào; không nối PostgreSQL (ADR đề xuất ở Đề nghị đồng bộ) |
| `transactionCode` | Mã giao dịch `{TENANT}-{yyyyMMdd}-{10 ký tự}`, ví dụ `T68-20261126-0000184320`; mã đối soát với trung ương |
| `securityHold` | Cờ của nền tảng: cổng từ chối mọi lượt cần dữ liệu mới sau chuỗi sự cố chữ ký, tới khi SO giải trừ |
| Nhãn đối chiếu | `STILL`, `SPEC_CHANGED`, `DISCONTINUED`, `UNKNOWN` (FRS §4.1) |
| `acr` | Claim cấp độ xác thực của token Keycloak; "mạnh" nghĩa là có yếu tố thứ hai trong 15 phút |
| Cung cấp lại | Gắn một dịch vụ quốc gia với một API ở PH-02 để HTTT đăng ký và gọi qua APISIX |

: Thuật ngữ riêng của tập API

### 0.4. Tài liệu tham chiếu

D02-03-PH14 (FRS, 57 FR), D02-04-PH14 (use case), D03-02-PH14 (SDD, §3.3 DTO, §4.4 chín chặng, §8.2 sự kiện), D03-03-PH14 (CSDL, §1.5 chuyển lỗi CSDL sang mã lỗi API), D03-04-PH05 (mẫu và hợp đồng PH-05), D02-08 (quyền `PERM-14-*`), D03-07 (SEC), ADR-057, ADR-070.

### 0.5. Cấu trúc tài liệu

Tài liệu chia thành mười một chương và phần cuối; bảng dưới nêu nội dung từng chương để người đọc tìm đúng chỗ.

| Chương | Nội dung |
|---|---|
| 1, 2 | Quy ước chung, xác thực và phân quyền |
| 3 | Danh mục 94 endpoint, ví dụ yêu cầu và phản hồi |
| 4, 5 | Sự kiện; hợp đồng với phân hệ khác và bên ngoài |
| 6 | Mã lỗi ERR-14 và thông điệp |
| 7, 8, 9 | Kiểm tra hợp đồng trong CI; ánh xạ từ hệ cũ; câu hỏi mở |
| 10, 11 | Đặc tả từng endpoint (sinh); phủ FR |
| Cuối | Đề nghị đồng bộ, lịch sử phiên bản |

: Cấu trúc tài liệu

## 1. Quy ước chung

Chương này gom các quy ước áp cho cả 94 endpoint để chương 3 và chương 10 không phải nhắc lại. Khác biệt giữa ba mặt phẳng được nêu rõ ở các dòng tương ứng.

| Mục | Quy ước |
|---|---|
| Đường gốc | Điều khiển `/api/national/v1`: người dùng qua BFF console của tenant. Dữ liệu nội bộ `/internal/national/v1`: qua mesh trong cụm hoặc qua APISIX (API cung cấp lại viết lại sang API-14-075). Chiều vào `/inbound/v1`: qua APISIX vùng biên (Z1 → Z2), không qua BFF |
| Đường dẫn trong OpenAPI | Đầy đủ gốc ở mọi path (khác PH-05) vì một tệp phục vụ ba mặt phẳng; bảng chương 3 ghi đường dẫn điều khiển tương đối với `/api/national/v1` và ghi đủ gốc cho hai mặt phẳng còn lại |
| Phiên bản | `v1` trong đường dẫn; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng; oasdiff ở CI-5 chặn thay đổi phá vỡ trong `v1` |
| Tenant | Điều khiển và dữ liệu: lấy từ token (claim `tenant`), không bao giờ từ đường dẫn hay thân; tenant `COMMON` chỉ PA ghi. Chiều vào: lấy từ điểm cuối đã đăng ký (BR-14-027); APISIX gắn `X-DH-Tenant`, lệch claim thì 403 và sự kiện an ninh |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:suspend`, `:approve-activation`, `:reveal`) theo quy ước D00-04 §4 |
| Khóa lạc quan | `GET` đối tượng trả `ETag: W/"{version}"`; `PUT`, `PATCH`, `DELETE` và hành động đổi trạng thái bắt buộc `If-Match`; lệch trả **ERR-14-004 với HTTP 412** kèm `currentEtag` (ERR-14-004 vẫn là 409 khi lỗi do trạng thái không cho phép), theo FRS §9.1 và D04-01 |
| Chống trùng | `POST` tạo, chạy nền, xuất, nhập bắt buộc `Idempotency-Key` (16…128 ký tự, 24 giờ); cùng khóa cùng thân trả lại phản hồi cũ; khác thân ERR-14-116. API-14-075 chỉ bắt buộc với dịch vụ `WRITE` (thiếu: ERR-14-003) |
| Phân trang | `page` (từ 1), `size` (mặc định 25, tối đa 100; vượt: ERR-14-003 kèm `max`); phản hồi `page: {number, size, totalItems, totalPages}`; giao dịch và nhật ký khai thác giới hạn khoảng thời gian ≤ 31 ngày; API-14-061 thêm phân trang keyset tùy chọn qua `after` theo (`started_at`, `transaction_code`) và trả `nextCursor` (Q14-59); lỗi lưu trữ của máy chủ ánh xạ sang mã ERR-14 theo bảng ở D03-03-PH14 §1.5; `ETag` của đối tượng là `version` |
| Lọc, tìm | Tham số lặp dạng `state=ACTIVE,SUSPENDED`; tìm `q` không dấu, tối thiểu 2 ký tự |
| Lỗi | RFC 9457 `application/problem+json`; `type` = `https://datahub.gov.vn/errors/ERR-14-nnn`, `code`, `title`, `status`, `detail` (câu tiếng Việt hiển thị được), `traceId` (32 ký tự hex, khớp `traceparent`); lỗi mặt phẳng dữ liệu thêm `transactionCode`; trường riêng theo mã (`errors[]`, `currentEtag`, `scope`, `reason`, `resetAt`, `cache.available`, `retryAfterSeconds`). `detail` không chứa nội dung kỹ thuật của trung ương, cấu hình nội bộ hay bí mật |
| Lỗi chung | 401, 403 do APISIX, Keycloak, OPA sinh, có thể không có `code` (theo FR-00); sai tenant là ERR-00-003; lỗi không lường trước ERR-14-127 (500) |
| Hành động được phép | Đối tượng điều khiển trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm |
| Truy vết | `traceparent` W3C xuyên BFF → `dh-integration` → Kafka → `worker`; mặt phẳng dữ liệu thêm `X-DH-Transaction` ở phản hồi |
| Tiêu đề riêng | `X-DH-Accept-Stale` (chấp nhận đệm quá hạn), `X-DH-Parallel-Run` (gắn phiên chạy song song), `X-DH-On-Behalf-Of` (luồng PH-04 gọi thay HTTT), `X-DH-Service`, `X-DH-Operation` (APISIX viết lại tuyến cung cấp lại), `X-DH-Cache` (`HIT`, `MISS`, `STALE`) ở phản hồi |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail`, `hint` |
| Tiến trình dài | Đối chiếu, làm mới chuỗi tin cậy, đồng bộ, xuất bằng chứng, công bố dữ liệu mở trả `202` kèm `Location` và `jobId` hoặc `runId`; tra bằng `GET` tương ứng |
| Thời hạn | Mỗi lượt gọi quốc gia dùng `service.timeoutMs` (mặc định `14.timeout.default-ms` = 15 giây, 1…60 giây); điều khiển 30 giây; chiều vào chờ luồng `14.inbound.timeout-ms` = 10 giây |
| Kích thước | Đặc tả ≤ 5 MiB, tệp nhập hệ cũ ≤ 10 MiB, thân chiều vào ≤ `14.inbound.max-body-mb` (giả định 5 MiB, tham số do SDD đề nghị), phản hồi quốc gia ≤ `14.adapter.max-response-mb` = 10 MiB |
| Dữ liệu cá nhân | Mọi API trả giao dịch che nội dung; chỉ API-14-063 (SO, có lý do, xác thực mạnh) trả nội dung và mỗi lần bị ghi vết |

: Quy ước chung

Giả định: hồ sơ "tỉnh vừa" (GĐ-01, 200 HTTT) ở các con số kích thước và tần suất; con số thật chờ đo ở kiểm thử hiệu năng của D05-02-PH14.

## 2. Xác thực và phân quyền

Ba mặt phẳng dùng ba cách xác thực. Bảng dưới liệt kê bên gọi, luồng và nơi kiểm quyền; quyền theo từng operation nằm ở cột "Quyền" của chương 3.

| Bên gọi | Luồng | Kiểm quyền | Operation |
|---|---|---|---|
| Người dùng console (PA, TA, TO, SO, IE, IA, AU, VW) | OIDC Authorization Code + PKCE qua BFF; token không ra trình duyệt | `PERM-14-*` theo vai trò (D02-08); bốn mắt, xác thực mạnh kiểm ở máy chủ | Mặt phẳng điều khiển |
| HTTT của tỉnh | `client_credentials` + `private_key_jwt`; `azp` là mã HTTT | Scope `national.invoke.{nhóm}` do PH-01 cấp theo đăng ký đã duyệt ở PH-02; OPA kiểm mục đích, mã hồ sơ, khung giờ | API-14-075…078 |
| Luồng PH-04 (`dh-runtime`) | Như trên; Kamelet `dh-national-invoke`, `X-DH-On-Behalf-Of` | Scope `national.invoke.*`; OPA đối chiếu HTTT gốc với đăng ký của luồng | API-14-075…078, 089 |
| PH-07 | `client_credentials` | `national.catalog.read` (079…081, 083), `national.catalog.propose` (082, 083); chỉ PH-07 (BR-14-036) | API-14-079…083 |
| `dh-runtime` của tenant | `client_credentials` + `private_key_jwt`, client `dh-runtime-{tenant}` | `national.runtime-config`; token gắn tenant, gọi tenant khác trả 404 | API-14-091 |
| PH-02, PH-06 | `client_credentials` | `national.sync.trigger` | API-14-054, 056 |
| PH-13, PH-01 | `client_credentials` | `national.health-read` | API-14-058, 060, 073 (PH-13); API-14-043 (PH-01 đọc `remainingQuota`) |
| Nền tảng quốc gia (NDXP, NDOP) | mTLS chấm dứt ở APISIX vùng biên; vân tay chứng thư khớp nguồn được phép | Nguồn được phép theo dịch vụ (ERR-14-119); chữ ký bản tin xác minh ở cổng | API-14-084, 085 |

: Xác thực và phân quyền theo bên gọi

Thông tin xác thực của tỉnh với NDXP không cấp cho bất kỳ client nào (BR-14-007): chỉ hồ sơ `national-gateway` của đúng tenant có chính sách đọc bí mật ở OpenBao. Một số quy tắc vượt quyền chức năng:

- **Bốn mắt (BR-14-022).** Người duyệt khác người đề nghị và khác người sửa gần nhất (ERR-14-007): bật nền tảng (API-14-009), luật định tuyến (027), kích hoạt chứng thư (033), bật điểm cuối chiều vào (090), hạn mức môi trường thật (042), công bố dữ liệu mở lần đầu (087), giảm kiểm soát dịch vụ (013), tham số bảo mật (071). Hạn mức, tham số, điểm cuối và dữ liệu mở dùng API duyệt dùng chung của hộp "Việc của tôi" (FR-00-070), nên không có API duyệt riêng ở bảng.
- **Xác thực mạnh (SEC-23).** Nạp chứng thư (030), yêu cầu và duyệt kích hoạt (032, 033), xem nội dung đầy đủ (063), xuất bằng chứng (064) đòi claim `acr` có yếu tố thứ hai trong 15 phút; thiếu trả ERR-14-030.
- **Tách người giữ khóa khỏi người quyết định.** SO có `PERM-14-cert` nhưng không có `PERM-14-service`, `PERM-14-route`; IE và IA là cặp loại trừ ở D02-08 §4.
- **Tenant `COMMON`.** Chỉ PA ghi nền tảng, dịch vụ, chứng thư của danh mục dùng chung; tenant tỉnh ghi đối tượng `COMMON` bị từ chối 403.
- **`PERM-14-invoke`** không gán cho người: nó là scope `national.invoke.{nhóm}` của client máy (ví dụ `national.invoke.lltp`).

## 3. Danh mục endpoint

Mỗi operation một mã `API-14-nnn`. Mã 001…090 do FRS §9.4 đề xuất; tập này giữ nguyên và bổ sung bốn mã: **API-14-091** (ảnh chụp cấu hình cho `dh-runtime`, đề xuất của SDD §4.3) và **API-14-092** (xóa chứng thư chưa từng kích hoạt, FRS FR-14-029 có luồng này nhưng chưa có API), **API-14-093** (liệt kê yêu cầu chờ duyệt bốn mắt) và **API-14-094** (duyệt hoặc từ chối một yêu cầu); hai mã sau chốt ngày 27/11/2026 theo Q448 để UI-14-17 có API duyệt chung cho năm loại thay đổi chưa có API duyệt riêng (hạn mức môi trường thật, bật điểm cuối chiều vào, tham số bảo mật, giảm kiểm soát dịch vụ, lần công bố dữ liệu mở đầu tiên). Cột FR là số FR-14; chi tiết tham số, lược đồ và mô tả lỗi theo từng operation ở OpenAPI và chương 10.

<!-- gen:endpoints:start -->
**Nền tảng quốc gia**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-001 | `GET /platforms` | Liệt kê nền tảng quốc gia | 001 | `PERM-14-read` |  | 200 |
| API-14-002 | `POST /platforms` | Khai báo nền tảng quốc gia | 002 | `PERM-14-admin` | bắt buộc | 201 |
| API-14-003 | `GET /platforms/{platformCode}` | Chi tiết nền tảng quốc gia | 001, 002 | `PERM-14-read` |  | 200 |
| API-14-004 | `PATCH /platforms/{platformCode}` | Sửa nền tảng quốc gia | 002 | `PERM-14-admin` |  | 200 |
| API-14-005 | `POST /platforms/{platformCode}:suspend` | Tạm ngừng nền tảng | 003 | `PERM-14-operate` |  | 200 |
| API-14-006 | `POST /platforms/{platformCode}:resume` | Tiếp tục nền tảng | 003 | `PERM-14-operate` |  | 200 |
| API-14-007 | `POST /platforms/{platformCode}:retire` | Ngừng dùng nền tảng | 003 | `PERM-14-admin` |  | 200 |
| API-14-008 | `POST /platforms/{platformCode}:request-activation` | Gửi duyệt bật nền tảng | 003 | `PERM-14-admin` |  | 200 |
| API-14-009 | `POST /platforms/{platformCode}:approve-activation` | Duyệt hoặc từ chối bật nền tảng | 003 | `PERM-14-approve` |  | 200 |
| API-14-039 | `POST /platforms/{platformCode}/credentials:rotate` | Xoay vòng thông tin xác thực nền tảng | 025 | `PERM-14-operate` | bắt buộc | 202 |
| API-14-040 | `POST /platforms/{platformCode}/token:test` | Thử lấy token của nền tảng | 024, 025 | `PERM-14-operate` |  | 200 |

: Danh mục endpoint · Nền tảng quốc gia

**Dịch vụ quốc gia**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-010 | `GET /services` | Liệt kê, tìm dịch vụ quốc gia | 004 | `PERM-14-read` |  | 200 |
| API-14-011 | `POST /services` | Khai báo dịch vụ quốc gia | 005 | `PERM-14-service` | bắt buộc | 201 |
| API-14-012 | `GET /services/{serviceCode}` | Chi tiết dịch vụ, hợp đồng và nhãn đối chiếu | 006 | `PERM-14-read` |  | 200 |
| API-14-013 | `PATCH /services/{serviceCode}` | Sửa dịch vụ quốc gia | 005 | `PERM-14-service` |  | 200 |
| API-14-014 | `POST /service-reconciliations` | Chạy đối chiếu danh mục dịch vụ với NDXP | 007 | `PERM-14-service` | bắt buộc | 202 |
| API-14-015 | `GET /service-reconciliations/{runId}` | Kết quả một lần đối chiếu | 007 | `PERM-14-read` |  | 200 |
| API-14-016 | `POST /service-reconciliations/{runId}:apply` | Áp dụng kết quả đối chiếu | 007 | `PERM-14-service` |  | 200 |
| API-14-017 | `POST /services/{serviceCode}:set-label` | Đặt nhãn đối chiếu bằng tay | 007 | `PERM-14-service` |  | 200 |
| API-14-018 | `GET /services/{serviceCode}/specs` | Danh sách phiên bản đặc tả của dịch vụ | 008 | `PERM-14-read` |  | 200 |
| API-14-019 | `POST /services/{serviceCode}/specs` | Nạp đặc tả dịch vụ | 008 | `PERM-14-service` | bắt buộc | 201 |
| API-14-020 | `POST /services/{serviceCode}/specs/{specVersion}:activate` | Kích hoạt phiên bản đặc tả | 008 | `PERM-14-service` |  | 200 |
| API-14-021 | `GET /services/{serviceCode}/exposure` | Xem cung cấp lại của dịch vụ | 009 | `PERM-14-read` |  | 200 |
| API-14-022 | `PUT /services/{serviceCode}/exposure` | Khai báo cung cấp lại dịch vụ | 009 | `PERM-14-service` |  | 200 |
| API-14-023 | `POST /services/{serviceCode}/exposure:publish` | Công bố cung cấp lại lên danh mục dịch vụ PH-02 | 009 | `PERM-14-service` | bắt buộc | 202 |

: Danh mục endpoint · Dịch vụ quốc gia

**Định tuyến**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-024 | `GET /routing-rules` | Liệt kê luật định tuyến | 013 | `PERM-14-read` |  | 200 |
| API-14-025 | `POST /routing-rules` | Tạo luật định tuyến | 013 | `PERM-14-route` | bắt buộc | 201 |
| API-14-026 | `PATCH /routing-rules/{ruleId}` | Sửa luật định tuyến | 013 | `PERM-14-route` |  | 200 |
| API-14-027 | `POST /routing-rules/{ruleId}:approve` | Duyệt hoặc từ chối luật định tuyến | 013 | `PERM-14-approve` |  | 200 |
| API-14-028 | `POST /routing-rules:simulate` | Mô phỏng định tuyến | 012, 013 | `PERM-14-route` |  | 200 |

: Danh mục endpoint · Định tuyến

**Chứng thư và sự cố chữ ký**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-029 | `GET /certificates` | Liệt kê chứng thư số | 029 | `PERM-14-read` |  | 200 |
| API-14-030 | `POST /certificates` | Nạp chứng thư số | 028 | `PERM-14-cert` | bắt buộc | 201 |
| API-14-031 | `GET /certificates/{certCode}` | Chi tiết chứng thư số | 029 | `PERM-14-read` |  | 200 |
| API-14-032 | `POST /certificates/{certCode}:request-activation` | Yêu cầu kích hoạt chứng thư | 028 | `PERM-14-cert` |  | 200 |
| API-14-033 | `POST /certificates/{certCode}:approve-activation` | Duyệt hoặc từ chối kích hoạt chứng thư | 028 | `PERM-14-approve` |  | 200 |
| API-14-034 | `POST /certificates/{certCode}:revoke` | Thu hồi chứng thư số | 029 | `PERM-14-cert` |  | 200 |
| API-14-035 | `GET /trust-store` | Xem chuỗi tin cậy và danh sách thu hồi | 030 | `PERM-14-read` |  | 200 |
| API-14-036 | `POST /trust-store:refresh` | Làm mới chuỗi tin cậy và danh sách thu hồi | 030 | `PERM-14-cert` |  | 202 |
| API-14-037 | `GET /signature-incidents` | Liệt kê sự cố chữ ký | 031 | `PERM-14-read` |  | 200 |
| API-14-038 | `POST /signature-incidents/{incidentId}:transition` | Xử lý sự cố chữ ký | 031 | `PERM-14-operate` |  | 200 |
| API-14-092 | `DELETE /certificates/{certCode}` | Xóa chứng thư chưa từng kích hoạt | 029 | `PERM-14-cert` |  | 204 |

: Danh mục endpoint · Chứng thư và sự cố chữ ký

**Hạn mức và đệm**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-041 | `GET /quotas` | Liệt kê hạn mức | 032, 033 | `PERM-14-read` |  | 200 |
| API-14-042 | `POST /quotas` | Khai báo hạn mức do trung ương áp | 032 | `PERM-14-quota` | bắt buộc | 201 |
| API-14-043 | `GET /quotas/usage` | Mức dùng hạn mức hiện tại | 033 | `PERM-14-read` hoặc `national.health-read` (dịch vụ) |  | 200 |
| API-14-044 | `GET /quota-allocations` | Liệt kê phân bổ hạn mức theo HTTT | 034 | `PERM-14-read` |  | 200 |
| API-14-045 | `PUT /quota-allocations/{systemCode}` | Đặt phân bổ hạn mức cho một HTTT | 034 | `PERM-14-quota` |  | 200 |
| API-14-046 | `GET /cache/stats` | Thống kê đệm | 035 | `PERM-14-read` |  | 200 |
| API-14-047 | `POST /cache:invalidate` | Vô hiệu đệm | 036 | `PERM-14-operate` |  | 200 |

: Danh mục endpoint · Hạn mức và đệm

**Điểm cuối chiều vào**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-048 | `GET /inbound-endpoints` | Liệt kê điểm cuối chiều vào | 039 | `PERM-14-read` |  | 200 |
| API-14-049 | `POST /inbound-endpoints` | Đăng ký điểm cuối chiều vào | 039 | `PERM-14-admin` | bắt buộc | 201 |
| API-14-050 | `PATCH /inbound-endpoints/{endpointCode}` | Sửa điểm cuối chiều vào | 039 | `PERM-14-admin` |  | 200 |
| API-14-051 | `GET /inbound-endpoints/{endpointCode}/allowed-senders` | Danh sách nguồn được phép | 039 | `PERM-14-read` |  | 200 |
| API-14-052 | `PUT /inbound-endpoints/{endpointCode}/allowed-senders` | Đặt danh sách nguồn được phép | 039 | `PERM-14-admin` |  | 200 |
| API-14-090 | `POST /inbound-endpoints/{endpointCode}:confirm` | Xác nhận vân tay chứng thư nguồn và bật điểm cuối | 039 | `PERM-14-cert` |  | 200 |

: Danh mục endpoint · Điểm cuối chiều vào

**Đồng bộ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-053 | `GET /sync/runs` | Liệt kê phiên đồng bộ | 043, 046 | `PERM-14-read` |  | 200 |
| API-14-054 | `POST /sync/catalog-runs` | Chạy đồng bộ danh mục dịch vụ lên Bộ | 043 | `PERM-14-sync` hoặc `national.sync.trigger` (dịch vụ) | bắt buộc | 202 |
| API-14-055 | `GET /sync/runs/{runId}` | Chi tiết một phiên đồng bộ | 043, 046 | `PERM-14-read` |  | 200 |
| API-14-056 | `POST /sync/master-data-runs` | Chạy đồng bộ dữ liệu chủ | 044 | `PERM-14-sync` hoặc `national.sync.trigger` (dịch vụ) | bắt buộc | 202 |
| API-14-057 | `POST /sync/runs/{runId}:retry` | Thử lại bản ghi lỗi của phiên đồng bộ | 046 | `PERM-14-sync` |  | 202 |
| API-14-087 | `POST /open-datasets` | Công bố tập dữ liệu mở lên NDOP | 045 | `PERM-14-sync` | bắt buộc | 202 |
| API-14-088 | `POST /open-datasets/{datasetCode}:withdraw` | Gỡ tập dữ liệu mở | 045 | `PERM-14-sync` |  | 202 |

: Danh mục endpoint · Đồng bộ

**Giám sát và nhật ký khai thác**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-058 | `GET /health` | Sức khỏe nền tảng quốc gia | 047 | `PERM-14-read` hoặc `national.health-read` (dịch vụ) |  | 200 |
| API-14-059 | `POST /platforms/{platformCode}:probe` | Kiểm tra kết nối tay | 047 | `PERM-14-operate` |  | 200 |
| API-14-060 | `GET /dashboard` | Tổng quan kết nối quốc gia | 048 | `PERM-14-read` hoặc `national.health-read` (dịch vụ) |  | 200 |
| API-14-061 | `GET /transactions` | Tra cứu giao dịch quốc gia | 049 | `PERM-14-audit-read` |  | 200 |
| API-14-062 | `GET /transactions/{transactionCode}` | Chi tiết giao dịch (nội dung đã che) | 049 | `PERM-14-audit-read` |  | 200 |
| API-14-063 | `POST /transactions/{transactionCode}:reveal` | Xem nội dung bản tin đầy đủ có lý do | 050 | `PERM-14-audit-reveal` |  | 200 |
| API-14-064 | `POST /transactions:export-evidence` | Xuất bằng chứng giao dịch | 051 | `PERM-14-audit-reveal` | bắt buộc | 202 |
| API-14-065 | `GET /usage` | Nhật ký khai thác theo HTTT | 052 | `PERM-14-audit-read` |  | 200 |
| API-14-066 | `POST /usage:export` | Xuất báo cáo sử dụng | 052 | `PERM-14-audit-read` | bắt buộc | 202 |
| API-14-067 | `GET /anomaly-alerts` | Liệt kê cảnh báo bất thường khai thác | 053 | `PERM-14-audit-read` |  | 200 |
| API-14-068 | `POST /anomaly-alerts/{alertId}:resolve` | Xử lý cảnh báo bất thường | 053 | `PERM-14-audit-read` |  | 200 |
| API-14-069 | `POST /reports/quota-efficiency` | Sinh báo cáo hạn mức và hiệu quả đệm | 057 | `PERM-14-audit-read` | bắt buộc | 202 |
| API-14-086 | `POST /platforms/{platformCode}/breaker:set` | Ép đóng hoặc mở ngắt mạch bằng tay | 038 | `PERM-14-operate` |  | 200 |

: Danh mục endpoint · Giám sát và nhật ký khai thác

**Tham số và chuyển đổi**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-070 | `GET /settings` | Xem tham số phân hệ | 054 | `PERM-14-read` |  | 200 |
| API-14-071 | `PUT /settings` | Đặt tham số phân hệ | 054 | `PERM-14-admin` |  | 200 |
| API-14-072 | `POST /migration/parallel-runs` | Tạo phiên chạy song song với hệ cũ | 055 | `PERM-14-service` | bắt buộc | 201 |
| API-14-073 | `GET /migration/parallel-runs/{runId}` | Kết quả phiên chạy song song | 055 | `PERM-14-read` hoặc `national.health-read` (dịch vụ) |  | 200 |
| API-14-074 | `POST /migration/legacy-services:import` | Nhập cấu hình dịch vụ từ hệ cũ | 056 | `PERM-14-service` | bắt buộc | 202 |
| API-14-089 | `POST /migration/parallel-runs/{runId}/observations` | Gửi quan sát cho phiên chạy song song | 055 | `national.parallel-observe` (dịch vụ) |  | 202 |

: Danh mục endpoint · Tham số và chuyển đổi

**Duyệt bốn mắt chung**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-093 | `GET /approval-requests` | Liệt kê yêu cầu chờ duyệt bốn mắt của phân hệ | 003, 005, 013, 028, 030, 032, 039, 045 | `PERM-14-approve` |  | 200 |
| API-14-094 | `POST /approval-requests/{approvalId}:decide` | Duyệt hoặc từ chối một yêu cầu chờ duyệt | 005, 032, 039, 045 | `PERM-14-approve` |  | 200 |

: Danh mục endpoint · Duyệt bốn mắt chung

**Gọi dịch vụ (nội bộ)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-075 | `POST /internal/national/v1/invocations` | Gọi dịch vụ quốc gia qua điểm gọi chung | 010, 017-022 | `national.invoke` (dịch vụ) | tùy chọn | 200 |
| API-14-076 | `POST /internal/national/v1/async-invocations` | Gửi yêu cầu bất đồng bộ vào hàng chờ | 016, 018 | `national.invoke` (dịch vụ) | bắt buộc | 202 |
| API-14-077 | `GET /internal/national/v1/async-invocations/{requestId}` | Tra kết quả yêu cầu bất đồng bộ | 016 | `national.invoke` (dịch vụ) |  | 200 |
| API-14-078 | `POST /internal/national/v1/async-invocations/{requestId}:cancel` | Hủy yêu cầu bất đồng bộ còn trong hàng chờ | 016 | `national.invoke` (dịch vụ) |  | 200 |

: Danh mục endpoint · Gọi dịch vụ (nội bộ)

**Cổng danh mục và cấu hình (nội bộ)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-079 | `GET /internal/national/v1/national-catalogs` | Liệt kê danh mục dùng chung quốc gia | 023 | `national.catalog.read` (dịch vụ) |  | 200 |
| API-14-080 | `GET /internal/national/v1/national-catalogs/{remoteCode}/structure` | Cấu trúc một danh mục quốc gia | 023 | `national.catalog.read` (dịch vụ) |  | 200 |
| API-14-081 | `GET /internal/national/v1/national-catalogs/{remoteCode}/data` | Dữ liệu một danh mục quốc gia | 023 | `national.catalog.read` (dịch vụ) |  | 200 |
| API-14-082 | `POST /internal/national/v1/national-catalogs/{remoteCode}/proposals` | Gửi đề xuất bổ sung danh mục quốc gia | 023 | `national.catalog.propose` (dịch vụ) | bắt buộc | 202 |
| API-14-083 | `GET /internal/national/v1/national-catalogs/{remoteCode}/proposals/{proposalId}` | Trạng thái đề xuất bổ sung danh mục | 023 | `national.catalog.propose` (dịch vụ) |  | 200 |
| API-14-091 | `GET /internal/national/v1/runtime-config` | Ảnh chụp cấu hình không bí mật cho cổng quốc gia | 010, 012, 033 | `national.runtime-config` (dịch vụ) |  | 200 |

: Danh mục endpoint · Cổng danh mục và cấu hình (nội bộ)

**Chiều vào (vùng biên)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-14-084 | `POST /inbound/v1/{endpointCode}/{serviceCode}` | Tiếp nhận yêu cầu từ nền tảng quốc gia | 040, 041 | mTLS nguồn được phép |  | 200 |
| API-14-085 | `POST /inbound/v1/{endpointCode}/notifications` | Tiếp nhận thông báo thay đổi từ quốc gia | 042 | mTLS nguồn được phép |  | 202 |

: Danh mục endpoint · Chiều vào (vùng biên)
<!-- gen:endpoints:end -->

### 3.1. Ví dụ yêu cầu và phản hồi

Ví dụ dưới đây là dữ liệu giả lập (tenant `T68`, HTTT `DVC`), đã được kiểm khớp lược đồ ở `check_contracts.py` khi là lược đồ có `examples`. Sơ đồ sau cho thấy đường đi của lượt gọi chính API-14-075.

```{.mermaid caption="Trình tự gọi dịch vụ quốc gia qua API-14-075"}
sequenceDiagram
  participant H as HTTT hoặc luồng PH-04
  participant A as APISIX
  participant G as Cổng quốc gia
  participant O as OPA và PH-09
  participant V as Valkey
  participant B as OpenBao
  participant N as Nền tảng quốc gia
  H->>A: POST invocations kèm token Datahub
  A->>G: chuyển tiếp kèm X-DH-Tenant
  G->>O: kiểm mục đích và mã hồ sơ
  O-->>G: cho phép
  G->>V: tra đệm, trừ hạn mức
  V-->>G: không có đệm, còn hạn mức
  G->>B: lấy token nền tảng và ký bản tin
  B-->>G: chữ ký
  G->>N: gửi bản tin đã ký qua egress
  N-->>G: phản hồi có chữ ký
  G->>G: xác minh chữ ký, chuẩn hóa, ghi giao dịch
  G-->>H: 200 data và meta
```

Hình trên cho thấy bên gọi chỉ làm việc với một điểm gọi: mục đích được kiểm trước khi chạm đệm, hạn mức hoặc nền tảng (OPA), mọi thông tin xác thực và khóa ký chỉ đi giữa cổng và OpenBao, và phản hồi chỉ về tới bên gọi sau khi chữ ký được xác minh.

**API-14-002 · Khai báo nền tảng quốc gia.** Yêu cầu (kèm `Idempotency-Key`):

```json
{ "platformCode": "ndxp-t68", "name": "Nền tảng chia sẻ dữ liệu quốc gia (NDXP) của tỉnh T68", "platformType": "NDXP",
  "connections": { "TEST": "ndxp-t68-oauth-test", "PROD": "ndxp-t68-oauth" }, "authMode": "PRIVATE_KEY_JWT", "specStatus": "OFFICIAL" }
```

Phản hồi `201` (`Location: /api/national/v1/platforms/ndxp-t68`, `ETag: W/"1"`):

```json
{ "platformCode": "ndxp-t68", "name": "Nền tảng chia sẻ dữ liệu quốc gia (NDXP) của tỉnh T68", "platformType": "NDXP", "scope": "TENANT",
  "state": "DRAFT", "securityHold": false, "specStatus": "OFFICIAL", "health": "UNKNOWN", "serviceCount": 0, "authMode": "PRIVATE_KEY_JWT",
  "allowedActions": ["update", "probe", "token-test"], "disabledReasons": { "request-activation": "Chưa có kiểm tra kết nối đạt trong 24 giờ" },
  "createdAt": "2026-11-26T08:00:00Z", "createdBy": "u-ta-0003", "version": 1 }
```

**API-14-011 · Khai báo dịch vụ quốc gia.** Yêu cầu:

```json
{ "serviceCode": "lltp-tra-trang-thai", "name": "Tra trạng thái hồ sơ lý lịch tư pháp", "platformCode": "ndxp-t68", "nationalServiceCode": "TP.LLTP.001",
  "group": "LLTP", "direction": "OUTBOUND", "protocol": "SOAP", "operationType": "READ", "sensitivity": "SENSITIVE", "priority": "ESSENTIAL",
  "cacheable": false, "signingMode": "XMLDSIG", "verifyMode": "XMLDSIG", "purposeRequired": true, "procedureCodeRequired": true, "timeoutMs": 15000 }
```

Bật đệm cho dịch vụ này (`"cacheable": true`) bị từ chối `422`:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-14-038", "title": "Cấu hình dịch vụ mâu thuẫn", "status": 422, "code": "ERR-14-038",
  "detail": "Dịch vụ mức Nhạy cảm hoặc dịch vụ ghi không được bật đệm.", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{ "path": "/cacheable", "rule": "sensitivity-no-cache", "message": "SENSITIVE không được đệm" }] }
```

**API-14-025 · Tạo luật định tuyến.** Yêu cầu `{ "matchGroup": "LLTP", "operationType": "READ", "primaryServiceCode": "lltp-tra-trang-thai", "allowFallback": false, "priority": 100, "basis": "Công văn hướng dẫn kết nối NDXP (giả định)" }`; phản hồi `201` trạng thái `PENDING_APPROVAL`, người duyệt nhận việc trong hộp "Việc của tôi" (API-14-027 xử lý).

**API-14-030 · Nạp chứng thư số.** Yêu cầu chỉ chứa phần công khai và tham chiếu khóa:

```json
{ "certCode": "ky-so-t68-2026", "platformCode": "ndxp-t68", "purpose": "SIGNING",
  "certificatePem": "-----BEGIN CERTIFICATE-----\nMIIC...giả lập...\n-----END CERTIFICATE-----", "keyRef": "kms-vidu-ky-so" }
```

Phản hồi `201` có `state: UPLOADED`, `keyMatchVerifiedAt` (ký thử qua `worker` khớp khóa ở OpenBao) và `chainOk: true`; không có trường nào chứa khóa.

**API-14-075 · Gọi dịch vụ quốc gia.** Yêu cầu từ HTTT `DVC` (không `Idempotency-Key` vì thao tác đọc):

```json
{ "serviceCode": "lltp-tra-trang-thai", "params": { "dossierCode": "LLTP-2026-000123" }, "purposeCode": "GIAI_QUYET_TTHC",
  "procedureCode": "1.001234", "caseCode": "HS-2026-08-001234", "freshData": false }
```

Phản hồi `200` (`X-DH-Transaction: T68-20261126-0000184320`, `X-DH-Cache: MISS`):

```json
{ "transactionCode": "T68-20261126-0000184320", "platformCode": "ndxp-t68", "data": { "status": "DA_CO_KET_QUA" },
  "meta": { "fromCache": false, "cacheAgeSeconds": null, "stale": false, "signatureVerified": true, "dataTime": "2026-11-26T08:15:02Z", "durationMs": 842 } }
```

Khi hết hạn mức, bên gọi nhận `429` và hướng dẫn dùng đệm nếu có:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-14-104", "title": "Hết hạn mức", "status": 429, "code": "ERR-14-104",
  "detail": "Đã dùng hết hạn mức truy vấn lltp-tra-trang-thai. Bộ đếm đặt lại lúc 27/11/2026 00:00.", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "transactionCode": "T68-20261126-0000184322", "scope": "SYSTEM", "reason": "QUOTA_EXHAUSTED", "resetAt": "2026-11-26T17:00:00Z", "cache": { "available": false } }
```

**API-14-076 · Gửi yêu cầu bất đồng bộ.** Cùng thân với API-14-075, bắt buộc `Idempotency-Key`; phản hồi `202`:

```json
{ "requestId": "6f0f6b1a-6a8e-4c52-8a3e-1f0d2b0a4c11", "transactionCode": "T68-20261126-0000184321", "state": "QUEUED",
  "statusUrl": "/internal/national/v1/async-invocations/6f0f6b1a-6a8e-4c52-8a3e-1f0d2b0a4c11", "queuePosition": 3 }
```

**API-14-063 · Xem nội dung bản tin đầy đủ.** Chỉ SO, kèm xác thực mạnh; yêu cầu `{ "reason": "Đối soát khiếu nại của công dân theo hồ sơ HS-2026-08-001234", "part": "RESPONSE" }`. Thiếu yếu tố thứ hai trả `403` ERR-14-030; nội dung quá hạn lưu `404` ERR-14-031. Phản hồi `200` có `viewId` để truy vết và `expiresAt` của lượt xem.

**API-14-084 · Tiếp nhận yêu cầu từ nền tảng quốc gia.** Sau khi biên chấm dứt mTLS, thân đã chuẩn hóa:

```json
{ "messageId": "msg-20261126-000771", "signedAt": "2026-11-26T08:15:00Z", "signature": "MEUCIQ...giả lập", "payload": { "dossierCode": "HT-2026-0001" } }
```

Bản tin lặp trong cửa sổ `14.inbound.replay-window-seconds` (600 giây) bị `409` ERR-14-122; cùng `messageId` gửi lại do mất biên nhận thì nhận lại kết quả đã có.

## 4. Danh mục sự kiện

Chủ đề theo `{tenant}.national.{thực-thể}.{sự-kiện}.v1` (D00-04 §4; ở môi trường thật `{tenant}` là chữ thường như `t68`). Lược đồ trong [`asyncapi-national.yaml`](ph14/asyncapi-national.yaml), đăng ký ở Apicurio chế độ BACKWARD (NFR-14-022, ADR-070). Sự kiện chỉ mang siêu dữ liệu và mã tham chiếu, không mang nội dung bản tin, thông tin xác thực hay dữ liệu cá nhân.

<!-- gen:events:start -->
| Mã | Chủ đề | Người phát | Qua | Khóa phân vùng | Giữ | Người nhận |
|---|---|---|---|---|---|---|
| EVT-14-01 | `{tenant}.national.platform.changed.v1` | `dh-integration` | Outbox | `platformCode` | 7 ngày | dh-runtime, PH-13 |
| EVT-14-02 | `{tenant}.national.service.changed.v1` | `dh-integration` | Outbox | `serviceCode` | 7 ngày | dh-runtime, PH-02, PH-13 |
| EVT-14-03 | `{tenant}.national.routing.changed.v1` | `dh-integration` | Outbox | `ruleId` | 7 ngày | dh-runtime |
| EVT-14-04 | `{tenant}.national.certificate.changed.v1` | `dh-integration` | Outbox | `certCode` | 30 ngày | dh-runtime, PH-13 |
| EVT-14-05 | `{tenant}.national.certificate.expiring.v1` | `dh-integration` | Outbox | `certCode` | 30 ngày | PH-13, thông báo ở PH-12 |
| EVT-14-06 | `{tenant}.national.signature.incident-opened.v1` | `dh-integration` | Outbox | `incidentId` | 30 ngày | PH-13 (SIEM), thông báo cho SO |
| EVT-14-07 | `{tenant}.national.quota.threshold-reached.v1` | `dh-runtime gateway` | LedgerSpool | `quotaId` | 7 ngày | PH-13, thông báo cho TA, TO |
| EVT-14-08 | `{tenant}.national.quota.changed.v1` | `dh-integration` | Outbox | `quotaId` | 7 ngày | dh-runtime, PH-13 |
| EVT-14-09 | `{tenant}.national.cache.invalidated.v1` | `dh-integration` | Outbox | `serviceCode` | 7 ngày | PH-13 |
| EVT-14-10 | `{tenant}.national.breaker.changed.v1` | `dh-runtime gateway` | LedgerSpool | `platformCode` | 7 ngày | PH-13, PH-04 |
| EVT-14-11 | `{tenant}.national.transaction.recorded.v1` | `dh-runtime gateway` | LedgerSpool | `transactionCode` | 3 ngày | PH-13, dh-integration (tổng hợp `usage_hourly`) |
| EVT-14-12 | `{tenant}.national.sync.run-finished.v1` | `dh-integration` | Outbox | `runId` | 7 ngày | PH-02, PH-06, PH-07, PH-13 |
| EVT-14-13 | `{tenant}.national.inbound.changed.v1` | `dh-integration` | Outbox | `endpointCode` | 7 ngày | PH-03 (nạp tuyến), PH-13 |
| EVT-14-14 | `{tenant}.national.exposure.changed.v1` | `dh-integration` | Outbox | `serviceCode` | 7 ngày | PH-02, PH-03 |
| EVT-14-15 | `{tenant}.national.health.changed.v1` | `dh-runtime worker` | LedgerSpool | `platformCode` | 7 ngày | PH-04, PH-13 |
| EVT-14-16 | `{tenant}.national.anomaly.detected.v1` | `dh-integration` | Outbox | `alertId` | 30 ngày | PH-13 (SIEM), thông báo cho SO |
| EVT-14-17 | `{tenant}.national.notification.received.v1` | `dh-runtime gateway` | LedgerSpool | `notificationId` | 7 ngày | PH-07, dh-runtime |
| nội bộ | `{tenant}.national.worker.command.v1` | `dh-integration` | Outbox | `commandId` | 1 ngày | dh-runtime worker |
| nội bộ | `{tenant}.national.worker.result.v1` | `dh-runtime worker` | LedgerSpool | `commandId` | 1 ngày | dh-integration |
| nội bộ | `{tenant}.national.quota.usage.v1` | `dh-runtime gateway` | LedgerSpool | `quotaId` | 3 ngày | dh-integration |

: Danh mục sự kiện của PH-14
<!-- gen:events:end -->

Hai cách phát, theo SDD §8.2. Sự kiện của mặt phẳng điều khiển (cột "Qua" là Outbox) ghi vào `ph14_national.outbox` cùng giao dịch với thay đổi miền, rồi Debezium hoặc bộ quét 500 ms đẩy lên Kafka; mang CloudEvents 1.0 nhị phân (`ce_type = vn.datahub.national.platform.changed.v1`, `ce_subject` là mã đối tượng). Sự kiện của cổng (cột "Qua" là LedgerSpool) ghi đĩa trước rồi đẩy Kafka, ít nhất một lần, giữ khóa phân vùng ổn định. Bên nhận xử lý lũy đẳng: cổng bỏ sự kiện có `configVersion` nhỏ hơn số đang giữ; bên tiêu thụ giao dịch ghi theo khóa tự nhiên `transactionCode` với `ON CONFLICT`. Chính sách tương thích: chỉ thêm trường tùy chọn trong `v1`; bỏ hoặc đổi nghĩa trường là `v2` và phát song song 6 tháng. Ba chủ đề nội bộ (`worker.command`, `worker.result`, `quota.usage`) không là EVT công bố; các chủ đề nội bộ khác của SDD (`signature.failed`, `async.state`, `asyncqueue.*`, `trust.crl`) giữ lược đồ ở Apicurio và chưa đưa vào AsyncAPI công bố (Q14-26 của SDD nêu hợp đồng nội bộ chờ xác nhận).

Ví dụ EVT-14-05 (chứng thư còn 30 ngày):

```json
{ "tenantId": "T68", "occurredAt": "2026-11-26T01:00:00Z", "certCode": "ky-so-t68-2026", "purpose": "SIGNING", "daysLeft": 30,
  "notAfter": "2026-12-26T00:00:00Z", "replacementReady": false }
```

Ví dụ EVT-14-11 (một giao dịch kết thúc; không có nội dung, chỉ băm và tham chiếu):

```json
{ "transactionCode": "T68-20261126-0000184320", "tenantId": "T68", "direction": "OUTBOUND", "serviceCode": "lltp-tra-trang-thai", "platformCode": "ndxp-t68",
  "systemCode": "DVC", "purposeCode": "GIAI_QUYET_TTHC", "procedureCode": "1.001234", "state": "SUCCEEDED", "errorCode": null, "fromCache": false,
  "stale": false, "durationMs": 842, "certCode": "ky-so-t68-2026", "payloadRef": "dh-nat-payload/T68/20261126/0000184320",
  "payloadHash": "sha256:abababababababababababababababababababababababababababababababab", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "startedAt": "2026-11-26T08:15:01Z", "finishedAt": "2026-11-26T08:15:02Z" }
```

## 5. Hợp đồng với phân hệ khác và bên ngoài

Bảng liệt kê từng cặp bên gọi và bên được gọi cùng hợp đồng. Các dòng "giả định" là phần PH-14 cần phân hệ kia xác nhận (Đề nghị đồng bộ); chúng chưa có tập API tương ứng ở thời điểm viết.

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| HTTT của tỉnh, luồng PH-04 | → PH-14 | API-14-075…078 (gọi, bất đồng bộ) | Kamelet `dh-national-invoke` là một `Processor` gọi API-14-075 qua mesh; Kamelet không biết nền tảng, token hay chữ ký; không tự thử lại (cổng thử lại theo FR-14-038) |
| PH-01 | PH-14 đọc | Bản sao HTTT (`system_replica`) qua EVT-01-*; scope `national.invoke.{nhóm}` do PH-01 cấp | Mã HTTT lấy từ `azp` |
| PH-02 | PH-14 → PH-02 | Tạo API nháp "dịch vụ quốc gia" kèm `Idempotency-Key` = `requestId` (API-14-023); lấy danh sách dịch vụ chia sẻ `PUBLISHED` để đồng bộ lên Bộ (API-14-054) | Giả định; EVT-14-14 báo cung cấp lại; PH-02 kích hoạt API-14-054 bằng `national.sync.trigger` |
| PH-03 | PH-14 → PH-03 | APISIX viết lại tuyến cung cấp lại sang API-14-075 kèm `X-DH-Service`, `X-DH-Operation`; bộ lọc vân tay mTLS cho `/inbound/v1` nạp từ EVT-14-13 | Giả định; chiều vào không qua APISIX nội bộ mà qua vùng biên |
| PH-04 | PH-14 → PH-04 | Chiều vào: gọi luồng đã phát hành theo ánh xạ điểm cuối (FR-14-041); `NationalServiceQueryApi`, `NationalHealthQueryApi` trong tiến trình (SDD §3.3) | ERR-14-039 khi luồng chưa phát hành; ERR-14-124 khi luồng lỗi |
| PH-04 | PH-04 → PH-14 | API-14-089 (quan sát chạy song song, băm kết quả), API-14-075 | Scope `national.parallel-observe` (Q14-55) |
| PH-05 | PH-14 đọc, ghi | Kết nối loại `oauth2-client`, `mtls-client` có `private_key_jwt`; ghi bí mật một chiều API-05-012, 020; thư viện `SecretVersionSelector` dùng chung | ERR-14-005 khi kết nối không phù hợp; ERR-14-034 khi chưa có bí mật ở môi trường |
| PH-06 | PH-06 → PH-14 | API-14-056 (đồng bộ dữ liệu chủ), scope `national.sync.trigger` | Đợt 3; ERR-14-125 thiếu ánh xạ |
| PH-07 | PH-07 → PH-14 | API-14-079…083 (cổng tiếp hợp `NDXP_DMDC`, ADR-057); `ifVersionNot` trả `304` | PH-07 ánh xạ lỗi sang ERR-07-028; PH-14 → PH-07 gọi `CatalogLookupApi` cho danh mục mục đích và thủ tục (giả định) |
| PH-09 | PH-14 → PH-09 | Kiểm tra mục đích trong sổ hoạt động xử lý bằng `purpose:decide` (API-09-227, đọc `ropaActivityId`); kiểm lô trước khi gửi hoặc công bố bằng `classification:check` (API-09-231) với `egressScope` là `OUT_OF_PROVINCE`; thời hạn 200 ms (chủ đầu tư chốt 27/11/2026); thư viện `dh-privacy-client` với `FailMode = PUBLIC_ONLY`; báo lượt khai thác theo lô ≤ 1.000 sự kiện qua API-09-237 (scope `privacy:decide`) | Giả định (Q14-26 của SDD); ERR-14-126, ERR-14-132; PH-14 xóa đệm quyết định theo EVT-09-07, 08, 12 |
| PH-12 | PH-14 → PH-12 | Bó OPA `national/*`; claim `acr`, `auth_time`; loại duyệt bốn mắt | Giả định |
| PH-13 | PH-14 → PH-13 | 17 sự kiện EVT-14; chỉ số `national_*`; API-14-058, 060, 073 (đọc bằng `national.health-read`) | Bản WORM 5 năm của giao dịch ở PH-13 |
| PH-01 | PH-01 → PH-14 | API-14-043 (`GET /quotas/usage`, `platformCode` tùy chọn), scope `national.health-read`, đọc một lần mỗi 3 giây cho một lượt hiển thị `remainingQuota` | PH-01 hiện `partial = true` ở API-01-026 khi PH-14 không trả lời |
| PH-16 | PH-16 → PH-14 → PH-16 | PH-14 nhận lệnh giao gói qua outbox của PH-16 (mang `submissionId`, `contentHash`, tệp gói, không mang thông tin xác thực), gửi qua nền tảng loại `REGISTRY` đã khai báo cho `channelRef` của mẫu gói (đích tạm là hệ giả lập khi trung ương chưa ban hành đặc tả), ký và giữ thông tin xác thực ở OpenBao; trả trạng thái gửi và biên nhận vào API-16-124 (`ReceiptIn`) cùng sự kiện EVT-16-12 | Gói không đổi nội dung giữa các lần gửi lại (`contentHash`); PH-14 không lưu nội dung gói quá `14.txn.payload-retention-days` |
| PH-18 | PH-14 đọc | Tham số `14.*` (đệm 30 giây), cờ bảo mật ★ | Lưu theo tenant |
| OpenBao | PH-14 đọc, ký | KV v2 (thông tin xác thực), `transit` (ký, kiểm khớp khóa), PKI mTLS nội bộ | Không qua API này; ERR-14-035 khi không khả dụng |
| Valkey | Cổng đọc, ghi | Đệm, bộ đếm hạn mức, khóa chống trùng, `SingleFlight` | ERR-14-133 khi không có kho chống trùng |
| NDXP | PH-14 ↔ NDXP | Ra: dịch vụ khai thác (OAuth 2.1, ký số tùy dịch vụ); vào: `/inbound/v1` | Đặc tả hiện hành chưa có (Q14-01, 02) |
| Hệ thống đăng ký danh mục dịch vụ của Bộ | PH-14 → Bộ | API-14-054: đăng ký, cập nhật dịch vụ chia sẻ, nhận biên nhận | Định dạng đăng ký chờ Q14-05 |
| NDOP | PH-14 → NDOP | API-14-087, 088: công bố, gỡ tập dữ liệu mở | Đặc tả chưa công bố, `specStatus = PROVISIONAL` (Q14-04) |

: Hợp đồng với phân hệ khác và bên ngoài

Dịch vụ của từng nhóm nghiệp vụ (tư pháp, bảo hiểm xã hội, ĐVQHNS, đăng ký doanh nghiệp, văn bản quy phạm pháp luật, danh mục dùng chung) không có endpoint riêng: mỗi dịch vụ là một bản ghi `serviceCode` ở API-14-011, hợp đồng (`inputSchema`, `outputSchema`) và thao tác ở API-14-019, và được gọi qua API-14-075 với `serviceCode` và `operation`. Nhờ vậy thêm một dịch vụ quốc gia mới là việc cấu hình, không phải đổi hợp đồng API.

## 6. Bảng mã lỗi ERR-14

Dải 001…099 cho mặt phẳng điều khiển, 101…199 cho mặt phẳng dữ liệu, theo cách của PH-04 và PH-05. 72 mã, trong đó 71 mã theo FRS §9.1 và **ERR-14-133** mới (503, kho chống trùng không khả dụng) thay mã tạm ERR-14-127 mà SDD §4.4 dùng cho trường hợp này (Q14-27). Cột "API phát sinh" quét từ `x-datahub-errors` của OpenAPI; mã "Chung" là mã không gắn riêng operation nào.

<!-- gen:errors:start -->
### 6.1. Lỗi mặt phẳng điều khiển (ERR-14-001…099)

Bảng dưới liệt kê các mã lỗi của mặt phẳng điều khiển, tức các API do console gọi, kèm mã HTTP, ý nghĩa và các API có thể phát sinh lỗi đó.

| Mã | HTTP | Ý nghĩa | API phát sinh (API-14-) |
|---|---|---|---|
| ERR-14-001 | 404 | Không tìm thấy đối tượng, hoặc đối tượng thuộc tenant khác (cùng thân với không tồn tại) | 003, 004, 005, 006, 007, 008, 009, 012 và 37 API khác |
| ERR-14-002 | 409 | Mã đã tồn tại, kể cả đối tượng đã ngừng dùng | 002, 011, 030 |
| ERR-14-003 | 400 | Tham số sai kiểu, sai miền, thiếu trường bắt buộc, khoảng thời gian quá rộng, thiếu lý do | 001, 002, 004, 005, 006, 007, 008, 009 và 66 API khác |
| ERR-14-004 | 409, 412 | Trạng thái hiện tại không cho phép thao tác, vượt số lần thử lại, thiếu điều kiện đóng (409); `If-Match` lệch `ETag` hiện tại (412) | 004, 005, 006, 007, 008, 009, 013, 016 và 25 API khác |
| ERR-14-005 | 422 | Kết nối PH-05 không tồn tại hoặc loại không phù hợp với cách xác thực | 002, 004 |
| ERR-14-006 | 409 | Đã có yêu cầu kích hoạt đang chờ duyệt | 008, 032 |
| ERR-14-007 | 403 | Người duyệt trùng người đề nghị hoặc người sửa gần nhất (bốn mắt) | 009, 027, 033, 090, 094 |
| ERR-14-008 | 422 | Chưa có kiểm tra kết nối đạt trong 24 giờ | 008 |
| ERR-14-009 | 422 | Dịch vụ chưa đủ điều kiện chuyển `ACTIVE` (thiếu đặc tả `ACTIVE` hoặc nền tảng chưa `ACTIVE`) | 013 |
| ERR-14-010 | 409 | Trùng số phiên bản đặc tả nhưng khác nội dung | 019 |
| ERR-14-011 | 422 | Đặc tả không đọc được, vượt giới hạn hoặc không an toàn | 019 |
| ERR-14-012 | 422 | Thay đổi phá vỡ chưa được duyệt | 016, 020 |
| ERR-14-013 | 409 | Luật định tuyến trùng điều kiện và mức ưu tiên | 025, 026 |
| ERR-14-014 | 422 | Dịch vụ đích của luật chưa hoạt động | 025 |
| ERR-14-015 | 422 | Dự phòng không hợp lệ (thao tác ghi, khác nhóm dữ liệu) | 025, 026 |
| ERR-14-016 | 422 | Thiếu căn cứ văn bản | 013, 025, 026, 042 |
| ERR-14-017 | 422 | Giới hạn hoặc chu kỳ hạn mức không hợp lệ | 042, 045 |
| ERR-14-018 | 422 | Tổng phân bổ cho HTTT vượt hạn mức | 045 |
| ERR-14-019 | 422 | Chứng thư không đọc được hoặc không thuộc chuỗi tin cậy | 030 |
| ERR-14-020 | 422 | Chứng thư không khớp khóa trong OpenBao | 030 |
| ERR-14-021 | 409 | Chứng thư chưa tới hạn hiệu lực hoặc đã hết hạn | 030, 032, 033 |
| ERR-14-022 | 409 | Chứng thư còn dùng để xác minh giao dịch, không xóa được | 092 |
| ERR-14-023 | 409 | Mã hoặc đường dẫn điểm cuối chiều vào đã dùng | 049 |
| ERR-14-024 | 422 | Danh sách nguồn được phép rỗng | 052, 090 |
| ERR-14-025 | 422 | Dịch vụ chưa đủ điều kiện cung cấp lại hoặc đường dẫn xung đột | 022, 023 |
| ERR-14-026 | 409 | Đã có phiên đồng bộ hoặc đối chiếu cùng loại đang chạy | 014, 036, 054, 056, 057, 087 |
| ERR-14-027 | 502 | PH-02, PH-04, PH-06, PH-07 hoặc PH-09 không khả dụng | 014, 023, 036, 054, 056, 079, 087, 088 |
| ERR-14-028 | 422 | Bên nhận (hệ thống của Bộ, NDOP) từ chối bản ghi | 054 |
| ERR-14-029 | 429 | Vượt số lần kiểm tra tay mỗi giờ | 040, 059 |
| ERR-14-030 | 403 | Chưa xác thực lại nhiều yếu tố để xem nội dung đầy đủ | 063, 064 |
| ERR-14-031 | 404 | Nội dung bản tin đã quá thời hạn lưu hoặc không được lưu | 062, 063, 064 |
| ERR-14-032 | 422 | Tệp nhập không hợp lệ (theo dòng, cột) | 074 |
| ERR-14-033 | 409 | Chạy song song: dịch vụ là thao tác ghi hoặc đã có phiên cho dịch vụ | 072 |
| ERR-14-034 | 422 | Thông tin xác thực chưa đặt ở môi trường đang dùng | 039, 040 |
| ERR-14-035 | 503 | OpenBao không khả dụng khi ghi, ký hoặc giải mã | 030, 039, 040, 059, 063 |
| ERR-14-036 | 422 | Giá trị tham số hoặc thời hạn đệm ngoài miền hoặc vượt trần | 013, 071 |
| ERR-14-037 | 422 | Nền tảng có dịch vụ yêu cầu ký nhưng chưa có chứng thư đang dùng đúng mục đích | 008 |
| ERR-14-038 | 422 | Cấu hình dịch vụ mâu thuẫn (mức `SENSITIVE` hoặc thao tác ghi mà bật đệm) | 011, 013 |
| ERR-14-039 | 422 | Luồng PH-04 xử lý chiều vào chưa tồn tại hoặc chưa phát hành | 049, 050 |

: Mã lỗi mặt phẳng điều khiển ERR-14

### 6.2. Lỗi mặt phẳng dữ liệu (ERR-14-101…199)

Trả cho HTTT, luồng PH-04, PH-07 qua API-14-075…083 và cho nền tảng quốc gia qua API-14-084, 085. Cột "Lớp lỗi" cho cổng và PH-04 biết có thử lại hay mở sự cố.

| Mã | HTTP | Ý nghĩa | Lớp lỗi | API phát sinh (API-14-) |
|---|---|---|---|---|
| ERR-14-133 | 503 | Kho chống trùng (Valkey) không khả dụng, từ chối thao tác ghi ra quốc gia (đề xuất, Q14-27) | Tạm thời, đóng an toàn | 075, 076 |
| ERR-14-101 | 502 | Không kết nối được nền tảng quốc gia | Tạm thời, thử lại | 075, 079 |
| ERR-14-102 | 404, 422 | Lỗi nghiệp vụ của trung ương (không tìm thấy, bị từ chối), đã che nội dung kỹ thuật | Nghiệp vụ, không thử lại | 075, 080, 081, 082 |
| ERR-14-103 | 503 | Nền tảng ngắt mạch hoặc không phản hồi, không có đệm, không có dự phòng | Tạm thời, thử lại | 075, 079 |
| ERR-14-104 | 429 | Hết hạn mức hoặc bị hoãn theo ưu tiên (`scope`, `reason`, `resetAt`) | Hoãn, không thử lại ngay | 075, 076, 079, 081 |
| ERR-14-105 | 422 | Không có luật định tuyến khớp | Cấu hình | 028, 075 |
| ERR-14-106 | 403 | HTTT không được phép gọi dịch vụ hoặc mục đích không hợp lệ | An ninh, nghiệp vụ | 075, 076 |
| ERR-14-107 | 422 | Thiếu mã hồ sơ hoặc mã thủ tục bắt buộc | Nghiệp vụ | 075, 076 |
| ERR-14-108 | 422 | Bản tin hoặc tham số không đúng lược đồ hoặc quy tắc của thao tác | Dữ liệu | 075, 076 |
| ERR-14-109 | 502 | Chữ ký phản hồi không hợp lệ (sự cố an ninh) | An ninh, mở sự cố chữ ký | 075, 084 |
| ERR-14-110 | 502 | Chứng thư của phản hồi không thuộc chuỗi tin cậy, hết hiệu lực hoặc bị thu hồi | An ninh, mở sự cố chữ ký | 075, 084 |
| ERR-14-111 | 502 | Thời điểm ký ngoài khoảng cho phép hoặc bản tin lặp | An ninh, mở sự cố chữ ký | 075, 084 |
| ERR-14-112 | 503 | Không ký được bản tin nên không gửi | Tạm thời, thử lại | 075 |
| ERR-14-113 | 503 | Chứng thư ký hết hạn hoặc bị thu hồi, nền tảng bị chặn ký | Chặn ký, cảnh báo cao nhất | 075 |
| ERR-14-114 | 502 | Nền tảng từ chối thông tin xác thực của tỉnh | Tạm thời, cảnh báo SO | 075 |
| ERR-14-115 | 504 | Quá hạn chờ phản hồi của nền tảng | Tạm thời, thử lại thao tác đọc | 075 |
| ERR-14-116 | 409 | Trùng `Idempotency-Key` nhưng khác nội dung | Nghiệp vụ | 075, 076, 082 |
| ERR-14-117 | 503 | Dịch vụ hoặc nền tảng đã ngừng hoặc đang tạm ngừng, không nhận lượt mới; nền tảng ở `SECURITY_HOLD` trả mã này kèm `reason = SECURITY_HOLD` | Nghiệp vụ | 075 |
| ERR-14-118 | 503 | Hàng chờ gửi quốc gia đầy | Tạm thời | 076 |
| ERR-14-119 | 403 | Nguồn chiều vào không được phép với dịch vụ | An ninh, cảnh báo SO | 084, 085 |
| ERR-14-120 | 401 | Chứng thư mTLS của nguồn chiều vào không hợp lệ | An ninh | 084, 085 |
| ERR-14-121 | 400 | Bản tin chiều vào sai định dạng, thiếu chữ ký hoặc loại thông báo sai | Dữ liệu | 084, 085 |
| ERR-14-122 | 409 | Bản tin chiều vào lặp hoặc nghi phát lại | An ninh, chống phát lại | 084, 085 |
| ERR-14-123 | 429 | Vượt giới hạn tần suất chiều vào | Hoãn | 084, 085 |
| ERR-14-124 | 502 | Luồng PH-04 xử lý chiều vào lỗi, quá hạn hoặc chưa nhận xử lý | Tạm thời | 084 |
| ERR-14-125 | 422 | Lô dữ liệu chủ thiếu ánh xạ ở PH-07, không gửi | Dữ liệu | 056 |
| ERR-14-126 | 403 | PH-09 chặn lô hoặc nguồn có trường không được gửi hay công bố | An ninh, nghiệp vụ | 056, 087 |
| ERR-14-127 | 500 | Lỗi nội bộ của PH-14, đã ghi nhận kèm mã truy vết | Nội bộ | 075, 076, 077, 078, 079, 080, 081, 082 và 4 API khác |
| ERR-14-128 | 502 | Phản hồi của nền tảng sai cấu trúc | Dữ liệu, cảnh báo | 075 |
| ERR-14-129 | 404 | Không tìm thấy yêu cầu bất đồng bộ | Nghiệp vụ | 077, 078 |
| ERR-14-130 | 409 | Không hủy được yêu cầu đã gửi | Nghiệp vụ | 078 |
| ERR-14-131 | 502 | Không tải được đặc tả hoặc WSDL từ xa, dùng bản đã lưu | Tạm thời, dùng bản đã lưu | 014, 019, 036 |
| ERR-14-132 | 503 | Không kiểm tra được mục đích (OPA hoặc PH-09 không khả dụng), từ chối an toàn | An ninh, đóng an toàn | 075 |

: Mã lỗi mặt phẳng dữ liệu ERR-14
<!-- gen:errors:end -->

### 6.3. Thông điệp hiển thị và trường bổ sung

Câu hiển thị cho các mã 002…039 ở FRS §9.2 (nguồn chuẩn, nhập lại ở D03-06-PH14 §5.2). Với mã 101…133, trường `detail` của phản hồi là câu cho cán bộ HTTT; câu viết sau đây tổng hợp từ các chức năng FR-14-010, 016, 023, 040, 041 và bổ sung phần còn thiếu (ghi ở Đề nghị đồng bộ để đưa vào tập màn hình). Người vận hành thấy chi tiết kỹ thuật ở UI-14-12.

| Mã | `detail` cho bên gọi | Trường bổ sung |
|---|---|---|
| ERR-14-101 | "Không kết nối được nền tảng quốc gia. Hệ thống sẽ thử lại, hãy gọi lại sau ít phút." | `transactionCode` |
| ERR-14-102 | "Nền tảng quốc gia không tìm thấy hoặc từ chối yêu cầu: {lý do đã che}." | `transactionCode`, `errors[]` |
| ERR-14-103 | "Nền tảng quốc gia tạm thời không phản hồi. Hệ thống sẽ thử lại tự động, hãy gọi lại sau ít phút." | `retryAfterSeconds` |
| ERR-14-104 | "Đã dùng hết hạn mức truy vấn {dịch vụ}. Bộ đếm đặt lại lúc {thời điểm}." | `scope` (`SYSTEM`, `SERVICE`, `PLATFORM`), `reason`, `resetAt`, `cache.available` |
| ERR-14-105 | "Chưa cấu hình đường đi cho dịch vụ {mã}. Liên hệ quản trị tỉnh để bổ sung luật định tuyến." | |
| ERR-14-106 | "HTTT {mã} không được phép gọi dịch vụ này vì mục đích đã nêu. Kiểm tra đăng ký sử dụng ở danh mục dịch vụ." | `reason` |
| ERR-14-107 | "Dịch vụ này yêu cầu mã thủ tục và mã hồ sơ. Bổ sung rồi gọi lại." | `errors[]` |
| ERR-14-108 | "Dữ liệu gửi đi không đúng mẫu của dịch vụ: {danh sách trường}." | `errors[]` |
| ERR-14-109 | "Không thể tin cậy dữ liệu nhận được. Sự cố đã được ghi nhận và báo cán bộ an toàn thông tin." | không có dữ liệu |
| ERR-14-110 | "Chứng thư của nền tảng quốc gia không đáng tin. Sự cố đã được ghi nhận." | không có dữ liệu |
| ERR-14-111 | "Bản tin nhận được có dấu hiệu cũ hoặc bị gửi lại nên bị từ chối." | không có dữ liệu |
| ERR-14-112 | "Chưa ký được bản tin nên chưa gửi. Hệ thống sẽ gửi lại khi sẵn sàng." | `retryAfterSeconds` |
| ERR-14-113 | "Chứng thư ký số đã hết hạn nên kết nối quốc gia tạm dừng. Liên hệ cán bộ an toàn thông tin." | |
| ERR-14-114 | "Nền tảng quốc gia từ chối thông tin xác thực của tỉnh. Kiểm tra với đơn vị quản lý nền tảng." | |
| ERR-14-115 | "Nền tảng quốc gia không trả lời trong {n} giây." | `transactionCode` |
| ERR-14-116 | "Khóa chống trùng đã dùng cho yêu cầu khác nội dung." | |
| ERR-14-117 | "Dịch vụ hoặc nền tảng đang ngừng hoặc tạm ngừng, chưa nhận lượt gọi mới." Khi nền tảng ở `SECURITY_HOLD`: "Nền tảng đang được giữ an ninh sau sự cố chữ ký nên chưa nhận lượt gọi mới. Liên hệ cán bộ an toàn thông tin của tỉnh." | `reason` (`SECURITY_HOLD` khi giữ an ninh) |
| ERR-14-118 | "Hàng chờ gửi quốc gia đang đầy. Thử lại sau ít phút." | `retryAfterSeconds` |
| ERR-14-119 | "Nguồn gọi không được phép với dịch vụ này." | cảnh báo SO |
| ERR-14-120 | "Chứng thư của nguồn gọi không hợp lệ." | |
| ERR-14-121 | "Bản tin không đúng định dạng hoặc thiếu chữ ký." | `errors[]` |
| ERR-14-122 | "Bản tin đã được nhận trước đó." | |
| ERR-14-123 | "Quá nhiều yêu cầu, thử lại sau." | `retryAfterSeconds` |
| ERR-14-124 | "Dịch vụ tạm thời chưa nhận xử lý." | |
| ERR-14-125 | "Lô dữ liệu chủ có trường chưa ánh xạ sang từ điển quốc gia: {danh sách}. Bổ sung ánh xạ ở phân hệ Danh mục dùng chung." | `errors[]` |
| ERR-14-126 | "Lô dữ liệu chủ chứa trường không được gửi ra ngoài tỉnh: {danh sách}. Với nguồn công bố: Nguồn chứa trường không được công bố: {danh sách}. Loại trường đó khỏi tập dữ liệu mở." | `errors[]` |
| ERR-14-127 | "Hệ thống gặp lỗi. Sự cố đã được ghi nhận, hãy báo mã truy vết {mã} cho bộ phận hỗ trợ." | `traceId` |
| ERR-14-128 | "Phản hồi từ nền tảng quốc gia không đúng cấu trúc. Sự cố đã được ghi nhận." | |
| ERR-14-129 | "Không tìm thấy yêu cầu bất đồng bộ {mã}." | |
| ERR-14-130 | "Yêu cầu đã được gửi, không hủy được. Dùng tra trạng thái để biết kết quả." | |
| ERR-14-131 | "Không tải được đặc tả từ xa. Hệ thống tiếp tục dùng bản đã lưu." | |
| ERR-14-132 | "Chưa kiểm tra được quyền khai thác nên yêu cầu bị từ chối để bảo đảm an toàn. Thử lại sau ít phút." | `retryAfterSeconds` |
| ERR-14-133 | "Kho chống trùng tạm thời không khả dụng nên không nhận thao tác ghi. Thử lại sau ít phút." | `retryAfterSeconds` |

: Thông điệp `detail` của lỗi mặt phẳng dữ liệu

`detail` không bao giờ chứa nội dung kỹ thuật của trung ương, cấu hình nội bộ hay bí mật. Lỗi 401, 403 do APISIX, Keycloak, OPA sinh theo FR-00-080: câu chung và mã truy vết.

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng OpenAPI và AsyncAPI của PH-14 được kiểm tự động trong CI, để bản đặc tả, ví dụ và mã lỗi không lệch nhau khi có thay đổi. Bảng dưới nêu từng phép kiểm, công cụ chạy và cổng CI áp dụng.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ, ví dụ khớp lược đồ, mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`; lệnh ghi có `If-Match`; `POST` chống trùng có `Idempotency-Key` | `check_contracts.py` (`openapi-spec-validator`, `jsonschema`) | CI-5 |
| Không trường bí mật, khóa riêng (`privateKey`, `clientSecret`, `password`, `secret`) ở lược đồ nào | `check_contracts.py` | CI-5 |
| Mã API 001…094 đủ, không trùng; mã lỗi tham chiếu đều có ở bảng chương 6 | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0 hợp lệ, đủ 17 EVT, ví dụ khớp | `check_contracts.py` và `@asyncapi/parser` 3 | CI-5 |
| Lint quy ước (tên `operationId`, `summary`, lỗi RFC 9457) | Spectral với bộ luật dự án | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp FRS, UC, SDD | `build/tools/kiem_tra_ma.py` | CI-1 |
| Hợp đồng nhà cung cấp, người tiêu dùng | Pact giữa `dh-runtime`, PH-04, PH-07 và `dh-integration`; giả lập NDXP bằng WireMock ở D05-02-PH14 | CI-5, RG |

: Kiểm tra hợp đồng trong CI

Kết quả ngày 26/11/2026: `check_contracts.py` ở thư mục `ph14` báo OpenAPI hợp lệ, 92 operation, 24 ví dụ khớp, 72 mã lỗi tham chiếu đều có định nghĩa, AsyncAPI 3.0 đủ 17 EVT và ví dụ khớp; Spectral với bộ luật `spectral:oas` không còn lỗi hay cảnh báo (11 cảnh báo thiếu `description` đã sửa trong bộ sinh); `@asyncapi/cli validate` (bộ phân tích AsyncAPI 3) hợp lệ, 0 lỗi, 0 cảnh báo, chỉ một thông tin gợi ý nâng lên AsyncAPI 3.1. Bộ luật Spectral riêng của dự án và oasdiff chạy ở CI-5 khi có nhánh `main` để so sánh.

## 8. Ánh xạ từ hệ cũ

Hệ cũ gọi NGSP bằng bộ điều hợp riêng trong từng ứng dụng và lưu Consumer Key, Secret dạng văn bản. PH-14 thay bằng điểm gọi chung và không di trú khóa cũ (BR-14-034).

| Hệ cũ (mã LGC, mã SRS cũ) | API mới | Ghi chú |
|---|---|---|
| LGC-NGSP-001 Tư pháp, Lý lịch tư pháp (tra danh sách, danh mục, trạng thái, nhận hồ sơ đăng ký) | API-14-075, 076; chiều vào API-14-084 nếu "nhận hồ sơ" là trung ương đẩy xuống (Q14-01) | Mỗi thao tác cũ thành một `operation` của dịch vụ nhóm `LLTP` |
| LGC-NGSP-002 Tư pháp, Hộ tịch | API-14-075, 076 | Thao tác ghi bắt buộc `Idempotency-Key`; cắt chuyển một lần, không chạy song song (Q14-11) |
| LGC-NGSP-003 Bảo hiểm xã hội | API-14-075 | Có kiểm tra mục đích; đệm 300 giây theo giả định Q14-08 |
| LGC-NGSP-004 Đồng bộ hồ sơ ĐVQHNS | API-14-075, 076, 041…045 | Thao tác nền ưu tiên `BACKGROUND` |
| LGC-NGSP-005 Đăng ký doanh nghiệp | API-14-075 | Tra theo khoảng thời gian ≤ 31 ngày |
| LGC-NGSP-006, LGC-DMDC-019 Danh mục dùng chung quốc gia | API-14-079…083 | PH-07 thay vì gọi thẳng NGSP |
| LGC-NGSP-007 Văn bản quy phạm pháp luật | API-14-075 | Dịch vụ nhóm `VBQPPL` |
| LGC-NGSP-008 Lấy token qua cổng AM bằng Consumer Key và Secret | API-14-039, 040 (xoay, thử token) và token do cổng tự lấy | Nâng cấp: `private_key_jwt`, bí mật ở OpenBao |
| SRS cũ FR-14-001, 002 (định tuyến) | API-14-024…028 | Thêm mô phỏng, bốn mắt |
| SRS cũ FR-14-006…008 (ký số, chứng thư) | API-14-029…038, 092 | Khóa ở OpenBao `transit`, bốn mắt |
| SRS cũ FR-14-009, 010 (hạn mức, đệm) | API-14-041…047 | Thêm phân bổ theo HTTT |
| SRS cũ FR-14-011 (tiếp nhận từ quốc gia) | API-14-048…052, 084, 085, 090 | Điểm cuối theo tenant |
| SRS cũ FR-14-012, 013 (đồng bộ) | API-14-053…057, 087, 088 | Mức S, Đợt 3 cho dữ liệu chủ và dữ liệu mở |
| SRS cũ FR-14-014 (giám sát) | API-14-058…060 | |
| Cấu hình dịch vụ NGSP trong các ứng dụng hệ cũ | API-14-072…074 | Chạy song song và nhập cấu hình; khóa cũ phải thu hồi khi cắt chuyển |

: Ánh xạ từ hệ cũ sang API mới

## 9. Câu hỏi mở

Câu hỏi của tập API theo dải Q14-55…59. Câu hỏi của FRS (Q14-01…14), SDD (Q14-20…27), use case (Q14-45…49) và CSDL (Q14-50…54) còn hiệu lực; ở đây chỉ nêu điều ảnh hưởng hợp đồng API.

> **Câu hỏi mở Q14-55:** API-14-089 cần một scope riêng cho luồng cắt chuyển của PH-04 gửi quan sát chạy song song. Tập này đề xuất `national.parallel-observe`; D02-08 §5 chưa có scope này, cũng chưa có dạng `national.invoke.{nhóm}` theo từng nhóm ở OpenAPI (OpenAPI dùng `national.invoke` làm khai báo chung). Cần PH-12 và PH-01 xác nhận tên và nơi cấp.

> **Câu hỏi mở Q14-56 (đã chốt ở đợt đồng bộ cuối):** `If-Match` lệch `ETag` trả HTTP 412 theo D00-04 và D04-01, giữ mã riêng ERR-14-004; ERR-14-004 vẫn trả 409 khi lỗi do trạng thái hiện tại không cho phép thao tác. `type` của RFC 9457 là `https://datahub.gov.vn/errors/ERR-14-nnn` cho mọi phân hệ.

> **Câu hỏi mở Q14-57:** API cung cấp lại do PH-02 công bố cho HTTT có hợp đồng riêng từng dịch vụ (sinh từ `contract.inputSchema`) hay dùng khung chung của API-14-075? Đề xuất tạm: hợp đồng riêng từng dịch vụ để HTTT thấy đúng tham số và trường trả về, APISIX viết lại sang khung chung kèm `X-DH-Service` và `X-DH-Operation`; cần PH-02, PH-03 xác nhận khả năng sinh và viết lại.

> **Câu hỏi mở Q14-58:** Khung `InboundEnvelope` (messageId, chữ ký, chứng thư, payload) ở API-14-084 và `NotificationRequest` ở API-14-085 là khung chuẩn hóa sau chấm dứt mTLS, chưa phải định dạng thật của trung ương (liên quan Q14-02, Q14-05, Q14-06). Khi có đặc tả thì bổ sung lược đồ theo từng dịch vụ chiều vào (`oneOf`), không đổi đường dẫn; cần đơn vị quản lý NDXP cung cấp và xác nhận cách trả lỗi.

> **Câu hỏi mở Q14-59:** Giao dịch và nhật ký khai thác dùng phân trang `page`/`size` với khoảng thời gian ≤ 31 ngày. Tỉnh vừa (GĐ-01) có khoảng 200 HTTT và hàng trăm nghìn giao dịch mỗi ngày nên trang sâu (`page` > 400) chậm. Đề xuất tạm: giới hạn `page × size` ≤ 10.000 và yêu cầu thu hẹp bộ lọc; nếu không đủ cho đối soát thì thêm phân trang con trỏ `cursor` ở `v1` (chỉ thêm tham số tùy chọn, không phá vỡ).

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục. Đường dẫn ghi đủ gốc (`/api/national/v1`, `/internal/national/v1`, `/inbound/v1`).

<!-- gen:dac-ta-api:start -->

### Nền tảng quốc gia

#### API-14-001 · Liệt kê nền tảng quốc gia

::: dac-ta
**Mục đích.** Liệt kê nền tảng quốc gia.

**Phương thức, đường dẫn.** `GET /api/national/v1/platforms`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-001.

**Tham số.** `state` (query, array, tùy chọn); `platformType` (query, array, tùy chọn); `scope` (query, PlatformScope, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm trạng thái, mức sức khỏe và `allowedActions`.
:::

#### API-14-002 · Khai báo nền tảng quốc gia

::: dac-ta
**Mục đích.** Khai báo nền tảng quốc gia.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-002.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlatformCreate`; trường bắt buộc: `platformCode`, `name`, `platformType`, `connections`, `authMode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `PlatformDetail`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`; mã lỗi của thao tác: ERR-14-002, ERR-14-003, ERR-14-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo ở `DRAFT`. Kết nối PH-05 phải là loại `oauth2-client` hoặc `mtls-client` phù hợp `authMode` (ERR-14-005). `scope = COMMON` chỉ PA.
:::

#### API-14-003 · Chi tiết nền tảng quốc gia

::: dac-ta
**Mục đích.** Chi tiết nền tảng quốc gia.

**Phương thức, đường dẫn.** `GET /api/national/v1/platforms/{platformCode}`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-001, FR-14-002.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả `ETag`. Không bao giờ trả thông tin xác thực.
:::

#### API-14-004 · Sửa nền tảng quốc gia

::: dac-ta
**Mục đích.** Sửa nền tảng quốc gia.

**Phương thức, đường dẫn.** `PATCH /api/national/v1/platforms/{platformCode}`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-002.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlatformUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-005 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nền tảng `ACTIVE` đổi kết nối thì quay về `TESTED` và phải kiểm tra lại.
:::

#### API-14-005 · Tạm ngừng nền tảng

::: dac-ta
**Mục đích.** Tạm ngừng nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}:suspend`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-003.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cổng từ chối lượt mới trong 30 giây, lượt đang chạy kết thúc (BR-14-032); phát EVT-14-01.
:::

#### API-14-006 · Tiếp tục nền tảng

::: dac-ta
**Mục đích.** Tiếp tục nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}:resume`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-003.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát EVT-14-01.
:::

#### API-14-007 · Ngừng dùng nền tảng

::: dac-ta
**Mục đích.** Ngừng dùng nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}:retire`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-003.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái cuối, mã không dùng lại. Còn dịch vụ `ACTIVE` trả ERR-14-004.
:::

#### API-14-008 · Gửi duyệt bật nền tảng

::: dac-ta
**Mục đích.** Gửi duyệt bật nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}:request-activation`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-003.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ActivationRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-006, ERR-14-008, ERR-14-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Yêu cầu có kiểm tra kết nối đạt trong 24 giờ (ERR-14-008) và, nếu nền tảng có dịch vụ cần ký, có chứng thư đang dùng đúng mục đích (ERR-14-037). Môi trường thật tạo việc cho người duyệt.
:::

#### API-14-009 · Duyệt hoặc từ chối bật nền tảng

::: dac-ta
**Mục đích.** Duyệt hoặc từ chối bật nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}:approve-activation`.

**Quyền.** `PERM-14-approve`.

**FR hiện thực.** FR-14-003.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bốn mắt: người duyệt khác người đề nghị và người sửa gần nhất (ERR-14-007). Duyệt thì `ACTIVE`, phát EVT-14-01.
:::

#### API-14-039 · Xoay vòng thông tin xác thực nền tảng

::: dac-ta
**Mục đích.** Xoay vòng thông tin xác thực nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}/credentials:rotate`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-025.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RotateCredentialRequest`; trường bắt buộc: `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `RotationStatus`; trường bắt buộc: `rotationId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`, `503`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-034, ERR-14-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Điều phối chuyển tiếp ở cổng; bí mật mới ghi ở PH-05. Kiểm tra token bằng thông tin mới trước khi chuyển; thất bại thì hủy (FR-14-025).
:::

#### API-14-040 · Thử lấy token của nền tảng

::: dac-ta
**Mục đích.** Thử lấy token của nền tảng.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}/token:test`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-024, FR-14-025.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `environment` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TokenTestResult`; trường bắt buộc: `ok`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `429`, `500`, `503`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-029, ERR-14-034, ERR-14-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lấy token ở `worker`, không lưu. Tối đa `14.test.max-per-hour` lần mỗi giờ (ERR-14-029).
:::

### Dịch vụ quốc gia

#### API-14-010 · Liệt kê, tìm dịch vụ quốc gia

::: dac-ta
**Mục đích.** Liệt kê, tìm dịch vụ quốc gia.

**Phương thức, đường dẫn.** `GET /api/national/v1/services`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-004.

**Tham số.** `q` (query, string, tùy chọn); `platformCode` (query, PlatformCode, tùy chọn); `group` (query, array, tùy chọn); `state` (query, array, tùy chọn); `reconcileLabel` (query, array, tùy chọn); `operationType` (query, OperationType, tùy chọn); `exposed` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm `facets`.
:::

#### API-14-011 · Khai báo dịch vụ quốc gia

::: dac-ta
**Mục đích.** Khai báo dịch vụ quốc gia.

**Phương thức, đường dẫn.** `POST /api/national/v1/services`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-005.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ServiceCreate`; trường bắt buộc: `serviceCode`, `name`, `platformCode`, `nationalServiceCode`, `group`, `direction`, `protocol`, `operationType`, `sensitivity`, `priority`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ServiceDetail`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`; mã lỗi của thao tác: ERR-14-002, ERR-14-003, ERR-14-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo ở `DRAFT`. Mức `SENSITIVE` hoặc `WRITE` mà bật đệm trả ERR-14-038. Chuyển `ACTIVE` khi có hợp đồng, đặc tả `ACTIVE` và nền tảng `ACTIVE` (ERR-14-009).
:::

#### API-14-012 · Chi tiết dịch vụ, hợp đồng và nhãn đối chiếu

::: dac-ta
**Mục đích.** Chi tiết dịch vụ, hợp đồng và nhãn đối chiếu.

**Phương thức, đường dẫn.** `GET /api/national/v1/services/{serviceCode}`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-006.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả hợp đồng, nhãn đối chiếu, trạng thái cung cấp lại. Có `ETag`.
:::

#### API-14-013 · Sửa dịch vụ quốc gia

::: dac-ta
**Mục đích.** Sửa dịch vụ quốc gia.

**Phương thức, đường dẫn.** `PATCH /api/national/v1/services/{serviceCode}`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-005.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ServiceUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-009, ERR-14-016, ERR-14-036, ERR-14-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giảm kiểm soát (bỏ mục đích, tăng thời hạn đệm, bật đệm) cần `basis` và người duyệt (ERR-14-016, BR-14-022). Phát EVT-14-02.
:::

#### API-14-014 · Chạy đối chiếu danh mục dịch vụ với NDXP

::: dac-ta
**Mục đích.** Chạy đối chiếu danh mục dịch vụ với NDXP.

**Phương thức, đường dẫn.** `POST /api/national/v1/service-reconciliations`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-007.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconcileRequest`; trường bắt buộc: `platformCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReconcileRun`; trường bắt buộc: `runId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `500`, `502`; mã lỗi của thao tác: ERR-14-003, ERR-14-026, ERR-14-027, ERR-14-131 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy ở `worker`, tải danh mục hiện hành của NDXP và so sánh; mỗi nền tảng một phiên cùng lúc (ERR-14-026). Theo dõi bằng API-14-015.
:::

#### API-14-015 · Kết quả một lần đối chiếu

::: dac-ta
**Mục đích.** Kết quả một lần đối chiếu.

**Phương thức, đường dẫn.** `GET /api/national/v1/service-reconciliations/{runId}`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-007.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReconcileRun`; trường bắt buộc: `runId`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mỗi mục có nhãn `STILL`, `SPEC_CHANGED`, `DISCONTINUED`, kèm danh sách thay đổi.
:::

#### API-14-016 · Áp dụng kết quả đối chiếu

::: dac-ta
**Mục đích.** Áp dụng kết quả đối chiếu.

**Phương thức, đường dẫn.** `POST /api/national/v1/service-reconciliations/{runId}:apply`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-007.

**Tham số.** `runId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReconcileApply`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReconcileRun`; trường bắt buộc: `runId`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-012 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp nhãn, tạo bản nháp đặc tả. Thay đổi phá vỡ chưa `acknowledgeBreaking` trả ERR-14-012. Phát EVT-14-02.
:::

#### API-14-017 · Đặt nhãn đối chiếu bằng tay

::: dac-ta
**Mục đích.** Đặt nhãn đối chiếu bằng tay.

**Phương thức, đường dẫn.** `POST /api/national/v1/services/{serviceCode}:set-label`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-007.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SetLabelRequest`; trường bắt buộc: `label`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đặt nhãn bằng tay khi đối chiếu tự động không dùng được; ghi lý do và kiểm toán. Nhãn `DISCONTINUED` chuyển dịch vụ sang `RETIRED` sau duyệt.
:::

#### API-14-018 · Danh sách phiên bản đặc tả của dịch vụ

::: dac-ta
**Mục đích.** Danh sách phiên bản đặc tả của dịch vụ.

**Phương thức, đường dẫn.** `GET /api/national/v1/services/{serviceCode}/specs`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-008.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceSpecList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mới nhất trước; mỗi phiên bản có `breaking`, `diffSummary`.
:::

#### API-14-019 · Nạp đặc tả dịch vụ

::: dac-ta
**Mục đích.** Nạp đặc tả dịch vụ.

**Phương thức, đường dẫn.** `POST /api/national/v1/services/{serviceCode}/specs`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-008.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SpecCreate`; trường bắt buộc: `specVersion`, `kind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ServiceSpec`; trường bắt buộc: `serviceCode`, `specVersion`, `kind`, `state`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `500`, `502`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-010, ERR-14-011, ERR-14-131 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiên bản cùng số cùng nội dung trả lại bản đã có (lũy đẳng); cùng số khác nội dung ERR-14-010. Đặc tả vượt giới hạn hoặc không an toàn (DTD, thực thể ngoài) ERR-14-011.
:::

#### API-14-020 · Kích hoạt phiên bản đặc tả

::: dac-ta
**Mục đích.** Kích hoạt phiên bản đặc tả.

**Phương thức, đường dẫn.** `POST /api/national/v1/services/{serviceCode}/specs/{specVersion}:activate`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-008.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc); `specVersion` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SpecActivate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ServiceSpec`; trường bắt buộc: `serviceCode`, `specVersion`, `kind`, `state`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-012 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiên bản `ACTIVE` bất biến; phiên bản trước thành `SUPERSEDED`. Thay đổi phá vỡ cần `acknowledgeBreaking` và tăng số chính hợp đồng.
:::

#### API-14-021 · Xem cung cấp lại của dịch vụ

::: dac-ta
**Mục đích.** Xem cung cấp lại của dịch vụ.

**Phương thức, đường dẫn.** `GET /api/national/v1/services/{serviceCode}/exposure`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-009.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Exposure`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đối tượng thuộc tenant khác trả 404 như không tồn tại (ERR-14-001).
:::

#### API-14-022 · Khai báo cung cấp lại dịch vụ

::: dac-ta
**Mục đích.** Khai báo cung cấp lại dịch vụ.

**Phương thức, đường dẫn.** `PUT /api/national/v1/services/{serviceCode}/exposure`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-009.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExposureUpdate`; trường bắt buộc: `path`, `contractVersion`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Exposure`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-025 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ dịch vụ `ACTIVE`, hướng `OUTBOUND`, đường dẫn không xung đột (ERR-14-025). Mỗi dịch vụ tối đa một cung cấp lại.
:::

#### API-14-023 · Công bố cung cấp lại lên danh mục dịch vụ PH-02

::: dac-ta
**Mục đích.** Công bố cung cấp lại lên danh mục dịch vụ PH-02.

**Phương thức, đường dẫn.** `POST /api/national/v1/services/{serviceCode}/exposure:publish`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-009.

**Tham số.** `serviceCode` (path, ServiceCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `500`, `502`; mã lỗi của thao tác: ERR-14-001, ERR-14-004, ERR-14-025, ERR-14-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lưu `requestId` rồi tạo API nháp ở PH-02 với chính `requestId` làm khóa chống trùng; PH-02 lỗi để lại `FAILED_CREATE`. Phát EVT-14-14.
:::

### Định tuyến

#### API-14-024 · Liệt kê luật định tuyến

::: dac-ta
**Mục đích.** Liệt kê luật định tuyến.

**Phương thức, đường dẫn.** `GET /api/national/v1/routing-rules`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-013.

**Tham số.** `state` (query, array, tùy chọn); `group` (query, ServiceGroup, tùy chọn); `serviceCode` (query, ServiceCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RoutingRuleList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).
:::

#### API-14-025 · Tạo luật định tuyến

::: dac-ta
**Mục đích.** Tạo luật định tuyến.

**Phương thức, đường dẫn.** `POST /api/national/v1/routing-rules`.

**Quyền.** `PERM-14-route`.

**FR hiện thực.** FR-14-013.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RoutingRuleCreate`; trường bắt buộc: `primaryServiceCode`, `priority`, `basis`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RoutingRule`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-013, ERR-14-014, ERR-14-015, ERR-14-016 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo ở `PENDING_APPROVAL` khi gửi duyệt, hoặc `DRAFT`. Dự phòng chỉ cho thao tác `READ` cùng nhóm (ERR-14-015). Trùng điều kiện và ưu tiên ERR-14-013.
:::

#### API-14-026 · Sửa luật định tuyến

::: dac-ta
**Mục đích.** Sửa luật định tuyến.

**Phương thức, đường dẫn.** `PATCH /api/national/v1/routing-rules/{ruleId}`.

**Quyền.** `PERM-14-route`.

**FR hiện thực.** FR-14-013.

**Tham số.** `ruleId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RoutingRuleUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RoutingRule`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-013, ERR-14-015, ERR-14-016 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa luật `ACTIVE` tạo bản chờ duyệt, luật cũ vẫn chạy tới khi duyệt.
:::

#### API-14-027 · Duyệt hoặc từ chối luật định tuyến

::: dac-ta
**Mục đích.** Duyệt hoặc từ chối luật định tuyến.

**Phương thức, đường dẫn.** `POST /api/national/v1/routing-rules/{ruleId}:approve`.

**Quyền.** `PERM-14-approve`.

**FR hiện thực.** FR-14-013.

**Tham số.** `ruleId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RoutingRule`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt thì `ACTIVE`, phát EVT-14-03; cổng nạp trong 30 giây.
:::

#### API-14-028 · Mô phỏng định tuyến

::: dac-ta
**Mục đích.** Mô phỏng định tuyến.

**Phương thức, đường dẫn.** `POST /api/national/v1/routing-rules:simulate`.

**Quyền.** `PERM-14-route`.

**FR hiện thực.** FR-14-012, FR-14-013.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SimulateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SimulateResult`; trường bắt buộc: `candidates`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-105 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không gọi ra quốc gia, không tiêu hạn mức, không ghi giao dịch. Luật trùng hiện `conflict = true`.
:::

### Chứng thư và sự cố chữ ký

#### API-14-029 · Liệt kê chứng thư số

::: dac-ta
**Mục đích.** Liệt kê chứng thư số.

**Phương thức, đường dẫn.** `GET /api/national/v1/certificates`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-029.

**Tham số.** `state` (query, array, tùy chọn); `purpose` (query, CertPurpose, tùy chọn); `platformCode` (query, PlatformCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CertificateList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không trả khóa; trả `daysLeft`.
:::

#### API-14-030 · Nạp chứng thư số

::: dac-ta
**Mục đích.** Nạp chứng thư số.

**Phương thức, đường dẫn.** `POST /api/national/v1/certificates`.

**Quyền.** `PERM-14-cert`.

**FR hiện thực.** FR-14-028.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CertificateUpload`; trường bắt buộc: `certCode`, `platformCode`, `purpose`, `certificatePem`, `keyRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CertificateDetail`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`, `503`; mã lỗi của thao tác: ERR-14-002, ERR-14-003, ERR-14-019, ERR-14-020, ERR-14-021, ERR-14-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần xác thực nhiều yếu tố (SEC-23). Kiểm chuỗi tin cậy (ERR-14-019), ký thử qua `worker` để khớp khóa ở OpenBao (ERR-14-020, Q14-25), còn hiệu lực (ERR-14-021). Trạng thái `UPLOADED`.
:::

#### API-14-031 · Chi tiết chứng thư số

::: dac-ta
**Mục đích.** Chi tiết chứng thư số.

**Phương thức, đường dẫn.** `GET /api/national/v1/certificates/{certCode}`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-029.

**Tham số.** `certCode` (path, CertCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CertificateDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không trả khóa; `keyRef` chỉ là tham chiếu.
:::

#### API-14-032 · Yêu cầu kích hoạt chứng thư

::: dac-ta
**Mục đích.** Yêu cầu kích hoạt chứng thư.

**Phương thức, đường dẫn.** `POST /api/national/v1/certificates/{certCode}:request-activation`.

**Quyền.** `PERM-14-cert`.

**FR hiện thực.** FR-14-028.

**Tham số.** `certCode` (path, CertCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CertActivationRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CertificateDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-006, ERR-14-021 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần xác thực nhiều yếu tố. Chuyển `PENDING_ACTIVATION` và tạo việc cho người duyệt.
:::

#### API-14-033 · Duyệt hoặc từ chối kích hoạt chứng thư

::: dac-ta
**Mục đích.** Duyệt hoặc từ chối kích hoạt chứng thư.

**Phương thức, đường dẫn.** `POST /api/national/v1/certificates/{certCode}:approve-activation`.

**Quyền.** `PERM-14-approve`.

**FR hiện thực.** FR-14-028.

**Tham số.** `certCode` (path, CertCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CertificateDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-007, ERR-14-021 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bốn mắt và xác thực nhiều yếu tố. Duyệt thì `ACTIVE`; chứng thư cũ cùng mục đích sang `SUPERSEDED` sau `14.cert.overlap-hours`. Phát EVT-14-04.
:::

#### API-14-034 · Thu hồi chứng thư số

::: dac-ta
**Mục đích.** Thu hồi chứng thư số.

**Phương thức, đường dẫn.** `POST /api/national/v1/certificates/{certCode}:revoke`.

**Quyền.** `PERM-14-cert`.

**FR hiện thực.** FR-14-029.

**Tham số.** `certCode` (path, CertCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevokeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CertificateDetail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chứng thư `REVOKED` không ký được; hết chứng thư cùng mục đích thì nền tảng bị chặn ký (ERR-14-113). Phát EVT-14-04.
:::

#### API-14-035 · Xem chuỗi tin cậy và danh sách thu hồi

::: dac-ta
**Mục đích.** Xem chuỗi tin cậy và danh sách thu hồi.

**Phương thức, đường dẫn.** `GET /api/national/v1/trust-store`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-030.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TrustStore`; trường bắt buộc: `anchors`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; chứng thư mTLS sai (ERR-14-120); `500` Lỗi nội bộ (ERR-14-127), kèm `traceId`; `detail` chung chung.

**Ghi chú.** Neo tin cậy và CRL; CRL quá `14.crl.max-age-days` hiện `STALE`.
:::

#### API-14-036 · Làm mới chuỗi tin cậy và danh sách thu hồi

::: dac-ta
**Mục đích.** Làm mới chuỗi tin cậy và danh sách thu hồi.

**Phương thức, đường dẫn.** `POST /api/national/v1/trust-store:refresh`.

**Quyền.** `PERM-14-cert`.

**FR hiện thực.** FR-14-030.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `409`, `500`, `502`; mã lỗi của thao tác: ERR-14-026, ERR-14-027, ERR-14-131 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tải chuỗi tin cậy và CRL ở `worker`. Thay đổi neo tin cậy cần duyệt bốn mắt (BR-14-022).
:::

#### API-14-037 · Liệt kê sự cố chữ ký

::: dac-ta
**Mục đích.** Liệt kê sự cố chữ ký.

**Phương thức, đường dẫn.** `GET /api/national/v1/signature-incidents`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-031.

**Tham số.** `state` (query, array, tùy chọn); `platformCode` (query, PlatformCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SignatureIncidentList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).
:::

#### API-14-038 · Xử lý sự cố chữ ký

::: dac-ta
**Mục đích.** Xử lý sự cố chữ ký.

**Phương thức, đường dẫn.** `POST /api/national/v1/signature-incidents/{incidentId}:transition`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-031.

**Tham số.** `incidentId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IncidentTransition`; trường bắt buộc: `to`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SignatureIncident`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `RELEASE_HOLD` giải trừ `securityHold` của nền tảng; chỉ SO (`PERM-14-operate` và vai trò SO).
:::

#### API-14-092 · Xóa chứng thư chưa từng kích hoạt

::: dac-ta
**Mục đích.** Xóa chứng thư chưa từng kích hoạt.

**Phương thức, đường dẫn.** `DELETE /api/national/v1/certificates/{certCode}`.

**Quyền.** `PERM-14-cert`.

**FR hiện thực.** FR-14-029.

**Tham số.** `certCode` (path, CertCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-004, ERR-14-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ xóa chứng thư `UPLOADED` chưa từng `ACTIVE`; còn giao dịch trong thời hạn lưu cần xác minh trả ERR-14-022. Chứng thư đã dùng chỉ thu hồi (API-14-034), không xóa (BR-14-019).
:::

### Hạn mức và đệm

#### API-14-041 · Liệt kê hạn mức

::: dac-ta
**Mục đích.** Liệt kê hạn mức.

**Phương thức, đường dẫn.** `GET /api/national/v1/quotas`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-032, FR-14-033.

**Tham số.** `platformCode` (query, PlatformCode, tùy chọn); `serviceCode` (query, ServiceCode, tùy chọn); `history` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tham số tùy chọn `history = true` trả thêm các phiên bản hạn mức đã bị thay thế, xếp theo `effectiveFrom` giảm dần, cho tab Lịch sử hạn mức của UI-14-09 (`CMP-VersionTimeline`).
:::

#### API-14-042 · Khai báo hạn mức do trung ương áp

::: dac-ta
**Mục đích.** Khai báo hạn mức do trung ương áp.

**Phương thức, đường dẫn.** `POST /api/national/v1/quotas`.

**Quyền.** `PERM-14-quota`.

**FR hiện thực.** FR-14-032.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `QuotaCreate`; trường bắt buộc: `platformCode`, `period`, `limit`, `basisDocument`, `effectiveFrom`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Quota`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-016, ERR-14-017 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Môi trường thật tạo yêu cầu duyệt (hộp "Việc của tôi"). Thiếu căn cứ văn bản ERR-14-016 (BR-14-011). Phát EVT-14-08.
:::

#### API-14-043 · Mức dùng hạn mức hiện tại

::: dac-ta
**Mục đích.** Mức dùng hạn mức hiện tại.

**Phương thức, đường dẫn.** `GET /api/national/v1/quotas/usage`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-033.

**Tham số.** `platformCode` (query, PlatformCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaUsage`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc từ bộ đếm ở Valkey; ngưỡng cảnh báo theo `14.quota.warn-levels`.
:::

#### API-14-044 · Liệt kê phân bổ hạn mức theo HTTT

::: dac-ta
**Mục đích.** Liệt kê phân bổ hạn mức theo HTTT.

**Phương thức, đường dẫn.** `GET /api/national/v1/quota-allocations`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-034.

**Tham số.** `serviceCode` (query, ServiceCode, tùy chọn); `period` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AllocationList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).
:::

#### API-14-045 · Đặt phân bổ hạn mức cho một HTTT

::: dac-ta
**Mục đích.** Đặt phân bổ hạn mức cho một HTTT.

**Phương thức, đường dẫn.** `PUT /api/national/v1/quota-allocations/{systemCode}`.

**Quyền.** `PERM-14-quota`.

**FR hiện thực.** FR-14-034.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AllocationPut`; trường bắt buộc: `period`, `limit`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Allocation`; trường bắt buộc: `systemCode`, `period`, `limit`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-017, ERR-14-018 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổng phân bổ cho mọi HTTT không vượt hạn mức (ERR-14-018). Dịch vụ `ESSENTIAL` được vượt trần HTTT nếu không vượt hạn mức toàn cục (Q14-24).
:::

#### API-14-046 · Thống kê đệm

::: dac-ta
**Mục đích.** Thống kê đệm.

**Phương thức, đường dẫn.** `GET /api/national/v1/cache/stats`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-035.

**Tham số.** `window` (query, string, tùy chọn); `serviceCode` (query, ServiceCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CacheStats`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).
:::

#### API-14-047 · Vô hiệu đệm

::: dac-ta
**Mục đích.** Vô hiệu đệm.

**Phương thức, đường dẫn.** `POST /api/national/v1/cache:invalidate`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-036.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CacheInvalidateRequest`; trường bắt buộc: `serviceCode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CacheInvalidateResult`; trường bắt buộc: `invalidated`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát EVT-14-09. Có `subjectKeyHash` chỉ vô hiệu một đối tượng.
:::

### Điểm cuối chiều vào

#### API-14-048 · Liệt kê điểm cuối chiều vào

::: dac-ta
**Mục đích.** Liệt kê điểm cuối chiều vào.

**Phương thức, đường dẫn.** `GET /api/national/v1/inbound-endpoints`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-039.

**Tham số.** `state` (query, array, tùy chọn); `platformCode` (query, PlatformCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboundEndpointList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).
:::

#### API-14-049 · Đăng ký điểm cuối chiều vào

::: dac-ta
**Mục đích.** Đăng ký điểm cuối chiều vào.

**Phương thức, đường dẫn.** `POST /api/national/v1/inbound-endpoints`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-039.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InboundEndpointCreate`; trường bắt buộc: `endpointCode`, `path`, `platformCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `InboundEndpoint`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-023, ERR-14-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo ở `DRAFT`. Luồng PH-04 xử lý chiều vào phải đã phát hành (ERR-14-039). Bật cần bốn mắt (BR-14-022) và xác nhận vân tay (API-14-090).
:::

#### API-14-050 · Sửa điểm cuối chiều vào

::: dac-ta
**Mục đích.** Sửa điểm cuối chiều vào.

**Phương thức, đường dẫn.** `PATCH /api/national/v1/inbound-endpoints/{endpointCode}`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-039.

**Tham số.** `endpointCode` (path, EndpointCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InboundEndpointUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboundEndpoint`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đổi ánh xạ luồng hoặc tắt; phát EVT-14-13.
:::

#### API-14-051 · Danh sách nguồn được phép

::: dac-ta
**Mục đích.** Danh sách nguồn được phép.

**Phương thức, đường dẫn.** `GET /api/national/v1/inbound-endpoints/{endpointCode}/allowed-senders`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-039.

**Tham số.** `endpointCode` (path, EndpointCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AllowedSenderList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đối tượng thuộc tenant khác trả 404 như không tồn tại (ERR-14-001).
:::

#### API-14-052 · Đặt danh sách nguồn được phép

::: dac-ta
**Mục đích.** Đặt danh sách nguồn được phép.

**Phương thức, đường dẫn.** `PUT /api/national/v1/inbound-endpoints/{endpointCode}/allowed-senders`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-039.

**Tham số.** `endpointCode` (path, EndpointCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AllowedSenderPut`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AllowedSenderList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thay toàn bộ danh sách; nguồn mới ở `PENDING_CONFIRM` tới khi SO xác nhận vân tay (API-14-090). Phát EVT-14-13.
:::

#### API-14-090 · Xác nhận vân tay chứng thư nguồn và bật điểm cuối

::: dac-ta
**Mục đích.** Xác nhận vân tay chứng thư nguồn và bật điểm cuối.

**Phương thức, đường dẫn.** `POST /api/national/v1/inbound-endpoints/{endpointCode}:confirm`.

**Quyền.** `PERM-14-cert`.

**FR hiện thực.** FR-14-039.

**Tham số.** `endpointCode` (path, EndpointCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConfirmRequest`; trường bắt buộc: `fingerprintsConfirmed`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboundEndpoint`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-007, ERR-14-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** SO xác nhận vân tay chứng thư của nguồn; điểm cuối chuyển `ACTIVE` sau duyệt bốn mắt (BR-14-022). Phát EVT-14-13 để PH-03 nạp tuyến.
:::

### Đồng bộ

#### API-14-053 · Liệt kê phiên đồng bộ

::: dac-ta
**Mục đích.** Liệt kê phiên đồng bộ.

**Phương thức, đường dẫn.** `GET /api/national/v1/sync/runs`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-043, FR-14-046.

**Tham số.** `kind` (query, array, tùy chọn); `state` (query, array, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRunList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ trả dữ liệu của tenant trong token; danh sách phân trang theo `page`, `size` (tối đa 100).
:::

#### API-14-054 · Chạy đồng bộ danh mục dịch vụ lên Bộ

::: dac-ta
**Mục đích.** Chạy đồng bộ danh mục dịch vụ lên Bộ.

**Phương thức, đường dẫn.** `POST /api/national/v1/sync/catalog-runs`.

**Quyền.** `PERM-14-sync`.

**FR hiện thực.** FR-14-043.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncCatalogRequest`; trường bắt buộc: `platformCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`, `502`; mã lỗi của thao tác: ERR-14-003, ERR-14-026, ERR-14-027, ERR-14-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đồng bộ danh mục dịch vụ lên hệ thống của Bộ; mỗi loại một phiên cùng lúc (ERR-14-026). Bên nhận từ chối từng bản ghi ghi ERR-14-028. Phát EVT-14-12.
:::

#### API-14-055 · Chi tiết một phiên đồng bộ

::: dac-ta
**Mục đích.** Chi tiết một phiên đồng bộ.

**Phương thức, đường dẫn.** `GET /api/national/v1/sync/runs/{runId}`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-043, FR-14-046.

**Tham số.** `runId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRunDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm bản ghi theo trang; không có nội dung dữ liệu.
:::

#### API-14-056 · Chạy đồng bộ dữ liệu chủ

::: dac-ta
**Mục đích.** Chạy đồng bộ dữ liệu chủ.

**Phương thức, đường dẫn.** `POST /api/national/v1/sync/master-data-runs`.

**Quyền.** `PERM-14-sync`.

**FR hiện thực.** FR-14-044.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncMasterDataRequest`; trường bắt buộc: `datasetCode`, `direction`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `500`, `502`; mã lỗi của thao tác: ERR-14-003, ERR-14-026, ERR-14-027, ERR-14-125, ERR-14-126 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 3 (PH-06). Thiếu ánh xạ ở PH-07 ERR-14-125; PH-09 chặn ERR-14-126.
:::

#### API-14-057 · Thử lại bản ghi lỗi của phiên đồng bộ

::: dac-ta
**Mục đích.** Thử lại bản ghi lỗi của phiên đồng bộ.

**Phương thức, đường dẫn.** `POST /api/national/v1/sync/runs/{runId}:retry`.

**Quyền.** `PERM-14-sync`.

**FR hiện thực.** FR-14-046.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncRetryRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ bản ghi `ERROR` hoặc `REJECTED`; tối đa `14.sync.max-retries` lần mỗi bản ghi (ERR-14-004).
:::

#### API-14-087 · Công bố tập dữ liệu mở lên NDOP

::: dac-ta
**Mục đích.** Công bố tập dữ liệu mở lên NDOP.

**Phương thức, đường dẫn.** `POST /api/national/v1/open-datasets`.

**Quyền.** `PERM-14-sync`.

**FR hiện thực.** FR-14-045.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OpenDatasetPublish`; trường bắt buộc: `datasetCode`, `platformCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `500`, `502`; mã lỗi của thao tác: ERR-14-003, ERR-14-026, ERR-14-027, ERR-14-126 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 3. Lần công bố đầu của một tập cần duyệt bốn mắt (BR-14-022). PH-09 chặn trường không được công bố (ERR-14-126).
:::

#### API-14-088 · Gỡ tập dữ liệu mở

::: dac-ta
**Mục đích.** Gỡ tập dữ liệu mở.

**Phương thức, đường dẫn.** `POST /api/national/v1/open-datasets/{datasetCode}:withdraw`.

**Quyền.** `PERM-14-sync`.

**FR hiện thực.** FR-14-045.

**Tham số.** `datasetCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `OpenDatasetWithdraw`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`, `502`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ tập đã công bố trên NDOP.
:::

### Giám sát và nhật ký khai thác

#### API-14-058 · Sức khỏe nền tảng quốc gia

::: dac-ta
**Mục đích.** Sức khỏe nền tảng quốc gia.

**Phương thức, đường dẫn.** `GET /api/national/v1/health`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-047.

**Tham số.** `platformCode` (query, PlatformCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HealthList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-13 gọi bằng token dịch vụ `national.health-read`. Có `ETag`.
:::

#### API-14-059 · Kiểm tra kết nối tay

::: dac-ta
**Mục đích.** Kiểm tra kết nối tay.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}:probe`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-047.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc); `environment` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProbeResult`; trường bắt buộc: `ok`, `steps`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `503`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-029, ERR-14-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy ở `worker`: DNS, TLS, token, gọi thăm dò, chữ ký. Không quá `14.test.max-per-hour` lần mỗi giờ (ERR-14-029).
:::

#### API-14-060 · Tổng quan kết nối quốc gia

::: dac-ta
**Mục đích.** Tổng quan kết nối quốc gia.

**Phương thức, đường dẫn.** `GET /api/national/v1/dashboard`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-048.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dashboard`; trường bắt buộc: `platforms`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; chứng thư mTLS sai (ERR-14-120); `500` Lỗi nội bộ (ERR-14-127), kèm `traceId`; `detail` chung chung.

**Ghi chú.** Một lời gọi dựng màn tổng quan (UI-14-01).
:::

#### API-14-061 · Tra cứu giao dịch quốc gia

::: dac-ta
**Mục đích.** Tra cứu giao dịch quốc gia.

**Phương thức, đường dẫn.** `GET /api/national/v1/transactions`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-049.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `serviceCode` (query, ServiceCode, tùy chọn); `state` (query, array, tùy chọn); `direction` (query, Direction, tùy chọn); `caseCode` (query, string, tùy chọn); `transactionCode` (query, string, tùy chọn); `fromCache` (query, boolean, tùy chọn); `stale` (query, boolean, tùy chọn); `asyncState` (query, array, tùy chọn); `after` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransactionPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khoảng thời gian tối đa 31 ngày (ERR-14-003). Nội dung bản tin đã che. Tham số tùy chọn `after` là con trỏ keyset theo (`started_at`, `transaction_code`): khi có `after`, `page` bị bỏ qua và phản hồi trả `nextCursor`, dùng cho khoảng thời gian lớn (Q14-59). `asyncState` lọc theo trạng thái yêu cầu bất đồng bộ (hàng chờ ở UI-14-12), `stale` lọc lượt trả dữ liệu đệm quá hạn.
:::

#### API-14-062 · Chi tiết giao dịch (nội dung đã che)

::: dac-ta
**Mục đích.** Chi tiết giao dịch (nội dung đã che).

**Phương thức, đường dẫn.** `GET /api/national/v1/transactions/{transactionCode}`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-049.

**Tham số.** `transactionCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransactionDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Siêu dữ liệu và dòng thời gian; không có nội dung (dùng API-14-063).
:::

#### API-14-063 · Xem nội dung bản tin đầy đủ có lý do

::: dac-ta
**Mục đích.** Xem nội dung bản tin đầy đủ có lý do.

**Phương thức, đường dẫn.** `POST /api/national/v1/transactions/{transactionCode}:reveal`.

**Quyền.** `PERM-14-audit-reveal`.

**FR hiện thực.** FR-14-050.

**Tham số.** `transactionCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevealRequest`; trường bắt buộc: `reason`, `part`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RevealResult`; trường bắt buộc: `transactionCode`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `500`, `503`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-030, ERR-14-031, ERR-14-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ SO, bắt buộc lý do và `acr` nhiều yếu tố trong 15 phút. Mỗi lần xem ghi vết; vượt `14.reveal.max-per-day` sinh EVT-14-16. Hết hạn lưu ERR-14-031.
:::

#### API-14-064 · Xuất bằng chứng giao dịch

::: dac-ta
**Mục đích.** Xuất bằng chứng giao dịch.

**Phương thức, đường dẫn.** `POST /api/national/v1/transactions:export-evidence`.

**Quyền.** `PERM-14-audit-reveal`.

**FR hiện thực.** FR-14-051.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportEvidenceRequest`; trường bắt buộc: `transactionCodes`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-030, ERR-14-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gói bằng chứng có chữ ký, giữ 7 ngày; giao cho AU qua kênh có kiểm soát.
:::

#### API-14-065 · Nhật ký khai thác theo HTTT

::: dac-ta
**Mục đích.** Nhật ký khai thác theo HTTT.

**Phương thức, đường dẫn.** `GET /api/national/v1/usage`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-052.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `serviceCode` (query, ServiceCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsagePage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổng hợp theo giờ từ `usage_hourly`.
:::

#### API-14-066 · Xuất báo cáo sử dụng

::: dac-ta
**Mục đích.** Xuất báo cáo sử dụng.

**Phương thức, đường dẫn.** `POST /api/national/v1/usage:export`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-052.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UsageExportRequest`; trường bắt buộc: `from`, `to`, `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** CSV UTF-8 có BOM hoặc XLSX; tạo bất đồng bộ, tải qua `statusUrl`.
:::

#### API-14-067 · Liệt kê cảnh báo bất thường khai thác

::: dac-ta
**Mục đích.** Liệt kê cảnh báo bất thường khai thác.

**Phương thức, đường dẫn.** `GET /api/national/v1/anomaly-alerts`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-053.

**Tham số.** `state` (query, array, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AnomalyAlertList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 2.
:::

#### API-14-068 · Xử lý cảnh báo bất thường

::: dac-ta
**Mục đích.** Xử lý cảnh báo bất thường.

**Phương thức, đường dẫn.** `POST /api/national/v1/anomaly-alerts/{alertId}:resolve`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-053.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AnomalyResolve`; trường bắt buộc: `decision`, `note`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AnomalyAlert`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quyết định gồm xác nhận hợp lệ, đề nghị thu hồi quyền gọi, hoặc tạm dừng dịch vụ cho HTTT (FR-14-053); ghi quyết định và kiểm toán.
:::

#### API-14-069 · Sinh báo cáo hạn mức và hiệu quả đệm

::: dac-ta
**Mục đích.** Sinh báo cáo hạn mức và hiệu quả đệm.

**Phương thức, đường dẫn.** `POST /api/national/v1/reports/quota-efficiency`.

**Quyền.** `PERM-14-audit-read`.

**FR hiện thực.** FR-14-057.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `QuotaEfficiencyRequest`; trường bắt buộc: `from`, `to`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 3.
:::

#### API-14-086 · Ép đóng hoặc mở ngắt mạch bằng tay

::: dac-ta
**Mục đích.** Ép đóng hoặc mở ngắt mạch bằng tay.

**Phương thức, đường dẫn.** `POST /api/national/v1/platforms/{platformCode}/breaker:set`.

**Quyền.** `PERM-14-operate`.

**FR hiện thực.** FR-14-038.

**Tham số.** `platformCode` (path, PlatformCode, bắt buộc).

**Thân yêu cầu.** application/json: `BreakerSetRequest`; trường bắt buộc: `mode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BreakerState`; trường bắt buộc: `platformCode`, `breaker`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ép đóng hoặc mở tay, tự hết hạn; phát EVT-14-10.
:::

### Tham số và chuyển đổi

#### API-14-070 · Xem tham số phân hệ

::: dac-ta
**Mục đích.** Xem tham số phân hệ.

**Phương thức, đường dẫn.** `GET /api/national/v1/settings`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-054.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; chứng thư mTLS sai (ERR-14-120); `500` Lỗi nội bộ (ERR-14-127), kèm `traceId`; `detail` chung chung.

**Ghi chú.** Giá trị `14.*` của tenant kèm mặc định, miền, cờ bảo mật (★).
:::

#### API-14-071 · Đặt tham số phân hệ

::: dac-ta
**Mục đích.** Đặt tham số phân hệ.

**Phương thức, đường dẫn.** `PUT /api/national/v1/settings`.

**Quyền.** `PERM-14-admin`.

**FR hiện thực.** FR-14-054.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsUpdate`; trường bắt buộc: `values`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-004, ERR-14-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ngoài miền hoặc vượt trần ERR-14-036. Tham số bảo mật (★) tạo yêu cầu duyệt bốn mắt (BR-14-022). Cổng làm mới trong 30 giây.
:::

#### API-14-072 · Tạo phiên chạy song song với hệ cũ

::: dac-ta
**Mục đích.** Tạo phiên chạy song song với hệ cũ.

**Phương thức, đường dẫn.** `POST /api/national/v1/migration/parallel-runs`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-055.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ParallelRunCreate`; trường bắt buộc: `serviceCode`, `sampleRatio`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ParallelRun`; tiêu đề `Location`, `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ dịch vụ `READ`; mỗi dịch vụ một phiên (ERR-14-033).
:::

#### API-14-073 · Kết quả phiên chạy song song

::: dac-ta
**Mục đích.** Kết quả phiên chạy song song.

**Phương thức, đường dẫn.** `GET /api/national/v1/migration/parallel-runs/{runId}`.

**Quyền.** `PERM-14-read`.

**FR hiện thực.** FR-14-055.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParallelRun`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `readyForCutover` khi đạt `14.parallel.match-ratio` liên tục `14.parallel.min-days` ngày và đủ `14.parallel.min-samples` mẫu.
:::

#### API-14-074 · Nhập cấu hình dịch vụ từ hệ cũ

::: dac-ta
**Mục đích.** Nhập cấu hình dịch vụ từ hệ cũ.

**Phương thức, đường dẫn.** `POST /api/national/v1/migration/legacy-services:import`.

**Quyền.** `PERM-14-service`.

**FR hiện thực.** FR-14-056.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegacyImportRequest`; trường bắt buộc: `sourceKind`, `content`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `LegacyImportResult`; trường bắt buộc: `jobId`, `state`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân tích cấu hình NGSP cũ; bí mật dạng rõ bị loại và báo SO. Tệp lỗi theo dòng, cột (ERR-14-032), chưa áp dụng gì.
:::

#### API-14-089 · Gửi quan sát cho phiên chạy song song

::: dac-ta
**Mục đích.** Gửi quan sát cho phiên chạy song song.

**Phương thức, đường dẫn.** `POST /api/national/v1/migration/parallel-runs/{runId}/observations`.

**Quyền.** Token dịch vụ, scope `national.parallel-observe`.

**FR hiện thực.** FR-14-055.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ParallelObservation`; trường bắt buộc: `observationId`, `newResultHash`, `legacyResultHash`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Luồng cắt chuyển của PH-04 gửi băm kết quả; không nhận dữ liệu. Lũy đẳng theo `observationId`.
:::

### Duyệt bốn mắt chung

#### API-14-093 · Liệt kê yêu cầu chờ duyệt bốn mắt của phân hệ

::: dac-ta
**Mục đích.** Liệt kê yêu cầu chờ duyệt bốn mắt của phân hệ.

**Phương thức, đường dẫn.** `GET /api/national/v1/approval-requests`.

**Quyền.** `PERM-14-approve`.

**FR hiện thực.** FR-14-003, FR-14-005, FR-14-013, FR-14-028, FR-14-030, FR-14-032, FR-14-039, FR-14-045.

**Tham số.** `type` (query, array, tùy chọn); `state` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApprovalRequestList`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `500`; mã lỗi của thao tác: ERR-14-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hộp "Việc của tôi" của UI-14-17 cho năm loại `ph14.quota-prod`, `ph14.inbound-activate`, `ph14.setting-security`, `ph14.service-relax`, `ph14.open-data-first`; chỉ trả yêu cầu của tenant trong token. Ba loại còn lại có API duyệt riêng (API-14-009, 027, 033).
:::

#### API-14-094 · Duyệt hoặc từ chối một yêu cầu chờ duyệt

::: dac-ta
**Mục đích.** Duyệt hoặc từ chối một yêu cầu chờ duyệt.

**Phương thức, đường dẫn.** `POST /api/national/v1/approval-requests/{approvalId}:decide`.

**Quyền.** `PERM-14-approve`.

**FR hiện thực.** FR-14-005, FR-14-032, FR-14-039, FR-14-045.

**Tham số.** `approvalId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ApprovalRequest`; trường bắt buộc: `approvalId`, `type`, `targetRef`, `state`, `requestedBy`, `requestedAt`, `expiresAt`, `version`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `500`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-004, ERR-14-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bốn mắt: người duyệt khác người đề nghị và người sửa gần nhất (ERR-14-007, BR-14-022). Duyệt thì áp thay đổi (hạn mức, điểm cuối chiều vào, tham số bảo mật, giảm kiểm soát dịch vụ, lần công bố dữ liệu mở đầu tiên) và phát sự kiện tương ứng; từ chối giữ cấu hình cũ. Kích hoạt điểm cuối chiều vào còn cần xác nhận vân tay (API-14-090).
:::

### Gọi dịch vụ (nội bộ)

#### API-14-075 · Gọi dịch vụ quốc gia qua điểm gọi chung

::: dac-ta
**Mục đích.** Gọi dịch vụ quốc gia qua điểm gọi chung.

**Phương thức, đường dẫn.** `POST /internal/national/v1/invocations`.

**Quyền.** Token dịch vụ, scope `national.invoke` (PERM-14-invoke).

**FR hiện thực.** FR-14-010, FR-14-017, FR-14-018, FR-14-019, FR-14-020, FR-14-021, FR-14-022.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn); `X-DH-Accept-Stale` (header, boolean, tùy chọn); `X-DH-Parallel-Run` (header, string, tùy chọn); `X-DH-On-Behalf-Of` (header, string, tùy chọn); `X-DH-Service` (header, ServiceCode, tùy chọn); `X-DH-Operation` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `InvocationRequest`; trường bắt buộc: `serviceCode`, `params`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `InvocationResult`; trường bắt buộc: `transactionCode`, `platformCode`, `meta`; tiêu đề `X-DH-Transaction`, `X-DH-Cache`; `202` đã nhận, xử lý bất đồng bộ, `AsyncAccepted`; trường bắt buộc: `requestId`, `state`, `statusUrl`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `500`, `502`, `503`, `504`; mã lỗi của thao tác: ERR-14-001, ERR-14-003, ERR-14-101, ERR-14-102, ERR-14-103, ERR-14-104, ERR-14-105, ERR-14-106, ERR-14-107, ERR-14-108, ERR-14-109, ERR-14-110, ERR-14-111, ERR-14-112, ERR-14-113, ERR-14-114, ERR-14-115, ERR-14-116, ERR-14-117, ERR-14-127, ERR-14-128, ERR-14-132, ERR-14-133 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Điểm gọi chung (chín chặng, SDD §4.4). Phản hồi kèm `X-DH-Transaction`, `X-DH-Cache` (`HIT`, `MISS`, `STALE`). Thao tác `WRITE` bắt buộc `Idempotency-Key`; cùng khóa cùng nội dung đang chạy trả `202` kèm `Retry-After`.
:::

#### API-14-076 · Gửi yêu cầu bất đồng bộ vào hàng chờ

::: dac-ta
**Mục đích.** Gửi yêu cầu bất đồng bộ vào hàng chờ.

**Phương thức, đường dẫn.** `POST /internal/national/v1/async-invocations`.

**Quyền.** Token dịch vụ, scope `national.invoke` (PERM-14-invoke).

**FR hiện thực.** FR-14-016, FR-14-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `InvocationRequest`; trường bắt buộc: `serviceCode`, `params`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `AsyncAccepted`; trường bắt buộc: `requestId`, `state`, `statusUrl`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `500`, `503`; mã lỗi của thao tác: ERR-14-003, ERR-14-104, ERR-14-106, ERR-14-107, ERR-14-108, ERR-14-116, ERR-14-118, ERR-14-127, ERR-14-133 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm tra như API-14-075 rồi ghi hàng chờ bền; trả `202` kèm `requestId`. Hàng chờ đầy ERR-14-118.
:::

#### API-14-077 · Tra kết quả yêu cầu bất đồng bộ

::: dac-ta
**Mục đích.** Tra kết quả yêu cầu bất đồng bộ.

**Phương thức, đường dẫn.** `GET /internal/national/v1/async-invocations/{requestId}`.

**Quyền.** Token dịch vụ, scope `national.invoke` (PERM-14-invoke).

**FR hiện thực.** FR-14-016.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AsyncStatus`; trường bắt buộc: `requestId`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `500`; mã lỗi của thao tác: ERR-14-127, ERR-14-129 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả lưu mã hóa tối đa 72 giờ.
:::

#### API-14-078 · Hủy yêu cầu bất đồng bộ còn trong hàng chờ

::: dac-ta
**Mục đích.** Hủy yêu cầu bất đồng bộ còn trong hàng chờ.

**Phương thức, đường dẫn.** `POST /internal/national/v1/async-invocations/{requestId}:cancel`.

**Quyền.** Token dịch vụ, scope `national.invoke` (PERM-14-invoke).

**FR hiện thực.** FR-14-016.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `AsyncCancel`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AsyncStatus`; trường bắt buộc: `requestId`, `state`.

**Lỗi.** HTTP `400`, `401`, `404`, `409`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-127, ERR-14-129, ERR-14-130 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ hủy được yêu cầu còn `QUEUED`; đã gửi trả ERR-14-130.
:::

### Cổng danh mục và cấu hình (nội bộ)

#### API-14-079 · Liệt kê danh mục dùng chung quốc gia

::: dac-ta
**Mục đích.** Liệt kê danh mục dùng chung quốc gia.

**Phương thức, đường dẫn.** `GET /internal/national/v1/national-catalogs`.

**Quyền.** Token dịch vụ, scope `national.catalog.read`.

**FR hiện thực.** FR-14-023.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalCatalogList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `429`, `500`, `502`, `503`; mã lỗi của thao tác: ERR-14-027, ERR-14-101, ERR-14-103, ERR-14-104, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ PH-07 gọi (BR-14-036). Lỗi sau thử lại được che và PH-07 ánh xạ sang ERR-07-028.
:::

#### API-14-080 · Cấu trúc một danh mục quốc gia

::: dac-ta
**Mục đích.** Cấu trúc một danh mục quốc gia.

**Phương thức, đường dẫn.** `GET /internal/national/v1/national-catalogs/{remoteCode}/structure`.

**Quyền.** Token dịch vụ, scope `national.catalog.read`.

**FR hiện thực.** FR-14-023.

**Tham số.** `remoteCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalCatalogStructure`; trường bắt buộc: `remoteCode`, `fields`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `404`, `422`, `500`; mã lỗi của thao tác: ERR-14-102, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đối tượng thuộc tenant khác trả 404 như không tồn tại (ERR-14-001).
:::

#### API-14-081 · Dữ liệu một danh mục quốc gia

::: dac-ta
**Mục đích.** Dữ liệu một danh mục quốc gia.

**Phương thức, đường dẫn.** `GET /internal/national/v1/national-catalogs/{remoteCode}/data`.

**Quyền.** Token dịch vụ, scope `national.catalog.read`.

**FR hiện thực.** FR-14-023.

**Tham số.** `remoteCode` (path, string, bắt buộc); `ifVersionNot` (query, string, tùy chọn); `page` (query, string, tùy chọn); `pageSize` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalCatalogData`; trường bắt buộc: `items`, `remoteVersion`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `400`, `401`, `404`, `422`, `429`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-102, ERR-14-104, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân trang phía nguồn (mặc định 1.000 bản ghi mỗi trang). `ifVersionNot` khớp phiên bản hiện hành thì trả `304`.
:::

#### API-14-082 · Gửi đề xuất bổ sung danh mục quốc gia

::: dac-ta
**Mục đích.** Gửi đề xuất bổ sung danh mục quốc gia.

**Phương thức, đường dẫn.** `POST /internal/national/v1/national-catalogs/{remoteCode}/proposals`.

**Quyền.** Token dịch vụ, scope `national.catalog.propose`.

**FR hiện thực.** FR-14-023.

**Tham số.** `remoteCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProposalRequest`; trường bắt buộc: `entries`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProposalStatus`; trường bắt buộc: `proposalId`, `state`.

**Lỗi.** HTTP `400`, `401`, `404`, `409`, `422`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-102, ERR-14-116, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bắt buộc `Idempotency-Key`; trả `202` kèm `proposalId`.
:::

#### API-14-083 · Trạng thái đề xuất bổ sung danh mục

::: dac-ta
**Mục đích.** Trạng thái đề xuất bổ sung danh mục.

**Phương thức, đường dẫn.** `GET /internal/national/v1/national-catalogs/{remoteCode}/proposals/{proposalId}`.

**Quyền.** Token dịch vụ, scope `national.catalog.propose`.

**FR hiện thực.** FR-14-023.

**Tham số.** `remoteCode` (path, string, bắt buộc); `proposalId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProposalStatus`; trường bắt buộc: `proposalId`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `500`; mã lỗi của thao tác: ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đối tượng thuộc tenant khác trả 404 như không tồn tại (ERR-14-001).
:::

#### API-14-091 · Ảnh chụp cấu hình không bí mật cho cổng quốc gia

::: dac-ta
**Mục đích.** Ảnh chụp cấu hình không bí mật cho cổng quốc gia.

**Phương thức, đường dẫn.** `GET /internal/national/v1/runtime-config`.

**Quyền.** Token dịch vụ, scope `national.runtime-config`.

**FR hiện thực.** FR-14-010, FR-14-012, FR-14-033.

**Tham số.** `If-None-Match` (header, string, tùy chọn); `sinceVersion` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuntimeConfig`; trường bắt buộc: `tenant`, `configVersion`, `platforms`, `services`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** HTTP `400`, `401`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `dh-runtime` của tenant gọi (hoặc nhận qua EVT-14-01, 02, 03, 04, 08, 13 rồi gọi). Có `ETag`; `If-None-Match` khớp trả `304`. Không chứa bí mật; chữ ký ảnh chụp do `dh-integration` ký.
:::

### Chiều vào (vùng biên)

#### API-14-084 · Tiếp nhận yêu cầu từ nền tảng quốc gia

::: dac-ta
**Mục đích.** Tiếp nhận yêu cầu từ nền tảng quốc gia.

**Phương thức, đường dẫn.** `POST /inbound/v1/{endpointCode}/{serviceCode}`.

**Quyền.** mTLS của nguồn được phép (chiều vào).

**FR hiện thực.** FR-14-040, FR-14-041.

**Tham số.** `endpointCode` (path, EndpointCode, bắt buộc); `serviceCode` (path, ServiceCode, bắt buộc); `X-DH-Tenant` (header, string, tùy chọn); `Service-code` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `InboundEnvelope`; trường bắt buộc: `messageId`, `payload`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InboundResponse`; trường bắt buộc: `messageId`, `transactionCode`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `500`, `502`; mã lỗi của thao tác: ERR-14-003, ERR-14-109, ERR-14-110, ERR-14-111, ERR-14-119, ERR-14-120, ERR-14-121, ERR-14-122, ERR-14-123, ERR-14-124, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Biên chấm dứt mTLS, kiểm vân tay, giới hạn tần suất; cổng xác minh chữ ký và chống phát lại trong `14.inbound.replay-window-seconds`; chuyển luồng PH-04 và trả phản hồi có ký. Cùng `messageId` gửi lại thì trả kết quả đã có.
:::

#### API-14-085 · Tiếp nhận thông báo thay đổi từ quốc gia

::: dac-ta
**Mục đích.** Tiếp nhận thông báo thay đổi từ quốc gia.

**Phương thức, đường dẫn.** `POST /inbound/v1/{endpointCode}/notifications`.

**Quyền.** mTLS của nguồn được phép (chiều vào).

**FR hiện thực.** FR-14-042.

**Tham số.** `endpointCode` (path, EndpointCode, bắt buộc); `X-DH-Tenant` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `NotificationRequest`; trường bắt buộc: `messageId`, `notificationType`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `NotificationAccepted`; trường bắt buộc: `notificationId`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `500`; mã lỗi của thao tác: ERR-14-003, ERR-14-119, ERR-14-120, ERR-14-121, ERR-14-122, ERR-14-123, ERR-14-127 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đợt 2. Ghi nhận và phát EVT-14-17; không chạy luồng.
:::

<!-- gen:dac-ta-api:end -->

## 11. Phủ chức năng

Bảng dưới đối chiếu 57 FR của FRS với API, để bảo đảm mỗi FR có ít nhất một API hoặc ghi rõ cách hiện thực. FR hiện thực bên trong cổng quốc gia (không có điểm vào riêng) được hiện thực qua đường gọi chung API-14-075 và các sự kiện, cấu hình ở chương 4.

<!-- gen:fr-cover:start -->
| FR | Chức năng | Mức, đợt | API |
|---|---|---|---|
| FR-14-001 | Liệt kê nền tảng quốc gia, trạng thái và mức sức khỏe | M, MVP | API-14-001, 003 |
| FR-14-002 | Khai báo nền tảng quốc gia và gắn kết nối PH-05 | M, MVP | API-14-002, 003, 004 |
| FR-14-003 | Bật, tạm ngừng, tiếp tục và ngừng dùng nền tảng | M, MVP | API-14-005, 006, 007, 008, 009, 093 |
| FR-14-004 | Liệt kê và tìm dịch vụ quốc gia | M, MVP | API-14-010 |
| FR-14-005 | Khai báo và sửa dịch vụ quốc gia | M, MVP | API-14-011, 013, 093, 094 |
| FR-14-006 | Xem chi tiết dịch vụ, hợp đồng và nhãn đối chiếu | M, MVP | API-14-012 |
| FR-14-007 | Đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP | M, MVP | API-14-014, 015, 016, 017 |
| FR-14-008 | Nạp đặc tả dịch vụ có phiên bản và phát hiện lệch | M, MVP | API-14-018, 019, 020 |
| FR-14-009 | Cung cấp lại dịch vụ quốc gia cho HTTT của tỉnh | M, MVP | API-14-021, 022, 023 |
| FR-14-010 | Gọi dịch vụ quốc gia qua điểm gọi chung | M, MVP | API-14-075, 091 |
| FR-14-011 | Kiểm tra mục đích khai thác và ủy quyền theo mục đích | M, MVP | Hiện thực ở chặng `purpose` của API-14-075, 076 (ERR-14-106, 107, 132); cờ `purposeRequired` khai ở API-14-011, 013 |
| FR-14-012 | Định tuyến tới nền tảng và dịch vụ đích | M, MVP | API-14-028, 091 |
| FR-14-013 | Quản lý bảng định tuyến | M, MVP | API-14-024, 025, 026, 027, 028, 093 |
| FR-14-014 | Chuyển đổi bản tin theo hợp đồng dịch vụ | M, MVP | Hiện thực ở chặng chuyển đổi bản tin trong cổng; hợp đồng và đặc tả khai ở API-14-011, 019 |
| FR-14-015 | Phân loại và chuẩn hóa lỗi từ quốc gia | M, MVP | Hiện thực ở chặng `normalize` trong cổng; lỗi trả ERR-14-102, 128 ở phản hồi API-14-075 |
| FR-14-016 | Gọi bất đồng bộ qua hàng chờ | M, MVP | API-14-076, 077, 078 |
| FR-14-017 | Bộ điều hợp tư pháp: lý lịch tư pháp | M, MVP | API-14-075 |
| FR-14-018 | Bộ điều hợp tư pháp: hộ tịch | M, MVP | API-14-075, 076 |
| FR-14-019 | Bộ điều hợp bảo hiểm xã hội | M, MVP | API-14-075 |
| FR-14-020 | Bộ điều hợp hồ sơ thủ tục cấp mã số ĐVQHNS | M, MVP | API-14-075 |
| FR-14-021 | Bộ điều hợp đăng ký doanh nghiệp | M, MVP | API-14-075 |
| FR-14-022 | Bộ điều hợp văn bản quy phạm pháp luật | M, MVP | API-14-075 |
| FR-14-023 | Cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07 | M, MVP | API-14-079, 080, 081, 082, 083 |
| FR-14-024 | Lấy và làm mới token OAuth 2.1 của nền tảng | M, MVP | API-14-040 |
| FR-14-025 | Xoay vòng và cấp lại thông tin xác thực | M, MVP | API-14-039, 040 |
| FR-14-026 | Ký số bản tin gửi đi | M, MVP | Hiện thực ở chặng gửi của API-14-075; chứng thư và khóa quản lý ở API-14-030…034, kiểm khớp khóa ở API-14-030 |
| FR-14-027 | Xác minh chữ ký phản hồi | M, MVP | Hiện thực ở chặng `verify` của API-14-075, 084; sự cố chữ ký xem ở API-14-037, 038 |
| FR-14-028 | Nạp và kích hoạt chứng thư số | M, MVP | API-14-030, 032, 033, 093 |
| FR-14-029 | Theo dõi hạn chứng thư, cảnh báo và chuyển tiếp | M, MVP | API-14-029, 031, 034, 092 |
| FR-14-030 | Cập nhật chuỗi tin cậy và danh sách thu hồi | M, MVP | API-14-035, 036, 093 |
| FR-14-031 | Xử lý sự cố chữ ký như sự cố an ninh | M, MVP | API-14-037, 038 |
| FR-14-032 | Khai báo hạn mức do trung ương áp | M, MVP | API-14-041, 042, 093, 094 |
| FR-14-033 | Đếm hạn mức, kiểm tra trước mỗi lượt gọi và cảnh báo ngưỡng | M, MVP | API-14-041, 043, 091 |
| FR-14-034 | Phân bổ hạn mức theo HTTT và ưu tiên dịch vụ thiết yếu | M, MVP | API-14-044, 045 |
| FR-14-035 | Đệm phản hồi theo loại dữ liệu | M, MVP | API-14-046 |
| FR-14-036 | Vô hiệu đệm | S, MVP | API-14-047 |
| FR-14-037 | Dùng dữ liệu đệm quá hạn có cờ | M, MVP | Dùng đệm quá hạn qua tiêu đề `X-DH-Accept-Stale` ở API-14-075; cờ `staleAllowed` khai ở API-14-011 |
| FR-14-038 | Ngắt mạch và thử lại | M, MVP | API-14-086 |
| FR-14-039 | Đăng ký điểm cuối chiều vào và nguồn được phép | M, MVP | API-14-048, 049, 050, 051, 052, 090, 093, 094 |
| FR-14-040 | Tiếp nhận yêu cầu từ nền tảng quốc gia | M, MVP | API-14-084 |
| FR-14-041 | Chuyển cho luồng PH-04 và trả phản hồi có ký | M, MVP | API-14-084 |
| FR-14-042 | Tiếp nhận thông báo thay đổi từ quốc gia | S, Đợt 2 | API-14-085 |
| FR-14-043 | Đồng bộ danh mục dịch vụ lên Bộ | M, MVP | API-14-053, 054, 055 |
| FR-14-044 | Cầu nối đồng bộ dữ liệu chủ hai chiều | S, Đợt 3 | API-14-056 |
| FR-14-045 | Công bố dữ liệu mở lên NDOP | S, Đợt 3 | API-14-087, 088, 093, 094 |
| FR-14-046 | Theo dõi trạng thái đồng bộ, xử lý lỗi và lệch | M, MVP | API-14-053, 055, 057 |
| FR-14-047 | Kiểm tra kết nối chủ động | M, MVP | API-14-058, 059 |
| FR-14-048 | Tổng quan kết nối quốc gia | M, MVP | API-14-060 |
| FR-14-049 | Tra cứu và đối soát giao dịch | M, MVP | API-14-061, 062 |
| FR-14-050 | Xem nội dung bản tin đầy đủ có lý do | M, MVP | API-14-063 |
| FR-14-051 | Xuất bằng chứng giao dịch | S, Đợt 2 | API-14-064 |
| FR-14-052 | Nhật ký khai thác theo HTTT và báo cáo sử dụng | M, MVP | API-14-065, 066 |
| FR-14-053 | Cảnh báo bất thường khai thác | S, Đợt 2 | API-14-067, 068 |
| FR-14-054 | Tham số phân hệ theo tenant | M, MVP | API-14-070, 071 |
| FR-14-055 | Chạy song song với kết nối NGSP cũ và đối chiếu | S, MVP | API-14-072, 073, 089 |
| FR-14-056 | Nhập cấu hình dịch vụ từ hệ cũ | S, MVP | API-14-074 |
| FR-14-057 | Báo cáo hạn mức và hiệu quả đệm | C, Đợt 3 | API-14-069 |

: Phủ FR bằng API
<!-- gen:fr-cover:end -->

**Quyết định đã chốt ngày 27/11/2026.** Các điểm dưới đây từng là đề nghị hoặc câu hỏi, nay chốt theo đề xuất kỹ thuật; phần việc ở tập của phân hệ khác do tập đó ghi.

- PH-02 có thêm loại API "dịch vụ quốc gia" nhận bản nháp từ PH-14 với `Idempotency-Key`, chỉ tạo `DRAFT`, sự kiện đã công bố mang `apiCode`, kèm danh sách dịch vụ chia sẻ `PUBLISHED` (API-14-023, 054).
- PH-03 có tuyến `/inbound/v1/*` ở vùng biên (mTLS, giới hạn tần suất, WAF), tuyến cung cấp lại viết sang API-14-075 kèm `X-DH-Service`, `X-DH-Operation`, và bộ lọc vân tay chứng thư nạp từ EVT-14-13 (API-14-084, 085); PH-03 ghi vào FR-03-001, 002, 038 và bảng PH-14 ở D03-04-PH03 mục 5.1.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây cần sửa ở tài liệu dùng chung hoặc tài liệu của phân hệ khác; tập này không sửa trực tiếp vì các luồng viết chạy song song. Đề nghị thực hiện trong đợt đồng bộ cuối. Không tạo ADR mới ở tập này; đề xuất ADR 075…079 đã nêu ở FRS và SDD.

| Tài liệu | Nội dung đề nghị | Lý do |
|---|---|---|
| D02-03-PH14 (FRS) §9.4 | Thêm API-14-091 (`GET /internal/national/v1/runtime-config`) và API-14-092 (`DELETE /certificates/{certCode}`); ghi đường dẫn đầy đủ gốc cho API-14-075…085; thêm ERR-14-133 vào §9.1 | Khớp hợp đồng đã chốt ở tập này; FR-14-029 có luồng xóa chứng thư nhưng chưa có API |
| D03-02-PH14 (SDD) §4.4, §8.1 | Đổi `type` của RFC 9457 từ `urn:dh:err:ERR-14-nnn` sang `https://datahub.gov.vn/errors/ERR-14-nnn`; đổi mã tạm ERR-14-127 khi Valkey không khả dụng (Q14-27) thành ERR-14-133; ghi 5 tham số bổ sung của SDD vào §9 | Q14-56, thống nhất với K-API |
| D02-08 §3.1, §5 | Thêm scope `national.parallel-observe` (Q14-55) cùng sáu scope đã đề nghị ở FRS | API-14-089 |
| D04-01 (quy ước API) | Chốt quy ước `If-Match` lệch: 409 hay 412 (Q14-56); cho phép `x-datahub-errors` trong luật Spectral | Thống nhất giữa PH |
| PH-02 (FRS, API) | API nhận bản nháp "API dịch vụ quốc gia" với `Idempotency-Key`, sự kiện đã công bố mang `apiCode`; danh sách dịch vụ chia sẻ `PUBLISHED`; trả lời Q14-57 | API-14-023, 054 |
| PH-03 (FRS, API) | Tuyến cung cấp lại viết sang API-14-075 kèm `X-DH-Service`, `X-DH-Operation`; tuyến `/inbound/v1/*` ở vùng biên với mTLS, giới hạn tần suất, WAF; bộ lọc vân tay nạp từ EVT-14-13 | API-14-084, 085, FR-14-009 |
| PH-04 (API) | Kamelet `dh-national-invoke` gọi API-14-075, gửi `X-DH-Parallel-Run` và băm trường tới API-14-089; ánh xạ chiều vào tới luồng | FR-14-010, 041, 055 |
| PH-07 (API) | `CatalogLookupApi` cho danh mục mục đích và thủ tục; xác nhận bốn thao tác gọi API-14-079…083 và ánh xạ lỗi sang ERR-07-028 | FR-14-011, 023 |
| PH-09, PH-12 (API) | PH-09: API kiểm tra mục đích và kiểm lô, thời hạn 200 ms; PH-12: bó OPA `national/*`, claim `acr` | FR-14-011, 044, 045, 050 |
| PH-13 (API, FRS) | Nhận EVT-14-01…17, chỉ số `national_*`; đọc API-14-058, 060, 073 bằng `national.health-read` | Giám sát |
| D03-06-PH14 (màn hình) | Chép bảng thông điệp mục 6.3 (mã 101…133) vào mục thông báo; câu mới cho ERR-14-133 | Lỗi mặt phẳng dữ liệu hiển thị ở UI-14-12 |
| D05-02-PH14 (kiểm thử) | Ca phối hợp theo hợp đồng này: Pact với PH-04, PH-07; WireMock giả lập NDXP; ca rò rỉ bí mật chạy trên mọi phản hồi và sự kiện | Chương 7 |

: Đề nghị đồng bộ cho tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu của tập API PH-14: 92 operation ở ba mặt phẳng, 17 sự kiện và ba chủ đề nội bộ, 72 mã lỗi, theo khuôn K-API và chuẩn trình bày K-TRINH-BAY. Giữ nguyên 90 mã API-14-001…090 do FRS đề xuất, thêm API-14-091 (cấu hình runtime, SDD) và API-14-092 (xóa chứng thư), thêm ERR-14-133. OpenAPI 3.1 và AsyncAPI 3.0 sinh từ `ph14/tools`. Có 5 câu hỏi mở (Q14-55…59) và mục Đề nghị đồng bộ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: ETag 412, cổng PH-09, PH-01, PH-16, phân trang keyset, trường bảng điều khiển, sinh lại từ OpenAPI; chốt Q448, Q415, Q416: thêm API-14-093, 094 (duyệt bốn mắt chung, 94 operation); ghi quyết định PH-02 nhận bản nháp dịch vụ quốc gia và PH-03 thêm tuyến /inbound/v1; chốt câu hỏi mở đợt đồng bộ: Q393 |
