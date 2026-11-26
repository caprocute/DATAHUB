---
ma_tai_lieu: D05-02-PH11
ten: Kịch bản và test case phân hệ PH-11 Quy trình liên thông (BPM)
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-11
mo_ta: Kịch bản và test case chức năng, hiệu năng, bền trạng thái khi khởi động lại, bốn mắt, cô lập tenant, che dữ liệu cá nhân ở tiến độ DVC, idempotency, Saga và tính hạn theo lịch làm việc của phân hệ Quy trình liên thông, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH11 FRS; D02-04-PH11 Use case; D03-06-PH11 Màn hình; D03-04-PH11 API; D03-03-PH11 CSDL; D02-08 Ma trận phân quyền
---

# D05-02-PH11 · Kịch bản và test case Quy trình liên thông

## Tóm tắt cho hội đồng thẩm định

Điều tài liệu chứng minh, độ phủ và nhóm ca bắt buộc đạt trước khi phát hành; số kịch bản, số ca do công cụ sinh lại từ các ca.

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-11 làm đúng mọi yêu cầu của D02-03-PH11 bản 0.2: 66 FR (48 mức M), 38 quy tắc BR-11, 24 yêu cầu phi chức năng, 73 mã lỗi có người gọi hoặc người vận hành nhìn thấy, 21 sự kiện.
- Một hồ sơ liên thông chạy đúng và có thể bù trừ: `LT_KHAI_SINH` chạy đầu cuối ở nhánh thành công, nhánh BHYT lỗi có bù trừ và nhánh bù trừ thất bại chuyển thủ công; `DUYET_KET_NAP_HTTT` do PH-01 khởi tạo, hai cấp duyệt, bốn mắt đúng.
- Trạng thái quy trình không mất: tắt cứng một pod hoặc khởi động lại toàn bộ bản sao không làm mất phiên, không chạy trùng job, không gửi trùng lệnh hay sự kiện.
- Hạn xử lý đúng theo lịch làm việc của tenant (ngày lễ, nghỉ bù, làm bù, tạm dừng khi chờ bổ sung), tenant này không đọc được phiên của tenant khác và Cổng DVC chỉ thấy tiến độ đã che dữ liệu cá nhân.

**Phạm vi.** Gồm <!--gen:so-ts-->35<!--/gen--> kịch bản với <!--gen:so-tc-->171 (TC-11-001…171; 123 ca P1)<!--/gen--> test case và 8 kịch bản nghiệm thu người dùng (UAT-01…08). Mọi FR mức M có ít nhất một ca dương và một ca âm theo mã ERR; ma trận mục 8 sinh bằng `ph11/tools/gen_matrix.py`. Hệ cũ (Viettel 2021) không có BPM (FRS mục 2.6) nên mục 7 là nghiệm thu theo vai trò thay cho nghiệm thu tương đương hệ cũ.

**Căn cứ.** FRS D02-03-PH11, use case D02-04-PH11, API `openapi-bpm.yaml` (137 operation), CSDL `ph11_bpm`, bộ kiểm `ph11_isolation_test.sql`, D03-06-PH11, D02-08; D05-01 (cổng `RG-1…5`); CV 631, NĐ 61/2018 sửa bởi NĐ 107/2021, Luật BVDLCN 91/2025; ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- cô lập tenant ở API, RLS, `tenantId` Flowable, topic Kafka và outbox (TS-11-25);
- bốn mắt và ma trận `PERM-11-*` không có đường vòng, kể cả TA vừa gửi vừa duyệt (TS-11-05, 26);
- không biến `SENSITIVE` dạng rõ ở log, sự kiện, lệnh Kafka, chỉ số, bảng `ACT_*`; tiến độ DVC không lộ ý định, mã luồng, lỗi kỹ thuật, tên cán bộ (TS-11-20, 27);
- khởi tạo, lệnh, kết quả, sự kiện idempotent; chuyển bước và sự kiện cùng giao dịch `ph11_bpm`, engine nguyên tử về hiệu ứng (TS-11-06, 07, 28, 32);
- tắt cứng pod, khởi động lại toàn bộ bản sao (TS-11-29);
- bộ 200 ca lịch mẫu không sai lệch, hạn đúng qua ngày lễ và ngày làm bù (TS-11-14, 31).

Số tải theo giả định GĐ-01 (tỉnh vừa, 200 HTTT) cộng hệ số cao điểm. `dh-platform` chưa có mô-đun `bpm`; các ca là tiêu chí nghiệm thu của Đợt 2.

## 0. Giới thiệu

### 0.1. Mục đích

Kịch bản và test case nghiệm thu PH-11: chức năng, hiệu năng, độ bền trạng thái, an toàn dữ liệu, tuân thủ BPMN 2.0.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư đối chiếu hành vi; cán bộ ATTT kiểm chương 5; chủ đầu tư dùng mục 7 nghiệm thu.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; Saga chuỗi bước bù trừ thay giao dịch phân tán; outbox bảng đệm sự kiện cùng giao dịch; LV làm việc; RLS an toàn theo hàng; canary chuỗi mồi phát hiện rò rỉ; DLCN dữ liệu cá nhân.

### 0.4. Tài liệu tham chiếu

D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH11 FRS; D02-04-PH11 Use case; D03-04-PH11 API; D03-03-PH11 CSDL; D03-06-PH11 Màn hình; D02-08 Ma trận phân quyền; ISO/IEC/IEEE 29119-3.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng (TS-11-01…24); 5 ca phi chức năng (TS-11-25…35); 6 thủ công; 7 nghiệm thu; 8 ma trận; 9 tự động hóa; 10 câu hỏi mở.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là mô-đun `vn.datahub.platform.bpm` của `dh-platform` (Spring Boot 4, Modulith) cùng Flowable 7.x nhúng (ADR 110), schema `ph11_bpm` có RLS và schema `ph11_flowable` của `pg-core`, 137 API dưới `/api/bpm/v1` (API-11-001…137), 21 topic `{tenant}.bpm.*` (EVT-11-01…21) và 23 màn hình dưới `/quy-trinh` (UI-11-01…23). Ngoài phạm vi: luồng PH-04 (bộ trả lời Kafka giả), danh bạ PH-12 và gợi ý AI PH-17 (giả lập), đồ họa bpmn-js (chỉ kiểm bàn phím và kết quả lưu).

### 1.2. Mức kiểm thử

Mức ghi ở trường "Tự động" của từng ca.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Hàm tính hạn theo lịch, bộ kiểm tra tĩnh từng `ruleCode`, bộ che biến, bộ giải ứng viên |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka KRaft, Keycloak, Valkey, WireMock cho PH-12) | Dịch vụ với CSDL, Flowable, outbox, inbox, bộ trả lời PH-04 giả |
| CSDL | DB | `psql` với `ph11_isolation_test.sql` | RLS, bốn mắt, khóa lũy đẳng, bất biến, schema engine |
| Hợp đồng | CT | Spectral, oasdiff, đối chiếu FRS | `openapi-bpm.yaml`, `asyncapi-bpm.yaml` |
| API | API | REST Assured | Mọi API-11 |
| Kafka | KT | `kcat`, client OAUTHBEARER | ACL theo tiền tố, lệnh, kết quả, sự kiện |
| Đầu cuối | E2E | Playwright, axe-core | UI-11-04, 15 và luồng `LT_KHAI_SINH` |
| Hiệu năng | k6 | k6, pgbench | NFR-11-001…006, 013…015, 018, 023, 024 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | NFR-11-008…012; Kafka, PG, PH-04, PH-12 ngừng |
| Bảo mật | ZAP | OWASP ZAP, quét canary | ASVS 5.0 mức 2, rò rỉ giá trị biến |
| Đồng hồ giả | CLK | Bộ chỉnh đồng hồ engine và `due.scan` | Hạn, nhắc, leo thang, hẹn giờ không chờ thực |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường cho các mức ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, CT, API, KT, E2E khói, CLK | `dh-platform` 1 bản sao; PH-04, PH-12, PH-17 là bộ giả; Kafka, PG, Valkey trong Testcontainers |
| STAGING | E2E đầy đủ, Chaos, ZAP, UAT dợt | Giống sản xuất về số bản sao (2…6), chính sách mạng, Flowable async executor |
| PERF | k6, Chaos tải, kiểm 50.000 phiên | `dh-platform` 4 bản sao 4 vCPU, 8 GB; `pg-core` theo D03-09 (giả định 8 vCPU, 32 GB); tenant T97…T99 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** Hợp đồng API-11 và lược đồ sự kiện đã gắn phiên bản; bộ dữ liệu mục 2 nạp được bằng `ph11/seed/` qua API (không chèn SQL, trừ bộ RLS); mô hình `M-KS`, `M-DUYET` phát hành bằng đúng luồng gửi duyệt, duyệt.
- **Ra.** Theo cổng D05-01: `RG-1` mọi ca API, DB, cô lập tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-11-001…024 ở PERF; `RG-4` UAT mục 7 ký và 9 tiêu chí chấp nhận ở FRS §14 đạt.

### 1.5. Quy ước mã và cách trình bày

Kịch bản `TS-11-nn`, test case `TC-11-nnn`; mã không tái sử dụng, ca bị hủy ghi "Đã hủy" và giữ mã. TS-11-01…24 ứng một một với UC-11-01…24; TS-11-25…35 là kịch bản phi chức năng và đầu cuối. Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-11-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py`. Đường dẫn tương đối với `/api/bpm/v1`; người dùng ghi tắt vai trò (mục 2.2); tenant mặc định T90.

| Ký hiệu | Nghĩa |
|---|---|
| ERR-00-403 | `403` do thiếu quyền chức năng `PERM-11-*` hoặc scope; `403` do bốn mắt hoặc phạm vi dữ liệu giữ mã ERR-11-005, 020, 022, 034, 036 |
| ERR-00-401, 428 | `401` thiếu hoặc sai token; `428` thiếu `If-Match` ở thao tác ghi |
| 404-ẩn | `404` ERR-11-001; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa giá trị biến |
| EVT: `loại` | Đúng một bản tin trên `t90.bpm.{loại}.v1`, khóa phân vùng `businessKey`, không chứa giá trị biến, sinh từ outbox cùng giao dịch (BR-11-023) |
| EVT: không | Sau 10 giây không có dòng mới trong `outbox_event` và không có bản tin trên topic liên quan |
| Mồi sạch | Chuỗi canary `DH-CANARY-{ca}` và số định danh giả của ca không xuất hiện ở dạng rõ trong phản hồi, log 5 phút, vết OTel, bảng `ph11_bpm.*` và `ACT_*`, outbox, Kafka, tệp xuất |
| CLK +n | Chỉnh đồng hồ giả tới thời điểm n sau mốc, rồi đợi một chu kỳ quét `11.due.scanMinutes` |

: Ký hiệu viết tắt trong kết quả mong đợi


### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi theo mức S1…S4 của D05-01; kết quả ghi ở cột "Kết quả" của `.xlsx`. Lỗi nhóm P1 chặn phát hành; mỗi lỗi S1, S2 sửa xong thêm một ca hồi quy tự động.

## 2. Dữ liệu kiểm thử

Dữ liệu giả lập: tên hư cấu, số định danh dải giả `0010990xxxxx`. Nạp bằng `ph11/seed/` qua API, trừ khối RLS ở mức CSDL.

### 2.1. Tenant

Tenant kiểm thử dải `T90…T99`, không dùng tenant sản xuất; topic T90 là `t90.bpm.*`.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant chính | Có `M-KS` v3 `PUBLISHED`, `M-DUYET` v1 `PUBLISHED`, biểu mẫu, ý định, lịch `LICH-T90-2027`; tham số mặc định theo FRS §8.2 |
| `T91` | Tenant đối chứng rò rỉ | Cùng `processKey`, `businessKey`, `formKey` với T90 nhưng dữ liệu khác; mọi ca chéo tenant |
| `T92` | Tham số nhỏ | `11.task.bulkMax = 5`, `11.instance.startRatePerClient = 5`, `11.model.maxXmlKb = 256`, `11.callActivity.maxDepth = 2`, `11.saga.maxRetries = 2`, `11.saga.retryBackoffSeconds = 30`, `11.delegation.maxDays = 7`, `11.message.bufferMinutes = 2` |
| `T93` | Chưa khai lịch 2027 | Cho ERR-11-116 |
| `T94` | Bộ 200 ca lịch | Lịch có ngày lễ, nghỉ bù, làm bù, nghỉ đột xuất; `F-LICH-200` |
| `T95` | Chịu lỗi | Cho Chaos: Kafka, PG, PH-04, PH-12 ngừng, tắt pod |
| `T96` | Tiến độ DVC, DLCN | Biến `SENSITIVE`, canary, client DVC hai loại |
| `T97`…`T99` | Hiệu năng | T97 khởi tạo và hoàn thành việc; T98 50.000 phiên `RUNNING`; T99 lịch sử, xuất, dọn |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

Trong ca, người dùng ghi tắt vai trò, tiền tố `U-T90-` được bỏ; `U-T91-` ghi đủ.

| Mã | Vai trò | Ghi chú |
|---|---|---|
| TA, TA2 | TA | Quản trị tỉnh; TA có cả quyền soạn lẫn duyệt (chỉ SIT) để kiểm bốn mắt độc lập |
| TO | TO | Vận hành; `PERM-11-instance`, `task-admin`, `compensate` |
| IE1, IE2 | IE | Kỹ sư tích hợp (soạn); IE1 gửi, IE2 sửa cuối nháp |
| IA1, IA2 | IA | Người duyệt phát hành, khác IE |
| AU, VW | AU, VW | Kiểm toán có `audit-read`; người xem chỉ `read` |
| CB-TP, CB-TP2, CB-CT, CB-BH, CB-VT, CB-LD, CB-SO | CB | Cán bộ Tư pháp (hai người), Công an cư trú, BHXH, Văn thư, lãnh đạo đơn vị (cấp phòng), cán bộ cấp sở; nhóm ứng viên theo PH-12 giả |
| U-T91-IE1, U-T91-CB1 | IE, CB | Đối chứng chéo tenant ở T91 |
| PA, PA2 | PA | Nền tảng; sở hữu mẫu `COMMON` |
| S-DVC | Máy | Cổng DVC: `bpm.instance.start`, `bpm.instance.read`, `bpm.progress.read`; trong `allowedStarters` của `M-KS` |
| S-DVC2 | Máy | Chỉ `bpm.progress.read`; không trong `allowedStarters`; không khởi tạo `M-KS` |
| S-PH01 | Máy | `bpm.instance.start`; `allowedStarters` của `M-DUYET` |
| S-PH04 | Máy | `bpm.service.worker`: nhận `service.requested`, ghi `completed`, `failed` |
| S-MC | Máy | HTTT một cửa: `bpm.task.read` |
| S-T91-DVC | Máy | Client đối chứng của T91 |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu

Bộ dữ liệu có tên, sinh bằng hạt cố định.

| Mã | Nội dung | Tenant |
|---|---|---|
| `M-KS` | `LT_KHAI_SINH` v3 `PUBLISHED`, v4 `DRAFT`: `nhanHoSo` (việc, nhóm `TU_PHAP`), `guiTuPhap` (ý định `dangKyKhaiSinh`, bù trừ `MANUAL` ý định `danhDauChoXuLy`), `guiCuTru` (`dangKyThuongTru`, `AUTO` bù trừ `huyDangKyThuongTru`), `capTheBHYT` (`capTheBHYT`, lỗi nghiệp vụ `BHXH_TU_CHOI`), `traKetQua`; hạn 5 ngày LV; `publicName` ở ba bước đăng ký | T90 |
| `M-DUYET` | `DUYET_KET_NAP_HTTT` v1: `duyetCapPhong` (nhóm `PHONG_TT`), `duyetCapSo` (nhóm `SO_TTTT`, `separateFrom` `duyetCapPhong`), mỗi việc hạn 3 ngày LV; leo thang `duyetCapSo`: mức 1 `NOTIFY_MANAGER` ngay, mức 2 `REASSIGN_GROUP` sau 4 giờ LV | T90 |
| `M-LOI` | Bộ mô hình lỗi mẫu: 20 tệp, mỗi tệp một `ruleCode` của bảng 6.2-c của FRS (16 `ERROR`, 3 `WARNING`, 1 `INFO`) | T90 |
| `X-OK`, `X-SAI`, `X-LON` | BPMN XML hợp lệ; XML sai chuẩn; XML 2.200 KB (vượt 2.048 KB), bản 300 KB cho T92 | T90, T92 |
| `F-DLCN` | Biến `soDinhDanhMe = 001099000123` (`SENSITIVE`), `hoTenTre` chứa canary (`RESTRICTED`), `maXa` (`INTERNAL`) | T90, T96 |
| `HS-nn` | `businessKey` dạng `HS-T90-2026-00nn`; `HS-01`…`HS-20` dùng lần lượt, mỗi ca ghi số dùng | T90 |
| `F-TEP` | `bien-ban.pdf` 1 MB; `shell.exe` đổi đuôi `.pdf`; `lon-25mb.pdf` | T90 |
| `LICH-T90-2027` | Giờ LV 07:30–11:30, 13:30–17:00 thứ Hai…Sáu; `HOLIDAY` 30/4, 1/5 và nghỉ bù 3/5/2027 (30/4 là thứ Sáu); bản `LICH-T90-2027-LB` thêm `MAKEUP_WORKDAY` thứ Bảy 8/5/2027 | T90 |
| `F-LICH-200` | 200 ca (`start`, `due`, `unit`, hạn kỳ vọng tính tay hai người độc lập) trải qua lễ, nghỉ bù, làm bù, nghỉ đột xuất, giờ ngoài giờ | T94 |
| `F-PERF` | 50.000 phiên `RUNNING` rải 12 bước, 20.000 việc mở, 5 triệu dòng `ACT_HI_*` | T98, T99 |

: Bộ dữ liệu kiểm thử

### 2.4. Hệ thống giả lập

Giả lập phân hệ và hệ thống ngoài.

| Hệ thống | Giả lập bằng | Kịch bản |
|---|---|---|
| PH-04 `dh-runtime` | Bộ trả lời Kafka `ph04-sim` | `COMPLETED`, `BUSINESS_ERROR BHXH_TU_CHOI`, `TECHNICAL`, im lặng (hết thời gian), trả hai lần cùng `id`, trả `commandId` lạ, bù trừ lỗi `n` lần |
| PH-12 (người dùng, nhóm, đơn vị) | WireMock | Danh sách thành viên đơn vị, nhóm rỗng, người ngừng hoạt động, lãnh đạo đơn vị có hoặc không |
| PH-10 | Bộ phát sự kiện khởi tạo | Sự kiện đúng lược đồ, sai lược đồ |
| PH-17 | WireMock | Gợi ý đúng, quá `11.ai.timeoutSeconds` |
| PH-13 | Bộ thu kiểm toán và chỉ số | Nhận `audit`, `traceparent`, cảnh báo P1 |
| Cổng DVC | Máy gọi thử `S-DVC` | Khởi tạo, tra tiến độ, báo bổ sung |

: Hệ thống giả lập

### 2.5. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Dữ liệu mỗi ca sinh và dọn bằng khóa `tc-{khóa}` trong tenant; ca dùng lại dữ liệu ca khác nêu ở hậu điều kiện. Ca bảo mật đặt canary `DH-CANARY-{ca}` vào biến `RESTRICTED` và `SENSITIVE`. Đồng hồ giả chỉ dùng ở TEST và STAGING.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-11-01 | Tạo mô hình, bản nháp, so sánh, nhập, xuất và mẫu dùng chung | UC-11-01 | 9 |
| TS-11-02 | Thiết kế BPMN, thuộc tính bước, kiểm tra tĩnh và chạy thử | UC-11-02 | 9 |
| TS-11-03 | Biến, biểu mẫu việc và bảng quyết định | UC-11-03 | 5 |
| TS-11-04 | Ý định nghiệp vụ và hành động bù trừ | UC-11-04 | 4 |
| TS-11-05 | Gửi duyệt, duyệt phát hành bốn mắt, ngừng dùng và thu hồi phiên bản | UC-11-05 | 9 |
| TS-11-06 | Khởi tạo phiên liên thông từ Cổng DVC, sự kiện PH-10 hoặc thủ công | UC-11-06 | 7 |
| TS-11-07 | Thực thi bước tự động qua PH-04 và nhận kết quả | UC-11-07 | 7 |
| TS-11-08 | Chờ thông điệp, hẹn giờ, gửi thông báo và gọi quy trình con | UC-11-08 | 6 |
| TS-11-09 | Tạo việc, phân công và đưa vào hộp "Việc của tôi" | UC-11-09 | 5 |
| TS-11-10 | Nhận việc, xem hồ sơ và hoàn thành việc với biểu mẫu, ý kiến, quyết định | UC-11-10 | 8 |
| TS-11-11 | Trả về bước trước, yêu cầu bổ sung hồ sơ và tạm dừng tính hạn | UC-11-11 | 6 |
| TS-11-12 | Chuyển việc, trao đổi ý kiến và đính kèm tệp trên việc | UC-11-12 | 4 |
| TS-11-13 | Ủy quyền khi vắng mặt và phân công lại hàng loạt | UC-11-13 | 4 |
| TS-11-14 | Quản lý lịch làm việc, tính hạn, nhắc hạn và leo thang quá hạn | UC-11-14 | 9 |
| TS-11-15 | Tra cứu và xem chi tiết phiên | UC-11-15 | 4 |
| TS-11-16 | Tạm dừng, tiếp tục và hủy phiên | UC-11-16 | 6 |
| TS-11-17 | Can thiệp phiên có duyệt: sửa biến, chuyển bước, di trú | UC-11-17 | 4 |
| TS-11-18 | Điều phối bù trừ Saga khi lỗi bước | UC-11-18 | 4 |
| TS-11-19 | Theo dõi nhật ký Saga, xử lý bù trừ thủ công và đối soát định kỳ | UC-11-19 | 5 |
| TS-11-20 | Tra tiến độ hồ sơ cho Cổng DVC và phát sự kiện tiến độ | UC-11-20 | 5 |
| TS-11-21 | Giám sát quy trình, phát hiện tắc nghẽn và báo cáo đúng hạn, trễ hạn | UC-11-21 | 4 |
| TS-11-22 | Xử lý sự cố engine và thử lại | UC-11-22 | 3 |
| TS-11-23 | Cấu hình cảnh báo, tham số `11.*` và chính sách lưu giữ | UC-11-23 | 4 |
| TS-11-24 | Kiểm toán lịch sử bước, nhật ký phân hệ và bằng chứng tuân thủ BPMN 2.0 | UC-11-24 | 5 |
| TS-11-25 | Cô lập tenant: API, RLS, Flowable, Kafka | — | 5 |
| TS-11-26 | Phân quyền theo ma trận PERM-11 và bốn mắt | — | 3 |
| TS-11-27 | Che dữ liệu cá nhân trong biến, sự kiện, lệnh, nhật ký | — | 3 |
| TS-11-28 | Idempotency khởi tạo, lệnh, kết quả, thông điệp, sự kiện | — | 3 |
| TS-11-29 | Bền trạng thái, sống sót khởi động lại, mất một bản sao | — | 4 |
| TS-11-30 | Hiệu năng, tải và quy mô | — | 5 |
| TS-11-31 | Hạn theo lịch làm việc: bộ 200 ca và đầu cuối | — | 2 |
| TS-11-32 | Nhất quán giao dịch, outbox và Saga | — | 2 |
| TS-11-33 | Chịu lỗi tích hợp: CSDL, PH-04, PH-12 | — | 3 |
| TS-11-34 | Truy cập và quan sát | — | 2 |
| TS-11-35 | Nghiệm thu đầu cuối LT_KHAI_SINH và DUYET_KET_NAP_HTTT | — | 3 |
| **Tổng** | | | **171** (123 ca P1) |

: Danh sách 35 kịch bản kèm use case và số ca
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Chuyển hợp lệ theo FRS §4; bảng ghi các chuyển cấm được kiểm ở chương 4.

| Máy trạng thái (FRS §4) | Chuyển cấm được kiểm |
|---|---|
| Phiên bản mô hình | Sửa bản `IN_REVIEW`, `PUBLISHED`; tự duyệt; thu hồi khi còn phiên |
| Phiên quy trình | Tạm dừng, chuyển bước khi COMPENSATING; hủy phiên đã kết thúc |
| Việc người dùng | Hai người cùng nhận; người không nhận hoàn thành |
| Hạn xử lý | Đếm giờ khi PAUSED |
| Bước Saga | DONE khi chưa ghi nhật ký; tự duyệt bỏ qua |
| Sự cố engine | Thử lại sự cố đã đóng |

: Chuyển trạng thái bị cấm được kiểm thử

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu, phạm vi phủ rồi các ca theo mục 1.5; TS-11-01…24 cùng số với UC-11-01…24.


### TS-11-01 · Tạo mô hình, bản nháp, so sánh, nhập, xuất và mẫu dùng chung

**Mục tiêu.** Xác nhận liệt kê, tạo, nhập, xuất mô hình và quản lý bản nháp đúng phạm vi tenant, đúng trạng thái, kèm mẫu `COMMON` chỉ PA quản lý.

**Phủ.** FR-11-001, 002, 006, 010, 015; UC-11-01; API-11-001…009, 015, 024, 041…043; UI-11-01, 02, 03, 05, 10; BR-11-005, 027, 031.

#### TC-11-001 · Liệt kê, tìm kiếm và xem chi tiết mô hình <!--k:model-list-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-001 · API-11-001, 002 · UI-11-01 · BR-11-031 · PERM-11-read

**Tiền điều kiện, dữ liệu.** T90 có `M-KS`, `M-DUYET` và 3 mô hình khác; VW.

**Các bước.**

1. VW gọi `GET /models?page=0&size=2&q=KHAI&status=PUBLISHED&sort=name`
2. VW gọi `GET /models/LT_KHAI_SINH`
3. VW đổi `size=50` và so `totalElements` với số mô hình của T90

**Kết quả mong đợi.** Bước 1 `200`, tối đa 2 phần tử, chỉ `LT_KHAI_SINH`. Bước 2 có `activeVersion = 3`, danh sách phiên bản và `ETag`. Bước 3 `totalElements = 5`, không có mô hình của T91.
:::

#### TC-11-002 · Tham số liệt kê sai và mô hình không tồn tại <!--k:model-list-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-001 · API-11-001, 002 · ERR-11-001, 003

**Tiền điều kiện, dữ liệu.** VW ở T90; `U-T91-IE1` đã tạo `LT_RIENG_T91` ở T91.

**Các bước.**

1. VW gọi `GET /models?size=0`, `size=1000`, `sort=lạ`, `status=FOO`
2. VW gọi `GET /models/KHONG_CO`
3. VW gọi `GET /models/LT_RIENG_T91`

**Kết quả mong đợi.** Bước 1 `400` ERR-11-003, `errors[]` chỉ đúng tham số sai. Bước 2 và 3 `404-ẩn` ERR-11-001, hai thân giống nhau trừ `traceId`.
:::

#### TC-11-003 · Tạo mô hình trống và sửa thuộc tính <!--k:model-create-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-002 · API-11-003, 005 · UI-11-02 · PERM-11-model

**Tiền điều kiện, dữ liệu.** IE1; mã `LT_THU_NGHIEM` chưa dùng.

**Các bước.**

1. IE1 gọi `POST /models` `{processKey:"LT_THU_NGHIEM", name:"Thử nghiệm", groupCode:"HO_TICH"}`
2. IE1 gọi `PATCH /models/LT_THU_NGHIEM` với `If-Match` đúng, đổi `name`

**Kết quả mong đợi.** Bước 1 `201`, `Location`, phiên bản 1 `DRAFT`, `ETag`. Bước 2 `200`, `name` mới, `ETag` đổi. KT: có (`model.create`, `model.update`).

**Hậu điều kiện.** Mô hình `LT_THU_NGHIEM` dùng lại ở TS-11-05.
:::

#### TC-11-004 · Tạo mô hình trùng mã, sai mẫu, lệch ETag <!--k:model-create-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-002 · API-11-003, 005 · ERR-11-002, 003, 004, 006 · ERR-00-403, 428

**Tiền điều kiện, dữ liệu.** IE1, VW; `LT_KHAI_SINH` có sẵn; `LT_CU` đã lưu trữ (`archived`).

**Các bước.**

1. IE1 `POST /models` với `processKey = LT_KHAI_SINH`
2. IE1 `POST /models` với `processKey = lt-khai-sinh` rồi `AB`
3. IE1 `PATCH` không `If-Match`
4. IE1 `PATCH` với `If-Match` cũ
5. IE1 `PATCH /models/LT_CU`
6. VW `POST /models`

**Kết quả mong đợi.** Bước 1 `409` ERR-11-002. Bước 2 `400` ERR-11-003 (hai lần). Bước 3 `428`. Bước 4 `409` ERR-11-004. Bước 5 `409` ERR-11-006. Bước 6 `403` ERR-00-403.

**Thông báo hiển thị.** "Mã LT_KHAI_SINH đã được dùng. Chọn mã khác."
:::

#### TC-11-005 · Tạo bản nháp từ bản phát hành và so sánh hai phiên bản <!--k:draft-diff-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-006 · API-11-007, 008, 009, 015 · UI-11-03, 05 · BR-11-005

**Tiền điều kiện, dữ liệu.** `M-KS` v3 `PUBLISHED`; IE1.

**Các bước.**

1. IE1 gọi `POST /models/LT_KHAI_SINH/versions` `{basedOn:3}`
2. IE1 thêm một service task ở v4 bằng `PUT /versions/4/bpmn`
3. IE1 gọi `GET /versions/4/diff?against=3`
4. VW gọi `GET /versions` rồi `GET /versions/3`

**Kết quả mong đợi.** Bước 1 `201`, v4 `DRAFT`, `basedOn = 3`, XML giống v3. Bước 3 `200` liệt kê 1 phần tử thêm, 0 xóa, cờ thuộc tính đổi. Bước 4 `checksum` v3 không đổi so với trước ca (BR-11-005).
:::

#### TC-11-006 · Nháp thứ hai, so sánh phiên bản lạ, sửa bản đã phát hành <!--k:draft-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-006 · API-11-008, 009, 010, 015 · ERR-11-001, 006 · ERR-00-403 · BR-11-005

**Tiền điều kiện, dữ liệu.** Sau ca `draft-diff` (v4 đang là nháp); VW.

**Các bước.**

1. IE1 gọi lại `POST /versions` `{basedOn:3}`
2. IE1 gọi `GET /versions/4/diff?against=99`
3. IE1 gọi `PUT /versions/3/bpmn`
4. VW gọi `POST /versions`

**Kết quả mong đợi.** Bước 1 `409` ERR-11-006. Bước 2 `404` ERR-11-001. Bước 3 `409` ERR-11-006, `checksum` v3 không đổi. Bước 4 `403` ERR-00-403.
:::

#### TC-11-007 · Nhập BPMN XML, xuất XML và gói quy trình <!--k:import-export-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-010 · API-11-004, 024 · UI-11-02 · BR-11-005, 014 · PERM-11-model, PERM-11-read

**Tiền điều kiện, dữ liệu.** IE1, VW; tệp `X-OK`.

**Các bước.**

1. IE1 gọi `POST /models:import` với `X-OK`
2. VW gọi `GET /versions/1/export?format=bpmn`
3. VW gọi `GET /versions/1/export?format=package`
4. IE1 nhập lại gói thành `LT_NHAP_LAI`

**Kết quả mong đợi.** Bước 1 `201`, `DRAFT`, `checksum` SHA-256 của `X-OK`. Bước 2 XML khớp `checksum`. Bước 3 tệp nén có BPMN, biểu mẫu, ý định, bù trừ, danh sách biến, tệp kê khai có băm. Bước 4 mô hình mới có cùng bộ phần tử, biến, bù trừ.
:::

#### TC-11-008 · Nhập XML sai chuẩn, vượt cỡ, thực thể ngoài <!--k:import-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-010 · API-11-004 · ERR-11-008, 009 · BR-11-014

**Tiền điều kiện, dữ liệu.** IE1; `X-SAI`, `X-LON`; một XML có `<!DOCTYPE>` và thực thể ngoài trỏ `file:///etc/passwd`; T92 có `11.model.maxXmlKb = 256`.

**Các bước.**

1. IE1 nhập `X-SAI`
2. IE1 nhập `X-LON`
3. IE1 nhập XML thực thể ngoài
4. IE1 ở T92 nhập tệp 300 KB

**Kết quả mong đợi.** Bước 1 `400` ERR-11-008. Bước 2 `413` ERR-11-009. Bước 3 `400` ERR-11-008, nội dung tệp hệ thống không xuất hiện trong phản hồi hay log. Bước 4 `413` ERR-11-009.

**Hậu điều kiện.** Không có mô hình mới.
:::

#### TC-11-009 · Mẫu dùng chung COMMON: tạo, phát hành bởi người khác, sao chép, cấm TA sửa <!--k:template-common-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-015, 002 · API-11-041, 042, 043, 003 · UI-11-10 · ERR-11-002, 005, 036 · BR-11-027

**Tiền điều kiện, dữ liệu.** PA, PA2, TA ở T90.

**Các bước.**

1. PA gọi `POST /templates` `{templateCode:"MAU_DUYET_2_CAP"}`
2. PA gọi `POST /templates/MAU_DUYET_2_CAP:publish`
3. PA2 gọi lại `:publish`
4. TA gọi `POST /models` `{fromTemplate:"MAU_DUYET_2_CAP", processKey:"LT_DUYET_RIENG"}`
5. TA gọi `POST /templates` trùng mã và sửa mẫu `COMMON`

**Kết quả mong đợi.** Bước 2 `403` ERR-11-005 (PA tự phát hành). Bước 3 `200` `PUBLISHED`. Bước 4 `201` mô hình riêng `DRAFT`, mẫu không đổi. Bước 5 `409` ERR-11-002, sửa mẫu `403` ERR-11-036.
:::

### TS-11-02 · Thiết kế BPMN, thuộc tính bước, kiểm tra tĩnh và chạy thử

**Mục tiêu.** Xác nhận trình thiết kế lưu đúng, khóa soạn một người, thuộc tính bước chặt, kiểm tra tĩnh chặn đủ lỗi, chạy thử không ảnh hưởng dữ liệu thật.

**Phủ.** FR-11-003, 004, 005, 011; UC-11-02; API-11-009…014, 025…028, 136; UI-11-04, 06; BR-11-003, 005, 008, 014, 015, 034, 035, 036; NFR-11-013.

#### TC-11-010 · Khóa soạn, danh mục phần tử và lưu sơ đồ <!--k:designer-save-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** E2E

**Truy vết.** FR-11-003 · API-11-010, 012, 013, 028 · UI-11-04 · BR-11-005 · PERM-11-model

**Tiền điều kiện, dữ liệu.** v4 `DRAFT` của `M-KS`; IE1, IE2; `11.designer.lockMinutes = 30`.

**Các bước.**

1. IE1 gọi `POST /versions/4:lock`
2. IE1 gọi `GET /element-catalog`
3. IE1 kéo thả một service task, lưu bằng `PUT /versions/4/bpmn` kèm `If-Match`; giao diện tự lưu sau `11.designer.autosaveSeconds` giây
4. IE1 gọi `:unlock`, IE2 gọi `:lock`

**Kết quả mong đợi.** Bước 1 `200`, `lockOwner = IE1`, `lockUntil` sau 30 phút; `:lock` lần nữa của IE1 làm mới `lockUntil`. Bước 2 liệt kê nhóm phần tử hỗ trợ, không có script task. Bước 3 `200`, `checksum` mới, `validationSummary`. Bước 4 hai lệnh `200`.
:::

#### TC-11-011 · Lưu lệch ETag, XML sai, khóa người khác, quyền xem <!--k:designer-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-003 · API-11-010, 012, 136 · EVT-11-20 · ERR-11-004, 008, 009, 016 · ERR-00-403

**Tiền điều kiện, dữ liệu.** IE1 đang giữ khóa v4; IE2, VW.

**Các bước.**

1. IE1 `PUT /bpmn` với `If-Match` cũ
2. IE1 `PUT /bpmn` với `X-SAI`
3. IE1 `PUT /bpmn` với `X-LON`
4. IE2 `PUT /bpmn` khi IE1 đang giữ khóa
5. VW `POST :lock` và `GET /versions/4`
6. IE2 `POST :request-lock`, rồi IE1 `:lock` lại

**Kết quả mong đợi.** Bước 1 `409` ERR-11-004. Bước 2 `400` ERR-11-008. Bước 3 `413` ERR-11-009. Bước 4 `409` ERR-11-016, nêu người đang giữ khóa. Bước 5 `403` ERR-00-403 rồi `200` xem được. Bước 6 `200`, IE1 nhận thông báo, khóa không tự nhả, `lockUntil` dời.

**Thông báo hiển thị.** "{người} đang sửa bản nháp này từ {giờ}. Bạn đang ở chế độ chỉ xem."
:::

#### TC-11-012 · Cấu hình thuộc tính service task, user task, timer, cổng <!--k:element-config-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-004 · API-11-011 · UI-11-04 · BR-11-002, 003, 008, 019, 034

**Tiền điều kiện, dữ liệu.** v4 `DRAFT`; ý định `capTheBHYT` `ACTIVE`; biểu mẫu `BIEU_MAU_TIEP_NHAN` `PUBLISHED`.

**Các bước.**

1. IE1 `PUT /elements/capTheBHYT` `{intentCode, inputMapping, outputMapping, timeout:120, businessErrors:["BHXH_TU_CHOI"]}`
2. IE1 `PUT /elements/nhanHoSo` `{assignment:{type:"CANDIDATE_GROUP", value:"TU_PHAP"}, formKey, due:{value:2, unit:"WORKING_DAY"}}`
3. IE1 `PUT` một timer biên `PT120S`
4. IE1 đọc lại `GET /versions/4`

**Kết quả mong đợi.** Ba `PUT` trả `200`; bản đọc lại giữ đủ thuộc tính; không có địa chỉ hay giao thức HTTT trong cấu hình (BR-11-002).
:::

#### TC-11-013 · Thuộc tính bước sai: ý định, biểu mẫu, biến <!--k:element-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-004 · API-11-011 · ERR-11-001, 011, 014, 015 · BR-11-003

**Tiền điều kiện, dữ liệu.** v4 `DRAFT`; IE1; biểu mẫu `BIEU_MAU_LA` ở `DRAFT`.

**Các bước.**

1. IE1 đặt `intentCode = khongCo`
2. IE1 đặt `formKey = BIEU_MAU_LA`
3. IE1 đặt điều kiện cổng `${soTienLa > 5}`
4. IE1 `PUT /elements/khongCoId`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-011. Bước 2 `422` ERR-11-014. Bước 3 `422` ERR-11-015. Bước 4 `404` ERR-11-001.
:::

#### TC-11-014 · Kiểm tra tĩnh mô hình hợp lệ <!--k:validate-ok-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-005 · API-11-014 · UI-11-04 · NFR-11-013 · BR-11-003

**Tiền điều kiện, dữ liệu.** v4 hợp lệ; một mô hình 200 phần tử hợp lệ.

**Các bước.**

1. IE1 gọi `POST /versions/4:validate?mode=FAST`
2. IE1 gọi `:validate?mode=FULL`
3. IE1 gọi `:validate?mode=FULL` trên mô hình 200 phần tử, đo thời gian

**Kết quả mong đợi.** `200`, `errors = 0`, có thể có WARNING; bản `FULL` kiểm ánh xạ luồng PH-04 đã phát hành, không `INTENT_NO_FLOW`; bước 3 xong ≤ 2 giây (không tính lần gọi PH-04).
:::

#### TC-11-015 · Bộ mô hình lỗi mẫu: mỗi ruleCode một tệp <!--k:validate-rules-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** UT

**Truy vết.** FR-11-005 · API-11-014 · ERR-11-012, 013 · BR-11-003, 008, 014, 015, 034, 035

**Tiền điều kiện, dữ liệu.** `M-LOI` (20 tệp); IE1.

**Các bước.**

1. Với mỗi tệp `M-LOI` mức ERROR, nhập rồi gọi `:validate?mode=FULL`
2. So `ruleCode`, `severity`, `elementId` với kỳ vọng của tệp
3. Chạy lại với `X-OK`

**Kết quả mong đợi.** Mỗi tệp trả đúng một `ruleCode` kỳ vọng, `severity = ERROR`, có `elementId`, câu mô tả. `INTENT_NO_FLOW` kèm ERR-11-012; `RISKY_NO_COMPENSATION` kèm ERR-11-013. `X-OK` không báo lỗi nào (0 dương tính giả).
:::

#### TC-11-016 · Cảnh báo và thông tin không chặn, biên 200 phần tử <!--k:validate-warn-->
::: dac-ta
**Loại.** Dương, Biên

**Ưu tiên.** P2

**Tự động.** UT

**Truy vết.** FR-11-005 · API-11-014, 016 · UI-11-04

**Tiền điều kiện, dữ liệu.** Ba tệp `M-LOI` mức WARNING; mô hình 200 phần tử và 201 phần tử; PH-04 danh mục không trả lời trong 5 giây.

**Các bước.**

1. Kiểm tra từng tệp WARNING
2. Kiểm tra mô hình 200 rồi 201 phần tử
3. Đặt PH-04 danh mục im lặng, chạy `FAST` rồi `FULL`
4. IE1 gửi duyệt bản chỉ có WARNING

**Kết quả mong đợi.** `TASK_NO_DUE`, `SERVICE_NO_TIMEOUT_BOUNDARY`, `NO_PUBLIC_NAME` ở WARNING; `LARGE_MODEL` INFO chỉ ở 201. `FAST` ghi INFO "Chưa kiểm được ánh xạ luồng"; `FULL` chặn ở bước triển khai. Gửi duyệt bản chỉ WARNING được chấp nhận.
:::

#### TC-11-017 · Chạy thử với service task giả lập <!--k:testrun-ok-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-011 · API-11-025, 026, 027 · UI-11-06 · BR-11-036

**Tiền điều kiện, dữ liệu.** v4 hợp lệ; IE1; kịch bản `capTheBHYT = BUSINESS_ERROR BHXH_TU_CHOI`; `11.test.retentionDays = 7`.

**Các bước.**

1. IE1 gọi `POST /versions/4/test-runs` `{scenario, clock:"ACCELERATED"}`
2. IE1 gọi `POST /test-runs/{id}:step` đến kết thúc
3. IE1 gọi `GET /test-runs/{id}`
4. Đếm bản tin trên `t90.bpm.*` và `GET /instances`
5. CLK +8 ngày

**Kết quả mong đợi.** `test_run` `PASSED` hoặc `FAILED` theo kịch bản, có dòng thời gian từng bước và Saga. Không bản tin Kafka, không dòng outbox, không lệnh PH-04, `GET /instances` không có phiên thử. Sau 8 ngày phiên thử bị dọn.
:::

#### TC-11-018 · Chạy thử lỗi: còn lỗi tĩnh, thiếu kịch bản, thiếu quyền <!--k:testrun-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-011 · API-11-025 · ERR-11-010, 042 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Một nháp còn lỗi `ERROR`; v4 hợp lệ; IE1, VW.

**Các bước.**

1. IE1 chạy thử nháp còn lỗi
2. IE1 chạy thử v4 mà không khai kịch bản cho `guiTuPhap`
3. VW chạy thử

**Kết quả mong đợi.** Bước 1 `422` ERR-11-010. Bước 2 `422` ERR-11-042. Bước 3 `403` ERR-00-403.

**Thông báo hiển thị.** "Chưa có kết quả giả lập cho bước guiTuPhap."
:::

### TS-11-03 · Biến, biểu mẫu việc và bảng quyết định

**Mục tiêu.** Xác nhận biểu mẫu, biến và phân loại dữ liệu đúng, bản phát hành bất biến, bảng quyết định cho rẽ nhánh.

**Phủ.** FR-11-012, 016, 017; UC-11-03; API-11-029…033, 044…048; UI-11-04, 08; BR-11-005, 014.

#### TC-11-019 · Tạo, phát hành, bất biến biểu mẫu <!--k:form-publish-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-012 · API-11-029, 030, 031, 032, 033 · UI-11-08 · BR-11-005 · PERM-11-model

**Tiền điều kiện, dữ liệu.** IE1; mã `BIEU_MAU_TIEP_NHAN` chưa dùng.

**Các bước.**

1. IE1 `POST /forms` `{formKey, schema (30 trường), decisions:["APPROVE","REJECT","RETURN"]}`
2. IE1 `PUT /forms/BIEU_MAU_TIEP_NHAN/versions/1` thêm trường
3. IE1 `POST .../versions/1:publish`
4. IE1 `PUT /versions/1` lần nữa
5. IE1 `GET /forms/BIEU_MAU_TIEP_NHAN`

**Kết quả mong đợi.** Bước 3 `200` `PUBLISHED`, có `checksum`. Bước 4 `409` ERR-11-006. Bước 5 có phiên bản 1 `PUBLISHED`; sửa phải tạo phiên bản 2 `DRAFT`.
:::

#### TC-11-020 · Biểu mẫu trùng mã, schema sai, ánh xạ biến chưa khai <!--k:form-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-012 · API-11-030, 031, 032 · ERR-11-001, 002, 003, 006, 015

**Tiền điều kiện, dữ liệu.** Sau `form-publish`; `U-T91-IE1`.

**Các bước.**

1. IE1 `POST /forms` trùng `formKey`
2. IE1 `POST /forms` với schema không phải JSON Schema
3. IE1 sửa bản đã `PUBLISHED`
4. IE1 `PUT` ánh xạ trường tới biến `soChuaKhai`
5. `U-T91-IE1` `GET /forms/BIEU_MAU_TIEP_NHAN`

**Kết quả mong đợi.** Bước 1 `409` ERR-11-002. Bước 2 `400` ERR-11-003. Bước 3 `409` ERR-11-006. Bước 4 `422` ERR-11-015. Bước 5 `404-ẩn` ERR-11-001.
:::

#### TC-11-021 · Khai báo biến và phân loại dữ liệu <!--k:var-declare-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-016 · API-11-044, 045 · UI-11-04 · BR-11-014, 015

**Tiền điều kiện, dữ liệu.** v4 `DRAFT`; IE1; `F-DLCN`.

**Các bước.**

1. IE1 `PUT /versions/4/variables` khai `soDinhDanhMe` (`SENSITIVE`), `hoTenTre` (`RESTRICTED`), `maXa` (`INTERNAL`), `ngaySinhTre` (`DATE`)
2. IE1 `GET /versions/4/variables`

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 `soDinhDanhMe` có `encrypt = true`, `mask` đặt sẵn; `maXa` không mã hóa; kiểu `DATE` giữ nguyên.
:::

#### TC-11-022 · Khai báo biến sai <!--k:var-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-016 · API-11-045 · ERR-11-003, 015 · BR-11-014, 015

**Tiền điều kiện, dữ liệu.** v4 `DRAFT`; IE1.

**Các bước.**

1. IE1 khai hai biến cùng tên `maXa`
2. IE1 khai biến `1sai`
3. IE1 khai `SENSITIVE` với `encrypt:false`
4. IE1 dùng `soDinhDanhMe` trong `publicName` rồi `:validate`

**Kết quả mong đợi.** Bước 1 và 2 `400` ERR-11-003. Bước 3 `422` ERR-11-015. Bước 4 `422` ERR-11-010 hoặc kết quả `SENSITIVE_IN_PUBLIC` mức `ERROR`.
:::

#### TC-11-023 · Bảng quyết định cho rẽ nhánh <!--k:dmn-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P3

**Tự động.** API

**Truy vết.** FR-11-017 · API-11-046, 047, 048 · ERR-11-040 · BR-11-005

**Tiền điều kiện, dữ liệu.** IE1.

**Các bước.**

1. IE1 `PUT /decision-tables/LOAI_HO_SO` `{hitPolicy:"FIRST", inputs:["tuoi"], rules:[...]}`
2. IE1 `POST /decision-tables/LOAI_HO_SO:evaluate` `{tuoi:5}`
3. IE1 `PUT` bảng có `hitPolicy` lạ rồi bảng thiếu luật mặc định

**Kết quả mong đợi.** Bước 2 `200` đầu ra theo luật khớp đầu tiên. Bước 3 `422` ERR-11-040 cả hai lần.
:::

### TS-11-04 · Ý định nghiệp vụ và hành động bù trừ

**Mục tiêu.** Xác nhận bước tự động chỉ mang ý định, ánh xạ sang luồng PH-04 theo môi trường, và bước rủi ro có bù trừ khác bước xuôi.

**Phủ.** FR-11-013, 014; UC-11-04; API-11-034…040; UI-11-09; BR-11-002, 003, 008, 009, 010.

#### TC-11-024 · Đăng ký ý định, ánh xạ luồng theo môi trường, ngừng dùng <!--k:intent-register-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-013 · API-11-034, 035, 036, 037, 038 · UI-11-09 · BR-11-002, 003 · PERM-11-model

**Tiền điều kiện, dữ liệu.** IE1; luồng PH-04 `flow-bhyt-test` đã phát hành ở TEST.

**Các bước.**

1. IE1 `POST /intents` `{intentCode:"capTheBHYT", inputSchema, outputSchema, writesExternal:true, businessErrors:["BHXH_TU_CHOI"]}`
2. IE1 `PUT /intents/capTheBHYT` gắn `bindings` `TEST → flow-bhyt-test`
3. IE1 `GET /intents/capTheBHYT/bindings`
4. IE1 `POST /intents/capTheBHYT:deprecate`

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `200`. Bước 3 trả ánh xạ theo môi trường, không chứa URL, giao thức, thông tin xác thực của HTTT. Bước 4 `DEPRECATED` khi không còn mô hình `PUBLISHED` dùng.
:::

#### TC-11-025 · Ý định trùng, sai mẫu, luồng chưa phát hành, còn tham chiếu <!--k:intent-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-013 · API-11-035, 036, 037 · ERR-11-002, 003, 012, 037 · BR-11-002, 003

**Tiền điều kiện, dữ liệu.** `M-KS` v3 `PUBLISHED` dùng `capTheBHYT`; luồng `flow-bhyt-draft` chưa phát hành.

**Các bước.**

1. IE1 `POST /intents` với `capTheBHYT`
2. IE1 `POST /intents` với `CapThe`
3. IE1 gắn `bindings` TEST tới `flow-bhyt-draft`
4. IE1 gắn `bindings` chứa `https://httt.example/api`
5. IE1 `:deprecate` ý định đang dùng ở v3

**Kết quả mong đợi.** Bước 1 `409` ERR-11-002. Bước 2 và 4 `400` ERR-11-003. Bước 3 `422` ERR-11-012. Bước 5 `409` ERR-11-037.
:::

#### TC-11-026 · Đăng ký hành động bù trừ theo bước <!--k:comp-register-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-014 · API-11-039, 040 · UI-11-09 · BR-11-008, 009, 010 · PERM-11-model

**Tiền điều kiện, dữ liệu.** v4 `DRAFT`; ý định `huyDangKyThuongTru`, `danhDauChoXuLy` `ACTIVE`.

**Các bước.**

1. IE1 `PUT /versions/4/compensations` cho `guiCuTru` (`AUTO`, `huyDangKyThuongTru`, ghi chú 40 ký tự) và `guiTuPhap` (`MANUAL`, `danhDauChoXuLy`, ghi chú 40 ký tự)
2. IE1 `GET /compensations`
3. IE1 `GET /versions/4/export?format=bpmn`

**Kết quả mong đợi.** Bước 1 `200`. Bước 3 XML có sự kiện bù trừ gắn hai bước và hai service task `isForCompensation`. Hành động do nghiệp vụ nhập, không suy máy móc từ bước xuôi (BR-11-009).
:::

#### TC-11-027 · Bù trừ trỏ chính bước xuôi, thiếu ghi chú, ý định lạ, thiếu bù trừ <!--k:comp-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-014 · API-11-040 · ERR-11-007, 011, 013, 044 · BR-11-008

**Tiền điều kiện, dữ liệu.** v4 `DRAFT`; IE1.

**Các bước.**

1. IE1 đặt bù trừ của `guiCuTru` là `dangKyThuongTru`
2. IE1 đặt ghi chú 8 ký tự
3. IE1 đặt ý định bù trừ `khongCo`
4. IE1 xóa bù trừ `guiTuPhap`, rồi `:validate`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-044. Bước 2 `422` ERR-11-007. Bước 3 `422` ERR-11-011. Bước 4 `RISKY_NO_COMPENSATION` kèm ERR-11-013.
:::

### TS-11-05 · Gửi duyệt, duyệt phát hành bốn mắt, ngừng dùng và thu hồi phiên bản

**Mục tiêu.** Xác nhận phát hành mô hình đi đúng bốn mắt, triển khai nguyên tử lên engine với `tenantId`, phiên cũ không bị ảnh hưởng và bản phát hành bất biến.

**Phủ.** FR-11-007, 008, 009; UC-11-05; API-11-006, 016…023, 131; UI-11-03, 07; BR-11-004, 005, 006, 028, 032, 033; EVT-11-01, 02.

#### TC-11-028 · Gửi duyệt, việc duyệt và rút lại <!--k:submit-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-007 · API-11-016, 017, 018, 019 · UI-11-03, 07 · BR-11-004, 033 · PERM-11-model

**Tiền điều kiện, dữ liệu.** v4 hợp lệ; IE1; IA1, IA2.

**Các bước.**

1. IE1 `POST /versions/4:submit` `{releaseNote:"Thêm bước kiểm tra"}`
2. IA1 `GET /publish-requests` và `GET /tasks`
3. IE1 `PUT /versions/4/bpmn`
4. IE1 `POST /versions/4:withdraw`
5. IE1 gửi lại

**Kết quả mong đợi.** Bước 1 `202`, v4 `IN_REVIEW`, `publish_request` `PENDING` có checksum, nhả khóa soạn. Bước 2 IA1 thấy yêu cầu và một việc `PUBLISH_REVIEW`. Bước 3 `409` ERR-11-006. Bước 4 `WITHDRAWN`, v4 `DRAFT`, việc duyệt `CANCELLED`.
:::

#### TC-11-029 · Gửi duyệt: còn lỗi, thiếu ghi chú, sai trạng thái, người duyệt chỉ định không đủ quyền <!--k:submit-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-007 · API-11-016 · ERR-11-006, 007, 010, 024 · ERR-00-403 · BR-11-033

**Tiền điều kiện, dữ liệu.** Nháp còn lỗi `ERROR`; v3 `PUBLISHED`; IE1, VW; CB-TP không có `PERM-11-publish`.

**Các bước.**

1. IE1 gửi nháp còn lỗi
2. IE1 gửi nháp hợp lệ với ghi chú 5 ký tự
3. IE1 gửi v3
4. IE1 chỉ định `reviewer = CB-TP`
5. VW gửi duyệt

**Kết quả mong đợi.** Bước 1 `422` ERR-11-010. Bước 2 `422` ERR-11-007. Bước 3 `409` ERR-11-006. Bước 4 `422` ERR-11-024. Bước 5 `403` ERR-00-403.

**Thông báo hiển thị.** "Mô hình còn 3 lỗi phải sửa. Xem ngăn Kết quả kiểm tra."
:::

#### TC-11-030 · Duyệt phát hành: triển khai, bản cũ ngừng, phiên cũ giữ phiên bản <!--k:approve-deploy-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-008 · API-11-020 · UI-11-07 · EVT-11-01 · BR-11-004, 005, 006, 032, 033 · PERM-11-publish

**Tiền điều kiện, dữ liệu.** v4 `IN_REVIEW` do IE1 gửi, IE2 sửa cuối; IA1; một phiên `HS-01` đang chạy ở v3.

**Các bước.**

1. IA1 `POST /publish-requests/{id}:approve` `{comment:"Đồng ý, đã đối chiếu luồng PH-04"}`
2. Tra `ACT_RE_DEPLOYMENT` và `ACT_RE_PROCDEF` theo tenant
3. S-DVC `POST /instances` `HS-02`
4. `GET /instances/{HS-01}`

**Kết quả mong đợi.** Bước 1 `200`; v4 `PUBLISHED`, v3 `DEPRECATED`, `publish_request` `APPROVED`; có `deploymentId`, `processDefinitionId`. Bước 2 `tenantId = t90`, tên `LT_KHAI_SINH:v4`. EVT: `model.published` có `checksum`, `publishedBy = IE1`, `approvedBy = IA1`. Bước 3 phiên dùng v4. Bước 4 `HS-01` vẫn v3 (BR-11-006). KT: có (`model.publish`).
:::

#### TC-11-031 · Từ chối phát hành, bản về nháp <!--k:reject-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-008 · API-11-021 · UI-11-07 · BR-11-033

**Tiền điều kiện, dữ liệu.** v5 `IN_REVIEW`; IA1.

**Các bước.**

1. IA1 `POST /publish-requests/{id}:reject` `{comment:"Thiếu bù trừ cho bước gửi Tư pháp, cần bổ sung"}`
2. IE1 `GET /versions/5`

**Kết quả mong đợi.** Bước 1 `200`, `REJECTED`; v5 `DRAFT`; IE1 nhận việc thông báo kèm lý do; không có EVT `model.published`.
:::

#### TC-11-032 · Duyệt vi phạm bốn mắt, thiếu ý kiến, bản đổi, luồng chưa phát hành <!--k:approve-neg-->
::: dac-ta
**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-008 · API-11-020, 021 · ERR-11-004, 005, 007, 010, 012 · BR-11-004, 005

**Tiền điều kiện, dữ liệu.** v6 do IE1 gửi, TA là người sửa cuối; TA có `PERM-11-model` và `PERM-11-publish` (SIT); IA1.

**Các bước.**

1. TA `:approve`
2. IE1 (cấp thêm `PERM-11-publish` ở SIT) `:approve`
3. IA1 `:approve` với `comment` rỗng
4. IA1 `:reject` với `comment` 5 ký tự
5. Sửa `checksum` của v6 ở CSDL, IA1 `:approve`
6. Ngừng luồng PH-04 của `capTheBHYT`, IA1 `:approve` bản hợp lệ

**Kết quả mong đợi.** Bước 1 và 2 `403` ERR-11-005. Bước 3 và 4 `422` ERR-11-007. Bước 5 `409` ERR-11-004, yêu cầu gửi lại. Bước 6 `422` ERR-11-012. Mọi bước v6 vẫn `IN_REVIEW`, không có bản tin `model.published`.

**Thông báo hiển thị.** "Anh/chị đã gửi hoặc sửa bản này nên không được tự duyệt."
:::

#### TC-11-033 · Engine từ chối triển khai <!--k:deploy-fail-->
::: dac-ta
**Loại.** Âm, Chịu lỗi

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-008 · API-11-020 · ERR-11-046 · BR-11-005, 032

**Tiền điều kiện, dữ liệu.** v7 `IN_REVIEW` có XML mà Flowable từ chối; v4 đang `PUBLISHED`; IA1.

**Các bước.**

1. IA1 `:approve`
2. Tra trạng thái v4, v7, `publish_request`, `ACT_RE_DEPLOYMENT`, outbox
3. Ngừng PostgreSQL 10 giây, IA1 `:approve` bản hợp lệ

**Kết quả mong đợi.** Bước 1 `503` hoặc `422` ERR-11-046. Bước 2 v4 vẫn `PUBLISHED`, v7 về `DRAFT`, `publish_request` `DEPLOY_FAILED`, không có deployment mới, không có EVT `model.published`. Bước 3 `503` ERR-11-046, trạng thái không đổi.

**Thông báo hiển thị.** "Không triển khai được lên engine: XML không hợp lệ. Bản đang chạy giữ nguyên."
:::

#### TC-11-167 · Duyệt từng miễn bù trừ khi phát hành <!--k:waiver-decide-->
::: dac-ta
**Loại.** Dương, Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-014, 008 · API-11-020 · UI-11-07 · ERR-11-005, 010 · BR-11-008 · PERM-11-publish

**Tiền điều kiện, dữ liệu.** v5 `IN_REVIEW` có bước `khongBu` `NONE_APPROVED` (ghi chú 30 ký tự) do TA gửi; IA1, TA.

**Các bước.**

1. TA `:approve` với `waiverDecisions[]` chấp nhận `khongBu`
2. IA1 `:approve` với `waiverDecisions[]` không chấp nhận `khongBu`
3. IA1 `:approve` với `waiverDecisions[]` chấp nhận `khongBu`

**Kết quả mong đợi.** Bước 1 `403` ERR-11-005 (người đề nghị không duyệt). Bước 2 `422` ERR-11-010 vì `khongBu` chưa có miễn đã duyệt (`RISKY_NO_COMPENSATION`), v5 vẫn `IN_REVIEW`. Bước 3 v5 `PUBLISHED`, miễn ghi kiểm toán; không có API duyệt miễn riêng.
:::
#### TC-11-034 · Ngừng dùng có xác nhận, khôi phục, thu hồi <!--k:retire-flow-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-009 · API-11-006, 020, 022, 023, 131 · UI-11-03 · EVT-11-02 · BR-11-006, 028 · PERM-11-publish

**Tiền điều kiện, dữ liệu.** `LT_THU_NGHIEM` v1 `PUBLISHED` là bản duy nhất, không có phiên; IA1; TA2.

**Các bước.**

1. IA1 `:deprecate` v1 `{confirmSolePublished:true, reason:"Ngừng thử nghiệm"}`
2. S-DVC `POST /instances` `LT_THU_NGHIEM`
3. IA2 `:restore` (API-11-131), IA1 `:approve` (API-11-020)
4. IA1 `:deprecate` lại rồi `:retire`
5. `GET /models/LT_THU_NGHIEM/versions`

**Kết quả mong đợi.** Bước 1 `DEPRECATED`, EVT `model.retired` `status = DEPRECATED`. Bước 2 `422` ERR-11-017. Bước 3 `202`, sau duyệt v1 về `PUBLISHED`, không triển khai lại. Bước 4 `RETIRED`, `suspendProcessDefinition` đã gọi, EVT `model.retired` `status = RETIRED`.
:::

#### TC-11-035 · Ngừng dùng, thu hồi: bản duy nhất, còn phiên, thiếu lý do, quyền <!--k:retire-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-009 · API-11-022, 023, 131 · ERR-11-006, 007, 017, 037, 038 · ERR-00-403 · BR-11-028

**Tiền điều kiện, dữ liệu.** `M-KS` v3 `DEPRECATED` còn 2 phiên; `M-DUYET` v1 là bản `PUBLISHED` duy nhất; IA1, IE1.

**Các bước.**

1. IA1 `:retire` v3
2. IA1 `:deprecate` `M-DUYET` v1 không có `confirmSolePublished`
3. IA1 `:deprecate` với `reason` 4 ký tự
4. IE1 `:retire`
5. IA1 `:deprecate` `M-DUYET` v1 với `confirmSolePublished:true`, rồi S-PH01 khởi tạo `DUYET_KET_NAP_HTTT`
6. IA1 `:restore` v3 (`M-KS` còn bản `PUBLISHED`), rồi `:restore` `M-DUYET` v1 thiếu lý do

**Kết quả mong đợi.** Bước 1 `409` ERR-11-037. Bước 2 `422` ERR-11-038. Bước 3 `422` ERR-11-007. Bước 4 `403` ERR-00-403. Bước 5 `422` ERR-11-017. Bước 6 `409` ERR-11-006, rồi `422` ERR-11-007.

**Thông báo hiển thị.** "Phiên bản còn 2 hồ sơ đang xử lý. Chờ kết thúc hoặc di trú sang phiên bản mới."
:::

### TS-11-06 · Khởi tạo phiên liên thông từ Cổng DVC, sự kiện PH-10 hoặc thủ công

**Mục tiêu.** Xác nhận khởi tạo phiên idempotent theo `businessKey` và `Idempotency-Key`, nguyên tử với outbox, đúng client được phép, và các kênh sự kiện, thủ công.

**Phủ.** FR-11-018, 019, 020; UC-11-06; API-11-049, 052, 126, 127; UI-11-13; EVT-11-03; BR-11-006, 007, 014, 022, 023; ERR-11-051.

#### TC-11-036 · Khởi tạo phiên qua API từ Cổng DVC <!--k:start-api-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-018, 046, 056 · API-11-049, 052 · EVT-11-03 · BR-11-006, 014, 023 · bpm.instance.start

**Tiền điều kiện, dữ liệu.** S-DVC; `M-KS` v3; `F-DLCN`; `HS-03`; `Idempotency-Key = K-03`.

**Các bước.**

1. S-DVC `POST /instances` `{processKey:"LT_KHAI_SINH", businessKey:"HS-T90-2026-0003", variables:F-DLCN, callbackTopic:"t90.motcua.hoso.ketqua.v1"}`
2. S-DVC `GET /instances:by-key?processKey=LT_KHAI_SINH&businessKey=HS-T90-2026-0003`
3. Tra `instance_index`, `due_tracking`, `outbox_event`, `ACT_RU_VARIABLE_`

**Kết quả mong đợi.** Bước 1 `201`, `instanceId`, `status = RUNNING`, `version = 3`, `dueAt`, `progressUrl`, `Location`. Bước 2 cùng `instanceId`. Bước 3 một dòng mỗi bảng; `due_tracking` `ON_TIME`; EVT: `instance.started` có `startChannel = API`; biến `soDinhDanhMe` chỉ dạng mã hóa, Mồi sạch; việc `nhanHoSo` đã tạo. KT: có (`instance.start`).

**Hậu điều kiện.** `HS-03` dùng lại ở TS-11-07, 09.
:::

#### TC-11-037 · Gửi lại cùng Idempotency-Key và cùng businessKey <!--k:start-idem-->
::: dac-ta
**Loại.** Dương, Biên

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-018 · API-11-049 · BR-11-007, 023 · EVT-11-03

**Tiền điều kiện, dữ liệu.** S-DVC; `HS-04`; thân yêu cầu cố định.

**Các bước.**

1. S-DVC gửi `POST /instances` `HS-04` với `K-04`
2. Gửi lại đúng như vậy
3. Gửi lại với `K-05` cùng thân
4. CLK +25 giờ, gửi lại với `K-04`
5. Đếm `instance_index` và `outbox_event` theo `HS-04`

**Kết quả mong đợi.** Lần 1 `201`. Lần 2 trả đúng phản hồi lần 1. Lần 3 `200` cùng `instanceId`. Lần 4 (quá 24 giờ) `200` cùng phiên đang chạy. Đúng 1 phiên, đúng 1 bản tin `instance.started`.
:::

#### TC-11-038 · Khởi tạo: trùng khác dữ liệu, thiếu bản phát hành, biến sai, client lạ, quá hạn mức <!--k:start-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-018 · API-11-049 · ERR-11-003, 017, 018, 019, 020, 041 · ERR-00-401 · BR-11-007

**Tiền điều kiện, dữ liệu.** Sau `start-idem`; `LT_THU_NGHIEM` không có bản `PUBLISHED`; S-DVC2; T92 `11.instance.startRatePerClient = 5`.

**Các bước.**

1. S-DVC gửi `HS-04` với `variables` khác
2. S-DVC khởi tạo `LT_THU_NGHIEM`
3. S-DVC khởi tạo `LT_KHAI_SINH` thiếu `maXa`, `ngaySinhTre` sai kiểu
4. S-DVC khởi tạo với `businessKey = "ab"`
5. S-DVC2 khởi tạo `LT_KHAI_SINH`
6. Ở T92 gửi 6 lượt trong 1 giây
7. Gọi không token

**Kết quả mong đợi.** Bước 1 `409` ERR-11-018. Bước 2 `422` ERR-11-017. Bước 3 `422` ERR-11-019, liệt kê hai biến. Bước 4 `400` ERR-11-003. Bước 5 `403` ERR-11-020. Bước 6 lượt thứ 6 `429` ERR-11-041 kèm `Retry-After`. Bước 7 `401` ERR-00-401.

**Thông báo hiển thị.** "Hồ sơ HS-T90-2026-0004 đã có phiên đang xử lý với dữ liệu khác."
:::

#### TC-11-168 · Dùng lại Idempotency-Key với nội dung khác <!--k:start-idem-conflict-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-018 · API-11-049 · ERR-11-051 · BR-11-007

**Tiền điều kiện, dữ liệu.** S-DVC; `HS-06`, `HS-07`; khóa `K-06`.

**Các bước.**

1. S-DVC `POST /instances` `HS-06` với `Idempotency-Key = K-06`
2. S-DVC `POST /instances` `HS-07` với cùng `K-06` trong 24 giờ

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `409` ERR-11-051, không có phiên `HS-07`, không có bản tin mới.

**Thông báo hiển thị.** "Khóa Idempotency-Key này đã dùng cho yêu cầu khác. Tạo khóa mới."
:::

#### TC-11-039 · Lỗi giữa giao dịch khởi tạo không để phiên nửa vời <!--k:start-atomic-->
::: dac-ta
**Loại.** Âm, Chịu lỗi

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-018 · API-11-049 · ERR-11-046 · BR-11-023 · EVT-11-03

**Tiền điều kiện, dữ liệu.** Bộ chèn lỗi ở điểm "sau `startProcessInstance`, trước `commit`"; `HS-05`.

**Các bước.**

1. Bật lỗi giả, S-DVC `POST /instances` `HS-05`
2. Đếm `ACT_RU_EXECUTION`, `instance_index`, `due_tracking`, `outbox_event` theo `HS-05`
3. Tắt lỗi, gửi lại cùng `Idempotency-Key`

**Kết quả mong đợi.** Bước 1 `5xx` hoặc `503` ERR-11-046. Bước 2 engine và `ph11_bpm` không chung giao dịch (nguyên tử về hiệu ứng): `instance_index`, `due_tracking`, `outbox_event` 0 dòng, không bản tin Kafka. Bước 3 `201`, tra ngược engine theo `businessKey` rồi dựng bản chiếu, đúng 1 phiên; không gọi lại thì sau 60 giây `StartRecoveryJob` dựng bản chiếu.
:::

#### TC-11-040 · Khởi tạo từ sự kiện PH-10 <!--k:start-event-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-019 · API-11-126 · ERR-11-104, 120 · BR-11-007, 022

**Tiền điều kiện, dữ liệu.** `event-start-binding` `t90.hoso.moi.v1 → LT_KHAI_SINH`; IE1 cấu hình; `HS-06`.

**Các bước.**

1. IE1 `GET /event-start-bindings`
2. PH-10 giả phát sự kiện hợp lệ `HS-06`
3. Phát lại cùng `id` 3 lần
4. Phát sự kiện thiếu `businessKey`

**Kết quả mong đợi.** Bước 2 một phiên `startChannel = EVENT`. Bước 3 không phiên mới, bộ đếm trùng tăng 3 (ERR-11-104 chỉ đếm). Bước 4 không phiên, bản tin vào DLQ, ERR-11-120 hiện ở UI-11-20 "Sự kiện khởi tạo … không hợp lệ: {mô tả}."
:::

#### TC-11-041 · Khởi tạo thủ công trên giao diện <!--k:start-manual-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** E2E

**Truy vết.** FR-11-020 · API-11-127, 049 · UI-11-13 · ERR-11-018, 019, 020 · PERM-11-instance

**Tiền điều kiện, dữ liệu.** TO, VW; `M-KS` cho phép khởi tạo thủ công; `M-DUYET` có `allow_manual_start = false`.

**Các bước.**

1. TO mở UI-11-13, `GET /models/LT_KHAI_SINH/start-form`
2. TO nhập biểu mẫu thiếu `maXa`, rồi đủ, `POST /instances` `{startChannel:"MANUAL"}`
3. TO khởi tạo `DUYET_KET_NAP_HTTT`
4. VW khởi tạo

**Kết quả mong đợi.** Bước 1 `200` có lược đồ. Bước 2 thiếu `422` ERR-11-019, đủ `201` `startChannel = MANUAL`. Bước 3 `403` ERR-11-020. Bước 4 `403` ERR-00-403.
:::

### TS-11-07 · Thực thi bước tự động qua PH-04 và nhận kết quả

**Mục tiêu.** Xác nhận lệnh service task đi qua Kafka và outbox, PH-11 không gọi HTTT, kết quả tương quan đúng, xử lý lỗi nghiệp vụ, kỹ thuật, quá hạn, trùng.

**Phủ.** FR-11-028, 029; UC-11-07; API-11-070, 071; EVT-11-17, 18, 19; BR-11-002, 010, 014, 022, 023; ERR-11-101…107.

#### TC-11-042 · Gửi lệnh thực thi service task <!--k:cmd-send-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** KT

**Truy vết.** FR-11-028 · API-11-070 · EVT-11-17 · BR-11-002, 014, 022, 023

**Tiền điều kiện, dữ liệu.** Phiên `HS-03` ở `nhanHoSo`; CB-TP; `ph04-sim` im lặng; `F-DLCN`.

**Các bước.**

1. CB-TP hoàn thành `nhanHoSo`
2. Đọc bản tin trên `t90.bpm.service.requested.v1`
3. `GET /instances/{id}/service-calls`

**Kết quả mong đợi.** Đúng một lệnh `intentCode = dangKyKhaiSinh`, `commandId` duy nhất, `elementId = guiTuPhap`, `replyTopic`, `timeoutAt`, `payload` là tham chiếu; khóa phân vùng `businessKey`; không có địa chỉ, giao thức HTTT, không có giá trị biến (Mồi sạch). `service_call` `REQUESTED`; phiên `WAITING_SERVICE`.
:::

#### TC-11-043 · Nhận kết quả thành công và đi tiếp <!--k:cmd-result-ok-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-029 · EVT-11-18, 04 · API-11-070 · BR-11-022, 023 · bpm.service.worker

**Tiền điều kiện, dữ liệu.** Sau `cmd-send`; S-PH04.

**Các bước.**

1. `ph04-sim` trả `completed` `{commandId, output:{maHoTich:"KS-0003"}}` trên `t90.bpm.service.completed.v1`
2. Đọc `service_call`, biến, `GET /instances/{id}`, sự kiện tiến độ

**Kết quả mong đợi.** `service_call` `COMPLETED`; biến theo `outputMapping`; phiên sang `guiCuTru` và gửi lệnh kế; EVT: `instance.step.completed` có `publicName`, `elementId`. Trạng thái và bản tin cùng cam kết.
:::

#### TC-11-044 · Kết quả trùng, không tương quan, đã đóng <!--k:cmd-dup-lost-->
::: dac-ta
**Loại.** Âm, Biên

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-029 · API-11-070 · ERR-11-103, 104 · EVT-11-18 · BR-11-022

**Tiền điều kiện, dữ liệu.** Phiên `HS-03` có lệnh `guiCuTru` đang chờ.

**Các bước.**

1. `ph04-sim` trả cùng bản tin `completed` hai lần (cùng `id`)
2. Trả `completed` với `commandId` lạ
3. Trả `completed` cho lệnh `guiTuPhap` đã đóng

**Kết quả mong đợi.** Lần trả thứ hai bỏ qua, bộ đếm trùng +1 (ERR-11-104), phiên đi tiếp đúng một lần, không có bản tin tiến độ thứ hai. Bước 2, 3 ERR-11-103: bản tin vào DLQ, sự cố `CORRELATION_FAILED` `OPEN`.

**Thông báo hiển thị.** "Kết quả của lệnh {commandId} không khớp phiên nào, đã chuyển hàng đợi lỗi."
:::

#### TC-11-045 · Lỗi nghiệp vụ BHXH_TU_CHOI <!--k:cmd-business-error-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-029 · EVT-11-19, 13 · ERR-11-105 · BR-11-010

**Tiền điều kiện, dữ liệu.** `HS-03` ở `capTheBHYT`; `guiTuPhap`, `guiCuTru` đã `DONE`; không có `ERROR_BOUNDARY`.

**Các bước.**

1. `ph04-sim` trả `failed` `{errorKind:"BUSINESS", errorCode:"BHXH_TU_CHOI"}`
2. Đọc `service_call`, dòng thời gian, trạng thái phiên

**Kết quả mong đợi.** `service_call` `FAILED`, `errorKind = BUSINESS`; dòng thời gian "capTheBHYT: cơ quan trả lỗi BHXH_TU_CHOI"; phiên `COMPENSATING`, EVT: `saga.compensation.started`. (Nhánh có biên bắt: token đi nhánh lỗi, không Saga.)
:::

#### TC-11-046 · Lỗi kỹ thuật PH-04, gửi lại lệnh <!--k:cmd-technical-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-029, 028 · API-11-071 · EVT-11-19 · ERR-11-106, 006 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Phiên `HS-07` ở `guiCuTru`; TO, VW.

**Các bước.**

1. `ph04-sim` trả `failed` `{errorKind:"TECHNICAL", attempts:3}`
2. TO `POST /service-calls/{commandId}:resend`
3. `ph04-sim` trả `completed` cho `commandId` mới
4. TO `:resend` lệnh đã `COMPLETED`
5. VW `:resend`

**Kết quả mong đợi.** Bước 1 sự cố mở (ERR-11-106), phiên giữ `WAITING_SERVICE`. Bước 2 `202`, `commandId` mới, lệnh cũ `CANCELLED`. Bước 3 phiên đi tiếp. Bước 4 `409` ERR-11-006. Bước 5 `403` ERR-00-403.
:::

#### TC-11-047 · Quá thời gian chờ kết quả <!--k:cmd-timeout-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-029 · API-11-070 · ERR-11-102 · BR-11-019 · NFR-11-016

**Tiền điều kiện, dữ liệu.** `guiTuPhap` có `timeout = 120` phút; `ph04-sim` im lặng; một bản thử có `TIMER_BOUNDARY`.

**Các bước.**

1. Phiên không biên: CLK +121 phút
2. Phiên có biên: CLK +121 phút

**Kết quả mong đợi.** Phiên không biên: `service_call` `TIMED_OUT`, sự cố `SERVICE_TIMEOUT`, cảnh báo "Bước … chờ PH-04 quá 120 phút." Phiên có biên: token đi nhánh biên, không sự cố.
:::

#### TC-11-048 · Không đẩy được lệnh lên Kafka <!--k:cmd-kafka-down-->
::: dac-ta
**Loại.** Âm, Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** FR-11-028 · EVT-11-17 · ERR-11-101, 107 · BR-11-022, 023

**Tiền điều kiện, dữ liệu.** T95; `11.outbox.maxAttempts = 5`; Chaos Mesh.

**Các bước.**

1. Ngừng Kafka, hoàn thành bước tới `guiTuPhap`
2. Chờ vượt 5 lần thử
3. Phục hồi Kafka
4. TO `:retry` sự cố

**Kết quả mong đợi.** Bước nghiệp vụ không hoàn lại; outbox `PENDING`. Sau 5 lần: sự cố ERR-11-101 "Không gửi được lệnh dangKyKhaiSinh của hồ sơ HS-T90-2026-0004 sau 5 lần." Sau khi Kafka lên và `:retry`, đúng một lệnh với cùng `commandId`; `PH-04` chỉ xử lý một lần; sự cố `RESOLVED`; job hết lượt thử cũng mở ERR-11-107.
:::

### TS-11-08 · Chờ thông điệp, hẹn giờ, gửi thông báo và gọi quy trình con

**Mục tiêu.** Xác nhận thông điệp tương quan idempotent, hẹn giờ chạy và lỗi hẹn giờ thành sự cố, thông báo chỉ phát yêu cầu, quy trình con giới hạn vòng và độ sâu.

**Phủ.** FR-11-030, 031, 032, 033; UC-11-08; API-11-069; EVT-11-20; BR-11-017, 022, 030, 034, 035; ERR-11-108, 109, 118, 123.

#### TC-11-049 · Tương quan thông điệp, thông điệp đến sớm <!--k:msg-correlate-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-030 · API-11-069 · BR-11-022 · bpm.instance.start

**Tiền điều kiện, dữ liệu.** Phiên `HS-08` chờ thông điệp `HO_SO_BO_SUNG`; phiên `HS-09` chưa tới bước chờ; T92 `11.message.bufferMinutes = 2`.

**Các bước.**

1. S-DVC `POST /messages` `{messageId:"M-1", messageName:"HO_SO_BO_SUNG", businessKey:"HS-08"}`
2. Gửi lại cùng `M-1`
3. Gửi `M-2` cho `HS-09` khi chưa tới bước, rồi đưa `HS-09` tới bước trong 1 phút

**Kết quả mong đợi.** Bước 1 `202`, phiên `HS-08` đi tiếp. Bước 2 trả kết quả lần đầu, không đi tiếp lần hai. Bước 3 thông điệp được giữ rồi giao khi phiên tới bước chờ.
:::

#### TC-11-050 · Thông điệp: không có phiên chờ, biến sai, hết thời gian chờ, thiếu scope <!--k:msg-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-030 · API-11-069 · ERR-11-019, 049, 109 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Phiên `HS-10` có `TIMER_BOUNDARY` chờ `HO_SO_BO_SUNG` 1 ngày; S-DVC, S-DVC2.

**Các bước.**

1. S-DVC gửi thông điệp cho `businessKey` không chờ
2. S-DVC gửi thông điệp có biến sai kiểu
3. Ở T92 gửi thông điệp cho phiên chưa tới bước rồi CLK +3 phút
4. CLK +25 giờ cho `HS-10`
5. S-DVC2 gửi thông điệp

**Kết quả mong đợi.** Bước 1 `404` ERR-11-049. Bước 2 `422` ERR-11-019. Bước 3 thông điệp quá đệm bị loại, `404` ERR-11-049. Bước 4 timeline "Hồ sơ HS-T90-2026-0008 hết thời gian chờ thông điệp HO_SO_BO_SUNG." (ERR-11-109). Bước 5 `403` ERR-00-403.

**Thông báo hiển thị.** "Hồ sơ HS-T90-2026-0008 hiện không chờ thông điệp HO_SO_BO_SUNG."
:::

#### TC-11-051 · Hẹn giờ biên, trung gian và khởi tạo <!--k:timer-ok-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** CLK

**Truy vết.** FR-11-031 · BR-11-017, 034 · EVT-11-03

**Tiền điều kiện, dữ liệu.** Bước `choPhanHoi` có hẹn giờ biên `PT24H`; mô hình `LT_NHAC_VIEC` có hẹn giờ khởi tạo cron 07:30 hằng ngày.

**Các bước.**

1. Phiên tới `choPhanHoi`, CLK +24 giờ
2. CLK qua 07:30 hai ngày liên tiếp
3. Ở T92 đặt hẹn giờ 30 giây rồi `:validate`

**Kết quả mong đợi.** Bước 1 biên nổ, việc bị hủy, token rẽ nhánh. Bước 2 hai phiên `startChannel = TIMER`. Bước 3 `TIMER_TOO_SHORT` (nhỏ hơn `11.timer.minSeconds`).
:::

#### TC-11-052 · Job hẹn giờ hết lượt thử <!--k:timer-fail-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-031 · ERR-11-108 · EVT-11-16 · BR-11-019

**Tiền điều kiện, dữ liệu.** Hẹn giờ trỏ biểu thức lỗi chèn bằng CSDL; `11.outbox.maxAttempts` mặc định.

**Các bước.**

1. Phiên tới hẹn giờ lỗi
2. Chờ job hết lượt thử
3. TO xem `GET /incidents`

**Kết quả mong đợi.** Sự cố `TIMER_FAILED` `OPEN` (ERR-11-108), EVT: `incident.opened`, cảnh báo PH-13; phiên không mất.
:::

#### TC-11-053 · Gửi thông báo từ quy trình <!--k:notify-step-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P3

**Tự động.** IT

**Truy vết.** FR-11-032 · EVT-11-20 · ERR-11-123 · BR-11-014, 030

**Tiền điều kiện, dữ liệu.** Mô hình có `SEND_TASK` mẫu `TB_HO_SO_NHAN`; bộ thông báo giả.

**Các bước.**

1. Phiên chạy qua `SEND_TASK`
2. Đọc `t90.bpm.notification.requested.v1`
3. Ngừng bộ thông báo, chạy phiên khác
4. Đặt biến `SENSITIVE` vào `params` rồi `:validate`

**Kết quả mong đợi.** Bước 2 có `templateCode`, `audience`, `channel`, `params` không DLCN; PH-11 không tự gửi. Bước 3 cảnh báo ERR-11-123, phiên vẫn đi tiếp. Bước 4 `SENSITIVE_IN_PUBLIC`.
:::

#### TC-11-054 · Gọi quy trình con, vòng và độ sâu <!--k:call-activity-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P3

**Tự động.** IT

**Truy vết.** FR-11-033 · ERR-11-118 · BR-11-035

**Tiền điều kiện, dữ liệu.** `LT_XAC_MINH` `PUBLISHED`; T92 `11.callActivity.maxDepth = 2`; mô hình vòng A gọi B gọi A; chuỗi sâu 3 cấp; `LT_CON_CHUA` chưa phát hành.

**Các bước.**

1. Phiên `LT_KHAI_SINH` gọi `LT_XAC_MINH`
2. `:validate` mô hình vòng
3. `:validate` chuỗi sâu 3 ở T92
4. Chạy phiên gọi `LT_CON_CHUA`

**Kết quả mong đợi.** Bước 1 phiên con `startChannel = CALL_ACTIVITY`, tiến độ công khai gộp vào bước gọi. Bước 2 `CALL_CYCLE`. Bước 3 `CALL_DEPTH`. Bước 4 sự cố ERR-11-118.
:::

### TS-11-09 · Tạo việc, phân công và đưa vào hộp "Việc của tôi"

**Mục tiêu.** Xác nhận việc tạo đúng ứng viên theo bốn kiểu phân công, loại người vi phạm tách nhiệm vụ, có dự phòng, hiện ở hộp việc đúng hạn.

**Phủ.** FR-11-034, 035; UC-11-09; API-11-072, 125; EVT-11-08, 09; BR-11-016, 020, 031, 037; ERR-11-113, 114.

#### TC-11-055 · Tạo việc theo nhóm, đơn vị, người, quy tắc <!--k:task-create-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-034, 046 · API-11-072 · EVT-11-08, 09 · BR-11-016, 037

**Tiền điều kiện, dữ liệu.** `HS-11` tới `nhanHoSo` (nhóm `TU_PHAP`: CB-TP, CB-TP2); một bước phân công `ORG_UNIT` với PH-12 giả trả 5 thành viên; một bước `USER` = CB-BH.

**Các bước.**

1. Chạy phiên tới từng bước
2. `GET /tasks?instanceId=` của từng ca
3. Sau khi tạo việc `ORG_UNIT`, PH-12 đổi thành viên đơn vị
4. Đọc lại ứng viên

**Kết quả mong đợi.** Nhóm: `UNASSIGNED`, hai ứng viên, `dueAt` 2 ngày LV, EVT: `task.created`. Người: `ASSIGNED`, EVT: `task.assigned` `via` ghi nhận. Đơn vị: 5 ứng viên chụp tại thời điểm tạo, không đổi sau khi PH-12 đổi (BR-11-037).
:::

#### TC-11-056 · Tách nhiệm vụ trong phiên <!--k:task-separate-->
::: dac-ta
**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-034 · BR-11-020 · ERR-11-113

**Tiền điều kiện, dữ liệu.** `DUYET_KET_NAP_HTTT`: CB-LD xử lý `duyetCapPhong`; nhóm `SO_TTTT` gồm CB-LD, CB-SO.

**Các bước.**

1. S-PH01 khởi tạo, CB-LD hoàn thành `duyetCapPhong`
2. `GET /tasks?instanceId=` việc `duyetCapSo`
3. Đổi nhóm `SO_TTTT` chỉ còn CB-LD, tạo phiên mới và lặp lại

**Kết quả mong đợi.** Bước 2 ứng viên chỉ CB-SO. Bước 3 không còn ứng viên hợp lệ: việc vào `VAN_HANH_QUY_TRINH` và có sự cố ERR-11-113; không giao cho CB-LD.
:::

#### TC-11-057 · Không có ứng viên hợp lệ <!--k:task-fallback-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-034 · ERR-11-113 · BR-11-019

**Tiền điều kiện, dữ liệu.** Nhóm `TU_PHAP` rỗng ở PH-12 giả; `11.task.fallbackGroup = VAN_HANH_QUY_TRINH`.

**Các bước.**

1. Chạy phiên tới `nhanHoSo`
2. TO `GET /incidents`
3. TO nhận việc ở nhóm dự phòng

**Kết quả mong đợi.** Việc ở nhóm `VAN_HANH_QUY_TRINH`, sự cố ERR-11-113 hiện ở UI-11-20; TO nhận được việc.

**Thông báo hiển thị.** "Việc nhanHoSo của hồ sơ HS-T90-2026-0011 không có người nhận hợp lệ, đã chuyển nhóm VAN_HANH_QUY_TRINH."
:::

#### TC-11-058 · Việc hiện trong "Việc của tôi" theo phạm vi <!--k:inbox-register-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-035 · API-11-125, 072 · BR-11-014, 031, 037 · NFR-11-015 · bpm.task.read

**Tiền điều kiện, dữ liệu.** Phiên `HS-12` vừa tới `nhanHoSo`; CB-TP, CB-BH; S-MC.

**Các bước.**

1. CB-TP gọi `GET /inbox-items` trong 5 giây
2. CB-BH gọi `GET /inbox-items`
3. S-MC `GET /tasks?orgUnit=TU_PHAP`
4. Hủy phiên `HS-12`, CB-TP gọi lại

**Kết quả mong đợi.** CB-TP thấy việc có nguồn `PH-11`; CB-BH không thấy. S-MC thấy danh sách, không có biến `SENSITIVE`. Sau hủy việc biến mất khỏi hộp trong ≤ 5 giây.
:::

#### TC-11-059 · Hộp việc chung không nhận <!--k:inbox-fail-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-035 · ERR-11-114

**Tiền điều kiện, dữ liệu.** Nhà cung cấp hộp việc FR-00-070 giả trả `503`.

**Các bước.**

1. Chạy phiên tới `nhanHoSo`
2. Đọc cảnh báo UI-11-20
3. Phục hồi nhà cung cấp

**Kết quả mong đợi.** Việc đã tạo trong `task_index`; cảnh báo ERR-11-114 "Không đăng ký được việc vào hộp Việc của tôi"; sau phục hồi việc hiện ở hộp, đúng một lần.
:::

### TS-11-10 · Nhận việc, xem hồ sơ và hoàn thành việc với biểu mẫu, ý kiến, quyết định

**Mục tiêu.** Xác nhận nhận, trả, xem, hoàn thành việc đúng quyền, đúng biểu mẫu, che biến nhạy cảm và gợi ý AI chỉ là gợi ý.

**Phủ.** FR-11-036, 037, 038, 039, 066; UC-11-10; API-11-073…077, 124; UI-11-15; EVT-11-09, 10; BR-11-014, 016, 020, 029, 031, 033.

#### TC-11-060 · Nhận và trả lại việc <!--k:claim-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-036 · API-11-074, 075 · EVT-11-09 · BR-11-016

**Tiền điều kiện, dữ liệu.** Việc `nhanHoSo` `UNASSIGNED`; CB-TP.

**Các bước.**

1. CB-TP `POST /tasks/{id}:claim`
2. CB-TP `POST /tasks/{id}:unclaim`

**Kết quả mong đợi.** Bước 1 `200`, `ASSIGNED`, EVT: `task.assigned` `via = CLAIM`. Bước 2 `UNASSIGNED`, ứng viên khác lại thấy việc.
:::

#### TC-11-061 · Nhận việc: đã có người, không phải ứng viên, phiên tạm dừng <!--k:claim-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-036 · API-11-074 · ERR-11-006, 021, 022

**Tiền điều kiện, dữ liệu.** Việc có hai ứng viên CB-TP, CB-TP2; CB-BH không thuộc nhóm; phiên khác `SUSPENDED`.

**Các bước.**

1. CB-TP và CB-TP2 cùng gửi `:claim` đồng thời
2. CB-BH `:claim`
3. CB-TP `:claim` việc của phiên `SUSPENDED`

**Kết quả mong đợi.** Bước 1 một `200`, một `409` ERR-11-021. Bước 2 `403` ERR-11-022. Bước 3 `409` ERR-11-006.

**Thông báo hiển thị.** "Việc đã được Lan nhận lúc 09:15."
:::

#### TC-11-062 · Xem chi tiết việc, che biến, xem giá trị rõ có lý do <!--k:task-view-->
::: dac-ta
**Loại.** Dương, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-037 · API-11-073, 055 · UI-11-15 · BR-11-014, 031 · PERM-09-unmask

**Tiền điều kiện, dữ liệu.** Việc của `HS-03` (`F-DLCN`); CB-TP, TA có `PERM-09-unmask`, TO.

**Các bước.**

1. CB-TP `GET /tasks/{id}`
2. TA `GET /instances/{id}/variables`
3. TA gọi lại với `reason="Đối chiếu khiếu nại"` và quyền mở che
4. TO gọi lại có lý do

**Kết quả mong đợi.** Bước 1 `maXa` rõ, `soDinhDanhMe` `****`, `hoTenTre` che với người không có quyền. Bước 2 vẫn `****`. Bước 3 giá trị rõ, KT: có (`variable.unmask`, lý do), giao diện tự che lại sau `11.task.unmaskSeconds` giây. Bước 4 vẫn `****` (không `PERM-09-unmask`, BR-11-014).
:::

#### TC-11-063 · Xem việc ngoài phạm vi hoặc không tồn tại <!--k:task-view-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-037 · API-11-073 · ERR-11-001, 022, 034 · BR-11-031

**Tiền điều kiện, dữ liệu.** Việc của đơn vị Tư pháp; CB-BH; `U-T91-IE1`.

**Các bước.**

1. CB-BH `GET /tasks/{id}`
2. CB-BH `GET /tasks/khong-co`
3. `U-T91-IE1` `GET /tasks/{id}`

**Kết quả mong đợi.** Bước 1 `403` ERR-11-034. Bước 2 `404` ERR-11-001. Bước 3 `404-ẩn` ERR-11-001.
:::

#### TC-11-064 · Hoàn thành việc với biểu mẫu, ý kiến, quyết định <!--k:complete-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-038, 046 · API-11-076 · UI-11-15 · EVT-11-10, 04 · BR-11-016, 023, 033 · PERM-11-task

**Tiền điều kiện, dữ liệu.** Việc `nhanHoSo` do CB-TP nhận; có nháp.

**Các bước.**

1. CB-TP `POST /tasks/{id}:complete` `{decision:"COMPLETE", data:{...}, comment:"Hồ sơ đủ"}`
2. Tra `task_index`, `due_tracking`, biến, `GET /instances/{id}`

**Kết quả mong đợi.** `200`; việc `COMPLETED`, nháp xóa, `dueResult = MET`; biến `SENSITIVE` mã hóa; token sang bước sau; EVT: `task.completed` có `decision`, `completedBy`, `dueResult`. KT: có.
:::

#### TC-11-065 · Hoàn thành sai: dữ liệu, ý kiến, người, tách nhiệm vụ, phiên tạm dừng <!--k:complete-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-038 · API-11-076 · ERR-11-005, 006, 007, 022, 023 · BR-11-016, 020, 033

**Tiền điều kiện, dữ liệu.** Việc `duyetCapSo` của CB-SO; CB-LD là người đã xử lý `duyetCapPhong`; một việc của phiên `SUSPENDED`.

**Các bước.**

1. CB-SO `:complete` với dữ liệu sai schema
2. CB-SO `:complete` `REJECT` với `comment` 8 ký tự
3. CB-TP `:complete` việc của CB-SO
4. Cấp thêm CB-LD vào ứng viên bằng CSDL, CB-LD nhận rồi `:complete`
5. CB-TP `:complete` việc phiên `SUSPENDED`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-023, `errors[]` theo trường. Bước 2 `422` ERR-11-007. Bước 3 `403` ERR-11-022. Bước 4 `403` ERR-11-005. Bước 5 `409` ERR-11-006.

**Thông báo hiển thị.** "Anh/chị đã xử lý bước duyệtCapPhong của hồ sơ này nên không được xử lý bước duyệt này."
:::

#### TC-11-066 · Lưu nháp kết quả việc <!--k:draft-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P3

**Tự động.** API

**Truy vết.** FR-11-039 · API-11-077 · ERR-11-004, 022, 023 · BR-11-014

**Tiền điều kiện, dữ liệu.** Việc đang `ASSIGNED` cho CB-TP.

**Các bước.**

1. CB-TP `PUT /tasks/{id}/draft` với `If-Match`
2. Mở lại việc
3. CB-TP `PUT` với `If-Match` cũ
4. CB-BH `PUT`
5. CB-TP `PUT` thân không phải đối tượng

**Kết quả mong đợi.** Bước 1 `200`, bước 2 nháp khớp, `SENSITIVE` mã hóa. Bước 3 `409` ERR-11-004. Bước 4 `403` ERR-11-022. Bước 5 `422` ERR-11-023.
:::

#### TC-11-067 · Gợi ý AI chỉ là gợi ý <!--k:ai-suggest-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P3

**Tự động.** IT

**Truy vết.** FR-11-066 · API-11-124 · ERR-11-124 · BR-11-029, 014 · PERM-17-use

**Tiền điều kiện, dữ liệu.** PH-17 giả; CB-TP có `PERM-17-use`; CB-VT không có; `11.ai.timeoutSeconds = 10`.

**Các bước.**

1. CB-TP `POST /tasks/{id}/ai-suggestions`
2. CB-TP hoàn thành việc theo quyết định khác gợi ý
3. Đặt PH-17 chậm 15 giây, gọi lại
4. CB-VT gọi

**Kết quả mong đợi.** Bước 1 `200` gợi ý, không chứa giá trị `SENSITIVE`. Bước 2 `ai_assisted = true`, quyết định là của cán bộ. Bước 3 ERR-11-124 sau 10 giây, việc xử lý bình thường. Bước 4 `403` ERR-00-403.
:::

### TS-11-11 · Trả về bước trước, yêu cầu bổ sung hồ sơ và tạm dừng tính hạn

**Mục tiêu.** Xác nhận trả về và yêu cầu bổ sung đúng bước, tạm dừng hạn đúng thời gian làm việc và tiếp tục khi công dân bổ sung.

**Phủ.** FR-11-044, 049; UC-11-11; API-11-087, 088, 089; EVT-11-04; BR-11-018, 033; ERR-11-007, 026, 049, 125.

#### TC-11-068 · Trả về bước trước <!--k:return-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-044 · API-11-087 · BR-11-033 · PERM-11-task

**Tiền điều kiện, dữ liệu.** `HS-13` ở `duyetCapSo`; `nhanHoSo` do CB-TP xử lý; CB-SO.

**Các bước.**

1. CB-SO `POST /tasks/{id}:return` `{toElementId:"nhanHoSo", comment:"Thiếu giấy chứng sinh, yêu cầu cán bộ tiếp nhận kiểm tra lại"}`

**Kết quả mong đợi.** `200`; việc cũ `COMPLETED` `decision = RETURN`; việc `nhanHoSo` mới giao lại CB-TP; dòng thời gian ghi lý do.
:::

#### TC-11-069 · Trả về bước không cho phép, thiếu ý kiến, sai trạng thái <!--k:return-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-044 · API-11-087, 088 · ERR-11-006, 007, 026 · BR-11-033

**Tiền điều kiện, dữ liệu.** Việc `duyetCapSo` của CB-SO; một việc của phiên `SUSPENDED`.

**Các bước.**

1. CB-SO `:return` tới bước không nằm trong danh sách cho phép
2. CB-SO `:return` với `comment` 6 ký tự
3. CB-SO `:request-supplement` với `comment` rỗng
4. CB-SO `:return` việc phiên `SUSPENDED`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-026. Bước 2 và 3 `422` ERR-11-007. Bước 4 `409` ERR-11-006.

**Thông báo hiển thị.** "Không trả về được bước khong-co. Chỉ trả về: nhanHoSo."
:::

#### TC-11-070 · Yêu cầu bổ sung, tạm dừng hạn, DVC báo đã bổ sung <!--k:supplement-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** CLK

**Truy vết.** FR-11-044, 049 · API-11-088, 089 · EVT-11-04 · BR-11-017, 018 · bpm.instance.start

**Tiền điều kiện, dữ liệu.** `HS-14` hạn 5 ngày LV; CB-VT; S-DVC; `LICH-T90-2027`; thứ Ba 10:00.

**Các bước.**

1. CB-VT `POST /tasks/{id}:request-supplement` `{comment}` lúc thứ Ba 10:00
2. Đọc `due_tracking`, `GET /progress/HS-14`
3. CLK tới thứ Năm 10:00, S-DVC `POST /instances/{id}:supplement-received`
4. Đọc `due_tracking`

**Kết quả mong đợi.** Bước 1 phiên chờ thông điệp `HO_SO_BO_SUNG`; hạn `PAUSED`, `pauseReason = WAITING_SUPPLEMENT`; EVT: `step.completed` `displayStatus = WAITING_SUPPLEMENT`. Bước 2 tiến độ DVC hiện "Chờ bổ sung". Bước 3 `202`; `pausedDuration = 15` giờ LV (5 + 7,5 + 2,5), `dueAt` dời đúng 15 giờ LV; phiên đi tiếp.
:::

#### TC-11-071 · Báo bổ sung khi phiên không chờ <!--k:supplement-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-049 · API-11-089 · ERR-11-049 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Phiên `HS-15` `RUNNING` không chờ bổ sung; S-DVC, S-DVC2.

**Các bước.**

1. S-DVC `POST /instances/{HS-15}:supplement-received`
2. S-DVC2 gọi cùng API cho phiên đang chờ

**Kết quả mong đợi.** Bước 1 `404` ERR-11-049. Bước 2 `403` ERR-00-403.

**Thông báo hiển thị.** "Hồ sơ HS-T90-2026-0015 hiện không chờ bổ sung."
:::

#### TC-11-169 · Hết hạn bổ sung hồ sơ: không tự hủy, mở sự cố <!--k:supplement-expired-->
::: dac-ta
**Loại.** Âm, Biên

**Ưu tiên.** P1

**Tự động.** CLK

**Truy vết.** FR-11-049, 024, 060 · API-11-088, 109, 058 · ERR-11-125 · EVT-11-16 · BR-11-017 · PERM-11-instance

**Tiền điều kiện, dữ liệu.** `HS-17`; CB-VT; TO; `LICH-T90-2027`.

**Các bước.**

1. CB-VT `:request-supplement` `HS-17` với `deadline` 2 ngày LV
2. CLK +3 ngày LV
3. TO `GET /incidents?type=SUPPLEMENT_EXPIRED`
4. TO `:cancel` phiên `HS-17` kèm lý do

**Kết quả mong đợi.** Bước 2 phiên không tự hủy, hạn giữ `PAUSED`, sự cố `SUPPLEMENT_EXPIRED` `OPEN` ERR-11-125, EVT: `incident.opened`. Bước 3 thấy sự cố ở UI-11-20. Bước 4 `CANCELLED`, sự cố đóng.

**Thông báo hiển thị.** "Hồ sơ HS-T90-2026-0017 quá 2 ngày chưa được bổ sung; đã mở sự cố."
:::

#### TC-11-072 · Tính lại hạn từ đầu khi bổ sung <!--k:supplement-reset-->
::: dac-ta
**Loại.** Biên

**Ưu tiên.** P3

**Tự động.** CLK

**Truy vết.** FR-11-049, 046 · API-11-089 · BR-11-017, 018

**Tiền điều kiện, dữ liệu.** Tenant `T92` với `11.supplement.resetDue = true`; phiên `HS-16` đã dừng 2 ngày.

**Các bước.**

1. S-DVC báo đã bổ sung lúc thứ Năm 10:00
2. Đọc `dueAt`

**Kết quả mong đợi.** `dueAt` là 5 ngày LV tính từ lúc nhận bổ sung (thứ Năm 10:00), không cộng `pausedDuration` kiểu cũ.
:::

### TS-11-12 · Chuyển việc, trao đổi ý kiến và đính kèm tệp trên việc

**Mục tiêu.** Xác nhận chuyển việc đúng người nhận, ý kiến và tệp đính kèm có kiểm tra loại, cỡ, quyền.

**Phủ.** FR-11-040, 043; UC-11-12; API-11-078, 083…086; EVT-11-09; BR-11-014, 020, 025; ERR-11-022, 024, 027.

#### TC-11-073 · Chuyển việc cho người khác <!--k:transfer-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-040 · API-11-078 · EVT-11-09 · BR-11-020 · PERM-11-task, PERM-11-task-admin

**Tiền điều kiện, dữ liệu.** Việc `ASSIGNED` cho CB-TP; CB-TP2 cùng nhóm; TO.

**Các bước.**

1. CB-TP `POST /tasks/{id}:transfer` `{toUser:"CB-TP2", reason:"Nghỉ đột xuất"}`
2. TO chuyển một việc của CB-BH cho CB-TP

**Kết quả mong đợi.** Bước 1 `200`, assignee mới, dòng thời gian ghi người chuyển và lý do, EVT: `task.assigned` `via = TRANSFER`; hộp việc CB-TP2 có, CB-TP mất. Bước 2 `200` nhờ `task-admin`.
:::

#### TC-11-074 · Chuyển việc không hợp lệ <!--k:transfer-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-040 · API-11-078 · ERR-11-024 · ERR-00-403 · BR-11-020

**Tiền điều kiện, dữ liệu.** CB-TP2 ngừng hoạt động ở PH-12 giả; `U-T91-CB1`; việc `duyetCapSo` có `separateFrom`; VW.

**Các bước.**

1. CB-TP chuyển cho chính mình
2. chuyển cho người ngừng hoạt động
3. chuyển cho `U-T91-CB1`
4. chuyển việc cấp sở cho CB-LD (đã xử lý cấp phòng)
5. CB-BH (không phải ứng viên, không `task-admin`) chuyển
6. VW chuyển

**Kết quả mong đợi.** Bước 1 đến 4 `422` ERR-11-024 kèm lý do. Bước 5 `403` ERR-11-022. Bước 6 `403` ERR-00-403.

**Thông báo hiển thị.** "Không chuyển được cho CB-TP2: tài khoản đã ngừng hoạt động."
:::

#### TC-11-075 · Ý kiến và tệp đính kèm <!--k:comment-attach-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P3

**Tự động.** API

**Truy vết.** FR-11-043 · API-11-083, 084, 085, 086 · BR-11-014, 025

**Tiền điều kiện, dữ liệu.** Việc của CB-TP; CB-TP2 cùng nhóm; `bien-ban.pdf` 1 MB; `11.task.attachmentMaxMb = 20`.

**Các bước.**

1. CB-TP `POST /tasks/{id}/comments` có `@CB-TP2`
2. CB-TP `POST /tasks/{id}/attachments` `bien-ban.pdf`
3. CB-TP2 `GET /comments`, `GET /attachments/{id}`

**Kết quả mong đợi.** Bình luận `201`, CB-TP2 nhận nhắc. Tệp `201` có `checksum` SHA-256, quét an toàn đạt; tải về trùng byte và `checksum`; `data_class` của tệp kế thừa từ biểu mẫu.
:::

#### TC-11-076 · Tệp sai loại, quá cỡ, người không có quyền <!--k:attach-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-043 · API-11-085, 086 · ERR-11-022, 027

**Tiền điều kiện, dữ liệu.** `shell.exe` đổi đuôi `.pdf`; `lon-25mb.pdf`; CB-BH không liên quan.

**Các bước.**

1. CB-TP tải `shell.exe` đổi đuôi
2. CB-TP tải `lon-25mb.pdf`
3. CB-BH `GET /attachments/{id}`
4. CB-BH `POST /comments`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-027 (nhận dạng theo nội dung). Bước 2 `413` ERR-11-027. Bước 3 và 4 `403` ERR-11-022.
:::

### TS-11-13 · Ủy quyền khi vắng mặt và phân công lại hàng loạt

**Mục tiêu.** Xác nhận ủy quyền có hiệu lực, hết hạn, thu hồi đúng và giao lại hàng loạt có xem trước, giới hạn và tách nhiệm vụ.

**Phủ.** FR-11-041, 042; UC-11-13; API-11-079…082; UI-11-16, 17; EVT-11-09; BR-11-020; ERR-11-024, 025, 050.

#### TC-11-077 · Ủy quyền hiệu lực, hết hạn, thu hồi <!--k:delegation-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** CLK

**Truy vết.** FR-11-041 · API-11-079, 080, 081 · UI-11-17 · EVT-11-09 · BR-11-020

**Tiền điều kiện, dữ liệu.** CB-TP, CB-TP2; hai việc đang giữ của CB-TP; `11.delegation.maxDays = 30`.

**Các bước.**

1. CB-TP `POST /delegations` `{toUser:"CB-TP2", from:+1 ngày, to:+6 ngày, includeExisting:true}`
2. CLK tới `from`
3. CB-TP2 hoàn thành một việc
4. CLK qua `to`
5. CB-TP tạo ủy quyền mới rồi `POST /delegations/{id}:revoke`

**Kết quả mong đợi.** Bước 1 `SCHEDULED`. Bước 2 `ACTIVE`; việc chuyển `DELEGATED`, CB-TP vẫn thấy. Bước 3 hoàn thành được. Bước 4 `EXPIRED`, việc chưa xong trả CB-TP. Bước 5 `REVOKED`, việc trả về.
:::

#### TC-11-078 · Ủy quyền quá dài, chồng lấn, vòng, khác tenant <!--k:delegation-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-041 · API-11-080 · ERR-11-025 · BR-11-020

**Tiền điều kiện, dữ liệu.** T92 `11.delegation.maxDays = 7`; CB-TP, CB-TP2.

**Các bước.**

1. CB-TP ủy quyền 10 ngày
2. Ủy quyền chồng khoảng với ủy quyền đang có
3. CB-TP ủy quyền cho CB-TP2 rồi CB-TP2 ủy lại cho CB-TP
4. CB-TP ủy quyền cho `U-T91-CB1`

**Kết quả mong đợi.** Cả bốn `422` ERR-11-025 với lý do tương ứng (quá ngày, chồng lấn, vòng, khác tenant).

**Thông báo hiển thị.** "Ủy quyền không hợp lệ: quá 7 ngày."
:::

#### TC-11-079 · Phân công lại hàng loạt có xem trước <!--k:bulk-reassign-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-042 · API-11-082 · UI-11-16 · EVT-11-09 · BR-11-020 · PERM-11-task-admin

**Tiền điều kiện, dữ liệu.** CB-TP đang giữ 4 việc, 1 việc là `duyetCapSo` mà người nhận đích đã xử lý cấp phòng; TO.

**Các bước.**

1. TO `POST /tasks:bulk-reassign` `{filter:{assignee:"CB-TP"}, toUser:"CB-TP2", preview:true}`
2. TO gửi lại với `preview:false`

**Kết quả mong đợi.** Bước 1 `200` xem trước: 3 việc sẽ chuyển, 1 việc bị loại do tách nhiệm vụ. Bước 2 `202`, mỗi việc một giao dịch, kết quả từng việc; EVT: `task.assigned` `via = BULK` cho 3 việc.
:::

#### TC-11-080 · Giao lại quá giới hạn, người đích sai, thiếu quyền <!--k:bulk-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-042 · API-11-082 · ERR-11-024, 050 · ERR-00-403

**Tiền điều kiện, dữ liệu.** T92 `11.task.bulkMax = 5`; 6 việc của CB-TP; TO, CB-TP.

**Các bước.**

1. TO giao lại 6 việc
2. TO giao lại cho người ngừng hoạt động
3. CB-TP gọi `:bulk-reassign`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-050. Bước 2 `422` ERR-11-024. Bước 3 `403` ERR-00-403.

**Thông báo hiển thị.** "Mỗi lần giao lại tối đa 5 việc."
:::

### TS-11-14 · Quản lý lịch làm việc, tính hạn, nhắc hạn và leo thang quá hạn

**Mục tiêu.** Xác nhận lịch làm việc, hạn qua ngày lễ, nghỉ bù, làm bù, ngoài giờ, nhắc và leo thang đúng mốc, không nhắc trùng khi nhiều bản sao.

**Phủ.** FR-11-045, 046, 047, 048; UC-11-14; API-11-090…093; UI-11-18; EVT-11-11, 12; BR-11-011, 017, 019; ERR-11-028, 113, 116, 123.

#### TC-11-081 · Khai và sửa lịch năm, tính lại hạn chưa đóng <!--k:cal-edit-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-045 · API-11-090, 091, 092 · UI-11-18 · BR-11-017 · PERM-11-config

**Tiền điều kiện, dữ liệu.** TA; phiên `HS-17` hạn 5 ngày LV có mốc rơi sau 4/5/2027; lịch `COMMON` 2027 do PA khai.

**Các bước.**

1. TA `POST /calendars/2027:import`
2. TA `PUT /calendars/2027` đặt giờ LV 07:30–11:30, 13:30–17:00, thêm `HOLIDAY` 4/5/2027
3. `GET /calendars`
4. `GET /instances/{HS-17}`

**Kết quả mong đợi.** Bước 1 sao chép ngày lễ `COMMON`, giữ ngày riêng của tỉnh. Bước 2 `200`, `recalculatedDues = n`. Bước 4 `dueAt` của `HS-17` dời đúng một ngày LV. KT: có (ngày thêm, sửa, xóa).
:::

#### TC-11-082 · Lịch sai: trùng ngày, giờ chồng, ngoài năm, thiếu quyền <!--k:cal-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-045 · API-11-091 · ERR-11-028 · ERR-00-403

**Tiền điều kiện, dữ liệu.** TA, TO.

**Các bước.**

1. TA `PUT /calendars/2027` có hai ngày cùng `date`
2. TA đặt giờ LV 07:30–11:30 và 11:00–12:00
3. TA thêm ngày `2028-01-01` vào lịch 2027
4. TO `PUT /calendars/2027`

**Kết quả mong đợi.** Bước 1 đến 3 `422` ERR-11-028 nêu ngày trùng, giờ chồng, ngày ngoài năm. Bước 4 `403` ERR-00-403.

**Thông báo hiển thị.** "Lịch không hợp lệ: ngày trùng 2027-05-04."
:::

#### TC-11-083 · Tính hạn 5 ngày LV qua ngày lễ, nghỉ bù và ngày làm bù <!--k:due-holiday-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** UT

**Truy vết.** FR-11-046 · API-11-093 · UI-11-18 · BR-11-017 · NFR-11-016 · PERM-11-read

**Tiền điều kiện, dữ liệu.** `LICH-T90-2027` và `LICH-T90-2027-LB`; TO.

**Các bước.**

1. TO `POST /calendars:compute-due` `{start:"2027-04-30T16:45+07:00", due:{value:5, unit:"WORKING_DAY"}}` với `LICH-T90-2027`
2. Lặp lại với `LICH-T90-2027-LB`
3. Tạo phiên `LT_KHAI_SINH` tiếp nhận đúng thời điểm đó rồi đọc `dueAt`

**Kết quả mong đợi.** Bước 1 `200`, `dueAt = 2027-05-10T17:00+07:00`; `explain[]` có 30/4 và 1/5 (lễ), 2/5 (Chủ nhật), 3/5 (nghỉ bù), 8/5 và 9/5 (cuối tuần). Bước 2 `dueAt = 2027-05-08T17:00+07:00`, `explain[]` ghi 8/5 là ngày làm bù. Bước 3 `dueAt` giống bước 1.
:::

#### TC-11-084 · Hạn theo giờ làm việc, ngoài giờ, ngày lịch <!--k:due-hours-->
::: dac-ta
**Loại.** Biên

**Ưu tiên.** P2

**Tự động.** UT

**Truy vết.** FR-11-046 · API-11-093 · BR-11-017 · NFR-11-016

**Tiền điều kiện, dữ liệu.** `LICH-T90-2027`; thứ Năm 6/5/2027 và thứ Sáu 7/5/2027.

**Các bước.**

1. `compute-due` start 10:30 thứ Năm, 4 giờ LV
2. start 16:00 thứ Sáu, 4 giờ LV
3. start 17:30 thứ Sáu, 1 ngày LV, `NEXT_WORKING_START`
4. start 10:00 thứ Sáu, 24 `CALENDAR_HOUR`
5. start 10:00 thứ Sáu, 2 `CALENDAR_DAY`

**Kết quả mong đợi.** Bước 1 `16:30` cùng ngày (nghỉ 11:30–13:30). Bước 2 `10:30` thứ Hai sau (1 giờ thứ Sáu và 3 giờ thứ Hai). Bước 3 bắt đầu 07:30 thứ Hai, hạn 17:00 thứ Hai. Bước 4 10:00 thứ Bảy (không bỏ cuối tuần). Bước 5 23:59:59 `Asia/Ho_Chi_Minh` của ngày thứ hai, không phụ thuộc giờ tiếp nhận.
:::

#### TC-11-085 · Năm chưa có lịch: dùng lịch mặc định <!--k:due-no-calendar-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-046 · API-11-093, 090 · ERR-11-116 · UI-11-18

**Tiền điều kiện, dữ liệu.** T93 chưa khai lịch 2027; TO.

**Các bước.**

1. TO `POST /calendars:compute-due` ở T93
2. Tạo phiên ở T93
3. TA mở UI-11-18 năm 2027

**Kết quả mong đợi.** `200`, hạn tính theo lịch mặc định (thứ Hai đến thứ Sáu); ghi ERR-11-116; UI-11-18 có băng cảnh báo.

**Thông báo hiển thị.** "Năm 2027 chưa có lịch làm việc; hạn đang tính theo lịch mặc định."
:::

#### TC-11-086 · Nhắc hạn đúng mốc, không nhắc trùng <!--k:due-soon-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** CLK

**Truy vết.** FR-11-047 · EVT-11-11 · BR-11-019 · NFR-11-016 · PERM-11-read

**Tiền điều kiện, dữ liệu.** Việc hạn 2 ngày LV; `11.task.dueSoonHours = 8`; 2 bản sao quét đồng thời; `11.due.scanMinutes = 1`.

**Các bước.**

1. Đọc `dueSoonAt`
2. CLK tới `dueSoonAt`
3. Đợi một chu kỳ quét
4. Đếm bản tin `task.due-soon`

**Kết quả mong đợi.** `dueSoonAt` = hạn trừ 8 giờ LV. Việc `DUE_SOON` trễ ≤ 5 phút so mốc; đúng 1 bản tin `task.due-soon` (khóa dòng `SKIP LOCKED`); thông báo trong ứng dụng gửi một lần; hộp việc đổi nhãn vàng.
:::

#### TC-11-087 · Không gửi được nhắc hạn <!--k:due-soon-fail-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-047 · ERR-11-123 · EVT-11-11

**Tiền điều kiện, dữ liệu.** Bộ thông báo giả ngừng.

**Các bước.**

1. CLK tới mốc nhắc
2. Đọc `due_tracking`, UI-11-20

**Kết quả mong đợi.** `DUE_SOON` đã đặt, EVT: `task.due-soon` đã phát; cảnh báo ERR-11-123 "Nhắc hạn việc … chưa gửi được."
:::

#### TC-11-088 · Quá hạn và leo thang hai mức <!--k:overdue-escalate-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** CLK

**Truy vết.** FR-11-048 · EVT-11-12 · BR-11-019 · UI-11-19

**Tiền điều kiện, dữ liệu.** Việc `duyetCapSo` hạn 3 ngày LV; mức 1 `NOTIFY_MANAGER`, mức 2 `REASSIGN_GROUP` sau 4 giờ LV; CB-LD là lãnh đạo đơn vị.

**Các bước.**

1. CLK qua hạn
2. CLK +4 giờ LV
3. CB-SO hoàn thành việc
4. TO mở giám sát UI-11-19
5. Việc `duyetCapPhong` không khai `afterHours`, `11.escalation.nextLevelHours = 4`, CLK qua hạn rồi +4 giờ LV

**Kết quả mong đợi.** Bước 1 `OVERDUE`, EVT: `task.overdue` `escalationLevel = 0`, rồi mức 1 báo CB-LD. Bước 2 mức 2, việc chuyển nhóm. Bước 3 `dueResult = MISSED`. Bước 4 việc quá hạn hiện trên giám sát, chỉ số `bpm_task_overdue` tăng. Bước 5 mức đầu ngay khi quá hạn (0 giờ), mức sau cách 4 giờ LV.
:::

#### TC-11-089 · Không xác định được lãnh đạo <!--k:overdue-no-manager-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-048 · ERR-11-113 · EVT-11-12

**Tiền điều kiện, dữ liệu.** PH-12 giả không có lãnh đạo đơn vị Tư pháp.

**Các bước.**

1. Việc quá hạn mức 1
2. Đọc cảnh báo UI-11-19

**Kết quả mong đợi.** Ghi ERR-11-113, chuyển mức kế tiếp; cảnh báo "Không xác định được lãnh đạo đơn vị Tư pháp để báo quá hạn."
:::

### TS-11-15 · Tra cứu và xem chi tiết phiên

**Mục tiêu.** Xác nhận danh sách, chi tiết, sơ đồ, dòng thời gian của phiên đúng phạm vi và che biến nhạy cảm.

**Phủ.** FR-11-021, 022; UC-11-15; API-11-050…055, 070; UI-11-11, 12; BR-11-014, 031.

#### TC-11-090 · Liệt kê, lọc phiên và phạm vi xem <!--k:inst-list-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-021 · API-11-050 · UI-11-11 · BR-11-031 · bpm.instance.read

**Tiền điều kiện, dữ liệu.** 20 phiên (`HS-01`…`HS-20`) nhiều trạng thái; VW, CB-TP, S-DVC (khởi tạo 10 phiên).

**Các bước.**

1. VW `GET /instances?processKey=LT_KHAI_SINH&status=RUNNING&dueStatus=DUE_SOON&page=0&size=10`
2. VW `GET /instances?businessKey=HS-T90-2026-0003`
3. CB-TP `GET /instances`
4. S-DVC `GET /instances`

**Kết quả mong đợi.** Bước 1 lọc đúng, phân trang. Bước 2 một phiên. Bước 3 chỉ phiên có việc của CB-TP hoặc đơn vị. Bước 4 chỉ 10 phiên do S-DVC khởi tạo, biến đã che.
:::

#### TC-11-091 · Liệt kê phiên sai tham số <!--k:inst-list-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-021 · API-11-050 · ERR-11-003 · ERR-00-403

**Tiền điều kiện, dữ liệu.** VW; người dùng không vai trò.

**Các bước.**

1. VW `GET /instances?status=FOO`
2. VW `GET /instances?size=1000`
3. VW `GET /instances?from=2027-02-01&to=2027-01-01`
4. Người không vai trò `GET /instances`

**Kết quả mong đợi.** Ba lần đầu `400` ERR-11-003. Bước 4 `403` ERR-00-403.
:::

#### TC-11-092 · Chi tiết phiên: sơ đồ, dòng thời gian, biến đã che <!--k:inst-detail-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-022 · API-11-051, 053, 054, 055, 070 · UI-11-12 · BR-11-014

**Tiền điều kiện, dữ liệu.** `HS-03` đang ở `capTheBHYT`; VW; TA có `PERM-09-unmask`.

**Các bước.**

1. VW `GET /instances/{id}`
2. VW `GET /instances/{id}/timeline`
3. VW `GET /instances/{id}/diagram`
4. VW `GET /instances/{id}/variables`
5. TA gọi lại `variables` có lý do mở che

**Kết quả mong đợi.** Chi tiết có `waitState = WAITING_SERVICE`; dòng thời gian đủ bước, người xử lý, lệnh `service_call`; sơ đồ đánh dấu bước xong và hiện tại; biến `SENSITIVE` `****`. TA có lý do: hiện rõ, KT: có.
:::

#### TC-11-093 · Chi tiết phiên không tồn tại, ngoài phạm vi, hết lưu giữ <!--k:inst-detail-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-022 · API-11-051 · ERR-11-001, 034

**Tiền điều kiện, dữ liệu.** CB-BH; phiên của Tư pháp; phiên đã dọn; `U-T91-IE1`.

**Các bước.**

1. CB-BH `GET /instances/{id}`
2. VW `GET /instances/khong-co`
3. VW `GET /instances/{id đã dọn}`
4. `U-T91-IE1` `GET /instances/{id}`

**Kết quả mong đợi.** Bước 1 `403` ERR-11-034. Bước 2 `404` ERR-11-001. Bước 3 `410` ERR-11-001. Bước 4 `404-ẩn`.
:::

### TS-11-16 · Tạm dừng, tiếp tục và hủy phiên

**Mục tiêu.** Xác nhận tạm dừng, tiếp tục và hủy phiên đúng trạng thái, hủy kèm bù trừ, và quyền hủy không bù trừ chỉ của TA.

**Phủ.** FR-11-023, 024; UC-11-16; API-11-056, 057, 058; EVT-11-06, 07; BR-11-008, 010, 011, 018, 023; ERR-11-006, 007, 030.

#### TC-11-094 · Tạm dừng và tiếp tục phiên <!--k:suspend-resume-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-023 · API-11-056, 057 · EVT-11-07 · BR-11-018, 023 · PERM-11-instance

**Tiền điều kiện, dữ liệu.** Phiên `HS-18` có việc mở và lệnh `guiCuTru` đang chờ; TO.

**Các bước.**

1. TO `POST /instances/{id}:suspend` `{reason:"Chờ ý kiến pháp lý", pauseDue:true}`
2. `ph04-sim` trả kết quả `guiCuTru` khi đang tạm dừng
3. CB hoàn thành việc
4. TO `:resume`

**Kết quả mong đợi.** Bước 1 `SUSPENDED`, hạn `PAUSED`, EVT: `instance.suspended` `state = SUSPENDED`. Bước 2 kết quả ghi `service_call` nhưng token chưa đi tiếp. Bước 3 `409` ERR-11-006. Bước 4 `RUNNING`, EVT `state = RESUMED`, token đi tiếp, hạn dời đúng thời gian dừng.
:::

#### TC-11-095 · Tạm dừng, tiếp tục sai trạng thái <!--k:suspend-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-023 · API-11-056, 057 · ERR-11-006, 007, 030 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Phiên `COMPLETED`; phiên `RUNNING`; phiên `COMPENSATING`; VW.

**Các bước.**

1. TO `:suspend` phiên `COMPLETED`
2. TO `:resume` phiên `RUNNING`
3. TO `:suspend` thiếu `reason`
4. TO `:suspend` phiên `COMPENSATING`
5. VW `:suspend`

**Kết quả mong đợi.** Bước 1, 2 `409` ERR-11-006. Bước 3 `422` ERR-11-007. Bước 4 `409` ERR-11-030. Bước 5 `403` ERR-00-403.

**Thông báo hiển thị.** "Phiên đang bù trừ, chờ Saga kết thúc."
:::

#### TC-11-096 · Hủy phiên chưa có bước rủi ro đã xong <!--k:cancel-simple-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-024 · API-11-058 · EVT-11-06 · PERM-11-instance

**Tiền điều kiện, dữ liệu.** Phiên `HS-19` ở `nhanHoSo`; TO.

**Các bước.**

1. TO `POST /instances/{id}:cancel` `{reason:"Hồ sơ nộp trùng"}`
2. `GET /tasks` của phiên
3. Đọc `due_tracking`

**Kết quả mong đợi.** `200`, `CANCELLED`; việc mở `CANCELLED`; hạn đóng; EVT: `instance.cancelled` `reason`, `compensated = false`.
:::

#### TC-11-097 · Hủy kèm bù trừ <!--k:cancel-comp-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-024, 051 · API-11-058 · EVT-11-06, 13, 14 · BR-11-008, 010, 011

**Tiền điều kiện, dữ liệu.** Phiên `HS-20` đã xong `guiTuPhap`, `guiCuTru`; TO.

**Các bước.**

1. TO `POST /instances/{id}:cancel` `{reason:"Công dân rút hồ sơ", compensate:"AUTO"}`
2. Theo dõi Saga
3. Giải quyết bước `MANUAL` bằng `resolve-manual`

**Kết quả mong đợi.** Bước 1 `202`, phiên `COMPENSATING`, giao diện hiện "Sẽ bù trừ 2 bước", `trigger = INSTANCE_CANCEL`. Khi mọi bước `DONE` hoặc `SKIPPED`: `COMPENSATED`, EVT: `instance.cancelled` `compensated = true`.
:::

#### TC-11-098 · Hủy sai trạng thái, thiếu lý do, bỏ bù trừ không đủ quyền <!--k:cancel-neg-->
::: dac-ta
**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-024 · API-11-058 · ERR-11-006, 007 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Phiên `COMPLETED`; phiên có bước rủi ro đã xong; TO, TA.

**Các bước.**

1. TO `:cancel` phiên `COMPLETED`
2. TO `:cancel` thiếu `reason`
3. TO `:cancel` `{compensate:"NONE"}` phiên có bước rủi ro
4. TA gọi như bước 3 với lý do 40 ký tự

**Kết quả mong đợi.** Bước 1 `409` ERR-11-006. Bước 2 `422` ERR-11-007. Bước 3 `403` ERR-00-403 "Chỉ quản trị tỉnh được hủy mà không bù trừ." Bước 4 `CANCELLED`, tạo việc đối chiếu thủ công cho TO.
:::

#### TC-11-170 · Client hệ thống hủy phiên của chính mình <!--k:cancel-client-->
::: dac-ta
**Loại.** Dương, Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-024 · API-11-058 · ERR-11-001 · bpm.instance.start

**Tiền điều kiện, dữ liệu.** `HS-21` do S-DVC khởi tạo và đã xong `guiTuPhap`, `guiCuTru`; `HS-22` do S-PH01 khởi tạo; `HS-23` do S-DVC khởi tạo chưa có bước ghi.

**Các bước.**

1. S-DVC `POST /instances/{HS-21}:cancel` kèm lý do
2. S-DVC `POST /instances/{HS-22}:cancel`
3. S-DVC `POST /instances/{HS-23}:cancel`

**Kết quả mong đợi.** Bước 1 `202`, bù trừ `AUTO`, `trigger = INSTANCE_CANCEL`. Bước 2 `404` ERR-11-001 (phiên của client khác). Bước 3 `200`, `CANCELLED`.
:::

### TS-11-17 · Can thiệp phiên có duyệt: sửa biến, chuyển bước, di trú

**Mục tiêu.** Xác nhận mọi can thiệp trực tiếp vào phiên đều qua bốn mắt, có lý do, kiểm toán và không phá trạng thái.

**Phủ.** FR-11-025, 026, 027; UC-11-17; API-11-059…068; UI-11-14; BR-11-005, 006, 021; ERR-11-005, 019, 030…033, 119.

#### TC-11-099 · Sửa biến phiên có duyệt <!--k:var-change-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-025 · API-11-059, 060, 061, 062 · ERR-11-005, 019, 033 · BR-11-014, 021 · PERM-11-instance-admin

**Tiền điều kiện, dữ liệu.** Phiên `HS-03`; `maXa` cho sửa, `soDinhDanhMe` không; TA, TA2.

**Các bước.**

1. TA `POST /instances/{id}/changes` `{type:"VARIABLE_UPDATE", name:"maXa", value:"26735", reason}`
2. TA `:approve`
3. TA2 `:approve`
4. TA đề nghị sửa `soDinhDanhMe`
5. TA đề nghị `ngaySinhTre` giá trị `abc`
6. TA đề nghị rồi TA2 `:reject` với ý kiến

**Kết quả mong đợi.** Bước 1 `PENDING`, có việc duyệt cho TA2. Bước 2 `403` ERR-11-005. Bước 3 `APPLIED`, KT ghi giá trị cũ đã che. Bước 4 `422` ERR-11-033. Bước 5 `422` ERR-11-019. Bước 6 `REJECTED`.
:::

#### TC-11-100 · Chuyển phiên tới bước khác có duyệt <!--k:move-token-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-027 · API-11-059, 061 · ERR-11-005, 030, 032 · BR-11-021

**Tiền điều kiện, dữ liệu.** Phiên `HS-18` ở `capTheBHYT`; một phiên `COMPENSATING`; TA, TA2.

**Các bước.**

1. TA đề nghị `MOVE_TOKEN` tới `guiCuTru`, TA2 duyệt
2. TA đề nghị chuyển vào sự kiện biên
3. TA đề nghị chuyển vào giữa nhánh song song chưa hợp
4. TA đề nghị cho phiên `COMPENSATING`
5. TA tự duyệt

**Kết quả mong đợi.** Bước 1 token ở `guiCuTru`, việc cũ `CANCELLED`, dòng thời gian "Chuyển bước thủ công". Bước 2 và 3 `422` ERR-11-032. Bước 4 `409` ERR-11-030. Bước 5 `403` ERR-11-005.
:::

#### TC-11-101 · Di trú 25 phiên từ v3 sang v4 <!--k:migrate-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-026 · API-11-063, 064, 065, 066, 068 · UI-11-14 · BR-11-006, 021 · PERM-11-instance-admin

**Tiền điều kiện, dữ liệu.** 25 phiên `RUNNING` ở v3; v4 `PUBLISHED`; TA, TA2; `11.migration.batchSize = 10`.

**Các bước.**

1. TA `POST /migration-plans` `{processKey, from:3, to:4}`
2. TA `:validate`
3. TA `:submit`, TA2 `:approve`
4. Theo dõi chạy ba lô
5. `GET /migration-plans/{id}`

**Kết quả mong đợi.** Ghép tự động theo `elementId`; kế hoạch `VALIDATED`; chạy 10, 10, 5 phiên, mỗi phiên một giao dịch; `COMPLETED`; `instance_index.version = 4`; phiên chạy tiếp đúng bước.
:::

#### TC-11-102 · Di trú: bước chưa ánh xạ, tự duyệt, phiên lỗi giữa chừng <!--k:migrate-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-026 · API-11-064, 066 · ERR-11-005, 031, 119 · BR-11-021

**Tiền điều kiện, dữ liệu.** v4 bỏ bước `guiCuTru` mà còn 3 phiên đang ở đó; một phiên bị chèn lỗi khi di trú.

**Các bước.**

1. TA `:validate` kế hoạch
2. TA tự `:approve`
3. Ánh xạ tay, TA2 duyệt, chạy
4. Đọc kết quả lô

**Kết quả mong đợi.** Bước 1 `422` ERR-11-031 nêu 3 phiên và bước chưa ánh xạ. Bước 2 `403` ERR-11-005. Sau chạy: `PARTIAL`, phiên lỗi ghi ERR-11-119 ở UI-11-14, các phiên khác `instance_index.version = 4`.
:::

### TS-11-18 · Điều phối bù trừ Saga khi lỗi bước

**Mục tiêu.** Xác nhận Saga bù trừ theo thứ tự ngược, đúng chính sách `AUTO`, `MANUAL`, `NONE_APPROVED`, không giao dịch phân tán, không im lặng khi lỗi (ADR 113).

**Phủ.** FR-11-051; UC-11-18; API-11-098; EVT-11-13, 14, 15, 17; BR-11-008…013; ERR-11-006, 030, 110, 111, 112.

#### TC-11-103 · Nhánh BHYT lỗi: bù trừ ngược, tự động rồi thủ công <!--k:saga-bhyt-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-051, 053 · EVT-11-13, 14, 17 · BR-11-008, 009, 010, 011, 013 · PERM-11-compensate

**Tiền điều kiện, dữ liệu.** Phiên `HS-21` có `guiTuPhap`, `guiCuTru` `DONE`; `ph04-sim` trả `BUSINESS_ERROR` cho `capTheBHYT`, `completed` cho `huyDangKyThuongTru`.

**Các bước.**

1. Gây lỗi `capTheBHYT`
2. Theo dõi `GET /sagas?instanceId=`
3. `ph04-sim` trả `completed` cho lệnh bù trừ
4. TO xử lý việc `MANUAL_COMPENSATION` của `guiTuPhap` bằng `:resolve-manual`

**Kết quả mong đợi.** Phiên `COMPENSATING`, `saga_log` `RUNNING`, EVT: `saga.compensation.started`. `saga_step`: `guiCuTru` trước, `guiTuPhap` sau; `guiCuTru` gửi lệnh `huyDangKyThuongTru` với `commandId` mới, `DONE` chỉ sau khi ghi nhật ký. `guiTuPhap` `MANUAL`, việc cho nhóm vận hành, cảnh báo P1. Khi xong: `SUCCEEDED`, phiên `COMPENSATED`, EVT: `saga.compensation.completed`.
:::

#### TC-11-104 · Thứ tự ngược, nhánh song song, bước chưa xong, miễn bù trừ <!--k:saga-order-->
::: dac-ta
**Loại.** Dương, Biên

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-051 · ERR-11-112 · BR-11-008, 011, 013

**Tiền điều kiện, dữ liệu.** Mô hình có hai bước song song `songSong1`, `songSong2` hoàn thành cùng lúc, bước `chuaXong` chưa chạy, bước `mienBu` `NONE_APPROVED`, bước `khongBu` ghi ngoài nhưng không có bù trừ (mô hình cũ).

**Các bước.**

1. Gây lỗi ở bước cuối
2. Đọc `saga_step` và thời điểm gửi lệnh

**Kết quả mong đợi.** Bước nối tiếp bù trừ ngược thời điểm hoàn thành; hai bước song song gửi lệnh gần như đồng thời; `chuaXong` và `mienBu` `SKIPPED`; `khongBu` chuyển `MANUAL` kèm ERR-11-112 "Bước khongBu chưa có bù trừ, đã chuyển xử lý thủ công."
:::

#### TC-11-105 · Kích hoạt bù trừ thủ công <!--k:saga-manual-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-051 · API-11-098 · ERR-11-006, 030 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Phiên `HS-22` có bước đã xong; phiên `HS-23` chưa có bước nào cần bù trừ; phiên đang `COMPENSATING`; TO, VW.

**Các bước.**

1. TO `POST /instances/{HS-22}:compensate`
2. TO `:compensate` `HS-23`
3. TO `:compensate` phiên đang `COMPENSATING`
4. VW `:compensate`

**Kết quả mong đợi.** Bước 1 `202` kèm `sagaId`, `steps[]`. Bước 2 `409` ERR-11-006. Bước 3 `409` ERR-11-030. Bước 4 `403` ERR-00-403.

**Thông báo hiển thị.** "Hồ sơ chưa có bước nào cần bù trừ."
:::

#### TC-11-106 · Không ghi được nhật ký Saga <!--k:saga-log-fail-->
::: dac-ta
**Loại.** Âm, Chịu lỗi

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-051 · ERR-11-111 · BR-11-013, 022

**Tiền điều kiện, dữ liệu.** Chèn lỗi ghi `saga_step`; phiên `HS-24` đang bù trừ `guiCuTru`.

**Các bước.**

1. Bật lỗi ghi nhật ký khi lệnh bù trừ trả `completed`
2. Đọc `saga_step`
3. Tắt lỗi, đợi thử lại
4. Đếm lệnh bù trừ tới `ph04-sim`

**Kết quả mong đợi.** Bước giữ `RUNNING`, cảnh báo ERR-11-111; sau khi tắt lỗi bước `DONE` đúng một lần; chỉ một lệnh bù trừ (idempotent theo `commandId`).

**Thông báo hiển thị.** "Không ghi được nhật ký bù trừ bước guiCuTru; bước giữ trạng thái chạy, sẽ thử lại."
:::

### TS-11-19 · Theo dõi nhật ký Saga, xử lý bù trừ thủ công và đối soát định kỳ

**Mục tiêu.** Xác nhận nhật ký Saga xem và xuất được, bước thủ công xử lý có kiểm soát (bỏ qua qua bốn mắt), hết lượt thử chuyển thủ công, đối soát phát hiện bù trừ chưa hiệu lực.

**Phủ.** FR-11-052, 053, 054; UC-11-19; API-11-096…103, 129, 132, 133; UI-11-21; EVT-11-15; BR-11-009, 012, 013, 025; ERR-11-005…007, 110, 121.

#### TC-11-107 · Xem nhật ký Saga <!--k:saga-view-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-052 · API-11-096, 097, 129 · UI-11-21 · BR-11-013, 025 · PERM-11-read, PERM-11-audit-read

**Tiền điều kiện, dữ liệu.** Một số Saga `SUCCEEDED`, `PARTIAL`; TO, AU.

**Các bước.**

1. TO `GET /sagas?status=PARTIAL&page=0&size=10`
2. TO `GET /sagas/{id}`
3. AU xuất nhật ký bằng `POST /sagas:export`

**Kết quả mong đợi.** Danh sách đúng trạng thái; chi tiết có `attempt`, `status`, `responseCode`, `evidence`, `resolvedBy` từng bước; AU xuất được tệp CSV có băm.
:::

#### TC-11-108 · Xem Saga sai tham số, tenant khác, xuất không quyền <!--k:saga-view-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-052 · API-11-096, 097, 129 · ERR-11-001, 003 · ERR-00-403

**Tiền điều kiện, dữ liệu.** VW; `U-T91-IE1`.

**Các bước.**

1. VW `GET /sagas?status=FOO`
2. `U-T91-IE1` `GET /sagas/{id}`
3. VW `POST /sagas:export`

**Kết quả mong đợi.** Bước 1 `400` ERR-11-003. Bước 2 `404-ẩn` ERR-11-001. Bước 3 `403` ERR-00-403.
:::

#### TC-11-109 · Thử lại, xác nhận thủ công, hết lượt thử <!--k:saga-retry-resolve-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-053 · API-11-099, 100 · UI-11-21 · EVT-11-15 · ERR-11-110 · BR-11-009, 012 · PERM-11-compensate

**Tiền điều kiện, dữ liệu.** T92 `11.saga.maxRetries = 2`, `11.saga.retryBackoffSeconds = 30`; `ph04-sim` trả `failed` cho `huyDangKyThuongTru` 3 lần; TO.

**Các bước.**

1. Gây Saga cho `HS-25`
2. CLK +30 giây hai lần
3. Đọc `saga_step` và `saga_log`
4. TO `POST /sagas/{id}/steps/{stepId}:retry`
5. `ph04-sim` trả `completed`

**Kết quả mong đợi.** Hai lần thử lỗi (ERR-11-110 "Bù trừ huyDangKyThuongTru … vẫn lỗi"), sau đó bước `MANUAL`, việc `MANUAL_COMPENSATION`, cảnh báo P1, phiên `FAILED`, `saga_log` `PARTIAL`, EVT: `saga.compensation.failed` có `manualSteps`. Bước 4 `RUNNING` rồi `DONE`, phiên `COMPENSATED`.
:::

#### TC-11-110 · Bỏ qua bước bù trừ qua bốn mắt, bước không ở thủ công <!--k:saga-skip-->
::: dac-ta
**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-053 · API-11-101, 132, 133, 099, 100 · ERR-11-005, 006, 007 · ERR-00-403 · BR-11-012

**Tiền điều kiện, dữ liệu.** Hai bước `MANUAL` (`b1`, `b2`), một bước `DONE`; TA, TA2, TO, VW.

**Các bước.**

1. TO đề nghị `:skip` `b1` không lý do
2. TO đề nghị `:skip` `b1` với lý do 40 ký tự
3. TO gọi `:approve-skip` chính đề nghị của mình
4. TA2 `:reject-skip` rồi TA `:approve-skip` đề nghị mới cho `b2` do TA2 đề nghị
5. TO `:retry` bước `DONE`; VW `:resolve-manual`

**Kết quả mong đợi.** Bước 1 `422` ERR-11-007. Bước 2 chỉ tạo đề nghị và việc `MANUAL_COMPENSATION` cho TA khác, `b1` vẫn `MANUAL`. Bước 3 `403` ERR-11-005. Bước 4 `b1` về `MANUAL` có lý do từ chối; `b2` `SKIPPED` do người khác duyệt, KT: có. Bước 5 `409` ERR-11-006 rồi `403` ERR-00-403.
:::

#### TC-11-111 · Đối soát bù trừ định kỳ <!--k:reconcile-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** FR-11-054 · API-11-102, 103 · ERR-11-121 · BR-11-012

**Tiền điều kiện, dữ liệu.** Một bước `DONE` mà `ph04-sim` báo bù trừ chưa hiệu lực; lịch `11.saga.reconcileCron = 0 0 2 * * *`; TO.

**Các bước.**

1. CLK tới 02:00
2. TO `POST /reconciliations`
3. `GET /reconciliations` và `GET /incidents`

**Kết quả mong đợi.** Lịch chạy tự động và chạy tay `202`; kết quả liệt kê một sai lệch; sự cố ERR-11-121 `OPEN` và việc cho TO; bước sai lệch không bị tự sửa.
:::

### TS-11-20 · Tra tiến độ hồ sơ cho Cổng DVC và phát sự kiện tiến độ

**Mục tiêu.** Xác nhận Cổng DVC chỉ thấy tiến độ rút gọn đã che, không lộ hồ sơ của client khác, sự kiện tiến độ đúng thứ tự, cùng giao dịch.

**Phủ.** FR-11-055, 056; UC-11-20; API-11-104; EVT-11-03…07; BR-11-014, 015, 023, 030; NFR-11-006, 018; ERR-11-035, 117.

#### TC-11-112 · Tra tiến độ hồ sơ <!--k:progress-ok-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-055 · API-11-104 · BR-11-014, 015 · NFR-11-006 · bpm.progress.read

**Tiền điều kiện, dữ liệu.** `HS-03` đang ở `capTheBHYT`; S-DVC; `11.progress.cacheSeconds = 30`.

**Các bước.**

1. S-DVC `GET /progress/HS-T90-2026-0003`
2. Lặp lại trong 30 giây, đọc số truy vấn CSDL
3. Đọc nhật ký truy cập

**Kết quả mong đợi.** `200`; `steps` chỉ ba bước có `publicName` với `DONE`, `DONE`, `IN_PROGRESS`; `displayStatus`, `percentEstimate`, `dueAt`, `message`; `Cache-Control: max-age=30`; lần lặp không đọc CSDL; có dòng nhật ký (client, `businessKey`, thời điểm), không ghi nội dung.
:::

#### TC-11-113 · Tiến độ không lộ DLCN, ý định, lỗi kỹ thuật, tên cán bộ <!--k:progress-mask-->
::: dac-ta
**Loại.** Dương, Bảo mật

**Ưu tiên.** P1

**Tự động.** ZAP

**Truy vết.** FR-11-055 · API-11-104 · BR-11-014, 015 · NFR-11-021

**Tiền điều kiện, dữ liệu.** Phiên T96 với `F-DLCN`, có sự cố `TECHNICAL` ở `capTheBHYT` và một phiên đang `COMPENSATING`; từ điển cấm: `intentCode`, mã luồng PH-04, `errorCode`, `BHXH_TU_CHOI`, tên CB, `soDinhDanhMe`, canary.

**Các bước.**

1. S-DVC tra tiến độ các phiên
2. Quét toàn bộ JSON và tiêu đề bằng từ điển cấm
3. Tra phiên cha có phiên con

**Kết quả mong đợi.** Không có từ khóa cấm trong thân hay tiêu đề; lỗi kỹ thuật hiện thành câu thân thiện "Hồ sơ đang được xử lý"; phiên con gộp vào đúng vị trí bước gọi; Mồi sạch.
:::

#### TC-11-114 · Tiến độ không lộ tồn tại hồ sơ <!--k:progress-404-->
::: dac-ta
**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-055 · API-11-104 · ERR-11-035 · ERR-00-403, 401

**Tiền điều kiện, dữ liệu.** `HS-03` do S-DVC khởi tạo; S-DVC2; S-T91-DVC.

**Các bước.**

1. S-DVC tra `HS-KHONG-CO`
2. S-DVC2 tra `HS-03`
3. S-T91-DVC tra `HS-03`
4. Token thiếu scope `bpm.progress.read` tra `HS-03`
5. Không token

**Kết quả mong đợi.** Bước 1 đến 3 `404` ERR-11-035, ba thân giống nhau trừ `traceId`. Bước 4 `403` ERR-00-403. Bước 5 `401` ERR-00-401.

**Thông báo hiển thị.** "Không tìm thấy hồ sơ HS-KHONG-CO."
:::

#### TC-11-115 · Phát sự kiện tiến độ cùng giao dịch <!--k:evt-progress-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** KT

**Truy vết.** FR-11-056 · EVT-11-03, 04, 05, 06, 07 · BR-11-014, 023, 030 · NFR-11-018

**Tiền điều kiện, dữ liệu.** Phiên `HS-26` chạy hết quy trình; lỗi chèn sau chuyển bước ở phiên `HS-27`.

**Các bước.**

1. Chạy `HS-26` đến `COMPLETED`
2. Đọc `t90.bpm.instance.*` theo `businessKey`
3. Với `HS-27` gây lỗi trước commit
4. Đo độ trễ từ chuyển bước đến bản tin

**Kết quả mong đợi.** Có `instance.started`, các `instance.step.completed` theo thứ tự, `instance.completed` có `outcome`, `dueResult`; cùng partition `businessKey`; độ trễ p95 ≤ 10 giây; không có giá trị biến (Mồi sạch); `HS-27` không có bản tin nào. PH-11 không gửi thông báo cho công dân.
:::

#### TC-11-116 · Outbox tồn đọng khi Kafka ngừng <!--k:outbox-backlog-->
::: dac-ta
**Loại.** Âm, Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** FR-11-056 · ERR-11-117 · EVT-11-04 · BR-11-023

**Tiền điều kiện, dữ liệu.** T95; Kafka ngừng 15 phút trong khi 50 phiên chạy.

**Các bước.**

1. Ngừng Kafka
2. Chạy bước các phiên
3. Đọc UI-11-19
4. Phục hồi Kafka, đối chiếu bản tin

**Kết quả mong đợi.** Bước nghiệp vụ vẫn hoàn thành; cảnh báo ERR-11-117 "Có {n} sự kiện chưa gửi quá {m} phút."; sau phục hồi đủ bản tin theo thứ tự từng `businessKey`, không trùng `id` CloudEvents.
:::

### TS-11-21 · Giám sát quy trình, phát hiện tắc nghẽn và báo cáo đúng hạn, trễ hạn

**Mục tiêu.** Xác nhận bảng giám sát đúng số liệu và phạm vi, tắc nghẽn tính theo mẫu đủ lớn, báo cáo hạn đúng theo giờ làm việc.

**Phủ.** FR-11-058, 059, 050; UC-11-21; API-11-094, 095, 107, 108; UI-11-19, 22; BR-11-017, 019, 031; ERR-11-003, 115.

#### TC-11-117 · Bảng điều khiển giám sát <!--k:monitor-ok-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-058 · API-11-107 · UI-11-19 · BR-11-031 · PERM-11-read

**Tiền điều kiện, dữ liệu.** T98 có 50.000 phiên `RUNNING`, vài phiên `SUSPENDED`, `COMPENSATING`, `FAILED`; việc quá hạn; sự cố mở.

**Các bước.**

1. VW `GET /monitoring/summary`
2. Đếm trực tiếp ở CSDL theo trạng thái
3. CB-TP gọi API

**Kết quả mong đợi.** Số phiên theo trạng thái, việc quá hạn, sự cố mở, outbox tồn khớp số đếm CSDL; CB-TP chỉ thấy phạm vi mình (BR-11-031).
:::

#### TC-11-118 · Giám sát sai tham số, thiếu quyền <!--k:monitor-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-058 · API-11-107 · ERR-11-003 · ERR-00-403

**Tiền điều kiện, dữ liệu.** VW; người không vai trò.

**Các bước.**

1. VW `GET /monitoring/summary?window=99d`
2. Người không vai trò gọi API

**Kết quả mong đợi.** Bước 1 `400` ERR-11-003. Bước 2 `403` ERR-00-403.
:::

#### TC-11-119 · Phát hiện tắc nghẽn bước và phiên tắc <!--k:bottleneck-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** CLK

**Truy vết.** FR-11-059 · API-11-108 · ERR-11-115 · BR-11-019

**Tiền điều kiện, dữ liệu.** `11.bottleneck.minSamples = 30`, `11.bottleneck.factor = 2,0`; bước `guiCuTru` có 40 mẫu, `capTheBHYT` có 12 mẫu; một phiên ở một bước 80 giờ; `11.instance.stuckHours = 72`.

**Các bước.**

1. Làm một phiên chờ ở `guiCuTru` quá 2 lần p95
2. Làm một phiên chờ ở `capTheBHYT` quá 2 lần p95
3. `GET /monitoring/bottlenecks`
4. CLK +73 giờ cho phiên chờ

**Kết quả mong đợi.** `guiCuTru` được cảnh báo; `capTheBHYT` không (dưới 30 mẫu). Phiên chờ quá 72 giờ: sự cố `STUCK_INSTANCE` (ERR-11-115).
:::

#### TC-11-120 · Báo cáo đúng hạn, trễ hạn <!--k:due-report-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-050 · API-11-094, 095 · UI-11-22 · BR-11-017, 018 · ERR-11-003, 039

**Tiền điều kiện, dữ liệu.** 100 phiên đã đóng, 80 `MET`, 20 `MISSED` (trong đó 5 phiên chỉ trễ khi cộng thời gian chờ bổ sung); VW.

**Các bước.**

1. VW `GET /reports/due?groupBy=orgUnit&from&to`
2. VW `POST /reports/due:export`
3. VW gọi với `from` sau `to`
4. VW gọi với khoảng 400 ngày

**Kết quả mong đợi.** Tỷ lệ đúng hạn 80 %; 5 phiên chờ bổ sung tính `MET`; xuất `202` ra tệp có băm; bước 3 `400` ERR-11-003; bước 4 `422` ERR-11-039 "Khoảng thời gian tối đa 366 ngày."
:::

### TS-11-22 · Xử lý sự cố engine và thử lại

**Mục tiêu.** Xác nhận sự cố mở đúng, thử lại và bỏ qua có kiểm soát, người vận hành nền tảng chỉ xem có phiếu.

**Phủ.** FR-11-060; UC-11-22; API-11-109…113; UI-11-20; EVT-11-16; BR-11-012; ERR-11-006, 007, 107.

#### TC-11-121 · Sự cố job: mở, thử lại, đóng <!--k:incident-retry-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-060 · API-11-109, 110, 111, 113 · UI-11-20 · EVT-11-16 · BR-11-012 · PERM-11-compensate

**Tiền điều kiện, dữ liệu.** Hai job chèn lỗi tạm thời `JOB_FAILED`; TO.

**Các bước.**

1. Để job hết lượt thử
2. TO `GET /incidents`, `GET /incidents/{id}`
3. Sửa nguyên nhân, TO `POST /incidents/{id}:retry`
4. TO `POST /incidents:bulk-retry` cho sự cố còn lại

**Kết quả mong đợi.** Sự cố `OPEN` có ngăn xếp rút gọn, `traceId`, phiên, bước, số lần thử; EVT: `incident.opened`, cảnh báo PH-13. `RETRYING` rồi `RESOLVED`. Bước 4 mọi sự cố chọn được chuyển `RETRYING`.
:::

#### TC-11-122 · Sự cố: đã đóng, lỗi tiếp, thiếu lý do, PO không phiếu <!--k:incident-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-060 · API-11-111, 112 · ERR-11-006, 007, 107 · ERR-00-403

**Tiền điều kiện, dữ liệu.** Sự cố `RESOLVED`; sự cố còn lỗi nguyên nhân; TO, PO, VW.

**Các bước.**

1. TO `:retry` sự cố `RESOLVED`
2. TO `:retry` sự cố nguyên nhân chưa sửa
3. TO `:ignore` không lý do
4. PO `:retry` không có phiếu sự cố
5. VW `:retry`

**Kết quả mong đợi.** Bước 1 `409` ERR-11-006. Bước 2 sự cố về `OPEN`, ERR-11-107 "Thử lại không thành công". Bước 3 `422` ERR-11-007. Bước 4 `403` ERR-00-403. Bước 5 `403` ERR-00-403.
:::

#### TC-11-123 · Bỏ qua sự cố có lý do <!--k:incident-ignore-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P3

**Tự động.** API

**Truy vết.** FR-11-060 · API-11-112 · UI-11-20

**Tiền điều kiện, dữ liệu.** Sự cố `STUCK_INSTANCE` của phiên đã được hủy; TO.

**Các bước.**

1. TO `POST /incidents/{id}:ignore` `{reason:"Phiên đã hủy, hồ sơ nộp lại"}`
2. Đọc job chết của phiên

**Kết quả mong đợi.** `IGNORED`, ghi `handled_by`, `reason`; job chết bị xóa; KT: có.
:::

### TS-11-23 · Cấu hình cảnh báo, tham số `11.*` và chính sách lưu giữ

**Mục tiêu.** Xác nhận tham số, ngưỡng cảnh báo, lưu giữ đổi đúng miền, không vượt trần, dọn lịch sử đúng, không dọn hồ sơ giữ pháp lý (xem và gỡ giữ).

**Phủ.** FR-11-061, 062, 063; UC-11-23; API-11-114…120, 134, 135; UI-11-23; BR-11-024, 025; NFR-11-019, 024; ERR-11-029, 047, 122.

#### TC-11-124 · Đổi tham số tenant <!--k:settings-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-062 · API-11-116, 117 · UI-11-23 · BR-11-024 · PERM-11-config

**Tiền điều kiện, dữ liệu.** TA; mặc định `11.task.dueSoonHours = 8`.

**Các bước.**

1. TA `GET /settings`
2. TA `PUT /settings` `If-Match` `{"11.task.dueSoonHours":12}`
3. Tạo việc mới, đọc `dueSoonAt`

**Kết quả mong đợi.** Bước 1 có mặc định theo FRS §8.2. Bước 2 `200`; KT: có (giá trị cũ, mới). Bước 3 `dueSoonAt` = hạn trừ 12 giờ LV.
:::

#### TC-11-125 · Tham số ngoài miền, vượt trần, thiếu quyền <!--k:settings-neg-->
::: dac-ta
**Loại.** Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-062 · API-11-117 · ERR-11-029 · ERR-00-403, 428 · BR-11-024

**Tiền điều kiện, dữ liệu.** PA đã đặt trần `11.delegation.maxDays = 60` ở `COMMON`; TA, TO.

**Các bước.**

1. TA đặt `11.timer.minSeconds = 30`
2. TA đặt `11.delegation.maxDays = 90`
3. TA đặt `11.saga.reconcileCron = "abc"`
4. TO `PUT /settings`
5. TA `PUT` không `If-Match`

**Kết quả mong đợi.** Bước 1 đến 3 `422` ERR-11-029 nêu miền hoặc trần. Bước 4 `403` ERR-00-403. Bước 5 `428` ERR-00-428.

**Thông báo hiển thị.** "11.timer.minSeconds phải trong khoảng 60…3600."
:::

#### TC-11-126 · Ngưỡng cảnh báo và chỉ số vận hành <!--k:alert-rules-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-061 · API-11-114, 115 · ERR-11-029 · NFR-11-019 · BR-11-024

**Tiền điều kiện, dữ liệu.** TA; bộ thu chỉ số của PH-13 giả.

**Các bước.**

1. TA `PUT /alert-rules` đặt ngưỡng `bpm_service_wait_seconds` p95 > 2 lần `timeout`
2. TA `GET /alert-rules`
3. TA `PUT` ngưỡng âm
4. Đọc điểm cuối chỉ số

**Kết quả mong đợi.** Bước 1 `200`, bước 2 trả đúng. Bước 3 `422` ERR-11-029. Điểm cuối chỉ số có các chỉ số của bảng vận hành.
:::

#### TC-11-127 · Chính sách lưu giữ, giữ pháp lý, dọn lịch sử <!--k:retention-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-063 · API-11-118…120, 134, 135 · ERR-11-007, 029, 047, 122 · BR-11-025 · NFR-11-024 · PERM-11-config

**Tiền điều kiện, dữ liệu.** T99: 1.000 phiên kết thúc 13 tháng trước, trong đó 50 giữ pháp lý; `11.retention.engineHistoryMonths = 12`.

**Các bước.**

1. TA `PUT /retention-policy` `{instanceYears:3}`
2. TA `POST /legal-holds` cho 50 hồ sơ
3. CLK qua `0 0 1 * * *`, đo p99 API khi dọn
4. TA dọn tay một hồ sơ giữ pháp lý
5. Chèn lỗi ở lô dọn thứ hai
6. TA `GET /legal-holds`, rồi `POST /legal-holds/{id}:release` thiếu lý do và với lý do 40 ký tự
7. TO `:release` hồ sơ khác

**Kết quả mong đợi.** Bước 1 `422` ERR-11-029 (miền 5…20). Bước 3 xóa `ACT_HI_*` của 950 phiên, giữ `instance_index`, `task_index`, `saga_*`, `service_call`, 50 phiên giữ pháp lý nguyên; p99 API tăng ≤ 10 %. Bước 4 `409` ERR-11-047. Bước 5 cảnh báo ERR-11-122 "Dọn lịch sử lỗi ở lô 2". Bước 6 danh sách kèm lý do, người, giờ; `422` ERR-11-007 rồi `200`, KT: có, hồ sơ đã gỡ bị dọn lần sau. Bước 7 `403` ERR-00-403.
:::

### TS-11-24 · Kiểm toán lịch sử bước, nhật ký phân hệ và bằng chứng tuân thủ BPMN 2.0

**Mục tiêu.** Xác nhận lịch sử bước đủ cho kiểm toán, bằng chứng có băm, mẫu BPMN 2.0 chạy được cùng thuyết minh WS-BPEL, nhật ký kiểm toán, xuất CSV.

**Phủ.** FR-11-057, 064, 065; UC-11-24; API-11-105, 106, 121…123, 128…130, 137; BR-11-025, 026, 038; NFR-11-023; ERR-11-001, 003, 006, 039.

#### TC-11-128 · Lịch sử bước và xuất bằng chứng <!--k:history-->
::: dac-ta
**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-057 · API-11-105, 106 · BR-11-025, 038 · NFR-11-023 · PERM-11-audit-read

**Tiền điều kiện, dữ liệu.** Phiên `HS-26` 50 bước đã hoàn thành; AU.

**Các bước.**

1. AU `GET /instances/{id}/history`
2. AU `POST /instances/{id}/history:export`
3. Tính lại SHA-256 của tệp

**Kết quả mong đợi.** Bước 1 đủ bước, người, thời điểm, biến đã che, ≤ 5 giây. Bước 2 `202`, tệp kèm băm. Bước 3 trùng băm và có tham chiếu chuỗi băm kiểm toán (ADR-031). KT: có.
:::

#### TC-11-129 · Lịch sử: thiếu quyền, hết lưu giữ <!--k:history-neg-->
::: dac-ta
**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-057 · API-11-105, 106 · ERR-11-001 · ERR-00-403

**Tiền điều kiện, dữ liệu.** VW, TO, TA; phiên đã dọn lịch sử.

**Các bước.**

1. VW `GET /instances/{id}/history`
2. TO `POST /instances/{id}/history:export`
3. TA `GET /instances/{id đã hết lưu giữ}/history`

**Kết quả mong đợi.** Bước 1 và 2 `403` ERR-00-403. Bước 3 `410` ERR-11-001.
:::

#### TC-11-130 · Bằng chứng tuân thủ BPMN 2.0 và thuyết minh WS-BPEL <!--k:compliance-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-064 · API-11-121, 122, 137 · ERR-11-006, 039 · BR-11-026, 038 · NFR-11-023 · PERM-11-audit-read

**Tiền điều kiện, dữ liệu.** AU; mẫu `MAU_CV631` có bước tự động giả lập, việc tự hoàn thành, một nhánh bù trừ.

**Các bước.**

1. AU `POST /compliance/sample-runs`
2. AU `GET /compliance/evidence-packs/{id}`
3. AU gọi với khoảng thống kê 13 tháng
4. AU `GET /compliance/sample-runs`; tải gói chưa dựng xong
5. VW gọi `POST /compliance/sample-runs`

**Kết quả mong đợi.** Bước 1 `202`, gói ≤ 2 phút; gói PDF và JSON có băm, XML mẫu, `instanceId`, lịch sử bước, danh sách phần tử BPMN 2.0 đã chạy, phiên bản Flowable, thuyết minh WS-BPEL. Bước 3 `422` ERR-11-039. Bước 4 danh sách lần chạy mẫu, gói chưa xong `409` ERR-11-006. Bước 5 `403` ERR-00-403.

**Thông báo hiển thị.** "Khoảng thời gian tối đa 12 tháng."
:::

#### TC-11-131 · Nhật ký kiểm toán phân hệ <!--k:audit-log-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-065 · API-11-123 · ERR-11-003, 039 · EVT-11-21 · BR-11-038 · PERM-11-audit-read

**Tiền điều kiện, dữ liệu.** Các thao tác của các ca trước (phát hành, hủy, sửa biến, bỏ qua bù trừ); AU, VW.

**Các bước.**

1. AU `GET /audit-logs?from&to&actor=TA&action=instance.cancel`
2. AU `GET /audit-logs?size=1000`
4. AU `GET /audit-logs` khoảng 400 ngày
3. VW `GET /audit-logs`

**Kết quả mong đợi.** Bước 1 trả đúng bản ghi, có `traceId`, tham chiếu chuỗi băm, không có giá trị biến. Bước 2 `400` ERR-11-003. Bước 3 `403` ERR-00-403. Bước 4 `422` ERR-11-039. Mỗi bản ghi có EVT: `audit.recorded` (`action`, `objectType`, `objectId`, `actor`, `traceId`, `hashRef`, không giá trị biến).
:::

#### TC-11-171 · Xuất CSV phiên, Saga và nhật ký kiểm toán <!--k:export-csv-->
::: dac-ta
**Loại.** Dương, Âm

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-021, 052, 065 · API-11-128, 129, 130 · ERR-11-039 · EVT-11-21 · PERM-11-read, PERM-11-audit-read

**Tiền điều kiện, dữ liệu.** 20 phiên, các Saga của TS-11-19; TO, AU, VW.

**Các bước.**

1. TO `POST /instances:export` lọc `status=RUNNING`
2. TO `POST /sagas:export`
3. AU `POST /audit-logs:export` khoảng 30 ngày, rồi khoảng 400 ngày
4. VW `POST /audit-logs:export`

**Kết quả mong đợi.** Bước 1, 2 `202`, tệp CSV có băm, đúng số dòng lọc, không giá trị `SENSITIVE`. Bước 3 `202`, KT: có; khoảng 400 ngày `422` ERR-11-039 "Khoảng thời gian tối đa 366 ngày." Bước 4 `403` ERR-00-403.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Mười một kịch bản dưới đây không ứng với một use case mà cắt ngang cả phân hệ: cô lập tenant, phân quyền, che dữ liệu cá nhân, idempotency, bền trạng thái, hiệu năng, hạn theo lịch, nhất quán Saga và outbox, chịu lỗi, truy cập và đầu cuối nghiệm thu. Ngưỡng lấy từ FRS §8.1 và điều kiện đo ghi ở từng ca; số tải là giả định GĐ-01.


### TS-11-25 · Cô lập tenant: API, RLS, Flowable, Kafka

**Mục tiêu.** Chứng minh tenant này không đọc, ghi được dữ liệu quy trình của tenant khác ở API, CSDL, engine, topic Kafka, khóa idempotency.

**Phủ.** BR-11-007, 032; NFR-11-020, 021; mọi API đọc của API-11-001…127; ph11_isolation_test.sql.

#### TC-11-132 · Rò rỉ chéo tenant ở mọi API đọc và ghi <!--k:iso-api-->
::: dac-ta
**Mục đích.** Chứng minh token T91 không đọc, ghi được đối tượng T90 qua API nào, `404` không phân biệt "không có" với "tenant khác".

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** API-11-002, 009, 019, 031, 051, 073, 097, 110, 122 · ERR-11-001 · BR-11-032 · NFR-11-020

**Tiền điều kiện, dữ liệu.** T90 có mô hình, biểu mẫu, ý định, phiên, việc, Saga, sự cố, gói bằng chứng; `U-T91-IE1`, `U-T91-CB1`, S-T91-DVC.

**Các bước.**

1. Với mỗi API `GET` có `{id}` (khoảng 45 API), gọi bằng token T91 với id của T90 và so thân với id không tồn tại
2. Gọi các API ghi (`:complete`, `:cancel`, `:approve`, `PUT`) bằng token T91 với id của T90
3. Gọi các API danh sách bằng token T91
4. Tìm chuỗi `canary` của T90 trong mọi phản hồi của T91

**Kết quả mong đợi.** Mọi lệnh `404-ẩn` ERR-11-001, thân giống "không tồn tại" trừ `traceId`; không có dòng nào của T90 trong danh sách T91; không thay đổi dữ liệu T90; canary T90 không xuất hiện.
:::

#### TC-11-133 · Cô lập ở CSDL: bộ ph11_isolation_test.sql <!--k:iso-db-->
::: dac-ta
**Mục đích.** Chứng minh RLS, phân vùng, mẫu `COMMON`, vai trò và schema engine chặn truy cập chéo tenant ở CSDL.

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** DB

**Truy vết.** BR-11-032, 004, 007, 023 · NFR-11-020, 021 · EN-11-02, 08, 09, 21

**Tiền điều kiện, dữ liệu.** CSDL rỗng đã nạp `ph11_bpm.sql`; vai trò có quyền tạo vai trò; T90, T91.

**Các bước.**

1. Chạy `psql -v ON_ERROR_STOP=1 -d datahub -f ph11_isolation_test.sql`
2. Đọc số khối `PASS`
3. Chạy lại với `SET ROLE` của dịch vụ ứng dụng

**Kết quả mong đợi.** Mọi khối `PASS`, không `RAISE`; T91 không đọc, sửa, xóa, chèn dòng T90 (SQLSTATE 42501 hoặc 0 dòng); khóa lũy đẳng, bốn mắt, bảng chỉ thêm, outbox không chứa giá trị biến đúng; vai trò dịch vụ không truy cập `ph11_flowable` ngoài dịch vụ PH-11.
:::

#### TC-11-134 · Mỗi tenant một tenantId Flowable <!--k:iso-engine-->
::: dac-ta
**Mục đích.** Chứng minh truy vấn engine lọc `tenantId`; cùng `processKey` ở hai tenant dùng đúng định nghĩa của mình.

**Loại.** Bảo mật

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** BR-11-032, 006 · FR-11-008, 018 · NFR-11-020

**Tiền điều kiện, dữ liệu.** `LT_KHAI_SINH` v3 ở T90; `LT_KHAI_SINH` v1 khác nội dung ở T91.

**Các bước.**

1. Đọc `ACT_RE_DEPLOYMENT` theo `TENANT_ID_`
2. S-DVC T90 và S-T91-DVC khởi tạo cùng `businessKey`
3. Đọc `PROC_DEF_ID_` của hai phiên
4. Kiểm quyền vai trò khác (ngoài dịch vụ) với `ACT_*`

**Kết quả mong đợi.** Mỗi deployment gắn `tenantId = t90` hoặc `t91`; phiên T90 dùng định nghĩa T90, phiên T91 dùng T91; vai trò ngoài dịch vụ bị từ chối truy cập `ACT_*`.
:::

#### TC-11-135 · ACL Kafka theo tiền tố và nội dung lệnh <!--k:iso-kafka-->
::: dac-ta
**Mục đích.** Chứng minh client T91 không đọc, không ghi topic `t90.bpm.*` và lệnh không mang dữ liệu tenant khác.

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** KT

**Truy vết.** EVT-11-03, 17, 18, 19 · BR-11-014, 032 · NFR-11-020

**Tiền điều kiện, dữ liệu.** Client OAUTHBEARER của T91; `ph04-sim` T91.

**Các bước.**

1. Client T91 đăng ký đọc `t90.bpm.instance.started.v1`
2. Client T91 ghi `t90.bpm.service.completed.v1` với `commandId` của T90
3. Quét các lệnh `t91.bpm.service.requested.v1` tìm `businessKey` T90

**Kết quả mong đợi.** Bước 1 và 2 bị từ chối theo ACL; lệnh giả không tương quan được phiên T90 (không có ERR-11-103 ở T90); bước 3 không có dữ liệu T90.
:::

#### TC-11-136 · Trùng khóa nghiệp vụ giữa hai tenant <!--k:iso-collision-->
::: dac-ta
**Mục đích.** Chứng minh cùng `businessKey`, `messageName`, `Idempotency-Key` ở hai tenant không đụng nhau.

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** BR-11-007, 022 · FR-11-018, 030, 055 · API-11-049, 069, 104 · ERR-11-035

**Tiền điều kiện, dữ liệu.** Hai phiên `HS-T90-2026-0001` ở T90 và T91 cùng `processKey`; cùng `Idempotency-Key`.

**Các bước.**

1. Hai client khởi tạo với cùng khóa
2. T91 gửi `HO_SO_BO_SUNG` cho `businessKey` đó
3. S-DVC và S-T91-DVC tra tiến độ

**Kết quả mong đợi.** Hai phiên độc lập; thông điệp chỉ đánh thức phiên T91; mỗi client chỉ thấy tiến độ của tenant mình.
:::

### TS-11-26 · Phân quyền theo ma trận PERM-11 và bốn mắt

**Mục tiêu.** Chứng minh mọi API chặn đúng vai trò, bốn mắt không có đường vòng, scope máy hẹp đúng.

**Phủ.** API-11-001…127; FR-11-008, 009, 014, 025, 026, 027, 053; BR-11-004, 021; NFR-11-020; ERR-11-005, 020, 034.

#### TC-11-137 · Ma trận quyền: mọi API, mọi vai trò <!--k:perm-matrix-->
::: dac-ta
**Mục đích.** Chứng minh mỗi API trả `200` cho vai trò được phép và `403` hoặc `401` cho vai trò khác, 100 % API có ca âm.

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** API-11-001…127 · ERR-00-403, 401 · NFR-11-020 · PERM-11-read, PERM-11-model, PERM-11-publish, PERM-11-instance, PERM-11-instance-admin, PERM-11-task-admin, PERM-11-compensate, PERM-11-config, PERM-11-audit-read

**Tiền điều kiện, dữ liệu.** Mười chủ thể: PA, PO, TA, TO, IE, IA, AU, VW, CB, không vai trò; bảng kỳ vọng sinh từ `x-datahub-permission` của `openapi-bpm.yaml` và ma trận FRS 3.2.

**Các bước.**

1. Sinh ca từ OpenAPI: mỗi cặp (API, chủ thể) một lệnh gọi
2. So mã trả về với kỳ vọng
3. Gọi mỗi API không token, token hết hạn, token sai tenant

**Kết quả mong đợi.** Không lệch ma trận; `403` thân RFC 9457 có `code = ERR-00-403`, `traceId`; không token `401` ERR-00-401; không có API nào thiếu ca âm.
:::

#### TC-11-138 · Bốn mắt ở mọi điểm bắt buộc <!--k:four-eyes-->
::: dac-ta
**Mục đích.** Chứng minh người gửi, người đề nghị không tự duyệt ở sáu điểm bốn mắt, kể cả TA có cả hai quyền.

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-008, 009, 014, 025, 026, 027, 053, 015 · ERR-11-005 · BR-11-004, 020, 021 · NFR-11-020

**Tiền điều kiện, dữ liệu.** TA có cả quyền soạn lẫn duyệt (SIT); TA2, IE1, IE2, IA1; sáu đối tượng chờ duyệt: bản phát hành, miễn bù trừ, sửa biến, chuyển bước, di trú, bỏ qua bước bù trừ, mẫu `COMMON`.

**Các bước.**

1. Với từng đối tượng: người đề nghị tự duyệt
2. Người sửa cuối tự duyệt (bản phát hành)
3. Người khác có quyền duyệt
4. Đọc KT của hai người

**Kết quả mong đợi.** Hai lần đầu `403` ERR-11-005 ở cả bảy điểm; người khác duyệt được `200`; kiểm toán ghi cả hai người, lý do, thời điểm.
:::

#### TC-11-139 · Phạm vi của tài khoản máy <!--k:scope-machine-->
::: dac-ta
**Mục đích.** Chứng minh scope máy chỉ làm đúng việc được cấp.

**Loại.** Âm, Bảo mật

**Ưu tiên.** P1

**Tự động.** API

**Truy vết.** FR-11-018, 035, 055, 028 · API-11-049, 104, 072, 051 · ERR-11-020, 034 · NFR-11-020

**Tiền điều kiện, dữ liệu.** S-DVC, S-DVC2, S-MC, S-PH04, S-PH01.

**Các bước.**

1. S-DVC gọi `GET /models`, `POST /tasks/{id}:complete`
2. S-MC gọi `GET /tasks`, đọc biến `SENSITIVE`
3. S-PH04 gọi API REST bất kỳ
4. S-DVC `GET /instances/{id}` của phiên do client khác khởi tạo
5. S-DVC2 khởi tạo `M-KS`

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403. Bước 2 có danh sách, không có biến `SENSITIVE`. Bước 3 `403` (chỉ dùng Kafka). Bước 4 `403` ERR-11-034. Bước 5 `403` ERR-11-020.
:::

### TS-11-27 · Che dữ liệu cá nhân trong biến, sự kiện, lệnh, nhật ký

**Mục tiêu.** Chứng minh không có giá trị biến `SENSITIVE` dạng rõ ngoài vùng mã hóa và tiến độ DVC không lộ thông tin nội bộ.

**Phủ.** FR-11-016, 022, 028, 055, 056; BR-11-014, 015; NFR-11-021; tiêu chí chấp nhận 7.

#### TC-11-140 · Quét rò rỉ giá trị biến SENSITIVE trên toàn hệ thống <!--k:leak-scan-->
::: dac-ta
**Mục đích.** Chứng minh 0 giá trị `SENSITIVE` dạng rõ ở log, vết, chỉ số, lệnh, sự kiện, outbox, bảng engine.

**Loại.** Bảo mật

**Ưu tiên.** P1

**Tự động.** ZAP

**Truy vết.** NFR-11-021 · BR-11-014 · FR-11-016, 028, 056, 022 · EVT-11-03, 04, 17, 20

**Tiền điều kiện, dữ liệu.** T96; 200 phiên `F-DLCN` chạy `LT_KHAI_SINH` đầu cuối, có sự cố, Saga, hủy; canary `DH-CANARY-leak` trong `hoTenTre`, `001099000123` trong `soDinhDanhMe`.

**Các bước.**

1. Chạy 200 phiên
2. Quét log ứng dụng, vết OTel, chỉ số Prometheus, bản tin Kafka mọi topic `t96.bpm.*`, `outbox_event.payload`, `ACT_RU_VARIABLE_`, `ACT_HI_VARINST`, thông báo
3. Đọc cột mã hóa của `ph11_bpm`

**Kết quả mong đợi.** 0 lần xuất hiện canary và số định danh dạng rõ ở mọi nơi trừ cột mã hóa của biến; `ACT_*` chỉ chứa mã hóa hoặc tham chiếu.
:::

#### TC-11-141 · Che hiển thị và mở che có điều kiện <!--k:mask-ui-api-->
::: dac-ta
**Mục đích.** Chứng minh che theo `dataClass`, mở che cần quyền và lý do, người vận hành nền tảng không xem biến.

**Loại.** Bảo mật

**Ưu tiên.** P2

**Tự động.** API

**Truy vết.** FR-11-016, 022, 037 · API-11-055, 073 · BR-11-014 · PERM-09-unmask

**Tiền điều kiện, dữ liệu.** `F-DLCN`; TA có `PERM-09-unmask`; TO không; PO có phiếu sự cố.

**Các bước.**

1. TA, TO, PO, CB-TP đọc biến phiên và việc
2. TA mở che có lý do
3. Xuất lịch sử bằng AU

**Kết quả mong đợi.** `SENSITIVE` luôn `****` trừ TA có quyền và lý do (KT: có); `RESTRICTED` che với người thiếu quyền; PO không thấy biến; tệp xuất chỉ chứa băm và biến đã che.
:::

#### TC-11-142 · Quét phản hồi tiến độ DVC quy mô lớn <!--k:progress-leak-->
::: dac-ta
**Mục đích.** Chứng minh 500 phản hồi tiến độ, kể cả lỗi, chỉ chứa `publicName`, trạng thái, hạn, thông điệp.

**Loại.** Bảo mật

**Ưu tiên.** P1

**Tự động.** ZAP

**Truy vết.** FR-11-055 · API-11-104 · BR-11-015, 014 · NFR-11-021

**Tiền điều kiện, dữ liệu.** T96; 500 hồ sơ nhiều trạng thái (đang xử lý, lỗi kỹ thuật, bù trừ, hủy); từ điển cấm như `progress-mask`.

**Các bước.**

1. S-DVC tra 500 hồ sơ
2. Quét thân, tiêu đề, thông điệp lỗi bằng từ điển cấm

**Kết quả mong đợi.** 0 khớp từ điển cấm; trường chỉ thuộc tập cho phép (`businessKey`, `displayStatus`, `percentEstimate`, `dueAt`, `steps`, `message`).
:::

### TS-11-28 · Idempotency khởi tạo, lệnh, kết quả, thông điệp, sự kiện

**Mục tiêu.** Chứng minh mọi điểm vào lặp lại hoặc giao lại đều không tác dụng kép.

**Phủ.** FR-11-018, 019, 028, 029, 030; BR-11-007, 022; API-11-049, 069, 071; ERR-11-104.

#### TC-11-143 · Khởi tạo đồng thời cùng hồ sơ <!--k:idem-concurrent-->
::: dac-ta
**Mục đích.** Chứng minh 50 lượt khởi tạo đồng thời cùng `businessKey` chỉ tạo một phiên.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-018 · API-11-049 · BR-11-007, 023

**Tiền điều kiện, dữ liệu.** T97; hai bản sao `dh-platform`; `businessKey` mới.

**Các bước.**

1. 50 luồng song song `POST /instances` cùng `businessKey`, một nửa cùng `Idempotency-Key`
2. Đếm `instance_index`, `ACT_RU_EXECUTION`, `outbox_event`

**Kết quả mong đợi.** Đúng một phiên, một bản tin `instance.started`; 49 phản hồi `200` cùng `instanceId` (hoặc phản hồi lần đầu); không `ACT_RU_EXECUTION` thừa.
:::

#### TC-11-144 · Giao lại kết quả, thông điệp, sự kiện khởi tạo <!--k:idem-redelivery-->
::: dac-ta
**Mục đích.** Chứng minh Kafka giao lại 5 lần mỗi loại chỉ tác dụng một lần, kể cả khi pod chết trước khi cam kết offset.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** FR-11-029, 030, 019 · EVT-11-18 · ERR-11-104 · BR-11-022

**Tiền điều kiện, dữ liệu.** Kết quả `completed`, thông điệp `HO_SO_BO_SUNG`, sự kiện khởi tạo PH-10; Chaos tắt pod.

**Các bước.**

1. Giao mỗi loại 5 lần cùng `id`
2. Tắt pod sau khi ghi `inbox_message` và trước khi cam kết offset
3. Đếm tác dụng

**Kết quả mong đợi.** `inbox_message` duy nhất theo `id`; phiên đi tiếp một lần, không bản tin tiến độ trùng; bộ đếm trùng tăng (ERR-11-104).
:::

#### TC-11-145 · Lệnh service task gửi lại không gọi HTTT hai lần <!--k:idem-command-->
::: dac-ta
**Mục đích.** Chứng minh gửi lại cùng `commandId` sau lỗi Kafka, và lệnh mới sau `:resend`, đều được PH-04 chống trùng.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** KT

**Truy vết.** FR-11-028 · API-11-071 · EVT-11-17 · BR-11-022

**Tiền điều kiện, dữ liệu.** `ph04-sim` đếm số lần gọi HTTT giả theo `commandId`; Kafka chập chờn.

**Các bước.**

1. Gây lỗi Kafka khi đẩy lệnh rồi hồi phục
2. TO `:resend` khi kết quả đã tới
3. Đọc số lần gọi HTTT giả

**Kết quả mong đợi.** Mỗi `commandId` gọi HTTT giả đúng một lần; lệnh cũ không chạy lại sau khi có lệnh mới; không bước nào thực thi hai lần.
:::

### TS-11-29 · Bền trạng thái, sống sót khởi động lại, mất một bản sao

**Mục tiêu.** Chứng minh tắt cứng pod hoặc khởi động lại toàn bộ bản sao không làm mất phiên, không chạy trùng job và không phục hồi sai bước.

**Phủ.** NFR-11-008…012; tiêu chí chấp nhận 4; FR-11-018, 028, 038.

#### TC-11-146 · Tắt cứng pod ngay sau hoàn thành bước <!--k:kill-pod-step-->
::: dac-ta
**Mục đích.** Chứng minh chuyển bước đã trả thành công đều có trong CSDL, phiên tiếp tục đúng bước ở bản sao khác.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** NFR-11-011 · FR-11-038, 028 · BR-11-023

**Tiền điều kiện, dữ liệu.** PERF 4 bản sao; 100 phiên `LT_KHAI_SINH` đang chạy; `kubectl delete pod --grace-period=0`.

**Các bước.**

1. CB hoàn thành 100 việc, ngay khi nhận `200` tắt cứng pod phục vụ
2. Đợi bản sao khác nhận
3. So `current_elements` và lệnh PH-04 đã gửi với danh sách mong đợi

**Kết quả mong đợi.** 100 % bước đã trả `200` có trong CSDL; không bước nào chạy lại; không lệnh PH-04 trùng; không phiên mất.
:::

#### TC-11-147 · Mất một bản sao đang giữ khóa job, mở rộng ngang <!--k:kill-pod-job-->
::: dac-ta
**Mục đích.** Chứng minh job được bản khác nhận trong 5 phút, chạy một lần; mở rộng 2 đến 6 bản sao không xử lý trùng.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** NFR-11-008, 009 · FR-11-031, 047 · BR-11-022

**Tiền điều kiện, dữ liệu.** PERF 4 bản sao; 2.000 job hẹn giờ đến hạn; một pod giữ khóa 200 job.

**Các bước.**

1. Tắt cứng pod giữ khóa
2. Đo thời gian đến khi 200 job được nhận
3. Tăng từ 2 lên 6 bản sao khi hàng đợi job sâu
4. Đếm số lần thực thi từng job

**Kết quả mong đợi.** Job được nhận ≤ 5 phút (hết hạn khóa); mỗi job chạy đúng một lần; mở rộng ngang không chạy trùng.
:::

#### TC-11-148 · Khởi động lại toàn bộ bản sao với 50.000 phiên <!--k:restart-all-->
::: dac-ta
**Mục đích.** Chứng minh 100 % phiên tiếp tục đúng bước sau khi khởi động lại toàn bộ bản sao.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** NFR-11-012, 005 · FR-11-018, 031 · tiêu chí chấp nhận 4

**Tiền điều kiện, dữ liệu.** T98 `F-PERF`: 50.000 phiên `RUNNING`, 5.000 việc mở, 1.000 hẹn giờ chờ.

**Các bước.**

1. Ghi ảnh chụp `waitState`, `current_elements`, việc mở
2. `kubectl rollout restart` toàn bộ
3. So ảnh chụp trước và sau
4. Cho CLK qua hạn của 1.000 hẹn giờ

**Kết quả mong đợi.** 100 % phiên giữ đúng bước và `waitState`; 5.000 việc còn nguyên ở hộp việc; 1.000 hẹn giờ nổ đúng giờ một lần.
:::

#### TC-11-149 · Phục hồi từ sao lưu <!--k:restore-db-->
::: dac-ta
**Mục đích.** Chứng minh RPO ≤ 5 phút, RTO ≤ 30 phút, sau phục hồi không phát lại sự kiện đã gửi.

**Loại.** Chịu lỗi

**Ưu tiên.** P2

**Tự động.** Chaos

**Truy vết.** NFR-11-010 · BR-11-022, 023

**Tiền điều kiện, dữ liệu.** PERF `pg-core` có sao lưu liên tục; tải nền 50 phiên/s.

**Các bước.**

1. Ghi mốc giao dịch cuối
2. Phá hủy phiên bản chính, phục hồi
3. Đo thời gian và mất mát
4. Quan sát outbox và `inbox_message`

**Kết quả mong đợi.** Mất dữ liệu ≤ 5 phút giao dịch; dịch vụ hoạt động lại ≤ 30 phút; không bản tin tiến độ trùng với `id` cũ; job và hẹn giờ tiếp tục.
:::

### TS-11-30 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh các chỉ tiêu độ trễ, thông lượng, sẵn sàng và quy mô của FRS §8.1 đạt trên môi trường PERF.

**Phủ.** NFR-11-001…007, 013, 014, 015, 018, 023, 024.

#### TC-11-150 · Khởi tạo phiên: độ trễ và thông lượng khi dồn <!--k:perf-start-->
::: dac-ta
**Mục đích.** Chứng minh p99 ≤ 200 ms ở 100 phiên/s và ≥ 200 phiên/s trong 5 phút, lỗi < 0,1 %, 4 bản sao, đã có 50.000 phiên.

**Loại.** Hiệu năng

**Ưu tiên.** P1

**Tự động.** k6

**Truy vết.** NFR-11-001, 004, 005 · FR-11-018 · API-11-049

**Tiền điều kiện, dữ liệu.** PERF 4 bản sao; T98 50.000 phiên `RUNNING`; 20 client S-DVC.

**Các bước.**

1. k6 100 phiên/s trong 15 phút, đo p99
2. k6 tăng tới 200 phiên/s giữ 5 phút
3. So p99 của hoàn thành việc, tra tiến độ với lúc trước khi có 50.000 phiên

**Kết quả mong đợi.** p99 ≤ 200 ms; thông lượng ≥ 200 phiên/s, lỗi < 0,1 %; chỉ tiêu NFR-11-001…003 không giảm với 50.000 phiên.
:::

#### TC-11-151 · Hoàn thành việc và xử lý kết quả service task <!--k:perf-task-->
::: dac-ta
**Mục đích.** Chứng minh p99 hoàn thành việc ≤ 300 ms với biểu mẫu 30 trường và p99 xử lý kết quả ≤ 500 ms ở 200 kết quả/s.

**Loại.** Hiệu năng

**Ưu tiên.** P1

**Tự động.** k6

**Truy vết.** NFR-11-002, 003 · FR-11-038, 029 · API-11-076

**Tiền điều kiện, dữ liệu.** T97; 5.000 việc mở có biểu mẫu 30 trường; `ph04-sim` trả 200 kết quả/s.

**Các bước.**

1. k6 hoàn thành việc ở 50 lượt/s
2. `ph04-sim` trả kết quả 200/s trong 5 phút
3. Đo theo `traceId` từ lúc nhận bản tin đến khi execution đi tiếp

**Kết quả mong đợi.** p99 API-11-076 ≤ 300 ms; p99 xử lý kết quả ≤ 500 ms.
:::

#### TC-11-152 · Tra tiến độ và sẵn sàng <!--k:perf-progress-->
::: dac-ta
**Mục đích.** Chứng minh p99 tra tiến độ ≤ 100 ms, trúng đệm ≥ 80 %, sẵn sàng ba API chính ≥ 99,9 %.

**Loại.** Hiệu năng

**Ưu tiên.** P1

**Tự động.** k6

**Truy vết.** NFR-11-006, 007 · FR-11-055 · API-11-104, 049, 076

**Tiền điều kiện, dữ liệu.** T98; 50.000 `businessKey`; thăm dò mỗi 10 giây trong 24 giờ.

**Các bước.**

1. k6 tra tiến độ 500 lượt/s theo phân bố 80 % lặp lại
2. Thăm dò ba API trong 24 giờ không bảo trì
3. Ghi tỷ lệ trúng đệm

**Kết quả mong đợi.** p99 ≤ 100 ms; trúng đệm ≥ 80 %; sẵn sàng 24 giờ ≥ 99,9 % (số liệu tháng đo ở sản xuất, Q11-41).
:::

#### TC-11-153 · Kiểm tra tĩnh và trình thiết kế <!--k:perf-design-->
::: dac-ta
**Mục đích.** Chứng minh kiểm tra tĩnh 200 phần tử ≤ 2 giây, mở 300 phần tử ≤ 3 giây, kéo thả ≤ 100 ms.

**Loại.** Hiệu năng

**Ưu tiên.** P2

**Tự động.** E2E

**Truy vết.** NFR-11-013, 014 · FR-11-005, 003 · UI-11-04

**Tiền điều kiện, dữ liệu.** Mô hình 200 và 300 phần tử; Chromium hiện hành, máy văn phòng 8 GB.

**Các bước.**

1. `:validate?mode=FULL` mô hình 200 phần tử, đo
2. Playwright mở mô hình 300 phần tử, đo đến lúc vẽ xong
3. Đo phản hồi kéo thả

**Kết quả mong đợi.** Kiểm tra ≤ 2 giây (không tính gọi PH-04); mở ≤ 3 giây; phản hồi kéo thả ≤ 100 ms.
:::

#### TC-11-154 · Hộp việc, sự kiện tiến độ, xuất bằng chứng, dọn lịch sử <!--k:perf-events-->
::: dac-ta
**Mục đích.** Chứng minh độ trễ hộp việc, sự kiện tiến độ, xuất lịch sử và tác động của dọn lịch sử.

**Loại.** Hiệu năng

**Ưu tiên.** P2

**Tự động.** k6

**Truy vết.** NFR-11-015, 018, 023, 024 · FR-11-035, 056, 057, 064, 063

**Tiền điều kiện, dữ liệu.** T97, T99; phiên 50 bước; lô 1.000 phiên cần dọn.

**Các bước.**

1. Tạo 1.000 việc, đo thời gian việc hiện ở hộp (p95)
2. Đo từ chuyển bước đến bản tin (p95)
3. Xuất lịch sử phiên 50 bước và gói tuân thủ
4. Chạy dọn lô 1.000 phiên khi tải nền

**Kết quả mong đợi.** Hộp việc ≤ 5 giây; sự kiện ≤ 10 giây; lịch sử ≤ 5 giây, gói tuân thủ ≤ 2 phút; p99 API tăng ≤ 10 % khi dọn.
:::

### TS-11-31 · Hạn theo lịch làm việc: bộ 200 ca và đầu cuối

**Mục tiêu.** Chứng minh tính hạn không sai lệch trên bộ 200 ca lịch mẫu và đúng ở luồng đầu cuối có ngày lễ, làm bù, tạm dừng chờ bổ sung.

**Phủ.** FR-11-045…050; BR-11-017, 018, 019; NFR-11-016; tiêu chí chấp nhận 6; ADR 114.

#### TC-11-155 · Bộ 200 ca lịch mẫu không sai lệch <!--k:cal-200-->
::: dac-ta
**Mục đích.** Chứng minh hàm tính hạn đúng trên 200 ca gồm lễ, nghỉ bù, làm bù, nghỉ đột xuất, giờ ngoài giờ, theo ADR 114.

**Loại.** Độ chính xác

**Ưu tiên.** P1

**Tự động.** UT

**Truy vết.** NFR-11-016 · FR-11-046 · BR-11-017, 018 · API-11-093

**Tiền điều kiện, dữ liệu.** `F-LICH-200` ở T94; hạn kỳ vọng do hai người tính tay độc lập và đã đối chiếu.

**Các bước.**

1. Chạy `compute-due` cho 200 ca
2. So từng `dueAt`
3. Lặp ở `11.due.receiveAfterHoursRule = SAME_DAY`

**Kết quả mong đợi.** Sai lệch 0 ca; `explain[]` khớp từng ngày bị bỏ; quy tắc tiếp nhận ngoài giờ đổi đúng theo tham số.
:::

#### TC-11-156 · Luồng hạn đầu cuối qua ngày lễ và ngày làm bù <!--k:cal-e2e-->
::: dac-ta
**Mục đích.** Chứng minh phiên `LT_KHAI_SINH` tiếp nhận 16:45 thứ Sáu 30/4/2027 có hạn 17:00 10/5, đổi thành 17:00 8/5 khi thêm ngày làm bù, nhắc và quá hạn đúng mốc.

**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** CLK

**Truy vết.** FR-11-045, 046, 047, 048, 050 · API-11-091, 094 · BR-11-017, 019 · NFR-11-016

**Tiền điều kiện, dữ liệu.** T90 `LICH-T90-2027`; phiên `HS-28` và `HS-29`; `11.due.scanMinutes = 1`.

**Các bước.**

1. Tạo `HS-28` lúc 16:45 30/4/2027
2. TA thêm `MAKEUP_WORKDAY` 8/5/2027
3. CLK tới mốc nhắc rồi quá hạn của `HS-28`
4. CB hoàn thành `HS-29` trước hạn
5. VW `GET /reports/due`

**Kết quả mong đợi.** `HS-28` hạn 10/5 17:00, sau khi thêm làm bù 8/5 17:00; nhắc và quá hạn trễ ≤ 5 phút, `OVERDUE` rồi `MISSED`; `HS-29` `MET`; báo cáo khớp.
:::

### TS-11-32 · Nhất quán giao dịch, outbox và Saga

**Mục tiêu.** Chứng minh chuyển trạng thái và sự kiện cùng cam kết, Saga không dùng giao dịch phân tán và khởi động đúng thời hạn (ADR 113).

**Phủ.** BR-11-010, 023; FR-11-051, 056; NFR-11-017; EVT-11-13.

#### TC-11-157 · Chèn lỗi ở mọi điểm của giao dịch chuyển bước <!--k:outbox-atomic-->
::: dac-ta
**Mục đích.** Chứng minh không có bản tin mà trạng thái chưa cam kết và không có trạng thái cam kết mà thiếu bản tin.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** BR-11-023 · FR-11-056, 038, 018 · EVT-11-04, 10 · NFR-11-011

**Tiền điều kiện, dữ liệu.** Bộ chèn lỗi ngẫu nhiên 1.000 lần ở điểm: trước ghi biến, sau engine, sau ghi `instance_index`, trước `commit`; T97.

**Các bước.**

1. Chạy 1.000 lần hoàn thành việc có chèn lỗi ngẫu nhiên
2. Với mỗi lần so trạng thái `task_index`, `instance_index`, `outbox_event` và bản tin Kafka

**Kết quả mong đợi.** Mọi lần: `task_index`, `instance_index`, `outbox_event` cùng một giao dịch `ph11_bpm` (cùng đổi hoặc không đổi); lỗi sau cam kết engine được đối soát dựng lại, đúng một bản tin; 0 bản tin cho thay đổi chưa cam kết.
:::

#### TC-11-158 · Khởi động bù trừ và không giao dịch phân tán <!--k:saga-latency-->
::: dac-ta
**Mục đích.** Chứng minh Saga bắt đầu ≤ 30 giây sau lỗi bước (p95) và cấu hình không dùng giao dịch XA, theo ADR 113.

**Loại.** Hiệu năng

**Ưu tiên.** P1

**Tự động.** IT

**Truy vết.** NFR-11-017 · BR-11-010, 011 · FR-11-051 · EVT-11-13

**Tiền điều kiện, dữ liệu.** T97; 100 phiên cùng lỗi `capTheBHYT`; cấu hình nguồn dữ liệu và Flowable.

**Các bước.**

1. Gây lỗi 100 phiên đồng thời
2. Đo `saga_log.startedAt` trừ thời điểm nhận lỗi
3. Kiểm cấu hình không có `XADataSource`, không `JTA`

**Kết quả mong đợi.** p95 ≤ 30 giây; không có thành phần giao dịch phân tán; nhất quán đạt bằng bù trừ.
:::

### TS-11-33 · Chịu lỗi tích hợp: CSDL, PH-04, PH-12

**Mục tiêu.** Chứng minh ngừng CSDL, PH-04, PH-12 không làm mất dữ liệu và phục hồi đúng.

**Phủ.** NFR-11-007, 010; FR-11-018, 028, 029, 034; ERR-11-046, 102, 113.

#### TC-11-159 · CSDL ngừng <!--k:db-down-->
::: dac-ta
**Mục đích.** Chứng minh CSDL ngừng thì API `503`, phiên đã cam kết còn nguyên, hệ thống tự phục hồi.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** FR-11-018 · ERR-11-046 · NFR-11-007, 010

**Tiền điều kiện, dữ liệu.** T95; ngừng `pg-core` 2 phút.

**Các bước.**

1. Ngừng CSDL, S-DVC `POST /instances`
2. Đọc kiểm tra sẵn sàng
3. Phục hồi, đếm phiên và job

**Kết quả mong đợi.** `503` ERR-11-046; bộ cân bằng tải loại pod khỏi dịch vụ; sau phục hồi job chạy tiếp, phiên đã cam kết còn đủ, không phiên nửa vời.

**Thông báo hiển thị.** "Dịch vụ quy trình tạm thời không sẵn sàng. Thử lại sau."
:::

#### TC-11-160 · PH-04 ngừng một giờ <!--k:ph04-down-->
::: dac-ta
**Mục đích.** Chứng minh lệnh chờ trong Kafka, phiên giữ `WAITING_SERVICE`, xử lý đúng khi PH-04 hồi phục.

**Loại.** Chịu lỗi

**Ưu tiên.** P1

**Tự động.** Chaos

**Truy vết.** FR-11-028, 029 · ERR-11-102 · EVT-11-17 · BR-11-022

**Tiền điều kiện, dữ liệu.** T95; `ph04-sim` ngừng 60 phút; 100 phiên đến `guiTuPhap`.

**Các bước.**

1. Ngừng `ph04-sim`
2. Chạy 100 phiên tới bước tự động
3. Đợi qua `timeoutAt` của 20 phiên
4. Phục hồi `ph04-sim`

**Kết quả mong đợi.** Lệnh tồn trong Kafka; phiên `WAITING_SERVICE`; 20 phiên quá hạn mở sự cố ERR-11-102; sau phục hồi kết quả tương quan đúng, không lệnh trùng.
:::

#### TC-11-161 · PH-12 ngừng <!--k:ph12-down-->
::: dac-ta
**Mục đích.** Chứng minh việc không mất khi PH-12 ngừng và xác thực vẫn đúng trong thời hạn đệm khóa.

**Loại.** Chịu lỗi

**Ưu tiên.** P2

**Tự động.** Chaos

**Truy vết.** FR-11-034, 035 · ERR-11-113 · NFR-11-020

**Tiền điều kiện, dữ liệu.** T95; PH-12 giả ngừng; token còn hạn.

**Các bước.**

1. Tạo việc `ORG_UNIT` khi PH-12 ngừng
2. Gọi API bằng token còn hạn
3. Phục hồi PH-12

**Kết quả mong đợi.** Việc vào `11.task.fallbackGroup` kèm ERR-11-113; API vẫn xác thực được bằng khóa đã đệm; sau phục hồi việc được giao lại đúng ứng viên.
:::

### TS-11-34 · Truy cập và quan sát

**Mục tiêu.** Chứng minh trình thiết kế và màn xử lý việc đạt WCAG 2.2 AA, mọi lệnh có dấu vết và chỉ số vận hành đủ.

**Phủ.** NFR-11-019, 022; UI-11-04, 15; FR-11-003, 038, 061.

#### TC-11-162 · WCAG 2.2 AA, bàn phím, giấy phép bpmn.io <!--k:a11y-->
::: dac-ta
**Mục đích.** Chứng minh UI-11-04, 15 không lỗi truy cập nghiêm trọng, trình thiết kế dùng được bằng bàn phím, logo bpmn.io hiển thị.

**Loại.** Truy cập

**Ưu tiên.** P2

**Tự động.** E2E

**Truy vết.** NFR-11-022 · UI-11-04, 15 · FR-11-003, 038

**Tiền điều kiện, dữ liệu.** Playwright, axe-core; chế độ chỉ bàn phím.

**Các bước.**

1. Chạy axe-core trên UI-11-04 và UI-11-15
2. Chỉ dùng bàn phím: chọn phần tử, nối, sửa thuộc tính, hoàn thành việc
3. Kiểm logo bpmn.io trên trình thiết kế
4. Kiểm tương phản và nhãn

**Kết quả mong đợi.** 0 lỗi mức serious, critical; mọi thao tác thực hiện được bằng bàn phím với thứ tự Tab hợp lý; logo bpmn.io luôn hiển thị.
:::

#### TC-11-163 · Dấu vết, chỉ số, cảnh báo <!--k:observe-->
::: dac-ta
**Mục đích.** Chứng minh một `traceId` theo suốt từ khởi tạo đến sự kiện và chỉ số vận hành đủ.

**Loại.** Dương

**Ưu tiên.** P2

**Tự động.** IT

**Truy vết.** NFR-11-019 · FR-11-061 · EVT-11-17, 04 · ERR-11-110

**Tiền điều kiện, dữ liệu.** PH-13 giả; `traceparent` ở yêu cầu khởi tạo.

**Các bước.**

1. S-DVC `POST /instances` kèm `traceparent`
2. Theo `traceId` qua API, lệnh PH-04, kết quả, sự kiện
3. Đọc chỉ số của bảng vận hành
4. Gây bù trừ thất bại

**Kết quả mong đợi.** Mọi API, lệnh, sự kiện mang `traceparent`; PH-13 thấy một vết liền mạch; đủ chỉ số; bù trừ thất bại sinh cảnh báo P1.
:::

### TS-11-35 · Nghiệm thu đầu cuối LT_KHAI_SINH và DUYET_KET_NAP_HTTT

**Mục tiêu.** Chạy đầu cuối hai quy trình mẫu theo tiêu chí chấp nhận 2 và 3 của FRS §14.

**Phủ.** FR-11-018, 028, 029, 034, 038, 051, 053, 055; tiêu chí chấp nhận 2, 3, 9; BR-11-001, 002, 010.

#### TC-11-164 · LT_KHAI_SINH nhánh thành công <!--k:e2e-ks-->
::: dac-ta
**Mục đích.** Chứng minh hồ sơ liên thông chạy từ Cổng DVC đến hoàn thành qua PH-04, ranh giới PH-11 và PH-04 đúng.

**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** E2E

**Truy vết.** FR-11-018, 028, 029, 034, 038, 055 · BR-11-001, 002 · EVT-11-03, 04, 05

**Tiền điều kiện, dữ liệu.** T90; `M-KS`; S-DVC; CB-TP; `ph04-sim`; `HS-30`.

**Các bước.**

1. S-DVC khởi tạo `HS-30`
2. CB-TP nhận và hoàn thành `nhanHoSo`
3. `ph04-sim` trả `completed` cho `guiTuPhap`, `guiCuTru`, `capTheBHYT`
4. S-DVC tra tiến độ sau mỗi bước
5. Kiểm lệnh Kafka và gọi HTTT

**Kết quả mong đợi.** Phiên `COMPLETED`, `dueResult = MET`; DVC thấy ba bước công khai chuyển `DONE` lần lượt; đủ EVT: `instance.started`, `step.completed`, `instance.completed`; PH-11 chỉ gửi lệnh ý định, không gọi HTTT.
:::

#### TC-11-165 · LT_KHAI_SINH nhánh lỗi BHYT: bù trừ thành công và thất bại chuyển thủ công <!--k:e2e-ks-saga-->
::: dac-ta
**Mục đích.** Chứng minh nhánh BHYT lỗi bù trừ về nhất quán, bù trừ thất bại không im lặng (tiêu chí 2).

**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** E2E

**Truy vết.** FR-11-051, 053, 055 · EVT-11-13, 14, 15 · ERR-11-105, 110 · BR-11-008, 009, 010, 012

**Tiền điều kiện, dữ liệu.** `HS-31` (bù trừ thành công), `HS-32` (bù trừ `guiCuTru` lỗi 3 lần); T92 `11.saga.maxRetries = 2`; TO.

**Các bước.**

1. Gây `BHXH_TU_CHOI` ở `HS-31`, TO xử lý `guiTuPhap` thủ công
2. Gây `BHXH_TU_CHOI` ở `HS-32`, `huyDangKyThuongTru` lỗi
3. TO `:resolve-manual`
4. S-DVC tra tiến độ hai hồ sơ

**Kết quả mong đợi.** `HS-31` `COMPENSATED`, EVT: `saga.compensation.completed`. `HS-32` `FAILED`, EVT: `saga.compensation.failed` và cảnh báo P1, sau xử lý `COMPENSATED`. DVC thấy "Đã hủy", không thấy lỗi kỹ thuật.
:::

#### TC-11-166 · DUYET_KET_NAP_HTTT do PH-01 khởi tạo, hai cấp duyệt, bốn mắt <!--k:e2e-duyet-->
::: dac-ta
**Mục đích.** Chứng minh PH-01 khởi tạo, hai cấp duyệt khác người, kết quả trả về PH-01, theo tiêu chí chấp nhận 3.

**Loại.** Dương

**Ưu tiên.** P1

**Tự động.** E2E

**Truy vết.** FR-11-018, 034, 038, 046, 048 · EVT-11-05 · ERR-11-005 · BR-11-004, 020

**Tiền điều kiện, dữ liệu.** S-PH01; CB-LD (cấp phòng), CB-SO (cấp sở); `HS-33`.

**Các bước.**

1. S-PH01 `POST /instances` `DUYET_KET_NAP_HTTT`
2. CB-LD duyệt `duyetCapPhong`
3. CB-LD thử duyệt `duyetCapSo`
4. CB-SO duyệt `duyetCapSo`
5. Đọc sự kiện `instance.completed`

**Kết quả mong đợi.** Bước 3 `403` ERR-11-005. Phiên `COMPLETED`, `outcome = APPROVED` gửi PH-01; mỗi việc hạn 3 ngày LV, `dueResult = MET`.
:::

## 6. Thủ tục kiểm thử thủ công

Kiểm tra cần người vì máy không quyết định đúng sai hoặc phụ thuộc môi trường thật.

### 6.1. Kiểm thử khám phá trình thiết kế

Hai kỹ sư IE khám phá trình thiết kế bpmn-js 90 phút: vẽ `LT_KHAI_SINH`, dán sơ đồ từ công cụ khác, hoàn tác nhiều bước, mở mô hình 300 phần tử; ghi hành vi khó hiểu, mất dữ liệu khi lưu, sơ đồ khác XML xuất. Kết quả thành lỗi S2 hoặc S3, không thay ca `designer-save`, `perf-design`.

### 6.2. Đối chiếu bộ 200 ca lịch mẫu

Hai người độc lập, không xem kết quả nhau, tính tay hạn 200 ca `F-LICH-200` từ lịch giấy của tỉnh thí điểm. Hai bản tính phải trùng nhau trước khi dùng làm kỳ vọng cho ca `cal-200` (Q11-40). Ca hai người lệch do Trưởng phòng Hành chính quyết định, không do kỹ sư kiểm thử.

### 6.3. Diễn tập sự cố

Ở STAGING, nhóm vận hành diễn tập: Kafka ngừng 30 phút khi hồ sơ đang chạy; bước bù trừ thất bại sau hết lượt thử; sự cố engine trên nhiều phiên. Người đọc cảnh báo ở UI-11-19, 20, 21, xử lý theo tài liệu vận hành, ghi thời gian từ cảnh báo đến xử lý xong.

### 6.4. Xác nhận ranh giới PH-11 và PH-04

Đội tích hợp và đội nghiệp vụ cùng đọc mô hình `LT_KHAI_SINH` và ba ý định, xác nhận bằng văn bản mô hình chỉ mang ý định, luồng PH-04 chỉ làm việc kỹ thuật, không có việc người dùng nằm ở PH-04 (tiêu chí chấp nhận 9, Q11-43). Biên bản đính vào hồ sơ nghiệm thu.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Hệ cũ không có BPM nên không có màn hình để so tương đương. Cán bộ tỉnh thí điểm thực hiện tám kịch bản trên STAGING theo vai trò, trỏ tới `LGC` liên quan gián tiếp và ca tự động đã chạy.

| Mã | Việc cán bộ làm | LGC liên quan | Mong đợi | FR | TC |
|---|---|---|---|---|---|
| UAT-01 | Kỹ sư IE vẽ, cấu hình, kiểm tra và gửi duyệt `LT_KHAI_SINH` v4; IA duyệt | — | Phát hành thành công, phiên cũ vẫn chạy v3 | FR-11-003, 005, 007, 008 | TC-11-010, TC-11-014, TC-11-028, TC-11-030 |
| UAT-02 | Cán bộ Tư pháp nhận hồ sơ, hoàn thành, trả về hoặc yêu cầu bổ sung | LGC-NGSP-002 | Hồ sơ đi đúng bước, hạn dừng khi chờ bổ sung | FR-11-036, 038, 044, 049 | TC-11-060, TC-11-064, TC-11-070 |
| UAT-03 | Lãnh đạo xem việc sắp hạn, quá hạn; cán bộ ủy quyền khi vắng | — | Nhắc và leo thang đúng, ủy quyền có hiệu lực | FR-11-041, 047, 048 | TC-11-086, TC-11-088, TC-11-077 |
| UAT-04 | Nhân viên Cổng DVC tra tiến độ hồ sơ của công dân | LGC-NGSP-002 | Thấy ba bước công khai, không thấy thông tin nội bộ | FR-11-055 | TC-11-112, TC-11-113 |
| UAT-05 | Vận hành xử lý hồ sơ BHYT lỗi: bù trừ tự động rồi thủ công | LGC-BUS-037 | Hồ sơ về nhất quán, không bước lệch nào bị bỏ sót | FR-11-051, 053 | TC-11-103, TC-11-109, TC-11-165 |
| UAT-06 | Vận hành xử lý sự cố engine và thử lại | LGC-BUS-037 | Sự cố mở, thử lại, đóng đúng | FR-11-060 | TC-11-121 |
| UAT-07 | Quản trị tỉnh khai lịch, đổi tham số, xem hạn qua ngày lễ | LGC-NGSP-004 | Hạn đúng theo lịch tỉnh, tham số có hiệu lực | FR-11-045, 046, 062 | TC-11-081, TC-11-083, TC-11-124 |
| UAT-08 | Kiểm toán viên xuất lịch sử và bằng chứng BPMN 2.0 | — | Gói có băm, thuyết minh WS-BPEL, ranh giới PH-11 và PH-04 xác nhận | FR-11-057, 064 | TC-11-128, TC-11-130, TC-11-164 |

: Kịch bản nghiệm thu người dùng

## 8. Ma trận truy vết

Các bảng do `gen_matrix.py` sinh từ các ca ở chương 4 và 5, không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" ghi ba chữ số cuối mã TC-11. FR mức M phải có ít nhất một ca ở mỗi cột (tên FR xem FRS mục 5). Bảng sinh tự động bằng `ph11/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Mức | Dương | Âm | Ca khác |
|---|---|---|---|---|
| FR-11-001 | M | 001 | 002 | — |
| FR-11-002 | M | 003, 009 | 004, 009 | — |
| FR-11-003 | M | 010 | 011 | 153, 162 |
| FR-11-004 | M | 012 | 013 | — |
| FR-11-005 | M | 014, 016 | 015 | 153 |
| FR-11-006 | M | 005 | 006 | — |
| FR-11-007 | M | 028 | 029 | — |
| FR-11-008 | M | 030, 031, 167 | 032, 033, 138, 167 | 134 |
| FR-11-009 | M | 034 | 035, 138 | — |
| FR-11-010 | M | 007 | 008 | — |
| FR-11-011 | S | 017 | 018 | — |
| FR-11-012 | M | 019 | 020 | — |
| FR-11-013 | M | 024 | 025 | — |
| FR-11-014 | M | 026, 167 | 027, 138, 167 | — |
| FR-11-015 | S | 009 | 009, 138 | — |
| FR-11-016 | M | 021 | 022 | 140, 141 |
| FR-11-017 | C | 023 | 023 | — |
| FR-11-018 | M | 036, 037, 164, 166 | 038, 039, 136, 139, 168 | 134, 143, 148, 150, 157, 159 |
| FR-11-019 | S | 040 | 040 | 144 |
| FR-11-020 | S | 041 | 041 | — |
| FR-11-021 | M | 090, 171 | 091, 171 | — |
| FR-11-022 | M | 092 | 093 | 140, 141 |
| FR-11-023 | M | 094 | 095 | — |
| FR-11-024 | M | 096, 097, 170 | 098, 169, 170 | — |
| FR-11-025 | S | 099 | 099, 138 | — |
| FR-11-026 | S | 101 | 102, 138 | — |
| FR-11-027 | S | 100 | 100, 138 | — |
| FR-11-028 | M | 042, 164 | 046, 048, 139 | 140, 145, 146, 160 |
| FR-11-029 | M | 043, 164 | 044, 045, 046, 047 | 144, 151, 160 |
| FR-11-030 | M | 049 | 050, 136 | 144 |
| FR-11-031 | M | 051 | 052 | 147, 148 |
| FR-11-032 | S | 053 | 053 | — |
| FR-11-033 | S | 054 | 054 | — |
| FR-11-034 | M | 055, 164, 166 | 056, 057 | 161 |
| FR-11-035 | M | 058 | 059, 139 | 154, 161 |
| FR-11-036 | M | 060 | 061 | — |
| FR-11-037 | M | 062 | 063 | 141 |
| FR-11-038 | M | 064, 164, 166 | 065 | 146, 151, 157, 162 |
| FR-11-039 | S | 066 | 066 | — |
| FR-11-040 | M | 073 | 074 | — |
| FR-11-041 | S | 077 | 078 | — |
| FR-11-042 | S | 079 | 080 | — |
| FR-11-043 | S | 075 | 076 | — |
| FR-11-044 | M | 068, 070 | 069 | — |
| FR-11-045 | M | 081, 156 | 082 | — |
| FR-11-046 | M | 036, 055, 064, 083, 156, 166 | 085 | 072, 084, 155 |
| FR-11-047 | M | 086, 156 | 087 | 147 |
| FR-11-048 | M | 088, 156, 166 | 089 | — |
| FR-11-049 | M | 070 | 071, 169 | 072 |
| FR-11-050 | S | 120, 156 | 120 | — |
| FR-11-051 | M | 097, 103, 104, 105, 165 | 105, 106 | 158 |
| FR-11-052 | M | 107, 171 | 108, 171 | — |
| FR-11-053 | M | 103, 109, 165 | 110, 138 | — |
| FR-11-054 | S | 111 | 111 | — |
| FR-11-055 | M | 112, 113, 164, 165 | 114, 136, 139 | 142, 152 |
| FR-11-056 | M | 036, 115 | 116 | 140, 154, 157 |
| FR-11-057 | M | 128 | 129 | 154 |
| FR-11-058 | M | 117 | 118 | — |
| FR-11-059 | S | 119 | 119 | — |
| FR-11-060 | M | 121, 123 | 122, 169 | — |
| FR-11-061 | M | 126, 163 | 126 | — |
| FR-11-062 | M | 124 | 125 | — |
| FR-11-063 | M | 127 | 127 | 154 |
| FR-11-064 | M | 130 | 130 | 154 |
| FR-11-065 | M | 131, 171 | 131, 171 | — |
| FR-11-066 | C | 067 | 067 | — |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

Hệ cũ không có BPM; ba mục `LGC` dưới do PH-14 và PH-04 làm chính, PH-11 chỉ điều phối và tra trạng thái. Ca ở cột "TC" kiểm chỗ PH-11 điều phối, không kiểm chức năng của hệ cũ (FRS mục 11.1).

| LGC | FR của PH-11 | TC | UAT |
|---|---|---|---|
| LGC-NGSP-002 | 018, 028, 029, 055 | 036, 037, 042, 043, 112, 113, 164, 165 (+1) | UAT-02, UAT-04 |
| LGC-NGSP-004 | 018, 046, 050 | 036, 037, 055, 064, 083, 120, 156, 164 (+1) | UAT-07 |
| LGC-BUS-037 | 027, 053, 060 | 100, 103, 109, 121, 123, 165 | UAT-05, UAT-06 |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Quy tắc nghiệp vụ → test case

Cột "Test case" ghi ba chữ số cuối mã TC-11 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-11-001 | 164 |
| BR-11-002 | 012, 024, 025, 042, 164 |
| BR-11-003 | 012, 013, 014, 015, 024, 025 |
| BR-11-004 | 028, 030, 032, 133, 138, 166 |
| BR-11-005 | 005, 006, 007, 010, 019, 023, 030, 032, 033 |
| BR-11-006 | 030, 034, 036, 101, 134 |
| BR-11-007 | 037, 038, 040, 133, 136, 143, 168 |
| BR-11-008 | 012, 015, 026, 027, 097, 103, 104, 165, 167 |
| BR-11-009 | 026, 103, 109, 165 |
| BR-11-010 | 026, 045, 097, 103, 158, 165 |
| BR-11-011 | 097, 103, 104, 158 |
| BR-11-012 | 109, 110, 111, 121, 165 |
| BR-11-013 | 103, 104, 106, 107 |
| BR-11-014 | 007, 008, 015, 021, 022, 036, 042, 053, 058, 062 (+12) |
| BR-11-015 | 015, 021, 022, 112, 113, 142 |
| BR-11-016 | 055, 060, 064, 065 |
| BR-11-017 | 051, 070, 072, 081, 083, 084, 120, 155, 156, 169 |
| BR-11-018 | 070, 072, 094, 120, 155 |
| BR-11-019 | 012, 047, 052, 057, 086, 088, 119, 156 |
| BR-11-020 | 056, 065, 073, 074, 077, 078, 079, 138, 166 |
| BR-11-021 | 099, 100, 101, 102, 138 |
| BR-11-022 | 040, 042, 043, 044, 048, 049, 106, 136, 144, 145 (+3) |
| BR-11-023 | 036, 037, 039, 042, 043, 048, 064, 094, 115, 116 (+5) |
| BR-11-024 | 124, 125, 126 |
| BR-11-025 | 075, 107, 127, 128 |
| BR-11-026 | 130 |
| BR-11-027 | 009 |
| BR-11-028 | 034, 035 |
| BR-11-029 | 067 |
| BR-11-030 | 053, 115 |
| BR-11-031 | 001, 058, 062, 063, 090, 117 |
| BR-11-032 | 030, 033, 132, 133, 134, 135 |
| BR-11-033 | 028, 029, 030, 031, 064, 065, 068, 069 |
| BR-11-034 | 012, 015, 051 |
| BR-11-035 | 015, 054 |
| BR-11-036 | 017 |
| BR-11-037 | 055, 058 |
| BR-11-038 | 128, 130, 131 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

Mã `ERR-11-101…125` là lỗi nền (engine, lệnh, Saga), kiểm ở sự cố, nhật ký, cảnh báo thay cho mã HTTP; `ERR-11-043`, `045`, `048` là mã dự phòng nên không có ca.

Cột "Test case" ghi ba chữ số cuối mã TC-11 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-11-001 | 002, 006, 013, 020, 063, 093, 108, 129, 132, 170 |
| ERR-11-002 | 004, 009, 020, 025 |
| ERR-11-003 | 002, 004, 020, 022, 025, 038, 091, 108, 118, 120 (+1) |
| ERR-11-004 | 004, 011, 032, 066 |
| ERR-11-005 | 009, 032, 065, 099, 100, 102, 110, 138, 166, 167 |
| ERR-11-006 | 004, 006, 019, 020, 028, 029, 035, 046, 061, 065 (+8) |
| ERR-11-007 | 027, 029, 032, 035, 065, 069, 095, 098, 110, 122 (+1) |
| ERR-11-008 | 008, 011 |
| ERR-11-009 | 008, 011 |
| ERR-11-010 | 018, 022, 029, 032, 167 |
| ERR-11-011 | 013, 027 |
| ERR-11-012 | 015, 025, 032 |
| ERR-11-013 | 015, 027 |
| ERR-11-014 | 013 |
| ERR-11-015 | 013, 020, 022 |
| ERR-11-016 | 011 |
| ERR-11-017 | 034, 035, 038 |
| ERR-11-018 | 038, 041 |
| ERR-11-019 | 038, 041, 050, 099 |
| ERR-11-020 | 038, 041, 139 |
| ERR-11-021 | 061 |
| ERR-11-022 | 061, 063, 065, 066, 074, 076 |
| ERR-11-023 | 065, 066 |
| ERR-11-024 | 029, 074, 080 |
| ERR-11-025 | 078 |
| ERR-11-026 | 069 |
| ERR-11-027 | 076 |
| ERR-11-028 | 082 |
| ERR-11-029 | 125, 126, 127 |
| ERR-11-030 | 095, 100, 105 |
| ERR-11-031 | 102 |
| ERR-11-032 | 100 |
| ERR-11-033 | 099 |
| ERR-11-034 | 063, 093, 139 |
| ERR-11-035 | 114, 136 |
| ERR-11-036 | 009 |
| ERR-11-037 | 025, 035 |
| ERR-11-038 | 035 |
| ERR-11-039 | 120, 130, 131, 171 |
| ERR-11-040 | 023 |
| ERR-11-041 | 038 |
| ERR-11-042 | 018 |
| ERR-11-044 | 027 |
| ERR-11-046 | 033, 039, 159 |
| ERR-11-047 | 127 |
| ERR-11-049 | 050, 071 |
| ERR-11-050 | 080 |
| ERR-11-051 | 168 |
| ERR-11-101 | 048 |
| ERR-11-102 | 047, 160 |
| ERR-11-103 | 044, 135 |
| ERR-11-104 | 040, 044, 144 |
| ERR-11-105 | 045, 165 |
| ERR-11-106 | 046 |
| ERR-11-107 | 048, 122 |
| ERR-11-108 | 052 |
| ERR-11-109 | 050 |
| ERR-11-110 | 109, 163, 165 |
| ERR-11-111 | 106 |
| ERR-11-112 | 104 |
| ERR-11-113 | 056, 057, 089, 161 |
| ERR-11-114 | 059 |
| ERR-11-115 | 119 |
| ERR-11-116 | 085 |
| ERR-11-117 | 116 |
| ERR-11-118 | 054 |
| ERR-11-119 | 102 |
| ERR-11-120 | 040 |
| ERR-11-121 | 111 |
| ERR-11-122 | 127 |
| ERR-11-123 | 053, 087 |
| ERR-11-124 | 067 |
| ERR-11-125 | 169 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

Cột "Test case" ghi ba chữ số cuối mã TC-11 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-11-001 | 150 |
| NFR-11-002 | 151 |
| NFR-11-003 | 151 |
| NFR-11-004 | 150 |
| NFR-11-005 | 148, 150 |
| NFR-11-006 | 112, 152 |
| NFR-11-007 | 152, 159 |
| NFR-11-008 | 147 |
| NFR-11-009 | 147 |
| NFR-11-010 | 149, 159 |
| NFR-11-011 | 146, 157 |
| NFR-11-012 | 148 |
| NFR-11-013 | 014, 153 |
| NFR-11-014 | 153 |
| NFR-11-015 | 058, 154 |
| NFR-11-016 | 047, 083, 084, 086, 155, 156 |
| NFR-11-017 | 158 |
| NFR-11-018 | 115, 154 |
| NFR-11-019 | 126, 163 |
| NFR-11-020 | 132, 133, 134, 135, 137, 138, 139, 161 |
| NFR-11-021 | 113, 133, 140, 142 |
| NFR-11-022 | 162 |
| NFR-11-023 | 128, 130, 154 |
| NFR-11-024 | 127, 154 |

: Yêu cầu phi chức năng tới test case

### 8.6. Sự kiện → test case

Cột "Test case" ghi ba chữ số cuối mã TC-11 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-11-01 | 030 |
| EVT-11-02 | 034 |
| EVT-11-03 | 036, 037, 039, 051, 115, 135, 140, 164 |
| EVT-11-04 | 043, 064, 070, 115, 116, 140, 157, 163, 164 |
| EVT-11-05 | 115, 164, 166 |
| EVT-11-06 | 096, 097, 115 |
| EVT-11-07 | 094, 115 |
| EVT-11-08 | 055 |
| EVT-11-09 | 055, 060, 073, 077, 079 |
| EVT-11-10 | 064, 157 |
| EVT-11-11 | 086, 087 |
| EVT-11-12 | 088, 089 |
| EVT-11-13 | 045, 097, 103, 158, 165 |
| EVT-11-14 | 097, 103, 165 |
| EVT-11-15 | 109, 165 |
| EVT-11-16 | 052, 121, 169 |
| EVT-11-17 | 042, 048, 103, 135, 140, 145, 160, 163 |
| EVT-11-18 | 043, 044, 135, 144 |
| EVT-11-19 | 045, 046, 135 |
| EVT-11-20 | 011, 053, 140 |
| EVT-11-21 | 131, 171 |

: Sự kiện tới test case

### 8.7. Màn hình → test case

Cột "Test case" ghi ba chữ số cuối mã TC-11 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-11-01 | 001 |
| UI-11-02 | 003, 007 |
| UI-11-03 | 005, 028, 034 |
| UI-11-04 | 010, 012, 014, 016, 021, 153, 162 |
| UI-11-05 | 005 |
| UI-11-06 | 017 |
| UI-11-07 | 028, 030, 031, 167 |
| UI-11-08 | 019 |
| UI-11-09 | 024, 026 |
| UI-11-10 | 009 |
| UI-11-11 | 090 |
| UI-11-12 | 092 |
| UI-11-13 | 041 |
| UI-11-14 | 101 |
| UI-11-15 | 062, 064, 162 |
| UI-11-16 | 079 |
| UI-11-17 | 077 |
| UI-11-18 | 081, 083, 085 |
| UI-11-19 | 088, 117 |
| UI-11-20 | 121, 123 |
| UI-11-21 | 107, 109 |
| UI-11-22 | 120 |
| UI-11-23 | 124 |

: Màn hình tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Mã kiểm thử ở `dh-platform/src/test` (`bpm`) cho UT, IT; `ph11/seed/` nạp dữ liệu mục 2 qua API; `ph11/k6/` cho tải; `ph11/chaos/` cho Chaos Mesh; công cụ sinh tài liệu ở `ph11/tools/` (chép từ `ph06/tools/`). Ca "Thủ công" chỉ ở mục 6.

### 9.2. Mẫu ca ma trận quyền

Ca `perm-matrix` sinh từ `x-datahub-permission` trong `openapi-bpm.yaml`: mỗi API một dòng, mỗi vai trò một cột, giá trị kỳ vọng `200` hoặc `403` lấy từ ma trận FRS 3.2.

### 9.3. Mẫu ca kiểm tra tĩnh

Ca `validate-rules` dùng thư mục `M-LOI` gồm 20 tệp BPMN, tên tệp là `ruleCode`; kỳ vọng nằm trong tệp `kyvong.json` cùng thư mục (`ruleCode`, `severity`, `elementId`).

### 9.4. Mẫu ca chèn lỗi

Các ca `start-atomic`, `outbox-atomic`, `saga-log-fail` dùng điểm chèn lỗi đặt tên (`before-commit`, `after-engine`, `saga-write`) bật bằng tham số kiểm thử chỉ tồn tại ở môi trường TEST, STAGING; bản sản xuất không có lớp chèn lỗi.

### 9.5. Sinh ma trận, Gherkin, bảng tính

Chạy theo thứ tự, từ thư mục `05-kiem-thu/test-case/ph11/tools/`:

```bash
python3 number_tcs.py      # cấp số TC-11-nnn, thay [[tc:khóa]]
python3 fill_doc.py        # bảng kịch bản, số ca, ma trận mục 8
python3 gen_gherkin.py     # ph11/gherkin/*.feature
python3 gen_xlsx.py        # ph11/D05-02-PH11-test-case.xlsx
python3 check_refs.py      # đối chiếu mã với FRS, use case, màn hình
```

Tệp `.xlsx` có bốn sheet: `TestCase` (cột kết quả chọn Đạt, Không đạt, Chặn, Chưa chạy), `UAT`, `TruyVet`, `HuongDan`. Tệp `.feature` dùng từ khóa tiếng Việt của Gherkin, mỗi kịch bản một tệp cộng `uat-quy-trinh.feature`.

### 9.6. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối chín tiêu chí ở FRS §14 với ca chứng minh.

| # | Tiêu chí | Ca chứng minh |
|---|---|---|
| 1 | 48/48 FR mức M có ca đạt | Bảng 8.1: mọi FR mức M có ca dương và ca âm |
| 2 | `LT_KHAI_SINH` đầu cuối: thành công, bù trừ, bù trừ thất bại | TC-11-164, TC-11-165, TC-11-103 |
| 3 | `DUYET_KET_NAP_HTTT` do PH-01 khởi tạo, hai cấp, bốn mắt | TC-11-166, TC-11-138 |
| 4 | NFR-11-001…024 đạt; tắt pod không mất phiên | TC-11-150, TC-11-146, TC-11-147, TC-11-148 |
| 5 | Kiểm tra tĩnh chặn đủ lỗi bảng 6.2-c | TC-11-015 |
| 6 | 200 ca lịch mẫu không sai lệch | TC-11-155 |
| 7 | Quét rò rỉ: 0 giá trị `SENSITIVE` dạng rõ | TC-11-140, TC-11-142 |
| 8 | Biên bản chạy mẫu BPMN 2.0 và thuyết minh WS-BPEL | TC-11-130 |
| 9 | Ranh giới PH-11 và PH-04 xác nhận bằng văn bản | Mục 6.4, TC-11-164 |

: Tiêu chí chấp nhận cấp phân hệ và ca chứng minh

## 10. Câu hỏi mở và ADR đề xuất

Các câu hỏi dưới đây chặn việc chốt kỳ vọng của một số ca; số hiệu theo dải Q11-40…44 của tập kiểm thử.

| Mã | Câu hỏi | Ảnh hưởng | Giả định tạm dùng |
|---|---|---|---|
| Q11-40 | Tỉnh thí điểm cung cấp lịch nghỉ lễ, nghỉ bù, làm bù năm 2027 và ai ký xác nhận bộ 200 ca? | `cal-200`, `cal-e2e`, `due-holiday` | Lịch giả định ở mục 2.3, hạn tính tay hai người |
| Q11-41 | Chỉ tiêu sẵn sàng 99,9 % theo tháng đo thế nào trước khi có môi trường sản xuất? | `perf-progress` | Đo 24 giờ ở PERF, tháng đo sau khi vận hành |
| Q11-42 | Bộ kiểm chuẩn BPMN 2.0 nào dùng để chạy mẫu cho hồ sơ CV 631 và có cần Apache ODE chạy thật cho WS-BPEL? | `compliance` | Mẫu tự dựng, thuyết minh văn bản, không chạy ODE |
| Q11-43 | Ai ký biên bản xác nhận ranh giới PH-11 và PH-04 (tiêu chí chấp nhận 9)? | Mục 6.4, UAT-08 | Trưởng nhóm tích hợp và trưởng nhóm nghiệp vụ |
| Q11-44 | Môi trường STAGING có Chaos Mesh và `kubectl` quyền xóa pod không, hay chỉ có kind ở TEST? | TS-11-29, 33 | Có ở STAGING; nếu không, ca `Chaos` chạy ở kind và ghi hạn chế |

: Câu hỏi mở của tập kiểm thử

ADR đề xuất liên quan tới ca kiểm thử, chưa có tệp ADR: ADR 110 (Flowable nhúng một engine đa tenant) cho TS-11-25; ADR 111 (trình thiết kế bpmn-js, kiểm tra tĩnh ở máy chủ, giữ logo bpmn.io) cho TS-11-02, 34; ADR 112 (service task bất đồng bộ qua Kafka và outbox) cho TS-11-07, 28, 32; ADR 113 (Saga bù trừ, không 2PC) cho TS-11-18, 19, 32; ADR 114 (lịch làm việc theo tenant, hạn theo ngày làm việc) cho TS-11-14, 31.

## Phụ lục A. Đề nghị đồng bộ FRS

FRS 0.2 (Phụ lục C) đã xử lý các đề nghị của bản 0.1; ca sửa theo.

| Mục FRS | Đề nghị | Tình trạng, ca |
|---|---|---|
| FR-11-049 | Hết hạn bổ sung | Đã hấp thụ: không tự hủy, sự cố `SUPPLEMENT_EXPIRED`; ca `supplement-expired` |
| FR-11-024 | `200`/`202`; client hệ thống | Đã hấp thụ; ca `cancel-client` |
| FR-11-046, 048 | `CALENDAR_DAY`; `afterHours` mặc định | Đã hấp thụ; ca `due-hours`, `overdue-escalate` |
| NFR-11-007, 016 | Cách đo; bộ 200 ca | Đã hấp thụ (FRS 8.1) |
| FR-11-010, 011 | XXE; phiên thử hết hạn | Đã hấp thụ; ca `import-neg`, `testrun-ok` |
| ERR-11-043, 045, 048 | Gỡ mã dự phòng | Không chấp nhận: giữ chỗ, không có ca |
| ERR-11-039 | Phạm vi, 366 ngày, 12 tháng | Đã hấp thụ (422); ca `due-report`, `audit-log`, `compliance` |

: Đề nghị đồng bộ FRS từ tập kiểm thử

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-26 | Nhóm kiểm thử | Bản đầu cho PH-11: 35 kịch bản, ca chức năng và phi chức năng, ma trận truy vết sinh tự động, Gherkin, bảng tính, câu hỏi mở Q11-40…44, đề nghị đồng bộ FRS |
| 0.2 | 2026-11-26 | Nhóm kiểm thử | Đồng bộ FRS 0.2: ca cho API-11-128…137, ERR-11-051, 125, bỏ qua bước Saga bốn mắt, `waiverDecisions[]`, client hủy phiên, `CALENDAR_DAY`, `nextLevelHours`; nguyên tử về hiệu ứng (Q11-21) |
