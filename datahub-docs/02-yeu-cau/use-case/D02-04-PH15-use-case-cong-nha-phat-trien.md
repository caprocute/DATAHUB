---
ma_tai_lieu: D02-04-PH15
ten: Đặc tả use case phân hệ PH-15 Cổng nhà phát triển
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-15
mo_ta: Đặc tả 31 use case của Cổng nhà phát triển theo hành trình thật của nhà phát triển, chủ dịch vụ và quản trị cổng, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH15 FRS; D03-04-PH15 API; D03-06-PH15 Màn hình; D05-02-PH15 Test case
---

# D02-04-PH15 · Đặc tả use case Cổng nhà phát triển

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 31 use case của PH-15 Cổng nhà phát triển, phủ toàn bộ 62 FR của [D02-03-PH15](../frs/D02-03-PH15-frs-cong-nha-phat-trien.md) (47 FR mức M, 13 mức S, 2 mức C): mỗi FR thuộc ít nhất một use case và bảng truy vết ngược ở §5.4 cho thấy điều đó. Use case đi theo hành trình thật của ba nhóm người dùng. Nhà phát triển (cán bộ CQNN đăng nhập SSO hoặc nhà thầu tự đăng ký ở realm `dh-dev`) tìm dịch vụ, đọc tài liệu, tạo ứng dụng sandbox, nhận bí mật một lần, thử API rồi nhờ cán bộ đầu mối gửi đăng ký sử dụng. Chủ dịch vụ khai báo sandbox, viết hướng dẫn, công bố API và trả lời hỗ trợ. Quản trị cổng duyệt tài khoản nhà thầu, khóa lạm dụng, cấu hình nhận diện, đối soát danh mục và tra nhật ký.

Ba điều ràng buộc xuyên suốt mọi use case. PH-15 chỉ trình bày và ủy thác: không duyệt đăng ký, không cấp thông tin xác thực production, không sửa vòng đời API (BR-15-001, BR-15-014, BR-15-015). Bí mật sandbox chỉ hiện một lần và không nằm trong nhật ký hay tệp xuất nào (BR-15-011). Thử API trên production mặc định tắt, chỉ bật theo dịch vụ sau duyệt bốn mắt, và an toàn khi lỗi: không ghi được kiểm toán thì từ chối (BR-15-019…023). Căn cứ pháp lý như FRS (CMP-LAW-03, CMP-LAW-05).

## 1. Giới thiệu

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các phân hệ và hệ thống ngoài để hoàn thành từng việc nghiệp vụ của PH-15, từ xem danh mục tới quản trị cổng. Phạm vi là toàn bộ FR-15-001…062. Chức năng dùng chung FR-00 (đăng nhập, phân quyền, kiểm toán, hộp "Việc của tôi", thông báo) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Hành vi chi tiết từng bước (kiểm tra, mã lỗi, câu thông báo) ở FR tương ứng; use case mô tả trình tự và vai trò. Phần máy chủ là module `portal` trong `dh-connect`, giao diện là `dh-portal` qua BFF (SEC-21).

### 1.2. Người đọc

Ba nhóm người đọc dùng tài liệu theo ba cách khác nhau, bảng dưới chỉ ra phần nên đọc.

| Người đọc | Phần cần đọc |
|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 4 (sơ đồ tổng), chương 5 (truy vết) |
| Kỹ sư giao diện, BFF, `portal` | Chương 6, đối chiếu cột Màn hình, API |
| Kiểm thử viên | Chương 6: mỗi luồng chính, thay thế, ngoại lệ là một ca kiểm thử ở D05-02-PH15 |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và tài liệu tham chiếu

Thuật ngữ, chữ viết tắt và vai trò dùng chung với [D02-03-PH15](../frs/D02-03-PH15-frs-cong-nha-phat-trien.md) §1.4 và D00-01. Tài liệu tham chiếu: D02-03-PH15 (FRS, nguồn của mọi mã lỗi, enum, route và câu thông báo), D03-04-PH15 (API), D03-06-PH15 (màn hình), D05-02-PH15 (ca kiểm thử), D02-08 (ma trận phân quyền), D02-04-PH05 (mẫu trình bày).

### 1.4. Cấu trúc tài liệu

Tài liệu gồm chín chương theo thứ tự người đọc cần tra.

| Chương | Nội dung |
|---|---|
| 2 | Quy ước đọc đặc tả |
| 3 | Tác nhân |
| 4 | Sơ đồ use case tổng (bốn hình) |
| 5 | Bảng tổng hợp và truy vết: UC với FR, UI, API, REQ; FR với UC |
| 6 | Đặc tả 31 use case, kèm sơ đồ trình tự cho năm use case nhiều thành phần |
| 7 | Luồng phụ dùng chung |
| 8, 9 | Mã mới, đối chiếu, câu hỏi mở, đề nghị đồng bộ |

: Cấu trúc tài liệu D02-04-PH15

## 2. Quy ước đọc đặc tả

Mỗi use case đặc tả bằng một khối hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ (kèm câu thông báo lấy từ FRS §9.1), Quy tắc áp dụng, Màn hình và API. Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `3a`) và quay lại luồng chính. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh và kết thúc use case hoặc quay lại bước nêu rõ. Luồng phụ dùng chung ở chương 7 ghi `LP-15-nn`.

Dữ liệu ví dụ đều giả lập, tenant `T68`: **An** (`nguyen.van.an`, nhà thầu Công ty ABC, tài khoản `dh-dev`), **Bình** (cán bộ Sở TN&MT, HTTT khai thác `HT-DATDAI`, đầu mối OR), **Chi** (chủ dịch vụ Sở Tư pháp, HTTT cung cấp `HT-TUPHAP`, API `tra-cuu-ho-tich`), **Dũng** (người duyệt dịch vụ CA), **Hà** (quản trị tỉnh TA), **Khánh** (cán bộ ATTT SO), **Lan** (khách ẩn danh). Ứng dụng mẫu `app-tra-cuu-ho-tich`; trang mẫu `bat-dau-nhanh`. Tên miền sandbox mẫu `sandbox-api.t68.datahub.gov.vn` (giả định, Q15-08).

## 3. Tác nhân

Bảng nêu tác nhân người và tác nhân máy của PH-15 kèm use case chính. Nhà phát triển có hai nguồn gốc (cán bộ SSO, nhà thầu `dh-dev`) nhưng cùng vai trò `ROLE-DEVELOPER`; chỗ hai nhóm khác nhau được nêu trong từng use case.

| Tác nhân | Loại | Use case chính |
|---|---|---|
| Khách ẩn danh (Lan) | Chính | 01, 02, 03, 05, 09 |
| Nhà phát triển DEV, `ROLE-DEVELOPER` (An, Bình) | Chính | 01…03, 05, 09…22, 26…28 |
| Cán bộ đầu mối OR, `ROLE-ORG_REQUESTER` (Bình) | Chính | 23, 24 |
| Chủ dịch vụ SV, `ROLE-SERVICE_OWNER` (Chi) | Chính | 06, 07, 18, 21, 25, 28 |
| Người duyệt dịch vụ CA, `ROLE-CATALOG_APPROVER` (Dũng) | Chính | 07, 21, 29, 30 |
| Quản trị tỉnh TA, `ROLE-TENANT_ADMIN` (Hà) | Chính | 04, 06, 07, 08, 21, 28…31 |
| Cán bộ ATTT SO, `ROLE-SECURITY_OFFICER` (Khánh) | Chính | 30, 31 |
| Kiểm toán viên AU, `ROLE-AUDITOR`; quản trị nền tảng PA, `ROLE-PLATFORM_ADMIN` | Chính | 31 (AU, PA); 30 (PA) |
| `portal` (tác vụ định kỳ, tác vụ nền) | Chính (máy) | 04, 12, 15, 16, 28 |
| PH-02 | Phụ | 01…05, 17, 22…25, 27 |
| PH-01 | Phụ | 17, 24 |
| PH-03 (APISIX sandbox, `forward-auth` API-15-082) | Phụ | 15, 16, 19, 22, 30 |
| PH-12 (Keycloak `dh-{tenant}`, `dh-dev`) | Phụ | 10, 11, 15, 16, 19, 22, 30 |
| PH-13 (kiểm toán, chỉ số) | Phụ | 19, 22, 26, 31 |
| PH-10, PH-18, kho Git tài liệu, OpenBao, OpenSearch, Valkey, dịch vụ quét mã độc | Phụ | Nhiều use case |

: Tác nhân của PH-15 và use case chính

## 4. Sơ đồ use case tổng

Có 31 use case nên sơ đồ tổng chia làm bốn hình theo nhóm nghiệp vụ để đọc được trên trang A4: khám phá và tài liệu (Hình 1), nội dung và tài khoản (Hình 2), ứng dụng và sandbox (Hình 3), điểm vào nghiệp vụ, theo dõi, hỗ trợ và quản trị (Hình 4).

```{.mermaid caption="Use case khám phá danh mục và đọc tài liệu"}
flowchart LR
  LAN([Khách ẩn danh])
  DEV([Nhà phát triển])
  TA([Quản trị tỉnh])
  P2([PH-02])
  subgraph KP["Danh mục và tài liệu"]
    U01[UC-15-01 Duyệt danh mục]
    U02[UC-15-02 Tìm kiếm]
    U03[UC-15-03 Chi tiết dịch vụ]
    U04[UC-15-04 Đồng bộ, đối soát]
    U05[UC-15-05 Đọc tài liệu API]
  end
  LAN --> U01 & U02 & U03 & U05
  DEV --> U01 & U02 & U03 & U05
  TA --> U04
  P2 --> U04
```

Hình 1 cho thấy khách ẩn danh và nhà phát triển dùng chung bốn use case khám phá; chỉ quản trị và PH-02 chạm tới đồng bộ.

```{.mermaid caption="Use case nội dung hướng dẫn và tài khoản nhà phát triển"}
flowchart LR
  ED([Biên tập viên SV CA TA])
  CA([Người duyệt])
  DEV([Nhà phát triển])
  TH([Nhà thầu dh-dev])
  GIT([Kho Git])
  subgraph ND["Nội dung"]
    U06[UC-15-06 Soạn trang]
    U07[UC-15-07 Gửi duyệt, đăng]
    U08[UC-15-08 Nhập Git, di trú]
    U09[UC-15-09 Đọc trang]
  end
  subgraph TK["Tài khoản"]
    U10[UC-15-10 Đăng nhập SSO]
    U11[UC-15-11 Tự đăng ký dh-dev]
    U12[UC-15-12 Hồ sơ, điều khoản]
    U13[UC-15-13 Nhóm, thành viên]
  end
  ED --> U06 & U08
  CA --> U07
  GIT --> U08
  DEV --> U09 & U10 & U12 & U13
  TH --> U11 & U10
```

Hình 2 cho thấy nội dung đi qua người soạn rồi người duyệt khác, còn nhà thầu phải qua đăng ký trước khi đăng nhập.

```{.mermaid caption="Use case ứng dụng sandbox và thử API"}
flowchart LR
  DEV([Nhà phát triển])
  SV([Chủ dịch vụ])
  CA([Người duyệt])
  subgraph UD["Ứng dụng và thông tin xác thực"]
    U14[UC-15-14 Tạo, quản lý ứng dụng]
    U15[UC-15-15 Cấp thông tin xác thực]
    U16[UC-15-16 Xoay, thu hồi]
    U17[UC-15-17 Tham chiếu production]
  end
  subgraph SB["Sandbox và thử"]
    U18[UC-15-18 Khai báo sandbox]
    U19[UC-15-19 Thử API sandbox]
    U20[UC-15-20 Lịch sử, bộ sưu tập]
    U21[UC-15-21 Bật, tắt thử production]
    U22[UC-15-22 Thử production]
  end
  DEV --> U14 & U15 & U16 & U17 & U19 & U20 & U22
  SV --> U18 & U21
  CA --> U21
```

Hình 3 cho thấy nhà phát triển làm mọi việc với ứng dụng và thử API; chủ dịch vụ và người duyệt chỉ xuất hiện ở khai báo sandbox và bật thử production.

```{.mermaid caption="Use case điểm vào nghiệp vụ, theo dõi, hỗ trợ và quản trị cổng"}
flowchart LR
  DEV([Nhà phát triển])
  OR([Cán bộ đầu mối])
  SV([Chủ dịch vụ])
  TA([Quản trị tỉnh])
  SO([Cán bộ ATTT])
  AU([Kiểm toán viên])
  subgraph NV["Điểm vào, theo dõi, hỗ trợ"]
    U23[UC-15-23 Đăng ký sử dụng]
    U24[UC-15-24 Kết nạp HTTT]
    U25[UC-15-25 Công bố API]
    U26[UC-15-26 Bảng điều khiển, thống kê]
    U27[UC-15-27 Theo dõi, hộp thông báo]
    U28[UC-15-28 Hỗ trợ, hỏi đáp]
  end
  subgraph QT["Quản trị cổng"]
    U29[UC-15-29 Nhận diện, tham số]
    U30[UC-15-30 Duyệt, khóa tài khoản]
    U31[UC-15-31 Nhật ký, báo cáo]
  end
  OR --> U23 & U24
  SV --> U25 & U28
  DEV --> U26 & U27 & U28
  TA --> U29 & U30 & U31
  SO --> U30 & U31
  AU --> U31
```

Hình 4 cho thấy cán bộ đầu mối là tác nhân duy nhất của đăng ký sử dụng và kết nạp, còn ba use case quản trị cổng do TA, SO, kiểm toán viên chia nhau.

Các hình cho thấy ba tầng. Tầng tự phục vụ (Hình 1, 3) là nơi nhà phát triển đi từ tìm dịch vụ tới gọi thử API mà không cần người trợ giúp. Tầng ủy thác (Hình 4, UC-15-23…25) là các điểm cổng chuyển yêu cầu sang PH-01, PH-02 nhân danh người dùng, không tự quyết. Tầng quản trị (Hình 2, 4) gồm duyệt bốn mắt nội dung và thử production, duyệt tài khoản nhà thầu. Use case máy (UC-15-04 và các tác vụ định kỳ trong UC-15-12, 15, 16, 28) không có giao diện riêng nhưng quyết định độ tin cậy của danh mục và hiệu lực thu hồi, nên được đặc tả cùng mức chi tiết.

## 5. Bảng tổng hợp use case và truy vết

### 5.1. Use case và FR

Bảng nối từng use case với các FR mà nó hiện thực; cột Mức lấy mức cao nhất trong các FR của use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-15-01 | Duyệt danh mục theo mức hiển thị, kể cả khách ẩn danh | DEV, khách | M | 002, 003, 004, 007, 008 |
| UC-15-02 | Tìm kiếm toàn văn tiếng Việt và gợi ý | DEV, khách | M | 005 |
| UC-15-03 | Xem chi tiết dịch vụ, đường dẫn sử dụng, lộ trình ngừng | DEV, khách | M | 006, 013 |
| UC-15-04 | Đồng bộ và đối soát danh mục với PH-02 | `portal`, TA | M | 001, 061 |
| UC-15-05 | Đọc tài liệu API, chọn phiên bản, tải, so sánh, lấy mẫu mã | DEV, khách | M | 009, 010, 011, 012 |
| UC-15-06 | Soạn trang nội dung Markdown | SV, CA, TA | M | 014 |
| UC-15-07 | Gửi duyệt, duyệt, đăng, khôi phục và gỡ trang | SV, CA, TA | M | 015, 016 |
| UC-15-08 | Nhập nội dung từ kho Git và di trú portal hệ cũ | TA, SV | S | 018, 062 |
| UC-15-09 | Đọc trang hướng dẫn, hỏi đáp, thông báo | DEV, khách | M | 017 |
| UC-15-10 | Đăng nhập SSO realm tenant hoặc dh-dev | DEV | M | 019 |
| UC-15-11 | Tự đăng ký tài khoản dh-dev | Nhà thầu | M | 020 |
| UC-15-12 | Hồ sơ, phiên, điều khoản, vô hiệu hóa và xóa tài khoản | DEV, `portal` | M | 021, 023, 024 |
| UC-15-13 | Nhóm phát triển và thành viên ứng dụng | DEV | S | 022, 033 |
| UC-15-14 | Tạo và quản lý ứng dụng sandbox | DEV | M | 025, 026 |
| UC-15-15 | Cấp thông tin xác thực sandbox, hiện bí mật một lần | DEV | M | 027, 028, 029 |
| UC-15-16 | Xoay vòng, thu hồi và hết hạn thông tin xác thực | DEV, `portal` | M | 030, 031 |
| UC-15-17 | Xem tham chiếu thông tin xác thực production | DEV (cán bộ) | M | 032 |
| UC-15-18 | Khai báo sandbox của dịch vụ | SV | M | 034 |
| UC-15-19 | Thử API trên sandbox MOCK và BACKEND | DEV | M | 035, 036, 037, 038, 039 |
| UC-15-20 | Lịch sử thử, bộ sưu tập và xuất Postman, Bruno, HTTP | DEV | S | 040, 041 |
| UC-15-21 | Đề xuất, duyệt, tắt thử production theo dịch vụ | SV, CA, TA | M | 042 |
| UC-15-22 | Thử API trên production | DEV (cán bộ) | M | 043 |
| UC-15-23 | Gửi và theo dõi đăng ký sử dụng API production | OR | M | 044, 045 |
| UC-15-24 | Nộp hồ sơ kết nạp HTTT từ cổng | OR | M | 046 |
| UC-15-25 | Công bố API từ cổng | SV | M | 047 |
| UC-15-26 | Bảng điều khiển, thống kê và nhật ký ứng dụng | DEV | M | 048, 049, 050 |
| UC-15-27 | Theo dõi thay đổi API và hộp thông báo | DEV | M | 051, 052 |
| UC-15-28 | Hỏi đáp, báo lỗi tài liệu, yêu cầu hỗ trợ và xử lý | DEV, SV, TA | M | 053, 054, 055 |
| UC-15-29 | Cấu hình nhận diện và tham số cổng | TA, CA | M | 056, 057 |
| UC-15-30 | Duyệt, khóa và mở khóa tài khoản dh-dev, ứng dụng | TA, SO, PA | M | 058, 059 |
| UC-15-31 | Tra nhật ký truy cập, thử và báo cáo sử dụng | TA, SO, AU, PA | M | 060 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Bảng nối use case với màn hình UI-15 và API-15 mà kỹ sư giao diện và kiểm thử viên cần đối chiếu.

| UC | UI | API |
|---|---|---|
| UC-15-01 | UI-15-01, 02 | API-15-001, 002, 003, 004, 005, 006, 013, 014 |
| UC-15-02 | UI-15-03 | API-15-010, 011, 012 |
| UC-15-03 | UI-15-04, 05 | API-15-007, 008, 015, 021 |
| UC-15-04 | UI-15-27 | API-15-009, 131, 132, 133, 134; API-02-081 |
| UC-15-05 | UI-15-05 | API-15-016, 017, 018, 019, 020 |
| UC-15-06 | UI-15-21 | API-15-022, 023, 024, 025, 033 |
| UC-15-07 | UI-15-22 | API-15-026…032 |
| UC-15-08 | UI-15-21, 27 | API-15-038, 039, 040, 135, 136, 137 |
| UC-15-09 | UI-15-07 | API-15-034, 035, 036, 037 |
| UC-15-10 | UI-15-08 | `/bff/dang-nhap`, `/bff/dang-xuat`; API-15-041 |
| UC-15-11 | UI-15-08 | API-15-045, 046 |
| UC-15-12 | UI-15-09, 24 | API-15-041, 042, 043, 044, 047, 048, 054 |
| UC-15-13 | UI-15-09, 12 | API-15-049…053, 066, 067, 068 |
| UC-15-14 | UI-15-10, 11, 12 | API-15-055…060 |
| UC-15-15 | UI-15-13 | API-15-061, 062 |
| UC-15-16 | UI-15-13 | API-15-063, 064; EVT-15-04, 05 |
| UC-15-17 | UI-15-13 | API-15-065 |
| UC-15-18 | UI-15-23 | API-15-069, 070 |
| UC-15-19 | UI-15-06 | API-15-071, 072, 073, 074, 082 |
| UC-15-20 | UI-15-14 | API-15-075…081 |
| UC-15-21 | UI-15-23 | API-15-083…086; EVT-15-10 |
| UC-15-22 | UI-15-06 | API-15-072, 082; EVT-15-11 |
| UC-15-23 | UI-15-15 | API-15-087, 088, 089, 090 |
| UC-15-24 | UI-15-16 | API-15-091, 092, 093 |
| UC-15-25 | UI-15-17 | API-15-094, 095, 096 |
| UC-15-26 | UI-15-18, 12 | API-15-097, 098, 099, 100 |
| UC-15-27 | UI-15-19 | API-15-101…106 |
| UC-15-28 | UI-15-04, 07, 20, 28 | API-15-107…115 |
| UC-15-29 | UI-15-25 | API-15-116…120 |
| UC-15-30 | UI-15-24 | API-15-121…127 |
| UC-15-31 | UI-15-26 | API-15-128, 129, 130 |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Bảng cho hội đồng thẩm định thấy mỗi use case truy về yêu cầu mức cao, quy trình nghiệp vụ và chức năng hệ cũ nào.

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-15-01, 02 | REQ-15 | BP-01 (tìm dịch vụ) | LGC-APIM-006, LGC-APIM-007 |
| UC-15-03 | REQ-15 | BP-01 | LGC-APIM-017 |
| UC-15-04 | REQ-15 | BP-01, BP-09 | LGC-APIM-006 |
| UC-15-05 | REQ-15 | BP-01 (đọc tài liệu), BP-02 | LGC-APIM-017, LGC-IAM-006 |
| UC-15-06, 07, 09 | REQ-15 | BP-09 | LGC-APIM-017 (thay TechDocs) |
| UC-15-08 | REQ-15 | BP-09 | LGC-APIM-006 |
| UC-15-10…13 | REQ-15, BO-03 | BP-01 | LGC-APIM-019, LGC-APIM-020 (liên quan) |
| UC-15-14…16 | REQ-15 | BP-01 (nhận thông tin sandbox) | LGC-IAM-006 |
| UC-15-17 | REQ-15 | BP-01 | LGC-APIM-019 (liên quan) |
| UC-15-18…22 | REQ-15, BO-03 | BP-01, BP-02 | LGC-IAM-006 |
| UC-15-23…25 | REQ-15 | BP-01, BP-02 | LGC-APIM-019, LGC-APIM-020 (liên quan) |
| UC-15-26 | REQ-15 | BP-01 | LGC-APIM-022 (phần nhà phát triển) |
| UC-15-27, 28 | REQ-15 | BP-01 | Không (chức năng mới) |
| UC-15-29 | REQ-15 | BP-09 | LGC-APIM-007 |
| UC-15-30, 31 | REQ-15 | BP-09 | LGC-APIM-007 |

: Use case, REQ, quy trình và hệ cũ

### 5.4. Truy vết ngược: FR sang use case

Bảng dưới cho thấy mỗi FR của PH-15 thuộc use case nào; không FR nào bị bỏ sót.

| FR | UC | FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|---|---|
| FR-15-001 | 04 | FR-15-017 | 09 | FR-15-033 | 13 | FR-15-049 | 26 |
| FR-15-002 | 01 | FR-15-018 | 08 | FR-15-034 | 18 | FR-15-050 | 26 |
| FR-15-003 | 01 | FR-15-019 | 10 | FR-15-035 | 19 | FR-15-051 | 27 |
| FR-15-004 | 01 | FR-15-020 | 11 | FR-15-036 | 19 | FR-15-052 | 27 |
| FR-15-005 | 02 | FR-15-021 | 12 | FR-15-037 | 19 | FR-15-053 | 28 |
| FR-15-006 | 03 | FR-15-022 | 13 | FR-15-038 | 19 | FR-15-054 | 28 |
| FR-15-007 | 01 | FR-15-023 | 12 | FR-15-039 | 19 | FR-15-055 | 28 |
| FR-15-008 | 01 | FR-15-024 | 12 | FR-15-040 | 20 | FR-15-056 | 29 |
| FR-15-009 | 05 | FR-15-025 | 14 | FR-15-041 | 20 | FR-15-057 | 29 |
| FR-15-010 | 05 | FR-15-026 | 14 | FR-15-042 | 21 | FR-15-058 | 30 |
| FR-15-011 | 05 | FR-15-027 | 15 | FR-15-043 | 22 | FR-15-059 | 30 |
| FR-15-012 | 05 | FR-15-028 | 15 | FR-15-044 | 23 | FR-15-060 | 31 |
| FR-15-013 | 03 | FR-15-029 | 15 | FR-15-045 | 23 | FR-15-061 | 04 |
| FR-15-014 | 06 | FR-15-030 | 16 | FR-15-046 | 24 | FR-15-062 | 08 |
| FR-15-015 | 07 | FR-15-031 | 16 | FR-15-047 | 25 | | |
| FR-15-016 | 07 | FR-15-032 | 17 | FR-15-048 | 26 | | |

: Truy vết ngược từ FR sang use case (số là UC-15-nn)

## 6. Đặc tả chi tiết use case

Chương này đặc tả 31 use case theo nhóm nghiệp vụ: khám phá và tài liệu (6.1 đến 6.5), nội dung (6.6 đến 6.9), tài khoản (6.10 đến 6.13), ứng dụng và thông tin xác thực (6.14 đến 6.17), sandbox và thử (6.18 đến 6.22), điểm vào nghiệp vụ và theo dõi (6.23 đến 6.28), quản trị cổng (6.29 đến 6.31). Năm use case nhiều thành phần (UC-15-04, 15, 19, 22, 23) có thêm sơ đồ trình tự.

### 6.1. UC-15-01 · Duyệt danh mục theo mức hiển thị, kể cả khách ẩn danh

::: dac-ta
**Mục tiêu.** Người xem thấy đúng các dịch vụ mình được phép thấy, lọc và sắp xếp được, và không biết đến dịch vụ ngoài tầm.

**Tác nhân chính.** `ROLE-DEVELOPER` (An, Bình), khách ẩn danh (Lan).

**Tác nhân phụ.** PH-02 (nguồn danh mục, qua bản sao), OpenSearch.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-002, 003, 004, 007, 008.

**Truy vết.** REQ-15; BP-01 bước tìm dịch vụ; LGC-APIM-006, LGC-APIM-007.

**Tiền điều kiện.** Bản sao danh mục đã nạp (UC-15-04). Với Lan: `15.public.enabled = true`.

**Kích hoạt.** Người dùng mở `/` hoặc `/dich-vu` ở tên miền cổng của T68.

**Đảm bảo tối thiểu.** Không dịch vụ ngoài tầm nào xuất hiện ở danh sách, facet, gợi ý hay tải đặc tả.

**Đảm bảo thành công.** Danh sách chỉ gồm API `portalPublished = true`, trạng thái `PUBLISHED`, `DEPRECATED` (và `SUSPENDED` có nhãn), đúng hạng người xem.

**Luồng chính.**

1. An mở `/`. Hệ thống xác định tenant `T68` từ tên miền và hạng người xem `DEV_USER`, rồi dựng trang chủ: khối tìm kiếm, tối đa 8 API nổi bật, trang `bat-dau-nhanh` được ghim, tối đa 3 thông báo (API-15-002).
2. An bấm "Danh mục dịch vụ". Hệ thống gọi API-15-005 và API-15-006, trả danh sách phân trang kèm facet tính trên tập đã được phép thấy.
3. An lọc `linh-vuc=tu-phap`, `xac-thuc=oauth2`, sắp xếp theo tên. Bộ lọc giữ trên URL.
4. Hệ thống không hiện API `dataClass = SENSITIVE` vì An là tài khoản `dh-dev` (BR-15-004).
5. An thấy `tra-cuu-ho-tich` (`PUBLISHED`, xanh) và một API `DEPRECATED` (vàng); mục `RETIRED`, `SUSPENDED` ẩn mặc định.

**Luồng thay thế.**

- **1a. Lan là khách ẩn danh.** Hệ thống dùng API-15-001, 003, 004: chỉ API `PUBLIC` có `dataClass = PUBLIC` và trang `audience = PUBLIC`; không hiện đầu mối, địa chỉ nội bộ; thao tác cần đăng nhập hiện lời mời đăng nhập (BR-15-005, BR-15-006).
- **1b. Tenant tắt chế độ công khai.** Khách bị chuyển tới `/dang-nhap`, không hiện lỗi.
- **3a. Bật "đã ngừng".** Hệ thống hiện thêm mục `RETIRED` kèm nhãn.
- **5a. Chọn "Dịch vụ sự kiện".** Hệ thống gọi API-15-013, hiện topic (`kind = EVENT`) kèm nút mở sang PH-10; cổng không đăng ký thay.
- **5b. Đồng bộ `STALE`.** Banner "chưa mới nhất" hiện nhưng danh sách vẫn đọc được.

**Luồng ngoại lệ.**

- **E1. Bản sao chưa nạp xong (bước 1).** ERR-15-008. "Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút." Các khối nội dung vẫn hiện.
- **E2. Giá trị lọc hoặc `co` sai miền (bước 3).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E3. Mở trực tiếp API ngoài tầm.** ERR-15-001 (404, thân giống API không tồn tại). "Không tìm thấy nội dung yêu cầu."
- **E4. Khách vượt 120 lượt mỗi phút mỗi IP (1a).** ERR-15-007. "Thao tác quá nhanh. Thử lại sau {n} giây."

**Quy tắc áp dụng.** BR-15-002, 003, 004, 005, 006, 033.

**Màn hình, API.** UI-15-01, 02; API-15-001…006, 013, 014.
:::

### 6.2. UC-15-02 · Tìm kiếm toàn văn tiếng Việt và gợi ý

::: dac-ta
**Mục tiêu.** Tìm dịch vụ, trang hướng dẫn, topic bằng tiếng Việt có hoặc không dấu, không lộ tiêu đề API ngoài tầm.

**Tác nhân chính.** `ROLE-DEVELOPER` (Bình), khách ẩn danh.

**Tác nhân phụ.** OpenSearch (dự phòng PostgreSQL FTS với `unaccent`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-005.

**Truy vết.** REQ-15; BP-01 bước tìm dịch vụ; LGC-APIM-006.

**Tiền điều kiện.** Chỉ mục đã dựng; `15.search.engine` là `OPENSEARCH` hoặc `PG_FTS`.

**Kích hoạt.** Gõ vào ô tìm kiếm lớn ở UI-15-01 hoặc bấm Enter.

**Đảm bảo tối thiểu.** Kết quả và gợi ý luôn qua bộ lọc người xem ở mức truy vấn.

**Đảm bảo thành công.** Danh sách xếp hạng có đoạn trích tô sáng, không lộ mục ngoài tầm.

**Luồng chính.**

1. Bình gõ "ho tich". Từ ký tự thứ 2, giao diện gọi API-15-012; hệ thống bỏ dấu, hạ chữ thường và trả tối đa 8 gợi ý sau không quá 200 ms.
2. Bình bấm Enter. Giao diện chuyển `/tim-kiem?q=ho%20tich` và gọi API-15-011.
3. Hệ thống tìm trên mã, tên, mô tả, thẻ của API, tiêu đề và nội dung trang đã đăng, tên topic; xếp hạng khớp mã, tên, thẻ, mô tả, nội dung.
4. Hệ thống áp bộ lọc người xem và ngôn ngữ trang, rồi trả kết quả có tô sáng bản có dấu ("Tra cứu **hộ tịch**").
5. Bình mở `tra-cuu-ho-tich` từ kết quả (tiếp UC-15-03).

**Luồng thay thế.**

- **1a. Khách ẩn danh.** Giao diện dùng API-15-010; chỉ trả mục `PUBLIC`.
- **2a. OpenSearch không trả lời.** Hệ thống chuyển sang PostgreSQL FTS và hiện banner nhẹ "Đang dùng tìm kiếm cơ bản."

**Luồng ngoại lệ.**

- **E1. Từ khóa rỗng hoặc dài quá 200 ký tự (bước 2).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E2. Gõ quá nhanh (bước 1).** ERR-15-007. "Thao tác quá nhanh. Thử lại sau {n} giây."
- **E3. Không có kết quả.** Không phải lỗi; hiện "Không có dịch vụ nào khớp. Thử bỏ bớt bộ lọc."

**Quy tắc áp dụng.** BR-15-002, 005, 006.

**Màn hình, API.** UI-15-03; API-15-010, 011, 012.
:::

### 6.3. UC-15-03 · Xem chi tiết dịch vụ, đường dẫn sử dụng, lộ trình ngừng

::: dac-ta
**Mục tiêu.** Nhà phát triển biết dịch vụ làm gì, ai chủ quản, cam kết gì, gọi ra sao và có sắp ngừng không, trước khi quyết định dùng.

**Tác nhân chính.** `ROLE-DEVELOPER` (An), khách ẩn danh.

**Tác nhân phụ.** PH-02 (mẫu gọi, SLA, lịch sử phiên bản).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-006, 013.

**Truy vết.** REQ-15; BP-01; LGC-APIM-017, LGC-IAM-006 (thay bằng hướng dẫn `client_credentials`).

**Tiền điều kiện.** `tra-cuu-ho-tich` nằm trong tập An được phép thấy.

**Kích hoạt.** An mở `/dich-vu/tra-cuu-ho-tich`.

**Đảm bảo tối thiểu.** Phần nào PH-02 không trả được thì hiện "Chưa tải được", phần còn lại vẫn hiện; cổng không sửa gì ở PH-02.

**Đảm bảo thành công.** Trang hiện đủ mô tả, SLA, gói, khối "Cách gọi API" và các nút theo ngữ cảnh.

**Luồng chính.**

1. Hệ thống gọi API-15-007 nạp mục danh mục và phiên bản `v2` mới nhất (tham số `phien-ban`).
2. Hệ thống hiện mô tả, đơn vị chủ quản Sở Tư pháp, HTTT cung cấp `HT-TUPHAP`, nhãn dữ liệu, trạng thái vòng đời (chỉ đọc), danh sách phiên bản và gói.
3. Hệ thống hiện SLA công khai (sẵn sàng, độ trễ, giờ phục vụ); đầu mối kỹ thuật chỉ hiện cho người đã đăng nhập.
4. Khối "Cách gọi API" (API-15-008) hiện địa chỉ gốc, địa chỉ lấy token của realm, phạm vi cần xin, tiêu đề bắt buộc và mẫu `curl` với giá trị giữ chỗ.
5. Hệ thống hiện nút "Đọc tài liệu", "Thử API", "Theo dõi thay đổi", "Hỏi đáp"; "Đăng ký sử dụng" chỉ hiện cho cán bộ đầu mối.
6. Phiên bản `v1` đang `DEPRECATED`: hệ thống hiện banner không đóng được "Phiên bản 1 sẽ ngừng ngày {ngày}. Chuyển sang v2." kèm liên kết so sánh. Tab `/thay-doi` (API-15-021) hiện dòng thời gian công bố, thay đổi phá vỡ, ngừng khuyến nghị, đổi SLA.

**Luồng thay thế.**

- **4a. Người xem không đủ điều kiện xem địa chỉ production.** Khối chỉ hiện địa chỉ sandbox.
- **6a. Đơn vị của An đang dùng `v1`.** Banner thêm "Đơn vị của bạn đang dùng phiên bản này."
- **6b. Chi (SV) mở trang.** Cảnh báo "Thiếu thông tin công bố" kèm liên kết sang PH-02 nếu mô tả, SLA hoặc đầu mối còn trống; cổng không sửa.

**Luồng ngoại lệ.**

- **E1. Dịch vụ ngoài tầm (bước 1).** ERR-15-001. "Không tìm thấy nội dung yêu cầu."
- **E2. Phiên bản đã ngừng hẳn.** ERR-15-038. "Phiên bản này đã ngừng cung cấp."
- **E3. PH-02 không trả được mẫu gọi (bước 4).** Khối hiện "Chưa tải được mẫu gọi. Thử lại." (ERR-15-030 chỉ ghi nhật ký).
- **E4. Danh mục quá cũ.** Hiện cảnh báo "chưa mới nhất"; quá 24 giờ thì ẩn nút thử production (BR-15-033).

**Quy tắc áp dụng.** BR-15-001, 002, 006, 027, 033.

**Màn hình, API.** UI-15-04, 05; API-15-007, 008, 015, 021.
:::

### 6.4. UC-15-04 · Đồng bộ và đối soát danh mục với PH-02

::: dac-ta
**Mục tiêu.** Bản sao danh mục ở cổng khớp PH-02 trong 30 giây bình thường và bắt kịp trong 5 phút kể cả khi mất sự kiện; quản trị đối soát được.

**Tác nhân chính.** `portal` (máy); `ROLE-TENANT_ADMIN` (Hà) cho đồng bộ lại và đối soát.

**Tác nhân phụ.** PH-02 (API-02-081, EVT-02-xx), Kafka, OpenSearch, PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-001, 061.

**Truy vết.** REQ-15; BP-01, BP-09; LGC-APIM-006; SRS cũ FR-15-001, SRS cũ FR-15-005.

**Tiền điều kiện.** PH-02 khả dụng; `portal-catalog` có scope `catalog:portal-read`; Hà có `PERM-15-portal-admin`.

**Kích hoạt.** Sự kiện EVT-02-01/02/03/05/06/08/10/11/12; chu kỳ kéo bù `15.sync.interval-seconds`; Hà bấm "Đồng bộ lại" hoặc "Đối soát" ở UI-15-27.

**Đảm bảo tối thiểu.** Khi PH-02 hỏng, cổng vẫn phục vụ bản sao cũ kèm banner, không xóa mục nào.

**Đảm bảo thành công.** Mục danh mục có `sourceVersion` mới nhất, chỉ mục tìm kiếm và bộ đệm được làm mới, `SyncRun` được ghi.

**Luồng chính.**

1. `portal` nhận EVT-02-02 của `tra-cuu-ho-tich`, loại trùng theo mã sự kiện (inbox) và xếp hàng theo `apiCode`.
2. `portal` gọi API-02-081 với `updatedSince`, phân trang tới hết.
3. Với mục có `sourceVersion` mới hơn, `portal` ghi đè bản sao; mục trong `removed[]` bị ẩn mềm.
4. Với phiên bản mới, `portal` tải đặc tả đã gộp, tính `contentHash`, phân tích thành mô hình thao tác.
5. `portal` cập nhật OpenSearch theo mức hiển thị, vô hiệu bộ đệm trang chi tiết.
6. `portal` ghi mốc đồng bộ, chỉ số `dh_portal_sync_lag_seconds`; nếu trạng thái đổi thì phát EVT-15-14.
7. Hà mở UI-15-27, bấm "Đối soát": hệ thống gọi API-15-133, so tổng hợp và băm của PH-02 với bản sao, hiện mục thiếu, thừa, lệch băm; với `fix = true` chạy đồng bộ lại đúng các mục lệch.

**Luồng thay thế.**

- **2a. Lần nạp đầu.** `updatedSince` để trống, nạp đầy.
- **3a. Hà bấm "Đồng bộ lại" nạp đầy (API-15-131).** Hệ thống tạo `SyncRun` kiểu nạp đầy hoặc cho một API.
- **4a. Đặc tả không phân tích được.** Mục vẫn nạp, phiên bản ghi lỗi phân tích (ERR-15-009 chỉ ghi nhật ký).

**Luồng ngoại lệ.**

- **E1. PH-02 lỗi `5xx` hoặc quá hạn (bước 2).** Thử lại lùi mũ 5, 30, 120 giây; quá `15.sync.stale-seconds` thì `STALE`, hiện banner. ERR-15-030 "Chưa kết nối được dịch vụ danh mục." chỉ hiện ở màn quản trị.
- **E2. Chưa từng nạp xong.** ERR-15-008. "Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút."
- **E3. Đang có lần chạy khác (bước 7, 3a).** ERR-15-035. "Đang có lần chạy khác. Đợi hoàn tất rồi thử lại."
- **E4. Chênh lệch dai dẳng sau sửa.** Hệ thống tạo cảnh báo cho PH-13; không hiện lỗi cho người dùng cuối.

**Quy tắc áp dụng.** BR-15-001, 033; NFR-15-004.

**Màn hình, API.** UI-15-27; API-15-009, 131…134; API-02-081.
:::

```{.mermaid caption="Trình tự đồng bộ danh mục từ PH-02"}
sequenceDiagram
  autonumber
  participant P2 as PH-02
  participant K as Kafka
  participant PT as portal
  participant OS as OpenSearch
  P2->>K: EVT-02-02 API đổi
  K->>PT: Nhận sự kiện, loại trùng
  PT->>P2: API-02-081 updatedSince
  P2-->>PT: items và removed
  PT->>PT: Ghi đè bản sao, phân tích đặc tả
  PT->>OS: Cập nhật chỉ mục theo mức hiển thị
  PT->>K: EVT-15-14 nếu trạng thái đổi
```

Hình cho thấy sự kiện chỉ là tín hiệu; dữ liệu luôn lấy lại từ API-02-081 nên mất sự kiện chỉ làm chậm tới chu kỳ kéo bù, không làm sai bản sao.

### 6.5. UC-15-05 · Đọc tài liệu API, chọn phiên bản, tải, so sánh, lấy mẫu mã

::: dac-ta
**Mục tiêu.** Nhà phát triển đọc đặc tả OpenAPI 3.1 hoặc AsyncAPI 3.0, chọn phiên bản, tải về, thấy khác biệt giữa hai phiên bản và sao chép mẫu mã chạy được.

**Tác nhân chính.** `ROLE-DEVELOPER` (An), khách ẩn danh.

**Tác nhân phụ.** PH-02 (đặc tả đã nạp).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-009, 010, 011, 012.

**Truy vết.** REQ-15; BP-01 bước đọc tài liệu, BP-02; LGC-APIM-017, LGC-IAM-006; SRS cũ FR-15-003, SRS cũ FR-15-004.

**Tiền điều kiện.** Phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED` có đặc tả đã nạp.

**Kích hoạt.** An bấm "Đọc tài liệu" ở UI-15-04, mở `/dich-vu/tra-cuu-ho-tich/tai-lieu`.

**Đảm bảo tối thiểu.** Mẫu mã không bao giờ chứa bí mật thật, chỉ giá trị giữ chỗ.

**Đảm bảo thành công.** Tài liệu dựng từ mô hình đã phân tích; tệp tải về có `ETag` theo băm.

**Luồng chính.**

1. Hệ thống gọi API-15-017, dựng mục lục trái theo `tags`, nội dung giữa theo từng thao tác: phương thức, đường dẫn, tham số, thân, phản hồi, mã lỗi RFC 9457, phạm vi cần có.
2. An chọn phiên bản `v1` ở danh sách (API-15-015); URL giữ `phien-ban=v1`, tài liệu nạp lại.
3. An mở thao tác `getHoTichByMa`: schema dạng cây thu gọn, ví dụ yêu cầu, phản hồi; liên kết sâu theo `operationId`.
4. An bấm "Sao chép mẫu", chọn `python`. Hệ thống gọi API-15-019 và sinh mẫu gồm bước lấy token, gọi thao tác, tiêu đề bắt buộc; giá trị nhạy cảm là `{CLIENT_SECRET}`.
5. An bấm "Tải đặc tả" định dạng YAML (API-15-016); hệ thống trả `tra-cuu-ho-tich-v2.yaml`.
6. An chọn "So sánh `v1` với `v2`" (API-15-020): hệ thống phân nhóm thao tác thêm, bỏ, đổi và đánh dấu thay đổi phá vỡ.

**Luồng thay thế.**

- **1a. Dịch vụ sự kiện (AsyncAPI).** Hệ thống hiện kênh, thông điệp, `payload`, mẫu nhận sự kiện Java, Python, JavaScript và nhãn "không có sandbox sự kiện" (API-15-018).
- **4a. Ngôn ngữ khác.** `curl`, `java`, `javascript`, `csharp`, `go` theo cùng mẫu cố định.
- **5a. API `RESTRICTED`, `SENSITIVE`.** Lần tải được ghi kiểm toán `DOWNLOAD_SPEC`.

**Luồng ngoại lệ.**

- **E1. Đặc tả không phân tích được (bước 1).** ERR-15-009. "Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ."
- **E2. Phiên bản ngoài tầm hoặc không có (bước 2).** ERR-15-001. "Không tìm thấy nội dung yêu cầu."
- **E3. Phiên bản đã ngừng hẳn.** ERR-15-038. "Phiên bản này đã ngừng cung cấp."
- **E4. So sánh hai phiên bản khác API (bước 6).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E5. Ngôn ngữ chưa có mẫu (bước 4).** ERR-15-003.

**Quy tắc áp dụng.** BR-15-001, 002, 006, 011.

**Màn hình, API.** UI-15-05; API-15-016…020.
:::

### 6.6. UC-15-06 · Soạn trang nội dung Markdown

::: dac-ta
**Mục tiêu.** Biên tập viên viết trang hướng dẫn, bắt đầu nhanh, FAQ, thông báo bằng Markdown an toàn, lưu nháp không mất.

**Tác nhân chính.** Chủ dịch vụ (Chi), CA, TA có `PERM-15-content-write`.

**Tác nhân phụ.** Kho đối tượng (ảnh), dịch vụ quét mã độc.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-014.

**Truy vết.** REQ-15; BP-09; SRS cũ FR-15-009, SRS cũ FR-15-010.

**Tiền điều kiện.** Chi có `PERM-15-content-write`; trang gắn API thì API thuộc tổ chức của Chi.

**Kích hoạt.** Chi bấm "Tạo trang" ở UI-15-22 hoặc mở `/quan-tri-cong/noi-dung/{ma-trang}`.

**Đảm bảo tối thiểu.** Nội dung vi phạm bộ lọc không bao giờ được lưu.

**Đảm bảo thành công.** Trang `bat-dau-nhanh` có phiên bản `DRAFT`, tự lưu mỗi 30 giây.

**Luồng chính.**

1. Chi chọn loại `QUICKSTART` và mẫu "Lấy token `client_credentials`".
2. Chi nhập `pageCode` `bat-dau-nhanh`, `lang` `vi`, `audience` `LOGGED_IN`. Hệ thống kiểm tra mã theo mẫu và chưa dùng.
3. Chi soạn Markdown với bản xem trước cạnh bên dùng cùng bộ lọc lúc hiển thị; kéo ảnh `so-do.png` (PNG, 1,2 MB) vào, hệ thống gọi API-15-033.
4. Hệ thống kiểm tra: cỡ ≤ 200 KB, không HTML thô, script, iframe, liên kết `javascript:`, ảnh ngoài kho.
5. Hệ thống lưu `DRAFT` (API-15-023 lần đầu, API-15-025 các lần sau kèm `If-Match`), ghi kiểm toán khi lưu có chủ đích.

**Luồng thay thế.**

- **1a. Trang gắn API.** Chi chọn `apiCode`; hệ thống chỉ cho API của tổ chức Chi.
- **3a. Mất kết nối.** Bản nháp phía trình duyệt giữ trong bộ nhớ trang, gửi lại khi có mạng; không ghi `localStorage`.

**Luồng ngoại lệ.**

- **E1. Mã đã dùng, kể cả trang lưu trữ (bước 2).** ERR-15-002. "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Nội dung có phần cấm (bước 4).** ERR-15-021. "Nội dung có phần không được phép: {chi tiết}."
- **E3. Tệp ảnh sai kiểu, vượt 5 MB hoặc nhiễm mã độc (bước 3).** ERR-15-024. "Tệp không hợp lệ: chỉ nhận PNG, JPEG, WebP tối đa 5 MB và không có mã độc."
- **E4. Hai người sửa cùng lúc (bước 5).** ERR-15-006. "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."
- **E5. Thiếu `PERM-15-content-write`.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-007, 012, 013, 034.

**Màn hình, API.** UI-15-21; API-15-022…025, 033.
:::

### 6.7. UC-15-07 · Gửi duyệt, duyệt, đăng, khôi phục và gỡ trang

::: dac-ta
**Mục tiêu.** Nội dung chỉ lên cổng sau khi người thứ hai duyệt; có lịch sử để so sánh, khôi phục và gỡ nhanh khi sai.

**Tác nhân chính.** Người soạn (Chi), người duyệt có `PERM-15-content-publish` (Dũng, Hà).

**Tác nhân phụ.** Hộp "Việc của tôi" (FR-00-070), OpenSearch.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-015, 016.

**Truy vết.** REQ-15; BP-09; FR-00-070, FR-00-071, FR-00-072; ADR-046.

**Tiền điều kiện.** Phiên bản `DRAFT` đạt kiểm tra nội dung (UC-15-06).

**Kích hoạt.** Chi bấm "Gửi duyệt" ở UI-15-21 hoặc Dũng mở yêu cầu duyệt loại `CONTENT`.

**Đảm bảo tối thiểu.** Không có đường nào tới `PUBLISHED` mà không qua người duyệt khác người soạn, người sửa gần nhất và người gửi.

**Đảm bảo thành công.** Phiên bản `PUBLISHED`, bản cũ `SUPERSEDED`, chỉ mục và bộ đệm làm mới, EVT-15-08 phát.

**Luồng chính.**

1. Chi bấm "Gửi duyệt". Hệ thống kiểm tra lại nội dung, chuyển `IN_REVIEW`, khóa sửa, tạo yêu cầu duyệt tới người có `PERM-15-content-publish` (API-15-026).
2. Dũng mở yêu cầu, đọc bản xem trước và khác biệt so với bản đang đăng.
3. Hệ thống kiểm tra Dũng khác Chi (người soạn, sửa gần nhất, gửi) (LP-15-01).
4. Dũng bấm "Duyệt" (API-15-027). Phiên bản thành `PUBLISHED`, bản đang đăng thành `SUPERSEDED`, chỉ mục cập nhật, phát EVT-15-08 (`content.published`).
5. Chi thấy thông báo "đã đăng". Sau đó Hà thấy trang viết sai, bấm "Gỡ đăng" kèm lý do (API-15-029): trang thành `UNPUBLISHED` ngay, xóa khỏi chỉ mục, phát EVT-15-09.
6. Chi mở lịch sử (API-15-030), chọn hai phiên bản để so sánh theo dòng, bấm "Khôi phục" (API-15-032): hệ thống tạo `DRAFT` mới và phải qua duyệt lại.

**Luồng thay thế.**

- **4a. Từ chối.** Dũng nêu lý do (API-15-028); phiên bản `REJECTED`, Chi nhận thông báo và soạn lại.
- **1b. Chi rút lại.** Trước khi duyệt, Chi đưa phiên bản `IN_REVIEW` về `DRAFT`.
- **5a. Gỡ không cần người thứ hai.** Gỡ chỉ giảm hiển thị nên một người có quyền đủ.

**Luồng ngoại lệ.**

- **E1. Người duyệt là người soạn hoặc gửi (bước 3).** ERR-15-023. "Người duyệt phải khác người soạn và người gửi duyệt."
- **E2. Trang không ở `IN_REVIEW` (bước 4) hoặc không `PUBLISHED` khi gỡ.** ERR-15-022. "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này."
- **E3. Gỡ trang `TERMS` đang hiệu lực (bước 5).** ERR-15-022; không cho gỡ điều khoản duy nhất.
- **E4. Từ chối thiếu lý do.** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E5. Phiên bản không có (bước 6).** ERR-15-001.

**Quy tắc áp dụng.** BR-15-012, 013, 034.

**Màn hình, API.** UI-15-21, 22; API-15-026…032.
:::

### 6.8. UC-15-08 · Nhập nội dung từ kho Git và di trú portal hệ cũ

::: dac-ta
**Mục tiêu.** Đưa nội dung có sẵn (thư mục `docs/` của kho tích hợp, trang portal Gravitee) vào cổng dưới dạng bản nháp, không bao giờ tự đăng.

**Tác nhân chính.** `ROLE-TENANT_ADMIN` (Hà), chủ dịch vụ (Chi) cho nhập Git.

**Tác nhân phụ.** Kho Git tài liệu, OpenBao (mã truy cập), dịch vụ quét mã độc, kho Garage (ảnh).

**Mức ưu tiên.** S.

**FR hiện thực.** FR-15-018, 062.

**Truy vết.** REQ-15; BP-09; LGC-APIM-006 (liên quan); SEC-16, SEC-33, SEC-45; FR-02-061.

**Tiền điều kiện.** Kho Git thuộc danh sách egress cho phép, có mã truy cập chỉ đọc; với di trú, PH-02 đã nhập danh mục API từ APIM cũ và có gói xuất Gravitee.

**Kích hoạt.** Chi khai báo nguồn Git ở UI-15-21; Hà tải gói ở UI-15-27 mục "Di trú".

**Đảm bảo tối thiểu.** Mọi nội dung nhập về là `DRAFT`; chạy lại cùng `migrationId` không tạo trùng.

**Đảm bảo thành công.** Các phiên bản `DRAFT` kèm `commit` hoặc báo cáo di trú, chờ UC-15-07.

**Luồng chính.**

1. Chi nhập URL kho `https://git.t68.gov.vn/tuphap/tich-hop-docs.git`, nhánh `main`, mã truy cập. Hệ thống kiểm tra URL thuộc egress, cất mã vào OpenBao (API-15-039).
2. Hệ thống đọc `portal.yaml` ở thư mục gốc, ánh xạ tệp Markdown sang `pageCode`, loại, ngôn ngữ, `audience`.
3. Chi bấm "Đồng bộ" (API-15-040) hoặc đợi chu kỳ `15.git.sync-interval-minutes`. Với tệp đổi băm, hệ thống tạo `DRAFT` mới kèm `commit` nguồn.
4. Hệ thống kiểm tra nội dung như UC-15-06; tệp vi phạm bị bỏ qua và liệt kê trong báo cáo.
5. Hà tải gói Gravitee ở UI-15-27 (API-15-135); hệ thống quét mã độc, kiểm tra cấu trúc, chuyển HTML, AsciiDoc sang Markdown, ánh xạ trang tới `apiCode` theo context path; Swagger gắn API bị bỏ qua.
6. Hà xem báo cáo xem trước (API-15-136: nhập được, bỏ qua, liên kết hỏng), bấm "Xác nhận" (API-15-137); hệ thống tạo các `DRAFT`.
7. Người gửi duyệt là người bấm "Gửi duyệt" ở UC-15-07; không ai trùng với người duyệt.

**Luồng thay thế.**

- **3a. Tệp không đổi.** Hệ thống bỏ qua, không tạo phiên bản.
- **6a. Hà hủy trước khi xác nhận.** Không tạo gì.

**Luồng ngoại lệ.**

- **E1. Kho không đọc được hoặc ngoài egress (bước 1, 3).** ERR-15-025. "Chưa kết nối được kho Git. Thử lại sau."
- **E2. Thiếu `portal.yaml`, gói sai cấu trúc hoặc có tệp cấm (bước 2, 5).** ERR-15-026. "Gói di trú sai cấu trúc hoặc có tệp không được phép."
- **E3. Tệp nhiễm mã độc (bước 5).** ERR-15-024. "Tệp không hợp lệ: chỉ nhận PNG, JPEG, WebP tối đa 5 MB và không có mã độc."
- **E4. Đang có đồng bộ hoặc di trú chạy.** ERR-15-035. "Đang có lần chạy khác. Đợi hoàn tất rồi thử lại."

**Quy tắc áp dụng.** BR-15-012, 013, 034.

**Màn hình, API.** UI-15-21, 27; API-15-038…040, 135…137.
:::

### 6.9. UC-15-09 · Đọc trang hướng dẫn, hỏi đáp, thông báo

::: dac-ta
**Mục tiêu.** Người xem đọc trang đã đăng an toàn, đúng đối tượng, có mục lục và phản hồi.

**Tác nhân chính.** `ROLE-DEVELOPER` (An), khách ẩn danh (Lan).

**Tác nhân phụ.** Kho đối tượng (ảnh ký tên).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-017.

**Truy vết.** REQ-15; SRS cũ FR-15-009; SEC-44, SEC-45.

**Tiền điều kiện.** Trang `PUBLISHED` (UC-15-07).

**Kích hoạt.** Mở `/huong-dan/bat-dau-nhanh`, `/hoi-dap` hoặc `/thong-bao`.

**Đảm bảo tối thiểu.** Không có HTML, script hay ảnh ngoài kho nào được dựng ra.

**Đảm bảo thành công.** Trang hiện đúng `audience`, ngày cập nhật, mục lục.

**Luồng chính.**

1. An mở `/huong-dan/bat-dau-nhanh` (API-15-037). Hệ thống so `audience` với hạng người xem.
2. Hệ thống dựng HTML từ Markdown qua danh sách cho phép; liên kết ngoài có `rel="noopener nofollow"`.
3. Hệ thống dựng mục lục từ tiêu đề, hiện ngày cập nhật, phiên bản, tên cổng làm tác giả (không tên cá nhân).
4. Ảnh phục vụ qua đường dẫn có chữ ký hết hạn 15 phút, `X-Content-Type-Options: nosniff`.
5. An bấm "Hữu ích" ở cuối trang (tiếp UC-15-28).

**Luồng thay thế.**

- **1a. Lan là khách.** Hệ thống dùng API-15-034, 035; chỉ trang `audience = PUBLIC`.
- **2a. Thông báo `ANNOUNCEMENT`.** Chỉ hiện trong khoảng `validFrom` đến `validTo`.
- **2b. Trang `TERMS`.** Hiện kèm nút "Đồng ý" (tiếp UC-15-12).

**Luồng ngoại lệ.**

- **E1. Trang không có hoặc ngoài tầm (bước 1).** ERR-15-001. "Không tìm thấy nội dung yêu cầu."
- **E2. Ảnh hết hạn chữ ký (bước 4).** Tải lại trang tự cấp chữ ký mới, không hiện lỗi.

**Quy tắc áp dụng.** BR-15-005, 006, 013.

**Màn hình, API.** UI-15-07; API-15-034…037.
:::

### 6.10. UC-15-10 · Đăng nhập SSO realm tenant hoặc dh-dev

::: dac-ta
**Mục tiêu.** Người dùng vào cổng bằng đúng realm, token ở máy chủ, trình duyệt chỉ có cookie phiên.

**Tác nhân chính.** `ROLE-DEVELOPER` (Bình cán bộ, An nhà thầu).

**Tác nhân phụ.** BFF, Keycloak (`dh-t68`, `dh-dev`), Valkey.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-019.

**Truy vết.** REQ-15; BO-03; SRS cũ FR-15-014; FR-00-001…003; SEC-21, SEC-23, SEC-29.

**Tiền điều kiện.** Keycloak khả dụng; tài khoản không bị khóa.

**Kích hoạt.** Bấm "Đăng nhập" ở `/dang-nhap`.

**Đảm bảo tối thiểu.** Không có token nào ở bộ nhớ JavaScript, `localStorage` hay `sessionStorage` (NFR-15-010).

**Đảm bảo thành công.** Phiên BFF hợp lệ, cookie `__Host-dh-sid`, hồ sơ có `lastLoginAt`.

**Luồng chính.**

1. Bình chọn "Cán bộ cơ quan"; An chọn "Nhà thầu". BFF chuyển tới Keycloak (`/bff/dang-nhap`) bằng Authorization Code và PKCE `S256`.
2. Keycloak xác thực, bắt MFA nếu vai trò yêu cầu (TA, CA: WebAuthn).
3. BFF đổi mã lấy token, giữ ở Valkey, đặt cookie `HttpOnly`, `Secure`, `SameSite=Strict`.
4. Lần đầu của Bình, hệ thống tạo hồ sơ nguồn `TENANT_SSO`, `ACTIVE`; hồ sơ của An đã có từ UC-15-11.
5. Hệ thống kiểm tra tài khoản `dh-dev` ở `ACTIVE` và điều khoản hiện hành (UC-15-12), cập nhật `lastLoginAt`.
6. Phiên nhàn rỗi 15 phút hoặc tối đa 10 giờ thì hết; "Đăng xuất" gọi `/bff/dang-xuat` và back-channel logout.

**Luồng thay thế.**

- **5a. Điều khoản mới.** Hộp thoại chấp nhận hiện trước khi vào chức năng cần `PERM-15-app`, `PERM-15-try`.

**Luồng ngoại lệ.**

- **E1. Keycloak lỗi (bước 2).** ERR-15-020. "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau." Trang công khai vẫn xem được.
- **E2. An chưa xác minh thư hoặc chưa được duyệt (bước 5).** ERR-15-011. "Tài khoản chưa được xác minh hoặc chưa được duyệt."
- **E3. Tài khoản khóa hoặc vô hiệu.** ERR-15-014. "Tài khoản đang bị khóa. Liên hệ quản trị cổng."
- **E4. Phiên hết hạn khi thao tác.** ERR-15-004. "Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục."

**Quy tắc áp dụng.** BR-15-004, 028, 031.

**Màn hình, API.** UI-15-08; `/bff/dang-nhap`, `/bff/dang-xuat`; API-15-041.
:::

### 6.11. UC-15-11 · Tự đăng ký tài khoản dh-dev

::: dac-ta
**Mục tiêu.** Nhà thầu tự đăng ký, được xác minh là chủ hộp thư và được quản trị duyệt trước khi có quyền.

**Tác nhân chính.** Nhà thầu (An).

**Tác nhân phụ.** Keycloak `dh-dev`, dịch vụ thư; Hà (duyệt ở UC-15-30).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-020.

**Truy vết.** REQ-15; BO-03; SRS cũ FR-15-014; CMP-LAW-05; SEC-22, SEC-27.

**Tiền điều kiện.** `15.dev.signup-enabled = true`.

**Kích hoạt.** An bấm "Đăng ký" ở `/dang-ky`.

**Đảm bảo tối thiểu.** Chưa xác minh thư hoặc chưa duyệt thì không có quyền gì; tài khoản chưa xác minh quá 24 giờ bị xóa.

**Đảm bảo thành công.** Tài khoản `PENDING_APPROVAL`, EVT-15-06 phát, yêu cầu duyệt nằm ở "Việc của tôi" của TA.

**Luồng chính.**

1. An nhập họ tên, thư `an@abc.example.vn`, tổ chức "Công ty ABC", số hợp đồng, đơn vị bảo lãnh, mật khẩu 14 ký tự; xác nhận đã đọc thông báo xử lý dữ liệu và điều khoản.
2. Hệ thống kiểm tra thư chưa đăng ký, mật khẩu đạt chính sách, tần suất theo IP (API-15-045).
3. Hệ thống tạo tài khoản `PENDING_EMAIL`, người dùng bị vô hiệu ở `dh-dev`, gửi thư chỉ chứa liên kết xác minh hiệu lực 24 giờ.
4. An bấm liên kết (API-15-046). Hệ thống chuyển `PENDING_APPROVAL`, phát EVT-15-06, tạo yêu cầu duyệt cho TA.
5. Hà duyệt ở UC-15-30; An nhận thư báo có liên kết đăng nhập.

**Luồng thay thế.**

- **3a. An quá 24 giờ chưa xác minh.** Tài khoản `EXPIRED`, bị xóa khỏi realm; An đăng ký lại.
- **5a. Bị từ chối.** Tài khoản `REJECTED` kèm lý do; An đăng ký lại với thông tin khác.

**Luồng ngoại lệ.**

- **E1. Thư đã đăng ký (bước 2).** ERR-15-012. "Thư điện tử này đã được đăng ký."
- **E2. Mã xác minh sai hoặc hết hạn (bước 4).** ERR-15-013. "Mã xác minh không đúng hoặc đã hết hạn."
- **E3. Đăng ký quá nhiều từ một IP.** ERR-15-037. "Bạn gửi quá nhiều. Thử lại sau {n} phút."
- **E4. Dữ liệu sai.** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

**Quy tắc áp dụng.** BR-15-028, 029.

**Màn hình, API.** UI-15-08; API-15-045, 046.
:::

### 6.12. UC-15-12 · Hồ sơ, phiên, điều khoản, vô hiệu hóa và xóa tài khoản

::: dac-ta
**Mục tiêu.** Người dùng tự quản hồ sơ và phiên, đồng ý điều khoản có phiên bản; tài khoản `dh-dev` không hoạt động bị vô hiệu và dữ liệu cá nhân được xóa theo yêu cầu.

**Tác nhân chính.** `ROLE-DEVELOPER` (An); `portal` (tác vụ định kỳ).

**Tác nhân phụ.** Keycloak `dh-dev`, Valkey, PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-021, 023, 024.

**Truy vết.** REQ-15; BO-03; CMP-LAW-05; FR-00-005, FR-00-061; SEC-27, SEC-39.

**Tiền điều kiện.** Đã đăng nhập; có trang `TERMS` đang đăng (UC-15-07).

**Kích hoạt.** Mở `/tai-khoan`, `/tai-khoan/dieu-khoan`; tác vụ hằng ngày quét tài khoản.

**Đảm bảo tối thiểu.** Người chưa đồng ý điều khoản vẫn đọc được danh mục và tài liệu.

**Đảm bảo thành công.** Hồ sơ lưu với `If-Match`; chấp nhận điều khoản ghi phiên bản, thời điểm, băm địa chỉ nguồn.

**Luồng chính.**

1. An mở hồ sơ (API-15-041), sửa số điện thoại; thư và tổ chức của cán bộ SSO chỉ đọc. Hệ thống lưu với `If-Match` (API-15-042).
2. An xem phiên đang mở (API-15-043) và thu hồi phiên "Máy văn phòng" (API-15-044); hệ thống hủy phiên BFF ở Valkey.
3. Điều khoản `v3` có hiệu lực: hộp thoại chặn thao tác cần `PERM-15-app`, `PERM-15-try`; An đánh dấu và bấm "Đồng ý" (API-15-048).
4. `portal` cảnh báo tài khoản không đăng nhập 30 và 40 ngày, đến ngày 45 chuyển `DISABLED`, tắt người dùng ở `dh-dev`, tạm ngừng ứng dụng thuộc riêng người này; phát EVT-15-07.
5. An yêu cầu xóa (API-15-054), gõ cụm từ xác nhận: hệ thống thu hồi mọi thông tin xác thực, chuyển ứng dụng nhóm cho chủ khác hoặc lưu trữ, ẩn danh họ tên, thư, tổ chức; kiểm toán giữ nguyên theo WORM nhưng chỉ tham chiếu mã ẩn danh.

**Luồng thay thế.**

- **4a. Kích hoạt lại.** Tài khoản `DISABLED` gửi yêu cầu, chuyển `PENDING_APPROVAL` để TA duyệt (UC-15-30).
- **4b. 24 tháng không hoạt động.** Hệ thống ẩn danh tự động (`15.dev.anonymize-after-months`).

**Luồng ngoại lệ.**

- **E1. Hồ sơ bị sửa nơi khác (bước 1).** ERR-15-006. "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."
- **E2. Chưa đồng ý điều khoản khi tạo ứng dụng hoặc thử (bước 3).** ERR-15-010. "Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục."
- **E3. Cụm xác nhận xóa sai (bước 5).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E4. An là chủ duy nhất của nhóm còn thành viên (bước 5).** ERR-15-028. "Phải còn ít nhất một chủ sở hữu."
- **E5. Thu hồi phiên không phải của mình.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-008, 028, 029, 034.

**Màn hình, API.** UI-15-09, 24; API-15-041…044, 047, 048, 054.
:::

### 6.13. UC-15-13 · Nhóm phát triển và thành viên ứng dụng

::: dac-ta
**Mục tiêu.** Đội nhiều người cùng sở hữu ứng dụng với vai trò rõ, không còn ứng dụng mồ côi.

**Tác nhân chính.** `ROLE-DEVELOPER` (An chủ nhóm, Bình thành viên).

**Tác nhân phụ.** Hộp thông báo (UC-15-27), dịch vụ thư.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-15-022, 033.

**Truy vết.** REQ-15; LGC-APIM-020 (liên quan); D02-08 `ROLE-DEVELOPER` (ứng dụng được giao).

**Tiền điều kiện.** Đã đăng nhập, đã đồng ý điều khoản; người được mời có tài khoản cùng tenant.

**Kích hoạt.** An bấm "Tạo nhóm" ở `/tai-khoan/nhom` hoặc "Thêm thành viên" ở tab `thanh-vien`.

**Đảm bảo tối thiểu.** Luôn còn ít nhất một `OWNER`.

**Đảm bảo thành công.** Nhóm `nhom-thau-a` có An (`OWNER`) và Bình (`DEVELOPER`); EVT-15-13 phát.

**Luồng chính.**

1. An tạo nhóm `nhom-thau-a` (API-15-050); hệ thống đặt An làm `OWNER`.
2. An mời Bình theo thư (API-15-051); lời mời `PENDING` hết hạn sau 7 ngày, gửi thông báo và thư chỉ có liên kết.
3. Bình chấp nhận ở hộp thông báo (API-15-052); lời mời `ACCEPTED`, phát EVT-15-13.
4. Ứng dụng `app-tra-cuu-ho-tich` thuộc nhóm hiện cho cả hai theo vai trò. Với ứng dụng cá nhân, An thêm thành viên trực tiếp (API-15-067).
5. Quyền theo vai trò: `OWNER` mọi việc kể cả giao người; `DEVELOPER` thử, cấp, xoay, thu hồi; `VIEWER` chỉ xem thống kê và nhật ký.
6. An đổi vai trò hoặc xóa thành viên (API-15-053, 068); thành viên thừa hưởng từ nhóm chỉ đổi ở nhóm.

**Luồng thay thế.**

- **3a. Bình từ chối hoặc để quá 7 ngày.** Lời mời `DECLINED` hoặc `EXPIRED`.
- **6a. Thành viên tự rời nhóm.** Cho phép nếu không phải `OWNER` cuối.

**Luồng ngoại lệ.**

- **E1. Mã nhóm trùng (bước 1).** ERR-15-002. "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Đã là thành viên hoặc đã có lời mời (bước 2).** ERR-15-027. "Người này đã là thành viên hoặc đã có lời mời."
- **E3. Xóa hoặc rời khi là chủ duy nhất (bước 6).** ERR-15-028. "Phải còn ít nhất một chủ sở hữu."
- **E4. `VIEWER` cố đổi thành viên.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-007, 009.

**Màn hình, API.** UI-15-09, 12; API-15-049…053, 066…068.
:::

### 6.14. UC-15-14 · Tạo và quản lý ứng dụng sandbox

::: dac-ta
**Mục tiêu.** Nhà phát triển có ứng dụng sandbox đại diện cho phần mềm đang phát triển, quản lý trạng thái và lưu trữ khi không dùng.

**Tác nhân chính.** `ROLE-DEVELOPER` (An).

**Tác nhân phụ.** PH-01 (kiểm tra HTTT khi liên kết), `portal` (tự lưu trữ).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-025, 026.

**Truy vết.** REQ-15; BP-01 bước nhận thông tin sandbox; LGC-APIM-020 (liên quan); SRS cũ FR-15-008.

**Tiền điều kiện.** Tài khoản `ACTIVE`, đã đồng ý điều khoản, có `PERM-15-app`.

**Kích hoạt.** An bấm "Tạo ứng dụng" ở `/ung-dung/moi`.

**Đảm bảo tối thiểu.** Ứng dụng không bao giờ có quyền production.

**Đảm bảo thành công.** Ứng dụng `ACTIVE`, An là `OWNER`, EVT-15-01 phát.

**Luồng chính.**

1. An nhập tên "Tra cứu hộ tịch", mã `app-tra-cuu-ho-tich`, chủ là nhóm `nhom-thau-a`. Hệ thống kiểm tra mã theo mẫu, chưa dùng kể cả mã đã lưu trữ.
2. Hệ thống kiểm tra giới hạn `15.app.max-per-user` (10) hoặc `15.app.max-per-team` (30).
3. Bình (cán bộ) có thể chọn liên kết `HT-DATDAI` để xem tham chiếu production (UC-15-17); nhà thầu không có trường này.
4. Hệ thống tạo ứng dụng (API-15-056), ghi kiểm toán, phát EVT-15-01.
5. Ở `/ung-dung/{ma-ung-dung}` An sửa mô tả với `If-Match` (API-15-058).
6. An lưu trữ ứng dụng (API-15-059): hệ thống thu hồi mọi thông tin xác thực (UC-15-16), chuyển `ARCHIVED`, phát EVT-15-02.

**Luồng thay thế.**

- **6a. Khôi phục trong 30 ngày (API-15-060).** Về `ACTIVE`, không khôi phục bí mật; quá 30 ngày ứng dụng bị xóa.
- **6b. 180 ngày không có lượt gọi.** `portal` cảnh báo 14 ngày rồi tự lưu trữ.

**Luồng ngoại lệ.**

- **E1. Mã trùng (bước 1).** ERR-15-002. "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Vượt số ứng dụng (bước 2).** ERR-15-015. "Đã đạt số ứng dụng tối đa ({n}). Lưu trữ ứng dụng không dùng để tạo mới."
- **E3. Chưa đồng ý điều khoản.** ERR-15-010. "Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục."
- **E4. HTTT không thuộc đơn vị (bước 3).** ERR-15-032. "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này."
- **E5. Lưu trữ ứng dụng đã `ARCHIVED`.** ERR-15-017. "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."
- **E6. Không phải thành viên.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-007, 008, 009, 010, 034.

**Màn hình, API.** UI-15-10, 11, 12; API-15-055…060.
:::

### 6.15. UC-15-15 · Cấp thông tin xác thực sandbox, hiện bí mật một lần

::: dac-ta
**Mục tiêu.** Ứng dụng có `client_credentials` sandbox hoặc API key để gọi sandbox; bí mật hiện đúng một lần và không để lại dấu vết.

**Tác nhân chính.** `ROLE-DEVELOPER` (An).

**Tác nhân phụ.** Keycloak `dh-dev` (Admin API giới hạn), PH-03 (`forward-auth`), PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-027, 028, 029.

**Truy vết.** REQ-15; BP-01; LGC-IAM-006 (thay thế); SEC-24, SEC-25, SEC-32, SEC-33; NFR-15-009.

**Tiền điều kiện.** Ứng dụng `ACTIVE`; chưa đạt `15.cred.max-per-app` (3).

**Kích hoạt.** An bấm "Cấp thông tin xác thực" ở `/ung-dung/app-tra-cuu-ho-tich/xac-thuc`.

**Đảm bảo tối thiểu.** Cấp lỗi giữa chừng thì xóa client đã tạo, không để bản ghi nửa vời.

**Đảm bảo thành công.** Bản ghi `ACTIVE` chỉ có tiền tố 8 ký tự và băm; EVT-15-03 phát; bí mật đã hiện một lần.

**Luồng chính.**

1. An chọn loại `CLIENT_CREDENTIALS`; BFF gọi API-15-062 kèm `Idempotency-Key`.
2. `portal` kiểm tra quyền, trạng thái ứng dụng và giới hạn, rồi tạo client `sbx-t68-app-tra-cuu-ho-tich-1` ở `dh-dev`, bật service account, chỉ scope `sandbox:call`, token sống 5 phút.
3. `portal` lưu `credentialId`, `clientId`, tiền tố bí mật, `expiresAt`; không lưu bí mật.
4. Phản hồi mang `no-store`; giao diện hiện bí mật trong ô bí mật, có "Sao chép", "Tải tệp `.env`"; hộp thoại không đóng cho tới khi An đánh dấu "Tôi đã lưu bí mật".
5. Giao diện xóa bí mật khỏi bộ nhớ khi đóng; không có chức năng xem lại.
6. Mẫu mã lấy token (UC-15-05) hiện kèm địa chỉ token của `dh-dev`.

**Luồng thay thế.**

- **1a. API key.** `portal` sinh khóa 32 byte `dhsk_t68_…`, lưu băm SHA-256 có muối; dùng ở `X-API-Key` của tuyến sandbox, không dùng được ở production.
- **1b. An nạp `jwks`.** Client dùng `private_key_jwt` thay `client_secret_basic`.

**Luồng ngoại lệ.**

- **E1. Vượt giới hạn (bước 2).** ERR-15-016. "Ứng dụng đã đạt số thông tin xác thực tối đa ({n})."
- **E2. Ứng dụng không `ACTIVE`.** ERR-15-017. "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."
- **E3. Keycloak lỗi (bước 2).** ERR-15-020. "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau." Không để lại client.
- **E4. Phát lại yêu cầu đã trả bí mật (bước 4).** ERR-15-019. "Bí mật chỉ hiện một lần và không xem lại được. Tạo thông tin xác thực mới nếu đã mất."
- **E5. Thiếu quyền.** ERR-15-005.

**Quy tắc áp dụng.** BR-15-010, 011, 015.

**Màn hình, API.** UI-15-13; API-15-061, 062.
:::

```{.mermaid caption="Trình tự cấp thông tin xác thực sandbox"}
sequenceDiagram
  autonumber
  actor An
  participant BFF as BFF dh-portal
  participant PT as portal
  participant KC as Keycloak dh-dev
  participant DB as ph15_portal
  An->>BFF: Cấp thông tin xác thực
  BFF->>PT: API-15-062 kèm Idempotency-Key
  PT->>KC: Tạo client sbx-t68-... scope sandbox:call
  KC-->>PT: clientId và bí mật
  PT->>DB: Lưu tiền tố và băm, không lưu bí mật
  PT-->>BFF: 201 kèm bí mật một lần
  BFF-->>An: Hiện bí mật, no-store
  PT->>PT: Phát EVT-15-03
```

Hình cho thấy bí mật đi một chiều từ Keycloak qua `portal` và BFF tới màn hình; nó không chạm cơ sở dữ liệu hay nhật ký của cổng.

### 6.16. UC-15-16 · Xoay vòng, thu hồi và hết hạn thông tin xác thực

::: dac-ta
**Mục tiêu.** Thay bí mật không gián đoạn, thu hồi nhanh khi lộ, nhắc trước khi hết hạn.

**Tác nhân chính.** `ROLE-DEVELOPER` (An); `portal` (tác vụ nhắc hạn).

**Tác nhân phụ.** Keycloak `dh-dev`, PH-03 (`forward-auth` nghe EVT-15-05), hộp thông báo.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-030, 031.

**Truy vết.** REQ-15; SEC-24, SEC-27, SEC-33.

**Tiền điều kiện.** Thông tin xác thực `ACTIVE` (xoay) hoặc `ACTIVE`, `ROTATING` (thu hồi); ứng dụng `ACTIVE`.

**Kích hoạt.** An bấm "Xoay vòng" hoặc "Thu hồi"; mốc 30, 7, 1 ngày trước hạn.

**Đảm bảo tối thiểu.** Keycloak lỗi thì giữ nguyên bản cũ (xoay) hoặc vẫn đánh dấu `REVOKED` ở cổng để chặn (thu hồi).

**Đảm bảo thành công.** Bản mới `ACTIVE`, bản cũ `ROTATING` rồi `EXPIRED`; hoặc `REVOKED` và lượt gọi mới bị chặn trong 60 giây.

**Luồng chính.**

1. An bấm "Xoay vòng" `sbx-t68-app-tra-cuu-ho-tich-1` (API-15-063). Hệ thống tạo bản mới, trả bí mật một lần như UC-15-15.
2. Bản cũ chuyển `ROTATING`, còn hiệu lực `15.cred.rotate-grace-hours` (24 giờ), phát EVT-15-04.
3. Chỉ số `dh_portal_cred_old_use_total` cho An biết còn lời gọi dùng bản cũ.
4. Hết 24 giờ bản cũ `EXPIRED`, bị xóa khỏi Keycloak.
5. Nghi lộ khóa, An bấm "Thu hồi" (API-15-064) kèm lý do: client bị vô hiệu, bản ghi `REVOKED`, phát EVT-15-05; `forward-auth` vô hiệu bộ đệm.
6. Với mốc 30, 7, 1 ngày trước `expiresAt`, `portal` gửi thông báo và thư chỉ có liên kết; tới hạn thì `EXPIRED` và phát EVT-15-05.

**Luồng thay thế.**

- **5a. Thu hồi bản `ROTATING`.** Cho phép, chấm dứt thời gian chuyển tiếp.

**Luồng ngoại lệ.**

- **E1. Thông tin xác thực không `ACTIVE` (bước 1).** ERR-15-018. "Thông tin xác thực đang {trạng thái} nên không thực hiện được thao tác này."
- **E2. Keycloak lỗi khi xoay (bước 1).** ERR-15-020. "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau." Bản cũ không đổi.
- **E3. Keycloak lỗi khi thu hồi (bước 5).** ERR-15-020; bản ghi vẫn `REVOKED`, hệ thống thử lại việc xóa client.
- **E4. Đã thu hồi hoặc hết hạn.** ERR-15-018.
- **E5. Vượt số thông tin xác thực khi xoay.** ERR-15-016.

**Quy tắc áp dụng.** BR-15-010, 011; NFR-15-007.

**Màn hình, API.** UI-15-13; API-15-063, 064; EVT-15-04, 05.
:::

### 6.17. UC-15-17 · Xem tham chiếu thông tin xác thực production

::: dac-ta
**Mục tiêu.** Cán bộ thấy định danh production của HTTT mình (không bí mật) để cấu hình ứng dụng, biết hạn và trạng thái.

**Tác nhân chính.** `ROLE-DEVELOPER` là cán bộ CQNN (Bình).

**Tác nhân phụ.** PH-01 (định danh production chỉ đọc).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-032.

**Truy vết.** REQ-15; BP-01; LGC-APIM-019 (liên quan); SEC-24; Q15-13.

**Tiền điều kiện.** Ứng dụng liên kết `HT-DATDAI`; Bình thuộc tổ chức của HTTT và là thành viên ứng dụng.

**Kích hoạt.** Bình mở `/ung-dung/{ma-ung-dung}/xac-thuc`, mục "Production".

**Đảm bảo tối thiểu.** Không hiện bí mật, không có nút xem bí mật.

**Đảm bảo thành công.** Hiện `clientId`, phương thức, 16 ký tự đầu dấu vân tay, hạn, trạng thái; lượt xem ghi kiểm toán.

**Luồng chính.**

1. Hệ thống kiểm tra Bình là thành viên và thuộc tổ chức của `HT-DATDAI`.
2. Hệ thống đọc từ PH-01 (bộ đệm 5 phút) định danh production (API-15-065).
3. Giao diện hiện `clientId`, phương thức `tls_client_auth`, dấu vân tay rút gọn, hạn, trạng thái `ACTIVE` hoặc `EXPIRING` (còn dưới 30 ngày), `REVOKED`.
4. Giao diện hiện liên kết "Xoay vòng hoặc nhận bí mật ở phân hệ Kết nạp" sang PH-01.
5. Hệ thống ghi kiểm toán lượt xem.

**Luồng thay thế.**

- **3a. Trạng thái `EXPIRING`.** Hiện nhắc xoay vòng ở PH-01.

**Luồng ngoại lệ.**

- **E1. An (nhà thầu) hoặc người ngoài tổ chức (bước 1).** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."
- **E2. PH-01 lỗi (bước 2).** ERR-15-031. "Chưa kết nối được dịch vụ kết nạp. Thử lại sau."

**Quy tắc áp dụng.** BR-15-004, 014, 015.

**Màn hình, API.** UI-15-13; API-15-065.
:::

### 6.18. UC-15-18 · Khai báo sandbox của dịch vụ

::: dac-ta
**Mục tiêu.** Chủ dịch vụ chọn cách sandbox phục vụ từng phiên bản: `MOCK`, `BACKEND` hoặc `OFF`.

**Tác nhân chính.** Chủ dịch vụ (Chi).

**Tác nhân phụ.** OpenBao (bí mật tiêu đề backend), danh sách egress (PH-18).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-034.

**Truy vết.** REQ-15; BO-03; SRS cũ FR-15-007; ADR-013.

**Tiền điều kiện.** Phiên bản `PUBLISHED` hoặc `DEPRECATED` ở bản sao danh mục; Chi là chủ dịch vụ của API.

**Kích hoạt.** Chi mở `/quan-tri-cong/dich-vu/tra-cuu-ho-tich`.

**Đảm bảo tối thiểu.** Backend ngoài egress hoặc không HTTPS không bao giờ được lưu.

**Đảm bảo thành công.** Hồ sơ sandbox của phiên bản được lưu, kiểm toán ghi.

**Luồng chính.**

1. Chi chọn phiên bản `v2` và chế độ `BACKEND` (API-15-069 đọc, API-15-070 ghi).
2. Chi nhập `backendUrl` `https://sandbox-tuphap.t68.gov.vn`, `healthPath` `/health`.
3. Hệ thống kiểm tra HTTPS và thuộc danh sách egress, thử `healthPath` và báo kết quả.
4. Chi nhập bí mật tiêu đề backend; hệ thống ghi một chiều vào OpenBao, không hiện lại.
5. Hệ thống lưu hồ sơ, ghi kiểm toán.

**Luồng thay thế.**

- **1a. Chế độ `MOCK`.** Hệ thống kiểm tra đặc tả đủ ví dụ hoặc schema cho mọi thao tác và liệt kê thao tác thiếu (cảnh báo ERR-15-110, vẫn lưu được); chọn `examplePolicy` `FIRST` hoặc `RANDOM`.
- **1b. `OFF`.** Khung thử của dịch vụ hiện "chưa bật sandbox".

**Luồng ngoại lệ.**

- **E1. Backend ngoài danh sách cho phép (bước 3).** ERR-15-119. "Địa chỉ hệ thống thử không nằm trong danh sách cho phép."
- **E2. Thiếu cấu hình theo chế độ.** ERR-15-120. "Dịch vụ thiếu cấu hình cho chế độ {chế độ}."
- **E3. Phiên bản đã ngừng.** ERR-15-040. "Dịch vụ này chưa đủ điều kiện cho thao tác này."
- **E4. Chi không phải chủ dịch vụ.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-017, 018, 034.

**Màn hình, API.** UI-15-23; API-15-069, 070.
:::

### 6.19. UC-15-19 · Thử API trên sandbox MOCK và BACKEND

::: dac-ta
**Mục tiêu.** Nhà phát triển gọi thử một thao tác, thấy phản hồi như thật mà không đụng dữ liệu thật hay production.

**Tác nhân chính.** `ROLE-DEVELOPER` (An).

**Tác nhân phụ.** BFF, Keycloak `dh-dev`, APISIX sandbox với `forward-auth` (API-15-082), module `portal-mock` hoặc backend thử, PH-13, Valkey.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-035, 036, 037, 038, 039.

**Truy vết.** REQ-15; BP-02; SRS cũ FR-15-007; CMP-LAW-05; SEC-43; BR-15-016.

**Tiền điều kiện.** Đã đồng ý điều khoản; dịch vụ có sandbox khác `OFF`; ứng dụng `ACTIVE` có thông tin xác thực; An là thành viên.

**Kích hoạt.** An bấm "Thử" ở UI-15-05 hoặc mở `/dich-vu/tra-cuu-ho-tich/thu`.

**Đảm bảo tối thiểu.** Không dữ liệu cá nhân thật nào vào backend thử; thân yêu cầu, phản hồi và tiêu đề xác thực không vào lịch sử, nhật ký, kiểm toán.

**Đảm bảo thành công.** Phản hồi hiện với trạng thái, độ trễ, tiêu đề; lượt thử có `tryId`, EVT-15-11 phát.

**Luồng chính.**

1. An chọn ứng dụng `app-tra-cuu-ho-tich`, thao tác `getHoTichByMa`, nhập `maHoTich = HT-2026-0001`. Bấm "Điền dữ liệu mẫu" để sinh giá trị tổng hợp (căn cước dải `000…`, thư `@example.gov.vn`).
2. Hệ thống kiểm tra thành viên, điều khoản, ứng dụng `ACTIVE`, phiên bản cho thử (API-15-071 kiểm tra yêu cầu khớp đặc tả).
3. Hệ thống quét giá trị theo `PII-15-01…06`, kiểm tra cỡ thân ≤ 256 KB, bỏ tiêu đề cấm `Authorization`, `Cookie`, `Host`.
4. Hệ thống áp hạn mức: 30 lượt mỗi phút mỗi người, 3.000 mỗi ngày mỗi ứng dụng (API-15-074 hiện số còn lại).
5. `portal` đổi token ngắn hạn cho ứng dụng ở Keycloak, gọi tuyến sandbox (API-15-072) kèm `X-DH-Try-Id`, `traceparent`; `forward-auth` (API-15-082) kiểm tra lại ứng dụng và hạn mức.
6. Chế độ `MOCK`: hệ thống kiểm tra lại yêu cầu theo đặc tả, chọn mã `2xx` đầu tiên (hoặc theo `X-DH-Mock-Status`), phản hồi ví dụ `FIRST` hoặc sinh từ schema, kèm `X-DH-Sandbox: mock`, chờ `mockLatencyMs`.
7. Chế độ `BACKEND`: hệ thống kiểm tra lại `backendUrl` còn trong egress, chuyển tiếp với `X-DH-Sandbox: backend`, thời gian chờ 15 giây, ngắt mạch sau 5 lỗi trong 30 giây.
8. Hệ thống cắt phản hồi ở 1 MB, che trường nhạy cảm (SEC-32), ghi vết lượt thử, phát EVT-15-11; giao diện hiện kết quả `OK`, độ trễ 118 ms.

**Luồng thay thế.**

- **3a. `MOCK` thấy dữ liệu giống thật.** Hệ thống cảnh báo nhưng vẫn cho gửi vì không có hệ thống nào nhận.
- **6a. An chọn `X-DH-Mock-Status: 404`.** Hệ thống trả mẫu lỗi RFC 9457 có trong đặc tả.
- **8a. Phản hồi vượt 1 MB.** Cắt và hiện cảnh báo ERR-15-123 (không chặn).

**Luồng ngoại lệ.**

- **E1. Dịch vụ chưa bật sandbox.** ERR-15-101. "Dịch vụ này chưa bật sandbox."
- **E2. Ứng dụng không đủ điều kiện hoặc phiên bản không cho thử.** ERR-15-102, ERR-15-122. "Ứng dụng chưa đủ điều kiện thử. Kiểm tra ứng dụng đang hoạt động và có thông tin xác thực."
- **E3. Yêu cầu không khớp đặc tả, thân quá lớn, tiêu đề cấm (bước 2, 3).** ERR-15-107, 105, 121. "Yêu cầu không khớp đặc tả: {chi tiết}."
- **E4. Dữ liệu cá nhân thật ở `BACKEND` (bước 3).** ERR-15-106. "Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."
- **E5. Vượt hạn mức (bước 4).** ERR-15-103 "Bạn đã vượt hạn mức thử mỗi phút. Thử lại sau {n} giây." hoặc ERR-15-104 "Ứng dụng đã vượt hạn mức thử trong ngày."
- **E6. Không sinh được `MOCK`.** ERR-15-110. "Chưa sinh được phản hồi mẫu. Dịch vụ thiếu ví dụ hoặc lược đồ."
- **E7. Backend quá hạn hoặc lỗi.** ERR-15-108 "Hệ thống thử không phản hồi trong {n} giây." hoặc ERR-15-109 "Hệ thống thử trả lỗi."
- **E8. Gateway sandbox lỗi.** ERR-15-111. "Cổng thử đang bảo trì. Thử lại sau."
- **E9. PH-13 không ghi được và API `RESTRICTED`, `SENSITIVE`.** ERR-15-115. "Chưa ghi được nhật ký nên không thử được lúc này."

**Quy tắc áp dụng.** BR-15-008, 016, 017, 018, 023, 024, 025, 026.

**Màn hình, API.** UI-15-06; API-15-071…074, 082.
:::

```{.mermaid caption="Trình tự thử API trên sandbox"}
sequenceDiagram
  autonumber
  actor An
  participant BFF as BFF dh-portal
  participant PT as portal
  participant KC as Keycloak dh-dev
  participant GW as APISIX sandbox
  participant BE as Mock hoặc backend thử
  An->>BFF: Gửi yêu cầu thử
  BFF->>PT: API-15-072
  PT->>PT: Kiểm tra đặc tả, PII-15, hạn mức
  PT->>KC: Đổi token ngắn hạn
  PT->>GW: Gọi tuyến sandbox kèm X-DH-Try-Id
  GW->>PT: forward-auth API-15-082
  PT-->>GW: Cho phép
  GW->>BE: Chuyển yêu cầu
  BE-->>GW: Phản hồi
  GW-->>PT: Phản hồi
  PT-->>BFF: Che trường nhạy cảm, EVT-15-11
  BFF-->>An: Hiện kết quả
```

Hình cho thấy cổng kiểm tra ở hai tầng: `portal` trước khi gọi và `forward-auth` ở APISIX, để lời gọi trực tiếp bằng thông tin xác thực (không qua khung thử) cũng chịu cùng hạn mức.

### 6.20. UC-15-20 · Lịch sử thử, bộ sưu tập và xuất Postman, Bruno, HTTP

::: dac-ta
**Mục tiêu.** Nhà phát triển gửi lại yêu cầu cũ, gom yêu cầu thành bộ sưu tập và xuất sang công cụ quen dùng mà không lộ bí mật.

**Tác nhân chính.** `ROLE-DEVELOPER` (An).

**Tác nhân phụ.** Không.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-15-040, 041.

**Truy vết.** REQ-15; SRS cũ FR-15-016.

**Tiền điều kiện.** Đã đăng nhập; có lượt thử trong 30 ngày.

**Kích hoạt.** An mở tab `bo-suu-tap` của ứng dụng.

**Đảm bảo tối thiểu.** Lượt `PRODUCTION` chỉ giữ siêu dữ liệu; yêu cầu chứa mẫu PII không được lưu.

**Đảm bảo thành công.** Bộ sưu tập lưu đúng giới hạn; tệp xuất không có bí mật.

**Luồng chính.**

1. Hệ thống liệt kê lượt thử 30 ngày gần nhất (API-15-075): thời điểm, ứng dụng, API, thao tác, trạng thái, độ trễ.
2. An chọn một lượt `SANDBOX` và bấm "Gửi lại": giao diện nạp yêu cầu (≤ 16 KB) vào khung thử.
3. An lưu yêu cầu vào bộ sưu tập "Hộ tịch" (API-15-078), đổi tên (API-15-079); tối đa 50 bộ, mỗi bộ 100 yêu cầu.
4. An bấm "Xuất" định dạng `postman` (API-15-081). Hệ thống trả Postman Collection v2.1, địa chỉ gốc và token là biến môi trường, bí mật là `{{CLIENT_SECRET}}`.
5. An xóa toàn bộ lịch sử (API-15-076): hệ thống xóa vật lý bản yêu cầu, giữ bản ghi kiểm toán.

**Luồng thay thế.**

- **4a. Định dạng `bruno` (.zip) hoặc `http`.** Cùng nguyên tắc giá trị giữ chỗ.
- **3a. Xóa bộ sưu tập (API-15-080).** Xóa mềm theo BR-15-034.

**Luồng ngoại lệ.**

- **E1. Bộ sưu tập của người khác (bước 3, 4).** ERR-15-001. "Không tìm thấy nội dung yêu cầu."
- **E2. Vượt số bộ sưu tập hoặc định dạng xuất không hỗ trợ.** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

**Quy tắc áp dụng.** BR-15-011, 024, 034.

**Màn hình, API.** UI-15-14; API-15-075…081.
:::

### 6.21. UC-15-21 · Đề xuất, duyệt, tắt thử production theo dịch vụ

::: dac-ta
**Mục tiêu.** Cho phép cán bộ có đăng ký ACTIVE thử một API ở production sau khi hai người khác nhau đồng ý; tắt được nhanh bất kỳ lúc nào.

**Tác nhân chính.** Chủ dịch vụ (Chi) đề xuất; người duyệt dịch vụ (Dũng) hoặc TA (Hà) duyệt.

**Tác nhân phụ.** PH-02 (`dataClass`), PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-042.

**Truy vết.** REQ-15; BO-03; SRS cũ FR-15-007; FR-00-071; ADR-046.

**Tiền điều kiện.** `15.try.prod-enabled = true`; API `PUBLISHED` có `dataClass` `PUBLIC` hoặc `INTERNAL`; người duyệt có `PERM-15-portal-admin`.

**Kích hoạt.** Chi bấm "Đề xuất bật thử production" ở `/quan-tri-cong/dich-vu/tra-cuu-ho-tich`.

**Đảm bảo tối thiểu.** Mặc định `OFF`; không có đường bật mà thiếu người duyệt thứ hai.

**Đảm bảo thành công.** Trạng thái `ENABLED` tới `validUntil` (≤ 90 ngày), EVT-15-10 phát.

**Luồng chính.**

1. Chi nêu lý do "Kiểm thử tích hợp Sở TN&MT" và thời hạn 30 ngày (API-15-084). Hệ thống kiểm tra điều kiện dịch vụ, tạo yêu cầu duyệt loại `TRY_PRODUCTION`, trạng thái `PENDING`.
2. Dũng xem thông tin dịch vụ, `dataClass`, lý do (API-15-083).
3. Hệ thống kiểm tra Dũng khác Chi (LP-15-01).
4. Dũng bấm "Duyệt" (API-15-085): `ENABLED` tới `validUntil`; hệ thống ghi kiểm toán, phát EVT-15-10.
5. Khi cần dừng, một người có quyền bấm "Tắt" (API-15-086), không cần người thứ hai: `OFF`, lượt thử kế tiếp bị chặn.

**Luồng thay thế.**

- **4a. Dũng từ chối kèm ý kiến.** `OFF` kèm lý do.
- **5a. Hết `validUntil`.** `portal` tự chuyển `EXPIRED` rồi `OFF`.

**Luồng ngoại lệ.**

- **E1. API `RESTRICTED`, `SENSITIVE` hoặc tenant tắt (bước 1).** ERR-15-040. "Dịch vụ này chưa đủ điều kiện cho thao tác này."
- **E2. Người duyệt là người đề xuất (bước 3).** ERR-15-023. "Người duyệt phải khác người soạn và người gửi duyệt."
- **E3. Thiếu lý do hoặc thời hạn quá 90 ngày.** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E4. Trạng thái không cho phép.** ERR-15-022. "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này."

**Quy tắc áp dụng.** BR-15-019, 020, 021.

**Màn hình, API.** UI-15-23; API-15-083…086; EVT-15-10.
:::

### 6.22. UC-15-22 · Thử API trên production

::: dac-ta
**Mục tiêu.** Cán bộ có đăng ký sử dụng ACTIVE thử một lời gọi đọc ở production, an toàn và có dấu vết đầy đủ.

**Tác nhân chính.** `ROLE-DEVELOPER` là cán bộ CQNN (Bình).

**Tác nhân phụ.** PH-02 (đăng ký ACTIVE), Keycloak (token exchange), APISIX production, PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-043.

**Truy vết.** REQ-15; BO-03; SRS cũ FR-15-007, SRS cũ FR-15-015; CMP-LAW-05; SEC-24, SEC-60.

**Tiền điều kiện.** Dịch vụ `ENABLED` còn hạn (UC-15-21); `HT-DATDAI` có đăng ký ACTIVE của `tra-cuu-ho-tich` (UC-15-23); Bình là cán bộ, không phải `dh-dev`.

**Kích hoạt.** Bình chọn môi trường "Production" ở `/dich-vu/tra-cuu-ho-tich/thu`.

**Đảm bảo tối thiểu.** Không ghi được kiểm toán thì không gọi; không lưu thân phản hồi.

**Đảm bảo thành công.** Phản hồi hiện cho Bình; kiểm toán `TRY_PRODUCTION` ghi trước khi gọi; EVT-15-11 phát.

**Luồng chính.**

1. Bình chọn thao tác `GET /ho-tich/{ma}`. Hệ thống kiểm tra dịch vụ `ENABLED`, `dataClass` không `RESTRICTED`, `SENSITIVE`, phương thức `GET` hoặc `HEAD`.
2. Hệ thống hỏi PH-02 `HT-DATDAI` có đăng ký ACTIVE của API.
3. `portal` ghi kiểm toán đồng bộ vào PH-13 trước khi gọi.
4. `portal` xin token trao đổi 5 phút, thu hẹp vào phạm vi `api:tra-cuu-ho-tich:{planCode}` của đăng ký, đánh dấu `act` là Bình.
5. `portal` gọi tuyến production qua APISIX như mọi HTTT, áp 10 lượt mỗi phút mỗi người (API-15-072).
6. Hệ thống trả phản hồi, che theo SEC-32, không lưu thân; ghi kết quả vào kiểm toán, phát EVT-15-11.

**Luồng thay thế.**

- **1a. Danh mục quá 24 giờ chưa đồng bộ.** Nút thử production bị ẩn (BR-15-033).

**Luồng ngoại lệ.**

- **E1. Dịch vụ chưa bật hoặc hết hạn (bước 1).** ERR-15-112. "Dịch vụ này chưa bật thử trên môi trường thật."
- **E2. Dữ liệu nhạy cảm.** ERR-15-114. "Dịch vụ có dữ liệu nhạy cảm không cho thử trên môi trường thật."
- **E3. Phương thức ghi (bước 1).** ERR-15-116. "Phương thức {phương thức} không được phép ở môi trường này."
- **E4. Không có đăng ký ACTIVE (bước 2).** ERR-15-113. "Tổ chức của bạn chưa có đăng ký sử dụng đang hoạt động cho dịch vụ này."
- **E5. Kiểm toán lỗi (bước 3).** ERR-15-115. "Chưa ghi được nhật ký nên không thử được lúc này." Không gọi production.
- **E6. Token exchange lỗi (bước 4).** ERR-15-117. "Chưa lấy được quyền truy cập tạm thời. Thử lại sau."
- **E7. Vượt hạn mức production (bước 5).** ERR-15-118. "Vượt hạn mức thử trên môi trường thật."

**Quy tắc áp dụng.** BR-15-019, 020, 022, 023, 024.

**Màn hình, API.** UI-15-06; API-15-072, 082; EVT-15-11.
:::

```{.mermaid caption="Trình tự thử API trên production"}
sequenceDiagram
  autonumber
  actor Binh as Bình
  participant PT as portal
  participant P2 as PH-02
  participant AU as PH-13 kiểm toán
  participant KC as Keycloak
  participant GW as APISIX production
  Binh->>PT: Thử GET trên production
  PT->>PT: Kiểm tra ENABLED, dataClass, phương thức
  PT->>P2: Đăng ký ACTIVE của HT-DATDAI
  P2-->>PT: Có, phạm vi api:tra-cuu-ho-tich
  PT->>AU: Ghi kiểm toán đồng bộ
  AU-->>PT: Đã ghi
  PT->>KC: Token exchange 5 phút, act = Bình
  PT->>GW: Gọi như một HTTT
  GW-->>PT: Phản hồi
  PT-->>Binh: Hiện phản hồi, không lưu thân
```

Hình nhấn mạnh thứ tự an toàn: kiểm toán được ghi trước lời gọi; nếu bước 5 lỗi thì lời gọi không xảy ra.

### 6.23. UC-15-23 · Gửi và theo dõi đăng ký sử dụng API production

::: dac-ta
**Mục tiêu.** Cán bộ đầu mối gửi đăng ký sử dụng API cho HTTT của đơn vị từ cổng và theo dõi kết quả; cổng không duyệt, không giữ bản sao quyết định.

**Tác nhân chính.** `ROLE-ORG_REQUESTER` (Bình).

**Tác nhân phụ.** PH-02 (API-02-058, đăng ký sử dụng), hộp thông báo.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-044, 045.

**Truy vết.** REQ-15; BP-01; SRS cũ FR-15-012; FR-02-046, FR-02-049…051; LGC-APIM-019, LGC-APIM-020 (liên quan).

**Tiền điều kiện.** Bình đăng nhập bằng tài khoản cán bộ, là đầu mối của đơn vị; đơn vị có HTTT `ACTIVE` ở PH-01 (`HT-DATDAI`).

**Kích hoạt.** Bình bấm "Đăng ký sử dụng" ở UI-15-04 hoặc mở `/dang-ky-su-dung`.

**Đảm bảo tối thiểu.** Cổng không tạo, không sửa đăng ký ở phía mình; lỗi PH-02 hiện nguyên văn.

**Đảm bảo thành công.** Đăng ký ở PH-02 trạng thái `PENDING` hoặc `ACTIVE`; Bình thấy dòng thời gian.

**Luồng chính.**

1. Hệ thống kiểm tra Bình có quyền đăng ký của tổ chức và có HTTT `ACTIVE`.
2. Wizard dẫn qua: phiên bản `v2`, gói "Tiêu chuẩn", HTTT `HT-DATDAI`, mục đích, khối lượng 5.000 lượt mỗi ngày, căn cứ pháp lý; điều khoản và SLA lấy từ bản sao danh mục.
3. Hệ thống ủy thác API-02-058 của PH-02 kèm danh tính Bình (API-15-087); PH-02 kiểm tra và tạo đăng ký.
4. Hệ thống hiện kết quả của PH-02 và liên kết sang theo dõi; ghi kiểm toán `SUBMIT_SUBSCRIPTION`.
5. Dũng và Chi duyệt ở PH-02; EVT-02-10, 11 tạo thông báo cho Bình.
6. Bình mở `/dang-ky-su-dung` (API-15-088, 089): thấy `ACTIVE`, phạm vi cấp, hạn rà soát; hệ thống hiện liên kết tới tham chiếu production (UC-15-17) và nút "Thử trên production" nếu cho phép (UC-15-22).

**Luồng thay thế.**

- **6a. Hủy khi còn `PENDING`.** Bình bấm "Hủy" (API-15-090); hệ thống ủy thác API hủy của PH-02.
- **5a. Từ chối.** Dòng thời gian hiện lý do của PH-02.

**Luồng ngoại lệ.**

- **E1. Không phải đầu mối hoặc chưa có HTTT hoạt động (bước 1).** ERR-15-032. "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này."
- **E2. PH-02 lỗi (bước 3, 6).** ERR-15-030. "Chưa kết nối được dịch vụ danh mục."
- **E3. Lỗi nghiệp vụ của PH-02.** Chuyển nguyên mã `ERR-02-*` và câu của PH-02.
- **E4. An (nhà thầu) mở chức năng.** Không có lối vào; gọi thẳng API thì ERR-15-005 "Bạn không có quyền thực hiện thao tác này." (BR-15-004).
- **E5. Đăng ký ngoài tổ chức.** ERR-15-001.

**Quy tắc áp dụng.** BR-15-004, 014.

**Màn hình, API.** UI-15-15; API-15-087…090.
:::

```{.mermaid caption="Trình tự gửi đăng ký sử dụng qua cổng"}
sequenceDiagram
  autonumber
  actor Binh as Bình
  participant PT as portal
  participant P2 as PH-02
  participant HN as Hộp thông báo
  Binh->>PT: Gửi đăng ký v2, gói Tiêu chuẩn, HT-DATDAI
  PT->>P2: API-02-058 kèm danh tính Bình
  P2-->>PT: Đăng ký PENDING
  PT-->>Binh: Hiện kết quả của PH-02
  P2->>PT: EVT-02-10 đổi trạng thái
  PT->>HN: Tạo thông báo cho Bình
  Binh->>PT: Theo dõi, API-15-089
  PT->>P2: Đọc trạng thái
  P2-->>PT: ACTIVE
```

Hình cho thấy cổng chỉ chuyển và đọc: quyết định `PENDING` sang `ACTIVE` nằm hoàn toàn ở PH-02.

### 6.24. UC-15-24 · Nộp hồ sơ kết nạp HTTT từ cổng

::: dac-ta
**Mục tiêu.** Cán bộ đầu mối nộp hồ sơ kết nạp HTTT ngay trên cổng, theo dõi trạng thái và biết bước nhận định danh production.

**Tác nhân chính.** `ROLE-ORG_REQUESTER` (Bình).

**Tác nhân phụ.** PH-01 (lược đồ biểu mẫu, hồ sơ F-01).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-046.

**Truy vết.** REQ-15; BP-01; SRS cũ FR-15-012; LGC-APIM-019, LGC-APIM-020 (liên quan, PH-01 chính).

**Tiền điều kiện.** Đăng nhập bằng tài khoản cán bộ, là đầu mối của đơn vị.

**Kích hoạt.** Bình mở `/ket-nap`.

**Đảm bảo tối thiểu.** Hồ sơ nháp giữ ở PH-01 khi PH-01 lỗi; cổng không hiện bí mật.

**Đảm bảo thành công.** Hồ sơ ở PH-01 có mã và trạng thái; Bình thấy hướng dẫn nhận định danh.

**Luồng chính.**

1. Hệ thống nạp lược đồ biểu mẫu kết nạp từ PH-01 (bộ đệm 10 phút) và dựng wizard.
2. Bình điền thông tin HTTT `HT-DATDAI`, đầu mối, giao thức; hệ thống kiểm tra sơ bộ theo lược đồ.
3. Hệ thống ủy thác tạo và gửi hồ sơ của PH-01 kèm danh tính Bình và `Idempotency-Key` (API-15-091); ghi kiểm toán `SUBMIT_ONBOARDING`.
4. Hệ thống hiện mã hồ sơ và trạng thái đọc từ PH-01 (API-15-092, 093): nháp, chờ duyệt, bổ sung, từ chối, đã kết nạp.
5. Khi đã kết nạp, hệ thống hiện hướng dẫn nhận định danh production qua kênh của PH-01 và gợi ý tạo ứng dụng sandbox liên kết `HT-DATDAI` (UC-15-14).

**Luồng thay thế.**

- **4a. PH-01 yêu cầu bổ sung.** Bình sửa và gửi lại; lỗi theo trường của PH-01 hiện dưới từng trường.

**Luồng ngoại lệ.**

- **E1. Không phải đầu mối (bước 1).** ERR-15-032. "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này."
- **E2. PH-01 lỗi (bước 1, 3, 4).** ERR-15-031. "Chưa kết nối được dịch vụ kết nạp. Thử lại sau."
- **E3. Dữ liệu sai lược đồ (bước 2).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

**Quy tắc áp dụng.** BR-15-014, 015.

**Màn hình, API.** UI-15-16; API-15-091…093.
:::

### 6.25. UC-15-25 · Công bố API từ cổng

::: dac-ta
**Mục tiêu.** Chủ dịch vụ nạp đặc tả, sửa lỗi theo kết quả kiểm tra và gửi duyệt công bố từ cổng; việc duyệt ở PH-02.

**Tác nhân chính.** Chủ dịch vụ (Chi).

**Tác nhân phụ.** PH-02 (đăng ký API, kiểm tra đặc tả, duyệt), dịch vụ quét mã độc.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-047.

**Truy vết.** REQ-15; BP-01; SRS cũ FR-15-013; FR-02-010, FR-02-011, FR-02-034; SEC-45.

**Tiền điều kiện.** Chi là chủ dịch vụ của tổ chức; `HT-TUPHAP` `ACTIVE`.

**Kích hoạt.** Chi bấm "Công bố API mới" ở `/cong-bo/moi`.

**Đảm bảo tối thiểu.** Cổng không có nút duyệt hay công bố trực tiếp.

**Đảm bảo thành công.** API ở PH-02 có phiên bản `PENDING`; khi `PUBLISHED` và `portalPublished` thì xuất hiện ở danh mục qua UC-15-04.

**Luồng chính.**

1. Chi nạp `tra-cuu-ho-tich-v3.yaml`; hệ thống quét mã độc rồi ủy thác PH-02 tạo API và phiên bản `DRAFT` (API-15-094).
2. Hệ thống hiện kết quả kiểm tra của PH-02 theo từng lỗi: lớp 1, lớp 2, quét bí mật, dữ liệu cá nhân thật.
3. Chi sửa đặc tả và nạp lại tới khi đạt.
4. Chi bấm "Gửi duyệt": hệ thống ủy thác PH-02, ghi kiểm toán `SUBMIT_PUBLICATION`.
5. Hệ thống đọc trạng thái `DRAFT`, `PENDING`, `PUBLISHED` (API-15-095, 096) và hiện dòng thời gian.
6. Dũng duyệt ở PH-02; API hiện ở danh mục sau đồng bộ.

**Luồng thay thế.**

- **6a. PH-02 từ chối.** Lý do hiện ở dòng thời gian; Chi sửa và gửi lại.

**Luồng ngoại lệ.**

- **E1. Không phải chủ dịch vụ (bước 1).** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."
- **E2. Tệp nhiễm mã độc.** ERR-15-024. "Tệp không hợp lệ: chỉ nhận PNG, JPEG, WebP tối đa 5 MB và không có mã độc."
- **E3. Đặc tả không đạt (bước 2).** Lỗi từng dòng của PH-02 hiện tại chỗ.
- **E4. PH-02 lỗi.** ERR-15-030. "Chưa kết nối được dịch vụ danh mục."

**Quy tắc áp dụng.** BR-15-001, 014.

**Màn hình, API.** UI-15-17; API-15-094…096.
:::

### 6.26. UC-15-26 · Bảng điều khiển, thống kê và nhật ký ứng dụng

::: dac-ta
**Mục tiêu.** Nhà phát triển thấy việc đang làm, lượt gọi, lỗi và nhật ký gọi đã che dữ liệu của chính ứng dụng mình.

**Tác nhân chính.** `ROLE-DEVELOPER` (An).

**Tác nhân phụ.** PH-13 (`metrics:portal-read`), PH-02.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-048, 049, 050.

**Truy vết.** REQ-15; BP-01; LGC-APIM-022 (phần nhà phát triển); SRS cũ FR-15-016; SEC-32; Q15-18.

**Tiền điều kiện.** Đã đăng nhập; với thống kê và nhật ký, An là thành viên ứng dụng và ứng dụng có hoạt động.

**Kích hoạt.** An mở `/tong-quan` hoặc tab `thong-ke`, `nhat-ky`.

**Đảm bảo tối thiểu.** Nguồn nào lỗi thì thẻ đó hiện "Chưa tải được", không hỏng cả trang; không có thân yêu cầu hay phản hồi trong nhật ký.

**Đảm bảo thành công.** Số liệu đúng nhãn `app_code`, nhật ký che dữ liệu.

**Luồng chính.**

1. An mở `/tong-quan` (API-15-097): số ứng dụng `ACTIVE`, thông tin xác thực hết hạn trong 30 ngày, lượt thử 24 giờ, tỷ lệ lỗi, đăng ký chờ duyệt, thông báo chưa đọc.
2. An mở tab `thong-ke` của `app-tra-cuu-ho-tich` (API-15-098): lượt gọi, tỷ lệ theo nhóm mã trạng thái, độ trễ p50, p95 theo API và thời gian.
3. An mở tab `nhat-ky` (API-15-099): thời điểm, phương thức, đường dẫn đã che tham số truy vấn, mã trạng thái, độ trễ, `traceId`, địa chỉ nguồn che octet cuối, tối đa 30 ngày.
4. An bấm một bản ghi `429` (API-15-100): hiện thao tác, mã lỗi RFC 9457 và liên kết tới đoạn tài liệu liên quan.

**Luồng thay thế.**

- **2a. Ứng dụng liên kết `HT-DATDAI`.** Thêm tổng hợp production của HTTT (số lượt, tỷ lệ lỗi) nếu PH-13 cung cấp, không chi tiết từng lời gọi.
- **3a. Nhật ký production.** Không hiện ở cổng; xem ở PH-13.

**Luồng ngoại lệ.**

- **E1. PH-13 lỗi (bước 2, 3).** ERR-15-039. "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."
- **E2. Không phải thành viên ứng dụng.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."
- **E3. Bản ghi không thuộc ứng dụng (bước 4).** ERR-15-001. "Không tìm thấy nội dung yêu cầu."
- **E4. PH-02 lỗi (bước 1).** Thẻ đăng ký hiện "Chưa tải được." (ERR-15-030 chỉ ghi nhật ký).

**Quy tắc áp dụng.** BR-15-009, 024.

**Màn hình, API.** UI-15-18, 12; API-15-097…100.
:::

### 6.27. UC-15-27 · Theo dõi thay đổi API và hộp thông báo

::: dac-ta
**Mục tiêu.** Nhà phát triển biết trước khi API đổi, ngừng hay giảm SLA; thông báo bắt buộc không thể tắt.

**Tác nhân chính.** `ROLE-DEVELOPER` (An, Bình).

**Tác nhân phụ.** PH-02 (EVT-02-10, 11, 12), dịch vụ thư, PH-10.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-051, 052.

**Truy vết.** REQ-15; BP-01; FR-02-057; FR-00-060, FR-00-062.

**Tiền điều kiện.** API nằm trong tập người dùng được thấy.

**Kích hoạt.** An bật "Theo dõi thay đổi" ở UI-15-04; EVT-02-12 tới `portal`.

**Đảm bảo tối thiểu.** Thư chỉ chứa liên kết; không gửi trùng.

**Đảm bảo thành công.** Thông báo xuất hiện ở hộp thông báo và theo kênh đã chọn.

**Luồng chính.**

1. An bật theo dõi `tra-cuu-ho-tich`, kênh `IN_APP` và `EMAIL` (API-15-102); hệ thống lưu EN-15-14.
2. HT-DATDAI có đăng ký ACTIVE nên Bình tự được theo dõi các loại bắt buộc.
3. PH-02 phát EVT-02-12 "ngừng khuyến nghị `v1`". `portal` tìm người theo dõi và người thuộc tổ chức có đăng ký liên quan, gộp trùng.
4. Hệ thống tạo thông báo (API-15-104) và gửi thư chỉ chứa liên kết.
5. An thấy số chưa đọc ở thanh trên (cập nhật mỗi 60 giây), bấm thông báo để tới trang đổi; đánh dấu đã đọc (API-15-105) hoặc tất cả (API-15-106).
6. Thông báo lưu 90 ngày rồi xóa.

**Luồng thay thế.**

- **1a. An tắt loại thông tin.** Cho phép với loại theo tùy chọn; hủy theo dõi bằng API-15-103.
- **3a. Nguồn khác.** Lời mời nhóm, nhắc hạn thông tin xác thực, trả lời phiếu, kết quả duyệt tài khoản cũng vào hộp thông báo.

**Luồng ngoại lệ.**

- **E1. Tắt loại bắt buộc (bước 1a).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu." Giao diện nêu "Loại thông báo này là bắt buộc nên không tắt được."
- **E2. API ngoài tầm hoặc thông báo của người khác.** ERR-15-001. "Không tìm thấy nội dung yêu cầu."

**Quy tắc áp dụng.** BR-15-027.

**Màn hình, API.** UI-15-19; API-15-101…106.
:::

### 6.28. UC-15-28 · Hỏi đáp, báo lỗi tài liệu, yêu cầu hỗ trợ và xử lý

::: dac-ta
**Mục tiêu.** Nhà phát triển hỏi, báo lỗi, xin hỗ trợ và được chủ dịch vụ trả lời trong hạn.

**Tác nhân chính.** `ROLE-DEVELOPER` (An); chủ dịch vụ (Chi) và TA (Hà) xử lý.

**Tác nhân phụ.** Hộp thông báo, dịch vụ thư, PH-10 (EVT-15-12).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-053, 054, 055.

**Truy vết.** REQ-15; BP-01; FR-00-070; SRS cũ FR-15-009.

**Tiền điều kiện.** Đã đăng nhập; API hoặc trang trong tầm nhìn; người xử lý có `PERM-15-support`.

**Kích hoạt.** An bấm "Hỏi đáp" ở UI-15-04, "Báo lỗi tài liệu" ở UI-15-07 hoặc "Gửi yêu cầu hỗ trợ" ở `/ho-tro/moi`.

**Đảm bảo tối thiểu.** Nội dung là văn bản thuần; tối đa 10 bài mỗi ngày mỗi người.

**Đảm bảo thành công.** Phiếu `HT-2026-0042` tới đúng người nhận; người gửi thấy trả lời.

**Luồng chính.**

1. An hỏi dưới `tra-cuu-ho-tich`: "Mã hộ tịch có phân biệt hoa thường không?" (API-15-108). Chi và người khác trả lời; Chi đánh dấu đã giải quyết.
2. An thấy tài liệu sai ví dụ, bấm "Báo lỗi" (API-15-109): phiếu `DOC_ERROR` kèm thao tác tới Chi, phát EVT-15-12.
3. An gửi yêu cầu hỗ trợ `SUPPORT_REQUEST` (API-15-110). Hệ thống chọn người nhận: đầu mối kỹ thuật của chủ dịch vụ; `ACCESS_REQUEST` tới đầu mối tổ chức; không có thì tới TA. Phiếu `OPEN`, gửi thông báo và thư chỉ có liên kết.
4. Chi mở hộp xử lý (API-15-114) thấy phiếu kèm hạn phản hồi đầu 24 giờ, trả lời; phiếu `ANSWERED` (API-15-115).
5. Chi chuyển giao hoặc ghi chú nội bộ (không hiện cho An).
6. An xác nhận hoặc mở lại trong 7 ngày (API-15-113); quá 7 ngày phiếu `RESOLVED` tự `CLOSED`.
7. Quá hạn phản hồi đầu, hệ thống nhắc Chi ở "Việc của tôi" và báo Hà.

**Luồng thay thế.**

- **2a. Đánh giá trang.** An bấm "Hữu ích" ở trang hướng dẫn; một phiếu mỗi người mỗi trang.

**Luồng ngoại lệ.**

- **E1. Gửi quá nhiều (bước 1 đến 3).** ERR-15-037. "Bạn gửi quá nhiều. Thử lại sau {n} phút."
- **E2. Nội dung trống hoặc quá dài.** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E3. Phiếu đã đóng (bước 6).** ERR-15-029. "Phiếu đã đóng. Tạo phiếu mới nếu cần."
- **E4. Phiếu ngoài phạm vi hoặc của người khác.** ERR-15-001. "Không tìm thấy nội dung yêu cầu."
- **E5. Thiếu `PERM-15-support`.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-030.

**Màn hình, API.** UI-15-04, 07, 20, 28; API-15-107…115.
:::

### 6.29. UC-15-29 · Cấu hình nhận diện và tham số cổng

::: dac-ta
**Mục tiêu.** Mỗi tỉnh đặt tên, logo, liên kết cổng và tinh chỉnh tham số `15.*` trong trần của nền tảng, có dấu vết.

**Tác nhân chính.** `ROLE-TENANT_ADMIN` (Hà), `ROLE-CATALOG_APPROVER`.

**Tác nhân phụ.** PH-18 (kho tham số), dịch vụ quét mã độc, PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-056, 057.

**Truy vết.** REQ-15; BP-09; LGC-APIM-007 (công khai theo tenant); ADR-020; D03-10.

**Tiền điều kiện.** Hà có `PERM-15-portal-admin`, đăng nhập khu `/quan-tri-cong` bằng MFA từ mạng quản trị.

**Kích hoạt.** Hà mở `/quan-tri-cong/nhan-dien` hoặc `/tham-so`.

**Đảm bảo tối thiểu.** Màu, phông, token, vật liệu kính không đổi được.

**Đảm bảo thành công.** Cấu hình lưu với `If-Match`, bộ đệm trang chủ vô hiệu, giá trị trước và sau ghi kiểm toán `CHANGE_SETTING`.

**Luồng chính.**

1. Hà xem cấu hình hiện hành và bản xem trước (API-15-116).
2. Hà đổi tên cổng "Cổng nhà phát triển Tỉnh T68", tải `logo-t68.png` 400 KB (API-15-118); hệ thống quét mã độc, kiểm tra PNG hoặc WebP, ≤ 512 KB, từ 128 px; SVG bị từ chối.
3. Hà nhập liên kết chân trang HTTPS, bấm "Lưu" (API-15-117).
4. Hà mở `/tham-so` (API-15-119), đặt `15.public.rate-limit-per-minute` = 200; hệ thống kiểm tra miền và trần nền tảng, lưu qua PH-18 (API-15-120), bộ đệm 60 giây.
5. Với tham số nhạy cảm `15.public.enabled` hoặc `15.try.prod-enabled`, Hà nêu lý do; hệ thống ghi kiểm toán mức cao.

**Luồng thay thế.**

- **4a. Hà thử đổi từ tên miền công khai.** Khu quản trị trả `404`, không lộ sự tồn tại.

**Luồng ngoại lệ.**

- **E1. Logo hoặc liên kết sai (bước 2, 3).** ERR-15-033. "Thông tin nhận diện chưa hợp lệ."
- **E2. Tham số ngoài miền hoặc vượt trần (bước 4).** ERR-15-034. "Giá trị của {khóa} phải trong khoảng {tối thiểu} đến {tối đa}."
- **E3. Xung đột sửa.** ERR-15-006. "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."
- **E4. Truy cập từ ngoài mạng quản trị.** ERR-15-036. "Khu quản trị chỉ truy cập được từ mạng quản trị."

**Quy tắc áp dụng.** BR-15-031, 032, 034.

**Màn hình, API.** UI-15-25; API-15-116…120.
:::

### 6.30. UC-15-30 · Duyệt, khóa và mở khóa tài khoản dh-dev, ứng dụng

::: dac-ta
**Mục tiêu.** Chỉ nhà thầu có hợp đồng mới có quyền; tài khoản hoặc ứng dụng lạm dụng bị khóa trong 60 giây.

**Tác nhân chính.** `ROLE-TENANT_ADMIN` (Hà), `ROLE-SECURITY_OFFICER` (Khánh), `ROLE-PLATFORM_ADMIN` có `PERM-15-dev-approve`.

**Tác nhân phụ.** Keycloak `dh-dev`, PH-03 (`forward-auth`), dịch vụ thư.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-058, 059.

**Truy vết.** REQ-15; BP-09; SRS cũ FR-15-014; SEC-27, SEC-64; Q15-03.

**Tiền điều kiện.** Tài khoản `PENDING_APPROVAL` (duyệt) hoặc `ACTIVE` (khóa); Hà đăng nhập khu quản trị bằng MFA.

**Kích hoạt.** Hà mở `/quan-tri-cong/tai-khoan-dev`; Khánh nhận cảnh báo lạm dụng.

**Đảm bảo tối thiểu.** Keycloak lỗi thì giữ nguyên trạng thái cũ, không nửa vời.

**Đảm bảo thành công.** Trạng thái tài khoản hoặc ứng dụng đổi; EVT-15-02, EVT-15-07 phát; kiểm toán `LOCK_ACCOUNT` hoặc `UNLOCK_ACCOUNT`.

**Luồng chính.**

1. Hà xem danh sách chờ duyệt (API-15-121): họ tên, thư, "Công ty ABC", số hợp đồng, đơn vị bảo lãnh; liên hệ đơn vị bảo lãnh ngoài cổng.
2. Hà bấm "Duyệt" An (API-15-122): hệ thống bật người dùng ở `dh-dev`, gán `tenantGrants` T68 và `ROLE-DEVELOPER`, chuyển `ACTIVE`, gửi thư và thông báo, phát EVT-15-07.
3. Khánh phát hiện ứng dụng `app-tra-cuu-ho-tich` thử dồn dập, nêu lý do và bấm "Khóa ứng dụng" (API-15-126): chuyển `SUSPENDED`, `forward-auth` từ chối lượt gọi sau tối đa 60 giây, thông tin xác thực giữ nguyên.
4. Hệ thống thông báo cho An, phát EVT-15-02.
5. Sau điều tra, Khánh bấm "Mở khóa" kèm lý do (API-15-127): ứng dụng về `ACTIVE`.
6. Yêu cầu quá 3 ngày chưa xử lý: hệ thống nhắc Hà và báo quản trị nền tảng.

**Luồng thay thế.**

- **2a. Từ chối.** Hà nêu lý do (API-15-123); tài khoản `REJECTED`, gửi thư.
- **3a. Khóa tài khoản.** API-15-124: tắt người dùng ở `dh-dev`, hủy phiên BFF, `LOCKED`, `SUSPENDED` mọi ứng dụng thuộc riêng người này; mở khóa bằng API-15-125.

**Luồng ngoại lệ.**

- **E1. Tài khoản không ở `PENDING_APPROVAL` (bước 2).** ERR-15-022. "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này."
- **E2. Ứng dụng không ở trạng thái cho phép (bước 3, 5).** ERR-15-017. "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."
- **E3. Thiếu lý do (từ chối, khóa).** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E4. Keycloak lỗi (bước 2, 3a).** ERR-15-020. "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau."
- **E5. Thiếu `PERM-15-dev-approve`.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-15-004, 010, 028.

**Màn hình, API.** UI-15-24; API-15-121…127; EVT-15-02, 07.
:::

### 6.31. UC-15-31 · Tra nhật ký truy cập, thử và báo cáo sử dụng

::: dac-ta
**Mục tiêu.** Người có quyền tra ai đã làm gì ở cổng, đo mức dùng và thời gian tới lời gọi sandbox đầu tiên.

**Tác nhân chính.** TA (Hà), SO (Khánh), `ROLE-AUDITOR`, PA có `PERM-15-audit-read`.

**Tác nhân phụ.** PH-13 (`audit:portal-read`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-15-060.

**Truy vết.** REQ-15; SRS cũ FR-15-015; FR-00-030, FR-00-031, FR-00-034, FR-00-040, FR-00-041; ADR-031; SEC-60, SEC-62.

**Tiền điều kiện.** Có bản ghi kiểm toán `PORTAL_*` ở PH-13; truy cập từ mạng quản trị.

**Kích hoạt.** Khánh mở `/quan-tri-cong/nhat-ky`.

**Đảm bảo tối thiểu.** Dữ liệu cá nhân trong tệp xuất bị che trừ khi có quyền; chính việc xem là hành động kiểm toán.

**Đảm bảo thành công.** Chuỗi bản ghi theo bộ lọc, báo cáo sử dụng, tệp xuất khi cần.

**Luồng chính.**

1. Khánh lọc `hanh-dong = TRY_PRODUCTION`, `tu`/`den` tuần qua (API-15-128). Hệ thống đọc từ PH-13: thời điểm, người, hành động, đối tượng, kết quả, `traceId`.
2. Khánh lọc `SECRET_ISSUED` của An để đối chiếu với báo cáo lạm dụng.
3. Hà mở báo cáo sử dụng (API-15-129): số truy cập, API xem nhiều, số ứng dụng, số lượt thử, tỷ lệ lỗi, trung vị từ tạo ứng dụng tới lời gọi sandbox thành công đầu tiên (chỉ tiêu 15 phút, NFR-15-022).
4. Khánh bấm "Xuất" 25.000 dòng (API-15-130): chạy nền, thông báo khi xong.
5. Hệ thống ghi kiểm toán `VIEW_AUDIT`, `EXPORT_AUDIT`.

**Luồng thay thế.**

- **4a. Dưới 10.000 dòng.** Tải ngay.
- **1a. Kỳ ngoài 12 tháng.** Yêu cầu truy xuất từ kho WORM 5 năm ở PH-13.

**Luồng ngoại lệ.**

- **E1. PH-13 lỗi (bước 1, 3).** ERR-15-039. "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."
- **E2. Khoảng thời gian quá 12 tháng trực tuyến.** ERR-15-003. "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."
- **E3. Thiếu `PERM-15-audit-read`.** ERR-15-005. "Bạn không có quyền thực hiện thao tác này."
- **E4. Truy cập từ ngoài mạng quản trị.** ERR-15-036. "Khu quản trị chỉ truy cập được từ mạng quản trị."

**Quy tắc áp dụng.** BR-15-023, 031.

**Màn hình, API.** UI-15-26; API-15-128…130.
:::

## 7. Luồng phụ dùng chung

Năm luồng phụ lặp ở nhiều use case được mô tả một lần ở đây; use case dẫn bằng mã `LP-15-nn` thay vì viết lại.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-15-01 | Bốn mắt: hệ thống so người duyệt với người soạn, người sửa gần nhất và người gửi (hoặc người đề xuất); trùng thì khóa nút "Duyệt" và trả ERR-15-023 nếu gọi thẳng API | UC-15-07, 21 |
| LP-15-02 | Lý do bắt buộc: hộp thoại có ô lý do; thiếu trả ERR-15-003 "Cần nêu lý do" | UC-15-07, 21, 30 |
| LP-15-03 | Bí mật một lần: phản hồi `no-store`, bí mật chỉ ở bộ nhớ trang, hộp thoại không đóng tới khi đánh dấu đã lưu, phát lại yêu cầu trả ERR-15-019 | UC-15-15, 16 |
| LP-15-04 | Ủy thác nhân danh người dùng: cổng gọi PH-01, PH-02 kèm danh tính và `Idempotency-Key`, hiện kết quả và lỗi nguyên văn, không giữ bản sao quyết định | UC-15-23, 24, 25 |
| LP-15-05 | An toàn khi lỗi kiểm toán: ghi kiểm toán đồng bộ trước khi gọi; PH-13 lỗi thì từ chối (ERR-15-115) với production và với API `RESTRICTED`, `SENSITIVE` | UC-15-19, 22 |

: Luồng phụ dùng chung

## 8. Tổng hợp mã mới và đối chiếu

### 8.1. Mã mới và đối chiếu phủ FR

Tập này không tạo mã FR, API, ERR, EVT mới. Mã mới: UC-15-01…31 và LP-15-01…05. Mọi FR mức M (47), S (13) và C (2) của FRS có ít nhất một use case (bảng ở §5.4); không FR nào thiếu. FR dùng chung nhiều use case: FR-15-001 chỉ ở UC-15-04 nhưng là nền cho UC-15-01…05; FR-15-035 hiện thực ở UC-15-19 và dùng lại ở UC-15-22 qua FR-15-043. Mọi mã ERR trong tập đối chiếu với FRS §9.1; câu thông báo lấy từ cột "Thông báo cho người dùng" của bảng đó, riêng ba chỗ nêu ở 8.2.

### 8.2. Đề nghị đồng bộ cho FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các lệch dưới đây phát hiện khi viết use case. Tập này theo FRS và không tự đặt khác.

| Mục | Lệch trong FRS | Đề nghị |
|---|---|---|
| FR-15-004 | Bước 1 dẫn "Phụ lục A.5" cho miền tham số truy vấn, nhưng A.5 là tiêu đề HTTP; tham số truy vấn ở A.4 | Sửa dẫn thành A.4 |
| FR-15-038 | Bước 1 dẫn bộ luật PII-15 ở "Phụ lục A.8", thực tế ở A.7 (A.8 là hành động kiểm toán); Q15-09 cũng dẫn A.8 | Sửa dẫn thành A.7 |
| §9.3 | API-15-045 gắn FR-15-019 (đăng nhập SSO) nhưng đường dẫn là đăng ký nhà thầu; đăng nhập đi qua `/bff/dang-nhap` | Gắn FR-15-019 với `/bff/*` và API-15-041; API-15-045 chỉ FR-15-020 |
| FR-15-051, 053, 058 | Câu "Cần nêu lý do từ chối", "Loại thông báo này là bắt buộc nên không tắt được" dùng ERR-15-003 nhưng câu khác với §9.1 | Thêm một dòng nêu chi tiết thay đổi theo ngữ cảnh vào ERR-15-003, hoặc cấp ERR riêng |
| FR-15-005, 010, 007 | Thông báo trong thân FR khác câu ở §9.1 (ví dụ ERR-15-001 "Không tìm thấy dịch vụ." với "Không tìm thấy nội dung yêu cầu.") | Thống nhất theo §9.1; tập này dùng §9.1 |
| FR-15-043, BR-15-022 | Điều kiện thử production là cán bộ thuộc tổ chức có đăng ký ACTIVE, nhưng `PERM-15-try` chỉ cấp cho DEV; OR không có quyền thử | Nêu rõ người thử là DEV cán bộ, OR chỉ đăng ký (UC-15-22, 23 viết theo hướng này) |
| §3.1 | Biên tập viên nội dung không có tên tác nhân riêng; chỉ có quyền `PERM-15-content-write` | Thêm tác nhân "Biên tập viên" hoặc giữ SV, CA, TA như tập này |

: Đề nghị đồng bộ cho FRS

## 9. Câu hỏi mở

> **Câu hỏi mở Q15-45:** UC-15-22 giả định mỗi cán bộ thuộc đúng một HTTT khi thử production. Nếu một cán bộ thuộc nhiều HTTT (ví dụ Bình thuộc `HT-DATDAI` và `HT-DVC`), khung thử có bắt chọn HTTT, và đăng ký ACTIVE của HTTT nào được dùng để thu hẹp token? Ngầm định: giao diện bắt chọn HTTT và `act` ghi cả mã HTTT.

> **Câu hỏi mở Q15-46:** UC-15-30 để SO (Khánh) có `PERM-15-dev-approve` nên duyệt được tài khoản `dh-dev` lẫn khóa ứng dụng. Có nên tách: TA, PA duyệt và khóa, SO chỉ khóa khi có sự cố (cặp loại trừ ở D02-08 §4)? Ngầm định: giữ ma trận FRS §3.2, SO được cả hai.

> **Câu hỏi mở Q15-47:** UC-15-19 bước 4 và `forward-auth` đếm hạn mức bằng Valkey. Khi Valkey không khả dụng, lời gọi sandbox bị chặn hay cho qua với hạn mức nội bộ của APISIX? Ngầm định: chặn đối với tuyến thử trong cổng, cho qua với mức tối thiểu ở APISIX cho lời gọi trực tiếp (chờ SDD).

> **Câu hỏi mở Q15-48:** UC-15-12 chỉ nêu vô hiệu hóa 45 ngày cho tài khoản `dh-dev`. Cán bộ SSO bị PH-12 khóa hoặc nghỉ việc thì ứng dụng cá nhân của họ xử lý thế nào (tạm ngừng, chuyển nhóm, lưu trữ)? Ngầm định: nhận EVT khóa từ PH-12 và tạm ngừng ứng dụng thuộc riêng người đó, như tài khoản `dh-dev`.

> **Câu hỏi mở Q15-49:** UC-15-08 tạo hàng trăm bản nháp cùng lúc khi di trú. Có cần thao tác "gửi duyệt hàng loạt" và duyệt hàng loạt không, hay duyệt từng trang theo bốn mắt (BR-15-012)? Ngầm định: duyệt từng trang ở Đợt 2; hàng loạt chờ quyết định của chủ đầu tư.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và K-TRINH-BAY: 31 use case phủ 62 FR, bốn hình use case tổng, năm sơ đồ trình tự, bảng truy vết hai chiều UC với FR, UI, API, REQ, LGC, năm câu hỏi mở Q15-45…49 và sáu đề nghị đồng bộ cho FRS |
