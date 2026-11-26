---
ma_tai_lieu: D05-02-PH15
ten: Kịch bản và test case phân hệ PH-15 Cổng nhà phát triển
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-15
mo_ta: Kịch bản và ca kiểm thử của Cổng nhà phát triển, gồm cô lập tenant, bí mật hiện một lần, forward-auth đóng khi lỗi, cấm dữ liệu cá nhân thật ở sandbox, chặn thử production khi PH-13 lỗi, truy cập 360 px, hiệu năng, UAT tương đương portal Gravitee cũ và ma trận truy vết.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH15 FRS; D02-04-PH15 Use case; D03-02-PH15 SDD; D03-03-PH15 CSDL; D03-04-PH15 API; D03-06-PH15 Màn hình
---

# D05-02-PH15 · Kịch bản và test case Cổng nhà phát triển

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-15 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH15: danh mục theo mức hiển thị, tài liệu API, hướng dẫn có duyệt bốn mắt, tài khoản và ứng dụng sandbox, thử API sandbox và production, ủy thác đăng ký sử dụng, quản trị cổng.
- Không mất chức năng của portal Gravitee cũ: publish, unpublish, make public, xem đường dẫn sử dụng, xem tài liệu, nhật ký của ứng dụng (LGC-APIM-006, 007, 017, 022) và credential tự phục vụ (LGC-IAM-006).
- Không có đường nào để bí mật sandbox lộ ra sau lần cấp, để dữ liệu cá nhân thật vào sandbox, để thử production khi không kiểm toán được, hay để tenant này thấy dữ liệu tenant khác.

**Phạm vi.** Gồm <!--gen:so-ts-->37<!--/gen--> kịch bản (TS-15-01…37) với <!--gen:so-tc-->208 (TC-15-001…208; 120 ca P1)<!--/gen--> test case và 10 kịch bản nghiệm thu người dùng (UAT-01…10). Mỗi FR mức M có ít nhất một ca dương và một ca âm; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph15/tools/gen_matrix.py`, kèm độ phủ UC, UI, BR, ERR, NFR, EVT, API.

**Căn cứ.** Tài liệu cùng bộ PH-15 (FRS D02-03-PH15, use case D02-04-PH15, SDD D03-02-PH15, CSDL D03-03-PH15, API D03-04-PH15, màn hình D03-06-PH15); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cấu trúc theo ISO/IEC/IEEE 29119-3; ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP và TCVN 14423:2026; khả năng truy cập WCAG 2.2 AA.

**Điểm cần hội đồng lưu ý.** Bảy nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- bí mật sandbox hiện một lần và dò mồi `DH-CANARY` không thấy ở đâu khác (TS-15-14, 32);
- cô lập tenant ở API, CSDL, tìm kiếm, bộ đệm, sandbox, Kafka (TS-15-31);
- `forward-auth` đóng khi lỗi, cổng nội bộ không giả mạo được (TS-15-33, 15);
- sandbox chặn dữ liệu cá nhân thật, dữ liệu mẫu nằm trong dải giả (TS-15-19);
- thử production mặc định tắt, bốn mắt, chỉ GET và HEAD, và bị chặn khi PH-13 không ghi được kiểm toán (TS-15-21, 22);
- API ngoài tầm trả như không tồn tại ở mọi đường, kể cả tìm kiếm và gợi ý (TS-15-02, 04);
- đường tới trang PUBLISHED chỉ qua duyệt của người khác, Markdown không thực thi script (TS-15-07, 08, 33).

Mã PH-15 hiện chưa có mã nguồn ngoài đặc tả; các ca ở đây là tiêu chí nghiệm thu của công việc mới. Một số hành vi FRS chưa nêu mã trả về; ca ghi "giả định" kèm câu hỏi mở Q15-40…44 ở cuối tài liệu. Số liệu quy mô dùng giả định GĐ-15-01 (tenant vừa: 500 API, 3.000 phiên bản, 2.000 tài khoản `dh-dev`).

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả kịch bản và test case của PH-15 để kiểm thử viên chạy được ngay trên môi trường SIT với bộ dữ liệu mục 2, không cần hỏi lại, và để chủ đầu tư nghiệm thu tương đương portal cũ ở mục 7.

### 0.2. Người đọc

Kiểm thử viên (viết, chạy ca), kỹ sư (viết ca tự động), cán bộ ATTT (TS-15-31…34) và chủ đầu tư (UAT mục 7).

### 0.3. Thuật ngữ

Dùng chung với [D02-03-PH15](../../02-yeu-cau/frs/D02-03-PH15-frs-cong-nha-phat-trien.md) §1.4 và D00-01. Thêm: ca dương, âm, biên (loại ca); "404-ẩn" (mục 1.5); đồng hồ giả lập; mồi `DH-CANARY` (giá trị đánh dấu để dò bí mật).

### 0.4. Tài liệu tham chiếu

D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH15 (FR, BR, ERR, NFR); D02-04-PH15 (UC); D03-02-PH15 (SDD, mục 12 chiến lược kiểm thử); D03-03-PH15 và bài kiểm `ph15_isolation_test.sql`; D03-04-PH15 (API, `openapi-portal.yaml`, `asyncapi-portal.yaml`); D03-06-PH15 (màn hình); bảng tính [D05-02-PH15-test-case.xlsx](ph15/D05-02-PH15-test-case.xlsx) sinh từ tài liệu này.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược và môi trường; chương 2 dữ liệu; chương 3 danh sách kịch bản; chương 4 ca chức năng (TS-15-01…30); chương 5 ca phi chức năng và xuyên suốt (TS-15-31…37); chương 6 thủ tục thủ công; chương 7 UAT; chương 8 ma trận truy vết; chương 9 tự động hóa. Mỗi ca là một khối gồm Loại, Ưu tiên, Tự động, Truy vết, Tiền điều kiện và dữ liệu, Các bước, Kết quả mong đợi.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Bảng liệt kê thành phần của PH-15 chịu kiểm thử và nơi chúng chạy.

| Đối tượng | Thành phần | Ghi chú |
|---|---|---|
| Giao diện | `dh-portal` (React 19, antd v6, `@datahub/ui`), BFF Spring Cloud Gateway ở Z2 | UI-15-01…28, `/bff/dang-nhap`, `/bff/dang-xuat` |
| Máy chủ | Module `portal` trong DU `dh-connect` (`vn.datahub.connect.portal`), cổng 8080 và cổng nội bộ 8081 | API `/api/portal/v1`, `/public`, `/try`, `/admin`, `/internal/v1` |
| Sandbox | APISIX tuyến sandbox, `forward-auth`, mock `MOCK` và `BACKEND` | `sandbox-api.t68.datahub.gov.vn` (giả định) |
| Dữ liệu | Schema `ph15_portal` trên `pg-core`, RLS theo `tenant_id`; Valkey, OpenSearch, Garage | `ph15_isolation_test.sql` |
| Tích hợp | PH-02 (`catalog:portal-read`, API-02-081), PH-01, PH-12 (Keycloak `dh-dev`), PH-13, PH-10, Kafka, Apicurio | WireMock cho PH-01, PH-02, PH-13 ở SIT |
| Sự kiện | EVT-15-01…14; tiêu thụ EVT-02-01, 02, 03, 05, 06, 08, 10, 11, 12 | Outbox, inbox |

: Đối tượng kiểm thử

### 1.2. Mức kiểm thử

Mỗi ca ở chương 4 và 5 gắn một hoặc nhiều mức sau.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, jqwik, Vitest | `VisibilityPolicy`, `MarkdownValidator`, `PiiScanner`, `SampleGenerator`, `SchemaDataGenerator` |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Valkey, OpenSearch, Keycloak, OpenBao, Kafka, ClamAV) | Control plane, outbox, inbox, saga Keycloak |
| CSDL | DB | `psql` với `ph15_isolation_test.sql` | RLS, bất biến, bốn mắt |
| Hợp đồng | CT | Spectral, oasdiff, Pact, Apicurio | OpenAPI, AsyncAPI, PH-02 |
| API | API | REST Assured | Mọi API-15 |
| Đầu cuối | E2E | Playwright (Chrome, Edge, Firefox, WebKit) | UI-15-01…28 |
| Hiệu năng | k6 | k6 | NFR-15-001…008, 012, 013, 018 |
| Chịu lỗi | Chaos | Chaos Mesh | PH-02, PH-13, Keycloak, Kafka, Valkey, APISIX |
| Bảo mật | ZAP | OWASP ZAP, Trivy, Semgrep | ASVS 5.0 mức 2, CSP, XSS, SSRF |
| Truy cập | A11Y | axe-core, NVDA, VoiceOver | WCAG 2.2 AA |

: Mức kiểm thử

### 1.3. Môi trường kiểm thử

Ba môi trường dùng cho ba mục đích khác nhau.

| Môi trường | Mô tả | Dùng cho |
|---|---|---|
| SIT | K8s một cụm; tenant T68, T01, T90; Keycloak, OpenSearch, Valkey, Kafka, Apicurio, APISIX sandbox thật; PH-01, PH-02, PH-13, kho Git giả lập (mục 2.5); Mailpit | API, E2E, IT, Chaos, ZAP |
| PERF | Cấu hình QM-VUA theo D03-09; dữ liệu GĐ-15-01 | k6 |
| UAT | Như SIT, nạp bản xuất portal Gravitee đã làm sạch (F-ZIP-GRAVITEE) | UAT mục 7 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào và ra

Cổng vào và ra của đợt kiểm thử.

| Loại | Tiêu chí |
|---|---|
| Vào | D02-03-PH15 ở trạng thái duyệt; DDL `ph15_portal` áp được; `openapi-portal.yaml` qua CT; bộ dữ liệu mục 2 nạp xong |
| Ra | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt, ca còn lại có lỗi mở mức Thấp; 0 lỗi mở mức Nghiêm trọng, Cao; ma trận mục 8 không có FR mức M thiếu ca dương hoặc ca âm; TS-15-31…34 đạt 100 % |

: Tiêu chí vào và ra

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-15-nn`, test case `TC-15-nnn`; mã không tái sử dụng (ca hủy ghi "Đã hủy" và giữ mã). Loại gồm Dương, Âm, Biên, Bảo mật (luôn kèm Âm), Hiệu năng, Truy cập. Ưu tiên: P1 chặn phát hành, P2 quan trọng, P3 bổ sung. Tự động: UT, IT, DB, CT, API, E2E, k6, Chaos, ZAP hoặc Thủ công. Đường dẫn API tương đối với `/api/portal/v1`. LGC ghi theo FRS; chức năng mới ghi "LGC mới".

| Ký hiệu | Nghĩa |
|---|---|
| `404` ERR-15-001 "404-ẩn" | Thân giống hệt nhau giữa "không tồn tại" và "ngoài tầm nhìn hoặc tenant khác", chỉ khác `traceId`, `instance` (BR-15-002, 034) |
| `403` ERR-15-005 | Thiếu quyền `PERM-15-*` hoặc không phải thành viên |
| KT: có (hành động) | Có bản ghi kiểm toán ở PH-13 với `PORTAL_{hành động}` ở phụ lục A.8 của FRS, đủ trường FR-00-041, không chứa bí mật hay thân yêu cầu |
| EVT-15-nn | Đúng một bản tin trên `t68.portal.{thực-thể}.{sự-kiện}.v1`, CloudEvents, có `dhtenant` |
| Mồi sạch | Tìm `DH-CANARY-{ca}` trong phản hồi (ngoài lần cấp), log 5 phút, vết OTel, bảng `ph15_portal.*`, outbox, Kafka, Valkey, tệp xuất, nhật ký gateway, PH-13: không thấy |
| Đồng hồ giả lập | Bộ đồng hồ kiểm thử đẩy thời gian cho hạn, nhắc, vô hiệu hóa, lưu giữ; không đợi thật |

: Quy ước mã và cách trình bày

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-15`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: bí mật hiện lần thứ hai hoặc xuất hiện ngoài kho băm; đọc được dữ liệu của tenant khác; dữ liệu cá nhân thật đi qua được sandbox; thử production lọt qua khi PH-13 lỗi, hay ở API nhạy cảm, hay khi chưa duyệt bốn mắt; `forward-auth` cho qua khi lỗi; người tự duyệt nội dung hoặc thử production của chính mình; script trong Markdown thực thi; thông tin xác thực production hiện ở cổng. Báo cáo hằng đêm từ JUnit, Playwright, k6, đối chiếu ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Nạp bằng bộ gieo qua API (không chèn SQL trực tiếp), trừ bản sao danh mục nạp từ S-PH02.

### 2.1. Tenant

Ba tenant kiểm thử; ca liên tenant dùng T68 và T01.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính | `15.public.enabled = false` trừ ca ghi khác; `15.try.prod-enabled = false` trừ TS-15-21, 22 |
| `T01` | Tỉnh đối chứng rò rỉ | Có cùng mã `tra-cuu-ho-tich`, `app-tra-cuu-ho-tich`, `bat-dau-nhanh`, `HT-2026-0001` nhưng nội dung khác, để phát hiện trả nhầm |
| `T90` | Tenant mới, trống | Chưa đồng bộ danh mục; dùng cho ca "chưa sẵn sàng", "tenant rỗng" |

: Tenant kiểm thử

### 2.2. Người dùng

Nhân vật trùng D02-04-PH15 (An, Bình, Chi, Dũng, Hà, Khánh, Lan); thêm Bi, Cự là hai nhà thầu để kiểm cách ly cùng tenant.

| Mã | Tenant | Vai trò, nguồn | Nhân vật | Mục đích |
|---|---|---|---|---|
| U-ANON | T68 | Khách ẩn danh | Lan | Hạng `ANONYMOUS` |
| U-T68-DEV-AN | T68 | `dh-dev` ACTIVE, nhà thầu Công ty ABC; đã chấp nhận điều khoản | An (`nguyen.van.an`) | Nhà phát triển chính; chủ `app-tra-cuu-ho-tich` |
| U-T68-DEV-BI | T68 | `dh-dev` ACTIVE; chưa chấp nhận điều khoản v2 | Bi | Điều khoản, thành viên nhóm, VIEWER |
| U-T68-DEV-CU | T68 | `dh-dev` ACTIVE, ngoài mọi nhóm của An | Cự | Đối chứng IDOR cùng tenant |
| U-T68-OR | T68 | Cán bộ SSO Sở TN&MT, đầu mối OR của `HT-DATDAI` | Bình | Đăng ký sử dụng, kết nạp, thử production |
| U-T68-SV | T68 | Chủ dịch vụ `HT-TUPHAP`, `PERM-15-content-write`, `PERM-15-support` | Chi | Soạn nội dung, khai báo sandbox, xử lý phiếu |
| U-T68-CA | T68 | CA, `PERM-15-content-write`, `PERM-15-content-publish` | Dũng | Duyệt nội dung, duyệt thử production |
| U-T68-TA | T68 | TA, `PERM-15-portal-admin`, `PERM-15-dev-approve` | Hà | Quản trị cổng |
| U-T68-SO | T68 | SO, `PERM-15-dev-approve`, `PERM-15-audit-read` | Khánh | Khóa, nhật ký |
| U-T68-AU | T68 | AU, `PERM-15-audit-read` | Kiểm toán viên | Chỉ đọc nhật ký |
| U-T01-USER, U-T01-DEV, U-T01-TA, U-T01-AU | T01 | Cán bộ, nhà phát triển, TA, AU của T01 | — | `OTHER_TENANT_USER`, đối chứng rò rỉ |
| S-APISIX | — | Danh tính SPIFFE của APISIX | — | `forward-auth` cổng 8081 |

: Người dùng kiểm thử

### 2.3. Danh mục mẫu F-CAT

Danh mục T68 do S-PH02 trả (mười API, một topic):

| Mã API | Mức hiển thị | `dataClass` | Trạng thái | Ghi chú |
|---|---|---|---|---|
| `tra-cuu-ho-tich` | TENANT | INTERNAL | 1.0.0 PUBLISHED, 0.9.0 DEPRECATED (ngừng 31/03/2027) | Cung cấp `HT-TUPHAP`; sandbox MOCK; 12 thao tác |
| `tra-cuu-dat-dai` | TENANT | SENSITIVE | PUBLISHED | Cấm thử production |
| `dm-hanh-chinh` | NATIONAL | INTERNAL | PUBLISHED | Sandbox BACKEND tới `sim-backend.sim.test` |
| `thoi-tiet-cong-khai` | PUBLIC | PUBLIC | PUBLISHED | Có thể bật thử production |
| `thoi-tiet-noi-bo` | PUBLIC | INTERNAL | PUBLISHED | Chứng minh cần cả hai điều kiện cho ẩn danh |
| `bao-cao-noi-bo` | TENANT | RESTRICTED | PUBLISHED | Cấm thử production; kiểm toán lỗi thì chặn |
| `dich-vu-cu` | PUBLIC | PUBLIC | DEPRECATED | |
| `tra-cuu-tam-ngung` | TENANT | INTERNAL | SUSPENDED | |
| `ban-do-cu` | PUBLIC | PUBLIC | RETIRED (v1) | Chỉ hiện khi lọc `da-ngung` |
| `an-khoi-cong` | TENANT | INTERNAL | PUBLISHED, `portalPublished = false` | Không hiện cho ai |
| `ho-tich.moi-dang-ky` (topic) | TENANT | INTERNAL | AsyncAPI 3.0 | Dịch vụ sự kiện |

: Danh mục mẫu F-CAT

Số mục thấy được (không tính topic): cán bộ T68 8; nhà phát triển `dh-dev` 7; cán bộ T01 qua NATIONAL 4; ẩn danh (công khai bật) 2. Bản mở rộng F-CAT-60 (60 API) dùng cho ca lọc, F-CAT-500 (500 API, 3.000 phiên bản) cho PERF.

### 2.4. Tệp và bộ dữ liệu mẫu

Tệp mẫu dùng cho ca về đặc tả, nội dung, nhập Git, di trú và dữ liệu cá nhân.

| Mã | Nội dung |
|---|---|
| F-SPEC-300 | OpenAPI 3.1 300 thao tác, nhiều tag, ví dụ và lược đồ |
| F-SPEC-BAD | Đặc tả không phân tích được (YAML hỏng) |
| F-MD-XSS | 120 vector XSS cho Markdown theo OWASP, gồm `<script>`, `<iframe>`, `<img onerror>`, `javascript:`, ảnh ngoài kho, `<svg onload>` |
| F-IMG-OK, F-IMG-SVG, F-IMG-EICAR | PNG 1 MB; SVG; PNG đội vỏ chuỗi EICAR |
| F-GIT-OK | Kho có `portal.yaml`, 12 tệp `.md`, 4 ảnh |
| F-ZIP-GRAVITEE | Gói xuất portal Gravitee đã làm sạch: 8 trang, 5 ảnh, 3 tài liệu, có thẻ `<script>` |
| F-PII | Sáu giá trị theo PII-15-01…06 (CCCD `079123456789`, CMND `123456789`, mã số thuế `0312345678`, điện thoại `0912345678`, thư `a@gmail.com`, hộ chiếu `B1234567`) |
| F-FAKE | Dải giả: `000123456789`, `000123456`, `0000123456`, `0900000123`, `x@example.gov.vn`, `X00123456` |

: Tệp và bộ dữ liệu mẫu

### 2.5. Hệ thống giả lập

Phụ thuộc ngoài được giả lập để ca chạy lặp lại được và có công tắc gây lỗi.

| Mã | Mô tả |
|---|---|
| S-PH02 | WireMock giả lập API-02-081 (`updatedSince`, `removed[]`, ETag), đường dẫn sử dụng, đăng ký sử dụng, phát EVT-02-* |
| S-PH01 | WireMock giả lập tham chiếu xác thực production và kết nạp F-01 |
| S-PH13 | Bộ thu kiểm toán, chỉ số; có công tắc ngắt |
| S-GIT | Kho Git thử, webhook |
| Mailpit | Hộp thư giả lập nhận thư xác minh, nhắc hạn |
| `sim-backend.sim.test` | WireMock làm backend thử (BACKEND), có công tắc chậm, lỗi 500, trả 2 MB |
| APISIX production giả lập | Đếm lời gọi để chứng minh thử production bị chặn |

: Hệ thống giả lập

### 2.6. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật ở bất kỳ môi trường kiểm thử nào; giá trị F-PII chỉ dùng để chứng minh bị chặn. Mỗi ca tự nạp và dọn dữ liệu của mình (mã có hậu tố `tc-`). Ca dùng giá trị mồi đặt tên `DH-CANARY-{khóa ca}`. Tham số tenant được đặt lại về mặc định sau mỗi ca đổi tham số.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-15-01 | Đồng bộ danh mục từ PH-02 | Xác nhận bản sao danh mục ở cổng khớp PH-02 trong vài chục giây, thay việc cập nhật tay ở portal hệ cũ, và vẫn phục vụ khi PH-02 hỏng | UC-15-04 | 6 |
| TS-15-02 | Mức hiển thị theo người xem và truy cập ẩn danh | Xác nhận mỗi người chỉ thấy đúng API mà mức hiển thị và dataClass cho phép, API ngoài tầm trả như không tồn tại, và khách ẩn danh chỉ thấy phần công khai khi tenant bật | UC-15-01 | 9 |
| TS-15-03 | Trang chủ, duyệt, lọc, dịch vụ sự kiện | Xác nhận trang chủ, duyệt và lọc danh mục, dịch vụ sự kiện hoạt động đúng và kiểm tra bộ lọc sai | UC-15-01 | 6 |
| TS-15-04 | Tìm kiếm toàn văn tiếng Việt và gợi ý | Xác nhận tìm kiếm không phân biệt dấu, gợi ý, tôn trọng mức hiển thị, dự phòng PostgreSQL và chống lạm dụng | UC-15-02 | 5 |
| TS-15-05 | Chi tiết dịch vụ, đường dẫn sử dụng, lộ trình ngừng | Xác nhận trang chi tiết thay "Xem chi tiết đường dẫn sử dụng" của hệ cũ, hiện đúng banner ngừng, tạm ngừng và ngừng hẳn | UC-15-03 | 5 |
| TS-15-06 | Tài liệu API, phiên bản, so sánh, mẫu mã | Xác nhận tài liệu OpenAPI 3.1 và AsyncAPI 3.0 hiển thị đúng, tải và so sánh được, mẫu mã sáu ngôn ngữ chạy được và không có bí mật | UC-15-05 | 9 |
| TS-15-07 | Soạn trang nội dung Markdown | Xác nhận chỉ nhân sự có quyền soạn, mã trang bất biến, Markdown bị lọc nguy hiểm, giới hạn cỡ và ảnh đính kèm | UC-15-06 | 8 |
| TS-15-08 | Duyệt bốn mắt, đăng và vòng đời trang | Xác nhận chỉ có một đường tới PUBLISHED là duyệt của người khác, phiên bản giữ lại, gỡ và hiển thị đúng đối tượng | UC-15-07, 09 | 8 |
| TS-15-09 | Nhập Git và di trú nội dung portal cũ | Xác nhận nội dung nhập từ Git và từ portal Gravitee đều thành bản nháp phải duyệt, qua bộ lọc, và gói sai bị từ chối | UC-15-08 | 4 |
| TS-15-10 | Đăng nhập, phiên và hồ sơ | Xác nhận đăng nhập SSO và dh-dev qua BFF, trạng thái tài khoản chặn đăng nhập, và hồ sơ, phiên của chính mình | UC-15-10, 12 | 5 |
| TS-15-11 | Tự đăng ký dh-dev và duyệt tài khoản | Xác nhận hai cổng chặn (xác minh thư, duyệt quản trị) trước khi nhà thầu có quyền, và quản trị đúng quyền | UC-15-11, 30 | 7 |
| TS-15-12 | Điều khoản, nhóm, vô hiệu hóa và xóa tài khoản | Xác nhận chấp nhận điều khoản có phiên bản, nhóm phát triển đúng chủ sở hữu, vô hiệu hóa 45 ngày và xóa theo yêu cầu | UC-15-12, 13 | 6 |
| TS-15-13 | Ứng dụng sandbox và thành viên | Xác nhận tạo, xem, sửa, lưu trữ, khôi phục ứng dụng, giới hạn số lượng, vai trò thành viên và cô lập giữa người dùng cùng tenant | UC-15-13, 14 | 8 |
| TS-15-14 | Cấp thông tin xác thực và bí mật hiện một lần | Xác nhận cấp client_credentials và API key sandbox thay credential tự phục vụ của hệ cũ, bí mật hiện đúng một lần và không có đường nào đọc lại | UC-15-15 | 6 |
| TS-15-15 | Xoay vòng, thu hồi, hết hạn thông tin xác thực | Xác nhận xoay có thời gian chuyển tiếp, thu hồi và hết hạn có hiệu lực ở forward-auth trong 60 giây, và mọi sai trạng thái bị chặn | UC-15-16 | 6 |
| TS-15-16 | Tham chiếu thông tin xác thực production | Xác nhận chỉ cán bộ thuộc tổ chức của HTTT thấy tham chiếu (không bí mật), nhà thầu và người ngoài bị chặn | UC-15-17 | 3 |
| TS-15-17 | Khai báo sandbox của dịch vụ | Xác nhận chủ dịch vụ khai báo MOCK, BACKEND, và các chặn SSRF, ngoài allowlist | UC-15-18 | 3 |
| TS-15-18 | Thử API ở sandbox MOCK | Xác nhận khung thử gọi qua APISIX sandbox, phản hồi MOCK sinh từ ví dụ, lược đồ, và đủ các chặn trước khi gọi | UC-15-19 | 7 |
| TS-15-19 | Thử BACKEND, chặn dữ liệu cá nhân, hạn mức | Xác nhận chế độ BACKEND an toàn, chặn mọi mẫu DLCN thật, dữ liệu mẫu tổng hợp trong dải giả, và các hạn mức | UC-15-19 | 8 |
| TS-15-20 | Lịch sử thử, bộ sưu tập, xuất | Xác nhận lịch sử không lưu thân hay bí mật, bộ sưu tập là của riêng mỗi người và xuất ra công cụ ngoài không lộ bí mật | UC-15-20 | 4 |
| TS-15-21 | Bật, tắt thử production theo dịch vụ | Xác nhận thử production mặc định tắt, bật theo bốn mắt, có thời hạn và chỉ cho API đủ điều kiện | UC-15-21 | 4 |
| TS-15-22 | Thử API trên production | Xác nhận thử production chỉ cho cán bộ có đăng ký ACTIVE, chỉ GET/HEAD, API không nhạy cảm, và đóng an toàn khi kiểm toán lỗi | UC-15-22 | 8 |
| TS-15-23 | Đăng ký sử dụng, kết nạp, công bố (ủy thác) | Xác nhận cổng chỉ ủy thác nhân danh người dùng, không tự duyệt, không giữ bản sao quyết định, và chỉ đầu mối thao tác | UC-15-23, 24, 25 | 7 |
| TS-15-24 | Bảng điều khiển, thống kê và nhật ký ứng dụng | Xác nhận số liệu và nhật ký chỉ của ứng dụng mình, dữ liệu đã che, thay "xem log request" của hệ cũ | UC-15-26 | 4 |
| TS-15-25 | Theo dõi thay đổi API và hộp thông báo | Xác nhận người theo dõi nhận thông báo thay đổi từ PH-02, loại bắt buộc không tắt được, và hộp thư chỉ của chủ nhận | UC-15-27 | 4 |
| TS-15-26 | Hỏi đáp, báo lỗi tài liệu, yêu cầu hỗ trợ | Xác nhận yêu cầu hỗ trợ tới đúng đầu mối của chủ dịch vụ, phiếu chỉ của người gửi, và chống gửi tràn | UC-15-28 | 4 |
| TS-15-27 | Nhận diện và tham số cổng theo tenant | Xác nhận quản trị đổi tên, logo, liên kết và tham số trong miền cho phép, và không đổi được giao diện nền | UC-15-29 | 4 |
| TS-15-28 | Khóa, mở khóa và khu quản trị | Xác nhận khóa tài khoản, ứng dụng có hiệu lực tức thời, và khu quản trị chỉ vào được từ mạng quản trị có MFA | UC-15-30 | 4 |
| TS-15-29 | Nhật ký kiểm toán và báo cáo sử dụng | Xác nhận kiểm toán đủ hành động, tra cứu đúng quyền, xuất có kiểm toán và cô lập giữa tenant | UC-15-31 | 4 |
| TS-15-30 | Đồng bộ lại và đối soát danh mục | Xác nhận quản trị chạy đồng bộ, đối soát phát hiện sai lệch và sửa được, và chống chạy song song | UC-15-04 | 3 |
| TS-15-31 | Cô lập tenant | Chứng minh không có đường rò rỉ chéo tenant ở API, CSDL, tìm kiếm, bộ đệm, sandbox và sự kiện | — | 5 |
| TS-15-32 | Không lộ bí mật và không token ở trình duyệt | Chứng minh bí mật sandbox chỉ hiện đúng lần cấp và không còn ở bất kỳ nơi nào, và trình duyệt không giữ token | — | 4 |
| TS-15-33 | An toàn khi lỗi, forward-auth, XSS, IDOR | Chứng minh các chốt an toàn: forward-auth đóng khi lỗi, cổng nội bộ không giả mạo được, Markdown không thực thi script, không IDOR giữa người dùng cùng tenant | — | 5 |
| TS-15-34 | Phân quyền và tách nhiệm | Chứng minh mỗi vai trò chỉ làm được điều D02-08 cho phép và bốn mắt độc lập với phân quyền | — | 4 |
| TS-15-35 | Hiệu năng, tải và quy mô | Chứng minh NFR-15-001…008, 012, 013, 018 ở quy mô một tenant vừa theo GĐ-15-01 | — | 10 |
| TS-15-36 | Truy cập, 360 px và trình duyệt | Chứng minh UI-15-01…28 đạt WCAG 2.2 AA, dùng được từ 360 px, bằng bàn phím, và chạy trên bốn trình duyệt | — | 5 |
| TS-15-37 | Chịu lỗi, hợp đồng, quan sát, lưu giữ, bắt đầu nhanh | Chứng minh cổng tiếp tục phục vụ khi phụ thuộc hỏng, sự kiện không mất, hợp đồng ổn định, chỉ số đủ, lưu giữ đúng và nhà phát triển mới gọi được sandbox trong 15 phút | — | 6 |
| **Tổng** | | | | **208** (120 ca P1) |

: Danh sách kịch bản
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Bảng nêu chuyển hợp lệ và chuyển cấm mà các ca chức năng phải kiểm.

| Máy trạng thái | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Ứng dụng sandbox | ACTIVE → SUSPENDED → ACTIVE; ACTIVE → ARCHIVED → ACTIVE (30 ngày); SUSPENDED → ARCHIVED | Khôi phục khi ACTIVE; sửa khi ARCHIVED; cấp credential khi không ACTIVE |
| Thông tin xác thực | ACTIVE → ROTATING → EXPIRED; ACTIVE → REVOKED; ACTIVE → EXPIRED | Xoay hoặc thu hồi khi REVOKED, EXPIRED; khôi phục |
| Phiên bản trang | DRAFT → IN_REVIEW → PUBLISHED → SUPERSEDED; IN_REVIEW → REJECTED → DRAFT; PUBLISHED → UNPUBLISHED | Duyệt khi không IN_REVIEW; tự duyệt; sửa khi IN_REVIEW; gỡ trang không PUBLISHED |
| Tài khoản `dh-dev` | PENDING_EMAIL → PENDING_APPROVAL → ACTIVE → LOCKED → ACTIVE; ACTIVE → DISABLED → PENDING_APPROVAL; ACTIVE → ERASED; PENDING_EMAIL → EXPIRED | Đăng nhập khi chưa duyệt, khóa, vô hiệu; duyệt khi không PENDING_APPROVAL |
| Thử production | OFF → PENDING → ENABLED → EXPIRED; ENABLED → OFF | Tự duyệt; bật cho RESTRICTED, SENSITIVE; thử khi OFF, EXPIRED |
| Đồng bộ | IDLE → RUNNING → IDLE; RUNNING → FAILED; * → STALE | Chạy song song |
| Phiếu hỗ trợ | OPEN → ANSWERED → RESOLVED → CLOSED | Thêm tin khi CLOSED |

: Máy trạng thái được kiểm thử

## 4. Kịch bản và test case chức năng

### TS-15-01 · Đồng bộ danh mục từ PH-02

**Mục tiêu.** Xác nhận bản sao danh mục ở cổng khớp PH-02 trong vài chục giây, thay việc cập nhật tay ở portal hệ cũ, và vẫn phục vụ khi PH-02 hỏng.

**Phủ.** FR-15-001; UC-15-04; API-15-009; EVT-15-14; ERR-15-008, 009; BR-15-001, 033; LGC-APIM-006.

#### TC-15-001 · Nạp đầu từ PH-02 phân trang tới hết <!--k:sync-initial-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-15-001 · UC-15-04 · API-15-009, 131 · UI-15-27 · EVT-15-14 · BR-15-001 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** S-PH02 (WireMock API-02-081) trả F-CAT (10 API, 1 topic, 12 phiên bản) chia 3 trang; tenant T68 chưa có mốc đồng bộ.

**Các bước.**

1. Khởi động mô-đun `portal`.
2. Đọc `GET /catalog/sync-status` (U-T68-TA) mỗi 2 giây đến khi `state = IDLE`.
3. `GET /catalog/apis?co=100` bằng U-T68-TA.

**Kết quả mong đợi.** Lần gọi đầu tới API-02-081 không có `updatedSince`, đọc đủ 3 trang; `itemCount = 11`; `lagSeconds` ≤ 5; đúng một EVT-15-14 `RUNNING` rồi một `IDLE`; đặc tả của 12 phiên bản có `contentHash`; mục `an-khoi-cong` (`portalPublished = false`) được lưu nhưng không hiện cho ai.
:::

#### TC-15-002 · Sự kiện PH-02 cập nhật bản sao trong 30 giây, loại trùng <!--k:sync-event-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-15-001 · UC-15-04 · EVT-15-14 · BR-15-001 · NFR-15-004 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** Bản sao đã nạp; S-PH02 phát EVT-02-02 cho `tra-cuu-ho-tich` (đổi mô tả, `sourceVersion` 10 → 11), gửi hai lần cùng mã sự kiện.

**Các bước.**

1. Ghi nhận thời điểm phát sự kiện.
2. Gọi `GET /catalog/apis/tra-cuu-ho-tich` (U-T68-DEV-AN) mỗi giây.

**Kết quả mong đợi.** Mô tả mới hiện ≤ 30 giây; bản ghi chỉ được ghi đè một lần (inbox loại trùng, ADR-042); bộ đệm trang chi tiết bị vô hiệu; chỉ mục tìm kiếm cập nhật.
:::

#### TC-15-003 · Mục bị gỡ ở PH-02 biến mất ở cổng <!--k:sync-removed-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-15-001 · UC-15-04 · BR-15-001, 002 · ERR-15-001 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** F-CAT; mục `api-thu-nghiem` đã đồng bộ và đang hiển thị; S-PH02 đưa nó vào `removed[]` (EVT-02-06).

**Các bước.**

1. Chạy kéo bù (`POST /admin/sync:run`, U-T68-TA).
2. `GET /catalog/apis/api-thu-nghiem` và `GET /search?q=thử nghiệm` bằng U-T68-DEV-AN.

**Kết quả mong đợi.** Mục bị gỡ đánh dấu ẩn (xóa mềm): `404` ERR-15-001 và vắng mặt ở danh sách, tìm kiếm; mục khác không đổi. Gọi lại PH-02 với `If-None-Match` nhận `304` thì chỉ ghi mốc kiểm tra, không đổi `updated_at` của mục nào.
:::

#### TC-15-004 · PH-02 hỏng: giữ bản sao, cảnh báo, ẩn thử production sau 24 giờ <!--k:sync-stale-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-15-001 · UC-15-04 · UI-15-02 · EVT-15-14 · BR-15-033 · NFR-15-008 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** Bản sao đã nạp; `15.sync.stale-seconds = 300` (tối thiểu); S-PH02 trả `503`; đồng hồ giả lập.

**Các bước.**

1. Cho S-PH02 trả `503`; quan sát nhịp thử lại.
2. Sau 6 phút `GET /catalog/sync-status`; mở UI-15-02 bằng U-T68-DEV-AN.
3. Đẩy đồng hồ thêm 24 giờ; mở UI-15-06 cho `thoi-tiet-cong-khai`.

**Kết quả mong đợi.** Thử lại lùi mũ 5, 30, 120 giây; `state = STALE`, EVT-15-14; UI-15-02 có banner "Danh mục có thể chưa phản ánh thay đổi mới nhất." nhưng danh mục và tài liệu vẫn đọc được; sau 24 giờ nút "Thử trên môi trường thật" bị ẩn; khi PH-02 hồi phục, `state` về `IDLE` không cần can thiệp.
:::

#### TC-15-005 · Tenant chưa nạp xong: 503 và trang chủ vẫn dựng <!--k:sync-not-ready-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-001, 003 · UC-15-04 · API-15-005 · UI-15-01 · ERR-15-008 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** Tenant mới T90 chưa từng đồng bộ; trang `huong-dan` đã đăng.

**Các bước.**

1. `GET /catalog/apis` (người dùng T90).
2. Mở UI-15-01.

**Kết quả mong đợi.** Bước 1 trả `503` ERR-15-008, `detail` "Danh mục đang được chuẩn bị. Vui lòng quay lại sau ít phút"; bước 2 khối danh mục hiện thông báo, các khối nội dung vẫn hiển thị.
:::

#### TC-15-006 · Đặc tả hỏng giữ bản cũ, không kéo theo API khác <!--k:sync-bad-spec-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** IT, API.

**Truy vết.** FR-15-001, 009 · UC-15-04 · API-15-016 · ERR-15-009 · BR-15-001 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** F-SPEC-BAD là đặc tả mới của phiên bản `1.0.0` `tra-cuu-ho-tich`; mục khác bình thường.

**Các bước.**

1. S-PH02 phát EVT-02-03 kèm đặc tả hỏng; chờ đồng bộ.
2. `GET /catalog/apis/tra-cuu-ho-tich/versions/1.0.0/spec`.
3. `GET /catalog/apis/dm-hanh-chinh`.

**Kết quả mong đợi.** Cổng giữ đặc tả đã nạp trước đó, ghi cảnh báo vào nhật ký vận hành (không hiện cho người dùng); khi chưa từng có đặc tả hợp lệ bước 2 trả `422` ERR-15-009; bước 3 bình thường.
:::

### TS-15-02 · Mức hiển thị theo người xem và truy cập ẩn danh

**Mục tiêu.** Xác nhận mỗi người chỉ thấy đúng API mà mức hiển thị và dataClass cho phép, API ngoài tầm trả như không tồn tại, và khách ẩn danh chỉ thấy phần công khai khi tenant bật.

**Phủ.** FR-15-002, 008, 001; UC-15-01; API-15-003, 004, 005, 010; ERR-15-001, 007; BR-15-002…006; LGC-APIM-006, 007.

#### TC-15-007 · Ma trận bốn hạng người xem × F-CAT <!--k:vis-matrix-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** FR-15-002 · UC-15-01 · API-15-003, 005 · UI-15-02 · BR-15-002, 004, 005 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** F-CAT (11 mục, mục 2.3); `15.public.enabled = true`; U-T68-OR, U-T68-DEV-AN, U-T01-USER, U-ANON.

**Các bước.**

1. Mỗi hạng gọi `GET /catalog/apis?co=100` (ANON gọi `/public/catalog/apis`).
2. Lặp ở UI-15-02 và so số mục với API.

**Kết quả mong đợi.** Số mục: cán bộ T68 (TENANT_USER) 8 (`tra-cuu-ho-tich`, `tra-cuu-dat-dai`, `dm-hanh-chinh`, `thoi-tiet-cong-khai`, `thoi-tiet-noi-bo`, `bao-cao-noi-bo`, `dich-vu-cu`, `tra-cuu-tam-ngung`); nhà phát triển `dh-dev` 7 (không có `tra-cuu-dat-dai` SENSITIVE); cán bộ T01 qua NATIONAL 4 (`dm-hanh-chinh`, `thoi-tiet-cong-khai`, `thoi-tiet-noi-bo`, `dich-vu-cu`); ẩn danh 2 (`thoi-tiet-cong-khai`, `dich-vu-cu`: vừa `PUBLIC` vừa dataClass `PUBLIC`). `an-khoi-cong`, `ban-do-cu` không có mặt ở cả bốn. UI khớp API. Ba cách hiển thị (API, UI, tìm kiếm) cho cùng kết quả.
:::

#### TC-15-008 · API ngoài tầm trả như không tồn tại ở mọi đường <!--k:vis-hidden-404-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-002 · UC-15-01 · API-15-004, 007, 008, 011, 012, 015, 016 · ERR-15-001 · BR-15-002 · NFR-15-017 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; `an-khoi-cong` (`portalPublished = false`), `tra-cuu-dat-dai` (SENSITIVE), mã không có `khong-co-that`.

**Các bước.**

1. Với từng mã ở D, gọi chi tiết, `/usage`, `/versions`, `/versions/1.0.0/spec`, `/search?q={mã}`, `/search/suggest?q={mã}`.
2. So thân phản hồi của mã ngoài tầm với mã không có thật.

**Kết quả mong đợi.** Mọi đường `404` ERR-15-001; thân giống hệt nhau trừ `traceId`, `instance`; tìm kiếm và gợi ý không có mục; tổng số kết quả không đếm mục ẩn.
:::

#### TC-15-009 · Khách ẩn danh xem phần công khai, không lộ thông tin nội bộ <!--k:vis-anon-on-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-008 · UC-15-01 · API-15-003, 004, 010 · UI-15-01, 02, 04 · BR-15-005, 006 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** `15.public.enabled = true`; U-ANON.

**Các bước.**

1. `GET /public/catalog/apis`, `GET /public/catalog/apis/thoi-tiet-cong-khai`.
2. Mở UI-15-04 của API đó khi chưa đăng nhập; tìm `q=thời tiết` ở `/public/search`.

**Kết quả mong đợi.** `200`; chi tiết không có địa chỉ backend, danh sách bên đăng ký, bí mật hay thông tin đầu mối cá nhân; không có nút Thử API và Đăng ký sử dụng, thay bằng lời mời đăng nhập; tìm kiếm chỉ trả mục và trang công khai.
:::

#### TC-15-010 · Tenant chưa bật công khai: ẩn danh không thấy gì <!--k:vis-anon-off-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-002, 008 · UC-15-01 · API-15-003, 004 · UI-15-02 · BR-15-005 · ERR-15-001 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** `15.public.enabled = false` (mặc định); U-ANON.

**Các bước.**

1. `GET /public/catalog/apis/thoi-tiet-cong-khai`.
2. Mở `/dich-vu` ở UI khi chưa đăng nhập.

**Kết quả mong đợi.** Bước 1 `404` ERR-15-001 (giả định, Q15-40); bước 2 chuyển tới `/dang-nhap`, không hiện thông báo lỗi.
:::

#### TC-15-011 · Ẩn danh chạm API không đủ điều kiện công khai <!--k:vis-anon-nonpublic-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-008 · UC-15-01 · API-15-004, 010 · ERR-15-001 · BR-15-005, 006 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** `15.public.enabled = true`; U-ANON; `tra-cuu-ho-tich` (TENANT), `dm-hanh-chinh` (NATIONAL), `thoi-tiet-noi-bo` (PUBLIC nhưng INTERNAL).

**Các bước.**

1. `GET /public/catalog/apis/{mã}` cho ba mã.
2. `GET /public/search?q=hộ tịch`.

**Kết quả mong đợi.** Ba mã `404` ERR-15-001 cùng thân; tìm kiếm không trả mục nào ngoài hai mục công khai; trang nội dung `audience = TENANT` không có trong `/public/pages`.
:::

#### TC-15-012 · Vượt tần suất ẩn danh theo IP <!--k:vis-anon-rate-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-008, 005 · API-15-010 · ERR-15-007 · BR-15-005 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** `15.public.rate-limit-per-minute = 30`; U-ANON từ hai IP A, B.

**Các bước.**

1. IP A gọi `GET /public/search?q=a` 31 lần trong 1 phút.
2. IP B gọi một lần.

**Kết quả mong đợi.** Lần 31 của A trả `429` ERR-15-007 kèm `Retry-After`; B `200`; qua phút kế A lại `200`.
:::

#### TC-15-013 · Cán bộ tỉnh khác chỉ thấy mức NATIONAL và PUBLIC <!--k:vis-other-tenant-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-002 · UC-15-01 · API-15-005, 007 · BR-15-002, 003 · ERR-15-001 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** U-T01-USER đăng nhập realm T01, vào tên miền cổng T68; F-CAT.

**Các bước.**

1. `GET /catalog/apis`.
2. `GET /catalog/apis/tra-cuu-ho-tich`.

**Kết quả mong đợi.** Bước 1 đúng 4 mục (xem TC-15-007); bước 2 `404` ERR-15-001.
:::

#### TC-15-014 · Đăng nhập giữa chừng tính lại bộ lọc <!--k:vis-login-switch-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-15-002 · UC-15-01 · UI-15-02 · BR-15-002 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** `15.public.enabled = true`; U-T68-DEV-AN.

**Các bước.**

1. Khách mở `/dich-vu` thấy 2 mục.
2. Bấm Đăng nhập, đăng nhập An.

**Kết quả mong đợi.** Về lại `/dich-vu` (giữ bộ lọc trên URL), trang nạp lại, thấy 7 mục.
:::

#### TC-15-015 · Gỡ và đăng lại cờ `portalPublished` phản ánh ngay <!--k:vis-unpublish-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-15-001, 002 · UC-15-04 · EVT-15-14 · BR-15-001, 002 · LGC-APIM-006; LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** S-PH02; `tra-cuu-ho-tich` đang hiển thị.

**Các bước.**

1. S-PH02 phát EVT-02-05 đặt `portalPublished = false`.
2. Sau 30 giây `GET /catalog/apis/tra-cuu-ho-tich`, tìm kiếm.
3. S-PH02 đặt lại `true`.

**Kết quả mong đợi.** Bước 2: `404` và mất khỏi tìm kiếm (Unpublish); sau bước 3 hiện lại trong 30 giây (Publish).
:::

### TS-15-03 · Trang chủ, duyệt, lọc, dịch vụ sự kiện

**Mục tiêu.** Xác nhận trang chủ, duyệt và lọc danh mục, dịch vụ sự kiện hoạt động đúng và kiểm tra bộ lọc sai.

**Phủ.** FR-15-003, 004, 007; UC-15-01; API-15-001, 002, 005, 006, 013, 014; UI-15-01, 02; ERR-15-003, 008.

#### TC-15-016 · Trang chủ theo nhận diện tenant <!--k:home-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-15-003 · UC-15-01 · API-15-001, 002 · UI-15-01 · BR-15-032 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN và U-ANON (`15.public.enabled = true`); nhận diện T68 đã đặt.

**Các bước.**

1. Mở `/` ở hai vai.

**Kết quả mong đợi.** Có tên cổng, logo, lời chào của T68; khối API nổi bật, tin mới, lối vào tài liệu, ứng dụng; ẩn danh chỉ thấy phần công khai (`/public/home`); không thay màu, phông, vật liệu kính.
:::

#### TC-15-017 · Tenant chưa có API: hướng dẫn công bố cho chủ dịch vụ <!--k:home-empty-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** E2E.

**Truy vết.** FR-15-003 · UC-15-01 · UI-15-01 · FR-15-047 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tenant T90 có bản sao danh mục rỗng; U-T68-SV (chuyển sang T90) và DEV T90.

**Các bước.**

1. Mở `/` bằng chủ dịch vụ rồi bằng nhà phát triển.

**Kết quả mong đợi.** Chủ dịch vụ thấy hướng dẫn liên hệ đầu mối và lối vào "Công bố API"; nhà phát triển chỉ thấy hướng dẫn liên hệ.
:::

#### TC-15-018 · Lọc, sắp xếp, phân trang, facet <!--k:browse-filter-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-004 · UC-15-01 · API-15-005, 006 · UI-15-02 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** U-T68-OR; F-CAT mở rộng 60 API.

**Các bước.**

1. `GET /catalog/apis?linh-vuc=tu-phap&chu-quan=STP68&xac-thuc=oauth2&sap-xep=ten&trang=2&co=20`.
2. `GET /catalog/facets` với cùng bộ lọc.
3. Mở UI-15-02, đặt bộ lọc, nạp lại trang bằng F5.

**Kết quả mong đợi.** Kết quả và phân trang đúng; số ở facet bằng số bản ghi lọc được; thứ tự theo tên tiếng Việt; bộ lọc còn nguyên trên URL sau F5; kết quả rỗng là `200` kèm "Không có dịch vụ nào khớp. Thử bỏ bớt bộ lọc.".
:::

#### TC-15-019 · Giá trị lọc sai miền <!--k:browse-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-004 · API-15-005 · ERR-15-003 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** U-T68-OR.

**Các bước.**

1. `GET /catalog/apis?co=7`, `?linh-vuc=khong-ton-tai`, `?loai=XYZ`, `?sap-xep=;drop`.

**Kết quả mong đợi.** Mỗi lần `400` ERR-15-003 kèm `errors[]` trỏ tham số sai; không `500`; `co` chỉ nhận 10, 20, 50, 100.
:::

#### TC-15-020 · Dịch vụ sự kiện và topic ngoài tầm <!--k:event-svc-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-007 · UC-15-01 · API-15-013, 014, 018 · UI-15-02, 04 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Topic `ho-tich.moi-dang-ky` (AsyncAPI 3.0) ở T68; topic `rieng-t01` chỉ ở T01; U-T68-OR.

**Các bước.**

1. `GET /catalog/topics`; `GET /catalog/topics/ho-tich.moi-dang-ky`; `GET .../events`.
2. `GET /catalog/topics/rieng-t01`.

**Kết quả mong đợi.** Bước 1 có nhãn "Dịch vụ sự kiện", kênh và lược đồ thông điệp; bước 2 `404` ERR-15-001. Lọc `loai=EVENT` ở UI-15-02 chỉ thấy topic.
:::

#### TC-15-021 · Nhãn trạng thái, mục đã ngừng và tạm ngừng <!--k:state-filter-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-15-004, 006 · API-15-005 · UI-15-02 · BR-15-002 · LGC-APIM-006; LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** `dich-vu-cu` DEPRECATED, `tra-cuu-tam-ngung` SUSPENDED, `ban-do-cu` RETIRED.

**Các bước.**

1. Duyệt mặc định rồi bật `da-ngung=true`.

**Kết quả mong đợi.** Mặc định không có `ban-do-cu`; hai mục còn lại có nhãn "Ngừng khuyến nghị", "Tạm ngừng"; bật bộ lọc hiện `ban-do-cu` trong mục "Đã ngừng" và không có đặc tả.
:::

### TS-15-04 · Tìm kiếm toàn văn tiếng Việt và gợi ý

**Mục tiêu.** Xác nhận tìm kiếm không phân biệt dấu, gợi ý, tôn trọng mức hiển thị, dự phòng PostgreSQL và chống lạm dụng.

**Phủ.** FR-15-005; UC-15-02; API-15-010, 011, 012; UI-15-03; ERR-15-003, 007; BR-15-002, 005.

#### TC-15-022 · Tìm không phân biệt dấu và hoa thường <!--k:search-vn-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-005 · UC-15-02 · API-15-011 · UI-15-03 · BR-15-002 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-OR; F-CAT (mô tả của `tra-cuu-ho-tich` chứa "hộ tịch", "Đăng ký khai sinh").

**Các bước.**

1. `GET /search?q=hộ tịch`, `q=ho tich`, `q=HỘ TỊCH`, `q=dang ky khai sinh`.

**Kết quả mong đợi.** Bốn lần cùng kết quả đầu là `tra-cuu-ho-tich` và trang hướng dẫn liên quan, có đoạn nổi bật; phân trang đúng; UI-15-03 hiện số kết quả.
:::

#### TC-15-023 · Gợi ý khi gõ <!--k:search-suggest-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-005 · UC-15-02 · API-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; F-CAT.

**Các bước.**

1. `GET /search/suggest?q=tra c`.

**Kết quả mong đợi.** Tối đa 8 gợi ý bắt đầu bằng "Tra cứu"; không có `tra-cuu-dat-dai` (ngoài tầm của nhà phát triển); p95 ≤ 200 ms (đo ở TC-15-189).
:::

#### TC-15-024 · Tìm kiếm không lộ mục ngoài tầm, kể cả ẩn danh <!--k:search-hidden-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-005, 008 · UC-15-02 · API-15-010, 011 · BR-15-002, 005 · ERR-15-001 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN, U-ANON (công khai bật); trang `huong-dan-noi-bo` `audience = TENANT`; `an-khoi-cong`; `tra-cuu-dat-dai`.

**Các bước.**

1. An tìm `q=đất đai`, `q=an-khoi-cong`, `q=huong-dan-noi-bo`.
2. Khách tìm `q=hộ tịch`.

**Kết quả mong đợi.** Bước 1 không có kết quả; `total` không đếm mục bị ẩn (không dò được bằng số đếm); bước 2 chỉ mục `PUBLIC` và trang `PUBLIC`.
:::

#### TC-15-025 · Dự phòng PostgreSQL FTS khi OpenSearch hỏng <!--k:search-fallback-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT, Chaos.

**Truy vết.** FR-15-005 · UC-15-02 · API-15-011 · NFR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.search.engine = OPENSEARCH`; ngắt OpenSearch; F-CAT.

**Các bước.**

1. `GET /search?q=ho tich`.
2. Đặt `15.search.engine = PG_FTS`, lặp lại.

**Kết quả mong đợi.** Cả hai lần vẫn có `tra-cuu-ho-tich` (unaccent), không `5xx`; không lộ mục ngoài tầm; cảnh báo vận hành được ghi.
:::

#### TC-15-026 · Từ khóa rỗng hoặc quá dài; lạm dụng <!--k:search-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-005 · API-15-011, 012 · ERR-15-003, 007 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN.

**Các bước.**

1. `q=` rỗng; `q` 201 ký tự.
2. 40 lần `GET /search/suggest` trong 10 giây.

**Kết quả mong đợi.** Bước 1 `400` ERR-15-003 "Từ khóa cần từ 1 đến 200 ký tự"; bước 2 sau ngưỡng `429` ERR-15-007 kèm `Retry-After`.
:::

### TS-15-05 · Chi tiết dịch vụ, đường dẫn sử dụng, lộ trình ngừng

**Mục tiêu.** Xác nhận trang chi tiết thay "Xem chi tiết đường dẫn sử dụng" của hệ cũ, hiện đúng banner ngừng, tạm ngừng và ngừng hẳn.

**Phủ.** FR-15-006, 013; UC-15-03; API-15-007, 008, 021; UI-15-04; ERR-15-001, 038; LGC-APIM-017, 006.

#### TC-15-027 · Chi tiết, "Cách gọi API" và SLA <!--k:detail-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-006 · UC-15-03 · API-15-007, 008 · UI-15-04 · BR-15-006 · LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN và U-T68-OR; S-PH02 trả đường dẫn sử dụng của `tra-cuu-ho-tich` theo FR-02-005.

**Các bước.**

1. `GET /catalog/apis/tra-cuu-ho-tich` và `/usage`.
2. Mở UI-15-04 bằng hai vai.

**Kết quả mong đợi.** Gateway URL và context path khớp S-PH02 (đúng tenant); hiện SLA, chủ quản, HTTT cung cấp, nhãn `dataClass`; cán bộ có nút "Đăng ký sử dụng", nhà thầu không có nút đó (chỉ "Thử API", "Tài liệu"); có nút Hỏi đáp và Báo lỗi.
:::

#### TC-15-028 · PH-02 không trả mẫu gọi <!--k:detail-usage-fail-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-006 · UC-15-03 · API-15-008 · UI-15-04 · ERR-15-030 · LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** S-PH02 trả `503` cho đường dẫn sử dụng.

**Các bước.**

1. Mở UI-15-04 của `tra-cuu-ho-tich`.

**Kết quả mong đợi.** Khối "Cách gọi API" hiện "Chưa tải được mẫu gọi. Thử lại."; phần còn lại của trang hiển thị bình thường; chỉ ghi nhật ký ERR-15-030, không lỗi toàn trang.
:::

#### TC-15-029 · Phiên bản DEPRECATED: banner lộ trình ngừng, thông báo bắt buộc <!--k:detail-deprecated-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-013 · UC-15-03 · API-15-015, 021 · UI-15-04, 05 · BR-15-027 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `tra-cuu-ho-tich` có `0.9.0` DEPRECATED (ngừng 31/03/2027, kế nhiệm `1.0.0`) và `1.0.0` PUBLISHED; U-T68-DEV-AN.

**Các bước.**

1. `GET /catalog/apis/tra-cuu-ho-tich?phien-ban=0.9.0` và `/changelog`.
2. Mở UI-15-04, UI-15-05 ở phiên bản `0.9.0`.

**Kết quả mong đợi.** Banner nêu ngày ngừng và liên kết phiên bản kế nhiệm; changelog liệt kê thay đổi theo thời gian, đánh dấu thay đổi phá vỡ; mặc định hiện `1.0.0`; thông báo ngừng khuyến nghị là loại bắt buộc (xem TC-15-148).
:::

#### TC-15-030 · Phiên bản SUSPENDED ẩn Thử API <!--k:detail-suspended-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-006 · UC-15-03 · UI-15-04, 06 · ERR-15-122 · BR-15-002 · LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** `tra-cuu-tam-ngung` SUSPENDED; U-T68-DEV-AN có ứng dụng `app-tra-cuu-ho-tich`.

**Các bước.**

1. Mở UI-15-04.
2. `POST /try/requests` cho API đó.

**Kết quả mong đợi.** Có nhãn "Tạm ngừng", nút Thử API bị ẩn; bước 2 `403` ERR-15-122.
:::

#### TC-15-031 · Phiên bản đã ngừng hẳn trả 410, changelog rỗng <!--k:detail-retired-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-006, 009, 011, 013 · API-15-015, 016, 021 · ERR-15-038 · LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** `ban-do-cu` v1 RETIRED; `tra-cuu-nhay-cam` chưa có thay đổi nào; U-T68-OR.

**Các bước.**

1. `GET /catalog/apis/ban-do-cu/versions/1/spec`.
2. `GET /catalog/apis/bao-cao-noi-bo/changelog`.

**Kết quả mong đợi.** Bước 1 `410` ERR-15-038 "Phiên bản này đã ngừng cung cấp."; bước 2 `200`, danh sách rỗng, UI hiện "Chưa có thay đổi nào được ghi nhận.".
:::

### TS-15-06 · Tài liệu API, phiên bản, so sánh, mẫu mã

**Mục tiêu.** Xác nhận tài liệu OpenAPI 3.1 và AsyncAPI 3.0 hiển thị đúng, tải và so sánh được, mẫu mã sáu ngôn ngữ chạy được và không có bí mật.

**Phủ.** FR-15-009, 010, 011, 012; UC-15-05; API-15-015…020; UI-15-05; ERR-15-003, 009, 038; LGC-APIM-017, IAM-006.

#### TC-15-032 · Hiển thị OpenAPI 3.1 <!--k:doc-openapi-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-009 · UC-15-05 · API-15-016, 017 · UI-15-05 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; đặc tả `tra-cuu-ho-tich` 1.0.0 (12 thao tác, 3 tag, ví dụ, lỗi RFC 9457).

**Các bước.**

1. `GET /catalog/apis/tra-cuu-ho-tich/versions/1.0.0/operations`.
2. Mở UI-15-05, chọn thao tác `getHoTich`, mở bằng neo `#getHoTich`.

**Kết quả mong đợi.** Danh sách thao tác theo tag, tham số, lược đồ yêu cầu/đáp ứng, ví dụ, mã lỗi RFC 9457, bảo mật OAuth2; neo mở đúng thao tác; neo sai thì về đầu trang không lỗi.
:::

#### TC-15-033 · Hiển thị AsyncAPI 3.0 và 2.x <!--k:doc-async-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-010 · UC-15-05 · API-15-018 · UI-15-05 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Topic `ho-tich.moi-dang-ky` (3.0) và `topic-cu` (2.x).

**Các bước.**

1. Mở UI-15-05 của hai topic.

**Kết quả mong đợi.** 3.0: kênh, thông điệp, lược đồ, ví dụ, máy chủ; 2.x: hiển thị thô kèm cảnh báo "Hiển thị ở chế độ tương thích.".
:::

#### TC-15-034 · Đặc tả chưa nạp hoặc không đọc được <!--k:doc-bad-spec-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-009 · UC-15-05 · API-15-016, 017 · UI-15-05 · ERR-15-009 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Phiên bản có F-SPEC-BAD, chưa từng có bản hợp lệ.

**Các bước.**

1. `GET .../operations` và `.../spec`.
2. Mở UI-15-05.

**Kết quả mong đợi.** `422` ERR-15-009; UI "Đặc tả của phiên bản này tạm thời chưa hiển thị được." kèm nút Báo lỗi tài liệu; không `500`.
:::

#### TC-15-035 · Chọn phiên bản và tải đặc tả có kiểm toán <!--k:doc-versions-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-011 · UC-15-05 · API-15-015, 016 · UI-15-05 · BR-15-002 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `tra-cuu-ho-tich` 0.9.0 DEPRECATED và 1.0.0.

**Các bước.**

1. `GET /catalog/apis/tra-cuu-ho-tich/versions`.
2. Tải đặc tả `1.0.0` dạng YAML và JSON bằng nút "Tải đặc tả".

**Kết quả mong đợi.** Danh sách phiên bản có trạng thái, gợi ý kế nhiệm lên đầu cho DEPRECATED; tệp tải về có băm khớp `contentHash`, mở được bằng trình soạn OpenAPI; KT: có (`DOWNLOAD_SPEC`).
:::

#### TC-15-036 · So sánh hai phiên bản <!--k:doc-diff-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-011 · UC-15-05 · API-15-020 · UI-15-05 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Hai phiên bản có sự khác biệt đã biết: thêm 2 thao tác, đổi 1 kiểu trường, xóa 1 tham số.

**Các bước.**

1. `GET /catalog/apis/tra-cuu-ho-tich/diff?tu=0.9.0&den=1.0.0`.

**Kết quả mong đợi.** Báo đúng 2 thêm, 1 đổi, 1 xóa; thay đổi phá vỡ được đánh dấu; chỉ ở mức đọc, không có thao tác sửa.
:::

#### TC-15-037 · So sánh sai đối tượng <!--k:doc-diff-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-011 · API-15-020 · ERR-15-001, 003, 038 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `tra-cuu-ho-tich`, `dm-hanh-chinh`, `ban-do-cu`.

**Các bước.**

1. So sánh phiên bản của hai API khác nhau.
2. So sánh phiên bản không tồn tại.
3. So sánh với phiên bản RETIRED.

**Kết quả mong đợi.** Lần lượt `400` ERR-15-003, `404` ERR-15-001, `410` ERR-15-038.
:::

#### TC-15-038 · Mẫu mã sáu ngôn ngữ chạy được trên sandbox <!--k:sample-langs-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-012 · UC-15-05 · API-15-019 · UI-15-05, 06 · NFR-15-022 · LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; ứng dụng và credential sandbox; sáu ngôn ngữ `curl`, `java`, `python`, `javascript`, `csharp`, `go`.

**Các bước.**

1. `GET /catalog/apis/tra-cuu-ho-tich/samples?ngon-ngu={x}&thao-tac=getHoTich` cho từng ngôn ngữ.
2. Chạy mẫu trong container tương ứng với `clientId`, `clientSecret` thật điền vào chỗ giữ.

**Kết quả mong đợi.** Mẫu có URL sandbox, phương thức, tiêu đề, ví dụ tham số; hướng dẫn lấy token bằng `client_credentials` (không dùng grant `password`); chỗ giữ `<CLIENT_SECRET>`; cả sáu mẫu chạy trả `200` MOCK; ở khung thử mẫu phản ánh đúng yêu cầu đang soạn.
:::

#### TC-15-039 · Mẫu không có ngôn ngữ hoặc thao tác <!--k:sample-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-012 · API-15-019 · ERR-15-001, 003 · LGC-APIM-017; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN.

**Các bước.**

1. `?ngon-ngu=ruby`.
2. `?thao-tac=khongco`.

**Kết quả mong đợi.** `400` ERR-15-003 "Chưa có mẫu cho ngôn ngữ này"; `404` ERR-15-001.
:::

#### TC-15-040 · Tài liệu dữ liệu nhạy cảm: cán bộ xem có kiểm toán, nhà phát triển không thấy <!--k:doc-sensitive-audit-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-009 · UC-15-05 · API-15-016 · BR-15-004 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `tra-cuu-dat-dai` SENSITIVE; U-T68-OR; U-T68-DEV-AN.

**Các bước.**

1. Bình `GET /catalog/apis/tra-cuu-dat-dai/versions/1.0.0/spec`.
2. An làm lại.

**Kết quả mong đợi.** Bình `200`, KT: có (`VIEW_SENSITIVE_DOCS`, `PORTAL_*`); An `404` ERR-15-001.
:::

### TS-15-07 · Soạn trang nội dung Markdown

**Mục tiêu.** Xác nhận chỉ nhân sự có quyền soạn, mã trang bất biến, Markdown bị lọc nguy hiểm, giới hạn cỡ và ảnh đính kèm.

**Phủ.** FR-15-014; UC-15-06; API-15-022…025, 033, 138; UI-15-21; ERR-15-002, 003, 005, 006, 021, 024; BR-15-007, 012, 013, 034.

#### TC-15-041 · Tạo trang nháp lũy đẳng <!--k:page-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-014 · UC-15-06 · API-15-022, 023, 024 · UI-15-21 · BR-15-034 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV (có `PERM-15-content-write`); mã `bat-dau-nhanh`.

**Các bước.**

1. `POST /content/pages` {pageCode, type `QUICKSTART`, lang `vi`, audience `LOGGED_IN`, nội dung Markdown} với `Idempotency-Key` K1.
2. Gửi lại đúng yêu cầu với K1.
3. `GET /content/pages/bat-dau-nhanh`.

**Kết quả mong đợi.** Bước 1 `201`, `ETag`, trạng thái `DRAFT`; bước 2 trả cùng phản hồi, không tạo bản thứ hai; bước 3 có phiên bản nháp 1 và tên người soạn.
:::

#### TC-15-042 · Mã trùng, sai mẫu, dùng lại mã đã lưu trữ <!--k:page-code-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-014 · UC-15-06 · API-15-023 · ERR-15-002, 003 · BR-15-007 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV; `bat-dau-nhanh` tồn tại; `da-luu-tru` đã ARCHIVED.

**Các bước.**

1. Tạo lại `bat-dau-nhanh`; tạo `Bat_Dau`; tạo `da-luu-tru`.

**Kết quả mong đợi.** `409` ERR-15-002 "Mã bat-dau-nhanh đã được dùng. Chọn mã khác."; `400` ERR-15-003 (mẫu `^[a-z0-9][a-z0-9-]{1,62}$`); `409` ERR-15-002 (mã không dùng lại sau lưu trữ).
:::

#### TC-15-043 · Lọc Markdown nguy hiểm <!--k:page-md-filter-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** FR-15-014 · UC-15-06 · API-15-025 · ERR-15-021 · BR-15-013 · NFR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** F-MD-XSS: `<script>`, `<iframe>`, `<img onerror>`, `[x](javascript:alert(1))`, `![x](https://evil.test/a.png)`, HTML thô `<div style>`, `<svg onload>`.

**Các bước.**

1. `PUT /content/pages/bat-dau-nhanh` với từng mẫu (kèm `If-Match`).
2. `PUT` bản có `[ok](https://example.org)`; mở UI-15-07.

**Kết quả mong đợi.** Mỗi mẫu `422` ERR-15-021 nêu phần không được phép và dòng; bản hợp lệ lưu được, liên kết ngoài có `rel="noopener nofollow"`; không mẫu nào được lưu vào CSDL.
:::

#### TC-15-044 · Biên cỡ trang 200 KB <!--k:page-size-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-014 · API-15-025 · ERR-15-021 · BR-15-013 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV; hai nội dung Markdown 204.800 byte và 204.801 byte.

**Các bước.**

1. `PUT` hai nội dung.

**Kết quả mong đợi.** Bản 204.800 byte `200`; bản 204.801 byte `422` ERR-15-021 (mã lỗi cho vượt cỡ chờ Q15-41).
:::

#### TC-15-045 · Đính kèm ảnh hợp lệ và đọc lại <!--k:attach-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-014, 017 · API-15-033, 138 · BR-15-013 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV; F-IMG-OK (PNG 1 MB), WebP 4,9 MB.

**Các bước.**

1. `POST /content/attachments` hai tệp.
2. `GET /content/attachments/{attachmentId}` bằng U-T68-DEV-AN trong trang đã đăng.

**Kết quả mong đợi.** `201` có `attachmentId`; ảnh phục vụ bằng URL ký có hạn, đúng `Content-Type`, `nosniff`; ảnh nằm trong kho của cổng (không liên kết ra ngoài).
:::

#### TC-15-046 · Đính kèm không hợp lệ hoặc nhiễm mã độc <!--k:attach-bad-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-014 · API-15-033 · ERR-15-024 · BR-15-013 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** F-IMG-SVG, ảnh 5,1 MB, EICAR đội vỏ PNG (ClamAV), polyglot GIF+JS, tệp đổi đuôi `.png`.

**Các bước.**

1. `POST /content/attachments` với từng tệp.

**Kết quả mong đợi.** Mỗi tệp `422` ERR-15-024; không tệp nào được lưu; ClamAV ghi nhận EICAR.
:::

#### TC-15-047 · Hai người sửa cùng lúc <!--k:page-concurrency-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-014 · API-15-025 · ERR-15-006 · BR-15-034 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV và U-T68-CA cùng mở phiên bản nháp, cùng `ETag` E1.

**Các bước.**

1. SV `PUT` với `If-Match: E1`; CA `PUT` với `If-Match: E1`.

**Kết quả mong đợi.** Lần hai `412` ERR-15-006 "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."; nội dung lần một không bị ghi đè.
:::

#### TC-15-048 · Nhà phát triển và kiểm toán viên không soạn được <!--k:page-perm-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-014 · API-15-022, 023 · ERR-15-005 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN, U-T68-AU, U-T68-OR (không có `PERM-15-content-write`).

**Các bước.**

1. Mỗi người `POST /content/pages`, `GET /content/pages`.

**Kết quả mong đợi.** `403` ERR-15-005; không có bản ghi; menu soạn nội dung không hiện ở UI.
:::

### TS-15-08 · Duyệt bốn mắt, đăng và vòng đời trang

**Mục tiêu.** Xác nhận chỉ có một đường tới PUBLISHED là duyệt của người khác, phiên bản giữ lại, gỡ và hiển thị đúng đối tượng.

**Phủ.** FR-15-015, 016, 017; UC-15-07, 09; API-15-026…032, 034…037, 142; UI-15-07, 22; EVT-15-08, 09; ERR-15-022, 023; BR-15-012.

#### TC-15-049 · Soạn, gửi duyệt, duyệt, đăng <!--k:flow-happy-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-15-015, 017 · UC-15-07 · API-15-026, 027, 037 · UI-15-21, 22, 07 · EVT-15-08 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV soạn, U-T68-CA duyệt; trang `bat-dau-nhanh` DRAFT.

**Các bước.**

1. SV `POST /content/pages/bat-dau-nhanh:submit`.
2. CA `POST ...:approve`.
3. U-T68-DEV-AN `GET /pages/bat-dau-nhanh`.

**Kết quả mong đợi.** `IN_REVIEW` rồi `PUBLISHED`; đúng một EVT-15-08 `content.published`; KT: có; trang hiển thị trong ≤ 5 giây (bộ đệm vô hiệu); lịch sử có người soạn, người gửi, người duyệt.
:::

#### TC-15-050 · Không tự duyệt, kể cả người sửa gần nhất <!--k:flow-four-eyes-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-015 · UC-15-07 · API-15-027 · ERR-15-023 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV gửi duyệt; U-T68-CA sửa 1 dòng của bản nháp rồi gửi lại; U-T68-TA.

**Các bước.**

1. SV tự `:approve`.
2. CA soạn trang `dieu-khoan-moi`, tự gửi, tự `:approve`.
3. Với bản CA là người sửa gần nhất của SV: CA `:approve`.
4. TA `:approve`.

**Kết quả mong đợi.** Bước 1…3 `403` ERR-15-023 "Người duyệt phải khác người soạn và người gửi duyệt."; trạng thái không đổi; bước 4 `200`.
:::

#### TC-15-051 · Từ chối có lý do, soạn lại <!--k:flow-reject-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-015 · UC-15-07 · API-15-028 · ERR-15-003 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Trang IN_REVIEW của U-T68-SV; U-T68-CA.

**Các bước.**

1. `POST ...:reject` thiếu lý do.
2. `POST ...:reject` {lý do}.
3. SV sửa tiếp rồi gửi lại.

**Kết quả mong đợi.** Bước 1 `400` ERR-15-003 "Cần nêu lý do từ chối"; bước 2 phiên bản `REJECTED` giữ vĩnh viễn, trang về `DRAFT` có thể sửa; bước 3 tạo phiên bản mới `IN_REVIEW`.
:::

#### TC-15-052 · Thao tác sai trạng thái <!--k:flow-state-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-015, 016 · API-15-026, 027, 029 · ERR-15-022 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Trang DRAFT, trang IN_REVIEW, trang UNPUBLISHED.

**Các bước.**

1. `:approve` trang DRAFT.
2. `:unpublish` trang không PUBLISHED.
3. `PUT` nội dung của phiên bản IN_REVIEW.

**Kết quả mong đợi.** `409` ERR-15-022 "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này." cho từng bước; người soạn rút lại bản IN_REVIEW được (về `DRAFT`).
:::

#### TC-15-053 · Nhắc duyệt quá hạn <!--k:flow-sla-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-15-015 · UC-15-07 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.content.review-sla-days = 1`; trang IN_REVIEW; đồng hồ giả lập +25 giờ.

**Các bước.**

1. Chạy tác vụ nhắc.

**Kết quả mong đợi.** "Việc của tôi" của người có quyền duyệt hiện yêu cầu; TA nhận thông báo; trang vẫn IN_REVIEW.
:::

#### TC-15-054 · Phiên bản trang, so sánh, khôi phục <!--k:ver-history-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-016 · UC-15-07 · API-15-030, 031, 032, 142 · UI-15-22 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Trang `bat-dau-nhanh` có phiên bản 1 PUBLISHED (SUPERSEDED), 2 PUBLISHED, 3 REJECTED; U-T68-CA.

**Các bước.**

1. `GET /content/pages/bat-dau-nhanh/versions` và `/versions/1`.
2. `GET /content/pages/bat-dau-nhanh/diff?tu=1&den=2` (API-15-142).
3. `POST .../versions/1:restore`.

**Kết quả mong đợi.** Cả ba phiên bản còn đủ; so sánh đúng dòng thêm/xóa; khôi phục tạo phiên bản nháp mới từ bản 1 và phải duyệt lại, bản đang đăng không đổi.
:::

#### TC-15-055 · Gỡ đăng và gỡ điều khoản duy nhất <!--k:ver-unpublish-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-016 · UC-15-07 · API-15-029, 035 · EVT-15-09 · ERR-15-022 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Trang `bat-dau-nhanh` PUBLISHED; trang TERMS đang hiệu lực, chưa có bản thay.

**Các bước.**

1. CA `:unpublish` `bat-dau-nhanh`; `GET /public/pages/bat-dau-nhanh`.
2. CA `:unpublish` trang TERMS.

**Kết quả mong đợi.** Bước 1 `UNPUBLISHED`, EVT-15-09, trang `404` ở cổng; bước 2 `409` ERR-15-022 "Không thể gỡ điều khoản đang có hiệu lực".
:::

#### TC-15-056 · Hiển thị theo đối tượng và trạng thái <!--k:page-view-aud-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-017 · UC-15-09 · API-15-034, 035, 036, 037 · UI-15-07 · BR-15-005 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Trang `PUBLIC`, `LOGGED_IN`, `TENANT`, và `DRAFT`; `15.public.enabled = true`; U-ANON, U-T68-DEV-AN, U-T68-OR.

**Các bước.**

1. Mỗi vai gọi `GET /public/pages` hoặc `GET /pages`, rồi chi tiết từng trang.
2. Trang chưa có bản `en`; ảnh có URL ký đã hết hạn.

**Kết quả mong đợi.** Ẩn danh chỉ thấy `PUBLIC`; nhà phát triển thấy `PUBLIC`, `LOGGED_IN`; cán bộ thấy thêm `TENANT`; trang `DRAFT` hoặc ngoài đối tượng `404` ERR-15-001; thiếu `en` hiện `vi` kèm ghi chú; ảnh hết chữ ký được cấp lại khi tải lại trang, không hiện lỗi.
:::

### TS-15-09 · Nhập Git và di trú nội dung portal cũ

**Mục tiêu.** Xác nhận nội dung nhập từ Git và từ portal Gravitee đều thành bản nháp phải duyệt, qua bộ lọc, và gói sai bị từ chối.

**Phủ.** FR-15-018, 062; UC-15-08; API-15-038…040, 135…137; UI-15-21, 27; ERR-15-024, 025, 026, 035; BR-15-012, 013; LGC-APIM-006.

#### TC-15-057 · Đồng bộ nội dung từ kho Git <!--k:git-sync-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT, API.

**Truy vết.** FR-15-018 · UC-15-08 · API-15-038, 039, 040 · UI-15-21, 27 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV; kho F-GIT-OK (`portal.yaml`, 12 tệp `.md`, 4 ảnh); S-GIT.

**Các bước.**

1. `POST /content/git-sources` rồi `:sync`; sau đó đồng bộ lại.
2. Gọi webhook của kho.

**Kết quả mong đợi.** 12 trang `DRAFT` (không tự đăng), ảnh nạp vào kho; lần hai không nhân bản (so băm); webhook kích hoạt đồng bộ ngay; chu kỳ `15.git.sync-interval-minutes` đúng.
:::

#### TC-15-058 · Kho lỗi hoặc cấu trúc sai <!--k:git-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-018 · API-15-040 · ERR-15-025, 026, 024 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Kho không với tới; kho thiếu `portal.yaml`; kho có `.exe` và `.svg`.

**Các bước.**

1. `:sync` từng kho.

**Kết quả mong đợi.** `502` ERR-15-025; `422` ERR-15-026 "Kho thiếu tệp portal.yaml hoặc sai cấu trúc"; tệp cấm bị bỏ và báo; không trang nào tạo từ kho lỗi.
:::

#### TC-15-059 · Di trú portal Gravitee <!--k:migrate-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, UAT.

**Truy vết.** FR-15-062 · UC-15-08 · API-15-135, 136, 137 · UI-15-27 · BR-15-012, 013 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** U-T68-TA; F-ZIP-GRAVITEE (xuất portal cũ: 8 trang, 5 ảnh, 3 tài liệu API, có thẻ `<script>`).

**Các bước.**

1. `POST /admin/migrations` tải gói; theo dõi `GET /admin/migrations/{id}`.
2. `POST .../{id}:confirm`.

**Kết quả mong đợi.** Báo cáo xem trước: 8 trang, 5 ảnh, 3 tài liệu, phần bị loại; sau xác nhận có 11 trang `DRAFT` phải qua duyệt bốn mắt mới đăng; `<script>` bị loại; ảnh nằm trong kho cổng; mọi trang nằm đúng mục hướng dẫn.
:::

#### TC-15-060 · Gói di trú sai, nhiễm mã độc, chạy song song <!--k:migrate-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-062 · API-15-135, 137 · ERR-15-024, 026, 035 · BR-15-013 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** Gói thiếu cấu trúc, gói có `.exe`, gói có EICAR, gói 51 MB; U-T68-TA, U-T68-DEV-AN.

**Các bước.**

1. Tải từng gói; tải gói hợp lệ lần hai khi lần một đang chạy.
2. An `POST /admin/migrations`.

**Kết quả mong đợi.** `422` ERR-15-026 (ba gói đầu), `422` ERR-15-024 (EICAR); `409` ERR-15-035; An `403` ERR-15-005.
:::

### TS-15-10 · Đăng nhập, phiên và hồ sơ

**Mục tiêu.** Xác nhận đăng nhập SSO và dh-dev qua BFF, trạng thái tài khoản chặn đăng nhập, và hồ sơ, phiên của chính mình.

**Phủ.** FR-15-019, 021; UC-15-10, 12; API-15-041…044; UI-15-08, 09; ERR-15-003, 004, 005, 006, 011, 014, 020.

#### TC-15-061 · Cán bộ đăng nhập SSO realm tenant <!--k:sso-login-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-15-019 · UC-15-10 · API-15-041 · UI-15-08 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-OR có tài khoản Keycloak realm T68; chưa có tài khoản cổng.

**Các bước.**

1. Bấm Đăng nhập ở UI-15-08 (`/bff/dang-nhap`), xác thực ở Keycloak.
2. `GET /me`.

**Kết quả mong đợi.** Chuyển về cổng bằng Authorization Code + PKCE; tạo tài khoản cổng `ACTIVE`, nguồn `TENANT_SSO`; cookie phiên `HttpOnly`, `Secure`, `SameSite`; hạng người xem `TENANT_USER`; đăng xuất `/bff/dang-xuat` hủy phiên.
:::

#### TC-15-062 · Tài khoản chưa duyệt, khóa, hết phiên <!--k:login-state-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-019 · UC-15-10 · UI-15-08 · ERR-15-004, 011, 014 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tài khoản dh-dev PENDING_EMAIL, PENDING_APPROVAL, LOCKED, DISABLED; phiên đã hết hạn.

**Các bước.**

1. Đăng nhập từng tài khoản.
2. Gọi `GET /me` với cookie hết hạn.

**Kết quả mong đợi.** `422` ERR-15-011 cho hai tài khoản chưa duyệt; `403` ERR-15-014 cho LOCKED, DISABLED; `401` ERR-15-004 và UI đưa về đăng nhập rồi quay lại đường dẫn cũ.
:::

#### TC-15-063 · Keycloak lỗi nhưng trang công khai vẫn xem được <!--k:login-kc-down-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-15-019 · UC-15-10 · UI-15-08 · ERR-15-020 · NFR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt Keycloak; `15.public.enabled = true`.

**Các bước.**

1. Bấm Đăng nhập.
2. Khách mở `/dich-vu`, `/huong-dan`.

**Kết quả mong đợi.** Bước 1 `503` ERR-15-020 "Dịch vụ đăng nhập tạm gián đoạn. Các trang công khai vẫn xem được"; bước 2 `200`.
:::

#### TC-15-064 · Hồ sơ và thu hồi phiên của mình <!--k:profile-session-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-021 · UC-15-12 · API-15-041, 042, 043, 044 · UI-15-09 · BR-15-034 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN đăng nhập trên hai trình duyệt.

**Các bước.**

1. `PUT /me` đổi số điện thoại với `If-Match`.
2. `GET /me/sessions`; `DELETE /me/sessions/{phiên kia}`.

**Kết quả mong đợi.** Hồ sơ đổi, KT; phiên kia bị hủy ngay (lệnh kế trả `401`); phiên hiện tại giữ.
:::

#### TC-15-065 · Sai ETag, giá trị sai, thu hồi phiên người khác <!--k:profile-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-021 · API-15-042, 044 · ERR-15-003, 005, 006 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN, U-T68-DEV-CU.

**Các bước.**

1. `PUT /me` với `If-Match` cũ; số điện thoại sai định dạng.
2. Cự `DELETE /me/sessions/{phiên của An}`.

**Kết quả mong đợi.** `412` ERR-15-006; `400` ERR-15-003; `403` ERR-15-005 và phiên của An không đổi.
:::

### TS-15-11 · Tự đăng ký dh-dev và duyệt tài khoản

**Mục tiêu.** Xác nhận hai cổng chặn (xác minh thư, duyệt quản trị) trước khi nhà thầu có quyền, và quản trị đúng quyền.

**Phủ.** FR-15-020, 058; UC-15-11, 30; API-15-045, 046, 121…123; UI-15-08, 24; EVT-15-06, 07; ERR-15-003, 005, 012, 013, 020, 022, 037; BR-15-028.

#### TC-15-066 · Đăng ký, xác minh thư, chờ duyệt <!--k:reg-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-15-020 · UC-15-11 · API-15-045, 046 · UI-15-08 · EVT-15-06 · BR-15-028, 029 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Hộp thư giả lập (Mailpit); `an@abc.example.vn`, Công ty ABC, hợp đồng `HD-2026-07`, đơn vị bảo lãnh Sở TT&TT.

**Các bước.**

1. `POST /developer-registrations`.
2. Lấy mã trong thư, `POST /developer-registrations:verify-email`.
3. Thử đăng nhập.

**Kết quả mong đợi.** `PENDING_EMAIL` rồi `PENDING_APPROVAL`; EVT-15-06 một lần; KT: có; chỉ hỏi họ tên, thư, đơn vị, số hợp đồng, bảo lãnh, điện thoại tùy chọn, có thông báo xử lý dữ liệu cá nhân; bước 3 `422` ERR-15-011.
:::

#### TC-15-067 · Thư trùng, mã sai, hết hạn, thiếu trường <!--k:reg-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-020 · UC-15-11 · API-15-045, 046 · ERR-15-003, 012, 013 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `an@abc.example.vn` đã đăng ký; đồng hồ +25 giờ.

**Các bước.**

1. Đăng ký lại cùng thư; thiếu số hợp đồng.
2. Xác minh với mã sai; xác minh sau 25 giờ.

**Kết quả mong đợi.** `409` ERR-15-012; `400` ERR-15-003 lỗi theo trường; `400` ERR-15-013; sau 25 giờ tài khoản `EXPIRED`.
:::

#### TC-15-068 · Gửi lại thư và đăng ký quá nhiều <!--k:reg-rate-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-020 · API-15-045 · ERR-15-037 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Một IP; một tài khoản PENDING_EMAIL.

**Các bước.**

1. Gửi lại thư xác minh 4 lần trong 1 giờ.
2. Đăng ký liên tục từ một IP quá ngưỡng.

**Kết quả mong đợi.** Lần 4 và lần vượt ngưỡng `429` ERR-15-037 "Bạn gửi quá nhiều. Thử lại sau {n} phút."
:::

#### TC-15-069 · Tenant tắt đăng ký tự phục vụ <!--k:reg-off-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-15-020 · UI-15-08 · ERR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.dev.signup-enabled = false`.

**Các bước.**

1. Mở `/dang-ky`; `POST /developer-registrations`.

**Kết quả mong đợi.** UI ẩn mục đăng ký; API `403` ERR-15-005 (giả định, Q15-41).
:::

#### TC-15-070 · Quản trị duyệt tài khoản <!--k:approve-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-15-058 · UC-15-30 · API-15-121, 122 · UI-15-24 · EVT-15-07 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tài khoản An PENDING_APPROVAL; U-T68-TA.

**Các bước.**

1. `GET /admin/dev-accounts?trang-thai=PENDING_APPROVAL`.
2. `POST /admin/dev-accounts/{userId}:approve`.
3. An đăng nhập.

**Kết quả mong đợi.** `ACTIVE`; người dùng được tạo ở realm `dh-dev` Keycloak; thư thông báo; EVT-15-07; KT: có; An vào được cổng, hạng `DEV_USER`; từ chối `:reject` có lý do giúp tài khoản `REJECTED` và thư thông báo.
:::

#### TC-15-071 · Duyệt sai trạng thái, thiếu lý do, Keycloak lỗi <!--k:approve-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-058 · UC-15-30 · API-15-122, 123 · ERR-15-003, 020, 022 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tài khoản ACTIVE; tài khoản PENDING_APPROVAL khi ngắt Keycloak.

**Các bước.**

1. `:approve` tài khoản ACTIVE.
2. `:reject` không có lý do.
3. `:approve` khi Keycloak ngắt; sau đó khôi phục và thử lại.

**Kết quả mong đợi.** `409` ERR-15-022; `400` ERR-15-003 "Cần nêu lý do từ chối"; `503` ERR-15-020 và tài khoản vẫn `PENDING_APPROVAL`, thử lại thành công.
:::

#### TC-15-072 · Chỉ vai trò có `PERM-15-dev-approve` duyệt được <!--k:approve-perm-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-058 · API-15-121, 122, 124 · ERR-15-005 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN, U-T68-OR, U-T68-SV, U-T68-SO, U-T68-TA.

**Các bước.**

1. Mỗi người gọi `GET /admin/dev-accounts` và `:approve`.

**Kết quả mong đợi.** An, Bình, Chi `403` ERR-15-005; Khánh (SO) và Hà (TA) `200` theo D02-08 (xem Q15-46 ở UC); nhắc quá `15.dev.approval-sla-days` gửi TA.
:::

### TS-15-12 · Điều khoản, nhóm, vô hiệu hóa và xóa tài khoản

**Mục tiêu.** Xác nhận chấp nhận điều khoản có phiên bản, nhóm phát triển đúng chủ sở hữu, vô hiệu hóa 45 ngày và xóa theo yêu cầu.

**Phủ.** FR-15-022, 023, 024; UC-15-12, 13; API-15-047…054; UI-15-09, 24; EVT-15-07, 13; ERR-15-002, 003, 010, 014, 027, 028; BR-15-028, 029.

#### TC-15-073 · Chưa chấp nhận điều khoản thì chặn tạo ứng dụng và thử <!--k:terms-block-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-023 · UC-15-12 · API-15-047, 048, 056, 072 · ERR-15-010 · BR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Điều khoản v2 hiện hành; U-T68-DEV-BI chưa chấp nhận.

**Các bước.**

1. Bi `POST /apps`, `POST /try/requests`.
2. Bi `GET /catalog/apis`, `GET /catalog/apis/tra-cuu-ho-tich/versions/1.0.0/spec`.

**Kết quả mong đợi.** Bước 1 `409` ERR-15-010 "Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục."; bước 2 `200` (vẫn đọc danh mục, tài liệu).
:::

#### TC-15-074 · Chấp nhận và điều khoản mới bắt buộc chấp nhận lại <!--k:terms-accept-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-023 · UC-15-12 · API-15-047, 048 · UI-15-09 · BR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-BI; U-T68-TA đăng điều khoản v3.

**Các bước.**

1. `GET /terms/current`; `POST /terms/acceptances` với v2; `POST /apps`.
2. Với v1 (cũ).
3. TA đăng v3 (xem TC-15-055); Bi `POST /apps`.

**Kết quả mong đợi.** v2 `201`, tạo ứng dụng được; v1 `400` ERR-15-003; sau v3 người dùng đang hoạt động nhận thông báo bắt buộc và bị chặn `409` ERR-15-010 đến khi chấp nhận lại; KT lưu phiên bản, thời điểm.
:::

#### TC-15-075 · Tạo nhóm, mời, chấp nhận <!--k:team-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-022 · UC-15-13 · API-15-049, 050, 051, 052 · UI-15-09 · EVT-15-13 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN, U-T68-DEV-BI.

**Các bước.**

1. An `POST /teams` `nhom-thau-a`; mời Bi.
2. Bi `POST /me/invitations/{id}:respond` chấp nhận.

**Kết quả mong đợi.** Nhóm có An `OWNER`, Bi thành viên; EVT-15-13; Bi thấy nhóm ở `GET /teams`; lời mời hết hạn chuyển `EXPIRED`.
:::

#### TC-15-076 · Trùng mã, trùng lời mời, rời nhóm khi là chủ duy nhất <!--k:team-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-022 · API-15-050, 051, 053 · ERR-15-002, 027, 028 · BR-15-007 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** Nhóm `nhom-thau-a` (An OWNER, Bi thành viên).

**Các bước.**

1. Tạo lại `nhom-thau-a`; mời Bi lần hai.
2. `DELETE /teams/nhom-thau-a/members/{An}`.
3. Cự (không thuộc nhóm) `POST /teams/nhom-thau-a/invitations`.

**Kết quả mong đợi.** `409` ERR-15-002; `409` ERR-15-027; `422` ERR-15-028 "Phải còn ít nhất một chủ sở hữu."; Cự `403` ERR-15-005.
:::

#### TC-15-077 · Vô hiệu hóa sau 45 ngày và kích hoạt lại <!--k:inactive-45d-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-15-024 · UC-15-12 · API-15-041 · EVT-15-07 · ERR-15-014 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tài khoản An ACTIVE; đồng hồ giả lập; tài khoản Bi đăng nhập ngày 44.

**Các bước.**

1. Đẩy đồng hồ 45 ngày không hoạt động.
2. An đăng nhập; yêu cầu kích hoạt lại; TA duyệt.

**Kết quả mong đợi.** An `DISABLED` (EVT-15-07), đăng nhập `403` ERR-15-014; sau yêu cầu `PENDING_APPROVAL`, TA duyệt thì `ACTIVE`; bộ đếm của Bi được đặt lại, không bị vô hiệu.
:::

#### TC-15-078 · Xóa tài khoản theo yêu cầu và ẩn danh tự động <!--k:erase-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-15-024 · UC-15-12 · API-15-054 · ERR-15-003, 028 · BR-15-029 · NFR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tài khoản dh-dev Cự có ứng dụng, lượt thử; tài khoản An là chủ duy nhất nhóm còn thành viên; tài khoản dh-dev `du.khong-hd` không hoạt động 24 tháng (đồng hồ giả lập).

**Các bước.**

1. Cự `POST /me:request-erasure` sai cụm xác nhận, rồi đúng.
2. An làm cùng việc.
3. Đẩy đồng hồ 24 tháng cho tài khoản không hoạt động.

**Kết quả mong đợi.** Sai cụm `400` ERR-15-003; đúng: `ERASED`, họ tên, thư ẩn danh, credential bị thu hồi, lượt thử giữ ở dạng ẩn danh; An `422` ERR-15-028; sau 24 tháng tài khoản tự ẩn danh.
:::

### TS-15-13 · Ứng dụng sandbox và thành viên

**Mục tiêu.** Xác nhận tạo, xem, sửa, lưu trữ, khôi phục ứng dụng, giới hạn số lượng, vai trò thành viên và cô lập giữa người dùng cùng tenant.

**Phủ.** FR-15-025, 026, 033; UC-15-13, 14; API-15-055…060, 066…068; UI-15-10, 11, 12; EVT-15-01, 02, 13; ERR-15-002, 003, 005, 006, 010, 015, 017, 027, 028, 032; BR-15-007, 009, 010.

#### TC-15-079 · Tạo ứng dụng sandbox <!--k:app-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-15-025 · UC-15-14 · API-15-055, 056, 057 · UI-15-10, 11 · EVT-15-01 · BR-15-007, 009 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN đã chấp nhận điều khoản.

**Các bước.**

1. Mở UI-15-11, nhập `app-tra-cuu-ho-tich`, tên, mô tả, chủ sở hữu cá nhân.
2. `GET /apps`, `GET /apps/app-tra-cuu-ho-tich`.

**Kết quả mong đợi.** `201`, `ACTIVE`, An là `OWNER`; EVT-15-01; xuất hiện ở UI-15-10; chọn "Cấp thông tin xác thực ngay" chuyển sang UI-15-13.
:::

#### TC-15-080 · Mã sai, trùng, vượt giới hạn, HTTT lạ <!--k:app-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-025 · UC-15-14 · API-15-056, 141 · ERR-15-002, 003, 015, 032 · BR-15-010 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** `15.app.max-per-user = 2`; An đã có 2 ứng dụng; U-T68-OR; HT-TUPHAP không thuộc đơn vị của Bình.

**Các bước.**

1. An `GET /apps:check-code` với mã đã dùng và mã `AB`; rồi tạo mã trùng, mã `AB`.
2. An tạo ứng dụng thứ 3.
3. Bình tạo ứng dụng gắn `HT-TUPHAP`.

**Kết quả mong đợi.** `check-code` báo mã đã dùng, mã sai mẫu; `409` ERR-15-002; `400` ERR-15-003; `422` ERR-15-015 "Đã đạt số ứng dụng tối đa (2)..."; `422` ERR-15-032 "HTTT này không thuộc đơn vị của bạn".
:::

#### TC-15-081 · Người ngoài ứng dụng không xem, sửa được <!--k:app-isolation-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-026 · UC-15-14 · API-15-055, 057, 058 · ERR-15-005, 001 · BR-15-009, 034 · NFR-15-017 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** `app-tra-cuu-ho-tich` của An; U-T68-DEV-CU (cùng tenant, không thành viên); U-T01-DEV có ứng dụng cùng mã ở T01.

**Các bước.**

1. Cự `GET /apps/app-tra-cuu-ho-tich`, `PATCH`, `:archive`.
2. Cự `GET /apps`.
3. U-T01-DEV qua tên miền T68 gọi `GET /apps/app-tra-cuu-ho-tich`.

**Kết quả mong đợi.** Bước 1 `403` ERR-15-005; bước 2 không có ứng dụng của An; bước 3 `404` ERR-15-001 thân giống "không tồn tại"; dữ liệu của An không đổi.
:::

#### TC-15-082 · Sửa ứng dụng, xung đột phiên bản, vai trò VIEWER <!--k:app-edit-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-026 · UC-15-14 · API-15-058 · ERR-15-005, 006 · BR-15-009, 034 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** Ứng dụng có An `OWNER`, Bi `VIEWER`.

**Các bước.**

1. An `PATCH` đổi tên với `If-Match` đúng; lặp với `If-Match` cũ.
2. Bi `PATCH`.

**Kết quả mong đợi.** `200`; `412` ERR-15-006; Bi `403` ERR-15-005.
:::

#### TC-15-083 · Lưu trữ thu hồi credential, khôi phục không khôi phục bí mật <!--k:app-archive-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-026 · UC-15-14, 16 · API-15-059, 060 · EVT-15-02, 05 · ERR-15-017, 102 · BR-15-010 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** Ứng dụng ACTIVE có 2 credential; An.

**Các bước.**

1. `:archive`; thử gọi sandbox bằng credential cũ.
2. `:restore` trong 30 ngày.
3. Lặp `:restore` khi ACTIVE; `PATCH` ứng dụng ARCHIVED.

**Kết quả mong đợi.** Bước 1 `ARCHIVED`, hai credential `REVOKED` (EVT-15-05 hai lần), `POST /try/requests` `403` ERR-15-102; bước 2 `ACTIVE`, credential vẫn REVOKED phải cấp mới; bước 3 `409` ERR-15-017; sau 30 ngày xóa không khôi phục được.
:::

#### TC-15-084 · Ứng dụng không dùng 180 ngày tự lưu trữ <!--k:app-auto-archive-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-15-026 · EVT-15-02 · BR-15-010 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** Ứng dụng không có lượt gọi; đồng hồ +180 ngày.

**Các bước.**

1. Chạy tác vụ lưu trữ tự động.

**Kết quả mong đợi.** Có thông báo trước; ứng dụng `ARCHIVED`, EVT-15-02 `reason` ghi không hoạt động; credential bị thu hồi.
:::

#### TC-15-085 · Giao ứng dụng cho thành viên và vai trò <!--k:app-members-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-033 · UC-15-13 · API-15-066, 067, 068 · UI-15-12 · EVT-15-13 · BR-15-009 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ứng dụng của An; Bi.

**Các bước.**

1. `PUT /apps/{}/members/{Bi}` vai `DEVELOPER`; Bi cấp credential, thử API.
2. Đổi Bi thành `VIEWER`; Bi cấp credential.
3. `DELETE` Bi.

**Kết quả mong đợi.** DEVELOPER dùng được; VIEWER xem được thống kê nhưng cấp credential, thử API `403` ERR-15-005; sau xóa Bi mất truy cập; EVT-15-13 mỗi lần.
:::

#### TC-15-086 · Thành viên trùng, xóa chủ duy nhất, không đủ quyền <!--k:app-members-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-033 · API-15-067, 068 · ERR-15-005, 027, 028 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ứng dụng của An (OWNER duy nhất), Bi DEVELOPER.

**Các bước.**

1. An thêm Bi lần hai.
2. An xóa chính mình.
3. Bi thêm người.

**Kết quả mong đợi.** `409` ERR-15-027; `422` ERR-15-028; `403` ERR-15-005.
:::

### TS-15-14 · Cấp thông tin xác thực và bí mật hiện một lần

**Mục tiêu.** Xác nhận cấp client_credentials và API key sandbox thay credential tự phục vụ của hệ cũ, bí mật hiện đúng một lần và không có đường nào đọc lại.

**Phủ.** FR-15-027, 028, 029; UC-15-15; API-15-061, 062; UI-15-13; EVT-15-03; ERR-15-005, 016, 017, 019, 020; BR-15-010, 011; LGC-IAM-006.

#### TC-15-087 · Cấp client_credentials sandbox <!--k:cred-cc-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-027, 029 · UC-15-15 · API-15-061, 062 · UI-15-13 · EVT-15-03 · BR-15-011 · NFR-15-006 · LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; ứng dụng ACTIVE; Keycloak realm `dh-dev` thật ở SIT.

**Các bước.**

1. `POST /apps/app-tra-cuu-ho-tich/credentials` {kind `CLIENT_CREDENTIALS`}.
2. Lấy token từ Keycloak bằng `clientId`, `clientSecret` vừa nhận.
3. `GET /apps/app-tra-cuu-ho-tich/credentials`.

**Kết quả mong đợi.** `201` trả `clientId = sbx-t68-app-tra-cuu-ho-tich-1` và `clientSecret` một lần; client tồn tại ở realm `dh-dev`, token lấy được, hạn ≤ 180 ngày; EVT-15-03; KT: có (`SECRET_ISSUED`); bước 3 chỉ có tiền tố 8 ký tự, trạng thái, hạn, không có bí mật; p95 ≤ 3 giây.
:::

#### TC-15-088 · Cấp theo private_key_jwt không có bí mật <!--k:cred-pkjwt-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-027 · API-15-062 · BR-15-011 · LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** Cặp khóa thử, JWKS công khai.

**Các bước.**

1. `POST .../credentials` với `authMethod = private_key_jwt` và `jwks`.

**Kết quả mong đợi.** `201` chỉ có `clientId`, không có bí mật để hiện; Keycloak ghi khóa công khai; lấy token bằng chứng thực khóa thành công.
:::

#### TC-15-089 · Cấp API key sandbox <!--k:cred-apikey-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-028 · UC-15-15 · API-15-062 · BR-15-011 · LGC-APIM-011.

**Tiền điều kiện, dữ liệu.** Ứng dụng ACTIVE của An.

**Các bước.**

1. `POST .../credentials` {kind `API_KEY`}.
2. Gọi sandbox bằng `X-API-Key`.
3. Kiểm CSDL `ph15_portal.app_credential`.

**Kết quả mong đợi.** Khóa `dhsk_t68_…` hiện một lần; gọi sandbox `200`; CSDL chỉ có tiền tố 8 ký tự và băm, không có khóa; EVT-15-03.
:::

#### TC-15-090 · Bí mật không xem lại được <!--k:secret-once-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-029 · UC-15-15 · API-15-061, 062 · UI-15-13 · ERR-15-019 · BR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Credential vừa cấp; `Idempotency-Key` K2.

**Các bước.**

1. Đóng hộp thoại bí mật, nạp lại UI-15-13, `GET .../credentials`.
2. Phát lại `POST` cấp với K2.

**Kết quả mong đợi.** Không có bí mật ở bước 1 (tiền tố thôi); bước 2 `410` ERR-15-019 "Bí mật chỉ hiện một lần..."; hộp thoại bí mật có nút sao chép, tải xuống, yêu cầu xác nhận "Tôi đã lưu"; phản hồi `Cache-Control: no-store`.
:::

#### TC-15-091 · Vượt giới hạn, ứng dụng không ACTIVE, thiếu quyền, Keycloak lỗi <!--k:cred-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-15-027, 028 · API-15-062 · ERR-15-005, 016, 017, 020 · BR-15-010 · LGC-APIM-011; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** `15.cred.max-per-app = 3`; ứng dụng có 3 credential; ứng dụng SUSPENDED; Bi VIEWER; Keycloak ngắt.

**Các bước.**

1. Cấp credential thứ 4.
2. Cấp ở ứng dụng SUSPENDED.
3. Bi cấp.
4. Cấp khi Keycloak ngắt.

**Kết quả mong đợi.** `422` ERR-15-016; `409` ERR-15-017; `403` ERR-15-005; `503` ERR-15-020, không có bản ghi credential nào được tạo.
:::

#### TC-15-092 · Sập giữa pha cấp: không credential mồ côi <!--k:cred-saga-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-15-027 · UC-15-15 · EVT-15-03 · BR-15-011 · LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** Chaos Mesh giết pod `api` sau khi tạo client Keycloak, trước khi ghi CSDL.

**Các bước.**

1. Bắt đầu cấp; giết pod; chờ đối soát.

**Kết quả mong đợi.** Không có client Keycloak `sbx-…` nào không có bản ghi ở cổng sau chu kỳ đối soát; không bí mật nào được trả cho người dùng; người dùng thử lại được.
:::

### TS-15-15 · Xoay vòng, thu hồi, hết hạn thông tin xác thực

**Mục tiêu.** Xác nhận xoay có thời gian chuyển tiếp, thu hồi và hết hạn có hiệu lực ở forward-auth trong 60 giây, và mọi sai trạng thái bị chặn.

**Phủ.** FR-15-030, 031; UC-15-16; API-15-063, 064, 082; UI-15-13; EVT-15-04, 05; ERR-15-018, 020; BR-15-011; NFR-15-007, 020; LGC-IAM-006.

#### TC-15-093 · Xoay có thời gian chuyển tiếp <!--k:rotate-grace-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-15-030 · UC-15-16 · API-15-063, 082 · UI-15-13 · EVT-15-04 · BR-15-011 · NFR-15-020 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Credential C1 ACTIVE; `graceHours = 24`; đồng hồ giả lập.

**Các bước.**

1. `POST /apps/app-tra-cuu-ho-tich/credentials/{C1}:rotate`.
2. Gọi sandbox bằng bí mật cũ và mới.
3. Đẩy đồng hồ +25 giờ; gọi bằng bí mật cũ.

**Kết quả mong đợi.** C1 `ROTATING`, bản mới `ACTIVE` với bí mật hiện một lần; bước 2 cả hai `200`, chỉ số `dh_portal_cred_old_use_total` tăng khi dùng bí mật cũ; bước 3 `401` (C1 `EXPIRED`); EVT-15-04 và EVT-15-05 (hết hạn); KT: có.
:::

#### TC-15-094 · Xoay và thu hồi bản cũ ngay <!--k:rotate-now-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-030 · API-15-063 · EVT-15-05 · NFR-15-007 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Credential C2 ACTIVE.

**Các bước.**

1. `:rotate` với `graceHours = 0`.
2. Gọi sandbox bằng bí mật cũ trong 60 giây.

**Kết quả mong đợi.** C2 chuyển thẳng `REVOKED`; bí mật cũ bị chặn ≤ 60 giây (≤ 5 giây khi nhận EVT-15-05).
:::

#### TC-15-095 · Xoay sai trạng thái, Keycloak lỗi <!--k:rotate-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, Chaos.

**Truy vết.** FR-15-030 · API-15-063 · ERR-15-018, 020, 003 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** C3 REVOKED; C4 ACTIVE khi ngắt Keycloak.

**Các bước.**

1. `:rotate` C3; `graceHours = 73`.
2. `:rotate` C4.

**Kết quả mong đợi.** `409` ERR-15-018 "Thông tin xác thực đang REVOKED..."; `400` ERR-15-003; `503` ERR-15-020, C4 vẫn `ACTIVE`, không có bản mới.
:::

#### TC-15-096 · Thu hồi chặn lời gọi trong 60 giây <!--k:revoke-effect-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-15-031 · UC-15-16 · API-15-064, 082 · EVT-15-05 · NFR-15-007 · BR-15-010 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Credential ACTIVE; vòng gọi sandbox liên tục 5 lần/giây; bộ đệm `forward-auth` 60 giây.

**Các bước.**

1. `POST .../credentials/{id}:revoke`.
2. Ghi thời điểm lời gọi đầu tiên bị từ chối.

**Kết quả mong đợi.** `REVOKED`; EVT-15-05 tới PH-03, PH-13; mọi lời gọi sau ≤ 60 giây (≤ 5 giây với EVT) bị `401` ở gateway; KT: có; sau khi Keycloak lỗi lúc xóa client, cổng vẫn đánh dấu `REVOKED` và thử lại xóa client.
:::

#### TC-15-097 · Thu hồi lại, thu hồi không có quyền <!--k:revoke-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-031 · API-15-064 · ERR-15-005, 018 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Credential đã REVOKED; Bi `VIEWER`.

**Các bước.**

1. `:revoke` lần hai.
2. Bi `:revoke` credential ACTIVE.

**Kết quả mong đợi.** `409` ERR-15-018; `403` ERR-15-005; không đổi dữ liệu.
:::

#### TC-15-098 · Nhắc hạn 30, 7, 1 ngày và hết hạn <!--k:cred-expiry-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-15-031 · UC-15-16 · EVT-15-05 · BR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.cred.ttl-days = 90`, `15.cred.expiry-notice-days = [30,7,1]`; đồng hồ giả lập; yêu cầu `ttlDays = 181`.

**Các bước.**

1. Cấp credential; đẩy đồng hồ qua ngày 60, 83, 89, 91.
2. Cấp với `ttlDays = 181`.

**Kết quả mong đợi.** Ba thông báo (hộp thư và thư điện tử) tại 30, 7, 1 ngày trước; ngày 91 `EXPIRED`, EVT-15-05 `reason` hết hạn, gọi sandbox `401`; `ttlDays = 181` bị `400` ERR-15-003.
:::

### TS-15-16 · Tham chiếu thông tin xác thực production

**Mục tiêu.** Xác nhận chỉ cán bộ thuộc tổ chức của HTTT thấy tham chiếu (không bí mật), nhà thầu và người ngoài bị chặn.

**Phủ.** FR-15-032; UC-15-17; API-15-065; UI-15-13; ERR-15-005, 031; BR-15-004, 015.

#### TC-15-099 · Xem tham chiếu production <!--k:prodref-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-032 · UC-15-17 · API-15-065 · UI-15-13 · BR-15-015 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-OR được giao ứng dụng `app-dat-dai` của HT-DATDAI; S-PH01 trả chứng thư `tls_client_auth`.

**Các bước.**

1. `GET /apps/app-dat-dai/prod-credentials`.

**Kết quả mong đợi.** `systemCode`, `clientId`, `authMethod`, 16 ký tự đầu dấu vân tay, hạn, trạng thái `ACTIVE` hoặc `EXPIRING`; không có bí mật hay khóa riêng; ghi chú bí mật production do PH-01, PH-12 cấp riêng.
:::

#### TC-15-100 · Nhà thầu và người ngoài tổ chức bị chặn <!--k:prodref-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-032 · UC-15-17 · API-15-065 · ERR-15-005 · BR-15-004, 015 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN (nhà thầu, thành viên ứng dụng); cán bộ HT-TUPHAP; DH-CANARY ở khóa riêng của S-PH01.

**Các bước.**

1. An và cán bộ HT-TUPHAP gọi `GET /apps/app-dat-dai/prod-credentials`.
2. Tìm canary trong phản hồi Bình.

**Kết quả mong đợi.** Cả hai `403` ERR-15-005; không có canary ở phản hồi thành công của Bình.
:::

#### TC-15-101 · PH-01 lỗi <!--k:prodref-ph01-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-032 · API-15-065 · ERR-15-031 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** S-PH01 trả `503`.

**Các bước.**

1. `GET /apps/app-dat-dai/prod-credentials` bằng Bình.

**Kết quả mong đợi.** `502` ERR-15-031; UI "Chưa tải được thông tin xác thực production. Thử lại sau."
:::

### TS-15-17 · Khai báo sandbox của dịch vụ

**Mục tiêu.** Xác nhận chủ dịch vụ khai báo MOCK, BACKEND, và các chặn SSRF, ngoài allowlist.

**Phủ.** FR-15-034; UC-15-18; API-15-069, 070; UI-15-23; ERR-15-005, 040, 101, 119, 120; BR-15-017, 018.

#### TC-15-102 · Khai báo MOCK và BACKEND <!--k:sbxprof-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-034 · UC-15-18 · API-15-069, 070 · UI-15-23 · ERR-15-101 · BR-15-017, 018 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV (chủ dịch vụ HT-TUPHAP); egress cho phép `sim-backend.sim.test`.

**Các bước.**

1. `PUT /catalog/apis/tra-cuu-ho-tich/sandbox` {versionNo `1.0.0`, mode `MOCK`, examplePolicy `FIRST`}.
2. `PUT /catalog/apis/dm-hanh-chinh/sandbox` {mode `BACKEND`, backendUrl `https://sim-backend.sim.test/dmhc`}.
3. `GET` cả hai.

**Kết quả mong đợi.** `200`, có `ETag`; hồ sơ trả đúng; chế độ OFF cho `POST /try/requests` trả `422` ERR-15-101.
:::

#### TC-15-103 · Backend ngoài allowlist, thiếu cấu hình, phiên bản ngừng, không phải chủ <!--k:sbxprof-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-034 · UC-15-18 · API-15-070 · ERR-15-005, 040, 119, 120 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV, U-T68-OR; `ban-do-cu` RETIRED.

**Các bước.**

1. `backendUrl` `https://evil.test/`, `http://sim-backend.sim.test`, `https://10.0.0.5/`.
2. `mode = BACKEND` thiếu `backendUrl`.
3. Cấu hình `ban-do-cu`.
4. Bình cấu hình `tra-cuu-ho-tich`.

**Kết quả mong đợi.** `422` ERR-15-119; `409` ERR-15-120 "Chế độ BACKEND cần khai báo backendUrl"; `422` ERR-15-040; `403` ERR-15-005.
:::

#### TC-15-104 · Chặn SSRF ở khai báo và lúc gọi <!--k:sbxprof-ssrf-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, ZAP.

**Truy vết.** FR-15-034, 037 · API-15-070, 072 · ERR-15-119 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Địa chỉ `https://localhost/`, `https://169.254.169.254/`, `https://[::1]/`, tên DNS trỏ `10.0.0.5`, URL 302 sang địa chỉ nội bộ.

**Các bước.**

1. Khai báo từng địa chỉ.
2. Với tên DNS đổi trỏ sau khi khai báo (rebinding), thử API.

**Kết quả mong đợi.** Tất cả bị từ chối `422` ERR-15-119; địa chỉ được kiểm lại ở lúc gọi; không theo chuyển hướng ra ngoài allowlist; không có kết nối nào tới mạng nội bộ (đếm ở WireMock nội bộ bằng 0).
:::

### TS-15-18 · Thử API ở sandbox MOCK

**Mục tiêu.** Xác nhận khung thử gọi qua APISIX sandbox, phản hồi MOCK sinh từ ví dụ, lược đồ, và đủ các chặn trước khi gọi.

**Phủ.** FR-15-035, 036; UC-15-19; API-15-071…074, 082; UI-15-06; EVT-15-11; ERR-15-005, 010, 102, 107, 110, 111, 116, 121, 122; BR-15-016, 017, 023, 024, 026.

#### TC-15-105 · Thử một thao tác ở chế độ MOCK <!--k:try-mock-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-035, 036 · UC-15-19 · API-15-072, 073 · UI-15-06 · EVT-15-11 · BR-15-017, 026 · NFR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; `app-tra-cuu-ho-tich` có credential; hồ sơ MOCK `FIRST` của `tra-cuu-ho-tich`.

**Các bước.**

1. `POST /try/requests` {appCode, apiCode, versionNo `1.0.0`, operation `getHoTich`, params `{id: "000123456789"}`}.
2. `GET /try/requests/{tryId}`.
3. Lặp với tiêu đề `X-DH-Mock-Status: 404`.

**Kết quả mong đợi.** `200`, phản hồi sinh từ ví dụ đầu của đặc tả, tiêu đề `X-DH-Sandbox: mock`, `X-DH-Try-Id`, `traceparent`; bước 3 trả phản hồi mẫu 404; EVT-15-11 `env = SANDBOX`, `result = OK`, không có thân; KT: có (`TRY_API`); gateway không gọi hệ thống nào (đếm WireMock bằng 0).
:::

#### TC-15-106 · Sinh từ lược đồ khi thiếu ví dụ <!--k:try-mock-schema-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-036 · API-15-072 · BR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Thao tác `listHoTich` có lược đồ (enum, định dạng ngày) nhưng không có ví dụ; `examplePolicy = RANDOM`.

**Các bước.**

1. Gọi hai lần liên tiếp.

**Kết quả mong đợi.** Phản hồi hợp lệ theo lược đồ (kiểu, enum, định dạng); hai lần có thể khác nhau; dữ liệu sinh thuộc dải giả (xem TC-15-117).
:::

#### TC-15-107 · Không sinh được, không khớp đặc tả, phiên bản không cho thử <!--k:try-mock-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-035, 036 · UC-15-19 · API-15-071, 072 · ERR-15-107, 110, 122 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Thao tác `exportHoTich` không có ví dụ lẫn lược đồ; thiếu tham số bắt buộc `id`; phiên bản SUSPENDED.

**Các bước.**

1. Thử `exportHoTich`.
2. Thử `getHoTich` thiếu `id`; gọi `POST /try/requests:validate`.
3. Thử phiên bản SUSPENDED.

**Kết quả mong đợi.** `422` ERR-15-110; `422` ERR-15-107 nêu chi tiết tham số, `validate` báo cùng lỗi và không tính hạn mức; `403` ERR-15-122.
:::

#### TC-15-108 · Ứng dụng, thành viên, điều khoản <!--k:try-eligible-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-035 · UC-15-19 · API-15-072 · ERR-15-005, 010, 102 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ứng dụng SUSPENDED; ứng dụng không credential; ứng dụng của An (Cự không thuộc); Bi chưa chấp nhận điều khoản; VIEWER.

**Các bước.**

1. Mỗi trường hợp gọi `POST /try/requests`.

**Kết quả mong đợi.** `403` ERR-15-102 (hai ứng dụng đầu); `403` ERR-15-005 (Cự, VIEWER); `409` ERR-15-010 (Bi); không lượt thử nào được tính hạn mức.
:::

#### TC-15-109 · Tiêu đề cấm, phương thức cấm, cổng sandbox hỏng <!--k:try-header-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-15-035 · API-15-072 · ERR-15-111, 116, 121 · BR-15-026 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; yêu cầu thử có `Authorization`, `Cookie`, `Host`; phương thức `TRACE`; ngắt APISIX sandbox.

**Các bước.**

1. Gửi từng tiêu đề cấm.
2. Thử `TRACE`.
3. Thử hợp lệ khi gateway ngắt.

**Kết quả mong đợi.** `422` ERR-15-121 "Tiêu đề Authorization không được phép gửi."; `422` ERR-15-116; `503` ERR-15-111 "Cổng thử đang bảo trì. Thử lại sau."
:::

#### TC-15-110 · Gọi trực tiếp qua tên miền sandbox dùng chung hạn mức <!--k:try-direct-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-035, 039 · API-15-082 · ERR-15-103 · BR-15-025 · LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** `15.try.rate-per-user-min = 5`; U-T68-DEV-AN; token client `sbx-t68-…-1`.

**Các bước.**

1. 3 lượt thử qua cổng.
2. 3 lượt gọi trực tiếp `https://sandbox-api.t68.datahub.gov.vn/...` với token.

**Kết quả mong đợi.** Lượt thứ 6 nhận `429` (cùng bộ đếm); lời gọi hợp lệ `200` có `X-DH-Sandbox: mock`.
:::

#### TC-15-111 · MOCK cảnh báo (không chặn) dữ liệu giống DLCN <!--k:try-mock-warn-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-036, 038 · API-15-071, 072 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Thân giống số căn cước `079123456789`.

**Các bước.**

1. `POST /try/requests` chế độ MOCK.

**Kết quả mong đợi.** `200` kèm `warnings[]` về PII-15-01; giá trị khớp không có ở bản ghi lượt thử, log, vết (tìm `079123456789` = 0).
:::

### TS-15-19 · Thử BACKEND, chặn dữ liệu cá nhân, hạn mức

**Mục tiêu.** Xác nhận chế độ BACKEND an toàn, chặn mọi mẫu DLCN thật, dữ liệu mẫu tổng hợp trong dải giả, và các hạn mức.

**Phủ.** FR-15-037, 038, 039; UC-15-19; API-15-071, 072, 074; UI-15-06; ERR-15-103…109, 119, 123; BR-15-016, 018, 025.

#### TC-15-112 · Thử qua backend của chủ dịch vụ <!--k:try-backend-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-15-037 · UC-15-19 · API-15-072 · UI-15-06 · BR-15-018, 026 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `dm-hanh-chinh` BACKEND tới `sim-backend.sim.test` (WireMock); U-T68-DEV-AN.

**Các bước.**

1. `POST /try/requests` `getTinh`.
2. Xem yêu cầu WireMock nhận được.

**Kết quả mong đợi.** `200`, `X-DH-Sandbox: backend`; backend nhận `X-DH-Try-Id`, `traceparent`, không nhận `Authorization`, `Cookie` của người dùng; chỉ gửi tới host đã khai báo.
:::

#### TC-15-113 · Backend lỗi, chậm, ngắt mạch <!--k:try-backend-fail-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-15-037 · UC-15-19 · API-15-072 · ERR-15-108, 109 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.try.timeout-seconds = 5`; WireMock trả `500`, rồi chậm 8 giây.

**Các bước.**

1. Thử khi backend `500`.
2. Thử khi backend chậm.
3. Gây 5 lỗi trong 30 giây rồi thử tiếp.

**Kết quả mong đợi.** `502` ERR-15-109 (kết quả `UPSTREAM_ERROR`); `504` ERR-15-108 "Hệ thống thử không phản hồi trong 5 giây." (`TIMEOUT`); sau 5 lỗi mạch mở: lượt kế `502` ERR-15-109 ngay, WireMock không nhận lời gọi; mạch đóng lại sau thời gian chờ.
:::

#### TC-15-114 · Kiểm lại allowlist egress lúc gọi <!--k:try-egress-recheck-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-15-037 · API-15-072 · ERR-15-119 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Hồ sơ BACKEND đã lưu; gỡ `sim-backend.sim.test` khỏi danh sách egress tenant.

**Các bước.**

1. Thử API.

**Kết quả mong đợi.** `422` ERR-15-119, không có kết nối ra backend.
:::

#### TC-15-115 · BACKEND chặn đủ sáu mẫu DLCN <!--k:pii-block-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** FR-15-038 · UC-15-19 · API-15-071, 072 · UI-15-06 · ERR-15-106 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Sáu giá trị F-PII: CCCD `079123456789`, CMND `123456789`, mã số thuế `0312345678`, điện thoại `0912345678`, thư `a@gmail.com`, hộ chiếu `B1234567`; chế độ BACKEND; WireMock đếm lời gọi.

**Các bước.**

1. Gửi mỗi giá trị ở thân, tham số đường dẫn, truy vấn, tiêu đề tùy chọn.

**Kết quả mong đợi.** Mọi lần `422` ERR-15-106 "Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."; backend nhận 0 lời gọi; giá trị khớp không có ở `try_run`, log, vết, kiểm toán, EVT-15-11 (tìm 0 lần).
:::

#### TC-15-116 · Dải giả được phép <!--k:pii-fake-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-038 · UC-15-19 · API-15-072 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `000123456789`, `000123456`, `0000123456`, `0900000123`, `x@example.gov.vn`, `X00123456`; BACKEND.

**Các bước.**

1. Gửi mỗi giá trị.

**Kết quả mong đợi.** Tất cả `200`, không bị chặn nhầm.
:::

#### TC-15-117 · Dữ liệu mẫu tổng hợp nằm trong dải giả <!--k:synthetic-data-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** UT.

**Truy vết.** FR-15-036, 038 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `SchemaDataGenerator` với lược đồ có các trường `cccd`, `soDienThoai`, `email`, `maSoThue`, `hoChieu`; 1.000 lượt sinh.

**Các bước.**

1. Sinh 1.000 phản hồi MOCK.
2. Quét bằng bộ luật PII-15-01…06.

**Kết quả mong đợi.** Mọi giá trị khớp mẫu đều thuộc dải giả (bắt đầu `000`, `0900000`, `@example.gov.vn`, `X00`); 0 giá trị khớp mẫu ngoài dải.
:::

#### TC-15-118 · Hạn mức theo người và Retry-After <!--k:quota-user-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-039 · UC-15-19 · API-15-072, 074 · ERR-15-103 · BR-15-025 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.try.rate-per-user-min = 5`; U-T68-DEV-AN.

**Các bước.**

1. 6 lượt thử trong 1 phút; `GET /try/quota`.
2. Chờ qua phút kế.

**Kết quả mong đợi.** Lượt 6 `429` ERR-15-103 kèm `Retry-After`; `quota` còn 0; sau phút kế `200`; lượt `THROTTLED` có EVT-15-11 và tăng `dh_portal_try_throttled_total`.
:::

#### TC-15-119 · Hạn mức ngày theo ứng dụng, cỡ thân, phản hồi quá cỡ <!--k:quota-app-body-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-039 · API-15-072 · ERR-15-104, 105, 123 · BR-15-025 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.try.rate-per-app-day = 100`; thân 257 KB (> 256 KB); backend trả 2 MB.

**Các bước.**

1. 101 lượt thử trong ngày (nhiều người dùng).
2. Gửi thân 257 KB.
3. Thử khi backend trả 2 MB.

**Kết quả mong đợi.** Lượt 101 `429` ERR-15-104 "Hạn mức làm mới lúc 00:00"; `413` ERR-15-105; phản hồi bị cắt ở 1 MB kèm cờ ERR-15-123, không lưu thân.
:::

### TS-15-20 · Lịch sử thử, bộ sưu tập, xuất

**Mục tiêu.** Xác nhận lịch sử không lưu thân hay bí mật, bộ sưu tập là của riêng mỗi người và xuất ra công cụ ngoài không lộ bí mật.

**Phủ.** FR-15-040, 041; UC-15-20; API-15-075…081; UI-15-14; ERR-15-001, 003; BR-15-024.

#### TC-15-120 · Lịch sử thử và giữ 30 ngày <!--k:history-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-15-040 · UC-15-20 · API-15-075, 076 · UI-15-14 · BR-15-024 · NFR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An đã thử 5 lượt; đồng hồ +31 ngày.

**Các bước.**

1. `GET /try/history`.
2. `DELETE /try/history`; làm lại, đẩy đồng hồ 31 ngày.

**Kết quả mong đợi.** Có tryId, thao tác, môi trường, kết quả, độ trễ, `traceId`; không có thân yêu cầu, phản hồi, tiêu đề xác thực; bước 2 xóa sạch; quá 30 ngày bản ghi tự mất.
:::

#### TC-15-121 · Bộ sưu tập yêu cầu <!--k:coll-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-040 · UC-15-20 · API-15-077, 078, 079, 080 · UI-15-14 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An; yêu cầu mẫu có tiêu đề `Authorization`.

**Các bước.**

1. Tạo bộ sưu tập 3 yêu cầu; sửa; xóa.

**Kết quả mong đợi.** Yêu cầu lưu ≤ 16 KB; tiêu đề `Authorization`, `Cookie` bị loại khi lưu; chỉ An thấy.
:::

#### TC-15-122 · Vượt bộ, vượt cỡ, bộ của người khác <!--k:coll-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-040 · API-15-077, 078, 079 · ERR-15-001, 003 · NFR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An đã có 50 bộ; Cự; bộ thứ 51; bộ với 101 yêu cầu.

**Các bước.**

1. An tạo bộ thứ 51; `PUT` bộ có 101 yêu cầu.
2. Cự `GET`, `PUT`, `DELETE`, xuất bộ của An; `GET /try/requests/{tryId của An}`.

**Kết quả mong đợi.** `400` ERR-15-003 "Đã đạt số bộ sưu tập tối đa"; Cự `404` ERR-15-001 ở mọi đường, dữ liệu của An không đổi.
:::

#### TC-15-123 · Xuất Postman, Bruno, HTTP không lộ bí mật <!--k:coll-export-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-15-041 · UC-15-20 · API-15-081 · UI-15-14 · BR-15-011 · ERR-15-003 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Bộ sưu tập có yêu cầu dùng credential; DH-CANARY ở thông tin xác thực.

**Các bước.**

1. `GET /try/collections/{id}/export?dinh-dang=postman|bruno|http`.
2. `dinh-dang=curl`.

**Kết quả mong đợi.** Ba tệp nhập được và chạy được bằng Newman, Bruno CLI, REST Client; dùng biến `{{clientSecret}}` thay giá trị; 0 canary; `400` ERR-15-003 cho định dạng ngoài danh sách.
:::

### TS-15-21 · Bật, tắt thử production theo dịch vụ

**Mục tiêu.** Xác nhận thử production mặc định tắt, bật theo bốn mắt, có thời hạn và chỉ cho API đủ điều kiện.

**Phủ.** FR-15-042; UC-15-21; API-15-083…086; UI-15-23; EVT-15-10; ERR-15-003, 023, 040; BR-15-019…021.

#### TC-15-124 · Mặc định tắt <!--k:prodtry-default-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-042 · UC-15-21 · API-15-083 · ERR-15-112 · BR-15-019 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.try.prod-enabled` mặc định (`false`); U-T68-CA.

**Các bước.**

1. `GET /admin/try-production`.
2. Bình (đăng ký ACTIVE) `POST /try/requests` môi trường PRODUCTION.

**Kết quả mong đợi.** Mọi dịch vụ `OFF`; bước 2 `403` ERR-15-112 "Dịch vụ này chưa bật thử trên môi trường thật.".
:::

#### TC-15-125 · Đề xuất và duyệt bốn mắt, có thời hạn <!--k:prodtry-enable-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-042 · UC-15-21 · API-15-084, 085 · UI-15-23 · EVT-15-10 · BR-15-019, 021 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `15.try.prod-enabled = true`; `thoi-tiet-cong-khai` (PUBLIC); U-T68-SV đề xuất, U-T68-CA duyệt.

**Các bước.**

1. SV `PUT /admin/try-production/thoi-tiet-cong-khai` {lý do, hạn 30 ngày, `allowWrite = false`}.
2. CA `:approve`.

**Kết quả mong đợi.** `PENDING` rồi `ENABLED` kèm `expiresAt`; EVT-15-10 hai lần; KT: có; sau hạn tự `EXPIRED` (tác vụ hằng giờ).
:::

#### TC-15-126 · Tự duyệt, API không đủ điều kiện, thiếu lý do, quá hạn tối đa <!--k:prodtry-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-042 · API-15-084, 085 · ERR-15-003, 023, 040 · BR-15-020, 021 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `bao-cao-noi-bo` (RESTRICTED), `tra-cuu-dat-dai` (SENSITIVE); tenant tắt công tắc; hạn 91 ngày.

**Các bước.**

1. SV tự `:approve`.
2. Đề xuất cho hai API RESTRICTED, SENSITIVE.
3. Đề xuất khi `15.try.prod-enabled = false`.
4. Đề xuất không lý do; hạn 91 ngày.

**Kết quả mong đợi.** `403` ERR-15-023; `422` ERR-15-040 ở bước 2, 3; `400` ERR-15-003 ở bước 4.
:::

#### TC-15-127 · Tắt bằng một người có quyền <!--k:prodtry-disable-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-042 · API-15-086 · EVT-15-10 · ERR-15-112 · BR-15-021 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Dịch vụ ENABLED; Hà (TA).

**Các bước.**

1. `POST /admin/try-production/thoi-tiet-cong-khai:disable`.
2. Bình thử production.

**Kết quả mong đợi.** `OFF`, EVT-15-10, KT: có; bước 2 `403` ERR-15-112 ngay.
:::

### TS-15-22 · Thử API trên production

**Mục tiêu.** Xác nhận thử production chỉ cho cán bộ có đăng ký ACTIVE, chỉ GET/HEAD, API không nhạy cảm, và đóng an toàn khi kiểm toán lỗi.

**Phủ.** FR-15-043; UC-15-22; API-15-072; UI-15-06; EVT-15-11; ERR-15-112…118; BR-15-019…024, 033.

#### TC-15-128 · Thử GET ở production bằng token trao đổi <!--k:prodtry-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-043 · UC-15-22 · API-15-072 · UI-15-06 · EVT-15-11 · BR-15-022, 024 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `thoi-tiet-cong-khai` ENABLED; U-T68-OR (HT-DATDAI có đăng ký ACTIVE); APISIX production giả lập.

**Các bước.**

1. Bình mở UI-15-06 (banner "Môi trường thật"), chọn môi trường production, gửi GET.

**Kết quả mong đợi.** `200`; token trao đổi sống 5 phút, `act` là Bình (và mã HTTT), `aud` và scope thu hẹp theo đăng ký, không đệm; EVT-15-11 `env = PRODUCTION`; KT: có (`TRY_PRODUCTION`); không lưu thân phản hồi; `X-DH-Try-Id`, `traceparent` có ở gateway.
:::

#### TC-15-129 · Không có đăng ký sử dụng ACTIVE <!--k:prodtry-no-sub-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-043 · UC-15-22 · API-15-072 · ERR-15-113 · BR-15-004, 022 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Đăng ký PENDING, đăng ký đã hết hạn, không đăng ký; U-T68-DEV-AN (nhà thầu).

**Các bước.**

1. Bình thử khi đăng ký PENDING; khi hết hạn.
2. An thử production.

**Kết quả mong đợi.** `403` ERR-15-113 "Tổ chức của bạn chưa có đăng ký sử dụng đang hoạt động cho dịch vụ này."; An `403` ERR-15-113 (giả định, Q15-42); không lời gọi tới gateway production.
:::

#### TC-15-130 · Dataclass đổi sang nhạy cảm sau khi bật <!--k:prodtry-sensitive-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-043 · API-15-072 · ERR-15-114 · BR-15-020 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `thoi-tiet-cong-khai` ENABLED; S-PH02 đổi `dataClass = SENSITIVE` (EVT-02-02).

**Các bước.**

1. Chờ đồng bộ; Bình thử production.

**Kết quả mong đợi.** `403` ERR-15-114 "Dịch vụ có dữ liệu nhạy cảm không cho thử trên môi trường thật."; trạng thái thử production tự về `OFF`.
:::

#### TC-15-131 · Chỉ GET và HEAD <!--k:prodtry-method-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-043 · API-15-072 · ERR-15-116 · BR-15-020 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `allowWrite = false`; mọi API ENABLED.

**Các bước.**

1. Thử `POST`, `PUT`, `PATCH`, `DELETE`; thử `GET`, `HEAD`.

**Kết quả mong đợi.** Bốn phương thức ghi `422` ERR-15-116 "Chỉ được thử phương thức GET và HEAD trên production"; `GET`, `HEAD` `200`.
:::

#### TC-15-132 · PH-13 lỗi thì từ chối thử production <!--k:prodtry-audit-fail-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos, API.

**Truy vết.** FR-15-043 · UC-15-22 · API-15-072 · ERR-15-115 · BR-15-023 · NFR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt PH-13 (kiểm toán đồng bộ); Bình; APISIX production đếm lời gọi.

**Các bước.**

1. Thử production.
2. Khôi phục PH-13; thử lại.

**Kết quả mong đợi.** `503` ERR-15-115 "Chưa ghi được nhật ký nên không thử được lúc này."; gateway production nhận 0 lời gọi, không phát token trao đổi; sau khôi phục `200` và có bản ghi kiểm toán.
:::

#### TC-15-133 · PH-13 lỗi ở sandbox: nhạy cảm thì chặn, còn lại ghi qua outbox <!--k:sbxtry-audit-fail-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos, API.

**Truy vết.** FR-15-035 · UC-15-19 · API-15-072 · ERR-15-115 · BR-15-023 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt PH-13; API `tra-cuu-ho-tich` (INTERNAL), `bao-cao-noi-bo` (RESTRICTED) có hồ sơ MOCK; An.

**Các bước.**

1. Thử `tra-cuu-ho-tich`.
2. Thử `bao-cao-noi-bo`.
3. Khôi phục PH-13.

**Kết quả mong đợi.** Bước 1 `200`, bản ghi kiểm toán nằm trong outbox; bước 2 `503` ERR-15-115; sau bước 3 outbox đẩy bù đủ bản ghi, không trùng.
:::

#### TC-15-134 · Token exchange lỗi, hạn mức production <!--k:prodtry-exchange-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, Chaos.

**Truy vết.** FR-15-043 · API-15-072 · ERR-15-117, 118 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt token exchange Keycloak; `15.try.prod-rate-per-user-min = 1`.

**Các bước.**

1. Thử production khi Keycloak lỗi.
2. Thử 2 lượt trong 1 phút khi Keycloak tốt.

**Kết quả mong đợi.** `502` ERR-15-117; lượt 2 `429` ERR-15-118.
:::

#### TC-15-135 · Danh mục quá 24 giờ ẩn thử production <!--k:prodtry-stale-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-15-043 · UI-15-06 · ERR-15-112 · BR-15-033 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt PH-02, đồng hồ +25 giờ.

**Các bước.**

1. Mở UI-15-06 và gọi API thử production.

**Kết quả mong đợi.** Nút thử production bị ẩn; API `403` ERR-15-112 (giả định, Q15-43); sandbox vẫn thử được.
:::

### TS-15-23 · Đăng ký sử dụng, kết nạp, công bố (ủy thác)

**Mục tiêu.** Xác nhận cổng chỉ ủy thác nhân danh người dùng, không tự duyệt, không giữ bản sao quyết định, và chỉ đầu mối thao tác.

**Phủ.** FR-15-044…047; UC-15-23, 24, 25; API-15-087…096; UI-15-15, 16, 17; ERR-15-005, 030, 031, 032; BR-15-001, 014, 015.

#### TC-15-136 · Gửi đăng ký sử dụng nhân danh đầu mối <!--k:sub-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-044 · UC-15-23 · API-15-087, 089 · UI-15-15 · BR-15-014 · LGC-APIM-016.

**Tiền điều kiện, dữ liệu.** U-T68-OR (đầu mối HT-DATDAI); S-PH02.

**Các bước.**

1. UI-15-15: chọn `tra-cuu-ho-tich`, `HT-DATDAI`, gói, mục đích; gửi.
2. `GET /subscriptions/{id}`.

**Kết quả mong đợi.** `PENDING`; S-PH02 nhận bằng danh tính Bình (không dùng danh tính dịch vụ); KT: có (`SUBMIT_SUBSCRIPTION`); chi tiết đọc từ PH-02, cổng không lưu quyết định.
:::

#### TC-15-137 · Không phải đầu mối, nhà thầu, PH-02 lỗi <!--k:sub-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-044, 045 · UC-15-23 · API-15-087, 088 · ERR-15-030, 032 · LGC-APIM-016.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; cán bộ không phải đầu mối; S-PH02 trả `ERR-02-*` nghiệp vụ; ngắt PH-02.

**Các bước.**

1. An gửi; cán bộ thường gửi.
2. Gửi khi PH-02 trả lỗi nghiệp vụ.
3. Gửi khi PH-02 ngắt.

**Kết quả mong đợi.** `422` ERR-15-032; mã `ERR-02-*` và câu của PH-02 chuyển nguyên văn; `502` ERR-15-030 "Chưa kết nối được dịch vụ danh mục."
:::

#### TC-15-138 · Theo dõi, hủy, không tự duyệt <!--k:sub-track-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-045 · UC-15-23 · API-15-088, 089, 090 · BR-15-014 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Đăng ký PENDING của HT-DATDAI; đăng ký của HT-TUPHAP; Bình.

**Các bước.**

1. `GET /subscriptions`; chi tiết; `:cancel`.
2. Bình `GET` đăng ký của HT-TUPHAP; `POST /subscriptions/{id}:approve`.

**Kết quả mong đợi.** Danh sách chỉ của tổ chức Bình; hủy được khi PENDING (hủy khi không còn PENDING chuyển lỗi PH-02 nguyên văn); bước 2 `404` ERR-15-001 và `404` cho đường không tồn tại; cổng không có đường duyệt.
:::

#### TC-15-139 · Nộp hồ sơ kết nạp F-01 <!--k:onboard-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-046 · UC-15-24 · API-15-091, 092, 093 · UI-15-16 · BR-15-014, 015 · LGC-APIM-019; LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** Bình (đầu mối); S-PH01 trả lỗi theo trường ở lần đầu.

**Các bước.**

1. Gửi hồ sơ thiếu trường; sửa; gửi lại.
2. `GET /onboarding/applications/{id}`.

**Kết quả mong đợi.** Lỗi theo trường của PH-01 hiện dưới từng trường; thành công tạo hồ sơ ở PH-01, theo dõi được; không có bí mật production ở bất cứ phản hồi nào; KT: có (`SUBMIT_ONBOARDING`).
:::

#### TC-15-140 · Không phải đầu mối, PH-01 lỗi <!--k:onboard-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-046 · API-15-091 · ERR-15-031, 032 · LGC-APIM-019; LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** Cán bộ không phải đầu mối; ngắt PH-01.

**Các bước.**

1. Gửi hồ sơ ở hai tình huống.

**Kết quả mong đợi.** `422` ERR-15-032; `502` ERR-15-031, bản nháp giữ lại.
:::

#### TC-15-141 · Công bố API từ cổng <!--k:publish-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-047 · UC-15-25 · API-15-094, 095, 096 · UI-15-17 · BR-15-001, 014 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SV (chủ dịch vụ HT-TUPHAP); đặc tả hợp lệ.

**Các bước.**

1. Mở `/cong-bo/moi`, tải đặc tả, gửi.
2. `GET /publications/{id}`.

**Kết quả mong đợi.** PH-02 tạo đăng ký API ở trạng thái nháp theo F-02; cổng không tự đăng API; KT: có (`SUBMIT_PUBLICATION`).
:::

#### TC-15-142 · Không phải chủ dịch vụ, đặc tả lỗi, PH-02 ngắt <!--k:publish-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-047 · API-15-094 · ERR-15-005, 030 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Bình; đặc tả sai ở dòng 12; ngắt PH-02.

**Các bước.**

1. Bình gửi.
2. Chi gửi đặc tả sai.
3. Chi gửi khi PH-02 ngắt.

**Kết quả mong đợi.** `403` ERR-15-005; lỗi từng dòng của PH-02 hiển thị tại chỗ; `502` ERR-15-030.
:::

### TS-15-24 · Bảng điều khiển, thống kê và nhật ký ứng dụng

**Mục tiêu.** Xác nhận số liệu và nhật ký chỉ của ứng dụng mình, dữ liệu đã che, thay "xem log request" của hệ cũ.

**Phủ.** FR-15-048, 049, 050; UC-15-26; API-15-097…100; UI-15-12, 18; ERR-15-001, 005, 039; BR-15-009, 024; LGC-APIM-022.

#### TC-15-143 · Tổng quan cá nhân chịu lỗi từng thẻ <!--k:dash-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-048 · UC-15-26 · API-15-097, 140 · UI-15-18 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; ngắt PH-13.

**Các bước.**

1. `GET /dashboard`; mở UI-15-18.

**Kết quả mong đợi.** Thẻ ứng dụng, credential sắp hết hạn, đăng ký, phiếu bình thường; thẻ số liệu hiện "Chưa tải được."; `GET /inbox/unread-count` (API-15-140) khớp huy hiệu.
:::

#### TC-15-144 · Thống kê theo ứng dụng khớp số lượt gọi <!--k:stats-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-049 · UC-15-26 · API-15-098 · UI-15-12 · BR-15-009 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** Ứng dụng gọi sandbox 100 lượt: 80 thành công, 15 lỗi 4xx, 5 lỗi 5xx.

**Các bước.**

1. `GET /apps/app-tra-cuu-ho-tich/stats?khoang=1d`.

**Kết quả mong đợi.** Tổng, lỗi theo mã, độ trễ p50, p95, theo API khớp đúng; đọc từ PH-13 (`metrics:portal-read`).
:::

#### TC-15-145 · Không thành viên, PH-13 lỗi <!--k:stats-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-049 · API-15-098 · ERR-15-005, 039 · NFR-15-017 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** U-T68-DEV-CU; ngắt PH-13; ứng dụng cùng mã ở T01.

**Các bước.**

1. Cự `GET .../stats`.
2. An `GET .../stats` khi PH-13 ngắt.

**Kết quả mong đợi.** `403` ERR-15-005; `502` ERR-15-039 "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."
:::

#### TC-15-146 · Nhật ký gọi che dữ liệu <!--k:logs-masked-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-050 · UC-15-26 · API-15-099, 100 · UI-15-12 · ERR-15-001 · BR-15-024 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** Ứng dụng của An và ứng dụng của Bi; lời gọi có `Authorization`, thân chứa CCCD, số điện thoại, DH-CANARY.

**Các bước.**

1. `GET /apps/{của An}/logs`; `/logs/{logId}`.
2. An gọi `logId` thuộc ứng dụng của Bi.

**Kết quả mong đợi.** Chỉ nhật ký ứng dụng của An; `Authorization` và trường PII che theo SEC-32; canary 0; bước 2 `404` ERR-15-001.
:::

### TS-15-25 · Theo dõi thay đổi API và hộp thông báo

**Mục tiêu.** Xác nhận người theo dõi nhận thông báo thay đổi từ PH-02, loại bắt buộc không tắt được, và hộp thư chỉ của chủ nhận.

**Phủ.** FR-15-051, 052; UC-15-27; API-15-101…106, 140; UI-15-19; EVT-15-12; ERR-15-001, 003; BR-15-027.

#### TC-15-147 · Theo dõi và nhận thông báo ngừng khuyến nghị <!--k:notify-follow-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-15-051, 052 · UC-15-27 · API-15-101, 102, 103, 104, 140 · UI-15-19 · BR-15-027 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An theo dõi `tra-cuu-ho-tich` kênh `IN_APP`, `EMAIL`; S-PH02 phát EVT-02-12 ngừng khuyến nghị.

**Các bước.**

1. `PUT /notification-subscriptions/tra-cuu-ho-tich`.
2. Phát sự kiện; `GET /inbox`; `GET /inbox/unread-count`.
3. `DELETE /notification-subscriptions/tra-cuu-ho-tich`; phát lại sự kiện thông tin.

**Kết quả mong đợi.** Trong ≤ 60 giây có thông báo trong hộp thư và thư điện tử; `unread-count` tăng 1; sau bước 3 không còn thông báo loại thông tin (loại bắt buộc vẫn tới); An không thấy thông báo về API đã ẩn khỏi tầm của An (xem TC-15-008).
:::

#### TC-15-148 · Không tắt loại bắt buộc; API ngoài tầm <!--k:notify-mandatory-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-051 · API-15-102 · ERR-15-001, 003 · BR-15-027 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An; `tra-cuu-dat-dai` ngoài tầm.

**Các bước.**

1. `PUT` tắt loại "ngừng khuyến nghị".
2. `PUT /notification-subscriptions/tra-cuu-dat-dai`.

**Kết quả mong đợi.** `400` ERR-15-003 "Loại thông báo này là bắt buộc nên không tắt được"; `404` ERR-15-001; thay đổi phá vỡ vẫn gửi dù người dùng tắt loại thông tin.
:::

#### TC-15-149 · Đánh dấu đã đọc, giữ 90 ngày <!--k:inbox-read-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-15-052 · API-15-105, 106 · NFR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** 5 thông báo chưa đọc; đồng hồ +91 ngày.

**Các bước.**

1. `:read` một thông báo; `:read-all`.
2. Đẩy đồng hồ 91 ngày.

**Kết quả mong đợi.** Số chưa đọc 4 rồi 0; thông báo cũ hơn 90 ngày bị xóa; phân trang đúng.
:::

#### TC-15-150 · Không đọc hộp thư người khác <!--k:inbox-isolation-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-052 · API-15-104, 105 · ERR-15-001 · NFR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Thông báo của An; Cự; U-T01-DEV.

**Các bước.**

1. Cự `POST /inbox/{id của An}:read`; `GET /inbox`.

**Kết quả mong đợi.** `404` ERR-15-001; hộp thư của Cự không có thông báo của An; thông báo không đổi trạng thái.
:::

### TS-15-26 · Hỏi đáp, báo lỗi tài liệu, yêu cầu hỗ trợ

**Mục tiêu.** Xác nhận yêu cầu hỗ trợ tới đúng đầu mối của chủ dịch vụ, phiếu chỉ của người gửi, và chống gửi tràn.

**Phủ.** FR-15-053, 054, 055; UC-15-28; API-15-107…115; UI-15-04, 07, 20, 28; EVT-15-12; ERR-15-001, 003, 005, 029, 037; BR-15-030.

#### TC-15-151 · Gửi và theo dõi phiếu hỗ trợ <!--k:ticket-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-054 · UC-15-28 · API-15-110, 111, 112, 113 · UI-15-20 · EVT-15-12 · BR-15-030 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN; đầu mối hỗ trợ của HT-TUPHAP là U-T68-SV.

**Các bước.**

1. `POST /support/tickets` {kind `SUPPORT_REQUEST`, apiCode `tra-cuu-ho-tich`, tiêu đề, nội dung}.
2. `GET /support/tickets`, chi tiết; `POST .../messages`.

**Kết quả mong đợi.** `201`, `ticketCode` dạng `HT-2026-nnnn`, `OPEN`, tới đầu mối của chủ dịch vụ (Chi); EVT-15-12 tới PH-13, PH-10 (thông báo); An chỉ thấy phiếu của mình.
:::

#### TC-15-152 · Đầu mối xử lý, nhắc quá hạn <!--k:ticket-handle-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-055 · UC-15-28 · API-15-114, 115 · UI-15-28 · BR-15-030 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Phiếu OPEN; Chi có `PERM-15-support`; `15.support.sla-hours = 4`; đồng hồ +5 giờ.

**Các bước.**

1. Chi `GET /admin/support/tickets`; `:transition` sang `ANSWERED`, `RESOLVED`, `CLOSED`.
2. Với phiếu khác để quá 5 giờ chưa phản hồi.

**Kết quả mong đợi.** Chuyển trạng thái đúng, EVT-15-12 mỗi lần, An nhận thông báo; phiếu quá hạn nhắc đầu mối và báo TA.
:::

#### TC-15-153 · Phiếu đóng, của người khác, quá dài, gửi tràn, thiếu quyền <!--k:ticket-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-054, 055 · API-15-110, 112, 113, 114 · ERR-15-001, 003, 005, 029, 037 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Phiếu CLOSED; phiếu của An; Cự; Bình không có `PERM-15-support`; phiếu 4.001 ký tự; 6 phiếu/giờ.

**Các bước.**

1. Thêm tin vào phiếu CLOSED.
2. Cự `GET` phiếu của An.
3. Gửi phiếu 4.001 ký tự; gửi 6 phiếu trong 1 giờ.
4. Bình `GET /admin/support/tickets`; Chi truy cập phiếu của dịch vụ khác.

**Kết quả mong đợi.** `409` ERR-15-029; `404` ERR-15-001; `400` ERR-15-003; `429` ERR-15-037; Bình `403` ERR-15-005; phiếu ngoài phạm vi `404`.
:::

#### TC-15-154 · Hỏi đáp công khai, báo lỗi tài liệu, đánh giá <!--k:qa-feedback-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-15-053 · UC-15-28 · API-15-107, 108, 109 · UI-15-04, 07 · ERR-15-003, 037 · BR-15-030 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An; nội dung `<b>x</b> DH-CANARY`; gửi liên tục quá ngưỡng.

**Các bước.**

1. `POST /catalog/apis/tra-cuu-ho-tich/questions`; `GET`.
2. `POST /feedback` (báo lỗi tài liệu, đánh giá 4 sao).
3. Gửi nội dung rỗng; gửi vượt ngưỡng.

**Kết quả mong đợi.** Câu hỏi là văn bản thuần (thẻ HTML hiện nguyên chữ, không dựng); phản hồi tới đầu mối; `400` ERR-15-003; `429` ERR-15-037.
:::

### TS-15-27 · Nhận diện và tham số cổng theo tenant

**Mục tiêu.** Xác nhận quản trị đổi tên, logo, liên kết và tham số trong miền cho phép, và không đổi được giao diện nền.

**Phủ.** FR-15-056, 057; UC-15-29; API-15-116…120, 139; UI-15-25; ERR-15-003, 005, 006, 033, 034; BR-15-031, 032; LGC-APIM-007.

#### TC-15-155 · Đặt nhận diện cổng <!--k:brand-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-056 · UC-15-29 · API-15-116, 117, 118, 139 · UI-15-25 · BR-15-032 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** U-T68-TA; logo PNG 200 KB, 256 px; U-ANON.

**Các bước.**

1. `PUT /admin/branding` {tên cổng, liên kết HTTPS, chân trang, lời chào}; `POST /admin/branding/logo`.
2. Khách `GET /public/branding`; mở `/`.

**Kết quả mong đợi.** `200`; khách thấy tên, logo, chân trang mới ≤ 60 giây; KT: có (`CHANGE_SETTING`); màu, phông, token, vật liệu kính không đổi; không tenant khác bị ảnh hưởng.
:::

#### TC-15-156 · Logo sai, liên kết không HTTPS, trường ngoài miền <!--k:brand-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-056 · API-15-117, 118 · ERR-15-003, 006, 033 · BR-15-032 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** Logo SVG, logo 600 KB, logo 100 px, liên kết `http://`, trường `primaryColor`.

**Các bước.**

1. Tải từng logo.
2. `PUT` liên kết `http://`; `PUT` có `primaryColor`; `PUT` với `If-Match` cũ.

**Kết quả mong đợi.** `422` ERR-15-033 (ba logo, liên kết); `400` ERR-15-003 (`primaryColor`, giả định); `412` ERR-15-006.
:::

#### TC-15-157 · Đổi tham số có hiệu lực <!--k:settings-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-057 · UC-15-29 · API-15-119, 120 · UI-15-25 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-TA; `15.app.max-per-user` 10, `15.public.enabled` `false`.

**Các bước.**

1. `PUT /admin/settings` đặt `15.app.max-per-user = 3`, `15.public.enabled = true`.
2. Tạo ứng dụng thứ 4; mở cổng khi ẩn danh.

**Kết quả mong đợi.** Hiệu lực trong 60 giây; ứng dụng thứ 4 `422` ERR-15-015; ẩn danh vào được phần công khai; KT: có (`CHANGE_SETTING`) ghi giá trị cũ, mới.
:::

#### TC-15-158 · Ngoài miền, vượt trần, thiếu quyền <!--k:settings-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-057 · API-15-120 · ERR-15-005, 006, 034 · BR-15-031 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Hà; An, Chi, Bình, Khánh (không `PERM-15-portal-admin`).

**Các bước.**

1. `15.cred.ttl-days = 181`; `15.sync.interval-seconds = 30`; `15.try.prod-max-days = 91`.
2. `If-Match` cũ.
3. An, Chi, Bình, Khánh `PUT`.

**Kết quả mong đợi.** `422` ERR-15-034 "Giá trị của 15.cred.ttl-days phải trong khoảng 30 đến 180" cho từng khóa; `412` ERR-15-006; bốn người `403` ERR-15-005; giá trị cũ giữ nguyên.
:::

### TS-15-28 · Khóa, mở khóa và khu quản trị

**Mục tiêu.** Xác nhận khóa tài khoản, ứng dụng có hiệu lực tức thời, và khu quản trị chỉ vào được từ mạng quản trị có MFA.

**Phủ.** FR-15-059; UC-15-30; API-15-124…127; UI-15-24; EVT-15-02, 07; ERR-15-003, 005, 017, 022, 036; BR-15-031.

#### TC-15-159 · Khóa và mở khóa tài khoản dh-dev <!--k:lock-account-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-059 · UC-15-30 · API-15-124, 125 · UI-15-24 · EVT-15-07 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An ACTIVE có phiên đang mở; Hà.

**Các bước.**

1. `POST /admin/dev-accounts/{An}:lock` {lý do}.
2. An gọi API, đăng nhập lại.
3. `:unlock`.

**Kết quả mong đợi.** `LOCKED`, phiên bị cắt, Keycloak vô hiệu người dùng; An `403` ERR-15-014; EVT-15-07; KT: có (`LOCK_ACCOUNT`, `UNLOCK_ACCOUNT`); sau mở khóa `ACTIVE`.
:::

#### TC-15-160 · Tạm ngừng và tiếp tục ứng dụng <!--k:suspend-app-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-15-059 · UC-15-30 · API-15-126, 127 · EVT-15-02 · ERR-15-017, 102 · NFR-15-007 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ứng dụng ACTIVE đang gọi sandbox liên tục; Khánh (SO).

**Các bước.**

1. `POST /admin/apps/app-tra-cuu-ho-tich:suspend` {lý do}.
2. An thử, cấp, xoay credential; gọi trực tiếp sandbox.
3. `:resume`.

**Kết quả mong đợi.** `SUSPENDED`, EVT-15-02; thử `403` ERR-15-102, cấp/xoay `409` ERR-15-017, gọi trực tiếp bị chặn ≤ 60 giây; sau `:resume` hoạt động, credential cũ vẫn `ACTIVE`.
:::

#### TC-15-161 · Sai trạng thái, thiếu lý do, thiếu quyền <!--k:lock-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-059 · API-15-124, 126 · ERR-15-003, 005, 017, 022 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tài khoản LOCKED; ứng dụng ARCHIVED; Bình.

**Các bước.**

1. `:lock` tài khoản LOCKED.
2. `:suspend` ứng dụng ARCHIVED.
3. `:lock` không lý do.
4. Bình `:lock`.

**Kết quả mong đợi.** `409` ERR-15-022; `409` ERR-15-017; `400` ERR-15-003; `403` ERR-15-005.
:::

#### TC-15-162 · Khu quản trị chỉ từ mạng quản trị, có MFA <!--k:admin-network-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-15-056, 057, 060 · UI-15-25, 26 · ERR-15-036 · BR-15-031 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** Hà có WebAuthn; cổng ở tên miền công khai và ở mạng quản trị.

**Các bước.**

1. Từ tên miền công khai mở `/quan-tri-cong/nhan-dien`.
2. Từ mạng ngoài quản trị gọi `GET /admin/settings`.
3. Từ mạng quản trị đăng nhập không MFA; rồi có WebAuthn.

**Kết quả mong đợi.** Bước 1 `404`; bước 2 `403` ERR-15-036; bước 3 buộc xác thực lại bằng WebAuthn, sau đó `200`; DEV không thấy menu quản trị.
:::

### TS-15-29 · Nhật ký kiểm toán và báo cáo sử dụng

**Mục tiêu.** Xác nhận kiểm toán đủ hành động, tra cứu đúng quyền, xuất có kiểm toán và cô lập giữa tenant.

**Phủ.** FR-15-060; UC-15-31; API-15-128…130; UI-15-26; ERR-15-003, 005, 039; BR-15-023, 024.

#### TC-15-163 · Tra cứu nhật ký theo hành động <!--k:audit-query-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-15-060 · UC-15-31 · API-15-128 · UI-15-26 · BR-15-024 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-SO, U-T68-AU; 20 lượt thử, 2 lần xem tài liệu nhạy cảm đã thực hiện.

**Các bước.**

1. `GET /admin/audit?hanh-dong=TRY_API&tu=…&den=…`.
2. Lọc `VIEW_SENSITIVE_DOCS`.

**Kết quả mong đợi.** Kết quả đúng số, có người, ứng dụng, API, `traceId`, kết quả; không có thân, bí mật; việc xem nhật ký tự ghi KT `VIEW_AUDIT`.
:::

#### TC-15-164 · Mỗi hành động của cổng đều có bản ghi kiểm toán <!--k:audit-actions-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-15-060 · UC-15-31 · API-15-128 · BR-15-023 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** S-PH13 ghi nhận; kịch bản gọi từng hành động: `VIEW_SENSITIVE_DOCS`, `DOWNLOAD_SPEC`, `TRY_API`, `TRY_PRODUCTION`, `SECRET_ISSUED`, `SUBMIT_SUBSCRIPTION`, `SUBMIT_ONBOARDING`, `SUBMIT_PUBLICATION`, `LOCK_ACCOUNT`, `UNLOCK_ACCOUNT`, `CHANGE_SETTING`, `VIEW_AUDIT`, `EXPORT_AUDIT`.

**Các bước.**

1. Thực hiện từng hành động một lần.

**Kết quả mong đợi.** Mỗi hành động đúng một bản ghi `PORTAL_*` ở PH-13 đủ trường FR-00-041 (người, tenant, thời điểm, đối tượng, kết quả, `traceId`), không chứa bí mật hay thân yêu cầu.
:::

#### TC-15-165 · Xuất nhật ký và báo cáo sử dụng <!--k:audit-export-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-060 · UC-15-31 · API-15-129, 130 · UI-15-26 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Khánh; dữ liệu 30 ngày.

**Các bước.**

1. `GET /admin/usage-report?khoang=30d`.
2. `POST /admin/audit:export`.

**Kết quả mong đợi.** Báo cáo khớp số lượt thử, ứng dụng, tài khoản mới; tệp xuất có băm; KT: có (`EXPORT_AUDIT`).
:::

#### TC-15-166 · Khoảng quá dài, PH-13 lỗi, thiếu quyền, tenant khác <!--k:audit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-15-060 · API-15-128, 129 · ERR-15-003, 005, 039 · NFR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Khoảng 13 tháng; ngắt PH-13; An, Bình; U-T01-AU.

**Các bước.**

1. `GET /admin/audit?tu=` quá 12 tháng.
2. Gọi khi PH-13 ngắt.
3. An, Bình gọi.
4. U-T01-AU gọi qua tên miền T68.

**Kết quả mong đợi.** `400` ERR-15-003 "Khoảng thời gian vượt 12 tháng"; `502` ERR-15-039; `403` ERR-15-005; bước 4 không có bản ghi nào của T68.
:::

### TS-15-30 · Đồng bộ lại và đối soát danh mục

**Mục tiêu.** Xác nhận quản trị chạy đồng bộ, đối soát phát hiện sai lệch và sửa được, và chống chạy song song.

**Phủ.** FR-15-061; UC-15-04; API-15-131…134; UI-15-27; ERR-15-005, 030, 035; BR-15-001.

#### TC-15-167 · Đồng bộ lại theo yêu cầu <!--k:resync-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-15-061 · UC-15-04 · API-15-131, 132 · UI-15-27 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Hà; bản sao đã nạp.

**Các bước.**

1. `POST /admin/sync:run`; `GET /admin/sync/runs`.

**Kết quả mong đợi.** Lần chạy có `runId`, `RUNNING` rồi `IDLE`, số mục, thời lượng; KT: có; lịch sử liệt kê đúng.
:::

#### TC-15-168 · Đang chạy, PH-02 lỗi, thiếu quyền <!--k:resync-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-061 · API-15-131 · ERR-15-005, 030, 035 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Lần chạy dài (WireMock chậm); ngắt PH-02; An.

**Các bước.**

1. Gọi `sync:run` hai lần liên tiếp.
2. Gọi khi PH-02 ngắt.
3. An gọi.

**Kết quả mong đợi.** `409` ERR-15-035 "Đang có lần chạy khác..."; `502` ERR-15-030; `403` ERR-15-005.
:::

#### TC-15-169 · Đối soát phát hiện và sửa sai lệch <!--k:reconcile-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-15-061 · UC-15-04 · API-15-133, 134 · BR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Xóa tay một mục ở bản sao, sửa tên mục khác (chỉ ở bản sao).

**Các bước.**

1. `POST /admin/reconciliations`; `GET /admin/reconciliations/latest`.
2. `sync:run`; đối soát lại.

**Kết quả mong đợi.** Báo 2 sai lệch (thiếu, khác `sourceVersion`); sau đồng bộ lại 0 sai lệch, bản sao ghi đè theo PH-02.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

### TS-15-31 · Cô lập tenant

**Mục tiêu.** Chứng minh không có đường rò rỉ chéo tenant ở API, CSDL, tìm kiếm, bộ đệm, sandbox và sự kiện.

**Phủ.** NFR-15-017; BR-15-003, 034; FR-15-002, 005, 025, 035; ERR-15-001, 005; ADR-003.

#### TC-15-170 · Mọi API đọc, ghi theo mã trả 404-ẩn giữa T68 và T01 <!--k:iso-api-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-15-017 · BR-15-003, 034 · ERR-15-001 · API-15-004, 024, 057, 073, 077, 089, 093, 096, 112 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** T68 và T01 có cùng mã `tra-cuu-ho-tich`, `app-tra-cuu-ho-tich`, `bat-dau-nhanh`, `HT-2026-0001`; token U-T01-TA, U-T01-DEV qua tên miền T68; danh sách thao tác sinh từ `openapi-portal.yaml`.

**Các bước.**

1. Với mọi operation có tham số định danh gọi bằng mã của T68.
2. Với mọi operation ghi lặp lại.
3. Đọc lại dữ liệu T68 bằng token T68; thêm tiêu đề `X-DH-Tenant: T68`.

**Kết quả mong đợi.** Mọi lần `404` ERR-15-001, thân giống "không tồn tại" trừ `traceId`, `instance`; dữ liệu T68 không đổi; tiêu đề `X-DH-Tenant` do client gửi bị bỏ qua.
:::

#### TC-15-171 · Danh sách không lẫn tenant <!--k:iso-list-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-15-017 · BR-15-003 · API-15-005, 055, 075, 104, 111, 121, 128 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Dữ liệu seed cả hai tenant (mỗi loại 3 bản ghi T68, 2 bản ghi T01).

**Các bước.**

1. Mỗi danh sách gọi bằng token T01 và bằng token T68.

**Kết quả mong đợi.** Token T01 chỉ thấy 2 bản ghi của T01; `total` đếm đúng; không có mã T68.
:::

#### TC-15-172 · Tên miền và token khác tenant <!--k:iso-domain-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-15-003 · NFR-15-017 · ERR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Tên miền cổng T01 với token realm T68, và ngược lại.

**Các bước.**

1. Gọi `GET /me`, `GET /apps`.

**Kết quả mong đợi.** Bị từ chối (`401` hoặc `403`), không lộ dữ liệu của cả hai tenant (giả định mã `403` ERR-15-005, Q15-40).
:::

#### TC-15-173 · Chỉ mục tìm kiếm, bộ đệm, hạn mức theo tenant <!--k:iso-index-cache-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-15-017 · FR-15-005 · BR-15-003 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Hai tenant có mục trùng tên; OpenSearch, Valkey thật.

**Các bước.**

1. T01 tìm `q=hộ tịch`, mở trang chủ sau khi T68 đã nạp bộ đệm.
2. Kiểm khóa Valkey và chỉ mục.

**Kết quả mong đợi.** T01 không thấy mục T68; khóa bộ đệm, hạn mức, chỉ mục đều chứa mã tenant; hạn mức của T68 không tiêu của T01.
:::

#### TC-15-174 · RLS, sandbox, sự kiện <!--k:iso-db-sandbox-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB, IT.

**Truy vết.** NFR-15-017 · BR-15-003 · EVT-15-01 · API-15-082 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** `ph15_isolation_test.sql`; client `sbx-t01-…`; topic `t68.portal.*`.

**Các bước.**

1. Chạy `psql -v ON_ERROR_STOP=1 -f ph15_isolation_test.sql`.
2. Dùng credential `sbx-t01-…` gọi sandbox ở host T68; dùng credential T68 ở host T01.
3. Principal Kafka của T01 đọc `t68.portal.app.created.v1`.

**Kết quả mong đợi.** Bài kiểm CSDL toàn `PASS` (không đặt `app.tenant_id` thì 0 dòng; ghi sai tenant bị chặn; bảng nhật ký không sửa được); bước 2 `forward-auth` từ chối; bước 3 bị ACL từ chối.
:::

### TS-15-32 · Không lộ bí mật và không token ở trình duyệt

**Mục tiêu.** Chứng minh bí mật sandbox chỉ hiện đúng lần cấp và không còn ở bất kỳ nơi nào, và trình duyệt không giữ token.

**Phủ.** NFR-15-009, 010; BR-15-011, 024; FR-15-027…030, 035, 040, 041, 050.

#### TC-15-175 · Dò mồi bí mật sau cấp và xoay <!--k:canary-secret-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** NFR-15-009 · FR-15-027, 028, 029, 030 · BR-15-011 · LGC-APIM-011; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** Bộ sinh khóa thay bằng giá trị `DH-CANARY-{ca}` (móc kiểm thử); ứng dụng An.

**Các bước.**

1. Cấp API key, cấp client_credentials, xoay một credential.
2. Tìm `DH-CANARY-{ca}` ở: phản hồi API (ngoài lần cấp), log ứng dụng 5 phút, vết OTel, bảng `ph15_portal.*`, outbox, Kafka, Valkey, tệp xuất, mẫu mã, nhật ký gateway, PH-13.

**Kết quả mong đợi.** Mọi nơi 0 lần; CSDL chỉ có tiền tố 8 ký tự và băm.
:::

#### TC-15-176 · Dò mồi trong lượt thử <!--k:canary-try-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-15-009 · FR-15-035, 040, 050 · BR-15-024 · LGC-APIM-022.

**Tiền điều kiện, dữ liệu.** Thân `{"ghiChu":"DH-CANARY-ct"}`, tiêu đề `X-API-Key: DH-CANARY-ct`.

**Các bước.**

1. Thử MOCK và BACKEND; lưu vào bộ sưu tập; xem lịch sử, nhật ký, kiểm toán.

**Kết quả mong đợi.** 0 canary ở `try_run`, lịch sử, nhật ký ứng dụng, kiểm toán, EVT-15-11, log, vết; tiêu đề xác thực bị loại khỏi bộ sưu tập.
:::

#### TC-15-177 · Không token ở trình duyệt <!--k:no-token-browser-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-15-010 · FR-15-019 · UI-15-08 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Playwright; sau đăng nhập SSO và dh-dev.

**Các bước.**

1. Kiểm `localStorage`, `sessionStorage`, IndexedDB, biến toàn cục, cookie không `HttpOnly`.
2. Bắt mọi yêu cầu XHR/fetch của SPA.

**Kết quả mong đợi.** Không có JWT, `access_token`, `refresh_token`; cookie phiên `HttpOnly`, `Secure`, `SameSite`; SPA không gửi `Authorization: Bearer` (BFF dùng cookie); yêu cầu ghi có chống CSRF.
:::

#### TC-15-178 · Không bí mật ở phản hồi, bộ đệm trình duyệt, log gateway <!--k:secret-headers-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API, ZAP.

**Truy vết.** NFR-15-009 · FR-15-029 · BR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Phản hồi cấp credential và `GET .../credentials`.

**Các bước.**

1. Kiểm tiêu đề, bộ nhớ đệm, lịch sử trình duyệt, log APISIX.

**Kết quả mong đợi.** `Cache-Control: no-store`; không `secret` ở `GET`; log gateway không ghi thân; ZAP không tìm thấy bí mật ở đường khác.
:::

### TS-15-33 · An toàn khi lỗi, forward-auth, XSS, IDOR

**Mục tiêu.** Chứng minh các chốt an toàn: forward-auth đóng khi lỗi, cổng nội bộ không giả mạo được, Markdown không thực thi script, không IDOR giữa người dùng cùng tenant.

**Phủ.** NFR-15-011; BR-15-013, 023, 026; FR-15-014, 017, 035, 039; API-15-082; ERR-15-005, 111.

#### TC-15-179 · forward-auth đóng khi lỗi phụ thuộc <!--k:fa-closed-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos, IT.

**Truy vết.** FR-15-035, 039 · API-15-082 · UC-15-19 · BR-15-023 · NFR-15-007, 008 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt lần lượt Valkey, CSDL, JWKS Keycloak; lời gọi sandbox hợp lệ và không hợp lệ.

**Các bước.**

1. Gọi sandbox trong từng sự cố.
2. Khôi phục.

**Kết quả mong đợi.** Khi Valkey, CSDL hoặc JWKS lỗi: mọi lời gọi qua `forward-auth` bị từ chối (đóng khi lỗi, Q15-47 cho hạn mức), không lời gọi nào lọt tới backend; đọc danh mục không phụ thuộc Valkey vẫn `200`; sau khôi phục lời gọi hợp lệ `200`.
:::

#### TC-15-180 · Cổng nội bộ không giả mạo được <!--k:fa-spoof-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, ZAP.

**Truy vết.** API-15-082 · FR-15-035 · NFR-15-017 · ERR-15-001, 005 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** S-APISIX (SPIFFE hợp lệ); danh tính khác; client Internet.

**Các bước.**

1. Gọi `POST /internal/v1/sandbox/authorize` từ danh tính khác APISIX; không mTLS.
2. Gọi qua BFF công khai `/api/portal/v1/internal/v1/...`.
3. Từ APISIX gửi `X-Forwarded-Host` của T01 với credential T68.

**Kết quả mong đợi.** Bước 1 bị từ chối ở cổng 8081; bước 2 `404`; bước 3 từ chối (tenant lấy từ host gateway, client không đặt được).
:::

#### TC-15-181 · Markdown không thực thi script, CSP chặt <!--k:xss-md-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP, E2E.

**Truy vết.** NFR-15-011 · FR-15-014, 017 · BR-15-013 · UI-15-07 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Bộ vector XSS OWASP cho Markdown (120 mẫu) đã đưa vào trang đã đăng qua đường nhập Git (bỏ qua bộ lọc ghi) và qua API.

**Các bước.**

1. Mở UI-15-07 từng trang; quét ZAP.

**Kết quả mong đợi.** 0 script thực thi; CSP `script-src 'self'`, không `unsafe-inline`, `frame-ancestors 'none'`; có `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Strict-Transport-Security`; bộ lọc đầu ra loại mẫu lọt qua.
:::

#### TC-15-182 · Không IDOR giữa hai người dùng cùng tenant <!--k:idor-same-tenant-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-15-017 · BR-15-009 · ERR-15-001, 005 · API-15-057, 062, 073, 078, 100, 105, 112 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** An và Cự cùng T68; mọi định danh của An: `appCode`, `credentialId`, `tryId`, `collectionId`, `logId`, `messageId`, `ticketCode`.

**Các bước.**

1. Cự gọi từng API với định danh của An.

**Kết quả mong đợi.** Mọi lần bị từ chối (`403` ERR-15-005 hoặc `404` ERR-15-001 theo FRS ở từng API); dữ liệu của An không đổi.
:::

#### TC-15-183 · CSRF và đăng nhập giả mạo <!--k:csrf-bff-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** ZAP.

**Truy vết.** FR-15-019 · NFR-15-010 · ERR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Trang giả của origin lạ gửi `POST /api/portal/v1/apps` bằng cookie của An.

**Các bước.**

1. Gửi yêu cầu chéo origin.

**Kết quả mong đợi.** Bị từ chối `403`; `state` và `nonce` đăng nhập được kiểm; không chuyển hướng mở tới địa chỉ ngoài.
:::

### TS-15-34 · Phân quyền và tách nhiệm

**Mục tiêu.** Chứng minh mỗi vai trò chỉ làm được điều D02-08 cho phép và bốn mắt độc lập với phân quyền.

**Phủ.** PERM-15-app, PERM-15-try, PERM-15-portal-admin, PERM-15-content-write, PERM-15-content-publish, PERM-15-support, PERM-15-dev-approve, PERM-15-audit-read; ERR-15-004, 005, 023.

#### TC-15-184 · Ma trận vai trò × API ghi <!--k:perm-matrix-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** ERR-15-005 · FR-15-014, 042, 056, 058 · API-15-023, 056, 072, 084, 117, 122, 128 · LGC-APIM-007.

**Tiền điều kiện, dữ liệu.** U-ANON, U-T68-DEV-AN, U-T68-OR, U-T68-SV, U-T68-CA, U-T68-TA, U-T68-SO, U-T68-AU; bảng vai trò → quyền sinh từ D02-08.

**Các bước.**

1. Mỗi vai gọi mọi API ghi và API quản trị.

**Kết quả mong đợi.** Cặp không có quyền `403` ERR-15-005 (ẩn danh `401` ERR-15-004), cặp có quyền thành công; kết quả khớp bảng quyền, không ngoại lệ.
:::

#### TC-15-185 · Bốn mắt độc lập với quyền <!--k:perm-sod-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-15-012, 021 · FR-15-015, 042 · ERR-15-023 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-CA có cả `PERM-15-content-write` và `PERM-15-content-publish`.

**Các bước.**

1. CA soạn, gửi và tự duyệt; CA đề xuất và tự duyệt thử production.

**Kết quả mong đợi.** `403` ERR-15-023 ở cả hai, dù đủ quyền.
:::

#### TC-15-186 · Chưa đăng nhập hoặc phiên hết hạn <!--k:perm-401-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** ERR-15-004 · FR-15-019 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Không cookie; cookie hết hạn.

**Các bước.**

1. Gọi mọi API không thuộc `/public`.

**Kết quả mong đợi.** `401` ERR-15-004; `/public/*` không cần đăng nhập (khi bật).
:::

#### TC-15-187 · Menu và đường dẫn theo quyền <!--k:perm-menu-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-15-24, 25, 26, 28 · BR-15-031 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Vai DEV, OR, SV, TA, SO, AU.

**Các bước.**

1. Mở menu và gõ trực tiếp đường dẫn `/quan-tri-cong/...`.

**Kết quả mong đợi.** Mục không có quyền không hiện; gõ trực tiếp `404` hoặc `403` theo TC-15-162; không lộ cấu trúc quản trị.
:::

### TS-15-35 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-15-001…008, 012, 013, 018 ở quy mô một tenant vừa theo GĐ-15-01.

**Phủ.** NFR-15-001…008, 012, 013, 018.

| Mã | Tên | Tải | Ngưỡng | Truy vết |
|---|---|---|---|---|
| TC-15-188 | Tải trang đầu <!--k:perf-lcp--> | Trang chủ, danh mục, tài liệu; máy 4 nhân, 8 GB, 20 Mbps; 30 lượt | LCP ≤ 2,5 giây, INP ≤ 200 ms | NFR-15-001 · UI-15-01, 02, 05 |
| TC-15-189 | API danh mục và tìm kiếm <!--k:perf-api--> | 500 API, 3.000 phiên bản; 100 người đồng thời, 15 phút | Đọc p95 ≤ 300 ms; tìm p95 ≤ 300 ms; gợi ý p95 ≤ 200 ms | NFR-15-002, 012 · FR-15-004, 005 |
| TC-15-190 | Hiển thị tài liệu <!--k:perf-spec--> | Đặc tả 300 thao tác; 50 người đồng thời | `operations` p95 ≤ 500 ms; dựng trang ≤ 2 giây | NFR-15-003 · FR-15-009 |
| TC-15-191 | Độ trễ đồng bộ <!--k:perf-sync--> | 50 thay đổi mỗi phút, 10 phút; sau đó mất sự kiện | Sự kiện → hiển thị p95 ≤ 30 giây; kéo bù ≤ 5 phút | NFR-15-004 · FR-15-001 |
| TC-15-192 | Độ trễ thêm của đường thử <!--k:perf-try--> | 50 lượt thử đồng thời, MOCK và BACKEND, 10 phút | Ngoài thời gian backend p95 ≤ 100 ms; MOCK p95 ≤ 150 ms | NFR-15-005 · FR-15-035, 036 |
| TC-15-193 | Cấp credential <!--k:perf-cred--> | 20 yêu cầu cấp đồng thời kể cả Keycloak | p95 ≤ 3 giây | NFR-15-006 · FR-15-027 |
| TC-15-194 | Hiệu lực thu hồi, khóa <!--k:perf-revoke--> | 100 lượt/giây; thu hồi 50 credential, khóa 10 ứng dụng | Chặn ≤ 60 giây; ≤ 5 giây khi nhận EVT-15-05 | NFR-15-007 · FR-15-031, 059 |
| TC-15-195 | Thông lượng thử toàn tenant <!--k:perf-throughput--> | ≥ 100 lượt/giây, 10 phút, hạn mức tenant 100 | Giữ NFR-15-005; vượt thì 429 chứ không lỗi 5xx | NFR-15-013 · FR-15-039 |
| TC-15-196 | Truy cập ẩn danh chịu tải <!--k:perf-anon--> | 300 lượt/giây trang `PUBLIC`; một IP vượt trần | Phục vụ nhờ bộ đệm, p95 ≤ 300 ms; IP vượt trần bị 429 | NFR-15-018 · FR-15-008 |
| TC-15-197 | Quy mô tenant vừa <!--k:perf-scale--> | 500 API, 3.000 phiên bản, 2.000 tài khoản dh-dev, 2.000 ứng dụng, 300 trang, 100 người đồng thời, 1 giờ | Mọi ngưỡng trên giữ; 0 lỗi 5xx | NFR-15-012 · FR-15-001, 025, 058 |

: TS-15-35 · Hiệu năng, tải và quy mô

### TS-15-36 · Truy cập, 360 px và trình duyệt

**Mục tiêu.** Chứng minh UI-15-01…28 đạt WCAG 2.2 AA, dùng được từ 360 px, bằng bàn phím, và chạy trên bốn trình duyệt.

**Phủ.** NFR-15-014, 015, 021; UI-15-01…28.

#### TC-15-198 · Quét tự động mọi màn <!--k:a11y-axe-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-15-014 · UI-15-01…28 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** U-T68-DEV-AN, U-T68-OR, U-T68-TA; dữ liệu mục 2.

**Các bước.**

1. Chạy axe-core trên 28 màn ở trạng thái rỗng, có dữ liệu, lỗi; chế độ sáng, tối, giảm trong suốt.

**Kết quả mong đợi.** 0 vi phạm mức nghiêm trọng hoặc nghiêm trọng cao; mọi ảnh có chữ thay thế; mọi trường có nhãn.
:::

#### TC-15-199 · Dùng được ở 360 px <!--k:a11y-360-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-15-014 · UI-15-01…28 · FR-15-009 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Viewport 360×640 và 320 px (zoom 400 %), Chrome và Safari iOS giả lập.

**Các bước.**

1. Đi hết luồng: tìm → chi tiết → tài liệu → tạo ứng dụng → cấp credential → thử API.
2. Mở UI-15-05, UI-15-06, UI-15-13, UI-15-26.

**Kết quả mong đợi.** Không cuộn ngang trang (bảng, khối mã cuộn trong vùng riêng); mục lục tài liệu thành ngăn kéo; khung thử xếp dọc; hộp thoại bí mật vừa màn hình; vùng chạm ≥ 24×24 px (WCAG 2.2 mục 2.5.8) và nút hành động chính ≥ 44 px; chữ không bị cắt khi phóng 200 %.
:::

#### TC-15-200 · Dùng bằng bàn phím <!--k:a11y-keyboard-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-15-014 · UI-15-02, 05, 06, 13 · FR-15-029 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Chỉ bàn phím, không chuột.

**Các bước.**

1. Thực hiện luồng của TC-15-199 chỉ bằng bàn phím.

**Kết quả mong đợi.** Thứ tự focus hợp lý, có "Bỏ qua tới nội dung", focus nhìn thấy; hộp thoại bí mật bẫy focus và trả focus; khung thử gửi được bằng Ctrl+Enter; không bẫy bàn phím.
:::

#### TC-15-201 · Trình đọc màn hình và tương phản <!--k:a11y-reader-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** Thủ công.

**Truy vết.** NFR-15-014 · UI-15-02, 05, 06, 13 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** NVDA + Firefox, VoiceOver + Safari; nền kính sáng, tối.

**Các bước.**

1. Đi luồng chính; nghe bí mật được hiển thị; đọc banner lỗi.

**Kết quả mong đợi.** Bí mật được thông báo bằng vùng `aria-live` một lần; trạng thái có chữ, không chỉ màu; tương phản ≥ 4,5:1 trên nền kính; tôn trọng giảm chuyển động.
:::

#### TC-15-202 · Ma trận trình duyệt <!--k:browser-matrix-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** NFR-15-015 · NFR-15-021 · UI-15-01…28 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Chrome, Edge, Firefox, Safari (hai bản gần nhất).

**Các bước.**

1. Chạy kịch bản khói E2E (tìm, tài liệu, tạo ứng dụng, cấp credential, thử API) trên từng trình duyệt.

**Kết quả mong đợi.** Đạt ở cả 8 bản; nhãn và ngày giờ tiếng Việt, ngày `dd/MM/yyyy`, múi giờ UTC+7.
:::

### TS-15-37 · Chịu lỗi, hợp đồng, quan sát, lưu giữ, bắt đầu nhanh

**Mục tiêu.** Chứng minh cổng tiếp tục phục vụ khi phụ thuộc hỏng, sự kiện không mất, hợp đồng ổn định, chỉ số đủ, lưu giữ đúng và nhà phát triển mới gọi được sandbox trong 15 phút.

**Phủ.** NFR-15-008, 016, 019, 020, 022.

#### TC-15-203 · Outbox giữ sự kiện khi Kafka ngắt <!--k:chaos-kafka-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** NFR-15-008 · EVT-15-01, 02, 03, 05, 08, 11, 14 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Ngắt Kafka 10 phút; thực hiện tạo ứng dụng, cấp, thu hồi, đăng trang, thử.

**Các bước.**

1. Làm các thao tác; khôi phục Kafka.

**Kết quả mong đợi.** API vẫn thành công; `outbox` giữ bản tin; sau khôi phục phát đủ, đúng thứ tự theo khóa, không trùng; bản tin không có bí mật; có `dhtenant`.
:::

#### TC-15-204 · Giết pod giữa thao tác <!--k:chaos-pod-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** NFR-15-008 · FR-15-015, 027, 030 · LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** Chaos Mesh giết pod `api` giữa `:approve` trang, giữa `:rotate`.

**Các bước.**

1. Thực hiện thao tác, giết pod, thử lại với cùng `Idempotency-Key`.

**Kết quả mong đợi.** Trạng thái nhất quán (không nửa chừng), không trùng sự kiện, không credential mồ côi.
:::

#### TC-15-205 · Tương thích hợp đồng API và sự kiện <!--k:contract-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** CT.

**Truy vết.** NFR-15-019 · FR-15-001 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** `openapi-portal.yaml`, `asyncapi-portal.yaml`; bản phát hành trước.

**Các bước.**

1. Chạy Spectral, oasdiff với bản trước; kiểm Apicurio chế độ BACKWARD.

**Kết quả mong đợi.** Không thay đổi phá vỡ ở `v1` (chỉ thêm trường tùy chọn); mọi phản hồi lỗi khớp RFC 9457; mọi lược đồ Avro tương thích BACKWARD.
:::

#### TC-15-206 · Chỉ số và cảnh báo <!--k:observability-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** NFR-15-020 · FR-15-001, 030, 035 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** Sau các kịch bản đồng bộ, thử, xoay, từ chối hiển thị.

**Các bước.**

1. Đọc `/metrics`; đẩy `sync_lag` lên 1.000 giây.

**Kết quả mong đợi.** Có và tăng đúng `dh_portal_sync_lag_seconds`, `dh_portal_try_total`, `dh_portal_try_throttled_total`, `dh_portal_cred_old_use_total`, `dh_portal_visibility_denied_total`; cảnh báo lag > 900 giây phát trong 2 phút.
:::

#### TC-15-207 · Lưu giữ <!--k:retention-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** NFR-15-016 · FR-15-040, 052, 060 · LGC mới (không có chức năng hệ cũ tương ứng).

**Tiền điều kiện, dữ liệu.** Đồng hồ giả lập; cấu hình lưu giữ.

**Các bước.**

1. Kiểm lịch sử thử, thông báo, phiên bản trang, nhật ký, ẩn danh tài khoản.

**Kết quả mong đợi.** Lịch sử thử 30 ngày; thông báo 90 ngày; phiên bản trang vĩnh viễn; nhật ký 12 tháng trực tuyến và WORM 5 năm (khóa đối tượng); tài khoản ẩn danh sau 24 tháng.
:::

#### TC-15-208 · Lời gọi sandbox đầu tiên trong 15 phút <!--k:quickstart-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** Thủ công.

**Truy vết.** NFR-15-022 · FR-15-012, 025, 027, 035 · UC-15-14, 15, 19 · LGC-APIM-017; LGC-APIM-020; LGC-IAM-006.

**Tiền điều kiện, dữ liệu.** 5 người chưa từng dùng cổng, có tài khoản dh-dev ACTIVE; trang `bat-dau-nhanh` đã đăng.

**Các bước.**

1. Theo hướng dẫn: tạo ứng dụng, cấp credential, chép mẫu curl, gọi sandbox.

**Kết quả mong đợi.** ≥ 4/5 người có lời gọi thành công đầu tiên ≤ 15 phút (đo bằng EVT-15-03 và EVT-15-11); khói sáu ngôn ngữ ≥ 95 % thao tác mẫu chạy được.
:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Ba phiên 90 phút, mỗi phiên một chủ đề: (1) hành trình nhà phát triển mới từ tìm dịch vụ tới lời gọi sandbox đầu tiên, theo TC-15-208; (2) quản trị cổng: nhận diện, tham số, duyệt tài khoản, di trú; (3) tìm cách vượt chặn: đoán mã API, đổi định danh, gửi dữ liệu giống DLCN, thử production khi chưa đủ điều kiện. Ghi chép theo mẫu SBTM; lỗi phát hiện chuyển thành ca tự động.

### 6.2. Diễn tập di trú portal Gravitee

Dùng bản xuất portal Gravitee thật của tỉnh thí điểm (đã làm sạch): nhập (UI-15-27), xem báo cáo xem trước, xác nhận, rà từng trang nháp, duyệt bốn mắt, đăng. Đo thời gian và số bước tay. Đạt khi 100 % trang, ảnh, tài liệu API được nhập, không script nào còn, và toàn bộ việc ≤ 1 ngày làm việc.

### 6.3. Diễn tập sự cố

Ba tình huống, có TA, SO tham gia: (1) nghi lộ bí mật sandbox: thu hồi, xoay, đối chiếu kiểm toán và TC-15-175; (2) PH-13 hỏng 2 giờ giữa giờ làm việc: thử production bị chặn, sandbox tiếp tục theo TC-15-133, cảnh báo vận hành; (3) tài khoản `dh-dev` lạm dụng sandbox: phát hiện qua `dh_portal_try_throttled_total`, khóa tài khoản và ứng dụng, đo thời gian có hiệu lực.

### 6.4. Kiểm thử truy cập thủ công

Với NVDA + Firefox và VoiceOver + Safari trên UI-15-02, 05, 06, 13: đi hết luồng chính, ghi lỗi theo WCAG 2.2; thêm một người dùng thật dùng điện thoại 360 px đi hết luồng tạo ứng dụng, cấp credential.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ quản trị portal Gravitee và nhà phát triển của tỉnh thí điểm tự thực hiện trên UAT. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Thấy API mới phát hành ở PH-02 xuất hiện trên cổng | LGC-APIM-006 | Hiện trong ≤ 30 giây, không ai cập nhật tay | FR-15-001, 002, 004 | TS-15-01, 02 |
| UAT-02 | Gỡ một API khỏi cổng rồi đăng lại | LGC-APIM-006 | Cờ ở PH-02 đổi thì cổng đổi theo trong ≤ 30 giây, kể cả tìm kiếm | FR-15-001, 002 | TS-15-02, 04 |
| UAT-03 | Công khai một API cho mọi người | LGC-APIM-007 | Bật công khai theo tenant, API vừa PUBLIC vừa dữ liệu công khai mới hiện cho khách, thêm mức NATIONAL | FR-15-002, 008, 056, 057 | TS-15-02, 27 |
| UAT-04 | Xem đường dẫn sử dụng của một API | LGC-APIM-017 | Gateway URL, context path, mẫu gọi ở một màn, đúng tenant | FR-15-006, 012 | TS-15-05, 06 |
| UAT-05 | Xem tài liệu API và tải đặc tả | LGC-APIM-017 | Tài liệu đọc được, chọn phiên bản, tải YAML, JSON, so sánh phiên bản | FR-15-009, 011, 013 | TS-15-06 |
| UAT-06 | Lấy token và gọi thử API | LGC-IAM-006 | Làm trong ≤ 15 phút bằng `client_credentials`, không dùng grant `password` | FR-15-012, 027, 035 | TS-15-14, 18, 37 |
| UAT-07 | Tạo ứng dụng và cấp credential tự phục vụ | LGC-IAM-006, LGC-APIM-019, LGC-APIM-020 | Ứng dụng sandbox và credential trong ≤ 3 giây, bí mật hiện một lần, giới hạn số lượng rõ ràng | FR-15-025, 027, 029 | TS-15-13, 14 |
| UAT-08 | Xem nhật ký lời gọi của ứng dụng mình | LGC-APIM-022 | Thấy trong 3 thao tác, dữ liệu nhạy cảm đã che, chỉ ứng dụng của mình | FR-15-049, 050 | TS-15-24 |
| UAT-09 | Chuyển trang hướng dẫn của portal cũ sang cổng mới | LGC-APIM-006 | Nhập từ gói xuất, trang vào dạng nháp, duyệt bốn mắt rồi đăng | FR-15-062, 015 | TS-15-09, 08 |
| UAT-10 | Gửi đăng ký sử dụng API production từ cổng | LGC-APIM-019, LGC-APIM-020 | Gửi và theo dõi ở một nơi, không phải gửi yêu cầu tay cho quản trị | FR-15-044, 045 | TS-15-23 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-15. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph15/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-15-001 | Đồng bộ danh mục dịch vụ từ PH-02 | M | LGC-APIM-006 | 001, 002, 003, 015, 205, 206 | 004, 005, 006 | 191, 197 | Có |
| FR-15-002 | Áp mức hiển thị theo người xem | M | LGC-APIM-007 | 007, 013, 014, 015 | 008, 010 | — | Có |
| FR-15-003 | Trang chủ cổng | M | mới | 016 | 005 | 017 | Có |
| FR-15-004 | Duyệt, lọc, sắp xếp danh mục dịch vụ | M | LGC-APIM-006 | 018, 021 | 019 | 189 | Có |
| FR-15-005 | Tìm kiếm toàn văn tiếng Việt và gợi ý | M | mới | 022, 023, 025 | 012, 024, 026, 173 | 189 | Có |
| FR-15-006 | Trang chi tiết dịch vụ, đường dẫn sử dụng  | M | LGC-APIM-017, LGC-IAM-006 | 021, 027 | 028, 031 | 030 | Có |
| FR-15-007 | Hiển thị dịch vụ sự kiện | S | mới | 020 | — | — | Có |
| FR-15-008 | Truy cập ẩn danh cổng công khai | M | LGC-APIM-007 | 009 | 010, 011, 012, 024 | 196 | Có |
| FR-15-009 | Hiển thị tài liệu OpenAPI 3.1 | M | mới | 032 | 006, 031, 034, 040 | 190, 199 | Có |
| FR-15-010 | Hiển thị tài liệu AsyncAPI 3.0 | S | mới | 033 | — | — | Có |
| FR-15-011 | Chọn phiên bản, tải đặc tả, so sánh phiên  | M | mới | 035, 036 | 031, 037 | — | Có |
| FR-15-012 | Sinh mẫu mã gọi API | M | LGC-APIM-017, LGC-IAM-006 | 038, 208 | 039 | — | Có |
| FR-15-013 | Changelog, lộ trình ngừng dùng và banner D | M | mới | 029 | 031 | — | Có |
| FR-15-014 | Soạn trang nội dung Markdown | M | mới | 041, 045 | 042, 043, 046, 047, 048, 181, 184 | 044 | Có |
| FR-15-015 | Gửi duyệt, duyệt và đăng trang | M | mới | 049, 051, 053 | 050, 052, 185, 204 | — | Có |
| FR-15-016 | Phiên bản trang, so sánh, khôi phục, gỡ đă | S | mới | 054, 055 | 052 | — | Có |
| FR-15-017 | Hiển thị trang nội dung | M | mới | 045, 049, 056 | 181 | — | Có |
| FR-15-018 | Nhập nội dung từ kho Git | S | mới | 057 | 058 | — | Có |
| FR-15-019 | Đăng nhập SSO realm tenant | M | mới | 061 | 062, 063, 177, 183, 186 | — | Có |
| FR-15-020 | Tự đăng ký tài khoản dh-dev | M | mới | 066 | 067, 068 | 069 | Có |
| FR-15-021 | Hồ sơ cá nhân và phiên đăng nhập | M | mới | 064 | 065 | — | Có |
| FR-15-022 | Nhóm phát triển | S | LGC-APIM-020 | 075 | 076 | — | Có |
| FR-15-023 | Chấp nhận điều khoản sử dụng có phiên bản | M | mới | 074 | 073 | — | Có |
| FR-15-024 | Vô hiệu hóa không hoạt động và xóa tài kho | S | mới | 077, 078 | — | — | Có |
| FR-15-025 | Tạo ứng dụng sandbox | M | LGC-APIM-020 | 079, 208 | 080 | 197 | Có |
| FR-15-026 | Xem, sửa, lưu trữ, khôi phục ứng dụng | M | LGC-APIM-020 | 082, 083 | 081 | 084 | Có |
| FR-15-027 | Cấp thông tin xác thực client_credentials  | M | LGC-IAM-006 | 087, 088, 208 | 091, 092, 175, 204 | 193 | Có |
| FR-15-028 | Cấp API key sandbox | M | LGC-APIM-011 | 089 | 091, 175 | — | Có |
| FR-15-029 | Hiển thị bí mật đúng một lần | M | mới | 087 | 090, 175, 178 | 200 | Có |
| FR-15-030 | Xoay vòng thông tin xác thực | M | mới | 093, 094, 206 | 095, 175, 204 | — | Có |
| FR-15-031 | Thu hồi và hết hạn thông tin xác thực | M | mới | 098 | 096, 097 | 194 | Có |
| FR-15-032 | Xem tham chiếu thông tin xác thực producti | M | mới | 099 | 100, 101 | — | Có |
| FR-15-033 | Giao ứng dụng cho thành viên | S | mới | 085 | 086 | — | Có |
| FR-15-034 | Khai báo sandbox của dịch vụ | M | mới | 102 | 103, 104 | — | Có |
| FR-15-035 | Thử API trên sandbox | M | mới | 105, 110, 206, 208 | 107, 108, 109, 133, 176, 179, 180 | 192 | Có |
| FR-15-036 | Chế độ sandbox MOCK | M | mới | 105, 106 | 107, 117 | 111, 192 | Có |
| FR-15-037 | Chế độ sandbox BACKEND | M | mới | 112 | 104, 113, 114 | — | Có |
| FR-15-038 | Dữ liệu mẫu tổng hợp và chặn dữ liệu cá nh | M | mới | 116 | 115, 117 | 111 | Có |
| FR-15-039 | Hạn mức sandbox | M | mới | 110 | 118, 119, 179 | 195 | Có |
| FR-15-040 | Lịch sử thử và bộ sưu tập yêu cầu | S | mới | 120, 121, 207 | 122, 176 | — | Có |
| FR-15-041 | Xuất Postman, Bruno, HTTP | C | mới | 123 | — | — | Có |
| FR-15-042 | Bật, tắt thử production theo dịch vụ | M | mới | 124, 125, 127 | 126, 184, 185 | — | Có |
| FR-15-043 | Thử API trên production | M | mới | 128 | 129, 130, 131, 132, 134 | 135 | Có |
| FR-15-044 | Gửi đăng ký sử dụng API production | M | LGC-APIM-016 | 136 | 137 | — | Có |
| FR-15-045 | Theo dõi đăng ký sử dụng | M | mới | 138 | 137 | — | Có |
| FR-15-046 | Điểm vào kết nạp HTTT (F-01) | M | LGC-APIM-019, LGC-APIM-020 | 139 | 140 | — | Có |
| FR-15-047 | Điểm vào công bố API (F-02) | M | mới | 141 | 142 | 017 | Có |
| FR-15-048 | Bảng điều khiển cá nhân | S | mới | 143 | — | — | Có |
| FR-15-049 | Thống kê lượt gọi và lỗi theo ứng dụng | M | LGC-APIM-022 | 144 | 145 | — | Có |
| FR-15-050 | Nhật ký gọi của ứng dụng đã che dữ liệu | S | LGC-APIM-022 | — | 146, 176 | — | Có |
| FR-15-051 | Đăng ký nhận thông báo thay đổi API | M | mới | 147 | 148 | — | Có |
| FR-15-052 | Hộp thông báo | M | mới | 147, 149, 207 | 150 | — | Có |
| FR-15-053 | Hỏi đáp, báo lỗi tài liệu, đánh giá trang | C | mới | 154 | — | — | Có |
| FR-15-054 | Gửi yêu cầu hỗ trợ cho chủ dịch vụ | M | mới | 151 | 153 | — | Có |
| FR-15-055 | Xử lý yêu cầu hỗ trợ | S | mới | 152 | 153 | — | Có |
| FR-15-056 | Cấu hình nhận diện cổng theo tenant | M | LGC-APIM-007 | 155 | 156, 162, 184 | — | Có |
| FR-15-057 | Tham số cổng | M | mới | 157 | 158, 162 | — | Có |
| FR-15-058 | Duyệt tài khoản dh-dev | M | mới | 070 | 071, 072, 184 | 197 | Có |
| FR-15-059 | Khóa, mở khóa tài khoản và ứng dụng | M | mới | 159, 160 | 161 | 194 | Có |
| FR-15-060 | Nhật ký truy cập, thử và báo cáo sử dụng c | M | mới | 163, 164, 165, 207 | 162, 166 | — | Có |
| FR-15-061 | Đồng bộ lại và đối soát danh mục với PH-02 | S | mới | 167, 169 | 168 | — | Có |
| FR-15-062 | Di trú nội dung portal hệ cũ | S | LGC-APIM-006 | 059 | 060 | — | Có |

: Yêu cầu chức năng và test case

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng portal hệ cũ (`LGC-APIM-006, 007, 017, 022`) và cấp credential tự phục vụ (`LGC-IAM-006`) được truy tới FR mới, ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-APIM-006 | 001, 004, 062 | 001, 002, 003, 004, 005, 006, 015, 018 (+6) | UAT-01, UAT-02, UAT-09 |
| LGC-APIM-007 | 002, 008, 056 | 007, 008, 009, 010, 011, 012, 013, 014 (+6) | UAT-03 |
| LGC-APIM-011 | 028 | 089, 091, 175 | — |
| LGC-APIM-016 | 044 | 136, 137 | — |
| LGC-APIM-017 | 006, 012 | 021, 027, 028, 030, 031, 038, 039, 208 | UAT-04, UAT-05 |
| LGC-APIM-019 | 046 | 139, 140 | UAT-07, UAT-10 |
| LGC-APIM-020 | 022, 025, 026, 046 | 075, 076, 079, 080, 081, 082, 083, 084 (+3) | UAT-07, UAT-10 |
| LGC-APIM-022 | 049, 050 | 144, 145, 146, 176 | UAT-08 |
| LGC-IAM-006 | 006, 012, 027 | 021, 027, 028, 030, 031, 038, 039, 087 (+7) | UAT-06, UAT-07 |

: Chức năng hệ cũ, yêu cầu và test case

### 8.3. Use case → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| UC-15-01 | 007, 008, 009, 010, 011, 013, 014, 016, 017, 018 (+1) |
| UC-15-02 | 022, 023, 024, 025 |
| UC-15-03 | 027, 028, 029, 030 |
| UC-15-04 | 001, 002, 003, 004, 005, 006, 015, 167, 169 |
| UC-15-05 | 032, 033, 034, 035, 036, 038, 040 |
| UC-15-06 | 041, 042, 043 |
| UC-15-07 | 049, 050, 051, 053, 054, 055 |
| UC-15-08 | 057, 059 |
| UC-15-09 | 056 |
| UC-15-10 | 061, 062, 063 |
| UC-15-11 | 066, 067 |
| UC-15-12 | 064, 073, 074, 077, 078 |
| UC-15-13 | 075, 085 |
| UC-15-14 | 079, 080, 081, 082, 083, 208 |
| UC-15-15 | 087, 089, 090, 092, 208 |
| UC-15-16 | 083, 093, 096, 098 |
| UC-15-17 | 099, 100 |
| UC-15-18 | 102, 103 |
| UC-15-19 | 105, 107, 108, 112, 113, 115, 116, 118, 133, 179 (+1) |
| UC-15-20 | 120, 121, 123 |
| UC-15-21 | 124, 125 |
| UC-15-22 | 128, 129, 132 |
| UC-15-23 | 136, 137, 138 |
| UC-15-24 | 139 |
| UC-15-25 | 141 |
| UC-15-26 | 143, 144, 146 |
| UC-15-27 | 147 |
| UC-15-28 | 151, 152, 154 |
| UC-15-29 | 155, 157 |
| UC-15-30 | 070, 071, 159, 160 |
| UC-15-31 | 163, 164, 165 |

: Use case và test case

### 8.4. Màn hình → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| UI-15-01 | 005, 009, 016, 017, 188, 198, 199, 202 |
| UI-15-02 | 004, 007, 009, 010, 014, 018, 020, 021, 188, 198 (+4) |
| UI-15-03 | 022, 198, 199, 202 |
| UI-15-04 | 009, 020, 027, 028, 029, 030, 154, 198, 199, 202 |
| UI-15-05 | 029, 032, 033, 034, 035, 036, 038, 188, 198, 199 (+3) |
| UI-15-06 | 030, 038, 105, 112, 115, 128, 135, 198, 199, 200 (+2) |
| UI-15-07 | 049, 056, 154, 181, 198, 199, 202 |
| UI-15-08 | 061, 062, 063, 066, 069, 177, 198, 199, 202 |
| UI-15-09 | 064, 074, 075, 198, 199, 202 |
| UI-15-10 | 079, 198, 199, 202 |
| UI-15-11 | 079, 198, 199, 202 |
| UI-15-12 | 085, 144, 146, 198, 199, 202 |
| UI-15-13 | 087, 090, 093, 099, 198, 199, 200, 201, 202 |
| UI-15-14 | 120, 121, 123, 198, 199, 202 |
| UI-15-15 | 136, 198, 199, 202 |
| UI-15-16 | 139, 198, 199, 202 |
| UI-15-17 | 141, 198, 199, 202 |
| UI-15-18 | 143, 198, 199, 202 |
| UI-15-19 | 147, 198, 199, 202 |
| UI-15-20 | 151, 198, 199, 202 |
| UI-15-21 | 041, 049, 057, 198, 199, 202 |
| UI-15-22 | 049, 054, 198, 199, 202 |
| UI-15-23 | 102, 125, 198, 199, 202 |
| UI-15-24 | 070, 159, 187, 198, 199, 202 |
| UI-15-25 | 155, 157, 162, 187, 198, 199, 202 |
| UI-15-26 | 162, 163, 165, 187, 198, 199, 202 |
| UI-15-27 | 001, 057, 059, 167, 198, 199, 202 |
| UI-15-28 | 152, 187, 198, 199, 202 |

: Màn hình và test case

### 8.5. Quy tắc nghiệp vụ → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| BR-15-001 | 001, 002, 003, 006, 015, 141, 169 |
| BR-15-002 | 003, 007, 008, 013, 014, 015, 021, 022, 024, 030 (+1) |
| BR-15-003 | 013, 170, 171, 172, 173, 174 |
| BR-15-004 | 007, 040, 100, 129 |
| BR-15-005 | 007, 009, 010, 011, 012, 024, 056 |
| BR-15-006 | 009, 011, 027 |
| BR-15-007 | 042, 076, 079 |
| BR-15-008 | 073, 074 |
| BR-15-009 | 079, 081, 082, 085, 144, 182 |
| BR-15-010 | 080, 083, 084, 091, 096 |
| BR-15-011 | 087, 088, 089, 090, 092, 093, 098, 123, 175, 178 |
| BR-15-012 | 048, 049, 050, 051, 053, 059, 185 |
| BR-15-013 | 043, 044, 045, 046, 059, 060, 181 |
| BR-15-014 | 136, 138, 139, 141 |
| BR-15-015 | 099, 100, 139 |
| BR-15-016 | 111, 115, 116, 117 |
| BR-15-017 | 102, 105, 106 |
| BR-15-018 | 102, 103, 104, 112, 113, 114 |
| BR-15-019 | 124, 125 |
| BR-15-020 | 126, 130, 131 |
| BR-15-021 | 125, 126, 127, 185 |
| BR-15-022 | 128, 129 |
| BR-15-023 | 132, 133, 164, 179 |
| BR-15-024 | 120, 128, 146, 163, 176 |
| BR-15-025 | 110, 118, 119 |
| BR-15-026 | 105, 109, 112 |
| BR-15-027 | 029, 147, 148 |
| BR-15-028 | 066, 070, 072, 077, 159 |
| BR-15-029 | 066, 078 |
| BR-15-030 | 151, 152, 154 |
| BR-15-031 | 158, 162, 187 |
| BR-15-032 | 016, 155, 156 |
| BR-15-033 | 004, 135 |
| BR-15-034 | 041, 047, 064, 081, 082, 170 |

: Quy tắc nghiệp vụ và test case

### 8.6. Mã lỗi → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| ERR-15-001 | 003, 008, 010, 011, 013, 020, 024, 037, 039, 040 (+11) |
| ERR-15-002 | 042, 076, 080 |
| ERR-15-003 | 019, 026, 037, 039, 042, 051, 065, 067, 071, 078 (+11) |
| ERR-15-004 | 062, 186 |
| ERR-15-005 | 048, 065, 069, 072, 081, 082, 086, 091, 097, 100 (+14) |
| ERR-15-006 | 047, 065, 082, 156, 158 |
| ERR-15-007 | 012, 026 |
| ERR-15-008 | 005 |
| ERR-15-009 | 006, 034 |
| ERR-15-010 | 073, 108 |
| ERR-15-011 | 062 |
| ERR-15-012 | 067 |
| ERR-15-013 | 067 |
| ERR-15-014 | 062, 077 |
| ERR-15-015 | 080 |
| ERR-15-016 | 091 |
| ERR-15-017 | 083, 091, 160, 161 |
| ERR-15-018 | 095, 097 |
| ERR-15-019 | 090 |
| ERR-15-020 | 063, 071, 091, 095 |
| ERR-15-021 | 043, 044 |
| ERR-15-022 | 052, 055, 071, 161 |
| ERR-15-023 | 050, 126, 185 |
| ERR-15-024 | 046, 058, 060 |
| ERR-15-025 | 058 |
| ERR-15-026 | 058, 060 |
| ERR-15-027 | 076, 086 |
| ERR-15-028 | 076, 078, 086 |
| ERR-15-029 | 153 |
| ERR-15-030 | 028, 137, 142, 168 |
| ERR-15-031 | 101, 140 |
| ERR-15-032 | 080, 137, 140 |
| ERR-15-033 | 156 |
| ERR-15-034 | 158 |
| ERR-15-035 | 060, 168 |
| ERR-15-036 | 162 |
| ERR-15-037 | 068, 153, 154 |
| ERR-15-038 | 031, 037 |
| ERR-15-039 | 145, 166 |
| ERR-15-040 | 103, 126 |
| ERR-15-101 | 102 |
| ERR-15-102 | 083, 108, 160 |
| ERR-15-103 | 110, 118 |
| ERR-15-104 | 119 |
| ERR-15-105 | 119 |
| ERR-15-106 | 115 |
| ERR-15-107 | 107 |
| ERR-15-108 | 113 |
| ERR-15-109 | 113 |
| ERR-15-110 | 107 |
| ERR-15-111 | 109 |
| ERR-15-112 | 124, 127, 135 |
| ERR-15-113 | 129 |
| ERR-15-114 | 130 |
| ERR-15-115 | 132, 133 |
| ERR-15-116 | 109, 131 |
| ERR-15-117 | 134 |
| ERR-15-118 | 134 |
| ERR-15-119 | 103, 104, 114 |
| ERR-15-120 | 103 |
| ERR-15-121 | 109 |
| ERR-15-122 | 030, 107 |
| ERR-15-123 | 119 |

: Mã lỗi và test case

### 8.7. Yêu cầu phi chức năng → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| NFR-15-001 | 188 |
| NFR-15-002 | 189 |
| NFR-15-003 | 190 |
| NFR-15-004 | 002, 191 |
| NFR-15-005 | 105, 192 |
| NFR-15-006 | 087, 193 |
| NFR-15-007 | 094, 096, 160, 179, 194 |
| NFR-15-008 | 004, 025, 063, 132, 179, 203, 204 |
| NFR-15-009 | 175, 176, 178 |
| NFR-15-010 | 177, 183 |
| NFR-15-011 | 043, 181 |
| NFR-15-012 | 189, 197 |
| NFR-15-013 | 195 |
| NFR-15-014 | 198, 199, 200, 201 |
| NFR-15-015 | 202 |
| NFR-15-016 | 078, 120, 149, 207 |
| NFR-15-017 | 008, 081, 122, 145, 150, 166, 170, 171, 172, 173 (+3) |
| NFR-15-018 | 196 |
| NFR-15-019 | 205 |
| NFR-15-020 | 093, 206 |
| NFR-15-021 | 202 |
| NFR-15-022 | 038, 208 |

: Yêu cầu phi chức năng và test case

### 8.8. Sự kiện → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| EVT-15-01 | 079, 174, 203 |
| EVT-15-02 | 083, 084, 160, 203 |
| EVT-15-03 | 087, 092, 203 |
| EVT-15-04 | 093 |
| EVT-15-05 | 083, 094, 096, 098, 203 |
| EVT-15-06 | 066 |
| EVT-15-07 | 070, 077, 159 |
| EVT-15-08 | 049, 203 |
| EVT-15-09 | 055 |
| EVT-15-10 | 125, 127 |
| EVT-15-11 | 105, 128, 203 |
| EVT-15-12 | 151 |
| EVT-15-13 | 075, 085 |
| EVT-15-14 | 001, 002, 004, 015, 203 |

: Sự kiện và test case

### 8.9. API → test case

Mỗi mã và ba chữ số cuối của các TC-15 phủ nó; dấu — là chưa có ca.

| Mã | Test case |
|---|---|
| API-15-001 | 016 |
| API-15-002 | 016 |
| API-15-003 | 007, 009, 010 |
| API-15-004 | 008, 009, 010, 011, 170 |
| API-15-005 | 005, 007, 013, 018, 019, 021, 171 |
| API-15-006 | 018 |
| API-15-007 | 008, 013, 027 |
| API-15-008 | 008, 027, 028 |
| API-15-009 | 001 |
| API-15-010 | 009, 011, 012, 024 |
| API-15-011 | 008, 022, 024, 025, 026 |
| API-15-012 | 008, 023, 026 |
| API-15-013 | 020 |
| API-15-014 | 020 |
| API-15-015 | 008, 029, 031, 035 |
| API-15-016 | 006, 008, 031, 032, 034, 035, 040 |
| API-15-017 | 032, 034 |
| API-15-018 | 020, 033 |
| API-15-019 | 038, 039 |
| API-15-020 | 036, 037 |
| API-15-021 | 029, 031 |
| API-15-022 | 041, 048 |
| API-15-023 | 041, 042, 048, 184 |
| API-15-024 | 041, 170 |
| API-15-025 | 043, 044, 047 |
| API-15-026 | 049, 052 |
| API-15-027 | 049, 050, 052 |
| API-15-028 | 051 |
| API-15-029 | 052, 055 |
| API-15-030 | 054 |
| API-15-031 | 054 |
| API-15-032 | 054 |
| API-15-033 | 045, 046 |
| API-15-034 | 056 |
| API-15-035 | 055, 056 |
| API-15-036 | 056 |
| API-15-037 | 049, 056 |
| API-15-038 | 057 |
| API-15-039 | 057 |
| API-15-040 | 057, 058 |
| API-15-041 | 061, 064, 077 |
| API-15-042 | 064, 065 |
| API-15-043 | 064 |
| API-15-044 | 064, 065 |
| API-15-045 | 066, 067, 068 |
| API-15-046 | 066, 067 |
| API-15-047 | 073, 074 |
| API-15-048 | 073, 074 |
| API-15-049 | 075 |
| API-15-050 | 075, 076 |
| API-15-051 | 075, 076 |
| API-15-052 | 075 |
| API-15-053 | 076 |
| API-15-054 | 078 |
| API-15-055 | 079, 081, 171 |
| API-15-056 | 073, 079, 080, 184 |
| API-15-057 | 079, 081, 170, 182 |
| API-15-058 | 081, 082 |
| API-15-059 | 083 |
| API-15-060 | 083 |
| API-15-061 | 087, 090 |
| API-15-062 | 087, 088, 089, 090, 091, 182 |
| API-15-063 | 093, 094, 095 |
| API-15-064 | 096, 097 |
| API-15-065 | 099, 100, 101 |
| API-15-066 | 085 |
| API-15-067 | 085, 086 |
| API-15-068 | 085, 086 |
| API-15-069 | 102 |
| API-15-070 | 102, 103, 104 |
| API-15-071 | 107, 111, 115 |
| API-15-072 | 073, 104, 105, 106, 107, 108, 109, 111, 112, 113 (+13) |
| API-15-073 | 105, 170, 182 |
| API-15-074 | 118 |
| API-15-075 | 120, 171 |
| API-15-076 | 120 |
| API-15-077 | 121, 122, 170 |
| API-15-078 | 121, 122, 182 |
| API-15-079 | 121, 122 |
| API-15-080 | 121 |
| API-15-081 | 123 |
| API-15-082 | 093, 096, 110, 174, 179, 180 |
| API-15-083 | 124 |
| API-15-084 | 125, 126, 184 |
| API-15-085 | 125, 126 |
| API-15-086 | 127 |
| API-15-087 | 136, 137 |
| API-15-088 | 137, 138 |
| API-15-089 | 136, 138, 170 |
| API-15-090 | 138 |
| API-15-091 | 139, 140 |
| API-15-092 | 139 |
| API-15-093 | 139, 170 |
| API-15-094 | 141, 142 |
| API-15-095 | 141 |
| API-15-096 | 141, 170 |
| API-15-097 | 143 |
| API-15-098 | 144, 145 |
| API-15-099 | 146 |
| API-15-100 | 146, 182 |
| API-15-101 | 147 |
| API-15-102 | 147, 148 |
| API-15-103 | 147 |
| API-15-104 | 147, 150, 171 |
| API-15-105 | 149, 150, 182 |
| API-15-106 | 149 |
| API-15-107 | 154 |
| API-15-108 | 154 |
| API-15-109 | 154 |
| API-15-110 | 151, 153 |
| API-15-111 | 151, 171 |
| API-15-112 | 151, 153, 170, 182 |
| API-15-113 | 151, 153 |
| API-15-114 | 152, 153 |
| API-15-115 | 152 |
| API-15-116 | 155 |
| API-15-117 | 155, 156, 184 |
| API-15-118 | 155, 156 |
| API-15-119 | 157 |
| API-15-120 | 157, 158 |
| API-15-121 | 070, 072, 171 |
| API-15-122 | 070, 071, 072, 184 |
| API-15-123 | 071 |
| API-15-124 | 072, 159, 161 |
| API-15-125 | 159 |
| API-15-126 | 160, 161 |
| API-15-127 | 160 |
| API-15-128 | 163, 164, 166, 171, 184 |
| API-15-129 | 165, 166 |
| API-15-130 | 165 |
| API-15-131 | 001, 167, 168 |
| API-15-132 | 167 |
| API-15-133 | 169 |
| API-15-134 | 169 |
| API-15-135 | 059, 060 |
| API-15-136 | 059 |
| API-15-137 | 059, 060 |
| API-15-138 | 045 |
| API-15-139 | 155 |
| API-15-140 | 143, 147 |
| API-15-141 | 080 |
| API-15-142 | 054 |

: API và test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Mã kiểm thử đặt cạnh mã nguồn theo mức.

| Thư mục | Nội dung |
|---|---|
| `apps/connect/src/test/java/vn/datahub/connect/portal/` | UT, IT; lớp cơ sở `PortalTestBase` (Testcontainers PostgreSQL 16, Valkey, OpenSearch, Keycloak, Kafka, ClamAV) |
| `apps/portal/src/**/*.test.ts` | UT frontend (Vitest) |
| `e2e/portal/ts-15-nn.spec.ts` | Playwright, bốn trình duyệt |
| `perf/portal/*.js` | k6 |
| `chaos/portal/*.yaml` | Chaos Mesh |
| `datahub-docs/03-thiet-ke/csdl/ph15/test/` | Bài kiểm cô lập CSDL |
| `datahub-docs/05-kiem-thu/test-case/ph15/gherkin/` | Gherkin sinh từ tài liệu này |

: Tổ chức mã kiểm thử

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-15-nnn")`, `test('TC-15-nnn …')`).

### 9.2. Mẫu ca dò mồi bí mật (JUnit)

Mẫu cho nhóm ca không lộ bí mật, dựa trên TC-15-175.

```java
@Tag("canary") @Tag("TC-15-175")
@Test void sandboxSecretIsShownOnce() {
  var canary = "DH-CANARY-cs-" + UUID.randomUUID();
  keygen.useFixed(canary);                       // móc kiểm thử thay bộ sinh khóa
  var cred = api.as(U_T68_DEV_AN)
      .post("/apps/app-tra-cuu-ho-tich/credentials", Map.of("kind", "API_KEY"))
      .then().statusCode(201).extract();
  assertThat(cred.path("secret").toString()).contains(canary);   // lần cấp duy nhất
  api.as(U_T68_DEV_AN).get("/apps/app-tra-cuu-ho-tich/credentials").then().body(not(containsString(canary)));
  assertThat(loki.query("{namespace=~\"dh-.*\"}", Duration.ofMinutes(5))).doesNotContain(canary);
  assertThat(db.dumpSchema("ph15_portal")).doesNotContain(canary);
  assertThat(kafka.readAll("t68\\.portal\\..*", Duration.ofSeconds(10))).doesNotContain(canary);
}
```

### 9.3. Mẫu ca không token ở trình duyệt (Playwright)

Mẫu cho ca đầu cuối kiểm không có token ở trình duyệt.

```ts
test('TC-15-177 không có token trong bộ nhớ trình duyệt', async ({ page }) => {
  await loginAs(page, 'U-T68-OR');
  const dump = await page.evaluate(() => JSON.stringify({ ...localStorage, ...sessionStorage }));
  expect(dump).not.toMatch(/access_token|refresh_token|eyJ[A-Za-z0-9_-]{10,}/);
  const cookies = await page.context().cookies();
  for (const c of cookies.filter(c => /session/i.test(c.name))) {
    expect(c.httpOnly).toBe(true); expect(c.secure).toBe(true);
  }
});
```

### 9.4. Sinh ma trận, Gherkin, bảng tính

Các lệnh dưới đây chạy trong thư mục `ph15/tools/` và sinh mọi phần tự động của tài liệu.

| Lệnh | Kết quả |
|---|---|
| `python3 ph15/tools/number_tcs.py` | Cấp số `TC-15-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph15/tools/fill_doc.py` | Ghi mục 3.1, số kịch bản, số ca và mục 8 (gọi `gen_matrix.py`; in ra stderr UC, UI, BR, ERR, NFR, EVT, API chưa có ca) |
| `python3 ph15/tools/gen_gherkin.py` | `ph15/gherkin/ts-15-nn.feature` và `uat-tuong-duong-portal.feature` |
| `python3 ph15/tools/gen_xlsx.py` | `ph15/D05-02-PH15-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

## 10. Câu hỏi mở

> **Câu hỏi mở Q15-40:** Khi `15.public.enabled = false`, các API `/public/*` trả `404` ERR-15-001 (ngầm định của TC TC-15-010) hay mã khác; và khi tên miền cổng và token thuộc hai tenant khác nhau thì trả `401` hay `403` ERR-15-005 (TC TC-15-172)? Cần FRS chốt để ca khỏi dựa giả định.

> **Câu hỏi mở Q15-41:** FRS chưa nêu mã lỗi khi trang vượt 200 KB (TC TC-15-044 giả định `422` ERR-15-021, có thể là `413`), và khi `15.dev.signup-enabled = false` thì API trả gì (TC TC-15-069 giả định `403` ERR-15-005). Ngầm định: như hai ca.

> **Câu hỏi mở Q15-42:** Nhà phát triển `dh-dev` (không thuộc HTTT nào) thử production nhận ERR-15-113 (không có đăng ký ACTIVE) hay ERR-15-005; TC TC-15-129 giả định ERR-15-113 để câu thông báo không lộ lý do cấu trúc. Ngầm định: ERR-15-113.

> **Câu hỏi mở Q15-43:** Khi danh mục quá 24 giờ chưa đồng bộ (BR-15-033), UI ẩn nút thử production nhưng API trả mã nào (TC TC-15-135 giả định `403` ERR-15-112)? Có cần mã riêng cho "dữ liệu cũ" không? Ngầm định: ERR-15-112.

> **Câu hỏi mở Q15-44:** Bộ luật PII-15 chặn mã số thuế 10 hoặc 13 chữ số, số CMND 9 chữ số: mọi chuỗi số 9 hay 10 chữ số trong thân thử đều bị coi là DLCN, gây dương tính giả cho mã đơn vị hay mã bưu điện hợp lệ. Cần chốt ngưỡng chấp nhận dương tính giả và cơ chế để chủ dịch vụ khai trường được miễn (nếu có) trước khi lập tập kiểm dương tính giả cho TC-15-115. Ngầm định: không miễn trừ, nhà phát triển dùng dải giả.

## Đề nghị đồng bộ

Các điểm sau cần tài liệu gốc chốt hoặc chỉnh để ca kiểm thử khỏi dựa giả định.

| Tài liệu | Đề nghị | Lý do |
|---|---|---|
| D02-03-PH15 §9.1 | Thêm ERR cho "trang vượt cỡ" hoặc nêu rõ dùng ERR-15-021; nêu mã khi `15.public.enabled = false` và `15.dev.signup-enabled = false` | Ca TC-15-044, TC-15-010, TC-15-069 đang dùng giả định (Q15-40, 41) |
| D02-03-PH15 §9.3 | Đưa API-15-138 (`GET /content/attachments/{attachmentId}`), 139 (`GET /public/branding`), 140 (`GET /inbox/unread-count`), 141 (`GET /apps:check-code`), 142 (`GET /content/pages/{pageCode}/diff`) vào bảng tóm lược khi FRS lên 0.2 | Ma trận mục 8.9 và ca TC-15-045, TC-15-155, TC-15-143, TC-15-054 dùng các mã này; API-15-141 chưa có ca vì chưa rõ luồng UI dùng (tạo ứng dụng kiểm mã) và sẽ thêm khi FRS 0.2 chốt |
| D02-03-PH15 FR-15-043 | Ghi rõ mã lỗi cho `dh-dev` thử production và khi danh mục quá 24 giờ | Q15-42, 43 |
| D02-03-PH15 Phụ lục A.7 | Bổ sung ngưỡng dương tính giả chấp nhận được và cơ chế miễn trừ của PII-15 | Q15-44 |
| D05-01 | Ghi bộ giả lập dùng chung cho SIT của PH-15: Mailpit, WireMock cho PH-01, PH-02, PH-13, APISIX production giả lập, bộ đồng hồ giả lập | Mục 2.5, 1.3 |
| D02-08 | Giữ ma trận `PERM-15-*` như đã chốt; TC TC-15-184 sinh ma trận ca từ D02-08 nên cần giữ đồng bộ khi D02-08 đổi | Tránh ca lệch quyền |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 37 kịch bản, 10 UAT; công cụ sinh ma trận, Gherkin, bảng tính chép từ ph05 và chỉnh cho PH-15 (UC, UI, EVT hai chữ số; thêm ma trận UC, UI, EVT, API) |
