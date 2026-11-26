---
ma_tai_lieu: D05-02-PH14
ten: Kịch bản và test case phân hệ PH-14 Kết nối quốc gia
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-14
mo_ta: Kịch bản và test case của phân hệ Kết nối quốc gia, chạy được trên SIT với NDXP giả lập, kèm UAT tương đương kết nối NGSP cũ và ma trận truy vết FR, BR, ERR, NFR.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH14 FRS; D02-04-PH14 Use case; D03-02-PH14 SDD; D03-04-PH14 API; D03-06-PH14 Màn hình
---

# D05-02-PH14 · Kịch bản và test case Kết nối quốc gia

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-14 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH14 (57 FR, 37 BR, 26 NFR, 71 mã lỗi).
- Không mất chức năng kết nối quốc gia của hệ cũ: tư pháp, hộ tịch, bảo hiểm xã hội, hồ sơ cấp mã ĐVQHNS, đăng ký doanh nghiệp, văn bản quy phạm pháp luật, danh mục dùng chung và lấy token (LGC-NGSP-001…008, LGC-DMDC-019).
- Không có đường nào để thông tin xác thực với nền tảng quốc gia, khóa riêng chữ ký số hay dữ liệu cá nhân lộ ra ngoài; không có lượt gọi nào ra quốc gia mà thiếu mục đích, nhật ký khai thác và chữ ký khi dịch vụ yêu cầu.

**Phạm vi.** Gồm <!--gen:so-ts-->37<!--/gen--> kịch bản (TS-14-01…37) với <!--gen:so-tc-->97 (TC-14-001…097; 69 ca P1)<!--/gen--> test case và 10 kịch bản nghiệm thu người dùng (UAT-01…10). Mỗi FR mức M có ít nhất một ca dương và một ca âm; mọi API, màn hình, use case và mã lỗi của phân hệ có ít nhất một ca. Ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph14/tools/gen_matrix.py`. Nền tảng quốc gia được thay bằng bộ giả lập (WireMock REST và SOAP có ký, có trễ, có ngắt mạch); kiểm thử với NDXP thật chỉ làm ở UAT khi trung ương cấp môi trường thử (Q14-40).

**Căn cứ.** Tài liệu cùng bộ PH-14 (FRS D02-03-PH14, use case D02-04-PH14, SDD D03-02-PH14, CSDL D03-03-PH14, API D03-04-PH14, màn hình D03-06-PH14); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; yêu cầu ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP, TCVN 14423:2026; kết nối chia sẻ dữ liệu theo Nghị định 278/2025/NĐ-CP (CMP-LAW-03, CMP-LAW-19); bảo vệ dữ liệu cá nhân theo Luật 91/2025 (CMP-LAW-05).

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- không lộ thông tin xác thực, khóa riêng và dữ liệu cá nhân, kiểm bằng giá trị mồi `DH-CANARY` (TS-14-32);
- cách ly tenant ở API, CSDL (RLS), đệm Valkey, hạn mức và OpenBao (TS-14-33);
- bốn mắt cho bật nền tảng thật, luật định tuyến, hạn mức PROD, kích hoạt chứng thư, tham số bảo mật (TS-14-02, 08, 18, 21, 30, 34);
- mục đích khai thác bắt buộc, từ chối an toàn khi không kiểm tra được (TS-14-10);
- ký số, xác minh chữ ký và xử lý sự cố chữ ký như sự cố an ninh (TS-14-17, 20);
- không đệm dữ liệu `SENSITIVE`, không thử lại thao tác ghi khi kết quả chưa rõ (TS-14-22, 23, 09).

Mã W1 hiện có của PH-14 chưa đủ để chạy các ca này; các ca là tiêu chí nghiệm thu của công việc mới. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT; 5 triệu lượt gọi/ngày) vì chưa có số liệu thật.

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu cho kiểm thử viên và kỹ sư biết cần kiểm tra gì, bằng dữ liệu nào, theo bước nào và thấy kết quả gì, để chạy được ngay trên SIT; cho chủ đầu tư biết điều kiện nghiệm thu so với kết nối quốc gia của hệ cũ.

### 0.2. Phạm vi

Phủ chức năng, API, màn hình, mã lỗi và yêu cầu phi chức năng của PH-14. Không kiểm thử lại phần nghiệp vụ của PH-04 (chuyển đổi ngữ nghĩa, luồng), PH-05 (kết nối PH-05 được dùng như đầu vào), PH-07 (chuyển mã danh mục), PH-09 (che dữ liệu); chỉ kiểm điểm giao tiếp với các phân hệ đó.

### 0.3. Người đọc

Kiểm thử viên, kỹ sư viết mã kiểm thử, cán bộ ATTT (TS-14-32…34), chủ đầu tư (mục 7).

### 0.4. Thuật ngữ và chữ viết tắt

| Thuật ngữ | Giải thích |
|---|---|
| NDXP, NGSP | Nền tảng trao đổi dữ liệu quốc gia (trước đây gọi là NGSP) |
| NDOP | Nền tảng dữ liệu mở quốc gia |
| TC, TS, UAT | Test case (ca), test scenario (kịch bản), nghiệm thu người dùng |
| SIT, UAT, PERF | Môi trường kiểm thử tích hợp, nghiệm thu, hiệu năng (mục 1.3) |
| DLCN | Dữ liệu cá nhân |
| Bốn mắt | Người duyệt khác người đề nghị và người sửa gần nhất, cả hai xác thực nhiều yếu tố |
| Mồi | Giá trị `DH-CANARY-…` cài vào bí mật hay dữ liệu cá nhân để dò rò rỉ |

: Thuật ngữ của tài liệu test case PH-14

### 0.5. Tài liệu tham chiếu

D02-03-PH14 (FR, BR, NFR, ERR), D02-04-PH14 (UC), D03-02-PH14 (SDD), D03-04-PH14 (API, ERR), D03-06-PH14 (UI), D02-08 (PERM-14-*), D03-07 (SEC), D05-01, D04-02, D00-03 phần A (LGC-NGSP, LGC-DMDC-019). Mẫu đối chiếu: D05-02-PH05.

### 0.6. Cấu trúc tài liệu

| Chương | Nội dung |
|---|---|
| 1 | Phạm vi, chiến lược, môi trường, tiêu chí vào ra, quy ước |
| 2 | Dữ liệu kiểm thử |
| 3 | Tổng quan 37 kịch bản |
| 4 | Kịch bản và ca chức năng (TS-14-01…31) |
| 5 | Kịch bản phi chức năng và xuyên suốt (TS-14-32…37) |
| 6 | Thủ tục kiểm thử thủ công |
| 7 | Nghiệm thu người dùng tương đương hệ cũ |
| 8 | Ma trận truy vết |
| 9 | Tự động hóa và tệp đi kèm |

: Cấu trúc tài liệu D05-02-PH14

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

Chương này nêu cái gì được kiểm thử, ở mức nào, trên môi trường nào và khi nào bắt đầu, kết thúc; theo kế hoạch tổng thể D05-01.

### 1.1. Đối tượng kiểm thử

| Thành phần | Nội dung kiểm thử | Kịch bản |
|---|---|---|
| Mặt phẳng điều khiển (`dh-integration`, module `national`) | Nền tảng, dịch vụ, định tuyến, chứng thư, hạn mức, chiều vào, đồng bộ, tham số, chuyển đổi | TS-14-01…08, 18…21, 24…26, 30, 31 |
| Mặt phẳng dữ liệu (`dh-runtime`, hồ sơ `national-gateway`) | Điểm gọi chung, bộ điều hợp, ký, xác minh, đệm, ngắt mạch, chiều vào | TS-14-09…17, 22, 23, 24 |
| Giám sát, nhật ký, đối soát | Tổng quan, giao dịch, nội dung đầy đủ, nhật ký khai thác, bất thường | TS-14-27…29 |
| Giao diện UI-14-01…17 | Hành vi, trạng thái, truy cập | TS-14-37 và các ca `E2E` |
| Xuyên suốt | Bí mật, tenant, quyền, hiệu năng, chịu lỗi | TS-14-32…36 |

: Đối tượng kiểm thử

### 1.2. Mức kiểm thử

| Mức | Công cụ | Ca |
|---|---|---|
| Đơn vị (ký, băm, luật định tuyến, bộ đếm hạn mức, máy trạng thái) | JUnit 5 | Chạy ở CI-3; các ca `API` dùng chung dữ liệu |
| Tích hợp, API | REST Assured, Testcontainers (PostgreSQL 16 RLS, Valkey, Kafka, OpenBao, Keycloak, OPA), WireMock giả lập NDXP | Phần lớn ca mục 4 |
| Hợp đồng | Schemathesis theo OpenAPI, Apicurio BACKWARD | NFR-14-022 |
| Giao diện | Playwright, axe-core | Ca `E2E`, TS-14-37 |
| Tải, bền | Gatling, k6, JMH | TS-14-35 |
| Chịu lỗi | Chaos Mesh (dừng OpenBao, Valkey, NDXP giả lập) | TS-14-36 |
| Thủ công | Kiểm thử khám phá, diễn tập, UAT | Mục 6, 7 |

: Mức kiểm thử và công cụ

### 1.3. Môi trường kiểm thử

| Môi trường | Dùng cho | Ghi chú |
|---|---|---|
| CI | Đơn vị, tích hợp có Testcontainers | Mỗi lần đẩy mã |
| SIT | Toàn bộ ca mục 4, 5 | Ba bản sao `national-gateway` trên hai nút; NDXP giả lập `sim-ndxp` |
| PERF | TS-14-35 | Tenant `T90`; hồ sơ tỉnh vừa theo GĐ-07 (200 HTTT, 300 lượt/giây cao điểm) |
| UAT | Mục 7 | Dữ liệu cấu hình nhập từ hệ cũ; NDXP thử của trung ương nếu có (Q14-40) |

: Môi trường kiểm thử

Giả lập `sim-ndxp` chạy các chế độ: `OK` (phản hồi hợp lệ, có ký), `SLOW` (trễ cấu hình được), `ERR5XX`, `BIZ404` (lỗi nghiệp vụ), `BADSIG` (chữ ký sai), `BADCHAIN` (chứng thư ngoài chuỗi tin cậy), `OLDTS` (thời điểm ký lệch), `AUTH401` (từ chối thông tin xác thực), `DOWN` (không phản hồi), `QUOTA` (trả hạn mức của trung ương).

### 1.4. Tiêu chí vào và ra

| | Tiêu chí |
|---|---|
| Vào | Bản dựng qua CI-1…CI-5; dữ liệu mục 2 nạp bằng API; OpenBao, Keycloak, OPA, Valkey sẵn sàng; chứng thư thử do CA thử cấp |
| Ra, SIT | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt; sáu nhóm ca bắt buộc (Tóm tắt) đạt 100 %; không còn lỗi mức Nghiêm trọng hoặc Cao đang mở; mọi FR mức M có ca dương và âm đạt |
| Ra, UAT | 10 kịch bản UAT đạt; chạy song song đạt `14.parallel.match-ratio` trong `14.parallel.min-days` ngày (UAT-09) |

: Tiêu chí vào và ra

### 1.5. Quy ước mã và cách trình bày

Ca viết số tạm là ba dấu thăng sau `TC-14-`, kèm khóa `<!--k:khóa-->`, cấp số bằng `ph14/tools/number_tcs.py`; tham chiếu chéo `[[tc:khóa]]`. Ưu tiên: P1 chặn phát hành, P2 quan trọng, P3 thường. Loại ca: Dương, Âm, Bảo mật, Biên, Hiệu năng, Chịu lỗi, Trợ năng. Tự động hóa: `API`, `E2E`, `k6`, `Chaos`, `Thủ công`. "Mã HTTP" ghi theo RFC 9457; "ERR-14-nnn" so với trường `code` của thân lỗi.

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi ở công cụ quản lý lỗi của dự án với mức Nghiêm trọng, Cao, Trung bình, Thấp; lỗi rò rỉ bí mật, chéo tenant, thiếu ký hoặc thiếu mục đích luôn Nghiêm trọng. Báo cáo ngày trong đợt SIT: số ca đạt, hỏng, chặn theo kịch bản; theo D05-01 §7.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập, nạp bằng `ph14/seed/` qua API (không chèn SQL trực tiếp). Không dùng dữ liệu cá nhân thật; số định danh, mã hồ sơ do bộ sinh dữ liệu tạo ra theo đúng khuôn.

### 2.1. Tenant

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính | Tham số mặc định theo FRS §8.2, trừ ca có ghi khác |
| `T01` | Tỉnh đối chứng rò rỉ | Có nền tảng `ndxp` và dịch vụ `hotich-tra-cuu` **trùng mã** với T68 nhưng khác địa chỉ, hạn mức và cấu hình |
| `T90` | Tenant hiệu năng | 10 nền tảng, 300 dịch vụ, 1.000 luật, 20 chứng thư, 50 điểm cuối |
| `COMMON` | Dịch vụ, nền tảng dùng chung toàn quốc | Chỉ PA ghi; tenant đọc được (BR-14-029) |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

| Mã | Tenant | Vai trò | Mục đích |
|---|---|---|---|
| U-PA | PLATFORM | PA | Quản trị nền tảng, dịch vụ `COMMON` |
| U-T68-TA | T68 | TA | Khai báo nền tảng, hạn mức, tham số, điểm cuối |
| U-T68-IE | T68 | IE | Dịch vụ, đặc tả, luật định tuyến |
| U-T68-IA | T68 | IA | Người duyệt chính |
| U-T68-IA2 | T68 | IA + TA (cố ý cấu hình sai, chỉ có ở SIT) | Kiểm lớp bốn mắt độc lập với tách vai trò; không tạo ở UAT, PROD |
| U-T68-TO | T68 | TO | Vận hành, tạm ngừng, ngắt mạch, đồng bộ |
| U-T68-SO | T68 | SO | Chứng thư, sự cố chữ ký, xem nội dung đầy đủ |
| U-T68-AU | T68 | AU | Tra giao dịch, nhật ký khai thác |
| U-T68-VW | T68 | VW | Chỉ `PERM-14-read` |
| U-T01-TA, U-T01-SO | T01 | TA, SO | Đối chứng rò rỉ |
| S-HT-MC | T68 | Client máy HTTT `HT-MOTCUA` (`azp`), scope `national:invoke` | Gọi API nội bộ |
| S-HT-KHAC | T68 | Client máy HTTT `HT-KHAC`, có scope nhưng chưa được cấp dịch vụ | Ca từ chối |
| S-PH07, S-PH04, S-PH06 | T68 | Tài khoản dịch vụ các phân hệ | Cổng danh mục, luồng chiều vào, dữ liệu chủ |
| S-NDXP-IN | T68 | Nguồn chiều vào có chứng thư mTLS đã đăng ký | Chiều vào |
| S-NDXP-LA | T68 | Nguồn có mTLS hợp lệ nhưng không nằm trong danh sách được phép | Ca từ chối |

: Người dùng và tài khoản máy

Mọi người dùng TA, SO, IA, PA có TOTP thử để kiểm xác thực nhiều yếu tố.

### 2.3. Nền tảng, dịch vụ, chứng thư mẫu

| Mã | Loại, thuộc tính | Trạng thái nạp sẵn | Dùng cho |
|---|---|---|---|
| P-NDXP (`ndxp`) | NDXP, REST + OAuth 2.1, kết nối PH-05 `ndxp-oauth` | `ACTIVE` (T68), môi trường thật | Hầu hết ca |
| P-NDOP (`ndop`) | NDOP, mTLS | `ACTIVE` | Dữ liệu mở |
| P-NEW (`ndxp-moi`) | Chưa có, tạo trong ca | — | Khai báo, duyệt |
| V-LLTP (`lltp-tra-trang-thai`) | Đọc, `ESSENTIAL`, ký `REQUIRED`, không đệm | `ACTIVE` | Tư pháp |
| V-HT (`hotich-tra-cuu`) | Đọc, `NORMAL`, đệm 300 giây, `staleAllowed`, mục `NORMAL` | `ACTIVE` | Đệm, hộ tịch |
| V-HT-DK (`hotich-dang-ky`) | **Ghi**, ký `REQUIRED`, `Idempotency-Key` bắt buộc | `ACTIVE` | Ghi, bất đồng bộ |
| V-BHXH (`bhxh-tra-ho`) | Đọc, DLCN, mục `SENSITIVE`, cần mã thủ tục và mã hồ sơ | `ACTIVE` | BHXH, DLCN |
| V-DVQHNS (`dvqhns-ds-hoso`) | Đọc theo khoảng thời gian, `BACKGROUND` | `ACTIVE` | Phân trang, hoãn theo ưu tiên |
| V-DKKD (`dkkd-moi-nhat`) | Đọc, đệm 600 giây | `ACTIVE` | Đăng ký doanh nghiệp |
| V-VBQPPL (`vbqppl-tim`) | Đọc, đệm 3.600 giây | `ACTIVE` | Văn bản quy phạm |
| V-DMDC (`dmdc-ds`) | Danh mục dùng chung quốc gia | `ACTIVE` | Cổng cho PH-07 |
| V-NEW (`tc-dich-vu-moi`) | Chưa có, tạo trong ca | — | Khai báo dịch vụ |
| K-KY-01 | Chứng thư ký, mục đích `SIGN`, khóa trong OpenBao | `ACTIVE`, còn 300 ngày | Ký |
| K-KY-02 | Chứng thư ký thay thế | `UPLOADED` | Kích hoạt, thay thế |
| K-HET | Chứng thư còn 5 ngày | `EXPIRING` | Cảnh báo hạn |
| K-NDXP-TIN | Chứng thư tin cậy của NDXP giả lập | trong chuỗi tin cậy | Xác minh |
| E-NDXP-IN (`ndxp-vao`) | Điểm cuối chiều vào, nguồn S-NDXP-IN | `ACTIVE`, ánh xạ luồng PH-04 `lg-nhan-tb` | Chiều vào |

: Nền tảng, dịch vụ, chứng thư mẫu

Mọi thông tin xác thực nạp sẵn có dạng `DH-CANARY-{mã}-{uuid}`; hồ sơ DLCN mẫu có CCCD, họ tên, địa chỉ mang mồi `DH-CANARY-PII-…`, để TS-14-32 dò được.

### 2.4. Nguyên tắc dữ liệu

Mỗi ca tạo đối tượng riêng có tiền tố `tc-` và tự dọn; đối tượng nạp sẵn ở mục 2.3 chỉ đọc, trừ ca ghi rõ "phục hồi sau ca". Đồng hồ giả lập (`Clock`) dùng cho ca hết hạn, cửa sổ trượt, chu kỳ hạn mức. Ca đo tải dùng `T90`, không dùng chung `T68`.

## 3. Tổng quan kịch bản kiểm thử

Mỗi kịch bản nhóm các ca cùng mục tiêu. Bảng dưới sinh tự động từ mục 4, 5.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-14-01 | Nền tảng quốc gia: khai báo, liệt kê, chi tiết | Xác nhận khai báo nền tảng gắn đúng kết nối PH-05, mã bất biến, đối tượng tenant khác không lộ | UC-14-01 | 4 |
| TS-14-02 | Bật nền tảng và duyệt bốn mắt | Xác nhận nền tảng chỉ sang `ACTIVE` sau kiểm tra kết nối đạt và người thứ hai duyệt | UC-14-02 | 3 |
| TS-14-03 | Tạm ngừng, tiếp tục, ngừng dùng nền tảng | Xác nhận tạm ngừng có hiệu lực trong 30 giây, mã không dùng lại sau khi ngừng | UC-14-03 | 3 |
| TS-14-04 | Dịch vụ quốc gia: danh sách, khai báo, chi tiết | Xác nhận khai báo dịch vụ có hợp đồng, nhãn đối chiếu, điều kiện kích hoạt và loại cấu hình mâu thuẫn bị chặn | UC-14-04 | 4 |
| TS-14-05 | Đặc tả có phiên bản và phát hiện lệch | Xác nhận nạp, so sánh, kích hoạt đặc tả; thay đổi phá vỡ phải được duyệt | UC-14-05 | 2 |
| TS-14-06 | Đối chiếu danh mục dịch vụ với NDXP | Xác nhận đối chiếu đề xuất đúng bốn nhãn và không tự thay đổi hợp đồng | UC-14-06 | 2 |
| TS-14-07 | Cung cấp lại dịch vụ quốc gia cho HTTT | Xác nhận HTTT chỉ nhận dịch vụ đã cung cấp lại, với trường đúng hợp đồng, không giữ thông tin xác thực quốc gia | UC-14-07 | 2 |
| TS-14-08 | Bảng định tuyến | Xác nhận luật định tuyến cần bốn mắt, mô phỏng đúng, và dự phòng chỉ cho thao tác đọc | UC-14-08 | 2 |
| TS-14-09 | Gọi dịch vụ quốc gia qua điểm gọi chung | Xác nhận HTTT chỉ cần một API của Datahub; lỗi quốc gia được phân loại, che nội dung kỹ thuật; thao tác ghi có `Idempotency-Key` và không thử lại khi kết quả chưa rõ | UC-14-09 | 5 |
| TS-14-10 | Mục đích khai thác và ủy quyền theo mục đích | Xác nhận mọi lượt gọi dịch vụ chứa DLCN có mục đích hợp lệ, mã thủ tục, mã hồ sơ; không kiểm tra được thì từ chối an toàn | UC-14-09, 35 | 2 |
| TS-14-11 | Gọi bất đồng bộ qua hàng chờ | Xác nhận yêu cầu dài hoặc lô đi qua hàng chờ, theo dõi, hủy được trước khi gửi | UC-14-10 | 2 |
| TS-14-12 | Bộ điều hợp tư pháp: lý lịch tư pháp, hộ tịch | Xác nhận không mất chức năng tư pháp của hệ cũ | UC-14-11 | 2 |
| TS-14-13 | Bộ điều hợp bảo hiểm xã hội | Xác nhận tra hộ gia đình, giới hạn thành viên, không đệm DLCN | UC-14-12 | 2 |
| TS-14-14 | Hồ sơ cấp mã ĐVQHNS, đăng ký doanh nghiệp, văn bản quy phạm pháp luật | Xác nhận phân trang tự động có giới hạn, đệm theo loại dữ liệu, hoãn dịch vụ nền khi gần hết hạn mức | UC-14-13, 14 | 2 |
| TS-14-15 | Cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07 | Xác nhận chỉ PH-07 gọi cổng, PH-14 không lưu dữ liệu danh mục | UC-14-15 | 2 |
| TS-14-16 | Token OAuth 2.1, xoay vòng thông tin xác thực | Xác nhận token lấy và làm mới tự động, thông tin xác thực ghi một chiều vào OpenBao, xoay vòng không gián đoạn | UC-14-16, 17 | 3 |
| TS-14-17 | Ký số bản tin và xác minh chữ ký phản hồi | Xác nhận khóa riêng không rời OpenBao, chữ ký sai là sự cố an ninh, không ký được thì không gửi | UC-14-09, 21 | 3 |
| TS-14-18 | Chứng thư số: nạp và kích hoạt | Xác nhận chứng thư chỉ dùng được sau bốn mắt, khớp khóa trong OpenBao và thuộc chuỗi tin cậy | UC-14-18 | 2 |
| TS-14-19 | Theo dõi hạn chứng thư, chuỗi tin cậy, danh sách thu hồi | Xác nhận cảnh báo 60, 30, 7 ngày, chuyển tiếp không gián đoạn, CRL quá hạn xử lý theo chế độ | UC-14-19, 20 | 3 |
| TS-14-20 | Sự cố chữ ký như sự cố an ninh | Xác nhận chữ ký sai ghi sự cố, vượt ngưỡng thì giữ an ninh nền tảng, chỉ SO giải trừ | UC-14-21 | 2 |
| TS-14-21 | Hạn mức do trung ương áp, đếm và phân bổ | Xác nhận hạn mức có căn cứ, đếm chính xác theo cửa sổ, hoãn theo ưu tiên và không gọi ra khi hết | UC-14-22, 23 | 3 |
| TS-14-22 | Đệm phản hồi và dữ liệu quá hạn | Xác nhận đệm theo tenant, không đệm dữ liệu nhạy cảm hoặc thao tác ghi, dữ liệu quá hạn có cờ | UC-14-24 | 2 |
| TS-14-23 | Ngắt mạch và thử lại | Xác nhận ngắt mạch mở khi lỗi quá ngưỡng, thử lại có giới hạn và không thử lại thao tác ghi | UC-14-25 | 2 |
| TS-14-24 | Chiều vào: đăng ký, tiếp nhận, chuyển luồng PH-04 | Xác nhận bản tin từ quốc gia chỉ được xử lý khi xác minh đạt, nguồn được phép, không lặp; tenant xác định từ điểm cuối | UC-14-26, 27 | 4 |
| TS-14-25 | Thông báo thay đổi từ quốc gia | Xác nhận thông báo đổi danh mục hay dịch vụ từ quốc gia sinh đề xuất cập nhật, không tự sửa cấu hình (Đợt 2) | UC-14-28 | 1 |
| TS-14-26 | Đồng bộ: danh mục dịch vụ, dữ liệu chủ, dữ liệu mở | Xác nhận chỉ gửi dịch vụ chia sẻ `PUBLISHED` của đúng tenant, dữ liệu chủ và dữ liệu mở qua kiểm tra PH-07, PH-09 | UC-14-29, 30, 31 | 4 |
| TS-14-27 | Tổng quan và kiểm tra kết nối chủ động | Xác nhận tổng quan phản ánh đúng sức khỏe, phát hiện mất kết nối ≤ 3 phút, giới hạn kiểm tra tay | UC-14-32 | 2 |
| TS-14-28 | Giao dịch, đối soát, xem nội dung đầy đủ, xuất bằng chứng | Xác nhận mọi giao dịch tra được bằng mã đối soát; nội dung đầy đủ chỉ SO xem có lý do và xác thực nhiều yếu tố | UC-14-33, 34 | 3 |
| TS-14-29 | Nhật ký khai thác, cảnh báo bất thường, báo cáo | Xác nhận 100 % lượt gọi có nhật ký khai thác, phát hiện tra cứu hàng loạt | UC-14-35, 36 | 3 |
| TS-14-30 | Tham số phân hệ theo tenant | Xác nhận tham số đúng miền, tham số bảo mật cần người duyệt thứ hai, hiệu lực ≤ 30 giây | UC-14-36 | 2 |
| TS-14-31 | Chuyển đổi từ hệ cũ: nhập cấu hình, chạy song song | Xác nhận nhập đúng cấu hình dịch vụ NGSP cũ, không di trú khóa cũ, chạy song song chỉ cho thao tác đọc | UC-14-37, 38 | 2 |
| TS-14-32 | Không lộ bí mật và dữ liệu cá nhân | Xác nhận thông tin xác thực, khóa riêng và DLCN không xuất hiện ngoài OpenBao và nơi được phép | — | 2 |
| TS-14-33 | Cách ly tenant và RLS | Xác nhận 0 rò rỉ chéo tenant ở API, CSDL, đệm, hạn mức, OpenBao, Kafka | — | 3 |
| TS-14-34 | Phân quyền và tách nhiệm | Xác nhận ma trận quyền PERM-14 đúng ở API và giao diện, tài khoản máy chỉ có scope gọi | — | 2 |
| TS-14-35 | Hiệu năng, tải và quy mô | Xác nhận ngưỡng hiệu năng trên hồ sơ tỉnh vừa (GĐ-07); đo ở PERF với tenant `T90` | — | 5 |
| TS-14-36 | Chịu lỗi và phục hồi | Xác nhận phục hồi khi quốc gia, OpenBao hay một bản sao sự cố, không mất bản tin | — | 3 |
| TS-14-37 | Truy cập, giao diện, truy vết, hợp đồng API | Xác nhận 17 màn đạt WCAG 2.2 AA, mọi giao dịch truy vết được, hợp đồng API tương thích | — | 2 |
| **Tổng** | | | | **97** (69 ca P1) |
<!--/gen-->

: Danh sách kịch bản kiểm thử

### 3.2. Máy trạng thái được kiểm thử

| Đối tượng | Trạng thái | Kịch bản |
|---|---|---|
| Nền tảng quốc gia | `DRAFT → TESTED → PENDING_ACTIVATION → ACTIVE ⇄ SUSPENDED → RETIRED`; `SECURITY_HOLD` | TS-14-01…03, 20 |
| Dịch vụ quốc gia | `DRAFT → ACTIVE ⇄ DEPRECATED → RETIRED` | TS-14-04…07 |
| Chứng thư số | `UPLOADED → PENDING_ACTIVATION → ACTIVE → EXPIRING → EXPIRED`; `SUPERSEDED`, `REVOKED` | TS-14-18, 19 |
| Giao dịch | `RECEIVED → COMPLETED_CACHE, QUOTA_EXCEEDED, SENT → SUCCEEDED, FAILED, TIMEOUT → UNKNOWN_RESULT, SIGNATURE_FAILED` | TS-14-09, 11, 17, 22, 28 |

: Máy trạng thái được kiểm thử

## 4. Kịch bản và test case chức năng

### TS-14-01 · Nền tảng quốc gia: khai báo, liệt kê, chi tiết

**Mục tiêu.** Xác nhận khai báo nền tảng gắn đúng kết nối PH-05, mã bất biến, đối tượng tenant khác không lộ.

**Phủ.** FR-14-001, 002; UC-14-01; API-14-001, 002, 003, 004; UI-14-02, 03; BR-14-025, 029; LGC-NGSP-008.

#### TC-14-001 · Liệt kê nền tảng và mức sức khỏe <!--k:plat-list-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-14-001 · API-14-001, 003 · UI-14-02 · UC-14-01.

**Tiền điều kiện, dữ liệu.** U-T68-VW; P-NDXP, P-NDOP; `COMMON` có một nền tảng mẫu.

**Các bước.**

1. Mở UI-14-02; lọc loại `NDXP`.
2. `GET /platforms?type=NDXP` rồi `GET /platforms/ndxp`.

**Kết quả mong đợi.** `200`, có `ndxp` với `state = ACTIVE`, `health` (`HEALTHY`, `DEGRADED`, `UNHEALTHY`, `UNKNOWN`), nền tảng `COMMON` đọc được; chi tiết không có trường bí mật; U-T68-VW không thấy nút Khai báo.
:::

#### TC-14-002 · Khai báo nền tảng hợp lệ ở trạng thái Nháp <!--k:plat-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-002 · API-14-002, 004 · UI-14-03 · UC-14-01 · BR-14-025 · LGC-NGSP-008.

**Tiền điều kiện, dữ liệu.** U-T68-TA; kết nối PH-05 `ndxp-oauth` (OAuth 2.1) `ACTIVE`; P-NEW chưa có.

**Các bước.**

1. Ở UI-14-03 chọn loại NDXP, mã `ndxp-moi`, địa chỉ mô phỏng, kết nối `ndxp-oauth`, bấm "Tạo".
2. `PATCH /platforms/ndxp-moi` với `If-Match` đổi tên hiển thị.

**Kết quả mong đợi.** Bước 1 `201`, `Location`, `ETag`, `state = DRAFT`; địa chỉ, mã dịch vụ nằm ở cấu hình theo tenant, không ghi cứng. Bước 2 `200`, `ETag` mới. Kiểm toán ghi hai thao tác.
:::

#### TC-14-003 · Khai báo nền tảng sai: trùng mã, kết nối sai loại, tham số sai <!--k:plat-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-002 · API-14-002 · ERR-14-002, 003, 005 · BR-14-025.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `ndxp` đang có; nền tảng `ndxp-cu` đã `RETIRED`; kết nối PH-05 loại `http-basic`.

**Các bước.**

1. `POST /platforms` mã `ndxp`.
2. `POST /platforms` mã `ndxp-cu`.
3. `POST /platforms` cách xác thực OAuth nhưng gắn kết nối `http-basic`; rồi gắn kết nối không tồn tại.
4. `POST /platforms` thiếu `type`.

**Kết quả mong đợi.** Bước 1, 2 trả `409` ERR-14-002 (kể cả đã ngừng dùng); bước 3 `422` ERR-14-005; bước 4 `400` ERR-14-003 kèm danh sách trường lỗi. Không đối tượng nào được tạo.
:::

#### TC-14-004 · Nền tảng của tenant khác trả như không tồn tại <!--k:plat-404-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-001 · API-14-003 · ERR-14-001 · BR-14-029 · NFR-14-024.

**Tiền điều kiện, dữ liệu.** U-T68-TA; `T01` có nền tảng `chi-t01` mà T68 không có.

**Các bước.**

1. U-T68-TA gọi `GET /platforms/khong-co`.
2. U-T68-TA gọi `GET /platforms/chi-t01`.

**Kết quả mong đợi.** Cả hai `404` ERR-14-001, thân giống nhau trừ `traceId`; không có thông tin tenant khác trong nhật ký trả về.
:::

### TS-14-02 · Bật nền tảng và duyệt bốn mắt

**Mục tiêu.** Xác nhận nền tảng chỉ sang `ACTIVE` sau kiểm tra kết nối đạt và người thứ hai duyệt.

**Phủ.** FR-14-003, 047; UC-14-02; API-14-008, 009, 059; UI-14-03, 17; BR-14-022; LGC-NGSP-008.

#### TC-14-005 · Kiểm tra kết nối, gửi duyệt và duyệt bật <!--k:plat-activate-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-003, 047 · API-14-059, 008, 009 · UI-14-03, 17 · UC-14-02 · BR-14-022.

**Tiền điều kiện, dữ liệu.** `ndxp-moi` `DRAFT`; `sim-ndxp` chế độ `OK`; U-T68-TA, U-T68-IA.

**Các bước.**

1. U-T68-TA gọi `POST /platforms/ndxp-moi:probe`; trạng thái sang `TESTED`.
2. `POST /platforms/ndxp-moi:request-activation`.
3. U-T68-IA (đã xác thực lại TOTP) mở "Việc của tôi" ở UI-14-17, `POST …:approve-activation`.

**Kết quả mong đợi.** Sau bước 2 `PENDING_ACTIVATION`; sau bước 3 `ACTIVE`, ghi người đề nghị, người duyệt, thời điểm; sự kiện đổi trạng thái được phát; hàng chờ của IA tự bỏ mục.
:::

#### TC-14-006 · Gửi duyệt khi chưa kiểm tra đạt hoặc đã có yêu cầu chờ <!--k:plat-activate-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-003 · API-14-008 · ERR-14-006, 008, 004.

**Tiền điều kiện, dữ liệu.** `ndxp-moi` `DRAFT`, chưa có kiểm tra đạt trong 24 giờ; sau đó một yêu cầu đang chờ duyệt.

**Các bước.**

1. `POST …:request-activation` khi chưa kiểm tra đạt.
2. Kiểm tra đạt, gửi duyệt; gửi duyệt lần hai.
3. `POST …:approve-activation` lên nền tảng đang `ACTIVE`.

**Kết quả mong đợi.** Bước 1 `422` ERR-14-008; bước 2 lần hai `409` ERR-14-006; bước 3 `409` ERR-14-004.
:::

#### TC-14-007 · Bốn mắt: người duyệt trùng người đề nghị hoặc người sửa <!--k:plat-four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-003 · API-14-009 · ERR-14-007 · BR-14-022 · PERM-14-approve.

**Tiền điều kiện, dữ liệu.** U-T68-IA2 (vừa IA vừa TA); yêu cầu bật do U-T68-IA2 đề nghị; yêu cầu khác do U-T68-TA sửa lần cuối.

**Các bước.**

1. U-T68-IA2 duyệt yêu cầu chính mình đề nghị.
2. U-T68-IA2 duyệt yêu cầu mà U-T68-TA đề nghị nhưng U-T68-IA2 sửa gần nhất.
3. U-T68-IA duyệt khi chưa xác thực lại nhiều yếu tố.

**Kết quả mong đợi.** Bước 1, 2 `403` ERR-14-007, nền tảng vẫn `PENDING_ACTIVATION`; bước 3 bị từ chối yêu cầu xác thực lại theo FR-00. Kiểm toán ghi cả lần bị từ chối.
:::

### TS-14-03 · Tạm ngừng, tiếp tục, ngừng dùng nền tảng

**Mục tiêu.** Xác nhận tạm ngừng có hiệu lực trong 30 giây, mã không dùng lại sau khi ngừng.

**Phủ.** FR-14-003; UC-14-03; API-14-005, 006, 007; UI-14-02, 03; BR-14-032; NFR-14-017.

#### TC-14-008 · Tạm ngừng có hiệu lực ≤ 30 giây, lượt đang chạy kết thúc <!--k:plat-suspend-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, k6.

**Truy vết.** FR-14-003 · API-14-005, 006, 075 · ERR-14-117 · BR-14-032 · NFR-14-017 · UC-14-03.

**Tiền điều kiện, dữ liệu.** `ndxp` `ACTIVE`; `sim-ndxp` chế độ `SLOW` 10 giây; U-T68-TO; S-HT-MC gọi `hotich-tra-cuu` liên tục 20 lượt/giây.

**Các bước.**

1. Khởi động một lượt gọi dài 10 giây, rồi `POST /platforms/ndxp:suspend` kèm lý do.
2. Đo thời gian tới khi lượt mới bị từ chối.
3. `POST …:resume`.

**Kết quả mong đợi.** Lượt đang chạy hoàn tất; lượt mới từ bước 1 + 30 giây trả `503` ERR-14-117; `resume` đưa về `ACTIVE`, lượt mới gọi được trong 30 giây.
:::

#### TC-14-009 · Ngừng dùng nền tảng và không dùng lại mã <!--k:plat-retire-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-003 · API-14-007 · ERR-14-002, 117 · BR-14-032.

**Tiền điều kiện, dữ liệu.** `ndxp-moi` `ACTIVE`, không có lượt đang chạy; U-T68-TO.

**Các bước.**

1. `POST /platforms/ndxp-moi:retire` kèm lý do.
2. Gọi dịch vụ thuộc nền tảng đó.
3. `POST /platforms` với mã `ndxp-moi`.

**Kết quả mong đợi.** `RETIRED`; bước 2 `503` ERR-14-117; bước 3 `409` ERR-14-002.
:::

#### TC-14-010 · Thao tác sai trạng thái hoặc không có quyền <!--k:plat-state-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-003 · API-14-005, 006, 007 · ERR-14-004 · PERM-14-operate.

**Tiền điều kiện, dữ liệu.** `ndxp` `ACTIVE`; U-T68-VW; U-T68-TO.

**Các bước.**

1. U-T68-TO `:resume` lên nền tảng đang `ACTIVE`.
2. U-T68-VW `:suspend`.
3. U-T68-TO `:suspend` thiếu lý do.

**Kết quả mong đợi.** Bước 1 `409` ERR-14-004; bước 2 `403`; bước 3 `400` ERR-14-003.
:::

### TS-14-04 · Dịch vụ quốc gia: danh sách, khai báo, chi tiết

**Mục tiêu.** Xác nhận khai báo dịch vụ có hợp đồng, nhãn đối chiếu, điều kiện kích hoạt và loại cấu hình mâu thuẫn bị chặn.

**Phủ.** FR-14-004, 005, 006; UC-14-04; API-14-010, 011, 012, 013; UI-14-04, 05; BR-14-014, 024.

#### TC-14-011 · Tìm, lọc danh mục dịch vụ và xem chi tiết hợp đồng <!--k:svc-list-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-14-004, 006 · API-14-010, 012 · UI-14-04, 05 · UC-14-04.

**Tiền điều kiện, dữ liệu.** U-T68-VW; V-LLTP, V-HT, V-BHXH.

**Các bước.**

1. Ở UI-14-04 tìm `hotich`, lọc nhóm `HO_TICH`, trang 1, 20 dòng.
2. `GET /services/lltp-tra-trang-thai`.

**Kết quả mong đợi.** Danh sách đúng, phân trang `page`/`size`, có nhãn đối chiếu và chỉ báo đã cung cấp lại; chi tiết có `purposeRequired`, `signingMode`, `cacheable`, `priority`, đặc tả `ACTIVE`; không trường bí mật.
:::

#### TC-14-012 · Khai báo dịch vụ và kích hoạt khi đủ điều kiện <!--k:svc-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-005 · API-14-011, 013 · UI-14-05 · UC-14-04 · BR-14-025.

**Tiền điều kiện, dữ liệu.** U-T68-IE; V-NEW chưa có; `ndxp` `ACTIVE`; đặc tả mẫu `ACTIVE`.

**Các bước.**

1. `POST /services` mã `tc-dich-vu-moi`, nhóm `TU_PHAP`, thao tác đọc, ưu tiên `NORMAL`, đệm 60 giây.
2. `PATCH /services/tc-dich-vu-moi` với `If-Match`, chuyển `ACTIVE`.

**Kết quả mong đợi.** `201` `DRAFT`; `PATCH` `200` `ACTIVE`; mã dịch vụ trung ương nằm ở cấu hình theo tenant.
:::

#### TC-14-013 · Khai báo dịch vụ sai: mâu thuẫn đệm, vượt trần, chưa đủ điều kiện <!--k:svc-create-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-005 · API-14-011, 013 · ERR-14-002, 003, 004, 009, 036, 038 · BR-14-014.

**Tiền điều kiện, dữ liệu.** U-T68-IE; `14.cache.max-ttl-seconds = 86400`; dịch vụ `tc-chua-dac-ta` chưa có đặc tả `ACTIVE`.

**Các bước.**

1. `POST /services` mức `SENSITIVE` kèm `cacheable = true`.
2. `POST /services` thao tác ghi kèm đệm.
3. `POST /services` đệm 90.000 giây.
4. `POST /services` mã trùng; thiếu nhóm.
5. Chuyển `ACTIVE` dịch vụ `tc-chua-dac-ta`; `PATCH` với `If-Match` cũ.

**Kết quả mong đợi.** Bước 1, 2 `422` ERR-14-038; bước 3 `422` ERR-14-036; bước 4 `409` ERR-14-002 và `400` ERR-14-003; bước 5 `422` ERR-14-009 và `409` ERR-14-004.
:::

#### TC-14-014 · Dịch vụ của tenant khác và `COMMON` <!--k:svc-isolation-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-004, 006 · API-14-010, 012, 013 · ERR-14-001 · BR-14-029.

**Tiền điều kiện, dữ liệu.** `T01` có `hotich-tra-cuu` khác cấu hình; `COMMON` có dịch vụ `dmdc-ds`.

**Các bước.**

1. U-T68-IE `GET /services/hotich-tra-cuu`; đối chiếu `baseUrl` với T01.
2. U-T01-TA `GET /services/dich-vu-chi-t68`.
3. U-T68-IE `PATCH` dịch vụ `COMMON`.

**Kết quả mong đợi.** Bước 1 trả cấu hình của T68; bước 2 `404` ERR-14-001; bước 3 `403`; dịch vụ `COMMON` đọc được.
:::

### TS-14-05 · Đặc tả có phiên bản và phát hiện lệch

**Mục tiêu.** Xác nhận nạp, so sánh, kích hoạt đặc tả; thay đổi phá vỡ phải được duyệt.

**Phủ.** FR-14-008; UC-14-05; API-14-018, 019, 020; UI-14-05.

#### TC-14-015 · Nạp đặc tả mới, phát hiện lệch, kích hoạt <!--k:spec-load-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-008 · API-14-018, 019, 020 · UI-14-05 · UC-14-05.

**Tiền điều kiện, dữ liệu.** U-T68-IE; V-HT có đặc tả v1 `ACTIVE`; tệp v2 chỉ thêm trường tùy chọn.

**Các bước.**

1. `POST /services/hotich-tra-cuu/specs` tệp v2.
2. `GET …/specs` xem báo cáo lệch.
3. `POST …/specs/2:activate`.

**Kết quả mong đợi.** v2 `UPLOADED`, báo cáo "không phá vỡ"; kích hoạt `ACTIVE`, v1 giữ lịch sử; hiệu lực ≤ 30 giây (NFR-14-026).
:::

#### TC-14-016 · Đặc tả trùng phiên bản, hỏng, phá vỡ chưa duyệt, tải xa lỗi <!--k:spec-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-008 · API-14-019, 020 · ERR-14-010, 011, 012, 131 · BR-14-024.

**Tiền điều kiện, dữ liệu.** U-T68-IE; v2 đã có; tệp v2 nội dung khác; tệp XML có thực thể ngoài (XXE); v3 xóa trường bắt buộc; WSDL từ xa `sim-ndxp` chế độ `DOWN`.

**Các bước.**

1. Nạp lại số phiên bản 2 nhưng khác nội dung.
2. Nạp tệp không đọc được, vượt giới hạn, và tệp có thực thể ngoài.
3. Nạp v3 phá vỡ rồi kích hoạt khi chưa duyệt.
4. Nạp đặc tả từ URL xa khi giả lập không phản hồi.

**Kết quả mong đợi.** Bước 1 `409` ERR-14-010; bước 2 `422` ERR-14-011, không giải thực thể ngoài; bước 3 `422` ERR-14-012; bước 4 `502` ERR-14-131 và hệ thống dùng bản đã lưu.
:::

### TS-14-06 · Đối chiếu danh mục dịch vụ với NDXP

**Mục tiêu.** Xác nhận đối chiếu đề xuất đúng bốn nhãn và không tự thay đổi hợp đồng.

**Phủ.** FR-14-007; UC-14-06; API-14-014, 015, 016, 017; UI-14-06; BR-14-024.

#### TC-14-017 · Chạy đối chiếu, xem đề xuất và áp dụng <!--k:recon-run-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-007 · API-14-014, 015, 016, 017 · UI-14-06 · UC-14-06 · BR-14-024.

**Tiền điều kiện, dữ liệu.** U-T68-IE; `sim-ndxp` trả danh mục thiếu một dịch vụ, đổi đặc tả một dịch vụ, thêm một dịch vụ mới.

**Các bước.**

1. `POST /service-reconciliations`; chờ xong; `GET …/{runId}`.
2. `POST …/{runId}:apply` chỉ cho dịch vụ "Đổi đặc tả".
3. `POST /services/{serviceCode}:set-label` đặt `UNKNOWN`.

**Kết quả mong đợi.** Đề xuất `STILL`, `SPEC_CHANGED`, `DISCONTINUED`, thêm mới; "Đổi đặc tả" chỉ sửa bộ điều hợp, giữ hợp đồng cung cấp lại; dịch vụ ngừng chuyển `DEPRECATED` hoặc `RETIRED` theo nhãn; nhãn tay ghi kiểm toán.
:::

#### TC-14-018 · Đối chiếu đang chạy hoặc đã áp dụng <!--k:recon-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-007 · API-14-014, 016 · ERR-14-026, 004, 001.

**Tiền điều kiện, dữ liệu.** Một phiên đối chiếu đang chạy; một phiên đã `APPLIED`.

**Các bước.**

1. `POST /service-reconciliations` khi đang có phiên cùng loại.
2. `POST …:apply` lần hai lên phiên đã áp dụng.
3. `GET` runId không có.

**Kết quả mong đợi.** `409` ERR-14-026; `409` ERR-14-004; `404` ERR-14-001.
:::

### TS-14-07 · Cung cấp lại dịch vụ quốc gia cho HTTT

**Mục tiêu.** Xác nhận HTTT chỉ nhận dịch vụ đã cung cấp lại, với trường đúng hợp đồng, không giữ thông tin xác thực quốc gia.

**Phủ.** FR-14-009; UC-14-07; API-14-021, 022, 023; UI-14-05; BR-14-007, 009.

#### TC-14-019 · Cung cấp lại dịch vụ và lọc trường theo hợp đồng <!--k:expose-publish-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-009 · API-14-021, 022, 023 · UI-14-05 · UC-14-07 · BR-14-007, 009.

**Tiền điều kiện, dữ liệu.** U-T68-IE; V-HT `ACTIVE`; HTTT `HT-MOTCUA`; hợp đồng chỉ cho `hoTen`, `ngaySinh`.

**Các bước.**

1. `PUT /services/hotich-tra-cuu/exposure` cấp cho `HT-MOTCUA`.
2. `POST …/exposure:publish`.
3. S-HT-MC gọi dịch vụ; phản hồi quốc gia có thêm trường `soCCCD`.

**Kết quả mong đợi.** Bước 2 thành công; bước 3 trả chỉ `hoTen`, `ngaySinh`; HTTT không nhận khóa, token, địa chỉ nền tảng.
:::

#### TC-14-020 · Cung cấp lại khi chưa đủ điều kiện hoặc đường dẫn xung đột <!--k:expose-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-009 · API-14-022, 023 · ERR-14-025, 001.

**Tiền điều kiện, dữ liệu.** Dịch vụ `DRAFT`; hai dịch vụ cùng đường dẫn cung cấp lại.

**Các bước.**

1. `POST …/exposure:publish` dịch vụ `DRAFT`.
2. Cung cấp lại dịch vụ thứ hai trùng đường dẫn.
3. `GET /services/khong-co/exposure`.

**Kết quả mong đợi.** `422` ERR-14-025 hai lần; `404` ERR-14-001.
:::

### TS-14-08 · Bảng định tuyến

**Mục tiêu.** Xác nhận luật định tuyến cần bốn mắt, mô phỏng đúng, và dự phòng chỉ cho thao tác đọc.

**Phủ.** FR-14-012, 013; UC-14-08; API-14-024, 025, 026, 027, 028; UI-14-07, 17; BR-14-022, 023.

#### TC-14-021 · Tạo luật, mô phỏng, gửi duyệt và duyệt <!--k:route-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-012, 013 · API-14-024, 025, 027, 028 · UI-14-07, 17 · UC-14-08 · BR-14-022.

**Tiền điều kiện, dữ liệu.** U-T68-IE, U-T68-IA; `hotich-tra-cuu` có hai đích: `ndxp` (ưu tiên 10), dự phòng `ndxp-moi` (ưu tiên 20).

**Các bước.**

1. `POST /routing-rules` điều kiện dịch vụ = `hotich-tra-cuu`, đích `ndxp`, dự phòng `ndxp-moi`.
2. `POST /routing-rules:simulate` với dịch vụ và HTTT mẫu.
3. IE gửi duyệt; U-T68-IA `POST /routing-rules/{ruleId}:approve`; `GET /routing-rules`.

**Kết quả mong đợi.** Mô phỏng trả đúng đích và lý do khớp; luật chưa duyệt chưa có hiệu lực; sau duyệt có hiệu lực ≤ 30 giây.
:::

#### TC-14-022 · Luật trùng, đích chưa hoạt động, dự phòng không hợp lệ <!--k:route-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-013 · API-14-025, 026 · ERR-14-013, 014, 015, 007 · BR-14-023.

**Tiền điều kiện, dữ liệu.** U-T68-IE; luật hiện có; dịch vụ đích `DRAFT`; dịch vụ ghi `hotich-dang-ky`; dịch vụ khác nhóm dữ liệu.

**Các bước.**

1. Tạo luật trùng điều kiện và ưu tiên.
2. Tạo luật đích là dịch vụ chưa hoạt động.
3. Tạo luật dự phòng cho thao tác ghi; rồi dự phòng khác nhóm dữ liệu.
4. U-T68-IE (người đề nghị) tự duyệt luật.

**Kết quả mong đợi.** Bước 1 `409` ERR-14-013; bước 2 `422` ERR-14-014; bước 3 `422` ERR-14-015 hai lần; bước 4 `403` ERR-14-007.
:::

### TS-14-09 · Gọi dịch vụ quốc gia qua điểm gọi chung

**Mục tiêu.** Xác nhận HTTT chỉ cần một API của Datahub; lỗi quốc gia được phân loại, che nội dung kỹ thuật; thao tác ghi có `Idempotency-Key` và không thử lại khi kết quả chưa rõ.

**Phủ.** FR-14-010, 014, 015, 026, 027; UC-14-09; API-14-075; UI-14-12; BR-14-007, 020, 030, 037; LGC-NGSP-001.

#### TC-14-023 · Gọi thành công, có mã giao dịch và nhật ký khai thác <!--k:invoke-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-010, 014, 026, 027 · API-14-075 · UC-14-09 · BR-14-007, 020, 037 · NFR-14-013, 020.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-LLTP đã cung cấp lại cho `HT-MOTCUA`; `sim-ndxp` `OK`.

**Các bước.**

1. `POST /internal/national/v1/invocations` `{serviceCode: lltp-tra-trang-thai, params: {dossierCode: LLTP-2026-000123}, purposeCode: GIAI_QUYET_TTHC}`; thân có thêm `systemCode: HT-KHAC`.
2. Tra giao dịch ở UI-14-12 theo `transactionCode`.

**Kết quả mong đợi.** `200` JSON chuẩn, `transactionCode`, `traceId`; mã HTTT lấy từ `azp` (bỏ qua `systemCode` trong thân); bản tin gửi đi có chữ ký, phản hồi đã xác minh; giao dịch `SUCCEEDED`; có dòng nhật ký khai thác đủ HTTT, mục đích.
:::

#### TC-14-024 · Lỗi từ quốc gia được phân loại và che nội dung kỹ thuật <!--k:invoke-err-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-015 · API-14-075 · ERR-14-101, 102, 115, 127, 128 · UI-14-12 · NFR-14-009.

**Tiền điều kiện, dữ liệu.** S-HT-MC; `sim-ndxp` lần lượt `BIZ404`, `DOWN`, `SLOW` quá 15 giây, phản hồi sai cấu trúc; tiêm lỗi nội bộ bằng cờ kiểm thử.

**Các bước.**

1. Gọi khi `BIZ404`.
2. Gọi khi `DOWN`; gọi khi trễ quá `14.timeout.default-ms`.
3. Gọi khi phản hồi thiếu trường bắt buộc.
4. Gọi khi bật cờ lỗi nội bộ.

**Kết quả mong đợi.** Bước 1 `404` hoặc `422` ERR-14-102, không có chuỗi lỗi của trung ương trong `detail`; bước 2 `502` ERR-14-101 và `504` ERR-14-115; bước 3 `502` ERR-14-128; bước 4 `500` ERR-14-127 kèm mã truy vết. Mọi giao dịch có trạng thái `FAILED` hoặc `TIMEOUT`.
:::

#### TC-14-025 · Thao tác ghi: Idempotency-Key và kết quả chưa rõ <!--k:invoke-write-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-010 · API-14-075 · ERR-14-003, 116, 108, 105, 117 · BR-14-030, 031 · UC-14-09.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-HT-DK; `sim-ndxp` `SLOW` rồi mất kết nối sau khi nhận; dịch vụ `tc-khong-luat` chưa có luật định tuyến.

**Các bước.**

1. `POST` ghi thiếu `Idempotency-Key`.
2. `POST` cùng khóa hai lần, lần hai khác `params`.
3. `POST` ghi khi quốc gia nhận nhưng không phản hồi; đếm số lần Datahub gửi.
4. `POST` với `params` sai lược đồ; gọi `tc-khong-luat`.

**Kết quả mong đợi.** Bước 1 `400` ERR-14-003; bước 2 lần hai `409` ERR-14-116; bước 3 giao dịch `UNKNOWN_RESULT`, gửi đúng một lần, không thử lại tự động, chỉ đối soát trạng thái; bước 4 `422` ERR-14-108 và ERR-14-105.
:::

#### TC-14-026 · Bộ điều hợp và chuyển đổi từ chối đầu vào sai, không có luật, lỗi không thử lại <!--k:invoke-adapters-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-012, 014, 017, 019, 020, 021, 022 · API-14-075 · ERR-14-102, 105, 108 · BR-14-037.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-LLTP, V-BHXH, V-DVQHNS, V-DKKD, V-VBQPPL; `sim-ndxp` `BIZ404`; dịch vụ `tc-khong-luat`.

**Các bước.**

1. Gọi từng dịch vụ với `params` sai kiểu hoặc thiếu trường bắt buộc.
2. Gọi `tc-khong-luat`.
3. Gọi V-LLTP khi `BIZ404`, xem trường `retryable`.

**Kết quả mong đợi.** Bước 1 `422` ERR-14-108 cho từng bộ điều hợp, không gọi ra quốc gia; bước 2 `422` ERR-14-105; bước 3 `404` ERR-14-102, `retryable = false`, không thử lại. Bộ điều hợp chỉ đổi giao thức, phong bì, lược đồ, không đổi ngữ nghĩa (BR-14-037).
:::

#### TC-14-027 · Phân loại lỗi có thể thử lại và thử lại thành công <!--k:invoke-classify-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-015, 038 · API-14-075 · BR-14-031 · UC-14-09.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-HT; `sim-ndxp` trả `503` một lần rồi `OK`; `14.retry.max-attempts = 2`.

**Các bước.**

1. Gọi thao tác đọc V-HT, đếm số lần gửi.
2. Xem giao dịch ở UI-14-12.

**Kết quả mong đợi.** Lỗi `503` của quốc gia phân loại `retryable = true`; thử lại một lần thì thành công, bên gọi nhận `200`; giao dịch ghi số lần thử và mã lỗi gốc đã che.
:::

### TS-14-10 · Mục đích khai thác và ủy quyền theo mục đích

**Mục tiêu.** Xác nhận mọi lượt gọi dịch vụ chứa DLCN có mục đích hợp lệ, mã thủ tục, mã hồ sơ; không kiểm tra được thì từ chối an toàn.

**Phủ.** FR-14-011, 052; UC-14-09, 35; API-14-075, 065; UI-14-13; BR-14-008, 009; LGC-NGSP-003.

#### TC-14-028 · Gọi dịch vụ DLCN đủ mục đích, mã thủ tục, mã hồ sơ <!--k:purpose-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-011, 052 · API-14-075, 065 · UI-14-13 · UC-14-09 · BR-14-008, 009 · SEC-37.

**Tiền điều kiện, dữ liệu.** S-HT-MC được cấp V-BHXH; U-T68-AU.

**Các bước.**

1. Gọi V-BHXH `purposeCode = GIAI_QUYET_TTHC`, `procedureCode = 1.001234`, `caseCode = HS-2026-08-001234`.
2. U-T68-AU mở UI-14-13, lọc theo HTTT và mục đích.

**Kết quả mong đợi.** `200`; nhật ký khai thác có HTTT, người dùng cuối nếu có, mục đích, mã thủ tục, mã hồ sơ, dịch vụ, thời điểm; không có giá trị DLCN trong nhật ký.
:::

#### TC-14-029 · Từ chối: chưa được cấp, mục đích sai, thiếu mã hồ sơ, ngoài khung giờ <!--k:purpose-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-011 · API-14-075 · ERR-14-106, 107, 132 · BR-14-008 · NFR-14-024.

**Tiền điều kiện, dữ liệu.** S-HT-KHAC; S-HT-MC; `14.purpose.allowed-hours = 07:00-18:00`, giờ giả lập 22:00.

**Các bước.**

1. S-HT-KHAC gọi V-BHXH.
2. S-HT-MC gọi với `purposeCode` không thuộc danh mục.
3. S-HT-MC gọi V-BHXH thiếu `caseCode`.
4. Chuyển giờ giả lập 22:00, gọi đúng; rồi dừng OPA và gọi lại.

**Kết quả mong đợi.** Bước 1, 2 `403` ERR-14-106; bước 3 `422` ERR-14-107; bước 4 lần một `403` ERR-14-106, lần hai `503` ERR-14-132 (từ chối an toàn). Không lượt nào chạm `sim-ndxp`; mỗi lượt từ chối có dòng nhật ký.
:::

### TS-14-11 · Gọi bất đồng bộ qua hàng chờ

**Mục tiêu.** Xác nhận yêu cầu dài hoặc lô đi qua hàng chờ, theo dõi, hủy được trước khi gửi.

**Phủ.** FR-14-016; UC-14-10; API-14-076, 077, 078; UI-14-12; BR-14-001.

#### TC-14-030 · Gửi bất đồng bộ, theo dõi đến hoàn thành <!--k:async-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-016 · API-14-076, 077 · UI-14-12 · UC-14-10 · BR-14-001.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-HT-DK; `sim-ndxp` `OK`.

**Các bước.**

1. `POST /async-invocations` ghi hộ tịch.
2. `GET /async-invocations/{requestId}` đến khi xong.

**Kết quả mong đợi.** `202` kèm `requestId`; trạng thái `QUEUED → SENT → SUCCEEDED`; kết quả có chữ ký đã xác minh; hiển thị ở hàng chờ UI-14-12.
:::

#### TC-14-031 · Hủy, không thấy, hàng chờ đầy <!--k:async-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-016 · API-14-077, 078 · ERR-14-118, 129, 130 · NFR-14-011.

**Tiền điều kiện, dữ liệu.** `14.queue.max-size = 1000` (tenant `T90`); `sim-ndxp` `DOWN`.

**Các bước.**

1. Gửi một yêu cầu rồi `POST …:cancel` khi còn `QUEUED`.
2. Gửi yêu cầu, cho đã `SENT`, `POST …:cancel`.
3. `GET` `requestId` không có.
4. Gửi 1.001 yêu cầu.

**Kết quả mong đợi.** Bước 1 `200` `CANCELLED`; bước 2 `409` ERR-14-130; bước 3 `404` ERR-14-129; bước 4 yêu cầu thứ 1.001 `503` ERR-14-118, 1.000 yêu cầu trước giữ nguyên.
:::

### TS-14-12 · Bộ điều hợp tư pháp: lý lịch tư pháp, hộ tịch

**Mục tiêu.** Xác nhận không mất chức năng tư pháp của hệ cũ.

**Phủ.** FR-14-017, 018; UC-14-11; API-14-075, 076; UI-14-04, 05; LGC-NGSP-001, 002.

#### TC-14-032 · Lý lịch tư pháp: danh sách, trạng thái, đánh dấu thành công <!--k:lltp-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-017 · API-14-075 · UC-14-11 · LGC-NGSP-001 · UI-14-04.

**Tiền điều kiện, dữ liệu.** S-HT-MC; `sim-ndxp` có 3 hồ sơ LLTP.

**Các bước.**

1. Gọi các thao tác `listDossiers`, `getCatalog`, `getStatus`.
2. Gọi `markSuccess` cho một hồ sơ, rồi `getStatusList`.

**Kết quả mong đợi.** Dữ liệu đúng cấu trúc JSON chuẩn tương đương hệ cũ; `markSuccess` là thao tác ghi có `Idempotency-Key`; mọi bản tin ký (BR-14-001).
:::

#### TC-14-033 · Hộ tịch: đăng ký, trạng thái, kết quả; hồ sơ không tồn tại <!--k:hotich-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-018 · API-14-075, 076 · ERR-14-102, 108 · LGC-NGSP-002 · UC-14-11.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-HT, V-HT-DK.

**Các bước.**

1. Đăng ký hộ tịch qua `async-invocations`; tra trạng thái, kết quả.
2. Tra hồ sơ `HT-KHONG-CO` (`BIZ404`).
3. Gọi thao tác không có trong bộ điều hợp.

**Kết quả mong đợi.** Bước 1 thành công; bước 2 `404` ERR-14-102; bước 3 `422` ERR-14-108.
:::

### TS-14-13 · Bộ điều hợp bảo hiểm xã hội

**Mục tiêu.** Xác nhận tra hộ gia đình, giới hạn thành viên, không đệm DLCN.

**Phủ.** FR-14-019; UC-14-12; API-14-075; UI-14-05; BR-14-009, 014; LGC-NGSP-003.

#### TC-14-034 · Tra hộ gia đình theo mã số, theo tiêu chí <!--k:bhxh-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-019 · API-14-075 · UC-14-12 · BR-14-009, 014 · LGC-NGSP-003.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-BHXH; hộ mẫu 4 thành viên.

**Các bước.**

1. Tra theo mã số hộ, đủ mục đích và mã hồ sơ; lặp lại ngay.
2. Lấy mã số theo tiêu chí.

**Kết quả mong đợi.** Chỉ trường theo hợp đồng cung cấp lại; lượt lặp lại vẫn gọi ra quốc gia (mục `SENSITIVE`, không đệm); lượt lặp có nhật ký riêng.
:::

#### TC-14-035 · Hộ vượt giới hạn thành viên <!--k:bhxh-limit-->

::: dac-ta
**Loại.** Biên, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-019 · API-14-075 · ERR-14-108 · UC-14-12.

**Tiền điều kiện, dữ liệu.** Hộ giả lập 31 thành viên; `14.bhxh.max-members = 30`.

**Các bước.**

1. Tra hộ 31 thành viên.

**Kết quả mong đợi.** Chỉ trả 30 thành viên kèm cờ cắt bớt và số tổng; DLCN không vào nhật ký.
:::

### TS-14-14 · Hồ sơ cấp mã ĐVQHNS, đăng ký doanh nghiệp, văn bản quy phạm pháp luật

**Mục tiêu.** Xác nhận phân trang tự động có giới hạn, đệm theo loại dữ liệu, hoãn dịch vụ nền khi gần hết hạn mức.

**Phủ.** FR-14-020, 021, 022; UC-14-13, 14; API-14-075; UI-14-04, 05; LGC-NGSP-004, 005, 007.

#### TC-14-036 · ĐVQHNS theo khoảng thời gian, tự phân trang <!--k:dvqhns-ok-->

::: dac-ta
**Loại.** Dương, Biên, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-020 · API-14-075 · ERR-14-003, 128 · UC-14-13 · LGC-NGSP-004.

**Tiền điều kiện, dữ liệu.** S-PH04; V-DVQHNS; 250 hồ sơ, 20 dòng/trang; `14.adapter.max-pages = 100`.

**Các bước.**

1. Gọi khoảng 1 ngày.
2. Gọi khoảng 5 năm.
3. Đặt phản hồi lớn hơn `14.adapter.max-response-mb`.

**Kết quả mong đợi.** Bước 1 gộp 13 trang thành một phản hồi; bước 2 `400` ERR-14-003 (khoảng quá rộng); bước 3 `502` ERR-14-128.
:::

#### TC-14-037 · Đăng ký doanh nghiệp và văn bản quy phạm: trúng đệm <!--k:dkkd-vbqppl-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-021, 022 · API-14-075 · UC-14-14 · NFR-14-004 · LGC-NGSP-005, 007.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-DKKD, V-VBQPPL.

**Các bước.**

1. Gọi `V-DKKD.getLatest` hai lần.
2. Gọi `V-VBQPPL.search` hai lần, lần hai `freshData = true`.

**Kết quả mong đợi.** Lần hai bước 1 `COMPLETED_CACHE`, không gọi ra; bước 2 lần hai gọi ra quốc gia; mọi truy vấn văn bản (tìm toàn văn, lĩnh vực, cơ quan, người ký, chức danh) trả đúng.
:::

### TS-14-15 · Cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07

**Mục tiêu.** Xác nhận chỉ PH-07 gọi cổng, PH-14 không lưu dữ liệu danh mục.

**Phủ.** FR-14-023; UC-14-15; API-14-079, 080, 081, 082, 083; UI-14-04, 11; BR-14-036; LGC-NGSP-006, LGC-DMDC-019.

#### TC-14-038 · Danh sách, cấu trúc, dữ liệu, đề xuất bổ sung <!--k:dmdc-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-023 · API-14-079, 080, 081, 082, 083 · UC-14-15 · UI-14-11 · BR-14-036 · LGC-NGSP-006, LGC-DMDC-019.

**Tiền điều kiện, dữ liệu.** S-PH07; V-DMDC; `sim-ndxp` có danh mục `DM_DANTOC`.

**Các bước.**

1. `GET /national-catalogs`; `GET …/DM_DANTOC/structure`; `GET …/DM_DANTOC/data`.
2. `POST …/DM_DANTOC/proposals`; `GET …/proposals/{proposalId}`.

**Kết quả mong đợi.** Dữ liệu chuyển tiếp nguyên trạng; không có bảng dữ liệu danh mục ở CSDL PH-14; đề xuất ghi trạng thái.
:::

#### TC-14-039 · Người gọi không phải PH-07; đề xuất không có <!--k:dmdc-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-023 · API-14-079, 083 · ERR-14-001, 027 · BR-14-036.

**Tiền điều kiện, dữ liệu.** S-HT-MC; S-PH07; PH-07 giả lập không khả dụng ở bước cuối.

**Các bước.**

1. S-HT-MC gọi `GET /national-catalogs`.
2. S-PH07 `GET …/proposals/khong-co`.
3. Dừng PH-07 phía chuyển đổi, S-PH07 gọi lấy dữ liệu.

**Kết quả mong đợi.** Bước 1 `403`; bước 2 `404` ERR-14-001; bước 3 `502` ERR-14-027.
:::

### TS-14-16 · Token OAuth 2.1, xoay vòng thông tin xác thực

**Mục tiêu.** Xác nhận token lấy và làm mới tự động, thông tin xác thực ghi một chiều vào OpenBao, xoay vòng không gián đoạn.

**Phủ.** FR-14-024, 025; UC-14-16, 17; API-14-039, 040; UI-14-03; BR-14-005, 031; LGC-NGSP-008.

#### TC-14-040 · Thử token và làm mới trước hạn <!--k:token-refresh-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-024 · API-14-040 · UI-14-03 · UC-14-16 · LGC-NGSP-008 · BR-14-005.

**Tiền điều kiện, dữ liệu.** U-T68-TO; token `sim-ndxp` sống 120 giây; `14.token.refresh-before-seconds = 60`.

**Các bước.**

1. `POST /platforms/ndxp/token:test`.
2. Đồng hồ giả lập tiến 61 giây; gọi dịch vụ.

**Kết quả mong đợi.** Bước 1 `200` chỉ có hạn dùng, không có giá trị token; bước 2 token mới được lấy trước khi gọi, không có lượt nào dùng token hết hạn.
:::

#### TC-14-041 · Xoay vòng thông tin xác thực, cửa sổ chuyển tiếp <!--k:cred-rotate-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-025 · API-14-039 · UC-14-17 · BR-14-005 · NFR-14-015 · SEC-31.

**Tiền điều kiện, dữ liệu.** U-T68-TA (đã xác thực lại); `14.secret.overlap-hours = 24`; giá trị mồi `DH-CANARY-KEY-…`.

**Các bước.**

1. `POST /platforms/ndxp/credentials:rotate` kèm giá trị mới (ghi một chiều).
2. Gọi dịch vụ liên tục trong 5 phút; `GET /platforms/ndxp`.
3. Dò mồi ở phản hồi, nhật ký, PostgreSQL.

**Kết quả mong đợi.** Không lượt gọi nào hỏng khi chuyển; chỉ có siêu dữ liệu phiên bản và ngày xoay; không tìm thấy mồi ngoài OpenBao; cảnh báo xoay đúng theo `14.secret.max-age-days`.
:::

#### TC-14-042 · Thông tin xác thực chưa đặt, OpenBao lỗi, nền tảng từ chối <!--k:cred-neg-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-14-024, 025 · API-14-039, 040 · ERR-14-034, 035, 114, 004 · BR-14-031.

**Tiền điều kiện, dữ liệu.** `ndxp-moi` chưa đặt thông tin xác thực; `sim-ndxp` `AUTH401`; dừng OpenBao.

**Các bước.**

1. `:test` token cho `ndxp-moi`.
2. Gọi dịch vụ khi `AUTH401` liên tiếp 3 lần trong 5 phút.
3. Dừng OpenBao, `:rotate`.

**Kết quả mong đợi.** Bước 1 `422` ERR-14-034; bước 2 `502` ERR-14-114, chỉ thử lại một lần trong 5 phút; bước 3 `503` ERR-14-035, không có giá trị nào lưu ra nơi khác.
:::

### TS-14-17 · Ký số bản tin và xác minh chữ ký phản hồi

**Mục tiêu.** Xác nhận khóa riêng không rời OpenBao, chữ ký sai là sự cố an ninh, không ký được thì không gửi.

**Phủ.** FR-14-026, 027, 031; UC-14-09, 21; UI-14-08, 14; BR-14-001, 002, 003, 004, 017.

#### TC-14-043 · Ký bằng khóa trong OpenBao, xác minh phản hồi <!--k:sign-ok-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-026, 027 · UC-14-09 · UI-14-08 · BR-14-001, 002, 004 · NFR-14-002, 003, 013 · SEC-32.

**Tiền điều kiện, dữ liệu.** V-LLTP (ký `REQUIRED`, xác minh `REQUIRED`); K-KY-01; `sim-ndxp` `OK`.

**Các bước.**

1. Gọi V-LLTP.
2. Đối chiếu bản tin `sim-ndxp` nhận và nhật ký OpenBao.
3. Xem thống kê ký ở UI-14-08.

**Kết quả mong đợi.** Bản tin có chữ ký, `sim-ndxp` xác minh được; OpenBao ghi một lệnh `transit/sign` với giá trị băm; khóa riêng không ở bộ nhớ hay đĩa của pod; phản hồi xác minh đạt rồi mới trả.
:::

#### TC-14-044 · Chữ ký phản hồi sai, ngoài chuỗi tin cậy, lệch thời điểm, lặp <!--k:verify-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-027, 031 · UI-14-14 · ERR-14-109, 110, 111 · BR-14-002, 003 · NFR-14-018.

**Tiền điều kiện, dữ liệu.** U-T68-SO; `sim-ndxp` lần lượt `BADSIG`, `BADCHAIN`, `OLDTS`, phát lại một phản hồi.

**Các bước.**

1. Gọi dịch vụ ở từng chế độ.
2. Mở UI-14-14.

**Kết quả mong đợi.** `502` lần lượt ERR-14-109, 110, 111, 111; phản hồi không đến HTTT; giao dịch `SIGNATURE_FAILED`; có sự cố chữ ký mới và cảnh báo SO ≤ 1 phút.
:::

#### TC-14-045 · Không ký được thì không gửi; chứng thư hết hạn; thiếu chứng thư <!--k:sign-block-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-14-026 · API-14-075, 076, 008 · ERR-14-112, 113, 037, 035 · BR-14-001, 017 · NFR-14-010.

**Tiền điều kiện, dữ liệu.** Dừng OpenBao; chứng thư ký hết hạn (đồng hồ giả lập); nền tảng `ndxp-moi` có dịch vụ yêu cầu ký nhưng chưa có chứng thư `ACTIVE`.

**Các bước.**

1. Dừng OpenBao, gọi dịch vụ ký và gửi một yêu cầu bất đồng bộ.
2. Khôi phục OpenBao; đặt đồng hồ quá `notAfter`; gọi dịch vụ.
3. `:request-activation` `ndxp-moi`.

**Kết quả mong đợi.** Bước 1 `503` ERR-14-112, `sim-ndxp` nhận 0 bản tin, yêu cầu bất đồng bộ ở lại hàng chờ, 0 bản tin mất; bước 2 `503` ERR-14-113 (nền tảng bị chặn ký); bước 3 `422` ERR-14-037.
:::

### TS-14-18 · Chứng thư số: nạp và kích hoạt

**Mục tiêu.** Xác nhận chứng thư chỉ dùng được sau bốn mắt, khớp khóa trong OpenBao và thuộc chuỗi tin cậy.

**Phủ.** FR-14-028; UC-14-18; API-14-029, 030, 031, 032, 033, 034; UI-14-08, 17; BR-14-018, 019.

#### TC-14-046 · Nạp, yêu cầu kích hoạt, duyệt bốn mắt <!--k:cert-activate-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-028 · API-14-029, 030, 031, 032, 033 · UI-14-08, 17 · UC-14-18 · BR-14-018.

**Tiền điều kiện, dữ liệu.** U-T68-SO, U-T68-IA; K-KY-02 hợp lệ, khóa đã ở OpenBao.

**Các bước.**

1. `POST /certificates` nạp K-KY-02; `GET /certificates/{certCode}`.
2. SO `:request-activation`; IA `:approve-activation`.

**Kết quả mong đợi.** `UPLOADED → PENDING_ACTIVATION → ACTIVE`; chi tiết không có khóa riêng; K-KY-01 chuyển `SUPERSEDED` sau cửa sổ `14.cert.overlap-hours`.
:::

#### TC-14-047 · Chứng thư lỗi: ngoài chuỗi, lệch khóa, chưa/hết hiệu lực, còn dùng xác minh <!--k:cert-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-028 · API-14-030, 032, 034 · ERR-14-019, 020, 021, 022, 007 · BR-14-018, 019.

**Tiền điều kiện, dữ liệu.** Tệp hỏng; chứng thư ngoài chuỗi; chứng thư khác khóa OpenBao; chứng thư `notBefore` ở tương lai; K-KY-01 còn dùng xác minh giao dịch trong hạn lưu.

**Các bước.**

1. Nạp từng tệp trên.
2. U-T68-SO tự duyệt yêu cầu của mình.
3. Thu hồi K-KY-01 rồi yêu cầu xóa bản ghi.

**Kết quả mong đợi.** `422` ERR-14-019 (hai lần), `422` ERR-14-020, `409` ERR-14-021; bước 2 `403` ERR-14-007; bước 3 thu hồi được nhưng xóa `409` ERR-14-022, bản ghi vẫn giữ.
:::

### TS-14-19 · Theo dõi hạn chứng thư, chuỗi tin cậy, danh sách thu hồi

**Mục tiêu.** Xác nhận cảnh báo 60, 30, 7 ngày, chuyển tiếp không gián đoạn, CRL quá hạn xử lý theo chế độ.

**Phủ.** FR-14-029, 030; UC-14-19, 20; API-14-029, 031, 035, 036; UI-14-08; BR-14-017.

#### TC-14-048 · Cảnh báo hạn và chuyển sang chứng thư thay thế <!--k:cert-expiry-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-029 · API-14-029, 031 · UC-14-19 · UI-14-08 · BR-14-017 · NFR-14-018.

**Tiền điều kiện, dữ liệu.** K-HET (còn 5 ngày) và K-KY-02 `ACTIVE`; đồng hồ giả lập.

**Các bước.**

1. Đặt đồng hồ tại các mốc 60, 30, 7 ngày trước hạn K-KY-01.
2. Tiến quá `notAfter` của K-HET.

**Kết quả mong đợi.** Cảnh báo ba mức ≤ 2 phút mỗi mốc; `EXPIRING → EXPIRED`; việc ký tự dùng chứng thư thay thế, không lượt nào bị chặn; đếm ngược hiển thị đúng ở UI-14-08.
:::

#### TC-14-049 · Làm mới chuỗi tin cậy và CRL; CRL quá hạn <!--k:trust-crl-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-030 · API-14-035, 036 · UC-14-20 · ERR-14-110 · BR-14-002.

**Tiền điều kiện, dữ liệu.** U-T68-SO; CRL của `sim-ndxp` nạp được; `14.crl.max-age-days = 7`; chế độ `SOFT` rồi `HARD`.

**Các bước.**

1. `POST /trust-store:refresh`; `GET /trust-store`.
2. Chặn tải CRL 8 ngày; gọi dịch vụ ở `SOFT`, đổi `14.crl.fail-mode = HARD` (bốn mắt), gọi lại.
3. Thu hồi chứng thư của `sim-ndxp` trong CRL.

**Kết quả mong đợi.** Bước 1 cập nhật thời điểm; bước 2 `SOFT` vẫn xác minh kèm cảnh báo mức cao, `HARD` `502` ERR-14-110; bước 3 phản hồi bị từ chối ERR-14-110.
:::

#### TC-14-050 · Chứng thư hết hạn không còn thay thế; chuỗi tin cậy bị sửa <!--k:cert-expiry-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-029, 030 · API-14-036, 075 · ERR-14-113, 019, 007 · BR-14-017, 018.

**Tiền điều kiện, dữ liệu.** U-T68-SO; K-HET là chứng thư ký duy nhất; nguồn chuỗi tin cậy giả có chữ ký sai.

**Các bước.**

1. Đồng hồ giả lập tiến quá `notAfter` của K-HET; gọi dịch vụ ký.
2. `POST /trust-store:refresh` với nguồn chữ ký sai.
3. Thêm chứng thư neo tin cậy khi người duyệt trùng người đề nghị.

**Kết quả mong đợi.** Bước 1 `503` ERR-14-113, nền tảng bị chặn ký và có cảnh báo; bước 2 `422` ERR-14-019, chuỗi cũ giữ nguyên; bước 3 `403` ERR-14-007.
:::

### TS-14-20 · Sự cố chữ ký như sự cố an ninh

**Mục tiêu.** Xác nhận chữ ký sai ghi sự cố, vượt ngưỡng thì giữ an ninh nền tảng, chỉ SO giải trừ.

**Phủ.** FR-14-031, 027; UC-14-21; API-14-037, 038; UI-14-14; BR-14-003.

#### TC-14-051 · Vượt ngưỡng vào SECURITY_HOLD, xử lý và giải trừ <!--k:sig-hold-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-031 · API-14-037, 038 · UI-14-14 · UC-14-21 · BR-14-003 · ERR-14-109 · PERM-14-operate.

**Tiền điều kiện, dữ liệu.** U-T68-SO; `14.signature.hold-threshold = 5`; `sim-ndxp` `BADSIG`.

**Các bước.**

1. Gọi 5 lượt trong 10 phút.
2. SO `POST /signature-incidents/{id}:transition` xác nhận, phân loại, kết thúc; giải trừ giữ.

**Kết quả mong đợi.** Nền tảng vào `SECURITY_HOLD`, lượt mới bị từ chối; SO giải trừ sau xác thực nhiều yếu tố, có lý do; kiểm toán đầy đủ; nền tảng trở về `ACTIVE`.
:::

#### TC-14-052 · Chuyển trạng thái sự cố sai hoặc không có quyền <!--k:sig-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-031 · API-14-037, 038 · ERR-14-004, 001.

**Tiền điều kiện, dữ liệu.** Sự cố `CLOSED`; U-T68-TA, U-T68-VW; sự cố của T01.

**Các bước.**

1. SO chuyển sự cố `CLOSED` về `OPEN`.
2. U-T68-VW chuyển trạng thái.
3. U-T68-SO `GET` sự cố của T01.

**Kết quả mong đợi.** `409` ERR-14-004; `403`; `404` ERR-14-001.
:::

### TS-14-21 · Hạn mức do trung ương áp, đếm và phân bổ

**Mục tiêu.** Xác nhận hạn mức có căn cứ, đếm chính xác theo cửa sổ, hoãn theo ưu tiên và không gọi ra khi hết.

**Phủ.** FR-14-032, 033, 034; UC-14-22, 23; API-14-041, 042, 043, 044, 045; UI-14-01, 09, 17; BR-14-011, 012, 013.

#### TC-14-053 · Khai báo hạn mức, phân bổ theo HTTT, duyệt ở môi trường thật <!--k:quota-declare-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-032, 034 · API-14-041, 042, 044, 045 · UI-14-09, 17 · UC-14-22 · BR-14-011, 022.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-IA; hạn mức 10.000 lượt/ngày cho `ndxp`.

**Các bước.**

1. `POST /quotas` kèm căn cứ (số, ngày, trích yếu), gửi duyệt, IA duyệt.
2. `PUT /quota-allocations/HT-MOTCUA` 6.000; `GET /quota-allocations`.

**Kết quả mong đợi.** Hạn mức có hiệu lực ≤ 30 giây sau duyệt; phân bổ lưu đúng; kiểm toán đủ.
:::

#### TC-14-054 · Hạn mức sai: thiếu căn cứ, chu kỳ sai, phân bổ vượt <!--k:quota-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-032, 034 · API-14-042, 045 · ERR-14-016, 017, 018 · PERM-14-quota.

**Tiền điều kiện, dữ liệu.** U-T68-TA; hạn mức 10.000/ngày; U-T68-IE.

**Các bước.**

1. `POST /quotas` không có căn cứ.
2. `POST /quotas` giới hạn 0 hoặc chu kỳ `HOURLY` ngoài miền.
3. Phân bổ 6.000 cho `HT-MOTCUA` rồi 5.000 cho `HT-KHAC`.
4. U-T68-IE khai báo hạn mức.

**Kết quả mong đợi.** `422` ERR-14-016; `422` ERR-14-017; bước 3 lần hai `422` ERR-14-018; bước 4 `403`.
:::

#### TC-14-055 · Đếm, ngưỡng 70, 85, 95 %, hoãn theo ưu tiên, hết hạn mức <!--k:quota-count-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API, k6.

**Truy vết.** FR-14-033, 034 · API-14-043, 075 · UI-14-01, 09 · UC-14-23 · ERR-14-104 · BR-14-012, 013 · NFR-14-018.

**Tiền điều kiện, dữ liệu.** Hạn mức 1.000 lượt/ngày; V-LLTP `ESSENTIAL`, V-HT `NORMAL`, V-DVQHNS `BACKGROUND`.

**Các bước.**

1. Gọi V-HT tới 700 lượt; gọi V-DVQHNS.
2. Tới 950 lượt; gọi V-HT, V-DVQHNS, V-LLTP.
3. Tới 1.000 lượt; gọi V-LLTP; `GET /quotas/usage`.
4. Qua nửa đêm giờ giả lập.

**Kết quả mong đợi.** Cảnh báo ở 70, 85, 95 % trong ≤ 2 phút; ≥ 70 % `BACKGROUND` bị hoãn `429` ERR-14-104; ≥ 95 % chỉ `ESSENTIAL` đi; 1.000 lượt thì `429` ERR-14-104 có `scope`, `reason`, `resetAt`, không gọi ra; bước 4 bộ đếm đặt lại; số đếm khớp tuyệt đối giữa 3 bản sao.
:::

### TS-14-22 · Đệm phản hồi và dữ liệu quá hạn

**Mục tiêu.** Xác nhận đệm theo tenant, không đệm dữ liệu nhạy cảm hoặc thao tác ghi, dữ liệu quá hạn có cờ.

**Phủ.** FR-14-035, 036, 037; UC-14-24; API-14-046, 047; UI-14-05, 09; BR-14-014, 015, 016; NFR-14-005.

#### TC-14-056 · Trúng đệm, cô lập tenant, không đệm mục nhạy cảm <!--k:cache-hit-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-035 · API-14-046, 075 · UI-14-05, 09 · UC-14-24 · BR-14-014, 015 · NFR-14-004, 024.

**Tiền điều kiện, dữ liệu.** V-HT (đệm 300 giây); V-BHXH; `T01` có `hotich-tra-cuu` cùng tham số; U-T68-TO.

**Các bước.**

1. S-HT-MC gọi V-HT hai lần; T01 gọi một lần cùng tham số.
2. Gọi V-BHXH hai lần.
3. `GET /cache/stats`; kiểm khóa Valkey.

**Kết quả mong đợi.** Lần hai `COMPLETED_CACHE`; T01 không nhận dữ liệu của T68; V-BHXH không đệm; khóa có tiền tố tenant; ủy quyền mục đích kiểm trước khi đọc đệm (HTTT chưa cấp vẫn `403` khi dữ liệu đã đệm).
:::

#### TC-14-057 · Vô hiệu đệm; dùng dữ liệu quá hạn có cờ khi quốc gia lỗi <!--k:cache-stale-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-036, 037 · API-14-047, 075 · ERR-14-103, 004 · BR-14-016 · NFR-14-009.

**Tiền điều kiện, dữ liệu.** V-HT `staleAllowed`; V-DKKD không cho dùng quá hạn; `14.cache.stale-max-seconds = 86400`; U-T68-TO.

**Các bước.**

1. Đệm hết hạn, `sim-ndxp` `DOWN`, gọi V-HT.
2. Cùng điều kiện, gọi V-DKKD.
3. `POST /cache:invalidate` V-HT; gọi lại khi `OK`.

**Kết quả mong đợi.** Bước 1 `200` kèm `stale = true` trong ≤ 1 giây; bước 2 `503` ERR-14-103; bước 3 đệm bị xóa, lượt sau gọi ra quốc gia; vô hiệu cho dịch vụ không tồn tại `404` ERR-14-001.
:::

### TS-14-23 · Ngắt mạch và thử lại

**Mục tiêu.** Xác nhận ngắt mạch mở khi lỗi quá ngưỡng, thử lại có giới hạn và không thử lại thao tác ghi.

**Phủ.** FR-14-038; UC-14-25; API-14-086; UI-14-01; BR-14-030, 031; NFR-14-009.

#### TC-14-058 · Mở, thăm dò, đóng ngắt mạch <!--k:breaker-flow-->

::: dac-ta
**Loại.** Dương, Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-038 · UC-14-25 · UI-14-01 · ERR-14-103 · BR-14-031 · NFR-14-009.

**Tiền điều kiện, dữ liệu.** `14.breaker.min-calls = 20`, `failure-ratio = 0,5`, `open-seconds = 30`; `sim-ndxp` `ERR5XX`.

**Các bước.**

1. Gọi 20 lượt lỗi liên tiếp.
2. Gọi tiếp khi ngắt mạch mở.
3. Sau 30 giây đặt `OK`, gọi.

**Kết quả mong đợi.** Ngắt mạch mở; lượt tiếp theo trả ≤ 1 giây `503` ERR-14-103 hoặc dữ liệu đệm quá hạn; thăm dò thành công thì đóng; UI-14-01 hiển thị trạng thái.
:::

#### TC-14-059 · Ép ngắt mạch tay; thử lại đọc, không thử lại ghi <!--k:breaker-manual-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-038 · API-14-086, 075 · BR-14-030, 031 · ERR-14-004, 103.

**Tiền điều kiện, dữ liệu.** U-T68-TO; `14.retry.max-attempts = 2`; `sim-ndxp` lỗi 503 hai lần rồi `OK`.

**Các bước.**

1. Gọi thao tác đọc; đếm số lần gửi.
2. Gọi thao tác ghi, cùng điều kiện.
3. `POST /platforms/ndxp/breaker:set` `OPEN` kèm lý do rồi `CLOSED`.

**Kết quả mong đợi.** Đọc thành công sau tối đa 3 lần gửi; ghi chỉ gửi một lần; ép `OPEN` có hiệu lực ≤ 30 giây; đặt trạng thái không đổi trả `409` ERR-14-004.
:::

### TS-14-24 · Chiều vào: đăng ký, tiếp nhận, chuyển luồng PH-04

**Mục tiêu.** Xác nhận bản tin từ quốc gia chỉ được xử lý khi xác minh đạt, nguồn được phép, không lặp; tenant xác định từ điểm cuối.

**Phủ.** FR-14-039, 040, 041; UC-14-26, 27; API-14-048, 049, 050, 051, 052, 084, 090; UI-14-10, 17; BR-14-027, 028.

#### TC-14-060 · Đăng ký điểm cuối, nguồn được phép, xác nhận vân tay <!--k:inbound-register-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-039 · API-14-048, 049, 050, 051, 052, 090 · UI-14-10, 17 · UC-14-26 · BR-14-027.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-SO; luồng PH-04 `lg-nhan-tb` đã phát hành.

**Các bước.**

1. `POST /inbound-endpoints` mã `ndxp-vao`, ánh xạ luồng.
2. `PUT …/allowed-senders` với vân tay chứng thư S-NDXP-IN.
3. SO `POST …:confirm` vân tay; `GET /inbound-endpoints`.

**Kết quả mong đợi.** Điểm cuối `ACTIVE` sau xác nhận bốn mắt; danh sách nguồn lưu đúng; `PATCH` đổi trạng thái được ghi kiểm toán.
:::

#### TC-14-061 · Đăng ký sai: trùng, nguồn rỗng, luồng chưa phát hành <!--k:inbound-register-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-039 · API-14-049, 052 · ERR-14-023, 024, 039.

**Tiền điều kiện, dữ liệu.** `ndxp-vao` đã có; luồng `lg-chua-phat-hanh` ở `DRAFT`.

**Các bước.**

1. `POST` điểm cuối trùng mã, rồi trùng đường dẫn.
2. `PUT …/allowed-senders` danh sách rỗng.
3. `POST` điểm cuối ánh xạ luồng `lg-chua-phat-hanh`.

**Kết quả mong đợi.** `409` ERR-14-023 hai lần; `422` ERR-14-024; `422` ERR-14-039.
:::

#### TC-14-062 · Tiếp nhận yêu cầu, chuyển luồng PH-04, trả phản hồi có ký <!--k:inbound-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-040, 041 · API-14-084 · UC-14-27 · BR-14-027, 028 · NFR-14-016.

**Tiền điều kiện, dữ liệu.** S-NDXP-IN; E-NDXP-IN `ACTIVE`; luồng `lg-nhan-tb` trả mẫu.

**Các bước.**

1. `POST /inbound/v1/ndxp-vao/tra-cuu-dan-cu` có chữ ký hợp lệ và `messageId` mới.
2. Xem giao dịch `INBOUND`.

**Kết quả mong đợi.** `200` phản hồi có chữ ký của tỉnh; luồng PH-04 nhận đúng một lần; tenant lấy từ điểm cuối, không từ thân; giao dịch `INBOUND` đủ `traceId`.
:::

#### TC-14-063 · Chiều vào bị từ chối: nguồn, mTLS, định dạng, lặp, tần suất, luồng lỗi <!--k:inbound-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-040, 041 · API-14-084 · ERR-14-119, 120, 121, 122, 123, 124 · BR-14-027, 028 · NFR-14-016.

**Tiền điều kiện, dữ liệu.** S-NDXP-LA; chứng thư mTLS hết hạn; `14.inbound.rate-limit-per-second = 50`; luồng PH-04 lỗi hoặc quá `14.inbound.timeout-ms`.

**Các bước.**

1. S-NDXP-LA gọi; gọi với chứng thư mTLS hết hạn.
2. Gửi bản tin thiếu chữ ký, và loại thông báo sai.
3. Gửi lại `messageId`; gửi lại cũ ngoài cửa sổ `14.inbound.replay-window-seconds`.
4. Gửi 80 lượt/giây trong 3 giây.
5. Bật luồng lỗi, rồi luồng chậm.

**Kết quả mong đợi.** `403` ERR-14-119; `401` ERR-14-120; `400` ERR-14-121; lặp `409` ERR-14-122; `429` ERR-14-123; `502` ERR-14-124. Từ chối ≤ 50 ms (p99), luồng PH-04 không nhận bản tin chưa xác minh.
:::

### TS-14-25 · Thông báo thay đổi từ quốc gia

**Mục tiêu.** Xác nhận thông báo đổi danh mục hay dịch vụ từ quốc gia sinh đề xuất cập nhật, không tự sửa cấu hình (Đợt 2).

**Phủ.** FR-14-042; UC-14-28; API-14-085; UI-14-10.

#### TC-14-064 · Nhận thông báo thay đổi và sinh đề xuất <!--k:notif-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-042 · API-14-085 · UC-14-28 · UI-14-10 · ERR-14-121.

**Tiền điều kiện, dữ liệu.** S-NDXP-IN; E-NDXP-IN.

**Các bước.**

1. `POST /inbound/v1/ndxp-vao/notifications` loại `CATALOG_CHANGED` hợp lệ.
2. Gửi loại thông báo không hỗ trợ.

**Kết quả mong đợi.** Bước 1 `202`, tạo đề xuất cho IE ở UI-14-10, cấu hình chưa đổi; bước 2 `400` ERR-14-121.
:::

### TS-14-26 · Đồng bộ: danh mục dịch vụ, dữ liệu chủ, dữ liệu mở

**Mục tiêu.** Xác nhận chỉ gửi dịch vụ chia sẻ `PUBLISHED` của đúng tenant, dữ liệu chủ và dữ liệu mở qua kiểm tra PH-07, PH-09.

**Phủ.** FR-14-043, 044, 045, 046; UC-14-29, 30, 31; API-14-053, 054, 055, 056, 057, 087, 088; UI-14-11; BR-14-010, 026, 035.

#### TC-14-065 · Đồng bộ danh mục dịch vụ lên Bộ, chỉ dịch vụ đã công bố <!--k:sync-catalog-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-043, 046 · API-14-053, 054, 055 · UI-14-11 · UC-14-29 · BR-14-035 · LGC-NGSP-006.

**Tiền điều kiện, dữ liệu.** U-T68-TO; 5 dịch vụ chia sẻ `PUBLISHED`, 2 `DRAFT`, 3 API nội bộ; `sim-ndxp` nhận đăng ký.

**Các bước.**

1. `POST /sync/catalog-runs`.
2. `GET /sync/runs/{runId}`; xem từng bản ghi ở UI-14-11.

**Kết quả mong đợi.** Chỉ 5 bản ghi gửi; không có API nội bộ hoặc dịch vụ tenant khác; phiên `SUCCEEDED`; lịch `14.sync.catalog-cron` chạy đúng.
:::

#### TC-14-066 · Đồng bộ lỗi: phiên trùng, bên nhận từ chối, phụ thuộc không khả dụng, thử lại <!--k:sync-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-043, 046 · API-14-054, 057, 053 · ERR-14-026, 027, 028, 004 · BR-14-026.

**Tiền điều kiện, dữ liệu.** Phiên đang chạy; `sim-ndxp` từ chối 1 bản ghi; PH-02 không khả dụng; `14.sync.stale-alert-days = 7`.

**Các bước.**

1. `POST /sync/catalog-runs` khi đang có phiên.
2. Chạy khi giả lập từ chối; `POST /sync/runs/{runId}:retry`.
3. Chạy khi PH-02 không khả dụng.
4. Không đồng bộ được 8 ngày giả lập.

**Kết quả mong đợi.** `409` ERR-14-026; phiên `PARTIAL`, bản ghi lỗi `422` ERR-14-028 thử lại được tối đa `14.sync.max-retries`, thử lại phiên đã xong `409` ERR-14-004; `502` ERR-14-027; cảnh báo tuân thủ ở ngày thứ 8.
:::

#### TC-14-067 · Dữ liệu chủ hai chiều: thiếu ánh xạ, PH-09 chặn <!--k:sync-master-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-044 · API-14-056 · UC-14-30 · ERR-14-125, 126 · BR-14-010.

**Tiền điều kiện, dữ liệu.** S-PH06; lô thiếu ánh xạ danh mục ở PH-07; lô có trường bị PH-09 cấm.

**Các bước.**

1. `POST /sync/master-data-runs` lô thiếu ánh xạ.
2. Chạy lô có trường cấm.

**Kết quả mong đợi.** `422` ERR-14-125, không gửi gì; `403` ERR-14-126, không gửi gì.
:::

#### TC-14-068 · Công bố và rút dữ liệu mở lên NDOP <!--k:open-data-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-045 · API-14-087, 088 · UC-14-31 · ERR-14-126, 028 · BR-14-010.

**Tiền điều kiện, dữ liệu.** U-T68-TA; tập dữ liệu đã qua PH-09; P-NDOP `ACTIVE`.

**Các bước.**

1. `POST /open-datasets` tập hợp lệ.
2. `POST /open-datasets/{datasetCode}:withdraw`.
3. Công bố tập có trường cá nhân.

**Kết quả mong đợi.** Công bố rồi rút thành công, có kiểm toán; bước 3 `403` ERR-14-126.
:::

### TS-14-27 · Tổng quan và kiểm tra kết nối chủ động

**Mục tiêu.** Xác nhận tổng quan phản ánh đúng sức khỏe, phát hiện mất kết nối ≤ 3 phút, giới hạn kiểm tra tay.

**Phủ.** FR-14-047, 048; UC-14-32; API-14-058, 059, 060; UI-14-01, 02; NFR-14-007.

#### TC-14-069 · Tổng quan, sức khỏe và phát hiện mất kết nối ≤ 3 phút <!--k:health-dash-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-047, 048 · API-14-058, 060 · UI-14-01, 02 · UC-14-32 · NFR-14-007, 018.

**Tiền điều kiện, dữ liệu.** U-T68-TO; `14.health.interval-seconds = 60`; `sim-ndxp` `OK` rồi `DOWN`.

**Các bước.**

1. `GET /dashboard`; mở UI-14-01.
2. Đặt `DOWN`; đo tới khi `health = UNHEALTHY`.

**Kết quả mong đợi.** Thẻ nền tảng, chỉ số 24 giờ, hạn mức kèm dự báo cạn, cảnh báo nổi bật; `UNHEALTHY` trong ≤ 3 phút và có cảnh báo; `GET /health` khớp.
:::

#### TC-14-070 · Kiểm tra tay vượt số lần mỗi giờ <!--k:probe-limit-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-047, 048 · API-14-059, 060 · ERR-14-029 · ERR-14-001.

**Tiền điều kiện, dữ liệu.** U-T68-TO; `14.test.max-per-hour = 5`.

**Các bước.**

1. Gọi `POST /platforms/ndxp:probe` 6 lần trong 1 giờ.
2. Gọi cho nền tảng của T01; U-T01-TA `GET /dashboard`.

**Kết quả mong đợi.** Lần 6 `429` ERR-14-029; bước 2 `404` ERR-14-001 và tổng quan của T01 chỉ có số liệu T01 (FR-14-048).
:::

### TS-14-28 · Giao dịch, đối soát, xem nội dung đầy đủ, xuất bằng chứng

**Mục tiêu.** Xác nhận mọi giao dịch tra được bằng mã đối soát; nội dung đầy đủ chỉ SO xem có lý do và xác thực nhiều yếu tố.

**Phủ.** FR-14-049, 050, 051; UC-14-33, 34; API-14-061, 062, 063, 064; UI-14-12; BR-14-020, 021.

#### TC-14-071 · Tra cứu giao dịch và dòng thời gian <!--k:txn-search-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-049 · API-14-061, 062 · UI-14-12 · UC-14-33 · BR-14-020 · LGC-NGSP-001.

**Tiền điều kiện, dữ liệu.** U-T68-AU; giao dịch `SUCCEEDED`, `FAILED`, `TIMEOUT`, `UNKNOWN_RESULT`, `COMPLETED_CACHE`.

**Các bước.**

1. Ô tra nhanh theo `transactionCode`.
2. Lọc theo HTTT, dịch vụ, trạng thái, khoảng thời gian.
3. Mở chi tiết.

**Kết quả mong đợi.** Kết quả đúng; chi tiết có dòng thời gian từng chặng, nội dung đã che; khoảng thời gian > 31 ngày `400` ERR-14-003; mã không có `404` ERR-14-001.
:::

#### TC-14-072 · Xem nội dung đầy đủ: lý do, xác thực lại, hết hạn lưu <!--k:txn-reveal-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-050 · API-14-063 · ERR-14-003, 030, 031 · BR-14-021 · PERM-14-audit-reveal · NFR-14-021.

**Tiền điều kiện, dữ liệu.** U-T68-SO, U-T68-AU; `14.txn.payload-retention-days = 30`; `14.reveal.max-per-day = 20`.

**Các bước.**

1. SO xem có lý do, đã xác thực nhiều yếu tố.
2. SO xem khi chưa xác thực lại; xem thiếu lý do.
3. SO xem giao dịch quá 30 ngày giả lập; giao dịch của T01.
4. U-T68-AU xem.
5. SO xem lần thứ 21 trong ngày.

**Kết quả mong đợi.** Bước 1 `200`, nội dung giải mã, ghi kiểm toán có lý do; bước 2 `403` ERR-14-030 và `400` ERR-14-003; bước 3 `404` ERR-14-031 và ERR-14-001; bước 4 `403`; bước 5 vẫn xem được nhưng phát cảnh báo.
:::

#### TC-14-073 · Xuất bằng chứng giao dịch <!--k:txn-evidence-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-051 · API-14-064 · UC-14-33 · ERR-14-003, 031 · BR-14-020.

**Tiền điều kiện, dữ liệu.** U-T68-SO; Đợt 2.

**Các bước.**

1. `POST /transactions:export-evidence` cho 10 giao dịch.
2. Xuất giao dịch quá hạn lưu nội dung; xuất không chọn giao dịch.

**Kết quả mong đợi.** Tệp có siêu dữ liệu, chữ ký, giá trị băm, không có giá trị mồi; bước 2 `404` ERR-14-031 cho nội dung, `400` ERR-14-003.
:::

### TS-14-29 · Nhật ký khai thác, cảnh báo bất thường, báo cáo

**Mục tiêu.** Xác nhận 100 % lượt gọi có nhật ký khai thác, phát hiện tra cứu hàng loạt.

**Phủ.** FR-14-052, 053, 057; UC-14-35, 36; API-14-065, 066, 067, 068, 069; UI-14-13; NFR-14-020.

#### TC-14-074 · Nhật ký khai thác theo HTTT, xuất báo cáo <!--k:usage-log-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-14-052 · API-14-065, 066 · UI-14-13 · UC-14-35 · NFR-14-020 · ERR-14-003.

**Tiền điều kiện, dữ liệu.** U-T68-AU; 1.000 lượt gọi mẫu của 3 HTTT.

**Các bước.**

1. `GET /usage` lọc theo HTTT, mục đích.
2. `POST /usage:export`; xuất khoảng thời gian không hợp lệ.

**Kết quả mong đợi.** Số dòng nhật ký bằng số giao dịch (100 %); tệp xuất không có DLCN; khoảng sai `400` ERR-14-003.
:::

#### TC-14-075 · Cảnh báo bất thường khai thác và xử lý <!--k:anomaly-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-053 · API-14-067, 068 · UC-14-35 · UI-14-13 · ERR-14-004, 001.

**Tiền điều kiện, dữ liệu.** U-T68-SO; `14.anomaly.lookups-per-hour = 500`; S-HT-MC tra 600 đối tượng khác nhau trong 1 giờ; Đợt 2.

**Các bước.**

1. Chạy tra hàng loạt rồi `GET /anomaly-alerts`.
2. `POST …/{alertId}:resolve` kèm kết luận; giải quyết lại; cảnh báo của T01.

**Kết quả mong đợi.** Cảnh báo tra cứu hàng loạt (THR-51) nêu HTTT, mục đích; `:resolve` ghi kiểm toán; lần hai `409` ERR-14-004; T01 `404` ERR-14-001.
:::

#### TC-14-076 · Báo cáo hạn mức và hiệu quả đệm <!--k:report-quota-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-14-057 · API-14-069 · UC-14-36 · UI-14-13 · NFR-14-005.

**Tiền điều kiện, dữ liệu.** U-T68-TA; 7 ngày dữ liệu đệm mẫu; Đợt 3.

**Các bước.**

1. `POST /reports/quota-efficiency` cho 7 ngày.

**Kết quả mong đợi.** Báo cáo có tỷ lệ trúng đệm theo dịch vụ, số lượt tiết kiệm, dự báo cạn hạn mức; số khớp `GET /cache/stats`.
:::

### TS-14-30 · Tham số phân hệ theo tenant

**Mục tiêu.** Xác nhận tham số đúng miền, tham số bảo mật cần người duyệt thứ hai, hiệu lực ≤ 30 giây.

**Phủ.** FR-14-054; UC-14-36; API-14-070, 071; UI-14-16, 17; BR-14-022; NFR-14-026.

#### TC-14-077 · Đổi tham số thường và tham số bảo mật <!--k:setting-change-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-054 · API-14-070, 071 · UI-14-16, 17 · UC-14-36 · BR-14-022 · NFR-14-026.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-IA.

**Các bước.**

1. `PUT /settings` đổi `14.retry.max-attempts` thành 3.
2. `PUT /settings` đổi `14.sign.max-skew-seconds` (★) thành 120; IA duyệt.

**Kết quả mong đợi.** Bước 1 hiệu lực ≤ 30 giây không khởi động lại; bước 2 chờ duyệt rồi hiệu lực; có nhãn bảo mật ở UI-14-16.
:::

#### TC-14-078 · Tham số ngoài miền, không có quyền, tự duyệt <!--k:setting-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-054 · API-14-071 · ERR-14-003, 007, 036 · BR-14-022.

**Tiền điều kiện, dữ liệu.** U-T68-TA; U-T68-IA2; U-T68-VW.

**Các bước.**

1. `PUT /settings` `14.timeout.default-ms = 90000`.
2. `PUT /settings` `14.cache.max-ttl-seconds` vượt trần.
3. U-T68-IA2 tự duyệt thay đổi tham số ★ mình đề nghị; U-T68-VW đổi tham số.

**Kết quả mong đợi.** `400` ERR-14-003; `422` ERR-14-036; `403` ERR-14-007; `403`.
:::

### TS-14-31 · Chuyển đổi từ hệ cũ: nhập cấu hình, chạy song song

**Mục tiêu.** Xác nhận nhập đúng cấu hình dịch vụ NGSP cũ, không di trú khóa cũ, chạy song song chỉ cho thao tác đọc.

**Phủ.** FR-14-055, 056; UC-14-37, 38; API-14-072, 073, 074, 089; UI-14-15; BR-14-033, 034; LGC-NGSP-008.

#### TC-14-079 · Nhập cấu hình dịch vụ từ phụ lục hệ cũ <!--k:import-legacy-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-14-056 · API-14-074 · UI-14-15 · UC-14-38 · ERR-14-032 · BR-14-034 · LGC-NGSP-008.

**Tiền điều kiện, dữ liệu.** U-T68-TA; tệp phụ lục NGSP cũ 20 dịch vụ có Consumer Key mồi; tệp lỗi dòng 7 sai cột.

**Các bước.**

1. `POST /migration/legacy-services:import` tệp hợp lệ.
2. Nhập tệp lỗi.

**Kết quả mong đợi.** 20 đề xuất dịch vụ, Consumer Key và Secret không được lưu (không có mồi trong CSDL, nhật ký), có nhắc cấp lại khóa và xác nhận thu hồi khóa cũ; tệp lỗi `422` ERR-14-032 chỉ rõ dòng 7, cột.
:::

#### TC-14-080 · Chạy song song, đối chiếu, sẵn sàng cắt chuyển <!--k:parallel-run-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-14-055 · API-14-072, 073, 089 · UI-14-15 · UC-14-37 · ERR-14-033 · BR-14-033 · LGC-NGSP-001.

**Tiền điều kiện, dữ liệu.** U-T68-TA; dịch vụ đọc V-LLTP; dịch vụ ghi V-HT-DK; hệ cũ giả lập; `14.parallel.match-ratio = 0,99`.

**Các bước.**

1. `POST /migration/parallel-runs` cho V-LLTP; `POST …/{runId}/observations` 1.000 mẫu, 995 khớp.
2. `GET /migration/parallel-runs/{runId}`.
3. Tạo phiên cho V-HT-DK; tạo phiên thứ hai cho V-LLTP.

**Kết quả mong đợi.** Tỷ lệ khớp 99,5 %, trạng thái sẵn sàng khi đủ `14.parallel.min-days` và `14.parallel.min-samples`; khác biệt chỉ cảnh báo, kết quả không bị sửa; bước 3 `409` ERR-14-033 hai lần.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Sáu kịch bản dưới đây kiểm các yêu cầu cắt ngang mọi chức năng: bí mật, tenant, quyền, hiệu năng, chịu lỗi, truy cập. Ca ở đây dùng bộ dữ liệu mục 2 và chạy sau khi các ca chức năng đạt.

### TS-14-32 · Không lộ bí mật và dữ liệu cá nhân

**Mục tiêu.** Xác nhận thông tin xác thực, khóa riêng và DLCN không xuất hiện ngoài OpenBao và nơi được phép.

**Phủ.** NFR-14-015; BR-14-004, 005, 021; SEC-31, 32, 37.

#### TC-14-081 · Dò mồi `DH-CANARY` ở mọi nơi có thể rò <!--k:canary-all-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** NFR-14-015 · BR-14-004, 005 · FR-14-025, 026, 050 · API-14-039, 063, 066 · ERR-14-127.

**Tiền điều kiện, dữ liệu.** Thông tin xác thực nền tảng, khóa chứng thư, hồ sơ BHXH đều mang mồi; chạy đủ TS-14-09…17, 28.

**Các bước.**

1. Quét phản hồi mọi API, nhật ký ứng dụng, vết OpenTelemetry, tệp xuất, sự kiện Kafka, bảng PostgreSQL, ảnh bộ nhớ pod.
2. Gây lỗi nội bộ có ngăn xếp (`ERR-14-127`).

**Kết quả mong đợi.** 0 mồi thông tin xác thực, khóa ở mọi nơi ngoài OpenBao; 0 mồi DLCN ngoài nội dung bản tin mã hóa; thân lỗi không có ngăn xếp.
:::

#### TC-14-082 · Nội dung bản tin mã hóa theo khóa tenant, thời hạn lưu <!--k:payload-encrypt-->

::: dac-ta
**Loại.** Bảo mật, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-14-021 · NFR-14-021 · FR-14-050 · SEC-33.

**Tiền điều kiện, dữ liệu.** `14.txn.payload-retention-days` 30 rồi 0.

**Các bước.**

1. Gọi dịch vụ, đọc bản ghi lưu nội dung ở CSDL.
2. Đặt 0, gọi lại; tiến đồng hồ 31 ngày.

**Kết quả mong đợi.** Nội dung là bản mã, giải bằng khóa tenant mới đọc được; đặt 0 thì không lưu; quá 30 ngày nội dung bị xóa, siêu dữ liệu giữ 5 năm.
:::

### TS-14-33 · Cách ly tenant và RLS

**Mục tiêu.** Xác nhận 0 rò rỉ chéo tenant ở API, CSDL, đệm, hạn mức, OpenBao, Kafka.

**Phủ.** NFR-14-024; BR-14-015, 027, 029; SEC-80, 82.

#### TC-14-083 · Bộ ca rò rỉ chéo tenant cho mọi API đọc và ghi <!--k:tenant-sweep-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-14-024 · BR-14-029 · ERR-14-001 · API-14-001, 003, 010, 012, 024, 029, 031, 041, 044, 048, 053, 055, 061, 062, 065, 067.

**Tiền điều kiện, dữ liệu.** T01 có đối tượng trùng mã với T68; token T68 và T01.

**Các bước.**

1. Với mỗi API đọc theo mã ở danh sách, dùng token T68 gọi mã chỉ có ở T01.
2. Dùng truy vấn danh sách, đếm số dòng của T01 lẫn vào.
3. Kết nối CSDL bằng vai trò ứng dụng T68, `SELECT` bảng của T01.

**Kết quả mong đợi.** `404` ERR-14-001 như đối tượng không tồn tại; 0 dòng T01 trong danh sách; RLS trả 0 dòng, `INSERT` chéo bị từ chối.
:::

#### TC-14-084 · Khóa đệm, bộ đếm, đường dẫn OpenBao, topic Kafka có tiền tố tenant <!--k:tenant-keys-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-14-024 · BR-14-015, 027 · API-14-084 · ERR-14-119.

**Tiền điều kiện, dữ liệu.** T68 và T01 cùng gọi `hotich-tra-cuu`; điểm cuối chiều vào của T01.

**Các bước.**

1. Liệt kê khóa Valkey, đường dẫn OpenBao, topic Kafka sau khi cả hai tenant chạy.
2. Gọi điểm cuối chiều vào của T01 bằng chứng thư nguồn của T68.

**Kết quả mong đợi.** Mọi khóa có tiền tố `t68.` hoặc `t01.`; bộ đếm hạn mức tách; bước 2 `403` ERR-14-119, tenant chỉ xác định từ điểm cuối đã đăng ký.
:::

#### TC-14-085 · Chỉ đi ra qua hồ sơ `national-gateway`, TLS và danh sách egress <!--k:egress-tls-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** BR-14-006 · NFR-14-014 · FR-14-010 · SEC-10, SEC-11.

**Tiền điều kiện, dữ liệu.** `national-gateway` 3 bản sao; danh sách egress chỉ có địa chỉ `sim-ndxp`; pod `dh-runtime` hồ sơ khác.

**Các bước.**

1. Từ pod hồ sơ khác và từ pod `national-gateway` thử kết nối tới địa chỉ ngoài danh sách.
2. Quét phiên bản TLS của kết nối tới `sim-ndxp` và NDOP; ép TLS 1.1.

**Kết quả mong đợi.** Chỉ `national-gateway` kết nối được đích trong danh sách; mọi đường khác bị chính sách mạng chặn (0 kết nối ngoài danh sách); TLS 1.3 ưu tiên, tối thiểu 1.2, mTLS khi nền tảng hỗ trợ; TLS 1.1 bị từ chối.
:::

### TS-14-34 · Phân quyền và tách nhiệm

**Mục tiêu.** Xác nhận ma trận quyền PERM-14 đúng ở API và giao diện, tài khoản máy chỉ có scope gọi.

**Phủ.** PERM-14-read, admin, service, route, approve, cert, quota, operate, sync, audit-read, audit-reveal, invoke; BR-14-007, 018, 022.

#### TC-14-086 · Ma trận quyền: vai trò × thao tác <!--k:perm-matrix-->

::: dac-ta
**Loại.** Bảo mật, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-14-003, 013, 028, 032, 050 · PERM-14-read · PERM-14-admin · PERM-14-service · PERM-14-route · PERM-14-approve · PERM-14-cert · PERM-14-quota · PERM-14-operate · PERM-14-sync · PERM-14-audit-read · PERM-14-audit-reveal · UI-14-17.

**Tiền điều kiện, dữ liệu.** Mọi người dùng mục 2.2; bảng tham số hóa theo FRS §3.2.

**Các bước.**

1. Với mỗi cặp (vai trò, thao tác), gọi API tương ứng và đối chiếu `200` hay `403`.
2. Mở UI-14-02, 08, 09, 17 bằng từng vai trò.

**Kết quả mong đợi.** Kết quả khớp ma trận FRS §3.2; giao diện ẩn nút không có quyền nhưng máy chủ vẫn `403` khi gọi thẳng; PA và vai trò kiểm toán không có đường vòng quyền duyệt.
:::

#### TC-14-087 · Tài khoản máy chỉ gọi, không quản trị; mã HTTT từ token <!--k:perm-invoke-->

::: dac-ta
**Loại.** Bảo mật, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** PERM-14-invoke · BR-14-007 · API-14-075, 001, 042 · ERR-14-106.

**Tiền điều kiện, dữ liệu.** S-HT-MC; S-HT-KHAC; token hết hạn; token thiếu scope.

**Các bước.**

1. S-HT-MC gọi `GET /platforms`, `POST /quotas`.
2. Gọi `invocations` bằng token hết hạn, token thiếu scope.
3. S-HT-KHAC gọi dịch vụ chưa cấp.

**Kết quả mong đợi.** `403` ở bước 1; `401` rồi `403` ở bước 2; `403` ERR-14-106 ở bước 3.
:::

### TS-14-35 · Hiệu năng, tải và quy mô

**Mục tiêu.** Xác nhận ngưỡng hiệu năng trên hồ sơ tỉnh vừa (GĐ-07); đo ở PERF với tenant `T90`.

**Phủ.** NFR-14-001, 002, 003, 004, 005, 006, 019, 025.

| Mã | Ca | Tải | Ngưỡng đạt | Truy vết |
|---|---|---|---|---|
| TC-14-088 | Chi phí xử lý thêm của PH-14 <!--k:perf-overhead--> | 500 lượt/giây, 30 phút, 3 bản sao, `sim-ndxp` trả ngay | p99 ≤ 80 ms | NFR-14-001, NFR-14-006 |
| TC-14-089 | Ký số và xác minh <!--k:perf-sign--> | Gatling từng chặng, OpenBao 3 nút | ký p99 ≤ 50 ms; xác minh p99 ≤ 30 ms | NFR-14-002, NFR-14-003 |
| TC-14-090 | Trúng đệm <!--k:perf-cache--> | 300 lượt/giây, mẫu truy vấn phân bố thực | p99 ≤ 15 ms; tỷ lệ trúng ≥ 60 % | NFR-14-004, NFR-14-005 |
| TC-14-091 | Thông lượng một tenant ở cao điểm <!--k:perf-tenant--> | 300 lượt/giây, hạn mức đủ, tuân thủ ưu tiên | không suy giảm, 0 lỗi do PH-14 | NFR-14-006 |
| TC-14-092 | Quy mô mỗi tenant <!--k:perf-scale--> | 10 nền tảng, 300 dịch vụ, 1.000 luật, 20 chứng thư, 50 điểm cuối; API điều khiển | đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | NFR-14-019, NFR-14-025, FR-14-004, FR-14-013 |

: Ca hiệu năng của PH-14

### TS-14-36 · Chịu lỗi và phục hồi

**Mục tiêu.** Xác nhận phục hồi khi quốc gia, OpenBao hay một bản sao sự cố, không mất bản tin.

**Phủ.** NFR-14-007, 008, 009, 010, 011, 012, 017, 026; BR-14-030.

#### TC-14-093 · Hàng chờ giữ ≥ 100.000 bản tin khi quốc gia gián đoạn <!--k:resil-queue-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-14-011 · FR-14-016 · API-14-076 · ERR-14-118 · BR-14-030.

**Tiền điều kiện, dữ liệu.** `T90`; `sim-ndxp` `DOWN`; giả lập nhanh 72 giờ.

**Các bước.**

1. Gửi 100.000 yêu cầu bất đồng bộ.
2. Giữ `DOWN` 72 giờ giả lập; khôi phục.

**Kết quả mong đợi.** 0 bản tin mất, 0 bản tin gửi trùng; gửi lại hết theo thứ tự sau khôi phục; sự cố quá `14.queue.max-age-hours` đánh dấu `FAILED` có cảnh báo.
:::

#### TC-14-094 · Mất một bản sao, OpenBao chậm; nạp nóng; khả dụng <!--k:resil-replica-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos, k6.

**Truy vết.** NFR-14-008, 010, 012, 017, 026 · FR-14-033, 038.

**Tiền điều kiện, dữ liệu.** 3 bản sao trên 2 nút; tải 300 lượt/giây.

**Các bước.**

1. Xóa một bản sao, rồi một nút.
2. Đổi luật định tuyến, hạn mức, chứng thư khi đang tải.
3. Đo khả dụng 24 giờ ở đường gọi ra và chiều vào.

**Kết quả mong đợi.** Không lượt nào mất; bộ đếm hạn mức vẫn chính xác; cấu hình mới có hiệu lực ≤ 30 giây không khởi động lại; khả dụng đường gọi ra ≥ 99,9 %, chiều vào ≥ 99,95 % (số liệu đo trên SIT, ngoại suy theo tháng).
:::

#### TC-14-095 · Kho chống trùng (Valkey) không khả dụng thì từ chối thao tác ghi <!--k:dedup-down-->

::: dac-ta
**Loại.** Chịu lỗi, Âm.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-14-010, 016 · API-14-075, 076 · ERR-14-133 · BR-14-030.

**Tiền điều kiện, dữ liệu.** S-HT-MC; V-HT-DK; dừng Valkey.

**Các bước.**

1. Gọi thao tác ghi có `Idempotency-Key`.
2. Gọi thao tác đọc không đệm.
3. Khôi phục Valkey, gọi lại ghi.

**Kết quả mong đợi.** Bước 1 `503` ERR-14-133, quốc gia nhận 0 bản tin (đóng an toàn, không gửi trùng); bước 2 vẫn chạy được; bước 3 thành công.
:::

### TS-14-37 · Truy cập, giao diện, truy vết, hợp đồng API

**Mục tiêu.** Xác nhận 17 màn đạt WCAG 2.2 AA, mọi giao dịch truy vết được, hợp đồng API tương thích.

**Phủ.** NFR-14-020, 021, 022, 023; UI-14-01…17.

#### TC-14-096 · 17 màn hình: axe-core, bàn phím, trạng thái chuẩn <!--k:a11y-all-->

::: dac-ta
**Loại.** Trợ năng.

**Ưu tiên.** P2.

**Tự động.** E2E, Thủ công.

**Truy vết.** NFR-14-023 · UI-14-01, UI-14-02, UI-14-03, UI-14-04, UI-14-05, UI-14-06, UI-14-07, UI-14-08, UI-14-09, UI-14-10, UI-14-11, UI-14-12, UI-14-13, UI-14-14, UI-14-15, UI-14-16, UI-14-17.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu mục 2; trình đọc màn hình NVDA.

**Các bước.**

1. Chạy axe-core trên từng màn ở trạng thái rỗng, đang tải, lỗi, có dữ liệu.
2. Duyệt chỉ bằng bàn phím: tab, mở hộp thoại duyệt, chọn dòng.
3. Kiểm tương phản ở lớp kính điều hướng và nền đặc ở bảng dày.

**Kết quả mong đợi.** 0 vi phạm mức nghiêm trọng, tương phản ≥ 4,5:1; thứ tự tab đúng, có bẫy tiêu điểm ở hộp thoại; trạng thái sức khỏe không chỉ dựa vào màu.
:::

#### TC-14-097 · Truy vết 100 % giao dịch, lưu giữ 5 năm, hợp đồng API v1 <!--k:trace-contract-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** NFR-14-020, 021, 022 · FR-14-049, 052 · API-14-062, 065 · EVT-14-01.

**Tiền điều kiện, dữ liệu.** 1.000 giao dịch qua PH-04; schema sự kiện ở Apicurio.

**Các bước.**

1. Đối chiếu `transactionCode`, `traceId` của từng giao dịch với PH-04, PH-13.
2. Kiểm vòng đời lưu giữ: 12 tháng trực tuyến, phần còn lại ở kho WORM.
3. Chạy Schemathesis; thêm trường bắt buộc vào sự kiện.

**Kết quả mong đợi.** 100 % có đủ ba mã; không xóa siêu dữ liệu trước 5 năm; API chỉ thêm trường tùy chọn; sự kiện đổi không BACKWARD bị Apicurio từ chối.
:::

## 6. Thủ tục kiểm thử thủ công

Các ca không tự động hóa được hoặc cần con người đánh giá; chạy ở SIT trước UAT.

### 6.1. Kiểm thử khám phá theo phiên

Phiên 90 phút cho từng nhóm FR A đến I: bắt đầu từ UI-14-01, đi theo nhiệm vụ của vai trò (TO xử lý nền tảng mất kết nối, SO xử lý sự cố chữ ký, TA xử lý hạn mức sắp cạn). Ghi lỗi, ca mới đưa vào mục 4 ở bản sau.

### 6.2. Diễn tập chuyển từ kết nối NGSP cũ

Chạy trên UAT: nhập phụ lục NGSP (TS-14-31), cấp khóa mới, chạy song song 7 ngày, xác nhận khóa cũ đã thu hồi ở trung ương, cắt chuyển từng nhóm dịch vụ; kiểm tra khôi phục về hệ cũ trong 15 phút (giả định, cần cơ sở ở D04).

### 6.3. Diễn tập sự cố

Ba tình huống: chữ ký phản hồi sai liên tục (TS-14-20), chứng thư ký hết hạn khi chưa có thay thế (TS-14-19), OpenBao mất (TS-14-17). Đo thời gian từ cảnh báo tới xử lý; SO thực hiện không cần hướng dẫn ngoài sổ tay vận hành.

### 6.4. Kiểm thử truy cập thủ công

NVDA và bàn phím trên UI-14-01, 03, 09, 12, 17; kiểm màn có biểu đồ dự báo cạn hạn mức có phương án bảng thay thế.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ vận hành và cán bộ HTTT của tỉnh thí điểm tự thực hiện trên UAT. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn kết nối NGSP cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Tra danh sách hồ sơ, trạng thái lý lịch tư pháp; đăng ký và tra kết quả hộ tịch | LGC-NGSP-001, LGC-NGSP-002 | Cùng dữ liệu như hệ cũ, HTTT chỉ gọi một API, không giữ khóa | FR-14-017, 018 | TS-14-12 |
| UAT-02 | Tra dữ liệu bảo hiểm xã hội của hộ gia đình | LGC-NGSP-003 | Có mục đích, mã hồ sơ; chỉ trường cần thiết | FR-14-019, 011 | TS-14-13, 10 |
| UAT-03 | Lấy danh sách hồ sơ cấp mã ĐVQHNS theo khoảng thời gian | LGC-NGSP-004 | Đủ hồ sơ, không phải tự phân trang | FR-14-020 | TS-14-14 |
| UAT-04 | Tra dữ liệu đăng ký doanh nghiệp mới nhất và hồ sơ trong ngày | LGC-NGSP-005 | Kết quả đúng, lượt lặp nhanh hơn nhờ đệm | FR-14-021, 035 | TS-14-14, 22 |
| UAT-05 | Tìm văn bản quy phạm pháp luật theo lĩnh vực, cơ quan, người ký | LGC-NGSP-007 | Đủ tiêu chí tìm như hệ cũ | FR-14-022 | TS-14-14 |
| UAT-06 | Kéo danh mục dùng chung quốc gia về PH-07 | LGC-NGSP-006, LGC-DMDC-019 | Danh sách, cấu trúc, dữ liệu, đề xuất bổ sung đầy đủ | FR-14-023, 007 | TS-14-15, 06 |
| UAT-07 | Lấy token và xoay thông tin xác thực mà không còn thấy Consumer Key | LGC-NGSP-008 | Không cần giữ khóa ở HTTT; xoay không gián đoạn | FR-14-024, 025 | TS-14-16 |
| UAT-08 | Nhập cấu hình dịch vụ từ phụ lục NGSP cũ | LGC-NGSP-008 | Có đề xuất dịch vụ; chỉ phải cấp lại khóa | FR-14-056 | TS-14-31 |
| UAT-09 | Chạy song song với kết nối cũ và đọc bảng khớp | LGC-NGSP-001, LGC-NGSP-003 | Thấy tỷ lệ khớp, khác biệt chỉ cảnh báo | FR-14-055 | TS-14-31 |
| UAT-10 | Tìm một giao dịch lỗi và xem nguyên nhân | LGC-NGSP-001 | Thấy trong 3 thao tác từ menu; nội dung che đúng quyền | FR-14-049, 050 | TS-14-28 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

Sinh tự động bằng `ph14/tools/gen_matrix.py` từ chính các ca ở mục 4 và 5.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-14. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph14/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-14-001 | Liệt kê nền tảng quốc gia, trạng thái và mức sức khỏe | M | mới | 001 | 004 | — | Có |
| FR-14-002 | Khai báo nền tảng quốc gia và gắn kết nối PH-05 | M | LGC-NGSP-008 | 002 | 003 | — | Có |
| FR-14-003 | Bật, tạm ngừng, tiếp tục và ngừng dùng nền tảng | M | mới | 005, 008, 009 | 006, 007, 010, 086 | — | Có |
| FR-14-004 | Liệt kê và tìm dịch vụ quốc gia | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 011 | 014 | 092 | Có |
| FR-14-005 | Khai báo và sửa dịch vụ quốc gia | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 012 | 013 | — | Có |
| FR-14-006 | Xem chi tiết dịch vụ, hợp đồng và nhãn đối chiếu | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 011 | 014 | — | Có |
| FR-14-007 | Đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 017 | 018 | — | Có |
| FR-14-008 | Nạp đặc tả dịch vụ có phiên bản và phát hiện lệch | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 015 | 016 | — | Có |
| FR-14-009 | Cung cấp lại dịch vụ quốc gia cho HTTT của tỉnh | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 019 | 020 | — | Có |
| FR-14-010 | Gọi dịch vụ quốc gia qua điểm gọi chung | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 023 | 025, 095 | 085 | Có |
| FR-14-011 | Kiểm tra mục đích khai thác và ủy quyền theo mục đích | M | mới | 028 | 029 | — | Có |
| FR-14-012 | Định tuyến tới nền tảng và dịch vụ đích | M | mới | 021 | 026 | — | Có |
| FR-14-013 | Quản lý bảng định tuyến | M | mới | 021 | 022, 086 | 092 | Có |
| FR-14-014 | Chuyển đổi bản tin theo hợp đồng dịch vụ | M | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 023 | 026 | — | Có |
| FR-14-015 | Phân loại và chuẩn hóa lỗi từ quốc gia | M | mới | 027 | 024 | — | Có |
| FR-14-016 | Gọi bất đồng bộ qua hàng chờ | M | LGC-NGSP-001, LGC-NGSP-002 | 030 | 031, 095 | 093 | Có |
| FR-14-017 | Bộ điều hợp tư pháp: lý lịch tư pháp | M | LGC-NGSP-001 | 032 | 026 | — | Có |
| FR-14-018 | Bộ điều hợp tư pháp: hộ tịch | M | LGC-NGSP-002 | 033 | 033 | — | Có |
| FR-14-019 | Bộ điều hợp bảo hiểm xã hội | M | LGC-NGSP-003 | 034 | 026, 035 | — | Có |
| FR-14-020 | Bộ điều hợp hồ sơ thủ tục cấp mã số ĐVQHNS | M | LGC-NGSP-004 | 036 | 026, 036 | — | Có |
| FR-14-021 | Bộ điều hợp đăng ký doanh nghiệp | M | LGC-NGSP-005 | 037 | 026 | — | Có |
| FR-14-022 | Bộ điều hợp văn bản quy phạm pháp luật | M | LGC-NGSP-007 | 037 | 026 | — | Có |
| FR-14-023 | Cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07 | M | LGC-DMDC-019, LGC-NGSP-006 | 038 | 039 | — | Có |
| FR-14-024 | Lấy và làm mới token OAuth 2.1 của nền tảng | M | LGC-NGSP-008 | 040 | 042 | — | Có |
| FR-14-025 | Xoay vòng và cấp lại thông tin xác thực | M | LGC-NGSP-008 | 041 | 042 | 081 | Có |
| FR-14-026 | Ký số bản tin gửi đi | M | mới | 023, 043 | 045 | 081 | Có |
| FR-14-027 | Xác minh chữ ký phản hồi | M | mới | 023, 043 | 044 | — | Có |
| FR-14-028 | Nạp và kích hoạt chứng thư số | M | mới | 046 | 047, 086 | — | Có |
| FR-14-029 | Theo dõi hạn chứng thư, cảnh báo và chuyển tiếp | M | mới | 048 | 050 | — | Có |
| FR-14-030 | Cập nhật chuỗi tin cậy và danh sách thu hồi | M | mới | 049 | 050 | — | Có |
| FR-14-031 | Xử lý sự cố chữ ký như sự cố an ninh | M | mới | 051 | 044, 052 | — | Có |
| FR-14-032 | Khai báo hạn mức do trung ương áp | M | mới | 053 | 054, 086 | — | Có |
| FR-14-033 | Đếm hạn mức, kiểm tra trước mỗi lượt gọi và cảnh báo ngưỡng | M | mới | 055 | 055 | 094 | Có |
| FR-14-034 | Phân bổ hạn mức theo HTTT và ưu tiên dịch vụ thiết yếu | M | mới | 053, 055 | 054, 055 | — | Có |
| FR-14-035 | Đệm phản hồi theo loại dữ liệu | M | mới | 056 | 056 | — | Có |
| FR-14-036 | Vô hiệu đệm | S | mới | 057 | 057 | — | Có |
| FR-14-037 | Dùng dữ liệu đệm quá hạn có cờ | M | mới | 057 | 057 | — | Có |
| FR-14-038 | Ngắt mạch và thử lại | M | mới | 027, 058, 059 | 058 | 094 | Có |
| FR-14-039 | Đăng ký điểm cuối chiều vào và nguồn được phép | M | mới | 060 | 061 | — | Có |
| FR-14-040 | Tiếp nhận yêu cầu từ nền tảng quốc gia | M | mới | 062 | 063 | — | Có |
| FR-14-041 | Chuyển cho luồng PH-04 và trả phản hồi có ký | M | LGC-NGSP-001 | 062 | 063 | — | Có |
| FR-14-042 | Tiếp nhận thông báo thay đổi từ quốc gia | S | mới | 064 | — | — | Có |
| FR-14-043 | Đồng bộ danh mục dịch vụ lên Bộ | M | mới | 065 | 066 | — | Có |
| FR-14-044 | Cầu nối đồng bộ dữ liệu chủ hai chiều | S | mới | — | 067 | — | Có |
| FR-14-045 | Công bố dữ liệu mở lên NDOP | S | mới | 068 | 068 | — | Có |
| FR-14-046 | Theo dõi trạng thái đồng bộ, xử lý lỗi và lệch | M | mới | 065 | 066 | — | Có |
| FR-14-047 | Kiểm tra kết nối chủ động | M | mới | 005, 069 | 070 | — | Có |
| FR-14-048 | Tổng quan kết nối quốc gia | M | mới | 069 | 070 | — | Có |
| FR-14-049 | Tra cứu và đối soát giao dịch | M | mới | 071, 097 | 071 | — | Có |
| FR-14-050 | Xem nội dung bản tin đầy đủ có lý do | M | mới | 072 | 072, 086 | 081, 082 | Có |
| FR-14-051 | Xuất bằng chứng giao dịch | S | mới | 073 | 073 | — | Có |
| FR-14-052 | Nhật ký khai thác theo HTTT và báo cáo sử dụng | M | mới | 028, 074, 097 | 074 | — | Có |
| FR-14-053 | Cảnh báo bất thường khai thác | S | mới | 075 | — | — | Có |
| FR-14-054 | Tham số phân hệ theo tenant | M | mới | 077 | 078 | — | Có |
| FR-14-055 | Chạy song song với kết nối NGSP cũ và đối chiếu | S | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 080 | 080 | — | Có |
| FR-14-056 | Nhập cấu hình dịch vụ từ hệ cũ | S | LGC-NGSP-001, LGC-NGSP-002, LGC-NGSP-003… | 079 | 079 | — | Có |
| FR-14-057 | Báo cáo hạn mức và hiệu quả đệm | C | mới | 076 | — | — | Có |

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng kết nối NGSP của hệ cũ (`LGC-NGSP`) và danh mục dùng chung quốc gia (`LGC-DMDC-019`) được truy tới FR mới, ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-DMDC-019 | 023 | 038 | UAT-06 |
| LGC-NGSP-001 | 004, 005, 006, 007, 008, 009, 010, 014, 016, 017, 041, 055, 056 | 030, 032, 062, 071, 080 | UAT-01, UAT-09, UAT-10 |
| LGC-NGSP-002 | 004, 005, 006, 007, 008, 009, 010, 014, 016, 018, 055, 056 | 030, 033 | UAT-01 |
| LGC-NGSP-003 | 004, 005, 006, 007, 008, 009, 010, 014, 019, 055, 056 | 034 | UAT-02, UAT-09 |
| LGC-NGSP-004 | 004, 005, 006, 007, 008, 009, 010, 014, 020, 055, 056 | 036 | UAT-03 |
| LGC-NGSP-005 | 004, 005, 006, 007, 008, 009, 010, 014, 021, 055, 056 | 037 | UAT-04 |
| LGC-NGSP-006 | 004, 005, 006, 007, 008, 009, 010, 014, 023, 055, 056 | 038, 065 | UAT-06 |
| LGC-NGSP-007 | 004, 005, 006, 007, 008, 009, 010, 014, 022, 055, 056 | 037 | UAT-05 |
| LGC-NGSP-008 | 002, 007, 024, 025, 055, 056 | 002, 040, 041, 079 | UAT-07, UAT-08 |

### 8.3. Quy tắc nghiệp vụ → test case

| Mã | Test case |
|---|---|
| BR-14-001 | 030, 043, 045 |
| BR-14-002 | 043, 044, 049 |
| BR-14-003 | 044, 051 |
| BR-14-004 | 043, 081 |
| BR-14-005 | 040, 041, 081 |
| BR-14-006 | 085 |
| BR-14-007 | 019, 023, 087 |
| BR-14-008 | 028, 029 |
| BR-14-009 | 019, 028, 034 |
| BR-14-010 | 067, 068 |
| BR-14-011 | 053 |
| BR-14-012 | 055 |
| BR-14-013 | 055 |
| BR-14-014 | 013, 034, 056 |
| BR-14-015 | 056, 084 |
| BR-14-016 | 057 |
| BR-14-017 | 045, 048, 050 |
| BR-14-018 | 046, 047, 050 |
| BR-14-019 | 047 |
| BR-14-020 | 023, 071, 073 |
| BR-14-021 | 072, 082 |
| BR-14-022 | 005, 007, 021, 053, 077, 078 |
| BR-14-023 | 022 |
| BR-14-024 | 016, 017 |
| BR-14-025 | 002, 003, 012 |
| BR-14-026 | 066 |
| BR-14-027 | 060, 062, 063, 084 |
| BR-14-028 | 062, 063 |
| BR-14-029 | 004, 014, 083 |
| BR-14-030 | 025, 059, 093, 095 |
| BR-14-031 | 025, 027, 042, 058, 059 |
| BR-14-032 | 008, 009 |
| BR-14-033 | 080 |
| BR-14-034 | 079 |
| BR-14-035 | 065 |
| BR-14-036 | 038, 039 |
| BR-14-037 | 023, 026 |

### 8.4. Mã lỗi → test case

| Mã | Test case |
|---|---|
| ERR-14-001 | 004, 014, 018, 020, 039, 052, 070, 075, 083 |
| ERR-14-002 | 003, 009, 013 |
| ERR-14-003 | 003, 013, 025, 036, 072, 073, 074, 078 |
| ERR-14-004 | 006, 010, 013, 018, 042, 052, 057, 059, 066, 075 |
| ERR-14-005 | 003 |
| ERR-14-006 | 006 |
| ERR-14-007 | 007, 022, 047, 050, 078 |
| ERR-14-008 | 006 |
| ERR-14-009 | 013 |
| ERR-14-010 | 016 |
| ERR-14-011 | 016 |
| ERR-14-012 | 016 |
| ERR-14-013 | 022 |
| ERR-14-014 | 022 |
| ERR-14-015 | 022 |
| ERR-14-016 | 054 |
| ERR-14-017 | 054 |
| ERR-14-018 | 054 |
| ERR-14-019 | 047, 050 |
| ERR-14-020 | 047 |
| ERR-14-021 | 047 |
| ERR-14-022 | 047 |
| ERR-14-023 | 061 |
| ERR-14-024 | 061 |
| ERR-14-025 | 020 |
| ERR-14-026 | 018, 066 |
| ERR-14-027 | 039, 066 |
| ERR-14-028 | 066, 068 |
| ERR-14-029 | 070 |
| ERR-14-030 | 072 |
| ERR-14-031 | 072, 073 |
| ERR-14-032 | 079 |
| ERR-14-033 | 080 |
| ERR-14-034 | 042 |
| ERR-14-035 | 042, 045 |
| ERR-14-036 | 013, 078 |
| ERR-14-037 | 045 |
| ERR-14-038 | 013 |
| ERR-14-039 | 061 |
| ERR-14-101 | 024 |
| ERR-14-102 | 024, 026, 033 |
| ERR-14-103 | 057, 058, 059 |
| ERR-14-104 | 055 |
| ERR-14-105 | 025, 026 |
| ERR-14-106 | 029, 087 |
| ERR-14-107 | 029 |
| ERR-14-108 | 025, 026, 033, 035 |
| ERR-14-109 | 044, 051 |
| ERR-14-110 | 044, 049 |
| ERR-14-111 | 044 |
| ERR-14-112 | 045 |
| ERR-14-113 | 045, 050 |
| ERR-14-114 | 042 |
| ERR-14-115 | 024 |
| ERR-14-116 | 025 |
| ERR-14-117 | 008, 009, 025 |
| ERR-14-118 | 031, 093 |
| ERR-14-119 | 063, 084 |
| ERR-14-120 | 063 |
| ERR-14-121 | 063, 064 |
| ERR-14-122 | 063 |
| ERR-14-123 | 063 |
| ERR-14-124 | 063 |
| ERR-14-125 | 067 |
| ERR-14-126 | 067, 068 |
| ERR-14-127 | 024, 081 |
| ERR-14-128 | 024, 036 |
| ERR-14-129 | 031 |
| ERR-14-130 | 031 |
| ERR-14-131 | 016 |
| ERR-14-132 | 029 |
| ERR-14-133 | 095 |

### 8.5. Yêu cầu phi chức năng → test case

| Mã | Test case |
|---|---|
| NFR-14-001 | 088 |
| NFR-14-002 | 043, 089 |
| NFR-14-003 | 043, 089 |
| NFR-14-004 | 037, 056, 090 |
| NFR-14-005 | 076, 090 |
| NFR-14-006 | 088, 091 |
| NFR-14-007 | 069 |
| NFR-14-008 | 094 |
| NFR-14-009 | 024, 057, 058 |
| NFR-14-010 | 045, 094 |
| NFR-14-011 | 031, 093 |
| NFR-14-012 | 094 |
| NFR-14-013 | 023, 043 |
| NFR-14-014 | 085 |
| NFR-14-015 | 041, 081 |
| NFR-14-016 | 062, 063 |
| NFR-14-017 | 008, 094 |
| NFR-14-018 | 044, 048, 055, 069 |
| NFR-14-019 | 092 |
| NFR-14-020 | 023, 074, 097 |
| NFR-14-021 | 072, 082, 097 |
| NFR-14-022 | 097 |
| NFR-14-023 | 096 |
| NFR-14-024 | 004, 029, 056, 083, 084 |
| NFR-14-025 | 092 |
| NFR-14-026 | 077, 094 |
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Mã kiểm thử đặt ở `dh-integration/national/src/test` (API, RLS, hợp đồng), `dh-runtime/national-gateway/src/test` (ký, đệm, hạn mức, ngắt mạch, chiều vào), `e2e/ph14` (Playwright), `perf/ph14` (Gatling, k6). Bộ giả lập `sim-ndxp` là một WireMock có tiện ích mở rộng ký và xác minh bằng chứng thư thử; cấu hình chế độ ở mục 1.3. Mỗi ca tự động mang nhãn `@TC-14-nnn` để báo cáo gộp theo ma trận.

### 9.2. Mẫu ca dò mồi (JUnit)

```java
@Test @Tag("TC-14-canary")
void khongLoMoiThongTinXacThuc() {
    var canary = "DH-CANARY-KEY-" + UUID.randomUUID();
    platform.rotateCredentials("ndxp", canary);
    invoke("lltp-tra-trang-thai", Map.of("dossierCode", "LLTP-2026-000123"));
    assertThat(scanner.findAll(canary, apiResponses, logs, traces, dbDump, kafka))
        .as("mồi chỉ được nằm ở OpenBao").isEmpty();
}
```

Đoạn mã chỉ minh họa cách dò; mã thật nằm ở `dh-integration/national/src/test`.

### 9.3. Sinh ma trận, Gherkin, bảng tính

| Lệnh | Kết quả |
|---|---|
| `python3 ph14/tools/number_tcs.py` | Cấp số `TC-14-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph14/tools/fill_doc.py` | Ghi bảng kịch bản, số ca và mục 8 vào tài liệu; in ra stderr BR, ERR, NFR chưa có ca |
| `python3 ph14/tools/gen_gherkin.py` | `ph14/gherkin/ts-14-nn.feature` và tệp UAT |
| `python3 ph14/tools/gen_xlsx.py` | `ph14/D05-02-PH14-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

## Đề nghị đồng bộ

1. D00-04 §3.2: chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để thêm TS, TC của PH-14 vào dải đã dùng.
2. D05-01 §môi trường: thêm bộ giả lập `sim-ndxp` (WireMock có ký) và tenant `T90` cho PERF của PH-14.
3. D05-01 cổng RG: bổ sung sáu nhóm ca bắt buộc 100 % của PH-14 (Tóm tắt) vào tiêu chí phát hành.
4. D02-08: mười quyền `PERM-14-*` đề nghị bổ sung ở FRS cần có trước khi chạy TS-14-34 ở UAT.

## Câu hỏi mở

> **Câu hỏi mở Q14-40:** Trung ương có cấp môi trường NDXP, NDOP thử cho tỉnh để chạy UAT với dịch vụ thật không, và có chứng thư thử, hạn mức thử riêng không? Giả định hiện tại: chỉ dùng `sim-ndxp` ở SIT, UAT dùng NDXP thử nếu được cấp.

> **Câu hỏi mở Q14-41:** Đơn vị nào cung cấp dữ liệu hồ sơ thủ tục và mã hồ sơ giả lập (không dùng dữ liệu cá nhân thật) cho UAT? Giả định: bộ sinh dữ liệu của dự án theo khuôn của trung ương.

> **Câu hỏi mở Q14-42:** Ngưỡng khả dụng 99,9 % và 99,95 % (NFR-14-008) đo trên SIT 24 giờ chỉ cho số ngoại suy; có cần chạy bền 30 ngày ở UAT trước nghiệm thu không? Giả định: chạy bền 7 ngày song song với TS-14-31.

> **Câu hỏi mở Q14-43:** Thời gian khôi phục về kết nối NGSP cũ khi cắt chuyển lỗi (diễn tập 6.2) lấy 15 phút theo giả định; cần chủ đầu tư và đơn vị vận hành hệ cũ xác nhận.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 37 kịch bản, test case theo ma trận FR, BR, ERR, NFR; 10 kịch bản nghiệm thu UAT; công cụ sinh ma trận, Gherkin, bảng tính tại `ph14/tools/` |
