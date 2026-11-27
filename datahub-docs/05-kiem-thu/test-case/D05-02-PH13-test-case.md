---
ma_tai_lieu: D05-02-PH13
ten: Kịch bản và test case phân hệ PH-13 Giám sát và kiểm toán
phien_ban: 0.5
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, kiểm toán viên, chủ đầu tư (UAT)
phan_he: PH-13
mo_ta: Kịch bản và test case của phân hệ Giám sát và kiểm toán (quan sát, nhật ký kiểm toán chuỗi băm, cảnh báo, phát hiện bất thường), chạy được ngay trên SIT với bộ dữ liệu mẫu, kèm nghiệm thu người dùng tương đương hệ cũ và ma trận truy vết.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH13 FRS; D02-04-PH13 Use case; D03-02-PH13 SDD; D03-03-PH13 CSDL; D03-04-PH13 API; D03-06-PH13 Màn hình
---

# D05-02-PH13 · Kịch bản và test case Giám sát và kiểm toán

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-13 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH13: thu thập dữ liệu quan sát, nhật ký kiểm toán chuỗi băm, tra cứu, bảng điều khiển, cảnh báo, phát hiện bất thường an ninh và các dịch vụ cho phân hệ khác.
- Không mất chức năng giám sát của hệ cũ: histogram và chi tiết agent, route, endpoint của Bus (LGC-BUS-007, 014…019, 027, 029, 030, 038), đồ thị CPU, bộ nhớ của Hub (LGC-HUB-005, 006), log request, danh sách và giám sát gateway, audit của APIM (LGC-APIM-022…027), log có cấu trúc và sao lưu log (LGC-NFR-004, 005).
- Nhật ký kiểm toán đúng là bằng chứng: mọi thao tác có bản ghi, không sửa được, phát hiện được can thiệp, tenant này không thấy dữ liệu của tenant khác, không có giá trị Nhạy cảm nào lọt vào log, trace, chỉ số hay bản ghi kiểm toán.

**Phạm vi.** Gồm <!--gen:so-ts-->41<!--/gen--> kịch bản (TS-13-01…) với <!--gen:so-tc-->135 (TC-13-001…135; 96 ca P1)<!--/gen--> test case và 12 kịch bản nghiệm thu người dùng (UAT-01…12). Mỗi FR mức M có ít nhất một ca dương và một ca âm; mọi API-13-001…090, UI-13-01…18, UC-13-01…43 và mọi mã ERR-13 có ít nhất một ca; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph13/tools/gen_matrix.py`. Các kịch bản chấp nhận `AT-13-001…034` của SRS cũ được ánh xạ vào các ca ở đây (FRS D02-03-PH13, mục 11).

**Căn cứ.** Tài liệu cùng bộ PH-13 (FRS D02-03-PH13, use case D02-04-PH13, SDD D03-02-PH13, CSDL D03-03-PH13, API D03-04-PH13, màn hình D03-06-PH13); ma trận phân quyền D02-08 (PERM-13); biện pháp SEC-60…67 ở D03-07; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP, TCVN 14423:2026; nhật ký kiểm toán online 12 tháng, WORM 5 năm (ADR-030).

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- nhật ký kiểm toán bất biến: không sửa, không xóa, can thiệp bị phát hiện, đứt chuỗi báo ngay (TS-13-05…08, TS-13-41);
- không mất bản ghi kiểm toán khi PH-13, PostgreSQL, OpenBao hoặc WORM ngừng đến 4 giờ (TS-13-09, TS-13-39);
- không giá trị Nhạy cảm dạng rõ trong log, trace, chỉ số, bản ghi kiểm toán, kiểm bằng giá trị mồi `DH-CANARY` (TS-13-02, TS-13-35);
- cách ly tenant ở mọi API đọc và ở Mimir, Loki, Tempo, ClickHouse, Grafana, PostgreSQL, WORM (TS-13-36);
- mọi lượt tra cứu, xuất, xác minh kiểm toán đều bị ghi vết, bắt buộc lý do và xác thực lại phiên (TS-13-11, 13, 14, 37);
- PH-13 ngừng không làm gateway hay runtime lỗi (TS-13-39).

Mã W1 hiện có của repo chỉ có khung dịch vụ; các ca ở đây là tiêu chí nghiệm thu của công việc mới. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, `QM-VUA`: 200 HTTT, 5 triệu lượt gọi API mỗi ngày, khoảng 100.000 bản ghi kiểm toán mỗi ngày) vì chưa có dữ liệu thật.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu là tập 7 của bộ PH-13. Mục đích là cung cấp bộ ca kiểm thử đủ để chứng minh PH-13 đạt các yêu cầu ở D02-03-PH13, thiết kế ở D03-02, D03-03, D03-04, D03-06-PH13 và không làm mất chức năng giám sát, nhật ký của hệ cũ. Phạm vi gồm ca chức năng (chương 4), ca phi chức năng và xuyên suốt (chương 5), thủ tục thủ công (chương 6) và nghiệm thu người dùng (chương 7). Ca được viết để chạy được ngay trên môi trường SIT với bộ dữ liệu mục 2, không cần hỏi lại.

### 0.2. Người đọc

Người đọc chính là kiểm thử viên (viết, chạy ca), kỹ sư (viết ca tự động), cán bộ ATTT và kiểm toán viên (ca TS-13-05…14, 35…37, 41) và chủ đầu tư (UAT mục 7).

### 0.3. Thuật ngữ và chữ viết tắt

Mỗi ca ở chương 4 và 5 viết theo một khối thống nhất với D05-02-PH04, D05-02-PH05: Loại, Ưu tiên, Tự động, Truy vết, Tiền điều kiện và dữ liệu, Bước, Mong đợi. Thuật ngữ dùng chung với [D02-03-PH13](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) mục 1.4 và D00-01; viết tắt riêng của tài liệu này: TS là kịch bản kiểm thử, TC là ca kiểm thử, UAT là nghiệm thu người dùng, IT là kiểm thử tích hợp, UT là kiểm thử đơn vị.

### 0.4. Tài liệu tham chiếu

D05-01 (kế hoạch kiểm thử), D02-03-PH13, D02-04-PH13, D03-02-PH13, D03-03-PH13, D03-04-PH13, D03-06-PH13, D02-08 (phân quyền), D03-07 (an toàn thông tin).

### 0.5. Cấu trúc tài liệu

Tài liệu gồm chín chương; bảng dưới tóm tắt nội dung từng chương.

| Chương | Nội dung |
|---|---|
| 1 | Phạm vi, chiến lược, môi trường, tiêu chí vào ra, quy ước |
| 2 | Dữ liệu kiểm thử |
| 3 | Danh sách kịch bản (sinh tự động) |
| 4 | 34 kịch bản chức năng TS-13-01…34 |
| 5 | Kịch bản phi chức năng và xuyên suốt TS-13-35…41 |
| 6 | Thủ tục kiểm thử thủ công |
| 7 | Nghiệm thu người dùng tương đương hệ cũ |
| 8 | Ma trận truy vết (sinh tự động) |
| 9 | Tự động hóa và tệp đi kèm |

: Cấu trúc tài liệu

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Bảng dưới nêu các thành phần chịu kiểm thử của PH-13, từ mặt điều khiển (API, giao diện) đến mặt dữ liệu (thu thập, chuỗi băm, kho WORM), để người đọc biết phạm vi của bộ ca ở chương 4 và 5.

| Đối tượng | Thành phần | Ghi chú |
|---|---|---|
| Control plane | Mô-đun `observability` và `audit` trong `dh-platform` (Spring Boot 4, Spring Modulith) | API `/api/observability/v1`, `/api/audit/v1`, `/api/platform/v1`; bộ neo, bộ sao WORM, bộ quản lý phân vùng, bộ phát hiện |
| Ghi vết ở nguồn | Thư viện `dh-audit` trong mọi DU, hộp thư đi, topic `{tenant}.audit.record.v1` | Ca nguồn phát chạy ở SIT với DU giả lập `F-DU-SIM` |
| Quan sát | OpenTelemetry Collector, Mimir, Loki, Tempo, Grafana, Alertmanager, ClickHouse (lượt gọi API) | LGTM; Ruler đánh giá luật |
| Kho bất biến | Bảng `audit_event` chỉ-thêm phân vùng theo tháng, kho WORM Ceph RGW Object Lock | Q306, Q341, Q347 |
| Khóa | OpenBao: khóa ký neo, khóa HMAC theo tenant | Không xuất khóa |
| Bên ngoài | SIEM, SOC (IF-08), kênh thông báo, PH-18 gửi thư và SMS (IF-09) | Giả lập `F-SIM-SIEM`, `F-SIM-CHAN` |
| Giao diện | UI-13-01…18 | React + antd v6, ECharts |

: Đối tượng kiểm thử

### 1.2. Mức kiểm thử

Bộ ca được phân theo các mức kiểm thử ở bảng dưới; cột "Ký hiệu" là giá trị của trường **Tự động** trong từng ca.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Tính băm chuỗi, chuẩn hóa JSON, quy tắc luật, che dữ liệu, máy trạng thái cảnh báo |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka, OpenBao, MinIO có Object Lock, ClickHouse) | Tiếp nhận, neo, WORM, đối chiếu |
| CSDL | DB | `psql` với `ph13_isolation_test.sql` (171 khối kiểm); ca rò rỉ T90, T91 cho ClickHouse viết riêng vì bài kiểm PostgreSQL chưa phủ | RLS, vai trò chỉ `INSERT`, `SELECT`, chặn `UPDATE`, `DELETE`, `TRUNCATE`; nhóm ca cô lập tenant, bất biến nhật ký, tách nhiệm |
| Hợp đồng | CT | `check_contracts.py`, Spectral, `@asyncapi/parser` | OpenAPI, AsyncAPI |
| API | API | REST Assured | Mọi API-13 |
| Đầu cuối | E2E | Playwright | UI-13-* |
| Hiệu năng | k6 | k6, tải log, span | NFR-13-001…010, 013, 017, 018, 031 |
| Chịu lỗi | Chaos | Chaos Mesh | PostgreSQL, OpenBao, WORM, Kafka, Mimir, Loki ngừng |
| Bảo mật | ZAP | OWASP ZAP, Trivy, Semgrep, bộ quét mồi | ASVS 5.0 mức 2 |
| Truy cập | A11Y | axe-core, NVDA | WCAG 2.2 AA |

: Mức kiểm thử

### 1.3. Môi trường kiểm thử

Các môi trường dưới đây khác nhau ở mức thật của phụ thuộc; chỉ ca hiệu năng và ca chịu lỗi dài chạy ở môi trường có kho và hạ tầng thật.

| Môi trường | Mô tả | Dùng cho |
|---|---|---|
| SIT | K8s một cụm, tenant T68, T01, PLATFORM, T90, T91; LGTM, ClickHouse, Kafka, OpenBao, kho WORM thật; DU, SIEM, kênh thông báo giả lập (mục 2.4) | API, E2E, RT, Chaos |
| PERF | Cấu hình `QM-VUA` theo D03-09, dữ liệu GĐ-01…07; 34 tenant giả cho ca thông lượng toàn nền tảng | k6 |
| UAT | Như SIT, có dữ liệu chuỗi kiểm toán 12 tháng sinh sẵn và dữ liệu giám sát mô phỏng như Bus cũ | UAT mục 7 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào và ra

Bảng dưới nêu điều kiện để bắt đầu và để kết thúc một vòng kiểm thử PH-13; tiêu chí ra là căn cứ cho tiêu chí chấp nhận cấp phân hệ ở D02-03-PH13 chương 14.

| Loại | Tiêu chí |
|---|---|
| Vào | D02-03-PH13 ở trạng thái duyệt; DDL `ph13` áp được; hợp đồng OpenAPI, AsyncAPI qua CT; bộ dữ liệu mục 2 nạp xong; chứng thư DU giả lập và khóa ký neo thử ở OpenBao sẵn sàng |
| Ra | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt, ca còn lại có lỗi mở mức Thấp; 0 lỗi mở mức Nghiêm trọng, Cao; ma trận mục 8 không có FR mức M thiếu ca dương hoặc ca âm; TS-13-05…09, 35, 36, 39, 41 đạt 100 % |

: Tiêu chí vào và ra

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-13-nn`, test case `TC-13-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi test case có:

- Tiêu đề: mã, tên ca.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, RT, CT, API, E2E, k6, Chaos, ZAP, A11Y, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC.
- **Tiền điều kiện / dữ liệu**: mã dữ liệu ở mục 2.
- **Bước**: đánh số. Đường dẫn API tương đối với đường gốc của nhóm ở D03-04-PH13 mục 3 (`/api/observability/v1`, `/api/audit/v1`, `/api/platform/v1`).
- **Mong đợi**: mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-13-009 (thiếu quyền `PERM-13-*`) |
| 404-ẩn | `404` với ERR-13-001, thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT: có (hành động) | Có bản ghi kiểm toán với `action` đó, đủ trường EN-13-01, không chứa bí mật; thao tác nhạy cảm có `reason` |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{tên}` | Đúng một bản tin trên topic `t68.obs.{tên}.v1` (CloudEvents, có `dhtenant`) |
| EVT: không | Sau 10 giây không có bản tin trên topic liên quan |
| Mồi sạch | Tìm chuỗi `DH-CANARY-{ca}` trong phản hồi API, log ứng dụng 5 phút, trace, chỉ số, bảng `ph13.*`, bản ghi kiểm toán, Kafka, tệp xuất: không thấy |

: Quy ước mã và cách trình bày

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-13`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: sửa hoặc xóa được bản ghi kiểm toán; đứt chuỗi mà không phát hiện; mất bản ghi kiểm toán; lộ giá trị Nhạy cảm trong log, trace, chỉ số, bản ghi kiểm toán; đọc được dữ liệu quan sát hay kiểm toán của tenant khác; tra cứu hay xuất kiểm toán mà không có bản ghi ghi vết; gói bằng chứng chưa ký được phát hành; PH-13 ngừng làm gateway lỗi. Báo cáo hằng đêm từ JUnit, Playwright, k6, đối chiếu ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Nạp bằng `ph13/seed/` qua API và DU giả lập (không chèn SQL trực tiếp vào bảng kiểm toán), trừ ca cố ý can thiệp ở TS-13-08 và TS-13-41 dùng tài khoản DBA thử chỉ có ở SIT.

### 2.1. Tenant

Bộ ca dùng các tenant giả lập dưới đây; mỗi tenant đại diện một cấu hình khác nhau (thời hạn lưu WORM, giờ trực, cấp nền tảng) để kiểm cách ly và tham số theo tenant.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính (giả lập) | Hồ sơ `QM-VUA`; `13.audit.worm-retention-years = 5`; giờ hành chính mặc định |
| `T01` | Tỉnh đối chứng rò rỉ | Có luồng, luật cảnh báo, truy vấn đã lưu **trùng mã** với T68 (`luong-chung`, `luat-cpu-cao`) nhưng khác nội dung, để phát hiện trả nhầm |
| `PLATFORM` | Tenant nền tảng | Luật chuẩn, bộ dashboard chuẩn, thao tác quản trị nền tảng |
| `T90` | Tenant mới | Ca khởi tạo quan sát và chuỗi kiểm toán (FR-13-059) |
| `T91` | Tenant sẽ ngừng | Ca đóng chuỗi (FR-13-060); có chuỗi 3 tháng sinh sẵn |

: Tenant

### 2.2. Người dùng

Viết tắt vai trò theo FRS D02-03-PH13 mục 3.1. Mọi người dùng vai trò TA, SO, AU, PA có TOTP thử để kiểm thử xác thực lại phiên.

| Mã | Tenant | Vai trò | Mục đích |
|---|---|---|---|
| U-PA | PLATFORM | PA | Luật chuẩn, SIEM nền tảng, phiên liên tenant |
| U-PO | PLATFORM | PO | Vận hành nền tảng; không có `PERM-13-audit-read` |
| U-T68-TA | T68 | TA | Cấu hình, luật, lịch trực, tham số |
| U-T68-TO | T68 | TO | Theo dõi, xử lý cảnh báo, chẩn đoán |
| U-T68-SO | T68 | SO | Cảnh báo an ninh, xuất bằng chứng |
| U-T68-AU | T68 | AU | Kiểm toán, chỉ đọc; xuất bằng chứng |
| U-T68-IE | T68 | IE | Tra log, trace luồng của mình |
| U-T68-SV | T68 | SV | Chủ dịch vụ, chỉ xem API của tổ chức `ORG-SO-TTTT` |
| U-T68-VW | T68 | VW | Chỉ `PERM-13-dashboard` |
| U-T68-NONE | T68 | Không vai trò PH-13 | Ca thiếu quyền |
| U-T01-TO, U-T01-AU | T01 | TO, AU | Đối chứng rò rỉ |
| S-DU | — | Tài khoản máy `dh-audit` của DU giả lập | Scope `audit:write`; mTLS |
| S-PH16 | — | PH-16 | Scope `obs:metrics-read` |
| S-PH18 | — | PH-18 | Scope `obs:diagnostics-read`, `obs:health-read` |
| S-PH20 | — | PH-20 | Scope `obs:tenant-provision` |
| S-AM | — | Alertmanager | Chứng thư mTLS cho API-13-090 |
| S-HIST | — | DU chủ đối tượng | Scope `audit:history-read` |
| U-OPS | PLATFORM | Đội vận hành (vai trò di trú, không có `PERM-13-*`) | Chạy `AuditRestore` trong cửa sổ bảo trì (FR-13-062) |

: Người dùng

### 2.3. Bộ dữ liệu

Các bộ dữ liệu dưới đây được sinh bằng công cụ của PH-13 hoặc nạp từ tệp mẫu; cột "Dùng cho" cho biết kịch bản nào cần bộ nào.

| Mã | Nội dung | Dùng cho |
|---|---|---|
| F-AUD-1K | Chuỗi T68 gồm 1.000 bản ghi từ 3 DU giả lập, 24 giờ, có neo ở giờ chẵn, lô WORM đã sao | TS-13-05…14 |
| F-AUD-12M | Chuỗi T68 theo tháng 13 tháng, tháng thứ 13 đã `SEALED` và WORM đã xác minh | TS-13-10 |
| F-AUD-CUT | Bản sao F-AUD-1K đã sửa trực tiếp một bản ghi ở bảng (bằng tài khoản DBA thử) | TS-13-08, 41 |
| F-AUD-PII | Bản ghi có `before`, `after` chứa số định danh, bí mật mồi `DH-CANARY` | TS-13-02, 05, 35 |
| F-LOG-CAN | 1.000 dòng log JSON, trong đó 20 dòng chứa mẫu CCCD giả, số điện thoại, thư điện tử, mồi `DH-CANARY` | TS-13-02, 35 |
| F-TRACE-MIX | 100 trace: 10 có lỗi, 5 chậm hơn p99, 5 chạm dữ liệu Nhạy cảm, 80 bình thường | TS-13-01, 16 |
| F-ACCESS-5M | 5 triệu bản ghi lượt gọi API trong 24 giờ, 200 HTTT | TS-13-17, 38 |
| F-RULE-STD | Bộ luật chuẩn nền tảng (FR-13-043) ở `PLATFORM`; luật riêng `luat-cpu-cao` ở T68 và T01 | TS-13-24 |
| F-DU-SIM | DU giả lập phát bản ghi kiểm toán, chỉ số, log; có thể phát sai (thiếu trường, trùng `id`, sai tenant, đồng hồ lệch) | TS-13-01, 05, 09 |
| F-SIM-SIEM | Máy thu syslog và HTTP giả, có thể ngắt | TS-13-31 |
| F-SIM-CHAN | Kênh thông báo giả: thư điện tử, SMS, webhook, ứng dụng; ghi thời điểm nhận | TS-13-25, 27 |
| F-AUD-LAG | Chuỗi T68 và T01 như F-AUD-1K nhưng cơ sở dữ liệu khôi phục PITR về trước lô WORM mới nhất khoảng 4 phút (bảng đứng sau WORM); WORM đủ bản ghi, có neo | TS-13-08 (FR-13-062) |
| F-SEC-EVT | Chuỗi bản ghi kiểm toán dựng sẵn khớp từng luật UC-SEC (đăng nhập thất bại hàng loạt, giải mã dữ liệu bất thường, sửa quyền ngoài giờ…) | TS-13-29, 30 |

: Bộ dữ liệu kiểm thử

### 2.4. Hệ giả lập

Để kiểm PH-13 mà không cần hệ thật của bên ngoài, các hệ giả lập dưới đây thay DU, SIEM và kênh thông báo ở SIT; chúng đếm số bản ghi phát để đối chiếu với số bản ghi PH-13 nhận.

| Mã | Mô tả |
|---|---|
| F-DU-SIM | Ba DU giả `dh-connect`, `dh-integration`, `dh-data` có chứng thư thật của SIT, phát bản ghi theo kịch bản và đếm số bản ghi phát |
| F-SIM-SIEM | Máy thu `siem.sim.test` hai cổng: TCP syslog và HTTPS ECS; có công tắc ngắt |
| F-SIM-CHAN | Máy chủ thư và cổng SMS giả; webhook `chan.sim.test` |
| PH-01 giả lập | Nhận API-01-089 bằng token dịch vụ `onboarding:suspension-proposal`, ghi lại thân yêu cầu; công tắc `down` (503), `suspended` (409 ERR-01-048), `not-allowed` (409 ERR-01-005), `duplicate` (202 với `duplicate = true`) |
| F-WORM | Kho WORM SIT (Ceph RGW Object Lock) có bucket riêng cho mỗi tenant; tài khoản ghi không có quyền xóa |

: Hệ giả lập

### 2.5. Nguyên tắc dữ liệu

Không dùng dữ liệu thật. Số định danh và số điện thoại trong bộ dữ liệu sinh từ dải số giả. Mồi `DH-CANARY-{ca}` đặt vào mọi chỗ có thể rò (thân bản ghi, nhãn, tên trường, thông điệp lỗi) để ca bảo mật dò được. Ca có tác dụng phụ tạo dữ liệu mã `tc-*` và tự dọn sau ca; ca chạy lại được.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-13-01 | Thu thập chỉ số, log, trace và lấy mẫu | Xác nhận mọi thành phần phát chỉ số, log JSON, vết có `trace_id` và dữ liệu có nhãn tenant đúng; thay "lấy dữ liệu JMX/Jolokia" và "logging quá trình routing" của Bus cũ; lấy mẫu trace theo đuôi giữ 100 % trace lỗi, chậm, chạm dữ liệu Nhạy cảm | UC-13-01 | 6 |
| TS-13-02 | Che dữ liệu Nhạy cảm và quét phát hiện lọt | Xác nhận không giá trị Nhạy cảm dạng rõ nào ở log, trace, chỉ số; quét phát hiện mẫu lọt và cảnh báo nguồn mà không ghi lại giá trị | UC-13-02 | 3 |
| TS-13-03 | Siêu dữ liệu lượt gọi API và chỉ số thành phần nền | Xác nhận APISIX gửi siêu dữ liệu lượt gọi vào ClickHouse không lộ nội dung, và thành phần nền (Kafka, PostgreSQL, OpenBao, APISIX) có chỉ số sức khỏe; thay "log mọi request" của APIM | UC-13-03 | 3 |
| TS-13-04 | Kiểm tra tổng hợp và cách ly dữ liệu quan sát theo tenant | Xác nhận kiểm tra tổng hợp mỗi phút phát hiện sự cố đường vào và truy vấn quan sát của tenant này không chạm dữ liệu tenant khác | UC-13-04, 01 | 4 |
| TS-13-05 | Tiếp nhận và chuỗi băm theo tenant | Xác nhận bản ghi từ DU được xác thực, ghi chỉ-thêm và nối chuỗi băm liên tục theo từng tenant; bản ghi sai bị cách ly, trùng bị bỏ | UC-13-05 | 4 |
| TS-13-06 | Neo băm ký hằng giờ và sao lô sang WORM | Xác nhận neo băm được ký bằng khóa OpenBao, lưu ở ba nơi độc lập, và bản ghi được sao lô sang kho WORM không xóa được | UC-13-06 | 4 |
| TS-13-07 | Kiểm tra toàn vẹn chuỗi | Xác nhận kiểm tra toàn vẹn hằng ngày, gia tăng khi neo và theo yêu cầu cho kết quả đúng, chỉ đọc, có lý do | UC-13-07 | 3 |
| TS-13-08 | Xử lý đứt chuỗi và neo không khớp | Xác nhận mọi can thiệp vào bản ghi đã neo bị phát hiện, báo ngay mức Nghiêm trọng, và hệ thống không tự sửa | UC-13-08 | 8 |
| TS-13-09 | Chịu lỗi, đệm bản ghi và đối chiếu số lượng | Xác nhận không mất bản ghi kiểm toán khi PH-13 hay kho ngừng, DU từ chối thao tác nhạy cảm khi không ghi vết được, và bộ đếm của DU khớp số nhận | UC-13-09 | 5 |
| TS-13-10 | Lưu giữ, lưu trữ phân vùng và tự kiểm toán của PH-13 | Xác nhận phân vùng quá 12 tháng chỉ lưu trữ khi WORM đã xác minh đủ, và mọi thao tác trên PH-13 đều có bản ghi kiểm toán | UC-13-10, 11 | 4 |
| TS-13-11 | Tra cứu nhật ký kiểm toán | Xác nhận tra cứu kiểm toán bắt buộc lý do, giới hạn khoảng và phạm vi, xác thực lại phiên, và chính lượt tra cứu bị ghi vết; thay "Audit" của APIM | UC-13-12, 14 | 4 |
| TS-13-12 | Lịch sử theo đối tượng cho tab "Lịch sử" | Xác nhận DU chủ đối tượng lấy được lịch sử thay đổi của đối tượng qua scope hẹp, chỉ trong tenant | UC-13-13 | 2 |
| TS-13-13 | Xuất bằng chứng kiểm toán ký số | Xác nhận gói bằng chứng bắt buộc ký số, kèm script xác minh ngoại tuyến, liên kết tải hết hạn, và mọi bước bị ghi vết | UC-13-15 | 3 |
| TS-13-14 | Báo cáo truy cập liên tenant | Xác nhận truy cập liên tenant luôn qua phiên có lý do, hết hạn 60 phút, ghi ở cả hai chuỗi và tenant bị truy cập được báo | UC-13-16 | 2 |
| TS-13-15 | Tra log tập trung | Xác nhận tra log theo điều kiện, ngữ cảnh, theo dõi trực tiếp; thay "quản trị log agent"; giới hạn đồng thời, khoảng, cú pháp | UC-13-17 | 3 |
| TS-13-16 | Truy vết và liên kết bằng `trace_id` | Xác nhận tìm trace, thác nước và liên kết chỉ số, trace, log, kiểm toán theo một `trace_id`; thay "logging quá trình routing" | UC-13-18 | 2 |
| TS-13-17 | Nhật ký truy cập API | Xác nhận tra lượt gọi API theo khoảng 24 giờ và HTTT trong 3 giây; thay "log mọi request" của APIM; không lộ nội dung | UC-13-19 | 2 |
| TS-13-18 | Bảng giám sát tổng quan và sức khỏe thành phần | Xác nhận bảng tổng quan nền tảng và API sức khỏe cho phân hệ khác; thay "tổng quan toàn hệ thống" và "dashboard hoạt động chung" của Bus, APIM | UC-13-20, 39 | 2 |
| TS-13-19 | Data plane: đơn vị triển khai, luồng, route, endpoint | Xác nhận bảng điều khiển data plane thay histogram, chi tiết agent, route, endpoint của Bus; chỉ số đúng tenant | UC-13-21 | 2 |
| TS-13-20 | Theo API và theo HTTT | Xác nhận chủ dịch vụ chỉ thấy chỉ số của API tổ chức mình | UC-13-22 | 2 |
| TS-13-21 | Hạ tầng: nút gateway, cụm Kafka | Xác nhận danh sách, chi tiết, tài nguyên gateway và cụm Kafka; thay "danh sách gateway", "giám sát gateway" của APIM và đồ thị CPU, bộ nhớ của Hub | UC-13-23 | 2 |
| TS-13-22 | Hoạt động nghiệp vụ và bảng điều khiển an ninh | Xác nhận lãnh đạo xem hoạt động nghiệp vụ không thấy log, kiểm toán; cán bộ ATTT xem bảng an ninh | UC-13-24 | 2 |
| TS-13-23 | Quản lý bộ dashboard theo tenant | Xác nhận bộ dashboard chuẩn đồng bộ sang Grafana của tenant, không sửa tay tại chỗ | UC-13-25 | 2 |
| TS-13-24 | Luật cảnh báo, runbook và bộ luật chuẩn | Xác nhận luật cảnh báo bắt buộc runbook đủ năm mục, biểu thức hợp lệ, chạy thử được; luật chuẩn nền tảng tenant không sửa, chỉ nhân bản | UC-13-26, 27 | 5 |
| TS-13-25 | Từ điều kiện bất thường đến thông báo người trực | Xác nhận luật được đánh giá, chống nhấp nháy, phân mức, gom nhóm, gửi theo lịch trực và leo thang đúng thời gian | UC-13-28 | 5 |
| TS-13-26 | Xử lý cảnh báo | Xác nhận xác nhận, đã xử lý, tạm ẩn theo máy trạng thái, có thời hạn, nguyên nhân, hành động | UC-13-29 | 2 |
| TS-13-27 | Lịch trực, nhóm nhận, kênh thông báo | Xác nhận lịch trực không hở, không chồng, nhóm Nghiêm trọng có đường độc lập; thử gửi kênh | UC-13-30 | 2 |
| TS-13-28 | Giám sát chính hệ thống giám sát và thống kê hiệu quả cảnh báo | Xác nhận có "giám sát người giám sát" độc lập và thống kê cảnh báo giả | UC-13-31, 32 | 2 |
| TS-13-29 | Luật phát hiện UC-SEC | Xác nhận bộ luật phát hiện UC-SEC nạp sẵn, tinh chỉnh ngưỡng trong biên, luật "mọi sự kiện" không tắt | UC-13-33 | 2 |
| TS-13-30 | Phát hiện bất thường và xử lý cảnh báo an ninh | Xác nhận bộ phát hiện sinh cảnh báo an ninh từ bản ghi kiểm toán, đóng cần kết luận, đề xuất tạm ngừng HTTT chuyển PH-01 chứ không tự thực hiện | UC-13-34, 35 | 8 |
| TS-13-31 | Đẩy sang SIEM, SOC và báo cáo sự cố | Xác nhận log và cảnh báo an ninh sang SIEM đã loại dữ liệu cá nhân, chuẩn ECS hoặc OCSF; hàng đợi đĩa khi SIEM ngừng; báo cáo sự cố sinh từ cảnh báo | UC-13-36, 37 | 3 |
| TS-13-32 | Dịch vụ cho phân hệ khác | Xác nhận PH-16 lấy số liệu tổng hợp và PH-18 lấy ngữ cảnh chẩn đoán qua scope hẹp, đúng tenant | UC-13-38, 39 | 2 |
| TS-13-33 | Vòng đời tenant: khởi tạo và đóng chuỗi | Xác nhận PH-20 khởi tạo quan sát và chuỗi kiểm toán cho tenant mới, lũy đẳng; đóng chuỗi khi ngừng hoặc sáp nhập, có neo cuối | UC-13-40, 41 | 3 |
| TS-13-34 | Tham số và hạn mức quan sát theo tenant | Xác nhận tenant đặt tham số `13.*` trong biên, vượt trần nền tảng bị từ chối | UC-13-42 | 3 |
| TS-13-35 | Không lộ dữ liệu Nhạy cảm | Chứng minh giá trị mồi `DH-CANARY` đặt vào mọi chỗ không xuất hiện ở log, trace, chỉ số, bản ghi kiểm toán, tệp xuất, SIEM | — | 2 |
| TS-13-36 | Cách ly tenant | Chứng minh 0 truy vấn chéo tenant thành công ở mọi API đọc và mọi kho | — | 2 |
| TS-13-37 | Phân quyền và tách nhiệm | Chứng minh ma trận `PERM-13-*` ở D02-08 được thực thi, người vận hành không đọc được kiểm toán, người xem không thấy log, và người xuất bằng chứng cần xác thực lại | — | 3 |
| TS-13-38 | Hiệu năng, tải và quy mô | Chứng minh NFR-13-001…010, 017, 018, 031 ở cấu hình `QM-VUA`, dữ liệu GĐ | — | 10 |
| TS-13-39 | Chịu lỗi và không chặn data plane | Chứng minh PH-13 hay kho quan sát ngừng không làm gateway, runtime, DU lỗi và 0 bản ghi kiểm toán mất | — | 3 |
| TS-13-40 | Truy cập và giao diện | Chứng minh mọi màn UI-13 đạt WCAG 2.2 AA và dùng được bằng bàn phím, trình đọc màn hình, không chỉ dựa vào màu | — | 2 |
| TS-13-41 | Bất biến nhật ký kiểm toán | Chứng minh không vai trò nào, kể cả quản trị cơ sở dữ liệu, sửa hoặc xóa được nhật ký ngoài tiến trình lưu trữ hợp lệ, và can thiệp bị phát hiện | — | 2 |
| **Tổng** | | | | **135** (96 ca P1) |

: Danh sách kịch bản
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Bảng dưới liệt kê các đối tượng có vòng đời ở PH-13 và kịch bản kiểm các chuyển trạng thái của từng đối tượng; máy trạng thái định nghĩa ở D02-03-PH13 mục 4.3–4.6.

| Đối tượng | Trạng thái | Kịch bản |
|---|---|---|
| Cảnh báo EN-13-09 | `FIRING` → `ACKNOWLEDGED` → `SILENCED` → `RESOLVED` | TS-13-25, 26 |
| Cảnh báo an ninh EN-13-15 | `NEW` → `ACKNOWLEDGED` → `CLOSED` | TS-13-30 |
| Phân vùng kiểm toán EN-13-21 | `OPEN` → `SEALED` → `ARCHIVED` | TS-13-10 |
| Yêu cầu xuất bằng chứng EN-13-05 | `PENDING` → `RUNNING` → `READY` → `EXPIRED` | TS-13-13 |
| Luật cảnh báo EN-13-07 | Bật, tắt, ngừng dùng | TS-13-24 |

: Máy trạng thái được kiểm thử

## 4. Kịch bản và test case chức năng

### TS-13-01 · Thu thập chỉ số, log, trace và lấy mẫu

**Mục tiêu.** Xác nhận mọi thành phần phát chỉ số, log JSON, vết có `trace_id` và dữ liệu có nhãn tenant đúng; thay "lấy dữ liệu JMX/Jolokia" và "logging quá trình routing" của Bus cũ; lấy mẫu trace theo đuôi giữ 100 % trace lỗi, chậm, chạm dữ liệu Nhạy cảm.

**Phủ.** FR-13-001, 002, 003, 004, 009; UC-13-01; NFR-13-001, 002, 003, 020, 027; BR-13-010, 026, 027; ERR-13-113, 114, 115, 116, 117; LGC-BUS-030, 038; LGC-NFR-004.

#### TC-13-001 · Thu chỉ số, log, trace từ DU giả lập có nhãn tenant <!--k:collect-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-001, 002, 003, 009 · UC-13-01 · NFR-13-027 · BR-13-027 · LGC-BUS-030 · LGC-NFR-004
- **Tiền điều kiện / dữ liệu** F-DU-SIM ba DU; T68.
- **Bước**
  1. F-DU-SIM phát 100 mẫu chỉ số, 100 dòng log JSON, 20 span có `traceparent`.
  2. Truy vấn Mimir, Loki, Tempo bằng nhãn `tenant="t68"` sau 60 giây.
- **Mong đợi** Cả ba nguồn có đủ dữ liệu; mọi dòng log là JSON có `trace_id`, `tenant`, `du`, `level`; nhãn `tenant` do hệ thống gắn từ chứng thư, không lấy từ nội dung do DU gửi (BR-13-027).

#### TC-13-002 · Thiếu nhãn tenant, nhãn ngoài danh sách, nhãn cardinality cao <!--k:collect-label-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-001, 009 · BR-13-026, 027 · ERR-13-113, 114 · NFR-13-020
- **Tiền điều kiện / dữ liệu** F-DU-SIM phát sai.
- **Bước**
  1. Phát mẫu không có nhãn tenant.
  2. Phát mẫu có nhãn `trace_id`, `user_id`, `client_ip` và một nhãn lạ.
  3. Phát mẫu với nhãn `tenant="t01"` từ DU của T68.
- **Mong đợi** Bước 1: mẫu gán `_unattributed`, chỉ U-PA thấy; ERR-13-113 trên chỉ số bộ thu. Bước 2: nhãn bị bỏ, mẫu vẫn vào; ERR-13-114. Bước 3: nhãn bị ghi đè bằng `t68`; T01 không thấy mẫu nào.


#### TC-13-121 · Log sai định dạng, span thiếu `traceparent`, trace chưa đủ quyết định lấy mẫu <!--k:collect-format-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-002, 003, 004 · BR-13-010, 011 · ERR-13-116, 117 · NFR-13-027
- **Tiền điều kiện / dữ liệu** F-DU-SIM phát sai.
- **Bước**
  1. Phát dòng log không phải JSON và dòng thiếu `trace_id`.
  2. Phát span không có `traceparent`.
  3. Phát trace nhưng bỏ span cuối, chờ quá thời gian quyết định.
- **Mong đợi** Dòng sai được bọc thành log JSON mức `WARN` kèm nguồn, không bị bỏ; span thiếu `traceparent` tạo trace mới có cờ; trace thiếu span: ERR-13-117, vẫn giữ nếu lỗi; DU nguồn bị đưa vào danh sách thiếu đo lường (NFR-13-027).

#### TC-13-003 · Giới hạn số chuỗi hoạt động của tenant <!--k:series-limit-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** k6
- **Truy vết** FR-13-001 · NFR-13-020 · BR-13-026 · ERR-13-114 · EVT-13-14
- **Tiền điều kiện / dữ liệu** `13.series.max-active = 1.000` ở T68 (giảm cho ca).
- **Bước**
  1. Phát 850 chuỗi riêng biệt, rồi 1.001 chuỗi.
- **Mong đợi** Đạt 85 %: EVT: `capacity.warning`. Quá 1.000: chuỗi mới bị bỏ, chuỗi cũ vẫn ghi; ERR-13-114; cảnh báo hiển thị ở UI-13-01.

#### TC-13-004 · Lấy mẫu trace theo đuôi giữ trace lỗi, chậm, nhạy cảm <!--k:trace-tail-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-003, 004 · BR-13-010 · NFR-13-003 · ERR-13-116, 117
- **Tiền điều kiện / dữ liệu** F-TRACE-MIX; `13.trace.success-sample-percent = 10`.
- **Bước**
  1. Phát F-TRACE-MIX và chờ quá `13.trace.decision-wait-seconds`.
  2. Đếm trace trong Tempo theo nhóm.
  3. Phát một trace có 3.000 span và một trace thiếu span cha.
- **Mong đợi** Giữ đủ 10 trace lỗi, 5 chậm, 5 nhạy cảm; trong 80 trace bình thường giữ 6…10. Trace 3.000 span bị cắt, ERR-13-116; trace thiếu span: ERR-13-117, vẫn lưu.

#### TC-13-005 · Bộ thu quá tải đệm và bỏ dữ liệu ít quan trọng <!--k:collector-overload-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** Chaos
- **Truy vết** FR-13-001, 002 · ERR-13-115 · NFR-13-007, 013 · BR-13-015
- **Tiền điều kiện / dữ liệu** Một bản sao collector; F-DU-SIM phát gấp 3 lần ngưỡng.
- **Bước**
  1. Phát tải cao 10 phút.
- **Mong đợi** Collector đệm; bỏ log mức `DEBUG`, `INFO` trước; giữ `ERROR` và bản ghi kiểm toán; ERR-13-115 hiện ở UI-13-01; DU nguồn không lỗi, không chậm.

### TS-13-02 · Che dữ liệu Nhạy cảm và quét phát hiện lọt

**Mục tiêu.** Xác nhận không giá trị Nhạy cảm dạng rõ nào ở log, trace, chỉ số; quét phát hiện mẫu lọt và cảnh báo nguồn mà không ghi lại giá trị.

**Phủ.** FR-13-005; UC-13-02; BR-13-011, 035; NFR-13-021, 024; ERR-13-105, 112; API-13-016; UI-13-06.

#### TC-13-006 · Che số định danh, số điện thoại, thư điện tử trong log trước khi lưu <!--k:redact-ok-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-005 · BR-13-011 · NFR-13-021
- **Tiền điều kiện / dữ liệu** F-LOG-CAN; U-T68-IE.
- **Bước**
  1. Phát F-LOG-CAN qua collector.
  2. Tìm trong Loki các mẫu CCCD giả, số điện thoại giả, thư điện tử giả và `DH-CANARY-redact`.
- **Mong đợi** 0 kết quả cho giá trị gốc; dòng log còn lại có dấu che `***`; trường không nhạy cảm giữ nguyên.

#### TC-13-007 · Quét hằng ngày phát hiện mẫu lọt, báo nguồn, không lưu giá trị <!--k:redact-leak-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-005, 040 · ERR-13-112 · BR-13-011 · UC-13-02 · API-13-016 · UI-13-06 · EVT-13-04
- **Tiền điều kiện / dữ liệu** Tắt bộ che cho một DU thử; F-LOG-CAN; U-T68-SO.
- **Bước**
  1. DU thử ghi 20 dòng chứa mẫu CCCD giả.
  2. Chạy bộ quét; U-T68-SO mở UI-13-06, mục kết quả quét; gọi `GET /dashboards/security`.
- **Mong đợi** Kết quả quét nêu DU, số dòng, loại mẫu, khoảng thời gian; không có giá trị gốc; cảnh báo nguồn DU; ERR-13-112; EVT: `security-alert.raised`.

#### TC-13-008 · Bản ghi kiểm toán chứa giá trị Nhạy cảm chưa che bị cách ly <!--k:audit-pii-quarantine-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-005, 010 · BR-13-035 · NFR-13-024 · ERR-13-105
- **Tiền điều kiện / dữ liệu** F-AUD-PII; S-DU.
- **Bước**
  1. Gửi bản ghi có `after.password = DH-CANARY-pii`.
  2. Tra chuỗi T68 theo `id`.
- **Mong đợi** Bản ghi vào bảng cách ly, không vào chuỗi, `seq` không nhảy; ERR-13-105; cảnh báo `WARNING` cho DU nguồn; mồi sạch ở mọi nơi trừ bảng cách ly đã che.

### TS-13-03 · Siêu dữ liệu lượt gọi API và chỉ số thành phần nền

**Mục tiêu.** Xác nhận APISIX gửi siêu dữ liệu lượt gọi vào ClickHouse không lộ nội dung, và thành phần nền (Kafka, PostgreSQL, OpenBao, APISIX) có chỉ số sức khỏe; thay "log mọi request" của APIM.

**Phủ.** FR-13-006, 007; UC-13-03; BR-13-011, 015, 016; ERR-13-118; EVT-13-14; LGC-APIM-022.

#### TC-13-009 · Lượt gọi API qua APISIX vào kho lượt gọi, không có thân yêu cầu <!--k:access-capture-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-006 · UC-13-03 · BR-13-011 · LGC-APIM-022
- **Tiền điều kiện / dữ liệu** 50 lượt gọi tới HTTT giả lập, một lượt có thân chứa `DH-CANARY-access`.
- **Bước**
  1. Gửi 50 lượt gọi qua APISIX.
  2. Truy vấn ClickHouse (qua API-13-025) trong 60 giây.
- **Mong đợi** 50 bản ghi có `trace_id`, HTTT, API, mã trả về, thời gian, kích thước; không thân yêu cầu, không tiêu đề `Authorization`; mồi sạch.

#### TC-13-010 · Kho lượt gọi API ngừng, gateway không bị chặn <!--k:access-store-down-->
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-13-006 · BR-13-015 · ERR-13-118 · NFR-13-014
- **Tiền điều kiện / dữ liệu** Tắt ClickHouse 10 phút; gửi 100 lượt/giây.
- **Bước**
  1. Tắt ClickHouse; gửi tải; bật lại.
- **Mong đợi** 0 lượt gọi lỗi do PH-13; Kafka giữ siêu dữ liệu; sau khi bật lại bản ghi vào đủ, không trùng; ERR-13-118 hiện ở UI-13-01.

#### TC-13-011 · Chỉ số thành phần nền đủ cho Kafka, PostgreSQL, OpenBao, APISIX <!--k:infra-metrics-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-007 · BR-13-016 · EVT-13-14 · NFR-13-027
- **Tiền điều kiện / dữ liệu** SIT đủ thành phần; tắt exporter của OpenBao.
- **Bước**
  1. Truy vấn `GET /components`.
  2. Tắt exporter của OpenBao 2 phút, truy vấn lại.
- **Mong đợi** Bước 1: mọi thành phần có trạng thái. Bước 2: OpenBao hiển thị "Chưa có dữ liệu" (không phải 0), các thành phần khác không đổi.

### TS-13-04 · Kiểm tra tổng hợp và cách ly dữ liệu quan sát theo tenant

**Mục tiêu.** Xác nhận kiểm tra tổng hợp mỗi phút phát hiện sự cố đường vào và truy vấn quan sát của tenant này không chạm dữ liệu tenant khác.

**Phủ.** FR-13-008, 009; UC-13-04, 01; API-13-070, 071; UI-13-01, 17; NFR-13-022, 030; ERR-13-040, 124; EVT-13-13.

#### TC-13-012 · Khai báo và chạy kiểm tra tổng hợp mỗi phút <!--k:probe-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-008 · UC-13-04 · API-13-070, 071 · UI-13-01, 17 · NFR-13-030
- **Tiền điều kiện / dữ liệu** U-T68-TA; HTTT giả lập `HT-NDXP`.
- **Bước**
  1. Mở UI-13-17, thêm kiểm tra tổng hợp tới `HT-NDXP`, chu kỳ mặc định 60 giây.
  2. Chờ 3 chu kỳ; mở UI-13-01.
- **Mong đợi** `PATCH /settings` trả `200`; KT: có (`OBS.SETTINGS.UPDATE`); có kết quả mỗi phút; thay đổi có hiệu lực ≤ 60 giây.

#### TC-13-013 · Kiểm tra thất bại liên tiếp sinh cảnh báo và sự kiện <!--k:probe-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-008 · ERR-13-124 · EVT-13-13 · BR-13-016
- **Tiền điều kiện / dữ liệu** `HT-NDXP` ngắt.
- **Bước**
  1. Ngắt `HT-NDXP`; chờ 5 chu kỳ.
- **Mong đợi** ERR-13-124; EVT: `probe.failed`; cảnh báo hiển thị ở UI-13-01; khi `HT-NDXP` về, sau 5 phút cảnh báo tự `RESOLVED`.

#### TC-13-014 · Tham số quan sát ngoài miền bị từ chối <!--k:settings-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-008, 061 · API-13-071 · ERR-13-040, 007 · BR-13-020
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. `PATCH /settings` đặt `13.probe.interval-seconds = 5` rồi `13.audit.worm-retention-years = 2`.
  2. `PATCH` lại với `If-Match` cũ.
- **Mong đợi** Cả hai lần đầu `422` ERR-13-040 (thời hạn lưu dưới 3 năm); lần ba `412` ERR-13-007; không có thay đổi nào được lưu.

#### TC-13-015 · Truy vấn quan sát không thấy dữ liệu tenant khác <!--k:obs-tenant-isolation-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-009 · BR-13-030 · NFR-13-022 · ERR-13-036 · API-13-019
- **Tiền điều kiện / dữ liệu** T01 và T68 đều có log `luong-chung`; U-T68-TO, U-T01-TO.
- **Bước**
  1. U-T68-TO tra log `luong-chung`; gửi thêm `targetTenant=t01`.
  2. Truy vấn Loki, Mimir, Tempo trực tiếp bằng chứng thư của T68 với nhãn `t01`.
- **Mong đợi** Bước 1: chỉ log T68; có `targetTenant` thì `403` ERR-13-036. Bước 2: 0 kết quả ở cả ba kho.

### TS-13-05 · Tiếp nhận và chuỗi băm theo tenant

**Mục tiêu.** Xác nhận bản ghi từ DU được xác thực, ghi chỉ-thêm và nối chuỗi băm liên tục theo từng tenant; bản ghi sai bị cách ly, trùng bị bỏ.

**Phủ.** FR-13-010, 011; UC-13-05; BR-13-001, 002, 004, 017, 019; ERR-13-101, 102, 103, 104, 106, 126; API-13-087; UI-13-18; NFR-13-008, 025.

#### TC-13-016 · Ghi một bản ghi hợp lệ, nối băm và gán `seq` <!--k:ingest-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-010, 011 · UC-13-05 · BR-13-004 · NFR-13-008 · API-13-087 · UI-13-18
- **Tiền điều kiện / dữ liệu** S-DU; chuỗi T68 trống.
- **Bước**
  1. Gửi 1.000 bản ghi hợp lệ qua Kafka.
  2. `GET /chain-status`; đọc 1.000 bản ghi theo `seq`.
- **Mong đợi** `seq` 1…1.000 liên tục; `hash = SHA-256(prev_hash ‖ canonical_json)` đúng với mọi bản ghi; offset Kafka chỉ xác nhận sau khi cam kết; độ trễ p95 ≤ 2 giây.

#### TC-13-017 · Bản ghi thiếu trường, trùng `id`, sai tenant, DU không được phép <!--k:ingest-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-010, 011 · ERR-13-101, 102, 103, 104 · BR-13-001, 017
- **Tiền điều kiện / dữ liệu** F-DU-SIM phát sai.
- **Bước**
  1. Gửi bản ghi thiếu `action`.
  2. Gửi lại một `id` đã có.
  3. Gửi bản ghi `tenant_id = t01` vào topic của T68.
  4. DU chưa đăng ký ghi cho T68 gửi bản ghi hợp lệ.
- **Mong đợi** Bước 1: ERR-13-101 cách ly. Bước 2: ERR-13-102 bỏ qua, chuỗi không đổi. Bước 3: ERR-13-104. Bước 4: ERR-13-103. Mỗi lần có cảnh báo `WARNING` cho DU nguồn; chuỗi T68 không có `seq` nào thừa.

#### TC-13-018 · Đồng hồ DU lệch về tương lai quá 2 giây <!--k:ingest-clock-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-010 · ERR-13-126 · BR-13-001
- **Tiền điều kiện / dữ liệu** F-DU-SIM đặt `occurred_at` lệch +3 giây.
- **Bước**
  1. Gửi bản ghi lệch +1 giây, rồi +3 giây.
- **Mong đợi** +1 giây: ghi bình thường. +3 giây: ghi được kèm cờ, ERR-13-126 cảnh báo `WARNING` cho DU; `recorded_at` do PH-13 gán, quyết định phân vùng.

#### TC-13-019 · Ghi đồng thời nhiều DU vào cùng chuỗi không hở `seq` <!--k:ingest-concurrent-->
- **Loại** Biên · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-011 · BR-13-017 · NFR-13-008 · ERR-13-106
- **Tiền điều kiện / dữ liệu** Ba DU giả, mỗi DU 1.000 bản ghi cùng lúc; sau đó chặn ghi bảng 30 giây.
- **Bước**
  1. Phát đồng thời 3.000 bản ghi.
  2. Chặn quyền ghi bảng kiểm toán 30 giây khi đang phát.
- **Mong đợi** Bước 1: 3.000 `seq` liên tục, không trùng, chuỗi băm đúng. Bước 2: ERR-13-106; offset Kafka không tiến; khi hết chặn không mất, không trùng bản ghi.

### TS-13-06 · Neo băm ký hằng giờ và sao lô sang WORM

**Mục tiêu.** Xác nhận neo băm được ký bằng khóa OpenBao, lưu ở ba nơi độc lập, và bản ghi được sao lô sang kho WORM không xóa được.

**Phủ.** FR-13-012, 013; UC-13-06; BR-13-013, 020; API-13-080, 081, 087; UI-13-14, 18; ERR-13-107, 108; EVT-13-06; NFR-13-023, 027.

#### TC-13-020 · Neo giờ chẵn được ký, lưu bảng, WORM và SIEM <!--k:anchor-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-012 · UC-13-06 · BR-13-013 · API-13-080, 081 · UI-13-14 · EVT-13-06
- **Tiền điều kiện / dữ liệu** F-AUD-1K; F-SIM-SIEM bật; `13.audit.anchor-interval-minutes = 60`.
- **Bước**
  1. Chờ đến giờ chẵn (hoặc kích bộ neo ở SIT).
  2. `GET /anchors`, `GET /anchors/{anchorId}`; kiểm chữ ký bằng khóa công khai.
- **Mong đợi** Neo có `seq` cuối, băm, chữ ký hợp lệ; có bản ở bảng neo, bucket WORM và SIEM; EVT: `audit.anchor-created`.

#### TC-13-021 · Không ký được neo tại OpenBao <!--k:anchor-sign-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-13-012 · ERR-13-107 · BR-13-013 · NFR-13-023
- **Tiền điều kiện / dữ liệu** Tắt OpenBao 90 phút.
- **Bước**
  1. Tắt OpenBao; chờ qua một giờ chẵn; bật lại.
- **Mong đợi** ERR-13-107, cảnh báo `WARNING`; bản ghi vẫn vào chuỗi; sau khi bật lại neo bù được ký, không bỏ sót giờ nào; không khóa nào rời OpenBao.

#### TC-13-022 · Sao lô sang WORM và không xóa được <!--k:worm-copy-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-013 · BR-13-013, 020 · API-13-087 · UI-13-18 · NFR-13-023
- **Tiền điều kiện / dữ liệu** F-AUD-1K; F-WORM.
- **Bước**
  1. Chờ 5 phút (`13.audit.worm-batch-minutes`) hoặc kích bộ sao.
  2. Dùng tài khoản ghi của bộ sao xóa đối tượng, rút ngắn thời hạn Object Lock.
- **Mong đợi** Bước 1: lô có tổng kiểm đúng; `GET /chain-status` hiện lô mới nhất. Bước 2: bị từ chối; Object Lock chỉ cho kéo dài.

#### TC-13-023 · Kho WORM ngừng, lô xếp hàng và sao bù <!--k:worm-down-->
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-13-013, 016 · ERR-13-108 · NFR-13-011 · UI-13-18
- **Tiền điều kiện / dữ liệu** Tắt F-WORM 30 phút.
- **Bước**
  1. Tắt WORM; ghi 500 bản ghi; bật lại.
- **Mong đợi** ERR-13-108 `WARNING`; chuỗi vẫn ghi; sau khi bật lại tất cả lô được sao đủ, đối chiếu khớp; UI-13-18 hiện độ trễ sao.

### TS-13-07 · Kiểm tra toàn vẹn chuỗi

**Mục tiêu.** Xác nhận kiểm tra toàn vẹn hằng ngày, gia tăng khi neo và theo yêu cầu cho kết quả đúng, chỉ đọc, có lý do.

**Phủ.** FR-13-014; UC-13-07; API-13-077, 078, 079; UI-13-14; EVT-13-07; BR-13-006, 033; ERR-13-008, 028, 032; NFR-13-010, 016.

#### TC-13-024 · Kiểm tra toàn vẹn theo yêu cầu trên chuỗi nguyên vẹn <!--k:verify-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-014 · UC-13-07 · API-13-077, 078, 079 · UI-13-14 · EVT-13-07 · BR-13-006
- **Tiền điều kiện / dữ liệu** F-AUD-1K; U-T68-AU đã xác thực lại phiên.
- **Bước**
  1. `POST /verifications` kèm `reason` (12 ký tự) và `Idempotency-Key`.
  2. Hỏi `GET /verifications/{id}` đến khi xong.
- **Mong đợi** `202`; kết quả `PASSED`, số bản ghi 1.000, neo cuối khớp; EVT: `verification-completed`; KT: có (`AUDIT.VERIFY`) với `reason`.

#### TC-13-025 · Yêu cầu kiểm tra thiếu lý do, thiếu xác thực lại, đang chạy <!--k:verify-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-014 · API-13-077 · ERR-13-008, 028, 032, 009
- **Tiền điều kiện / dữ liệu** U-T68-AU; U-T68-TO.
- **Bước**
  1. `POST /verifications` không có `reason`.
  2. Gọi khi phiên chưa xác thực lại.
  3. Gọi hai lần liên tiếp khi lần một còn chạy.
  4. U-T68-TO gọi.
- **Mong đợi** Bước 1 `400` ERR-13-008; bước 2 `403` ERR-13-028; bước 3 `409` ERR-13-032; bước 4 403-PQ. Không phát sinh lượt kiểm tra nào ngoài lượt đầu.

#### TC-13-026 · Kiểm tra gia tăng khi neo và kiểm tra hằng ngày <!--k:verify-schedule-->
- **Loại** Dương, Biên · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-014 · NFR-13-010, 016 · BR-13-033
- **Tiền điều kiện / dữ liệu** F-AUD-1K; `13.audit.verify-cron = 0 3 * * *`.
- **Bước**
  1. Kích kiểm tra hằng ngày ở SIT; đo thời gian.
  2. Kiểm tra API không có đường sửa, nối lại chuỗi.
- **Mong đợi** Từ neo gần nhất tới đầu chuỗi ≤ 2 phút; không có endpoint sửa hay dựng lại chuỗi (BR-13-033); lượt kiểm tra gia tăng nối với mỗi neo mới.

### TS-13-08 · Xử lý đứt chuỗi và neo không khớp

**Mục tiêu.** Xác nhận mọi can thiệp vào bản ghi đã neo bị phát hiện, báo ngay mức Nghiêm trọng, và hệ thống không tự sửa.

**Phủ.** FR-13-015; UC-13-08; BR-13-012, 033; ERR-13-109, 110; EVT-13-05; API-13-079; UI-13-14, 18; NFR-13-016.

#### TC-13-027 · Sửa trực tiếp một bản ghi đã neo bị phát hiện <!--k:chain-tamper-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-014, 015 · UC-13-08 · BR-13-012, 033 · ERR-13-109 · EVT-13-05 · API-13-079 · UI-13-14 · NFR-13-016
- **Tiền điều kiện / dữ liệu** F-AUD-CUT; U-T68-SO, U-T68-TA nhận thông báo.
- **Bước**
  1. Chạy kiểm tra gia tăng khi neo.
  2. `GET /verifications/{id}`; mở UI-13-14.
- **Mong đợi** Kết quả `BROKEN` nêu `seq` đầu tiên sai; ≤ 1 giờ phát hiện; ERR-13-109; cảnh báo Nghiêm trọng gửi SO và TA ngay; EVT: `audit.chain-broken`; không có nút sửa; chuỗi giữ nguyên.

#### TC-13-028 · Neo không khớp bản WORM hoặc SIEM <!--k:anchor-mismatch-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-015 · UC-13-08 · ERR-13-110 · BR-13-012, 013 · EVT-13-05
- **Tiền điều kiện / dữ liệu** F-AUD-1K; sửa bản neo ở bảng neo (tài khoản DBA thử).
- **Bước**
  1. Chạy kiểm tra toàn vẹn.
- **Mong đợi** So ba nơi thấy lệch; ERR-13-110 Nghiêm trọng; nêu nơi nào lệch; EVT: `chain-broken`; không tự ghi đè.

#### TC-13-029 · Chuỗi nguyên vẹn không sinh cảnh báo giả <!--k:chain-no-false-alarm-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-015 · UC-13-08 · BR-13-012 · ERR-13-109
- **Tiền điều kiện / dữ liệu** F-AUD-1K, qua 7 ngày kiểm tra hằng ngày.
- **Bước**
  1. Chạy kiểm tra liên tiếp 7 lần với ghi liên tục.
- **Mong đợi** 7 lần `PASSED`; 0 cảnh báo đứt chuỗi; 0 EVT `chain-broken`.

#### TC-13-127 · Khôi phục chuỗi sau sự cố: nạp lại nguyên văn từ WORM, xác minh đạt, biên bản ký <!--k:restore-ok-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P2 · **Tự động** Thủ công, IT
- **Truy vết** FR-13-062 · UC-13-43 · BR-13-002, 033 · FR-13-011, 012, 013, 014 · ERR-13-109
- **Tiền điều kiện / dữ liệu** F-AUD-LAG (chuỗi T68 khôi phục PITR về trước 4 phút so với lô WORM mới nhất, WORM đủ bản ghi); `ingest` chưa mở; U-OPS chạy `AuditRestore`; U-T68-SO, U-T68-TA đã ký biên bản mở và cửa sổ bảo trì.
- **Bước**
  1. So `head_seq`, `head_hash` của T68 với lô WORM mới nhất và neo gần nhất.
  2. Chạy `AuditRestore`; sau đó mở lại `ingest` và để DU giả lập gửi lại bản ghi chưa lên WORM (có bản trùng `id`).
  3. Chạy xác minh `ON_DEMAND` toàn chuỗi; đọc chuỗi `PLATFORM`.
  4. SO và TA ký biên bản; U-OPS lưu ở `dh-evidence`.
  5. Tìm API, màn hình hay quyền `PERM-13-*` cho thao tác khôi phục.
- **Mong đợi** Bước 1: bảng đứng sau WORM khoảng 4 phút. Bước 2: bản ghi được chèn nguyên văn (giữ `seq`, `recorded_at`, `prev_hash`, `hash`) theo thứ tự, không bản ghi nào bị sửa hay dựng mới; bản trùng `id` bị bỏ qua (ERR-13-102), bản còn lại nhận `seq` nối tiếp. Bước 3: kết quả `PASSED` toàn chuỗi; có `AUDIT.CHAIN.RESTORE` (lý do, số tenant, khoảng `seq` nạp lại) ở chuỗi `PLATFORM` và ở SIEM. Bước 4: biên bản có chữ ký của cả SO và TA, lưu ở `dh-evidence`. Bước 5: không có API, màn hình hay quyền nào cho thao tác này (không đường nào sửa, nối lại hay dựng lại chuỗi). KT: có.

#### TC-13-128 · Khôi phục chuỗi: bảng không đứng sau WORM, và nhiều tenant mất dữ liệu <!--k:restore-alt-->
- **Loại** Dương, Biên · **Ưu tiên** P3 · **Tự động** Thủ công, IT
- **Truy vết** FR-13-062 · UC-13-43 · BR-13-033
- **Tiền điều kiện / dữ liệu** Hai tình huống: (a) F-AUD-1K của T68 còn nguyên so với WORM; (b) T68, T01 cùng mất dữ liệu (F-AUD-LAG cho cả hai); chữ ký SO và TA đủ.
- **Bước**
  1. Tình huống (a): chạy thủ tục.
  2. Tình huống (b): chạy lần lượt T68 rồi T01; theo dõi thời điểm mở `ingest` của từng tenant.
- **Mong đợi** Tình huống (a): bỏ bước nạp lại, không chèn bản ghi nào, chỉ xác minh `PASSED` và lập biên bản. Tình huống (b): mỗi tenant được xác minh đạt rồi mới mở `ingest` cho tenant đó; `AUDIT.CHAIN.RESTORE` ghi số tenant và khoảng `seq` của từng tenant.

#### TC-13-129 · Khôi phục chuỗi: băm WORM không khớp neo hoặc trigger từ chối thì dừng <!--k:restore-neg-hash-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-062 · UC-13-43 · BR-13-002, 033 · FR-13-015 · ERR-13-109, 110
- **Tiền điều kiện / dữ liệu** F-AUD-LAG; một lô WORM thử bị đổi một bản ghi (băm không khớp neo); biến thể khác: bản ghi cần chèn không liền kề (thiếu một `seq`); biên bản đã ký.
- **Bước**
  1. Chạy `AuditRestore` với lô bị đổi.
  2. Chạy với lô thiếu một `seq` giữa chừng.
  3. Thử chèn thủ công một bản ghi bằng tài khoản DBA thử để vượt `tg_audit_chain_guard`.
- **Mong đợi** Bước 1: dừng ngay, không chèn thêm bản ghi nào; xử lý như đứt chuỗi theo FR-13-015: ERR-13-109 hoặc ERR-13-110 mức Nghiêm trọng, cảnh báo SO và TA, EVT `audit.chain-broken`. Bước 2: `tg_audit_chain_guard` từ chối bản ghi không liền kề, thủ tục dừng. Bước 3: bị từ chối, không có đường vượt qua trigger; chuỗi giữ nguyên.

#### TC-13-130 · Khôi phục chuỗi: thiếu chữ ký SO hoặc TA thì không chạy <!--k:restore-neg-sign-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P2 · **Tự động** Thủ công
- **Truy vết** FR-13-062 · UC-13-43 · BR-13-033
- **Tiền điều kiện / dữ liệu** F-AUD-LAG; biên bản mở và cửa sổ bảo trì: biến thể 1 chỉ SO ký, biến thể 2 chỉ TA ký, biến thể 3 chưa ai ký.
- **Bước**
  1. U-OPS yêu cầu mở cửa sổ bảo trì và chạy `AuditRestore` với từng biến thể.
- **Mong đợi** Cả ba biến thể: không mở cửa sổ bảo trì, không chạy `AuditRestore`, `ingest` vẫn đóng, chuỗi không đổi; yêu cầu bị ghi nhận có lý do. Chỉ khi cả SO và TA cùng ký mới chạy được.

#### TC-13-131 · Khôi phục chuỗi: xác minh toàn chuỗi không đạt sau khi nạp <!--k:restore-neg-verify-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-062 · UC-13-43 · FR-13-014, 015 · ERR-13-109
- **Tiền điều kiện / dữ liệu** F-AUD-LAG; một bản ghi trong khoảng đã nạp có băm sai mà vẫn liền kề (dựng bằng DBA thử ở SIT); biên bản đã ký.
- **Bước**
  1. Chạy `AuditRestore`, rồi xác minh `ON_DEMAND` toàn chuỗi.
- **Mong đợi** Xác minh `BROKEN`, nêu `seq` đầu tiên sai; chuỗi giữ trạng thái đứt, không mở `ingest` cho tenant, mở sự cố theo FR-13-015 (ERR-13-109); không ghi `AUDIT.CHAIN.RESTORE` loại thành công.

### TS-13-09 · Chịu lỗi, đệm bản ghi và đối chiếu số lượng

**Mục tiêu.** Xác nhận không mất bản ghi kiểm toán khi PH-13 hay kho ngừng, DU từ chối thao tác nhạy cảm khi không ghi vết được, và bộ đếm của DU khớp số nhận.

**Phủ.** FR-13-016, 017; UC-13-09; BR-13-001, 003, 004; NFR-13-011, 026; API-13-086, 089; ERR-13-043, 111; EVT-13-09.

#### TC-13-030 · PH-13 ngừng 4 giờ, 0 bản ghi mất <!--k:outbox-4h-->
- **Loại** Dương, Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-13-016 · BR-13-004 · NFR-13-011 · API-13-089 · UC-13-09
- **Tiền điều kiện / dữ liệu** F-DU-SIM phát 10 bản ghi/giây; ngừng toàn bộ pod PH-13 4 giờ (rút gọn 30 phút ở SIT, 4 giờ ở đợt phát hành).
- **Bước**
  1. Ngừng PH-13; DU tiếp tục thao tác; bật lại.
- **Mong đợi** Bản ghi chờ ở hộp thư đi và Kafka; sau khi bật lại vào đủ theo thứ tự, không trùng (idempotent theo `id`); số mất = 0; `POST /internal/records:batch` nhận được lô dự phòng, trả `202`.

#### TC-13-031 · Không ghi vết được ở nguồn thì từ chối thao tác dữ liệu Nhạy cảm <!--k:fail-closed-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-016 · BR-13-003 · BR-13-001 · NFR-13-014
- **Tiền điều kiện / dữ liệu** F-DU-SIM; chặn Kafka `acks=all` và hộp thư đi đầy.
- **Bước**
  1. DU thử thực hiện thao tác thường và thao tác xem giá trị Nhạy cảm.
- **Mong đợi** Thao tác Nhạy cảm bị từ chối, không có thay đổi dữ liệu; thao tác thường không bị chặn chỉ vì PH-13 ngừng (BR-13-003).

#### TC-13-032 · Đối chiếu số bản ghi khớp bộ đếm của DU <!--k:reconcile-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-017 · BR-13-001 · NFR-13-026 · API-13-086 · UI-13-18
- **Tiền điều kiện / dữ liệu** F-DU-SIM phát 5.000 bản ghi, bộ đếm 5.000.
- **Bước**
  1. Chạy đối chiếu; `GET /reconciliations`.
- **Mong đợi** Chênh lệch 0 cho mọi DU.

#### TC-13-033 · Đối chiếu lệch phát cảnh báo <!--k:reconcile-mismatch-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-017 · ERR-13-111 · EVT-13-09 · API-13-086 · BR-13-001
- **Tiền điều kiện / dữ liệu** F-DU-SIM bỏ 3 bản ghi khỏi Kafka nhưng đếm.
- **Bước**
  1. Chạy đối chiếu.
- **Mong đợi** Lệch 3; ERR-13-111; EVT: `reconciliation-mismatch` nêu `duCode`; UI-13-14 hiện.

#### TC-13-034 · Ghi vào chuỗi tenant đã đóng <!--k:ingest-closed-chain-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-016, 060 · ERR-13-043 · API-13-089
- **Tiền điều kiện / dữ liệu** Chuỗi T91 đã đóng.
- **Bước**
  1. `POST /internal/records:batch` bản ghi cho T91.
- **Mong đợi** `409` ERR-13-043; không có bản ghi nào vào chuỗi.

### TS-13-10 · Lưu giữ, lưu trữ phân vùng và tự kiểm toán của PH-13

**Mục tiêu.** Xác nhận phân vùng quá 12 tháng chỉ lưu trữ khi WORM đã xác minh đủ, và mọi thao tác trên PH-13 đều có bản ghi kiểm toán.

**Phủ.** FR-13-018, 019; UC-13-10, 11; BR-13-002, 006, 020; API-13-088; UI-13-18; EVT-13-11; ERR-13-125; NFR-13-019, 025; LGC-NFR-005.

#### TC-13-035 · Phân vùng tháng thứ 13 chuyển `ARCHIVED` sau khi WORM xác minh đủ <!--k:partition-archive-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-018 · UC-13-10 · BR-13-002, 020 · API-13-088 · UI-13-18 · EVT-13-11 · LGC-NFR-005
- **Tiền điều kiện / dữ liệu** F-AUD-12M.
- **Bước**
  1. Chạy bộ quản lý phân vùng; `GET /partitions`.
- **Mong đợi** Phân vùng cũ `SEALED` → `ARCHIVED` chỉ sau khi tổng kiểm WORM khớp; EVT: `partition-archived`; phân vùng trong 12 tháng không bị động tới.

#### TC-13-036 · Chưa xác minh được WORM thì giữ phân vùng và báo <!--k:partition-hold-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-018 · UC-13-10 · ERR-13-125 · BR-13-002 · API-13-088 · UI-13-18
- **Tiền điều kiện / dữ liệu** F-AUD-12M; xóa lô WORM của một ngày ở bản sao thử.
- **Bước**
  1. Chạy bộ quản lý phân vùng.
- **Mong đợi** Phân vùng giữ `SEALED`; ERR-13-125 `WARNING`; không có bản ghi nào bị xóa khỏi bảng.

#### TC-13-037 · Mọi thao tác trên PH-13 để lại bản ghi kiểm toán <!--k:self-audit-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-019 · UC-13-11 · BR-13-006 · NFR-13-025
- **Tiền điều kiện / dữ liệu** U-T68-TA, U-T68-SO, U-T68-AU.
- **Bước**
  1. Thực hiện: tra kiểm toán, xem chi tiết, kiểm tra toàn vẹn, xuất bằng chứng, tải, xem liên tenant, sửa luật, đổi ngưỡng, tạm ẩn, đổi tham số, đổi SIEM.
  2. Tra chuỗi T68 theo `source_du = dh-platform` trong khoảng thời gian.
- **Mong đợi** Đúng một bản ghi cho mỗi thao tác (100 %), có `actor`, `action`, `reason` (nếu bắt buộc), `trace_id`; không chứa giá trị Nhạy cảm.


#### TC-13-122 · Thao tác bị từ chối hoặc thất bại vẫn có bản ghi kiểm toán <!--k:self-audit-denied-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-019 · UC-13-11 · BR-13-006 · NFR-13-025 · ERR-13-009 · ERR-13-012
- **Tiền điều kiện / dữ liệu** U-T68-TO (không quyền kiểm toán); U-T68-AU.
- **Bước**
  1. U-T68-TO gọi `POST /records:search`.
  2. U-T68-AU tra kiểm toán thiếu lý do.
  3. Tra chuỗi T68 theo `action = AUDIT.QUERY`.
- **Mong đợi** Hai bản ghi với `outcome = DENIED` và `FAILED`, có `actor`, `error_code` (ERR-13-009, ERR-13-012); không chứa nội dung truy vấn nhạy cảm.

### TS-13-11 · Tra cứu nhật ký kiểm toán

**Mục tiêu.** Xác nhận tra cứu kiểm toán bắt buộc lý do, giới hạn khoảng và phạm vi, xác thực lại phiên, và chính lượt tra cứu bị ghi vết; thay "Audit" của APIM.

**Phủ.** FR-13-020, 021, 023; UC-13-12, 14; API-13-074, 075; UI-13-13; BR-13-005, 006, 007, 029; ERR-13-004, 005, 011, 012, 013, 015, 028, 029, 031; NFR-13-009; LGC-APIM-027.

#### TC-13-038 · Tra cứu theo người, hành động, khoảng thời gian kèm lý do <!--k:audit-search-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-13-020, 021 · UC-13-12 · API-13-074, 075 · UI-13-13 · BR-13-006, 007 · LGC-APIM-027
- **Tiền điều kiện / dữ liệu** F-AUD-1K; U-T68-AU đã xác thực lại phiên.
- **Bước**
  1. Mở UI-13-13, lọc `action = CATALOG.PUBLISH`, 24 giờ, nhập lý do 20 ký tự.
  2. Mở một bản ghi; bấm "Xác minh băm".
- **Mong đợi** `POST /records:search` `200`, phân trang con trỏ, có `totalEstimate`; chi tiết hiện `before`, `after` đã che; băm khớp neo gần nhất; KT: có (`AUDIT.QUERY`, `AUDIT.VIEW`) kèm `reason`.

#### TC-13-039 · Tra cứu thiếu lý do, quá khoảng, quá rộng, sai định dạng <!--k:audit-search-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-020, 021 · API-13-074, 075 · ERR-13-012, 004, 005, 013, 029, 031, 028, 015
- **Tiền điều kiện / dữ liệu** F-AUD-1K; U-T68-AU.
- **Bước**
  1. Không `reason`; không `from`; khoảng 32 ngày; khoảng 13 tháng trước; số định danh sai định dạng; phạm vi trả về hơn 1 triệu bản ghi; phiên chưa xác thực lại; mở chi tiết `auditId` của T01 (404-ẩn).
- **Mong đợi** Lần lượt ERR-13-012; 004; 005 (`maxDays = 31`); 029; 031; 013 (kèm `recordCount`); 028. Mỗi lần thất bại vẫn có KT `AUDIT.QUERY` với `outcome = DENIED` hoặc `FAILED`.

#### TC-13-040 · Tra theo đối tượng bị tra cứu, số định danh chỉ lưu HMAC <!--k:audit-by-subject-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-023 · UC-13-14 · BR-13-005, 007 · API-13-074 · UI-13-13
- **Tiền điều kiện / dữ liệu** F-AUD-PII có `object_key_hmac`; U-T68-SO nhập số định danh giả và căn cứ.
- **Bước**
  1. Tra theo số định danh `DH-CANARY-subject`, kèm căn cứ.
  2. Tìm số này trong log ứng dụng, bảng `ph13.*`, bản ghi kiểm toán.
- **Mong đợi** Kết quả đúng đối tượng; số định danh người tra nhập không được lưu, ghi log hay trả lại; bản ghi `AUDIT.QUERY` chỉ có HMAC và căn cứ; mồi sạch.

#### TC-13-041 · Giới hạn đồng thời và thời gian chờ của truy vấn <!--k:audit-query-limits-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-020 · ERR-13-011, 015 · NFR-13-009 · BR-13-029
- **Tiền điều kiện / dữ liệu** U-T68-AU; truy vấn nặng giả lập.
- **Bước**
  1. Chạy 6 truy vấn đồng thời.
  2. Chạy truy vấn nặng quá 30 giây.
- **Mong đợi** Truy vấn thứ 6 `429` ERR-13-011 có `retryAfterSeconds`; truy vấn quá hạn `504` ERR-13-015; truy vấn thường p95 ≤ 3 giây (10.000 kết quả, 31 ngày).

### TS-13-12 · Lịch sử theo đối tượng cho tab "Lịch sử"

**Mục tiêu.** Xác nhận DU chủ đối tượng lấy được lịch sử thay đổi của đối tượng qua scope hẹp, chỉ trong tenant.

**Phủ.** FR-13-022; UC-13-13; API-13-076; UI-13-13; ERR-13-044, 001, 036; BR-13-017.

#### TC-13-042 · Lấy lịch sử của một đối tượng <!--k:history-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-022 · UC-13-13 · API-13-076 · UI-13-13
- **Tiền điều kiện / dữ liệu** F-AUD-1K có 12 bản ghi cho `object = CATALOG/DM_GIOI_TINH`; S-HIST.
- **Bước**
  1. `GET /objects/CATALOG/DM_GIOI_TINH/history`.
- **Mong đợi** `200`, 12 mục theo thời gian giảm dần, đã che; không có bản ghi của đối tượng cùng mã ở T01.

#### TC-13-043 · Scope thiếu hoặc đối tượng tenant khác <!--k:history-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-022 · API-13-076 · ERR-13-044, 001, 036 · BR-13-017
- **Tiền điều kiện / dữ liệu** Token máy không có `audit:history-read`; S-HIST của T01 gọi đối tượng T68.
- **Bước**
  1. Gọi bằng token thiếu scope.
  2. S-HIST của T01 gọi lịch sử đối tượng của T68.
- **Mong đợi** Bước 1 `403` ERR-13-044 (không nêu scope thiếu); bước 2 404-ẩn hoặc `403` ERR-13-036, không rò số bản ghi.

### TS-13-13 · Xuất bằng chứng kiểm toán ký số

**Mục tiêu.** Xác nhận gói bằng chứng bắt buộc ký số, kèm script xác minh ngoại tuyến, liên kết tải hết hạn, và mọi bước bị ghi vết.

**Phủ.** FR-13-024; UC-13-15; API-13-082, 083, 084; UI-13-14; EVT-13-08; BR-13-014, 017, 029; ERR-13-025, 026, 027, 008, 012, 013, 028; NFR-13-031.

#### TC-13-044 · Xuất gói bằng chứng, tải và tự xác minh ngoại tuyến <!--k:export-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-13-024 · UC-13-15 · API-13-082, 083, 084 · UI-13-14 · EVT-13-08 · BR-13-014 · NFR-13-031
- **Tiền điều kiện / dữ liệu** F-AUD-1K; U-T68-AU xác thực lại, nhập lý do và căn cứ.
- **Bước**
  1. `POST /exports` phạm vi 24 giờ; hỏi `GET /exports/{id}`.
  2. Tải `GET /exports/{id}/download`; chạy script xác minh đi kèm không có mạng.
- **Mong đợi** `202` → `READY`; EVT: `export-ready`; gói có bản ghi, chuỗi băm, neo, chữ ký; script báo hợp lệ; sửa một byte thì báo hỏng; KT: có (`AUDIT.EXPORT`, `AUDIT.DOWNLOAD`).

#### TC-13-045 · Không ký được thì không xuất, không để lại tệp <!--k:export-sign-fail-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-024 · BR-13-014 · ERR-13-026 · ERR-13-014
- **Tiền điều kiện / dữ liệu** Tắt OpenBao khi gói đã dựng.
- **Bước**
  1. Yêu cầu tải gói khi OpenBao ngừng.
- **Mong đợi** `503` ERR-13-026; không có tệp chưa ký ở kho tạm hay bucket; khi OpenBao về, tải lại được.

#### TC-13-046 · Trùng yêu cầu, thiếu lý do, quá rộng, hết hạn tải <!--k:export-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-024 · API-13-082, 084 · ERR-13-025, 008, 012, 013, 027, 028, 009 · BR-13-029
- **Tiền điều kiện / dữ liệu** U-T68-AU; U-T68-TA; `13.export.link-ttl-minutes = 15`.
- **Bước**
  1. Gửi hai yêu cầu cùng phạm vi.
  2. Không lý do; phạm vi trên 10 triệu bản ghi; phiên chưa xác thực lại.
  3. Tải sau 16 phút; U-T68-TA yêu cầu.
- **Mong đợi** Lần hai `409` ERR-13-025; ERR-13-008 hoặc 012; ERR-13-013; ERR-13-028; tải quá hạn `410` ERR-13-027; TA bị 403-PQ.

### TS-13-14 · Báo cáo truy cập liên tenant

**Mục tiêu.** Xác nhận truy cập liên tenant luôn qua phiên có lý do, hết hạn 60 phút, ghi ở cả hai chuỗi và tenant bị truy cập được báo.

**Phủ.** FR-13-025; UC-13-16; API-13-085; UI-13-16; BR-13-017, 018; EVT-13-12; ERR-13-036.

#### TC-13-047 · Mở phiên liên tenant, ghi hai chuỗi, thông báo tenant bị truy cập <!--k:xtenant-ok-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-025 · UC-13-16 · API-13-085 · UI-13-16 · BR-13-018 · EVT-13-12
- **Tiền điều kiện / dữ liệu** U-PO mở phiên liên tenant vào T68 kèm lý do; U-T68-AU.
- **Bước**
  1. U-PO mở phiên, xem bảng điều khiển T68.
  2. U-T68-AU mở UI-13-16, `GET /cross-tenant-access`.
- **Mong đợi** Báo cáo có phiên của U-PO, lý do, thời hạn 60 phút; bản ghi ở chuỗi PLATFORM và chuỗi T68; EVT: `cross-tenant-access` vào T68; hết 60 phút phiên tự đóng.

#### TC-13-048 · Truy cập tenant khác không có phiên <!--k:xtenant-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-025 · ERR-13-036 · BR-13-018, 030 · API-13-085
- **Tiền điều kiện / dữ liệu** U-PO không có phiên; U-T01-AU.
- **Bước**
  1. U-PO gọi `GET /alerts?targetTenant=t68`.
  2. U-T01-AU gọi `GET /cross-tenant-access` của T68.
- **Mong đợi** Bước 1 `403` ERR-13-036 (không nêu tên tenant đích); bước 2 chỉ thấy báo cáo của T01.

### TS-13-15 · Tra log tập trung

**Mục tiêu.** Xác nhận tra log theo điều kiện, ngữ cảnh, theo dõi trực tiếp; thay "quản trị log agent"; giới hạn đồng thời, khoảng, cú pháp.

**Phủ.** FR-13-026, 027; UC-13-17; API-13-019, 020, 021, 027, 028, 029; UI-13-07; ERR-13-004, 005, 006, 011, 015, 037, 002; NFR-13-005; LGC-BUS-029.

#### TC-13-049 · Tra log theo luồng, mức, thời gian, lưu truy vấn <!--k:logs-search-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-13-026 · UC-13-17 · API-13-019, 027, 028, 029 · UI-13-07 · NFR-13-005 · LGC-BUS-029
- **Tiền điều kiện / dữ liệu** F-DU-SIM; U-T68-IE.
- **Bước**
  1. Mở UI-13-07, lọc `level=ERROR`, luồng `luong-chung`, 1 giờ.
  2. Lưu truy vấn; tải danh sách; xóa.
- **Mong đợi** Kết quả p95 ≤ 5 giây; `POST /saved-queries` `201`; xóa `204`; KT: có khi đổi truy vấn dùng chung.

#### TC-13-050 · Log sai cú pháp, quá khoảng, trùng truy vấn lưu <!--k:logs-search-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-026 · API-13-019, 028 · ERR-13-006, 004, 005, 011, 002, 037
- **Tiền điều kiện / dữ liệu** U-T68-IE.
- **Bước**
  1. Truy vấn thiếu dấu đóng ngoặc.
  2. `from ≥ to`; khoảng 8 ngày.
  3. Lưu truy vấn trùng tên; gửi lại `Idempotency-Key` khác nội dung.
- **Mong đợi** ERR-13-006 kèm vị trí ký tự; ERR-13-004; ERR-13-005 (`maxDays = 7`); ERR-13-002; ERR-13-037.

#### TC-13-051 · Ngữ cảnh quanh dòng log và theo dõi trực tiếp tự tắt <!--k:logs-tail-->
- **Loại** Dương, Biên · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-13-027 · API-13-020, 021 · UI-13-07 · ERR-13-015
- **Tiền điều kiện / dữ liệu** F-DU-SIM phát log liên tục; `13.live-tail.idle-minutes = 15`.
- **Bước**
  1. Mở ngữ cảnh một dòng log; mở `GET /logs:tail`.
  2. Không thao tác 15 phút.
- **Mong đợi** Ngữ cảnh gồm 50 dòng trước và sau; SSE nhận dòng mới ≤ 30 giây; tự đóng sau 15 phút.

### TS-13-16 · Truy vết và liên kết bằng `trace_id`

**Mục tiêu.** Xác nhận tìm trace, thác nước và liên kết chỉ số, trace, log, kiểm toán theo một `trace_id`; thay "logging quá trình routing".

**Phủ.** FR-13-028, 029; UC-13-18; API-13-022, 023, 024; UI-13-08; ERR-13-030, 006; NFR-13-005; LGC-BUS-038.

#### TC-13-052 · Biểu đồ thác nước và liên kết bốn nguồn <!--k:trace-correlate-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-028, 029 · UC-13-18 · API-13-022, 023, 024 · UI-13-08 · LGC-BUS-038 · NFR-13-005
- **Tiền điều kiện / dữ liệu** F-TRACE-MIX có một trace lỗi, có bản ghi kiểm toán cùng `trace_id`; U-T68-TO.
- **Bước**
  1. Tìm trace theo mã luồng và trạng thái lỗi.
  2. Mở trace; mở liên kết.
- **Mong đợi** Thác nước đủ span; `GET /correlations/{traceId}` trả log, chỉ số, bản ghi kiểm toán cùng `trace_id`; p95 ≤ 2 giây.

#### TC-13-053 · Trace không có ở cả ba nguồn <!--k:trace-404-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-028, 029 · ERR-13-030, 001 · API-13-023, 024
- **Tiền điều kiện / dữ liệu** `trace_id` ngẫu nhiên; trace của T01.
- **Bước**
  1. Gọi `GET /traces/{id}` với `trace_id` không có; với trace của T01.
- **Mong đợi** `404` ERR-13-030; trace của T01 có phản hồi giống hệt trừ `traceId` của yêu cầu.

### TS-13-17 · Nhật ký truy cập API

**Mục tiêu.** Xác nhận tra lượt gọi API theo khoảng 24 giờ và HTTT trong 3 giây; thay "log mọi request" của APIM; không lộ nội dung.

**Phủ.** FR-13-030; UC-13-19; API-13-025, 026; UI-13-09; NFR-13-006, 018; ERR-13-004, 005, 044; LGC-APIM-022; LGC-PAY-021.

#### TC-13-054 · Lọc lượt gọi theo HTTT, API, mã lỗi, xem chi tiết <!--k:access-search-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, k6
- **Truy vết** FR-13-030 · UC-13-19 · API-13-025, 026 · UI-13-09 · NFR-13-006 · LGC-APIM-022 · LGC-PAY-021
- **Tiền điều kiện / dữ liệu** F-ACCESS-5M; U-T68-TO.
- **Bước**
  1. Lọc 24 giờ, HTTT `HT-NDXP`, mã `5xx`.
  2. Mở một lượt gọi.
- **Mong đợi** p95 ≤ 3 giây; chi tiết có `trace_id` bấm sang UI-13-08; không thân, không `Authorization`.

#### TC-13-055 · Khoảng quá 31 ngày và lượt gọi tenant khác <!--k:access-search-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-030 · API-13-025, 026 · ERR-13-005, 004, 001 · BR-13-030
- **Tiền điều kiện / dữ liệu** U-T68-TO; recordId của T01.
- **Bước**
  1. Tra khoảng 32 ngày; không `from`.
  2. `GET /access-logs/{recordId}` của T01.
- **Mong đợi** ERR-13-005 (`maxDays = 31`); ERR-13-004; bước 2 404-ẩn.

### TS-13-18 · Bảng giám sát tổng quan và sức khỏe thành phần

**Mục tiêu.** Xác nhận bảng tổng quan nền tảng và API sức khỏe cho phân hệ khác; thay "tổng quan toàn hệ thống" và "dashboard hoạt động chung" của Bus, APIM.

**Phủ.** FR-13-031, 058; UC-13-20, 39; API-13-001, 002; UI-13-01; BR-13-016, 030; NFR-13-001, 004; LGC-BUS-014; LGC-APIM-026.

#### TC-13-056 · Tổng quan nền tảng hiện số liệu và trạng thái các thành phần <!--k:overview-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-031 · UC-13-20 · API-13-001, 002 · UI-13-01 · NFR-13-004 · LGC-BUS-014 · LGC-APIM-026
- **Tiền điều kiện / dữ liệu** SIT đủ thành phần; U-T68-VW.
- **Bước**
  1. Mở UI-13-01; `GET /overview`, `GET /components`.
- **Mong đợi** Tải ≤ 3 giây (12 panel, 50 người xem); số liệu tenant T68; U-T68-VW xem được; chỉ số thiếu dữ liệu hiển thị "Chưa có dữ liệu" không phải 0 (BR-13-016); trạng thái truyền đạt cả bằng chữ lẫn màu.

#### TC-13-057 · Người không quyền, sức khỏe cho phân hệ khác theo scope <!--k:overview-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-031, 058 · API-13-001, 002 · ERR-13-009, 010, 044 · BR-13-030
- **Tiền điều kiện / dữ liệu** U-T68-NONE; S-PH18; token máy không scope.
- **Bước**
  1. U-T68-NONE gọi `GET /overview`; gọi không token.
  2. S-PH18 gọi `GET /components`; token không scope gọi.
- **Mong đợi** 403-PQ; `401` ERR-13-010; S-PH18 `200`; thiếu scope `403` ERR-13-044.

### TS-13-19 · Data plane: đơn vị triển khai, luồng, route, endpoint

**Mục tiêu.** Xác nhận bảng điều khiển data plane thay histogram, chi tiết agent, route, endpoint của Bus; chỉ số đúng tenant.

**Phủ.** FR-13-032, 033, 034; UC-13-21; API-13-003, 004, 005, 006, 007, 008; UI-13-02; ERR-13-005; BR-13-016; LGC-BUS-007, 015, 016, 017, 019, 027.

#### TC-13-058 · Đơn vị triển khai, luồng, route và thống kê endpoint <!--k:dataplane-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-032, 033, 034 · UC-13-21 · API-13-003, 004, 005, 006, 007, 008 · UI-13-02 · LGC-BUS-007, 015, 016, 017, 019, 027
- **Tiền điều kiện / dữ liệu** F-DU-SIM; luồng `luong-chung` chạy 100 bản tin/phút; U-T68-TO.
- **Bước**
  1. Mở UI-13-02; xem histogram bản tin thành công và thất bại, đồ thị CPU, bộ nhớ của đơn vị triển khai.
  2. Bấm luồng, bấm route; mở thống kê endpoint 24 giờ.
- **Mong đợi** Số liệu khớp bộ phát; có thời gian trung bình, lỗi, bản tin gần nhất, API gọi nhiều nhất; chỉ luồng của T68.

#### TC-13-059 · Luồng không có dữ liệu, khoảng thống kê quá hạn <!--k:dataplane-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-032, 033, 034 · API-13-004, 006, 007, 008 · ERR-13-001, 005 · BR-13-016
- **Tiền điều kiện / dữ liệu** Luồng mới chưa chạy; luồng của T01.
- **Bước**
  1. Gọi `GET /deployments/khong-co`; gọi chỉ số luồng mới; luồng `luong-chung` của T01 qua token T68.
  2. Thống kê endpoint 32 ngày.
- **Mong đợi** Luồng mới trả `200` với "Chưa có dữ liệu"; luồng T01 404-ẩn; ERR-13-005 (`maxDays = 31`).

### TS-13-20 · Theo API và theo HTTT

**Mục tiêu.** Xác nhận chủ dịch vụ chỉ thấy chỉ số của API tổ chức mình.

**Phủ.** FR-13-035; UC-13-22; API-13-009, 010; UI-13-03; BR-13-030; ERR-13-001.

#### TC-13-060 · Chủ dịch vụ xem chỉ số API của tổ chức mình <!--k:api-stats-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-035 · UC-13-22 · API-13-009, 010 · UI-13-03
- **Tiền điều kiện / dữ liệu** F-ACCESS-5M; U-T68-SV thuộc `ORG-SO-TTTT`.
- **Bước**
  1. Mở UI-13-03; lọc theo API; mở HTTT.
- **Mong đợi** Chỉ API của tổ chức `ORG-SO-TTTT`; số lượt, tỷ lệ lỗi, độ trễ p95 khớp F-ACCESS-5M.

#### TC-13-061 · Chủ dịch vụ không xem được HTTT, API tổ chức khác <!--k:api-stats-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-035 · API-13-010 · ERR-13-001, 009 · BR-13-030
- **Tiền điều kiện / dữ liệu** U-T68-SV; HTTT của tổ chức khác; HTTT của T01.
- **Bước**
  1. Gọi `GET /systems/{systemCode}/stats` của tổ chức khác, rồi của T01.
- **Mong đợi** 404-ẩn cho cả hai; thân giống hệt trừ `traceId`.

### TS-13-21 · Hạ tầng: nút gateway, cụm Kafka

**Mục tiêu.** Xác nhận danh sách, chi tiết, tài nguyên gateway và cụm Kafka; thay "danh sách gateway", "giám sát gateway" của APIM và đồ thị CPU, bộ nhớ của Hub.

**Phủ.** FR-13-036, 037, 038; UC-13-23; API-13-011, 012, 013, 014; UI-13-04; BR-13-016; ERR-13-001; LGC-APIM-023; 024, 025; LGC-HUB-005, 006.

#### TC-13-062 · Nút gateway và cụm Kafka hiển thị tài nguyên <!--k:infra-dash-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-036, 037, 038 · UC-13-23 · API-13-011, 012, 013, 014 · UI-13-04 · LGC-APIM-023; 024, 025 · LGC-HUB-005, 006
- **Tiền điều kiện / dữ liệu** SIT có 2 nút APISIX, 3 broker; U-PO.
- **Bước**
  1. Mở UI-13-04; mở một nút gateway; xem CPU, heap, kết nối; xem cụm Kafka (lag, broker, phân vùng).
- **Mong đợi** Danh sách đủ 2 nút; số liệu khớp Prometheus; Kafka đủ 3 broker; ngừng 1 nút thì hiện `DOWN` trong ≤ 3 phút.

#### TC-13-063 · Nút không tồn tại, thiếu dữ liệu, không quyền <!--k:infra-dash-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-036, 037, 038 · API-13-012, 013, 014 · ERR-13-001, 009 · BR-13-016
- **Tiền điều kiện / dữ liệu** U-T68-IE; nút `khong-co`.
- **Bước**
  1. `GET /gateways/khong-co`.
  2. U-T68-IE gọi `GET /kafka/cluster`.
- **Mong đợi** `404` ERR-13-001; IE giữ `PERM-13-dashboard` như D02-08 nên không nhận `403`, nhưng chỉ thấy dữ liệu của luồng và HTTT do mình thiết kế, hạ tầng chung chỉ ở mức tenant theo BR-13-030 (đã chốt 27/11/2026, Q13-41); exporter ngừng hiện "Chưa có dữ liệu".

### TS-13-22 · Hoạt động nghiệp vụ và bảng điều khiển an ninh

**Mục tiêu.** Xác nhận lãnh đạo xem hoạt động nghiệp vụ không thấy log, kiểm toán; cán bộ ATTT xem bảng an ninh.

**Phủ.** FR-13-039, 040; UC-13-24; API-13-015, 016; UI-13-05, 06; ERR-13-009; BR-13-030.

#### TC-13-064 · Hoạt động nghiệp vụ và bảng an ninh đúng người xem <!--k:biz-sec-dash-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-039, 040 · UC-13-24 · API-13-015, 016 · UI-13-05, 06
- **Tiền điều kiện / dữ liệu** F-SEC-EVT; U-T68-VW; U-T68-SO.
- **Bước**
  1. U-T68-VW mở UI-13-05; thử mở `/giam-sat/log` và UI-13-06.
  2. U-T68-SO mở UI-13-06.
- **Mong đợi** VW xem được UI-13-05, không mở được log, kiểm toán; SO thấy đăng nhập thất bại, bị từ chối, kết quả quét; số liệu khớp F-SEC-EVT.

#### TC-13-065 · VW không có quyền xem log và kiểm toán <!--k:biz-sec-dash-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-020, 026, 039, 040 · API-13-016, 019, 074 · ERR-13-009 · UC-13-24
- **Tiền điều kiện / dữ liệu** U-T68-VW.
- **Bước**
  1. Gọi `POST /logs:search`, `POST /records:search`.
- **Mong đợi** Cả hai 403-PQ; giao diện ẩn menu Log, Kiểm toán.

### TS-13-23 · Quản lý bộ dashboard theo tenant

**Mục tiêu.** Xác nhận bộ dashboard chuẩn đồng bộ sang Grafana của tenant, không sửa tay tại chỗ.

**Phủ.** FR-13-041; UC-13-25; API-13-017, 018; UI-13-17; ERR-13-035, 009; BR-13-032.

#### TC-13-066 · Đồng bộ bộ dashboard chuẩn sang Grafana của tenant <!--k:dashset-sync-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-041 · UC-13-25 · API-13-017, 018 · UI-13-17 · BR-13-032
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. `GET /dashboard-sets`; `POST /dashboard-sets/{setCode}:sync`.
- **Mong đợi** `202`; Grafana của T68 có bộ chuẩn; KT: có (`OBS.DASHBOARD.SYNC`); không ảnh hưởng Grafana của T01.

#### TC-13-067 · Bộ dashboard không hợp lệ hoặc không quyền <!--k:dashset-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-041 · API-13-018 · ERR-13-035, 009, 016
- **Tiền điều kiện / dữ liệu** Bộ lỗi `bo-hong`; U-T68-TO; T68 tạm ngừng ở ca phụ.
- **Bước**
  1. Đồng bộ `bo-hong`; U-T68-TO đồng bộ; tenant tạm ngừng đồng bộ.
- **Mong đợi** `422` ERR-13-035; 403-PQ; `423` ERR-13-016 (chỉ đọc).

### TS-13-24 · Luật cảnh báo, runbook và bộ luật chuẩn

**Mục tiêu.** Xác nhận luật cảnh báo bắt buộc runbook đủ năm mục, biểu thức hợp lệ, chạy thử được; luật chuẩn nền tảng tenant không sửa, chỉ nhân bản.

**Phủ.** FR-13-042, 043; UC-13-26, 27; API-13-035, 036, 037, 038, 039, 040, 041, 042, 043, 044; UI-13-11; BR-13-008, 009, 031, 032; ERR-13-002, 017, 018, 019, 008, 007, 037; EVT-13-10; LGC-PAY-009.

#### TC-13-068 · Tạo luật kèm runbook, chạy thử trên 24 giờ, bật <!--k:rule-create-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-13-042 · UC-13-26 · API-13-036, 039, 042, 043 · UI-13-11 · BR-13-008, 009 · EVT-13-10
- **Tiền điều kiện / dữ liệu** U-T68-TA; dữ liệu 24 giờ.
- **Bước**
  1. Tạo runbook `rb-api-loi` đủ năm mục; tạo luật `luat-api-5xx` mức Nghiêm trọng có mô tả triệu chứng.
  2. `POST /alert-rules/luat-api-5xx:test`.
- **Mong đợi** `201`; kết quả thử nêu số lần sẽ phát trong 24 giờ; EVT: `rule.changed`; KT: có (`OBS.RULE.CREATE`); hiệu lực ≤ 60 giây.


#### TC-13-123 · Tenant mới có sẵn bộ luật chuẩn với runbook đủ năm mục <!--k:rule-standard-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-042, 043 · UC-13-27 · API-13-035, 037, 042 · UI-13-11 · BR-13-008, 032 · NFR-13-028
- **Tiền điều kiện / dữ liệu** F-RULE-STD; T90 vừa khởi tạo; U-PA phát hành bản mới.
- **Bước**
  1. Liệt kê luật và runbook ở T90.
  2. U-PA phát hành bản luật chuẩn mới; đọc lại ở T68 sau 60 giây.
- **Mong đợi** Mọi luật chuẩn có runbook đủ năm mục; bản mới tới T68 ≤ 60 giây, EVT: `rule.changed`; luật nhân bản của tenant không bị đè.

#### TC-13-069 · Luật thiếu runbook, biểu thức sai, mã trùng <!--k:rule-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-042 · API-13-036, 038, 043, 044 · ERR-13-017, 018, 002, 007, 037, 008 · BR-13-008, 009
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. Luật không runbook; runbook thiếu mục "khi nào báo cấp trên".
  2. Biểu thức dùng nhãn `trace_id`.
  3. Tạo luật trùng mã `luat-cpu-cao`; sửa với `If-Match` cũ; tắt không lý do.
- **Mong đợi** ERR-13-017; ERR-13-018 (nêu "nhãn `trace_id` không được dùng làm nhãn chỉ số"); ERR-13-002; ERR-13-007; ERR-13-008. Luật Nghiêm trọng chỉ dựa trên mức dùng CPU bị từ chối (BR-13-009).

#### TC-13-070 · Luật chuẩn nền tảng không sửa, không tắt, chỉ nhân bản <!--k:rule-standard-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-042, 043 · API-13-035, 037, 038, 040, 041 · ERR-13-019 · BR-13-032
- **Tiền điều kiện / dữ liệu** F-RULE-STD; U-T68-TA; U-PA.
- **Bước**
  1. U-T68-TA liệt kê luật; sửa, tắt một luật chuẩn; nhân bản thành luật riêng.
  2. U-PA sửa luật chuẩn ở PLATFORM.
- **Mong đợi** Sửa, tắt: `403` ERR-13-019; nhân bản được; U-PA sửa được, EVT: `rule.changed` tới mọi tenant.

#### TC-13-071 · Luật của hai tenant trùng mã không lẫn <!--k:rule-isolation-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-042 · API-13-037, 038 · ERR-13-001 · BR-13-031
- **Tiền điều kiện / dữ liệu** `luat-cpu-cao` ở T68 và T01 khác ngưỡng; U-T68-TA.
- **Bước**
  1. Đọc và sửa `luat-cpu-cao`; so với T01.
- **Mong đợi** Chỉ thấy, sửa ngưỡng của T68; T01 không đổi.

### TS-13-25 · Từ điều kiện bất thường đến thông báo người trực

**Mục tiêu.** Xác nhận luật được đánh giá, chống nhấp nháy, phân mức, gom nhóm, gửi theo lịch trực và leo thang đúng thời gian.

**Phủ.** FR-13-044, 045, 046; UC-13-28; API-13-030, 090; UI-13-10, 12; BR-13-009, 021, 022, 028; ERR-13-119, 120, 121; EVT-13-01, 03; NFR-13-015.

#### TC-13-072 · Luật thỏa đủ thời gian duy trì sinh `FIRING`, gửi thông báo ≤ 60 giây <!--k:alert-fire-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-044, 045, 046 · UC-13-28 · API-13-030, 090 · UI-13-10 · EVT-13-01 · NFR-13-015
- **Tiền điều kiện / dữ liệu** Luật `luat-api-5xx` duy trì 2 phút; lịch trực T68; F-SIM-CHAN.
- **Bước**
  1. Phát lỗi 5xx vượt ngưỡng 1 phút, rồi ngừng; phát tiếp 3 phút.
  2. Đo từ lúc `FIRING` tới khi kênh giả nhận.
- **Mong đợi** Nhấp nháy 1 phút không sinh cảnh báo; 3 phút sinh một cảnh báo; thông báo p95 ≤ 60 giây tới người trực đúng ca; EVT: `alert.fired`; API-13-090 chỉ nhận từ mTLS của Alertmanager.

#### TC-13-073 · Gom nhóm, chống lặp và chỉ gửi ngoài ứng dụng trong giờ hành chính <!--k:alert-group-hours-->
- **Loại** Dương, Biên · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-045, 046 · BR-13-028 · API-13-030 · UI-13-10
- **Tiền điều kiện / dữ liệu** 20 cảnh báo cùng luật; mức Cảnh báo lúc 20:00 và 09:00.
- **Bước**
  1. Sinh 20 cảnh báo cùng nhãn trong 5 phút.
  2. Sinh cảnh báo mức Cảnh báo ngoài giờ rồi trong giờ.
- **Mong đợi** Gom thành một nhóm, một thông báo; ngoài giờ mức Cảnh báo chỉ hiển thị trong ứng dụng, chờ tới 07:30 mới gửi.


#### TC-13-124 · Cảnh báo đang tạm ẩn không gửi thông báo mới, luật khác nhau không gom nhầm <!--k:alert-silence-no-notify-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-045, 046, 047 · BR-13-021 · API-13-030, 034 · UI-13-10
- **Tiền điều kiện / dữ liệu** Cảnh báo `SILENCED` 12 giờ; hai luật khác nhau cùng nhãn dịch vụ.
- **Bước**
  1. Tạo thêm 5 lần phát của luật đang tạm ẩn; phát hai luật khác nhau cùng lúc.
- **Mong đợi** Không thông báo mới cho luật tạm ẩn; hai luật khác nhau thành hai nhóm riêng; hết hạn tạm ẩn mà điều kiện còn thì gửi lại.

#### TC-13-074 · Nghiêm trọng chưa xác nhận leo thang 15 phút, 30 phút <!--k:alert-escalate-->
- **Loại** Dương, Biên · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-046 · BR-13-022 · EVT-13-03 · ERR-13-121 · UI-13-12
- **Tiền điều kiện / dữ liệu** Nhóm nhận ba cấp, ít nhất hai kênh khác loại; `13.alert.escalate-minutes = 15,30`.
- **Bước**
  1. Giữ `FIRING` Nghiêm trọng, không xác nhận 31 phút; một lần khác xác nhận ở phút 10.
- **Mong đợi** Cấp 2 ở 15 phút, cấp 3 ở 30 phút, EVT: `alert.escalated`; hết cấp mà chưa ai nhận: ERR-13-121; xác nhận ở phút 10 dừng leo thang.

#### TC-13-075 · Kênh thông báo lỗi, luật đánh giá lỗi báo về chính hệ thống <!--k:alert-channel-fail-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-044, 046, 049 · ERR-13-119, 120 · BR-13-022
- **Tiền điều kiện / dữ liệu** Ngắt một kênh F-SIM-CHAN; luật có biểu thức làm Ruler lỗi.
- **Bước**
  1. Gửi cảnh báo khi một kênh ngắt.
- **Mong đợi** Chuyển sang kênh khác loại; ERR-13-120 hiển thị ở UI-13-01; luật lỗi đánh giá: ERR-13-119.

### TS-13-26 · Xử lý cảnh báo

**Mục tiêu.** Xác nhận xác nhận, đã xử lý, tạm ẩn theo máy trạng thái, có thời hạn, nguyên nhân, hành động.

**Phủ.** FR-13-047; UC-13-29; API-13-031, 032, 033, 034; UI-13-10; BR-13-021, 023; ERR-13-020, 021, 022, 007, 009; EVT-13-02.

#### TC-13-076 · Xác nhận, tạm ẩn rồi đóng cảnh báo <!--k:alert-handle-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-047 · UC-13-29 · API-13-031, 032, 033, 034 · UI-13-10 · BR-13-021, 023 · EVT-13-02
- **Tiền điều kiện / dữ liệu** Cảnh báo Nghiêm trọng `FIRING`; U-T68-TO.
- **Bước**
  1. Xác nhận; tạm ẩn 12 giờ với lý do; đóng với nguyên nhân, hành động, kết quả `FIXED`.
- **Mong đợi** Trạng thái `ACKNOWLEDGED` → `SILENCED` → `RESOLVED` (`MANUAL`); EVT: `alert.resolved`; KT: có từng bước; hết hạn tạm ẩn mà điều kiện còn thì quay về `FIRING`.

#### TC-13-077 · Tạm ẩn quá hạn, đóng thiếu nguyên nhân, thao tác sai trạng thái <!--k:alert-handle-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-047 · API-13-032, 033, 034 · ERR-13-021, 022, 020, 007, 009 · BR-13-021, 023
- **Tiền điều kiện / dữ liệu** Cảnh báo Nghiêm trọng; cảnh báo `RESOLVED`; U-T68-VW.
- **Bước**
  1. Tạm ẩn Nghiêm trọng 25 giờ; tạm ẩn thiếu lý do.
  2. Đóng không có nguyên nhân.
  3. Xác nhận cảnh báo đã `RESOLVED`; U-T68-VW xác nhận.
- **Mong đợi** ERR-13-021 (`maxDays` nêu 24 giờ); ERR-13-022; `409` ERR-13-020; 403-PQ.

### TS-13-27 · Lịch trực, nhóm nhận, kênh thông báo

**Mục tiêu.** Xác nhận lịch trực không hở, không chồng, nhóm Nghiêm trọng có đường độc lập; thử gửi kênh.

**Phủ.** FR-13-048; UC-13-30; API-13-045, 046, 047, 048, 049, 050, 051; UI-13-12; ERR-13-033, 034, 002, 037; BR-13-022, 031.

#### TC-13-078 · Tạo lịch trực, nhóm, kênh và gửi thử <!--k:oncall-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-048 · UC-13-30 · API-13-045, 046, 047, 048, 049, 050, 051 · UI-13-12
- **Tiền điều kiện / dữ liệu** U-T68-TA; F-SIM-CHAN.
- **Bước**
  1. Tạo kênh thư điện tử, SMS, webhook; gửi thử từng kênh.
  2. Tạo lịch trực 24/7 hai ca; sửa.
- **Mong đợi** `201`; thử gửi `200`, kênh giả nhận; KT: có.

#### TC-13-079 · Lịch hở khoảng, chồng ca, kênh thử thất bại <!--k:oncall-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-048 · API-13-046, 047, 049, 051 · ERR-13-034, 033, 002, 037 · BR-13-022
- **Tiền điều kiện / dữ liệu** U-T68-TA; kênh ngắt.
- **Bước**
  1. Lịch thiếu Thứ Bảy 00:00–07:30; lịch hai ca chồng nhau.
  2. Nhóm Nghiêm trọng chỉ có một đường.
  3. Gửi thử tới kênh ngắt; tạo kênh trùng mã.
- **Mong đợi** ERR-13-034 nêu khoảng hở (ví dụ "Thứ Bảy 00:00–07:30 chưa có người nhận"); ERR-13-033; ERR-13-002.

### TS-13-28 · Giám sát chính hệ thống giám sát và thống kê hiệu quả cảnh báo

**Mục tiêu.** Xác nhận có "giám sát người giám sát" độc lập và thống kê cảnh báo giả.

**Phủ.** FR-13-049, 050; UC-13-31, 32; API-13-052, 053; UI-13-01, 10; ERR-13-122, 123; EVT-13-14; NFR-13-013, 028.

#### TC-13-080 · Mimir, Loki, Alertmanager ngừng thì có cảnh báo qua đường độc lập <!--k:selfmon-->
- **Loại** Dương, Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-13-049 · UC-13-31 · API-13-053 · UI-13-01 · ERR-13-123, 122 · NFR-13-013
- **Tiền điều kiện / dữ liệu** Giám sát bên ngoài (watchdog) sẵn; U-PA.
- **Bước**
  1. Ngừng Loki; ngừng Alertmanager; làm đầy kho tới 85 %; ngắt SIEM.
- **Mong đợi** `GET /monitoring-health` nêu thành phần ngừng; đường cảnh báo độc lập vẫn báo U-PA; ERR-13-123 ở 85 %; ERR-13-122 khi SIEM không nhận; EVT: `capacity.warning`.

#### TC-13-081 · Thống kê hiệu quả cảnh báo <!--k:alert-stats-->
- **Loại** Dương, Biên · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-13-050 · UC-13-32 · API-13-052 · UI-13-10 · NFR-13-028 · BR-13-023
- **Tiền điều kiện / dữ liệu** 100 cảnh báo, 30 đóng `NO_ACTION`.
- **Bước**
  1. `GET /alert-stats` 30 ngày.
- **Mong đợi** Tỷ lệ cảnh báo giả 30 %; thời gian xác nhận trung bình; theo luật; khoảng không có dữ liệu hiển thị "Chưa có dữ liệu".

### TS-13-29 · Luật phát hiện UC-SEC

**Mục tiêu.** Xác nhận bộ luật phát hiện UC-SEC nạp sẵn, tinh chỉnh ngưỡng trong biên, luật "mọi sự kiện" không tắt.

**Phủ.** FR-13-051; UC-13-33; API-13-054, 055; UI-13-15; BR-13-024, 025, 032; ERR-13-024, 008, 028, 009.

#### TC-13-082 · Tinh chỉnh ngưỡng trong biên có lý do <!--k:detrule-tune-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-051 · UC-13-33 · API-13-054, 055 · UI-13-15 · BR-13-025 · EVT-13-10
- **Tiền điều kiện / dữ liệu** U-T68-SO xác thực lại; luật đăng nhập thất bại ngưỡng mặc định 5.
- **Bước**
  1. `GET /detection-rules`; nới ngưỡng thành 8; siết thành 3.
- **Mong đợi** `200`; KT: có (`OBS.DETRULE.TUNE`) kèm `reason`; EVT: `rule.changed`.

#### TC-13-083 · Nới quá 2 lần, tắt luật Nghiêm trọng, thiếu lý do <!--k:detrule-tune-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-051 · API-13-055 · ERR-13-024, 008, 028, 009 · BR-13-025
- **Tiền điều kiện / dữ liệu** U-T68-SO; U-T68-TO.
- **Bước**
  1. Nới ngưỡng 11 (hơn 2 lần mặc định 5).
  2. Tắt luật Nghiêm trọng kiểu "mọi sự kiện".
  3. Sửa không lý do; phiên chưa xác thực lại; U-T68-TO sửa.
- **Mong đợi** ERR-13-024; ERR-13-024; ERR-13-008; ERR-13-028; 403-PQ.

### TS-13-30 · Phát hiện bất thường và xử lý cảnh báo an ninh

**Mục tiêu.** Xác nhận bộ phát hiện sinh cảnh báo an ninh từ bản ghi kiểm toán, đóng cần kết luận, đề xuất tạm ngừng HTTT chuyển PH-01 chứ không tự thực hiện.

**Phủ.** FR-13-052, 053; UC-13-34, 35; API-13-056, 057, 058, 059, 060; API-01-089; UI-13-15; BR-13-024; ERR-13-020, 023, 008, 028, 014, 001, 009, 003; ERR-01-005, 048; EVT-13-04.

#### TC-13-084 · Chuỗi đăng nhập thất bại sinh cảnh báo an ninh <!--k:secalert-detect-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-052, 053 · UC-13-34 · API-13-056, 057 · UI-13-15 · EVT-13-04
- **Tiền điều kiện / dữ liệu** F-SEC-EVT; U-T68-SO.
- **Bước**
  1. Phát 6 lần đăng nhập thất bại từ một nguồn trong 5 phút; sau đó phát chuỗi hợp lệ.
- **Mong đợi** Một cảnh báo an ninh `NEW` với bằng chứng là `audit_id`; EVT: `security-alert.raised`; chuỗi hợp lệ không sinh cảnh báo.


#### TC-13-125 · Dưới ngưỡng, hành vi hợp lệ, đồng hồ lệch không sinh cảnh báo an ninh giả <!--k:secalert-no-false-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-13-052 · UC-13-34 · API-13-056 · BR-13-025
- **Tiền điều kiện / dữ liệu** F-SEC-EVT; luật đăng nhập thất bại ngưỡng 5.
- **Bước**
  1. Phát 5 lần thất bại (đúng ngưỡng chưa vượt), rồi 4 lần trong cửa sổ khác; phát thao tác hợp lệ giờ hành chính.
- **Mong đợi** 0 cảnh báo an ninh; chỉ vượt ngưỡng (6 lần) mới sinh; bản ghi lệch đồng hồ ERR-13-126 không gây cảnh báo.

#### TC-13-085 · Tiếp nhận, đóng kết luận và đề xuất tạm ngừng HTTT <!--k:secalert-handle-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-13-053 · UC-13-35 · API-13-058, 059, 060 · UI-13-15 · BR-13-024
- **Tiền điều kiện / dữ liệu** Cảnh báo an ninh `NEW`; U-T68-SO.
- **Bước**
  1. Tiếp nhận; đề xuất tạm ngừng HTTT `HT-NDXP` kèm lý do; đóng kết luận "sự cố thật".
- **Mong đợi** `NEW` → `ACKNOWLEDGED` → `CLOSED`; đề xuất tới hộp việc PH-01, HTTT chưa bị tạm ngừng cho tới khi người có quyền duyệt; KT: có từng bước.

#### TC-13-086 · Đóng thiếu kết luận, thao tác sai trạng thái <!--k:secalert-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-053 · API-13-058, 059, 060 · ERR-13-023, 020, 008, 028 · BR-13-024
- **Tiền điều kiện / dữ liệu** Cảnh báo an ninh `CLOSED`; cảnh báo `NEW`.
- **Bước**
  1. Đóng không kết luận; tiếp nhận cảnh báo đã `CLOSED`; đề xuất tạm ngừng không lý do; phiên chưa xác thực lại.
- **Mong đợi** ERR-13-023; ERR-13-020; ERR-13-008; ERR-13-028.

#### TC-13-132 · Đề xuất tạm ngừng gửi sang PH-01 qua API-01-089 bằng token dịch vụ <!--k:susp-send-ok-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-13-053 · UC-13-35 · API-13-060 · BR-13-024 · API-01-089 · FR-01-053
- **Tiền điều kiện / dữ liệu** Cảnh báo an ninh `ACKNOWLEDGED` của `HT-NDXP` (T68, ACTIVE) mức `HIGH`; U-T68-SO; PH-01 giả lập nhận API-01-089 (scope `onboarding:suspension-proposal`) và ghi lại thân yêu cầu.
- **Bước**
  1. SO `POST /security-alerts/{alertId}:propose-suspension` với `systemCode = HT-NDXP`, `reason` 40 ký tự, `If-Match` đúng.
  2. Đọc yêu cầu PH-01 giả lập nhận được.
  3. Đọc cảnh báo và nhật ký kiểm toán PH-13.
- **Mong đợi** Bước 1: `200`, cảnh báo có `proposedAction`. Bước 2: một lời gọi `POST /internal/suspension-proposals` bằng token dịch vụ của PH-13 (không phải token người dùng), thân có `systemCode = HT-NDXP`, `alertId` đúng cảnh báo, `severity = HIGH`, `reason` nguyên văn, liên kết sâu `evidenceUrl` về cảnh báo; PH-01 trả `202`, `duplicate = false`. Bước 3: có bản ghi `SECURITY.ALERT.PROPOSE_SUSPENSION` kèm HTTT, lý do; PH-13 không gọi API đổi trạng thái HTTT và không chờ quyết định.

#### TC-13-133 · Đề xuất tạm ngừng khi PH-01 lỗi, từ chối hoặc báo trùng <!--k:susp-send-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-053 · API-13-060 · API-01-089 · ERR-13-014, 001, 009 · BR-13-024
- **Tiền điều kiện / dữ liệu** Cảnh báo an ninh `ACKNOWLEDGED`; PH-01 giả lập có công tắc `down`, `suspended` (trả `409` ERR-01-048), `duplicate`; HTTT `HT-TC-KHAC` thuộc T01; U-T68-SO, U-T68-AU.
- **Bước**
  1. Bật `down`; SO đề xuất.
  2. Tắt `down`; SO đề xuất lại.
  3. Bật `suspended`: SO đề xuất cho HTTT đã bị tạm ngừng.
  4. SO đề xuất lần hai cùng cảnh báo khi PH-01 trả `duplicate = true`.
  5. SO đề xuất cho `HT-TC-KHAC`; AU đề xuất.
- **Mong đợi** Bước 1: `503` ERR-13-014, đề xuất chưa gửi, cảnh báo không ghi `proposedAction`, SO thử lại được. Bước 2: `200`, một đề xuất tới PH-01. Bước 3: PH-13 coi đề xuất đã được đáp ứng, không báo lỗi cho SO và không thử lại. Bước 4: `200`, không tạo việc thứ hai ở PH-01, không có bản ghi đề xuất trùng. Bước 5: `404` ERR-13-001 và PH-13 không gọi PH-01; AU `403` ERR-13-009. Không ca nào làm HTTT đổi trạng thái.

#### TC-13-134 · Đề xuất tạm ngừng từ cảnh báo mức thấp hơn HIGH bị từ chối <!--k:susp-low-severity-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-13-053 · UC-13-35 · API-13-060 · UI-13-15 · ERR-13-003 · BR-13-024
- **Tiền điều kiện / dữ liệu** Hai cảnh báo an ninh `ACKNOWLEDGED` của `HT-NDXP` (T68, ACTIVE), một mức `MEDIUM`, một mức `HIGH`; U-T68-SO; PH-01 giả lập ghi lại mọi yêu cầu nhận được.
- **Bước**
  1. SO mở chi tiết cảnh báo mức `MEDIUM` ở UI-13-15.
  2. SO `POST /security-alerts/{alertId}:propose-suspension` cho cảnh báo `MEDIUM` với `systemCode = HT-NDXP`, `reason` 40 ký tự, `If-Match` đúng.
  3. SO mở chi tiết cảnh báo mức `HIGH`.
- **Mong đợi** Bước 1: nút "Đề xuất tạm ngừng HTTT" không hiện. Bước 2: `400` ERR-13-003 "Chỉ cảnh báo mức Cao hoặc Nghiêm trọng mới đề xuất tạm ngừng HTTT được."; PH-01 giả lập không nhận yêu cầu nào, cảnh báo không ghi `proposedAction`, HTTT giữ nguyên `ACTIVE`. Bước 3: nút hiện và dùng được.

#### TC-13-135 · Đề xuất tạm ngừng khi PH-01 báo HTTT không ở trạng thái cho phép <!--k:susp-state-not-allowed-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-053 · UC-13-35 · API-13-060 · API-01-089 · UI-13-15 · ERR-01-005 · BR-13-024
- **Tiền điều kiện / dữ liệu** Cảnh báo an ninh `ACKNOWLEDGED` mức `HIGH` của `HT-NDXP`; PH-01 giả lập bật công tắc `not-allowed` (trả `409` ERR-01-005); U-T68-SO.
- **Bước**
  1. SO đề xuất tạm ngừng `HT-NDXP` kèm `reason` 40 ký tự.
  2. Đọc cảnh báo và nhật ký kiểm toán PH-13.
- **Mong đợi** Bước 1: PH-13 báo cho SO "HTTT HT-NDXP không ở trạng thái cho phép tạm ngừng." (khác ca PH-01 trả ERR-01-048 là coi đã đáp ứng, không báo lỗi); không thử lại. Bước 2: cảnh báo không ghi `proposedAction`; HTTT không đổi trạng thái.

### TS-13-31 · Đẩy sang SIEM, SOC và báo cáo sự cố

**Mục tiêu.** Xác nhận log và cảnh báo an ninh sang SIEM đã loại dữ liệu cá nhân, chuẩn ECS hoặc OCSF; hàng đợi đĩa khi SIEM ngừng; báo cáo sự cố sinh từ cảnh báo.

**Phủ.** FR-13-054, 055; UC-13-36, 37; API-13-061, 062, 063, 064, 065, 066; UI-13-15, 17; BR-13-034; ERR-13-039, 122, 008, 002, 037.

#### TC-13-087 · Đẩy sang SIEM đúng chuẩn, không dữ liệu cá nhân <!--k:siem-ok-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-13-054 · UC-13-36 · API-13-061, 062, 063, 064 · UI-13-17 · BR-13-034
- **Tiền điều kiện / dữ liệu** F-SIM-SIEM; F-AUD-PII; U-T68-TA.
- **Bước**
  1. Tạo mục tiêu SIEM; gửi thử; phát cảnh báo an ninh và log mồi.
- **Mong đợi** Gửi thử `200`; bản tin ECS có trường chuẩn; không số định danh, thư điện tử, mồi `DH-CANARY`; điểm xuất cho cơ quan chuyên trách tắt mặc định.

#### TC-13-088 · SIEM ngừng, hàng đợi đĩa và gửi bù; mục tiêu sai <!--k:siem-neg-->
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-13-054 · API-13-062, 063, 064 · ERR-13-122, 039, 002, 037 · BR-13-034
- **Tiền điều kiện / dữ liệu** `13.siem.queue-max-mb = 256`; ngắt F-SIM-SIEM.
- **Bước**
  1. Ngắt SIEM; phát log; bật lại.
  2. Tạo mục tiêu có địa chỉ không với tới; tạo mục tiêu trùng mã.
- **Mong đợi** Hàng đợi đĩa, đầy thì bỏ bản cũ nhất và cảnh báo (ERR-13-122); sau khi bật gửi bù theo thứ tự; ERR-13-039; ERR-13-002.

#### TC-13-089 · Sinh báo cáo sự cố từ cảnh báo an ninh <!--k:incident-report-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-13-055 · UC-13-37 · API-13-065, 066 · ERR-13-008, 001 · UI-13-15
- **Tiền điều kiện / dữ liệu** Cảnh báo an ninh `CLOSED` sự cố thật; U-T68-SO.
- **Bước**
  1. `POST /incident-reports:generate` có lý do, rồi không lý do.
  2. `GET /incident-reports/{reportId}`; id của T01.
- **Mong đợi** `201` báo cáo có dòng thời gian, hệ thống, phạm vi dữ liệu cá nhân (không giá trị); lần hai ERR-13-008; id T01 404-ẩn.

### TS-13-32 · Dịch vụ cho phân hệ khác

**Mục tiêu.** Xác nhận PH-16 lấy số liệu tổng hợp và PH-18 lấy ngữ cảnh chẩn đoán qua scope hẹp, đúng tenant.

**Phủ.** FR-13-056, 057, 058; UC-13-38, 39; API-13-067, 068, 069, 002; ERR-13-004, 005, 006, 011, 015, 030, 044; NFR-13-002.

#### TC-13-090 · PH-16 lấy số liệu tổng hợp, PH-18 lấy ngữ cảnh chẩn đoán <!--k:services-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-056, 057 · UC-13-38, 39 · API-13-067, 068, 069
- **Tiền điều kiện / dữ liệu** S-PH16; S-PH18; F-TRACE-MIX.
- **Bước**
  1. S-PH16 `POST /metrics:query`, `GET /metrics/summary`.
  2. S-PH18 `GET /diagnostics/{traceId}`.
- **Mong đợi** `200`; số liệu khớp bộ phát; chẩn đoán gồm trace, log lỗi, cảnh báo liên quan; không dữ liệu Nhạy cảm.

#### TC-13-091 · Scope thiếu, truy vấn sai, ngoài phạm vi tenant <!--k:services-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-056, 057 · API-13-067, 068, 069 · ERR-13-044, 004, 005, 006, 030, 011, 015
- **Tiền điều kiện / dữ liệu** S-PH16 gọi `diagnostics`; S-PH18 gọi `metrics:query`.
- **Bước**
  1. Gọi chéo scope.
  2. Truy vấn thiếu khoảng, quá khoảng, sai cú pháp; trace không có.
- **Mong đợi** ERR-13-044; ERR-13-004; ERR-13-005; ERR-13-006; ERR-13-030.

### TS-13-33 · Vòng đời tenant: khởi tạo và đóng chuỗi

**Mục tiêu.** Xác nhận PH-20 khởi tạo quan sát và chuỗi kiểm toán cho tenant mới, lũy đẳng; đóng chuỗi khi ngừng hoặc sáp nhập, có neo cuối.

**Phủ.** FR-13-059, 060; UC-13-40, 41; API-13-072, 073; UI-13-17; ERR-13-042, 043, 037, 044, 008; BR-13-017, 020.

#### TC-13-092 · Khởi tạo quan sát và chuỗi cho T90, chạy lại không đổi <!--k:tenant-provision-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-059 · UC-13-40 · API-13-072 · BR-13-017
- **Tiền điều kiện / dữ liệu** S-PH20; T90 chưa có cấu hình.
- **Bước**
  1. `POST /tenants/t90/observability:provision` kèm `Idempotency-Key`; lặp lại cùng khóa cùng nội dung.
  2. Ghi bản ghi đầu tiên; gọi `GET /chain-status` của T90.
- **Mong đợi** `200`; Grafana, bộ luật chuẩn, dashboard, chuỗi `seq` 1 sẵn sàng; lặp lại không tạo thêm; KT: có.

#### TC-13-093 · Khởi tạo lại khác tham số, khóa trùng khác nội dung, thiếu scope <!--k:tenant-provision-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-13-059 · API-13-072 · ERR-13-042, 037, 044
- **Tiền điều kiện / dữ liệu** T90 đã khởi tạo; S-PH16.
- **Bước**
  1. Khởi tạo T90 với tham số khác.
  2. Dùng `Idempotency-Key` cũ với nội dung khác.
  3. S-PH16 gọi khởi tạo.
- **Mong đợi** `409` ERR-13-042; `409` ERR-13-037; `403` ERR-13-044.

#### TC-13-094 · Đóng chuỗi T91, neo cuối, từ chối ghi tiếp <!--k:chain-close-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-060 · UC-13-41 · API-13-073 · ERR-13-043, 008, 044 · BR-13-020 · UI-13-17
- **Tiền điều kiện / dữ liệu** T91 có chuỗi 3 tháng; S-PH20.
- **Bước**
  1. `POST /tenants/t91/audit-chain:close` có lý do; lặp lại.
  2. Gửi bản ghi vào T91.
- **Mong đợi** Neo cuối được ký, WORM giữ nguyên thời hạn, chuỗi `CLOSED`; lặp lại hoặc ghi tiếp `409` ERR-13-043; tra cứu chuỗi vẫn được.

### TS-13-34 · Tham số và hạn mức quan sát theo tenant

**Mục tiêu.** Xác nhận tenant đặt tham số `13.*` trong biên, vượt trần nền tảng bị từ chối.

**Phủ.** FR-13-061; UC-13-42; API-13-070, 071; UI-13-17; ERR-13-040, 041, 007, 008; BR-13-020, 031; NFR-13-030.

#### TC-13-095 · Đổi tham số trong biên có hiệu lực ≤ 60 giây <!--k:params-ok-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-061 · UC-13-42 · API-13-070, 071 · UI-13-17 · NFR-13-019, 030
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. `PATCH /settings` đặt `13.alert.silence-max-days = 3`, `13.audit.worm-retention-years = 7`.
- **Mong đợi** `200`; tạm ẩn quá 3 ngày bị từ chối sau ≤ 60 giây; lô WORM mới có thời hạn 7 năm, lô cũ không rút ngắn; KT: có kèm `reason`.

#### TC-13-096 · Hạn mức vượt trần, tham số ngoài miền, thiếu lý do <!--k:params-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-13-061 · API-13-071 · ERR-13-041, 040, 007, 008, 009
- **Tiền điều kiện / dữ liệu** U-T68-TA; U-T68-TO.
- **Bước**
  1. Đặt `13.series.max-active = 3.000.000`.
  2. Đặt `13.alert.escalate-minutes = 2`; không `reason`.
  3. U-T68-TO sửa.
- **Mong đợi** `422` ERR-13-041; ERR-13-040; ERR-13-008; 403-PQ; không giá trị nào được lưu.


#### TC-13-126 · Dữ liệu vào sai kiểu và `size` quá giới hạn ở API danh sách, tạo mới <!--k:common-input-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** API-13-030, 036, 035 · ERR-13-003, 038 · FR-13-042, 047
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. `GET /alerts?size=201`.
  2. `POST /alert-rules` với `severity = BAT_KY`.
- **Mong đợi** `400` ERR-13-038; `400` ERR-13-003 với `errors[]` nêu `path = severity`, thông điệp "Trường `severity` phải là một trong CRITICAL, WARNING, INFO."

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Bảy kịch bản dưới đây không gắn một FR; chúng chứng minh các cam kết xuyên suốt của PH-13 (không lộ dữ liệu Nhạy cảm, cách ly tenant, phân quyền, hiệu năng, chịu lỗi, truy cập, bất biến). Nhóm TS-13-35, 36, 39, 41 đạt 100 % mới được phát hành.

### TS-13-35 · Không lộ dữ liệu Nhạy cảm

**Mục tiêu.** Chứng minh giá trị mồi `DH-CANARY` đặt vào mọi chỗ không xuất hiện ở log, trace, chỉ số, bản ghi kiểm toán, tệp xuất, SIEM.

**Phủ.** NFR-13-021, 024; BR-13-005, 011, 035; FR-13-002, 005, 010, 024, 054.

#### TC-13-097 · Dò mồi trên toàn bộ đầu ra của PH-13 <!--k:canary-sweep-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT, ZAP
- **Truy vết** NFR-13-021, 024 · BR-13-011, 035 · FR-13-005, 010 · ERR-13-105, 112
- **Tiền điều kiện / dữ liệu** F-LOG-CAN, F-AUD-PII; mồi `DH-CANARY-sweep` ở thân, nhãn, tên trường, thông điệp lỗi.
- **Bước**
  1. Chạy toàn bộ kịch bản TS-13-01…34 với mồi.
  2. Dò mồi ở Loki, Mimir, Tempo, ClickHouse, bảng `ph13.*`, chuỗi kiểm toán, Kafka, tệp xuất, SIEM giả, log ứng dụng.
- **Mong đợi** 0 lần thấy mồi (trừ bảng cách ly đã che); quét hằng ngày 1 % log và 100 % dòng `ERROR` sạch.

#### TC-13-098 · Thông điệp lỗi không nêu tenant, scope, khóa <!--k:error-no-leak-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** ERR-13-036, 044, 001 · BR-13-017
- **Tiền điều kiện / dữ liệu** U-T68-TO, U-PO, S-PH16.
- **Bước**
  1. Gây ERR-13-036, ERR-13-044, ERR-13-001 theo ba cách khác nhau.
- **Mong đợi** Thân lỗi không nêu tên tenant đích, scope thiếu, khóa; phản hồi 404-ẩn giống hệt trừ `traceId`.

### TS-13-36 · Cách ly tenant

**Mục tiêu.** Chứng minh 0 truy vấn chéo tenant thành công ở mọi API đọc và mọi kho.

**Phủ.** NFR-13-022; BR-13-017, 030; FR-13-009, 020, 022, 026, 028, 030, 035; ERR-13-001, 036.

#### TC-13-099 · Bộ kiểm thử rò rỉ trên mọi API đọc <!--k:leak-all-read-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-13-022 · BR-13-017, 030 · FR-13-020, 022, 026, 028, 030, 035 · ERR-13-001, 036 · API-13-004, 006, 010, 012, 019, 023, 025, 026, 031, 037, 057, 066, 075, 079, 081, 083
- **Tiền điều kiện / dữ liệu** Dữ liệu trùng mã T01 và T68; U-T68-AU, U-T68-TO, U-T01-AU, U-T01-TO.
- **Bước**
  1. Với mỗi API đọc theo mã, gọi bằng token T68 các mã chỉ có ở T01.
  2. Thử `targetTenant`, đổi `tenant` trong thân, thử tiêu đề `X-Tenant`.
- **Mong đợi** 404-ẩn hoặc `403` ERR-13-036; bước 2 không đổi được tenant; tenant luôn lấy từ token.

#### TC-13-100 · Cách ly ở kho: Mimir, Loki, Tempo, ClickHouse, Grafana, PostgreSQL, WORM <!--k:leak-stores-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** DB, IT
- **Truy vết** NFR-13-022 · BR-13-017 · FR-13-009, 011, 013
- **Tiền điều kiện / dữ liệu** `ph13_isolation_test.sql`; chứng thư T68; bucket WORM của T01.
- **Bước**
  1. Phiên PostgreSQL đặt `app.tenant = t68` đọc `audit_event` của t01.
  2. Gọi Grafana của T68 tới nguồn dữ liệu T01; đọc bucket WORM của T01 bằng khóa T68.
- **Mong đợi** RLS trả 0 dòng; Grafana, WORM từ chối; ClickHouse, Loki, Mimir, Tempo không trả dữ liệu T01.

### TS-13-37 · Phân quyền và tách nhiệm

**Mục tiêu.** Chứng minh ma trận `PERM-13-*` ở D02-08 được thực thi, người vận hành không đọc được kiểm toán, người xem không thấy log, và người xuất bằng chứng cần xác thực lại.

**Phủ.** FR-13-020, 024, 025, 042, 047, 053, 061; ERR-13-009, 010, 028; BR-13-006, 018.

#### TC-13-101 · Ma trận quyền PERM-13 theo từng vai trò <!--k:perm-matrix-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** ERR-13-009, 010 · FR-13-020, 042, 047, 053, 061 · API-13-001, 019, 032, 036, 054, 062, 074, 082
- **Tiền điều kiện / dữ liệu** Mọi người dùng mục 2.2.
- **Bước**
  1. Với mỗi vai trò, gọi một API đại diện cho từng quyền `dashboard`, `logs`, `audit-read`, `audit-export`, `alert-admin`, `alert-ack`, `security`, `admin`.
  2. Gọi không token và token hết hạn.
- **Mong đợi** Khớp ma trận D02-08: PO không có `audit-read`; SO, AU có `audit-export`; TA không có `audit-export`; VW chỉ `dashboard`; 403-PQ cho phần còn lại; không token `401` ERR-13-010.

#### TC-13-102 · Thao tác nhạy cảm cần xác thực lại phiên <!--k:stepup-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** ERR-13-028 · BR-13-006, 029 · FR-13-020, 024, 014, 053 · API-13-074, 077, 082, 084, 055, 060
- **Tiền điều kiện / dữ liệu** U-T68-AU, U-T68-SO phiên mới đăng nhập 20 phút.
- **Bước**
  1. Gọi tra kiểm toán, kiểm tra toàn vẹn, xuất, tải, tinh chỉnh ngưỡng, đề xuất tạm ngừng khi chưa xác thực lại.
  2. Xác thực lại bằng TOTP rồi gọi lại.
- **Mong đợi** Bước 1 `403` ERR-13-028; bước 2 `200` hoặc `202`; không có bản ghi thành công nào ở bước 1.

#### TC-13-103 · Tài khoản máy chỉ chạm phạm vi được cấp <!--k:machine-scope-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** ERR-13-044 · BR-13-017 · API-13-067, 069, 072, 073, 076, 089
- **Tiền điều kiện / dữ liệu** S-DU, S-PH16, S-PH18, S-PH20, S-HIST.
- **Bước**
  1. Mỗi tài khoản gọi API của tài khoản khác.
  2. S-DU gửi bản ghi cho tenant không được cấp.
- **Mong đợi** `403` ERR-13-044 mọi trường hợp; bản ghi lạ cách ly ERR-13-103.

### TS-13-38 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-13-001…010, 017, 018, 031 ở cấu hình `QM-VUA`, dữ liệu GĐ.

**Phủ.** NFR-13-001, 002, 003, 004, 005, 006, 007, 008, 009, 010, 017, 018, 031.

| Mã | Tên | Tải | Ngưỡng | Truy vết |
|---|---|---|---|---|
| TC-13-104 | Độ trễ chỉ số tới bảng điều khiển <!--k:perf-metric-lag--> | 250.000 chuỗi, chu kỳ 15 giây, 30 phút | p95 ≤ 30 giây, p99 ≤ 60 giây | NFR-13-001 · FR-13-001 |
| TC-13-105 | Độ trễ log và trace tới tra cứu <!--k:perf-log-lag--> | 20.000 dòng log/giây, 5.000 span/giây | Log p95 ≤ 30 giây; trace p95 ≤ 60 giây | NFR-13-002, 003, 007 · FR-13-002, 003 |
| TC-13-106 | Tải bảng điều khiển chuẩn <!--k:perf-dashboard--> | 12 panel, 50 người xem đồng thời | p95 ≤ 3 giây | NFR-13-004 · FR-13-031 |
| TC-13-107 | Truy vấn trace và log <!--k:perf-query--> | Log 90 ngày khoảng 50 GB | Trace p95 ≤ 2 giây; log 1 giờ p95 ≤ 5 giây, 24 giờ ≤ 15 giây | NFR-13-005 · FR-13-026, 028 |
| TC-13-108 | Tra lượt gọi API <!--k:perf-access-query--> | F-ACCESS-5M nhân 365 ngày ngày (1,8 tỷ bản ghi) | Lọc 24 giờ, HTTT p95 ≤ 3 giây | NFR-13-006, 018 · FR-13-030 |
| TC-13-109 | Ghi bản ghi kiểm toán <!--k:perf-audit-write--> | 1.000 bản ghi/giây toàn nền tảng, 34 tenant, bản ghi 1,5 KB, 30 phút | p95 ≤ 2 giây, p99 ≤ 5 giây; 0 mất | NFR-13-008, 011 · FR-13-010, 011 |
| TC-13-110 | Truy vấn kiểm toán <!--k:perf-audit-query--> | 36,5 triệu bản ghi mỗi tenant | 31 ngày, 10.000 kết quả p95 ≤ 3 giây; 12 tháng p95 ≤ 10 giây | NFR-13-009, 017 · FR-13-020 |
| TC-13-111 | Kiểm tra toàn vẹn <!--k:perf-verify--> | Chuỗi 12 tháng, 36,5 triệu bản ghi | Tới đầu chuỗi từ neo gần nhất ≤ 2 phút; toàn chuỗi ≤ 60 phút; độ trễ ghi tăng ≤ 10 % | NFR-13-010 · FR-13-014 |
| TC-13-112 | Xuất 1 triệu bản ghi <!--k:perf-export--> | 1 triệu bản ghi, gói khoảng 200 MB | ≤ 15 phút; script ngoại tuyến xác minh được | NFR-13-031 · FR-13-024 |
| TC-13-113 | Thông lượng thu thập toàn nền tảng <!--k:perf-collect-all--> | 34 tenant mỗi tenant 250.000 chuỗi, 20.000 dòng/giây | Không mất mẫu có độ ưu tiên cao, collector đệm theo ERR-13-115 | NFR-13-007, 003 · FR-13-001 |

: TS-13-38 · Hiệu năng, tải và quy mô

### TS-13-39 · Chịu lỗi và không chặn data plane

**Mục tiêu.** Chứng minh PH-13 hay kho quan sát ngừng không làm gateway, runtime, DU lỗi và 0 bản ghi kiểm toán mất.

**Phủ.** NFR-13-011, 012, 013, 014; BR-13-003, 004, 015; FR-13-016; ERR-13-014.

#### TC-13-114 · Tắt toàn bộ `dh-platform` và LGTM 24 giờ, data plane vẫn chạy <!--k:chaos-control-down-->
- **Loại** Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** NFR-13-014, 011 · BR-13-015 · FR-13-016 · ERR-13-014
- **Tiền điều kiện / dữ liệu** Tải 100 lượt/giây qua gateway; tắt `dh-platform` và LGTM (rút gọn 2 giờ ở SIT, 24 giờ ở phát hành).
- **Bước**
  1. Tắt; giữ tải; bật lại.
- **Mong đợi** 0 lượt gọi API lỗi do PH-13; hộp thư đi giữ bản ghi kiểm toán; sau bật lại 0 mất, chuỗi nối đúng.

#### TC-13-115 · Mất 1 pod PH-13 hoặc 1 broker Kafka giữa lúc ghi <!--k:chaos-node-loss-->
- **Loại** Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** NFR-13-011, 012, 013 · FR-13-010, 011 · BR-13-004
- **Tiền điều kiện / dữ liệu** F-DU-SIM 100 bản ghi/giây.
- **Bước**
  1. Xóa 1 pod PH-13; sau đó tắt 1 broker; kiểm tra chuỗi.
- **Mong đợi** 0 mất, 0 trùng, `seq` liên tục; kiểm tra toàn vẹn `PASSED`.

#### TC-13-116 · Mất site chính, RPO ≤ 5 phút <!--k:dr-site-loss-->
- **Loại** Khả dụng · **Ưu tiên** P2 · **Tự động** Thủ công
- **Truy vết** NFR-13-012 · FR-13-013 · BR-13-013
- **Tiền điều kiện / dữ liệu** Hai site active–standby (ADR-034); diễn tập DR hằng năm.
- **Bước**
  1. Ngắt site chính; chuyển sang site dự phòng; kiểm tra chuỗi.
- **Mong đợi** RTO ≤ 4 giờ; mất không quá lô WORM gần nhất (RPO ≤ 5 phút); bản ghi chờ ở hộp thư đi của DU được ghi bù.

### TS-13-40 · Truy cập và giao diện

**Mục tiêu.** Chứng minh mọi màn UI-13 đạt WCAG 2.2 AA và dùng được bằng bàn phím, trình đọc màn hình, không chỉ dựa vào màu.

**Phủ.** NFR-13-029; FR-13-031, 042, 020, 047; UI-13-01…18.

#### TC-13-117 · axe-core mọi màn, không lỗi mức A, AA <!--k:a11y-axe-->
- **Loại** Truy cập · **Ưu tiên** P1 · **Tự động** A11Y
- **Truy vết** NFR-13-029 · FR-13-031 · UI-13-01…18
- **Tiền điều kiện / dữ liệu** U-T68-SO có đủ quyền; dữ liệu SIT.
- **Bước**
  1. Chạy axe-core ở mọi route UI-13-01…18 ở sáng, tối, độ thu phóng 200 %.
- **Mong đợi** 0 lỗi mức A, AA; tương phản chữ nền kính, nội dung dày dùng nền đặc (ADR-020).

#### TC-13-118 · Mười luồng chính bằng bàn phím và NVDA <!--k:a11y-nvda-->
- **Loại** Truy cập · **Ưu tiên** P2 · **Tự động** Thủ công
- **Truy vết** NFR-13-029 · FR-13-020, 026, 028, 031, 047 · UI-13-01, 07, 08, 10, 13
- **Tiền điều kiện / dữ liệu** NVDA; U-T68-TO; U-T68-AU.
- **Bước**
  1. Đi các luồng: xem tổng quan, tra log, mở trace, xử lý cảnh báo, tra kiểm toán, xuất bằng chứng.
- **Mong đợi** Hoàn tất không dùng chuột; biểu đồ có bảng thay thế và nhãn chữ; trạng thái không chỉ biểu thị bằng màu; thông báo lỗi đọc được.

### TS-13-41 · Bất biến nhật ký kiểm toán

**Mục tiêu.** Chứng minh không vai trò nào, kể cả quản trị cơ sở dữ liệu, sửa hoặc xóa được nhật ký ngoài tiến trình lưu trữ hợp lệ, và can thiệp bị phát hiện.

**Phủ.** BR-13-002, 019; FR-13-011, 013, 015; NFR-13-016, 023; ERR-13-109.

#### TC-13-119 · Mọi vai trò ứng dụng và quản trị chỉ `INSERT`, `SELECT` <!--k:immutable-roles-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** DB
- **Truy vết** BR-13-002, 019 · FR-13-011 · NFR-13-023
- **Tiền điều kiện / dữ liệu** `ph13_isolation_test.sql`; vai trò ứng dụng, quản trị nền tảng, DBA thử.
- **Bước**
  1. Mỗi vai trò chạy `UPDATE`, `DELETE`, `TRUNCATE`, `DROP PARTITION`, `ALTER TABLE` lên `audit_event` và bảng neo.
  2. Thử API và giao diện xóa, sửa bản ghi.
- **Mong đợi** Vai trò ứng dụng: lỗi quyền cho mọi lệnh ngoài `INSERT`, `SELECT`; không có API hay nút sửa, xóa; ngoại lệ duy nhất là tiến trình lưu trữ phân vùng đã xác minh.

#### TC-13-120 · Can thiệp bằng DBA thử bị phát hiện ≤ 24 giờ <!--k:immutable-detect-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** BR-13-002 · FR-13-015 · NFR-13-016 · ERR-13-109
- **Tiền điều kiện / dữ liệu** F-AUD-CUT; chỉ SIT.
- **Bước**
  1. DBA thử sửa một bản ghi cũ chưa neo; chờ kiểm tra hằng ngày.
- **Mong đợi** Phát hiện ≤ 24 giờ; ERR-13-109 Nghiêm trọng; bản sao WORM giữ giá trị gốc làm bằng chứng.

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Mỗi phiên 90 phút, hai người (một thao tác, một ghi chép), tập trung bốn vùng: luồng từ cảnh báo đến xử lý (UI-13-10…12), tra kiểm toán và xuất bằng chứng (UI-13-13, 14), đọc biểu đồ thác nước (UI-13-08), trang cài đặt (UI-13-17). Ghi lỗi theo mục 1.6.

### 6.2. Diễn tập đứt chuỗi

Ở SIT, cán bộ ATTT và quản trị tỉnh diễn tập quy trình ứng cứu khi nhận cảnh báo ERR-13-109 từ ca TC-13-027: xác minh bằng gói bằng chứng, đối chiếu bản WORM, lập báo cáo sự cố (TC-13-089). Đạt khi hoàn tất trong 60 phút và không ai cần sửa chuỗi.

### 6.3. Diễn tập sự cố giám sát

Tắt lần lượt Loki, Mimir, Alertmanager, kho WORM trong giờ làm việc, kiểm tra người trực nhận cảnh báo độc lập (TC-13-080) và nội dung runbook đủ năm mục dùng được.

### 6.4. Kiểm thử truy cập thủ công

Theo TC-13-118, bổ sung kiểm tra trên trình duyệt cũ nhất được hỗ trợ và màn hình 1366 × 768.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ vận hành Bus, Hub, APIM cũ tự thực hiện trên UAT. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem tổng quan hệ thống: bao nhiêu agent (đơn vị triển khai) hoạt động trên tổng số | LGC-BUS-014, LGC-APIM-026 | Thấy ngay ở trang đầu, thêm trạng thái từng thành phần | FR-13-031, 032 | TS-13-18, 19 |
| UAT-02 | Xem histogram bản tin thành công và thất bại theo thời gian | LGC-BUS-007 | Thấy theo giây đến theo ngày, chọn khoảng bất kỳ | FR-13-033 | TS-13-19 |
| UAT-03 | Xem CPU, bộ nhớ từng đơn vị triển khai và chi tiết route | LGC-BUS-015, 016, 017, 019 | Đủ số liệu của Bus cũ, bấm từ luồng xuống route | FR-13-032, 033 | TS-13-19 |
| UAT-04 | Xem thống kê theo endpoint và API gọi nhiều nhất | LGC-BUS-027 | Thấy lưu lượng, bản tin gần nhất, lỗi | FR-13-034 | TS-13-19 |
| UAT-05 | Tìm log của một luồng trong giờ qua và đọc ngữ cảnh | LGC-BUS-029, 038, LGC-NFR-004 | Tìm được trong 3 thao tác, bấm `trace_id` sang trace | FR-13-026, 027, 028 | TS-13-15, 16 |
| UAT-06 | Xem biểu đồ CPU, bộ nhớ của Hub và cụm Kafka | LGC-HUB-005, 006 | Thấy cùng màn hạ tầng, có cảnh báo ngưỡng | FR-13-038 | TS-13-21 |
| UAT-07 | Xem danh sách gateway, chi tiết và tài nguyên | LGC-APIM-023; 024, 025 | Đủ nút, CPU, heap, kết nối như APIM cũ | FR-13-036, 037 | TS-13-21 |
| UAT-08 | Tra mọi request vào một API của ứng dụng và xem chi tiết | LGC-APIM-022; LGC-PAY-021 | Lọc theo HTTT, API, mã lỗi trong 3 giây; không lộ nội dung | FR-13-030 | TS-13-17 |
| UAT-09 | Tra "ai đã làm gì" một đối tượng trong một tuần | LGC-APIM-027 | Có lý do, thấy trước sau, xác minh băm | FR-13-020, 021, 022 | TS-13-11, 12 |
| UAT-10 | Nhận thông báo khi mất kết nối nhà cung cấp thanh toán | LGC-PAY-009 | Cảnh báo có runbook, gửi đúng người trực ≤ 60 giây | FR-13-043, 046 | TS-13-24, 25 |
| UAT-11 | Lấy log của một tháng đã lưu để kiểm tra lại | LGC-NFR-005 | Truy vết lại được; log cũ trên WORM; không phải sao lưu thủ công | FR-13-018 | TS-13-10 |
| UAT-12 | Xuất bằng chứng ký số cho thanh tra | LGC-APIM-027 | Gói tự xác minh ngoại tuyến, kiểm toán viên tự làm được | FR-13-024 | TS-13-13 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

Chương này sinh tự động từ chính các ca ở chương 4 và 5 bằng `ph13/tools/gen_matrix.py`; không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-13. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph13/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-13-001 | Thu thập chỉ số từ mọi thành phần | M | LGC-APIM-025, LGC-BUS-030 | 001 | 002 | 003, 005, 104, 113 | Có |
| FR-13-002 | Thu thập log có cấu trúc | M | LGC-BUS-029, LGC-NFR-004 | 001 | 121 | 005, 105 | Có |
| FR-13-003 | Thu thập vết truy nguyên | M | LGC-BUS-038 | 001, 004 | 121 | 105 | Có |
| FR-13-004 | Lấy mẫu trace theo đuôi | M | mới | 004 | 121 | — | Có |
| FR-13-005 | Che dữ liệu Nhạy cảm và quét phát hiện lọt | M | mới | 006 | 007, 008 | 097 | Có |
| FR-13-006 | Thu siêu dữ liệu lượt gọi API | M | LGC-APIM-022, LGC-BUS-027 | 009 | 010 | — | Có |
| FR-13-007 | Thu chỉ số thành phần nền và hạ tầng | M | LGC-APIM-025, LGC-BUS-016, LGC-HUB-005… | 011 | 011 | — | Có |
| FR-13-008 | Kiểm tra tổng hợp mỗi phút | M | mới | 012 | 013, 014 | — | Có |
| FR-13-009 | Cách ly dữ liệu quan sát theo tenant | M | mới | 001 | 002, 015 | 100 | Có |
| FR-13-010 | Tiếp nhận và xác thực bản ghi kiểm toán | M | LGC-APIM-027 | 016 | 008, 017 | 018, 097, 109, 115 | Có |
| FR-13-011 | Ghi chỉ-thêm và nối chuỗi băm theo tenant | M | LGC-APIM-027 | 016, 127 | 017 | 019, 100, 109, 115, 119 | Có |
| FR-13-012 | Neo băm ký hằng giờ | M | mới | 020, 127 | 021 | — | Có |
| FR-13-013 | Sao lô sang kho WORM | M | LGC-APIM-027, LGC-NFR-005 | 022, 127 | 023 | 100, 116 | Có |
| FR-13-014 | Kiểm tra toàn vẹn chuỗi | M | mới | 024, 026, 127 | 025, 027, 131 | 102, 111 | Có |
| FR-13-015 | Xử lý đứt chuỗi và neo không khớp | M | mới | 029 | 027, 028, 129, 131 | 120 | Có |
| FR-13-016 | Chịu lỗi và đệm bản ghi khi PH-13 hoặc kho ngừng | M | mới | 030 | 023, 031, 034 | 114 | Có |
| FR-13-017 | Đối chiếu số bản ghi với bộ đếm của DU | M | mới | 032 | 033 | — | Có |
| FR-13-018 | Vòng đời lưu giữ và lưu trữ phân vùng | M | LGC-NFR-005 | 035 | 036 | — | Có |
| FR-13-019 | Kiểm toán chính thao tác của PH-13 | M | mới | 037 | 122 | — | Có |
| FR-13-062 | Khôi phục chuỗi kiểm toán sau sự cố mất dữ liệu | C | mới | 127, 128 | 129, 130, 131 | — | Có |
| FR-13-020 | Tra cứu nhật ký kiểm toán | M | LGC-APIM-027 | 038 | 039, 065 | 041, 099, 101, 102, 110, 118 | Có |
| FR-13-021 | Xem chi tiết bản ghi và xác minh băm | M | LGC-APIM-027 | 038 | 039 | — | Có |
| FR-13-022 | Lịch sử theo đối tượng cho tab "Lịch sử" | M | LGC-PAY-019 | 042 | 043 | 099 | Có |
| FR-13-023 | Tra theo đối tượng bị tra cứu | S | mới | 040 | — | — | Có |
| FR-13-024 | Xuất bằng chứng kiểm toán ký số | M | LGC-APIM-027 | 044 | 045, 046 | 102, 112 | Có |
| FR-13-025 | Báo cáo truy cập liên tenant | S | mới | 047 | 048 | — | Có |
| FR-13-026 | Tra log tập trung | M | LGC-BUS-029, LGC-NFR-004 | 049 | 050, 065 | 099, 107, 118 | Có |
| FR-13-027 | Chi tiết dòng log, ngữ cảnh và theo dõi trực tiếp | S | LGC-BUS-029 | 051 | — | — | Có |
| FR-13-028 | Tìm trace và biểu đồ thác nước | M | LGC-BUS-038 | 052 | 053 | 099, 107, 118 | Có |
| FR-13-029 | Liên kết chỉ số, trace, log, kiểm toán bằng trace_id | M | mới | 052 | 053 | — | Có |
| FR-13-030 | Tra nhật ký truy cập API | M | LGC-APIM-022, LGC-PAY-021 | 054 | 055 | 099, 108 | Có |
| FR-13-031 | Bảng điều khiển tổng quan nền tảng | M | LGC-APIM-026, LGC-BUS-014 | 056 | 057 | 106, 117, 118 | Có |
| FR-13-032 | Bảng điều khiển đơn vị triển khai và tài nguyên | M | LGC-BUS-014, LGC-BUS-015, LGC-BUS-016… | 058 | 059 | — | Có |
| FR-13-033 | Bảng điều khiển theo luồng và route | M | LGC-BUS-007, LGC-BUS-019 | 058 | 059 | — | Có |
| FR-13-034 | Thống kê theo endpoint | M | LGC-BUS-027 | 058 | 059 | — | Có |
| FR-13-035 | Bảng điều khiển theo API và theo HTTT | M | LGC-APIM-022, LGC-APIM-026 | 060 | 061 | 099 | Có |
| FR-13-036 | Danh sách và chi tiết nút gateway | M | LGC-APIM-023, LGC-APIM-024 | 062 | 063 | — | Có |
| FR-13-037 | Giám sát tài nguyên nút gateway | M | LGC-APIM-025 | 062 | 063 | — | Có |
| FR-13-038 | Bảng điều khiển cụm Kafka | M | LGC-HUB-005, LGC-HUB-006 | 062 | 063 | — | Có |
| FR-13-039 | Bảng điều khiển hoạt động nghiệp vụ | M | mới | 064 | 065 | — | Có |
| FR-13-040 | Bảng điều khiển an ninh | M | mới | 064 | 007, 065 | — | Có |
| FR-13-041 | Quản lý bộ dashboard theo tenant | S | mới | 066 | 067 | — | Có |
| FR-13-042 | Quản lý luật cảnh báo kèm runbook, chạy thử | M | mới | 068, 123 | 069, 070, 071, 126 | 101 | Có |
| FR-13-043 | Bộ luật cảnh báo chuẩn của nền tảng | M | LGC-PAY-009 | 123 | 070 | — | Có |
| FR-13-044 | Đánh giá luật, chống nhấp nháy, sinh cảnh báo | M | mới | 072 | 075 | — | Có |
| FR-13-045 | Phân mức, gom nhóm, chống lặp | M | mới | 072, 073 | 124 | — | Có |
| FR-13-046 | Gửi thông báo theo lịch trực và leo thang | M | mới | 072, 073, 074 | 075, 124 | — | Có |
| FR-13-047 | Xử lý cảnh báo: xác nhận, đã xử lý, tạm ẩn | M | mới | 076 | 077, 124, 126 | 101, 118 | Có |
| FR-13-048 | Quản lý lịch trực, nhóm nhận, kênh thông báo | M | mới | 078 | 079 | — | Có |
| FR-13-049 | Giám sát chính hệ thống giám sát | M | mới | 080 | 075 | — | Có |
| FR-13-050 | Thống kê hiệu quả cảnh báo | S | mới | 081 | — | — | Có |
| FR-13-051 | Nạp và tinh chỉnh bộ luật phát hiện UC-SEC | M | mới | 082 | 083 | — | Có |
| FR-13-052 | Phát hiện bất thường từ bản ghi kiểm toán | M | mới | 084 | 125 | — | Có |
| FR-13-053 | Xử lý cảnh báo an ninh, đề xuất tạm ngừng HTTT | M | mới | 084, 085, 132 | 086, 133, 134, 135 | 101, 102 | Có |
| FR-13-054 | Đẩy log và cảnh báo an ninh sang SIEM, SOC | M | mới | 087 | 088 | — | Có |
| FR-13-055 | Mẫu báo cáo sự cố và thông báo vi phạm DLCN | C | mới | 089 | 089 | — | Có |
| FR-13-056 | Cung cấp số liệu cho PH-16 | M | mới | 090 | 091 | — | Có |
| FR-13-057 | Cung cấp ngữ cảnh chẩn đoán cho PH-18 | M | mới | 090 | 091 | — | Có |
| FR-13-058 | Cung cấp sức khỏe thành phần cho phân hệ khác | S | mới | — | 057 | — | Có |
| FR-13-059 | Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới | M | mới | 092 | 093 | — | Có |
| FR-13-060 | Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập | S | mới | 094 | 034, 094 | — | Có |
| FR-13-061 | Tham số và hạn mức quan sát theo tenant | S | mới | 095 | 014, 096 | 101 | Có |

: Yêu cầu chức năng → test case

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng giám sát, nhật ký của Bus (`LGC-BUS`), Hub (`LGC-HUB`), APIM (`LGC-APIM`), PayGov (`LGC-PAY`) và yêu cầu nhật ký (`LGC-NFR`) được truy tới FR mới và tới ca tự động, ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-APIM-022 | 006, 030, 035 | 009, 054, 060 | UAT-08 |
| LGC-APIM-023 | 036 | 062 | UAT-07 |
| LGC-APIM-024 | 036 | 062 | — |
| LGC-APIM-025 | 001, 007, 037 | 001, 011, 062 | — |
| LGC-APIM-026 | 031, 035 | 056, 060 | UAT-01 |
| LGC-APIM-027 | 010, 011, 013, 020, 021, 024 | 016, 022, 038, 044, 127 | UAT-09, UAT-12 |
| LGC-BUS-007 | 033 | 058 | UAT-02 |
| LGC-BUS-014 | 031, 032 | 056, 058 | UAT-01 |
| LGC-BUS-015 | 032 | 058 | UAT-03 |
| LGC-BUS-016 | 007, 032 | 011, 058 | UAT-03 |
| LGC-BUS-017 | 032 | 058 | UAT-03 |
| LGC-BUS-019 | 033 | 058 | UAT-03 |
| LGC-BUS-027 | 006, 034 | 009, 058 | UAT-04 |
| LGC-BUS-029 | 002, 026, 027 | 001, 049, 051 | UAT-05 |
| LGC-BUS-030 | 001 | 001 | — |
| LGC-BUS-038 | 003, 028 | 001, 004, 052 | UAT-05 |
| LGC-HUB-005 | 007, 038 | 011, 062 | UAT-06 |
| LGC-HUB-006 | 007, 038 | 011, 062 | UAT-06 |
| LGC-NFR-004 | 002, 026 | 001, 049 | UAT-05 |
| LGC-NFR-005 | 013, 018 | 022, 035, 127 | UAT-11 |
| LGC-PAY-009 | 043 | 123 | UAT-10 |
| LGC-PAY-019 | 022 | 042 | — |
| LGC-PAY-021 | 030 | 054 | UAT-08 |

: Chức năng hệ cũ → yêu cầu → test case

### 8.3. Quy tắc nghiệp vụ → test case

Bảng sau cho biết mỗi quy tắc nghiệp vụ BR-13 được kiểm bởi những ca nào; quy tắc chưa có ca được báo ở đầu ra của tập lệnh sinh bảng và phải bằng không trước khi chốt bản.

| Mã | Test case |
|---|---|
| BR-13-001 | 017, 018, 031, 032, 033 |
| BR-13-002 | 035, 036, 119, 120, 127, 129 |
| BR-13-003 | 031 |
| BR-13-004 | 016, 030, 115 |
| BR-13-005 | 040 |
| BR-13-006 | 024, 037, 038, 102, 122 |
| BR-13-007 | 038, 040 |
| BR-13-008 | 068, 069, 123 |
| BR-13-009 | 068, 069 |
| BR-13-010 | 004, 121 |
| BR-13-011 | 006, 007, 009, 097, 121 |
| BR-13-012 | 027, 028, 029 |
| BR-13-013 | 020, 021, 022, 028, 116 |
| BR-13-014 | 044, 045 |
| BR-13-015 | 005, 010, 114 |
| BR-13-016 | 011, 013, 059, 063 |
| BR-13-017 | 017, 019, 043, 092, 098, 099, 100, 103 |
| BR-13-018 | 047, 048 |
| BR-13-019 | 119 |
| BR-13-020 | 014, 022, 035, 094 |
| BR-13-021 | 076, 077, 124 |
| BR-13-022 | 074, 075, 079 |
| BR-13-023 | 076, 077, 081 |
| BR-13-024 | 085, 086, 132, 133, 134, 135 |
| BR-13-025 | 082, 083, 125 |
| BR-13-026 | 002, 003 |
| BR-13-027 | 001, 002 |
| BR-13-028 | 073 |
| BR-13-029 | 041, 046, 102 |
| BR-13-030 | 015, 048, 055, 057, 061, 099 |
| BR-13-031 | 071 |
| BR-13-032 | 066, 070, 123 |
| BR-13-033 | 026, 027, 127, 128, 129, 130 |
| BR-13-034 | 087, 088 |
| BR-13-035 | 008, 097 |

: Quy tắc nghiệp vụ → test case

### 8.4. Mã lỗi → test case

Bảng sau cho biết mỗi mã lỗi ERR-13 được kích hoạt và kiểm thông điệp ở những ca nào; mã lỗi chạy nền (101…126) được kiểm qua chỉ số và cảnh báo thay vì mã HTTP.

| Mã | Test case |
|---|---|
| ERR-13-001 | 043, 053, 055, 059, 061, 063, 071, 089, 098, 099 (+1) |
| ERR-13-002 | 050, 069, 079, 088 |
| ERR-13-003 | 126, 134 |
| ERR-13-004 | 039, 050, 055, 091 |
| ERR-13-005 | 039, 050, 055, 059, 091 |
| ERR-13-006 | 050, 091 |
| ERR-13-007 | 014, 069, 077, 096 |
| ERR-13-008 | 025, 046, 069, 083, 086, 089, 094, 096 |
| ERR-13-009 | 025, 046, 057, 061, 063, 065, 067, 077, 083, 096 (+3) |
| ERR-13-010 | 057, 101 |
| ERR-13-011 | 041, 050, 091 |
| ERR-13-012 | 039, 046, 122 |
| ERR-13-013 | 039, 046 |
| ERR-13-014 | 045, 114, 133 |
| ERR-13-015 | 039, 041, 051, 091 |
| ERR-13-016 | 067 |
| ERR-13-017 | 069 |
| ERR-13-018 | 069 |
| ERR-13-019 | 070 |
| ERR-13-020 | 077, 086 |
| ERR-13-021 | 077 |
| ERR-13-022 | 077 |
| ERR-13-023 | 086 |
| ERR-13-024 | 083 |
| ERR-13-025 | 046 |
| ERR-13-026 | 045 |
| ERR-13-027 | 046 |
| ERR-13-028 | 025, 039, 046, 083, 086, 102 |
| ERR-13-029 | 039 |
| ERR-13-030 | 053, 091 |
| ERR-13-031 | 039 |
| ERR-13-032 | 025 |
| ERR-13-033 | 079 |
| ERR-13-034 | 079 |
| ERR-13-035 | 067 |
| ERR-13-036 | 015, 043, 048, 098, 099 |
| ERR-13-037 | 050, 069, 079, 088, 093 |
| ERR-13-038 | 126 |
| ERR-13-039 | 088 |
| ERR-13-040 | 014, 096 |
| ERR-13-041 | 096 |
| ERR-13-042 | 093 |
| ERR-13-043 | 034, 094 |
| ERR-13-044 | 043, 057, 091, 093, 094, 098, 103 |
| ERR-13-101 | 017 |
| ERR-13-102 | 017 |
| ERR-13-103 | 017 |
| ERR-13-104 | 017 |
| ERR-13-105 | 008, 097 |
| ERR-13-106 | 019 |
| ERR-13-107 | 021 |
| ERR-13-108 | 023 |
| ERR-13-109 | 027, 029, 120, 127, 129, 131 |
| ERR-13-110 | 028, 129 |
| ERR-13-111 | 033 |
| ERR-13-112 | 007, 097 |
| ERR-13-113 | 002 |
| ERR-13-114 | 002, 003 |
| ERR-13-115 | 005 |
| ERR-13-116 | 004, 121 |
| ERR-13-117 | 004, 121 |
| ERR-13-118 | 010 |
| ERR-13-119 | 075 |
| ERR-13-120 | 075 |
| ERR-13-121 | 074 |
| ERR-13-122 | 080, 088 |
| ERR-13-123 | 080 |
| ERR-13-124 | 013 |
| ERR-13-125 | 036 |
| ERR-13-126 | 018 |

: Mã lỗi → test case

### 8.5. Yêu cầu phi chức năng → test case

Bảng sau cho biết mỗi yêu cầu phi chức năng NFR-13 được chứng minh bằng ca nào, chủ yếu ở kịch bản hiệu năng, chịu lỗi và truy cập (mục 5).

| Mã | Test case |
|---|---|
| NFR-13-001 | 104 |
| NFR-13-002 | 105 |
| NFR-13-003 | 004, 105, 113 |
| NFR-13-004 | 056, 106 |
| NFR-13-005 | 049, 052, 107 |
| NFR-13-006 | 054, 108 |
| NFR-13-007 | 005, 105, 113 |
| NFR-13-008 | 016, 019, 109 |
| NFR-13-009 | 041, 110 |
| NFR-13-010 | 026, 111 |
| NFR-13-011 | 023, 030, 109, 114, 115 |
| NFR-13-012 | 115, 116 |
| NFR-13-013 | 005, 080, 115 |
| NFR-13-014 | 010, 031, 114 |
| NFR-13-015 | 072 |
| NFR-13-016 | 026, 027, 120 |
| NFR-13-017 | 110 |
| NFR-13-018 | 108 |
| NFR-13-019 | 095 |
| NFR-13-020 | 002, 003 |
| NFR-13-021 | 006, 097 |
| NFR-13-022 | 015, 099, 100 |
| NFR-13-023 | 021, 022, 119 |
| NFR-13-024 | 008, 097 |
| NFR-13-025 | 037, 122 |
| NFR-13-026 | 032 |
| NFR-13-027 | 001, 011, 121 |
| NFR-13-028 | 081, 123 |
| NFR-13-029 | 117, 118 |
| NFR-13-030 | 012, 095 |
| NFR-13-031 | 044, 112 |

: Yêu cầu phi chức năng → test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Mã kiểm thử tự động đặt cạnh mã nguồn của từng mô-đun theo cấu trúc dưới đây; khóa `k:` ở tiêu đề mỗi ca là tên phương thức hoặc tệp kiểm thử tương ứng.

| Thư mục | Nội dung |
|---|---|
| `dh-platform/src/test/java/.../audit` | UT, IT chuỗi băm, tiếp nhận, neo, WORM, đối chiếu |
| `dh-platform/src/test/java/.../observability` | Luật cảnh báo, che dữ liệu, trạng thái cảnh báo |
| `tests/db/ph13_isolation_test.sql` | RLS, vai trò chỉ `INSERT`, `SELECT` |
| `tests/e2e/ph13/` | Playwright theo UI-13-01…18 |
| `tests/perf/ph13/` | k6 cho TS-13-38 |
| `tests/chaos/ph13/` | Chaos Mesh cho TS-13-09, 39 |
| `tests/contract/` | OpenAPI, AsyncAPI của PH-13 (CI-5) |

: Tổ chức mã kiểm thử

### 9.2. Mẫu ca dò mồi (JUnit)

Ca dò mồi chứng minh dữ liệu Nhạy cảm không lọt ra log, trace hay chỉ số; ví dụ dưới đây là khung để kỹ sư viết các ca còn lại của TS-13-02.

```java
@Test
void canarySweep() {
    var canary = "DH-CANARY-sweep";
    seed.sendLog(tenant("t68"), logWith(canary));
    seed.sendAudit(tenant("t68"), auditWith("after.password", canary));
    await().atMost(90, SECONDS).untilAsserted(() -> {
        assertThat(loki.query("{tenant=\"t68\"} |= \"%s\"".formatted(canary))).isEmpty();
        assertThat(clickhouse.countContaining(canary)).isZero();
        assertThat(chain.countContaining("t68", canary)).isZero(); // bản ghi bị cách ly, không vào chuỗi
    });
}
```

### 9.3. Mẫu ca kiểm tra chuỗi băm (JUnit)

Ví dụ dưới đây kiểm tính liên tục của chuỗi băm theo tenant; các ca phát hiện can thiệp ở TS-13-07, 08 dùng cùng khung.

```java
@Test
void chainHashIsContinuous() {
    var records = chain.readAll("t68");
    for (int i = 1; i < records.size(); i++) {
        assertThat(records.get(i).seq()).isEqualTo(records.get(i - 1).seq() + 1);
        assertThat(records.get(i).hash()).isEqualTo(sha256(records.get(i).prevHash() + canonical(records.get(i))));
        assertThat(records.get(i).prevHash()).isEqualTo(records.get(i - 1).hash());
    }
}
```

### 9.4. Mẫu ca giao diện (Playwright)

Ví dụ dưới đây kiểm một ca giao diện có xác thực lại phiên và lý do bắt buộc; các ca giao diện khác theo cùng khung.

```ts
test('tra kiểm toán bắt buộc lý do', async ({ page }) => {
  await login(page, 'U-T68-AU', { stepUp: true });
  await page.goto('/giam-sat/kiem-toan');
  await page.getByRole('button', { name: 'Tra cứu' }).click();
  await expect(page.getByText('Cần nhập lý do')).toBeVisible();
});
```

### 9.5. Sinh ma trận, Gherkin, bảng tính

Ma trận truy vết, tệp Gherkin và bảng tính ca kiểm thử đều được sinh từ chính các ca ở chương 4 và 5 bằng các lệnh dưới đây, nên không bao giờ lệch với nội dung tài liệu.

| Lệnh | Kết quả |
|---|---|
| `python3 ph13/tools/number_tcs.py` | Cấp số `TC-13-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph13/tools/fill_doc.py` | Ghi mục 3.1, số kịch bản, số ca và mục 8; in ra stderr BR, ERR, NFR chưa có ca |
| `python3 ph13/tools/gen_gherkin.py` | `ph13/gherkin/ts-13-nn.feature` |
| `python3 ph13/tools/gen_xlsx.py` | `ph13/D05-02-PH13-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

## 10. Câu hỏi mở

> **Câu hỏi mở Q13-40:** Ca TC-13-116 (mất site chính) và các ca chịu lỗi 4 giờ chạy rút gọn ở SIT (30 phút đến 2 giờ). Giả định: chạy đủ 4 giờ và 24 giờ một lần trước mỗi đợt phát hành ở môi trường PERF; cần chủ đầu tư xác nhận có cấp được cụm PERF đủ thời gian.

> **Q13-41 (đã chốt 27/11/2026):** IE giữ `PERM-13-dashboard` (● ở D02-08 hiện hành), giới hạn ở bảng điều khiển của luồng và HTTT do mình thiết kế; hạ tầng chung hiển thị ở mức tenant theo BR-13-030; TC-13-063 theo đúng quyết định này. *Câu hỏi gốc:* Quyền xem hạ tầng của IE chưa chốt: D02-08 cho `PERM-13-dashboard` mọi vai trò nhưng FRS phân biệt dữ liệu tenant và hạ tầng chung.

> **Câu hỏi mở Q13-42:** Số lượng nút thử trong bộ kiểm thử rò rỉ API (TC-13-099) liệt kê 24 API đại diện; cần quyết định có sinh bộ kiểm thử tự động từ OpenAPI để phủ 100 % API đọc không. Giả định: có, bổ sung ở CI-5 sau MVP.

## 11. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các đề nghị dưới đây thuộc tài liệu dùng chung hoặc tập của phân hệ khác; tập này không sửa trực tiếp, chỉ ghi để luồng tài liệu chung và chủ các tập tương ứng xử lý.

| Tài liệu | Đề nghị |
|---|---|
| D05-01 | Thêm vào kế hoạch kiểm thử: hồ sơ PERF cho ca ghi kiểm toán 1.000 bản ghi/giây toàn nền tảng, 34 tenant (TS-13-38) và ca chịu lỗi 4 giờ (TS-13-09, 39) |
| D04-02 | Thêm cổng CI chạy `ph13_isolation_test.sql` và bộ dò mồi `DH-CANARY` (TS-13-35, 36, 41) mỗi lần phát hành |
| D02-08 | Xác nhận phạm vi `PERM-13-dashboard` của IE với hạ tầng (Q13-41) |
| D00-04 | Cập nhật bảng dải mã sau khi tập này chạy `--cap-nhat-so-tra-cuu` (TS-13, TC-13) |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 41 kịch bản, 12 UAT, ma trận truy vết sinh tự động, công cụ `ph13/tools/` |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà chéo bảy tập PH-13: chương 0 tách thành các mục theo khuôn; thêm UC-13-08 vào TC-13-027, 028, 029; thêm chú thích và đoạn mở cho bảng ma trận (bộ sinh `gen_matrix.py`, `fill_doc.py` đã sửa để giữ chú thích khi sinh lại) |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: tầng kiểm thử CSDL ghi ph13_isolation_test.sql và ca rò rỉ ClickHouse T90, T91; chốt câu hỏi mở đợt đồng bộ: Q451 |
| 0.4 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bổ sung ca cho FR-13-062, UC-13-43 (TC-13-127…131) và gửi đề xuất tạm ngừng qua API-01-089 (TC-13-132, 133); thêm F-AUD-LAG, U-OPS, PH-01 giả lập (133 ca) |
| 0.5 | 27/11/2026 | Nhóm viết tài liệu (Claude) | FR-13-053: thêm ca đề xuất từ cảnh báo mức thấp hơn HIGH (ERR-13-003) và ca PH-01 trả ERR-01-005 (TC-13-134, 135); công tắc `not-allowed` của PH-01 giả lập |
