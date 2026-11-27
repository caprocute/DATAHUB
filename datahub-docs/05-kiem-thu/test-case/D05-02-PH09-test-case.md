---
ma_tai_lieu: D05-02-PH09
ten: Kịch bản và test case phân hệ PH-09 Quyền riêng tư
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-09
mo_ta: Kịch bản và test case chức năng, cô lập tenant, đóng an toàn, hiệu lực thu hồi chấp thuận, k-ẩn danh, đồng hồ 72 giờ, hiệu năng và nghiệm thu tương đương hệ cũ của phân hệ Quyền riêng tư, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH09 FRS; D02-04-PH09 Use case; D03-02-PH09 SDD; D03-06-PH09 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH09 · Kịch bản và test case Quyền riêng tư

## Tóm tắt cho hội đồng thẩm định

Phần này viết cho hội đồng thẩm định: tài liệu chứng minh điều gì, phủ đến đâu và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản, số ca do công cụ sinh lại từ chính các ca nên luôn khớp với chương 4 và 5.

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-09 làm đúng mọi yêu cầu đã chốt ở D02-03-PH09 bản 0.2: 64 FR, 62 quy tắc BR-09, 26 yêu cầu phi chức năng, 95 mã lỗi (ERR-09-001…082 và 101…113), 245 API, 32 sự kiện.
- Không có đường nào để dữ liệu Nhạy cảm đi qua Datahub khi thiếu mục đích, chấp thuận của chủ quản hoặc kế hoạch che: bản tin có nhãn `STATE_SECRET` bị chặn toàn bộ, chấp thuận bị thu hồi chặn lời gọi tại điểm thực thi trong 15 giây, PH-09 mất kết nối thì điểm thực thi đóng an toàn sau 5 phút đệm.
- Không có giá trị dữ liệu cá nhân (DLCN) ở dạng rõ trong log, vết, topic, tệp xuất, bảng `ph09_privacy`, và không có đường nào để tenant này đọc dữ liệu quyền riêng tư của tenant khác.
- Các thao tác đặc quyền (xem đầy đủ, khôi phục giá trị gốc, hủy khóa, xóa mật mã, gỡ nhãn bí mật) luôn có kiểm toán trước, người duyệt khác người đề nghị, tập ẩn danh phát hành đạt k ≥ 10 và đồng hồ vi phạm 72 giờ không bị bỏ sót.

**Phạm vi.** Gồm <!--gen:so-ts-->42<!--/gen--> kịch bản với <!--gen:so-tc-->150 (TC-09-001…150; 108 ca P1)<!--/gen--> test case và 9 kịch bản nghiệm thu người dùng (UAT-01…09). Mọi FR mức M có ít nhất một ca dương và một ca âm, mọi mã lỗi ERR-09 có ít nhất một ca, mọi màn hình UI-09 có ca; các API chính (quyết định mục đích, kế hoạch che, áp che, giả danh hóa, xem đầy đủ, khôi phục, ẩn danh hóa, yêu cầu chủ thể, vi phạm) có ca riêng. Ma trận mục 8 sinh bằng `ph09/tools/gen_matrix.py`. Hệ cũ chỉ có hai chức năng liên quan là LGC-TOOL-012 (nâng cấp) và LGC-NGSP-003 (giữ nguyên, PH-09 thêm kiểm soát) nên mục 7 nghiệm thu tương đương hệ cũ theo vai trò và đối chiếu mười một FR cũ của SRS repo.

**Căn cứ.** FRS D02-03-PH09, use case D02-04-PH09, màn hình D03-06-PH09, SDD D03-02-PH09, ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01 (cổng `RG-1…5`); Luật Bảo vệ dữ liệu cá nhân 91/2025, Nghị định 356/2025/NĐ-CP, Luật Dữ liệu, TCVN 14423:2026; cấu trúc theo ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- cô lập tenant ở API, RLS, data plane, Kafka, khóa (TS-09-35);
- ma trận `PERM-09-*` và bốn mắt không có đường vòng, kể cả với TA có cả quyền soạn và duyệt (TS-09-36);
- chặn dữ liệu bí mật nhà nước, chặn kích hoạt hợp đồng `SENSITIVE` khi thiếu chấp thuận, thu hồi chấp thuận hiệu lực ≤ 15 giây (TS-09-06, 15, 39);
- đóng an toàn khi PH-09 hoặc nhật ký PH-13 mất kết nối (TS-09-18, 38);
- không có DLCN dạng rõ ở log, sự kiện, tệp xuất (TS-09-21, 37);
- k ≥ 10, rủi ro `HIGH` bị chặn, đồng hồ 72 giờ đúng mốc 24, 48, 60 giờ (TS-09-25, 33, 39).

Dữ liệu và quy mô dùng giả định GĐ-01…07 (tỉnh vừa, 200 HTTT) và GĐ-09-04 của FRS (3.000 chấp thuận hiệu lực, 50.000 phần tử, 500 cột quét). Mã hiện có của `dh-data` chưa có mô-đun `privacy`; các ca là tiêu chí nghiệm thu của công việc mới ở Đợt 2, mốc W4.

## 0. Giới thiệu

### 0.1. Mục đích

Đặc tả kịch bản và test case của PH-09 để nghiệm thu chức năng, an toàn dữ liệu, hiệu lực tức thời của chấp thuận, hiệu năng và tương đương hệ cũ.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư `dh-data`, `dh-console` đối chiếu hành vi; cán bộ ATTT kiểm chương 5; chủ đầu tư dùng mục 7 và 9.2 để nghiệm thu.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; DLCN dữ liệu cá nhân; PEP điểm thực thi chính sách (PH-03, 04, 06, 14, 19); PDP điểm quyết định (OPA); PAP, PIP nguồn chính sách và thông tin (PH-09); DSR yêu cầu của chủ thể dữ liệu; DPIA đánh giá tác động; RLS an toàn theo hàng; k-ẩn danh mỗi tổ hợp bán định danh có ít nhất k bản ghi; canary chuỗi mồi phát hiện rò rỉ. Vai trò viết tắt theo D02-08: PA, TA, TO, SO, DS, DA, DO, OR, SV, VW, AU.

### 0.4. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng (TS-09-01…34 ứng một một với UC-09-01…34); 5 ca phi chức năng (TS-09-35…42); 6 thủ công; 7 nghiệm thu; 8 ma trận; 9 tự động hóa; 10 đề nghị đồng bộ và câu hỏi mở.

### 0.5. Tài liệu tham chiếu

D05-01 kế hoạch kiểm thử; D02-03-PH09 (mã FR, BR, NFR, ERR, EVT, API, UI, enum Phụ lục A); D02-04-PH09 (UC); D03-06-PH09 (màn hình); D03-02-PH09 (kiến trúc); D02-08 (ma trận quyền); D03-07 (phân loại bốn mức, SEC-31…39); mẫu cùng loại D05-02-PH06.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là mô-đun `vn.datahub.data.privacy` của `dh-data` (control plane `/api/privacy/v1`, data plane nội bộ mTLS `/privacy/v1`), Job K8s quét và ẩn danh hóa (ARX), schema `ph09_privacy` của `pg-core` với RLS theo `tenant_id`, 237 API (API-09-001…245), 32 topic `{tenant}.privacy.*` (EVT-09-01…32) và 22 màn hình dưới `/du-lieu/quyen-rieng-tu` (UI-09-01…22). Ngoài phạm vi: nội dung xử lý của PH-06, PH-19, PH-14 (giả lập ở chỗ gọi, ca thuộc tập của phân hệ đó), hành vi nội bộ của OPA và OpenBao (chỉ kiểm tích hợp).

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca; chiến lược chung theo D05-01.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Mẫu che, kiểm tổng số định danh, giải quyết thứ tự ưu tiên quy tắc, thuật toán đồng hồ |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka KRaft, Keycloak, OpenBao dev, OPA, WireMock cho PH-02, 11, 13, 14, 19) | Dịch vụ với CSDL, outbox, bundle, khóa |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph09/test/` | RLS, ràng buộc, bất biến lịch sử |
| Job | JOB | pytest, Job K8s trên kind | Quét, ẩn danh hóa ARX, tác vụ lưu giữ, đồng hồ |
| Hợp đồng | CT | Spectral, oasdiff | OpenAPI `/api/privacy/v1`, `/privacy/v1`, lược đồ sự kiện |
| API | API | REST Assured | Mọi API-09 |
| Kafka | KT | `kcat`, client OAUTHBEARER | ACL theo tiền tố, nội dung sự kiện |
| Đầu cuối | E2E | Playwright, axe-core | UI-09-01…22 |
| Hiệu năng | k6 | k6, đồng hồ Job | NFR-09-001…004, 011, 020, 023 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | PH-09, PH-13, OpenBao, Kafka, PostgreSQL, nút |
| Bảo mật | ZAP | OWASP ZAP, quét canary, Semgrep | ASVS 5.0 mức 2, rò rỉ giá trị |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường phục vụ các mức ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, JOB, CT, API, KT, E2E khói | `dh-data` 1 bản sao; PH-02, 11, 13, 14, 19 là WireMock; OPA thật; OpenBao chế độ dev; Job K8s trên kind; đồng hồ giả cho ca thời gian |
| STAGING | E2E đầy đủ, Chaos, ZAP, UAT dợt ở tenant `T68` | Giống sản xuất về số bản sao và chính sách mạng |
| PERF | k6, JOB quy mô, DR | Data plane 3 bản sao trên 3 nút; `pg-core` 8 vCPU, 32 GB; Job ARX 8 vCPU, 32 GB; tenant T97…T99 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** Hợp đồng API-09 và lược đồ sự kiện đã gắn phiên bản; bộ dữ liệu mục 2 nạp được bằng `ph09/seed/` qua API (không chèn SQL, trừ bộ RLS).
- **Ra.** `RG-1` mọi ca API, DB và rò rỉ chéo tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-09-001…026 ở PERF; `RG-4` UAT mục 7 ký và 13 tiêu chí chấp nhận cấp phân hệ ở FRS §14 đạt (đối chiếu ở mục 9.2).

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-09-nn`, test case `TC-09-nnn`; mã không tái sử dụng, ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-09-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và tham chiếu `[[tc:khóa]]`, không in ra bản xuất. Đường dẫn trong bước tương đối với `/api/privacy/v1`; data plane ghi đủ `/privacy/v1/...`. Tên trường JSON không có trong FRS lấy từ `openapi-privacy.yaml` (D03-04-PH09): `dryRun`, `statutory` (mục đích luật định), `confirmInconsistency` (xác nhận xoay khóa làm bí danh đổi), `effectiveClass`, `neverReveal` (Q09-42).

| Trường | Nội dung |
|---|---|
| **Mục đích.** | Ca chứng minh điều gì, theo FR, BR hoặc NFR chính |
| **Loại.** | Dương, Âm, Biên, Bảo mật, Hiệu năng, Độ chính xác, Chịu lỗi, Truy cập |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung |
| **Tự động.** | Mức ở mục 1.2 hoặc "Thủ công" |
| **Truy vết.** | FR, BR, API, UI, ERR, EVT, NFR, quyền, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu ở chương 2 |
| **Các bước.** | Danh sách đánh số |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán |
| **Thông báo hiển thị.** | Câu người dùng nhìn thấy theo FRS §9.1, chỉ ở ca có mã lỗi |

: Các trường của khối đặc tả test case

Lỗi thiếu quyền, chưa xác thực và thiếu `If-Match` dùng mã nền ERR-00-403, ERR-00-401, ERR-00-428, không có mã ERR-09 riêng. Trong kết quả mong đợi dùng các ký hiệu sau.

| Ký hiệu | Nghĩa |
|---|---|
| ERR-00-403 | `403` do thiếu quyền chức năng `PERM-09-*` hoặc scope; thân RFC 9457 có `code`, `traceId` (`403` do phạm vi tổ chức hoặc nghiệp vụ giữ mã ERR-09-005, 008, 041, 065…) |
| ERR-00-401, 428 | `401` thiếu hoặc sai token; `428` thiếu `If-Match` ở thao tác ghi |
| 404-ẩn | `404` ERR-09-001; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa giá trị DLCN |
| EVT: `loại` | Đúng một bản tin trên topic `t90.privacy.{loại}.v1`, không chứa giá trị DLCN |
| Mồi sạch | Chuỗi canary `DH-CANARY-{ca}` và số định danh giả của ca không xuất hiện ở dạng rõ trong phản hồi (trừ phiếu xem đầy đủ), log 5 phút, vết OTel, bảng `ph09_privacy.*`, outbox, Kafka, tệp xuất |

: Ký hiệu viết tắt trong kết quả mong đợi

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi theo mức S1…S4 của D05-01; kết quả ghi ở cột "Kết quả" của `.xlsx`. Lỗi ở ca P1 chặn phát hành; lỗi S1, S2 sửa xong phải có thêm ca hồi quy tự động.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập (SEC-38): tên là nhân vật hư cấu, số định danh ở dải giả không do cơ quan nào cấp, không dùng DLCN thật hay dữ liệu `SENSITIVE` thật ở bất kỳ môi trường nào ngoài PROD. Nạp bằng `ph09/seed/` qua API, trừ khối RLS chạy ở mức CSDL.

### 2.1. Tenant

Tenant kiểm thử dùng dải `T90…T99`; `T68` dành cho UAT dợt và ca liên tenant ở STAGING; không dùng tenant sản xuất.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant chính | Đã bật PH-09: bốn mức phân loại, 18 loại DLCN, mục đích, chính sách che mặc định đã duyệt, miền giả danh; tham số mặc định theo FRS §8.2 |
| `T91` | Tenant đối chứng rò rỉ | Cùng mã phần tử, mục đích, miền, CCCD giả với T90; dùng cho mọi ca chéo tenant |
| `T92` | Tham số nhỏ | `09.request.sla-days = 3`, `09.mask.reveal-max-per-hour = 3`, `09.reid.approval-ttl-hours = 1` |
| `T93` | Mới | Chưa có chính sách, hoạt động xử lý nào |
| `T94` | Chịu lỗi | Cho Chaos: ngừng PH-09, PH-13, OpenBao, Kafka, PostgreSQL, Job |
| `T95` | Đồng hồ | Đồng hồ giả: hết hạn chấp thuận, hạn DSR, đồng hồ 72 giờ, DPIA, xóa mật mã |
| `T96` | Ẩn danh, AI | F-ANON 200.000 bản ghi, F-ANON-S, F-ANON-M |
| `T97`…`T99` | Hiệu năng | T97 quyết định, kế hoạch che, áp che (200 HTTT, 3.000 chấp thuận); T98 50.000 phần tử, quét 500 cột, ẩn danh 1 triệu; T99 2 triệu bản ghi kiểm toán một tháng |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

Người dùng mang tên nhân vật hư cấu, vai trò theo D02-08; mỗi vai có một tài khoản `U-{tenant}-{vai}`.

| Mã | Tenant | Vai trò | Ghi chú |
|---|---|---|---|
| U-PA | PLATFORM | PA | Đặt trần, sàn tham số |
| U-T90-TA | T90 | TA | Có `PERM-09-policy`, `policy-approve`, `config`; có cả quyền soạn lẫn duyệt (kiểm bốn mắt độc lập) |
| U-T90-SO | T90 | SO | Bộ phận bảo vệ DLCN (GĐ-09-01); có `PERM-09-unmask` được cấp riêng |
| U-T90-DS1, DS2 | T90 | DS | Thuộc Sở Y tế (DS1), Sở Giáo dục (DS2) |
| U-T90-DA1 | T90 | DA | Người duyệt chính |
| U-T90-DO1, DO2 | T90 | DO | DO1 chủ quản nguồn `HT-YT` (Sở Y tế), DO2 thuộc Sở GD |
| U-T90-OR1, OR2 | T90 | OR | OR1 đầu mối HTTT-BH, OR2 thuộc tổ chức khác |
| U-T90-SV1, TO, AU, VW | T90 | SV, TO, AU, VW | Chủ dịch vụ, vận hành, kiểm toán, người xem |
| U-T91-SO, TA, DO1, AU | T91 | SO, TA, DO, AU | Đối chứng chéo tenant |
| S-T90-PEP-04, APPLY-04, PSEUDO, REG, CONSENT | T90 | Tài khoản máy | Scope `privacy:decide`, `privacy:apply` (kèm `decide`), `privacy:pseudonymize`, `privacy:register`, `privacy:consent` |
| S-T90-NOSCOPE, S-T91-PEP, S-T91-CONSENT | T90, T91 | Tài khoản máy | Không scope; scope của tenant đối chứng |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu

Bộ dữ liệu có tên, sinh bằng hạt cố định để chạy lại được.

| Mã | Nội dung | Tenant |
|---|---|---|
| F-ELM | 60 phần tử `INTERNAL_ENTITY`, `API_SCHEMA`, `EVENT_SCHEMA`: 12 chưa phân loại, 20 DLCN cơ bản, 8 nhạy cảm, 1 phần tử `neverReveal` (`matKhau`) | T90 |
| F-MSG | Bản tin 10 KB, 8 trường: `hoTen`, `cccd`, `soDienThoai`, `email`, `ngaySinh`, `diaChi`, `soTaiKhoan`, `maBenhAn` (mức `SENSITIVE`), có biến thể thêm `soHieuMat` mang nhãn | T90, T97 |
| F-SIM | 1.000 dòng mẫu cho mô phỏng che | T90 |
| F-SCAN | Bảng 40 cột, 10.000 dòng: 8 cột có CCCD, MST, thẻ, điện thoại, thư đúng kiểm tổng, 4 cột nhiễu | T98 |
| F-LOG | Log 5 phút có canary và CCCD giả dạng rõ | T90 |
| F-ANON | 200.000 bản ghi giả: ngày sinh, mã xã, giới tính, nghề (bán định danh), `bệnh` (nhạy cảm), `cccd` (trực tiếp); F-ANON-S 500 bản ghi nhiều giá trị độc nhất; F-ANON-M rủi ro 0,07; F-ANON-1M 1 triệu bản ghi 10 thuộc tính | T96, T98 |
| F-DSR | Chủ thể giả CC-01, CC-03 có dấu vết ở PH-06, PH-19 và nhật ký PH-13 giả lập (12 lượt truy cập) | T90 |

: Bộ dữ liệu kiểm thử

Số định danh giả dùng trong ca (giả định theo Q09-07, không do cơ quan nào cấp):

| Mã | Giá trị | Ý nghĩa |
|---|---|---|
| CC-01 | `001090000101` | CCCD giả, Nguyễn Văn An, sinh 12/03/1990; điện thoại `0912345678`; thư `an.nguyen@example.test` |
| CC-03 | `079195000303` | CCCD giả, Trần Thị Bình, sinh 05/07/1995 |
| HTTT | HTTT-BH, HTTT-TK, HTTT-CHUA | Hệ giả lập BHXH tra hộ gia đình; hệ thống kê; hệ chưa đăng ký sử dụng |
| Mục đích | `MD-TRACUU-HGD`, `MD-THONGKE`, `MD-LUATDINH` | Tra cứu hộ gia đình (SENSITIVE); thống kê (3 trường); bắt buộc theo luật |
| Hợp đồng | API-HGD, API-DM, TOPIC-HS-YT | `SENSITIVE`, `PUBLIC`, `RESTRICTED` |

: Định danh và mã nghiệp vụ giả

### 2.4. Hệ thống giả lập

Phân hệ và hệ thống ngoài được giả lập như sau.

| Hệ thống | Giả lập bằng | Kịch bản |
|---|---|---|
| PH-02 (hợp đồng, đăng ký sử dụng, chấm dứt tenant) | WireMock | Hợp đồng đổi mức, HTTT có và không có đăng ký, bàn giao PH-20 |
| PH-03, 04, 06, 14, 19 (PEP) | Máy gọi thử dùng token dịch vụ; PH-06, 19, 14 là WireMock | Gọi data plane, nhận sự kiện, trả `502` một lần để thử chuyển DSR |
| PH-12 (OPA) | OPA thật 3 bản sao | Nạp bundle, từ chối bundle sai chữ ký |
| PH-13 (kiểm toán) | WireMock | Ghi bình thường, `503`, truy theo `subjectHash` |
| OpenBao | Bản dev có transit | Ký bundle, HMAC, khóa theo tenant, ngừng |
| Kho tệp, Job | Garage, Job K8s | Tệp xuất, tập ẩn danh mã hóa SSE-C |

: Hệ thống giả lập

### 2.5. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Mỗi ca ghi dữ liệu sinh ra và dọn bằng khóa `tc-{khóa}` trong tenant; ca dùng lại dữ liệu của ca khác nêu rõ ở tiền điều kiện. Ca bảo mật dùng canary `DH-CANARY-{ca}` đặt vào trường `SENSITIVE`. Ca thời gian dùng đồng hồ giả của T95, không chờ thật 72 giờ hay 365 ngày.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5; mục tiêu đầy đủ ở đầu mỗi kịch bản. Chuyển trạng thái hợp lệ và bị cấm của từng đối tượng được kiểm theo enum ở FRS Phụ lục A (ví dụ chấp thuận `SCHEDULED → ACTIVE → SUSPENDED → REVOKED`, khóa `ACTIVE → DECRYPT_ONLY → DISABLED → DESTROYED`), không lặp lại ở đây.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-09-01 | Danh mục mức phân loại, loại dữ liệu cá nhân, tra cứu và xuất | UC-09-01 | 3 |
| TS-09-02 | Đăng ký phần tử dữ liệu từ lược đồ và khai báo MVP | UC-09-02 | 3 |
| TS-09-03 | Đề xuất, xác nhận và hạ mức phân loại trường | UC-09-03 | 4 |
| TS-09-04 | Quét phát hiện trường nghi dữ liệu cá nhân | UC-09-04 | 3 |
| TS-09-05 | Mức phân loại của hợp đồng | UC-09-05 | 3 |
| TS-09-06 | Nhãn bí mật nhà nước và chặn dữ liệu | UC-09-06 | 4 |
| TS-09-07 | Sổ hoạt động xử lý, liên kết và xuất sổ | UC-09-07 | 4 |
| TS-09-08 | Cơ sở pháp lý, văn bản căn cứ và mục đích khai thác | UC-09-08 | 3 |
| TS-09-09 | Lập yêu cầu khai thác theo mục đích | UC-09-09 | 3 |
| TS-09-10 | Thẩm định, chấp thuận có điều kiện hoặc từ chối | UC-09-10 | 4 |
| TS-09-11 | Gia hạn, sửa, tạm dừng, thu hồi và tự hết hạn chấp thuận | UC-09-11 | 4 |
| TS-09-12 | Bundle OPA ký và phát hành | UC-09-12 | 4 |
| TS-09-13 | Quyết định mục đích trực tuyến cho điểm thực thi | UC-09-13 | 5 |
| TS-09-14 | Phát hiện khai thác bất thường và báo cáo theo mục đích | UC-09-14 | 3 |
| TS-09-15 | Chặn kích hoạt hợp đồng mức Nhạy cảm | UC-09-15 | 3 |
| TS-09-16 | Kiểu che và chính sách che | UC-09-16 | 3 |
| TS-09-17 | Mô phỏng, duyệt và phát hành chính sách che | UC-09-17 | 3 |
| TS-09-18 | Kế hoạch che trực tuyến, đệm và đóng an toàn | UC-09-18 | 3 |
| TS-09-19 | Áp che bản tin cho luồng PH-04 | UC-09-19 | 5 |
| TS-09-20 | Xem giá trị đầy đủ có lý do trong 60 giây | UC-09-20 | 4 |
| TS-09-21 | Che log, trace và quét rò rỉ DLCN trong log | UC-09-21 | 3 |
| TS-09-22 | Miền giả danh hóa và vòng đời khóa | UC-09-22 | 3 |
| TS-09-23 | Giả danh hóa giá trị bằng HMAC hoặc token | UC-09-23 | 4 |
| TS-09-24 | Khôi phục giá trị gốc từ token | UC-09-24 | 3 |
| TS-09-25 | Ẩn danh hóa, k tối thiểu 10 và rủi ro tái định danh | UC-09-25 | 5 |
| TS-09-26 | Chuẩn bị dữ liệu cho AI, môi trường không phải PROD và tập đã ẩn danh | UC-09-26 | 3 |
| TS-09-27 | Lịch lưu giữ, tác vụ xóa và báo cáo tuân thủ thời hạn lưu | UC-09-27 | 3 |
| TS-09-28 | Giữ pháp lý và xóa mật mã khi chấm dứt tenant | UC-09-28 | 3 |
| TS-09-29 | Tiếp nhận, xác minh, tra cứu và chuyển xử lý yêu cầu của chủ thể | UC-09-29 | 4 |
| TS-09-30 | Hạn xử lý, trả lời, đóng yêu cầu và báo cáo truy cập | UC-09-30 | 3 |
| TS-09-31 | Mẫu và bản ghi sự đồng ý | UC-09-31 | 3 |
| TS-09-32 | Hồ sơ đánh giá tác động DPIA | UC-09-32 | 3 |
| TS-09-33 | Vi phạm dữ liệu cá nhân và đồng hồ 72 giờ | UC-09-33 | 4 |
| TS-09-34 | Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo và tham số | UC-09-34 | 3 |
| TS-09-35 | Cô lập tenant: API, RLS, data plane, Kafka, khóa | — | 5 |
| TS-09-36 | Phân quyền theo ma trận PERM-09 và bốn mắt | — | 4 |
| TS-09-37 | Không lộ dữ liệu cá nhân ở sự kiện, tệp xuất và bề mặt tấn công | — | 3 |
| TS-09-38 | Đóng an toàn, chịu lỗi và phục hồi | — | 4 |
| TS-09-39 | Hiệu lực tức thời và đồng hồ | — | 5 |
| TS-09-40 | Hiệu năng, quy mô và quan sát | — | 6 |
| TS-09-41 | Truy cập giao diện và hợp đồng API | — | 2 |
| TS-09-42 | Tương đương hệ cũ và chức năng cũ của SRS repo | — | 3 |
| **Tổng** | | | **150** (108 ca P1) |

: Danh sách 42 kịch bản kèm use case và số ca
<!--/gen-->

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ, sau đó là các ca theo mục 1.5. TS-09-01…34 cùng số thứ tự với UC-09-01…34.

### TS-09-01 · Danh mục mức phân loại, loại dữ liệu cá nhân, tra cứu và xuất

**Mục tiêu.** Xác nhận bốn mức phân loại, danh mục loại DLCN nạp sẵn, chỉnh chính sách log của mức và xuất danh mục đúng phạm vi tenant.

**Phủ.** FR-09-001, 002, 008; UC-09-01; API-09-001, 002, 007, 008, 009, 030, 031; UI-09-02, 03; BR-09-002, 060; ERR-09-001, 003, 011.

#### TC-09-001 · Xem bốn mức, loại DLCN nạp sẵn và sửa chính sách log của mức <!--k:cls-catalog-->

::: dac-ta
**Mục đích.** Chứng minh `DataClass` có đúng bốn mức thứ hạng 1 đến 4 và 18 loại DLCN nạp sẵn (9 cơ bản, 9 nhạy cảm) theo FRS Phụ lục A.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-001, 002 · API-09-001, 002, 007 · ERR-09-003 · UI-09-02 · PERM-09-read, PERM-09-policy.

**Tiền điều kiện, dữ liệu.** T90 mới nạp; U-T90-VW, U-T90-TA.

**Các bước.**

1. VW `GET /data-classes` và `GET /personal-data-categories`.
2. TA `PATCH /data-classes/INTERNAL` đặt `logPolicy = PARTIAL_MASK`, kèm `If-Match`.
3. VW gọi lại `PATCH /data-classes/INTERNAL`.
4. TA `PATCH` thiếu `If-Match`.
5. TA `PATCH /data-classes/SENSITIVE` đặt `logPolicy = FULL`.

**Kết quả mong đợi.** Bước 1 `200`, bốn mức `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`, 18 loại. Bước 2 `200`, `ETag` mới, KT: có (data-class-update). Bước 3 ERR-00-403 (VW thiếu `PERM-09-policy`). Bước 4 `428` ERR-00-428. Bước 5 `422` ERR-09-003 vì mức `SENSITIVE` luôn `NO_VALUE`.
:::

#### TC-09-002 · Thêm loại DLCN trùng mã, ngừng loại đang dùng <!--k:cls-category-neg-->

::: dac-ta
**Mục đích.** Chứng minh mã loại duy nhất và loại đang được trường dùng không ngừng được.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-002 · API-09-008, 009 · ERR-09-001, 002, 011 · BR-09-002.

**Tiền điều kiện, dữ liệu.** T90; loại `HEALTH` đang gắn 3 phần tử; U-T90-SO.

**Các bước.**

1. SO `POST /personal-data-categories` với `code = HEALTH`.
2. SO `PATCH /personal-data-categories/HEALTH` đặt `status = RETIRED`.
3. SO thêm loại `TC_LOAI_MOI` rồi ngừng ngay.
4. SO `GET /personal-data-categories/TC_LOAI_MOI` sau khi đã `RETIRED`.

**Kết quả mong đợi.** Bước 1 `409` ERR-09-002. Bước 2 `409` ERR-09-011, không đổi. Bước 3 thêm `201`, ngừng `200`; KT: có cho cả hai. Bước 4 `410` ERR-09-001 vì đối tượng danh mục đã ngừng.

**Thông báo hiển thị.** "Mã HEALTH đã được dùng. Chọn mã khác." và "Mục HEALTH đang được 3 trường sử dụng nên không ngừng được."
:::

#### TC-09-003 · Xuất danh mục phân loại chạy nền, tải tệp, rò rỉ chéo tenant <!--k:cls-export-->

::: dac-ta
**Mục đích.** Chứng minh xuất theo bộ lọc có trạng thái nền và không lẫn phần tử tenant khác.

**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-008 · API-09-030, 031 · UI-09-02 · BR-09-060 · ERR-09-001.

**Tiền điều kiện, dữ liệu.** T90 F-ELM 60 phần tử; T91 có 5 phần tử; U-T90-AU, U-T91-SO.

**Các bước.**

1. AU `POST /classification-exports` lọc `dataClass = SENSITIVE`, rồi hỏi `GET /classification-exports/{id}` đến `READY`.
2. Tải tệp; đếm dòng.
3. U-T91-SO `GET /classification-exports/{id}` của T90.

**Kết quả mong đợi.** Bước 1 `202` rồi `READY`. Bước 2 tệp chỉ có phần tử `SENSITIVE` của T90, không có giá trị dữ liệu, KT: có (classification-export). Bước 3 `404` ERR-09-001, thân giống "không tồn tại".
:::

### TS-09-02 · Đăng ký phần tử dữ liệu từ lược đồ và khai báo MVP

**Mục tiêu.** Xác nhận đăng ký phần tử từ phân hệ, lược đồ OpenAPI, JSON Schema, Avro và khai báo MVP, đúng trạng thái, không trùng.

**Phủ.** FR-09-003; UC-09-02; API-09-010…014, 243; UI-09-02, 03; BR-09-001, 007; ERR-09-003, 006, 014, 015.

#### TC-09-004 · Đăng ký phần tử hàng loạt qua scope `privacy:register` <!--k:elm-register-->

::: dac-ta
**Mục đích.** Chứng minh phần tử mới chưa phân loại được xử lý như `SENSITIVE` (BR-09-001) cho đến khi `CONFIRMED`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-003 · API-09-012, 010, 011 · UI-09-02 · BR-09-001.

**Tiền điều kiện, dữ liệu.** T90; S-T90-REG; PH-06 giả lập gửi 20 phần tử `INTERNAL_ENTITY`.

**Các bước.**

1. S-T90-REG `POST /data-elements:register` 20 phần tử, `Idempotency-Key` K1.
2. Gửi lại đúng yêu cầu với K1.
3. `GET /data-elements?status=ACTIVE&unclassified=true` rồi `GET /data-elements/{id}`.

**Kết quả mong đợi.** Bước 1 `201`, 20 phần tử `ACTIVE`. Bước 2 `200` cùng kết quả, không tạo thêm. Bước 3 20 phần tử, `effectiveClass = SENSITIVE`, `provisional = true`; KT: có (element-register).
:::

#### TC-09-005 · Nhập lược đồ, khai báo MVP và lược đồ hỏng <!--k:elm-import-->

::: dac-ta
**Mục đích.** Chứng minh khai báo MVP nhập ở `PROPOSED`, giữ nguyên mức đã khai; lược đồ hỏng và phần tử trùng bị từ chối.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-003 · API-09-013, 014 · BR-09-007 · ERR-09-015, 003, 014.

**Tiền điều kiện, dữ liệu.** T90; tệp `hs-suc-khoe.openapi.yaml` (14 trường), `ca.avsc` (6 trường), `hong.json`; khai báo `x-dh-classification` ở 5 trường; U-T90-DS1.

**Các bước.**

1. DS1 `POST /data-elements:import-schema` với từng tệp.
2. DS1 `POST /data-elements:import-declarations` với 5 khai báo.
3. DS1 nhập lại `hs-suc-khoe.openapi.yaml`.
4. DS1 đăng ký phần tử trỏ tới hợp đồng không có.

**Kết quả mong đợi.** Bước 1 OpenAPI và Avro `201` (20 phần tử), `hong.json` `422` ERR-09-015, không tạo phần tử. Bước 2 5 phần tử `ClassificationStatus = PROPOSED`, `source = MVP_IMPORT`, mức đúng như khai. Bước 3 `409` ERR-09-014. Bước 4 `400` ERR-09-003.

**Thông báo hiển thị.** "Không đọc được lược đồ: dòng 3 thiếu `type`." và "Phần tử hs-suc-khoe.cccd đã được đăng ký."
:::

#### TC-09-006 · Ngừng phần tử đang thuộc hoạt động xử lý rồi ngừng sau khi gỡ liên kết <!--k:elm-retire-->

::: dac-ta
**Mục đích.** Chứng minh phần tử đang được hoạt động hoặc hợp đồng dùng không ngừng được.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-003 · API-09-010, 243 · ERR-09-006 · UI-09-03.

**Tiền điều kiện, dữ liệu.** T90; phần tử `cccd` thuộc hoạt động `ACTIVE` HD-01.

**Các bước.**

1. DS1 mở UI-09-03, tab "Hoạt động liên kết" của phần tử `cccd`, bấm "Ngừng phần tử" kèm lý do.
2. SO của tổ chức sở hữu gỡ liên kết với HD-01 rồi `POST /data-elements/{id}:retire` (API-09-243).

**Kết quả mong đợi.** Bước 1 giao diện hiện số liên kết, gọi API trả `409` ERR-09-006, phần tử vẫn `ACTIVE`. Bước 2 `200`, `RETIRED`, lịch sử phân loại còn nguyên.

**Thông báo hiển thị.** "Đối tượng đang ở trạng thái còn liên kết hoạt động ACTIVE, không thực hiện được thao tác này."
:::

### TS-09-03 · Đề xuất, xác nhận và hạ mức phân loại trường

**Mục tiêu.** Xác nhận đề xuất, xác nhận, từ chối, hàng loạt và hạ mức bốn mắt có văn bản căn cứ, người đề xuất không tự xác nhận.

**Phủ.** FR-09-004; UC-09-03; API-09-015…019; UI-09-02, 03; BR-09-002, 003, 007; ERR-09-005, 012, 013.

#### TC-09-007 · Đề xuất rồi xác nhận nâng mức, sự kiện đổi phân loại <!--k:clf-propose-confirm-->

::: dac-ta
**Mục đích.** Chứng minh nâng mức chỉ cần một người xác nhận khác người đề xuất, có sự kiện và lịch sử.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-004 · API-09-015, 016, 019 · UI-09-03 · EVT-09-01 · BR-09-003.

**Tiền điều kiện, dữ liệu.** T90; phần tử `ngaySinh` mức `INTERNAL`; U-T90-DS1 (đề xuất), U-T90-SO (xác nhận).

**Các bước.**

1. DS1 `PUT /data-elements/{id}/classification` đề xuất `RESTRICTED`, loại `BASIC`, `identifiability = QUASI`.
2. SO `POST /classifications/{cid}:confirm`.
3. `GET /data-elements/{id}/history`.

**Kết quả mong đợi.** Bước 1 `200`, `PROPOSED`. Bước 2 `200`, `CONFIRMED`, bản cũ `SUPERSEDED`. EVT: `classification.changed` mang mức cũ và mới. Bước 3 hai dòng lịch sử, người, thời điểm. KT: có (classification-confirm).
:::

#### TC-09-008 · Người đề xuất tự xác nhận, DS xác nhận, thiếu loại DLCN <!--k:clf-self-neg-->

::: dac-ta
**Mục đích.** Chứng minh chỉ TA, SO, DO tổ chức sở hữu xác nhận và người đề xuất không tự xác nhận (BR-09-003).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-004 · API-09-015, 016 · ERR-09-005, 012 · BR-09-003.

**Tiền điều kiện, dữ liệu.** T90; phần tử `email` chưa phân loại; U-T90-DS1, U-T90-SO.

**Các bước.**

1. DS1 đề xuất `INTERNAL` rồi tự `:confirm`.
2. DS1 đề xuất `INTERNAL` loại `NONE` cho trường tên `soDienThoai`.
3. SO đề xuất rồi tự `:confirm`.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-005. Bước 2 `422` ERR-09-012 (trường là DLCN cần chọn loại phù hợp). Bước 3 `403` ERR-09-005. Phân loại còn `PROPOSED`.

**Thông báo hiển thị.** "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
:::

#### TC-09-009 · Hạ mức cần số văn bản căn cứ và người thứ hai <!--k:clf-downgrade-->

::: dac-ta
**Mục đích.** Chứng minh hạ mức hoặc hạ loại DLCN từ `SENSITIVE` xuống `BASIC` hoặc `NONE` cần văn bản căn cứ và hai người khác nhau (BR-09-002).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-004 · API-09-015, 016 · ERR-09-013, 005 · BR-09-002.

**Tiền điều kiện, dữ liệu.** T90; `soTaiKhoan` đang `SENSITIVE` `CONFIRMED`; U-T90-SO, U-T90-TA.

**Các bước.**

1. SO đề xuất hạ xuống `RESTRICTED` không nêu căn cứ.
2. SO đề xuất kèm `legalDocument = CV-123/2026`, lý do 30 ký tự; SO tự xác nhận.
3. TA xác nhận.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-013. Bước 2 đề xuất `PROPOSED`, tự xác nhận `403` ERR-09-005. Bước 3 `200`, mức mới `RESTRICTED`, EVT: `classification.changed`, KT: có (classification-downgrade) kèm số văn bản.

**Thông báo hiển thị.** "Hạ mức phân loại cần nêu số văn bản căn cứ và lý do."
:::

#### TC-09-010 · Xác nhận hàng loạt chỉ cho mẫu đã duyệt và từ chối đề xuất <!--k:clf-bulk-->

::: dac-ta
**Mục đích.** Chứng minh xác nhận hàng loạt chỉ áp cho đề xuất cùng mẫu đã xem và từ chối ghi được lý do.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-004 · API-09-017, 018 · BR-09-007 · ERR-09-006.

**Tiền điều kiện, dữ liệu.** T90; 5 phần tử `PROPOSED` từ khai báo MVP; U-T90-SO.

**Các bước.**

1. SO `POST /classifications:bulk-confirm` với 5 mã.
2. SO `:reject` một đề xuất đã `CONFIRMED`.
3. SO `:reject` đề xuất `PROPOSED` kèm lý do.

**Kết quả mong đợi.** Bước 1 `200`, 5 phần tử `CONFIRMED`, giữ đúng mức đã khai. Bước 2 `409` ERR-09-006. Bước 3 `200`, `REJECTED`.
:::

### TS-09-04 · Quét phát hiện trường nghi dữ liệu cá nhân

**Mục tiêu.** Xác nhận quét mẫu bằng bộ mẫu và kiểm tổng, kết quả chỉ là gợi ý, không chạy chồng, mẫu độc hại bị chặn.

**Phủ.** FR-09-005; UC-09-04; API-09-020…026; UI-09-04; BR-09-006, 025; ERR-09-016, 017; NFR-09-009.

#### TC-09-011 · Quét cột có CCCD, MST, thẻ, điện thoại, thư điện tử <!--k:scan-run-->

::: dac-ta
**Mục đích.** Chứng minh phát hiện bằng mẫu và kiểm tổng, kết quả vào hộp việc, không tự đổi phân loại (BR-09-006).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-09-005 · API-09-020, 022, 023, 024 · UI-09-04 · BR-09-006 · EVT-09-02.

**Tiền điều kiện, dữ liệu.** T98 F-SCAN: bảng 40 cột giả (8 cột có số định danh đúng, 4 cột nhiễu), 10.000 dòng.

**Các bước.**

1. U-T90-SO `POST /scans` cho bảng F-SCAN, `09.scan.confidence = 0,8`.
2. Hỏi `GET /scans/{id}` đến `COMPLETED`, rồi `GET /scans/{id}/findings`.
3. SO `POST /findings/{fid}:resolve` hành động `CLASSIFY` một kết quả.

**Kết quả mong đợi.** Bước 2 8 kết quả `OPEN` đúng `detectorType` (`NATIONAL_ID_12`, `TAX_ID_10_13`, `BANK_CARD_LUHN`, `PHONE_VN`, `EMAIL`), mỗi kết quả có độ tin cậy và 3 dòng mẫu đã che, không giá trị rõ. EVT: `classification.scan-finished`. Bước 3 tạo đề xuất `PROPOSED`, phân loại hiện hành chưa đổi.
:::

#### TC-09-012 · Quét chồng, mẫu phát hiện nguy hiểm, kết quả đã xử lý <!--k:scan-neg-->

::: dac-ta
**Mục đích.** Chứng minh không chạy hai lượt trên cùng phạm vi và mẫu có thể làm chậm bị chặn.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-005 · API-09-020, 026 · ERR-09-016, 017, 006.

**Tiền điều kiện, dữ liệu.** T98; một lượt quét `RUNNING`; U-T90-SO; biểu thức `(a+)+$`.

**Các bước.**

1. SO `POST /scans` cùng phạm vi đang quét.
2. SO `PUT /detectors/EMAIL` với biểu thức `(a+)+$`.
3. SO `:resolve` kết quả đã `CLASSIFIED`.

**Kết quả mong đợi.** Bước 1 `409` ERR-09-017. Bước 2 `422` ERR-09-016, mẫu cũ giữ. Bước 3 `409` ERR-09-006.

**Thông báo hiển thị.** "Đang có lượt quét cho phạm vi này. Chờ lượt quét xong."
:::

#### TC-09-013 · Tỷ lệ bỏ sót số định danh chuẩn ≤ 1 % <!--k:scan-recall-->

::: dac-ta
**Mục đích.** Đo độ phủ của bộ mẫu và kiểm tổng.

**Loại.** Độ chính xác.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** FR-09-005 · NFR-09-009 · API-09-020.

**Tiền điều kiện, dữ liệu.** T98 bộ mẫu chuẩn 5.000 giá trị CCCD, MST, thẻ, điện thoại hợp lệ chèn vào 500 cột; giả định theo Q09-41.

**Các bước.**

1. Chạy `POST /scans` cho 500 cột, `09.scan.sample-rows = 10.000`.
2. So kết quả với danh sách chèn.

**Kết quả mong đợi.** Bỏ sót ≤ 1 % số cột chứa số định danh chuẩn; quét xong ≤ 10 phút (4 vCPU).
:::

### TS-09-05 · Mức phân loại của hợp đồng

**Mục tiêu.** Xác nhận mức hợp đồng bằng mức cao nhất của trường, mức tạm thời khi còn trường chưa xác nhận và tính lại khi phân loại đổi.

**Phủ.** FR-09-006; UC-09-05; API-09-027, 028, 029; UI-09-02, 03; BR-09-001, 004; NFR-09-010.

#### TC-09-014 · Mức hợp đồng bằng mức cao nhất, tạm thời khi còn trường chưa xác nhận <!--k:ctr-level-->

::: dac-ta
**Mục đích.** Chứng minh mức hợp đồng theo trường cao nhất và `provisional` theo BR-09-001.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-006 · API-09-027, 028, 029 · BR-09-004, 001 · EVT-09-03.

**Tiền điều kiện, dữ liệu.** T90; API-HGD có 6 trường (5 `CONFIRMED` mức thấp nhất `INTERNAL`, 1 chưa phân loại); S-T90-REG.

**Các bước.**

1. `GET /contract-levels/API/API-HGD`.
2. SO xác nhận trường còn lại là `RESTRICTED`; S-T90-REG `POST /contract-levels:recompute`.
3. `GET /contract-levels/API/API-HGD`.

**Kết quả mong đợi.** Bước 1 `level = SENSITIVE`, `provisional = true`. Bước 3 `level = RESTRICTED`, `provisional = false`. EVT: `contract-level.changed` đúng một lần với mức cũ và mới.
:::

#### TC-09-015 · Hợp đồng không tự hạ mức khi trường bị hạ chưa duyệt đủ <!--k:ctr-downgrade-neg-->

::: dac-ta
**Mục đích.** Chứng minh đề xuất chưa xác nhận không làm đổi mức hợp đồng.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-006 · API-09-028 · BR-09-004, 002.

**Tiền điều kiện, dữ liệu.** T90; API-HGD mức `SENSITIVE` do `soTaiKhoan`; đề xuất hạ mức ở `PROPOSED`.

**Các bước.**

1. `GET /contract-levels/API/API-HGD` khi đề xuất hạ còn `PROPOSED`.
2. TA xác nhận đề xuất; gọi lại.

**Kết quả mong đợi.** Bước 1 `SENSITIVE`, không `EVT`. Bước 2 mức mới theo trường cao nhất còn lại, EVT: `contract-level.changed`.
:::

#### TC-09-016 · Tính lại 3.000 hợp đồng ≤ 60 giây, mỗi hợp đồng ≤ 5 giây <!--k:ctr-recompute-perf-->

::: dac-ta
**Mục đích.** Đo NFR-09-010.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** FR-09-006 · NFR-09-010 · API-09-029.

**Tiền điều kiện, dữ liệu.** T97 200 HTTT, 3.000 hợp đồng, 50.000 phần tử.

**Các bước.**

1. Đổi mức một phần tử dùng chung 3.000 hợp đồng; đo thời gian đến khi `EVT-09-03` cuối.
2. Gọi `POST /contract-levels:recompute` cho một hợp đồng 200 trường.

**Kết quả mong đợi.** Bước 1 ≤ 60 giây; bước 2 ≤ 5 giây.
:::

### TS-09-06 · Nhãn bí mật nhà nước và chặn dữ liệu

**Mục tiêu.** Xác nhận chặn tuyệt đối toàn bản tin khi có nhãn `STATE_SECRET`, thân lỗi không nêu trường, gỡ nhãn cần văn bản giải mật và hai người.

**Phủ.** FR-09-007; UC-09-06; API-09-003…006, 231; UI-09-03; BR-09-005, 057; ERR-09-018, 019, 101; EVT-09-14.

#### TC-09-017 · Gán nhãn rồi bản tin có trường nhãn bị chặn toàn bộ <!--k:lbl-block-->

::: dac-ta
**Mục đích.** Chứng minh chặn cả bản tin, không lọc từng trường, không nêu trường nào mang nhãn (BR-09-005).

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-007 · API-09-004, 231 · BR-09-005 · ERR-09-101 · EVT-09-14.

**Tiền điều kiện, dữ liệu.** T90; phần tử `soHieuMat` đề nghị nhãn; U-T90-SO, U-T90-DO1; S-T90-PEP-04; bản tin F-MSG có 8 trường kèm `soHieuMat`.

**Các bước.**

1. SO `POST /secret-labels` gán `STATE_SECRET` cho `soHieuMat`.
2. PEP `POST /privacy/v1/classification:check` với F-MSG.

**Kết quả mong đợi.** Bước 2 `403` ERR-09-101 "Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước."; thân không nêu tên trường, không trả trường nào khác; EVT: `secret-label.blocked` (cảnh báo nghiêm trọng tới SO); KT: có (secret-block).
:::

#### TC-09-018 · Đăng ký phần tử mang nhãn bí mật hoặc lược đồ có trường nhãn <!--k:lbl-ingest-neg-->

::: dac-ta
**Mục đích.** Chứng minh dữ liệu mang nhãn không được đưa vào Datahub.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-007 · API-09-012, 013 · ERR-09-018.

**Tiền điều kiện, dữ liệu.** T90; nhãn `STATE_SECRET` đã gán; U-T90-DS1.

**Các bước.**

1. DS1 nhập lược đồ chứa trường `soHieuMat`.
2. S-T90-REG đăng ký phần tử đích trùng phần tử có nhãn.

**Kết quả mong đợi.** Cả hai `422` ERR-09-018, không phần tử nào được tạo; EVT: `secret-label.blocked`.

**Thông báo hiển thị.** "Dữ liệu mang nhãn bí mật nhà nước không được đưa vào Datahub."
:::

#### TC-09-019 · Gỡ nhãn cần số và ngày văn bản giải mật, người thứ hai duyệt <!--k:lbl-release-->

::: dac-ta
**Mục đích.** Chứng minh gỡ nhãn có hai người và bằng chứng giải mật.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-007 · API-09-005, 006 · ERR-09-019, 005 · BR-09-005, 057.

**Tiền điều kiện, dữ liệu.** T90; nhãn của ca lbl-block; U-T90-SO, U-T90-TA.

**Các bước.**

1. SO `POST /secret-labels/{id}:request-release` thiếu số văn bản.
2. SO đề nghị kèm `declassificationDoc = GM-09/2026`, ngày 2026-11-01.
3. SO tự `:approve-release`.
4. TA `:approve-release`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-019. Bước 3 `403` ERR-09-005. Bước 4 `200`, nhãn `RELEASED`, KT: có (secret-label-release) gồm số văn bản. `classification:check` sau đó cho qua.

**Thông báo hiển thị.** "Gỡ nhãn bí mật nhà nước cần số và ngày văn bản giải mật."
:::

#### TC-09-020 · Không ghi được nhật ký thì không gỡ nhãn <!--k:lbl-audit-fail-->

::: dac-ta
**Mục đích.** Chứng minh thao tác đặc quyền bị từ chối khi không ghi được kiểm toán (BR-09-057).

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-09-007 · BR-09-057 · ERR-09-010 · API-09-006.

**Tiền điều kiện, dữ liệu.** T94; nhãn đã có đề nghị gỡ; PH-13 giả lập trả `503`.

**Các bước.**

1. TA `:approve-release` khi PH-13 ngừng.

**Kết quả mong đợi.** `503` ERR-09-010, nhãn còn `STATE_SECRET`; bật lại PH-13 thì thao tác chạy được.
:::

### TS-09-07 · Sổ hoạt động xử lý, liên kết và xuất sổ

**Mục tiêu.** Xác nhận lập, duyệt bốn mắt, phiên bản hóa, liên kết trường và xuất sổ hoạt động xử lý theo mẫu.

**Phủ.** FR-09-009, 010, 011, 013; UC-09-07; API-09-032…044, 051…053; UI-09-05, 06; BR-09-008, 009, 010, 011, 012; ERR-09-020, 021, 022, 023, 024, 025.

#### TC-09-021 · Lập hoạt động, gửi duyệt, duyệt bốn mắt, kích hoạt <!--k:ropa-create-approve-->

::: dac-ta
**Mục đích.** Chứng minh hoạt động chỉ `ACTIVE` sau khi người khác người soạn duyệt và có phiên bản.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-009, 010 · API-09-033, 036, 037, 040 · UI-09-05, 06 · BR-09-009, 010, 011 · EVT-09-04.

**Tiền điều kiện, dữ liệu.** T90; U-T90-DS1 (soạn), U-T90-DA1 (duyệt); căn cứ `STATE_TASK` văn bản `ND-xx/2026` còn hiệu lực.

**Các bước.**

1. DS1 `POST /processing-activities` đủ mục đích, cơ sở `STATE_TASK`, vai trò `CONTROLLER`, dữ liệu, bên nhận, thời hạn lưu 60 tháng, hành động `DELETE`.
2. DS1 `:submit`; DA1 `:approve`.
3. `GET /processing-activities/{id}/versions`.

**Kết quả mong đợi.** Bước 1 `201`, `DRAFT`; hoạt động dữ liệu đi qua ghi vai trò `PROCESSOR` và bên kiểm soát là cơ quan cung cấp (BR-09-010). Bước 2 `PENDING_APPROVAL` rồi `ACTIVE`, EVT: `activity.activated`, KT: có (activity-approve). Bước 3 phiên bản 1 `ACTIVE`.
:::

#### TC-09-022 · Thiếu mục, căn cứ hết hiệu lực, đồng ý cho hoạt động bắt buộc, tự duyệt <!--k:ropa-neg-->

::: dac-ta
**Mục đích.** Chứng minh kiểm đủ mục (BR-09-012), căn cứ còn hiệu lực, cơ sở `CONSENT` không dùng cho hoạt động bắt buộc, người soạn không duyệt.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-009, 010 · API-09-033, 036, 037 · ERR-09-020, 021, 024, 005 · BR-09-009, 012.

**Tiền điều kiện, dữ liệu.** T90; văn bản `ND-cu/2020` hết hiệu lực; U-T90-DS1, U-T90-DA1.

**Các bước.**

1. DS1 `:submit` hoạt động thiếu thời hạn lưu.
2. DS1 tạo hoạt động dùng căn cứ `ND-cu/2020`.
3. DS1 tạo hoạt động bắt buộc theo luật với `legalBasis = CONSENT`.
4. DS1 gửi duyệt rồi tự `:approve`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-020 nêu "thời hạn lưu". Bước 2 `422` ERR-09-021. Bước 3 `422` ERR-09-024. Bước 4 `403` ERR-09-005.

**Thông báo hiển thị.** "Hoạt động xử lý còn thiếu: thời hạn lưu."
:::

#### TC-09-023 · Liên kết trường DLCN, trường chưa thuộc hoạt động, ngừng khi còn liên kết <!--k:ropa-link-->

::: dac-ta
**Mục đích.** Chứng minh mỗi trường DLCN đã xác nhận thuộc ít nhất một hoạt động `ACTIVE` (BR-09-008).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-011 · API-09-041, 042, 043, 044, 039 · ERR-09-022, 023 · BR-09-008.

**Tiền điều kiện, dữ liệu.** T90; 4 trường DLCN `CONFIRMED`, 1 trường chưa thuộc hoạt động; HD-01 `ACTIVE`.

**Các bước.**

1. `GET /processing-activities:unlinked-elements`.
2. DS1 thêm liên kết trường còn lại vào HD-01 (phiên bản mới, chờ duyệt).
3. TA gọi `:retire` HD-01 khi còn liên kết.
4. S-T90-REG kích hoạt hợp đồng chứa trường chưa liên kết (xem TC-09-051).

**Kết quả mong đợi.** Bước 1 liệt kê đúng 1 trường. Bước 3 `409` ERR-09-022. Bước 4 `422` ERR-09-023 nêu số trường chưa thuộc hoạt động. Sau khi duyệt, `unlinked-elements` rỗng.

**Thông báo hiển thị.** "Hoạt động còn 4 liên kết đang hiệu lực. Gỡ liên kết trước khi ngừng."
:::

#### TC-09-024 · Xuất sổ theo mẫu và mẫu không tồn tại <!--k:ropa-export-->

::: dac-ta
**Mục đích.** Chứng minh xuất sổ chạy nền theo mẫu và không chứa dữ liệu cá nhân.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-013 · API-09-051, 052, 053 · ERR-09-025 · UI-09-05.

**Tiền điều kiện, dữ liệu.** T90; HD-01 `ACTIVE`; U-T90-SO.

**Các bước.**

1. SO `GET /ropa-templates`; `POST /ropa-exports` mẫu `A05-ROPA` rồi tải tệp.
2. `POST /ropa-exports` mẫu `khong-co`.

**Kết quả mong đợi.** Bước 1 tệp đủ cột mục đích, cơ sở, dữ liệu, bên nhận, thời hạn lưu; không giá trị DLCN; KT: có (ropa-export). Bước 2 `422` ERR-09-025.
:::

### TS-09-08 · Cơ sở pháp lý, văn bản căn cứ và mục đích khai thác

**Mục tiêu.** Xác nhận danh mục cơ sở, văn bản và mục đích, kiểm mã trùng và ngừng khi còn dùng.

**Phủ.** FR-09-012, 014; UC-09-08; API-09-045…050, 054…057; UI-09-07; BR-09-009, 015, 047; ERR-09-002, 011, 021.

#### TC-09-025 · Thêm văn bản căn cứ, cơ sở và mục đích, mục đích bắt buộc theo luật <!--k:pur-catalog-->

::: dac-ta
**Mục đích.** Chứng minh danh mục mục đích gắn cơ sở pháp lý và cờ bắt buộc theo luật dùng cho BR-09-047.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-012, 014 · API-09-046, 049, 055, 054 · UI-09-07 · BR-09-047.

**Tiền điều kiện, dữ liệu.** T90; U-T90-DO1, U-T90-TA.

**Các bước.**

1. TA `POST /legal-documents` văn bản `ND-xx/2026` hiệu lực từ 2026-01-01.
2. TA `POST /legal-bases` cơ sở `STATE_TASK` gắn văn bản.
3. DO1 `POST /purposes` mã `MD-TRACUU-HGD`, cờ `statutory = false`; thêm `MD-LUATDINH` cờ `true`.
4. `GET /purposes`.

**Kết quả mong đợi.** Bước 1 đến 3 `201`; bước 4 có cả hai mục đích; KT: có cho mỗi thao tác ghi.
:::

#### TC-09-026 · Mã mục đích trùng, ngừng mục đích còn chấp thuận, văn bản hết hiệu lực <!--k:pur-neg-->

::: dac-ta
**Mục đích.** Chứng minh mục đích đang dùng không ngừng được và mã duy nhất.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-012, 014 · API-09-055, 057, 050 · ERR-09-002, 011, 021.

**Tiền điều kiện, dữ liệu.** T90; `MD-TRACUU-HGD` có 1 chấp thuận `ACTIVE`; U-T90-DO1, U-T90-TA.

**Các bước.**

1. DO1 `POST /purposes` mã `MD-TRACUU-HGD`.
2. DO1 `POST /purposes/MD-TRACUU-HGD:retire`.
3. TA `PATCH /legal-documents/{id}` đặt hết hiệu lực văn bản đang làm căn cứ cho HD-01.

**Kết quả mong đợi.** Bước 1 `409` ERR-09-002. Bước 2 `409` ERR-09-011 nêu 1 chấp thuận. Bước 3 `200`, hoạt động HD-01 được gắn cờ cảnh báo cần rà soát căn cứ (ERR-09-021 khi gửi duyệt phiên bản mới).
:::

#### TC-09-027 · Mục đích bị giới hạn bởi trần thời hạn chấp thuận <!--k:pur-grant-cap-->

::: dac-ta
**Mục đích.** Chứng minh tham số tenant không vượt trần PA.

**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-09-014 · API-09-056 · BR-09-015 · ERR-09-078.

**Tiền điều kiện, dữ liệu.** T92; U-T90-TA; PA đặt trần `09.grant.max-days = 730`.

**Các bước.**

1. TA đặt `09.grant.max-days = 731` qua `PUT /settings`.
2. TA đặt `730`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-078 nêu miền `30…730`. Bước 2 `200`, KT: có (settings-update).
:::

### TS-09-09 · Lập yêu cầu khai thác theo mục đích

**Mục tiêu.** Xác nhận lập, gửi, rút yêu cầu khai thác cho HTTT, chỉ với mục đích còn hiệu lực, HTTT có đăng ký sử dụng, trường trong phạm vi.

**Phủ.** FR-09-015; UC-09-09; API-09-058…063; UI-09-08; BR-09-013, 016; ERR-09-026, 027, 028, 003, 008.

#### TC-09-028 · Lập nháp, sửa, gửi thẩm định tới chủ quản <!--k:req-submit-->

::: dac-ta
**Mục đích.** Chứng minh yêu cầu nháp gửi được và phát sự kiện tới chủ quản.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-015 · API-09-059, 061, 062, 060 · UI-09-08 · EVT-09-05 · PERM-09-purpose-request.

**Tiền điều kiện, dữ liệu.** T90; U-T90-OR1; HTTT-BH có đăng ký sử dụng PH-02; API-HGD mức `SENSITIVE`; mục đích `MD-TRACUU-HGD`.

**Các bước.**

1. OR1 `POST /access-requests` (HTTT-BH, mục đích, API-HGD, 6 trường, 5.000 lượt mỗi ngày).
2. OR1 `PUT` thêm lý do sử dụng; `:submit`.

**Kết quả mong đợi.** Bước 1 `201` `DRAFT`. Bước 2 `SUBMITTED`; EVT: `purpose-request.submitted`; hộp việc DO1 có yêu cầu với hạn `09.request.sla-days = 10` ngày làm việc.
:::

#### TC-09-029 · Mục đích hết hiệu lực, HTTT chưa hoạt động, trường ngoài phạm vi, tổ chức khác <!--k:req-neg-->

::: dac-ta
**Mục đích.** Chứng minh kiểm tra nghiệp vụ ở bước lập và phạm vi tổ chức của OR.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-015 · API-09-059, 061 · ERR-09-026, 027, 028, 003, 008, 009 · BR-09-016.

**Tiền điều kiện, dữ liệu.** T90; `MD-CU` đã `RETIRED`; HTTT-CHUA chưa đăng ký sử dụng; mục đích `MD-THONGKE` chỉ cho 3 trường; U-T90-OR1, OR2 (tổ chức khác).

**Các bước.**

1. OR1 lập yêu cầu mục đích `MD-CU`.
2. OR1 lập yêu cầu cho HTTT-CHUA.
3. OR1 lập yêu cầu `MD-THONGKE` kèm trường ngoài 3 trường cho phép.
4. OR2 `PUT` yêu cầu nháp của OR1.
5. OR1 lập yêu cầu với `contractId` không tồn tại.
6. Ngừng PH-02 rồi OR1 lập yêu cầu mới.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-026. Bước 2 `422` ERR-09-027. Bước 3 `422` ERR-09-028 nêu tên trường. Bước 4 `403` ERR-09-008. Bước 5 `400` ERR-09-003. Bước 6 `503` ERR-09-009 "Chưa kết nối được PH-02. Thử lại sau ít phút."

**Thông báo hiển thị.** "Trường soTaiKhoan nằm ngoài phạm vi của mục đích MD-THONGKE."
:::

#### TC-09-030 · Rút yêu cầu chưa quyết định và rút yêu cầu đã duyệt <!--k:req-withdraw-->

::: dac-ta
**Mục đích.** Chứng minh chỉ rút được yêu cầu chưa có quyết định cuối.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-015 · API-09-063 · ERR-09-006.

**Tiền điều kiện, dữ liệu.** T90; hai yêu cầu `SUBMITTED` và `APPROVED`; U-T90-OR1.

**Các bước.**

1. OR1 `:withdraw` yêu cầu `SUBMITTED`.
2. OR1 `:withdraw` yêu cầu `APPROVED`.

**Kết quả mong đợi.** Bước 1 `200`, `WITHDRAWN`, mục biến khỏi hộp việc DO1. Bước 2 `409` ERR-09-006.
:::

### TS-09-10 · Thẩm định, chấp thuận có điều kiện hoặc từ chối

**Mục tiêu.** Xác nhận chủ quản dữ liệu chấp thuận, chấp thuận có điều kiện, từ chối, yêu cầu bổ sung; người lập không duyệt yêu cầu của mình; không trùng chấp thuận.

**Phủ.** FR-09-016; UC-09-10; API-09-064…066; UI-09-09; BR-09-013, 014, 015, 016; ERR-09-005, 008, 029, 030.

#### TC-09-031 · Chấp thuận có điều kiện tạo chấp thuận `ACTIVE` kèm điều kiện <!--k:dec-approve-cond-->

::: dac-ta
**Mục đích.** Chứng minh quyết định `APPROVE_WITH_CONDITIONS` ghi điều kiện `FIELD_SUBSET`, `DAILY_QUOTA`, `NO_EXPORT` vào chấp thuận và bundle.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-016 · API-09-064, 065 · UI-09-09 · EVT-09-06 · BR-09-016 · PERM-09-purpose-approve.

**Tiền điều kiện, dữ liệu.** T90; yêu cầu của ca req-submit; U-T90-DO1 (chủ quản `HT-YT`).

**Các bước.**

1. DO1 `GET /access-requests:inbox`.
2. DO1 `POST /access-requests/{id}:decide` `APPROVE_WITH_CONDITIONS`, hạn 180 ngày, 4 trong 6 trường, hạn ngạch 2.000 lượt mỗi ngày, `NO_EXPORT`.
3. `GET /purpose-grants/{gid}`.

**Kết quả mong đợi.** Bước 2 `200`, yêu cầu `APPROVED`, chấp thuận `ACTIVE` đúng bộ ba (HTTT-BH, `MD-TRACUU-HGD`, API-HGD). EVT: `purpose-grant.approved`; KT: có (grant-approve). Bước 3 hiện đủ điều kiện, `validTo` = hôm nay + 180 ngày.
:::

#### TC-09-032 · Từ chối bắt buộc lý do, yêu cầu bổ sung thông tin <!--k:dec-reject-info-->

::: dac-ta
**Mục đích.** Chứng minh từ chối có lý do và yêu cầu bổ sung đưa yêu cầu về `NEEDS_INFO`.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-016 · API-09-065, 066 · ERR-09-007 · UI-09-09.

**Tiền điều kiện, dữ liệu.** T90; hai yêu cầu `SUBMITTED`; U-T90-DO1, U-T90-OR1.

**Các bước.**

1. DO1 `:request-info` yêu cầu thứ nhất, câu hỏi 25 ký tự.
2. DO1 `:decide` `REJECT` yêu cầu thứ hai, lý do 10 ký tự.
3. DO1 `:decide` `REJECT` lý do 30 ký tự.

**Kết quả mong đợi.** Bước 1 `AccessRequestStatus = NEEDS_INFO`, OR1 nhận thông báo. Bước 2 `422` ERR-09-007. Bước 3 `REJECTED`; không có chấp thuận nào; OR1 xem được lý do.

**Thông báo hiển thị.** "Nhập lý do tối thiểu 20 ký tự."
:::

#### TC-09-033 · Người lập tự duyệt, DO tổ chức khác, trùng chấp thuận, vượt thời hạn tối đa <!--k:dec-neg-->

::: dac-ta
**Mục đích.** Chứng minh BR-09-013, 014, 015.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-016 · API-09-065 · ERR-09-005, 008, 029, 030 · BR-09-013, 014, 015.

**Tiền điều kiện, dữ liệu.** T90; TA đồng thời lập yêu cầu; DO2 thuộc Sở GD; chấp thuận ACTIVE của HTTT-BH.

**Các bước.**

1. TA lập yêu cầu rồi tự `:decide` `APPROVE`.
2. DO2 `:decide` yêu cầu của dữ liệu `HT-YT`.
3. DO1 duyệt yêu cầu thứ hai cùng bộ ba đã có chấp thuận `ACTIVE`.
4. DO1 duyệt với hạn 400 ngày.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-005. Bước 2 `403` ERR-09-008. Bước 3 `409` ERR-09-029. Bước 4 `422` ERR-09-030 "Thời hạn chấp thuận tối đa 365 ngày."
:::

#### TC-09-034 · Hộp việc sắp theo hạn và quá hạn thẩm định <!--k:dec-sla-->

::: dac-ta
**Mục đích.** Chứng minh thứ tự hộp việc và cờ quá hạn theo ngày làm việc.

**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-09-016 · API-09-064 · UI-09-09 · NFR-09-016.

**Tiền điều kiện, dữ liệu.** T92 `09.request.sla-days = 3`; ba yêu cầu gửi cách nhau 1, 3, 4 ngày làm việc (đồng hồ giả).

**Các bước.**

1. DO1 `GET /access-requests:inbox` sau 4 ngày làm việc.

**Kết quả mong đợi.** Sắp theo hạn tăng dần; yêu cầu 4 ngày có cờ quá hạn, yêu cầu 3 ngày đến hạn hôm nay, yêu cầu 1 ngày chưa đến hạn.
:::

### TS-09-11 · Gia hạn, sửa, tạm dừng, thu hồi và tự hết hạn chấp thuận

**Mục tiêu.** Xác nhận vòng đời chấp thuận, giới hạn gia hạn, sự kiện đẩy khi tạm dừng hoặc thu hồi và tự hết hạn không gia hạn ngầm.

**Phủ.** FR-09-017; UC-09-11; API-09-067…073; UI-09-08, 09; BR-09-015, 017; ERR-09-006, 007, 031; EVT-09-06…10; NFR-09-025.

#### TC-09-035 · Gia hạn và sửa chấp thuận, tối đa ba lần <!--k:grant-renew-->

::: dac-ta
**Mục đích.** Chứng minh giới hạn `09.grant.renew-max = 3` và gia hạn không vượt trần.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-017 · API-09-069, 070 · ERR-09-031, 030 · BR-09-015 · EVT-09-06.

**Tiền điều kiện, dữ liệu.** T90; chấp thuận G1 đã gia hạn 2 lần; U-T90-DO1.

**Các bước.**

1. DO1 `:renew` G1 thêm 180 ngày (lần 3).
2. DO1 `:renew` G1 lần 4.
3. DO1 `:amend` G1 bớt 1 trường, hạ hạn ngạch.
4. OR1 `POST /access-requests` với `requestKind = RENEWAL`, `renewsGrantId` = chấp thuận `ACTIVE` G3 (cùng HTTT, mục đích).

**Kết quả mong đợi.** Bước 1 `200`, `renewCount = 3`. Bước 2 `422` ERR-09-031 "Chấp thuận đã gia hạn tối đa 3 lần. Lập yêu cầu mới." Bước 3 `200`, EVT: `purpose-grant.approved` (loại sửa), KT: có (grant-amend). Bước 4 `201` `DRAFT`; khi DO duyệt, G3 được gia hạn thay vì tạo chấp thuận mới và `renewCount` tăng 1.
:::

#### TC-09-036 · Tạm dừng và khôi phục, lý do bắt buộc <!--k:grant-suspend-resume-->

::: dac-ta
**Mục đích.** Chứng minh `ACTIVE → SUSPENDED → ACTIVE` và thao tác sai trạng thái bị chặn.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-017 · API-09-071, 072 · ERR-09-007, 006 · EVT-09-07.

**Tiền điều kiện, dữ liệu.** T90; G1 `ACTIVE`; U-T90-DO1.

**Các bước.**

1. DO1 `:suspend` G1 lý do 5 ký tự.
2. DO1 `:suspend` lý do 25 ký tự.
3. DO1 `:suspend` lần hai.
4. DO1 `:resume`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-007. Bước 2 `200`, EVT: `purpose-grant.suspended`. Bước 3 `409` ERR-09-006. Bước 4 `200`, `ACTIVE`, EVT: `purpose-grant.suspended` loại khôi phục.
:::

#### TC-09-037 · Thu hồi chấp thuận, quyết định mục đích chuyển sang từ chối <!--k:grant-revoke-->

::: dac-ta
**Mục đích.** Chứng minh thu hồi có hiệu lực ở điểm thực thi trong 15 giây (BR-09-017); đo chi tiết ở TC-09-135.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-017, 019 · API-09-073, 227 · EVT-09-08 · BR-09-017 · ERR-09-102.

**Tiền điều kiện, dữ liệu.** T90; G1 `ACTIVE`; S-T90-PEP-04 gọi `purpose:decide` 5 lượt mỗi giây; U-T90-DO1.

**Các bước.**

1. PEP gọi liên tục `POST /privacy/v1/purpose:decide` cho G1.
2. DO1 `:revoke` G1 lý do 30 ký tự.
3. Ghi thời điểm lượt `deny` đầu tiên.

**Kết quả mong đợi.** Bước 2 `200`, `REVOKED`, EVT: `purpose-grant.revoked` có trên `t90.privacy.purpose-grant.revoked.v1`, KT: có (grant-revoke). Bước 3 mọi lượt sau 15 giây là `403` ERR-09-102; chấp thuận không `ACTIVE` lại được (thử `:resume` `409` ERR-09-006).
:::

#### TC-09-038 · Tự hết hạn, báo trước 30 ngày, không gia hạn ngầm <!--k:grant-expire-->

::: dac-ta
**Mục đích.** Chứng minh `EXPIRED` tự động và báo trước đúng hạn.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-017 · NFR-09-025 · EVT-09-09, 10 · BR-09-015 · API-09-068.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; chấp thuận G2 hạn sau 31 ngày, `09.grant.expiring-notice-days = 30`.

**Các bước.**

1. Tiến đồng hồ 1 ngày.
2. Tiến đến sau `validTo` 1 phút.
3. Gọi `purpose:decide` cho G2.

**Kết quả mong đợi.** Bước 1 EVT: `purpose-grant.expiring` đúng một lần. Bước 2 điểm thực thi từ chối G2 trong ≤ 60 giây sau `validTo`; `GrantStatus = EXPIRED` trong ≤ 5 phút, EVT: `purpose-grant.expired`. Bước 3 `403` ERR-09-102; không gia hạn tự động.
:::

### TS-09-12 · Bundle OPA ký và phát hành

**Mục tiêu.** Xác nhận dựng, ký, kiểm thử, phát hành và quay lại bundle, OPA từ chối bundle sai chữ ký hoặc quá hạn.

**Phủ.** FR-09-018; UC-09-12; API-09-074…078, 233; UI-09-09; BR-09-018; NFR-09-005, 007, 008, 020; ERR-09-032, 033.

#### TC-09-039 · Đổi chấp thuận kích hoạt dựng, ký và phát hành bundle <!--k:bnd-publish-->

::: dac-ta
**Mục đích.** Chứng minh bundle ký bằng khóa transit không xuất được, có `validUntil` = phát hành + 60 phút và mọi OPA nạp.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-09-018 · API-09-074, 075, 078, 233 · BR-09-018 · EVT-09-11 · NFR-09-005.

**Tiền điều kiện, dữ liệu.** T90; 3 OPA của PH-12 giả lập đăng ký đẩy; `09.bundle.debounce-seconds = 10`, `valid-minutes = 60`.

**Các bước.**

1. Phê duyệt chấp thuận mới.
2. Sau 10 giây `GET /policy-bundles` và `GET /policy-bundles/{id}`.
3. `GET /policy-bundles:sync-status`; `GET /privacy/v1/bundles/current` kèm `If-None-Match`.

**Kết quả mong đợi.** Bước 2 bundle mới `PUBLISHED`, kết quả kiểm thử golden đạt, chữ ký hợp lệ, `validUntil` cách `issuedAt` 60 phút, kích thước ≤ 5 MB. EVT: `bundle.published`. Bước 3 cả 3 OPA có `bundle_loaded`, độ trễ ≤ 60 giây; lần gọi lại cùng `ETag` trả `304`.
:::

#### TC-09-040 · OpenBao ngừng, bộ ca chuẩn không đạt, quay lại bản trước <!--k:bnd-neg-->

::: dac-ta
**Mục đích.** Chứng minh không phát hành bundle chưa ký hoặc không qua kiểm thử, bản cũ vẫn hiệu lực.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-018 · API-09-076, 077 · ERR-09-032, 033 · BR-09-018.

**Tiền điều kiện, dữ liệu.** T94; U-T90-DA1; Rego lỗi cố ý làm 1 trong 300 ca golden sai.

**Các bước.**

1. Ngừng OpenBao rồi `POST /policy-bundles:publish`.
2. Bật lại; phát hành bundle có ca golden sai.
3. DA1 `POST /policy-bundles/{prev}:rollback`.

**Kết quả mong đợi.** Bước 1 `503` ERR-09-032, bundle cũ vẫn hiệu lực. Bước 2 `422` ERR-09-033 nêu ca sai, không phát hành. Bước 3 `200`, EVT: `bundle.published` cho bản được quay lại, KT: có (bundle-rollback).

**Thông báo hiển thị.** "Chưa ký được gói chính sách vì OpenBao không khả dụng. Gói cũ vẫn có hiệu lực."
:::

#### TC-09-041 · OPA từ chối bundle sai chữ ký và quá `validUntil` <!--k:bnd-tamper-->

::: dac-ta
**Mục đích.** Chứng minh OPA không nạp bundle bị sửa và từ chối hợp đồng `SENSITIVE` khi bundle quá hạn.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-09-018 · BR-09-018 · NFR-09-007 · API-09-233.

**Tiền điều kiện, dữ liệu.** T90; bundle đã phát hành; OPA thử.

**Các bước.**

1. Sửa 1 byte của bundle rồi cho OPA nạp.
2. Ngừng PH-09 qua `validUntil`; gọi quyết định cho API-HGD `SENSITIVE`.

**Kết quả mong đợi.** Bước 1 OPA từ chối, giữ bundle cũ, chỉ số `bundle_load_failed` tăng. Bước 2 quyết định `deny` cho `SENSITIVE`; hợp đồng `INTERNAL` vẫn được phục vụ theo bản chụp.
:::

#### TC-09-042 · Tương đương Rego và PH-09 trên 300 ca chuẩn <!--k:bnd-golden-->

::: dac-ta
**Mục đích.** Chứng minh OPA và PH-09 cho kết quả trùng nhau 100 %.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** CT.

**Truy vết.** FR-09-018, 019, 027 · NFR-09-008 · API-09-227, 228.

**Tiền điều kiện, dữ liệu.** T90; golden set 300 ca quyết định và kế hoạch che (Q09-42).

**Các bước.**

1. Chạy bộ golden qua OPA và qua `purpose:decide`, `mask-plans:resolve`.

**Kết quả mong đợi.** 300/300 ca trùng quyết định, mức che và điều kiện; ca lệch làm CI đỏ.
:::

### TS-09-13 · Quyết định mục đích trực tuyến cho điểm thực thi

**Mục tiêu.** Xác nhận quyết định theo mức phân loại, chấp thuận, nhãn bí mật và hạn chế xử lý của chủ thể, mã lỗi data plane và hạn mức gọi.

**Phủ.** FR-09-019; UC-09-13; API-09-227; BR-09-005, 017, 019, 020, 047; ERR-09-101, 102, 103, 104, 111, 113; NFR-09-001, 004, 024.

#### TC-09-043 · Cho phép khi có chấp thuận, điều kiện đi kèm và bỏ qua chấp thuận ở mức thấp <!--k:dec-allow-->

::: dac-ta
**Mục đích.** Chứng minh `SENSITIVE` cần chấp thuận `ACTIVE`, `PUBLIC` và `INTERNAL` chỉ ghi mục đích, `RESTRICTED` cần mục đích thuộc danh mục.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-019 · API-09-227 · BR-09-019 · NFR-09-001.

**Tiền điều kiện, dữ liệu.** T90; G1 `ACTIVE`; API-DM `PUBLIC`; TOPIC-HS-YT `RESTRICTED` (`09.grant.require-restricted = false`); S-T90-PEP-04.

**Các bước.**

1. PEP `POST /privacy/v1/purpose:decide` cho API-HGD, HTTT-BH, `MD-TRACUU-HGD`.
2. Gọi cho API-DM với mục đích tùy ý trong danh mục.
3. Gọi cho TOPIC-HS-YT với `MD-THONGKE`.

**Kết quả mong đợi.** Cả ba `200` `allow`; bước 1 kèm điều kiện (4 trường, hạn ngạch, `NO_EXPORT`); bước 2 chỉ ghi nhận mục đích; lượt `SENSITIVE` và `RESTRICTED` được đếm theo (HTTT, mục đích, hợp đồng).
:::

#### TC-09-044 · Từ chối khi không có chấp thuận, thiếu mục đích, hạn chế chủ thể, nhãn bí mật <!--k:dec-deny-->

::: dac-ta
**Mục đích.** Chứng minh các mã lỗi data plane và ngoại lệ mục đích bắt buộc theo luật khi chủ thể bị hạn chế.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-019 · API-09-227 · ERR-09-102, 103, 104, 101 · BR-09-005, 047.

**Tiền điều kiện, dữ liệu.** T90; HTTT-TK không có chấp thuận; chủ thể CC-03 đang `RESTRICT` (xem TC-09-102); `MD-LUATDINH` bắt buộc theo luật; API có trường nhãn `STATE_SECRET`.

**Các bước.**

1. HTTT-TK gọi API-HGD `SENSITIVE`.
2. Gọi không có `purpose`.
3. HTTT-BH gọi tra CC-03 với `MD-TRACUU-HGD`; rồi với `MD-LUATDINH`.
4. Gọi hợp đồng có trường `STATE_SECRET`.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-102. Bước 2 `400` ERR-09-103. Bước 3 mục đích thường `403` ERR-09-104, mục đích `MD-LUATDINH` `200`. Bước 4 `403` ERR-09-101 không nêu trường.

**Thông báo hiển thị.** "Không có chấp thuận mục đích còn hiệu lực cho yêu cầu này."
:::

#### TC-09-045 · Bên gọi không có scope hoặc vượt hạn mức gọi <!--k:dec-caller-->

::: dac-ta
**Mục đích.** Chứng minh chỉ token dịch vụ có `privacy:decide` gọi được data plane và có giới hạn tốc độ.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-019 · API-09-227 · ERR-09-111, 113 · PERM-09-read.

**Tiền điều kiện, dữ liệu.** T90; S-T90-NOSCOPE; S-T90-PEP-04; `09.api.rate-du-per-sec = 2.000` lượt mỗi giây mỗi DU.

**Các bước.**

1. S-T90-NOSCOPE gọi `purpose:decide`.
2. Người dùng U-T90-TA gọi `purpose:decide` bằng token người dùng.
3. S-T90-PEP-04 gọi vượt 2.000 lượt mỗi giây trong 5 giây.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-111. Bước 2 `403` ERR-09-111. Bước 3 phần vượt nhận `429` ERR-09-113 kèm `Retry-After`; lượt trong hạn vẫn `200`.
:::

#### TC-09-046 · Vượt hạn ngạch ngày và vượt trường được phép sinh cảnh báo <!--k:dec-bulk-anomaly-->

::: dac-ta
**Mục đích.** Chứng minh đếm lượt và cảnh báo trong 5 phút khi vượt hạn ngạch hoặc ngoài trường được phép.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-019, 020 · NFR-09-026 · API-09-227, 237 · BR-09-020 · EVT-09-13.

**Tiền điều kiện, dữ liệu.** T90; G1 hạn ngạch 2.000 lượt mỗi ngày; PEP báo lượt qua `usage-events:report`.

**Các bước.**

1. PEP báo 2.100 lượt trong ngày, trong đó 10 lượt đọc trường ngoài 4 trường cho phép.
2. Chờ ≤ 5 phút; `GET /usage-anomalies`.

**Kết quả mong đợi.** Có cảnh báo `QUOTA_EXCEEDED` và `OFF_PURPOSE` gắn G1; EVT: `usage.anomaly-detected`; `09.anomaly.auto-suspend = false` nên chấp thuận không đổi trạng thái. Cảnh báo tới DO và SO ≤ 5 phút sau lượt vượt (NFR-09-026).
:::

#### TC-09-047 · Quyết định p95 ≤ 20 ms ở điểm thực thi, 5.000 yêu cầu mỗi giây toàn cụm <!--k:dec-latency-->

::: dac-ta
**Mục đích.** Đo NFR-09-001 và NFR-09-004.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-09-001, 004 · API-09-227.

**Tiền điều kiện, dữ liệu.** T97; hồ sơ tỉnh vừa, 3 bản sao data plane; PEP có đệm.

**Các bước.**

1. k6 1.000 lượt mỗi giây 15 phút qua PEP có đệm, rồi gọi trực tiếp `purpose:decide`.
2. Tăng lên 5.000 lượt mỗi giây toàn cụm 30 phút.

**Kết quả mong đợi.** PEP có đệm p95 ≤ 20 ms (trúng đệm ≤ 2 ms); gọi trực tiếp p95 ≤ 50 ms, p99 ≤ 100 ms. Ở 5.000 lượt mỗi giây độ trễ tăng không quá 20 %, 0 lỗi `5xx`.
:::

### TS-09-14 · Phát hiện khai thác bất thường và báo cáo theo mục đích

**Mục tiêu.** Xác nhận cảnh báo, xử lý cảnh báo (ghi nhận, loại trừ, chuyển vụ việc), ngưỡng, báo cáo theo mục đích và xuất.

**Phủ.** FR-09-020, 021; UC-09-14; API-09-079…087, 237; UI-09-01, 09; BR-09-020; ERR-09-034, 036, 007; NFR-09-026.

#### TC-09-048 · Ghi nhận, loại trừ và chuyển cảnh báo thành vụ việc vi phạm <!--k:ano-handle-->

::: dac-ta
**Mục đích.** Chứng minh vòng đời cảnh báo `OPEN → ACKNOWLEDGED, DISMISSED, ESCALATED`.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-020 · API-09-079…083 · UI-09-09 · EVT-09-13 · PERM-09-breach.

**Tiền điều kiện, dữ liệu.** T90; ba cảnh báo `OPEN` (`BULK_ACCESS`, `OFF_HOURS`, `DORMANT_REUSE`); U-T90-DO1, U-T90-SO.

**Các bước.**

1. DO1 `:acknowledge` cảnh báo 1; `:dismiss` cảnh báo 2 kèm lý do 25 ký tự.
2. SO `:escalate` cảnh báo 3.
3. `GET /breaches`.

**Kết quả mong đợi.** Cảnh báo lần lượt `ACKNOWLEDGED`, `DISMISSED`, `ESCALATED`; có vụ việc `REPORTED` nguồn `ANOMALY` với `detectedAt` là thời điểm cảnh báo; KT: có cho từng thao tác.
:::

#### TC-09-049 · Ngưỡng cảnh báo ngoài miền và loại trừ không lý do <!--k:ano-rules-neg-->

::: dac-ta
**Mục đích.** Chứng minh kiểm miền ngưỡng cảnh báo và lý do loại trừ.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-020 · API-09-085, 082 · ERR-09-034, 007, 078.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA, U-T90-DO1.

**Các bước.**

1. TA `PUT /anomaly-rules` đặt `quota-warn-percent = 99`.
2. TA đặt `bulk-threshold = 50`.
3. DO1 `:dismiss` không lý do.

**Kết quả mong đợi.** Bước 1 và 2 `422` ERR-09-034 (hoặc ERR-09-078 theo miền `50…95`, `100…100.000`). Bước 3 `422` ERR-09-007.

**Thông báo hiển thị.** "Ngưỡng cảnh báo không hợp lệ."
:::

#### TC-09-050 · Báo cáo khai thác theo mục đích, giới hạn 12 tháng, xuất nền <!--k:rpt-usage-->

::: dac-ta
**Mục đích.** Chứng minh báo cáo theo (HTTT, mục đích, hợp đồng) và giới hạn khoảng thời gian.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-021 · API-09-086, 087 · ERR-09-036 · UI-09-01.

**Tiền điều kiện, dữ liệu.** T90; 3 tháng dữ liệu lượt khai thác; U-T90-SO.

**Các bước.**

1. SO `GET /usage-reports?from=2026-09-01&to=2026-11-25`.
2. Đặt khoảng 14 tháng.
3. `POST /usage-reports:export`.

**Kết quả mong đợi.** Bước 1 tổng lượt khớp số báo cáo của PEP. Bước 2 `422` ERR-09-036 "Chọn khoảng thời gian tối đa 12 tháng." Bước 3 `202`, tệp không chứa giá trị DLCN.
:::

### TS-09-15 · Chặn kích hoạt hợp đồng mức Nhạy cảm

**Mục tiêu.** Xác nhận PH-02 và PH-04 không kích hoạt hợp đồng chứa dữ liệu Nhạy cảm khi chưa có mục đích và chấp thuận, kể cả hợp đồng mức tạm thời.

**Phủ.** FR-09-022; UC-09-15; API-09-088, 089; UI-09-09, 02; BR-09-001, 008, 019; ERR-09-035, 023; SEC-37.

#### TC-09-051 · Kích hoạt hợp đồng `SENSITIVE` khi chưa có chấp thuận bị chặn <!--k:act-block-->

::: dac-ta
**Mục đích.** Chứng minh kiểm điều kiện kích hoạt theo SEC-37.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-022 · API-09-088, 089 · ERR-09-035, 023 · BR-09-019, 008 · UI-09-09.

**Tiền điều kiện, dữ liệu.** T90; API-HGD mức `SENSITIVE` chưa có chấp thuận; 1 trường DLCN chưa thuộc hoạt động; S-T90-REG (vai PH-02).

**Các bước.**

1. S-T90-REG `POST /activation-checks` cho API-HGD.
2. `GET /activation-checks:blocked`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-035 nêu "cần mục đích và chấp thuận của chủ quản" và ERR-09-023 nêu số trường chưa thuộc hoạt động; PH-02 không chuyển `ACTIVE`. Bước 2 liệt kê API-HGD kèm lý do chặn.

**Thông báo hiển thị.** "Hợp đồng API-HGD chứa dữ liệu Nhạy cảm, cần mục đích và chấp thuận của chủ quản trước khi kích hoạt."
:::

#### TC-09-052 · Kích hoạt được sau khi có chấp thuận và hoạt động <!--k:act-pass-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện được gỡ khi đủ chấp thuận và hoạt động xử lý.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-022 · API-09-088 · BR-09-019, 008.

**Tiền điều kiện, dữ liệu.** T90; sau ca dec-approve-cond và ropa-link.

**Các bước.**

1. S-T90-REG `POST /activation-checks` cho API-HGD.

**Kết quả mong đợi.** `200` `allowed = true`, không còn trong `activation-checks:blocked`.
:::

#### TC-09-053 · Hợp đồng mức tạm thời vẫn bị chặn <!--k:act-provisional-->

::: dac-ta
**Mục đích.** Chứng minh mức tạm thời `SENSITIVE` (BR-09-001) chưa cho kích hoạt khi thiếu chấp thuận.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-022 · API-09-088 · BR-09-001 · ERR-09-035.

**Tiền điều kiện, dữ liệu.** T90; API-MOI có trường chưa phân loại; có chấp thuận cho API-HGD khác.

**Các bước.**

1. S-T90-REG `POST /activation-checks` cho API-MOI.

**Kết quả mong đợi.** `422` ERR-09-035; sau khi xác nhận trường là `INTERNAL` thì lượt kiểm lại `200`.
:::

### TS-09-16 · Kiểu che và chính sách che

**Mục tiêu.** Xác nhận kiểu che chuẩn, mẫu che, soạn chính sách theo mức, loại DLCN, vai trò, mục đích, kênh và thứ tự ưu tiên.

**Phủ.** FR-09-023, 024; UC-09-16; API-09-090…095; UI-09-10; BR-09-021, 022, 024; ERR-09-037, 038; LGC-TOOL-012.

#### TC-09-054 · Mẫu che chuẩn cho số định danh, điện thoại, thư điện tử, ngày sinh, họ tên, địa chỉ <!--k:mask-types-->

::: dac-ta
**Mục đích.** Chứng minh bộ mẫu chuẩn thay bốn chế độ cũ `none`, `mask`, `pseudonymize`, `anonymize` bằng `MaskType`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-023 · API-09-090, 091 · UI-09-10 · BR-09-021 · LGC-TOOL-012.

**Tiền điều kiện, dữ liệu.** T90; U-T90-SO.

**Các bước.**

1. SO `GET /mask-types`.
2. SO `PUT /mask-types/NATIONAL_ID/patterns` đổi `keep-last-3` thành `keep-last-4`.

**Kết quả mong đợi.** Bước 1 có bảy `MaskType` và mẫu `keep-last-3` (số định danh), `keep-first-3-last-2` (điện thoại), `keep-first-1-domain` (thư điện tử), `year-only` (ngày sinh), `keep-first-token` (họ tên), `admin-level` huyện (địa chỉ), kèm ví dụ trước và sau. Bước 2 `200`; chính sách `ACTIVE` không đổi, mẫu chỉ áp cho phiên bản kế tiếp.
:::

#### TC-09-055 · Soạn chính sách che có quy tắc cụ thể hơn thắng quy tắc chung <!--k:mask-policy-create-->

::: dac-ta
**Mục đích.** Chứng minh thứ tự (loại DLCN, vai trò, mục đích, kênh, mức) và trùng ưu tiên thì kiểu che chặt hơn thắng.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-024 · API-09-093, 094, 095 · BR-09-022, 024 · UI-09-10.

**Tiền điều kiện, dữ liệu.** T90; U-T90-DS1 (`PERM-09-policy` theo tổ chức).

**Các bước.**

1. DS1 `POST /mask-policies` bản nháp với quy tắc chung `SENSITIVE → REPLACE`, quy tắc riêng `NATIONAL_ID`, vai trò `ROLE-DATA_STEWARD`, kênh `UI` → `PARTIAL keep-last-3`.
2. `PUT /mask-policies/{id}/versions/1` thêm hai quy tắc cùng độ ưu tiên `PARTIAL` và `DROP` cho điện thoại.
3. Mô phỏng ở TC-09-057.

**Kết quả mong đợi.** Bước 1 `201`, `DRAFT`. Bước 2 lưu được; khi áp, cùng ưu tiên chọn `DROP` (chặt hơn); `DROP` chỉ dùng khi chính sự tồn tại của trường là thông tin nhạy cảm (BR-09-024), còn bên nhận cần đối chiếu thì dùng `PARTIAL`. Mặc định theo BR-09-021: `SENSITIVE` che, `RESTRICTED` che một phần theo vai trò, `INTERNAL` và `PUBLIC` giữ nguyên.
:::

#### TC-09-056 · Kiểu che không hợp kiểu dữ liệu, trùng ưu tiên, thiếu quy tắc mặc định <!--k:mask-policy-neg-->

::: dac-ta
**Mục đích.** Chứng minh kiểm hợp lệ kiểu che ở cả mẫu và chính sách.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-023, 024 · API-09-091, 095 · ERR-09-037, 038.

**Tiền điều kiện, dữ liệu.** T90; U-T90-SO.

**Các bước.**

1. SO đặt `YEAR_ONLY` cho trường `email`.
2. SO lưu phiên bản có hai quy tắc cùng ưu tiên cùng kiểu che.
3. SO lưu phiên bản không có quy tắc mặc định cho mức `SENSITIVE`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-037. Bước 2 và 3 `422` ERR-09-038.

**Thông báo hiển thị.** "Chính sách có quy tắc trùng ưu tiên hoặc thiếu quy tắc mặc định cho mức Nhạy cảm."
:::

### TS-09-17 · Mô phỏng, duyệt và phát hành chính sách che

**Mục tiêu.** Xác nhận mô phỏng trên dữ liệu mẫu, điều kiện mô phỏng đạt trước khi gửi duyệt, duyệt bốn mắt, phiên bản, so sánh và quay lại.

**Phủ.** FR-09-025, 026; UC-09-17; API-09-096…101; UI-09-10, 11; BR-09-023, 025; ERR-09-039, 040, 080, 005.

#### TC-09-057 · Mô phỏng che trên mẫu F-SIM theo vai trò, mục đích, kênh <!--k:mask-sim-->

::: dac-ta
**Mục đích.** Chứng minh kết quả xem trước đúng mẫu che và dữ liệu mẫu không bị ghi lại.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-025 · API-09-101 · UI-09-11 · BR-09-025 · LGC-TOOL-012.

**Tiền điều kiện, dữ liệu.** T90; F-SIM 1.000 dòng (CCCD `001090000101`, điện thoại `0912345678`, thư `an.nguyen@example.test`, sinh `1990-03-12`); chính sách nháp của ca mask-policy-create.

**Các bước.**

1. DS1 `POST /mask-simulations` vai `ROLE-DATA_STEWARD`, mục đích `MD-TRACUU-HGD`, kênh `UI`.
2. Gọi lại với kênh `EXPORT` và vai `ROLE-VIEWER`.

**Kết quả mong đợi.** Bước 1 CCCD `*********101`, điện thoại `091*****78`, thư `a***@example.test`, ngày sinh `1990`, họ tên giữ họ. Bước 2 theo quy tắc kênh `EXPORT` chặt hơn. Mồi sạch với dữ liệu mẫu trong log và bảng `ph09_privacy.*` sau khi xong; 1.000 dòng ≤ 5 giây (NFR-09-023).
:::

#### TC-09-058 · Mẫu quá 1.000 dòng, gửi duyệt khi chưa mô phỏng đạt <!--k:mask-sim-neg-->

::: dac-ta
**Mục đích.** Chứng minh giới hạn mẫu và điều kiện mô phỏng đạt (BR-09-023).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-025, 026 · API-09-101, 096 · ERR-09-039, 040, 080 · BR-09-023.

**Tiền điều kiện, dữ liệu.** T90; U-T90-DS1; tệp 1.001 dòng.

**Các bước.**

1. DS1 `POST /mask-simulations` với 1.001 dòng.
2. DS1 `:submit` phiên bản chưa có mô phỏng đạt.
3. DS1 gửi mẫu có số định danh đúng kiểm tổng ngoài miền giả (giá trị lấy từ kho dữ liệu thử, không ghi trong tài liệu).

**Kết quả mong đợi.** Bước 1 `413` ERR-09-039. Bước 2 `422` ERR-09-040. Bước 3 `422` ERR-09-080 "Dữ liệu mẫu có dấu hiệu là dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."

**Thông báo hiển thị.** "Dữ liệu mẫu tối đa 1.000 dòng." và "Cần mô phỏng đạt trên bộ dữ liệu mẫu trước khi gửi duyệt."
:::

#### TC-09-059 · Duyệt bốn mắt, kích hoạt, so sánh và quay lại phiên bản <!--k:mask-approve-->

::: dac-ta
**Mục đích.** Chứng minh người soạn không duyệt dù có đủ quyền và phát hành đổi kế hoạch che.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-026 · API-09-097, 098, 099, 100 · ERR-09-005 · EVT-09-12 · BR-09-023.

**Tiền điều kiện, dữ liệu.** T90; phiên bản 2 đã mô phỏng đạt; U-T90-DS1 (soạn), U-T90-DA1; TA có cả `PERM-09-policy` và `PERM-09-policy-approve`.

**Các bước.**

1. DS1 `:submit` rồi tự `:approve`; TA là người soạn cũng tự `:approve`.
2. DA1 `:approve`.
3. `GET .../versions/2/diff`; DA1 `POST /mask-policies/{id}:rollback`.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-005 cho cả hai. Bước 2 `ACTIVE`, bản 1 `SUPERSEDED`, EVT: `mask-policy.activated`, KT: có (mask-policy-approve). Bước 3 diff liệt kê quy tắc đổi; quay lại tạo bản 3 giống bản 1, EVT: `mask-policy.activated`.
:::

### TS-09-18 · Kế hoạch che trực tuyến, đệm và đóng an toàn

**Mục tiêu.** Xác nhận kế hoạch che theo chủ thể, mục đích, kênh, `ETag`, đệm 300 giây và hành vi khi PH-09 không có kế hoạch.

**Phủ.** FR-09-027; UC-09-18; API-09-228, 232; BR-09-001, 022, 027; ERR-09-105, 111; NFR-09-002, 007.

#### TC-09-060 · Kế hoạch che đúng thứ tự ưu tiên, `304` khi không đổi, trường chưa phân loại như `SENSITIVE` <!--k:plan-resolve-->

::: dac-ta
**Mục đích.** Chứng minh PEP nhận kế hoạch đủ `{planVersion, ttlSeconds, fields, failMode}` và dùng đệm.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-027 · API-09-228, 232 · BR-09-022, 001 · NFR-09-002.

**Tiền điều kiện, dữ liệu.** T90; chính sách ACTIVE của ca mask-approve; S-T90-PEP-04; phần tử `ghiChu` chưa phân loại.

**Các bước.**

1. PEP `POST /privacy/v1/mask-plans:resolve` (`roles`, `purpose`, `channel`, 200 trường) kèm `If-None-Match` trống.
2. Lặp lại với `ETag` vừa nhận.
3. `GET /privacy/v1/classification-index`.

**Kết quả mong đợi.** Bước 1 `200`, trường `cccd` `PARTIAL`, `ghiChu` mức `SENSITIVE` che mặc định, `neverReveal` đúng cờ. Bước 2 `304`. Bước 3 trả `ETag`; p95 trực tiếp ≤ 50 ms, trúng đệm ≤ 2 ms.
:::

#### TC-09-061 · PH-09 mất kết nối: dùng đệm tối đa 5 phút rồi đóng an toàn <!--k:plan-failsafe-->

::: dac-ta
**Mục đích.** Chứng minh đóng an toàn: luồng từ chối, đọc chỉ trả trường `PUBLIC`.

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-09-027, 028 · BR-09-027 · ERR-09-105 · NFR-09-007 · API-09-228.

**Tiền điều kiện, dữ liệu.** T94; PEP-04 luồng và PEP-06 đọc; `09.plan.cache-seconds = 300`.

**Các bước.**

1. Chạy bình thường 1 phút để đệm đầy; ngắt PH-09.
2. Trong 5 phút gọi đọc và chạy luồng với kế hoạch đã đệm.
3. Sau 5 phút gọi lại.

**Kết quả mong đợi.** Bước 2 vẫn che đúng theo bản chụp. Bước 3 luồng bị từ chối ERR-09-105 "Chưa lập được kế hoạch che, đang dùng chế độ đóng an toàn."; điểm đọc trả chỉ trường `PUBLIC` kèm `X-Datahub-Masking: fallback`; không bản tin nào đi qua chưa che. Khi PH-09 hồi phục PEP tự dùng lại kế hoạch mới.
:::

#### TC-09-062 · Bên gọi không phép và đệm bị xóa khi chính sách đổi <!--k:plan-neg-->

::: dac-ta
**Mục đích.** Chứng minh PEP xóa đệm khi nhận sự kiện đổi chính sách hoặc phân loại.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-027 · API-09-228 · ERR-09-111 · EVT-09-12, 01.

**Tiền điều kiện, dữ liệu.** T90; S-T90-NOSCOPE; PEP có đệm.

**Các bước.**

1. S-T90-NOSCOPE gọi `mask-plans:resolve`.
2. Kích hoạt chính sách mới rồi gọi lại qua PEP đang có đệm.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-111. Bước 2 PEP xóa đệm khi nhận EVT-09-12 và dùng `planVersion` mới trong ≤ 15 giây.
:::

### TS-09-19 · Áp che bản tin cho luồng PH-04

**Mục tiêu.** Xác nhận áp che từng kiểu, chặn bản tin có nhãn, giới hạn bản tin, giả danh hóa trong luồng và ghi vết thao tác che.

**Phủ.** FR-09-028; UC-09-19; API-09-229, 231; BR-09-005, 025; ERR-09-106…110; NFR-09-003; LGC-TOOL-012.

#### TC-09-063 · Áp che PARTIAL, REPLACE, KEYED_HASH, TOKENIZE, GENERALIZE, DROP <!--k:apply-kinds-->

::: dac-ta
**Mục đích.** Chứng minh bản tin đầu ra đúng từng kiểu che và không còn giá trị rõ.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-028 · API-09-229 · BR-09-025 · NFR-09-003 · LGC-TOOL-012.

**Tiền điều kiện, dữ liệu.** T90; S-T90-APPLY-04; bản tin F-MSG 10 KB 8 trường; miền giả danh `PD-HGD` (HMAC) và `PD-TOKEN` (token); chính sách mỗi trường một kiểu.

**Các bước.**

1. PEP `POST /privacy/v1/messages:apply` với F-MSG, kênh `FLOW`.
2. So từng trường đầu ra với bản tin gốc.

**Kết quả mong đợi.** `200`; `cccd` `*********101` (PARTIAL), `soDienThoai` thay `[REDACTED]` (REPLACE), `maBenhAn` bí danh HMAC ổn định (KEYED_HASH), `soTaiKhoan` token (TOKENIZE), `ngaySinh` `1990` (GENERALIZE), `ghiChu` bị loại (DROP). Mồi sạch với canary trong `maBenhAn`; KT: có tổng hợp theo kênh.
:::

#### TC-09-064 · Bản tin có trường nhãn bí mật bị chặn, không trả trường nào <!--k:apply-block-->

::: dac-ta
**Mục đích.** Chứng minh `messages:apply` chặn toàn bản tin như `classification:check`.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-028, 007 · API-09-229 · BR-09-005 · ERR-09-101 · EVT-09-14.

**Tiền điều kiện, dữ liệu.** T90; nhãn trên `soHieuMat`; S-T90-APPLY-04.

**Các bước.**

1. PEP `POST /privacy/v1/messages:apply` với F-MSG có `soHieuMat`.

**Kết quả mong đợi.** `403` ERR-09-101, thân không có trường dữ liệu và không nêu trường nhãn; EVT: `secret-label.blocked`.
:::

#### TC-09-065 · Sai lược đồ, bản tin quá lớn, miền giả danh không hoạt động <!--k:apply-neg-->

::: dac-ta
**Mục đích.** Chứng minh lỗi data plane phân biệt rõ nguồn.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-028 · API-09-229 · ERR-09-106, 107, 109.

**Tiền điều kiện, dữ liệu.** T90; `PD-HGD` ở `SUSPENDED`; S-T90-APPLY-04.

**Các bước.**

1. Gửi thân thiếu `channel`.
2. Gửi bản tin 2 MB (vượt giới hạn 1 MiB của ERR-09-107).
3. Gửi bản tin có trường giả danh theo `PD-HGD`.

**Kết quả mong đợi.** Bước 1 `400` ERR-09-106. Bước 2 `413` ERR-09-107. Bước 3 `422` ERR-09-109, không bản tin nào trả giá trị rõ.
:::

#### TC-09-066 · OpenBao hoặc nhật ký che ngừng: không băm, không token hóa, từ chối <!--k:apply-dep-fail-->

::: dac-ta
**Mục đích.** Chứng minh không trả dữ liệu thô khi hạ tầng khóa hoặc kiểm toán không dùng được.

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-09-028 · API-09-229 · ERR-09-108, 110 · BR-09-057.

**Tiền điều kiện, dữ liệu.** T94; S-T90-APPLY-04; bản tin có trường `KEYED_HASH`.

**Các bước.**

1. Ngừng OpenBao rồi gọi `messages:apply`.
2. Bật OpenBao, ngừng ghi nhật ký che; gọi lại.

**Kết quả mong đợi.** Bước 1 `503` ERR-09-108, không trường rõ nào trong thân. Bước 2 `503` ERR-09-110, thao tác bị từ chối. Mồi sạch.
:::

#### TC-09-067 · Áp che bản tin 10 KB p95 ≤ 30 ms, có băm hoặc token p95 ≤ 80 ms <!--k:apply-latency-->

::: dac-ta
**Mục đích.** Đo NFR-09-003.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-09-003 · API-09-229.

**Tiền điều kiện, dữ liệu.** T97; 3 bản sao.

**Các bước.**

1. k6 500 lượt mỗi giây 15 phút, bản tin 10 KB không băm có khóa; rồi lô token 500 giá trị.

**Kết quả mong đợi.** p95 ≤ 30 ms (không băm) và p95 ≤ 80 ms (băm hoặc token hóa theo lô), 0 lỗi `5xx`.
:::

### TS-09-20 · Xem giá trị đầy đủ có lý do trong 60 giây

**Mục tiêu.** Xác nhận cấp phiếu xem đầy đủ, giới hạn lần, trường cấm xem, hết hạn đúng 60 giây và ghi vết trước khi cấp.

**Phủ.** FR-09-029; UC-09-20; API-09-102, 103, 236, 241; UI-09-22, 20; BR-09-026, 057; ERR-09-007, 010, 041, 042, 043, 112; NFR-09-015.

#### TC-09-068 · Cấp phiếu, xác thực phiếu, giá trị tự che sau 60 giây <!--k:rev-grant-->

::: dac-ta
**Mục đích.** Chứng minh phiếu hết hạn sau `09.mask.reveal-seconds = 60` và PH-09 không thấy giá trị.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-029 · API-09-102, 236, 241 · UI-09-22 · BR-09-026 · NFR-09-015 · PERM-09-unmask.

**Tiền điều kiện, dữ liệu.** T90; U-T90-SO có `PERM-09-unmask`, U-T90-AU; trường `cccd` ở UI của PH-06 giả lập; canary `DH-CANARY-rev-grant`.

**Các bước.**

1. Trên UI-09-22 SO nhập lý do 30 ký tự, bấm xem.
2. DU gọi `POST /privacy/v1/reveal-grants/{gid}:verify` trong 30 giây.
3. Quan sát đồng hồ đếm ngược; gọi `:verify` lại sau 61 giây.
4. AU `GET /reveal-grants/{grantId}`.

**Kết quả mong đợi.** Bước 1 `201` `{grantId, expiresAt, serverTime, remainingThisHour}` (`remainingThisHour` = 20 trừ số lần đã cấp trong giờ), KT: có ghi trước khi cấp. Bước 2 `200`. Bước 3 giá trị tự che lại; `:verify` `403` ERR-09-112. Giá trị rõ không có trong log, bảng `ph09_privacy.*`, đĩa. Bước 4 `200`, thấy người xem, trường, lý do, hết hạn, trạng thái; không có `value`.
:::

#### TC-09-069 · Thiếu quyền, lý do ngắn, trường cấm xem, vượt 20 lần mỗi giờ <!--k:rev-neg-->

::: dac-ta
**Mục đích.** Chứng minh BR-09-026 từng điều kiện.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-029 · API-09-102 · ERR-09-041, 007, 042, 043 · BR-09-026.

**Tiền điều kiện, dữ liệu.** T92 `09.mask.reveal-max-per-hour = 3`; trường `matKhau` đặt `neverReveal`; U-T90-DS1 (không quyền), U-T90-SO.

**Các bước.**

1. DS1 `POST /reveal-grants`.
2. SO gửi lý do 10 ký tự.
3. SO xin xem `matKhau`.
4. SO xin xem 4 lần liên tiếp với lý do hợp lệ.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-041. Bước 2 `422` ERR-09-007. Bước 3 `422` ERR-09-042. Bước 4 lần thứ 4 `429` ERR-09-043.

**Thông báo hiển thị.** "Đã vượt số lần xem giá trị đầy đủ trong giờ. Thử lại sau."
:::

#### TC-09-070 · Không ghi được kiểm toán thì không cấp phiếu <!--k:rev-audit-fail-->

::: dac-ta
**Mục đích.** Chứng minh ghi vết trước khi cấp, không cấp khi không ghi được.

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-09-029 · BR-09-057 · ERR-09-010 · API-09-102.

**Tiền điều kiện, dữ liệu.** T94; PH-13 giả lập `503`; U-T90-SO.

**Các bước.**

1. SO `POST /reveal-grants` khi PH-13 ngừng.

**Kết quả mong đợi.** `503` ERR-09-010, không có `RevealGrant` mới; giao diện thông báo từ chối.
:::

#### TC-09-071 · Lịch sử xem đầy đủ, tách quyền xem và quyền xem lịch sử <!--k:rev-history-->

::: dac-ta
**Mục đích.** Chứng minh lịch sử đủ lượt và tín hiệu bất thường.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-029 · API-09-103 · UI-09-20 · PERM-09-audit-read · EVT-09-15.

**Tiền điều kiện, dữ liệu.** T90; 25 lượt xem của SO trong 1 giờ ở T95; U-T90-AU, U-T90-SO.

**Các bước.**

1. AU `GET /reveal-grants`.
2. SO `GET /reveal-grants`.

**Kết quả mong đợi.** Bước 1 `200`, đủ lượt (người, đối tượng, trường, lý do, hết hạn), EVT: `reveal.granted` khi vượt ngưỡng bất thường. Bước 2 ERR-00-403.
:::

### TS-09-21 · Che log, trace và quét rò rỉ DLCN trong log

**Mục tiêu.** Xác nhận cấu hình che log, quét rò rỉ, xử lý kết quả và log không chứa DLCN rõ.

**Phủ.** FR-09-030; UC-09-21; API-09-104…108; UI-09-10, 01; BR-09-025, 058; ERR-09-044; NFR-09-014.

#### TC-09-072 · Đặt cấu hình che log rồi quét thấy canary rò rỉ <!--k:log-config-scan-->

::: dac-ta
**Mục đích.** Chứng minh quét phát hiện rò rỉ và kết quả không chứa giá trị rõ.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-09-030 · API-09-105, 106, 107, 108 · UI-09-10 · BR-09-025 · NFR-09-014.

**Tiền điều kiện, dữ liệu.** T90; F-LOG log 5 phút có `DH-CANARY-log-scan` và CCCD giả ở dạng rõ; U-T90-SO.

**Các bước.**

1. SO `PUT /log-masking-config` mức `SENSITIVE` ghi `[REDACTED]`.
2. `POST /leak-scans`; `GET /leak-findings`.
3. SO `POST /leak-findings/{id}:resolve` với `resolution = FIXED`.

**Kết quả mong đợi.** Bước 2 có kết quả chỉ tên trường, dịch vụ, thời điểm; không giá trị rõ; thẻ UI-09-01 tăng. Bước 3 kết quả không còn `OPEN`, có người xử lý và thời điểm xử lý, KT: có.
:::

#### TC-09-073 · Cấu hình che log không hợp lệ <!--k:log-config-neg-->

::: dac-ta
**Mục đích.** Chứng minh không cho phép tắt che mức `SENSITIVE` ở log.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-030 · API-09-105 · ERR-09-044.

**Tiền điều kiện, dữ liệu.** T90; U-T90-SO.

**Các bước.**

1. SO đặt mức `SENSITIVE` ghi giá trị rõ ở kênh `LOG`.

**Kết quả mong đợi.** `422` ERR-09-044 nêu lý do; cấu hình cũ giữ.
:::

#### TC-09-074 · Quét canary toàn hệ không thấy DLCN ở log, trace, topic <!--k:log-canary-sweep-->

::: dac-ta
**Mục đích.** Chứng minh 0 giá trị `SENSITIVE` dạng rõ ngoài phiếu xem (NFR-09-014).

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP.

**Truy vết.** NFR-09-014 · BR-09-025, 058 · FR-09-030.

**Tiền điều kiện, dữ liệu.** T90; canary đặt vào trường `SENSITIVE` của mọi ca ghi ở TS-09-01…34.

**Các bước.**

1. Chạy bộ quét canary sau khi chạy toàn bộ mục 4.

**Kết quả mong đợi.** 0 lần xuất hiện ở log 24 giờ, vết OTel, mọi topic `t90.privacy.*`, outbox, bảng `ph09_privacy.*`, tệp xuất.
:::

### TS-09-22 · Miền giả danh hóa và vòng đời khóa

**Mục tiêu.** Xác nhận tạo miền theo tenant và mục đích, xoay, ngừng, hủy khóa có hai người và chờ, không hủy khi còn dùng.

**Phủ.** FR-09-031, 034; UC-09-22; API-09-109…118; UI-09-12; BR-09-028, 029, 031, 033; ERR-09-045, 046, 047, 005.

#### TC-09-075 · Tạo miền HMAC và miền token kèm khóa đầu <!--k:pd-create-->

::: dac-ta
**Mục đích.** Chứng minh khóa riêng theo tenant và theo mục đích để hai tập không nối được (BR-09-028).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-031 · API-09-110, 111, 109 · UI-09-12 · BR-09-028.

**Tiền điều kiện, dữ liệu.** T90; U-T90-SO, U-T90-TA; OpenBao transit.

**Các bước.**

1. TA `POST /pseudonym-domains` `PD-HGD` (`HMAC_SHA256`, `NATIONAL_ID`, mục đích `MD-TRACUU-HGD`).
2. Tạo `PD-TK` (`MD-THONGKE`) và `PD-TOKEN` (`TOKEN_TRANSIT`).
3. `GET /pseudonym-domains/PD-HGD/keys`.

**Kết quả mong đợi.** Bước 1 và 2 `201`, mỗi miền có khóa `ACTIVE` phiên bản 1 trong OpenBao, KT: có. Bước 3 không có giá trị khóa; tên khóa mang mã tenant. Tạo `PD-HGD` lần hai `409` ERR-09-045.
:::

#### TC-09-076 · Xoay khóa cảnh báo mất nhất quán, giãn cách tối thiểu <!--k:pd-rotate-->

::: dac-ta
**Mục đích.** Chứng minh xoay giữ khóa cũ ở `DECRYPT_ONLY` và chặn xoay quá gần.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-034 · API-09-116, 115 · ERR-09-047 · BR-09-029, 033 · EVT-09-16 · PERM-09-policy-approve.

**Tiền điều kiện, dữ liệu.** T90; `PD-HGD` khóa v1 vừa tạo; `09.pseudo.min-rotate-days = 30`; U-T90-DA1.

**Các bước.**

1. DA1 `POST /pseudonym-domains/PD-HGD/keys:rotate` với `confirmInconsistency = false`.
2. DA1 xoay lại kèm `confirmInconsistency = true`.
3. DA1 xoay lần hai ngay.

**Kết quả mong đợi.** Bước 1 từ chối `422` ERR-09-003 kèm cảnh báo bí danh đổi. Bước 2 `200`, v2 `ACTIVE`, v1 `DECRYPT_ONLY`, EVT: `pseudonym-key.state-changed`. Bước 3 `409` ERR-09-047 nêu số ngày chờ.
:::

#### TC-09-077 · Hủy khóa: chặn khi còn dùng, hai người duyệt, chờ trước khi hủy <!--k:pd-destroy-->

::: dac-ta
**Mục đích.** Chứng minh BR-09-033.

**Loại.** Âm, Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-034 · API-09-117, 118 · ERR-09-046, 005 · BR-09-033.

**Tiền điều kiện, dữ liệu.** T90; khóa v1 còn dữ liệu giải được; `09.pseudo.destroy-delay-days = 30`; U-T90-TA, U-T90-DA1.

**Các bước.**

1. TA `POST /pseudonym-keys/{v1}:disable`; rồi `:destroy` khi còn dữ liệu dùng khóa v1.
2. Sau khi không còn dữ liệu, TA `:destroy`; TA tự duyệt.
3. DA1 duyệt; tiến đồng hồ 30 ngày.

**Kết quả mong đợi.** Bước 1 `:disable` `200` (`DISABLED`), `:destroy` `409` ERR-09-046. Bước 2 tự duyệt `403` ERR-09-005. Bước 3 sau 30 ngày `DESTROYED`, EVT: `pseudonym-key.state-changed`, KT: có (key-destroy).
:::

### TS-09-23 · Giả danh hóa giá trị bằng HMAC hoặc token

**Mục tiêu.** Xác nhận bí danh nhất quán, khác nhau giữa các miền, token đảo ngược, không lưu bảng ánh xạ.

**Phủ.** FR-09-032; UC-09-23; API-09-230; BR-09-028, 029, 030; ERR-09-108, 109; NFR-09-011; SEC-38.

#### TC-09-078 · Cùng giá trị cùng miền cùng khóa cho cùng bí danh, khác miền khác bí danh <!--k:pseudo-consistent-->

::: dac-ta
**Mục đích.** Chứng minh tính nhất quán và không nối được giữa hai mục đích.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-031, 032 · API-09-230 · BR-09-028, 029, 031 · NFR-09-011.

**Tiền điều kiện, dữ liệu.** T90; S-T90-PSEUDO; `PD-HGD`, `PD-TK`; lô 500 CCCD giả trong đó 100 trùng.

**Các bước.**

1. S-T90-PSEUDO `POST /privacy/v1/pseudonyms:issue` lô 500 giá trị cho `PD-HGD`, hai lần.
2. Gửi cùng lô cho `PD-TK`.
3. Gửi 1 giá trị rỗng.

**Kết quả mong đợi.** Bước 1 hai lần cho cùng bí danh, 100 giá trị trùng cho 100 bí danh trùng. Bước 2 không bí danh nào trùng bước 1. Bước 3 giữ rỗng, không sinh bí danh. Không bảng ánh xạ nào trong `ph09_privacy.*` (BR-09-030). Tập chứa bí danh vẫn phải thuộc một hoạt động xử lý (BR-09-031). Mồi sạch.
:::

#### TC-09-079 · Token hóa đảo ngược và HMAC không đảo ngược <!--k:pseudo-token-->

::: dac-ta
**Mục đích.** Chứng minh chỉ miền token đảo ngược được, đường giải qua OpenBao transit có kiểm soát.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-032, 033 · API-09-230 · BR-09-030 · ERR-09-048.

**Tiền điều kiện, dữ liệu.** T90; `PD-TOKEN` (token), `PD-HGD` (HMAC); U-T90-SO.

**Các bước.**

1. Cấp token cho 10 giá trị bằng `PD-TOKEN`.
2. Đề nghị khôi phục 10 token của `PD-HGD`.

**Kết quả mong đợi.** Token khác nhau cho cùng giá trị không xảy ra (cùng khóa cho cùng token). Bước 2 `422` ERR-09-048 "Miền PD-HGD dùng HMAC không đảo ngược, không khôi phục được giá trị gốc."
:::

#### TC-09-080 · OpenBao ngừng hoặc miền không có khóa hoạt động <!--k:pseudo-neg-->

::: dac-ta
**Mục đích.** Chứng minh không trả giá trị thô khi không giả danh hóa được.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-032 · API-09-230 · ERR-09-108, 109.

**Tiền điều kiện, dữ liệu.** T94; `PD-HGD` có khóa; `PD-RONG` chưa có khóa.

**Các bước.**

1. Gọi `pseudonyms:issue` khi OpenBao ngừng.
2. Gọi cho `PD-RONG`.

**Kết quả mong đợi.** Bước 1 `503` ERR-09-108. Bước 2 `422` ERR-09-109. Không trả giá trị thô.
:::

#### TC-09-081 · HMAC ≥ 2.000 giá trị mỗi giây mỗi bản sao, token ≥ 500 giá trị mỗi giây <!--k:pseudo-perf-->

::: dac-ta
**Mục đích.** Đo NFR-09-011.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-09-011 · API-09-230.

**Tiền điều kiện, dữ liệu.** T97; khóa đã đệm trong bộ nhớ 5 phút.

**Các bước.**

1. k6 lô 500 giá trị HMAC trên 1 bản sao 5 phút; lô 500 token.

**Kết quả mong đợi.** HMAC ≥ 2.000 giá trị mỗi giây; token ≥ 500 giá trị mỗi giây; nhất quán bí danh 100 %.
:::

### TS-09-24 · Khôi phục giá trị gốc từ token

**Mục tiêu.** Xác nhận khôi phục đặc quyền với ba người khác nhau, MFA, hạn duyệt và hạn thực hiện, tối đa 100 giá trị, kết quả hiển thị 60 giây.

**Phủ.** FR-09-033; UC-09-24; API-09-119…124; UI-09-13, 12; BR-09-032, 057; ERR-09-048, 049, 050, 005, 010; EVT-09-17.

#### TC-09-082 · Đề nghị, duyệt cấp một và hai, thực hiện có MFA <!--k:reid-flow-->

::: dac-ta
**Mục đích.** Chứng minh ba người khác nhau, MFA, kiểm toán trước khi giải, kết quả không lưu.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-033 · API-09-119, 122, 124, 121 · UI-09-13 · EVT-09-17 · BR-09-032 · PERM-09-reidentify.

**Tiền điều kiện, dữ liệu.** T90; 20 token của `PD-TOKEN`; U-T90-SO (đề nghị, thực hiện), DO1 (cấp một), TA (cấp hai).

**Các bước.**

1. SO `POST /reidentification-requests` 20 token, mục đích, căn cứ.
2. DO1 `:approve` cấp một; TA `:approve` cấp hai.
3. SO `:execute` không MFA; rồi với MFA.

**Kết quả mong đợi.** Bước 1 `PENDING_L1`. Bước 2 `PENDING_L2` rồi `APPROVED`. Bước 3 không MFA bị yêu cầu xác thực lại (ERR-00-401); có MFA `200`, `EXECUTED`, kết quả hiển thị 60 giây rồi hủy, không lưu đĩa, EVT: `reidentification.executed`, KT: có (reid-execute) vĩnh viễn WORM, SO và TA nhận thông báo.
:::

#### TC-09-083 · Giá trị quá 100, miền HMAC, tự duyệt, đề nghị hết hạn <!--k:reid-neg-->

::: dac-ta
**Mục đích.** Chứng minh các ràng buộc BR-09-032.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-033 · API-09-119, 122, 124 · ERR-09-049, 048, 005, 050.

**Tiền điều kiện, dữ liệu.** T92 `09.reid.approval-ttl-hours = 1`; U-T90-SO, DO1, TA.

**Các bước.**

1. SO đề nghị 101 token.
2. SO đề nghị khôi phục giá trị của `PD-HGD`.
3. SO tự `:approve` cấp một.
4. Đề nghị hợp lệ, chờ 61 phút rồi `:execute`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-049. Bước 2 `422` ERR-09-048. Bước 3 `403` ERR-09-005. Bước 4 `409` ERR-09-050 "Đề nghị khôi phục đã hết hiệu lực. Lập đề nghị mới."
:::

#### TC-09-084 · Không ghi được kiểm toán thì không khôi phục <!--k:reid-audit-fail-->

::: dac-ta
**Mục đích.** Chứng minh thao tác đặc quyền bị từ chối khi mất kiểm toán.

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-09-033 · BR-09-057 · ERR-09-010 · API-09-124.

**Tiền điều kiện, dữ liệu.** T94; đề nghị `APPROVED`; PH-13 `503`.

**Các bước.**

1. SO `:execute` có MFA khi PH-13 ngừng.

**Kết quả mong đợi.** `503` ERR-09-010, không giải mã token nào, đề nghị vẫn `APPROVED`.
:::

### TS-09-25 · Ẩn danh hóa, k tối thiểu 10 và rủi ro tái định danh

**Mục tiêu.** Xác nhận cấu hình, chạy ARX, ngưỡng k ≥ 10, đánh giá rủi ro, duyệt rủi ro `MEDIUM`, chặn `HIGH` và tập quá ít bản ghi.

**Phủ.** FR-09-035, 036, 037; UC-09-25; API-09-125…136; UI-09-14; BR-09-034, 035, 036; ERR-09-051, 052, 053, 054; NFR-09-012.

#### TC-09-085 · Ngưỡng k dưới 10, còn trường định danh trực tiếp <!--k:anon-config-neg-->

::: dac-ta
**Mục đích.** Chứng minh sàn k = 10 (SEC-38) và loại trường định danh trực tiếp.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-035 · API-09-126, 129 · ERR-09-051, 052 · BR-09-035, 036.

**Tiền điều kiện, dữ liệu.** T96; `09.anon.k-min = 10`; U-T90-DS1, DA1.

**Các bước.**

1. DS1 `POST /anonymization-configs` với `k = 5`.
2. DS1 tạo cấu hình k = 10 còn `cccd` (`DIRECT`) chưa `REMOVE`; DA1 `:approve`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-051 "Ngưỡng k phải từ 10 trở lên." Bước 2 `422` ERR-09-052 nêu `cccd`.
:::

#### TC-09-086 · Chạy ẩn danh hóa đạt k thực tế ≥ 10 và rủi ro không HIGH <!--k:anon-run-->

::: dac-ta
**Mục đích.** Chứng minh kết quả kiểm chứng k thực tế và không lưu ánh xạ.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-036, 037 · API-09-130, 132, 134 · BR-09-034, 035 · NFR-09-012.

**Tiền điều kiện, dữ liệu.** T96 F-ANON 200.000 bản ghi giả (ngày sinh, mã xã, giới tính, nghề; thuộc tính nhạy cảm `bệnh`); cấu hình k = 10 `ACTIVE`.

**Các bước.**

1. DS1 `POST /anonymization-jobs`.
2. Hỏi `GET /anonymization-jobs/{id}` đến `COMPLETED`; `GET .../risk-report`.
3. Đếm kích thước nhóm nhỏ nhất trên tập đầu ra bằng công cụ độc lập.

**Kết quả mong đợi.** `202`, `COMPLETED`, `kActual ≥ 10`, rủi ro `LOW`, số bản ghi trước và sau; nhóm nhỏ nhất ≥ 10 bản ghi; không bảng ánh xạ hoặc khóa giải. Mã `cccd` bị loại hoàn toàn.
:::

#### TC-09-087 · Không đạt k sau ba vòng, rủi ro HIGH, rủi ro MEDIUM cần SO duyệt <!--k:anon-risk-neg-->

::: dac-ta
**Mục đích.** Chứng minh chặn `HIGH`, từ chối tập quá ít và `MEDIUM` cần SO.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-036, 037 · API-09-130, 135, 136 · ERR-09-053, 054 · BR-09-035.

**Tiền điều kiện, dữ liệu.** T96 F-ANON-S 500 bản ghi nhiều giá trị độc nhất; tập F-ANON-M rủi ro 0,07; U-T90-SO.

**Các bước.**

1. Chạy job trên F-ANON-S.
2. `POST /risk-assessments` cho tập có rủi ro 0,12.
3. Chạy job cho F-ANON-M rồi DS1 phát hành; SO `:approve-risk`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-054 nêu % bản ghi còn lại (< 30 %), `REJECTED_RISK` hoặc `FAILED`. Bước 2 `HIGH`, `422` ERR-09-053 khi phát hành. Bước 3 `AWAITING_RISK_REVIEW`, chỉ phát hành sau khi SO duyệt.

**Thông báo hiển thị.** "Rủi ro tái định danh cao, không phát hành. Xem khuyến nghị của báo cáo."
:::

#### TC-09-088 · l-đa dạng khi bật và hủy job đang chạy <!--k:anon-ldiv-->

::: dac-ta
**Mục đích.** Chứng minh thuộc tính nhạy cảm đạt l-đa dạng và hủy job giải phóng tài nguyên.

**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** JOB.

**Truy vết.** FR-09-035, 036 · API-09-128, 133 · BR-09-036.

**Tiền điều kiện, dữ liệu.** T96; cấu hình bật `L_DIVERSITY` với `l = 3` cho `bệnh`.

**Các bước.**

1. Chạy job; kiểm l-đa dạng của đầu ra.
2. Chạy job lần hai rồi `POST /anonymization-jobs/{id}:cancel` giữa chừng.

**Kết quả mong đợi.** Bước 1 mọi nhóm có ≥ 3 giá trị `bệnh` khác nhau. Bước 2 `CANCELLED`, Job K8s dừng, không tập đầu ra.
:::

#### TC-09-089 · k ≥ 10 ở mọi tập phát hành (kiểm thuộc tính) <!--k:anon-k-property-->

::: dac-ta
**Mục đích.** Chứng minh 100 % tập phát hành có k thực tế ≥ k cấu hình.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-036 · BR-09-035 · NFR-09-012.

**Tiền điều kiện, dữ liệu.** T96; 20 tập sinh ngẫu nhiên hạt cố định, k cấu hình 10…20.

**Các bước.**

1. Chạy 20 job với hạt khác nhau, kiểm tập đầu ra bằng kiểm độc lập.

**Kết quả mong đợi.** 20/20 tập có k thực tế ≥ k cấu hình; không tập `HIGH` nào phát hành.
:::

### TS-09-26 · Chuẩn bị dữ liệu cho AI, môi trường không phải PROD và tập đã ẩn danh

**Mục tiêu.** Xác nhận chuẩn bị dữ liệu theo đích, cấm dữ liệu `SENSITIVE` thật ngoài PROD, phát hành, sửa, rút lại tập đã ẩn danh.

**Phủ.** FR-09-038, 039; UC-09-26; API-09-137…144; UI-09-14; BR-09-034, 037; ERR-09-055, 056, 082; SEC-38, 49.

#### TC-09-090 · Chuẩn bị dữ liệu AI chỉ ẩn danh, RESTRICTED khi bật và chạy nội bộ <!--k:prep-ai-->

::: dac-ta
**Mục đích.** Chứng minh dữ liệu cho AI chỉ ẩn danh và `RESTRICTED` cần cờ tenant (SEC-38, SEC-49).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-09-038 · API-09-137, 138 · BR-09-037 · ERR-09-082 · EVT-09-18.

**Tiền điều kiện, dữ liệu.** T96; `09.ai.allow-restricted = false`; PH-17 giả lập; U-T90-DS1.

**Các bước.**

1. DS1 `POST /data-preparations` đích `AI_TRAINING` cho tập `RESTRICTED`.
2. Bật `09.ai.allow-restricted = true`, mô hình chạy nội bộ; lặp lại.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-082 "Dữ liệu Hạn chế chưa được phép dùng cho AI. Đề nghị TA bật tham số 09.ai.allow-restricted." Bước 2 `202`, tập ẩn danh k ≥ 10, siêu dữ liệu nêu cấu hình, EVT: `dataset.status-changed` khi phát hành.
:::

#### TC-09-091 · Đích không PROD dùng dữ liệu SENSITIVE thật bị cấm, mục đích không cho phép <!--k:prep-neg-->

::: dac-ta
**Mục đích.** Chứng minh `NON_PROD_TEST` chỉ nhận dữ liệu sinh hoặc giả danh không đảo ngược.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-038 · API-09-137 · ERR-09-055 · BR-09-037.

**Tiền điều kiện, dữ liệu.** T96; U-T90-DS1; mục đích `MD-THONGKE` không cho trường Nhạy cảm.

**Các bước.**

1. DS1 chuẩn bị `NON_PROD_TEST` từ bảng `SENSITIVE` thật, không giả danh.
2. DS1 chuẩn bị `OPEN_DATA` cho mục đích `MD-THONGKE` có trường Nhạy cảm.

**Kết quả mong đợi.** Cả hai `422` ERR-09-055 "Mục đích MD-THONGKE không cho phép dùng dữ liệu có trường Nhạy cảm."; không tập nào được tạo.
:::

#### TC-09-092 · Phát hành, sửa điều kiện, rút lại tập, hết hạn <!--k:ds-publish-->

::: dac-ta
**Mục đích.** Chứng minh tập `PUBLISHED` không sửa được, chỉ rút lại và tạo tập mới.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-039 · API-09-142, 143, 144, 140 · ERR-09-056 · EVT-09-18.

**Tiền điều kiện, dữ liệu.** T96; tập `READY` từ ca anon-run.

**Các bước.**

1. DS1 `PUT .../terms` rồi `:publish`.
2. DS1 `PUT .../terms` lần hai.
3. DS1 `:withdraw`.

**Kết quả mong đợi.** Bước 1 `PUBLISHED`. Bước 2 `409` ERR-09-056. Bước 3 `WITHDRAWN`; EVT: `dataset.status-changed` mỗi lần đổi trạng thái.
:::

### TS-09-27 · Lịch lưu giữ, tác vụ xóa và báo cáo tuân thủ thời hạn lưu

**Mục tiêu.** Xác nhận lập lịch lưu giữ bốn mắt, tác vụ chạy thử và chạy thật, không chạy chồng, bảng chứa DLCN phải có thời hạn lưu và báo cáo.

**Phủ.** FR-09-040, 041, 044; UC-09-27; API-09-145…155, 163; UI-09-15; BR-09-038, 040; ERR-09-057, 061, 006; NFR-09-018.

#### TC-09-093 · Lập, duyệt lịch lưu giữ và bảng DLCN thiếu thời hạn lưu <!--k:ret-schedule-->

::: dac-ta
**Mục đích.** Chứng minh mỗi bảng chứa DLCN có thời hạn lưu tường minh (BR-09-038).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-040 · API-09-146, 149, 150 · UI-09-15 · ERR-09-057, 005 · BR-09-038.

**Tiền điều kiện, dữ liệu.** T90; bảng `ho_so_cong_dan` chứa DLCN chưa có lịch; U-T90-SO (soạn), U-T90-DA1 (duyệt).

**Các bước.**

1. SO `GET /retention-schedules` và mở UI-09-15.
2. SO tạo lịch 36 tháng, hành động `PSEUDONYMIZE`; `:submit`; tự `:approve`; DA1 `:approve`.

**Kết quả mong đợi.** Bước 1 cảnh báo ERR-09-057 "Bảng ho_so_cong_dan chứa dữ liệu cá nhân nhưng chưa có thời hạn lưu." Bước 2 tự duyệt `403` ERR-09-005; DA1 `ACTIVE`; bảng hết cảnh báo.
:::

#### TC-09-094 · Chạy thử, chạy thật xóa hoặc giả danh hóa, không chạy chồng, báo cáo <!--k:ret-task-->

::: dac-ta
**Mục đích.** Chứng minh tác vụ xử lý đúng bản ghi hết hạn trong 24 giờ sau lịch, trừ đối tượng giữ pháp lý.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-09-041, 044 · API-09-154, 152, 153, 163 · ERR-09-061 · EVT-09-19 · NFR-09-018.

**Tiền điều kiện, dữ liệu.** T90; 1.000 bản ghi giả quá hạn 36 tháng, 50 bản ghi đang giữ pháp lý; U-T90-SO.

**Các bước.**

1. SO `POST /retention-tasks:run` `dryRun = true`.
2. SO chạy thật; ngay sau đó chạy lần hai.
3. `GET /retention-reports`.

**Kết quả mong đợi.** Bước 1 liệt kê 950 bản ghi sẽ xử lý, không đổi dữ liệu. Bước 2 `202`, lần hai `409` ERR-09-061. Tác vụ `COMPLETED` giả danh hóa 950 bản ghi, bỏ qua 50 đang giữ; EVT: `retention.task-finished`. Bước 3 tỷ lệ tuân thủ 100 % ngoài đối tượng giữ pháp lý.
:::

#### TC-09-095 · Hủy tác vụ chưa chạy, sao lưu và tombstone <!--k:ret-cancel-->

::: dac-ta
**Mục đích.** Chứng minh chỉ hủy được tác vụ chưa chạy và danh sách xóa áp lại khi khôi phục sao lưu.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-041 · API-09-155 · ERR-09-006 · BR-09-040.

**Tiền điều kiện, dữ liệu.** T90; tác vụ `QUEUED` và tác vụ `COMPLETED`; U-T90-SO.

**Các bước.**

1. SO `:cancel` tác vụ `QUEUED`; rồi `:cancel` tác vụ `COMPLETED`.
2. Khôi phục bản sao lưu 20 ngày tuổi trong môi trường thử.

**Kết quả mong đợi.** Bước 1 `200` rồi `409` ERR-09-006. Bước 2 trước khi phục vụ, hệ thống áp lại tombstone nên bản ghi đã xóa không xuất hiện lại.
:::

### TS-09-28 · Giữ pháp lý và xóa mật mã khi chấm dứt tenant

**Mục tiêu.** Xác nhận giữ pháp lý chặn xóa, gỡ giữ có kiểm toán, xóa mật mã tenant cần hai người, chờ 30 ngày và không hoàn tác.

**Phủ.** FR-09-042, 043; UC-09-28; API-09-156…162; UI-09-15; BR-09-039, 041; ERR-09-058, 059, 060, 005; EVT-09-20, 21.

#### TC-09-096 · Đặt giữ pháp lý, chặn xóa, gỡ giữ <!--k:hold-set-->

::: dac-ta
**Mục đích.** Chứng minh giữ pháp lý chặn mọi tác vụ xóa đối tượng liên quan.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-042 · API-09-157, 158, 154 · ERR-09-059, 058 · EVT-09-20 · BR-09-039.

**Tiền điều kiện, dữ liệu.** T90; bản ghi thuộc hoạt động HD-01 đã quá hạn; U-T90-SO.

**Các bước.**

1. SO `POST /legal-holds` thiếu số văn bản.
2. SO đặt giữ kèm `CV-777/2026`, cơ quan, hạn rà soát.
3. SO chạy `POST /retention-tasks:run` đối tượng đang giữ.
4. SO `POST /legal-holds/{id}:release`; chạy lại.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-059. Bước 2 `201`, EVT: `legal-hold.changed`. Bước 3 `409` ERR-09-058 "Dữ liệu đang bị giữ pháp lý, không xóa được cho đến khi gỡ giữ." Bước 4 `RELEASED`, KT: có, tác vụ xử lý được.
:::

#### TC-09-097 · Đề nghị, hai người duyệt, chờ rồi hủy KEK `dh-{tenant}-pii` <!--k:shred-flow-->

::: dac-ta
**Mục đích.** Chứng minh xóa mật mã không hoàn tác sau đúng độ trễ và hai người duyệt.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-09-043 · API-09-159, 161, 160 · EVT-09-21 · BR-09-041 · PERM-09-retention.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; tenant T95 đã bàn giao dữ liệu theo PH-20; `09.shred.delay-days = 30`; U-T95-SO, U-T95-DA1.

**Các bước.**

1. SO `POST /tenant-shred-requests`; SO tự `:approve`.
2. DA1 `:approve`; trạng thái `WAITING`.
3. Tiến đồng hồ 30 ngày.
4. Đọc thử một bản ghi mã hóa bằng KEK của T95.

**Kết quả mong đợi.** Bước 1 `REQUESTED`, tự duyệt `403` ERR-09-005. Bước 2 `APPROVED`, `WAITING`. Bước 3 `EXECUTED`, EVT: `crypto-shred.completed`, KT: có. Bước 4 không giải mã được; khóa không khôi phục được.
:::

#### TC-09-098 · Chưa bàn giao, hủy trước khi thực hiện, tenant khác <!--k:shred-neg-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện xóa mật mã (BR-09-041).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-043 · API-09-159, 162 · ERR-09-060, 006 · BR-09-041.

**Tiền điều kiện, dữ liệu.** T94 chưa bàn giao PH-20; yêu cầu ở trạng thái `WAITING`; U-T91-SO.

**Các bước.**

1. SO `POST /tenant-shred-requests` khi chưa bàn giao.
2. SO `:cancel` yêu cầu `WAITING`; rồi `:cancel` lần hai.
3. U-T91-SO `GET /tenant-shred-requests/{id}` của T94.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-060 nêu lý do. Bước 2 `200` rồi `409` ERR-09-006. Bước 3 `404` ERR-09-001.

**Thông báo hiển thị.** "Chưa đủ điều kiện xóa mật mã tenant: chưa bàn giao dữ liệu theo PH-20."
:::

### TS-09-29 · Tiếp nhận, xác minh, tra cứu và chuyển xử lý yêu cầu của chủ thể

**Mục tiêu.** Xác nhận tiếp nhận ba kênh, xác minh danh tính trước khi tra cứu, tra cứu theo băm HMAC, chuyển tác vụ và hạn chế xử lý.

**Phủ.** FR-09-045…048; UC-09-29; API-09-164…173, 178, 235; UI-09-16; BR-09-042, 044, 045, 046, 047, 061; ERR-09-062…066.

#### TC-09-099 · Tiếp nhận yêu cầu ở ba kênh, trùng lặp và thiếu thông tin <!--k:dsr-intake-->

::: dac-ta
**Mục đích.** Chứng minh tiếp nhận có `Idempotency-Key`, định danh chỉ giữ mã hóa trong phiếu và không trùng yêu cầu cùng loại.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-045 · API-09-165, 166 · UI-09-16 · ERR-09-062, 064 · BR-09-061, 045 · EVT-09-22.

**Tiền điều kiện, dữ liệu.** T90; chủ thể CC-01; U-T90-DS1; S-T90-REG (kênh dịch vụ công).

**Các bước.**

1. S-T90-REG `POST /subject-requests` loại `ACCESS`, kênh `PUBLIC_SERVICE`, CCCD CC-01, khóa K2; gửi lại với K2.
2. DS1 tiếp nhận kênh `COUNTER` loại `ERASE` thiếu loại hoặc định danh.
3. DS1 tiếp nhận lại `ACCESS` cho CC-01 khi còn yêu cầu đang xử lý.

**Kết quả mong đợi.** Bước 1 `201` `RECEIVED`, hạn 10 ngày làm việc, gửi lại cùng kết quả; CCCD không có ở bảng khác ngoài phiếu mã hóa; EVT: `dsr.received`. Bước 2 `422` ERR-09-062. Bước 3 `409` ERR-09-064.
:::

#### TC-09-100 · Chưa xác minh không tra cứu được; sau xác minh tra theo băm <!--k:dsr-verify-search-->

::: dac-ta
**Mục đích.** Chứng minh BR-09-042 và tra cứu theo băm HMAC khóa theo tenant (BR-09-045).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-046, 047 · API-09-167, 168, 169, 235 · ERR-09-063, 065 · BR-09-042, 045.

**Tiền điều kiện, dữ liệu.** T90; yêu cầu DSR-01 `RECEIVED`; CC-01 xuất hiện ở PH-06, PH-19, PH-13 giả lập; U-T90-DS1.

**Các bước.**

1. DS1 `:search` khi chưa xác minh.
2. DS1 `:verify` người đại diện không chứng minh được.
3. DS1 `:verify` đúng (`ID_DOCUMENT`) rồi `:search`; `GET .../findings`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-063. Bước 2 `403` ERR-09-065. Bước 3 kết quả từ PH-06, PH-19, PH-13 chỉ gồm siêu dữ liệu (hệ thống, đối tượng, số bản ghi), tra bằng `subject-hashes:compute`; không giá trị CCCD rõ trong thân hoặc log.
:::

#### TC-09-101 · Chuyển tác vụ, bên kiểm soát, lỗi chuyển và phân công <!--k:dsr-route-->

::: dac-ta
**Mục đích.** Chứng minh dữ liệu đi qua chuyển cho bên kiểm soát và xóa bị từ chối có căn cứ (BR-09-046).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-048 · API-09-170, 171, 172, 173 · ERR-09-066 · BR-09-044, 046.

**Tiền điều kiện, dữ liệu.** T90; DSR-01 đã xác minh; PH-06 giả lập `502` ở lần đầu; yêu cầu `ERASE` cho dữ liệu có căn cứ pháp lý giữ.

**Các bước.**

1. DS1 `POST /subject-requests/{id}/tasks` đích `PH06_MASTER`, `PH19_PAYMENT`, `CONTROLLER`.
2. PH-06 giả lập trả `502` rồi `200`; PH-06 `:complete`.
3. DS1 `:assign` cho DS2; xử lý yêu cầu `ERASE` có căn cứ giữ.

**Kết quả mong đợi.** Bước 1 ba tác vụ `OPEN`. Bước 2 hệ thống tự thử lại, lần lỗi hiện ERR-09-066 "Chưa chuyển được yêu cầu tới PH-06. Hệ thống sẽ thử lại."; tác vụ `DONE`. Bước 3 tác vụ `ERASE` `REFUSED` có nêu căn cứ.
:::

#### TC-09-102 · Hạn chế xử lý có hiệu lực ở quyết định mục đích <!--k:dsr-restrict-->

::: dac-ta
**Mục đích.** Chứng minh khi chủ thể bị hạn chế chỉ mục đích bắt buộc theo luật còn được truy cập.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-048, 019 · API-09-178, 227 · EVT-09-26 · BR-09-047 · ERR-09-104.

**Tiền điều kiện, dữ liệu.** T90; yêu cầu `RESTRICT` cho CC-03; HTTT-BH có chấp thuận `MD-TRACUU-HGD`.

**Các bước.**

1. DS1 hoàn tất tác vụ hạn chế; PEP gọi `purpose:decide` cho CC-03.
2. DS1 `POST /subject-requests/{id}:lift-restriction`; gọi lại.

**Kết quả mong đợi.** Bước 1 mục đích thường `403` ERR-09-104, `MD-LUATDINH` `200`; EVT: `dsr.restriction-changed` tới PH-06, PH-19, PH-14. Bước 2 EVT: `dsr.restriction-changed`, `allow` trở lại ở mục đích thường.
:::

### TS-09-30 · Hạn xử lý, trả lời, đóng yêu cầu và báo cáo truy cập

**Mục tiêu.** Xác nhận theo dõi hạn và nhắc, trả lời có bằng chứng, đóng khi hết tác vụ, báo cáo "ai đã truy cập dữ liệu của tôi".

**Phủ.** FR-09-049, 050, 051; UC-09-30; API-09-174…177, 179, 180, 181, 242, 244; UI-09-16, 01; BR-09-043, 048; ERR-09-067, 068; NFR-09-016.

#### TC-09-103 · Nhắc trước 3 ngày làm việc và cờ quá hạn <!--k:dsr-due-->

::: dac-ta
**Mục đích.** Chứng minh nhắc đúng 3 ngày làm việc trước hạn (100 %) và cảnh báo SO khi quá hạn.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-049 · API-09-174, 242 · EVT-09-23, 24 · BR-09-043 · NFR-09-016.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; 3 yêu cầu hạn sau 3, 0 và -1 ngày làm việc; lịch ngày nghỉ giả định Q09-43.

**Các bước.**

1. Tiến đồng hồ; `GET /subject-requests:due`.
2. U-T90-VW gọi `GET /subject-requests:due`.
3. SO `POST /subject-requests/{id}:extend` kèm lý do và hạn mới không quá ngày pháp luật cho phép.

**Kết quả mong đợi.** Yêu cầu 1 có EVT: `dsr.due-soon` đúng một lần. Yêu cầu 3 có cờ `overdue`, EVT: `dsr.overdue` tới SO; trạng thái `DsrStatus` không đổi; thẻ "yêu cầu quá hạn" ở UI-09-01 đúng số. Bước 2 ERR-00-403. Bước 3 `200`, hạn mới được ghi, chủ thể được báo; hạn vượt mức pháp luật cho phép bị từ chối.
:::

#### TC-09-104 · Trả lời, lưu bằng chứng và đóng yêu cầu <!--k:dsr-respond-close-->

::: dac-ta
**Mục đích.** Chứng minh không đóng khi còn tác vụ hoặc thiếu kết quả, từ chối cần căn cứ.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-050 · API-09-175, 176, 177, 244 · ERR-09-067, 068 · BR-09-048 · EVT-09-25.

**Tiền điều kiện, dữ liệu.** T90; DSR-01 còn 1 tác vụ `OPEN`; U-T90-DS1.

**Các bước.**

1. DS1 `:close` khi còn 1 tác vụ.
2. DS1 `:respond` thiếu kết quả hoặc bằng chứng.
3. Hoàn tất tác vụ; `:respond` đủ kết quả `FULFILLED` kèm tệp; `:close`.
4. SO `POST /subject-requests/{id}:withdraw` kèm lý do trên một yêu cầu khác đang `IN_PROGRESS`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-067 "Còn 1 tác vụ chưa hoàn tất, chưa đóng được yêu cầu." Bước 2 `422` ERR-09-068. Bước 3 `CLOSED`, bằng chứng lưu 5 năm, EVT: `dsr.closed`. Bước 4 `200`, `WITHDRAWN`, tác vụ đang mở bị hủy.
:::

#### TC-09-105 · Báo cáo ai đã truy cập dữ liệu của chủ thể, không lộ nội dung <!--k:dsr-access-report-->

::: dac-ta
**Mục đích.** Chứng minh báo cáo liệt kê người, hệ thống, mục đích, thời điểm.

**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-051 · API-09-179, 180, 181 · BR-09-044, 042 · ERR-09-063.

**Tiền điều kiện, dữ liệu.** T90; CC-01 có 12 lượt truy cập ở nhật ký PH-13 giả lập; DSR-01 đã xác minh.

**Các bước.**

1. DS1 `POST /subject-requests/{id}:access-report`; `GET .../access-report`.
2. `GET /subject-request-reports`.
3. DS1 `:access-report` cho yêu cầu chưa xác minh.

**Kết quả mong đợi.** Bước 1 12 dòng (HTTT, mục đích, thời điểm) không giá trị dữ liệu. Bước 2 tỷ lệ đóng trong hạn đúng báo cáo. Bước 3 `422` ERR-09-063.
:::

### TS-09-31 · Mẫu và bản ghi sự đồng ý

**Mục tiêu.** Xác nhận mẫu có phiên bản, bốn mắt, ghi nhận đồng ý kèm bằng chứng, rút đồng ý có hiệu lực trong 60 giây và tra cứu trạng thái.

**Phủ.** FR-09-052, 053, 054; UC-09-31; API-09-182…191, 234, 238, 245; UI-09-17; BR-09-049, 050, 051; ERR-09-069…072; EVT-09-27, 28.

#### TC-09-106 · Tạo mẫu, duyệt, sửa mẫu đã có người đồng ý phải tạo phiên bản mới <!--k:cns-template-->

::: dac-ta
**Mục đích.** Chứng minh mẫu nêu mục đích cụ thể, dữ liệu, cách rút và không sửa tại chỗ.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-052 · API-09-183, 185, 186, 184, 238 · ERR-09-069, 070, 005 · BR-09-049.

**Tiền điều kiện, dữ liệu.** T90; U-T90-SO (soạn), U-T90-DA1; mẫu `CNS-TIENICH` đã có 3 người đồng ý.

**Các bước.**

1. SO tạo mẫu thiếu cách rút lại.
2. SO tạo mẫu đủ; gửi duyệt; tự duyệt; DA1 duyệt.
3. SO `PUT /consent-templates/CNS-TIENICH/versions/1` khi đã có người đồng ý.
4. SO `GET /consent-templates/CNS-TIENICH`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-069. Bước 2 tự duyệt `403` ERR-09-005, DA1 `ACTIVE`. Bước 3 `409` ERR-09-070 "Mẫu đã có người đồng ý. Tạo phiên bản mới thay vì sửa." Bước 4 `200`, chi tiết mẫu kèm danh sách phiên bản (API-09-238).
:::

#### TC-09-107 · Ghi nhận đồng ý đủ bằng chứng, rút trong 60 giây, rút lần hai <!--k:cns-record-withdraw-->

::: dac-ta
**Mục đích.** Chứng minh bằng chứng đủ trường và rút đồng ý hiệu lực ≤ 60 giây (đệm `09.consent.cache-seconds` tối đa 60).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-053, 054 · API-09-188, 189, 191, 234, 245 · ERR-09-071, 072 · BR-09-050, 051 · EVT-09-27, 28.

**Tiền điều kiện, dữ liệu.** T90; S-T90-CONSENT; mẫu `CNS-TIENICH` v1 `ACTIVE`; chủ thể CC-01 (băm).

**Các bước.**

1. S-T90-CONSENT `POST /consents` thiếu kênh hoặc phiên bản mẫu.
2. Gửi đủ (băm chủ thể, mẫu và phiên bản, băm nội dung hiển thị, thời điểm, kênh `WEB`, người ghi).
3. `POST /privacy/v1/consents:check`; rút `:withdraw`; kiểm lại sau ≤ 60 giây; rút lần hai.
4. SO `POST /consents:search` với định danh chủ thể trong thân (mã mẫu `<bi-mat-mau>`).

**Kết quả mong đợi.** Bước 1 `422` ERR-09-071. Bước 2 `201` `GIVEN`, EVT: `consent.given`. Bước 3 trạng thái `GIVEN` rồi `WITHDRAWN` ≤ 60 giây sau khi rút, EVT: `consent.withdrawn`; rút lần hai `409` ERR-09-072. Xử lý trước đó không bị vô hiệu. Bước 4 `200`, danh sách bản ghi đồng ý theo băm; định danh không lặp lại trong kết quả và log (API-09-245).
:::

#### TC-09-108 · Đồng ý chỉ cho tiện ích không bắt buộc <!--k:cns-optional-->

::: dac-ta
**Mục đích.** Chứng minh không dùng đồng ý làm điều kiện thực hiện thủ tục hành chính.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-052, 054 · API-09-234 · BR-09-049 · ERR-09-024.

**Tiền điều kiện, dữ liệu.** T90; hoạt động bắt buộc theo luật; hoạt động tiện ích không bắt buộc.

**Các bước.**

1. Gắn mẫu đồng ý vào hoạt động bắt buộc theo luật.
2. Tra `consents:check` cho tiện ích không bắt buộc khi chưa có đồng ý.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-024. Bước 2 `GIVEN = false`; thủ tục chính vẫn thực hiện được.
:::

### TS-09-32 · Hồ sơ đánh giá tác động DPIA

**Mục tiêu.** Xác nhận lập đủ mục, duyệt và phiên bản, nhắc rà soát 12 tháng, xuất hồ sơ gửi Cục A05 chỉ khi đã duyệt.

**Phủ.** FR-09-055, 056, 057; UC-09-32; API-09-192…201; UI-09-18; BR-09-052, 053; ERR-09-073, 074, 005; EVT-09-29.

#### TC-09-109 · Lập, gửi duyệt, duyệt bốn mắt, xuất hồ sơ A05, ghi số công văn <!--k:dpia-flow-->

::: dac-ta
**Mục đích.** Chứng minh hồ sơ bên kiểm soát và hồ sơ bên xử lý đi đủ vòng đời đến `SUBMITTED_A05`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-09-055, 056, 057 · API-09-193, 196, 197, 200, 201 · UI-09-18 · BR-09-052.

**Tiền điều kiện, dữ liệu.** T90; HD-01 `ACTIVE`; U-T90-SO (soạn), U-T90-DA1.

**Các bước.**

1. SO `POST /dpia-records` loại `PROCESSING`, đủ mục; `:submit`.
2. DA1 `:approve`.
3. SO `:export-a05`; tải tệp; `:mark-submitted` số công văn `CV-A05-01`.

**Kết quả mong đợi.** Bước 2 `ACTIVE`, KT: có. Bước 3 tệp theo mẫu A05, không giá trị DLCN, `DpiaStatus = SUBMITTED_A05`.
:::

#### TC-09-110 · Thiếu mục, tự duyệt, xuất khi chưa duyệt <!--k:dpia-neg-->

::: dac-ta
**Mục đích.** Chứng minh kiểm đủ mục và chưa duyệt không xuất.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-055, 056, 057 · API-09-196, 197, 200 · ERR-09-073, 005, 074.

**Tiền điều kiện, dữ liệu.** T90; hồ sơ nháp thiếu "biện pháp bảo vệ"; U-T90-SO, U-T90-DA1.

**Các bước.**

1. SO `:submit` hồ sơ thiếu biện pháp bảo vệ.
2. SO gửi hồ sơ đủ rồi tự `:approve`.
3. SO `:export-a05` hồ sơ chưa duyệt.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-073 nêu mục thiếu. Bước 2 `403` ERR-09-005. Bước 3 `409` ERR-09-074.
:::

#### TC-09-111 · Đến hạn rà soát 12 tháng, nhắc trước 30 ngày <!--k:dpia-review-->

::: dac-ta
**Mục đích.** Chứng minh nhắc rà soát đúng hạn.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** FR-09-056 · API-09-199 · EVT-09-29 · BR-09-053.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; hồ sơ duyệt cách 11 tháng; `09.dpia.review-months = 12`.

**Các bước.**

1. Tiến đồng hồ đến 335 ngày; `GET /dpia-records:reviews-due`.

**Kết quả mong đợi.** Hồ sơ có trong danh sách, EVT: `dpia.review-due` đúng một lần cho SO; thêm hoạt động rủi ro làm hồ sơ cần rà soát sớm.
:::

### TS-09-33 · Vi phạm dữ liệu cá nhân và đồng hồ 72 giờ

**Mục tiêu.** Xác nhận ghi nhận, đánh giá, đồng hồ 72 giờ không dừng, thông báo Cục A05 và chủ thể, khắc phục, đóng hồ sơ và hồ sơ không có DLCN rõ.

**Phủ.** FR-09-058, 059, 060; UC-09-33; API-09-202…214, 239, 240; UI-09-19; BR-09-054, 055, 056, 057; ERR-09-075, 076, 077, 006; EVT-09-30, 31, 32; NFR-09-017.

#### TC-09-112 · Ghi nhận vi phạm có thời điểm phát hiện, đánh giá mức, đồng hồ bắt đầu <!--k:brh-record-->

::: dac-ta
**Mục đích.** Chứng minh đồng hồ tính từ `detectedAt` đã ghi nhận và hồ sơ không chứa DLCN rõ (BR-09-056).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-058, 059 · API-09-203, 206, 207 · UI-09-19 · EVT-09-30 · BR-09-054 · PERM-09-breach.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; U-T90-TO (ghi nhận), U-T90-SO.

**Các bước.**

1. TO `POST /breaches` có `detectedAt`, mô tả, 120 chủ thể (băm), loại `HEALTH`.
2. SO `:assess` mức `HIGH`.
3. `GET /breaches/{id}/clock`.

**Kết quả mong đợi.** Bước 1 `201` `REPORTED`, EVT: `breach.recorded`. Bước 2 `ASSESSING` rồi `NOTIFYING`. Bước 3 còn 72 giờ trừ thời gian đã trôi; sửa mô tả không đặt lại đồng hồ. Hồ sơ chỉ có số lượng, loại, băm.
:::

#### TC-09-113 · Thiếu thời điểm phát hiện, không thông báo chủ thể không căn cứ, đóng khi còn nghĩa vụ, TO không đóng được <!--k:brh-neg-->

::: dac-ta
**Mục đích.** Chứng minh các ràng buộc thông báo và đóng hồ sơ (BR-09-055, BR-09-057).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-058, 059, 060 · API-09-203, 208, 213 · ERR-09-075, 077, 076, 006 · BR-09-055.

**Tiền điều kiện, dữ liệu.** T95; vụ việc BR-01 `NOTIFYING` chưa gửi A05; U-T90-TO, U-T90-SO.

**Các bước.**

1. TO `POST /breaches` không `detectedAt`.
2. SO soạn thông báo `SUBJECT` không nêu căn cứ miễn trừ khi chọn không thông báo.
3. SO `:close` khi chưa gửi A05.
4. TO `:close`.

**Kết quả mong đợi.** Bước 1 `422` ERR-09-075. Bước 2 `422` ERR-09-077. Bước 3 `409` ERR-09-076 "Còn nghĩa vụ thông báo chưa hoàn tất, chưa đóng được hồ sơ." Bước 4 ERR-00-403 (TO không đóng được).
:::

#### TC-09-114 · Cảnh báo ở 24, 48, 60 giờ, thông báo A05 trước 72 giờ <!--k:brh-clock-->

::: dac-ta
**Mục đích.** Chứng minh cảnh báo đúng mốc (±1 phút) và có bằng chứng thông báo trước 72 giờ.

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-059 · API-09-207, 208, 209, 239 · EVT-09-31, 32 · NFR-09-017 · BR-09-054, 055.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; BR-01 `detectedAt` = T0; `09.breach.alert-hours = 24, 48, 60`.

**Các bước.**

1. Tiến đồng hồ đến T0+24 giờ, +48 giờ, +60 giờ.
2. Ở T0+70 giờ SO soạn thông báo A05, `:mark-sent`; `GET /breaches/{id}/notifications` (API-09-239).
3. Thử tạm dừng hoặc đặt lại đồng hồ.

**Kết quả mong đợi.** Bước 1 EVT: `breach.deadline-near` đúng ở ba mốc cho SO, TA, DA, sai số ≤ 1 phút. Bước 2 `SENT`, EVT: `breach.notified`, `BreachStatus = NOTIFIED`. Bước 3 không có đường tạm dừng hay đặt lại; đồng hồ chỉ dừng khi thông báo A05 đã `SENT` (BR-09-054). Bước 2 danh sách thông báo có bản A05 `SENT`.
:::

#### TC-09-115 · Khắc phục, bài học, đóng hồ sơ, tải hồ sơ <!--k:brh-dossier-->

::: dac-ta
**Mục đích.** Chứng minh hồ sơ có biện pháp, bài học và đóng đúng trạng thái.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-060 · API-09-211, 212, 213, 214, 240 · UI-09-19.

**Tiền điều kiện, dữ liệu.** T90; vụ việc `NOTIFIED`; U-T90-SO.

**Các bước.**

1. SO ghi biện pháp khắc phục và bài học; `:close`; `GET .../dossier`.
2. `GET /breaches/{id}/actions`.

**Kết quả mong đợi.** `CLOSED`, hồ sơ có dòng thời gian, thông báo, khắc phục, bài học; KT: có; không giá trị DLCN rõ. Bước 2 `200`, liệt kê biện pháp khắc phục kèm người phụ trách, hạn và trạng thái (API-09-240).
:::

### TS-09-34 · Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo và tham số

**Mục tiêu.** Xác nhận tra nhật ký theo quyền, bảng điều khiển, báo cáo định kỳ và tham số `09.*` trong miền, trần, sàn do PA đặt.

**Phủ.** FR-09-061…064; UC-09-34; API-09-215…226; UI-09-20, 01, 21; BR-09-058, 059, 060; ERR-09-003, 078, 079; NFR-09-013, 022, 023.

#### TC-09-116 · Tra nhật ký theo thời gian, người, loại thao tác; giới hạn khoảng tra; xuất <!--k:aud-query-->

::: dac-ta
**Mục đích.** Chứng minh AU tra được, DS không, mọi thao tác ghi có bản ghi và không chứa giá trị `SENSITIVE`.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-061 · API-09-215, 216, 217 · UI-09-20 · PERM-09-audit-read · ERR-09-079 · BR-09-058.

**Tiền điều kiện, dữ liệu.** T99 2 triệu bản ghi kiểm toán một tháng; U-T90-AU, U-T90-DS1.

**Các bước.**

1. AU `GET /audit-events?from&to&actor=...` trong 30 ngày; chi tiết một bản ghi.
2. AU tra khoảng 120 ngày (`09.audit.query-max-days = 90`).
3. DS1 `GET /audit-events`.
4. AU `POST /audit-exports`.

**Kết quả mong đợi.** Bước 1 `200`, bản ghi chỉ có tên trường, băm có khóa, số lượng. Bước 2 từ chối `422` ERR-09-079 "Chọn khoảng thời gian tối đa 90 ngày." Bước 3 ERR-00-403. Bước 4 `202`, tệp không có giá trị rõ, KT: có (audit-export).
:::

#### TC-09-117 · Bảng điều khiển, báo cáo tuân thủ và lịch lập báo cáo <!--k:dash-report-->

::: dac-ta
**Mục đích.** Chứng minh thẻ chỉ số bấm được, VW chỉ xem tổng quan và báo cáo theo lịch.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-09-062, 063 · API-09-218, 219, 220, 221, 222, 223 · UI-09-01 · ERR-09-003 · NFR-09-022.

**Tiền điều kiện, dữ liệu.** T90; U-T90-VW, U-T90-TA.

**Các bước.**

1. VW mở UI-09-01; bấm thẻ "hợp đồng bị chặn".
2. TA `POST /compliance-reports` kỳ quý; `PUT /compliance-reports:schedule` `0 6 1 * *`; rồi gửi lịch `hai ngay mot lan`.
3. VW mở UI-09-15.

**Kết quả mong đợi.** Bước 1 danh sách đã lọc khớp `GET /activation-checks:blocked`; chỉ số `privacy_unclassified_fields`, `privacy_dsr_overdue`, `privacy_breach_clock_seconds` đúng. Bước 2 `201`, tệp tải được, lịch hợp lệ `200`, lịch sai `400` ERR-09-003. Bước 3 ERR-00-403.
:::

#### TC-09-118 · Tham số ngoài miền, vượt trần PA, không cần khởi động lại <!--k:set-neg-->

::: dac-ta
**Mục đích.** Chứng minh BR-09-059 và hiệu lực không khởi động lại.

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-064 · API-09-224, 225, 226 · ERR-09-078 · BR-09-059 · PERM-09-config.

**Tiền điều kiện, dữ liệu.** T90; trần PA `09.plan.cache-seconds ≤ 300`, sàn `09.anon.k-min ≥ 10`; U-T90-TA, U-PA.

**Các bước.**

1. TA đặt `09.plan.cache-seconds = 600`, `09.anon.k-min = 5`, `09.mask.reveal-seconds = 90`.
2. TA đặt `09.plan.cache-seconds = 120`; PEP lấy kế hoạch.
3. `GET /settings/history`.

**Kết quả mong đợi.** Bước 1 mỗi giá trị `422` ERR-09-078 "Giá trị của 09.plan.cache-seconds ngoài miền cho phép 60…300." Bước 2 `200`, PEP dùng `ttlSeconds = 120` ngay, không khởi động lại. Bước 3 lịch sử có người, giá trị cũ, mới, KT: có.
:::


## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Các kịch bản TS-09-35…42 kiểm các tính chất xuyên suốt: cô lập tenant, phân quyền, không lộ DLCN, đóng an toàn, hiệu lực tức thời, hiệu năng, truy cập và tương đương hệ cũ. Ca hiệu năng và chịu lỗi chạy ở PERF hoặc STAGING theo mục 1.3.

### TS-09-35 · Cô lập tenant: API, RLS, data plane, Kafka, khóa

**Mục tiêu.** Chứng minh không đường nào để T91 đọc hoặc ghi dữ liệu quyền riêng tư của T90, ở mọi API đọc, data plane, CSDL, Kafka và khóa mật mã.

**Phủ.** NFR-09-019; FR-09-001…064 (mọi API đọc); API-09-001…245; BR-09-045, 060; ERR-09-001.

#### TC-09-119 · Rò rỉ chéo tenant: phân loại, sổ xử lý, mục đích, chính sách che, miền, lịch, tham số <!--k:iso-api-catalog-->

::: dac-ta
**Mục đích.** Chứng minh nhóm API cấu hình của T90 là `404-ẩn` với T91 và danh sách chỉ có dữ liệu T91.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-09-019 · FR-09-003, 004, 009, 014, 024, 031, 040, 064 · API-09-011, 034, 054, 094, 111, 147, 224 · ERR-09-001 · BR-09-060.

**Tiền điều kiện, dữ liệu.** T90 và T91 cùng mã phần tử `cccd`, mục đích `MD-TRACUU-HGD`, miền `PD-HGD`; U-T91-TA, U-T91-SO.

**Các bước.**

1. U-T91-SO gọi GET chi tiết và danh sách các API trên bằng định danh của T90.
2. U-T91-TA `PUT /settings` với `tenant_id` T90 trong thân.

**Kết quả mong đợi.** Bước 1 danh sách chỉ T91; chi tiết `404-ẩn` ERR-09-001. Bước 2 `400` hoặc `403`, không ghi vào T90. T90 không đổi.
:::

#### TC-09-120 · Rò rỉ chéo tenant: yêu cầu, chấp thuận, khôi phục, chủ thể, vi phạm, đồng ý, DPIA, nhật ký <!--k:iso-api-case-->

::: dac-ta
**Mục đích.** Chứng minh đối tượng nghiệp vụ và nhật ký của T90 là `404-ẩn` kể cả với thao tác `:revoke`, `:execute`, `:close`.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-09-019 · FR-09-015, 017, 033, 045, 053, 055, 058, 061 · API-09-060, 068, 121, 166, 191, 194, 204, 216 · ERR-09-001 · BR-09-060.

**Tiền điều kiện, dữ liệu.** Đối tượng T90 tạo ở TS-09-09…33; U-T91-DO1, U-T91-SO, U-T91-AU.

**Các bước.**

1. Gọi GET và POST hành động các API trên bằng token T91 với định danh của T90.
2. U-T91-AU `GET /audit-events` đúng khoảng thời gian có sự kiện T90.

**Kết quả mong đợi.** Mọi lệnh `404` ERR-09-001, không đổi trạng thái T90, thân giống "không tồn tại" trừ `traceId`. Bước 2 không có bản ghi T90.
:::

#### TC-09-121 · RLS CSDL: mọi bảng `ph09_privacy` bật RLS, không ngữ cảnh tenant thì không thấy hàng <!--k:iso-rls-->

::: dac-ta
**Mục đích.** Chứng minh RLS theo `tenant_id` đủ mọi bảng.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** NFR-09-019 · BR-09-060 · FR-09-061.

**Tiền điều kiện, dữ liệu.** Schema `ph09_privacy` trên `ph09_test`; vai ứng dụng `dh_data_app`; 20 hàng T90, 20 hàng T91 mỗi bảng; `psql` với `03-thiet-ke/csdl/ph09/test/`.

**Các bước.**

1. Truy `pg_class`, `pg_policies` để liệt kê bảng thiếu RLS hoặc thiếu chính sách.
2. Đặt `app.tenant_id = T90`; `SELECT` mọi bảng; thử `INSERT` hàng mang `tenant_id` T91; thử `UPDATE`, `DELETE` hàng T91.
3. Không đặt `app.tenant_id`; `SELECT` mọi bảng.

**Kết quả mong đợi.** Bước 1 0 bảng thiếu. Bước 2 chỉ thấy 20 hàng T90; INSERT, UPDATE, DELETE hàng T91 bị từ chối hoặc 0 hàng. Bước 3 0 hàng.
:::

#### TC-09-122 · Data plane: token T91 không lấy được kế hoạch, bundle, chỉ mục của T90 <!--k:iso-plane-->

::: dac-ta
**Mục đích.** Chứng minh điểm thực thi chỉ nhận dữ liệu của tenant mình và băm chủ thể khác nhau giữa tenant.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-09-019 · API-09-227, 228, 232, 233, 234, 235, 236 · BR-09-060 · ERR-09-111.

**Tiền điều kiện, dữ liệu.** T90, T91; S-T91-PEP (scope `privacy:decide` của T91); S-T91-CONSENT.

**Các bước.**

1. S-T91-PEP gọi `mask-plans:resolve`, `classification-index`, `bundles/current`, `purpose:decide` với `contract` chỉ có ở T90.
2. S-T91-CONSENT gọi `consents:check` với băm chủ thể của T90.
3. Cùng CCCD `001090000101` gọi `subject-hashes:compute` ở T90 và T91.

**Kết quả mong đợi.** Bước 1 dữ liệu chỉ của T91; hợp đồng T90 không tồn tại với T91 (`403` ERR-09-102 hoặc `404-ẩn`). Bước 2 `GIVEN = false`. Bước 3 hai băm khác nhau (khóa theo tenant).
:::

#### TC-09-123 · Topic `{tenant}.privacy.*`, ACL tiền tố và khóa mật mã theo tenant <!--k:iso-kafka-key-->

::: dac-ta
**Mục đích.** Chứng minh ACL Kafka theo tiền tố và khóa giả danh riêng từng tenant.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** NFR-09-019 · EVT-09-01…32 · BR-09-060, 028.

**Tiền điều kiện, dữ liệu.** T90, T91; client OAUTHBEARER của mỗi tenant; `PD-HGD` ở cả hai tenant.

**Các bước.**

1. Consumer T91 đọc `t90.privacy.purpose-grant.approved.v1`; producer T91 ghi vào `t90.privacy.*`.
2. Cùng giá trị CCCD giả qua `pseudonyms:issue` ở T90 và T91.

**Kết quả mong đợi.** Bước 1 `TOPIC_AUTHORIZATION_FAILED` cả hai chiều. Bước 2 hai bí danh khác nhau; khóa trong OpenBao mang mã tenant khác nhau.
:::

### TS-09-36 · Phân quyền theo ma trận PERM-09 và bốn mắt

**Mục tiêu.** Chứng minh ma trận 16 quyền, quyền theo tổ chức, scope dịch vụ, bốn mắt không có đường vòng.

**Phủ.** FR-09-004, 010, 016, 026, 034, 043, 056; API-09-001…245; BR-09-003, 014; ERR-09-004, 005, 008, 081; PERM-09-*.

#### TC-09-124 · Quét ma trận 16 quyền trên 11 vai, kể cả quyền theo tổ chức <!--k:perm-matrix-->

::: dac-ta
**Mục đích.** Chứng minh ● được, — bị `403`, ○ chỉ với đối tượng thuộc tổ chức mình.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-004, 009, 015, 029, 045, 058, 061, 064 · API-09-015, 033, 059, 102, 165, 203, 215, 225 · ERR-09-008 · PERM-09-classify, PERM-09-ropa, PERM-09-purpose-request, PERM-09-unmask, PERM-09-dsr, PERM-09-breach, PERM-09-audit-read, PERM-09-config.

**Tiền điều kiện, dữ liệu.** Ma trận FRS 3.2; mỗi vai của T90 một người dùng (PA, TA, TO, SO, DS, DA, DO, OR, SV, VW, AU).

**Các bước.**

1. Mỗi vai gọi một API đại diện của từng quyền.
2. Với ○ (DS, DO, OR, SV) gọi trên đối tượng của tổ chức mình và tổ chức khác.

**Kết quả mong đợi.** Ô ● `2xx`; ô — ERR-00-403; ô ○ đối tượng khác tổ chức `403` ERR-09-008. Hai vai DS và DA không đồng thời giữ quyền trong cùng tenant.
:::

#### TC-09-125 · Quét mọi thao tác bốn mắt: người đề nghị hay soạn không duyệt dù đủ quyền <!--k:perm-4eyes-->

::: dac-ta
**Mục đích.** Chứng minh ADR-046 áp cho 11 thao tác (hạ mức, gỡ nhãn, hoạt động, chính sách che, lịch lưu giữ, cấu hình ẩn danh, mẫu đồng ý, DPIA, khóa, xóa mật mã, chấp thuận).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-004, 010, 016, 026, 033, 034, 035, 040, 043, 052, 056 · API-09-016, 037, 065, 097, 122, 129, 150, 161, 186, 197 · ERR-09-005 · BR-09-003, 014.

**Tiền điều kiện, dữ liệu.** U-T90-TA có cả `PERM-09-policy` và `PERM-09-policy-approve`; DA1; SO.

**Các bước.**

1. Với từng thao tác, người soạn hoặc đề nghị gọi duyệt trên đối tượng của mình.
2. Người thứ hai khác gọi duyệt.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-005 ở cả 11 thao tác, kể cả TA có đủ hai quyền. Bước 2 thành công, KT: có ghi cả hai người.
:::

#### TC-09-126 · Scope `privacy:*` đúng API, token người dùng không gọi data plane, token máy không gọi control plane <!--k:perm-service-->

::: dac-ta
**Mục đích.** Chứng minh scope tối thiểu cho từng tài khoản máy.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-019, 027, 028, 032, 054 · API-09-227, 229, 230, 234 · ERR-09-111 · PERM-09-config.

**Tiền điều kiện, dữ liệu.** T90; S-T90-PEP-04 (`privacy:decide`), S-T90-APPLY-04, S-T90-PSEUDO, S-T90-CONSENT; U-T90-SO.

**Các bước.**

1. Mỗi tài khoản gọi API của scope khác.
2. U-T90-SO gọi `purpose:decide`.
3. S-T90-PEP-04 gọi `PUT /settings`.

**Kết quả mong đợi.** Bước 1 `403` ERR-09-111. Bước 2 `403` ERR-09-111. Bước 3 ERR-00-403.
:::

#### TC-09-127 · Thiếu token, thiếu `If-Match`, ETag cũ, gọi lặp `Idempotency-Key` <!--k:perm-http-->

::: dac-ta
**Mục đích.** Chứng minh lỗi nền ERR-00-401, 428 và cạnh tranh ghi ERR-09-004.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-064, 045 · API-09-225, 165 · ERR-09-004, 081 · BR-09-061.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA; `ETag` cũ của `/settings`.

**Các bước.**

1. `PUT /settings` không token.
2. `PUT /settings` thiếu `If-Match`.
3. `PUT /settings` với `ETag` đã cũ.
4. `POST /subject-requests` hai lần cùng `Idempotency-Key` và thân, rồi lần ba cùng khóa với thân khác.

**Kết quả mong đợi.** Bước 1 `401` ERR-00-401. Bước 2 `428` ERR-00-428. Bước 3 `409` ERR-09-004 "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới." Bước 4 một yêu cầu duy nhất; dùng lại khóa với thân khác `409` ERR-09-081 "Idempotency-Key đã dùng với thân khác. Dùng khóa mới."
:::

### TS-09-37 · Không lộ dữ liệu cá nhân ở sự kiện, tệp xuất và bề mặt tấn công

**Mục tiêu.** Chứng minh sự kiện, tệp xuất không mang giá trị DLCN và bề mặt API, data plane qua quét bảo mật.

**Phủ.** NFR-09-014; EVT-09-01…32; BR-09-025, 056, 058; API-09-030, 052, 087, 217.

#### TC-09-128 · Sự kiện: tên topic, lược đồ và không có giá trị DLCN <!--k:sec-events-->

::: dac-ta
**Mục đích.** Chứng minh 32 sự kiện theo mẫu `{tenant}.privacy.{thực-thể}.{sự-kiện}.v1`, chỉ chứa mã, mức, số lượng.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** EVT-09-01…32 · NFR-09-014 · BR-09-025, 058 · FR-09-018, 061.

**Tiền điều kiện, dữ liệu.** T90; chạy toàn bộ mục 4 với canary `DH-CANARY-evt`; kcat đọc mọi `t90.privacy.*`.

**Các bước.**

1. Thu mọi bản tin sau khi chạy mục 4.
2. Kiểm tên topic, lược đồ, và tìm canary, CCCD giả, số điện thoại giả.

**Kết quả mong đợi.** Mọi tên chữ thường đúng mẫu, đủ 32 loại có bản tin; 0 giá trị DLCN rõ (kể cả `EVT-09-17`, `EVT-09-30`).
:::

#### TC-09-129 · Mọi tệp xuất không có DLCN rõ: phân loại, sổ, khai thác, nhật ký, hồ sơ vi phạm <!--k:sec-export-->

::: dac-ta
**Mục đích.** Chứng minh tệp xuất chỉ chứa tên trường, mã, băm, số lượng.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-09-008, 013, 021, 060, 061 · API-09-030, 052, 087, 214, 217 · NFR-09-014 · BR-09-056.

**Tiền điều kiện, dữ liệu.** T90; canary `DH-CANARY-export` trong trường `SENSITIVE` của các đối tượng nguồn.

**Các bước.**

1. Tạo năm loại tệp xuất; tải về; tìm canary và CCCD giả.

**Kết quả mong đợi.** 0 lần xuất hiện; tệp có thân "đã che"; KT: có cho từng lần xuất.
:::

#### TC-09-130 · ZAP ASVS 5.0 mức 2 trên control plane và data plane (mTLS, ReDoS, tiêm mẫu) <!--k:sec-zap-->

::: dac-ta
**Mục đích.** Chứng minh bề mặt tấn công đạt ASVS và data plane chỉ nhận chứng chỉ DU.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP.

**Truy vết.** FR-09-005, 019, 027, 028 · API-09-026, 227, 229 · ERR-09-016, 111.

**Tiền điều kiện, dữ liệu.** STAGING; control plane qua APISIX; data plane nội bộ mTLS.

**Các bước.**

1. Chạy ZAP active scan control plane có xác thực.
2. Gọi data plane không chứng chỉ, chứng chỉ hết hạn, chứng chỉ của tenant khác.
3. Gửi mẫu phát hiện ReDoS, thân JSON lồng sâu, mẫu che chứa mã.

**Kết quả mong đợi.** Không lỗi mức cao; bước 2 từ chối ở kênh TLS; bước 3 `422` ERR-09-016 hoặc `400`, dịch vụ không tăng độ trễ.
:::

### TS-09-38 · Đóng an toàn, chịu lỗi và phục hồi

**Mục tiêu.** Chứng minh hành vi khi mất PH-09, Kafka, nhật ký, CSDL, nút; thao tác đặc quyền đóng an toàn; phục hồi đạt RTO, RPO.

**Phủ.** NFR-09-006, 007, 013, 021; FR-09-018, 027, 028; BR-09-018, 027, 057; ERR-09-010, 105.

#### TC-09-131 · Mất nhật ký PH-13: mọi thao tác đặc quyền bị từ chối <!--k:ft-priv-sweep-->

::: dac-ta
**Mục đích.** Chứng minh không thao tác đặc quyền nào chạy khi không ghi được kiểm toán.

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-09-013 · BR-09-057 · ERR-09-010 · FR-09-007, 029, 033, 034, 043, 060 · API-09-006, 102, 124, 118, 161, 213.

**Tiền điều kiện, dữ liệu.** T94; sáu thao tác đặc quyền sẵn sàng (gỡ nhãn, xem đầy đủ, khôi phục, hủy khóa, xóa mật mã, đóng vi phạm); PH-13 `503`.

**Các bước.**

1. Ngừng PH-13; gọi sáu thao tác.
2. Bật PH-13; gọi lại.

**Kết quả mong đợi.** Bước 1 sáu `503` ERR-09-010, không đổi trạng thái. Bước 2 sáu thao tác thực hiện được, mỗi thao tác một bản ghi KT. Thao tác thường vẫn chạy với kiểm toán hàng đợi.
:::

#### TC-09-132 · Kafka ngừng: sự kiện nằm ở outbox, phát lại đủ, không trùng tác động <!--k:ft-outbox-->

::: dac-ta
**Mục đích.** Chứng minh không mất sự kiện thu hồi.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-09-017, 018 · EVT-09-08, 11 · NFR-09-005.

**Tiền điều kiện, dữ liệu.** T94; Kafka dừng 10 phút; thu hồi 3 chấp thuận trong lúc dừng.

**Các bước.**

1. Dừng Kafka; DO1 thu hồi 3 chấp thuận.
2. Bật Kafka.

**Kết quả mong đợi.** Ba hàng outbox chờ; sau khi Kafka lên đủ 3 EVT: `purpose-grant.revoked`, mỗi sự kiện đúng một lần theo khóa idempotent; trong lúc dừng, kênh bundle p99 ≤ 60 giây vẫn thu hồi hiệu lực ở OPA.
:::

#### TC-09-133 · Mất CSDL chính: RTO ≤ 30 phút, RPO ≤ 5 phút, mất một nút data plane <!--k:ft-db-dr-->

::: dac-ta
**Mục đích.** Chứng minh diễn tập DR (ADR-034) và khả năng chịu mất nút.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-09-021, 006 · FR-09-018.

**Tiền điều kiện, dữ liệu.** T94; `pg-core` có bản sao đồng bộ; data plane 3 bản sao trên 3 nút; tải 1.000 yêu cầu mỗi giây.

**Các bước.**

1. Ghi 10 phút; tắt PostgreSQL chính; đo đến khi `ph09_privacy` ghi lại được.
2. Xóa một pod data plane.

**Kết quả mong đợi.** Bước 1 mất dữ liệu ≤ 5 phút, khôi phục ≤ 30 phút. Bước 2 thông lượng giảm ≤ 33 %, 0 yêu cầu quyết định trả sai (chỉ chậm hoặc `5xx` tạm thời), PEP dùng đệm.
:::

#### TC-09-134 · Job quét hoặc ẩn danh bị dừng giữa chừng: không để lại tập dở dang <!--k:ft-job-kill-->

::: dac-ta
**Mục đích.** Chứng minh job lỗi kết thúc `FAILED`, không phát hành tập hoặc kết quả dở.

**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-09-005, 036 · API-09-020, 130 · BR-09-034.

**Tiền điều kiện, dữ liệu.** T94; job quét và job ARX đang `RUNNING`.

**Các bước.**

1. `kubectl delete pod` Job quét; Job ARX.

**Kết quả mong đợi.** Trạng thái `FAILED`, không tập `READY`, tệp tạm ở Garage bị dọn, chạy lại được, không kết quả quét một nửa.
:::

### TS-09-39 · Hiệu lực tức thời và đồng hồ

**Mục tiêu.** Chứng minh thu hồi chấp thuận có hiệu lực ≤ 15 giây, đồng bộ bundle p99 ≤ 60 giây, phiếu xem 60 giây, đồng hồ vi phạm bền qua khởi động lại.

**Phủ.** NFR-09-005, 015, 017, 024, 025; BR-09-017, 018, 051, 062; FR-09-017, 018, 029, 059; EVT-09-08.

#### TC-09-135 · Thu hồi chấp thuận có hiệu lực tại điểm thực thi ≤ 15 giây <!--k:rev-15s-->

::: dac-ta
**Mục đích.** Đo độ trễ thu hồi, tạm dừng bằng sự kiện đẩy; kênh bundle là dự phòng.

**Loại.** Hiệu năng, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-09-017, 019 · NFR-09-005, 024 · BR-09-017 · EVT-09-08 · API-09-073, 227.

**Tiền điều kiện, dữ liệu.** T97; 3 PEP (PH-03, PH-04, PH-14) bật đệm; 100 chấp thuận `ACTIVE`; mỗi PEP gọi `purpose:decide` 10 lượt mỗi giây.

**Các bước.**

1. DO1 thu hồi 100 chấp thuận lần lượt; đo từ `:revoke` đến lượt `deny` đầu tiên ở từng PEP.
2. Lặp với `:suspend`.
3. Chặn kênh sự kiện đẩy, thu hồi 10 chấp thuận.

**Kết quả mong đợi.** Bước 1 và 2 p95 ≤ 15 giây, tối đa ≤ 15 giây. Bước 3 hiệu lực qua bundle p99 ≤ 60 giây.
:::

#### TC-09-136 · Đồng bộ chính sách và chấp thuận tới mọi OPA p99 ≤ 60 giây <!--k:sync-60s-->

::: dac-ta
**Mục đích.** Đo NFR-09-005 và OPA nạp ≤ 2 giây.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-09-005, 020 · FR-09-018 · API-09-078 · EVT-09-11.

**Tiền điều kiện, dữ liệu.** T97; 3 OPA; 3.000 chấp thuận hiệu lực; bundle gần 5 MB.

**Các bước.**

1. Thực hiện 200 thay đổi chấp thuận rải 20 phút; đo `bundle_loaded` từng OPA.

**Kết quả mong đợi.** p99 ≤ 60 giây; bundle ≤ 5 MB; OPA nạp ≤ 2 giây.
:::

#### TC-09-137 · Phiếu xem đầy đủ hết hạn đúng 60 giây ± 1 giây <!--k:clk-reveal-->

::: dac-ta
**Mục đích.** Đo độ chính xác hết hạn của phiếu và việc không ghi đĩa.

**Loại.** Biên.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** NFR-09-015 · FR-09-029 · API-09-236 · BR-09-026.

**Tiền điều kiện, dữ liệu.** T90; đồng hồ thực; `09.mask.reveal-seconds = 60`.

**Các bước.**

1. Cấp phiếu 20 lần; gọi `:verify` ở giây 59, 60, 61.

**Kết quả mong đợi.** Hết hạn ở 60 ± 1 giây; giây 59 `200`, giây 61 `403` ERR-09-112; giá trị rõ không có trên đĩa nút DU.
:::

#### TC-09-138 · Đồng hồ 72 giờ bền qua khởi động lại và đổi múi giờ <!--k:clk-restart-->

::: dac-ta
**Mục đích.** Chứng minh đồng hồ không đặt lại khi dịch vụ khởi động lại và cảnh báo không bị bỏ sót hay lặp.

**Loại.** Chịu lỗi, Biên.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-09-017 · BR-09-054 · FR-09-059 · EVT-09-31.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; vụ việc `detectedAt` = T0; múi giờ hiển thị `Asia/Ho_Chi_Minh`, lưu UTC.

**Các bước.**

1. Tiến đến T0+23 giờ 59 phút; xóa pod rồi chờ dịch vụ lên.
2. Tiến đến T0+24 giờ, +48 giờ.

**Kết quả mong đợi.** EVT: `breach.deadline-near` đúng một lần mỗi mốc ± 1 phút; `clock` hiển thị còn đúng thời gian; không mốc nào lặp lại sau khởi động.
:::

#### TC-09-150 · Đệm quyết định tối đa 15 giây cho ALLOW, 5 giây cho DENY <!--k:cache-decision-->

::: dac-ta
**Mục đích.** Chứng minh BR-09-062: thư viện `dh-privacy-client` không đệm quá trần, để không dò được từng trường qua kết quả đệm.

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-09-019 · API-09-227 · ERR-09-078 · BR-09-062 · NFR-09-024 · EVT-09-08.

**Tiền điều kiện, dữ liệu.** T97; PEP dùng `dh-privacy-client`; `09.decision.cache-seconds = 15`; chấp thuận G1 `ACTIVE`, trường `cccd` chưa thuộc G1; đồng hồ giả.

**Các bước.**

1. PEP gọi `purpose:decide` cho trường được phép ở giây 0, 10 và 16.
2. PEP gọi cho `cccd` (bị từ chối) ở giây 0, 3 và 6.
3. Đặt `09.decision.cache-seconds = 3`; lặp bước 2 cách nhau 4 giây.
4. Khi quyết định `ALLOW` còn trong đệm, DO thu hồi G1.
5. TA đặt `09.decision.cache-seconds = 30`.

**Kết quả mong đợi.** Bước 1 chỉ lượt giây 0 và 16 tới PH-09, lượt giây 10 lấy từ đệm. Bước 2 lượt giây 3 lấy từ đệm, lượt giây 6 tới PH-09 vì `DENY` chỉ đệm 5 giây. Bước 3 cả hai lượt tới PH-09 (tham số nhỏ hơn 5 giây thì lấy tham số). Bước 4 đệm bị xóa ngay, lượt kế tiếp bị từ chối trong ≤ 15 giây (NFR-09-024). Bước 5 `422` ERR-09-078 "Giá trị của 09.decision.cache-seconds ngoài miền cho phép 0…15."
:::

### TS-09-40 · Hiệu năng, quy mô và quan sát

**Mục tiêu.** Chứng minh các NFR-09 còn lại ở hồ sơ tỉnh vừa trên PERF.

**Phủ.** NFR-09-002, 006, 012, 013, 016, 020, 022, 023.

#### TC-09-139 · Kế hoạch che p95 ≤ 50 ms với 200 trường <!--k:perf-plan-->

::: dac-ta
**Mục đích.** Đo NFR-09-002.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-09-002 · API-09-228.

**Tiền điều kiện, dữ liệu.** T97; 3 bản sao; kế hoạch 200 trường.

**Các bước.**

1. k6 1.000 lượt mỗi giây 15 phút `mask-plans:resolve`, 30 % trúng `304`.

**Kết quả mong đợi.** p95 ≤ 50 ms khi gọi trực tiếp, trúng đệm ≤ 2 ms, 0 lỗi `5xx`.
:::

#### TC-09-140 · Ghi kiểm toán ≤ 100 ms, phủ 100 % thao tác ghi và đặc quyền <!--k:perf-audit-->

::: dac-ta
**Mục đích.** Chứng minh số lượt ở cổng bằng số bản ghi PH-13.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-09-013 · FR-09-061 · API-09-215.

**Tiền điều kiện, dữ liệu.** T99; 10.000 thao tác ghi và 500 thao tác đặc quyền.

**Các bước.**

1. Chạy các thao tác; đối chiếu số lượt APISIX với số bản ghi PH-13.

**Kết quả mong đợi.** 100 % có bản ghi; ghi p95 ≤ 100 ms; không thao tác nào thiếu.
:::

#### TC-09-141 · Ẩn danh hóa 1 triệu bản ghi, 10 thuộc tính ≤ 15 phút <!--k:perf-anon-1m-->

::: dac-ta
**Mục đích.** Đo NFR-09-012.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** NFR-09-012 · FR-09-036 · API-09-130.

**Tiền điều kiện, dữ liệu.** T98 F-ANON-1M; Job 8 vCPU, 32 GB (giả định theo Q09-44).

**Các bước.**

1. Chạy job ẩn danh hóa k = 10.

**Kết quả mong đợi.** `COMPLETED` ≤ 15 phút; k thực tế ≥ 10; rủi ro không `HIGH`.
:::

#### TC-09-142 · Danh sách 50.000 phần tử p95 ≤ 1 giây, quy mô 200 HTTT <!--k:perf-ui-->

::: dac-ta
**Mục đích.** Đo NFR-09-023 và NFR-09-020.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-09-023, 020 · API-09-010 · UI-09-02.

**Tiền điều kiện, dữ liệu.** T98; 50.000 phần tử; 3.000 chấp thuận; 2 triệu bản ghi kiểm toán.

**Các bước.**

1. k6 `GET /data-elements` có lọc; tải UI-09-02 bằng Playwright.

**Kết quả mong đợi.** p95 ≤ 1 giây; bảng cuộn ảo không treo; truy vấn có chỉ mục.
:::

#### TC-09-143 · Khả dụng data plane ≥ 99,95 % trong 24 giờ thử và chỉ số quan sát <!--k:perf-avail-->

::: dac-ta
**Mục đích.** Đo khả dụng và sự có mặt đủ tám chỉ số của NFR-09-022.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-09-006, 022 · API-09-227.

**Tiền điều kiện, dữ liệu.** PERF; 3 bản sao; thăm dò 1 lượt mỗi giây; chỉ số Prometheus.

**Các bước.**

1. Chạy thăm dò 24 giờ, kèm một lần khởi động cuốn chiếu.
2. Đọc `privacy_decide_total`, `privacy_mask_total`, `privacy_blocked_total`, `privacy_bundle_age_seconds`…

**Kết quả mong đợi.** Khả dụng ≥ 99,95 % (suy ra tháng); đủ tám chỉ số có nhãn đúng; cảnh báo hiện ở UI-09-01.
:::

#### TC-09-144 · 98 % yêu cầu chủ thể đóng trong hạn <!--k:perf-dsr-sla-->

::: dac-ta
**Mục đích.** Chứng minh cách tính chỉ số tuân thủ hạn (theo quý).

**Loại.** Hiệu năng.

**Ưu tiên.** P3.

**Tự động.** JOB.

**Truy vết.** NFR-09-016 · FR-09-049 · API-09-181.

**Tiền điều kiện, dữ liệu.** T95 đồng hồ giả; 500 yêu cầu mô phỏng với phân bố xử lý giả định.

**Các bước.**

1. Chạy mô phỏng; `GET /subject-request-reports`.

**Kết quả mong đợi.** Tỷ lệ báo cáo khớp số tính độc lập; nhắc trước 3 ngày làm việc đạt 100 %.
:::

### TS-09-41 · Truy cập giao diện và hợp đồng API

**Mục tiêu.** Chứng minh 22 màn hình dùng được bằng bàn phím và trình đọc màn hình, và hợp đồng OpenAPI khớp FRS.

**Phủ.** UI-09-01…22; API-09-001…245; NFR-09-023.

#### TC-09-145 · Truy cập 22 màn hình, trạng thái rỗng, lỗi và hộp thoại xem đầy đủ <!--k:ui-a11y-->

::: dac-ta
**Mục đích.** Chứng minh WCAG 2.1 AA, route đúng, tab con và query giữ được khi quay lại.

**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-09-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 · NFR-09-023.

**Tiền điều kiện, dữ liệu.** STAGING; Playwright, axe-core; U-T90-SO, DO1, TA, AU, VW.

**Các bước.**

1. Duyệt từng route `/du-lieu/quyen-rieng-tu/...` bằng vai phù hợp; chạy axe; thao tác chỉ bằng bàn phím.
2. Mở UI-09-22 từ màn PH-06: nhập lý do, quan sát đếm ngược.

**Kết quả mong đợi.** 0 lỗi axe mức nghiêm trọng; vai không phù hợp thấy 403 đúng; UI-09-22 đặt tiêu điểm vào ô lý do, thông báo đếm ngược cho trình đọc màn hình và tự che ở giây 60.
:::

#### TC-09-146 · OpenAPI `/api/privacy/v1` và `/privacy/v1` khớp FRS 9.4 <!--k:ct-openapi-->

::: dac-ta
**Mục đích.** Chứng minh 245 API, mã lỗi và enum đúng nguồn chuẩn (FRS Phụ lục A).

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** CT.

**Truy vết.** FR-09-064 · API-09-001, 227 · NFR-09-020.

**Tiền điều kiện, dữ liệu.** `03-thiet-ke/api/ph09/openapi-privacy.yaml`; Spectral, oasdiff.

**Các bước.**

1. Chạy Spectral; so mã API và đường dẫn với bảng FRS 9.4; so enum với Phụ lục A.

**Kết quả mong đợi.** 0 lệch mã, đường dẫn, phương thức; mọi POST ghi có `Idempotency-Key`; mọi lỗi theo RFC 9457 có `code`, `traceId`.
:::

### TS-09-42 · Tương đương hệ cũ và chức năng cũ của SRS repo

**Mục tiêu.** Chứng minh LGC-TOOL-012 được nâng cấp mà không mất chức năng, LGC-NGSP-003 giữ nguyên chức năng có thêm kiểm soát mục đích, và nêu lệch với SRS cũ.

**Phủ.** LGC-TOOL-012; LGC-NGSP-003; FR-09-003, 004, 014…022, 023…030, 031…038.

#### TC-09-147 · Bốn chế độ cũ none, mask, pseudonymize, anonymize và quy tắc che cũ còn đạt được <!--k:leg-tool012-->

::: dac-ta
**Mục đích.** Chứng minh chính sách tập trung tái tạo được kết quả của bước che cấu hình tay từng luồng (hệ cũ) và có thêm kiểu mới.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** LGC-TOOL-012 · FR-09-023, 024, 028, 032, 036 · API-09-091, 229 · UI-09-10.

**Tiền điều kiện, dữ liệu.** T90; F-MSG; quy tắc che cũ của SRS (số định danh giữ 4 đầu 4 cuối, họ tên che tên, điện thoại giữ 3 đầu 2 cuối).

**Các bước.**

1. Cấu hình mẫu `KEEP_FIRST_LAST` n = 4 cho số định danh; `none` thành `NONE`, `mask` thành `PARTIAL`, `pseudonymize` thành `KEYED_HASH` hoặc `TOKENIZE`, `anonymize` thành job ARX.
2. `messages:apply` F-MSG cho từng kiểu.

**Kết quả mong đợi.** CCCD `001090000101` cho `0010****0101`; mỗi chế độ cũ có kết quả tương đương; thêm `GENERALIZE`, `DROP`, `REPLACE` (nâng cấp); một chính sách thay cấu hình riêng từng luồng, có phiên bản.
:::

#### TC-09-148 · Tra cứu hộ gia đình giữ nguyên kết quả, thêm kiểm soát mục đích và ghi vết <!--k:leg-ngsp003-->

::: dac-ta
**Mục đích.** Chứng minh chức năng tra cứu của PH-14 không đổi kết quả và PH-09 chỉ thêm kiểm soát (FRS 11.1).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** LGC-NGSP-003 · FR-09-014, 015, 016, 019, 020 · API-09-227, 237 · ERR-09-102.

**Tiền điều kiện, dữ liệu.** T90; PH-14 giả lập trả kết quả tra BHXH; HTTT-BH có chấp thuận `MD-TRACUU-HGD`; HTTT-TK không có.

**Các bước.**

1. HTTT-BH tra mã BHXH hộ gia đình qua PH-14 khi có chấp thuận.
2. HTTT-TK tra cùng mã.
3. Thu hồi chấp thuận của HTTT-BH; tra lại.

**Kết quả mong đợi.** Bước 1 kết quả giống trước khi có PH-09, trường được phép đúng điều kiện chấp thuận, lượt khai thác được đếm. Bước 2 và 3 `403` ERR-09-102, ghi vết và báo lượt.
:::

#### TC-09-149 · Đối chiếu FR-09-001…009 của SRS cũ với hành vi mới <!--k:leg-srs-fr-->

::: dac-ta
**Mục đích.** Chứng minh từng điểm của SRS cũ có chỗ xử lý, và các khác biệt chủ ý của FRS được kiểm đúng hành vi mới.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-09-004, 007, 029, 033, 034, 035, 036, 037, 038 · BR-09-001, 032, 035 · ERR-09-053, 054 · LGC-TOOL-012.

**Tiền điều kiện, dữ liệu.** T90, T96; bảng so sánh SRS cũ (FR-09-001…009) và FRS 0.2.

**Các bước.**

1. Trường chưa phân loại: SRS cũ coi là mức mật và chặn; chạy `classification:check` với trường chưa phân loại.
2. Khôi phục hàng loạt: SRS cũ yêu cầu duyệt riêng khi hơn 10 bí danh; thử 11 và 101 token.
3. Ẩn danh hóa AI: SRS cũ yêu cầu k cao hơn thông thường; thử k = 10 và k = 20 cho `AI_TRAINING`.
4. Ẩn danh hóa còn dưới 30 % bản ghi: SRS cũ cảnh báo; chạy F-ANON-S.

**Kết quả mong đợi.** Bước 1 FRS mới xử lý như `SENSITIVE` (BR-09-001) và không chặn bản tin, khác SRS cũ (ĐN-TC-05). Bước 2 11 token vẫn cần chuỗi duyệt ba người, 101 token `422` ERR-09-049. Bước 3 k = 10 được chấp nhận, không có ngưỡng k riêng cho AI (ĐN-TC-06). Bước 4 từ chối `422` ERR-09-054, chặt hơn cảnh báo cũ.
:::


## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Hai phiên 90 phút cho mỗi điều lệ: (1) tìm cách lấy giá trị DLCN dạng rõ từ giao diện, API, log, tệp xuất, sự kiện, bản sao lưu; (2) tìm cách để HTTT khai thác dữ liệu `SENSITIVE` khi không có chấp thuận, qua API, topic, luồng, xuất, tra cứu hộ gia đình. Ghi lỗi theo mục 1.6.

### 6.2. Diễn tập vi phạm 72 giờ

SO và TO diễn tập một vụ việc giả định trên T95 với đồng hồ thật rút ngắn: ghi nhận, đánh giá, soạn thông báo Cục A05 và chủ thể, đóng hồ sơ; đo thời gian từ phát hiện đến thông báo và kiểm cảnh báo ở các mốc.

### 6.3. Diễn tập xóa mật mã và khôi phục sao lưu

Diễn tập thủ công trên T95: xóa mật mã tenant sau bàn giao, thử giải mã bản sao lưu bằng khóa đã hủy, khôi phục một bản sao lưu 20 ngày tuổi và kiểm bước áp lại danh sách xóa (BR-09-040).

## 7. Nghiệm thu người dùng tương đương hệ cũ

Hệ cũ chỉ có hai chức năng liên quan: LGC-TOOL-012 (bước mã hóa và che dữ liệu nhạy cảm cấu hình riêng từng luồng, nâng cấp thành chính sách tập trung) và LGC-NGSP-003 (tra cứu bảo hiểm xã hội hộ gia đình, giữ nguyên ở PH-14 và PH-09 thêm kiểm soát mục đích). Cán bộ của tỉnh thí điểm tự thực hiện các việc ở 7.1 trên UAT; đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng.

### 7.1. Kịch bản nghiệm thu theo vai trò

Chín việc dưới đây phủ hai mã hệ cũ và các nhóm FR cốt lõi; cột cuối dẫn tới kịch bản tự động tương ứng.

| Mã | Việc cần làm | Liên quan hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | DO thẩm định và chấp thuận có điều kiện yêu cầu khai thác của HTTT-BH | LGC-NGSP-003 | Chấp thuận ACTIVE kèm điều kiện, HTTT-BH tra được đúng trường, HTTT-TK bị từ chối | FR-09-015, 016, 019 | TS-09-09, 10, 13, 42 |
| UAT-02 | DO thu hồi chấp thuận đang dùng | LGC-NGSP-003 | HTTT-BH bị chặn trong 15 giây, có sự kiện và kiểm toán | FR-09-017, 018 | TS-09-11, 39 |
| UAT-03 | TA soạn chính sách che, mô phỏng, DA duyệt | LGC-TOOL-012 | Kết quả xem trước đúng mẫu che, phát hành bốn mắt, có phiên bản và quay lại được | FR-09-024, 025, 026 | TS-09-16, 17, 42 |
| UAT-04 | SO xem giá trị đầy đủ một trường Nhạy cảm | LGC-TOOL-012 | Hộp thoại nhập lý do, đếm ngược 60 giây, tự che lại, có nhật ký | FR-09-029 | TS-09-20 |
| UAT-05 | SO tiếp nhận, xác minh, tra cứu và trả lời yêu cầu của chủ thể | — | Báo cáo đúng hạn, tra cứu theo băm, không lộ định danh | FR-09-045, 046, 047, 050 | TS-09-29, 30 |
| UAT-06 | SO ghi nhận vi phạm và theo dõi đồng hồ 72 giờ | — | Cảnh báo ở 24, 48, 60 giờ, thông báo Cục A05 có bằng chứng | FR-09-058, 059, 060 | TS-09-33, 39 |
| UAT-07 | DS chạy ẩn danh hóa tập dữ liệu cho AI | — | Tập đạt k ≥ 10, báo cáo rủi ro, rủi ro HIGH bị chặn | FR-09-036, 037, 038 | TS-09-25, 26 |
| UAT-08 | SO lập sổ hoạt động xử lý và hồ sơ DPIA, xuất cho Cục A05 | — | Hoạt động ACTIVE sau duyệt bốn mắt, hồ sơ xuất đủ mục | FR-09-009, 010, 055, 057 | TS-09-07, 32 |
| UAT-09 | SO xác nhận phân loại trường và thử kích hoạt hợp đồng Nhạy cảm | — | Hợp đồng bị chặn tới khi có chấp thuận và hoạt động xử lý | FR-09-004, 022 | TS-09-03, 15 |

: Kịch bản nghiệm thu UAT-01…09 theo vai trò

### 7.2. Đối chiếu mười một FR cũ của SRS repo

SRS repo (`docs/07-srs/SRS-PH-09-privacy.md`) có 11 FR; FRS 0.2 mở rộng thành 64. Bảng nối từng FR cũ với FR mới, nêu khác biệt chủ ý và ca chứng minh.

| FR cũ | Nội dung cũ | FR mới | Khác biệt | TC |
|---|---|---|---|---|
| 001 | Thang phân loại bốn cấp, trường chưa phân loại mặc định mức cao nhất | FR-09-001, 004 | Mức `MAT` tách thành nhãn chặn `STATE_SECRET`; bốn mức là `DataClass` | TC-09-001, TC-09-007 |
| 002 | Chặn dữ liệu bí mật nhà nước, trường chưa phân loại coi như mật | FR-09-007 | Trường chưa phân loại là `SENSITIVE`, không chặn (BR-09-001) | TC-09-017, TC-09-149 |
| 003 | Che theo `fieldMask` `full`, `masked`, `hidden` | FR-09-023, 024, 027, 028 | Kế hoạch che theo vai trò, mục đích, kênh; `hidden` thành `DROP` | TC-09-063, TC-09-147 |
| 004 | Giả danh hóa đảo ngược, khóa theo miền | FR-09-031, 032 | HMAC không đảo ngược hoặc token qua transit, không bảng ánh xạ | TC-09-078, TC-09-079 |
| 005 | Khôi phục giá trị gốc, hơn 10 bí danh cần duyệt riêng | FR-09-033 | Tối đa 100, ba người khác nhau, MFA | TC-09-082, TC-09-083 |
| 006 | Vòng đời khóa, xoay 365 ngày | FR-09-034 | Giãn cách tối thiểu 30 ngày, hủy có hai người và chờ | TC-09-076, TC-09-077 |
| 007 | Ẩn danh hóa, k, ba vòng tổng quát hóa | FR-09-035, 036 | k ≥ 10 (sàn), từ chối khi còn dưới 30 % bản ghi | TC-09-086, TC-09-087 |
| 008 | Đánh giá rủi ro tái định danh | FR-09-037 | Ba mô hình, `HIGH` chặn, `MEDIUM` cần SO | TC-09-087 |
| 009 | Ẩn danh hóa dữ liệu huấn luyện AI | FR-09-038 | Không ngưỡng k riêng cho AI; `RESTRICTED` cần cờ tenant | TC-09-090, TC-09-149 |
| 010 | Ghi vết thao tác bảo vệ dữ liệu | FR-09-061 | Nhật ký không giá trị `SENSITIVE`, tra theo quyền | TC-09-116 |
| 011 | Báo cáo tuân thủ | FR-09-062, 063 | Bảng điều khiển và báo cáo theo lịch | TC-09-117 |

: Đối chiếu FR cũ của SRS repo với FR mới và ca kiểm thử

## 8. Ma trận truy vết

Ma trận nối FR, BR, ERR, NFR, EVT, API, UI và mã hệ cũ với test case; toàn bộ do công cụ sinh từ chính các ca nên không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-09. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph09/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | Dương | Âm | Đạt |
|---|---|---|---|---|---|
| FR-09-001 | Quản lý danh mục mức phân loại và nhãn chặn  | M | 001 | 001 | Có |
| FR-09-002 | Quản lý danh mục loại dữ liệu cá nhân | M | 001 | 001, 002 | Có |
| FR-09-003 | Đăng ký phần tử dữ liệu từ phân hệ, lược đồ  | M | 004, 005 | 005, 006, 119 | Có |
| FR-09-004 | Đề xuất, xác nhận phân loại trường (hạ mức c | M | 007, 009, 010, 149 | 008, 009, 010, 119, 124, 125, 149 | Có |
| FR-09-005 | Quét phát hiện trường nghi dữ liệu cá nhân c | S | 011 | 012 | Có |
| FR-09-006 | Tính và công bố mức phân loại của hợp đồng A | M | 014 | 015 | Có |
| FR-09-007 | Chặn dữ liệu bí mật nhà nước đi qua Datahub | M | 017, 019, 149 | 018, 019, 064, 149 | Có |
| FR-09-008 | Tra cứu, xuất danh mục phân loại và lịch sử  | S | 003 | 003 | Có |
| FR-09-009 | Lập hoạt động xử lý dữ liệu cá nhân | M | 021 | 022, 119, 124 | Có |
| FR-09-010 | Duyệt, phiên bản hóa hoạt động xử lý | M | 021 | 022, 125 | Có |
| FR-09-011 | Liên kết hoạt động xử lý với trường, API, to | M | 023 | 023 | Có |
| FR-09-012 | Quản lý danh mục cơ sở pháp lý và căn cứ văn | M | 025 | 026 | Có |
| FR-09-013 | Xuất sổ hoạt động xử lý theo mẫu | S | 024 | 024 | Có |
| FR-09-014 | Quản lý danh mục mục đích khai thác | M | 025, 148 | 026, 119, 148 | Có |
| FR-09-015 | Lập yêu cầu khai thác theo mục đích | M | 028, 030, 148 | 029, 030, 120, 124, 148 | Có |
| FR-09-016 | Thẩm định, chấp thuận có điều kiện hoặc từ c | M | 031, 032, 148 | 032, 033, 125, 148 | Có |
| FR-09-017 | Gia hạn, sửa, tạm dừng, thu hồi chấp thuận v | M | 035, 036, 037, 038 | 035, 036, 120 | Có |
| FR-09-018 | Đồng bộ chấp thuận và chính sách sang bundle | M | 039, 042 | 040, 041 | Có |
| FR-09-019 | Quyết định mục đích trực tuyến cho điểm thực | M | 037, 042, 043, 046, 102, 148, 150 | 044, 045, 126, 148 | Có |
| FR-09-020 | Phát hiện khai thác vượt mục đích, vượt hạn  | S | 046, 048, 148 | 049, 148 | Có |
| FR-09-021 | Báo cáo khai thác theo mục đích | S | 050 | 050 | Có |
| FR-09-022 | Chặn kích hoạt hợp đồng mức Nhạy cảm khi chư | M | 052 | 051, 053 | Có |
| FR-09-023 | Quản lý kiểu che và mẫu che | M | 054, 147 | 056 | Có |
| FR-09-024 | Soạn chính sách che theo mức, loại dữ liệu c | M | 055, 147 | 056, 119 | Có |
| FR-09-025 | Mô phỏng chính sách che trên dữ liệu mẫu | S | 057 | 058 | Có |
| FR-09-026 | Duyệt, phát hành, phiên bản hóa chính sách c | M | 059 | 058, 059, 125 | Có |
| FR-09-027 | Trả kế hoạch che trực tuyến cho điểm thực th | M | 042, 060 | 062, 126 | Có |
| FR-09-028 | Áp che bản tin cho luồng PH-04 | M | 063, 147 | 064, 065, 126 | Có |
| FR-09-029 | Xem giá trị đầy đủ có lý do trong 60 giây | M | 068, 071, 149 | 069, 071, 124, 149 | Có |
| FR-09-030 | Cấu hình che cho log, trace và quét rò rỉ dữ | M | 072 | 073 | Có |
| FR-09-031 | Quản lý miền giả danh hóa theo tenant và mục | M | 075, 078 | 119 | Có |
| FR-09-032 | Giả danh hóa giá trị bằng HMAC hoặc token | M | 078, 079, 147 | 079, 080, 126 | Có |
| FR-09-033 | Khôi phục giá trị gốc từ token (đặc quyền, h | S | 079, 082, 149 | 079, 083, 120, 125, 149 | Có |
| FR-09-034 | Quản lý vòng đời khóa giả danh hóa trên Open | M | 076, 077, 149 | 076, 077, 125, 149 | Có |
| FR-09-035 | Cấu hình ẩn danh hóa | S | 088, 149 | 085, 125, 149 | Có |
| FR-09-036 | Ẩn danh hóa tập dữ liệu với k tối thiểu 10 | S | 086, 088, 147, 149 | 087, 149 | Có |
| FR-09-037 | Đánh giá rủi ro tái định danh | S | 086, 149 | 087, 149 | Có |
| FR-09-038 | Chuẩn bị dữ liệu cho AI và môi trường không  | M | 090, 149 | 091, 149 | Có |
| FR-09-039 | Quản lý tập dữ liệu đã ẩn danh và điều kiện  | C | 092 | 092 | Có |
| FR-09-040 | Lập lịch lưu giữ theo bảng và loại dữ liệu | M | 093 | 093, 119, 125 | Có |
| FR-09-041 | Tác vụ xóa hoặc giả danh hóa khi hết hạn và  | M | 094, 095 | 094, 095 | Có |
| FR-09-042 | Giữ pháp lý (tạm hoãn xóa) | M | 096 | 096 | Có |
| FR-09-043 | Xóa mật mã khi chấm dứt tenant | M | 097 | 098, 125 | Có |
| FR-09-044 | Báo cáo tuân thủ thời hạn lưu | S | 094 | 094 | Có |
| FR-09-045 | Tiếp nhận yêu cầu của chủ thể dữ liệu | M | 099 | 099, 120, 124, 127 | Có |
| FR-09-046 | Xác minh danh tính chủ thể | M | 100 | 100 | Có |
| FR-09-047 | Tra cứu dữ liệu về chủ thể theo băm định dan | M | 100 | 100 | Có |
| FR-09-048 | Phân công, chuyển xử lý cho PH-06, PH-19 hoặ | M | 101, 102 | 101 | Có |
| FR-09-049 | Theo dõi hạn xử lý, nhắc và quá hạn | M | 103 | 103 | Có |
| FR-09-050 | Trả lời chủ thể, đóng yêu cầu, lưu bằng chứn | M | 104 | 104 | Có |
| FR-09-051 | Báo cáo ai đã truy cập dữ liệu của chủ thể | S | 105 | 105 | Có |
| FR-09-052 | Quản lý mẫu sự đồng ý | M | 106 | 106, 108, 125 | Có |
| FR-09-053 | Ghi nhận, rút sự đồng ý và lưu bằng chứng | M | 107 | 107, 120 | Có |
| FR-09-054 | Tra cứu trạng thái đồng ý cho tiện ích không | C | 107 | 107, 108, 126 | Có |
| FR-09-055 | Lập hồ sơ đánh giá tác động xử lý dữ liệu cá | M | 109 | 110, 120 | Có |
| FR-09-056 | Duyệt, phiên bản hóa, nhắc cập nhật hồ sơ đá | M | 109, 111 | 110, 125 | Có |
| FR-09-057 | Xuất hồ sơ đánh giá tác động gửi Cục A05 | C | 109 | 110 | Có |
| FR-09-058 | Ghi nhận vi phạm dữ liệu cá nhân và đánh giá | M | 112 | 113, 120, 124 | Có |
| FR-09-059 | Đồng hồ 72 giờ, thông báo Cục A05 và chủ thể | M | 112, 114 | 113 | Có |
| FR-09-060 | Hồ sơ vi phạm, khắc phục và bài học | M | 115 | 113 | Có |
| FR-09-061 | Ghi vết thao tác bảo vệ dữ liệu | M | 116 | 116, 120, 121, 124 | Có |
| FR-09-062 | Bảng điều khiển tuân thủ quyền riêng tư | S | 117 | 117 | Có |
| FR-09-063 | Báo cáo tuân thủ định kỳ | C | 117 | 117 | Có |
| FR-09-064 | Cấu hình tham số PH-09 của tenant | M | 146 | 118, 119, 124, 127 | Có |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

Hai mã chức năng hệ cũ được PH-09 phủ theo FRS mục 11.1: LGC-TOOL-012 (nâng cấp che dữ liệu nhạy cảm thành chính sách tập trung) và LGC-NGSP-003 (tra cứu BHXH giữ nguyên ở PH-14, PH-09 thêm kiểm soát mục đích). Chức năng cũ FR-09-001…011 của SRS repo xem ở mục 7.2.

| LGC | FR của PH-09 | TC | UAT |
|---|---|---|---|
| LGC-TOOL-012 | 023, 024, 027, 028, 030, 031, 032, 036 | 042, 054, 055, 057, 060, 063, 072, 075 (+6) | UAT-03, UAT-04 |
| LGC-NGSP-003 | 014, 015, 016, 017, 018, 019, 020, 021, 022 | 025, 028, 030, 031, 032, 035, 036, 037 (+11) | UAT-01, UAT-02 |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Quy tắc nghiệp vụ → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-09-001 | 004, 014, 053, 060, 149 |
| BR-09-002 | 002, 009, 015 |
| BR-09-003 | 007, 008, 125 |
| BR-09-004 | 014, 015 |
| BR-09-005 | 017, 019, 044, 064 |
| BR-09-006 | 011 |
| BR-09-007 | 005, 010 |
| BR-09-008 | 023, 051, 052 |
| BR-09-009 | 021, 022 |
| BR-09-010…011 | 021 |
| BR-09-012 | 022 |
| BR-09-013 | 033 |
| BR-09-014 | 033, 125 |
| BR-09-015 | 027, 033, 035, 038 |
| BR-09-016 | 029, 031 |
| BR-09-017 | 037, 135 |
| BR-09-018 | 039, 040, 041 |
| BR-09-019 | 043, 051, 052 |
| BR-09-020 | 046 |
| BR-09-021 | 054 |
| BR-09-022 | 055, 060 |
| BR-09-023 | 058, 059 |
| BR-09-024 | 055 |
| BR-09-025 | 057, 063, 072, 074, 128 |
| BR-09-026 | 068, 069, 137 |
| BR-09-027 | 061 |
| BR-09-028 | 075, 078, 123 |
| BR-09-029 | 076, 078 |
| BR-09-030 | 079 |
| BR-09-031 | 078 |
| BR-09-032 | 082, 149 |
| BR-09-033 | 076, 077 |
| BR-09-034 | 086, 134 |
| BR-09-035 | 085, 086, 087, 089, 149 |
| BR-09-036 | 085, 088 |
| BR-09-037 | 090, 091 |
| BR-09-038 | 093 |
| BR-09-039 | 096 |
| BR-09-040 | 095 |
| BR-09-041 | 097, 098 |
| BR-09-042 | 100, 105 |
| BR-09-043 | 103 |
| BR-09-044 | 101, 105 |
| BR-09-045 | 099, 100 |
| BR-09-046 | 101 |
| BR-09-047 | 025, 044, 102 |
| BR-09-048 | 104 |
| BR-09-049 | 106, 108 |
| BR-09-050…051 | 107 |
| BR-09-052 | 109 |
| BR-09-053 | 111 |
| BR-09-054 | 112, 114, 138 |
| BR-09-055 | 113, 114 |
| BR-09-056 | 129 |
| BR-09-057 | 019, 020, 066, 070, 084, 131 |
| BR-09-058 | 074, 116, 128 |
| BR-09-059 | 118 |
| BR-09-060 | 003, 119, 120, 121, 122, 123 |
| BR-09-061 | 099, 127 |
| BR-09-062 | 150 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

Mã `ERR-09-001…078` thuộc control plane, `ERR-09-101…113` thuộc data plane; lỗi `401`, `403` do thiếu quyền dùng ERR-00-401, ERR-00-403.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-09-001 | 002, 003, 098, 119, 120 |
| ERR-09-002 | 002, 026 |
| ERR-09-003 | 001, 005, 029, 117 |
| ERR-09-004 | 127 |
| ERR-09-005 | 008, 009, 019, 022, 033, 059, 077, 083, 093, 097 (+3) |
| ERR-09-006 | 006, 010, 012, 030, 036, 037, 095, 098, 113 |
| ERR-09-007 | 032, 036, 049, 069 |
| ERR-09-008 | 029, 033, 124 |
| ERR-09-009 | 029 |
| ERR-09-010 | 020, 070, 084, 131 |
| ERR-09-011 | 002, 026 |
| ERR-09-012 | 008 |
| ERR-09-013 | 009 |
| ERR-09-014…015 | 005 |
| ERR-09-016 | 012, 130 |
| ERR-09-017 | 012 |
| ERR-09-018 | 018 |
| ERR-09-019 | 019 |
| ERR-09-020 | 022 |
| ERR-09-021 | 022, 026 |
| ERR-09-022 | 023 |
| ERR-09-023 | 023, 051 |
| ERR-09-024 | 022, 108 |
| ERR-09-025 | 024 |
| ERR-09-026…028 | 029 |
| ERR-09-029 | 033 |
| ERR-09-030 | 033, 035 |
| ERR-09-031 | 035 |
| ERR-09-032…033 | 040 |
| ERR-09-034 | 049 |
| ERR-09-035 | 051, 053 |
| ERR-09-036 | 050 |
| ERR-09-037…038 | 056 |
| ERR-09-039…040 | 058 |
| ERR-09-041…043 | 069 |
| ERR-09-044 | 073 |
| ERR-09-045 | 075 |
| ERR-09-046 | 077 |
| ERR-09-047 | 076 |
| ERR-09-048 | 079, 083 |
| ERR-09-049 | 083, 149 |
| ERR-09-050 | 083 |
| ERR-09-051…052 | 085 |
| ERR-09-053…054 | 087, 149 |
| ERR-09-055 | 091 |
| ERR-09-056 | 092 |
| ERR-09-057 | 093 |
| ERR-09-058…059 | 096 |
| ERR-09-060 | 098 |
| ERR-09-061 | 094 |
| ERR-09-062 | 099 |
| ERR-09-063 | 100, 105 |
| ERR-09-064 | 099 |
| ERR-09-065 | 100 |
| ERR-09-066 | 101 |
| ERR-09-067…068 | 104 |
| ERR-09-069…070 | 106 |
| ERR-09-071…072 | 107 |
| ERR-09-073…074 | 110 |
| ERR-09-075…077 | 113 |
| ERR-09-078 | 027, 049, 118, 150 |
| ERR-09-079 | 116 |
| ERR-09-080 | 058 |
| ERR-09-081 | 127 |
| ERR-09-082 | 090 |
| ERR-09-101 | 017, 044, 064 |
| ERR-09-102 | 037, 038, 044, 122, 148 |
| ERR-09-103 | 044 |
| ERR-09-104 | 044, 102 |
| ERR-09-105 | 061 |
| ERR-09-106…107 | 065 |
| ERR-09-108 | 066, 080 |
| ERR-09-109 | 065, 080 |
| ERR-09-110 | 066 |
| ERR-09-111 | 045, 062, 122, 126, 130 |
| ERR-09-112 | 068, 137 |
| ERR-09-113 | 045 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-09-001 | 043, 047 |
| NFR-09-002 | 060, 139 |
| NFR-09-003 | 063, 067 |
| NFR-09-004 | 047 |
| NFR-09-005 | 039, 132, 135, 136 |
| NFR-09-006 | 133, 143 |
| NFR-09-007 | 041, 061 |
| NFR-09-008 | 042 |
| NFR-09-009 | 013 |
| NFR-09-010 | 016 |
| NFR-09-011 | 078, 081 |
| NFR-09-012 | 086, 089, 141 |
| NFR-09-013 | 131, 140 |
| NFR-09-014 | 072, 074, 128, 129 |
| NFR-09-015 | 068, 137 |
| NFR-09-016 | 034, 103, 144 |
| NFR-09-017 | 114, 138 |
| NFR-09-018 | 094 |
| NFR-09-019 | 119, 120, 121, 122, 123 |
| NFR-09-020 | 136, 142, 146 |
| NFR-09-021 | 133 |
| NFR-09-022 | 117, 143 |
| NFR-09-023 | 142, 145 |
| NFR-09-024 | 135, 150 |
| NFR-09-025 | 038 |
| NFR-09-026 | 046 |

: Yêu cầu phi chức năng tới test case

### 8.6. Sự kiện → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-09-01 | 007, 062, 123, 128 |
| EVT-09-02 | 011, 123, 128 |
| EVT-09-03 | 014, 123, 128 |
| EVT-09-04 | 021, 123, 128 |
| EVT-09-05 | 028, 123, 128 |
| EVT-09-06 | 031, 035, 123, 128 |
| EVT-09-07 | 036, 123, 128 |
| EVT-09-08 | 037, 123, 128, 132, 135, 150 |
| EVT-09-09…10 | 038, 123, 128 |
| EVT-09-11 | 039, 123, 128, 132, 136 |
| EVT-09-12 | 059, 062, 123, 128 |
| EVT-09-13 | 046, 048, 123, 128 |
| EVT-09-14 | 017, 064, 123, 128 |
| EVT-09-15 | 071, 123, 128 |
| EVT-09-16 | 076, 123, 128 |
| EVT-09-17 | 082, 123, 128 |
| EVT-09-18 | 090, 092, 123, 128 |
| EVT-09-19 | 094, 123, 128 |
| EVT-09-20 | 096, 123, 128 |
| EVT-09-21 | 097, 123, 128 |
| EVT-09-22 | 099, 123, 128 |
| EVT-09-23…24 | 103, 123, 128 |
| EVT-09-25 | 104, 123, 128 |
| EVT-09-26 | 102, 123, 128 |
| EVT-09-27…28 | 107, 123, 128 |
| EVT-09-29 | 111, 123, 128 |
| EVT-09-30 | 112, 123, 128 |
| EVT-09-31 | 114, 123, 128, 138 |
| EVT-09-32 | 114, 123, 128 |

: Sự kiện tới test case

### 8.7. API → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ api này.

| Mã | Test case |
|---|---|
| API-09-001 | 001, 146 |
| API-09-002 | 001 |
| API-09-004 | 017 |
| API-09-005 | 019 |
| API-09-006 | 019, 020, 131 |
| API-09-007 | 001 |
| API-09-008…009 | 002 |
| API-09-010 | 004, 006, 142 |
| API-09-011 | 004, 119 |
| API-09-012 | 004, 018 |
| API-09-013 | 005, 018 |
| API-09-014 | 005 |
| API-09-015 | 007, 008, 009, 124 |
| API-09-016 | 007, 008, 009, 125 |
| API-09-017…018 | 010 |
| API-09-019 | 007 |
| API-09-020 | 011, 012, 013, 134 |
| API-09-022…024 | 011 |
| API-09-026 | 012, 130 |
| API-09-027 | 014 |
| API-09-028 | 014, 015 |
| API-09-029 | 014, 016 |
| API-09-030 | 003, 129 |
| API-09-031 | 003 |
| API-09-033 | 021, 022, 124 |
| API-09-034 | 119 |
| API-09-036 | 021, 022 |
| API-09-037 | 021, 022, 125 |
| API-09-039 | 023 |
| API-09-040 | 021 |
| API-09-041…044 | 023 |
| API-09-046 | 025 |
| API-09-049 | 025 |
| API-09-050 | 026 |
| API-09-051 | 024 |
| API-09-052 | 024, 129 |
| API-09-053 | 024 |
| API-09-054 | 025, 119 |
| API-09-055 | 025, 026 |
| API-09-056 | 027 |
| API-09-057 | 026 |
| API-09-059 | 028, 029, 124 |
| API-09-060 | 028, 120 |
| API-09-061 | 028, 029 |
| API-09-062 | 028 |
| API-09-063 | 030 |
| API-09-064 | 031, 034 |
| API-09-065 | 031, 032, 033, 125 |
| API-09-066 | 032 |
| API-09-068 | 038, 120 |
| API-09-069…070 | 035 |
| API-09-071…072 | 036 |
| API-09-073 | 037, 135 |
| API-09-074…075 | 039 |
| API-09-076…077 | 040 |
| API-09-078 | 039, 136 |
| API-09-079…081 | 048 |
| API-09-082 | 048, 049 |
| API-09-083 | 048 |
| API-09-085 | 049 |
| API-09-086 | 050 |
| API-09-087 | 050, 129 |
| API-09-088 | 051, 052, 053 |
| API-09-089 | 051 |
| API-09-090 | 054 |
| API-09-091 | 054, 056, 147 |
| API-09-093 | 055 |
| API-09-094 | 055, 119 |
| API-09-095 | 055, 056 |
| API-09-096 | 058 |
| API-09-097 | 059, 125 |
| API-09-098…100 | 059 |
| API-09-101 | 057, 058 |
| API-09-102 | 068, 069, 070, 124, 131 |
| API-09-103 | 071 |
| API-09-105 | 072, 073 |
| API-09-106…108 | 072 |
| API-09-109…110 | 075 |
| API-09-111 | 075, 119 |
| API-09-115…116 | 076 |
| API-09-117 | 077 |
| API-09-118 | 077, 131 |
| API-09-119 | 082, 083 |
| API-09-121 | 082, 120 |
| API-09-122 | 082, 083, 125 |
| API-09-124 | 082, 083, 084, 131 |
| API-09-126 | 085 |
| API-09-128 | 088 |
| API-09-129 | 085, 125 |
| API-09-130 | 086, 087, 134, 141 |
| API-09-132 | 086 |
| API-09-133 | 088 |
| API-09-134 | 086 |
| API-09-135…136 | 087 |
| API-09-137 | 090, 091 |
| API-09-138 | 090 |
| API-09-140 | 092 |
| API-09-142…144 | 092 |
| API-09-146 | 093 |
| API-09-147 | 119 |
| API-09-149 | 093 |
| API-09-150 | 093, 125 |
| API-09-152…153 | 094 |
| API-09-154 | 094, 096 |
| API-09-155 | 095 |
| API-09-157…158 | 096 |
| API-09-159 | 097, 098 |
| API-09-160 | 097 |
| API-09-161 | 097, 125, 131 |
| API-09-162 | 098 |
| API-09-163 | 094 |
| API-09-165 | 099, 124, 127 |
| API-09-166 | 099, 120 |
| API-09-167…169 | 100 |
| API-09-170…173 | 101 |
| API-09-174 | 103 |
| API-09-175…177 | 104 |
| API-09-178 | 102 |
| API-09-179…180 | 105 |
| API-09-181 | 105, 144 |
| API-09-183…185 | 106 |
| API-09-186 | 106, 125 |
| API-09-188…189 | 107 |
| API-09-191 | 107, 120 |
| API-09-193 | 109 |
| API-09-194 | 120 |
| API-09-196 | 109, 110 |
| API-09-197 | 109, 110, 125 |
| API-09-199 | 111 |
| API-09-200 | 109, 110 |
| API-09-201 | 109 |
| API-09-203 | 112, 113, 124 |
| API-09-204 | 120 |
| API-09-206 | 112 |
| API-09-207 | 112, 114 |
| API-09-208 | 113, 114 |
| API-09-209 | 114 |
| API-09-211…212 | 115 |
| API-09-213 | 113, 115, 131 |
| API-09-214 | 115, 129 |
| API-09-215 | 116, 124, 140 |
| API-09-216 | 116, 120 |
| API-09-217 | 116, 129 |
| API-09-218…223 | 117 |
| API-09-224 | 118, 119 |
| API-09-225 | 118, 124, 127 |
| API-09-226 | 118 |
| API-09-227 | 037, 042, 043, 044, 045, 046, 047, 102, 122, 126 (+6) |
| API-09-228 | 042, 060, 061, 062, 122, 139 |
| API-09-229 | 063, 064, 065, 066, 067, 126, 130, 147 |
| API-09-230 | 078, 079, 080, 081, 126 |
| API-09-231 | 017 |
| API-09-232 | 060, 122 |
| API-09-233 | 039, 041, 122 |
| API-09-234 | 107, 108, 122, 126 |
| API-09-235 | 100, 122 |
| API-09-236 | 068, 122, 137 |
| API-09-237 | 046, 148 |
| API-09-238 | 106 |
| API-09-239 | 114 |
| API-09-240 | 115 |
| API-09-241 | 068 |
| API-09-242 | 103 |
| API-09-243 | 006 |
| API-09-244 | 104 |
| API-09-245 | 107 |

: API tới test case (chỉ liệt kê API có ca)

API không có ca riêng (38/245), thuộc nhóm đọc, liệt kê, tải hoặc sửa bản nháp được kiểm cùng API cùng tài nguyên: 003, 021, 025, 032, 035, 038, 045, 047, 048, 058, 067, 084, 092, 104, 112, 113, 114, 120, 123, 125, 127, 131, 139, 141, 145, 148, 151, 156, 164, 182, 187, 190, 192, 195, 198, 202, 205, 210.

### 8.8. Màn hình → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-09 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-09-01 | 050, 117, 145 |
| UI-09-02 | 001, 003, 004, 142, 145 |
| UI-09-03 | 006, 007, 145 |
| UI-09-04 | 011, 145 |
| UI-09-05 | 021, 024, 145 |
| UI-09-06 | 021, 145 |
| UI-09-07 | 025, 145 |
| UI-09-08 | 028, 145 |
| UI-09-09 | 031, 032, 034, 048, 051, 145 |
| UI-09-10 | 054, 055, 072, 145, 147 |
| UI-09-11 | 057, 145 |
| UI-09-12 | 075, 145 |
| UI-09-13 | 082, 145 |
| UI-09-14 | 145 |
| UI-09-15 | 093, 145 |
| UI-09-16 | 099, 145 |
| UI-09-17 | 145 |
| UI-09-18 | 109, 145 |
| UI-09-19 | 112, 115, 145 |
| UI-09-20 | 071, 116, 145 |
| UI-09-21 | 145 |
| UI-09-22 | 068, 145 |

: Màn hình tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Sinh ma trận, Gherkin, bảng tính

Chuỗi lệnh dưới chạy từ `05-kiem-thu/test-case/`; công cụ chép từ `ph06/tools/` và chỉnh cho PH-09.

| Lệnh | Kết quả |
|---|---|
| `python3 ph09/tools/number_tcs.py` | Cấp số `TC-09-nnn`, thay `[[tc:khóa]]` |
| `python3 ph09/tools/fill_doc.py` | Ghi bảng 3.1, số kịch bản, số ca và mục 8; in ra stderr các mã chưa có ca |
| `python3 ph09/tools/gen_gherkin.py` | `ph09/gherkin/ts-09-nn.feature`, `uat-quyen-rieng-tu.feature` |
| `python3 ph09/tools/gen_xlsx.py` | `ph09/D05-02-PH09-test-case.xlsx` theo mẫu nghiệm thu |
| `python3 ph09/tools/check_refs.py` | Đối chiếu mã trong tập với FRS, UC, màn hình |

: Chuỗi công cụ sinh phần tự động

### 9.2. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối 13 tiêu chí ở FRS §14 với ca chứng minh.

| Tiêu chí FRS §14 | Ca |
|---|---|
| 1. Mọi FR mức M có ca dương và ca âm; rò rỉ chéo tenant | mục 8.1; TS-09-35 |
| 2. Quyết định p95 ≤ 20 ms có đệm, ≤ 50 ms trực tiếp, 5.000 yêu cầu mỗi giây, bundle ≤ 60 giây | TC-09-047, TC-09-136 |
| 3. Hợp đồng SENSITIVE không kích hoạt khi thiếu chấp thuận; thu hồi chặn lời gọi | TC-09-051, TC-09-135 |
| 4. Nhãn STATE_SECRET chặn ở mọi điểm thực thi | TC-09-017, TC-09-064 |
| 5. Không thấy SENSITIVE dạng rõ ở CSDL, log, topic, tệp xuất | TC-09-074, TC-09-128, TC-09-129 |
| 6. Xem đầy đủ hết hạn 60 giây, ghi kiểm toán trước, từ chối khi PH-13 không ghi được | TC-09-137, TC-09-070, TC-09-131 |
| 7. Khôi phục giá trị gốc cần ba người khác nhau | TC-09-082, TC-09-083 |
| 8. Tập ẩn danh k ≥ 10, rủi ro HIGH chặn | TC-09-089, TC-09-087 |
| 9. Tác vụ lưu giữ hằng ngày, giữ pháp lý, xóa mật mã | TC-09-094, TC-09-096, TC-09-097 |
| 10. ≥ 98 % yêu cầu chủ thể đóng đúng hạn | TC-09-144, TC-09-103 |
| 11. Vi phạm: cảnh báo 24, 48, 60 giờ | TC-09-114, TC-09-138 |
| 12. Mất một nút data plane, RTO ≤ 30 phút | TC-09-133 |
| 13. Mọi mục 11.1 và 11.3 có kết luận | mục 7 |

: Đối chiếu tiêu chí chấp nhận cấp phân hệ với ca kiểm thử

## 10. Đề nghị đồng bộ và câu hỏi mở

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

### 10.1. Đề nghị cho FRS

FRS 0.2 đã hấp thụ các đề nghị của bản 0.1 (Phụ lục C của FRS); bảng nêu kết quả và cách ca đã chỉnh. Tập này không sửa FRS.

| Mã | Điểm nêu ở bản 0.1 | Kết quả ở FRS 0.2 và ca đã chỉnh |
|---|---|---|
| ĐN-TC-01 | Chỉ tiêu thu hồi 15 giây khác 60 giây | Đã chốt 15 giây qua sự kiện, 60 giây qua bundle (NFR-09-024); TC-09-135 đo cả hai |
| ĐN-TC-02 | Đồng hồ 72 giờ không dừng hay đặt lại, khác 14.11 | Đã chốt: chỉ dừng khi thông báo A05 đã `SENT` (BR-09-054); TC-09-114 |
| ĐN-TC-03 | Ngưỡng bất thường của EVT-09-15 chưa có tham số | Đã có `09.mask.reveal-alert-per-hour` mặc định 10; TC-09-071 dùng ngưỡng 10 mỗi giờ |
| ĐN-TC-04 | Thiếu mã lỗi cho AI khi cờ tắt, khoảng tra nhật ký, khóa trùng khác thân | Đã có ERR-09-082, 079, 081; TC-09-090, 116, 127 dùng mã này. Thiếu MFA dùng ERR-00-401, không cấp mã PH-09 |
| ĐN-TC-05 | Lệch SRS cũ chưa ghi ở Phụ lục B | Đã ghi ở bảng 11.3 của FRS; TC-09-149, 147 kiểm cả hai phía |
| ĐN-TC-06 | `09.anon.k-min-ai` cho dữ liệu AI | Không nhận: giữ một sàn k ≥ 10, đặt cao hơn được trong cấu hình; TC-09-149 chấp nhận k = 10 |
| ĐN-TC-07 | Số cho ERR-09-107 và ERR-09-113 | Đã có 1 MiB và `09.api.rate-du-per-sec = 2.000`; TC-09-065, 045 dùng số này |
| ĐN-TC-08 | NFR cho tự hết hạn và cảnh báo 5 phút | Đã có NFR-09-025, 026; TC-09-038, 046 |
| ĐN-TC-09 | NFR dẫn nhầm ở 14.5; khi nào `410` | Đã sửa: NFR-09-014; `410` khi đối tượng danh mục `RETIRED` (TC-09-002) |

: Kết quả hấp thụ đề nghị của tập kiểm thử vào FRS 0.2

### 10.2. Đề nghị đồng bộ tài liệu khác

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới thuộc tài liệu dùng chung hoặc tập của người khác; tập này không tự sửa.

| Tài liệu | Đề nghị |
|---|---|
| D05-01 | Thêm PH-09 vào bảng phân bổ tenant kiểm thử `T90…T99` và cổng `RG-1…5`; ghi bộ ca golden OPA (NFR-09-008) vào CI |
| D03-04-PH09, `openapi-privacy.yaml` | Đối chiếu tên trường JSON giả định ở mục 1.5 (`dryRun`, `mandatoryByLaw`, `confirmInconsistency`, `effectiveClass`, `neverReveal`) |
| D03-03-PH09, `csdl/ph09/test/` | Bài kiểm RLS của TC-09-121 dùng chung với bộ kiểm CSDL; thêm kiểm "không bảng ánh xạ bí danh" (BR-09-030) |
| D02-08 | Cặp loại trừ SO với `PERM-09-purpose-approve`, DS với DA đã dùng ở TC-09-124; cần có trong ma trận |
| `05-kiem-thu/test-case/ph06/tools/gen_xlsx.py` | Bộ lọc cột FR dùng tiền tố `FR-10` thay vì `FR-06`, làm cột FR của `.xlsx` PH-06 trống; bản PH-09 đã dùng `FR-09` |
| D00-04 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi nhận tập này (số TS, TC mới) |

: Đề nghị đồng bộ tài liệu khác

### 10.3. Câu hỏi mở

> **Câu hỏi mở Q09-41:** Bộ mẫu chuẩn 500 cột cho NFR-09-009 do ai cung cấp và tỷ lệ cột chứa số định danh; đến khi có câu trả lời, ca TC-09-013 dùng bộ sinh 8 cột có số định danh trong 40 cột, nhân lên 500 cột.

> **Câu hỏi mở Q09-42:** Ai sở hữu và duyệt bộ ca chuẩn (golden set ≥ 300 ca, NFR-09-008), và tên trường JSON giả định ở mục 1.5 khi `openapi-privacy.yaml` chốt; tạm dùng 300 ca sinh từ ma trận mức × loại × vai × mục đích × kênh.

> **Câu hỏi mở Q09-43:** Lịch ngày làm việc (ngày nghỉ lễ của tỉnh) để tính hạn 10 ngày làm việc và nhắc trước 3 ngày; ca TC-09-103 dùng lịch giả định thứ Hai đến thứ Sáu, không nghỉ lễ.

> **Câu hỏi mở Q09-44:** Có đo thật ẩn danh hóa 1 triệu bản ghi (NFR-09-012) và diễn tập DR (NFR-09-021) trên hạ tầng của tỉnh trước nghiệm thu không, và có kiểm thử xâm nhập độc lập riêng cho API xem đầy đủ, khôi phục giá trị gốc ngoài ZAP và quét canary không.

> **Câu hỏi mở Q09-45:** FR-09-025 từ chối mẫu mô phỏng có số định danh đúng kiểm tổng, thẻ đúng Luhn hoặc điện thoại ngoài "miền giả" (ERR-09-080) nhưng FRS chưa nêu miền giả gồm dải nào. Dữ liệu CC-01 (điện thoại `0912345678`) và ca TC-09-057 dùng giá trị mẫu có dạng hợp lệ; cần chốt dải giả cho CCCD, MST, thẻ, điện thoại để ca TC-09-057 và TC-09-058 bước 3 phân biệt được mẫu giả với mẫu thật.

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-26 | Bản đầu: kịch bản TS-09-01…42, test case TC-09, ma trận truy vết, Gherkin, bảng tính theo FRS 0.1 |
| 0.2 | 2026-11-26 | Đồng bộ FRS 0.2: ERR-09-079…082, API-09-238…245, NFR-09-024…026, BR-09-062; sửa mã lỗi ở TC-09-006, 090, 116, 117; thêm TC-09-150; thu hẹp mục 10.1, bỏ Q09-40, thêm Q09-45 |
| 0.3 | 2026-11-27 | Đồng bộ chéo cuối: tên trường JSON theo OpenAPI (`statutory`, `confirmInconsistency`); ca xoay khóa chờ ERR-09-003 khi chưa xác nhận |

: Lịch sử phiên bản
