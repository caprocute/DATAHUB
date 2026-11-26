---
ma_tai_lieu: D05-02-PH02
ten: Kịch bản và test case phân hệ PH-02 Danh mục dịch vụ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-02
mo_ta: Kịch bản và test case của phân hệ Danh mục dịch vụ (danh mục API, gói sử dụng, đăng ký sử dụng, đồng bộ quốc gia), chạy được trên SIT với bộ dữ liệu mẫu, kèm UAT tương đương APIM cũ và ma trận truy vết.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH02 FRS; D02-04-PH02 Use case; D03-02-PH02 SDD; D03-04-PH02 API; D03-06-PH02 Màn hình
---

# D05-02-PH02 · Kịch bản và test case Danh mục dịch vụ

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-02 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH02 (62 FR, 40 BR, 45 mã lỗi `ERR-02-*`, 20 NFR).
- Không mất chức năng quản lý API, gói (plan), đăng ký sử dụng (subscription), endpoint backend của APIM cũ (LGC-APIM-001…006, 008…011, 016…018, 021; LGC-BUS-028), đồng thời các điểm nâng cấp (đặc tả OpenAPI bắt buộc, duyệt bốn mắt, kiểu xác thực theo mức phân loại) hoạt động.
- Không có đường nào để một API chưa duyệt đến gateway, một đăng ký chưa duyệt có phạm vi truy cập, bí mật hay dữ liệu cá nhân thật nằm trong đặc tả đi ra danh mục, hay tenant này thấy hợp đồng API của tenant khác.

**Phạm vi.** Gồm <!--gen:so-ts-->28<!--/gen--> kịch bản (TS-02-01…) với <!--gen:so-tc-->168 (TC-02-001…168; 102 ca P1)<!--/gen--> test case và 16 kịch bản nghiệm thu người dùng (UAT-01…16: 12 tương đương hệ cũ, 4 cho chức năng mới). Mỗi FR mức M có ít nhất một ca dương và một ca âm; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph02/tools/gen_matrix.py`.

**Căn cứ.** Bộ tài liệu PH-02 (FRS D02-03-PH02, use case D02-04-PH02, SDD D03-02-PH02, CSDL D03-03-PH02, API D03-04-PH02, màn hình D03-06-PH02); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP, TCVN 14423:2026; nghĩa vụ công bố danh mục dịch vụ chia sẻ theo CMP-LAW-03, CMP-LAW-19.

**Điểm cần hội đồng lưu ý.** Bốn nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- không để bí mật hay dữ liệu cá nhân thật trong đặc tả lọt qua cổng công bố, kiểm bằng giá trị mồi `DH-CANARY` (TS-02-06, TS-02-25);
- cách ly tenant ở mọi API đọc, ghi (`404` cùng thân, TS-02-25);
- bốn mắt cho công bố API, gói, ngừng dùng, đăng ký mức `RESTRICTED` trở lên (TS-02-11, 14, 16);
- phạm vi truy cập chỉ sinh từ đăng ký `ACTIVE`, không có đường cấp tay, và thu hồi có hiệu lực ở gateway trong 30 giây (TS-02-17, 18, TS-02-24).

**Độ phủ.** Mọi FR (62, trong đó 50 mức M), mọi operation API (95), mọi mã lỗi `ERR-02-*` (45), mọi quy tắc BR (40), mọi use case (38) và mọi màn UI-02 (17) có ít nhất một ca; mỗi FR mức M có ca dương và ca âm; mỗi operation có ca âm hoặc ca cách ly tenant. Chỉ số cụ thể ở các bảng mục 8 (sinh tự động). Ngoài ca chức năng, tài liệu có ca biên (độ dài mã, 10 MiB, ngưỡng SLA, mốc nhắc), ca bảng tham số hóa (ma trận kiểu xác thực, ma trận scope, `If-Match`, `Idempotency-Key`), ca khả dụng (tắt từng dịch vụ phụ thuộc, dừng tiến trình giữa lúc công bố) và 9 ca giao diện (TS-02-28).

Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT) và giả định GĐ-02-01 của FRS PH-02 (khoảng 180 API công bố, 640 đăng ký) vì chưa có dữ liệu thật.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu là tập 7 của bộ PH-02. Ca được viết để chạy ngay trên SIT với bộ dữ liệu ở chương 2, không cần hỏi lại, và để chứng minh PH-02 làm đúng các FR, quy tắc, mã lỗi và chỉ tiêu phi chức năng đã duyệt ở D02-03-PH02. Phạm vi gồm danh mục API, gói sử dụng, đăng ký sử dụng, đồng bộ quốc gia, SLA, di trú từ APIM cũ và cách ly tenant.

### 0.2. Người đọc

Kiểm thử viên (viết và chạy ca), kỹ sư (viết ca tự động), cán bộ ATTT (ca TS-02-06, 25) và chủ đầu tư (nghiệm thu UAT ở chương 7).

### 0.3. Thuật ngữ và chữ viết tắt

**API** là một dịch vụ đã khai báo trong danh mục; **phiên bản** (version) mang vòng đời `DRAFT`, `PENDING`, `PUBLISHED`, `SUSPENDED`, `DEPRECATED`, `RETIRED`; **gói** (plan) mang `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED`; **đăng ký** (subscription) mang `PENDING`, `ACTIVE`, `SUSPENDED`, `REJECTED`, `CANCELLED`, `REVOKED`, `EXPIRED`; **CA** là cán bộ duyệt; **SV** là chủ dịch vụ; **OR** là đại diện HTTT khai thác.

### 0.4. Tài liệu tham chiếu

D05-01 (kế hoạch kiểm thử tổng thể), D02-03-PH02 (FRS), D02-04-PH02 (use case), D03-02-PH02 (SDD), D03-04-PH02 (API và OpenAPI), D03-06-PH02 (màn hình), D03-03-PH02 (CSDL, bài kiểm cô lập), D03-07 (biện pháp ATTT `SEC-*`).

### 0.5. Cấu trúc tài liệu

Chương 1 nêu phạm vi, chiến lược, mức kiểm thử và tiêu chí vào, ra; chương 2 dữ liệu kiểm thử; chương 3 tổng quan 28 kịch bản `TS-02-*`; chương 4 ca chức năng; chương 5 ca phi chức năng và xuyên suốt; chương 6 thủ tục kiểm thử thủ công; chương 7 nghiệm thu người dùng tương đương hệ cũ; chương 8 ma trận truy vết FR, quy tắc, mã lỗi, NFR sang ca; chương 9 tự động hóa và tệp đi kèm.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Kiểm thử phân hệ PH-02 trong `dh-connect` (schema `ph02_catalog`): 95 operation REST dưới `/api/catalog/v1` (API-02-001…095), 17 màn UI-02-01…17, bộ đồng bộ quốc gia, bộ cấp phạm vi, bộ đối soát gateway. Ngoài phạm vi: thực thi chính sách tại gateway (PH-03, chỉ kiểm hiệu lực cấu hình qua gateway giả), hồ sơ HTTT (PH-01), cổng nhà phát triển (PH-15).

### 1.2. Mức kiểm thử

Bảng dưới nêu từng mức kiểm thử, phạm vi, công cụ và cổng CI hoặc cổng phát hành tương ứng.

| Mức | Phạm vi | Công cụ | Cổng |
|---|---|---|---|
| UT | Quy tắc BR, máy trạng thái, so sánh phiên bản, bộ luật quy ước | JUnit 5 | CI-2 |
| IT, DB | Dịch vụ với PostgreSQL thật, RLS, outbox | Testcontainers | CI-3 |
| CT | Hợp đồng với PH-03, PH-04, PH-14, PH-15 | Pact | CI-5 |
| API | Mọi operation, ca dương, âm, phân quyền | REST Assured | CI-4 |
| E2E | Luồng người dùng trên UI-02-* | Playwright, axe | CI-6 |
| k6, Chaos | Hiệu năng, tắt `dh-connect` | k6, Chaos Mesh | RG-3 |
| Thủ công | Khám phá, diễn tập di trú, UAT | Theo mục 6, 7 | RG-4 |

: Mức kiểm thử và công cụ

### 1.3. Môi trường kiểm thử

SIT: cụm `dh-connect` ba bản sao, PostgreSQL có RLS, Kafka, Apicurio, OpenBao, ba bản sao APISIX giả lập cấu hình (M-GW), Nền tảng quốc gia giả (M-NSP), PH-04 giả (M-FLOW), máy chủ phát đặc tả giả (M-URL). Tải hiệu năng chạy ở môi trường PERF với bộ dữ liệu quy mô tỉnh vừa (2.000 API, 10.000 phiên bản, 20.000 đăng ký). Tham số mặc định `02.*` theo FRS §8.2 trừ khi ca ghi khác.

### 1.4. Tiêu chí vào và ra

Các tiêu chí dưới đây quyết định khi nào bắt đầu và khi nào được coi là xong từng đợt kiểm thử.

- **Vào:** bản dựng qua CI-1…4; migration chạy sạch; dữ liệu mục 2 nạp được bằng `seed-ph02.sh`.
- **Ra RG-3:** 100 % ca P1 đạt, ≥ 95 % ca P2 đạt, không còn lỗi mức nghiêm trọng, NFR-02-001…006 đạt ở PERF.
- **Ra RG-4 (UAT):** 16 UAT đạt, không lỗi P1 mở.

### 1.5. Quy ước mã và cách trình bày

Kịch bản `TS-02-nn`, test case `TC-02-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi ca là một khối `::: dac-ta`. Các ca viết bổ sung ở lượt hoàn thiện bản 0.1 (từ `TC-02-084`) nằm trong kịch bản theo chủ đề nên số trong một kịch bản không liền mạch; thứ tự đọc theo kịch bản, tra theo ma trận mục 8.

- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập. Ca tham số hóa (bảng) ghi "bảng tham số hóa" ở tên ca; mỗi dòng của bảng là một lần chạy riêng ở báo cáo.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, CT, API, E2E, k6, Chaos, hoặc "Thủ công".
- Đường dẫn API tương đối với `/api/catalog/v1`.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-02-014 (thiếu quyền `PERM-02-*`) |
| 404-ẩn | `404` với ERR-02-001, thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` (BR-02-033) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, có giá trị trước và sau (BR-02-028) |
| EVT: `{tên}` | Đúng một bản tin trên topic `t68.catalog.{tên}.v1` (CloudEvents, có `dhtenant`) |
| EVT: không | Sau 10 giây không có dòng mới trong `ph02_catalog.outbox` |
| GW: nạp `{x}` | M-GW nhận cấu hình `x` trong ≤ 30 giây và gửi xác nhận API-02-082 |
| Mồi sạch | Chuỗi `DH-CANARY-{ca}` không xuất hiện trong phản hồi API, log 5 phút, vết OTel, bảng `ph02_catalog.*`, outbox, Kafka, danh mục cho máy |

: Quy ước mã và cách trình bày

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi ở công cụ theo dõi dự án với nhãn `PH-02` và mã ca. Báo cáo ngày gồm số ca chạy, đạt, không đạt, chặn theo kịch bản; báo cáo cuối đợt lấy từ tệp `.xlsx` mục 9.

## 2. Dữ liệu kiểm thử

### 2.1. Tenant

Bảng dưới nêu các tenant dùng trong ca kiểm thử và mục đích của từng tenant.

| Mã | Dùng cho |
|---|---|
| T68 | Tenant chính của mọi ca |
| T01 | Tenant đối chứng rò rỉ chéo, ca liên tenant |
| T91 | Tenant rỗng (không dữ liệu) cho ca trạng thái rỗng ở giao diện |
| COMMON | Chỉ để kiểm danh mục chia sẻ toàn quốc |

: Tenant kiểm thử

### 2.2. Người dùng

Bảng dưới nêu người dùng và tài khoản dịch vụ kiểm thử, kèm vai trò, để mỗi ca chỉ cần gọi theo mã.

| Mã | Tenant | Vai trò | Mục đích |
|---|---|---|---|
| U-PA | PLATFORM | PA | Quản trị nền, quyền admin |
| U-T68-TA | T68 | TA | Quản trị tenant, chuyển chủ quản, di trú, tham số |
| U-T68-SV1 | T68 | SV | Chủ dịch vụ của Sở TN&MT |
| U-T68-SV2 | T68 | SV | Chủ dịch vụ của Sở Tư pháp (đối chứng "tổ chức khác") |
| U-T68-CA | T68 | CA | Người duyệt |
| U-T68-CA2 | T68 | CA | Người duyệt thứ hai |
| U-T68-SV-CA | T68 | SV + CA (cố ý cấu hình sai, chỉ có ở SIT) | Kiểm lớp bốn mắt độc lập với lớp tách vai trò |
| U-T68-TO | T68 | TO | Vận hành, đồng bộ quốc gia |
| U-T68-SO | T68 | SO | Tạm ngừng khẩn ATTT |
| U-T68-OR1 | T68 | OR | Đại diện HTTT khai thác HT-KHAITHAC-1 |
| U-T68-VW | T68 | VW (chỉ `PERM-02-read`) | Chỉ đọc |
| U-T68-AU | T68 | AU | Kiểm toán |
| U-T01-SV | T01 | SV | Đối chứng rò rỉ |
| S-GW, S-GW-ACK, S-FLOW, S-PORTAL, S-METRIC | — | Tài khoản dịch vụ | Scope `catalog:gateway-read` (S-GW), `catalog:gateway-ack` (S-GW-ACK, chỉ xác nhận nạp cấu hình), `catalog:flow-sync`, `catalog:portal-read`, `catalog:metrics-read` |

: Người dùng kiểm thử

### 2.3. HTTT, API, gói, đăng ký mẫu

Bảng dưới nêu hệ thống thông tin, API, gói và đăng ký mẫu dùng làm dữ liệu nền của các ca.

| Mã | Nội dung |
|---|---|
| H-CUNGCAP-1 | HTTT `ACTIVE` của Sở TN&MT, cung cấp API |
| H-KHAITHAC-1 | HTTT `ACTIVE` của Sở Tư pháp, khai thác; H-KHAITHAC-2 ở trạng thái `PENDING` ở PH-01 |
| A-DATDAI | API `tc-dat-dai` phiên bản 1.0.0 `PUBLISHED`, mức dữ liệu `INTERNAL`, 2 gói (`goi-co-ban` `API_KEY`, `goi-mtls` `OAUTH2_MTLS`) |
| A-DRAFT | API `tc-nhap` phiên bản 1.0.0 `DRAFT`, có backend và gói đủ điều kiện gửi duyệt |
| A-DEPREC | API `tc-cu` 1.0.0 `DEPRECATED` có đăng ký `ACTIVE`, kế nhiệm `tc-cu` 2.0.0 `PUBLISHED` |
| A-T01 | API `tc-chi-t01` chỉ có ở T01 |
| SUB-ACTIVE | Đăng ký `ACTIVE` của H-KHAITHAC-1 vào `tc-dat-dai/goi-co-ban` |

: Dữ liệu API, gói, đăng ký

### 2.4. Tệp đặc tả mẫu

Bảng dưới nêu các tệp đặc tả OpenAPI mẫu, mỗi tệp đại diện một tình huống hợp lệ hoặc có lỗi.

| Mã | Nội dung |
|---|---|
| F-SPEC-OK | OpenAPI 3.1 hợp lệ, 120 dòng, mô tả tiếng Việt, đạt lớp 1 và lớp 2 |
| F-SPEC-SW2 | Swagger 2.0 hợp lệ |
| F-SPEC-L1 | Thiếu `info.version`, `$ref` hỏng (không đạt lớp 1) |
| F-SPEC-L2 | Hợp lệ lớp 1, thiếu `operationId`, thiếu mô tả tổng thể, vi phạm quy ước đặt tên |
| F-SPEC-SECRET | Ví dụ chứa khóa PEM, JWT, `https://u:p@host`, giá trị `DH-CANARY-…` |
| F-SPEC-PII | Ví dụ chứa số CCCD, số điện thoại thật (đã sinh ngẫu nhiên hợp lệ định dạng) |
| F-SPEC-BOMB | YAML alias lồng nhau (bom), độ sâu `$ref` > 50 |
| F-SPEC-BIG | 11 MiB; F-SPEC-5K: 5.000 dòng; F-SPEC-10M: 10 MiB |
| F-SPEC-STATE | Đặc tả khai `x-dh-stateSecret: true` |
| F-APIM-EXPORT | Gói xuất APIM cũ 12 API, 20 gói, 35 subscription, đã ẩn danh |

: Tệp đặc tả và gói xuất mẫu

Bộ ghép giả: M-URL phục vụ đặc tả ở `https://spec.sit.local/…` (có kịch bản trả chậm, chuyển hướng tới địa chỉ nội bộ); M-NSP trả `202` hoặc `422` theo cờ; M-GW chậm hoặc từ chối theo cờ.

### 2.5. Nguyên tắc dữ liệu

Mỗi kịch bản tự tạo dữ liệu riêng với tiền tố `tc-{khóa ca}`, dọn sau ca bằng xóa mềm cộng `seed-ph02.sh --reset`. Không dùng dữ liệu thật của tỉnh; mọi số CCCD, điện thoại là chuỗi sinh ngẫu nhiên.

### 2.6. Dữ liệu và bộ giả bổ sung

Bảng dưới nêu dữ liệu và bộ giả (mock) bổ sung cho các phân hệ chưa sẵn sàng, kèm kịch bản dùng chúng.

| Mã | Nội dung | Dùng ở |
|---|---|---|
| S-FLOW-T01 | Tài khoản dịch vụ `catalog:flow-sync` của T01 | TS-02-07 |
| M-TOPIC | PH-10 giả: topic `tc-su-kien-t68`, `tc-su-kien-t01` | TS-02-02 |
| M-MAIL | Thư điện tử giả có độ trễ điều chỉnh được | TS-02-27 |
| Cờ đóng băng | Cờ đóng băng thay đổi PROD đặt trong thời gian chạy, kèm đồng hồ giả | TS-02-12 |
| Đồng hồ giả | Tiến thời gian cho bộ nhắc duyệt, mốc ngừng dùng, rà soát đăng ký, đồng bộ quá hạn, dọn lưu giữ | TS-02-14, 18, 19, 20, 27 |
| `tc-cu` 0.9.0 | Phiên bản `RETIRED`, đặc tả còn tải được | TS-02-01 |
| `tc-nhom-a`, `tc-nhom-a1`, `tc-nhom-da-xoa` | Nhóm phân loại có API, có con, đã xóa | TS-02-03 |
| 4 API theo mức dữ liệu | Một API mỗi mức `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` | TS-02-09 |
| Biến thể F-APIM-EXPORT | Thiếu trường, tệp cụt, quá lớn, có khóa mồi | TS-02-23 |
| Hồ sơ PERF nhỏ | 1.000 API, 100 người dùng (chạy bền 8 giờ) | TS-02-24 |

: Dữ liệu và bộ giả bổ sung

Tập lệnh `seed-ph02.sh` tạo các đối tượng trên theo tên; mọi dữ liệu là chuỗi sinh ngẫu nhiên hoặc ẩn danh, không có dữ liệu thật của tỉnh.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

Bảng sinh tự động từ các kịch bản mục 4, 5 bằng `ph02/tools/fill_doc.py`.

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-02-01 | Tra cứu danh mục, chi tiết, tìm kiếm, mẫu gọi và tải đặc tả | Xác nhận tra cứu thay màn "Danh sách API" và "Đường dẫn sử dụng" của APIM cũ, với phiên bản nháp ẩn với người ngoài tổ chức, tìm toàn văn tiếng Việt và tải đặc tả đã công bố | UC-02-01 | 8 |
| TS-02-02 | Danh mục cho máy, mức hiển thị và cách ly tenant khi đọc | Xác nhận danh mục cho HTTT khai thác, cổng nhà phát triển và dịch vụ sự kiện theo mức hiển thị, không lộ API của tenant khác | UC-02-02, 04 | 5 |
| TS-02-03 | Phân loại, gắn thẻ và bộ phân loại | Xác nhận phân loại dữ liệu và thẻ theo từng API, quản trị nhóm, chặn bí mật nhà nước | UC-02-03 | 5 |
| TS-02-04 | Đăng ký API bằng trình hướng dẫn và nạp đặc tả | Xác nhận đăng ký API thay "Tạo API từ đầu" và "Nạp Swagger" của APIM cũ, kèm đặc tả OpenAPI bắt buộc, context-path theo quy ước, phiên bản nháp sửa được | UC-02-05 | 9 |
| TS-02-05 | Kiểm tra đặc tả hai lớp | Xác nhận kiểm tra lớp 1 (chuẩn OpenAPI 3.1), lớp 2 (quy ước nền tảng), kiểm tra không lưu và bộ luật theo tenant | UC-02-06, 38 | 6 |
| TS-02-06 | Bí mật, dữ liệu cá nhân thật và API trùng chức năng | Xác nhận không có bí mật hay dữ liệu cá nhân thật đi qua cổng công bố, quy trình phản đối nhận diện sai, phát hiện API trùng | UC-02-07 | 6 |
| TS-02-07 | Đồng bộ lại đặc tả, tự đăng ký từ luồng, khung route | Xác nhận tích hợp với URL nguồn, PH-04 và sinh khung route | UC-02-08, 09, 10 | 6 |
| TS-02-08 | Backend, cân bằng tải và sức khỏe | Xác nhận thay "Quản lý endpoint backend" của APIM cũ, kèm danh sách đích được phép, TLS tối thiểu, địa chỉ cấm | UC-02-11 | 7 |
| TS-02-09 | Gói sử dụng: thông tin, kiểu xác thực, hạn mức | Xác nhận tạo gói thay bước Define, Secure của Plan ở APIM cũ, thêm OAuth 2.1 và mTLS, kiểu xác thực theo mức phân loại | UC-02-12 | 7 |
| TS-02-10 | Vòng đời gói: công bố, ngừng khuyến nghị, đóng, sao chép | Xác nhận bốn trạng thái gói giữ như APIM cũ, có duyệt bốn mắt | UC-02-12, 13, 14 | 8 |
| TS-02-11 | Gửi duyệt, duyệt bốn mắt và công bố API | Xác nhận vòng đời `DRAFT → PENDING → PUBLISHED`, thử TEST, khóa nội dung và chỉ công bố khi gateway nhận cấu hình | UC-02-15, 16 | 10 |
| TS-02-12 | Tạm ngừng khẩn và tiếp tục | Xác nhận thay Start/Stop API, tạm ngừng không cần duyệt có thời hạn tối đa | UC-02-17 | 4 |
| TS-02-13 | Phiên bản mới, so sánh và tác động | Xác nhận phiên bản, phân loại thay đổi phá vỡ và phân tích bên bị ảnh hưởng | UC-02-18 | 5 |
| TS-02-14 | Ngừng khuyến nghị, ngừng hẳn, xóa API | Xác nhận lộ trình ngừng dùng có kế nhiệm, hạn tối thiểu, không ngừng hẳn khi còn đăng ký, xóa mềm giữ bằng chứng | UC-02-19, 20 | 7 |
| TS-02-15 | Mức hiển thị và chuyển chủ quản | Xác nhận mức hiển thị theo phân loại, gỡ khỏi cổng nhà phát triển, chuyển chủ quản | UC-02-21, 22 | 3 |
| TS-02-16 | Đăng ký sử dụng: gửi và duyệt | Xác nhận đăng ký thay "Subscription theo API, theo Application", tự duyệt theo mức dữ liệu, bốn mắt cho `RESTRICTED` trở lên | UC-02-23, 24 | 8 |
| TS-02-17 | Cấp phạm vi truy cập và xem đăng ký | Xác nhận phạm vi `api:{apiCode}:{planCode}` chỉ sinh từ đăng ký `ACTIVE`, không có đường cấp tay; xem theo API, theo HTTT không rò rỉ | UC-02-25, 26 | 4 |
| TS-02-18 | Tạm ngừng, tiếp tục, thu hồi, hủy, gia hạn đăng ký | Xác nhận bảy trạng thái đăng ký và hiệu lực ở gateway | UC-02-27, 28 | 4 |
| TS-02-19 | Đồng bộ danh mục lên Nền tảng quốc gia | Xác nhận đồng bộ API `NATIONAL`, `PUBLIC` qua PH-14, thử lại và cảnh báo quá hạn | UC-02-29, 30 | 4 |
| TS-02-20 | Cam kết chất lượng (SLA) và tuân thủ | Xác nhận khai báo SLA, đối chiếu thực tế, không kết luận khi thiếu dữ liệu, cảnh báo nhiều kỳ không đạt | UC-02-31, 32 | 5 |
| TS-02-21 | Thông báo thay đổi và thống kê | Xác nhận thông báo bắt buộc không tắt được, thông báo tay có giới hạn, thống kê tenant | UC-02-33, 34 | 4 |
| TS-02-22 | Giao diện nội bộ và đối soát gateway | Xác nhận PH-03, PH-04, PH-15 đọc dữ liệu công bố đúng scope và phát hiện lệch cấu hình | UC-02-35, 36 | 4 |
| TS-02-23 | Di trú từ APIM cũ và tham số phân hệ | Xác nhận nhập API, gói, đăng ký từ APIM cũ không mang khóa và bí mật, sửa tham số `02.*` trong giới hạn | UC-02-37, 38 | 5 |
| TS-02-24 | Hiệu năng và quy mô | Chứng minh NFR-02-001…006, 010 ở hồ sơ tỉnh vừa (GĐ-07) trên môi trường PERF | — | 9 |
| TS-02-25 | Cách ly tenant và không lộ bí mật xuyên suốt | Chứng minh NFR-02-012, 013: mọi API đọc, ghi cách ly tenant; mồi `DH-CANARY` không lọt ra đâu ngoài chỗ được phép | — | 8 |
| TS-02-26 | Sẵn sàng, cách ly sự cố và phục hồi | Chứng minh data plane không phụ thuộc PH-02, khôi phục đúng RPO, RTO | — | 4 |
| TS-02-27 | Truy cập, quan sát, thông báo và lưu giữ | Chứng minh NFR-02-015…019 | — | 4 |
| TS-02-28 | Giao diện: nhập liệu, trạng thái, nút theo quyền và ngôn ngữ | Chứng minh 17 màn UI-02-01…17 hiển thị đúng trạng thái, kiểm tra nhập liệu ở trình duyệt khớp máy chủ, nút thao tác theo quyền và hành động được phép, và dùng tiếng Việt có dấu, giờ Việt Nam | UC-02-01, 05, 06, 16, 23, 24, 29, 32, 37, 38 | 9 |
| **Tổng** | | | | **168** (102 ca P1) |

: Danh sách kịch bản kiểm thử của PH-02
<!--/gen-->

: Danh sách kịch bản kiểm thử

### 3.2. Máy trạng thái được kiểm thử

Ba máy trạng thái ở FRS §4.3…4.5 được phủ như sau: phiên bản API (TS-02-11, 12, 13, 14), gói (TS-02-09, 10), đăng ký (TS-02-16, 17, 18). Mỗi chuyển hợp lệ có ít nhất một ca dương, mỗi chuyển không hợp lệ được kiểm bằng ERR-02-011.

## 4. Kịch bản và test case chức năng

### TS-02-01 · Tra cứu danh mục, chi tiết, tìm kiếm, mẫu gọi và tải đặc tả

**Mục tiêu.** Xác nhận tra cứu thay màn "Danh sách API" và "Đường dẫn sử dụng" của APIM cũ, với phiên bản nháp ẩn với người ngoài tổ chức, tìm toàn văn tiếng Việt và tải đặc tả đã công bố.

**Phủ.** FR-02-001, 002, 003, 005, 006; UC-02-01; API-02-001, 002, 003, 006, 007, 090, 091, 074, 075; UI-02-01, 02; BR-02-033, 039; LGC-APIM-001; 017.

#### TC-02-001 · Danh sách API có lọc, sắp xếp và phân trang <!--k:list-filter-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-001 · API-02-001 · UI-02-01 · UC-02-01 · LGC-APIM-001.

**Tiền điều kiện, dữ liệu.** U-T68-VW; 25 API ở T68 gồm A-DATDAI, A-DRAFT, A-DEPREC.

**Các bước.**

1. `GET /apis?page=1&size=10&status=PUBLISHED&sort=name:asc`.
2. Lọc thêm theo đơn vị, `dataClass=INTERNAL`; mở UI-02-01 và đổi `?trang=2&co=10`.

**Kết quả mong đợi.** `200`, đúng trang và tổng, chỉ A-DATDAI khớp bộ lọc; thân có `ETag`; thẻ "Cần chú ý" ở UI-02-01 đếm đúng A-DEPREC.
:::

#### TC-02-002 · Người ngoài tổ chức không thấy phiên bản nháp <!--k:draft-hidden-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-001, 002, 003 · API-02-001, 002, 003 · BR-02-039 · ERR-02-001.

**Tiền điều kiện, dữ liệu.** A-DRAFT của Sở TN&MT; U-T68-SV2, U-T68-OR1, U-T68-SV1.

**Các bước.**

1. U-T68-SV2 và U-T68-OR1 gọi `GET /apis`, `GET /apis/tc-nhap`, `GET /search/apis?q=tc-nhap`.
2. U-T68-SV1 gọi lại ba lời gọi trên.

**Kết quả mong đợi.** Bước 1: danh sách và tìm kiếm không chứa `tc-nhap`, chi tiết là 404-ẩn. Bước 2: thấy đủ.
:::

#### TC-02-003 · Chi tiết API có đủ tab, SLA thực tế cạnh cam kết <!--k:detail-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-002 · API-02-002, 074, 075, 090, 091 · UI-02-02 · BR-02-013 · LGC-APIM-017.

**Tiền điều kiện, dữ liệu.** A-DATDAI có SLA cam kết 99,5 % và kỳ thực tế chưa đủ dữ liệu.

**Các bước.**

1. `GET /apis/tc-dat-dai`, `GET /apis/tc-dat-dai/versions`, `GET /apis/tc-dat-dai/history`.
2. Mở UI-02-02, xem tab SLA.

**Kết quả mong đợi.** Đủ phiên bản, gói, lịch sử; tab SLA hiện "chưa đủ dữ liệu", không kết luận đạt hay không đạt.
:::

#### TC-02-004 · Tìm toàn văn tiếng Việt có dấu và không dấu <!--k:search-vi-->

::: dac-ta
**Loại.** Dương, Biên · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-003 · API-02-003 · UI-02-01 · NFR-02-002.

**Tiền điều kiện, dữ liệu.** A-DATDAI có mô tả "Tra cứu thửa đất theo mã".

**Các bước.**

1. `GET /search/apis?q=thửa đất`, rồi `q=thua dat`.
2. `GET /search/apis?q=` (rỗng) và `q` dài 300 ký tự.

**Kết quả mong đợi.** Bước 1 cả hai đều trả A-DATDAI. Bước 2: `400` ERR-02-003 cho `q` quá dài; `q` rỗng trả danh sách mặc định.
:::

#### TC-02-005 · Đường dẫn sử dụng, mẫu gọi và tải đặc tả đã công bố <!--k:usage-spec-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-005, 006 · API-02-006, 007 · UI-02-02 · BR-02-001, 039 · ERR-02-001 · LGC-APIM-017.

**Tiền điều kiện, dữ liệu.** A-DATDAI, A-DRAFT; U-T68-OR1.

**Các bước.**

1. `GET …/tc-dat-dai/versions/1.0.0/usage-guide` rồi `…/spec`.
2. U-T68-OR1 gọi `…/tc-nhap/versions/1.0.0/spec`.

**Kết quả mong đợi.** Bước 1: có URL gateway ghép context-path `/{nhóm}/tc-dat-dai/v1`, mẫu `curl` theo kiểu xác thực của gói, tải được đặc tả đúng `Content-Type`. Bước 2: 404-ẩn.
:::

#### TC-02-084 · Đường dẫn sử dụng và đặc tả của phiên bản ngừng dùng, đã ngừng hẳn, không tồn tại <!--k:usage-spec-state-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-005, 006 · API-02-006, 007 · UI-02-02 · UC-02-01 · BR-02-014, 039 · ERR-02-001 · LGC-APIM-017.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; A-DEPREC (`DEPRECATED`); `tc-cu` 0.9.0 ở `RETIRED` (seed thêm); A-DRAFT.

**Các bước.**

1. `GET …/tc-cu/versions/1.0.0/usage-guide` (phiên bản `DEPRECATED`).
2. `GET …/tc-cu/versions/0.9.0/spec` (phiên bản `RETIRED`).
3. `GET …/tc-cu/versions/9.9.9/spec`; sau đó `GET …/tc-nhap/versions/1.0.0/usage-guide` bằng U-T68-OR1.

**Kết quả mong đợi.** Bước 1: `200`, kèm cờ ngừng khuyến nghị, ngày hết hạn và liên kết phiên bản kế nhiệm 2.0.0. Bước 2: `200`, đặc tả vẫn tải được vì giữ vĩnh viễn (BR-02-014). Bước 3: `404` ERR-02-001 cho phiên bản không có; bản `DRAFT` với người ngoài tổ chức cũng `404`, cùng thân.
:::

#### TC-02-085 · Tham số lọc, sắp xếp, phân trang sai và ở biên <!--k:list-validation-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-001, 003 · API-02-001, 003 · UI-02-01 · UC-02-01 · ERR-02-003.

**Tiền điều kiện, dữ liệu.** U-T68-VW; 25 API ở T68.

**Các bước.**

1. `GET /apis?size=100`, rồi `size=101`, `size=0`, `page=0`.
2. `GET /apis?sort=truong-la:asc` và `status=KHONG-CO`.
3. `GET /search/apis` không có `q`; rồi `q=` rỗng.
4. `GET /apis?status=PUBLISHED,DEPRECATED` (tham số lặp phân tách dấu phẩy).

**Kết quả mong đợi.** `size=100` trả `200`. Các giá trị còn lại trả `400` ERR-02-003 kèm `errors[]` nêu đúng trường (`size`, `page`, `sort`, `status`, `q`). Bước 4 trả đủ hai trạng thái, không trả `RETIRED`. UI-02-01 mở bằng đường dẫn sai tham số thì rơi về trang 1, cỡ 20, có thông báo.
:::

#### TC-02-086 · Danh sách phiên bản và lịch sử của API, cách ly tổ chức và tenant <!--k:versions-history-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-002 · API-02-090, 091 · UI-02-02 · UC-02-01 · BR-02-028, 033, 039 · ERR-02-001.

**Tiền điều kiện, dữ liệu.** A-DATDAI đã qua vòng đời `DRAFT` → `PUBLISHED` → `SUSPENDED` → `PUBLISHED`; A-DRAFT; A-T01; U-T68-SV1, U-T68-VW, U-T68-SV2.

**Các bước.**

1. U-T68-SV1 gọi `GET …/tc-dat-dai/versions` và `GET …/tc-dat-dai/history`.
2. U-T68-VW và U-T68-SV2 gọi `…/tc-nhap/versions` (có bản `DRAFT`).
3. U-T68-SV1 gọi `GET /apis/tc-chi-t01/versions` và `…/history`.
4. Mở tab Phiên bản và tab Lịch sử ở UI-02-02.

**Kết quả mong đợi.** Bước 1: `200`, lịch sử đủ mọi chuyển trạng thái kèm lý do, người làm, giá trị trước và sau, đúng thứ tự thời gian. Bước 2: danh sách không có phiên bản `DRAFT` (`totalElements` = 0), không báo lỗi. Bước 3: `404` ERR-02-001 cùng thân với mã không tồn tại. Bước 4: hai tab hiện đúng dữ liệu của bước 1.
:::

### TS-02-02 · Danh mục cho máy, mức hiển thị và cách ly tenant khi đọc

**Mục tiêu.** Xác nhận danh mục cho HTTT khai thác, cổng nhà phát triển và dịch vụ sự kiện theo mức hiển thị, không lộ API của tenant khác.

**Phủ.** FR-02-004, 009; UC-02-02, 04; API-02-004, 005, 013, 081; UI-02-01; BR-02-033, 037, 038.

#### TC-02-006 · Danh mục cho máy theo mức hiển thị và điều kiện `304` <!--k:catalog-machine-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-004 · API-02-004, 005, 081 · UC-02-02 · BR-02-037 · NFR-02-001 · EVT-02-05.

**Tiền điều kiện, dữ liệu.** S-PORTAL; A-DATDAI mức hiển thị `NATIONAL`, một API `TENANT`, một API `PUBLIC`.

**Các bước.**

1. S-PORTAL gọi `GET /internal/portal/catalog`, ghi `ETag`.
2. Gọi lại với `If-None-Match`.
3. `GET /catalog/apis` bằng token máy `catalog:read`.

**Kết quả mong đợi.** Bước 1 trả API `PUBLIC` và `NATIONAL` theo hợp đồng PH-15, không trả API `TENANT`. Bước 2: `304`. Bước 3: chỉ các API `PUBLISHED`.
:::

#### TC-02-007 · Đọc danh mục với tenant khác và token sai scope <!--k:catalog-cross-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-004 · API-02-004, 005, 081 · BR-02-033 · ERR-02-001, 014 · NFR-02-013.

**Tiền điều kiện, dữ liệu.** A-T01; token S-GW (scope `catalog:gateway-read`).

**Các bước.**

1. Người dùng T68 gọi `GET /catalog/apis/tc-chi-t01` và `GET /apis/khong-co`.
2. S-GW gọi `GET /internal/portal/catalog`.

**Kết quả mong đợi.** Bước 1: hai lời gọi đều 404-ẩn, thân giống nhau trừ `traceId`. Bước 2: 403-PQ.
:::

#### TC-02-008 · Dịch vụ sự kiện hiển thị chỉ đọc, không thao tác vòng đời <!--k:event-service-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P3 · **Tự động.** API, E2E

**Truy vết.** FR-02-009 · API-02-013 · UI-02-01 · UC-02-04 · BR-02-038.

**Tiền điều kiện, dữ liệu.** Hai topic PH-10 đã công bố ở T68 (Đợt 2).

**Các bước.**

1. `GET /event-services`.
2. Mở UI-02-01 tab "Dịch vụ sự kiện", tìm nút đăng ký.

**Kết quả mong đợi.** Có hai topic kèm liên kết sang PH-10; không có nút đăng ký hay duyệt ở PH-02.
:::

#### TC-02-087 · Danh mục cho máy: phần thay đổi theo `updatedSince`, danh sách gỡ và giới hạn tần suất <!--k:catalog-delta-->

::: dac-ta
**Loại.** Dương, Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-004 · API-02-004, 005 · UC-02-02 · BR-02-037, 039 · ERR-02-003 · NFR-02-001.

**Tiền điều kiện, dữ liệu.** Token máy `catalog:read` của H-KHAITHAC-1; A-DATDAI, A-DEPREC; một API sắp chuyển `RETIRED`.

**Các bước.**

1. `GET /catalog/apis` lấy `ETag` và mốc `T0`; sửa mô tả A-DATDAI; chuyển một API sang `RETIRED`.
2. `GET /catalog/apis?updatedSince=T0` kèm `If-None-Match` cũ.
3. `GET /catalog/apis?updatedSince=hôm-qua`.
4. Gọi 61 lần trong một phút bằng cùng client.

**Kết quả mong đợi.** Bước 2: `200`, `items` chỉ có A-DATDAI, `removed[]` có mã API đã `RETIRED`. Bước 3: `400` ERR-02-003 nêu trường `updatedSince`. Bước 4: lần thứ 61 trả `429` kèm `Retry-After` (giới hạn 60 yêu cầu mỗi phút mỗi client); các lần trước đó trả `304` hoặc `200` đúng.
:::

#### TC-02-088 · Dịch vụ sự kiện: không lộ topic tenant khác và không có thao tác ghi ở PH-02 <!--k:event-leak-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P2 · **Tự động.** API, IT

**Truy vết.** FR-02-009 · API-02-013 · UI-02-01 · UC-02-04 · BR-02-033, 038 · ERR-02-001, 014.

**Tiền điều kiện, dữ liệu.** Topic `tc-su-kien-t68` ở T68 và `tc-su-kien-t01` ở T01 (PH-10, giả lập M-TOPIC); token máy không có scope `catalog:read`.

**Các bước.**

1. U-T68-VW gọi `GET /event-services`.
2. Gọi `GET /event-services` bằng token máy thiếu scope.
3. Đối chiếu tập operation của OpenAPI `dh-connect` (CI-5) với đường dẫn `/event-services`.

**Kết quả mong đợi.** Bước 1: chỉ thấy `tc-su-kien-t68`; không dấu vết của topic T01. Bước 2: `403` ERR-02-014. Bước 3: chỉ có `GET`, không có tạo, sửa, xóa hay đăng ký ở PH-02 (BR-02-038).
:::

### TS-02-03 · Phân loại, gắn thẻ và bộ phân loại

**Mục tiêu.** Xác nhận phân loại dữ liệu và thẻ theo từng API, quản trị nhóm, chặn bí mật nhà nước.

**Phủ.** FR-02-007, 008; UC-02-03; API-02-008, 009, 010, 011, 012; UI-02-14; BR-02-007, 021, 037.

#### TC-02-009 · Đặt phân loại và thẻ cho API của tổ chức mình <!--k:classify-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-007 · API-02-008 · UI-02-02, 14 · UC-02-03 · KT: có (api.classify).

**Tiền điều kiện, dữ liệu.** A-DRAFT; U-T68-SV1.

**Các bước.**

1. `PUT /apis/tc-nhap/classification` với nhóm `dat-dai`, `dataClass=INTERNAL`, thẻ `tra-cuu`.
2. Mở UI-02-14.

**Kết quả mong đợi.** `200`; API xuất hiện trong nhóm; có bản ghi kiểm toán giá trị trước và sau.
:::

#### TC-02-010 · Từ chối bí mật nhà nước, API của tổ chức khác, mức quá cao so với hiển thị <!--k:classify-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-007 · API-02-008 · BR-02-007, 032, 037 · ERR-02-016, 014, 043.

**Tiền điều kiện, dữ liệu.** A-DATDAI; U-T68-SV2; U-T68-SV1.

**Các bước.**

1. U-T68-SV1 gửi `stateSecret=true`.
2. U-T68-SV2 đặt phân loại cho `tc-dat-dai`.
3. U-T68-SV1 đặt `dataClass=SENSITIVE` khi mức hiển thị là `NATIONAL`.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-016. Bước 2: 403-PQ. Bước 3: `422` ERR-02-043.
:::

#### TC-02-011 · Quản lý nhóm: thêm, đổi tên, gộp, xóa kèm chuyển API <!--k:category-admin-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-008 · API-02-009, 010, 011, 012 · UI-02-14 · BR-02-021 · ERR-02-002, 014.

**Tiền điều kiện, dữ liệu.** U-T68-TA; nhóm `dat-dai` có 3 API; U-T68-SV1.

**Các bước.**

1. U-T68-TA `POST /categories` mã `moi-truong`; `PATCH` đổi tên; tạo lại mã `moi-truong` sau khi xóa.
2. `DELETE /categories/dat-dai` chuyển sang `khac`.
3. U-T68-SV1 gọi `POST /categories`.

**Kết quả mong đợi.** Bước 1: đổi tên thành công, tạo lại mã đã dùng `409` ERR-02-002. Bước 2: 3 API sang `khac`. Bước 3: 403-PQ.
:::

#### TC-02-089 · Nhóm phân loại: mã trùng kể cả mã đã xóa, xóa nhóm thiếu đích, vòng cây, sai quyền <!--k:category-neg-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-008 · API-02-009, 010, 011, 012 · UI-02-14 · UC-02-03 · BR-02-021 · ERR-02-002, 003, 014, 011.

**Tiền điều kiện, dữ liệu.** Nhóm `tc-nhom-a` (có 2 API), `tc-nhom-a1` con của nó, `tc-nhom-da-xoa` đã xóa; U-T68-TA, U-T68-SV1, U-T68-VW.

**Các bước.**

1. U-T68-TA `POST /categories` mã `tc-nhom-da-xoa`.
2. `DELETE /categories/tc-nhom-a` không chỉ nhóm đích, rồi với nhóm đích không tồn tại.
3. `PATCH /categories/tc-nhom-a` đặt cha là `tc-nhom-a1`.
4. U-T68-SV1 và U-T68-VW gọi `POST /categories`.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-002 (mã không dùng lại). Bước 2: `400` ERR-02-003 (thiếu đích), rồi `404` ERR-02-001. Bước 3: bị từ chối vì tạo vòng (`409` ERR-02-011 hoặc `400` ERR-02-003 nêu lý do, không đổi cây). Bước 4: `403` ERR-02-014. UI-02-14 ẩn nút thêm, xóa với SV và VW.
:::

#### TC-02-090 · Phân loại: xung đột `If-Match` và gỡ thẻ <!--k:classify-concurrency-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-007 · API-02-008 · UI-02-14 · UC-02-03 · BR-02-028 · ERR-02-015.

**Tiền điều kiện, dữ liệu.** A-DATDAI; hai phiên U-T68-SV1 (A và B) cùng lấy `ETag`.

**Các bước.**

1. Phiên A `PUT /apis/tc-dat-dai/classification` đổi thẻ thành `[đất đai]`, kèm `If-Match`.
2. Phiên B gửi cùng thay đổi với `ETag` cũ.
3. Phiên B lấy lại `ETag` mới, gỡ hết thẻ (`tags: []`).

**Kết quả mong đợi.** Bước 1: `200`, `ETag` đổi. Bước 2: `412` ERR-02-015, dữ liệu giữ nguyên bản của phiên A. Bước 3: `200`, API không còn thẻ; mỗi thay đổi có một dòng kiểm toán giá trị trước, sau.
:::

### TS-02-04 · Đăng ký API bằng trình hướng dẫn và nạp đặc tả

**Mục tiêu.** Xác nhận đăng ký API thay "Tạo API từ đầu" và "Nạp Swagger" của APIM cũ, kèm đặc tả OpenAPI bắt buộc, context-path theo quy ước, phiên bản nháp sửa được.

**Phủ.** FR-02-010, 011, 014, 015, 024; UC-02-05; API-02-014, 015, 018, 019, 030; UI-02-03; BR-02-021, 022, 030, 032; LGC-APIM-002; 003, 004.

#### TC-02-012 · Đăng ký API qua năm bước từ tệp OpenAPI hợp lệ <!--k:register-ok-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-010, 011, 024 · API-02-014, 015, 030 · UI-02-03 · UC-02-05 · EVT-02-01 · KT: có (api.register) · LGC-APIM-002; 003.

**Tiền điều kiện, dữ liệu.** U-T68-SV1; H-CUNGCAP-1; F-SPEC-OK.

**Các bước.**

1. `POST /spec-uploads` nguồn `FILE` với F-SPEC-OK.
2. `GET /context-paths:check?path=/dat-dai/tc-moi/v1`.
3. `POST /apis` mã `tc-moi`, kèm phiên bản 1.0.0.

**Kết quả mong đợi.** `201`; phiên bản `DRAFT`; context-path đúng `/{nhóm}/tc-moi/v1`; EVT: `api.registered`; chủ quản là tổ chức của H-CUNGCAP-1.
:::

#### TC-02-013 · Nạp Swagger 2.0, nội dung dán, URL và các nguồn lỗi <!--k:upload-sources-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-011 · API-02-015 · ERR-02-005, 009, 010, 036 · LGC-APIM-003.

**Tiền điều kiện, dữ liệu.** F-SPEC-SW2, F-SPEC-BIG; M-URL (trả chậm 30 giây, chuyển hướng tới `http://169.254.169.254/`).

**Các bước.**

1. Nạp F-SPEC-SW2; nạp nội dung dán; nạp URL hợp lệ.
2. Nạp F-SPEC-BIG; nạp tệp rác `{`; nạp URL trả chậm; nạp URL chuyển hướng tới địa chỉ cấm.
3. Nạp URL 21 lần trong một giờ.

**Kết quả mong đợi.** Bước 1: chuyển Swagger 2.0 sang OpenAPI 3.1 có cảnh báo. Bước 2: lần lượt `413` ERR-02-009, `422` ERR-02-005, `422` ERR-02-010, `422` ERR-02-010. Bước 3: lần 21 là `429` ERR-02-036.
:::

#### TC-02-014 · Context-path trùng, xung đột tiền tố, sai quy ước, bất biến sau công bố <!--k:context-path-neg-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-024, 014 · API-02-030, 018, 014 · BR-02-022 · ERR-02-019, 002 · UI-02-03.

**Tiền điều kiện, dữ liệu.** A-DATDAI (`/dat-dai/tc-dat-dai/v1` đã `PUBLISHED`); API `RETIRED` mới 2 tháng giữ chỗ.

**Các bước.**

1. Đăng ký API với path trùng A-DATDAI; path `/dat-dai/tc-dat-dai/v1/con`; path `/Dat Dai/x`; path của API `RETIRED`.
2. `PATCH /apis/tc-dat-dai` đổi context-path.

**Kết quả mong đợi.** Bước 1: cả bốn `422` ERR-02-019. Bước 2: `409` ERR-02-011 hoặc `422` ERR-02-019 (path bất biến).
:::

#### TC-02-015 · Sửa bản nháp, khóa khi chờ duyệt, xung đột `If-Match`, mẫu đặc tả <!--k:edit-draft-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-014, 015 · API-02-018, 019 · BR-02-030, 032 · ERR-02-038, 015, 014 · UI-02-03.

**Tiền điều kiện, dữ liệu.** A-DRAFT; A-DRAFT thứ hai ở `PENDING`; U-T68-SV1, U-T68-SV2.

**Các bước.**

1. U-T68-SV1 `PATCH /apis/tc-nhap` đúng `If-Match`, rồi `If-Match` cũ.
2. Sửa A-DRAFT đang `PENDING`.
3. U-T68-SV2 sửa A-DRAFT của Sở TN&MT.
4. `GET /spec-templates/openapi`.

**Kết quả mong đợi.** Bước 1: `200`, rồi `412` ERR-02-015. Bước 2: `409` ERR-02-038. Bước 3: 403-PQ. Bước 4: tệp mẫu đạt lớp 1, lớp 2.
:::

#### TC-02-016 · Đăng ký cho HTTT không `ACTIVE` hoặc thiếu mô tả tổng thể <!--k:register-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-010 · API-02-014 · BR-02-002, 032 · ERR-02-004, 003, 002, 041.

**Tiền điều kiện, dữ liệu.** H-KHAITHAC-2 chưa `ACTIVE`; mã `tc-dat-dai` đã dùng.

**Các bước.**

1. `POST /apis` với HTTT không `ACTIVE`.
2. `POST /apis` thiếu `name`.
3. `POST /apis` với mã `tc-dat-dai`.

**Kết quả mong đợi.** Lần lượt `422` ERR-02-004, `400` ERR-02-003 kèm danh sách lỗi theo trường, `409` ERR-02-002.
:::

#### TC-02-091 · Đăng ký API: biên độ dài mã API, mã phiên bản, context-path <!--k:register-boundary-->

::: dac-ta
**Loại.** Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API, UT

**Truy vết.** FR-02-010, 024 · API-02-014 · UI-02-03 · UC-02-05 · BR-02-021, 022 · ERR-02-003.

**Tiền điều kiện, dữ liệu.** U-T68-SV1; F-SPEC-OK; H-CUNGCAP-1.

**Các bước.**

1. `POST /apis` với `apiCode` 2 ký tự, rồi 3 ký tự, 63 ký tự, 64 ký tự, bắt đầu bằng số, chứa chữ hoa.
2. `versionNo` `1.0`, `1.0.0`, `01.0.0`, `1.0.0-beta`.
3. `contextPath` dài 120 ký tự rồi 121 ký tự; có chữ hoa; không bắt đầu bằng `/`.

**Kết quả mong đợi.** Chỉ các giá trị đúng `^[a-z][a-z0-9-]{2,62}$` (3…63 ký tự), `MAJOR.MINOR.PATCH` và `^/[a-z0-9/-]{3,120}$` được `201`; còn lại `400` ERR-02-003 nêu đúng trường. UI-02-03 chặn ngay ở bước nhập và hiện cùng thông báo.
:::

#### TC-02-092 · Giới hạn kích thước đặc tả: đúng 10 MiB và vượt giới hạn <!--k:spec-size-limit-->

::: dac-ta
**Loại.** Biên, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-011 · API-02-015 · UI-02-03 · UC-02-05 · BR-02-001 · ERR-02-009 · NFR-02-011.

**Tiền điều kiện, dữ liệu.** F-SPEC-10M (đúng 10 MiB), F-SPEC-BIG (11 MiB); `02.spec.max-size-mib` = 10.

**Các bước.**

1. `POST /spec-uploads` với F-SPEC-10M.
2. `POST /spec-uploads` với F-SPEC-BIG bằng tệp, rồi bằng nội dung dán.
3. Đặt `02.spec.max-size-mib` = 5 (miền cho phép) rồi nạp lại F-SPEC-10M.

**Kết quả mong đợi.** Bước 1: `200` trong ≤ 20 giây. Bước 2: `413` ERR-02-009 ở cả hai nguồn, không giữ tệp nào ở kho đối tượng. Bước 3: `413`. UI-02-03 báo vượt giới hạn trước khi gửi nếu biết kích thước tệp.
:::

#### TC-02-093 · Nạp đặc tả từ URL: địa chỉ nội bộ, chuyển hướng, quá thời gian, quá số lần <!--k:url-fetch-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-011 · API-02-015 · UI-02-03 · UC-02-05 · BR-02-023 · ERR-02-010, 036 · SEC-16.

**Tiền điều kiện, dữ liệu.** M-URL với các kịch bản: trả thường, chuyển hướng `302` tới `http://169.254.169.254/`, trả chậm hơn `02.spec.url-fetch-timeout-seconds`; U-T68-SV1.

**Các bước.**

1. Nạp URL `http://169.254.169.254/latest/meta-data`, `http://127.0.0.1:8080/spec`, `http://localhost/spec`.
2. Nạp URL M-URL chuyển hướng tới địa chỉ nội bộ.
3. Nạp URL M-URL trả chậm.
4. Nạp hợp lệ 20 lần trong một giờ, rồi lần 21.

**Kết quả mong đợi.** Bước 1, 2, 3: `422` ERR-02-010, thông báo chung, không nêu địa chỉ IP đã phân giải; nhật ký ghi lý do ở mức nội bộ. Bước 4: 20 lần đầu `200`, lần 21 `429` ERR-02-036 kèm `retryAfterSeconds` và tiêu đề `Retry-After`.
:::

#### TC-02-162 · Kiểm tra context-path trước khi đăng ký: hợp lệ, trùng, tiền tố, tham số sai <!--k:context-path-check-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-024 · API-02-030 · UI-02-03 · UC-02-05 · BR-02-022 · ERR-02-019, 003.

**Tiền điều kiện, dữ liệu.** A-DATDAI (`/dat-dai/tc-dat-dai/v1`); API `RETIRED` còn trong thời gian giữ chỗ 12 tháng; U-T68-VW.

**Các bước.**

1. `GET /context-paths:check?path=/dat-dai/tc-moi/v1`.
2. Kiểm tra đúng đường dẫn của A-DATDAI; tiền tố cha `/dat-dai/tc-dat-dai`; đường dẫn con `/dat-dai/tc-dat-dai/v1/con`; đường dẫn của API đang giữ chỗ.
3. Kiểm tra `path=` rỗng; `path=/Dat-Dai`; thiếu tham số.
4. Gõ thử ở UI-02-03 bước "Đường dẫn".

**Kết quả mong đợi.** Bước 1: `200`, khả dụng. Bước 2: `200` kèm `available=false` và lý do (trùng, xung đột tiền tố, đang giữ chỗ); đây là phép kiểm tra, không tạo gì. Bước 3: `400` ERR-02-003; đường dẫn sai quy ước `/{nhóm}/{mã API}/v{số chính}` báo sai quy ước (ERR-02-019 khi đăng ký thật). Bước 4: UI báo cùng lý do ngay khi gõ, có giới hạn tần suất gọi ở trình duyệt.
:::

### TS-02-05 · Kiểm tra đặc tả hai lớp

**Mục tiêu.** Xác nhận kiểm tra lớp 1 (chuẩn OpenAPI 3.1), lớp 2 (quy ước nền tảng), kiểm tra không lưu và bộ luật theo tenant.

**Phủ.** FR-02-016, 017, 019, 021; UC-02-06, 38; API-02-020, 021, 022, 024, 025, 092; UI-02-04, 15; BR-02-002; NFR-02-003.

#### TC-02-017 · Đặc tả không đạt lớp 1 chặn gửi duyệt <!--k:lint-l1-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-016 · API-02-020, 021 · UI-02-04 · ERR-02-006, 005.

**Tiền điều kiện, dữ liệu.** API nháp nạp F-SPEC-L1.

**Các bước.**

1. `POST …/lint-runs`.
2. `GET …/lint-results`; mở UI-02-04, bấm nhảy tới lỗi.

**Kết quả mong đợi.** Có lỗi mức `ERROR` kèm dòng, cột, đường dẫn JSON; thao tác gửi duyệt trả `422` ERR-02-006; UI tô sáng đúng dòng.
:::

#### TC-02-018 · Lớp 2: lỗi nghiêm trọng chặn, cảnh báo cho phép chấp nhận kèm lý do <!--k:lint-l2-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-016, 017 · API-02-020, 021, 092 · BR-02-002, 028 · ERR-02-007, 041 · KT: có (lint.acknowledge).

**Tiền điều kiện, dữ liệu.** F-SPEC-L2; U-T68-SV1.

**Các bước.**

1. Chạy kiểm tra; ghi số lỗi và cảnh báo.
2. `:acknowledge` một cảnh báo không kèm lý do, rồi kèm lý do.
3. Sửa đặc tả thiếu mô tả tổng thể để hết lỗi nghiêm trọng.

**Kết quả mong đợi.** Bước 1: có lỗi nghiêm trọng ERR-02-007. Bước 2: `400` ERR-02-041 rồi `200`, có kiểm toán. Bước 3: cảnh báo ngôn ngữ chỉ cảnh báo, không chặn.
:::

#### TC-02-019 · Kiểm tra không lưu khi gõ: không ghi dữ liệu, giới hạn tần suất <!--k:lint-nosave-->

::: dac-ta
**Loại.** Dương, Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-019 · API-02-022 · UI-02-03, 04 · ERR-02-036 · NFR-02-003.

**Tiền điều kiện, dữ liệu.** F-SPEC-5K; U-T68-SV1.

**Các bước.**

1. `POST /spec-lint` F-SPEC-5K; đếm bản ghi `ph02_catalog.lint_result`.
2. Gọi 61 lần trong một giờ.

**Kết quả mong đợi.** Bước 1: `200` ≤ 5 giây, không thêm bản ghi. Bước 2: lần 61 `429` ERR-02-036 kèm `retryAfterSeconds`.
:::

#### TC-02-020 · Bộ luật quy ước theo tenant: đổi mức, phân quyền <!--k:lint-rules-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-021 · API-02-024, 025 · UI-02-15 · UC-02-38 · ERR-02-014, 003 · KT: có (lint-rules.update).

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-SV1.

**Các bước.**

1. U-T68-TA `PUT /lint-rules` hạ một luật từ `ERROR` xuống `WARN`.
2. U-T68-SV1 gọi `PUT /lint-rules`.
3. Gửi luật nền tảng bắt buộc (không được tắt) với mức `OFF`.

**Kết quả mong đợi.** Bước 1: `200`, kiểm lại F-SPEC-L2 chỉ còn cảnh báo. Bước 2: 403-PQ. Bước 3: `400` ERR-02-003.
:::

#### TC-02-094 · Chạy kiểm tra đồng thời và vượt giới hạn tần suất <!--k:lint-conflict-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-016, 019 · API-02-021, 022 · UI-02-04 · UC-02-06 · ERR-02-035, 036.

**Tiền điều kiện, dữ liệu.** A-DRAFT với F-SPEC-5K; U-T68-SV1; `02.lint.max-per-hour` = 60.

**Các bước.**

1. Gửi hai `POST …/lint-runs` gần như cùng lúc cho cùng phiên bản.
2. Gọi `POST /spec-lint` 60 lần liên tiếp trong một giờ, rồi lần thứ 61.
3. Đợi hết `retryAfterSeconds` rồi gọi lại.

**Kết quả mong đợi.** Bước 1: một lần `200`, một lần `409` ERR-02-035; kết quả lưu chỉ có một bản. Bước 2: lần 61 `429` ERR-02-036 kèm `Retry-After`. Bước 3: `200`.
:::

#### TC-02-095 · Chấp nhận cảnh báo lớp 2: thiếu lý do, lỗi nghiêm trọng, sai quyền <!--k:lint-ack-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-017 · API-02-092 · UI-02-04 · UC-02-06 · BR-02-028 · ERR-02-041, 011, 014.

**Tiền điều kiện, dữ liệu.** A-DRAFT với F-SPEC-L2 (có cả cảnh báo và lỗi nghiêm trọng); U-T68-SV1, U-T68-VW.

**Các bước.**

1. `POST …/lint-findings/{id cảnh báo}:acknowledge` không có `reason`.
2. Chấp nhận phát hiện mức nghiêm trọng.
3. U-T68-VW chấp nhận một cảnh báo.
4. U-T68-SV1 chấp nhận cảnh báo kèm lý do hợp lệ; mở UI-02-04.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-041. Bước 2: `409` ERR-02-011 (lỗi nghiêm trọng không chấp nhận được). Bước 3: `403` ERR-02-014. Bước 4: `200`, cảnh báo chuyển "đã chấp nhận" kèm người, lý do, thời điểm; lỗi nghiêm trọng vẫn chặn gửi duyệt.
:::

### TS-02-06 · Bí mật, dữ liệu cá nhân thật và API trùng chức năng

**Mục tiêu.** Xác nhận không có bí mật hay dữ liệu cá nhân thật đi qua cổng công bố, quy trình phản đối nhận diện sai, phát hiện API trùng.

**Phủ.** FR-02-018, 020, 007, 010; UC-02-07; API-02-023, 093, 094, 008, 014, 015, 021, 042, 045, 047; UI-02-04, 10; BR-02-007, 015; NFR-02-012.

#### TC-02-021 · Đặc tả chứa khóa PEM, JWT, mật khẩu trong URL bị chặn mọi bước <!--k:secret-block-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-018 · API-02-021, 042, 045, 047 · BR-02-015 · ERR-02-008 · NFR-02-012.

**Tiền điều kiện, dữ liệu.** F-SPEC-SECRET, mồi `DH-CANARY-secret-{uuid}`; U-T68-SV1, U-T68-CA.

**Các bước.**

1. Nạp F-SPEC-SECRET, chạy kiểm tra.
2. Gửi duyệt; ép duyệt và công bố bằng lời gọi trực tiếp.
3. Tìm mồi ở phản hồi, log, vết, bảng, Kafka, danh mục cho máy.

**Kết quả mong đợi.** Bước 1: phát hiện đủ 4 loại, giá trị che một phần trong kết quả. Bước 2: ba thao tác đều `422` ERR-02-008. Bước 3: mồi sạch.
:::

#### TC-02-022 · Dữ liệu cá nhân thật (CCCD, điện thoại) trong ví dụ <!--k:pii-block-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-018 · API-02-021, 042 · BR-02-015 · ERR-02-008 · NFR-02-012.

**Tiền điều kiện, dữ liệu.** F-SPEC-PII; bộ 50 mẫu chuẩn bí mật, PII.

**Các bước.**

1. Chạy kiểm tra F-SPEC-PII.
2. Chạy bộ 50 mẫu chuẩn.

**Kết quả mong đợi.** Bước 1: chặn gửi duyệt. Bước 2: phát hiện ≥ 95 % (≥ 48/50), mỗi mẫu bỏ sót ghi lỗi theo dõi.
:::

#### TC-02-023 · Phản đối nhận diện bí mật: người đề nghị khác người xác nhận <!--k:secret-dispute-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-018 · API-02-093, 094 · ERR-02-013, 014 · KT: có (lint.dispute).

**Tiền điều kiện, dữ liệu.** Phát hiện giả tính dương ở API nháp; U-T68-SV1, U-T68-SO.

**Các bước.**

1. U-T68-SV1 `:dispute-secret` kèm lý do.
2. U-T68-SV1 gọi `:confirm-dispute`.
3. U-T68-SO `:confirm-dispute` chấp nhận.

**Kết quả mong đợi.** Bước 1: chờ xác nhận. Bước 2: 403-PQ. Bước 3: phát hiện chuyển "đã xác nhận không phải bí mật", có kiểm toán; nếu SO là người đề nghị thì `403` ERR-02-013.
:::

#### TC-02-024 · Phát hiện API trùng chức năng theo ngưỡng <!--k:duplicate-->

::: dac-ta
**Loại.** Dương, Biên · **Ưu tiên.** P3 · **Tự động.** API, E2E

**Truy vết.** FR-02-020 · API-02-023 · UI-02-03, 10 · UC-02-07.

**Tiền điều kiện, dữ liệu.** `02.duplicate.threshold` = 0,8; API nháp có đặc tả gần giống A-DATDAI (điểm 0,85) và một API khác (điểm 0,79).

**Các bước.**

1. `GET …/duplicates`.
2. Mở hồ sơ duyệt ở UI-02-10.

**Kết quả mong đợi.** Chỉ A-DATDAI được liệt kê; người duyệt thấy "API gần giống"; không chặn gửi duyệt.
:::

#### TC-02-096 · Phát hiện API trùng chức năng: không trùng, tenant khác, quyền đọc <!--k:duplicate-neg-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-020 · API-02-023 · UI-02-03 · UC-02-07 · BR-02-033 · ERR-02-001, 014.

**Tiền điều kiện, dữ liệu.** A-DRAFT với đặc tả khác biệt hoàn toàn; A-T01 có đặc tả giống A-DATDAI; U-T68-VW; `02.duplicate.threshold` mặc định.

**Các bước.**

1. U-T68-VW gọi `GET …/tc-nhap/versions/1.0.0/duplicates`.
2. Gọi cho phiên bản của A-T01.
3. Nạp đặc tả giống A-DATDAI vào A-DRAFT rồi gọi lại.

**Kết quả mong đợi.** Bước 1: `200`, danh sách rỗng, không lỗi. Bước 2: `404` ERR-02-001 (không lộ việc A-T01 giống A-DATDAI). Bước 3: có A-DATDAI với điểm giống ≥ ngưỡng; kết quả chỉ là gợi ý, không chặn gửi duyệt.
:::

#### TC-02-097 · Dịch vụ khai `x-dh-stateSecret` bị chặn ở mọi đường vào <!--k:state-secret-all-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-007, 010, 018 · API-02-008, 014, 015 · UI-02-03, 14 · UC-02-03 · BR-02-007 · ERR-02-016.

**Tiền điều kiện, dữ liệu.** F-SPEC-STATE; A-DRAFT; U-T68-SV1.

**Các bước.**

1. `POST /apis` kèm đặc tả F-SPEC-STATE.
2. `PUT /apis/tc-nhap/classification` đặt `stateSecret = true`.
3. Nạp F-SPEC-STATE bằng `POST /spec-uploads`.

**Kết quả mong đợi.** Cả ba `422` ERR-02-016. Không có bản ghi nào được tạo hoặc đổi; log không chứa nội dung đặc tả.
:::

### TS-02-07 · Đồng bộ lại đặc tả, tự đăng ký từ luồng, khung route

**Mục tiêu.** Xác nhận tích hợp với URL nguồn, PH-04 và sinh khung route.

**Phủ.** FR-02-012, 013, 026, 014; UC-02-08, 09, 10; API-02-016, 017, 032, 095, 018; UI-02-02; BR-02-010, 030.

#### TC-02-025 · Đồng bộ lại đặc tả từ URL: phát hiện thay đổi, không ghi đè bản đã công bố <!--k:resync-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-012 · API-02-016, 095 · UI-02-02 · EVT-02-07 · ERR-02-035, 011.

**Tiền điều kiện, dữ liệu.** Bản nháp nạp từ M-URL; đổi nội dung nguồn.

**Các bước.**

1. `POST …/spec:resync`, theo dõi `GET /operations/{id}`.
2. Gọi `:resync` lần hai khi lần một đang chạy.
3. Gọi `:resync` cho phiên bản `PUBLISHED`.

**Kết quả mong đợi.** Bước 1: `202`, có khác biệt, EVT: `version.spec-source-changed`. Bước 2: `409` ERR-02-035. Bước 3: `409` ERR-02-011.
:::

#### TC-02-026 · PH-04 tự đăng ký API từ luồng REST; chỉ sửa mô tả, gói, SLA <!--k:flow-register-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-013, 014 · API-02-017, 018 · BR-02-030 · ERR-02-014, 011 · EVT-02-01 · LGC-BUS-028.

**Tiền điều kiện, dữ liệu.** S-FLOW (`catalog:flow-sync`); luồng `tc-luong-rest`.

**Các bước.**

1. S-FLOW `PUT /internal/flow-apis/tc-luong-rest`, lặp lại lần hai (idempotent).
2. U-T68-SV1 sửa mô tả, rồi sửa đặc tả của API `origin = FLOW`.
3. Dùng token người dùng gọi `PUT /internal/flow-apis/…`.

**Kết quả mong đợi.** Bước 1: tạo một API, lần hai cập nhật. Bước 2: mô tả `200`; đặc tả bị từ chối. Bước 3: 403-PQ.
:::

#### TC-02-027 · Sinh khung route chín chặng cho PH-04 từ đặc tả <!--k:flow-skeleton-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-026 · API-02-032, 095 · UC-02-10 · BR-02-010, 024 · ERR-02-037, 021 · UI-02-02.

**Tiền điều kiện, dữ liệu.** A-DRAFT với F-SPEC-OK; M-FLOW.

**Các bước.**

1. `POST …/flow-skeleton` cho thao tác có trong đặc tả.
2. Gọi cho thao tác không có trong đặc tả.
3. Gọi cho phiên bản chưa có backend `ACTIVE`.

**Kết quả mong đợi.** Bước 1: `202`, khung đủ chín chặng, không có logic nghiệp vụ. Bước 2: `422` ERR-02-037. Bước 3: `422` ERR-02-021.
:::

#### TC-02-098 · Đồng bộ lại đặc tả: đang chạy, kho đối tượng sự cố, tra tiến độ <!--k:resync-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API, IT

**Truy vết.** FR-02-012 · API-02-016, 095 · UI-02-02 · UC-02-08 · BR-02-014 · ERR-02-035, 034, 011, 001.

**Tiền điều kiện, dữ liệu.** A-DRAFT có URL nguồn trên M-URL; A-DATDAI (`PUBLISHED`); A-T01.

**Các bước.**

1. Hai `POST …:resync` liên tiếp cho cùng phiên bản `DRAFT`.
2. Tắt kho đối tượng (hộp giả) rồi `POST …:resync`.
3. `GET /operations/{id}` của tác vụ ở bước 1; rồi `GET /operations/{id của T01}`.
4. `POST …:resync` cho phiên bản `PUBLISHED`.

**Kết quả mong đợi.** Bước 1: `202` rồi `409` ERR-02-035. Bước 2: `503` ERR-02-034 kèm `retryAfterSeconds`, không đổi đặc tả. Bước 3: tiến độ đúng; định danh của T01 trả `404` ERR-02-001. Bước 4: `409` ERR-02-011, bản công bố không bị ghi đè.
:::

#### TC-02-099 · Tự đăng ký từ luồng: token tenant khác, scope sai, thân sai <!--k:flow-register-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-013 · API-02-017 · UC-02-09 · BR-02-030, 033 · ERR-02-014, 003, 001.

**Tiền điều kiện, dữ liệu.** S-FLOW của T68 và S-FLOW-T01; luồng `tc-luong-rest` của T68.

**Các bước.**

1. S-FLOW-T01 `PUT /internal/flow-apis/tc-luong-rest`.
2. S-FLOW gọi với thân thiếu `contractSpec`, rồi với `flowCode` khác đường dẫn.
3. Token `catalog:read` gọi cùng operation.

**Kết quả mong đợi.** Bước 1: API chỉ tạo ở T01 theo claim tenant của token; T68 không đổi và không lộ. Bước 2: `400` ERR-02-003, API cũ giữ nguyên. Bước 3: `403` ERR-02-014.
:::

#### TC-02-163 · Sinh lại khung route: không ghi đè luồng đã sửa, đặc tả rất lớn, không có logic nghiệp vụ <!--k:skeleton-regen-->

::: dac-ta
**Loại.** Dương, Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API, CT

**Truy vết.** FR-02-026 · API-02-032, 095 · UI-02-02 · UC-02-10 · BR-02-010 · ERR-02-035, 038, 034.

**Tiền điều kiện, dữ liệu.** A-DRAFT với F-SPEC-OK và với đặc tả 5.000 thao tác; M-FLOW; luồng `tc-khung` đã được kỹ sư sửa tay ở PH-04.

**Các bước.**

1. `POST …/flow-skeleton` cho đặc tả 5.000 thao tác; theo dõi `operationId`.
2. Gọi hai lần liền cho cùng thao tác.
3. Sinh lại khung cho thao tác đã có luồng `tc-khung` được sửa tay.
4. Gọi khi phiên bản ở `PENDING`; rồi khi M-FLOW không phản hồi.

**Kết quả mong đợi.** Bước 1: `202`, hoàn tất trong thời gian của tác vụ bất đồng bộ, khung đủ chín chặng cho từng thao tác, không có logic nghiệp vụ. Bước 2: `409` ERR-02-035 cho lần hai. Bước 3: PH-02 không ghi đè luồng đã sửa; trả khung mới dưới dạng đề xuất để PH-04 tự quyết. Bước 4: `409` ERR-02-038; `503` ERR-02-034.
:::

### TS-02-08 · Backend, cân bằng tải và sức khỏe

**Mục tiêu.** Xác nhận thay "Quản lý endpoint backend" của APIM cũ, kèm danh sách đích được phép, TLS tối thiểu, địa chỉ cấm.

**Phủ.** FR-02-022, 023, 025; UC-02-11; API-02-026, 027, 028, 029, 031, 032, 042; UI-02-02; BR-02-023, 024; LGC-APIM-018.

#### TC-02-028 · Khai báo hai backend, đặt trọng số và kiểm tra sức khỏe <!--k:backend-ok-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-022, 023, 025 · API-02-026, 027, 028, 031 · UI-02-02 · UC-02-11 · BR-02-024 · LGC-APIM-018.

**Tiền điều kiện, dữ liệu.** A-DRAFT; hai kết nối PH-05 cùng tenant.

**Các bước.**

1. `POST …/backends` hai lần, trọng số 70 và 30.
2. `PATCH` thời gian chờ 5.000 ms, thử lại 2, kiểm tra sức khỏe `/health`.
3. `GET …/backends/health`.

**Kết quả mong đợi.** `201/202`, `200`; sức khỏe từng backend hiển thị; tổng trọng số lớn hơn 0.
:::

#### TC-02-029 · Backend trỏ tới địa chỉ cấm, TLS thấp, ngoài danh sách cho phép <!--k:backend-ssrf-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-022 · API-02-027 · BR-02-023 · ERR-02-020 · NFR-02-011.

**Tiền điều kiện, dữ liệu.** Đích: `http://127.0.0.1`, `https://169.254.169.254`, `https://dh-control.svc`, host TLS 1.0, kết nối của T01.

**Các bước.**

1. Khai báo lần lượt từng đích.

**Kết quả mong đợi.** Mọi lần `422` ERR-02-020; không có bản ghi backend nào được tạo; log không chứa nội dung phản hồi từ đích.
:::

#### TC-02-030 · Giới hạn số backend, trần thời gian chờ, xóa backend cuối <!--k:backend-limit-->

::: dac-ta
**Loại.** Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-023, 022 · API-02-027, 028, 029 · BR-02-024 · ERR-02-040, 021, 003.

**Tiền điều kiện, dữ liệu.** `02.backend.max-per-version` = 10, `02.backend.max-timeout-ms` = 60.000.

**Các bước.**

1. Thêm backend thứ 11; đặt timeout 120.000 ms.
2. Đặt tổng trọng số 0; xóa backend `ACTIVE` cuối cùng rồi gửi duyệt.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-040. Bước 2: không gửi duyệt được, `422` ERR-02-021.
:::

#### TC-02-031 · Backend của tenant khác và phiên bản không thuộc tổ chức <!--k:backend-cross-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-022, 025 · API-02-026, 027, 031 · BR-02-032, 033 · ERR-02-001, 014.

**Tiền điều kiện, dữ liệu.** A-T01; U-T68-SV2.

**Các bước.**

1. U-T68-SV2 gọi `POST …/tc-dat-dai/…/backends`.
2. Người dùng T68 gọi `GET /apis/tc-chi-t01/versions/1.0.0/backends/health`.

**Kết quả mong đợi.** Bước 1: 403-PQ. Bước 2: 404-ẩn.
:::

#### TC-02-100 · Backend trỏ tới kết nối hoặc luồng của tenant khác, hoặc không đúng loại <!--k:backend-target-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-022 · API-02-027, 028, 032 · UI-02-02 · UC-02-11 · BR-02-023, 033 · ERR-02-020, 001 · SEC-16.

**Tiền điều kiện, dữ liệu.** Kết nối `tc-kn-t68` (PH-05, T68), `tc-kn-t01` (T01); luồng `tc-luong-t68`, `tc-luong-t01`; A-DRAFT.

**Các bước.**

1. `POST …/backends` đích kết nối `tc-kn-t68`, rồi luồng `tc-luong-t68`.
2. Lặp với `tc-kn-t01` và `tc-luong-t01`.
3. `PATCH` backend hợp lệ sang đích `tc-kn-t01`.
4. Đích là kết nối đã ngừng dùng ở PH-05.

**Kết quả mong đợi.** Bước 1: `201`. Bước 2, 3, 4: `422` ERR-02-020, thông báo chung không nói đối tượng có tồn tại ở tenant khác hay không; backend cũ không đổi.
:::

#### TC-02-101 · Sức khỏe backend: tenant khác, trạng thái từng backend, dịch vụ phụ thuộc sự cố <!--k:backend-health-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API, IT

**Truy vết.** FR-02-025 · API-02-031 · UI-02-02 · UC-02-11 · BR-02-033 · ERR-02-001, 034.

**Tiền điều kiện, dữ liệu.** A-DATDAI có hai backend, một chạy, một tắt; A-T01; U-T68-VW.

**Các bước.**

1. U-T68-VW `GET …/backends/health`.
2. `GET /apis/tc-chi-t01/versions/1.0.0/backends/health`.
3. Làm PH-03 (nguồn số liệu sức khỏe) không phản hồi rồi gọi lại.

**Kết quả mong đợi.** Bước 1: `200`, backend chạy `UP`, backend tắt `DOWN` kèm thời điểm kiểm tra gần nhất. Bước 2: `404` ERR-02-001. Bước 3: `503` ERR-02-034 kèm `retryAfterSeconds`; UI-02-02 hiện thẻ "chưa lấy được dữ liệu", không hiện `UP` giả.
:::

#### TC-02-102 · Trọng số backend: tổng bằng 0, âm, và xóa backend khiến hết trọng số <!--k:backend-weight-->

::: dac-ta
**Loại.** Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-022, 023 · API-02-028, 029, 042 · UI-02-02 · UC-02-11 · BR-02-024 · ERR-02-003, 012.

**Tiền điều kiện, dữ liệu.** A-DRAFT có hai backend trọng số 50 và 50; U-T68-SV1.

**Các bước.**

1. `PATCH` trọng số `-1`; rồi `101` (giả định miền hợp lệ 0…100, cơ sở: mẫu `weight: 100` ở D03-04-PH02).
2. Đặt cả hai trọng số `0`; sau đó `POST …:submit`.
3. Đặt `100` và `0`; `POST …:submit`.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-003. Bước 2: cho phép lưu nháp nhưng `:submit` trả `409` ERR-02-012 với `missing[]` có `NO_ACTIVE_BACKEND`. Bước 3: đủ điều kiện (tổng trọng số > 0), `:submit` qua điều kiện này.
:::

### TS-02-09 · Gói sử dụng: thông tin, kiểu xác thực, hạn mức

**Mục tiêu.** Xác nhận tạo gói thay bước Define, Secure của Plan ở APIM cũ, thêm OAuth 2.1 và mTLS, kiểu xác thực theo mức phân loại.

**Phủ.** FR-02-027, 028, 029; UC-02-12; API-02-033, 034, 035, 036, 041, 040; UI-02-06, 07; BR-02-016, 017, 021, 025, 040; LGC-APIM-009; 010, 011.

#### TC-02-032 · Tạo gói `API_KEY`, đặt hạn mức và đường dẫn cho phép <!--k:plan-create-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-027, 028, 029 · API-02-034, 036 · UI-02-07 · UC-02-12 · BR-02-040 · LGC-APIM-009; 010, 011 · EVT-02-08.

**Tiền điều kiện, dữ liệu.** A-DRAFT mức `INTERNAL`; U-T68-SV1.

**Các bước.**

1. `POST …/plans` mã `goi-co-ban`, đối tượng được xin là HTTT cấp tỉnh.
2. `PUT …/access-policy`: `API_KEY`, 100 lượt/phút, cho phép `GET /thua-dat/*`.

**Kết quả mong đợi.** `201` gói `STAGING`, `200` chính sách; EVT: `plan.state-changed`; đơn giá chỉ hiển thị (BR-02-040).
:::

#### TC-02-033 · Kiểu xác thực không hợp mức phân loại, hạn mức vô lý, mã gói trùng <!--k:plan-neg-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-027, 028, 029 · API-02-034, 036 · BR-02-016, 021 · ERR-02-022, 023, 002, 040.

**Tiền điều kiện, dữ liệu.** API `RESTRICTED`, API `SENSITIVE`, API `INTERNAL`.

**Các bước.**

1. `KEYLESS` cho API `INTERNAL`; `API_KEY` cho `RESTRICTED`; `OAUTH2_PKJWT` cho `SENSITIVE`.
2. Hạn mức 0, hạn mức âm; đường dẫn cho phép `/**` trên API chỉ có `GET`.
3. Tạo gói mã `goi-co-ban` lần hai; tạo gói thứ 11.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-022. Bước 2: `422` ERR-02-023. Bước 3: `409` ERR-02-002, `422` ERR-02-040.
:::

#### TC-02-034 · Gói `PUBLISHED` chỉ sửa theo hướng tương thích <!--k:plan-compat-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-028, 029 · API-02-035, 036 · BR-02-017 · ERR-02-011.

**Tiền điều kiện, dữ liệu.** Gói `goi-co-ban` của A-DATDAI (`PUBLISHED`, 100 lượt/phút).

**Các bước.**

1. Tăng hạn mức lên 200; thêm thao tác cho phép.
2. Hạ hạn mức xuống 50; đổi sang `OAUTH2_MTLS`.

**Kết quả mong đợi.** Bước 1: `200`. Bước 2: `409` ERR-02-011, thông báo hướng dẫn tạo gói mới.
:::

#### TC-02-103 · Ma trận kiểu xác thực theo mức phân loại dữ liệu (bảng tham số hóa) <!--k:plan-auth-matrix-->

::: dac-ta
**Loại.** Dương, Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API, UT

**Truy vết.** FR-02-028 · API-02-036, 040 · UI-02-07 · UC-02-12 · BR-02-016 · ERR-02-022 · SEC-24.

**Tiền điều kiện, dữ liệu.** Bốn API mẫu ở các mức `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` (mức hiển thị `PUBLIC` cho API đầu); U-T68-SV1.

**Các bước.**

1. Với mỗi API, `PUT …/access-policy` lần lượt `KEYLESS`, `API_KEY`, `OAUTH2_PKJWT`, `OAUTH2_MTLS` (16 cặp).
2. Cặp `PUBLIC` + `KEYLESS` nhưng mức hiển thị `ORG` (không phải `PUBLIC`).
3. `POST …/plans:copy-from` từ phiên bản có mức `INTERNAL` sang phiên bản đã nâng lên `RESTRICTED`, gói gốc dùng `API_KEY`.

**Kết quả mong đợi.** Chỉ các cặp hợp lệ `200`: `PUBLIC` nhận cả bốn kiểu, `INTERNAL` từ `API_KEY`, `RESTRICTED` chỉ `OAUTH2_PKJWT` hoặc `OAUTH2_MTLS`, `SENSITIVE` chỉ `OAUTH2_MTLS`; 10 cặp còn lại `422` ERR-02-022. Bước 2: `422` ERR-02-022 vì `KEYLESS` đòi hiển thị `PUBLIC`. Bước 3: `422` ERR-02-022, gói chưa được tạo ở phiên bản đích. UI-02-07 chỉ liệt kê kiểu hợp lệ ở danh sách chọn.
:::

#### TC-02-104 · Thao tác cho phép ngoài đặc tả và hạn mức vô lý <!--k:plan-paths-limits-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-029 · API-02-036 · UI-02-07 · UC-02-12 · BR-02-017 · ERR-02-037, 023, 003.

**Tiền điều kiện, dữ liệu.** A-DRAFT với đặc tả F-SPEC-OK (có `getDatDai`, `taoDatDai`); gói `goi-nhap`; U-T68-SV1.

**Các bước.**

1. `PUT …/access-policy` với `operationScopes` chỉ gồm `operationId` của `GET /dat-dai/{id}`.
2. Thêm `operationId` không có trong đặc tả (ví dụ `xoaDatDai`).
3. `quota.perSecond` = `0`, `-5`; rồi `dailyCalls` nhỏ hơn `perSecond` (ví dụ `perSecond` 20, `dailyCalls` 10).
4. Hạn mức hợp lệ sát giới hạn dưới (`perSecond` = 1, `dailyCalls` = 100).

**Kết quả mong đợi.** Bước 1, 4: `200`. Bước 2: `422` ERR-02-037 nêu thao tác thừa. Bước 3: `422` ERR-02-023 nêu trường không hợp lý (`quota.perSecond`, `quota.dailyCalls`); chính sách cũ không đổi.
:::

#### TC-02-105 · Giới hạn số gói mỗi phiên bản và đọc danh sách gói <!--k:plan-limit-read-->

::: dac-ta
**Loại.** Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-027 · API-02-033, 034 · UI-02-06 · UC-02-12 · BR-02-033, 039 · ERR-02-040, 001.

**Tiền điều kiện, dữ liệu.** A-DRAFT; `02.plan.max-per-version` = 10 (giả định mặc định, cơ sở: bảng tham số FRS PH-02 §tham số); U-T68-SV1, U-T68-SV2, U-T68-VW; A-T01.

**Các bước.**

1. U-T68-SV1 tạo gói thứ 1…10, rồi gói thứ 11.
2. U-T68-VW và U-T68-SV2 gọi `GET …/tc-nhap/versions/1.0.0/plans`.
3. U-T68-SV1 gọi `GET /apis/tc-chi-t01/versions/1.0.0/plans`.

**Kết quả mong đợi.** Gói thứ 11 `422` ERR-02-040 kèm `limit`. Bước 2: người ngoài tổ chức không thấy danh sách gói của bản `DRAFT` (rỗng). Bước 3: `404` ERR-02-001. UI-02-06 vô hiệu hóa nút "Tạo gói" khi đủ 10 gói và nêu lý do.
:::

#### TC-02-106 · Đơn giá của gói chỉ là thông tin hiển thị <!--k:plan-price-info-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P3 · **Tự động.** API, E2E

**Truy vết.** FR-02-027 · API-02-034 · UI-02-06, 07 · UC-02-12 · BR-02-040.

**Tiền điều kiện, dữ liệu.** A-DRAFT; U-T68-SV1.

**Các bước.**

1. Tạo gói `goi-gia` có `priceNote` "Miễn phí giữa cơ quan nhà nước".
2. Xem gói ở UI-02-06, 07 và ở danh mục cho máy.
3. Tìm trong hệ thống bất kỳ chức năng tính phí, hóa đơn từ PH-02.

**Kết quả mong đợi.** Đơn giá hiện đúng nhãn "thông tin tham khảo", không ảnh hưởng đăng ký hay hạn mức; PH-02 không có operation tính phí (thu phí thuộc PH-19).
:::

### TS-02-10 · Vòng đời gói: công bố, ngừng khuyến nghị, đóng, sao chép

**Mục tiêu.** Xác nhận bốn trạng thái gói giữ như APIM cũ, có duyệt bốn mắt.

**Phủ.** FR-02-027, 030, 031, 032, 033, 035; UC-02-12, 13, 14; API-02-037, 038, 039, 040, 045, 034, 041, 046, 096, 033; UI-02-06, 10; BR-02-008, 018, 019; LGC-APIM-009.

#### TC-02-035 · Công bố gói qua bốn mắt <!--k:plan-publish-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-030 · API-02-037, 045 · UI-02-06, 10 · UC-02-13 · BR-02-008 · ERR-02-013, 012, 014 · KT: có (plan.publish).

**Tiền điều kiện, dữ liệu.** Gói `STAGING`, phiên bản `PUBLISHED`; U-T68-SV1, U-T68-CA, U-T68-SV-CA, U-T68-VW.

**Các bước.**

1. U-T68-SV1 `:submit`; U-T68-VW `:submit`.
2. U-T68-SV1 phê duyệt chính yêu cầu của mình; U-T68-SV-CA vừa gửi vừa duyệt.
3. U-T68-CA `:approve`.

**Kết quả mong đợi.** Bước 1: `202`; VW 403-PQ. Bước 2: `403` ERR-02-013. Bước 3: gói `PUBLISHED`, GW: nạp plan.
:::

#### TC-02-036 · Ngừng khuyến nghị, đóng gói và điều kiện còn đăng ký <!--k:plan-close-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-031, 032 · API-02-038, 039, 041 · BR-02-018, 019 · ERR-02-024, 025, 011.

**Tiền điều kiện, dữ liệu.** `goi-co-ban` có SUB-ACTIVE; gói `goi-trong` không có đăng ký; H-KHAITHAC-1.

**Các bước.**

1. Ngừng khuyến nghị `goi-co-ban` (duyệt xong), rồi gửi đăng ký mới vào gói.
2. `:submit-close` `goi-co-ban`; rồi `:submit-close` `goi-trong`.
3. Hủy gói nháp bằng `DELETE`.

**Kết quả mong đợi.** Bước 1: đăng ký mới `409` ERR-02-025. Bước 2: `409` ERR-02-024, gói không đăng ký đóng được. Bước 3: `204`.
:::

#### TC-02-037 · Sao chép gói sang phiên bản mới <!--k:plan-copy-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-033 · API-02-040 · UI-02-06 · BR-02-021, 035 · ERR-02-002.

**Tiền điều kiện, dữ liệu.** A-DATDAI 1.0.0 có 2 gói; phiên bản 1.1.0 `DRAFT`.

**Các bước.**

1. `POST …/1.1.0/plans:copy-from` từ 1.0.0; gọi lần hai.

**Kết quả mong đợi.** Lần một tạo 2 gói `STAGING` cùng mã; lần hai `409` ERR-02-002.
:::

#### TC-02-107 · Ngừng khuyến nghị gói: hạn ngắn, thiếu gói kế nhiệm, ngoại lệ khẩn có TA đồng ý <!--k:plan-deprecate-neg-->

::: dac-ta
**Loại.** Âm, Dương, Biên · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-031 · API-02-038, 045 · UI-02-06, 10 · UC-02-14 · BR-02-004, 005, 008, 018 · ERR-02-031, 032, 013, 041.

**Tiền điều kiện, dữ liệu.** A-DATDAI có `goi-co-ban` (`PUBLISHED`, có SUB-ACTIVE) và `goi-co-ban-v2` (`PUBLISHED`); U-T68-SV1, U-T68-CA, U-T68-TA; `02.deprecation.min-days` = 180.

**Các bước.**

1. `POST …/plans/goi-co-ban:submit-deprecate` hạn 30 ngày.
2. Hạn 180 ngày nhưng không chỉ gói kế nhiệm.
3. Hạn 179 ngày, rồi đúng 180 ngày, gói kế nhiệm `goi-co-ban-v2`.
4. Hạn 30 ngày kèm cờ khẩn, lý do; CA duyệt (không phải TA).
5. Như bước 4, TA đồng ý trong yêu cầu duyệt.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-031 kèm hạn tối thiểu 180. Bước 2: `422` ERR-02-032. Bước 3: 179 ngày `422` ERR-02-031, 180 ngày `202`. Bước 4: CA không đủ quyền chấp nhận ngoại lệ (`403` ERR-02-013 hoặc yêu cầu giữ `PENDING` chờ TA). Bước 5: duyệt được. Sau duyệt, gói `DEPRECATED` không nhận đăng ký mới, đăng ký sẵn có tiếp tục (BR-02-018).
:::

#### TC-02-108 · Đóng gói còn đăng ký: danh sách nơi đang dùng và đóng được khi hết <!--k:plan-close-usages-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-032 · API-02-039, 045 · UI-02-06 · UC-02-14 · BR-02-019 · ERR-02-024.

**Tiền điều kiện, dữ liệu.** Gói `goi-dong` (`DEPRECATED`) có 3 đăng ký: `PENDING`, `ACTIVE`, `SUSPENDED`; U-T68-SV1, U-T68-CA.

**Các bước.**

1. `POST …/plans/goi-dong:submit-close`.
2. Hủy từng đăng ký (`PENDING` → `CANCELLED`, `ACTIVE` → `REVOKED`); gọi lại sau mỗi lần.
3. Còn đăng ký `SUSPENDED` duy nhất; gọi lại.
4. Hủy nốt; gọi lại; CA duyệt.

**Kết quả mong đợi.** Bước 1, 2, 3: `409` ERR-02-024 với `usages[]` giảm dần 3, 2, 1 phần tử (`kind`, `ref`), không có dữ liệu cá nhân; đăng ký `SUSPENDED` vẫn tính là còn hiệu lực. Bước 4: `202`; sau duyệt gói `CLOSED`, mã gói không dùng lại.
:::

#### TC-02-109 · Hủy gói nháp và mã gói đã hủy không dùng lại <!--k:plan-delete-draft-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-032 · API-02-034, 041 · UI-02-06 · UC-02-14 · BR-02-021, 028 · ERR-02-011, 002, 041.

**Tiền điều kiện, dữ liệu.** A-DRAFT có gói `goi-huy` ở `STAGING`; A-DATDAI `goi-co-ban` ở `PUBLISHED`; U-T68-SV1.

**Các bước.**

1. `DELETE …/plans/goi-huy` (không lý do) rồi có lý do.
2. `POST …/plans` tạo lại mã `goi-huy`.
3. `DELETE …/plans/goi-co-ban` (gói `PUBLISHED`).

**Kết quả mong đợi.** Bước 1: `400` ERR-02-041, rồi `204` xóa mềm, vẫn còn trong lịch sử. Bước 2: `409` ERR-02-002. Bước 3: `409` ERR-02-011, phải theo đường ngừng khuyến nghị và đóng.
:::

#### TC-02-110 · Từ chối công bố gói: thiếu lý do, yêu cầu đã xử lý, quay về nháp <!--k:plan-reject-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-030, 035 · API-02-037, 045, 046 · UI-02-10 · UC-02-13 · BR-02-008, 028 · ERR-02-041, 011.

**Tiền điều kiện, dữ liệu.** A-DRAFT có gói `goi-tu-choi` đủ điều kiện; U-T68-SV1, U-T68-CA.

**Các bước.**

1. SV gửi duyệt công bố gói; CA `:reject` không lý do.
2. CA `:reject` có lý do; sau đó CA `:approve` cùng yêu cầu.
3. SV sửa gói và gửi lại.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-041. Bước 2: từ chối `200`, gói về `STAGING`, SV nhận thông báo kèm lý do; duyệt lại yêu cầu đã xử lý `409` ERR-02-011. Bước 3: tạo yêu cầu duyệt mới `202`.
:::

#### TC-02-166 · Danh sách gói toàn tenant: lọc, phân trang, đếm theo trạng thái, cách ly <!--k:plans-list-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-027, 031 · API-02-096, 033 · UI-02-06 · UC-02-12, 14 · BR-02-039 · ERR-02-003, 001.

**Tiền điều kiện, dữ liệu.** A-DATDAI (hai gói), A-DRAFT (một gói `STAGING`), A-DEPREC (gói `DEPRECATED`), A-T01 ở tenant T01; người dùng U-T68-SV1, U-T68-SV2, U-T68-VW.

**Các bước.**

1. U-T68-VW gọi `GET /plans?size=2&page=1`, rồi `page=2`.
2. U-T68-VW gọi `GET /plans?status=DEPRECATED&authType=OAUTH2_MTLS`.
3. U-T68-SV2 gọi `GET /plans?apiCode=tc-nhap` (API `DRAFT` của tổ chức khác).
4. Gọi `GET /plans?size=500` và `GET /plans?authType=KHONG-CO`.
5. Tìm mã gói của T01 trong kết quả của U-T68-VW.

**Kết quả mong đợi.** Bước 1: `200`, `totalElements` bằng số gói người gọi được xem, hai trang không trùng dòng, `counts` đếm theo `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED`. Bước 2: chỉ gói `DEPRECATED` đúng kiểu xác thực, mỗi dòng nêu API, phiên bản và `versionStatus`. Bước 3: danh sách rỗng, không lộ sự tồn tại của `tc-nhap` (BR-02-039). Bước 4: `400` ERR-02-003 kèm `errors[]` theo trường. Bước 5: không có gói của T01. UI-02-06 hiện đúng số gói và nhãn trạng thái.
:::

### TS-02-11 · Gửi duyệt, duyệt bốn mắt và công bố API

**Mục tiêu.** Xác nhận vòng đời `DRAFT → PENDING → PUBLISHED`, thử TEST, khóa nội dung và chỉ công bố khi gateway nhận cấu hình.

**Phủ.** FR-02-034, 035, 036, 014, 022, 027, 028, 029, 059; UC-02-15, 16; API-02-042, 043, 044, 098, 045, 046, 047, 082, 016, 018, 027, 028, 029, 034, 035, 036; UI-02-02, 10; BR-02-001, 003, 008, 014, 024; LGC-APIM-004; 006.

#### TC-02-038 · Gửi duyệt thiếu điều kiện <!--k:submit-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-034 · API-02-042 · BR-02-001, 015, 024 · ERR-02-012, 021, 008, 041.

**Tiền điều kiện, dữ liệu.** Ba phiên bản nháp: không gói, không backend, đặc tả lỗi; `02.submit.require-test-deploy` = true, chưa thử TEST.

**Các bước.**

1. Gửi duyệt từng phiên bản; gửi duyệt phiên bản chưa thử TEST.

**Kết quả mong đợi.** `409` ERR-02-012 kèm danh sách điều kiện còn thiếu, hoặc `422` ERR-02-021, ERR-02-008; phiên bản vẫn `DRAFT`.
:::

#### TC-02-039 · Gửi duyệt, rút lại, duyệt và công bố ra gateway <!--k:publish-flow-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-034, 035, 036 · API-02-042, 043, 044, 045, 047, 082 · UI-02-02, 10 · UC-02-15, 16 · EVT-02-04, 05 · KT: có (version.publish) · LGC-APIM-004; 006.

**Tiền điều kiện, dữ liệu.** A-DRAFT đủ điều kiện, đã thử TEST; U-T68-SV1, U-T68-CA; M-GW.

**Các bước.**

1. Gửi duyệt, rút lại, gửi lại; thử sửa khi `PENDING`.
2. U-T68-CA `GET /review-requests`, `:approve`.
3. M-GW xác nhận qua `POST /internal/gateway/apply-acks`.

**Kết quả mong đợi.** Sửa khi chờ duyệt `409` ERR-02-038. Duyệt xong phiên bản `PUBLISHED`, EVT: `version.published`, GW: nạp route trong ≤ 30 giây, API xuất hiện trong danh mục.
:::

#### TC-02-040 · Bốn mắt: người duyệt trùng người gửi hoặc người sửa gần nhất; API `SENSITIVE` <!--k:four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-035 · API-02-045, 046 · BR-02-008 · ERR-02-013, 014.

**Tiền điều kiện, dữ liệu.** U-T68-SV-CA sửa gần nhất đặc tả; API `SENSITIVE` chờ duyệt; U-T68-CA, U-T68-CA2, U-T68-TA.

**Các bước.**

1. U-T68-SV-CA duyệt yêu cầu mình gửi và yêu cầu do mình sửa.
2. U-T68-CA duyệt API `SENSITIVE` một mình.
3. Bổ sung xác nhận của U-T68-TA khác U-T68-CA; U-T68-CA2 từ chối kèm ý kiến.

**Kết quả mong đợi.** Bước 1: `403` ERR-02-013. Bước 2: chưa công bố, thiếu xác nhận TA. Bước 3: công bố được; từ chối có lý do, trả về `DRAFT`.
:::

#### TC-02-041 · Gateway không nhận cấu hình: công bố không hoàn tất <!--k:publish-gw-fail-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-036 · API-02-047, 082 · BR-02-014 · ERR-02-033, 034.

**Tiền điều kiện, dữ liệu.** M-GW không trả xác nhận quá 60 giây; phiên bản đã được duyệt.

**Các bước.**

1. Thực hiện công bố; chờ quá hạn.
2. Bật lại M-GW, thử lại.

**Kết quả mong đợi.** Bước 1: `503` ERR-02-033, phiên bản chưa `PUBLISHED`, danh mục không hiển thị, không mất đặc tả. Bước 2: công bố thành công, một lần duy nhất.
:::

#### TC-02-111 · Gửi duyệt phiên bản: chặn do đặc tả, phá vỡ giữ số chính, số hiệu không tăng <!--k:submit-spec-block-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-034 · API-02-042 · UI-02-02, 04 · UC-02-15 · BR-02-001, 003, 015 · ERR-02-006, 007, 017, 018, 008.

**Tiền điều kiện, dữ liệu.** Năm phiên bản nháp có backend, gói đủ: đặc tả F-SPEC-L1; F-SPEC-L2 (lỗi nghiêm trọng); đặc tả đổi kiểu trường nhưng giữ `1.x.x`; số hiệu bằng số hiệu trước; F-SPEC-SECRET.

**Các bước.**

1. `POST …:submit` lần lượt cho từng phiên bản.
2. Lặp lại sau khi sửa đúng từng lỗi.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-006 (lớp 1), ERR-02-007 (lớp 2), `409` ERR-02-017 kèm `suggestedVersion`, `422` ERR-02-018, `422` ERR-02-008 (`findings[]` chỉ `ruleId`, `location`, `message`, giá trị bí mật không lặp lại). Không phiên bản nào sang `PENDING`. Bước 2: `202` cho từng phiên bản đã sửa.
:::

#### TC-02-112 · Từ chối yêu cầu duyệt phiên bản và gửi lại <!--k:review-reject-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-035 · API-02-042, 044, 046 · UI-02-10 · UC-02-16 · BR-02-008, 028 · ERR-02-041, 011.

**Tiền điều kiện, dữ liệu.** A-DRAFT đủ điều kiện; U-T68-SV1, U-T68-CA, U-T68-CA2, U-T68-VW.

**Các bước.**

1. SV gửi duyệt; U-T68-VW gọi `GET /review-requests`; CA gọi cùng lệnh.
2. CA gọi `:reject` không lý do; rồi có lý do.
3. SV `:withdraw` yêu cầu đã bị từ chối.
4. SV sửa, gửi lại; CA2 duyệt.

**Kết quả mong đợi.** Bước 1: danh sách của VW không chứa yêu cầu nào (chỉ người có quyền duyệt thấy yêu cầu chờ mình), danh sách của CA có yêu cầu. Bước 2: `400` ERR-02-041, rồi `200`, phiên bản về `DRAFT`. Bước 3: `409` ERR-02-011. Bước 4: `202` rồi `200`, kiểm toán ghi đủ lượt gửi, từ chối, gửi lại.
:::

#### TC-02-113 · Yêu cầu duyệt quá `02.review.overdue-days` và nhắc <!--k:review-overdue-->

::: dac-ta
**Loại.** Biên, Dương · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** FR-02-035 · API-02-044 · UI-02-10 · UC-02-16 · BR-02-028 · EVT-02-16 · NFR-02-015.

**Tiền điều kiện, dữ liệu.** Yêu cầu duyệt `RV-1` gửi cách đây 4 ngày 23 giờ, `RV-2` cách đây 5 ngày 1 giờ (đồng hồ giả); `02.review.overdue-days` = 5, `02.review.reminder-days` đặt theo bảng tham số.

**Các bước.**

1. Chạy bộ nhắc duyệt.
2. `GET /review-requests?overdue=true` bằng U-T68-CA.
3. CA duyệt `RV-2`; chạy lại bộ nhắc.

**Kết quả mong đợi.** `RV-1` chưa gắn nhãn quá hạn; `RV-2` có cảnh báo gửi tới CA và TA đúng một lần và phát đúng một sự kiện EVT-02-16 (`{tenant}.catalog.review.overdue.v1`, khóa phân vùng `reviewRequestId`), UI-02-10 hiện chỉ báo "quá hạn". Sau khi duyệt, không còn nhắc và không phát thêm sự kiện.
:::

#### TC-02-114 · Công bố: lặp lệnh, xác nhận nạp cấu hình bị gửi lại <!--k:publish-idempotent-->

::: dac-ta
**Loại.** Biên, Dương · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-036, 059 · API-02-047, 082 · UC-02-16, 35 · BR-02-028 · ERR-02-042.

**Tiền điều kiện, dữ liệu.** Yêu cầu duyệt đã duyệt, chờ công bố; S-GW-ACK (scope `catalog:gateway-ack`); M-GW.

**Các bước.**

1. `POST …:publish` hai lần cùng `Idempotency-Key`, cùng thân.
2. `POST …:publish` cùng khóa, khác thân.
3. S-GW-ACK gửi `POST /internal/gateway/apply-acks` hai lần cho cùng bản cấu hình.

**Kết quả mong đợi.** Bước 1: lần hai trả lại phản hồi cũ, chỉ một lần đẩy cấu hình sang M-GW, một sự kiện công bố. Bước 2: `422` ERR-02-042. Bước 3: cả hai `204`, trạng thái phiên bản `PUBLISHED` một lần, không phát hai thông báo.
:::

#### TC-02-164 · Phiên bản đang chờ duyệt bị khóa: mọi lệnh sửa trả `409` <!--k:pending-lock-all-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-014, 022, 027, 028, 029, 034, 036 · API-02-016, 018, 027, 028, 029, 034, 035, 036 · UI-02-02 · UC-02-15 · BR-02-008 · ERR-02-038.

**Tiền điều kiện, dữ liệu.** Phiên bản A-DRAFT đã `:submit` (trạng thái `PENDING`), có một backend và một gói; U-T68-SV1.

**Các bước.**

1. Lần lượt gọi từng operation sửa trên phiên bản: đồng bộ lại đặc tả, sửa API, thêm, sửa, xóa backend, tạo gói, sửa gói, đổi chính sách truy cập.
2. `:withdraw` rồi gọi lại bộ lệnh trên.

**Kết quả mong đợi.** Bước 1: mọi lệnh `409` ERR-02-038, dữ liệu không đổi, không có dòng kiểm toán. Bước 2: sau rút lại phiên bản về `DRAFT`, mọi lệnh sửa thành công.
:::

#### TC-02-167 · Chi tiết yêu cầu duyệt: điều kiện, lịch sử và ETag dùng cho quyết định <!--k:review-detail-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-035, 047 · API-02-098, 045 · UI-02-10 · UC-02-16, 24 · BR-02-008 · ERR-02-001, 015.

**Tiền điều kiện, dữ liệu.** Yêu cầu duyệt `RV-1` loại `VERSION_PUBLISH` của A-DRAFT đang `PENDING`, có một lần hỏi thêm và một lần trả lời; yêu cầu `RV-T01` của tenant T01; người dùng U-T68-CA, U-T68-SV1, U-T68-VW.

**Các bước.**

1. U-T68-CA gọi `GET /review-requests/{RV-1}`.
2. U-T68-CA gọi `POST /review-requests/{RV-1}:approve` với `If-Match` lấy từ bước 1.
3. U-T68-CA gọi lại API-02-098 cho `RV-1` bằng `If-Match` cũ ở lệnh duyệt thứ hai (giả lập người duyệt thứ hai tải chậm).
4. U-T68-CA gọi API-02-098 với mã của `RV-T01` và với mã không tồn tại.
5. U-T68-VW gọi API-02-098 cho `RV-1`.

**Kết quả mong đợi.** Bước 1: `200`, `request.status = PENDING`, `conditions[]` mỗi điều kiện có `met`, `history[]` đủ gửi, hỏi thêm, trả lời theo thứ tự thời gian, tiêu đề `ETag`. Bước 2: `200`. Bước 3: `412` ERR-02-015 vì `etag` đã đổi. Bước 4: cả hai đều `404` ERR-02-001, thân giống nhau trừ `traceId`. Bước 5: `200` (VW có `PERM-02-read`) nhưng `request.canDecide = false`; UI-02-10 khóa nút "Duyệt".
:::

### TS-02-12 · Tạm ngừng khẩn và tiếp tục

**Mục tiêu.** Xác nhận thay Start/Stop API, tạm ngừng không cần duyệt có thời hạn tối đa.

**Phủ.** FR-02-037, 023, 036; UC-02-17; API-02-048, 049, 028, 047; UI-02-02; BR-02-034; LGC-APIM-005.

#### TC-02-042 · Tạm ngừng khẩn, tiếp tục, hết thời hạn tối đa <!--k:suspend-resume-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-037 · API-02-048, 049 · UI-02-02 · UC-02-17 · BR-02-034 · EVT-02-06 · KT: có (version.suspend) · LGC-APIM-005.

**Tiền điều kiện, dữ liệu.** A-DATDAI `PUBLISHED`; U-T68-SO, U-T68-TO; `02.suspend.max-days` = 30.

**Các bước.**

1. U-T68-SO `:suspend` lý do an ninh; U-T68-TO `:resume`.
2. U-T68-TO `:resume` sau khi SO tạm ngừng; U-T68-SO `:resume`.
3. Đẩy đồng hồ 31 ngày.

**Kết quả mong đợi.** Bước 1: `200`, GW: gỡ route; TO không tiếp tục được vì SO tạm ngừng vì an ninh. Bước 2: SO tiếp tục được, GW: nạp route. Bước 3: cảnh báo quá hạn tạm ngừng.
:::

#### TC-02-043 · Tạm ngừng thiếu lý do hoặc sai quyền hoặc sai trạng thái <!--k:suspend-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-037 · API-02-048, 049 · BR-02-034 · ERR-02-041, 014, 011, 039.

**Tiền điều kiện, dữ liệu.** A-DATDAI; A-DRAFT; U-T68-SV1; cờ đóng băng thay đổi PROD.

**Các bước.**

1. Tạm ngừng không có `reason`; SV1 tạm ngừng; tạm ngừng phiên bản `DRAFT`.
2. Bật đóng băng rồi tạm ngừng.

**Kết quả mong đợi.** `400` ERR-02-041; 403-PQ; `409` ERR-02-011; `423` ERR-02-039.
:::

#### TC-02-115 · Tạm ngừng vì an ninh: ai được tiếp tục <!--k:suspend-owner-rule-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-037 · API-02-048, 049 · UI-02-02 · UC-02-17 · BR-02-034 · ERR-02-014, 041.

**Tiền điều kiện, dữ liệu.** A-DATDAI `PUBLISHED`; U-T68-SO, U-T68-TO, U-T68-TA.

**Các bước.**

1. U-T68-SO `:suspend` vì an ninh, có lý do.
2. U-T68-TO `:resume`.
3. U-T68-TA `:resume`; rồi U-T68-TO `:suspend` rồi `:resume`.
4. U-T68-SO `:resume` không lý do.

**Kết quả mong đợi.** Bước 2: `403` ERR-02-014 (chỉ SO hoặc TA tiếp tục bản SO tạm ngừng vì an ninh). Bước 3: TA `200`; TO tạm ngừng thì chính TO hoặc TA tiếp tục được. Bước 4: `400` ERR-02-041. Mọi lần có kiểm toán trước, sau.
:::

#### TC-02-165 · Đóng băng thay đổi môi trường thật: chặn các lệnh ghi lên gateway, vẫn đọc được <!--k:freeze-window-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-023, 036, 037 · API-02-028, 047, 048 · UI-02-02 · UC-02-15, 17 · ERR-02-039.

**Tiền điều kiện, dữ liệu.** Cờ đóng băng thay đổi PROD đặt tới `T+2 giờ` (đồng hồ giả); A-DATDAI `PUBLISHED`, một yêu cầu công bố đã duyệt; U-T68-TA, U-T68-SV1, U-T68-TO.

**Các bước.**

1. Trong thời gian đóng băng: `PATCH` backend, `:publish`, `:suspend` (cùng giả định của TC-02-043: đóng băng chặn mọi lệnh ghi lên gateway, kể cả tạm ngừng; câu hỏi liên quan ở Q02-45 của D02-04-PH02).
2. `GET` danh mục, chi tiết, lịch sử.
3. Đẩy đồng hồ qua `T+2 giờ` rồi gọi lại các lệnh ở bước 1.

**Kết quả mong đợi.** Bước 1: `423` ERR-02-039 kèm thời điểm kết thúc đóng băng, UI hiện dải thông báo đầu trang. Bước 2: đọc bình thường `200`. Bước 3: các lệnh thành công; không lệnh nào bị chạy ngầm trong lúc đóng băng.
:::

### TS-02-13 · Phiên bản mới, so sánh và tác động

**Mục tiêu.** Xác nhận phiên bản, phân loại thay đổi phá vỡ và phân tích bên bị ảnh hưởng.

**Phủ.** FR-02-042, 043, 044, 036; UC-02-18; API-02-054, 055, 056, 042; UI-02-05; BR-02-003, 006, 035; NFR-02-004.

#### TC-02-044 · Tạo phiên bản mới, so sánh phá vỡ và tác động <!--k:version-diff-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-042, 043, 044 · API-02-054, 055, 056 · UI-02-05 · UC-02-18 · BR-02-003, 035 · NFR-02-004.

**Tiền điều kiện, dữ liệu.** A-DATDAI 1.0.0 có SUB-ACTIVE; U-T68-SV1.

**Các bước.**

1. `POST /apis/tc-dat-dai/versions` số 2.0.0 và bản 1.1.0.
2. Đổi kiểu một trường bắt buộc ở 2.0.0; `GET /version-diff?from=1.0.0&to=2.0.0`.
3. `GET …/2.0.0/impact`.

**Kết quả mong đợi.** `201`; diff phân loại "phá vỡ", sinh ≤ 3 giây; impact liệt kê H-KHAITHAC-1 và đăng ký bị ảnh hưởng; 2.0.0 có đường dẫn `/v2` chạy song song.
:::

#### TC-02-045 · Phá vỡ nhưng giữ số chính, số hiệu không tăng, lặp số <!--k:version-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-042, 043 · API-02-054, 042 · BR-02-003, 021 · ERR-02-017, 018, 002, 014.

**Tiền điều kiện, dữ liệu.** Bản 1.1.0 có thay đổi phá vỡ so với 1.0.0; U-T68-SV2.

**Các bước.**

1. Gửi duyệt 1.1.0.
2. Tạo phiên bản `0.9.0`; tạo lại `1.0.0`.
3. U-T68-SV2 tạo phiên bản cho `tc-dat-dai`.

**Kết quả mong đợi.** `409` ERR-02-017; `422` ERR-02-018; `409` ERR-02-002; 403-PQ.
:::

#### TC-02-046 · Tác động của phiên bản không tồn tại, tenant khác <!--k:impact-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-044, 043 · API-02-055, 056 · BR-02-033 · ERR-02-001.

**Tiền điều kiện, dữ liệu.** A-T01.

**Các bước.**

1. `GET /apis/tc-chi-t01/version-diff`; `GET /apis/tc-dat-dai/versions/9.9.9/impact`.

**Kết quả mong đợi.** Cả hai 404-ẩn.
:::

#### TC-02-116 · So sánh phiên bản: tham số sai, cùng một phiên bản, tenant khác <!--k:version-diff-params-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-043 · API-02-055 · UI-02-05 · UC-02-18 · BR-02-033 · ERR-02-003, 001.

**Tiền điều kiện, dữ liệu.** A-DATDAI 1.0.0, 1.1.0, 2.0.0; A-T01; U-T68-VW.

**Các bước.**

1. `GET /apis/tc-dat-dai/version-diff?from=1.0.0` (thiếu `to`).
2. `from=1.0.0&to=1.0.0`.
3. `from=1.0.0&to=9.9.9`.
4. `GET /apis/tc-chi-t01/version-diff?from=1.0.0&to=1.1.0`.
5. `from=2.0.0&to=1.0.0` (ngược chiều).

**Kết quả mong đợi.** Bước 1: `400` ERR-02-003. Bước 2: `200` không có thay đổi. Bước 3: `404` ERR-02-001. Bước 4: `404`, cùng thân. Bước 5: `200`, báo cáo theo chiều ngược, thay đổi "thêm" thành "bớt". UI-02-05 hiện đúng trạng thái "không có thay đổi".
:::

#### TC-02-117 · Công bố phiên bản cùng số chính khi thiếu gói cùng mã <!--k:version-plan-parity-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-042, 036 · API-02-042, 054 · UI-02-02 · UC-02-18 · BR-02-024, 035 · ERR-02-012.

**Tiền điều kiện, dữ liệu.** A-DATDAI 1.0.0 có `goi-co-ban` với SUB-ACTIVE; phiên bản 1.1.0 tương thích, chỉ có gói `goi-moi`; U-T68-SV1.

**Các bước.**

1. `POST …/1.1.0:submit`.
2. `POST …/1.1.0/plans:copy-from` từ 1.0.0 (sao chép `goi-co-ban`); gửi lại.
3. Duyệt, công bố 1.1.0.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-012, `missing[]` nêu thiếu gói cùng mã với gói đang có đăng ký. Bước 2: `202`. Bước 3: 1.1.0 thay 1.0.0 ở cùng đường dẫn `/v1`; SUB-ACTIVE vẫn gọi được, không phải đăng ký lại.
:::

### TS-02-14 · Ngừng khuyến nghị, ngừng hẳn, xóa API

**Mục tiêu.** Xác nhận lộ trình ngừng dùng có kế nhiệm, hạn tối thiểu, không ngừng hẳn khi còn đăng ký, xóa mềm giữ bằng chứng.

**Phủ.** FR-02-038, 039, 040, 044; UC-02-19, 20; API-02-050, 051, 052, 014, 045; UI-02-13; BR-02-004, 005, 006, 014, 020, 021; LGC-APIM-008.

#### TC-02-047 · Ngừng khuyến nghị có kế nhiệm, đúng hạn tối thiểu <!--k:deprecate-ok-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-038 · API-02-050, 045 · UI-02-13 · UC-02-19 · BR-02-004, 005 · EVT-02-06 · LGC-APIM-008.

**Tiền điều kiện, dữ liệu.** `tc-cu` 1.0.0 `PUBLISHED` có đăng ký, 2.0.0 `PUBLISHED`; U-T68-SV1, U-T68-CA.

**Các bước.**

1. `:propose-deprecate` hạn 200 ngày, kế nhiệm 2.0.0; CA duyệt.

**Kết quả mong đợi.** Phiên bản `DEPRECATED`; thông báo bắt buộc tới bên khai thác; lịch nhắc 90, 30, 7 ngày.
:::

#### TC-02-048 · Ngừng khuyến nghị thiếu kế nhiệm hoặc hạn ngắn <!--k:deprecate-neg-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-038 · API-02-050 · BR-02-004, 005 · ERR-02-031, 032.

**Tiền điều kiện, dữ liệu.** `02.deprecation.min-days` = 180.

**Các bước.**

1. Đề nghị hạn 179 ngày (không lý do khẩn); hạn 180 ngày.
2. Đề nghị không có kế nhiệm và không xác nhận ngừng hẳn dịch vụ.

**Kết quả mong đợi.** 179 ngày `422` ERR-02-031; 180 ngày được chấp nhận; thiếu kế nhiệm `422` ERR-02-032.
:::

#### TC-02-049 · Ngừng hẳn khi còn đăng ký hiệu lực, hủy bản nháp <!--k:retire-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-039 · API-02-051 · BR-02-006, 014 · ERR-02-030, 011.

**Tiền điều kiện, dữ liệu.** A-DEPREC còn SUB-ACTIVE; A-DRAFT.

**Các bước.**

1. `:propose-retire` A-DEPREC tới hạn.
2. Hủy A-DRAFT bằng `:propose-retire`.
3. Hủy toàn bộ đăng ký rồi thử lại bước 1.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-030, không tự chuyển `RETIRED`. Bước 2: phiên bản `RETIRED`, đặc tả vẫn lưu. Bước 3: được duyệt.
:::

#### TC-02-050 · Xóa mềm API: điều kiện, mã không dùng lại <!--k:delete-api-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-040 · API-02-052, 014 · BR-02-020, 021, 014 · ERR-02-030, 002 · EVT-02-03 · KT: có (api.delete).

**Tiền điều kiện, dữ liệu.** `tc-nhap` (chỉ `DRAFT`); A-DATDAI.

**Các bước.**

1. `DELETE /apis/tc-dat-dai`.
2. `DELETE /apis/tc-nhap`; đăng ký lại mã `tc-nhap`.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-030. Bước 2: `204`, EVT: `api.deleted`, bản ghi vẫn còn (xóa mềm), đăng ký lại `409` ERR-02-002.
:::

#### TC-02-118 · Nhắc ngừng khuyến nghị theo mốc 90, 30, 7 ngày <!--k:deprecate-reminders-->

::: dac-ta
**Loại.** Biên, Dương · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** FR-02-038, 044 · API-02-050 · UI-02-13 · UC-02-19 · BR-02-004, 029 · NFR-02-015.

**Tiền điều kiện, dữ liệu.** A-DEPREC có hạn chuyển đổi còn 91 ngày, SUB-ACTIVE; đồng hồ giả; `02.deprecation.reminders` = 90, 30, 7.

**Các bước.**

1. Chạy bộ nhắc ở ngày còn 91, 90, 89 ngày; lặp lại trong cùng ngày.
2. Chạy ở các mốc 31, 30, 8, 7, 1 ngày.
3. Đổi `02.deprecation.reminders` thành `60, 14` rồi chạy lại ở mốc 60.

**Kết quả mong đợi.** Mỗi mốc gửi đúng một thông báo tới SV và bên đăng ký của A-DEPREC (không gửi lặp trong cùng mốc); ngày 91, 89, 31, 8, 1 không gửi. Sau khi đổi tham số, mốc 60 gửi, mốc 90 không gửi nữa.
:::

#### TC-02-119 · Tới hạn ngừng hẳn khi còn đăng ký: không tự chuyển `RETIRED` <!--k:retire-due-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P1 · **Tự động.** IT

**Truy vết.** FR-02-039, 044 · API-02-051 · UI-02-13 · UC-02-20 · BR-02-006 · ERR-02-030.

**Tiền điều kiện, dữ liệu.** A-DEPREC đã quá hạn chuyển đổi, còn đăng ký `ACTIVE`; `tc-cu-het` quá hạn, đăng ký `SUSPENDED`; `tc-cu-sach` quá hạn, không còn đăng ký; đồng hồ giả.

**Các bước.**

1. Chạy bộ xử lý hạn ngừng dùng.
2. Đề nghị ngừng hẳn A-DEPREC (`propose-retire`).
3. Hủy mọi đăng ký của A-DEPREC rồi đề nghị lại; CA duyệt.

**Kết quả mong đợi.** Bước 1: không phiên bản nào tự `RETIRED`; A-DEPREC và `tc-cu-het` có cảnh báo gửi SV, CA, TA; `tc-cu-sach` vẫn chờ người can thiệp (không tự động). Bước 2: `409` ERR-02-030 kèm `usages[]`. Bước 3: `202`, sau duyệt `RETIRED`, đường dẫn giữ chỗ 12 tháng.
:::

#### TC-02-120 · Xóa API: còn phiên bản đang phục vụ, còn đăng ký, và sai tổ chức <!--k:delete-api-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-040 · API-02-052 · UI-02-02 · UC-02-20 · BR-02-020, 032 · ERR-02-030, 011, 014, 001.

**Tiền điều kiện, dữ liệu.** A-DATDAI (`PUBLISHED`); `tc-ngung` chỉ còn phiên bản `RETIRED` và một đăng ký `SUSPENDED`; U-T68-SV1, U-T68-SV2.

**Các bước.**

1. U-T68-SV1 `DELETE /apis/tc-dat-dai`.
2. `DELETE /apis/tc-ngung`.
3. U-T68-SV2 `DELETE /apis/tc-dat-dai`.
4. `DELETE /apis/khong-co`.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-011 (còn phiên bản `PUBLISHED`). Bước 2: `409` ERR-02-030 kèm `usages[]` (đăng ký `SUSPENDED` vẫn tính). Bước 3: `403` ERR-02-014 hoặc `404` ERR-02-001 theo quyền; API không đổi. Bước 4: `404`.
:::

### TS-02-15 · Mức hiển thị và chuyển chủ quản

**Mục tiêu.** Xác nhận mức hiển thị theo phân loại, gỡ khỏi cổng nhà phát triển, chuyển chủ quản.

**Phủ.** FR-02-041, 045, 054; UC-02-21, 22; API-02-053, 057, 069; UI-02-02; BR-02-008, 009, 032, 037; LGC-APIM-006.

#### TC-02-051 · Đặt mức hiển thị `NATIONAL` cần CA duyệt; `PUBLIC` với dữ liệu không công khai bị chặn <!--k:visibility-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-041 · API-02-053 · UI-02-02 · UC-02-21 · BR-02-037, 008, 009 · ERR-02-043, 014 · EVT-02-02 · LGC-APIM-006.

**Tiền điều kiện, dữ liệu.** A-DATDAI `INTERNAL`; U-T68-SV1, U-T68-CA.

**Các bước.**

1. Đặt `PUBLIC`; đặt `NATIONAL` bằng SV1; CA duyệt.
2. Gỡ khỏi cổng nhà phát triển.

**Kết quả mong đợi.** `PUBLIC` `422` ERR-02-043; `NATIONAL` chờ CA, sau duyệt thành công và vào hàng đồng bộ quốc gia; gỡ cổng có thông báo bắt buộc.
:::

#### TC-02-052 · Chuyển chủ quản API chỉ TA, kiểm tra đơn vị đích <!--k:transfer-owner-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-045 · API-02-057 · BR-02-032 · ERR-02-004, 014 · KT: có (api.transfer-owner).

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-SV1; đơn vị đích `ACTIVE`; đơn vị không tồn tại.

**Các bước.**

1. U-T68-SV1 `PUT /apis/tc-dat-dai/owner`.
2. U-T68-TA chuyển sang đơn vị không tồn tại, rồi sang đơn vị hợp lệ.

**Kết quả mong đợi.** 403-PQ; `422` ERR-02-004; thành công, SV2 của chủ mới sửa được.
:::

#### TC-02-121 · Hạ mức hiển thị: gỡ khỏi cổng, thông báo bắt buộc, đồng bộ quốc gia <!--k:visibility-downgrade-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-041, 054 · API-02-053, 069 · UI-02-02, 12 · UC-02-21 · BR-02-009, 029, 037 · ERR-02-041.

**Tiền điều kiện, dữ liệu.** A-DATDAI `NATIONAL`, có SUB-ACTIVE, đã đồng bộ lên Nền tảng quốc gia (M-NSP); U-T68-SV1, U-T68-CA.

**Các bước.**

1. SV `PUT /apis/tc-dat-dai/visibility` hạ về `ORG`, không lý do; rồi có lý do.
2. Quan sát danh mục cho máy, cổng nhà phát triển, hàng đợi thông báo, bản ghi đồng bộ.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-041, rồi `200` (hạ mức không cần CA duyệt). Bước 2: API biến mất khỏi danh mục `NATIONAL` và `removed[]` ghi nhận; bên đăng ký nhận thông báo bắt buộc không tắt được; bản ghi đồng bộ có hành động gỡ; chỉ báo quá hạn đồng bộ tắt.
:::

### TS-02-16 · Đăng ký sử dụng: gửi và duyệt

**Mục tiêu.** Xác nhận đăng ký thay "Subscription theo API, theo Application", tự duyệt theo mức dữ liệu, bốn mắt cho `RESTRICTED` trở lên.

**Phủ.** FR-02-046, 047, 051; UC-02-23, 24; API-02-058, 044, 045, 046, 064; UI-02-08, 09, 10; BR-02-011, 012, 026, 027; LGC-APIM-016; 021.

#### TC-02-053 · Gửi đăng ký vào gói `autoApprove` dữ liệu `INTERNAL` được tự duyệt <!--k:sub-auto-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-046, 047 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-012, 026 · EVT-02-09, 10 · LGC-APIM-016; 021.

**Tiền điều kiện, dữ liệu.** Gói `goi-co-ban` bật `autoApprove`; H-KHAITHAC-1; U-T68-OR1.

**Các bước.**

1. `POST /subscriptions` kèm mục đích, khối lượng, `Idempotency-Key`; gửi lại cùng khóa.

**Kết quả mong đợi.** `201` đăng ký `ACTIVE`, EVT: `subscription.activated`; lần hai trả cùng kết quả, không tạo thêm.
:::

#### TC-02-054 · Đăng ký bị từ chối: HTTT không `ACTIVE`, gói không nhận, trùng, thiếu căn cứ <!--k:sub-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-046 · API-02-058 · BR-02-011, 012, 027 · ERR-02-026, 025, 027, 028, 029, 042.

**Tiền điều kiện, dữ liệu.** H-KHAITHAC-2 chưa `ACTIVE`; gói `DEPRECATED`; SUB-ACTIVE; API dữ liệu cá nhân.

**Các bước.**

1. Đăng ký bằng H-KHAITHAC-2; vào gói `DEPRECATED`; lần hai vào cùng phiên bản.
2. Đăng ký dữ liệu cá nhân thiếu căn cứ pháp lý; thiếu mục đích.
3. Dùng lại `Idempotency-Key` với thân khác.

**Kết quả mong đợi.** `422` ERR-02-026; `409` ERR-02-025; `409` ERR-02-027; `422` ERR-02-029; `422` ERR-02-042.
:::

#### TC-02-055 · Duyệt đăng ký `RESTRICTED`: SV một mình không đủ, CA hoặc TA quyết định <!--k:sub-approve-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-047 · API-02-044, 045, 046 · UI-02-10 · UC-02-24 · BR-02-026, 008 · ERR-02-013, 014 · KT: có (subscription.approve).

**Tiền điều kiện, dữ liệu.** Đăng ký `PENDING` vào gói `RESTRICTED`; U-T68-SV1, U-T68-CA.

**Các bước.**

1. U-T68-SV1 `:approve`.
2. U-T68-CA `:reject` thiếu ý kiến, rồi kèm ý kiến; đăng ký thứ hai CA `:approve`.

**Kết quả mong đợi.** 403-PQ hoặc `403` ERR-02-013; từ chối thiếu ý kiến `400` ERR-02-041; `REJECTED` có lý do; duyệt thành công `ACTIVE`.
:::

#### TC-02-122 · Đăng ký: HTTT thuộc tổ chức khác hoặc không hoạt động <!--k:sub-neg-org-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-011, 033 · ERR-02-026.

**Tiền điều kiện, dữ liệu.** U-T68-OR1 (thuộc H-KHAITHAC-1); H-KHAITHAC-2 (`PENDING` ở PH-01); HTTT của Sở khác ở T68; HTTT chỉ có ở T01.

**Các bước.**

1. OR1 `POST /subscriptions` cho HTTT của Sở khác.
2. OR1 gửi cho H-KHAITHAC-2 (không `ACTIVE`).
3. OR1 gửi với mã HTTT của T01.
4. OR1 gửi cho H-KHAITHAC-1 đúng tổ chức.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-026. Bước 2: `422` ERR-02-026 (HTTT không `ACTIVE`). Bước 3: `422` ERR-02-026, thân không phân biệt "không tồn tại" với "ở tenant khác". Bước 4: `201`.
:::

#### TC-02-123 · Đăng ký: đối tượng được dùng gói, trùng hiệu lực, thiếu mục đích hoặc căn cứ pháp lý <!--k:sub-neg-audience-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-012, 027 · ERR-02-028, 027, 029.

**Tiền điều kiện, dữ liệu.** Gói `goi-gioi-han` chỉ cho nhóm HTTT thuộc đơn vị `Sở Tư pháp`; gói `goi-mtls` dữ liệu `RESTRICTED`; SUB-ACTIVE; U-T68-OR1.

**Các bước.**

1. OR1 đăng ký HTTT ngoài đối tượng vào `goi-gioi-han`.
2. OR1 đăng ký lần hai cùng phiên bản (đã có SUB-ACTIVE).
3. Đăng ký thiếu `purpose`, thiếu `expectedVolume`.
4. Đăng ký vào `goi-mtls` thiếu căn cứ pháp lý.

**Kết quả mong đợi.** Bước 1: `422` ERR-02-028. Bước 2: `409` ERR-02-027. Bước 3, 4: `422` ERR-02-029 nêu trường thiếu (căn cứ pháp lý bắt buộc từ mức `RESTRICTED` hoặc có dữ liệu cá nhân, CMP-LAW-05). UI-02-09 chặn gửi và nêu trường thiếu.
:::

#### TC-02-124 · Đăng ký vào gói hoặc phiên bản không nhận đăng ký mới <!--k:sub-neg-closed-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-011, 018 · ERR-02-025.

**Tiền điều kiện, dữ liệu.** Gói `STAGING`, `DEPRECATED`, `CLOSED`; phiên bản `SUSPENDED`, `DEPRECATED`, `RETIRED`; gói và phiên bản `PUBLISHED`; U-T68-OR1.

**Các bước.**

1. Gửi đăng ký vào từng gói không `PUBLISHED`.
2. Gửi đăng ký vào từng phiên bản không `PUBLISHED`.
3. Gửi vào gói và phiên bản `PUBLISHED`.

**Kết quả mong đợi.** Bước 1, 2: `409` ERR-02-025 với mọi trạng thái trên, không tạo bản ghi. Bước 3: `201`. Đăng ký sẵn có vào gói `DEPRECATED` vẫn giữ hiệu lực.
:::

#### TC-02-125 · Đổi gói: đăng ký mới rồi hủy đăng ký cũ <!--k:sub-change-plan-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P2 · **Tự động.** API, E2E

**Truy vết.** FR-02-046, 051 · API-02-058, 064 · UI-02-08, 09 · UC-02-23, 27 · BR-02-027, 025.

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE vào `goi-co-ban`; `goi-mtls` nhận đăng ký; U-T68-OR1.

**Các bước.**

1. Đăng ký `goi-mtls` cho cùng HTTT khi đăng ký cũ còn `ACTIVE`.
2. Hủy đăng ký cũ (`:cancel`), duyệt đăng ký mới.
3. Kiểm tra phạm vi truy cập của HTTT.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-027 (BR-02-027: đổi gói là đăng ký mới sau khi hủy cũ hoặc theo luồng đổi gói được hỗ trợ). Bước 2: sau khi hủy, đăng ký mới `201`, duyệt `ACTIVE`. Bước 3: chỉ còn phạm vi `api:tc-dat-dai:goi-mtls`, phạm vi `goi-co-ban` đã thu hồi.
:::

#### TC-02-126 · Từ chối đăng ký: lý do, trạng thái `REJECTED`, gửi lại <!--k:sub-reject-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-047 · API-02-045, 046 · UI-02-10 · UC-02-24 · BR-02-026, 028, 029 · ERR-02-041, 011.

**Tiền điều kiện, dữ liệu.** Đăng ký `PENDING` vào gói `RESTRICTED`; U-T68-CA, U-T68-OR1.

**Các bước.**

1. CA `:reject` không lý do; có lý do.
2. Kiểm tra phạm vi truy cập, thông báo.
3. CA `:approve` đăng ký đã `REJECTED`.
4. OR1 gửi đăng ký mới với căn cứ bổ sung.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-041, rồi `200`, đăng ký `REJECTED`. Bước 2: không có phạm vi; HTTT nhận thông báo quyết định kèm lý do (bắt buộc, không tắt được). Bước 3: `409` ERR-02-011. Bước 4: `201` đăng ký mới.
:::

### TS-02-17 · Cấp phạm vi truy cập và xem đăng ký

**Mục tiêu.** Xác nhận phạm vi `api:{apiCode}:{planCode}` chỉ sinh từ đăng ký `ACTIVE`, không có đường cấp tay; xem theo API, theo HTTT không rò rỉ.

**Phủ.** FR-02-048, 049, 050; UC-02-25, 26; API-02-059, 060, 067, 068; UI-02-02, 08; BR-02-025, 033; LGC-APIM-016; 021.

#### TC-02-056 · Cấp phạm vi sau duyệt, cấp lại khi lỗi, không có đường cấp tay <!--k:grant-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-048 · API-02-067, 068 · UC-02-25 · BR-02-025 · ERR-02-033, 011, 014 · GW: nạp consumer.

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE vừa duyệt; M-GW lỗi lần đầu; U-T68-TO.

**Các bước.**

1. `GET …/grant` sau khi duyệt khi M-GW lỗi; `:regrant` khi đã bật lại M-GW.
2. Tìm API sửa phạm vi tay (PATCH tùy ý vào `/subscriptions/{id}`, tạo scope không có đăng ký).

**Kết quả mong đợi.** Bước 1: lúc đầu "chưa cấp", sau `:regrant` `202` rồi cấp đủ ≤ 30 giây. Bước 2: không có operation nào, `405` hoặc `404`; scope chỉ hiện với đăng ký `ACTIVE`.
:::

#### TC-02-057 · Xem đăng ký theo API và theo HTTT, cách ly theo tổ chức và tenant <!--k:sub-views-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-049, 050 · API-02-059, 060 · UI-02-02, 08 · UC-02-26 · BR-02-033 · ERR-02-001 · NFR-02-013.

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE; đăng ký của HTTT khác; A-T01 có đăng ký; U-T68-OR1, U-T68-SV1.

**Các bước.**

1. U-T68-OR1 `GET /subscriptions?systemCode=…` của mình và của HTTT khác.
2. U-T68-SV1 `GET /subscriptions?apiCode=tc-dat-dai`.
3. Truy vấn `apiCode=tc-chi-t01`.

**Kết quả mong đợi.** OR1 chỉ thấy đăng ký của HTTT mình; SV1 thấy mọi đăng ký của API mình; bước 3 404-ẩn.
:::

#### TC-02-127 · Trạng thái cấp phạm vi: tên phạm vi, cách ly, cấp lại sai trạng thái <!--k:grant-neg-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-048 · API-02-067, 068 · UI-02-08 · UC-02-25 · BR-02-025 · ERR-02-001, 011, 014.

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE; đăng ký `SUSPENDED`; đăng ký của T01; U-T68-TO, U-T68-VW.

**Các bước.**

1. `GET /subscriptions/{SUB-ACTIVE}/grant`.
2. `GET /subscriptions/{id của T01}/grant`.
3. U-T68-TO `:regrant` cho đăng ký `SUSPENDED`; U-T68-VW `:regrant` cho SUB-ACTIVE.

**Kết quả mong đợi.** Bước 1: phạm vi `api:tc-dat-dai:goi-co-ban`, trạng thái đã cấp. Bước 2: `404` ERR-02-001. Bước 3: `409` ERR-02-011 và `403` ERR-02-014; không có đường nào cấp phạm vi bằng tay.
:::

#### TC-02-128 · Danh sách đăng ký: lọc sai, người xem ngoài HTTT <!--k:sub-list-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-049, 050 · API-02-059, 060 · UI-02-08 · UC-02-26 · BR-02-033 · ERR-02-003, 001.

**Tiền điều kiện, dữ liệu.** 640 đăng ký mẫu ở T68 (rút gọn 50); U-T68-OR1, U-T68-SV2; đăng ký ở T01.

**Các bước.**

1. `GET /subscriptions` không có `apiCode` cũng không có `systemCode`.
2. `GET /subscriptions?status=KHONG-CO`.
3. U-T68-OR1 gọi `GET /subscriptions?systemCode={HTTT của Sở khác}`.
4. `GET /subscriber-systems` bằng OR1.

**Kết quả mong đợi.** Bước 1, 2: `400` ERR-02-003. Bước 3: danh sách rỗng, không lộ đăng ký của HTTT mình không được xem. Bước 4: chỉ HTTT OR1 được xem.
:::

### TS-02-18 · Tạm ngừng, tiếp tục, thu hồi, hủy, gia hạn đăng ký

**Mục tiêu.** Xác nhận bảy trạng thái đăng ký và hiệu lực ở gateway.

**Phủ.** FR-02-051, 052; UC-02-27, 28; API-02-061, 062, 063, 064, 065, 066; UI-02-08; BR-02-028, 034; LGC-APIM-016; 021.

#### TC-02-058 · Tạm ngừng, tiếp tục, thu hồi, hủy: quyền, lý do và hiệu lực gateway <!--k:sub-lifecycle-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-051 · API-02-061, 062, 063, 064 · UI-02-08 · UC-02-27 · BR-02-028, 034 · ERR-02-041, 014, 011 · EVT-02-11 · GW: gỡ consumer · KT: có (subscription.revoke).

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE; U-T68-SO, U-T68-OR1, U-T68-CA.

**Các bước.**

1. U-T68-SO `:suspend` kèm lý do; thiếu lý do; `:resume`.
2. U-T68-CA `:revoke`; OR1 `:cancel` đăng ký đã thu hồi.
3. OR1 `:cancel` đăng ký `ACTIVE` khác.

**Kết quả mong đợi.** `200` kèm GW gỡ rồi nạp consumer; thiếu lý do `400` ERR-02-041; thu hồi `REVOKED` ≤ 30 giây, hủy lại `409` ERR-02-011; hủy `CANCELLED`, EVT: `subscription.state-changed`.
:::

#### TC-02-059 · Gia hạn và rà soát định kỳ: quá hạn thành `EXPIRED` <!--k:sub-renew-->

::: dac-ta
**Loại.** Dương, Biên · **Ưu tiên.** P3 · **Tự động.** API, IT

**Truy vết.** FR-02-052 · API-02-065, 066 · UC-02-28 · BR-02-012 · ERR-02-011.

**Tiền điều kiện, dữ liệu.** `02.subscription.review-months` = 12, đẩy đồng hồ 12 tháng (Đợt 2).

**Các bước.**

1. `:renew` kèm mục đích mới; `:confirm-review`.
2. Không làm gì quá hạn thêm 30 ngày.

**Kết quả mong đợi.** Gia hạn cập nhật hạn; không phản hồi thì `EXPIRED`, gỡ consumer; `:renew` đăng ký `REVOKED` `409` ERR-02-011.
:::

#### TC-02-129 · Vòng đời đăng ký: sai quyền, sai trạng thái, thiếu lý do <!--k:sub-lifecycle-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-051 · API-02-061, 062, 063, 064 · UI-02-08 · UC-02-27 · BR-02-028, 034 · ERR-02-014, 011, 041.

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE; đăng ký `REVOKED`; đăng ký `CANCELLED`; U-T68-OR1, U-T68-SV1, U-T68-CA, U-T68-SO.

**Các bước.**

1. OR1 `:revoke` SUB-ACTIVE.
2. U-T68-TO `:suspend` SUB-ACTIVE không lý do.
3. CA `:resume` đăng ký `ACTIVE`; OR1 `:cancel` đăng ký `REVOKED`; SO `:resume` đăng ký `CANCELLED`.
4. SV1 `:cancel` thay cho OR1.

**Kết quả mong đợi.** Bước 1: `403` ERR-02-014 (thu hồi cần `PERM-02-approve-subscription`). Bước 2: `400` ERR-02-041. Bước 3: `409` ERR-02-011 cả ba. Bước 4: `403`. SUB-ACTIVE không đổi trạng thái.
:::

#### TC-02-130 · Gia hạn và rà soát: sai trạng thái, sai quyền, hạn rà soát <!--k:sub-renew-neg-->

::: dac-ta
**Loại.** Âm, Biên · **Ưu tiên.** P2 · **Tự động.** API, IT

**Truy vết.** FR-02-052 · API-02-065, 066 · UI-02-08 · UC-02-28 · BR-02-012, 026 · ERR-02-011, 014, 029.

**Tiền điều kiện, dữ liệu.** SUB-ACTIVE sắp tới hạn rà soát (`02.subscription.review-months`); đăng ký `CANCELLED`; U-T68-OR1, U-T68-VW; đồng hồ giả.

**Các bước.**

1. OR1 `:renew` đăng ký `CANCELLED`.
2. U-T68-VW `:confirm-review`; OR1 `:confirm-review`.
3. OR1 `:renew` SUB-ACTIVE thiếu mục đích cập nhật.
4. Tới hạn rà soát không ai xác nhận: chạy bộ rà soát; rồi OR1 gia hạn đúng.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-011. Bước 2: `403` ERR-02-014 cả hai. Bước 3: `422` ERR-02-029. Bước 4: quá hạn rà soát chuyển `EXPIRED` và thu hồi phạm vi; gia hạn đúng khi còn hiệu lực giữ `ACTIVE`.
:::

### TS-02-19 · Đồng bộ danh mục lên Nền tảng quốc gia

**Mục tiêu.** Xác nhận đồng bộ API `NATIONAL`, `PUBLIC` qua PH-14, thử lại và cảnh báo quá hạn.

**Phủ.** FR-02-053, 054; UC-02-29, 30; API-02-069, 070, 071, 072; UI-02-12; BR-02-009; NFR-02-014.

#### TC-02-060 · Đồng bộ ngay, theo dõi, thử lại bản ghi bị từ chối <!--k:sync-run-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-053, 054 · API-02-069, 070, 071, 072 · UI-02-12 · UC-02-29, 30 · BR-02-009 · ERR-02-044, 035, 034, 014 · EVT-02-14.

**Tiền điều kiện, dữ liệu.** A-DATDAI `NATIONAL` đã `PUBLISHED`, API `TENANT`; M-NSP; U-T68-TO, U-T68-SV1.

**Các bước.**

1. `POST /national-sync/runs`; chạy lần hai khi lần một chưa xong; SV1 chạy.
2. M-NSP trả `422` cho một bản ghi; `GET /national-sync/records`; `:resend` sau khi sửa.
3. Đồng bộ API `TENANT`.

**Kết quả mong đợi.** `202`, lần hai `409` ERR-02-035, SV1 403-PQ; bản ghi `REJECTED` hiện lý do, gửi lại thành `SYNCED`; API `TENANT` `409` ERR-02-044.
:::

#### TC-02-061 · Quá `02.sync.overdue-days` phát cảnh báo tuân thủ <!--k:sync-overdue-->

::: dac-ta
**Loại.** Biên · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** FR-02-054, 053 · API-02-070 · UI-02-12 · BR-02-009 · NFR-02-014, 019.

**Tiền điều kiện, dữ liệu.** M-NSP ngừng; `02.sync.overdue-days` = 7.

**Các bước.**

1. Đẩy đồng hồ 7 ngày rồi 8 ngày; `GET /national-sync/summary`.

**Kết quả mong đợi.** Ngày 7 chưa cảnh báo; ngày 8 `catalog_national_sync_overdue_total` tăng, thẻ "Quá hạn" ở UI-02-12.
:::

#### TC-02-131 · Đồng bộ quốc gia: API chưa đủ điều kiện, đang chạy, Nền tảng quốc gia sự cố, sai quyền <!--k:sync-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-053, 054 · API-02-069, 071 · UI-02-12 · UC-02-29, 30 · BR-02-009 · ERR-02-044, 035, 034, 014.

**Tiền điều kiện, dữ liệu.** A-DRAFT (chưa công bố); A-DATDAI `NATIONAL`; bản ghi đồng bộ `SY-1` ở trạng thái `REJECTED`; M-NSP; U-T68-TO, U-T68-SV1.

**Các bước.**

1. U-T68-TO `POST /national-sync/runs` với phạm vi gồm A-DRAFT.
2. Gọi `runs` hai lần liền nhau; rồi `POST /national-sync/records/SY-1:resend` khi lần chạy còn đang chạy.
3. Đặt M-NSP không phản hồi rồi `runs`.
4. U-T68-SV1 gọi `runs`.

**Kết quả mong đợi.** Bước 1: `409` ERR-02-044 nêu API chưa đủ điều kiện. Bước 2: `202` rồi `409` ERR-02-035 cho cả lệnh chạy thứ hai và lệnh gửi lại. Bước 3: `503` ERR-02-034 khi PH-14 không nhận lệnh; các bản ghi đang chờ chuyển `RETRY` theo lịch và không bao giờ bị đánh dấu "đã đồng bộ". Bước 4: `403` ERR-02-014.
:::

#### TC-02-132 · Bản ghi đồng bộ: lọc, cách ly tenant, gửi lại bản ghi của tenant khác <!--k:sync-records-neg-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-054 · API-02-070, 071, 072 · UI-02-12 · UC-02-30 · BR-02-033 · ERR-02-003, 001, 014.

**Tiền điều kiện, dữ liệu.** 30 bản ghi đồng bộ ở T68 (ba trạng thái), 5 ở T01; U-T68-VW, U-T68-TO.

**Các bước.**

1. `GET /national-sync/records?status=REJECTED&size=10`, rồi `status=KHONG-CO`.
2. `GET /national-sync/summary`; đối chiếu số trên UI-02-12.
3. U-T68-TO `:resend` bản ghi của T01; U-T68-VW `:resend` bản ghi của T68.

**Kết quả mong đợi.** Bước 1: lọc đúng; giá trị sai `400` ERR-02-003. Bước 2: tổng khớp UI. Bước 3: `404` ERR-02-001 cùng thân với mã không tồn tại; VW `403` ERR-02-014.
:::

### TS-02-20 · Cam kết chất lượng (SLA) và tuân thủ

**Mục tiêu.** Xác nhận khai báo SLA, đối chiếu thực tế, không kết luận khi thiếu dữ liệu, cảnh báo nhiều kỳ không đạt.

**Phủ.** FR-02-055, 056; UC-02-31, 32; API-02-073, 074, 075, 097; UI-02-11; BR-02-013, 031; EVT-02-13.

#### TC-02-062 · Khai báo SLA, báo trước khi cam kết kém đi <!--k:sla-declare-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-055 · API-02-073, 074 · UI-02-11 · UC-02-31 · BR-02-028 · ERR-02-003, 023, 014.

**Tiền điều kiện, dữ liệu.** A-DATDAI SLA 99,5 %; `02.sla.worsen-notice-days` = 30; U-T68-SV1, U-T68-VW.

**Các bước.**

1. Khai SLA 99 %; khai độ sẵn sàng 120 %; VW khai SLA.

**Kết quả mong đợi.** SLA kém đi có hiệu lực sau 30 ngày, hiện "đang chờ hiệu lực", thông báo bắt buộc; 120 % `400` ERR-02-003; VW 403-PQ.
:::

#### TC-02-063 · Chốt kỳ SLA: thiếu dữ liệu không kết luận, 3 kỳ liên tiếp không đạt cảnh báo <!--k:sla-period-->

::: dac-ta
**Loại.** Dương, Biên, Âm · **Ưu tiên.** P1 · **Tự động.** IT

**Truy vết.** FR-02-056 · API-02-075 · UI-02-11 · UC-02-32 · BR-02-013, 031 · EVT-02-13 · NFR-02-015.

**Tiền điều kiện, dữ liệu.** `02.sla.min-days-data` = 7, `02.sla.min-calls` = 1.000, `02.sla.breach-periods` = 3; số liệu tổng hợp giả lập.

**Các bước.**

1. Kỳ 5 ngày dữ liệu; kỳ 900 lượt gọi; ba kỳ đủ dữ liệu liên tiếp dưới cam kết.

**Kết quả mong đợi.** Hai kỳ đầu "chưa đủ dữ liệu"; kỳ thứ ba cảnh báo SV, CA, TA trong ≤ 15 phút, EVT: `sla.period-closed`.
:::

#### TC-02-133 · Kỳ SLA ở biên: đúng ngưỡng ngày dữ liệu, đúng ngưỡng lượt gọi, kỳ liên tiếp bị ngắt <!--k:sla-boundary-->

::: dac-ta
**Loại.** Biên · **Ưu tiên.** P1 · **Tự động.** IT

**Truy vết.** FR-02-056 · API-02-075 · UI-02-11 · UC-02-32 · BR-02-013, 031.

**Tiền điều kiện, dữ liệu.** `02.sla.min-days-data` = 7, `02.sla.min-calls` = 1.000, `02.sla.breach-periods` = 3; số liệu tổng hợp giả lập; cam kết 99,5 %.

**Các bước.**

1. Kỳ có 6 ngày dữ liệu; kỳ có đúng 7 ngày; mỗi kỳ 999 và 1.000 lượt gọi, độ sẵn sàng thực tế 99,0 %.
2. Ba kỳ đủ dữ liệu liên tiếp không đạt, nhưng kỳ thứ hai đạt.
3. Hai kỳ không đạt liên tiếp, kỳ thứ ba thiếu dữ liệu, kỳ thứ tư không đạt.

**Kết quả mong đợi.** Bước 1: 6 ngày hoặc 999 lượt "chưa đủ dữ liệu", không kết luận; đúng 7 ngày và 1.000 lượt "không đạt". Bước 2: chuỗi bị ngắt, không cảnh báo. Bước 3: kỳ thiếu dữ liệu không đếm và không ngắt chuỗi, nên cảnh báo phát ở kỳ thứ tư (đủ 3 kỳ có kết luận liên tiếp: hai kỳ đầu và kỳ thứ tư). Đây là giả định, cơ sở: BR-02-031 chỉ kết luận ở kỳ đủ dữ liệu.
:::

#### TC-02-134 · Đọc SLA và kỳ SLA của tenant khác, phiên bản chưa có cam kết <!--k:sla-read-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-055, 056 · API-02-074, 075 · UI-02-11 · UC-02-31, 32 · BR-02-013, 033 · ERR-02-001.

**Tiền điều kiện, dữ liệu.** A-DRAFT chưa khai SLA; A-T01 có SLA; U-T68-VW.

**Các bước.**

1. `GET …/tc-nhap/versions/1.0.0/sla` và `…/sla/periods`.
2. `GET /apis/tc-chi-t01/versions/1.0.0/sla` và `…/sla/periods`.

**Kết quả mong đợi.** Bước 1: `200` với "chưa khai báo cam kết", không báo "đạt"; danh sách kỳ rỗng. Bước 2: `404` ERR-02-001 cùng thân với mã không tồn tại.
:::

#### TC-02-168 · Tổng hợp tuân thủ SLA toàn tenant: kỳ đủ dữ liệu, API không đạt liên tiếp, nhóm theo mức phân loại <!--k:sla-summary-->

::: dac-ta
**Loại.** Dương, Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API, IT

**Truy vết.** FR-02-056 · API-02-097, 075 · UI-02-11 · UC-02-32 · BR-02-013, 031 · ERR-02-003, 034.

**Tiền điều kiện, dữ liệu.** Mười API có cam kết SLA: bảy đạt kỳ gần nhất, hai không đạt hai kỳ liên tiếp (`02.sla.breach-periods` = 2), một chưa đủ `02.sla.min-days-data` ngày; hai API chưa khai SLA; PH-13 giả trả số đo; người dùng U-T68-TA, U-T68-VW.

**Các bước.**

1. U-T68-TA gọi `GET /sla/summary`.
2. Gọi `GET /sla/summary?months=36` và `GET /sla/summary?months=0`.
3. Tắt PH-13 giả rồi gọi lại API-02-097.
4. Gọi bằng token tenant T01 cho dữ liệu T68.

**Kết quả mong đợi.** Bước 1: `200`, `apisWithCommitment = 10`, `apisWithoutCommitment = 2`, `breachedApis = 2`, `consecutiveBreachApis = 2`, `compliance` tính trên chín API đủ dữ liệu (API thiếu dữ liệu không bị tính là đạt), `groups[]` cộng lại bằng 10, `worstApis[]` nêu hai API. Bước 2: `36` hợp lệ; `0` trả `400` ERR-02-003. Bước 3: `503` ERR-02-034 kèm `retryAfterSeconds`; UI-02-11 hiện "Số liệu cập nhật lúc {thời điểm}", không hiện tỷ lệ giả. Bước 4: không thấy dữ liệu T68.
:::

### TS-02-21 · Thông báo thay đổi và thống kê

**Mục tiêu.** Xác nhận thông báo bắt buộc không tắt được, thông báo tay có giới hạn, thống kê tenant.

**Phủ.** FR-02-057, 058; UC-02-33, 34; API-02-076, 077, 078, 079; UI-02-11, 13; BR-02-029; NFR-02-015.

#### TC-02-064 · Thông báo bắt buộc tới mọi bên liên quan; thông báo tay có trần <!--k:notice-->

::: dac-ta
**Loại.** Dương, Biên, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-057 · API-02-076, 077 · UI-02-13 · UC-02-33 · BR-02-029 · ERR-02-036, 014 · EVT-02-12 · NFR-02-015.

**Tiền điều kiện, dữ liệu.** A-DEPREC có 3 HTTT đăng ký; bên nhận tắt thông báo trong hồ sơ; `02.notice.announcement-max-per-day` = 3.

**Các bước.**

1. Phát sinh `:propose-deprecate`; xem `GET /change-notices`.
2. Gửi 4 thông báo tay trong một ngày.

**Kết quả mong đợi.** Cả 3 bên nhận trong ≤ 15 phút dù đã tắt, thư điện tử ≤ 1 giờ; thông báo tay thứ 4 `429` ERR-02-036.
:::

#### TC-02-065 · Thống kê sử dụng theo phiên bản và tenant <!--k:usage-stats-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P3 · **Tự động.** API

**Truy vết.** FR-02-058 · API-02-078, 079 · UI-02-11 · UC-02-34 · BR-02-033 · ERR-02-001, 014.

**Tiền điều kiện, dữ liệu.** S-METRIC; số liệu gọi của A-DATDAI (Đợt 2).

**Các bước.**

1. `GET …/usage-stats`; `GET /usage-stats/summary` bằng S-METRIC.
2. `GET /apis/tc-chi-t01/versions/1.0.0/usage-stats`; S-GW gọi `/usage-stats/summary`.

**Kết quả mong đợi.** Số lượt gọi, bên khai thác đúng; bước 2 404-ẩn và 403-PQ.
:::

#### TC-02-135 · Lịch sử thông báo thay đổi: bên nhận chỉ thấy phần của mình, cách ly tenant, lọc sai <!--k:notice-list-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-057 · API-02-076, 077 · UI-02-13 · UC-02-33 · BR-02-029, 033 · ERR-02-003, 014, 001.

**Tiền điều kiện, dữ liệu.** Thông báo bắt buộc và thông báo tay cho A-DATDAI (bên nhận H-KHAITHAC-1 và HTTT khác); thông báo của T01; U-T68-OR1, U-T68-VW, U-T68-SV2.

**Các bước.**

1. OR1 `GET /change-notices`.
2. `GET /change-notices?from=2026-12-01&to=2026-11-01`; `type=KHONG-CO`.
3. U-T68-SV2 (tổ chức khác chủ API) `POST /apis/tc-dat-dai/change-notices`.
4. U-T68-VW `POST` thông báo tay.

**Kết quả mong đợi.** Bước 1: chỉ thấy thông báo gửi tới HTTT của OR1, không thấy danh sách bên nhận khác, không thấy của T01. Bước 2: `400` ERR-02-003. Bước 3, 4: `403` ERR-02-014, không phát thông báo nào.
:::

#### TC-02-136 · Thống kê sử dụng: khoảng thời gian sai, token máy sai scope, tenant khác <!--k:usage-stats-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-058 · API-02-078, 079 · UI-02-11 · UC-02-34 · BR-02-033 · ERR-02-003, 001, 014.

**Tiền điều kiện, dữ liệu.** S-METRIC (`catalog:metrics-read`), S-PORTAL; số liệu thống kê giả lập; A-T01.

**Các bước.**

1. `GET …/usage-stats?from=2026-12-01&to=2026-11-01`; khoảng dài hơn mức cho phép.
2. S-PORTAL gọi `GET /usage-stats/summary`; S-METRIC gọi cùng operation.
3. `GET /apis/tc-chi-t01/versions/1.0.0/usage-stats`.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-003. Bước 2: S-PORTAL `403` ERR-02-014, S-METRIC `200` chỉ có số liệu T68. Bước 3: `404` ERR-02-001.
:::

### TS-02-22 · Giao diện nội bộ và đối soát gateway

**Mục tiêu.** Xác nhận PH-03, PH-04, PH-15 đọc dữ liệu công bố đúng scope và phát hiện lệch cấu hình.

**Phủ.** FR-02-059, 060; UC-02-35, 36; API-02-080, 081, 082, 083, 084, 017; UI-02-17; NFR-02-020.

#### TC-02-066 · Giao diện nội bộ theo scope dịch vụ và `ETag` <!--k:internal-api-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-059 · API-02-080, 081, 082 · UC-02-35 · BR-02-025, 033 · ERR-02-014, 001 · EVT-02-05.

**Tiền điều kiện, dữ liệu.** S-GW, S-PORTAL, S-FLOW; token người dùng.

**Các bước.**

1. S-GW `GET /internal/gateway/published-config` hai lần với `If-None-Match`.
2. S-PORTAL gọi `/internal/gateway/published-config`; token người dùng gọi API nội bộ.
3. S-GW đọc cấu hình T01 bằng token T68.

**Kết quả mong đợi.** `200` rồi `304`, chỉ phiên bản `PUBLISHED`, gói, đăng ký `ACTIVE`; bước 2 403-PQ; bước 3 chỉ trả dữ liệu T68.
:::

#### TC-02-067 · Đối soát phát hiện route thừa, thiếu, lệch và đẩy lại <!--k:reconcile-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** FR-02-060 · API-02-083, 084 · UI-02-17 · UC-02-36 · ERR-02-035, 014 · EVT-02-15 · NFR-02-020.

**Tiền điều kiện, dữ liệu.** Tiêm lệch ở M-GW: thiếu một route, thừa một route, sai trọng số; `02.reconcile.auto-repair` = false (Đợt 2).

**Các bước.**

1. Chờ chu kỳ 5 phút; `GET /gateway-reconciliations/latest`.
2. `POST /gateway-reconciliations` lần hai khi lần một chạy; U-T68-TO đẩy lại.

**Kết quả mong đợi.** Phát hiện ≤ 10 phút, EVT: `gateway.drift-detected`; lần hai `409` ERR-02-035; đẩy lại sửa route thiếu và lệch, route thừa chỉ báo.
:::

#### TC-02-137 · Ma trận scope của giao diện nội bộ: mỗi token chỉ gọi được operation của mình <!--k:internal-matrix-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, CT

**Truy vết.** FR-02-059 · API-02-017, 080, 081, 082 · UC-02-35 · BR-02-033 · ERR-02-014 · NFR-02-018.

**Tiền điều kiện, dữ liệu.** S-GW (`catalog:gateway-read`), S-GW-ACK (`catalog:gateway-ack`), S-FLOW, S-PORTAL; token người dùng U-T68-TA.

**Các bước.**

1. Với mỗi cặp (token, operation) trong {017, 080, 081, 082}, gọi operation.
2. Gọi bằng token người dùng U-T68-TA.
3. Gọi bằng token tenant T01 cho dữ liệu T68.

**Kết quả mong đợi.** Chỉ cặp đúng scope `200`, `204` hoặc `304`; 12 cặp sai scope `403` ERR-02-014; token người dùng `403`, kể cả TA; token T01 chỉ thấy dữ liệu T01. Hợp đồng Pact với PH-03, PH-04, PH-15 vẫn đạt.
:::

#### TC-02-138 · Đối soát gateway: đang chạy, gateway sự cố, tắt tự sửa, sai quyền <!--k:reconcile-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P2 · **Tự động.** API, IT

**Truy vết.** FR-02-060 · API-02-083, 084 · UI-02-17 · UC-02-36 · ERR-02-035, 033, 014.

**Tiền điều kiện, dữ liệu.** M-GW có một route thừa, một route thiếu; `02.reconcile.auto-repair` = false; U-T68-TO, U-T68-VW.

**Các bước.**

1. U-T68-TO `POST /gateway-reconciliations` hai lần liền.
2. Đợi lần chạy xong; xem `GET /gateway-reconciliations/latest`.
3. Đặt M-GW từ chối nhận cấu hình rồi chạy lại.
4. U-T68-VW gọi cả hai operation.

**Kết quả mong đợi.** Bước 1: `202` rồi `409` ERR-02-035. Bước 2: báo cáo nêu route thừa, thiếu, lệch; không tự đẩy lại vì tắt tự sửa. Bước 3: `202` rồi kết quả ở `operationId` ghi ERR-02-033 vì gateway không nhận cấu hình; không đánh dấu "đã khớp". Bước 4: `403` ERR-02-014.
:::

### TS-02-23 · Di trú từ APIM cũ và tham số phân hệ

**Mục tiêu.** Xác nhận nhập API, gói, đăng ký từ APIM cũ không mang khóa và bí mật, sửa tham số `02.*` trong giới hạn.

**Phủ.** FR-02-061, 062; UC-02-37, 38; API-02-085, 086, 087, 088, 089; UI-02-16, 17; BR-02-015, 021, 036; LGC-APIM-002; 003, 009.

#### TC-02-068 · Di trú: xem trước, xác nhận, đăng ký vào `SUSPENDED`, không nhập khóa <!--k:legacy-import-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, E2E

**Truy vết.** FR-02-061 · API-02-085, 086, 087 · UI-02-16 · UC-02-37 · BR-02-036, 021, 015 · ERR-02-045, 002, 014 · LGC-APIM-002; 003, 009 · EVT-02-01.

**Tiền điều kiện, dữ liệu.** F-APIM-EXPORT; tệp sai định dạng; U-T68-TA, U-T68-SV1; mồi `DH-CANARY-legacy` ở trường khóa API.

**Các bước.**

1. `POST /legacy-imports` tệp hợp lệ; xem trước; `:commit`; `GET …/report`.
2. Nạp tệp sai định dạng; SV1 gọi `POST /legacy-imports`.
3. Commit lần hai gói trùng mã.

**Kết quả mong đợi.** 12 API, 20 gói, 35 đăng ký ở `SUSPENDED`, không có khóa; báo cáo đối chiếu khớp số lượng; mồi sạch; `400` ERR-02-045; SV1 403-PQ; trùng mã `409` ERR-02-002.
:::

#### TC-02-069 · Sửa tham số `02.*`: trong miền, ngoài miền, vượt trần nền tảng <!--k:settings-->

::: dac-ta
**Loại.** Dương, Biên, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-062 · API-02-088, 089 · UI-02-17 · UC-02-38 · BR-02-028 · ERR-02-040, 003, 014 · KT: có (settings.update).

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-SV1.

**Các bước.**

1. `PATCH /settings` `02.suspend.max-days` = 45; = 91; `02.deprecation.min-days` = 20.
2. SV1 `PATCH /settings`; `GET /settings`.

**Kết quả mong đợi.** 45 `200`, có hiệu lực ≤ 60 giây; 91 và 20 `422` ERR-02-040 hoặc `400` ERR-02-003; SV1 403-PQ, SV1 đọc được.
:::

#### TC-02-139 · Gói xuất APIM cũ sai định dạng: thiếu cột, tệp hỏng, quá lớn, chứa khóa <!--k:legacy-bad-package-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-061 · API-02-085, 086 · UI-02-16 · UC-02-37 · BR-02-015, 036 · ERR-02-045, 009, 008.

**Tiền điều kiện, dữ liệu.** Biến thể của F-APIM-EXPORT: thiếu trường `context-path`; tệp JSON cụt; tệp quá giới hạn kích thước; tệp có khóa bí mật mồi `DH-CANARY-legacy-…`; U-T68-TA.

**Các bước.**

1. `POST /legacy-imports` lần lượt từng biến thể.
2. `POST /legacy-imports` với F-APIM-EXPORT nguyên vẹn.
3. Quét phản hồi, log, bảng `ph02_catalog.*`, báo cáo `GET …/report`.

**Kết quả mong đợi.** Bước 1: `400` ERR-02-045 nêu dòng, cột lỗi (thiếu trường, tệp hỏng); quá lớn `413` ERR-02-009; không có dữ liệu nào được ghi. Bước 2: `200` kèm bản xem trước; khóa mồi bị loại, báo "không nhập khóa". Bước 3: mồi không xuất hiện ở bất kỳ nơi nào.
:::

#### TC-02-140 · Xác nhận nhập: định danh lạ, nhập lại, xung đột mã, sai quyền <!--k:legacy-commit-neg-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-061 · API-02-085, 086, 087 · UI-02-16 · UC-02-37 · BR-02-021, 036 · ERR-02-001, 002, 014, 042.

**Tiền điều kiện, dữ liệu.** Bản xem trước `IMP-1` từ F-APIM-EXPORT (có một mã API trùng A-DATDAI); `IMP-2` của T01; U-T68-TA, U-T68-SV1.

**Các bước.**

1. U-T68-TA `POST /legacy-imports/{IMP-2}:commit`.
2. U-T68-SV1 `:commit IMP-1`.
3. U-T68-TA `:commit IMP-1` hai lần cùng `Idempotency-Key`; rồi lần ba khác khóa.
4. `GET /legacy-imports/{IMP-1}/report`.

**Kết quả mong đợi.** Bước 1: `404` ERR-02-001. Bước 2: `403` ERR-02-014. Bước 3: lần đầu `201`; lần hai trả lại phản hồi cũ; lần ba không nhập thêm (đã nhập) và báo xung đột mã `409` ERR-02-002 cho phần trùng. Bước 4: báo cáo đối chiếu số API, gói, đăng ký khớp bản xem trước; mã trùng A-DATDAI được liệt kê là bỏ qua, không đè.
:::

#### TC-02-141 · Sửa tham số `02.*` ghi kiểm toán qua PH-18, khóa lạ, xung đột `If-Match` <!--k:settings-audit-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** FR-02-062 · API-02-088, 089 · UI-02-17 · UC-02-38 · BR-02-028 · ERR-02-003, 015, 014.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-VW; `02.suspend.max-days` = 14 (giả định mặc định).

**Các bước.**

1. U-T68-TA `PATCH /settings` đổi `02.suspend.max-days` thành 30, kèm `If-Match`.
2. Gửi lại với `ETag` cũ.
3. `PATCH` khóa không có (`02.khong-co`) và giá trị sai kiểu.
4. U-T68-VW `GET /settings`, rồi `PATCH`.

**Kết quả mong đợi.** Bước 1: `200`, có bản ghi kiểm toán qua PH-18 (người, trước, sau). Bước 2: `412` ERR-02-015. Bước 3: `400` ERR-02-003 nêu khóa hoặc kiểu sai. Bước 4: đọc được `200`; sửa `403` ERR-02-014. Tham số mới có hiệu lực ở lần tạm ngừng kế tiếp.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Các kịch bản dưới đây chạy lại ở mỗi đợt phát hành; TS-02-25 là điều kiện bắt buộc đạt 100 %.

### TS-02-24 · Hiệu năng và quy mô

**Mục tiêu.** Chứng minh NFR-02-001…006, 010 ở hồ sơ tỉnh vừa (GĐ-07) trên môi trường PERF.

**Phủ.** NFR-02-001, 002, 003, 004, 005, 006, 010, 011; API-02-001, 003, 022, 055, 002, 004, 015, 047, 048, 059, 063, 069; FR-02-001, 011, 016, 053.

| Mã | Ca | Tải | Ngưỡng đạt | Truy vết |
|---|---|---|---|---|
| TC-02-070 | Tra cứu danh mục <!--k:perf-read--> | 2.000 API, 200 người dùng đồng thời, 10 phút, API-02-001, 002, 004 | p95 ≤ 300 ms, p99 ≤ 500 ms, `304` khi chưa đổi | NFR-02-001, 006 · API-02-001, 004 |
| TC-02-071 | Tìm kiếm toàn văn <!--k:perf-search--> | 2.000 API, 10.000 phiên bản, 100 yêu cầu/giây | p95 ≤ 500 ms | NFR-02-002 · API-02-003 |
| TC-02-072 | Kiểm tra đặc tả 5.000 dòng và 10 MiB <!--k:perf-lint--> | 20 lần song song F-SPEC-5K, 5 lần F-SPEC-10M | ≤ 5 giây; ≤ 20 giây | NFR-02-003, 011 · API-02-022 |
| TC-02-073 | Báo cáo khác biệt hai phiên bản <!--k:perf-diff--> | Hai đặc tả 5.000 dòng, 20 lần | ≤ 3 giây | NFR-02-004 · API-02-055 |
| TC-02-074 | Hiệu lực cấu hình ở gateway <!--k:perf-gw--> | 100 lệnh công bố, tạm ngừng, cấp, thu hồi; ba bản sao APISIX | p95 ≤ 30 giây từ quyết định tới áp dụng | NFR-02-005 · API-02-047, 048, 063 |
| TC-02-075 | Quy mô tối đa mỗi tenant <!--k:perf-scale--> | 2.000 API, 50 phiên bản mỗi API, 20.000 đăng ký, 5.000 thao tác mỗi đặc tả | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | NFR-02-006, 010 · API-02-001, 059 |

: Ca hiệu năng

#### TC-02-076 · Đặc tả độc hại: bom YAML, `$ref` sâu, quá nhiều thao tác <!--k:spec-bomb-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API, IT

**Truy vết.** FR-02-011, 016 · API-02-015, 022 · NFR-02-011 · ERR-02-009, 005, 006.

**Tiền điều kiện, dữ liệu.** F-SPEC-BOMB; đặc tả 5.001 thao tác.

**Các bước.**

1. Nạp F-SPEC-BOMB và `POST /spec-lint`; theo dõi bộ nhớ, CPU của `dh-connect`.
2. Nạp đặc tả 5.001 thao tác.

**Kết quả mong đợi.** Bị từ chối `422` hoặc `413` trong ≤ 20 giây, tiến trình không quá bộ nhớ, các yêu cầu khác không chậm quá 2 lần.
:::

#### TC-02-142 · Đồng bộ lô lớn lên Nền tảng quốc gia trong 15 phút <!--k:perf-sync-batch-->

::: dac-ta
**Loại.** Hiệu năng · **Ưu tiên.** P2 · **Tự động.** k6, IT

**Truy vết.** FR-02-053 · API-02-069 · UI-02-12 · UC-02-29 · NFR-02-014 · BR-02-009.

**Tiền điều kiện, dữ liệu.** 180 API công bố `NATIONAL` (hồ sơ tỉnh vừa, GĐ-02-01); M-NSP trả sau 100 ms; `02.sync.batch-size` mặc định.

**Các bước.**

1. Đặt toàn bộ 180 API ở trạng thái đủ điều kiện cùng lúc.
2. Đo từ lúc đủ điều kiện tới khi mọi bản ghi `SYNCED`.
3. Lặp lại với M-NSP lỗi 5 % bản ghi.

**Kết quả mong đợi.** Bước 2: ≤ 15 phút. Bước 3: 5 % bản ghi vào `RETRY` rồi `SYNCED` ở lần thử kế tiếp, không bản ghi nào bị gửi trùng.
:::

#### TC-02-143 · Chạy bền 8 giờ ở nửa tải: không rò bộ nhớ, không lệch hiệu năng <!--k:perf-soak-->

::: dac-ta
**Loại.** Hiệu năng · **Ưu tiên.** P3 · **Tự động.** k6

**Truy vết.** NFR-02-006, 007 · API-02-001, 002, 059 · FR-02-001.

**Tiền điều kiện, dữ liệu.** Môi trường PERF; 1.000 API, 100 người dùng đồng thời; hỗn hợp 90 % đọc, 10 % ghi.

**Các bước.**

1. Chạy 8 giờ liên tục.
2. So sánh p95 giờ đầu với giờ cuối; theo dõi bộ nhớ, số kết nối DB, độ trễ bộ đệm.

**Kết quả mong đợi.** p95 giờ cuối không quá 1,2 lần giờ đầu; bộ nhớ tiến trình không tăng đơn điệu quá 10 %; không lỗi 5xx do cạn kết nối; sẵn sàng đo được ≥ 99,5 % (NFR-02-007).
:::

### TS-02-25 · Cách ly tenant và không lộ bí mật xuyên suốt

**Mục tiêu.** Chứng minh NFR-02-012, 013: mọi API đọc, ghi cách ly tenant; mồi `DH-CANARY` không lọt ra đâu ngoài chỗ được phép.

**Phủ.** NFR-02-012, 013; BR-02-033; ERR-02-001, 014, 016; API-02-001…095; FR-02-002, 011, 014, 018, 022, 030, 034, 035, 036, 037, 038, 039, 040, 044, 046, 049, 051, 053, 061.

#### TC-02-077 · Rò rỉ chéo tenant cho toàn bộ API có tham số đường dẫn <!--k:cross-tenant-all-->

::: dac-ta
**Loại.** Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** NFR-02-013 · BR-02-033 · ERR-02-001, 014 · API-02-002, 005, 006, 007, 020, 026, 033, 044, 055, 056, 059, 063, 067, 072, 074, 078 · FR-02-002, 022, 044, 049.

**Tiền điều kiện, dữ liệu.** Đối tượng của T01 với mọi loại (API, phiên bản, gói, đăng ký, yêu cầu duyệt, bản ghi đồng bộ); U-T68-TA có quyền cao nhất ở T68.

**Các bước.**

1. Sinh bộ lời gọi tự động cho mọi operation đọc và ghi có định danh đối tượng, dùng định danh của T01 bằng token T68.
2. So sánh thân với thân của định danh không tồn tại.
3. Đọc trực tiếp bảng `ph02_catalog.*` bằng vai trò ứng dụng T68 không đặt `tenant_id`.

**Kết quả mong đợi.** 100 % lời gọi trả 404-ẩn, thân giống nhau trừ `traceId`; truy vấn DB thiếu ngữ cảnh tenant không trả hàng nào (RLS).
:::

#### TC-02-078 · Mồi bí mật đi qua toàn bộ đường: đặc tả, ví dụ, ghi chú, di trú, URL nguồn <!--k:canary-all-->

::: dac-ta
**Loại.** Bảo mật · **Ưu tiên.** P1 · **Tự động.** E2E, IT

**Truy vết.** NFR-02-012 · FR-02-018, 011, 061, 014 · BR-02-015, 036 · ERR-02-008 · API-02-015, 021, 085.

**Tiền điều kiện, dữ liệu.** Mồi `DH-CANARY-all-{uuid}` đặt vào ví dụ đặc tả, ghi chú duyệt, lý do chuyển trạng thái, khóa của gói xuất APIM, tiêu đề của URL nguồn.

**Các bước.**

1. Chạy vòng đời đầy đủ: nạp, kiểm tra, gửi duyệt, duyệt, công bố, đồng bộ quốc gia, di trú.
2. Quét phản hồi API, log 5 phút, vết OTel, bảng `ph02_catalog.*`, outbox, Kafka, danh mục cho máy, tệp báo cáo.

**Kết quả mong đợi.** Mồi trong ví dụ đặc tả bị chặn trước công bố; mồi trong khóa di trú không được nhập; không nơi nào chứa mồi ngoài bản ghi bị chặn (che một phần).
:::

#### TC-02-079 · Đọc ngoài quyền: vai trò sai ở mọi operation ghi <!--k:perm-matrix-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** FR-02-014, 030, 035, 046, 051, 053 · API-02-014, 037, 045, 058, 061, 069 · ERR-02-014 · UI-02-02, 06, 08.

**Tiền điều kiện, dữ liệu.** U-T68-VW, U-T68-AU, U-T68-OR1, U-T68-TO, U-T68-SV1, U-T68-CA theo ma trận FRS §3.2.

**Các bước.**

1. Với mỗi cặp (vai trò, operation ghi), gọi theo bảng quyền sinh từ D02-08.
2. Ở UI, mở UI-02-02, 06, 08 bằng U-T68-VW.

**Kết quả mong đợi.** Mọi cặp ngoài quyền 403-PQ; UI ẩn hoặc vô hiệu hóa nút thao tác tương ứng.
:::

#### TC-02-144 · Chống trùng lệnh: `Idempotency-Key` ở mọi `POST` <!--k:idempotency-all-->

::: dac-ta
**Loại.** Biên, Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** NFR-02-006 · API-02-014, 034, 042, 047, 058, 069 · ERR-02-042, 003, 014.

**Tiền điều kiện, dữ liệu.** Các lệnh `POST` tạo hoặc đổi trạng thái có `Idempotency-Key`; U-T68-SV1, U-T68-OR1, U-T68-TO.

**Các bước.**

1. Với mỗi lệnh, gửi hai lần cùng khóa, cùng thân.
2. Gửi lần ba cùng khóa, khác thân.
3. Khóa 15 ký tự, 16 ký tự, 128 ký tự, 129 ký tự.
4. Cùng khóa nhưng người gọi khác.

**Kết quả mong đợi.** Bước 1: lần hai trả lại đúng phản hồi lần một, chỉ một thay đổi dữ liệu, một dòng kiểm toán. Bước 2: `422` ERR-02-042. Bước 3: 15 và 129 `400` ERR-02-003, 16 và 128 hợp lệ. Bước 4: không trả lại phản hồi của người khác (khóa tính theo `(tenant, người gọi, khóa)`).
:::

#### TC-02-145 · Khóa lạc quan: `If-Match` ở mọi lệnh sửa, xóa, đổi trạng thái <!--k:if-match-all-->

::: dac-ta
**Loại.** Âm · **Ưu tiên.** P1 · **Tự động.** API

**Truy vết.** NFR-02-013 · API-02-008, 018, 025, 028, 035, 036, 047, 053, 057, 073, 089 · ERR-02-015.

**Tiền điều kiện, dữ liệu.** Đối tượng đại diện cho từng operation ở trạng thái cho phép; hai phiên cùng lấy `ETag` rồi một phiên đổi trước.

**Các bước.**

1. Sinh bộ lời gọi từ OpenAPI cho mọi operation `PUT`, `PATCH`, `DELETE` và hành động đổi trạng thái.
2. Phiên thứ hai gửi với `ETag` cũ.
3. Gửi không có `If-Match`.

**Kết quả mong đợi.** Bước 2: `412` ERR-02-015, dữ liệu giữ bản của phiên đầu, không có dòng kiểm toán mới. Bước 3: bị từ chối, không đổi dữ liệu (mã lỗi đúng theo D03-04-PH02 §1).
:::

#### TC-02-146 · Định dạng lỗi `problem+json` thống nhất, không lộ chi tiết nội bộ <!--k:error-format-->

::: dac-ta
**Loại.** Bảo mật, Âm · **Ưu tiên.** P2 · **Tự động.** API

**Truy vết.** NFR-02-012, 013 · API-02-001, 014, 022, 042 · ERR-02-001, 003, 008, 014, 034.

**Tiền điều kiện, dữ liệu.** Một lời gọi gây ra từng lỗi trên; `Accept-Language: vi` và `en`.

**Các bước.**

1. Gọi và lấy thân lỗi, tiêu đề `Content-Type`.
2. Kiểm tra từng trường: `type`, `title`, `status`, `code`, `traceId`, `errors[]`, `findings[]`.
3. Bật lỗi nội bộ (ném ngoại lệ ở IT) rồi gọi.

**Kết quả mong đợi.** `application/problem+json`; `code` đúng `ERR-02-nnn`; `traceId` 32 ký tự hex khớp vết OTel; `title`, `detail` theo ngôn ngữ yêu cầu; không có dấu vết ngăn xếp, tên bảng, địa chỉ nội bộ, giá trị bí mật; lỗi 5xx chỉ nêu `traceId`.
:::

#### TC-02-147 · Kiểm toán mọi chuyển trạng thái có lý do, trước, sau <!--k:audit-all-->

::: dac-ta
**Loại.** Dương, Bảo mật · **Ưu tiên.** P1 · **Tự động.** IT, API

**Truy vết.** FR-02-034, 035, 036, 037, 038, 039, 040, 051 · BR-02-028 · API-02-042, 045, 047, 048, 050, 051, 052, 063 · ERR-02-041.

**Tiền điều kiện, dữ liệu.** Một đối tượng cho mỗi chuyển trạng thái của phiên bản, gói, đăng ký; U-T68-AU.

**Các bước.**

1. Thực hiện từng chuyển trạng thái, không lý do rồi có lý do.
2. U-T68-AU truy vấn kiểm toán.
3. Thử sửa hoặc xóa dòng kiểm toán bằng mọi vai trò.

**Kết quả mong đợi.** Không lý do `400` ERR-02-041 (trừ tạo mới); có lý do: mỗi lần đúng một dòng với người, thời điểm, giá trị trước và sau, `traceId`. Không có đường sửa, xóa kiểm toán; AU chỉ đọc.
:::

#### TC-02-148 · Tương thích hợp đồng `v1`: chặn thay đổi phá vỡ ở CI <!--k:contract-compat-->

::: dac-ta
**Loại.** Âm, Bảo mật · **Ưu tiên.** P2 · **Tự động.** CI

**Truy vết.** NFR-02-018 · API-02-001…095.

**Tiền điều kiện, dữ liệu.** OpenAPI `v1` đã phát hành; nhánh thử đổi tên trường, bỏ trường bắt buộc, thêm trường bắt buộc; nhánh thử thêm trường tùy chọn.

**Các bước.**

1. Chạy oasdiff ở CI-5 cho từng nhánh.
2. Chạy kiểm tra hợp đồng Pact với PH-03, PH-04, PH-15.

**Kết quả mong đợi.** Ba nhánh phá vỡ bị chặn, nhánh thêm trường tùy chọn qua; Pact đạt ở nhánh qua.
:::

### TS-02-26 · Sẵn sàng, cách ly sự cố và phục hồi

**Mục tiêu.** Chứng minh data plane không phụ thuộc PH-02, khôi phục đúng RPO, RTO.

**Phủ.** NFR-02-007, 008, 009, 018, 020; FR-02-036, 059, 010, 011, 034, 048, 053, 060; API-02-001, 014, 015, 042, 047, 069, 082.

#### TC-02-080 · Tắt `dh-connect` 24 giờ, API đang chạy vẫn phục vụ <!--k:chaos-->

::: dac-ta
**Loại.** Hiệu năng · **Ưu tiên.** P1 · **Tự động.** Chaos

**Truy vết.** NFR-02-008, 007 · FR-02-059, 036 · ERR-02-033, 034.

**Tiền điều kiện, dữ liệu.** 20 API `PUBLISHED` đang nhận tải ổn định qua gateway.

**Các bước.**

1. Tắt toàn bộ bản sao `dh-connect` (CX-01); giữ 24 giờ.
2. Thử công bố API mới; bật lại `dh-connect`.

**Kết quả mong đợi.** Tỷ lệ lỗi data plane không tăng; công bố mới `503` ERR-02-034; sau khi bật lại, đồng bộ cấu hình hồi phục ≤ 5 phút, không mất bản ghi.
:::

#### TC-02-081 · Diễn tập DR: RPO ≤ 15 phút, RTO ≤ 4 giờ, đối soát sau khôi phục <!--k:dr-->

::: dac-ta
**Loại.** Hiệu năng · **Ưu tiên.** P2 · **Tự động.** Thủ công

**Truy vết.** NFR-02-009, 020, 018 · FR-02-060.

**Tiền điều kiện, dữ liệu.** Hai site; dữ liệu T68 đầy đủ; tải ghi liên tục.

**Các bước.**

1. Chuyển site; đo thời điểm bản ghi cuối còn lại và thời gian dịch vụ hồi phục.
2. Chạy đối soát gateway.

**Kết quả mong đợi.** Mất dữ liệu ≤ 15 phút, hồi phục ≤ 4 giờ; đối soát không báo lệch ngoài vùng bị mất; hợp đồng `v1` không đổi (CI-5).
:::

#### TC-02-149 · Từng dịch vụ phụ thuộc ngừng: đọc vẫn chạy, ghi trả `503` đúng mã <!--k:dependency-down-->

::: dac-ta
**Loại.** Âm, Khả dụng · **Ưu tiên.** P1 · **Tự động.** IT, chaos

**Truy vết.** NFR-02-007, 008 · FR-02-010, 011, 034, 053 · API-02-001, 014, 015, 042, 069 · ERR-02-034, 033.

**Tiền điều kiện, dữ liệu.** Bộ giả của PH-01, PH-04, PH-10, PH-12, PH-13, PH-14, PH-18, kho đối tượng, cổng API; tắt từng cái một.

**Các bước.**

1. Với mỗi dịch vụ, tắt rồi chạy một lệnh đọc và một lệnh ghi phụ thuộc vào nó.
2. Bật lại, lặp lệnh có `Idempotency-Key`.

**Kết quả mong đợi.** Đọc danh mục (API-02-001) luôn `200`. Lệnh ghi cần dịch vụ phụ thuộc: `503` ERR-02-034 (ERR-02-033 với cổng API) kèm `retryAfterSeconds`; không có dữ liệu ghi dở. Sau khi bật lại, lặp lệnh thành công, không tạo trùng.
:::

#### TC-02-150 · Dừng tiến trình giữa lúc công bố: không mất, không công bố trùng <!--k:crash-publish-->

::: dac-ta
**Loại.** Khả dụng · **Ưu tiên.** P1 · **Tự động.** chaos

**Truy vết.** FR-02-036, 048 · API-02-047, 082 · UC-02-16 · NFR-02-008, 009 · ERR-02-033.

**Tiền điều kiện, dữ liệu.** Yêu cầu duyệt đã duyệt; M-GW; hộp thư đi (outbox) bật.

**Các bước.**

1. Gọi `:publish`; ngay sau khi giao dịch xong, dừng bất thình lình pod `dh-connect` trước khi đẩy cấu hình.
2. Khởi động lại pod; quan sát outbox và M-GW.
3. Lặp lại dừng pod sau khi M-GW đã nạp nhưng trước khi nhận xác nhận.

**Kết quả mong đợi.** Bước 2: cấu hình được đẩy đúng một lần từ outbox, phiên bản chuyển `PUBLISHED` sau xác nhận, thông báo gửi một lần. Bước 3: M-GW nhận lần hai bỏ qua (cùng `configEpoch`), không route trùng.
:::

### TS-02-27 · Truy cập, quan sát, thông báo và lưu giữ

**Mục tiêu.** Chứng minh NFR-02-015…019.

**Phủ.** NFR-02-015, 016, 017, 019; UI-02-01…17; FR-02-036, 040, 056, 057; API-02-020, 072, 077, 091.

#### TC-02-082 · Quét axe và bàn phím trên 17 màn UI-02 <!--k:a11y-->

::: dac-ta
**Loại.** Truy cập · **Ưu tiên.** P2 · **Tự động.** E2E

**Truy vết.** NFR-02-016 · UI-02-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17.

**Tiền điều kiện, dữ liệu.** Dữ liệu mục 2; Playwright với axe.

**Các bước.**

1. Mở từng màn ở trạng thái có dữ liệu, rỗng, lỗi; chạy axe.
2. Thao tác UI-02-03 (wizard) và UI-02-10 (duyệt) chỉ bằng bàn phím.

**Kết quả mong đợi.** Không vi phạm WCAG 2.2 AA mức nghiêm trọng; thứ tự tab đúng; lỗi gắn với trường qua `aria-describedby`.
:::

#### TC-02-083 · Chỉ số, kiểm toán và lưu giữ <!--k:observability-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** NFR-02-017, 019 · FR-02-036, 040, 056 · API-02-091.

**Tiền điều kiện, dữ liệu.** Đã chạy TS-02-11, 14, 19.

**Các bước.**

1. Đọc `/metrics`: `catalog_apis_total{status}`, `catalog_spec_validation_total{result,mode}`, `catalog_publish_duration_seconds`, `catalog_national_sync_status`.
2. Xóa mềm API, kiểm tra đặc tả và lịch sử còn; kiểm tra chính sách lưu giữ kỳ SLA.

**Kết quả mong đợi.** Đủ chỉ số, nhãn đúng; đặc tả, phiên bản, đăng ký giữ vĩnh viễn kể cả đã xóa; chính sách lưu giữ khớp NFR-02-017.
:::

#### TC-02-151 · Thông báo trong ứng dụng ≤ 15 phút, thư điện tử ≤ 1 giờ <!--k:notice-latency-->

::: dac-ta
**Loại.** Biên, Dương · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** FR-02-057 · API-02-077 · UI-02-13 · UC-02-33 · BR-02-029 · NFR-02-015.

**Tiền điều kiện, dữ liệu.** A-DATDAI có 3 bên đăng ký; PH-13 giả (trong ứng dụng), M-MAIL (thư điện tử) có độ trễ điều chỉnh được.

**Các bước.**

1. Phát một thông báo bắt buộc (tạm ngừng).
2. Đặt độ trễ M-MAIL 50 phút, rồi 70 phút.
3. Bên nhận thử tắt thông báo bắt buộc trong hồ sơ.

**Kết quả mong đợi.** Trong ứng dụng tới đủ 3 bên ≤ 15 phút. Thư điện tử 50 phút đạt, 70 phút bị ghi "vi phạm mục tiêu" ở chỉ số. Không tắt được thông báo bắt buộc.
:::

#### TC-02-152 · Dọn dữ liệu theo thời hạn lưu giữ: chỉ dọn loại được phép <!--k:retention-expire-->

::: dac-ta
**Loại.** Biên, Bảo mật · **Ưu tiên.** P2 · **Tự động.** IT

**Truy vết.** NFR-02-017 · BR-02-014 · API-02-020, 072, 077.

**Tiền điều kiện, dữ liệu.** Đồng hồ giả; dữ liệu có tuổi 1 năm ± 1 ngày (kết quả kiểm tra đặc tả), 3 năm ± 1 ngày (kỳ SLA), 2 năm (thông báo), 5 năm (bản ghi đồng bộ); đặc tả `RETIRED` 10 năm.

**Các bước.**

1. Chạy bộ dọn lưu giữ.
2. Đọc lại từng loại qua API.

**Kết quả mong đợi.** Chỉ dữ liệu quá thời hạn bị dọn (kết quả kiểm tra > 1 năm, kỳ SLA > 3 năm, thông báo > 2 năm, bản ghi đồng bộ > 5 năm); dữ liệu sát ngày thì giữ. Đặc tả, phiên bản, đăng ký, lịch sử vòng đời, cam kết SLA không bao giờ bị dọn (BR-02-014).
:::

### TS-02-28 · Giao diện: nhập liệu, trạng thái, nút theo quyền và ngôn ngữ

**Mục tiêu.** Chứng minh 17 màn UI-02-01…17 hiển thị đúng trạng thái, kiểm tra nhập liệu ở trình duyệt khớp máy chủ, nút thao tác theo quyền và hành động được phép, và dùng tiếng Việt có dấu, giờ Việt Nam.

**Phủ.** FR-02-001, 003, 010, 011, 016, 019, 021, 034, 035, 037, 043, 044, 046, 047, 051, 054, 056, 061, 062; UC-02-01, 05, 06, 16, 23, 24, 29, 32, 37, 38; UI-02-01…17; NFR-02-016; API-02-001, 002, 003, 014, 015, 022, 024, 025, 033, 044, 045, 046, 055, 056, 058, 059, 070, 072, 075, 085, 086, 088, 089.

#### TC-02-153 · Trình hướng dẫn đăng ký API: chặn từng bước, giữ bản nháp, chỉ lỗi theo dòng <!--k:ui-wizard-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** E2E

**Truy vết.** FR-02-010, 011, 016, 019 · API-02-014, 015, 022 · UI-02-03, 04 · UC-02-05, 06 · ERR-02-003, 006.

**Tiền điều kiện, dữ liệu.** U-T68-SV1; F-SPEC-OK, F-SPEC-L1.

**Các bước.**

1. Mở UI-02-03; bấm "Tiếp" ở từng bước khi thiếu trường bắt buộc.
2. Điền bước 1, 2; tải lại trình duyệt giữa chừng.
3. Nạp F-SPEC-L1; bấm vào một lỗi trong danh sách.
4. Sửa bằng trình soạn và xem kết quả kiểm tra không lưu khi gõ.

**Kết quả mong đợi.** Bước 1: không qua bước, trường lỗi được đánh dấu bằng chữ và biểu tượng (không chỉ màu), thông báo cùng nội dung với `errors[]` của máy chủ. Bước 2: dữ liệu đã nhập còn nguyên (bản nháp). Bước 3: con trỏ nhảy đúng dòng lỗi trong đặc tả. Bước 4: kết quả cập nhật không quá 1 giây sau khi ngừng gõ, không ghi bản nào vào cơ sở dữ liệu.
:::

#### TC-02-154 · Trạng thái rỗng, đang tải, lỗi và mất kết nối ở các màn danh sách <!--k:ui-states-->

::: dac-ta
**Loại.** Âm, Dương · **Ưu tiên.** P2 · **Tự động.** E2E

**Truy vết.** FR-02-001, 046, 047, 054 · API-02-001, 059, 044, 072 · UI-02-01, 06, 08, 10, 12 · UC-02-01, 24, 30 · ERR-02-034.

**Tiền điều kiện, dữ liệu.** Tenant `T91` rỗng; T68 có dữ liệu; chặn mạng bằng công cụ Playwright; API trả `503` ERR-02-034 theo cờ.

**Các bước.**

1. Mở từng màn ở `T91`.
2. Làm chậm phản hồi 3 giây.
3. Cho API trả `503`, rồi bấm "Thử lại".
4. Ngắt mạng khi đang mở màn.

**Kết quả mong đợi.** Bước 1: trạng thái rỗng có lời giải thích và hành động kế tiếp (ví dụ "Đăng ký API đầu tiên"). Bước 2: khung chờ, không nhảy bố cục. Bước 3: thông báo lỗi nêu `traceId`, "Thử lại" gọi lại một lần. Bước 4: báo mất kết nối, giữ dữ liệu đã nhập ở biểu mẫu.
:::

#### TC-02-155 · Nút thao tác theo `allowedActions` và vai trò, kèm lý do bị khóa <!--k:ui-allowed-actions-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** E2E

**Truy vết.** FR-02-034, 035, 037, 046, 051 · API-02-002, 033, 059 · UI-02-02, 06, 08, 10 · ERR-02-014, 011 · PERM-02-submit.

**Tiền điều kiện, dữ liệu.** Đối tượng ở các trạng thái `DRAFT`, `PENDING`, `PUBLISHED`, `SUSPENDED`; U-T68-SV1, U-T68-CA, U-T68-TO, U-T68-OR1, U-T68-VW.

**Các bước.**

1. Mỗi vai trò mở UI-02-02, 06, 08, 10 ở từng trạng thái.
2. Di chuột hoặc dùng bàn phím vào nút bị khóa.
3. Gọi thẳng API cho thao tác mà UI đã khóa.

**Kết quả mong đợi.** Nút hiện hoặc khóa đúng `allowedActions[]`; nút khóa có lý do (`disabledReasons`) đọc được bằng bàn phím và trình đọc màn hình; VW không có nút ghi nào. Bước 3: máy chủ vẫn từ chối `403` ERR-02-014 hoặc `409` ERR-02-011.
:::

#### TC-02-156 · Màn so sánh phiên bản: phân loại thay đổi, lọc, điều hướng bàn phím <!--k:ui-diff-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P2 · **Tự động.** E2E

**Truy vết.** FR-02-043, 044 · API-02-055, 056 · UI-02-05 · UC-02-18 · BR-02-003.

**Tiền điều kiện, dữ liệu.** A-DATDAI 1.0.0 và 2.0.0 (có 3 thay đổi phá vỡ, 5 không phá vỡ); U-T68-SV1.

**Các bước.**

1. Mở UI-02-05, chọn hai phiên bản.
2. Lọc "chỉ phá vỡ"; mở rộng một thay đổi.
3. Duyệt hết danh sách bằng `Tab` và phím mũi tên.
4. Mở tab "Tác động".

**Kết quả mong đợi.** Số thay đổi đúng 3 phá vỡ, 5 không phá vỡ, khớp `GET /version-diff`; lọc đúng; có thể duyệt, mở rộng bằng bàn phím; tab "Tác động" liệt kê bên đăng ký ảnh hưởng, khớp API-02-056.
:::

#### TC-02-157 · Màn gửi đăng ký: chọn gói, căn cứ pháp lý theo mức dữ liệu, chặn gửi thiếu <!--k:ui-subscribe-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** E2E

**Truy vết.** FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-011, 012, 026 · ERR-02-029, 025.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; gói `PUBLISHED` mức `INTERNAL` và `RESTRICTED`; gói `DEPRECATED`.

**Các bước.**

1. Mở UI-02-09 cho API `RESTRICTED`; để trống mục đích, khối lượng, căn cứ pháp lý; bấm gửi.
2. Mở danh sách gói.
3. Chọn gói `INTERNAL` có tự duyệt; gửi.

**Kết quả mong đợi.** Bước 1: nút gửi bị chặn, trường căn cứ pháp lý hiện là bắt buộc kèm gợi ý. Bước 2: gói `DEPRECATED` bị khóa kèm lý do. Bước 3: đăng ký `ACTIVE` ngay, màn báo "đã tự duyệt" và phạm vi được cấp.
:::

#### TC-02-158 · Màn duyệt: thấy rõ thay đổi, bốn mắt, lý do bắt buộc <!--k:ui-review-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P1 · **Tự động.** E2E

**Truy vết.** FR-02-035, 047 · API-02-044, 045, 046 · UI-02-10 · UC-02-16, 24 · BR-02-008 · ERR-02-013, 041.

**Tiền điều kiện, dữ liệu.** Yêu cầu duyệt phiên bản do U-T68-SV1 gửi, API `SENSITIVE`; U-T68-CA, U-T68-TA, U-T68-SV-CA.

**Các bước.**

1. U-T68-CA mở UI-02-10, xem hồ sơ; bấm "Từ chối" không nhập lý do.
2. U-T68-SV-CA mở cùng yêu cầu (người gửi) và bấm "Duyệt".
3. CA duyệt; mở lại bằng TA.

**Kết quả mong đợi.** Bước 1: hồ sơ hiện thay đổi trước, sau, kết quả kiểm tra, người gửi và người sửa gần nhất; từ chối cần lý do. Bước 2: nút bị khóa kèm nêu vai trò trùng (ERR-02-013, không nêu dữ liệu cá nhân). Bước 3: API `SENSITIVE` hiện thêm bước xác nhận của TA.
:::

#### TC-02-159 · Màn đồng bộ quốc gia và SLA: số trên thẻ khớp API, có bảng thay thế biểu đồ <!--k:ui-sync-sla-->

::: dac-ta
**Loại.** Dương · **Ưu tiên.** P2 · **Tự động.** E2E

**Truy vết.** FR-02-054, 056 · API-02-070, 072, 075 · UI-02-11, 12 · UC-02-30, 32 · BR-02-013 · NFR-02-016.

**Tiền điều kiện, dữ liệu.** Tám bản ghi đồng bộ ở mọi trạng thái; một API quá hạn 8 ngày; ba kỳ SLA (đạt, không đạt, chưa đủ dữ liệu).

**Các bước.**

1. Mở UI-02-12; so các thẻ với `GET /national-sync/summary`.
2. Mở UI-02-11; xem kỳ chưa đủ dữ liệu.
3. Bật chế độ bảng thay cho biểu đồ.

**Kết quả mong đợi.** Số khớp API; API quá hạn có chỉ báo; kỳ chưa đủ dữ liệu hiện "chưa đủ dữ liệu" thay vì "đạt" hoặc "không đạt"; mọi biểu đồ có bảng số liệu tương đương.
:::

#### TC-02-160 · Màn nhập hệ cũ, bộ luật, cài đặt: chỉ quản trị, xem trước trước khi xác nhận <!--k:ui-admin-->

::: dac-ta
**Loại.** Dương, Âm · **Ưu tiên.** P2 · **Tự động.** E2E

**Truy vết.** FR-02-021, 061, 062 · API-02-024, 025, 085, 086, 088, 089 · UI-02-15, 16, 17 · UC-02-37, 38 · ERR-02-014.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-SV1, U-T68-VW; F-APIM-EXPORT.

**Các bước.**

1. SV1 và VW mở UI-02-15, 16, 17.
2. TA nạp F-APIM-EXPORT ở UI-02-16 và xem bản xem trước.
3. TA bấm xác nhận khi chưa đọc báo cáo xem trước (cuộn chưa tới cuối).
4. TA đổi một tham số `02.*` rồi hoàn tác.

**Kết quả mong đợi.** Bước 1: VW chỉ xem được bộ luật và tham số, SV1 không thấy nút ghi, màn nhập không hiển thị với hai vai trò này. Bước 2: số API, gói, đăng ký khớp F-APIM-EXPORT (12, 20, 35). Bước 3: có bước xác nhận nêu rõ "không nhập khóa, đăng ký vào `SUSPENDED`". Bước 4: mọi thay đổi ghi kiểm toán.
:::

#### TC-02-161 · Tiếng Việt có dấu, giờ Việt Nam, định dạng số và ngày, ngôn ngữ `en` <!--k:ui-locale-->

::: dac-ta
**Loại.** Dương, Biên · **Ưu tiên.** P3 · **Tự động.** E2E

**Truy vết.** FR-02-001, 003, 056 · API-02-003 · UI-02-01, 02, 11 · UC-02-01 · NFR-02-016.

**Tiền điều kiện, dữ liệu.** Tên API và mô tả có dấu tiếng Việt, ký tự `đ`, `Đ`; dữ liệu có thời điểm `2026-11-26T17:30:00Z`.

**Các bước.**

1. Mở UI-02-01, 02, 11 với múi giờ trình duyệt khác nhau.
2. Tìm `đất đai` và `dat dai`.
3. Chuyển `Accept-Language: en`; gây một lỗi.

**Kết quả mong đợi.** Thời điểm hiện 27/11/2026 00:30 (giờ Việt Nam, UTC+7) bất kể múi giờ trình duyệt; số theo quy ước Việt Nam; hai cách tìm cùng ra kết quả; thông báo lỗi `en` vẫn đủ `code` và `traceId`.
:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Mỗi phiên 90 phút, hai người (một thao tác, một ghi chép), theo mẫu SBTM. Lỗi phát hiện ghi ở công cụ theo dõi với nhãn `PH-02-khám-phá` và chuyển thành ca tự động nếu lặp lại được.

| Phiên | Chủ đề | Gợi ý khám phá | Vai trò tham gia |
|---|---|---|---|
| KP-1 | Đăng ký API bằng trình hướng dẫn | Đặc tả thật của tỉnh thí điểm, tệp dán lạ, URL chậm, thao tác ngược bước, đóng trình duyệt giữa chừng | SV |
| KP-2 | Kiểm tra đặc tả và bí mật | Đặc tả có ví dụ nhạy cảm kiểu mới (khóa dịch vụ cũ, chuỗi kết nối), thử qua mặt bộ quét bằng mã hóa base64, chia nhỏ khóa | SV, SO |
| KP-3 | Gói và đăng ký | Tổ hợp gói, kiểu xác thực, đối tượng được dùng; đổi gói khi đang có đăng ký | SV, OR, CA |
| KP-4 | Vòng đời và phiên bản | Gửi duyệt, rút, từ chối, công bố đồng thời bởi hai người; phiên bản song song | SV, CA, TA |
| KP-5 | Ngừng dùng và thông báo | Ngừng khuyến nghị có đăng ký, hạn gần, thông báo tới bên nhận | SV, OR, TA |
| KP-6 | Quyền và cách ly | Đổi vai trò giữa các thao tác, mở hai tenant ở hai thẻ trình duyệt, đường dẫn đoán mã | Tất cả vai trò |

: Phiên khám phá

### 6.2. Diễn tập di trú từ APIM cũ

Dùng gói xuất đã ẩn danh của một tỉnh thí điểm (nếu chưa có thì dùng F-APIM-EXPORT, Q02-42): nhập ở UI-02-16, đối chiếu số API, gói, đăng ký với APIM cũ, đối chiếu đường dẫn gọi, kiểm tra không có khóa nào được nhập, đăng ký ở `SUSPENDED`. Chạy song song hai hệ theo cách bóp nghẹt dần (strangler) trong 5 ngày làm việc.

Đạt khi: số API, gói, đăng ký khớp 100 %; mọi đường dẫn gọi qua gateway mới cho kết quả như cũ trong 5 ngày; số bước thủ công của TA ≤ 10 cho cả gói; không có khóa hay bí mật nào ở cơ sở dữ liệu, log, báo cáo.

### 6.3. Diễn tập sự cố

Có SO, TO, SV, CA tham gia; mỗi tình huống đo thời gian phát hiện và thời gian xử lý.

| Tình huống | Thao tác | Đạt khi |
|---|---|---|
| Tạm ngừng khẩn một API đang có tải | SO tạm ngừng; kiểm tra gọi từ HTTT khai thác; tiếp tục bởi SO hoặc TA | Gateway áp dụng ≤ 30 giây, thông báo tới bên đăng ký, đối chiếu kiểm toán đủ |
| Gateway không nhận cấu hình | Chặn M-GW (hoặc APISIX ở PERF); công bố một phiên bản | Công bố không hoàn tất, báo ERR-02-033, đối soát phát hiện lệch, đẩy lại thành công khi gateway về |
| Nền tảng quốc gia ngừng 8 ngày | M-NSP không phản hồi; đẩy đồng hồ giả 8 ngày | Bản ghi `RETRY`, cảnh báo tuân thủ ngày thứ 8, không mất bản ghi khi khôi phục |
| Nghi lộ khóa trong đặc tả đã công bố | Chèn mồi vào một đặc tả đã `PUBLISHED` (qua tay), chạy rà soát | Phát hiện, tạm ngừng khẩn, thay đặc tả bằng phiên bản mới, không lặp lại giá trị lộ |

: Diễn tập sự cố

### 6.4. Kiểm thử truy cập thủ công

Với NVDA + Firefox và VoiceOver + Safari trên UI-02-03, 04, 10, 11: đi hết luồng chính (đăng ký API, xem kết quả kiểm tra, duyệt, xem SLA), ghi lỗi theo WCAG 2.2 AA. Kiểm màu tương phản trên nền kính ở thanh điều hướng, thu phóng 200 %, bàn phím không bẫy tiêu điểm trong trình soạn đặc tả.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ vận hành APIM cũ tự thực hiện trên UAT (UAT-01…12 theo chức năng hệ cũ; UAT-13…16 cho chức năng mới, thực hiện cùng đại diện HTTT khai thác). Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem danh sách API, lọc theo trạng thái, tìm theo tên | LGC-APIM-001 | Tìm ra API trong 3 thao tác, không chậm hơn hệ cũ | FR-02-001, 003 | TS-02-01 |
| UAT-02 | Tạo API từ đầu: tên, phiên bản, mô tả, context-path, URL backend | LGC-APIM-002 | Làm được trong 10 phút với wizard, thêm đặc tả bắt buộc | FR-02-010, 022, 024 | TS-02-04, 08 |
| UAT-03 | Tạo API bằng cách nạp Swagger hoặc OpenAPI | LGC-APIM-003 | Nạp được cả Swagger 2.0 và OpenAPI 3.1, thấy lỗi theo dòng | FR-02-011, 016, 017 | TS-02-04, 05 |
| UAT-04 | Lưu nháp rồi gửi duyệt và thử TEST | LGC-APIM-004 | Có nút "Lưu nháp", "Lưu và gửi duyệt"; người duyệt khác người gửi | FR-02-010, 034, 035 | TS-02-04, 11 |
| UAT-05 | Tạm ngừng và tiếp tục API | LGC-APIM-005 | Thao tác có lý do, gateway áp dụng trong 30 giây | FR-02-037 | TS-02-12 |
| UAT-06 | Công bố API lên cổng nhà phát triển và gỡ xuống | LGC-APIM-006 | Đặt mức hiển thị, có thông báo khi gỡ | FR-02-041, 036 | TS-02-15, 11 |
| UAT-07 | Xóa API không còn dùng | LGC-APIM-008 | Chỉ xóa được khi hết đăng ký; có ngừng dùng báo trước | FR-02-038, 039, 040 | TS-02-14 |
| UAT-08 | Tạo gói, chọn Keyless hoặc API key, công bố, ngừng khuyến nghị, đóng | LGC-APIM-009; 010, 011 | Đủ bốn trạng thái, thêm OAuth2, mTLS | FR-02-027, 028, 030, 031, 032 | TS-02-09, 10 |
| UAT-09 | Xem đăng ký theo API và theo ứng dụng, duyệt, thu hồi | LGC-APIM-016; 021 | Thấy đủ trong 3 thao tác, thu hồi có hiệu lực ngay | FR-02-046, 047, 049, 050, 051 | TS-02-16, 17, 18 |
| UAT-10 | Xem đường dẫn sử dụng và mẫu gọi | LGC-APIM-017 | Có URL gateway, mẫu `curl` | FR-02-005, 002 | TS-02-01 |
| UAT-11 | Quản lý nhiều endpoint backend của API | LGC-APIM-018 | Có cân bằng tải, kiểm tra sức khỏe | FR-02-022, 023, 025 | TS-02-08 |
| UAT-12 | Chuyển API, gói, đăng ký từ APIM cũ sang hệ mới; xem API sinh từ luồng PH-04 | LGC-APIM-002; 003, 009, LGC-BUS-028 | Nhập có xem trước, không phải nhập lại khóa; API từ luồng hiện trong danh mục | FR-02-061, 013 | TS-02-23, 07 |
| UAT-13 | Với tư cách đại diện HTTT khai thác: gửi đăng ký sử dụng, chờ duyệt, nhận phạm vi và gọi thử | — (mới, thay quy trình xin khóa thủ công) | Đăng ký có mục đích, khối lượng; duyệt đúng cấp; sau duyệt gọi được trong 30 giây, không ai cấp tay | FR-02-046, 047, 048 | TS-02-16, 17 |
| UAT-14 | Công bố phiên bản mới có duyệt bốn mắt; ngừng khuyến nghị phiên bản cũ và thông báo bên dùng | — (mới) | Người duyệt khác người gửi; bên đăng ký nhận thông báo; lộ trình ≥ 180 ngày | FR-02-035, 038, 042, 057 | TS-02-11, 13, 14, 21 |
| UAT-15 | Theo dõi đồng bộ danh mục lên Nền tảng quốc gia và xử lý bản ghi bị từ chối | — (mới, đáp ứng CMP-LAW-03, 19) | Thấy trạng thái từng API, thử lại được, cảnh báo khi quá hạn | FR-02-053, 054 | TS-02-19 |
| UAT-16 | Khai báo cam kết chất lượng (SLA) và xem tuân thủ theo kỳ | — (mới) | SLA cam kết cạnh số liệu thực tế; kỳ thiếu dữ liệu không bị kết luận | FR-02-055, 056 | TS-02-20 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-02. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph02/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-02-001 | Liệt kê API trong danh mục, lọc, sắp xếp | M | LGC-APIM-001 | 001, 154, 161 | 002, 085, 154 | 143 | Có |
| FR-02-002 | Xem chi tiết API | M | LGC-APIM-001; LGC-APIM-017 | 003, 086 | 002, 086 | 077 | Có |
| FR-02-003 | Tìm kiếm toàn văn danh mục | M | LGC-APIM-001 | 004, 161 | 002, 085 | — | Có |
| FR-02-004 | Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển  | M | mới | 006, 087 | 007, 087 | — | Có |
| FR-02-005 | Xem đường dẫn sử dụng và mẫu gọi API | M | LGC-APIM-017 | 005 | 005, 084 | — | Có |
| FR-02-006 | Tải đặc tả OpenAPI đã công bố | M | mới | 005 | 005, 084 | — | Có |
| FR-02-007 | Phân loại và gắn thẻ API | M | mới | 009, 090 | 010, 090, 097 | — | Có |
| FR-02-008 | Quản lý bộ phân loại và thẻ | S | mới | 011 | 011, 089 | — | Có |
| FR-02-009 | Hiển thị dịch vụ sự kiện (topic) trong danh mục | S | mới | 008 | 088 | — | Có |
| FR-02-010 | Đăng ký API mới bằng trình hướng dẫn | M | LGC-APIM-002; LGC-APIM-004 | 012, 153 | 016, 091, 097, 149, 153 | — | Có |
| FR-02-011 | Nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL | M | LGC-APIM-003 | 012, 013, 153 | 013, 076, 092, 093, 149, 153 | 078 | Có |
| FR-02-012 | Đồng bộ lại đặc tả từ URL nguồn, phát hiện thay đổi | S | mới | 025 | 025, 098 | — | Có |
| FR-02-013 | Tự đăng ký API từ luồng REST của PH-04 | M | LGC-BUS-028 | 026 | 026, 099 | — | Có |
| FR-02-014 | Sửa thông tin API và đặc tả khi còn bản nháp | M | LGC-APIM-002 | 015, 026 | 014, 015, 026, 079, 164 | 078 | Có |
| FR-02-015 | Cung cấp mẫu đặc tả và quy ước viết API | S | mới | 015 | 015 | — | Có |
| FR-02-016 | Kiểm tra đặc tả lớp 1: chuẩn OpenAPI 3.1 | M | LGC-APIM-003 | 018, 153 | 017, 018, 076, 094, 153 | — | Có |
| FR-02-017 | Kiểm tra đặc tả lớp 2: quy ước nền tảng | M | mới | 018 | 018, 095 | — | Có |
| FR-02-018 | Quét bí mật và dữ liệu cá nhân thật trong đặc tả | M | mới | 023 | 021, 022, 023, 097 | 078 | Có |
| FR-02-019 | Kiểm tra đặc tả không lưu (xem trước khi gõ) | M | mới | 019, 153 | 019, 094, 153 | — | Có |
| FR-02-020 | Phát hiện API trùng chức năng | S | mới | 024, 096 | 096 | — | Có |
| FR-02-021 | Quản lý bộ luật kiểm tra quy ước | S | mới | 020, 160 | 020, 160 | — | Có |
| FR-02-022 | Khai báo backend của API | M | LGC-APIM-002; LGC-APIM-018 | 028 | 029, 030, 031, 100, 102, 164 | 077 | Có |
| FR-02-023 | Cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức  | M | LGC-APIM-018 | 028 | 030, 102, 165 | — | Có |
| FR-02-024 | Quản lý context-path và kiểm tra trùng | M | LGC-APIM-002; LGC-APIM-017 | 012, 162 | 014, 091, 162 | — | Có |
| FR-02-025 | Xem sức khỏe backend | S | LGC-APIM-018 | 028, 101 | 031, 101 | — | Có |
| FR-02-026 | Sinh khung route cho PH-04 từ đặc tả | M | mới | 027, 163 | 027, 163 | — | Có |
| FR-02-027 | Tạo gói sử dụng: thông tin và điều kiện truy cập | M | LGC-APIM-009; LGC-APIM-010 | 032, 106, 166 | 033, 105, 164, 166 | — | Có |
| FR-02-028 | Chọn kiểu xác thực của gói | M | LGC-APIM-011 | 032, 034, 103 | 033, 034, 103, 164 | — | Có |
| FR-02-029 | Khai báo hạn mức và đường dẫn cho phép của gói | M | LGC-APIM-012; LGC-APIM-013; LGC-APIM-014… | 032, 034 | 033, 034, 104, 164 | — | Có |
| FR-02-030 | Công bố gói (`STAGING` sang `PUBLISHED`) | M | LGC-APIM-009 | 035 | 035, 079, 110 | — | Có |
| FR-02-031 | Ngừng khuyến nghị gói | M | LGC-APIM-009 | 036, 107, 166 | 036, 107, 166 | — | Có |
| FR-02-032 | Đóng gói | M | LGC-APIM-009 | 036, 108, 109 | 036, 108, 109 | — | Có |
| FR-02-033 | Sao chép gói sang phiên bản mới | S | LGC-APIM-009 | 037 | 037 | — | Có |
| FR-02-034 | Gửi duyệt công bố API | M | LGC-APIM-004 | 039, 147, 155 | 038, 111, 149, 155, 164 | — | Có |
| FR-02-035 | Duyệt hoặc từ chối công bố (bốn mắt) | M | mới | 039, 112, 113, 147, 155, 158, 167 | 040, 079, 110, 112, 155, 158, 167 | — | Có |
| FR-02-036 | Công bố API ra gateway và danh mục | M | LGC-APIM-004; LGC-APIM-006 | 039, 083, 114, 117, 147 | 041, 117, 164, 165 | 080, 150 | Có |
| FR-02-037 | Tạm ngừng và tiếp tục API | M | LGC-APIM-005 | 042, 115, 147, 155 | 043, 115, 155, 165 | — | Có |
| FR-02-038 | Ngừng khuyến nghị API có lộ trình | M | LGC-APIM-008 | 047, 118, 147 | 048 | — | Có |
| FR-02-039 | Ngừng hẳn API | M | LGC-APIM-008 | 049, 147 | 049, 119 | — | Có |
| FR-02-040 | Xóa API | M | LGC-APIM-008 | 050, 083, 147 | 050, 120 | — | Có |
| FR-02-041 | Đặt mức hiển thị, công bố và gỡ khỏi cổng nhà phát triển | M | LGC-APIM-006; LGC-APIM-007 | 051, 121 | 051 | — | Có |
| FR-02-042 | Tạo phiên bản mới | M | mới | 044, 117 | 045, 117 | — | Có |
| FR-02-043 | So sánh phiên bản và phân loại thay đổi phá vỡ | M | mới | 044, 156 | 045, 046, 116 | — | Có |
| FR-02-044 | Phân tích tác động của thay đổi tới bên khai thác | M | mới | 044, 118, 156 | 046, 119 | 077 | Có |
| FR-02-045 | Chuyển chủ quản API | S | mới | 052 | 052 | — | Có |
| FR-02-046 | Gửi đăng ký sử dụng API | M | LGC-APIM-016; LGC-APIM-021 | 053, 125, 154, 155, 157 | 054, 079, 122, 123, 124, 154, 155, 157 | — | Có |
| FR-02-047 | Duyệt hoặc từ chối đăng ký sử dụng | M | LGC-APIM-016 | 053, 055, 126, 154, 158, 167 | 055, 126, 154, 158, 167 | — | Có |
| FR-02-048 | Cấp phạm vi truy cập theo đăng ký đã duyệt | M | mới | 056, 127 | 056, 127 | 150 | Có |
| FR-02-049 | Xem đăng ký theo API | M | LGC-APIM-016 | 057 | 057, 128 | 077 | Có |
| FR-02-050 | Xem đăng ký theo HTTT | M | LGC-APIM-021 | 057 | 057, 128 | — | Có |
| FR-02-051 | Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký | M | LGC-APIM-016; LGC-APIM-021 | 058, 125, 147, 155 | 058, 079, 129, 155 | — | Có |
| FR-02-052 | Gia hạn và rà soát định kỳ đăng ký | S | mới | 059 | 130 | — | Có |
| FR-02-053 | Đồng bộ danh mục lên Nền tảng quốc gia qua PH-14 | M | mới | 060 | 060, 079, 131, 149 | 061, 142 | Có |
| FR-02-054 | Theo dõi trạng thái đồng bộ, thử lại, cảnh báo quá hạn | M | mới | 060, 121, 132, 154, 159 | 060, 131, 132, 154 | 061 | Có |
| FR-02-055 | Khai báo cam kết chất lượng dịch vụ (SLA) | M | mới | 062 | 062, 134 | — | Có |
| FR-02-056 | Đối chiếu SLA thực tế, báo cáo tuân thủ | M | mới | 063, 083, 159, 161, 168 | 063, 134, 168 | 133 | Có |
| FR-02-057 | Thông báo thay đổi cho bên khai thác | M | mới | 064, 151 | 064, 135 | — | Có |
| FR-02-058 | Thống kê sử dụng dịch vụ | S | mới | 065 | 065, 136 | — | Có |
| FR-02-059 | Cung cấp giao diện nội bộ cho PH-03, PH-04, PH-15 | M | mới | 066, 114 | 066, 137 | 080 | Có |
| FR-02-060 | Đối soát cấu hình công bố với gateway | C | mới | 067 | 067, 138 | 081 | Có |
| FR-02-061 | Di trú API, gói, đăng ký từ APIM cũ | M | LGC-APIM-002; LGC-APIM-003; LGC-APIM-009… | 068, 160 | 068, 139, 140, 160 | 078 | Có |
| FR-02-062 | Cấu hình tham số của phân hệ | M | mới | 069, 141, 160 | 069, 141, 160 | — | Có |

: Truy vết từ yêu cầu chức năng sang test case

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng kết nối của Bus tích hợp (`LGC-BUS`) và Productivity Tooling (`LGC-TOOL`) được truy tới FR mới và tới ca tự động, ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-APIM-001 | 001, 002, 003 | 001, 003, 004, 086, 154, 161 | UAT-01 |
| LGC-APIM-002 | 010, 014, 022, 024, 061 | 012, 015, 026, 028, 068, 153, 162 | UAT-02, UAT-12 |
| LGC-APIM-003 | 011, 016, 061 | 012, 013, 018, 068, 153 | UAT-03, UAT-12 |
| LGC-APIM-004 | 010, 034, 036 | 012, 039, 083, 114, 117, 147, 153, 155 | UAT-04 |
| LGC-APIM-005 | 037 | 042, 115, 147, 155 | UAT-05 |
| LGC-APIM-006 | 036, 041 | 039, 051, 083, 114, 117, 121, 147 | UAT-06 |
| LGC-APIM-007 | 041 | 051, 121 | — |
| LGC-APIM-008 | 038, 039, 040 | 047, 049, 050, 083, 118, 147 | UAT-07 |
| LGC-APIM-009 | 027, 030, 031, 032, 033, 061 | 032, 035, 036, 037, 068, 106, 107, 108 (+2) | UAT-08, UAT-12 |
| LGC-APIM-010 | 027 | 032, 106, 166 | UAT-08 |
| LGC-APIM-011 | 028 | 032, 034, 103 | UAT-08 |
| LGC-APIM-012 | 029 | 032, 034 | — |
| LGC-APIM-013 | 029 | 032, 034 | — |
| LGC-APIM-014 | 029 | 032, 034 | — |
| LGC-APIM-015 | 029 | 032, 034 | — |
| LGC-APIM-016 | 046, 047, 049, 051, 061 | 053, 055, 057, 058, 125, 126, 147, 154 (+4) | UAT-09 |
| LGC-APIM-017 | 002, 005, 024 | 003, 005, 012, 084, 086, 162 | UAT-10 |
| LGC-APIM-018 | 022, 023, 025 | 028, 101 | UAT-11 |
| LGC-APIM-021 | 046, 050, 051, 061 | 053, 057, 058, 125, 147, 154, 155, 157 | UAT-09 |
| LGC-BUS-028 | 013 | 026 | UAT-12 |

: Truy vết từ chức năng hệ cũ sang yêu cầu và test case

### 8.3. Quy tắc nghiệp vụ → test case

Bảng dưới liệt kê từng quy tắc nghiệp vụ (BR-02) và các ca kiểm thử chứng minh quy tắc đó; ba chữ số là số cuối mã TC-02.

| Mã | Test case |
|---|---|
| BR-02-001 | 005, 038, 092, 111 |
| BR-02-002 | 016, 018 |
| BR-02-003 | 044, 045, 111, 156 |
| BR-02-004 | 047, 048, 107, 118 |
| BR-02-005 | 047, 048, 107 |
| BR-02-006 | 049, 119 |
| BR-02-007 | 010, 097 |
| BR-02-008 | 035, 040, 051, 055, 107, 110, 112, 158, 164, 167 |
| BR-02-009 | 051, 060, 061, 121, 131, 142 |
| BR-02-010 | 027, 163 |
| BR-02-011 | 054, 122, 124, 157 |
| BR-02-012 | 053, 054, 059, 123, 130, 157 |
| BR-02-013 | 003, 063, 133, 134, 159, 168 |
| BR-02-014 | 041, 049, 050, 084, 098, 152 |
| BR-02-015 | 021, 022, 038, 068, 078, 111, 139 |
| BR-02-016 | 033, 103 |
| BR-02-017 | 034, 104 |
| BR-02-018 | 036, 107, 124 |
| BR-02-019 | 036, 108 |
| BR-02-020 | 050, 120 |
| BR-02-021 | 011, 033, 037, 045, 050, 068, 089, 091, 109, 140 |
| BR-02-022 | 014, 091, 162 |
| BR-02-023 | 029, 093, 100 |
| BR-02-024 | 027, 028, 030, 038, 102, 117 |
| BR-02-025 | 056, 066, 125, 127 |
| BR-02-026 | 053, 055, 126, 130, 157 |
| BR-02-027 | 054, 123, 125 |
| BR-02-028 | 018, 058, 062, 069, 086, 090, 095, 109, 110, 112 (+6) |
| BR-02-029 | 064, 118, 121, 126, 135, 151 |
| BR-02-030 | 015, 026, 099 |
| BR-02-031 | 063, 133, 168 |
| BR-02-032 | 010, 015, 016, 031, 052, 120 |
| BR-02-033 | 007, 031, 046, 057, 065, 066, 077, 086, 088, 096 (+12) |
| BR-02-034 | 042, 043, 058, 115, 129 |
| BR-02-035 | 037, 044, 117 |
| BR-02-036 | 068, 078, 139, 140 |
| BR-02-037 | 006, 010, 051, 087, 121 |
| BR-02-038 | 008, 088 |
| BR-02-039 | 002, 005, 084, 086, 087, 105, 166 |
| BR-02-040 | 032, 106 |

: Truy vết từ quy tắc nghiệp vụ sang test case

### 8.4. Mã lỗi → test case

Bảng dưới liệt kê từng mã lỗi ERR-02 và các ca kiểm thử làm phát sinh lỗi đó; mã nào chưa có ca sẽ được đánh dấu khi sinh bảng.

| Mã | Test case |
|---|---|
| ERR-02-001 | 002, 005, 007, 031, 046, 057, 065, 066, 077, 084 (+20) |
| ERR-02-002 | 011, 014, 016, 033, 037, 045, 050, 068, 089, 109 (+1) |
| ERR-02-003 | 016, 020, 030, 062, 069, 085, 087, 089, 091, 099 (+14) |
| ERR-02-004 | 016, 052 |
| ERR-02-005 | 013, 017, 076 |
| ERR-02-006 | 017, 076, 111, 153 |
| ERR-02-007 | 018, 111 |
| ERR-02-008 | 021, 022, 038, 078, 111, 139, 146 |
| ERR-02-009 | 013, 076, 092, 139 |
| ERR-02-010 | 013, 093 |
| ERR-02-011 | 025, 026, 034, 036, 043, 049, 056, 058, 059, 089 (+11) |
| ERR-02-012 | 035, 038, 102, 117 |
| ERR-02-013 | 023, 035, 040, 055, 107, 158 |
| ERR-02-014 | 007, 010, 011, 015, 020, 023, 026, 031, 035, 040 (+39) |
| ERR-02-015 | 015, 090, 141, 145, 167 |
| ERR-02-016 | 010, 097 |
| ERR-02-017 | 045, 111 |
| ERR-02-018 | 045, 111 |
| ERR-02-019 | 014, 162 |
| ERR-02-020 | 029, 100 |
| ERR-02-021 | 027, 030, 038 |
| ERR-02-022 | 033, 103 |
| ERR-02-023 | 033, 062, 104 |
| ERR-02-024 | 036, 108 |
| ERR-02-025 | 036, 054, 124, 157 |
| ERR-02-026 | 054, 122 |
| ERR-02-027 | 054, 123 |
| ERR-02-028 | 054, 123 |
| ERR-02-029 | 054, 123, 130, 157 |
| ERR-02-030 | 049, 050, 119, 120 |
| ERR-02-031 | 048, 107 |
| ERR-02-032 | 048, 107 |
| ERR-02-033 | 041, 056, 080, 138, 149, 150 |
| ERR-02-034 | 041, 060, 080, 098, 101, 131, 146, 149, 154, 163 (+1) |
| ERR-02-035 | 025, 060, 067, 094, 098, 131, 138, 163 |
| ERR-02-036 | 013, 019, 064, 093, 094 |
| ERR-02-037 | 027, 104 |
| ERR-02-038 | 015, 163, 164 |
| ERR-02-039 | 043, 165 |
| ERR-02-040 | 030, 033, 069, 105 |
| ERR-02-041 | 016, 018, 038, 043, 058, 095, 107, 109, 110, 112 (+6) |
| ERR-02-042 | 054, 114, 140, 144 |
| ERR-02-043 | 010, 051 |
| ERR-02-044 | 060, 131 |
| ERR-02-045 | 068, 139 |

: Truy vết từ mã lỗi sang test case

### 8.5. Yêu cầu phi chức năng → test case

Bảng dưới liệt kê từng yêu cầu phi chức năng (NFR-02) và các ca kiểm thử đo hoặc chứng minh yêu cầu đó.

| Mã | Test case |
|---|---|
| NFR-02-001 | 006, 070, 087 |
| NFR-02-002 | 004, 071 |
| NFR-02-003 | 019, 072 |
| NFR-02-004 | 044, 073 |
| NFR-02-005 | 074 |
| NFR-02-006 | 070, 075, 143, 144 |
| NFR-02-007 | 080, 143, 149 |
| NFR-02-008 | 080, 149, 150 |
| NFR-02-009 | 081, 150 |
| NFR-02-010 | 075 |
| NFR-02-011 | 029, 072, 076, 092 |
| NFR-02-012 | 021, 022, 078, 146 |
| NFR-02-013 | 007, 057, 077, 145, 146 |
| NFR-02-014 | 061, 142 |
| NFR-02-015 | 063, 064, 113, 118, 151 |
| NFR-02-016 | 082, 159, 161 |
| NFR-02-017 | 083, 152 |
| NFR-02-018 | 081, 137, 148 |
| NFR-02-019 | 061, 083 |
| NFR-02-020 | 067, 081 |

: Truy vết từ yêu cầu phi chức năng sang test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Mã kiểm thử nằm ở `dh-connect/src/test` (UT, IT, DB), `contract-tests/ph02` (Pact), `api-tests/ph02` (REST Assured, mỗi ca một lớp đặt theo mã `TC02xxx`), `e2e/ph02` (Playwright), `perf/ph02` (k6). Dữ liệu nạp bằng `seed-ph02.sh`; ca tiêu thụ M-GW, M-NSP, M-FLOW, M-URL chạy với bộ giả trong `testdoubles/ph02`.

### 9.2. Mẫu ca dò mồi bí mật (JUnit)

Đoạn mã dưới là mẫu ca JUnit cho kiểu ca "dò mồi": gài giá trị `DH-CANARY` vào đặc tả rồi kiểm không nơi nào ngoài chỗ được phép chứa nó.

```java
@Tag("canary") @Tag("TC-02-078")
@Test void canaryNeverLeavesTheSpecGate() {
  var canary = "DH-CANARY-all-" + UUID.randomUUID();
  var spec = Fixtures.openApi("F-SPEC-OK").withExample("$.paths./dat-dai.get.responses.200", canary);
  var up = api.as(U_T68_SV1).body(spec).post("/spec-uploads");
  up.then().statusCode(200);
  api.as(U_T68_SV1).post("/apis/tc-nhap/versions/1.0.0:submit").then().statusCode(422)
     .body("code", equalTo("ERR-02-008"))
     .body("findings[0]", not(hasKey("value")));      // không lặp lại giá trị
  assertThat(har.allBodies()).doesNotContain(canary);
  assertThat(loki.query("{namespace=~\"dh-.*\"}", Duration.ofMinutes(5))).doesNotContain(canary);
  assertThat(db.dumpSchema("ph02_catalog")).doesNotContain(canary);
  assertThat(kafka.readAll("t68\\..*", Duration.ofSeconds(10))).doesNotContain(canary);
}
```

### 9.3. Mẫu ca bảng tham số hóa: kiểu xác thực theo mức dữ liệu (REST Assured)

Đoạn mã dưới là mẫu ca tham số hóa, chạy cùng một ca với nhiều cặp mức dữ liệu và kiểu xác thực.

```java
@ParameterizedTest @Tag("TC-02-103")
@CsvSource({"PUBLIC,KEYLESS,200", "PUBLIC,OAUTH2_MTLS,200",
            "INTERNAL,KEYLESS,422", "INTERNAL,API_KEY,200",
            "RESTRICTED,API_KEY,422", "RESTRICTED,OAUTH2_PKJWT,200",
            "SENSITIVE,OAUTH2_PKJWT,422", "SENSITIVE,OAUTH2_MTLS,200"})
void authTypeFollowsDataClass(String dataClass, String authType, int status) {
  var v = fixtures.draftVersion("tc-auth-" + dataClass.toLowerCase(), dataClass);
  var r = api.as(U_T68_SV1).ifMatch(v.planEtag())
      .body(Map.of("authType", authType, "quota", Map.of("perSecond", 5, "dailyCalls", 1000)))
      .put(v.plan("goi-nhap") + "/access-policy");
  r.then().statusCode(status);
  if (status == 422) r.then().body("code", equalTo("ERR-02-022"));
}
```

### 9.4. Mẫu ca trình hướng dẫn (Playwright)

Đoạn mã dưới là mẫu ca Playwright cho trình hướng dẫn đăng ký API, dùng làm khuôn cho các ca giao diện còn lại.

```ts
test('TC-02-153 trình hướng dẫn chặn bước thiếu trường và giữ bản nháp', async ({ page }) => {
  await page.goto('/danh-muc-dich-vu/dang-ky-api');
  await page.getByRole('button', { name: 'Tiếp' }).click();
  await expect(page.getByRole('alert')).toContainText('Mã API là bắt buộc');   // chữ, không chỉ màu
  await page.getByLabel('Mã API').fill('tc-wizard');
  await page.getByLabel('Tên hiển thị').fill('Tra cứu thử');
  await page.reload();                                                         // bản nháp còn nguyên
  await expect(page.getByLabel('Mã API')).toHaveValue('tc-wizard');
  await page.getByRole('button', { name: 'Tiếp' }).click();
  await page.setInputFiles('input[type=file]', 'fixtures/F-SPEC-L1.yaml');
  await page.getByRole('link', { name: /dòng \d+/ }).first().click();
  await expect(page.locator('.cm-activeLine')).toBeVisible();                   // nhảy đúng dòng lỗi
});
```

### 9.5. Sinh ma trận, Gherkin, bảng tính

Bảng dưới nêu các lệnh sinh ma trận truy vết, tệp Gherkin và bảng tính từ chính nội dung tập này, để các tệp đi kèm luôn khớp với tài liệu.

| Lệnh | Kết quả |
|---|---|
| `python3 ph02/tools/number_tcs.py` | Cấp số `TC-02-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph02/tools/fill_doc.py` | Ghi bảng kịch bản (3.1), số kịch bản, số ca, ma trận mục 8; in ra stderr BR, ERR, NFR chưa có ca |
| `python3 ph02/tools/gen_gherkin.py` | `ph02/gherkin/ts-02-nn.feature` |
| `python3 ph02/tools/gen_xlsx.py` | `ph02/D05-02-PH02-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

## Câu hỏi mở

> **Câu hỏi mở Q02-40:** SIT dùng APISIX thật ba bản sao hay gateway giả (M-GW) cho các ca đo hiệu lực cấu hình (TC ở TS-02-24)? Giả định: M-GW ở SIT, APISIX thật chỉ ở PERF vì NFR-02-005 đo lan truyền ảnh chụp.

> **Câu hỏi mở Q02-41:** Bộ 50 mẫu chuẩn bí mật và dữ liệu cá nhân (NFR-02-012) do cán bộ ATTT nào cấp và duyệt? Giả định: nhóm ATTT dự án sinh bộ ngẫu nhiên đúng định dạng, không dùng dữ liệu thật.

> **Câu hỏi mở Q02-42:** Có gói xuất APIM cũ thật đã ẩn danh của một tỉnh để chạy UAT-12 không? Giả định: dùng F-APIM-EXPORT sinh theo cấu trúc APIM cũ trong `docs/`.

> **Câu hỏi mở Q02-43:** PH-14 có môi trường thử Nền tảng quốc gia (sandbox) cho TS-02-19 không? Giả định: dùng M-NSP đến khi có sandbox.

> **Câu hỏi mở Q02-44:** Hồ sơ tải 2.000 API ở PERF do ai nạp và khi nào? Giả định: sinh bằng `seed-ph02.sh --scale=medium` trước RG-3.

## Đề nghị đồng bộ

Các việc dưới đây nằm ngoài quyền sửa của tập này (tài liệu dùng chung hoặc tập khác); chuyển cho luồng hoặc đợt đồng bộ phụ trách.

- D02-08: PH-02 dùng "quyền quản trị phân hệ (động từ `admin`)" cho tham số, bộ phân loại, bộ luật, chuyển chủ quản, di trú; đề nghị bổ sung động từ `admin` vào ma trận PERM-02 (trùng đề nghị ở FRS PH-02).
- D05-01: bổ sung môi trường PERF có hồ sơ 2.000 API cho NFR-02-001…006 và ca hỗn loạn CX-01 áp dụng cho `dh-connect` (NFR-02-008).
- D05-01: bổ sung tenant rỗng `T91`, bộ giả M-TOPIC, M-MAIL, đồng hồ giả và cờ đóng băng vào danh mục môi trường và bộ giả dùng chung.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: kịch bản chức năng, phi chức năng, 12 UAT, ma trận truy vết sinh tự động |
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Lượt bổ sung: thêm ca âm, biên, bảng tham số hóa cho FR, ERR, API còn mỏng; kịch bản giao diện TS-02-28; 4 UAT chức năng mới; thủ tục thủ công, mẫu mã tự động; giữ nguyên mã đã cấp |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: thêm TC-02-166…168 cho API-02-096, 097, 098; thêm EVT-02-16 vào TC-02-113; tách tài khoản dịch vụ S-GW-ACK; thêm chú thích cho bảng ma trận (sinh tự động); Giới thiệu theo khuôn; thêm câu mở cho các mục chỉ có bảng |
