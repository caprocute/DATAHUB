---
ma_tai_lieu: D05-02-PH20
ten: Đặc tả ca kiểm thử phân hệ PH-20 Quản trị tenant và phát hành sản phẩm
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư dh-platform, quản trị nền tảng, quản trị tỉnh, cán bộ an toàn thông tin, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-20
mo_ta: Kịch bản và test case chức năng, saga khởi tạo tenant theo từng bước, vòng đời và bốn mắt, sáp nhập tenant, tổ chức, hạn mức và sử dụng, phát hành theo sóng, cô lập tenant, hiệu năng và nghiệm thu của phân hệ Quản trị tenant và phát hành sản phẩm, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH20 FRS; D02-04-PH20 Use case; D03-04-PH20 API (openapi-ph20.yaml); D03-06-PH20 Màn hình; D03-03-PH20 CSDL (ph20_isolation_test.sql); D03-10 Thiết kế đa tenant; D02-08 Ma trận phân quyền
---

# D05-02-PH20 · Đặc tả ca kiểm thử Quản trị tenant và phát hành sản phẩm

## Tóm tắt cho hội đồng thẩm định

Phần này nói tài liệu chứng minh điều gì, phủ đến đâu và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản, số ca do công cụ sinh lại từ chính các ca nên luôn khớp chương 4 và 5.

**Mục tiêu.** Tài liệu chứng minh sáu điều:

- PH-20 làm đúng yêu cầu của D02-03-PH20: 70 FR (51 mức M, 19 mức S), 42 BR, 24 NFR, 171 API (134 ở `/api/platform/v1`, 27 ở `/api/tenant/v1`, 10 ở `/internal/tenant/v1`), 86 mã lỗi (`ERR-20-001…068` và `101…118`), 16 sự kiện EVT-20-01…16 và 22 màn hình UI-20-01…22.
- Khởi tạo một tỉnh mới tự động, lũy đẳng và có thể thử lại: saga 17 bước `S01_RECORD…S17_ACTIVATE` chạy tới `ACTIVE` trong không quá 60 phút (NFR-00-057), mỗi bước lỗi đều thử lại được từ đúng chỗ dừng, bù trừ ngược không để lại tài nguyên mồ côi, bước chờ báo quá hạn thì `FAILED` đúng mã lỗi.
- Thao tác nguy hiểm có người thứ hai: chấm dứt tenant, sáp nhập, đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng đều bốn mắt (người lập không tự duyệt, người duyệt chấm dứt không xác nhận bàn giao); mọi thao tác ghi của quản trị nền tảng vào tenant tỉnh có lý do, mã phiếu và bản ghi kiểm toán.
- Tạm ngừng có hiệu lực ở mặt phẳng dữ liệu trong 60 giây với `ERR-20-001`; chấm dứt chỉ chạy khi gói bàn giao đã `DELIVERED`, hết thời gian nguội và có hai quản trị nền tảng; tenant `MERGED` chỉ đọc.
- Sáp nhập hai tỉnh giữ nguyên `id` gốc, kiểm đếm khớp 100 % bản ghi, không xung đột nào bị ghi đè tự động, cutover không làm lỗi lượt gọi; phát hành theo sóng tự dừng khi tỷ lệ lỗi vượt 2 % và quay lui được khi không có thay đổi lược đồ không tương thích.
- Tenant này không đọc được dữ liệu của tenant khác ở API, CSDL (RLS) và Kafka; kiểm thử rò rỉ chéo tenant chỉ chạy trên `T90…T99`.

**Phạm vi.** Gồm <!--gen:so-ts-->44<!--/gen--> kịch bản với <!--gen:so-tc-->233 (TC-20-001…233; 151 ca P1)<!--/gen--> test case và 8 kịch bản nghiệm thu người dùng (UAT-01…08). Kịch bản `TS-20-01…36` ứng một một với `UC-20-01…36` (đề nghị A-10 của tập use case); `TS-20-37…44` là kịch bản xuyên suốt và phi chức năng. Mọi FR mức M có ít nhất một ca dương và một ca âm, mọi FR mức S có ít nhất một ca, mọi mã `ERR-20` có ít nhất một ca; ma trận mục 8 sinh bằng `ph20/tools/gen_matrix.py`.

**Căn cứ.** FRS D02-03-PH20, use case D02-04-PH20, API D03-04-PH20 (`openapi-ph20.yaml`, tên trường và mã lỗi theo từng thao tác), màn hình D03-06-PH20 (UI-20-01…22), CSDL D03-03-PH20 (`ph20_isolation_test.sql`), D03-10 (nền đa tenant, saga, sáp nhập), D02-08, kế hoạch D05-01 (cổng `RG-1…5`); cấu trúc theo ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Bảy nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- cô lập tenant và ca rò rỉ chéo tenant cho từng nhóm API, RLS, Kafka (TS-20-37);
- phân quyền âm theo `PERM-20-*` và bốn mắt (TS-20-38, 13, 14, 21, 25);
- saga khởi tạo: lỗi và thử lại từng bước, bù trừ, hết hạn chờ báo, lũy đẳng khi phân hệ gọi lại (TS-20-05, 06, 40);
- tạm ngừng, chấm dứt, thời gian nguội, xóa mật mã (TS-20-20, 21, 22);
- sáp nhập: chạy thử, kiểm đếm, xung đột, định danh, cutover, chuyển tiếp (TS-20-24…29, 44);
- phát hành theo sóng: ngưỡng lỗi dừng sóng, quay lui, cửa sổ bảo trì (TS-20-32…34, 44);
- hiệu năng saga ≤ 60 phút và các NFR-20 đo được (TS-20-41).

Dữ liệu dùng giả định GĐ-01…07 (tỉnh `T01` quy mô vừa, 200 HTTT). Các phân hệ khác (PH-12, 13, 07, 10, 03, 18…) được giả lập bằng bản giả hợp đồng; PostgreSQL thật dùng cho kiểm RLS. Hợp đồng `merge-transfers` với PH-18 và nhiều điểm của kho GitOps còn là giả định (Q20-15, Q20-14 của FRS), nên các ca liên quan ghi rõ là ca theo hợp đồng giả định.

## 0. Giới thiệu

### 0.1. Mục đích

Đặc tả kịch bản và test case của PH-20 để nghiệm thu chức năng của quản trị tenant (hồ sơ, saga khởi tạo, cấu hình GitOps, hạn mức, phân hệ, vòng đời, sáp nhập, tổ chức, phát hành), tính an toàn của thao tác bốn mắt và cô lập tenant, hiệu năng theo NFR-20 và nghiệm thu nghiệp vụ của quản trị nền tảng, quản trị tỉnh.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư `dh-platform`, `dh-console` đối chiếu hành vi; cán bộ ATTT kiểm chương 5; quản trị nền tảng, quản trị tỉnh, chủ đầu tư dùng mục 7 và 9.5.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; PA, PO, PAU quản trị, vận hành, kiểm toán nền tảng (tenant `PLATFORM`); TA, TO, SO, AU, DS, VW quản trị tỉnh, vận hành tỉnh, cán bộ an toàn thông tin, kiểm toán viên, cán bộ dữ liệu, người xem của một tỉnh; saga chuỗi bước khởi tạo có bù trừ ngược; lũy đẳng gọi lại nhiều lần vẫn cho một kết quả; bước chờ báo bước bất đồng bộ đợi phân hệ báo qua API-20-166; GitOps lấy kho Git `dh-tenant-config` làm trạng thái mong muốn; cutover thời điểm tenant nguồn chuyển `MERGED`; sóng (wave) một nhóm tenant nâng cấp cùng lúc; RLS an toàn theo hàng của PostgreSQL; ĐVHC đơn vị hành chính.

### 0.4. Tài liệu tham chiếu

FRS D02-03-PH20 (mã FR, BR, NFR, ERR, EVT, API-20, UI-20, tham số `20.*`, câu thông báo mục 9.2, Phụ lục A enum); use case D02-04-PH20 (khung kịch bản, ma trận UC); OpenAPI `openapi-ph20.yaml` cùng ba tệp thành phần `openapi-platform.yaml`, `openapi-tenant.yaml`, `openapi-internal.yaml`; màn hình D03-06-PH20; CSDL D03-03-PH20 và `ph20_isolation_test.sql`; D03-10; kế hoạch D05-01; ma trận phân quyền D02-08; khuôn K-TC và K-TRINH-BAY.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng `TS-20-01…36` (ứng một một với `UC-20-01…36`); 5 ca xuyên suốt và phi chức năng `TS-20-37…44`; 6 thủ công; 7 nghiệm thu; 8 ma trận truy vết; 9 tự động hóa; 10 đề nghị đồng bộ và câu hỏi mở.

### 0.6. Nguyên tắc viết ca

Bảy nguyên tắc áp cho mọi ca.

1. Tên trường, mã HTTP và giá trị enum lấy từ `openapi-ph20.yaml` và FRS Phụ lục A, không đặt tên riêng. Mã lỗi theo từng thao tác của OpenAPI (`x-datahub-errors`).
2. Mọi ca nạp dữ liệu bằng API hoặc sự kiện, không chèn SQL (trừ ca DB). Ca kiểm bí mật chỉ dùng giá trị `<bi-mat-mau>`, không ghi bí mật thật hay chuỗi giống khóa.
3. Ca có mã lỗi ghi nguyên văn câu thông báo của FRS mục 9.2 với biến đã điền giá trị thử.
4. Ca bốn mắt luôn dùng hai quản trị nền tảng khác nhau (`U-PA1`, `U-PA2`) và thử cả trường hợp một người có đủ hai quyền.
5. Ca có đồng hồ (hạn ghi đè, thời gian nguội, thời gian chuyển tiếp, quá hạn chờ báo, cửa sổ bảo trì, thời gian soak) dùng `clock-sim`, không chờ thật.
6. Con số kỳ vọng tính tay từ bảng ở chương 2, không lấy từ kết quả hệ thống.
7. Mọi thao tác ghi của PA vào tenant tỉnh có `reason` từ 20 ký tự và `ticketRef` (BR-20-009); ca không nhắc thì dùng giá trị chuẩn `reason = "Thực hiện theo phiếu kiểm thử, ca tự động"` và `ticketRef = TC-PH20-001`.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là hai mô-đun `vn.datahub.platform.tenant` và `vn.datahub.platform.release` của `dh-platform` (mặt phẳng điều khiển, giả định namespace `dh-control`), schema `ph20_tenant` trên `pg-core` với RLS, 171 API (`/api/platform/v1`, `/api/tenant/v1`, `/internal/tenant/v1`), các topic `platform.tenant.*.v1`, `platform.release.*.v1`, `{tenant}.tenant.org.changed.v1` (EVT-20-01…16), kho GitOps `dh-tenant-config` và 22 màn hình của `dh-console` (`/nen-tang/*`, `/quan-tri/cai-dat-tinh`, `/quan-tri/to-chuc`). Ngoài phạm vi: nội dung thực thi của PH-12 (realm), PH-13 (chuỗi kiểm toán, Mimir), PH-07 (gói danh mục nền), PH-10 (topic, ACL), PH-03 (APISIX), PH-04, PH-06, PH-09 (xóa mật mã), PH-16 (KPI-12), PH-18 (tham số, thông báo, chuyển dữ liệu sáp nhập); các phân hệ này được giả lập (mục 2.5) và chỉ kiểm hợp đồng với PH-20.

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca; chiến lược chung theo D05-01.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Máy trạng thái, kiểm mã tenant, tính hạn mức hiệu lực, tính cảnh báo ngưỡng, tính thời gian chuyển tiếp, so khớp SemVer |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka KRaft, Keycloak, Gitea, WireMock) | Dịch vụ với CSDL, hộp gửi `outbox`, hộp nhận `inbox_event`, bộ thực thi saga với bản giả |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph20/test/ph20_isolation_test.sql` | RLS bảng `tenant` và bảng theo tenant, bất biến, bốn mắt ở mức ràng buộc, phân vùng `usage_snapshot` |
| API | API | REST Assured | Mọi API-20 |
| Kafka | KT | `kcat`, client Java OAUTHBEARER | Nội dung sự kiện, khóa phân vùng `tenantCode`, ACL tiền tố |
| Đầu cuối | E2E | Playwright, axe-core | UI-20-01…22 |
| Hiệu năng | k6 | k6, pgbench | NFR-20-001, 003, 005…013, 019, 020 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | Pod `dh-platform`, Kafka, PH-12, PH-13, Git, Argo CD, PostgreSQL |
| Bảo mật | ZAP | OWASP ZAP, bộ ca rò rỉ tự sinh theo danh mục API | Quyền, rò rỉ chéo tenant, bí mật trong cấu hình |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường phục vụ các mức ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, API, KT, E2E khói | `dh-platform` 1 bản sao; phân hệ khác, Git, Argo CD, OpenBao, Ceph RGW là bản giả hợp đồng (WireMock, Gitea, MinIO thay RGW); PostgreSQL 16 thật cho mọi ca RLS; Kafka KRaft thử |
| STAGING | E2E đầy đủ, saga đầu cuối, sáp nhập, phát hành, Chaos, ZAP, UAT dợt | Giống sản xuất về số bản sao và chính sách mạng; Argo CD, Git, Keycloak, OpenBao thật; phân hệ khác bản thật hoặc bản giả theo ca (ghi ở tiền điều kiện) |
| PERF | k6, đo quy mô 34 tenant | `dh-platform` 2 bản sao 4 CPU ảo, 8 GB; `pg-core` PostgreSQL 16; 34 tenant tổng hợp nạp bằng công cụ nạp, không qua saga |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** Hợp đồng `openapi-ph20.yaml` và `asyncapi-ph20.yaml` đã gắn phiên bản; DDL `ph20_tenant` nạp được; `clock-sim` hoạt động; các bản giả có kịch bản thành công, lỗi, quá hạn và gọi lại; mẫu khởi tạo `tinh-chuan` v3 đã `PUBLISHED`.
- **Ra.** `RG-1` mọi ca API, DB và rò rỉ chéo tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-20 ở PERF và STAGING, saga đầu cuối ≤ 60 phút; `RG-4` UAT mục 7 ký và 9 tiêu chí chấp nhận ở FRS mục 14 đạt (đối chiếu ở mục 9.5).

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-20-nn`, test case `TC-20-nnn`; mã không tái sử dụng, ca hủy ghi "Đã hủy". Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-20-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và `[[tc:khóa]]`. Đường dẫn API viết tắt phần gốc: `P/` là `/api/platform/v1/`, `T/` là `/api/tenant/v1/`, `I/` là `/internal/tenant/v1/`. Lệnh `POST` kèm `Idempotency-Key` có giá trị cố định theo ca; lệnh `PUT`, `PATCH` và hành động trên đối tượng có phiên bản kèm `If-Match` lấy từ `ETag` lần đọc trước. Mỗi ca có các trường sau.

| Trường | Nội dung |
|---|---|
| **Loại.** | Dương, Âm, Biên, Bảo mật, Hiệu năng, Chịu lỗi, Truy cập |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung |
| **Tự động.** | Mức ở mục 1.2 |
| **Truy vết.** | FR, BR, API, UI, UC, ERR, EVT, NFR, quyền, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu ở chương 2 |
| **Các bước.** | Danh sách đánh số |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán |
| **Thông báo hiển thị.** | Câu người dùng nhìn thấy theo FRS 9.2 (nguyên văn, `{biến}` đã điền giá trị thử); chỉ ở ca có mã lỗi |

: Các trường của khối đặc tả test case

Lỗi thiếu quyền chức năng, chưa xác thực và thiếu `If-Match` dùng mã nền `ERR-00-403`, `ERR-00-401`, `ERR-00-428` (FRS mục 9.1); lệch `If-Match` là `412` `ERR-20-005`. Thân lỗi là `application/problem+json` có `code`, `traceId`, `errors[]`. Trong kết quả mong đợi dùng các ký hiệu sau.

| Ký hiệu | Nghĩa |
|---|---|
| 404-ẩn | `404` `ERR-20-002`; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT | Bản ghi kiểm toán chuyển sang PH-13, đủ trường FR-00-041, kèm `reason`, `ticketRef`; vào chuỗi của tenant bị tác động và chuỗi `PLATFORM` (SEC-85) |
| EVT: `loại` | Đúng một bản tin trên topic tương ứng, khóa phân vùng `tenantCode`, chỉ mã và trạng thái, không dữ liệu cá nhân (BR-20-039) |
| Mồi sạch | Chuỗi mồi `DH-CANARY-{ca}` đặt trong ghi chú, lý do không xuất hiện trong log, vết OTel, sự kiện, tệp xuất, kho Git |

: Ký hiệu viết tắt trong kết quả mong đợi

### 1.6. Quản lý lỗi và báo cáo

Lỗi tìm thấy ghi theo mức S1…S4 của D05-01 kèm mã ca, bước, `traceId`; ca không đạt ở cổng `RG-1`, `RG-2` chặn phát hành. Phát hiện rò rỉ chéo tenant luôn là S1 (BR-20-038). Kết quả chạy gom về `.xlsx` (mục 9) qua thẻ `@TC-20-nnn`.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập: tên người là nhân vật hư cấu, tên miền dùng `example.vn`, số văn bản dùng tiền tố `TC/`, mã phiếu `TC-PH20-nnn`. Nạp bằng API hoặc sự kiện, trừ khối RLS chạy ở mức CSDL. Không dùng bí mật thật: tham chiếu bí mật viết `<bi-mat-mau>`.

### 2.1. Tenant

Tenant kiểm thử dùng dải `T90…T99` với `testTenant = true`; không dùng tenant sản xuất. Theo BR-20-038, kiểm thử rò rỉ chỉ chạy trên dải này.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant tỉnh chính, đích sáp nhập | `ACTIVE`, `SHARED`, `QM-VUA`, `HT-B`, mẫu `tinh-chuan` v3, kênh `STABLE`, phiên bản 2.3.1; PH-06, PH-16, PH-19 bật, PH-17 tắt; 200 HTTT, 400 người dùng, 40 tổ chức |
| `T91` | Đối chứng rò rỉ, nguồn sáp nhập | `ACTIVE`, `SHARED`, cùng mã tổ chức và HTTT với `T90` ở một phần dữ liệu nhưng nội dung khác (nguồn xung đột); 120 HTTT, 150 người dùng, 25 tổ chức |
| `T92` | Vòng đời | `ACTIVE`, dùng cho tạm ngừng, khôi phục, chấm dứt, gói bàn giao; một bản `T92` khác đã `SUSPENDED` sẵn |
| `T93` | Khởi tạo mới thành công | Hồ sơ khai báo mới, chạy saga `INITIAL` tới `ACTIVE` |
| `T94` | Khởi tạo lỗi, bù trừ | Bản giả phân hệ cài lỗi theo bước `S01…S17`; dùng cho thử lại, bù trừ, hết hạn chờ báo |
| `T95` | Cách ly | `DEDICATED_DB`; đổi chế độ cách ly; cụm riêng (Đợt 2) |
| `T96` | Hạn mức, sử dụng | Hạn mức hợp đồng cài sẵn; ảnh chụp sử dụng giả theo giờ |
| `T97` | Hiệu năng saga, registry | PERF: chạy saga và tải registry |
| `T98` | Hiệu năng tổ chức, sử dụng | PERF: nhập 5.000 tổ chức, đọc tổ chức, 25 tháng sử dụng |
| `T99` | Mồi rò rỉ | Tài nguyên cài sẵn có chuỗi mồi `DH-CANARY-T99`; đích của ca `CROSS_TENANT_LEAK` trong kiểm tra khói |
| `PLATFORM`, `COMMON` | Tenant đặc biệt | Bị bảo vệ khỏi mọi thao tác nguy hiểm (BR-20-003) |
| `T01…T34` (chỉ PERF) | 34 tenant tổng hợp | Nạp bằng công cụ nạp, `testTenant = true`, để đo NFR-20-005 (không dùng cho kiểm thử rò rỉ) |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

Người dùng mang tên nhân vật hư cấu, vai trò theo D02-08 và FRS mục 3.

| Mã | Tenant | Vai trò | Ghi chú |
|---|---|---|---|
| U-PA1, U-PA2 | PLATFORM | PA | Hoa, Tuấn; đủ quyền `PERM-20-*` quản trị; luôn dùng hai người khác nhau cho bốn mắt |
| U-PA3 | PLATFORM | PA | Cấu hình sai chủ ý có đủ `PERM-20-lifecycle` và `PERM-20-approve` (chỉ SIT) để thử một người giữ cả hai quyền |
| U-PO | PLATFORM | PO | Vận hành; `PERM-20-read`, `PERM-20-release` (chỉ theo dõi và dừng sóng) |
| U-PAU | PLATFORM | PAU | Kiểm toán nền tảng, chỉ đọc |
| U-T90-TA | T90 | TA | Lan; `PERM-20-settings`, `PERM-20-org`, `PERM-20-org-read`, `PERM-20-usage-read` |
| U-T90-TO, U-T90-SO, U-T90-AU, U-T90-DS, U-T90-VW | T90 | TO, SO, AU, DS, VW | Việt, Thảo, Thu, Quân, Nam |
| U-T91-TA, U-T91-VW | T91 | TA, VW | Đối chứng chéo tenant |
| U-T92-TA, U-T96-TA | T92, T96 | TA | Người dùng của tenant tương ứng |
| S-PH03, S-PH04, S-PH10, S-PH12, S-PH16, S-PH18 | PLATFORM | Máy | Scope `tenant:registry-read`; `S-PH10`, `S-PH04`, `S-PH12` thêm `tenant:provision-report`; `S-PH18` thêm `tenant:provision-report` cho báo sáp nhập |
| S-PH01, S-PH07, S-PH08 | PLATFORM | Máy | Scope `tenant:org-read` |
| S-NOSCOPE | PLATFORM | Máy | Không có scope nào của PH-20 |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu

Bộ dữ liệu có tên, sinh bằng hạt cố định để chạy lại được.

| Mã | Nội dung | Tenant |
|---|---|---|
| F-TPL | Mẫu khởi tạo `tinh-chuan`: phiên bản 3 `PUBLISHED` (mọi phân hệ không lõi bật trừ PH-17), `quotaByScale` cho bốn quy mô; phiên bản 2 `RETIRED`; mẫu `tinh-nho` v1 `DRAFT` | PLATFORM |
| F-HS-93 | Hồ sơ khai báo `T93`: `name` "Tỉnh Thử Ba (giả định)", `adminUnitId` ĐVHC cấp tỉnh còn hiệu lực chưa có tenant, `isolationMode = SHARED`, `scaleProfile = QM-VUA`, `deploymentProfile = HT-B`, `templateCode = tinh-chuan`, `templateVersion = 3`, ba đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL` | PLATFORM |
| F-SAGA | Bộ kịch bản bản giả theo `stepCode`: `OK`, `FAIL_ONCE`, `FAIL_ALWAYS`, `NO_REPORT`, `REPORT_FAILED`, `DUP_REPORT` cho `S01…S17` | T93, T94 |
| F-HTTT | 200 hệ thống thông tin của `T90` (GĐ-01), 120 của `T91` | T90, T91 |
| F-ORG | Cây tổ chức `T90`: 1 UBND tỉnh, 12 sở, 27 tổ chức khác; `T91`: 25 tổ chức, trong đó 3 mã trùng mã của `T90` (xung đột `ORGANIZATION`) | T90, T91 |
| F-ORG-IMP | Tệp nhập tổ chức: 5.000 dòng hợp lệ (`T98`); tệp 40 dòng có 3 dòng lỗi (mã trùng, cấp trên không tồn tại, ngày hiệu lực ngược) | T90, T98 |
| F-QUOTA | `T96`: `API_RPS` 500 (dùng 400, tức 80 %), `OBJECT_STORAGE_GB` 500 (dùng 300), `USERS` 2.000 (dùng 1.000), `ACTIVE_FLOWS` 1.000 (dùng 1.000, tức 100 %) | T96 |
| F-USAGE | Ảnh chụp sử dụng theo giờ 30 ngày của `T96`, 25 tháng của `T98` (giả định theo `20.usage.retention-months`) | T96, T98 |
| F-MERGE | Kế hoạch sáp nhập `T91` vào `T90`: 12 dòng ánh xạ `ORGANIZATION`, 20 dòng `MEMBER_SYSTEM`, 30 dòng `CATALOG_CODE`, 4 dòng `API_CONTEXT_PATH`, 150 dòng `USER`, 6 dòng `TOPIC`; xung đột cài sẵn 3 mã tổ chức, 2 mã danh mục, 1 mã `API_CONTEXT_PATH` | T90, T91 |
| F-REL | Phiên bản sản phẩm: `2.3.1` `STABLE`, `2.4.0-rc.1` `DRAFT`, `2.4.0` `PREVIEW` (đã 15 ngày), `2.2.0` `STABLE`, `2.1.0` `DEPRECATED`; kế hoạch nâng cấp ba sóng (`T90`; `T91`, `T92`; `T93`) | PLATFORM |
| F-LEAK | Danh mục API của PH-03 dùng để sinh ca rò rỉ; tài nguyên mồi ở `T99` | T90…T99 |

: Bộ dữ liệu kiểm thử

### 2.4. Số đếm chuẩn

Bảng liệt kê số kỳ vọng mà nhiều ca dùng, tính tay từ F-QUOTA và F-MERGE để không lấy từ hệ thống.

| Phép tính | Giá trị kỳ vọng |
|---|---|
| Phần trăm sử dụng `API_RPS` của `T96` | 400 / 500 = 80 % → cảnh báo `WARN_80` |
| Phần trăm sử dụng `ACTIVE_FLOWS` của `T96` | 1.000 / 1.000 = 100 % → cảnh báo `LIMIT_100` |
| Đặt lại cảnh báo `API_RPS` | Dùng xuống 370 (74 %, dưới `20.quota.alert-reset-percent` = 75) liên tục 24 giờ → `RESOLVED` |
| Hạ `OBJECT_STORAGE_GB` của `T96` xuống 250 | Thấp hơn mức đang dùng 300 → ERR-20-030, phải duyệt bốn mắt |
| Hạn mức hiệu lực `USERS` | Hợp đồng 2.000, ghi đè 2.500 còn hạn 10 ngày → 2.500; hết hạn → 2.000 |
| Kiểm đếm sáp nhập `USER` | Nguồn 150, bỏ qua `SKIP` 6, đích nhận 144 → khớp |
| Kiểm đếm sáp nhập `ORGANIZATION` | Nguồn 25, đích nhận 25 (3 đổi tên bằng `RENAME_SOURCE`) → khớp, tổng tổ chức `T90` = 65 |
| Chuyển tiếp mặc định | `20.merge.transition-months` = 6 tháng; tối đa `20.merge.transition-max-months` = 12 |
| Thời gian nguội chấm dứt | `20.terminate.cooling-days` = 30 ngày kể từ lúc tạm ngừng |
| Ngưỡng dừng sóng | Lỗi 5xx của sóng > 2 % (`20.release.wave-error-threshold-percent`) |

: Số đếm chuẩn dùng cho tính tay kết quả mong đợi

### 2.5. Hệ thống giả lập

Phân hệ và hệ thống ngoài được giả lập như sau.

| Hệ thống | Giả lập bằng | Kịch bản |
|---|---|---|
| PH-12 (`iam-sim`) | WireMock | API-12-080 tạo realm, API-12-084, 085 đổi trạng thái realm, API-12-045, 046 chuyển định danh: thành công, `409`, `503`, trễ; phát `EVT-12-13` |
| PH-13 (`obs-sim`) | WireMock | API-13-072 khởi tạo quan sát, API-13-073 đóng chuỗi kiểm toán, nhận bản ghi kiểm toán; phát `EVT-13-14`; Mimir giả cho số đo sử dụng |
| PH-07 (`rdm-sim`) | WireMock | API-07-073 nạp gói danh mục nền; ĐVHC `COMMON`; phát `EVT-07-10` sắp xếp lại ĐVHC |
| PH-10, PH-03, PH-04, PH-06, PH-19, PH-17 (`mod-sim`) | WireMock và bộ phát Kafka | Nghe EVT-20-01, 04, 05, 07, 08; báo tiến độ qua API-20-166 theo kịch bản F-SAGA; phát `EVT-03-10`, `EVT-03-11` |
| PH-18 (`ops-sim`) | WireMock | `POST /api/ops/v1/merge-transfers` (giả định, có `dryRun`), báo API-20-167; `NotificationApi` gửi thư; đăng ký, đổi tham số `20.*`; việc xử lý lỗi |
| PH-09 (`crypto-sim`) | WireMock và bộ phát Kafka | Xóa mật mã FR-09-043; phát `EVT-09-21` hoặc không phát |
| PH-16 (`kpi-sim`) | WireMock | API-16-030 nhận thời gian khởi tạo; `503` |
| PH-01, PH-08 (`org-reader-sim`) | Máy khách giả | Gọi API-20-169…171 với scope `tenant:org-read` |
| OpenBao, Ceph RGW (`vault-sim`, `s3-sim`) | Bản giả hợp đồng | Tạo, xóa đường dẫn `kv/dh/{ma}/...`, KEK, bucket `dh-{ma}-{mục đích}` |
| Git, Argo CD (`git-sim`, `argo-sim`) | Gitea và bộ giả Argo CD | Commit ký vào `dh-tenant-config`; `Synced`, `OutOfSync`, `Degraded`; từ chối ghi |
| Đồng hồ (`clock-sim`) | Đồng hồ giả | Đẩy thời gian cho quá hạn chờ báo, hạn ghi đè, thời gian nguội, soak 14 ngày, cửa sổ bảo trì, chuyển tiếp 6 tháng |

: Hệ thống giả lập

### 2.6. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Mỗi ca ghi dữ liệu sinh ra và dọn bằng khóa `tc-{khóa}` trong tenant; ca dùng lại dữ liệu của ca khác nêu rõ ở tiền điều kiện. Ca bảo mật đặt chuỗi mồi `DH-CANARY-{ca}` và số định danh giả dải `0010990xxxxx` vào trường văn bản tự do. Tenant mã `T01…T34` và dữ liệu PERF không chạy chung với ca chức năng.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5; mục 3.2 liệt kê số ca theo loại và mục 3.3 các máy trạng thái được kiểm.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-20-01 | Tra cứu và xem chi tiết tenant toàn nền tảng | UC-20-01 | 4 |
| TS-20-02 | Khai báo tenant mới và kiểm tra sẵn sàng | UC-20-02 | 8 |
| TS-20-03 | Sửa hồ sơ, đầu mối, hợp đồng và bảo vệ tenant đặc biệt | UC-20-03 | 6 |
| TS-20-04 | Quản lý mẫu khởi tạo có phiên bản | UC-20-04 | 3 |
| TS-20-05 | Chạy saga khởi tạo tenant | UC-20-05 | 4 |
| TS-20-06 | Theo dõi saga, thử lại, bù trừ và hủy khởi tạo | UC-20-06 | 6 |
| TS-20-07 | Kiểm tra khói, kích hoạt, bàn giao và đo thời gian khởi tạo | UC-20-07 | 5 |
| TS-20-08 | Khởi tạo bổ sung và khởi tạo cụm riêng | UC-20-08 | 4 |
| TS-20-09 | Cấu hình nền tảng của tenant và ghi vào kho GitOps | UC-20-09 | 4 |
| TS-20-10 | Xem phiên bản, so sánh, khôi phục cấu hình và xử lý lệch | UC-20-10 | 4 |
| TS-20-11 | Cài đặt tỉnh, xem phiên bản và lịch bảo trì của tỉnh | UC-20-11 | 4 |
| TS-20-12 | Chính sách tiếp nhận và nhật ký truy cập liên tenant | UC-20-12 | 4 |
| TS-20-13 | Chuyển chế độ cách ly của tenant | UC-20-13 | 2 |
| TS-20-14 | Đặt, đổi hạn mức hợp đồng và ghi đè tạm thời | UC-20-14 | 7 |
| TS-20-15 | Thu thập sử dụng tài nguyên và cảnh báo ngưỡng hạn mức | UC-20-15 | 4 |
| TS-20-16 | Xem sử dụng tài nguyên và lập báo cáo sử dụng | UC-20-16 | 4 |
| TS-20-17 | Danh mục phân hệ, bật phân hệ và trạng thái cho menu | UC-20-17 | 7 |
| TS-20-18 | Tắt, tạm ngừng, tiếp tục phân hệ và đặt cờ tính năng | UC-20-18 | 4 |
| TS-20-19 | Phân hệ đọc registry, tổ chức và thực thi trạng thái tenant | UC-20-19 | 5 |
| TS-20-20 | Tạm ngừng và khôi phục tenant | UC-20-20 | 5 |
| TS-20-21 | Đề nghị, duyệt chấm dứt tenant và xuất gói bàn giao | UC-20-21 | 5 |
| TS-20-22 | Thực hiện chấm dứt tenant | UC-20-22 | 4 |
| TS-20-23 | Lịch sử vòng đời và thông báo đổi trạng thái | UC-20-23 | 4 |
| TS-20-24 | Lập kế hoạch và bảng ánh xạ sáp nhập | UC-20-24 | 5 |
| TS-20-25 | Chạy thử, gửi duyệt và duyệt kế hoạch sáp nhập | UC-20-25 | 5 |
| TS-20-26 | Điều phối chuyển dữ liệu sáp nhập theo phân hệ | UC-20-26 | 4 |
| TS-20-27 | Xử lý xung đột sáp nhập | UC-20-27 | 4 |
| TS-20-28 | Chuyển định danh, cấp song song thông tin xác thực và cutover | UC-20-28 | 6 |
| TS-20-29 | Kết thúc sáp nhập sau thời gian chuyển tiếp | UC-20-29 | 4 |
| TS-20-30 | Quản lý danh mục tổ chức, nhập, xuất và chủ quản dữ liệu | UC-20-30 | 8 |
| TS-20-31 | Giải thể, hợp nhất tổ chức và đồng bộ khi sắp xếp ĐVHC | UC-20-31 | 8 |
| TS-20-32 | Quản lý phiên bản sản phẩm và kênh phát hành | UC-20-32 | 7 |
| TS-20-33 | Lập kế hoạch nâng cấp theo sóng và thông báo lịch bảo trì | UC-20-33 | 8 |
| TS-20-34 | Theo dõi nâng cấp, dừng sóng và quay lui | UC-20-34 | 8 |
| TS-20-35 | Bảng điều khiển đa tenant và kiểm thử rò rỉ chéo tenant | UC-20-35 | 6 |
| TS-20-36 | Tra nhật ký kiểm toán và tham số 20.* | UC-20-36 | 5 |
| TS-20-37 | Cô lập tenant và rò rỉ chéo tenant theo nhóm API | — | 8 |
| TS-20-38 | Phân quyền âm và bốn mắt | — | 4 |
| TS-20-39 | Lũy đẳng, đồng thời, định dạng lỗi và kiểm toán | — | 5 |
| TS-20-40 | Saga khởi tạo từng bước S01…S17 | — | 13 |
| TS-20-41 | Hiệu năng và dung lượng | — | 8 |
| TS-20-42 | Chịu lỗi và phục hồi | — | 3 |
| TS-20-43 | Giao diện: trạng thái, quyền hiển thị và WCAG 2.2 AA | — | 4 |
| TS-20-44 | Đầu cuối: khởi tạo tỉnh, sáp nhập hai tỉnh, phát hành theo sóng | — | 3 |
| **Tổng** | | | **233** (151 ca P1) |

: Danh sách 44 kịch bản kèm use case và số ca
<!--/gen-->

### 3.2. Số ca theo loại

<!--gen:loai-->
| Loại | Số ca |
|---|---|
| Âm | 124 |
| Dương | 123 |
| Biên | 13 |
| Hiệu năng | 9 |
| Chịu lỗi | 7 |
| Bảo mật | 4 |

: Số ca theo loại
<!--/gen-->

### 3.3. Máy trạng thái được kiểm thử

Bảng liệt kê chuyển hợp lệ và chuyển cấm được kiểm ở chương 4 và 5.

| Máy trạng thái (FRS mục 4) | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Tenant (`TenantStatus`) | `PROVISIONING` → `ACTIVE`, `FAILED`; `FAILED` → `PROVISIONING`, `DECOMMISSIONED`; `ACTIVE` ↔ `SUSPENDED`; `ACTIVE` → `MERGING` → `MERGED` → `DECOMMISSIONED`; `MERGING` → `ACTIVE` (hủy); `SUSPENDED` → `DECOMMISSIONED` | Tạm ngừng tenant `PLATFORM`, `COMMON`; chấm dứt khi không `SUSPENDED`; ghi vào tenant `MERGED`; dùng lại mã đã `DECOMMISSIONED` |
| Lần chạy saga | `PENDING` → `RUNNING` → `WAITING` → `RUNNING` → `SUCCEEDED`; `RUNNING` → `FAILED` → `RUNNING`; `FAILED` → `COMPENSATING` → `COMPENSATED` → `CANCELLED`; `COMPENSATING` → `FAILED` | Hai lần chạy cùng tenant; thử lại lần chạy không `FAILED`; bù trừ tenant đã từng `ACTIVE` |
| Bước saga | `PENDING` → `RUNNING` → `SUCCEEDED`; `RUNNING` → `WAITING_REPORT` → `SUCCEEDED`, `FAILED`; `FAILED` → `RUNNING`, `SKIPPED`; `SUCCEEDED` → `COMPENSATING` → `COMPENSATED` | Bỏ qua bước bắt buộc; báo tiến độ cho bước không ở `WAITING_REPORT` |
| Đề nghị có duyệt (`RequestStatus`) | `DRAFT` → `PENDING_APPROVAL` → `APPROVED` → `EXECUTING` → `DONE`; `PENDING_APPROVAL` → `REJECTED`, `DRAFT` (rút); `APPROVED` → `CANCELLED`; `EXECUTING` → `APPROVED` (lỗi, thử lại) | Tự duyệt; sửa đề nghị khi chờ duyệt; thực hiện khi chưa duyệt |
| Phân hệ theo tenant (`ModuleState`) | `DISABLED` → `ENABLING` → `ENABLED` → `SUSPENDED` → `ENABLED`; `ENABLED` → `DISABLING` → `DISABLED`; `ENABLING` → `FAILED` → `ENABLING` | Bật khi thiếu phụ thuộc; tắt phân hệ lõi; tắt phân hệ đang bị phụ thuộc |
| Sáp nhập (`MergeStatus`) | `DRAFT` → `DRY_RUN` → `DRAFT` → `PENDING_APPROVAL` → `APPROVED` → `TRANSFERRING` → `CONFLICT_REVIEW` → `TRANSFERRING` → `IDENTITY_TRANSFER` → `CUTOVER` → `TRANSITION` → `COMPLETED`; `TRANSFERRING` → `FAILED` → `TRANSFERRING`; `APPROVED` → `CANCELLED` | Gửi duyệt khi chạy thử cũ; cutover khi còn xung đột; hủy sau cutover; kết thúc sớm khi còn thông tin xác thực cũ |
| Tổ chức (`OrgStatus`) | `ACTIVE` ↔ `INACTIVE`; `ACTIVE`, `INACTIVE` → `DISSOLVED`; `ACTIVE` → `MERGED` | Giải thể khi còn tham chiếu mà không có tổ chức kế thừa; tạo chu trình; xóa cứng |
| Phiên bản sản phẩm (`ReleaseStatus`) | `DRAFT` → `PREVIEW` → `STABLE` → `DEPRECATED`; `PREVIEW`, `STABLE` → `WITHDRAWN` | `STABLE` khi mới thí điểm dưới 14 ngày; sửa phiên bản đã `PREVIEW` |
| Nâng cấp theo tenant (`TenantUpgradeStatus`) | `PENDING` → `IN_WINDOW` → `UPGRADING` → `VERIFYING` → `DONE`; `FAILED` → `UPGRADING`, `ROLLED_BACK`; `PENDING` → `SKIPPED` | Quay lui khi có thay đổi lược đồ không tương thích; tiếp tục khi sóng dừng chưa xác nhận |

: Chuyển trạng thái hợp lệ và bị cấm được kiểm thử


## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ, sau đó là các ca theo mục 1.5. `TS-20-01…36` cùng số thứ tự với `UC-20-01…36`. Mỗi use case có ít nhất một ca dương và một ca âm cho các FR của nó; mã lỗi, sự kiện, API, màn hình của FR đó được ghi ở trường truy vết của từng ca.

### TS-20-01 · Tra cứu và xem chi tiết tenant toàn nền tảng

**Mục tiêu.** Quản trị nền tảng tra cứu, lọc, xuất danh sách và xem chi tiết một tenant; tenant không thuộc phạm vi hoặc không tồn tại bị che bằng `404` thống nhất.

**Phủ.** FR-20-002, 003; UC-20-01; UI-20-01, 03; API-20-001, 003.

#### TC-20-001 · Liệt kê, tìm, lọc, sắp xếp và xuất CSV danh sách tenant <!--k:list-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-002, 060 · UC-20-01 · API-20-001 · UI-20-01 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`, `U-PAU`; `T90…T99`, `PLATFORM`, `COMMON` đã có; `T90` kênh `STABLE`, phiên bản 2.3.1.

**Các bước.**

1. `GET P/tenants?page=0&size=20`
2. `GET P/tenants?status=ACTIVE&isolationMode=SHARED&scaleProfile=QM-VUA`
3. `GET P/tenants?q=T90`
4. `GET P/tenants?channel=STABLE&currentVersion=2.3.1&testTenant=true&sort=tenantCode`
5. `GET P/tenants?format=csv`
6. Lặp bước 1 bằng `U-PO` rồi `U-PAU`

**Kết quả mong đợi.** Bước 1 `200`, mỗi mục có `tenantCode`, `name`, `kind`, `status`, `isolationMode`, `scaleProfile`, `deploymentProfile`, `currentVersion`, `channel`, `testTenant`; `PLATFORM`, `COMMON` có `kind` tương ứng. Bước 2 chỉ tenant `ACTIVE` `SHARED` `QM-VUA`. Bước 3 trả `T90`. Bước 4 trả `T90` và các tenant cùng kênh, cùng phiên bản, theo thứ tự `tenantCode`. Bước 5 trả tệp CSV có dòng tiêu đề và đủ cột, không dữ liệu cá nhân. Bước 6 cả ba vai trò đều `200`. Không phát sự kiện; không có bản ghi kiểm toán (đọc).

:::

#### TC-20-002 · Bộ lọc sai, vai trò tỉnh và chưa xác thực khi liệt kê tenant <!--k:list-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-002 · API-20-001 · ERR-20-004 · UI-20-01.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`, `U-T90-VW`.

**Các bước.**

1. `GET P/tenants?size=5000`
2. `GET P/tenants?status=XYZ`
3. `GET P/tenants?isolationMode=KHONG-CO&page=-1`
4. `U-T90-TA` gọi `GET P/tenants`
5. `U-T90-VW` gọi `GET P/tenants`
6. Gọi `GET P/tenants` không có token

**Kết quả mong đợi.** Bước 1 đến 3 `400` `ERR-20-004`, `errors[]` trỏ `size`, `status`, `isolationMode`, `page`. Bước 4, 5 `403` `ERR-00-403` (TA, VW không gọi được `/api/platform/v1`, FRS mục 3.2). Bước 6 `401` `ERR-00-401`. Không có dữ liệu tenant nào trong thân lỗi.

**Thông báo hiển thị.** ERR-20-004: "status chưa hợp lệ: giá trị không thuộc danh mục."

:::

#### TC-20-003 · Xem chi tiết tenant theo khối include và tenant đặc biệt <!--k:detail-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-003 · UC-20-01 · API-20-003 · UI-20-03, 01 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PAU`; `T90`, `PLATFORM`.

**Các bước.**

1. `GET P/tenants/T90`
2. `GET P/tenants/T90?include=summary&include=config&include=contacts&include=modules&include=quotas&include=lastRun`
3. `GET P/tenants/PLATFORM` bằng `U-PAU`
4. Mở `/nen-tang/tenant/T90` ở `dh-console`, đi qua bảy tab

**Kết quả mong đợi.** Bước 1 `200` có khối tóm tắt (`status = ACTIVE`, `realm = dh-t90`, `templateCode`, `templateVersion`, `channel`). Bước 2 trả thêm `config` (`syncStatus`, `driftStatus`, `configVersionNo`), `contacts`, `modules`, `quotas`, `lastRun`. Bước 3 `200`; tenant `PLATFORM` xem được nhưng nhãn bảo vệ hiển thị. Bước 4 bảy tab Tổng quan, Cấu hình nền tảng, Hợp đồng và đầu mối, Phân hệ, Hạn mức, Lịch sử vòng đời, Kiểm toán hiển thị theo `allowedActions[]`; `U-PAU` không thấy nút ghi.

:::

#### TC-20-004 · Chi tiết tenant không tồn tại, mã sai mẫu, khối include sai <!--k:detail-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-003 · API-20-003 · ERR-20-002, ERR-20-004 · UI-20-03.

**Tiền điều kiện, dữ liệu.** `U-PA1`; mã `T89` chưa từng khai báo.

**Các bước.**

1. `GET P/tenants/T89`
2. `GET P/tenants/T9`
3. `GET P/tenants/T90?include=khong-co`
4. `U-T90-TA` gọi `GET P/tenants/T91`

**Kết quả mong đợi.** Bước 1 `404` `ERR-20-002`. Bước 2, 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-00-403`, thân không nêu `T91` có tồn tại hay không. Màn UI-20-03 với mã không tồn tại dùng `ST-08`, câu "Không tìm thấy tenant T89 trong phạm vi được xem." và không lộ khác biệt giữa "không tồn tại" và "ngoài quyền xem".

**Thông báo hiển thị.** ERR-20-002: "Không tìm thấy tenant T89 trong phạm vi được xem."

:::

### TS-20-02 · Khai báo tenant mới và kiểm tra sẵn sàng

**Mục tiêu.** Khai báo hồ sơ tenant đầy đủ, chặn mã, ĐVHC, mẫu, đầu mối sai, bảo đảm lũy đẳng khi tạo; kiểm tra sẵn sàng báo từng mục `BLOCKER` trước khi chạy saga.

**Phủ.** FR-20-001, 007; UC-20-02; UI-20-02, 04; API-20-002, 005, 006.

#### TC-20-005 · Khai báo tenant T93 với hồ sơ đầy đủ <!--k:reg-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-001 · UC-20-02 · API-20-002 · BR-20-001, 002, 009 · UI-20-02 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-HS-93; mẫu `tinh-chuan` v3 `PUBLISHED`; ĐVHC của `T93` còn hiệu lực, chưa có tenant.

**Các bước.**

1. `POST P/tenants` thân F-HS-93 (`tenantCode = T93`, `testTenant = true`, `modulesExcluded = [PH-17]`), kèm `Idempotency-Key`, `reason`, `ticketRef` chuẩn
2. `GET P/tenants/T93`
3. `GET P/tenants/T93/contacts`

**Kết quả mong đợi.** Bước 1 `201`, `Location` trỏ `P/tenants/T93`, `status = PROVISIONING`, `kind = PROVINCE`, `realm = dh-t93`, `templateVersion = 3`, `isolationMode = SHARED`. Bước 2 `200` khớp hồ sơ. Bước 3 có ba đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL`. Chưa tạo lần chạy saga, chưa phát EVT-20-01 (chỉ phát sau `S05_BUCKETS`). KT: bản ghi khai báo vào chuỗi `PLATFORM` kèm `reason`, `ticketRef`. Mồi sạch với chuỗi `DH-CANARY-reg-ok` đặt ở `note`.

:::

#### TC-20-006 · Mã tenant sai mẫu, trong dải kiểm thử, trùng hoặc đã dùng <!--k:reg-code-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-001 · API-20-002 · BR-20-001 · ERR-20-003, ERR-20-004 · UI-20-02.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T93` đã khai báo ở ca trước; `T88` từng `DECOMMISSIONED` (bản ghi cài sẵn).

**Các bước.**

1. Khai báo với `tenantCode = X93`
2. Khai báo với `tenantCode = T7`
3. Khai báo `tenantCode = T95` với `testTenant = false`
4. Khai báo lại `tenantCode = T93`
5. Khai báo `tenantCode = T88` (mã đã `DECOMMISSIONED`)

**Kết quả mong đợi.** Bước 1, 2, 3 `400` `ERR-20-004` (mẫu `^T\d{2}$`; dải `T90…T99` chỉ với `testTenant = true`), `errors[]` trỏ `tenantCode`. Bước 4, 5 `409` `ERR-20-003`; mã đã dùng không được cấp lại kể cả tenant đã chấm dứt. Không tạo bản ghi nào.

**Thông báo hiển thị.** ERR-20-003: "Tenant T93 đã tồn tại. Chọn mã khác."

:::

#### TC-20-007 · ĐVHC đã có tenant, không phải cấp tỉnh hoặc hết hiệu lực <!--k:reg-adminunit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-001, 007 · API-20-002 · BR-20-002 · ERR-20-011, ERR-20-012.

**Tiền điều kiện, dữ liệu.** `U-PA1`; ĐVHC `adm-t90` đã gắn `T90`; ĐVHC cấp xã `adm-xa-01`; ĐVHC cấp tỉnh đã hết hiệu lực `adm-cu`.

**Các bước.**

1. Khai báo `tenantCode = T96` với `adminUnitId = adm-t90`
2. Khai báo `T96` với `adminUnitId = adm-xa-01`
3. Khai báo `T96` với `adminUnitId = adm-cu`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-011`. Bước 2, 3 `422` `ERR-20-012`. Mỗi tỉnh có tối đa một tenant không ở trạng thái cuối. Không tạo bản ghi.

**Thông báo hiển thị.** ERR-20-011: "Đơn vị hành chính Tỉnh Thử Chín Mươi đã có tenant T90 đang sử dụng."; ERR-20-012: "Đơn vị hành chính adm-xa-01 không phải cấp tỉnh hoặc đã hết hiệu lực."

:::

#### TC-20-008 · Mẫu không dùng được, thiếu đầu mối, cụm đích chưa đạt <!--k:reg-tpl-contact-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-001, 007 · API-20-002 · ERR-20-015, ERR-20-021, ERR-20-064.

**Tiền điều kiện, dữ liệu.** `U-PA1`; mẫu `tinh-nho` v1 `DRAFT`; mẫu `tinh-chuan` v2 `RETIRED`; cụm `cl-thu-01` đã đăng ký nhưng chưa `verify`.

**Các bước.**

1. Khai báo với `templateCode = tinh-nho`, `templateVersion = 1`
2. Khai báo với `templateCode = tinh-chuan`, `templateVersion = 2`
3. Khai báo với `contacts` chỉ có vai trò `TECHNICAL`
4. Khai báo `isolationMode = DEDICATED_CLUSTER`, `clusterCode = cl-thu-01`

**Kết quả mong đợi.** Bước 1, 2 `422` `ERR-20-015` (mẫu chưa phát hành, đã ngừng). Bước 3 `422` `ERR-20-021` (thiếu `TENANT_ADMIN`). Bước 4 `422` `ERR-20-064` (cụm chưa đạt, FR-20-017 đợt 2). Không tạo bản ghi.

**Thông báo hiển thị.** ERR-20-015: "Mẫu khởi tạo tinh-nho phiên bản 1 không dùng được: mẫu chưa phát hành."; ERR-20-021: "Cần đủ đầu mối TENANT_ADMIN trước khi khai báo tenant."

:::

#### TC-20-009 · Khai báo lặp cùng khóa chống lặp và khóa dùng cho yêu cầu khác <!--k:reg-idem-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-001 · API-20-002 · ERR-20-009, ERR-20-004 · NFR-20-020.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-HS-93 với mã `T94`; khóa `ik-reg-1`.

**Các bước.**

1. `POST P/tenants` hồ sơ `T94` với `Idempotency-Key = ik-reg-1`
2. Gửi lại đúng thân, đúng khóa
3. Gửi `Idempotency-Key = ik-reg-1` với thân khác (`tenantCode = T95`)
4. Gửi không có `Idempotency-Key`

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `201` cùng thân, cùng `Location`, chỉ có một bản ghi `T94`. Bước 3 `409` `ERR-20-009`. Bước 4 `400` `ERR-20-004`, `errors[]` trỏ tiêu đề `Idempotency-Key` (đề nghị ĐN-TC-03 xác nhận mã). Chỉ một bản ghi kiểm toán khai báo.

**Thông báo hiển thị.** ERR-20-009: "Khóa chống lặp đã được dùng cho một yêu cầu khác. Tạo yêu cầu mới."

:::

#### TC-20-010 · Kiểm tra sẵn sàng cho hồ sơ chưa lưu và hồ sơ đã lưu <!--k:ready-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-007 · UC-20-02 · API-20-005, 006 · UI-20-02 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-HS-93; sức chứa còn trống; PH-12, PH-13, PH-07 giả lập sẵn sàng.

**Các bước.**

1. `POST P/tenants:check-readiness` với thân hồ sơ chưa lưu (`tenantCode = T96`)
2. `POST P/tenants/T93:check-readiness`

**Kết quả mong đợi.** Bước 1, 2 `200`, `ready = true`, `items[]` có đủ mười mục `CODE_UNIQUE`, `ADMIN_UNIT`, `CAPACITY`, `CLUSTER_RESOURCES`, `TEMPLATE`, `CONTACTS`, `HOST_PREFIX`, `DEPENDENCIES`, `CLUSTER_TARGET`, `CONTRACT` với mức qua; `CLUSTER_TARGET` không áp dụng ở chế độ `SHARED`. Không tạo bản ghi, không có kiểm toán ghi.

:::

#### TC-20-011 · Hết sức chứa nền tảng và thiếu tài nguyên cụm <!--k:ready-capacity-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-007 · API-20-005, 006 · BR-20-002 · ERR-20-013, ERR-20-014, ERR-20-017 · NFR-20-005.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `obs-sim` báo `EVT-13-14` cảnh báo sức chứa: nền tảng đã có 34 tenant tỉnh (trần giả định theo NFR-00-060); cụm `HT-A` thiếu 8 CPU ảo.

**Các bước.**

1. `POST P/tenants:check-readiness` với hồ sơ `T96`
2. `POST P/tenants:check-readiness` với `deploymentProfile = HT-A`
3. `POST P/tenants/T93:check-readiness` khi còn hai mục `BLOCKER`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-013` ở mục `CAPACITY` và `ERR-20-017` tổng. Bước 2 `422` `ERR-20-014` ở `CLUSTER_RESOURCES` (thiếu 8 CPU ảo). Bước 3 `422` `ERR-20-017` với `items[]` nêu hai mục cần xử lý. Cảnh báo sức chứa nhận từ `EVT-13-14` hiển thị ở UI-20-20.

**Thông báo hiển thị.** ERR-20-013: "Nền tảng đã đạt sức chứa 34 tenant. Liên hệ vận hành hạ tầng để mở rộng."; ERR-20-014: "Cụm chưa đủ tài nguyên cho hồ sơ HT-A: thiếu 8 CPU ảo."; ERR-20-017: "Kiểm tra sẵn sàng chưa đạt: 2 mục cần xử lý."

:::

#### TC-20-012 · Kiểm tra sẵn sàng khi phụ thuộc không khả dụng <!--k:ready-dep-neg-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-007 · API-20-005, 006 · ERR-20-062 · NFR-20-017.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `iam-sim` trả `503` cho API-12-080 thăm dò.

**Các bước.**

1. `POST P/tenants:check-readiness` với hồ sơ `T96`
2. Bật lại `iam-sim`, lặp bước 1

**Kết quả mong đợi.** Bước 1 `503` `ERR-20-062` với tên dịch vụ PH-12, mục `DEPENDENCIES` ở mức `BLOCKER`, thân không mất dữ liệu đã nhập. Bước 2 `200`, `ready = true`.

**Thông báo hiển thị.** ERR-20-062: "Dịch vụ PH-12 tạm thời không khả dụng. Thử lại sau."

:::

### TS-20-03 · Sửa hồ sơ, đầu mối, hợp đồng và bảo vệ tenant đặc biệt

**Mục tiêu.** Sửa hồ sơ hành chính có `If-Match`, lý do, phiếu; mã tenant và realm bất biến; quản lý đầu mối, hợp đồng; `PLATFORM`, `COMMON` được bảo vệ khỏi thao tác nguy hiểm.

**Phủ.** FR-20-004, 005, 006; UC-20-03; UI-20-03; API-20-004, 007…012.

#### TC-20-013 · Sửa tên, quy mô, ghi chú của tenant có If-Match và lý do <!--k:prof-edit-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-004 · UC-20-03 · API-20-004 · BR-20-009 · UI-20-03 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` `ACTIVE`; `ETag` lần đọc trước.

**Các bước.**

1. `GET P/tenants/T90` lấy `ETag`
2. `PATCH P/tenants/T90` với `name`, `note` (chứa `DH-CANARY-prof-edit`), `scaleProfile = QM-LON`, `reason` 25 ký tự, `ticketRef`, kèm `If-Match`
3. `GET P/tenants/T90`
4. `GET P/tenants/T90/status-history`

**Kết quả mong đợi.** Bước 2 `200`, `ETag` mới. Bước 3 trả giá trị mới, `tenantCode`, `realm`, `kind` giữ nguyên. KT: có `reason`, `ticketRef`, người sửa, giá trị trước và sau, vào chuỗi `T90` và `PLATFORM`. Mồi sạch ở `note` không xuất hiện trong log, sự kiện. Lịch sử trạng thái không đổi (không phải đổi trạng thái).

:::

#### TC-20-014 · Sửa hồ sơ thiếu If-Match, lệch phiên bản, thiếu lý do, đổi thuộc tính bất biến <!--k:prof-edit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-004 · API-20-004 · BR-20-001, 009 · ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-068, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; `T90`; `T88` đã `DECOMMISSIONED` (bản ghi cài sẵn).

**Các bước.**

1. `PATCH P/tenants/T90` thiếu `If-Match`
2. `U-PA1` và `U-PA2` cùng đọc `ETag`, `U-PA1` sửa trước, `U-PA2` sửa sau cùng `ETag` cũ
3. `PATCH` với `reason` 10 ký tự và không `ticketRef`
4. `PATCH` với thân có `tenantCode = T89` hoặc `realm = dh-khac`
5. `PATCH P/tenants/T88` (đã `DECOMMISSIONED`)

**Kết quả mong đợi.** Bước 1 `428` `ERR-00-428`. Bước 2 người sau `412` `ERR-20-005`, không mất cập nhật. Bước 3 `422` `ERR-20-008`. Bước 4 `422` `ERR-20-068`, không đổi gì. Bước 5 `409` `ERR-20-006`. Không có bản ghi kiểm toán thành công cho các lần bị từ chối.

**Thông báo hiển thị.** ERR-20-005: "Tenant đã được người khác sửa. Tải lại để xem thay đổi."; ERR-20-008: "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu."; ERR-20-068: "Không đổi được tenantCode của tenant sau khai báo."

:::

#### TC-20-015 · PLATFORM và COMMON không bị sửa, tạm ngừng, chấm dứt, tắt phân hệ <!--k:special-tenant-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, DB.

**Truy vết.** FR-20-006 · API-20-004, 065, 066, 071, 047 · BR-20-003 · ERR-20-010 · `PERM-20-lifecycle`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `PLATFORM`, `COMMON`; khối DB của `ph20_isolation_test.sql` mục 1 (trigger bảo vệ tenant).

**Các bước.**

1. `PATCH P/tenants/PLATFORM` đổi `name`
2. `POST P/tenants/COMMON/lifecycle-requests` với `requestType = SUSPEND`
3. `POST P/tenants/COMMON/lifecycle-requests` với `requestType = TERMINATE`
4. `POST P/tenants/PLATFORM/modules/PH-16:disable`
5. `POST P/tenants/COMMON/isolation-changes` với `targetMode = DEDICATED_DB`
6. Chạy khối kiểm trigger bảo vệ tenant bằng `psql` dưới chủ schema

**Kết quả mong đợi.** Bước 1 đến 5 `403` `ERR-20-010`, tenant không đổi. Bước 6 trigger từ chối cập nhật trạng thái, xóa dòng `PLATFORM`, `COMMON` (PASS theo tệp kiểm). Không phát sự kiện đổi trạng thái.

**Thông báo hiển thị.** ERR-20-010: "Tenant PLATFORM là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."

:::

#### TC-20-016 · Thêm, sửa, ngừng đầu mối; thêm, gia hạn hợp đồng dịch vụ <!--k:contact-contract-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-005 · API-20-007, 008, 009, 010, 011, 012 · BR-20-009 · UI-20-03 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` có ba đầu mối; hợp đồng `HD-T90-2026` hiệu lực đến 31/12/2026.

**Các bước.**

1. `GET P/tenants/T90/contacts`
2. `POST P/tenants/T90/contacts` vai trò `SECURITY`, `fullName`, `officialEmail` (miền `example.vn`), `phone`
3. `PATCH P/tenants/T90/contacts/{contactId}` đổi `position`, kèm `If-Match`
4. `PATCH` đầu mối vừa thêm với `active = false`
5. `POST P/tenants/T90/contracts` với `contractNo = HD-T90-2027`, `validFrom`, `validTo`, `serviceLevel = PREMIUM`
6. `PATCH P/tenants/T90/contracts/{contractId}` gia hạn `validTo`
7. `GET P/tenants/T90/contracts`

**Kết quả mong đợi.** Bước 1 có ba đầu mối. Bước 2 `201`. Bước 3, 4 `200` đổi đúng trường. Bước 5 `201`. Bước 6 `200`, `ETag` mới. Bước 7 liệt kê hai hợp đồng. Mọi thao tác ghi có KT kèm `reason`, `ticketRef`; email không xuất hiện trong log (mồi sạch).

:::

#### TC-20-017 · Ngừng đầu mối quản trị cuối cùng, hợp đồng sai thời hạn, trùng, sai định dạng <!--k:contact-contract-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-005 · API-20-008, 009, 011, 012 · ERR-20-004, ERR-20-005, ERR-20-021, ERR-20-022, ERR-20-008.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T91` chỉ có một đầu mối `TENANT_ADMIN`.

**Các bước.**

1. `PATCH` đầu mối `TENANT_ADMIN` duy nhất của `T91` với `active = false`
2. `POST P/tenants/T91/contacts` với `officialEmail = khong-phai-email`
3. `POST P/tenants/T91/contracts` với `validTo` trước `validFrom`
4. `POST P/tenants/T91/contracts` chồng khoảng hiệu lực lên hợp đồng đang `ACTIVE`
5. `PATCH` hợp đồng với `If-Match` cũ
6. `PATCH` đầu mối không có `reason`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-021`. Bước 2 `400` `ERR-20-004`. Bước 3, 4 `422` `ERR-20-022`. Bước 5 `412` `ERR-20-005`. Bước 6 `422` `ERR-20-008`. Không đổi dữ liệu.

**Thông báo hiển thị.** ERR-20-022: "Hợp đồng HD-T91-2026: ngày hết hiệu lực phải sau ngày bắt đầu."

:::

#### TC-20-018 · Tenant đặc biệt vẫn đọc được, registry luôn ACTIVE, tenant tỉnh sửa bình thường <!--k:special-tenant-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-006 · API-20-003, 004, 162, 163 · BR-20-009 · UC-20-03.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `S-PH03`; `PLATFORM`, `COMMON`, `T90` `ACTIVE`.

**Các bước.**

1. `GET P/tenants/PLATFORM` và `GET P/tenants/COMMON`
2. `S-PH03` `GET I/tenants` và `GET I/tenants?kind=PROVINCE`
3. `PATCH P/tenants/T90` đổi `displayName`, kèm `If-Match`, `reason`, `ticketRef`

**Kết quả mong đợi.** Bước 1 `200`, hiển thị `kind`, trạng thái `ACTIVE`. Bước 2 registry luôn trả `PLATFORM`, `COMMON` `ACTIVE`; lọc `kind=PROVINCE` không có hai tenant này. Bước 3 `200` (lớp chặn tenant đặc biệt không cản tenant tỉnh).

:::

### TS-20-04 · Quản lý mẫu khởi tạo có phiên bản

**Mục tiêu.** Soạn mẫu khởi tạo, mở phiên bản mới, so sánh, phát hành và ngừng; phiên bản đã phát hành bất biến, lần chạy saga ghi phiên bản mẫu đã dùng.

**Phủ.** FR-20-015; UC-20-04; UI-20-21; API-20-025…032.

#### TC-20-019 · Tạo mẫu, mở phiên bản mới, sửa, so sánh, phát hành, ngừng phiên bản <!--k:tpl-lifecycle-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-015 · UC-20-04 · API-20-025, 026, 027, 028, 029, 030, 031, 032 · BR-20-042 · UI-20-21 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; mẫu `tinh-chuan` v3 `PUBLISHED`.

**Các bước.**

1. `GET P/provisioning-templates?state=PUBLISHED`
2. `POST P/provisioning-templates` mã `mau-thu-90` với `modules`, `quotaByScale` bốn quy mô, `rdmPackageVersion`, `orgSeed`, `activation = AUTO`, `releaseChannel = STABLE`
3. `GET P/provisioning-templates/mau-thu-90`
4. `POST P/provisioning-templates/tinh-chuan/versions` với `fromVersion = 3`, `changeNote`
5. `PATCH P/provisioning-templates/tinh-chuan/versions/4` đổi `kpiSetVersion`, kèm `If-Match`
6. `GET P/provisioning-templates/tinh-chuan/versions/4?compareTo=3`
7. `POST .../versions/4:publish`
8. `POST .../versions/3:retire` với `reason`

**Kết quả mong đợi.** Bước 2 `201`, phiên bản 1 `DRAFT`. Bước 4 `201` phiên bản 4 `DRAFT` sao từ 3. Bước 5 `200`. Bước 6 trả bảng so sánh chỉ khác `kpiSetVersion`. Bước 7 `200`, phiên bản 4 `PUBLISHED`, bất biến. Bước 8 phiên bản 3 `RETIRED`, các lần chạy cũ vẫn giữ `templateVersion = 3`. KT mọi thao tác ghi.

:::

#### TC-20-020 · Mẫu trùng mã, thiếu phân hệ lõi, hạn mức quá trần, sửa bản đã phát hành <!--k:tpl-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-015 · API-20-026, 028, 030, 031, 032 · BR-20-042 · ERR-20-003, ERR-20-006, ERR-20-029, ERR-20-033, ERR-20-063, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; mẫu `tinh-chuan` v3 `PUBLISHED`, v4 `DRAFT`.

**Các bước.**

1. `POST P/provisioning-templates` mã `tinh-chuan`
2. `POST P/provisioning-templates` với `modules` thiếu PH-12 (phân hệ lõi)
3. `PATCH .../tinh-chuan/versions/4` đặt `quotaByScale` `API_RPS` vượt trần nền tảng
4. `PATCH .../tinh-chuan/versions/3` (đã `PUBLISHED`)
5. `POST .../versions/3:publish` lần hai
6. `PATCH .../versions/4` không có `If-Match`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-003`. Bước 2 `422` `ERR-20-033`. Bước 3 `422` `ERR-20-029`. Bước 4 `409` `ERR-20-063`. Bước 5 `409` `ERR-20-006`. Bước 6 `428` `ERR-00-428`. Mẫu không đổi.

**Thông báo hiển thị.** ERR-20-063: "Phiên bản 3 của mẫu tinh-chuan đã phát hành, không sửa được. Tạo phiên bản mới."; ERR-20-029: "Hạn mức API_RPS phải trong khoảng 1 đến 5000 request/giây."

:::

#### TC-20-021 · Ngừng phiên bản mẫu đang được lần chạy dùng và dùng mẫu đã ngừng <!--k:tpl-retire-used-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-20-015 · API-20-032, 002 · BR-20-042 · ERR-20-006, ERR-20-015.

**Tiền điều kiện, dữ liệu.** `U-PA1`; lần chạy `RUNNING` của `T93` đang dùng `tinh-chuan` v4; `tinh-chuan` v2 `RETIRED`.

**Các bước.**

1. `POST .../versions/4:retire` khi lần chạy đang dùng
2. Khai báo tenant mới với `templateVersion = 2`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006` (còn lần chạy chưa kết thúc dùng phiên bản này). Bước 2 `422` `ERR-20-015` với lý do "phiên bản đã ngừng". Mẫu v4 giữ `PUBLISHED`.

:::

### TS-20-05 · Chạy saga khởi tạo tenant

**Mục tiêu.** Chạy saga 17 bước tới `ACTIVE`: bước đồng bộ, bước chờ báo, bước không áp dụng `SKIPPED`, sự kiện đúng thời điểm, một lần chạy chưa kết thúc cho mỗi tenant; phân hệ báo tiến độ qua API nội bộ.

**Phủ.** FR-20-008; UC-20-05; UI-20-02, 03, 04; API-20-013, 166.

#### TC-20-022 · Chạy saga INITIAL của T93 tới ACTIVE qua 17 bước <!--k:run-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, IT.

**Truy vết.** FR-20-008, 012, 013 · UC-20-05 · API-20-013, 015, 166 · BR-20-004, 005, 006, 042 · EVT-20-01, 03, 07 · UI-20-04 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`; `T93` `PROVISIONING` (ca reg-ok); F-SAGA toàn `OK`; PH-06, PH-16, PH-19 bật theo mẫu, PH-17 tắt.

**Các bước.**

1. `POST P/tenants/T93/provisioning-runs` với `runKind = INITIAL`
2. Theo dõi `GET P/provisioning-runs/{runId}` cho tới khi kết thúc
3. Đọc `steps[]` và `smokeResults[]`
4. Đọc sự kiện trên `platform.tenant.created.v1`, `platform.tenant.module-enabled.v1`, `platform.tenant.activated.v1`

**Kết quả mong đợi.** Bước 1 `202`, `Location` trỏ lần chạy, `status = PENDING`, 17 bước theo thứ tự. Bước 2 kết thúc `SUCCEEDED`, `durationSeconds` ≤ 3.600; tenant `ACTIVE`. Bước 3: `S07_DATABASE` `SKIPPED` (chế độ `SHARED`); các bước còn lại `SUCCEEDED`, mỗi bước có `outputRef`; bốn ca khói `PASS`. EVT: `created` đúng một lần ngay sau `S05_BUCKETS`; `module-enabled` cho mỗi phân hệ không lõi bật theo mẫu (PH-19, PH-16, PH-06; không có PH-17); `activated` một lần ở `S17_ACTIVATE`. Phân hệ lõi `ENABLED` ngay. KT: mỗi bước bắt đầu, kết thúc, kết quả, `templateVersion = 3`, vào chuỗi `PLATFORM` và chuỗi `T93` khi đã có.

:::

#### TC-20-023 · Bước không áp dụng: S07 theo chế độ cách ly, S12 và S14 theo phân hệ bật <!--k:run-skip-rules-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-008 · API-20-013 · UC-20-05 · BR-20-042.

**Tiền điều kiện, dữ liệu.** `T95` hồ sơ `DEDICATED_DB`; `T93` hồ sơ không bật PH-06, PH-16 (mẫu `mau-thu-90` bản không có hai phân hệ này); CNPG giả.

**Các bước.**

1. Chạy saga `INITIAL` cho `T95` (`DEDICATED_DB`)
2. Chạy saga `INITIAL` cho tenant dùng mẫu không bật PH-06 và PH-16
3. So sánh trạng thái `S07_DATABASE`, `S12_SEED_MDM`, `S14_KPI`

**Kết quả mong đợi.** `T95`: `S07_DATABASE` chạy và `SUCCEEDED` (tạo cụm CloudNativePG, migration, bảng định tuyến), các bước sau dùng chuỗi kết nối mới. Tenant không bật PH-06: `S12_SEED_MDM` `SKIPPED`; không bật PH-16: `S14_KPI` `SKIPPED`; cả hai lần chạy vẫn `SUCCEEDED`.

:::

#### TC-20-024 · Chạy saga khi tenant sai trạng thái, đang có lần chạy, chưa sẵn sàng, tenant đặc biệt <!--k:run-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-008, 016 · API-20-013 · BR-20-006 · ERR-20-006, ERR-20-010, ERR-20-016, ERR-20-017, ERR-20-009.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` `ACTIVE`; `T94` có một lần chạy `RUNNING`; `T96` có `BLOCKER` sức chứa.

**Các bước.**

1. `POST P/tenants/T90/provisioning-runs` với `runKind = INITIAL`
2. `POST P/tenants/T94/provisioning-runs` lần hai khi lần chạy đầu chưa kết thúc
3. `POST P/tenants/T96/provisioning-runs` khi kiểm tra sẵn sàng có `BLOCKER`
4. `POST P/tenants/PLATFORM/provisioning-runs`
5. Gửi lại cùng `Idempotency-Key` khác thân

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `409` `ERR-20-016` kèm `runId` đang chạy. Bước 3 `422` `ERR-20-017`. Bước 4 `403` `ERR-20-010`. Bước 5 `409` `ERR-20-009`. Mỗi tenant có tối đa một lần chạy chưa kết thúc.

**Thông báo hiển thị.** ERR-20-016: "Tenant T94 đang có lần khởi tạo run-0001 chưa kết thúc."; ERR-20-006: "Không thể chạy saga khi tenant đang ở trạng thái ACTIVE."

:::

#### TC-20-025 · Phân hệ báo tiến độ bước chờ báo: hợp lệ, báo trùng, sai trạng thái, thiếu scope <!--k:report-api-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-008, 009 · API-20-166 · BR-20-005 · ERR-20-002, ERR-20-004, ERR-20-104, ERR-20-105.

**Tiền điều kiện, dữ liệu.** `T94` có lần chạy với `S06_EVENTING` `WAITING_REPORT`, `S10_INTEGRATION` `PENDING`; `S-PH10` (scope `tenant:provision-report`), `S-NOSCOPE`, `S-PH03`.

**Các bước.**

1. `S-PH10` gọi `POST I/provisioning-runs/{runId}/steps/S06_EVENTING:report` với `status = SUCCEEDED`, `outputRef`, kèm `Idempotency-Key = {runId}:S06_EVENTING:report`
2. `S-PH10` gửi lại đúng báo cáo, đúng khóa
3. `S-PH10` báo cho `S10_INTEGRATION` đang `PENDING`
4. `S-NOSCOPE` báo cho `S06_EVENTING`
5. `S-PH10` báo `status = FAILED` thiếu `errorCode`
6. Báo cho `runId` không tồn tại

**Kết quả mong đợi.** Bước 1 `200`, `S06_EVENTING` `SUCCEEDED`. Bước 2 `200` trả lại đúng kết quả lần đầu, không đổi bước hai lần. Bước 3 `409` `ERR-20-105`. Bước 4 `403` `ERR-20-104`. Bước 5 `400` `ERR-20-004`. Bước 6 `404` `ERR-20-002`. SSE của UI-20-04 nhận `step-changed` cho bước 1.

**Thông báo hiển thị.** ERR-20-105: "Báo tiến độ bước S10_INTEGRATION không khớp trạng thái PENDING."; ERR-20-104: "Tài khoản dịch vụ không có quyền tenant:provision-report."

:::

### TS-20-06 · Theo dõi saga, thử lại, bù trừ và hủy khởi tạo

**Mục tiêu.** Theo dõi tiến độ saga thời gian thực; thử lại từ đúng bước lỗi không làm lại bước đã xong; bỏ qua bước không bắt buộc; bù trừ ngược và hủy khởi tạo không để tài nguyên mồ côi.

**Phủ.** FR-20-009, 010, 011; UC-20-06; UI-20-04; API-20-014…021.

#### TC-20-026 · Xem danh sách lần chạy, chi tiết và luồng SSE kèm nối lại <!--k:track-stream-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-009 · UC-20-06 · API-20-014, 015, 016 · NFR-20-007 · UI-20-04 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; lần chạy `RUNNING` của `T97`.

**Các bước.**

1. `GET P/tenants/T97/provisioning-runs`
2. `GET P/provisioning-runs/{runId}`
3. Mở `GET P/provisioning-runs/{runId}/stream` bằng `U-PO`, ghi `eventId`
4. Ngắt kết nối giữa chừng, nối lại với `Last-Event-ID`
5. Ngắt hơn 1 giờ rồi nối lại với `Last-Event-ID` cũ

**Kết quả mong đợi.** Bước 1, 2 `200`, có `currentStep`, `elapsedSeconds`, `etaSeconds`. Bước 3 nhận `step-changed` mỗi lần đổi bước, trễ ≤ 2 giây so với thời điểm bước đổi. Bước 4 nhận chuỗi bù, không mất, không lặp sự kiện. Bước 5 nhận ảnh chụp đầy đủ, không báo lỗi. UI-20-04 cập nhật dòng bước tại chỗ, giữ vị trí cuộn, hiện "Đang nối lại…" khi mất kết nối. `U-PO` thấy tiến độ nhưng không có nút ghi.

:::

#### TC-20-027 · Thử lại từ bước lỗi đầu tiên, bước đã xong không làm lại <!--k:retry-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-010 · UC-20-06 · API-20-017, 018 · BR-20-005, 007 · EVT-20-02 · UI-20-04 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `T94`; F-SAGA: `S09_GATEWAY` `FAIL_ALWAYS` rồi đổi thành `OK`; lần chạy `FAILED`, `S01…S08` `SUCCEEDED`.

**Các bước.**

1. Quan sát lần chạy `FAILED` sau 3 lần tự thử ở `S09_GATEWAY` (10, 30, 90 giây, dùng `clock-sim`)
2. Chuyển bản giả `S09_GATEWAY` sang `OK`
3. `POST P/provisioning-runs/{runId}:retry` với `reason`, kèm `If-Match`, `Idempotency-Key`
4. Theo dõi tới khi kết thúc

**Kết quả mong đợi.** Bước 1 EVT: `platform.tenant.provisioning-failed.v1` (EVT-20-02) đúng một lần; tenant `FAILED`; việc báo PA ở PH-18. Bước 3 `202`, `status = RUNNING`, `attempt` tăng; tenant `PROVISIONING`; bước `S09_GATEWAY` gọi lại với cùng `Idempotency-Key = {runId}:S09_GATEWAY`, `S01…S08` không bị làm lại (bản giả đếm đúng một lần gọi mỗi bước). Bước 4 lần chạy `SUCCEEDED`. KT có lần thử lại, người thử, lý do.

:::

#### TC-20-028 · Thử lại một bước, bỏ qua bước không bắt buộc, từ chối bỏ qua bước bắt buộc <!--k:retry-step-skip-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-010 · API-20-018, 019 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-018, ERR-20-009.

**Tiền điều kiện, dữ liệu.** `T94`; lần chạy `FAILED` với `S12_SEED_MDM` `FAILED` rồi `S03_REALM` `FAILED` ở lần chạy khác.

**Các bước.**

1. `POST .../steps/S12_SEED_MDM:retry`
2. `POST .../steps/S12_SEED_MDM:skip` với `reason` 25 ký tự, `ticketRef`
3. `POST .../steps/S03_REALM:skip` (bước bắt buộc)
4. `POST .../steps/S12_SEED_MDM:skip` với `reason` 8 ký tự
5. `POST .../steps/S01_RECORD:retry` khi bước đã `SUCCEEDED`
6. `POST .../steps/S12_SEED_MDM:skip` với `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 `202`, bước `SKIPPED` kèm lý do, saga tiếp tục. Bước 3 `409` `ERR-20-018`. Bước 4 `422` `ERR-20-008`. Bước 5 `409` `ERR-20-018`. Bước 6 `412` `ERR-20-005`. Chỉ `S12_SEED_MDM`, `S14_KPI` và từng phân hệ của `S15_MODULES` bỏ qua được.

**Thông báo hiển thị.** ERR-20-018: "Không thể thử lại bước S03_REALM: bước bắt buộc, không bỏ qua được."

:::

#### TC-20-029 · Thử lại lần chạy không ở FAILED, thiếu If-Match <!--k:retry-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-010 · API-20-017 · ERR-20-006, ERR-20-018, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `T93` lần chạy `SUCCEEDED`; `T94` lần chạy `RUNNING`.

**Các bước.**

1. `POST P/provisioning-runs/{runId-T93}:retry`
2. `POST P/provisioning-runs/{runId-T94}:retry` khi đang `RUNNING`
3. `POST .../{runId-T94 FAILED}:retry` thiếu `If-Match`

**Kết quả mong đợi.** Bước 1, 2 `409` `ERR-20-006`. Bước 3 `428` `ERR-00-428`.

**Thông báo hiển thị.** ERR-20-006: "Không thể thử lại khi lần chạy đang ở trạng thái RUNNING."

:::

#### TC-20-030 · Bù trừ ngược và hủy khởi tạo, bucket còn đối tượng để dọn tay <!--k:compensate-cancel-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-011 · UC-20-06 · API-20-020, 021 · BR-20-001, 005 · EVT-20-04 · UI-20-04 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `T94` `FAILED` ở `S09_GATEWAY` sau khi `S01…S08` xong; bucket `dh-t94-files` còn một đối tượng thử.

**Các bước.**

1. `POST P/provisioning-runs/{runId}:cancel` với `reason`, `ticketRef`, `confirmTenantCode = T94`
2. Theo dõi thứ tự gọi bù trừ ở các bản giả
3. Đọc `steps[]`, trạng thái tenant
4. Khai báo lại tenant với `tenantCode = T94`

**Kết quả mong đợi.** Bước 1 `202`, lần chạy `COMPENSATING`. Bước 2 thứ tự bù ngược `S08` (đóng chuỗi API-13-073), `S07` không áp dụng, `S06` (EVT-20-04 `DECOMMISSIONED` để PH-10 gỡ), `S05` bucket rỗng thì xóa, bucket có đối tượng thì để lại đánh dấu `MANUAL_CLEANUP`, `S04` xóa đường dẫn và KEK chưa dùng, `S03` xóa realm `PROVISIONING`, `S02` revert commit, `S01` xóa bản ghi chỉ khi chưa có bước nào xong; mỗi lời gọi mang `Idempotency-Key = {runId}:{stepCode}:compensate`. Bước 3 lần chạy `COMPENSATED` rồi `CANCELLED`, tenant `DECOMMISSIONED`, danh sách việc dọn tay hiện ở UI-20-04. Bước 4 `409` `ERR-20-003` (mã không tái dùng, BR-20-001). EVT: `status-changed` đúng một lần.

:::

#### TC-20-031 · Bù trừ tenant đã từng hoạt động, sai mã xác nhận, sai trạng thái, bù trừ lỗi <!--k:compensate-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-011 · API-20-020, 021 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-019, ERR-20-107.

**Tiền điều kiện, dữ liệu.** `T90` đã từng `ACTIVE`; `T94` lần chạy `FAILED`; `T97` lần chạy `SUCCEEDED`; bản giả `S03_REALM` trả lỗi khi bù.

**Các bước.**

1. `POST P/provisioning-runs/{runId-T90}:compensate` (lần chạy `INITIAL` cũ của tenant đã `ACTIVE`)
2. `POST .../{runId-T94}:cancel` với `confirmTenantCode = T99`
3. `POST .../{runId-T97}:compensate` khi `SUCCEEDED`
4. `POST .../{runId-T94}:cancel` không có `reason`
5. Bù trừ `T94` khi `iam-sim` lỗi ở `S03_REALM`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-019`. Bước 2 `400` `ERR-20-004`. Bước 3 `409` `ERR-20-006`. Bước 4 `422` `ERR-20-008`. Bước 5 bước `S03_REALM` giữ `COMPENSATING` với `ERR-20-107` ("Bước S03_REALM lỗi tại PH-12: không tạo được realm."), lần chạy `FAILED`, PA thử bù lại được; không xóa bản ghi tenant.

**Thông báo hiển thị.** ERR-20-019: "Không thể bù trừ: tenant T90 đã từng hoạt động."

:::

### TS-20-07 · Kiểm tra khói, kích hoạt, bàn giao và đo thời gian khởi tạo

**Mục tiêu.** Kiểm tra khói bốn ca trước khi kích hoạt; kích hoạt và bàn giao chỉ khi khói đạt; đo thời gian khởi tạo (KPI-12) và đẩy cho PH-16.

**Phủ.** FR-20-012, 013, 014; UC-20-07; UI-20-04, 20; API-20-015, 022, 023, 024.

#### TC-20-032 · Chạy lại kiểm tra khói trên tenant đang hoạt động <!--k:smoke-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-012 · UC-20-07 · API-20-022, 015 · BR-20-004 · UI-20-04 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T93` `ACTIVE`; `iam-sim`, `mod-sim` sẵn sàng; `T99` có tài nguyên mồi.

**Các bước.**

1. `POST P/tenants/T93/smoke-tests`
2. `GET P/provisioning-runs/{runId}` đọc `smokeResults[]`

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 có bốn ca `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK` đều `PASS`, mỗi ca có `durationMs`, `evidence`; ca `CROSS_TENANT_LEAK` đọc tài nguyên mồi của `T99` bằng token `T93` và nhận `404`. Tài khoản máy tạm `smoke-{runId}` hết hạn 30 phút và bị xóa; HTTT giả lập bị xóa; trạng thái tenant không đổi.

:::

#### TC-20-033 · Ca khói lỗi, rò rỉ phát hiện, tắt khói, chạy chồng <!--k:smoke-fail-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-012 · API-20-022, 023 · BR-20-004 · ERR-20-006, ERR-20-016, ERR-20-020, ERR-20-111, ERR-20-117.

**Tiền điều kiện, dữ liệu.** `T94` ở `S16_SMOKE`; `mod-sim` cài `EVENT_SAMPLE` lỗi; kịch bản khác cài `CROSS_TENANT_LEAK` trả `200`; `T92` `SUSPENDED`.

**Các bước.**

1. Chạy saga `T94` tới `S16_SMOKE` với `EVENT_SAMPLE` lỗi
2. Cài `T99` đọc được từ token `T94` (rò rỉ giả lập) rồi chạy lại khói
3. Đặt `20.smoke.enabled = false` cho `T94` (tenant kiểm thử), chạy lại; thử đặt `false` ở nền tảng có tenant tỉnh thật
4. `POST P/tenants/T92/smoke-tests` khi `SUSPENDED`; `POST` khi đang có lần chạy khác

**Kết quả mong đợi.** Bước 1 ca `EVENT_SAMPLE` ghi `ERR-20-117` ("Ca kiểm tra khói EVENT_SAMPLE lỗi: không nhận lại sự kiện mẫu sau 30 giây."), bước `S16_SMOKE` và lần chạy `FAILED`. Bước 2 `ERR-20-111` ("Phát hiện rò rỉ chéo tenant ở GET /api/tenant/v1/context."), sự cố mức 1 mở ở PH-18, báo PO, kích hoạt bị chặn. Bước 3 tenant kiểm thử: `S16_SMOKE` `SKIPPED` kèm cảnh báo; đặt `false` khi có tenant tỉnh thật bị từ chối (BR-20-004). Bước 4 `409` `ERR-20-006`, rồi `409` `ERR-20-016`.

**Thông báo hiển thị.** ERR-20-117: "Ca kiểm tra khói EVENT_SAMPLE lỗi: không nhận lại sự kiện mẫu sau 30 giây."

:::

#### TC-20-034 · Kích hoạt tenant, bàn giao qua thư, hẹn giờ kích hoạt <!--k:activate-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-013, 014 · UC-20-07 · API-20-023, 015 · BR-20-004 · EVT-20-03 · UI-20-04 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `T97` `PROVISIONING`, bước `S16_SMOKE` đạt; `T93` hẹn giờ; `ops-sim` nhận thư; `kpi-sim` sẵn sàng.

**Các bước.**

1. `POST P/tenants/T97:activate` kèm `If-Match`, `Idempotency-Key`
2. `POST P/tenants/T96:activate` với `activateAt` sau 5 ngày; sau đó dùng `clock-sim` đẩy tới giờ hẹn
3. Đọc thư bàn giao ở `ops-sim`, đọc quan sát ở `kpi-sim`

**Kết quả mong đợi.** Bước 1 `200`, tenant `ACTIVE`, `activatedAt` có giá trị, `handoverDelivery = SENT`, máy khách kiểm thử ở realm bị xóa; EVT: `platform.tenant.activated.v1` đúng một lần; registry vô hiệu đệm. Bước 2 `S17_ACTIVATE` chờ tới giờ hẹn rồi `ACTIVE`; hủy hẹn thì kích hoạt ngay. Bước 3 thư mẫu `ph20-handover` tới ba đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL`; PH-16 nhận quan sát `thoi-gian-khoi-tao-tenant` (KPI-12) kèm tham chiếu chống lặp là `runId`. KT kích hoạt.

:::

#### TC-20-035 · Kích hoạt khi khói chưa đạt, sai trạng thái, thiếu đầu mối, thư và KPI lỗi <!--k:activate-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-013, 014 · API-20-023 · ERR-20-006, ERR-20-020, ERR-20-021, ERR-20-062, ERR-20-005.

**Tiền điều kiện, dữ liệu.** `T94` khói còn 1 ca lỗi; `T90` `ACTIVE`; tenant không còn đầu mối `TENANT_ADMIN`; `ops-sim` và `kpi-sim` trả `503`.

**Các bước.**

1. `POST P/tenants/T94:activate`
2. `POST P/tenants/T90:activate`
3. `POST P/tenants/T97:activate` khi thiếu đầu mối `TENANT_ADMIN`
4. Kích hoạt tenant có khói đạt khi `ops-sim` và `kpi-sim` đều `503`
5. `POST ...:activate` với `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-020`. Bước 2 `409` `ERR-20-006`. Bước 3 `422` `ERR-20-021`. Bước 4 tenant vẫn `ACTIVE`, `handoverDelivery = FAILED`, UI-20-04 hiện `ERR-20-062` kèm nút "Gửi lại" (tối đa 3 lần mỗi ngày); quan sát KPI giữ ở outbox chuyên dụng, thử lại mỗi giờ. Bước 5 `412` `ERR-20-005`.

**Thông báo hiển thị.** ERR-20-020: "Kiểm tra khói chưa đạt (1 ca lỗi). Không thể kích hoạt tenant."; ERR-20-062: "Dịch vụ Thông báo tạm thời không khả dụng. Thử lại sau."

:::

#### TC-20-036 · Thống kê thời gian khởi tạo theo giờ làm việc và khoảng thời gian <!--k:kpi12-metrics-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, UT.

**Truy vết.** FR-20-014 · API-20-024 · BR-20-041 · NFR-20-002 · ERR-20-004, ERR-20-032 · UI-20-20 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T93`: `declaredAt` thứ Sáu 15:00, `activatedAt` thứ Hai 10:00 sau; ngày làm việc 08:00 đến 17:00, thứ Bảy và Chủ nhật nghỉ (lịch do PH-18 quản, Q20-19).

**Các bước.**

1. `GET P/provisioning-metrics?tenantCode=T93`
2. `GET P/provisioning-metrics?from=2025-01-01&to=2026-11-27`
3. `GET P/provisioning-metrics?from=2024-01-01&to=2026-11-27`
4. `GET P/provisioning-metrics?from=khong-phai-ngay`

**Kết quả mong đợi.** Bước 1 `leadTimeWorkingHours` = 4 (thứ Sáu 15:00 đến 17:00 được 2 giờ, thứ Hai 08:00 đến 10:00 được 2 giờ, cuối tuần không tính), `provisionMinutes` ≤ 60, có `slowestStep`. Bước 2 trả `median`, `p95`. Bước 3 `400` `ERR-20-032`. Bước 4 `400` `ERR-20-004`. Chỉ số `dh_tenant_provision_duration_seconds` có nhãn `tenant`.

**Thông báo hiển thị.** ERR-20-032: "Khoảng thời gian tối đa là 730 ngày."

:::

### TS-20-08 · Khởi tạo bổ sung và khởi tạo cụm riêng

**Mục tiêu.** Khởi tạo bổ sung hàng loạt cho tenant đang hoạt động khi nền tảng thêm bước, phân hệ, không gián đoạn phục vụ; đăng ký, kiểm tra cụm riêng và sinh gói cấu hình (Đợt 2).

**Phủ.** FR-20-016, 017; UC-20-08; UI-20-02, 04, 20, 21; API-20-013, 033…038.

#### TC-20-037 · Xem trước và tạo đợt khởi tạo bổ sung bước S15 cho phân hệ mới <!--k:supp-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-016 · UC-20-08 · API-20-033, 034, 013 · BR-20-006 · EVT-20-07 · UI-20-04, 20 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`, `T91`, `T92` (`SUSPENDED`), `T96` `ACTIVE`; phân hệ PH-19 mới thêm vào mẫu; `waveSize = 2`.

**Các bước.**

1. `POST P/supplement-plans:preview` với `steps = [S15_MODULES]`, `modules = [PH-19]`, `waveSize = 2`, `reason`, `ticketRef`
2. `POST P/supplement-plans` cùng thân, kèm `Idempotency-Key`
3. Theo dõi `runIds[]` bằng `GET P/provisioning-runs/{runId}`
4. Gọi API dữ liệu của `T90` trong lúc chạy

**Kết quả mong đợi.** Bước 1 `200`, `candidates[]` gồm `T90`, `T91`, `T96`; `excluded[]` có `T92` lý do "tạm ngừng". Bước 2 `202`, `planId`, `runIds[]`. Bước 3 mỗi lần chạy `runKind = SUPPLEMENT`, chỉ `S15_MODULES` chạy, bước khác `SKIPPED`; tối đa 2 lần chạy cùng lúc; EVT: `module-enabled` cho PH-19 mỗi tenant. Bước 4 tenant giữ `ACTIVE`, API trả `200` suốt quá trình.

:::

#### TC-20-038 · Bổ sung khi không tenant nào cần, bước không hỗ trợ, tenant bị loại, lỗi một tenant <!--k:supp-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-016 · API-20-033, 034, 013 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-016, ERR-20-107.

**Tiền điều kiện, dữ liệu.** `U-PA1`; mọi tenant đã có PH-19; `T94` có lần chạy `RUNNING`; bản giả PH-19 trả lỗi cho `T91`.

**Các bước.**

1. `POST P/supplement-plans:preview` với phân hệ đã bật ở mọi tenant
2. `POST P/supplement-plans` với `steps = [S03_REALM]`
3. `POST P/supplement-plans` thiếu `reason`
4. `POST P/tenants/T94/provisioning-runs` với `runKind = SUPPLEMENT` khi đang có lần chạy khác
5. Chạy đợt bổ sung khi PH-19 lỗi ở `T91`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `400` `ERR-20-004` (`S01`, `S02`, `S03`, `S16`, `S17` không hỗ trợ bổ sung). Bước 3 `400` `ERR-20-004` (thiếu `reason`, `ticketRef`). Bước 4 `409` `ERR-20-016`. Bước 5 lần chạy của `T91` `FAILED` với `ERR-20-107` trên dòng bước, tenant khác không bị chặn, thử lại bằng `:retry`; bù trừ phần bổ sung giữ `T91` `ACTIVE`.

:::

#### TC-20-039 · Đăng ký, kiểm tra cụm riêng và sinh gói cấu hình (Đợt 2) <!--k:cluster-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-20-017 · UC-20-08 · API-20-035, 036, 037, 038 · BR-20-035 · UI-20-02, 04 · `PERM-20-provision`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `20.dedicated-cluster.enabled = true`; cụm giả `cl-thu-01` đủ CRD, StorageClass, dung lượng; `secretRef` là `<bi-mat-mau>`.

**Các bước.**

1. `POST P/clusters` với `clusterCode`, `name`, `apiEndpoint`, `argoCdEndpoint`, `capabilities`, `secretRef`
2. `POST P/clusters/cl-thu-01:verify`
3. `GET P/clusters?state=VERIFIED`
4. Khai báo `T95` với `isolationMode = DEDICATED_CLUSTER`, `clusterCode = cl-thu-01`, rồi `POST P/tenants/T95/dedicated-bundle`

**Kết quả mong đợi.** Bước 1 `201`, cụm `REGISTERED`; thân và kho Git không chứa giá trị bí mật, chỉ tham chiếu. Bước 2 `200`, `VERIFIED`. Bước 3 liệt kê `cl-thu-01`. Bước 4 `202`, gói `tar.zst` có liên kết tải hạn 24 giờ và `sha256`; saga trên cụm đích ghi Git ở `clusters/cl-thu-01/`.

:::

#### TC-20-040 · Cụm không đạt, mã cụm trùng, Đợt 2 chưa bật, báo cáo sai chữ ký <!--k:cluster-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-20-017 · API-20-036, 037, 038 · BR-20-035 · ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-064.

**Tiền điều kiện, dữ liệu.** `U-PA1`; cụm `cl-thieu` thiếu CRD bắt buộc; `20.dedicated-cluster.enabled = false` ở lần chạy đầu.

**Các bước.**

1. `POST P/clusters:verify` với `cl-thieu`
2. `POST P/clusters` với `clusterCode = cl-thu-01` đã có
3. Khai báo `DEDICATED_CLUSTER` khi `20.dedicated-cluster.enabled = false`
4. Tải tệp báo cáo tiến độ cụm với chữ ký sai

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-064` kèm danh sách thiếu (CRD). Bước 2 `409` `ERR-20-003`. Bước 3 `409` `ERR-20-006`. Bước 4 `400` `ERR-20-004`.

**Thông báo hiển thị.** ERR-20-064: "Cụm cl-thieu chưa đạt yêu cầu: thiếu CRD cnpg.io/Cluster."

:::

### TS-20-09 · Cấu hình nền tảng của tenant và ghi vào kho GitOps

**Mục tiêu.** Sửa cấu hình nền tảng của tenant có `If-Match`, ghi commit ký vào `dh-tenant-config`, Argo CD áp xuống, phát EVT-20-09; kho Git là trạng thái mong muốn.

**Phủ.** FR-20-019, 020; UC-20-09; UI-20-03, 17; API-20-039, 040.

#### TC-20-041 · Sửa cấu hình nền tảng, commit ký, Argo CD áp, phát sự kiện <!--k:cfg-edit-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-019, 020 · UC-20-09 · API-20-039, 040 · BR-20-010 · NFR-20-011 · EVT-20-09 · UI-20-03 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` `IN_SYNC`; `git-sim` ký commit bằng khóa dịch vụ `svc-ph20-gitops` (`<bi-mat-mau>`); `argo-sim` `Synced`, `Healthy`.

**Các bước.**

1. `GET P/tenants/T90/platform-config` lấy `ETag`
2. `PUT P/tenants/T90/platform-config` đổi `publicHost`, `apiPathPrefix = /t90`, `drRegion`, `reason`, `ticketRef`, kèm `If-Match`
3. Theo dõi `syncStatus` bằng `GET P/tenants/T90/platform-config`
4. Đọc commit mới nhất ở `tenants/T90/` trong `git-sim`

**Kết quả mong đợi.** Bước 2 `200`, `ETag` và `configVersionNo` tăng, `syncStatus = COMMITTED`. Bước 3 chuyển `APPLIED` trong ≤ 5 phút, có `commitSha`, `appliedAt`. Bước 4 thông điệp theo mẫu `ph20(T90): ... [TC-PH20-001]`, có chữ ký, tệp `tenant.yaml` đúng lược đồ, không chứa bí mật hay `DH-CANARY`. EVT: `platform.tenant.config-changed.v1` (EVT-20-09) đúng một lần sau `APPLIED`, kèm `configVersionNo`, `commitSha`. PH-03 dựng lại route.

:::

#### TC-20-042 · Sửa cấu hình: host trùng, đổi realm, đang lệch, thiếu quyền, thiếu If-Match <!--k:cfg-edit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-019 · API-20-040 · BR-20-001, 009 · ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-025, ERR-20-067, ERR-20-068, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` host `api.t90.example.vn`, `T91` host `api.t91.example.vn`; `T96` đang `DRIFTED`.

**Các bước.**

1. `PUT P/tenants/T90/platform-config` với `publicHost = api.t91.example.vn`
2. `PUT` với `apiPathPrefix = /T 90` (sai mẫu)
3. `PUT` thân có `realm = dh-t99`
4. `PUT P/tenants/T96/platform-config` khi cấu hình đang lệch
5. `PUT` thiếu `If-Match`; `PUT` với `If-Match` cũ; `PUT` thiếu `reason`
6. `PUT P/tenants/PLATFORM/platform-config`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-067`. Bước 2 `400` `ERR-20-004` (mẫu `^/[a-z0-9-]{2,30}$`). Bước 3 `422` `ERR-20-068`. Bước 4 `409` `ERR-20-025`. Bước 5 lần lượt `428` `ERR-00-428`, `412` `ERR-20-005`, `422` `ERR-20-008`. Bước 6 `403` `ERR-20-010`. Không đổi dữ liệu, không commit.

**Thông báo hiển thị.** ERR-20-067: "Tên miền hoặc tiền tố api.t91.example.vn đã được tenant khác dùng."; ERR-20-025: "Cấu hình tenant T96 đang lệch chưa xử lý. Đối chiếu trước khi sửa."

:::

#### TC-20-043 · Ghi Git lỗi, xung đột đẩy, Argo CD không áp được <!--k:cfg-git-fail-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-20-020 · API-20-040, 039 · BR-20-010 · ERR-20-024, ERR-20-109 · NFR-20-011 · UI-20-03, 17.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`; `git-sim` kịch bản từ chối đẩy; kịch bản commit xen kẽ; `argo-sim` `Degraded` quá 10 phút.

**Các bước.**

1. `PUT P/tenants/T90/platform-config` khi `git-sim` từ chối đẩy
2. Bật lại `git-sim`, quan sát outbox thử lại
3. Chèn commit khác vào `tenants/T90/` rồi lưu cấu hình
4. `argo-sim` trả `Degraded` hơn 10 phút

**Kết quả mong đợi.** Bước 1 `502` `ERR-20-024`; giao dịch nghiệp vụ đã lưu, `syncStatus = PENDING`, UI-20-17 hiện "chờ ghi Git". Bước 2 outbox thử lại và `APPLIED`, sự kiện EVT-20-09 phát một lần. Bước 3 hệ thống kéo lại, sinh lại tệp từ CSDL, thử tối đa 3 lần, kết quả đúng. Bước 4 `syncStatus = SYNC_FAILED`, `ERR-20-109` ("Argo CD không áp được cấu hình 8: kho Git từ chối kết nối.") ở nhật ký, cảnh báo PO.

**Thông báo hiển thị.** ERR-20-024: "Không ghi được cấu hình vào kho GitOps. Thử lại sau, nếu lặp lại báo vận hành nền tảng."

:::

#### TC-20-044 · Không lưu bí mật trong CSDL hay kho Git <!--k:cfg-no-secret-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, ZAP.

**Truy vết.** FR-20-020 · NFR-20-024 · BR-20-010 · API-20-040, 036 · UC-20-09.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`; chuỗi mồi `DH-CANARY-cfg-secret`; công cụ quét bí mật trên kho `dh-tenant-config`.

**Các bước.**

1. Đặt cấu hình có tham chiếu bí mật `<bi-mat-mau>` ở trường `note` và đăng ký cụm kèm `secretRef`
2. Quét kho Git, bảng `tenant_platform_config`, `tenant_config_version` bằng công cụ quét bí mật
3. Tìm chuỗi mồi trong log, vết OTel, sự kiện EVT-20-09

**Kết quả mong đợi.** Chỉ có tham chiếu đường dẫn `kv/dh/{ma}/...`, không có giá trị bí mật; quét 0 phát hiện; chuỗi mồi không xuất hiện ngoài bản ghi nhập.

:::

### TS-20-10 · Xem phiên bản, so sánh, khôi phục cấu hình và xử lý lệch

**Mục tiêu.** Xem lịch sử, so sánh, khôi phục phiên bản cấu hình bằng thay đổi mới (không xóa lịch sử); phát hiện lệch giữa Git và nơi thực thi, xử lý bằng `REAPPLY` hoặc `ACCEPT`.

**Phủ.** FR-20-021, 022; UC-20-10; UI-20-17; API-20-041…046.

#### TC-20-045 · Liệt kê, so sánh và khôi phục phiên bản cấu hình <!--k:ver-compare-restore-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-20-021 · UC-20-10 · API-20-041, 042, 043 · BR-20-010 · EVT-20-09 · UI-20-17 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; `T90` có phiên bản cấu hình 1…7; phiên bản 5 khác 7 ở `apiPathPrefix` và `drRegion`.

**Các bước.**

1. `GET P/tenants/T90/config-versions?scope=PLATFORM_CONFIG`
2. `GET P/tenants/T90/config-versions/7?compareTo=5`
3. `POST P/tenants/T90/config-versions/5:restore` với `reason`, `ticketRef`, kèm `If-Match`, `Idempotency-Key`
4. `GET P/tenants/T90/config-versions` bằng `U-PO`

**Kết quả mong đợi.** Bước 1 danh sách có số phiên bản, thời điểm, người, tệp đổi, lý do, `syncStatus`. Bước 2 khác biệt theo khóa YAML đúng hai khóa `apiPathPrefix`, `drRegion` (UI hiển thị bằng `CMP-DiffViewer` có ký hiệu thêm, đổi, xóa). Bước 3 `202`, tạo phiên bản 8 mang nội dung của 5, lịch sử 1…7 còn nguyên, `APPLIED` sau Argo CD, EVT-20-09. Bước 4 `U-PO` xem được, không có nút khôi phục.

:::

#### TC-20-046 · Khôi phục phiên bản không tương thích, không có phiên bản, thiếu lý do <!--k:ver-restore-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-021 · API-20-042, 043 · ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-026, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; phiên bản 1 của `T90` có lược đồ cũ không chuyển đổi được; `PLATFORM`.

**Các bước.**

1. `POST P/tenants/T90/config-versions/1:restore`
2. `POST P/tenants/T90/config-versions/99:restore`
3. `GET P/tenants/T90/config-versions/5?compareTo=khong-so`
4. `POST .../5:restore` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
5. `POST P/tenants/PLATFORM/config-versions/1:restore`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-026`, chỉ cho xem tệp gốc. Bước 2 `404` `ERR-20-002`. Bước 3 `400` `ERR-20-004`. Bước 4 lần lượt `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 5 `403` `ERR-20-010`. Không có commit mới.

**Thông báo hiển thị.** ERR-20-026: "Không khôi phục được phiên bản cấu hình 1: lược đồ cũ không còn tương thích."

:::

#### TC-20-047 · Phát hiện lệch, cảnh báo khóa an ninh, REAPPLY và ACCEPT <!--k:drift-detect-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-022 · UC-20-10 · API-20-044, 045, 046 · BR-20-010 · NFR-20-010 · UI-20-17 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; `T90` `IN_SYNC`; `argo-sim` `OutOfSync` ở ứng dụng `t90-gateway` (khóa thường) và `iam-sim` báo lệch chính sách realm (khóa an ninh); `clock-sim` đẩy 1 giờ.

**Các bước.**

1. Tạo hai lệch; đẩy `clock-sim` tới chu kỳ `20.drift.check-interval` (PT1H)
2. `GET P/tenants/T90/config-drifts?status=DRIFTED`
3. `POST P/tenants/T90/config-drifts/{driftId-thường}:resolve` với `action = ACCEPT`, `reason`, `ticketRef`
4. `POST .../{driftId-an-ninh}:resolve` với `action = REAPPLY`
5. `POST P/tenants/T90/config:reconcile`

**Kết quả mong đợi.** Bước 1 hai bản ghi `DRIFTED` trong ≤ 1 giờ; lệch khóa an ninh cảnh báo PO ngay qua PH-13, khóa thường gộp báo hằng ngày. Bước 3 `202`, giá trị thực ghi vào CSDL và Git, lệch `IN_SYNC`. Bước 4 `202`, Argo CD đồng bộ lại hoặc gọi API-12-083, lệch `IN_SYNC`. Bước 5 `202`, `driftStatus = IN_SYNC` sau lần đối chiếu.

:::

#### TC-20-048 · ACCEPT khóa an ninh, đối chiếu chồng, thiếu lý do, Argo CD không khả dụng <!--k:drift-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-022 · API-20-044, 045, 046 · ERR-20-002, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-004.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` có lệch khóa an ninh; `T91` đang có đối chiếu chạy; `argo-sim` ngừng.

**Các bước.**

1. `POST .../config-drifts/{driftId-an-ninh}:resolve` với `action = ACCEPT`
2. `POST P/tenants/T91/config:reconcile` khi đang đối chiếu
3. `POST .../:resolve` không có `reason`
4. `POST .../config-drifts/khong-co:resolve`; `action = XOA`
5. `argo-sim` ngừng, chạy chu kỳ đối chiếu
6. `POST P/tenants/COMMON/config:reconcile`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006` (khóa an ninh chỉ `REAPPLY`). Bước 2 `409` `ERR-20-006` (đang đối chiếu). Bước 3 `422` `ERR-20-008`. Bước 4 `404` `ERR-20-002`, rồi `400` `ERR-20-004`. Bước 5 `driftStatus = UNKNOWN`, không sinh lệch giả. Bước 6 `403` `ERR-20-010`.

:::

### TS-20-11 · Cài đặt tỉnh, xem phiên bản và lịch bảo trì của tỉnh

**Mục tiêu.** Quản trị tỉnh tự quản cài đặt trong giới hạn nền tảng, đặt cửa sổ bảo trì ưa thích và xem phiên bản, ghi chú phát hành; tỉnh tạm ngừng hoặc đã sáp nhập thì chỉ đọc.

**Phủ.** FR-20-018, 064; UC-20-11; UI-20-12; API-20-135, 136, 159, 160.

#### TC-20-049 · Quản trị tỉnh xem và sửa cài đặt tỉnh trong giới hạn <!--k:set-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-018 · UC-20-11 · API-20-135, 136 · BR-20-011 · EVT-20-09 · UI-20-12 · `PERM-20-settings`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `U-T90-VW`; `T90` `ACTIVE`; tổ chức `SO-KHCN` `ACTIVE`.

**Các bước.**

1. `GET T/settings` bằng `U-T90-TA`, lấy `ETag`
2. `PUT T/settings` với `displayName`, `itOwnerOrgCode = SO-KHCN`, `sessionIdleMinutes = 15`, `passwordMinLength = 14`, `mfaRequiredRoles = [ROLE-TENANT_ADMIN, ROLE-SECURITY_OFFICER]`, `maintenanceWindowPref` thứ Bảy 22:00 dài 4 giờ, `supportContactEmail`, kèm `If-Match`
3. `GET T/settings` bằng `U-T90-VW`

**Kết quả mong đợi.** Bước 1 có giới hạn nền tảng cho từng trường. Bước 2 `200`, `ETag` mới, ghi `settings.yaml` qua GitOps, EVT: `platform.tenant.config-changed.v1` (`changeKind` cài đặt tỉnh) để PH-12 áp chính sách phiên, mật khẩu. Bước 3 `200` phần hiển thị, không có nút sửa. KT: không cần mã phiếu (tỉnh tự quản), có người sửa, giá trị trước và sau.

:::

#### TC-20-050 · Cài đặt vượt giới hạn nền tảng, tổ chức không hợp lệ, vai trò thấp, tỉnh bị tạm ngừng hoặc đã sáp nhập <!--k:set-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-018 · API-20-136 · BR-20-011, 026 · ERR-20-001, ERR-20-002, ERR-20-005, ERR-20-023, ERR-20-115, ERR-00-403, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-TO`; `T92` `SUSPENDED` (`U-T92-TA`); `T91` `MERGED` (`U-T91-TA`); tổ chức `SO-CU` `DISSOLVED`.

**Các bước.**

1. `PUT T/settings` với `sessionIdleMinutes = 30`
2. `PUT` với `passwordMinLength = 8`; `mfaRequiredRoles` thiếu `ROLE-TENANT_ADMIN`; `maintenanceWindowPref` dài 7 giờ
3. `PUT` với `itOwnerOrgCode = SO-CU`
4. `U-T90-TO` gọi `PUT T/settings`; gọi thiếu `If-Match`; `If-Match` cũ
5. `U-T92-TA` gọi `PUT T/settings`; `U-T91-TA` gọi `PUT T/settings`

**Kết quả mong đợi.** Bước 1, 2 `422` `ERR-20-023` ("Thời gian rảnh phiên vượt giới hạn của nền tảng (15)."). Bước 3 `404` `ERR-20-002` (tổ chức không `ACTIVE`). Bước 4 `403` `ERR-00-403`; `428` `ERR-00-428`; `412` `ERR-20-005`. Bước 5 `T92` `403` `ERR-20-001`; `T91` `409` `ERR-20-115`. Không đổi gì.

**Thông báo hiển thị.** ERR-20-023: "sessionIdleMinutes vượt giới hạn của nền tảng (15 phút)."; ERR-20-115: "Tỉnh đã sáp nhập vào T90. Dữ liệu chỉ còn để tra cứu."

:::

#### TC-20-051 · Xem phiên bản, ghi chú, lịch bảo trì và đặt cửa sổ bảo trì ưa thích <!--k:release-info-window-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-20-064, 018 · UC-20-11 · API-20-159, 160 · BR-20-033 · UI-20-12 · `PERM-20-settings`, `PERM-20-org-read`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-TO`, `U-T90-AU`; `T90` chạy 2.3.1; kế hoạch nâng cấp 2.4.0 đã `SCHEDULED` cho `T90`; ghi chú 3 bản gần nhất.

**Các bước.**

1. `GET T/release-info` bằng `U-T90-TO`, `U-T90-AU`
2. `PUT T/maintenance-window` với `dayOfWeek = SAT`, `startTime = 22:00`, `durationHours = 4`, `timezone = Asia/Ho_Chi_Minh`, kèm `If-Match`
3. `GET T/release-info` lại

**Kết quả mong đợi.** Bước 1 `200` có phiên bản đang chạy, ghi chú ba bản gần nhất, lịch nâng cấp sắp tới, cửa sổ hiện hành; kênh có chữ "Chưa có lịch bảo trì" khi không có kế hoạch (tenant khác). Bước 2 `200`; cửa sổ mới áp cho kế hoạch lập sau, không đổi kế hoạch đã `SCHEDULED`. Bước 3 phản ánh cửa sổ mới. TO, AU không có nút đặt cửa sổ.

:::

#### TC-20-052 · Cửa sổ bảo trì ngoài giới hạn, trùng giờ cao điểm, tỉnh tạm ngừng <!--k:window-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-064, 018 · API-20-160 · BR-20-033 · ERR-20-001, ERR-20-059, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `U-T92-TA` (`SUSPENDED`).

**Các bước.**

1. `PUT T/maintenance-window` với `durationHours = 7` (vượt 6 giờ), rồi `durationHours = 1` (dưới 2 giờ)
2. `PUT` với `dayOfWeek = MON`, `startTime = 09:00` (giờ cao điểm 7:00 đến 17:00 ngày làm việc)
3. `PUT` với `timezone = UTC+99`
4. `U-T92-TA` gọi `PUT T/maintenance-window`
5. `PUT` thiếu `If-Match`

**Kết quả mong đợi.** Bước 1, 2, 3 `422` `ERR-20-059`. Bước 4 `403` `ERR-20-001`. Bước 5 `428` `ERR-00-428`. Cửa sổ cũ giữ nguyên.

**Thông báo hiển thị.** ERR-20-059: "Cửa sổ bảo trì không hợp lệ: trùng giờ cao điểm 7:00 đến 17:00 ngày làm việc."

:::

### TS-20-12 · Chính sách tiếp nhận và nhật ký truy cập liên tenant

**Mục tiêu.** Tỉnh đặt chính sách tiếp nhận truy cập liên tenant (đọc, ghi, chấp thuận trước, thời hạn tối đa), SO và AU xem nhật ký; PH-12 đọc chính sách khi cấp quyền.

**Phủ.** FR-20-023, 024; UC-20-12; UI-20-22; API-20-137, 138, 139, 165.

#### TC-20-053 · Quản trị tỉnh đặt chính sách tiếp nhận; SO, AU xem; PH-12 đọc <!--k:xt-policy-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-023 · UC-20-12 · API-20-137, 138, 165 · BR-20-012 · EVT-20-09 · UI-20-22 · `PERM-20-settings`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-SO`, `U-T90-AU`; `S-PH12`; `20.cross-tenant.max-hours` = 4.

**Các bước.**

1. `GET T/cross-tenant-policy` bằng `U-T90-TA`, lấy `ETag`
2. `PUT T/cross-tenant-policy` với `allowRead = true`, `allowWrite = false`, `requirePriorApproval = true`, `maxHours = 2`, `notifyContacts` (hai đầu mối hợp lệ), `blockedReasons = [MAINTENANCE]`, kèm `If-Match`
3. `GET T/cross-tenant-policy` bằng `U-T90-SO` và `U-T90-AU`
4. `S-PH12` gọi `GET I/tenants/T90/cross-tenant-policy`

**Kết quả mong đợi.** Bước 2 `200`, phiên bản chính sách mới; EVT: `platform.tenant.config-changed.v1` với `changeKind = CROSS_TENANT_POLICY` để PH-12 vô hiệu đệm. Bước 3 SO, AU đọc được, không sửa được. Bước 4 `200` trả đúng giá trị mới. KT có người sửa.

:::

#### TC-20-054 · Chính sách vượt trần, người nhận không hợp lệ, vai trò không đủ, tỉnh tạm ngừng <!--k:xt-policy-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-023 · API-20-138 · BR-20-012 · ERR-20-001, ERR-20-004, ERR-20-005, ERR-20-027, ERR-00-403, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-SO`, `U-T90-VW`, `U-T92-TA` (`SUSPENDED`); người dùng `U-T91-TA` thuộc tenant khác.

**Các bước.**

1. `PUT T/cross-tenant-policy` với `maxHours = 6`
2. `PUT` với `notifyContacts` chứa địa chỉ của `U-T91-TA`
3. `U-T90-SO` và `U-T90-VW` gọi `PUT`
4. `PUT` thiếu `If-Match`; `If-Match` cũ
5. `U-T92-TA` gọi `PUT`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-027`. Bước 2 `400` `ERR-20-004` (người nhận không phải đầu mối hay người dùng `ACTIVE` của tỉnh). Bước 3 `403` `ERR-00-403`. Bước 4 `428` `ERR-00-428`; `412` `ERR-20-005`. Bước 5 `403` `ERR-20-001`. Chính sách cũ giữ nguyên.

**Thông báo hiển thị.** ERR-20-027: "Thời hạn truy cập liên tenant tối đa là 4 giờ."

:::

#### TC-20-055 · Xem nhật ký truy cập liên tenant và lọc <!--k:xt-log-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-20-024 · UC-20-12 · API-20-139 · UI-20-22 · `PERM-20-settings`.

**Tiền điều kiện, dữ liệu.** `U-T90-SO`, `U-T90-AU`, `U-T90-TA`; `obs-sim` có ba phiên liên tenant vào `T90` (hai đọc, một ghi) và một phiên vào `T91`.

**Các bước.**

1. `GET T/cross-tenant-access-log?from=2026-11-01&to=2026-11-27`
2. `GET T/cross-tenant-access-log?access=WRITE&reasonType=INCIDENT`
3. `GET T/cross-tenant-access-log?actor=U-PA1&ticketRef=TC-PH20-001`
4. Mở một phiên để xem chi tiết thao tác

**Kết quả mong đợi.** Bước 1 ba phiên của `T90`, không có phiên của `T91` (truy vấn theo tenant ngữ cảnh). Mỗi phiên có người (tenant nhà `PLATFORM`), lý do, phiếu, người duyệt, bắt đầu, kết thúc, số thao tác đọc, ghi. Bước 2 chỉ phiên có thao tác ghi. Bước 3 lọc đúng. Bước 4 chi tiết đường dẫn API, thời điểm, kết quả. SO, AU, TA cùng đọc được.

:::

#### TC-20-056 · Khoảng thời gian quá dài, tham số sai, PH-13 không khả dụng, vai trò không đủ <!--k:xt-log-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-024 · API-20-139 · ERR-20-004, ERR-20-032, ERR-20-062, ERR-00-403.

**Tiền điều kiện, dữ liệu.** `U-T90-SO`, `U-T90-VW`; `obs-sim` ngừng ở bước 3.

**Các bước.**

1. `GET T/cross-tenant-access-log?from=2025-01-01&to=2026-11-27`
2. `GET T/cross-tenant-access-log?access=DELETE`
3. `obs-sim` ngừng, `GET T/cross-tenant-access-log`
4. `U-T90-VW` gọi `GET T/cross-tenant-access-log`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-032`. Bước 2 `400` `ERR-20-004`. Bước 3 `503` `ERR-20-062`. Bước 4 `403` `ERR-00-403`.

**Thông báo hiển thị.** ERR-20-032: "Khoảng thời gian tối đa là 366 ngày."; ERR-20-062: "Dịch vụ Nhật ký kiểm toán tạm thời không khả dụng. Thử lại sau."

:::

### TS-20-13 · Chuyển chế độ cách ly của tenant

**Mục tiêu.** Đề nghị đổi chế độ cách ly một bậc mỗi lần, bốn mắt, thực hiện trong cửa sổ bảo trì, kiểm đếm khớp rồi mới đổi định tuyến (Đợt 2).

**Phủ.** FR-20-025; UC-20-13; UI-20-03; API-20-047, 076, 077, 079.

#### TC-20-057 · Đổi T95 từ SHARED lên DEDICATED_DB có duyệt bốn mắt <!--k:iso-change-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-025 · UC-20-13 · API-20-047, 075, 076, 079 · BR-20-008, 040 · EVT-20-04, 09 · UI-20-03 · `PERM-20-lifecycle`, `PERM-20-approve`.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`, `U-PA2`; `T95` `ACTIVE` `SHARED`, `DATABASE_GB` 40; công cụ chuyển dữ liệu của PH-18 giả (`ops-sim`); cửa sổ bảo trì thứ Bảy 22:00.

**Các bước.**

1. `U-PA1` `POST P/tenants/T95/isolation-changes` với `targetMode = DEDICATED_DB`, `scheduledAt` trong cửa sổ, `decisionDocNo`, `reason`, `ticketRef`
2. `U-PA1` gửi duyệt `POST P/lifecycle-requests/{requestId}:submit`
3. `U-PA2` `POST .../{requestId}:approve` với `comment`
4. Đẩy `clock-sim` tới giờ hẹn; theo dõi lần chạy `ISOLATION_CHANGE`

**Kết quả mong đợi.** Bước 1 `201`, `requestType = ISOLATION_CHANGE`, có ước thời gian và dung lượng. Bước 2 `PENDING_APPROVAL`. Bước 3 `200`, `APPROVED`. Bước 4 tới giờ hẹn tạo lần chạy `ISOLATION_CHANGE`: `S07_DATABASE` tạo cụm CloudNativePG, sao dữ liệu theo `tenant_id`, kiểm đếm từng bảng khớp, đổi `isolationMode = DEDICATED_DB`, đề nghị `DONE`; dữ liệu cũ giữ ở cụm chung `20.export.retention-days` ngày rồi xóa. EVT: `status-changed` và `config-changed`. Tenant phục vụ bình thường trong cửa sổ.

:::

#### TC-20-058 · Đổi cách ly: bỏ bậc, ngoài cửa sổ, kiểm đếm lệch, trạng thái sai <!--k:iso-change-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-025 · API-20-047, 079 · BR-20-040 · ERR-20-004, ERR-20-006, ERR-20-028, ERR-20-059, ERR-20-113.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T95` `SHARED`; `T90` có lần chạy đổi cách ly `RUNNING`; bản giả báo kiểm đếm lệch ở bảng `organization`.

**Các bước.**

1. `POST P/tenants/T95/isolation-changes` với `targetMode = DEDICATED_CLUSTER` (bỏ bậc)
2. `POST` với `scheduledAt` thứ Hai 09:00 (ngoài cửa sổ bảo trì)
3. `POST` thiếu `decisionDocNo`
4. `POST P/tenants/T90/isolation-changes` khi đang có lần chạy khác
5. Chạy đổi cách ly khi bản giả kiểm đếm lệch

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-028`. Bước 2 `422` `ERR-20-059`. Bước 3 `400` `ERR-20-004`. Bước 4 `409` `ERR-20-006`. Bước 5 lần chạy `FAILED` với `ERR-20-113` ("Kiểm đếm organization lệch: nguồn 40, đích 39."), định tuyến giữ cụm cũ, dữ liệu không mất.

**Thông báo hiển thị.** ERR-20-028: "Không chuyển được từ chế độ SHARED sang DEDICATED_CLUSTER: chỉ chuyển từng bậc."

:::

### TS-20-14 · Đặt, đổi hạn mức hợp đồng và ghi đè tạm thời

**Mục tiêu.** Đặt hạn mức hợp đồng trong trần nền tảng, hạ hạn mức dưới mức đang dùng phải bốn mắt, ghi đè tạm thời có thời hạn tự hết; hạn mức hiệu lực đẩy xuống nơi thực thi, PH-20 không tự thực thi.

**Phủ.** FR-20-026, 027, 032; UC-20-14; UI-20-05, 08; API-20-048…055, 164.

#### TC-20-059 · Đặt hạn mức hợp đồng và đọc hạn mức hiệu lực <!--k:quota-set-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-026 · UC-20-14 · API-20-048, 049, 164 · BR-20-013 · EVT-20-05 · UI-20-05 · `PERM-20-quota`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T96` có hợp đồng `ACTIVE`, hạn mức theo F-QUOTA; `S-PH03`.

**Các bước.**

1. `GET P/tenants/T96/quotas`
2. `PUT P/tenants/T96/quotas` với `items` = `API_RPS` 600, `USERS` 2.500, `contractId`, `reason`, `ticketRef`, kèm `If-Match`
3. `S-PH03` gọi `GET I/tenants/T96/enforcement`

**Kết quả mong đợi.** Bước 1 có `contractValue`, `platformCeiling`, `overrideValue`, `effectiveValue`, `lastUsage`, `source`, `pushStatus` cho 12 tài nguyên. Bước 2 `200`, `effectiveValue` = giá trị mới (tăng trong trần); `pushStatus` `PENDING` rồi `PUSHED`. EVT: `platform.tenant.quota-changed.v1`. Bước 3 `quotas[]` có `API_RPS` 600 để PH-03 áp ở APISIX. KT có `reason`, `ticketRef`.

:::

#### TC-20-060 · Hạn mức ngoài miền, vượt trần, hạ dưới mức đang dùng, hợp đồng không hợp lệ <!--k:quota-set-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-026, 027 · API-20-049 · BR-20-013, 014 · ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-022, ERR-20-029, ERR-20-030, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T96` `OBJECT_STORAGE_GB` hợp đồng 500, đang dùng 300; hợp đồng `HD-HET-HAN` đã `EXPIRED`.

**Các bước.**

1. `PUT P/tenants/T96/quotas` với `API_RPS = 0`
2. `PUT` với `API_RPS` vượt trần nền tảng
3. `PUT` với `OBJECT_STORAGE_GB = 250` (thấp hơn mức dùng 300)
4. `PUT` với `contractId` của hợp đồng đã hết hạn
5. `PUT` thiếu `If-Match`; `If-Match` cũ; thiếu `ticketRef`
6. `PUT P/tenants/COMMON/quotas`

**Kết quả mong đợi.** Bước 1, 2 `422` `ERR-20-029`. Bước 3 `422` `ERR-20-030`, nêu phải qua đề nghị có duyệt. Bước 4 `422` `ERR-20-022`. Bước 5 lần lượt `428` `ERR-00-428`, `412` `ERR-20-005`, `422` `ERR-20-008`. Bước 6 `403` `ERR-20-010`. Không đổi hạn mức.

**Thông báo hiển thị.** ERR-20-030: "Hạ hạn mức OBJECT_STORAGE_GB xuống 250 thấp hơn mức đang dùng 300 cần được duyệt."; ERR-20-029: "Hạn mức API_RPS phải trong khoảng 1 đến 5000 request/giây."

:::

#### TC-20-061 · Đề nghị hạ hạn mức dưới mức đang dùng, duyệt bốn mắt, đẩy xuống nơi thực thi <!--k:quota-decrease-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-027 · UC-20-14 · API-20-050, 051, 052, 053, 164 · BR-20-008, 014 · EVT-20-05 · UI-20-05, 08 · `PERM-20-quota`, `PERM-20-approve`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; `T96`; `gw-sim` xác nhận qua `EVT-03-11`; `ops-sim` nhận việc duyệt.

**Các bước.**

1. `U-PA1` `POST P/tenants/T96/quota-change-requests` với `items` = `OBJECT_STORAGE_GB` 250, `effectiveAt`, `reason`, `ticketRef`
2. `U-PA2` `POST P/quota-change-requests/{requestId}:approve` với `comment`
3. `GET P/tenants/T96/quota-change-requests?status=DONE`
4. Đọc `GET P/tenants/T96/quotas` và dung lượng đang dùng

**Kết quả mong đợi.** Bước 1 `201`, `PENDING_APPROVAL`. Bước 2 `200`, `APPROVED` rồi `DONE` sau khi `EVT-03-11` xác nhận áp. Bước 3 có đề nghị. Bước 4 `effectiveValue` = 250 nhưng tài nguyên đã cấp (300 GB) không bị cắt, chỉ chặn cấp mới (BR-20-014). EVT: `quota-changed` một lần. Từ chối: `U-PA2` `:reject` kèm `comment` thì `REJECTED`, hạn mức giữ 500.

:::

#### TC-20-062 · Tự duyệt đề nghị hạn mức, duyệt hai lần, từ chối thiếu ý kiến <!--k:quota-decrease-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-027 · API-20-050, 052, 053 · BR-20-008 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-029, ERR-00-403.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`, `U-PA3`; `U-T90-TA`; đề nghị `PENDING_APPROVAL` do `U-PA1` lập; đề nghị đã `APPROVED`.

**Các bước.**

1. `U-PA1` `:approve` đề nghị của chính mình
2. `U-PA2` `:approve` đề nghị đã `APPROVED`
3. `U-PA2` `:reject` thiếu `comment`
4. `U-T90-TA` gọi `:approve`
5. `U-PA2` `:approve` với `If-Match` cũ
6. Đề nghị có giá trị mới `API_RPS = 9999` rồi duyệt

**Kết quả mong đợi.** Bước 1 `403` `ERR-20-007`. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-00-403`. Bước 5 `412` `ERR-20-005`. Bước 6 `422` `ERR-20-029`. Đề nghị không đổi trạng thái khi bị từ chối.

**Thông báo hiển thị.** ERR-20-007: "Anh/chị là người lập đề nghị nên không được duyệt đề nghị. Cần một quản trị nền tảng khác duyệt."

:::

#### TC-20-063 · Ghi đè hạn mức tạm thời, thu hồi và tự hết hạn <!--k:override-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, UT.

**Truy vết.** FR-20-032 · UC-20-14 · API-20-054, 055, 048 · BR-20-013, 015 · EVT-20-05 · UI-20-05 · `PERM-20-quota`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T96` `USERS` hợp đồng 2.000; `20.quota.override-max-days` = 30; `clock-sim`.

**Các bước.**

1. `POST P/tenants/T96/quota-overrides` với `resource = USERS`, `value = 2500`, `validFrom`, `validTo` sau 10 ngày, `reason`, `ticketRef`
2. `GET P/tenants/T96/quotas`
3. `clock-sim` đẩy 11 ngày; `GET P/tenants/T96/quotas`
4. Ghi đè thứ hai rồi `POST .../quota-overrides/{overrideId}:revoke` với `reason`

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `effectiveValue` `USERS` = 2.500 (lớn hơn của hợp đồng và ghi đè còn hạn), `source = OVERRIDE`. Bước 3 trả về 2.000, ghi đè `EXPIRED`. Bước 4 `200`, thu hồi trước hạn, hạn mức trở lại hợp đồng. EVT: `quota-changed` khi tạo, khi thu hồi, khi hết hạn.

:::

#### TC-20-064 · Ghi đè quá số ngày, vượt trần, thu hồi sai, thiếu lý do <!--k:override-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-032 · API-20-054, 055 · BR-20-015 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-029, ERR-20-031.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T96`; ghi đè đã `EXPIRED`; tenant `PLATFORM`.

**Các bước.**

1. Ghi đè với `validTo` sau 45 ngày
2. Ghi đè `value` vượt trần nền tảng
3. Ghi đè thiếu `reason`
4. `:revoke` ghi đè đã `EXPIRED`
5. Ghi đè `resource = KHONG_CO`; ghi đè `validTo` trước `validFrom`
6. Ghi đè cho `PLATFORM`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-031`. Bước 2 `422` `ERR-20-029`. Bước 3 `422` `ERR-20-008`. Bước 4 `409` `ERR-20-006`. Bước 5 `400` `ERR-20-004`. Bước 6 `403` `ERR-20-010`.

**Thông báo hiển thị.** ERR-20-031: "Ghi đè hạn mức tối đa 30 ngày."

:::

#### TC-20-065 · Nơi thực thi không xác nhận áp hạn mức sau 15 phút <!--k:quota-push-confirm-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-20-027 · UC-20-14 · API-20-164, 048 · BR-20-013 · EVT-20-05 · UI-20-05.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T96`; `gw-sim` không phát `EVT-03-11`; `clock-sim`.

**Các bước.**

1. Đổi hạn mức `API_RPS` của `T96` tăng trong trần
2. Đẩy `clock-sim` 15 phút
3. `GET P/tenants/T96/quotas`

**Kết quả mong đợi.** `pushStatus = PENDING` rồi cảnh báo ở UI-20-05, PH-20 không tự thử lại, không tự hoàn tác (Q20-49); khi `gw-sim` phát lại xác nhận thì `PUSHED`.

:::

### TS-20-15 · Thu thập sử dụng tài nguyên và cảnh báo ngưỡng hạn mức

**Mục tiêu.** Bộ lập lịch thu số đo hằng giờ cho từng tenant, lũy đẳng; cảnh báo 80 % và 100 % khử lặp, đặt lại khi dùng xuống dưới 75 % liên tục 24 giờ.

**Phủ.** FR-20-028, 029; UC-20-15; UI-20-06, 13; API-20-058, 059.

#### TC-20-066 · Thu sử dụng theo giờ, lũy đẳng, đọc bù <!--k:usage-collect-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, UT.

**Truy vết.** FR-20-028 · UC-20-15 · NFR-20-008 · API-20-056, 057 · BR-20-016 · `PERM-20-read` · `20.usage.retention-months`.

**Tiền điều kiện, dữ liệu.** `T96`, `T90`; `obs-sim` (Mimir giả) trả số đo theo F-USAGE; `20.usage.snapshot-interval` = PT1H; `clock-sim`.

**Các bước.**

1. Đẩy `clock-sim` một giờ, chạy bộ lập lịch
2. Chạy lại bộ lập lịch cùng giờ lần hai
3. Cài `obs-sim` thiếu số đo của `OBJECT_STORAGE_GB` một giờ, giờ sau trả lại
4. `GET P/tenants/T96/usage?resource=API_RPS&granularity=HOUR`

**Kết quả mong đợi.** Bước 1 mỗi tài nguyên một dòng `usage_snapshot` có hạn mức hiệu lực tại giờ đó và phần trăm, trễ ≤ 15 phút (NFR-20-008). Bước 2 không nhân bản nhờ khóa duy nhất (`tenant_id`, `resource`, `hour_start`). Bước 3 giờ thiếu có `quality = MISSING`, giờ sau đọc bù lại tối đa 24 giờ trước. Bước 4 trả đúng chuỗi theo giờ.

:::

#### TC-20-067 · Nguồn số đo lỗi, thiếu quá 3 giờ, tenant đã chấm dứt <!--k:usage-missing-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-028 · NFR-20-008 · ERR-20-006, ERR-20-062, ERR-20-110 · UC-20-15 · UI-20-06.

**Tiền điều kiện, dữ liệu.** `obs-sim` ngừng; `T88` `DECOMMISSIONED`; `U-PO`.

**Các bước.**

1. Chạy bộ lập lịch khi Mimir không khả dụng
2. Giữ ngừng quá 3 giờ liên tiếp (`clock-sim`)
3. Yêu cầu thu bổ sung cho `T88`

**Kết quả mong đợi.** Bước 1 cả lượt `MISSING` với `ERR-20-062` ở nhật ký, không phát cảnh báo hạn mức giả. Bước 2 `ERR-20-110` ("Thiếu số liệu sử dụng API_RPS của T96 từ 09:00."), cảnh báo `U-PO` ở UI-20-06. Bước 3 `409` `ERR-20-006`.

**Thông báo hiển thị.** ERR-20-110: "Thiếu số liệu sử dụng API_RPS của T96 từ 09:00."

:::

#### TC-20-068 · Cảnh báo 80 % và 100 %, khử lặp, đặt lại <!--k:alert-threshold-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, UT.

**Truy vết.** FR-20-029 · UC-20-15 · BR-20-016 · NFR-20-009 · EVT-20-06 · UI-20-06 · `PERM-20-quota`.

**Tiền điều kiện, dữ liệu.** `T96` theo F-QUOTA (`API_RPS` 400/500, `ACTIVE_FLOWS` 1.000/1.000); `20.quota.warn-percent` = 80; `20.quota.alert-reset-percent` = 75; `20.usage.probe-interval` = PT5M; `ops-sim`.

**Các bước.**

1. Thu số đo giờ đầu
2. Thu số đo `API_RPS` = 410 giờ sau
3. Đưa `API_RPS` xuống 370 và giữ 24 giờ liên tục
4. `GET P/quota-alerts?tenantCode=T96`

**Kết quả mong đợi.** Bước 1 `API_RPS` 80 % tạo cảnh báo `WARN_80` `OPEN` và `ACTIVE_FLOWS` 100 % tạo `LIMIT_100`; EVT: `platform.tenant.quota-threshold-reached.v1` mỗi cảnh báo một lần, ≤ 5 phút sau thu số đo; thông báo qua PH-18 tới PO và đầu mối `TECHNICAL`, `TENANT_ADMIN`. Bước 2 cập nhật `used` và `percent` của cảnh báo đang mở, không gửi lặp. Bước 3 sau 24 giờ dưới 75 % (370/500 = 74 %) cảnh báo `RESOLVED`. Bước 4 liệt kê đúng.

:::

#### TC-20-069 · Xác nhận cảnh báo hợp lệ và không hợp lệ <!--k:alert-ack-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-029 · API-20-058, 059 · ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-009 · UI-20-06 · `PERM-20-quota`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; cảnh báo `OPEN` của `T96`; cảnh báo `RESOLVED`.

**Các bước.**

1. `POST P/quota-alerts/{alertId}:acknowledge` với `comment`
2. Xác nhận lại cùng cảnh báo với khóa chống lặp khác
3. `POST` cảnh báo `RESOLVED`
4. `POST` mã cảnh báo không có
5. `U-PO` gọi `POST ...:acknowledge`
6. `GET P/quota-alerts?alertLevel=KHONG`
7. Dùng lại `Idempotency-Key` của bước 1 cho một cảnh báo khác

**Kết quả mong đợi.** Bước 1 `200`, `acknowledgedBy`, `acknowledgedAt`. Bước 2 `409` `ERR-20-006`. Bước 3 `409` `ERR-20-006`. Bước 4 `404` `ERR-20-002`. Bước 5 `403` `ERR-00-403` (PO không có `PERM-20-quota`). Bước 6 `400` `ERR-20-004`. Bước 7 `409` `ERR-20-009`.

:::

### TS-20-16 · Xem sử dụng tài nguyên và lập báo cáo sử dụng

**Mục tiêu.** Quản trị nền tảng xem sử dụng toàn nền tảng, quản trị tỉnh xem sử dụng và hạn mức của tỉnh mình; lập báo cáo theo kỳ, xuất XLSX, CSV, PDF.

**Phủ.** FR-20-030, 031; UC-20-16; UI-20-06, 13; API-20-056, 057, 060, 061, 062, 140, 141.

#### TC-20-070 · Xem sử dụng toàn nền tảng, một tenant, và của tỉnh <!--k:usage-view-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-030 · UC-20-16 · API-20-056, 057, 140, 141 · NFR-20-006 · UI-20-06, 13 · `PERM-20-read`, `PERM-20-usage-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`, `U-T96-TA`, `U-T90-TO`, `U-T90-AU`; F-USAGE (30 ngày `T96`).

**Các bước.**

1. `GET P/usage?from=2026-11-01&to=2026-11-27&granularity=DAY&resource=API_RPS&sort=-percent`
2. `GET P/tenants/T96/usage?from=2026-11-20&to=2026-11-27&granularity=HOUR`
3. `U-T96-TA` gọi `GET T/usage` và `GET T/quotas`
4. `U-T90-TO`, `U-T90-AU` gọi `GET T/usage`
5. Mở `/nen-tang/su-dung` và `/quan-tri/cai-dat-tinh/su-dung`

**Kết quả mong đợi.** Bước 1 xếp tenant theo phần trăm giảm dần, `T96` ở đầu với 80 %. Bước 2 chuỗi theo giờ đủ. Bước 3 chỉ số liệu và hạn mức hiệu lực của `T96`, kèm cảnh báo mở. Bước 4 `200`. Bước 5 UI-20-06 và UI-20-13 hiện thẻ chỉ số, biểu đồ có bảng số thay thế, p95 danh sách ≤ 1,5 giây (NFR-20-006).

:::

#### TC-20-071 · Khoảng thời gian quá dài, tham số sai, mã tenant không có, vai trò không đủ <!--k:usage-view-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-030 · API-20-056, 057, 140, 141 · ERR-20-002, ERR-20-004, ERR-20-032, ERR-00-403.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`, `U-T90-VW`.

**Các bước.**

1. `GET P/usage?from=2020-01-01&to=2026-11-27`
2. `GET P/usage?granularity=NAM&resource=KHONG_CO`
3. `GET P/tenants/T89/usage`
4. `U-T90-VW` gọi `GET T/usage`
5. `U-T90-TA` gọi `GET T/usage?tenantCode=T91`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-032`. Bước 2 `400` `ERR-20-004`. Bước 3 `404` `ERR-20-002`. Bước 4 `403` `ERR-00-403`. Bước 5 `200` nhưng chỉ số liệu `T90`, bỏ qua tham số `tenantCode` (không rò rỉ `T91`).

**Thông báo hiển thị.** ERR-20-032: "Khoảng thời gian tối đa là 730 ngày."

:::

#### TC-20-072 · Lập báo cáo sử dụng theo kỳ, tải tệp <!--k:usage-report-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-031 · API-20-060, 061, 062 · UI-20-06 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-USAGE; kỳ tháng 10/2026.

**Các bước.**

1. `POST P/usage-reports` với `scope = ALL_TENANTS`, `period = 2026-10`, `format = XLSX`, kèm `Idempotency-Key`
2. `GET P/usage-reports?scope=ALL_TENANTS&status=READY`
3. `GET P/usage-reports/{reportId}/file`
4. Lập tiếp `CSV` và `PDF` cho `scope = T96`

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 báo cáo `READY`. Bước 3 tải được tệp XLSX có một dòng mỗi tenant và tài nguyên, tổng khớp tổng ảnh chụp giờ của F-USAGE. Bước 4 hai tệp CSV, PDF đúng nội dung. Tệp không có dữ liệu cá nhân.

:::

#### TC-20-073 · Báo cáo không lập được, định dạng sai, báo cáo không có <!--k:usage-report-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-031 · API-20-060, 062 · ERR-20-002, ERR-20-004, ERR-20-009, ERR-20-032, ERR-20-066.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kỳ `2026-12` chưa có số liệu; `T89` không tồn tại.

**Các bước.**

1. `POST P/usage-reports` với `period = 2026-12`
2. `POST P/usage-reports` với `format = DOCX`
3. `POST P/usage-reports` với `scope = T89`
4. `GET P/usage-reports/khong-co/file`
5. `POST` lặp cùng khóa chống lặp khác thân
6. `POST` với `period` dài hơn 24 tháng

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-066` ("Không lập được báo cáo sử dụng: không có số liệu."). Bước 2 `400` `ERR-20-004`. Bước 3 `404` `ERR-20-002`. Bước 4 `404` `ERR-20-002`. Bước 5 `409` `ERR-20-009`. Bước 6 `400` `ERR-20-032`.

**Thông báo hiển thị.** ERR-20-066: "Không lập được báo cáo sử dụng: kỳ 2026-12 chưa có số liệu."

:::

### TS-20-17 · Danh mục phân hệ, bật phân hệ và trạng thái cho menu

**Mục tiêu.** Xem danh mục phân hệ và ma trận phụ thuộc; bật phân hệ cho tenant (bất đồng bộ, chờ báo); cung cấp trạng thái phân hệ cho menu và giao diện.

**Phủ.** FR-20-033, 034, 037; UC-20-17; UI-20-07; API-20-063, 064, 065, 142, 163, 166.

#### TC-20-074 · Xem danh mục phân hệ, ma trận phụ thuộc và phân hệ của tenant <!--k:mod-catalog-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-033 · UC-20-17 · API-20-063, 064 · BR-20-017 · UI-20-07 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` có PH-16, PH-19 bật, PH-17 tắt.

**Các bước.**

1. `GET P/modules?wave=1&core=true`
2. `GET P/modules?q=PH-16`
3. `GET P/tenants/T90/modules`

**Kết quả mong đợi.** Bước 1 có phân hệ lõi PH-03, PH-10, PH-12, PH-13, PH-18, PH-20 với `core = true`. Bước 2 có `PH-16`, kèm phụ thuộc. Bước 3 mỗi phân hệ có `state` (`ENABLED`, `DISABLED`), `core`, `runId`, `lastReportAt`. Ma trận phụ thuộc hiển thị ở UI-20-07.

:::

#### TC-20-075 · Bật phân hệ PH-17 cho T90 và nhận báo xong <!--k:mod-enable-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-034 · UC-20-17 · API-20-065, 166, 064 · BR-20-017 · EVT-20-07 · UI-20-07 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`; PH-17 `DISABLED`; phụ thuộc của PH-17 đã bật; `S-PH17` (`mod-sim`) có scope báo tiến độ.

**Các bước.**

1. `POST P/tenants/T90/modules/PH-17:enable` với `reason`, `ticketRef`, `Idempotency-Key`
2. `GET P/tenants/T90/modules`
3. `mod-sim` báo `SUCCEEDED` qua `POST I/provisioning-runs/{runId}/steps/S15_MODULES:report`
4. `GET T/context` bằng `U-T90-VW`

**Kết quả mong đợi.** Bước 1 `202`, `ModuleState = ENABLING`; EVT: `platform.tenant.module-enabled.v1` một lần. Bước 3 `ENABLED`. Bước 4 `modules` có PH-17 `ENABLED`, menu hiện mục PH-17. KT có `reason`, `ticketRef`.

:::

#### TC-20-076 · Bật thiếu phụ thuộc, đã bật, phân hệ chưa sẵn sàng, tenant đặc biệt <!--k:mod-enable-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-034 · API-20-065 · BR-20-017 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-033, ERR-20-055.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T91` chưa bật PH-06; phân hệ PH-14 trạng thái `PLANNED` ở danh mục; `T90` có PH-16 `ENABLED`.

**Các bước.**

1. `POST P/tenants/T91/modules/PH-08:enable` khi PH-06 (phụ thuộc) chưa bật
2. `POST P/tenants/T90/modules/PH-16:enable`
3. `POST P/tenants/T90/modules/PH-14:enable`
4. `POST P/tenants/T90/modules/PH-99:enable`
5. `POST .../PH-17:enable` thiếu `reason`
6. `POST P/tenants/PLATFORM/modules/PH-17:enable`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-033`. Bước 2 `409` `ERR-20-006`. Bước 3 `422` `ERR-20-055` (theo OpenAPI liệt kê `ERR-20-055` cho API-20-065; FRS chưa nêu, xem đề nghị ĐN-TC-04). Bước 4 `400` `ERR-20-004`. Bước 5 `422` `ERR-20-008`. Bước 6 `403` `ERR-20-010`.

**Thông báo hiển thị.** ERR-20-033: "Phân hệ PH-08 cần PH-06 được bật trước."

:::

#### TC-20-077 · Phân hệ báo lỗi hoặc quá hạn khi bật rồi thử lại <!--k:mod-enable-fail-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-034 · API-20-065, 166 · UC-20-17 · ERR-20-106, ERR-20-107 · UI-20-07.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `mod-sim` cài `REPORT_FAILED` rồi `NO_REPORT`; `clock-sim`.

**Các bước.**

1. Bật PH-17 cho `T91`, `mod-sim` báo `FAILED` kèm `errorCode`
2. Bật lại PH-17, `mod-sim` không báo; đẩy `clock-sim` quá `20.provision.step-timeout-minutes` (15 phút)
3. Bật lại PH-17, `mod-sim` báo `SUCCEEDED`

**Kết quả mong đợi.** Bước 1 `ModuleState = FAILED`, `ERR-20-107` ("Bước S15_MODULES lỗi tại PH-17: khởi động phân hệ thất bại."). Bước 2 `FAILED` với `ERR-20-106` ("Bước S15_MODULES chưa nhận báo cáo từ PH-17 sau 15 phút."). Bước 3 `ENABLED`. Phân hệ khác không bị ảnh hưởng.

:::

#### TC-20-078 · Trạng thái tenant, phân hệ và dải cảnh báo cho menu <!--k:ctx-view-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-037, 066 · UC-20-17 · API-20-142, 163 · UI-20-07 · NFR-20-004 · BR-20-036.

**Tiền điều kiện, dữ liệu.** `U-T90-VW`, `U-T92-TA` (`SUSPENDED`), `U-T91-TA` (`MERGED`); `S-PH03`.

**Các bước.**

1. `GET T/context` bằng `U-T90-VW`
2. `GET T/context` bằng `U-T92-TA`
3. `GET T/context` bằng `U-T91-TA`
4. `S-PH03` gọi `GET I/tenants/T90`
5. Mở `dh-console` bằng từng tài khoản

**Kết quả mong đợi.** Bước 1 `status = ACTIVE`, `readOnly = false`, `modules[]`, `banner` rỗng. Bước 2 `status = SUSPENDED`, `readOnly = true`, `banner` `CRITICAL` "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh." Bước 3 `MERGED`, `readOnly = true`, banner kèm liên kết sang tỉnh đích. Bước 4 bản ghi registry có phân hệ đang bật. Bước 5 dải cảnh báo xuất hiện ngay dưới thanh trên, menu ẩn mục phân hệ chưa bật, làm mới mỗi 60 giây; API `context` luôn `200` kể cả khi tạm ngừng.

:::

#### TC-20-079 · Danh mục phân hệ: tham số sai, danh mục chưa nạp <!--k:mod-catalog-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-20-033 · API-20-063, 064 · ERR-20-004, ERR-20-062, ERR-20-002.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`; danh mục phân hệ chưa nạp (bản giả lỗi triển khai).

**Các bước.**

1. `GET P/modules?wave=abc`; `GET P/modules?core=maybe`
2. `GET P/modules` khi danh mục chưa nạp
3. `GET P/tenants/T-KHONG-CO/modules`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004`. Bước 2 `503` `ERR-20-062`. Bước 3 `404` `ERR-20-002`.

:::

#### TC-20-080 · Ngữ cảnh tenant: token không có tenant, tenant đã chấm dứt, tham số tenant giả <!--k:ctx-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-037 · API-20-142, 163 · ERR-00-401 · ERR-20-102 · ERR-20-104.

**Tiền điều kiện, dữ liệu.** `U-T90-VW`; token không có tenant; `T88` `DECOMMISSIONED` (người dùng cũ); `S-NOSCOPE`.

**Các bước.**

1. `GET T/context` với token không có tenant hợp lệ
2. `GET T/context` bằng người dùng của `T88`
3. `GET T/context?tenantId=T91` bằng `U-T90-VW`
4. `S-NOSCOPE` `GET I/tenants/T90`

**Kết quả mong đợi.** Bước 1 `401` `ERR-00-401` ("Phiên đăng nhập đã hết hạn. Đăng nhập lại."). Bước 2 `410` `ERR-20-102` ("Tỉnh đã chấm dứt sử dụng Datahub."). Bước 3 trả ngữ cảnh `T90` (tham số bị bỏ qua). Bước 4 `403` `ERR-20-104`.

**Thông báo hiển thị.** ERR-20-102: "Tỉnh đã chấm dứt sử dụng Datahub."

:::

### TS-20-18 · Tắt, tạm ngừng, tiếp tục phân hệ và đặt cờ tính năng

**Mục tiêu.** Tắt, tạm ngừng, tiếp tục phân hệ của tenant không xóa dữ liệu; phân hệ lõi không tắt được; đặt cờ tính năng theo tenant trong phân hệ đã bật.

**Phủ.** FR-20-035, 036; UC-20-18; UI-20-07; API-20-064, 066, 067, 068, 069, 070.

#### TC-20-081 · Tạm ngừng, tiếp tục và tắt phân hệ, dữ liệu giữ nguyên <!--k:mod-suspend-disable-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-035 · UC-20-18 · API-20-066, 067, 068, 064 · BR-20-018 · EVT-20-08 · ERR-20-103 · UI-20-07 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` có PH-17 `ENABLED` và dữ liệu thử; `mod-sim` báo xong.

**Các bước.**

1. `POST P/tenants/T90/modules/PH-17:suspend` với `reason`, `ticketRef`
2. Gọi API của PH-17 bằng token `T90`
3. `POST .../PH-17:resume`
4. `POST .../PH-17:disable`; `mod-sim` báo xong; `GET P/tenants/T90/modules`
5. Bật lại PH-17 và đọc dữ liệu cũ

**Kết quả mong đợi.** Bước 1 `202`, `SUSPENDED`, EVT: `platform.tenant.module-disabled.v1`; menu hiện chỉ đọc. Bước 2 `503` `ERR-20-103` ("Chức năng này chưa được bật cho tỉnh."). Bước 3 `ENABLED`. Bước 4 `DISABLING` rồi `DISABLED`, EVT `module-disabled` một lần. Bước 5 dữ liệu của phân hệ còn nguyên (BR-20-018).

:::

#### TC-20-082 · Tắt phân hệ lõi, phân hệ đang bị phụ thuộc, sai trạng thái <!--k:mod-disable-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-035 · API-20-066, 067, 068 · BR-20-003, 017 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-034, ERR-20-035.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` có PH-06 là phụ thuộc của PH-08; PH-17 `DISABLED`; `PLATFORM`.

**Các bước.**

1. `POST P/tenants/T90/modules/PH-12:disable`
2. `POST P/tenants/T90/modules/PH-06:disable` khi PH-08 đang bật
3. `POST .../PH-17:suspend` khi `DISABLED`
4. `POST .../PH-16:resume` khi `ENABLED`
5. `POST .../PH-16:disable` thiếu `reason`; `PH-99:disable`
6. `POST P/tenants/PLATFORM/modules/PH-16:suspend`

**Kết quả mong đợi.** Bước 1 `403` `ERR-20-035`. Bước 2 `409` `ERR-20-034`. Bước 3, 4 `409` `ERR-20-006`. Bước 5 `422` `ERR-20-008`, rồi `400` `ERR-20-004`. Bước 6 `403` `ERR-20-010`.

**Thông báo hiển thị.** ERR-20-035: "Phân hệ PH-12 là phân hệ lõi, không tắt được."; ERR-20-034: "Phân hệ PH-06 đang được PH-08 dùng. Tắt các phân hệ đó trước."

:::

#### TC-20-083 · Đặt và xem cờ tính năng theo tenant <!--k:flag-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-036 · UC-20-18 · API-20-069, 070 · UI-20-07 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` PH-19 `ENABLED` có cờ `ph19.tinh-nang-thu`.

**Các bước.**

1. `GET P/tenants/T90/feature-flags?moduleCode=PH-19`
2. `PUT P/tenants/T90/feature-flags/ph19.tinh-nang-thu` với `enabled = true`, `validTo`, `reason`, `ticketRef`, kèm `If-Match`
3. `GET T/context` bằng `U-T90-VW`

**Kết quả mong đợi.** Bước 2 `200`. Bước 3 `featureFlags` có cờ bật đến `validTo`; sau hạn tự tắt. KT có `reason`, `ticketRef`.

:::

#### TC-20-084 · Cờ không áp dụng, cờ không có, thiếu If-Match, thiếu lý do <!--k:flag-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-036 · API-20-070 · ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-036, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; cờ `ph17.tro-ly-thu` thuộc PH-17 đang `DISABLED`; `PLATFORM`.

**Các bước.**

1. `PUT .../feature-flags/ph17.tro-ly-thu` với `enabled = true`
2. `PUT .../feature-flags/khong-co`
3. `PUT .../feature-flags/ph19.tinh-nang-thu` với `validTo` trong quá khứ
4. `PUT` thiếu `If-Match`; `If-Match` cũ; thiếu `reason`
5. `PUT P/tenants/PLATFORM/feature-flags/ph19.tinh-nang-thu`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-036` (phân hệ chưa bật). Bước 2 `404` `ERR-20-002`. Bước 3 `400` `ERR-20-004`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`, `422` `ERR-20-008`. Bước 5 `403` `ERR-20-010`.

**Thông báo hiển thị.** ERR-20-036: "Cờ ph17.tro-ly-thu không áp dụng được: phân hệ PH-17 chưa bật."

:::

### TS-20-19 · Phân hệ đọc registry, tổ chức và thực thi trạng thái tenant

**Mục tiêu.** Phân hệ khác đọc registry và tổ chức bằng scope máy; mặt phẳng dữ liệu và mặt phẳng điều khiển thực thi trạng thái tenant (`ERR-20-001`, `101`, `102`, `103`, `115`, `118`) trong 60 giây.

**Phủ.** FR-20-057, 065, 066; UC-20-19; API-20-142, 162, 163, 164, 169, 170, 171.

#### TC-20-085 · Phân hệ đọc registry, bản ghi tenant và cấu hình thực thi <!--k:registry-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-065 · UC-20-19 · API-20-162, 163, 164 · NFR-20-003 · BR-20-036 · `tenant:registry-read`.

**Tiền điều kiện, dữ liệu.** `S-PH03`, `S-PH12`, `S-PH10`; `T90…T99` có trạng thái khác nhau.

**Các bước.**

1. `S-PH03` gọi `GET I/tenants?status=ACTIVE`
2. `S-PH12` gọi `GET I/tenants?module=PH-16&updatedSince=2026-11-01T00:00:00+07:00`
3. `S-PH03` gọi `GET I/tenants/T90` và `GET I/tenants/T90/enforcement`
4. Đổi trạng thái `T92` rồi gọi lại bước 1

**Kết quả mong đợi.** Bước 1 chỉ tenant `ACTIVE`. Bước 2 lọc đúng phân hệ và thời điểm. Bước 3 `enforcement` có `hosts`, `apiPrefix`, `quotas[]`, `redirects[]`, `configVersion`, `essentialApisAllowed`. Bước 4 EVT-20-04 vô hiệu đệm, kết quả mới trong ≤ `20.registry.cache-seconds`. Không có dữ liệu cá nhân trong bản ghi.

:::

#### TC-20-086 · Registry với scope sai, token người dùng, tenant không có <!--k:registry-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-065 · API-20-162, 163, 164, 165 · ERR-20-002, ERR-20-004, ERR-20-104, ERR-00-401.

**Tiền điều kiện, dữ liệu.** `S-NOSCOPE`, `S-PH01` (chỉ `tenant:org-read`); `U-PA1` (người dùng).

**Các bước.**

1. `S-NOSCOPE` gọi `GET I/tenants`
2. `S-PH01` gọi `GET I/tenants/T90/enforcement`
3. `U-PA1` gọi `GET I/tenants`
4. `S-PH03` gọi `GET I/tenants/T89`
5. `S-PH03` gọi `GET I/tenants?status=XYZ`
6. Gọi không có chứng chỉ mTLS hoặc token

**Kết quả mong đợi.** Bước 1, 2 `403` `ERR-20-104`. Bước 3 `403` `ERR-20-104` (token người dùng không đi cổng nội bộ). Bước 4 `404` `ERR-20-002`. Bước 5 `400` `ERR-20-004`. Bước 6 `401` `ERR-00-401`.

**Thông báo hiển thị.** ERR-20-104: "Tài khoản dịch vụ không có quyền tenant:registry-read."

:::

#### TC-20-087 · Thực thi trạng thái tenant ở mặt phẳng dữ liệu theo từng trạng thái <!--k:enforce-matrix-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-20-066 · UC-20-19 · API-20-142, 163 · BR-20-021, 026, 036 · ERR-20-001, ERR-20-101, ERR-20-102, ERR-20-103, ERR-20-115, ERR-20-118 · NFR-20-004.

**Tiền điều kiện, dữ liệu.** `gw-sim`, `mod-sim`; tenant theo trạng thái: `T92` `SUSPENDED`, `T97` `PROVISIONING`, `T94` `FAILED`, `T88` `DECOMMISSIONED`, `T91` `MERGED`, `T90` PH-17 `DISABLED`, `T90` đang bảo trì nâng cấp; `20.suspend.essential-api-allowed = false`.

**Các bước.**

1. Gọi API dữ liệu bằng token từng tenant ở trên
2. Bật `20.suspend.essential-api-allowed = true`, gọi API thiết yếu chỉ đọc và API ghi của `T92`
3. Gọi `GET T/context` ở mọi tenant trên

**Kết quả mong đợi.** `T92` `403` `ERR-20-001`; `T97`, `T94` `503` `ERR-20-101`; `T88` `410` `ERR-20-102`; `T91` đọc theo chuyển tiếp, ghi `409` `ERR-20-115`; PH-17 tắt `503` `ERR-20-103`; đang bảo trì ghi `503` `ERR-20-118`. Bước 2 API thiết yếu chỉ đọc `200`, API ghi vẫn `403` `ERR-20-001`. Bước 3 `context` luôn `200`. Mỗi từ chối có thân `problem+json` đúng câu thông báo FRS mục 9.2.

**Thông báo hiển thị.** ERR-20-101: "Tỉnh chưa sẵn sàng phục vụ."; ERR-20-102: "Tỉnh đã chấm dứt sử dụng Datahub."; ERR-20-103: "Chức năng này chưa được bật cho tỉnh."; ERR-20-118: "Tỉnh đang bảo trì nâng cấp đến 03:00. Thao tác ghi tạm dừng."

:::

#### TC-20-088 · Phân hệ đọc tổ chức: danh sách, một tổ chức, tra hàng loạt <!--k:org-read-api-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-057, 058 · UC-20-19 · API-20-169, 170, 171 · NFR-20-013 · BR-20-028, 036 · `tenant:org-read`.

**Tiền điều kiện, dữ liệu.** `S-PH01`, `S-PH07`; `T90` có F-ORG, tổ chức `SO-CU` đã `DISSOLVED` (có `successorCode`), 5 tổ chức là chủ quản dữ liệu.

**Các bước.**

1. `S-PH01` gọi `GET I/organizations?status=ACTIVE&orgType=DEPARTMENT`
2. `S-PH01` gọi `GET I/organizations?isDataOwner=true`
3. `S-PH01` gọi `GET I/organizations?asOf=2025-06-30&updatedSince=2026-11-01T00:00:00+07:00`
4. `S-PH07` gọi `GET I/organizations/SO-CU`
5. `S-PH08` gọi `POST I/organizations:lookup` với 500 mã và `asOf`

**Kết quả mong đợi.** Bước 1 chỉ sở `ACTIVE`. Bước 2 đúng năm tổ chức chủ quản. Bước 3 trả tổ chức theo hiệu lực tại ngày `asOf`. Bước 4 `200` kể cả đã giải thể, có `status = DISSOLVED`, `successorCode`. Bước 5 trả đủ 500 mã (mã không có đánh dấu không tìm thấy). p95 ≤ 100 ms (NFR-20-013); tenant ngữ cảnh lấy từ token máy.

:::

#### TC-20-089 · Tra tổ chức: quá 500 mã, scope sai, tổ chức không có <!--k:org-read-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-057 · API-20-169, 170, 171 · ERR-20-002, ERR-20-004, ERR-20-104.

**Tiền điều kiện, dữ liệu.** `S-PH01`, `S-NOSCOPE`, `S-PH03` (chỉ `tenant:registry-read`).

**Các bước.**

1. `POST I/organizations:lookup` với 501 mã
2. `GET I/organizations/KHONG-CO`
3. `S-NOSCOPE` và `S-PH03` gọi `GET I/organizations`
4. `GET I/organizations?asOf=2026-13-45`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004`. Bước 2 `404` `ERR-20-002`. Bước 3 `403` `ERR-20-104`. Bước 4 `400` `ERR-20-004`.

:::

### TS-20-20 · Tạm ngừng và khôi phục tenant

**Mục tiêu.** Tạm ngừng có lý do, văn bản căn cứ, không cần bốn mắt, hiệu lực ở mặt phẳng dữ liệu trong 60 giây; khôi phục sau kiểm tra khói rút gọn; thông báo đổi trạng thái.

**Phủ.** FR-20-038, 039, 044; UC-20-20; UI-20-08; API-20-071, 079, API-12-084, 085.

#### TC-20-090 · Tạm ngừng T92 theo quyết định quản lý và hiệu lực ở mặt phẳng dữ liệu <!--k:suspend-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-038, 044 · UC-20-20 · API-20-071, 079 · BR-20-021 · EVT-20-04 · ERR-20-001 · NFR-20-004 · UI-20-08 · `PERM-20-lifecycle`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T92` `ACTIVE`; `iam-sim`, `mod-sim`, `mod-sim`, `ops-sim`; `clock-sim`.

**Các bước.**

1. `POST P/tenants/T92/lifecycle-requests` với `requestType = SUSPEND`, `suspendReason = MANAGEMENT_DECISION`, `reasonText` 30 ký tự, `ticketRef`, `decisionDocNo = TC/QĐ-01`, `decisionDocDate`, `essentialApisAllowed = false`
2. Theo dõi `GET P/lifecycle-requests/{requestId}` tới khi xong
3. Gọi API dữ liệu và `dh-console` bằng token `T92` ngay khi tenant `SUSPENDED`
4. Đọc thư thông báo ở `ops-sim`

**Kết quả mong đợi.** Bước 1 `201`, `APPROVED` ngay (không cần duyệt), thực hiện ngay. Bước 2 `DONE`, tenant `SUSPENDED`, đã gọi API-12-084 (realm chỉ đăng nhập xem, chặn token máy), lịch sử trạng thái có quyết định; EVT: `platform.tenant.status-changed.v1` đúng một lần. Bước 3 trong ≤ 60 giây mọi API trả `403` `ERR-20-001`, giao diện chỉ đọc có dải cảnh báo; PH-04 dừng luồng theo lịch, PH-10 chặn sản xuất sự kiện. Bước 4 đầu mối và quản trị tỉnh nhận thư nêu lý do và liên hệ, không có dữ liệu cá nhân của người dùng khác.

**Thông báo hiển thị.** ERR-20-001: "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh."

:::

#### TC-20-091 · Tạm ngừng sai trạng thái, thiếu lý do, thiếu văn bản, tenant đặc biệt, PH-12 lỗi <!--k:suspend-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-038 · API-20-071, 079 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-107 · `20.lifecycle.reason-min-length`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T92` đã `SUSPENDED`; `T90` `ACTIVE`; `iam-sim` trả `409` ở API-12-084.

**Các bước.**

1. `POST P/tenants/T92/lifecycle-requests` với `SUSPEND` khi đã `SUSPENDED`
2. `POST P/tenants/T90/lifecycle-requests` `SUSPEND` với `reasonText` 10 ký tự, không `ticketRef`
3. `POST` `suspendReason = MANAGEMENT_DECISION` không có `decisionDocNo`
4. `POST P/tenants/PLATFORM/lifecycle-requests` `SUSPEND`
5. `POST` `SUSPEND` cho `T90` khi `iam-sim` lỗi

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-008`. Bước 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-20-010`. Bước 5 đề nghị về `APPROVED` (thực hiện lỗi) với `ERR-20-107` ở UI-20-08, data plane vẫn chặn nhờ EVT-20-04 tới PH-03, tenant theo dõi được thực hiện lại.

**Thông báo hiển thị.** ERR-20-006: "Không thể tạm ngừng khi tenant đang ở trạng thái SUSPENDED."

:::

#### TC-20-092 · Tạm ngừng do sự cố an ninh: không cần văn bản, mở việc bổ sung văn bản <!--k:suspend-incident-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-038 · UC-20-20 · API-20-071 · BR-20-021 · UI-20-08.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T91`; `ops-sim` nhận việc; `clock-sim`.

**Các bước.**

1. `POST P/tenants/T91/lifecycle-requests` `SUSPEND` với `suspendReason = SECURITY_INCIDENT`, không văn bản
2. Kiểm tra việc ở `ops-sim`
3. Đẩy `clock-sim` quá 3 ngày làm việc khi chưa bổ sung

**Kết quả mong đợi.** Bước 1 `201`, tạm ngừng ngay. Bước 2 có việc yêu cầu bổ sung văn bản trong 3 ngày làm việc. Bước 3 tenant giữ `SUSPENDED`, cảnh báo hai PA, không tự khôi phục (Q20-47).

:::

#### TC-20-093 · Khôi phục tenant sau kiểm tra khói rút gọn <!--k:resume-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-039 · UC-20-20 · API-20-071, 079, API-12-085 · EVT-20-04 · UI-20-08 · `PERM-20-lifecycle`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T92` `SUSPENDED` do `CONTRACT_EXPIRED`; `iam-sim`, `mod-sim`.

**Các bước.**

1. `POST P/tenants/T92/lifecycle-requests` với `requestType = RESUME`, `reasonText`, `ticketRef`, `decisionDocNo`
2. Theo dõi tới khi `DONE`
3. Gọi API dữ liệu bằng token `T92`

**Kết quả mong đợi.** Bước 2 gọi API-12-085, chạy ca `LOGIN_ADMIN`, `API_SAMPLE`, tenant `ACTIVE`, EVT: `status-changed` một lần; cảnh báo nếu chưa có hợp đồng hiệu lực mới (không chặn). Bước 3 `200`, trong ≤ 60 giây. Thông báo đổi trạng thái gửi đầu mối.

:::

#### TC-20-094 · Khôi phục sai trạng thái, đang có đề nghị chấm dứt, khói rút gọn lỗi <!--k:resume-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-039 · API-20-071, 079 · ERR-20-006, ERR-20-037, ERR-20-117.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90` `ACTIVE`; `T92` `SUSPENDED` có đề nghị `TERMINATE` đã `APPROVED`; `T91` `SUSPENDED`, `iam-sim` lỗi ca `LOGIN_ADMIN`.

**Các bước.**

1. `POST P/tenants/T90/lifecycle-requests` `RESUME`
2. `POST P/tenants/T92/lifecycle-requests` `RESUME`
3. `POST P/tenants/T91/lifecycle-requests` `RESUME`

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-037` ("Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant T92: đang có đề nghị chấm dứt."). Bước 3 `ERR-20-117` ("Ca kiểm tra khói LOGIN_ADMIN lỗi: không lấy được token quản trị tỉnh."), tenant giữ `SUSPENDED`.

**Thông báo hiển thị.** ERR-20-037: "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant T92: đang có đề nghị chấm dứt."

:::

### TS-20-21 · Đề nghị, duyệt chấm dứt tenant và xuất gói bàn giao

**Mục tiêu.** Lập đề nghị chấm dứt khi tenant `SUSPENDED`, duyệt bốn mắt, xuất gói bàn giao có bản kê ký, cấp liên kết có hạn, xác nhận bàn giao bởi người khác người duyệt.

**Phủ.** FR-20-040, 041; UC-20-21; UI-20-08; API-20-071, 073…078, 080…084, 168.

#### TC-20-095 · Lập, gửi, duyệt đề nghị chấm dứt bốn mắt <!--k:term-request-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-040 · UC-20-21 · API-20-071, 073, 074, 075, 076, 077 · BR-20-008, 019 · UI-20-08 · `PERM-20-lifecycle`, `PERM-20-approve`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; `T92` `SUSPENDED` từ 35 ngày trước (`clock-sim`); văn bản chấm dứt `TC/QĐ-02`.

**Các bước.**

1. `U-PA1` `POST P/tenants/T92/lifecycle-requests` với `requestType = TERMINATE`, `reasonText`, `ticketRef`, `decisionDocNo`, `decisionDocDate`, `decisionFileId`, `plannedAt` sau ngày nguội, `exportRequired = true`
2. `U-PA1` `POST P/lifecycle-requests/{requestId}:submit`
3. `U-PA2` `GET P/lifecycle-requests?status=PENDING_APPROVAL` và `GET .../{requestId}`
4. `U-PA2` `POST .../{requestId}:approve` với `comment`

**Kết quả mong đợi.** Bước 1 `201`, `DRAFT`. Bước 2 `PENDING_APPROVAL`, nội dung khóa. Bước 3 `U-PA2` thấy tóm tắt dữ liệu sẽ mất (số HTTT, API, người dùng, dung lượng), trạng thái gói bàn giao, ngày sớm nhất được thực hiện (`coolingUntil`). Bước 4 `200`, `APPROVED`, hệ thống tự yêu cầu gói bàn giao nếu chưa có và báo đầu mối tỉnh. Không phát EVT-20-04 (chỉ khi thực hiện). Rút và từ chối: `U-PA1` `:cancel` rút về `DRAFT`, `U-PA2` `:reject` kèm ý kiến thì `REJECTED`.

:::

#### TC-20-096 · Chấm dứt: tenant chưa tạm ngừng, chưa hết nguội, tự duyệt, đề nghị trùng, thiếu văn bản <!--k:term-request-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-040 · API-20-071, 075, 076, 078 · BR-20-008, 019 · ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-037, ERR-20-038.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`, `U-PA3`; `T90` `ACTIVE`; `T92` `SUSPENDED` từ 10 ngày; đề nghị `TERMINATE` đang `PENDING_APPROVAL`.

**Các bước.**

1. `POST P/tenants/T90/lifecycle-requests` `TERMINATE`
2. `POST P/tenants/T92/lifecycle-requests` `TERMINATE` với `plannedAt` sau 15 ngày (trước ngày nguội)
3. `POST` thiếu `decisionDocNo`, `decisionDocDate`
4. `POST P/tenants/T92/lifecycle-requests` `TERMINATE` lần hai khi đã có đề nghị chưa kết thúc
5. `U-PA1` `:approve` đề nghị do chính mình lập; `U-PA3` (đủ cả hai quyền) lập rồi tự duyệt
6. `U-PA2` `:approve` khi `DRAFT`; `:submit` khi `APPROVED`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-037`. Bước 2 `422` `ERR-20-038` ("Chưa hết thời gian chờ 30 ngày kể từ khi tạm ngừng (đến 14/12/2026)."). Bước 3 `400` `ERR-20-004`. Bước 4 `409` `ERR-20-006`. Bước 5 `403` `ERR-20-007` kể cả người giữ cả hai quyền. Bước 6 `409` `ERR-20-006`.

**Thông báo hiển thị.** ERR-20-038: "Chưa hết thời gian chờ 30 ngày kể từ khi tạm ngừng (đến 14/12/2026)."

:::

#### TC-20-097 · Xuất gói bàn giao, ký bản kê, cấp liên kết, xác nhận đã bàn giao <!--k:export-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-20-041 · UC-20-21 · API-20-080, 081, 082, 083, 084, 168 · BR-20-008, 019 · EVT-20-16 · UI-20-08 · `PERM-20-lifecycle`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; `T92` `SUSPENDED`; đề nghị chấm dứt do `U-PA2` duyệt; `mod-sim` của PH-01, 02, 07, 16 xuất phần dữ liệu; `s3-sim`.

**Các bước.**

1. `POST P/tenants/T92/export-packages` với `format = JSONL`, `includeAudit = true`
2. Mỗi phân hệ báo `POST I/export-packages/{packageId}/items/{module}:report` với `status = DONE`, `rowCount`, `sizeBytes`, `sha256`, `fileId`
3. `GET P/export-packages/{packageId}`
4. `POST .../{packageId}:issue-link` với `recipientEmail`, `expiresHours = 48`
5. `U-PA1` (không phải người duyệt) `POST .../{packageId}:confirm-delivery` với `handoverDocFileId`, `deliveredAt`, `deliveredTo`

**Kết quả mong đợi.** Bước 1 `202`, `REQUESTED` rồi `COLLECTING`. Bước 3 `READY`, có `manifestSha256` (bản kê `manifest.json` ký bằng khóa nền tảng) và EVT: `platform.tenant.export-ready.v1`; phân hệ chưa bật ghi "không có dữ liệu". Bước 4 `200`, `downloadUrl` hạn 48 giờ. Bước 5 `200`, `DELIVERED`. Liên kết và email người nhận không xuất hiện trong log (mồi sạch).

:::

#### TC-20-098 · Gói bàn giao: cấp liên kết khi chưa sẵn sàng, người duyệt tự xác nhận, gói hết hạn, phân hệ lỗi <!--k:export-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-041 · API-20-080, 082, 083, 084, 168 · BR-20-008 · ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-039, ERR-20-104, ERR-20-107.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; gói `COLLECTING`; gói `READY` của đề nghị do `U-PA2` duyệt; gói `EXPIRED` (sau 90 ngày, `clock-sim`); `S-NOSCOPE`.

**Các bước.**

1. `POST .../{packageId}:issue-link` khi `COLLECTING`
2. `U-PA2` (người duyệt chấm dứt) `POST .../{packageId}:confirm-delivery`
3. `GET P/export-packages/{packageId}` và `POST ...:issue-link` với gói `EXPIRED`
4. `POST ...:issue-link` với `recipientEmail = khong-hop-le`
5. `S-NOSCOPE` gọi `POST I/export-packages/{packageId}/items/PH-01:report`
6. Phân hệ không báo quá 24 giờ

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `403` `ERR-20-007`. Bước 3 `410` `ERR-20-039`. Bước 4 `400` `ERR-20-004`. Bước 5 `403` `ERR-20-104`. Bước 6 phần dữ liệu đó `FAILED` với `ERR-20-107`, gói chưa `READY`, PA chạy lại phần lỗi. Gói không có `packageId` thì `404` `ERR-20-002`.

**Thông báo hiển thị.** ERR-20-039: "Gói bàn giao pkg-0007 đã hết hạn lưu. Lập gói mới."

:::

#### TC-20-099 · Hộp duyệt toàn nền tảng và lọc đề nghị vòng đời <!--k:term-inbox-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-040, 043 · API-20-072, 073, 074 · UI-20-08 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA2`, `U-PO`; ba đề nghị `PENDING_APPROVAL`, một `DONE`.

**Các bước.**

1. `GET P/lifecycle-requests?status=PENDING_APPROVAL&requestType=TERMINATE`
2. `GET P/lifecycle-requests?tenantCode=T92`
3. `GET P/tenants/T92/lifecycle-requests?type=SUSPEND&from=2026-10-01&to=2026-11-27`
4. `GET P/lifecycle-requests/{requestId}` và `GET P/lifecycle-requests/khong-co`

**Kết quả mong đợi.** Bước 1, 2, 3 trả đúng tập đã lọc, có `allowedActions[]` theo người xem (người lập không có hành động "duyệt"). Bước 4 `200` rồi `404` `ERR-20-002`.

:::

### TS-20-22 · Thực hiện chấm dứt tenant

**Mục tiêu.** Thực hiện chấm dứt chỉ khi đủ ba điều kiện (đề nghị đã duyệt, gói bàn giao `DELIVERED`, hết thời gian nguội), gỡ tài nguyên, xóa mật mã không đảo ngược sau khi nhận xác nhận.

**Phủ.** FR-20-042; UC-20-22; UI-20-08; API-20-079.

#### TC-20-100 · Thực hiện chấm dứt T92 và nhận xác nhận xóa mật mã <!--k:term-exec-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-042 · UC-20-22 · API-20-079 · BR-20-019, 020 · EVT-20-04 · ERR-20-102 · UI-20-08 · `PERM-20-lifecycle`.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`, `U-PA2`; `T92` `SUSPENDED` từ 35 ngày, đề nghị `TERMINATE` `APPROVED` do `U-PA2` duyệt, gói bàn giao `DELIVERED`; `iam-sim`, `obs-sim`, `crypto-sim`, `vault-sim`, `s3-sim`, `git-sim`.

**Các bước.**

1. `POST P/lifecycle-requests/{requestId}:execute` với `confirmTenantCode = T92`, kèm `If-Match`, `Idempotency-Key`
2. Theo dõi từng bước, kiểm các bản giả
3. `crypto-sim` phát `EVT-09-21`
4. Gọi API bằng token `T92`

**Kết quả mong đợi.** Bước 1 `202`, `EXECUTING`. Bước 2 EVT: `platform.tenant.status-changed.v1` (`DECOMMISSIONED`) để phân hệ gỡ tài nguyên; PH-12 xóa realm; API-13-073 đóng chuỗi kiểm toán (chuỗi WORM giữ theo thời hạn); bucket, đường dẫn OpenBao gỡ, thư mục Git commit xóa có ký; gọi FR-09-043 xóa KEK `dh-t92-pii`. Bước 3 tenant `DECOMMISSIONED`, đề nghị `DONE`, lịch sử trạng thái có người duyệt và người thực hiện. Bước 4 `410` `ERR-20-102`. Mã `T92` không cấp lại được.

:::

#### TC-20-101 · Thực hiện chấm dứt khi thiếu điều kiện <!--k:term-exec-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-042 · API-20-079 · BR-20-008, 019 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-037, ERR-20-038 · ERR-00-428 · `20.terminate.cooling-days`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; đề nghị A (gói bàn giao `READY` chưa `DELIVERED`), đề nghị B (`DELIVERED` nhưng mới tạm ngừng 20 ngày), đề nghị C (`PENDING_APPROVAL`).

**Các bước.**

1. `POST .../{A}:execute` với `confirmTenantCode` đúng
2. `POST .../{B}:execute`
3. `POST .../{C}:execute`
4. `POST .../{A}:execute` với `confirmTenantCode = T99`
5. `POST .../{A}:execute` thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-037` (gói chưa `DELIVERED`). Bước 2 `422` `ERR-20-038`. Bước 3 `409` `ERR-20-006` (chưa duyệt). Bước 4 `400` `ERR-20-004`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`. Không phát EVT-20-04. Người xác nhận bàn giao trùng người duyệt: `403` `ERR-20-007` ở bước xác nhận (xem ca export-neg).

:::

#### TC-20-102 · Không nhận xác nhận xóa mật mã sau 24 giờ <!--k:term-shred-timeout-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-042 · API-20-079 · BR-20-020 · ERR-20-116 · UC-20-22.

**Tiền điều kiện, dữ liệu.** `T92` ở bước xóa mật mã; `crypto-sim` không phát `EVT-09-21`; `clock-sim`.

**Các bước.**

1. Thực hiện chấm dứt `T92`, `crypto-sim` im lặng
2. Đẩy `clock-sim` 24 giờ
3. Kiểm tra trạng thái tenant và đề nghị

**Kết quả mong đợi.** Cảnh báo SO nền tảng với `ERR-20-116` ("Chưa nhận xác nhận xóa mật mã của T92."), tenant giữ `SUSPENDED`, đề nghị giữ `EXECUTING`; khi `EVT-09-21` tới sau đó thì chuyển `DECOMMISSIONED`.

**Thông báo hiển thị.** ERR-20-116: "Chưa nhận xác nhận xóa mật mã của T92."

:::

#### TC-20-103 · Phân hệ chưa báo gỡ xong sau 24 giờ, PH-12 lỗi khi xóa realm <!--k:term-module-late-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-042 · API-20-079 · ERR-20-062 · ERR-20-102 · UC-20-22 · UI-20-08.

**Tiền điều kiện, dữ liệu.** `T92`; `mod-sim` PH-04 không báo gỡ; `iam-sim` `503` lần đầu.

**Các bước.**

1. Thực hiện chấm dứt `T92` khi `iam-sim` `503`
2. Bật `iam-sim`, thực hiện lại
3. Đẩy `clock-sim` 24 giờ khi PH-04 chưa báo gỡ

**Kết quả mong đợi.** Bước 1 `503` `ERR-20-062`, đề nghị về `APPROVED`, thử lại được, chưa xóa gì không đảo ngược. Bước 2 thành công. Bước 3 tenant vẫn `DECOMMISSIONED` (data plane đã trả `ERR-20-102`), mở việc dọn cho PH-04 ở PH-18.

:::

### TS-20-23 · Lịch sử vòng đời và thông báo đổi trạng thái

**Mục tiêu.** Tra lịch sử trạng thái và quyết định của tenant, nhật ký đề nghị; thông báo đổi trạng thái gửi đúng người, không lộ dữ liệu cá nhân.

**Phủ.** FR-20-043, 044; UC-20-23; UI-20-03; API-20-072, 074, 085.

#### TC-20-104 · Tra lịch sử trạng thái, quyết định và đề nghị vòng đời <!--k:history-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-043 · UC-20-23 · API-20-085, 072, 074 · UI-20-03 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`, `U-PAU`; `T92` có chuỗi `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `ACTIVE`, `SUSPENDED`.

**Các bước.**

1. `GET P/tenants/T92/status-history`
2. `GET P/tenants/T92/status-history?type=SUSPEND&from=2026-01-01&to=2026-11-27`
3. `GET P/tenants/T92/lifecycle-requests` bằng `U-PAU`
4. Mở tab "Lịch sử vòng đời" ở UI-20-03

**Kết quả mong đợi.** Bước 1 liệt kê theo thời gian: trạng thái cũ, mới, người, lý do, mã phiếu, văn bản quyết định, đề nghị liên quan. Bước 2 chỉ lần tạm ngừng. Bước 3 `U-PAU` xem được, không sửa. Bước 4 hiển thị đúng và không có nút ghi cho PO, PAU.

:::

#### TC-20-105 · Lịch sử: tenant không có, tham số sai <!--k:history-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-043 · API-20-085, 072 · ERR-20-002, ERR-20-004.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`.

**Các bước.**

1. `GET P/tenants/T89/status-history`
2. `GET P/tenants/T92/status-history?from=ngay-sai`
3. `GET P/tenants/T92/lifecycle-requests?type=KHONG-CO`
4. `U-T90-TA` gọi `GET P/tenants/T92/status-history`

**Kết quả mong đợi.** Bước 1 `404` `ERR-20-002`. Bước 2, 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-00-403`.

:::

#### TC-20-106 · Thông báo đổi trạng thái tới đầu mối và quản trị tỉnh <!--k:notify-status-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-044 · UC-20-23 · EVT-20-04 · BR-20-039 · NFR-20-020.

**Tiền điều kiện, dữ liệu.** `T92`; `ops-sim` nhận `NotificationApi`; ba đầu mối và `U-T92-TA`.

**Các bước.**

1. Tạm ngừng rồi khôi phục `T92`
2. Đọc thư ở `ops-sim` và bản tin EVT-20-04
3. `ops-sim` trả `503` khi gửi, đổi trạng thái `T92` lần nữa

**Kết quả mong đợi.** Bước 2 mỗi lần đổi trạng thái có một thư tới đầu mối và `TENANT_ADMIN` với nội dung nêu trạng thái mới, lý do, liên hệ; EVT-20-04 phát ≤ 5 giây (NFR-20-020) và chỉ chứa mã, trạng thái, không dữ liệu cá nhân (BR-20-039). Bước 3 đổi trạng thái vẫn thành công, thông báo thử lại qua outbox, kết quả gửi xem được ở API-20-085.

:::

#### TC-20-107 · Thông báo: PH-18 lỗi thử lại 6 lần, không còn đầu mối hoạt động <!--k:notify-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-044 · ERR-20-062 · ERR-20-021 · UC-20-23.

**Tiền điều kiện, dữ liệu.** `ops-sim` `503`; `T90` chỉ còn đầu mối `LEADER` (đầu mối `TENANT_ADMIN`, `TECHNICAL` đã vô hiệu); `U-PO`.

**Các bước.**

1. Tạm ngừng `T90` khi `ops-sim` `503`; tiến đồng hồ 1 giờ
2. Đặt `T90` chỉ còn một đầu mối rồi đổi trạng thái

**Kết quả mong đợi.** Bước 1 thử lại 6 lần trong 1 giờ rồi cảnh báo PO ở UI-20-20 (`ERR-20-062`); trạng thái tenant vẫn đổi (thông báo không chặn). Bước 2 `ERR-20-021` ("Cần đủ đầu mối TENANT_ADMIN trước khi thông báo."), cảnh báo PO.

:::

### TS-20-24 · Lập kế hoạch và bảng ánh xạ sáp nhập

**Mục tiêu.** Lập kế hoạch sáp nhập hai tenant tỉnh (nguồn, đích, căn cứ pháp lý, thời gian chuyển tiếp), lập và sửa bảng ánh xạ sáu loại đối tượng; kế hoạch hủy được trước cutover.

**Phủ.** FR-20-045, 046; UC-20-24; UI-20-08, 09, 11; API-20-086…089, 093…096.

#### TC-20-108 · Lập kế hoạch sáp nhập T91 vào T90, sửa và xem danh sách <!--k:plan-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-045 · UC-20-24 · API-20-086, 087, 088, 089 · BR-20-022, 025 · UI-20-09, 11 · `PERM-20-merge` · `20.merge.transition-months`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; `T90`, `T91` `ACTIVE` `PROVINCE`; F-MERGE; văn bản `TC/QĐ-SN-01`.

**Các bước.**

1. `POST P/merge-plans` với `name`, `sourceTenants = [T91]`, `targetTenant = T90`, `decisionDocNo`, `decisionDocDate`, `decisionFileId`, `effectiveDate`, `transitionMonths = 6`, `modules`, kèm `Idempotency-Key`
2. `GET P/merge-plans?status=DRAFT&tenantCode=T91` bằng `U-PO`
3. `GET P/merge-plans/{mergePlanId}`
4. `PATCH P/merge-plans/{mergePlanId}` đổi `name` và `transitionMonths = 8`, kèm `If-Match`

**Kết quả mong đợi.** Bước 1 `201`, mã `MG-2026-001`, `status = DRAFT`, phân hệ bật ở nguồn mà đích chưa bật được cảnh báo kèm gợi ý FR-20-034. Bước 2 có kế hoạch. Bước 3 `progress.modulesTotal` đúng số phân hệ, `allowedActions[]`. Bước 4 `200`, `transitionMonths = 8`. KT mọi thao tác ghi.

:::

#### TC-20-109 · Kế hoạch không hợp lệ: nguồn trùng đích, tenant không đủ điều kiện, thuộc kế hoạch khác, chuyển tiếp quá dài <!--k:plan-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-045 · API-20-086, 089 · BR-20-022, 025 · ERR-20-004, ERR-20-040, ERR-20-041, ERR-20-045.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`, `T91` `ACTIVE`; `T92` `SUSPENDED`; `T93` đã thuộc `MG-2026-001` chưa kết thúc.

**Các bước.**

1. `POST P/merge-plans` với `sourceTenants = [T90]`, `targetTenant = T90`
2. `POST` với nguồn `T92` (`SUSPENDED`) hoặc `PLATFORM`
3. `POST` với nguồn `T93` đang thuộc kế hoạch khác
4. `POST` với `transitionMonths = 13`
5. `POST` thiếu `decisionDocNo`, `effectiveDate`

**Kết quả mong đợi.** Bước 1, 2 `422` `ERR-20-040` (nguồn khác đích, đều `ACTIVE`, đều `PROVINCE`). Bước 3 `409` `ERR-20-041`. Bước 4 `422` `ERR-20-045`. Bước 5 `400` `ERR-20-004`. Không tạo kế hoạch.

**Thông báo hiển thị.** ERR-20-041: "Tenant T93 đang thuộc kế hoạch sáp nhập MG-2026-001."; ERR-20-045: "Thời gian chuyển tiếp tối đa 12 tháng."

:::

#### TC-20-110 · Hủy kế hoạch trước cutover và không hủy sau cutover <!--k:plan-cancel-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-045 · API-20-093, 089 · BR-20-024 · ERR-20-005, ERR-20-006, ERR-20-008, ERR-00-428 · EVT-20-04.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch A `APPROVED`; kế hoạch B `TRANSFERRING` (nguồn `MERGING`, đã chuyển một phần); kế hoạch C đã `TRANSITION`.

**Các bước.**

1. `POST .../merge-plans/{A}:cancel` với `reason`, kèm `If-Match`
2. `POST .../{B}:cancel`
3. `POST .../{C}:cancel`
4. `POST .../{B}:cancel` thiếu `reason`, thiếu `If-Match`, `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `200`, `CANCELLED`. Bước 2 `200`, `CANCELLED`, dữ liệu đã chuyển sang đích được PH-18 gỡ theo `origin_tenant_id`, nguồn về `ACTIVE` (EVT: `status-changed`). Bước 3 `409` `ERR-20-006` (hủy chỉ trước cutover). Bước 4 `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-111 · Sinh gợi ý, xem, sửa bảng ánh xạ sáu loại đối tượng <!--k:map-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-046 · UC-20-24 · API-20-094, 095, 096 · BR-20-023 · UI-20-09 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `DRAFT` T91→T90 với F-MERGE; `rdm-sim`, `iam-sim`.

**Các bước.**

1. `POST P/merge-plans/{id}/mappings:suggest`
2. `GET P/merge-plans/{id}/mappings?mappingType=ORGANIZATION&status=PROPOSED`
3. `PUT P/merge-plans/{id}/mappings/{mappingId}` với `action = MAP`, `targetCode`, `note`, kèm `If-Match`
4. `PUT` một dòng `action = CREATE` và một dòng `action = SKIP`
5. `GET P/merge-plans/{id}/mappings?status=CONFLICT`

**Kết quả mong đợi.** Bước 1 `200`, sinh dòng cho 12 `ORGANIZATION`, 20 `MEMBER_SYSTEM`, 30 `CATALOG_CODE`, 4 `API_CONTEXT_PATH`, 150 `USER`, 6 `TOPIC`; mã trùng đánh `CONFLICT`. Bước 3, 4 `200`, dòng `CONFIRMED`. Bước 5 liệt kê dòng xung đột (3 mã tổ chức, 2 mã danh mục, 1 mã `API_CONTEXT_PATH`). Ánh xạ thay đổi làm chạy thử trước đó thành cũ.

:::

#### TC-20-112 · Ánh xạ: mã đích trùng, hành động sai, kế hoạch không ở DRAFT, PH-07 lỗi <!--k:map-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-046 · API-20-095, 096 · ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-042, ERR-20-062, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `DRAFT`; kế hoạch `APPROVED`; `rdm-sim` `503`.

**Các bước.**

1. `PUT .../mappings/{mappingId}` với `targetCode` đã có ở đích khi `action = CREATE`
2. `PUT` với `action = XOA`
3. `PUT` thiếu `If-Match`; `If-Match` cũ
4. `POST .../mappings:suggest` ở kế hoạch `APPROVED`
5. `POST .../mappings:suggest` khi `rdm-sim` `503`
6. `POST .../:dry-run` khi còn dòng bắt buộc chưa quyết định

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-003`. Bước 2 `400` `ERR-20-004`. Bước 3 `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 4 `409` `ERR-20-006`. Bước 5 `503` `ERR-20-062`. Bước 6 `422` `ERR-20-042` ("Bảng ánh xạ còn 5 dòng bắt buộc chưa quyết định.").

**Thông báo hiển thị.** ERR-20-042: "Bảng ánh xạ còn 5 dòng bắt buộc chưa quyết định."

:::

### TS-20-25 · Chạy thử, gửi duyệt và duyệt kế hoạch sáp nhập

**Mục tiêu.** Chạy thử trên bản sao không ghi, ghi băm ánh xạ để phát hiện chạy thử cũ; gửi duyệt cần chạy thử đạt còn hiệu lực; duyệt bốn mắt; PH-18 và phân hệ báo kết quả qua API nội bộ.

**Phủ.** FR-20-045, 047; UC-20-25; UI-20-08, 09, 10, 11; API-20-090…092, 097, 167.

#### TC-20-113 · Chạy thử sáp nhập đạt, ghi băm ánh xạ <!--k:dryrun-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-047 · UC-20-25 · API-20-097, 167 · BR-20-023 · UI-20-09, 10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `DRAFT` T91→T90 đã đủ ánh xạ; `ops-sim` (hợp đồng `merge-transfers` giả định, `dryRun = true`).

**Các bước.**

1. `POST P/merge-plans/{id}:dry-run` với `modules` mặc định
2. `ops-sim` báo từng phân hệ `POST I/merge-plans/{id}/participants/{module}:report` với `phase = DRY_RUN`, `status = SUCCEEDED`, `exportedCount`, `conflictCount`
3. `GET P/merge-plans/{id}`

**Kết quả mong đợi.** Bước 1 `202`, kế hoạch `DRY_RUN`. Bước 3 kế hoạch về `DRAFT`, `dryRun.result = PASSED`, `dryRun.mappingHash` có giá trị, `stale = false`, xung đột dự kiến theo loại khớp F-MERGE (3 + 2 + 1), không ghi dữ liệu thật ở đích. Có xung đột dự kiến vẫn `PASSED`.

:::

#### TC-20-114 · Chạy thử: ánh xạ chưa đủ, đang chạy, phân hệ lỗi, chạy thử cũ <!--k:dryrun-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-047, 045 · API-20-097, 090 · ERR-20-004, ERR-20-006, ERR-20-042, ERR-20-043, ERR-20-107, ERR-20-113.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch thiếu dòng ánh xạ; kế hoạch đang `DRY_RUN`; `ops-sim` báo lệch kiểm đếm ở PH-01.

**Các bước.**

1. `POST .../:dry-run` khi còn dòng bắt buộc chưa quyết định
2. `POST .../:dry-run` khi đang chạy thử
3. Chạy thử khi `ops-sim` báo PH-01 lệch kiểm đếm, và khi báo `FAILED` với `errorCode` ở PH-07
4. Sửa một dòng ánh xạ sau chạy thử `PASSED`, rồi `POST .../:submit`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-042`. Bước 2 `409` `ERR-20-006`. Bước 3 `dryRun.result = FAILED` với `ERR-20-113` ("Kiểm đếm PH-01 lệch: nguồn 120, đích 119.") và `ERR-20-107`. Bước 4 `dryRun.stale = true`, `422` `ERR-20-043`.

**Thông báo hiển thị.** ERR-20-043: "Chạy thử sáp nhập chưa đạt hoặc đã cũ so với bảng ánh xạ hiện hành."

:::

#### TC-20-115 · Gửi duyệt và duyệt bốn mắt kế hoạch sáp nhập <!--k:submit-approve-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-045 · UC-20-25 · API-20-090, 091, 092 · BR-20-008 · UI-20-09, 10, 08 · `PERM-20-merge`, `PERM-20-approve`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`, `U-T90-TA`, `U-T91-TA`; kế hoạch `DRAFT` có chạy thử `PASSED` còn hiệu lực.

**Các bước.**

1. `U-PA1` `POST .../merge-plans/{id}:submit`
2. `U-PA2` `POST .../{id}:approve` với `comment`
3. Tạo kế hoạch khác, `U-PA2` `:reject` với `comment`
4. `U-T90-TA` và `U-T91-TA` mở UI-20-10 của kế hoạch

**Kết quả mong đợi.** Bước 1 `PENDING_APPROVAL`. Bước 2 `200`, `APPROVED`, báo TA hai tỉnh. Bước 3 `REJECTED` về `DRAFT` kèm ý kiến. Bước 4 mỗi TA chỉ đọc phần tỉnh mình, không thấy dữ liệu tỉnh kia.

:::

#### TC-20-116 · Gửi duyệt khi chạy thử cũ, tự duyệt, trạng thái sai, từ chối thiếu ý kiến <!--k:submit-approve-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-045 · API-20-090, 091, 092 · BR-20-008 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-043, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`, `U-PA3`; kế hoạch chưa chạy thử; kế hoạch `PENDING_APPROVAL` do `U-PA1` gửi.

**Các bước.**

1. `U-PA1` `:submit` khi chưa chạy thử đạt
2. `U-PA1` `:approve` kế hoạch của chính mình
3. `U-PA3` (đủ hai quyền) lập, gửi rồi `:approve`
4. `U-PA2` `:approve` kế hoạch còn `DRAFT`
5. `U-PA2` `:reject` thiếu `comment`; `:approve` thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-043`. Bước 2, 3 `403` `ERR-20-007`. Bước 4 `409` `ERR-20-006`. Bước 5 `400` `ERR-20-004`, `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-117 · Phân hệ tham gia báo tiến độ chuyển: hợp lệ, sai trạng thái, thiếu scope <!--k:merge-report-api-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-047, 048 · API-20-167 · ERR-20-002, ERR-20-004, ERR-20-104, ERR-20-114.

**Tiền điều kiện, dữ liệu.** `S-PH18` (scope `tenant:provision-report`), `S-NOSCOPE`; kế hoạch `TRANSFERRING`, phân hệ PH-07 `RUNNING`, phân hệ PH-02 `PENDING`.

**Các bước.**

1. `S-PH18` báo PH-07 `phase = TRANSFER`, `status = SUCCEEDED`, `exportedCount`, `importedCount`, `verifiedCount`
2. Báo lặp đúng nội dung
3. Báo cho PH-02 `phase = CUTOVER` khi kế hoạch chưa tới cutover
4. `S-NOSCOPE` báo
5. Báo `phase = KHONG-CO`; báo cho `mergePlanId` không có

**Kết quả mong đợi.** Bước 1 `200`, PH-07 `SUCCEEDED`. Bước 2 `200` kết quả cũ, không đổi hai lần. Bước 3 `409` `ERR-20-114`. Bước 4 `403` `ERR-20-104`. Bước 5 `400` `ERR-20-004`, rồi `404` `ERR-20-002`.

**Thông báo hiển thị.** ERR-20-114: "Báo tiến độ sáp nhập không khớp trạng thái của PH-02."

:::

### TS-20-26 · Điều phối chuyển dữ liệu sáp nhập theo phân hệ

**Mục tiêu.** Sau khi duyệt, chuyển nguồn sang `MERGING`, điều phối PH-18 chuyển dữ liệu theo thứ tự phụ thuộc, giữ `id` gốc, kiểm đếm khớp từng phân hệ, thử lại từng phân hệ lỗi.

**Phủ.** FR-20-048; UC-20-26; UI-20-10; API-20-088, 098, 099, 100, 167.

#### TC-20-118 · Bắt đầu chuyển dữ liệu T91 sang T90, kiểm đếm khớp <!--k:transfer-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-048 · UC-20-26 · API-20-098, 099, 088, 167 · BR-20-023 · NFR-20-014 · EVT-20-04, 10 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`; kế hoạch `APPROVED`; F-MERGE đã giải quyết ánh xạ; `ops-sim` giả định hợp đồng `merge-transfers` (Q20-15).

**Các bước.**

1. `POST P/merge-plans/{id}:start` với `reason`, `ticketRef`, kèm `If-Match`, `Idempotency-Key`
2. Theo dõi `GET P/merge-plans/{id}/participants`
3. Kiểm đếm `USER`: nguồn 150, `SKIP` 6; `ORGANIZATION`: nguồn 25
4. Kiểm `id` và `origin_tenant_id` ở đích

**Kết quả mong đợi.** Bước 1 `202`, nguồn `T91` `MERGING` nhưng vẫn phục vụ, kế hoạch `TRANSFERRING`; EVT: `merge-started` và `status-changed`. Bước 2 thứ tự phụ thuộc PH-20 (tổ chức), PH-07, PH-01, PH-02, PH-10, PH-04, PH-05, PH-03, các phân hệ khác; mỗi phân hệ `SUCCEEDED`. Bước 3 `USER` nhập 144, `ORGANIZATION` nhập 25 (tổng tổ chức `T90` = 65) khớp 100 % (NFR-20-014). Bước 4 dữ liệu giữ `id` gốc, có `origin_tenant_id = T91`. Hết phân hệ thì kế hoạch sang `IDENTITY_TRANSFER`.

:::

#### TC-20-119 · Chuyển dữ liệu: kế hoạch chưa duyệt, chạy thử cũ, kiểm đếm lệch <!--k:transfer-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-048 · API-20-098, 167 · BR-20-024 · ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-043, ERR-20-113, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `DRAFT`; kế hoạch `APPROVED` nhưng ánh xạ đổi sau chạy thử; `ops-sim` báo PH-01 nhập 119 trên 120.

**Các bước.**

1. `POST .../:start` khi `DRAFT`
2. `POST .../:start` khi chạy thử cũ
3. `POST .../:start` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
4. Chạy chuyển khi PH-01 nhập thiếu một bản ghi

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-043`. Bước 3 `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 4 phân hệ `FAILED` với `ERR-20-113` ("Kiểm đếm PH-01 lệch: nguồn 120, đích 119."), kế hoạch `FAILED` hoặc `CONFLICT_REVIEW` theo nguyên nhân; không sang `IDENTITY_TRANSFER`.

:::

#### TC-20-120 · Chạy lại chuyển của một phân hệ lỗi <!--k:transfer-retry-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-048 · API-20-100, 099 · ERR-20-004, ERR-20-006, ERR-20-043 · UI-20-10.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `FAILED` ở PH-01 (`ops-sim` lỗi một lần); PH-07 `SUCCEEDED`.

**Các bước.**

1. `POST .../participants/PH-01:retry` với `reason`
2. `POST .../participants/PH-07:retry` khi `SUCCEEDED`
3. `POST .../participants/PH-01:retry` thiếu `reason`
4. `POST .../participants/PH-01:retry` khi ánh xạ đã đổi (chạy thử cũ)

**Kết quả mong đợi.** Bước 1 `202`, phân hệ về `TRANSFERRING` rồi `SUCCEEDED`, kế hoạch tiếp tục. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `422` `ERR-20-043`. Chạy lại không nhân bản dữ liệu đã chuyển (lũy đẳng theo `{mergePlanId}:{module}:transfer`).

:::

#### TC-20-121 · Dữ liệu phát sinh ở nguồn trong lúc chuyển được bù ở lượt cuối <!--k:transfer-delta-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-048, 051 · API-20-098, 106 · BR-20-023 · NFR-20-014 · UC-20-26.

**Tiền điều kiện, dữ liệu.** Kế hoạch `TRANSFERRING`; trong lúc chuyển, tạo thêm 3 HTTT và sửa 2 tổ chức ở `T91`.

**Các bước.**

1. Phát sinh thay đổi ở `T91` sau khi phân hệ đã chuyển xong
2. Chạy cutover (lượt bù cuối)

**Kết quả mong đợi.** Mỗi phân hệ chạy lượt bù theo `updated_at`; đích có đủ 3 HTTT và 2 sửa đổi; kiểm đếm sau bù khớp 100 %; không bản ghi nào bị ghi đè tự động.

:::

### TS-20-27 · Xử lý xung đột sáp nhập

**Mục tiêu.** Quyết định từng xung đột (mã trùng khác nghĩa) theo năm cách xử lý, đơn lẻ và hàng loạt; không ghi đè ngoài ý muốn; hết xung đột mở thì kế hoạch về `TRANSFERRING`.

**Phủ.** FR-20-049; UC-20-27; UI-20-10; API-20-101, 102, 103.

#### TC-20-122 · Xem xung đột và xử lý từng dòng bằng ba cách <!--k:conflict-resolve-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-049 · UC-20-27 · API-20-101, 102 · BR-20-023, 024 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `CONFLICT_REVIEW` T91→T90 với F-MERGE: 3 xung đột mã tổ chức, 2 mã danh mục, 1 mã `API_CONTEXT_PATH`.

**Các bước.**

1. `GET P/merge-plans/{id}/conflicts?status=OPEN`
2. `POST .../conflicts/{c1}:resolve` với `resolution = KEEP_TARGET`, `comment`, kèm `If-Match`
3. `POST .../{c2}:resolve` với `resolution = RENAME_SOURCE`, `newCode = DM-T91-01`
4. `POST .../{c3}:resolve` danh mục với `resolution = MERGE_ITEMS`
5. Xem lại `GET .../conflicts?status=OPEN`

**Kết quả mong đợi.** Bước 1 6 dòng mở, mỗi dòng có hai bản nguồn, đích. Bước 2, 3, 4 `200`, dòng `RESOLVED` kèm người, ý kiến. Bước 5 còn 3 dòng; không bản ghi nào ở đích bị ghi đè ngoài `KEEP_SOURCE`. Kiểm toán từng quyết định.

:::

#### TC-20-123 · Xử lý xung đột sai cách, mã mới trùng, đã quyết, thiếu If-Match <!--k:conflict-resolve-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-049 · API-20-102 · ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-002, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO` (không có `PERM-20-merge`); kế hoạch có xung đột mã tổ chức `c1`, danh mục `c2`, `c3` đã `RESOLVED`.

**Các bước.**

1. `:resolve` `c1` với `resolution = MERGE_ITEMS` (chỉ cho danh mục)
2. `:resolve` `c1` với `RENAME_SOURCE` thiếu `newCode`, rồi với `newCode` đã dùng
3. `:resolve` `c3` đã quyết; `c-khong-co`
4. Thiếu `If-Match`; `If-Match` cũ
5. `U-PO` `:resolve`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004`. Bước 2 `400` `ERR-20-004`, `409` `ERR-20-003`. Bước 3 `409` `ERR-20-006`, `404` `ERR-20-002`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 5 `403` `ERR-00-403`. Không dòng nào đổi.

:::

#### TC-20-124 · Xử lý hàng loạt tối đa 500 xung đột cùng loại <!--k:conflict-batch-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API, PERF.

**Truy vết.** FR-20-049 · API-20-103 · ERR-20-004, ERR-20-006 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch có 600 xung đột `CATALOG_CODE` và 5 xung đột `USER`.

**Các bước.**

1. `POST .../conflicts:resolve-batch` với 500 `conflictIds` cùng loại và `KEEP_TARGET`
2. Gửi 501 mã
3. Gửi lô trộn `CATALOG_CODE` và `USER`
4. Gửi lô có một mã đã `RESOLVED`

**Kết quả mong đợi.** Bước 1 `200`, `resolved = 500`, `openRemaining = 105`. Bước 2 `400` `ERR-20-004`. Bước 3 `400` `ERR-20-004` (khác loại). Bước 4 `409` `ERR-20-006`, không dòng nào đổi (tất cả hoặc không).

:::

#### TC-20-125 · Hết xung đột mở thì kế hoạch về TRANSFERRING và phần dính xung đột tiếp tục <!--k:conflict-auto-continue-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-049, 048 · UC-20-27 · API-20-102, 167.

**Tiền điều kiện, dữ liệu.** Kế hoạch `CONFLICT_REVIEW` còn một xung đột; `ops-sim` chờ lệnh tiếp tục cho phần dính xung đột.

**Các bước.**

1. `:resolve` xung đột cuối với `KEEP_SOURCE`
2. Kiểm lệnh tiếp tục gửi PH-18 và kế hoạch

**Kết quả mong đợi.** Kế hoạch về `TRANSFERRING`; `ops-sim` nhận đúng một lệnh tiếp tục cho phần xung đột (lũy đẳng); sau khi phân hệ báo xong kế hoạch sang `IDENTITY_TRANSFER`.

:::

### TS-20-28 · Chuyển định danh, cấp song song thông tin xác thực và cutover

**Mục tiêu.** Tạo lại người dùng ở realm đích, cấp client mới cho HTTT song song với thông tin cũ; cutover có xác nhận lại mã kế hoạch, lượt bù cuối, nguồn sang `MERGED` và bật chuyển tiếp.

**Phủ.** FR-20-050, 051; UC-20-28; UI-20-10; API-20-104, 105, 106, 164; API-12-045, 046.

#### TC-20-126 · Chuyển định danh và cấp song song thông tin xác thực <!--k:identity-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-050 · UC-20-28 · API-20-104, 105 · API-12-045, API-12-046 · BR-20-024, 025 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `IDENTITY_TRANSFER` không còn xung đột; `iam-sim` (hợp đồng API-12-045, 046), `ops-sim`; ánh xạ `USER`: 150 người, 6 `SKIP`.

**Các bước.**

1. `POST P/merge-plans/{id}:transfer-identity` với `notifyUsers = true`, `Idempotency-Key`, `If-Match`
2. `iam-sim` trả kế hoạch định danh: 120 tạo mới, 24 gộp, 6 bỏ qua
3. `GET P/merge-plans/{id}/credentials`
4. Kiểm thư hướng dẫn gửi đầu mối kỹ thuật từng HTTT qua `ops-sim`

**Kết quả mong đợi.** Bước 1 `202`. Bước 3 `items[]` mỗi HTTT có `memberSystemCode`, `newClientId`, `status = ISSUED`, `lastCallOld`, `lastCallNew`; không có giá trị bí mật trong phản hồi hay kiểm toán (chỉ `<bi-mat-mau>` ở bản giả). Hạn client mới bằng `transitionEndsAt`. Bước 4 mỗi đầu mối nhận một thư. Kế hoạch sẵn sàng `CUTOVER`.

:::

#### TC-20-127 · Chuyển định danh khi còn xung đột, PH-12 lỗi, sai trạng thái <!--k:identity-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-050 · API-20-104 · ERR-20-044, ERR-20-062, ERR-20-006, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch còn 2 xung đột mở; kế hoạch `DRAFT`; `iam-sim` `503`.

**Các bước.**

1. `:transfer-identity` khi còn 2 xung đột
2. `:transfer-identity` khi kế hoạch `DRAFT`
3. `:transfer-identity` khi `iam-sim` `503` (đã hết xung đột)
4. Thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-044` ("Còn 2 xung đột sáp nhập chưa xử lý."). Bước 2 `409` `ERR-20-006`. Bước 3 `503` `ERR-20-062`, kế hoạch giữ `IDENTITY_TRANSFER`, thử lại được. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`.

**Thông báo hiển thị.** ERR-20-044: "Còn 2 xung đột sáp nhập chưa xử lý."

:::

#### TC-20-128 · Cutover: nguồn MERGED, bật chuyển tiếp, header Deprecation <!--k:cutover-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-051 · UC-20-28 · API-20-106, 164 · BR-20-024, 025, 026 · NFR-20-015 · EVT-20-11, EVT-20-04, EVT-03-10 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `CUTOVER` sẵn sàng; hai tỉnh trong cửa sổ bảo trì; `mod-sim` (PH-03) đọc API-20-164; `ops-sim`.

**Các bước.**

1. `POST P/merge-plans/{id}:cutover` với `confirmCode = {mã kế hoạch}`, `reason`, `ticketRef`, kèm `If-Match`, `Idempotency-Key`
2. `ops-sim` chạy lượt bù cuối, báo kiểm đếm khớp
3. `GET I/tenants/T91/enforcement` bằng `S-PH03`
4. `mod-sim` gọi địa chỉ cũ của `T91` qua chuyển tiếp
5. `mod-sim` báo EVT-03-10 xác nhận

**Kết quả mong đợi.** Bước 1 `202`, kế hoạch `TRANSITION`, `transitionEndsAt = hiện tại + 8 tháng` (theo kế hoạch đã sửa), phát EVT-20-11 và EVT-20-04. Bước 3 nguồn `MERGED`, `mergedInto = T90`, bảng chuyển tiếp `API_CONTEXT_PATH`. Bước 4 phản hồi từ `T90` kèm `Deprecation` và `Sunset = transitionEndsAt`. Bước 5 xác nhận chuyển tiếp bật được ghi (EVT-03-10). Ghi vào `T91` sau cutover bị chặn (xem TS-20-37).

:::

#### TC-20-129 · Cutover sai xác nhận, ngoài cửa sổ bảo trì, còn xung đột, lệch kiểm đếm <!--k:cutover-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-051 · API-20-106 · BR-20-024 · ERR-20-044, ERR-20-006, ERR-20-059, ERR-20-008, ERR-20-113, ERR-20-004, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `CUTOVER`; kế hoạch còn xung đột; ngoài cửa sổ bảo trì; `ops-sim` báo lượt bù lệch.

**Các bước.**

1. `:cutover` gõ sai `confirmCode`
2. `:cutover` thiếu `reason` hoặc `ticketRef`
3. `:cutover` ngoài cửa sổ bảo trì
4. `:cutover` khi còn xung đột; khi kế hoạch không ở trạng thái cho phép
5. Trong cửa sổ, lượt bù cuối lệch kiểm đếm
6. Thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004`. Bước 2 `422` `ERR-20-008`. Bước 3 `422` `ERR-20-059`. Bước 4 `409` `ERR-20-044`, `409` `ERR-20-006`. Bước 5 cutover dừng, `ERR-20-113`, nguồn bỏ chỉ đọc, kế hoạch giữ `IDENTITY_TRANSFER`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-130 · Tenant nguồn MERGED chỉ đọc và cảnh báo lỗi chuyển tiếp trên 1 % <!--k:cutover-merged-readonly-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-051, 066 · API-20-106, 164 · ERR-20-115 · UC-20-28 · NFR-20-015.

**Tiền điều kiện, dữ liệu.** Nguồn `T91` `MERGED` sau cutover; `mod-sim` đẩy 100 lượt chuyển tiếp trong 60 phút đầu, 2 lượt lỗi.

**Các bước.**

1. `U-T91-TA` ghi (`PATCH T/settings`)
2. `U-T91-TA` đọc lịch sử (`GET T/settings`)
3. Theo dõi 60 phút đầu của chuyển tiếp

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-115` ("Tỉnh đã sáp nhập vào T90. Dữ liệu chỉ còn để tra cứu."). Bước 2 `200`. Bước 3 tỷ lệ lỗi 2 % vượt 1 % thì cảnh báo PA, không tự quay lui.

**Thông báo hiển thị.** ERR-20-115: "Tỉnh đã sáp nhập vào T90. Dữ liệu chỉ còn để tra cứu."

:::

#### TC-20-131 · Không nhận xác nhận chuyển tiếp từ PH-03 sau 15 phút <!--k:cutover-redirect-timeout-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-20-051 · API-20-164 · EVT-03-10 · UC-20-28.

**Tiền điều kiện, dữ liệu.** Sau cutover; `mod-sim` không gửi EVT-03-10.

**Các bước.**

1. Chờ 15 phút (đồng hồ giả lập)

**Kết quả mong đợi.** Cảnh báo PO; chưa ghi xác nhận chuyển tiếp bật; cutover không bị hoàn tác.

:::

### TS-20-29 · Kết thúc sáp nhập sau thời gian chuyển tiếp

**Mục tiêu.** Gia hạn chuyển tiếp trong trần, nhắc 30, 7, 1 ngày, kết thúc đúng hạn hoặc sớm khi không còn `OLD_ONLY`; nguồn `DECOMMISSIONED`, kế hoạch `COMPLETED`.

**Phủ.** FR-20-052; UC-20-29; UI-20-10; API-20-107, 108.

#### TC-20-132 · Gia hạn chuyển tiếp trong trần 12 tháng và vượt trần <!--k:extend-transition-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-052 · UC-20-29 · API-20-107 · BR-20-025 · ERR-20-045, ERR-20-008, ERR-20-004, ERR-20-005, ERR-20-006, ERR-00-428 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `TRANSITION` đã 8 tháng; tham số `20.merge.transition-max-months = 12`.

**Các bước.**

1. `POST P/merge-plans/{id}:extend-transition` với `extendMonths = 2`, `reason`, `ticketRef`, kèm `If-Match`
2. Gia hạn thêm `extendMonths = 3`
3. Gia hạn thiếu `reason`
4. Gia hạn kế hoạch `COMPLETED`; thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `200`, `transitionEndsAt` dời hai tháng (tổng 10). Bước 2 `422` `ERR-20-045` ("Thời gian chuyển tiếp tối đa 12 tháng."). Bước 3 `422` `ERR-20-008`. Bước 4 `409` `ERR-20-006`, `428` `ERR-00-428`, `412` `ERR-20-005`. Header `Sunset` đổi theo.

:::

#### TC-20-133 · Kết thúc sáp nhập đúng hạn và sớm khi không còn OLD_ONLY <!--k:complete-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-052 · UC-20-29 · API-20-108 · BR-20-020, 025 · EVT-20-12, EVT-20-04 · UI-20-10 · `PERM-20-merge`.

**Tiền điều kiện, dữ liệu.** Kế hoạch `TRANSITION` đến hạn; `iam-sim` thu hồi client cũ; `obs-sim` (API-13-073); kế hoạch thứ hai kết thúc sớm.

**Các bước.**

1. Đồng hồ giả lập tới `transitionEndsAt`, theo dõi tự động
2. Kế hoạch thứ hai: `POST .../:complete` với `confirmCode` khi không còn HTTT `OLD_ONLY`
3. Gọi địa chỉ cũ của nguồn sau khi kết thúc

**Kết quả mong đợi.** Nguồn `DECOMMISSIONED`, kế hoạch `COMPLETED`, chuyển tiếp tắt (EVT-20-12), client cũ thu hồi, chuỗi kiểm toán nguồn đóng (API-13-073), dữ liệu nguồn chỉ đọc rồi xóa mật mã theo FR-20-042. Kết thúc sớm `202`. Bước 3 `410` `ERR-20-102`. PH-16 nhận EVT-20-12.

:::

#### TC-20-134 · Kết thúc khi chưa hết chuyển tiếp và còn HTTT dùng địa chỉ cũ <!--k:complete-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-052 · API-20-108 · ERR-20-046, ERR-20-004, ERR-20-005, ERR-20-006, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `TRANSITION` còn 3 tháng và 4 HTTT `OLD_ONLY`; kế hoạch `DRAFT`.

**Các bước.**

1. `POST .../:complete` khi còn `OLD_ONLY`
2. `:complete` sai `confirmCode`
3. `:complete` kế hoạch `DRAFT`
4. Thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-046` ("Chưa hết thời gian chuyển tiếp (đến 2027-05-27) và còn 4 HTTT dùng địa chỉ cũ."). Bước 2 `400` `ERR-20-004`. Bước 3 `409` `ERR-20-006`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`.

**Thông báo hiển thị.** ERR-20-046: "Chưa hết thời gian chuyển tiếp (đến 2027-05-27) và còn 4 HTTT dùng địa chỉ cũ."

:::

#### TC-20-135 · Nhắc 30, 7, 1 ngày trước khi hết chuyển tiếp <!--k:transition-remind-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-052 · UC-20-29 · BR-20-025.

**Tiền điều kiện, dữ liệu.** Kế hoạch `TRANSITION`; `ops-sim` thu thư; 3 HTTT `OLD_ONLY`.

**Các bước.**

1. Đồng hồ giả lập tới T-30, T-7, T-1 ngày
2. Một HTTT chuyển xong (`IN_USE_NEW`) trước T-7

**Kết quả mong đợi.** Ba đợt thư đến đầu mối đúng 3 HTTT còn `OLD_ONLY` (đợt T-7 và T-1 chỉ 2 HTTT sau khi một cái đã chuyển); mỗi đợt gửi một lần.

:::

### TS-20-30 · Quản lý danh mục tổ chức, nhập, xuất và chủ quản dữ liệu

**Mục tiêu.** TA tạo, sửa, xem cây tổ chức; nhập Excel, CSV có xem trước và xác nhận; xuất; đánh dấu và tra cứu chủ quản dữ liệu; mọi ghi phát EVT-20-13.

**Phủ.** FR-20-053, 055, 058; UC-20-30; UI-20-14, 15, 16; API-20-143…146, 152…156, 171.

#### TC-20-136 · Tạo, xem cây, xem bảng, sửa tổ chức <!--k:org-create-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-053 · UC-20-30 · API-20-143, 144, 145, 146 · BR-20-027, 028 · EVT-20-13 · UI-20-14, 15 · `PERM-20-org`, `PERM-20-org-read`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-VW`; F-ORG (`T90`); `kafka` thu EVT-20-13.

**Các bước.**

1. `POST T/organizations` với `orgCode = SO-KHCN2`, `name`, `orgType = DEPARTMENT`, `parentCode = UBND-TINH`, `adminUnitId`, `effectiveFrom`, kèm `Idempotency-Key`
2. `GET T/organizations?view=TREE`; `GET T/organizations?view=TABLE&q=KHCN`
3. `GET T/organizations/SO-KHCN2`
4. `PATCH T/organizations/SO-KHCN2` đổi `name`, `shortName`, kèm `If-Match`
5. `U-T90-VW` `GET T/organizations`

**Kết quả mong đợi.** Bước 1 `201`, `ACTIVE`, `ETag`, phát EVT-20-13 `CREATED`. Bước 2 cây hiện tổ chức mới dưới `UBND-TINH`; bảng có phân trang. Bước 4 `200`, EVT-20-13 `UPDATED`. Bước 5 `200` (mọi vai trò tỉnh xem được). Kiểm toán các thao tác ghi.

:::

#### TC-20-137 · Tạo, sửa tổ chức sai: mã, cha, chu trình, ĐVHC, hiệu lực, quyền <!--k:org-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-053 · API-20-144, 146 · BR-20-027 · ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-012, ERR-20-047, ERR-20-052, ERR-20-002, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-VW`; F-ORG; tổ chức `SO-TEST` đã `DISSOLVED`.

**Các bước.**

1. Tạo với `orgCode = so-khcn` (chữ thường) và một mã 51 ký tự
2. Tạo với `orgCode = SO-TEST` (đã giải thể)
3. Tạo với `parentCode` không tồn tại, và với cha `INACTIVE`
4. `PATCH` đổi cha của `UBND-TINH` thành con của chính nó (chu trình)
5. Tạo với `adminUnitId` không thuộc tỉnh; với `effectiveTo` trước `effectiveFrom`
6. `PATCH` thiếu `If-Match`; `If-Match` cũ; `GET T/organizations/KHONG-CO`
7. `U-T90-VW` `POST T/organizations`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004`. Bước 2 `409` `ERR-20-003`. Bước 3 `422` `ERR-20-047`. Bước 4 `422` `ERR-20-047` ("Tổ chức cấp trên UBND-TINH không hợp lệ: tạo chu trình."). Bước 5 `422` `ERR-20-012`, `422` `ERR-20-052`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`, `404` `ERR-20-002`. Bước 7 `403` `ERR-00-403`.

**Thông báo hiển thị.** ERR-20-047: "Tổ chức cấp trên UBND-TINH không hợp lệ: tạo chu trình."

:::

#### TC-20-138 · Xem cây theo ngày hiệu lực và đổi cha giữ lịch sử <!--k:org-asof-history-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-053 · API-20-143, 146 · BR-20-028 · UC-20-30.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; tổ chức `PB-A` con của `SO-KHCN`; ngày 2026-11-27.

**Các bước.**

1. `PATCH T/organizations/PB-A` đổi `parentCode` sang `SO-TTTT`, hiệu lực 2026-12-01
2. `GET T/organizations?view=TREE&asOf=2026-11-30`
3. `GET T/organizations?view=TREE&asOf=2026-12-02`

**Kết quả mong đợi.** `asOf` 2026-11-30 hiện `PB-A` dưới `SO-KHCN`; `asOf` 2026-12-02 hiện dưới `SO-TTTT`; lịch sử cha cũ còn lưu với hiệu lực.

:::

#### TC-20-139 · Nhập tổ chức: xem trước, xác nhận, ghi một giao dịch <!--k:org-import-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-055 · UC-20-30 · API-20-153, 154, 155 · BR-20-027 · EVT-20-13 · UI-20-16 · `PERM-20-org`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA` ở `T98`; F-ORG-IMP (tệp 5.000 dòng hợp lệ); `20.org.import-max-rows` mặc định.

**Các bước.**

1. `POST T/organization-imports` tải tệp 5.000 dòng, `mode = CREATE_ONLY`, kèm `Idempotency-Key`
2. `GET T/organization-imports/{importId}` đến khi `PREVIEW_READY`
3. `POST T/organization-imports/{importId}:confirm`
4. `GET T/organizations?view=TABLE` đếm

**Kết quả mong đợi.** Bước 1 `202`, `importId`. Bước 2 `summary`: 5.000 `CREATE`, 0 `ERROR`. Bước 3 `202`, ghi trong một giao dịch theo thứ tự cha trước con, phát một EVT-20-13 `BULK_IMPORT` có danh sách mã. Bước 4 thêm 5.000 tổ chức.

:::

#### TC-20-140 · Nhập tổ chức lỗi: tệp sai, quá dòng, dòng lỗi, lô hết hạn <!--k:org-import-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-055 · API-20-153, 154, 155 · ERR-20-050, ERR-20-051, ERR-20-006, ERR-20-009, ERR-20-004 · UI-20-16.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; F-ORG-IMP (tệp 40 dòng, 3 dòng lỗi); tệp `.pdf`; tệp `20.org.import-max-rows + 1` dòng; tệp > 10 MB.

**Các bước.**

1. Tải tệp `.pdf`, tệp quá số dòng, tệp quá 10 MB
2. Tải tệp 40 dòng có 3 dòng lỗi (mã trùng, cấp trên không tồn tại, ngày hiệu lực ngược)
3. `:confirm` lô còn dòng lỗi
4. `:confirm` lô đã quá 24 giờ (đồng hồ giả lập)
5. Tải lại bằng `Idempotency-Key` đã dùng cho tệp khác

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-050` ("Tệp nhập không hợp lệ: vượt quá số dòng cho phép."). Bước 2 `summary`: 3 `ERROR` kèm `rowNo`, `errors[]` từng dòng. Bước 3 `422` `ERR-20-051` ("Còn 3 dòng lỗi. Sửa tệp rồi tải lại."), không ghi gì. Bước 4 `409` `ERR-20-006`. Bước 5 `409` `ERR-20-009`.

**Thông báo hiển thị.** ERR-20-051: "Còn 3 dòng lỗi. Sửa tệp rồi tải lại."

:::

#### TC-20-141 · Nhập UPSERT: sinh CREATE, UPDATE, UNCHANGED <!--k:org-import-upsert-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-055 · API-20-153, 154, 155 · UC-20-30.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; F-ORG; tệp 10 dòng: 4 mới, 3 sửa tên, 3 giống hệt.

**Các bước.**

1. Tải với `mode = UPSERT`, xem trước, xác nhận

**Kết quả mong đợi.** `summary`: 4 `CREATE`, 3 `UPDATE`, 3 `UNCHANGED`; sau xác nhận chỉ 7 dòng đổi, phát một EVT-20-13 gộp.

:::

#### TC-20-142 · Xuất tổ chức XLSX, CSV theo bộ lọc <!--k:org-export-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-055 · API-20-156 · UI-20-14 · `PERM-20-org-read`.

**Tiền điều kiện, dữ liệu.** `U-T90-VW`; F-ORG; tổ chức đã `DISSOLVED` có kế thừa.

**Các bước.**

1. `GET T/organizations:export?format=xlsx&status=ACTIVE`
2. `GET T/organizations:export?format=csv`
3. `GET T/organizations:export?format=pdf`

**Kết quả mong đợi.** Bước 1, 2 tệp theo bộ lọc, có cột trạng thái, kế thừa, mã hóa UTF-8; chỉ tổ chức của `T90`. Bước 3 `400` `ERR-20-004`.

:::

#### TC-20-143 · Đánh dấu và bỏ đánh dấu chủ quản dữ liệu, tra cứu hàng loạt <!--k:data-owner-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-058 · UC-20-30 · API-20-152, 171 · ERR-20-049, ERR-20-006, ERR-20-062, ERR-20-005, ERR-00-428 · EVT-20-13 · `PERM-20-org`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `SO-KHCN` `ACTIVE`; `org-reader-sim` (`S-PH01`); `mod-sim` PH-06, PH-08 trả 3 đối tượng đang giao cho `SO-KHCN`; `SO-OLD` `INACTIVE`.

**Các bước.**

1. `PUT T/organizations/SO-KHCN/data-owner` với `isDataOwner = true`, `dataDomains`, `reason`, kèm `If-Match`
2. `S-PH01` `POST I/organizations:lookup` với `isDataOwner = true`
3. `PUT` bỏ đánh dấu `SO-KHCN` khi còn 3 đối tượng
4. `PUT` đánh dấu `SO-OLD` (`INACTIVE`)
5. `PUT` khi PH-06 trả `503`
6. `PUT` thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `200`, EVT-20-13 `DATA_OWNER`. Bước 2 trả `SO-KHCN`. Bước 3 `409` `ERR-20-049` ("Tổ chức SO-KHCN còn 3 đối tượng tham chiếu. Chọn tổ chức kế thừa."). Bước 4 `409` `ERR-20-006`. Bước 5 `503` `ERR-20-062`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

### TS-20-31 · Giải thể, hợp nhất tổ chức và đồng bộ khi sắp xếp ĐVHC

**Mục tiêu.** Ngừng, hoạt động lại, giải thể, hợp nhất tổ chức kèm kế thừa; nhận sự kiện sắp xếp ĐVHC sinh đề xuất, TA áp hoặc bỏ; tra lịch sử.

**Phủ.** FR-20-054, 056; UC-20-31; UI-20-14, 15; API-20-147…151, 157, 158.

#### TC-20-144 · Giải thể tổ chức có kế thừa, chuyển cha tổ chức con <!--k:org-dissolve-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-054 · UC-20-31 · API-20-149, 151 · BR-20-028 · EVT-20-13 · UI-20-15 · `PERM-20-org`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `SO-A` có 2 tổ chức con, 5 HTTT (PH-01), 12 người dùng (PH-12); `SO-B` `ACTIVE`; `mod-sim` trả số tham chiếu.

**Các bước.**

1. `POST T/organizations/SO-A:dissolve` với `effectiveTo`, `successorCode = SO-B`, `decisionDocNo`, `decisionDocDate`, `reason`, kèm `If-Match`
2. `GET T/organizations/SO-A/history`
3. Kiểm hai tổ chức con

**Kết quả mong đợi.** Bước 1 `200`, `SO-A` `DISSOLVED`, `successor = SO-B`, danh sách con đã chuyển cha; EVT-20-13 `DISSOLVED` kèm `successorCode`; PH-01 tạo đề nghị đổi chủ quản chờ TA duyệt hàng loạt. Bước 2 có bản ghi lịch sử. Bước 3 cha mới là `SO-B`.

:::

#### TC-20-145 · Giải thể thiếu kế thừa, kế thừa sai, trạng thái cuối, PH lỗi <!--k:org-dissolve-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-054 · API-20-149 · ERR-20-049, ERR-20-048, ERR-20-006, ERR-20-062, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `SO-A` còn 5 tham chiếu; `SO-C` `DISSOLVED`; `SO-D` ở `T91`.

**Các bước.**

1. `:dissolve` `SO-A` không có `successorCode`
2. `:dissolve` với kế thừa chính nó; kế thừa `SO-C` (không `ACTIVE`); kế thừa `SO-D` của tenant khác
3. `:dissolve` `SO-C` (đã giải thể)
4. `:dissolve` khi PH-01 không trả lời số tham chiếu
5. Thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-049`. Bước 2 `422` `ERR-20-048` cả ba trường hợp (kế thừa tenant khác nhận `404` hoặc `422` theo hợp đồng, không lộ tồn tại; ghi nhận ở bản chạy). Bước 3 `409` `ERR-20-006`. Bước 4 `503` `ERR-20-062`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-146 · Hợp nhất hai tổ chức vào tổ chức đích có sẵn và tổ chức đích mới <!--k:org-merge-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-054 · API-20-150, 151 · BR-20-028 · EVT-20-13 · UC-20-31.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `SO-E`, `SO-F` `ACTIVE` có tham chiếu; đích `SO-EF` chưa có.

**Các bước.**

1. `POST T/organizations:merge` với `sourceCodes = [SO-E, SO-F]`, `targetCode = SO-EF`, tạo mới, `decisionDocNo`, `reason`
2. Hợp nhất `SO-G` vào `SO-B` có sẵn

**Kết quả mong đợi.** Bước 1 `200`, `SO-EF` `ACTIVE`, nguồn `MERGED` với `successor = SO-EF`, EVT-20-13 `MERGED`. Bước 2 tương tự với đích có sẵn. Tổ chức con chuyển cha sang đích.

:::

#### TC-20-147 · Hợp nhất sai: nguồn trùng đích, nguồn không hoạt động, thiếu văn bản <!--k:org-merge-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-054 · API-20-150 · ERR-20-004, ERR-20-048, ERR-20-006, ERR-20-002.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `SO-E` `ACTIVE`; `SO-C` `DISSOLVED`.

**Các bước.**

1. Hợp nhất với `targetCode` nằm trong `sourceCodes`
2. Hợp nhất nguồn `SO-C`
3. Hợp nhất thiếu `reason` hoặc `sourceCodes` rỗng
4. Hợp nhất nguồn `KHONG-CO`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-048`. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `404` `ERR-20-002`. Không tổ chức nào đổi.

:::

#### TC-20-148 · Ngừng và hoạt động lại tổ chức <!--k:org-deactivate-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-054 · API-20-147, 148 · ERR-20-006, ERR-20-005, ERR-00-428 · EVT-20-13.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `SO-H` `ACTIVE`; `SO-C` `DISSOLVED`.

**Các bước.**

1. `POST T/organizations/SO-H:deactivate` với `reason`, kèm `If-Match`
2. `POST .../SO-H:reactivate`
3. `:reactivate` `SO-C`; `:deactivate` `SO-H` đã `INACTIVE`
4. Thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `INACTIVE`, không cần kế thừa. Bước 2 về `ACTIVE`; mỗi lần phát EVT-20-13. Bước 3 `409` `ERR-20-006`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-149 · Xem lịch sử tổ chức, tổ chức tenant khác <!--k:org-history-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-20-054 · API-20-151 · ERR-20-002 · UI-20-15.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T91-TA`; `SO-A` đã giải thể.

**Các bước.**

1. `U-T90-TA` `GET T/organizations/SO-A/history`
2. `U-T91-TA` `GET T/organizations/SO-A/history`

**Kết quả mong đợi.** Bước 1 các bản ghi theo thời gian (cha, tên, trạng thái, kế thừa). Bước 2 `404` `ERR-20-002`.

:::

#### TC-20-150 · Sự kiện sắp xếp ĐVHC sinh đề xuất; TA áp và bỏ <!--k:sync-adminunit-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-056 · UC-20-31 · API-20-157, 158 · BR-20-028 · EVT-20-13 · UI-20-14 · `PERM-20-org` · BR-20-029.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; `rdm-sim` phát EVT-07-10 gộp hai xã A, B thành xã C hiệu lực 2026-12-01; `T90` có tổ chức `UBND-A`, `UBND-B`; `T91` không có tổ chức liên quan.

**Các bước.**

1. `rdm-sim` phát EVT-07-10 (hai lần cùng `eventId`)
2. `GET T/organization-sync-proposals?status=PENDING`
3. `POST .../{p1}:decide` với `decision = APPLY`, sửa tên, mã tổ chức mới `UBND-C`
4. `POST .../{p2}:decide` với `decision = DISMISS`, `reason`

**Kết quả mong đợi.** Bước 1 inbox lũy đẳng: chỉ một bộ đề xuất cho `T90`, không có đề xuất cho `T91`. Bước 2 hai đề xuất: tạo `UBND-C`, giải thể `UBND-A`, `UBND-B` kế thừa `UBND-C`. Bước 3 `200`, chạy như FR-20-054, EVT-20-13. Bước 4 `DISMISSED` có lý do.

:::

#### TC-20-151 · Áp đề xuất khi còn tham chiếu, đề xuất đã xử lý, tự áp dụng trước <!--k:sync-adminunit-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** IT, API.

**Truy vết.** FR-20-056 · API-20-158, 157 · ERR-20-049, ERR-20-006, ERR-20-004, ERR-20-002.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; đề xuất `p3` áp dụng làm giải thể tổ chức còn 4 tham chiếu mà kế thừa chưa hợp lệ; `p1` đã `APPLIED`; tỉnh đã tự giải thể `UBND-D` trước sự kiện.

**Các bước.**

1. `:decide` `p3` `APPLY` với kế thừa không hợp lệ
2. `:decide` `p1` lần nữa
3. `:decide` với `decision = XOA`; mã `p-khong-co`
4. Nhận sự kiện cho `UBND-D` đã tự giải thể

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-049`. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`, `404` `ERR-20-002`. Bước 4 đề xuất tự đánh dấu `ALREADY_APPLIED`.

:::

### TS-20-32 · Quản lý phiên bản sản phẩm và kênh phát hành

**Mục tiêu.** Đăng ký phiên bản SemVer có chữ ký, sửa tới trước `PREVIEW`, đưa lên `PREVIEW` và `STABLE` sau soak 14 ngày, ngừng hỗ trợ, rút; đổi kênh đăng ký của tenant.

**Phủ.** FR-20-059, 060; UC-20-32; UI-20-03, 18; API-20-001, 109…117.

#### TC-20-152 · Đăng ký phiên bản, sửa ghi chú, xem danh sách và chi tiết <!--k:rel-create-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-059 · UC-20-32 · API-20-109, 110, 111, 112 · BR-20-034 · UI-20-18 · `PERM-20-release` · BR-20-030.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-REL; ảnh có chữ ký và SBOM (bản giả hợp đồng CI).

**Các bước.**

1. `POST P/releases` với `releaseVersion = 2.4.1`, `components[]` (`du`, `image`, `digest`), `schemaChanges = [{module, kind = EXPAND}]`, `releaseNotes`, `minFromVersion = 2.3.0`, kèm `Idempotency-Key`
2. `GET P/releases?status=DRAFT`
3. `GET P/releases/2.4.1`
4. `PATCH P/releases/2.4.1` đổi `releaseNotes`, kèm `If-Match`

**Kết quả mong đợi.** Bước 1 `201`, `DRAFT`. Bước 2 có `2.4.1` và `2.4.0-rc.1`. Bước 3 có cột số tenant đang chạy (0). Bước 4 `200`. Kiểm toán.

:::

#### TC-20-153 · Phiên bản không hợp lệ, trùng, chữ ký thiếu, sửa sau PREVIEW <!--k:rel-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-059 · API-20-110, 112 · ERR-20-053, ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-005, ERR-00-428 · BR-20-030.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; F-REL (`2.4.0` `PREVIEW`, `2.3.1` `STABLE`); thành phần có digest không có chữ ký cosign.

**Các bước.**

1. `POST P/releases` với `releaseVersion = 2.4` (không đúng SemVer)
2. `POST` với `2.3.0` nhỏ hơn bản cùng dòng đã có `2.3.1`
3. `POST` với `2.3.1` (đã tồn tại)
4. `POST` với thành phần thiếu chữ ký
5. `PATCH 2.4.0` đổi thành phần sau `PREVIEW`
6. `PATCH 2.4.1` thiếu `If-Match`; `If-Match` cũ
7. `U-PO` `POST P/releases`

**Kết quả mong đợi.** Bước 1, 4 `422` `ERR-20-053` ("Phiên bản sản phẩm 2.4 không hợp lệ: không đúng SemVer."). Bước 2 `422` `ERR-20-053` (không lớn hơn bản cùng dòng). Bước 3 `409` `ERR-20-003`. Bước 5 `409` `ERR-20-006`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 7 `403` `ERR-00-403`. Bước 1 với `releaseVersion` thiếu trường: `400` `ERR-20-004`.

**Thông báo hiển thị.** ERR-20-053: "Phiên bản sản phẩm 2.4 không hợp lệ: không đúng SemVer."

:::

#### TC-20-154 · Đưa lên PREVIEW rồi STABLE sau 14 ngày thí điểm <!--k:rel-preview-promote-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-060 · UC-20-32 · API-20-113, 114 · BR-20-031 · EVT-20-14 · UI-20-18 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `2.4.1` `DRAFT` đủ thành phần; đồng hồ giả lập; không sự cố mức 1.

**Các bước.**

1. `POST P/releases/2.4.1:preview` kèm `If-Match`
2. Tiến đồng hồ 14 ngày; `POST P/releases/2.4.1:promote` kèm `If-Match`
3. `GET P/releases/2.4.1`

**Kết quả mong đợi.** Bước 1 `200`, `PREVIEW`, EVT-20-14. Bước 2 `200`, `STABLE`, EVT-20-14 thứ hai. Bước 3 trạng thái `STABLE`, mốc `stableAt`.

:::

#### TC-20-155 · Promote khi chưa đủ 14 ngày, có sự cố mức 1, sai trạng thái <!--k:rel-promote-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-060 · API-20-113, 114 · BR-20-031 · ERR-20-054, ERR-20-006, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `2.4.0` `PREVIEW` mới 9 ngày; `2.4.2` `PREVIEW` đủ 15 ngày nhưng có sự cố mức 1 gắn phiên bản; `2.4.1` `DRAFT`.

**Các bước.**

1. `:promote` `2.4.0` (mới 9 ngày)
2. `:promote` `2.4.2` (sự cố mức 1)
3. `:promote` `2.4.1` đang `DRAFT`
4. `:preview` `2.4.0` đã `PREVIEW`
5. `:promote` thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-054` ("Phiên bản 2.4.0 mới thí điểm 9 ngày, cần tối thiểu 14 ngày và không có sự cố mức 1."). Bước 2 `422` `ERR-20-054`. Bước 3, 4 `409` `ERR-20-006`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`.

**Thông báo hiển thị.** ERR-20-054: "Phiên bản 2.4.0 mới thí điểm 9 ngày, cần tối thiểu 14 ngày và không có sự cố mức 1."

:::

#### TC-20-156 · Bản vá khẩn lên STABLE sau 1 ngày khi PO duyệt <!--k:rel-emergency-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-060 · API-20-114 · BR-20-031 · ERR-20-054 · UC-20-32.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; bản vá `2.3.2` `PREVIEW` mới 1 ngày, cờ `emergency = true`.

**Các bước.**

1. `U-PA1` `:promote` `2.3.2` không có duyệt của PO
2. `U-PO` xác nhận khẩn, rồi `U-PA1` `:promote`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-054`. Bước 2 `200`, `STABLE` sau ≥ 1 ngày.

:::

#### TC-20-157 · Ngừng hỗ trợ và rút phiên bản lỗi <!--k:rel-deprecate-withdraw-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-059 · API-20-115, 116 · BR-20-034 · ERR-20-006, ERR-20-004, ERR-20-005, ERR-00-428 · EVT-20-14.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-REL (`2.1.0` `DEPRECATED`, `2.2.0` `STABLE`); `20.release.supported-minors = 2`.

**Các bước.**

1. `POST P/releases/2.2.0:deprecate` với `reason`, kèm `If-Match`
2. `POST P/releases/2.4.0:withdraw` với `reason`
3. Lập kế hoạch nâng cấp lên bản `WITHDRAWN`
4. `:deprecate` bản đã `DEPRECATED`; `:withdraw` thiếu `reason`

**Kết quả mong đợi.** Bước 1 `DEPRECATED` (ngoài 2 bản phụ hỗ trợ). Bước 2 `WITHDRAWN`, không tenant mới nâng lên. Bước 3 `422` `ERR-20-055`. Bước 4 `409` `ERR-20-006`, `400` `ERR-20-004`.

:::

#### TC-20-158 · Đổi kênh đăng ký của tenant, và khi đang có kế hoạch nâng cấp <!--k:rel-subscription-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-060 · API-20-117 · ERR-20-061, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-002, ERR-00-428 · UI-20-03 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T93` kênh `STABLE`, không kế hoạch; `T92` có kế hoạch `RUNNING`; `T90` PROVINCE (cần lý do, phiếu).

**Các bước.**

1. `PUT P/tenants/T93/release-subscription` với `channel = PREVIEW`, `environment`, `reason`, kèm `If-Match`
2. `PUT .../T92/release-subscription` đổi kênh
3. `PUT` với `channel = KHAC`
4. `PUT` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ; tenant `T00-KHONG-CO`

**Kết quả mong đợi.** Bước 1 `200`, `release.yaml` ghi kênh mới. Bước 2 `409` `ERR-20-061` ("Tenant T92 đang có kế hoạch nâng cấp PL-2026-001. Đổi kênh sau khi kế hoạch kết thúc."). Bước 3 `400` `ERR-20-004`. Bước 4 `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`, `404` `ERR-20-002`.

**Thông báo hiển thị.** ERR-20-061: "Tenant T92 đang có kế hoạch nâng cấp PL-2026-001. Đổi kênh sau khi kế hoạch kết thúc."

:::

### TS-20-33 · Lập kế hoạch nâng cấp theo sóng và thông báo lịch bảo trì

**Mục tiêu.** Lập kế hoạch theo sóng (PREVIEW trước, sóng 2 tối đa 5 tenant nhỏ, sóng 3 phần còn lại), sửa, lên lịch tính theo cửa sổ bảo trì, thông báo tỉnh trước 72 giờ; bản khẩn thông báo trước tối thiểu 2 giờ.

**Phủ.** FR-20-061, 063; UC-20-33; UI-20-12, 19; API-20-118…121, 128, 160.

#### TC-20-159 · Lập kế hoạch nâng cấp ba sóng, sửa, xem <!--k:plan-create-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-061 · UC-20-33 · API-20-118, 119, 120 · BR-20-032, 033 · UI-20-19 · `PERM-20-release` · `20.release.wave-soak-hours-patch`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; F-REL (`2.3.1` `STABLE`); sóng `T90`; `T91`, `T92`; `T93` (F-REL); mọi tenant chạy bản ≥ `minFromVersion`.

**Các bước.**

1. `POST P/releases/2.3.1/upgrade-plans` không có `waves[]` (hệ thống gợi ý), kèm `Idempotency-Key`
2. `POST` với `waves[]` tự chọn: sóng 1 `T90`; sóng 2 `T91`, `T92`; sóng 3 `T93`; `soakHours` mặc định
3. `GET P/upgrade-plans/{planId}`
4. `PATCH P/upgrade-plans/{planId}` đổi tenant sóng 3, kèm `If-Match`

**Kết quả mong đợi.** Bước 1 `201`, gợi ý: sóng 1 tenant kênh `PREVIEW`, sóng 2 tối đa 5 tenant nhỏ, sóng 3 phần còn lại. Bước 2 `201`, `DRAFT`, `soakHours` 48 (bản phụ) hoặc 24 (bản vá). Bước 3 lịch từng tenant. Bước 4 `200`.

:::

#### TC-20-160 · Kế hoạch không hợp lệ: tenant ở hai kế hoạch, bản không dùng được, dưới minFromVersion <!--k:plan-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-061 · API-20-118, 120 · ERR-20-056, ERR-20-055, ERR-20-004, ERR-20-006, ERR-20-005, ERR-20-002, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T92` đã trong kế hoạch khác; `2.4.0-rc.1` `DRAFT`; `T94` chạy bản 2.0.0 nhỏ hơn `minFromVersion`.

**Các bước.**

1. `POST .../2.3.1/upgrade-plans` có `T92` ở hai sóng
2. `POST` có `T92` đang thuộc kế hoạch khác
3. `POST` có `T94` dưới `minFromVersion`
4. `POST .../2.4.0-rc.1/upgrade-plans` (bản `DRAFT`); `POST .../2.0.0/...` không có
5. `PATCH` kế hoạch đang `RUNNING`; thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1, 2, 3 `422` `ERR-20-056` ("Kế hoạch nâng cấp không hợp lệ: T92 đã thuộc kế hoạch khác."). Bước 4 `422` `ERR-20-055`, `404` `ERR-20-002`. Bước 5 `409` `ERR-20-006`, `428` `ERR-00-428`, `412` `ERR-20-005`. Thiếu `waves[]` và `waveNo` sai kiểu `400` `ERR-20-004`.

**Thông báo hiển thị.** ERR-20-056: "Kế hoạch nâng cấp không hợp lệ: T92 đã thuộc kế hoạch khác."

:::

#### TC-20-161 · Lên lịch: thời điểm mỗi tenant là cửa sổ đầu tiên sau soak của sóng trước <!--k:plan-schedule-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-061, 063 · UC-20-33 · API-20-121, 119 · BR-20-032, 033 · EVT-20-15 · UI-20-19 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `DRAFT` ba sóng; `20.release.wave-soak-hours-minor = 48`; cửa sổ `T90` thứ Bảy 22:00 (3 giờ), `T91` thứ Bảy 23:00 (2 giờ), `T92` mặc định; đồng hồ giả lập thứ Tư.

**Các bước.**

1. `POST P/upgrade-plans/{planId}:schedule` với `startAfter`, kèm `If-Match`
2. `GET P/upgrade-plans/{planId}/tenant-upgrades`

**Kết quả mong đợi.** Bước 1 `200`, `SCHEDULED`, EVT-20-15, thông báo (FR-20-063) được kích hoạt. Bước 2 `T90` thứ Bảy gần nhất 22:00; sóng 2 là cửa sổ đầu tiên sau khi sóng 1 hết 48 giờ theo dõi, tức thứ Bảy kế tiếp (không sớm hơn 48 giờ sau xong sóng 1); sóng 3 sau sóng 2 cùng quy tắc.

:::

#### TC-20-162 · Lên lịch sai trạng thái, cửa sổ trùng giờ cao điểm <!--k:plan-schedule-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-061 · API-20-121 · ERR-20-006, ERR-20-059, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch đã `SCHEDULED`; kế hoạch `DRAFT` có tenant cửa sổ cài sai trùng giờ cao điểm.

**Các bước.**

1. `:schedule` kế hoạch đã `SCHEDULED`
2. `:schedule` kế hoạch có tenant cửa sổ thứ Tư 09:00 (giờ cao điểm 7:00–17:00 ngày làm việc)
3. `:schedule` thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-059` ("Cửa sổ bảo trì không hợp lệ: trùng giờ cao điểm."). Bước 3 `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-163 · Nâng cấp khẩn bỏ chờ cửa sổ, báo trước tối thiểu 2 giờ <!--k:plan-emergency-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-061, 063 · API-20-118, 121, 128 · BR-20-033 · ERR-20-004 · UC-20-33.

**Tiền điều kiện, dữ liệu.** `U-PA1`; bản vá bảo mật `2.3.2` `STABLE`; `20.upgrade.emergency-notice-hours = 2`; `ops-sim`.

**Các bước.**

1. `POST .../2.3.2/upgrade-plans` với `emergency = true`; `:schedule` với `startAfter` sau 1 giờ
2. `:schedule` với `startAfter` sau 3 giờ

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004` hoặc `422` `ERR-20-056` (báo trước dưới 2 giờ; ghi nhận ở Phụ lục đề nghị về mã lỗi). Bước 2 `200`, bỏ chờ cửa sổ, thông báo gửi ngay nêu lý do.

:::

#### TC-20-164 · Thông báo phát hành và lịch bảo trì, banner 72 giờ trước <!--k:announce-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-063 · UC-20-33 · API-20-128 · UI-20-12, 19 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `SCHEDULED`; `ops-sim` (NotificationApi); `U-T90-TA`.

**Các bước.**

1. `POST P/releases/2.3.1:announce` với `planId`, `audience = TA`, `message`
2. `POST ...:announce` với `audience = ALL_USERS`
3. Kiểm banner tại `dh-console` của `T90` ở 73 giờ và 71 giờ trước lịch

**Kết quả mong đợi.** Bước 1 `202`, thư và thông báo trong ứng dụng gửi tới TA, ghi trạng thái gửi. Bước 2 gửi mọi người dùng tỉnh. Bước 3 banner chỉ hiện từ 72 giờ trước.

:::

#### TC-20-165 · Thông báo khi PH-18 lỗi, kế hoạch chưa lên lịch <!--k:announce-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** IT, API.

**Truy vết.** FR-20-063 · API-20-128 · ERR-20-062, ERR-20-006, ERR-20-004, ERR-20-002.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `ops-sim` `503`; kế hoạch `DRAFT`.

**Các bước.**

1. `:announce` khi `ops-sim` `503`
2. `:announce` kế hoạch `DRAFT`
3. `:announce` với `audience = KHAC`; bản không có

**Kết quả mong đợi.** Bước 1 `503` `ERR-20-062` ("Dịch vụ PH-18 tạm thời không khả dụng. Thử lại sau."), trạng thái gửi `FAILED` thử lại được. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`, `404` `ERR-20-002`.

:::

#### TC-20-166 · TA đặt cửa sổ bảo trì ngoài giờ cao điểm, áp cho kế hoạch lập sau <!--k:window-set-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-061, 064 · API-20-160, 159 · BR-20-033 · UI-20-12 · `PERM-20-settings`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`; kế hoạch của `T90` đã `SCHEDULED` với cửa sổ cũ.

**Các bước.**

1. `PUT T/maintenance-window` với `dayOfWeek = SATURDAY`, `startTime = 22:00`, `durationHours = 4`
2. `GET T/release-info`

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 cửa sổ hiện hành mới; kế hoạch `SCHEDULED` không đổi, chỉ kế hoạch lập sau dùng cửa sổ mới.

:::

### TS-20-34 · Theo dõi nâng cấp, dừng sóng và quay lui

**Mục tiêu.** Chạy nâng cấp theo sóng với banner bảo trì, kiểm tra sau nâng cấp; dừng sóng khi lỗi vượt 2 % hoặc có tenant `FAILED`; tiếp tục chỉ sau xác nhận; quay lui bị chặn khi có thay đổi `CONTRACT`; PO chỉ theo dõi và dừng sóng.

**Phủ.** FR-20-062; UC-20-34; UI-20-19; API-20-119, 122…127.

#### TC-20-167 · Nâng cấp sóng 1 và 2 thành công, kiểm tra sau nâng cấp đạt <!--k:upg-run-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-20-062 · UC-20-34 · API-20-119, 126 · BR-20-032, 033 · EVT-20-15 · ERR-20-118 · UI-20-19 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** STAGING; kế hoạch `SCHEDULED` ba sóng (F-REL); `git-sim`, `argo-sim` `Synced`; bộ smoke giả đạt; `20.release.verify-minutes = 30`.

**Các bước.**

1. Đồng hồ giả lập tới cửa sổ của `T90`
2. Trong lúc nâng cấp, `U-T90-TA` gọi một thao tác ghi (`PUT T/settings`) và một thao tác đọc
3. Chờ `argo-sim` `Synced` và bộ smoke chạy
4. `GET P/upgrade-plans/{planId}/tenant-upgrades`
5. Sóng 1 xong, theo dõi 48 giờ, sóng 2 bắt đầu

**Kết quả mong đợi.** Bước 1 kế hoạch `RUNNING`, `T90` `UPGRADING`, banner bảo trì, `release.yaml` ghi phiên bản. Bước 2 ghi `503` `ERR-20-118` ("Tỉnh đang bảo trì nâng cấp đến 02:00. Thao tác ghi tạm dừng."), đọc `200`. Bước 3 kiểm tra đạt, `T90` `DONE`, bỏ banner. Bước 4 trạng thái từng tenant. Bước 5 sóng 2 chỉ bắt đầu sau 48 giờ theo dõi sóng 1. Phát EVT-20-15 theo từng thay đổi.

**Thông báo hiển thị.** ERR-20-118: "Tỉnh đang bảo trì nâng cấp đến 02:00. Thao tác ghi tạm dừng."

:::

#### TC-20-168 · Sóng dừng khi tỷ lệ 5xx vượt 2 % hoặc có tenant FAILED <!--k:upg-wave-stop-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-062 · UC-20-34 · API-20-119, 123, 126 · BR-20-032 · ERR-20-057, ERR-20-112, ERR-20-109 · EVT-20-15 · NFR-20-016.

**Tiền điều kiện, dữ liệu.** Kế hoạch `RUNNING` sóng 2 gồm `T91`, `T92`; `mod-sim` đẩy tỷ lệ 5xx của sóng; `20.release.wave-error-threshold-percent = 2`.

**Các bước.**

1. Cho tỷ lệ 5xx của sóng 2 bằng 2,0 % (đúng ngưỡng)
2. Cho tỷ lệ 5xx lên 2,1 %
3. Với sóng 2 khác: bộ smoke của `T92` báo 3 ca lỗi
4. `POST P/upgrade-plans/{planId}:resume` khi sóng dừng, chưa xác nhận
5. Với sóng khác: `argo-sim` trả `Degraded` cho `T91`

**Kết quả mong đợi.** Bước 1 không dừng (`>` mới dừng). Bước 2 sóng dừng, kế hoạch `PAUSED`, cảnh báo PA, sóng 3 không chạy. Bước 3 `T92` `FAILED` với `ERR-20-112` ("Kiểm tra sau nâng cấp của T92 không đạt: 3 ca lỗi."), sóng dừng. Bước 4 `409` `ERR-20-057` ("Sóng 2 đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục."). Bước 5 `ERR-20-109` ghi vào tiến trình.

**Thông báo hiển thị.** ERR-20-057: "Sóng 2 đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục."

:::

#### TC-20-169 · Dừng tay và tiếp tục sóng, PO dừng được nhưng không tiếp tục <!--k:upg-pause-resume-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-062 · API-20-122, 123 · BR-20-032 · ERR-20-006, ERR-20-004, ERR-20-005, ERR-20-007, ERR-00-428 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; kế hoạch `RUNNING`; kế hoạch `COMPLETED`.

**Các bước.**

1. `U-PO` `POST P/upgrade-plans/{planId}:pause` với `reason`, `ticketRef`
2. `U-PA1` `:resume` sau khi xử lý
3. `:pause` kế hoạch đã `COMPLETED`; `:resume` kế hoạch `RUNNING` (không dừng)
4. `:pause` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
5. `U-PO` `:resume`

**Kết quả mong đợi.** Bước 1 `200`, `PAUSED`. Bước 2 `200`, `RUNNING`. Bước 3 `409` `ERR-20-006`. Bước 4 `400` `ERR-20-004`, `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 5 `403` `ERR-00-403` (PO chỉ theo dõi và dừng sóng; ghi nhận theo UC).

:::

#### TC-20-170 · Quay lui tenant đã nâng cấp khi chỉ có thay đổi EXPAND <!--k:upg-rollback-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-20-062 · UC-20-34 · API-20-124, 119 · BR-20-032 · EVT-20-15 · UI-20-19 · `PERM-20-release`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch `PAUSED`, `T91` `DONE` ở `2.4.0` (thay đổi lược đồ chỉ `EXPAND`), phiên bản trước `2.3.1`.

**Các bước.**

1. `POST P/upgrade-plans/{planId}:rollback` với `tenantCodes = [T91]`, `reason`, `ticketRef`
2. Chờ `argo-sim` đồng bộ và kiểm tra
3. `GET P/upgrade-plans/{planId}/tenant-upgrades?status=ROLLED_BACK`

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 `release.yaml` ghi lại `2.3.1`, banner bảo trì tạm, kiểm tra đạt. Bước 3 `T91` `ROLLED_BACK`. EVT-20-15.

:::

#### TC-20-171 · Quay lui bị chặn khi có CONTRACT, sai trạng thái, thiếu phiếu <!--k:upg-rollback-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-062 · API-20-124 · ERR-20-058, ERR-20-006, ERR-20-004, ERR-20-009, ERR-20-005, ERR-00-428.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch của bản có `schemaChanges` kind `CONTRACT`; `T92` `PENDING` (chưa nâng cấp); `Idempotency-Key` đã dùng.

**Các bước.**

1. `:rollback` `T90` của bản có `CONTRACT`
2. `:rollback` `T92` chưa nâng cấp
3. `:rollback` thiếu `ticketRef`, `tenantCodes` rỗng
4. `:rollback` dùng lại `Idempotency-Key` cho yêu cầu khác
5. Thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-058` ("Không quay lui được phiên bản 2.4.0 vì có thay đổi lược đồ không tương thích ở PH-02."). Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `409` `ERR-20-009`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`.

**Thông báo hiển thị.** ERR-20-058: "Không quay lui được phiên bản 2.4.0 vì có thay đổi lược đồ không tương thích ở PH-02."

:::

#### TC-20-172 · Hủy kế hoạch chưa chạy và không hủy khi đang chạy <!--k:upg-cancel-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-062 · API-20-125 · ERR-20-006, ERR-20-004, ERR-20-005, ERR-00-428 · UC-20-34.

**Tiền điều kiện, dữ liệu.** `U-PA1`; kế hoạch A `SCHEDULED`; kế hoạch B `RUNNING`.

**Các bước.**

1. `:cancel` A với `reason`
2. `:cancel` B
3. `:cancel` A lần nữa; thiếu `reason`; thiếu `If-Match`; `If-Match` cũ

**Kết quả mong đợi.** Bước 1 `CANCELLED`, thông báo hủy gửi tỉnh. Bước 2 `409` `ERR-20-006` (đang chạy thì dừng rồi quay lui, không hủy). Bước 3 `409` `ERR-20-006`, `400` `ERR-20-004`, `428` `ERR-00-428`, `412` `ERR-20-005`.

:::

#### TC-20-173 · Thử lại nâng cấp của một tenant lỗi <!--k:upg-retry-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-20-062 · API-20-127, 126 · ERR-20-006, ERR-20-057, ERR-20-004, ERR-20-002, ERR-20-058.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T92` `FAILED` ở sóng 2, kế hoạch `PAUSED` do ngưỡng; `T93` `PENDING`.

**Các bước.**

1. `POST .../tenant-upgrades/T92:retry` khi sóng chưa được xác nhận
2. Xác nhận xử lý (`:resume`), rồi `retry` `T92` với `reason`
3. `retry` `T93` (`PENDING`); `retry` thiếu `reason`; `retry` tenant không thuộc kế hoạch

**Kết quả mong đợi.** Bước 1 `409` `ERR-20-057`. Bước 2 `202`, `T92` về `UPGRADING` rồi `DONE`. Bước 3 `409` `ERR-20-006`, `400` `ERR-20-004`, `404` `ERR-20-002`.

:::

#### TC-20-174 · Danh sách nâng cấp theo tenant: lọc, mã không có, tham số sai <!--k:upg-list-neg-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-20-062 · API-20-119, 126 · ERR-20-002, ERR-20-004 · UI-20-19.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; kế hoạch ba sóng.

**Các bước.**

1. `GET .../tenant-upgrades?waveNo=2&status=DONE&page=1&size=20`
2. `GET .../tenant-upgrades?waveNo=abc`
3. `GET P/upgrade-plans/pl-khong-co`; `GET .../pl-khong-co/tenant-upgrades`
4. `U-PO` `GET P/upgrade-plans/{planId}`

**Kết quả mong đợi.** Bước 1 `200` lọc đúng. Bước 2 `400` `ERR-20-004`. Bước 3 `404` `ERR-20-002`. Bước 4 `200` (PO xem được).

:::

### TS-20-35 · Bảng điều khiển đa tenant và kiểm thử rò rỉ chéo tenant

**Mục tiêu.** Bảng điều khiển tổng hợp KPI và danh sách cần xử lý; điều phối kiểm thử rò rỉ chỉ trên `T90…T99`, bất kỳ dữ liệu đánh dấu nào lọt thì mở sự cố mức 1.

**Phủ.** FR-20-067, 070; UC-20-35; UI-20-20; API-20-129, 132, 133, 134.

#### TC-20-175 · Bảng điều khiển hiện KPI, danh sách cần xử lý và mốc cập nhật cuối <!--k:dash-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-067 · UC-20-35 · API-20-129 · NFR-20-006 · UI-20-20 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`, `U-PAU`; số đếm chuẩn mục 2.4 (tenant theo trạng thái, 5 cảnh báo hạn mức, 2 lệch cấu hình, 1 kế hoạch nâng cấp đang chạy); `obs-sim`.

**Các bước.**

1. `GET P/dashboard?environment=STAGING` bằng `U-PA1`
2. Lặp lại bằng `U-PO` và `U-PAU`
3. Số liệu sử dụng trễ 2 giờ (`obs-sim` trễ)
4. Mở UI-20-20, bấm một dòng cần xử lý

**Kết quả mong đợi.** Bước 1 `200`, các thẻ: số tenant theo trạng thái, thời gian khởi tạo p95, KPI-12, cảnh báo hạn mức, lệch, nâng cấp đang chạy, lần rò rỉ gần nhất. Bước 2 cùng nội dung. Bước 3 hiện mốc cập nhật cuối. Bước 4 dẫn tới màn chi tiết đúng tenant. Thời gian tải đạt NFR-20-003.

:::

#### TC-20-176 · Bảng điều khiển: nguồn chỉ số lỗi, tham số sai, quyền <!--k:dash-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-20-067 · API-20-129 · ERR-20-062, ERR-20-004 · UI-20-20.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`; `obs-sim` `503`.

**Các bước.**

1. `GET P/dashboard` khi Mimir giả `503`
2. `GET P/dashboard?environment=KHAC`
3. `U-T90-TA` `GET P/dashboard`

**Kết quả mong đợi.** Bước 1 `503` `ERR-20-062` hoặc `200` với thẻ lỗi hiện "Không có số liệu" (theo FR-067, thẻ lỗi độc lập); ghi nhận theo bản chạy. Bước 2 `400` `ERR-20-004`. Bước 3 `403` `ERR-00-403`.

:::

#### TC-20-177 · Chạy kiểm thử rò rỉ T90 sang T91, không có rò rỉ <!--k:leak-run-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, SEC.

**Truy vết.** FR-20-070 · UC-20-35 · API-20-132, 134, 133 · BR-20-004 · NFR-20-019 · UI-20-20 · `PERM-20-admin`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T90`, `T91` `ACTIVE` kiểm thử; F-LEAK (danh mục API của PH-03, tài nguyên mồi ở `T99`); `mod-sim`.

**Các bước.**

1. `POST P/leak-tests` với `sourceTenant = T90`, `targetTenant = T91`, `apiScope = ALL`, kèm `Idempotency-Key`
2. `GET P/leak-tests/{testRunId}` đến khi `COMPLETED`
3. `GET P/leak-tests?status=COMPLETED`

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 mỗi API có kết quả `PASSED`; API chỉ nền tảng `SKIPPED` kèm lý do; không phản hồi nào chứa dữ liệu đánh dấu của `T91`; gọi cả với tham số `tenantId` giả. Bước 3 có lần chạy.

:::

#### TC-20-178 · Phát hiện rò rỉ: mở sự cố mức 1, báo PO <!--k:leak-detect-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT, SEC.

**Truy vết.** FR-20-070 · UC-20-35 · API-20-132, 134 · ERR-20-111 · SEC-87 · UI-20-20.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; một API giả cố ý trả dữ liệu đánh dấu của tenant đích (bản giả `mod-sim`); `ops-sim` nhận sự cố.

**Các bước.**

1. `POST P/leak-tests` `T92` → `T93`
2. Xem kết quả và sự cố

**Kết quả mong đợi.** Kết quả của API đó `LEAKED` với `ERR-20-111` ("Phát hiện rò rỉ chéo tenant ở GET /api/ops/v1/tai-nguyen."); sự cố mức 1 mở qua PH-18; PO nhận thông báo; thẻ "lần rò rỉ gần nhất" ở UI-20-20 cập nhật.

**Thông báo hiển thị.** ERR-20-111: "Phát hiện rò rỉ chéo tenant ở GET /api/ops/v1/tai-nguyen."

:::

#### TC-20-179 · Kiểm thử rò rỉ trên tenant ngoài T90…T99, đang chạy, quyền <!--k:leak-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-070 · API-20-132, 133, 134 · ERR-20-065, ERR-20-004, ERR-20-009, ERR-20-002 · BR-20-038.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PO`; `T01` (`testTenant = false`, tỉnh thật); `T90`.

**Các bước.**

1. `POST P/leak-tests` với `sourceTenant = T01`
2. `POST` với `sourceTenant = T90`, `targetTenant = T90` hoặc thiếu trường
3. `POST` với `Idempotency-Key` đã dùng cho yêu cầu khác
4. `GET P/leak-tests/khong-co`; `GET P/leak-tests?status=KHAC`
5. `U-PO` `POST P/leak-tests`

**Kết quả mong đợi.** Bước 1 `422` `ERR-20-065` ("Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99."). Bước 2 `400` `ERR-20-004`. Bước 3 `409` `ERR-20-009`. Bước 4 `404` `ERR-20-002`, `400` `ERR-20-004`. Bước 5 `403` `ERR-00-403` (cần `PERM-20-admin`).

**Thông báo hiển thị.** ERR-20-065: "Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99."

:::

#### TC-20-180 · Lịch kiểm thử rò rỉ định kỳ theo tham số <!--k:leak-schedule-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-20-070, 069 · BR-20-004 · UC-20-35.

**Tiền điều kiện, dữ liệu.** `20.leak-test.schedule` đặt hàng đêm; đồng hồ giả lập; ShedLock.

**Các bước.**

1. Tiến đồng hồ tới lịch, hai bản DU cùng chạy
2. Xem `GET P/leak-tests`

**Kết quả mong đợi.** Chỉ một lần chạy được tạo (ShedLock); mặc định `T90`, `T91`.

:::

### TS-20-36 · Tra nhật ký kiểm toán và tham số 20.*

**Mục tiêu.** Tra nhật ký kiểm toán PH-20 toàn nền tảng và theo tỉnh, giới hạn 366 ngày; xem 29 tham số `20.*`, giá trị hiệu lực và nguồn; đổi giá trị qua PH-18 áp trong 60 giây, ngoài miền bị từ chối.

**Phủ.** FR-20-068, 069; UC-20-36; UI-20-03; API-20-130, 131, 161.

#### TC-20-181 · PA, PAU tra nhật ký toàn nền tảng; TA, AU tra theo tỉnh <!--k:audit-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-20-068 · UC-20-36 · API-20-130, 161 · BR-20-009 · UI-20-03 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PAU`, `U-T90-TA`, `U-T90-AU`; nhật ký có thao tác của `T90` và `T91`; `obs-sim` (API-13-072).

**Các bước.**

1. `U-PAU` `GET P/audit-events?tenantCode=T90&action=TENANT_SUSPEND&from=2026-11-01&to=2026-11-27`
2. `U-PA1` `GET P/audit-events?actor=U-PA2&ticketRef=TICKET-01`
3. `U-T90-TA` `GET T/audit-events?from=2026-11-01&to=2026-11-27`
4. `U-T90-AU` `GET T/audit-events`

**Kết quả mong đợi.** Bước 1, 2 `200`, `items[]` đúng bộ lọc, thao tác thay đổi có lý do và phiếu. Bước 3, 4 chỉ thao tác liên quan `T90`, không có bản ghi `T91`.

:::

#### TC-20-182 · Tra kiểm toán: khoảng quá dài, PH-13 lỗi, tham số sai, chéo tenant <!--k:audit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, SEC.

**Truy vết.** FR-20-068 · API-20-130, 161 · ERR-20-032, ERR-20-062, ERR-20-004 · SEC-87.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`; `obs-sim` `503`.

**Các bước.**

1. `GET P/audit-events?from=2025-01-01&to=2026-11-27` (> 366 ngày)
2. `GET P/audit-events?from=2026-11-27&to=2026-11-01`
3. `GET P/audit-events` khi `obs-sim` `503`
4. `U-T90-TA` `GET T/audit-events?tenantCode=T91`
5. `U-T90-TA` `GET P/audit-events`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-032` ("Khoảng thời gian tối đa là 366 ngày."). Bước 2 `400` `ERR-20-004`. Bước 3 `503` `ERR-20-062`. Bước 4 chỉ trả bản ghi của `T90` (tham số `tenantCode` không mở rộng phạm vi). Bước 5 `403` `ERR-00-403`.

**Thông báo hiển thị.** ERR-20-032: "Khoảng thời gian tối đa là 366 ngày."

:::

#### TC-20-183 · Xem tham số 20.* với giá trị hiệu lực và nguồn <!--k:param-view-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-069 · UC-20-36 · API-20-131 · BR-20-004 · UI-20-03 · `PERM-20-read`.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `ops-sim` đã đăng ký 29 khóa; `20.release.stable-soak-days` ghi đè 21 ngày.

**Các bước.**

1. `GET P/parameters?page=1&size=50`
2. `GET P/parameters?q=release`

**Kết quả mong đợi.** Bước 1 đủ 29 khóa, mỗi khóa có miền, mặc định, giá trị hiệu lực, nguồn. Bước 2 các khóa `20.release.*`, `stable-soak-days = 21` nguồn ghi đè, còn lại nguồn mặc định.

:::

#### TC-20-184 · Đổi tham số qua PH-18 áp trong 60 giây; ngoài miền bị từ chối <!--k:param-change-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-069 · UC-20-36 · BR-20-004 · ERR-20-060 · BR-20-037.

**Tiền điều kiện, dữ liệu.** `ops-sim` đẩy thay đổi tham số; `U-PO` đổi ở PH-18; tenant thật `T01` có mặt.

**Các bước.**

1. `ops-sim` đổi `20.release.wave-error-threshold-percent` từ 2 sang 3
2. Chờ ≤ 60 giây rồi `GET P/parameters?q=wave-error`
3. Đẩy giá trị 20 (ngoài miền 0,5…10)
4. Đẩy `20.smoke.enabled = false` khi nền tảng có tenant tỉnh thật
5. `ops-sim` không khả dụng khi DU khởi động lại

**Kết quả mong đợi.** Bước 2 giá trị hiệu lực 3, nguồn ghi đè, đã áp ≤ 60 giây. Bước 3, 4 bị từ chối với `ERR-20-060` ("Giá trị 20 của tham số 20.release.wave-error-threshold-percent ngoài miền 0,5…10."); giá trị cũ giữ. Bước 5 DU dùng giá trị cuối đã nhận, rồi mặc định dự phòng.

**Thông báo hiển thị.** ERR-20-060: "Giá trị 20 của tham số 20.release.wave-error-threshold-percent ngoài miền 0,5…10."

:::

#### TC-20-185 · Tham số: tham số truy vấn sai, tenant xem chéo <!--k:param-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-20-069 · API-20-131 · ERR-20-004.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`.

**Các bước.**

1. `GET P/parameters?size=0`; `?size=1000`
2. `U-T90-TA` `GET P/parameters`

**Kết quả mong đợi.** Bước 1 `400` `ERR-20-004`. Bước 2 `403` `ERR-00-403`.

:::


## 5. Kịch bản kiểm thử xuyên suốt và phi chức năng

Tám kịch bản dưới kiểm các yêu cầu cắt ngang: cô lập tenant, phân quyền, lũy đẳng và kiểm toán, saga theo từng bước, hiệu năng, chịu lỗi, giao diện và các ca đầu cuối. Ca hiệu năng ghi ngưỡng của NFR-20; số đo thật chạy ở PERF và STAGING (mục 1.3).

### TS-20-37 · Cô lập tenant và rò rỉ chéo tenant theo nhóm API

**Mục tiêu.** Mỗi nhóm API có ca rò rỉ chéo tenant (SEC-87); RLS ở PostgreSQL thật; ACL Kafka theo tiền tố; chặn ghi vào tenant `MERGED`, `SUSPENDED`, `DECOMMISSIONED` ở data plane và control plane.

**Phủ.** FR-20-065, 066, 070; SEC-87; BR-20-021; API-20-001…171 (theo nhóm); ERR-20-001, 101, 102, 103, 115.

#### TC-20-186 · Rò rỉ chéo tenant nhóm API tỉnh: mọi đối tượng của T90 mà người dùng T91 gọi đều trả 404 <!--k:leak-tenant-api-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, SEC.

**Truy vết.** SEC-87 · FR-20-066, 070 · API-20-135, 137, 139, 140, 141, 142, 143, 145, 151, 154, 157, 159, 161 · ERR-20-002 · NFR-20-019.

**Tiền điều kiện, dữ liệu.** `U-T91-TA`, `U-T90-TA`; `T90` có tổ chức `SO-KHCN`, lô nhập `importId-90`, đề xuất `proposalId-90`; F-LEAK.

**Các bước.**

1. `U-T91-TA` gọi từng API đọc theo mã của `T90`: `GET T/organizations/SO-KHCN`, `.../SO-KHCN/history`, `GET T/organization-imports/{importId-90}`, `GET T/organization-sync-proposals` (đối chiếu `proposalId-90`)
2. Gọi API ghi theo mã của `T90`: `PATCH T/organizations/SO-KHCN`, `POST .../SO-KHCN:dissolve`, `POST T/organization-imports/{importId-90}:confirm`, `POST .../{proposalId-90}:decide`
3. Gọi `GET T/settings`, `T/usage`, `T/quotas`, `T/cross-tenant-access-log`, `T/audit-events` đổi `tenantCode`, `X-Tenant-Id`, `tenantId` giả sang `T90`
4. Đối chiếu số dòng và kiểm tra nhật ký rò rỉ

**Kết quả mong đợi.** Bước 1, 2 `404` `ERR-20-002` cho mọi mã của `T90`, nội dung phản hồi không phân biệt "không có" và "của tenant khác". Bước 3 mọi API trả dữ liệu của `T91` (tenant ngữ cảnh lấy từ danh tính, bỏ qua tham số giả), không có dòng nào của `T90`. Bước 4 không có sự cố rò rỉ.

:::

#### TC-20-187 · Rò rỉ nhóm API nền tảng: người dùng tỉnh gọi API nền tảng, và chiều ngược lại <!--k:leak-platform-api-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, SEC.

**Truy vết.** SEC-87 · FR-20-066 · API-20-001, 003, 004, 086, 109, 118, 129, 130, 131 · ERR-00-403 · ERR-20-002.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-VW`, `U-PA1`; `T91` `ACTIVE`; kế hoạch sáp nhập T91→T90.

**Các bước.**

1. `U-T90-TA` `GET P/tenants`, `GET P/tenants/T91`, `GET P/merge-plans`, `GET P/releases`, `GET P/dashboard`
2. `U-T90-TA` `PATCH P/tenants/T91` và `POST P/tenants/T91/lifecycle-requests`
3. `U-PA1` `GET T/organizations` (không có ngữ cảnh tenant)

**Kết quả mong đợi.** Bước 1, 2 `403` `ERR-00-403` (người dùng tỉnh không thuộc tenant `PLATFORM`; quyết định 0.2: nhóm `/api/platform/v1` trả `403` vì đường dẫn nền tảng không phải tài nguyên của một tỉnh, không có gì để che; tài nguyên của tenant khác ở `/api/tenant/v1` và `/internal/tenant/v1` trả `404`, xem TC-20-186, 188). Bước 3 `403` `ERR-00-403` do token `PLATFORM` không có ngữ cảnh tenant, không trả dữ liệu của tenant nào. Không bản ghi nào bị đổi.

:::

#### TC-20-188 · Rò rỉ nhóm API nội bộ: sai scope, sai bên báo, tenant không thuộc ngữ cảnh <!--k:leak-internal-api-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, SEC.

**Truy vết.** SEC-87 · FR-20-065, 057 · API-20-162, 163, 164, 165, 166, 167, 168, 169, 170, 171 · ERR-20-104, ERR-20-002.

**Tiền điều kiện, dữ liệu.** `S-PH03` (`tenant:registry-read`), `S-PH01` (`tenant:org-read`), `S-PH10` (`tenant:provision-report`), `S-NOSCOPE`; kế hoạch, lần chạy `T93`.

**Các bước.**

1. `S-PH01` gọi `GET I/tenants`, `GET I/tenants/T93/enforcement`
2. `S-PH03` gọi `GET I/organizations`, `POST I/organizations:lookup`
3. `S-PH10` báo bước của phân hệ khác (bước `S09_GATEWAY` là của PH-03)
4. `S-NOSCOPE` gọi mọi API nội bộ
5. `S-PH01` `GET I/organizations/KHONG-CO` với ngữ cảnh `T93`; với mã của `T90` khi ngữ cảnh `T91`

**Kết quả mong đợi.** Bước 1, 2 `403` `ERR-20-104` ("Tài khoản dịch vụ không có quyền tenant:registry-read."). Bước 3 `403` `ERR-20-104` (không phải bên thực hiện của bước). Bước 4 `403` `ERR-20-104`. Bước 5 `404` `ERR-20-002`, không lộ tổ chức của tenant khác.

:::

#### TC-20-189 · RLS PostgreSQL: vai ứng dụng chỉ thấy dòng của tenant mình, không ghi bảng tenant <!--k:rls-tenant-sql-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT, SEC.

**Truy vết.** SEC-87 · NFR-20-024 · FR-20-066 · BR-20-009.

**Tiền điều kiện, dữ liệu.** PostgreSQL thật; DDL `ph20_tenant`; tenant `T90`, `T91`, `T92`; vai `dh_platform_app`, `dh_platform_ctl`, `dh_report_ro`; tệp `ph20_isolation_test.sql`.

**Các bước.**

1. Chạy `psql -v ON_ERROR_STOP=1 -f ph20_isolation_test.sql` trên CSDL rỗng sau DDL
2. Với phiên đặt biến `app.tenant_id = T90`, truy vấn mọi bảng có `tenant_id`; ghi dòng `tenant_id = T91`
3. Với phiên không đặt biến `app.tenant_id`, đọc bảng tenant; chạy khối "thiếu biến phiên"
4. Với phiên `PLATFORM` (vai nền tảng), đọc tổ chức mọi tenant; thử ghi nhóm bảng tự quản của tỉnh
5. Kiểm vai không có `BYPASSRLS`, `SUPERUSER`; bảng không thuộc sở hữu vai ứng dụng; bảng điều khiển bốn mắt, duy nhất có điều kiện, máy trạng thái, bất biến, phân vùng

**Kết quả mong đợi.** Bước 1 tệp chạy hết 14 khối, mọi ca ghi PASS, tổng kiểm cuối đạt. Bước 2 chỉ thấy dòng `T90`; ghi `T91` bị chặn. Bước 3 trả 0 dòng, không lỗi lộ dữ liệu. Bước 4 đọc được, ghi bị chặn. Bước 5 không vai nào vượt RLS; ràng buộc nghiệp vụ chặn đúng.

:::

#### TC-20-190 · ACL Kafka theo tiền tố: principal tenant không đọc, ghi được topic tenant khác <!--k:leak-kafka-acl-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT, SEC.

**Truy vết.** SEC-87 · FR-20-065 · EVT-20-13 · EVT-20-04 · UC-20-35.

**Tiền điều kiện, dữ liệu.** Kafka thật; `T90`, `T91`; principal nội bộ `T90` theo ACL tiền tố `t90.`; topic `t91.tenant.org.changed.v1`, `platform.tenant.status-changed.v1`.

**Các bước.**

1. Principal `T90` đọc topic `t91.tenant.org.changed.v1`
2. Principal `T90` ghi vào `t91.tenant.org.changed.v1`
3. Principal `T90` đọc `platform.tenant.status-changed.v1`
4. PH-20 tạo tổ chức ở `T90`, kiểm EVT-20-13 ở topic `t90.`

**Kết quả mong đợi.** Bước 1, 2 bị từ chối (ACL). Bước 3 bị từ chối (topic nền tảng chỉ cho phân hệ đăng ký). Bước 4 sự kiện chỉ ở topic `t90.`, `tenantCode = T90`, không ở topic tenant khác.

:::

#### TC-20-191 · Giả mạo ngữ cảnh tenant: header, token, tham số bị bỏ qua <!--k:leak-mesh-spoof-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, SEC.

**Truy vết.** SEC-87 · FR-20-066 · API-20-135, 143 · ERR-20-002.

**Tiền điều kiện, dữ liệu.** `U-T91-TA`; token realm `T91`; mesh giả lập.

**Các bước.**

1. Gọi `GET T/organizations` với `X-Tenant-Id: T90`
2. Gọi với token realm `T91` nhưng path chứa mã của `T90`
3. Gọi với `tenantId=T90` ở query và body
4. Gọi với token realm đã hết hạn, và token ký sai

**Kết quả mong đợi.** Bước 1, 3 trả dữ liệu `T91` (tham số, header bị bỏ qua). Bước 2 `404` `ERR-20-002`. Bước 4 `401` `ERR-00-401`. Không dòng nào của `T90`.

:::

#### TC-20-192 · Kiểm thử rò rỉ hằng đêm phủ 100 % API công bố trong 60 phút <!--k:leak-seeded-run-->

::: dac-ta
**Loại.** Dương, Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** PERF, SEC.

**Truy vết.** SEC-87 · FR-20-070 · API-20-132, 134 · NFR-20-019.

**Tiền điều kiện, dữ liệu.** PERF; `T90`, `T91` kiểm thử; danh mục 171 API (F-LEAK).

**Các bước.**

1. Chạy `POST P/leak-tests` `ALL` và đo thời gian
2. Đếm API có kết quả `PASSED`, `SKIPPED`, `LEAKED`

**Kết quả mong đợi.** Hoàn tất ≤ 60 phút; mỗi API công bố có kết quả (phủ 100 %); `LEAKED = 0`; ca `SKIPPED` có lý do.

:::

#### TC-20-193 · Ghi vào tenant MERGED, SUSPENDED, DECOMMISSIONED ở data plane và control plane <!--k:enforce-merged-decom-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-20-066 · BR-20-021 · ERR-20-001, ERR-20-101, ERR-20-102, ERR-20-103, ERR-20-115, ERR-20-118 · NFR-20-004.

**Tiền điều kiện, dữ liệu.** `T90` `ACTIVE`; `T92` `SUSPENDED`; `T88` `DECOMMISSIONED`; `T91` `MERGED`; `T94` `PROVISIONING`; `T90` tắt PH-19; `T96` `ACTIVE` đang nâng cấp.

**Các bước.**

1. Gọi ghi data plane theo từng tenant, qua `S-PH03` đọc API-20-164
2. Gọi đọc data plane của `T92`, `T91`
3. Gọi phân hệ bị tắt của `T90`
4. Ghi ở `T96` đang bảo trì nâng cấp

**Kết quả mong đợi.** Bước 1 `T92` `403` `ERR-20-001`; `T88` `410` `ERR-20-102`; `T91` `409` `ERR-20-115`; `T94` `503` `ERR-20-101`. Bước 2 đọc `200` cho `T92`, `T91`. Bước 3 `503` `ERR-20-103`. Bước 4 `503` `ERR-20-118`.

:::

### TS-20-38 · Phân quyền âm và bốn mắt

**Mục tiêu.** Mỗi quyền `PERM-20-*` có ca bị từ chối khi thiếu quyền; năm điểm bốn mắt từ chối người lập tự duyệt; một người giữ cả hai quyền vẫn bị chặn.

**Phủ.** BR-20-008; D02-08; ERR-20-007; ERR-00-403; PERM-20-admin, approve, lifecycle, merge, org, org-read, provision, quota, read, release, settings, usage-read.

#### TC-20-194 · Mỗi PERM-20 bị từ chối khi vai không có quyền <!--k:perm-matrix-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-20-008 · ERR-00-403 · API-20-002, 049, 071, 086, 110, 129, 132, 136, 140, 144 · `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-admin`, `PERM-20-settings`, `PERM-20-org`, `PERM-20-usage-read`, `PERM-20-read`, `PERM-20-approve`, `PERM-20-org-read`.

**Tiền điều kiện, dữ liệu.** `U-PO` (chỉ `PERM-20-read`, `PERM-20-release` theo dõi), `U-PAU` (chỉ đọc), `U-T90-VW`, `U-T90-TA`, `U-T90-AU`; mỗi thao tác chọn đúng một API đại diện của quyền.

**Các bước.**

1. `U-PAU` gọi thao tác cần `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-admin`
2. `U-PO` gọi thao tác cần `PERM-20-lifecycle`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-approve`
3. `U-T90-VW` gọi thao tác cần `PERM-20-settings`, `PERM-20-org`
4. `U-T90-AU` gọi thao tác cần `PERM-20-org`, `PERM-20-settings`, `PERM-20-usage-read` ngoài phạm vi
5. `U-T90-TA` gọi thao tác nền tảng cần `PERM-20-read`

**Kết quả mong đợi.** Mọi bước `403` `ERR-00-403`, không đổi dữ liệu, không lộ tên quyền thiếu ở thông báo cho người dùng cuối; có bản ghi kiểm toán từ chối.

:::

#### TC-20-195 · Năm điểm bốn mắt: người lập không được duyệt <!--k:perm-four-eyes-all-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-20-008 · FR-20-025, 027, 040, 041, 045 · ERR-20-007 · `PERM-20-approve`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`, `U-PA3`; năm đề nghị: đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng, chấm dứt, xác nhận bàn giao gói dữ liệu, kế hoạch sáp nhập.

**Các bước.**

1. `U-PA1` lập từng đề nghị rồi tự duyệt
2. `U-PA3` (đủ hai quyền) lập, gửi rồi duyệt đề nghị của chính mình
3. `U-PA2` duyệt từng đề nghị
4. Với chấm dứt: người duyệt đề nghị chấm dứt xác nhận bàn giao gói dữ liệu

**Kết quả mong đợi.** Bước 1, 2 `403` `ERR-20-007` ("Anh/chị là người lập nên không được duyệt. Cần một quản trị nền tảng khác duyệt."). Bước 3 `200`. Bước 4 `403` `ERR-20-007`. Cả năm điểm đều bị chặn; đề nghị giữ trạng thái chờ.

**Thông báo hiển thị.** ERR-20-007: "Anh/chị là người lập nên không được duyệt. Cần một quản trị nền tảng khác duyệt."

:::

#### TC-20-196 · Quyền tỉnh chỉ trong phạm vi tenant của mình, cấp cho vai khác <!--k:perm-tenant-scope-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** BR-20-008 · API-20-135, 144 · ERR-00-403 · ERR-20-002 · `PERM-20-settings`, `PERM-20-org-read`.

**Tiền điều kiện, dữ liệu.** `U-T90-TA`, `U-T90-DS` (nhà phát triển), `U-T90-SO`; `T90`, `T91`.

**Các bước.**

1. `U-T90-SO` `GET T/organizations`; `PUT T/settings`
2. `U-T90-DS` `GET T/usage`
3. `U-T90-TA` gọi `GET T/organizations/{mã của T91}`

**Kết quả mong đợi.** Bước 1 đọc `200` (`PERM-20-org-read` cho mọi vai trò tỉnh), ghi `403` `ERR-00-403`. Bước 2 `403` `ERR-00-403` hoặc `200` theo ma trận D02-08 (ghi nhận kết quả thực tế). Bước 3 `404` `ERR-20-002`.

:::

#### TC-20-197 · Không đăng nhập, token hết hạn, thiếu scope <!--k:perm-unauth-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** ERR-00-401 · ERR-00-403 · API-20-001, 135, 162.

**Tiền điều kiện, dữ liệu.** Không token; token hết hạn; `S-NOSCOPE`.

**Các bước.**

1. Gọi `GET P/tenants`, `GET T/settings`, `GET I/tenants` không token
2. Gọi với token hết hạn
3. `S-NOSCOPE` gọi `GET I/tenants`

**Kết quả mong đợi.** Bước 1, 2 `401` `ERR-00-401` đúng định dạng RFC 9457 có `code`, `traceId`. Bước 3 `403` `ERR-20-104`.

:::

### TS-20-39 · Lũy đẳng, đồng thời, định dạng lỗi và kiểm toán

**Mục tiêu.** Mọi `POST` ghi có `Idempotency-Key`; mọi sửa có `If-Match`; lỗi theo RFC 9457; mọi thao tác thay đổi có bản ghi kiểm toán đủ trường và không có bí mật.

**Phủ.** BR-20-009; NFR-20-018, 020, 021, 024; ERR-20-004, 005, 009; ERR-00-428; EVT-20-01…16.

#### TC-20-198 · Gọi lại cùng Idempotency-Key trả kết quả cũ, khác nội dung trả 409 <!--k:idem-replay-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** ERR-20-009 · API-20-002, 086, 110, 144 · BR-20-009.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-T90-TA`; bốn thao tác `POST` tạo mới đại diện (khai báo tenant, kế hoạch sáp nhập, phiên bản, tổ chức).

**Các bước.**

1. Gửi `POST` với `Idempotency-Key = K1`, rồi gửi lại đúng nội dung
2. Gửi lại với `K1` nhưng nội dung khác
3. Gửi hai yêu cầu đồng thời cùng `K2`
4. Gửi `POST` không có `Idempotency-Key`

**Kết quả mong đợi.** Bước 1 lần hai trả đúng kết quả lần một, không tạo bản ghi mới, không phát sự kiện thứ hai. Bước 2 `409` `ERR-20-009` ("Khóa chống lặp đã được dùng cho một yêu cầu khác. Tạo yêu cầu mới."). Bước 3 một bản ghi duy nhất. Bước 4 `400` `ERR-20-004` (giả định ĐN-TC-03: hợp đồng chưa nêu mã lỗi).

**Thông báo hiển thị.** ERR-20-009: "Khóa chống lặp đã được dùng cho một yêu cầu khác. Tạo yêu cầu mới."

:::

#### TC-20-199 · Hai người sửa cùng đối tượng: người sau nhận 412 <!--k:concurrency-ifmatch-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** ERR-20-005 · ERR-00-428 · API-20-004, 146, 120, 112 · UI-20-15.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`; một tenant, một tổ chức, một kế hoạch nâng cấp; `ETag` hiện tại `v1`.

**Các bước.**

1. Hai người cùng đọc `ETag = v1`
2. Người A `PATCH` kèm `If-Match: v1`, thành công, `ETag = v2`
3. Người B `PATCH` kèm `If-Match: v1`
4. Người B `PATCH` không có `If-Match`

**Kết quả mong đợi.** Bước 2 `200`. Bước 3 `412` `ERR-20-005` ("Tổ chức đã được người khác sửa. Tải lại để xem thay đổi."), dữ liệu giữ bản của A. Bước 4 `428` `ERR-00-428`. UI hiện hộp thoại "Tải lại".

**Thông báo hiển thị.** ERR-20-005: "Tổ chức đã được người khác sửa. Tải lại để xem thay đổi."

:::

#### TC-20-200 · Mọi lỗi theo RFC 9457 có code, traceId, errors[] <!--k:error-format-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** ERR-20-004 · ERR-20-002 · ERR-20-006 · API-20-001, 003, 144 · NFR-20-021.

**Tiền điều kiện, dữ liệu.** Ba lỗi đại diện: `400` (sai trường), `404`, `409`.

**Các bước.**

1. Gọi để sinh `400`, `404`, `409`
2. Kiểm `Content-Type` và trường

**Kết quả mong đợi.** `application/problem+json`; có `type`, `title`, `status`, `code` (`ERR-20-xxx`), `traceId`; `400` có `errors[]` (`field`, `message`); thông báo tiếng Việt có dấu; không lộ ngăn xếp, tên bảng, địa chỉ nội bộ.

:::

#### TC-20-201 · Mọi thao tác thay đổi có kiểm toán đủ trường, không có bí mật <!--k:audit-completeness-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, SEC.

**Truy vết.** BR-20-009 · NFR-20-018 · NFR-20-024 · FR-20-068 · EVT-20-04.

**Tiền điều kiện, dữ liệu.** Danh sách thao tác ghi của 134 + 27 API (lấy từ OpenAPI); `obs-sim` nhận bản ghi; `U-PA1`.

**Các bước.**

1. Thực hiện một lần mỗi thao tác ghi (thành công)
2. Thực hiện thao tác ghi bị từ chối (403, 409)
3. Duyệt bản ghi kiểm toán trong `obs-sim`
4. Tìm chuỗi bí mật mẫu `<bi-mat-mau>` trong kiểm toán, nhật ký, CSDL `ph20_tenant`, kho Git giả

**Kết quả mong đợi.** 100 % thao tác ghi thành công có bản ghi (ai, khi nào, tenant, đối tượng, giá trị trước và sau trừ bí mật, `ticketRef`, `traceId`). Thao tác bị từ chối có bản ghi từ chối. Không tìm thấy bí mật ở bất kỳ nơi nào (NFR-20-024).

:::

#### TC-20-202 · Outbox phát đủ 16 sự kiện đúng khóa, tenantCode, lược đồ <!--k:outbox-events-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** EVT-20-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16 · NFR-20-020 · NFR-20-021.

**Tiền điều kiện, dữ liệu.** Kafka và Apicurio thật; kịch bản gây ra từng sự kiện (khai báo, lỗi saga, kích hoạt, đổi trạng thái, đổi hạn mức, chạm ngưỡng, bật và tắt phân hệ, đổi cấu hình, ba sự kiện sáp nhập, tổ chức, phát hành, nâng cấp, gói bàn giao).

**Các bước.**

1. Thực hiện từng kịch bản
2. Đọc sự kiện từ topic, kiểm lược đồ với Apicurio, khóa, `tenantCode`, `eventId`
3. Đo trễ từ commit đến sự kiện; làm Kafka ngừng 2 phút rồi bật lại

**Kết quả mong đợi.** Cả 16 sự kiện được phát đúng tên, đúng lược đồ, `eventId` duy nhất; p95 ≤ 5 giây; sau khi Kafka phục hồi không mất, không trùng ngoài ý muốn (người nhận lũy đẳng theo `eventId`); số đo `dh_tenant_*` có nhãn `tenant` (NFR-20-021).

:::

### TS-20-40 · Saga khởi tạo từng bước S01…S17

**Mục tiêu.** Mỗi bước saga có ca lỗi rồi thử lại, bù trừ ngược theo bảng bù trừ, bước bất đồng bộ hết hạn chờ báo, báo lặp lũy đẳng; `Idempotency-Key = {runId}:{stepCode}`.

**Phủ.** FR-20-008…013; BR-20-004, 007; API-20-013…023, 166; ERR-20-016…021, 105, 106, 107, 108, 117; EVT-20-01, 02, 03.

#### TC-20-203 · S01_RECORD, S02_CONFIG_REPO: lỗi Git rồi thử lại, bù trừ revert <!--k:saga-s01-s02-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 010, 011 · API-20-013, 017, 018, 020 · BR-20-007 · ERR-20-018, ERR-20-019 · EVT-20-02.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T94` `PROVISIONING`; F-SAGA `FAIL_ONCE` ở `S02_CONFIG_REPO` (`git-sim` từ chối ghi một lần).

**Các bước.**

1. `POST P/tenants/T94/provisioning-runs` (`INITIAL`)
2. `POST P/provisioning-runs/{runId}/steps/S02_CONFIG_REPO:retry`
3. Chạy lại với `FAIL_ALWAYS` ở `S02`, rồi `POST P/provisioning-runs/{runId}:compensate`

**Kết quả mong đợi.** Bước 1 `S01` `SUCCEEDED`, `S02` `FAILED`, lần chạy `FAILED`, EVT-20-02. Bước 2 `S02` `SUCCEEDED`, tiếp tục các bước sau. Bước 3 bù trừ: revert commit ở `dh-tenant-config`, `S01` xóa bản ghi chỉ khi chưa có bước nào khác xong (ở đây còn bước khác nên giữ, tenant về `FAILED`); bước bù không làm được trả `ERR-20-019`.

:::

#### TC-20-204 · S03_REALM: PH-12 lỗi `409`, `503`, trễ; bù trừ xóa realm đang PROVISIONING <!--k:saga-s03-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 011 · API-20-013, 018, 020 · ERR-20-062, ERR-20-107 · BR-20-007.

**Tiền điều kiện, dữ liệu.** `U-PA1`; `T94`; `iam-sim` kịch bản `409` (realm đã có), `503`, trễ 90 giây.

**Các bước.**

1. Chạy saga khi `iam-sim` `503`
2. Thử lại bước sau khi `iam-sim` bình thường
3. Chạy saga khi `iam-sim` trễ 90 giây
4. Bù trừ lần chạy `FAILED` sau `S03`

**Kết quả mong đợi.** Bước 1 `S03` `FAILED` với `ERR-20-107` ("Bước S03_REALM lỗi tại PH-12: 503."). Bước 2 `SUCCEEDED`, realm `dh-t94`, client `dh-console`, `dh-portal`, quản trị tỉnh đầu tiên. Bước 3 vẫn chờ, không `FAILED`, theo thời hạn bước. Bước 4 `iam-sim` nhận lệnh xóa realm còn `PROVISIONING`.

:::

#### TC-20-205 · S04_SECRETS, S05_BUCKETS: OpenBao, Ceph lỗi; bù trừ xóa đường dẫn, KEK chưa dùng, bucket rỗng <!--k:saga-s04-s05-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 011 · API-20-018, 020 · NFR-20-024 · ERR-20-107, ERR-20-019.

**Tiền điều kiện, dữ liệu.** `T94`; `vault-sim`, `s3-sim`; `s3-sim` có bucket `dh-t94-files` chứa một tệp (bù trừ không xóa được).

**Các bước.**

1. Chạy saga với `FAIL_ONCE` ở `S04`, thử lại
2. Chạy với `FAIL_ONCE` ở `S05`, thử lại
3. Bù trừ khi bucket `dh-t94-files` còn tệp

**Kết quả mong đợi.** Bước 1 đường dẫn `kv/dh/t94/...`, chính sách, KEK `dh-t94-pii` được tạo một lần (lũy đẳng), không bí mật nào vào CSDL hay Git. Bước 2 đủ bốn bucket `files`, `exports`, `backup`, `audit`. Bước 3 bucket còn tệp không bị xóa, lần bù `ERR-20-019`, cần xử lý tay.

:::

#### TC-20-206 · S06_EVENTING (bất đồng bộ): chờ báo, báo thành công, báo lỗi, hết hạn <!--k:saga-s06-async-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 009 · API-20-166 · BR-20-007 · ERR-20-105, ERR-20-106, ERR-20-107 · NFR-20-007.

**Tiền điều kiện, dữ liệu.** `S-PH10`; F-SAGA `OK`, `REPORT_FAILED`, `NO_REPORT`; `20.provision.step-timeout-minutes`, `20.provision.step-retry-max`; đồng hồ giả lập.

**Các bước.**

1. Lần chạy 1 (`OK`): `S-PH10` báo `S06_EVENTING` `SUCCEEDED`
2. Lần chạy 2 (`REPORT_FAILED`): `S-PH10` báo `FAILED` kèm `errorCode`
3. Lần chạy 3 (`NO_REPORT`): tiến đồng hồ quá thời hạn bước
4. Quan sát tiến trình qua `GET P/provisioning-runs/{runId}/stream` (SSE)

**Kết quả mong đợi.** Bước 1 bước `WAITING` rồi `SUCCEEDED`. Bước 2 `FAILED` với `ERR-20-107`. Bước 3 sau `step-timeout` tự thử tối đa `step-retry-max` lần rồi `FAILED` với `ERR-20-106` ("Bước S06_EVENTING chưa nhận báo cáo từ PH-10 sau 15 phút."). Bước 4 sự kiện tiến độ trễ ≤ 2 giây (NFR-20-007).

**Thông báo hiển thị.** ERR-20-106: "Bước S06_EVENTING chưa nhận báo cáo từ PH-10 sau 15 phút."

:::

#### TC-20-207 · Báo lặp, báo sai bước, báo sai bên, báo khi lần chạy đã kết thúc <!--k:saga-callback-idem-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-20-009 · API-20-166 · ERR-20-105, ERR-20-104, ERR-20-004, ERR-20-002.

**Tiền điều kiện, dữ liệu.** `S-PH10`, `S-PH04`, `S-NOSCOPE`; lần chạy `RUNNING` đang chờ `S06`; lần chạy `FAILED`; F-SAGA `DUP_REPORT`.

**Các bước.**

1. `S-PH10` báo `S06_EVENTING` `SUCCEEDED` hai lần
2. `S-PH10` báo `S09_GATEWAY` (bước của PH-03)
3. `S-PH10` báo `S06_EVENTING` khi bước đã `FAILED` do hết hạn
4. `S-NOSCOPE` báo
5. Báo `stepCode` không có (`S99_KHONG`); báo `runId` không có; thân thiếu `status`

**Kết quả mong đợi.** Bước 1 hai lần `200`, kết quả như nhau, tiến độ không đổi hai lần. Bước 2 `403` `ERR-20-104` (không phải bên thực hiện). Bước 3 `409` `ERR-20-105` ("Báo tiến độ bước S06_EVENTING không khớp trạng thái FAILED."). Bước 4 `403` `ERR-20-104`. Bước 5 `400` `ERR-20-004`, `404` `ERR-20-002`, `400` `ERR-20-004`.

**Thông báo hiển thị.** ERR-20-105: "Báo tiến độ bước S06_EVENTING không khớp trạng thái FAILED."

:::

#### TC-20-208 · S07_DATABASE chỉ DEDICATED_DB: tạo cụm CNPG, bỏ qua với SHARED <!--k:saga-s07-dedicated-db-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-008, 007 · API-20-013 · BR-20-007 · ERR-20-107.

**Tiền điều kiện, dữ liệu.** `T93` `SHARED`, `T95` `DEDICATED_DB` (PostgreSQL thật, CNPG giả hợp đồng).

**Các bước.**

1. Chạy saga `T93`
2. Chạy saga `T95` với `FAIL_ONCE` ở `S07`, thử lại

**Kết quả mong đợi.** Bước 1 `S07` `SKIPPED` (không áp dụng). Bước 2 cụm, migration, bảng định tuyến tạo một lần; bù trừ xóa cụm.

:::

#### TC-20-209 · S08_OBSERVABILITY đồng bộ, S09_GATEWAY bất đồng bộ đọc API-20-164 <!--k:saga-s08-s09-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 009, 065 · API-20-166, 164 · EVT-20-01 · ERR-20-107, ERR-20-106 · NFR-20-003.

**Tiền điều kiện, dữ liệu.** `obs-sim` (API-13-072, 073); `S-PH03`; F-SAGA.

**Các bước.**

1. Chạy saga; `obs-sim` trả `409` một lần ở `S08`, thử lại
2. `S-PH03` đọc `GET I/tenants/T94/enforcement`, rồi báo `S09_GATEWAY` `SUCCEEDED`
3. Bù trừ: kiểm đóng chuỗi kiểm toán (API-13-073) và PH-03 gỡ

**Kết quả mong đợi.** Bước 1 chuỗi kiểm toán, tổ chức Grafana, luật cảnh báo lập một lần. Bước 2 PH-03 nhận hạn mức hợp đồng và host, tiền tố; `S09` `SUCCEEDED`. Bước 3 đúng thứ tự bù ngược.

:::

#### TC-20-210 · S10_INTEGRATION, S11_SEED_RDM, S12_SEED_MDM: bật theo mẫu, lỗi, bù trừ <!--k:saga-s10-s12-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-008, 009 · API-20-166 · EVT-20-01 · ERR-20-107, ERR-20-106.

**Tiền điều kiện, dữ liệu.** `T94`; mẫu bật PH-04, PH-07, PH-06; `rdm-sim` API-07-073; `mod-sim` báo `S10`, `S12`.

**Các bước.**

1. Chạy saga bình thường
2. Chạy với `rdm-sim` `503` ở `S11`, thử lại
3. Chạy với PH-06 không bật trong mẫu

**Kết quả mong đợi.** Bước 1 `S10`, `S12` `SUCCEEDED` qua báo; `S11` nạp gói danh mục nền. Bước 2 `S11` `FAILED`, thử lại thành công. Bước 3 `S12` `SKIPPED`.

:::

#### TC-20-211 · S13_ORG_SEED gieo tổ chức cấp tỉnh, S14_KPI kế thừa chỉ tiêu <!--k:saga-s13-s14-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008 · API-20-013 · ERR-20-062, ERR-20-107 · EVT-20-13.

**Tiền điều kiện, dữ liệu.** `T94`; ĐVHC `COMMON` (UBND tỉnh, sở theo mẫu); `kpi-sim` `503` một lần (PH-16 bật).

**Các bước.**

1. Chạy saga
2. `kpi-sim` `503` ở `S14`, thử lại; chạy với PH-16 không bật

**Kết quả mong đợi.** Bước 1 `S13` tạo UBND tỉnh và các sở theo mẫu (số tổ chức khớp mẫu), phát EVT-20-13. Bước 2 `S14` `FAILED` rồi `SUCCEEDED`; không bật thì `SKIPPED`.

:::

#### TC-20-212 · S15_MODULES phát EVT-20-07 từng phân hệ bật và chờ báo <!--k:saga-s15-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 009, 034 · API-20-166 · EVT-20-07, EVT-20-08 · ERR-20-106.

**Tiền điều kiện, dữ liệu.** Mẫu bật PH-19, PH-17; `mod-sim` PH-19 báo, PH-17 không báo.

**Các bước.**

1. Chạy saga tới `S15`
2. PH-19 báo `SUCCEEDED`; PH-17 không báo, quá hạn
3. Bù trừ lần chạy `FAILED`

**Kết quả mong đợi.** Bước 1 phát EVT-20-07 cho từng phân hệ. Bước 2 PH-19 `SUCCEEDED`; `S15` `FAILED` với `ERR-20-106` do PH-17. Bước 3 phát EVT-20-08 cho phân hệ đã bật.

:::

#### TC-20-213 · S16_SMOKE: ca khói lỗi dừng saga, tenant không ACTIVE <!--k:saga-s16-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 012 · BR-20-004 · API-20-022 · ERR-20-117, ERR-20-020.

**Tiền điều kiện, dữ liệu.** `T94`; `20.smoke.enabled = true`; bản giả làm ca "rò rỉ chéo tenant" lỗi.

**Các bước.**

1. Chạy saga tới `S16`
2. `GET P/tenants/T94`
3. `POST P/tenants/T94:activate`

**Kết quả mong đợi.** Bước 1 `S16` `FAILED` với `ERR-20-117` ("Ca kiểm tra khói LEAK-CHECK lỗi: trả dữ liệu của T93."). Bước 2 tenant giữ `PROVISIONING` (hoặc `FAILED`). Bước 3 `422` `ERR-20-020`.

:::

#### TC-20-214 · S17_ACTIVATE: ACTIVE, thông báo đầu mối, đẩy KPI-12 <!--k:saga-s17-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008, 013, 014 · API-20-023 · EVT-20-03 · ERR-20-062, ERR-20-021.

**Tiền điều kiện, dữ liệu.** `T94` đã qua `S16`; `ops-sim`; `kpi-sim` `503`.

**Các bước.**

1. Chạy `S17`
2. Chạy lại với `kpi-sim` `503`
3. Đầu mối `TENANT_ADMIN` bị xóa trước khi kích hoạt

**Kết quả mong đợi.** Bước 1 `ACTIVE`, EVT-20-03, thư đến đầu mối, KPI-12 đẩy qua API-16-030. Bước 2 tenant vẫn `ACTIVE`, việc đẩy KPI-12 thử lại sau (không chặn). Bước 3 `422` `ERR-20-021`.

:::

#### TC-20-215 · Saga vượt tổng thời gian cho phép <!--k:saga-total-timeout-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-008 · BR-20-007 · ERR-20-108 · NFR-00-057.

**Tiền điều kiện, dữ liệu.** `20.provision.timeout-minutes = 60`; mọi bước trễ tổng 61 phút (đồng hồ giả lập).

**Các bước.**

1. Chạy saga với bước trễ dần

**Kết quả mong đợi.** Lần chạy `FAILED` với `ERR-20-108` ("Khởi tạo vượt thời gian cho phép 60 phút."), EVT-20-02, các bước dở dang dừng; thử lại hoặc bù trừ được.

**Thông báo hiển thị.** ERR-20-108: "Khởi tạo vượt thời gian cho phép 60 phút."

:::

### TS-20-41 · Hiệu năng và dung lượng

**Mục tiêu.** Đo các ngưỡng NFR-20 ở PERF với 34 tenant; saga ≤ 60 phút p95; registry p99 ≤ 50 ms ở ≥ 500 lượt/giây; tạm ngừng ≤ 60 giây; nhập 5.000 dòng ≤ 30 giây.

**Phủ.** NFR-00-057, 060; NFR-20-001, 003, 004, 005, 006, 008, 009, 010, 011, 012, 013, 016, 017.

#### TC-20-216 · Saga khởi tạo ≤ 60 phút p95 trên 34 tenant <!--k:perf-saga-60-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** PERF.

**Truy vết.** NFR-00-057 · NFR-20-001 · NFR-20-005 · FR-20-008.

**Tiền điều kiện, dữ liệu.** PERF; 34 tenant `T01…T34` (`testTenant = true`, ngoài dải `T90…T99`, xem Phụ lục ĐN-TC-07); mẫu `tinh-chuan`; bản giả theo F-SAGA `OK` với trễ thực tế; 5 lần chạy song song tối đa.

**Các bước.**

1. Khởi tạo tuần tự và song song 5 tenant, tổng 34 lần
2. Ghi thời gian từ `S01` đến `ACTIVE`

**Kết quả mong đợi.** p95 ≤ 60 phút, không lần nào quá 60 phút do tranh chấp tài nguyên; nền tảng phục vụ ≥ 34 tenant, sức chứa cấu hình 40; thời gian khởi tạo đẩy được cho KPI-12.

:::

#### TC-20-217 · Registry tenant p99 ≤ 50 ms ở ≥ 500 lượt mỗi giây <!--k:perf-registry-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** PERF.

**Truy vết.** NFR-20-003 · NFR-20-017 · FR-20-065 · API-20-162, 163, 164.

**Tiền điều kiện, dữ liệu.** PERF; 34 tenant; `S-PH03`; tải k6 ở 500, 750 lượt/giây trong 10 phút.

**Các bước.**

1. Gọi `GET I/tenants/{code}/enforcement` ở 500 lượt/giây
2. Ở 750 lượt/giây; khi PH-20 DU mất một bản

**Kết quả mong đợi.** p99 ≤ 50 ms ở 500 lượt/giây; không lỗi 5xx; khi mất một bản vẫn đạt; sẵn sàng registry ≥ 99,9 % theo đo cửa sổ.

:::

#### TC-20-218 · Tạm ngừng có hiệu lực ở data plane ≤ 60 giây <!--k:perf-suspend-60-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** PERF, IT.

**Truy vết.** NFR-20-004 · FR-20-038, 066 · ERR-20-001 · EVT-20-04.

**Tiền điều kiện, dữ liệu.** PERF; `T96` đang có tải; `S-PH03`, bộ lọc `dh-tenant-filter`.

**Các bước.**

1. `POST P/tenants/T96/lifecycle-requests` tạm ngừng; ghi thời điểm phát EVT-20-04
2. Gọi API data plane liên tục mỗi 1 giây

**Kết quả mong đợi.** Từ lúc tạm ngừng đến khi lượt ghi bị chặn `ERR-20-001` không quá 60 giây; lượt đọc vẫn qua.

:::

#### TC-20-219 · Danh sách màn hình p95 ≤ 1,5 giây; SSE tiến độ ≤ 2 giây <!--k:perf-ui-lists-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** PERF.

**Truy vết.** NFR-20-006 · NFR-20-007 · API-20-001, 143, 087, 109 · UI-20-01, 14, 11, 18.

**Tiền điều kiện, dữ liệu.** PERF; 34 tenant; 5.000 tổ chức; 100 kế hoạch sáp nhập; 100 phiên bản.

**Các bước.**

1. Tải 100 người dùng đồng thời gọi bốn danh sách
2. Theo dõi tiến độ saga qua SSE, đo trễ giữa đổi trạng thái và sự kiện

**Kết quả mong đợi.** p95 ≤ 1,5 giây mỗi danh sách; trễ SSE ≤ 2 giây.

:::

#### TC-20-220 · Thu sử dụng hằng giờ trễ ≤ 15 phút; cảnh báo ≤ 5 phút; lệch cấu hình ≤ 1 giờ; GitOps ≤ 5 phút <!--k:perf-usage-alert-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** PERF, IT.

**Truy vết.** NFR-20-008 · NFR-20-009 · NFR-20-010 · NFR-20-011 · FR-20-028, 029, 022, 020.

**Tiền điều kiện, dữ liệu.** PERF; 34 tenant; `obs-sim` Mimir; `git-sim`, `argo-sim`; đồng hồ thật.

**Các bước.**

1. Đo trễ từ giờ tròn đến ảnh chụp sử dụng; lưu 25 tháng
2. Đẩy sử dụng `T96` vượt 80 %; đo đến cảnh báo
3. Sửa lệch ở `argo-sim`; đo đến khi phát hiện
4. Ghi cấu hình; đo đến khi Argo CD áp

**Kết quả mong đợi.** Trễ sử dụng ≤ 15 phút; cảnh báo ≤ 5 phút; phát hiện lệch ≤ 1 giờ; áp cấu hình ≤ 5 phút; dữ liệu 25 tháng còn truy vấn được.

:::

#### TC-20-221 · Xem trước nhập 5.000 dòng ≤ 30 giây; API đọc tổ chức p95 ≤ 100 ms <!--k:perf-org-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** PERF.

**Truy vết.** NFR-20-012 · NFR-20-013 · FR-20-055, 057 · API-20-153, 154, 169, 170, 171.

**Tiền điều kiện, dữ liệu.** PERF; F-ORG-IMP 5.000 dòng; `org-reader-sim`.

**Các bước.**

1. Tải tệp 5.000 dòng, đo đến `PREVIEW_READY`
2. Tải 200 lượt mỗi giây vào API-20-169, 170, 171

**Kết quả mong đợi.** Xem trước ≤ 30 giây; p95 ≤ 100 ms ở API đọc tổ chức.

:::

#### TC-20-222 · Kiểm đếm sáp nhập 100 %; cutover 0 lỗi, thêm trễ ≤ 10 ms; dừng sóng ≤ 5 phút <!--k:perf-merge-wave-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** PERF, IT.

**Truy vết.** NFR-20-014 · NFR-20-015 · NFR-20-016 · FR-20-048, 051, 062.

**Tiền điều kiện, dữ liệu.** PERF; kế hoạch sáp nhập lớn (10 nghìn bản ghi mỗi phân hệ); `mod-sim`; sóng nâng cấp ba tenant.

**Các bước.**

1. Chuyển dữ liệu, so kiểm đếm trừ `SKIP`
2. Cutover khi có 200 lượt gọi mỗi giây vào địa chỉ cũ
3. Đẩy tỷ lệ 5xx của sóng lên 3 %, đo đến khi dừng sóng

**Kết quả mong đợi.** Khớp 100 %; không lượt gọi lỗi do chuyển tiếp, thêm trễ p95 ≤ 10 ms; sóng dừng ≤ 5 phút.

:::

#### TC-20-223 · Gói bàn giao 500 GB hoàn tất ≤ 24 giờ <!--k:perf-export-500gb-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P3.

**Tự động.** PERF.

**Truy vết.** NFR-20-023 · FR-20-041 · API-20-080, 082 · EVT-20-16.

**Tiền điều kiện, dữ liệu.** PERF; `T96` với dữ liệu giả 500 GB ở `s3-sim` (giả định Q20-02, xem Q20-43); `ops-sim`.

**Các bước.**

1. `POST P/tenants/T96/export-packages`; theo dõi đến `READY`

**Kết quả mong đợi.** Gói `READY` ≤ 24 giờ, EVT-20-16 phát một lần; số đo thật chốt ở hạ tầng tỉnh (Q20-43).

:::

### TS-20-42 · Chịu lỗi và phục hồi

**Mục tiêu.** Chạy lại sau khởi động lại DU, ShedLock tránh chạy đôi, sự cố phụ thuộc, Kafka và PH-18 ngừng; không mất tiến độ, không làm hai lần.

**Phủ.** FR-20-008, 028, 044; NFR-20-017, 020; ERR-20-062.

#### TC-20-224 · DU khởi động lại giữa saga, tiếp tục đúng bước <!--k:resilience-restart-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-20-008 · API-20-015 · BR-20-007 · NFR-20-017.

**Tiền điều kiện, dữ liệu.** Hai bản DU PH-20; lần chạy tới `S06` (đang chờ báo).

**Các bước.**

1. Dừng DU đang giữ khóa lần chạy
2. Bản còn lại nhận lần chạy; `S-PH10` báo `S06`

**Kết quả mong đợi.** Lần chạy tiếp tục từ `S06`, không chạy lại `S01…S05`; không bước nào thực hiện hai lần (`Idempotency-Key = {runId}:{stepCode}`).

:::

#### TC-20-225 · ShedLock: thu sử dụng, hết hạn ghi đè, nhắc chuyển tiếp chỉ chạy một bản <!--k:resilience-shedlock-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-20-028, 032, 052 · NFR-20-008.

**Tiền điều kiện, dữ liệu.** Hai bản DU; đồng hồ giả lập đến giờ tròn.

**Các bước.**

1. Cả hai bản cùng đến giờ thu sử dụng và hết hạn ghi đè

**Kết quả mong đợi.** Mỗi việc chạy đúng một lần; không cảnh báo trùng; không thư nhắc trùng.

:::

#### TC-20-226 · Phụ thuộc ngừng: PH-12, PH-13, PH-07, PH-18, Git, Argo CD, Kafka <!--k:resilience-deps-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** ERR-20-062 · ERR-20-024 · ERR-20-109 · NFR-20-020 · FR-20-007, 020.

**Tiền điều kiện, dữ liệu.** Từng bản giả `503`, riêng Kafka ngừng 5 phút.

**Các bước.**

1. Kiểm sẵn sàng khi `iam-sim` `503`
2. Ghi cấu hình khi `git-sim` từ chối
3. Phát sự kiện khi Kafka ngừng

**Kết quả mong đợi.** `ERR-20-017` kèm kiểm `DEPENDENCIES` `BLOCKER` (`ERR-20-062`); `ERR-20-024` 502, không để cấu hình nửa vời; sự kiện giữ ở outbox và phát khi Kafka về, không mất.

:::

### TS-20-43 · Giao diện: trạng thái, quyền hiển thị và WCAG 2.2 AA

**Mục tiêu.** Mỗi màn UI-20-01…22 kiểm bốn trạng thái (đang tải, rỗng, lỗi, bị từ chối), nút hiển thị theo quyền, thao tác nguy hiểm phải gõ lại mã, và đạt WCAG 2.2 AA.

**Phủ.** NFR-20-022; D03-06 mục 3; UI-20-01…22.

#### TC-20-227 · Bốn trạng thái của mọi màn: tải, rỗng, lỗi, không có quyền <!--k:ui-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-20-022 · UI-20-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 · ERR-20-062 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** Playwright; `U-PA1`, `U-T90-TA`, `U-T90-VW`; chặn API chậm, trả rỗng, `503`, `403` theo màn.

**Các bước.**

1. Với từng màn, làm API trả chậm 3 giây
2. Làm API trả danh sách rỗng
3. Làm API trả `503`
4. Mở màn bằng vai không có quyền

**Kết quả mong đợi.** Bước 1 khung xương tải, không nhảy bố cục. Bước 2 trạng thái rỗng có hướng dẫn tiếp theo. Bước 3 thông báo lỗi tiếng Việt có mã và nút "Thử lại", không lộ chi tiết kỹ thuật. Bước 4 trang "Không có quyền" (hoặc ẩn mục), không gọi API ghi.

:::

#### TC-20-228 · Nút và mục menu theo quyền; thao tác nguy hiểm gõ lại mã <!--k:ui-role-visibility-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** UI-20-02, 03, 08, 09, 10, 12, 14, 15, 18, 19 · BR-20-008, 009 · ERR-20-007, ERR-20-008 · `PERM-20-lifecycle`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-org`, `PERM-20-settings`, `PERM-20-approve`.

**Tiền điều kiện, dữ liệu.** `U-PA1`, `U-PA2`, `U-PO`, `U-PAU`, `U-T90-TA`, `U-T90-VW`.

**Các bước.**

1. Mỗi vai mở các màn, ghi lại nút ghi hiển thị
2. Mở "Chấm dứt", "Cutover", "Giải thể tổ chức"; để trống ô gõ lại mã
3. Mở đề nghị do chính mình lập bằng `U-PA1`

**Kết quả mong đợi.** Bước 1 vai chỉ đọc không thấy nút ghi; PO chỉ thấy "Dừng sóng". Bước 2 nút xác nhận vô hiệu đến khi gõ đúng mã; thiếu lý do hiện `ERR-20-008`. Bước 3 nút "Duyệt" ẩn, nếu gọi tay thì `403` `ERR-20-007`.

:::

#### TC-20-229 · WCAG 2.2 AA: bàn phím, tương phản, tiêu điểm, đọc màn hình, co dãn 200 % <!--k:ui-wcag-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, A11Y.

**Truy vết.** NFR-20-022 · UI-20-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22.

**Tiền điều kiện, dữ liệu.** Playwright với axe-core; NVDA ở STAGING cho ba màn (UI-20-02, 04, 10); trình duyệt Chrome, Firefox.

**Các bước.**

1. Quét axe mọi màn ở trạng thái mặc định và có lỗi
2. Duyệt toàn bộ bằng bàn phím: thứ tự Tab, bẫy tiêu điểm hộp thoại, `Esc` đóng
3. Kiểm tương phản chữ ≥ 4,5:1, thành phần ≥ 3:1, phóng 200 % không cuộn ngang
4. Đọc bằng NVDA: nhãn trường, vùng thông báo `aria-live` khi tiến độ saga đổi
5. Kiểm trạng thái không chỉ dựa màu; mục tiêu bấm ≥ 24×24 px

**Kết quả mong đợi.** Không vi phạm mức nghiêm trọng hoặc cao của axe; mọi chức năng dùng được bằng bàn phím; thông báo tiến độ được đọc; trạng thái có chữ và biểu tượng.

:::

#### TC-20-230 · Wizard khai báo tenant: kiểm hợp lệ từng bước, giữ bản nháp <!--k:ui-wizard-validate-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-20-02 · UI-20-09 · FR-20-001, 007 · ERR-20-004, ERR-20-003, ERR-20-011.

**Tiền điều kiện, dữ liệu.** `U-PA1`; mã `T93` đã dùng.

**Các bước.**

1. Đi 5 bước của UI-20-02, để trống trường bắt buộc rồi bấm "Tiếp"
2. Nhập mã `T90` (đã dùng) rồi sang bước sau
3. Thoát giữa chừng rồi quay lại

**Kết quả mong đợi.** Bước 1 lỗi hiện ngay cạnh trường, tiêu điểm về trường lỗi. Bước 2 `ERR-20-003` hiện ở bước mã. Bước 3 bản nháp giữ lại (nếu có), không gửi khi chưa xác nhận.

:::

### TS-20-44 · Đầu cuối: khởi tạo tỉnh, sáp nhập hai tỉnh, phát hành theo sóng

**Mục tiêu.** Ba kịch bản đầu cuối ở STAGING xuyên nhiều phân hệ giả lập: khởi tạo `T93` tới `ACTIVE`, sáp nhập `T91` vào `T90` từ kế hoạch đến hoàn tất, phát hành 2.4.0 theo ba sóng dừng do ngưỡng.

**Phủ.** FR-20-001…014, 045…052, 059…064; BR-20-020, 023…026, 031…033.

#### TC-20-231 · Khai báo, kiểm sẵn sàng, saga 17 bước, kiểm tra khói, ACTIVE, KPI-12 <!--k:e2e-provision-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-20-001, 007, 008, 012, 013, 014 · UC-20-01, 05, 06, 07 · NFR-00-057 · NFR-20-002 · EVT-20-01, 03.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`; F-HS-93, F-TPL, F-SAGA `OK`; mọi giả lập.

**Các bước.**

1. Khai báo `T93` bằng wizard UI-20-02
2. Kiểm sẵn sàng đạt; chạy saga; theo dõi UI-20-04
3. Kích hoạt; quản trị tỉnh đầu tiên của `T93` (`T93-TA`) đăng nhập
4. Kiểm KPI-12, tổ chức gieo, hạn mức, phân hệ

**Kết quả mong đợi.** `T93` `ACTIVE` trong ≤ 60 phút; EVT-20-01 và EVT-20-03; quản trị tỉnh đổi mật khẩu, bật MFA; hạn mức theo mẫu; tổ chức cấp tỉnh có; KPI-12 ghi nhận ≤ 1 ngày làm việc.

:::

#### TC-20-232 · Sáp nhập T91 vào T90: lập, chạy thử, duyệt, chuyển, xử lý xung đột, định danh, cutover, hoàn tất <!--k:e2e-merge-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-20-045, 046, 047, 048, 049, 050, 051, 052 · UC-20-24, 25, 26, 27, 28, 29 · BR-20-023, 024, 025, 026 · NFR-20-014, 015 · EVT-20-04, 10, 11, 12.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`, `U-PA2`; F-MERGE, F-ORG, F-HTTT (120 HTTT của `T91`); `iam-sim`, `ops-sim`, `mod-sim`.

**Các bước.**

1. Lập kế hoạch, sinh ánh xạ, xử lý 6 xung đột, chạy thử `PASSED`
2. `U-PA1` gửi, `U-PA2` duyệt; bắt đầu chuyển; kiểm đếm
3. Chuyển định danh; cấp thông tin xác thực song song
4. Cutover trong cửa sổ bảo trì; gọi địa chỉ cũ của `T91`
5. Trước hết chuyển tiếp: gia hạn một lần; tới hạn kết thúc

**Kết quả mong đợi.** Mỗi bước đúng trạng thái; đích giữ `id` gốc và `origin_tenant_id`; kiểm đếm 100 %; sau cutover địa chỉ cũ có `Deprecation`, `Sunset`; nguồn `MERGED` rồi `DECOMMISSIONED`; EVT-20-10, 11, 12 phát đúng một lần; 120 HTTT thuộc `T90` sau kết thúc.

:::

#### TC-20-233 · Phát hành 2.4.0 theo ba sóng, sóng 2 dừng do ngưỡng, xử lý, tiếp tục, hoàn tất <!--k:e2e-release-wave-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-20-059, 060, 061, 062, 063 · UC-20-32, 33, 34 · BR-20-031, 032, 033 · NFR-20-016 · ERR-20-057 · EVT-20-14, 15.

**Tiền điều kiện, dữ liệu.** STAGING; `U-PA1`, `U-PO`; F-REL (`2.4.0` `PREVIEW` 15 ngày); ba sóng (`T90`; `T91`, `T92`; `T93`).

**Các bước.**

1. `:promote` `2.4.0` sang `STABLE`; lập kế hoạch ba sóng; lên lịch; thông báo
2. Sóng 1 chạy, theo dõi 48 giờ
3. Sóng 2: tỷ lệ 5xx 3 % thì dừng; tiếp tục chưa xác nhận bị chặn
4. Xác nhận xử lý rồi tiếp tục; sóng 3 chạy

**Kết quả mong đợi.** Sóng 2 dừng ≤ 5 phút sau khi vượt ngưỡng, sóng 3 không chạy; `ERR-20-057` khi tiếp tục chưa xác nhận; sau xử lý mọi tenant `DONE`, kế hoạch `COMPLETED`; EVT-20-14 hai lần (PREVIEW, STABLE), EVT-20-15 theo từng tenant.

:::


## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Mỗi phiên 90 phút do kiểm thử viên cùng quản trị nền tảng thật thực hiện ở STAGING, tập trung vào nhầm tenant khi thao tác (đặc biệt `T90` và `T91` trong sáp nhập), nhầm trạng thái `SUSPENDED` và `MERGED`, đọc sai cột "hiệu lực" của hạn mức, bỏ sót bước gõ lại mã ở thao tác nguy hiểm và nhầm người lập, người duyệt ở bốn mắt.

### 6.2. Tính tay hạn mức và thời gian

Trước mỗi lần phát hành, kiểm thử viên tính tay hạn mức hiệu lực của `T96` (max giữa hợp đồng và ghi đè còn hạn, không quá trần), tỷ lệ sử dụng `API_RPS` (400 trên 500 là 80 %), ngưỡng đặt lại 75 % và `leadTimeWorkingHours` của KPI-12 theo lịch làm việc, rồi so với màn UI-20-05, UI-20-13 và `GET P/provisioning-metrics`; lệch một đơn vị là lỗi S2.

### 6.3. Kiểm chứng bản gói bàn giao và kho cấu hình bằng công cụ ngoài

Cán bộ ATTT tải gói bàn giao (ca export-ok), tự tính SHA-256 theo từng phân hệ, mở lại tệp bằng công cụ ngoài và kiểm đủ thành phần; đồng thời đọc kho `dh-tenant-config` bằng `git log --show-signature` để kiểm commit ký, và kiểm không có bí mật (chỉ tham chiếu Vault).

### 6.4. Diễn tập sự cố

Diễn tập ở STAGING bốn tình huống: PH-12 ngừng giữa saga khởi tạo; Argo CD báo `Degraded` giữa sóng nâng cấp; mất kết nối PH-03 đúng lúc cutover; Kafka ngừng 5 phút khi đổi trạng thái tenant. Với mỗi tình huống, ghi thời gian phát hiện, thời gian khắc phục và việc làm tay.

## 7. Nghiệm thu người dùng

PH-20 là năng lực mới nên không có nghiệm thu "tương đương hệ cũ". Quản trị nền tảng, vận hành, quản trị tỉnh và kiểm toán viên của tỉnh thí điểm tự thực hiện trên UAT với tenant kiểm thử `T90…T99`; đạt khi làm được không cần hướng dẫn ngoài tài liệu. Cột "Liên quan hệ cũ" ghi mục hệ cũ liên quan gián tiếp (FRS mục 2.6).

| Mã | Việc cần làm | Liên quan hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Khai báo tỉnh mới `T93`, kiểm tra sẵn sàng, chạy khởi tạo và theo dõi 17 bước tới kích hoạt | LGC-IAM-002, LGC-BUS-031 | Tenant `ACTIVE` trong 60 phút, kiểm tra khói đạt, quản trị tỉnh đầu tiên đăng nhập được, hạn mức theo mẫu | FR-20-001, 007, 008, 012, 013 | TS-20-02, 05, 07, 44 |
| UAT-02 | Xử lý một bước lỗi: thử lại, bỏ qua theo luật, bù trừ và hủy khởi tạo | — | Bước lỗi thử lại được; bù trừ ngược không để tài nguyên mồ côi; không bỏ qua bước bắt buộc | FR-20-010, 011 | TS-20-06, 40 |
| UAT-03 | Tạm ngừng một tỉnh do sự cố, kiểm tỉnh chỉ đọc rồi khôi phục | — | Lượt ghi bị chặn trong 60 giây, đọc vẫn dùng được, khôi phục trở lại bình thường, có lịch sử và thư báo | FR-20-038, 039 | TS-20-20, 23, 41 |
| UAT-04 | Đặt hạn mức hợp đồng, ghi đè tạm thời, xem sử dụng và xử lý cảnh báo 80 % | — | Hạn mức hiệu lực đúng, cảnh báo một lần, đặt lại khi dưới 75 %, hạ dưới mức đang dùng cần người duyệt khác | FR-20-026, 027, 028, 029, 032 | TS-20-14, 15, 16 |
| UAT-05 | Đề nghị chấm dứt, duyệt bốn mắt, xuất gói bàn giao, xác nhận và thực hiện sau thời gian nguội | — | Chấm dứt bị chặn khi thiếu bàn giao hoặc chưa hết nguội; hai người khác nhau; xóa mật mã được xác nhận | FR-20-040, 041, 042 | TS-20-21, 22 |
| UAT-06 | Sáp nhập hai tỉnh: lập kế hoạch, chạy thử, duyệt, chuyển, xử lý xung đột, cutover, hoàn tất | — | Kiểm đếm khớp 100 %, địa chỉ cũ vẫn dùng kèm `Deprecation`, nguồn `MERGED` rồi đóng hẳn | FR-20-045…052 | TS-20-24…29, 44 |
| UAT-07 | Quản trị tỉnh nhập danh mục tổ chức, giải thể một tổ chức có kế thừa, xử lý đề xuất sắp xếp ĐVHC | LGC-IAM-002 | Xem trước đúng, dòng lỗi chặn xác nhận, giải thể buộc chọn kế thừa, tổ chức con chuyển cha | FR-20-053, 054, 055, 056 | TS-20-30, 31 |
| UAT-08 | Đăng ký phiên bản, đưa lên `PREVIEW` và `STABLE`, lập kế hoạch ba sóng, theo dõi, dừng sóng và quay lui | — | Sóng tự dừng khi lỗi vượt 2 %, tiếp tục cần xác nhận, quay lui bị chặn khi có `CONTRACT`, tỉnh được báo lịch | FR-20-059…064 | TS-20-32, 33, 34, 44 |

: Kịch bản nghiệm thu UAT-01…08 theo vai trò

## 8. Ma trận truy vết

Ma trận sinh tự động từ chính các ca bằng `ph20/tools/gen_matrix.py` nên luôn khớp với chương 4 và 5; ô "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-20.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-20. FR mức M phải có ít nhất một ca ở mỗi cột; FR mức S chỉ cần một ca (dấu "—" ở cột Đạt nghĩa là chưa có ca âm, không bắt buộc).

| FR | Mức | Dương | Âm | Đạt |
|---|---|---|---|---|
| FR-20-001 | M | 005, 230, 231 | 006, 007, 008, 230 | Có |
| FR-20-002 | M | 001 | 002 | Có |
| FR-20-003 | M | 003 | 004 | Có |
| FR-20-004 | M | 013 | 014 | Có |
| FR-20-005 | S | 016 | 017 | Có |
| FR-20-006 | M | 018 | 015 | Có |
| FR-20-007 | M | 010, 208, 230, 231 | 007, 008, 011, 012, 226, 230 | Có |
| FR-20-008 | M | 022, 023, 025, 203, 204, 205, 206, 208, 209, 210, 211, 212 (+3) | 024, 025, 203, 204, 205, 206, 209, 210, 211, 212, 213, 214 | Có |
| FR-20-009 | M | 025, 026, 206, 209, 210, 212 | 025, 206, 207, 209, 210, 212 | Có |
| FR-20-010 | M | 027, 028, 203 | 028, 029, 203 | Có |
| FR-20-011 | M | 030, 203, 204, 205 | 031, 203, 204, 205 | Có |
| FR-20-012 | M | 022, 032, 231 | 033, 213 | Có |
| FR-20-013 | M | 022, 034, 214, 231 | 035, 214 | Có |
| FR-20-014 | S | 034, 036, 214, 231 | 035, 036, 214 | Có |
| FR-20-015 | S | 019 | 020, 021 | Có |
| FR-20-016 | S | 037 | 024, 038 | Có |
| FR-20-017 | S | 039 | 040 | Có |
| FR-20-018 | M | 049, 051 | 050, 052 | Có |
| FR-20-019 | M | 041 | 042 | Có |
| FR-20-020 | M | 041 | 043, 226 | Có |
| FR-20-021 | S | 045 | 046 | Có |
| FR-20-022 | S | 047 | 048 | Có |
| FR-20-023 | M | 053 | 054 | Có |
| FR-20-024 | S | 055 | 056 | Có |
| FR-20-025 | S | 057 | 058, 195 | Có |
| FR-20-026 | M | 059 | 060 | Có |
| FR-20-027 | M | 061 | 060, 062, 065, 195 | Có |
| FR-20-028 | M | 066, 225 | 067 | Có |
| FR-20-029 | M | 068, 069 | 069 | Có |
| FR-20-030 | M | 070 | 071 | Có |
| FR-20-031 | S | 072 | 073 | Có |
| FR-20-032 | S | 063, 225 | 064 | Có |
| FR-20-033 | M | 074 | 079 | Có |
| FR-20-034 | M | 075, 212 | 076, 077, 212 | Có |
| FR-20-035 | M | 081 | 082 | Có |
| FR-20-036 | S | 083 | 084 | Có |
| FR-20-037 | M | 078 | 080 | Có |
| FR-20-038 | M | 090 | 091 | Có |
| FR-20-039 | M | 093 | 094 | Có |
| FR-20-040 | M | 095, 099 | 096, 195 | Có |
| FR-20-041 | M | 097 | 098, 195 | Có |
| FR-20-042 | M | 100 | 101, 102, 103 | Có |
| FR-20-043 | M | 099, 104 | 105 | Có |
| FR-20-044 | M | 090, 106 | 107 | Có |
| FR-20-045 | M | 108, 110, 115, 232 | 109, 110, 114, 116, 195 | Có |
| FR-20-046 | M | 111, 232 | 112 | Có |
| FR-20-047 | M | 113, 117, 232 | 114, 117 | Có |
| FR-20-048 | M | 117, 118, 120, 125, 232 | 117, 119, 120 | Có |
| FR-20-049 | M | 122, 124, 125, 232 | 123 | Có |
| FR-20-050 | M | 126, 232 | 127 | Có |
| FR-20-051 | M | 128, 232 | 129 | Có |
| FR-20-052 | M | 132, 133, 135, 225, 232 | 132, 134 | Có |
| FR-20-053 | M | 136, 138 | 137 | Có |
| FR-20-054 | M | 144, 146, 148, 149 | 145, 147, 148, 149 | Có |
| FR-20-055 | M | 139, 141, 142 | 140 | Có |
| FR-20-056 | S | 150 | 151 | Có |
| FR-20-057 | M | 088 | 089, 188 | Có |
| FR-20-058 | S | 088, 143 | 143 | Có |
| FR-20-059 | M | 152, 157, 233 | 153, 157 | Có |
| FR-20-060 | M | 001, 154, 158, 233 | 155, 158 | Có |
| FR-20-061 | M | 159, 161, 166, 233 | 160, 162 | Có |
| FR-20-062 | S | 167, 169, 170, 172, 173, 174, 233 | 169, 171, 172, 173, 174 | Có |
| FR-20-063 | S | 161, 164, 233 | 165 | Có |
| FR-20-064 | S | 051, 166 | 052 | Có |
| FR-20-065 | M | 085, 209 | 086, 188, 190, 209 | Có |
| FR-20-066 | M | 078, 087 | 087, 186, 187, 189, 191, 193 | Có |
| FR-20-067 | S | 175 | 176 | Có |
| FR-20-068 | M | 181, 201 | 182 | Có |
| FR-20-069 | M | 180, 183, 184 | 184, 185 | Có |
| FR-20-070 | S | 177, 180, 192 | 178, 179, 186 | Có |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

PH-20 là năng lực mới (hệ cũ không có khái niệm tenant), không có `LGC` do PH-20 làm chính. Hai mục dưới là chức năng hệ cũ mà PH-20 phủ hoặc tham gia gián tiếp (FRS mục 2.6, 11.1). Ca ở cột "TC" kiểm phần PH-20 bổ sung, không kiểm chức năng của hệ cũ.

| LGC | FR của PH-20 | TC | UAT |
|---|---|---|---|
| LGC-IAM-002 | 018, 053, 054, 055, 008 | 022, 023, 025, 049, 051, 136, 138, 139, 141, 142 (+16) | UAT-01, UAT-07 |
| LGC-BUS-031 | 001, 008, 019, 020 | 005, 022, 023, 025, 041, 203, 204, 205, 206, 208 (+8) | UAT-01 |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Use case → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ use case này.

| Mã | Test case |
|---|---|
| UC-20-01 | 001, 003, 231 |
| UC-20-02 | 005, 010 |
| UC-20-03 | 013, 018 |
| UC-20-04 | 019 |
| UC-20-05 | 022, 023, 231 |
| UC-20-06 | 026, 027, 030, 231 |
| UC-20-07 | 032, 034, 231 |
| UC-20-08 | 037, 039 |
| UC-20-09 | 041, 044 |
| UC-20-10 | 045, 047 |
| UC-20-11 | 049, 051 |
| UC-20-12 | 053, 055 |
| UC-20-13 | 057 |
| UC-20-14 | 059, 061, 063, 065 |
| UC-20-15 | 066, 067, 068 |
| UC-20-16 | 070 |
| UC-20-17 | 074, 075, 077, 078 |
| UC-20-18 | 081, 083 |
| UC-20-19 | 085, 087, 088 |
| UC-20-20 | 090, 092, 093 |
| UC-20-21 | 095, 097 |
| UC-20-22 | 100, 102, 103 |
| UC-20-23 | 104, 106, 107 |
| UC-20-24 | 108, 111, 232 |
| UC-20-25 | 113, 115, 232 |
| UC-20-26 | 118, 121, 232 |
| UC-20-27 | 122, 125, 232 |
| UC-20-28 | 126, 128, 130, 131, 232 |
| UC-20-29 | 132, 133, 135, 232 |
| UC-20-30 | 136, 138, 139, 141, 143 |
| UC-20-31 | 144, 146, 150 |
| UC-20-32 | 152, 154, 156, 233 |
| UC-20-33 | 159, 161, 163, 164, 233 |
| UC-20-34 | 167, 168, 170, 172, 233 |
| UC-20-35 | 175, 177, 178, 180, 190 |
| UC-20-36 | 181, 183, 184 |

: Use case tới test case

### 8.4. Màn hình → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-20-01 | 001, 002, 003, 219, 227, 229 |
| UI-20-02 | 005, 006, 010, 039, 227, 228, 229, 230 |
| UI-20-03 | 003, 004, 013, 016, 041, 043, 057, 104, 158, 181 (+4) |
| UI-20-04 | 022, 026, 027, 030, 032, 034, 037, 039, 227, 229 |
| UI-20-05 | 059, 061, 063, 065, 227, 229 |
| UI-20-06 | 067, 068, 069, 070, 072, 227, 229 |
| UI-20-07 | 074, 075, 077, 078, 081, 083, 227, 229 |
| UI-20-08 | 061, 090, 092, 093, 095, 097, 099, 100, 103, 115 (+3) |
| UI-20-09 | 108, 111, 113, 115, 227, 228, 229, 230 |
| UI-20-10 | 113, 115, 118, 120, 122, 124, 126, 128, 132, 133 (+3) |
| UI-20-11 | 108, 219, 227, 229 |
| UI-20-12 | 049, 051, 164, 166, 227, 228, 229 |
| UI-20-13 | 070, 227, 229 |
| UI-20-14 | 136, 142, 150, 219, 227, 228, 229 |
| UI-20-15 | 136, 144, 149, 199, 227, 228, 229 |
| UI-20-16 | 139, 140, 227, 229 |
| UI-20-17 | 043, 045, 047, 227, 229 |
| UI-20-18 | 152, 154, 219, 227, 228, 229 |
| UI-20-19 | 159, 161, 164, 167, 170, 174, 227, 228, 229 |
| UI-20-20 | 036, 037, 175, 176, 177, 178, 227, 229 |
| UI-20-21 | 019, 227, 229 |
| UI-20-22 | 053, 055, 227, 229 |

: Màn hình tới test case

### 8.5. API → test case

Nhóm API và ca rò rỉ chéo tenant (SEC-87) xem thêm TS-20-37.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ api này.

| Mã | Test case |
|---|---|
| API-20-001 | 001, 002, 187, 197, 200, 219 |
| API-20-002 | 005, 006, 007, 008, 009, 021, 194, 198 |
| API-20-003 | 003, 004, 018, 187, 200 |
| API-20-004 | 013, 014, 015, 018, 187, 199 |
| API-20-005 | 010, 011, 012 |
| API-20-006 | 010, 011, 012 |
| API-20-007 | 016 |
| API-20-008 | 016, 017 |
| API-20-009 | 016, 017 |
| API-20-010 | 016 |
| API-20-011 | 016, 017 |
| API-20-012 | 016, 017 |
| API-20-013 | 022, 023, 024, 037, 038, 203, 204, 208, 211 |
| API-20-014 | 026 |
| API-20-015 | 022, 026, 032, 034, 224 |
| API-20-016 | 026 |
| API-20-017 | 027, 029, 203 |
| API-20-018 | 027, 028, 203, 204, 205 |
| API-20-019 | 028 |
| API-20-020 | 030, 031, 203, 204, 205 |
| API-20-021 | 030, 031 |
| API-20-022 | 032, 033, 213 |
| API-20-023 | 033, 034, 035, 214 |
| API-20-024 | 036 |
| API-20-025 | 019 |
| API-20-026 | 019, 020 |
| API-20-027 | 019 |
| API-20-028 | 019, 020 |
| API-20-029 | 019 |
| API-20-030 | 019, 020 |
| API-20-031 | 019, 020 |
| API-20-032 | 019, 020, 021 |
| API-20-033 | 037, 038 |
| API-20-034 | 037, 038 |
| API-20-035 | 039 |
| API-20-036 | 039, 040, 044 |
| API-20-037 | 039, 040 |
| API-20-038 | 039, 040 |
| API-20-039 | 041, 043 |
| API-20-040 | 041, 042, 043, 044 |
| API-20-041 | 045 |
| API-20-042 | 045, 046 |
| API-20-043 | 045, 046 |
| API-20-044 | 047, 048 |
| API-20-045 | 047, 048 |
| API-20-046 | 047, 048 |
| API-20-047 | 015, 057, 058 |
| API-20-048 | 059, 063, 065 |
| API-20-049 | 059, 060, 194 |
| API-20-050 | 061, 062 |
| API-20-051 | 061 |
| API-20-052 | 061, 062 |
| API-20-053 | 061, 062 |
| API-20-054 | 063, 064 |
| API-20-055 | 063, 064 |
| API-20-056 | 066, 070, 071 |
| API-20-057 | 066, 070, 071 |
| API-20-058 | 069 |
| API-20-059 | 069 |
| API-20-060 | 072, 073 |
| API-20-061 | 072 |
| API-20-062 | 072, 073 |
| API-20-063 | 074, 079 |
| API-20-064 | 074, 075, 079, 081 |
| API-20-065 | 015, 075, 076, 077 |
| API-20-066 | 015, 081, 082 |
| API-20-067 | 081, 082 |
| API-20-068 | 081, 082 |
| API-20-069 | 083 |
| API-20-070 | 083, 084 |
| API-20-071 | 015, 090, 091, 092, 093, 094, 095, 096, 194 |
| API-20-072 | 099, 104, 105 |
| API-20-073 | 095, 099 |
| API-20-074 | 095, 099, 104 |
| API-20-075 | 057, 095, 096 |
| API-20-076 | 057, 095, 096 |
| API-20-077 | 095 |
| API-20-078 | 096 |
| API-20-079 | 057, 058, 090, 091, 093, 094, 100, 101, 102, 103 |
| API-20-080 | 097, 098, 223 |
| API-20-081 | 097 |
| API-20-082 | 097, 098, 223 |
| API-20-083 | 097, 098 |
| API-20-084 | 097, 098 |
| API-20-085 | 104, 105 |
| API-20-086 | 108, 109, 187, 194, 198 |
| API-20-087 | 108, 219 |
| API-20-088 | 108, 118 |
| API-20-089 | 108, 109, 110 |
| API-20-090 | 114, 115, 116 |
| API-20-091 | 115, 116 |
| API-20-092 | 115, 116 |
| API-20-093 | 110 |
| API-20-094 | 111 |
| API-20-095 | 111, 112 |
| API-20-096 | 111, 112 |
| API-20-097 | 113, 114 |
| API-20-098 | 118, 119, 121 |
| API-20-099 | 118, 120 |
| API-20-100 | 120 |
| API-20-101 | 122 |
| API-20-102 | 122, 123, 125 |
| API-20-103 | 124 |
| API-20-104 | 126, 127 |
| API-20-105 | 126 |
| API-20-106 | 121, 128, 129, 130 |
| API-20-107 | 132 |
| API-20-108 | 133, 134 |
| API-20-109 | 152, 187, 219 |
| API-20-110 | 152, 153, 194, 198 |
| API-20-111 | 152 |
| API-20-112 | 152, 153, 199 |
| API-20-113 | 154, 155 |
| API-20-114 | 154, 155, 156 |
| API-20-115 | 157 |
| API-20-116 | 157 |
| API-20-117 | 158 |
| API-20-118 | 159, 160, 163, 187 |
| API-20-119 | 159, 161, 167, 168, 170, 174 |
| API-20-120 | 159, 160, 199 |
| API-20-121 | 161, 162, 163 |
| API-20-122 | 169 |
| API-20-123 | 168, 169 |
| API-20-124 | 170, 171 |
| API-20-125 | 172 |
| API-20-126 | 167, 168, 173, 174 |
| API-20-127 | 173 |
| API-20-128 | 163, 164, 165 |
| API-20-129 | 175, 176, 187, 194 |
| API-20-130 | 181, 182, 187 |
| API-20-131 | 183, 185, 187 |
| API-20-132 | 177, 178, 179, 192, 194 |
| API-20-133 | 177, 179 |
| API-20-134 | 177, 178, 179, 192 |
| API-20-135 | 049, 186, 191, 196, 197 |
| API-20-136 | 049, 050, 194 |
| API-20-137 | 053, 186 |
| API-20-138 | 053, 054 |
| API-20-139 | 055, 056, 186 |
| API-20-140 | 070, 071, 186, 194 |
| API-20-141 | 070, 071, 186 |
| API-20-142 | 078, 080, 087, 186 |
| API-20-143 | 136, 138, 186, 191, 219 |
| API-20-144 | 136, 137, 194, 196, 198, 200 |
| API-20-145 | 136, 186 |
| API-20-146 | 136, 137, 138, 199 |
| API-20-147 | 148 |
| API-20-148 | 148 |
| API-20-149 | 144, 145 |
| API-20-150 | 146, 147 |
| API-20-151 | 144, 146, 149, 186 |
| API-20-152 | 143 |
| API-20-153 | 139, 140, 141, 221 |
| API-20-154 | 139, 140, 141, 186, 221 |
| API-20-155 | 139, 140, 141 |
| API-20-156 | 142 |
| API-20-157 | 150, 151, 186 |
| API-20-158 | 150, 151 |
| API-20-159 | 051, 166, 186 |
| API-20-160 | 051, 052, 166 |
| API-20-161 | 181, 182, 186 |
| API-20-162 | 018, 085, 086, 188, 197, 217 |
| API-20-163 | 018, 078, 080, 085, 086, 087, 188, 217 |
| API-20-164 | 059, 061, 065, 085, 086, 128, 130, 131, 188, 209 (+1) |
| API-20-165 | 053, 086, 188 |
| API-20-166 | 022, 025, 075, 077, 188, 206, 207, 209, 210, 212 |
| API-20-167 | 113, 117, 118, 119, 125, 188 |
| API-20-168 | 097, 098, 188 |
| API-20-169 | 088, 089, 188, 221 |
| API-20-170 | 088, 089, 188, 221 |
| API-20-171 | 088, 089, 143, 188, 221 |

: API tới test case

### 8.6. Mã lỗi → test case

Mã `ERR-20-106…113`, `116`, `117` là lỗi chạy nền không có mã HTTP (FRS mục 9.1); ca kiểm ở sổ bước, trạng thái lần chạy, cảnh báo và thông báo thay cho mã HTTP.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-20-001 | 050, 052, 054, 087, 090, 193, 218 |
| ERR-20-002 | 004, 025, 046, 048, 050, 069, 071, 073, 079, 084 (+24) |
| ERR-20-003 | 006, 020, 030, 040, 112, 123, 137, 153, 230 |
| ERR-20-004 | 002, 004, 006, 009, 017, 025, 028, 031, 036, 038 (+58) |
| ERR-20-005 | 014, 017, 028, 029, 035, 042, 046, 050, 052, 054 (+27) |
| ERR-20-006 | 014, 020, 021, 024, 028, 029, 031, 033, 035, 038 (+43) |
| ERR-20-007 | 062, 096, 098, 101, 116, 169, 195, 228 |
| ERR-20-008 | 014, 017, 028, 031, 038, 042, 046, 048, 060, 064 (+10) |
| ERR-20-009 | 009, 024, 028, 069, 073, 140, 171, 179, 198 |
| ERR-20-010 | 015, 024, 042, 046, 048, 060, 064, 076, 082, 084 (+1) |
| ERR-20-011 | 007, 230 |
| ERR-20-012 | 007, 137 |
| ERR-20-013 | 011 |
| ERR-20-014 | 011 |
| ERR-20-015 | 008, 021 |
| ERR-20-016 | 024, 033, 038 |
| ERR-20-017 | 011, 024, 226 |
| ERR-20-018 | 028, 029, 203 |
| ERR-20-019 | 031, 203, 205 |
| ERR-20-020 | 033, 035, 213 |
| ERR-20-021 | 008, 017, 035, 107, 214 |
| ERR-20-022 | 017, 060 |
| ERR-20-023 | 050 |
| ERR-20-024 | 043, 226 |
| ERR-20-025 | 042 |
| ERR-20-026 | 046 |
| ERR-20-027 | 054 |
| ERR-20-028 | 058 |
| ERR-20-029 | 020, 060, 062, 064 |
| ERR-20-030 | 060 |
| ERR-20-031 | 064 |
| ERR-20-032 | 036, 056, 071, 073, 182 |
| ERR-20-033 | 020, 076 |
| ERR-20-034 | 082 |
| ERR-20-035 | 082 |
| ERR-20-036 | 084 |
| ERR-20-037 | 094, 096, 101 |
| ERR-20-038 | 096, 101 |
| ERR-20-039 | 098 |
| ERR-20-040 | 109 |
| ERR-20-041 | 109 |
| ERR-20-042 | 112, 114 |
| ERR-20-043 | 114, 116, 119, 120 |
| ERR-20-044 | 127, 129 |
| ERR-20-045 | 109, 132 |
| ERR-20-046 | 134 |
| ERR-20-047 | 137 |
| ERR-20-048 | 145, 147 |
| ERR-20-049 | 143, 145, 151 |
| ERR-20-050 | 140 |
| ERR-20-051 | 140 |
| ERR-20-052 | 137 |
| ERR-20-053 | 153 |
| ERR-20-054 | 155, 156 |
| ERR-20-055 | 076, 157, 160 |
| ERR-20-056 | 160, 163 |
| ERR-20-057 | 168, 173, 233 |
| ERR-20-058 | 171, 173 |
| ERR-20-059 | 052, 058, 129, 162 |
| ERR-20-060 | 184 |
| ERR-20-061 | 158 |
| ERR-20-062 | 012, 035, 056, 067, 079, 103, 107, 112, 127, 143 (+9) |
| ERR-20-063 | 020 |
| ERR-20-064 | 008, 040 |
| ERR-20-065 | 179 |
| ERR-20-066 | 073 |
| ERR-20-067 | 042 |
| ERR-20-068 | 014, 042 |
| ERR-20-101 | 087, 193 |
| ERR-20-102 | 080, 087, 100, 103, 133, 193 |
| ERR-20-103 | 081, 087, 193 |
| ERR-20-104 | 025, 080, 086, 089, 098, 117, 188, 197, 207 |
| ERR-20-105 | 025, 206, 207 |
| ERR-20-106 | 077, 206, 209, 210, 212 |
| ERR-20-107 | 031, 038, 077, 091, 098, 114, 204, 205, 206, 208 (+3) |
| ERR-20-108 | 215 |
| ERR-20-109 | 043, 168, 226 |
| ERR-20-110 | 067 |
| ERR-20-111 | 033, 178 |
| ERR-20-112 | 168 |
| ERR-20-113 | 058, 114, 119, 129 |
| ERR-20-114 | 117 |
| ERR-20-115 | 050, 087, 130, 193 |
| ERR-20-116 | 102 |
| ERR-20-117 | 033, 094, 213 |
| ERR-20-118 | 087, 167, 193 |

: Mã lỗi tới test case

### 8.7. Sự kiện → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-20-01 | 022, 202, 209, 210, 231 |
| EVT-20-02 | 027, 202, 203 |
| EVT-20-03 | 022, 034, 202, 214, 231 |
| EVT-20-04 | 030, 057, 090, 093, 100, 106, 110, 118, 128, 133 (+5) |
| EVT-20-05 | 059, 061, 063, 065, 202 |
| EVT-20-06 | 068, 202 |
| EVT-20-07 | 022, 037, 075, 202, 212 |
| EVT-20-08 | 081, 202, 212 |
| EVT-20-09 | 041, 045, 049, 053, 057, 202 |
| EVT-20-10 | 118, 202, 232 |
| EVT-20-11 | 128, 202, 232 |
| EVT-20-12 | 133, 202, 232 |
| EVT-20-13 | 136, 139, 143, 144, 146, 148, 150, 190, 202, 211 |
| EVT-20-14 | 154, 157, 202, 233 |
| EVT-20-15 | 161, 167, 168, 170, 202, 233 |
| EVT-20-16 | 097, 202, 223 |

: Sự kiện tới test case

### 8.8. Quy tắc nghiệp vụ → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-20-001 | 005, 006, 014, 030, 042 |
| BR-20-002 | 005, 007, 011 |
| BR-20-003 | 015, 082 |
| BR-20-004 | 022, 032, 033, 034, 177, 180, 183, 184, 213 |
| BR-20-005 | 022, 025, 027, 030 |
| BR-20-006 | 022, 024, 037 |
| BR-20-007 | 027, 203, 204, 206, 208, 215, 224 |
| BR-20-008 | 057, 061, 062, 095, 096, 097, 098, 101, 115, 116 (+4) |
| BR-20-009 | 005, 013, 014, 016, 018, 042, 181, 189, 198, 201 (+1) |
| BR-20-010 | 041, 043, 044, 045, 047 |
| BR-20-011 | 049, 050 |
| BR-20-012 | 053, 054 |
| BR-20-013 | 059, 060, 063, 065 |
| BR-20-014 | 060, 061 |
| BR-20-015 | 063, 064 |
| BR-20-016 | 066, 068 |
| BR-20-017 | 074, 075, 076, 082 |
| BR-20-018 | 081 |
| BR-20-019 | 095, 096, 097, 100, 101 |
| BR-20-020 | 100, 102, 133 |
| BR-20-021 | 087, 090, 092, 193 |
| BR-20-022 | 108, 109 |
| BR-20-023 | 111, 113, 118, 121, 122, 232 |
| BR-20-024 | 110, 119, 122, 126, 128, 129, 232 |
| BR-20-025 | 108, 109, 126, 128, 132, 133, 135, 232 |
| BR-20-026 | 050, 087, 128, 232 |
| BR-20-027 | 136, 137, 139 |
| BR-20-028 | 088, 136, 138, 144, 146, 150 |
| BR-20-029 | 150 |
| BR-20-030 | 152, 153 |
| BR-20-031 | 154, 155, 156, 233 |
| BR-20-032 | 159, 161, 167, 168, 169, 170, 233 |
| BR-20-033 | 051, 052, 159, 161, 163, 166, 167, 233 |
| BR-20-034 | 152, 157 |
| BR-20-035 | 039, 040 |
| BR-20-036 | 078, 085, 087, 088 |
| BR-20-037 | 184 |
| BR-20-038 | 179 |
| BR-20-039 | 106 |
| BR-20-040 | 057, 058 |
| BR-20-041 | 036 |
| BR-20-042 | 019, 020, 021, 022, 023 |

: Quy tắc nghiệp vụ tới test case

### 8.9. Yêu cầu phi chức năng → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-20 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-20-001 | 216 |
| NFR-20-002 | 036, 231 |
| NFR-20-003 | 085, 209, 217 |
| NFR-20-004 | 078, 087, 090, 193, 218 |
| NFR-20-005 | 011, 216 |
| NFR-20-006 | 070, 175, 219 |
| NFR-20-007 | 026, 206, 219 |
| NFR-20-008 | 066, 067, 220, 225 |
| NFR-20-009 | 068, 220 |
| NFR-20-010 | 047, 220 |
| NFR-20-011 | 041, 043, 220 |
| NFR-20-012 | 221 |
| NFR-20-013 | 088, 221 |
| NFR-20-014 | 118, 121, 222, 232 |
| NFR-20-015 | 128, 130, 222, 232 |
| NFR-20-016 | 168, 222, 233 |
| NFR-20-017 | 012, 217, 224 |
| NFR-20-018 | 201 |
| NFR-20-019 | 177, 186, 192 |
| NFR-20-020 | 009, 106, 202, 226 |
| NFR-20-021 | 200, 202 |
| NFR-20-022 | 227, 229 |
| NFR-20-023 | 223 |
| NFR-20-024 | 044, 189, 201, 205 |

: Yêu cầu phi chức năng tới test case

### 8.10. Quyền PERM-20 → test case

Cột "Test case" liệt kê ca có nhắc quyền trong truy vết, dữ liệu hoặc kết quả; ca phân quyền âm nằm ở TS-20-38.

| Quyền | Test case |
|---|---|
| `PERM-20-admin` | 013, 016, 019, 041, 045, 047, 075, 081, 083, 177 (+2) |
| `PERM-20-approve` | 057, 061, 095, 115, 194, 195, 228 |
| `PERM-20-lifecycle` | 015, 057, 090, 093, 095, 097, 100, 194, 228 |
| `PERM-20-merge` | 108, 111, 113, 115, 118, 122, 123, 124, 126, 128 (+4) |
| `PERM-20-org` | 136, 139, 143, 144, 150, 194, 228 |
| `PERM-20-org-read` | 051, 136, 142, 194, 196 |
| `PERM-20-provision` | 005, 010, 022, 027, 030, 032, 034, 037, 039, 194 |
| `PERM-20-quota` | 059, 061, 063, 068, 069, 194 |
| `PERM-20-read` | 001, 003, 026, 036, 066, 070, 072, 074, 099, 104 (+4) |
| `PERM-20-release` | 152, 154, 158, 159, 161, 164, 167, 169, 170, 194 (+1) |
| `PERM-20-settings` | 049, 051, 053, 055, 166, 194, 196, 228 |
| `PERM-20-usage-read` | 070, 194 |

: Quyền PERM-20 tới test case

### 8.11. Tham số 20.* → test case

Cột "Test case" liệt kê ca có dùng hoặc đổi tham số.

| Tham số | Test case |
|---|---|
| `20.cross-tenant.max-hours` | 053 |
| `20.dedicated-cluster.enabled` | 039, 040 |
| `20.drift.check-interval` | 047 |
| `20.export.retention-days` | 057 |
| `20.leak-test.schedule` | 180 |
| `20.lifecycle.reason-min-length` | 091 |
| `20.merge.transition-max-months` | 132 |
| `20.merge.transition-months` | 108 |
| `20.org.import-max-rows` | 139, 140 |
| `20.provision.step-retry-max` | 206 |
| `20.provision.step-timeout-minutes` | 077, 206 |
| `20.provision.timeout-minutes` | 215 |
| `20.quota.alert-reset-percent` | 068 |
| `20.quota.override-max-days` | 063 |
| `20.quota.warn-percent` | 068 |
| `20.registry.cache-seconds` | 085 |
| `20.release.stable-soak-days` | 183 |
| `20.release.supported-minors` | 157 |
| `20.release.verify-minutes` | 167 |
| `20.release.wave-error-threshold-percent` | 168, 184 |
| `20.release.wave-soak-hours-minor` | 161 |
| `20.release.wave-soak-hours-patch` | 159 |
| `20.smoke.enabled` | 033, 184, 213 |
| `20.suspend.essential-api-allowed` | 087 |
| `20.terminate.cooling-days` | 101 |
| `20.upgrade.emergency-notice-hours` | 163 |
| `20.usage.probe-interval` | 068 |
| `20.usage.retention-months` | 066 |
| `20.usage.snapshot-interval` | 066 |

: Tham số 20.* tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Ca UT, IT, API nằm trong `dh-platform/src/test/java/vn/datahub/platform/tenant/` theo gói con `provisioning`, `lifecycle`, `quota`, `merge`, `org`, `release`, `isolation`; ca E2E trong `dh-console/e2e/tenant/`; ca k6 trong `dh-platform/perf/tenant/`; ca DB chạy tệp `ph20_isolation_test.sql` của D03-03-PH20 trên PostgreSQL thật. Mỗi ca gắn thẻ `@TC-20-nnn`.

### 9.2. Mẫu ca hạn mức hiệu lực và tên bước saga

Mẫu kiểm hạn mức hiệu lực và khóa lũy đẳng của bước saga.

```java
@Test void hanMucHieuLucVaKhoaBuoc() {
    var eff = Quota.effective(contract(500), override(800, validUntil(NOW.plusDays(3))), ceiling(1000));
    assertThat(eff).isEqualTo(800);                                   // max(hợp đồng, ghi đè còn hạn) <= trần
    assertThat(Quota.effective(contract(500), override(800, validUntil(NOW.minusDays(1))), ceiling(1000))).isEqualTo(500);
    assertThat(Saga.idempotencyKey("run-01", "S06_EVENTING")).isEqualTo("run-01:S06_EVENTING");
}
```

### 9.3. Mẫu ca quét bí mật

Ca `audit-completeness` đặt chuỗi mẫu `<bi-mat-mau>` vào các trường bí mật của bản giả OpenBao, chạy mọi ca ghi, rồi `grep` ở nhật ký, vết OTel, kiểm toán, CSDL `ph20_tenant`, kho Git giả, topic; kỳ vọng 0 kết quả ngoài bản giả OpenBao.

### 9.4. Sinh ma trận, Gherkin, bảng tính

Chuỗi lệnh dưới chạy từ `05-kiem-thu/test-case/`.

| Lệnh | Kết quả |
|---|---|
| `python3 ph20/tools/number_tcs.py` | Cấp số `TC-20-nnn`, thay `[[tc:khóa]]` |
| `python3 ph20/tools/fill_doc.py` | Ghi bảng 3.1, 3.2, số kịch bản, số ca và mục 8; in ra stderr FR, BR, ERR, NFR chưa có ca |
| `python3 ph20/tools/gen_gherkin.py` | `ph20/gherkin/ts-20-nn.feature`, `uat-quan-tri-tenant.feature` |
| `python3 ph20/tools/gen_xlsx.py` | `ph20/D05-02-PH20-test-case.xlsx` theo mẫu nghiệm thu |
| `python3 ph20/tools/check_refs.py` | Đối chiếu mã trong tập với FRS và use case |
| `node build/tools/kiem_tra_gherkin.mjs` | Kiểm cú pháp Gherkin (CI) |

: Chuỗi công cụ sinh phần tự động

Bản `.docx` của tài liệu dựng từ `.md` bằng bộ xuất chung của dự án; `.xlsx` và Gherkin là bản để chạy và giao cho người thực hiện sau này.

### 9.5. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối chín tiêu chí ở FRS mục 14 với ca chứng minh.

| Tiêu chí FRS mục 14 | Ca |
|---|---|
| 1. Khai báo tenant, saga 17 bước tới `ACTIVE` ≤ 60 phút, kiểm tra khói đạt, EVT-20-03 | TC-20-022, TC-20-032, TC-20-231, TC-20-216 |
| 2. Bước lỗi thử lại, bù trừ ngược, không còn tài nguyên mồ côi | TC-20-027, TC-20-030, TC-20-203, TC-20-205 |
| 3. Tạm ngừng: mọi API trả `ERR-20-001` ≤ 60 giây; khôi phục bình thường | TC-20-090, TC-20-218, TC-20-093 |
| 4. Chấm dứt bị chặn khi chưa bàn giao, chưa hết nguội, cùng người duyệt | TC-20-096, TC-20-101, TC-20-195 |
| 5. Sáp nhập thử: chạy thử, chuyển, xung đột, cutover, `Deprecation`, kiểm đếm 100 % | TC-20-232, TC-20-118, TC-20-128 |
| 6. Nhập 5.000 tổ chức xem trước ≤ 30 giây; giải thể có tham chiếu buộc chọn kế thừa | TC-20-139, TC-20-221, TC-20-145 |
| 7. Nâng cấp theo sóng tự dừng khi lỗi vượt 2 %; quay lui khi không có `CONTRACT` | TC-20-168, TC-20-170, TC-20-171, TC-20-233 |
| 8. Kiểm thử rò rỉ hằng đêm phủ 100 % API, không rò rỉ | TC-20-177, TC-20-192 |
| 9. Mọi thao tác thay đổi có kiểm toán kèm lý do, phiếu; mọi sửa thiếu `If-Match` bị từ chối | TC-20-201, TC-20-199 |

: Đối chiếu tiêu chí chấp nhận cấp phân hệ với ca kiểm thử

## 10. Đề nghị đồng bộ và câu hỏi mở

### 10.1. Đề nghị đồng bộ

Các đề nghị phát sinh khi viết ca; tập này chưa sửa tài liệu nào khác. Các ca liên quan chấp nhận kết quả hiện hành của hợp đồng và ghi chú đề nghị.

| Mã | Tài liệu | Đề nghị |
|---|---|---|
| ĐN-TC-01 | D02-03-PH20 FR-20-018 và FR-20-061, 064 | Đã đồng bộ ở 0.2: cửa sổ bảo trì dài 2…6 giờ, ngoài giờ cao điểm, ở mọi tập; ca window-neg dùng 7 giờ và 1 giờ, window-set-ok dùng 4 giờ |
| ĐN-TC-02 | D02-03-PH20 FR-20-007, FR-20-014, OpenAPI | Đã đồng bộ ở 0.2: tên ca kiểm tra khói theo OpenAPI (`LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK`) và mã chỉ tiêu KPI-12 `thoi-gian-khoi-tao-tenant` của PH-16 ở mọi tập |
| ĐN-TC-03 | D03-04-PH20 (OpenAPI) | Nêu mã lỗi khi thiếu `Idempotency-Key` ở `POST` ghi: ca idem-replay giả định `400` `ERR-20-004` |
| ĐN-TC-04 | D03-04-PH20 API-20-065, D02-03-PH20 FR-20-034 | OpenAPI liệt kê `ERR-20-055` ở API-20-065 nhưng FRS chỉ dùng mã này cho phát hành (FR-20-061); thống nhất một nơi |
| ĐN-TC-05 | D03-04-PH20, D05-01 | Đã đồng bộ ở 0.2: token không thuộc tenant `PLATFORM` gọi `/api/platform/v1` trả `403` `ERR-00-403`; tài nguyên của tenant khác ở `/api/tenant/v1` và `/internal/tenant/v1` trả `404` `ERR-20-002`; bộ thử rò rỉ của D05-01 cần ghi theo quyết định này |
| ĐN-TC-06 | D03-04-PH20 FR-20-069 | `ERR-20-060` (tham số ngoài miền) không có operation OpenAPI trả về vì tham số đổi qua PH-18; ghi rõ nơi trả và hợp đồng đẩy thay đổi |
| ĐN-TC-07 | D05-01, D00-04 | PERF cần 34 tenant `T01…T34` (`testTenant = true`) ngoài dải `T90…T99` để đo NFR-20-005; bổ sung quy ước dải tenant hiệu năng |
| ĐN-TC-08 | D02-03-PH20 FR-20-061 | Nêu mã lỗi khi lên lịch nâng cấp khẩn với thời gian báo trước ít hơn `20.upgrade.emergency-notice-hours`; ca plan-emergency chấp nhận `400` hoặc `422` |
| ĐN-TC-09 | D02-04-PH20 (A-01, A-05), Q20-46, Q20-49 | Bổ sung hộp duyệt đề nghị đổi hạn mức ở màn và thống nhất ngoại lệ A-01, A-05 của use case |
| ĐN-TC-10 | D02-03-PH20 mục 3.2 | Đã đồng bộ ở 0.2: mã bước saga chỉ còn `S03_REALM` |
| ĐN-TC-11 | D05-01 | Thêm vào cổng `RG-1` nhóm ca rò rỉ chéo tenant theo nhóm API và vào cổng `RG-3` nhóm saga từng bước, sáp nhập đầu cuối |

: Đề nghị đồng bộ phát sinh từ tập kiểm thử PH-20

### 10.2. Câu hỏi mở

> **Câu hỏi mở Q20-40:** Bộ 34 tenant hiệu năng `T01…T34` dựng bằng bộ sinh giả hay sao chép từ tỉnh thí điểm đã ẩn danh; hiện dùng bộ sinh giả theo hạt cố định (liên quan ĐN-TC-07).

> **Câu hỏi mở Q20-41:** Hợp đồng của PH-18 về `POST /api/ops/v1/merge-transfers` (có `dryRun`) và về báo tiến độ API-20-167 chưa có đặc tả; các ca TS-20-25, 26, 27 dùng bản giả theo giả định (liên quan Q20-15).

> **Câu hỏi mở Q20-42:** Gitea và Argo CD thật có sẵn ở STAGING không, hay dùng bản giả `git-sim`, `argo-sim`; ca đo NFR-20-011 (áp cấu hình ≤ 5 phút) chỉ có ý nghĩa với Argo CD thật.

> **Câu hỏi mở Q20-43:** NFR-20-023 (gói bàn giao 500 GB ≤ 24 giờ) cần dung lượng Ceph và băng thông của hạ tầng thật; hiện chỉ kiểm logic ở STAGING với gói giả, số đo thật để PERF của hạ tầng tỉnh.

> **Câu hỏi đã đóng Q20-44:** Ca rò rỉ chéo tenant ở nhóm API nền tảng mong `403` `ERR-00-403` (đường dẫn nền tảng không phải tài nguyên của một tỉnh), còn tài nguyên của tenant khác ở `/api/tenant/v1` và `/internal/tenant/v1` mong `404` (ĐN-TC-05, TC-20-187). API chỉ nền tảng không nằm trong phép thử dữ liệu đánh dấu của NFR-20-019 (ghi `SKIPPED` kèm lý do theo FR-20-070) nhưng có ca riêng TC-20-187.

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-27 | Bản đầu: kịch bản TS-20-01…44, test case TC-20, ma trận truy vết, Gherkin, bảng tính |
| 0.2 | 2026-11-27 | Đồng bộ với FRS 0.2: cửa sổ bảo trì 2…6 giờ, quyết định 403 và 404 đóng Q20-44, tên trường theo OpenAPI, thông báo lỗi nguyên văn FRS 9.2, 29 tham số; sinh lại số ca, ma trận, Gherkin, bảng tính |

: Lịch sử phiên bản
