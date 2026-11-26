---
ma_tai_lieu: D05-02-PH06
ten: Kịch bản và test case phân hệ PH-06 Dữ liệu chủ
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-06
mo_ta: Kịch bản và test case chức năng, độ chính xác đối sánh, hiệu năng, cô lập tenant, mã hóa số định danh, kiểm toán và nghiệm thu của phân hệ Dữ liệu chủ, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH06 FRS; D02-04-PH06 Use case; D03-06-PH06 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH06 · Kịch bản và test case Dữ liệu chủ

## Tóm tắt cho hội đồng thẩm định

Phần này viết cho hội đồng thẩm định: tài liệu chứng minh điều gì, phủ đến đâu và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản, số ca do công cụ sinh lại từ chính các ca nên luôn khớp với chương 4 và 5.

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-06 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH06 bản 0.2: 60 FR, 33 quy tắc BR-06, 20 yêu cầu phi chức năng.
- Đối sánh gom đúng một người, một tổ chức thành một bản ghi vàng: trên tập nhãn giả định 12.000 cặp, hợp nhất sai ≤ 0,1 %, bỏ sót ≤ 2 %, và hai bản ghi có số định danh xác định khác nhau không thể hợp nhất qua bất kỳ đường nào (BR-06-006).
- Không có đường nào để tenant này đọc dữ liệu chủ của tenant khác, để số định danh và thuộc tính `SENSITIVE` lộ dạng rõ ở CSDL, log, topic, tệp xuất, hay để một lượt trả dữ liệu không có nhật ký truy cập.
- Hợp nhất, tách, hoàn tác luôn khôi phục đúng trạng thái trước, có người duyệt khác người đề nghị với thao tác rủi ro cao, và đồng bộ quốc gia tự dừng khi lệch quá 5 %.

**Phạm vi.** Gồm <!--gen:so-ts-->35<!--/gen--> kịch bản với <!--gen:so-tc-->151 (TC-06-001…151; 118 ca P1)<!--/gen--> test case và 8 kịch bản nghiệm thu người dùng (UAT-01…08). Mọi FR có ít nhất một ca dương và một ca âm; ma trận mục 8 sinh bằng `ph06/tools/gen_matrix.py`. PH-06 là phân hệ mới của Đợt 3, hệ cũ không có chức năng dữ liệu chủ (D02-02 ghi LGC "—") nên mục 7 là nghiệm thu theo vai trò thay cho nghiệm thu tương đương hệ cũ.

**Căn cứ.** FRS D02-03-PH06, use case D02-04-PH06, màn hình D03-06-PH06, ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01 (cổng `RG-1…5`); Luật Dữ liệu, Luật BVDLCN 91/2025, Nghị định 278/2025/NĐ-CP, Nghị định 356/2025/NĐ-CP, Nghị định 331/2026/NĐ-CP, TCVN 14423:2026; cấu trúc theo ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Năm nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- cô lập tenant ở API, RLS, ACL Kafka, kho tệp (TS-06-29);
- bốn mắt và ma trận `PERM-06-*` không có đường vòng, kể cả với TA có cả quyền soạn và duyệt (TS-06-30, TS-06-14);
- không lộ số định danh và thuộc tính `SENSITIVE` ở dạng rõ, nhật ký truy cập đủ 100 % lượt trả dữ liệu (TS-06-31);
- độ chính xác đối sánh trên tập nhãn và bất biến "khác CCCD không hợp nhất" (TS-06-33, TS-06-18);
- hợp nhất, tách, hoàn tác khôi phục đúng, job lô thất bại giữa chừng không đổi bản ghi vàng ngoài các cặp đã áp (TS-06-19, 20, 11, 34).

Dữ liệu và quy mô dùng giả định GĐ-01…07 (tỉnh vừa, 200 HTTT) và giả định riêng ở mục 2: tenant hiệu năng 1,2 triệu công dân, 25.000 tổ chức, 5 triệu bản ghi nguồn. Mã hiện có của `dh-data` chưa có mô-đun `mdm`; các ca là tiêu chí nghiệm thu của công việc mới ở Đợt 3.

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả kịch bản và test case của PH-06 Dữ liệu chủ để nghiệm thu chức năng, độ chính xác đối sánh, hiệu năng và an toàn dữ liệu.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư `dh-data`, `dh-console` đối chiếu hành vi; cán bộ ATTT kiểm chương 5; chủ đầu tư dùng mục 7 và 9.6 để nghiệm thu.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; DS người quản lý dữ liệu; DA người duyệt; DO chủ quản dữ liệu; TA quản trị tenant; PA quản trị nền tảng; RLS an toàn theo hàng; precision, recall độ chính xác và độ phủ của đối sánh; canary chuỗi mồi phát hiện rò rỉ.

### 0.4. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng; 5 ca phi chức năng; 6 thủ công; 7 nghiệm thu; 8 ma trận; 9 tự động hóa; 10 đề nghị và câu hỏi mở.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là mô-đun `vn.datahub.data.mdm` của `dh-data` (các thành phần `mdm-serve`, `mdm-normalize`, `mdm-match`, `mdm-steward`, `mdm-sync`), job đối sánh theo lô Splink chạy Job K8s `mdm-splink`, schema `ph06_mdm` của `pg-core` với RLS theo `tenant_id`, 96 API dưới `/api/mdm/v1` (API-06-001…096), 15 topic `{tenant}.mdm.*` (EVT-06-01…15) và 18 màn hình dưới `/du-lieu/du-lieu-chu` (UI-06-01…18). Ngoài phạm vi: nội dung CSDL quốc gia (PH-14 giả lập bằng WireMock), danh mục ĐVHC (PH-07 giả lập, ca chuyển mã thuộc D05-02-PH07), chính sách che chung (PH-09 giả lập, ca thuộc D05-02-PH09).

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca; chiến lược chung theo D05-01.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest, pytest | Bộ kiểm tra khóa, chuẩn hóa tên, ngày, địa chỉ; hàm chấm điểm; công thức ưu tiên hàng đợi; chiến lược sống sót |
| Tích hợp | IT | Testcontainers (PostgreSQL 16 có `pg_trgm`, Kafka KRaft, Keycloak, Garage, WireMock cho PH-07, 09, 14) | Dịch vụ với CSDL, outbox, kho tệp, nhật ký truy cập |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph06/test/` | RLS, ràng buộc duy nhất `(sourceCode, sourceKey)`, bất biến lịch sử |
| Job | JOB | pytest, Job K8s trên cụm kind | Job Splink: staging, quyền CSDL, kết quả, dọn dẹp |
| Hợp đồng | CT | Spectral, oasdiff, đối chiếu FRS | OpenAPI `/api/mdm/v1`, lược đồ sự kiện |
| API | API | REST Assured | Mọi API-06 |
| Kafka | KT | `kcat`, client Java OAUTHBEARER | ACL theo tiền tố, nội dung sự kiện |
| Đầu cuối | E2E | Playwright, axe-core | UI-06-01…18 |
| Độ chính xác | ACC | `ph06/seed/eval_accuracy.py` trên tập nhãn | Precision, recall, tỷ lệ tự động |
| Hiệu năng | k6 | k6 (HTTP), pgbench, đồng hồ Job | NFR-06-001…005, 013, 014, 020 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | PostgreSQL, Kafka, PH-07/09/14, Job |
| Bảo mật | ZAP | OWASP ZAP, quét canary, Semgrep | ASVS 5.0 mức 2, rò rỉ giá trị |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường phục vụ các mức kiểm thử ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, JOB, CT, API, KT, E2E khói | `dh-data` 1 bản sao; PH-07, 09, 14 là WireMock; Job K8s trên kind |
| STAGING | E2E đầy đủ, Chaos, ZAP, UAT dợt | Giống sản xuất về số bản sao và chính sách mạng |
| PERF | k6, ACC, JOB quy mô | `dh-data` 2 bản sao 4 vCPU, 8 GB; `pg-core` 8 vCPU, 32 GB; Job 8 vCPU, 32 GB; tenant T97…T99 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** Hợp đồng API-06 và lược đồ sự kiện đã gắn phiên bản; bộ dữ liệu mục 2 nạp được bằng `ph06/seed/` qua API (không chèn SQL, trừ bộ RLS).
- **Ra.** Theo cổng D05-01: `RG-1` mọi ca API, DB và rò rỉ chéo tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-06-001…020 ở PERF; `RG-4` UAT mục 7 ký và 12 tiêu chí chấp nhận cấp phân hệ ở FRS §14 đạt (đối chiếu ở mục 9.6).

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-06-nn`, test case `TC-06-nnn`; mã không tái sử dụng, ca bị hủy ghi "Đã hủy" và giữ mã. TS-06-01…28 ứng một một với UC-06-01…28; TS-06-29…35 là kịch bản phi chức năng. Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-06-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và tham chiếu `[[tc:khóa]]`, không in ra bản xuất.

| Trường | Nội dung |
|---|---|
| **Mục đích.** | Ca chứng minh điều gì, theo FR hoặc NFR chính |
| **Loại.** | Dương, Âm, Biên, Bảo mật, Hiệu năng, Độ chính xác, Chịu lỗi, Truy cập |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung |
| **Tự động.** | Mức ở mục 1.2 hoặc "Thủ công" |
| **Truy vết.** | FR, BR, API, UI, ERR, EVT, NFR, quyền, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu ở chương 2 |
| **Các bước.** | Danh sách đánh số; đường dẫn tương đối với `/api/mdm/v1` |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán |
| **Thông báo hiển thị.** | Câu người dùng nhìn thấy theo FRS §9.2 và D03-06-PH06 §5.3, chỉ ở ca có mã lỗi |
| **Hậu điều kiện.** | Dữ liệu còn lại sau ca, ca nào dùng lại |

: Các trường của khối đặc tả test case

Mã lỗi nền tảng chưa có ở FRS PH-06 (thiếu quyền, chưa xác thực) dùng ký hiệu 403-PQ, 401-XT; đề nghị bổ sung ở mục 10.1. Trong kết quả mong đợi dùng các ký hiệu sau.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` do thiếu quyền `PERM-06-*` hoặc scope `mdm:*`; thân RFC 9457 có `code`, `traceId` |
| 401-XT | `401` thiếu hoặc sai token |
| 404-ẩn | `404` ERR-06-001; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa giá trị thuộc tính DLCN |
| NK: có | Có đúng một dòng `access_log` cho lượt trả dữ liệu (BR-06-010) |
| EVT: `loại` | Đúng một bản tin trên topic `t90.mdm.{loại}.v1`, không chứa giá trị thuộc tính (BR-06-012) |
| EVT: không | Sau 10 giây không có dòng mới trong outbox và không có bản tin trên topic liên quan |
| Mồi sạch | Chuỗi canary `DH-CANARY-{ca}` và số định danh giả của ca không xuất hiện ở dạng rõ trong phản hồi, log 5 phút, vết OTel, bảng `ph06_mdm.*`, outbox, Kafka, tệp xuất |

: Ký hiệu viết tắt trong kết quả mong đợi

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi theo mức S1…S4 của D05-01; ca đạt, không đạt, chặn ghi ở cột "Kết quả" của `.xlsx`. Lỗi ở nhóm P1 chặn phát hành. Mọi lỗi S1, S2 sửa xong phải có thêm một ca hồi quy tự động trong tập này.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập: tên là nhân vật hư cấu, số định danh ở dải giả không do cơ quan nào cấp. Nạp bằng `ph06/seed/` qua API, trừ khối RLS chạy ở mức CSDL.

### 2.1. Tenant

Tenant kiểm thử dùng dải `T90…T99`; không dùng tenant sản xuất.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant chính | Đã cài gói nền CITIZEN, ORGANIZATION, ADDRESS; nguồn `QG-DANCU`, `HT-YTE`, `HT-GIAODUC`, `HT-THUE`, `QG-DKDN`; tham số mặc định theo FRS §8.2 |
| `T91` | Tenant đối chứng rò rỉ | Cùng mã domain, nguồn, CCCD giả với T90 nhưng `goldenId` khác; dùng cho mọi ca chéo tenant |
| `T92` | Tham số nhỏ | `06.queue.max-open = 100`, `06.export.max-rows = 1000`, `06.undo.window-days = 30`, `06.ingest.rate-per-source = 600` |
| `T93` | Chưa cài gói nền | Không có domain; dùng cho FR-06-007 |
| `T94` | Đồng bộ quốc gia | PH-14 giả lập bằng WireMock có kịch bản lệch 2 % và 8 % |
| `T95` | Chịu lỗi | Cho Chaos: dừng nhật ký truy cập, PH-07, PH-09, Kafka, Job |
| `T96` | Độ chính xác | Tập nhãn giả định 12.000 cặp (F-LBL) và 100.000 ứng viên (F-AUTO) |
| `T97`…`T99` | Hiệu năng | T97 tra cứu, resolve, nạp (1,2 triệu CITIZEN, 25.000 ORGANIZATION, 5 triệu bản ghi nguồn); T98 dung lượng 10 triệu bản ghi vàng; T99 job lô |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

Người dùng mang tên nhân vật hư cấu, vai trò theo D02-08.

| Mã | Tenant | Vai trò | Ghi chú |
|---|---|---|---|
| U-PA | PLATFORM | PA | Cài gói nền, trần tham số |
| U-T90-TA | T90 | TA | Có `PERM-06-config`, `merge`, `export`, `operate`; có cả quyền soạn lẫn duyệt qua cấu hình sai chủ ý (chỉ SIT) để kiểm bốn mắt độc lập |
| U-T90-DS1, DS2 | T90 | DS | Lan, Hùng; DS1 thuộc Sở Y tế, DS2 thuộc Sở Giáo dục (kiểm `○` theo tổ chức) |
| U-T90-DA1, DA2 | T90 | DA | Minh, Thảo; DA1 là người duyệt chính |
| U-T90-DO1 | T90 | DO | Quân, chủ quản nguồn `HT-YTE` |
| U-T90-TO, SO, AU, VW | T90 | TO, SO, AU, VW | Việt, Hà, Thu, Nam |
| U-T91-DS1, DA1 | T91 | DS, DA | Đối chứng chéo tenant |
| S-T90-INGEST-{nguồn} | T90 | HTTT | Scope `mdm:ingest`, gắn một nguồn đã đăng ký |
| S-T90-RESOLVE, READ, SEARCH | T90 | HTTT, PH-04 | Scope `mdm:resolve`, `mdm:read`, `mdm:search`; mục đích PH-09 `MD-TRACUU` |
| S-T90-NOPURPOSE | T90 | HTTT | Có scope nhưng PH-09 chưa chấp thuận mục đích |
| S-T91-READ | T91 | HTTT | Token đối chứng |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu

Bộ dữ liệu có tên, sinh bằng hạt cố định để chạy lại được.

| Mã | Nội dung | Tenant |
|---|---|---|
| F-CIT | 40 công dân giả có trùng chủ ý qua ba nguồn: cùng CCCD khác cách viết tên; cùng tên và ngày sinh khác CCCD; thiếu CCCD; đảo họ tên; sai ngày, tháng | T90 |
| F-ORG | 20 tổ chức giả có MST đúng, MST sai chữ số kiểm tra, không MST, tiền tố loại hình khác nhau | T90 |
| F-ADDR | 30 địa chỉ giả: mã ĐVHC hiện hành, mã cũ (một mã cũ một mã mới và một mã cũ nhiều mã mới), mã không tồn tại, chuỗi không tách được | T90 |
| F-FILE | Tệp `ung-vien-2000.xlsx` 2.000 dòng (50 dòng lỗi), `ung-vien-cong-thuc.xlsx` có công thức, `ung-vien-lon.csv` vượt giới hạn | T90 |
| F-LBL | 12.000 cặp có nhãn: 6.000 `MATCH`, 6.000 `NO_MATCH`, trong đó 1.500 cặp khó (không dấu, đảo họ tên, sai tháng, trùng tên khác ngày sinh, cha con cùng tên); sinh bằng bộ sinh có hạt cố định, giả định nhiễu 8 % | T96 |
| F-AUTO | 100.000 ứng viên mô phỏng 30 ngày nạp thử, 20 nguồn | T96 |
| F-SYNC | Lượt đối chiếu 1.000 bản ghi lệch 2 % và 8 % | T94 |
| F-PERF | 1,2 triệu CITIZEN, 25.000 ORGANIZATION, 5 triệu bản ghi nguồn từ 20 nguồn (giả định theo GĐ-04, GĐ-07) | T97, T98, T99 |

: Bộ dữ liệu kiểm thử

Số định danh giả dùng trong ca (chữ số kiểm tra MST tính theo trọng số ở FR-06-003, giả định Q06-09):

| Mã | Giá trị | Ý nghĩa |
|---|---|---|
| CC-01 | `001090000101` | CCCD hợp lệ, Nguyễn Văn An, sinh 12/03/1990 |
| CC-02 | `001090000202` | CCCD hợp lệ khác, cùng tên và ngày sinh với CC-01 |
| CC-03 | `079195000303` | CCCD hợp lệ, Trần Thị Bình, sinh 05/07/1995 |
| CC-X | `00109000010`, `000000000000` | Sai độ dài; giá trị giả toàn số 0 |
| MST-01, MST-02 | `0109000015`, `0109000022` | MST hợp lệ của hai tổ chức khác nhau |
| MST-X | `0109000016` | Sai chữ số kiểm tra |

: Số định danh giả

### 2.4. Hệ thống giả lập

Phân hệ và hệ thống ngoài được giả lập như sau.

| Hệ thống | Giả lập bằng | Kịch bản |
|---|---|---|
| PH-07 (ĐVHC, danh mục) | WireMock | Hiện hành, mã cũ chuyển một-một và một-nhiều, mã không tồn tại, ngừng `503` |
| PH-09 (phân loại, mục đích, che) | WireMock | `CONFIRMED`, `PROPOSED`, mục đích chấp thuận và không, ngừng `503` |
| PH-14 (CSDL tổng hợp quốc gia) | WireMock `nat-sim` | Gửi bản ghi quốc gia, tra lô, lệch 2 % và 8 %, ngừng, dữ liệu mâu thuẫn |
| PH-04 `dh-runtime`, PH-10 | Máy gọi thử dùng token dịch vụ | Kênh `FLOW`, `EVENT` |
| Kho tệp | Garage trong Testcontainers | Tệp tạm, tệp xuất |

: Hệ thống giả lập

### 2.5. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Mỗi ca ghi dữ liệu sinh ra và dọn bằng khóa `tc-{khóa}` trong tenant; ca dùng lại dữ liệu của ca khác nêu rõ ở hậu điều kiện. Ca bảo mật dùng canary `DH-CANARY-{ca}` đặt vào thuộc tính `SENSITIVE`.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-06-01 | Gói domain nền và xem domain | UC-06-01 | 3 |
| TS-06-02 | Soạn mô hình domain, khóa định danh và phân loại | UC-06-02 | 8 |
| TS-06-03 | Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain | UC-06-03 | 3 |
| TS-06-04 | Nguồn và ưu tiên nguồn | UC-06-04 | 5 |
| TS-06-05 | Nạp ứng viên qua API, luồng PH-04 và sự kiện PH-10 | UC-06-05 | 5 |
| TS-06-06 | Nạp tệp lô có xem trước | UC-06-06 | 2 |
| TS-06-07 | Chuẩn hóa ứng viên và xử lý ứng viên lỗi | UC-06-07 | 6 |
| TS-06-08 | Bộ quy tắc đối sánh, khóa gom nhóm và ngưỡng | UC-06-08 | 4 |
| TS-06-09 | Tập nhãn, chạy thử, đánh giá và kích hoạt bộ quy tắc | UC-06-09 | 4 |
| TS-06-10 | Đối sánh tự động và tạo, cập nhật bản ghi vàng | UC-06-10 | 10 |
| TS-06-11 | Job đối sánh theo lô bằng Splink | UC-06-11 | 6 |
| TS-06-12 | Hàng đợi người quản lý dữ liệu | UC-06-12 | 4 |
| TS-06-13 | So sánh cạnh nhau và quyết định | UC-06-13 | 4 |
| TS-06-14 | Duyệt bốn mắt hợp nhất rủi ro cao | UC-06-14 | 3 |
| TS-06-15 | Quy tắc sống sót, xem trước tác động và áp lại | UC-06-15 | 4 |
| TS-06-16 | Chi tiết bản ghi vàng, lịch sử và nguồn gốc | UC-06-16 | 4 |
| TS-06-17 | Sửa tay, ngừng và khôi phục bản ghi vàng | UC-06-17 | 4 |
| TS-06-18 | Hợp nhất bản ghi vàng thủ công | UC-06-18 | 3 |
| TS-06-19 | Tách bản ghi vàng và gỡ liên kết chéo nguồn | UC-06-19 | 3 |
| TS-06-20 | Hoàn tác thao tác trên bản ghi vàng | UC-06-20 | 3 |
| TS-06-21 | Tra cứu, tra ID nguồn và tìm kiếm có che dữ liệu | UC-06-21 | 7 |
| TS-06-22 | Giải quyết bản ghi trực tuyến (resolve) | UC-06-22 | 4 |
| TS-06-23 | Xuất dữ liệu chủ có kiểm soát | UC-06-23 | 3 |
| TS-06-24 | Phát sự kiện thay đổi và đăng ký nhận cập nhật | UC-06-24 | 3 |
| TS-06-25 | Đồng bộ CSDL tổng hợp quốc gia và xử lý lệch | UC-06-25 | 6 |
| TS-06-26 | Vận hành: dashboard, lịch job và nhật ký | UC-06-26 | 3 |
| TS-06-27 | Yêu cầu của chủ thể dữ liệu | UC-06-27 | 4 |
| TS-06-28 | Chính sách lưu giữ và tham số theo tenant | UC-06-28 | 2 |
| TS-06-29 | Cô lập tenant: API, RLS, Kafka, kho tệp | — | 5 |
| TS-06-30 | Phân quyền theo ma trận PERM-06 và bốn mắt | — | 3 |
| TS-06-31 | Kiểm toán, mã hóa số định danh và an toàn dữ liệu | — | 5 |
| TS-06-32 | Hiệu năng, tải và quy mô | — | 6 |
| TS-06-33 | Độ chính xác đối sánh | — | 5 |
| TS-06-34 | Chịu lỗi, khôi phục và quan sát | — | 4 |
| TS-06-35 | Truy cập và giao diện | — | 3 |
| **Tổng** | | | **151** (118 ca P1) |

: Danh sách 35 kịch bản kèm use case và số ca
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Bảng liệt kê chuyển hợp lệ và chuyển cấm được kiểm ở chương 4.

| Máy trạng thái (FRS §4) | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Domain, phiên bản mô hình | DRAFT → PENDING_APPROVAL → ACTIVE → SUSPENDED → ACTIVE → RETIRED; ACTIVE → SUPERSEDED; PENDING_APPROVAL → REJECTED | Sửa phiên bản ACTIVE; ngừng khi còn bản ghi vàng; tự duyệt |
| Bản ghi vàng | ACTIVE → LOCKED → ACTIVE; ACTIVE → MERGED; MERGED → ACTIVE (tách, hoàn tác); ACTIVE → RETIRED → ACTIVE | Xóa; sửa khi LOCKED; ngừng khi còn liên kết hiệu lực |
| Mục hàng đợi | OPEN → ASSIGNED → RESOLVED; ASSIGNED → DEFERRED; → PENDING_APPROVAL → RESOLVED; → CANCELLED | Hai người cùng nhận; quyết định khi lỗi thời |
| Job đối sánh | QUEUED → PREPARING → RUNNING → APPLYING → SUCCEEDED; RUNNING → AWAITING_CONFIRMATION; → FAILED, CANCELLED, PARTIALLY_SUCCEEDED | Hủy job đã SUCCEEDED; hai job cùng loại cho một domain |
| Ứng viên | RECEIVED → NORMALIZED → QUEUED hoặc LINKED; RECEIVED → DUPLICATE, SUPERSEDED, REJECTED | Xử lý lại ứng viên LINKED |
| Xuất, đăng ký nhận, yêu cầu chủ thể | PENDING_APPROVAL → APPROVED → GENERATING → READY → EXPIRED; ACTIVE → SUSPENDED → ACTIVE → REVOKED; RECEIVED → IN_PROGRESS → COMPLETED | Tải khi chưa duyệt, tải sau hạn; tiếp tục sau REVOKED |

: Chuyển trạng thái hợp lệ và bị cấm được kiểm thử

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ, sau đó là các ca theo mục 1.5. TS-06-01…28 cùng số thứ tự với UC-06-01…28.

### TS-06-01 · Gói domain nền và xem domain

**Mục tiêu.** Xác nhận cài được ba domain nền và xem domain đúng phạm vi tenant, phiên bản và trạng thái.

**Phủ.** FR-06-001, 007; UC-06-01; API-06-001, 002, 012; UI-06-07; BR-06-016, 017.

#### TC-06-001 · Liệt kê, lọc và xem chi tiết domain <!--k:dom-list-->

::: dac-ta
**Mục đích.** Chứng minh danh sách domain có phân trang, lọc theo trạng thái và chi tiết đủ thuộc tính, khóa, phiên bản, theo FR-06-001.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-001 · API-06-001, 002 · UI-06-07 · PERM-06-read.

**Tiền điều kiện, dữ liệu.** T90 có CITIZEN, ORGANIZATION `ACTIVE`, ADDRESS `DRAFT`; U-T90-VW.

**Các bước.**

1. `GET /domains?page=0&size=2&status=ACTIVE`.
2. `GET /domains/CITIZEN`.
3. VW gọi `GET /domains/CITIZEN` rồi so với `GET /domains/CITIZEN` của DS1.

**Kết quả mong đợi.** Bước 1 `200`, 2 phần tử, `totalElements = 2`, ADDRESS không có. Bước 2 có `status`, `activeVersion`, danh sách thuộc tính với `AttributeType`, `dataClass`, khóa `CCCD_12`. Bước 3 hai thân giống nhau; `ETag` có mặt.

**Hậu điều kiện.** Không đổi dữ liệu.
:::

#### TC-06-002 · Cài gói domain nền vào tenant mới <!--k:baseline-install-->

::: dac-ta
**Mục đích.** Chứng minh gói nền tạo CITIZEN, ORGANIZATION, ADDRESS với thuộc tính, khóa, phân loại đề xuất, theo FR-06-007.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-007 · API-06-012 · UI-06-07 · BR-06-016 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** T93 chưa có domain; U-PA, PH-09 giả lập `PROPOSED`.

**Các bước.**

1. PA `POST /domains:install-baseline` cho T93.
2. `GET /domains` và chi tiết CITIZEN.

**Kết quả mong đợi.** Bước 1 `201`, ba domain `DRAFT` phiên bản 1. CITIZEN có khóa `CCCD_12` `deterministic = true`, ORGANIZATION có `MST_10_13`, ADDRESS có `DVHC_CODE`. Thuộc tính DLCN (họ tên, ngày sinh, CCCD) `ClassificationStatus = PROPOSED`, `dataClass = SENSITIVE` cho số định danh. KT: có (install-baseline).

**Hậu điều kiện.** T93 có ba domain DRAFT, chưa kích hoạt được tới khi PH-09 xác nhận phân loại.
:::

#### TC-06-003 · Cài gói nền lần hai, thiếu quyền, tenant đã tùy chỉnh <!--k:baseline-neg-->

::: dac-ta
**Mục đích.** Chứng minh gói nền không ghi đè domain đã có và chỉ PA, TA được cài, theo FR-06-007.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-007 · API-06-012 · ERR-06-002, 006 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** T93 sau ca baseline-install; T90 đã sửa thuộc tính CITIZEN.

**Các bước.**

1. TA gọi lại `POST /domains:install-baseline` ở T93.
2. DS1 gọi `POST /domains:install-baseline`.
3. TA gọi ở T90 khi CITIZEN đã có phiên bản 2 do tỉnh sửa.

**Kết quả mong đợi.** Bước 1 `409` ERR-06-002, không tạo thêm. Bước 2 403-PQ. Bước 3 không ghi đè phiên bản 2, các domain thiếu mới được bổ sung, phản hồi liệt kê "đã có, bỏ qua".

**Hậu điều kiện.** Không domain nào bị đổi ngoài domain thiếu.
:::

### TS-06-02 · Soạn mô hình domain, khóa định danh và phân loại

**Mục tiêu.** Xác nhận soạn được mô hình có kiểu, khóa kiểm đúng, phân loại PH-09 bắt buộc cho DLCN, phiên bản và tương thích đúng.

**Phủ.** FR-06-002, 003, 004, 005; UC-06-02; API-06-003…007, 013; UI-06-07; BR-06-001, 016, 017; ERR-06-008, 009, 010.

#### TC-06-004 · Tạo domain tùy chỉnh với mười một kiểu thuộc tính <!--k:model-create-->

::: dac-ta
**Mục đích.** Chứng minh soạn domain `DEMO-CANBO` đủ các `AttributeType`, thuộc tính `matchable`, trọng số, theo FR-06-002.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-002 · API-06-003, 005, 006 · UI-06-07 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** T90, U-T90-DS1 có `PERM-06-config` (○).

**Các bước.**

1. `POST /domains` mã `DEMO-CANBO`.
2. `PUT .../model-versions/1` với 11 thuộc tính, mỗi `AttributeType` một cái, hai thuộc tính `matchable`.
3. `GET .../model-versions/1`.

**Kết quả mong đợi.** Bước 1 `201` `DRAFT`. Bước 2 `200`, `ETag` mới. Bước 3 trả đủ 11 thuộc tính theo thứ tự, kiểu đúng. KT: có (domain-create, model-update).

**Hậu điều kiện.** Domain DEMO-CANBO DRAFT; dùng lại ở model-neg, version-diff.
:::

#### TC-06-005 · Mã trùng, kiểu sai, tham chiếu không tồn tại, ETag cũ <!--k:model-neg-->

::: dac-ta
**Mục đích.** Chứng minh các nhánh bị chặn khi soạn mô hình, theo FR-06-002.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-002 · API-06-003, 006 · ERR-06-002, 003, 004.

**Tiền điều kiện, dữ liệu.** DEMO-CANBO DRAFT của ca model-create; DS2 sửa đồng thời.

**Các bước.**

1. `POST /domains` mã `DEMO-CANBO` lần hai.
2. `PUT` thuộc tính `ngaySinh` kiểu `TEXT` (không có trong enum).
3. `PUT` thuộc tính `CODE_REF` trỏ danh mục `KHONG-CO`.
4. DS2 `PUT` bằng `If-Match` cũ.

**Kết quả mong đợi.** Bước 1 `409` ERR-06-002. Bước 2, 3 `400` ERR-06-003 có `errors[]` đúng trường. Bước 4 `409` ERR-06-004 kèm `currentEtag`.

**Thông báo hiển thị.** ERR-06-004 hộp xung đột phiên bản của nền tảng.

**Hậu điều kiện.** Mô hình không đổi.
:::

#### TC-06-006 · Thử kiểm tra khóa định danh CCCD, MST <!--k:idkey-validate-->

::: dac-ta
**Mục đích.** Chứng minh bộ kiểm tra trả đúng `IdentifierStatus` và che giá trị, theo FR-06-003.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-06-003 · BR-06-001 · API-06-013 · UI-06-07 · NFR-06-010.

**Tiền điều kiện, dữ liệu.** CC-01, CC-03, CC-X, MST-01, MST-X (mục 2.3).

**Các bước.**

1. `POST /identifier-rules:test` validator `CCCD_12` với `[CC-01, CC-X chín số, 000000000000]`.
2. Lặp với `MST_10_13` và `[MST-01, MST-X, 0109000015-001, 0000000000]`.

**Kết quả mong đợi.** Bước 1 `VALID`, `INVALID_FORMAT`, `PLACEHOLDER`. Bước 2 `VALID`, `INVALID_CHECKSUM`, `VALID`, `PLACEHOLDER`. Mỗi `value` chỉ giữ 3 số cuối, lượt thử không lưu giá trị (Mồi sạch).

**Hậu điều kiện.** Không đổi mô hình.
:::

#### TC-06-007 · Khóa sai kiểu, biểu thức ReDoS, trùng loại, CMND xác định <!--k:idkey-neg-->

::: dac-ta
**Mục đích.** Chứng minh khóa chỉ khai được trên thuộc tính `IDENTIFIER` và biểu thức không gây quá tải, theo FR-06-003.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, ZAP.

**Truy vết.** FR-06-003 · BR-06-001 · API-06-006, 013 · ERR-06-002, 003, 009.

**Tiền điều kiện, dữ liệu.** DEMO-CANBO DRAFT.

**Các bước.**

1. Gắn khóa `CCCD_12` vào thuộc tính `STRING`.
2. Khai `REGEX` `^(a+)+$`; đo thời gian trả lời.
3. Khai hai khóa `CCCD_12` trong một domain.
4. Khai `CMND_9` với `deterministic = true`.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-009. Bước 2 `400` ERR-06-003 trong ≤ 1 s, không treo CPU. Bước 3 `409` ERR-06-002. Bước 4 `422` ERR-06-003 (CMND_9 bắt buộc `deterministic = false`).

**Hậu điều kiện.** Không khóa nào được lưu.
:::

#### TC-06-008 · Gán và xác nhận phân loại dữ liệu theo PH-09 <!--k:classify-pos-->

::: dac-ta
**Mục đích.** Chứng minh phân loại `PROPOSED` thành `CONFIRMED` qua PH-09 và `SENSITIVE` kéo theo mã hóa, theo FR-06-004.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-004 · BR-06-016 · API-06-006 · UI-06-07.

**Tiền điều kiện, dữ liệu.** CITIZEN DRAFT của T93; PH-09 giả lập xác nhận.

**Các bước.**

1. Xem thuộc tính `idNumber` `PROPOSED`.
2. PH-09 giả lập trả `CONFIRMED` cho `idNumber`, `fullName`, `dateOfBirth`.
3. `GET` lại thuộc tính.

**Kết quả mong đợi.** `ClassificationStatus = CONFIRMED`, `dataClass` giữ `SENSITIVE`, đặt cờ mã hóa envelope và chỉ dùng HMAC trong gom nhóm (BR-06-016). KT: có (classify).

**Hậu điều kiện.** CITIZEN của T93 đủ phân loại, sẵn sàng gửi duyệt ở ca lifecycle-pos.
:::

#### TC-06-009 · Kích hoạt khi DLCN chưa xác nhận; PH-09 ngừng <!--k:classify-neg-->

::: dac-ta
**Mục đích.** Chứng minh không gửi duyệt được mô hình còn thuộc tính DLCN chưa xác nhận, theo FR-06-004.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-004, 006 · BR-06-016 · API-06-008 · ERR-06-010, 021.

**Tiền điều kiện, dữ liệu.** DEMO-CANBO có thuộc tính `ngaySinh` `PROPOSED`.

**Các bước.**

1. `POST .../model-versions/1:submit`.
2. Dừng PH-09 giả lập (`503`), `GET` phân loại.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-010 nêu tên thuộc tính. Bước 2 `503` ERR-06-021, dữ liệu phân loại đang có không mất.

**Thông báo hiển thị.** ERR-06-010 "Thuộc tính {tên} là dữ liệu cá nhân nhưng chưa có phân loại được PH-09 xác nhận." ở dòng thuộc tính, UI-06-07.

**Hậu điều kiện.** Mô hình vẫn DRAFT.
:::

#### TC-06-010 · Tạo phiên bản mới và so sánh tương thích <!--k:version-diff-->

::: dac-ta
**Mục đích.** Chứng minh phiên bản mới từ bản `ACTIVE` và phân loại `NON_BREAKING`, `BREAKING`, theo FR-06-005.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-005 · API-06-004, 005, 007 · BR-06-017 · UI-06-07.

**Tiền điều kiện, dữ liệu.** CITIZEN `ACTIVE` phiên bản 1 ở T90.

**Các bước.**

1. `POST .../model-versions` tạo phiên bản 2; thêm thuộc tính `email`.
2. `GET .../model-versions/2/diff?against=1`.
3. Đổi kiểu `phone` từ `STRING` sang `PHONE` rồi `diff`.

**Kết quả mong đợi.** Bước 2 `CompatLevel = NON_BREAKING`. Bước 3 `BREAKING` kèm danh sách thay đổi và kế hoạch áp lại cần có. Phiên bản 1 vẫn `ACTIVE`.

**Hậu điều kiện.** Phiên bản 2 DRAFT ở T90, dùng ở ca lifecycle-pos.
:::

#### TC-06-011 · Sửa trực tiếp phiên bản ACTIVE và thay đổi phá vỡ <!--k:version-neg-->

::: dac-ta
**Mục đích.** Chứng minh phiên bản `ACTIVE` bất biến, theo BR-06-017.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-005 · BR-06-017 · API-06-006 · ERR-06-004, 008.

**Tiền điều kiện, dữ liệu.** CITIZEN `ACTIVE` phiên bản 1.

**Các bước.**

1. `PUT .../model-versions/1` đổi tên thuộc tính.
2. `PUT .../model-versions/2` với `If-Match` cũ.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-008 "cần phiên bản mới". Bước 2 `409` ERR-06-004. Phiên bản 1 không đổi byte nào (so `ETag`).

**Hậu điều kiện.** Không đổi.
:::

### TS-06-03 · Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain

**Mục tiêu.** Xác nhận vòng đời domain có bốn mắt, trạng thái cấm bị chặn và sự kiện kích hoạt phát đúng.

**Phủ.** FR-06-006; UC-06-03; API-06-008…011; UI-06-07; BR-06-016, 017; EVT-06-10.

#### TC-06-012 · Gửi duyệt rồi DA khác kích hoạt phiên bản <!--k:lifecycle-pos-->

::: dac-ta
**Mục đích.** Chứng minh DRAFT, PENDING_APPROVAL, ACTIVE, phiên bản cũ thành SUPERSEDED, theo FR-06-006.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-06-006 · API-06-008, 009 · EVT-06-10 · BR-06-017 · PERM-06-approve.

**Tiền điều kiện, dữ liệu.** CITIZEN phiên bản 2 của ca version-diff (T90, NON_BREAKING); DS1 đề nghị, DA1 duyệt.

**Các bước.**

1. DS1 `POST .../model-versions/2:submit`.
2. DA1 `POST .../model-versions/2:approve`.
3. Đọc topic `t90.mdm.model.activated.v1`.

**Kết quả mong đợi.** Bước 1 `200` `PENDING_APPROVAL`. Bước 2 `200` `ACTIVE`, phiên bản 1 `SUPERSEDED`. Bước 3 đúng một bản tin EVT-06-10 chỉ có mã domain, phiên bản. KT: có (submit, approve).

**Hậu điều kiện.** CITIZEN phiên bản 2 ACTIVE.
:::

#### TC-06-013 · Tự duyệt bị chặn; từ chối <!--k:lifecycle-4eyes-->

::: dac-ta
**Mục đích.** Chứng minh người đề nghị không tự duyệt kể cả TA có cả hai quyền, theo FR-06-006 và ADR-046.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-006 · API-06-008, 009, 010 · ERR-06-005, 007 · BR-06-004.

**Tiền điều kiện, dữ liệu.** DEMO-CANBO đủ phân loại; U-T90-TA (soạn và duyệt), DA1.

**Các bước.**

1. TA `submit` rồi TA `approve` chính bản đó.
2. DA1 `reject` không lý do.
3. DA1 `reject` với lý do 30 ký tự.

**Kết quả mong đợi.** Bước 1 `403` ERR-06-005. Bước 2 `422` ERR-06-007. Bước 3 `200` `REJECTED`, ý kiến lưu. KT: có (reject).

**Thông báo hiển thị.** ERR-06-005 "Anh/chị là người đề nghị nên không được tự duyệt." ở hộp cảnh báo trên nút Duyệt.

**Hậu điều kiện.** Phiên bản REJECTED; không phát EVT-06-10.
:::

#### TC-06-014 · Tạm ngừng, tiếp tục, ngừng; ngừng khi còn bản ghi vàng <!--k:lifecycle-suspend-->

::: dac-ta
**Mục đích.** Chứng minh chuyển trạng thái domain hợp lệ và chặn chuyển cấm, theo FR-06-006.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-006 · API-06-011 · ERR-06-006, 011 · BR-06-007.

**Tiền điều kiện, dữ liệu.** DEMO-CANBO `ACTIVE` không có bản ghi vàng; CITIZEN `ACTIVE` có bản ghi vàng.

**Các bước.**

1. `POST /domains/DEMO-CANBO:suspend`, nạp ứng viên, `:resume`.
2. `:retire` DEMO-CANBO; sau đó `:resume` lần nữa.
3. `:retire` CITIZEN.

**Kết quả mong đợi.** Bước 1 SUSPENDED nhận ứng viên bị từ chối rồi ACTIVE nhận lại. Bước 2 `RETIRED`; `:resume` `409` ERR-06-006. Bước 3 `422` ERR-06-011. KT: có (suspend, resume, retire).

**Hậu điều kiện.** DEMO-CANBO RETIRED, CITIZEN không đổi.
:::

### TS-06-04 · Nguồn và ưu tiên nguồn

**Mục tiêu.** Xác nhận đăng ký nguồn gắn HTTT ACTIVE, thứ tự ưu tiên có căn cứ văn bản và bốn mắt, nguồn quốc gia luôn mức 1 với thuộc tính thẩm quyền.

**Phủ.** FR-06-008, 009; UC-06-04; API-06-014…020; UI-06-08; BR-06-003, 004, 032; ERR-06-005, 012, 013.

#### TC-06-015 · Đăng ký nguồn gắn HTTT và kênh nạp <!--k:src-create-->

::: dac-ta
**Mục đích.** Chứng minh đăng ký `QG-DANCU` kiểu `NATIONAL_DB` qua kênh `NATIONAL_SYNC` và `HT-YTE` qua `API`, `FLOW`, theo FR-06-008.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-008 · API-06-014, 015, 016 · UI-06-08 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** T90; HTTT `HT-YTE`, `HT-GIAODUC` `ACTIVE` ở PH-01; TA.

**Các bước.**

1. `POST /sources` mã `HT-YTE`, `SourceKind = SECTOR_RELATED`, kênh `API`, `FLOW`.
2. `PATCH /sources/HT-YTE` thêm kênh `EVENT`.
3. `POST /sources/HT-YTE:suspend` rồi `:resume`.

**Kết quả mong đợi.** Nguồn `DRAFT` rồi `ACTIVE`; kênh cập nhật; tạm ngừng rồi tiếp tục đúng `SourceStatus`. Nguồn quốc gia chỉ nhận kênh `NATIONAL_SYNC`. KT: có (source-create, source-update).

**Hậu điều kiện.** Nguồn HT-YTE ACTIVE dùng cho các ca nạp.
:::

#### TC-06-016 · HTTT chưa ACTIVE, trùng mã, trỏ thẳng CSDL quốc gia <!--k:src-neg-->

::: dac-ta
**Mục đích.** Chứng minh nguồn phải gắn HTTT `ACTIVE` và PH-06 không gọi thẳng CSDL quốc gia, theo BR-06-032.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-008 · BR-06-032 · API-06-015 · ERR-06-002, 003, 012.

**Tiền điều kiện, dữ liệu.** HTTT `HT-MOI` `DRAFT` ở PH-01; nguồn `HT-YTE` đã có.

**Các bước.**

1. `POST /sources` mã `HT-MOI`.
2. `POST /sources` mã `HT-YTE`.
3. `POST /sources` kiểu `NATIONAL_DB` có `endpoint = https://csdl-quocgia.example`.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-012. Bước 2 `409` ERR-06-002. Bước 3 `400` ERR-06-003: không có trường `endpoint`, nguồn quốc gia chỉ đi qua PH-14; egress từ `dh-data` tới host ngoài bị NetworkPolicy chặn (kiểm bằng `curl` trong pod, kết nối bị từ chối).

**Hậu điều kiện.** Không nguồn mới.
:::

#### TC-06-017 · Đề xuất và duyệt thứ tự ưu tiên có văn bản <!--k:prio-approve-->

::: dac-ta
**Mục đích.** Chứng minh thứ tự ưu tiên chỉ có hiệu lực khi có căn cứ và DA khác duyệt, và `QG-DANCU` mức 1 cho thuộc tính thẩm quyền, theo FR-06-009.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-009 · BR-06-003, 004 · API-06-018, 019, 020 · UI-06-08 · PERM-06-approve.

**Tiền điều kiện, dữ liệu.** Nguồn `QG-DANCU`, `HT-YTE`, `HT-GIAODUC` ACTIVE; DS1 đề nghị, DA1 duyệt.

**Các bước.**

1. `POST /domains/CITIZEN/source-priorities:propose` đặt `QG-DANCU` 1, `HT-YTE` 2, `HT-GIAODUC` 3, kèm số, ngày văn bản `12/QĐ-SKHCN`.
2. DA1 `POST /source-priority-proposals/{id}:approve`.
3. `GET /domains/CITIZEN/source-priorities`.

**Kết quả mong đợi.** Bước 1 `201` `PENDING_APPROVAL`. Bước 2 `200`. Bước 3 thứ tự áp dụng, thuộc tính `dateOfBirth`, `idNumber` đánh dấu `nationalAuthority` có `QG-DANCU` mức 1. KT: có (priority-propose, priority-approve).

**Hậu điều kiện.** Bảng ưu tiên ACTIVE dùng ở các ca sống sót, golden-create.
:::

#### TC-06-018 · Thiếu căn cứ, tự duyệt, nguồn quốc gia không mức 1 <!--k:prio-neg-->

::: dac-ta
**Mục đích.** Chứng minh ba điều kiện chặn của FR-06-009.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-009 · BR-06-003, 004 · ERR-06-005, 013, 022.

**Tiền điều kiện, dữ liệu.** Như prio-approve; thêm đề xuất của DS1.

**Các bước.**

1. `propose` không có số, ngày văn bản.
2. DS1 `approve` đề xuất do chính DS1 gửi.
3. `propose` đặt `HT-YTE` mức 1 cho `dateOfBirth` (thuộc tính thẩm quyền).

**Kết quả mong đợi.** Bước 1 `422` ERR-06-013. Bước 2 `403` ERR-06-005 (và 403-PQ vì DS không có `approve`). Bước 3 `422` ERR-06-022 (vi phạm BR-06-003).

**Thông báo hiển thị.** ERR-06-013 "Nhập số, ngày văn bản phê duyệt thứ tự ưu tiên nguồn." dưới ô căn cứ, UI-06-08.

**Hậu điều kiện.** Bảng ưu tiên không đổi.
:::

#### TC-06-019 · Nguồn tạm ngừng không nạp được <!--k:src-lifecycle-->

::: dac-ta
**Mục đích.** Chứng minh nguồn `SUSPENDED` hoặc `RETIRED` bị từ chối nạp ứng viên, theo FR-06-008.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-008 · API-06-017, 021 · ERR-06-014.

**Tiền điều kiện, dữ liệu.** Nguồn `HT-GIAODUC` ACTIVE; S-T90-INGEST-HT-GIAODUC.

**Các bước.**

1. `:suspend` nguồn; gửi một ứng viên.
2. `:resume`; gửi lại.
3. `:retire`; gửi lại.

**Kết quả mong đợi.** Bước 1 `403` ERR-06-014. Bước 2 `202` `RECEIVED`. Bước 3 `403` ERR-06-014; liên kết đã có không đổi.

**Thông báo hiển thị.** ERR-06-014 "Hệ thống {mã} chưa được đăng ký làm nguồn cho domain {domain}."

**Hậu điều kiện.** Nguồn HT-GIAODUC RETIRED; dùng nguồn FILE-NHAP cho ca sau.
:::

### TS-06-05 · Nạp ứng viên qua API, luồng PH-04 và sự kiện PH-10

**Mục tiêu.** Xác nhận ba kênh nạp trực tuyến nhận đúng, lũy đẳng, chặn nguồn lạ và vượt hạn mức.

**Phủ.** FR-06-010, 011, 012; UC-06-05; API-06-016, 021, 022; BR-06-018, 028, 029; EVT-06-07; ERR-06-014…018, 048, 110.

#### TC-06-020 · Nạp ứng viên qua API và phát sự kiện nhận lô <!--k:ingest-api-->

::: dac-ta
**Mục đích.** Chứng minh `POST candidates` nhận đúng, trả `202` và trạng thái, theo FR-06-010.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-06-010 · API-06-021 · EVT-06-07 · BR-06-028 · NFR-06-004.

**Tiền điều kiện, dữ liệu.** Nguồn `HT-YTE` ACTIVE; S-T90-INGEST-HT-YTE; bản ghi F-CIT số 1.

**Các bước.**

1. `POST /domains/CITIZEN/candidates` với `Idempotency-Key`, `sourceKey = YT-0001`, `sourceVersion = 1`, `operation = CREATE`.
2. `GET /domains/CITIZEN/candidates/{id}`.
3. Đọc topic `t90.mdm.candidate.ingested.v1`.

**Kết quả mong đợi.** Bước 1 `202` `RECEIVED`. Bước 2 chuyển tới `NORMALIZED` rồi `LINKED` hoặc `QUEUED` trong ≤ 10 s, `raw` và `normalized` cạnh nhau. Bước 3 một bản tin gộp, chỉ số lượng, không chứa giá trị. KT: có (candidate-ingest).

**Hậu điều kiện.** Ứng viên YT-0001 dùng ở ca golden-create.
:::

#### TC-06-021 · Thiếu sourceKey, sai lược đồ, quá lô, nguồn lạ, vượt hạn mức <!--k:ingest-api-neg-->

::: dac-ta
**Mục đích.** Chứng minh năm nhánh lỗi nạp, theo FR-06-010.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-010 · API-06-021 · ERR-06-014, 016, 017, 018, 048.

**Tiền điều kiện, dữ liệu.** T92 (`06.ingest.rate-per-source = 600`); S-T90-INGEST-HT-YTE.

**Các bước.**

1. Gửi bản ghi không `sourceKey`.
2. Gửi bản ghi thiếu thuộc tính bắt buộc, kiểu `DATE` sai.
3. Gửi lô 10.001 bản ghi.
4. Dùng token của `HT-GIAODUC` gửi cho nguồn `HT-YTE`.
5. Ở T92 gửi 700 bản ghi trong một phút.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-016. Bước 2 `422` ERR-06-017 liệt kê trường. Bước 3 `413` ERR-06-018. Bước 4 `403` ERR-06-014. Bước 5 bản ghi 601 trở đi `429` ERR-06-048 kèm `Retry-After`.

**Thông báo hiển thị.** ERR-06-017 "Bản ghi không đúng mô hình {domain} phiên bản {n}: {danh sách trường}."

**Hậu điều kiện.** Không ứng viên nào từ các bước lỗi.
:::

#### TC-06-022 · Lũy đẳng bằng Idempotency-Key và sourceVersion <!--k:ingest-idem-->

::: dac-ta
**Mục đích.** Chứng minh mỗi `(sourceCode, sourceKey, sourceVersion)` xử lý một lần và khóa lũy đẳng có hiệu lực 24 giờ, theo BR-06-028.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-010, 016 · BR-06-028, 029 · ERR-06-015.

**Tiền điều kiện, dữ liệu.** YT-0001 phiên bản 1 đã nạp.

**Các bước.**

1. Gửi lại đúng thân, cùng `Idempotency-Key`.
2. Gửi `Idempotency-Key` cũ với thân khác.
3. Gửi khóa mới, cùng `(HT-YTE, YT-0001, 1)`.

**Kết quả mong đợi.** Bước 1 `202` trả đúng kết quả cũ, không thêm ứng viên. Bước 2 `409` ERR-06-015. Bước 3 ứng viên mới `DUPLICATE`, không đối sánh lại.

**Hậu điều kiện.** Chỉ một ứng viên có hiệu lực.
:::

#### TC-06-023 · Nạp qua luồng PH-04 bằng API nội bộ <!--k:ingest-flow-->

::: dac-ta
**Mục đích.** Chứng minh `dh-runtime` nạp thay nguồn đã đăng ký và không nạp thay nguồn khác, theo FR-06-011.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-011 · API-06-022 · ERR-06-014.

**Tiền điều kiện, dữ liệu.** Luồng giả `luong-yte` gắn nguồn `HT-YTE`; token `dh-runtime` T90.

**Các bước.**

1. `POST /internal/domains/CITIZEN/candidates` từ `luong-yte` với `sourceCode = HT-YTE`.
2. Cùng luồng gửi `sourceCode = QG-DANCU`.
3. Gọi API nội bộ từ ngoài mạng nội bộ qua APISIX.

**Kết quả mong đợi.** Bước 1 `202`, kênh `FLOW`. Bước 2 `403` ERR-06-014, nhật ký luồng PH-04 có câu "Luồng {mã} không được gửi dữ liệu thay nguồn {nguồn}". Bước 3 `404` (đường dẫn `/internal` không công bố ở cổng).

**Hậu điều kiện.** Một ứng viên kênh FLOW.
:::

#### TC-06-024 · Nạp qua sự kiện PH-10; sự kiện sai lược đồ vào DLQ <!--k:ingest-event-->

::: dac-ta
**Mục đích.** Chứng minh bộ nhận sự kiện nạp ứng viên đúng và không mất sự kiện hỏng, theo FR-06-012.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT, KT.

**Truy vết.** FR-06-012 · API-06-016 · ERR-06-110 · EVT-06-07.

**Tiền điều kiện, dữ liệu.** Nguồn `HT-YTE` bật kênh `EVENT` với topic `t90.yte.cong-dan.cap-nhat.v1`.

**Các bước.**

1. Đẩy 10 sự kiện hợp lệ.
2. Đẩy 1 sự kiện sai lược đồ.

**Kết quả mong đợi.** Bước 1 10 ứng viên kênh `EVENT`. Bước 2 sự kiện vào DLQ của PH-10, ghi ERR-06-110, bộ nhận không dừng; không ứng viên nào từ sự kiện hỏng.

**Hậu điều kiện.** DLQ có đúng 1 mục.
:::

### TS-06-06 · Nạp tệp lô có xem trước

**Mục tiêu.** Xác nhận nạp tệp hai pha: kiểm trước, xem trước 50 dòng, xác nhận mới ghi.

**Phủ.** FR-06-013; UC-06-06; API-06-023, 024, 025; UI-06-11; ERR-06-018, 019.

#### TC-06-025 · Nạp tệp 2.000 dòng có xem trước và xác nhận <!--k:file-pos-->

::: dac-ta
**Mục đích.** Chứng minh pha 1 báo cáo lỗi theo dòng, pha 2 chỉ ghi sau xác nhận, theo FR-06-013.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-013 · API-06-023, 024, 025 · UI-06-11 · PERM-06-ingest.

**Tiền điều kiện, dữ liệu.** F-FILE `ung-vien-2000.xlsx` (50 dòng lỗi); DS1; nguồn `FILE-NHAP`.

**Các bước.**

1. `POST /domains/CITIZEN/candidate-files` tải tệp; chờ pha 1.
2. `GET /candidate-files/{id}`: xem báo cáo và 50 dòng đầu.
3. Chọn "Chỉ nạp dòng hợp lệ", `:confirm`.

**Kết quả mong đợi.** Pha 1 báo cáo 50 dòng lỗi theo dòng, cột; chưa có ứng viên nào. Sau `:confirm` job `FILE_INGEST` `SUCCEEDED`, 1.950 ứng viên kênh `FILE`, `sourceKey = fileId:dòng`. Tệp tạm ở Garage mã hóa, xóa sau xử lý. KT: có (file-confirm).

**Hậu điều kiện.** 1.950 ứng viên của `FILE-NHAP`.
:::

#### TC-06-026 · Tệp có công thức, quá lớn, tất cả hoặc không <!--k:file-neg-->

::: dac-ta
**Mục đích.** Chứng minh tệp sai khuôn bị chặn và mặc định "tất cả hoặc không", theo FR-06-013.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-013 · API-06-023, 024 · ERR-06-018, 019.

**Tiền điều kiện, dữ liệu.** F-FILE `ung-vien-cong-thuc.xlsx`, `ung-vien-lon.csv`, `ung-vien-2000.xlsx`.

**Các bước.**

1. Tải tệp có công thức `=HYPERLINK(...)`.
2. Tải tệp vượt giới hạn.
3. Tải tệp 2.000 dòng có 50 dòng lỗi, `:confirm` mặc định.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-019, không có ứng viên. Bước 2 `413` ERR-06-018. Bước 3 từ chối nạp, 0 ứng viên mới.

**Hậu điều kiện.** Không ứng viên.
:::

### TS-06-07 · Chuẩn hóa ứng viên và xử lý ứng viên lỗi

**Mục tiêu.** Xác nhận chuẩn hóa tên, ngày, định danh, địa chỉ, chống trùng, thứ tự phiên bản, xóa từ nguồn và xử lý ứng viên lỗi.

**Phủ.** FR-06-014, 015, 016, 017; UC-06-07; API-06-026…029; UI-06-11; BR-06-001, 009, 015, 028, 029, 033; ERR-06-007, 020, 021.

#### TC-06-027 · Chuẩn hóa họ tên và tên pháp nhân <!--k:norm-name-->

::: dac-ta
**Mục đích.** Chứng minh `nameAscii`, `nameKey`, tách họ, tên đệm, tên, tiền tố loại hình, theo FR-06-014.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-06-014 · API-06-029 · UI-06-11 · BR-06-001.

**Tiền điều kiện, dữ liệu.** F-CIT, F-ORG.

**Các bước.**

1. `POST /normalization:preview` với `NGUYEN VAN A` và `Nguyễn Văn  A` (hai dấu cách).
2. Với `Đặng Thị Hồng`, `Công ty TNHH Thương mại Hoa Sen`, `CTCP Hoa Sen`.

**Kết quả mong đợi.** Bước 1 cùng `nameAscii = nguyen van a`, hoa chữ đầu, NFC. Bước 2 `nameAscii = dang thi hong`, `givenName = Hồng`; hai tổ chức cùng phần lõi `hoa sen`, `orgFormToken` `TNHH`, `CTCP`.

**Hậu điều kiện.** Không lưu.
:::

#### TC-06-028 · Chuẩn hóa ngày, điện thoại, số định danh <!--k:norm-date-id-->

::: dac-ta
**Mục đích.** Chứng minh ngày nhiều dạng, giá trị giả và số định danh sai không dùng làm khóa, theo FR-06-014.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-06-014 · BR-06-001, 015 · API-06-029 · UI-06-11.

**Tiền điều kiện, dữ liệu.** CC-01, CC-X, MST-X.

**Các bước.**

1. Preview ngày `12/03/1990`, `1990-03-12`, `19900312`, `1990`, `01/01/1900`, `00/00/0000`, ngày tương lai.
2. Preview `CC-01` có dấu chấm, `CC-X`, `MST-X`.
3. Điện thoại `+84 912 345 678`, email `AN@Mail.COM`.

**Kết quả mong đợi.** Bước 1 ba dạng đầu ra `1990-03-12` `DAY`; `1990` `YEAR`; ba giá trị giả `MISSING` cảnh báo `DATE_PLACEHOLDER`. Bước 2 CC-01 sạch `VALID`; `CC-X`, `MST-X` `identifierStatus` không hợp lệ, cảnh báo `IDENTIFIER_INVALID`, không dùng làm khóa. Bước 3 `0912345678`, `an@mail.com`.

**Hậu điều kiện.** Không lưu.
:::

#### TC-06-029 · Chuẩn hóa địa chỉ theo ĐVHC của PH-07 <!--k:norm-address-->

::: dac-ta
**Mục đích.** Chứng minh mã ĐVHC hiện hành, chuyển mã cũ và cảnh báo mã lạ, theo FR-06-015.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-015 · BR-06-033 · ERR-06-020, 021 · UI-06-11.

**Tiền điều kiện, dữ liệu.** F-ADDR; PH-07 giả lập mã cũ một-một, một-nhiều, mã lạ.

**Các bước.**

1. Nạp địa chỉ mã hiện hành, mã cũ một-một, mã cũ một-nhiều, mã không tồn tại, chuỗi không tách được.
2. Dừng PH-07, nạp một địa chỉ.

**Kết quả mong đợi.** Bước 1 lần lượt không cảnh báo; `ADMIN_UNIT_CONVERTED` kèm `legacyAdminUnitCode`; `ADMIN_UNIT_SPLIT` đưa vào xem xét; `ADMIN_UNIT_UNKNOWN` (ERR-06-020 là cảnh báo, ứng viên vẫn đi tiếp); `ADDRESS_UNPARSED`. Bản ghi vàng chỉ giữ mã hiện hành. Bước 2 `NORMALIZATION_PENDING`, ERR-06-021 ở nhật ký; khi PH-07 lại, tự xử lý.

**Hậu điều kiện.** Ứng viên địa chỉ có cảnh báo.
:::

#### TC-06-030 · Chống trùng và bản ghi nguồn đến trễ <!--k:cand-dup-order-->

::: dac-ta
**Mục đích.** Chứng minh phiên bản nhỏ hơn không ghi đè giá trị mới hơn cùng nguồn, theo BR-06-029.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-016 · BR-06-028, 029, 009 · API-06-021.

**Tiền điều kiện, dữ liệu.** `HT-YTE`/`YT-0002` phiên bản 5 đã LINKED với `phone = 0901000001`.

**Các bước.**

1. Gửi phiên bản 3 với `phone = 0902000002`.
2. Gửi phiên bản 6 với `phone = 0903000003`.
3. Gửi lại phiên bản 6.

**Kết quả mong đợi.** Bước 1 ứng viên `SUPERSEDED`, bản ghi vàng giữ `0901000001`. Bước 2 `phone` bản ghi vàng đổi `0903000003`, nguồn ở cấp thuộc tính là `HT-YTE`. Bước 3 `DUPLICATE`.

**Hậu điều kiện.** Bản ghi vàng YT-0002 phiên bản 6.
:::

#### TC-06-031 · Xóa từ nguồn gỡ liên kết, không xóa bản ghi vàng <!--k:cand-delete-->

::: dac-ta
**Mục đích.** Chứng minh `operation = DELETE` gỡ liên kết chéo, tính lại sống sót và chỉ đề nghị ngừng qua hàng đợi, theo FR-06-016.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-016 · BR-06-007, 018 · EVT-06-02.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng có hai liên kết `HT-YTE`, `HT-GIAODUC`; thuộc tính `phone` do `HT-YTE`.

**Các bước.**

1. `HT-YTE` gửi `DELETE` cho `sourceKey`.
2. `HT-GIAODUC` gửi `DELETE` cho liên kết còn lại.

**Kết quả mong đợi.** Bước 1 xref `DETACHED` lý do `SOURCE_DELETED`, `phone` lấy từ nguồn còn lại, EVT-06-02. Bước 2 bản ghi vàng hết liên kết hiệu lực: mục hàng đợi `ORPHANED` đề nghị ngừng, bản ghi vẫn `ACTIVE`, không tự `RETIRED`.

**Hậu điều kiện.** Một mục ORPHANED.
:::

#### TC-06-032 · Xem, xử lý lại và loại bỏ ứng viên lỗi <!--k:cand-handle-->

::: dac-ta
**Mục đích.** Chứng minh lọc, xem ứng viên, xử lý lại, loại bỏ có lý do, theo FR-06-017.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-017 · BR-06-008, 010 · API-06-026, 027, 028 · ERR-06-007 · PERM-06-update.

**Tiền điều kiện, dữ liệu.** T90 có 5 ứng viên `REJECTED`, 3 cảnh báo; DS1.

**Các bước.**

1. `GET .../candidates?status=REJECTED&page=0&size=3`.
2. `:reprocess` ứng viên đã sửa mô hình; `:discard` không lý do; `:discard` với lý do 25 ký tự.
3. `GET` chi tiết ứng viên.

**Kết quả mong đợi.** Bước 1 3 phần tử, trường `SENSITIVE` che. Bước 2 reprocess `200` `NORMALIZED`; discard thiếu lý do `422` ERR-06-007; có lý do `DISCARDED`. Bước 3 NK: có, KT: có (discard).

**Hậu điều kiện.** Ứng viên `DISCARDED` giữ dòng rút gọn.
:::

### TS-06-08 · Bộ quy tắc đối sánh, khóa gom nhóm và ngưỡng

**Mục tiêu.** Xác nhận soạn bộ quy tắc có phiên bản, quy tắc loại trừ bất biến, khóa gom nhóm hiệu quả và ngưỡng trong miền.

**Phủ.** FR-06-018, 019, 023; UC-06-08; API-06-030…032, 035, 036; UI-06-09; BR-06-006, 020; ERR-06-003, 022, 023.

#### TC-06-033 · Soạn bộ quy tắc xác định, xác suất, loại trừ <!--k:rules-create-->

::: dac-ta
**Mục đích.** Chứng minh bộ quy tắc có đủ ba `MatchRuleType` và các `Comparator`, theo FR-06-018.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-018 · API-06-030, 031, 032 · UI-06-09 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** CITIZEN `ACTIVE`; DS1.

**Các bước.**

1. `POST .../rule-sets` phiên bản 1 `DRAFT`.
2. `PUT .../rule-sets/1` với: `DETERMINISTIC` `idNumber`; `PROBABILISTIC` `fullName` `NAME_VN` trọng số 4, `dateOfBirth` `DATE_TOLERANCE`, `phone` `PHONE`; `EXCLUSION` khóa định danh khác nhau.

**Kết quả mong đợi.** `200`, lưu đủ ba loại, `ETag` mới; `GET` trả đúng. KT: có (ruleset-update).

**Hậu điều kiện.** Bộ quy tắc v1 DRAFT dùng ở các ca sau.
:::

#### TC-06-034 · Bỏ quy tắc loại trừ, comparator sai <!--k:rules-neg-->

::: dac-ta
**Mục đích.** Chứng minh quy tắc loại trừ khóa định danh khác nhau không tắt được, theo BR-06-006.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-018 · BR-06-006 · API-06-032 · ERR-06-003, 022.

**Tiền điều kiện, dữ liệu.** Bộ quy tắc v1 DRAFT.

**Các bước.**

1. `PUT` xóa quy tắc `EXCLUSION` khóa định danh.
2. `PUT` đặt `enabled = false` cho nó.
3. `PUT` `Comparator = SOUNDEX`.

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-06-022 (BR-06-006). Bước 3 `400` ERR-06-003.

**Hậu điều kiện.** Bộ quy tắc không đổi.
:::

#### TC-06-035 · Khóa gom nhóm và thống kê hiệu quả <!--k:blocking-stats-->

::: dac-ta
**Mục đích.** Chứng minh gom nhóm giảm tập so sánh và dùng HMAC cho thuộc tính nhạy cảm, theo FR-06-019.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-06-019 · API-06-036 · NFR-06-006 · BR-06-016 · UI-06-09.

**Tiền điều kiện, dữ liệu.** T97 F-PERF; bộ quy tắc có khóa gom `nameKey + năm sinh`, `phone`.

**Các bước.**

1. `GET .../rule-sets/1/blocking-stats`.
2. Kiểm khối chứa giá trị `idNumber` trong bảng khóa gom.

**Kết quả mong đợi.** Bước 1 số ứng viên trung bình mỗi lượt ≤ 50, độ phủ cặp đúng ≥ 99,5 % trên F-LBL; khối > 200 cắt, tăng `mdm_block_truncated_total`. Bước 2 chỉ có HMAC, không rõ.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-036 · Đặt ngưỡng trong và ngoài miền <!--k:threshold-->

::: dac-ta
**Mục đích.** Chứng minh ngưỡng tự hợp nhất ≥ 0,90 và cách ngưỡng xem xét ≥ 0,10, theo BR-06-020.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-023 · BR-06-020 · API-06-032 · ERR-06-023 · UI-06-09.

**Tiền điều kiện, dữ liệu.** Bộ quy tắc v1 DRAFT.

**Các bước.**

1. Đặt `autoMergeThreshold = 0,92`, `reviewThreshold = 0,15`.
2. Đặt `0,85`.
3. Đặt `0,92` và `reviewThreshold = 0,85`.
4. Đổi ngưỡng ở bản `ACTIVE`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2, 3 `422` ERR-06-023. Bước 4 `422` ERR-06-008 (cần phiên bản mới, đánh giá lại).

**Thông báo hiển thị.** ERR-06-023 "Ngưỡng tự hợp nhất phải từ 0,90 trở lên và cao hơn ngưỡng xem xét ít nhất 0,10." dưới thanh trượt.

**Hậu điều kiện.** v1 ngưỡng 0,92/0,15.
:::

### TS-06-09 · Tập nhãn, chạy thử, đánh giá và kích hoạt bộ quy tắc

**Mục tiêu.** Xác nhận bộ quy tắc chỉ kích hoạt khi đánh giá đạt precision ≥ 99,9 % và recall ≥ 98 % trên tập nhãn ≥ 1.000 cặp.

**Phủ.** FR-06-024, 025, 026; UC-06-09; API-06-033…035, 037…040; UI-06-09, 13; BR-06-021; NFR-06-008, 009; EVT-06-11; ERR-06-024, 026.

#### TC-06-037 · Tập nhãn: tạo, thêm cặp, khóa; tập quá nhỏ <!--k:label-sets-->

::: dac-ta
**Mục đích.** Chứng minh quản lý tập nhãn `EVALUATION` và chặn tập dưới 1.000 cặp, theo FR-06-025.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-025 · API-06-037, 038, 039 · UI-06-13 · ERR-06-002, 003, 006, 026 · PERM-06-steward.

**Tiền điều kiện, dữ liệu.** T96; DS1, DS2.

**Các bước.**

1. Tạo tập `NHAN-A`, thêm 200 cặp `PairLabel` `MATCH`, `NO_MATCH`; thêm nhãn `MAYBE`.
2. Tạo tập `NHAN-A` lần hai.
3. Chạy đánh giá trên `NHAN-A`.
4. Thêm cặp vào tập đã khóa.

**Kết quả mong đợi.** Bước 1 nhận 200 cặp, nhãn `MAYBE` `400` ERR-06-003. Bước 2 `409` ERR-06-002. Bước 3 `422` ERR-06-026. Bước 4 `409` ERR-06-006.

**Hậu điều kiện.** Tập `NHAN-A` 200 cặp; F-LBL đã nạp thành `NHAN-12K`.
:::

#### TC-06-038 · Chạy thử bộ quy tắc trên mẫu <!--k:dry-run-->

::: dac-ta
**Mục đích.** Chứng minh chạy thử cho số cặp theo vùng và mẫu 100 cặp mà không đổi dữ liệu, theo FR-06-024.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, JOB.

**Truy vết.** FR-06-024 · API-06-033 · UI-06-09.

**Tiền điều kiện, dữ liệu.** Bộ quy tắc v1 DRAFT, T96 có 100.000 ứng viên.

**Các bước.**

1. `POST .../rule-sets/1:dry-run` mẫu 5.000 bản ghi.
2. Đếm bản ghi vàng, ứng viên trước và sau.

**Kết quả mong đợi.** Job `RULE_DRY_RUN` `SUCCEEDED`; báo cáo số cặp `MATCH`, `POSSIBLE_MATCH`, `NO_MATCH`, mẫu 100 cặp. Số bản ghi vàng, ứng viên, mục hàng đợi không đổi.

**Hậu điều kiện.** Không đổi dữ liệu.
:::

#### TC-06-039 · Đánh giá đạt và kích hoạt có bốn mắt <!--k:eval-pass-->

::: dac-ta
**Mục đích.** Chứng minh đánh giá trên `NHAN-12K` cho verdict `PASSED` và kích hoạt qua DA khác, theo FR-06-026.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** ACC, API.

**Truy vết.** FR-06-026 · BR-06-021 · NFR-06-008, 009 · API-06-034, 035 · EVT-06-11 · PERM-06-approve.

**Tiền điều kiện, dữ liệu.** Bộ quy tắc đã tinh chỉnh; tập `NHAN-12K` 12.000 cặp; DS1, DA1.

**Các bước.**

1. `POST .../rule-sets/2:evaluate` với `NHAN-12K`.
2. DS1 `submit`, DA1 `approve`.
3. Đọc `t90.mdm.ruleset.activated.v1`.

**Kết quả mong đợi.** Báo cáo precision ≥ 99,9 %, recall ≥ 98 %, ma trận nhầm lẫn TP, FP, FN, TN, `EvaluationVerdict = PASSED`. Bộ quy tắc `ACTIVE`, bản cũ `SUPERSEDED`, một bản tin EVT-06-11. KT: có (ruleset-activate).

**Hậu điều kiện.** Bộ quy tắc v2 ACTIVE ở T96.
:::

#### TC-06-040 · Đánh giá không đạt chặn kích hoạt <!--k:eval-fail-->

::: dac-ta
**Mục đích.** Chứng minh bộ quy tắc precision 99,5 % không kích hoạt được và tự hợp nhất bị tắt khi đánh giá tháng không đạt, theo FR-06-026.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** ACC, API.

**Truy vết.** FR-06-026 · BR-06-021 · API-06-034, 035 · ERR-06-024, 005.

**Tiền điều kiện, dữ liệu.** Bộ quy tắc v3 cố ý nới (trọng số tên thấp); `06.match.auto-disable-on-fail = true`.

**Các bước.**

1. `evaluate` v3.
2. `submit` rồi `approve` v3.
3. Chạy đánh giá định kỳ tháng trên bộ `ACTIVE` đã bị làm nhiễu.

**Kết quả mong đợi.** Bước 1 `FAILED`, precision 99,5 %. Bước 2 `422` ERR-06-024 "Phiên bản 3 chưa đạt: precision 99,5%, recall …". Bước 3 tự hợp nhất bị tắt, mọi `MATCH` trực tuyến thành `POSSIBLE_MATCH`, cảnh báo PH-13 (ĐN-UC-07).

**Thông báo hiển thị.** ERR-06-024 "Phiên bản {n} chưa đạt: precision {p}%, recall {r}%." hộp cảnh báo đầu UI-06-09.

**Hậu điều kiện.** v3 không ACTIVE.
:::

### TS-06-10 · Đối sánh tự động và tạo, cập nhật bản ghi vàng

**Mục tiêu.** Xác nhận đối sánh xác định, xác suất trực tuyến, nhận diện xung đột định danh và tạo, cập nhật bản ghi vàng đúng, có ảnh chụp lịch sử.

**Phủ.** FR-06-020, 021, 034; UC-06-10; API-06-071; BR-06-001, 002, 005, 006, 015, 018, 023; ERR-06-111; EVT-06-01, 02.

#### TC-06-041 · Đối sánh xác định theo CCCD hợp lệ <!--k:det-match-->

::: dac-ta
**Mục đích.** Chứng minh cùng CCCD hợp lệ cho `MATCH` `DETERMINISTIC` điểm 1,0 dù tên khác, theo BR-06-001.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-020 · BR-06-001 · NFR-06-010 · API-06-071.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng An CC-01; nguồn `HT-GIAODUC`.

**Các bước.**

1. Gửi ứng viên CC-01 tên `NGUYEN V. AN`, ngày sinh sai tháng.

**Kết quả mong đợi.** `outcome = MATCH`, `method = DETERMINISTIC`, `score = 1,0`; ứng viên `LINKED` vào bản ghi vàng An; tên không đổi nếu nguồn ưu tiên thấp hơn. EVT-06-02 nếu thuộc tính đổi.

**Hậu điều kiện.** An có thêm một liên kết.
:::

#### TC-06-042 · Khóa sai kiểm tra không dùng đối sánh xác định <!--k:det-invalid-->

::: dac-ta
**Mục đích.** Chứng minh `CC-X` và `MST-X` rơi xuống đối sánh xác suất, theo BR-06-001.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-020 · BR-06-001 · NFR-06-010.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng ORG có `MST-01`; ứng viên MST-X cùng tên.

**Các bước.**

1. Gửi ứng viên tổ chức với `MST-X`.
2. Gửi ứng viên công dân với CCCD toàn số 0 trùng một bản ghi vàng.

**Kết quả mong đợi.** Bước 1 `method` không phải `DETERMINISTIC`; kết luận theo điểm xác suất. Bước 2 không `MATCH` xác định; gắn `IDENTIFIER_INVALID`.

**Hậu điều kiện.** Không liên kết sai.
:::

#### TC-06-043 · Cùng tên, ngày sinh khác CCCD không hợp nhất <!--k:det-conflict-->

::: dac-ta
**Mục đích.** Chứng minh quy tắc loại trừ chặn hợp nhất hai khóa xác định khác nhau, theo BR-06-006.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-020, 021 · BR-06-006 · ERR-06-029 · UI-06-05.

**Tiền điều kiện, dữ liệu.** CC-01 và CC-02 cùng tên, cùng ngày sinh (F-CIT).

**Các bước.**

1. Nạp ứng viên CC-02 khi bản ghi vàng CC-01 đã có.
2. Chạy lại `resolve` với tên, ngày sinh, kèm CC-02.

**Kết quả mong đợi.** Bước 1 tạo bản ghi vàng mới; mục hàng đợi `IDENTIFIER_CONFLICT` ưu tiên 90, SLA 1 ngày. Bước 2 `outcome = CONFLICT` hoặc `NO_MATCH` với CC-01, không bao giờ `MATCH`.

**Hậu điều kiện.** Hai bản ghi vàng riêng, một mục hàng đợi.
:::

#### TC-06-044 · Đối sánh xác suất: vùng MATCH và POSSIBLE_MATCH <!--k:prob-zones-->

::: dac-ta
**Mục đích.** Chứng minh ba vùng điểm theo ngưỡng 0,90 và 0,10, theo FR-06-021.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** FR-06-021 · BR-06-002 · API-06-071 · NFR-06-003.

**Tiền điều kiện, dữ liệu.** Bộ quy tắc v2 ACTIVE (`0,92`/`0,15`); 5 cặp có điểm 0,97; 0,93; 0,50; 0,16; 0,05.

**Các bước.**

1. Nạp 5 ứng viên, đọc `match_result`.

**Kết quả mong đợi.** Điểm 0,97 và 0,93 `MATCH` `PROBABILISTIC_ONLINE` tự gắn; 0,50 và 0,16 `POSSIBLE_MATCH` vào hàng đợi (không tự động); 0,05 `NO_MATCH` tạo bản ghi vàng mới. `match_result` lưu điểm từng thuộc tính và 5 ứng viên đầu.

**Hậu điều kiện.** 2 mục hàng đợi.
:::

#### TC-06-045 · Nhiều ứng viên cùng vượt ngưỡng <!--k:prob-multi-->

::: dac-ta
**Mục đích.** Chứng minh hai ứng viên điểm sát nhau thì không tự hợp nhất, theo FR-06-021.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-021 · BR-06-002 · API-06-071.

**Tiền điều kiện, dữ liệu.** Hai bản ghi vàng "Trần Văn Bảo" sinh 1985 điểm 0,93 và 0,92 với ứng viên mới.

**Các bước.**

1. Nạp ứng viên.

**Kết quả mong đợi.** `POSSIBLE_MATCH`, `QueueReason = MULTIPLE_CANDIDATES`, mục hàng đợi chứa cả hai.

**Hậu điều kiện.** Một mục.
:::

#### TC-06-046 · Ít thuộc tính dùng được <!--k:prob-minattr-->

::: dac-ta
**Mục đích.** Chứng minh ứng viên dưới `minAttributes` không tự hợp nhất, theo BR-06-015.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-021 · BR-06-015 · API-06-071.

**Tiền điều kiện, dữ liệu.** `minAttributes = 3`; ứng viên chỉ có họ tên và điện thoại.

**Các bước.**

1. Nạp ứng viên trùng họ tên với một bản ghi vàng.
2. Nạp ứng viên không giống khối nào.

**Kết quả mong đợi.** Bước 1 `POSSIBLE_MATCH` `INSUFFICIENT_ATTRIBUTES`. Bước 2 `NO_MATCH`.

**Hậu điều kiện.** Một mục.
:::

#### TC-06-047 · Ba nguồn chồng lấn cho một bản ghi vàng <!--k:golden-create-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 3 của FRS: một bản ghi vàng, ba liên kết, ngày sinh từ `QG-DANCU`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-034, 043 · BR-06-003, 009, 018 · EVT-06-01, 02.

**Tiền điều kiện, dữ liệu.** Bảng ưu tiên của prio-approve ACTIVE; CC-03 ở `QG-DANCU`, `HT-YTE`, `HT-GIAODUC` với ngày sinh khác nhau.

**Các bước.**

1. Nạp lần lượt `HT-GIAODUC`, `HT-YTE`, `QG-DANCU`.
2. `GET .../golden-records/{id}` và `/lineage`.

**Kết quả mong đợi.** Một `goldenId` UUID v7, `version` tăng theo từng thay đổi, ba xref `ACTIVE`, `dateOfBirth` lấy từ `QG-DANCU`, lineage ghi nguồn từng thuộc tính. EVT-06-01 một lần, EVT-06-02 hai lần, không chứa giá trị.

**Hậu điều kiện.** Bản ghi vàng Bình dùng ở các TS sau.
:::

#### TC-06-048 · Nguồn gửi lại y nguyên <!--k:golden-nochange-->

::: dac-ta
**Mục đích.** Chứng minh không đổi giá trị thì không tăng `version`, không phát sự kiện, theo FR-06-034.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-06-034 · EVT-06-02.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình version n.

**Các bước.**

1. Nguồn `HT-YTE` gửi `sourceVersion` mới, cùng giá trị.

**Kết quả mong đợi.** Xref cập nhật thời điểm, `version` giữ n, EVT: không, không dòng `golden_history` mới.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-049 · Không ghi được lịch sử thì hủy cập nhật <!--k:golden-history-fail-->

::: dac-ta
**Mục đích.** Chứng minh ảnh chụp ghi trong cùng giao dịch, ghi lỗi thì không đổi bản ghi vàng, theo BR-06-005.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-034 · BR-06-005 · ERR-06-111.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình; gây lỗi ghi `golden_history` bằng quyền thu hồi ở PostgreSQL (T95).

**Các bước.**

1. Nạp ứng viên đổi `phone`.
2. Khôi phục quyền, chờ thử lại.

**Kết quả mong đợi.** Bước 1 giao dịch hủy, bản ghi vàng nguyên vẹn, ứng viên giữ `NORMALIZED`, ERR-06-111 ở nhật ký xử lý, thử lại 3 lần giãn dần. Bước 2 cập nhật thành công, có đủ ảnh chụp.

**Hậu điều kiện.** Một ảnh chụp mới.
:::

#### TC-06-050 · Máy không ghi đè quyết định của người <!--k:negative-link-->

::: dac-ta
**Mục đích.** Chứng minh cặp có `negativeLink` không bị đề xuất hợp nhất lại, theo BR-06-023.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-021 · BR-06-023 · API-06-071.

**Tiền điều kiện, dữ liệu.** Cặp P-17 đã được DS2 quyết `NO_MATCH`.

**Các bước.**

1. Nạp ứng viên mới giống P-17 điểm 0,95.
2. Chạy job lô trên domain.

**Kết quả mong đợi.** Không `MATCH`, không mục hàng đợi mới cho cặp; ca lô bỏ qua cặp, đếm vào `skipped`.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-11 · Job đối sánh theo lô bằng Splink

**Mục tiêu.** Xác nhận job lô chạy đúng, chỉ đọc staging, dừng ở ngưỡng an toàn, thất bại không đổi bản ghi vàng ngoài các cặp đã áp.

**Phủ.** FR-06-022, 056; UC-06-11; API-06-041…044; UI-06-12; BR-06-022, 023; ERR-06-025, 101…105; EVT-06-09.

#### TC-06-051 · Job FULL_INITIAL trên 20.000 CITIZEN <!--k:batch-run-->

::: dac-ta
**Mục đích.** Chứng minh vòng đời job, staging chỉ có HMAC và dọn sau job, theo FR-06-022.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB, API.

**Truy vết.** FR-06-022 · API-06-042, 043 · EVT-06-09 · BR-06-016 · PERM-06-operate.

**Tiền điều kiện, dữ liệu.** T90 nạp 20.000 ứng viên F-CIT mở rộng, bộ quy tắc v2 ACTIVE; TO.

**Các bước.**

1. `POST /domains/CITIZEN/match-jobs` `BatchScope = FULL_INITIAL`.
2. Theo dõi `GET /match-jobs/{id}` tới kết thúc.
3. Quét `ph06_mdm.stg_match_{jobId}` khi `RUNNING`, rồi sau job.

**Kết quả mong đợi.** Trạng thái đi qua `QUEUED`, `PREPARING`, `RUNNING`, `APPLYING`, `SUCCEEDED`; `counts` đủ `input`, `pairs`, `match`, `possible`, `applied`, `skipped`. Staging chỉ chứa thuộc tính `matchable` đã chuẩn hóa, định danh dạng HMAC, không có CCCD rõ; sau job bảng staging bị xóa. Mỗi hợp nhất mang `batchOperationId`, `method = PROBABILISTIC_BATCH`. EVT-06-09 một bản tin. KT: có (job-start).

**Hậu điều kiện.** Bản ghi vàng đã gom; dùng ở ca batch-partial.
:::

#### TC-06-052 · Chạy thử không áp; job trùng bị chặn <!--k:batch-dryrun-dup-->

::: dac-ta
**Mục đích.** Chứng minh `dryRun` dừng sau chấm điểm và không cho hai job cùng loại, theo FR-06-022.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-022 · API-06-042 · ERR-06-025.

**Tiền điều kiện, dữ liệu.** T90 như batch-run.

**Các bước.**

1. Tạo job `dryRun = true`; đếm bản ghi vàng trước, sau.
2. Tạo job thật rồi tạo tiếp một job nữa khi job đầu `RUNNING`.

**Kết quả mong đợi.** Bước 1 báo cáo cặp theo vùng, mẫu 100 cặp, số bản ghi vàng không đổi. Bước 2 job thứ hai `409` ERR-06-025.

**Thông báo hiển thị.** ERR-06-025 "Domain {mã} đang có job đối sánh {jobId} chạy."

**Hậu điều kiện.** Một job đang chạy.
:::

#### TC-06-053 · Vượt ngưỡng an toàn 5 % chờ xác nhận <!--k:batch-safety-->

::: dac-ta
**Mục đích.** Chứng minh job có số cặp `MATCH` > 5 % số bản ghi vào dừng ở `AWAITING_CONFIRMATION`, theo BR-06-022.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-06-022 · BR-06-022 · API-06-044 · ERR-06-105 · PERM-06-approve.

**Tiền điều kiện, dữ liệu.** Tập T99 dựng 30 % bản ghi trùng chủ ý; `06.batch.safety-ratio = 0,05`.

**Các bước.**

1. Chạy job, chờ trạng thái.
2. DA1 `:confirm` một job; với job khác DA1 từ chối.

**Kết quả mong đợi.** Bước 1 `AWAITING_CONFIRMATION`, ERR-06-105 ở UI-06-12, không bản ghi vàng nào đổi. Bước 2 xác nhận thì `APPLYING` → `SUCCEEDED`; từ chối thì `CANCELLED`, không đổi (ĐN-UC-04).

**Hậu điều kiện.** Hai job ở trạng thái cuối.
:::

#### TC-06-054 · Job lỗi đọc staging, quá giờ, hết bộ nhớ <!--k:batch-fail-->

::: dac-ta
**Mục đích.** Chứng minh job thất bại không đổi bản ghi vàng nào, theo FR-06-022.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** JOB, Chaos.

**Truy vết.** FR-06-022 · ERR-06-101, 102, 103 · BR-06-023.

**Tiền điều kiện, dữ liệu.** T95; chặn quyền đọc staging; đặt thời gian tối đa 1 phút; giới hạn bộ nhớ Job 256 MB.

**Các bước.**

1. Chạy job với từng sự cố.
2. Đối chiếu bảng `golden_record`, `golden_history`.

**Kết quả mong đợi.** Ba job `FAILED` lần lượt ERR-06-101, 102, 103 (kèm gợi ý chuyển Spark); `golden_record` và `golden_history` không đổi; vận hành thấy câu "Job {id} lỗi khi đọc dữ liệu … Không bản ghi vàng nào bị đổi.".

**Hậu điều kiện.** Staging đã dọn.
:::

#### TC-06-055 · Bỏ qua cặp đã đổi sau khi xuất và cặp có quyết định thủ công <!--k:batch-skip-->

::: dac-ta
**Mục đích.** Chứng minh job không ghi đè quyết định của người và dữ liệu đổi giữa chừng, theo BR-06-023.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-06-022 · BR-06-023 · ERR-06-104.

**Tiền điều kiện, dữ liệu.** Cặp P-17 `negativeLink`; cặp P-18 liên kết do người xác nhận; cặp P-19 đổi bản ghi sau khi xuất staging.

**Các bước.**

1. Chạy job, trong lúc `RUNNING` sửa P-19.

**Kết quả mong đợi.** P-17 không đề xuất lại; P-18 không bị tự tách; P-19 bị bỏ qua ERR-06-104; `skipped = 3`.

**Hậu điều kiện.** Ba cặp không đổi.
:::

#### TC-06-056 · Job thất bại giữa chừng chỉ để lại cặp đã áp <!--k:batch-partial-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 9: không đổi bản ghi vàng ngoài các cặp đã áp có `batchOperationId`.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-06-022 · BR-06-005, 023 · ERR-06-103.

**Tiền điều kiện, dữ liệu.** T95; job `APPLYING` 5.000 cặp.

**Các bước.**

1. Xóa pod Job khi đã áp khoảng 2.000 cặp.
2. So `golden_record` trước, sau theo `batchOperationId`.

**Kết quả mong đợi.** Job `PARTIALLY_SUCCEEDED` hoặc `FAILED`; mọi bản ghi vàng đổi đều có `batchOperationId` và ảnh chụp; không bản ghi nào đổi nửa chừng; chạy lại job không áp trùng cặp.

**Hậu điều kiện.** Có thể `:rerun`.
:::

### TS-06-12 · Hàng đợi người quản lý dữ liệu

**Mục tiêu.** Xác nhận tạo mục không trùng, tính ưu tiên đúng, nhận việc không xung đột, SLA và cảnh báo quá tải.

**Phủ.** FR-06-027, 028, 032; UC-06-12; API-06-045, 047, 050; UI-06-04, 01; BR-06-002, 015, 019; ERR-06-027, 028; EVT-06-08.

#### TC-06-057 · Tạo mục hàng đợi, ưu tiên và SLA <!--k:q-create-->

::: dac-ta
**Mục đích.** Chứng minh công thức ưu tiên 0…100, hạn SLA và không tạo trùng cặp, theo FR-06-027.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-06-027 · BR-06-002, 019 · EVT-06-08 · API-06-045.

**Tiền điều kiện, dữ liệu.** Bảy lý do `QueueReason`; mặc định `06.queue.sla-days = 7`.

**Các bước.**

1. Tạo mục cho từng `QueueReason`.
2. Tạo mục lần hai cho cùng một cặp, đổi thứ tự hai bản ghi.

**Kết quả mong đợi.** Điểm cơ sở `IDENTIFIER_CONFLICT` 90, `CRITICAL_CONFLICT` 70, `MULTIPLE_CANDIDATES` 50, `POSSIBLE_MATCH` 40, `INSUFFICIENT_ATTRIBUTES` 30, `ORPHANED` 20, cộng tối đa 10 + 10 theo số liên kết và độ gần ngưỡng, trần 100. SLA 7 ngày, riêng `IDENTIFIER_CONFLICT` 1 ngày. Cặp trùng chỉ cập nhật điểm, không mục mới. Mỗi mục mới một EVT-06-08.

**Hậu điều kiện.** Bảy mục `OPEN`.
:::

#### TC-06-058 · Liệt kê, nhận việc, phân công, nhả <!--k:q-claim-->

::: dac-ta
**Mục đích.** Chứng minh lọc, sắp theo ưu tiên, nhận việc, giữ 30 phút, phân công bởi DA, theo FR-06-028.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-028 · API-06-045, 047 · UI-06-04 · PERM-06-steward.

**Tiền điều kiện, dữ liệu.** Bảy mục của q-create; DS1, DS2, DA1.

**Các bước.**

1. DS1 `GET /stewardship/items?status=OPEN&sort=priority,desc`.
2. DS1 `:claim` mục đầu; đợi quá `06.queue.hold-minutes`.
3. DA1 `:assign` mục khác cho DS2; DS2 `:release`.

**Kết quả mong đợi.** Bước 1 xếp ưu tiên giảm dần. Bước 2 mục `ASSIGNED` cho DS1, hết 30 phút tự nhả về `OPEN`. Bước 3 `ASSIGNED` rồi `OPEN`. Mỗi chuyển có KT.

**Hậu điều kiện.** Mục trả về OPEN.
:::

#### TC-06-059 · Hai người cùng nhận, mục ngoài tổ chức <!--k:q-claim-neg-->

::: dac-ta
**Mục đích.** Chứng minh khóa nhận việc và phạm vi tổ chức của DS (`○`), theo FR-06-028.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-028 · API-06-047 · ERR-06-027, 028 · UI-06-05.

**Tiền điều kiện, dữ liệu.** Mục M1 của nguồn Sở Y tế; DS1 (Y tế), DS2 (Giáo dục).

**Các bước.**

1. DS1 và DS2 cùng gọi `:claim` M1 trong 100 ms.
2. DS2 `:claim` mục chỉ gồm dữ liệu nguồn Sở Y tế.

**Kết quả mong đợi.** Bước 1 một `200`, một `409` ERR-06-027, UI chuyển sang mục kế tiếp. Bước 2 `403` ERR-06-028.

**Thông báo hiển thị.** ERR-06-027 "Mục này vừa được {người} nhận. Hệ thống chuyển anh/chị sang mục kế tiếp."

**Hậu điều kiện.** M1 của DS1.
:::

#### TC-06-060 · Quá hạn SLA, nâng ưu tiên, quá tải <!--k:q-sla-->

::: dac-ta
**Mục đích.** Chứng minh quá hạn +20 điểm, giao lại sau 14 ngày, cảnh báo quá tải mà không tự quyết cặp, theo FR-06-032.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-032 · BR-06-002 · NFR-06-019 · UI-06-04, 01 · API-06-050.

**Tiền điều kiện, dữ liệu.** T92 (`06.queue.max-open = 100`); đồng hồ giả lập.

**Các bước.**

1. Tiến thời gian 8 ngày; đọc `GET /stewardship/stats`.
2. Tiến tới 15 ngày.
3. Tạo 101 mục mở.

**Kết quả mong đợi.** Bước 1 mục `overdue`, điểm +20 (trần 100), thông báo người nhận và DA. Bước 2 giao DA phân công lại. Bước 3 cảnh báo quá tải tới PH-13 có phân tích theo nguồn và lý do; mọi cặp vẫn `OPEN`, không cặp nào tự động hợp nhất (BR-06-002). `mdm_queue_open`, `overdue`, `age_seconds` đúng.

**Hậu điều kiện.** 101 mục mở.
:::

### TS-06-13 · So sánh cạnh nhau và quyết định

**Mục tiêu.** Xác nhận so sánh đúng, quyết định có lý do, cấm hợp nhất khác định danh, mục lỗi thời.

**Phủ.** FR-06-029, 030; UC-06-13; API-06-046, 048; UI-06-05; BR-06-006, 008, 010, 023; ERR-06-007, 029, 030.

#### TC-06-061 · So sánh cạnh nhau hai bản ghi <!--k:cmp-view-->

::: dac-ta
**Mục đích.** Chứng minh bảng so sánh có `ComparisonLevel` từng thuộc tính, che DLCN và ghi nhật ký truy cập, theo FR-06-029.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-06-029 · API-06-046 · UI-06-05 · BR-06-010 · BR-06-026.

**Tiền điều kiện, dữ liệu.** Mục POSSIBLE_MATCH điểm 0,62; DS1.

**Các bước.**

1. DS1 mở mục.
2. Bấm "Hiện giá trị" thuộc tính `SENSITIVE` khi không có `PERM-09-unmask`.

**Kết quả mong đợi.** Bước 1 năm mức `EXACT`, `FUZZY_HIGH`, `FUZZY_LOW`, `DIFFERENT`, `MISSING` đúng từng thuộc tính, màu kèm nhãn chữ; NK: có. Bước 2 giá trị vẫn che.

**Hậu điều kiện.** Một dòng `access_log`.
:::

#### TC-06-062 · Quyết định khớp hợp nhất ngay mức rủi ro thấp <!--k:decide-match-->

::: dac-ta
**Mục đích.** Chứng minh quyết định `MATCH` có lý do ≥ 20 ký tự hợp nhất và phát sự kiện, theo FR-06-030.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-030 · BR-06-008, 019 · API-06-048 · EVT-06-03 · PERM-06-steward.

**Tiền điều kiện, dữ liệu.** Mục hai bản ghi vàng 1 liên kết mỗi bên, điểm 0,96; DS1 đã nhận.

**Các bước.**

1. `POST /stewardship/items/{id}:decide` `MATCH`, `survivorId`, lý do 40 ký tự.

**Kết quả mong đợi.** `200`, `riskLevel = LOW`, mục `RESOLVED`, bản ghi vàng còn lại `MERGED`, xref chuyển sang bản sống sót, EVT-06-03. KT: có (steward-decide).

**Hậu điều kiện.** Một bản ghi vàng `MERGED`.
:::

#### TC-06-063 · Quyết định không khớp và hoãn <!--k:decide-nomatch-->

::: dac-ta
**Mục đích.** Chứng minh `NO_MATCH` ghi `negativeLink` và `DEFER` giữ mục, theo FR-06-030.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-030 · BR-06-023 · API-06-048.

**Tiền điều kiện, dữ liệu.** Hai mục POSSIBLE_MATCH; DS1.

**Các bước.**

1. `decide` `NO_MATCH` mục 1 kèm lý do.
2. `decide` `DEFER` mục 2.

**Kết quả mong đợi.** Mục 1 `RESOLVED`, có `negativeLink`, cặp không đề xuất lại. Mục 2 `DEFERRED`, có hạn nhắc.

**Hậu điều kiện.** Một negativeLink.
:::

#### TC-06-064 · Lý do ngắn, mục lỗi thời, khác số định danh <!--k:decide-neg-->

::: dac-ta
**Mục đích.** Chứng minh ba nhánh chặn quyết định, theo FR-06-030.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-029, 030 · BR-06-006, 008 · API-06-048 · ERR-06-007, 029, 030.

**Tiền điều kiện, dữ liệu.** Mục cặp CC-01/CC-02; mục M5 có bản ghi vừa đổi.

**Các bước.**

1. `decide` `MATCH` với lý do 10 ký tự.
2. `decide` `MATCH` cặp CC-01/CC-02 kèm lý do đủ dài.
3. Sửa bản ghi của M5 rồi `decide` M5.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-007. Bước 2 `422` ERR-06-029, nút "Khớp" ở UI bị vô hiệu kèm chú thích. Bước 3 `409` ERR-06-030, mục xem xét lại.

**Thông báo hiển thị.** ERR-06-029 "Hai bản ghi có số định danh khác nhau nên không được hợp nhất. Kiểm tra lại dữ liệu nguồn."

**Hậu điều kiện.** Không hợp nhất.
:::

### TS-06-14 · Duyệt bốn mắt hợp nhất rủi ro cao

**Mục tiêu.** Xác nhận phân loại rủi ro cao theo BR-06-019 và quy trình duyệt, từ chối, nhắc.

**Phủ.** FR-06-031; UC-06-14; API-06-049, 061; UI-06-05; BR-06-019; ERR-06-005, 031.

#### TC-06-065 · Năm điều kiện rủi ro cao <!--k:risk-classify-->

::: dac-ta
**Mục đích.** Chứng minh `RiskLevel` theo từng điều kiện của BR-06-019.

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-06-031, 027 · BR-06-019.

**Tiền điều kiện, dữ liệu.** Năm cặp: (a) hai bản ghi vàng cùng 3 liên kết; (b) thuộc tính quan trọng khác nhau; (c) vàng-vàng điểm 0,94; (d) hợp nhất thủ công 3 bản ghi; (e) tách bản ghi có 3 liên kết; cặp đối chứng 2 liên kết điểm 0,96.

**Các bước.**

1. Tạo thao tác cho từng cặp, đọc `riskLevel`.

**Kết quả mong đợi.** Năm cặp `HIGH` (chờ duyệt, bản ghi vàng `LOCKED`); cặp đối chứng `LOW`; biên 0,95 vàng-vàng là `LOW`, 0,949 là `HIGH`.

**Hậu điều kiện.** Năm thao tác PENDING_APPROVAL.
:::

#### TC-06-066 · DA khác duyệt và từ chối <!--k:approve-pos-->

::: dac-ta
**Mục đích.** Chứng minh duyệt thực hiện thao tác trong một giao dịch và từ chối trả về người đề nghị, theo FR-06-031.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-031 · API-06-049, 061 · BR-06-019 · EVT-06-03 · PERM-06-approve.

**Tiền điều kiện, dữ liệu.** Thao tác (a), (b) của risk-classify; DS1 đề nghị, DA1.

**Các bước.**

1. DA1 `:approve` (a).
2. DA1 `:reject` (b) kèm ý kiến.
3. DA1 đổi `survivorId` rồi duyệt một thao tác (c).

**Kết quả mong đợi.** Bước 1 hợp nhất áp, mở khóa, mục `RESOLVED`, EVT-06-03. Bước 2 mục về `ASSIGNED` cho DS1 kèm ý kiến, bản ghi vàng mở khóa. Bước 3 coi như từ chối kèm đề nghị. KT: có (steward-approve, reject).

**Hậu điều kiện.** (a) đã áp; (b), (c) về DS1.
:::

#### TC-06-067 · Tự duyệt, DA duy nhất, nhắc và giao lại <!--k:approve-neg-->

::: dac-ta
**Mục đích.** Chứng minh người đề nghị không tự duyệt, bản ghi vàng `LOCKED` chặn thao tác khác và việc nhắc, giao lại, theo FR-06-031.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-06-031 · API-06-049 · ERR-06-005, 031 · UI-06-05.

**Tiền điều kiện, dữ liệu.** Thao tác (d); TA vừa đề nghị vừa có `approve` (cấu hình sai chủ ý, SIT); đồng hồ giả lập.

**Các bước.**

1. TA `:approve` thao tác do TA đề nghị.
2. DS2 sửa tay bản ghi vàng đang `LOCKED`.
3. Tiến 3 ngày làm việc, rồi 6 ngày.

**Kết quả mong đợi.** Bước 1 `403` ERR-06-005 dù có quyền. Bước 2 `409` ERR-06-031. Bước 3 nhắc DA sau 2 ngày làm việc; quá 5 ngày giao DA khác của tenant (Q06-45 nếu chỉ có một DA).

**Thông báo hiển thị.** ERR-06-031 "Bản ghi vàng {id} đang có thao tác chờ duyệt."

**Hậu điều kiện.** (d) vẫn PENDING_APPROVAL.
:::

### TS-06-15 · Quy tắc sống sót, xem trước tác động và áp lại

**Mục tiêu.** Xác nhận bảy chiến lược sống sót chọn đúng giá trị, nguồn quốc gia thắng thuộc tính thẩm quyền, áp lại hàng loạt có bốn mắt.

**Phủ.** FR-06-033, 042; UC-06-15; API-06-051…055; UI-06-10; BR-06-003, 004, 005; ERR-06-005, 013, 022, 025.

#### TC-06-068 · Cấu hình, duyệt quy tắc sống sót và chặn sai <!--k:surv-config-->

::: dac-ta
**Mục đích.** Chứng minh cấu hình `SurvivorshipStrategy` theo thuộc tính, có căn cứ, bốn mắt, theo FR-06-033.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-033 · BR-06-003, 004 · API-06-051, 052, 053 · ERR-06-005, 013, 022 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** CITIZEN ACTIVE; DS1, DA1.

**Các bước.**

1. `PUT .../survivorship-rules` đặt `dateOfBirth` `NATIONAL_AUTHORITY`, `phone` `MOST_RECENT`, `address` `SOURCE_PRIORITY`.
2. `submit`, DS1 tự `approve`, rồi DA1 `approve`.
3. `PUT` đặt `dateOfBirth` `MOST_FREQUENT`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 DS1 `403` ERR-06-005; DA1 `200` ACTIVE. Bước 3 `422` ERR-06-022 (thuộc tính thẩm quyền quốc gia chỉ `NATIONAL_AUTHORITY`). Thiếu căn cứ `422` ERR-06-013. KT: có.

**Hậu điều kiện.** Quy tắc sống sót ACTIVE.
:::

#### TC-06-069 · Kết quả của từng chiến lược sống sót <!--k:surv-strategies-->

::: dac-ta
**Mục đích.** Chứng minh mỗi chiến lược chọn đúng giá trị và đúng nguồn ở cấp thuộc tính.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT.

**Truy vết.** FR-06-034, 033 · BR-06-003, 009, 029.

**Tiền điều kiện, dữ liệu.** Ba nguồn gửi `phone` khác nhau tại các thời điểm, độ đầy đủ khác nhau; bảng ưu tiên prio-approve.

**Các bước.**

1. Chạy bảng tham số: `NATIONAL_AUTHORITY`, `MANUAL_OVERRIDE`, `SOURCE_PRIORITY`, `MOST_RECENT`, `MOST_COMPLETE`, `MOST_FREQUENT`, `FIRST_VALUE` trên cùng bộ ba giá trị.

**Kết quả mong đợi.** Mỗi chiến lược trả đúng giá trị kỳ vọng ghi trong bảng ca; `QG-DANCU` thắng mọi `NATIONAL_AUTHORITY`; hòa thì theo `SOURCE_PRIORITY` rồi `MOST_RECENT`; lineage ghi chiến lược đã dùng.

**Hậu điều kiện.** Không dữ liệu.
:::

#### TC-06-070 · Xem trước tác động và áp lại hàng loạt <!--k:reapply-->

::: dac-ta
**Mục đích.** Chứng minh áp lại tính trước số bản ghi đổi và có bốn mắt, theo FR-06-042.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, JOB.

**Truy vết.** FR-06-042 · BR-06-004, 005 · API-06-054, 055 · PERM-06-approve.

**Tiền điều kiện, dữ liệu.** T90 có 5.000 bản ghi vàng; đổi `phone` sang `MOST_FREQUENT` (đã duyệt).

**Các bước.**

1. `POST .../survivorship-rules:impact`.
2. DS1 `:reapply`; DA1 duyệt; chờ job.

**Kết quả mong đợi.** Bước 1 báo số bản ghi, thuộc tính sẽ đổi, mẫu trước-sau, chưa đổi dữ liệu. Bước 2 job `SURVIVORSHIP_REAPPLY` `SUCCEEDED`, số bản ghi đổi bằng ước tính, mỗi bản ghi có ảnh chụp, EVT-06-02 mỗi bản ghi đổi.

**Hậu điều kiện.** Bản ghi vàng theo quy tắc mới.
:::

#### TC-06-071 · Áp lại tự duyệt và job trùng <!--k:reapply-neg-->

::: dac-ta
**Mục đích.** Chứng minh áp lại chặn tự duyệt và hai lượt đồng thời, theo FR-06-042.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-042 · API-06-055 · ERR-06-005, 025.

**Tiền điều kiện, dữ liệu.** Như reapply.

**Các bước.**

1. DS1 tự duyệt `:reapply`.
2. Gọi `:reapply` khi một job `SURVIVORSHIP_REAPPLY` đang chạy.

**Kết quả mong đợi.** Bước 1 `403` ERR-06-005. Bước 2 `409` ERR-06-025.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-16 · Chi tiết bản ghi vàng, lịch sử và nguồn gốc

**Mục tiêu.** Xác nhận xem bản ghi vàng có che, lịch sử đủ, so sánh hai phiên bản, nguồn gốc từng thuộc tính.

**Phủ.** FR-06-035, 041, 043; UC-06-16; API-06-056, 063, 064, 065; UI-06-03; BR-06-005, 009, 010, 026; ERR-06-001, 039.

#### TC-06-072 · Xem chi tiết bản ghi vàng đã che <!--k:gold-view-->

::: dac-ta
**Mục đích.** Chứng minh chi tiết có thuộc tính, xref, nguồn từng thuộc tính, che theo phân loại, theo FR-06-035.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-035 · API-06-056 · UI-06-03 · BR-06-009, 010, 026 · PERM-06-read.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình; DS1, VW.

**Các bước.**

1. DS1 `GET .../golden-records/{id}` với `X-Purpose`.
2. VW `GET` cùng bản ghi.

**Kết quả mong đợi.** Bước 1 `200`, mỗi thuộc tính có `source`, `confidence`; `idNumber` hiển thị `*********303`. Bước 2 cùng che, không có giá trị rõ. NK: có hai dòng.

**Hậu điều kiện.** Hai dòng access_log.
:::

#### TC-06-073 · Bản ghi đã ngừng, không tồn tại, mất nhật ký truy cập <!--k:gold-view-neg-->

::: dac-ta
**Mục đích.** Chứng minh `410`, `404` và không trả dữ liệu khi không ghi được nhật ký, theo BR-06-010.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-035 · BR-06-010 · ERR-06-001, 039.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng `RETIRED` G-R; T95.

**Các bước.**

1. `GET` G-R.
2. `GET` một `goldenId` không có.
3. Dừng dịch vụ ghi `access_log`, `GET` bản ghi `ACTIVE`.

**Kết quả mong đợi.** Bước 1 `410` ERR-06-001. Bước 2 `404` ERR-06-001. Bước 3 `503` ERR-06-039, thân không chứa giá trị thuộc tính.

**Thông báo hiển thị.** ERR-06-039 "Chưa ghi được nhật ký truy cập nên không hiển thị dữ liệu. Thử lại sau ít phút."

**Hậu điều kiện.** Không có dòng access_log mới ở bước 3.
:::

#### TC-06-074 · Lịch sử phiên bản và so sánh hai phiên bản <!--k:hist-diff-->

::: dac-ta
**Mục đích.** Chứng minh mỗi thay đổi có ảnh chụp và so sánh hai phiên bản đúng, theo FR-06-041.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-041 · BR-06-005 · API-06-063, 064 · ERR-06-001.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng đã qua 5 thay đổi: `CREATE`, `UPDATE`, `MANUAL_EDIT`, `MERGE`, `UNDO`.

**Các bước.**

1. `GET .../history`.
2. `GET .../history/3` và so với 5.
3. `GET .../history/99`.

**Kết quả mong đợi.** Bước 1 5 dòng `GoldenChangeType` đúng thứ tự, người, thời điểm. Bước 2 diff chỉ ra thuộc tính đổi. Bước 3 `404` ERR-06-001.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-075 · Truy xuất nguồn gốc từng thuộc tính <!--k:lineage-->

::: dac-ta
**Mục đích.** Chứng minh lineage nêu nguồn, khóa nguồn, chiến lược và sửa tay, theo FR-06-043.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-043 · BR-06-009, 014 · API-06-065 · ERR-06-001 · UI-06-03.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình có thuộc tính do `QG-DANCU`, `HT-YTE` và một giá trị `MANUAL`.

**Các bước.**

1. `GET .../lineage`.
2. `GET .../lineage?attribute=khongco`.

**Kết quả mong đợi.** Bước 1 mỗi thuộc tính `sourceCode`, `sourceKey`, `strategy`, thời điểm; thuộc tính sửa tay nguồn `MANUAL` kèm hạn và yêu cầu sửa tại nguồn. Bước 2 `400` ERR-06-003.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-17 · Sửa tay, ngừng và khôi phục bản ghi vàng

**Mục tiêu.** Xác nhận sửa tay có lý do và hạn, thuộc tính thẩm quyền quốc gia không sửa tay, ngừng và khôi phục không xóa dữ liệu.

**Phủ.** FR-06-036, 040; UC-06-17; API-06-057, 062; UI-06-03; BR-06-007, 008, 014, 025; ERR-06-004, 007, 031, 035, 036; EVT-06-05, 06, 15.

#### TC-06-076 · Sửa tay thuộc tính có hạn và yêu cầu sửa tại nguồn <!--k:manual-edit-->

::: dac-ta
**Mục đích.** Chứng minh sửa tay là tạm thời, có `validUntil` và sinh yêu cầu sửa tại nguồn, theo BR-06-014.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-036 · BR-06-014 · API-06-057 · EVT-06-02, 15 · PERM-06-update.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình thuộc tính `phone` do `HT-YTE`; DS1, DO1.

**Các bước.**

1. `PATCH .../attributes` đặt `phone`, lý do 30 ký tự, `validUntil` +30 ngày, `If-Match`.
2. Tiến quá hạn; đọc `phone`.

**Kết quả mong đợi.** Bước 1 `200`, chiến lược `MANUAL_OVERRIDE`, lineage nguồn `MANUAL`, `GoldenChangeType = MANUAL_EDIT`, ảnh chụp; EVT-06-15 gửi DO1, EVT-06-02. Bước 2 override bỏ, giá trị `HT-YTE` quay lại, DS1 nhận thông báo. Nếu nguồn đã gửi giá trị khớp trước hạn, override tự bỏ. KT: có (manual-edit).

**Hậu điều kiện.** Một yêu cầu sửa tại nguồn.
:::

#### TC-06-077 · Sửa tay trái thẩm quyền, thiếu lý do, ETag cũ, đang khóa <!--k:manual-neg-->

::: dac-ta
**Mục đích.** Chứng minh bốn nhánh chặn sửa tay, theo FR-06-036.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-036 · BR-06-008, 025 · API-06-057 · ERR-06-004, 007, 031, 035.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình; bản ghi vàng LOCKED G-L.

**Các bước.**

1. `PATCH` `dateOfBirth` (thẩm quyền quốc gia).
2. `PATCH` `phone` lý do 10 ký tự.
3. `PATCH` với `ETag` cũ.
4. `PATCH` G-L.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-035. Bước 2 `422` ERR-06-007. Bước 3 `409` ERR-06-004. Bước 4 `409` ERR-06-031.

**Thông báo hiển thị.** ERR-06-035 "Thuộc tính {tên} chỉ được sửa tại CSDL quốc gia. Hướng dẫn công dân liên hệ cơ quan đăng ký."

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-078 · Ngừng và khôi phục bản ghi vàng <!--k:retire-restore-->

::: dac-ta
**Mục đích.** Chứng minh ngừng chỉ chuyển `RETIRED`, không xóa, và khôi phục được, theo BR-06-007.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-040 · BR-06-007 · API-06-062 · EVT-06-05, 06 · PERM-06-merge.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng TEST_DATA không còn liên kết hiệu lực; DS1.

**Các bước.**

1. `POST .../{id}:retire` `RetireReason = TEST_DATA`, lý do 25 ký tự.
2. `GET` bản ghi, rồi `GET .../history`.
3. `:restore`.

**Kết quả mong đợi.** Bước 1 `RETIRED`, EVT-06-05. Bước 2 `410` ở tra cứu thường; lịch sử còn nguyên. Bước 3 `ACTIVE`, EVT-06-06. Không có đường `DELETE` (`405`). KT: có (retire, restore).

**Hậu điều kiện.** Bản ghi ACTIVE.
:::

#### TC-06-079 · Ngừng khi còn liên kết hiệu lực, trạng thái sai <!--k:retire-neg-->

::: dac-ta
**Mục đích.** Chứng minh chỉ ngừng bản ghi hết liên kết và hợp lệ về trạng thái, theo FR-06-040.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-040 · API-06-062 · ERR-06-006, 007, 036.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình (3 liên kết); bản ghi `MERGED`.

**Các bước.**

1. `:retire` Bình.
2. `:retire` bản ghi `MERGED`.
3. `:restore` bản ghi `ACTIVE`.
4. `:retire` thiếu lý do.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-036. Bước 2, 3 `409` ERR-06-006. Bước 4 `422` ERR-06-007.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-18 · Hợp nhất bản ghi vàng thủ công

**Mục tiêu.** Xác nhận hợp nhất thủ công đúng, không hợp nhất khác số định danh qua bất kỳ đường nào, rủi ro cao chờ duyệt.

**Phủ.** FR-06-037; UC-06-18; API-06-058, 061; UI-06-06, 02; BR-06-006, 008, 019; ERR-06-007, 029, 031.

#### TC-06-080 · Hợp nhất hai bản ghi vàng <!--k:merge-manual-->

::: dac-ta
**Mục đích.** Chứng minh hợp nhất chuyển xref, tính lại sống sót, ghi ảnh chụp, theo FR-06-037.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-037 · API-06-058 · UI-06-06 · EVT-06-03 · BR-06-005 · PERM-06-merge.

**Tiền điều kiện, dữ liệu.** Hai bản ghi vàng cùng người, một liên kết mỗi bên, không CCCD mâu thuẫn; DS1.

**Các bước.**

1. `POST .../golden-records:merge` `survivorId`, `mergedIds`, lý do 40 ký tự.
2. `GET` hai bản ghi và `history`.

**Kết quả mong đợi.** `200` mức `LOW`; bản ghi bị gộp `MERGED` `mergedInto`, xref của nó sang survivor; `version` tăng; ảnh chụp cả hai; EVT-06-03 có `mergedGoldenIds`. KT: có (merge).

**Hậu điều kiện.** Dùng ở undo-merge.
:::

#### TC-06-081 · Hợp nhất khác số định danh qua mọi đường <!--k:merge-neg-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 4: hai bản ghi có CCCD khác nhau không hợp nhất được bằng bất kỳ đường nào.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-06-037, 030, 022, 021 · BR-06-006 · ERR-06-007, 029 · API-06-058.

**Tiền điều kiện, dữ liệu.** Hai bản ghi vàng CC-01 và CC-02 (cùng tên, ngày sinh); DA1.

**Các bước.**

1. `merge` thủ công kèm lý do đủ dài.
2. `decide` `MATCH` ở hàng đợi.
3. Ép job lô và resolve trực tuyến cho cặp này.
4. DA1 duyệt một đề nghị hợp nhất cặp này (tạo bằng cách sửa dữ liệu trực tiếp trong CSDL kiểm thử).

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-06-029. Bước 3 không `MATCH`. Bước 4 `422` ERR-06-029 ngay khi duyệt (kiểm phía máy chủ). Hai bản ghi vẫn `ACTIVE`; cũng chặn khi thiếu lý do `422` ERR-06-007.

**Thông báo hiển thị.** ERR-06-029 "Hai bản ghi có số định danh khác nhau nên không được hợp nhất. Kiểm tra lại dữ liệu nguồn."

**Hậu điều kiện.** Hai bản ghi riêng.
:::

#### TC-06-082 · Hợp nhất từ ba bản ghi chờ duyệt <!--k:merge-highrisk-->

::: dac-ta
**Mục đích.** Chứng minh hợp nhất ≥ 3 bản ghi là rủi ro cao, khóa bản ghi và chờ DA, theo BR-06-019.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-037, 031 · BR-06-019 · API-06-058, 061 · ERR-06-031.

**Tiền điều kiện, dữ liệu.** Ba bản ghi vàng cùng người; DS1, DA1.

**Các bước.**

1. DS1 `merge` ba bản ghi.
2. DS2 `merge` một trong ba.
3. DA1 `:approve`.

**Kết quả mong đợi.** Bước 1 `202` `PENDING_APPROVAL`, ba bản ghi `LOCKED`. Bước 2 `409` ERR-06-031. Bước 3 áp, EVT-06-03, mở khóa.

**Hậu điều kiện.** Ba bản ghi thành một.
:::

### TS-06-19 · Tách bản ghi vàng và gỡ liên kết chéo nguồn

**Mục tiêu.** Xác nhận tách khôi phục đúng bản ghi cũ, ghi liên kết âm, gỡ liên kết có hậu quả đúng.

**Phủ.** FR-06-038, 044; UC-06-19; API-06-059, 061, 066, 067; UI-06-06, 03; BR-06-008, 018, 019, 023; ERR-06-006, 031, 032; EVT-06-04, 14.

#### TC-06-083 · Tách một bản ghi vàng thành hai <!--k:split-pos-->

::: dac-ta
**Mục đích.** Chứng minh tách phân bổ liên kết, tính lại sống sót, ghi `negativeLink`, theo FR-06-038.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-038 · BR-06-023 · API-06-059 · UI-06-06 · EVT-06-04 · PERM-06-merge.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng X gom nhầm hai người, hai liên kết mỗi người (rủi ro cao, DA1 duyệt).

**Các bước.**

1. `POST .../{id}:split` phân bổ hai nhóm, lý do 40 ký tự.
2. DA1 duyệt.
3. `GET` hai bản ghi, `xrefs`.

**Kết quả mong đợi.** Bản ghi mới (hoặc `goldenId` cũ `MERGED` được khôi phục) cho nhóm sau; xref chuyển đúng; sống sót tính lại cho cả hai; `negativeLink` giữa hai bên; EVT-06-04 có `fromGoldenId`, `toGoldenIds[]`. KT: có (split).

**Hậu điều kiện.** Hai bản ghi vàng.
:::

#### TC-06-084 · Phân bổ tách không hợp lệ <!--k:split-neg-->

::: dac-ta
**Mục đích.** Chứng minh mọi liên kết phải được phân đúng một nhóm và có ít nhất hai nhóm, theo FR-06-038.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-038 · API-06-059 · ERR-06-007, 032.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Y bốn liên kết.

**Các bước.**

1. Phân bổ thiếu một liên kết.
2. Phân bổ một liên kết vào hai nhóm.
3. Chỉ một nhóm.
4. Thiếu lý do.

**Kết quả mong đợi.** Bước 1, 2, 3 `422` ERR-06-032. Bước 4 `422` ERR-06-007. Bản ghi Y không đổi.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-085 · Xem và gỡ liên kết chéo nguồn <!--k:xref-detach-->

::: dac-ta
**Mục đích.** Chứng minh gỡ liên kết `MANUAL`, hai chế độ `RelinkMode` và liên kết do người xác nhận không bị máy tự tách, theo FR-06-044.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-044 · BR-06-018, 023 · API-06-066, 067 · ERR-06-006, 031 · EVT-06-14.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Z hai liên kết; DS1.

**Các bước.**

1. `GET .../xrefs`.
2. `POST .../xrefs/{id}:detach` `NEW_GOLDEN`, lý do.
3. Gỡ lại xref vừa `DETACHED`.
4. Chạy job lô trên domain.

**Kết quả mong đợi.** Bước 1 `XrefStatus` đúng. Bước 2 xref `DETACHED` `MANUAL`, bản ghi vàng mới, EVT-06-14. Bước 3 `409` ERR-06-006. Bước 4 không tự gắn lại xref đã gỡ (BR-06-023).

**Hậu điều kiện.** Z một liên kết.
:::

### TS-06-20 · Hoàn tác thao tác trên bản ghi vàng

**Mục tiêu.** Xác nhận hoàn tác khôi phục đúng kể cả khi có cập nhật nguồn xen giữa, thao tác phụ thuộc và hạn 90 ngày.

**Phủ.** FR-06-039; UC-06-20; API-06-060, 061; UI-06-03, 06; BR-06-005, 024; ERR-06-005, 033, 034; EVT-06-03, 04.

#### TC-06-086 · Hoàn tác hợp nhất và tách có cập nhật nguồn xen giữa <!--k:undo-merge-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 5: hợp nhất rồi hoàn tác, tách rồi hoàn tác khôi phục đúng trạng thái trước.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-039 · BR-06-005, 024 · API-06-060 · EVT-06-03, 04 · PERM-06-merge.

**Tiền điều kiện, dữ liệu.** Hợp nhất ca merge-manual; sau đó `HT-YTE` gửi cập nhật `phone`.

**Các bước.**

1. `POST /operations/{opId}:undo` thao tác hợp nhất.
2. Tách một bản ghi rồi `undo` thao tác tách.
3. So thuộc tính, xref với ảnh chụp trước.

**Kết quả mong đợi.** Bản ghi bị gộp `ACTIVE`, xref về chỗ cũ, cập nhật `phone` đến sau vẫn được áp; thao tác gốc `UNDONE`, thao tác `UNDO` mới ghi trỏ gốc, lịch sử không xóa. Hoàn tác hợp nhất phát EVT-06-04, hoàn tác tách phát EVT-06-03. KT: có (undo).

**Hậu điều kiện.** Trạng thái như trước các thao tác.
:::

#### TC-06-087 · Thao tác phụ thuộc chưa xác nhận <!--k:undo-dep-->

::: dac-ta
**Mục đích.** Chứng minh hoàn tác bị chặn khi có thao tác thủ công phụ thuộc, theo FR-06-039.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-039 · API-06-060 · ERR-06-033.

**Tiền điều kiện, dữ liệu.** Thao tác O1 hợp nhất, sau đó O2 `MANUAL_EDIT` trên bản ghi.

**Các bước.**

1. `undo` O1 với `confirmDependents = false`.
2. `undo` O1 với `confirmDependents = true`.

**Kết quả mong đợi.** Bước 1 `409` ERR-06-033 liệt kê 1 thao tác phụ thuộc. Bước 2 hoàn tác cả chuỗi.

**Thông báo hiển thị.** ERR-06-033 "Có {n} thao tác sau phụ thuộc vào thao tác này. Xem danh sách và xác nhận để hoàn tác cả chuỗi."

**Hậu điều kiện.** O1, O2 `UNDONE`.
:::

#### TC-06-088 · Hoàn tác quá hạn chuyển DA duyệt <!--k:undo-expired-->

::: dac-ta
**Mục đích.** Chứng minh quá `06.undo.window-days` cần DA khác duyệt, theo BR-06-024.

**Loại.** Biên, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-039 · BR-06-024 · API-06-060, 061 · ERR-06-005, 034.

**Tiền điều kiện, dữ liệu.** T92 (30 ngày); thao tác cách 29 và 31 ngày.

**Các bước.**

1. `undo` thao tác 29 ngày.
2. `undo` thao tác 31 ngày bằng DS1.
3. DS1 tự duyệt rồi DA1 duyệt.

**Kết quả mong đợi.** Bước 1 áp ngay. Bước 2 `403` ERR-06-034, tạo đề nghị chờ DA. Bước 3 DS1 `403` ERR-06-005; DA1 áp.

**Hậu điều kiện.** Một thao tác quá hạn được hoàn tác.
:::

### TS-06-21 · Tra cứu, tra ID nguồn và tìm kiếm có che dữ liệu

**Mục tiêu.** Xác nhận tra cứu, tra chéo ID, tìm kiếm đúng phạm vi, che theo phân loại và mục đích, giới hạn truy cập hàng loạt.

**Phủ.** FR-06-045, 046, 048, 052; UC-06-21; API-06-056, 068…070, 072; UI-06-02, 03; BR-06-010, 013, 026; ERR-06-037, 038, 039, 040, 050.

#### TC-06-089 · Tra bản ghi vàng theo ID và theo khóa định danh <!--k:lookup-id-->

::: dac-ta
**Mục đích.** Chứng minh tra theo `goldenId` và theo CCCD trong thân `POST`, theo FR-06-046.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-046 · API-06-056, 070 · NFR-06-001 · BR-06-010, 026.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình; S-T90-READ có mục đích `MD-TRACUU`.

**Các bước.**

1. `GET .../golden-records/{id}` với `X-Purpose`.
2. `POST .../golden-records:lookup` thân `{ "identifier": CC-03 }`.
3. Quét log APISIX tìm CC-03.

**Kết quả mong đợi.** Bước 1, 2 `200` cùng bản ghi, thuộc tính trong phạm vi mục đích, che theo phân loại, NK: có. Bước 3 không có CC-03 trong URL, log (số định danh luôn trong thân).

**Hậu điều kiện.** Hai dòng access_log.
:::

#### TC-06-090 · Không tìm thấy, thiếu mục đích, thiếu scope <!--k:lookup-neg-->

::: dac-ta
**Mục đích.** Chứng minh ba nhánh lỗi tra cứu, theo FR-06-046.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-046, 052 · BR-06-026 · API-06-070 · ERR-06-037, 050.

**Tiền điều kiện, dữ liệu.** S-T90-READ, S-T90-NOPURPOSE, token không scope `mdm:read`.

**Các bước.**

1. `lookup` khóa không tồn tại.
2. `lookup` bằng S-T90-NOPURPOSE.
3. `lookup` bằng token không scope.

**Kết quả mong đợi.** Bước 1 `404` ERR-06-050. Bước 2 `403` ERR-06-037. Bước 3 403-PQ. Không dòng `access_log` trả dữ liệu cho bước 2, 3.

**Thông báo hiển thị.** ERR-06-037 "Yêu cầu thiếu mục đích khai thác được chấp thuận cho dữ liệu này."

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-091 · Tra ID nguồn và ID vàng, tra lô <!--k:xref-lookup-->

::: dac-ta
**Mục đích.** Chứng minh tra hai chiều `(sourceCode, sourceKey)` và `goldenId`, theo FR-06-045.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-045 · API-06-068, 069 · ERR-06-003, 050.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình có xref `HT-YTE`/`YT-0001`.

**Các bước.**

1. `GET .../xrefs/HT-YTE/YT-0001`.
2. `POST .../xrefs:batch-lookup` 100 cặp, 5 cặp không có.
3. `batch-lookup` 1.001 cặp.

**Kết quả mong đợi.** Bước 1 `goldenId` đúng. Bước 2 95 kết quả, 5 `NOT_FOUND`. Bước 3 `400` ERR-06-003 (quá giới hạn lô).

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-092 · Tìm kiếm bản ghi vàng theo thuộc tính <!--k:search-->

::: dac-ta
**Mục đích.** Chứng minh tìm theo họ tên cộng năm sinh hoặc xã, phân trang, theo FR-06-048.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-048 · API-06-072 · UI-06-02 · BR-06-013.

**Tiền điều kiện, dữ liệu.** S-T90-SEARCH (`mdm:search`, mục đích chấp thuận); T97.

**Các bước.**

1. `POST .../golden-records:search` họ tên `Nguyễn Văn An` và năm sinh 1990, `size = 20`.
2. Tìm họ tên có dấu và không dấu.

**Kết quả mong đợi.** Bước 1 trang kết quả đúng, mỗi bản ghi đã che, NK: có từng bản ghi. Bước 2 cùng tập kết quả.

**Hậu điều kiện.** Một lượt tìm.
:::

#### TC-06-093 · Tiêu chí quá rộng, thiếu scope, truy cập hàng loạt <!--k:search-neg-->

::: dac-ta
**Mục đích.** Chứng minh chặn tìm rộng và truy cập vượt 100 bản ghi trong 10 phút, theo BR-06-013.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-048 · BR-06-013 · API-06-072 · ERR-06-038, 040.

**Tiền điều kiện, dữ liệu.** `06.access.bulk-threshold = 100 bản ghi / 10 phút`.

**Các bước.**

1. Tìm chỉ họ tên.
2. Tìm lần lượt 12 trang × 10 bản ghi khác nhau trong 10 phút.
3. Tìm bằng token thiếu `mdm:search`.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-040. Bước 2 từ bản ghi thứ 101 `403` ERR-06-038, ghi vết đặc biệt, cảnh báo quét bất thường. Bước 3 403-PQ.

**Thông báo hiển thị.** ERR-06-040 "Nhập thêm tiêu chí: họ tên cần đi kèm ngày sinh, năm sinh hoặc xã."

**Hậu điều kiện.** Một vết đặc biệt.
:::

#### TC-06-094 · Che dữ liệu theo phân loại, vai trò và mục đích <!--k:mask-matrix-->

::: dac-ta
**Mục đích.** Chứng minh ma trận `DataClass` × vai trò × mục đích, giá trị `SENSITIVE` luôn che nếu thiếu `PERM-09-unmask`, theo FR-06-052.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-052 · BR-06-016, 026 · API-06-056, 072 · UI-06-03.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng đủ bốn mức `DataClass`; DS1 không và có `PERM-09-unmask`; token máy mục đích phạm vi hẹp.

**Các bước.**

1. Chạy bảng tham số vai trò, mục đích, thuộc tính.
2. Gọi xuất và tìm kiếm với mục đích hẹp.
3. Quét phản hồi tìm canary `SENSITIVE`.

**Kết quả mong đợi.** `PUBLIC` rõ cho mọi vai trò có `read`; `INTERNAL`, `RESTRICTED` che theo chính sách PH-09; `SENSITIVE` che kể cả DS, chỉ hiện khi có `PERM-09-unmask` cộng lý do và ghi vết. Thuộc tính ngoài mục đích bị lược khỏi phản hồi. Mồi sạch.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-095 · Dừng nhật ký truy cập thì mọi API trả dữ liệu từ chối <!--k:accesslog-fail-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 6: không ghi được `access_log` thì không trả dữ liệu.

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** BR-06-010 · ERR-06-039 · NFR-06-015.

**Tiền điều kiện, dữ liệu.** T95; token đủ quyền cho từng API trả dữ liệu.

**Các bước.**

1. Dừng dịch vụ ghi `access_log`.
2. Gọi API-06-056, 068, 069, 070, 071, 072 và xuất, chi tiết ứng viên, so sánh cạnh nhau.
3. Khôi phục, gọi lại.

**Kết quả mong đợi.** Bước 2 mọi API `503` ERR-06-039, thân không chứa giá trị. Bước 3 trả `200`, số dòng `access_log` bằng số lượt thành công ở APISIX.

**Hậu điều kiện.** Không dòng thừa.
:::

### TS-06-22 · Giải quyết bản ghi trực tuyến (resolve)

**Mục tiêu.** Xác nhận ba kết luận `200`, `202`, `404`, không lưu dữ liệu gửi lên, hạn mức và mục đích.

**Phủ.** FR-06-047, 020, 021; UC-06-22; API-06-071; BR-06-002, 010, 026; ERR-06-003, 037, 048, 050; EVT-06-08.

#### TC-06-096 · Resolve có CCCD trả MATCH <!--k:resolve-match-->

::: dac-ta
**Mục đích.** Chứng minh `200` kèm `goldenId`, điểm, phương thức, thuộc tính đã che, theo FR-06-047.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-047 · API-06-071 · BR-06-001, 010 · NFR-06-002.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình; S-T90-RESOLVE.

**Các bước.**

1. `POST /domains/CITIZEN:resolve` `attributes` có CC-03, `requestingSource = HT-YTE`.

**Kết quả mong đợi.** `200`, `outcome = MATCH`, `method = DETERMINISTIC`, `goldenId`, `score`, `attributeScores`; thuộc tính che theo mục đích; không tạo ứng viên và không đổi bản ghi vàng; `access_log` không lưu giá trị đã gửi; NK: có.

**Hậu điều kiện.** Một dòng access_log.
:::

#### TC-06-097 · Resolve nghi ngờ trả 202 và tạo mục hàng đợi <!--k:resolve-possible-->

::: dac-ta
**Mục đích.** Chứng minh `POSSIBLE_MATCH` trả tối đa 3 ứng viên và không ghi dữ liệu theo kết quả, theo FR-06-047.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-047 · BR-06-002 · API-06-071 · EVT-06-08.

**Tiền điều kiện, dữ liệu.** Hai bản ghi vàng cùng tên "Lê Văn Cường"; không CCCD.

**Các bước.**

1. `resolve` mặc định `LOOKUP_ONLY`.
2. `resolve` `LOOKUP_OR_QUEUE`.

**Kết quả mong đợi.** Bước 1 `202`, `candidates[]` ≤ 3 chỉ có `goldenId`, điểm, thuộc tính hiển thị đã che. Bước 2 `202` kèm `queueItemId`, EVT-06-08 một lần.

**Hậu điều kiện.** Một mục hàng đợi.
:::

#### TC-06-098 · Resolve không khớp trả 404 NO_MATCH <!--k:resolve-nomatch-->

::: dac-ta
**Mục đích.** Chứng minh người gọi nhận `404` có `outcome = NO_MATCH`, theo FR-06-047.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-047 · API-06-071 · ERR-06-050.

**Tiền điều kiện, dữ liệu.** Hồ sơ giả chưa có trong T90.

**Các bước.**

1. `resolve` hồ sơ đó.

**Kết quả mong đợi.** `404` ERR-06-050 `outcome = NO_MATCH`; không tạo bản ghi vàng.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-099 · Thiếu thuộc tính tối thiểu, vượt hạn mức, thiếu mục đích <!--k:resolve-neg-->

::: dac-ta
**Mục đích.** Chứng minh ba nhánh lỗi, theo FR-06-047.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-047 · API-06-071 · ERR-06-003, 037, 048.

**Tiền điều kiện, dữ liệu.** T92 hạn mức nhỏ; S-T90-NOPURPOSE.

**Các bước.**

1. `resolve` chỉ có `email`.
2. Gọi 1.000 lượt trong một phút vượt hạn mức.
3. `resolve` bằng S-T90-NOPURPOSE.

**Kết quả mong đợi.** Bước 1 `400` ERR-06-003 "Cần ít nhất {n} thuộc tính …". Bước 2 từ lượt vượt `429` ERR-06-048. Bước 3 `403` ERR-06-037.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-23 · Xuất dữ liệu chủ có kiểm soát

**Mục tiêu.** Xác nhận xuất cần chấp thuận DO và DA, tệp mã hóa, thủy vân, hạn tải 24 giờ, giới hạn dòng.

**Phủ.** FR-06-049; UC-06-23; API-06-073…076; UI-06-15; BR-06-013, 026, 027; ERR-06-005, 041, 042.

#### TC-06-100 · Xuất 500 bản ghi có chấp thuận <!--k:export-pos-->

::: dac-ta
**Mục đích.** Chứng minh đề nghị, chấp thuận bởi DO và DA khác người đề nghị, tệp mã hóa có thủy vân, theo BR-06-027.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-049 · BR-06-027 · API-06-073, 074, 075, 076 · UI-06-15 · PERM-06-export.

**Tiền điều kiện, dữ liệu.** TA đề nghị; DO1, DA1; 500 bản ghi vàng, trường `PUBLIC`, `INTERNAL`.

**Các bước.**

1. `POST .../exports` `CSV`, `fields[]`, 500 bản ghi.
2. DO1 và DA1 `:approve`.
3. Chờ job `EXPORT`; `GET .../file`.

**Kết quả mong đợi.** `PENDING_APPROVAL` → `APPROVED` → `GENERATING` → `READY`; tệp mã hóa, mật khẩu qua thông báo trong ứng dụng, thủy vân người xuất ở dòng đầu, trường `SENSITIVE` che; hạn tải 24 giờ; mỗi lần tải có `access_log` ghi số bản ghi. KT: có (export-request, approve, download).

**Hậu điều kiện.** Tệp READY hết hạn sau 24 giờ.
:::

#### TC-06-101 · Vượt giới hạn, chưa chấp thuận, tự duyệt, tệp hết hạn <!--k:export-neg-->

::: dac-ta
**Mục đích.** Chứng minh các chặn của xuất, theo FR-06-049.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-049 · BR-06-027 · API-06-073, 075, 076 · ERR-06-005, 041, 042.

**Tiền điều kiện, dữ liệu.** T92 (`06.export.max-rows = 1000`).

**Các bước.**

1. Đề nghị xuất 1.001 bản ghi.
2. Tải tệp khi chưa `APPROVED`.
3. Người đề nghị tự `:approve`.
4. Tiến 25 giờ, tải tệp `READY`.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-041. Bước 2 `422` ERR-06-041. Bước 3 `403` ERR-06-005. Bước 4 `410` ERR-06-042, tệp đã xóa khỏi Garage.

**Hậu điều kiện.** Tệp EXPIRED.
:::

#### TC-06-102 · Xuất nhỏ chỉ trường không nhạy cảm <!--k:export-small-->

::: dac-ta
**Mục đích.** Chứng minh ≤ 100 bản ghi chỉ trường `PUBLIC`, `INTERNAL` cần DA duyệt, theo FR-06-049.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-049 · BR-06-013, 026 · API-06-073.

**Tiền điều kiện, dữ liệu.** DA1; 80 bản ghi.

**Các bước.**

1. Đề nghị xuất 80 bản ghi trường `PUBLIC`, `INTERNAL`.
2. Đề nghị xuất 80 bản ghi có `idNumber`.

**Kết quả mong đợi.** Bước 1 chỉ cần DA1 duyệt. Bước 2 cần cả DO và DA, `idNumber` che trừ khi duyệt rõ.

**Hậu điều kiện.** Một tệp READY.
:::

### TS-06-24 · Phát sự kiện thay đổi và đăng ký nhận cập nhật

**Mục tiêu.** Xác nhận sự kiện phát đủ, đúng chủ đề, không chứa giá trị thuộc tính, đăng ký nhận có mục đích và duyệt.

**Phủ.** FR-06-050, 051; UC-06-24; API-06-077, 078, 079; UI-06-15, 18; BR-06-012, 026; EVT-06-01…06; ERR-06-043, 109.

#### TC-06-103 · Sự kiện bản ghi vàng đủ sáu loại, không lộ giá trị <!--k:evt-emit-->

::: dac-ta
**Mục đích.** Chứng minh mỗi thao tác phát đúng một sự kiện cùng giao dịch outbox và chỉ chứa mã, phiên bản, tên thuộc tính đổi, theo BR-06-012.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT, IT.

**Truy vết.** FR-06-050 · BR-06-012 · EVT-06-01, 02, 03, 04, 05, 06 · NFR-06-014, 016 · ERR-06-109.

**Tiền điều kiện, dữ liệu.** T90; canary `DH-CANARY-evt` trong thuộc tính `SENSITIVE`.

**Các bước.**

1. Tạo, cập nhật, hợp nhất, tách, ngừng, khôi phục một bản ghi vàng.
2. Đọc sáu topic `t90.mdm.golden.*.v1`.
3. Dừng Kafka 5 phút khi cập nhật; bật lại.

**Kết quả mong đợi.** Bước 2 mỗi thao tác đúng một bản tin `ce_type = vn.datahub.mdm.golden.{…}`, có `dhtenant`, `goldenId`, `version`, tên thuộc tính đổi, nguồn gây đổi; Mồi sạch. Bước 3 outbox giữ, phát đủ theo thứ tự `goldenId` sau khi bật lại; quá số lần thử thì ERR-06-109 báo vận hành.

**Hậu điều kiện.** Không mất, không trùng bản tin.
:::

#### TC-06-104 · Đăng ký nhận cập nhật LINKED_ONLY được DO duyệt <!--k:sub-pos-->

::: dac-ta
**Mục đích.** Chứng minh HTTT nhận sự kiện của bản ghi vàng đã liên kết với nguồn của mình, theo FR-06-051.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, KT.

**Truy vết.** FR-06-051 · API-06-077, 078, 079 · UI-06-15 · BR-06-026 · PERM-06-export.

**Tiền điều kiện, dữ liệu.** HTTT `HT-YTE` có mục đích PH-09; DO1, DA1.

**Các bước.**

1. `POST /update-subscriptions` `SubscriptionScope = LINKED_ONLY`.
2. DO1 `:approve`.
3. Sửa một bản ghi vàng có xref `HT-YTE` và một bản ghi không có.

**Kết quả mong đợi.** Đăng ký `PENDING_APPROVAL` → `ACTIVE`. Chỉ bản ghi có xref `HT-YTE` sinh sự kiện tới bên nhận. `:suspend`, `:revoke` dừng nhận trong ≤ 60 giây. KT: có (subscription).

**Hậu điều kiện.** Một đăng ký ACTIVE.
:::

#### TC-06-105 · Đăng ký thiếu mục đích, tự duyệt, đã thu hồi <!--k:sub-neg-->

::: dac-ta
**Mục đích.** Chứng minh chặn đăng ký không có mục đích và dùng lại đăng ký đã thu hồi, theo FR-06-051.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-051 · API-06-078, 079 · ERR-06-005, 006, 043.

**Tiền điều kiện, dữ liệu.** HTTT `HT-MOI` chưa có mục đích; đăng ký `REVOKED`.

**Các bước.**

1. `POST /update-subscriptions` cho `HT-MOI`.
2. Người đề nghị tự `:approve`.
3. `:resume` đăng ký `REVOKED`.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-043. Bước 2 `403` ERR-06-005. Bước 3 `409` ERR-06-006.

**Hậu điều kiện.** Không đăng ký mới.
:::

### TS-06-25 · Đồng bộ CSDL tổng hợp quốc gia và xử lý lệch

**Mục tiêu.** Xác nhận đồng bộ chiều xuống, đối chiếu, tạm dừng khi lệch quá 5 %, xử lý lệch và chiều lên theo danh mục.

**Phủ.** FR-06-053, 054; UC-06-25; API-06-080…084; UI-06-14; BR-06-003, 011, 014, 025, 032; ERR-06-044, 045, 106, 107, 108; EVT-06-12, 13.

#### TC-06-106 · Chiều xuống: thuộc tính thẩm quyền quốc gia thắng <!--k:sync-down-->

::: dac-ta
**Mục đích.** Chứng minh bản ghi quốc gia vào như ứng viên nguồn mức 1 và ghi đè giá trị địa phương, theo FR-06-053.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-053 · BR-06-003, 032 · NFR-06-020 · API-06-080 · UI-06-14 · PERM-06-sync.

**Tiền điều kiện, dữ liệu.** T94; `nat-sim` gửi 100 bản ghi; bản ghi vàng có `dateOfBirth` địa phương khác.

**Các bước.**

1. `nat-sim` gửi bản ghi kênh `NATIONAL_SYNC`.
2. `GET /national-sync/status`.

**Kết quả mong đợi.** `dateOfBirth` lấy theo quốc gia, `GoldenChangeType = NATIONAL_SYNC`, ảnh chụp, lineage nguồn `QG-DANCU`; `nationalSyncedAt` cập nhật; áp trong ≤ 15 phút từ lúc nhận (NFR-06-020). Không có kết nối từ `dh-data` tới host quốc gia, chỉ tới PH-14.

**Hậu điều kiện.** 100 bản ghi vàng đồng bộ.
:::

#### TC-06-107 · Đối chiếu 1.000 bản ghi lệch 2 % <!--k:sync-reconcile-->

::: dac-ta
**Mục đích.** Chứng minh lượt đối chiếu trong ngưỡng áp lệch thẩm quyền và đưa lệch khác vào danh sách, theo FR-06-053.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-053, 054 · API-06-081, 083 · EVT-06-12 · UI-06-14.

**Tiền điều kiện, dữ liệu.** T94 F-SYNC lệch 2 % (20 bản ghi: 8 thuộc tính thẩm quyền, 12 thuộc tính khác).

**Các bước.**

1. `POST /national-sync/runs` `RECONCILE`.
2. `GET /national-sync/discrepancies`.

**Kết quả mong đợi.** Job `NATIONAL_RECONCILE` `SUCCEEDED`; 8 lệch thẩm quyền tự áp; 12 lệch còn `OPEN` với `DiscrepancySeverity` đúng (nhân thân `CRITICAL`); một EVT-06-12.

**Hậu điều kiện.** 12 lệch OPEN.
:::

#### TC-06-108 · Lệch 8 % tạm dừng đồng bộ tự động <!--k:sync-pause-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 8: lệch > 5 % thì không áp lệch nào và cảnh báo.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-06-053 · BR-06-011 · ERR-06-044, 107 · EVT-06-13 · UI-06-14.

**Tiền điều kiện, dữ liệu.** T94 F-SYNC lệch 8 % (80/1.000); `06.sync.pause-ratio = 0,05`.

**Các bước.**

1. Chạy `RECONCILE`.
2. Chạy lại `POST /national-sync/runs`.
3. DA1 điều tra và `POST /national-sync:resume`, chọn bỏ các lệch.

**Kết quả mong đợi.** Bước 1 đồng bộ `PAUSED`, không bản ghi vàng nào đổi, ERR-06-107 "tỷ lệ lệch 8% vượt 5%", EVT-06-13, cảnh báo DA, TA, băng đỏ UI-06-14. Bước 2 `409` ERR-06-044. Bước 3 `RUNNING`, EVT-06-13 (tiếp tục). KT: có (sync-pause, sync-resume).

**Thông báo hiển thị.** ERR-06-107 "Đồng bộ tự động đã tạm dừng: tỷ lệ lệch {x}% vượt 5%. Điều tra trước khi tiếp tục."

**Hậu điều kiện.** Đồng bộ RUNNING; 80 lệch đã xử lý.
:::

#### TC-06-109 · Chiều lên theo danh mục thuộc tính <!--k:sync-up-->

::: dac-ta
**Mục đích.** Chứng minh chỉ thuộc tính không thẩm quyền trong `06.sync.up-attributes` được gửi lên, theo FR-06-053 (Q06-02).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-06-053 · API-06-082 · ERR-06-045 · BR-06-025.

**Tiền điều kiện, dữ liệu.** T94; `06.sync.up-attributes` rỗng, rồi `["email"]`.

**Các bước.**

1. Chạy `NATIONAL_SYNC_UP` khi rỗng.
2. Đặt `["email"]`, chạy lại.
3. Đặt `["dateOfBirth"]`.

**Kết quả mong đợi.** Bước 1 không gửi gì. Bước 2 PH-14 nhận đúng `email`. Bước 3 `422` ERR-06-045 (thuộc tính thẩm quyền quốc gia).

**Hậu điều kiện.** Danh mục `["email"]`.
:::

#### TC-06-110 · Xử lý danh sách lệch <!--k:disc-resolve-->

::: dac-ta
**Mục đích.** Chứng minh bốn cách giải quyết `DiscrepancyResolution` và cấm giữ giá trị địa phương cho thuộc tính thẩm quyền, theo BR-06-025.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-054 · BR-06-014, 025 · API-06-084 · ERR-06-035 · PERM-06-sync.

**Tiền điều kiện, dữ liệu.** Ba lệch OPEN: thuộc tính thẩm quyền, thuộc tính khác, hai chiều mâu thuẫn.

**Các bước.**

1. `:resolve` `ACCEPT_NATIONAL` lệch 1.
2. `KEEP_LOCAL` lệch 1 khác thẩm quyền; `KEEP_LOCAL` lệch thẩm quyền.
3. `REPORT_TO_NATIONAL`; `IGNORE` kèm lý do.

**Kết quả mong đợi.** `ACCEPTED_NATIONAL`; `KEPT_LOCAL` hợp lệ với thuộc tính thường; `KEEP_LOCAL` với thuộc tính thẩm quyền `422` ERR-06-035; `REPORTED_TO_NATIONAL`, `IGNORED`; mọi quyết định có lý do và KT.

**Hậu điều kiện.** Các lệch đã đóng.
:::

#### TC-06-111 · PH-14 không khả dụng hoặc dữ liệu mâu thuẫn <!--k:sync-ph14-down-->

::: dac-ta
**Mục đích.** Chứng minh đồng bộ suy giảm có kiểm soát khi PH-14 lỗi, theo FR-06-053.

**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-06-053 · BR-06-032 · ERR-06-106, 108.

**Tiền điều kiện, dữ liệu.** T94, T95; `nat-sim` ngừng, rồi trả hai giá trị quốc gia mâu thuẫn cho một khóa.

**Các bước.**

1. Chạy đồng bộ khi `nat-sim` ngừng.
2. Chạy khi dữ liệu quốc gia mâu thuẫn.

**Kết quả mong đợi.** Bước 1 ERR-06-106 ở nhật ký, thử lại giãn dần, tra cứu nội bộ không bị ảnh hưởng. Bước 2 ERR-06-108, bản ghi bỏ qua, vào danh sách lệch, không áp giá trị nào.

**Hậu điều kiện.** Không bản ghi vàng đổi.
:::

### TS-06-26 · Vận hành: dashboard, lịch job và nhật ký

**Mục tiêu.** Xác nhận dashboard khớp số liệu, lịch và điều khiển job, nhật ký xử lý và truy cập đủ, phân quyền.

**Phủ.** FR-06-055, 056, 057; UC-06-26; API-06-085…089; UI-06-01, 12, 18; BR-06-010, 013, 031; ERR-06-006, 105.

#### TC-06-112 · Dashboard khớp số liệu CSDL <!--k:dash-metrics-->

::: dac-ta
**Mục đích.** Chứng minh chỉ số dashboard khớp đếm trực tiếp, theo FR-06-055.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-06-055 · API-06-085 · UI-06-01 · NFR-06-018 · ERR-06-112.

**Tiền điều kiện, dữ liệu.** T90 sau các kịch bản trước; VW.

**Các bước.**

1. `GET /dashboard/metrics`.
2. So từng chỉ số với truy vấn `psql`.

**Kết quả mong đợi.** Số bản ghi vàng theo trạng thái, hàng đợi mở và quá hạn, tỷ lệ tự động, job gần nhất, lệch quốc gia khớp đúng; chèn cố ý hai bản ghi vàng cùng số định danh thì hiện thẻ cảnh báo ERR-06-112 "Phát hiện {n} bản ghi vàng cùng số định danh"; VW xem được, không có nút hành động.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-113 · Lịch job, chạy lại, hủy <!--k:job-control-->

::: dac-ta
**Mục đích.** Chứng minh đặt lịch, `:rerun`, `:cancel` và chặn hủy job đã xong, theo FR-06-056.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-056 · API-06-041, 044, 086, 087 · ERR-06-006 · PERM-06-operate.

**Tiền điều kiện, dữ liệu.** TO; job `RUNNING` và `SUCCEEDED`.

**Các bước.**

1. `PUT /job-schedules/BATCH_MATCH` cron `0 2 * * 0`.
2. `:cancel` job `RUNNING`; `:rerun` job `FAILED`.
3. `:cancel` job `SUCCEEDED`; DS1 `:cancel`.

**Kết quả mong đợi.** Bước 1 lịch lưu. Bước 2 `CANCELLED`, rồi job mới `QUEUED`. Bước 3 `409` ERR-06-006; DS1 403-PQ. KT: có (job-cancel, job-rerun).

**Hậu điều kiện.** Lịch tuần 02:00.
:::

#### TC-06-114 · Nhật ký xử lý và nhật ký truy cập <!--k:logs-->

::: dac-ta
**Mục đích.** Chứng minh nhật ký có đủ trường, phạm vi quyền, giữ 12 tháng trực tuyến và 5 năm WORM, theo BR-06-031.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-057 · BR-06-013, 031 · API-06-088, 089 · UI-06-18 · PERM-06-audit-read.

**Tiền điều kiện, dữ liệu.** AU, SO, DS1; T90 có 100.000 dòng access_log.

**Các bước.**

1. AU `GET /access-logs` lọc theo người, mục đích, khoảng ngày.
2. DS1 `GET /access-logs`.
3. `GET /processing-logs` với DS1.

**Kết quả mong đợi.** Bước 1 mỗi dòng có người hoặc HTTT, mục đích, `goldenId`, số bản ghi, thời điểm, không có giá trị thuộc tính; lượt vượt ngưỡng hàng loạt gắn "vết đặc biệt". Bước 2 403-PQ. Bước 3 `200`. Cấu hình lưu giữ `access_log` 12 tháng và bản sao WORM 5 năm (kiểm cấu hình, không chờ thời gian).

**Hậu điều kiện.** Không đổi.
:::

### TS-06-27 · Yêu cầu của chủ thể dữ liệu

**Mục tiêu.** Xác nhận tiếp nhận, xử lý ba loại yêu cầu của chủ thể theo hạn, sửa tại nguồn, hạn chế xử lý.

**Phủ.** FR-06-058; UC-06-27; API-06-090, 091, 092; UI-06-16; BR-06-014, 030; ERR-06-007, 046; EVT-06-15.

#### TC-06-115 · Yêu cầu biết (ACCESS) <!--k:dsr-access-->

::: dac-ta
**Mục đích.** Chứng minh báo cáo dữ liệu đang giữ cho chính chủ thể, theo FR-06-058.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-06-058 · BR-06-030 · API-06-090, 091, 092 · UI-06-16 · PERM-06-dsr.

**Tiền điều kiện, dữ liệu.** SO tiếp nhận; DS1 xác nhận; bản ghi vàng Bình.

**Các bước.**

1. `POST /subject-requests` `DsrType = ACCESS`, đã xác minh danh tính, CC-03.
2. DS1 xác nhận đúng người, `:complete`.

**Kết quả mong đợi.** Yêu cầu `RECEIVED` → `IN_PROGRESS` → `COMPLETED`; báo cáo có thuộc tính (giá trị rõ cho chính chủ thể), nguồn từng thuộc tính, danh sách HTTT và mục đích truy cập 12 tháng; hạn theo `06.dsr.sla-days`. KT: có (dsr-complete).

**Hậu điều kiện.** Một yêu cầu COMPLETED.
:::

#### TC-06-116 · Yêu cầu sửa (RECTIFICATION) <!--k:dsr-rectify-->

::: dac-ta
**Mục đích.** Chứng minh sửa tại nguồn, không sửa ở bản ghi vàng, theo BR-06-014.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-058 · BR-06-014, 025 · API-06-092 · EVT-06-15.

**Tiền điều kiện, dữ liệu.** Hai yêu cầu: thuộc tính `phone` (nguồn `HT-YTE`) và `dateOfBirth` (thẩm quyền quốc gia).

**Các bước.**

1. `POST /subject-requests` cho `phone`; `:forward`.
2. `POST` cho `dateOfBirth`; `:complete`.

**Kết quả mong đợi.** Bước 1 `FORWARDED_TO_SOURCE`, EVT-06-15 tới `HT-YTE`, bản ghi vàng chưa đổi tới khi nguồn gửi. Bước 2 `COMPLETED` kèm hướng dẫn liên hệ cơ quan đăng ký.

**Hậu điều kiện.** Một yêu cầu FORWARDED.
:::

#### TC-06-117 · Yêu cầu hạn chế xử lý (RESTRICTION) <!--k:dsr-restrict-->

::: dac-ta
**Mục đích.** Chứng minh hạn chế đưa bản ghi vàng sang `LOCKED` có cờ `restricted`, theo FR-06-058.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-06-058 · API-06-092 · BR-06-026.

**Tiền điều kiện, dữ liệu.** Bản ghi vàng Bình; DS1.

**Các bước.**

1. `POST` `RESTRICTION`; `:complete`.
2. Gọi `lookup` mục đích tra cứu thường.

**Kết quả mong đợi.** Bản ghi `LOCKED` `restricted`, PH-09 nhận cập nhật chính sách; tra cứu mục đích không bắt buộc theo luật bị từ chối. Việc gỡ hạn chế chưa có API (ĐN-UC-05).

**Hậu điều kiện.** Bình LOCKED restricted.
:::

#### TC-06-118 · Chưa xác minh, yêu cầu xóa, từ chối, quá hạn <!--k:dsr-neg-->

::: dac-ta
**Mục đích.** Chứng minh các nhánh chặn và cảnh báo hạn của yêu cầu chủ thể, theo FR-06-058.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-058 · BR-06-030 · API-06-090, 092 · ERR-06-007, 046.

**Tiền điều kiện, dữ liệu.** SO; `06.dsr.sla-days = 10`; đồng hồ giả lập.

**Các bước.**

1. Gửi yêu cầu chưa xác minh danh tính.
2. Gửi yêu cầu xóa dữ liệu.
3. `:reject` thiếu lý do.
4. Tiến 8 rồi 11 ngày làm việc.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-046. Bước 2 từ chối có căn cứ pháp lý giữ dữ liệu có nguồn thẩm quyền, chuyển PH-09. Bước 3 `422` ERR-06-007. Bước 4 cảnh báo SO trước hạn 2 ngày, đánh dấu quá hạn.

**Thông báo hiển thị.** ERR-06-046 "Yêu cầu của chủ thể chưa xác minh danh tính."

**Hậu điều kiện.** Ba yêu cầu ở trạng thái cuối.
:::

### TS-06-28 · Chính sách lưu giữ và tham số theo tenant

**Mục tiêu.** Xác nhận dọn dữ liệu trung gian theo chính sách, bỏ qua dữ liệu bị giữ pháp lý, tham số trong miền.

**Phủ.** FR-06-059, 060; UC-06-28; API-06-093…096; UI-06-17, 12; BR-06-020, 022, 031; ERR-06-047, 049, 114.

#### TC-06-119 · Dọn dữ liệu quá hạn và giữ pháp lý <!--k:retention-->

::: dac-ta
**Mục đích.** Chứng minh `RETENTION_PURGE` xóa `raw`, `normalized` quá hạn, giữ dòng rút gọn, bỏ qua `legalHold`, theo FR-06-059.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-06-059 · BR-06-031 · API-06-093, 094 · ERR-06-049, 114 · UI-06-17.

**Tiền điều kiện, dữ liệu.** T90 có ứng viên quá hạn, 50 trong số đó thuộc nguồn có `legalHold`; TA.

**Các bước.**

1. `PUT /retention-policies/CANDIDATE` thấp hơn mức tối thiểu.
2. Đặt hợp lệ; chạy job.
3. Đọc kết quả và nhật ký xử lý.

**Kết quả mong đợi.** Bước 1 `422` ERR-06-049. Bước 3 ứng viên quá hạn mất `raw`, `normalized`, còn dòng rút gọn (nguồn, `sourceKey` băm, trạng thái, `goldenId`); 50 ứng viên giữ pháp lý bị bỏ qua, ERR-06-114 ghi nhận; không xóa bản ghi vàng; số lượng ghi vào nhật ký, báo cáo tháng.

**Hậu điều kiện.** Dữ liệu trung gian đã dọn.
:::

#### TC-06-120 · Tham số theo tenant trong và ngoài miền <!--k:settings-->

::: dac-ta
**Mục đích.** Chứng minh đổi tham số trong miền có hiệu lực, ngoài miền và vượt trần bị chặn, theo FR-06-060.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-060 · BR-06-020, 022 · API-06-095, 096 · ERR-06-047 · PERM-06-config.

**Tiền điều kiện, dữ liệu.** TA, DS1, PA.

**Các bước.**

1. TA `PUT /settings` `06.queue.sla-days = 5`, `06.batch.safety-ratio = 0,08`.
2. TA đặt `06.batch.safety-ratio = 0,5`; `06.export.max-rows = 5.000.000`.
3. DS1 `PUT /settings`.

**Kết quả mong đợi.** Bước 1 `200`, tạo mục hàng đợi mới có SLA 5 ngày, job lô dùng 8 %. Bước 2 `422` ERR-06-047 nêu miền. Bước 3 403-PQ. KT: có (settings-update) ghi giá trị cũ, mới.

**Hậu điều kiện.** Hai tham số đã đổi.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

### TS-06-29 · Cô lập tenant: API, RLS, Kafka, kho tệp

**Mục tiêu.** Chứng minh không đường nào để T91 đọc hoặc ghi dữ liệu chủ của T90, với mọi API đọc.

**Phủ.** NFR-06-001; FR-06-001…060 (mọi API đọc); API-06-001…096; BR-06-032.

#### TC-06-121 · Rò rỉ chéo tenant: cấu hình <!--k:iso-api-cfg-->

::: dac-ta
**Mục đích.** Chứng minh domain, nguồn, quy tắc, tập nhãn, sống sót, lưu giữ, tham số của T90 là `404-ẩn` với T91.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** API-06-002, 004, 018, 030, 037, 051, 093, 095 · ERR-06-001 · FR-06-001, 009, 018, 025, 033, 059, 060.

**Tiền điều kiện, dữ liệu.** T90 và T91 cùng mã domain `CITIZEN`, nguồn `HT-YTE`; U-T91-DS1.

**Các bước.**

1. U-T91-DS1 gọi GET chi tiết, danh sách các API nhóm cấu hình bằng định danh của T90.
2. Gửi `tenant_id` T90 trong thân `PUT /settings`.

**Kết quả mong đợi.** Bước 1 danh sách chỉ có dữ liệu T91, chi tiết 404-ẩn thân giống "không tồn tại" trừ `traceId`. Bước 2 `400` hoặc `403` ERR-00-003, không ghi vào T90.

**Hậu điều kiện.** T90 không đổi.
:::

#### TC-06-122 · Rò rỉ chéo tenant: ứng viên, hàng đợi, bản ghi vàng <!--k:iso-api-data-->

::: dac-ta
**Mục đích.** Chứng minh ứng viên, mục hàng đợi, bản ghi vàng, lịch sử, lineage, xref, thao tác của T90 là 404-ẩn với T91, kể cả `:claim`, `:undo`, `:approve`.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** API-06-026, 027, 045, 046, 056, 063, 065, 066, 060, 061 · ERR-06-001 · FR-06-017, 028, 035, 041, 043, 044.

**Tiền điều kiện, dữ liệu.** Đối tượng của T90 đã tạo ở TS-06-10…20; U-T91-DS1, DA1.

**Các bước.**

1. Gọi GET và POST hành động của các API trên bằng token T91.

**Kết quả mong đợi.** Mọi lệnh `404` ERR-06-001, không đổi trạng thái T90, không dòng `access_log` ở T90.

**Hậu điều kiện.** T90 không đổi.
:::

#### TC-06-123 · Rò rỉ chéo tenant: tra cứu, resolve, tìm, xuất, nhật ký <!--k:iso-api-serve-->

::: dac-ta
**Mục đích.** Chứng minh các API trả dữ liệu không trả bản ghi của tenant khác dù trùng CCCD giả.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** API-06-068, 069, 070, 071, 072, 074, 076, 088, 089, 091 · ERR-06-001, 050 · FR-06-045…049, 057, 058.

**Tiền điều kiện, dữ liệu.** CC-03 có ở cả T90 và T91 với `goldenId` khác; S-T91-READ; tệp xuất T90.

**Các bước.**

1. `lookup`, `resolve`, `search` bằng S-T91-READ.
2. Tải tệp xuất, xem yêu cầu chủ thể, nhật ký của T90.

**Kết quả mong đợi.** Bước 1 chỉ trả `goldenId` của T91. Bước 2 `404` ERR-06-001. Tệp xuất ở Garage không truy cập được bằng URL của T91.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-124 · RLS trên mọi bảng ph06_mdm <!--k:iso-rls-db-->

::: dac-ta
**Mục đích.** Chứng minh RLS theo `tenant_id` ở mọi bảng, kể cả bảng staging và kết quả job.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** API-06-001 · NFR-06-016 · BR-06-018.

**Tiền điều kiện, dữ liệu.** `03-thiet-ke/csdl/ph06/test/`; vai CSDL của T90, T91.

**Các bước.**

1. Liệt kê bảng `ph06_mdm.*` thiếu `ROW LEVEL SECURITY` hoặc `FORCE`.
2. Với vai T90 đọc, chèn, sửa, xóa dòng T91; chèn dòng `tenant_id` T91.
3. Kiểm vai Job Splink: chỉ đọc `stg_match_*`, chỉ ghi `stg_match_result_*`.

**Kết quả mong đợi.** Không bảng thiếu RLS. Đọc thấy 0 dòng T91; chèn và sửa bị chặn `WITH CHECK`; vai nào cũng không có `BYPASSRLS`. Job không đọc được `golden_record`.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-125 · Cô lập topic và tệp theo tenant <!--k:iso-kafka-files-->

::: dac-ta
**Mục đích.** Chứng minh ACL tiền tố `t90.mdm.` và tiền tố kho tệp.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT, IT.

**Truy vết.** EVT-06-01…15 · BR-06-012 · FR-06-050, 049.

**Tiền điều kiện, dữ liệu.** Principal T90, T91; tệp tạm và tệp xuất T90.

**Các bước.**

1. Principal T91 đọc, ghi `t90.mdm.golden.updated.v1`.
2. T91 liệt kê topic.
3. T91 đọc đối tượng Garage của T90.

**Kết quả mong đợi.** Bước 1 bị từ chối (`TOPIC_AUTHORIZATION_FAILED`). Bước 2 không thấy topic T90. Bước 3 `AccessDenied`.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-30 · Phân quyền theo ma trận PERM-06 và bốn mắt

**Mục tiêu.** Chứng minh mười hai quyền PERM-06 khớp ma trận FRS §3.2 và mọi điểm bốn mắt không có đường vòng.

**Phủ.** FRS §3.2, §3.3; BR-06-004, 019, 024, 027; ERR-06-005, 028.

#### TC-06-126 · Ma trận 12 quyền × 10 vai trò <!--k:perm-matrix-->

::: dac-ta
**Mục đích.** Chứng minh từng ô ●, ○, — của ma trận quyền bằng một API đại diện cho mỗi quyền.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** PERM-06-read, update, merge, config, approve, steward, ingest, export, sync, operate, dsr, audit-read · ERR-06-028 · FR-06-001…060.

**Tiền điều kiện, dữ liệu.** 10 vai trò PA, TA, TO, SO, DS, DA, DO, VW, AU cùng token máy.

**Các bước.**

1. Chạy bảng tham số 12 × 10 gọi API đại diện (ví dụ `PERM-06-merge`: `POST …:merge`).
2. Với ô `○`, gọi trên đối tượng trong và ngoài tổ chức.

**Kết quả mong đợi.** Ô ● trả 2xx, ô — trả 403-PQ; ô ○ chỉ đối tượng thuộc tổ chức, ngoài tổ chức `403` ERR-06-028. DS không có `approve`; DA không có `update`.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-127 · Mọi điểm bốn mắt <!--k:perm-4eyes-->

::: dac-ta
**Mục đích.** Chứng minh người đề nghị không tự duyệt ở tám điểm bốn mắt của FRS §3.3, kể cả TA có cả hai quyền.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-06-004, 019, 024, 027 · ERR-06-005 · FR-06-006, 009, 018, 031, 033, 039, 042, 049.

**Tiền điều kiện, dữ liệu.** U-T90-TA (soạn và duyệt, chỉ SIT), DS1, DA1.

**Các bước.**

1. Tại từng điểm: kích hoạt mô hình, bộ quy tắc, ưu tiên nguồn, quy tắc sống sót, hợp nhất rủi ro cao, hoàn tác quá hạn, xuất, áp lại, người đề nghị gọi `:approve`.
2. Cùng thao tác do DA khác duyệt.

**Kết quả mong đợi.** Bước 1 tám lần `403` ERR-06-005, không đổi trạng thái. Bước 2 tám lần thành công. KT: có ghi cả lượt bị chặn.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-128 · Scope tài khoản máy <!--k:perm-scope-->

::: dac-ta
**Mục đích.** Chứng minh scope `mdm:ingest`, `read`, `resolve`, `search` tách biệt và gắn nguồn, mục đích.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-06-010, 046, 047, 048 · ERR-06-014, 037.

**Tiền điều kiện, dữ liệu.** Bốn token, mỗi token một scope.

**Các bước.**

1. Mỗi token gọi API của scope khác.
2. Token `mdm:search` khi PH-09 chưa chấp thuận mục đích.

**Kết quả mong đợi.** Gọi sai scope 403-PQ; `mdm:ingest` chỉ cho nguồn đã đăng ký (ERR-06-014); bước 2 `403` ERR-06-037 và không cấp được `mdm:search`.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-31 · Kiểm toán, mã hóa số định danh và an toàn dữ liệu

**Mục tiêu.** Chứng minh số định danh và thuộc tính SENSITIVE được mã hóa, không lộ ở log, topic, tệp, và mọi lượt trả dữ liệu có nhật ký.

**Phủ.** NFR-06-015, 016; FR-06-004, 052, 057; BR-06-010, 012, 016; ERR-06-113.

#### TC-06-129 · Quét giá trị SENSITIVE dạng rõ ở mọi nơi lưu <!--k:sec-encrypt-->

::: dac-ta
**Mục đích.** Chứng minh tiêu chí chấp nhận 7: 100 % thuộc tính `SENSITIVE` mã hóa envelope (ADR-032) khi lưu.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** ZAP, DB.

**Truy vết.** NFR-06-016 · BR-06-012, 016 · FR-06-004, 034.

**Tiền điều kiện, dữ liệu.** T90 nạp 2.000 ứng viên có canary `DH-CANARY-sec` và CC-xx giả trong thuộc tính `SENSITIVE`.

**Các bước.**

1. Quét `ph06_mdm.*` (ứng viên, `golden`, `golden_history`, `match_result`, staging, outbox).
2. Quét log 5 phút, vết OTel, topic `t90.mdm.*`, tệp xuất, bản sao lưu logic.
3. Quét phản hồi API bằng vai không có `PERM-09-unmask`.

**Kết quả mong đợi.** Không thấy canary, CCCD giả rõ ở nơi nào; cột nhạy cảm ở dạng bản mã có `key_id`; khóa gom nhóm, staging chỉ HMAC.

**Hậu điều kiện.** Báo cáo quét đính kèm.
:::

#### TC-06-130 · Không giải mã được và xoay khóa <!--k:sec-key-->

::: dac-ta
**Mục đích.** Chứng minh lỗi giải mã không lộ dữ liệu và job `REENCRYPT` xoay khóa không gián đoạn.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** ERR-06-113 · NFR-06-016 · FR-06-056.

**Tiền điều kiện, dữ liệu.** T95; OpenBao giả lập khóa mất, rồi khóa mới.

**Các bước.**

1. Gỡ khóa của một bản ghi, `GET` bản ghi.
2. Chạy `REENCRYPT` với khóa mới trong lúc k6 đọc 50 lượt mỗi giây.

**Kết quả mong đợi.** Bước 1 thuộc tính lỗi bị bỏ, ERR-06-113 ở nhật ký, cảnh báo vận hành, các thuộc tính khác vẫn trả. Bước 2 job `SUCCEEDED`, 0 lỗi đọc, mọi bản mã mang `key_id` mới.

**Hậu điều kiện.** Khóa cũ nghỉ hưu.
:::

#### TC-06-131 · Số access_log khớp số lượt ở cổng <!--k:sec-audit-count-->

::: dac-ta
**Mục đích.** Chứng minh 100 % lượt trả dữ liệu có đúng một dòng `access_log`.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** k6, DB.

**Truy vết.** NFR-06-015 · BR-06-010 · FR-06-057.

**Tiền điều kiện, dữ liệu.** T97; 10.000 lượt hỗn hợp `lookup`, `resolve`, `search`, chi tiết, xuất, so sánh.

**Các bước.**

1. Chạy tải, thu số lượt `2xx` ở APISIX.
2. Đếm `access_log` cùng khoảng.

**Kết quả mong đợi.** Hai số bằng nhau, không dòng thiếu hoặc thừa; mỗi dòng có người hoặc HTTT, mục đích, số bản ghi, `traceId`.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-132 · Kiểm toán thay đổi đủ trường, không chứa DLCN <!--k:sec-audit-content-->

::: dac-ta
**Mục đích.** Chứng minh mọi thao tác thay đổi có kiểm toán PH-13 đủ trường FR-00-041 và không chứa giá trị DLCN.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-06-002, 006, 030, 036, 037, 038, 039, 049, 053 · BR-06-008, 012.

**Tiền điều kiện, dữ liệu.** Các thao tác đã chạy ở TS-06-02…25 với canary.

**Các bước.**

1. Đối chiếu danh sách thao tác với bản ghi kiểm toán.
2. Quét nội dung kiểm toán tìm canary.

**Kết quả mong đợi.** Số thao tác bằng số bản ghi; có người, thời điểm, đối tượng, lý do, trước và sau chỉ ở dạng tên thuộc tính; Mồi sạch.

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-133 · Quét ZAP API và chống tiêm, ReDoS <!--k:sec-zap-->

::: dac-ta
**Mục đích.** Chứng minh không cảnh báo High ở `/api/mdm/v1` (ASVS 5.0 mức 2).

**Loại.** Bảo mật.

**Ưu tiên.** P2.

**Tự động.** ZAP.

**Truy vết.** API-06-001…096 · FR-06-003, 048.

**Tiền điều kiện, dữ liệu.** STAGING, token thử đủ quyền.

**Các bước.**

1. ZAP API scan theo OpenAPI có xác thực.
2. Tiêm SQL, `REGEX` ReDoS, thân quá lớn vào `search`, `identifier-rules:test`, tệp nạp.

**Kết quả mong đợi.** 0 cảnh báo High; Medium đã phân loại; mọi tiêm bị từ chối `400`, `422`, `413`, không treo.

**Hậu điều kiện.** Báo cáo ZAP.
:::

### TS-06-32 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-06-001…005, 013, 014, 020 ở hồ sơ tỉnh vừa trên PERF.

**Phủ.** NFR-06-001…005, 013, 014, 020.

#### TC-06-134 · Tra bản ghi vàng p99 ≤ 50 ms <!--k:perf-lookup-->

::: dac-ta
**Mục đích.** Đo NFR-06-001 ở 200 lượt mỗi giây qua APISIX.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-06-001 · API-06-056, 070.

**Tiền điều kiện, dữ liệu.** T97 F-PERF; tra theo ID và khóa, tỷ lệ 70/30.

**Các bước.**

1. k6 200 lượt mỗi giây trong 15 phút, 5 phút khởi động.

**Kết quả mong đợi.** p99 ≤ 50 ms, 0 lỗi `5xx`, không tính mạng ngoài.

**Hậu điều kiện.** Báo cáo k6.
:::

#### TC-06-135 · Resolve xác định p99 ≤ 30 ms <!--k:perf-det-->

::: dac-ta
**Mục đích.** Đo NFR-06-002 cho resolve có CCCD.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-06-002 · API-06-071.

**Tiền điều kiện, dữ liệu.** T97.

**Các bước.**

1. k6 resolve 100 % có CCCD hợp lệ, 200 lượt mỗi giây, đo trong `dh-data`.

**Kết quả mong đợi.** p99 ≤ 30 ms.

**Hậu điều kiện.** Báo cáo.
:::

#### TC-06-136 · Resolve xác suất p95 ≤ 300 ms, p99 ≤ 800 ms <!--k:perf-prob-->

::: dac-ta
**Mục đích.** Đo NFR-06-003 gồm gom nhóm và chấm điểm trên 1,2 triệu CITIZEN.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-06-003 · API-06-071.

**Tiền điều kiện, dữ liệu.** T97; hồ sơ không CCCD.

**Các bước.**

1. k6 100 lượt mỗi giây 15 phút.

**Kết quả mong đợi.** p95 ≤ 300 ms, p99 ≤ 800 ms; tỷ lệ `TIMEOUT` < 1 %.

**Hậu điều kiện.** Báo cáo.
:::

#### TC-06-137 · Thông lượng nạp 1.000 bản ghi mỗi giây <!--k:perf-ingest-->

::: dac-ta
**Mục đích.** Đo NFR-06-004 và dung lượng NFR-06-005.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-06-004, 005 · API-06-021.

**Tiền điều kiện, dữ liệu.** T97 nạp; T98 10 triệu bản ghi vàng.

**Các bước.**

1. Nạp 1.000 bản ghi mỗi giây duy trì 10 phút.
2. Trên T98 lặp perf-lookup.

**Kết quả mong đợi.** Hàng chờ không quá 5 phút. Ở T98 tra vẫn p99 ≤ 50 ms.

**Hậu điều kiện.** Báo cáo.
:::

#### TC-06-138 · Job lô 1,2 triệu CITIZEN ≤ 2 giờ <!--k:perf-batch-->

::: dac-ta
**Mục đích.** Đo NFR-06-013 trên Job 8 vCPU, 32 GB (giả định theo số đo công bố của Splink).

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** NFR-06-013 · FR-06-022.

**Tiền điều kiện, dữ liệu.** T99 1,2 triệu CITIZEN, bộ quy tắc ACTIVE.

**Các bước.**

1. Chạy `FULL_INITIAL`, ghi thời gian từng pha.

**Kết quả mong đợi.** Từ `QUEUED` tới `SUCCEEDED` ≤ 2 giờ; bộ nhớ Job không quá giới hạn.

**Hậu điều kiện.** Số đo làm cơ sở GĐ.
:::

#### TC-06-139 · Độ trễ sự kiện và đồng bộ chiều xuống <!--k:perf-event-sync-->

::: dac-ta
**Mục đích.** Đo NFR-06-014 và NFR-06-020.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6, KT.

**Truy vết.** NFR-06-014, 020 · EVT-06-02 · FR-06-050, 053.

**Tiền điều kiện, dữ liệu.** T97, T94.

**Các bước.**

1. Cập nhật 100 bản ghi mỗi giây 10 phút, đo `mdm_event_lag_seconds`.
2. `nat-sim` gửi 10.000 thay đổi, đo thời điểm áp.

**Kết quả mong đợi.** Commit tới Kafka p95 ≤ 5 giây. Áp thay đổi quốc gia p95 ≤ 15 phút.

**Hậu điều kiện.** Báo cáo.
:::

### TS-06-33 · Độ chính xác đối sánh

**Mục tiêu.** Chứng minh precision, recall, tỷ lệ tự động và độ phủ gom nhóm trên tập nhãn giả định.

**Phủ.** NFR-06-006…010; BR-06-001, 021; FR-06-019, 020, 021, 022, 026.

#### TC-06-140 · Precision, recall đối sánh trực tuyến <!--k:acc-pr-online-->

::: dac-ta
**Mục đích.** Chứng minh hợp nhất sai ≤ 0,1 % và bỏ sót ≤ 2 % trên `NHAN-12K`.

**Loại.** Độ chính xác.

**Ưu tiên.** P1.

**Tự động.** ACC.

**Truy vết.** NFR-06-008, 009 · BR-06-021 · FR-06-021, 026.

**Tiền điều kiện, dữ liệu.** T96 F-LBL 12.000 cặp; bộ quy tắc ACTIVE.

**Các bước.**

1. `eval_accuracy.py` chạy đối sánh trực tuyến cho mọi cặp.
2. Tính ma trận TP, FP, FN, TN theo vùng `MATCH`.

**Kết quả mong đợi.** Precision = TP/(TP+FP) ≥ 99,9 %; recall = TP/(TP+FN) ≥ 98 %; báo cáo kèm 1.500 cặp khó riêng, FP ghi từng cặp.

**Hậu điều kiện.** Báo cáo đính kèm hồ sơ RG-3.
:::

#### TC-06-141 · Đối sánh lô Splink không kém trực tuyến <!--k:acc-batch-->

::: dac-ta
**Mục đích.** Chứng minh kết quả Splink đạt cùng ngưỡng và nhất quán với trực tuyến.

**Loại.** Độ chính xác.

**Ưu tiên.** P1.

**Tự động.** ACC, JOB.

**Truy vết.** NFR-06-008, 009 · FR-06-022.

**Tiền điều kiện, dữ liệu.** Cùng `NHAN-12K`.

**Các bước.**

1. Chạy job lô `dryRun` trên tập, đọc kết quả.
2. So kết luận với acc-pr-online.

**Kết quả mong đợi.** Precision ≥ 99,9 %, recall ≥ 98 %; số cặp hai phương pháp khác kết luận ≤ 2 %, tất cả nằm trong vùng `POSSIBLE_MATCH` của ít nhất một phương pháp.

**Hậu điều kiện.** Báo cáo.
:::

#### TC-06-142 · Đối sánh xác định đúng 100 % <!--k:acc-det-->

::: dac-ta
**Mục đích.** Chứng minh khóa hợp lệ cho kết quả đúng tuyệt đối.

**Loại.** Độ chính xác.

**Ưu tiên.** P1.

**Tự động.** ACC.

**Truy vết.** NFR-06-010 · BR-06-001 · FR-06-020.

**Tiền điều kiện, dữ liệu.** 2.000 cặp khóa hợp lệ (trùng và khác), tên nhiễu.

**Các bước.**

1. Chạy `resolve` cho từng cặp.

**Kết quả mong đợi.** 100 % cặp cùng khóa `MATCH`, cặp khác khóa không bao giờ `MATCH`; 0 sai.

**Hậu điều kiện.** Báo cáo.
:::

#### TC-06-143 · Độ phủ gom nhóm và tỷ lệ tự động <!--k:acc-block-auto-->

::: dac-ta
**Mục đích.** Chứng minh ≤ 50 ứng viên mỗi lượt, độ phủ ≥ 99,5 % và ≥ 85 % ứng viên tự xử lý.

**Loại.** Độ chính xác.

**Ưu tiên.** P2.

**Tự động.** ACC.

**Truy vết.** NFR-06-006, 007 · FR-06-019, 027.

**Tiền điều kiện, dữ liệu.** T96 F-AUTO 100.000 ứng viên, 20 nguồn.

**Các bước.**

1. Nạp F-AUTO.
2. Đọc `blocking-stats` và `mdm_auto_rate`.

**Kết quả mong đợi.** Trung bình ≤ 50, độ phủ ≥ 99,5 %; tự động ≥ 85 %, vào hàng đợi ≤ 15 %.

**Hậu điều kiện.** Báo cáo.
:::

#### TC-06-144 · Ca khó không hợp nhất sai <!--k:acc-hard-->

::: dac-ta
**Mục đích.** Chứng minh cha con, anh em song sinh, trùng tên khác ngày sinh không bị tự hợp nhất.

**Loại.** Độ chính xác.

**Ưu tiên.** P1.

**Tự động.** ACC.

**Truy vết.** BR-06-006, 015 · FR-06-021.

**Tiền điều kiện, dữ liệu.** 300 cặp khó trong F-LBL.

**Các bước.**

1. Chạy đối sánh.

**Kết quả mong đợi.** 0 cặp song sinh, cha con tự `MATCH`; chuyển vào hàng đợi hoặc `NO_MATCH`.

**Hậu điều kiện.** Báo cáo.
:::

### TS-06-34 · Chịu lỗi, khôi phục và quan sát

**Mục tiêu.** Chứng minh hệ suy giảm có kiểm soát khi PH-07, PH-09, Kafka, PostgreSQL lỗi, và đủ chỉ số, cảnh báo.

**Phủ.** NFR-06-011, 012, 018, 019; ERR-06-021, 109, 111; BR-06-005.

#### TC-06-145 · PH-07 hoặc PH-09 ngừng <!--k:chaos-deps-->

::: dac-ta
**Mục đích.** Chứng minh nạp và resolve suy giảm đúng khi phụ thuộc ngừng.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** ERR-06-021 · FR-06-014, 015, 047 · NFR-06-011.

**Tiền điều kiện, dữ liệu.** T95; WireMock PH-07 rồi PH-09 trả `503`.

**Các bước.**

1. Nạp ứng viên địa chỉ khi PH-07 ngừng.
2. `resolve` khi PH-09 ngừng.
3. Khôi phục.

**Kết quả mong đợi.** Bước 1 `NORMALIZATION_PENDING`, tự xử lý sau khi khôi phục. Bước 2 `503` ERR-06-021, không trả dữ liệu chưa kiểm mục đích. Bước 3 hàng chờ tiêu hết, không mất ứng viên.

**Hậu điều kiện.** Không mất dữ liệu.
:::

#### TC-06-146 · PostgreSQL chuyển dự phòng, Kafka ngừng <!--k:chaos-pg-kafka-->

::: dac-ta
**Mục đích.** Chứng minh RPO ≤ 15 phút, RTO ≤ 30 phút và outbox không mất sự kiện.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-06-012, 014 · ERR-06-109 · BR-06-005.

**Tiền điều kiện, dữ liệu.** T95 chịu tải 50 thao tác mỗi giây.

**Các bước.**

1. Chuyển dự phòng `pg-core`; đo thời gian dịch vụ tra cứu hồi phục.
2. Dừng Kafka 10 phút rồi bật.

**Kết quả mong đợi.** Không bản ghi vàng nào mất giao dịch đã commit, 0 bản ghi lệch ảnh chụp; hồi phục ≤ 30 phút; outbox phát đủ, thứ tự theo `goldenId`.

**Hậu điều kiện.** Số đo RTO, RPO.
:::

#### TC-06-147 · Đối sánh trực tuyến quá giờ <!--k:chaos-prob-timeout-->

::: dac-ta
**Mục đích.** Chứng minh truy vấn > 800 ms thành `POSSIBLE_MATCH` lý do `TIMEOUT`.

**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-06-021 · NFR-06-018 · UI-06-01.

**Tiền điều kiện, dữ liệu.** T95; chèn độ trễ `pg_sleep` vào truy vấn khối.

**Các bước.**

1. `resolve` 100 lượt khi có độ trễ.

**Kết quả mong đợi.** Mọi lượt `202` `TIMEOUT`, `mdm_match_timeout_total` tăng; khi tỷ lệ > 1 % dashboard hiện cảnh báo "Đối sánh trực tuyến chậm".

**Hậu điều kiện.** Không đổi.
:::

#### TC-06-148 · Chỉ số và cảnh báo <!--k:obs-alerts-->

::: dac-ta
**Mục đích.** Chứng minh phát đủ chỉ số và bảy cảnh báo của NFR-06-019.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** NFR-06-018, 019 · FR-06-055.

**Tiền điều kiện, dữ liệu.** STAGING; Prometheus, Alertmanager PH-13.

**Các bước.**

1. Kiểm danh sách chỉ số với bảng FR-06-055 và `mdm_event_lag_seconds`, `mdm_match_timeout_total`, `mdm_block_truncated_total`.
2. Mô phỏng: hàng đợi > 500, tự động < 80 %, lệch quốc gia > 5 %, mục chờ > 7 ngày, job thất bại, ghi vết lỗi, quét bất thường.

**Kết quả mong đợi.** Đủ chỉ số; mỗi mô phỏng sinh đúng một cảnh báo tới PH-13 trong ≤ 5 phút.

**Hậu điều kiện.** Không đổi.
:::

### TS-06-35 · Truy cập và giao diện

**Mục tiêu.** Chứng minh giao diện dùng được, che dữ liệu cá nhân, hiển thị đúng câu thông báo lỗi.

**Phủ.** UI-06-01…18; FR-06-029, 030, 052; ERR-06-005, 007, 027, 029, 030, 039.

#### TC-06-149 · Luồng người quản lý dữ liệu trên giao diện <!--k:ui-steward-e2e-->

::: dac-ta
**Mục đích.** Chứng minh hành trình từ hàng đợi tới quyết định và hợp nhất, trung vị ≤ 60 giây mỗi mục (NFR-06-017).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** UI-06-04, 05, 06 · FR-06-028, 029, 030, 037 · NFR-06-017.

**Tiền điều kiện, dữ liệu.** 30 mục POSSIBLE_MATCH; DS1.

**Các bước.**

1. Mở `/du-lieu/du-lieu-chu/hang-doi`, nhận mục đầu.
2. Quyết định theo bàn phím.
3. Lặp 30 mục, đo thời gian.

**Kết quả mong đợi.** Mỗi mục xong không rời trang; trung vị ≤ 60 giây; không chỉ dùng màu để phân biệt mức so sánh.

**Hậu điều kiện.** 30 mục xử lý.
:::

#### TC-06-150 · Khả năng truy cập 18 màn hình <!--k:ui-a11y-->

::: dac-ta
**Mục đích.** Chứng minh axe-core 0 lỗi nghiêm trọng và thao tác bằng bàn phím ở mọi màn.

**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-06-01…18 · FR-06-029.

**Tiền điều kiện, dữ liệu.** STAGING; ba trình duyệt.

**Các bước.**

1. Chạy axe ở 18 màn, 4 trạng thái (tải, rỗng, lỗi, có dữ liệu).
2. Duyệt bằng Tab, phím tắt UI-06-05.

**Kết quả mong đợi.** 0 lỗi mức serious, critical; thứ tự focus đúng; nhãn có chữ cho mọi trạng thái màu.

**Hậu điều kiện.** Báo cáo axe.
:::

#### TC-06-151 · Câu thông báo lỗi và che DLCN trên giao diện <!--k:ui-notices-->

::: dac-ta
**Mục đích.** Chứng minh 19 câu thông báo của FRS §9.2 hiển thị đúng vị trí và DLCN che mặc định.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-06-02, 03, 05, 07, 08, 09, 14 · ERR-06-005, 007, 010, 013, 023, 024, 027, 029, 030, 031, 033, 035, 038, 039, 040, 044, 107.

**Tiền điều kiện, dữ liệu.** Đã gây từng lỗi ở các ca TS-06-02…25.

**Các bước.**

1. Với từng mã, gây lỗi trên giao diện, chụp màn.
2. Mở màn chi tiết bản ghi vàng khi không có `PERM-09-unmask`.

**Kết quả mong đợi.** Câu và vị trí khớp bảng FRS §9.2 và D03-06-PH06 §5.3, có nút "Sao chép mã truy vết"; `idNumber` che, chỉ hiện khi có quyền và lý do.

**Hậu điều kiện.** Ảnh chụp lưu.
:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Hai phiên 90 phút cho mỗi điều lệ: (1) "Tìm cách hợp nhất sai hai người khác nhau" bằng dữ liệu nhiễu tự nghĩ ra, qua mọi kênh (hàng đợi, thủ công, lô, resolve); (2) "Tìm cách lấy số định danh dạng rõ" từ giao diện, API, log, tệp xuất. Ghi lỗi theo mục 1.6.

### 6.2. Gán nhãn tập kiểm chứng

Hai DS gán nhãn độc lập 300 cặp mẫu phân tầng, tính hệ số đồng thuận Cohen's kappa; chỉ dùng tập có kappa ≥ 0,8 cho nghiệm thu thật (Q06-06, Q06-40).

### 6.3. Diễn tập sự cố

Diễn tập thủ công: lệch đồng bộ quốc gia 8 %, job lô thất bại giữa chừng, mất nhật ký truy cập; vận hành làm theo sổ tay, đo thời gian phát hiện và xử lý.

## 7. Nghiệm thu người dùng

Hệ cũ không có chức năng dữ liệu chủ nên không có nghiệm thu "tương đương hệ cũ". Người quản lý dữ liệu của tỉnh thí điểm tự thực hiện trên UAT; đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng. Bốn `LGC` liên quan gián tiếp (NGSP-003, NGSP-005, DMDC-015, 019) chỉ được kiểm ở chỗ PH-06 nhận dữ liệu (mục 8.2).

| Mã | Việc cần làm | Liên quan hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem tổng quan: hàng đợi, tỷ lệ tự động, cảnh báo | — | Bảy thẻ chỉ số đúng, bấm vào ra danh sách đã lọc | FR-06-055 | TS-06-26 |
| UAT-02 | Xử lý một mục hàng đợi: so sánh và quyết định | — | Quyết định trong 60 giây, lý do ≥ 20 ký tự | FR-06-029, 030 | TS-06-13 |
| UAT-03 | Hợp nhất hai bản ghi và hoàn tác | — | Làm được, thấy lịch sử, hoàn tác khôi phục | FR-06-037, 039 | TS-06-18, 20 |
| UAT-04 | Xem nguồn gốc từng thuộc tính của một công dân | LGC-NGSP-003 | Thấy nguồn từng thuộc tính, dữ liệu BHXH qua PH-14 | FR-06-043 | TS-06-16 |
| UAT-05 | Xem dữ liệu doanh nghiệp từ đăng ký kinh doanh | LGC-NGSP-005 | Tổ chức gom theo MST, nguồn `QG-DKDN` | FR-06-046, 053 | TS-06-21, 25 |
| UAT-06 | Nạp tệp lô, xem trước, xác nhận | LGC-DMDC-015 | Báo cáo lỗi theo dòng, địa chỉ chuẩn hóa theo mã ĐVHC hiện hành | FR-06-013, 015 | TS-06-06, 07 |
| UAT-07 | Xử lý lệch đồng bộ quốc gia | — | Danh sách lệch, giải quyết bốn cách, cảnh báo tạm dừng | FR-06-053, 054 | TS-06-25 |
| UAT-08 | Tiếp nhận yêu cầu của chủ thể dữ liệu | — | Báo cáo đúng hạn, sửa tại nguồn | FR-06-058 | TS-06-27 |

: Kịch bản nghiệm thu UAT-01…08 theo vai trò

## 8. Ma trận truy vết

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-06. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph06/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | Dương | Âm | Ca khác | Đạt |
|---|---|---|---|---|---|---|
| FR-06-001 | Liệt kê và xem domain dữ liệu chủ | M | 001 | 121, 126 | — | Có |
| FR-06-002 | Soạn mô hình domain với thuộc tính có kiểu | M | 004 | 005, 126 | 132 | Có |
| FR-06-003 | Khai báo khóa định danh và quy tắc kiểm tra | M | 006 | 007, 126 | 133 | Có |
| FR-06-004 | Gán phân loại dữ liệu cho thuộc tính theo PH-09 | M | 008 | 009, 126 | 129 | Có |
| FR-06-005 | Quản lý phiên bản mô hình và kiểm tra tương thích | S | 010 | 011, 126 | — | Có |
| FR-06-006 | Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain | M | 012, 014 | 009, 013, 014, 126, 127 | 132 | Có |
| FR-06-007 | Nạp gói domain nền CITIZEN, ORGANIZATION, ADDRESS | M | 002 | 003, 126 | — | Có |
| FR-06-008 | Đăng ký nguồn dữ liệu chủ gắn HTTT | M | 015, 019 | 016, 019, 126 | — | Có |
| FR-06-009 | Khai báo mức tin cậy và thứ tự ưu tiên nguồn có phê duyệ | M | 017 | 018, 121, 126, 127 | — | Có |
| FR-06-010 | Nạp bản ghi ứng viên qua API | M | 020, 022 | 021, 022, 126, 128 | — | Có |
| FR-06-011 | Nạp bản ghi ứng viên qua luồng PH-04 | M | 023 | 023, 126 | — | Có |
| FR-06-012 | Nạp bản ghi ứng viên qua sự kiện PH-10 | S | 024 | 024, 126 | — | Có |
| FR-06-013 | Nạp tệp lô có xem trước | M | 025 | 026, 126 | — | Có |
| FR-06-014 | Chuẩn hóa họ tên, ngày, số định danh | M | 027, 028 | 028, 126 | 145 | Có |
| FR-06-015 | Chuẩn hóa địa chỉ theo ĐVHC của PH-07 | M | 029 | 029, 126 | 145 | Có |
| FR-06-016 | Chống trùng, thứ tự phiên bản nguồn và xóa từ nguồn | M | 022, 030, 031 | 022, 030, 126 | — | Có |
| FR-06-017 | Xem bản ghi ứng viên và xử lý ứng viên lỗi | M | 032 | 032, 122, 126 | — | Có |
| FR-06-018 | Quản lý bộ quy tắc đối sánh có phiên bản | M | 033 | 034, 121, 126, 127 | — | Có |
| FR-06-019 | Cấu hình khóa gom nhóm và theo dõi hiệu quả | M | 035 | 126 | 143 | Có |
| FR-06-020 | Đối sánh xác định theo khóa định danh | M | 041 | 042, 043, 126 | 142 | Có |
| FR-06-021 | Đối sánh xác suất trực tuyến | M | 044 | 043, 045, 046, 050, 081, 126 | 140, 144, 147 | Có |
| FR-06-022 | Chạy job đối sánh theo lô bằng Splink | M | 051, 052, 053, 055 | 052, 053, 054, 081, 126 | 056, 138, 141 | Có |
| FR-06-023 | Cấu hình ngưỡng tự hợp nhất, xem xét, khác biệt | M | 036 | 036, 126 | — | Có |
| FR-06-024 | Chạy thử bộ quy tắc trên mẫu | S | 038 | 126 | — | Có |
| FR-06-025 | Quản lý tập nhãn kiểm chứng | M | 037 | 037, 121, 126 | — | Có |
| FR-06-026 | Đo precision, recall và chặn kích hoạt quy tắc kém | M | 039 | 040, 126 | 140 | Có |
| FR-06-027 | Tạo mục hàng đợi và tính mức ưu tiên | M | 057, 065 | 126 | 143 | Có |
| FR-06-028 | Liệt kê, nhận việc và phân công mục hàng đợi | M | 058, 149 | 059, 122, 126 | — | Có |
| FR-06-029 | So sánh cạnh nhau hai bản ghi | M | 061, 149 | 064, 126 | 150 | Có |
| FR-06-030 | Quyết định khớp, không khớp, hoãn | M | 062, 063, 149 | 064, 081, 126 | 132 | Có |
| FR-06-031 | Duyệt bốn mắt hợp nhất rủi ro cao | M | 065, 066, 082 | 067, 082, 126, 127 | — | Có |
| FR-06-032 | Theo dõi SLA, nâng ưu tiên và cảnh báo quá tải | M | 060 | 126 | — | Có |
| FR-06-033 | Cấu hình quy tắc sống sót thuộc tính | M | 068, 069 | 068, 121, 126, 127 | — | Có |
| FR-06-034 | Tạo và cập nhật bản ghi vàng tự động | M | 047, 048, 069 | 049, 126 | 129 | Có |
| FR-06-035 | Xem chi tiết bản ghi vàng | M | 072 | 073, 122, 126 | — | Có |
| FR-06-036 | Sửa tay thuộc tính có lý do | S | 076 | 077, 126 | 132 | Có |
| FR-06-037 | Hợp nhất bản ghi vàng thủ công | M | 080, 082, 149 | 081, 082, 126 | 132 | Có |
| FR-06-038 | Tách bản ghi vàng | M | 083 | 084, 126 | 132 | Có |
| FR-06-039 | Hoàn tác thao tác trên bản ghi vàng | M | 086 | 087, 088, 126, 127 | 132 | Có |
| FR-06-040 | Ngừng và khôi phục bản ghi vàng | M | 078 | 079, 126 | — | Có |
| FR-06-041 | Xem lịch sử phiên bản và so sánh hai phiên bản | M | 074 | 074, 122, 126 | — | Có |
| FR-06-042 | Xem trước tác động và áp lại sống sót hàng loạt | S | 070 | 071, 126, 127 | — | Có |
| FR-06-043 | Truy xuất nguồn gốc từng thuộc tính | M | 047, 075 | 075, 122, 126 | — | Có |
| FR-06-044 | Xem và gỡ liên kết chéo nguồn | M | 085 | 085, 122, 126 | — | Có |
| FR-06-045 | Tra ID nguồn và ID vàng | M | 091 | 091, 123, 126 | — | Có |
| FR-06-046 | Tra cứu bản ghi vàng theo ID hoặc khóa định danh | M | 089 | 090, 123, 126, 128 | — | Có |
| FR-06-047 | Giải quyết bản ghi trực tuyến (resolve) | M | 096, 097 | 098, 099, 123, 126, 128 | 145 | Có |
| FR-06-048 | Tìm kiếm bản ghi vàng theo thuộc tính | M | 092 | 093, 123, 126, 128 | 133 | Có |
| FR-06-049 | Xuất dữ liệu chủ có kiểm soát | M | 100, 102 | 101, 123, 126, 127 | 125, 132 | Có |
| FR-06-050 | Phát sự kiện thay đổi bản ghi vàng | M | 103 | 126 | 125, 139 | Có |
| FR-06-051 | Đăng ký nhận cập nhật cho HTTT | S | 104 | 105, 126 | — | Có |
| FR-06-052 | Che dữ liệu theo phân loại và mục đích PH-09 | M | 094 | 090, 126 | — | Có |
| FR-06-053 | Đồng bộ với CSDL tổng hợp quốc gia qua PH-14 | M | 106, 107, 109 | 108, 109, 126 | 111, 132, 139 | Có |
| FR-06-054 | Xử lý danh sách lệch đồng bộ quốc gia | M | 107, 110 | 110, 126 | — | Có |
| FR-06-055 | Dashboard chỉ số dữ liệu chủ | M | 112, 148 | 126 | — | Có |
| FR-06-056 | Lịch job, chạy lại và hủy job | M | 113 | 113, 126, 130 | — | Có |
| FR-06-057 | Nhật ký xử lý và nhật ký truy cập | M | 114 | 123, 126 | 131 | Có |
| FR-06-058 | Tiếp nhận và xử lý yêu cầu của chủ thể dữ liệu | M | 115, 116, 117 | 118, 123, 126 | — | Có |
| FR-06-059 | Chính sách lưu giữ và dọn dữ liệu | M | 119 | 119, 121, 126 | — | Có |
| FR-06-060 | Tham số phân hệ theo tenant | M | 120 | 120, 121, 126 | — | Có |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

Hệ cũ không có chức năng dữ liệu chủ; bốn mục `LGC` dưới do PH-14 và PH-07 làm chính, PH-06 chỉ dùng dữ liệu. Ca ở cột "TC" kiểm chỗ PH-06 nhận dữ liệu đó, không kiểm chức năng của hệ cũ (FRS mục 11.1).

| LGC | FR của PH-06 | TC | UAT |
|---|---|---|---|
| LGC-NGSP-003 | 008, 045, 046 | 015, 019, 089, 091 | UAT-04 |
| LGC-NGSP-005 | 007, 053, 054 | 002, 106, 107, 109, 110 | UAT-05 |
| LGC-DMDC-015 | 015 | 029 | UAT-06 |
| LGC-DMDC-019 | 015 | 029 | — |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Quy tắc nghiệp vụ → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-06-001 | 006, 007, 027, 028, 041, 042, 096, 142 |
| BR-06-002 | 044, 045, 057, 060, 097 |
| BR-06-003 | 017, 018, 047, 068, 069, 106 |
| BR-06-004 | 013, 017, 018, 068, 070, 127 |
| BR-06-005 | 049, 056, 070, 074, 080, 086, 146 |
| BR-06-006 | 034, 043, 064, 081, 144 |
| BR-06-007 | 014, 031, 078 |
| BR-06-008 | 032, 062, 064, 077, 132 |
| BR-06-009 | 030, 047, 069, 072, 075 |
| BR-06-010 | 032, 061, 072, 073, 089, 095, 096, 131 |
| BR-06-011 | 108 |
| BR-06-012 | 103, 125, 129, 132 |
| BR-06-013 | 092, 093, 102, 114 |
| BR-06-014 | 075, 076, 110, 116 |
| BR-06-015 | 028, 046, 144 |
| BR-06-016 | 002, 008, 009, 035, 051, 094, 129 |
| BR-06-017 | 010, 011, 012 |
| BR-06-018 | 031, 047, 085, 124 |
| BR-06-019 | 057, 062, 065, 066, 082, 127 |
| BR-06-020 | 036, 120 |
| BR-06-021 | 039, 040, 140 |
| BR-06-022 | 053, 120 |
| BR-06-023 | 050, 054, 055, 056, 063, 083, 085 |
| BR-06-024 | 086, 088, 127 |
| BR-06-025 | 077, 109, 110, 116 |
| BR-06-026 | 061, 072, 089, 090, 094, 102, 104, 117 |
| BR-06-027 | 100, 101, 127 |
| BR-06-028 | 020, 022, 030 |
| BR-06-029 | 022, 030, 069 |
| BR-06-030 | 115, 118 |
| BR-06-031 | 114, 119 |
| BR-06-032 | 016, 106, 111 |
| BR-06-033 | 029 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

Mã `ERR-06-101…114` là lỗi nền (job, đồng bộ), kiểm ở trạng thái job, nhật ký, cảnh báo thay cho mã HTTP.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-06-001 | 073, 074, 075, 121, 122, 123 |
| ERR-06-002 | 003, 005, 007, 016, 037 |
| ERR-06-003 | 005, 007, 016, 034, 037, 075, 091, 099 |
| ERR-06-004 | 005, 011, 077 |
| ERR-06-005 | 013, 018, 040, 067, 068, 071, 088, 101, 105, 127 (+1) |
| ERR-06-006 | 003, 014, 037, 079, 085, 105, 113 |
| ERR-06-007 | 013, 032, 064, 077, 079, 081, 084, 118, 151 |
| ERR-06-008 | 011, 036 |
| ERR-06-009 | 007 |
| ERR-06-010 | 009, 151 |
| ERR-06-011 | 014 |
| ERR-06-012 | 016 |
| ERR-06-013 | 018, 068, 151 |
| ERR-06-014 | 019, 021, 023, 128 |
| ERR-06-015 | 022 |
| ERR-06-016 | 021 |
| ERR-06-017 | 021 |
| ERR-06-018 | 021, 026 |
| ERR-06-019 | 026 |
| ERR-06-020 | 029 |
| ERR-06-021 | 009, 029, 145 |
| ERR-06-022 | 018, 034, 068 |
| ERR-06-023 | 036, 151 |
| ERR-06-024 | 040, 151 |
| ERR-06-025 | 052, 071 |
| ERR-06-026 | 037 |
| ERR-06-027 | 059, 151 |
| ERR-06-028 | 059, 126 |
| ERR-06-029 | 043, 064, 081, 151 |
| ERR-06-030 | 064, 151 |
| ERR-06-031 | 067, 077, 082, 085, 151 |
| ERR-06-032 | 084 |
| ERR-06-033 | 087, 151 |
| ERR-06-034 | 088 |
| ERR-06-035 | 077, 110, 151 |
| ERR-06-036 | 079 |
| ERR-06-037 | 090, 099, 128 |
| ERR-06-038 | 093, 151 |
| ERR-06-039 | 073, 095, 151 |
| ERR-06-040 | 093, 151 |
| ERR-06-041 | 101 |
| ERR-06-042 | 101 |
| ERR-06-043 | 105 |
| ERR-06-044 | 108, 151 |
| ERR-06-045 | 109 |
| ERR-06-046 | 118 |
| ERR-06-047 | 120 |
| ERR-06-048 | 021, 099 |
| ERR-06-049 | 119 |
| ERR-06-050 | 090, 091, 098, 123 |
| ERR-06-101 | 054 |
| ERR-06-102 | 054 |
| ERR-06-103 | 054, 056 |
| ERR-06-104 | 055 |
| ERR-06-105 | 053 |
| ERR-06-106 | 111 |
| ERR-06-107 | 108, 151 |
| ERR-06-108 | 111 |
| ERR-06-109 | 103, 146 |
| ERR-06-110 | 024 |
| ERR-06-111 | 049 |
| ERR-06-112 | 112 |
| ERR-06-113 | 130 |
| ERR-06-114 | 119 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-06-001 | 089, 134 |
| NFR-06-002 | 096, 135 |
| NFR-06-003 | 044, 136 |
| NFR-06-004 | 020, 137 |
| NFR-06-005 | 137 |
| NFR-06-006 | 035, 143 |
| NFR-06-007 | 143 |
| NFR-06-008 | 039, 140, 141 |
| NFR-06-009 | 039, 140, 141 |
| NFR-06-010 | 006, 041, 042, 142 |
| NFR-06-011 | 145 |
| NFR-06-012 | 146 |
| NFR-06-013 | 138 |
| NFR-06-014 | 103, 139, 146 |
| NFR-06-015 | 095, 131 |
| NFR-06-016 | 103, 124, 129, 130 |
| NFR-06-017 | 149 |
| NFR-06-018 | 112, 147, 148 |
| NFR-06-019 | 060, 148 |
| NFR-06-020 | 106, 139 |

: Yêu cầu phi chức năng tới test case

### 8.6. Sự kiện → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-06-01 | 047, 103, 125 |
| EVT-06-02 | 031, 047, 048, 076, 103, 125, 139 |
| EVT-06-03 | 062, 066, 080, 086, 103, 125 |
| EVT-06-04 | 083, 086, 103, 125 |
| EVT-06-05 | 078, 103, 125 |
| EVT-06-06 | 078, 103, 125 |
| EVT-06-07 | 020, 024, 125 |
| EVT-06-08 | 057, 097, 125 |
| EVT-06-09 | 051, 125 |
| EVT-06-10 | 012, 125 |
| EVT-06-11 | 039, 125 |
| EVT-06-12 | 107, 125 |
| EVT-06-13 | 108, 125 |
| EVT-06-14 | 085, 125 |
| EVT-06-15 | 076, 116, 125 |

: Sự kiện tới test case

### 8.7. API → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ api này.

| Mã | Test case |
|---|---|
| API-06-001 | 001, 124, 133 |
| API-06-002 | 001, 121, 133 |
| API-06-003 | 004, 005, 133 |
| API-06-004 | 010, 121, 133 |
| API-06-005 | 004, 010, 133 |
| API-06-006 | 004, 005, 007, 008, 011, 133 |
| API-06-007 | 010, 133 |
| API-06-008 | 009, 012, 013, 133 |
| API-06-009 | 012, 013, 133 |
| API-06-010 | 013, 133 |
| API-06-011 | 014, 133 |
| API-06-012 | 002, 003, 133 |
| API-06-013 | 006, 007, 133 |
| API-06-014 | 015, 133 |
| API-06-015 | 015, 016, 133 |
| API-06-016 | 015, 024, 133 |
| API-06-017 | 019, 133 |
| API-06-018 | 017, 121, 133 |
| API-06-019 | 017, 133 |
| API-06-020 | 017, 133 |
| API-06-021 | 019, 020, 021, 030, 133, 137 |
| API-06-022 | 023, 133 |
| API-06-023 | 025, 026, 133 |
| API-06-024 | 025, 026, 133 |
| API-06-025 | 025, 133 |
| API-06-026 | 032, 122, 133 |
| API-06-027 | 032, 122, 133 |
| API-06-028 | 032, 133 |
| API-06-029 | 027, 028, 133 |
| API-06-030 | 033, 121, 133 |
| API-06-031 | 033, 133 |
| API-06-032 | 033, 034, 036, 133 |
| API-06-033 | 038, 133 |
| API-06-034 | 039, 040, 133 |
| API-06-035 | 039, 040, 133 |
| API-06-036 | 035, 133 |
| API-06-037 | 037, 121, 133 |
| API-06-038 | 037, 133 |
| API-06-039 | 037, 133 |
| API-06-040 | 133 |
| API-06-041 | 113, 133 |
| API-06-042 | 051, 052, 133 |
| API-06-043 | 051, 133 |
| API-06-044 | 053, 113, 133 |
| API-06-045 | 057, 058, 122, 133 |
| API-06-046 | 061, 122, 133 |
| API-06-047 | 058, 059, 133 |
| API-06-048 | 062, 063, 064, 133 |
| API-06-049 | 066, 067, 133 |
| API-06-050 | 060, 133 |
| API-06-051 | 068, 121, 133 |
| API-06-052 | 068, 133 |
| API-06-053 | 068, 133 |
| API-06-054 | 070, 133 |
| API-06-055 | 070, 071, 133 |
| API-06-056 | 072, 089, 094, 122, 133, 134 |
| API-06-057 | 076, 077, 133 |
| API-06-058 | 080, 081, 082, 133 |
| API-06-059 | 083, 084, 133 |
| API-06-060 | 086, 087, 088, 122, 133 |
| API-06-061 | 066, 082, 088, 122, 133 |
| API-06-062 | 078, 079, 133 |
| API-06-063 | 074, 122, 133 |
| API-06-064 | 074, 133 |
| API-06-065 | 075, 122, 133 |
| API-06-066 | 085, 122, 133 |
| API-06-067 | 085, 133 |
| API-06-068 | 091, 123, 133 |
| API-06-069 | 091, 123, 133 |
| API-06-070 | 089, 090, 123, 133, 134 |
| API-06-071 | 041, 044, 045, 046, 050, 096, 097, 098, 099, 123 (+3) |
| API-06-072 | 092, 093, 094, 123, 133 |
| API-06-073 | 100, 101, 102, 133 |
| API-06-074 | 100, 123, 133 |
| API-06-075 | 100, 101, 133 |
| API-06-076 | 100, 101, 123, 133 |
| API-06-077 | 104, 133 |
| API-06-078 | 104, 105, 133 |
| API-06-079 | 104, 105, 133 |
| API-06-080 | 106, 133 |
| API-06-081 | 107, 133 |
| API-06-082 | 109, 133 |
| API-06-083 | 107, 133 |
| API-06-084 | 110, 133 |
| API-06-085 | 112, 133 |
| API-06-086 | 113, 133 |
| API-06-087 | 113, 133 |
| API-06-088 | 114, 123, 133 |
| API-06-089 | 114, 123, 133 |
| API-06-090 | 115, 118, 133 |
| API-06-091 | 115, 123, 133 |
| API-06-092 | 115, 116, 117, 118, 133 |
| API-06-093 | 119, 121, 133 |
| API-06-094 | 119, 133 |
| API-06-095 | 120, 121, 133 |
| API-06-096 | 120, 133 |

: API tới test case

### 8.8. Màn hình → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-06 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-06-01 | 060, 112, 147, 150 |
| UI-06-02 | 092, 150, 151 |
| UI-06-03 | 072, 075, 094, 150, 151 |
| UI-06-04 | 058, 060, 149, 150 |
| UI-06-05 | 043, 059, 061, 067, 149, 150, 151 |
| UI-06-06 | 080, 083, 149, 150 |
| UI-06-07 | 001, 002, 004, 006, 008, 010, 150, 151 |
| UI-06-08 | 015, 017, 150, 151 |
| UI-06-09 | 033, 035, 036, 038, 150, 151 |
| UI-06-10 | 150 |
| UI-06-11 | 025, 027, 028, 029, 150 |
| UI-06-12 | 150 |
| UI-06-13 | 037, 150 |
| UI-06-14 | 106, 107, 108, 150, 151 |
| UI-06-15 | 100, 104, 150 |
| UI-06-16 | 115, 150 |
| UI-06-17 | 119, 150 |
| UI-06-18 | 114, 150 |

: Màn hình tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Ca UT, IT, API nằm trong `dh-data/src/test/java/vn/datahub/data/mdm/` theo gói con `domain`, `ingest`, `match`, `steward`, `golden`, `serve`, `sync`; ca JOB trong `mdm-splink/tests/`; ca E2E trong `dh-console/e2e/du-lieu-chu/`; bộ sinh dữ liệu và `eval_accuracy.py` trong `ph06/seed/`. Mỗi ca gắn thẻ `@TC-06-nnn` để báo cáo gom về `.xlsx`.

### 9.2. Mẫu ca độ chính xác

Mẫu tính precision và recall trên tập nhãn.

```python
def test_precision_recall(labelled_pairs, resolve):
    tp = fp = fn = 0
    for a, b, label in labelled_pairs:            # F-LBL 12.000 cặp
        out = resolve(a, b)                       # vùng MATCH hay không
        tp += out == "MATCH" and label == "MATCH"
        fp += out == "MATCH" and label == "NO_MATCH"
        fn += out != "MATCH" and label == "MATCH"
    assert tp / (tp + fp) >= 0.999 and tp / (tp + fn) >= 0.98
```

### 9.3. Mẫu ca bất biến khác định danh

Mẫu tham số hóa qua năm đường hợp nhất.

```java
@ParameterizedTest @EnumSource(MergePath.class)   // MANUAL, STEWARD, BATCH, ONLINE, APPROVAL
void khongHopNhatKhacCccd(MergePath path) {
    var r = path.attempt(golden("001090000101"), golden("001090000202"));
    assertThat(r.error()).isEqualTo("ERR-06-029");
}
```

### 9.4. Mẫu ca quét canary

Ca `sec-encrypt` đặt `DH-CANARY-sec` vào thuộc tính `SENSITIVE`, chạy toàn bộ luồng nạp, hợp nhất, xuất, rồi `grep` trong dump CSDL, log, topic, tệp xuất; kỳ vọng 0 kết quả.

### 9.5. Sinh ma trận, Gherkin, bảng tính

Chuỗi lệnh dưới chạy từ `05-kiem-thu/test-case/`.

| Lệnh | Kết quả |
|---|---|
| `python3 ph06/tools/number_tcs.py` | Cấp số `TC-06-nnn`, thay `[[tc:khóa]]` |
| `python3 ph06/tools/fill_doc.py` | Ghi bảng 3.1, số kịch bản, số ca và mục 8; in ra stderr FR, BR, ERR, NFR chưa có ca |
| `python3 ph06/tools/gen_gherkin.py` | `ph06/gherkin/ts-06-nn.feature`, `uat-du-lieu-chu.feature` |
| `python3 ph06/tools/gen_xlsx.py` | `D05-02-PH06-test-case.xlsx` theo mẫu nghiệm thu |
| `python3 ph06/tools/check_refs.py` | Đối chiếu mã trong tập với FRS, UC, màn hình |

: Chuỗi công cụ sinh phần tự động

### 9.6. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối 12 tiêu chí ở FRS §14 với ca chứng minh.

| Tiêu chí FRS §14 | Ca |
|---|---|
| 1. Mọi FR mức M có ca dương và ca âm; rò rỉ chéo tenant | mục 8.1; TS-06-29 |
| 2. Precision, recall, tỷ lệ tự động | TS-06-33 |
| 3. Ba nguồn một bản ghi vàng | TC-06-047 |
| 4. Khác CCCD không hợp nhất | TC-06-081, TC-06-043 |
| 5. Hợp nhất, tách, hoàn tác | TC-06-086 |
| 6. Dừng nhật ký truy cập | TC-06-095, TC-06-131 |
| 7. Không lộ giá trị `SENSITIVE` | TC-06-129, TC-06-103 |
| 8. Lệch 8 % tạm dừng | TC-06-108 |
| 9. Job lô 1,2 triệu | TC-06-138, TC-06-056 |
| 10. NFR-06-001, 003, 004 | TS-06-32 |
| 11, 12. Văn bản ưu tiên nguồn, quy trình khiếu nại | TC-06-017, TC-06-115 |

: Đối chiếu tiêu chí chấp nhận cấp phân hệ với ca kiểm thử

## 10. Đề nghị bổ sung cho FRS và câu hỏi mở

### 10.1. Đề nghị bổ sung cho FRS

Những chỗ tập kiểm thử cần mà FRS chưa có.

| Mã | Đề nghị |
|---|---|
| ĐN-TC-01 | Bổ sung mã lỗi nền cho thiếu quyền và chưa xác thực (hiện ca dùng 403-PQ, 401-XT) và thêm mã cho "nhãn không hợp lệ" thay vì dùng ERR-06-003 |
| ĐN-TC-02 | FR-06-003: nêu cách xử lý `CMND_9` khi `deterministic = true` (ca idkey-neg giả định ERR-06-003) |
| ĐN-TC-03 | FR-06-030: chốt "sửa quyết định trong 24 giờ" (ĐN-UC-01); chưa có ca |
| ĐN-TC-04 | FR-06-026: nêu luồng tự tắt tự hợp nhất khi đánh giá tháng không đạt (ĐN-UC-07), ca eval-fail giả định |
| ĐN-TC-05 | FR-06-045: nêu giới hạn tra lô (ca xref-lookup giả định 1.000 cặp) |
| ĐN-TC-06 | FR-06-058: thêm gỡ hạn chế xử lý (ĐN-UC-05) |
| ĐN-TC-07 | §8.1: thêm NFR đo thời gian sửa quyết định hàng đợi và định nghĩa vùng "MATCH" cho precision (ca acc-pr-online) |

: Đề nghị bổ sung cho FRS

### 10.2. Câu hỏi mở

> **Câu hỏi mở Q06-40:** Tập nhãn nghiệm thu 10.000 cặp lấy từ dữ liệu thật của T01 hay bộ sinh giả; đến khi có câu trả lời, ca ACC dùng F-LBL 12.000 cặp giả định (nhiễu 8 %, 1.500 cặp khó) và hệ số đồng thuận kappa ≥ 0,8.

> **Câu hỏi mở Q06-41:** Ngưỡng hiệu năng NFR-06-013 (≤ 2 giờ cho 1,2 triệu bản ghi) dựa số đo công bố của Splink; cần đo thật trên Job 8 vCPU, 32 GB của hạ tầng tỉnh trước khi chốt.

> **Câu hỏi mở Q06-42:** Môi trường thử PH-14 (CSDL tổng hợp quốc gia) có sẵn cho kiểm thử không; hiện dùng WireMock `nat-sim` với kịch bản lệch 2 % và 8 %.

> **Câu hỏi mở Q06-43:** Thuật toán chữ số kiểm tra MST và cấu trúc CCCD dùng để sinh số giả theo Q06-09; cần đối chiếu văn bản hiện hành trước khi khóa bộ dữ liệu.

> **Câu hỏi mở Q06-44:** Có kiểm thử xâm nhập độc lập riêng cho API tìm kiếm và xuất (nguy cơ lấy dữ liệu hàng loạt) không, ngoài ZAP và quét canary.

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-26 | Bản đầu: kịch bản TS-06-01…35, test case TC-06, ma trận truy vết, Gherkin, bảng tính |

: Lịch sử phiên bản
