---
ma_tai_lieu: D03-04-PH06
ten: Đặc tả API và sự kiện phân hệ PH-06 Dữ liệu chủ
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư tích hợp, kỹ sư dh-data, kiểm thử viên, hội đồng thẩm định
phan_he: PH-06
mo_ta: Hợp đồng REST và sự kiện của PH-06 Dữ liệu chủ gồm 126 operation (96 mã gốc của FRS, 24 mã tách từ dòng gộp, 5 mã mới của FRS 0.2 và API-06-126 của đợt đồng bộ cuối) và 15 sự kiện EVT-06, kèm quy ước chung, quyền, scope máy, mã lỗi RFC 9457, ví dụ, kiểm tra hợp đồng và đề nghị bổ sung cho FRS.
tai_lieu_lien_quan: D02-03-PH06 FRS; D03-02-PH06 SDD; D03-03-PH06 CSDL; D03-06-PH06 Giao diện; D05-02-PH06 Test case
---

# D03-04-PH06 · Đặc tả API và sự kiện Dữ liệu chủ

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của phân hệ PH-06 Dữ liệu chủ: nơi giữ một bản ghi vàng cho mỗi công dân, tổ chức, địa chỉ và liên kết nó với bản ghi của từng hệ thống nguồn. PH-06 công bố **126 operation REST** gốc `/api/mdm/v1` (module `mdm` của `dh-data`) và **15 sự kiện** `EVT-06-01…15` trên Kafka. Mã API-06-001…096 giữ đúng đường dẫn và phương thức của FRS §9.4; 15 dòng gộp nhiều hành động ở FRS (như `:{suspend,resume,retire}`) được tách thành operation riêng, cấp mã mới **API-06-097…120** (24 mã, mục 3.1); FRS 0.2 đã áp cách tách này ở 9.4 và thêm **API-06-121…125** (mở lại quyết định, danh sách thao tác, khóa tập nhãn, nhận việc tiếp theo, gỡ hạn chế xử lý).

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:

- [`ph06/openapi-mdm.yaml`](ph06/openapi-mdm.yaml): OpenAPI 3.1, 203 lược đồ, mỗi operation có ví dụ yêu cầu (khi có thân) và ví dụ phản hồi; 225 ví dụ khớp lược đồ theo [`check_contracts.py`](ph06/tools/check_contracts.py); `openapi-spec-validator` hợp lệ.
- [`ph06/asyncapi-mdm.yaml`](ph06/asyncapi-mdm.yaml): AsyncAPI 3.0, 15 kênh, 15 operation, 15 thông điệp CloudEvents, 15 ví dụ khớp payload.

Bốn nguyên tắc hợp đồng:

1. **Enum và tên trường lấy theo Phụ lục A của FRS.** Enum trong OpenAPI được đọc thẳng từ FRS khi sinh; [`doi_chieu_frs.py`](ph06/tools/doi_chieu_frs.py) đối chiếu thêm đường dẫn, mã lỗi, sự kiện, quyền. Trường và enum chỉ có ở API được liệt kê ở mục 10.1 để FRS hấp thụ, không tự thêm vào phụ lục.
2. **Không trả dữ liệu cá nhân đầy đủ mặc định.** Mọi phản hồi qua bộ che theo phân loại PH-09 và mục đích khai thác (`X-Purpose`); giá trị `SENSITIVE` chỉ lộ khi có `PERM-09-unmask`, lý do ở tiêu đề và ghi nhật ký truy cập. Số định danh cá nhân luôn đi trong thân `POST`, không lên đường dẫn hay chuỗi truy vấn.
3. **Sự kiện không mang giá trị thuộc tính** (BR-06-012): chỉ mã, phiên bản, tên thuộc tính; bên nhận tra lại bằng API có kiểm soát.
4. **Mọi lệnh tạo có `Idempotency-Key`, mọi lệnh sửa và hành động trên tài nguyên có `If-Match`;** thao tác rủi ro cao (hợp nhất, tách, hoàn tác quá hạn, xuất, đổi ưu tiên nguồn) qua duyệt bốn mắt.

Căn cứ: FRS D02-03-PH06 §3.2, §9 và Phụ lục A; CSDL D03-03-PH06 (schema `ph06_mdm`). Mọi tên miền, dữ liệu trong ví dụ là giả lập, tenant T68.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả mặt giao tiếp của PH-06 ở mức đủ để kỹ sư `dh-data` hiện thực, kỹ sư của HTTT nguồn và PH-04, PH-08, PH-14 tích hợp, và kiểm thử viên viết ca kiểm thử hợp đồng.

### 0.2. Thuật ngữ và tài liệu tham chiếu

Bảng giải thích thuật ngữ và các tài liệu tập này dựa vào.

| Thuật ngữ, tài liệu | Giải thích |
|---|---|
| Bản ghi vàng (`goldenId`) | Bản ghi hợp nhất đại diện duy nhất một thực thể |
| Liên kết chéo (xref) | Cặp `(sourceCode, sourceKey)` với `goldenId` |
| Resolve | Đối sánh một bản ghi trực tuyến, trả `goldenId` hoặc đề xuất hàng đợi |
| `X-Purpose` | Tiêu đề mã mục đích khai thác đã được PH-09 chấp thuận |
| D02-03-PH06 FRS | Nguồn chuẩn cho FR, ERR, EVT, PERM, enum (Phụ lục A) |
| D03-03-PH06 CSDL | Bảng, ràng buộc, mã hóa; tên trường JSON camelCase tương ứng cột snake_case |
| D02-08 Ma trận phân quyền | `PERM-06-read`, `update`, `merge` đã có; chín quyền còn lại đề nghị (FRS Phụ lục B) |
| `docs/07-srs/SRS-PH-06-mdm.md` M5 | API của SRS cũ trong repo (mục 8.2) |

: Thuật ngữ và tài liệu tham chiếu của tập API PH-06

### 0.3. Người đọc

Kỹ sư tích hợp, kỹ sư `dh-data`, kiểm thử viên và hội đồng thẩm định.

### 0.4. Cấu trúc tài liệu

Chương 1, 2 quy ước và quyền; 3, 4 endpoint và sự kiện; 5, 6 hợp đồng ngoài phân hệ và mã lỗi; 7 kiểm tra; 8, 9 ánh xạ và truy vết; 10, 11 đề nghị cho FRS và câu hỏi mở; 12 đặc tả từng endpoint.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi operation, trừ khi bảng endpoint ở chương 3 ghi khác.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/mdm/v1`: BFF console của tenant; trong cụm `dh-data.dh-data.svc`; HTTT qua cổng `apisix-ext` hoặc `apisix-int`. API `/api/mdm/v1/internal/*` (API-06-022) chỉ mở trong mạng nội bộ, không có ở BFF |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2`, chạy song song tối thiểu 6 tháng; oasdiff ở CI chặn thay đổi phá vỡ trong `v1` |
| Tenant | Lấy từ token (claim `tenant`), không bao giờ từ thân hay đường dẫn; đối tượng của tenant khác trả `404` ERR-06-001, không lộ sự tồn tại |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên hoặc tập (`:approve`, `:merge`, `:resolve`) |
| Khóa lạc quan | `GET` trả `ETag: W/"{version}"`; `PUT`, `PATCH` và hành động trên tài nguyên có phiên bản bắt buộc `If-Match`; lệch trả `409` ERR-06-004, thiếu trả `428`. Miễn: hành động không có tài nguyên cha có phiên bản (API-06-013, 054, 055, 060, 069…072, 082, 084, 118) |
| Chống trùng | `POST` tạo, nạp, hợp nhất, tách, hoàn tác, xuất, chạy đồng bộ bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ ở Valkey `dh:{tenant}:mdm:idem:{chủ thể}:{khóa}`; cùng khóa cùng thân trả lại phản hồi cũ, khác thân ERR-06-015 (BR-06-028) |
| Phân trang | `page` (từ 0), `size` (1…100 mặc định 20; tìm kiếm tối đa 50); phản hồi `items`, `page`, `size`, `totalElements` (tìm kiếm giới hạn "trên 1.000") |
| Lỗi | RFC 9457 `application/problem+json`, `type = https://datahub.gov.vn/errors/{code}`, `code`, `traceId`, `errors[]` theo trường |
| Tác vụ dài | Job, nạp tệp, xuất, áp lại sống sót, đồng bộ trả `202` kèm `jobId`, `runId` hoặc `Location`; theo dõi bằng `GET` hoặc EVT-06-09 |
| Hạn mức | Vượt hạn mức gọi `429` ERR-06-048, tiêu đề `Retry-After`; nạp theo `06.ingest.rate-per-source` |
| Che dữ liệu | Mọi phản hồi có DLCN đi qua bộ che theo PH-09 và `X-Purpose`; `Cache-Control: private, max-age=0` ở tra cứu bản ghi vàng; mọi lượt đọc ghi nhật ký truy cập, không ghi được thì từ chối ERR-06-039 |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên APISIX, BFF, `dh-data`, Kafka; `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail` |

: Quy ước chung của API PH-06

### 1.1. Mặt giao tiếp và đường mạng

PH-06 có ba mặt giao tiếp, khác nhau ở bên gọi và cách xác thực.

| Mặt | Bên gọi | Xác thực | Operation |
|---|---|---|---|
| Người dùng | Console qua BFF | OIDC và PKCE ở BFF, token không ra trình duyệt; quyền `PERM-06-*` | Toàn bộ trừ 022 |
| Máy, công khai trong TTDL | HTTT nguồn, PH-04, PH-08, PH-14 | `client_credentials` và mTLS; scope `mdm:*` (mục 2.2) | 021, 068…072, 081 |
| Nội bộ | Luồng PH-04 chạy ở `dh-runtime` | mTLS mesh, token máy gắn nguồn, scope `mdm:ingest`, chỉ `apisix-int` | 022 |

: Mặt giao tiếp và đường mạng

## 2. Xác thực và phân quyền

### 2.1. Quyền người dùng

Quyền theo FRS §3.2. Cột "Quyền" ở mục 3 và `x-datahub-permission` trong OpenAPI là nguồn chi tiết.

| Quyền | Vai trò (FRS 3.2) | Operation tiêu biểu |
|---|---|---|
| `PERM-06-read` | PA, TA, TO, SO, DS, DA, VW, AU (DO ○) | Mọi `GET` cấu hình, xem bản ghi vàng đã che, lịch sử, truy nguồn gốc, dashboard, xem trước chuẩn hóa |
| `PERM-06-update` | TA, DS (○) | Sửa tay thuộc tính (057), gỡ liên kết chéo (067) |
| `PERM-06-merge` | TA, DS (○), DA | Hợp nhất, tách, hoàn tác, ngừng, khôi phục bản ghi vàng (058…062, 113) |
| `PERM-06-config` | PA (gói nền), TA, DS (○) | Soạn mô hình, nguồn, ưu tiên nguồn, quy tắc, sống sót, lưu giữ, tham số; gửi duyệt |
| `PERM-06-approve` | DA | Duyệt, từ chối mô hình, quy tắc, ưu tiên nguồn, sống sót, hợp nhất rủi ro cao; xác nhận job vượt ngưỡng |
| `PERM-06-steward` | TA, DS, DA | Hàng đợi (045…049, 121, 124), tập nhãn (037…039, 123) |
| `PERM-06-ingest` | TA, DS (○) | Nạp tệp lô, xử lý lại, loại bỏ ứng viên |
| `PERM-06-export` | TA, DS (○), DA, DO (○) | Đề nghị, chấp thuận xuất (073…076, 114), chấp thuận đăng ký nhận (079) |
| `PERM-06-sync` | TA, DS, DA | Chạy, tạm dừng, tiếp tục đồng bộ, xử lý lệch (081…084, 118) |
| `PERM-06-operate` | TA, TO | Job, lịch job (041…044, 086, 087, 105) |
| `PERM-06-dsr` | TA, SO, DS | Yêu cầu của chủ thể dữ liệu (090…092, 119, 120, 125) |
| `PERM-06-audit-read` | SO, AU | Nhật ký truy cập (089) |

: Quyền người dùng

Quy tắc vượt quyền chức năng, máy chủ kiểm:

- **Bốn mắt** (BR-06-004, 019): người duyệt khác người đề nghị, kể cả DA có cả `config` và `approve` (ERR-06-005); kiểm theo từng yêu cầu, không theo vai trò.
- **Phạm vi tổ chức**: mục hàng đợi ngoài tổ chức của người dùng ERR-06-028; DO chỉ chấp thuận xuất của nguồn mình chủ quản.
- **Xem đầy đủ `SENSITIVE`**: cần `PERM-09-unmask` và tiêu đề `X-Unmask-Reason` (≥ 20 ký tự); không có thì giá trị luôn che, kể cả với DS (FRS 3.2).
- **Mục đích khai thác**: tra cứu, resolve, tìm kiếm bắt buộc `X-Purpose` hợp lệ ở PH-09, thiếu ERR-06-037; vượt ngưỡng truy cập hàng loạt ERR-06-038 (BR-06-013).
- **Hoàn tác**: trong 90 ngày không cần duyệt; quá hạn cần DA (ERR-06-034).

### 2.2. Scope máy

Bên gọi là máy dùng scope `mdm:*` cấp ở Keycloak khi đăng ký client.

| Scope | Cấp cho | Operation | Ghi chú |
|---|---|---|---|
| `mdm:ingest` | Client của HTTT nguồn; luồng PH-04 | 021, 022 | `systemCode` của token phải khớp nguồn `ACTIVE` cho domain (ERR-06-014) |
| `mdm:read` | HTTT, PH-04, PH-08 | 070 | Chỉ đọc bản ghi vàng đã che theo mục đích |
| `mdm:xref` | HTTT, PH-04 | 068, 069 | Tra ID nguồn, ID vàng |
| `mdm:resolve` | HTTT, PH-04 | 071 | Chỉ máy; không có quyền người dùng |
| `mdm:search` | HTTT (cấp hạn chế) | 072 | Trả trường rút gọn |
| `mdm:national-sync` | PH-14 | 081 | Kích hoạt lượt đồng bộ từ phía PH-14 |
| `mdm:steward-intake` | PH-08 | 126 | Tạo mục hàng đợi lý do `DQ_FINDING`; chỉ qua `apisix-int` |

: Scope máy

### 2.3. Lỗi xác thực và che dữ liệu

FRS 0.2 (9.1) quy định `401`, `403` do thiếu quyền chức năng và `428` thiếu `If-Match` dùng mã nền tảng `ERR-00-401`, `ERR-00-403`, `ERR-00-428` trong `code` của thân lỗi, không cấp mã ERR-06 riêng. `403` do phạm vi dữ liệu hoặc nghiệp vụ giữ mã ERR-06 (005, 014, 028, 034, 037, 038). Mọi operation trả `401` và `403`; phản hồi che dữ liệu theo FR-06-052 không phải lỗi mà là giá trị đã che trong thân `200`.

## 3. Danh mục endpoint

Bảng sinh từ [`ph06/tools/spec.py`](ph06/tools/spec.py) bằng `gen_md.py`, cùng nguồn với OpenAPI. Cột "FR" bỏ tiền tố `FR-06-`; "Chống trùng, khóa" ghi `Idem` (`Idempotency-Key`), `If-Match`, `X-Purpose` bắt buộc; "HTTP" là mã thành công. Quyền ghi dạng "read hoặc mdm:xref" nghĩa là người dùng có quyền đó hoặc máy có scope đó.

<!-- gen:endpoints:start -->
**Domain và mô hình**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-001 | `GET /domains` | read | 001 | - | 200 |
| API-06-002 | `GET /domains/{domainCode}` | read | 001 | - | 200 |
| API-06-003 | `POST /domains` | config | 002 | Idem | 201 |
| API-06-004 | `GET /domains/{domainCode}/model-versions` | read | 005 | - | 200 |
| API-06-005 | `POST /domains/{domainCode}/model-versions` | config | 002, 005 | Idem | 201 |
| API-06-006 | `PUT /domains/{domainCode}/model-versions/{version}` | config | 002, 003, 004 | If-Match | 200 |
| API-06-007 | `GET /domains/{domainCode}/model-versions/{version}/diff` | read | 005 | - | 200 |
| API-06-008 | `POST /domains/{domainCode}/model-versions/{version}:submit` | config | 006 | If-Match | 200 |
| API-06-009 | `POST /domains/{domainCode}/model-versions/{version}:approve` | approve | 006 | If-Match | 200 |
| API-06-010 | `POST /domains/{domainCode}/model-versions/{version}:reject` | approve | 006 | If-Match | 200 |
| API-06-011 | `POST /domains/{domainCode}:suspend` | config | 006 | If-Match | 200 |
| API-06-012 | `POST /domains:install-baseline` | config | 007 | - | 200 |
| API-06-013 | `POST /identifier-rules:test` | config | 003 | - | 200 |
| API-06-097 | `POST /domains/{domainCode}:resume` | config | 006 | If-Match | 200 |
| API-06-098 | `POST /domains/{domainCode}:retire` | config | 006 | If-Match | 200 |

: Danh mục endpoint · Domain và mô hình

**Nguồn và ưu tiên nguồn**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-014 | `GET /sources` | read | 008 | - | 200 |
| API-06-015 | `POST /sources` | config | 008 | Idem | 201 |
| API-06-016 | `PATCH /sources/{sourceCode}` | config | 008, 012 | If-Match | 200 |
| API-06-017 | `POST /sources/{sourceCode}:suspend` | config | 008 | If-Match | 200 |
| API-06-018 | `GET /domains/{domainCode}/source-priorities` | read | 009 | - | 200 |
| API-06-019 | `POST /domains/{domainCode}/source-priorities:propose` | config | 009 | Idem | 202 |
| API-06-020 | `POST /source-priority-proposals/{proposalId}:approve` | approve | 009 | If-Match | 200 |
| API-06-099 | `POST /sources/{sourceCode}:resume` | config | 008 | If-Match | 200 |
| API-06-100 | `POST /sources/{sourceCode}:retire` | config | 008 | If-Match | 200 |
| API-06-101 | `POST /source-priority-proposals/{proposalId}:reject` | approve | 009 | If-Match | 200 |

: Danh mục endpoint · Nguồn và ưu tiên nguồn

**Nạp ứng viên**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-021 | `POST /domains/{domainCode}/candidates` | ingest hoặc `mdm:ingest` | 010, 016 | Idem | 202,207 |
| API-06-022 | `POST /internal/domains/{domainCode}/candidates` | scope `mdm:ingest` | 011, 016, 053 | Idem | 202,207 |
| API-06-023 | `POST /domains/{domainCode}/candidate-files` | ingest | 013 | Idem | 202 |
| API-06-024 | `POST /candidate-files/{fileId}:confirm` | ingest | 013 | If-Match | 202 |
| API-06-025 | `GET /candidate-files/{fileId}` | ingest | 013 | - | 200 |
| API-06-026 | `GET /domains/{domainCode}/candidates` | read | 017 | - | 200 |
| API-06-027 | `GET /domains/{domainCode}/candidates/{candidateId}` | read | 014, 017 | - | 200 |
| API-06-028 | `POST /domains/{domainCode}/candidates:reprocess` | ingest | 017 | - | 200 |
| API-06-029 | `POST /normalization:preview` | read | 014, 015 | - | 200 |
| API-06-102 | `POST /domains/{domainCode}/candidates:discard` | ingest | 017 | - | 200 |

: Danh mục endpoint · Nạp ứng viên

**Quy tắc đối sánh**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-030 | `GET /domains/{domainCode}/rule-sets` | read | 018 | - | 200 |
| API-06-031 | `POST /domains/{domainCode}/rule-sets` | config | 018 | Idem | 201 |
| API-06-032 | `PUT /domains/{domainCode}/rule-sets/{version}` | config | 018, 019, 023 | If-Match | 200 |
| API-06-033 | `POST /domains/{domainCode}/rule-sets/{version}:dry-run` | config | 024 | Idem, If-Match | 202 |
| API-06-034 | `POST /domains/{domainCode}/rule-sets/{version}:evaluate` | config | 026 | Idem, If-Match | 202 |
| API-06-035 | `POST /domains/{domainCode}/rule-sets/{version}:submit` | config | 018 | If-Match | 200 |
| API-06-036 | `GET /domains/{domainCode}/rule-sets/{version}/blocking-stats` | config | 019 | - | 200 |
| API-06-037 | `GET /domains/{domainCode}/label-sets` | steward | 025 | - | 200 |
| API-06-038 | `POST /domains/{domainCode}/label-sets` | steward | 025 | Idem | 201 |
| API-06-039 | `POST /label-sets/{labelSetCode}/pairs` | steward | 025 | Idem | 201 |
| API-06-040 | `GET /domains/{domainCode}/accuracy-reports` | read | 026 | - | 200 |
| API-06-103 | `POST /domains/{domainCode}/rule-sets/{version}:approve` | approve | 018 | If-Match | 200 |
| API-06-104 | `POST /domains/{domainCode}/rule-sets/{version}:reject` | approve | 018 | If-Match | 200 |
| API-06-123 | `POST /label-sets/{labelSetCode}:lock` | steward | 025 | If-Match | 200 |

: Danh mục endpoint · Quy tắc đối sánh

**Job đối sánh**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-041 | `GET /match-jobs` | operate | 022, 056 | - | 200 |
| API-06-042 | `POST /domains/{domainCode}/match-jobs` | operate | 022 | Idem | 202 |
| API-06-043 | `GET /match-jobs/{jobId}` | operate | 022 | - | 200 |
| API-06-044 | `POST /match-jobs/{jobId}:cancel` | operate | 022, 056 | If-Match | 200 |
| API-06-105 | `POST /match-jobs/{jobId}:rerun` | operate | 022, 056 | If-Match | 202 |
| API-06-106 | `POST /match-jobs/{jobId}:confirm` | approve | 022, 056 | If-Match | 200 |

: Danh mục endpoint · Job đối sánh

**Hàng đợi người quản lý**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-045 | `GET /stewardship/items` | steward | 028 | - | 200 |
| API-06-046 | `GET /stewardship/items/{itemId}` | steward | 029 | - | 200 |
| API-06-047 | `POST /stewardship/items/{itemId}:claim` | steward | 028 | If-Match | 200 |
| API-06-048 | `POST /stewardship/items/{itemId}:decide` | steward | 030 | If-Match | 200 |
| API-06-049 | `POST /stewardship/items/{itemId}:approve` | approve | 031 | If-Match | 200 |
| API-06-050 | `GET /stewardship/stats` | read | 032 | - | 200 |
| API-06-107 | `POST /stewardship/items/{itemId}:release` | steward | 028 | If-Match | 200 |
| API-06-108 | `POST /stewardship/items/{itemId}:assign` | steward | 028 | If-Match | 200 |
| API-06-109 | `POST /stewardship/items/{itemId}:reject` | approve | 031 | If-Match | 200 |
| API-06-121 | `POST /stewardship/items/{itemId}:reopen` | steward | 030 | If-Match | 200 |
| API-06-124 | `POST /stewardship/items:claim-next` | steward | 028 | - | 200,204 |
| API-06-126 | `POST /internal/stewardship/items:from-dq` | scope `mdm:steward-intake` | 027 | Idem | 201,200 |

: Danh mục endpoint · Hàng đợi người quản lý

**Quy tắc sống sót**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-051 | `GET /domains/{domainCode}/survivorship-rules` | read | 033 | - | 200 |
| API-06-052 | `PUT /domains/{domainCode}/survivorship-rules` | config | 033 | If-Match | 200 |
| API-06-053 | `POST /domains/{domainCode}/survivorship-rules:submit` | config | 033 | - | 200 |
| API-06-054 | `POST /domains/{domainCode}/survivorship-rules:impact` | config | 042 | - | 200 |
| API-06-055 | `POST /domains/{domainCode}/survivorship-rules:reapply` | config | 042 | Idem | 202 |
| API-06-110 | `POST /domains/{domainCode}/survivorship-rules:approve` | approve | 033 | - | 200 |
| API-06-111 | `POST /domains/{domainCode}/survivorship-rules:reject` | approve | 033 | - | 200 |

: Danh mục endpoint · Quy tắc sống sót

**Bản ghi vàng**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-056 | `GET /domains/{domainCode}/golden-records/{goldenId}` | read | 035, 046 | - | 200 |
| API-06-057 | `PATCH /domains/{domainCode}/golden-records/{goldenId}/attributes` | update | 036 | If-Match | 200 |
| API-06-058 | `POST /domains/{domainCode}/golden-records:merge` | merge | 037 | Idem | 200,202 |
| API-06-059 | `POST /domains/{domainCode}/golden-records/{goldenId}:split` | merge | 038 | Idem, If-Match | 200,202 |
| API-06-060 | `POST /operations/{operationId}:undo` | merge | 039 | Idem | 200,202 |
| API-06-061 | `POST /operations/{operationId}:approve` | approve | 031, 037, 038, 039 | If-Match | 200 |
| API-06-062 | `POST /domains/{domainCode}/golden-records/{goldenId}:retire` | merge | 040 | If-Match | 200 |
| API-06-063 | `GET /domains/{domainCode}/golden-records/{goldenId}/history` | read | 041 | - | 200 |
| API-06-064 | `GET /domains/{domainCode}/golden-records/{goldenId}/history/{version}` | read | 041 | - | 200 |
| API-06-065 | `GET /domains/{domainCode}/golden-records/{goldenId}/lineage` | read | 043 | - | 200 |
| API-06-112 | `POST /operations/{operationId}:reject` | approve | 031, 037, 038, 039 | If-Match | 200 |
| API-06-113 | `POST /domains/{domainCode}/golden-records/{goldenId}:restore` | merge | 040 | If-Match | 200 |
| API-06-122 | `GET /domains/{domainCode}/golden-records/{goldenId}/operations` | read | 035, 039 | - | 200 |

: Danh mục endpoint · Bản ghi vàng

**Liên kết chéo và tra cứu**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-066 | `GET /domains/{domainCode}/golden-records/{goldenId}/xrefs` | read | 044 | - | 200 |
| API-06-067 | `POST /domains/{domainCode}/golden-records/{goldenId}/xrefs/{xrefId}:detach` | update | 044 | If-Match | 200 |
| API-06-068 | `GET /domains/{domainCode}/xrefs/{sourceCode}/{sourceKey}` | read hoặc `mdm:xref` | 045 | X-Purpose | 200 |
| API-06-069 | `POST /domains/{domainCode}/xrefs:batch-lookup` | read hoặc `mdm:xref` | 045 | X-Purpose | 200 |
| API-06-070 | `POST /domains/{domainCode}/golden-records:lookup` | read hoặc `mdm:read` | 046 | X-Purpose | 200 |
| API-06-071 | `POST /domains/{domainCode}:resolve` | scope `mdm:resolve` | 020, 021, 047 | X-Purpose | 200,202 |
| API-06-072 | `POST /domains/{domainCode}/golden-records:search` | read hoặc `mdm:search` | 048 | X-Purpose | 200 |

: Danh mục endpoint · Liên kết chéo và tra cứu

**Cung cấp dữ liệu**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-073 | `POST /domains/{domainCode}/exports` | export | 049 | Idem | 202 |
| API-06-074 | `GET /exports/{exportId}` | export | 049 | - | 200 |
| API-06-075 | `POST /exports/{exportId}:approve` | export | 049 | If-Match | 200 |
| API-06-076 | `GET /exports/{exportId}/file` | export | 049 | - | 200 |
| API-06-077 | `GET /update-subscriptions` | config | 051 | - | 200 |
| API-06-078 | `POST /update-subscriptions` | config | 051 | Idem | 201 |
| API-06-079 | `POST /update-subscriptions/{subscriptionId}:approve` | export | 051 | If-Match | 200 |
| API-06-114 | `POST /exports/{exportId}:reject` | export | 049 | If-Match | 200 |
| API-06-115 | `POST /update-subscriptions/{subscriptionId}:suspend` | config | 051 | If-Match | 200 |
| API-06-116 | `POST /update-subscriptions/{subscriptionId}:resume` | config | 051 | If-Match | 200 |
| API-06-117 | `POST /update-subscriptions/{subscriptionId}:revoke` | config | 051 | If-Match | 200 |

: Danh mục endpoint · Cung cấp dữ liệu

**Đồng bộ quốc gia**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-080 | `GET /national-sync/status` | read | 053 | - | 200 |
| API-06-081 | `POST /national-sync/runs` | sync hoặc `mdm:national-sync` | 053 | Idem | 202 |
| API-06-082 | `POST /national-sync:pause` | sync | 053, 054 | - | 200 |
| API-06-083 | `GET /national-sync/discrepancies` | sync | 054 | - | 200 |
| API-06-084 | `POST /national-sync/discrepancies:resolve` | sync | 054 | - | 200 |
| API-06-118 | `POST /national-sync:resume` | sync | 053, 054 | - | 200 |

: Danh mục endpoint · Đồng bộ quốc gia

**Vận hành**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-085 | `GET /dashboard/metrics` | read | 055 | - | 200 |
| API-06-086 | `GET /job-schedules` | operate | 056 | - | 200 |
| API-06-087 | `PUT /job-schedules/{jobType}` | operate | 056 | If-Match | 200 |
| API-06-088 | `GET /processing-logs` | read | 057 | - | 200 |
| API-06-089 | `GET /access-logs` | audit-read | 057 | - | 200 |

: Danh mục endpoint · Vận hành

**Chủ thể dữ liệu và lưu giữ**

| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |
|---|---|---|---|---|---|
| API-06-090 | `POST /subject-requests` | dsr | 058 | Idem | 201 |
| API-06-091 | `GET /subject-requests/{requestId}` | dsr | 058 | - | 200 |
| API-06-092 | `POST /subject-requests/{requestId}:complete` | dsr | 058 | If-Match | 200 |
| API-06-093 | `GET /retention-policies` | config | 059 | - | 200 |
| API-06-094 | `PUT /retention-policies/{objectType}` | config | 059 | If-Match | 200 |
| API-06-095 | `GET /settings` | config | 060 | - | 200 |
| API-06-096 | `PUT /settings` | config | 060 | If-Match | 200 |
| API-06-119 | `POST /subject-requests/{requestId}:forward` | dsr | 058 | If-Match | 200 |
| API-06-120 | `POST /subject-requests/{requestId}:reject` | dsr | 058 | If-Match | 200 |
| API-06-125 | `POST /subject-requests/{requestId}:lift-restriction` | dsr | 058 | If-Match | 200 |

: Danh mục endpoint · Chủ thể dữ liệu và lưu giữ
<!-- gen:endpoints:end -->

### 3.1. Tách dòng gộp của FRS

FRS §9.4 gộp nhiều hành động vào một dòng để giữ thứ tự mã. Mỗi operation cần một mã (khuôn K-API) nên tập này giữ mã FRS cho hành động đầu và cấp mã kế tiếp từ API-06-097 theo thứ tự dòng cho các hành động còn lại; đề nghị FRS cập nhật §9.4 theo bảng (mục 10.2).

<!-- gen:split:start -->
| Dòng FRS 9.4 | Hành động gộp | Giữ mã cho | Mã cấp mới |
|---|---|---|---|

: Tách dòng gộp của FRS
<!-- gen:split:end -->

### 3.2. Ví dụ luồng chính

Dữ liệu giả lập, tenant T68; `Idempotency-Key` viết dạng đọc được cho gọn. Mỗi operation có ví dụ đầy đủ trong OpenAPI.

**API-06-071 Resolve trực tuyến (HTTT hoặc PH-04)**

```http
POST /api/mdm/v1/domains/CITIZEN:resolve
Authorization: Bearer {token máy, scope mdm:resolve}
X-Purpose: TK-THONG-KE
Content-Type: application/json

{"attributes": {"fullName": "Nguyễn Văn A", "dateOfBirth": "1990-05-14", "permanentAddress": "79"},
 "requestingSource": "HT-YTE", "mode": "LOOKUP_OR_QUEUE"}
```

```json
{"outcome": "POSSIBLE_MATCH", "score": 0.87, "method": "PROBABILISTIC_ONLINE",
 "candidates": [{"goldenId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "score": 0.87}],
 "queueItemId": "0193b1d4-9a10-7c33-8e21-4f5a6b7c8d90"}
```

Kết quả `202` vì tạo mục hàng đợi; `404` ERR-06-050 khi `NO_MATCH`; `429` ERR-06-048 khi vượt hạn mức.

**API-06-058 Hợp nhất thủ công, rủi ro cao chờ duyệt**

```http
POST /api/mdm/v1/domains/CITIZEN/golden-records:merge
Idempotency-Key: t68-hop-nhat-20261126-01
Content-Type: application/json

{"goldenIds": ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f02"],
 "reason": "Hai bản ghi cùng một người theo hồ sơ hộ tịch số 114."}
```

```json
{"operationId": "0193b1d4-b001-7d10-9a11-6a7b8c9d0e12", "changeType": "MERGE", "status": "PENDING_APPROVAL", "riskLevel": "HIGH"}
```

DA duyệt bằng `POST /operations/{operationId}:approve` (API-06-061) với `If-Match`; người duyệt trùng người đề nghị bị từ chối ERR-06-005.

**API-06-056 Xem chi tiết bản ghi vàng có xem giá trị nhạy cảm**

```http
GET /api/mdm/v1/domains/CITIZEN/golden-records/0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01?unmask=nationalId
X-Unmask-Reason: Đối chiếu hồ sơ khiếu nại số 2026-0456 của chủ thể
```

Thuộc tính không có `PERM-09-unmask` trả `masked = true`, `value` che dạng `*********234`. Phản hồi có `ETag` để dùng cho `If-Match` của API-06-057.

## 4. Danh mục sự kiện

### 4.1. Sự kiện của PH-06 (EVT-06-01…15)

Sự kiện ghi vào `ph06_mdm.outbox_event` cùng giao dịch nghiệp vụ, Debezium Outbox Event Router đưa lên Kafka theo topic `{tenant}.mdm.{thực-thể}.{sự-kiện}.v1` (FRS 9.3; ví dụ `t68.mdm.golden.merged.v1`). CloudEvents 1.0 dạng cấu trúc, `type = vn.datahub.mdm.{thực-thể}.{sự-kiện}.v1`, `source = dh-data/mdm/{tenant}`.

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Khóa | Payload `data` | Bên nhận |
|---|---|---|---|---|---|
| EVT-06-01 | `{tenant}.mdm.golden.created.v1` | Tạo bản ghi vàng | `goldenId` | `GoldenCreatedData` | HTTT đăng ký, PH-08 |
| EVT-06-02 | `{tenant}.mdm.golden.updated.v1` | Thuộc tính, liên kết đổi (kể cả đồng bộ, áp lại, sửa tay, hoàn tác) | `goldenId` | `GoldenUpdatedData` | HTTT đăng ký, PH-04 (xóa bộ đệm), PH-08 |
| EVT-06-03 | `{tenant}.mdm.golden.merged.v1` | Hợp nhất | `survivorId` | `GoldenMergedData` | HTTT đăng ký, PH-08 |
| EVT-06-04 | `{tenant}.mdm.golden.split.v1` | Tách | `goldenId` | `GoldenSplitData` | HTTT đăng ký, PH-08 |
| EVT-06-05 | `{tenant}.mdm.golden.retired.v1` | Ngừng | `goldenId` | `GoldenRetiredData` | HTTT đăng ký |
| EVT-06-06 | `{tenant}.mdm.golden.restored.v1` | Khôi phục từ `RETIRED` | `goldenId` | `GoldenRestoredData` | HTTT đăng ký |
| EVT-06-07 | `{tenant}.mdm.candidate.ingested.v1` | Lô ứng viên được nhận (gộp, chỉ số lượng) | `sourceCode` | `CandidateIngestedData` | PH-13, PH-08 |
| EVT-06-08 | `{tenant}.mdm.steward.item-created.v1` | Mục hàng đợi mới | `itemId` | `ItemCreatedData` | PH-13 (đếm), "Việc của tôi" |
| EVT-06-09 | `{tenant}.mdm.job.finished.v1` | Job kết thúc ở trạng thái cuối | `jobId` | `JobFinishedData` | PH-13, PH-18 |
| EVT-06-10 | `{tenant}.mdm.model.activated.v1` | Phiên bản mô hình domain `ACTIVE` | `domainCode` | `ModelActivatedData` | PH-04 (lược đồ), PH-08, HTTT nguồn |
| EVT-06-11 | `{tenant}.mdm.ruleset.activated.v1` | Bộ quy tắc `ACTIVE` | `domainCode` | `RuleSetActivatedData` | PH-13 |
| EVT-06-12 | `{tenant}.mdm.national-sync.discrepancy-detected.v1` | Lượt đối chiếu có lệch mới | `runId` | `DiscrepancyDetectedData` | PH-13 |
| EVT-06-13 | `{tenant}.mdm.national-sync.paused.v1` | Đồng bộ tạm dừng hoặc tiếp tục | `tenant` | `SyncPausedData` | PH-13, PH-14 |
| EVT-06-14 | `{tenant}.mdm.xref.changed.v1` | Liên kết chéo được gỡ, chuyển | `xrefId` | `XrefChangedData` | HTTT nguồn liên quan |
| EVT-06-15 | `{tenant}.mdm.source-correction.requested.v1` | Yêu cầu sửa tại nguồn | `requestId` | `SourceCorrectionData` | HTTT nguồn, PH-09 |

: Sự kiện của PH-06
<!-- gen:events:end -->

### 4.2. Quy tắc chung của sự kiện

Các quy tắc sau áp dụng cho cả 15 sự kiện.

- **Không giá trị thuộc tính** (BR-06-012): `changedAttributes[]` chỉ là tên; ràng buộc `ck_outbox_event_no_value` ở CSDL chặn khóa giá trị. Bên nhận tra lại qua API-06-070 hoặc 056 có kiểm soát.
- **Thứ tự và khử trùng**: khóa phân vùng ở cột "Khóa" (hợp nhất dùng `survivorId`); phát ít nhất một lần, bên nhận khử trùng theo `id` (inbox) và xử lý lũy đẳng; quá 50 lần thử ghi ERR-06-109.
- **Áp lại hàng loạt**: gộp tối đa 500 `goldenId` mỗi sự kiện `golden.updated` với `changeType = SURVIVORSHIP_REAPPLY`.
- **Đăng ký topic**: 15 topic đăng ký ở PH-10 theo FR-10-067; HTTT nhận bằng đăng ký API-06-078, chấp thuận API-06-079.
- **Tương thích**: chỉ thêm trường tùy chọn trong `v1` (BACKWARD); lưu giữ topic 7 ngày, 3 phân vùng (giả định, Q06-58).

### 4.3. Nạp bằng sự kiện (FR-06-012)

`dh-data` là bên nhận nội bộ của topic nguồn (FR-10-045) qua subscription đã duyệt ở PH-10; `id` của CloudEvents là `Idempotency-Key`, `time` là `sourceUpdatedAt`. Không có API, ví dụ lỗi lược đồ vào DLQ của PH-10 (ERR-06-110).

## 5. Hợp đồng với phân hệ khác và bên ngoài

Bảng liệt kê từng bên tương tác với PH-06, hướng gọi và hợp đồng.

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| HTTT nguồn | HTTT → PH-06 | API-06-021 (scope `mdm:ingest`) | Một bản ghi hoặc lô ≤ 500; `207` khi có bản ghi lỗi; hạn mức `06.ingest.rate-per-source` |
| PH-04 | PH-04 → PH-06 | API-06-022, 068…072; EVT-06-02 xóa bộ đệm lược đồ | Luồng gọi tra liên kết, resolve; tiêu đề `X-Purpose` |
| PH-01 | PH-06 đọc | HTTT `ACTIVE`, cấp độ ATTT (ERR-06-012) | Qua giao diện module, bộ đệm 5 phút |
| PH-07 | PH-06 đọc | Mã ĐVHC tại ngày tham chiếu, danh mục `CODE_REF` (ERR-06-020, 021) | Không có khóa ngoại |
| PH-08 | PH-08 → PH-06 | API-06-070; EVT-06-01…04, 10 | Tra bản ghi vàng đã che; thống kê |
| PH-09 | PH-06 ↔ PH-09 | Phân loại, mục đích, chấp thuận (ERR-06-010, 021, 037); yêu cầu chủ thể (API-06-090); EVT-06-15 | Không khả dụng thì `503` |
| PH-10 | PH-06 ↔ PH-10 | 15 topic `{tenant}.mdm.*`; nạp bằng sự kiện (mục 4.3) | Debezium Outbox Event Router |
| PH-12 | PH-06 → OPA, Keycloak | Quyền `PERM-06-*`, scope `mdm:*`, `PERM-09-unmask` | Kiểm ở APISIX và `dh-data` |
| PH-13 | PH-06 → PH-13 | EVT-06-07…09, 11…13; chỉ số OTLP; API-06-085, 088, 089 | Bảng điều khiển, cảnh báo |
| PH-14 | PH-06 ↔ PH-14 | Đồng bộ quốc gia: API-06-081 (scope `mdm:national-sync`), 080, 082…084; EVT-06-12, 13 | Thuộc tính không gửi lên: ERR-06-045 |
| PH-18 | PH-06 → PH-18 | EVT-06-09 (job lỗi) | Màn xử lý lỗi chung |
| PH-20 | PH-20 → PH-06 | Khởi tạo tenant gọi API-06-012 (gói nền) | `p_seed_tenant` ở CSDL |

: Hợp đồng với phân hệ khác và bên ngoài

## 6. Bảng mã lỗi ERR-06

Ý nghĩa và HTTP theo FRS §9.1 (nạp tự động khi sinh). Cột "API phát sinh" sinh từ `x-datahub-errors`; mã dùng ở hơn 6 operation ghi số lượng. ERR-06-101…114 là lỗi nền (job, đồng bộ, outbox) không trả cho người gọi API, hiển thị ở UI-06-18.

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | API phát sinh (API-06-) |
|---|---|---|---|
| ERR-06-001 | 404, 410 | Không tìm thấy đối tượng, thuộc tenant khác; `410` khi bản ghi vàng `RETIRED` | 100 API |
| ERR-06-002 | 409 | Mã đã tồn tại (domain, thuộc tính, nguồn, khóa, tập nhãn) | 14 API |
| ERR-06-003 | 400 | Dữ liệu không hợp lệ theo lược đồ hoặc tham chiếu không tồn tại | 86 API |
| ERR-06-004 | 409 | Xung đột phiên bản (`If-Match` không khớp `ETag`) | 55 API |
| ERR-06-005 | 403 | Vi phạm bốn mắt: người đề nghị, gửi duyệt hoặc quyết định bước trước tự duyệt, chấp thuận | 30 API |
| ERR-06-006 | 409 | Trạng thái hiện tại không cho thao tác | 42 API |
| ERR-06-007 | 422 | Thiếu lý do hoặc lý do < 20 ký tự | 20 API |
| ERR-06-008 | 422 | Thay đổi phá vỡ trên mô hình cần phiên bản mới (trả khi `PUT` sửa trực tiếp phiên bản nháp, API-06-006) | 006 |
| ERR-06-009 | 422 | Mô hình thiếu khóa định danh hoặc tổ hợp đối sánh; thuộc tính khóa sai kiểu | 003, 005, 006, 013 |
| ERR-06-010 | 422 | Thuộc tính DLCN chưa có phân loại PH-09 xác nhận | 006 |
| ERR-06-011 | 422 | Ngừng domain còn bản ghi vàng hoạt động | 008, 009, 010, 011, 097, 098 |
| ERR-06-012 | 422 | HTTT chưa `ACTIVE` ở PH-01 | 014, 015, 016, 017, 099, 100 |
| ERR-06-013 | 422 | Thiếu căn cứ phê duyệt thứ tự ưu tiên nguồn | 018, 019, 020, 101 |
| ERR-06-014 | 403 | Bên gửi không phải nguồn đã đăng ký, chưa `ACTIVE` cho domain | 021, 022 |
| ERR-06-015 | 409 | `Idempotency-Key` dùng lại với nội dung khác | 22 API |
| ERR-06-016 | 422 | Bản ghi thiếu `sourceKey` | 021 |
| ERR-06-017 | 422 | Bản ghi ứng viên sai lược đồ domain | 021, 022 |
| ERR-06-018 | 413 | Lô, tệp vượt giới hạn | 021, 023, 024, 025, 068, 069 |
| ERR-06-019 | 422 | Tệp sai khuôn, có công thức, macro | 023, 024, 025 |
| ERR-06-020 | 422 | Mã ĐVHC không tồn tại tại ngày tham chiếu (cảnh báo trên ứng viên) | Ứng viên mang cảnh báo, không trả lỗi |
| ERR-06-021 | 503 | PH-07 hoặc PH-09 không khả dụng | 006 |
| ERR-06-022 | 422 | Bộ quy tắc, khóa gom nhóm, chiến lược sống sót không hợp lệ | 12 API |
| ERR-06-023 | 422 | Ngưỡng ngoài miền cho phép | 032 |
| ERR-06-024 | 422 | Bộ quy tắc chưa có đánh giá đạt | 8 API |
| ERR-06-025 | 409 | Đã có job cùng loại đang chạy cho domain | 9 API |
| ERR-06-026 | 422 | Tập nhãn quá nhỏ | 034, 040 |
| ERR-06-027 | 409 | Mục hàng đợi đã có người nhận | 045, 047, 107, 108, 124 |
| ERR-06-028 | 403 | Mục hàng đợi ngoài phạm vi tổ chức của người dùng | 045, 047, 107, 108, 124 |
| ERR-06-029 | 422 | Hợp nhất hai bản ghi có khóa định danh khác nhau | 048, 058, 061, 112, 121 |
| ERR-06-030 | 409 | Mục hàng đợi lỗi thời do dữ liệu đổi | 7 API |
| ERR-06-031 | 409 | Bản ghi vàng đang `LOCKED` | 8 API |
| ERR-06-032 | 422 | Phân bổ tách không hợp lệ | 059, 061, 112 |
| ERR-06-033 | 409 | Hoàn tác có thao tác phụ thuộc chưa xác nhận | 060, 061, 112, 122 |
| ERR-06-034 | 403 | Hoàn tác quá hạn, đã chuyển duyệt | 060, 061, 112, 122 |
| ERR-06-035 | 422 | Thao tác trái thẩm quyền quốc gia của thuộc tính | 14 API |
| ERR-06-036 | 422 | Ngừng bản ghi vàng còn liên kết hiệu lực | 062, 113 |
| ERR-06-037 | 403 | Thiếu mục đích khai thác được chấp thuận | 056, 068, 069, 070, 071 |
| ERR-06-038 | 403 | Vượt ngưỡng truy cập hàng loạt | 072 |
| ERR-06-039 | 503 | Không ghi được nhật ký truy cập, từ chối trả dữ liệu | 046, 056, 070, 088, 089, 122 |
| ERR-06-040 | 422 | Tiêu chí tìm kiếm quá rộng | 072 |
| ERR-06-041 | 422 | Xuất vượt giới hạn hoặc chưa chấp thuận | 073, 074, 075, 076, 114 |
| ERR-06-042 | 410 | Tệp xuất hết hạn | 073, 074, 075, 076, 114 |
| ERR-06-043 | 422 | HTTT chưa có mục đích khai thác cho đăng ký nhận cập nhật | 077, 078, 079, 115, 116, 117 |
| ERR-06-044 | 409 | Đồng bộ quốc gia đang tạm dừng | 022, 080, 081, 082, 118 |
| ERR-06-045 | 422 | Thuộc tính không được gửi lên CSDL quốc gia | 022, 080, 081, 082, 118 |
| ERR-06-046 | 422 | Yêu cầu của chủ thể chưa xác minh danh tính | 090, 091, 092, 119, 120, 125 |
| ERR-06-047 | 422 | Tham số ngoài miền | 12 API |
| ERR-06-048 | 429 | Vượt hạn mức gọi | 021, 071 |
| ERR-06-049 | 422 | Thời hạn lưu giữ dưới mức tối thiểu | 093, 094 |
| ERR-06-050 | 404 | Không có bản ghi vàng khớp khóa, liên kết hoặc resolve `NO_MATCH` | 056, 068, 069, 070, 071, 126 |
| ERR-06-051 | 422 | Cặp nhãn không hợp lệ (nhãn sai, hai tham chiếu trùng hoặc không tồn tại, cặp đã có) | 037, 038, 039, 123 |
| ERR-06-052 | 422 | Khóa định danh `CMND_9` khai xác định (`deterministic = true`) | 006, 013 |
| ERR-06-053 | 409 | Quyết định hàng đợi quá hạn mở lại hoặc đã có thao tác phụ thuộc | 048, 121 |
| ERR-06-101 | - | Job Splink lỗi đọc staging | Không trả cho người gọi |
| ERR-06-102 | - | Job quá thời gian tối đa | Không trả cho người gọi |
| ERR-06-103 | - | Job hết bộ nhớ, tài nguyên | Không trả cho người gọi |
| ERR-06-104 | - | Cặp của job bị bỏ qua do bản ghi đổi sau khi xuất staging | Không trả cho người gọi |
| ERR-06-105 | - | Job vượt ngưỡng an toàn, chờ xác nhận | Không trả cho người gọi |
| ERR-06-106 | - | PH-14 không khả dụng | Không trả cho người gọi |
| ERR-06-107 | - | Lệch quốc gia vượt ngưỡng, đồng bộ tạm dừng | Không trả cho người gọi |
| ERR-06-108 | - | Dữ liệu quốc gia mâu thuẫn nội bộ | Không trả cho người gọi |
| ERR-06-109 | - | Outbox phát sự kiện thất bại quá số lần | Không trả cho người gọi |
| ERR-06-110 | - | Sự kiện nguồn sai lược đồ, vào DLQ | Không trả cho người gọi |
| ERR-06-111 | - | Không ghi được lịch sử, cập nhật bản ghi vàng bị hủy | Không trả cho người gọi |
| ERR-06-112 | - | Hai bản ghi vàng cùng khóa định danh | Không trả cho người gọi |
| ERR-06-113 | - | Không giải mã được trường nhạy cảm | Không trả cho người gọi |
| ERR-06-114 | - | Dọn lưu giữ bỏ qua đối tượng bị giữ pháp lý | Không trả cho người gọi |

: Mã lỗi ERR-06
<!-- gen:errors:end -->

Khung lỗi chung (FRS 0.2, 9.1): ba mã nền tảng dùng cho mọi operation, không thuộc dải ERR-06 và không có cột "API phát sinh" riêng.

| Mã | HTTP | Ý nghĩa | Áp dụng |
|---|---|---|---|
| ERR-00-401 | 401 | Chưa xác thực hoặc token hết hạn | Mọi operation |
| ERR-00-403 | 403 | Thiếu quyền chức năng `PERM-06-*` hoặc scope máy | Mọi operation |
| ERR-00-428 | 428 | Thiếu tiêu đề `If-Match` ở thao tác ghi | Operation có `If-Match` (cột Chống trùng ở mục 3) |

: Mã lỗi nền tảng dùng ở PH-06

### 6.1. Thân lỗi

Lược đồ `Problem`: `type`, `title`, `status`, `detail`, `instance`, `code`, `traceId`, `errors[]` (`field`, `message`). `title`, `detail` theo `Accept-Language`; thông điệp hiển thị cho người dùng theo FRS 9.2. Lỗi từng bản ghi trong lô nạp nằm ở `results[].errors`, không làm hỏng cả lô.

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng được kiểm tự động ở CI để OpenAPI, AsyncAPI, FRS và tài liệu không lệch nhau.

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ; mọi ví dụ khớp lược đồ; mỗi operation có `x-datahub-id` duy nhất, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`; lệnh ghi có `If-Match`, lệnh tạo có `Idempotency-Key`; mã ERR có ở FRS và mã HTTP của nó có trong responses; không trường bí mật | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0: kênh, operation, thông điệp tham chiếu đúng; ví dụ khớp payload; đủ 15 topic đúng FRS | `check_contracts.py`; `@asyncapi/parser` 3 | CI-5 |
| Lint quy ước; thay đổi phá vỡ trong `v1` | `@redocly/cli lint`; oasdiff `breaking` | CI-5 |
| Enum, trường, ERR, EVT, PERM, đường dẫn API-06-001…126 và FR của từng dòng khớp FRS | [`doi_chieu_frs.py`](ph06/tools/doi_chieu_frs.py) | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py`, rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp tài liệu gốc | `build/tools/kiem_tra_ma.py` | CI-1 |

: Các kiểm tra hợp đồng chạy trong CI

Kết quả chạy ngày 26/11/2026 trên máy viết tài liệu: `check_contracts.py` báo OpenAPI hợp lệ, 125 operation, 125 mã, 225 ví dụ khớp; AsyncAPI 15 kênh, 15 operation, 15 thông điệp, 15 ví dụ khớp; 0 lỗi. `doi_chieu_frs.py` báo 125 mã FRS §9.4 khớp phương thức, đường dẫn, FR; enum, ERR, EVT, PERM không lệch; trường, enum chỉ có ở API liệt kê ở mục 10.1. Chưa chạy `@redocly/cli`, `@asyncapi/parser`, Spectral (không cài ở máy viết tài liệu); chạy ở CI-5.

```bash
cd datahub-docs/03-thiet-ke/api/ph06
python3 tools/gen_openapi.py && python3 tools/gen_asyncapi.py && python3 tools/gen_md.py --write
python3 tools/check_contracts.py && python3 tools/doi_chieu_frs.py
```

## 8. Ánh xạ từ hệ cũ

### 8.1. Hệ Viettel 2021 và các HTTT ngành

Hệ cũ (Viettel 2021) không có dữ liệu chủ nên không có API cũ nào để ánh xạ. LGC-NGSP-003 (BHXH hộ gia đình) và LGC-NGSP-005 (đăng ký doanh nghiệp) là nguồn dữ liệu công dân, tổ chức vào `mdm_source` qua PH-14; chúng không đổi chức năng.

### 8.2. API M5 của SRS repo

SRS cũ (`docs/07-srs/SRS-PH-06-mdm.md` M5) có hai gốc `/api/v1/master` và `/api/admin/v1/mdm`; tập này thay bằng một gốc `/api/mdm/v1`, và đưa khóa định danh khỏi đường dẫn.

| API cũ | API mới | Chuyển đổi |
|---|---|---|
| `GET /api/v1/master/{entity}/{key}` | API-06-070 `POST …/golden-records:lookup` | Khóa định danh chuyển vào thân để không lọt log cổng; `entity` thành `domainCode` |
| `POST /api/v1/master/{entity}/search` | API-06-072 | Thêm `X-Purpose`, giới hạn `size` 50 |
| `POST /api/v1/master/{entity}/resolve` | API-06-071 | `mode` `LOOKUP_ONLY`, `LOOKUP_OR_QUEUE` |
| `GET …/{key}/lineage`, `/history`, `/sources` | API-06-065, 063, 066 | Theo `goldenId` |
| `POST /api/admin/v1/mdm/candidates` | API-06-021, 022, 023 | Thêm tệp lô và luồng PH-04 |
| `GET /queue`, `GET /queue/{id}`, `POST /queue/{id}/resolve` | API-06-045, 046, 048 | `resolve` thành `:decide` |
| `POST /entities/merge`, `/entities/{id}/split`, `/operations/{id}/undo` | API-06-058, 059, 060 | Thêm bốn mắt API-06-061 |
| `GET`, `PUT /source-priority` | API-06-018, 019, 020 | `PUT` thành đề nghị có căn cứ, duyệt ở 020 |
| `POST /sync/national`, `GET /sync/discrepancies`, `GET /stats` | API-06-081, 083, 085 | Thêm tạm dừng, xử lý lệch |

: Ánh xạ API M5 của SRS cũ sang API mới

## 9. Truy vết FR → API

Mỗi FR-06 có ít nhất một API hoặc ghi rõ nơi xử lý. Bảng sinh từ cột FR của FRS §9.4.

<!-- gen:fr:start -->
| FR | Tên | API (API-06-) |
|---|---|---|
| FR-06-001 | Liệt kê và xem domain dữ liệu chủ | 001, 002 |
| FR-06-002 | Soạn mô hình domain với thuộc tính có kiểu | 003, 005, 006 |
| FR-06-003 | Khai báo khóa định danh và quy tắc kiểm tra | 006, 013 |
| FR-06-004 | Gán phân loại dữ liệu cho thuộc tính theo PH-09 | 006 |
| FR-06-005 | Quản lý phiên bản mô hình và kiểm tra tương thích | 004, 005, 007 |
| FR-06-006 | Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain | 008, 009, 010, 011, 097, 098 |
| FR-06-007 | Nạp gói domain nền CITIZEN, ORGANIZATION, ADDRESS | 012 |
| FR-06-008 | Đăng ký nguồn dữ liệu chủ gắn HTTT | 014, 015, 016, 017, 099, 100 |
| FR-06-009 | Khai báo mức tin cậy và thứ tự ưu tiên nguồn có phê duyệt | 018, 019, 020, 101 |
| FR-06-010 | Nạp bản ghi ứng viên qua API | 021 |
| FR-06-011 | Nạp bản ghi ứng viên qua luồng PH-04 | 022 |
| FR-06-012 | Nạp bản ghi ứng viên qua sự kiện PH-10 | 016 |
| FR-06-013 | Nạp tệp lô có xem trước | 023, 024, 025 |
| FR-06-014 | Chuẩn hóa họ tên, ngày, số định danh | 027, 029 |
| FR-06-015 | Chuẩn hóa địa chỉ theo ĐVHC của PH-07 | 029 |
| FR-06-016 | Chống trùng, thứ tự phiên bản nguồn và xóa từ nguồn | 021, 022 |
| FR-06-017 | Xem bản ghi ứng viên và xử lý ứng viên lỗi | 026, 027, 028, 102 |
| FR-06-018 | Quản lý bộ quy tắc đối sánh có phiên bản | 030, 031, 032, 035, 103, 104 |
| FR-06-019 | Cấu hình khóa gom nhóm và theo dõi hiệu quả | 032, 036 |
| FR-06-020 | Đối sánh xác định theo khóa định danh | 071 |
| FR-06-021 | Đối sánh xác suất trực tuyến | 071 |
| FR-06-022 | Chạy job đối sánh theo lô bằng Splink | 041, 042, 043, 044, 105, 106 |
| FR-06-023 | Cấu hình ngưỡng tự hợp nhất, xem xét, khác biệt | 032 |
| FR-06-024 | Chạy thử bộ quy tắc trên mẫu | 033 |
| FR-06-025 | Quản lý tập nhãn kiểm chứng | 037, 038, 039, 123 |
| FR-06-026 | Đo precision, recall và chặn kích hoạt quy tắc kém | 034, 040 |
| FR-06-027 | Tạo mục hàng đợi và tính mức ưu tiên | 126 |
| FR-06-028 | Liệt kê, nhận việc và phân công mục hàng đợi | 045, 047, 107, 108, 124 |
| FR-06-029 | So sánh cạnh nhau hai bản ghi | 046 |
| FR-06-030 | Quyết định khớp, không khớp, hoãn | 048, 121 |
| FR-06-031 | Duyệt bốn mắt hợp nhất rủi ro cao | 049, 061, 109, 112 |
| FR-06-032 | Theo dõi SLA, nâng ưu tiên và cảnh báo quá tải | 050 |
| FR-06-033 | Cấu hình quy tắc sống sót thuộc tính | 051, 052, 053, 110, 111 |
| FR-06-034 | Tạo và cập nhật bản ghi vàng tự động | Hệ thống; xem ở 056, 063 |
| FR-06-035 | Xem chi tiết bản ghi vàng | 056, 122 |
| FR-06-036 | Sửa tay thuộc tính có lý do | 057 |
| FR-06-037 | Hợp nhất bản ghi vàng thủ công | 058, 061, 112 |
| FR-06-038 | Tách bản ghi vàng | 059, 061, 112 |
| FR-06-039 | Hoàn tác thao tác trên bản ghi vàng | 060, 061, 112, 122 |
| FR-06-040 | Ngừng và khôi phục bản ghi vàng | 062, 113 |
| FR-06-041 | Xem lịch sử phiên bản và so sánh hai phiên bản | 063, 064 |
| FR-06-042 | Xem trước tác động và áp lại sống sót hàng loạt | 054, 055 |
| FR-06-043 | Truy xuất nguồn gốc từng thuộc tính | 065 |
| FR-06-044 | Xem và gỡ liên kết chéo nguồn | 066, 067 |
| FR-06-045 | Tra ID nguồn và ID vàng | 068, 069 |
| FR-06-046 | Tra cứu bản ghi vàng theo ID hoặc khóa định danh | 056, 070 |
| FR-06-047 | Giải quyết bản ghi trực tuyến (resolve) | 071 |
| FR-06-048 | Tìm kiếm bản ghi vàng theo thuộc tính | 072 |
| FR-06-049 | Xuất dữ liệu chủ có kiểm soát | 073, 074, 075, 076, 114 |
| FR-06-050 | Phát sự kiện thay đổi bản ghi vàng | Sự kiện EVT-06-01…06, 14 (mục 4) |
| FR-06-051 | Đăng ký nhận cập nhật cho HTTT | 077, 078, 079, 115, 116, 117 |
| FR-06-052 | Che dữ liệu theo phân loại và mục đích PH-09 | Hệ thống che dữ liệu trong mọi phản hồi (mục 2.3) |
| FR-06-053 | Đồng bộ với CSDL tổng hợp quốc gia qua PH-14 | 022, 080, 081, 082, 118 |
| FR-06-054 | Xử lý danh sách lệch đồng bộ quốc gia | 082, 083, 084, 118 |
| FR-06-055 | Dashboard chỉ số dữ liệu chủ | 085 |
| FR-06-056 | Lịch job, chạy lại và hủy job | 041, 044, 086, 087, 105, 106 |
| FR-06-057 | Nhật ký xử lý và nhật ký truy cập | 088, 089 |
| FR-06-058 | Tiếp nhận và xử lý yêu cầu của chủ thể dữ liệu | 090, 091, 092, 119, 120, 125 |
| FR-06-059 | Chính sách lưu giữ và dọn dữ liệu | 093, 094 |
| FR-06-060 | Tham số phân hệ theo tenant | 095, 096 |

: Truy vết FR-06 sang API
<!-- gen:fr:end -->

## 10. Đề nghị bổ sung cho FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

### 10.1. Trường và enum chỉ có ở API

Các tên dưới đây có ở OpenAPI hoặc AsyncAPI mà FRS chưa có; không tự thêm vào Phụ lục A mà đề nghị FRS hấp thụ.

- **Enum**: `phase` của tệp lô (`UPLOADED`, `PREVIEWED`, `CONFIRMED`, `INGESTING`, `DONE`, `FAILED`, suy từ cột của `candidate_file`, `DONE`, `FAILED` dùng chung với mức nhật ký `INFO`, `WARN`, `ERROR` của `processing_log`); `reasonCode` của EVT-06-13 (`RATIO_EXCEEDED`, `RESUMED`) cùng `MANUAL`; trạng thái từng bản ghi nạp (`RECEIVED`, `DUPLICATE`, `SUPERSEDED`, `REJECTED`, có ở FR-06-010 nhưng không là enum `CandidateStatus`); `delivery` (`PUSH`, `PULL`); chế độ mẫu của chạy thử (FR-06-024).
- **Trường phản hồi**: `accessedAt`, `acceptWarnings`, `adminUnitName`, `autoMerge`, `review`, `thresholds`, `basedOnVersion`, `byReason`, `byStatus`, `candidateIds`, `changedAt`, `changedBy`, `changedGolden`, `columnMapping`, `compatLevel`, `configVersion`, `confirmLarge`, `description`, `discrepancyId`, `discrepancyIds`, `downloadUrl`, `duplicate`, `received`, `rejected`, `effectiveFrom`, `estimatedTotal`, `evaluatedAt`, `expiresAt`, `expression`, `finishedAt`, `startedAt`, `keys`, `lastRunAt`, `linkedAt`, `loggedAt`, `matchMethod`, `matchOutcome`, `newDiscrepancies`, `nextRunAt`, `note`, `oldestOpenDays`, `organizationName`, `yearOfBirth`, `origin`, `pairCount`, `pauseReason`, `phase`, `reasonCode`, `recordedAt`, `reportId`, `reportUrl`, `requestedAt`, `requestedBy`, `requiresApproval`, `applyDiscrepancies`, `lockedAt`, `lockedBy`, `undoable`, `undoDeadline`, `resultSummary`, `rowCount`, `rowErrors`, `ruleType`, `sourceCount`, `state`, `submittedBy`, `totalCapped`, `unmasked`, `xrefIds`. Phần lớn là trường kỹ thuật của danh sách, tiến độ, ngày giờ; đề nghị FRS bổ sung vào bảng dữ liệu ra của FR tương ứng.

Các trường phản hồi do màn hình yêu cầu (D03-06-PH06 Phụ lục B, mục B3 đến B6) đã được thêm vào OpenAPI ở bản đồng bộ chéo cuối, đều là trường tùy chọn: `thresholds`, `holdUntil`, `similarDecisions[]`, `nextItems[]` ở `StewardItemDetail` (API-06-046); `lineageHint` ở `GoldenRecord` (API-06-056, số giá trị khác nhau của từng thuộc tính); `criticalAlerts`, `queueByReason` và `bySource[]` có tỷ lệ định danh sai, trùng ở `DashboardMetrics` (API-06-085); `scoreDistribution[]` (100 khoảng điểm) ở `AccuracyReport` (API-06-040, kết quả của API-06-034 `:evaluate`); kết quả của `:dry-run` (API-06-033) chưa có lược đồ riêng nên phần phân bố điểm của chạy thử còn chờ chốt cùng SDD. FRS không cần hấp thụ các trường này (quyết định của FRS 0.2, Phụ lục C).

### 10.2. Đề nghị khác

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Ngoài trường và enum, tập này đề nghị FRS xử lý các điểm sau.

| Số | Nội dung | Tập này đang làm |
|---|---|---|
| 1 | FRS 9.4 gộp 15 dòng nhiều hành động nhưng khuôn K-API cần mỗi operation một mã | Đã áp ở FRS 0.2: giữ mã FRS cho hành động đầu, API-06-097…120 (mục 3.1) |
| 2 | FRS 9.1 chưa có mã cho `401`, `403` thiếu quyền chức năng, `428` thiếu `If-Match` | Đã áp ở FRS 0.2: dùng `ERR-00-401`, `ERR-00-403`, `ERR-00-428` (mục 6) |
| 3 | FRS 9.4 chưa quy định `X-Purpose`, `X-Unmask-Reason` | Đã áp ở FRS 0.2 (9.4, tiêu đề bắt buộc): tra cứu (068…072) và xem bản ghi vàng có `unmask` |
| 4 | `identifierRule.validator` có `REGEX` nhưng chưa có enum | Đã áp ở FRS 0.2: Dùng chuỗi tự do kèm `pattern` (CSDL D03-03 đề nghị 2) |
| 5 | `attribute` rỗng ở ưu tiên nguồn nghĩa là mọi thuộc tính | Đã áp ở FRS 0.2: Dùng giá trị `*` (CSDL D03-03) |
| 6 | Gói nền cài với phiên bản `ACTIVE` không qua bốn mắt | Đã áp ở FRS 0.2: API-06-012 ghi nhận (CSDL D03-03) |
| 7 | ERR-06-008 (thay đổi phá vỡ khi sửa trực tiếp) cần ngữ cảnh | Đã áp ở FRS 0.2: Gắn API-06-006 `PUT` phiên bản nháp trả `422` |
| 8 | Bản 0.2 thêm API-06-121…125, `decision` ở API-06-106, `cause` ở API-06-118, `partition` ở API-06-045 | Đã làm ở OpenAPI và mục 12; không còn đề nghị mở |

: Đề nghị khác cho FRS

## 11. Câu hỏi mở

Các câu hỏi dưới đây chưa có quyết định; cột đề xuất là giả định tạm dùng.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q06-55 | Hạn mức nạp, tra cứu theo nguồn: trả `Retry-After` và tiêu đề `RateLimit-*`; ngưỡng 6.000 bản ghi mỗi phút (`06.ingest.rate-per-source`) tính theo bản ghi hay theo yêu cầu | Theo bản ghi, hạn mức ở APISIX và `dh-data` |
| Q06-56 | `X-Unmask-Reason` và `unmask` ở `GET` có đủ an toàn, hay chuyển sang `POST …:reveal` có thân | Tiêu đề cho lý do, tên thuộc tính ở truy vấn không phải DLCN; chuyển `POST` nếu ATTT yêu cầu |
| Q06-57 | Cần `GET` danh sách bản ghi vàng (duyệt) ngoài tìm kiếm `POST` (UI-06-02) không | Không: tìm kiếm có tiêu chí bắt buộc, tránh duyệt toàn bộ DLCN (ERR-06-040) |
| Q06-58 | Giao nhận cập nhật bằng `PUSH` (webhook) dùng kênh của PH-10 hay do PH-06 tự phát; lưu giữ topic mặc định | Dùng kênh PH-10 (FR-10-067); 7 ngày, 3 phân vùng theo mức của PH-05 |
| Q06-59 | Chấp nhận mã tách 097…120 hay chuyển dòng gộp thành một operation có tham số `{action}` | Mã tách, theo tiền lệ PH-10 (mục 3.1) |

: Câu hỏi mở của tập API PH-06

## 12. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục.

<!-- gen:dac-ta-api:start -->

### Domain và mô hình

#### API-06-001 · Danh sách, tìm kiếm domain

::: dac-ta
**Mục đích.** Danh sách, tìm kiếm domain.

**Phương thức, đường dẫn.** `GET /domains`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-001.

**Tham số.** `status` (query, DomainStatus, tùy chọn); `q` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DomainPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-001, ERR-06-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-002 · Chi tiết domain

::: dac-ta
**Mục đích.** Chi tiết domain.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-001.

**Tham số.** `domainCode` (path, string, bắt buộc); `version` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DomainDetail`; trường bắt buộc: `domainCode`, `name`, `status`, `attributes`, `identifiers`, `versions`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-001, ERR-06-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-003 · Tạo domain

::: dac-ta
**Mục đích.** Tạo domain.

**Phương thức, đường dẫn.** `POST /domains`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-002.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DomainCreate`; trường bắt buộc: `domainCode`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Domain`; trường bắt buộc: `domainCode`, `name`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-003, ERR-06-004, ERR-06-006, ERR-06-009, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-004 · Danh sách phiên bản mô hình

::: dac-ta
**Mục đích.** Danh sách phiên bản mô hình.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/model-versions`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-005.

**Tham số.** `domainCode` (path, string, bắt buộc); `status` (query, VersionStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModelVersionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-005 · Tạo phiên bản mô hình nháp

::: dac-ta
**Mục đích.** Tạo phiên bản mô hình nháp.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/model-versions`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-002, FR-06-005.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ModelVersionCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ModelVersion`; trường bắt buộc: `domainCode`, `version`, `status`, `attributes`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-003, ERR-06-004, ERR-06-006, ERR-06-009, ERR-06-001, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-006 · Sửa phiên bản mô hình nháp

::: dac-ta
**Mục đích.** Sửa phiên bản mô hình nháp.

**Phương thức, đường dẫn.** `PUT /domains/{domainCode}/model-versions/{version}`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-002, FR-06-003, FR-06-004.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `ModelVersionUpdate`; trường bắt buộc: `attributes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModelVersion`; trường bắt buộc: `domainCode`, `version`, `status`, `attributes`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`, `503`; mã lỗi của thao tác: ERR-06-002, ERR-06-003, ERR-06-004, ERR-06-006, ERR-06-009, ERR-06-052, ERR-06-010, ERR-06-021, ERR-06-001, ERR-06-008 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-007 · So sánh hai phiên bản mô hình

::: dac-ta
**Mục đích.** So sánh hai phiên bản mô hình.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/model-versions/{version}/diff`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-005.

**Tham số.** `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `with` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModelDiff`; trường bắt buộc: `changes`, `affectedSources`, `affectedGoldenCount`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-008 · Gửi duyệt phiên bản mô hình

::: dac-ta
**Mục đích.** Gửi duyệt phiên bản mô hình.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/model-versions/{version}:submit`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-006.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModelVersion`; trường bắt buộc: `domainCode`, `version`, `status`, `attributes`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-006, ERR-06-007, ERR-06-011, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-009 · Duyệt phiên bản mô hình

::: dac-ta
**Mục đích.** Duyệt phiên bản mô hình.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/model-versions/{version}:approve`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-006.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModelVersion`; trường bắt buộc: `domainCode`, `version`, `status`, `attributes`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-006, ERR-06-007, ERR-06-011, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-010 · Từ chối phiên bản mô hình

::: dac-ta
**Mục đích.** Từ chối phiên bản mô hình.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/model-versions/{version}:reject`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-006.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ModelVersion`; trường bắt buộc: `domainCode`, `version`, `status`, `attributes`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-006, ERR-06-007, ERR-06-011, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-011 · Tạm ngừng domain

::: dac-ta
**Mục đích.** Tạm ngừng domain.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}:suspend`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-006.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Domain`; trường bắt buộc: `domainCode`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-006, ERR-06-007, ERR-06-011, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-012 · Nạp gói domain nền

::: dac-ta
**Mục đích.** Nạp gói domain nền.

**Phương thức, đường dẫn.** `POST /domains:install-baseline`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `InstallBaselineRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InstallBaselineResult`; trường bắt buộc: `installed`, `skipped`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-06-001, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gói nền cài với phiên bản `ACTIVE` không qua duyệt bốn mắt (cột người gửi bỏ trống), có đề nghị bổ sung cho FRS.
:::

#### API-06-013 · Thử bộ kiểm tra khóa định danh

::: dac-ta
**Mục đích.** Thử bộ kiểm tra khóa định danh.

**Phương thức, đường dẫn.** `POST /identifier-rules:test`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-003.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IdentifierTestRequest`; trường bắt buộc: `validator`, `values`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IdentifierTestResult`; trường bắt buộc: `results`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-003, ERR-06-009, ERR-06-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-097 · Tiếp tục domain

::: dac-ta
**Mục đích.** Tiếp tục domain.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}:resume`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-006.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Domain`; trường bắt buộc: `domainCode`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-006, ERR-06-007, ERR-06-011, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-098 · Ngừng domain

::: dac-ta
**Mục đích.** Ngừng domain.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}:retire`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-006.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Domain`; trường bắt buộc: `domainCode`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-006, ERR-06-007, ERR-06-011, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Nguồn và ưu tiên nguồn

#### API-06-014 · Danh sách nguồn

::: dac-ta
**Mục đích.** Danh sách nguồn.

**Phương thức, đường dẫn.** `GET /sources`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-008.

**Tham số.** `status` (query, SourceStatus, tùy chọn); `kind` (query, SourceKind, tùy chọn); `domainCode` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SourcePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-012 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-015 · Đăng ký nguồn

::: dac-ta
**Mục đích.** Đăng ký nguồn.

**Phương thức, đường dẫn.** `POST /sources`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SourceCreate`; trường bắt buộc: `sourceCode`, `sourceKind`, `domains`, `channels`, `ownerOrgCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Source`; trường bắt buộc: `sourceCode`, `sourceKind`, `domains`, `channels`, `ownerOrgCode`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-012, ERR-06-003, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-016 · Sửa nguồn

::: dac-ta
**Mục đích.** Sửa nguồn.

**Phương thức, đường dẫn.** `PATCH /sources/{sourceCode}`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-008, FR-06-012.

**Tham số.** `If-Match` (header, string, bắt buộc); `sourceCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SourceUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Source`; trường bắt buộc: `sourceCode`, `sourceKind`, `domains`, `channels`, `ownerOrgCode`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-012, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-017 · Tạm ngừng nguồn

::: dac-ta
**Mục đích.** Tạm ngừng nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:suspend`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-008.

**Tham số.** `If-Match` (header, string, bắt buộc); `sourceCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Source`; trường bắt buộc: `sourceCode`, `sourceKind`, `domains`, `channels`, `ownerOrgCode`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-012, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-018 · Bảng ưu tiên nguồn hiện hành

::: dac-ta
**Mục đích.** Bảng ưu tiên nguồn hiện hành.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/source-priorities`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-009.

**Tham số.** `domainCode` (path, string, bắt buộc); `attribute` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SourcePriorityTable`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-013, ERR-06-035, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-019 · Đề nghị thứ tự ưu tiên nguồn

::: dac-ta
**Mục đích.** Đề nghị thứ tự ưu tiên nguồn.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/source-priorities:propose`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-009.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `PriorityProposalRequest`; trường bắt buộc: `entries`, `approvalRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `PriorityProposal`; trường bắt buộc: `proposalId`, `status`, `entries`, `approvalRef`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-013, ERR-06-035, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-020 · Duyệt đề nghị ưu tiên nguồn

::: dac-ta
**Mục đích.** Duyệt đề nghị ưu tiên nguồn.

**Phương thức, đường dẫn.** `POST /source-priority-proposals/{proposalId}:approve`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-009.

**Tham số.** `If-Match` (header, string, bắt buộc); `proposalId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SourcePriorityTable`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-013, ERR-06-035, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-099 · Tiếp tục nguồn

::: dac-ta
**Mục đích.** Tiếp tục nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:resume`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-008.

**Tham số.** `If-Match` (header, string, bắt buộc); `sourceCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Source`; trường bắt buộc: `sourceCode`, `sourceKind`, `domains`, `channels`, `ownerOrgCode`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-012, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-100 · Ngừng nguồn

::: dac-ta
**Mục đích.** Ngừng nguồn.

**Phương thức, đường dẫn.** `POST /sources/{sourceCode}:retire`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-008.

**Tham số.** `If-Match` (header, string, bắt buộc); `sourceCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Source`; trường bắt buộc: `sourceCode`, `sourceKind`, `domains`, `channels`, `ownerOrgCode`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-012, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-101 · Từ chối đề nghị ưu tiên nguồn

::: dac-ta
**Mục đích.** Từ chối đề nghị ưu tiên nguồn.

**Phương thức, đường dẫn.** `POST /source-priority-proposals/{proposalId}:reject`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-009.

**Tham số.** `If-Match` (header, string, bắt buộc); `proposalId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PriorityProposal`; trường bắt buộc: `proposalId`, `status`, `entries`, `approvalRef`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-013, ERR-06-035, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Nạp ứng viên

#### API-06-021 · Nạp bản ghi ứng viên qua API

::: dac-ta
**Mục đích.** Nạp bản ghi ứng viên qua API.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/candidates`.

**Quyền.** `PERM-06-ingest hoặc scope `mdm:ingest``.

**FR hiện thực.** FR-06-010, FR-06-016.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CandidateIngestRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CandidateIngestResult`; trường bắt buộc: `results`; tiêu đề `ETag`; `207`, `CandidateIngestResult`; trường bắt buộc: `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `422`, `429`; mã lỗi của thao tác: ERR-06-014, ERR-06-016, ERR-06-017, ERR-06-018, ERR-06-048, ERR-06-015, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mỗi bản ghi xử lý riêng; có bản ghi lỗi trả `207` kèm `results[]`, bản ghi tốt vẫn được nhận. `Idempotency-Key` dùng lại với nội dung khác: ERR-06-015.
:::

#### API-06-022 · Nạp bản ghi ứng viên qua luồng PH-04

::: dac-ta
**Mục đích.** Nạp bản ghi ứng viên qua luồng PH-04.

**Phương thức, đường dẫn.** `POST /internal/domains/{domainCode}/candidates`.

**Quyền.** scope `mdm:ingest`.

**FR hiện thực.** FR-06-011, FR-06-016, FR-06-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `InternalIngestRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CandidateIngestResult`; trường bắt buộc: `results`; tiêu đề `ETag`; `207`, `CandidateIngestResult`; trường bắt buộc: `results`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-014, ERR-06-017, ERR-06-015, ERR-06-044, ERR-06-045, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ qua `/internal` trong mạng nội bộ, token máy gắn nguồn; không có ở BFF.
:::

#### API-06-023 · Tải tệp lô lên để xem trước

::: dac-ta
**Mục đích.** Tải tệp lô lên để xem trước.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/candidate-files`.

**Quyền.** `PERM-06-ingest`.

**FR hiện thực.** FR-06-013.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `CandidateFileUpload`; trường bắt buộc: `file`, `sourceCode`, `domainCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CandidateFile`; trường bắt buộc: `fileId`, `phase`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `422`; mã lỗi của thao tác: ERR-06-018, ERR-06-019, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-024 · Xác nhận nạp tệp lô

::: dac-ta
**Mục đích.** Xác nhận nạp tệp lô.

**Phương thức, đường dẫn.** `POST /candidate-files/{fileId}:confirm`.

**Quyền.** `PERM-06-ingest`.

**FR hiện thực.** FR-06-013.

**Tham số.** `If-Match` (header, string, bắt buộc); `fileId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `FileConfirm`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CandidateFile`; trường bắt buộc: `fileId`, `phase`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `422`, `428`; mã lỗi của thao tác: ERR-06-018, ERR-06-019, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-025 · Trạng thái tệp lô

::: dac-ta
**Mục đích.** Trạng thái tệp lô.

**Phương thức, đường dẫn.** `GET /candidate-files/{fileId}`.

**Quyền.** `PERM-06-ingest`.

**FR hiện thực.** FR-06-013.

**Tham số.** `fileId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CandidateFile`; trường bắt buộc: `fileId`, `phase`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `413`, `422`; mã lỗi của thao tác: ERR-06-018, ERR-06-019, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-026 · Danh sách bản ghi ứng viên

::: dac-ta
**Mục đích.** Danh sách bản ghi ứng viên.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/candidates`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-017.

**Tham số.** `domainCode` (path, string, bắt buộc); `sourceCode` (query, string, tùy chọn); `status` (query, CandidateStatus, tùy chọn); `warning` (query, NormalizationWarning, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `sourceKey` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CandidatePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-007, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-027 · Chi tiết bản ghi ứng viên

::: dac-ta
**Mục đích.** Chi tiết bản ghi ứng viên.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/candidates/{candidateId}`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-014, FR-06-017.

**Tham số.** `domainCode` (path, string, bắt buộc); `candidateId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CandidateDetail`; trường bắt buộc: `candidateId`, `sourceCode`, `sourceKey`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-007, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-028 · Xử lý lại ứng viên

::: dac-ta
**Mục đích.** Xử lý lại ứng viên.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/candidates:reprocess`.

**Quyền.** `PERM-06-ingest`.

**FR hiện thực.** FR-06-017.

**Tham số.** `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CandidateBulkRequest`; trường bắt buộc: `candidateIds`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BulkActionResult`; trường bắt buộc: `accepted`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-007, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-029 · Xem trước chuẩn hóa

::: dac-ta
**Mục đích.** Xem trước chuẩn hóa.

**Phương thức, đường dẫn.** `POST /normalization:preview`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-014, FR-06-015.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `NormalizePreviewRequest`; trường bắt buộc: `domainCode`, `attributes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NormalizePreviewResult`; trường bắt buộc: `raw`, `normalized`, `warnings`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-102 · Loại bỏ ứng viên

::: dac-ta
**Mục đích.** Loại bỏ ứng viên.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/candidates:discard`.

**Quyền.** `PERM-06-ingest`.

**FR hiện thực.** FR-06-017.

**Tham số.** `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CandidateBulkRequest`; trường bắt buộc: `candidateIds`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BulkActionResult`; trường bắt buộc: `accepted`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-007, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Quy tắc đối sánh

#### API-06-030 · Danh sách bộ quy tắc đối sánh

::: dac-ta
**Mục đích.** Danh sách bộ quy tắc đối sánh.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/rule-sets`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-018.

**Tham số.** `domainCode` (path, string, bắt buộc); `status` (query, VersionStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-024, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-031 · Tạo bộ quy tắc nháp

::: dac-ta
**Mục đích.** Tạo bộ quy tắc nháp.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/rule-sets`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleSetCreate`; trường bắt buộc: `rules`, `blockingKeys`, `thresholds`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RuleSet`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`, `blockingKeys`, `thresholds`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-024, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-032 · Sửa bộ quy tắc nháp

::: dac-ta
**Mục đích.** Sửa bộ quy tắc nháp.

**Phương thức, đường dẫn.** `PUT /domains/{domainCode}/rule-sets/{version}`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-018, FR-06-019, FR-06-023.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `RuleSetUpdate`; trường bắt buộc: `rules`, `blockingKeys`, `thresholds`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`, `blockingKeys`, `thresholds`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-024, ERR-06-023, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-033 · Chạy thử bộ quy tắc trên mẫu

::: dac-ta
**Mục đích.** Chạy thử bộ quy tắc trên mẫu.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/rule-sets/{version}:dry-run`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-024.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `DryRunRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-025, ERR-06-047, ERR-06-003, ERR-06-004, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-034 · Đo precision, recall của bộ quy tắc

::: dac-ta
**Mục đích.** Đo precision, recall của bộ quy tắc.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/rule-sets/{version}:evaluate`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-026.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `EvaluateRequest`; trường bắt buộc: `labelSetCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-024, ERR-06-026, ERR-06-003, ERR-06-004, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-035 · Gửi duyệt bộ quy tắc

::: dac-ta
**Mục đích.** Gửi duyệt bộ quy tắc.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/rule-sets/{version}:submit`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-018.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`, `blockingKeys`, `thresholds`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-024, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-036 · Thống kê khóa gom nhóm

::: dac-ta
**Mục đích.** Thống kê khóa gom nhóm.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/rule-sets/{version}/blocking-stats`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-019.

**Tham số.** `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BlockingStats`; trường bắt buộc: `keys`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-022, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-037 · Danh sách tập nhãn

::: dac-ta
**Mục đích.** Danh sách tập nhãn.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/label-sets`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-025.

**Tham số.** `domainCode` (path, string, bắt buộc); `purpose` (query, LabelSetPurpose, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LabelSetPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-051, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-038 · Tạo tập nhãn

::: dac-ta
**Mục đích.** Tạo tập nhãn.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/label-sets`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `LabelSetCreate`; trường bắt buộc: `labelSetCode`, `purpose`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LabelSet`; trường bắt buộc: `labelSetCode`, `domainCode`, `purpose`, `locked`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-051, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-039 · Thêm cặp nhãn vào tập

::: dac-ta
**Mục đích.** Thêm cặp nhãn vào tập.

**Phương thức, đường dẫn.** `POST /label-sets/{labelSetCode}/pairs`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `labelSetCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `LabelPairsRequest`; trường bắt buộc: `pairs`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LabelSet`; trường bắt buộc: `labelSetCode`, `domainCode`, `purpose`, `locked`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-051, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-040 · Danh sách báo cáo độ chính xác

::: dac-ta
**Mục đích.** Danh sách báo cáo độ chính xác.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/accuracy-reports`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-026.

**Tham số.** `domainCode` (path, string, bắt buộc); `ruleSetVersion` (query, integer, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccuracyReportPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-024, ERR-06-026, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-103 · Duyệt bộ quy tắc

::: dac-ta
**Mục đích.** Duyệt bộ quy tắc.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/rule-sets/{version}:approve`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-018.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`, `blockingKeys`, `thresholds`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-024, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-104 · Từ chối bộ quy tắc

::: dac-ta
**Mục đích.** Từ chối bộ quy tắc.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/rule-sets/{version}:reject`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-018.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `version` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`, `blockingKeys`, `thresholds`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-024, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-123 · Khóa tập nhãn kiểm chứng

::: dac-ta
**Mục đích.** Khóa tập nhãn kiểm chứng.

**Phương thức, đường dẫn.** `POST /label-sets/{labelSetCode}:lock`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-025.

**Tham số.** `If-Match` (header, string, bắt buộc); `labelSetCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LabelSet`; trường bắt buộc: `labelSetCode`, `domainCode`, `purpose`, `locked`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-002, ERR-06-006, ERR-06-051, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khóa rồi không mở lại; thêm cặp sau đó tạo tập nhãn phiên bản mới. Ghi kiểm toán.
:::

### Job đối sánh

#### API-06-041 · Danh sách job

::: dac-ta
**Mục đích.** Danh sách job.

**Phương thức, đường dẫn.** `GET /match-jobs`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-022, FR-06-056.

**Tham số.** `domainCode` (query, string, tùy chọn); `jobType` (query, JobType, tùy chọn); `status` (query, JobStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MatchJobPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-025, ERR-06-006, ERR-06-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-042 · Tạo job đối sánh lô

::: dac-ta
**Mục đích.** Tạo job đối sánh lô.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/match-jobs`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-022.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `MatchJobCreate`; trường bắt buộc: `domainCode`, `scope`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-06-025, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-043 · Chi tiết job

::: dac-ta
**Mục đích.** Chi tiết job.

**Phương thức, đường dẫn.** `GET /match-jobs/{jobId}`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-022.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MatchJob`; trường bắt buộc: `jobId`, `domainCode`, `jobType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-06-025, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-044 · Hủy job

::: dac-ta
**Mục đích.** Hủy job.

**Phương thức, đường dẫn.** `POST /match-jobs/{jobId}:cancel`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-022, FR-06-056.

**Tham số.** `If-Match` (header, string, bắt buộc); `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MatchJob`; trường bắt buộc: `jobId`, `domainCode`, `jobType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-025, ERR-06-006, ERR-06-047, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-105 · Chạy lại job

::: dac-ta
**Mục đích.** Chạy lại job.

**Phương thức, đường dẫn.** `POST /match-jobs/{jobId}:rerun`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-022, FR-06-056.

**Tham số.** `If-Match` (header, string, bắt buộc); `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RerunRequest`; trường bắt buộc: `fromStep`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-025, ERR-06-006, ERR-06-047, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-106 · Xác nhận job vượt ngưỡng an toàn

::: dac-ta
**Mục đích.** Xác nhận job vượt ngưỡng an toàn.

**Phương thức, đường dẫn.** `POST /match-jobs/{jobId}:confirm`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-022, FR-06-056.

**Tham số.** `If-Match` (header, string, bắt buộc); `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `JobConfirmRequest`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MatchJob`; trường bắt buộc: `jobId`, `domainCode`, `jobType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-025, ERR-06-006, ERR-06-047, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thân có `decision` (`ApprovalDecision`): `REJECT` chuyển job `AWAITING_CONFIRMATION` sang `CANCELLED`, không áp cặp nào.
:::

### Hàng đợi người quản lý

#### API-06-045 · Danh sách mục hàng đợi

::: dac-ta
**Mục đích.** Danh sách mục hàng đợi.

**Phương thức, đường dẫn.** `GET /stewardship/items`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-028.

**Tham số.** `domainCode` (query, string, tùy chọn); `reason` (query, QueueReason, tùy chọn); `status` (query, QueueItemStatus, tùy chọn); `assignee` (query, string, tùy chọn); `riskLevel` (query, RiskLevel, tùy chọn); `overdue` (query, boolean, tùy chọn); `sourceCode` (query, string, tùy chọn); `partition` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItemPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `409`; mã lỗi của thao tác: ERR-06-027, ERR-06-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lọc `partition`: `mine`, `unclaimed`, `overdue`, `pending-approval`.
:::

#### API-06-046 · So sánh cạnh nhau hai bản ghi

::: dac-ta
**Mục đích.** So sánh cạnh nhau hai bản ghi.

**Phương thức, đường dẫn.** `GET /stewardship/items/{itemId}`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-029.

**Tham số.** `itemId` (path, string, bắt buộc); `unmask` (query, string, tùy chọn); `X-Unmask-Reason` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItemDetail`; trường bắt buộc: `item`, `left`, `right`, `attributes`, `mergeAllowed`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-06-030, ERR-06-039, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xem giá trị `SENSITIVE` đầy đủ cần `PERM-09-unmask` và tiêu đề `X-Unmask-Reason`; không có thì giá trị che.
:::

#### API-06-047 · Nhận mục hàng đợi

::: dac-ta
**Mục đích.** Nhận mục hàng đợi.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:claim`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-028.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `428`; mã lỗi của thao tác: ERR-06-027, ERR-06-028, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-048 · Quyết định khớp, không khớp, hoãn

::: dac-ta
**Mục đích.** Quyết định khớp, không khớp, hoãn.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:decide`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-030.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DecideRequest`; trường bắt buộc: `decision`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-007, ERR-06-029, ERR-06-030, ERR-06-031, ERR-06-053, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-049 · Duyệt bốn mắt hợp nhất rủi ro cao

::: dac-ta
**Mục đích.** Duyệt bốn mắt hợp nhất rủi ro cao.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:approve`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-031.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-007, ERR-06-030, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-050 · Thống kê hàng đợi

::: dac-ta
**Mục đích.** Thống kê hàng đợi.

**Phương thức, đường dẫn.** `GET /stewardship/stats`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-032.

**Tham số.** `domainCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardStats`; trường bắt buộc: `byStatus`, `overdue`; tiêu đề `ETag`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền.

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-107 · Trả mục hàng đợi

::: dac-ta
**Mục đích.** Trả mục hàng đợi.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:release`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-028.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `428`; mã lỗi của thao tác: ERR-06-027, ERR-06-028, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-108 · Phân công mục hàng đợi

::: dac-ta
**Mục đích.** Phân công mục hàng đợi.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:assign`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-028.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `AssignRequest`; trường bắt buộc: `assigneeId`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi của thao tác: ERR-06-027, ERR-06-028, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-109 · Từ chối hợp nhất rủi ro cao

::: dac-ta
**Mục đích.** Từ chối hợp nhất rủi ro cao.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:reject`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-031.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-007, ERR-06-030, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-121 · Mở lại quyết định hàng đợi

::: dac-ta
**Mục đích.** Mở lại quyết định hàng đợi.

**Phương thức, đường dẫn.** `POST /stewardship/items/{itemId}:reopen`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-030.

**Tham số.** `If-Match` (header, string, bắt buộc); `itemId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-007, ERR-06-029, ERR-06-030, ERR-06-031, ERR-06-053, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trong `06.queue.reopen-hours` (24 giờ) và chưa có thao tác phụ thuộc; quá hạn ERR-06-053. Hoàn tác thay đổi bản ghi vàng của quyết định cũ rồi đưa mục về `ASSIGNED`.
:::

#### API-06-124 · Nhận mục hàng đợi tiếp theo

::: dac-ta
**Mục đích.** Nhận mục hàng đợi tiếp theo.

**Phương thức, đường dẫn.** `POST /stewardship/items:claim-next`.

**Quyền.** `PERM-06-steward`.

**FR hiện thực.** FR-06-028.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ClaimNextRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardItem`; trường bắt buộc: `itemId`, `domainCode`, `reason`, `status`, `riskLevel`; tiêu đề `ETag`; `204` không có nội dung.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-06-027, ERR-06-028, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Một lệnh nguyên tử (`SKIP LOCKED`); hết mục phù hợp trả `204`, không lỗi. Mục gán `ASSIGNED` giữ `06.queue.hold-minutes`.
:::

#### API-06-126 · Tạo mục hàng đợi từ phát hiện chất lượng (PH-08)

::: dac-ta
**Mục đích.** Tạo mục hàng đợi từ phát hiện chất lượng (PH-08).

**Phương thức, đường dẫn.** `POST /internal/stewardship/items:from-dq`.

**Quyền.** scope `mdm:steward-intake`.

**FR hiện thực.** FR-06-027.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StewardIntakeRequest`; trường bắt buộc: `domainCode`, `goldenId`, `ruleCodes`, `suggestedAction`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `StewardIntakeResult`; trường bắt buộc: `itemId`, `created`, `reason`, `priority`, `dueAt`; tiêu đề `ETag`, `Location`; `200` thành công, `StewardIntakeResult`; trường bắt buộc: `itemId`, `created`, `reason`, `priority`, `dueAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-047, ERR-06-050, ERR-06-003, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** API nội bộ chỉ qua `apisix-int` với scope `mdm:steward-intake` của PH-08; tạo mục lý do `DQ_FINDING` (điểm cơ sở 35, hạn theo `06.queue.sla-days`, người nhận là DS của miền). `201` mục mới; `200` khi đã có mục mở cho `goldenId` nên chỉ gắn thêm mã quy tắc. Không nhận lý do khác.
:::

### Quy tắc sống sót

#### API-06-051 · Cấu hình sống sót hiện hành

::: dac-ta
**Mục đích.** Cấu hình sống sót hiện hành.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/survivorship-rules`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-033.

**Tham số.** `domainCode` (path, string, bắt buộc); `version` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SurvivorshipConfig`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-035, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-052 · Soạn cấu hình sống sót

::: dac-ta
**Mục đích.** Soạn cấu hình sống sót.

**Phương thức, đường dẫn.** `PUT /domains/{domainCode}/survivorship-rules`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-033.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SurvivorshipPut`; trường bắt buộc: `rules`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SurvivorshipConfig`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-035, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bản nháp cấu hình sống sót; cần duyệt bốn mắt trước khi `ACTIVE` (BR-06-019).
:::

#### API-06-053 · Gửi duyệt cấu hình sống sót

::: dac-ta
**Mục đích.** Gửi duyệt cấu hình sống sót.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/survivorship-rules:submit`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-033.

**Tham số.** `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SurvivorshipConfig`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-035, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-054 · Xem trước tác động của cấu hình sống sót

::: dac-ta
**Mục đích.** Xem trước tác động của cấu hình sống sót.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/survivorship-rules:impact`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-042.

**Tham số.** `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SurvivorshipImpactRequest`; trường bắt buộc: `rules`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SurvivorshipImpact`; trường bắt buộc: `sampleSize`, `changedGolden`, `changedAttributes`, `requiresApproval`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-06-025, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-055 · Áp lại sống sót hàng loạt

::: dac-ta
**Mục đích.** Áp lại sống sót hàng loạt.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/survivorship-rules:reapply`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-042.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReapplyRequest`; trường bắt buộc: `configVersion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-06-025, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-110 · Duyệt cấu hình sống sót

::: dac-ta
**Mục đích.** Duyệt cấu hình sống sót.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/survivorship-rules:approve`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-033.

**Tham số.** `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SurvivorshipConfig`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-035, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-111 · Từ chối cấu hình sống sót

::: dac-ta
**Mục đích.** Từ chối cấu hình sống sót.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/survivorship-rules:reject`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-033.

**Tham số.** `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SurvivorshipConfig`; trường bắt buộc: `domainCode`, `version`, `status`, `rules`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-022, ERR-06-035, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Bản ghi vàng

#### API-06-056 · Chi tiết bản ghi vàng

::: dac-ta
**Mục đích.** Chi tiết bản ghi vàng.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/golden-records/{goldenId}`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-035, FR-06-046.

**Tham số.** `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc); `unmask` (query, string, tùy chọn); `X-Unmask-Reason` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenRecord`; trường bắt buộc: `goldenId`, `domainCode`, `status`, `attributes`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `503`; mã lỗi của thao tác: ERR-06-001, ERR-06-039, ERR-06-037, ERR-06-050 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xem giá trị `SENSITIVE` đầy đủ cần `PERM-09-unmask` và tiêu đề `X-Unmask-Reason`; `410` khi bản ghi `RETIRED`. Mọi lượt đọc ghi nhật ký truy cập (BR-06-010), không ghi được thì từ chối (ERR-06-039).
:::

#### API-06-057 · Sửa tay thuộc tính bản ghi vàng

::: dac-ta
**Mục đích.** Sửa tay thuộc tính bản ghi vàng.

**Phương thức, đường dẫn.** `PATCH /domains/{domainCode}/golden-records/{goldenId}/attributes`.

**Quyền.** `PERM-06-update`.

**FR hiện thực.** FR-06-036.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `AttributePatchRequest`; trường bắt buộc: `attribute`, `value`, `reason`, `evidenceRef`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-004, ERR-06-031, ERR-06-035, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-058 · Hợp nhất bản ghi vàng thủ công

::: dac-ta
**Mục đích.** Hợp nhất bản ghi vàng thủ công.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records:merge`.

**Quyền.** `PERM-06-merge`.

**FR hiện thực.** FR-06-037.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `MergeRequest`; trường bắt buộc: `goldenIds`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-003, ERR-06-006, ERR-06-029, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `200` khi thực hiện ngay, `202` khi rủi ro cao chờ duyệt bốn mắt (`status = PENDING_APPROVAL`).
:::

#### API-06-059 · Tách bản ghi vàng

::: dac-ta
**Mục đích.** Tách bản ghi vàng.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records/{goldenId}:split`.

**Quyền.** `PERM-06-merge`.

**FR hiện thực.** FR-06-038.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SplitRequest`; trường bắt buộc: `groups`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-031, ERR-06-032, ERR-06-003, ERR-06-004, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `200` hoặc `202` khi bản ghi có từ 3 liên kết chờ duyệt.
:::

#### API-06-060 · Hoàn tác thao tác

::: dac-ta
**Mục đích.** Hoàn tác thao tác.

**Phương thức, đường dẫn.** `POST /operations/{operationId}:undo`.

**Quyền.** `PERM-06-merge`.

**FR hiện thực.** FR-06-039.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `operationId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `UndoRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-06-006, ERR-06-033, ERR-06-034, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trong 90 ngày không cần duyệt; quá hạn chờ duyệt (ERR-06-034).
:::

#### API-06-061 · Duyệt thao tác rủi ro cao

::: dac-ta
**Mục đích.** Duyệt thao tác rủi ro cao.

**Phương thức, đường dẫn.** `POST /operations/{operationId}:approve`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-031, FR-06-037, FR-06-038, FR-06-039.

**Tham số.** `If-Match` (header, string, bắt buộc); `operationId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-007, ERR-06-030, ERR-06-003, ERR-06-006, ERR-06-029, ERR-06-031, ERR-06-032, ERR-06-033, ERR-06-034, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-062 · Ngừng bản ghi vàng

::: dac-ta
**Mục đích.** Ngừng bản ghi vàng.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records/{goldenId}:retire`.

**Quyền.** `PERM-06-merge`.

**FR hiện thực.** FR-06-040.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RetireRequest`; trường bắt buộc: `retireReason`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenRecord`; trường bắt buộc: `goldenId`, `domainCode`, `status`, `attributes`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-036, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-063 · Lịch sử phiên bản bản ghi vàng

::: dac-ta
**Mục đích.** Lịch sử phiên bản bản ghi vàng.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/golden-records/{goldenId}/history`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-041.

**Tham số.** `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc); `asOf` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-064 · Một phiên bản lịch sử và so sánh

::: dac-ta
**Mục đích.** Một phiên bản lịch sử và so sánh.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/golden-records/{goldenId}/history/{version}`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-041.

**Tham số.** `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc); `version` (path, integer, bắt buộc); `compareWith` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistorySnapshot`; trường bắt buộc: `version`, `snapshot`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-065 · Truy nguồn gốc thuộc tính

::: dac-ta
**Mục đích.** Truy nguồn gốc thuộc tính.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/golden-records/{goldenId}/lineage`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-043.

**Tham số.** `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc); `attribute` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LineageResult`; trường bắt buộc: `goldenId`, `attributes`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`; mã lỗi của thao tác: ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-112 · Từ chối thao tác rủi ro cao

::: dac-ta
**Mục đích.** Từ chối thao tác rủi ro cao.

**Phương thức, đường dẫn.** `POST /operations/{operationId}:reject`.

**Quyền.** `PERM-06-approve`.

**FR hiện thực.** FR-06-031, FR-06-037, FR-06-038, FR-06-039.

**Tham số.** `If-Match` (header, string, bắt buộc); `operationId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-007, ERR-06-030, ERR-06-003, ERR-06-006, ERR-06-029, ERR-06-031, ERR-06-032, ERR-06-033, ERR-06-034, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-113 · Khôi phục bản ghi vàng

::: dac-ta
**Mục đích.** Khôi phục bản ghi vàng.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records/{goldenId}:restore`.

**Quyền.** `PERM-06-merge`.

**FR hiện thực.** FR-06-040.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RestoreRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenRecord`; trường bắt buộc: `goldenId`, `domainCode`, `status`, `attributes`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-036, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-122 · Danh sách thao tác của bản ghi vàng

::: dac-ta
**Mục đích.** Danh sách thao tác của bản ghi vàng.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/golden-records/{goldenId}/operations`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-035, FR-06-039.

**Tham số.** `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc); `status` (query, OperationStatus, tùy chọn); `changeType` (query, GoldenChangeType, tùy chọn); `undoable` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenOperationPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-06-001, ERR-06-039, ERR-06-006, ERR-06-033, ERR-06-034 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thao tác chờ duyệt và thao tác hoàn tác được của một bản ghi vàng; dùng cho tab Thao tác.
:::

### Liên kết chéo và tra cứu

#### API-06-066 · Liên kết chéo của bản ghi vàng

::: dac-ta
**Mục đích.** Liên kết chéo của bản ghi vàng.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/golden-records/{goldenId}/xrefs`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-044.

**Tham số.** `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `XrefList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-06-006, ERR-06-031, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-067 · Gỡ liên kết chéo

::: dac-ta
**Mục đích.** Gỡ liên kết chéo.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records/{goldenId}/xrefs/{xrefId}:detach`.

**Quyền.** `PERM-06-update`.

**FR hiện thực.** FR-06-044.

**Tham số.** `If-Match` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `goldenId` (path, string, bắt buộc); `xrefId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DetachRequest`; trường bắt buộc: `reason`, `relink`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenOperationResult`; trường bắt buộc: `operationId`, `changeType`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `428`; mã lỗi của thao tác: ERR-06-006, ERR-06-031, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-068 · Tra ID vàng theo ID nguồn

::: dac-ta
**Mục đích.** Tra ID vàng theo ID nguồn.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}/xrefs/{sourceCode}/{sourceKey}`.

**Quyền.** `PERM-06-read hoặc scope `mdm:xref``.

**FR hiện thực.** FR-06-045.

**Tham số.** `X-Purpose` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc); `sourceCode` (path, string, bắt buộc); `sourceKey` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `XrefLookupResult`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `413`; mã lỗi của thao tác: ERR-06-018, ERR-06-037, ERR-06-050, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `sourceKey` nằm trên đường dẫn vì không phải DLCN; khóa định danh cá nhân luôn gửi trong thân (API-06-070).
:::

#### API-06-069 · Tra hàng loạt liên kết chéo

::: dac-ta
**Mục đích.** Tra hàng loạt liên kết chéo.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/xrefs:batch-lookup`.

**Quyền.** `PERM-06-read hoặc scope `mdm:xref``.

**FR hiện thực.** FR-06-045.

**Tham số.** `X-Purpose` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `BatchLookupRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `XrefLookupResult`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `413`; mã lỗi của thao tác: ERR-06-018, ERR-06-037, ERR-06-050, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-070 · Tra cứu bản ghi vàng theo ID hoặc khóa định danh

::: dac-ta
**Mục đích.** Tra cứu bản ghi vàng theo ID hoặc khóa định danh.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records:lookup`.

**Quyền.** `PERM-06-read hoặc scope `mdm:read``.

**FR hiện thực.** FR-06-046.

**Tham số.** `X-Purpose` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `GoldenLookupRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GoldenRecord`; trường bắt buộc: `goldenId`, `domainCode`, `status`, `attributes`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `410`, `503`; mã lỗi của thao tác: ERR-06-001, ERR-06-037, ERR-06-039, ERR-06-050, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Khóa định danh gửi trong thân `POST` để không lọt vào log của cổng; `ETag` và `Cache-Control: private, max-age=0` trong phản hồi.
:::

#### API-06-071 · Giải quyết bản ghi trực tuyến (resolve)

::: dac-ta
**Mục đích.** Giải quyết bản ghi trực tuyến (resolve).

**Phương thức, đường dẫn.** `POST /domains/{domainCode}:resolve`.

**Quyền.** scope `mdm:resolve`.

**FR hiện thực.** FR-06-020, FR-06-021, FR-06-047.

**Tham số.** `X-Purpose` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResolveRequest`; trường bắt buộc: `attributes`, `requestingSource`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ResolveResult`; trường bắt buộc: `outcome`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `ResolveResult`; trường bắt buộc: `outcome`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-06-003, ERR-06-037, ERR-06-048, ERR-06-001, ERR-06-050 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `200` khớp, `202` đã tạo mục hàng đợi (`LOOKUP_OR_QUEUE`), `404` ERR-06-050 khi `NO_MATCH`.
:::

#### API-06-072 · Tìm kiếm bản ghi vàng theo thuộc tính

::: dac-ta
**Mục đích.** Tìm kiếm bản ghi vàng theo thuộc tính.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/golden-records:search`.

**Quyền.** `PERM-06-read hoặc scope `mdm:search``.

**FR hiện thực.** FR-06-048.

**Tham số.** `X-Purpose` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SearchRequest`; trường bắt buộc: `criteria`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SearchResult`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`; mã lỗi của thao tác: ERR-06-038, ERR-06-040, ERR-06-003, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Cung cấp dữ liệu

#### API-06-073 · Đề nghị xuất dữ liệu chủ

::: dac-ta
**Mục đích.** Đề nghị xuất dữ liệu chủ.

**Phương thức, đường dẫn.** `POST /domains/{domainCode}/exports`.

**Quyền.** `PERM-06-export`.

**FR hiện thực.** FR-06-049.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc); `domainCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportCreate`; trường bắt buộc: `domainCode`, `fields`, `format`, `purposeCode`, `legalBasis`, `recipient`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Export`; trường bắt buộc: `exportId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-041, ERR-06-042, ERR-06-003, ERR-06-015, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-074 · Trạng thái yêu cầu xuất

::: dac-ta
**Mục đích.** Trạng thái yêu cầu xuất.

**Phương thức, đường dẫn.** `GET /exports/{exportId}`.

**Quyền.** `PERM-06-export`.

**FR hiện thực.** FR-06-049.

**Tham số.** `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Export`; trường bắt buộc: `exportId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-041, ERR-06-042, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-075 · Chấp thuận yêu cầu xuất

::: dac-ta
**Mục đích.** Chấp thuận yêu cầu xuất.

**Phương thức, đường dẫn.** `POST /exports/{exportId}:approve`.

**Quyền.** `PERM-06-export`.

**FR hiện thực.** FR-06-049.

**Tham số.** `If-Match` (header, string, bắt buộc); `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Export`; trường bắt buộc: `exportId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-041, ERR-06-042, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-076 · Tải tệp xuất

::: dac-ta
**Mục đích.** Tải tệp xuất.

**Phương thức, đường dẫn.** `GET /exports/{exportId}/file`.

**Quyền.** `PERM-06-export`.

**FR hiện thực.** FR-06-049.

**Tham số.** `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** HTTP `401`, `403`, `404`, `410`, `422`; mã lỗi của thao tác: ERR-06-005, ERR-06-041, ERR-06-042, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Liên kết ký có hạn; hết hạn trả `410` (ERR-06-042). Tệp có thủy vân.
:::

#### API-06-077 · Danh sách đăng ký nhận cập nhật

::: dac-ta
**Mục đích.** Danh sách đăng ký nhận cập nhật.

**Phương thức, đường dẫn.** `GET /update-subscriptions`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-051.

**Tham số.** `domainCode` (query, string, tùy chọn); `systemCode` (query, string, tùy chọn); `status` (query, SubscriptionStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubscriptionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi của thao tác: ERR-06-043 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-078 · Đăng ký nhận cập nhật cho HTTT

::: dac-ta
**Mục đích.** Đăng ký nhận cập nhật cho HTTT.

**Phương thức, đường dẫn.** `POST /update-subscriptions`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-051.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubscriptionCreate`; trường bắt buộc: `systemCode`, `domainCode`, `scope`, `eventTypes`, `delivery`, `purposeCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Subscription`; trường bắt buộc: `subscriptionId`, `systemCode`, `domainCode`, `scope`, `status`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-043, ERR-06-003, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-079 · Chấp thuận đăng ký nhận cập nhật

::: dac-ta
**Mục đích.** Chấp thuận đăng ký nhận cập nhật.

**Phương thức, đường dẫn.** `POST /update-subscriptions/{subscriptionId}:approve`.

**Quyền.** `PERM-06-export`.

**FR hiện thực.** FR-06-051.

**Tham số.** `If-Match` (header, string, bắt buộc); `subscriptionId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `systemCode`, `domainCode`, `scope`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-043, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-114 · Từ chối yêu cầu xuất

::: dac-ta
**Mục đích.** Từ chối yêu cầu xuất.

**Phương thức, đường dẫn.** `POST /exports/{exportId}:reject`.

**Quyền.** `PERM-06-export`.

**FR hiện thực.** FR-06-049.

**Tham số.** `If-Match` (header, string, bắt buộc); `exportId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Export`; trường bắt buộc: `exportId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `410`, `422`, `428`; mã lỗi của thao tác: ERR-06-005, ERR-06-041, ERR-06-042, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-115 · Tạm ngừng đăng ký nhận cập nhật

::: dac-ta
**Mục đích.** Tạm ngừng đăng ký nhận cập nhật.

**Phương thức, đường dẫn.** `POST /update-subscriptions/{subscriptionId}:suspend`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-051.

**Tham số.** `If-Match` (header, string, bắt buộc); `subscriptionId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `systemCode`, `domainCode`, `scope`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-043, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-116 · Tiếp tục đăng ký nhận cập nhật

::: dac-ta
**Mục đích.** Tiếp tục đăng ký nhận cập nhật.

**Phương thức, đường dẫn.** `POST /update-subscriptions/{subscriptionId}:resume`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-051.

**Tham số.** `If-Match` (header, string, bắt buộc); `subscriptionId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `systemCode`, `domainCode`, `scope`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-043, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-117 · Thu hồi đăng ký nhận cập nhật

::: dac-ta
**Mục đích.** Thu hồi đăng ký nhận cập nhật.

**Phương thức, đường dẫn.** `POST /update-subscriptions/{subscriptionId}:revoke`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-051.

**Tham số.** `If-Match` (header, string, bắt buộc); `subscriptionId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Subscription`; trường bắt buộc: `subscriptionId`, `systemCode`, `domainCode`, `scope`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-043, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Đồng bộ quốc gia

#### API-06-080 · Trạng thái đồng bộ quốc gia

::: dac-ta
**Mục đích.** Trạng thái đồng bộ quốc gia.

**Phương thức, đường dẫn.** `GET /national-sync/status`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-053.

**Tham số.** `domainCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncStatus`; trường bắt buộc: `state`, `paused`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-044, ERR-06-045 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-081 · Chạy đồng bộ quốc gia thủ công

::: dac-ta
**Mục đích.** Chạy đồng bộ quốc gia thủ công.

**Phương thức, đường dẫn.** `POST /national-sync/runs`.

**Quyền.** `PERM-06-sync hoặc scope `mdm:national-sync``.

**FR hiện thực.** FR-06-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncRunRequest`; trường bắt buộc: `direction`, `domainCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRunAccepted`; trường bắt buộc: `runId`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-044, ERR-06-045, ERR-06-003, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-082 · Tạm dừng đồng bộ quốc gia

::: dac-ta
**Mục đích.** Tạm dừng đồng bộ quốc gia.

**Phương thức, đường dẫn.** `POST /national-sync:pause`.

**Quyền.** `PERM-06-sync`.

**FR hiện thực.** FR-06-053, FR-06-054.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncStatus`; trường bắt buộc: `state`, `paused`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-044, ERR-06-045, ERR-06-007, ERR-06-035, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-083 · Danh sách lệch đồng bộ quốc gia

::: dac-ta
**Mục đích.** Danh sách lệch đồng bộ quốc gia.

**Phương thức, đường dẫn.** `GET /national-sync/discrepancies`.

**Quyền.** `PERM-06-sync`.

**FR hiện thực.** FR-06-054.

**Tham số.** `runId` (query, string, tùy chọn); `attribute` (query, string, tùy chọn); `severity` (query, DiscrepancySeverity, tùy chọn); `status` (query, DiscrepancyStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiscrepancyPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi của thao tác: ERR-06-007, ERR-06-035 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-084 · Xử lý lệch đồng bộ quốc gia

::: dac-ta
**Mục đích.** Xử lý lệch đồng bộ quốc gia.

**Phương thức, đường dẫn.** `POST /national-sync/discrepancies:resolve`.

**Quyền.** `PERM-06-sync`.

**FR hiện thực.** FR-06-054.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DiscrepancyResolveRequest`; trường bắt buộc: `discrepancyIds`, `resolution`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiscrepancyResolveResult`; trường bắt buộc: `processed`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`; mã lỗi của thao tác: ERR-06-007, ERR-06-035, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-118 · Tiếp tục đồng bộ quốc gia

::: dac-ta
**Mục đích.** Tiếp tục đồng bộ quốc gia.

**Phương thức, đường dẫn.** `POST /national-sync:resume`.

**Quyền.** `PERM-06-sync`.

**FR hiện thực.** FR-06-053, FR-06-054.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SyncResumeRequest`; trường bắt buộc: `cause`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncStatus`; trường bắt buộc: `state`, `paused`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-044, ERR-06-045, ERR-06-007, ERR-06-035, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bắt buộc `cause` (nguyên nhân đã điều tra, từ 20 ký tự), lưu ở `national_sync_state`, kiểm toán và đưa vào EVT-06-13.
:::

### Vận hành

#### API-06-085 · Chỉ số dashboard dữ liệu chủ

::: dac-ta
**Mục đích.** Chỉ số dashboard dữ liệu chủ.

**Phương thức, đường dẫn.** `GET /dashboard/metrics`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-055.

**Tham số.** `domainCode` (query, string, tùy chọn); `khoang` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DashboardMetrics`; trường bắt buộc: `metrics`.

**Lỗi.** `401` Chưa xác thực; `403` Không đủ quyền.

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-086 · Danh sách lịch job

::: dac-ta
**Mục đích.** Danh sách lịch job.

**Phương thức, đường dẫn.** `GET /job-schedules`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-056.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `JobSchedulePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-087 · Sửa lịch job

::: dac-ta
**Mục đích.** Sửa lịch job.

**Phương thức, đường dẫn.** `PUT /job-schedules/{jobType}`.

**Quyền.** `PERM-06-operate`.

**FR hiện thực.** FR-06-056.

**Tham số.** `If-Match` (header, string, bắt buộc); `jobType` (path, JobType, bắt buộc).

**Thân yêu cầu.** application/json: `JobSchedulePut`; trường bắt buộc: `cron`, `enabled`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `JobSchedule`; trường bắt buộc: `jobType`, `cron`, `enabled`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-006, ERR-06-047, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-088 · Nhật ký xử lý

::: dac-ta
**Mục đích.** Nhật ký xử lý.

**Phương thức, đường dẫn.** `GET /processing-logs`.

**Quyền.** `PERM-06-read`.

**FR hiện thực.** FR-06-057.

**Tham số.** `jobId` (query, string, tùy chọn); `candidateId` (query, string, tùy chọn); `level` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProcessingLogPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `503`; mã lỗi của thao tác: ERR-06-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-089 · Nhật ký truy cập

::: dac-ta
**Mục đích.** Nhật ký truy cập.

**Phương thức, đường dẫn.** `GET /access-logs`.

**Quyền.** `PERM-06-audit-read`.

**FR hiện thực.** FR-06-057.

**Tham số.** `goldenId` (query, string, tùy chọn); `actor` (query, string, tùy chọn); `systemCode` (query, string, tùy chọn); `purposeCode` (query, string, tùy chọn); `tu` (query, string, tùy chọn); `den` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessLogPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `503`; mã lỗi của thao tác: ERR-06-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

### Chủ thể dữ liệu và lưu giữ

#### API-06-090 · Tiếp nhận yêu cầu của chủ thể dữ liệu

::: dac-ta
**Mục đích.** Tiếp nhận yêu cầu của chủ thể dữ liệu.

**Phương thức, đường dẫn.** `POST /subject-requests`.

**Quyền.** `PERM-06-dsr`.

**FR hiện thực.** FR-06-058.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DsrCreate`; trường bắt buộc: `requestType`, `subjectIdentifier`, `verificationRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Dsr`; trường bắt buộc: `requestId`, `requestType`, `status`, `dueAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-046, ERR-06-003, ERR-06-015 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-091 · Chi tiết yêu cầu của chủ thể dữ liệu

::: dac-ta
**Mục đích.** Chi tiết yêu cầu của chủ thể dữ liệu.

**Phương thức, đường dẫn.** `GET /subject-requests/{requestId}`.

**Quyền.** `PERM-06-dsr`.

**FR hiện thực.** FR-06-058.

**Tham số.** `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dsr`; trường bắt buộc: `requestId`, `requestType`, `status`, `dueAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-06-006, ERR-06-046, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-092 · Hoàn tất yêu cầu của chủ thể dữ liệu

::: dac-ta
**Mục đích.** Hoàn tất yêu cầu của chủ thể dữ liệu.

**Phương thức, đường dẫn.** `POST /subject-requests/{requestId}:complete`.

**Quyền.** `PERM-06-dsr`.

**FR hiện thực.** FR-06-058.

**Tham số.** `If-Match` (header, string, bắt buộc); `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DsrComplete`; trường bắt buộc: `resultSummary`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dsr`; trường bắt buộc: `requestId`, `requestType`, `status`, `dueAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-006, ERR-06-046, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-093 · Danh sách chính sách lưu giữ

::: dac-ta
**Mục đích.** Danh sách chính sách lưu giữ.

**Phương thức, đường dẫn.** `GET /retention-policies`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-059.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RetentionPolicyPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`.

**Lỗi.** HTTP `401`, `403`, `422`; mã lỗi của thao tác: ERR-06-049 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-094 · Sửa chính sách lưu giữ

::: dac-ta
**Mục đích.** Sửa chính sách lưu giữ.

**Phương thức, đường dẫn.** `PUT /retention-policies/{objectType}`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-059.

**Tham số.** `If-Match` (header, string, bắt buộc); `objectType` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RetentionPolicyPut`; trường bắt buộc: `retentionDays`, `action`, `legalHold`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RetentionPolicy`; trường bắt buộc: `objectType`, `retentionDays`, `action`, `legalHold`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-049, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-095 · Danh sách tham số phân hệ

::: dac-ta
**Mục đích.** Danh sách tham số phân hệ.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-060.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingsDoc`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-06-004, ERR-06-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-096 · Sửa tham số phân hệ

::: dac-ta
**Mục đích.** Sửa tham số phân hệ.

**Phương thức, đường dẫn.** `PUT /settings`.

**Quyền.** `PERM-06-config`.

**FR hiện thực.** FR-06-060.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsPut`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingsDoc`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-004, ERR-06-047, ERR-06-003 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mỗi khóa theo miền ở FRS 8.2; ngoài miền ERR-06-047.
:::

#### API-06-119 · Chuyển yêu cầu sửa tới nguồn

::: dac-ta
**Mục đích.** Chuyển yêu cầu sửa tới nguồn.

**Phương thức, đường dẫn.** `POST /subject-requests/{requestId}:forward`.

**Quyền.** `PERM-06-dsr`.

**FR hiện thực.** FR-06-058.

**Tham số.** `If-Match` (header, string, bắt buộc); `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `DsrForward`; trường bắt buộc: `sourceCode`, `attributes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dsr`; trường bắt buộc: `requestId`, `requestType`, `status`, `dueAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-006, ERR-06-046, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-120 · Từ chối yêu cầu của chủ thể dữ liệu

::: dac-ta
**Mục đích.** Từ chối yêu cầu của chủ thể dữ liệu.

**Phương thức, đường dẫn.** `POST /subject-requests/{requestId}:reject`.

**Quyền.** `PERM-06-dsr`.

**FR hiện thực.** FR-06-058.

**Tham số.** `If-Match` (header, string, bắt buộc); `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dsr`; trường bắt buộc: `requestId`, `requestType`, `status`, `dueAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-006, ERR-06-046, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Theo FRS 9.4.
:::

#### API-06-125 · Gỡ hạn chế xử lý dữ liệu

::: dac-ta
**Mục đích.** Gỡ hạn chế xử lý dữ liệu.

**Phương thức, đường dẫn.** `POST /subject-requests/{requestId}:lift-restriction`.

**Quyền.** `PERM-06-dsr`.

**FR hiện thực.** FR-06-058.

**Tham số.** `If-Match` (header, string, bắt buộc); `requestId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dsr`; trường bắt buộc: `requestId`, `requestType`, `status`, `dueAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `428`; mã lỗi của thao tác: ERR-06-006, ERR-06-046, ERR-06-003, ERR-06-004, ERR-06-001 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bỏ cờ `restricted`, bản ghi `LOCKED` về `ACTIVE`; yêu cầu `RESTRICTION` giữ `COMPLETED`; phát EVT-06-02.
:::

<!-- gen:dac-ta-api:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-API và K-TRINH-BAY: 120 operation (96 mã FRS, 24 mã tách), 15 sự kiện, OpenAPI và AsyncAPI sinh từ một nguồn, kiểm hợp đồng 217 ví dụ; năm câu hỏi mở Q06-55…59 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: thêm API-06-121…125 (125 operation, 225 ví dụ kiểm); `decision` ở API-06-106, `cause` ở API-06-118, `partition` ở API-06-045; định nghĩa ERR-06-051…053; khung lỗi nền ERR-00-401, 403, 428 ở mục 6; đánh dấu các đề nghị mục 10.2 đã áp |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: mẫu type ERR-06-nnn, trường phản hồi mới của màn hình bàn làm việc; chốt câu hỏi mở đợt đồng bộ: Q387, Q411 |
