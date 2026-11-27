---
ma_tai_lieu: D00-04
ten: Sổ tra cứu gọn cho người viết tài liệu phân hệ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Người viết tài liệu phân hệ (người và Claude), kiểm thử viên, kỹ sư
mo_ta: Sổ tra cứu gọn cho người viết tài liệu phân hệ về mã đã dùng, số kế tiếp, quy ước đặt tên và các quyết định đã chốt, để không phải đọc lại tài liệu gốc.
tai_lieu_lien_quan: D00-01 Thuật ngữ và quy ước; D00-02 Sổ ADR; D00-03 Ma trận truy vết; D03-01 SAD; khuon/; build/tools/kiem_tra_ma.py
---

# D00-04 · Sổ tra cứu gọn cho người viết tài liệu phân hệ

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Sổ gom vào vài trang những gì người viết tập phân hệ cần biết trước khi viết: mã đã dùng, số kế tiếp, quy ước đặt tên và quyết định đã chốt, để các luồng viết song song không trùng mã và không mở lại tài liệu gốc.

**Phạm vi.** Sổ chỉ tóm tắt, không định nghĩa mới; định nghĩa gốc ở D00-01, D00-02 và D03-01. Bảng dải mã đã dùng ở mục 3.2 được sinh tự động từ bộ tài liệu.

**Căn cứ.** D00-01 §3, §6, §7 (mã truy vết và văn bản CMP-LAW) và nhật ký quyết định D00-02 §5.

**Những điểm hội đồng cần lưu ý.** (1) Sổ không thay thế tài liệu gốc; khi lệch thì tài liệu gốc đúng. (2) Dải mã đã dùng được sinh bằng script `kiem_tra_ma.py` và kiểm tra trong CI nên số kế tiếp đáng tin. (3) Mục 5 chỉ ghi quyết định đã chốt; câu hỏi còn mở nằm ở tài liệu của từng phân hệ.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Phân hệ | 20 (12 MVP, 4 đợt 2, 4 đợt 3) |
| Phân hệ đã đủ bảy tập | 4 (PH-04, 05, 07, 10) |
| Chủ đề quyết định đã chốt | 9 |

: Con số chính của sổ tra cứu gọn

## Giới thiệu tài liệu

### Mục đích

Giúp người viết tra nhanh mã, quy ước và quyết định trước khi viết một tập phân hệ.

### Phạm vi

Tóm tắt từ D00-01, D00-02, SRS, SAD và bộ khuôn; không thêm quy ước mới.

### Người đọc

Người viết tập phân hệ (người và Claude), kiểm thử viên và kỹ sư đọc mục 1 đến 5; hội đồng thẩm định chỉ cần Tóm tắt và mục 5.

### Thuật ngữ và chữ viết tắt

Sổ không có thuật ngữ riêng; thuật ngữ chung theo D00-01 §2.

### Tài liệu tham chiếu

D00-01 (mã, kiểu, quy ước), D00-02 (ADR, nhật ký), D03-01 (phân hệ, DU), D03-07 (SEC), `khuon/` (khuôn tập phân hệ), `build/tools/kiem_tra_ma.py` (sinh dải mã).

### Cấu trúc tài liệu

Sổ gồm sáu chương theo thứ tự người viết cần tra.

| Chương | Nội dung |
|---|---|
| 1 | Cách dùng: tài liệu gốc cần mở theo từng loại thông tin |
| 2 | Phân hệ, DU và tình trạng tài liệu |
| 3 | Dải mã cấp trước và dải đã dùng |
| 4 | Quy ước đặt tên và trình bày |
| 5 | Quyết định đã chốt |
| 6 | Kiểm tra tự động |

: Cấu trúc chương của D00-04

## 1. Cách dùng

Sổ này gom vào hai, ba trang những gì một luồng viết tập phân hệ cần biết trước khi viết: mã nào đã dùng, số kế tiếp còn trống, quy ước đặt tên và các quyết định đã chốt. Người viết **đọc sổ này thay cho việc đọc lại** D00-01, SRS, SAD, các ADR và bộ mẫu PH-07. Chỉ mở tài liệu gốc khi cần đúng một chi tiết, theo cột "Mở khi cần" ở bảng dưới, và chỉ đọc mục được chỉ.

Bảng sau cho biết khi cần một chi tiết thì mở tài liệu nào, mục nào.

| Cần | Mở khi cần | Mục |
|---|---|---|
| Định nghĩa đầy đủ một họ mã, quy tắc truy vết | D00-01 | §3 |
| Kiểu dữ liệu chuẩn (`T-ID`, `T-CODE`, `T-TS`, `T-MONEY`…) và cột ngữ cảnh bắt buộc | D00-01 | §5, §5.1 |
| Văn bản pháp lý `CMP-LAW-01…20` | D00-01 | §7 |
| Nội dung một ADR | `00-chung/adr/ADR-{nnn}-*.md` | cả tệp (ngắn) |
| FR-00, NFR-00 dùng chung (đăng nhập, danh sách, kiểm toán, truy cập) | D02-02 SRS | §3, §4 |
| Vai trò `ROLE-*`, quyền `PERM-*` | D02-08 | bảng theo PH |
| Thực thể dùng chung `DD-*` | D02-07 | bảng DD |
| Phân hệ, DU, vùng mạng, luồng dữ liệu | D03-01 SAD | §4 |
| Biện pháp `SEC-*`, tài sản `AS-*`, đe dọa `THR-*` | D03-07 | bảng SEC |
| Token, thành phần `CMP-*` | D03-05-02, D03-05-03, D03-05-04 | mục theo tên |
| Cây menu, route, mẫu màn `PTN-*`, trạng thái chuẩn | D03-06-00 | §2.3, §2.4, §4 |
| Khuôn tập phân hệ | [`khuon/`](khuon/README.md) | một tệp theo loại |
| Ví dụ đầy đủ khi khuôn chưa đủ rõ | Tập PH-07 hoặc PH-04 tương ứng | chỉ mục cần xem |

: Tài liệu gốc cần mở theo từng loại thông tin

## 2. Phân hệ, DU và tài liệu đã có

Bảng dưới nối phân hệ với DU triển khai (D03-01 §4.1), đợt và tình trạng tài liệu ngày 26/11/2026. Package Java là `vn.datahub.{du}.{module}`.

| PH | Tên | DU | Đợt | Tài liệu |
|---|---|---|---|---|
| 01 | Kết nạp HTTT | `dh-connect` | MVP | chưa |
| 02 | Danh mục dịch vụ | `dh-connect` | MVP | chưa |
| 03 | Cổng API | `apisix`, `dh-connect` | MVP | chưa |
| 04 | Lõi tích hợp, trình thiết kế luồng | `dh-integration`, `dh-runtime` | MVP | đủ bảy tập 0.2 |
| 05 | Bộ điều hợp | `dh-integration`, `dh-runtime` | MVP | đủ bảy tập 0.1 |
| 06 | Dữ liệu chủ | `dh-data` | Đợt 3 | đủ bảy tập (FRS 0.2) |
| 07 | Danh mục dùng chung | `dh-data` | MVP | đủ bảy tập 0.3 (mẫu) |
| 08 | Chất lượng dữ liệu | `dh-data` | Đợt 3 | đủ bảy tập 0.2 |
| 09 | Quyền riêng tư | `dh-data` | Đợt 2 | đủ bảy tập (FRS 0.2) |
| 10 | Sự kiện | `dh-integration`, `dh-runtime`, `kafka` | MVP | đủ bảy tập (FRS 0.3) |
| 11 | Quy trình liên thông | `dh-platform` | Đợt 2 | đủ bảy tập (FRS 0.2, CSDL 0.4) |
| 12 | Định danh và phân quyền | `keycloak`, `opa`, `dh-platform` | MVP | chưa |
| 13 | Giám sát và kiểm toán | `dh-platform`, LGTM | MVP | chưa |
| 14 | Kết nối quốc gia | `dh-runtime`, `dh-integration` | MVP | chưa |
| 15 | Cổng nhà phát triển | `dh-portal`, `dh-connect` | Đợt 2 | chưa |
| 16 | Báo cáo chỉ tiêu và sổ kiến trúc | `dh-platform` | Đợt 3 | đủ bảy tập (FRS 0.2) |
| 17 | Trợ lý AI | `dh-assist` | Đợt 3 | đủ bảy tập (FRS 0.2) |
| 18 | Vận hành và xử lý lỗi | `dh-platform` | MVP | đủ bảy tập (FRS 0.2) |
| 19 | Thanh toán | `dh-payment` | Đợt 2 | BRD, khung truy vết (luồng riêng) |
| 20 | Quản trị tenant | `dh-platform` | MVP | chưa |

: Phân hệ, DU triển khai, đợt và tình trạng tài liệu

## 3. Dải mã đã cấp và số kế tiếp

### 3.1. Dải cấp trước theo nhóm

Các dải dưới đây được cấp trước để các luồng viết song song không trùng số. Luồng nào cần thêm thì lấy số kế tiếp trong dải của mình.

| Họ | Dải | Ghi chú |
|---|---|---|
| ADR | 001–019 lõi · 020–029 giao diện · 030–039 ATTT, hạ tầng · 040–049 PH-19 · 050–059 PH-07 và khác · 060–069 PH-04, PH-05 · 070–074 PH-10 · 080–084 PH-06 · 085–089 PH-08 · 090–094 PH-09 (đề xuất, chưa có tệp) · 160–164 PH-16 (đề xuất, chưa có tệp) · 180–184 PH-18 | 014–019, 024–029, 039, 074 còn trống. ADR-016 là mã cũ của repo (shadcn), đã bị ADR-020 thay |
| SEC | 01–09 quản trị · 10–19 mạng · 20–29 IAM · 30–39 dữ liệu · 40–49 ứng dụng · 50–59 nền tảng · 60–67 giám sát · 70–75 sự cố · 80–88 tenant · 90–99 cấp độ 4 | Định nghĩa ở D03-07; tập phân hệ chỉ tham chiếu, không tạo mới |
| ERR-{PH} | 001–099 control plane · 101–199 runtime/data plane | Theo cách PH-04 (ERR-04-001…049, 101…112) |
| Câu hỏi mở | `Q{PH}-nn` theo tập: 01–19 FRS · 20–29 SDD · 30–39 màn hình · 40–44 test · 45–49 UC · 50–54 CSDL · 55–59 API | Theo cách PH-04. Câu hỏi cấp hệ thống: Q300–313 D03-07, Q320–329 D03-08, Q330–349 D03-09, Q350–359 D04, Q360–369 D05-01 |
| Giả định | GĐ-01…07 (sổ ở phụ lục D02-01): tỉnh T01 quy mô vừa, 200 HTTT | Thiếu số liệu thật thì dùng giả định có ghi cơ sở, không hỏi người dùng |
| Cổng | `CI-1…9` cổng CI (D04-02) · `RG-1…5` cổng phát hành kiểm thử (D05-01) · `G0…G5` cổng quản lý dự án (D01-02) | Không dùng G1/G2 cho cổng CI |
| Hạ tầng | `Z0…Z7` vùng mạng · `QM-NHO/VUA/LON/CHUNG` quy mô · `HT-A` on-prem, `HT-B` cloud dùng chung · `TPH-n` tầng phục hồi | D03-07, D03-09 |
| Tenant | Ví dụ trong tài liệu: `T68` (topic chữ thường `t68.`), `T01` cho giả định; `T90…T99` dành cho kiểm thử; `COMMON` là tenant toàn quốc | Không dùng tên tỉnh làm mã |
| Mẫu màn | `PTN-01…14` (D03-06-00 §4): 01 Danh sách · 02 Chi tiết · 03 Biểu mẫu trang · 04 Biểu mẫu nhanh · 05 Wizard · 06 Dashboard · 07 Designer · 08 Cây + bảng · 09 Nhập có xem trước · 10 Hộp việc, duyệt · 11 Giám sát, tra log · 12 Cài đặt · 13 Trang lỗi · 14 Tài liệu cổng | Tập màn phân hệ không tạo PTN mới |
| Thành phần | `CMP-*`: 44 nguyên tử (D03-05-03), 75 phức hợp (D03-05-04), 2 nền = 121 | Tập màn phân hệ không tự đặt CMP hay token; cần thêm thì ghi vào phụ lục "Đề nghị bổ sung cho D03-05" |

: Dải mã cấp trước cho từng họ mã

### 3.2. Dải đã dùng thực tế (sinh tự động)

Bảng sau được sinh từ chính bộ tài liệu, chỉ đếm mã đã được định nghĩa ở tài liệu gốc của nó. "Số kế tiếp" là số lớn nhất cộng một; dải có lỗ hổng (ví dụ API-04) vẫn lấy số kế tiếp sau số lớn nhất, không lấp lỗ. Chạy lại `python3 datahub-docs/build/tools/kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi thêm mã.

<!-- dai-ma:bat-dau (sinh bằng build/tools/kiem_tra_ma.py --cap-nhat-so-tra-cuu, không sửa tay) -->

| Họ mã | PH | Số mã | Thấp nhất | Cao nhất | Số kế tiếp còn trống |
|---|---|---|---|---|---|
| FR | 00 | 40 | `FR-00-001` | `FR-00-093` | `FR-00-094` |
| FR | 01 | 51 | `FR-01-001` | `FR-01-051` | `FR-01-052` |
| FR | 02 | 62 | `FR-02-001` | `FR-02-062` | `FR-02-063` |
| FR | 03 | 59 | `FR-03-001` | `FR-03-059` | `FR-03-060` |
| FR | 04 | 70 | `FR-04-001` | `FR-04-084` | `FR-04-085` |
| FR | 05 | 62 | `FR-05-001` | `FR-05-062` | `FR-05-063` |
| FR | 06 | 60 | `FR-06-001` | `FR-06-060` | `FR-06-061` |
| FR | 07 | 53 | `FR-07-001` | `FR-07-053` | `FR-07-054` |
| FR | 08 | 61 | `FR-08-001` | `FR-08-061` | `FR-08-062` |
| FR | 09 | 64 | `FR-09-001` | `FR-09-064` | `FR-09-065` |
| FR | 10 | 76 | `FR-10-001` | `FR-10-076` | `FR-10-077` |
| FR | 11 | 66 | `FR-11-001` | `FR-11-066` | `FR-11-067` |
| FR | 12 | 62 | `FR-12-001` | `FR-12-062` | `FR-12-063` |
| FR | 13 | 61 | `FR-13-001` | `FR-13-061` | `FR-13-062` |
| FR | 14 | 57 | `FR-14-001` | `FR-14-057` | `FR-14-058` |
| FR | 15 | 62 | `FR-15-001` | `FR-15-062` | `FR-15-063` |
| FR | 16 | 58 | `FR-16-001` | `FR-16-058` | `FR-16-059` |
| FR | 17 | 62 | `FR-17-001` | `FR-17-062` | `FR-17-063` |
| FR | 18 | 72 | `FR-18-001` | `FR-18-072` | `FR-18-073` |
| FR | 19 | 69 | `FR-19-001` | `FR-19-069` | `FR-19-070` |
| NFR | 00 | 43 | `NFR-00-001` | `NFR-00-062` | `NFR-00-063` |
| NFR | 01 | 22 | `NFR-01-001` | `NFR-01-022` | `NFR-01-023` |
| NFR | 02 | 22 | `NFR-02-001` | `NFR-02-022` | `NFR-02-023` |
| NFR | 03 | 27 | `NFR-03-001` | `NFR-03-027` | `NFR-03-028` |
| NFR | 04 | 17 | `NFR-04-001` | `NFR-04-017` | `NFR-04-018` |
| NFR | 05 | 16 | `NFR-05-001` | `NFR-05-016` | `NFR-05-017` |
| NFR | 06 | 20 | `NFR-06-001` | `NFR-06-020` | `NFR-06-021` |
| NFR | 07 | 15 | `NFR-07-001` | `NFR-07-015` | `NFR-07-016` |
| NFR | 08 | 20 | `NFR-08-001` | `NFR-08-020` | `NFR-08-021` |
| NFR | 09 | 26 | `NFR-09-001` | `NFR-09-026` | `NFR-09-027` |
| NFR | 10 | 20 | `NFR-10-001` | `NFR-10-020` | `NFR-10-021` |
| NFR | 11 | 24 | `NFR-11-001` | `NFR-11-024` | `NFR-11-025` |
| NFR | 12 | 33 | `NFR-12-001` | `NFR-12-033` | `NFR-12-034` |
| NFR | 13 | 31 | `NFR-13-001` | `NFR-13-031` | `NFR-13-032` |
| NFR | 14 | 26 | `NFR-14-001` | `NFR-14-026` | `NFR-14-027` |
| NFR | 15 | 22 | `NFR-15-001` | `NFR-15-022` | `NFR-15-023` |
| NFR | 16 | 22 | `NFR-16-001` | `NFR-16-022` | `NFR-16-023` |
| NFR | 17 | 28 | `NFR-17-001` | `NFR-17-028` | `NFR-17-029` |
| NFR | 18 | 22 | `NFR-18-001` | `NFR-18-022` | `NFR-18-023` |
| NFR | 19 | 32 | `NFR-19-001` | `NFR-19-032` | `NFR-19-033` |
| BR | 01 | 34 | `BR-01-001` | `BR-01-034` | `BR-01-035` |
| BR | 02 | 40 | `BR-02-001` | `BR-02-040` | `BR-02-041` |
| BR | 03 | 30 | `BR-03-001` | `BR-03-030` | `BR-03-031` |
| BR | 04 | 22 | `BR-04-001` | `BR-04-022` | `BR-04-023` |
| BR | 05 | 30 | `BR-05-001` | `BR-05-030` | `BR-05-031` |
| BR | 06 | 33 | `BR-06-001` | `BR-06-033` | `BR-06-034` |
| BR | 07 | 29 | `BR-07-001` | `BR-07-041` | `BR-07-042` |
| BR | 08 | 35 | `BR-08-001` | `BR-08-035` | `BR-08-036` |
| BR | 09 | 62 | `BR-09-001` | `BR-09-062` | `BR-09-063` |
| BR | 10 | 36 | `BR-10-001` | `BR-10-036` | `BR-10-037` |
| BR | 11 | 38 | `BR-11-001` | `BR-11-038` | `BR-11-039` |
| BR | 12 | 45 | `BR-12-001` | `BR-12-045` | `BR-12-046` |
| BR | 13 | 35 | `BR-13-001` | `BR-13-035` | `BR-13-036` |
| BR | 14 | 37 | `BR-14-001` | `BR-14-037` | `BR-14-038` |
| BR | 15 | 34 | `BR-15-001` | `BR-15-034` | `BR-15-035` |
| BR | 16 | 35 | `BR-16-001` | `BR-16-035` | `BR-16-036` |
| BR | 17 | 87 | `BR-17-001` | `BR-17-087` | `BR-17-088` |
| BR | 18 | 50 | `BR-18-001` | `BR-18-050` | `BR-18-051` |
| BR | 19 | 34 | `BR-19-001` | `BR-19-034` | `BR-19-035` |
| UC | 01 | 34 | `UC-01-01` | `UC-01-34` | `UC-01-35` |
| UC | 02 | 38 | `UC-02-01` | `UC-02-38` | `UC-02-39` |
| UC | 03 | 31 | `UC-03-01` | `UC-03-31` | `UC-03-32` |
| UC | 04 | 22 | `UC-04-01` | `UC-04-22` | `UC-04-23` |
| UC | 05 | 26 | `UC-05-01` | `UC-05-26` | `UC-05-27` |
| UC | 06 | 28 | `UC-06-01` | `UC-06-28` | `UC-06-29` |
| UC | 07 | 17 | `UC-07-01` | `UC-07-17` | `UC-07-18` |
| UC | 08 | 27 | `UC-08-01` | `UC-08-27` | `UC-08-28` |
| UC | 09 | 34 | `UC-09-01` | `UC-09-34` | `UC-09-35` |
| UC | 10 | 28 | `UC-10-01` | `UC-10-28` | `UC-10-29` |
| UC | 11 | 24 | `UC-11-01` | `UC-11-24` | `UC-11-25` |
| UC | 12 | 42 | `UC-12-01` | `UC-12-42` | `UC-12-43` |
| UC | 13 | 42 | `UC-13-01` | `UC-13-42` | `UC-13-43` |
| UC | 14 | 38 | `UC-14-01` | `UC-14-38` | `UC-14-39` |
| UC | 15 | 31 | `UC-15-01` | `UC-15-31` | `UC-15-32` |
| UC | 16 | 30 | `UC-16-01` | `UC-16-30` | `UC-16-31` |
| UC | 17 | 36 | `UC-17-01` | `UC-17-36` | `UC-17-37` |
| UC | 18 | 40 | `UC-18-01` | `UC-18-40` | `UC-18-41` |
| UC | 19 | 29 | `UC-19-01` | `UC-19-29` | `UC-19-30` |
| API | 01 | 88 | `API-01-001` | `API-01-088` | `API-01-089` |
| API | 02 | 98 | `API-02-001` | `API-02-098` | `API-02-099` |
| API | 03 | 96 | `API-03-001` | `API-03-096` | `API-03-097` |
| API | 04 | 51 | `API-04-001` | `API-04-091` | `API-04-092` |
| API | 05 | 93 | `API-05-001` | `API-05-093` | `API-05-094` |
| API | 06 | 125 | `API-06-001` | `API-06-125` | `API-06-126` |
| API | 07 | 75 | `API-07-001` | `API-07-075` | `API-07-076` |
| API | 08 | 132 | `API-08-001` | `API-08-132` | `API-08-133` |
| API | 09 | 245 | `API-09-001` | `API-09-245` | `API-09-246` |
| API | 10 | 121 | `API-10-001` | `API-10-121` | `API-10-122` |
| API | 11 | 137 | `API-11-001` | `API-11-137` | `API-11-138` |
| API | 12 | 111 | `API-12-001` | `API-12-111` | `API-12-112` |
| API | 13 | 90 | `API-13-001` | `API-13-090` | `API-13-091` |
| API | 14 | 92 | `API-14-001` | `API-14-092` | `API-14-093` |
| API | 15 | 142 | `API-15-001` | `API-15-142` | `API-15-143` |
| API | 16 | 130 | `API-16-001` | `API-16-130` | `API-16-131` |
| API | 17 | 193 | `API-17-001` | `API-17-193` | `API-17-194` |
| API | 18 | 188 | `API-18-001` | `API-18-188` | `API-18-189` |
| API | 19 | 107 | `API-19-001` | `API-19-205` | `API-19-206` |
| EVT | 01 | 15 | `EVT-01-01` | `EVT-01-15` | `EVT-01-16` |
| EVT | 02 | 16 | `EVT-02-01` | `EVT-02-16` | `EVT-02-17` |
| EVT | 03 | 12 | `EVT-03-01` | `EVT-03-12` | `EVT-03-13` |
| EVT | 04 | 14 | `EVT-04-01` | `EVT-04-14` | `EVT-04-15` |
| EVT | 05 | 15 | `EVT-05-01` | `EVT-05-15` | `EVT-05-16` |
| EVT | 06 | 15 | `EVT-06-01` | `EVT-06-15` | `EVT-06-16` |
| EVT | 07 | 10 | `EVT-07-01` | `EVT-07-10` | `EVT-07-11` |
| EVT | 08 | 14 | `EVT-08-01` | `EVT-08-14` | `EVT-08-15` |
| EVT | 09 | 32 | `EVT-09-01` | `EVT-09-32` | `EVT-09-33` |
| EVT | 10 | 16 | `EVT-10-01` | `EVT-10-16` | `EVT-10-17` |
| EVT | 11 | 21 | `EVT-11-01` | `EVT-11-21` | `EVT-11-22` |
| EVT | 12 | 16 | `EVT-12-01` | `EVT-12-16` | `EVT-12-17` |
| EVT | 13 | 14 | `EVT-13-01` | `EVT-13-14` | `EVT-13-15` |
| EVT | 14 | 17 | `EVT-14-01` | `EVT-14-17` | `EVT-14-18` |
| EVT | 15 | 14 | `EVT-15-01` | `EVT-15-14` | `EVT-15-15` |
| EVT | 16 | 14 | `EVT-16-01` | `EVT-16-14` | `EVT-16-15` |
| EVT | 17 | 28 | `EVT-17-01` | `EVT-17-28` | `EVT-17-29` |
| EVT | 18 | 29 | `EVT-18-01` | `EVT-18-29` | `EVT-18-30` |
| EVT | 19 | 18 | `EVT-19-01` | `EVT-19-18` | `EVT-19-19` |
| ERR | 01 | 54 | `ERR-01-001` | `ERR-01-054` | `ERR-01-055` |
| ERR | 02 | 45 | `ERR-02-001` | `ERR-02-045` | `ERR-02-046` |
| ERR | 03 | 57 | `ERR-03-001` | `ERR-03-130` | `ERR-03-131` |
| ERR | 04 | 61 | `ERR-04-001` | `ERR-04-112` | `ERR-04-113` |
| ERR | 05 | 60 | `ERR-05-001` | `ERR-05-120` | `ERR-05-121` |
| ERR | 06 | 67 | `ERR-06-001` | `ERR-06-114` | `ERR-06-115` |
| ERR | 07 | 48 | `ERR-07-001` | `ERR-07-048` | `ERR-07-049` |
| ERR | 08 | 75 | `ERR-08-001` | `ERR-08-119` | `ERR-08-120` |
| ERR | 09 | 95 | `ERR-09-001` | `ERR-09-113` | `ERR-09-114` |
| ERR | 10 | 75 | `ERR-10-001` | `ERR-10-121` | `ERR-10-122` |
| ERR | 11 | 76 | `ERR-11-001` | `ERR-11-125` | `ERR-11-126` |
| ERR | 12 | 66 | `ERR-12-001` | `ERR-12-125` | `ERR-12-126` |
| ERR | 13 | 70 | `ERR-13-001` | `ERR-13-126` | `ERR-13-127` |
| ERR | 14 | 72 | `ERR-14-001` | `ERR-14-133` | `ERR-14-134` |
| ERR | 15 | 63 | `ERR-15-001` | `ERR-15-123` | `ERR-15-124` |
| ERR | 16 | 86 | `ERR-16-001` | `ERR-16-125` | `ERR-16-126` |
| ERR | 17 | 105 | `ERR-17-001` | `ERR-17-118` | `ERR-17-119` |
| ERR | 18 | 96 | `ERR-18-001` | `ERR-18-124` | `ERR-18-125` |
| ERR | 19 | 51 | `ERR-19-001` | `ERR-19-099` | `ERR-19-100` |
| UI | 01 | 17 | `UI-01-01` | `UI-01-17` | `UI-01-18` |
| UI | 02 | 17 | `UI-02-01` | `UI-02-17` | `UI-02-18` |
| UI | 03 | 18 | `UI-03-01` | `UI-03-18` | `UI-03-19` |
| UI | 04 | 21 | `UI-04-01` | `UI-04-21` | `UI-04-22` |
| UI | 05 | 17 | `UI-05-01` | `UI-05-17` | `UI-05-18` |
| UI | 06 | 18 | `UI-06-01` | `UI-06-18` | `UI-06-19` |
| UI | 07 | 13 | `UI-07-01` | `UI-07-13` | `UI-07-14` |
| UI | 08 | 20 | `UI-08-01` | `UI-08-20` | `UI-08-21` |
| UI | 09 | 22 | `UI-09-01` | `UI-09-22` | `UI-09-23` |
| UI | 10 | 20 | `UI-10-01` | `UI-10-20` | `UI-10-21` |
| UI | 11 | 23 | `UI-11-01` | `UI-11-23` | `UI-11-24` |
| UI | 12 | 19 | `UI-12-01` | `UI-12-19` | `UI-12-20` |
| UI | 13 | 18 | `UI-13-01` | `UI-13-18` | `UI-13-19` |
| UI | 14 | 17 | `UI-14-01` | `UI-14-17` | `UI-14-18` |
| UI | 15 | 28 | `UI-15-01` | `UI-15-28` | `UI-15-29` |
| UI | 16 | 20 | `UI-16-01` | `UI-16-20` | `UI-16-21` |
| UI | 17 | 20 | `UI-17-01` | `UI-17-20` | `UI-17-21` |
| UI | 18 | 24 | `UI-18-01` | `UI-18-24` | `UI-18-25` |
| UI | 19 | 28 | `UI-19-01` | `UI-19-28` | `UI-19-29` |
| TS | 01 | 35 | `TS-01-01` | `TS-01-35` | `TS-01-36` |
| TS | 02 | 28 | `TS-02-01` | `TS-02-28` | `TS-02-29` |
| TS | 03 | 32 | `TS-03-01` | `TS-03-32` | `TS-03-33` |
| TS | 04 | 32 | `TS-04-01` | `TS-04-32` | `TS-04-33` |
| TS | 05 | 36 | `TS-05-01` | `TS-05-36` | `TS-05-37` |
| TS | 06 | 35 | `TS-06-01` | `TS-06-35` | `TS-06-36` |
| TS | 07 | 30 | `TS-07-01` | `TS-07-30` | `TS-07-31` |
| TS | 08 | 35 | `TS-08-01` | `TS-08-35` | `TS-08-36` |
| TS | 09 | 42 | `TS-09-01` | `TS-09-42` | `TS-09-43` |
| TS | 10 | 35 | `TS-10-01` | `TS-10-35` | `TS-10-36` |
| TS | 11 | 35 | `TS-11-01` | `TS-11-35` | `TS-11-36` |
| TS | 12 | 37 | `TS-12-01` | `TS-12-37` | `TS-12-38` |
| TS | 13 | 41 | `TS-13-01` | `TS-13-41` | `TS-13-42` |
| TS | 14 | 38 | `TS-14-01` | `TS-14-38` | `TS-14-39` |
| TS | 15 | 37 | `TS-15-01` | `TS-15-37` | `TS-15-38` |
| TS | 16 | 36 | `TS-16-01` | `TS-16-36` | `TS-16-37` |
| TS | 17 | 45 | `TS-17-01` | `TS-17-45` | `TS-17-46` |
| TS | 18 | 46 | `TS-18-01` | `TS-18-46` | `TS-18-47` |
| TS | 19 | 34 | `TS-19-01` | `TS-19-34` | `TS-19-35` |
| TC | 01 | 143 | `TC-01-001` | `TC-01-143` | `TC-01-144` |
| TC | 02 | 168 | `TC-02-001` | `TC-02-168` | `TC-02-169` |
| TC | 03 | 136 | `TC-03-001` | `TC-03-136` | `TC-03-137` |
| TC | 04 | 202 | `TC-04-001` | `TC-04-202` | `TC-04-203` |
| TC | 05 | 155 | `TC-05-001` | `TC-05-155` | `TC-05-156` |
| TC | 06 | 158 | `TC-06-001` | `TC-06-158` | `TC-06-159` |
| TC | 07 | 320 | `TC-07-001` | `TC-07-320` | `TC-07-321` |
| TC | 08 | 153 | `TC-08-001` | `TC-08-153` | `TC-08-154` |
| TC | 09 | 150 | `TC-09-001` | `TC-09-150` | `TC-09-151` |
| TC | 10 | 158 | `TC-10-001` | `TC-10-158` | `TC-10-159` |
| TC | 11 | 171 | `TC-11-001` | `TC-11-171` | `TC-11-172` |
| TC | 12 | 127 | `TC-12-001` | `TC-12-127` | `TC-12-128` |
| TC | 13 | 126 | `TC-13-001` | `TC-13-126` | `TC-13-127` |
| TC | 14 | 156 | `TC-14-001` | `TC-14-156` | `TC-14-157` |
| TC | 15 | 208 | `TC-15-001` | `TC-15-208` | `TC-15-209` |
| TC | 16 | 124 | `TC-16-001` | `TC-16-124` | `TC-16-125` |
| TC | 17 | 163 | `TC-17-001` | `TC-17-163` | `TC-17-164` |
| TC | 18 | 171 | `TC-18-001` | `TC-18-171` | `TC-18-172` |
| TC | 19 | 187 | `TC-19-001` | `TC-19-836` | `TC-19-837` |
| ADR | — | 70 | `ADR-001` | `ADR-184` | theo dải nhóm, §3 |
| SEC | — | 92 | `SEC-01` | `SEC-99` | theo dải nhóm, §3 |
| PTN | — | 14 | `PTN-01` | `PTN-14` | `PTN-15` |
| LGC-APIM | — | 27 | `LGC-APIM-001` | `LGC-APIM-027` | `LGC-APIM-028` |
| LGC-BUS | — | 41 | `LGC-BUS-001` | `LGC-BUS-041` | `LGC-BUS-042` |
| LGC-DMDC | — | 19 | `LGC-DMDC-001` | `LGC-DMDC-019` | `LGC-DMDC-020` |
| LGC-HUB | — | 14 | `LGC-HUB-001` | `LGC-HUB-014` | `LGC-HUB-015` |
| LGC-IAM | — | 8 | `LGC-IAM-001` | `LGC-IAM-008` | `LGC-IAM-009` |
| LGC-NFR | — | 14 | `LGC-NFR-001` | `LGC-NFR-014` | `LGC-NFR-015` |
| LGC-NGSP | — | 8 | `LGC-NGSP-001` | `LGC-NGSP-008` | `LGC-NGSP-009` |
| LGC-PAY | — | 26 | `LGC-PAY-001` | `LGC-PAY-026` | `LGC-PAY-027` |
| LGC-TOOL | — | 29 | `LGC-TOOL-001` | `LGC-TOOL-029` | `LGC-TOOL-030` |
| REQ | — | 31 | `REQ-01` | `REQ-99` | `REQ-100` |
| CMP-LAW | — | 33 | `CMP-LAW-01` | `CMP-LAW-97` | `CMP-LAW-98` |
| PERM | 01…20 | 230 | — | — | động từ theo D02-08 |

: Dải mã đã dùng thực tế trong bộ tài liệu (sinh tự động)

<!-- dai-ma:ket-thuc -->

## 4. Quy ước đặt tên và trình bày

Bảng sau tóm tắt D00-01 §6, §8 và D03-06-00 §2.4 ở mức đủ để viết, kèm ví dụ thật từ PH-04, PH-07.

| Đối tượng | Quy ước | Ví dụ |
|---|---|---|
| Tệp tập phân hệ | `{nhóm}/{loại}/D0x-0y-PH{nn}-{loai}-{ten-khong-dau}.md` | `02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md` |
| Metadata đầu tệp | sáu trường `ma_tai_lieu`, `ten`, `phien_ban`, `ngay`, `trang_thai`, `nguoi_doc`; thêm `phan_he` | tiêu đề `# D02-03-PH07 · …` |
| Mở đầu tài liệu | Mục "Tóm tắt cho hội đồng thẩm định" (mục tiêu, phạm vi, căn cứ pháp lý) trước phần kỹ thuật | mọi tập PH-07 |
| Schema PostgreSQL | `ph{nn}_{tên ngắn}` | `ph07_rdm` (PH-04 đang dùng `ph04`, chờ đợt đồng bộ) |
| Bảng, cột | `snake_case`, tiếng Anh, số ít; luôn có `id`, `tenant_id`, `created_*`, `updated_*`, `version` | `catalog_item` |
| REST | `/api/{nhóm}/v{n}/{tài-nguyên-số-nhiều}`, lỗi RFC 9457, phân trang `page`/`size` | `/api/rdm/v1`, `/api/integration/v1` |
| Hành động REST | `POST …/{ma}:{động-từ}` | `POST /workspaces/{workspaceCode}:archive` |
| Topic Kafka | `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}`, chữ thường | `t68.rdm.catalog.published.v1` |
| Route giao diện | `/{nhóm}/{tài-nguyên}/{ma}/{màn-con}` tiếng Việt không dấu; màn con `/moi`, `/{ma}`, `/{ma}/sua`, `/{ma}/thiet-ke`, `/{ma}/lich-su`, `/nhap` | `/du-lieu/danh-muc/DM_GIOI_TINH`, `/tich-hop/luong/{ma-luong}/thiet-ke` |
| Query giao diện | `q`, `trang` (từ 1), `co` (10/20/50/100), `sap-xep=truong:tang\|giam`, `tu`/`den`, `khoang`, `chon`, `bo-loc` | `?trang=2&sap-xep=ngay-tao:giam` |
| Design token | CSS `--dh-{nhóm}-{vai trò}-{biến thể}`, mã `TKN-{nhóm}-{tên}`; chỉ dùng tầng ngữ nghĩa | `--dh-color-text-primary`, `color-diff-*`, `color-source-*` |
| Quyền | `PERM-{PH}-{động-từ}` | `PERM-07-publish` |
| Test case | Viết `TC-{PH}-###` kèm `<!--k:khóa-->`, cấp số bằng `number_tcs.py`; tham chiếu `[[tc:khóa]]` | `TC-04-010 · … <!--k:flow-detail-->` |
| Câu hỏi mở | `> **Câu hỏi mở Q{PH}-nn:** …` và gom vào mục câu hỏi mở cuối tài liệu | `Q04-31` |
| Sơ đồ | Mermaid; mỗi sơ đồ có một đoạn thuyết minh ngay sau; không dùng `;` trong thông điệp sequence | |

: Quy ước đặt tên và trình bày tóm tắt kèm ví dụ

## 5. Quyết định đã chốt

Các quyết định dưới đây đã được chủ đầu tư chọn và không bàn lại trong tập phân hệ (nhật ký đầy đủ ở D00-02 §5).

| Chủ đề | Đã chốt |
|---|---|
| Định vị | Datahub là LGSP thế hệ mới, có lớp dữ liệu dùng chung, chưa lakehouse; đa tenant nhiều tỉnh, mỗi tỉnh chủ quản tenant (Q311, Q323b); hệ mới theo NĐ 331/2026 (Q300); thay hệ cũ bằng chạy song song, thay dần (strangler) |
| Phạm vi | Đủ 20 phân hệ, phủ toàn bộ nghiệp vụ hệ cũ (Bus, Tooling, Hub, APIM, Danh mục Aita, PayGov, NGSP) và giữ màn có giá trị vận hành; mỗi tập phải có ma trận truy vết `LGC` → FR |
| Stack | Backend Java Spring Boot 4 + Modulith (ADR-001); Camel Quarkus 3.33.x cho PH-04/05/14 (ADR-002, ADR-061); PostgreSQL + RLS (ADR-003); Kafka thay Pulsar (ADR-004); APISIX làm gateway và lớp biên kèm WAF Coraza, không Envoy (ADR-005, ADR-033); Keycloak + OPA (ADR-006); OpenBao (ADR-012) |
| Lưu trữ | WORM và sao lưu chung Ceph RGW, tách bucket (Q306, Q341, Q347); tách `pg-payment` cho PH-19 (Q340) |
| Giao diện | React + antd v6, Liquid Glass (ADR-020): kính chỉ cho lớp điều hướng và lớp nổi, nội dung dày dùng nền đặc để đạt WCAG 2.2 AA; Lucide (ADR-022), ECharts (ADR-023) |
| ATTT | Cấp độ 3, sẵn sàng lên cấp độ 4 (ADR-030); mật khẩu ≥ 14 ký tự, khóa phiên 15 phút, vô hiệu tài khoản sau 45 ngày (TCVN 14423:2026); log kiểm toán online 12 tháng, WORM 5 năm; DR hai site active–standby (ADR-034) |
| Pháp lý | Viện dẫn văn bản mới làm căn cứ chính, văn bản cũ ở cột kế thừa: Luật ANM 116/2025, NĐ 331/2026, Luật BVDLCN 91/2025 + NĐ 356/2025, NĐ 278/2025, TCVN 14423:2026, NĐ 224/2026. Còn mở: Q301, Q313, Q320, Q321, Q323a |
| PH-04 | Trình thiết kế tự làm lại mô hình Kaoto (ADR-060), catalog sinh lại theo runtime; SQL trực tiếp có kiểm soát (Q359, ADR-067) |
| Dự án | GitHub khi phát triển, GitLab on-prem khi bàn giao (Q353); chủ quản CNTT là tham số theo tỉnh, mặc định Sở KH&CN (Q05); nguồn chuẩn là Markdown, .docx chỉ là bản xuất |

: Quyết định đã chốt theo chủ đề

## 6. Kiểm tra tự động

Script `build/tools/kiem_tra_ma.py` chạy trong CI (workflow `datahub-docs`) mỗi khi `datahub-docs/` thay đổi. Nó báo ba loại lỗi:

1. **Mã thiếu:** một mã được nhắc nhưng tài liệu gốc của họ mã (D00-01 §3.1) đã có mà không định nghĩa mã đó. Mã định nghĩa là mã nằm trong tiêu đề hoặc ở ô thứ nhất, thứ hai của hàng bảng. Nếu tài liệu gốc chưa viết, mã chỉ được đếm là "chờ tài liệu gốc".
2. **Mã trùng:** cùng mã là tiêu đề của hai mục cùng cấp, hoặc là ô đầu của hai hàng trong cùng một bảng.
3. **Liên kết hỏng:** liên kết tương đối tới tệp không có, hoặc tới neo không khớp tiêu đề.

Lỗi có từ trước ngày 26/11/2026 nằm ở `build/tools/kiem_tra_ngoai_le.txt`; CI chỉ đỏ khi có lỗi mới. Sửa lỗi cũ trong đợt đồng bộ cuối rồi chạy `--ghi-ngoai-le` để thu hẹp danh sách.

```bash
python3 datahub-docs/build/tools/kiem_tra_ma.py              # soát, chỉ in lỗi mới
python3 datahub-docs/build/tools/kiem_tra_ma.py --tat-ca     # in cả lỗi đã ghi nhận
python3 datahub-docs/build/tools/kiem_tra_ma.py --dai-ma     # in dải mã đã dùng
```

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: cách dùng, phân hệ và DU, dải mã, quy ước đặt tên, quyết định đã chốt, kiểm tra tự động |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định và phần Giới thiệu tài liệu ngắn gọn (sáu ý); viết lại chú thích bảng cho cụ thể; không sửa khối sinh tự động |
