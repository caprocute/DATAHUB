---
ma_tai_lieu: D05-02-PH16
ten: Kịch bản và test case phân hệ PH-16 Báo cáo chỉ tiêu và sổ kiến trúc
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư dh-platform, quản trị tỉnh, cán bộ tổng hợp, cán bộ an toàn thông tin, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-16
mo_ta: Kịch bản và test case chức năng, công thức và trạng thái chỉ tiêu, fail-soft khi thiếu nguồn, bốn mắt, báo cáo công bố bất biến, sổ kiến trúc, gửi quốc gia qua PH-14, cô lập tenant, hiệu năng và nghiệm thu của phân hệ Báo cáo chỉ tiêu và sổ kiến trúc, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH16 FRS; D02-04-PH16 Use case; D03-04-PH16 API (openapi-kpi.yaml); D03-06-PH16 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH16 · Kịch bản và test case Báo cáo chỉ tiêu và sổ kiến trúc

## Tóm tắt cho hội đồng thẩm định

Phần này nói tài liệu chứng minh điều gì, phủ đến đâu và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản, số ca do công cụ sinh lại từ chính các ca nên luôn khớp chương 4 và 5.

**Mục tiêu.** Tài liệu chứng minh năm điều:

- PH-16 làm đúng yêu cầu của D02-03-PH16: 58 FR (37 mức M, 17 mức S, 4 mức C), 35 BR, 22 NFR, 130 API, mã lỗi ERR-16-001…061 và 101…125.
- Chỉ tiêu tính đúng và truy được nguồn: công thức CEL, trạng thái theo ngưỡng ba mức, điểm nhóm 50,00/100,00/75,00/60,00/50,00 và điểm tổng 66,50 ở bộ số chuẩn F-KY-1; thiếu nguồn thì ra số phần đã có, gắn `PARTIAL`, không điền 0, không nội suy.
- Báo cáo chính thức an toàn: bốn mắt không có đường vòng, chỉ tiêu bắt buộc thiếu số thì bị chặn trước khi gửi duyệt, báo cáo `PUBLISHED` bất biến (PDF ký số, mã băm SHA-256, lưu WORM), đính chính bằng phiên bản mới.
- Tenant này không đọc được số liệu, báo cáo, sổ kiến trúc của tenant khác ở API, CSDL (RLS) và Kafka; so sánh liên tenant chỉ ẩn danh và chỉ khi đủ `16.compare.min-tenants` tỉnh.
- Gói quốc gia đi qua PH-14, idempotent, có nhật ký nộp làm bằng chứng, gửi lại không tạo bản trùng; hiệu năng đạt NFR-16-001…010, 015, 016.

**Phạm vi.** Gồm <!--gen:so-ts-->36<!--/gen--> kịch bản với <!--gen:so-tc-->124 (TC-16-001…124; 104 ca P1)<!--/gen--> test case và 8 kịch bản nghiệm thu người dùng (UAT-01…08). Mọi FR mức M có ít nhất một ca dương và một ca âm, mọi FR mức S, C có ít nhất một ca; ma trận mục 8 sinh bằng `ph16/tools/gen_matrix.py`. PH-16 là năng lực mới của Đợt 3 nên mục 7 nghiệm thu theo vai trò, không theo hệ cũ.

**Căn cứ.** FRS D02-03-PH16, use case D02-04-PH16 (kịch bản TS-16-01…30 ứng một một với UC-16-01…30), API D03-04-PH16 (`openapi-kpi.yaml`), màn hình UI-16-01…20 (FRS mục 10.1), D02-08, kế hoạch D05-01 (cổng `RG-1…5`); Nghị định 278/2025, Nghị định 30/2020, Luật Dữ liệu, Luật An ninh mạng; cấu trúc theo ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- công thức, trạng thái và điểm nhóm (TS-16-11), fail-soft khi thiếu nguồn (TS-16-11, 36);
- bốn mắt cho định nghĩa, số liệu tay, báo cáo, đánh giá tuân thủ (TS-16-03, 08, 14, 15, 26, 32);
- báo cáo công bố bất biến, ký số, đính chính (TS-16-15, 16, 35);
- cô lập tenant và ẩn danh so sánh liên tenant (TS-16-21, 31);
- gửi quốc gia: idempotent, biên nhận, gửi lại, `16.national.enabled` (TS-16-28, 29);
- idempotent khi thu thập quan sát, tính lại khi có số trễ, kỳ đã chốt (TS-16-06, 09, 10).

Dữ liệu dùng giả định GĐ-04 (tỉnh vừa, 200 HTTT); khung chỉ số quốc gia chưa ban hành (CMP-LAW-11 là dự thảo) nên công thức, ngưỡng, mẫu gói trong ca là cấu hình thử.

## 0. Giới thiệu

### 0.1. Mục đích

Đặc tả kịch bản và test case của PH-16 để nghiệm thu chức năng, tính đúng của chỉ tiêu, độ bất biến của báo cáo công bố, tuân thủ kiến trúc, gửi quốc gia, an toàn dữ liệu và hiệu năng.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư `dh-platform`, `dh-console` đối chiếu hành vi; cán bộ ATTT kiểm chương 5; quản trị tỉnh, cán bộ tổng hợp, chủ đầu tư dùng mục 7 và 9.5.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; VW người xem; TA quản trị tỉnh; TO cán bộ tổng hợp; SO cán bộ an toàn thông tin; DS cán bộ dữ liệu; AU kiểm toán viên; PA, PO, PU quản trị, vận hành, kiểm toán nền tảng; quan sát (`observation`) một số liệu đã tổng hợp ở phân hệ nguồn; chỉ tiêu (`indicator`) đại lượng được tính theo công thức; kỳ (`period`) tháng, quý, năm; `PARTIAL` kết quả thiếu một phần nguồn; WORM ghi một lần đọc nhiều lần; RLS an toàn theo hàng; CEL ngôn ngữ biểu thức.

### 0.4. Tài liệu tham chiếu

FRS D02-03-PH16 (mã FR, BR, NFR, ERR, EVT, API-16, UI-16, câu thông báo mục 9.2, tham số mục 8.2, Phụ lục A enum), use case D02-04-PH16 (khung kịch bản), OpenAPI `openapi-kpi.yaml`, kế hoạch kiểm thử D05-01, ma trận phân quyền D02-08, khuôn K-TC và K-TRINH-BAY.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng TS-16-01…30 (ứng một một với UC-16-01…30); 5 ca xuyên suốt và phi chức năng TS-16-31…36; 6 thủ công; 7 nghiệm thu; 8 ma trận truy vết; 9 tự động hóa; 10 đề nghị đồng bộ và câu hỏi mở.

### 0.6. Nguyên tắc viết ca

Sáu nguyên tắc áp cho mọi ca.

1. Tên trường, mã HTTP và giá trị enum lấy từ `openapi-kpi.yaml` và FRS Phụ lục A, không đặt tên riêng.
2. Mọi ca nạp dữ liệu bằng API hoặc sự kiện, không chèn SQL (trừ ca DB).
3. Ca có mã lỗi ghi nguyên văn câu thông báo của FRS mục 9.2 với biến đã điền giá trị thử.
4. Ca bốn mắt luôn dùng hai người dùng khác nhau và thử cả trường hợp một người có đủ hai quyền.
5. Ca có đồng hồ (hạn, STALE, giãn cách gửi lại) dùng `clock-sim`, không chờ thật.
6. Con số kỳ vọng tính tay từ bảng ở chương 2, không lấy từ kết quả hệ thống.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là hai mô-đun `vn.datahub.platform.kpi` và `vn.datahub.platform.arch` của `dh-platform` (control plane), schema `ph16_kpi` với RLS theo `tenant_id`, 130 API dưới `/api/kpi/v1` (API-16-001…130), các topic `{tenant}.kpi.*` (EVT-16-01…14) và 20 màn hình dưới `/giam-sat/chi-tieu` (UI-16-01…20). Ngoài phạm vi: số liệu thô và giám sát thời gian thực (PH-13), danh mục API (PH-02), điểm chất lượng (PH-08), danh mục dùng chung (PH-07), kết nối, ký, gửi tới nền tảng quốc gia (PH-14), hộp việc (PH-18), trợ lý hỏi đáp (PH-17); các phân hệ này được giả lập (mục 2.5).

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca; chiến lược chung theo D05-01.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Biểu thức CEL, làm tròn, gộp theo kỳ, trạng thái theo ngưỡng, điểm nhóm |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka KRaft, Keycloak, WireMock) | Dịch vụ với CSDL, hộp gửi, hộp nhận, kho WORM thử |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph16/test/` | RLS, bảng chỉ thêm, phân vùng, bất biến |
| API | API | REST Assured | Mọi API-16 |
| Kafka | KT | `kcat`, client Java OAUTHBEARER | ACL theo tiền tố, nội dung sự kiện |
| Đầu cuối | E2E | Playwright, axe-core | UI-16-01…20 |
| Hiệu năng | k6 | k6, pgbench | NFR-16-001…007, 009, 010, 015, 016 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | Pod, Kafka, PH-13, dịch vụ ký, WORM, PH-14 |
| Bảo mật | ZAP | OWASP ZAP, quét mồi | Quyền, rò rỉ định danh trong `dimensions`, log |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường phục vụ các mức ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, API, KT, E2E khói | `dh-platform` 1 bản sao; phân hệ nguồn, PH-14, dịch vụ ký, kho WORM là WireMock; Kafka KRaft thử |
| STAGING | E2E đầy đủ, Chaos, ZAP, UAT dợt | Giống sản xuất về số bản sao và chính sách mạng; kho WORM Ceph RGW bật Object Lock |
| PERF | k6, đo quy mô | `dh-platform` 2 bản sao 4 vCPU, 8 GB; `pg-core` PostgreSQL 16; tenant T97…T99 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** Hợp đồng `openapi-kpi.yaml` và lược đồ sự kiện đã gắn phiên bản; dữ liệu mục 2 nạp được bằng API hoặc sự kiện; `clock-sim` hoạt động; mẫu `COMMON` đã nạp; PH-14 giả lập có kịch bản `ACK`, `REJECT`, `TIMEOUT`.
- **Ra.** `RG-1` mọi ca API, DB và rò rỉ chéo tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-16 ở PERF; `RG-4` UAT mục 7 ký và 8 tiêu chí chấp nhận ở FRS mục 14 đạt (đối chiếu ở mục 9.5).

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-16-nn`, test case `TC-16-nnn`; mã không tái sử dụng, ca hủy ghi "Đã hủy". Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-16-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và `[[tc:khóa]]`. Đường dẫn API tính từ `/api/kpi/v1`. Lệnh tạo kèm tiêu đề `Idempotency-Key` có giá trị cố định theo ca; lệnh sửa và hành động kèm `If-Match` lấy từ `ETag` lần đọc trước. Mỗi ca có các trường sau.

| Trường | Nội dung |
|---|---|
| **Loại.** | Dương, Âm, Biên, Bảo mật, Hiệu năng, Chịu lỗi, Truy cập |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung |
| **Tự động.** | Mức ở mục 1.2 |
| **Truy vết.** | FR, BR, API, UI, ERR, EVT, NFR, quyền, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu ở chương 2 |
| **Các bước.** | Danh sách đánh số |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán |
| **Thông báo hiển thị.** | Câu người dùng nhìn thấy theo FRS 9.2 (nguyên văn, `{biến}` đã điền giá trị thử); chỉ ở ca có mã lỗi |

: Các trường của khối đặc tả test case

Lỗi thiếu quyền chức năng, chưa xác thực và thiếu `If-Match` dùng mã nền ERR-00-403, ERR-00-401, ERR-00-428 theo FRS 9.1; `403` do bốn mắt, phạm vi dữ liệu hoặc mẫu dùng chung giữ ERR-16-005, ERR-16-037, ERR-16-014. Trong kết quả mong đợi dùng các ký hiệu sau.

| Ký hiệu | Nghĩa |
|---|---|
| 404-ẩn | `404` ERR-16-001; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT | Mọi thao tác ghi đều phải có bản ghi kiểm toán chuyển sang PH-13, đủ trường FR-00-041; ca chỉ nêu khi kiểm nội dung kiểm toán (ca aud-every-write kiểm toàn bộ) |
| EVT: `loại` | Đúng một bản tin trên topic `t90.kpi.{loại}.v1`, chỉ mã, trạng thái, số tổng hợp, không nội dung báo cáo |
| Mồi sạch | Chuỗi mồi `DH-CANARY-{ca}` đặt trong `dimensions` hoặc ghi chú không xuất hiện trong log, vết OTel, kiểm toán, sự kiện, tệp xuất |

: Ký hiệu viết tắt trong kết quả mong đợi

### 1.6. Quản lý lỗi và báo cáo

Lỗi tìm thấy ghi theo mức S1…S4 của D05-01 kèm mã ca, bước, `traceId`; ca không đạt ở cổng `RG-1`, `RG-2` chặn phát hành. Kết quả chạy gom về `.xlsx` (mục 9) qua thẻ `@TC-16-nnn`.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập: tên người là nhân vật hư cấu, tên miền dùng `example.vn`, số văn bản dùng tiền tố `TC/`. Nạp bằng API hoặc sự kiện, trừ khối RLS chạy ở mức CSDL.

### 2.1. Tenant

Tenant kiểm thử dùng dải `T90…T99`; không dùng tenant sản xuất. Theo BR-16-019, dữ liệu các tenant này không vào chỉ tiêu của tenant thật.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant chính | Đã kế thừa 24 chỉ tiêu `COMMON`; nguồn `src-ph01`…`src-ph20`; kỳ `M-2026-09`, `M-2026-10` (bộ F-KY-1); `16.national.enabled = false` |
| `T91` | Đối chứng rò rỉ | Cùng mã chỉ tiêu, báo cáo `bc-thang-2026-10`, thành phần `httt-hotich` nhưng số liệu khác; mọi ca chéo tenant |
| `T92` | Tham số nhỏ | `16.export.max-rows = 1000`, `16.manual.evidence-required = true` khóa bởi PA, `16.source.fail-after = 3` |
| `T93` | Chưa có số liệu | Không kỳ, không nguồn; dùng cho trạng thái trống |
| `T94` | Nguồn lỗi, trễ | Nguồn PH-13, PH-19 có kịch bản ngừng, trễ, `503` |
| `T95` | Chịu lỗi | Cho Chaos: pod, Kafka, PH-13, dịch vụ ký, WORM |
| `T96` | Gửi quốc gia | `16.national.enabled = true`, mẫu gói `KPI_REPORT` và `ARCH_REGISTRY` đã `ACTIVE`, báo cáo `bc-thang-2026-09` đã `PUBLISHED` |
| `T97`…`T99` | Hiệu năng | T97 tổng hợp và tiếp nhận (10 triệu quan sát); T98 bảng điều khiển, xuất, 10.000 thành phần kiến trúc; T99 báo cáo và công bố 50 trang |
| `COMMON` | Dùng chung | Bộ 24 chỉ tiêu mẫu do PA quản lý |

: Tenant kiểm thử

So sánh liên tenant dùng nhóm `T90`, `T91`, `T92`, `T94` đều có số chính thức của chỉ tiêu `tre-gateway-p95` kỳ `M-2026-10` theo cùng phiên bản mẫu; ca âm chỉ dùng `T90`, `T91`.

### 2.2. Người dùng và tài khoản máy

Người dùng mang tên nhân vật hư cấu, vai trò theo D02-08.

| Mã | Tenant | Vai trò | Ghi chú |
|---|---|---|---|
| U-PA | PLATFORM | PA | Mẫu `COMMON`, so sánh liên tenant (thấy mã tỉnh), khóa tham số |
| U-PU | PLATFORM | PU | Chỉ đọc, so sánh liên tenant ẩn danh |
| U-PO | PLATFORM | PO | Theo dõi job toàn nền tảng |
| U-T90-TA1, TA2 | T90 | TA | Lan, Minh; có `PERM-16-approve` và `PERM-16-admin` |
| U-T90-TA3 | T90 | TA | Hùng; cấu hình sai chủ ý có cả `PERM-16-report` và `PERM-16-approve` (chỉ SIT) để kiểm bốn mắt độc lập |
| U-T90-TO1, TO2, SO, DS, AU, VW | T90 | TO, TO, SO, DS, AU, VW | Việt, Hà, Thảo, Quân, Thu, Nam |
| U-T91-TA1, TO1 | T91 | TA, TO | Đối chứng chéo tenant |
| U-T93-TA, U-T94-TA, U-T96-TA, U-T96-TO | T93, T94, T96 | TA, TO | Người dùng của tenant tương ứng |
| S-T90-PH01, PH13, PH19 | T90 | Máy | Scope `kpi.ingest` |
| S-T90-CI, PH17, PH14 | T90 | Máy | Scope `arch.register`, `kpi.read`, `kpi.national-receipt` |
| S-T90-NOSCOPE, S-T91-PH01 | T90, T91 | Máy | Không có scope; thông tin xác thực tenant đối chứng |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu

Bộ dữ liệu có tên, sinh bằng hạt cố định để chạy lại được.

| Mã | Nội dung | Tenant |
|---|---|---|
| F-KY-1 | Kỳ `M-2026-10` đã tính: 24 chỉ tiêu, số quan sát cài sẵn theo bảng 2.4, `completeness` 20/24 | T90 |
| F-LICHSU | 36 kỳ tháng lịch sử; `httt-ket-noi-ty-le` kỳ `M-2026-09` = 70, `M-2025-10` = 60 | T90, T98 |
| F-KT | Sổ kiến trúc 40 thành phần: 12 `HTTT`, 15 `API`, 6 `FLOW`, 5 `TOPIC`, 2 `ADAPTER`, 40 phụ thuộc, 1 thành phần mồ côi cài sẵn (`api-mo-coi`) | T90 |
| F-TC | Bộ tiêu chí tuân thủ phiên bản 1, 12 tiêu chí (8 bắt buộc) theo Khung CPĐT 3.0 | T90 |
| F-BC | Báo cáo `bc-thang-2026-09` `PUBLISHED` phiên bản 1; `bc-thang-2026-10` `DRAFT` | T90 |
| F-PERF | 10 triệu quan sát một phân vùng tháng; 36 kỳ; 10.000 thành phần; 1.000 báo cáo (giả định theo GĐ-04, NFR-16-022) | T97…T99 |

: Bộ dữ liệu kiểm thử

### 2.4. Số đếm chuẩn F-KY-1

Bảng cho kết quả kỳ `M-2026-10` của T90 sau lần tổng hợp. Điểm chỉ tiêu theo BR-16-016 (`ON_TRACK` 100, `AT_RISK` 50, `OFF_TRACK` 0), điểm nhóm là trung bình loại `NO_DATA`, điểm tổng là trung bình có trọng số nhóm. Các ca điểm và bảng điều khiển tính từ bảng này.

| Nhóm | Số chỉ tiêu | ON_TRACK | AT_RISK | OFF_TRACK | NO_DATA | Điểm nhóm | Trọng số | Đóng góp |
|---|---|---|---|---|---|---|---|---|
| `KET_NOI` | 4 | 1 | 1 | 1 | 1 | 50,00 | 30 | 15,00 |
| `CHIA_SE` | 7 | 7 | 0 | 0 | 0 | 100,00 | 20 | 20,00 |
| `DU_LIEU` | 3 | 1 | 1 | 0 | 1 | 75,00 | 20 | 15,00 |
| `VAN_HANH` | 6 | 2 | 2 | 1 | 1 | 60,00 | 15 | 9,00 |
| `KIEN_TRUC` | 4 | 1 | 1 | 1 | 1 | 50,00 | 15 | 7,50 |
| **Tổng** | **24** | **12** | **5** | **3** | **4** | | **100** | **66,50** |

: Số đếm chuẩn và điểm kỳ vọng của F-KY-1

Độ đầy đủ lần tổng hợp: 20 chỉ tiêu có số trên 24, tức `0,833333`, nên là `PARTIAL`. Ví dụ công thức: `httt-ket-noi-ty-le` có công thức `obs("ph01.httt.connected") / obs("ph01.httt.total") * 100`, với 150 trên 200 ra `75,000000`, ngưỡng `greenFrom` 90, `amberFrom` 70 nên là `AT_RISK`; so kỳ trước 70 thì `delta` +5,000000, `trend` `UP`, so cùng kỳ năm trước 60 thì `deltaYoY` +15,000000. Chỉ tiêu chiều thấp tốt `tre-gateway-p95` có `greenFrom` 200, `amberFrom` 300: 250 là `AT_RISK`, 350 là `OFF_TRACK`.

### 2.5. Hệ thống giả lập

Phân hệ và hệ thống ngoài được giả lập như sau.

| Hệ thống | Giả lập bằng | Kịch bản |
|---|---|---|
| PH-01, 02, 04, 05, 07, 08, 10, 13, 19, 20 (`src-sim`) | WireMock và bộ phát Kafka thử | Phát EVT-01-03, EVT-02-05, EVT-04-07, EVT-07-05, EVT-08-14, EVT-19-07…; API chỉ số có kịch bản `200`, `503`, trễ, sai lược đồ |
| PH-14 (`qg-sim`) | WireMock | Nhận gói, trả biên nhận `ACK`, `REJECT` (mã lý do), `TIMEOUT`; gọi lại `/internal/national/receipts` |
| Dịch vụ ký số (`sign-sim`) | WireMock | Ký thành công; `503` |
| Kho WORM (`worm-sim`) | WireMock hoặc Ceph RGW thử | Ghi, đọc, từ chối xóa trước hạn, lỗi ghi |
| PH-13 (`notif-sim`) | WireMock | Nhận kiểm toán, thông báo, trạng thái vận hành; ngừng |
| PH-18 (`inbox-sim`) | WireMock | Nhận việc "Kỳ chưa chốt được", "Báo cáo chờ duyệt" |
| Đồng hồ (`clock-sim`) | Đồng hồ giả | Đẩy thời gian cho STALE, chốt kỳ, hết hạn liên kết, giãn cách gửi lại, hết hạn miễn trừ |

: Hệ thống giả lập

### 2.6. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Mỗi ca ghi dữ liệu sinh ra và dọn bằng khóa `tc-{khóa}` trong tenant; ca dùng lại dữ liệu của ca khác nêu rõ ở tiền điều kiện. Ca bảo mật đặt chuỗi mồi `DH-CANARY-{ca}` và số định danh giả dải `0010990xxxxx` vào `dimensions`.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5; mục 3.2 liệt kê số ca theo loại và mục 3.3 các máy trạng thái được kiểm.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-16-01 | Bộ chỉ tiêu, nhóm và trọng số | UC-16-01 | 4 |
| TS-16-02 | Soạn định nghĩa chỉ tiêu: công thức, mục tiêu, ngưỡng | UC-16-02 | 6 |
| TS-16-03 | Duyệt định nghĩa, ngừng và thay thế chỉ tiêu | UC-16-03 | 4 |
| TS-16-04 | Kế thừa bộ chỉ tiêu mẫu COMMON và nhận cập nhật mẫu | UC-16-04 | 3 |
| TS-16-05 | Đăng ký nguồn số liệu và theo dõi độ tươi | UC-16-05 | 5 |
| TS-16-06 | Tiếp nhận quan sát: sự kiện, kéo API, API đẩy | UC-16-06 | 5 |
| TS-16-07 | Nhật ký tiếp nhận và xử lý lại quan sát bị loại | UC-16-07 | 1 |
| TS-16-08 | Nhập số liệu tay kèm bằng chứng và xác nhận | UC-16-08 | 6 |
| TS-16-09 | Kỳ báo cáo, chốt kỳ và mở lại kỳ | UC-16-09 | 5 |
| TS-16-10 | Chạy tổng hợp theo lịch hoặc thủ công và tính lại | UC-16-10 | 5 |
| TS-16-11 | Tính giá trị, độ đầy đủ, trạng thái và điểm nhóm | UC-16-11 | 7 |
| TS-16-12 | Quản lý mẫu báo cáo | UC-16-12 | 2 |
| TS-16-13 | Lập bản nháp, thuyết minh và báo cáo đột xuất | UC-16-13 | 4 |
| TS-16-14 | Gửi duyệt và duyệt báo cáo bốn mắt | UC-16-14 | 4 |
| TS-16-15 | Công bố báo cáo chính thức | UC-16-15 | 5 |
| TS-16-16 | Đính chính và rút báo cáo đã công bố | UC-16-16 | 2 |
| TS-16-17 | Tra cứu báo cáo và tải bằng chứng công bố | UC-16-17 | 2 |
| TS-16-18 | Xuất báo cáo và phân phối theo danh sách | UC-16-18 | 3 |
| TS-16-19 | Cung cấp chỉ tiêu cho hệ khác và thẻ Tổng quan | UC-16-19 | 2 |
| TS-16-20 | Bảng điều khiển, chi tiết chỉ tiêu và so sánh hai kỳ | UC-16-20 | 3 |
| TS-16-21 | So sánh liên tenant ẩn danh | UC-16-21 | 1 |
| TS-16-22 | Theo dõi vận hành thu thập và tính toán | UC-16-22 | 1 |
| TS-16-23 | Tìm, xem và xuất sổ kiến trúc | UC-16-23 | 2 |
| TS-16-24 | Tự đăng ký, cập nhật vận hành và đối chiếu thành phần | UC-16-24 | 4 |
| TS-16-25 | Khai báo, sửa thành phần, phiên bản và phụ thuộc | UC-16-25 | 3 |
| TS-16-26 | Đánh giá tuân thủ kiến trúc, xác nhận và miễn trừ | UC-16-26 | 4 |
| TS-16-27 | Quản lý mẫu gói quốc gia | UC-16-27 | 1 |
| TS-16-28 | Lập và gửi gói báo cáo chỉ tiêu, sổ kiến trúc qua PH-14 | UC-16-28 | 4 |
| TS-16-29 | Nhật ký nộp, biên nhận, gửi lại và đối soát | UC-16-29 | 4 |
| TS-16-30 | Tham số, lưu giữ dữ liệu và nhật ký kiểm toán | UC-16-30 | 4 |
| TS-16-31 | Cô lập tenant: API, RLS, Kafka | — | 3 |
| TS-16-32 | Phân quyền PERM-16, bốn mắt và tài khoản máy | — | 2 |
| TS-16-33 | Kiểm toán và quan sát vận hành | — | 2 |
| TS-16-34 | Hiệu năng | — | 4 |
| TS-16-35 | Tái lập, chịu lỗi và giao sự kiện | — | 4 |
| TS-16-36 | Vòng đầy đủ và truy cập giao diện | — | 3 |
| **Tổng** | | | **124** (104 ca P1) |

: Danh sách 36 kịch bản kèm use case và số ca
<!--/gen-->

### 3.2. Số ca theo loại

Một ca có thể thuộc nhiều loại nên tổng theo loại lớn hơn tổng số ca.

<!--gen:loai-->
| Loại | Số ca |
|---|---|
| Dương | 71 |
| Âm | 56 |
| Bảo mật | 19 |
| Chịu lỗi | 10 |
| Biên | 6 |
| Hiệu năng | 4 |
| Truy cập | 2 |

: Số ca theo loại
<!--/gen-->

### 3.3. Máy trạng thái được kiểm thử

Bảng liệt kê chuyển hợp lệ và chuyển cấm được kiểm ở chương 4.

| Máy trạng thái (FRS mục 4) | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Phiên bản định nghĩa | DRAFT → PENDING_APPROVAL → ACTIVE; PENDING_APPROVAL → CHANGES_REQUESTED → DRAFT; PENDING_APPROVAL → DRAFT (rút); ACTIVE → SUPERSEDED, RETIRED | Gửi duyệt khi chưa thử tính; tự duyệt; sửa phiên bản `ACTIVE` |
| Nguồn số liệu | ACTIVE ↔ STALE, FAILED, PAUSED; ACTIVE → RETIRED | Ngừng nguồn duy nhất của chỉ tiêu; kéo khi `PAUSED` |
| Số liệu tay | DRAFT → SUBMITTED → ACCEPTED, REJECTED | Tự xác nhận; gửi thiếu bằng chứng; thêm số `ACCEPTED` thứ hai cùng kỳ |
| Kỳ báo cáo | OPEN → COLLECTING → COMPUTED → CLOSED → REOPENED → CLOSED | Tính lại kỳ `CLOSED`; mở lại khi còn báo cáo đang duyệt |
| Lần tổng hợp | QUEUED → RUNNING → SUCCEEDED, PARTIAL, FAILED, CANCELLED | Hai lần chạy cùng kỳ; chạy kỳ `CLOSED` |
| Báo cáo | DRAFT → IN_REVIEW → APPROVED → PUBLISHED → SUPERSEDED, WITHDRAWN; IN_REVIEW, APPROVED → CHANGES_REQUESTED → DRAFT | Sửa báo cáo `PUBLISHED`; tự duyệt, tự công bố; gửi quốc gia báo cáo chưa công bố |
| Đánh giá tuân thủ | DRAFT → SUBMITTED → CONFIRMED, REJECTED | Tự xác nhận; gửi thiếu tiêu chí bắt buộc; miễn trừ quá 180 ngày |
| Gói quốc gia | PENDING → SENDING → SENT → ACKNOWLEDGED; SENDING → FAILED → SENDING; SENT → REJECTED | Gửi lại gói `REJECTED`; gửi quá `16.national.retry-max`; nộp trùng |

: Chuyển trạng thái hợp lệ và bị cấm được kiểm thử

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ, sau đó là các ca theo mục 1.5. TS-16-01…30 cùng số thứ tự với UC-16-01…30.

### TS-16-01 · Bộ chỉ tiêu, nhóm và trọng số

**Mục tiêu.** Xem, lọc bộ chỉ tiêu; đặt trọng số năm nhóm tổng bằng 100, từ chối tổng sai.

**Phủ.** FR-16-001, 007; UC-16-01.

#### TC-16-001 · Liệt kê, lọc và xem chi tiết chỉ tiêu <!--k:ind-list-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-001 · API-16-001, 003, 004 · UI-16-03.

**Tiền điều kiện, dữ liệu.** T90 đã kế thừa 24 chỉ tiêu `COMMON`; U-T90-VW.

**Các bước.**

1. `GET /indicators?page=0&size=10`
2. `GET /indicators?groupCode=KET_NOI&state=ACTIVE&measurement=AUTO`
3. `GET /indicators?q=mttd`
4. `GET /indicators/httt-ket-noi-ty-le`
5. `GET /indicators/httt-ket-noi-ty-le/versions`

**Kết quả mong đợi.** Bước 1 `200`, `totalElements = 24`, `items` đủ `indicatorCode`, `groupCode`, `kind`, `direction`, `measurement`, `unit`, `state`, `facets.byGroup` cộng bằng 24. Bước 2 chỉ chỉ tiêu `KET_NOI` đo `AUTO` (`httt-ket-noi-ty-le`, `thoi-gian-ket-nap-httt`, `thoi-gian-xay-luong`). Bước 3 trả `mttd`. Bước 4 có `activeVersion = 1`, `activeDefinition.formula`, `scope = TENANT`, `derivedFrom.indicatorCode`. Bước 5 trả danh sách phiên bản. EVT: không. KT: không (đọc).

:::

#### TC-16-002 · Bộ lọc sai và chỉ tiêu thuộc tenant khác <!--k:ind-list-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-001 · API-16-001, 003 · ERR-16-057, ERR-16-001.

**Tiền điều kiện, dữ liệu.** T90; chỉ tiêu `tc-chi-t91` chỉ có ở T91 (U-T91-TA1 tạo).

**Các bước.**

1. `GET /indicators?groupCode=XYZ`
2. `GET /indicators?size=5000`
3. U-T90-VW `GET /indicators/tc-chi-t91`
4. `GET /indicators/khong-co`

**Kết quả mong đợi.** Bước 1, 2 `400` ERR-16-057, `errors[]` trỏ `groupCode`, `size`. Bước 3, 4 `404` ERR-16-001, hai thân giống nhau trừ `traceId` (404-ẩn). Không lộ sự tồn tại của chỉ tiêu tenant khác.

**Thông báo hiển thị.** ERR-16-057: "Tham số groupCode không hợp lệ: giá trị không thuộc danh mục."; ERR-16-001: "Không tìm thấy chỉ tiêu tc-chi-t91 trong phạm vi được xem."

:::

#### TC-16-003 · Đặt trọng số năm nhóm tổng bằng 100 <!--k:grp-weights-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-007 · API-16-016, 017 · UI-16-03 · BR-16-016.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; trọng số hiện hành 20 mỗi nhóm.

**Các bước.**

1. `GET /groups`
2. `PUT /groups` với `groups` = `KET_NOI` 30, `CHIA_SE` 20, `DU_LIEU` 20, `VAN_HANH` 15, `KIEN_TRUC` 15, `effectiveFrom = 2026-11-01`, kèm `If-Match`
3. `GET /groups`

**Kết quả mong đợi.** Bước 2 `200`; bước 3 trả đúng năm nhóm với `weight` mới, `displayName`, `order`. Điểm tổng kỳ `M-2026-10` tính lại theo 30/20/20/15/15 cho 66,50 (xem TC-16-051).

:::

#### TC-16-004 · Tổng trọng số khác 100 hoặc thiếu If-Match <!--k:grp-weights-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-007 · API-16-017 · ERR-16-012, ERR-16-004, ERR-00-428, ERR-00-403.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1, U-T90-VW.

**Các bước.**

1. `PUT /groups` với trọng số 30, 20, 20, 15, 10 (tổng 95)
2. `PUT /groups` hợp lệ nhưng không có `If-Match`
3. U-T90-VW `PUT /groups` hợp lệ
4. Hai phiên U-T90-TA1 cùng đọc `ETag` rồi cùng `PUT /groups`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-012, không đổi dữ liệu. Bước 2 `428` ERR-00-428. Bước 3 `403` ERR-00-403. Bước 4 phiên đầu `200`, phiên sau `409` ERR-16-004. Không mất cập nhật.

**Thông báo hiển thị.** ERR-16-012: "Tổng trọng số năm nhóm đang là 95. Điều chỉnh cho bằng 100."; ERR-16-004: "Chỉ tiêu đã được người khác sửa. Tải lại để xem thay đổi." (đối tượng là danh sách nhóm)

:::

### TS-16-02 · Soạn định nghĩa chỉ tiêu: công thức, mục tiêu, ngưỡng

**Mục tiêu.** Tạo chỉ tiêu và phiên bản nháp; công thức CEL kiểm và thử tính; mục tiêu, ngưỡng ba mức hợp lệ.

**Phủ.** FR-16-002, 003, 004; UC-16-02.

#### TC-16-005 · Tạo chỉ tiêu và phiên bản định nghĩa nháp <!--k:ind-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-002 · API-16-002, 005, 003 · UI-16-04 · BR-16-002.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1.

**Các bước.**

1. `POST /indicators` thân `{indicatorCode: tc-ket-noi-moi, name: "Tỷ lệ HTTT kết nối mới", groupCode: KET_NOI, kind: RATIO, direction: HIGHER_BETTER, measurement: AUTO, unit: "%", aggregation: LAST, mandatory: false}` với khóa idempotent `tc-ind-create-1`
2. Gửi lại đúng yêu cầu
3. `POST /indicators/tc-ket-noi-moi/versions` thân `{changeNote: "Bản đầu"}`
4. `GET /indicators/tc-ket-noi-moi`

**Kết quả mong đợi.** Bước 1 `201`, `Location` và `ETag`, `state = DRAFT`, `scope = TENANT`, `activeVersion` trống. Bước 2 trả lại cùng phản hồi, không tạo bản thứ hai. Bước 3 `201`, `version = 1`, `state = DRAFT`. EVT: không (chưa `ACTIVE`).

:::

#### TC-16-006 · Mã trùng, sai mẫu, tổ hợp thuộc tính sai <!--k:ind-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-002 · API-16-002, 005 · ERR-16-002, ERR-16-003, ERR-16-006, ERR-16-058.

**Tiền điều kiện, dữ liệu.** T90; chỉ tiêu `tc-ket-noi-moi` đã có (ind-create).

**Các bước.**

1. `POST /indicators` lại với `indicatorCode = tc-ket-noi-moi`
2. `POST /indicators` với `indicatorCode = "Ket_Noi"`
3. `POST /indicators` với `kind = BOOLEAN`, `aggregation = SUM`, `direction = HIGHER_BETTER`, `unit = "%"`
4. `POST /indicators/tc-ket-noi-moi/versions` khi đã có phiên bản `DRAFT`
5. Gửi lại khóa idempotent `tc-ind-create-1` nhưng thân khác (đổi `name`)

**Kết quả mong đợi.** Bước 1 `409` ERR-16-002. Bước 2 `400` ERR-16-003, `errors[]` trỏ `indicatorCode`. Bước 3 `400` ERR-16-003 (tổ hợp thuộc tính sai). Bước 4 `409` ERR-16-006. Bước 5 `409` ERR-16-058. Không tạo thêm bản ghi.

**Thông báo hiển thị.** ERR-16-058: "Khóa chống trùng tc-ind-create-1 đã dùng cho yêu cầu khác nội dung trong 24 giờ. Tạo khóa mới rồi gửi lại."; ERR-16-002: "Chỉ tiêu tc-ket-noi-moi đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có."; ERR-16-003: "Mã chỉ tiêu chưa hợp lệ: chỉ gồm chữ thường, số, gạch nối, 3 đến 63 ký tự."; ERR-16-006: "Không thể thực hiện khi phiên bản đang ở trạng thái DRAFT."

:::

#### TC-16-007 · Soạn công thức CEL, kiểm và thử tính trên kỳ trước <!--k:formula-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-003 · API-16-007, 008, 009, 010 · UI-16-04 · BR-16-001, BR-16-034.

**Tiền điều kiện, dữ liệu.** T90; `tc-ket-noi-moi` bản 1 `DRAFT`; kỳ `M-2026-09` có quan sát `ph01.httt.connected` = 140, `ph01.httt.total` = 200.

**Các bước.**

1. `GET /metrics?page=0&size=20`
2. `PATCH /indicators/tc-ket-noi-moi/versions/1` với `formula = obs("ph01.httt.connected") / obs("ph01.httt.total") * 100`, `variables = [{alias: connected, metricCode: ph01.httt.connected}, {alias: total, metricCode: ph01.httt.total}]`, `decimals = 1`
3. `POST …/versions/1:validate`
4. `POST …/versions/1:dry-run` với `dryRunPeriods = [M-2026-09]`

**Kết quả mong đợi.** Bước 1 liệt kê `metricCode` có nguồn kèm `sourceCode`. Bước 2 `200`. Bước 3 `valid = true`, `referencedMetrics` đủ hai biến. Bước 4 `results[0].value = 70`, `completeness = COMPLETE`, `elapsedMs` < 50, có `dryRunHash`. Dry-run không ghi giá trị chỉ tiêu nào.

:::

#### TC-16-008 · Công thức sai cú pháp hoặc biến chưa có nguồn <!--k:formula-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-003 · API-16-007, 008, 009 · ERR-16-008, ERR-16-009, ERR-16-011.

**Tiền điều kiện, dữ liệu.** `tc-ket-noi-moi` bản 1 `DRAFT`.

**Các bước.**

1. `PATCH …/versions/1` với `formula = obs("ph01.httt.connected") / (obs("ph01.httt.total") * 100` (thiếu ngoặc đóng) rồi `:validate`
2. `PATCH` với `formula = obs("ph99.khong.co") * 2` và `variables` trỏ `ph99.khong.co`
3. `:dry-run` với `dryRunPeriods = [M-2099-01]`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-008, `errors[].field = formula`, có vị trí dòng và cột. Bước 2 `422` ERR-16-009. Bước 3 `400` ERR-16-003 (kỳ ở tương lai hoặc không có). Phiên bản vẫn `DRAFT`, dòng `dryRunHash` bị xóa sau mỗi lần sửa nên gửi duyệt sau đó bị ERR-16-011 (xem TC-16-012).

**Thông báo hiển thị.** ERR-16-008: "Công thức chưa đúng ở vị trí 1:{cột}: {mô tả}." (cột và mô tả do bộ phân tích CEL trả; ca kiểm khung câu và `errors[]`); ERR-16-009: "Biến ph99.khong.co chưa có nguồn số liệu nào. Đăng ký nguồn trước khi dùng."

:::

#### TC-16-009 · Đặt mục tiêu, ngưỡng ba mức, đơn vị, làm tròn <!--k:target-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-004 · API-16-007, 003 · UI-16-04 · BR-16-015, BR-16-034.

**Tiền điều kiện, dữ liệu.** `tc-ket-noi-moi` bản 1 `DRAFT` có công thức hợp lệ.

**Các bước.**

1. `PATCH …/versions/1` với `target = {baseline: 60, target: 95, targetDate: 2026-12-31, targetMode: ABSOLUTE}`, `thresholds = {greenFrom: 90, amberFrom: 70}`, `direction = HIGHER_BETTER`, `decimals = 1`
2. `PATCH` chiều thấp tốt cho `tre-gateway-p95` bản nháp: `direction = LOWER_BETTER`, `thresholds = {greenFrom: 200, amberFrom: 300}`
3. `PATCH` kiểu khoảng: `direction = TARGET_RANGE`, `thresholds = {range: {low: 80, high: 100, tolerance: 5}}`

**Kết quả mong đợi.** Cả ba `200`; `GET …/versions/1` trả đúng `target`, `thresholds`, `decimals`. Vùng `GREEN`, `AMBER`, `RED` suy ra theo chiều tốt (BR-16-015).

:::

#### TC-16-010 · Ngưỡng không đơn điệu hoặc ngoài miền <!--k:target-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-004 · API-16-007 · ERR-16-010, ERR-16-003.

**Tiền điều kiện, dữ liệu.** `tc-ket-noi-moi` bản 1 `DRAFT`.

**Các bước.**

1. `PATCH` với `direction = HIGHER_BETTER`, `greenFrom = 60`, `amberFrom = 80`
2. `PATCH` với `direction = LOWER_BETTER`, `greenFrom = 300`, `amberFrom = 200`
3. `PATCH` với `decimals = 5`
4. `PATCH` với `targetMode = RELATIVE_TO_BASELINE` nhưng thiếu `baseline`

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-16-010, `errors[]` trỏ `thresholds`. Bước 3, 4 `400` ERR-16-003. Không đổi dữ liệu.

**Thông báo hiển thị.** ERR-16-010: "Ngưỡng chưa hợp lệ: với chiều HIGHER_BETTER, mốc xanh phải lớn hơn mốc vàng."

:::

### TS-16-03 · Duyệt định nghĩa, ngừng và thay thế chỉ tiêu

**Mục tiêu.** Gửi duyệt, duyệt bốn mắt, yêu cầu sửa, rút; ngừng và thay thế chỉ tiêu có điều kiện.

**Phủ.** FR-16-005, 006; UC-16-03.

#### TC-16-011 · Thử tính, gửi duyệt, duyệt và kích hoạt <!--k:ver-submit-approve-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-005 · API-16-011, 012, 078, 004, 006 · UI-16-04, UI-16-12 · EVT-16-01 · BR-16-002, BR-16-003.

**Tiền điều kiện, dữ liệu.** T90; `tc-ket-noi-moi` bản 1 đã `:dry-run` và `target-ok`; U-T90-TA1 soạn, U-T90-TA2 duyệt.

**Các bước.**

1. U-T90-TA1 `POST …/versions/1:submit` với `changeNote` 25 ký tự và `effectiveFrom = 2026-11-01`
2. U-T90-TA2 `GET /review-queue?itemType=INDICATOR_VERSION`
3. U-T90-TA2 `POST …/versions/1:approve` kèm `If-Match`
4. `GET /indicators/tc-ket-noi-moi/versions/1?compareTo=0`

**Kết quả mong đợi.** Bước 1 `200`, `state = PENDING_APPROVAL`, `submittedBy = TA1`. Bước 2 có mục chờ duyệt. Bước 3 `200`, `state = ACTIVE`, `approvedBy = TA2`, chỉ tiêu `activeVersion = 1`. EVT: `indicator.activated` (EVT-16-01) tới PH-13, PH-17. Mỗi chỉ tiêu chỉ một phiên bản `ACTIVE` (BR-16-002).

:::

#### TC-16-012 · Gửi duyệt khi chưa thử tính hoặc thiếu ghi chú <!--k:ver-submit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-005 · API-16-011 · ERR-16-011, ERR-16-007.

**Tiền điều kiện, dữ liệu.** `tc-ket-noi-moi` bản 2 `DRAFT`, vừa sửa `formula` sau lần dry-run.

**Các bước.**

1. `POST …/versions/2:submit` với `changeNote` đủ dài
2. `:dry-run` rồi `POST …/versions/2:submit` với `changeNote = "sửa"`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-011. Bước 2 `422` ERR-16-007. Phiên bản vẫn `DRAFT`.

**Thông báo hiển thị.** ERR-16-011: "Thử tính phiên bản sau lần sửa cuối trước khi gửi duyệt."; ERR-16-007: "Nhập lý do (tối thiểu 20 ký tự)."

:::

#### TC-16-013 · Bốn mắt, yêu cầu sửa và rút bản gửi duyệt <!--k:ver-four-eyes-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-005 · API-16-012, 013, 014 · EVT-16-01 · ERR-16-005, ERR-16-007 · BR-16-003.

**Tiền điều kiện, dữ liệu.** Bản 2 `PENDING_APPROVAL` do U-T90-TA1 soạn và gửi; U-T90-TA3 có cả quyền soạn và duyệt.

**Các bước.**

1. U-T90-TA1 `POST …/versions/2:approve`
2. U-T90-TA2 soạn, U-T90-TA3 gửi một bản khác rồi U-T90-TA2 `:approve`
3. U-T90-TA2 `POST …/versions/2:request-changes` với `comment` 10 ký tự
4. U-T90-TA2 `:request-changes` với `comment` 30 ký tự, TA1 sửa, `:submit` lại, rồi `:withdraw` với `reason` 25 ký tự

**Kết quả mong đợi.** Bước 1 `403` ERR-16-005. Bước 2 `403` ERR-16-005 (người duyệt là người soạn). Bước 3 `422` ERR-16-007. Bước 4 `CHANGES_REQUESTED` kèm `decisionComment`, sau gửi lại về `PENDING_APPROVAL`, sau rút về `DRAFT`. Ở các bước lỗi trạng thái vẫn `PENDING_APPROVAL`, không bản ghi kiểm toán thành công.

**Thông báo hiển thị.** ERR-16-005: "Anh/chị là người lập hoặc gửi nên không được tự duyệt."

:::

#### TC-16-014 · Ngừng và thay thế chỉ tiêu, xem lịch sử phiên bản, ngừng sai điều kiện <!--k:ind-retire-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-006 · API-16-015, 004, 006 · UI-16-03 · ERR-16-013, ERR-16-054, ERR-16-007 · EVT-16-02.

**Tiền điều kiện, dữ liệu.** T90; `tc-ket-noi-moi` `ACTIVE`; `httt-ket-noi-ty-le` `ACTIVE`, không nằm trong báo cáo chờ duyệt.

**Các bước.**

1. `POST /indicators/tc-ket-noi-moi:retire` với `reason` 25 ký tự, `replacedBy = httt-ket-noi-ty-le`, `effectivePeriod = M-2026-12`
2. `GET /indicators/tc-ket-noi-moi`
3. `GET …/versions/2?compareTo=1`
4. `POST /indicators/mttd:retire` khi `mttd` đang trong báo cáo `IN_REVIEW`
5. `:retire` với `replacedBy` đã `RETIRED` hoặc khác `kind`
6. `:retire` với `reason` 5 ký tự

**Kết quả mong đợi.** Bước 1 `200`, chỉ tiêu `state = RETIRED`, `replacedBy` đúng, kỳ từ `M-2026-12` không tính; giá trị các kỳ trước giữ. Bước 3 trả `diff[]` các trường khác nhau giữa hai phiên bản. EVT: `indicator.retired` (EVT-16-02). Bước 4 `409` ERR-16-013. Bước 5 `422` ERR-16-054. Bước 6 `422` ERR-16-007.

**Thông báo hiển thị.** ERR-16-013: "Chỉ tiêu mttd đang có trong 1 báo cáo chờ duyệt. Hoàn tất các báo cáo này trước khi ngừng."; ERR-16-054: "Chỉ tiêu thay thế tc-da-ngung phải đang hiệu lực và cùng loại giá trị."

:::

### TS-16-04 · Kế thừa bộ chỉ tiêu mẫu COMMON và nhận cập nhật mẫu

**Mục tiêu.** Tenant nhận 24 chỉ tiêu mẫu, không sửa trực tiếp, nhận cập nhật mẫu qua quyết định có duyệt.

**Phủ.** FR-16-008; UC-16-04.

#### TC-16-015 · Kế thừa bộ chỉ tiêu mẫu COMMON <!--k:common-adopt-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-008 · API-16-018, 001, 003 · UI-16-03 · BR-16-018.

**Tiền điều kiện, dữ liệu.** T93 chưa có chỉ tiêu; U-T93-TA; mẫu `COMMON` 24 chỉ tiêu (U-PA).

**Các bước.**

1. `GET /indicators?scope=COMMON`
2. `POST /indicators:adopt-common` với `indicatorCodes` rỗng (kế thừa toàn bộ), khóa idempotent `tc-adopt-1`
3. `POST /indicators:adopt-common` lại với `indicatorCodes = [mttd]`
4. `GET /indicators/mttd`

**Kết quả mong đợi.** Bước 1 `200`, 24 chỉ tiêu `scope = COMMON`. Bước 2 `201`, `adopted` 24 mã, `skipped` rỗng; mỗi chỉ tiêu ở tenant có `scope = TENANT`, `derivedFrom = {indicatorCode, version}`, công thức, ngưỡng, nhóm theo mẫu, trạng thái `ACTIVE`. Bước 3 `skipped = [{indicatorCode: mttd, reason}]`, không tạo bản trùng.

:::

#### TC-16-016 · Sửa trực tiếp chỉ tiêu mẫu hoặc kế thừa mã đã có <!--k:common-edit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-008 · API-16-005, 007, 018 · ERR-16-014, ERR-16-002 · BR-16-018.

**Tiền điều kiện, dữ liệu.** T94 chưa kế thừa mẫu (dọn trước ca), U-T94-TA; T90 đã kế thừa, U-T90-TA1; U-PA.

**Các bước.**

1. U-T94-TA `PATCH /indicators/mttd/versions/1` trên chỉ tiêu `scope = COMMON`
2. U-T90-TA1 `POST /indicators:adopt-common` với `indicatorCodes = [mttd]` khi đã có bản tùy biến
3. U-PA sửa mẫu `COMMON` hợp lệ

**Kết quả mong đợi.** Bước 1 `403` ERR-16-014. Bước 2 `skipped` kèm lý do trùng (`201` với `adopted` rỗng) hoặc `409` ERR-16-002 khi mã trùng bản tự đặt. Bước 3 `200` (PA có quyền với mẫu). Mẫu `COMMON` không đổi từ phía tenant (BR-16-018).

**Thông báo hiển thị.** ERR-16-014: "Chỉ tiêu mẫu dùng chung không sửa trực tiếp được. Tạo phiên bản tùy biến của tỉnh."

:::

#### TC-16-017 · Nhận cập nhật mẫu, quyết định ACCEPT hoặc DISMISS, xung đột tùy biến <!--k:common-update-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-008 · API-16-019, 020 · UI-16-03 · ERR-16-055 · BR-16-018 · EVT-16-01.

**Tiền điều kiện, dữ liệu.** T90 đã kế thừa; U-PA phát phiên bản 2 của mẫu `api-cong-bo` (đổi `greenFrom`) và `mttr-muc-1`; T90 chưa tùy biến hai chỉ tiêu này.

**Các bước.**

1. `GET /common-updates`
2. `GET /indicators`
3. U-T90-TA1 `POST /common-updates/api-cong-bo:decide` với `decision = ACCEPT`
4. `POST /common-updates/mttr-muc-1:decide` với `decision = DISMISS`, `comment`
5. `POST /common-updates/tre-gateway-p95:decide` `ACCEPT` khi T90 đã tùy biến `thresholds` của chỉ tiêu này và mẫu cũng đổi `thresholds`

**Kết quả mong đợi.** Bước 1 có hai mục, `changedFields`, `conflictFields` rỗng. Bước 2 `hasCommonUpdate = true`. Bước 3 `newDraftVersion` trỏ bản nháp tùy biến, chưa `ACTIVE` tới khi duyệt bốn mắt (BR-16-018); số liệu đang chạy không đổi. Bước 4 `dismissed = true`, mục chuyển `DISMISSED`. Bước 5 `conflictFields = [thresholds]`, `409` ERR-16-055, không tạo bản nháp.

**Thông báo hiển thị.** ERR-16-055: "Trường thresholds đã được tỉnh tùy biến và mẫu cũng thay đổi. Chọn giữ bản nào."

:::

### TS-16-05 · Đăng ký nguồn số liệu và theo dõi độ tươi

**Mục tiêu.** Đăng ký bốn loại nguồn kèm hợp đồng chỉ số; STALE, FAILED, tạm dừng và ngừng đúng điều kiện.

**Phủ.** FR-16-009, 013; UC-16-05.

#### TC-16-018 · Đăng ký nguồn EVENT, PULL_API, PUSH_API, MANUAL và thử nguồn <!--k:src-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-009 · API-16-022, 023, 021, 025, 024 · UI-16-05.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; `src-sim` có API chỉ số của PH-13 trả `200`.

**Các bước.**

1. `POST /sources` `{sourceCode: tc-ph01-event, sourceType: EVENT, providerModule: PH-01, topic: "t90.httt.activated.v1", schemaRef: "evt-01-03@1", contract: {metricCodes: [ph01.httt.connected, ph01.httt.total]}, priority: 1}`
2. `POST /sources` `{sourceCode: tc-ph13-pull, sourceType: PULL_API, providerModule: PH-13, endpoint: "/metrics/sla-month", cron: "0 0 2 * * *", scope: "metrics.read", contract: {metricCodes: [ph13.dataplane.availability]}}`
3. `POST /sources` loại `PUSH_API` (`clientId = S-T90-PH19`) và loại `MANUAL`
4. `POST /sources/tc-ph13-pull:test`
5. `GET /sources?page=0&size=10`
6. `PATCH /sources/tc-ph13-pull` đổi `priority = 2` kèm `If-Match`

**Kết quả mong đợi.** Bốn lần tạo `201`, `state = ACTIVE`, `Location`, `ETag`. `:test` `200`, `ok = true`, `sampleMetrics` chứa `ph13.dataplane.availability`, `elapsedMs`. Danh sách có `freshness.state`, `ageHours`. Sau `PATCH` `priority = 2`. EVT: `source.state-changed` (EVT-16-03) khi tạo `ACTIVE`.

:::

#### TC-16-019 · Cấu hình thiếu theo loại, mã trùng, thử nguồn thất bại <!--k:src-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-009 · API-16-022, 025 · ERR-16-015, ERR-16-002, ERR-16-016.

**Tiền điều kiện, dữ liệu.** Nguồn `tc-ph01-event` đã có; `src-sim` PH-13 trả `500` cho `/metrics/hong`.

**Các bước.**

1. `POST /sources` loại `EVENT` thiếu `topic`
2. `POST /sources` loại `PULL_API` thiếu `endpoint`
3. `POST /sources` lại `sourceCode = tc-ph01-event`
4. tạo nguồn `tc-hong` với `endpoint = "/metrics/hong"` rồi `:test`
5. U-T90-VW `POST /sources`

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-16-015. Bước 3 `409` ERR-16-002. Bước 4 `422` ERR-16-016, `ok = false`. Bước 5 `403` ERR-00-403.

**Thông báo hiển thị.** ERR-16-015: "Nguồn loại EVENT cần topic. Bổ sung trước khi lưu."; ERR-16-016: "Không đọc được dữ liệu từ nguồn tc-hong: HTTP 500. Kiểm tra quyền và cấu hình."

:::

#### TC-16-020 · Nguồn quá hạn chuyển STALE rồi ACTIVE khi có số mới <!--k:src-stale-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-013 · API-16-023, 021 · UI-16-05, UI-16-06 · ERR-16-107 · EVT-16-03 · NFR-16-014 · BR-16-007.

**Tiền điều kiện, dữ liệu.** T90; nguồn `src-ph13` `ACTIVE`, quan sát cuối cùng lúc T0; `clock-sim`; `16.source.stale-hours = 26`.

**Các bước.**

1. Đẩy `clock-sim` tới T0 + 25 giờ, đợi bộ quét 10 phút
2. Đẩy tới T0 + 26 giờ 10 phút, đợi bộ quét
3. `GET /sources/src-ph13`
4. Đẩy một quan sát mới `ph13.dataplane.availability` qua `kpi.ingest`

**Kết quả mong đợi.** Sau bước 1 vẫn `ACTIVE`. Sau bước 2 `state = STALE` trong ≤ 15 phút kể từ khi quá ngưỡng (NFR-16-014), `freshness.ageHours` ≥ 26, `stateReason` ghi ERR-16-107; EVT: `source.state-changed` tới PH-13 (thông báo) và PH-18. Lần tổng hợp tiếp theo gắn cờ `STALE_SOURCE` cho chỉ tiêu dùng nguồn này. Sau bước 4 về `ACTIVE`, phát thêm một EVT.

**Thông báo hiển thị.** ERR-16-107: "Nguồn src-ph13 không có số mới từ 2026-11-24 00:00."

:::

#### TC-16-021 · Kéo API lỗi liên tiếp chuyển FAILED <!--k:src-failed-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-013, FR-16-011 · API-16-023, 029 · ERR-16-106, ERR-16-108 · EVT-16-03 · UI-16-06.

**Tiền điều kiện, dữ liệu.** T94; nguồn `src-ph19` loại `PULL_API`; `src-sim` PH-19 trả `503`; `16.source.fail-after = 3`.

**Các bước.**

1. Kích hoạt kéo theo lịch ba lần liên tiếp (hoặc `POST /sources/src-ph19:pull` ba lần)
2. `GET /sources/src-ph19/ingest-logs?result=REJECTED`
3. đổi `src-sim` về `200`, kéo lần bốn
4. `GET /sources/src-ph19`

**Kết quả mong đợi.** Lần 1, 2 ghi ERR-16-106 "lần 1", "lần 2", nguồn vẫn `ACTIVE`. Lần 3 nguồn `FAILED` (ERR-16-108), EVT: `source.state-changed`. Nhật ký có ba dòng lỗi. Lần 4 thành công, nguồn về `ACTIVE`, bộ đếm lỗi về 0.

**Thông báo hiển thị.** ERR-16-106: "Kéo số từ src-ph19 lỗi lần 2: HTTP 503."; ERR-16-108: "Nguồn src-ph19 lỗi 3 lần liên tiếp, đã chuyển trạng thái Lỗi."

:::

#### TC-16-022 · Tạm dừng, tiếp tục và ngừng nguồn <!--k:src-pause-retire-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-009, FR-16-013 · API-16-026, 027, 028 · ERR-16-007, ERR-16-017, ERR-16-006 · EVT-16-03.

**Tiền điều kiện, dữ liệu.** T90; `src-ph13` là nguồn duy nhất của `san-sang-data-plane` (đang `ACTIVE`); nguồn `tc-phu` không chỉ tiêu nào dùng.

**Các bước.**

1. `POST /sources/tc-phu:pause` với `reason` 5 ký tự
2. `:pause` với `reason` 25 ký tự và `until`
3. `POST /sources/tc-phu:pull`
4. `:resume`
5. `POST /sources/src-ph13:retire` với `reason` 25 ký tự
6. `POST /sources/tc-phu:retire`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-007. Bước 2 `PAUSED`, EVT. Bước 3 `409` ERR-16-006. Bước 4 `ACTIVE`. Bước 5 `409` ERR-16-017. Bước 6 `200`, `RETIRED`. KT: có từng thao tác.

**Thông báo hiển thị.** ERR-16-017: "Nguồn src-ph13 là nguồn duy nhất của 1 chỉ tiêu đang hiệu lực."

:::

### TS-16-06 · Tiếp nhận quan sát: sự kiện, kéo API, API đẩy

**Mục tiêu.** Quan sát vào idempotent, chuẩn hóa, loại đúng điều kiện; kéo bù khi lỡ sự kiện.

**Phủ.** FR-16-010, 011, 012; UC-16-06.

#### TC-16-023 · Tiếp nhận quan sát từ sự kiện Kafka, idempotent <!--k:ing-event-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-010 · API-16-043, 042 · UI-16-06 · BR-16-012, BR-16-013 · NFR-16-004.

**Tiền điều kiện, dữ liệu.** T90; nguồn `tc-ph01-event` `ACTIVE`; bộ phát Kafka thử.

**Các bước.**

1. Phát EVT-01-03 mang `eventId = e-001`, số HTTT kết nối 150 và tổng 200 kỳ `M-2026-10`
2. Phát lại đúng bản tin `e-001`
3. `GET /observations?sourceCode=tc-ph01-event&periodCode=M-2026-10`
4. `GET /sources/tc-ph01-event/ingest-logs`

**Kết quả mong đợi.** Bước 1 tạo hai quan sát chuẩn hóa `ph01.httt.connected` = 150, `ph01.httt.total` = 200 với `periodStart = 2026-10-01`, `periodEnd = 2026-10-31`, `idempotencyRef = e-001`, `channel = EVENT`, `late = false`, trễ p95 ≤ 60 giây. Bước 2 không tạo thêm (`DUPLICATE` trong nhật ký). Bước 3 đúng hai quan sát. Kỳ tính theo `periodEnd`, múi giờ `Asia/Ho_Chi_Minh`.

:::

#### TC-16-024 · Bản tin sai lược đồ, chỉ số ngoài hợp đồng, dữ liệu thử <!--k:ing-event-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-010 · API-16-042, 044 · ERR-16-105, ERR-16-102 · BR-16-019.

**Tiền điều kiện, dữ liệu.** T90; hợp đồng `tc-ph01-event` chỉ có `ph01.httt.*`; nguồn PH-19 `src-ph19`.

**Các bước.**

1. Phát bản tin thiếu trường `periodEnd`
2. Phát bản tin có `metricCode = ph01.khac.chi-so`
3. Phát EVT-19-07 có `isTest = true`
4. `GET /rejected-observations`

**Kết quả mong đợi.** Bước 1 loại, ghi ERR-16-105, bản tin vào hàng lỗi (DLQ), không tạo quan sát. Bước 2 loại, ERR-16-102. Bước 3 không tạo quan sát nào cho `giao-dich-thanh-toan-truc-tuyen` (BR-16-019). Bước 4 liệt kê hai dòng bị loại với `code`, `detail`.

**Thông báo hiển thị.** ERR-16-105: "Bản tin không đúng lược đồ evt-01-03@1: thiếu trường periodEnd."; ERR-16-102: "Chỉ số ph01.khac.chi-so không thuộc hợp đồng của nguồn tc-ph01-event."

:::

#### TC-16-025 · API đẩy quan sát theo lô, kết quả từng phần tử, idempotent <!--k:ing-push-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-012, FR-16-010 · API-16-030 · UI-16-06 · ERR-16-103 · BR-16-012 · NFR-16-003 · scope `kpi.ingest`.

**Tiền điều kiện, dữ liệu.** S-T90-PH01; nguồn `tc-ph01-push`.

**Các bước.**

1. `POST /ingest/observations` với 100 quan sát hợp lệ (`metricCode` thuộc hợp đồng, `idempotencyRef` khác nhau)
2. Gửi lô 4 phần tử: 2 hợp lệ, 1 trùng bước trước, 1 `metricCode` ngoài hợp đồng
3. `GET /sources/tc-ph01-push/ingest-logs?result=ACCEPTED`
4. Gửi lô một quan sát `snap-1001` giá trị 200, gửi lại đúng lô, rồi gửi lại `snap-1001` với giá trị 210

**Kết quả mong đợi.** Bước 1 `202`, `accepted = 100`, `duplicate = 0`, `rejected = 0`. Bước 2 `207`, `accepted = 2`, `duplicate = 1`, `rejected = 1`, `results[].index`, `status`, `code = ERR-16-102` cho phần tử bị loại. Bước 3 có đủ dòng. Với 100 quan sát p95 ≤ 300 ms (đo chi tiết ở TC-16-115). Bước 4 `202` `accepted = 1`; gửi lại `duplicate = 1`; giá trị 210 `REJECTED` `code = ERR-16-103`, không ghi đè 200.

**Thông báo hiển thị.** ERR-16-103: "Quan sát snap-1001 đã có với giá trị khác. Cần kiểm tra ở phân hệ nguồn."

:::

#### TC-16-026 · API đẩy: thiếu scope, lệch tenant, định danh cá nhân trong dimensions <!--k:ing-push-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-012, FR-16-010 · API-16-030 · ERR-16-101, ERR-16-037 · BR-16-028 · scope `kpi.ingest`.

**Tiền điều kiện, dữ liệu.** S-T90-NOSCOPE, S-T91-PH01, S-T90-PH01; mồi `0010990123456`.

**Các bước.**

1. S-T90-NOSCOPE `POST /ingest/observations`
2. S-T91-PH01 gửi lô với `sourceCode = tc-ph01-push` của T90
3. S-T90-PH01 gửi quan sát có `dimensions = {cccd: "0010990123456", ghiChu: "DH-CANARY-ing-push"}`
4. S-T90-PH01 gửi quan sát thiếu `value`

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403. Bước 2 `403` ERR-16-037 (hoặc `400` ERR-16-101 lệch tenant), không ghi vào T90. Bước 3 loại, `code = ERR-16-101`, `errors[]` trỏ `dimensions`; mồi sạch ở log, nhật ký tiếp nhận, kiểm toán. Bước 4 `400` ERR-16-101.

**Thông báo hiển thị.** ERR-16-101: "Quan sát thứ 1 sai lược đồ: dimensions."

:::

#### TC-16-027 · Kéo API chỉ số theo lịch, đọc bù khi lỡ sự kiện, kéo lỗi <!--k:ing-pull-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-011 · API-16-029, 042, 043 · UI-16-06 · ERR-16-006, ERR-16-060, ERR-16-106 · BR-16-012 · NFR-16-004.

**Tiền điều kiện, dữ liệu.** T90; nguồn `tc-ph13-pull` `ACTIVE`; `src-sim` PH-13 trả chỉ số tháng cho `M-2026-10`; nguồn `tc-ph01-event` mất bản tin `e-777` (không tới Kafka) nhưng có ở API thống kê PH-01.

**Các bước.**

1. `POST /sources/tc-ph13-pull:pull` với `from = 2026-10-01`, `to = 2026-10-31`
2. `GET /sources/tc-ph13-pull/ingest-logs`
3. Chạy bộ đọc bù của `tc-ph01-event` (lịch đêm)
4. `GET /observations?sourceCode=tc-ph01-event&late=false`
5. `POST /sources/tc-phu:pull` (nguồn `PAUSED`)
6. `POST /sources/tc-ph13-pull:pull` khi `src-sim` PH-13 trả `503`, rồi đọc bù với `from`/`to` cách nhau 14 tháng

**Kết quả mong đợi.** Bước 1 `202`, `ingestLogId`, `state = QUEUED`. Bước 2 có dòng `ACCEPTED` kèm `channel = PULL_API`. Bước 3 phát hiện thiếu `e-777`, kéo bù và ghi quan sát (`idempotencyRef` theo `snapshotId`), không trùng với quan sát đã nhận từ sự kiện. Kéo lại cùng khoảng không tạo bản trùng. Bước 5 `409` ERR-16-006. Bước 6 tác vụ kết thúc lỗi, nhật ký ERR-16-106 kèm `503`, không ghi quan sát, dữ liệu cũ giữ; khoảng đọc bù quá 12 tháng `400` ERR-16-060 "Khoảng thời gian tra cứu tối đa 12 tháng mỗi lần."

:::

### TS-16-07 · Nhật ký tiếp nhận và xử lý lại quan sát bị loại

**Mục tiêu.** Tra nhật ký, lọc theo kết quả và mã lỗi; xử lý lại sau khi sửa hợp đồng.

**Phủ.** FR-16-016; UC-16-07.

#### TC-16-028 · Tra nhật ký tiếp nhận và xử lý lại quan sát bị loại <!--k:reprocess-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-016 · API-16-042, 044, 045, 024 · ERR-16-007, ERR-16-003 · UI-16-06.

**Tiền điều kiện, dữ liệu.** Quan sát bị loại `ph01.khac.chi-so` (id `r1`) và bản tin sai lược đồ (id `r2`) từ TC-16-024.

**Các bước.**

1. `GET /sources/tc-ph01-event/ingest-logs?result=REJECTED&code=ERR-16-102`
2. `GET /rejected-observations?sourceCode=tc-ph01-event`
3. U-T90-VW `GET /sources/tc-ph01-event/ingest-logs`
4. `PATCH /sources/tc-ph01-event` thêm `ph01.khac.chi-so` vào `contract.metricCodes`
5. `POST /rejected-observations:reprocess` `{ids: [r1, r2], reason: "Đã bổ sung hợp đồng chỉ số"}`
6. `POST /rejected-observations:reprocess` với `reason` 5 ký tự
7. `POST /rejected-observations:reprocess` với `ids` rỗng

**Kết quả mong đợi.** Bước 1, 2 chỉ trả dòng khớp bộ lọc (`metricCode`, `code`, `detail`, `receivedAt`). Bước 3 `403` ERR-00-403. Bước 5 `200`, `reprocessed = 1` (`r1`), `stillRejected = [{id: r2, code: ERR-16-105}]`. Bước 6 `400` ERR-16-003 (`reason` ngắn hơn 20 ký tự theo lược đồ) hoặc `422` ERR-16-007. Bước 7 `400` ERR-16-003. Quan sát `r1` có `REPROCESSED` trong nhật ký, không trùng.

:::

### TS-16-08 · Nhập số liệu tay kèm bằng chứng và xác nhận

**Mục tiêu.** Nhập tay có bằng chứng, nhập hàng loạt có xem trước, xác nhận bốn mắt, chỉ tiêu MIXED.

**Phủ.** FR-16-014, 015; UC-16-08.

#### TC-16-029 · Nhập tay kèm bằng chứng và gửi xác nhận <!--k:man-create-submit-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-014 · API-16-032, 035, 033, 039, 031 · UI-16-07 · BR-16-006.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; chỉ tiêu `ket-noi-diem-diem-con-lai` (MANUAL, đơn vị `điểm`); kỳ `M-2026-10` chưa chốt.

**Các bước.**

1. `POST /manual-values` `{indicatorCode: ket-noi-diem-diem-con-lai, periodCode: M-2026-10, value: 142, method: "Khảo sát 200 HTTT bằng biểu mẫu nội bộ quý 4", evidence: [{docNumber: "TC/KS-2026-10", docDate: 2026-10-28}]}`
2. `POST /manual-values/{manualId}/evidence` tệp PDF 200 KB, `docNumber`, `docDate`
3. `POST /manual-values/{manualId}:submit`
4. `GET /manual-values?state=SUBMITTED&periodCode=M-2026-10`

**Kết quả mong đợi.** Bước 1 `201`, `state = DRAFT`, `enteredBy = TO1`. Bước 2 `201`, `evidence[].sha256` 64 ký tự hex. Bước 3 `200`, `state = SUBMITTED`, `submittedAt`. Bước 4 có bản này. Giá trị chưa vào tính toán tới khi `ACCEPTED`; lần tổng hợp gắn cờ `MANUAL_PENDING` (ERR-16-112).

:::

#### TC-16-030 · Thiếu bằng chứng, ngoài miền, tệp sai loại, kỳ đã chốt <!--k:man-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-014 · API-16-032, 035, 039, 034 · ERR-16-018, ERR-16-019, ERR-16-053, ERR-16-022 · BR-16-006.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; `16.manual.evidence-required = true`; kỳ `M-2026-09` `CLOSED`; chỉ tiêu `diem-hai-long-sus` miền 0…100.

**Các bước.**

1. Tạo số tay không `evidence` rồi `:submit`
2. Tạo `diem-hai-long-sus` `value = 120`
3. `POST …/evidence` tải tệp `bang-chung.exe`
4. `POST /manual-values` cho kỳ `M-2026-09`
5. `PATCH /manual-values/{manualId}` bản `SUBMITTED` đổi `value`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-018. Bước 2 `422` ERR-16-019. Bước 3 `400` ERR-16-053. Bước 4 `409` ERR-16-022. Bước 5 `409` ERR-16-006 (không sửa bản đã gửi). Không bản nhập nào được tạo hoặc đổi.

**Thông báo hiển thị.** ERR-16-018: "Số liệu tay cần ít nhất một bằng chứng (tệp hoặc số văn bản)."; ERR-16-019: "Giá trị 120 nằm ngoài miền cho phép của chỉ tiêu (0 đến 100)."; ERR-16-053: "Tệp bang-chung.exe không được nhận: chỉ PDF, ảnh, XLSX, DOCX tối đa 20 MB."; ERR-16-022: "Kỳ M-2026-09 đã chốt. Mở lại kỳ nếu cần sửa hoặc tính lại."

:::

#### TC-16-031 · Nhập hàng loạt bằng tệp XLSX có xem trước, tệp sai <!--k:man-import-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-014 · API-16-036, 037, 038 · UI-16-07 · ERR-16-020, ERR-16-021.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; tệp theo mẫu tải về từ `GET /manual-values/template` gồm 3 dòng hợp lệ, 1 dòng `value` sai kiểu.

**Các bước.**

1. `GET /manual-values/template`
2. `POST /manual-values:import` tải tệp
3. `POST /manual-values/imports/{importId}:commit`
4. `POST /manual-values:import` với tệp thiếu cột `periodCode`, rồi tệp 2.001 dòng
5. Commit tệp có một dòng trùng chỉ tiêu và kỳ đã `ACCEPTED`

**Kết quả mong đợi.** Bước 2 `200`, `rows[]` có `row`, `status` (`VALID` hoặc `INVALID`), `errors`; `validCount = 3`, `invalidCount = 1`, `expiresAt`; chưa ghi gì. Bước 3 `200`, chỉ 3 dòng `IMPORTED`, tạo 3 bản nhập `DRAFT`; dòng sai không tạo. Bước 4 `422` ERR-16-020 "Tệp không đúng mẫu nhập số liệu hoặc vượt 2.000 dòng. Tải mẫu mới nhất." Bước 5 `409` ERR-16-021, không dòng nào được ghi.

:::

#### TC-16-032 · Xác nhận số liệu tay và dùng vào tính toán <!--k:man-accept-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-015 · API-16-040, 078, 053 · UI-16-07, UI-16-12 · EVT-16-04 · BR-16-005.

**Tiền điều kiện, dữ liệu.** Số tay `SUBMITTED` của `ket-noi-diem-diem-con-lai` do U-T90-TO1 nhập (man-create-submit); U-T90-SO có `PERM-16-manual`, nằm trong `confirmerRoles`.

**Các bước.**

1. U-T90-SO `GET /review-queue?itemType=MANUAL_VALUE`
2. U-T90-SO `POST /manual-values/{manualId}:accept`
3. `POST /periods/M-2026-10/runs` rồi `GET /runs/{runId}/values?indicatorCode=ket-noi-diem-diem-con-lai`

**Kết quả mong đợi.** Bước 2 `200`, `state = ACCEPTED`, `decidedBy = SO`. EVT: `manual-value.decided` (EVT-16-04) tới PH-18. Bước 3 giá trị chỉ tiêu `value = 142`, `completeness = COMPLETE`, dòng truy nguồn có `manualId` (BR-16-001).

:::

#### TC-16-033 · Người nhập tự xác nhận, sai vai trò, từ chối thiếu lý do, trùng số <!--k:man-four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-015 · API-16-040, 041 · ERR-16-005, ERR-16-059, ERR-16-007, ERR-16-021 · BR-16-005.

**Tiền điều kiện, dữ liệu.** Số tay `SUBMITTED` do TO1 nhập; U-T90-TA1 không thuộc `confirmerRoles` của chỉ tiêu này; chỉ tiêu đã có số `ACCEPTED` cùng kỳ ở ca khác.

**Các bước.**

1. U-T90-TO1 `:accept` bản của chính mình
2. U-T90-TA1 `:accept`
3. U-T90-SO `POST …:reject` với `reason` 10 ký tự
4. U-T90-SO `:accept` bản thứ hai cùng chỉ tiêu và kỳ khi đã có `ACCEPTED`

**Kết quả mong đợi.** Bước 1 `403` ERR-16-005. Bước 2 `403` ERR-16-059 (không thuộc vai trò được xác nhận). Bước 3 `422` ERR-16-007. Bước 4 `409` ERR-16-021. Trạng thái bản nhập không đổi.

**Thông báo hiển thị.** ERR-16-059: "Anh/chị không thuộc vai trò được giao xác nhận số liệu của chỉ tiêu ket-noi-diem-diem-con-lai này."; ERR-16-007: "Nhập lý do (tối thiểu 20 ký tự)."

:::

#### TC-16-034 · Chỉ tiêu MIXED: số tự động chỉ có hiệu lực khi có xác nhận tay <!--k:man-mixed-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-014, FR-16-015 · API-16-040, 053 · BR-16-035 · EVT-16-04.

**Tiền điều kiện, dữ liệu.** T90; chỉ tiêu `bi-mat-ngoai-kho` (MIXED); PH-12 quét ra 0 bí mật ngoài kho (AUTO) kỳ `M-2026-10`; chưa có số tay.

**Các bước.**

1. Chạy tổng hợp `M-2026-10`, đọc `bi-mat-ngoai-kho`
2. U-T90-SO nhập số tay `0` có bằng chứng, gửi, U-T90-DS xác nhận (người khác người nhập)
3. Chạy lại, đọc giá trị
4. Kỳ khác: số AUTO `NO_DATA`, số tay đã `ACCEPTED`, chạy tổng hợp

**Kết quả mong đợi.** Bước 1 chưa có số: `NO_DATA`, cờ `MANUAL_PENDING`. Bước 3 `value = 0`, `COMPLETE`. Bước 4 số tay thay số tự động vì tự động `NO_DATA` (BR-16-035). Số tự động không tự có hiệu lực khi chưa có xác nhận.

:::

### TS-16-09 · Kỳ báo cáo, chốt kỳ và mở lại kỳ

**Mục tiêu.** Tạo kỳ đúng mẫu; chốt kỳ khi đủ điều kiện; mở lại có lý do và đánh cờ đính chính.

**Phủ.** FR-16-017, 024; UC-16-09.

#### TC-16-035 · Tạo kỳ tháng, quý, năm và xem lịch kỳ <!--k:per-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-017 · API-16-047, 046, 048 · UI-16-08 · BR-16-013.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; `16.period.types = MONTH,QUARTER,YEAR`; ngày hiện tại 2026-11-05.

**Các bước.**

1. `POST /periods` `{periodCode: M-2026-11}`
2. `POST /periods` `{periodCode: Q-2026-Q4}`
3. `POST /periods` `{periodCode: Y-2026}`
4. `GET /periods?periodType=MONTH&year=2026&page=0&size=12`
5. `GET /periods/M-2026-11`

**Kết quả mong đợi.** Ba lần tạo `201`; `state = OPEN`, `startDate`, `endDate` đúng (`M-2026-11`: 2026-11-01…2026-11-30; `Q-2026-Q4`: 2026-10-01…2026-12-31), `closeDueDate = 2026-12-05` cho kỳ tháng 11 (`16.period.close-day = 5`). Danh sách trả đủ kỳ.

:::

#### TC-16-036 · Mã kỳ sai mẫu, trùng, ở tương lai <!--k:per-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-017 · API-16-047 · ERR-16-024.

**Tiền điều kiện, dữ liệu.** Kỳ `M-2026-11` đã có; ngày hiện tại 2026-11-05.

**Các bước.**

1. `POST /periods` `{periodCode: M-2026-13}`
2. `POST /periods` `{periodCode: M-2026-11}`
3. `POST /periods` `{periodCode: M-2027-06}`
4. `POST /periods` `{periodCode: "T-2026-10"}`

**Kết quả mong đợi.** Cả bốn `422` ERR-16-024 (sai mẫu, trùng, tương lai, sai loại); không tạo kỳ.

**Thông báo hiển thị.** ERR-16-024: "Kỳ M-2026-13 không hợp lệ hoặc đã có. Mã kỳ có dạng M-2026-10, Q-2026-Q3, Y-2026."

:::

#### TC-16-037 · Chốt kỳ khi đủ điều kiện <!--k:per-close-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-024, FR-16-017 · API-16-057, 048 · UI-16-08 · EVT-16-14 · BR-16-011, BR-16-030.

**Tiền điều kiện, dữ liệu.** T90; kỳ `M-2026-10` đã tổng hợp `PARTIAL` (F-KY-1), không còn số tay `SUBMITTED`, không quan sát mới chưa tính; U-T90-TA1.

**Các bước.**

1. `POST /periods/M-2026-10:close` thân `{confirmPartial: true}` kèm `If-Match`
2. `GET /periods/M-2026-10`
3. Đẩy một quan sát mới `periodEnd = 2026-10-31`
4. Đặt `clock-sim` 2026-12-05 03:00 với `16.period.auto-close = true`: kỳ `M-2026-11` đủ điều kiện, kỳ `Q-2026-Q3` còn số tay `SUBMITTED`

**Kết quả mong đợi.** Bước 1 `200`, `state = CLOSED`, `closedBy`, `closedAt`, `officialRunId` trỏ lần tổng hợp chính thức, nhãn `PARTIAL` giữ trên số chốt. Bước 3 quan sát ghi `late = true`, không tính (ERR-16-104). EVT: `period.state-changed` (EVT-16-14, `CLOSED`, kèm `officialRunId`) tới PH-13, PH-17, PH-18. Bước 4 hệ thống tự chốt `M-2026-11`; `Q-2026-Q3` giữ nguyên và PH-18 nhận việc cho TA "Kỳ Q-2026-Q3 chưa chốt được" kèm lý do ERR-16-025.

:::

#### TC-16-038 · Chốt chưa đủ điều kiện, mở lại sai <!--k:per-close-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-024 · API-16-057, 058 · ERR-16-025, ERR-16-026, ERR-16-007.

**Tiền điều kiện, dữ liệu.** Kỳ `M-2026-11` còn 2 số tay `SUBMITTED`; kỳ `M-2026-10` `CLOSED` và báo cáo `bc-thang-2026-10` `IN_REVIEW`; U-T90-TA1.

**Các bước.**

1. `POST /periods/M-2026-11:close`
2. `POST /periods/M-2026-10:reopen` `{reason: "Sửa số liệu nguồn PH-13"}` (dưới 50 ký tự)
3. `POST /periods/M-2026-10:reopen` với `reason` 60 ký tự khi báo cáo đang `IN_REVIEW`
4. U-T90-TO1 (có `PERM-16-run`) `POST /periods/M-2026-11:close` và `POST /periods/M-2026-10:reopen`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-025 kèm lý do "còn 2 số liệu tay chờ xác nhận". Bước 2 `422` ERR-16-007. Bước 3 `409` ERR-16-026. Bước 4 `403` ERR-00-403 (TO chạy tổng hợp, tính lại nhưng không chốt, không mở lại kỳ, FRS mục 3.2). Kỳ vẫn `CLOSED`.

**Thông báo hiển thị.** ERR-16-025: "Chưa chốt được kỳ M-2026-11: còn 2 số liệu tay chờ xác nhận."; ERR-16-007: "Nhập lý do mở lại (tối thiểu 50 ký tự)."; ERR-16-026: "Kỳ M-2026-10 có báo cáo đang duyệt. Trả báo cáo về nháp trước khi mở lại kỳ."

:::

#### TC-16-039 · Mở lại kỳ, chốt lại và cờ cần đính chính <!--k:per-reopen-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-024, FR-16-030 · API-16-058, 057, 066 · UI-16-08, UI-16-10 · EVT-16-14 · BR-16-011.

**Tiền điều kiện, dữ liệu.** T90; kỳ `M-2026-09` `CLOSED`, báo cáo `bc-thang-2026-09` `PUBLISHED`, chỉ tiêu `httt-ket-noi-ty-le` = 70; U-T90-TA1.

**Các bước.**

1. `POST /periods/M-2026-09:reopen` `{reason: <60 ký tự>, indicatorCodes: [httt-ket-noi-ty-le]}`
2. Nhập quan sát sửa `ph01.httt.connected` từ 140 thành 150 (số trễ)
3. `POST /periods/M-2026-09/runs`, rồi `POST /periods/M-2026-09:close`
4. `GET /reports/bc-thang-2026-09`

**Kết quả mong đợi.** Bước 1 `200`, `state = REOPENED`, `reopenReason`, EVT-16-14 (`REOPENED`, kèm lý do). Bước 3 giá trị mới 75 khác 70, kỳ `CLOSED` lại. Bước 4 `needsCorrection = true`; bản `PUBLISHED` không đổi nội dung (BR-16-009).

:::

### TS-16-10 · Chạy tổng hợp theo lịch hoặc thủ công và tính lại

**Mục tiêu.** Lần tổng hợp theo lịch, thủ công, hủy; tính lại khi có số trễ hoặc đổi công thức.

**Phủ.** FR-16-018, 023; UC-16-10.

#### TC-16-040 · Chạy tổng hợp thủ công và theo dõi lần chạy <!--k:run-manual-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-018 · API-16-050, 051, 049, 053 · UI-16-08, UI-16-09 · EVT-16-05 · BR-16-030.

**Tiền điều kiện, dữ liệu.** T90; kỳ `M-2026-10` `COLLECTING`, dữ liệu F-KY-1; U-T90-TO1.

**Các bước.**

1. `POST /periods/M-2026-10/runs` `{trigger: MANUAL, reason: "Tổng hợp thử"}` khóa idempotent `tc-run-1`
2. `GET /runs/{runId}` đến khi kết thúc
3. `GET /runs?periodCode=M-2026-10&state=PARTIAL`

**Kết quả mong đợi.** Bước 1 `202`, `runId`, `state = QUEUED`, `trigger = MANUAL`. Bước 2 `RUNNING` rồi `PARTIAL`, `completeness = 0,833333`, `counts = {indicatorTotal: 24, indicatorComputed: 20, noData: 4}`, `flags` gồm `MISSING_SOURCE`, `MANUAL_PENDING`. Bước 3 có lần này. EVT: `period.computed` (EVT-16-05) kèm `completeness`, `flags`. Tổng hợp xong ≤ 5 phút (NFR-16-001).

:::

#### TC-16-041 · Chạy kỳ đã chốt, đang chạy, quá thời gian; hủy lần chạy <!--k:run-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-018 · API-16-050, 051, 052 · ERR-16-022, ERR-16-023, ERR-16-110, ERR-16-007 · BR-16-030 · NFR-16-001.

**Tiền điều kiện, dữ liệu.** Kỳ `M-2026-09` `CLOSED`; kỳ `M-2026-11` đang có lần chạy `RUNNING`; T92 với `16.aggregate.timeout-minutes = 5` (trần thấp), nguồn giả làm chậm.

**Các bước.**

1. `POST /periods/M-2026-09/runs`
2. `POST /periods/M-2026-11/runs` khi đang chạy
3. Chạy kỳ ở T92 với công thức giả chậm quá 5 phút
4. `POST /runs/{runId}:cancel` thiếu lý do, rồi với lý do 25 ký tự khi lần chạy `RUNNING`

**Kết quả mong đợi.** Bước 1 `409` ERR-16-022. Bước 2 `409` ERR-16-023. Bước 3 lần chạy `FAILED`, `errorCode = ERR-16-110`, kết quả lần trước giữ nguyên (không ghi đè, BR-16-030), thông báo tới PH-13. Bước 4 thiếu lý do `422` ERR-16-007; có lý do `200`, `CANCELLED`, kết quả lần trước còn.

**Thông báo hiển thị.** ERR-16-023: "Kỳ M-2026-11 đang được tổng hợp (bắt đầu 2026-11-26 01:30). Chờ lần này xong."; ERR-16-110: "Lần tổng hợp vượt 5 phút và đã dừng. Kết quả lần trước được giữ."

:::

#### TC-16-042 · Số liệu trễ tự tính lại sau cửa sổ gom <!--k:recompute-late-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-023 · API-16-055, 069 · UI-16-09 · NFR-16-002 · BR-16-011 · EVT-16-05.

**Tiền điều kiện, dữ liệu.** T90; kỳ `M-2026-10` chưa chốt đã tổng hợp; `16.late-data.recompute = true`, `16.late-data.debounce-minutes = 5`; báo cáo `bc-thang-2026-10` `DRAFT`.

**Các bước.**

1. Đẩy ba quan sát trễ trong 2 phút
2. Quan sát kết quả sau 10 phút
3. `GET /runs?periodCode=M-2026-10&trigger=LATE_DATA`
4. `GET /reports/bc-thang-2026-10`

**Kết quả mong đợi.** Chỉ một lần chạy `trigger = LATE_DATA` sau cửa sổ 5 phút (gom ba yêu cầu); giá trị mới hiển thị ≤ 10 phút từ khi nhận quan sát. Báo cáo `DRAFT` hiện dải "Số liệu kỳ đã được tính lại" và có thể `:refresh`. EVT: `period.computed`.

:::

#### TC-16-043 · Tính lại kỳ đã chốt hoặc đã tắt tự tính lại <!--k:recompute-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-023 · API-16-055 · ERR-16-022, ERR-16-023, ERR-16-007.

**Tiền điều kiện, dữ liệu.** Kỳ `M-2026-09` `CLOSED`; tenant T92 `16.late-data.recompute = false`.

**Các bước.**

1. `POST /periods/M-2026-09:recompute` `{reason: <25 ký tự>}`
2. `POST /periods/M-2026-10:recompute` khi có lần chạy `RUNNING`
3. `POST /periods/M-2026-10:recompute` với `reason` ngắn
4. Ở T92 đẩy quan sát trễ rồi `GET /periods/M-2026-10`

**Kết quả mong đợi.** Bước 1 `409` ERR-16-022. Bước 2 `409` ERR-16-023. Bước 3 `422` ERR-16-007. Bước 4 không tạo lần chạy; quan sát được ghi; UI-16-08 báo "Có 1 số liệu mới chưa tính".

:::

#### TC-16-044 · Đổi công thức rồi tính lại; kỳ đã chốt giữ phiên bản cũ <!--k:recompute-formula-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-023, FR-16-019 · API-16-055, 053, 054 · BR-16-002, BR-16-033.

**Tiền điều kiện, dữ liệu.** `httt-ket-noi-ty-le` phiên bản 1 `ACTIVE` (`effectiveFrom = 2026-01-01`); phiên bản 2 đổi công thức làm tròn `ACTIVE` với `effectiveFrom = 2026-11-01`; kỳ `M-2026-10` chưa chốt, `M-2026-09` đã chốt.

**Các bước.**

1. `POST /periods/M-2026-10:recompute` `{reason: <25 ký tự>, indicatorCodes: [httt-ket-noi-ty-le]}`
2. `GET /runs/{runId}/values?indicatorCode=httt-ket-noi-ty-le`
3. `GET /values/{valueId}/lineage`
4. `GET /periods/M-2026-09` rồi đọc giá trị kỳ này

**Kết quả mong đợi.** Kỳ `M-2026-10` (`effectiveFrom` ≤ ngày cuối kỳ) tính bằng phiên bản 2: `versionUsed = 2`, `lineage.formula` là công thức mới, `inputs[]` đủ biến. Kỳ `M-2026-09` giữ `versionUsed = 1` và số đã chốt không đổi (BR-16-033).

:::

### TS-16-11 · Tính giá trị, độ đầy đủ, trạng thái và điểm nhóm

**Mục tiêu.** Công thức đúng theo phiên bản hiệu lực, gộp theo kỳ, fail-soft khi thiếu nguồn, trạng thái theo ngưỡng, điểm nhóm và điểm tổng đúng bảng 2.4.

**Phủ.** FR-16-019, 020, 021, 022; UC-16-11.

#### TC-16-045 · Tính giá trị chỉ tiêu bằng công thức CEL và lưu dòng truy nguồn <!--k:calc-value-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** FR-16-019 · API-16-053, 054, 043 · UI-16-09 · BR-16-001, BR-16-002, BR-16-034.

**Tiền điều kiện, dữ liệu.** T90; `httt-ket-noi-ty-le` bản 1 `ACTIVE`; quan sát kỳ `M-2026-10`: `ph01.httt.connected` = 150, `ph01.httt.total` = 200.

**Các bước.**

1. Chạy tổng hợp `M-2026-10`
2. `GET /runs/{runId}/values?indicatorCode=httt-ket-noi-ty-le`
3. `GET /values/{valueId}/lineage`
4. Chạy tổng hợp `Q-2026-Q3` cho chỉ tiêu thử có tháng 70, 75, 80

**Kết quả mong đợi.** `value = 75`, `displayValue` theo `decimals`, `versionUsed = 1`, `status = AT_RISK`, `threshold = AMBER`. `lineage.formula` là công thức đang hiệu lực, `inputs[]` có hai phần tử với `observationId` thật và `value` 150, 200 (BR-16-001). Giá trị lưu đủ 6 chữ số thập phân. Quý gộp từ giá trị tháng con (không đọc lại quan sát): `AVG` 75, `SUM` 225, `MAX` 80, `MIN` 70, `LAST` 80.

:::

#### TC-16-046 · Nhiều nguồn cùng chỉ số: lấy nguồn ưu tiên cao nhất <!--k:calc-priority-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-019 · API-16-054, 043 · BR-16-014.

**Tiền điều kiện, dữ liệu.** T90; hai nguồn cùng `ph13.dataplane.availability` kỳ `M-2026-10`: `src-ph13` `priority = 1` giá trị 99,5, `tc-nguon-phu` `priority = 2` giá trị 98,0; `src-ph13` có hai quan sát, nhận lúc 08:00 giá trị 99,4 và lúc 09:00 giá trị 99,5.

**Các bước.**

1. Chạy tổng hợp
2. `GET /values/{valueId}/lineage` của `san-sang-data-plane`
3. Tạm dừng `src-ph13` rồi chạy lại

**Kết quả mong đợi.** Bước 2 dùng 99,5 (nguồn `priority` cao nhất, quan sát mới nhất theo `receivedAt`). Bước 3 khi `src-ph13` `PAUSED` thì lấy 98,0 từ nguồn kế tiếp có số. Dòng truy nguồn ghi đúng `observationId` được chọn.

:::

#### TC-16-047 · Công thức lỗi khi tính: chia cho 0 <!--k:calc-formula-err-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** FR-16-019, FR-16-020 · API-16-053 · ERR-16-109 · BR-16-007.

**Tiền điều kiện, dữ liệu.** T90; kỳ có `ph01.httt.total` = 0; các chỉ tiêu khác bình thường.

**Các bước.**

1. Chạy tổng hợp
2. `GET /runs/{runId}/values?status=NO_DATA`
3. `GET /runs/{runId}`

**Kết quả mong đợi.** `httt-ket-noi-ty-le` có `value` trống, `completeness = NO_DATA`, `flags` có `FORMULA_ERROR`; không điền 0. 23 chỉ tiêu còn lại vẫn tính. Lần chạy `PARTIAL`, `errorCode` trống (lỗi theo chỉ tiêu).

**Thông báo hiển thị.** ERR-16-109: "Chỉ tiêu httt-ket-noi-ty-le: công thức lỗi khi tính (chia cho 0). Giá trị để trống."

:::

#### TC-16-048 · Thiếu nguồn: PARTIAL, cờ, không bịa số <!--k:calc-partial-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-020 · API-16-051, 053, 048 · ERR-16-111, ERR-16-112, ERR-16-107 · BR-16-007, BR-16-030 · UI-16-09.

**Tiền điều kiện, dữ liệu.** T94; kỳ `M-2026-10`; nguồn PH-13 `FAILED` (5 chỉ tiêu dùng riêng PH-13: `san-sang-data-plane`, `tre-gateway-p95`, `nhat-ky-khai-thac-du`, `mttd`, `mttr-muc-1`); 1 chỉ tiêu có số tay `SUBMITTED`; kỳ trước có số.

**Các bước.**

1. Chạy tổng hợp
2. `GET /runs/{runId}`
3. `GET /runs/{runId}/values?completeness=NO_DATA`
4. `GET /periods/M-2026-10`

**Kết quả mong đợi.** Lần chạy `PARTIAL`, `completeness` = (24 − 6) / 24 = `0,75` với 6 chỉ tiêu `NO_DATA` (5 của PH-13 và 1 chờ xác nhận tay), `flags` gồm `MISSING_SOURCE`, `STALE_SOURCE`, `MANUAL_PENDING`. Chỉ tiêu `NO_DATA` có `missingMetrics` đủ, không nội suy, không lấy số kỳ trước, không bằng 0 (BR-16-007). Kỳ báo `completeness` và cờ.

**Thông báo hiển thị.** ERR-16-111: "Thiếu số liệu từ src-ph13 cho kỳ M-2026-10."; ERR-16-112: "Chỉ tiêu ket-noi-diem-diem-con-lai chờ xác nhận số liệu tay."

:::

#### TC-16-049 · Trạng thái theo ngưỡng ba mức, hai chiều tốt, làm tròn <!--k:calc-status-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** FR-16-021, FR-16-019 · API-16-053 · BR-16-015, BR-16-034 · UI-16-01, UI-16-02.

**Tiền điều kiện, dữ liệu.** `httt-ket-noi-ty-le` (HIGHER_BETTER, `greenFrom` 90, `amberFrom` 70); `tre-gateway-p95` (LOWER_BETTER, 200, 300, đơn vị ms); chỉ tiêu `RELATIVE_TO_BASELINE` `baseline` 60, mục tiêu +50 %.

**Các bước.**

1. Đặt giá trị 95, 90, 89,99, 70, 69,99 cho chỉ tiêu thứ nhất và đọc `status`, `threshold`
2. Đặt 150, 200, 250, 300, 350 cho `tre-gateway-p95`
3. Chỉ tiêu `NO_DATA`
4. Chỉ tiêu `decimals = 0`, `greenFrom` 90 nhận 89,96; chỉ tiêu khác nhận 2 trên 3 nhân 100

**Kết quả mong đợi.** Chỉ tiêu thứ nhất: 95 → `ON_TRACK`/`GREEN`; 90 → `ON_TRACK`; 89,99 → `AT_RISK`/`AMBER`; 70 → `AT_RISK`; 69,99 → `OFF_TRACK`/`RED`. `tre-gateway-p95`: 150, 200 → `ON_TRACK`; 250, 300 → `AT_RISK`; 350 → `OFF_TRACK`. Chỉ tiêu tương đối quy đổi ngưỡng từ giá trị nền trước khi so. `NO_DATA` giữ `NO_DATA`. Bước 4 `value = 89,96`, `displayValue = "90"`, `status = AT_RISK` (so trên giá trị chưa làm tròn); chỉ tiêu kia `value = 66,666667` (6 chữ số thập phân).

:::

#### TC-16-050 · Sự kiện chệch chỉ phát khi trạng thái đổi; đổi ngưỡng không đổi kỳ đã chốt <!--k:calc-status-event-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-021 · API-16-056 · EVT-16-06 · BR-16-017, BR-16-033.

**Tiền điều kiện, dữ liệu.** T90; `httt-ket-noi-ty-le` kỳ `M-2026-10` đang `ON_TRACK` ở lần chạy trước (giá trị 95).

**Các bước.**

1. Đẩy số trễ làm giá trị còn 75, chạy lại
2. Chạy lại lần nữa với dữ liệu không đổi
3. Đẩy số làm giá trị còn 95, chạy lại
4. Đẩy số làm chỉ tiêu `NO_DATA`
5. `GET /periods/M-2026-10/status-changes`
6. Duyệt bản mới của chỉ tiêu đổi `thresholds`, đọc lại giá trị kỳ `M-2026-09` đã chốt

**Kết quả mong đợi.** Lần 1 phát một EVT-16-06 (`ON_TRACK` → `AT_RISK`). Lần 2 không phát (BR-16-017). Lần 3 phát một (về `ON_TRACK`). Lần 4 không phát EVT-16-06 (chuyển `NO_DATA` dựa cảnh báo nguồn). `status-changes` có đúng các thay đổi, `from`, `to`, `runId`, `at`. Bước 6 trạng thái và điểm của kỳ đã chốt không đổi (BR-16-033).

:::

#### TC-16-051 · Điểm nhóm, điểm tổng, xu hướng và chênh lệch <!--k:calc-group-score-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** FR-16-022, FR-16-007 · API-16-090 · UI-16-01 · BR-16-016.

**Tiền điều kiện, dữ liệu.** T90; F-KY-1 (bảng 2.4); trọng số 30/20/20/15/15; `M-2026-09` có `overallScore` 60,00.

**Các bước.**

1. `GET /dashboard?periodCode=M-2026-10&view=LATEST`
2. `GET /dashboard?periodCode=M-2026-10&compareTo=M-2026-09`

**Kết quả mong đợi.** `groups[]`: `KET_NOI` 50,00, `CHIA_SE` 100,00, `DU_LIEU` 75,00, `VAN_HANH` 60,00, `KIEN_TRUC` 50,00 (`NO_DATA` bị loại khỏi trung bình), `coverage` mỗi nhóm = số chỉ tiêu có số / tổng (ví dụ `KET_NOI` 0,75). `overallScore = 66,5`. `statusCounts = {ON_TRACK: 12, AT_RISK: 5, OFF_TRACK: 3, NO_DATA: 4}`. So kỳ trước `delta = +6,5`, `trend = UP`.

:::

### TS-16-12 · Quản lý mẫu báo cáo

**Mục tiêu.** Tạo, sửa có phiên bản, xem thử mẫu báo cáo; từ chối mẫu không hợp lệ.

**Phủ.** FR-16-025; UC-16-12.

#### TC-16-052 · Tạo mẫu báo cáo, sửa có phiên bản và xem thử <!--k:tpl-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-025 · API-16-060, 062, 063, 059, 061 · UI-16-13 · BR-16-027.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; kỳ `M-2026-10` đã tính.

**Các bước.**

1. `POST /report-templates` `{templateCode: tc-thang-ngan, name: "Báo cáo tháng ngắn", reportType: PERIODIC, periodTypes: [MONTH], sections: [{type: SUMMARY}, {type: GROUP, groupCode: KET_NOI}, {type: INDICATOR_TABLE, indicatorCodes: [httt-ket-noi-ty-le, mttd]}, {type: CHART, chartType: "line"}, {type: NARRATIVE}], formats: [PDF, XLSX], letterhead: {issuer: "UBND tỉnh T90", formNo: "BC-CT/01", recipients: "Bộ Khoa học và Công nghệ"}}`
2. `POST /report-templates/tc-thang-ngan:preview` `{periodCode: M-2026-10}`
3. `PATCH /report-templates/tc-thang-ngan` thêm phần `ANNEX` kèm `If-Match`
4. `GET /report-templates/tc-thang-ngan`

**Kết quả mong đợi.** Bước 1 `201`, `state = ACTIVE`, `version = 1`. Bước 2 `200`, `previewUrl`, `expiresAt`; bản xem thử có tên cơ quan, số ký hiệu, nơi nhận theo thể thức NĐ 30/2020. Bước 3 `version = 2`; báo cáo đã lập từ bản 1 giữ bố cục cũ.

:::

#### TC-16-053 · Mẫu không hợp lệ hoặc mã trùng <!--k:tpl-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-025 · API-16-060, 062, 063 · ERR-16-027, ERR-16-002.

**Tiền điều kiện, dữ liệu.** Mẫu `tc-thang-ngan` đã có.

**Các bước.**

1. `POST /report-templates` với phần `INDICATOR_TABLE` chứa `khong-co-ma`
2. `POST /report-templates` với `formats = []`
3. `POST /report-templates` lại `templateCode = tc-thang-ngan`
4. `POST …:preview` cho kỳ chưa tính
5. U-T90-TO1 `POST /report-templates`

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-16-027. Bước 3 `409` ERR-16-002. Bước 4 `422` ERR-16-027 hoặc xem thử với số trống. Bước 5 `403` ERR-00-403 (TO không có `PERM-16-admin`).

**Thông báo hiển thị.** ERR-16-027: "Mẫu chưa hợp lệ: sections[2] chỉ tiêu khong-co-ma không tồn tại."

:::

### TS-16-13 · Lập bản nháp, thuyết minh và báo cáo đột xuất

**Mục tiêu.** Lập bản nháp từ kỳ đã tính, viết giải trình, làm mới khi tính lại; báo cáo đột xuất theo khoảng.

**Phủ.** FR-16-026, 027, 032; UC-16-13.

#### TC-16-054 · Lập bản nháp báo cáo kỳ từ kết quả đã tính <!--k:rep-draft-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-026 · API-16-065, 066, 070 · UI-16-10, UI-16-11 · BR-16-008, BR-16-029.

**Tiền điều kiện, dữ liệu.** T90; kỳ `M-2026-10` `CLOSED` (F-KY-1); mẫu `tc-thang-ngan`; U-T90-TO1.

**Các bước.**

1. `POST /reports` `{reportCode: bc-thang-2026-10, templateCode: tc-thang-ngan, reportType: PERIODIC, periodCode: M-2026-10, title: "Báo cáo chỉ tiêu tháng 10/2026"}`
2. `GET /reports/bc-thang-2026-10`
3. `GET /reports/bc-thang-2026-10/preview`

**Kết quả mong đợi.** Bước 1 `201`, `state = DRAFT`, `latestVersion = 1`, `runId` là lần tổng hợp chính thức, `completeness = PARTIAL`. Bước 2 có `requiredExplanations` (chỉ tiêu `OFF_TRACK` và chỉ tiêu bắt buộc thiếu số) và `missingExplanations` bằng với nó. Bước 3 `previewUrl`, `provisional = false`.

:::

#### TC-16-055 · Lập báo cáo khi kỳ chưa tính hoặc mã sai <!--k:rep-draft-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-026 · API-16-065 · ERR-16-028, ERR-16-002, ERR-16-003.

**Tiền điều kiện, dữ liệu.** Kỳ `M-2026-12` `OPEN` chưa có lần tổng hợp; báo cáo `bc-thang-2026-10` đã có.

**Các bước.**

1. `POST /reports` `periodCode = M-2026-12`
2. `POST /reports` lại `reportCode = bc-thang-2026-10`
3. `POST /reports` với `reportCode = "BC_Thang"`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-028. Bước 2 `409` ERR-16-002. Bước 3 `400` ERR-16-003. Không tạo báo cáo.

**Thông báo hiển thị.** ERR-16-028: "Kỳ M-2026-12 chưa có kết quả tổng hợp hoặc chưa chốt. Hoàn tất trước khi lập hoặc gửi báo cáo."

:::

#### TC-16-056 · Viết thuyết minh, giải trình chỉ tiêu chệch; sửa báo cáo đã công bố <!--k:rep-explain-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-027 · API-16-067, 068, 066 · UI-16-11 · ERR-16-032, ERR-16-003 · BR-16-029.

**Tiền điều kiện, dữ liệu.** Báo cáo `bc-thang-2026-10` `DRAFT`; `missingExplanations` có 3 mã `OFF_TRACK`; U-T90-TO1.

**Các bước.**

1. `PATCH /reports/bc-thang-2026-10` cập nhật `sections` với `ReportSectionText` nội dung 500 ký tự, kèm `documentNumber = "125/BC-STTTT"` và `recipientsNote = "UBND tỉnh; Bộ KH&CN."` (kèm `If-Match`)
2. `PUT /reports/bc-thang-2026-10/explanations/{mã}` `{cause, action, dueDate}` cho một mã
3. Lặp lại cho cả ba mã
4. `GET /reports/bc-thang-2026-10`
5. `PATCH /reports/bc-thang-2026-09` và `PUT …/explanations/mttd` khi báo cáo `PUBLISHED`
6. `PUT` giải trình với `cause = ""`

**Kết quả mong đợi.** Bước 1 `200`, `documentNumber`, `recipientsNote` được lưu nguyên văn (tối đa 64 và 2.000 ký tự). Bước 2 `200`, `explanation`, `missingExplanations` còn 2. Sau bước 3 rỗng. Bước 4 `explanations[]` đủ ba. Bước 5 `409` ERR-16-032. Bước 6 `400` ERR-16-003.

**Thông báo hiển thị.** ERR-16-032: "Báo cáo đã công bố không sửa được. Dùng chức năng đính chính."

:::

#### TC-16-057 · Báo cáo đột xuất theo khoảng và tập chỉ tiêu tự chọn <!--k:rep-adhoc-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-16-032 · API-16-065, 070 · ERR-16-033 · BR-16-004.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; `16.report.four-eyes = true`.

**Các bước.**

1. `POST /reports` `{reportCode: bc-dot-xuat-q1-q3, reportType: AD_HOC, title: "Sơ kết 9 tháng", from: 2026-01-01, to: 2026-09-30, indicatorCodes: [httt-ket-noi-ty-le, mttd, api-cong-bo]}`
2. `POST /reports` với `from = 2024-01-01`, `to = 2026-09-30` (33 tháng)
3. `POST /reports` với `from = 2026-09-30`, `to = 2026-01-01`

**Kết quả mong đợi.** Bước 1 `201`, `reportType = AD_HOC`, `rangeFrom`, `rangeTo`, chỉ ba chỉ tiêu. Bước 2, 3 `422` ERR-16-033. Báo cáo đột xuất không được gửi quốc gia (xem TC-16-096).

**Thông báo hiển thị.** ERR-16-033: "Khoảng báo cáo từ 2024-01-01 đến 2026-09-30 không hợp lệ hoặc vượt 24 tháng."

:::

### TS-16-14 · Gửi duyệt và duyệt báo cáo bốn mắt

**Mục tiêu.** Báo cáo gửi duyệt khi đủ điều kiện, bốn mắt, yêu cầu sửa.

**Phủ.** FR-16-028; UC-16-14.

#### TC-16-058 · Gửi duyệt, duyệt bốn mắt <!--k:rep-submit-approve-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-028 · API-16-071, 072, 078 · UI-16-11, UI-16-12 · EVT-16-07 · BR-16-004.

**Tiền điều kiện, dữ liệu.** `bc-thang-2026-10` `DRAFT` đủ giải trình, đã có `documentNumber`, `recipientsNote` (rep-explain); U-T90-TO1 lập, U-T90-TA1 duyệt.

**Các bước.**

1. U-T90-TO1 `POST /reports/bc-thang-2026-10:submit` `{note: "Gửi duyệt"}`
2. U-T90-TA1 `GET /review-queue?itemType=REPORT`
3. U-T90-TA1 `POST /reports/bc-thang-2026-10:approve` kèm `If-Match`

**Kết quả mong đợi.** Bước 1 `200`, `state = IN_REVIEW`, `submittedBy = TO1`. EVT: `report.submitted` (EVT-16-07) tới PH-18. Bước 3 `200`, `state = APPROVED`, `reviewedBy = TA1`.

:::

#### TC-16-059 · Chỉ tiêu bắt buộc thiếu số hoặc thiếu giải trình <!--k:rep-submit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-028 · API-16-071 · ERR-16-029, ERR-16-030, ERR-16-061 · BR-16-008, BR-16-029.

**Tiền điều kiện, dữ liệu.** Báo cáo `PERIODIC` kỳ `M-2026-11` có `bi-mat-ngoai-kho` (bắt buộc) `NO_DATA` và 2 chỉ tiêu `OFF_TRACK` chưa giải trình; chỉ tiêu bắt buộc `ho-so-cap-do-phe-duyet` `PARTIAL` có giải trình.

**Các bước.**

1. `POST …:submit` khi có chỉ tiêu bắt buộc `NO_DATA`
2. Nhập số tay cho chỉ tiêu bắt buộc và xác nhận, tính lại, `POST …:submit` khi còn 2 chỉ tiêu chưa giải trình
3. Giải trình đủ nhưng báo cáo `PERIODIC` chưa có `documentNumber` và `recipientsNote`, `POST …:submit`
4. `PATCH` `documentNumber = "125/BC-STTTT"`, `recipientsNote = "UBND tỉnh; Bộ KH&CN."` rồi `POST …:submit`; thử thêm báo cáo `AD_HOC` không có hai trường

**Kết quả mong đợi.** Bước 1 `422` ERR-16-029, nêu danh sách chỉ tiêu. Bước 2 `422` ERR-16-030. Bước 3 `422` ERR-16-061, `errors[]` trỏ `documentNumber`, `recipientsNote`. Bước 4 `200` (chỉ tiêu bắt buộc `PARTIAL` được phép khi có giải trình); báo cáo `AD_HOC` gửi duyệt được mà không cần hai trường (BR-16-027). Báo cáo `AD_HOC` không bị chặn bởi ERR-16-029.

**Thông báo hiển thị.** ERR-16-029: "Chỉ tiêu bắt buộc bi-mat-ngoai-kho chưa có số liệu. Báo cáo chính thức chưa gửi duyệt được."; ERR-16-030: "Còn 2 chỉ tiêu chệch hoặc thiếu số chưa có giải trình."; ERR-16-061: "Báo cáo chính thức cần số ký hiệu và nơi nhận trước khi gửi duyệt."

:::

#### TC-16-060 · Người lập hoặc người gửi không tự duyệt; ngoại lệ báo cáo đột xuất <!--k:rep-four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-028 · API-16-072, 073 · ERR-16-005, ERR-16-007 · BR-16-004.

**Tiền điều kiện, dữ liệu.** Báo cáo `IN_REVIEW` do U-T90-TO1 lập, U-T90-TA3 gửi; U-T90-TA3 có đủ quyền; báo cáo `AD_HOC` ở T92 với `16.report.four-eyes = false`.

**Các bước.**

1. U-T90-TA3 `POST …:approve` bản mình gửi
2. U-T90-TO1 `POST …:approve`
3. Ở T92 người lập báo cáo `AD_HOC` tự `:approve`
4. Ở T92 người lập báo cáo `PERIODIC` tự `:approve` khi `four-eyes = false`

**Kết quả mong đợi.** Bước 1 `403` ERR-16-005 (người gửi). Bước 2 `403` ERR-00-403 (TO không có `PERM-16-approve`). Bước 3 `200` (chỉ `AD_HOC` được miễn bốn mắt). Bước 4 `403` ERR-16-005 (tham số không áp cho `PERIODIC`).

**Thông báo hiển thị.** ERR-16-005: "Anh/chị là người lập hoặc gửi nên không được tự duyệt."

:::

#### TC-16-061 · Yêu cầu sửa, sửa lại và gửi lại <!--k:rep-changes-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-028 · API-16-073, 071 · ERR-16-007 · EVT-16-09 · UI-16-12.

**Tiền điều kiện, dữ liệu.** Báo cáo `IN_REVIEW` (hoặc `APPROVED`) do TO1 lập; U-T90-TA1 duyệt.

**Các bước.**

1. U-T90-TA1 `POST …:request-changes` với `comment` 5 ký tự
2. `POST …:request-changes` với `comment` 30 ký tự (≥ 20)
3. U-T90-TO1 sửa thuyết minh, `:submit` lại
4. U-T90-TA1 `:request-changes` bản `APPROVED`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-007. Bước 2 `state = CHANGES_REQUESTED`, EVT: `report.state-changed` (EVT-16-09). Bước 3 về `IN_REVIEW`, `latestVersion` tăng. Bước 4 báo cáo `APPROVED` chuyển `CHANGES_REQUESTED` ("Trả về soạn"), phát EVT-16-09, có kiểm toán ý kiến.

:::

### TS-16-15 · Công bố báo cáo chính thức

**Mục tiêu.** Công bố chụp bất biến, ký số, lưu WORM; lỗi ký, lưu, dựng PDF không làm báo cáo thành PUBLISHED; không sửa được báo cáo đã công bố.

**Phủ.** FR-16-029; UC-16-15.

#### TC-16-062 · Công bố: chụp, PDF theo thể thức, ký số, lưu WORM <!--k:pub-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-029 · API-16-074, 066, 088 · UI-16-12 · EVT-16-08 · BR-16-009, BR-16-010, BR-16-027 · NFR-16-009.

**Tiền điều kiện, dữ liệu.** `bc-thang-2026-10` `APPROVED` (người lập TO1, người duyệt TA1); U-T90-TA2 công bố; `sign-sim` và `worm-sim` thành công; `16.report.signing = true`.

**Các bước.**

1. U-T90-TA2 `POST /reports/bc-thang-2026-10:publish` `{publishNote: "Công bố kỳ tháng 10"}` kèm `If-Match`
2. `GET /reports/bc-thang-2026-10`
3. `GET /reports/bc-thang-2026-10/evidence`

**Kết quả mong đợi.** Bước 1 `200`, `state = PUBLISHED`, `publishedVersion = 1`, `publishedAt`, `contentHash` 64 ký tự hex, `signature = {signer, signedAt, certificateSerial, format}`, `wormRef`. Bước 3 `verified = true`, `downloadUrl`. PDF có tên cơ quan, số ký hiệu, nơi nhận, chữ ký số (NĐ 30/2020). Bản lưu WORM giữ ≥ 10 năm. EVT: `report.published` (EVT-16-08) tới PH-13, PH-17 và kích hoạt phân phối (xem TC-16-073).

:::

#### TC-16-063 · Người lập công bố, kỳ bị mở lại, thiếu If-Match <!--k:pub-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-029 · API-16-074 · ERR-16-005, ERR-16-006, ERR-00-428 · BR-16-004.

**Tiền điều kiện, dữ liệu.** Báo cáo `APPROVED` do U-T90-TO1 lập; U-T90-TA3 là người gửi; kỳ báo cáo bị mở lại sau duyệt (REOPENED).

**Các bước.**

1. U-T90-TA3 `POST …:publish`
2. U-T90-TA2 `POST …:publish` khi kỳ `REOPENED`
3. U-T90-TA2 `POST …:publish` không có `If-Match`

**Kết quả mong đợi.** Bước 1 `403` ERR-16-005. Bước 2 `409` ERR-16-006 (báo cáo không còn khớp lần tổng hợp chính thức). Bước 3 `428` ERR-00-428. Báo cáo vẫn `APPROVED`; không tệp nào ghi vào WORM; không EVT-16-08.

:::

#### TC-16-064 · Dịch vụ ký số không sẵn sàng rồi công bố lại <!--k:pub-sign-fail-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-029 · API-16-074 · ERR-16-031 · EVT-16-08.

**Tiền điều kiện, dữ liệu.** Báo cáo `APPROVED`; `sign-sim` trả `503`.

**Các bước.**

1. U-T90-TA2 `POST …:publish`
2. `GET /reports/{reportCode}`
3. Đưa `sign-sim` về `200`, `POST …:publish` lại

**Kết quả mong đợi.** Bước 1 `503` ERR-16-031. Bước 2 `state = APPROVED`, không `wormRef`, không EVT-16-08. Bước 3 `200 PUBLISHED`, đúng một EVT-16-08, một tệp ký.

**Thông báo hiển thị.** ERR-16-031: "Dịch vụ ký số đang gián đoạn. Báo cáo vẫn ở trạng thái Đã duyệt, thử công bố lại sau."

:::

#### TC-16-065 · Lưu WORM lỗi hoặc dựng PDF lỗi: không công bố <!--k:pub-store-fail-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-029 · API-16-074 · ERR-16-113, ERR-16-114 · UI-16-12.

**Tiền điều kiện, dữ liệu.** Hai báo cáo `APPROVED`; `worm-sim` trả lỗi ghi; bộ dựng PDF được làm lỗi bằng mẫu hỏng.

**Các bước.**

1. `POST …:publish` khi `worm-sim` lỗi
2. `POST …:publish` bản khác khi dựng PDF lỗi
3. Sửa lỗi, công bố lại cả hai

**Kết quả mong đợi.** Bước 1 báo lỗi ERR-16-114 (`5xx` hoặc `502`), báo cáo vẫn `APPROVED`, không `contentHash` công bố, không EVT-16-08, cảnh báo PH-13. Bước 2 ERR-16-113, báo cáo vẫn `APPROVED`. Bước 3 thành công, không tệp mồ côi nào ở kho (`worm-sim` chỉ có tệp của lần thành công).

**Thông báo hiển thị.** ERR-16-114: "Không lưu được bản công bố vào kho lưu trữ. Báo cáo chưa được công bố."; ERR-16-113: "Không dựng được tệp báo cáo: mẫu không hợp lệ."

:::

#### TC-16-066 · Báo cáo đã công bố bất biến <!--k:pub-immutable-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-029, FR-16-036 · API-16-067, 068, 069, 076, 088 · ERR-16-032, ERR-16-006, ERR-16-124 · BR-16-009, BR-16-010 · NFR-16-013.

**Tiền điều kiện, dữ liệu.** `bc-thang-2026-10` `PUBLISHED`; quyền DBA ở CSDL thử; `worm-sim`.

**Các bước.**

1. `PATCH /reports/bc-thang-2026-10`, `PUT …/explanations/mttd`, `POST …:refresh`
2. `POST …:submit`, `POST …:approve` trên báo cáo `PUBLISHED`
3. Ghi SQL trực tiếp bằng vai trò dịch vụ để đổi `contentHash`
4. Xóa hoặc ghi đè tệp ở `worm-sim` trước hạn
5. `GET …/evidence` rồi tính SHA-256 tệp tải về
6. Thay tệp ở `worm-sim` bằng tệp khác, chạy tác vụ kiểm băm, `GET …/evidence`

**Kết quả mong đợi.** Bước 1 `409` ERR-16-032 (hoặc ERR-16-006 cho `:refresh`). Bước 2 `409` ERR-16-006. Bước 3 bị chặn bởi trigger hoặc không có quyền ghi. Bước 4 từ chối (WORM). Bước 5 SHA-256 tệp khớp `contentHash` và chữ ký kiểm chứng được ngoài hệ thống; 0 lệnh sửa thành công (NFR-16-013). Bước 6 tác vụ ghi ERR-16-124, thông báo SO và PH-13, `verified = false`, báo cáo không bị tự sửa.

:::

### TS-16-16 · Đính chính và rút báo cáo đã công bố

**Mục tiêu.** Đính chính bằng phiên bản mới, bản cũ SUPERSEDED vẫn tra được; rút giữ nguyên tệp.

**Phủ.** FR-16-030; UC-16-16.

#### TC-16-067 · Đính chính báo cáo đã công bố bằng phiên bản mới; rút báo cáo <!--k:corr-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-030 · API-16-075, 077, 066 · UI-16-10 · API-16-076 · EVT-16-09, EVT-16-08 · BR-16-009.

**Tiền điều kiện, dữ liệu.** `bc-thang-2026-09` `PUBLISHED` phiên bản 1, `needsCorrection = true` (per-reopen); U-T90-TA1.

**Các bước.**

1. `POST /reports/bc-thang-2026-09:correct` `{reason: <60 ký tự>, correctionNote: "Sửa số kết nối HTTT từ 70 thành 75"}` khóa idempotent `tc-corr-1`
2. U-T90-TO1 duyệt lại và U-T90-TA2 công bố phiên bản 2
3. `GET /reports/bc-thang-2026-09/versions`
4. `POST /reports/bc-thang-2026-08:withdraw` `{reason: <40 ký tự>}` rồi `GET …/evidence`

**Kết quả mong đợi.** Bước 1 `201`, bản 2 `DRAFT` với `correctionOf = 1`, `correctionReason`. Sau bước 2 bản 2 `PUBLISHED`, bản 1 `SUPERSEDED` (vẫn tra được, `contentHash` bản 1 giữ nguyên); EVT: `report.state-changed` (SUPERSEDED) và `report.published`. Bước 3 liệt kê hai phiên bản, `needsCorrection` về `false`. Bước 4 `WITHDRAWN`, tệp ký và `contentHash` còn nguyên, EVT `report.state-changed`, không còn ở `/feed/reports`.

:::

#### TC-16-068 · Đính chính sai trạng thái, thiếu lý do <!--k:corr-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-030 · API-16-075, 076 · ERR-16-006, ERR-16-007, ERR-16-005.

**Tiền điều kiện, dữ liệu.** Báo cáo `bc-thang-2026-10-nhap` `DRAFT`; `bc-thang-2026-09` `PUBLISHED`; U-T90-TA1.

**Các bước.**

1. `POST /reports/bc-thang-2026-10-nhap:correct`
2. `POST /reports/bc-thang-2026-09:correct` với `reason` 10 ký tự
3. `POST /reports/bc-thang-2026-10-nhap:withdraw`
4. `POST /reports/bc-thang-2026-09:withdraw` không có `reason`

**Kết quả mong đợi.** Bước 1, 3 `409` ERR-16-006 (báo cáo chưa công bố). Bước 2, 4 `422` ERR-16-007 (hoặc `400` ERR-16-003 theo lược đồ). Không đổi dữ liệu.

**Thông báo hiển thị.** ERR-16-006: "Không thể thực hiện khi báo cáo đang ở trạng thái DRAFT."

:::

### TS-16-17 · Tra cứu báo cáo và tải bằng chứng công bố

**Mục tiêu.** Liệt kê, xem báo cáo và lịch sử phiên bản theo quyền; tải bằng chứng kiểm chứng được.

**Phủ.** FR-16-031, 036; UC-16-17.

#### TC-16-069 · Liệt kê, tìm, xem báo cáo và lịch sử phiên bản theo quyền <!--k:rep-list-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-031 · API-16-064, 066, 077 · UI-16-10 · ERR-16-057, ERR-16-001.

**Tiền điều kiện, dữ liệu.** T90: `bc-thang-2026-09` `PUBLISHED`, `bc-thang-2026-10` `DRAFT`; T91 có `bc-thang-2026-10`; U-T90-VW, U-T90-TO1.

**Các bước.**

1. U-T90-TO1 `GET /reports?state=DRAFT&reportType=PERIODIC&periodCode=M-2026-10`
2. U-T90-VW `GET /reports`
3. U-T90-VW `GET /reports/bc-thang-2026-10`
4. U-T90-TO1 `GET /reports?state=XYZ`
5. U-T91-TO1 `GET /reports/bc-thang-2026-10` của T90

**Kết quả mong đợi.** Bước 1 trả bản nháp kèm người lập, `latestVersion`. Bước 2 VW chỉ thấy báo cáo đã công bố (`PUBLISHED`, `SUPERSEDED`; không thấy `WITHDRAWN`, chỉ TA và AU thấy theo FR-16-031), kèm `needsCorrection`. Bước 3 `404` ERR-16-001 (VW không thấy bản nháp, 404-ẩn). Bước 4 `400` ERR-16-057. Bước 5 `404` ERR-16-001 theo tenant.

:::

#### TC-16-070 · Tải bằng chứng công bố và kiểm chứng ngoài hệ thống <!--k:rep-evidence-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-036 · API-16-088, 077 · UI-16-10 · BR-16-010.

**Tiền điều kiện, dữ liệu.** `bc-thang-2026-09` `PUBLISHED`; U-T90-AU.

**Các bước.**

1. `GET /reports/bc-thang-2026-09/evidence?version=1`
2. Tải `downloadUrl`, tính SHA-256 và kiểm chữ ký bằng công cụ ngoài
3. `GET /reports/bc-thang-2026-10/evidence` (bản nháp)

**Kết quả mong đợi.** Bước 1 `200`, `verified = true`, `contentHash`, `signature`, `downloadUrl`, `expiresAt`. Bước 2 SHA-256 khớp `contentHash`, chữ ký hợp lệ. Bước 3 `404` ERR-16-001 hoặc không có bằng chứng (báo cáo chưa công bố). KT: có (report.evidence.read) vì là truy cập bằng chứng.

:::

### TS-16-18 · Xuất báo cáo và phân phối theo danh sách

**Mục tiêu.** Xuất PDF, XLSX, CSV, JSON; liên kết hết hạn; phân phối khi công bố, gửi lỗi được ghi.

**Phủ.** FR-16-033, 034; UC-16-18.

#### TC-16-071 · Xuất báo cáo và bảng chỉ tiêu ra bốn định dạng <!--k:exp-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-033 · API-16-079, 080, 081 · UI-16-10 · EVT-16-13 · BR-16-026, BR-16-027 · NFR-16-010.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1; `bc-thang-2026-09` `PUBLISHED`; kỳ `M-2026-10` đã tính.

**Các bước.**

1. `POST /exports` `{subject: REPORT, subjectRef: {reportCode: bc-thang-2026-09, version: 1}, format: PDF}`
2. `POST /exports` `{subject: INDICATOR_VALUES, subjectRef: {periodCode: M-2026-10}, format: XLSX}`
3. Tương tự `CSV` và `JSON`
4. `GET /exports/{exportId}` đến khi `SUCCEEDED`
5. `GET /exports/{exportId}/file`

**Kết quả mong đợi.** Bước 1, 2 `202`, `state = QUEUED`. Bước 4 `SUCCEEDED`, `rowCount`, `sha256`, `downloadUrl`, `expiresAt` = lúc tạo + 24 giờ. Bước 5 `200` tệp đúng định dạng; PDF theo thể thức NĐ 30/2020. EVT: `export.completed` (EVT-16-13) tới người yêu cầu. Chỉ báo cáo `PUBLISHED` được xuất ra ngoài phân hệ.

:::

#### TC-16-072 · Xuất vượt giới hạn dòng, liên kết hết hạn, đối tượng ngoài quyền <!--k:exp-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-033 · API-16-079, 080, 081 · ERR-16-034, ERR-16-035, ERR-16-037, ERR-16-115 · EVT-16-13 · BR-16-026.

**Tiền điều kiện, dữ liệu.** T92 `16.export.max-rows = 1000` với 1.500 quan sát; báo cáo `bc-thang-2026-10` `DRAFT`; liên kết đã tạo cách đây 25 giờ (`clock-sim`).

**Các bước.**

1. Ở T92 `POST /exports` `{subject: OBSERVATIONS, format: CSV}`
2. U-T90-TO1 `POST /exports` `{subject: REPORT, subjectRef: {reportCode: bc-thang-2026-10}}` (chưa công bố)
3. `GET /exports/{exportId}/file` sau 25 giờ
4. U-T91-TO1 `GET /exports/{exportId}` của T90
5. Xuất báo cáo khi bộ dựng tệp bị làm lỗi

**Kết quả mong đợi.** Bước 1 `422` ERR-16-034. Bước 2 `403` ERR-16-037. Bước 3 `410` ERR-16-035, `state = EXPIRED`. Bước 4 `404` ERR-16-001 (404-ẩn). Bước 5 `state = FAILED`, `errorCode = ERR-16-115`, EVT-16-13 báo lỗi tới người yêu cầu.

**Thông báo hiển thị.** ERR-16-034: "Dữ liệu vượt giới hạn 1000 dòng. Thu hẹp bộ lọc hoặc phạm vi."; ERR-16-035: "Liên kết tải đã hết hạn. Tạo lại yêu cầu xuất."; ERR-16-037: "Anh/chị hoặc ứng dụng không được truy cập báo cáo này."; ERR-16-115: "Xuất bc-thang-2026-09 không thành công: không dựng được tệp."

:::

#### TC-16-073 · Danh sách phân phối, gửi khi công bố, người nhận sai, gửi lỗi <!--k:dist-ok-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-16-034 · API-16-083, 084, 082, 085 · UI-16-13 · ERR-16-036, ERR-16-116 · EVT-16-08.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; `notif-sim` nhận thư; báo cáo kỳ `M-2026-10` được công bố (pub-ok).

**Các bước.**

1. `POST /distributions` `{distributionCode: tc-lanh-dao, name: "Lãnh đạo UBND", reportTypes: [PERIODIC], periodTypes: [MONTH], recipients: [{type: USER, ref: U-T90-VW}, {type: GROUP, ref: lanh-dao-so}, {type: EMAIL, ref: "ubnd@t90.example.vn"}], attach: LINK, active: true}`
2. Công bố báo cáo `PERIODIC` kỳ tháng
3. `GET /distributions/tc-lanh-dao/deliveries`
4. `POST /distributions` với người nhận `EMAIL` `ai-do@gmail.com`
5. Công bố khi `notif-sim` làm lỗi địa chỉ `loi@t90.example.vn`

**Kết quả mong đợi.** Bước 1 `201`. Sau bước 2 sinh ba dòng `Delivery` `state = SENT` kèm `reportCode`, `version`, `recipient`, `sentAt`; thư gửi qua kênh PH-13 chứa liên kết (`attach = LINK`). Báo cáo `AD_HOC` không kích hoạt danh sách này. Bước 4 `422` ERR-16-036. Bước 5 `Delivery` `FAILED`, `errorCode = ERR-16-116`, không ảnh hưởng `PUBLISHED`.

**Thông báo hiển thị.** ERR-16-036: "Người nhận ai-do@gmail.com không hợp lệ hoặc không thuộc miền thư công vụ."; ERR-16-116: "Gửi tới loi@t90.example.vn không thành công."

:::

### TS-16-19 · Cung cấp chỉ tiêu cho hệ khác và thẻ Tổng quan

**Mục tiêu.** API đọc cho PH-17 và HTTT được cấp, thẻ chỉ tiêu cho trang Tổng quan.

**Phủ.** FR-16-035, 037; UC-16-19.

#### TC-16-074 · API đọc chỉ tiêu, báo cáo cho hệ khác và thẻ Tổng quan <!--k:feed-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-035, FR-16-037 · API-16-086, 087, 089 · UI-16-01 · BR-16-007, BR-16-009, BR-16-026 · NFR-16-006.

**Tiền điều kiện, dữ liệu.** S-T90-PH17 (scope `kpi.read`); `bc-thang-2026-09` `PUBLISHED`, `bc-thang-2026-08` `WITHDRAWN`, `bc-thang-2026-10` `DRAFT`; `16.overview.pinned-indicators` = `mttd,httt-ket-noi-ty-le,bi-mat-ngoai-kho,ho-so-cap-do-phe-duyet` (4 mã).

**Các bước.**

1. `GET /feed/indicator-values?periodCode=M-2026-09&onlyOfficial=true&groupCode=KET_NOI`
2. `GET /feed/reports?reportType=PERIODIC&from=2026-01-01&to=2026-12-31`
3. `GET /feed/indicator-values?indicatorCodes=mttd,httt-ket-noi-ty-le`
4. `GET /cards?limit=4` (4 chỉ tiêu ghim theo `16.overview.pinned-indicators`, một chỉ tiêu `NO_DATA`) và mở `/tong-quan`; đặt lại tham số rỗng rồi `GET /cards`

**Kết quả mong đợi.** Bước 1 `200`, `FeedValue` có `value`, `unit`, `status`, `completeness`, `provisional = false`, `reportCode`. Bước 2 chỉ `bc-thang-2026-09` (không bản nháp, không bản `WITHDRAWN`), có `contentHash`, `downloadUrl`. Bước 3 đúng hai chỉ tiêu. p99 ≤ 300 ms ở 50 lượt/giây (đo ở TC-16-116). Bước 4 `cards[]` ≤ 4, mỗi thẻ có `displayValue`, `status`, `trend`, `link` tới `/giam-sat/chi-tieu/chi-so/{ma}`; chỉ tiêu thiếu số hiện "Chưa có số liệu", không điền số cũ; `/tong-quan` hiển thị đủ thẻ. Tham số rỗng thì thẻ lấy điểm tổng và chỉ tiêu `OFF_TRACK` có trọng số nhóm cao nhất.

:::

#### TC-16-075 · Đọc máy: thiếu scope, tenant khác, tham số sai <!--k:feed-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-035 · API-16-086, 087 · ERR-16-037, ERR-16-057.

**Tiền điều kiện, dữ liệu.** S-T90-NOSCOPE, S-T91-PH01 (scope `kpi.read` của T91), S-T90-PH17.

**Các bước.**

1. S-T90-NOSCOPE `GET /feed/reports`
2. S-T91-PH01 `GET /feed/reports?reportCode=bc-thang-2026-09` (tenant T90)
3. S-T90-PH17 `GET /feed/indicator-values?from=2026-12-01&to=2026-01-01`

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403. Bước 2 không thấy dữ liệu T90 (`403` ERR-16-037 hoặc danh sách rỗng chỉ của T91). Bước 3 `400` ERR-16-057. Câu thông báo ERR-16-037 trả cho bên gọi máy.

**Thông báo hiển thị.** ERR-16-037: "Anh/chị hoặc ứng dụng không được truy cập báo cáo này."

:::

### TS-16-20 · Bảng điều khiển, chi tiết chỉ tiêu và so sánh hai kỳ

**Mục tiêu.** Bảng điều khiển năm nhóm cho lãnh đạo, chi tiết chỉ tiêu có truy nguồn, lọc và so sánh hai kỳ.

**Phủ.** FR-16-038, 039, 040; UC-16-20.

#### TC-16-076 · Bảng điều khiển năm nhóm, lọc và so sánh hai kỳ <!--k:dash-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-038, FR-16-040 · API-16-090, 091 · UI-16-01, UI-16-02 · BR-16-002, BR-16-016, BR-16-007 · NFR-16-005.

**Tiền điều kiện, dữ liệu.** T90 sau F-KY-1 (`M-2026-10` chưa chốt, `M-2026-09` đã chốt); U-T90-VW.

**Các bước.**

1. `GET /dashboard`
2. `GET /dashboard?periodCode=M-2026-10&view=LATEST`
3. `GET /dashboard?periodCode=M-2026-09&view=OFFICIAL`
4. Mở `/giam-sat/chi-tieu`
5. `GET /dashboard?periodCode=M-2026-10&groupCode=KET_NOI&status=AT_RISK`
6. `GET /dashboard?periodCode=M-2026-10&compareTo=M-2026-09`

**Kết quả mong đợi.** Bước 1 mặc định kỳ tháng gần nhất đã tính. Bước 2 `overallScore = 66,5`, năm `groups[]` đúng bảng 2.4, `statusCounts` 12/5/3/4, `attention[]` gồm chỉ tiêu `OFF_TRACK` rồi `AT_RISK` sắp theo trọng số, `flags` có `MISSING_SOURCE`, `provisional = true`. Bước 3 chỉ kỳ đã chốt, `provisional = false`. Bước 4 hiện điểm tổng, năm vòng nhóm, xu hướng 13 kỳ; chỉ tiêu `NO_DATA` có nhãn "Chưa có số liệu". Tải ≤ 2 giây p95. Bước 5 chỉ chỉ tiêu `KET_NOI` ở `AT_RISK`. Bước 6 `comparison[]` có `valueA`, `valueB`, `delta`, `deltaPct`, `statusA`, `statusB`, `definitionChanged = true` cho chỉ tiêu đổi định nghĩa giữa hai kỳ.

:::

#### TC-16-077 · Bảng điều khiển: kỳ sai, chưa có kỳ, tenant trống <!--k:dash-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-038, FR-16-039 · API-16-090, 091 · ERR-16-057, ERR-16-001.

**Tiền điều kiện, dữ liệu.** T93 chưa có kỳ nào; T90.

**Các bước.**

1. Ở T90 `GET /dashboard?periodCode=2026-10`
2. Ở T90 `GET /dashboard?periodCode=M-2031-01`
3. Ở T93 `GET /dashboard`
4. Ở T90 `GET /indicators/khong-co/series`

**Kết quả mong đợi.** Bước 1 `400` ERR-16-057. Bước 2 `404` ERR-16-001. Bước 3 `404` ERR-16-001 hoặc `200` thân trống kèm trạng thái "Chưa có kỳ nào được tính" (không bịa số). Bước 4 `404` ERR-16-001.

:::

#### TC-16-078 · Chi tiết chỉ tiêu: chuỗi thời gian, đường mục tiêu, truy tới quan sát <!--k:ind-detail-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-039 · API-16-091, 054, 043 · UI-16-02 · BR-16-001.

**Tiền điều kiện, dữ liệu.** T90, F-LICHSU (36 kỳ); `httt-ket-noi-ty-le` có định nghĩa ACTIVE; U-T90-TO1.

**Các bước.**

1. `GET /indicators/httt-ket-noi-ty-le/series?periodType=MONTH&from=M-2026-01&to=M-2026-10&lineage=true`
2. Từ một điểm chọn `GET /values/{valueId}/lineage`
3. Từ `inputs[0].observationId` `GET /observations?metricCode=ph01.httt.connected&periodCode=M-2026-10`

**Kết quả mong đợi.** Bước 1 `series[]` 10 điểm có `value`, `status`, `completeness`, `version`; `targetLine` = 95; `definition` có công thức và ngưỡng. Bước 2 `inputs[]` có `variable`, `metricCode`, `observationId`, `value`. Bước 3 trả quan sát gốc với `sourceRef`, `idempotencyRef`. Truy nguồn đi trọn từ số tới quan sát.

:::

### TS-16-21 · So sánh liên tenant ẩn danh

**Mục tiêu.** PA, PU so sánh phân bố, tỉnh khác ẩn danh, chỉ khi đủ số tenant tối thiểu.

**Phủ.** FR-16-041; UC-16-21.

#### TC-16-079 · So sánh liên tenant: phân bố, mã giả, không đủ tenant, vai trò <!--k:cmp-ok-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-041 · API-16-092 · UI-16-18 · ERR-16-038 · BR-16-020.

**Tiền điều kiện, dữ liệu.** Bốn tenant T90, T91, T92, T94 có số chính thức `tre-gateway-p95` kỳ `M-2026-10`: 180, 220, 260, 340 (ms); cùng phiên bản mẫu; `16.compare.min-tenants = 3`; U-PA, U-PU.

**Các bước.**

1. U-PA `GET /cross-tenant/comparison?indicatorCode=tre-gateway-p95&periodCode=M-2026-10`
2. U-PU gọi cùng yêu cầu
3. Đổi một tenant sang công thức tùy biến rồi gọi lại
4. Với `mttd` chỉ T90, T91 có số chính thức: U-PA gọi, rồi U-T90-TA1 gọi

**Kết quả mong đợi.** Bước 1 `200`, `tenantCount = 4`, `distribution` (`min` 180, `median` 240, `max` 340, `p25`, `p75`), `tenants[]` có `alias`, `value`, `status`; PA thấy mã tỉnh thật. Bước 2 cùng phân bố nhưng `alias` là mã giả ổn định theo kỳ (không suy ra tỉnh). Bước 3 `tenantCount = 3`, tenant tùy biến công thức bị loại. Bước 4 `422` ERR-16-038, không lộ số hai tenant; TA gọi `403` ERR-00-403.

**Thông báo hiển thị.** ERR-16-038: "Cần ít nhất 3 tỉnh có số chính thức để so sánh."

:::

### TS-16-22 · Theo dõi vận hành thu thập và tính toán

**Mục tiêu.** Tổng quan vận hành nguồn, lần chạy, xuất, gửi quốc gia; chỉ số vận hành của chính PH-16.

**Phủ.** FR-16-042, 058; UC-16-22.

#### TC-16-080 · Tổng quan vận hành và chỉ số vận hành của chính PH-16 <!--k:ops-overview-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-042, FR-16-058 · API-16-093, 049 · UI-16-08 · NFR-16-019.

**Tiền điều kiện, dữ liệu.** T90 có 12 nguồn `ACTIVE`, 2 `STALE`, 1 `FAILED`, 1 `PAUSED`; 1 xuất đang chạy; 1 gói quốc gia `FAILED`.

**Các bước.**

1. U-T90-TO1 `GET /ops/overview`
2. `GET /runs?state=FAILED&from=2026-11-01`
3. U-PO xem tổng hợp toàn nền tảng
4. `GET /actuator/prometheus` rồi quét chuỗi mồi `DH-CANARY-ops`

**Kết quả mong đợi.** Bước 1 `sources` = {ACTIVE 12, STALE 2, FAILED 1, PAUSED 1}, `runs[]` các lần gần nhất, `exports.running = 1`, `national.failed = 1`, `outboxLagSeconds` số nguyên ≥ 0. Bước 2 lọc đúng. Bước 3 PO thấy theo từng tenant, không thấy nội dung báo cáo. Bước 4 có đủ `kpi_observations_total{source,result}`, `kpi_source_state{source}`, `kpi_run_duration_seconds`, `kpi_run_completeness`, `kpi_indicator_status{group,status}`, `kpi_report_publish_total{result}`, `kpi_national_submission_total{type,state}`, `kpi_outbox_lag_seconds`, khớp dữ liệu; không nhãn nào chứa định danh người dùng hay chuỗi mồi.

:::

### TS-16-23 · Tìm, xem và xuất sổ kiến trúc

**Mục tiêu.** Tìm theo loại, vòng đời, tuân thủ; chi tiết thành phần; xuất sổ và sơ đồ phụ thuộc.

**Phủ.** FR-16-043, 049; UC-16-23.

#### TC-16-081 · Liệt kê, tìm, lọc, xem chi tiết thành phần; bộ lọc sai, tenant khác <!--k:arch-list-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-043 · API-16-094, 096 · UI-16-14, UI-16-15 · ERR-16-057, ERR-16-001.

**Tiền điều kiện, dữ liệu.** T90, F-KT (40 thành phần); U-T90-VW.

**Các bước.**

1. `GET /arch/components?page=0&size=20`
2. `GET /arch/components?componentType=API&lifecycle=ACTIVE&complianceLevel=NOT_ASSESSED`
3. `GET /arch/components?opsStatus=DOWN&origin=AUTO&q=hotich`
4. `GET /arch/components/httt-hotich`
5. `GET /arch/components?componentType=LOAI-LA`
6. U-T90-VW `GET /arch/components/httt-chi-t91` (chỉ có ở T91)

**Kết quả mong đợi.** Bước 1 `totalElements = 40`, `facets` theo loại, vòng đời, tuân thủ. Bước 2, 3 chỉ phần tử khớp. Bước 4 có `componentType`, `lifecycle`, `opsStatus`, `origin`, `complianceLevel`, `versions[]`, `dependencies[]`, `ownerOrgName`, `sourceRef`. Bước 5 `400` ERR-16-057. Bước 6 `404` ERR-16-001 (404-ẩn).

:::

#### TC-16-082 · Xuất sổ kiến trúc và sơ đồ phụ thuộc <!--k:arch-export-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-16-049 · API-16-079, 080, 081 · UI-16-15 · BR-16-026.

**Tiền điều kiện, dữ liệu.** T90, F-KT; U-T90-TO1.

**Các bước.**

1. `POST /exports` `{subject: ARCH_REGISTRY, subjectRef: {filter: {componentType: API}}, format: CSV}`
2. `POST /exports` `{subject: ARCH_GRAPH, subjectRef: {rootComponent: httt-hotich, depth: 2}, format: JSON}`
3. `POST /exports` `{subject: ARCH_GRAPH, subjectRef: {rootComponent: httt-hotich, depth: 6}, format: JSON}`

**Kết quả mong đợi.** Bước 1, 2 `202`, kết thúc `SUCCEEDED`; CSV đủ cột, JSON có nút và cạnh đến độ sâu 2. Bước 3 `400` ERR-16-003 (`depth` tối đa 5) hoặc `422` ERR-16-034 khi vượt giới hạn dữ liệu.

:::

### TS-16-24 · Tự đăng ký, cập nhật vận hành và đối chiếu thành phần

**Mục tiêu.** Thành phần tự vào sổ từ sự kiện nguồn và CI; trạng thái vận hành từ PH-13; đối chiếu phát hiện lệch, mồ côi.

**Phủ.** FR-16-044, 046, 048; UC-16-24.

#### TC-16-083 · Tự đăng ký thành phần từ sự kiện nguồn và API CI <!--k:arch-auto-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-044 · API-16-101, 096 · UI-16-14 · EVT-16-10 · BR-16-023 · NFR-16-015 · scope `arch.register`.

**Tiền điều kiện, dữ liệu.** T90; S-T90-CI; bộ phát PH-01, PH-02, PH-04, PH-10.

**Các bước.**

1. Phát EVT-01-03 (HTTT `httt-moi-1` `ACTIVE`), EVT-02-05 (API `api-moi-1`), EVT-04-07 (luồng `flow-moi-1`), EVT-10-01 (topic `topic-moi-1`)
2. Phát lại EVT-01-03 cùng `eventId`
3. S-T90-CI `POST /ingest/arch-components` `{components: [{componentCode: adapter-moi-1, componentType: ADAPTER, name: "Bộ điều hợp SOAP", version: "1.0.0", lifecycle: ACTIVE, sourceRef: "git:adapter-moi-1", dependsOn: [httt-moi-1], contentHash: <64 hex>}]}`
4. Gọi lại đúng lô

**Kết quả mong đợi.** Bước 1 bốn thành phần `origin = AUTO` xuất hiện ≤ 60 giây p95, `lifecycle = ACTIVE`, `sourceRef`, EVT: `arch-component.changed` (EVT-16-10) mỗi thành phần. Bước 2 không tạo trùng (loại theo `eventId`). Bước 3 `202`, `results[0].status = CREATED`, phụ thuộc `httt-moi-1` được nối. Bước 4 `UNCHANGED`. Trường do nguồn quản lý chỉ cập nhật từ nguồn (BR-16-023).

:::

#### TC-16-084 · Sự kiện thiếu trường, loại sai, thiếu scope <!--k:arch-auto-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-044 · API-16-101 · ERR-16-119, ERR-16-039 · UI-16-14.

**Tiền điều kiện, dữ liệu.** S-T90-CI, S-T90-NOSCOPE; sự kiện thiếu thành phần cha `httt-khong-co`.

**Các bước.**

1. Phát EVT-02-05 có `dependsOn = httt-khong-co`
2. `POST /ingest/arch-components` với `componentType = "LOAI-LA"`
3. `POST /ingest/arch-components` thiếu `componentCode`
4. S-T90-NOSCOPE `POST /ingest/arch-components`

**Kết quả mong đợi.** Bước 1 ghi ERR-16-119, đưa vào hàng đối chiếu (tab lệch UI-16-14), không tạo thành phần hỏng. Bước 2, 3 `results[].status = REJECTED`, `code = ERR-16-039` (hoặc `422` ERR-16-039). Bước 4 `403` ERR-00-403.

**Thông báo hiển thị.** ERR-16-119: "Không đăng ký được thành phần từ sự kiện e-9001: thiếu thành phần cha httt-khong-co."; ERR-16-039: "Thành phần adapter-sai thiếu trường componentCode hoặc loại không hợp lệ."

:::

#### TC-16-085 · Cập nhật trạng thái vận hành từ PH-13 và mất tin <!--k:arch-ops-->

::: dac-ta
**Loại.** Dương, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-16-046 · API-16-096 · UI-16-15 · ERR-16-121 · EVT-16-10.

**Tiền điều kiện, dữ liệu.** T90; thành phần `httt-hotich`; `notif-sim` (PH-13) phát trạng thái.

**Các bước.**

1. Phát trạng thái `DEGRADED` cho `httt-hotich`
2. Phát `UP`
3. Ngừng phát tin 2 giờ
4. `GET /arch/components/httt-hotich`

**Kết quả mong đợi.** Bước 1 `opsStatus = DEGRADED`, `opsStatusAt`, EVT: `arch-component.changed`. Bước 2 `UP`. Bước 3 sau thời gian quy định `opsStatus = UNKNOWN`, ghi ERR-16-121. Trạng thái vận hành là trường do PH-13 quản lý.

**Thông báo hiển thị.** ERR-16-121: "Chưa nhận trạng thái vận hành của httt-hotich từ 2026-11-26 08:00."

:::

#### TC-16-086 · Đối chiếu sổ kiến trúc: thiếu, mồ côi, lệch <!--k:arch-recon-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-048 · API-16-111, 112, 113 · UI-16-14 · ERR-16-120, ERR-16-056.

**Tiền điều kiện, dữ liệu.** T90, F-KT có thành phần mồ côi `api-mo-coi` (không còn ở PH-02), 1 API ở PH-02 chưa có trong sổ, 1 thành phần lệch phiên bản.

**Các bước.**

1. `POST /arch/reconciliations` `{componentTypes: [API]}` khóa idempotent `tc-recon-1`
2. `GET /arch/reconciliations/{reconId}`
3. `POST /arch/reconciliations/{reconId}/items/{itemId}:resolve` `{resolution: <25 ký tự>}`
4. `POST /arch/reconciliations` khi đang chạy
5. `resolve` với `resolution` 5 ký tự

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 `items[]` có đúng ba mục: `ORPHAN` (`api-mo-coi`), `MISSING`, `MISMATCH` với `diff`; tab lệch báo ERR-16-120. Bước 3 mục có `resolution`. Bước 4 `409` ERR-16-056. Bước 5 `400` ERR-16-003 (lược đồ `minLength` 20).

**Thông báo hiển thị.** ERR-16-120: "3 thành phần lệch với PH-02."; ERR-16-056: "Đã có lần đối chiếu đang chạy. Chờ lần này xong."

:::

### TS-16-25 · Khai báo, sửa thành phần, phiên bản và phụ thuộc

**Mục tiêu.** Khai báo thủ công, thêm phiên bản, phụ thuộc không vòng, đổi vòng đời; trường do nguồn quản lý không sửa tay.

**Phủ.** FR-16-045; UC-16-25.

#### TC-16-087 · Khai báo thành phần, phiên bản và phụ thuộc <!--k:arch-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-16-045 · API-16-095, 098, 099, 097 · UI-16-15 · EVT-16-10.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO1.

**Các bước.**

1. `POST /arch/components` `{componentCode: cong-thanh-toan-ngoai, name: "Cổng thanh toán ngoài", componentType: HTTT, lifecycle: PLANNED, ownerOrgId: ORG-TC, dependsOn: [httt-hotich]}`
2. `POST /arch/components/cong-thanh-toan-ngoai/versions` `{version: "1.0.0", releasedOn: 2026-11-20, specRef: "doc:tc-1"}`
3. `PUT /arch/components/cong-thanh-toan-ngoai/dependencies` `{dependsOn: [{componentCode: httt-hotich}, {componentCode: topic-moi-1}]}`
4. `PATCH /arch/components/cong-thanh-toan-ngoai` đổi `description`

**Kết quả mong đợi.** Bước 1 `201`, `origin = MANUAL`. Bước 2 `201`. Bước 3 `200`, `dependencies[]` hai phần tử `kind = MANUAL`. Bước 4 `200`. EVT: `arch-component.changed` mỗi lần đổi.

:::

#### TC-16-088 · Loại sai, mã trùng, phụ thuộc vòng, sửa trường do nguồn quản lý <!--k:arch-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-045, FR-16-044 · API-16-095, 097, 099 · ERR-16-039, ERR-16-002, ERR-16-041, ERR-16-040 · BR-16-023, BR-16-025.

**Tiền điều kiện, dữ liệu.** Thành phần A phụ thuộc B, B phụ thuộc C; `thanh-phan-cu` `RETIRED`.

**Các bước.**

1. `POST /arch/components` với `componentType = "LOAI-LA"`
2. `POST /arch/components` lại `componentCode = httt-hotich`
3. `PUT …/dependencies` của C với `dependsOn = [A]` (tạo vòng)
4. `PUT …/dependencies` với `dependsOn = [thanh-phan-cu]`
5. `PATCH /arch/components/httt-moi-1` (`origin = AUTO`, từ PH-01) đổi `name`, rồi đổi `description`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-039. Bước 2 `409` ERR-16-002. Bước 3, 4 `422` ERR-16-041. Bước 5 đổi `name` `409` ERR-16-040, đổi `description` `200`. Đồ thị phụ thuộc không đổi.

**Thông báo hiển thị.** ERR-16-041: "Phụ thuộc tới thanh-phan-cu tạo vòng hoặc thành phần đó đã ngừng."; ERR-16-040: "Trường name do PH-01 cập nhật tự động, không sửa tay được."

:::

#### TC-16-089 · Chuyển vòng đời; không xóa, không ngừng khi còn phụ thuộc hoạt động <!--k:arch-lifecycle-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-045 · API-16-100, 096 · ERR-16-042, ERR-16-006 · BR-16-025 · EVT-16-10.

**Tiền điều kiện, dữ liệu.** `httt-hotich` `ACTIVE` có 2 thành phần `ACTIVE` phụ thuộc; `tc-mo-coi-2` `ACTIVE` không ai phụ thuộc.

**Các bước.**

1. `POST …/httt-hotich:change-lifecycle` `{lifecycle: DEPRECATED}`
2. `{lifecycle: RETIRED}` cho `httt-hotich`
3. `{lifecycle: RETIRED}` cho `tc-mo-coi-2`
4. `{lifecycle: PLANNED}` cho `tc-mo-coi-2` đã `RETIRED`
5. `DELETE /arch/components/tc-mo-coi-2`

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `422` ERR-16-042. Bước 3 `200 RETIRED`. Bước 4 `422` ERR-16-042 (chuyển ngược không hợp lệ). Bước 5 `404` hoặc `405` (không có thao tác xóa; chỉ `RETIRED`). EVT: `arch-component.changed` ở bước 1, 3.

**Thông báo hiển thị.** ERR-16-042: "Không chuyển được sang RETIRED: còn 2 thành phần đang hoạt động phụ thuộc."

:::

### TS-16-26 · Đánh giá tuân thủ kiến trúc, xác nhận và miễn trừ

**Mục tiêu.** Bộ tiêu chí cấu hình; đánh giá bốn mắt; miễn trừ có hạn.

**Phủ.** FR-16-047; UC-16-26.

#### TC-16-090 · Tạo và kích hoạt bộ tiêu chí tuân thủ <!--k:cmp-criteria-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-047 · API-16-103, 104, 102 · UI-16-16 · ERR-16-045.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; F-TC phiên bản 1 `ACTIVE`.

**Các bước.**

1. `POST /compliance/criteria-sets` `{name: "Bộ tiêu chí v2", criteria: [{criterionCode: C-01, name: "Có tài liệu thiết kế", appliesTo: [HTTT, API], mandatory: true, weight: 10, frameworkRef: "CPĐT 3.0"}, …]}`
2. `POST /compliance/criteria-sets/2:activate`
3. `POST /compliance/criteria-sets` với tiêu chí `weight = -1` hoặc `criterionCode` trùng
4. `GET /compliance/criteria-sets`

**Kết quả mong đợi.** Bước 1 `201`, `state = DRAFT`. Bước 2 `200`, bản 2 `ACTIVE`, bản 1 `SUPERSEDED`. Bước 3 `422` ERR-16-045. Bước 4 trả hai bản. Đánh giá đã `CONFIRMED` theo bản cũ giữ kết quả.

**Thông báo hiển thị.** ERR-16-045: "Bộ tiêu chí chưa hợp lệ: criterionCode C-01 trùng."

:::

#### TC-16-091 · Đánh giá, gửi và xác nhận bốn mắt <!--k:cmp-assess-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-047 · API-16-105, 106, 107, 108 · UI-16-16 · EVT-16-11 · BR-16-024.

**Tiền điều kiện, dữ liệu.** T90; thành phần `httt-hotich` `NOT_ASSESSED`; bộ tiêu chí F-TC (8 bắt buộc); U-T90-SO lập, U-T90-TA2 xác nhận.

**Các bước.**

1. U-T90-SO `POST /arch/components/httt-hotich/assessments` `{criteriaSetVersion: 1}`
2. `PATCH /arch/assessments/{id}` điền `results` 12 tiêu chí: 10 `PASS`, 1 `FAIL` kèm `note`, 1 `NA`
3. `POST …:submit`
4. U-T90-TA2 `POST …:confirm`
5. `GET /arch/components/httt-hotich`
6. `POST …/waivers` với `until` = hôm nay + 200 ngày, rồi với `reason` 10 ký tự

**Kết quả mong đợi.** Bước 1 `201`, `DRAFT`. Bước 3 `SUBMITTED`, `proposedLevel` (ví dụ `PARTIAL`), `score`. Bước 4 `CONFIRMED`, `confirmedBy = TA2`. Bước 5 `complianceLevel = PARTIAL` (chỉ đổi sau khi `CONFIRMED`). EVT: `arch-compliance.assessed` (EVT-16-11).

:::

#### TC-16-092 · Thiếu kết quả bắt buộc, tự xác nhận, từ chối thiếu lý do <!--k:cmp-assess-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-047 · API-16-107, 108, 109 · ERR-16-043, ERR-16-005, ERR-16-007 · BR-16-024.

**Tiền điều kiện, dữ liệu.** Đánh giá `DRAFT` thiếu kết quả 3 tiêu chí bắt buộc; đánh giá `SUBMITTED` do U-T90-SO lập; có tiêu chí `FAIL` thiếu `note`.

**Các bước.**

1. `POST …:submit`
2. U-T90-SO `POST …:confirm` bản của mình
3. U-T90-TA2 `POST …:reject` với `comment` 5 ký tự
4. Gửi đánh giá có `FAIL` thiếu `note`

**Kết quả mong đợi.** Bước 1 `422` ERR-16-043. Bước 2 `403` ERR-16-005. Bước 3 `422` ERR-16-007. Bước 4 `422` ERR-16-043. `complianceLevel` không đổi.

**Thông báo hiển thị.** ERR-16-043: "Còn 3 tiêu chí bắt buộc chưa có kết quả hoặc tiêu chí không đạt chưa có ghi chú."

:::

#### TC-16-093 · Miễn trừ có hạn, vượt hạn tối đa và hết hạn miễn trừ <!--k:cmp-waiver-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-047 · API-16-110, 096 · UI-16-16 · ERR-16-044, ERR-16-007 · EVT-16-11 · BR-16-024.

**Tiền điều kiện, dữ liệu.** `httt-hotich` `PARTIAL` đã `CONFIRMED`; `16.compliance.waiver-max-days = 180`; `clock-sim`; U-T90-TA1.

**Các bước.**

1. `POST /arch/components/httt-hotich/waivers` `{criterionCode: C-07, reason: <60 ký tự>, until: <ngày hiện tại + 90>, planNote}`
2. `GET /arch/components/httt-hotich`
3. Đẩy đồng hồ qua `until`, chạy tác vụ hết hạn
4. `GET /arch/components/httt-hotich`
5. `POST …/waivers` với `until` = hôm nay + 200 ngày, rồi với `reason` 10 ký tự
6. U-T90-VW `POST …/waivers`

**Kết quả mong đợi.** Bước 1 `201`, `approvedBy`. Bước 2 `complianceLevel = EXEMPTED`. EVT: `arch-compliance.assessed` (miễn trừ). Bước 3 miễn trừ hết hạn, mức quay về `PARTIAL` (mức `CONFIRMED` gần nhất), EVT lần hai (hết hạn miễn trừ). Bước 5 `422` ERR-16-044; bước 6 `422` ERR-16-007 (hoặc `400` ERR-16-003 theo lược đồ). Bước 7 `403` ERR-00-403. Mức tuân thủ không đổi ở các bước lỗi.

**Thông báo hiển thị.** ERR-16-044: "Miễn trừ tối đa 180 ngày."

:::

### TS-16-27 · Quản lý mẫu gói quốc gia

**Mục tiêu.** Mẫu gói là cấu hình có phiên bản, kiểm tra trước khi kích hoạt, không viết cứng.

**Phủ.** FR-16-050; UC-16-27.

#### TC-16-094 · Tạo, thử, kích hoạt mẫu gói quốc gia có phiên bản; mẫu sai <!--k:ntpl-create-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-050 · API-16-115, 116, 117, 114 · UI-16-17 · ERR-16-047 · BR-16-002, BR-16-021.

**Tiền điều kiện, dữ liệu.** T96; U-PA hoặc U-T96-TA; không có mẫu `KPI_REPORT`.

**Các bước.**

1. `POST /national/templates` `{templateCode: qg-bao-cao-chi-tieu, submissionType: KPI_REPORT, version: 1, schema: {…}, mapping: {…ánh xạ trường báo cáo sang gói…}, channelRef: "ph14:qg-sim", effectiveFrom: 2026-12-01}`
2. `GET /national/templates/qg-bao-cao-chi-tieu`
3. `POST /national/templates/qg-bao-cao-chi-tieu/versions/1:activate`
4. Tạo phiên bản 2 rồi kích hoạt
5. `POST /national/templates` với `schema` không hợp lệ, hoặc `mapping` trỏ trường không có
6. U-T96-TO (không có `PERM-16-national`) `POST /national/templates`

**Kết quả mong đợi.** Bước 1 `201`, `state = DRAFT`, `testResult` đạt thử trên báo cáo mẫu. Bước 3 `200`, `ACTIVE`. Bước 4 bản 2 `ACTIVE`, bản 1 `SUPERSEDED`; gói đã nộp theo bản 1 không đổi. Mẫu nằm ở cấu hình, đổi không cần phát hành (NFR-16-020). Bước 5 `422` ERR-16-047. Bước 6 `403` ERR-00-403; mẫu hiện hành giữ `ACTIVE`.

**Thông báo hiển thị.** ERR-16-047: "Mẫu gói qg-bao-cao-chi-tieu phiên bản 2 chưa hợp lệ: mapping trỏ trường khong-co."

:::

### TS-16-28 · Lập và gửi gói báo cáo chỉ tiêu, sổ kiến trúc qua PH-14

**Mục tiêu.** Gói chỉ từ báo cáo đã công bố hoặc sổ kiến trúc hiện hành, qua PH-14, idempotent.

**Phủ.** FR-16-051, 052; UC-16-28.

#### TC-16-095 · Lập gói báo cáo chỉ tiêu và gửi qua PH-14 <!--k:nat-kpi-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-051 · API-16-118, 119, 120, 121, 123 · UI-16-17, UI-16-10 · EVT-16-12 · BR-16-021, BR-16-022.

**Tiền điều kiện, dữ liệu.** T96; U-T96-TA; báo cáo `bc-thang-2026-09` `PUBLISHED` phiên bản 1; mẫu `KPI_REPORT` `ACTIVE`; `qg-sim` kịch bản `ACK`; `16.national.enabled = true`.

**Các bước.**

1. `POST /national/submissions` `{submissionType: KPI_REPORT, reportCode: bc-thang-2026-09, version: 1, templateCode: qg-bao-cao-chi-tieu}` khóa idempotent `tc-sub-1`
2. `GET /national/submissions/{id}` (bản xem trước)
3. `POST /national/submissions/{id}:send`
4. Đợi biên nhận
5. `GET /national/submissions/{id}/logs`
6. `GET /national/submissions?submissionType=KPI_REPORT&state=ACKNOWLEDGED`

**Kết quả mong đợi.** Bước 1 `201`, `state = PENDING`, `contentHash`, `preview`. Bước 3 `202`, `SENDING` → `SENT`, gói đi qua PH-14 (không gọi thẳng hệ quốc gia; `qg-sim` nhận từ PH-14). Sau biên nhận `ACKNOWLEDGED`, `receiptNo`. Nhật ký có dòng cho mỗi lần giao, phản hồi, biên nhận; danh sách lọc trả gói này. EVT: `national-submission.state-changed` (EVT-16-12) mỗi lần đổi.

:::

#### TC-16-096 · Gửi quốc gia đang tắt, báo cáo chưa công bố, gói không đạt mẫu, báo cáo đột xuất <!--k:nat-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-051 · API-16-118, 121 · ERR-16-046, ERR-16-052, ERR-16-048 · BR-16-021.

**Tiền điều kiện, dữ liệu.** T90 (`16.national.enabled = false`); T96; báo cáo `bc-thang-2026-10` `DRAFT`; báo cáo `bc-dot-xuat-q1-q3` `AD_HOC`; mẫu gói yêu cầu trường `periodCode` mà báo cáo thử thiếu.

**Các bước.**

1. Ở T90 `POST /national/submissions`
2. Ở T96 `POST /national/submissions` với `reportCode = bc-thang-2026-10` (chưa công bố)
3. Ở T96 với báo cáo đột xuất
4. Ở T96 với gói thiếu trường bắt buộc của mẫu

**Kết quả mong đợi.** Bước 1 `409` ERR-16-046. Bước 2 `422` ERR-16-052. Bước 3 `422` ERR-16-052 (đột xuất không gửi quốc gia). Bước 4 `422` ERR-16-048. Không gói nào được tạo hoặc gửi.

**Thông báo hiển thị.** ERR-16-046: "Chức năng gửi quốc gia chưa được bật cho tỉnh."; ERR-16-052: "Chỉ gửi được báo cáo đã công bố."; ERR-16-048: "Gói chưa đạt mẫu qg-bao-cao-chi-tieu: periodCode bắt buộc."

:::

#### TC-16-097 · Gói trùng nội dung đã nộp (idempotent) <!--k:nat-dup-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-051, FR-16-053 · API-16-118 · ERR-16-049 · BR-16-021.

**Tiền điều kiện, dữ liệu.** T96; gói `KPI_REPORT` của `bc-thang-2026-09` phiên bản 1 đã `ACKNOWLEDGED` (mã biên nhận `BN-TC-0001`, ngày 2026-11-26).

**Các bước.**

1. `POST /national/submissions` lại với `reportCode = bc-thang-2026-09`, `version = 1`
2. Sau khi đính chính tạo phiên bản 2 công bố, `POST /national/submissions` với `version = 2`

**Kết quả mong đợi.** Bước 1 `409` ERR-16-049 (cùng `reportCode`, phiên bản, `contentHash`), không tạo gói mới. Bước 2 `201` (khác phiên bản, khác `contentHash`).

**Thông báo hiển thị.** ERR-16-049: "Gói bc-thang-2026-09 đã được nộp ngày 2026-11-26 (mã biên nhận BN-TC-0001) và chưa thay đổi."

:::

#### TC-16-098 · Gửi sổ kiến trúc qua PH-14, toàn bộ và theo thay đổi <!--k:nat-arch-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-16-052 · API-16-118, 121, 120 · UI-16-17 · EVT-16-12 · BR-16-021, BR-16-024.

**Tiền điều kiện, dữ liệu.** T96; sổ kiến trúc 40 thành phần, 10 đã `CONFIRMED` tuân thủ; mẫu `ARCH_REGISTRY` `ACTIVE`; `qg-sim`.

**Các bước.**

1. `POST /national/submissions` `{submissionType: ARCH_REGISTRY, mode: FULL, componentTypes: [HTTT, API], templateCode: qg-so-kien-truc}` rồi `:send`
2. Đổi vòng đời một thành phần
3. `POST /national/submissions` `{submissionType: ARCH_REGISTRY, mode: DELTA}`

**Kết quả mong đợi.** Bước 1 `componentCount` đúng số `HTTT`, `API`, mỗi thành phần có phiên bản, trạng thái vận hành, `complianceLevel`; gói đi qua PH-14, nhận biên nhận. Bước 3 gói `DELTA` chỉ thành phần thay đổi; idempotent theo `componentCode` + phiên bản + `contentHash`.

:::

### TS-16-29 · Nhật ký nộp, biên nhận, gửi lại và đối soát

**Mục tiêu.** Biên nhận khớp mã băm; gửi lại giãn cách đúng; đối soát phát hiện lệch.

**Phủ.** FR-16-053, 054; UC-16-29.

#### TC-16-099 · Nhận biên nhận từ PH-14 và nhật ký chỉ thêm <!--k:nat-receipt-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-053 · API-16-124, 120, 123 · UI-16-17 · EVT-16-12 · BR-16-022.

**Tiền điều kiện, dữ liệu.** Gói `SENT` (hash `H1`); S-T90-PH14 (scope `kpi.national-receipt`).

**Các bước.**

1. S-T90-PH14 `POST /internal/national/receipts` `{submissionId, channelMessageId: m-1, status: ACKNOWLEDGED, receiptNo: BN-TC-0002, contentHash: H1}`
2. `GET /national/submissions/{id}`
3. `GET /national/submissions/{id}/logs`
4. Gửi lại đúng biên nhận

**Kết quả mong đợi.** Bước 1 `204`. Bước 2 `ACKNOWLEDGED`, `receiptNo`, `ackAt`. Bước 3 nhật ký chỉ thêm, có dòng biên nhận kèm `channelMessageId`; không sửa, không xóa dòng cũ. Bước 4 không tạo dòng thứ hai (idempotent theo `channelMessageId`) hoặc `409` ERR-16-006.

:::

#### TC-16-100 · Biên nhận lệch mã băm, sai scope, gói không có <!--k:nat-receipt-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-053 · API-16-124 · ERR-16-124, ERR-16-001, ERR-16-006, ERR-00-403.

**Tiền điều kiện, dữ liệu.** Gói `SENT` (hash `H1`); S-T90-NOSCOPE, S-T90-PH14.

**Các bước.**

1. S-T90-PH14 gửi biên nhận với `contentHash = H2`
2. S-T90-NOSCOPE `POST /internal/national/receipts`
3. S-T90-PH14 gửi biên nhận cho `submissionId` không có
4. Gửi biên nhận `ACKNOWLEDGED` cho gói đang `PENDING`

**Kết quả mong đợi.** Bước 1 ghi ERR-16-124, gói giữ `SENT`, báo cán bộ ATTT, thông báo PH-13. Bước 2 `403` ERR-00-403. Bước 3 `404` ERR-16-001. Bước 4 `409` ERR-16-006.

**Thông báo hiển thị.** ERR-16-124: "Bản lưu hoặc biên nhận của gói bc-thang-2026-09 không khớp mã băm đã ghi. Đã báo cán bộ an toàn thông tin."

:::

#### TC-16-101 · Gửi lại tự động theo giãn cách và gửi lại thủ công <!--k:nat-retry-->

::: dac-ta
**Loại.** Dương, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-053 · API-16-121, 122, 123 · UI-16-17 · ERR-16-118, ERR-16-117, ERR-16-050 · EVT-16-12 · BR-16-021.

**Tiền điều kiện, dữ liệu.** T96 `16.national.retry-max = 5`; `qg-sim` kịch bản `TIMEOUT`; `clock-sim`; gói mới (hash `H1`).

**Các bước.**

1. `POST …:send`
2. Đẩy đồng hồ 5, 15, 45, 135 phút lần lượt
3. Sau lần thứ 5 `GET /national/submissions/{id}`
4. Đổi `qg-sim` về `ACK`, U-T96-TA `POST …:retry` `{reason: <25 ký tự>}`
5. Với `qg-sim` `REJECT` mã `QG-422`, thử `POST …:retry`
6. Gửi lại khi đã `ACKNOWLEDGED`

**Kết quả mong đợi.** Lần đầu thất bại `FAILED`, ERR-16-118 "sẽ thử lại lần 1"; tự gửi lại đúng giãn cách 5, 15, 45, 135 phút (`attemptCount` tăng); quá `retry-max` thì dừng, tạo việc cho TA. Bước 4 gửi lại cùng `contentHash` thành công, không tạo bản trùng ở `qg-sim`. Bước 5 gói `REJECTED` hiện ERR-16-117, `:retry` bị `409` ERR-16-050. Bước 6 `409` ERR-16-050.

**Thông báo hiển thị.** ERR-16-118: "Gửi qua PH-14 không thành công, sẽ thử lại lần 2."; ERR-16-117: "Hệ quốc gia từ chối gói: QG-422 sai lược đồ."; ERR-16-050: "Gói bc-thang-2026-09 đang ở trạng thái ACKNOWLEDGED hoặc đã gửi lại tối đa 5 lần."

:::

#### TC-16-102 · Đối soát sổ kiến trúc, gói đã nộp và chỉ tiêu <!--k:nat-recon-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-16-054 · API-16-125, 126 · UI-16-17 · ERR-16-056.

**Tiền điều kiện, dữ liệu.** T96; một thành phần đổi sau lần gửi `FULL`; một báo cáo `PUBLISHED` chưa có gói.

**Các bước.**

1. `POST /national/reconciliations` `{scope: ALL}`
2. `GET /national/reconciliations/{reconId}`
3. `POST /national/reconciliations` khi đang chạy

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 `items[]` có `kind`, `ref`, `expected`, `actual`, `suggestion`: một dòng cho thành phần lệch, một cho báo cáo chưa nộp. Bước 3 `409` ERR-16-056.

:::

### TS-16-30 · Tham số, lưu giữ dữ liệu và nhật ký kiểm toán

**Mục tiêu.** Tham số tenant trong miền, áp dụng nhanh; lưu giữ theo hạn; kiểm toán tra cứu được.

**Phủ.** FR-16-055, 056, 057; UC-16-30.

#### TC-16-103 · Sửa tham số tenant và áp dụng không cần phát hành <!--k:set-patch-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-055 · API-16-128, 127 · UI-16-19 · NFR-16-020.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1.

**Các bước.**

1. `GET /settings`
2. `PATCH /settings` mảng `settings` đặt `16.export.link-hours` = 48 và `16.period.close-day` = 7 kèm `If-Match`
3. Tạo xuất mới và kiểm `expiresAt`
4. `GET /settings`

**Kết quả mong đợi.** Bước 1 25 khóa `16.*` kèm `default`, `ceiling`, `scope`. Bước 2 `200`. Bước 3 `expiresAt` = tạo + 48 giờ, áp dụng ≤ 60 giây, không cần khởi động lại. Bước 4 giá trị mới, `updatedBy`. Thêm chỉ tiêu, nguồn, mẫu gói cũng không cần phát hành.

:::

#### TC-16-104 · Tham số ngoài miền, vượt trần, khóa bởi PA <!--k:set-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-055 · API-16-128 · ERR-16-051, ERR-00-403, ERR-00-428.

**Tiền điều kiện, dữ liệu.** T92 (PA khóa `16.manual.evidence-required = true`); U-T90-TA1, U-T90-VW.

**Các bước.**

1. `PATCH /settings` `16.report.retention-years = 5`
2. `PATCH /settings` `16.compare.min-tenants = 2`
3. Ở T92 `PATCH /settings` `16.manual.evidence-required = false`
4. U-T90-VW `PATCH /settings`
5. `PATCH /settings` không `If-Match`

**Kết quả mong đợi.** Bước 1, 2, 3 `422` ERR-16-051 (ngoài miền, dưới sàn, vượt khóa PA). Bước 4 `403` ERR-00-403. Bước 5 `428` ERR-00-428. Giá trị không đổi.

**Thông báo hiển thị.** ERR-16-051: "Giá trị 5 của 16.report.retention-years nằm ngoài miền cho phép (10 đến 30)."

:::

#### TC-16-105 · Nhật ký kiểm toán thao tác PH-16, quyền xem, khoảng tra quá dài <!--k:audit-read-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-056 · API-16-129 · UI-16-20 · ERR-16-060 · BR-16-032.

**Tiền điều kiện, dữ liệu.** T90 đã chạy các ca ghi; U-T90-AU, U-T90-VW, U-PU.

**Các bước.**

1. U-T90-AU `GET /audit-events?objectType=report&action=report.publish&from=2026-11-01`
2. `GET /audit-events?actor=U-T90-TA2`
3. U-T90-VW `GET /audit-events`
4. U-PU xem kiểm toán liên tenant
5. `GET /audit-events?from=2025-01-01&to=2026-11-26` (quá 12 tháng)

**Kết quả mong đợi.** Bước 1, 2 `200`, mỗi dòng có `at`, `actor`, `role`, `action`, `objectType`, `objectRef`, `before`, `after`, `traceId`; không có nội dung nhạy cảm. Bước 3 `403` ERR-00-403 (VW không có `PERM-16-audit-read`). Bước 4 PU chỉ đọc, thấy theo tenant. Bước 5 `400` ERR-16-060.

**Thông báo hiển thị.** ERR-16-060: "Khoảng thời gian tra cứu tối đa 12 tháng mỗi lần."

:::

#### TC-16-106 · Lưu giữ, xóa dữ liệu theo hạn; báo cáo công bố giữ 10 năm <!--k:retention-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-16-057 · API-16-130 · ERR-16-122, ERR-16-125 · BR-16-010, BR-16-031 · NFR-16-013.

**Tiền điều kiện, dữ liệu.** T90; quan sát tháng M-2023-09 cũ hơn 36 tháng; `16.observation.retention-months = 36`; tệp xuất hết hạn 8 ngày; `bc-thang-2026-09` `PUBLISHED`; `clock-sim`.

**Các bước.**

1. `GET /retention/status`
2. Chạy tác vụ dọn theo hạn
3. Cố xóa báo cáo `bc-thang-2026-09` hoặc tệp WORM trước hạn 10 năm
4. Làm lỗi tác vụ dọn (khóa phân vùng)
5. Ghi quan sát vào tháng chưa có phân vùng

**Kết quả mong đợi.** Bước 1 liệt kê `partitions[]` (`name`, `rowCount`, `rangeFrom`, `rangeTo`), `lastPurgeAt`, `nextPurgeAt`. Bước 2 phân vùng quá hạn bị loại, `bytesFreed`; giá trị chỉ tiêu và lần tổng hợp chính thức vẫn còn; tệp xuất hết hạn bị xóa sau 7 ngày. Bước 3 bị từ chối, báo cáo còn nguyên. Bước 4 ghi ERR-16-122, thông báo PH-13, không mất dữ liệu cũ. Bước 5 ghi ERR-16-125, quan sát vào đệm, không mất.

**Thông báo hiển thị.** ERR-16-122: "Lần dọn dữ liệu ngày 2026-11-26 lỗi: khóa phân vùng."; ERR-16-125: "Không ghi được quan sát kỳ M-2026-12: phân vùng chưa sẵn sàng."

:::

## 5. Kịch bản kiểm thử xuyên suốt và phi chức năng

Sáu kịch bản dưới kiểm các yêu cầu cắt ngang: cô lập tenant, phân quyền, kiểm toán, hiệu năng, tái lập, chịu lỗi và truy cập. Ca hiệu năng ghi ngưỡng của NFR-16; số đo thật chạy ở PERF (mục 1.3).

### TS-16-31 · Cô lập tenant: API, RLS, Kafka

**Mục tiêu.** Tenant này không đọc, ghi, nghe được dữ liệu của tenant khác ở mọi lớp.

**Phủ.** FR-16-035, 044, 055; NFR-16-018.

#### TC-16-107 · Rò rỉ chéo tenant qua API đọc, ghi và tài khoản máy <!--k:iso-api-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** ERR-16-001, ERR-16-037 · API-16-001, 003, 021, 023, 031, 033, 043, 046, 048, 051, 064, 066, 077, 080, 088, 090, 094, 096, 112, 120, 129, 030, 101, 086 · BR-16-023 · FR-16-031, FR-16-043.

**Tiền điều kiện, dữ liệu.** T90 và T91 cùng mã chỉ tiêu, nguồn, kỳ, báo cáo `bc-thang-2026-10`, thành phần; U-T91-TA1, U-T91-TO1 (có đủ quyền ở T91).

**Các bước.**

1. Với từng API đọc trong Truy vết, U-T91-TA1 gọi bằng mã tài nguyên mà chỉ T90 có (ví dụ `exportId`, `submissionId`, `manualId`, `runId`)
2. Gọi danh sách và so `totalElements` với số liệu của T91
3. So sánh thân `404` giữa mã không tồn tại và mã thuộc T90
4. Thử `POST /reports/bc-thang-2026-10:approve` của T91 vào báo cáo cùng mã nhưng thuộc T90
5. S-T91-PH01 (scope `kpi.ingest`, `arch.register`, `kpi.read` của T91) gọi `POST /ingest/observations` với `sourceCode` của T90, `POST /ingest/arch-components` với `componentCode` có ở T90, `GET /feed/indicator-values`

**Kết quả mong đợi.** Mọi lần gọi theo mã của T90 trả `404` ERR-16-001 (404-ẩn, thân giống mã không tồn tại trừ `traceId`) hoặc `403` ERR-16-037 cho phạm vi dữ liệu; danh sách chỉ chứa dữ liệu T91; thao tác ghi không có tác dụng ở T90; không bản ghi kiểm toán thành công ở T90. Bước 5: `403` ERR-16-037 hoặc `400` ERR-16-101, không quan sát nào vào T90; thành phần tạo ở T91 không ghi đè T90; `feed` chỉ trả số của T91.

:::

#### TC-16-108 · Cô lập ở CSDL bằng RLS <!--k:iso-rls-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** FR-16-055 · NFR-16-018 · BR-16-020 · ERR-16-037.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu T90 và T91 ở schema `ph16_kpi`; vai trò dịch vụ có `app.tenant_id`; vai trò báo cáo liên tenant.

**Các bước.**

1. Đặt `app.tenant_id = T91` rồi `SELECT` mọi bảng `ph16_kpi`
2. Đặt `T91` rồi `INSERT` và `UPDATE` dòng có `tenant_id = T90`
3. Không đặt `app.tenant_id`
4. Vai trò báo cáo liên tenant `SELECT` bảng giá trị và khung nhìn tổng hợp
5. Thử đọc các phân vùng bảng giá trị trực tiếp

**Kết quả mong đợi.** Bước 1 chỉ dòng T91 hoặc 0 dòng của T90. Bước 2 bị từ chối bởi chính sách RLS. Bước 3 không trả dòng nào. Bước 4 chỉ qua khung nhìn tổng hợp có ngoại lệ RLS, không đọc được bảng quan sát; đủ để so sánh ẩn danh. Bước 5 phân vùng cũng chịu RLS. Kịch bản chạy bằng tệp kiểm cô lập của D03-03-PH16.

:::

#### TC-16-109 · Cô lập ở Kafka và nội dung sự kiện <!--k:iso-kafka-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** EVT-16-08, EVT-16-12 · NFR-16-018 · BR-16-021.

**Tiền điều kiện, dữ liệu.** Client OAUTHBEARER của T91 và của T90; báo cáo của T90 được công bố; gói quốc gia của T96 đổi trạng thái.

**Các bước.**

1. Client T91 đăng ký `t90.kpi.report.published.v1` và `t90.kpi.national-submission.state-changed.v1`
2. Client T90 đọc `t90.kpi.report.published.v1`
3. Kiểm nội dung bản tin
4. Bản tin EVT-16-05 chứa `completeness`, `flags`

**Kết quả mong đợi.** Bước 1 bị từ chối (ACL theo tiền tố tenant). Bước 2 nhận đúng một bản tin. Bước 3 chỉ có mã báo cáo, phiên bản, trạng thái, số tổng hợp; không có nội dung báo cáo, bằng chứng, `dimensions`. Bước 4 đúng lược đồ.

:::

### TS-16-32 · Phân quyền PERM-16, bốn mắt và tài khoản máy

**Mục tiêu.** Ma trận vai trò × quyền, cặp loại trừ, scope máy, If-Match.

**Phủ.** FR-16-005, 015, 028, 047, 055; NFR-16-018.

#### TC-16-110 · Ma trận quyền theo vai trò <!--k:perm-matrix-->

::: dac-ta
**Loại.** Bảo mật, Truy cập.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** PERM-16-read, PERM-16-admin, PERM-16-approve, PERM-16-source, PERM-16-manual, PERM-16-run, PERM-16-report, PERM-16-export, PERM-16-arch, PERM-16-arch-assess, PERM-16-national, PERM-16-compare, PERM-16-config, PERM-16-audit-read · ERR-00-403 · API-16-002, 012, 022, 032, 050, 065, 079, 095, 108, 118, 092, 128, 129.

**Tiền điều kiện, dữ liệu.** Người dùng ở bảng 2.2: VW, TA, TO, SO, DS, AU, PA, PU; D02-08 là nguồn quyền.

**Các bước.**

1. Với mỗi cặp (vai trò, API đại diện của từng quyền) gọi một lần
2. So kết quả với bảng quyền trong FRS mục 3.2
3. Ba vai trò PU, AU, VW thử mọi API ghi

**Kết quả mong đợi.** Mọi cặp được phép trả mã thành công, mọi cặp không được trả `403` ERR-00-403, không có đường tắt (ví dụ TO không `:approve`, VW không ghi, AU xuất được nhưng không nhập tay, PU chỉ đọc và so sánh, PA chỉ ghi mẫu `COMMON` và so sánh). 0 lệch giữa FRS và hành vi.

:::

#### TC-16-111 · Bốn cặp loại trừ không có đường vòng <!--k:perm-sod-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-16-005, FR-16-015, FR-16-028, FR-16-047 · API-16-012, 040, 072, 074, 108 · ERR-16-005 · BR-16-003, BR-16-004, BR-16-005, BR-16-024.

**Tiền điều kiện, dữ liệu.** U-T90-TA3 có cả `PERM-16-report` và `PERM-16-approve`; hai phiên trình duyệt khác nhau của cùng người; hai tài khoản mới.

**Các bước.**

1. TA3 soạn rồi `:approve` định nghĩa chỉ tiêu của chính mình
2. TA3 lập báo cáo rồi `:approve`, `:publish`
3. TO nhập số tay rồi tự `:accept`
4. SO lập đánh giá tuân thủ rồi tự `:confirm`
5. Thử bằng hai phiên của cùng người, đổi `If-Match`, gọi trực tiếp API không qua giao diện
6. Người thứ hai khác làm đúng các bước

**Kết quả mong đợi.** Bốn trường hợp tự duyệt đều `403` ERR-16-005, kể cả người có đủ hai quyền, đổi phiên hoặc gọi API trực tiếp. Người thứ hai khác thực hiện thành công. Mỗi lần chặn có kiểm toán từ chối.

:::

### TS-16-33 · Kiểm toán và quan sát vận hành

**Mục tiêu.** Mọi thao tác ghi có kiểm toán không mất; không rò rỉ định danh; chỉ số vận hành đủ.

**Phủ.** FR-16-056, 058, 010; NFR-16-019.

#### TC-16-112 · Mọi thao tác ghi có kiểm toán, không mất khi PH-13 ngừng <!--k:aud-every-write-->

::: dac-ta
**Loại.** Bảo mật, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-16-056 · API-16-129 · ERR-16-123 · BR-16-032 · NFR-16-012.

**Tiền điều kiện, dữ liệu.** T95; `notif-sim` (PH-13) ngừng; tập 20 thao tác ghi đại diện (tạo chỉ tiêu, duyệt, nhập tay, chốt kỳ, công bố, xuất, đổi tham số…).

**Các bước.**

1. Thực hiện 20 thao tác khi PH-13 ngừng
2. Khởi động lại `dh-platform`
3. Bật lại PH-13
4. Đối chiếu kiểm toán ở PH-13 với danh sách thao tác

**Kết quả mong đợi.** Bước 1 hệ thống báo ERR-16-123 "Kiểm toán PH-16 tồn 20 bản ghi chưa chuyển" ở PH-13 sau khi có lại. Bước 2 không mất bản ghi tồn. Bước 4 đủ 20 bản ghi theo đúng thứ tự, trường đủ (người, vai trò, hành động, đối tượng, trước, sau, `traceId`), không trùng.

:::

#### TC-16-113 · Không lộ định danh cá nhân và chuỗi mồi <!--k:aud-no-pii-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP.

**Truy vết.** FR-16-010, FR-16-012 · BR-16-028 · ERR-16-101 · NFR-16-018.

**Tiền điều kiện, dữ liệu.** T90; mồi `DH-CANARY-aud` và số giả `0010990123456` đặt ở `dimensions`, `reason`, `note`, `description`; nhật ký ứng dụng, vết OTel.

**Các bước.**

1. Đẩy quan sát với `dimensions` chứa số giả
2. Đặt mồi vào `reason`, `note`, `description`, `comment` ở các API ghi
3. Chạy mọi ca ghi, xuất báo cáo, gói quốc gia
4. `grep` mồi ở log 5 phút, vết OTel, kiểm toán, Kafka, tệp xuất, metric

**Kết quả mong đợi.** Bước 1 loại ERR-16-101. Mồi ở trường văn bản tự do chỉ nằm trong bản ghi của chính nó (`reason`, `note`), không ra log, vết, metric, sự kiện, tệp xuất của phân hệ khác. Số giả không có ở bất kỳ đâu. Mồi sạch.

:::

### TS-16-34 · Hiệu năng

**Mục tiêu.** Tổng hợp, tiếp nhận, đọc, công bố, xuất, tự đăng ký đạt ngưỡng NFR-16.

**Phủ.** NFR-16-001…007, 009, 010, 015, 016.

#### TC-16-114 · Tổng hợp kỳ tháng 24 chỉ tiêu trên 10 triệu quan sát <!--k:perf-agg-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-16-001, NFR-16-022 · FR-16-018 · API-16-050, 051.

**Tiền điều kiện, dữ liệu.** T97 (F-PERF): 10 triệu quan sát trong phân vùng tháng, 36 kỳ, 24 chỉ tiêu.

**Các bước.**

1. `POST /periods/{kỳ}/runs`
2. Đo thời gian từ `QUEUED` tới `SUCCEEDED`
3. Lặp 5 lần
4. Đồng thời chạy tải đọc nền 50 yêu cầu/giây

**Kết quả mong đợi.** Mỗi lần ≤ 5 phút (NFR-16-001); `completeness` và giá trị đúng như dữ liệu chuẩn; không lỗi `5xx`.

:::

#### TC-16-115 · API đẩy quan sát và tiêu thụ sự kiện <!--k:perf-ingest-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-16-003, NFR-16-004 · FR-16-010, FR-16-012 · API-16-030.

**Tiền điều kiện, dữ liệu.** T97; S-T90-PH01; bộ phát Kafka 50 sự kiện/giây.

**Các bước.**

1. k6 15 phút `POST /ingest/observations` lô 100, tối thiểu 200 quan sát/giây
2. Song song phát 50 sự kiện/giây
3. Đo trễ từ phát tới ghi quan sát

**Kết quả mong đợi.** API đẩy p95 ≤ 300 ms, p99 ≤ 500 ms mỗi lô 100; thông lượng ≥ 200 quan sát/giây; trễ sự kiện p95 ≤ 60 giây; 0 quan sát mất, 0 trùng.

:::

#### TC-16-116 · Bảng điều khiển, API đọc, danh sách <!--k:perf-read-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-16-005, NFR-16-006, NFR-16-007 · FR-16-038, FR-16-035, FR-16-031, FR-16-043 · API-16-090, 086, 064, 094.

**Tiền điều kiện, dữ liệu.** T98: 24 chỉ tiêu, 13 kỳ, 1.000 báo cáo, 10.000 thành phần; 200 người dùng đồng thời; S-T90-PH17.

**Các bước.**

1. 200 người dùng mở `GET /dashboard`
2. 50 lượt/giây `GET /feed/indicator-values`
3. `GET /reports` và `GET /arch/components` phân trang
4. `GET /reports/{reportCode}` và chi tiết thành phần
5. Đo LCP của UI-16-01 bằng Playwright

**Kết quả mong đợi.** `/dashboard` p95 ≤ 2 giây, LCP ≤ 2,5 giây; `/feed/*` p99 ≤ 300 ms; danh sách p95 ≤ 1,5 giây; chi tiết ≤ 1 giây.

:::

#### TC-16-117 · Công bố 50 trang, xuất 100.000 dòng, tự đăng ký và gói sổ kiến trúc <!--k:perf-publish-export-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-16-009, NFR-16-010, NFR-16-015, NFR-16-016 · FR-16-029, FR-16-033, FR-16-044, FR-16-052 · API-16-074, 079, 101, 118.

**Tiền điều kiện, dữ liệu.** T99: báo cáo 50 trang đã `APPROVED`; 100.000 dòng quan sát; `sign-sim` và `worm-sim` sẵn sàng.

**Các bước.**

1. Công bố báo cáo 50 trang, đo từ yêu cầu tới `PUBLISHED` (20 lần)
2. Xuất 100.000 dòng XLSX
3. Xuất 100.000 dòng CSV
4. Ở T98 phát 10 sự kiện/giây và lập gói `ARCH_REGISTRY` `FULL` 1.000 thành phần

**Kết quả mong đợi.** Công bố p95 ≤ 2 phút (gồm dựng PDF, ký, lưu WORM); XLSX ≤ 3 phút; CSV ≤ 1 phút; tệp hợp lệ, `sha256` khớp. Thành phần tự đăng ký xuất hiện ≤ 60 giây p95; dựng và giao gói sổ kiến trúc ≤ 5 phút (không kể trễ hệ quốc gia).

:::

### TS-16-35 · Tái lập, chịu lỗi và giao sự kiện

**Mục tiêu.** Cùng đầu vào cùng kết quả; dừng 1 giờ không mất, không trùng; băm bất biến; giao sự kiện ít nhất một lần.

**Phủ.** NFR-16-008, 011, 012, 013, 017.

#### TC-16-118 · Tính lại cho cùng giá trị <!--k:repro-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** NFR-16-011 · FR-16-019, FR-16-023 · BR-16-034.

**Tiền điều kiện, dữ liệu.** T90; dữ liệu F-KY-1 đóng băng; hai lần tổng hợp liên tiếp cùng phiên bản công thức.

**Các bước.**

1. Chạy tổng hợp `M-2026-10` lần 1
2. Chạy tổng hợp lần 2 (`trigger = RECOMPUTE`)
3. So từng `value`, `status`, `completeness`, `lineage` giữa hai lần

**Kết quả mong đợi.** Mọi `value` giống nhau tới 6 chữ số thập phân (sai số 0), `status`, `completeness` và `inputs[]` trùng; chỉ `runId`, `computedAt` khác.

:::

#### TC-16-119 · Dừng dh-platform 1 giờ, xóa một bản sao khi đang tổng hợp <!--k:chaos-restart-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-16-012, NFR-16-008 · FR-16-010, FR-16-018 · BR-16-012, BR-16-030 · ERR-16-110.

**Tiền điều kiện, dữ liệu.** T95; Kafka giữ 7 ngày; hai bản sao `dh-platform`; luồng 50 sự kiện/giây; một lần tổng hợp đang `RUNNING`.

**Các bước.**

1. Dừng cả hai bản sao 1 giờ trong khi phát sự kiện
2. Bật lại, đợi tiêu thụ bù
3. Khi đang tổng hợp, xóa một pod
4. Đo tỷ lệ API control thành công trong tháng thử

**Kết quả mong đợi.** Bước 2 0 quan sát mất, 0 quan sát trùng (so số sự kiện đã phát). Bước 3 lần tổng hợp dở dang hoàn tất ở bản còn lại hoặc `FAILED` không ghi đè kết quả lần trước; API control vẫn đáp. Sẵn sàng ≥ 99,5 % mỗi tháng với tối thiểu 2 bản sao.

:::

#### TC-16-120 · Kiểm băm hằng ngày bản công bố 100 % khớp <!--k:immutable-hash-->

::: dac-ta
**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-16-013 · FR-16-029, FR-16-036 · ERR-16-124 · BR-16-009, BR-16-010.

**Tiền điều kiện, dữ liệu.** T90 có 50 báo cáo `PUBLISHED` ở các phiên bản; tác vụ kiểm băm.

**Các bước.**

1. Chạy tác vụ kiểm băm hằng ngày
2. Thử 100 lệnh sửa (`PATCH`, `PUT`, `:refresh`, SQL, ghi đè WORM) lên báo cáo `PUBLISHED`
3. Chạy lại tác vụ

**Kết quả mong đợi.** Lần 1 khớp 100 %. Bước 2 0 lệnh sửa thành công. Lần 3 vẫn khớp 100 %; nếu có sai lệch cài sẵn thì đúng mục sai bị báo ERR-16-124.

:::

#### TC-16-121 · Giao sự kiện ít nhất một lần khi Kafka ngừng <!--k:outbox-lag-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** NFR-16-017 · EVT-16-05, EVT-16-08, EVT-16-12 · FR-16-029, FR-16-051.

**Tiền điều kiện, dữ liệu.** T95; hộp gửi (outbox) bật; Kafka ngừng 10 phút.

**Các bước.**

1. Ngừng Kafka, công bố một báo cáo và đổi trạng thái một gói quốc gia
2. Bật Kafka
3. Đo `kpi_outbox_lag_seconds` và đếm bản tin trên topic

**Kết quả mong đợi.** Sau khi bật lại, mỗi sự kiện được giao ít nhất một lần, bên tiêu thụ xử lý trùng không lỗi (khóa theo `eventId`); trễ outbox p95 ≤ 5 giây khi Kafka bình thường; trạng thái dữ liệu không lệch với sự kiện.

:::

### TS-16-36 · Vòng đầy đủ và truy cập giao diện

**Mục tiêu.** Vòng một kỳ tháng khép kín, diễn tập thiếu nguồn, WCAG 2.2 AA.

**Phủ.** FR-16-018, 020, 024, 029, 038; NFR-16-021.

#### TC-16-122 · Vòng đầy đủ một kỳ tháng <!--k:e2e-cycle-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-16-010, 014, 015, 018, 023, 024, 026, 028, 029, 034 · API-16-030, 032, 040, 050, 057, 065, 071, 072, 074 · UI-16-06, 07, 08, 10, 12 · EVT-16-05, EVT-16-08.

**Tiền điều kiện, dữ liệu.** T90 đã kế thừa 24 chỉ tiêu; nguồn đầy đủ; TO1, SO, TA1, TA2, VW.

**Các bước.**

1. Phát quan sát từ sự kiện và API đẩy
2. TO nhập số tay có bằng chứng, SO xác nhận
3. TO chạy tổng hợp
4. Đẩy một số trễ, đợi tính lại
5. TA chốt kỳ
6. TO lập báo cáo, giải trình, gửi duyệt
7. TA1 duyệt, TA2 công bố ký số lưu WORM
8. Phân phối tới danh sách, VW xem báo cáo

**Kết quả mong đợi.** Mọi bước thành công đúng trạng thái: kỳ `CLOSED`, báo cáo `PUBLISHED` có `contentHash`, chữ ký, `wormRef`; phân phối `SENT`; VW tra được bằng chứng; kiểm toán đủ ở mọi bước; điểm và trạng thái đúng bảng 2.4.

:::

#### TC-16-123 · Diễn tập thiếu nguồn: STALE, PARTIAL, báo cáo chính thức bị chặn <!--k:e2e-missing-->

::: dac-ta
**Loại.** Chịu lỗi, Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** FR-16-013, 020, 026, 028 · API-16-023, 051, 071 · ERR-16-107, ERR-16-111, ERR-16-029 · BR-16-007, BR-16-008 · UI-16-05, UI-16-09.

**Tiền điều kiện, dữ liệu.** T94; tắt nguồn PH-13 một ngày (`clock-sim`); chỉ tiêu bắt buộc phụ thuộc PH-13.

**Các bước.**

1. Đẩy đồng hồ 27 giờ không có số PH-13
2. Chạy tổng hợp
3. Lập báo cáo `PERIODIC` và gửi duyệt
4. Bật PH-13, đẩy số, tính lại, gửi duyệt lại

**Kết quả mong đợi.** Nguồn `STALE`, cờ `STALE_SOURCE`, chỉ tiêu liên quan `NO_DATA`, lần tổng hợp `PARTIAL`, không điền số; gửi duyệt báo cáo bị `422` ERR-16-029. Sau khi có số, tính lại đủ, gửi duyệt thành công. Bảng điều khiển luôn có nhãn `PARTIAL` trong thời gian thiếu.

:::

#### TC-16-124 · Khả năng truy cập WCAG 2.2 AA trên UI-16-01…20 <!--k:a11y-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** NFR-16-021 · UI-16-01…20.

**Tiền điều kiện, dữ liệu.** Playwright, axe-core; NVDA; dữ liệu F-KY-1, F-KT.

**Các bước.**

1. Chạy axe-core trên 20 màn ở chế độ sáng và tối
2. Duyệt bằng bàn phím UI-16-01, 04, 07, 12, 16, 17
3. Đọc biểu đồ chỉ tiêu bằng NVDA
4. Kiểm bảng số thay thế và nhãn trạng thái

**Kết quả mong đợi.** 0 lỗi mức nghiêm trọng của axe-core; mọi thao tác chính dùng được bằng bàn phím, thứ tự tab đúng; mọi biểu đồ có bảng số thay thế; trạng thái `ON_TRACK`, `AT_RISK`, `OFF_TRACK`, `NO_DATA` có nhãn chữ, không chỉ dùng màu.

:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Mỗi phiên 90 phút do kiểm thử viên cùng cán bộ tổng hợp thật thực hiện, tập trung vào nhầm kỳ, nhầm phiên bản công thức khi tính lại, đọc sai nhãn `PARTIAL` và sai thứ tự ở vòng duyệt, công bố.

### 6.2. Tính tay chỉ tiêu và điểm

Trước mỗi lần phát hành, kiểm thử viên tính tay `httt-ket-noi-ty-le` (150/200 → 75,000000), điểm nhóm và điểm tổng theo bảng 2.4 (66,50) từ quan sát thô rồi so với màn UI-16-01; lệch 0,01 là lỗi S2.

### 6.3. Kiểm chứng bản công bố bằng công cụ ngoài

Cán bộ ATTT tải bản công bố và bằng chứng (ca rep-evidence), tự tính SHA-256, kiểm chữ ký bằng phần mềm đọc PDF ký số và đối chiếu thể thức NĐ 30/2020.

### 6.4. Diễn tập sự cố

Diễn tập ở STAGING ba tình huống: dịch vụ ký số gián đoạn khi công bố; PH-14 từ chối hàng loạt; tắt PH-13 một ngày.

## 7. Nghiệm thu người dùng

PH-16 là năng lực mới nên không có nghiệm thu "tương đương hệ cũ". Quản trị tỉnh, cán bộ tổng hợp, cán bộ ATTT, lãnh đạo (VW) của tỉnh thí điểm tự thực hiện trên UAT với dữ liệu `T68` (hồ sơ GĐ-04); đạt khi làm được không cần hướng dẫn ngoài tài liệu. Cột "Liên quan hệ cũ" ghi bảng thống kê rời của hệ cũ (FRS mục 11.1).

| Mã | Việc cần làm | Liên quan hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem bảng điều khiển, mở chi tiết một chỉ tiêu và truy tới quan sát | LGC-APIM-026, LGC-PAY-013, LGC-PAY-020 | Điểm, năm nhóm, trạng thái đúng; chỉ tiêu thiếu số có nhãn; truy tới quan sát gốc | FR-16-038, 039, 040 | TS-16-20 |
| UAT-02 | Kế thừa bộ chỉ tiêu mẫu, soạn và duyệt bốn mắt một chỉ tiêu | — | Chỉ tiêu `ACTIVE`, người duyệt khác người soạn, bản mẫu không sửa trực tiếp | FR-16-002…005, 008 | TS-16-02, 03, 04 |
| UAT-03 | Đăng ký nguồn, theo dõi độ tươi, nhập số tay kèm bằng chứng và xác nhận | LGC-BUS-027 | Nguồn đúng trạng thái; số tay `ACCEPTED` do người khác xác nhận, vào tính toán | FR-16-009, 013, 014, 015 | TS-16-05, 08 |
| UAT-04 | Chạy tổng hợp, đọc nhãn `PARTIAL`, tính lại khi có số trễ, chốt kỳ | — | Kết quả, cờ thiếu nguồn, kỳ `CLOSED`, số trễ không đổi kỳ đã chốt | FR-16-018, 020, 023, 024 | TS-16-09, 10, 11 |
| UAT-05 | Lập báo cáo, giải trình chỉ tiêu chệch, duyệt bốn mắt và công bố ký số | — | Báo cáo `PUBLISHED` có mã băm, chữ ký; bị chặn khi thiếu số bắt buộc | FR-16-026, 027, 028, 029 | TS-16-13, 14, 15 |
| UAT-06 | Đính chính báo cáo đã công bố và tải bằng chứng | — | Phiên bản mới, bản cũ `SUPERSEDED` còn tra được; bằng chứng kiểm chứng được | FR-16-030, 031, 036 | TS-16-16, 17 |
| UAT-07 | Xem sổ kiến trúc, đánh giá tuân thủ bốn mắt, đối chiếu thành phần mồ côi | LGC-HUB-001…004 | Thành phần tự đăng ký, mức tuân thủ đổi sau xác nhận, mồ côi được tìm ra | FR-16-043, 044, 047, 048 | TS-16-23, 24, 26 |
| UAT-08 | Lập và gửi gói báo cáo, sổ kiến trúc qua PH-14 và gửi lại khi lỗi | LGC-NGSP-004 | Có biên nhận; gửi lại không tạo bản trùng; nhật ký nộp đủ | FR-16-051, 052, 053 | TS-16-28, 29 |

: Kịch bản nghiệm thu UAT-01…08 theo vai trò

## 8. Ma trận truy vết

Ma trận sinh tự động từ chính các ca bằng `ph16/tools/gen_matrix.py` nên luôn khớp với chương 4 và 5; ô "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-16.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-16. FR mức M phải có ít nhất một ca ở mỗi cột; FR mức S, C chỉ cần một ca (dấu "—" ở cột Đạt nghĩa là chưa có ca âm, không bắt buộc).

| FR | Mức | Dương | Âm | Đạt |
|---|---|---|---|---|
| FR-16-001 | M | 001 | 002 | Có |
| FR-16-002 | M | 005 | 006 | Có |
| FR-16-003 | M | 007 | 008 | Có |
| FR-16-004 | M | 009 | 010 | Có |
| FR-16-005 | M | 011, 013 | 012, 013 | Có |
| FR-16-006 | S | 014 | 014 | Có |
| FR-16-007 | S | 003, 051 | 004 | Có |
| FR-16-008 | M | 015, 017 | 016, 017 | Có |
| FR-16-009 | M | 018, 022 | 019, 022 | Có |
| FR-16-010 | M | 023, 025, 122 | 024, 025, 026 | Có |
| FR-16-011 | M | 027 | 027 | Có |
| FR-16-012 | S | 025 | 025, 026 | Có |
| FR-16-013 | M | 020, 022, 123 | 022 | Có |
| FR-16-014 | M | 029, 031, 122 | 030, 031 | Có |
| FR-16-015 | M | 032, 122 | 033 | Có |
| FR-16-016 | S | 028 | 028 | Có |
| FR-16-017 | M | 035, 037 | 036 | Có |
| FR-16-018 | M | 040, 122 | 041 | Có |
| FR-16-019 | M | 044, 045, 046, 049, 118 | 047 | Có |
| FR-16-020 | M | 048, 123 | 047 | Có |
| FR-16-021 | M | 049, 050 | 050 | Có |
| FR-16-022 | S | 051 | — | — |
| FR-16-023 | M | 042, 044, 118, 122 | 043 | Có |
| FR-16-024 | M | 037, 039, 122 | 038 | Có |
| FR-16-025 | M | 052 | 053 | Có |
| FR-16-026 | M | 054, 122, 123 | 055 | Có |
| FR-16-027 | M | 056 | 056 | Có |
| FR-16-028 | M | 058, 061, 122, 123 | 059, 060, 061 | Có |
| FR-16-029 | M | 062, 122 | 063, 066 | Có |
| FR-16-030 | S | 039, 067 | 068 | Có |
| FR-16-031 | M | 069 | 069 | Có |
| FR-16-032 | C | 057 | 057 | Có |
| FR-16-033 | M | 071 | 072 | Có |
| FR-16-034 | S | 073, 122 | 073 | Có |
| FR-16-035 | M | 074 | 075 | Có |
| FR-16-036 | S | 070 | 066 | Có |
| FR-16-037 | S | 074 | — | — |
| FR-16-038 | M | 076 | 077 | Có |
| FR-16-039 | M | 078 | 077 | Có |
| FR-16-040 | S | 076 | — | — |
| FR-16-041 | C | 079 | 079 | Có |
| FR-16-042 | S | 080 | — | — |
| FR-16-043 | M | 081 | 081 | Có |
| FR-16-044 | M | 083 | 084, 088 | Có |
| FR-16-045 | S | 087, 089 | 088, 089 | Có |
| FR-16-046 | S | 085 | — | — |
| FR-16-047 | M | 090, 091, 093 | 090, 092, 093 | Có |
| FR-16-048 | S | 086 | — | — |
| FR-16-049 | C | 082 | — | — |
| FR-16-050 | M | 094 | 094 | Có |
| FR-16-051 | M | 095 | 096, 097 | Có |
| FR-16-052 | S | 098 | — | — |
| FR-16-053 | M | 099, 101 | 097, 100 | Có |
| FR-16-054 | C | 102 | — | — |
| FR-16-055 | M | 103 | 104 | Có |
| FR-16-056 | M | 105 | 105 | Có |
| FR-16-057 | S | 106 | 106 | Có |
| FR-16-058 | S | 080 | — | — |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

PH-16 là năng lực mới, không có `LGC` do PH-16 làm chính; chín mục dưới là bảng thống kê rời của hệ cũ mà PH-16 nâng thành chỉ tiêu định kỳ (FRS mục 11.1). Ca ở cột "TC" kiểm phần PH-16 bổ sung (chỉ tiêu, báo cáo, sổ kiến trúc), không kiểm chức năng của hệ cũ.

| LGC | FR của PH-16 | TC | UAT |
|---|---|---|---|
| LGC-APIM-026 | 010, 011, 038 | 023, 025, 027, 076, 122 | UAT-01 |
| LGC-PAY-013 | 010, 038 | 023, 025, 076, 122 | UAT-01 |
| LGC-PAY-020 | 010, 038 | 023, 025, 076, 122 | UAT-01 |
| LGC-HUB-001 | 010, 044 | 023, 025, 083, 122 | UAT-07 |
| LGC-HUB-002 | 010, 044 | 023, 025, 083, 122 | UAT-07 |
| LGC-HUB-003 | 010, 044 | 023, 025, 083, 122 | UAT-07 |
| LGC-HUB-004 | 010, 044 | 023, 025, 083, 122 | UAT-07 |
| LGC-BUS-027 | 011, 038 | 027, 076 | UAT-03 |
| LGC-NGSP-004 | 051, 053 | 095, 099, 101 | UAT-08 |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Quy tắc nghiệp vụ → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-16-001 | 007, 045, 078 |
| BR-16-002 | 005, 011, 044, 045, 076, 094 |
| BR-16-003 | 011, 013, 111 |
| BR-16-004 | 057, 058, 060, 063, 111 |
| BR-16-005 | 032, 033, 111 |
| BR-16-006 | 029, 030 |
| BR-16-007 | 020, 047, 048, 074, 076, 123 |
| BR-16-008 | 054, 059, 123 |
| BR-16-009 | 062, 066, 067, 074, 120 |
| BR-16-010 | 062, 066, 070, 106, 120 |
| BR-16-011 | 037, 039, 042 |
| BR-16-012 | 023, 025, 027, 119 |
| BR-16-013 | 023, 035 |
| BR-16-014 | 046 |
| BR-16-015 | 009, 049 |
| BR-16-016 | 003, 051, 076 |
| BR-16-017 | 050 |
| BR-16-018 | 015, 016, 017 |
| BR-16-019 | 024 |
| BR-16-020 | 079, 108 |
| BR-16-021 | 094, 095, 096, 097, 098, 101, 109 |
| BR-16-022 | 095, 099 |
| BR-16-023 | 083, 088, 107 |
| BR-16-024 | 091, 092, 093, 098, 111 |
| BR-16-025 | 088, 089 |
| BR-16-026 | 071, 072, 074, 082 |
| BR-16-027 | 052, 062, 071 |
| BR-16-028 | 026, 113 |
| BR-16-029 | 054, 056, 059 |
| BR-16-030 | 037, 040, 041, 048, 119 |
| BR-16-031 | 106 |
| BR-16-032 | 105, 112 |
| BR-16-033 | 044, 050 |
| BR-16-034 | 007, 009, 045, 049, 118 |
| BR-16-035 | 034 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

Mã `ERR-16-105…125` là lỗi vận hành (thu thập, tính toán, gửi, dọn dữ liệu), không có mã HTTP; ca kiểm ở trạng thái nguồn, cờ lần tổng hợp, nhật ký tiếp nhận, thông báo PH-13 thay cho mã HTTP.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-16-001 | 002, 069, 070, 072, 077, 081, 100, 107 |
| ERR-16-002 | 006, 016, 019, 053, 055, 088 |
| ERR-16-003 | 006, 008, 010, 028, 055, 056, 068, 082, 086, 093 |
| ERR-16-004 | 004 |
| ERR-16-005 | 013, 033, 060, 063, 068, 092, 111 |
| ERR-16-006 | 006, 022, 027, 030, 063, 066, 068, 089, 099, 100 |
| ERR-16-007 | 012, 013, 014, 022, 028, 033, 038, 041, 043, 060 (+4) |
| ERR-16-008 | 008 |
| ERR-16-009 | 008 |
| ERR-16-010 | 010 |
| ERR-16-011 | 008, 012 |
| ERR-16-012 | 004 |
| ERR-16-013 | 014 |
| ERR-16-014 | 016 |
| ERR-16-015 | 019 |
| ERR-16-016 | 019 |
| ERR-16-017 | 022 |
| ERR-16-018 | 030 |
| ERR-16-019 | 030 |
| ERR-16-020 | 031 |
| ERR-16-021 | 031, 033 |
| ERR-16-022 | 030, 041, 043 |
| ERR-16-023 | 041, 043 |
| ERR-16-024 | 036 |
| ERR-16-025 | 037, 038 |
| ERR-16-026 | 038 |
| ERR-16-027 | 053 |
| ERR-16-028 | 055 |
| ERR-16-029 | 059, 123 |
| ERR-16-030 | 059 |
| ERR-16-031 | 064 |
| ERR-16-032 | 056, 066 |
| ERR-16-033 | 057 |
| ERR-16-034 | 072, 082 |
| ERR-16-035 | 072 |
| ERR-16-036 | 073 |
| ERR-16-037 | 026, 072, 075, 107, 108 |
| ERR-16-038 | 079 |
| ERR-16-039 | 084, 088 |
| ERR-16-040 | 088 |
| ERR-16-041 | 088 |
| ERR-16-042 | 089 |
| ERR-16-043 | 092 |
| ERR-16-044 | 093 |
| ERR-16-045 | 090 |
| ERR-16-046 | 096 |
| ERR-16-047 | 094 |
| ERR-16-048 | 096 |
| ERR-16-049 | 097 |
| ERR-16-050 | 101 |
| ERR-16-051 | 104 |
| ERR-16-052 | 096 |
| ERR-16-053 | 030 |
| ERR-16-054 | 014 |
| ERR-16-055 | 017 |
| ERR-16-056 | 086, 102 |
| ERR-16-057 | 002, 069, 075, 077, 081 |
| ERR-16-058 | 006 |
| ERR-16-059 | 033 |
| ERR-16-060 | 027, 105 |
| ERR-16-061 | 059 |
| ERR-16-101 | 026, 107, 113 |
| ERR-16-102 | 024, 025 |
| ERR-16-103 | 025 |
| ERR-16-104 | 037 |
| ERR-16-105 | 024, 028 |
| ERR-16-106 | 021, 027 |
| ERR-16-107 | 020, 048, 123 |
| ERR-16-108 | 021 |
| ERR-16-109 | 047 |
| ERR-16-110 | 041, 119 |
| ERR-16-111 | 048, 123 |
| ERR-16-112 | 029, 048 |
| ERR-16-113 | 065 |
| ERR-16-114 | 065 |
| ERR-16-115 | 072 |
| ERR-16-116 | 073 |
| ERR-16-117 | 101 |
| ERR-16-118 | 101 |
| ERR-16-119 | 084 |
| ERR-16-120 | 086 |
| ERR-16-121 | 085 |
| ERR-16-122 | 106 |
| ERR-16-123 | 112 |
| ERR-16-124 | 066, 100, 120 |
| ERR-16-125 | 106 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-16-001 | 041, 114 |
| NFR-16-002 | 042 |
| NFR-16-003 | 025, 115 |
| NFR-16-004 | 023, 027, 115 |
| NFR-16-005 | 076, 116 |
| NFR-16-006 | 074, 116 |
| NFR-16-007 | 116 |
| NFR-16-008 | 119 |
| NFR-16-009 | 062, 117 |
| NFR-16-010 | 071, 117 |
| NFR-16-011 | 118 |
| NFR-16-012 | 112, 119 |
| NFR-16-013 | 066, 106, 120 |
| NFR-16-014 | 020 |
| NFR-16-015 | 083, 117 |
| NFR-16-016 | 117 |
| NFR-16-017 | 121 |
| NFR-16-018 | 108, 109, 113 |
| NFR-16-019 | 080 |
| NFR-16-020 | 103 |
| NFR-16-021 | 124 |
| NFR-16-022 | 114 |

: Yêu cầu phi chức năng tới test case

### 8.6. Sự kiện → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-16-01 | 011, 013, 017 |
| EVT-16-02 | 014 |
| EVT-16-03 | 020, 021, 022 |
| EVT-16-04 | 032, 034 |
| EVT-16-05 | 040, 042, 121, 122 |
| EVT-16-06 | 050 |
| EVT-16-07 | 058 |
| EVT-16-08 | 062, 064, 067, 073, 109, 121, 122 |
| EVT-16-09 | 061, 067 |
| EVT-16-10 | 083, 085, 087, 089 |
| EVT-16-11 | 091, 093 |
| EVT-16-12 | 095, 098, 099, 101, 109, 121 |
| EVT-16-13 | 071, 072 |
| EVT-16-14 | 037, 039 |

: Sự kiện tới test case

### 8.7. API → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ api này.

| Mã | Test case |
|---|---|
| API-16-001 | 001, 002, 015, 107 |
| API-16-002 | 005, 006, 110 |
| API-16-003 | 001, 002, 005, 009, 015, 107 |
| API-16-004 | 001, 011, 014 |
| API-16-005 | 005, 006, 016 |
| API-16-006 | 011, 014 |
| API-16-007 | 007, 008, 009, 010, 016 |
| API-16-008 | 007, 008 |
| API-16-009 | 007, 008 |
| API-16-010 | 007 |
| API-16-011 | 011, 012 |
| API-16-012 | 011, 013, 110, 111 |
| API-16-013 | 013 |
| API-16-014 | 013 |
| API-16-015 | 014 |
| API-16-016 | 003 |
| API-16-017 | 003, 004 |
| API-16-018 | 015, 016 |
| API-16-019 | 017 |
| API-16-020 | 017 |
| API-16-021 | 018, 020, 107 |
| API-16-022 | 018, 019, 110 |
| API-16-023 | 018, 020, 021, 107, 123 |
| API-16-024 | 018, 028 |
| API-16-025 | 018, 019 |
| API-16-026 | 022 |
| API-16-027 | 022 |
| API-16-028 | 022 |
| API-16-029 | 021, 027 |
| API-16-030 | 025, 026, 107, 115, 122 |
| API-16-031 | 029, 107 |
| API-16-032 | 029, 030, 110, 122 |
| API-16-033 | 029, 107 |
| API-16-034 | 030 |
| API-16-035 | 029, 030 |
| API-16-036 | 031 |
| API-16-037 | 031 |
| API-16-038 | 031 |
| API-16-039 | 029, 030 |
| API-16-040 | 032, 033, 034, 111, 122 |
| API-16-041 | 033 |
| API-16-042 | 023, 024, 027, 028 |
| API-16-043 | 023, 027, 045, 046, 078, 107 |
| API-16-044 | 024, 028 |
| API-16-045 | 028 |
| API-16-046 | 035, 107 |
| API-16-047 | 035, 036 |
| API-16-048 | 035, 037, 048, 107 |
| API-16-049 | 040, 080 |
| API-16-050 | 040, 041, 110, 114, 122 |
| API-16-051 | 040, 041, 048, 107, 114, 123 |
| API-16-052 | 041 |
| API-16-053 | 032, 034, 040, 044, 045, 047, 048, 049 |
| API-16-054 | 044, 045, 046, 078 |
| API-16-055 | 042, 043, 044 |
| API-16-056 | 050 |
| API-16-057 | 037, 038, 039, 122 |
| API-16-058 | 038, 039 |
| API-16-059 | 052 |
| API-16-060 | 052, 053 |
| API-16-061 | 052 |
| API-16-062 | 052, 053 |
| API-16-063 | 052, 053 |
| API-16-064 | 069, 107, 116 |
| API-16-065 | 054, 055, 057, 110, 122 |
| API-16-066 | 039, 054, 056, 062, 067, 069, 107 |
| API-16-067 | 056, 066 |
| API-16-068 | 056, 066 |
| API-16-069 | 042, 066 |
| API-16-070 | 054, 057 |
| API-16-071 | 058, 059, 061, 122, 123 |
| API-16-072 | 058, 060, 111, 122 |
| API-16-073 | 060, 061 |
| API-16-074 | 062, 063, 064, 065, 111, 117, 122 |
| API-16-075 | 067, 068 |
| API-16-076 | 066, 067, 068 |
| API-16-077 | 067, 069, 070, 107 |
| API-16-078 | 011, 032, 058 |
| API-16-079 | 071, 072, 082, 110, 117 |
| API-16-080 | 071, 072, 082, 107 |
| API-16-081 | 071, 072, 082 |
| API-16-082 | 073 |
| API-16-083 | 073 |
| API-16-084 | 073 |
| API-16-085 | 073 |
| API-16-086 | 074, 075, 107, 116 |
| API-16-087 | 074, 075 |
| API-16-088 | 062, 066, 070, 107 |
| API-16-089 | 074 |
| API-16-090 | 051, 076, 077, 107, 116 |
| API-16-091 | 076, 077, 078 |
| API-16-092 | 079, 110 |
| API-16-093 | 080 |
| API-16-094 | 081, 107, 116 |
| API-16-095 | 087, 088, 110 |
| API-16-096 | 081, 083, 085, 089, 093, 107 |
| API-16-097 | 087, 088 |
| API-16-098 | 087 |
| API-16-099 | 087, 088 |
| API-16-100 | 089 |
| API-16-101 | 083, 084, 107, 117 |
| API-16-102 | 090 |
| API-16-103 | 090 |
| API-16-104 | 090 |
| API-16-105 | 091 |
| API-16-106 | 091 |
| API-16-107 | 091, 092 |
| API-16-108 | 091, 092, 110, 111 |
| API-16-109 | 092 |
| API-16-110 | 093 |
| API-16-111 | 086 |
| API-16-112 | 086, 107 |
| API-16-113 | 086 |
| API-16-114 | 094 |
| API-16-115 | 094 |
| API-16-116 | 094 |
| API-16-117 | 094 |
| API-16-118 | 095, 096, 097, 098, 110, 117 |
| API-16-119 | 095 |
| API-16-120 | 095, 098, 099, 107 |
| API-16-121 | 095, 096, 098, 101 |
| API-16-122 | 101 |
| API-16-123 | 095, 099, 101 |
| API-16-124 | 099, 100 |
| API-16-125 | 102 |
| API-16-126 | 102 |
| API-16-127 | 103 |
| API-16-128 | 103, 104, 110 |
| API-16-129 | 105, 107, 110, 112 |
| API-16-130 | 106 |

: API tới test case

### 8.8. Màn hình → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-16 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-16-01 | 049, 051, 074, 076, 124 |
| UI-16-02 | 049, 076, 078, 124 |
| UI-16-03 | 001, 003, 014, 015, 017, 124 |
| UI-16-04 | 005, 007, 009, 011, 124 |
| UI-16-05 | 018, 020, 123, 124 |
| UI-16-06 | 020, 021, 023, 025, 027, 028, 122, 124 |
| UI-16-07 | 029, 031, 032, 122, 124 |
| UI-16-08 | 035, 037, 039, 040, 080, 122, 124 |
| UI-16-09 | 040, 042, 045, 048, 123, 124 |
| UI-16-10 | 039, 054, 067, 069, 070, 071, 095, 122, 124 |
| UI-16-11 | 054, 056, 058, 124 |
| UI-16-12 | 011, 032, 058, 061, 062, 065, 122, 124 |
| UI-16-13 | 052, 073, 124 |
| UI-16-14 | 081, 083, 084, 086, 124 |
| UI-16-15 | 081, 082, 085, 087, 124 |
| UI-16-16 | 090, 091, 093, 124 |
| UI-16-17 | 094, 095, 098, 099, 101, 102, 124 |
| UI-16-18 | 079, 124 |
| UI-16-19 | 103, 124 |
| UI-16-20 | 105, 124 |

: Màn hình tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Ca UT, IT, API nằm trong `dh-platform/src/test/java/vn/datahub/platform/kpi/` và `…/arch/` theo gói con; ca E2E trong `dh-console/e2e/chi-tieu/`; ca k6 trong `dh-platform/perf/kpi/`; ca DB chạy tệp kiểm cô lập của D03-03-PH16. Mỗi ca gắn thẻ `@TC-16-nnn`.

### 9.2. Mẫu ca công thức và trạng thái

Mẫu kiểm công thức, trạng thái theo ngưỡng và điểm tổng theo bảng 2.4.

```java
@Test void trangThaiVaDiemTong() {
    var v = Compute.indicator("httt-ket-noi-ty-le", obs(150), obs(200)); // 75,000000
    assertThat(v.value()).isEqualByComparingTo("75.000000");
    assertThat(v.status()).isEqualTo(AT_RISK);                           // greenFrom 90, amberFrom 70
    var groups = Map.of(KET_NOI, 50.00, CHIA_SE, 100.00, DU_LIEU, 75.00, VAN_HANH, 60.00, KIEN_TRUC, 50.00);
    assertThat(Score.total(groups, Weights.of(30, 20, 20, 15, 15))).isEqualTo(66.50);
}
```

### 9.3. Mẫu ca quét mồi

Ca `aud-no-pii` đặt `DH-CANARY-aud` vào các trường văn bản tự do và số giả `0010990123456` vào `dimensions`, chạy mọi ca ghi, xuất, gói quốc gia, rồi `grep` ở log, vết OTel, kiểm toán, topic, tệp xuất, metric; kỳ vọng 0 kết quả ngoài bản ghi nhập.

### 9.4. Sinh ma trận, Gherkin, bảng tính

Chuỗi lệnh dưới chạy từ `05-kiem-thu/test-case/`.

| Lệnh | Kết quả |
|---|---|
| `python3 ph16/tools/number_tcs.py` | Cấp số `TC-16-nnn`, thay `[[tc:khóa]]` |
| `python3 ph16/tools/fill_doc.py` | Ghi bảng 3.1, 3.2, số kịch bản, số ca và mục 8; in ra stderr FR, BR, ERR, NFR chưa có ca |
| `python3 ph16/tools/gen_gherkin.py` | `ph16/gherkin/ts-16-nn.feature`, `uat-bao-cao-chi-tieu.feature` |
| `python3 ph16/tools/gen_xlsx.py` | `ph16/D05-02-PH16-test-case.xlsx` theo mẫu nghiệm thu |
| `python3 ph16/tools/check_refs.py` | Đối chiếu mã trong tập với FRS và use case |
| `node build/tools/kiem_tra_gherkin.mjs` | Kiểm cú pháp Gherkin (CI) |

: Chuỗi công cụ sinh phần tự động

Bản `.docx` của tài liệu dựng từ `.md` bằng bộ xuất chung của dự án; `.xlsx` và Gherkin là bản để chạy và giao cho người thực hiện sau này.

### 9.5. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối tám tiêu chí ở FRS mục 14 với ca chứng minh.

| Tiêu chí FRS mục 14 | Ca |
|---|---|
| 1. 37 FR mức M có ca dương và ca âm | mục 8.1 |
| 2. Tenant mới kế thừa đủ 24 chỉ tiêu mẫu; chỉ tiêu `AUTO` có giá trị `COMPLETE` | TC-16-015, TC-16-045 |
| 3. Vòng đầy đủ một kỳ tháng | TC-16-122 |
| 4. Diễn tập thiếu nguồn: `STALE`, `PARTIAL`, báo cáo chính thức bị chặn | TC-16-020, TC-16-123, TC-16-059 |
| 5. Báo cáo công bố không sửa được; đính chính; bằng chứng kiểm chứng ngoài hệ thống | TC-16-066, TC-16-067, TC-16-070 |
| 6. NFR-16-001, 003, 005, 011, 012 | TC-16-114, TC-16-115, TC-16-116, TC-16-118, TC-16-119 |
| 7. Sổ kiến trúc tự có thành phần; đánh giá bốn mắt; đối chiếu tìm mồ côi | TC-16-083, TC-16-091, TC-16-086 |
| 8. Gói quốc gia qua PH-14, có biên nhận, gửi lại không trùng | TC-16-095, TC-16-099, TC-16-101 |

: Đối chiếu tiêu chí chấp nhận cấp phân hệ với ca kiểm thử

## 10. Đề nghị đồng bộ và câu hỏi mở

### 10.1. Đề nghị đồng bộ

Các đề nghị phát sinh khi viết ca. FRS 0.2 đã nêu sẵn nội dung của ĐN-TC-01 (VW chỉ thấy `PUBLISHED`, `SUPERSEDED`; TA, AU thấy thêm `WITHDRAWN`, FR-16-031), ĐN-TC-02 (chỉ TA chốt và mở lại kỳ, FR-16-024, mục 3.2) và ĐN-TC-03 (quá 2 giờ không có tin thì `UNKNOWN`, FR-16-046): ba đề nghị này đóng, ca rep-list, per-close-neg, arch-ops đã sửa theo. Năm đề nghị còn lại chưa được hấp thụ.

| Mã | Tài liệu | Đề nghị |
|---|---|---|
| ĐN-TC-04 | D02-03-PH16 FR-16-053 | Ghi quy tắc idempotent của biên nhận trùng `channelMessageId` (không tạo dòng thứ hai hay `409`); ca nat-receipt chấp nhận hai kết quả |
| ĐN-TC-05 | D03-04-PH16 (OpenAPI) | Đồng nhất mã lỗi khi `reason` ngắn hơn `minLength` của lược đồ: ERR-16-003 (`400`) hay ERR-16-007 (`422`); nhiều ca chấp nhận cả hai |
| ĐN-TC-06 | D03-04-PH16 API-16-092 | Ghi `PERM-16-compare` cho PU và cách tạo mã giả (`alias`) ổn định theo kỳ |
| ĐN-TC-07 | D02-08 | Thêm 12 quyền `PERM-16-approve`, `source`, `manual`, `run`, `report`, `export`, `arch`, `arch-assess`, `national`, `compare`, `config`, `audit-read` và các scope `kpi.ingest`, `kpi.read`, `arch.register`, `kpi.national-receipt` |
| ĐN-TC-08 | D05-01 | Thêm nhóm ca "báo cáo bất biến, WORM" vào cổng `RG-1` và nhóm "gửi quốc gia qua PH-14" vào cổng `RG-3` |

: Đề nghị đồng bộ phát sinh từ tập kiểm thử PH-16

### 10.2. Câu hỏi mở

> **Câu hỏi mở Q16-40:** Bộ số liệu UAT dùng số đã ẩn danh của tỉnh thí điểm hay bộ sinh giả; hiện mọi ca dùng F-KY-1, F-KT sinh bằng hạt cố định, số định danh giả dải `0010990xxxxx`.

> **Câu hỏi mở Q16-41:** Môi trường thử thật của PH-14, dịch vụ ký số và kho WORM có sẵn cho kiểm thử tích hợp không; hiện dùng WireMock với kịch bản `ACK`, `REJECT`, `TIMEOUT`, `503` (liên quan Q16-02, Q16-03).

> **Câu hỏi mở Q16-42:** Ngưỡng NFR-16-001 (10 triệu quan sát trong 5 phút) và NFR-16-009 (PDF 50 trang) cần đo thật trên `pg-core` của hạ tầng tỉnh trước khi chốt; hiện đo ở PERF theo giả định GĐ-04.

> **Câu hỏi mở Q16-43:** Giá trị mẫu của gói quốc gia `KPI_REPORT`, `ARCH_REGISTRY` (lược đồ, ánh xạ, mã lý do từ chối) do ai cung cấp khi hệ quốc gia chưa có đặc tả; các ca `ntpl-create`, `nat-kpi` dùng lược đồ thử tự đặt.

> **Câu hỏi mở Q16-44:** So sánh liên tenant ở môi trường thử cần tối thiểu ba tenant có số chính thức cùng phiên bản mẫu; có dùng chung T90, T91, T92, T94 hay cần tenant riêng, và có cần thỏa thuận giữa các tỉnh (Q16-12).

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-26 | Bản đầu: kịch bản TS-16-01…36, test case TC-16, ma trận truy vết, Gherkin, bảng tính |

: Lịch sử phiên bản
