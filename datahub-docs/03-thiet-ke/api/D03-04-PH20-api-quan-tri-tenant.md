---
ma_tai_lieu: D03-04-PH20
ten: Thiết kế giao diện lập trình Quản trị tenant và phát hành sản phẩm
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kỹ sư tích hợp các phân hệ gọi PH-20, kỹ sư console quản trị, kiểm thử viên, hội đồng thẩm định
phan_he: PH-20
mo_ta: Hợp đồng giao tiếp của phân hệ Quản trị tenant và phát hành sản phẩm gồm 171 operation REST ở ba nhóm đường dẫn nền tảng, tỉnh và nội bộ, 16 sự kiện phát và 6 sự kiện tiêu thụ, quy ước chung, bảng mã lỗi RFC 9457, sơ đồ trình tự saga, sáp nhập và báo tiến độ bất đồng bộ, ca rò rỉ chéo tenant, truy vết với FR và đề nghị đồng bộ.
tai_lieu_lien_quan: D02-03-PH20 FRS; D03-03-PH20 CSDL; D03-06-PH20 Màn hình; D03-10 Thiết kế đa tenant; D03-04-PH12; D03-04-PH13; D03-04-PH03; D03-04-PH10; D03-04-PH16; D05-02-PH20 Test case
---

# D03-04-PH20 · Thiết kế giao diện lập trình Quản trị tenant và phát hành sản phẩm

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của PH-20 Quản trị tenant và phát hành sản phẩm: nơi quản trị nền tảng khai báo và khởi tạo một tỉnh mới, đặt hạn mức, tạm ngừng, chấm dứt, sáp nhập tỉnh khi sắp xếp đơn vị hành chính, phát hành phiên bản mới theo sóng, và nơi quản trị tỉnh tự quản cài đặt, danh mục tổ chức, xem sử dụng tài nguyên. Hợp đồng chia ba nhóm đường dẫn: **134** operation ở `/api/platform/v1` (chỉ vai trò nền tảng), **27** ở `/api/tenant/v1` (tenant lấy từ token), **10** ở `/internal/tenant/v1` (phân hệ khác, mTLS và scope dịch vụ), tổng **171** operation API-20-001…171, đúng mã, phương thức, đường dẫn và quyền của FRS D02-03-PH20 mục 9.4. Kèm **16 sự kiện phát** EVT-20-01…16, **6 sự kiện tiêu thụ** và **86 mã lỗi** ERR-20 theo RFC 9457.

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:

- [`ph20/openapi-platform.yaml`](ph20/openapi-platform.yaml), [`ph20/openapi-tenant.yaml`](ph20/openapi-tenant.yaml), [`ph20/openapi-internal.yaml`](ph20/openapi-internal.yaml): OpenAPI 3.1 theo ba nhóm; [`ph20/openapi-ph20.yaml`](ph20/openapi-ph20.yaml) là bản gộp đủ 171 operation dùng để sinh chương 4. Mỗi operation có `operationId`, `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`, ví dụ yêu cầu và phản hồi khớp lược đồ theo [`check_contracts.py`](ph20/tools/check_contracts.py); Spectral (`build/tools/spectral.yaml`) không có lỗi.
- [`ph20/asyncapi-ph20.yaml`](ph20/asyncapi-ph20.yaml): AsyncAPI 3.0, 22 kênh (16 phát, 6 nhận), CloudEvents 1.0 chế độ nhị phân với tiêu đề `ce_dhtenant`, 22 ví dụ khớp payload; Spectral không có lỗi.

Sáu nguyên tắc hợp đồng:

1. **Tenant lấy từ token, không từ đường dẫn hay thân.** Riêng nhóm nền tảng, `tenantCode` ở đường dẫn là tenant bị tác động; mọi thao tác ghi của quản trị nền tảng vào tenant tỉnh bắt buộc có `reason` (từ 20 ký tự) và `ticketRef`, ghi kiểm toán vào chuỗi của tenant bị tác động (ERR-20-008).
2. **Đối tượng của tenant khác trả `404` ERR-20-002, không trả `403`,** để không lộ sự tồn tại; kiểm thử rò rỉ chéo tenant chạy hằng đêm bằng API-20-132 (chương 8).
3. **Mọi `POST` ghi có `Idempotency-Key`, mọi `PUT`, `PATCH` và hành động trên đối tượng có phiên bản có `If-Match`** (ERR-20-005, ERR-00-428); có 82 operation chống trùng và 55 operation khóa lạc quan.
4. **Tác vụ dài trả `202` và theo dõi được:** saga khởi tạo, chuyển dữ liệu sáp nhập, gói bàn giao, báo cáo sử dụng, nâng cấp theo sóng; tiến độ bước bất đồng bộ do phân hệ báo về bằng API-20-166, 167, 168 (chương 7).
5. **Thao tác không đảo ngược được cần hai quản trị nền tảng khác nhau** (chấm dứt, sáp nhập, đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng): API duyệt trả ERR-20-007 nếu người duyệt là người đề nghị.
6. **PH-20 điều phối, không tự thực thi:** hạn mức, trạng thái tạm ngừng, chuyển tiếp sáp nhập được đẩy xuống PH-03, PH-04, PH-10, PH-12 qua sự kiện và API đọc `/internal`; chuyển dữ liệu sáp nhập do PH-18 chạy theo hợp đồng `merge-transfers`.

Căn cứ: FRS D02-03-PH20 mục 9 và Phụ lục A, CSDL D03-03-PH20 (schema `ph20_tenant`, tên trường dạng camelCase ở API), D03-10 mục 5. Mọi tên miền, mã tenant (`T68`, `T90`, `T91`), dữ liệu trong ví dụ là giả lập. Các giả định ghi rõ ở từng mục và tổng hợp ở Phụ lục A.

## 1. Giới thiệu

### 1.1. Mục đích

Tài liệu đặc tả mặt giao tiếp của PH-20 đủ để kỹ sư `dh-platform` hiện thực module `tenant` và `release`, kỹ sư console hiện thực màn UI-20-01…22, kỹ sư các phân hệ PH-01, 03, 04, 06, 07, 09, 10, 12, 13, 16, 18, 19 tích hợp (nghe sự kiện, đọc registry, báo tiến độ), và kiểm thử viên viết ca kiểm thử hợp đồng cùng ca rò rỉ chéo tenant.

### 1.2. Phạm vi

Gồm API REST của ba nhóm, sự kiện Kafka phát và nhận, quyền, scope máy, mã lỗi, sơ đồ trình tự. Không gồm: hành vi nghiệp vụ chi tiết (FRS D02-03-PH20), cấu trúc bảng (D03-03-PH20), màn hình (D03-06-PH20), API của phân hệ khác mà PH-20 gọi ra (nằm ở tập API của phân hệ đó, tổng hợp ở mục 2.10), cơ chế thực thi hạn mức ở APISIX (PH-03), tham số `20.*` do PH-18 sở hữu (PH-20 chỉ đọc giá trị hiệu lực ở API-20-131).

### 1.3. Đối tượng sử dụng và cách đọc

| Người đọc | Đọc mục | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, 2.1 đến 2.4, 8, Phụ lục A | Nắm nguyên tắc tách tenant, bốn mắt, lũy đẳng, các điểm lệch với FRS |
| Kỹ sư `dh-platform` | 2, 3, 4, 6 | Hiện thực operation, mã lỗi, khóa lạc quan, chống trùng |
| Kỹ sư console quản trị | 2.4, 3, 4, 7.2 | Gọi API, theo dõi saga bằng SSE, xử lý `202` |
| Kỹ sư phân hệ khác | 2.10, 5, 7.2, 4 (nhóm `/internal`) | Nghe sự kiện, đọc registry và tổ chức, báo tiến độ bước saga |
| Kiểm thử viên | 4, 6, 8, 9 | Ca hợp đồng, ca lỗi, ca rò rỉ chéo tenant, ma trận FR và API |

: Người đọc và mục nên đọc

### 1.4. Thuật ngữ và chữ viết tắt

| Thuật ngữ | Giải thích |
|---|---|
| Tenant (`tenantCode`) | Một tỉnh dùng Datahub, mã dạng `T68`; hai tenant đặc biệt `PLATFORM` và `COMMON` được bảo vệ khỏi mọi thao tác vòng đời (ERR-20-010) |
| Saga khởi tạo (`runId`) | Lần chạy 17 bước `S01_RECORD` … `S17_ACTIVATE` tạo mọi tài nguyên của một tenant; mỗi bước lũy đẳng với `{runId}:{stepCode}`, có bù trừ |
| Bước bất đồng bộ | Bước do phân hệ khác thực hiện (`S06`, `S09`, `S10`, `S12`, `S15`); PH-20 phát sự kiện rồi chờ phân hệ báo qua API-20-166, quá `20.provision.step-timeout-minutes` thì `FAILED` (ERR-20-106) |
| Đề nghị có duyệt | Đối tượng `LifecycleRequest` hoặc `QuotaChangeRequest` đi qua `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, thực hiện; người duyệt khác người đề nghị (bốn mắt) |
| Kế hoạch sáp nhập (`mergePlanId`) | Mã dạng `SN-2026-001` gom tenant nguồn, tenant đích, bảng ánh xạ, chạy thử, chuyển dữ liệu theo phân hệ, cutover, chuyển tiếp |
| Bên tham gia sáp nhập | Phân hệ có dữ liệu theo tenant, cung cấp xuất, nhập, kiểm đếm theo gói; PH-18 chạy công cụ chuyển, PH-20 điều phối (ADR 202 đề xuất) |
| Cutover và chuyển tiếp | Tenant nguồn sang `MERGED` chỉ đọc, lượt gọi cũ được APISIX chuyển sang tenant đích kèm tiêu đề `Deprecation` và `Sunset` trong thời gian chuyển tiếp |
| Kênh phát hành | `STABLE` và `PREVIEW`; bản `STABLE` chỉ nhận sau ít nhất `20.release.stable-soak-days` ngày chạy ở tenant thí điểm |
| Sóng nâng cấp | Nhóm tenant nâng cấp cùng lúc, cách nhau `soakHours`, trong cửa sổ bảo trì của từng tỉnh, tự dừng khi tỷ lệ lỗi vượt `20.release.wave-error-threshold-percent` |
| Kho `dh-tenant-config` | Kho Git GitOps giữ cấu hình tenant làm trạng thái mong muốn, mỗi tenant một thư mục; Argo CD áp (ADR 201 đề xuất) |
| `ce_dhtenant` | Thuộc tính mở rộng CloudEvents `dhtenant` mang mã tenant bị tác động, đặt ở tiêu đề Kafka |
| PA, PO, PAU, TA, TO, SO, AU, DS, VW | Vai trò theo D02-08: quản trị, vận hành, kiểm toán nền tảng; quản trị, vận hành tỉnh, cán bộ an toàn thông tin, kiểm toán viên, cán bộ dữ liệu, người xem |

: Thuật ngữ và chữ viết tắt của tập API PH-20

### 1.5. Tài liệu tham chiếu

FRS D02-03-PH20 (nguồn chuẩn mã FR, ERR, EVT, PERM, liệt kê ở Phụ lục A, danh mục API ở mục 9.4, tham số ở mục 8.2); CSDL D03-03-PH20 (`ph20_tenant.sql`, tên cột chuyển sang camelCase ở API); D03-10 Thiết kế đa tenant (mục 5 vòng đời tenant, saga); D02-08 (ma trận quyền, vai trò); D00-04 (sổ tra cứu gọn, khuôn lỗi); D03-04-PH16 (mẫu tập API); D03-04-PH12, PH13, PH07, PH10, PH03, PH16, PH18 (API mà PH-20 gọi hoặc nghe). Không có SRS cũ cho PH-20 (REQ-20 là năng lực mới).

### 1.6. Cấu trúc tài liệu

Chương 2 nêu nguyên tắc chung (đường dẫn, xác thực, tenant, lỗi, lũy đẳng, phiên bản, phân trang, giới hạn tốc độ). Chương 3 là bảng tổng hợp 171 API. Chương 4 là đặc tả từng endpoint, sinh tự động từ OpenAPI. Chương 5 là sự kiện. Chương 6 là bảng mã lỗi. Chương 7 là sơ đồ trình tự saga, báo tiến độ bất đồng bộ, sáp nhập. Chương 8 là ca rò rỉ chéo tenant. Chương 9 truy vết API và FR. Chương 10 là câu hỏi mở Q20-55…59. Phụ lục A là đề nghị đồng bộ.

## 2. Nguyên tắc chung

### 2.1. Ba nhóm đường dẫn

Ba nhóm khác nhau về người gọi, cách xác thực, nơi truy cập và phạm vi tenant; không có đường dẫn dùng chung giữa các nhóm.

| Nhóm | Gốc đường dẫn | Số operation | Người gọi | Xác thực | Phạm vi tenant | Nơi truy cập |
|---|---|---|---|---|---|---|
| Nền tảng | `/api/platform/v1` | 134 | PA, PO, PAU ở tenant `PLATFORM`; tài khoản dịch vụ của nền tảng | OIDC (WebAuthn bắt buộc với vai trò nền tảng), quyền `PERM-20-*` | Tenant bị tác động nêu ở `{tenantCode}`; mọi thao tác ghi cần `reason`, `ticketRef` | Console nền tảng qua BFF, không mở ra cổng công khai |
| Tỉnh tự quản | `/api/tenant/v1` | 27 | TA, TO, SO, AU, DS, VW của tỉnh | OIDC realm của tỉnh, quyền `PERM-20-*` | Lấy từ claim `tenant` của token, không có `tenantCode` ở đường dẫn hay thân | Console của tỉnh qua BFF |
| Nội bộ | `/internal/tenant/v1` | 10 | Phân hệ khác (PH-01, 03, 04, 06, 07, 08, 10, 12, 16, 18, 19…), APISIX plugin | OAuth 2.1 client credentials, mTLS trong mesh, scope `tenant:*` | Registry theo `tenantCode` ở đường dẫn, tổ chức theo tenant ngữ cảnh của thông tin xác thực | Chỉ trong mesh `dh-control` (Z3), không qua cổng công khai |

: Ba nhóm đường dẫn của PH-20

Hành động trên tài nguyên dùng hậu tố `:{hành-động}` (ví dụ `:approve`, `:check-readiness`, `:report`), theo quy ước chung của các tập API. Đường dẫn dùng tiếng Anh không dấu dạng `kebab-case`; tên trường dùng `camelCase`; giá trị liệt kê dùng `UPPER_SNAKE_CASE` theo Phụ lục A của FRS.

### 2.2. Xác thực và phân quyền

Người dùng đăng nhập OIDC với PKCE qua BFF của console, token không ra trình duyệt; vai trò nền tảng bắt buộc WebAuthn. Máy gọi máy dùng OAuth 2.1 `client_credentials` kèm mTLS, token Keycloak của realm `dh-platform` (ADR-006). Máy chủ kiểm quyền theo từng yêu cầu, không tin lời khai của giao diện.

| Quyền | Vai trò | Số operation | Operation (số API-20-) |
|---|---|---|---|
| `PERM-20-read` | PA, PO, PAU; TA, AU chỉ phần của tỉnh mình | 48 | 001, 003, 007, 010, 014…016, 024, 025, 027, 029, 035, 039, 041, 042, 044, 048, 051, 056…058, 060…064, 069, 072…074, 081, 082, 085, 087, 088, 094, 099, 101, 105, 109, 111, 119, 126, 129…131, 133, 134 |
| `PERM-20-admin` | PA | 20 | 004, 008, 009, 011, 012, 026, 028, 030…032, 040, 043, 045, 046, 065…068, 070, 132 |
| `PERM-20-provision` | PA | 16 | 002, 005, 006, 013, 017…023, 033, 034, 036…038 |
| `PERM-20-lifecycle` | PA | 8 | 047, 071, 075, 078…080, 083, 084 |
| `PERM-20-approve` | PA (không tự duyệt) | 6 | 052, 053, 076, 077, 091, 092 |
| `PERM-20-quota` | PA | 5 | 049, 050, 054, 055, 059 |
| `PERM-20-merge` | PA | 15 | 086, 089, 090, 093, 095…098, 100, 102…104, 106…108 |
| `PERM-20-release` | PA; PO chỉ theo dõi và dừng sóng | 16 | 110, 112…118, 120…125, 127, 128 |
| `PERM-20-settings` | TA | 5 | 136…139, 160 |
| `PERM-20-org` | TA | 12 | 144, 146…150, 152…155, 157, 158 |
| `PERM-20-org-read` | Mọi vai trò tỉnh, PA, PO, PAU | 6 | 135, 143, 145, 151, 156, 159 |
| `PERM-20-usage-read` | TA, TO, AU | 2 | 140, 141 |

: Quyền người dùng và operation tương ứng

D02-08 hiện có `PERM-20-admin` và `PERM-20-read`; mười quyền còn lại là đề nghị của FRS (Phụ lục A). Operation `API-20-142` cho mọi người dùng đã đăng nhập; `API-20-161` cho TA và AU của tỉnh; `API-20-137`, `API-20-139` cho TA ghi và SO, AU đọc (xem Phụ lục A về quyền đọc của SO, AU).

| Scope máy | Bên giữ | Operation | Ghi chú |
|---|---|---|---|
| `tenant:registry-read` | Mọi DU, plugin APISIX của PH-03, PH-12, tác vụ nền | 162…165 | Registry, cấu hình thực thi, chính sách liên tenant; đệm tối đa `20.registry.cache-seconds` |
| `tenant:org-read` | PH-01, 06, 07, 08, 12, 16 | 169…171 | Chỉ tổ chức của tenant trong thông tin xác thực máy |
| `tenant:provision-report` | Phân hệ tham gia saga, PH-18, phân hệ xuất gói | 166…168 | Báo tiến độ bước saga, chuyển sáp nhập, xuất gói; chỉ bên thực hiện của bước (ERR-20-104) |

: Scope máy do PH-20 cấp cho phân hệ khác

Scope PH-20 dùng khi gọi ra: `iam:realm-provision` (PH-12), `obs:tenant-provision` (PH-13), `platform.tenant.provision` (PH-07, giả định của PH-07), `event:topic-register` (PH-10), `kpi.ingest` (PH-16); chi tiết ở mục 2.10.

### 2.3. Tenant từ token và tách nhiệm vụ

| Quy tắc | Nội dung | Mã lỗi khi vi phạm |
|---|---|---|
| Tenant từ token | Nhóm `/api/tenant/v1` và tổ chức nội bộ lấy tenant từ claim `tenant` hoặc thông tin xác thực máy; thân yêu cầu có `tenantCode` khác tenant của token bị bỏ qua và ghi cảnh báo | Không có (bỏ qua) |
| Đối tượng của tenant khác | Đối tượng không thuộc tenant của người gọi trả `404`, không phân biệt với đối tượng không tồn tại | ERR-20-002 |
| Vai trò sai nhóm | Token không thuộc tenant `PLATFORM` (TA, TO…) gọi `/api/platform/v1` trả `403`, vì đường dẫn nền tảng không phải tài nguyên của một tỉnh nên không có gì để che; PA gọi `/api/tenant/v1` để ghi dữ liệu của tỉnh cũng bị chặn ở lớp xác thực. Tài nguyên của tenant khác ở `/api/tenant/v1` và `/internal/tenant/v1` trả `404` | ERR-00-403 (nhóm nền tảng), ERR-20-002 (tài nguyên tenant khác) |
| Tenant đặc biệt | `PLATFORM`, `COMMON` không đổi trạng thái, không chấm dứt, không sáp nhập | ERR-20-010 |
| Lý do và mã phiếu | Mọi thao tác ghi của PA vào tenant tỉnh có `reason` từ `20.lifecycle.reason-min-length` ký tự và `ticketRef`; ghi kiểm toán vào chuỗi của tenant bị tác động (SEC-85) | ERR-20-008 |
| Bốn mắt | Người lập, gửi đề nghị chấm dứt, kế hoạch sáp nhập, đổi chế độ cách ly, hạ hạn mức khác người duyệt; người duyệt chấm dứt khác người xác nhận bàn giao | ERR-20-007 |
| Tenant tạm ngừng | Nhóm `/api/tenant/v1` trả `403` khi tenant `SUSPENDED`, trừ `API-20-142` (trả `readOnly`, `banner`); data plane và control plane thực thi (FR-20-066) | ERR-20-001 |
| Tenant `MERGED` | Tenant nguồn sau cutover chỉ đọc, ghi trả `409` | ERR-20-115 |

: Quy tắc tenant và tách nhiệm vụ áp dụng cho mọi operation

### 2.4. Quy ước yêu cầu và phản hồi

| Mục | Quy ước |
|---|---|
| Định dạng | JSON UTF-8 (`application/json`); lỗi `application/problem+json`; tệp xuất `XLSX`, `CSV`, `PDF`; luồng tiến độ `text/event-stream`; tải lên `multipart/form-data` (API-20-153) |
| Thời gian, số | Thời điểm ISO 8601 có múi giờ (`+07:00`); ngày `YYYY-MM-DD`; kỳ báo cáo `M-2026-10`, `Q-2026-Q3`, `Y-2026`; số thập phân dùng dấu chấm, không bao quanh bằng nháy |
| Khóa lạc quan | `GET` đối tượng có phiên bản trả `ETag: W/"{n}"`; `PUT`, `PATCH` và hành động có `M` ở chương 3 cần `If-Match`; lệch trả `412` ERR-20-005, thiếu trả `428` ERR-00-428. Hành động không đổi trạng thái đối tượng (kiểm tra sẵn sàng, xem trước, báo tiến độ, tra hàng loạt) không có `If-Match` |
| Chống trùng | `POST` có `I` ở chương 3 (82 operation) bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ, so băm SHA-256 thân yêu cầu; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-20-009. Năm `POST` chỉ đọc (API-20-005, 006, 033, 095, 171) không cần khóa |
| Phân trang | Danh sách có `page` (từ 0) và `size` (1…200, mặc định 20; API-20-162 và API-20-169 tối đa 1.000); phản hồi `items`, `page`, `size`, `totalElements`; sắp xếp bằng `sort` nơi FRS nêu |
| Tác vụ dài | Trả `202` kèm `Location` tới tài nguyên theo dõi (lần chạy, gói bàn giao, báo cáo, kế hoạch); trạng thái đọc bằng `GET`, tiến độ saga thời gian thực bằng SSE (API-20-016) |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên hoặc tập; hành động đổi trạng thái trả đối tượng mới kèm `ETag` mới |
| Tệp | Tải xuống API-20-062, 156 trả tệp trực tiếp kèm `Content-Disposition`; liên kết gói bàn giao hết hạn trả `410` ERR-20-039. Nhập tổ chức tối đa 10 MB và `20.org.import-max-rows` dòng |
| Truy vết | `traceparent` W3C xuyên APISIX, BFF, `dh-platform`, Kafka; mọi phản hồi lỗi có `traceId` |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho thông điệp lỗi; mã lỗi không đổi theo ngôn ngữ |
| Tham số đường dẫn | Các `{…}` ở đường dẫn là bắt buộc; `{tenantCode}` theo `^T[0-9]{2}$`, `{moduleCode}` và `{module}` theo `^PH-[0-9]{2}$`, `{mergePlanId}` dạng `SN-2026-001`, các `{…Id}` là UUID; chương 4 không lặp lại |

: Quy ước chung của API PH-20

### 2.5. Lỗi RFC 9457

Mọi lỗi trả `application/problem+json` theo RFC 9457 và D00-04, với `type` là `https://datahub.example.vn/errors/{code}`, `code` dạng `ERR-20-nnn`, `traceId`, và `errors[]` theo trường khi lỗi dữ liệu. Thiếu xác thực, thiếu quyền chức năng, thiếu `If-Match` dùng mã chung ERR-00-401, ERR-00-403, ERR-00-428. Bảng đầy đủ 86 mã ở chương 6.

```http
HTTP/1.1 409 Conflict
Content-Type: application/problem+json

{"type": "https://datahub.example.vn/errors/ERR-20-011", "title": "ĐVHC đã có tenant", "status": 409,
 "code": "ERR-20-011", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "detail": "Đơn vị hành chính Lâm Viên đã có tenant T68 đang sử dụng.", "instance": "/api/platform/v1/tenants",
 "errors": [{"field": "adminUnitId", "message": "Đơn vị hành chính Lâm Viên đã có tenant T68 đang sử dụng.", "code": "ERR-20-011"}]}
```

Ví dụ lỗi khai báo tenant trùng đơn vị hành chính. Ba nhóm lỗi hay gặp: `422` do quy tắc nghiệp vụ (ERR-20-008, 013, 017, 029, 030), `409` do trạng thái hoặc trùng (ERR-20-003, 006, 011, 016, 067), `503` do phụ thuộc không khả dụng (ERR-20-062). Lỗi không có mã HTTP (ERR-20-106…113, 116, 117) chỉ ghi ở bước saga, lần chạy hoặc cảnh báo, không bao giờ nằm ở phản hồi của operation.

### 2.6. Lũy đẳng

`Idempotency-Key` là UUID do máy khách sinh, một khóa cho một ý định. Máy chủ lưu khóa theo cặp (client, phương thức, đường dẫn) trong bảng `idempotency_key` 24 giờ; cùng khóa cùng thân trả lại phản hồi đầu kể cả khi đang `IN_PROGRESS` (máy chủ chờ tối đa 30 giây rồi trả `409`), khác thân trả `409` ERR-20-009. Với saga, mỗi bước còn có khóa riêng `{runId}:{stepCode}` khi PH-20 gọi phân hệ khác, để thử lại không tạo tài nguyên đôi. Khi PA chọn "Lưu và khởi tạo", console gọi API-20-002 rồi API-20-013 với cùng khóa hậu tố `:run`. Máy khách nên giữ khóa và gửi lại khi mất phản hồi mạng.

### 2.7. Phiên bản API

Phiên bản `v1` ở đường dẫn; thay đổi phá vỡ (xóa trường, đổi nghĩa, đổi kiểu) sang `v2`, chạy song song tối thiểu 6 tháng, oasdiff ở CI chặn thay đổi phá vỡ trong `v1`. Thêm trường tùy chọn, thêm giá trị liệt kê ở phản hồi, thêm operation là tương thích; bên gọi phải bỏ qua trường lạ. Sự kiện `v1` tương thích BACKWARD ở Apicurio. Phiên bản sản phẩm Datahub (`releaseVersion` SemVer) độc lập với phiên bản API.

### 2.8. Phân trang, lọc, sắp xếp

Mọi `GET` danh sách nhận `page`, `size` và các bộ lọc nêu ở chương 4; bộ lọc mảng lặp tham số (`status=ACTIVE&status=SUSPENDED`). Danh sách tenant trả thêm `facets`, danh mục tổ chức trả thêm `tree` khi `view = TREE`, bảng ánh xạ trả thêm `summary`. Khoảng thời gian có giới hạn: sử dụng tối đa 400 ngày, kiểm toán và nhật ký liên tenant tối đa 366 ngày (ERR-20-032, 400). Xuất CSV danh sách tenant tối đa 1.000 dòng.

### 2.9. Giới hạn tốc độ

Giới hạn do APISIX (PH-03) thực thi, trả `429` kèm `Retry-After` và `RateLimit-Remaining`, không dùng mã ERR-20. Con số dưới đây là **giả định** theo quy mô mục tiêu 34 tenant (NFR-00-060) và tỉnh quy mô vừa 200 HTTT (GĐ-01…07), chờ chốt ở Q20-55.

| Nhóm | Giới hạn đề xuất | Cơ sở giả định |
|---|---|---|
| `/api/platform/v1` | 300 yêu cầu mỗi phút mỗi tài khoản, ghi 60 mỗi phút; tối đa 5 luồng SSE mỗi người dùng | Một đội quản trị dưới 10 người, thao tác tay là chính |
| `/api/tenant/v1` | 600 yêu cầu mỗi phút mỗi tenant và 120 mỗi phút mỗi người dùng; nhập tổ chức 6 lần mỗi phút | Một tỉnh khoảng 200 người dùng quản trị, danh mục tổ chức dưới 5.000 dòng |
| `/internal/tenant/v1` | 3.000 yêu cầu mỗi phút mỗi client; tra hàng loạt (API-20-171) 60 mỗi phút | Phân hệ đọc có đệm `20.registry.cache-seconds` = 60, mỗi tenant khoảng vài chục lượt đọc mỗi phút |

: Giới hạn tốc độ đề xuất của PH-20

### 2.10. Lời gọi ra phân hệ khác

Hợp đồng của phía bị gọi nằm ở tập API của phân hệ đó; PH-20 chỉ dựa vào các mã sau. Mỗi lời gọi mang `Idempotency-Key` bằng `{runId}:{stepCode}` (saga) hoặc `{mergePlanId}:{module}` (sáp nhập).

| Phân hệ | Lời gọi | Scope hoặc kênh | Dùng ở |
|---|---|---|---|
| PH-12 | API-12-080 tạo realm, client, vai trò; API-12-084, 085 tạm ngừng, khôi phục realm; API-12-045, 046 kế hoạch và thực hiện chuyển định danh | `iam:realm-provision` | `S03_REALM`, API-20-079, API-20-104 |
| PH-13 | API-13-072 `POST /api/platform/v1/tenants/{tenantCode}/observability:provision`; API-13-073 đóng chuỗi kiểm toán | `obs:tenant-provision` | `S08_OBSERVABILITY`, bù trừ |
| PH-07 | API-07-073 `/api/platform/rdm/v1/tenants/{tenantId}:seed` | `platform.tenant.provision` | `S11_SEED_RDM` |
| PH-10 | Đăng ký topic `platform.tenant.*.v1`, `platform.release.*.v1`; nghe EVT-20-01 | `event:topic-register` | `S06_EVENTING` |
| PH-16 | API-16-030 đẩy chỉ tiêu `thoi-gian-khoi-tao-tenant` (KPI-12) | `kpi.ingest` | `S17_ACTIVATE` |
| PH-09 | FR-09-043 xóa mật mã tenant (sau bàn giao, hai người duyệt); nhận EVT-09-21 | mTLS mesh | API-20-079 chấm dứt |
| PH-18 | `POST /api/ops/v1/merge-transfers` chuyển dữ liệu một phân hệ (giả định, Phụ lục A); `NotificationApi` gửi thư; đọc API-20-162 | mTLS mesh | API-20-098, 128, `S17_ACTIVATE` |
| OpenBao, Ceph RGW, Git, Argo CD | API của hạ tầng (không phải API Datahub) | Tài khoản dịch vụ `svc-ph20-gitops` | `S02`, `S04`, `S05`, `S07`, API-20-040 |

: Lời gọi ra phân hệ khác của PH-20

## 3. Bảng tổng hợp API

Bảng tổng hợp sinh từ [`ph20/openapi-ph20.yaml`](ph20/openapi-ph20.yaml) bằng `gen_md.py`. Cột "FR" bỏ tiền tố `FR-20-`; cột "Khóa": `I` bắt buộc `Idempotency-Key`, `M` bắt buộc `If-Match`; cột "HTTP" là mã thành công. Có 171 operation: 67 `GET`, 87 `POST`, 9 `PUT`, 8 `PATCH`; 82 có `I`, 55 có `M`.

### 3.1. Tổng hợp theo nhóm chức năng

| Nhóm chức năng | Gốc | Số operation | Mã API-20- | Nội dung |
|---|---|---|---|---|
| Hồ sơ tenant | `/api/platform/v1` | 6 | 001…006 | Khai báo, xem, sửa hồ sơ hành chính, kiểm tra sẵn sàng (nhóm A). |
| Đầu mối và hợp đồng | `/api/platform/v1` | 6 | 007…012 | Đầu mối và hợp đồng dịch vụ của tenant (FR-20-005). |
| Saga khởi tạo | `/api/platform/v1` | 12 | 013…024 | Chạy, theo dõi, thử lại, bù trừ, kiểm tra khói, kích hoạt (nhóm B). |
| Mẫu khởi tạo và khởi tạo bổ sung | `/api/platform/v1` | 10 | 025…034 | Mẫu khởi tạo có phiên bản và đợt bổ sung (FR-20-015, 016). |
| Cụm riêng | `/api/platform/v1` | 4 | 035…038 | Cụm đích `DEDICATED_CLUSTER` (FR-20-017). |
| Cấu hình tenant | `/api/platform/v1` | 9 | 039…047 | Cấu hình nền tảng, phiên bản GitOps, lệch cấu hình, đổi chế độ cách ly (nhóm C). |
| Hạn mức và sử dụng | `/api/platform/v1` | 15 | 048…062 | Hạn mức hợp đồng, đề nghị đổi, ghi đè, sử dụng, cảnh báo, báo cáo (nhóm D). |
| Phân hệ và tính năng | `/api/platform/v1` | 8 | 063…070 | Danh mục phân hệ, bật tắt phân hệ, cờ tính năng (nhóm E). |
| Vòng đời tenant | `/api/platform/v1` | 15 | 071…085 | Tạm ngừng, khôi phục, chấm dứt, gói bàn giao, lịch sử (nhóm F). |
| Sáp nhập tenant | `/api/platform/v1` | 23 | 086…108 | Kế hoạch, ánh xạ, chuyển dữ liệu, xung đột, cutover (nhóm G). |
| Phát hành sản phẩm | `/api/platform/v1` | 20 | 109…128 | Phiên bản, kênh, kế hoạch nâng cấp theo sóng (nhóm I). |
| Quản trị nền tảng | `/api/platform/v1` | 6 | 129…134 | Bảng điều khiển, kiểm toán, tham số, kiểm thử rò rỉ (nhóm J). |
| Cài đặt và ngữ cảnh tỉnh | `/api/tenant/v1` | 8 | 135…142 | Cài đặt, chính sách liên tenant, sử dụng, ngữ cảnh của tỉnh (`/api/tenant/v1`). |
| Tổ chức | `/api/tenant/v1` | 16 | 143…158 | Danh mục tổ chức của tỉnh (nhóm H). |
| Phiên bản và kiểm toán của tỉnh | `/api/tenant/v1` | 3 | 159…161 | Phiên bản, bảo trì, kiểm toán của tỉnh. |
| Registry tenant | `/internal/tenant/v1` | 4 | 162…165 | Registry và cấu hình thực thi cho phân hệ khác (`/internal`). |
| Báo tiến độ | `/internal/tenant/v1` | 3 | 166…168 | Phân hệ báo tiến độ bước saga, sáp nhập, xuất gói (`/internal`). |
| Đọc tổ chức | `/internal/tenant/v1` | 3 | 169…171 | API đọc tổ chức cho phân hệ khác (`/internal`). |

: Nhóm chức năng và operation của PH-20

### 3.2. Danh mục endpoint

#### 3.2.1. Hồ sơ tenant

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-001 | GET | `/tenants` | 002,060 | read | - | 200 |
| API-20-002 | POST | `/tenants` | 001 | provision | I | 201 |
| API-20-003 | GET | `/tenants/{tenantCode}` | 003 | read | - | 200 |
| API-20-004 | PATCH | `/tenants/{tenantCode}` | 004 | admin | M | 200 |
| API-20-005 | POST | `/tenants:check-readiness` | 001,007 | provision | - | 200 |
| API-20-006 | POST | `/tenants/{tenantCode}:check-readiness` | 007 | provision | - | 200 |

: Các API nhóm Hồ sơ tenant

#### 3.2.2. Đầu mối và hợp đồng

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-007 | GET | `/tenants/{tenantCode}/contacts` | 005 | read | - | 200 |
| API-20-008 | POST | `/tenants/{tenantCode}/contacts` | 005 | admin | I | 201 |
| API-20-009 | PATCH | `/tenants/{tenantCode}/contacts/{contactId}` | 005 | admin | M | 200 |
| API-20-010 | GET | `/tenants/{tenantCode}/contracts` | 005 | read | - | 200 |
| API-20-011 | POST | `/tenants/{tenantCode}/contracts` | 005 | admin | I | 201 |
| API-20-012 | PATCH | `/tenants/{tenantCode}/contracts/{contractId}` | 005 | admin | M | 200 |

: Các API nhóm Đầu mối và hợp đồng

#### 3.2.3. Saga khởi tạo

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-013 | POST | `/tenants/{tenantCode}/provisioning-runs` | 008,016 | provision | I | 202 |
| API-20-014 | GET | `/tenants/{tenantCode}/provisioning-runs` | 009 | read | - | 200 |
| API-20-015 | GET | `/provisioning-runs/{runId}` | 009,012 | read | - | 200 |
| API-20-016 | GET | `/provisioning-runs/{runId}/stream` | 009 | read | - | 200 |
| API-20-017 | POST | `/provisioning-runs/{runId}:retry` | 010 | provision | IM | 202 |
| API-20-018 | POST | `/provisioning-runs/{runId}/steps/{stepCode}:retry` | 010 | provision | IM | 202 |
| API-20-019 | POST | `/provisioning-runs/{runId}/steps/{stepCode}:skip` | 010 | provision | IM | 202 |
| API-20-020 | POST | `/provisioning-runs/{runId}:compensate` | 011 | provision | IM | 202 |
| API-20-021 | POST | `/provisioning-runs/{runId}:cancel` | 011 | provision | IM | 202 |
| API-20-022 | POST | `/tenants/{tenantCode}/smoke-tests` | 012 | provision | I | 202 |
| API-20-023 | POST | `/tenants/{tenantCode}:activate` | 013 | provision | IM | 200 |
| API-20-024 | GET | `/provisioning-metrics` | 014 | read | - | 200 |

: Các API nhóm Saga khởi tạo

#### 3.2.4. Mẫu khởi tạo và khởi tạo bổ sung

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-025 | GET | `/provisioning-templates` | 015 | read | - | 200 |
| API-20-026 | POST | `/provisioning-templates` | 015 | admin | I | 201 |
| API-20-027 | GET | `/provisioning-templates/{templateCode}` | 015 | read | - | 200 |
| API-20-028 | POST | `/provisioning-templates/{templateCode}/versions` | 015 | admin | I | 201 |
| API-20-029 | GET | `/provisioning-templates/{templateCode}/versions/{version}` | 015 | read | - | 200 |
| API-20-030 | PATCH | `/provisioning-templates/{templateCode}/versions/{version}` | 015 | admin | M | 200 |
| API-20-031 | POST | `/provisioning-templates/{templateCode}/versions/{version}:publish` | 015 | admin | IM | 200 |
| API-20-032 | POST | `/provisioning-templates/{templateCode}/versions/{version}:retire` | 015 | admin | IM | 200 |
| API-20-033 | POST | `/supplement-plans:preview` | 016 | provision | - | 200 |
| API-20-034 | POST | `/supplement-plans` | 016 | provision | I | 202 |

: Các API nhóm Mẫu khởi tạo và khởi tạo bổ sung

#### 3.2.5. Cụm riêng

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-035 | GET | `/clusters` | 017 | read | - | 200 |
| API-20-036 | POST | `/clusters` | 017 | provision | I | 201 |
| API-20-037 | POST | `/clusters/{clusterCode}:verify` | 017 | provision | I | 200 |
| API-20-038 | POST | `/tenants/{tenantCode}/dedicated-bundle` | 017 | provision | I | 202 |

: Các API nhóm Cụm riêng

#### 3.2.6. Cấu hình tenant

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-039 | GET | `/tenants/{tenantCode}/platform-config` | 019,020 | read | - | 200 |
| API-20-040 | PUT | `/tenants/{tenantCode}/platform-config` | 019,020 | admin | M | 200 |
| API-20-041 | GET | `/tenants/{tenantCode}/config-versions` | 021 | read | - | 200 |
| API-20-042 | GET | `/tenants/{tenantCode}/config-versions/{versionNo}` | 021 | read | - | 200 |
| API-20-043 | POST | `/tenants/{tenantCode}/config-versions/{versionNo}:restore` | 021 | admin | IM | 202 |
| API-20-044 | GET | `/tenants/{tenantCode}/config-drifts` | 022 | read | - | 200 |
| API-20-045 | POST | `/tenants/{tenantCode}/config:reconcile` | 022 | admin | I | 202 |
| API-20-046 | POST | `/tenants/{tenantCode}/config-drifts/{driftId}:resolve` | 022 | admin | I | 202 |
| API-20-047 | POST | `/tenants/{tenantCode}/isolation-changes` | 025 | lifecycle | I | 201 |

: Các API nhóm Cấu hình tenant

#### 3.2.7. Hạn mức và sử dụng

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-048 | GET | `/tenants/{tenantCode}/quotas` | 026,032 | read | - | 200 |
| API-20-049 | PUT | `/tenants/{tenantCode}/quotas` | 026 | quota | M | 200 |
| API-20-050 | POST | `/tenants/{tenantCode}/quota-change-requests` | 027 | quota | I | 201 |
| API-20-051 | GET | `/tenants/{tenantCode}/quota-change-requests` | 027 | read | - | 200 |
| API-20-052 | POST | `/quota-change-requests/{requestId}:approve` | 027 | approve | IM | 200 |
| API-20-053 | POST | `/quota-change-requests/{requestId}:reject` | 027 | approve | IM | 200 |
| API-20-054 | POST | `/tenants/{tenantCode}/quota-overrides` | 032 | quota | I | 201 |
| API-20-055 | POST | `/tenants/{tenantCode}/quota-overrides/{overrideId}:revoke` | 032 | quota | I | 200 |
| API-20-056 | GET | `/usage` | 030 | read | - | 200 |
| API-20-057 | GET | `/tenants/{tenantCode}/usage` | 030 | read | - | 200 |
| API-20-058 | GET | `/quota-alerts` | 029 | read | - | 200 |
| API-20-059 | POST | `/quota-alerts/{alertId}:acknowledge` | 029 | quota | I | 200 |
| API-20-060 | POST | `/usage-reports` | 031 | read | I | 202 |
| API-20-061 | GET | `/usage-reports` | 031 | read | - | 200 |
| API-20-062 | GET | `/usage-reports/{reportId}/file` | 031 | read | - | 200 |

: Các API nhóm Hạn mức và sử dụng

#### 3.2.8. Phân hệ và tính năng

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-063 | GET | `/modules` | 033 | read | - | 200 |
| API-20-064 | GET | `/tenants/{tenantCode}/modules` | 034,035 | read | - | 200 |
| API-20-065 | POST | `/tenants/{tenantCode}/modules/{moduleCode}:enable` | 034 | admin | I | 202 |
| API-20-066 | POST | `/tenants/{tenantCode}/modules/{moduleCode}:disable` | 035 | admin | I | 202 |
| API-20-067 | POST | `/tenants/{tenantCode}/modules/{moduleCode}:suspend` | 035 | admin | I | 202 |
| API-20-068 | POST | `/tenants/{tenantCode}/modules/{moduleCode}:resume` | 035 | admin | I | 202 |
| API-20-069 | GET | `/tenants/{tenantCode}/feature-flags` | 036 | read | - | 200 |
| API-20-070 | PUT | `/tenants/{tenantCode}/feature-flags/{flagCode}` | 036 | admin | M | 200 |

: Các API nhóm Phân hệ và tính năng

#### 3.2.9. Vòng đời tenant

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-071 | POST | `/tenants/{tenantCode}/lifecycle-requests` | 038,039,040 | lifecycle | I | 201 |
| API-20-072 | GET | `/tenants/{tenantCode}/lifecycle-requests` | 043 | read | - | 200 |
| API-20-073 | GET | `/lifecycle-requests` | 040 | read | - | 200 |
| API-20-074 | GET | `/lifecycle-requests/{requestId}` | 040,043 | read | - | 200 |
| API-20-075 | POST | `/lifecycle-requests/{requestId}:submit` | 040 | lifecycle | IM | 200 |
| API-20-076 | POST | `/lifecycle-requests/{requestId}:approve` | 025,040 | approve | IM | 200 |
| API-20-077 | POST | `/lifecycle-requests/{requestId}:reject` | 025,040 | approve | IM | 200 |
| API-20-078 | POST | `/lifecycle-requests/{requestId}:cancel` | 040 | lifecycle | IM | 200 |
| API-20-079 | POST | `/lifecycle-requests/{requestId}:execute` | 025,038,039,042 | lifecycle | IM | 202 |
| API-20-080 | POST | `/tenants/{tenantCode}/export-packages` | 041 | lifecycle | I | 202 |
| API-20-081 | GET | `/tenants/{tenantCode}/export-packages` | 041 | read | - | 200 |
| API-20-082 | GET | `/export-packages/{packageId}` | 041 | read | - | 200 |
| API-20-083 | POST | `/export-packages/{packageId}:issue-link` | 041 | lifecycle | I | 200 |
| API-20-084 | POST | `/export-packages/{packageId}:confirm-delivery` | 041 | lifecycle | I | 200 |
| API-20-085 | GET | `/tenants/{tenantCode}/status-history` | 043,044 | read | - | 200 |

: Các API nhóm Vòng đời tenant

#### 3.2.10. Sáp nhập tenant

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-086 | POST | `/merge-plans` | 045 | merge | I | 201 |
| API-20-087 | GET | `/merge-plans` | 045 | read | - | 200 |
| API-20-088 | GET | `/merge-plans/{mergePlanId}` | 045,048 | read | - | 200 |
| API-20-089 | PATCH | `/merge-plans/{mergePlanId}` | 045 | merge | M | 200 |
| API-20-090 | POST | `/merge-plans/{mergePlanId}:submit` | 045 | merge | IM | 200 |
| API-20-091 | POST | `/merge-plans/{mergePlanId}:approve` | 045 | approve | IM | 200 |
| API-20-092 | POST | `/merge-plans/{mergePlanId}:reject` | 045 | approve | IM | 200 |
| API-20-093 | POST | `/merge-plans/{mergePlanId}:cancel` | 045 | merge | IM | 200 |
| API-20-094 | GET | `/merge-plans/{mergePlanId}/mappings` | 046 | read | - | 200 |
| API-20-095 | POST | `/merge-plans/{mergePlanId}/mappings:suggest` | 046 | merge | - | 200 |
| API-20-096 | PUT | `/merge-plans/{mergePlanId}/mappings/{mappingId}` | 046 | merge | M | 200 |
| API-20-097 | POST | `/merge-plans/{mergePlanId}:dry-run` | 047 | merge | I | 202 |
| API-20-098 | POST | `/merge-plans/{mergePlanId}:start` | 048 | merge | IM | 202 |
| API-20-099 | GET | `/merge-plans/{mergePlanId}/participants` | 048 | read | - | 200 |
| API-20-100 | POST | `/merge-plans/{mergePlanId}/participants/{module}:retry` | 048 | merge | I | 202 |
| API-20-101 | GET | `/merge-plans/{mergePlanId}/conflicts` | 049 | read | - | 200 |
| API-20-102 | POST | `/merge-plans/{mergePlanId}/conflicts/{conflictId}:resolve` | 049 | merge | IM | 200 |
| API-20-103 | POST | `/merge-plans/{mergePlanId}/conflicts:resolve-batch` | 049 | merge | I | 200 |
| API-20-104 | POST | `/merge-plans/{mergePlanId}:transfer-identity` | 050 | merge | IM | 202 |
| API-20-105 | GET | `/merge-plans/{mergePlanId}/credentials` | 050 | read | - | 200 |
| API-20-106 | POST | `/merge-plans/{mergePlanId}:cutover` | 051 | merge | IM | 202 |
| API-20-107 | POST | `/merge-plans/{mergePlanId}:extend-transition` | 052 | merge | IM | 200 |
| API-20-108 | POST | `/merge-plans/{mergePlanId}:complete` | 052 | merge | IM | 202 |

: Các API nhóm Sáp nhập tenant

#### 3.2.11. Phát hành sản phẩm

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-109 | GET | `/releases` | 059 | read | - | 200 |
| API-20-110 | POST | `/releases` | 059 | release | I | 201 |
| API-20-111 | GET | `/releases/{releaseVersion}` | 059 | read | - | 200 |
| API-20-112 | PATCH | `/releases/{releaseVersion}` | 059 | release | M | 200 |
| API-20-113 | POST | `/releases/{releaseVersion}:preview` | 060 | release | IM | 200 |
| API-20-114 | POST | `/releases/{releaseVersion}:promote` | 060 | release | IM | 200 |
| API-20-115 | POST | `/releases/{releaseVersion}:deprecate` | 059 | release | IM | 200 |
| API-20-116 | POST | `/releases/{releaseVersion}:withdraw` | 059 | release | IM | 200 |
| API-20-117 | PUT | `/tenants/{tenantCode}/release-subscription` | 060 | release | M | 200 |
| API-20-118 | POST | `/releases/{releaseVersion}/upgrade-plans` | 061 | release | I | 201 |
| API-20-119 | GET | `/upgrade-plans/{planId}` | 061,062 | read | - | 200 |
| API-20-120 | PATCH | `/upgrade-plans/{planId}` | 061 | release | M | 200 |
| API-20-121 | POST | `/upgrade-plans/{planId}:schedule` | 061 | release | IM | 200 |
| API-20-122 | POST | `/upgrade-plans/{planId}:pause` | 062 | release | IM | 200 |
| API-20-123 | POST | `/upgrade-plans/{planId}:resume` | 062 | release | IM | 200 |
| API-20-124 | POST | `/upgrade-plans/{planId}:rollback` | 062 | release | IM | 202 |
| API-20-125 | POST | `/upgrade-plans/{planId}:cancel` | 062 | release | IM | 200 |
| API-20-126 | GET | `/upgrade-plans/{planId}/tenant-upgrades` | 062 | read | - | 200 |
| API-20-127 | POST | `/upgrade-plans/{planId}/tenant-upgrades/{tenantCode}:retry` | 062 | release | I | 202 |
| API-20-128 | POST | `/releases/{releaseVersion}:announce` | 063 | release | I | 202 |

: Các API nhóm Phát hành sản phẩm

#### 3.2.12. Quản trị nền tảng

Đường dẫn rút gọn, bỏ gốc `/api/platform/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-129 | GET | `/dashboard` | 067 | read | - | 200 |
| API-20-130 | GET | `/audit-events` | 068 | read | - | 200 |
| API-20-131 | GET | `/parameters` | 069 | read | - | 200 |
| API-20-132 | POST | `/leak-tests` | 070 | admin | I | 202 |
| API-20-133 | GET | `/leak-tests` | 070 | read | - | 200 |
| API-20-134 | GET | `/leak-tests/{testRunId}` | 070 | read | - | 200 |

: Các API nhóm Quản trị nền tảng

#### 3.2.13. Cài đặt và ngữ cảnh tỉnh

Đường dẫn rút gọn, bỏ gốc `/api/tenant/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-135 | GET | `/settings` | 018,064 | org-read | - | 200 |
| API-20-136 | PUT | `/settings` | 018 | settings | M | 200 |
| API-20-137 | GET | `/cross-tenant-policy` | 023 | settings | - | 200 |
| API-20-138 | PUT | `/cross-tenant-policy` | 023 | settings | M | 200 |
| API-20-139 | GET | `/cross-tenant-access-log` | 024 | settings | - | 200 |
| API-20-140 | GET | `/usage` | 030 | usage-read | - | 200 |
| API-20-141 | GET | `/quotas` | 030 | usage-read | - | 200 |
| API-20-142 | GET | `/context` | 037,066 | mọi người dùng | - | 200 |

: Các API nhóm Cài đặt và ngữ cảnh tỉnh

#### 3.2.14. Tổ chức

Đường dẫn rút gọn, bỏ gốc `/api/tenant/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-143 | GET | `/organizations` | 053 | org-read | - | 200 |
| API-20-144 | POST | `/organizations` | 053 | org | I | 201 |
| API-20-145 | GET | `/organizations/{orgCode}` | 053 | org-read | - | 200 |
| API-20-146 | PATCH | `/organizations/{orgCode}` | 053 | org | M | 200 |
| API-20-147 | POST | `/organizations/{orgCode}:deactivate` | 054 | org | IM | 200 |
| API-20-148 | POST | `/organizations/{orgCode}:reactivate` | 054 | org | IM | 200 |
| API-20-149 | POST | `/organizations/{orgCode}:dissolve` | 054 | org | IM | 200 |
| API-20-150 | POST | `/organizations:merge` | 054 | org | I | 200 |
| API-20-151 | GET | `/organizations/{orgCode}/history` | 054 | org-read | - | 200 |
| API-20-152 | PUT | `/organizations/{orgCode}/data-owner` | 058 | org | M | 200 |
| API-20-153 | POST | `/organization-imports` | 055 | org | I | 202 |
| API-20-154 | GET | `/organization-imports/{importId}` | 055 | org | - | 200 |
| API-20-155 | POST | `/organization-imports/{importId}:confirm` | 055 | org | I | 202 |
| API-20-156 | GET | `/organizations:export` | 055 | org-read | - | 200 |
| API-20-157 | GET | `/organization-sync-proposals` | 056 | org | - | 200 |
| API-20-158 | POST | `/organization-sync-proposals/{proposalId}:decide` | 056 | org | I | 200 |

: Các API nhóm Tổ chức

#### 3.2.15. Phiên bản và kiểm toán của tỉnh

Đường dẫn rút gọn, bỏ gốc `/api/tenant/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-159 | GET | `/release-info` | 064 | org-read | - | 200 |
| API-20-160 | PUT | `/maintenance-window` | 018,061 | settings | M | 200 |
| API-20-161 | GET | `/audit-events` | 068 | TA, AU | - | 200 |

: Các API nhóm Phiên bản và kiểm toán của tỉnh

#### 3.2.16. Registry tenant

Đường dẫn rút gọn, bỏ gốc `/internal/tenant/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-162 | GET | `/tenants` | 065 | scope tenant:registry-read | - | 200 |
| API-20-163 | GET | `/tenants/{tenantCode}` | 037,065,066 | scope tenant:registry-read | - | 200 |
| API-20-164 | GET | `/tenants/{tenantCode}/enforcement` | 026,027,051,066 | scope tenant:registry-read | - | 200 |
| API-20-165 | GET | `/tenants/{tenantCode}/cross-tenant-policy` | 023 | scope tenant:registry-read | - | 200 |

: Các API nhóm Registry tenant

#### 3.2.17. Báo tiến độ

Đường dẫn rút gọn, bỏ gốc `/internal/tenant/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-166 | POST | `/provisioning-runs/{runId}/steps/{stepCode}:report` | 008,034 | scope tenant:provision-report | I | 200 |
| API-20-167 | POST | `/merge-plans/{mergePlanId}/participants/{module}:report` | 047,048 | scope tenant:provision-report | I | 200 |
| API-20-168 | POST | `/export-packages/{packageId}/items/{module}:report` | 041 | scope tenant:provision-report | I | 200 |

: Các API nhóm Báo tiến độ

#### 3.2.18. Đọc tổ chức

Đường dẫn rút gọn, bỏ gốc `/internal/tenant/v1`.

| Mã | PT | Đường dẫn | FR | Quyền | Khóa | HTTP |
|---|---|---|---|---|---|---|
| API-20-169 | GET | `/organizations` | 057 | scope tenant:org-read | - | 200 |
| API-20-170 | GET | `/organizations/{orgCode}` | 057 | scope tenant:org-read | - | 200 |
| API-20-171 | POST | `/organizations:lookup` | 057,058 | scope tenant:org-read | - | 200 |

: Các API nhóm Đọc tổ chức

## 4. Đặc tả từng endpoint

Chương này sinh tự động từ [`ph20/openapi-ph20.yaml`](ph20/openapi-ph20.yaml) bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục: mục đích, phương thức và đường dẫn, quyền, FR hiện thực, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú. Mã lỗi nêu ở mục "Lỗi" là tập mã operation có thể trả; ý nghĩa ở chương 6. Ví dụ yêu cầu và phản hồi nằm ở OpenAPI (không lặp lại ở đây để tài liệu gọn).

<!-- gen:dac-ta-api:start -->

### Hồ sơ tenant

#### API-20-001 · Liệt kê, tìm, lọc tenant toàn nền tảng

::: dac-ta
**Mục đích.** Liệt kê, tìm, lọc tenant toàn nền tảng.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-002, FR-20-060.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `isolationMode` (query, array, tùy chọn); `scaleProfile` (query, array, tùy chọn); `deploymentProfile` (query, array, tùy chọn); `channel` (query, ReleaseChannel, tùy chọn); `currentVersion` (query, string, tùy chọn); `quotaAlert` (query, QuotaAlertLevel, tùy chọn); `kind` (query, array, tùy chọn); `testTenant` (query, boolean, tùy chọn); `sort` (query, string, tùy chọn); `format` (query, ListFormat, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ tenant `PLATFORM` gọi được. `format=csv` trả tệp CSV UTF-8 tối đa 1.000 dòng, không chứa dữ liệu cá nhân; mặc định chỉ `kind = PROVINCE` và không tính tenant kiểm thử. Khối `facets` đếm theo trạng thái, chế độ cách ly, kênh.
:::

#### API-20-002 · Khai báo tenant mới ở `PROVISIONING` (chưa chạy saga)

::: dac-ta
**Mục đích.** Khai báo tenant mới ở `PROVISIONING` (chưa chạy saga).

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-001.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantCreate`; trường bắt buộc: `tenantCode`, `name`, `isolationMode`, `scaleProfile`, `deploymentProfile`, `templateCode`, `templateVersion`, `contacts`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Tenant`; trường bắt buộc: `tenantCode`, `name`, `kind`, `status`, `isolationMode`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-20-003, ERR-20-004, ERR-20-009, ERR-20-011, ERR-20-012, ERR-20-015, ERR-20-017, ERR-20-021, ERR-20-062, ERR-20-064 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ ghi hồ sơ ở `PROVISIONING`, chưa chạy saga và chưa tạo tài nguyên ở hệ khác. Mã theo mẫu `^T[0-9]{2}$`, dải `T90…T99` dành cho tenant kiểm thử (`testTenant = true`). Có `Idempotency-Key`; phản hồi kèm `Location` và `ETag`.
:::

#### API-20-003 · Chi tiết tenant, khối tóm tắt

::: dac-ta
**Mục đích.** Chi tiết tenant, khối tóm tắt.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-003.

**Tham số.** `tenantCode` (path, string, bắt buộc); `include` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantDetail`; trường bắt buộc: `tenantCode`, `name`, `kind`, `status`, `isolationMode`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `include` chọn các khối trả kèm (`summary`, `config`, `contacts`, `modules`, `quotas`, `lastRun`) để giảm tải. Tenant `PLATFORM` và `COMMON` cũng xem được nhưng được bảo vệ khỏi mọi thao tác ghi (ERR-20-010).
:::

#### API-20-004 · Sửa hồ sơ hành chính (`If-Match`)

::: dac-ta
**Mục đích.** Sửa hồ sơ hành chính (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/tenants/{tenantCode}`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-004.

**Tham số.** `tenantCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantUpdate`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Tenant`; trường bắt buộc: `tenantCode`, `name`, `kind`, `status`, `isolationMode`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-068, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không đổi `tenantCode`, `realm`, `kind`; `adminUnitId` chỉ đổi khi tenant còn `PROVISIONING` và chưa chạy saga (ERR-20-068). Mọi thao tác ghi cần `reason` và `ticketRef` (ERR-20-008).
:::

#### API-20-005 · Kiểm tra sẵn sàng cho hồ sơ chưa lưu

::: dac-ta
**Mục đích.** Kiểm tra sẵn sàng cho hồ sơ chưa lưu.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants:check-readiness`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-001, FR-20-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `TenantCreate`; trường bắt buộc: `tenantCode`, `name`, `isolationMode`, `scaleProfile`, `deploymentProfile`, `templateCode`, `templateVersion`, `contacts`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReadinessResult`; trường bắt buộc: `ready`, `checkedAt`, `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-20-003, ERR-20-004, ERR-20-011, ERR-20-012, ERR-20-013, ERR-20-014, ERR-20-015, ERR-20-017, ERR-20-021, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm tra sẵn sàng cho hồ sơ chưa lưu, không ghi dữ liệu. Mục `BLOCKER` chưa đạt thì `ready = false`.
:::

#### API-20-006 · Kiểm tra lại sẵn sàng trước khi chạy saga

::: dac-ta
**Mục đích.** Kiểm tra lại sẵn sàng trước khi chạy saga.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}:check-readiness`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-007.

**Tham số.** `tenantCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReadinessResult`; trường bắt buộc: `ready`, `checkedAt`, `items`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-013, ERR-20-014, ERR-20-017, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm tra lại sẵn sàng của tenant đã lưu trước khi chạy saga; lưu kết quả lần kiểm gần nhất vào bản ghi tenant.
:::

### Đầu mối và hợp đồng

#### API-20-007 · Danh sách đầu mối

::: dac-ta
**Mục đích.** Danh sách đầu mối.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/contacts`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-005.

**Tham số.** `tenantCode` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ContactPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách đầu mối.
:::

#### API-20-008 · Thêm đầu mối

::: dac-ta
**Mục đích.** Thêm đầu mối.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/contacts`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-005.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ContactCreate`; trường bắt buộc: `role`, `fullName`, `officialEmail`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Contact`; trường bắt buộc: `contactId`, `role`, `fullName`, `officialEmail`, `active`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-009, ERR-20-010, ERR-20-021, ERR-20-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm đầu mối.
:::

#### API-20-009 · Sửa, ngừng đầu mối

::: dac-ta
**Mục đích.** Sửa, ngừng đầu mối.

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/tenants/{tenantCode}/contacts/{contactId}`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-005.

**Tham số.** `tenantCode` (path, string, bắt buộc); `contactId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ContactUpdate`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Contact`; trường bắt buộc: `contactId`, `role`, `fullName`, `officialEmail`, `active`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-021, ERR-20-022, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa, ngừng đầu mối. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-010 · Danh sách hợp đồng dịch vụ

::: dac-ta
**Mục đích.** Danh sách hợp đồng dịch vụ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/contracts`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-005.

**Tham số.** `tenantCode` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ContractPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách hợp đồng dịch vụ.
:::

#### API-20-011 · Thêm hợp đồng dịch vụ

::: dac-ta
**Mục đích.** Thêm hợp đồng dịch vụ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/contracts`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-005.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ContractCreate`; trường bắt buộc: `contractNo`, `validFrom`, `validTo`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Contract`; trường bắt buộc: `contractId`, `contractNo`, `status`, `validFrom`, `validTo`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-009, ERR-20-010, ERR-20-021, ERR-20-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm hợp đồng dịch vụ.
:::

#### API-20-012 · Sửa, gia hạn hợp đồng

::: dac-ta
**Mục đích.** Sửa, gia hạn hợp đồng.

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/tenants/{tenantCode}/contracts/{contractId}`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-005.

**Tham số.** `tenantCode` (path, string, bắt buộc); `contractId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ContractUpdate`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Contract`; trường bắt buộc: `contractId`, `contractNo`, `status`, `validFrom`, `validTo`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-021, ERR-20-022, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa, gia hạn hợp đồng. Cần `If-Match` theo `ETag` đã đọc.
:::

### Saga khởi tạo

#### API-20-013 · Chạy saga (`INITIAL`, `SUPPLEMENT`)

::: dac-ta
**Mục đích.** Chạy saga (`INITIAL`, `SUPPLEMENT`).

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/provisioning-runs`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-008, FR-20-016.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RunCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-010, ERR-20-016, ERR-20-017, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả `202` kèm `Location` tới lần chạy. `runKind = INITIAL` chạy 17 bước `S01_RECORD` … `S17_ACTIVATE`; `SUPPLEMENT` chỉ chạy các bước, phân hệ nêu ở `steps`, `modules`. Mỗi tenant chỉ một lần chạy tại một thời điểm (ERR-20-016). Bước bất đồng bộ chờ phân hệ báo qua API-20-166.
:::

#### API-20-014 · Các lần chạy saga của tenant

::: dac-ta
**Mục đích.** Các lần chạy saga của tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/provisioning-runs`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-009.

**Tham số.** `tenantCode` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProvisioningRunPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Các lần chạy saga của tenant.
:::

#### API-20-015 · Chi tiết lần chạy kèm sổ bước, kết quả kiểm tra khói

::: dac-ta
**Mục đích.** Chi tiết lần chạy kèm sổ bước, kết quả kiểm tra khói.

**Phương thức, đường dẫn.** `GET /api/platform/v1/provisioning-runs/{runId}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-009, FR-20-012.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả lần chạy kèm sổ bước và `smokeResults`; tenant khác hoặc không có lần chạy trả `404` ERR-20-002.
:::

#### API-20-016 · Luồng SSE tiến độ thời gian thực

::: dac-ta
**Mục đích.** Luồng SSE tiến độ thời gian thực.

**Phương thức, đường dẫn.** `GET /api/platform/v1/provisioning-runs/{runId}/stream`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-009.

**Tham số.** `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Luồng `text/event-stream`; mỗi sự kiện SSE là một thay đổi của bước hoặc lần chạy; nối lại bằng tiêu đề `Last-Event-ID`.
:::

#### API-20-017 · Thử lại từ bước lỗi đầu tiên

::: dac-ta
**Mục đích.** Thử lại từ bước lỗi đầu tiên.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-runs/{runId}:retry`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-010.

**Tham số.** `runId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StepAction`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-018, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thử lại từ bước lỗi đầu tiên, tối đa `20.provision.step-retry-max` lần mỗi bước; chỉ khi lần chạy `FAILED` (ERR-20-018).
:::

#### API-20-018 · Thử lại một bước

::: dac-ta
**Mục đích.** Thử lại một bước.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-runs/{runId}/steps/{stepCode}:retry`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-010.

**Tham số.** `runId` (path, string, bắt buộc); `stepCode` (path, StepCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StepAction`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-018, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thử lại một bước. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-019 · Bỏ qua bước không bắt buộc có lý do

::: dac-ta
**Mục đích.** Bỏ qua bước không bắt buộc có lý do.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-runs/{runId}/steps/{stepCode}:skip`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-010.

**Tham số.** `runId` (path, string, bắt buộc); `stepCode` (path, StepCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SkipStepRequest`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-018, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ bước không bắt buộc; lý do từ 20 ký tự.
:::

#### API-20-020 · Bù trừ ngược các bước đã xong

::: dac-ta
**Mục đích.** Bù trừ ngược các bước đã xong.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-runs/{runId}:compensate`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-011.

**Tham số.** `runId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CompensateRequest`; trường bắt buộc: `reason`, `ticketRef`, `confirmTenantCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-019, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bù trừ ngược theo thứ tự các bước đã xong; yêu cầu gõ lại mã tenant ở `confirmTenantCode`. Không bù trừ được trả ERR-20-019.
:::

#### API-20-021 · Hủy khởi tạo (bù trừ rồi `CANCELLED`)

::: dac-ta
**Mục đích.** Hủy khởi tạo (bù trừ rồi `CANCELLED`).

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-runs/{runId}:cancel`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-011.

**Tham số.** `runId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CompensateRequest`; trường bắt buộc: `reason`, `ticketRef`, `confirmTenantCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProvisioningRun`; trường bắt buộc: `runId`, `tenantCode`, `runKind`, `status`, `attempt`, `steps`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-019, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bù trừ các bước đã xong rồi chuyển lần chạy sang `CANCELLED`.
:::

#### API-20-022 · Chạy lại kiểm tra khói

::: dac-ta
**Mục đích.** Chạy lại kiểm tra khói.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/smoke-tests`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-012.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SmokeRun`; trường bắt buộc: `runId`, `tenantCode`, `status`, `startedAt`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-20-002, ERR-20-006, ERR-20-009, ERR-20-010, ERR-20-016 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy lại bốn ca kiểm tra khói; kết quả đọc ở `smokeResults` của API-20-015. `20.smoke.enabled = false` thì ca ghi `SKIPPED`.
:::

#### API-20-023 · Kích hoạt và bàn giao

::: dac-ta
**Mục đích.** Kích hoạt và bàn giao.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}:activate`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-013.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ActivateRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TenantActivation`; trường bắt buộc: `tenantCode`, `status`, `activatedAt`, `handoverDelivery`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-010, ERR-20-020, ERR-20-021, ERR-20-062, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển `ACTIVE`, gửi thông báo bàn giao cho đầu mối `TENANT_ADMIN`, đẩy KPI-12 sang PH-16. Cần kiểm tra khói đạt (ERR-20-020) và có đầu mối (ERR-20-021). Phát EVT-20-03.
:::

#### API-20-024 · Thời gian khởi tạo theo tenant, theo bước

::: dac-ta
**Mục đích.** Thời gian khởi tạo theo tenant, theo bước.

**Phương thức, đường dẫn.** `GET /api/platform/v1/provisioning-metrics`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-014.

**Tham số.** `tenantCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProvisioningMetrics`; trường bắt buộc: `items`, `median`, `p95`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004, ERR-20-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thời gian khởi tạo theo tenant, theo bước, trung vị và p95 (KPI-12, mục tiêu không quá một ngày làm việc).
:::

### Mẫu khởi tạo và khởi tạo bổ sung

#### API-20-025 · Danh sách mẫu khởi tạo

::: dac-ta
**Mục đích.** Danh sách mẫu khởi tạo.

**Phương thức, đường dẫn.** `GET /api/platform/v1/provisioning-templates`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-015.

**Tham số.** `q` (query, string, tùy chọn); `state` (query, TemplateState, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplatePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách mẫu khởi tạo.
:::

#### API-20-026 · Tạo mẫu khởi tạo, phiên bản 1 `DRAFT`

::: dac-ta
**Mục đích.** Tạo mẫu khởi tạo, phiên bản 1 `DRAFT`.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-templates`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-015.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateCreate`; trường bắt buộc: `templateCode`, `name`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TemplateVersion`; trường bắt buộc: `templateCode`, `version`, `state`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-029, ERR-20-033, ERR-20-063 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo mẫu và phiên bản 1 `DRAFT`; phiên bản chỉ phát hành được khi lược đồ hợp lệ và phân hệ lõi có đủ (ERR-20-015).
:::

#### API-20-027 · Chi tiết mẫu và các phiên bản

::: dac-ta
**Mục đích.** Chi tiết mẫu và các phiên bản.

**Phương thức, đường dẫn.** `GET /api/platform/v1/provisioning-templates/{templateCode}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-015.

**Tham số.** `templateCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplateDetail`; trường bắt buộc: `templateCode`, `name`, `latestVersion`, `versions`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết mẫu và các phiên bản.
:::

#### API-20-028 · Mở phiên bản mới từ bản đang dùng

::: dac-ta
**Mục đích.** Mở phiên bản mới từ bản đang dùng.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-templates/{templateCode}/versions`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-015.

**Tham số.** `templateCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateNewVersion`; trường bắt buộc: `changeNote`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TemplateVersion`; trường bắt buộc: `templateCode`, `version`, `state`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-029, ERR-20-033, ERR-20-063 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sao nội dung phiên bản đang dùng sang phiên bản mới `DRAFT`.
:::

#### API-20-029 · Nội dung một phiên bản, so sánh (`compareTo`)

::: dac-ta
**Mục đích.** Nội dung một phiên bản, so sánh (`compareTo`).

**Phương thức, đường dẫn.** `GET /api/platform/v1/provisioning-templates/{templateCode}/versions/{version}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-015.

**Tham số.** `templateCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `compareTo` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `templateCode`, `version`, `state`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `compareTo` là số phiên bản cần so; khác biệt trả ở `diff`.
:::

#### API-20-030 · Sửa phiên bản `DRAFT`

::: dac-ta
**Mục đích.** Sửa phiên bản `DRAFT`.

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/provisioning-templates/{templateCode}/versions/{version}`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-015.

**Tham số.** `templateCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateVersionUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `templateCode`, `version`, `state`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-029, ERR-20-033, ERR-20-063, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa phiên bản `DRAFT`. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-031 · Phát hành phiên bản mẫu

::: dac-ta
**Mục đích.** Phát hành phiên bản mẫu.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-templates/{templateCode}/versions/{version}:publish`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-015.

**Tham số.** `templateCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `templateCode`, `version`, `state`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-029, ERR-20-033, ERR-20-063, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát hành phiên bản; phiên bản `PUBLISHED` bất biến, sửa cần phiên bản mới (ERR-20-063).
:::

#### API-20-032 · Ngừng phiên bản mẫu

::: dac-ta
**Mục đích.** Ngừng phiên bản mẫu.

**Phương thức, đường dẫn.** `POST /api/platform/v1/provisioning-templates/{templateCode}/versions/{version}:retire`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-015.

**Tham số.** `templateCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `TemplateVersion`; trường bắt buộc: `templateCode`, `version`, `state`, `modules`, `quotaByScale`, `rdmPackageVersion`, `orgSeed`, `activation`, `releaseChannel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-029, ERR-20-033, ERR-20-063, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ngừng phiên bản mẫu. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-033 · Xem trước tenant cần khởi tạo bổ sung

::: dac-ta
**Mục đích.** Xem trước tenant cần khởi tạo bổ sung.

**Phương thức, đường dẫn.** `POST /api/platform/v1/supplement-plans:preview`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-016.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SupplementRequest`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SupplementPreview`; trường bắt buộc: `candidates`, `excluded`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-20-004, ERR-20-006 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xem trước các tenant cần khởi tạo bổ sung; tenant đang có lần chạy khác nằm ở `excluded` kèm lý do. Không ghi dữ liệu.
:::

#### API-20-034 · Lập đợt khởi tạo bổ sung hàng loạt

::: dac-ta
**Mục đích.** Lập đợt khởi tạo bổ sung hàng loạt.

**Phương thức, đường dẫn.** `POST /api/platform/v1/supplement-plans`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-016.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SupplementRequest`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SupplementPlan`; trường bắt buộc: `planId`, `status`, `tenantCount`, `runIds`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-20-004, ERR-20-006, ERR-20-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lập đợt bổ sung, chạy theo sóng `waveSize` tenant song song (mặc định 3).
:::

### Cụm riêng

#### API-20-035 · Danh sách cụm đích `DEDICATED_CLUSTER`

::: dac-ta
**Mục đích.** Danh sách cụm đích `DEDICATED_CLUSTER`.

**Phương thức, đường dẫn.** `GET /api/platform/v1/clusters`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-017.

**Tham số.** `state` (query, ClusterState, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClusterPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách cụm đích `DEDICATED_CLUSTER`.
:::

#### API-20-036 · Đăng ký cụm đích

::: dac-ta
**Mục đích.** Đăng ký cụm đích.

**Phương thức, đường dẫn.** `POST /api/platform/v1/clusters`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-017.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ClusterCreate`; trường bắt buộc: `clusterCode`, `name`, `apiEndpoint`, `argoCdEndpoint`, `secretRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Cluster`; trường bắt buộc: `clusterCode`, `name`, `apiEndpoint`, `argoCdEndpoint`, `state`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-064 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `secretRef` chỉ là đường dẫn OpenBao, không bao giờ là giá trị bí mật. Chỉ dùng khi `20.dedicated-cluster.enabled = true` (Đợt 2).
:::

#### API-20-037 · Kiểm tra cụm đạt yêu cầu

::: dac-ta
**Mục đích.** Kiểm tra cụm đạt yêu cầu.

**Phương thức, đường dẫn.** `POST /api/platform/v1/clusters/{clusterCode}:verify`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-017.

**Tham số.** `clusterCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ClusterVerification`; trường bắt buộc: `clusterCode`, `state`, `checks`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-064 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm cụm đích (API, Argo CD, năng lực); cụm đạt chuyển `VERIFIED`, không đạt trả ERR-20-064.
:::

#### API-20-038 · Sinh gói cấu hình cho cụm riêng

::: dac-ta
**Mục đích.** Sinh gói cấu hình cho cụm riêng.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/dedicated-bundle`.

**Quyền.** `PERM-20-provision`.

**FR hiện thực.** FR-20-017.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `DedicatedBundle`; trường bắt buộc: `bundleId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-064 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sinh gói cấu hình cho cụm riêng kéo qua Argo CD (Q20-08); liên kết tải hết hạn sau 24 giờ.
:::

### Cấu hình tenant

#### API-20-039 · Cấu hình nền tảng của tenant kèm trạng thái ghi Git, áp Argo CD

::: dac-ta
**Mục đích.** Cấu hình nền tảng của tenant kèm trạng thái ghi Git, áp Argo CD.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/platform-config`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-019, FR-20-020.

**Tham số.** `tenantCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformConfig`; trường bắt buộc: `realm`, `publicHost`, `apiPathPrefix`, `deploymentProfile`, `runtimeNamespaceMode`, `configVersionNo`, `syncStatus`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả cấu hình kèm `configVersionNo`, `commitSha`, `syncStatus`, `appliedAt` của kho `dh-tenant-config`.
:::

#### API-20-040 · Sửa cấu hình nền tảng (`If-Match`)

::: dac-ta
**Mục đích.** Sửa cấu hình nền tảng (`If-Match`).

**Phương thức, đường dẫn.** `PUT /api/platform/v1/tenants/{tenantCode}/platform-config`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-019, FR-20-020.

**Tham số.** `tenantCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PlatformConfigUpdate`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformConfig`; trường bắt buộc: `realm`, `publicHost`, `apiPathPrefix`, `deploymentProfile`, `runtimeNamespaceMode`, `configVersionNo`, `syncStatus`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `502`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-024, ERR-20-025, ERR-20-067, ERR-20-068, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi commit ký vào kho GitOps rồi áp qua Argo CD; host, tiền tố trùng tenant khác trả ERR-20-067. Lỗi ghi Git trả `502` ERR-20-024. Phát EVT-20-09.
:::

#### API-20-041 · Lịch sử phiên bản cấu hình

::: dac-ta
**Mục đích.** Lịch sử phiên bản cấu hình.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/config-versions`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-021.

**Tham số.** `tenantCode` (path, string, bắt buộc); `scope` (query, ConfigScope, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConfigVersionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch sử phiên bản cấu hình.
:::

#### API-20-042 · Nội dung phiên bản, so sánh (`compareTo`)

::: dac-ta
**Mục đích.** Nội dung phiên bản, so sánh (`compareTo`).

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/config-versions/{versionNo}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-021.

**Tham số.** `tenantCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `compareTo` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConfigVersion`; trường bắt buộc: `versionNo`, `scope`, `commitSha`, `changeSource`, `applyStatus`, `changedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nội dung phiên bản, so sánh (`compareTo`).
:::

#### API-20-043 · Khôi phục phiên bản cấu hình

::: dac-ta
**Mục đích.** Khôi phục phiên bản cấu hình.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/config-versions/{versionNo}:restore`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-021.

**Tham số.** `tenantCode` (path, string, bắt buộc); `versionNo` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ConfigVersion`; trường bắt buộc: `versionNo`, `scope`, `commitSha`, `changeSource`, `applyStatus`, `changedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-026, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khôi phục tạo phiên bản cấu hình mới có nội dung của phiên bản cũ (không xóa lịch sử); trả `202` khi chờ Argo CD áp.
:::

#### API-20-044 · Lệch cấu hình của tenant

::: dac-ta
**Mục đích.** Lệch cấu hình của tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/config-drifts`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-022.

**Tham số.** `tenantCode` (path, string, bắt buộc); `status` (query, DriftStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConfigDriftPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lệch cấu hình của tenant.
:::

#### API-20-045 · Đối chiếu ngay

::: dac-ta
**Mục đích.** Đối chiếu ngay.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/config:reconcile`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-022.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReconcileResult`; trường bắt buộc: `reconcileId`, `status`, `startedAt`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-006, ERR-20-008, ERR-20-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đối chiếu ngay trạng thái mong muốn ở Git với trạng thái thực; trả `202`.
:::

#### API-20-046 · Xử lý một lệch (áp lại hoặc nhận vào Git)

::: dac-ta
**Mục đích.** Xử lý một lệch (áp lại hoặc nhận vào Git).

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/config-drifts/{driftId}:resolve`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-022.

**Tham số.** `tenantCode` (path, string, bắt buộc); `driftId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DriftResolveRequest`; trường bắt buộc: `action`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ConfigDrift`; trường bắt buộc: `driftId`, `status`, `detectedAt`, `detectedBy`, `differences`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-025 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `REAPPLY` áp lại giá trị ở Git, `ACCEPT` nhận giá trị thực vào Git.
:::

#### API-20-047 · Đề nghị chuyển chế độ cách ly

::: dac-ta
**Mục đích.** Đề nghị chuyển chế độ cách ly.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/isolation-changes`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-025.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IsolationChangeCreate`; trường bắt buộc: `targetMode`, `reason`, `ticketRef`, `decisionDocNo`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-007, ERR-20-009, ERR-20-010, ERR-20-028, ERR-20-059 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo đề nghị `ISOLATION_CHANGE` cần duyệt bốn mắt (API-20-076); thực hiện bằng API-20-079 trong cửa sổ bảo trì (ERR-20-028, 059).
:::

### Hạn mức và sử dụng

#### API-20-048 · Hạn mức hợp đồng, ghi đè, hiệu lực

::: dac-ta
**Mục đích.** Hạn mức hợp đồng, ghi đè, hiệu lực.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/quotas`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-026, FR-20-032.

**Tham số.** `tenantCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantQuotas`; trường bắt buộc: `tenantCode`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạn mức hợp đồng, ghi đè, hiệu lực.
:::

#### API-20-049 · Đặt hạn mức hợp đồng ban đầu hoặc tăng trong trần

::: dac-ta
**Mục đích.** Đặt hạn mức hợp đồng ban đầu hoặc tăng trong trần.

**Phương thức, đường dẫn.** `PUT /api/platform/v1/tenants/{tenantCode}/quotas`.

**Quyền.** `PERM-20-quota`.

**FR hiện thực.** FR-20-026.

**Tham số.** `tenantCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `QuotaSetRequest`; trường bắt buộc: `items`, `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantQuotas`; trường bắt buộc: `tenantCode`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-029, ERR-20-030, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đặt hạn mức hợp đồng ban đầu hoặc tăng trong trần nền tảng; hạ hạn mức phải đi qua API-20-050. Ngoài miền trả ERR-20-029.
:::

#### API-20-050 · Đề nghị đổi hạn mức có duyệt

::: dac-ta
**Mục đích.** Đề nghị đổi hạn mức có duyệt.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/quota-change-requests`.

**Quyền.** `PERM-20-quota`.

**FR hiện thực.** FR-20-027.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `QuotaChangeCreate`; trường bắt buộc: `items`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `QuotaChangeRequest`; trường bắt buộc: `requestId`, `tenantCode`, `status`, `items`, `requestedBy`, `requestedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-029 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạ dưới mức đang dùng cần bốn mắt (ERR-20-030, 007). Sau khi duyệt, hạn mức đẩy xuống PH-03, PH-04, PH-10, PH-12 và phát EVT-20-05.
:::

#### API-20-051 · Các đề nghị đổi hạn mức

::: dac-ta
**Mục đích.** Các đề nghị đổi hạn mức.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/quota-change-requests`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-027.

**Tham số.** `tenantCode` (path, string, bắt buộc); `status` (query, RequestStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaChangeRequestPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Các đề nghị đổi hạn mức.
:::

#### API-20-052 · Duyệt đề nghị đổi hạn mức

::: dac-ta
**Mục đích.** Duyệt đề nghị đổi hạn mức.

**Phương thức, đường dẫn.** `POST /api/platform/v1/quota-change-requests/{requestId}:approve`.

**Quyền.** `PERM-20-approve`.

**FR hiện thực.** FR-20-027.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `QuotaChangeRequest`; trường bắt buộc: `requestId`, `tenantCode`, `status`, `items`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-029, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người đề nghị (ERR-20-007).
:::

#### API-20-053 · Từ chối đề nghị đổi hạn mức

::: dac-ta
**Mục đích.** Từ chối đề nghị đổi hạn mức.

**Phương thức, đường dẫn.** `POST /api/platform/v1/quota-change-requests/{requestId}:reject`.

**Quyền.** `PERM-20-approve`.

**FR hiện thực.** FR-20-027.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `QuotaChangeRequest`; trường bắt buộc: `requestId`, `tenantCode`, `status`, `items`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-029, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối đề nghị đổi hạn mức. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-054 · Ghi đè hạn mức tạm thời

::: dac-ta
**Mục đích.** Ghi đè hạn mức tạm thời.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/quota-overrides`.

**Quyền.** `PERM-20-quota`.

**FR hiện thực.** FR-20-032.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OverrideCreate`; trường bắt buộc: `resource`, `value`, `validFrom`, `validTo`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `QuotaOverride`; trường bắt buộc: `overrideId`, `tenantCode`, `resource`, `value`, `validFrom`, `validTo`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-029, ERR-20-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi đè tạm thời, tối đa `20.quota.override-max-days` ngày (ERR-20-031); hết hạn tự động trở về mức hợp đồng.
:::

#### API-20-055 · Thu hồi ghi đè trước hạn

::: dac-ta
**Mục đích.** Thu hồi ghi đè trước hạn.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/quota-overrides/{overrideId}:revoke`.

**Quyền.** `PERM-20-quota`.

**FR hiện thực.** FR-20-032.

**Tham số.** `tenantCode` (path, string, bắt buộc); `overrideId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `QuotaOverride`; trường bắt buộc: `overrideId`, `tenantCode`, `resource`, `value`, `validFrom`, `validTo`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-010, ERR-20-029, ERR-20-031 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thu hồi ghi đè trước hạn.
:::

#### API-20-056 · Sử dụng tài nguyên toàn nền tảng

::: dac-ta
**Mục đích.** Sử dụng tài nguyên toàn nền tảng.

**Phương thức, đường dẫn.** `GET /api/platform/v1/usage`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-030.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `granularity` (query, UsageGranularity, tùy chọn); `resource` (query, array, tùy chọn); `tenantCode` (query, array, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageResponse`; trường bắt buộc: `from`, `to`, `granularity`, `series`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004, ERR-20-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ dữ liệu tổng hợp theo hạn mức, không chứa dữ liệu nghiệp vụ của tỉnh; `ranking` xếp tenant theo `percent`. Khoảng tối đa 400 ngày (ERR-20-032).
:::

#### API-20-057 · Sử dụng tài nguyên của một tenant

::: dac-ta
**Mục đích.** Sử dụng tài nguyên của một tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/usage`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-030.

**Tham số.** `tenantCode` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `granularity` (query, UsageGranularity, tùy chọn); `resource` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageResponse`; trường bắt buộc: `from`, `to`, `granularity`, `series`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuỗi sử dụng của một tenant; `granularity = HOUR` chỉ khi khoảng không quá 7 ngày.
:::

#### API-20-058 · Cảnh báo hạn mức toàn nền tảng

::: dac-ta
**Mục đích.** Cảnh báo hạn mức toàn nền tảng.

**Phương thức, đường dẫn.** `GET /api/platform/v1/quota-alerts`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-029.

**Tham số.** `tenantCode` (query, string, tùy chọn); `resource` (query, QuotaResource, tùy chọn); `alertLevel` (query, QuotaAlertLevel, tùy chọn); `state` (query, AlertState, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaAlertPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cảnh báo hạn mức toàn nền tảng.
:::

#### API-20-059 · Xác nhận đã xử lý cảnh báo

::: dac-ta
**Mục đích.** Xác nhận đã xử lý cảnh báo.

**Phương thức, đường dẫn.** `POST /api/platform/v1/quota-alerts/{alertId}:acknowledge`.

**Quyền.** `PERM-20-quota`.

**FR hiện thực.** FR-20-029.

**Tham số.** `alertId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AcknowledgeRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `QuotaAlert`; trường bắt buộc: `alertId`, `tenantCode`, `resource`, `alertLevel`, `state`, `raisedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xác nhận đã xử lý; cảnh báo tự đóng khi sử dụng xuống dưới `20.quota.alert-reset-percent`.
:::

#### API-20-060 · Lập báo cáo sử dụng theo kỳ

::: dac-ta
**Mục đích.** Lập báo cáo sử dụng theo kỳ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/usage-reports`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-031.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UsageReportCreate`; trường bắt buộc: `scope`, `period`, `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `UsageReport`; trường bắt buộc: `reportId`, `scope`, `period`, `format`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-009, ERR-20-066 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bất đồng bộ, trả `202` kèm `reportId`; theo dõi bằng API-20-061 và tải bằng API-20-062. Không lập được trả ERR-20-066.
:::

#### API-20-061 · Danh sách báo cáo sử dụng

::: dac-ta
**Mục đích.** Danh sách báo cáo sử dụng.

**Phương thức, đường dẫn.** `GET /api/platform/v1/usage-reports`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-031.

**Tham số.** `scope` (query, string, tùy chọn); `status` (query, UsageReportStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageReportPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách báo cáo sử dụng.
:::

#### API-20-062 · Tải tệp báo cáo

::: dac-ta
**Mục đích.** Tải tệp báo cáo.

**Phương thức, đường dẫn.** `GET /api/platform/v1/usage-reports/{reportId}/file`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-031.

**Tham số.** `reportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `Content-Disposition`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả tệp báo cáo (`XLSX`, `CSV` hoặc `PDF` theo `format`); liên kết hết hạn trả `410`.
:::

### Phân hệ và tính năng

#### API-20-063 · Danh mục phân hệ và ma trận phụ thuộc

::: dac-ta
**Mục đích.** Danh mục phân hệ và ma trận phụ thuộc.

**Phương thức, đường dẫn.** `GET /api/platform/v1/modules`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-033.

**Tham số.** `wave` (query, integer, tùy chọn); `core` (query, boolean, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModulePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh mục phân hệ và ma trận phụ thuộc (`REQUIRED`, `OPTIONAL`).
:::

#### API-20-064 · Phân hệ theo tenant

::: dac-ta
**Mục đích.** Phân hệ theo tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/modules`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-034, FR-20-035.

**Tham số.** `tenantCode` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantModulePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân hệ theo tenant.
:::

#### API-20-065 · Bật phân hệ

::: dac-ta
**Mục đích.** Bật phân hệ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:enable`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-034.

**Tham số.** `tenantCode` (path, string, bắt buộc); `moduleCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TenantModule`; trường bắt buộc: `moduleCode`, `state`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-033, ERR-20-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bật phân hệ: kiểm phụ thuộc `REQUIRED` (ERR-20-033), phát EVT-20-07, chờ phân hệ báo xong; trạng thái `ENABLING` rồi `ENABLED`.
:::

#### API-20-066 · Tắt phân hệ

::: dac-ta
**Mục đích.** Tắt phân hệ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:disable`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-035.

**Tham số.** `tenantCode` (path, string, bắt buộc); `moduleCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TenantModule`; trường bắt buộc: `moduleCode`, `state`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-034, ERR-20-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tắt phân hệ: phân hệ lõi trả ERR-20-035, phân hệ còn bị phụ thuộc trả ERR-20-034; phát EVT-20-08.
:::

#### API-20-067 · Tạm ngừng phân hệ

::: dac-ta
**Mục đích.** Tạm ngừng phân hệ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:suspend`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-035.

**Tham số.** `tenantCode` (path, string, bắt buộc); `moduleCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TenantModule`; trường bắt buộc: `moduleCode`, `state`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-034, ERR-20-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạm ngừng phân hệ (`SUSPENDED`); giao diện hiện chế độ tạm ngừng, API của phân hệ trả ERR-20-103.
:::

#### API-20-068 · Tiếp tục phân hệ tạm ngừng

::: dac-ta
**Mục đích.** Tiếp tục phân hệ tạm ngừng.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:resume`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-035.

**Tham số.** `tenantCode` (path, string, bắt buộc); `moduleCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TenantModule`; trường bắt buộc: `moduleCode`, `state`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-034, ERR-20-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiếp tục phân hệ đang `SUSPENDED`.
:::

#### API-20-069 · Cờ tính năng của tenant

::: dac-ta
**Mục đích.** Cờ tính năng của tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/feature-flags`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-036.

**Tham số.** `tenantCode` (path, string, bắt buộc); `moduleCode` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FeatureFlagPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cờ tính năng của tenant.
:::

#### API-20-070 · Đặt cờ tính năng

::: dac-ta
**Mục đích.** Đặt cờ tính năng.

**Phương thức, đường dẫn.** `PUT /api/platform/v1/tenants/{tenantCode}/feature-flags/{flagCode}`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-036.

**Tham số.** `tenantCode` (path, string, bắt buộc); `flagCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FlagSetRequest`; trường bắt buộc: `enabled`, `reason`, `ticketRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FeatureFlag`; trường bắt buộc: `flagCode`, `enabled`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-036, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cờ không áp dụng được cho tenant trả ERR-20-036.
:::

### Vòng đời tenant

#### API-20-071 · Lập đề nghị vòng đời (`SUSPEND`, `RESUME`, `TERMINATE`)

::: dac-ta
**Mục đích.** Lập đề nghị vòng đời (`SUSPEND`, `RESUME`, `TERMINATE`).

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/lifecycle-requests`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-038, FR-20-039, FR-20-040.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LifecycleRequestCreate`; trường bắt buộc: `requestType`, `reasonText`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-008, ERR-20-009, ERR-20-010, ERR-20-037, ERR-20-038 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `requestType` nhận `SUSPEND`, `RESUME`, `TERMINATE` (đổi cách ly dùng API-20-047, hạ hạn mức dùng API-20-050). Chấm dứt cần `plannedAt` sau thời gian nguội `20.terminate.cooling-days` (ERR-20-038) và cần gói bàn giao khi `exportRequired = true`.
:::

#### API-20-072 · Đề nghị vòng đời của tenant

::: dac-ta
**Mục đích.** Đề nghị vòng đời của tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/lifecycle-requests`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-043.

**Tham số.** `tenantCode` (path, string, bắt buộc); `type` (query, array, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LifecycleRequestPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đề nghị vòng đời của tenant.
:::

#### API-20-073 · Hộp duyệt đề nghị toàn nền tảng

::: dac-ta
**Mục đích.** Hộp duyệt đề nghị toàn nền tảng.

**Phương thức, đường dẫn.** `GET /api/platform/v1/lifecycle-requests`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-040.

**Tham số.** `status` (query, array, tùy chọn); `requestType` (query, array, tùy chọn); `tenantCode` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LifecycleRequestPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hộp duyệt toàn nền tảng: mặc định đề nghị `PENDING_APPROVAL`; loại trừ đề nghị do chính người gọi lập.
:::

#### API-20-074 · Chi tiết đề nghị

::: dac-ta
**Mục đích.** Chi tiết đề nghị.

**Phương thức, đường dẫn.** `GET /api/platform/v1/lifecycle-requests/{requestId}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-040, FR-20-043.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết đề nghị.
:::

#### API-20-075 · Gửi duyệt đề nghị

::: dac-ta
**Mục đích.** Gửi duyệt đề nghị.

**Phương thức, đường dẫn.** `POST /api/platform/v1/lifecycle-requests/{requestId}:submit`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-040.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-037, ERR-20-038, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi duyệt đề nghị `DRAFT`; chuyển `PENDING_APPROVAL`.
:::

#### API-20-076 · Duyệt đề nghị (bốn mắt)

::: dac-ta
**Mục đích.** Duyệt đề nghị (bốn mắt).

**Phương thức, đường dẫn.** `POST /api/platform/v1/lifecycle-requests/{requestId}:approve`.

**Quyền.** `PERM-20-approve`.

**FR hiện thực.** FR-20-025, FR-20-040.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-028, ERR-20-037, ERR-20-038, ERR-20-059, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt bốn mắt: người duyệt khác người lập, gửi (ERR-20-007). Phát EVT-20-04 khi thực hiện.
:::

#### API-20-077 · Từ chối đề nghị

::: dac-ta
**Mục đích.** Từ chối đề nghị.

**Phương thức, đường dẫn.** `POST /api/platform/v1/lifecycle-requests/{requestId}:reject`.

**Quyền.** `PERM-20-approve`.

**FR hiện thực.** FR-20-025, FR-20-040.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-028, ERR-20-037, ERR-20-038, ERR-20-059, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối đề nghị. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-078 · Rút đề nghị

::: dac-ta
**Mục đích.** Rút đề nghị.

**Phương thức, đường dẫn.** `POST /api/platform/v1/lifecycle-requests/{requestId}:cancel`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-040.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-037, ERR-20-038, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Rút đề nghị. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-079 · Thực hiện đề nghị đã duyệt

::: dac-ta
**Mục đích.** Thực hiện đề nghị đã duyệt.

**Phương thức, đường dẫn.** `POST /api/platform/v1/lifecycle-requests/{requestId}:execute`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-025, FR-20-038, FR-20-039, FR-20-042.

**Tham số.** `requestId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExecuteLifecycleRequest`; trường bắt buộc: `confirmTenantCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `LifecycleRequest`; trường bắt buộc: `requestId`, `tenantCode`, `requestType`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-008, ERR-20-009, ERR-20-028, ERR-20-037, ERR-20-038, ERR-20-059, ERR-20-062, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thực hiện đề nghị `APPROVED`. `SUSPEND` đặt tenant `SUSPENDED` và gọi PH-12 (API-12-084); `TERMINATE` yêu cầu đã bàn giao, hết thời gian nguội và gõ lại `confirmTenantCode`; kết thúc khi PH-09 xác nhận xóa mật mã (EVT-09-21). Trả `202`.
:::

#### API-20-080 · Yêu cầu gói bàn giao dữ liệu

::: dac-ta
**Mục đích.** Yêu cầu gói bàn giao dữ liệu.

**Phương thức, đường dẫn.** `POST /api/platform/v1/tenants/{tenantCode}/export-packages`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-041.

**Tham số.** `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportPackageCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportPackage`; trường bắt buộc: `packageId`, `tenantCode`, `status`, `items`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-010, ERR-20-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bất đồng bộ; thu thập từng phân hệ `exportParticipant` qua API-20-168. Phát EVT-20-16 khi sẵn sàng.
:::

#### API-20-081 · Danh sách gói bàn giao

::: dac-ta
**Mục đích.** Danh sách gói bàn giao.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/export-packages`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-041.

**Tham số.** `tenantCode` (path, string, bắt buộc); `status` (query, ExportPackageStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportPackagePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `410`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách gói bàn giao.
:::

#### API-20-082 · Chi tiết gói, tiến độ theo phân hệ

::: dac-ta
**Mục đích.** Chi tiết gói, tiến độ theo phân hệ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/export-packages/{packageId}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-041.

**Tham số.** `packageId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportPackage`; trường bắt buộc: `packageId`, `tenantCode`, `status`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`; mã lỗi của thao tác: ERR-20-002, ERR-20-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết gói, tiến độ theo phân hệ.
:::

#### API-20-083 · Cấp liên kết tải có thời hạn

::: dac-ta
**Mục đích.** Cấp liên kết tải có thời hạn.

**Phương thức, đường dẫn.** `POST /api/platform/v1/export-packages/{packageId}:issue-link`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-041.

**Tham số.** `packageId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IssueLinkRequest`; trường bắt buộc: `recipientEmail`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ExportDownloadLink`; trường bắt buộc: `packageId`, `downloadUrl`, `expiresAt`, `recipientEmail`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cấp liên kết tải có thời hạn tối đa 72 giờ gửi tới `recipientEmail`; gói hết hạn trả `410` ERR-20-039. Người xác nhận bàn giao khác người duyệt chấm dứt (ERR-20-007).
:::

#### API-20-084 · Ghi nhận đã bàn giao, biên bản

::: dac-ta
**Mục đích.** Ghi nhận đã bàn giao, biên bản.

**Phương thức, đường dẫn.** `POST /api/platform/v1/export-packages/{packageId}:confirm-delivery`.

**Quyền.** `PERM-20-lifecycle`.

**FR hiện thực.** FR-20-041.

**Tham số.** `packageId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConfirmDeliveryRequest`; trường bắt buộc: `handoverDocFileId`, `deliveredAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ExportPackage`; trường bắt buộc: `packageId`, `tenantCode`, `status`, `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi nhận đã bàn giao kèm biên bản; điều kiện để thực hiện chấm dứt.
:::

#### API-20-085 · Lịch sử trạng thái và quyết định

::: dac-ta
**Mục đích.** Lịch sử trạng thái và quyết định.

**Phương thức, đường dẫn.** `GET /api/platform/v1/tenants/{tenantCode}/status-history`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-043, FR-20-044.

**Tham số.** `tenantCode` (path, string, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `type` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StatusHistoryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch sử trạng thái kèm quyết định, nguyên nhân và trạng thái thông báo cho đầu mối (FR-20-044).
:::

### Sáp nhập tenant

#### API-20-086 · Lập kế hoạch sáp nhập `DRAFT`

::: dac-ta
**Mục đích.** Lập kế hoạch sáp nhập `DRAFT`.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-045.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MergePlanCreate`; trường bắt buộc: `sourceTenants`, `targetTenant`, `decisionDocNo`, `decisionDocDate`, `effectiveDate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-004, ERR-20-007, ERR-20-009, ERR-20-040, ERR-20-041, ERR-20-043, ERR-20-045 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lập kế hoạch `DRAFT`: kiểm tenant nguồn, đích không thuộc kế hoạch khác (ERR-20-041), `transitionMonths` không vượt `20.merge.transition-max-months` (ERR-20-045).
:::

#### API-20-087 · Danh sách sáp nhập

::: dac-ta
**Mục đích.** Danh sách sáp nhập.

**Phương thức, đường dẫn.** `GET /api/platform/v1/merge-plans`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-045.

**Tham số.** `status` (query, array, tùy chọn); `tenantCode` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MergePlanPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách sáp nhập.
:::

#### API-20-088 · Chi tiết kế hoạch, tiến độ

::: dac-ta
**Mục đích.** Chi tiết kế hoạch, tiến độ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/merge-plans/{mergePlanId}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-045, FR-20-048.

**Tham số.** `mergePlanId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết kế hoạch kèm `dryRun`, `progress`; TA của hai tỉnh chỉ đọc phần tỉnh mình.
:::

#### API-20-089 · Sửa kế hoạch `DRAFT`

::: dac-ta
**Mục đích.** Sửa kế hoạch `DRAFT`.

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/merge-plans/{mergePlanId}`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-045.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MergePlanUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-007, ERR-20-040, ERR-20-041, ERR-20-043, ERR-20-045, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa kế hoạch `DRAFT`. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-090 · Gửi duyệt kế hoạch

::: dac-ta
**Mục đích.** Gửi duyệt kế hoạch.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:submit`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-045.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-040, ERR-20-041, ERR-20-043, ERR-20-045, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi duyệt kế hoạch. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-091 · Duyệt kế hoạch (bốn mắt)

::: dac-ta
**Mục đích.** Duyệt kế hoạch (bốn mắt).

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:approve`.

**Quyền.** `PERM-20-approve`.

**FR hiện thực.** FR-20-045.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecisionRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-040, ERR-20-041, ERR-20-043, ERR-20-045, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Duyệt bốn mắt kế hoạch sáp nhập: chạy thử phải đạt và không cũ (ERR-20-043); người duyệt khác người lập (ERR-20-007).
:::

#### API-20-092 · Từ chối kế hoạch

::: dac-ta
**Mục đích.** Từ chối kế hoạch.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:reject`.

**Quyền.** `PERM-20-approve`.

**FR hiện thực.** FR-20-045.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-040, ERR-20-041, ERR-20-043, ERR-20-045, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối kế hoạch. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-093 · Hủy kế hoạch trước cutover

::: dac-ta
**Mục đích.** Hủy kế hoạch trước cutover.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:cancel`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-045.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-009, ERR-20-040, ERR-20-041, ERR-20-043, ERR-20-045, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy kế hoạch trước cutover. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-094 · Bảng ánh xạ

::: dac-ta
**Mục đích.** Bảng ánh xạ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/merge-plans/{mergePlanId}/mappings`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-046.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `mappingType` (query, MergeMappingType, tùy chọn); `status` (query, MappingStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MappingPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bảng ánh xạ.
:::

#### API-20-095 · Sinh gợi ý ánh xạ tự động

::: dac-ta
**Mục đích.** Sinh gợi ý ánh xạ tự động.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}/mappings:suggest`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-046.

**Tham số.** `mergePlanId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MappingSuggestResult`; trường bắt buộc: `created`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-006, ERR-20-042, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sinh gợi ý ánh xạ tự động theo mã, đường dẫn, tên; chỉ tạo dòng `PROPOSED`, không ghi đè dòng đã xác nhận.
:::

#### API-20-096 · Sửa một dòng ánh xạ

::: dac-ta
**Mục đích.** Sửa một dòng ánh xạ.

**Phương thức, đường dẫn.** `PUT /api/platform/v1/merge-plans/{mergePlanId}/mappings/{mappingId}`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-046.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `mappingId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MappingUpdate`; trường bắt buộc: `action`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MappingItem`; trường bắt buộc: `mappingId`, `mappingType`, `sourceCode`, `action`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-042, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa một dòng ánh xạ. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-097 · Chạy thử sáp nhập

::: dac-ta
**Mục đích.** Chạy thử sáp nhập.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:dry-run`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-047.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DryRunRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bất đồng bộ; kết quả ở `dryRun` của API-20-088. Ánh xạ chưa đủ trả ERR-20-042; PH-18 chạy chuyển thử và báo qua API-20-167.
:::

#### API-20-098 · Bắt đầu chuyển dữ liệu

::: dac-ta
**Mục đích.** Bắt đầu chuyển dữ liệu.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:start`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-048.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-043, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát EVT-20-10, gọi PH-18 `POST /api/ops/v1/merge-transfers` cho từng phân hệ; kế hoạch sang `TRANSFERRING`. Trả `202`.
:::

#### API-20-099 · Tiến độ theo phân hệ

::: dac-ta
**Mục đích.** Tiến độ theo phân hệ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/merge-plans/{mergePlanId}/participants`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-048.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParticipantPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiến độ chuyển dữ liệu theo phân hệ: số xuất, nhập, kiểm đếm, xung đột. Kiểm đếm lệch ghi ERR-20-113.
:::

#### API-20-100 · Chạy lại chuyển của một phân hệ

::: dac-ta
**Mục đích.** Chạy lại chuyển của một phân hệ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}/participants/{module}:retry`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-048.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `module` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergeParticipantRun`; trường bắt buộc: `module`, `phase`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-043 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy lại chuyển của một phân hệ.
:::

#### API-20-101 · Danh sách xung đột

::: dac-ta
**Mục đích.** Danh sách xung đột.

**Phương thức, đường dẫn.** `GET /api/platform/v1/merge-plans/{mergePlanId}/conflicts`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-049.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `state` (query, ConflictState, tùy chọn); `mappingType` (query, MergeMappingType, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConflictPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách xung đột.
:::

#### API-20-102 · Quyết định một xung đột

::: dac-ta
**Mục đích.** Quyết định một xung đột.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}/conflicts/{conflictId}:resolve`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-049.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `conflictId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConflictResolveRequest`; trường bắt buộc: `resolution`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergeConflict`; trường bắt buộc: `conflictId`, `mappingType`, `sourceCode`, `conflictKind`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-044, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quyết định một xung đột; `RENAME_SOURCE` cần `newCode`.
:::

#### API-20-103 · Quyết định hàng loạt

::: dac-ta
**Mục đích.** Quyết định hàng loạt.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}/conflicts:resolve-batch`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-049.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BatchResolveRequest`; trường bắt buộc: `conflictIds`, `resolution`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `BatchResolveResult`; trường bắt buộc: `resolved`, `failed`, `openRemaining`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quyết định tối đa 200 xung đột cùng cách giải quyết; xung đột không quyết định được nằm ở `failed`.
:::

#### API-20-104 · Chuyển định danh, cấp song song thông tin xác thực

::: dac-ta
**Mục đích.** Chuyển định danh, cấp song song thông tin xác thực.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:transfer-identity`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-050.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TransferIdentityRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-044, ERR-20-062, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển định danh qua PH-12 (API-12-045, 046) và cấp song song thông tin xác thực HTTT mới; không trả giá trị bí mật. Còn xung đột mở trả ERR-20-044.
:::

#### API-20-105 · Trạng thái thông tin xác thực song song của HTTT

::: dac-ta
**Mục đích.** Trạng thái thông tin xác thực song song của HTTT.

**Phương thức, đường dẫn.** `GET /api/platform/v1/merge-plans/{mergePlanId}/credentials`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-050.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái thông tin xác thực song song của từng HTTT; không bao giờ trả giá trị bí mật.
:::

#### API-20-106 · Chuyển tiếp, nguồn sang `MERGED`

::: dac-ta
**Mục đích.** Chuyển tiếp, nguồn sang `MERGED`.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:cutover`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-051.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CutoverRequest`; trường bắt buộc: `confirmCode`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-044, ERR-20-059, ERR-20-115, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển tiếp: tenant nguồn sang `MERGED` chỉ đọc, bật chuyển tiếp lượt gọi có tiêu đề `Deprecation` và `Sunset`, phát EVT-20-11. Yêu cầu gõ lại `confirmCode`.
:::

#### API-20-107 · Gia hạn thời gian chuyển tiếp

::: dac-ta
**Mục đích.** Gia hạn thời gian chuyển tiếp.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:extend-transition`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-052.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExtendTransitionRequest`; trường bắt buộc: `extendMonths`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-045, ERR-20-046, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gia hạn tối đa đến `20.merge.transition-max-months` (ERR-20-045).
:::

#### API-20-108 · Kết thúc sáp nhập

::: dac-ta
**Mục đích.** Kết thúc sáp nhập.

**Phương thức, đường dẫn.** `POST /api/platform/v1/merge-plans/{mergePlanId}:complete`.

**Quyền.** `PERM-20-merge`.

**FR hiện thực.** FR-20-052.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CompleteMergeRequest`; trường bắt buộc: `confirmCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `MergePlan`; trường bắt buộc: `mergePlanId`, `status`, `sourceTenants`, `targetTenant`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-045, ERR-20-046, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết thúc sau thời gian chuyển tiếp (ERR-20-046), phát EVT-20-12; tenant nguồn giữ chỉ đọc theo Q20-01.
:::

### Phát hành sản phẩm

#### API-20-109 · Danh mục phiên bản sản phẩm

::: dac-ta
**Mục đích.** Danh mục phiên bản sản phẩm.

**Phương thức, đường dẫn.** `GET /api/platform/v1/releases`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-059.

**Tham số.** `status` (query, array, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReleasePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh mục phiên bản sản phẩm; `20.release.supported-minors` quyết định bản còn được hỗ trợ.
:::

#### API-20-110 · Đăng ký phiên bản `DRAFT`

::: dac-ta
**Mục đích.** Đăng ký phiên bản `DRAFT`.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-059.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReleaseCreate`; trường bắt buộc: `releaseVersion`, `components`, `releaseNotes`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Release`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-053 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đăng ký phiên bản `DRAFT` kèm thành phần, thay đổi lược đồ `EXPAND` hoặc `CONTRACT`. Phiên bản theo SemVer (ERR-20-053).
:::

#### API-20-111 · Chi tiết phiên bản, thành phần, tenant đang chạy

::: dac-ta
**Mục đích.** Chi tiết phiên bản, thành phần, tenant đang chạy.

**Phương thức, đường dẫn.** `GET /api/platform/v1/releases/{releaseVersion}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-059.

**Tham số.** `releaseVersion` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReleaseDetail`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết phiên bản, thành phần, tenant đang chạy.
:::

#### API-20-112 · Sửa ghi chú phát hành

::: dac-ta
**Mục đích.** Sửa ghi chú phát hành.

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/releases/{releaseVersion}`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-059.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReleaseUpdate`; trường bắt buộc: `releaseNotes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Release`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-053, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa ghi chú phát hành. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-113 · Đưa phiên bản lên kênh `PREVIEW`

::: dac-ta
**Mục đích.** Đưa phiên bản lên kênh `PREVIEW`.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases/{releaseVersion}:preview`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-060.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Release`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-054, ERR-20-061, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đưa lên kênh `PREVIEW`; phát EVT-20-14.
:::

#### API-20-114 · Nâng phiên bản lên `STABLE`

::: dac-ta
**Mục đích.** Nâng phiên bản lên `STABLE`.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases/{releaseVersion}:promote`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-060.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Release`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-054, ERR-20-061, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ nâng lên `STABLE` sau ít nhất `20.release.stable-soak-days` ngày chạy ở tenant thí điểm (ERR-20-054). Phát EVT-20-14.
:::

#### API-20-115 · Đánh dấu ngoài hỗ trợ

::: dac-ta
**Mục đích.** Đánh dấu ngoài hỗ trợ.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases/{releaseVersion}:deprecate`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-059.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Release`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-053, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đánh dấu ngoài hỗ trợ. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-116 · Rút phiên bản lỗi

::: dac-ta
**Mục đích.** Rút phiên bản lỗi.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases/{releaseVersion}:withdraw`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-059.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonTicket`; trường bắt buộc: `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Release`; trường bắt buộc: `releaseVersion`, `status`, `breakingChange`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-009, ERR-20-053, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Rút phiên bản lỗi; tenant đang chạy phiên bản này cần kế hoạch quay lui.
:::

#### API-20-117 · Đổi kênh, môi trường đăng ký của tenant

::: dac-ta
**Mục đích.** Đổi kênh, môi trường đăng ký của tenant.

**Phương thức, đường dẫn.** `PUT /api/platform/v1/tenants/{tenantCode}/release-subscription`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-060.

**Tham số.** `tenantCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubscriptionSetRequest`; trường bắt buộc: `channel`, `environment`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReleaseSubscription`; trường bắt buộc: `tenantCode`, `channel`, `environment`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-010, ERR-20-054, ERR-20-061, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tenant `PROD` không đăng ký kênh `PREVIEW` (Q20-09); đổi kênh khi đang nâng cấp trả ERR-20-061.
:::

#### API-20-118 · Lập kế hoạch nâng cấp theo sóng

::: dac-ta
**Mục đích.** Lập kế hoạch nâng cấp theo sóng.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases/{releaseVersion}/upgrade-plans`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-061.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UpgradePlanCreate`; trường bắt buộc: `waves`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-009, ERR-20-055, ERR-20-056, ERR-20-059 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lập kế hoạch theo sóng với `soakHours` giữa các sóng; phiên bản không dùng được trả ERR-20-055. Bản khẩn cấp dùng `emergency = true` và báo trước `20.upgrade.emergency-notice-hours` giờ.
:::

#### API-20-119 · Chi tiết kế hoạch, sóng, tiến độ

::: dac-ta
**Mục đích.** Chi tiết kế hoạch, sóng, tiến độ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/upgrade-plans/{planId}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-061, FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết kế hoạch, sóng, tiến độ.
:::

#### API-20-120 · Sửa kế hoạch `DRAFT`

::: dac-ta
**Mục đích.** Sửa kế hoạch `DRAFT`.

**Phương thức, đường dẫn.** `PATCH /api/platform/v1/upgrade-plans/{planId}`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-061.

**Tham số.** `planId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UpgradePlanUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-055, ERR-20-056, ERR-20-059, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa kế hoạch `DRAFT`. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-121 · Lên lịch kế hoạch

::: dac-ta
**Mục đích.** Lên lịch kế hoạch.

**Phương thức, đường dẫn.** `POST /api/platform/v1/upgrade-plans/{planId}:schedule`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-061.

**Tham số.** `planId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-055, ERR-20-056, ERR-20-059, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lên lịch: mỗi tenant được xếp vào cửa sổ bảo trì của tỉnh (ERR-20-059).
:::

#### API-20-122 · Dừng sóng

::: dac-ta
**Mục đích.** Dừng sóng.

**Phương thức, đường dẫn.** `POST /api/platform/v1/upgrade-plans/{planId}:pause`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-057, ERR-20-058, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PO được dừng sóng. Sóng cũng tự dừng khi tỷ lệ lỗi vượt `20.release.wave-error-threshold-percent` (ERR-20-057).
:::

#### API-20-123 · Tiếp tục sóng

::: dac-ta
**Mục đích.** Tiếp tục sóng.

**Phương thức, đường dẫn.** `POST /api/platform/v1/upgrade-plans/{planId}:resume`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-057, ERR-20-058, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiếp tục sóng. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-124 · Quay lui tenant đã nâng cấp

::: dac-ta
**Mục đích.** Quay lui tenant đã nâng cấp.

**Phương thức, đường dẫn.** `POST /api/platform/v1/upgrade-plans/{planId}:rollback`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RollbackRequest`; trường bắt buộc: `tenantCodes`, `reason`, `ticketRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-057, ERR-20-058, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quay lui các tenant đã nâng cấp; không quay lui được khi phiên bản có thay đổi `CONTRACT` (ERR-20-058).
:::

#### API-20-125 · Hủy kế hoạch chưa chạy

::: dac-ta
**Mục đích.** Hủy kế hoạch chưa chạy.

**Phương thức, đường dẫn.** `POST /api/platform/v1/upgrade-plans/{planId}:cancel`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `UpgradePlan`; trường bắt buộc: `planId`, `releaseVersion`, `channel`, `status`, `waves`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-057, ERR-20-058, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy kế hoạch chưa chạy. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-126 · Nâng cấp theo tenant

::: dac-ta
**Mục đích.** Nâng cấp theo tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/upgrade-plans/{planId}/tenant-upgrades`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc); `status` (query, TenantUpgradeStatus, tùy chọn); `waveNo` (query, integer, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantUpgradePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nâng cấp theo tenant.
:::

#### API-20-127 · Thử lại nâng cấp một tenant

::: dac-ta
**Mục đích.** Thử lại nâng cấp một tenant.

**Phương thức, đường dẫn.** `POST /api/platform/v1/upgrade-plans/{planId}/tenant-upgrades/{tenantCode}:retry`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-062.

**Tham số.** `planId` (path, string, bắt buộc); `tenantCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TenantUpgrade`; trường bắt buộc: `tenantCode`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-057, ERR-20-058 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thử lại nâng cấp một tenant `FAILED`.
:::

#### API-20-128 · Gửi thông báo phát hành, lịch bảo trì

::: dac-ta
**Mục đích.** Gửi thông báo phát hành, lịch bảo trì.

**Phương thức, đường dẫn.** `POST /api/platform/v1/releases/{releaseVersion}:announce`.

**Quyền.** `PERM-20-release`.

**FR hiện thực.** FR-20-063.

**Tham số.** `releaseVersion` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AnnounceRequest`; trường bắt buộc: `audience`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `AnnounceResult`; trường bắt buộc: `announcementId`, `recipients`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi thông báo tới TA hoặc mọi người dùng qua PH-18; bất đồng bộ.
:::

### Quản trị nền tảng

#### API-20-129 · Bảng điều khiển nền tảng đa tenant

::: dac-ta
**Mục đích.** Bảng điều khiển nền tảng đa tenant.

**Phương thức, đường dẫn.** `GET /api/platform/v1/dashboard`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-067.

**Tham số.** `environment` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlatformDashboard`; trường bắt buộc: `generatedAt`, `environment`, `tenantsByStatus`, `runsInProgress`, `openAlerts`, `driftedTenants`, `upgrades`, `mergesInProgress`, `capacity`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-20-004, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bảng điều khiển tổng hợp: số tenant theo trạng thái, lần chạy, cảnh báo, lệch cấu hình, nâng cấp, sáp nhập, kiểm thử rò rỉ, sức chứa, KPI-12.
:::

#### API-20-130 · Nhật ký kiểm toán PH-20 toàn nền tảng

::: dac-ta
**Mục đích.** Nhật ký kiểm toán PH-20 toàn nền tảng.

**Phương thức, đường dẫn.** `GET /api/platform/v1/audit-events`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-068.

**Tham số.** `tenantCode` (query, string, tùy chọn); `actor` (query, string, tùy chọn); `action` (query, array, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `ticketRef` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditEventPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-20-004, ERR-20-032, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký kiểm toán thao tác PH-20 toàn nền tảng (PA, PAU); khoảng tối đa 366 ngày (ERR-20-032).
:::

#### API-20-131 · Giá trị hiệu lực của tham số `20.*`

::: dac-ta
**Mục đích.** Giá trị hiệu lực của tham số `20.*`.

**Phương thức, đường dẫn.** `GET /api/platform/v1/parameters`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-069.

**Tham số.** `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ParameterPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị hiệu lực của tham số `20.*`; việc sửa thực hiện ở PH-18 (`/van-hanh/tham-so`).
:::

#### API-20-132 · Chạy kiểm thử rò rỉ chéo tenant ngay

::: dac-ta
**Mục đích.** Chạy kiểm thử rò rỉ chéo tenant ngay.

**Phương thức, đường dẫn.** `POST /api/platform/v1/leak-tests`.

**Quyền.** `PERM-20-admin`.

**FR hiện thực.** FR-20-070.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LeakTestCreate`; trường bắt buộc: `sourceTenant`, `targetTenant`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `LeakTestRun`; trường bắt buộc: `testRunId`, `triggerType`, `status`, `sourceTenant`, `targetTenant`, `casesTotal`, `casesFailed`, `startedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-004, ERR-20-009, ERR-20-065 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ chạy giữa hai tenant kiểm thử (ERR-20-065), không chạy ở `PROD` (Q20-18). Bất đồng bộ; phát hiện rò rỉ ghi ERR-20-111.
:::

#### API-20-133 · Danh sách lần kiểm thử rò rỉ

::: dac-ta
**Mục đích.** Danh sách lần kiểm thử rò rỉ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/leak-tests`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-070.

**Tham số.** `status` (query, LeakStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LeakTestPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách lần kiểm thử rò rỉ.
:::

#### API-20-134 · Kết quả từng ca kiểm thử rò rỉ

::: dac-ta
**Mục đích.** Kết quả từng ca kiểm thử rò rỉ.

**Phương thức, đường dẫn.** `GET /api/platform/v1/leak-tests/{testRunId}`.

**Quyền.** `PERM-20-read`.

**FR hiện thực.** FR-20-070.

**Tham số.** `testRunId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LeakTestRun`; trường bắt buộc: `testRunId`, `triggerType`, `status`, `sourceTenant`, `targetTenant`, `casesTotal`, `casesFailed`, `startedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả từng ca kiểm thử; mỗi ca gọi API của tenant này bằng thông tin xác thực của tenant kia, kỳ vọng `404`.
:::

### Cài đặt và ngữ cảnh tỉnh

#### API-20-135 · Cài đặt tỉnh

::: dac-ta
**Mục đích.** Cài đặt tỉnh.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/settings`.

**Quyền.** `PERM-20-org-read`.

**FR hiện thực.** FR-20-018, FR-20-064.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantSettings`; trường bắt buộc: `displayName`, `itOwnerOrgCode`, `sessionIdleMinutes`, `passwordMinLength`, `mfaRequiredRoles`, `maintenanceWindowPref`; tiêu đề `ETag`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền hoặc bị chặn.

**Ghi chú.** Tenant lấy từ token, không có tham số tenant ở đường dẫn.
:::

#### API-20-136 · Sửa cài đặt tỉnh (`If-Match`)

::: dac-ta
**Mục đích.** Sửa cài đặt tỉnh (`If-Match`).

**Phương thức, đường dẫn.** `PUT /api/tenant/v1/settings`.

**Quyền.** `PERM-20-settings`.

**FR hiện thực.** FR-20-018.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantSettingsUpdate`; trường bắt buộc: `displayName`, `itOwnerOrgCode`, `sessionIdleMinutes`, `passwordMinLength`, `mfaRequiredRoles`, `maintenanceWindowPref`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantSettings`; trường bắt buộc: `displayName`, `itOwnerOrgCode`, `sessionIdleMinutes`, `passwordMinLength`, `mfaRequiredRoles`, `maintenanceWindowPref`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-001, ERR-20-004, ERR-20-005, ERR-20-023, ERR-20-115, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trong giới hạn nền tảng (`sessionIdleMinutes` 5…15, `passwordMinLength` 14…64, vai trò `ROLE-TENANT_ADMIN` luôn bắt buộc MFA) trả ERR-20-023 khi vượt. Trường `maintenanceWindowPref` nằm trong bộ cài đặt, dài 2…6 giờ (ERR-20-059), cùng giá trị với API-20-160. Phát EVT-20-09.
:::

#### API-20-137 · Chính sách tiếp nhận liên tenant

::: dac-ta
**Mục đích.** Chính sách tiếp nhận liên tenant.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/cross-tenant-policy`.

**Quyền.** `PERM-20-settings`.

**FR hiện thực.** FR-20-023.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CrossTenantPolicy`; trường bắt buộc: `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours`; tiêu đề `ETag`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền hoặc bị chặn.

**Ghi chú.** Đọc chính sách tiếp nhận; SO và AU đọc, TA sửa. Vai trò SO và AU của tỉnh đọc được (không ghi).
:::

#### API-20-138 · Sửa chính sách tiếp nhận liên tenant

::: dac-ta
**Mục đích.** Sửa chính sách tiếp nhận liên tenant.

**Phương thức, đường dẫn.** `PUT /api/tenant/v1/cross-tenant-policy`.

**Quyền.** `PERM-20-settings`.

**FR hiện thực.** FR-20-023.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CrossTenantPolicyUpdate`; trường bắt buộc: `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CrossTenantPolicy`; trường bắt buộc: `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-001, ERR-20-004, ERR-20-005, ERR-20-027, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `maxHours` không vượt `20.cross-tenant.max-hours` (ERR-20-027). PH-12 đọc chính sách này khi cấp truy cập liên tenant.
:::

#### API-20-139 · Nhật ký truy cập liên tenant vào tỉnh

::: dac-ta
**Mục đích.** Nhật ký truy cập liên tenant vào tỉnh.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/cross-tenant-access-log`.

**Quyền.** `PERM-20-settings`.

**FR hiện thực.** FR-20-024.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `actor` (query, string, tùy chọn); `reasonType` (query, string, tùy chọn); `ticketRef` (query, string, tùy chọn); `access` (query, AccessKind, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CrossTenantAccessPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-20-004, ERR-20-032, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khoảng tối đa 366 ngày (ERR-20-032); chỉ lượt truy cập vào tỉnh của người gọi. Vai trò SO và AU của tỉnh đọc được (không ghi).
:::

#### API-20-140 · Sử dụng tài nguyên của tỉnh

::: dac-ta
**Mục đích.** Sử dụng tài nguyên của tỉnh.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/usage`.

**Quyền.** `PERM-20-usage-read`.

**FR hiện thực.** FR-20-030.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `granularity` (query, UsageGranularity, tùy chọn); `resource` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageResponse`; trường bắt buộc: `from`, `to`, `granularity`, `series`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004, ERR-20-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sử dụng tài nguyên của tỉnh.
:::

#### API-20-141 · Hạn mức hiệu lực và cảnh báo của tỉnh

::: dac-ta
**Mục đích.** Hạn mức hiệu lực và cảnh báo của tỉnh.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/quotas`.

**Quyền.** `PERM-20-usage-read`.

**FR hiện thực.** FR-20-030.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaView`; trường bắt buộc: `tenantCode`, `items`, `alerts`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạn mức hiệu lực và cảnh báo của tỉnh.
:::

#### API-20-142 · Trạng thái tenant, phân hệ đang bật, dải cảnh báo cho `dh-console`

::: dac-ta
**Mục đích.** Trạng thái tenant, phân hệ đang bật, dải cảnh báo cho `dh-console`.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/context`.

**Quyền.** Mọi người dùng đã đăng nhập.

**FR hiện thực.** FR-20-037, FR-20-066.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantContext`; trường bắt buộc: `tenantCode`, `status`, `readOnly`, `modules`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền hoặc bị chặn.

**Ghi chú.** Mọi người dùng đã đăng nhập gọi được, kể cả khi tenant `SUSPENDED` (trả `readOnly = true` và `banner`) để giao diện hiện đúng trạng thái.
:::

### Tổ chức

#### API-20-143 · Danh mục tổ chức (cây, bảng)

::: dac-ta
**Mục đích.** Danh mục tổ chức (cây, bảng).

**Phương thức, đường dẫn.** `GET /api/tenant/v1/organizations`.

**Quyền.** `PERM-20-org-read`.

**FR hiện thực.** FR-20-053.

**Tham số.** `q` (query, string, tùy chọn); `orgType` (query, array, tùy chọn); `status` (query, array, tùy chọn); `parentCode` (query, string, tùy chọn); `adminUnitId` (query, string, tùy chọn); `asOf` (query, string, tùy chọn); `view` (query, OrgView, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OrganizationPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `view = TREE` trả thêm `tree`; `asOf` xem theo ngày hiệu lực. Chỉ tổ chức của tenant người gọi.
:::

#### API-20-144 · Tạo tổ chức

::: dac-ta
**Mục đích.** Tạo tổ chức.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organizations`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OrganizationCreate`; trường bắt buộc: `orgCode`, `name`, `orgType`, `adminUnitId`, `effectiveFrom`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-001, ERR-20-003, ERR-20-004, ERR-20-009, ERR-20-047, ERR-20-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mã tổ chức duy nhất trong tenant (ERR-20-003); cấp trên không tạo chu trình (ERR-20-047); hiệu lực hợp lệ (ERR-20-052). Phát EVT-20-13.
:::

#### API-20-145 · Chi tiết tổ chức

::: dac-ta
**Mục đích.** Chi tiết tổ chức.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/organizations/{orgCode}`.

**Quyền.** `PERM-20-org-read`.

**FR hiện thực.** FR-20-053.

**Tham số.** `orgCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết tổ chức.
:::

#### API-20-146 · Sửa tổ chức (`If-Match`)

::: dac-ta
**Mục đích.** Sửa tổ chức (`If-Match`).

**Phương thức, đường dẫn.** `PATCH /api/tenant/v1/organizations/{orgCode}`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-053.

**Tham số.** `orgCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OrganizationUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-047, ERR-20-052, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không đổi `orgCode`; đổi cấp trên kiểm chu trình (ERR-20-047). Phát EVT-20-13.
:::

#### API-20-147 · Ngừng tổ chức

::: dac-ta
**Mục đích.** Ngừng tổ chức.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organizations/{orgCode}:deactivate`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-054.

**Tham số.** `orgCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OrgDeactivateRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `503`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-048, ERR-20-049, ERR-20-062, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ngừng tổ chức; còn tham chiếu mà không có tổ chức kế thừa trả ERR-20-049.
:::

#### API-20-148 · Hoạt động lại tổ chức

::: dac-ta
**Mục đích.** Hoạt động lại tổ chức.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organizations/{orgCode}:reactivate`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-054.

**Tham số.** `orgCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `503`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-048, ERR-20-049, ERR-20-062, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hoạt động lại tổ chức. Cần `If-Match` theo `ETag` đã đọc.
:::

#### API-20-149 · Giải thể tổ chức có kế thừa

::: dac-ta
**Mục đích.** Giải thể tổ chức có kế thừa.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organizations/{orgCode}:dissolve`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-054.

**Tham số.** `orgCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OrgDissolveRequest`; trường bắt buộc: `effectiveTo`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `428`, `503`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-009, ERR-20-048, ERR-20-049, ERR-20-062, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giải thể cần tổ chức kế thừa khi còn tham chiếu (ERR-20-048, 049). Phát EVT-20-13 để PH-01, PH-06, PH-07, PH-08, PH-12, PH-16 xử lý.
:::

#### API-20-150 · Sáp nhập nhiều tổ chức vào một tổ chức

::: dac-ta
**Mục đích.** Sáp nhập nhiều tổ chức vào một tổ chức.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organizations:merge`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OrgMergeRequest`; trường bắt buộc: `sourceCodes`, `targetCode`, `effectiveTo`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `OrgMergeResult`; trường bắt buộc: `target`, `mergedCodes`, `movedChildren`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-20-001, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-048, ERR-20-049, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sáp nhập nhiều tổ chức nguồn vào tổ chức đích có sẵn hoặc tạo mới (`createTarget`); chuyển tổ chức con sang đích.
:::

#### API-20-151 · Lịch sử hiệu lực, kế thừa

::: dac-ta
**Mục đích.** Lịch sử hiệu lực, kế thừa.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/organizations/{orgCode}/history`.

**Quyền.** `PERM-20-org-read`.

**FR hiện thực.** FR-20-054.

**Tham số.** `orgCode` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OrgHistoryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch sử hiệu lực, kế thừa.
:::

#### API-20-152 · Đánh dấu, bỏ đánh dấu chủ quản dữ liệu

::: dac-ta
**Mục đích.** Đánh dấu, bỏ đánh dấu chủ quản dữ liệu.

**Phương thức, đường dẫn.** `PUT /api/tenant/v1/organizations/{orgCode}/data-owner`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-058.

**Tham số.** `orgCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DataOwnerRequest`; trường bắt buộc: `isDataOwner`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Organization`; trường bắt buộc: `orgCode`, `name`, `orgType`, `effectiveFrom`, `status`, `isDataOwner`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `428`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-049, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đánh dấu tổ chức chủ quản dữ liệu để PH-06, PH-08 tra cứu (API-20-171).
:::

#### API-20-153 · Tải tệp nhập, sinh xem trước

::: dac-ta
**Mục đích.** Tải tệp nhập, sinh xem trước.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organization-imports`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-055.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `OrgImportUpload`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `OrgImportJob`; trường bắt buộc: `importId`, `status`, `mode`, `totalRows`, `validRows`, `errorRows`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-20-001, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-050, ERR-20-051 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `multipart/form-data` với tệp `.xlsx` hoặc `.csv` UTF-8 tối đa 10 MB và `20.org.import-max-rows` dòng (ERR-20-050). Chưa ghi dữ liệu: trả bản xem trước theo dòng. Kết quả đọc ở API-20-154.
:::

#### API-20-154 · Kết quả kiểm từng dòng

::: dac-ta
**Mục đích.** Kết quả kiểm từng dòng.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/organization-imports/{importId}`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-055.

**Tham số.** `importId` (path, string, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OrgImportJob`; trường bắt buộc: `importId`, `status`, `mode`, `totalRows`, `validRows`, `errorRows`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả kiểm từng dòng (`rows`, phân trang), thống kê `summary`; lô còn dòng lỗi không xác nhận được (ERR-20-051).
:::

#### API-20-155 · Xác nhận nhập

::: dac-ta
**Mục đích.** Xác nhận nhập.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organization-imports/{importId}:confirm`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-055.

**Tham số.** `importId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `OrgImportJob`; trường bắt buộc: `importId`, `status`, `mode`, `totalRows`, `validRows`, `errorRows`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-006, ERR-20-009, ERR-20-050, ERR-20-051 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi các dòng hợp lệ, bất đồng bộ; trả `202`.
:::

#### API-20-156 · Xuất danh mục tổ chức, tải tệp mẫu

::: dac-ta
**Mục đích.** Xuất danh mục tổ chức, tải tệp mẫu.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/organizations:export`.

**Quyền.** `PERM-20-org-read`.

**FR hiện thực.** FR-20-055.

**Tham số.** `format` (query, OrgExportFormat, tùy chọn); `template` (query, boolean, tùy chọn); `status` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `Content-Disposition`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả tệp XLSX hoặc CSV; `template = true` trả tệp mẫu nhập.
:::

#### API-20-157 · Đề xuất đồng bộ do sắp xếp ĐVHC

::: dac-ta
**Mục đích.** Đề xuất đồng bộ do sắp xếp ĐVHC.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/organization-sync-proposals`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-056.

**Tham số.** `state` (query, ProposalState, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncProposalPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-20-004 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đề xuất sinh từ EVT-07-10 khi sắp xếp đơn vị hành chính; TA quyết định.
:::

#### API-20-158 · Áp hoặc bỏ đề xuất đồng bộ

::: dac-ta
**Mục đích.** Áp hoặc bỏ đề xuất đồng bộ.

**Phương thức, đường dẫn.** `POST /api/tenant/v1/organization-sync-proposals/{proposalId}:decide`.

**Quyền.** `PERM-20-org`.

**FR hiện thực.** FR-20-056.

**Tham số.** `proposalId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecideProposalRequest`; trường bắt buộc: `decision`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SyncProposal`; trường bắt buộc: `proposalId`, `state`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-20-001, ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009, ERR-20-049 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Áp hoặc bỏ đề xuất đồng bộ.
:::

### Phiên bản và kiểm toán của tỉnh

#### API-20-159 · Phiên bản đang chạy, ghi chú phát hành, lịch bảo trì

::: dac-ta
**Mục đích.** Phiên bản đang chạy, ghi chú phát hành, lịch bảo trì.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/release-info`.

**Quyền.** `PERM-20-org-read`.

**FR hiện thực.** FR-20-064.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantReleaseInfo`; trường bắt buộc: `currentVersion`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền hoặc bị chặn.

**Ghi chú.** Phiên bản đang chạy, ghi chú phát hành, lịch bảo trì sắp tới của tỉnh.
:::

#### API-20-160 · Đặt cửa sổ bảo trì ưa thích của tỉnh

::: dac-ta
**Mục đích.** Đặt cửa sổ bảo trì ưa thích của tỉnh.

**Phương thức, đường dẫn.** `PUT /api/tenant/v1/maintenance-window`.

**Quyền.** `PERM-20-settings`.

**FR hiện thực.** FR-20-018, FR-20-061.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `MaintenanceWindowSet`; trường bắt buộc: `dayOfWeek`, `startTime`, `durationHours`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MaintenanceWindow`; trường bắt buộc: `dayOfWeek`, `startTime`, `durationHours`, `timezone`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`, `428`; mã lỗi của thao tác: ERR-20-001, ERR-20-004, ERR-20-005, ERR-20-023, ERR-20-055, ERR-20-056, ERR-20-059, ERR-20-115, ERR-00-428 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cửa sổ dài 2 đến 6 giờ theo múi giờ `Asia/Ho_Chi_Minh` (ERR-20-059); kế hoạch nâng cấp chỉ xếp tenant vào cửa sổ này. Phân vai: đây là nơi TA đặt riêng cửa sổ ưa thích của tỉnh; API-20-136 lưu trọn bộ cài đặt nên mang cùng trường `maintenanceWindowPref` và áp cùng kiểm tra; lịch cụ thể của từng kế hoạch nâng cấp do PA đặt ở API-20-121 và không đổi cửa sổ ưa thích.
:::

#### API-20-161 · Nhật ký kiểm toán PH-20 của tỉnh

::: dac-ta
**Mục đích.** Nhật ký kiểm toán PH-20 của tỉnh.

**Phương thức, đường dẫn.** `GET /api/tenant/v1/audit-events`.

**Quyền.** Vai trò TA hoặc AU của tỉnh (ROLE-TENANT_ADMIN, ROLE-AUDITOR).

**FR hiện thực.** FR-20-068.

**Tham số.** `actor` (query, string, tùy chọn); `action` (query, array, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `ticketRef` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditEventPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `503`; mã lỗi của thao tác: ERR-20-004, ERR-20-032, ERR-20-062 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Nhật ký kiểm toán thao tác PH-20 của tỉnh (TA, AU); khoảng tối đa 366 ngày. Vai trò TA và AU của tỉnh đọc được.
:::

### Registry tenant

#### API-20-162 · Registry tenant (`?status=ACTIVE` cho tác vụ nền)

::: dac-ta
**Mục đích.** Registry tenant (`?status=ACTIVE` cho tác vụ nền).

**Phương thức, đường dẫn.** `GET /internal/tenant/v1/tenants`.

**Quyền.** Scope tenant:registry-read.

**FR hiện thực.** FR-20-065.

**Tham số.** `status` (query, TenantStatus, tùy chọn); `isolationMode` (query, IsolationMode, tùy chọn); `module` (query, string, tùy chọn); `updatedSince` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RegistryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Registry cho phân hệ khác; `?status=ACTIVE` cho tác vụ nền. Kết quả được đệm tối đa `20.registry.cache-seconds` giây.
:::

#### API-20-163 · Bản ghi registry của một tenant kèm phân hệ đang bật

::: dac-ta
**Mục đích.** Bản ghi registry của một tenant kèm phân hệ đang bật.

**Phương thức, đường dẫn.** `GET /internal/tenant/v1/tenants/{tenantCode}`.

**Quyền.** Scope tenant:registry-read.

**FR hiện thực.** FR-20-037, FR-20-065, FR-20-066.

**Tham số.** `tenantCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RegistryTenant`; trường bắt buộc: `tenantCode`, `tenantId`, `status`, `isolationMode`, `realm`, `hosts`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bản ghi registry của một tenant kèm phân hệ đang bật; tenant không tồn tại trả `404`.
:::

#### API-20-164 · Hạn mức hiệu lực, host, tiền tố, ánh xạ chuyển tiếp cho PH-03, PH-04, PH-10

::: dac-ta
**Mục đích.** Hạn mức hiệu lực, host, tiền tố, ánh xạ chuyển tiếp cho PH-03, PH-04, PH-10.

**Phương thức, đường dẫn.** `GET /internal/tenant/v1/tenants/{tenantCode}/enforcement`.

**Quyền.** Scope tenant:registry-read.

**FR hiện thực.** FR-20-026, FR-20-027, FR-20-051, FR-20-066.

**Tham số.** `tenantCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EnforcementConfig`; trường bắt buộc: `tenantCode`, `status`, `hosts`, `quotas`, `configVersion`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạn mức hiệu lực, host, tiền tố, ánh xạ chuyển tiếp cho PH-03, PH-04, PH-10.
:::

#### API-20-165 · Chính sách tiếp nhận cho PH-12

::: dac-ta
**Mục đích.** Chính sách tiếp nhận cho PH-12.

**Phương thức, đường dẫn.** `GET /internal/tenant/v1/tenants/{tenantCode}/cross-tenant-policy`.

**Quyền.** Scope tenant:registry-read.

**FR hiện thực.** FR-20-023.

**Tham số.** `tenantCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CrossTenantPolicy`; trường bắt buộc: `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chính sách tiếp nhận liên tenant cho PH-12 khi cấp truy cập liên tenant.
:::

### Báo tiến độ

#### API-20-166 · Phân hệ báo tiến độ bước saga bất đồng bộ

::: dac-ta
**Mục đích.** Phân hệ báo tiến độ bước saga bất đồng bộ.

**Phương thức, đường dẫn.** `POST /internal/tenant/v1/provisioning-runs/{runId}/steps/{stepCode}:report`.

**Quyền.** Scope tenant:provision-report.

**FR hiện thực.** FR-20-008, FR-20-034.

**Tham số.** `runId` (path, string, bắt buộc); `stepCode` (path, StepCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StepReport`; trường bắt buộc: `status`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReportAck`; trường bắt buộc: `accepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-104, ERR-20-105 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân hệ báo kết quả bước bất đồng bộ của saga (`S06`, `S09`, `S10`, `S12`, `S15`). Chỉ bên thực hiện của bước mới báo được (ERR-20-104); sai bước hoặc trạng thái trả ERR-20-105. Báo lặp cùng kết quả vẫn trả `200`.
:::

#### API-20-167 · PH-18, phân hệ tham gia báo tiến độ chuyển sáp nhập

::: dac-ta
**Mục đích.** PH-18, phân hệ tham gia báo tiến độ chuyển sáp nhập.

**Phương thức, đường dẫn.** `POST /internal/tenant/v1/merge-plans/{mergePlanId}/participants/{module}:report`.

**Quyền.** Scope tenant:provision-report.

**FR hiện thực.** FR-20-047, FR-20-048.

**Tham số.** `mergePlanId` (path, string, bắt buộc); `module` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ParticipantReport`; trường bắt buộc: `phase`, `status`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReportAck`; trường bắt buộc: `accepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-104, ERR-20-114 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-18 và phân hệ tham gia báo tiến độ chuyển dữ liệu sáp nhập; sai trạng thái kế hoạch trả ERR-20-114.
:::

#### API-20-168 · Phân hệ báo đã xuất phần dữ liệu của mình

::: dac-ta
**Mục đích.** Phân hệ báo đã xuất phần dữ liệu của mình.

**Phương thức, đường dẫn.** `POST /internal/tenant/v1/export-packages/{packageId}/items/{module}:report`.

**Quyền.** Scope tenant:provision-report.

**FR hiện thực.** FR-20-041.

**Tham số.** `packageId` (path, string, bắt buộc); `module` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportItemReport`; trường bắt buộc: `status`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ReportAck`; trường bắt buộc: `accepted`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân hệ báo đã xuất phần dữ liệu của mình vào gói bàn giao.
:::

### Đọc tổ chức

#### API-20-169 · Đọc tổ chức của tenant ngữ cảnh

::: dac-ta
**Mục đích.** Đọc tổ chức của tenant ngữ cảnh.

**Phương thức, đường dẫn.** `GET /internal/tenant/v1/organizations`.

**Quyền.** Scope tenant:org-read.

**FR hiện thực.** FR-20-057.

**Tham số.** `status` (query, array, tùy chọn); `orgType` (query, array, tùy chọn); `isDataOwner` (query, boolean, tùy chọn); `asOf` (query, string, tùy chọn); `updatedSince` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OrganizationRefPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ tổ chức của tenant ngữ cảnh (tenant lấy từ thông tin xác thực máy), `size` tối đa 1.000.
:::

#### API-20-170 · Đọc một tổ chức, kể cả đã giải thể

::: dac-ta
**Mục đích.** Đọc một tổ chức, kể cả đã giải thể.

**Phương thức, đường dẫn.** `GET /internal/tenant/v1/organizations/{orgCode}`.

**Quyền.** Scope tenant:org-read.

**FR hiện thực.** FR-20-057.

**Tham số.** `orgCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OrganizationRef`; trường bắt buộc: `orgCode`, `name`, `orgType`, `status`, `isDataOwner`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc một tổ chức, kể cả đã giải thể, kèm `resolvedSuccessor` đã giải chuỗi kế thừa.
:::

#### API-20-171 · Tra hàng loạt tối đa 500 mã

::: dac-ta
**Mục đích.** Tra hàng loạt tối đa 500 mã.

**Phương thức, đường dẫn.** `POST /internal/tenant/v1/organizations:lookup`.

**Quyền.** Scope tenant:org-read.

**FR hiện thực.** FR-20-057, FR-20-058.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `OrgLookupRequest`; trường bắt buộc: `codes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `OrgLookupResult`; trường bắt buộc: `items`, `notFound`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-20-002, ERR-20-004, ERR-20-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tra tối đa 500 mã; mã không có nằm ở `notFound`. Là lệnh `POST` chỉ đọc nên không cần `Idempotency-Key`.
:::

<!-- gen:dac-ta-api:end -->

## 5. Sự kiện

Sự kiện qua outbox (`ph20_tenant.outbox`, cùng giao dịch nghiệp vụ) lên Kafka bằng Debezium, lược đồ JSON ở Apicurio mức BACKWARD, khóa phân vùng là mã đối tượng, không chứa dữ liệu cá nhân (BR-20-039). Hợp đồng máy đọc được ở [`ph20/asyncapi-ph20.yaml`](ph20/asyncapi-ph20.yaml).

### 5.1. Sự kiện PH-20 phát

| Mã | Topic | Khóa phân vùng | Bên nhận chính | FR | Lược đồ dữ liệu |
|---|---|---|---|---|---|
| EVT-20-01 | `platform.tenant.created.v1` | `tenantCode` | PH-10, PH-03, PH-04, PH-06, PH-13 | 008 | `TenantCreatedData` |
| EVT-20-02 | `platform.tenant.provisioning-failed.v1` | `tenantCode` | PH-13, PH-18 | 008, 010 | `ProvisioningFailedData` |
| EVT-20-03 | `platform.tenant.activated.v1` | `tenantCode` | mọi DU, PH-16 | 013, 014 | `TenantActivatedData` |
| EVT-20-04 | `platform.tenant.status-changed.v1` | `tenantCode` | PH-01, PH-03, PH-04, PH-12, PH-13, PH-19 | 038–044, 048, 051, 052 | `TenantStatusChangedData` |
| EVT-20-05 | `platform.tenant.quota-changed.v1` | `tenantCode` | PH-03, PH-04, PH-10, PH-12 | 026, 027, 032 | `QuotaChangedData` |
| EVT-20-06 | `platform.tenant.quota-threshold-reached.v1` | `tenantCode` | PH-13, PH-18 | 029 | `QuotaThresholdReachedData` |
| EVT-20-07 | `platform.tenant.module-enabled.v1` | `tenantCode` | phân hệ được bật | 034 | `ModuleEnabledData` |
| EVT-20-08 | `platform.tenant.module-disabled.v1` | `tenantCode` | phân hệ bị tắt | 035 | `ModuleDisabledData` |
| EVT-20-09 | `platform.tenant.config-changed.v1` | `tenantCode` | PH-03, PH-12, dh-console | 018–021, 025 | `ConfigChangedData` |
| EVT-20-10 | `platform.tenant.merge-started.v1` | `mergePlanId` | phân hệ có dữ liệu, PH-18 | 048 | `MergeStartedData` |
| EVT-20-11 | `platform.tenant.merge-cutover.v1` | `mergePlanId` | PH-03, PH-12, PH-01 | 051 | `MergeCutoverData` |
| EVT-20-12 | `platform.tenant.merge-completed.v1` | `mergePlanId` | PH-13, PH-16, PH-03 | 052 | `MergeCompletedData` |
| EVT-20-13 | `{tenant}.tenant.org.changed.v1` | `orgCode` | PH-01, PH-06, PH-07, PH-08, PH-12, PH-16 | 053–056, 058 | `OrgChangedData` |
| EVT-20-14 | `platform.release.published.v1` | `releaseVersion` | PH-18 | 060 | `ReleasePublishedData` |
| EVT-20-15 | `platform.tenant.upgrade-changed.v1` | `tenantCode` | PH-13, PH-18 | 061, 062 | `UpgradeChangedData` |
| EVT-20-16 | `platform.tenant.export-ready.v1` | `tenantCode` | PH-18 | 041 | `ExportReadyData` |

: Sự kiện EVT-20-01…16 do PH-20 phát

Sự kiện vòng đời tenant và phát hành đi trên tiền tố nền tảng `platform.` vì tenant mới chưa có tiền tố Kafka riêng (cùng cách PH-13 dùng `platform.obs.audit.recorded.v1`); sự kiện tổ chức EVT-20-13 đi trên `{tenant}.tenant.org.changed.v1`. Topic ghi ở bảng là tên đầy đủ, không thêm tiền tố môi trường.

### 5.2. Khung CloudEvents

| Thuộc tính | Tiêu đề Kafka | Giá trị |
|---|---|---|
| `specversion` | `ce_specversion` | `1.0` |
| `id` | `ce_id` | UUID v7, khóa lũy đẳng của bên tiêu thụ |
| `source` | `ce_source` | `/datahub/dh-platform/tenant` |
| `type` | `ce_type` | `vn.datahub.{topic bỏ .v1}.v1`, ví dụ `vn.datahub.platform.tenant.created.v1` |
| `time` | `ce_time` | Thời điểm phát sinh ISO 8601 |
| `subject` | `ce_subject` | Khóa phân vùng: `tenantCode`, `mergePlanId`, `orgCode` hoặc `releaseVersion` |
| `dhtenant` | `ce_dhtenant` | Mã tenant bị tác động (`T68`); `PLATFORM` với sự kiện cấp nền tảng (EVT-20-14); với sáp nhập là tenant đích |
| `dataschema` | `ce_dataschema` | Lược đồ ở Apicurio |
| `traceparent` | `traceparent` | Ngữ cảnh truy vết W3C |

: Khung CloudEvents chế độ nhị phân của sự kiện PH-20

Thân Kafka là JSON của `data` (lược đồ ở cột cuối bảng 5.1). Thứ tự bảo đảm theo khóa phân vùng: các sự kiện của một tenant đến đúng thứ tự phát sinh; sự kiện của nhiều tenant không có thứ tự chung. Bên nhận khử trùng theo `ce_id`, xử lý lại được, và phải bỏ qua trường lạ.

### 5.3. Sự kiện PH-20 tiêu thụ

| Mã | Topic | Bên phát | PH-20 làm gì |
|---|---|---|---|
| EVT-07-10 | `common.rdm.adminunit.reorganized.v1` | PH-07 | Sinh đề xuất đồng bộ tổ chức (API-20-157), FR-20-056. |
| EVT-12-13 | `{tenant}.iam.realm.changed.v1` | PH-12 | Cập nhật trạng thái realm trong registry, FR-20-019, 050. |
| EVT-09-21 | `{tenant}.privacy.crypto-shred.completed.v1` | PH-09 | Ghi xác nhận xóa mật mã, kết thúc chấm dứt tenant, FR-20-042. |
| EVT-13-14 | `{tenant}.obs.capacity.warning.v1` | PH-13 | Đưa vào kiểm tra sẵn sàng và bảng điều khiển, FR-20-007, 067. |
| EVT-03-10 | `{tenant}.gateway.tenant-redirect.changed.v1` | PH-03 | Xác nhận chuyển tiếp đã bật hoặc tắt, FR-20-051, 052. |
| EVT-03-11 | `{tenant}.gateway.limit.changed.v1` | PH-03 | Xác nhận hạn mức đã áp ở gateway, FR-20-027. |

: Sự kiện PH-20 tiêu thụ

### 5.4. Quy tắc chung của sự kiện

| Mục | Quy tắc |
|---|---|
| Phát | Ghi `outbox` cùng giao dịch với thay đổi nghiệp vụ; Debezium đưa lên Kafka; phát ít nhất một lần |
| Nhận | Khử trùng theo `ce_id` ở bảng `inbox_event`; xử lý lại một sự kiện không đổi kết quả |
| Lưu giữ, phân vùng | Lưu giữ 7 ngày, 3 phân vùng, 3 bản sao, `min.insync.replicas` 2 (giả định theo mức của PH-05, PH-10) |
| Dữ liệu cá nhân | Không có: chỉ mã, trạng thái, số đếm; đường dẫn tải gói bàn giao không nằm ở EVT-20-16 |
| Lệch tên topic | PH-19 đang nghe `tenant.module-enabled.v1` và kiểm thử PH-10 dùng `dh.platform.tenant.created.v1`; PH-20 giữ tên của FRS 9.3, đề nghị hai phân hệ đổi (Phụ lục A) |
| Bước bất đồng bộ | Phân hệ nhận EVT-20-01 hoặc EVT-20-07 phải báo kết quả bằng API-20-166 trong `20.provision.step-timeout-minutes`; EVT-20-10 đi cùng báo API-20-167 |

: Quy tắc chung của sự kiện PH-20

## 6. Bảng mã lỗi

Nguồn chuẩn là FRS D02-03-PH20 mục 9.1. Cột "HTTP" là mã trả ở phản hồi, dấu "—" là lỗi chỉ ghi vào bước, lần chạy, cảnh báo (không bao giờ ở phản hồi). Cột "Operation" là các API-20 có thể trả mã đó, tính từ `x-datahub-errors`. Thông điệp hiển thị cho người dùng ở FRS mục 9.2. Mã chung ngoài PH-20: ERR-00-401 chưa xác thực (`401`), ERR-00-403 không đủ quyền chức năng (`403`), ERR-00-428 thiếu `If-Match` (`428`).

| Mã | HTTP | Ý nghĩa | Khi nào | Operation (số API-20-) |
|---|---|---|---|---|
| ERR-20-001 | 403 | Tenant tạm ngừng | Data plane, control plane khi `SUSPENDED` (FR-038, 066) | 136, 138, 144, 146…150, 152, 153, 155, 158, 160 |
| ERR-20-002 | 404 | Không tìm thấy | Mọi FR tra theo mã | 003, 004, 006…023, 027…032, 037…055, 057…062, 064…072, 074…085, 088…108, 111…128, 134, 145…149, 151, 152, 154, 155, 158, 162…171 |
| ERR-20-003 | 409 | Trùng mã | Tạo tenant, mẫu, tổ chức, phiên bản | 002, 005, 026, 028, 030…032, 036…038, 095, 096, 102, 103, 110, 112, 115, 116, 144, 146 |
| ERR-20-004 | 400 | Dữ liệu sai định dạng | Mọi FR có đầu vào | 001…005, 008, 009, 011…013, 017…021, 023…026, 028…030, 032…038, 040…044, 046, 047, 049…061, 063, 065…073, 076…081, 083…087, 089, 091…094, 096…098, 100…104, 106…110, 112, 115…118, 120, 122, 124…133, 136, 138…140, 143, 144, 146…150, 152…154, 156…158, 160…162, 166…169, 171 |
| ERR-20-005 | 412 | Phiên bản lệch (`If-Match`) | Mọi thao tác sửa | 004, 009, 012, 017…021, 023, 030…032, 040, 043, 049, 052, 053, 070, 075…079, 089…093, 096, 098, 102, 104, 106…108, 112…117, 120…125, 136, 138, 146…149, 152, 160 |
| ERR-20-006 | 409 | Trạng thái không cho phép | Mọi máy trạng thái | 004, 013, 017…023, 026, 028, 030…034, 036…038, 043, 045, 046, 050, 052…055, 059, 065…068, 071, 075…080, 083, 084, 090…093, 095, 097, 098, 100, 102…104, 106…108, 110, 112…116, 121…125, 127, 128, 147…150, 152, 153, 155, 158 |
| ERR-20-007 | 403 | Vi phạm bốn mắt | FR-025, 027, 040, 041, 045 | 047, 050, 052, 053, 071, 075…080, 083, 084, 086, 089…093 |
| ERR-20-008 | 422 | Thiếu lý do, phiếu | Mọi thao tác thay đổi tenant tỉnh | 004, 009, 012, 019…021, 040, 043, 045, 046, 049, 050, 054, 065…068, 070, 071, 079, 098, 116 |
| ERR-20-009 | 409 | Khóa chống lặp dùng cho yêu cầu khác | Mọi `POST` có `Idempotency-Key` | 002, 008, 011, 013, 017…023, 026, 028, 031, 032, 034, 036…038, 043, 045…047, 050, 052…055, 059, 060, 065…068, 071, 075…080, 083, 084, 086, 090…093, 097, 098, 100, 102…104, 106…108, 110, 113…116, 118, 121…125, 127, 128, 132, 144, 147…150, 153, 155, 158 |
| ERR-20-010 | 403 | Tenant đặc biệt | FR-006 | 004, 008, 009, 011…013, 022, 023, 040, 043, 046, 047, 049, 050, 054, 055, 065…068, 070, 071, 080, 117 |
| ERR-20-011 | 409 | ĐVHC đã có tenant | FR-001, 007 | 002, 005 |
| ERR-20-012 | 422 | ĐVHC không hợp lệ | FR-001, 053 | 002, 005 |
| ERR-20-013 | 422 | Hết sức chứa nền tảng | FR-007 | 005, 006 |
| ERR-20-014 | 422 | Thiếu tài nguyên cụm | FR-007 | 005, 006 |
| ERR-20-015 | 422 | Mẫu không dùng được | FR-007, 015 | 002, 005 |
| ERR-20-016 | 409 | Đang có lần chạy | FR-008, 016 | 013, 022 |
| ERR-20-017 | 422 | Kiểm tra sẵn sàng chưa đạt | FR-007, 008 | 002, 005, 006, 013 |
| ERR-20-018 | 409 | Không thử lại được | FR-010 | 017…019 |
| ERR-20-019 | 409 | Không bù trừ được | FR-011 | 020, 021 |
| ERR-20-020 | 422 | Kiểm tra khói chưa đạt | FR-012, 013 | 023 |
| ERR-20-021 | 422 | Thiếu đầu mối | FR-005, 013 | 002, 005, 008, 009, 011, 012, 023 |
| ERR-20-022 | 422 | Hợp đồng không hợp lệ | FR-005, 026 | 008, 009, 011, 012 |
| ERR-20-023 | 422 | Vượt giới hạn nền tảng | FR-018 | 136, 160 |
| ERR-20-024 | 502 | Ghi GitOps lỗi | FR-020 | 040 |
| ERR-20-025 | 409 | Cấu hình đang lệch | FR-019, 022 | 040, 046 |
| ERR-20-026 | 422 | Không khôi phục được cấu hình | FR-021 | 043 |
| ERR-20-027 | 422 | Liên tenant vượt trần | FR-023 | 138 |
| ERR-20-028 | 422 | Không chuyển được chế độ cách ly | FR-025 | 047, 076, 077, 079 |
| ERR-20-029 | 422 | Hạn mức ngoài miền | FR-026, 027 | 026, 028, 030…032, 049, 050, 052…055 |
| ERR-20-030 | 422 | Hạ dưới mức đang dùng | FR-027 | 049 |
| ERR-20-031 | 422 | Ghi đè quá số ngày | FR-032 | 054, 055 |
| ERR-20-032 | 400 | Khoảng thời gian quá dài | FR-030, 031, 068 | 024, 056, 057, 062, 130, 139…141, 161 |
| ERR-20-033 | 422 | Thiếu phụ thuộc phân hệ | FR-034 | 026, 028, 030…032, 065 |
| ERR-20-034 | 409 | Phân hệ đang bị phụ thuộc | FR-035 | 066…068 |
| ERR-20-035 | 403 | Phân hệ lõi | FR-035 | 066…068 |
| ERR-20-036 | 422 | Cờ không áp dụng được | FR-036 | 070 |
| ERR-20-037 | 422 | Chưa đủ điều kiện chấm dứt, khôi phục | FR-039, 040, 042 | 071, 075…079 |
| ERR-20-038 | 422 | Chưa hết thời gian nguội | FR-040 | 071, 075…079 |
| ERR-20-039 | 410 | Gói bàn giao hết hạn | FR-041 | 080…084 |
| ERR-20-040 | 422 | Kế hoạch sáp nhập không hợp lệ | FR-045 | 086, 089…093 |
| ERR-20-041 | 409 | Tenant thuộc kế hoạch khác | FR-045 | 086, 089…093 |
| ERR-20-042 | 422 | Ánh xạ chưa đủ | FR-046, 047 | 095…097 |
| ERR-20-043 | 422 | Chạy thử chưa đạt hoặc đã cũ | FR-045, 048 | 086, 089…093, 098, 100 |
| ERR-20-044 | 409 | Còn xung đột | FR-049, 050, 051 | 102…104, 106 |
| ERR-20-045 | 422 | Chuyển tiếp vượt tối đa | FR-045, 052 | 086, 089…093, 107, 108 |
| ERR-20-046 | 409 | Chưa hết chuyển tiếp | FR-052 | 107, 108 |
| ERR-20-047 | 422 | Cấp trên không hợp lệ, chu trình | FR-053 | 144, 146 |
| ERR-20-048 | 422 | Kế thừa không hợp lệ | FR-054 | 147…150 |
| ERR-20-049 | 409 | Còn tham chiếu, cần kế thừa | FR-054, 056, 058 | 147…150, 152, 158 |
| ERR-20-050 | 422 | Tệp nhập không hợp lệ | FR-055 | 153, 155 |
| ERR-20-051 | 422 | Lô còn dòng lỗi | FR-055 | 153, 155 |
| ERR-20-052 | 422 | Hiệu lực sai | FR-053 | 144, 146 |
| ERR-20-053 | 422 | Phiên bản sản phẩm không hợp lệ | FR-059 | 110, 112, 115, 116 |
| ERR-20-054 | 422 | Chưa đủ thí điểm | FR-060 | 113, 114, 117 |
| ERR-20-055 | 422 | Phiên bản không dùng được | FR-061 | 065, 118, 120, 121, 160 |
| ERR-20-056 | 422 | Kế hoạch nâng cấp không hợp lệ | FR-061 | 118, 120, 121, 160 |
| ERR-20-057 | 409 | Sóng dừng do ngưỡng | FR-062 | 122…125, 127 |
| ERR-20-058 | 422 | Không quay lui được | FR-062 | 122…125, 127 |
| ERR-20-059 | 422 | Cửa sổ bảo trì không hợp lệ | FR-051, 061, 064 | 047, 076, 077, 079, 106, 118, 120, 121, 160 |
| ERR-20-060 | 422 | Tham số ngoài miền | FR-069 | Dữ liệu, data plane |
| ERR-20-061 | 409 | Đổi kênh khi đang nâng cấp | FR-060 | 113, 114, 117 |
| ERR-20-062 | 503 | Phụ thuộc không khả dụng | Mọi FR gọi phân hệ khác | 002, 005, 006, 013, 023, 079, 085, 095, 104, 105, 128…130, 139, 147…150, 161 |
| ERR-20-063 | 409 | Mẫu đã phát hành | FR-015 | 026, 028, 030…032 |
| ERR-20-064 | 422 | Cụm chưa đạt | FR-017 | 002, 036…038 |
| ERR-20-065 | 422 | Không phải tenant kiểm thử | FR-070 | 132 |
| ERR-20-066 | 422 | Không lập được báo cáo | FR-031 | 060 |
| ERR-20-067 | 409 | Host, tiền tố trùng | FR-001, 019 | 040 |
| ERR-20-068 | 422 | Thuộc tính bất biến | FR-004, 019 | 004, 040 |
| ERR-20-101 | 503 | Tenant chưa sẵn sàng | `PROVISIONING`, `FAILED` (FR-066) | Dữ liệu, data plane |
| ERR-20-102 | 410 | Tenant đã chấm dứt | `DECOMMISSIONED` (FR-042, 066) | Dữ liệu, data plane |
| ERR-20-103 | 503 | Phân hệ chưa bật | FR-035, 066 | Dữ liệu, data plane |
| ERR-20-104 | 403 | Scope không đủ, không phải bên thực hiện | API nội bộ (FR-009, 057, 065) | 162…171 |
| ERR-20-105 | 409 | Báo tiến độ sai bước, trạng thái | API-20-166 (FR-009) | 166 |
| ERR-20-106 | — | Bước quá hạn chờ báo | Saga (FR-008) | Chương 7, saga |
| ERR-20-107 | — | Bên thực hiện báo lỗi | Saga, sáp nhập (FR-008, 047) | Chương 7, saga |
| ERR-20-108 | — | Saga vượt tổng thời gian | Saga (FR-008) | Chương 7, saga |
| ERR-20-109 | — | Argo CD đồng bộ lỗi | FR-020, 062 | Chương 7, saga |
| ERR-20-110 | — | Thiếu số liệu sử dụng | FR-028 | Chương 7, saga |
| ERR-20-111 | — | Phát hiện rò rỉ | FR-070 | Chương 7, saga |
| ERR-20-112 | — | Kiểm tra sau nâng cấp không đạt | FR-062 | Chương 7, saga |
| ERR-20-113 | — | Kiểm đếm sáp nhập lệch | FR-047, 048, 051 | Chương 7, saga |
| ERR-20-114 | 409 | Báo sáp nhập sai trạng thái | API-20-167 (FR-048) | 167 |
| ERR-20-115 | 409 | Tenant `MERGED` chỉ đọc | FR-051, 066 | 106, 136, 160 |
| ERR-20-116 | — | Chưa xác nhận xóa mật mã | FR-042 | Chương 7, saga |
| ERR-20-117 | — | Ca kiểm tra khói lỗi | FR-012 | Chương 7, saga |
| ERR-20-118 | 503 | Đang bảo trì nâng cấp | FR-062, 066 | Dữ liệu, data plane |

: Mã lỗi ERR-20 của PH-20

Mã ERR-20-101, 102, 103 (tenant chưa sẵn sàng, đã chấm dứt, phân hệ chưa bật) do data plane trả cho lượt gọi vào API của tenant, không nằm ở operation của PH-20; các operation `/api/tenant/v1` khi tenant tạm ngừng trả ERR-20-001. ERR-20-104 và ERR-20-105, 114 chỉ ở các API báo tiến độ `/internal`.

## 7. Sơ đồ trình tự

### 7.1. Saga khởi tạo tenant

Khai báo tenant ghi hồ sơ, chạy saga phát sự kiện cho phân hệ tự khởi tạo phần của mình; PA theo dõi bằng SSE. Sơ đồ vẽ các bước tiêu biểu, không vẽ đủ 17 bước (xem FRS mục 4.4).

```{.mermaid caption="Trình tự khởi tạo tenant bằng saga 17 bước"}
sequenceDiagram
  participant PA as PA qua console
  participant P as PH-20 dh-platform
  participant G as Git và Argo CD
  participant I as PH-12
  participant O as PH-13
  participant K as Kafka
  participant X as PH-10 PH-03 PH-04
  PA->>P: POST /tenants rồi POST /tenants/T68:check-readiness
  P-->>PA: 201 PROVISIONING và readiness ready
  PA->>P: POST /tenants/T68/provisioning-runs
  P-->>PA: 202 runId PENDING
  PA->>P: GET /provisioning-runs/{runId}/stream
  P->>G: S02 commit cấu hình tenants/T68
  P->>I: S03 API-12-080 tạo realm dh-t68
  I-->>P: 200 realm PROVISIONING
  P->>O: S08 API-13-072 chuỗi kiểm toán
  O-->>P: 200
  P-)K: Phát EVT-20-01 platform.tenant.created.v1
  K-)X: Mỗi phân hệ tự khởi tạo phần của mình
  X->>P: POST /internal/.../steps/S06_EVENTING:report SUCCEEDED
  P-->>PA: SSE step-changed rồi run SUCCEEDED
  PA->>P: POST /tenants/T68:activate If-Match
  P-->>PA: 200 ACTIVE và handoverDelivery SENT
  P-)K: Phát EVT-20-03 platform.tenant.activated.v1
```

Bước lỗi dừng saga ở `FAILED` và phát EVT-20-02; PA thử lại từ bước lỗi bằng API-20-017 hoặc bù trừ bằng API-20-020. Kích hoạt (API-20-023) chỉ thành công khi kiểm tra khói đạt (ERR-20-020). Thời gian từ khai báo đến `ACTIVE` mục tiêu không quá 60 phút khi tự động (NFR-00-057) và không quá một ngày làm việc kể cả thời gian chờ con người (KPI-12).

### 7.2. Báo tiến độ bất đồng bộ của bước saga

Bước bất đồng bộ không chờ đồng bộ trên một yêu cầu HTTP dài: PH-20 phát sự kiện, đặt bước `WAITING_REPORT` và hẹn giờ; phân hệ báo kết quả qua API-20-166.

```{.mermaid caption="Trình tự báo tiến độ bước bất đồng bộ S06_EVENTING"}
sequenceDiagram
  participant S as Saga PH-20
  participant K as Kafka
  participant E as PH-10
  participant C as Console
  participant T as Bộ hẹn giờ
  S->>S: Đặt S06 WAITING_REPORT và timeoutAt
  S-)K: EVT-20-01 kèm runId
  S-)C: SSE step-changed S06 WAITING_REPORT
  K-)E: Nhận EVT-20-01
  E->>E: Tạo principal, ACL, topic hệ thống
  E->>S: POST /internal/tenant/v1/provisioning-runs/{runId}/steps/S06_EVENTING:report
  S-->>E: 200 accepted stepStatus SUCCEEDED
  S-)C: SSE step-changed S06 SUCCEEDED
  T->>S: Hết step-timeout-minutes mà chưa có báo cáo
  S->>S: Đặt S06 FAILED ERR-20-106 và run FAILED
  S-)K: EVT-20-02 provisioning-failed
```

Hai nhánh: có báo cáo trong hạn thì bước `SUCCEEDED` (hoặc `FAILED` kèm `errorCode` nếu phân hệ báo lỗi, ERR-20-107); quá hạn `20.provision.step-timeout-minutes` (mặc định 15 phút) thì bước `FAILED` với ERR-20-106. Báo lặp cùng kết quả trả `200` (lũy đẳng); báo sai bước hoặc sai trạng thái trả `409` ERR-20-105; bên không phải bên thực hiện trả `403` ERR-20-104. Cùng cơ chế dùng cho báo tiến độ chuyển sáp nhập (API-20-167) và xuất gói bàn giao (API-20-168).

### 7.3. Sáp nhập tenant

Sáp nhập gom tenant nguồn vào tenant đích khi sắp xếp đơn vị hành chính. PH-20 điều phối, PH-18 chạy chuyển dữ liệu từng phân hệ, PH-12 chuyển định danh, PH-03 chuyển tiếp lượt gọi.

```{.mermaid caption="Trình tự lập, duyệt, chuyển dữ liệu và cutover sáp nhập tenant"}
sequenceDiagram
  participant A as PA lập kế hoạch
  participant B as PA duyệt
  participant P as PH-20
  participant N as PH-18
  participant M as Phân hệ có dữ liệu
  participant I as PH-12
  participant W as PH-03
  A->>P: POST /merge-plans rồi PUT /mappings/{id} rồi :dry-run
  P-->>A: 202 dryRun PASSED và mappingHash
  A->>P: POST /merge-plans/{id}:submit If-Match
  B->>P: POST /merge-plans/{id}:approve If-Match
  P-->>B: 200 APPROVED người duyệt khác người lập
  A->>P: POST /merge-plans/{id}:start
  P-)N: EVT-20-10 và POST /api/ops/v1/merge-transfers mỗi phân hệ
  N->>M: Xuất, nhập, kiểm đếm theo gói
  N->>P: POST /internal/.../participants/{module}:report
  P-->>A: TRANSFERRING rồi CONFLICT_REVIEW nếu còn xung đột
  A->>P: POST /conflicts:resolve-batch
  A->>P: POST /merge-plans/{id}:transfer-identity
  P->>I: API-12-045 và API-12-046 cấp song song thông tin xác thực
  A->>P: POST /merge-plans/{id}:cutover confirmCode
  P-)W: EVT-20-11 nguồn MERGED, chuyển tiếp kèm Deprecation
  W-)P: EVT-03-10 xác nhận chuyển tiếp đã bật
  A->>P: POST /merge-plans/{id}:complete sau thời gian chuyển tiếp
  P-)W: EVT-20-12 merge-completed
```

Điều kiện chặn: chạy thử phải đạt và không cũ so với bảng ánh xạ (ERR-20-043), còn xung đột mở thì không chuyển định danh, không cutover (ERR-20-044), thời gian chuyển tiếp không vượt `20.merge.transition-max-months` (ERR-20-045), chưa hết chuyển tiếp thì không kết thúc (ERR-20-046). Hủy kế hoạch chỉ được trước cutover (API-20-093); sau cutover tenant nguồn giữ `MERGED` chỉ đọc theo Q20-01. TA của hai tỉnh xem phần của tỉnh mình ở API-20-088, 099, 101 qua console (chỉ đọc).

### 7.4. Tạm ngừng tenant và thực thi ở data plane

Tạm ngừng đi qua đề nghị, thực hiện, rồi PH-12 và PH-03 thực thi, mọi lượt gọi vào tenant trả ERR-20-001 trong không quá 60 giây.

```{.mermaid caption="Trình tự tạm ngừng tenant và thực thi ERR-20-001"}
sequenceDiagram
  participant A as PA
  participant P as PH-20
  participant I as PH-12
  participant W as PH-03 APISIX
  participant U as Người dùng tỉnh
  A->>P: POST /tenants/T68/lifecycle-requests SUSPEND
  P-->>A: 201 DRAFT
  A->>P: POST /lifecycle-requests/{id}:execute If-Match
  P->>I: API-12-084 realm chỉ đọc
  P->>P: Tenant SUSPENDED, ghi lịch sử và kiểm toán
  P-)W: EVT-20-04 status-changed
  P-->>A: 202 EXECUTING
  U->>W: Gọi API của tỉnh
  W-->>U: 403 ERR-20-001 Tỉnh đang tạm ngừng
  U->>P: GET /api/tenant/v1/context
  P-->>U: 200 readOnly true và banner
```

Tạm ngừng không cần bốn mắt (chỉ chấm dứt, sáp nhập, đổi cách ly, hạ hạn mức cần). Khi `20.suspend.essential-api-allowed = true` và đề nghị có `essentialApisAllowed`, API thiết yếu vẫn được phục vụ. Khôi phục dùng cùng đường dẫn với `requestType = RESUME` và đảo ngược thực thi.

## 8. Ca rò rỉ chéo tenant

Nguyên tắc: người gọi không thể biết đối tượng của tenant khác có tồn tại hay không. Mọi truy cập đối tượng không thuộc tenant của token trả `404` ERR-20-002 với thân giống hệt đối tượng không tồn tại (cùng `title`, `detail`, độ dài), không trả `403`. Ranh giới thực thi ở hai lớp: tầng ứng dụng (tenant lấy từ token) và RLS PostgreSQL (`app.tenant_id`, D03-10 mục 4); lớp RLS vẫn giữ kể cả khi tầng ứng dụng sai.

| Ca | Yêu cầu | Kỳ vọng | Lý do |
|---|---|---|---|
| L-01 | TA của T68 gọi `GET /api/tenant/v1/organizations/{orgCode}` với mã tổ chức chỉ có ở T91 | `404` ERR-20-002 | Truy vấn theo `tenant_id` của token, RLS lọc dòng của T91 |
| L-02 | TA của T68 gọi `PUT /api/tenant/v1/organizations/{orgCode}/data-owner` với mã của T91 | `404` ERR-20-002 | Không phân biệt không tồn tại và thuộc tenant khác, thân giống nhau |
| L-03 | TA của T68 gọi `GET /api/tenant/v1/organization-imports/{importId}` của lô nhập T91 | `404` ERR-20-002 | Lô nhập có `tenant_id`, RLS chuẩn |
| L-04 | TA của T68 gọi `GET /api/platform/v1/tenants/T91` | `403` ERR-00-403 | Token không thuộc `PLATFORM` gọi nhóm nền tảng: `403` ở lớp xác thực trước khi tới dữ liệu; đường dẫn nền tảng không phải tài nguyên tỉnh nên không lộ sự tồn tại của T91 |
| L-05 | TA của T68 gửi `tenantCode = T91` trong thân `PUT /api/tenant/v1/settings` | Ghi cài đặt của T68, bỏ qua `tenantCode` lạ | Tenant luôn lấy từ token |
| L-06 | Client mang scope `tenant:org-read` của PH-01 ở ngữ cảnh T68 gọi `GET /internal/tenant/v1/organizations/{orgCode}` mã của T91 | `404` ERR-20-002 | Tổ chức đọc theo tenant ngữ cảnh của thông tin xác thực máy |
| L-07 | Client mang scope `tenant:org-read` gọi `POST /internal/tenant/v1/organizations:lookup` có lẫn mã T91 | `200`, mã T91 nằm ở `notFound` | Tra hàng loạt không trả lỗi từng dòng, chỉ liệt kê mã không tìm thấy |
| L-08 | Phân hệ báo `POST /internal/tenant/v1/provisioning-runs/{runId}/steps/S06_EVENTING:report` của lần chạy tenant khác bên thực hiện | `403` ERR-20-104 | Chỉ bên thực hiện của bước được báo |
| L-09 | PA T68 qua `/api/platform/v1` gọi `GET /tenants/T91/usage` không có quyền đọc | `403` ERR-00-403 | Quyền đọc phải có ở nhóm nền tảng, tách khỏi quyền của tenant |
| L-10 | Người dùng T68 gọi `GET /api/tenant/v1/cross-tenant-access-log` tìm lượt truy cập của T91 | `200` chỉ lượt vào T68 | Nhật ký chỉ lượt truy cập vào tỉnh của người gọi |

: Ca kiểm thử rò rỉ chéo tenant ở tầng API

```http
GET /api/tenant/v1/organizations/SO-CHI-CO-O-T91 HTTP/1.1
Authorization: Bearer <token-tenant-T68>

HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{"type": "https://datahub.example.vn/errors/ERR-20-002", "title": "Không tìm thấy", "status": 404, "code": "ERR-20-002",
 "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "detail": "Không tìm thấy tổ chức SO-CHI-CO-O-T91 trong phạm vi được xem.", "instance": "/api/tenant/v1/organizations/SO-CHI-CO-O-T91"}
```

Ví dụ ca L-01: thân lỗi không chứa mã tenant lạ và không khác thân của mã không tồn tại. FR-20-070 điều phối kiểm thử rò rỉ hằng đêm giữa hai tenant kiểm thử T90 và T91, phủ 100% operation của ba nhóm; API-20-132, 133, 134 chạy và đọc kết quả, phát hiện rò rỉ ghi ERR-20-111 và cảnh báo PH-13. Kiểm thử không chạy ở `PROD` (Q20-18) và chỉ giữa tenant kiểm thử (ERR-20-065). Ca L-01…L-10 là ca hợp đồng bắt buộc của D05-02-PH20.

## 9. Truy vết API và FR

Mỗi FR-20-001…070 phải có ít nhất một API hoặc lý do không có API riêng. Bảng sinh từ `x-datahub-fr` của OpenAPI; cột "API-20-" liệt kê số.

| FR | Tên chức năng | API-20- |
|---|---|---|
| FR-20-001 | Khai báo tenant mới | 002, 005 |
| FR-20-002 | Liệt kê, tìm, lọc tenant toàn nền tảng | 001 |
| FR-20-003 | Xem chi tiết tenant | 003 |
| FR-20-004 | Sửa hồ sơ hành chính của tenant | 004 |
| FR-20-005 | Quản lý đầu mối và hợp đồng dịch vụ của tenant | 007…012 |
| FR-20-006 | Bảo vệ tenant đặc biệt PLATFORM và COMMON | Không có API riêng: bảo vệ tenant đặc biệt áp cho mọi API ghi (ERR-20-010) |
| FR-20-007 | Kiểm tra sẵn sàng trước khởi tạo | 005, 006 |
| FR-20-008 | Chạy saga khởi tạo tenant | 013, 166 |
| FR-20-009 | Theo dõi tiến độ saga thời gian thực | 014…016 |
| FR-20-010 | Thử lại saga từ bước lỗi | 017…019 |
| FR-20-011 | Bù trừ và hủy khởi tạo | 020, 021 |
| FR-20-012 | Kiểm tra khói sau khởi tạo | 015, 022 |
| FR-20-013 | Kích hoạt tenant và bàn giao cho quản trị tỉnh | 023 |
| FR-20-014 | Đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16 | 024 |
| FR-20-015 | Quản lý mẫu khởi tạo có phiên bản | 025…032 |
| FR-20-016 | Khởi tạo bổ sung cho tenant đang hoạt động | 013, 033, 034 |
| FR-20-017 | Khởi tạo tenant chế độ DEDICATED_CLUSTER | 035…038 |
| FR-20-018 | Cài đặt tỉnh do quản trị tỉnh tự quản | 135, 136, 160 |
| FR-20-019 | Cấu hình nền tảng của tenant | 039, 040 |
| FR-20-020 | Ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống | 039, 040 |
| FR-20-021 | Lịch sử, so sánh, khôi phục phiên bản cấu hình | 041…043 |
| FR-20-022 | Phát hiện lệch cấu hình và đối chiếu định kỳ | 044…046 |
| FR-20-023 | Chính sách tiếp nhận truy cập liên tenant của tỉnh | 137, 138, 165 |
| FR-20-024 | Xem nhật ký truy cập liên tenant vào tỉnh | 139 |
| FR-20-025 | Chuyển chế độ cách ly của tenant | 047, 076, 077, 079 |
| FR-20-026 | Đặt hạn mức hợp đồng của tenant | 048, 049, 164 |
| FR-20-027 | Đổi hạn mức có duyệt và đẩy xuống nơi thực thi | 050…053, 164 |
| FR-20-028 | Thu thập sử dụng tài nguyên theo tenant | Không có API riêng: tác vụ nền thu số liệu, kết quả đọc ở API-20-056, 057, 140 |
| FR-20-029 | Cảnh báo ngưỡng hạn mức 80% và 100% | 058, 059 |
| FR-20-030 | Xem sử dụng tài nguyên của tỉnh và toàn nền tảng | 056, 057, 140, 141 |
| FR-20-031 | Báo cáo sử dụng tài nguyên theo kỳ, xuất tệp | 060…062 |
| FR-20-032 | Ghi đè hạn mức tạm thời có thời hạn | 048, 054, 055 |
| FR-20-033 | Danh mục phân hệ của nền tảng và ma trận phụ thuộc | 063 |
| FR-20-034 | Bật phân hệ cho tenant | 064, 065, 166 |
| FR-20-035 | Tắt, tạm ngừng phân hệ cho tenant | 064, 066…068 |
| FR-20-036 | Cờ tính năng theo tenant | 069, 070 |
| FR-20-037 | Cung cấp trạng thái phân hệ cho menu và giao diện | 142, 163 |
| FR-20-038 | Tạm ngừng tenant | 071, 079 |
| FR-20-039 | Khôi phục tenant | 071, 079 |
| FR-20-040 | Đề nghị và duyệt chấm dứt tenant | 071, 073…078 |
| FR-20-041 | Xuất gói bàn giao dữ liệu tenant | 080…084, 168 |
| FR-20-042 | Thực hiện chấm dứt tenant | 079 |
| FR-20-043 | Lịch sử vòng đời và quyết định | 072, 074, 085 |
| FR-20-044 | Thông báo thay đổi trạng thái tenant | 085 |
| FR-20-045 | Lập kế hoạch sáp nhập | 086…093 |
| FR-20-046 | Lập bảng ánh xạ sáp nhập | 094…096 |
| FR-20-047 | Chạy thử sáp nhập | 097, 167 |
| FR-20-048 | Điều phối chuyển dữ liệu theo phân hệ | 088, 098…100, 167 |
| FR-20-049 | Xử lý xung đột sáp nhập | 101…103 |
| FR-20-050 | Chuyển định danh và cấp song song thông tin xác thực HTTT | 104, 105 |
| FR-20-051 | Chuyển tiếp lượt gọi và chuyển tenant nguồn sang MERGED | 106, 164 |
| FR-20-052 | Kết thúc sáp nhập sau thời gian chuyển tiếp | 107, 108 |
| FR-20-053 | Quản lý danh mục tổ chức | 143…146 |
| FR-20-054 | Hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa | 147…151 |
| FR-20-055 | Nhập tổ chức từ Excel, CSV có xem trước và xuất | 153…156 |
| FR-20-056 | Đồng bộ tổ chức khi sắp xếp đơn vị hành chính | 157, 158 |
| FR-20-057 | API đọc tổ chức cho phân hệ khác | 169…171 |
| FR-20-058 | Đánh dấu và tra cứu tổ chức chủ quản dữ liệu | 152, 171 |
| FR-20-059 | Danh mục phiên bản sản phẩm | 109…112, 115, 116 |
| FR-20-060 | Kênh phát hành và đăng ký kênh của tenant | 001, 113, 114, 117 |
| FR-20-061 | Lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì | 118…121, 160 |
| FR-20-062 | Theo dõi nâng cấp, dừng sóng, quay lui | 119, 122…127 |
| FR-20-063 | Thông báo phát hành và lịch bảo trì tới tỉnh | 128 |
| FR-20-064 | Xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh | 135, 159 |
| FR-20-065 | Registry tenant cho phân hệ khác | 162, 163 |
| FR-20-066 | Thực thi trạng thái tenant ở data plane và control plane | 142, 163, 164 |
| FR-20-067 | Bảng điều khiển nền tảng đa tenant | 129 |
| FR-20-068 | Nhật ký kiểm toán thao tác PH-20 | 130, 161 |
| FR-20-069 | Tham số 20.* của phân hệ | 131 |
| FR-20-070 | Điều phối kiểm thử rò rỉ chéo tenant định kỳ | 132…134 |

: Truy vết FR sang API

FR không có API riêng: FR-20-006, FR-20-028 (lý do ở cột cuối bảng). Mọi API-20-001…171 đều có ít nhất một FR hiện thực.

## 10. Câu hỏi mở

Dải Q20-55…59 dành cho tập API; Q20-01…19 ở FRS không lặp lại.

| Mã | Câu hỏi | Ảnh hưởng | Đề xuất tạm |
|---|---|---|---|
| Q20-55 | Giới hạn tốc độ cụ thể theo nhóm đường dẫn và theo tenant do ai chốt (PH-03 hay PH-20) | Mục 2.9 | Dùng bảng giả định 2.9, đặt ở APISIX, đổi không cần phát hành mới |
| Q20-56 | Tải tệp nhập tổ chức qua `multipart/form-data` trực tiếp hay xin liên kết tải lên trước vào kho tệp DD-12 | API-20-153 | Multipart trực tiếp tối đa 10 MB, quét virus rồi mới đọc |
| Q20-57 | Luồng SSE tiến độ saga đi qua BFF hay trực tiếp APISIX, giới hạn kết nối mỗi người dùng | API-20-016 | Qua APISIX, tối đa 5 luồng mỗi người dùng, nối lại bằng `Last-Event-ID` |
| Q20-58 | Nhật ký kiểm toán của tỉnh (API-20-161) hiện họ tên hay mã ẩn danh của PA nền tảng tác động vào tỉnh | API-20-161, SEC-85 | Hiện mã người dùng nền tảng và vai trò, không hiện họ tên |
| Q20-59 | `mergePlanId` dạng mã nghiệp vụ `SN-năm-số` hay UUID; ai cấp số | API-20-086 đến 108, EVT-20-10…12 | Mã nghiệp vụ `SN-2026-001` do PH-20 cấp theo năm, UUID ở khóa nội bộ |

: Câu hỏi mở Q20-55…59

## Phụ lục A. Đề nghị đồng bộ

Tập API không sửa tài liệu khác; các lệch và đề nghị dưới đây ghi để luồng chính xử lý.

| Tài liệu | Đề nghị |
|---|---|
| FRS D02-03-PH20 | FR-20-038: trường `reason` kiểu `SuspendReason` đổi tên `suspendReason` ở API để khỏi trùng `reason` văn bản của các FR khác (thân `LifecycleRequestCreate`); sửa FRS hoặc ghi chú đổi tên |
| FRS D02-03-PH20 | FR-20-001, FR-20-005: API dùng `isolationMode`, `scaleProfile`, `deploymentProfile`, `contacts[].role`, giữ đúng tên FRS; riêng đầu mối dùng giá trị `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY` theo FRS 4.2 |
| FRS D02-03-PH20, D02-08 | API-20-137, API-20-139 ghi quyền "SO, AU đọc" và API-20-161 ghi "TA, AU" nhưng không có `PERM-20-*` tương ứng; đề nghị thêm hai quyền đọc mới (một cho SO, AU, TA đọc truy cập liên tenant; một cho TA, AU đọc nhật ký kiểm toán của tỉnh), hoặc xác nhận dùng vai trò trực tiếp |
| FRS D02-03-PH20 | API-20-162: `?status=ACTIVE` ghi ở FRS; API còn nhận `isolationMode`, `module`, `updatedSince`, `size` tối đa 1.000 (thêm để đồng bộ tăng dần, tương thích ngược) |
| D02-08 | Thêm mười quyền `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-approve`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-settings`, `PERM-20-org`, `PERM-20-org-read`, `PERM-20-usage-read`; scope `tenant:registry-read`, `tenant:org-read`, `tenant:provision-report` (các mã PERM-20 mới này chưa có ở D02-08 nên `kiem_tra_ma.py` báo thiếu cho tới khi D02-08 cập nhật) |
| CSDL D03-03-PH20 | Chưa có bảng cho: cụm đích `DEDICATED_CLUSTER` (`clusterCode`, `state`, API-20-035…038), đợt khởi tạo bổ sung (`planId`, API-20-033, 034), đề xuất đồng bộ tổ chức (`proposalId`, API-20-157, 158), thông báo phát hành (`announcementId`, API-20-128), lần đối chiếu cấu hình (`reconcileId`, API-20-045); đề nghị thêm `dedicated_cluster`, `supplement_plan`, `org_sync_proposal`, `release_announcement` hoặc ghi rõ lưu ở bảng nào |
| CSDL D03-03-PH20 | `merge_plan.plan_code` là `mergePlanId` ở API (dạng `SN-2026-001`); `usage_report.status` `GENERATING` được API giữ; `tenant_config_version.config_scope` giữ năm giá trị như API `ConfigScope` |
| D03-06-PH20 và D05-02-PH20 | Màn hình gọi đúng mã API-20 ở chương 3; ca L-01…L-10 ở chương 8 là ca hợp đồng bắt buộc của test case; ca "Idempotency-Key lặp khác thân" và "If-Match thiếu, lệch" cho mọi operation có khóa |
| PH-18 | Chốt `POST /api/ops/v1/merge-transfers` (một phân hệ của một kế hoạch, kèm `Idempotency-Key = {mergePlanId}:{module}`) và `NotificationApi`; gọi API-20-167 báo tiến độ, API-20-162 với `?status=ACTIVE` cho tác vụ nền; đăng ký 29 khóa `20.*`; PH-20 chỉ đọc giá trị hiệu lực ở API-20-131 |
| PH-19, PH-10 | PH-19 đổi tên topic nghe sang `platform.tenant.module-enabled.v1`; PH-10 đổi tên topic trong kiểm thử `dh.platform.tenant.created.v1` sang `platform.tenant.created.v1` và nhận phần báo tiến độ qua API-20-166 |
| PH-12 | Nhận scope `iam:realm-provision` cho PH-20 (API-12-080, 084, 085, 045, 046); đọc API-20-165 khi cấp truy cập liên tenant; nghe EVT-20-04, EVT-20-11 |
| PH-13, PH-03, PH-07, PH-16, PH-09 | PH-13: scope `obs:tenant-provision`, nhận EVT-20-12, nhãn `tenant` cho `dh_tenant_*`; PH-03: đọc API-20-164, phát EVT-03-10, EVT-03-11, thực thi ERR-20-001 và `Deprecation`, `Sunset`; PH-07: scope `platform.tenant.provision` cho API-07-073; PH-16: nhận API-16-030 với `metricCode` `thoi-gian-khoi-tao-tenant`; PH-09: FR-09-043 và EVT-09-21 |
| D00-04 | Ghi quy ước tiêu đề CloudEvents `ce_dhtenant` cho sự kiện cấp nền tảng (`PLATFORM`) và sự kiện sáp nhập (tenant đích); ghi dải Q20-55…59 |

: Đề nghị đồng bộ với tài liệu khác

Giả định chính của tập: (1) tenant mẫu `T68` quy mô vừa với 200 HTTT (GĐ-01…07); (2) giới hạn tốc độ ở mục 2.9; (3) Kafka 3 phân vùng, lưu giữ 7 ngày như PH-05, PH-10; (4) liên kết tải gói bàn giao tối đa 72 giờ theo FR-20-041; (5) API `/internal` không có phân trang nâng cao ngoài `page`, `size`.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 171 operation, 16 sự kiện phát, 6 sự kiện tiêu thụ, bảng mã lỗi, ba sơ đồ trình tự, ca rò rỉ chéo tenant |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ với FRS 0.2: quyết định 403 cho nhóm nền tảng và 404 cho tài nguyên tenant khác, phân vai API-20-136 và 160 cho cửa sổ bảo trì, thông báo lỗi trong ví dụ khớp FRS 9.2, `changeKind` của EVT-20-09, cột FR của API-20-005, 085, 164, 166, 167 |

: Lịch sử phiên bản
