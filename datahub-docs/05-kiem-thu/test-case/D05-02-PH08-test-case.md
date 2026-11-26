---
ma_tai_lieu: D05-02-PH08
ten: Kịch bản và test case phân hệ PH-08 Chất lượng dữ liệu
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, chuyên viên quản lý dữ liệu, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-08
mo_ta: Kịch bản và test case chức năng, công thức điểm, kiểm tra trực tuyến, che giá trị Nhạy cảm, cô lập tenant, hiệu năng và nghiệm thu của phân hệ Chất lượng dữ liệu, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH08 FRS; D02-04-PH08 Use case; D03-03-PH08 CSDL; D03-04-PH08 API; D03-06-PH08 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH08 · Kịch bản và test case Chất lượng dữ liệu

## Tóm tắt cho hội đồng thẩm định

Phần này viết cho hội đồng thẩm định: tài liệu chứng minh điều gì, phủ đến đâu và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản và số ca do công cụ sinh lại từ chính các ca nên luôn khớp với chương 4 và 5.

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-08 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH08 bản 0.1: 61 FR (36 mức M, 21 mức S, 4 mức C), 35 quy tắc BR-08, 20 yêu cầu phi chức năng NFR-08.
- Điểm chất lượng tính đúng công thức: điểm chiều theo `POOLED`, điểm tổng có trọng số 0,20/0,20/0,15/0,10/0,15/0,20, chiều bị bỏ qua (`SKIPPED`) không bị tính bằng 0 mà chuẩn hóa trọng số và gắn cờ `INCOMPLETE_DIMENSIONS`; ví dụ số cụ thể cho điểm 91,45 và 93,06.
- Không giá trị Nhạy cảm nào ở dạng rõ trong bản ghi lỗi, hồ sơ, sự kiện, nhật ký hay tệp xuất; tenant này không đọc được dữ liệu đo của tenant khác ở API, CSDL (RLS), Kafka và bộ đệm quy tắc; bốn mắt không có đường vòng.
- Kiểm tra trực tuyến đạt p95 ≤ 50 ms, báo cáo năm chỉ công bố khi đủ lần đo toàn bộ, và vòng khắc phục từ lỗi đến phiếu, đo kiểm chứng, báo cáo chạy khép kín.

**Phạm vi.** Gồm <!--gen:so-ts-->35<!--/gen--> kịch bản với <!--gen:so-tc-->152 (TC-08-001…152; 97 ca P1)<!--/gen--> test case và 8 kịch bản nghiệm thu người dùng (UAT-01…08). Mọi FR mức M có ít nhất một ca dương và một ca âm, mọi FR mức S, C có ít nhất một ca; ma trận mục 8 sinh bằng `ph08/tools/gen_matrix.py`. PH-08 là năng lực mới của Đợt 3 (hệ cũ không có chức năng chất lượng dữ liệu), nên mục 7 là nghiệm thu theo vai trò thay cho nghiệm thu tương đương hệ cũ.

**Căn cứ.** FRS D02-03-PH08, use case D02-04-PH08, CSDL D03-03-PH08 (test cô lập `ph08_isolation_test.sql`), tập API D03-04-PH08 và màn hình D03-06-PH08 (đang soạn song song, mã API-08 theo FRS 9.4, UI-08 theo FRS 10.1), ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01 (cổng `RG-1…5`); Luật Dữ liệu 60/2024, Nghị định 165/2025, Nghị định 278/2025 (hạn chuẩn hóa dữ liệu 31/12/2026); cấu trúc theo ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Năm nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- công thức điểm và xử lý chiều bị bỏ qua (TS-08-12, TS-08-13);
- cô lập tenant ở API, RLS, Kafka, bộ đệm (TS-08-28) và phân quyền, bốn mắt (TS-08-29);
- không lộ giá trị Nhạy cảm, dấu vân tay lỗi ổn định (TS-08-30);
- báo cáo năm bị chặn đúng khi thiếu lần đo `FULL`, thiếu chiều hoặc chỉ có mẫu (TS-08-25);
- kiểm tra trực tuyến đúng chế độ `STRICT`, `ADVISORY`, `FAIL_OPEN`, `FAIL_CLOSED` và p95 ≤ 50 ms (TS-08-15, 16, 32).

Dữ liệu và quy mô dùng giả định GĐ-01…07 (tỉnh vừa, 200 HTTT) và giả định riêng ở mục 2; các ca là tiêu chí nghiệm thu của công việc mới ở Đợt 3.

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả kịch bản và test case của PH-08 Chất lượng dữ liệu để nghiệm thu chức năng, công thức điểm, kiểm tra trực tuyến, an toàn dữ liệu và hiệu năng.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư `dh-data`, `dh-console` đối chiếu hành vi; cán bộ ATTT kiểm chương 5; chuyên viên quản lý dữ liệu và chủ đầu tư dùng mục 7 và 9.5 để nghiệm thu.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; DS cán bộ phụ trách chất lượng; DA người duyệt; DO tổ chức chủ quản dữ liệu; TA quản trị tenant; PA quản trị nền tảng; CDE phần tử dữ liệu trọng yếu; RLS an toàn theo hàng; `POOLED` cách tính điểm chiều bằng tổng đạt trên tổng áp dụng; `fingerprint` dấu vân tay lỗi; canary chuỗi mồi phát hiện rò rỉ.

### 0.4. Tài liệu tham chiếu

FRS D02-03-PH08 (mã FR, BR, NFR, ERR, EVT, API-08, UI-08 và câu thông báo), use case D02-04-PH08 (khung kịch bản), CSDL D03-03-PH08 (bảng, test cô lập), kế hoạch kiểm thử D05-01, ma trận phân quyền D02-08, khuôn K-TC và K-TRINH-BAY.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng TS-08-01…27 (ứng một một với UC-08-01…27); 5 ca phi chức năng TS-08-28…35; 6 thủ công; 7 nghiệm thu; 8 ma trận; 9 tự động hóa; 10 đề nghị đồng bộ và câu hỏi mở.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là mô-đun `vn.datahub.data.dq` của `dh-data` (các thành phần `dq-scan`, `dq-worker`, `dq-inline`, `dq-finding`, `dq-alert`), schema `ph08_dq` của `pg-core` với RLS theo `tenant_id` (31 bảng), 128 API dưới `/api/dq/v1` (API-08-001…128), 14 topic `{tenant}.dq.*` (EVT-08-01…14) và 20 màn hình dưới `/du-lieu/chat-luong` (UI-08-01…20). Ngoài phạm vi: nội dung bản ghi vàng (PH-06), bảng mã (PH-07), kết nối nguồn (PH-05), che khi trả dữ liệu (PH-09), kênh thông báo (PH-13), KPI tổng hợp (PH-16); các phân hệ này được giả lập (mục 2.5) và ca của chúng thuộc tập D05-02 tương ứng.

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca; chiến lược chung theo D05-01.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Công thức điểm, dấu vân tay, che giá trị, dịch quy tắc sang SQL, CEL |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka KRaft, Keycloak, Garage, WireMock) | Dịch vụ với CSDL, hộp gửi, hộp nhận, kho tệp |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph08/test/` | RLS, bất biến, bảng chỉ thêm, phân vùng |
| API | API | REST Assured | Mọi API-08 |
| Kafka | KT | `kcat`, client Java OAUTHBEARER | ACL theo tiền tố, nội dung sự kiện |
| Đầu cuối | E2E | Playwright, axe-core | UI-08-01…20 |
| Hiệu năng | k6 | k6, pgbench, đồng hồ lần đo | NFR-08-001…004, 010…014, 019 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | Pod, Kafka, PH-05, 07, 13, 16 |
| Bảo mật | ZAP | OWASP ZAP, quét canary | Rò rỉ giá trị Nhạy cảm, quyền |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường phục vụ các mức ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, API, KT, E2E khói | `dh-data` 1 bản sao; PH-05, 06, 07, 09, 13, 16, 20 là WireMock; nguồn đo là PostgreSQL bản sao chỉ đọc |
| STAGING | E2E đầy đủ, Chaos, ZAP, UAT dợt | Giống sản xuất về số bản sao và chính sách mạng |
| PERF | k6, đo lô quy mô | `dh-data` 2 bản sao 4 vCPU, 8 GB; bốn bộ thực thi; `pg-core` 8 vCPU, 32 GB; nguồn bản sao chỉ đọc cùng vùng mạng (giả định); tenant T97…T99 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** Hợp đồng API-08 và lược đồ sự kiện đã gắn phiên bản; bộ dữ liệu mục 2 nạp được bằng API (không chèn SQL, trừ bộ RLS); `clock-sim` đẩy được đồng hồ cho ca có hẹn giờ.
- **Ra.** Theo cổng D05-01: `RG-1` mọi ca API, DB và rò rỉ chéo tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-08-001…020 ở PERF; `RG-4` UAT mục 7 ký và 8 tiêu chí chấp nhận cấp phân hệ ở FRS mục 14 đạt (đối chiếu ở mục 9.5).

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-08-nn`, test case `TC-08-nnn`; mã không tái sử dụng, ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-08-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và tham chiếu `[[tc:khóa]]`, không in ra bản xuất. Đường dẫn API tính từ `/api/dq/v1`. Mỗi ca có các trường sau.

| Trường | Nội dung |
|---|---|
| **Loại.** | Dương, Âm, Biên, Bảo mật, Hiệu năng, Chịu lỗi, Truy cập |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung |
| **Tự động.** | Mức ở mục 1.2 |
| **Truy vết.** | FR, BR, API, UI, ERR, EVT, NFR, LGC, quyền, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu ở chương 2 |
| **Các bước.** | Danh sách đánh số |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán |
| **Thông báo hiển thị.** | Câu người dùng nhìn thấy theo FRS 9.2 (nguyên văn, `{biến}` đã điền giá trị thử); chỉ ở ca có mã lỗi; câu ghi "(FR-08-nnn)" là biến thể theo ngữ cảnh của FR |

: Các trường của khối đặc tả test case

Lỗi thiếu quyền chức năng, chưa xác thực và thiếu `If-Match` dùng mã nền ERR-00-403, ERR-00-401, ERR-00-428 theo FRS 9.1; `403` do phạm vi tổ chức giữ ERR-08-032, ERR-08-005, ERR-08-035. Trong kết quả mong đợi dùng các ký hiệu sau.

| Ký hiệu | Nghĩa |
|---|---|
| 404-ẩn | `404` ERR-08-001; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa giá trị Nhạy cảm |
| EVT: `loại` | Đúng một bản tin trên topic `t90.dq.{loại}.v1`, chỉ mã đối tượng, số đếm, điểm |
| Mồi sạch | Chuỗi canary `DH-CANARY-{ca}` và CCCD giả của ca không xuất hiện ở dạng rõ trong phản hồi, log 5 phút, vết OTel, bảng `ph08_dq.*`, hộp gửi, Kafka, tệp xuất |

: Ký hiệu viết tắt trong kết quả mong đợi

### 1.6. Quản lý lỗi và báo cáo

Lỗi tìm thấy ghi theo mức S1…S4 của D05-01 kèm mã ca, bước, `traceId`; ca không đạt ở cổng `RG-1`, `RG-2` chặn phát hành. Kết quả chạy gom về `.xlsx` (mục 9) qua thẻ `@TC-08-nnn`.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập: tên là nhân vật hư cấu, CCCD dùng dải `0010990xxxxx` không do cơ quan nào cấp. Nạp bằng API, trừ khối RLS chạy ở mức CSDL.

### 2.1. Tenant

Tenant kiểm thử dùng dải `T90…T99`; không dùng tenant sản xuất.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant chính | Đã seed bằng `p_seed_tenant`; miền `DAN_CU` (ORG-CA), `DOANH_NGHIEP` (ORG-TC); đối tượng `mdm-citizen`, `mdm-org`, `rdm-dvhc`, `src-hotich`, `flow-hotich` |
| `T91` | Đối chứng rò rỉ | Cùng mã đối tượng `mdm-citizen` nhưng bộ quy tắc và dữ liệu khác; mọi ca chéo tenant |
| `T92` | Tham số nhỏ | `08.scan.duplicate-policy = REJECT`, `08.scan.manual-per-hour = 3`, `08.scan.queue-timeout-hours = 1`, `08.scan.max-duration-hours = 1`, `08.finding.max-per-rule-task = 50` |
| `T93` | Chưa có số liệu | Không có lần đo; dùng cho trạng thái trống |
| `T94` | Phụ thuộc lỗi | `rdm-sim`, `conn-sim`, `mdm-sim` có kịch bản ngừng, trễ |
| `T95` | Chịu lỗi | Cho Chaos: pod, Kafka, PH-13, PH-16 |
| `T96` | Báo cáo năm | Mọi đối tượng có lần đo `FULL` đủ chiều trong 2026 (F-ANNUAL) |
| `T97`…`T99` | Hiệu năng | T97 kiểm tra trực tuyến; T98 dashboard, tra cứu lỗi 10 triệu dòng; T99 đo lô 1 triệu bản ghi |
| `COMMON` | Dùng chung | 12 quy tắc mẫu do PA quản lý |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

Người dùng mang tên nhân vật hư cấu, vai trò theo D02-08.

| Mã | Tenant | Vai trò | Ghi chú |
|---|---|---|---|
| U-PA | PLATFORM | PA | Sửa mẫu `COMMON`, đặt trần tham số, xem so sánh liên tenant |
| U-T90-TA | T90 | TA | Có cả quyền soạn và duyệt (cấu hình sai chủ ý, chỉ SIT) để kiểm bốn mắt độc lập |
| U-T90-DS1, DS2 | T90 | DS | Lan, Hùng |
| U-T90-DA1, DA2 | T90 | DA | Minh, Thảo |
| U-T90-DO1, DO2 | T90 | DO | Quân (ORG-CA), Bình (ORG-TC) |
| U-T90-TO, SO, AU, VW | T90 | TO, SO, AU, VW | Việt, Hà, Thu, Nam |
| U-T91-DS1, DA1 | T91 | DS, DA | Đối chứng chéo tenant |
| S-T90-PH04, PH06 | T90 | Máy | Scope `dq.check` |
| S-T90-PH16, HTTT-HT | T90 | Máy | Scope `dq.read` (HTTT hộ tịch chỉ đọc dữ liệu của mình) |
| S-T90-PH05 | T90 | Máy | Gọi API nội bộ `/internal/profile-metrics` qua mTLS |
| S-T90-NOSCOPE, S-T91-PH04 | T90, T91 | Máy | Không có scope; token tenant đối chứng |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu

Bộ dữ liệu có tên, sinh bằng hạt cố định để chạy lại được.

| Mã | Nội dung | Tenant |
|---|---|---|
| F-SCORE | 10.000 bản ghi vàng giả của `mdm-citizen` cài sẵn số lỗi theo bảng 2.4 | T90 |
| F-HT | Bảng `hotich.khai_sinh` 5.000 dòng: 4,2 % `ten_cha` rỗng, 200 mã ĐVHC không thuộc danh mục hiện hành (30 mã cũ đã chuyển), cột `cccd` Nhạy cảm | T90 |
| F-LOI | 300 lỗi một quy tắc và 12 bản ghi thiếu khóa, dùng cho ca trần lỗi | T92 |
| F-ANNUAL | Ảnh chụp `FULL` đủ sáu chiều cho mọi đối tượng trong 2026 | T96 |
| F-PERF | 1 triệu bản ghi nguồn 30 quy tắc; 200 đối tượng với 13 tháng ảnh chụp; 10 triệu dòng lỗi phân vùng tháng (giả định theo GĐ-04, GĐ-07) | T97…T99 |

: Bộ dữ liệu kiểm thử

### 2.4. Số đếm chuẩn F-SCORE-1

Bảng cho số đếm của một lần đo `FULL` trên F-SCORE, mỗi chiều một quy tắc; mẫu số của quy tắc là tổng cột Đạt và Vi phạm (quy tắc CONSISTENCY chỉ áp dụng cho 5.000 bản ghi có bản đối chiếu ở nguồn). Các ca công thức điểm tính từ bảng này.

| Chiều | Quy tắc | Đạt | Vi phạm | Điểm chiều | Trọng số v0 | Điểm × trọng số |
|---|---|---|---|---|---|---|
| COMPLETENESS | `R-CCCD-NN` | 9.800 | 200 | 98,00 | 0,20 | 19,60 |
| ACCURACY | `R-CCCD-RX` | 9.500 | 500 | 95,00 | 0,20 | 19,00 |
| CONSISTENCY | `R-NS-EQ` | 4.000 | 1.000 | 80,00 | 0,15 | 12,00 |
| TIMELINESS | `R-CAPNHAT` | 9.000 | 1.000 | 90,00 | 0,10 | 9,00 |
| UNIQUENESS | `R-CCCD-UQ` | 9.900 | 100 | 99,00 | 0,15 | 14,85 |
| VALIDITY | `R-GT-RDM` | 8.500 | 1.500 | 85,00 | 0,20 | 17,00 |
| **Điểm tổng** | | | | | 1,00 | **91,45** |

: Số đếm chuẩn và điểm kỳ vọng của F-SCORE-1

Khi VALIDITY bị bỏ qua, tổng các ô còn lại là 74,45 trên trọng số 0,80 nên điểm là 93,06. Với cấu hình trọng số v1 (0,25/0,20/0,15/0,10/0,10/0,20) điểm là 91,40.

### 2.5. Hệ thống giả lập

Phân hệ và hệ thống ngoài được giả lập như sau.

| Hệ thống | Giả lập bằng | Kịch bản |
|---|---|---|
| PH-06 (`mdm-sim`) | WireMock | Khung nhìn hợp đồng `v_dq_citizen`, sự kiện EVT-06-01…04, 10, nguồn gốc bản ghi, nhận mục steward, ngừng |
| PH-07 (`rdm-sim`) | WireMock | Danh mục `DVHC`, `GIOI-TINH`, mã cũ chuyển, danh mục ngừng, hạn chế, trễ, `503` |
| PH-05 (`conn-sim`) | PostgreSQL bản sao chỉ đọc cộng WireMock | Kết nối `hotich-pg-ro`, `hotich-rw`, nhật ký câu lệnh, ngắt |
| PH-09 (`cls-sim`) | WireMock | Phân loại `CONFIRMED`, `PROPOSED`, đổi phân loại |
| PH-13, PH-16 (`notif-sim`, `kpi-sim`) | WireMock | Nhận thông báo, kiểm toán, KPI; ngừng |
| PH-20 (`org-sim`), ký số (`sign-sim`) | WireMock | Tổ chức ORG-CA, ORG-TC; ký số thành công, lỗi |
| PH-04 (`flow-sim`), đồng hồ (`clock-sim`) | Máy gọi thử, đồng hồ giả | Luồng gọi `dh-dq-check`; đẩy thời gian cho lịch, SLA, hạn |

: Hệ thống giả lập

### 2.6. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Mỗi ca ghi dữ liệu sinh ra và dọn bằng khóa `tc-{khóa}` trong tenant; ca dùng lại dữ liệu của ca khác nêu rõ ở tiền điều kiện. Ca bảo mật đặt canary `DH-CANARY-{ca}` vào trường Nhạy cảm.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5; mục 3.2 liệt kê số ca theo loại và mục 3.3 các máy trạng thái được kiểm.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-08-01 | Miền chất lượng, chủ quản và cán bộ phụ trách | UC-08-01 | 5 |
| TS-08-02 | Đăng ký đối tượng đo từ PH-06, PH-07, PH-05 và khai báo CDE | UC-08-02 | 9 |
| TS-08-03 | Tìm, xem, ngừng và khôi phục đối tượng đo | UC-08-03 | 4 |
| TS-08-04 | Hồ sơ dữ liệu và gợi ý quy tắc | UC-08-04 | 5 |
| TS-08-05 | Soạn bộ quy tắc và định nghĩa quy tắc theo chiều | UC-08-05 | 6 |
| TS-08-06 | Quy tắc nâng cao, thư viện mẫu và chạy thử | UC-08-06 | 7 |
| TS-08-07 | Gửi duyệt, duyệt, kích hoạt và ngừng bộ quy tắc | UC-08-07 | 5 |
| TS-08-08 | So sánh phiên bản, sao chép, nhập và xuất bộ quy tắc | UC-08-08 | 3 |
| TS-08-09 | Cấu hình trọng số và ngưỡng có duyệt | UC-08-09 | 4 |
| TS-08-10 | Lập lịch đo, đo theo yêu cầu, theo dõi và hủy | UC-08-10 | 7 |
| TS-08-11 | Đo theo lô, đối chiếu danh mục PH-07 và ghi bản ghi lỗi | UC-08-11 | 6 |
| TS-08-12 | Tính điểm có trọng số, so kỳ trước và xu hướng | UC-08-12 | 9 |
| TS-08-13 | Xử lý phụ thuộc không khả dụng khi đo | UC-08-13 | 5 |
| TS-08-14 | Đo tăng dần theo sự kiện PH-06, PH-07 | UC-08-14 | 3 |
| TS-08-15 | Kiểm tra trực tuyến bản ghi và bước trong luồng PH-04 | UC-08-15 | 5 |
| TS-08-16 | Cổng chất lượng cho PH-06 và giám sát kiểm tra trực tuyến | UC-08-16 | 3 |
| TS-08-17 | Tra cứu, xem chi tiết và xuất bản ghi lỗi | UC-08-17 | 5 |
| TS-08-18 | Ngoại lệ chấp nhận có hạn và có duyệt | UC-08-18 | 3 |
| TS-08-19 | Mở phiếu khắc phục, phân công và theo dõi SLA | UC-08-19 | 4 |
| TS-08-20 | Nhận, xử lý và cập nhật tiến độ phiếu khắc phục | UC-08-20 | 2 |
| TS-08-21 | Báo đã sửa, đo lại kiểm chứng và xác nhận phiếu | UC-08-21 | 4 |
| TS-08-22 | Từ chối, chuyển, leo thang phiếu và chuyển lỗi bản ghi vàng sang PH-06 | UC-08-22 | 3 |
| TS-08-23 | Khai báo, phát và xử lý cảnh báo chất lượng | UC-08-23 | 3 |
| TS-08-24 | Bảng điều khiển, thẻ điểm và so sánh liên tenant | UC-08-24 | 4 |
| TS-08-25 | Báo cáo kỳ, duyệt, công bố và báo cáo chính thức hằng năm | UC-08-25 | 5 |
| TS-08-26 | Xuất, ký số, phân phối báo cáo và đẩy chỉ số sang PH-16, PH-13 | UC-08-26 | 4 |
| TS-08-27 | Tham số tenant, lưu giữ dữ liệu đo và nhật ký kiểm toán | UC-08-27 | 6 |
| TS-08-28 | Cô lập tenant: API, RLS, Kafka, bộ đệm trực tuyến | — | 4 |
| TS-08-29 | Phân quyền theo ma trận PERM-08, bốn mắt và tài khoản máy | — | 3 |
| TS-08-30 | Bản ghi lỗi: dấu vân tay, che giá trị và không lộ dữ liệu Nhạy cảm | — | 4 |
| TS-08-31 | Kiểm toán và truy vết xuyên suốt | — | 2 |
| TS-08-32 | Hiệu năng kiểm tra trực tuyến | — | 3 |
| TS-08-33 | Hiệu năng đo lô, hồ sơ, bảng điều khiển và báo cáo | — | 3 |
| TS-08-34 | Tái lập, chịu lỗi và giao sự kiện | — | 2 |
| TS-08-35 | Vòng đầy đủ và truy cập giao diện | — | 2 |
| **Tổng** | | | **152** (97 ca P1) |

: Danh sách 35 kịch bản kèm use case và số ca
<!--/gen-->

### 3.2. Số ca theo loại

Một ca có thể thuộc nhiều loại nên tổng theo loại lớn hơn tổng số ca.

<!--gen:loai-->
| Loại | Số ca |
|---|---|
| Dương | 77 |
| Âm | 69 |
| Bảo mật | 19 |
| Biên | 8 |
| Chịu lỗi | 6 |
| Hiệu năng | 6 |
| Truy cập | 1 |

: Số ca theo loại
<!--/gen-->

### 3.3. Máy trạng thái được kiểm thử

Bảng liệt kê chuyển hợp lệ và chuyển cấm được kiểm ở chương 4.

| Máy trạng thái (FRS mục 4) | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Phiên bản bộ quy tắc | DRAFT → PENDING_APPROVAL → ACTIVE; PENDING_APPROVAL → DRAFT (rút, từ chối); PENDING_APPROVAL → APPROVED → ACTIVE; ACTIVE → SUPERSEDED, RETIRED | Gửi duyệt khi rỗng hoặc chưa chạy thử; tự duyệt; kích hoạt bản SUPERSEDED |
| Lần đo | QUEUED → RUNNING → SUCCEEDED, PARTIAL, FAILED; QUEUED, RUNNING → CANCELLED | Hủy lần đo đã kết thúc; hai lần đo cùng đối tượng đang QUEUED hoặc RUNNING |
| Bản ghi lỗi, ngoại lệ | OPEN → IN_REMEDIATION → RESOLVED; OPEN → WAIVED → OPEN; RESOLVED → OPEN (tái xuất); ngoại lệ PENDING_APPROVAL → ACTIVE → EXPIRED, REVOKED | Lỗi thuộc hai phiếu mở; ngoại lệ quá 180 ngày; tự duyệt |
| Phiếu khắc phục | OPEN → ASSIGNED → IN_PROGRESS → FIXED → VERIFIED; FIXED → REOPENED; ASSIGNED → REJECTED, CANCELLED | Chủ quản tự VERIFIED; cập nhật phiếu CANCELLED; từ chối phiếu VERIFIED |
| Báo cáo, cảnh báo | DRAFT → IN_REVIEW → PUBLISHED → WITHDRAWN; FIRING → ACKNOWLEDGED, SILENCED, RESOLVED | Sửa báo cáo PUBLISHED; tắt tiếng quá 7 ngày; xác nhận cảnh báo RESOLVED |

: Chuyển trạng thái hợp lệ và bị cấm được kiểm thử

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ, sau đó là các ca theo mục 1.5. TS-08-01…27 cùng số thứ tự với UC-08-01…27.

### TS-08-01 · Miền chất lượng, chủ quản và cán bộ phụ trách

**Mục tiêu.** Khai báo được miền có chủ quản và cán bộ phụ trách, từ chối miền thiếu chủ, chặn ngừng miền còn đối tượng hoạt động.

**Phủ.** FR-08-001; UC-08-01.

#### TC-08-001 · Tạo, xem và liệt kê miền <!--k:dom-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-001 · API-08-001, 002, 003 · UI-08-19 · PERM-08-asset.

**Tiền điều kiện, dữ liệu.** T90 đã seed; U-T90-TA; ORG-CA (Công an tỉnh) tồn tại ở PH-20 giả lập (`org-sim`); DS1 có vai trò DS.

**Các bước.**

1. `POST /domains` thân `{code: DAN_CU, name: "Dân cư", ownerOrgId: ORG-CA, stewardUserId: DS1}`
2. `GET /domains/DAN_CU`
3. `GET /domains?status=ACTIVE&page=0&size=10`

**Kết quả mong đợi.** Bước 1 `201`, tiêu đề `Location` và `ETag`, `status = ACTIVE`, `assetCount = 0`. Bước 2 trả đủ `ownerOrgName`, `stewardUserId`. Bước 3 có đúng một miền. KT: có (domain.create), ghi chủ quản và cán bộ phụ trách. EVT: không.

:::

#### TC-08-002 · Mã miền trùng hoặc sai mẫu <!--k:dom-neg-code-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-001 · API-08-002 · UI-08-19 · ERR-08-002, 003.

**Tiền điều kiện, dữ liệu.** Miền `DAN_CU` đã có (dom-create).

**Các bước.**

1. `POST /domains` lại với `code = DAN_CU`
2. `POST /domains` với `code = "dan-cu"`

**Kết quả mong đợi.** Bước 1 `409` ERR-08-002. Bước 2 `400` ERR-08-003, `errors[]` trỏ trường `code`, theo mẫu `^[A-Z][A-Z0-9_]{2,31}$`. Không tạo thêm miền.

**Thông báo hiển thị.** ERR-08-002: "Mã DAN_CU đã được dùng. Chọn mã khác."; ERR-08-003: "Mã miền không hợp lệ: chỉ gồm chữ in hoa, số, gạch dưới, 3 đến 32 ký tự."

:::

#### TC-08-003 · Miền thiếu chủ quản hoặc cán bộ phụ trách không hợp lệ <!--k:dom-neg-owner-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-001 · API-08-002 · BR-08-026 · ERR-08-008.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA; U-T90-VW (vai trò VW, không phải DS); tổ chức `ORG-KHONG-CO` không có ở `org-sim`.

**Các bước.**

1. `POST /domains` với `ownerOrgId = ORG-KHONG-CO`
2. `POST /domains` với `stewardUserId` là người dùng VW

**Kết quả mong đợi.** Cả hai `422` ERR-08-008, không tạo miền, không bản ghi kiểm toán thành công.

**Thông báo hiển thị.** ERR-08-008: "Miền DAT_DAI cần tổ chức chủ quản và cán bộ phụ trách hợp lệ trước khi dùng."

:::

#### TC-08-004 · Ngừng miền còn đối tượng đo hoạt động <!--k:dom-inactive-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-001 · API-08-004 · UI-08-19.

**Tiền điều kiện, dữ liệu.** Miền `DAN_CU` có đối tượng `mdm-citizen` `ACTIVE`.

**Các bước.**

1. `PATCH /domains/DAN_CU` thân `{status: INACTIVE}` với `If-Match` đúng
2. `POST /assets/mdm-citizen:suspend` (lý do 25 ký tự) rồi lặp bước 1

**Kết quả mong đợi.** Bước 1 `409` ERR-08-006, thân liệt kê đối tượng cần ngừng trước. Bước 2 sau khi ngừng đối tượng: `200`, `status = INACTIVE`, phiếu đang mở không tự chuyển.

**Thông báo hiển thị.** ERR-08-006 (FR-08-001): "Miền còn 1 đối tượng đo đang hoạt động. Ngừng các đối tượng này trước."

:::

#### TC-08-005 · Sửa miền đồng thời và thiếu If-Match <!--k:dom-etag-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-001 · API-08-004 · ERR-00-428 · ERR-08-004.

**Tiền điều kiện, dữ liệu.** Miền `DAN_CU`, `ETag` v1 của U-T90-DS1 và U-T90-TA.

**Các bước.**

1. TA `PATCH /domains/DAN_CU` đổi tên với `If-Match` v1 (thành công, `ETag` v2)
2. DS1 `PATCH` với `If-Match` v1 cũ
3. `PATCH` không có `If-Match`

**Kết quả mong đợi.** Bước 2 `409` ERR-08-004 và không ghi đè. Bước 3 `428` ERR-00-428.

**Thông báo hiển thị.** ERR-08-004: "Miền đã được người khác sửa. Tải lại để xem thay đổi."

:::

### TS-08-02 · Đăng ký đối tượng đo từ PH-06, PH-07, PH-05 và khai báo CDE

**Mục tiêu.** Bốn đường đăng ký đối tượng đo hội tụ ở khai báo CDE, chỉ nhận nguồn đủ điều kiện, che theo phân loại PH-09.

**Phủ.** FR-08-002…005; UC-08-02.

#### TC-08-006 · Đăng ký đối tượng đo từ domain PH-06 <!--k:ast-mdm-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-002 · API-08-006, 016 · UI-08-03 · BR-08-004, 005 · PERM-08-asset.

**Tiền điều kiện, dữ liệu.** T90; U-T90-DS1; domain `CITIZEN` ở `mdm-sim` trạng thái `ACTIVE` có khung nhìn `ph06_mdm.v_dq_citizen`.

**Các bước.**

1. `GET /sources/mdm-domains`
2. `POST /assets` `{assetCode: mdm-citizen, assetType: MDM_DOMAIN, sourceRef: {domainCode: CITIZEN}, domainCode: DAN_CU}`

**Kết quả mong đợi.** Bước 1 liệt kê `CITIZEN`. Bước 2 `201`, `status = DRAFT`, `fields[]` lấy từ khung nhìn, `recordKey = goldenId`. Nhật ký truy vấn của `mdm-sim` chỉ có `SELECT` trên khung nhìn; không có truy cập bảng vật lý `ph06_mdm.*` (BR-08-005).

:::

#### TC-08-007 · Domain PH-06 chưa sẵn sàng hoặc mã trùng <!--k:ast-mdm-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-002 · API-08-006 · BR-08-005 · ERR-08-009, 002.

**Tiền điều kiện, dữ liệu.** T90; domain `ORGANIZATION` ở `mdm-sim` trạng thái `DRAFT`; `mdm-citizen` đã có.

**Các bước.**

1. `POST /assets` với `sourceRef.domainCode = ORGANIZATION`
2. `POST /assets` lại `assetCode = mdm-citizen`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-009. Bước 2 `409` ERR-08-002. Không có đối tượng mới.

**Thông báo hiển thị.** ERR-08-009: "Domain ORGANIZATION chưa sẵn sàng cho đo chất lượng. Đề nghị PH-06 cấp khung nhìn hợp đồng."; ERR-08-002: "Mã mdm-citizen đã được dùng. Chọn mã khác."

:::

#### TC-08-008 · Đăng ký đối tượng đo từ danh mục PH-07 <!--k:ast-rdm-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-003 · API-08-006, 017 · UI-08-03 · LGC-DMDC-006, 007, 008.

**Tiền điều kiện, dữ liệu.** T90; danh mục `DVHC` đã phát hành ở `rdm-sim`.

**Các bước.**

1. `GET /sources/rdm-catalogs`
2. `POST /assets` `{assetCode: rdm-dvhc, assetType: RDM_CATALOG, sourceRef: {catalogCode: DVHC, versionPolicy: LATEST}}`

**Kết quả mong đợi.** `201`, `sourceRef = {catalogCode, versionPolicy, versionNo}`. Đối tượng này đo chất lượng danh mục sau mỗi lần nhập hoặc phát hành, không thay chức năng nhập của PH-07.

:::

#### TC-08-009 · Danh mục chưa phát hành hoặc hạn chế chưa cấp quyền <!--k:ast-rdm-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-003 · API-08-006 · ERR-08-010.

**Tiền điều kiện, dữ liệu.** T90; danh mục `LOAI-DAT` ở `rdm-sim` trạng thái `DRAFT`; danh mục hạn chế `HS-MAT` chưa cấp quyền khai thác cho PH-08.

**Các bước.**

1. `POST /assets` với `catalogCode = LOAI-DAT`
2. `POST /assets` với `catalogCode = HS-MAT`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-010. Bước 2 `403` ERR-08-032 (thiếu quyền khai thác danh mục).

**Thông báo hiển thị.** ERR-08-010: "Danh mục LOAI-DAT chưa phát hành ở PH-07."; ERR-08-032 (FR-08-003): "Anh/chị chưa có quyền khai thác danh mục HS-MAT."

:::

#### TC-08-010 · Đăng ký đối tượng đo từ nguồn PH-05 chỉ đọc <!--k:ast-src-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-004 · API-08-006, 018 · UI-08-03 · BR-08-025.

**Tiền điều kiện, dữ liệu.** T90; kết nối `hotich-pg-ro` ở `conn-sim` (PostgreSQL bản sao chỉ đọc, đã cấp cho PH-08); bảng `hotich.khai_sinh` (F-HT).

**Các bước.**

1. `POST /sources/connections/hotich-pg-ro:discover`
2. `POST /assets` `{assetCode: src-hotich, assetType: SOURCE_DATASET, sourceRef: {connectionCode: hotich-pg-ro, schema: hotich, table: khai_sinh}, recordKey: [so_khai_sinh], updatedAtField: ngay_cap_nhat}`

**Kết quả mong đợi.** Bước 1 trả danh sách bảng và cột. Bước 2 `201`, `sourceRef` đủ ba trường, `scanWindow = 22:00-05:00`. PH-08 không lưu thông tin đăng nhập kết nối (bí mật ở OpenBao); nhật ký nguồn chỉ có `SELECT`.

:::

#### TC-08-011 · Kết nối không chỉ đọc, bảng cấm hoặc khóa sai <!--k:ast-src-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-004 · API-08-006 · BR-08-005 · ERR-08-011, 012, 013.

**Tiền điều kiện, dữ liệu.** T90; `hotich-rw` (kết nối ghi được); bảng `ph05_integration.connection` (CSDL control).

**Các bước.**

1. `POST /assets` với `connectionCode = hotich-rw`
2. `POST /assets` với `table = ph05_integration.connection`
3. `POST /assets` với `recordKey = [cot_khong_co]` trên `hotich.khai_sinh`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-011. Bước 2 `422` ERR-08-012. Bước 3 `422` ERR-08-013. Không đối tượng nào được tạo.

**Thông báo hiển thị.** ERR-08-011: "Kết nối hotich-rw không phải kết nối chỉ đọc được cấp cho chất lượng dữ liệu."; ERR-08-012: "Không đo được bảng ph05_integration.connection. Bảng không tồn tại hoặc thuộc CSDL quản trị của Datahub."; ERR-08-013: "Khóa bản ghi cot_khong_co không có trong bảng hotich.khai_sinh."

:::

#### TC-08-012 · Khai báo CDE và kéo phân loại PH-09 <!--k:cde-set-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-005 · API-08-008, 013, 014, 015 · UI-08-04 · BR-08-012, 031 · PERM-08-asset.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` `DRAFT`; `cls-sim` trả `nationalId` `SENSITIVE` `CONFIRMED`, `fullName` `RESTRICTED` `CONFIRMED`.

**Các bước.**

1. `PUT /assets/mdm-citizen/fields/nationalId` `{isCde: true}`
2. `PUT /assets/mdm-citizen/fields/fullName` `{isCde: true}`
3. `POST /assets/mdm-citizen/fields:sync-classification`
4. `GET /assets/mdm-citizen/fields`
5. `PATCH /assets/mdm-citizen` đổi tên hiển thị với `If-Match` đúng

**Kết quả mong đợi.** `nationalId` có `dataClass = SENSITIVE`, `maskingMode = HASH`; `fullName` `RESTRICTED`, `maskingMode = PARTIAL`; `cdeCoverage` hiển thị tỷ lệ CDE có quy tắc `COMPLETENESS` hoặc `VALIDITY` (0 % khi chưa có quy tắc). `PATCH` trả `200` và `ETag` mới. KT: có (field.cde).

:::

#### TC-08-013 · Che lỏng hơn phân loại hoặc trường không thuộc lược đồ <!--k:cde-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-005 · API-08-014 · BR-08-012 · ERR-08-003, 014.

**Tiền điều kiện, dữ liệu.** Như cde-set.

**Các bước.**

1. `PUT /assets/mdm-citizen/fields/nationalId` `{maskingMode: NONE}`
2. `PUT /assets/mdm-citizen/fields/truong_la` `{isCde: true}`

**Kết quả mong đợi.** Bước 1 `400` ERR-08-003 (che lỏng hơn mức `SENSITIVE`). Bước 2 `422` ERR-08-014. Cấu hình trường không đổi.

**Thông báo hiển thị.** ERR-08-003: "nationalId không hợp lệ: mức SENSITIVE phải che ít nhất ở chế độ HASH."; ERR-08-014: "Trường truong_la không có trong đối tượng đo mdm-citizen."

:::

#### TC-08-014 · Kích hoạt đối tượng theo điều kiện CDE và phân loại <!--k:ast-activate-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-002 · FR-08-005 · API-08-009 · BR-08-031 · ERR-08-047.

**Tiền điều kiện, dữ liệu.** Đối tượng `mdm-new` `DRAFT` chưa có CDE; đối tượng `mdm-citizen` có CDE `nationalId` mà `cls-sim` trả `PROPOSED`.

**Các bước.**

1. `POST /assets/mdm-new:activate`
2. đặt CDE `nationalId` rồi `POST /assets/mdm-citizen:activate`

**Kết quả mong đợi.** Bước 1 `409` ERR-08-006, đối tượng giữ `DRAFT`. Bước 2 `200`, `ACTIVE` kèm cảnh báo ERR-08-047 (không chặn), trường che như `SENSITIVE`; tự tạo lịch theo `08.scan.default-cron` và chạy hồ sơ (`08.profile.on-activate`).

**Thông báo hiển thị.** ERR-08-047: "Trường nationalId chưa có phân loại xác nhận ở PH-09. Giá trị sẽ được che như dữ liệu Nhạy cảm."; ERR-08-006 (FR-08-002): "Đối tượng đo cần ít nhất một phần tử dữ liệu trọng yếu trước khi kích hoạt."

:::

### TS-08-03 · Tìm, xem, ngừng và khôi phục đối tượng đo

**Mục tiêu.** Danh sách, bộ lọc, phạm vi tổ chức của DO, cô lập tenant và vòng đời tạm ngừng, khôi phục, ngừng hẳn đối tượng đo.

**Phủ.** FR-08-006, 007; UC-08-03.

#### TC-08-015 · Liệt kê, lọc và xem đối tượng đo <!--k:ast-list-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-006 · API-08-005, 007 · UI-08-02, 04 · BR-08-026 · PERM-08-read.

**Tiền điều kiện, dữ liệu.** T90 có `mdm-citizen`, `rdm-dvhc`, `src-hotich` đã đo; U-T90-DS1, U-T90-DO1 (ORG-CA), U-T90-VW.

**Các bước.**

1. DS1 `GET /assets?domainCode=DAN_CU&verdict=PASS&sort=score,desc&page=0&size=10`
2. DS1 `GET /assets/mdm-citizen`
3. DO1 `GET /assets`

**Kết quả mong đợi.** Bước 1 `200`, `items[]` có `score`, `verdict`, `trend`, `lastScanAt`, `openFindings{CRITICAL,MAJOR,MINOR}`, `cdeCoverage`, kèm `facets`. Bước 2 có `ETag`. Bước 3 chỉ các đối tượng của miền thuộc ORG-CA.

:::

#### TC-08-016 · DO ngoài tổ chức, tham số sai và tenant khác <!--k:ast-scope-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-006 · API-08-005, 007 · BR-08-026 · ERR-08-032, 001, 045.

**Tiền điều kiện, dữ liệu.** `mdm-org` thuộc miền `DOANH_NGHIEP` (ORG-TC); T91 có đối tượng cùng mã `mdm-citizen`.

**Các bước.**

1. DO1 `GET /assets/mdm-org`
2. DS1 `GET /assets/khong-co`
3. U-T91-DS1 `GET /assets/src-hotich` (chỉ có ở T90)
4. DS1 `GET /assets?size=0&sort=xyz`

**Kết quả mong đợi.** Bước 1 `403` ERR-08-032. Bước 2 và 3 `404` ERR-08-001, hai thân giống nhau trừ `traceId` (404-ẩn). Bước 4 `422` ERR-08-045.

**Thông báo hiển thị.** ERR-08-032: "Đối tượng mdm-org không thuộc tổ chức của anh/chị."; ERR-08-001: "Không tìm thấy đối tượng đo src-hotich trong tỉnh đang làm việc."; ERR-08-045: "Tham số size không hợp lệ: phải từ 1 đến 200."

:::

#### TC-08-017 · Tạm ngừng, khôi phục và ngừng hẳn đối tượng <!--k:ast-suspend-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-007 · API-08-010, 011, 012 · UI-08-04 · BR-08-020 · PERM-08-asset.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` `ACTIVE`, lịch tháng hoạt động, một lần đo `QUEUED`.

**Các bước.**

1. DS1 `POST /assets/mdm-citizen:suspend` `{reason: "Nguồn bảo trì đến hết tuần, tạm ngừng đo"}`
2. `GET /scans?assetCode=mdm-citizen&status=CANCELLED`
3. `POST /assets/mdm-citizen:resume`
4. `POST /assets/rdm-dvhc:retire` (lý do ≥ 20 ký tự)

**Kết quả mong đợi.** Bước 1 `200`, `status = SUSPENDED`, `cancelledScans[]` có lần đo `QUEUED`, lịch không bắn. Bước 3 `ACTIVE`, lịch tiếp tục. Bước 4 `RETIRED`; dữ liệu đo giữ theo chính sách lưu giữ (FR-08-059). KT: có (asset.suspend, asset.resume, asset.retire).

:::

#### TC-08-018 · Ngừng thiếu lý do, đang đo hoặc sai trạng thái <!--k:ast-suspend-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-007 · API-08-010, 011, 012 · ERR-08-007, 028, 006.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` có lần đo `RUNNING`; `rdm-dvhc` `RETIRED`.

**Các bước.**

1. `POST /assets/src-hotich:suspend` `{reason: "bảo trì"}`
2. `POST /assets/mdm-citizen:suspend` (lý do đủ dài)
3. `POST /assets/rdm-dvhc:resume`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-007. Bước 2 `409` ERR-08-028. Bước 3 `409` ERR-08-006.

**Thông báo hiển thị.** ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-028: "Đối tượng đang có lần chạy SC-2026-11-0007. Đợi lần này xong hoặc hủy."; ERR-08-006: "Không thể khôi phục khi đối tượng đo đang ở trạng thái RETIRED."

:::

### TS-08-04 · Hồ sơ dữ liệu và gợi ý quy tắc

**Mục tiêu.** Chạy hồ sơ, đọc thống kê cột, không lưu giá trị gốc cột Nhạy cảm, gợi ý quy tắc, nhận chỉ số hồ sơ từ PH-05.

**Phủ.** FR-08-008…011; UC-08-04.

#### TC-08-019 · Chạy hồ sơ dữ liệu và xem thẻ cột <!--k:prof-run-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-008, 009 · API-08-019, 020, 021, 022 · UI-08-05 · BR-08-025 · NFR-08-013.

**Tiền điều kiện, dữ liệu.** `src-hotich` `ACTIVE` với F-HT (5.000 dòng, cột `cccd` Nhạy cảm, 4,2 % `ten_cha` rỗng); U-T90-DS1.

**Các bước.**

1. `POST /assets/src-hotich/profile-runs` `{mode: SAMPLE, sampleSize: 5000}`
2. poll `GET /profile-runs/{runId}` đến `SUCCEEDED`
3. `GET /profile-runs/{runId}/columns`

**Kết quả mong đợi.** Bước 1 `202`, `status = QUEUED`, `Location` tới API-08-021. Bước 3 mỗi cột có `nullRatio`, `distinctEstimate`, `min`, `max`, `quantiles`, `topPatterns`, `inferredType`; `ten_cha.nullRatio` = 0,042 ± 0,001; `distinctEstimate` lệch ≤ 2 % so với đếm chính xác. Truy vấn lên nguồn chỉ `SELECT`.

:::

#### TC-08-020 · Hồ sơ cho bản tin luồng, mẫu sai, đang chạy, nguồn lỗi <!--k:prof-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-008 · API-08-019 · ERR-08-111 · ERR-08-050, 030, 028.

**Tiền điều kiện, dữ liệu.** `flow-hotich` (`FLOW_MESSAGE`); `src-hotich`; một lần hồ sơ `RUNNING`; `conn-sim` có thể ngắt.

**Các bước.**

1. `POST /assets/flow-hotich/profile-runs`
2. `POST /assets/src-hotich/profile-runs` `{mode: SAMPLE, sampleSize: 50}`
3. `POST` hồ sơ lần hai khi lần một còn `RUNNING`
4. ngắt `conn-sim` rồi chạy hồ sơ mới

**Kết quả mong đợi.** Bước 1 `422` ERR-08-050. Bước 2 `422` ERR-08-030. Bước 3 `409` ERR-08-028. Bước 4 lần hồ sơ `FAILED`, UI-08-05 và PH-13 nhận ERR-08-111; điểm không đổi.

**Thông báo hiển thị.** ERR-08-050: "Đối tượng loại bản tin trên luồng không chạy hồ sơ hoặc đo theo lô."; ERR-08-030: "Kích thước mẫu phải từ 100 đến 1.000.000 bản ghi; lần đo cho báo cáo năm phải đo toàn bộ."; ERR-08-028: "Đối tượng đang có lần chạy PR-0007. Đợi lần này xong hoặc hủy."; ERR-08-111: "Lần hồ sơ PR-0008 thất bại: kết nối bị ngắt."

:::

#### TC-08-021 · Hồ sơ cột Nhạy cảm không lưu giá trị phổ biến, chưa có hồ sơ <!--k:prof-sens-->

::: dac-ta
**Loại.** Bảo mật, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-008, 009 · API-08-022 · BR-08-012 · NFR-08-016 · PERM-08-finding-read.

**Tiền điều kiện, dữ liệu.** `src-hotich.cccd` `SENSITIVE`, đặt canary `DH-CANARY-prof` vào một dòng; U-T90-DS1 (có `PERM-08-finding-read`), U-T90-TA (không có).

**Các bước.**

1. Chạy hồ sơ
2. DS1 `GET /profile-runs/{runId}/columns`
3. TA `GET` cùng đường dẫn
4. quét `ph08_dq`, log, vết OTel tìm `DH-CANARY-prof`
5. `GET /profile-runs/{runId}/columns` của đối tượng `src-moi` chưa chạy hồ sơ

**Kết quả mong đợi.** Cột `cccd` chỉ có `topPatterns` (ví dụ `\d{12}`) và số đếm, không có `topValues`. `topValues` của cột không Nhạy cảm chỉ hiện cho DS1, TA thấy rỗng. Quét canary 0 kết quả (Mồi sạch). Bước 5 `404` ERR-08-001 (chưa có hồ sơ).

**Thông báo hiển thị.** ERR-08-001 (FR-08-009): "Chưa có hồ sơ dữ liệu cho đối tượng src-moi. Bấm Chạy hồ sơ."

:::

#### TC-08-022 · Gợi ý quy tắc từ hồ sơ <!--k:prof-suggest-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-08-010 · API-08-023, 031 · UI-08-05 · ERR-08-022.

**Tiền điều kiện, dữ liệu.** Hồ sơ `SUCCEEDED` của `src-hotich`; bộ `RS-HOTICH` chưa có nháp.

**Các bước.**

1. `POST /profile-runs/{runId}:suggest-rules`
2. chọn 2 gợi ý, sửa tham số một gợi ý rồi `POST /rule-sets/RS-HOTICH/versions/1/rules`
3. DS2 lặp bước 2 khi nháp do DS1 tạo

**Kết quả mong đợi.** Bước 1 `200`, `suggestions[]` có `dimension`, `operator`, `target`, `params`, `confidence`, `evidence` (ví dụ `NOT_NULL` cho cột `nullRatio < 1 %`, `REGEX` từ `topPatterns`). Bước 2 quy tắc vào bản nháp với `source = SUGGESTED`. Bước 3 `409` ERR-08-022.

**Thông báo hiển thị.** ERR-08-022: "Bộ quy tắc RS-HOTICH đang có bản nháp phiên bản 1 do DS1 tạo."

:::

#### TC-08-023 · Nhận chỉ số hồ sơ từ PH-05 <!--k:prof-ph05-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-08-011 · API-08-024 · ERR-08-118.

**Tiền điều kiện, dữ liệu.** Tài khoản dịch vụ `S-T90-PH05` (mTLS); lô chỉ số hợp lệ và một lô thiếu trường `nullRatio`.

**Các bước.**

1. `POST /internal/profile-metrics` lô hợp lệ
2. gửi lô thứ hai cùng cửa sổ
3. gửi lô sai định dạng
4. `GET /assets/src-hotich/profile-runs`

**Kết quả mong đợi.** Bước 1 `202`, `accepted`, `ignored`. Bước 2 cộng dồn. Bước 3 `422` ERR-08-118, hiển thị cho vận hành ở PH-13. Bước 4 có lần hồ sơ `mode = EXTERNAL`, UI-08-05 ghi nguồn "PH-05".

**Thông báo hiển thị.** ERR-08-118: "Lô dữ liệu từ {nguồn} sai định dạng: thiếu trường nullRatio."

:::

### TS-08-05 · Soạn bộ quy tắc và định nghĩa quy tắc theo chiều

**Mục tiêu.** Tạo bộ quy tắc ở bản nháp, mỗi chiều dùng đúng toán tử, kiểm tham số, danh mục, nguồn đối chiếu và tìm quy tắc.

**Phủ.** FR-08-012, 013, 022; UC-08-05.

#### TC-08-024 · Tạo bộ quy tắc và phiên bản nháp <!--k:rs-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-012 · API-08-025, 026, 027, 029 · UI-08-06 · BR-08-006 · PERM-08-rule-admin.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` `ACTIVE`; U-T90-DS1.

**Các bước.**

1. `POST /rule-sets` `{ruleSetCode: RS-CITIZEN, assetCode: mdm-citizen}`
2. `GET /rule-sets/RS-CITIZEN`
3. `GET /rule-sets/RS-CITIZEN/versions`
4. `GET /rule-sets?assetCode=mdm-citizen`

**Kết quả mong đợi.** Bước 1 `201`, `version = 1`, `status = DRAFT`, `ruleCount = 0`, `ETag`. Phiên bản `ACTIVE` (nếu có) không đổi. KT: có (ruleset.create).

:::

#### TC-08-025 · Đã có bản nháp hoặc đối tượng đã có bộ quy tắc <!--k:rs-draft-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-012 · API-08-026, 029 · BR-08-006 · ERR-08-022, 002.

**Tiền điều kiện, dữ liệu.** `RS-CITIZEN` có nháp v2 do DS1 tạo; U-T90-DS2.

**Các bước.**

1. DS2 `POST /rule-sets/RS-CITIZEN/versions`
2. DS2 `POST /rule-sets` `{ruleSetCode: RS-CITIZEN-2, assetCode: mdm-citizen}`

**Kết quả mong đợi.** Bước 1 `409` ERR-08-022. Bước 2 `409` ERR-08-002. Không tạo thêm nháp.

**Thông báo hiển thị.** ERR-08-022: "Bộ quy tắc RS-CITIZEN đang có bản nháp phiên bản 2 do DS1 tạo."; ERR-08-002: "Mã RS-CITIZEN-2 đã được dùng. Chọn mã khác."

:::

#### TC-08-026 · Định nghĩa quy tắc cho từng chiều <!--k:rule-def-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-013 · API-08-031, 032, 033 · UI-08-07, 08 · PERM-08-rule-admin.

**Tiền điều kiện, dữ liệu.** Nháp v1 của `RS-CITIZEN`; danh mục `GIOI-TINH` đã phát hành ở `rdm-sim`; CDE `nationalId`, `gender`, `birthDate`, `updatedAt`.

**Các bước.**

1. Thêm 6 quy tắc bằng `POST /rule-sets/RS-CITIZEN/versions/1/rules`: `R-CCCD-NN` `COMPLETENESS` `NOT_NULL` `CRITICAL`
2. `R-CCCD-RX` `ACCURACY` `REGEX` `^\d{12}$` `MAJOR`
3. `R-NS-EQ` `CONSISTENCY` `EQ_SOURCE` đối chiếu `src-hotich.ngay_sinh`
4. `R-CAPNHAT` `TIMELINESS` `MAX_AGE_DAYS` 365 `MINOR`
5. `R-CCCD-UQ` `UNIQUENESS` `UNIQUE_IN_ASSET` `CRITICAL`
6. `R-GT-RDM` `VALIDITY` `IN_RDM` `catalogCode = GIOI-TINH` `MAJOR`
7. `DELETE …/rules/R-CAPNHAT` (quy tắc mới thêm trong nháp)

**Kết quả mong đợi.** Mỗi lệnh `201`, quy tắc có `execMode` suy ra (`R-CCCD-UQ` là `BATCH`, còn lại `BOTH`), `ETag` phiên bản đổi; `DELETE` `204`, quy tắc xóa thật vì chưa từng có ở phiên bản trước (quy tắc đã có ở phiên bản trước chỉ được tắt `enabled = false`); sau đó thêm lại để `ruleCount = 6`; dấu chạy thử cũ (nếu có) bị vô hiệu (BR-08-006). Sáu chiều đều có quy tắc.

:::

#### TC-08-027 · Toán tử không thuộc chiều, tham số sai, thiếu danh mục hoặc nguồn <!--k:rule-neg-op-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-013 · API-08-031, 032 · BR-08-003 · ERR-08-015, 016, 017, 018, 014.

**Tiền điều kiện, dữ liệu.** Như rule-def.

**Các bước.**

1. `POST` quy tắc `COMPLETENESS` với `operator = REGEX`
2. `POST` `REGEX` với `pattern = "[a-"`
3. `POST` chiều `VALIDITY` `IN_RDM` không có `catalogCode`
4. `POST` chiều `CONSISTENCY` `EQ_SOURCE` không có nguồn đối chiếu
5. `POST` quy tắc `NOT_NULL` trên trường `khong_co`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-015. Bước 2 `422` ERR-08-016. Bước 3 `422` ERR-08-017. Bước 4 `422` ERR-08-018. Bước 5 `422` ERR-08-014. Không quy tắc nào được lưu.

**Thông báo hiển thị.** ERR-08-015: "Toán tử REGEX không dùng được cho chiều COMPLETENESS."; ERR-08-016: "Tham số pattern của quy tắc R-CCCD-RX không hợp lệ: biểu thức chính quy không biên dịch được."; ERR-08-017: "Quy tắc chiều Hợp lệ phải chọn danh mục PH-07 để đối chiếu."; ERR-08-018: "Quy tắc chiều Nhất quán phải chọn đối tượng đo và trường để đối chiếu."; ERR-08-014: "Trường khong_co không có trong đối tượng đo mdm-citizen."

:::

#### TC-08-028 · Quy tắc hợp lệ tự liệt kê mã thay cho danh mục <!--k:rule-neg-rdm-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-013 · API-08-031 · BR-08-003 · ERR-08-017 · ERR-08-015.

**Tiền điều kiện, dữ liệu.** Nháp v1 của `RS-CITIZEN`.

**Các bước.**

1. `POST` quy tắc `VALIDITY` `IN_RDM` với `params = {values: ["1","2","3"]}` không có `catalogCode`
2. `POST` quy tắc `VALIDITY` `REGEX` `^(1|2|3)$` cho trường `gender`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-017: PH-08 không nhận danh sách mã tự khai. Bước 2 `422` ERR-08-015 vì `REGEX` không thuộc chiều `VALIDITY`. Schema `ph08_dq` không có bảng chứa mã danh mục.

**Thông báo hiển thị.** ERR-08-015: "Toán tử REGEX không dùng được cho chiều VALIDITY."

:::

#### TC-08-029 · Liệt kê và tìm quy tắc <!--k:rule-list-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-022 · API-08-053 · UI-08-06 · PERM-08-read · ERR-08-045.

**Tiền điều kiện, dữ liệu.** T90 có 40 quy tắc ở 5 đối tượng, 6 quy tắc dùng mẫu `TPL-MST` bản cũ.

**Các bước.**

1. `GET /rules?dimension=VALIDITY&severity=MAJOR&execMode=BOTH&page=0&size=20`
2. `GET /rules?templateOutdated=true`
3. `GET /rules?dimension=KHAC`

**Kết quả mong đợi.** `200`, `items[]` có `ruleCode`, `assetCode`, `dimension`, `operator`, `severity`, `execMode`, `lastFailRate`, `templateRef`, kèm `facets`; bước 2 trả đúng 6 quy tắc dùng mẫu cũ. Bước 3 `422` ERR-08-045.

**Thông báo hiển thị.** ERR-08-045: "Tham số dimension không hợp lệ: không thuộc sáu chiều."

:::

### TS-08-06 · Quy tắc nâng cao, thư viện mẫu và chạy thử

**Mục tiêu.** CEL, vị từ SQL có kiểm soát, quy tắc mẫu `COMMON` và chạy thử tái lập được mà không ghi lỗi hay ảnh chụp.

**Phủ.** FR-08-014…016; UC-08-06.

#### TC-08-030 · Kiểm tra và thêm quy tắc CEL <!--k:cel-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-014 · API-08-031, 034 · UI-08-08 · BR-08-017.

**Tiền điều kiện, dữ liệu.** Nháp v1 `RS-CITIZEN`; U-T90-DS1.

**Các bước.**

1. `POST /rules:validate-expression` `{language: CEL, expression: "has(ngayCap) && ngayCap >= ngaySinh"}`
2. `POST /rule-sets/RS-CITIZEN/versions/1/rules` `{operator: CEL_EXPRESSION, dimension: CONSISTENCY, expression: "..."}`

**Kết quả mong đợi.** Bước 1 `200`, `normalizedExpression`, `estimatedCost` dưới giới hạn, `execMode = BOTH`. Bước 2 `201`, quy tắc chạy được cả lô và trực tuyến.

:::

#### TC-08-031 · CEL sai cú pháp, sai kiểu hoặc vượt chi phí <!--k:cel-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-014 · API-08-034 · BR-08-017 · ERR-08-019.

**Tiền điều kiện, dữ liệu.** Như cel-ok.

**Các bước.**

1. `POST /rules:validate-expression` với `"ngayCap >="`
2. với `"ngayCap + 1 > ngaySinh"` (cộng ngày với số nguyên không hợp kiểu)
3. với biểu thức lồng `all` trên danh sách 10^6 phần tử

**Kết quả mong đợi.** Cả ba `422` ERR-08-019, bước 1 chỉ vị trí `1:11`; không lưu quy tắc.

**Thông báo hiển thị.** ERR-08-019: "Biểu thức không hợp lệ ở vị trí 1:11: thiếu vế phải."

:::

#### TC-08-032 · Vị từ SQL chưa bật, vi phạm danh sách cho phép và chế độ chạy <!--k:sql-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-014 · FR-08-013 · API-08-031, 032 · BR-08-017 · ERR-08-020, 016.

**Tiền điều kiện, dữ liệu.** `src-hotich` có `ngay_sinh`; cờ `08.rule.sql-predicate-enabled = false`; sau bước 1 TA bật cờ.

**Các bước.**

1. `POST` quy tắc `SQL_PREDICATE` `ngay_sinh <= current_date`
2. bật cờ rồi `POST` lại
3. `POST` `SQL_PREDICATE` `1=1; DROP TABLE khai_sinh`
4. `POST` `SQL_PREDICATE` có truy vấn con `(SELECT ...)` hoặc `pg_sleep(100)`
5. `POST` `UNIQUE_IN_ASSET` với `execMode = INLINE`

**Kết quả mong đợi.** Bước 1 `409` ERR-08-006. Bước 2 `201`, `execMode = BATCH`. Bước 3 và 4 `422` ERR-08-020. Bước 5 `422` ERR-08-016 (giả định, xem ĐN-TC-03): quy tắc `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE` chỉ chạy lô.

**Thông báo hiển thị.** ERR-08-020: "Vị từ SQL dùng nhiều lệnh không được phép. Chỉ được viết điều kiện trên cột của bảng đang đo."; ERR-08-016: "Tham số execMode của quy tắc R-CCCD-UQ không hợp lệ: toán tử chỉ chạy theo lô."; ERR-08-006 (FR-08-014): "Quy tắc vị từ SQL chưa được bật cho tỉnh. Liên hệ quản trị."

:::

#### TC-08-033 · Dùng quy tắc mẫu COMMON <!--k:tpl-use-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-015 · API-08-035, 031 · UI-08-06, 08 · LGC-NGSP-005.

**Tiền điều kiện, dữ liệu.** `COMMON` có 12 mẫu (`TPL-CCCD`, `TPL-MST`, `TPL-SDT`, `TPL-EMAIL`, `TPL-DVHC`…); `mdm-org` có CDE `mst`.

**Các bước.**

1. `GET /rule-templates?scope=COMMON`
2. `POST /rule-sets/RS-ORG/versions/1/rules` `{templateRef: TPL-MST, field: mst}`

**Kết quả mong đợi.** Bước 1 trả 12 mẫu có phiên bản. Bước 2 `201`, quy tắc `ACCURACY` `CHECKSUM` `MST_10`, `source = TEMPLATE`, giữ `templateRef` và số phiên bản mẫu.

:::

#### TC-08-034 · Tenant sửa mẫu COMMON, PA sửa mẫu <!--k:tpl-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-015 · API-08-036 · BR-08-032.

**Tiền điều kiện, dữ liệu.** Quy tắc `R-MST` đang dùng `TPL-MST` v1; U-T90-DS1; U-PA.

**Các bước.**

1. DS1 `POST /rule-templates` sửa `TPL-MST` ở `COMMON`
2. PA `POST /rule-templates` sửa `TPL-MST`
3. kiểm `R-MST`

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403 ("Anh/chị không có quyền sửa mẫu dùng chung toàn quốc."). Bước 2 `201`, mẫu v2. Bước 3 `R-MST` vẫn trỏ `TPL-MST` v1; `GET /rules?templateOutdated=true` liệt kê `R-MST`.

:::

#### TC-08-035 · Chạy thử quy tắc trên mẫu tái lập <!--k:dry-run-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-016 · API-08-037 · UI-08-08 · BR-08-012, 019 · PERM-08-rule-admin.

**Tiền điều kiện, dữ liệu.** Nháp v1 `RS-CITIZEN` đủ 6 quy tắc; F-SCORE (10.000 bản ghi); U-T90-DS1.

**Các bước.**

1. `POST /rule-sets/RS-CITIZEN/versions/1:dry-run` `{sampleSize: 1000, sampleSeed: 42}`
2. lặp lại với cùng `sampleSeed`
3. đếm bản ghi lỗi và ảnh chụp mới

**Kết quả mong đợi.** Bước 1 `200`, `dryRunId`, `sampleSeed = 42`, `results[]` (`passCount`, `failCount`, `errorCount`, `examples[]` đã che, `durationMs`), `estimatedScores`; ví dụ lỗi của cột Nhạy cảm chỉ có giá trị băm hoặc che. Bước 2 cùng tập khóa và cùng số đếm. Bước 3 không có bản ghi lỗi, không có ảnh chụp; phiên bản có dấu chạy thử.

:::

#### TC-08-036 · Chạy thử vượt giới hạn hoặc nguồn không khả dụng <!--k:dry-run-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-016 · API-08-037 · ERR-08-105 · ERR-08-031.

**Tiền điều kiện, dữ liệu.** `08.dryrun.max-rows = 10000`; `conn-sim` có thể ngắt.

**Các bước.**

1. `POST …:dry-run` `{sampleSize: 60000}`
2. ngắt `conn-sim` rồi `POST …:dry-run` cho `RS-HOTICH`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-031. Bước 2 `503` ERR-08-105.

**Thông báo hiển thị.** ERR-08-031: "Chạy thử tối đa 10.000 bản ghi. Giảm kích thước mẫu."; ERR-08-105: "Không đọc được nguồn của đối tượng src-hotich: kết nối bị ngắt. Thử lại sau."

:::

### TS-08-07 · Gửi duyệt, duyệt, kích hoạt và ngừng bộ quy tắc

**Mục tiêu.** Vòng đời phiên bản bộ quy tắc và bốn mắt: người soạn hoặc gửi không tự duyệt.

**Phủ.** FR-08-017, 018; UC-08-07.

#### TC-08-037 · Chạy thử, gửi duyệt, duyệt và kích hoạt <!--k:rs-submit-flow-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-017, 018 · API-08-037, 038, 039, 041 · UI-08-09 · BR-08-006 · EVT-08-01 · PERM-08-approve.

**Tiền điều kiện, dữ liệu.** Nháp v2 của `RS-CITIZEN` (v1 `ACTIVE`); DS1 soạn; U-T90-DA1; `dq-inline` đang đăng ký topic.

**Các bước.**

1. DS1 `:dry-run` rồi `:submit`
2. DS1 `:submit` rồi rút bằng `:reject` với `action = WITHDRAW`
3. DS1 `:submit` lại; DA1 `POST …/versions/2:approve` hiệu lực ngay
4. `GET /rule-sets/RS-CITIZEN/versions`

**Kết quả mong đợi.** Bước 1 `PENDING_APPROVAL`, nội dung bị khóa. Bước 2 về `DRAFT`, không tính là từ chối. Bước 3 `200`, `status = ACTIVE`, `approvedBy = DA1`, v1 thành `SUPERSEDED`; đúng một phiên bản `ACTIVE`. EVT: `ruleset.activated` (EVT-08-01) một lần. KT: có (ruleset.activate).

:::

#### TC-08-038 · Gửi duyệt khi bộ rỗng hoặc chưa chạy thử <!--k:rs-submit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-017 · API-08-038 · BR-08-006 · ERR-08-021, 053.

**Tiền điều kiện, dữ liệu.** Nháp v3 chưa có quy tắc bật; nháp v4 đã chạy thử, rồi DS1 sửa một quy tắc.

**Các bước.**

1. DS1 `:submit` v3
2. DS1 `:submit` v4 sau khi sửa

**Kết quả mong đợi.** Bước 1 `422` ERR-08-021. Bước 2 `422` ERR-08-053 vì sửa làm mất hiệu lực dấu chạy thử. Cả hai giữ `DRAFT`.

**Thông báo hiển thị.** ERR-08-021: "Phiên bản 3 chưa có quy tắc nào đang bật."; ERR-08-053: "Chạy thử phiên bản sau lần sửa cuối trước khi gửi duyệt."

:::

#### TC-08-039 · Người soạn không tự duyệt, từ chối thiếu lý do <!--k:rs-four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-017 · API-08-039, 040 · BR-08-007 · ERR-00-403 · ERR-08-005, 007.

**Tiền điều kiện, dữ liệu.** v5 chờ duyệt, DS1 gửi; U-T90-TA có cả `PERM-08-rule-admin` và `PERM-08-approve` (cấu hình sai chủ ý, chỉ SIT) và là người soạn v6.

**Các bước.**

1. DS1 `:approve` v5
2. TA `:approve` v6 do chính TA soạn
3. DA2 `:reject` v5 với lý do 10 ký tự
4. DA2 `:reject` v5 với lý do 30 ký tự
5. tenant chỉ có một người giữ `PERM-08-approve`, mở UI-08-19 và để việc duyệt chờ 6 ngày làm việc

**Kết quả mong đợi.** Bước 1 và 2 `403` ERR-08-005, trạng thái không đổi. Bước 3 `422` ERR-08-007. Bước 4 `200`, v5 về `DRAFT` kèm lý do. Bước 5 UI-08-19 cảnh báo thiếu DA dự phòng và hệ thống nhắc TA qua PH-13 khi chờ quá 5 ngày làm việc. KT: có (ruleset.reject).

**Thông báo hiển thị.** ERR-08-005: "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."; ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."

:::

#### TC-08-040 · Duyệt hiệu lực tương lai rồi tự kích hoạt <!--k:rs-approve-future-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-018 · API-08-039, 041 · BR-08-006 · EVT-08-01.

**Tiền điều kiện, dữ liệu.** v7 chờ duyệt; đồng hồ giả `clock-sim`.

**Các bước.**

1. DA2 `:approve` v7 `{effectiveFrom: 2026-12-01T00:00:00+07:00}`
2. `GET /rule-sets/RS-CITIZEN/versions`
3. đẩy `clock-sim` qua 2026-12-01T00:00
4. kiểm lại

**Kết quả mong đợi.** Bước 1 v7 `APPROVED`, v6 vẫn `ACTIVE`. Sau bước 3 v7 `ACTIVE`, v6 `SUPERSEDED`, EVT-08-01 đúng một lần, bộ đệm trực tuyến nạp v7 trong 30 giây.

:::

#### TC-08-041 · Ngừng bộ quy tắc và các chuyển trạng thái cấm <!--k:rs-retire-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-018 · API-08-041, 042 · BR-08-006 · ERR-08-007, 006, 027.

**Tiền điều kiện, dữ liệu.** `RS-HOTICH` v1 `ACTIVE`; `RS-CITIZEN` v5 `SUPERSEDED`.

**Các bước.**

1. DS1 `POST /rule-sets/RS-HOTICH:retire` lý do 10 ký tự
2. lặp với lý do 40 ký tự
3. `POST …/versions/5:activate`
4. tạo lần đo `POST /scans` cho `src-hotich`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-007. Bước 2 `200`, phiên bản `RETIRED`. Bước 3 `409` ERR-08-006. Bước 4 `422` ERR-08-027 vì không còn bộ quy tắc hiệu lực.

**Thông báo hiển thị.** ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-006: "Không thể kích hoạt khi phiên bản đang ở trạng thái SUPERSEDED."; ERR-08-027: "Đối tượng src-hotich chưa có bộ quy tắc đang hiệu lực."

:::

### TS-08-08 · So sánh phiên bản, sao chép, nhập và xuất bộ quy tắc

**Mục tiêu.** So sánh hai phiên bản, sao chép, nhập, xuất YAML hoặc JSON và các lỗi tương ứng.

**Phủ.** FR-08-019, 020; UC-08-08.

#### TC-08-042 · So sánh phiên bản và xem lịch sử <!--k:rs-diff-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-019 · API-08-028, 030, 043 · UI-08-09.

**Tiền điều kiện, dữ liệu.** `RS-CITIZEN` v1 (6 quy tắc) và v2 (thêm 1, sửa 1, đổi `ruleCode` 1).

**Các bước.**

1. `GET /rule-sets/RS-CITIZEN/versions/2/diff?against=1`
2. `GET /rule-sets/RS-CITIZEN/versions/99`

**Kết quả mong đợi.** Bước 1 `changes[]` có `ADDED`, `MODIFIED`, `REMOVED` với `before`, `after`; quy tắc đổi `ruleCode` được cảnh báo "dấu vân tay lỗi cũ không nối tiếp"; `history[]` có người duyệt, thời điểm. Bước 2 `404` ERR-08-001.

**Thông báo hiển thị.** ERR-08-001 (FR-08-019): "Không tìm thấy phiên bản 99 của bộ quy tắc RS-CITIZEN."

:::

#### TC-08-043 · Sao chép bộ quy tắc sang đối tượng cùng lược đồ và khác lược đồ <!--k:rs-copy-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-020 · API-08-044, 045 · UI-08-06 · ERR-08-026, 022.

**Tiền điều kiện, dữ liệu.** `mdm-citizen-b` cùng lược đồ; `mdm-org` thiếu trường `birthDate`; không có nháp ở đích.

**Các bước.**

1. `POST /rule-sets/RS-CITIZEN:copy` `{targetAssetCode: mdm-citizen-b}`
2. `POST …:copy` `{targetAssetCode: mdm-org}`
3. sao chép lần hai khi đích đã có nháp
4. `GET /rule-sets/RS-CITIZEN/versions/2/export?format=YAML`

**Kết quả mong đợi.** Bước 1 `201`, nháp mới, `rulesNeedingReview[]`. Bước 2 `422` ERR-08-026. Bước 3 `409` ERR-08-022. Bước 4 `200` tệp YAML.

**Thông báo hiển thị.** ERR-08-026: "Đối tượng đích thiếu trường birthDate, nationalId. Khai báo ánh xạ trường trước khi sao chép."; ERR-08-022: "Bộ quy tắc RS-CITIZEN-B đang có bản nháp phiên bản 1 do DS1 tạo."

:::

#### TC-08-044 · Nhập tệp sai lược đồ hoặc quá lớn <!--k:rs-import-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-020 · API-08-046 · ERR-08-025, 046.

**Tiền điều kiện, dữ liệu.** Tệp `sai-luoc-do.yaml` (toán tử `REGEXX` ở `rules[3]`); tệp `lon.yaml` 11 MB; giới hạn 10 MB.

**Các bước.**

1. `POST /rule-sets:import` với `sai-luoc-do.yaml`
2. `POST /rule-sets:import` với `lon.yaml`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-025 chỉ `rules[3].operator`. Bước 2 `413` ERR-08-046. Không tạo bản nháp.

**Thông báo hiển thị.** ERR-08-025: "Tệp không đúng định dạng bộ quy tắc ở rules[3: {chi tiết}."; ERR-08-046: "Tệp vượt 10 MB."

:::

### TS-08-09 · Cấu hình trọng số và ngưỡng có duyệt

**Mục tiêu.** Trọng số sáu chiều và ngưỡng có phiên bản, tổng bằng 1, bốn mắt, không hồi tố điểm quá khứ.

**Phủ.** FR-08-021; UC-08-09.

#### TC-08-045 · Soạn, gửi duyệt và duyệt cấu hình trọng số <!--k:wc-flow-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-021 · API-08-047, 048, 050, 051 · UI-08-10 · BR-08-002 · PERM-08-approve.

**Tiền điều kiện, dữ liệu.** Chưa có cấu hình T90 (dùng v0 mặc định 0,20/0,20/0,15/0,10/0,15/0,20; ngưỡng 80/70); DS1, DA1.

**Các bước.**

1. `GET /weight-configs`
2. DS1 `POST /weight-configs` `{scope: TENANT, weights: {COMPLETENESS: 0.25, ACCURACY: 0.20, CONSISTENCY: 0.15, TIMELINESS: 0.10, UNIQUENESS: 0.10, VALIDITY: 0.20}, passThreshold: 85, warnThreshold: 70}`
3. `:submit`
4. DA1 `:approve`

**Kết quả mong đợi.** Bước 1 có v0. Bước 2 `201`, `status = DRAFT`. Bước 4 `ACTIVE`, v0 `SUPERSEDED`; mỗi phạm vi đúng một cấu hình `ACTIVE`; lần đo sau dùng `weightConfigId` mới. KT: có (weight.approve).

:::

#### TC-08-046 · Tổng trọng số và ngưỡng ngoài miền <!--k:wc-neg-sum-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-021 · API-08-048, 049 · BR-08-002 · BR-08-023 · ERR-08-023, 024.

**Tiền điều kiện, dữ liệu.** Nháp cấu hình của DS1.

**Các bước.**

1. `POST` trọng số `0.20/0.20/0.15/0.10/0.15/0.25` (tổng 1,05)
2. `POST` trọng số `0.2005/0.20/0.15/0.10/0.15/0.20` (tổng 1,0005)
3. `POST` một trọng số 1,2
4. `POST` ngưỡng đạt 80, cảnh báo 85

**Kết quả mong đợi.** Bước 1 `422` ERR-08-023, thân ghi tổng 1,05. Bước 2 `201` (trong dung sai 0,001). Bước 3 `422` ERR-08-023. Bước 4 `422` ERR-08-024.

**Thông báo hiển thị.** ERR-08-023: "Tổng trọng số sáu chiều phải bằng 1 (hiện là 1,05)."; ERR-08-024: "Ngưỡng cảnh báo phải nhỏ hơn hoặc bằng ngưỡng đạt và trong khoảng 0 đến 100."

:::

#### TC-08-047 · Tự duyệt và hạ ngưỡng thiếu lý do <!--k:wc-four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-021 · API-08-051, 052 · BR-08-007 · ERR-08-005, 007.

**Tiền điều kiện, dữ liệu.** Cấu hình chờ duyệt do DS1 gửi; ngưỡng đạt hiện 80, đề xuất 70.

**Các bước.**

1. DS1 `:approve`
2. TA (có cả quyền soạn và duyệt) `:approve` cấu hình do chính TA gửi
3. DA1 `:reject` không lý do
4. `POST` hạ ngưỡng đạt từ 80 xuống 70 không lý do

**Kết quả mong đợi.** Bước 1 và 2 `403` ERR-08-005. Bước 3 và 4 `422` ERR-08-007. Cấu hình giữ nguyên.

**Thông báo hiển thị.** ERR-08-005: "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."; ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."

:::

#### TC-08-048 · Đổi trọng số không hồi tố điểm quá khứ <!--k:wc-no-retro-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-021 · FR-08-028 · API-08-065 · BR-08-008.

**Tiền điều kiện, dữ liệu.** Ảnh chụp S1 của `mdm-citizen` điểm 91,45 với cấu hình v0; DA1 vừa duyệt v1 như wc-flow; chạy lần đo S2 trên dữ liệu không đổi.

**Các bước.**

1. `GET /scans/{S1}/score`
2. chạy lần đo S2 `POST /scans`
3. `GET /scans/{S2}/score`

**Kết quả mong đợi.** S1 giữ 91,45 và `weightConfigId` v0. S2 tính theo v1 (0,25/0,20/0,15/0,10/0,10/0,20): 98×0,25 + 95×0,20 + 80×0,15 + 90×0,10 + 99×0,10 + 85×0,20 = 91,40, `weightConfigId` v1, cờ `WEIGHTS_CHANGED` ở so kỳ S1 → S2.

:::

### TS-08-10 · Lập lịch đo, đo theo yêu cầu, theo dõi và hủy

**Mục tiêu.** Lịch cron, đo theo yêu cầu có hạn mức, đo trùng, hủy, chạy lại và tự hủy khi chờ quá hạn.

**Phủ.** FR-08-023, 024, 030; UC-08-10.

#### TC-08-049 · Lập lịch đo tháng, tạm dừng và tiếp tục <!--k:sch-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-023 · API-08-054, 055, 056, 057, 058 · UI-08-11 · BR-08-001 · PERM-08-run.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` có bộ quy tắc `ACTIVE`; U-T90-TO; `08.scan.timezone = Asia/Ho_Chi_Minh`; ngày hiện tại 2026-11-26.

**Các bước.**

1. `POST /schedules` `{assetCode: mdm-citizen, cron: "0 0 2 1 * ?", mode: FULL}`
2. `POST /schedules/{id}:pause`
3. `POST /schedules/{id}:resume`
4. `GET /schedules?assetCode=mdm-citizen`
5. `PATCH /schedules/{id}` đổi `cron` thành `0 0 3 1 * ?`

**Kết quả mong đợi.** Bước 1 `201`, `nextFireAt = 2026-12-01T02:00:00+07:00`, `status = ACTIVE`. Bước 2 `PAUSED`, không bắn lần đo. Bước 3 `ACTIVE`, `nextFireAt` giữ. Bước 5 `200`, `nextFireAt` 03:00. Lịch bắn trên một bản sao duy nhất khi có hai bản sao `dh-data` (ShedLock).

:::

#### TC-08-050 · Cron quá dày, lịch trùng, chưa có bộ quy tắc <!--k:sch-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-023 · API-08-055 · BR-08-001 · ERR-08-029, 049, 027.

**Tiền điều kiện, dữ liệu.** Như sch-create; `rdm-dvhc` chưa có bộ quy tắc `ACTIVE`.

**Các bước.**

1. `POST /schedules` với `cron = "0 */5 * * * ?"`
2. `POST /schedules` lại cho `mdm-citizen` cùng chế độ `FULL`
3. `POST /schedules` cho `rdm-dvhc`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-029 (dày hơn 24 giờ). Bước 2 `409` ERR-08-049. Bước 3 `422` ERR-08-027.

**Thông báo hiển thị.** ERR-08-029: "Lịch 0 */5 * * * ? không hợp lệ hoặc dày hơn mức cho phép (24 giờ một lần)."; ERR-08-049: "Đối tượng mdm-citizen đã có lịch FULL 0 0 2 1 * ?."; ERR-08-027: "Đối tượng rdm-dvhc chưa có bộ quy tắc đang hiệu lực."

:::

#### TC-08-051 · Đo theo yêu cầu và theo dõi tiến độ <!--k:scan-manual-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-024, 030 · API-08-059, 060, 061, 067 · UI-08-11, 12 · EVT-08-02 · PERM-08-run.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` với F-SCORE (10.000 bản ghi), bộ quy tắc `ACTIVE`; không có lần đo đang chạy.

**Các bước.**

1. `POST /scans` `{assetCode: mdm-citizen, mode: FULL}` kèm `Idempotency-Key`
2. `GET /scans/{scanId}` lặp đến `SUCCEEDED`
3. `GET /scans/{scanId}/tasks`

**Kết quả mong đợi.** Bước 1 `202`, `status = QUEUED`, `estimatedRows`, `position`, `Location`. Bước 2 `progress` tăng, trạng thái `QUEUED → RUNNING → SUCCEEDED`. Bước 3 có 1 tác vụ (10.000 < `08.scan.task-size`). EVT: `scan.completed` (EVT-08-02) kèm `score`, `verdict`, `flags`.

:::

#### TC-08-052 · Đo trùng, vượt hạn mức, mẫu sai, đo năm bằng mẫu <!--k:scan-manual-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-024 · API-08-059 · BR-08-020 · ERR-08-028, 052, 030, 055.

**Tiền điều kiện, dữ liệu.** T92 (`duplicate-policy = REJECT`, `manual-per-hour = 3`); `mdm-citizen` của T92 có lần đo `RUNNING`.

**Các bước.**

1. `POST /scans` khi đang `RUNNING`
2. hủy, tạo đủ 3 lần đo rồi lần thứ 4 trong cùng giờ
3. `POST /scans` `{mode: SAMPLE, sampleSize: 50}`
4. `POST /scans` `{trigger: ANNUAL, mode: SAMPLE}`
5. `POST /scans` lần hai cùng `Idempotency-Key` nhưng thân khác
6. lặp cùng khóa, cùng thân

**Kết quả mong đợi.** Bước 1 `409` ERR-08-028. Bước 2 `429` ERR-08-052. Bước 3 và 4 `422` ERR-08-030. Bước 5 `409` ERR-08-055. Bước 6 trả lại kết quả lần đầu, không tạo lần đo mới. Với `QUEUE` (T90) bước 1 trả `202`, lần mới xếp hàng, mỗi đối tượng tối đa một lần `QUEUED` hoặc `RUNNING`.

**Thông báo hiển thị.** ERR-08-028: "Đối tượng đang có lần chạy SC-0005. Đợi lần này xong hoặc hủy."; ERR-08-052: "Đã đạt 3 lần đo theo yêu cầu trong một giờ. Thử lại sau 41 phút."; ERR-08-030: "Kích thước mẫu phải từ 100 đến 1.000.000 bản ghi; lần đo cho báo cáo năm phải đo toàn bộ."; ERR-08-055: "Khóa chống trùng này đã dùng cho một yêu cầu khác nội dung. Tạo khóa mới rồi gửi lại."

:::

#### TC-08-053 · Hủy và chạy lại lần đo <!--k:scan-cancel-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-030 · API-08-062, 063 · UI-08-12 · BR-08-020 · ERR-08-007, 006.

**Tiền điều kiện, dữ liệu.** Lần đo `RUNNING` của `src-hotich` (F-HT); U-T90-TO.

**Các bước.**

1. `POST /scans/{id}:cancel` lý do 10 ký tự
2. `POST /scans/{id}:cancel` lý do 30 ký tự
3. `POST /scans/{id}:cancel` lần nữa
4. `POST /scans/{id}:rerun`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-007. Bước 2 `200`, `CANCELLED`, không có ảnh chụp, không phát EVT-08-03. Bước 3 `409` ERR-08-006. Bước 4 `202`, `scanId` mới `QUEUED`; lần cũ không bị sửa.

**Thông báo hiển thị.** ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-006: "Không thể hủy khi lần đo đang ở trạng thái CANCELLED."

:::

#### TC-08-054 · Lần đo chờ quá hạn tự hủy <!--k:scan-timeout-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-030 · API-08-061 · ERR-08-119.

**Tiền điều kiện, dữ liệu.** T92 đặt `08.scan.queue-timeout-hours = 1`; nguồn của lần đo đang bận do lần đo khác chiếm.

**Các bước.**

1. Tạo lần đo `QUEUED`
2. đẩy `clock-sim` thêm 61 phút
3. `GET /scans/{id}`

**Kết quả mong đợi.** Lần đo thành `CANCELLED`, lý do tự động; UI-08-11 nhận ERR-08-119; không có ảnh chụp.

**Thông báo hiển thị.** ERR-08-119: "Lần đo SC-0009 chờ quá 1 giờ và đã bị hủy."

:::

#### TC-08-055 · Đo cả miền <!--k:scan-domain-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-024 · API-08-059 · UI-08-04.

**Tiền điều kiện, dữ liệu.** Miền `DAN_CU` có 3 đối tượng `ACTIVE` và 1 `SUSPENDED`.

**Các bước.**

1. `POST /scans` `{domainCode: DAN_CU, mode: FULL}`

**Kết quả mong đợi.** `202`, danh sách 3 `scanId` (mỗi đối tượng `ACTIVE` một lần đo), đối tượng `SUSPENDED` bị bỏ qua.

:::

### TS-08-11 · Đo theo lô, đối chiếu danh mục PH-07 và ghi bản ghi lỗi

**Mục tiêu.** Quy tắc đẩy xuống nguồn chỉ đọc, lấy mẫu tái lập, đối chiếu PH-07 không lưu bảng mã, xử lý quy tắc lỗi và vượt trần.

**Phủ.** FR-08-026, 027; UC-08-11.

#### TC-08-056 · Thực thi quy tắc theo lô trên mẫu F-SCORE <!--k:scan-exec-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-026 · API-08-061, 064 · UI-08-12 · BR-08-004, 025.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` với F-SCORE (bảng 2.4): 10.000 bản ghi, 6 quy tắc; lần đo `FULL`.

**Các bước.**

1. `POST /scans` `{mode: FULL}` chờ `SUCCEEDED`
2. `GET /scans/{id}/rule-results`
3. đọc nhật ký truy vấn của `mdm-sim`

**Kết quả mong đợi.** `rule-results` khớp bảng 2.4: `R-CCCD-NN` pass 9.800, fail 200; `R-CCCD-RX` pass 9.500, fail 500; `R-NS-EQ` pass 4.000, fail 1.000; `R-CAPNHAT` pass 9.000, fail 1.000; `R-CCCD-UQ` pass 9.900, fail 100; `R-GT-RDM` pass 8.500, fail 1.500. Nhật ký nguồn chỉ có truy vấn tập hợp `SELECT count(*) FILTER (...)` và truy vấn khóa lỗi có `LIMIT`, không kéo toàn bộ bản ghi về PH-08.

:::

#### TC-08-057 · Lấy mẫu tái lập theo seed <!--k:scan-sample-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-026 · API-08-059, 064 · BR-08-019 · NFR-08-008.

**Tiền điều kiện, dữ liệu.** `src-hotich` F-HT 5.000 dòng.

**Các bước.**

1. `POST /scans` `{mode: SAMPLE, sampleSize: 1000, sampleSeed: 7}` hai lần
2. so tập `recordKey` đã đo
3. đổi `sampleSeed = 8`

**Kết quả mong đợi.** Hai lần cùng seed cho cùng tập khóa và cùng số đếm; lần đo ghi `sampleSeed` 64 bit; seed khác cho tập khác. Điểm lần đo mẫu không được dùng cho báo cáo năm (xem rep-annual-neg).

:::

#### TC-08-058 · Truy vấn lên nguồn chỉ SELECT, giới hạn thời gian, song song, cửa sổ giờ <!--k:scan-src-safe-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** FR-08-026 · API-08-059 · BR-08-025 · BR-08-005.

**Tiền điều kiện, dữ liệu.** `hotich-pg-ro` có nhật ký câu lệnh; tài khoản nguồn có quyền chỉ đọc; cửa sổ `22:00-05:00`; `statement_timeout` 15 phút.

**Các bước.**

1. Chạy lần đo `FULL` với hai đối tượng cùng kết nối
2. thu nhật ký câu lệnh
3. thử `conn-sim` nhận `INSERT` giả từ tài khoản đo
4. tạo lần đo lúc 14:00

**Kết quả mong đợi.** Mọi câu lệnh là `SELECT`; tối đa 2 truy vấn đồng thời mỗi kết nối; có `statement_timeout`; không truy cập CSDL control. `INSERT` bị nguồn từ chối. Lần đo `SCHEDULE` lúc 14:00 chờ đến 22:00, lần `MANUAL` có cảnh báo ngoài cửa sổ.

:::

#### TC-08-059 · Đối chiếu danh mục PH-07 cho chiều hợp lệ <!--k:scan-rdm-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-027 · API-08-064 · BR-08-003 · NFR-08-006 · LGC-DMDC-006, 007, 008.

**Tiền điều kiện, dữ liệu.** `src-hotich` có cột `ma_dvhc`: 200 trên 5.000 mã không thuộc `DVHC` hiện hành, 30 mã là mã cũ đã chuyển (EVT-07-10); quy tắc `IN_RDM` `catalogCode = DVHC`.

**Các bước.**

1. `POST /scans` `{mode: FULL}`
2. `GET /scans/{id}/rule-results`
3. kiểm giản đồ `ph08_dq` tìm bảng chứa mã danh mục

**Kết quả mong đợi.** `failCount = 200`, `passCount = 4.800`; gợi ý mã mới cho 30 mã cũ; tra PH-07 theo lô 500 mã; không có bảng mã nào ở `ph08_dq` (BR-08-003). Đối tượng `rdm-dvhc` cũng được đo chất lượng sau mỗi lần phát hành danh mục.

:::

#### TC-08-060 · Quy tắc lỗi khi chạy, danh mục ngừng, lược đồ nguồn đổi <!--k:scan-rule-err-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-026, 027 · API-08-064 · UI-08-12 · ERR-08-107, 116.

**Tiền điều kiện, dữ liệu.** Quy tắc `R-DIV` (`CEL_EXPRESSION` chia cho trường 0 ở một số bản ghi); danh mục `DVHC-CU` đã ngừng ở `rdm-sim` (EVT-07-03); cột `ho_ten` bị xóa ở nguồn.

**Các bước.**

1. Đo `mdm-citizen` có `R-DIV`
2. đo `src-hotich` có quy tắc `IN_RDM` `DVHC-CU`
3. đo `src-hotich` có quy tắc dùng `ho_ten`

**Kết quả mong đợi.** Bước 1 `R-DIV` trạng thái `ERROR`, quy tắc khác vẫn chạy, `ERROR` không vào mẫu số điểm. Bước 2 quy tắc `ERROR`, cảnh báo quy tắc trỏ danh mục ngừng. Bước 3 quy tắc `ERROR` kèm cảnh báo cho DS.

**Thông báo hiển thị.** ERR-08-107: "Quy tắc R-DIV lỗi khi chạy: chia cho không."; ERR-08-116: "Trường ho_ten không còn ở nguồn. Quy tắc R-HOTEN không chạy được."

:::

#### TC-08-061 · Quá thời gian, vượt trần lỗi, bản ghi thiếu khóa <!--k:scan-limits-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-026 · FR-08-036 · API-08-061 · UI-08-12 · ERR-08-106 · ERR-08-110, 109.

**Tiền điều kiện, dữ liệu.** T92 (`max-duration-hours = 1`, `max-per-rule-task = 50`); nguồn trễ giả lập; F-LOI.

**Các bước.**

1. Đo khi nguồn trễ quá 1 giờ
2. đo trên F-LOI
3. đọc kết quả quy tắc

**Kết quả mong đợi.** Bước 1 lần đo dừng, ERR-08-106 ở UI-08-12 và PH-13, EVT-08-03 nếu `FAILED`. Bước 2 lưu 50 lỗi đầu, số đếm đủ 300, cờ `TRUNCATED`. Bước 3 12 bản ghi thiếu khóa thành lỗi cấu trúc `CRITICAL`.

**Thông báo hiển thị.** ERR-08-106: "Lần đo SC-0011 vượt 1 giờ và đã dừng."; ERR-08-110: "Quy tắc R-CCCD-NN có hơn 50 bản ghi lỗi. Chỉ lưu 50 bản ghi đầu, số đếm vẫn đủ."; ERR-08-109: "12 bản ghi thiếu khóa và được ghi là lỗi cấu trúc."

:::

### TS-08-12 · Tính điểm có trọng số, so kỳ trước và xu hướng

**Mục tiêu.** Công thức điểm bằng ví dụ số, chiều bị bỏ qua, ngoại lệ, kết luận theo ngưỡng, cờ `INCOMPLETE_DIMENSIONS`, `WEIGHTS_CHANGED`, xu hướng.

**Phủ.** FR-08-028, 029; UC-08-12.

#### TC-08-062 · Điểm sáu chiều và điểm tổng theo ví dụ số <!--k:score-formula-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** FR-08-028 · API-08-065 · UI-08-12 · BR-08-002, 022, 023 · NFR-08-007.

**Tiền điều kiện, dữ liệu.** F-SCORE-1 (bảng 2.4) với trọng số mặc định 0,20/0,20/0,15/0,10/0,15/0,20; mỗi chiều một quy tắc.

**Các bước.**

1. Chạy lần đo `FULL` của `mdm-citizen`
2. `GET /scans/{id}/score`
3. UT tính điểm với ví dụ của FRS (91,2; 88,0; 79,5; 72,0; 96,0; 85,0)

**Kết quả mong đợi.** Điểm chiều 98,00 (COMPLETENESS), 95,00 (ACCURACY), 80,00 (CONSISTENCY), 90,00 (TIMELINESS), 99,00 (UNIQUENESS), 85,00 (VALIDITY). Điểm tổng = 98×0,20 + 95×0,20 + 80×0,15 + 90×0,10 + 99×0,15 + 85×0,20 = 91,45; `verdict = PASS`; không cờ. Ảnh chụp ghi `ruleSetVersion`, `weightConfigId`, `passCount`, `failCount`, `skippedCount`, `waivedCount` từng chiều. EVT: `scan.completed` kèm `score = 91.45`. Ví dụ thứ hai của FRS cho 86,365, làm tròn nửa lên 86,37, `PASS` với ngưỡng 80.

:::

#### TC-08-063 · Chiều bị bỏ qua và cờ INCOMPLETE_DIMENSIONS <!--k:score-skipped-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-028, 031 · API-08-065 · UI-08-12 · BR-08-022 · ERR-08-108.

**Tiền điều kiện, dữ liệu.** Như score-formula nhưng `rdm-sim` trả `503` suốt lần đo nên `R-GT-RDM` là `SKIPPED`.

**Các bước.**

1. Chạy lần đo `FULL`
2. `GET /scans/{id}/score`

**Kết quả mong đợi.** Điểm VALIDITY rỗng (`null`), `skippedCount ≥ 1`. Điểm tổng chuẩn hóa trên năm chiều: (19,60 + 19,00 + 12,00 + 9,00 + 14,85) / 0,80 = 74,45 / 0,80 = 93,06; `verdict = PASS`; cờ `INCOMPLETE_DIMENSIONS`; UI-08-12 tô xám chiều VALIDITY kèm lý do. Không dùng 91,45 và không tính VALIDITY bằng 0.

**Thông báo hiển thị.** ERR-08-108: "Không đối chiếu được danh mục DVHC. Chiều Hợp lệ bị bỏ qua ở lần đo này."

:::

#### TC-08-064 · Mọi quy tắc bị bỏ qua thì không có điểm <!--k:score-none-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-028 · API-08-065 · UI-08-12 · ERR-08-108.

**Tiền điều kiện, dữ liệu.** Đối tượng `rdm-only` chỉ có quy tắc `IN_RDM`; `rdm-sim` trả `503`.

**Các bước.**

1. Chạy lần đo
2. `GET /scans/{id}/score`

**Kết quả mong đợi.** Lần đo kết thúc có ảnh chụp với `score = null`, `verdict` rỗng, cờ `INCOMPLETE_DIMENSIONS`, dòng "Không đủ dữ liệu để tính điểm cho lần đo {mã}."; không có điểm 0 giả; không phát EVT-08-05.

**Thông báo hiển thị.** ERR-08-108: "Không đối chiếu được danh mục DVHC. Chiều Hợp lệ bị bỏ qua ở lần đo này."

:::

#### TC-08-065 · POOLED và RULE_AVERAGE <!--k:score-pooled-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-028 · API-08-065 · BR-08-022 · ERR-08-042.

**Tiền điều kiện, dữ liệu.** Chiều CONSISTENCY có hai quy tắc, trọng số quy tắc bằng nhau: `R-A` pass 900 fail 100 (90,00); `R-B` pass 100 fail 100 (50,00).

**Các bước.**

1. Đo với `08.score.dimension-method = POOLED`
2. đổi tham số thành `RULE_AVERAGE`, đo lại cùng dữ liệu
3. đặt tham số `TRUNG_BINH`

**Kết quả mong đợi.** POOLED: 100 × 1.000 / 1.200 = 83,33. RULE_AVERAGE: (90,00 + 50,00) / 2 = 70,00. Bước 3 `422` ERR-08-042.

**Thông báo hiển thị.** ERR-08-042: "Giá trị TRUNG_BINH của 08.score.dimension-method ngoài khoảng cho phép POOLED, RULE_AVERAGE."

:::

#### TC-08-066 · Ngoại lệ và ERROR không vào mẫu số <!--k:score-waived-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-028 · FR-08-040 · API-08-065 · BR-08-021, 022.

**Tiền điều kiện, dữ liệu.** `R-CCCD-NN` pass 9.800, fail 200 trong đó 50 lỗi thuộc ngoại lệ `ACTIVE`; quy tắc `R-X` `ERROR`.

**Các bước.**

1. Đo
2. `GET /scans/{id}/score`

**Kết quả mong đợi.** Mẫu số của `R-CCCD-NN` = 9.800 + 150 = 9.950; điểm 100 × 9.800 / 9.950 = 98,49; `waivedCount = 50` hiển thị riêng; `R-X` không có trong mẫu số.

:::

#### TC-08-067 · Kết luận ở các ngưỡng biên <!--k:score-verdict-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-028 · API-08-065 · BR-08-023 · EVT-08-05.

**Tiền điều kiện, dữ liệu.** Ngưỡng 80/70; bộ dữ liệu cài sẵn cho điểm 80,00; 79,99; 70,00; 69,99; lần đo trước điểm 90.

**Các bước.**

1. Đo bốn lần với bốn bộ dữ liệu
2. ghi `verdict`
3. đếm EVT-08-05 theo lần đo

**Kết quả mong đợi.** 80,00 → `PASS`; 79,99 → `WARN`; 70,00 → `WARN`; 69,99 → `FAIL`. EVT: `score.threshold-breached` (EVT-08-05) chỉ khi chuyển từ `PASS` hoặc `WARN` sang `FAIL` hoặc xuống dưới ngưỡng cảnh báo lần đầu, không lặp ở lần `FAIL` kế tiếp.

:::

#### TC-08-068 · So kỳ trước và xu hướng <!--k:trend-cmp-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-029 · API-08-065, 066 · UI-08-04, 12 · BR-08-024 · EVT-08-04.

**Tiền điều kiện, dữ liệu.** `src-hotich` chưa từng đo; tháng 1 điểm 91,45; tháng 2 điểm 85,00; tháng 3 điểm 85,75; tháng 4 điểm 87,30.

**Các bước.**

1. Đo tháng 1
2. đo tháng 2
3. đo tháng 3
4. đo tháng 4
5. `GET /assets/src-hotich/score-history`

**Kết quả mong đợi.** Tháng 1 `trend = BASELINE`. Tháng 2 Δ = −6,45 → `DEGRADED`, EVT: `score.degraded` (EVT-08-04) vì giảm ≥ 5,0. Tháng 3 Δ = +0,75 → `STABLE`. Tháng 4 Δ = +1,55 → `IMPROVED`. Mỗi ảnh chụp có `findingsNew`, `findingsPersisting`, `findingsResolved`; `series[]` đủ bốn điểm.

:::

#### TC-08-069 · Khác cấu hình trọng số, khác phiên bản quy tắc <!--k:trend-flags-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-029 · API-08-065 · BR-08-008.

**Tiền điều kiện, dữ liệu.** Hai ảnh chụp liên tiếp khác `weightConfigId` và khác phiên bản bộ quy tắc (thêm `R-NEW`, bớt `R-OLD`).

**Các bước.**

1. `GET /scans/{id}/score`

**Kết quả mong đợi.** `flags` có `WEIGHTS_CHANGED`; thân ghi danh sách quy tắc thêm (`R-NEW`) và bớt (`R-OLD`); Δ vẫn tính.

:::

#### TC-08-070 · Chưa có ảnh chụp nào <!--k:trend-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-08-029 · API-08-065, 066.

**Tiền điều kiện, dữ liệu.** Đối tượng `src-moi` `ACTIVE` chưa có lần đo thành công.

**Các bước.**

1. `GET /assets/src-moi/score-history`

**Kết quả mong đợi.** `404` ERR-08-001 theo ngữ cảnh "chưa có lần đo nào thành công".

**Thông báo hiển thị.** ERR-08-001 (FR-08-029): "Đối tượng src-moi chưa có lần đo nào thành công."

:::

### TS-08-13 · Xử lý phụ thuộc không khả dụng khi đo

**Mục tiêu.** Nguồn hoặc PH-07 không khả dụng không bao giờ sinh điểm giả; sự kiện chờ ở hộp gửi khi PH-13, PH-16 chậm.

**Phủ.** FR-08-031; UC-08-13.

#### TC-08-071 · Nguồn không khả dụng ngay đầu lần đo <!--k:dep-source-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-031 · API-08-061, 063 · UI-08-12 · EVT-08-03 · ERR-08-105.

**Tiền điều kiện, dữ liệu.** `src-hotich`; `conn-sim` trả lỗi kết nối.

**Các bước.**

1. `POST /scans` cho `src-hotich`
2. quan sát 3 lần thử
3. bật lại `conn-sim`, `POST /scans/{id}:rerun`

**Kết quả mong đợi.** Lần đo `FAILED` sau 3 lần thử, không có ảnh chụp, `dependencyIssues[]` ghi ERR-08-105; EVT: `scan.failed` (EVT-08-03); cảnh báo vận hành tới PH-13. Lần chạy lại `SUCCEEDED`.

**Thông báo hiển thị.** ERR-08-105: "Không đọc được nguồn của đối tượng src-hotich: kết nối bị từ chối. Thử lại sau."

:::

#### TC-08-072 · Nguồn rớt giữa chừng và ngưỡng phủ 95 % <!--k:dep-partial-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-031 · API-08-061, 067 · BR-08-001 · EVT-08-02.

**Tiền điều kiện, dữ liệu.** Đối tượng 1.000.000 bản ghi, `08.scan.task-size = 20000` (50 tác vụ); `08.scan.min-coverage = 95`.

**Các bước.**

1. Ngắt nguồn khi 1 tác vụ lỗi (98 % phủ)
2. chạy lại, ngắt khi 3 tác vụ lỗi (94 % phủ)

**Kết quả mong đợi.** Bước 1 lần đo `PARTIAL`, quy tắc ở tác vụ lỗi `ERROR`, điểm tính trên tác vụ thành công, EVT: `scan.completed` kèm `flags`. Bước 2 lần đo `FAILED`, không điểm.

:::

#### TC-08-073 · PH-07 không khả dụng thì chiều hợp lệ bị bỏ qua <!--k:dep-rdm-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-031 · FR-08-027 · UI-08-12 · ERR-08-108 · NFR-08-006.

**Tiền điều kiện, dữ liệu.** `mdm-citizen`; `rdm-sim` ngừng 02:10–02:40 giả lập; ngắt mạch sau 5 lỗi liên tiếp, thử lại sau 30 giây.

**Các bước.**

1. Chạy lần đo trong lúc `rdm-sim` ngừng
2. `GET /scans/{id}`
3. bật `rdm-sim`, chạy lại

**Kết quả mong đợi.** Quy tắc `IN_RDM` `SKIPPED` ERR-08-108, các chiều khác có điểm, cờ `INCOMPLETE_DIMENSIONS`; UI-08-12 ghi "PH-07 gián đoạn 02:10–02:40". Lần chạy lại có điểm đủ sáu chiều, không cờ.

:::

#### TC-08-074 · Chiều còn quy tắc khác thì vẫn có điểm <!--k:dep-other-rule-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-031 · API-08-065 · BR-08-022.

**Tiền điều kiện, dữ liệu.** Chiều `VALIDITY` có `R-GT-RDM` (`IN_RDM`) và `R-NHOM-CEL` (`CEL_EXPRESSION` không cần PH-07).

**Các bước.**

1. Chạy lần đo khi `rdm-sim` ngừng

**Kết quả mong đợi.** `R-GT-RDM` `SKIPPED`, `R-NHOM-CEL` chạy; điểm VALIDITY tính từ `R-NHOM-CEL`; không có cờ `INCOMPLETE_DIMENSIONS`.

:::

#### TC-08-075 · PH-13, PH-16 chậm thì sự kiện nằm ở hộp gửi <!--k:dep-outbox-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-031 · FR-08-057 · EVT-08-02 · EVT-08-14 · ERR-08-113.

**Tiền điều kiện, dữ liệu.** `notif-sim` và `kpi-sim` ngừng.

**Các bước.**

1. Chạy lần đo thành công
2. kiểm hộp gửi `dq_outbox`
3. bật lại `notif-sim`, `kpi-sim` sau 10 phút

**Kết quả mong đợi.** Lần đo vẫn `SUCCEEDED`, ảnh chụp ghi; sự kiện chờ ở hộp gửi, tự thử lại và giao sau khi bật lại, không giao trùng.

:::

### TS-08-14 · Đo tăng dần theo sự kiện PH-06, PH-07

**Mục tiêu.** Đo tăng dần chỉ trên khóa đổi, không thay ảnh chụp đầy đủ, xử lý sự kiện sai định dạng.

**Phủ.** FR-08-025; UC-08-14.

#### TC-08-076 · Gom sự kiện bản ghi vàng đổi thành lần đo tăng dần <!--k:inc-event-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-025 · API-08-060, 061, 130, 131 · BR-08-033 · EVT-06-02 · EVT-06-03 · EVT-08-06.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` bật tăng dần; `08.incremental.batch-window-minutes = 15`; `mdm-sim` phát 500 sự kiện `golden.updated` và 1 `golden.merged`.

**Các bước.**

1. Phát sự kiện trong 5 phút
2. đợi hết cửa sổ
3. `GET /scans?trigger=EVENT`
4. `POST /assets/mdm-citizen:disable-incremental` rồi phát lại sự kiện, sau đó `:enable-incremental`

**Kết quả mong đợi.** Một lần đo `INCREMENTAL` `trigger = EVENT` chỉ trên 500 khóa đổi; lỗi cập nhật theo dấu vân tay; EVT-08-06 nếu có lỗi mới; lỗi của bản ghi bị hợp nhất `RESOLVED` lý do `RECORD_REMOVED`; ảnh chụp đầy đủ gần nhất không bị thay, điểm hiện hành gộp. Khi `disable-incremental` sự kiện không sinh lần đo nữa; `enable-incremental` bật lại.

:::

#### TC-08-077 · Danh mục PH-07 phát hành hoặc tổ chức lại ĐVHC <!--k:inc-rdm-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-025 · API-08-060 · EVT-07-05 · EVT-07-10 · LGC-DMDC-006, 007, 008.

**Tiền điều kiện, dữ liệu.** `rdm-dvhc` và `src-hotich` có quy tắc `IN_RDM` với `DVHC`; `rdm-sim` phát `catalog.published` rồi `adminunit.reorganized`.

**Các bước.**

1. Phát `catalog.published`
2. phát `adminunit.reorganized`
3. `GET /scans?trigger=EVENT`

**Kết quả mong đợi.** Lần đo tăng dần cho `rdm-dvhc`; sau `adminunit.reorganized` có lần đo tăng dần cho mọi đối tượng có quy tắc `IN_RDM` với `DVHC`; sự kiện `catalog.retired` làm quy tắc trỏ danh mục ngừng bị cảnh báo.

:::

#### TC-08-078 · Sự kiện sai lược đồ và đổi mô hình domain <!--k:inc-bad-event-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-025 · FR-08-002 · EVT-06-10 · ERR-08-118 · ERR-08-116.

**Tiền điều kiện, dữ liệu.** `mdm-sim` phát sự kiện thiếu `goldenId` và sự kiện `model.activated` ẩn trường `ngayCap`.

**Các bước.**

1. Phát sự kiện sai
2. phát `model.activated`
3. chạy lần đo sau

**Kết quả mong đợi.** Sự kiện sai vào hộp nhận lỗi, cảnh báo vận hành ERR-08-118 ở PH-13, không đo. `model.activated` chỉ so lược đồ, DS nhận cảnh báo; lần đo sau quy tắc dùng `ngayCap` thành `ERROR` ERR-08-116.

**Thông báo hiển thị.** ERR-08-118: "Lô dữ liệu từ {nguồn} sai định dạng: thiếu goldenId."; ERR-08-116: "Trường ngayCap không còn ở nguồn. Quy tắc R-CAPNHAT không chạy được."

:::

### TS-08-15 · Kiểm tra trực tuyến bản ghi và bước trong luồng PH-04

**Mục tiêu.** API trực tuyến trả `PASS`, `WARN`, `FAIL` đúng chế độ, không lộ giá trị, chỉ chạy quy tắc cho phép; Kamelet xử lý theo `onFail`.

**Phủ.** FR-08-032, 033; UC-08-15.

#### TC-08-079 · Kết luận PASS, WARN, FAIL ở chế độ STRICT <!--k:chk-verdict-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-032 · API-08-068, 071, 072 · UI-08-20 · BR-08-016 · PERM-08-rule-admin.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` bật trực tuyến `STRICT`, `FAIL_OPEN`; `RS-CITIZEN` v5 `ACTIVE` (`R-CCCD-NN` `CRITICAL`, `R-CAPNHAT` `MINOR`); `S-T90-PH04` scope `dq.check`.

**Các bước.**

1. `PUT /assets/mdm-citizen/inline-config` `{mode: STRICT, onDependencyFailure: FAIL_OPEN}`
2. `POST /checks:evaluate` bản ghi hợp lệ
3. bản ghi thiếu `nationalId`
4. bản ghi chỉ cũ hơn 365 ngày
5. `GET /assets/mdm-citizen/inline-config`
6. bản ghi thiếu `nationalId` và `birthDate` với `failFast = true`

**Kết quả mong đợi.** Bước 2 `200` `PASS`. Bước 3 `FAIL`, `violations[]` có `ruleCode`, `dimension`, `severity`, `fieldPath`, `message`, không chứa giá trị. Bước 4 `WARN` (chỉ `MINOR`). Mỗi phản hồi có `evaluatedRules`, `durationMs`, `ruleSetVersion = 5`. Bước 5 trả cấu hình đang đặt. Bước 6 dừng ở quy tắc `CRITICAL` đầu tiên vi phạm, `violations[]` có đúng một phần tử, `durationMs` nhỏ hơn bước 3. EVT: `check.failed` (EVT-08-13) gộp theo phút.

:::

#### TC-08-080 · ADVISORY không bao giờ FAIL <!--k:chk-advisory-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-032 · FR-08-033 · API-08-068, 071 · BR-08-016.

**Tiền điều kiện, dữ liệu.** Như chk-verdict nhưng `mode = ADVISORY`.

**Các bước.**

1. `POST /checks:evaluate` bản ghi thiếu `nationalId` (`CRITICAL`)

**Kết quả mong đợi.** `200`, `verdict` là `PASS` hoặc `WARN`, không bao giờ `FAIL`, kèm `violations[]` (ca ghi lại giá trị thực tế để chốt Q08-44); bản tin trong luồng luôn đi tiếp, chỉ gắn tiêu đề.

:::

#### TC-08-081 · Bản ghi sai lược đồ, chưa bật trực tuyến, thiếu scope, tenant khác <!--k:chk-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-032 · API-08-068 · ERR-00-403 · BR-08-026 · ERR-08-101, 102.

**Tiền điều kiện, dữ liệu.** Đối tượng `src-hotich` chưa bật trực tuyến; bản ghi 70 KB; `S-T90-NOSCOPE` không có `dq.check`; `S-T91-PH04` (T91 có `mdm-citizen` riêng).

**Các bước.**

1. `POST /checks:evaluate` bản ghi sai kiểu `birthDate`
2. bản ghi 70 KB
3. `POST /checks:evaluate` cho `src-hotich`
4. `S-T90-NOSCOPE` gọi
5. `S-T91-PH04` gọi `mdm-citizen` với bộ quy tắc khác

**Kết quả mong đợi.** Bước 1 và 2 `422` ERR-08-101. Bước 3 `404` ERR-08-102. Bước 4 `403` ERR-00-403. Bước 5 dùng bộ quy tắc của T91, không dùng của T90 (bộ đệm theo tenant).

**Thông báo hiển thị.** ERR-08-101: "Bản ghi không đúng lược đồ của đối tượng mdm-citizen: birthDate sai kiểu ngày."; ERR-08-102: "Đối tượng src-hotich chưa bật kiểm tra trực tuyến."

:::

#### TC-08-082 · Chỉ quy tắc cho phép trực tuyến được chạy <!--k:chk-rules-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-032 · API-08-068, 069 · BR-08-017 · ERR-08-045.

**Tiền điều kiện, dữ liệu.** `RS-CITIZEN` có `UNIQUE_IN_ASSET`, `EQ_SOURCE`, `SQL_PREDICATE`, CEL gán `INLINE`; `evaluate-batch` 100 và 101 bản ghi.

**Các bước.**

1. `POST /checks:evaluate`
2. xem `evaluatedRules`
3. `POST /checks:evaluate-batch` 100 bản ghi
4. 101 bản ghi

**Kết quả mong đợi.** `evaluatedRules` không gồm `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE`. Batch 100 trả 100 kết luận đúng thứ tự. Batch 101 bị từ chối `422` ERR-08-045 (giả định, xem ĐN-TC-02).

**Thông báo hiển thị.** ERR-08-045: "Tham số records không hợp lệ: tối đa 100 bản ghi mỗi lần."

:::

#### TC-08-083 · Kamelet dh-dq-check trong luồng PH-04 <!--k:chk-flow-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-033 · API-08-068 · UI-08-20 · BR-08-016, 018 · EVT-08-13.

**Tiền điều kiện, dữ liệu.** Luồng `lgsp-hotich` (PH-04 giả lập `flow-sim`) có bước `dh-dq-check` trỏ `mdm-citizen`; `S-T90-PH04`.

**Các bước.**

1. `onFail = STOP_TO_DLQ`, `STRICT`: gửi bản tin `FAIL`
2. `onFail = CONTINUE_WITH_HEADER`
3. `ADVISORY`
4. trỏ bước tới đối tượng chưa bật trực tuyến

**Kết quả mong đợi.** Bước 1 bản tin vào DLQ lý do `DQ_FAIL` kèm tiêu đề `dh-dq-verdict`, `dh-dq-violations`. Bước 2 đi tiếp kèm tiêu đề. Bước 3 luôn đi tiếp. Bước 4 runtime ghi cảnh báo luồng "Bước kiểm tra chất lượng trỏ tới đối tượng src-hotich chưa bật trực tuyến." và áp `onUnavailable`.

:::

### TS-08-16 · Cổng chất lượng cho PH-06 và giám sát kiểm tra trực tuyến

**Mục tiêu.** Cổng đầu vào PH-06, `FAIL_OPEN`, `FAIL_CLOSED` khi phụ thuộc lỗi hoặc quá ngân sách, thống kê theo phút.

**Phủ.** FR-08-034, 035; UC-08-16.

#### TC-08-084 · Cổng chất lượng đầu vào cho PH-06 <!--k:gate-mdm-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-035 · API-08-068, 071 · UI-08-20 · BR-08-016.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` bật cổng `STRICT`; `S-T90-PH06` (`dq.check`); `mdm-sim` gọi trước khi nạp ứng viên.

**Các bước.**

1. Nạp ứng viên thiếu `nationalId`
2. đổi cổng sang `ADVISORY`, nạp lại

**Kết quả mong đợi.** Bước 1 PH-06 từ chối nạp với lý do `DQ_GATE`. Bước 2 nạp được, bản ghi gắn cờ chất lượng, không bị từ chối.

:::

#### TC-08-085 · FAIL_OPEN, FAIL_CLOSED khi phụ thuộc lỗi và quá ngân sách <!--k:gate-fail-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-035 · FR-08-032 · API-08-068 · BR-08-018 · ERR-08-103 · ERR-08-104.

**Tiền điều kiện, dữ liệu.** `RS-CITIZEN` có `IN_RDM`; `rdm-sim` trả `503`; ngân sách `08.inline.timeout-ms = 10` và `rdm-sim` trễ 30 ms ở bước 4.

**Các bước.**

1. `FAIL_OPEN`: `POST /checks:evaluate`
2. `FAIL_CLOSED`: `POST /checks:evaluate`
3. cổng PH-06 ở `FAIL_CLOSED` nạp ứng viên
4. `FAIL_CLOSED`, `rdm-sim` bật lại nhưng trễ 30 ms

**Kết quả mong đợi.** Bước 1 `200` `PASS` `degraded = true`, thống kê `degraded` tăng. Bước 2 `503` ERR-08-104. Bước 3 PH-06 nhận ERR-08-104, ghi nhật ký nạp. Bước 4 `504` ERR-08-103. Mặc định không đặt là `FAIL_OPEN` (không chặn nạp dữ liệu chủ).

**Thông báo hiển thị.** ERR-08-104: "Dịch vụ đối chiếu danh mục tạm thời không khả dụng."; ERR-08-103: "Kiểm tra chất lượng vượt 10 ms."

:::

#### TC-08-086 · Thống kê kiểm tra trực tuyến theo phút <!--k:inline-stats-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-034 · API-08-070 · UI-08-20 · EVT-08-13 · LGC-BUS-027 · PERM-08-read · ERR-08-045.

**Tiền điều kiện, dữ liệu.** 1.000 lần gọi trong 10 phút từ hai bên gọi, 120 lần `FAIL` ở `R-CCCD-NN`; U-T90-TO.

**Các bước.**

1. `GET /inline-stats?from=…&to=…&resolution=MINUTE`
2. `GET /inline-stats?from=2026-01-01&to=2026-11-26&resolution=MINUTE`

**Kết quả mong đợi.** Bước 1 `series[]` theo phút, `topRules[]` đầu bảng `R-CCCD-NN`, `p95Ms`; EVT-08-13 gộp tối đa một bản tin mỗi phút mỗi đối tượng mỗi bên gọi, không chứa giá trị bản ghi. Bước 2 `422` ERR-08-045.

**Thông báo hiển thị.** ERR-08-045: "Tham số to không hợp lệ: khoảng tối đa 7 ngày với độ phân giải MINUTE."

:::

### TS-08-17 · Tra cứu, xem chi tiết và xuất bản ghi lỗi

**Mục tiêu.** Tra cứu lỗi chỉ hiện giá trị đã che, đúng phạm vi tổ chức, xem nguồn gốc, xuất có duyệt khi có trường Nhạy cảm.

**Phủ.** FR-08-037…039; UC-08-17.

#### TC-08-087 · Tra cứu, lọc và nhóm bản ghi lỗi <!--k:fnd-list-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-037 · API-08-073, 078 · UI-08-13 · BR-08-012 · PERM-08-finding-read.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` có 200 lỗi `R-CCCD-NN` `OPEN`; U-T90-DS1.

**Các bước.**

1. `GET /findings?assetCode=mdm-citizen&severity=CRITICAL&status=OPEN&page=0&size=50`
2. `GET /finding-groups?assetCode=mdm-citizen`

**Kết quả mong đợi.** Bước 1 `items[]` có `recordKeyMasked`, `ruleCode`, `dimension`, `severity`, `fieldPath`, `maskedValue`, `status`, `firstSeenAt`, `lastSeenAt`, `issueCode`; không có giá trị gốc. Bước 2 nhóm theo (đối tượng, quy tắc, chủ quản) có số đếm 200.

:::

#### TC-08-088 · DO ngoài tổ chức, VW, tenant khác, tìm theo khóa đầy đủ <!--k:fnd-scope-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-037 · API-08-073, 129 · BR-08-026 · ERR-00-403 · ERR-08-032, 001.

**Tiền điều kiện, dữ liệu.** Lỗi của `mdm-org` (ORG-TC); U-T90-DO1 (ORG-CA); U-T90-VW; U-T91-DS1.

**Các bước.**

1. DO1 `GET /findings?assetCode=mdm-org`
2. VW `GET /findings`
3. U-T91-DS1 `GET /findings/{id của T90}`
4. DS1 `POST /findings:search` với CCCD đầy đủ `001099000001`

**Kết quả mong đợi.** Bước 1 `403` ERR-08-032. Bước 2 `403` ERR-00-403. Bước 3 `404` ERR-08-001 (404-ẩn). Bước 4 trả lỗi khớp qua HMAC của khóa, nhật ký và URL không chứa CCCD.

**Thông báo hiển thị.** ERR-08-032: "Đối tượng mdm-org không thuộc tổ chức của anh/chị."; ERR-08-001: "Không tìm thấy bản ghi lỗi FD-0001 trong tỉnh đang làm việc."

:::

#### TC-08-089 · Chi tiết bản ghi lỗi và nguồn gốc <!--k:fnd-detail-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-038 · API-08-074 · UI-08-14 · PERM-08-finding-read.

**Tiền điều kiện, dữ liệu.** Lỗi `FD-0102` của `mdm-citizen`; `mdm-sim` trả nguồn gốc "HTTT Hộ tịch, 12/10/2026"; DS1 có `PERM-06-read`.

**Các bước.**

1. `GET /findings/FD-0102`
2. tắt `mdm-sim`, `GET /findings/FD-0102`
3. `GET /findings/FD-9999`

**Kết quả mong đợi.** Bước 1 `200`, `rule`, `history[]`, `lineage`, `suggestedOwnerOrgId`. Bước 2 vẫn `200` với dòng "Chưa lấy được nguồn gốc từ PH-06, thử lại sau.", không mã lỗi. Bước 3 `404` ERR-08-001 ("Không tìm thấy bản ghi lỗi FD-9999.").

**Thông báo hiển thị.** ERR-08-001 (FR-08-038): "Không tìm thấy bản ghi lỗi FD-9999."

:::

#### TC-08-090 · Xuất có trường Nhạy cảm cần DO chấp thuận <!--k:exp-sens-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-039 · API-08-075, 076, 077 · BR-08-007, 027 · PERM-08-export · ERR-08-041.

**Tiền điều kiện, dữ liệu.** 5.000 lỗi có cột `nationalId`; DS1 đề nghị; U-T90-DO1 chấp thuận.

**Các bước.**

1. DS1 `POST /findings:export` lý do 30 ký tự
2. DS1 `GET /exports/{id}`
3. DO1 `POST /exports/{id}:approve`
4. DS1 `GET /exports/{id}` đến `READY`, tải tệp
5. sau 25 giờ tải lại

**Kết quả mong đợi.** Bước 1 `202`, `containsSensitive = true`, `PENDING_APPROVAL`. Bước 2 `409` ERR-08-041. Bước 4 `200`, tệp chỉ giá trị băm hoặc che, quét canary sạch. Bước 5 `410` ERR-08-041 (hạn tải 24 giờ). KT: có (finding.export, export.approve).

**Thông báo hiển thị.** ERR-08-041: "Tệp xuất EX-0001 chưa được chấp thuận hoặc đã hết hạn tải."

:::

#### TC-08-091 · Tự chấp thuận xuất, thiếu mục đích <!--k:exp-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-039 · API-08-075, 076 · BR-08-007 · ERR-08-007.

**Tiền điều kiện, dữ liệu.** Yêu cầu xuất chờ chấp thuận do DS1 đề nghị.

**Các bước.**

1. DS1 `POST /exports/{id}:approve`
2. DS1 `POST /findings:export` lý do 10 ký tự

**Kết quả mong đợi.** Bước 1 `403` ERR-08-005 (câu "người đề nghị xuất"). Bước 2 `422` ERR-08-007.

**Thông báo hiển thị.** ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-005 (FR-08-039): "Anh/chị là người đề nghị xuất nên không được tự chấp thuận."

:::

### TS-08-18 · Ngoại lệ chấp nhận có hạn và có duyệt

**Mục tiêu.** Ngoại lệ có hạn tối đa 180 ngày, phạm vi cụ thể, duyệt bốn mắt, hết hạn tự mở lại lỗi.

**Phủ.** FR-08-040; UC-08-18.

#### TC-08-092 · Đề nghị, duyệt và hết hạn ngoại lệ <!--k:wv-flow-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-040 · API-08-079, 080, 081 · UI-08-14 · BR-08-021 · EVT-08-10 · PERM-08-approve.

**Tiền điều kiện, dữ liệu.** 3 lỗi `OPEN` của `mdm-citizen`; DS1, DA1; `clock-sim`.

**Các bước.**

1. DS1 `POST /waivers` `{scope: FINDINGS, findingIds: [3 lỗi], reason: ≥ 50 ký tự, validUntil: +90 ngày}`
2. DA1 `POST /waivers/{id}:approve`
3. chạy lần đo kế tiếp
4. đẩy `clock-sim` qua `validUntil`, chạy job hằng ngày

**Kết quả mong đợi.** Bước 1 `PENDING_APPROVAL`. Bước 2 `ACTIVE`, lỗi `WAIVED`, EVT: `waiver.approved` (EVT-08-10). Bước 3 lỗi `WAIVED` không vào mẫu số, đếm riêng. Bước 4 `EXPIRED`, lỗi về `OPEN` và tính lại ở lần đo sau. KT: có (waiver.approve).

:::

#### TC-08-093 · Hạn quá trần, phạm vi rỗng, lý do ngắn, tự duyệt <!--k:wv-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-040 · API-08-079, 081 · BR-08-007, 021 · ERR-08-033, 007.

**Tiền điều kiện, dữ liệu.** `08.waiver.max-days = 180`; DS1, DA1.

**Các bước.**

1. DS1 `POST /waivers` `validUntil` +200 ngày
2. `POST /waivers` `findingIds = []`
3. `POST /waivers` lý do 30 ký tự
4. DS1 `POST /waivers/{id}:approve` ngoại lệ do mình đề nghị

**Kết quả mong đợi.** Bước 1 và 2 `422` ERR-08-033. Bước 3 `422` ERR-08-007 (tối thiểu 50 ký tự). Bước 4 `403` ERR-08-005 (câu "người đề nghị ngoại lệ").

**Thông báo hiển thị.** ERR-08-033: "Ngoại lệ tối đa 180 ngày và phải có phạm vi lỗi cụ thể."; ERR-08-007: "Nhập lý do (tối thiểu 50 ký tự)."; ERR-08-005 (FR-08-040): "Anh/chị là người đề nghị ngoại lệ nên không được tự duyệt."

:::

#### TC-08-094 · Từ chối và thu hồi ngoại lệ <!--k:wv-reject-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-040 · API-08-082, 083 · UI-08-14.

**Tiền điều kiện, dữ liệu.** Một ngoại lệ `PENDING_APPROVAL`, một ngoại lệ `ACTIVE`.

**Các bước.**

1. DA1 `POST /waivers/{id}:reject` kèm lý do
2. DA1 `POST /waivers/{id}:revoke` kèm lý do

**Kết quả mong đợi.** Bước 1 `REJECTED`, lỗi vẫn `OPEN`. Bước 2 `REVOKED`, lỗi về `OPEN`, tính lại ở lần đo sau.

:::

### TS-08-19 · Mở phiếu khắc phục, phân công và theo dõi SLA

**Mục tiêu.** Mở phiếu từ nhóm lỗi, chủ quản lấy từ miền, SLA theo mức và ngày làm việc, tự mở khi vượt ngưỡng, phân công trong tổ chức.

**Phủ.** FR-08-041, 042; UC-08-19.

#### TC-08-095 · Mở phiếu khắc phục từ nhóm lỗi <!--k:iss-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-041, 042 · API-08-078, 084, 086, 087 · UI-08-13, 15 · EVT-08-07 · PERM-08-remediate.

**Tiền điều kiện, dữ liệu.** 12 lỗi `R-CCCD-NN` `CRITICAL` của `mdm-citizen` (miền DAN_CU, chủ quản ORG-CA); DS1.

**Các bước.**

1. `GET /finding-groups?assetCode=mdm-citizen`
2. `POST /issues` `{findingGroup: …, severity: CRITICAL}`
3. `GET /issues/{code}`
4. DO1 `POST /issues/{code}:assign` cho `U-T90-DO1-NV` cùng ORG-CA

**Kết quả mong đợi.** Bước 2 `201`, `issueCode = DQ-2026-000001`, `status = ASSIGNED` hoặc `OPEN`, `ownerOrgId = ORG-CA`, `findingCount = 12`, `dueDate`; 12 lỗi thành `IN_REMEDIATION`. Bước 4 `200`, `assigneeUserId`, `slaRemainingDays`. EVT: `issue.created` (EVT-08-07).

:::

#### TC-08-096 · Lỗi đã thuộc phiếu khác, giao người ngoài tổ chức <!--k:iss-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-041, 042 · API-08-084, 087 · BR-08-026 · ERR-08-034, 007.

**Tiền điều kiện, dữ liệu.** Phiếu `DQ-2026-000001` đang mở với 12 lỗi; DO1 (ORG-CA); người dùng `U-T90-XX` thuộc ORG-TC.

**Các bước.**

1. DS1 `POST /issues` chọn 12 lỗi đó
2. DO1 `POST /issues/DQ-2026-000001:assign` cho `U-T90-XX`
3. DS1 `:assign` đổi hạn thiếu lý do

**Kết quả mong đợi.** Bước 1 `409` ERR-08-034. Bước 2 `403` ERR-08-032 (người được giao không thuộc tổ chức). Bước 3 `422` ERR-08-007.

**Thông báo hiển thị.** ERR-08-034: "Có 12 bản ghi lỗi đã thuộc phiếu DQ-2026-000001. Bỏ chọn hoặc gắn vào phiếu đó."; ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-032 (FR-08-042): "Người được giao không thuộc tổ chức Công an tỉnh."

:::

#### TC-08-097 · Hạn SLA theo mức nghiêm trọng và ngày làm việc <!--k:iss-sla-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-042 · API-08-084, 085 · BR-08-015.

**Tiền điều kiện, dữ liệu.** `08.issue.sla-days`: `CRITICAL` 5, `MAJOR` 15, `MINOR` 30 ngày làm việc; mở phiếu lúc thứ Sáu 2026-12-04; Q08-43 (lịch nghỉ lễ).

**Các bước.**

1. Mở một phiếu mỗi mức
2. đọc `dueDate`, `slaRemainingDays`

**Kết quả mong đợi.** `CRITICAL` hạn 2026-12-11 (thứ Sáu tuần sau, bỏ thứ Bảy, Chủ nhật); `MAJOR` 2026-12-25; `MINOR` 2027-01-15 (lịch làm việc giả định chỉ trừ thứ Bảy, Chủ nhật; ngày nghỉ lễ chờ Q08-43). `overdue = false`.

:::

#### TC-08-098 · Tự mở phiếu khi lỗi CRITICAL mới vượt ngưỡng <!--k:iss-auto-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-041 · API-08-084 · BR-08-035 · EVT-08-07.

**Tiền điều kiện, dữ liệu.** `08.issue.auto-open-critical = 100`; lần đo `FAIL`.

**Các bước.**

1. Lần đo A: 101 lỗi `CRITICAL` mới
2. lần đo B: 100 lỗi `CRITICAL` mới
3. đặt tham số 0, lần đo có 500 lỗi

**Kết quả mong đợi.** A tự mở một phiếu gộp theo (đối tượng, quy tắc). B không mở. Với tham số 0 không phiếu nào được tự mở.

:::

### TS-08-20 · Nhận, xử lý và cập nhật tiến độ phiếu khắc phục

**Mục tiêu.** Chủ quản nhận, bắt đầu, trao đổi, đính kèm trên phiếu và bị chặn đúng phạm vi.

**Phủ.** FR-08-043; UC-08-20.

#### TC-08-099 · Bắt đầu xử lý và trao đổi trên phiếu <!--k:iss-progress-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-043 · API-08-085, 086, 088, 089, 097 · UI-08-15, 16 · EVT-08-08 · PERM-08-remediate.

**Tiền điều kiện, dữ liệu.** Phiếu `DQ-2026-000001` `ASSIGNED` cho ORG-CA; DO1.

**Các bước.**

1. DO1 `GET /issues?scope=MINE`
2. `POST /issues/DQ-2026-000001:start`
3. `POST /issues/DQ-2026-000001/activities` `{type: COMMENT, body: "@DS1 đã sửa 8/12"}` kèm tệp 1 MB
4. `GET /issues/DQ-2026-000001/activities`

**Kết quả mong đợi.** `IN_PROGRESS`; hoạt động `COMMENT`, `ATTACHMENT` có dòng thời gian; nhắc `@DS1` gửi thông báo riêng; EVT: `issue.status-changed` (EVT-08-08) khi đổi trạng thái.

:::

#### TC-08-100 · Phiếu đã hủy, tệp quá lớn, DO khác tổ chức <!--k:iss-progress-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-043 · API-08-089, 086 · BR-08-026 · ERR-08-006, 046, 032.

**Tiền điều kiện, dữ liệu.** Phiếu `CANCELLED`; phiếu của ORG-CA; DO2 thuộc ORG-TC.

**Các bước.**

1. DO1 `POST …/activities` trên phiếu `CANCELLED`
2. DO1 đính tệp 26 MB
3. DO2 `GET /issues/DQ-2026-000001`

**Kết quả mong đợi.** Bước 1 `409` ERR-08-006. Bước 2 `413` ERR-08-046. Bước 3 `403` ERR-08-032.

**Thông báo hiển thị.** ERR-08-006: "Không thể cập nhật khi phiếu đang ở trạng thái CANCELLED."; ERR-08-046: "Tệp vượt 25 MB."; ERR-08-032: "Đối tượng DQ-2026-000001 không thuộc tổ chức của anh/chị."

:::

### TS-08-21 · Báo đã sửa, đo lại kiểm chứng và xác nhận phiếu

**Mục tiêu.** Chủ quản không tự xác nhận; `VERIFIED` chỉ do lần đo `VERIFY` sạch hoặc DS xác nhận có lý do; lỗi kỹ thuật giữ `FIXED`.

**Phủ.** FR-08-044; UC-08-21.

#### TC-08-101 · Báo đã sửa và đo kiểm chứng sạch <!--k:ver-clean-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-044 · API-08-090, 086 · UI-08-16 · BR-08-014, 034 · NFR-08-014 · EVT-08-09.

**Tiền điều kiện, dữ liệu.** Phiếu `IN_PROGRESS` 12 lỗi `R-CCCD-NN`; DO1 đã sửa nguồn; `08.verify.wait-mdm-minutes = 0` ở TEST.

**Các bước.**

1. DO1 `POST /issues/{code}:mark-fixed` `{note: ≥ 20 ký tự}`
2. chờ lần đo `VERIFY`
3. `GET /issues/{code}`

**Kết quả mong đợi.** Bước 1 `202`, `verifyScanId`, phiếu `FIXED`. Lần `VERIFY` chỉ trên 12 khóa, sạch → phiếu `VERIFIED`, 12 lỗi `RESOLVED` (`CLEARED`), EVT: `issue.verified` (EVT-08-09). Tổng thời gian ≤ 5 phút với ≤ 10.000 khóa.

:::

#### TC-08-102 · Đo kiểm chứng vẫn còn lỗi <!--k:ver-reopen-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-044 · API-08-090 · BR-08-034.

**Tiền điều kiện, dữ liệu.** Phiếu `FIXED` nhưng 3 trên 12 lỗi vẫn còn ở nguồn.

**Các bước.**

1. Chạy `VERIFY`
2. `GET /issues/{code}`

**Kết quả mong đợi.** Phiếu `REOPENED`, 9 lỗi `RESOLVED`, 3 lỗi `IN_REMEDIATION`; DO báo sửa lại được.

:::

#### TC-08-103 · Chủ quản tự xác nhận, báo sửa thiếu ghi chú, DS xác nhận thủ công <!--k:ver-self-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-044 · API-08-090, 091 · BR-08-014 · ERR-08-036, 035, 007.

**Tiền điều kiện, dữ liệu.** Phiếu `FIXED`; nguồn `src-cu` đã ngừng nên không đo lại được; DO1, DS1.

**Các bước.**

1. DO1 `POST /issues/{code}:mark-fixed` ghi chú 10 ký tự
2. DO1 `POST /issues/{code}:verify`
3. DS1 `:verify` lý do 30 ký tự
4. DS1 `:verify` `{mode: MANUAL}` lý do 60 ký tự

**Kết quả mong đợi.** Bước 1 `422` ERR-08-036. Bước 2 `403` ERR-08-035. Bước 3 `422` ERR-08-007 (tối thiểu 50 ký tự). Bước 4 `200`, `VERIFIED`, lỗi `RESOLVED` lý do `MANUAL_CONFIRMED`, KT ghi lý do.

**Thông báo hiển thị.** ERR-08-036: "Mô tả việc đã sửa (tối thiểu 20 ký tự) trước khi báo đã sửa."; ERR-08-035: "Chủ quản không tự xác nhận phiếu. Hệ thống sẽ đo lại để kiểm chứng."; ERR-08-007: "Nhập lý do (tối thiểu 50 ký tự)."

:::

#### TC-08-104 · Đo kiểm chứng lỗi kỹ thuật giữ phiếu FIXED <!--k:ver-tech-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-044 · API-08-090 · UI-08-16 · ERR-08-115.

**Tiền điều kiện, dữ liệu.** Phiếu vừa báo `FIXED`; `conn-sim` ngắt khi lần `VERIFY` chạy; `clock-sim`.

**Các bước.**

1. Lần `VERIFY` `FAILED` do nguồn ngắt
2. đẩy `clock-sim` 1 giờ, lặp lần nữa (tối đa 3 lần)
3. sau lần thứ ba vẫn lỗi

**Kết quả mong đợi.** Phiếu giữ `FIXED` (không `REOPENED`), hiển thị ERR-08-115, hệ thống thử lại sau 1 giờ; sau 3 lần giao DS xử lý.

**Thông báo hiển thị.** ERR-08-115: "Đo kiểm chứng phiếu DQ-2026-000001 lỗi kỹ thuật. Hệ thống sẽ thử lại."

:::

### TS-08-22 · Từ chối, chuyển, leo thang phiếu và chuyển lỗi bản ghi vàng sang PH-06

**Mục tiêu.** Từ chối, chuyển, hủy, leo thang theo ngày quá hạn và chuyển lỗi bản ghi vàng sang hàng đợi steward PH-06.

**Phủ.** FR-08-045, 046; UC-08-22.

#### TC-08-105 · Từ chối, chuyển, hủy phiếu <!--k:iss-reject-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-045 · API-08-092, 093, 096 · UI-08-15, 16 · EVT-08-08 · ERR-08-007, 006.

**Tiền điều kiện, dữ liệu.** Phiếu `ASSIGNED` cho ORG-CA (đúng ra thuộc ORG-TC); DO1, DS1.

**Các bước.**

1. DO1 `POST /issues/{code}:reject` `{type: WRONG_OWNER}` lý do 10 ký tự
2. DO1 `:reject` lý do 30 ký tự
3. DS1 `:transfer` sang ORG-TC
4. DS1 `:cancel` một phiếu khác `OPEN` lý do đủ dài
5. DS1 `:reject` phiếu `VERIFIED`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-007. Bước 2 `REJECTED`, về DS. Bước 3 `ASSIGNED` cho ORG-TC. Bước 4 `CANCELLED`. Bước 5 `409` ERR-08-006. EVT: `issue.status-changed` mỗi lần đổi.

**Thông báo hiển thị.** ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-006: "Không thể từ chối khi phiếu đang ở trạng thái VERIFIED."

:::

#### TC-08-106 · Leo thang phiếu quá hạn <!--k:iss-escalate-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-045 · API-08-094 · BR-08-015 · EVT-08-08.

**Tiền điều kiện, dữ liệu.** Phiếu `CRITICAL` quá hạn; `08.issue.escalate-after-overdue-days = 5`; `clock-sim`.

**Các bước.**

1. Đẩy `clock-sim` qua hạn + 5 ngày làm việc, chạy job hằng ngày
2. đẩy thêm 5 ngày
3. DS1 `POST /issues/{code}:escalate` thủ công cho phiếu còn hạn

**Kết quả mong đợi.** Sau bước 1 `escalationLevel = 1`; sau bước 2 `escalationLevel = 2`; mỗi lần EVT-08-08 và thông báo PH-13. Bước 3 leo thang thủ công trước hạn khi lỗi `CRITICAL` ảnh hưởng liên thông.

:::

#### TC-08-107 · Chuyển lỗi bản ghi vàng sang hàng đợi PH-06 <!--k:iss-steward-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-046 · API-08-095 · BR-08-004 · ERR-08-105 · ERR-08-051.

**Tiền điều kiện, dữ liệu.** Lỗi `UNIQUENESS` của `mdm-citizen`; lỗi của `src-hotich`; `mdm-sim` đã có mục mở cho một `goldenId`.

**Các bước.**

1. DS1 `POST /issues/{code}:send-to-steward` (lỗi MDM)
2. cùng lệnh với lỗi `goldenId` đã có mục mở
3. cùng lệnh với lỗi `src-hotich`
4. tắt `mdm-sim`, lặp bước 1

**Kết quả mong đợi.** Bước 1 `200`, `stewardItemIds[]`, mục PH-06 lý do `DQ_FINDING`. Bước 2 gắn thêm lý do, không tạo trùng. Bước 3 `422` ERR-08-051. Bước 4 `503` ERR-08-105. PH-08 không sửa bản ghi vàng.

**Thông báo hiển thị.** ERR-08-051: "Chỉ lỗi của bản ghi vàng mới chuyển được sang hàng đợi dữ liệu chủ."; ERR-08-105: "Không đọc được nguồn của đối tượng mdm-citizen: PH-06 không khả dụng. Thử lại sau."

:::

### TS-08-23 · Khai báo, phát và xử lý cảnh báo chất lượng

**Mục tiêu.** Quy tắc cảnh báo, một cảnh báo chưa giải quyết mỗi cặp quy tắc và đối tượng, nhắc lại, xác nhận, tắt tiếng có hạn.

**Phủ.** FR-08-047…049; UC-08-23.

#### TC-08-108 · Khai báo quy tắc cảnh báo <!--k:al-rule-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-047 · API-08-098, 099, 100 · UI-08-17 · PERM-08-rule-admin · ERR-08-037.

**Tiền điều kiện, dữ liệu.** T90; DS1.

**Các bước.**

1. `POST /alert-rules` `{condition: SCORE_BELOW, threshold: 80, severity: HIGH, assetCode: mdm-citizen}`
2. `PUT /alert-rules/AR-01` đổi ngưỡng 75
3. `POST /alert-rules` `{condition: SCORE_BELOW, threshold: -5}`
4. `GET /alert-rules`

**Kết quả mong đợi.** Bước 1 `201`, bước 2 `200`. Bước 3 `422` ERR-08-037. Bước 4 có quy tắc mặc định và quy tắc vừa tạo; tắt quy tắc mặc định thay vì xóa.

**Thông báo hiển thị.** ERR-08-037: "Quy tắc cảnh báo AR-02 không hợp lệ: ngưỡng phải trong khoảng 0 đến 100."

:::

#### TC-08-109 · Phát cảnh báo, không trùng, nhắc lại, tự giải quyết và PH-13 lỗi <!--k:al-fire-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-048 · API-08-101 · UI-08-17 · BR-08-029 · EVT-08-12 · ERR-08-114.

**Tiền điều kiện, dữ liệu.** Quy tắc `AR-01` `SCORE_BELOW` 80 cho `mdm-citizen`; `notif-sim`; `08.alert.repeat-hours = 4`; `clock-sim`.

**Các bước.**

1. Lần đo điểm 78
2. lần đo kế tiếp điểm 75 sau 1 giờ
3. sau 4 giờ lần đo điểm 74
4. lần đo điểm 85
5. tắt `notif-sim`, lần đo điểm 70 làm cảnh báo mới `FIRING`, chờ 65 phút

**Kết quả mong đợi.** Bước 1 một cảnh báo `FIRING`, EVT: `alert.fired` (EVT-08-12), `notif-sim` nhận. Bước 2 không tạo cảnh báo thứ hai, không nhắc. Bước 3 nhắc lại một lần. Bước 4 `RESOLVED`, EVT-08-12 `RESOLVED`. Bước 5 sự kiện nằm ở hộp gửi, thử lại; quá 1 giờ UI-08-17 ghi ERR-08-114.

**Thông báo hiển thị.** ERR-08-114: "Cảnh báo hoặc thông báo AL-0007 chưa gửi được tới kênh thông báo."

:::

#### TC-08-110 · Xác nhận, tắt tiếng và giới hạn 7 ngày <!--k:al-ack-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-049 · API-08-102, 103 · BR-08-029 · ERR-08-007, 006.

**Tiền điều kiện, dữ liệu.** Cảnh báo `FIRING`; cảnh báo khác `RESOLVED`; DS1.

**Các bước.**

1. `POST /alerts/{id}:acknowledge`
2. `POST /alerts/{id}:silence` `{reason: ≥ 20 ký tự, until: +3 ngày}`
3. `:silence` `until: +10 ngày`
4. `:acknowledge` cảnh báo `RESOLVED`

**Kết quả mong đợi.** Bước 1 `ACKNOWLEDGED`. Bước 2 `SILENCED`, không phát lại trong 3 ngày. Bước 3 `422` ERR-08-007 (thời hạn không quá 7 ngày). Bước 4 `409` ERR-08-006.

**Thông báo hiển thị.** ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."; ERR-08-006: "Không thể xác nhận khi cảnh báo đang ở trạng thái RESOLVED."

:::

### TS-08-24 · Bảng điều khiển, thẻ điểm và so sánh liên tenant

**Mục tiêu.** Bảng điều khiển, thẻ điểm đúng số liệu và phạm vi vai trò, thẻ điểm lịch sử bất biến, so sánh liên tenant ẩn danh.

**Phủ.** FR-08-050, 051, 061; UC-08-24.

#### TC-08-111 · Bảng điều khiển và thẻ điểm tenant <!--k:dash-view-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-050, 051 · API-08-104, 105, 106 · UI-08-01, 04 · NFR-08-010 · PERM-08-read.

**Tiền điều kiện, dữ liệu.** T90 có `mdm-citizen` điểm 91,45 (10.000 bản ghi) và `src-hotich` điểm 80,00 (30.000 bản ghi); U-T90-DS1, U-T90-VW, U-T90-DO1.

**Các bước.**

1. DS1 `GET /dashboard`
2. VW `GET /dashboard`
3. DO1 `GET /dashboard`
4. DS1 `GET /scorecards/assets/mdm-citizen?asOf=2026-10-31`

**Kết quả mong đợi.** Bước 1 `tenantScore` = (91,45 × 10.000 + 80,00 × 30.000) / 40.000 = 82,86; có `domains[]`, `radar`, `trend[]` 13 tháng, `counters{}`, `coverage`. Bước 2 chỉ số tổng hợp, không có liên kết tới danh sách lỗi. Bước 3 phần của ORG-CA nổi bật. Bước 4 trả ảnh chụp bất biến tại thời điểm đó.

:::

#### TC-08-112 · Ngoài phạm vi tổ chức, HTTT đọc thẻ điểm không phải của mình, chưa có số liệu <!--k:dash-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-050, 051 · API-08-104, 106 · BR-08-026 · ERR-08-032, 001.

**Tiền điều kiện, dữ liệu.** DO1 (ORG-CA); `S-T90-HTTT-HT` (scope `dq.read`, HTTT hộ tịch); đối tượng `src-moi` chưa đo; tenant T93 chưa có lần đo.

**Các bước.**

1. DO1 `GET /dashboard?orgId=ORG-TC`
2. `S-T90-HTTT-HT` `GET /scorecards/assets/mdm-org`
3. DS1 `GET /scorecards/assets/src-moi`
4. T93 `GET /dashboard`

**Kết quả mong đợi.** Bước 1 và 2 `403` ERR-08-032. Bước 3 `404` ERR-08-001. Bước 4 `200` trạng thái trống "Chưa có số liệu. Đăng ký đối tượng đo và chạy lần đo đầu tiên." (không phải lỗi).

**Thông báo hiển thị.** ERR-08-032: "Đối tượng mdm-org không thuộc tổ chức của anh/chị."; ERR-08-001: "Không tìm thấy đối tượng đo src-moi trong tỉnh đang làm việc."

:::

#### TC-08-113 · So sánh liên tenant ẩn danh <!--k:bench-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-08-061 · API-08-128 · UI-08-01 · BR-08-030 · PERM-08-read.

**Tiền điều kiện, dữ liệu.** T90…T95 và T96 đặt `08.benchmark.opt-in = true` (6 tenant); U-PA; U-T90-TA.

**Các bước.**

1. PA `GET /platform/benchmarks`
2. TA T90 `GET /platform/benchmarks`

**Kết quả mong đợi.** Có `median`, `p25`, `p75`, `participants = 6`; không nêu tên tenant khác. Với TA có thêm `myPercentile`.

:::

#### TC-08-114 · Nhóm nhỏ hơn 5 hoặc tenant chưa tham gia <!--k:bench-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-08-061 · API-08-128 · BR-08-030 · ERR-08-044.

**Tiền điều kiện, dữ liệu.** Chỉ 4 tenant đã opt-in; T97 chưa opt-in; U-T97-TA.

**Các bước.**

1. PA `GET /platform/benchmarks`
2. U-T97-TA `GET /platform/benchmarks`

**Kết quả mong đợi.** Bước 1 `422` ERR-08-044. Bước 2 `409` ERR-08-006 ("Tỉnh chưa bật tham gia so sánh chất lượng.").

**Thông báo hiển thị.** ERR-08-044: "Chưa đủ 5 tỉnh tham gia để so sánh ẩn danh."; ERR-08-006 (FR-08-061): "Tỉnh chưa bật tham gia so sánh chất lượng."

:::

### TS-08-25 · Báo cáo kỳ, duyệt, công bố và báo cáo chính thức hằng năm

**Mục tiêu.** Báo cáo kỳ, duyệt bốn mắt, công bố bất biến, thu hồi; báo cáo năm chỉ công bố khi mọi đối tượng có lần đo `FULL` đủ chiều.

**Phủ.** FR-08-052…054; UC-08-25.

#### TC-08-115 · Sinh báo cáo kỳ và báo cáo thiếu lần đo trong kỳ <!--k:rep-periodic-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-052 · API-08-107, 108, 109 · UI-08-18 · PERM-08-report · ERR-08-112.

**Tiền điều kiện, dữ liệu.** T90 có 3 đối tượng đo thành công trong 2026-11, một đối tượng không; T95 không có lần đo nào; DS1.

**Các bước.**

1. DS1 `POST /reports` `{type: PERIODIC, period: 2026-11}`
2. `GET /reports/{code}`
3. `GET /reports?type=PERIODIC&page=0&size=10`
4. T95 `POST /reports` `{type: PERIODIC, period: 2026-11}`
5. tắt kho tệp rồi `POST /reports`

**Kết quả mong đợi.** Bước 1 `201`, `reportCode = BC-DQ-2026-11-T90`, `DRAFT`, `missingAssets[]` có đối tượng chưa đo, `recommendations[]` gợi ý. Bước 3 `422` ERR-08-027 theo ngữ cảnh. Bước 4 thông báo ERR-08-112 trong ứng dụng, không có báo cáo dở dang.

**Thông báo hiển thị.** ERR-08-112: "Không tạo được báo cáo BC-DQ-2026-11-T90. Thử lại sau."; ERR-08-027 (FR-08-052): "Không có lần đo thành công nào trong kỳ 2026-11 để lập báo cáo."

:::

#### TC-08-116 · Gửi duyệt, duyệt và công bố báo cáo <!--k:rep-flow-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-053 · API-08-110, 111, 112 · UI-08-18 · BR-08-007, 009 · EVT-08-11 · PERM-08-approve.

**Tiền điều kiện, dữ liệu.** Báo cáo `DRAFT` (rep-periodic); DS1, DA1.

**Các bước.**

1. DS1 `PATCH /reports/{code}` thêm khuyến nghị
2. DS1 `:submit`
3. DA1 `:approve`
4. `GET /reports/{code}`

**Kết quả mong đợi.** `IN_REVIEW` rồi `PUBLISHED` với `contentHash`, `publishedAt`, `approvedBy = DA1`; nội dung bất biến. EVT: `report.published` (EVT-08-11). KT: có (report.publish).

:::

#### TC-08-117 · Thiếu khuyến nghị, tự duyệt, sửa báo cáo đã công bố, thu hồi <!--k:rep-flow-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-053 · API-08-111, 112, 113, 114, 110 · BR-08-009, 011 · ERR-08-039, 005, 040, 007.

**Tiền điều kiện, dữ liệu.** Báo cáo `DRAFT` không khuyến nghị; báo cáo `PUBLISHED`.

**Các bước.**

1. DS1 `:submit` báo cáo không khuyến nghị
2. DS1 `:approve` báo cáo do mình gửi
3. `PATCH` báo cáo `PUBLISHED`
4. DA1 `:withdraw` lý do 10 ký tự
5. DA1 `:withdraw` lý do 30 ký tự, lập báo cáo thay thế
6. DA1 `POST /reports/{code}:reject` báo cáo `IN_REVIEW` kèm lý do 30 ký tự

**Kết quả mong đợi.** Bước 1 `422` ERR-08-039. Bước 2 `403` ERR-08-005. Bước 3 `409` ERR-08-040. Bước 4 `422` ERR-08-007. Bước 5 `WITHDRAWN`, EVT-08-11 `WITHDRAWN`, báo cáo gốc không bị sửa. Bước 6 báo cáo về `DRAFT` kèm lý do.

**Thông báo hiển thị.** ERR-08-039: "Báo cáo cần ít nhất một khuyến nghị trước khi gửi duyệt."; ERR-08-005: "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."; ERR-08-040: "Báo cáo BC-DQ-2026-11-T90 đã công bố và không sửa được. Thu hồi và lập báo cáo thay thế."; ERR-08-007: "Nhập lý do (tối thiểu 20 ký tự)."

:::

#### TC-08-118 · Báo cáo chính thức năm khi đủ điều kiện <!--k:rep-annual-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-054 · API-08-115, 107, 111, 112 · UI-08-18 · BR-08-010 · EVT-08-11 · EVT-08-14.

**Tiền điều kiện, dữ liệu.** T96 có mọi đối tượng với lần đo `FULL` `SUCCEEDED` trong 2026, ảnh chụp không `INCOMPLETE_DIMENSIONS`; DS1, DA1.

**Các bước.**

1. `POST /reports:check-annual-readiness` `{year: 2026}`
2. `POST /reports` `{type: ANNUAL, year: 2026}`
3. thêm khuyến nghị, `:submit`, DA1 `:approve`

**Kết quả mong đợi.** Bước 1 `readiness.ready = true`, ba danh sách trống. Bước 2 `201`, `BC-DQ-2026-NAM-T96`, ảnh chụp theo `FULL_DECEMBER`; đối tượng `FLOW_MESSAGE` không đo theo lô nên được loại khỏi điều kiện và báo cáo trình bày bằng thống kê trực tuyến cả năm. Bước 3 `PUBLISHED`; EVT-08-11 và EVT-08-14.

:::

#### TC-08-119 · Báo cáo năm bị chặn khi thiếu FULL, thiếu chiều, chỉ có mẫu <!--k:rep-annual-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-054 · FR-08-024 · API-08-115, 107, 059 · BR-08-010 · ERR-08-038 · ERR-08-030.

**Tiền điều kiện, dữ liệu.** T90: A chỉ có lần đo `SAMPLE`; B có ảnh chụp `INCOMPLETE_DIMENSIONS`; C không có lần `FULL` trong năm.

**Các bước.**

1. `POST /reports:check-annual-readiness`
2. `POST /reports` `{type: ANNUAL}`
3. `POST /scans` `{trigger: ANNUAL, mode: SAMPLE}`
4. `POST /scans` `{trigger: ANNUAL, mode: FULL}` cho A, B, C, kiểm lại

**Kết quả mong đợi.** Bước 1 `ready = false`, `missingFull = [C]`, `incomplete = [B]`, `sampleOnly = [A]`. Bước 2 `422` ERR-08-038. Bước 3 `422` ERR-08-030. Bước 4 sau khi đủ ba lần `FULL` sạch, `ready = true`.

**Thông báo hiển thị.** ERR-08-038: "Chưa đủ điều kiện báo cáo chính thức năm 2026: 3 đối tượng thiếu lần đo toàn bộ hoặc có điểm thiếu chiều."; ERR-08-030: "Kích thước mẫu phải từ 100 đến 1.000.000 bản ghi; lần đo cho báo cáo năm phải đo toàn bộ."

:::

### TS-08-26 · Xuất, ký số, phân phối báo cáo và đẩy chỉ số sang PH-16, PH-13

**Mục tiêu.** Xuất PDF, XLSX, JSON, ký số, đăng ký nhận qua PH-13 và đẩy KPI sang PH-16 không giao trùng.

**Phủ.** FR-08-055…057; UC-08-26.

#### TC-08-120 · Xuất báo cáo PDF, XLSX và đối chiếu contentHash <!--k:rep-export-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-055 · API-08-116, 117 · UI-08-18 · BR-08-009 · NFR-08-012.

**Tiền điều kiện, dữ liệu.** Báo cáo `PUBLISHED` 200 đối tượng; U-T90-DS1, U-T90-VW.

**Các bước.**

1. DS1 `POST /reports/{code}/exports` `{format: PDF}`
2. `GET /reports/{code}/exports/{id}` đến `READY`
3. `format = XLSX`
4. `format = JSON`, băm nội dung

**Kết quả mong đợi.** `202` rồi `fileUrl`; PDF và XLSX mở được, số liệu trùng báo cáo; băm JSON bằng `contentHash`. VW tải được bản đã xuất của báo cáo `PUBLISHED`.

:::

#### TC-08-121 · Ký số báo cáo và ký thất bại <!--k:rep-sign-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-055 · API-08-118 · UI-08-18 · ERR-00-403 · ERR-08-048.

**Tiền điều kiện, dữ liệu.** Báo cáo `PUBLISHED`; `sign-sim`; DA1, DS1.

**Các bước.**

1. DA1 `POST /reports/{code}:sign`
2. `sign-sim` ngừng, DA1 `:sign` lại
3. DS1 `:sign`

**Kết quả mong đợi.** Bước 1 `200`, `signatureRef`, nội dung báo cáo không đổi. Bước 2 `422` ERR-08-048. Bước 3 `403` ERR-00-403.

**Thông báo hiển thị.** ERR-08-048: "Không ký số được báo cáo BC-DQ-2026-11-T90: dịch vụ ký không phản hồi."

:::

#### TC-08-122 · Đăng ký nhận báo cáo và phân phối qua PH-13 <!--k:rep-subscribe-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-08-056 · API-08-119, 120, 121 · UI-08-18 · EVT-08-11 · ERR-08-114 · ERR-08-032.

**Tiền điều kiện, dữ liệu.** Báo cáo sắp công bố; DO1 (ORG-CA); `notif-sim`.

**Các bước.**

1. DO1 `POST /report-subscriptions` `{scope: ORGANIZATION, orgId: ORG-CA, channel: IN_APP}`
2. DO1 đăng ký `orgId: ORG-TC`
3. công bố báo cáo
4. tắt `notif-sim`, công bố báo cáo khác
5. DO1 `DELETE /report-subscriptions/{id}`

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `403` ERR-08-032. Bước 3 `distribution[]` ghi đã gửi. Bước 4 biên bản "chưa gửi" ERR-08-114, thử lại. Bước 5 hủy được.

**Thông báo hiển thị.** ERR-08-032: "Đối tượng mdm-org không thuộc tổ chức của anh/chị."; ERR-08-114: "Cảnh báo hoặc thông báo BC-DQ-2026-11-T90 chưa gửi được tới kênh thông báo."

:::

#### TC-08-123 · Đẩy KPI sang PH-16, không giao trùng <!--k:kpi-push-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-057 · API-08-122 · BR-08-009 · EVT-08-14 · ERR-08-113.

**Tiền điều kiện, dữ liệu.** `kpi-sim` (PH-16); `S-T90-PH16` scope `dq.read`.

**Các bước.**

1. Chạy lần đo `FULL` thành công
2. `GET /kpi/snapshots`
3. dừng `kpi-sim` 25 giờ rồi bật lại
4. chạy lần đo `INCREMENTAL`

**Kết quả mong đợi.** Bước 1 EVT: `kpi.published` (EVT-08-14) kèm `kpiSchemaVersion`. Bước 2 liệt kê KPI. Bước 3 quá 24 giờ có ERR-08-113 cảnh báo vận hành; sau khi bật lại giao đủ, mỗi `eventId` đúng một lần. Bước 4 không phát KPI.

**Thông báo hiển thị.** ERR-08-113: "Chưa đẩy được 3 bản tin KPI chất lượng dữ liệu sang PH-16."

:::

### TS-08-27 · Tham số tenant, lưu giữ dữ liệu đo và nhật ký kiểm toán

**Mục tiêu.** Tham số trong miền và trần, lưu giữ không dưới sàn, dọn đúng hạn, nhật ký kiểm toán bất biến, từ chối thao tác khi không ghi được kiểm toán.

**Phủ.** FR-08-058…060; UC-08-27.

#### TC-08-124 · Xem và sửa tham số tenant <!--k:set-update-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-058 · API-08-123, 124 · UI-08-19 · PERM-08-config.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA; U-T90-DS1.

**Các bước.**

1. TA `GET /settings`
2. TA `PUT /settings` `{08.scan.manual-per-hour: 20}` với `If-Match` đúng
3. `GET /settings`

**Kết quả mong đợi.** Bước 1 liệt kê 43 khóa với `default`, `max`, `updatedBy`. Bước 3 giá trị 20, `updatedBy = TA`. KT: có (setting.update) ghi giá trị trước và sau.

:::

#### TC-08-125 · Ngoài miền, vượt trần, xung đột, thiếu quyền <!--k:set-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-058 · API-08-124 · ERR-00-403 · ERR-00-428 · ERR-08-042, 004.

**Tiền điều kiện, dữ liệu.** `08.scan.min-interval-hours` miền ≥ 6; PA đặt trần `08.scan.manual-per-hour = 30`.

**Các bước.**

1. TA `PUT` `08.scan.min-interval-hours = 2`
2. TA `PUT` `08.scan.manual-per-hour = 50`
3. TA `PUT` với `If-Match` cũ
4. TA `PUT` không `If-Match`
5. DS1 `PUT`

**Kết quả mong đợi.** Bước 1 và 2 `422` ERR-08-042. Bước 3 `409` ERR-08-004. Bước 4 `428` ERR-00-428. Bước 5 `403` ERR-00-403.

**Thông báo hiển thị.** ERR-08-042: "Giá trị 2 của 08.scan.min-interval-hours ngoài khoảng cho phép ≥ 6."; ERR-08-004: "Tham số đã được người khác sửa. Tải lại để xem thay đổi."

:::

#### TC-08-126 · Xem trước và chạy dọn dữ liệu theo lưu giữ <!--k:ret-run-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-059 · API-08-125, 126 · UI-08-19 · BR-08-028.

**Tiền điều kiện, dữ liệu.** T90 có lỗi 400 ngày tuổi, kết quả quy tắc 25 tháng, ảnh chụp 6 năm, báo cáo công bố 11 năm (dữ liệu dựng bằng `clock-sim`).

**Các bước.**

1. `POST /retention-runs:preview`
2. chạy job dọn 03:00
3. `GET /retention-runs`

**Kết quả mong đợi.** Bước 1 `estimates{}` theo loại, chưa xóa. Bước 2 xóa lỗi quá 13 tháng (395 ngày) và kết quả quy tắc quá 24 tháng; không xóa ảnh chụp trong 5 năm và báo cáo công bố trong 10 năm. Bước 3 ghi số dòng đã xóa.

:::

#### TC-08-127 · Lưu giữ dưới sàn và dọn lỗi <!--k:ret-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-059 · API-08-124, 125 · BR-08-028 · ERR-08-117 · ERR-08-043.

**Tiền điều kiện, dữ liệu.** Sàn lưu lỗi 13 tháng; job dọn gặp lỗi CSDL giả lập.

**Các bước.**

1. TA `PUT /settings` `08.finding.retention-months = 12`
2. chạy job dọn với lỗi giả lập

**Kết quả mong đợi.** Bước 1 `422` ERR-08-043. Bước 2 job ghi ERR-08-117 ở UI-08-19 và PH-13, dữ liệu chưa xóa còn nguyên, thử lại ngày sau.

**Thông báo hiển thị.** ERR-08-043: "Thời gian lưu bản ghi lỗi không được dưới 13 tháng."; ERR-08-117: "Lần dọn dữ liệu 2026-11-27 chưa hoàn tất: CSDL từ chối."

:::

#### TC-08-128 · Đọc nhật ký kiểm toán và tính bất biến <!--k:aud-read-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-060 · API-08-127 · UI-08-04, 19 · PERM-08-audit-read · ERR-00-403.

**Tiền điều kiện, dữ liệu.** Sau các ca duyệt, xuất, đổi tham số; U-T90-SO, U-T90-AU, U-T90-DS1.

**Các bước.**

1. SO `GET /audit-events?assetCode=mdm-citizen&action=ruleset.activate`
2. AU `GET /audit-events` xuất nhật ký
3. DS1 `GET /audit-events`
4. thử `UPDATE` và `DELETE` bản ghi kiểm toán bằng `dh_data_app`

**Kết quả mong đợi.** Bước 1 mỗi bản ghi có người thao tác, `tenantId`, hành động, đối tượng, giá trị trước và sau, `traceId`, thời điểm; không chứa giá trị thuộc tính Nhạy cảm. Bước 2 có kiểm toán lượt xuất. Bước 3 `403` ERR-00-403. Bước 4 bị chặn (bất biến).

:::

#### TC-08-129 · Không ghi được kiểm toán thì từ chối thao tác <!--k:aud-fail-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-060 · API-08-039 · ERR-08-054 · BR-08-007.

**Tiền điều kiện, dữ liệu.** Kênh kiểm toán PH-13 giả lập ngừng; bộ quy tắc chờ duyệt.

**Các bước.**

1. DA1 `POST …:approve` khi kênh kiểm toán ngừng
2. bật lại, `POST …:approve`

**Kết quả mong đợi.** Bước 1 `503` ERR-08-054, phiên bản vẫn `PENDING_APPROVAL`, không phát EVT-08-01. Bước 2 `200`.

**Thông báo hiển thị.** ERR-08-054: "Hệ thống tạm thời không ghi được nhật ký. Thao tác chưa được thực hiện."

:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Tám kịch bản dưới đây không ứng với một use case mà cắt ngang mọi chức năng: cô lập tenant, phân quyền, che giá trị Nhạy cảm, kiểm toán, hiệu năng, chịu lỗi và vòng đầy đủ. Các ca cô lập, che giá trị và phân quyền là điều kiện chặn phát hành.

### TS-08-28 · Cô lập tenant: API, RLS, Kafka, bộ đệm trực tuyến

**Mục tiêu.** T91 không đọc, ghi, suy ra dữ liệu của T90 ở API, CSDL, Kafka và bộ đệm quy tắc.

**Phủ.** NFR-08-016, 017; BR-08-026, 030; mọi API đọc; schema `ph08_dq`; topic `{tenant}.dq.*`.

#### TC-08-130 · Rò rỉ chéo tenant ở mọi API đọc và ghi <!--k:iso-api-->

::: dac-ta
**Loại.** Bảo mật, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-006 · FR-08-037 · FR-08-051 · API-08-007, 021, 027, 061, 074, 079, 086, 109 · ERR-08-001 · NFR-08-017.

**Tiền điều kiện, dữ liệu.** T90 có đối tượng, bộ quy tắc, lần đo, lỗi, phiếu, báo cáo, ngoại lệ, tệp xuất; U-T91-DS1, U-T91-DA1.

**Các bước.**

1. T91 `GET`/`POST` lên id của T90 ở các API: `/assets`, `/profile-runs`, `/rule-sets`, `/scans`, `/findings`, `/waivers`, `/issues`, `/reports`, `/exports`
2. T91 gọi các thao tác ghi `:approve`, `:cancel`, `:activate` lên id T90
3. giả mạo tiêu đề `X-Tenant-Id: T90`
4. so thân phản hồi với id không tồn tại

**Kết quả mong đợi.** Mọi lệnh `404` ERR-08-001, thân giống hệt trường hợp "không tồn tại" trừ `traceId` (404-ẩn); dữ liệu T90 không đổi; tenant lấy từ token, tiêu đề giả mạo bị bỏ qua; danh sách của T91 không có dòng nào của T90.

:::

#### TC-08-131 · RLS theo tenant_id ở schema ph08_dq <!--k:iso-rls-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** FR-08-060 · BR-08-026 · NFR-08-016.

**Tiền điều kiện, dữ liệu.** Tệp `03-thiet-ke/csdl/ph08/test/ph08_isolation_test.sql` trên CSDL rỗng đã chạy `ph08_dq.sql`; vai trò `dh_data_app` (không `BYPASSRLS`).

**Các bước.**

1. `psql -v ON_ERROR_STOP=1 -f ph08_isolation_test.sql`
2. thêm: `SET app.tenant_id = 'T90'` rồi `SELECT` các bảng
3. không đặt `app.tenant_id`
4. `INSERT` dòng `tenant_id = 'T91'` khi đang là T90
5. T90 đọc và sửa `dq_rule_template` của `COMMON`

**Kết quả mong đợi.** Tệp chạy hết, mọi dòng `PASS`. Với T90 chỉ thấy dòng T90; không đặt `app.tenant_id` thì 0 dòng; chèn sai tenant bị `42501`; `COMMON` đọc được nhưng sửa bị `42501`.

:::

#### TC-08-132 · ACL Kafka theo tiền tố tenant và nội dung sự kiện <!--k:iso-kafka-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** FR-08-057 · EVT-08-02 · EVT-08-06 · EVT-08-14 · NFR-08-017.

**Tiền điều kiện, dữ liệu.** Client T91 OAUTHBEARER; sự kiện EVT-08-02, 06, 14 của T90.

**Các bước.**

1. T91 `subscribe` `t90.dq.scan.completed.v1`
2. T91 `produce` vào `t90.dq.check.failed.v1`
3. đọc nội dung bản tin T90 bằng client hợp lệ

**Kết quả mong đợi.** Hai bước đầu bị từ chối ACL. Bản tin T90 chỉ có mã đối tượng, số đếm, điểm; không có khóa bản ghi cá nhân và giá trị dữ liệu.

:::

#### TC-08-133 · Bộ đệm quy tắc trực tuyến cô lập theo tenant <!--k:iso-cache-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-032 · API-08-068 · NFR-08-005 · BR-08-026.

**Tiền điều kiện, dữ liệu.** T90 và T91 cùng có `mdm-citizen` với bộ quy tắc khác nhau (T90 yêu cầu `nationalId`, T91 không).

**Các bước.**

1. T90 gọi `POST /checks:evaluate` bản ghi thiếu `nationalId` để nạp bộ đệm
2. T91 gọi cùng bản ghi
3. T91 kích hoạt bộ quy tắc mới
4. T90 gọi lại

**Kết quả mong đợi.** T90 `FAIL`, T91 `PASS`. Kích hoạt của T91 không làm làm mới bộ đệm T90; kết luận T90 không đổi.

:::

### TS-08-29 · Phân quyền theo ma trận PERM-08, bốn mắt và tài khoản máy

**Mục tiêu.** Ma trận 11 quyền theo vai trò, phạm vi tổ chức của DO, loại trừ người soạn với người duyệt, scope máy.

**Phủ.** FRS mục 3.2 và 3.3; BR-08-007, 026; NFR-08-017; ERR-00-401, 403.

#### TC-08-134 · Ma trận PERM-08 theo vai trò <!--k:perm-matrix-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-001 · FR-08-017 · FR-08-050 · FR-08-060 · ERR-00-401 · ERR-00-403 · PERM-08-read, asset, approve, run, finding-read, remediate, report, export, config, audit-read · ERR-08-032.

**Tiền điều kiện, dữ liệu.** Người dùng T90: PA (qua `PLATFORM`), TA, TO, SO, DS1, DA1, DO1, VW, AU; ma trận ở FRS mục 3.2.

**Các bước.**

1. Với mỗi quyền chọn một API đại diện (`GET /dashboard`, `POST /domains`, `POST …:approve`, `POST /scans`, `GET /findings`, `POST /issues/{code}:start`, `POST /reports`, `POST /findings:export`, `PUT /settings`, `GET /audit-events`)
2. gọi bằng từng vai trò
3. gọi không token
4. DO1 gọi API của đối tượng ngoài ORG-CA

**Kết quả mong đợi.** Vai trò có ● trả `2xx`; không có quyền `403` ERR-00-403; không token `401` ERR-00-401; DO ○ ngoài tổ chức `403` ERR-08-032; VW chỉ `GET /dashboard` tổng hợp. Kết quả khớp đúng từng ô của bảng ma trận.

**Thông báo hiển thị.** ERR-08-032: "Đối tượng mdm-org không thuộc tổ chức của anh/chị."

:::

#### TC-08-135 · Bốn mắt không có đường vòng <!--k:perm-sod-->

::: dac-ta
**Loại.** Bảo mật, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-017 · FR-08-021 · FR-08-040 · FR-08-053 · FR-08-039 · API-08-039, 051, 081, 112, 076 · BR-08-007 · PERM-08-approve · ERR-08-005.

**Tiền điều kiện, dữ liệu.** U-T90-TA có cả quyền soạn và duyệt (SIT); mỗi loại đối tượng (bộ quy tắc, trọng số, ngoại lệ, báo cáo, xuất lỗi) do chính người đó soạn hoặc gửi.

**Các bước.**

1. TA gọi duyệt cho cả năm loại
2. DS1 (soạn) gọi duyệt
3. thử đổi người gửi bằng cách sửa nội dung rồi gửi lại và tự duyệt
4. DA2 (người khác) duyệt cả năm loại

**Kết quả mong đợi.** Bước 1, 2, 3 `403` ERR-08-005, trạng thái không đổi. Bước 4 `200`. Mọi lượt từ chối có KT: có (approve.denied).

**Thông báo hiển thị.** ERR-08-005: "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."

:::

#### TC-08-136 · Scope máy dq.check, dq.read và API nội bộ <!--k:perm-machine-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-032 · FR-08-051 · FR-08-011 · API-08-068, 106, 122, 024 · NFR-08-017 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** `S-T90-PH04` (`dq.check`); `S-T90-PH16` (`dq.read`); `S-T90-HTTT-HT` (`dq.read`).

**Các bước.**

1. `S-T90-PH04` gọi `POST /scans` và `GET /assets`
2. `S-T90-PH16` gọi `POST /checks:evaluate`
3. `S-T90-PH16` gọi `GET /kpi/snapshots`
4. gọi `POST /internal/profile-metrics` từ ngoài mạng nội bộ qua APISIX

**Kết quả mong đợi.** Bước 1 và 2 `403` ERR-00-403. Bước 3 `200`. Bước 4 bị từ chối vì đường dẫn `/internal` chỉ mở trong mạng nội bộ (mTLS).

:::

### TS-08-30 · Bản ghi lỗi: dấu vân tay, che giá trị và không lộ dữ liệu Nhạy cảm

**Mục tiêu.** Dấu vân tay nối tiếp lỗi qua kỳ và phiên bản quy tắc; không giá trị Nhạy cảm dạng rõ ở CSDL, log, sự kiện, tệp xuất.

**Phủ.** FR-08-036, 005, 038; BR-08-012, 013, 034; NFR-08-016.

#### TC-08-137 · Dấu vân tay ổn định qua kỳ và phiên bản quy tắc <!--k:fnd-fp-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-036 · API-08-073, 074 · BR-08-013.

**Tiền điều kiện, dữ liệu.** `mdm-citizen` có lỗi `R-CCCD-NN` cho khóa `001099000001` (và biến thể có khoảng trắng đầu cuối); `RS-CITIZEN` v5 rồi v6 giữ `ruleCode`; v7 đổi `ruleCode`.

**Các bước.**

1. Đo với v5
2. đo với v6 trên cùng dữ liệu
3. đo với v7 (quy tắc đổi `ruleCode`)
4. `GET /findings/{id}`

**Kết quả mong đợi.** Khóa ` 001099000001 ` và `001099000001` cho cùng dấu vân tay `SHA-256(T90, mdm-citizen, R-CCCD-NN, 001099000001)`. v5 → v6: cùng lỗi, `occurrences = 2`, `firstSeenScanId` giữ. v7: dấu vân tay mới, lỗi cũ `RESOLVED` lý do `RULE_RETIRED`, cảnh báo ở bản so sánh.

:::

#### TC-08-138 · Vòng đời lỗi mới, còn, hết, mở lại và phạm vi lấy mẫu <!--k:fnd-life-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-036 · FR-08-029 · API-08-065, 073 · BR-08-034 · EVT-08-06.

**Tiền điều kiện, dữ liệu.** Kỳ 1 có 100 lỗi; kỳ 2 còn 60, hết 40, mới 15; một lỗi đã `RESOLVED` tái xuất; một bản ghi bị xóa ở nguồn; một lỗi `WAIVED`.

**Các bước.**

1. Đo `FULL` kỳ 1
2. đo `FULL` kỳ 2
3. đo `SAMPLE` kỳ 3 (mẫu không chứa 20 lỗi cũ)
4. `GET /scans/{id}/score`

**Kết quả mong đợi.** Kỳ 2: `findingsNew = 15`, `findingsPersisting = 60`, `findingsResolved = 40` (`CLEARED`); lỗi tái xuất về `OPEN`, `reopenCount + 1`; bản ghi xóa `RESOLVED` lý do `RECORD_REMOVED`; lỗi `WAIVED` còn thấy vẫn `WAIVED`. Kỳ 3 chỉ giải quyết lỗi nằm trong mẫu, 20 lỗi ngoài mẫu giữ nguyên. EVT-08-06 một lần mỗi lần đo.

:::

#### TC-08-139 · Che giá trị theo phân loại và leak scan <!--k:fnd-mask-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** FR-08-036 · FR-08-005 · API-08-073 · BR-08-012 · NFR-08-016.

**Tiền điều kiện, dữ liệu.** `nationalId` `SENSITIVE` (`HASH`), `fullName` và `phone` `RESTRICTED` (`PARTIAL`), `note` `PUBLIC` (`NONE`); canary `DH-CANARY-leak` đặt ở `nationalId`; CCCD giả dải `0010990xxxxx`.

**Các bước.**

1. Chạy hồ sơ, chạy thử, đo lô, mở phiếu, xuất lỗi, sinh báo cáo
2. đọc `maskedValue` mỗi trường
3. quét `ph08_dq`, log 5 phút, vết OTel, outbox, Kafka, tệp xuất, báo cáo tìm canary và mẫu CCCD, MST, SĐT dạng rõ

**Kết quả mong đợi.** `nationalId` lưu HMAC-SHA-256 khóa tenant (64 ký tự hex); `phone` dạng `09******78`; `note` tối đa 255 ký tự; khóa bản ghi là CCCD lưu `recordKeyHash`, hiển thị bản che; quét 0 kết quả (Mồi sạch).

:::

#### TC-08-140 · Cố hạ che, cố đọc giá trị gốc, phân loại chưa xác nhận <!--k:fnd-mask-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-036 · FR-08-005 · FR-08-038 · API-08-014, 015, 074 · BR-08-012 · ERR-08-047.

**Tiền điều kiện, dữ liệu.** Lỗi cũ của `fullName` che `PARTIAL`; PH-09 nâng `fullName` lên `SENSITIVE`; CDE `email` chưa xác nhận.

**Các bước.**

1. `POST /assets/mdm-citizen/fields:sync-classification`
2. đọc lại các lỗi cũ của `fullName`
3. tìm API trả giá trị gốc (mọi `GET` ở `/findings`, `/profile-runs`, `/scans`)
4. kích hoạt đối tượng có CDE `email` `PROPOSED`

**Kết quả mong đợi.** Job nền che lại lỗi cũ thành `HASH`. Không API nào trả giá trị gốc; người có `PERM-09-unmask` đọc lại nguồn qua PH-09 (Q08-07). Trường chưa xác nhận che như `SENSITIVE` kèm cảnh báo ERR-08-047.

**Thông báo hiển thị.** ERR-08-047: "Trường email chưa có phân loại xác nhận ở PH-09. Giá trị sẽ được che như dữ liệu Nhạy cảm."

:::

### TS-08-31 · Kiểm toán và truy vết xuyên suốt

**Mục tiêu.** Mọi hành động thay đổi có kiểm toán đủ trường; `traceId` nối lần đo với lời gọi PH-05, PH-06, PH-07.

**Phủ.** FR-08-060; NFR-08-015, 020; BR-08-009.

#### TC-08-141 · Mọi hành động thay đổi đều có kiểm toán <!--k:aud-actions-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-08-060 · FR-08-001 · FR-08-018 · FR-08-021 · FR-08-040 · FR-08-044 · FR-08-053 · FR-08-058 · API-08-127 · UI-08-04.

**Tiền điều kiện, dữ liệu.** T90; chuỗi hành động từ các ca TS-08-01…27.

**Các bước.**

1. Thực hiện: tạo miền, kích hoạt bộ quy tắc, duyệt trọng số, duyệt ngoại lệ, xác nhận phiếu, xuất lỗi, công bố báo cáo, đổi tham số
2. `GET /audit-events` theo từng hành động
3. mở tab "Lịch sử" của `mdm-citizen` ở UI-08-04

**Kết quả mong đợi.** Mỗi hành động có một bản ghi với người thao tác, tenant, hành động, đối tượng, giá trị trước và sau, `traceId`, thời điểm; không có giá trị thuộc tính Nhạy cảm; tab "Lịch sử" hiển thị cùng bản ghi.

:::

#### TC-08-142 · traceId xuyên lần đo, tác vụ và lời gọi phụ thuộc <!--k:aud-trace-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-08-060 · NFR-08-020 · NFR-08-015 · API-08-061.

**Tiền điều kiện, dữ liệu.** Lần đo `FULL` của `mdm-citizen` có lời gọi tới `mdm-sim`, `rdm-sim`, `conn-sim`; Tempo, Prometheus.

**Các bước.**

1. Chạy lần đo, lấy `traceId`
2. tìm trong Tempo
3. đọc `/metrics`

**Kết quả mong đợi.** Một cây vết gồm lần đo, các tác vụ, lời gọi PH-05, PH-06, PH-07 cùng `traceId`. Có đủ chỉ số `dq_scan_jobs_total`, `dq_scan_duration_seconds`, `dq_score_gauge`, `dq_findings_total`, `dq_check_total`, `dq_check_duration_seconds`, `dq_issues_overdue`, `dq_outbox_lag_seconds`.

:::

### TS-08-32 · Hiệu năng kiểm tra trực tuyến

**Mục tiêu.** Độ trễ, thông lượng, bộ đệm và tra PH-07 của kiểm tra trực tuyến ở hồ sơ tỉnh vừa trên PERF.

**Phủ.** NFR-08-001, 002, 005, 006; BR-08-018; FR-08-032.

#### TC-08-143 · p95 kiểm tra trực tuyến ≤ 50 ms <!--k:perf-inline-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-08-001 · FR-08-032 · API-08-068.

**Tiền điều kiện, dữ liệu.** T97; `dh-data` 2 bản sao 4 vCPU, 8 GB; bộ quy tắc 50 quy tắc không `UNIQUE_*`; bộ đệm đã nóng; bản ghi trung bình 2 KB.

**Các bước.**

1. k6 500 lượt mỗi giây gọi `POST /checks:evaluate` trong 15 phút, bỏ 5 phút khởi động; đo ở máy chủ

**Kết quả mong đợi.** p95 ≤ 50 ms, p99 ≤ 100 ms, 0 lỗi `5xx`.

:::

#### TC-08-144 · Thông lượng ≥ 2.000 bản ghi mỗi giây <!--k:perf-tput-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-08-002 · FR-08-032 · API-08-068, 069.

**Tiền điều kiện, dữ liệu.** Như perf-inline; dùng `evaluate-batch` 20 bản ghi mỗi lần.

**Các bước.**

1. k6 tăng dần đến tải đều 2.000 bản ghi mỗi giây trong 15 phút

**Kết quả mong đợi.** Duy trì ≥ 2.000 bản ghi mỗi giây, tỷ lệ lỗi < 0,1 %.

:::

#### TC-08-145 · Bộ đệm quy tắc và tra PH-07 <!--k:perf-cache-->

::: dac-ta
**Loại.** Hiệu năng, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-08-005 · NFR-08-006 · FR-08-027 · EVT-08-01.

**Tiền điều kiện, dữ liệu.** `dq_inline_rule_cache_hit_ratio`; `rdm-sim` có độ trễ 40 ms mỗi lô 500 mã.

**Các bước.**

1. Chạy tải perf-inline và đọc tỷ lệ trúng
2. kích hoạt phiên bản mới, đo thời gian đến lúc `ruleSetVersion` mới xuất hiện
3. tra PH-07 lô 500 mã
4. ép `rdm-sim` lỗi 5 lần liên tiếp rồi chờ 30 giây

**Kết quả mong đợi.** Tỷ lệ trúng ≥ 95 %; phiên bản mới có hiệu lực ≤ 30 giây sau EVT-08-01; tra lô 500 mã p95 ≤ 100 ms; ngắt mạch sau 5 lỗi liên tiếp và thử lại sau 30 giây.

:::

### TS-08-33 · Hiệu năng đo lô, hồ sơ, bảng điều khiển và báo cáo

**Mục tiêu.** Thời gian đo lô, đo mẫu, hồ sơ, tra cứu lỗi, bảng điều khiển, báo cáo và mở rộng theo số bộ thực thi.

**Phủ.** NFR-08-003, 004, 010…014, 019; FR-08-008, 026, 044, 050, 052.

#### TC-08-146 · Đo FULL 1 triệu bản ghi, SAMPLE, hồ sơ <!--k:perf-scan-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-08-003 · NFR-08-004 · NFR-08-013 · NFR-08-014 · FR-08-026 · FR-08-008 · FR-08-044.

**Tiền điều kiện, dữ liệu.** T99; nguồn PostgreSQL bản sao chỉ đọc 1 triệu dòng, 30 quy tắc; bốn bộ thực thi.

**Các bước.**

1. Đo `FULL`
2. đo `SAMPLE` 10.000 bản ghi
3. hồ sơ 1 triệu dòng 50 cột
4. đo kiểm chứng 10.000 khóa

**Kết quả mong đợi.** `FULL` ≤ 60 phút. `SAMPLE` ≤ 3 phút. Hồ sơ ≤ 15 phút, sai số HLL ≤ 2 %. Đo kiểm chứng ≤ 5 phút từ lúc báo đã sửa (không gồm chờ PH-06).

:::

#### TC-08-147 · Mở rộng gần tuyến tính theo số bộ thực thi <!--k:perf-scale-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-08-019 · NFR-08-003.

**Tiền điều kiện, dữ liệu.** T99 như perf-scan.

**Các bước.**

1. Đo `FULL` với 1, 2, 4, 8 bộ thực thi, ghi thông lượng

**Kết quả mong đợi.** Thông lượng với n bộ ≥ 0,8 × n × thông lượng 1 bộ, tới n = 8.

:::

#### TC-08-148 · Bảng điều khiển, tra cứu lỗi và báo cáo <!--k:perf-ui-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-08-010 · NFR-08-011 · NFR-08-012 · FR-08-050 · FR-08-037 · FR-08-052 · FR-08-055 · API-08-104, 073.

**Tiền điều kiện, dữ liệu.** T98: 200 đối tượng, 13 tháng ảnh chụp, 10 triệu dòng lỗi phân vùng tháng.

**Các bước.**

1. k6 `GET /dashboard` 50 người dùng đồng thời
2. `GET /findings` lọc theo đối tượng và trạng thái
3. sinh báo cáo kỳ cho 200 đối tượng
4. xuất PDF 100 trang

**Kết quả mong đợi.** Dashboard p95 ≤ 2 giây. Tra cứu lỗi p95 ≤ 1,5 giây. Báo cáo kỳ ≤ 5 phút. PDF 100 trang ≤ 2 phút.

:::

### TS-08-34 · Tái lập, chịu lỗi và giao sự kiện

**Mục tiêu.** Cùng dữ liệu cho cùng điểm; chịu mất pod hoặc Kafka mà không đo trùng, không mất sự kiện, lịch không chạy hai lần.

**Phủ.** NFR-08-007, 008, 009, 018; FR-08-023, 026, 028; EVT-08-02, 14.

#### TC-08-149 · Tái lập điểm và mẫu <!--k:rep-det-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-08-007 · NFR-08-008 · FR-08-028 · BR-08-019.

**Tiền điều kiện, dữ liệu.** Dữ liệu đóng băng F-SCORE; cùng phiên bản quy tắc và cấu hình trọng số.

**Các bước.**

1. Đo `FULL` hai lần liên tiếp
2. đo `SAMPLE` seed 7 hai lần
3. so điểm và tập `recordKey`

**Kết quả mong đợi.** Điểm chênh ≤ 0,01; tập `recordKey` mẫu giống hệt.

:::

#### TC-08-150 · Mất pod, mất Kafka, lịch không chạy trùng <!--k:fail-chaos-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-08-009 · NFR-08-018 · NFR-08-015 · FR-08-023 · FR-08-026 · EVT-08-02.

**Tiền điều kiện, dữ liệu.** T95; `dh-data` 2 bản sao; lần đo 200.000 bản ghi đang `RUNNING`.

**Các bước.**

1. Xóa pod đang chạy tác vụ
2. dừng Kafka 10 phút rồi bật lại
3. để hai bản sao cùng chạm giờ lịch 02:00
4. đo `dq_outbox_lag_seconds`

**Kết quả mong đợi.** Tác vụ tiếp tục từ chỗ dừng, không đo hai lần cùng khóa; sự kiện không mất, giao ít nhất một lần, consumer xử lý idempotent, trễ p95 ≤ 5 giây khi Kafka bình thường; lịch chỉ bắn một lần (ShedLock); API sẵn sàng ≥ 99,5 % trong tháng thử.

:::

### TS-08-35 · Vòng đầy đủ và truy cập giao diện

**Mục tiêu.** Diễn tập vòng khép kín từ lịch đo đến báo cáo công bố và kiểm tra truy cập giao diện.

**Phủ.** FR-08-023, 026, 028, 036, 041, 044, 052, 053; UI-08-01, 12, 13, 16; tiêu chí chấp nhận FRS mục 14.

#### TC-08-151 · Vòng đầy đủ lịch tháng đến báo cáo kỳ <!--k:e2e-cycle-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-08-023 · FR-08-026 · FR-08-028 · FR-08-036 · FR-08-041 · FR-08-044 · FR-08-052 · FR-08-053 · UI-08-01, 11, 12, 13, 16, 18 · EVT-08-02 · EVT-08-09 · EVT-08-11.

**Tiền điều kiện, dữ liệu.** T90 `mdm-citizen` với F-SCORE; lịch tháng; DS1, DA1, DO1; `clock-sim`.

**Các bước.**

1. Đẩy `clock-sim` tới 2026-12-01 02:00, lịch tự bắn lần đo `FULL`
2. xem lần đo ở UI-08-12 và lỗi ở UI-08-13
3. DS1 mở phiếu cho `R-CCCD-NN` (UI-08-16)
4. DO1 sửa nguồn và báo đã sửa
5. chờ đo kiểm chứng `VERIFIED`
6. DS1 sinh báo cáo kỳ, DA1 duyệt, công bố
7. xem điểm mới ở UI-08-01

**Kết quả mong đợi.** Mỗi bước hoàn tất đúng trạng thái: lần đo `SUCCEEDED` điểm 91,45, lỗi mới `OPEN`, phiếu `VERIFIED`, lỗi `RESOLVED`, báo cáo `PUBLISHED`, dashboard cập nhật; đủ EVT-08-02, 06, 07, 09, 11 và kiểm toán từng bước.

:::

#### TC-08-152 · Truy cập và giao diện các màn trọng yếu <!--k:a11y-ui-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-08-01 · UI-08-12 · UI-08-13 · UI-08-18 · FR-08-050.

**Tiền điều kiện, dữ liệu.** STAGING; Playwright, axe-core.

**Các bước.**

1. Chạy axe-core trên UI-08-01, 12, 13, 18 ở độ rộng 1280 và 360 px
2. điều hướng chỉ bằng bàn phím
3. đọc thẻ điểm bằng trình đọc màn hình

**Kết quả mong đợi.** 0 lỗi mức nghiêm trọng; kết luận `PASS`, `WARN`, `FAIL` không chỉ phân biệt bằng màu; thứ tự tab hợp lý; không cuộn ngang ở 360 px.

:::

## 6. Thủ tục kiểm thử thủ công

Một số kiểm tra cần phán đoán của con người và không đưa vào tự động hóa; ba thủ tục dưới đây chạy ở STAGING trước mỗi đợt phát hành.

### 6.1. Kiểm thử khám phá theo phiên

Hai phiên 90 phút cho mỗi điều lệ: (1) "làm điểm cao giả" bằng quy tắc, ngoại lệ, mẫu đo, chiều bị bỏ qua mà dữ liệu không tốt hơn; (2) "lấy giá trị Nhạy cảm dạng rõ" từ giao diện, API, log, tệp xuất, báo cáo. Ghi lỗi theo mục 1.6.

### 6.2. Tính tay công thức điểm

Chuyên viên quản lý dữ liệu và kiểm thử viên cùng tính tay năm bộ số đếm khác nhau (gồm một bộ có chiều bị bỏ qua và một bộ có ngoại lệ) trên bảng tính độc lập rồi so với điểm hệ thống; chênh lệch tối đa 0,01 (NFR-08-007). Kết quả ghi vào hồ sơ nghiệm thu của TS-08-12.

### 6.3. Diễn tập sự cố

Diễn tập: PH-07 gián đoạn giữa lần đo, kiểm tra trực tuyến khi PH-07 chậm với `FAIL_OPEN` và `FAIL_CLOSED`, PH-13 không nhận cảnh báo; vận hành làm theo sổ tay, đo thời gian phát hiện và xử lý.

## 7. Nghiệm thu người dùng

Hệ cũ không có chức năng chất lượng dữ liệu nên không có nghiệm thu "tương đương hệ cũ". Cán bộ quản lý dữ liệu của tỉnh thí điểm (T01) tự thực hiện trên UAT; đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng. Sáu `LGC` liên quan gián tiếp (DMDC-006, 007, 008, BUS-027, NGSP-003, 005) chỉ được kiểm ở phần PH-08 bổ sung (mục 8.2).

| Mã | Việc cần làm | Liên quan hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem tổng quan chất lượng của tỉnh và thẻ điểm một đối tượng | — | Điểm tỉnh, thẻ miền, xu hướng đúng; bấm vào ra danh sách đã lọc | FR-08-050, 051 | TS-08-24 |
| UAT-02 | Đăng ký đối tượng đo từ domain dữ liệu chủ và khai CDE | — | Đối tượng `DRAFT`, trường CDE che đúng theo phân loại | FR-08-002, 005 | TS-08-02 |
| UAT-03 | Soạn bộ quy tắc sáu chiều, chạy thử, gửi duyệt, DA duyệt | — | Bộ quy tắc `ACTIVE`, DA khác người soạn | FR-08-012, 013, 016, 017 | TS-08-05, 06, 07 |
| UAT-04 | Chạy đo theo yêu cầu, đọc điểm sáu chiều và so với kỳ trước | — | Điểm, kết luận, xu hướng, cờ thiếu chiều hiển thị đúng | FR-08-024, 028, 029 | TS-08-10, 12 |
| UAT-05 | Đo chất lượng mã ĐVHC sau khi nhập danh mục | LGC-DMDC-006 | Số mã không hợp lệ và gợi ý mã mới, không có bảng mã ở PH-08 | FR-08-027 | TS-08-11 |
| UAT-06 | Giao và xử lý phiếu khắc phục, đo kiểm chứng | — | Phiếu tới `VERIFIED`, chủ quản không tự xác nhận | FR-08-041…044 | TS-08-19, 20, 21 |
| UAT-07 | Lập và công bố báo cáo năm | — | Báo cáo năm bị chặn khi thiếu `FULL`, công bố sau khi đủ | FR-08-054 | TS-08-25 |
| UAT-08 | Kiểm tra trực tuyến một luồng và xem thống kê lỗi theo luồng | LGC-BUS-027 | Bản tin lỗi vào DLQ hoặc đi tiếp kèm tiêu đề, thống kê theo phút | FR-08-032, 033, 034 | TS-08-15, 16 |

: Kịch bản nghiệm thu UAT-01…08 theo vai trò

## 8. Ma trận truy vết

Ma trận dưới đây nối từng FR, quy tắc nghiệp vụ, mã lỗi, yêu cầu phi chức năng, sự kiện, API và màn hình với các test case phủ chúng; bảng được `fill_doc.py` sinh lại từ chính các ca nên không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-08. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph08/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | Dương | Âm | Đạt |
|---|---|---|---|---|---|
| FR-08-001 | Khai báo miền chất lượng, chủ quản, cán bộ p | M | 001, 141 | 002, 003, 004, 005 | Có |
| FR-08-002 | Đăng ký đối tượng đo từ domain PH-06 | M | 006 | 007, 014, 078 | Có |
| FR-08-003 | Đăng ký đối tượng đo từ danh mục PH-07 | M | 008 | 009 | Có |
| FR-08-004 | Đăng ký đối tượng đo nguồn qua kết nối PH-05 | S | 010 | 011 | Có |
| FR-08-005 | Khai báo phần tử dữ liệu trọng yếu, lấy phân | M | 012 | 013, 014, 140 | Có |
| FR-08-006 | Liệt kê, tìm, xem đối tượng đo | M | 015 | 016, 130 | Có |
| FR-08-007 | Ngừng, khôi phục đối tượng đo | M | 017 | 018 | Có |
| FR-08-008 | Chạy hồ sơ dữ liệu | S | 019 | 020, 021 | Có |
| FR-08-009 | Xem hồ sơ dữ liệu theo cột | S | 019 | 021 | Có |
| FR-08-010 | Gợi ý quy tắc từ hồ sơ | C | 022 | 022 | Có |
| FR-08-011 | Nhận chỉ số hồ sơ từ PH-05 | C | 023 | 023 | Có |
| FR-08-012 | Tạo bộ quy tắc phiên bản nháp | M | 024 | 025 | Có |
| FR-08-013 | Định nghĩa quy tắc theo chiều và toán tử | M | 026 | 027, 028, 032 | Có |
| FR-08-014 | Quy tắc biểu thức CEL và vị từ SQL có kiểm s | S | 030 | 031, 032 | Có |
| FR-08-015 | Thư viện quy tắc mẫu ở COMMON | S | 033 | 034 | Có |
| FR-08-016 | Chạy thử quy tắc trên mẫu | M | 035 | 036 | Có |
| FR-08-017 | Gửi duyệt, duyệt, từ chối bộ quy tắc | M | 037 | 038, 039, 135 | Có |
| FR-08-018 | Kích hoạt, thay thế, ngừng phiên bản bộ quy  | M | 037, 040, 141 | 041 | Có |
| FR-08-019 | So sánh phiên bản, xem lịch sử | S | 042 | 042 | Có |
| FR-08-020 | Sao chép, nhập, xuất bộ quy tắc YAML, JSON | S | 043 | 044 | Có |
| FR-08-021 | Cấu hình trọng số và ngưỡng có phiên bản, có | M | 045, 048, 141 | 046, 047, 135 | Có |
| FR-08-022 | Liệt kê, tìm quy tắc | M | 029 | 029 | Có |
| FR-08-023 | Lập lịch đo | M | 049, 151 | 050 | Có |
| FR-08-024 | Chạy đo theo yêu cầu | M | 051, 055 | 052, 119 | Có |
| FR-08-025 | Đo tăng dần theo sự kiện PH-06, PH-07 | S | 076, 077 | 078 | Có |
| FR-08-026 | Thực thi quy tắc theo lô | M | 056, 057, 151 | 060, 061 | Có |
| FR-08-027 | Đối chiếu danh mục PH-07 cho chiều hợp lệ | M | 059 | 060 | Có |
| FR-08-028 | Tính điểm có trọng số | M | 048, 062, 063, 065, 066, 149, 151 | 064 | Có |
| FR-08-029 | So kỳ trước, xu hướng | M | 068, 069, 138 | 070 | Có |
| FR-08-030 | Theo dõi tiến độ, hủy, chạy lại lần đo | M | 051, 053 | 054 | Có |
| FR-08-031 | Xử lý phụ thuộc không khả dụng | M | 063, 074 | 071 | Có |
| FR-08-032 | API kiểm tra trực tuyến bản ghi | S | 079, 080, 082 | 081, 085 | Có |
| FR-08-033 | Bước kiểm tra chất lượng trong luồng PH-04 | S | 080, 083 | 083 | Có |
| FR-08-034 | Thống kê kiểm tra trực tuyến | S | 086 | 086 | Có |
| FR-08-035 | Cổng chất lượng đầu vào cho PH-06 | C | 084 | 085 | Có |
| FR-08-036 | Ghi bản ghi lỗi, dấu vân tay, che giá trị | M | 137, 138, 151 | 061, 140 | Có |
| FR-08-037 | Tra cứu, lọc bản ghi lỗi | M | 087 | 088, 130 | Có |
| FR-08-038 | Xem chi tiết bản ghi lỗi, nguồn gốc | M | 089 | 140 | Có |
| FR-08-039 | Xuất bản ghi lỗi có duyệt khi có trường Nhạy | S | 090 | 091, 135 | Có |
| FR-08-040 | Ngoại lệ chấp nhận có hạn, có duyệt | S | 066, 092, 094, 141 | 093, 135 | Có |
| FR-08-041 | Mở phiếu khắc phục từ nhóm lỗi | M | 095, 098, 151 | 096 | Có |
| FR-08-042 | Phân công cho tổ chức chủ quản, SLA | M | 095 | 096 | Có |
| FR-08-043 | Cập nhật tiến độ, trao đổi trên phiếu | M | 099 | 100 | Có |
| FR-08-044 | Xác nhận đã sửa và đo lại kiểm chứng | M | 101, 141, 151 | 102, 103 | Có |
| FR-08-045 | Từ chối, chuyển, leo thang phiếu quá hạn | S | 105, 106 | 105 | Có |
| FR-08-046 | Chuyển lỗi bản ghi vàng sang hàng đợi PH-06 | S | 107 | 107 | Có |
| FR-08-047 | Khai báo quy tắc cảnh báo | S | 108 | 108 | Có |
| FR-08-048 | Phát cảnh báo qua kênh thông báo PH-13 | S | 109 | 109 | Có |
| FR-08-049 | Xác nhận, tắt tiếng cảnh báo | S | 110 | 110 | Có |
| FR-08-050 | Bảng điều khiển chất lượng tenant | M | 111 | 112 | Có |
| FR-08-051 | Thẻ điểm theo đối tượng đo, miền, tổ chức | M | 111 | 112, 130 | Có |
| FR-08-052 | Sinh báo cáo kỳ | M | 115, 151 | 115 | Có |
| FR-08-053 | Duyệt và công bố báo cáo | M | 116, 141, 151 | 117, 135 | Có |
| FR-08-054 | Báo cáo chính thức hằng năm | M | 118 | 119 | Có |
| FR-08-055 | Xuất báo cáo PDF, XLSX, ký số | S | 120, 121 | 121 | Có |
| FR-08-056 | Phân phối báo cáo, đăng ký nhận | S | 122 | 122 | Có |
| FR-08-057 | Đẩy chỉ số sang PH-16, PH-13 | S | 123 | 123 | Có |
| FR-08-058 | Tham số chất lượng theo tenant | M | 124, 141 | 125 | Có |
| FR-08-059 | Lưu giữ và dọn dữ liệu đo | M | 126 | 127 | Có |
| FR-08-060 | Nhật ký kiểm toán PH-08 | M | 128, 141, 142 | 129 | Có |
| FR-08-061 | So sánh liên tenant tổng hợp ẩn danh | C | 113 | 114 | Có |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

Hệ cũ không có chức năng chất lượng dữ liệu; sáu mục `LGC` dưới do PH-07, PH-13, PH-14 làm chính, PH-08 chỉ đo chất lượng sau nhập, thống kê lỗi hoặc dùng làm nguồn đối chiếu. Ca ở cột "TC" kiểm phần PH-08 bổ sung, không kiểm chức năng của hệ cũ (FRS mục 11.1).

| LGC | FR của PH-08 | TC | UAT |
|---|---|---|---|
| LGC-DMDC-006 | 003, 025, 027 | 008, 059, 076, 077 | UAT-05 |
| LGC-DMDC-007 | 003, 025, 027 | 008, 059, 076, 077 | — |
| LGC-DMDC-008 | 003, 025, 027 | 008, 059, 076, 077 | — |
| LGC-BUS-027 | 034 | 086 | UAT-08 |
| LGC-NGSP-003 | 013 | 026 | — |
| LGC-NGSP-005 | 013, 015 | 026, 033 | — |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Quy tắc nghiệp vụ → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-08-001 | 049, 050, 072 |
| BR-08-002 | 045, 046, 062 |
| BR-08-003 | 027, 028, 059 |
| BR-08-004 | 006, 056, 107 |
| BR-08-005 | 006, 007, 011, 058 |
| BR-08-006 | 024, 025, 037, 038, 040, 041 |
| BR-08-007 | 039, 047, 090, 091, 093, 116, 129, 135 |
| BR-08-008 | 048, 069 |
| BR-08-009 | 116, 117, 120, 123 |
| BR-08-010 | 118, 119 |
| BR-08-011 | 117 |
| BR-08-012 | 012, 013, 021, 035, 087, 139, 140 |
| BR-08-013 | 137 |
| BR-08-014 | 101, 103 |
| BR-08-015 | 097, 106 |
| BR-08-016 | 079, 080, 083, 084 |
| BR-08-017 | 030, 031, 032, 082 |
| BR-08-018 | 083, 085 |
| BR-08-019 | 035, 057, 149 |
| BR-08-020 | 017, 052, 053 |
| BR-08-021 | 066, 092, 093 |
| BR-08-022 | 062, 063, 065, 066, 074 |
| BR-08-023 | 046, 062, 067 |
| BR-08-024 | 068 |
| BR-08-025 | 010, 019, 056, 058 |
| BR-08-026 | 003, 015, 016, 081, 088, 096, 100, 112, 131, 133 |
| BR-08-027 | 090 |
| BR-08-028 | 126, 127 |
| BR-08-029 | 109, 110 |
| BR-08-030 | 113, 114 |
| BR-08-031 | 012, 014 |
| BR-08-032 | 034 |
| BR-08-033 | 076 |
| BR-08-034 | 101, 102, 138 |
| BR-08-035 | 098 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

Mã `ERR-08-106…119` là lỗi vận hành của đo lô, báo cáo, sự kiện, không có mã HTTP; ca kiểm ở trạng thái lần đo, cờ ảnh chụp, nhật ký, cảnh báo thay cho mã HTTP.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-08-001 | 016, 021, 042, 070, 088, 089, 112, 130 |
| ERR-08-002 | 002, 007, 025 |
| ERR-08-003 | 002, 013 |
| ERR-08-004 | 005, 125 |
| ERR-08-005 | 039, 047, 091, 093, 117, 135 |
| ERR-08-006 | 004, 014, 018, 032, 041, 053, 100, 105, 110, 114 |
| ERR-08-007 | 018, 039, 041, 047, 053, 091, 093, 096, 103, 105 (+2) |
| ERR-08-008 | 003 |
| ERR-08-009 | 007 |
| ERR-08-010 | 009 |
| ERR-08-011 | 011 |
| ERR-08-012 | 011 |
| ERR-08-013 | 011 |
| ERR-08-014 | 013, 027 |
| ERR-08-015 | 027, 028 |
| ERR-08-016 | 027, 032 |
| ERR-08-017 | 027, 028 |
| ERR-08-018 | 027 |
| ERR-08-019 | 031 |
| ERR-08-020 | 032 |
| ERR-08-021 | 038 |
| ERR-08-022 | 022, 025, 043 |
| ERR-08-023 | 046 |
| ERR-08-024 | 046 |
| ERR-08-025 | 044 |
| ERR-08-026 | 043 |
| ERR-08-027 | 041, 050, 115 |
| ERR-08-028 | 018, 020, 052 |
| ERR-08-029 | 050 |
| ERR-08-030 | 020, 052, 119 |
| ERR-08-031 | 036 |
| ERR-08-032 | 009, 016, 088, 096, 100, 112, 122, 134 |
| ERR-08-033 | 093 |
| ERR-08-034 | 096 |
| ERR-08-035 | 103 |
| ERR-08-036 | 103 |
| ERR-08-037 | 108 |
| ERR-08-038 | 119 |
| ERR-08-039 | 117 |
| ERR-08-040 | 117 |
| ERR-08-041 | 090 |
| ERR-08-042 | 065, 125 |
| ERR-08-043 | 127 |
| ERR-08-044 | 114 |
| ERR-08-045 | 016, 029, 082, 086 |
| ERR-08-046 | 044, 100 |
| ERR-08-047 | 014, 140 |
| ERR-08-048 | 121 |
| ERR-08-049 | 050 |
| ERR-08-050 | 020 |
| ERR-08-051 | 107 |
| ERR-08-052 | 052 |
| ERR-08-053 | 038 |
| ERR-08-054 | 129 |
| ERR-08-055 | 052 |
| ERR-08-101 | 081 |
| ERR-08-102 | 081 |
| ERR-08-103 | 085 |
| ERR-08-104 | 085 |
| ERR-08-105 | 036, 071, 107 |
| ERR-08-106 | 061 |
| ERR-08-107 | 060 |
| ERR-08-108 | 063, 064, 073 |
| ERR-08-109 | 061 |
| ERR-08-110 | 061 |
| ERR-08-111 | 020 |
| ERR-08-112 | 115 |
| ERR-08-113 | 075, 123 |
| ERR-08-114 | 109, 122 |
| ERR-08-115 | 104 |
| ERR-08-116 | 060, 078 |
| ERR-08-117 | 127 |
| ERR-08-118 | 023, 078 |
| ERR-08-119 | 054 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-08-001 | 143 |
| NFR-08-002 | 144 |
| NFR-08-003 | 146, 147 |
| NFR-08-004 | 146 |
| NFR-08-005 | 133, 145 |
| NFR-08-006 | 059, 073, 145 |
| NFR-08-007 | 062, 149 |
| NFR-08-008 | 057, 149 |
| NFR-08-009 | 150 |
| NFR-08-010 | 111, 148 |
| NFR-08-011 | 148 |
| NFR-08-012 | 120, 148 |
| NFR-08-013 | 019, 146 |
| NFR-08-014 | 101, 146 |
| NFR-08-015 | 142, 150 |
| NFR-08-016 | 021, 131, 139 |
| NFR-08-017 | 130, 132, 136 |
| NFR-08-018 | 150 |
| NFR-08-019 | 147 |
| NFR-08-020 | 142 |

: Yêu cầu phi chức năng tới test case

### 8.6. Sự kiện → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-08-01 | 037, 040, 145 |
| EVT-08-02 | 051, 072, 075, 132, 150, 151 |
| EVT-08-03 | 071 |
| EVT-08-04 | 068 |
| EVT-08-05 | 067 |
| EVT-08-06 | 076, 132, 138 |
| EVT-08-07 | 095, 098 |
| EVT-08-08 | 099, 105, 106 |
| EVT-08-09 | 101, 151 |
| EVT-08-10 | 092 |
| EVT-08-11 | 116, 118, 122, 151 |
| EVT-08-12 | 109 |
| EVT-08-13 | 083, 086 |
| EVT-08-14 | 075, 118, 123, 132 |

: Sự kiện tới test case

### 8.7. API → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ api này.

| Mã | Test case |
|---|---|
| API-08-001 | 001 |
| API-08-002 | 001, 002, 003 |
| API-08-003 | 001 |
| API-08-004 | 004, 005 |
| API-08-005 | 015, 016 |
| API-08-006 | 006, 007, 008, 009, 010, 011 |
| API-08-007 | 015, 016, 130 |
| API-08-008 | 012 |
| API-08-009 | 014 |
| API-08-010 | 017, 018 |
| API-08-011 | 017, 018 |
| API-08-012 | 017, 018 |
| API-08-013 | 012 |
| API-08-014 | 012, 013, 140 |
| API-08-015 | 012, 140 |
| API-08-016 | 006 |
| API-08-017 | 008 |
| API-08-018 | 010 |
| API-08-019 | 019, 020 |
| API-08-020 | 019 |
| API-08-021 | 019, 130 |
| API-08-022 | 019, 021 |
| API-08-023 | 022 |
| API-08-024 | 023, 136 |
| API-08-025 | 024 |
| API-08-026 | 024, 025 |
| API-08-027 | 024, 130 |
| API-08-028 | 042 |
| API-08-029 | 024, 025 |
| API-08-030 | 042 |
| API-08-031 | 022, 026, 027, 028, 030, 032, 033 |
| API-08-032 | 026, 027, 032 |
| API-08-033 | 026 |
| API-08-034 | 030, 031 |
| API-08-035 | 033 |
| API-08-036 | 034 |
| API-08-037 | 035, 036, 037 |
| API-08-038 | 037, 038 |
| API-08-039 | 037, 039, 040, 129, 135 |
| API-08-040 | 039 |
| API-08-041 | 037, 040, 041 |
| API-08-042 | 041 |
| API-08-043 | 042 |
| API-08-044 | 043 |
| API-08-045 | 043 |
| API-08-046 | 044 |
| API-08-047 | 045 |
| API-08-048 | 045, 046 |
| API-08-049 | 046 |
| API-08-050 | 045 |
| API-08-051 | 045, 047, 135 |
| API-08-052 | 047 |
| API-08-053 | 029 |
| API-08-054 | 049 |
| API-08-055 | 049, 050 |
| API-08-056 | 049 |
| API-08-057 | 049 |
| API-08-058 | 049 |
| API-08-059 | 051, 052, 055, 057, 058, 119 |
| API-08-060 | 051, 076, 077 |
| API-08-061 | 051, 054, 056, 061, 071, 072, 076, 130, 142 |
| API-08-062 | 053 |
| API-08-063 | 053, 071 |
| API-08-064 | 056, 057, 059, 060 |
| API-08-065 | 048, 062, 063, 064, 065, 066, 067, 068, 069, 070 (+2) |
| API-08-066 | 068, 070 |
| API-08-067 | 051, 072 |
| API-08-068 | 079, 080, 081, 082, 083, 084, 085, 133, 136, 143 (+1) |
| API-08-069 | 082, 144 |
| API-08-070 | 086 |
| API-08-071 | 079, 080, 084 |
| API-08-072 | 079 |
| API-08-073 | 087, 088, 137, 138, 139, 148 |
| API-08-074 | 089, 130, 137, 140 |
| API-08-075 | 090, 091 |
| API-08-076 | 090, 091, 135 |
| API-08-077 | 090 |
| API-08-078 | 087, 095 |
| API-08-079 | 092, 093, 130 |
| API-08-080 | 092 |
| API-08-081 | 092, 093, 135 |
| API-08-082 | 094 |
| API-08-083 | 094 |
| API-08-084 | 095, 096, 097, 098 |
| API-08-085 | 097, 099 |
| API-08-086 | 095, 099, 100, 101, 130 |
| API-08-087 | 095, 096 |
| API-08-088 | 099 |
| API-08-089 | 099, 100 |
| API-08-090 | 101, 102, 103, 104 |
| API-08-091 | 103 |
| API-08-092 | 105 |
| API-08-093 | 105 |
| API-08-094 | 106 |
| API-08-095 | 107 |
| API-08-096 | 105 |
| API-08-097 | 099 |
| API-08-098 | 108 |
| API-08-099 | 108 |
| API-08-100 | 108 |
| API-08-101 | 109 |
| API-08-102 | 110 |
| API-08-103 | 110 |
| API-08-104 | 111, 112, 148 |
| API-08-105 | 111 |
| API-08-106 | 111, 112, 136 |
| API-08-107 | 115, 118, 119 |
| API-08-108 | 115 |
| API-08-109 | 115, 130 |
| API-08-110 | 116, 117 |
| API-08-111 | 116, 117, 118 |
| API-08-112 | 116, 117, 118, 135 |
| API-08-113 | 117 |
| API-08-114 | 117 |
| API-08-115 | 118, 119 |
| API-08-116 | 120 |
| API-08-117 | 120 |
| API-08-118 | 121 |
| API-08-119 | 122 |
| API-08-120 | 122 |
| API-08-121 | 122 |
| API-08-122 | 123, 136 |
| API-08-123 | 124 |
| API-08-124 | 124, 125, 127 |
| API-08-125 | 126, 127 |
| API-08-126 | 126 |
| API-08-127 | 128, 141 |
| API-08-128 | 113, 114 |
| API-08-129 | 088 |
| API-08-130 | 076 |
| API-08-131 | 076 |

: API tới test case

### 8.8. Màn hình → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-08 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-08-01 | 111, 113, 151, 152 |
| UI-08-02 | 015 |
| UI-08-03 | 006, 008, 010 |
| UI-08-04 | 012, 015, 017, 055, 068, 111, 128, 141 |
| UI-08-05 | 019, 022 |
| UI-08-06 | 024, 029, 033, 043 |
| UI-08-07 | 026 |
| UI-08-08 | 026, 030, 033, 035 |
| UI-08-09 | 037, 042 |
| UI-08-10 | 045 |
| UI-08-11 | 049, 051, 151 |
| UI-08-12 | 051, 053, 056, 060, 061, 062, 063, 064, 068, 071 (+3) |
| UI-08-13 | 087, 095, 151, 152 |
| UI-08-14 | 089, 092, 094 |
| UI-08-15 | 095, 099, 105 |
| UI-08-16 | 099, 101, 104, 105, 151 |
| UI-08-17 | 108, 109 |
| UI-08-18 | 115, 116, 118, 120, 121, 122, 151, 152 |
| UI-08-19 | 001, 002, 004, 124, 126, 128 |
| UI-08-20 | 079, 083, 084, 086 |

: Màn hình tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Ca UT, IT, API nằm trong `dh-data/src/test/java/vn/datahub/data/dq/` theo gói con `asset`, `rule`, `scan`, `score`, `inline`, `finding`, `issue`, `alert`, `report`, `admin`; ca E2E trong `dh-console/e2e/chat-luong/`; ca k6 trong `dh-data/perf/dq/`; ca DB chạy tệp `ph08_isolation_test.sql`. Mỗi ca gắn thẻ `@TC-08-nnn` để báo cáo gom về `.xlsx`.

### 9.2. Mẫu ca công thức điểm

Mẫu kiểm điểm chiều và điểm tổng theo bảng 2.4, gồm trường hợp chiều bị bỏ qua.

```java
@Test void diemTongCoTrongSo() {
    var dims = Map.of(COMPLETENESS, 98.00, ACCURACY, 95.00, CONSISTENCY, 80.00,
                      TIMELINESS, 90.00, UNIQUENESS, 99.00, VALIDITY, 85.00);
    assertThat(Scoring.total(dims, Weights.DEFAULT)).isEqualTo(91.45);
    var thieu = new HashMap<>(dims); thieu.put(VALIDITY, null);          // SKIPPED
    var r = Scoring.totalWithFlags(thieu, Weights.DEFAULT);
    assertThat(r.score()).isEqualTo(93.06);                               // 74,45 / 0,80
    assertThat(r.flags()).contains("INCOMPLETE_DIMENSIONS");
}
```

### 9.3. Mẫu ca quét canary

Ca `fnd-mask` đặt `DH-CANARY-leak` vào trường Nhạy cảm, chạy hồ sơ, chạy thử, đo lô, mở phiếu, xuất lỗi, sinh báo cáo, rồi `grep` trong dump `ph08_dq`, log, vết OTel, hộp gửi, topic, tệp xuất; kỳ vọng 0 kết quả.

### 9.4. Sinh ma trận, Gherkin, bảng tính

Chuỗi lệnh dưới chạy từ `05-kiem-thu/test-case/`.

| Lệnh | Kết quả |
|---|---|
| `python3 ph08/tools/number_tcs.py` | Cấp số `TC-08-nnn`, thay `[[tc:khóa]]` |
| `python3 ph08/tools/fill_doc.py` | Ghi bảng 3.1, 3.2, số kịch bản, số ca và mục 8; in ra stderr FR, BR, ERR, NFR chưa có ca |
| `python3 ph08/tools/gen_gherkin.py` | `ph08/gherkin/ts-08-nn.feature`, `uat-chat-luong-du-lieu.feature` |
| `python3 ph08/tools/gen_xlsx.py` | `ph08/D05-02-PH08-test-case.xlsx` theo mẫu nghiệm thu |
| `python3 ph08/tools/check_refs.py` | Đối chiếu mã trong tập với FRS và use case |

: Chuỗi công cụ sinh phần tự động

Bản `.docx` của tài liệu dựng từ `.md` bằng bộ xuất chung của dự án; `.xlsx` và Gherkin là bản để chạy và giao cho người thực hiện sau này.

### 9.5. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối tám tiêu chí ở FRS mục 14 với ca chứng minh.

| Tiêu chí FRS mục 14 | Ca |
|---|---|
| 1. Mọi FR mức M có ca dương và ca âm | mục 8.1 |
| 2. Sáu chiều đều có quy tắc `ACTIVE`; chiều hợp lệ gọi PH-07, không có bảng mã cục bộ | TC-08-026, TC-08-059 |
| 3. Vòng đầy đủ lịch → lần đo → lỗi → phiếu → kiểm chứng → báo cáo | TC-08-151 |
| 4. Báo cáo năm qua bốn mắt; kiểm sẵn sàng chặn đúng | TC-08-118, TC-08-119 |
| 5. NFR-08-001…004, 007, 008 | TS-08-32, TS-08-33, TC-08-149 |
| 6. Quét NFR-08-016 không thấy giá trị Nhạy cảm dạng rõ | TC-08-139 |
| 7. Trực tuyến `STRICT`, `ADVISORY`; diễn tập PH-07 gián đoạn | TC-08-079, TC-08-083, TC-08-085 |
| 8. Chỉ số ở PH-16, PH-13; sự kiện không trùng | TC-08-123, TC-08-075 |

: Đối chiếu tiêu chí chấp nhận cấp phân hệ với ca kiểm thử

## 10. Đề nghị đồng bộ và câu hỏi mở

### 10.1. Đề nghị đồng bộ

Tập kiểm thử không sửa FRS và tài liệu chung; các điểm lệch hoặc mơ hồ phát hiện khi viết ca ghi ở bảng dưới.

| Mã | Tài liệu | Đề nghị |
|---|---|---|
| ĐN-TC-01 | D02-03-PH08 BR-08-016, FR-08-032 | Nêu rõ khi nào `ADVISORY` trả `PASS`, khi nào `WARN` nếu có lỗi `CRITICAL`, `MAJOR` (ca chk-advisory chỉ khẳng định không bao giờ `FAIL`, Q08-44) |
| ĐN-TC-02 | D02-03-PH08 FR-08-032 | Mã lỗi khi `evaluate-batch` quá 100 bản ghi (ca chk-rules dùng ERR-08-045) |
| ĐN-TC-03 | D02-03-PH08 FR-08-013, BR-08-017 | Mã lỗi khi đặt `execMode = INLINE` cho toán tử chỉ chạy lô (ca sql-neg dùng ERR-08-016) |
| ĐN-TC-04 | D02-03-PH08 mục 9.2 | ERR-08-027 dùng cho hai nghĩa ("chưa có bộ quy tắc" và "không có lần đo trong kỳ"); đề nghị câu riêng hoặc mã riêng |
| ĐN-TC-05 | D02-03-PH08 FR-08-049 | Hạn tắt tiếng quá 7 ngày đang dùng ERR-08-007 (thiếu lý do); đề nghị dùng ERR-08-042 |
| ĐN-TC-06 | D02-03-PH08 BR-08-015 | Nêu nguồn lịch ngày làm việc và ngày nghỉ lễ để tính SLA (Q08-43) |

: Đề nghị đồng bộ phát sinh từ tập kiểm thử PH-08

### 10.2. Câu hỏi mở

> **Câu hỏi mở Q08-40:** Bộ dữ liệu UAT dùng số liệu thật đã ẩn danh của T01 hay bộ sinh giả; đến khi có câu trả lời, mọi ca dùng F-SCORE, F-HT sinh bằng hạt cố định và CCCD giả dải `0010990xxxxx`.

> **Câu hỏi mở Q08-41:** Ngưỡng NFR-08-003 (1 triệu bản ghi, 30 quy tắc trong 60 phút) và NFR-08-019 cần đo thật trên bản sao chỉ đọc của HTTT nguồn ở hạ tầng tỉnh trước khi chốt; hiện đo trên PostgreSQL cùng vùng mạng (giả định).

> **Câu hỏi mở Q08-42:** Môi trường thử thật của PH-05, PH-07, PH-13, PH-16 có sẵn cho kiểm thử tích hợp không; hiện dùng WireMock với kịch bản ngừng và trễ.

> **Câu hỏi mở Q08-43:** Lịch ngày làm việc và ngày nghỉ lễ dùng để tính hạn SLA của phiếu lấy từ nguồn nào; ca iss-sla tạm tính thứ Bảy, Chủ nhật.

> **Câu hỏi mở Q08-44:** Kết luận kiểm tra trực tuyến ở chế độ `ADVISORY` khi có lỗi `CRITICAL` là `WARN` hay `PASS` kèm `violations[]`; FRS 0.2 chỉ nêu "luôn `PASS` hoặc `WARN`".

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-26 | Bản đầu: kịch bản TS-08-01…35, test case TC-08, ma trận truy vết, Gherkin, bảng tính |

: Lịch sử phiên bản
