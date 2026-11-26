---
ma_tai_lieu: D02-04-PH02
ten: Đặc tả use case phân hệ PH-02 Danh mục dịch vụ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, chủ dịch vụ và người duyệt dịch vụ, kỹ sư giao diện và dh-connect, kiểm thử viên
phan_he: PH-02
mo_ta: Đặc tả 38 use case của phân hệ Danh mục dịch vụ theo vòng đời thật của một API ở tỉnh, từ đăng ký, kiểm tra đặc tả, công bố có duyệt bốn mắt, đăng ký sử dụng, đồng bộ danh mục quốc gia tới ngừng dùng, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH02 FRS; D02-02 SRS; D02-08 Ma trận phân quyền; D03-04-PH02 API; D03-06-PH02 Màn hình; D05-02-PH02 Test case
---

# D02-04-PH02 · Đặc tả use case Danh mục dịch vụ

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả 38 use case (UC) của PH-02 theo cách người dùng và hệ thống thật sự làm việc với nhau: ai bấm gì, hệ thống kiểm tra gì, khi nào dừng, thông báo gì hiện ra. Mỗi UC hiện thực một hay nhiều chức năng của [D02-03-PH02](../frs/D02-03-PH02-frs-danh-muc-dich-vu.md); tập UC phủ đủ 62 FR (50 FR mức M, 11 FR mức S, 1 FR mức C), không FR nào mồ côi (bảng 5.4).

**Phạm vi.** Các UC đi theo vòng đời của một API ở tỉnh: chủ dịch vụ đăng ký API và nạp đặc tả OpenAPI, hệ thống kiểm tra hai lớp và quét bí mật, chủ dịch vụ khai backend và gói sử dụng, thử trên TEST rồi gửi duyệt, người duyệt dịch vụ duyệt theo nguyên tắc bốn mắt và API ra gateway; đơn vị khác đăng ký sử dụng, được duyệt và được cấp phạm vi truy cập tự động; danh mục được đồng bộ lên Nền tảng quốc gia, SLA được đối chiếu hằng tháng; khi cần thì tạm ngừng khẩn, nâng phiên bản, ngừng khuyến nghị có lộ trình rồi ngừng hẳn. Bảy UC là UC máy (không có giao diện thao tác riêng nhưng quyết định hành vi hệ thống): cung cấp danh mục cho máy, tự đăng ký từ luồng PH-04, cấp phạm vi, đồng bộ quốc gia, chốt kỳ SLA, thông báo thay đổi, giao diện nội bộ cho PH-03, PH-04, PH-15.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-03 và CMP-LAW-19 (công bố, công khai, đăng ký danh mục dịch vụ chia sẻ), CMP-LAW-09 (quản lý dịch vụ, cổng API của LGSP), CMP-LAW-06 và CMP-LAW-08 (xác thực máy–máy, kiểm soát truy cập cấp độ 3), CMP-LAW-05 (khai báo mục đích khi khai thác dữ liệu cá nhân).

**Những điểm hội đồng cần lưu ý.** (1) Không có đường tắt: UC-02-16 là cửa duy nhất đưa một phiên bản API ra môi trường thật, và chỉ mở khi người duyệt khác người gửi và khác người sửa gần nhất. (2) Hệ thống không bao giờ tự ngừng hẳn khi còn bên khai thác (UC-02-20); mọi lộ trình ngừng dùng có báo trước tối thiểu 180 ngày mặc định (UC-02-19). (3) Quyền gọi API không được cấp bằng tay: UC-02-25 sinh phạm vi `api:{mã API}:{mã gói}` từ đăng ký đã duyệt và chỉ hoàn tất khi cả định danh (PH-01, PH-12) lẫn gateway (PH-03) xác nhận. (4) Nghĩa vụ đăng ký danh mục lên Nền tảng quốc gia chạy tự động và có cảnh báo tuân thủ khi quá 7 ngày (UC-02-29, UC-02-30). (5) Sự cố của PH-02 không làm gián đoạn API đang chạy, vì gateway giữ cấu hình đã nạp (UC-02-35).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Use case | 38 (mức M: 32, S: 5, C: 1; trong đó 7 UC máy) |
| FR được phủ | 62 trên 62 (M: 50, S: 11, C: 1) |
| Use case Đợt 2 | 4 (UC-02-04, 28, 34, 36); còn lại 34 UC thuộc MVP |
| Màn hình được dùng | 17 (UI-02-01…17); chỉ UC-02-35 không có màn hình |
| Nhóm sơ đồ | 4 hình ở chương 4, chia theo bảy nhóm nghiệp vụ |

: Con số chính của tập use case PH-02

## 1. Giới thiệu

Chương này nói tài liệu viết cho ai, đặc tả những gì và đọc kèm tài liệu nào. Người đọc chỉ cần mục 1.1 và 1.2 để biết phần nào dành cho mình.

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các phân hệ và hệ thống bên ngoài để hoàn thành từng việc nghiệp vụ của PH-02, từ lúc chủ dịch vụ đăng ký API tới lúc API được ngừng hẳn. Phạm vi là toàn bộ FR-02-001…062. Chức năng dùng chung FR-00 (đăng nhập, chọn tenant, phân trang, lọc chuẩn, xuất Excel và CSV, kiểm toán chung, tab "Lịch sử", hộp "Việc của tôi", hiển thị lỗi chung) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Hành vi chi tiết của từng bước (kiểm tra, mã lỗi, câu thông báo) nằm ở FR tương ứng; UC mô tả trình tự và vai trò, và nhắc lại mã lỗi cùng câu thông báo ở luồng ngoại lệ để kiểm thử viên không phải lật hai tài liệu.

Tài liệu không thay FRS. Khi UC và FR khác nhau, FR là nguồn chuẩn và UC phải được sửa theo. Việc thực thi lúc chạy (xác thực, hạn mức, chặn đường dẫn ở gateway) thuộc PH-03; hiển thị tài liệu cho nhà phát triển thuộc PH-15; hai phân hệ này chỉ xuất hiện như tác nhân phụ.

### 1.2. Người đọc

Bảng dưới nêu từng nhóm người đọc cần đọc phần nào của tập use case.

| Người đọc | Phần cần đọc | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 3, chương 4, chương 5 | Đánh giá phạm vi, mức phủ FR và hệ cũ, điểm kiểm soát |
| Chủ dịch vụ, người duyệt dịch vụ, đầu mối đơn vị khai thác | Chương 3, chương 6 phần của vai trò mình | Biết việc mình làm và điều hệ thống chặn |
| Kỹ sư giao diện, BFF, dh-connect | Chương 5.2, chương 6, chương 7 | Dựng màn hình và API đúng trình tự |
| Kiểm thử viên | Chương 6: mỗi luồng chính, luồng thay thế, luồng ngoại lệ là một ca kiểm thử ở D05-02-PH02 | Viết ca dương, ca âm, ca vòng đời |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và chữ viết tắt

Thuật ngữ, chữ viết tắt và vai trò dùng chung với [D02-03-PH02](../frs/D02-03-PH02-frs-danh-muc-dich-vu.md) §1.4 (HTTT, tenant, API, phiên bản, gói sử dụng, đăng ký sử dụng, backend, context-path, thay đổi phá vỡ, bốn mắt, SV, CA, OR, TA, TO, SO, IE, PA, VW, AU). Riêng tập này thêm bốn thuật ngữ.

| Thuật ngữ | Giải thích |
|---|---|
| Use case (UC) | Một mục tiêu nghiệp vụ trọn vẹn của một tác nhân chính, mô tả bằng luồng chính, luồng thay thế và luồng ngoại lệ |
| UC máy | UC mà tác nhân chính là hệ thống (phân hệ khác, lịch, bộ xử lý nền), không có màn hình riêng |
| Luồng phụ dùng chung (LP) | Đoạn xử lý lặp ở nhiều UC, đặc tả một lần ở chương 7 (mã `LP-02-nn`) |
| Việc của tôi | Hộp việc dùng chung (FR-00) nơi hiện mọi yêu cầu duyệt, nhắc việc của một người |

: Thuật ngữ riêng của tập use case

### 1.4. Tài liệu tham chiếu

Bảng dưới liệt kê các tài liệu mà tập use case dựa vào.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D02-03-PH02 | FRS phân hệ PH-02 | Nguồn chuẩn của mã FR, BR, ERR, EVT, API, UI và câu thông báo (§9.2) |
| D02-02 | SRS hệ thống | Nhóm FR-00 dùng chung, REQ-02 |
| D02-08 | Ma trận phân quyền | `PERM-02-*`, vai trò, phạm vi `api:{mã API}:{mã gói}`, cặp loại trừ SV và CA |
| D03-04-PH02 | Thiết kế API | Định nghĩa đầy đủ các `API-02-nnn` |
| D03-06-PH02 | Thiết kế màn hình | Bố cục `UI-02-nn`, câu thông báo |
| D05-02-PH02 | Test case | Ca kiểm thử sinh từ luồng của tập này |
| D00-03 phần A | Kiểm kê hệ cũ | `LGC-APIM-*`, `LGC-BUS-028` ở bảng 5.3 |

: Tài liệu tham chiếu của tập use case

### 1.5. Cấu trúc tài liệu

Chương 2 giải thích cách đọc đặc tả và dữ liệu minh họa. Chương 3 nêu tác nhân. Chương 4 vẽ sơ đồ use case tổng thành bốn hình. Chương 5 gồm bốn bảng truy vết: UC ↔ FR, UC ↔ màn hình ↔ API, UC ↔ REQ ↔ quy trình ↔ hệ cũ, và FR → UC. Chương 6 đặc tả chi tiết 38 UC. Chương 7 gom bảy luồng phụ dùng chung. Chương 8 đối chiếu mã. Chương 9 là câu hỏi mở.

## 2. Quy ước đọc đặc tả

Mỗi UC được đặc tả bằng một khối hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ, Quy tắc áp dụng, Màn hình và API. Đảm bảo tối thiểu là điều luôn đúng kể cả khi UC thất bại giữa chừng; đảm bảo thành công là trạng thái dữ liệu khi UC xong.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `A1`, `A2` kèm bước phát sinh và quay lại luồng chính ở bước nêu rõ. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh, mã `ERR-02-nnn`, câu thông báo người dùng thấy trong ngoặc kép (lấy từ FRS §9.2 hoặc từ bước FR tương ứng) và nêu UC kết thúc hay quay lại bước nào. Lỗi của UC máy không có người nhìn trực tiếp thì nêu nơi người vận hành thấy (nhật ký, cảnh báo, màn UI-02-12 hoặc UI-02-17).

Dữ liệu ví dụ đều giả lập, ngày minh họa là 26/11/2026. Tenant `T68`. Nhân vật và dữ liệu dùng xuyên suốt:

| Ký hiệu | Vai trò hoặc loại | Ghi chú |
|---|---|---|
| **Lan** | SV (chủ dịch vụ), Sở Tư pháp, đơn vị `SO-TUPHAP` | Cung cấp HTTT `HT-TUPHAP` |
| **Minh** | CA (người duyệt dịch vụ) | Không giữ vai trò SV (cặp loại trừ D02-08 §4) |
| **Hạnh** | OR (cán bộ đầu mối), Văn phòng UBND tỉnh `VP-UBND` | Đại diện HTTT khai thác `HT-MOTCUA` |
| **Quang** | TA (quản trị tenant) | Khác Minh khi cần xác nhận lần hai |
| **Chi** | TO (vận hành tenant) | |
| **Dũng** | SO (cán bộ ATTT) | |
| **An** | IE (kỹ sư tích hợp) | Làm việc ở PH-04, PH-05 |
| **Hà** | PA (quản trị nền tảng) | |
| `tra-cuu-ho-tich` | API mức `RESTRICTED`, nhóm `ho-tich`, phiên bản `1.0.0` | Context-path `/ho-tich/tra-cuu-ho-tich/v1` |
| `ho-so-dat-dai` | API mức `INTERNAL`, `HT-DATDAI`, phiên bản `1.2.0` rồi `2.0.0` | Dùng cho ví dụ phiên bản, ngừng dùng, SLA |
| `danh-muc-dan-toc` | API mức `PUBLIC`, gói `KEYLESS` | Dùng cho ví dụ công khai |
| `HT-MOTCUA`, `HT-YTE`, `HT-DVC` | HTTT khai thác | Có định danh máy ở PH-01 (trừ khi UC nói khác) |
| Gói `cong-khai`, `tich-hop-noi-bo`, `tich-hop-bao-mat` | Ba gói mẫu của FR-02-027 | |

: Nhân vật và dữ liệu minh họa

## 3. Tác nhân

Bảng dưới liệt kê tác nhân người theo vai trò D02-08, tác nhân máy theo phân hệ và UC mà họ là tác nhân chính. Tác nhân phụ xuất hiện ở khối "Tác nhân phụ" của từng UC.

| Tác nhân | Loại | Use case chính |
|---|---|---|
| Chủ dịch vụ (SV, `ROLE-SERVICE_OWNER`, Lan) | Chính | 03, 05, 06, 07, 08, 11, 12, 13, 14, 15, 18, 19, 20, 21, 24, 26, 31, 33 |
| Người duyệt dịch vụ (CA, `ROLE-CATALOG_APPROVER`, Minh) | Chính | 13, 14, 16, 19, 20, 21, 24 |
| Cán bộ đầu mối tổ chức (OR, `ROLE-ORG_REQUESTER`, Hạnh) | Chính | 23, 28; phối hợp 26, 27 |
| Quản trị tenant (TA, `ROLE-TENANT_ADMIN`, Quang) | Chính | 22, 37, 38; thay SV, CA ở mức tenant; xác nhận lần hai ở 16 |
| Vận hành tenant (TO, `ROLE-TENANT_OPERATOR`, Chi) | Chính | 30, 36; phối hợp 17, 27 |
| Cán bộ ATTT (SO, `ROLE-SECURITY_OFFICER`, Dũng) | Chính | 17, 27 (tạm ngừng khẩn); phối hợp 07 |
| Kỹ sư tích hợp (IE, `ROLE-INTEGRATION_ENGINEER`, An) | Chính | 01, 04, 10 |
| Quản trị nền tảng (PA, `ROLE-PLATFORM_ADMIN`, Hà) | Chính | 37, 38 (cùng TA) |
| Người xem (VW), kiểm toán viên (AU) | Chính | 01, 34 (chỉ xem) |
| HTTT khai thác (máy, scope `catalog:read`) | Chính (máy) | 02 |
| PH-04 `dh-integration` (scope `catalog:flow-sync`) | Chính (máy) | 09, 35 |
| PH-03 bộ đồng bộ cấu hình, PH-15 cổng nhà phát triển | Chính (máy) | 35 |
| Bộ cấp quyền của PH-02 | Chính (máy) | 25 |
| Lịch và bộ xử lý nền của PH-02 | Chính (máy) | 29, 32, 33 |
| PH-01, PH-10, PH-12, PH-13, PH-14, PH-16, PH-18 | Phụ | Nhiều UC: hồ sơ HTTT, topic, định danh, số đo, kết nối quốc gia, chỉ tiêu, tham số và hộp việc |
| Nền tảng quốc gia, dịch vụ quét mã độc (DD-12), kho đối tượng Garage | Phụ | 29, 30; 05, 37; 05 |

: Tác nhân của PH-02 và use case chính

Cặp SV và CA loại trừ nhau trong cùng tenant (D02-08 §4), nên ở mọi UC có duyệt, Lan và Minh là hai người khác nhau; riêng API mức `SENSITIVE`, người xác nhận lần hai là Quang (TA) khác Minh (UC-02-16).

## 4. Sơ đồ use case tổng

38 UC vượt ngưỡng đọc được trên một trang A4, nên sơ đồ tổng chia làm bốn hình theo nhóm nghiệp vụ: danh mục, đăng ký API và kiểm tra đặc tả (Hình 1); backend, gói và vòng đời API (Hình 2); đăng ký sử dụng (Hình 3); đồng bộ quốc gia, chất lượng, tích hợp và quản trị (Hình 4).

```{.mermaid caption="Use case danh mục, đăng ký API và kiểm tra đặc tả"}
flowchart LR
  IE(["Kỹ sư tích hợp"])
  SV(["Chủ dịch vụ"])
  SO(["Cán bộ ATTT"])
  TA(["Quản trị tenant"])
  HK(["HTTT khai thác"])
  P15(["PH-15"])
  P4(["PH-04"])
  subgraph TC["Danh mục và tra cứu"]
    U01["UC-02-01 Tra cứu, xem chi tiết, tải đặc tả"]
    U02["UC-02-02 Cung cấp danh mục cho máy"]
    U03["UC-02-03 Phân loại, gắn thẻ"]
    U04["UC-02-04 Dịch vụ sự kiện"]
  end
  subgraph DK["Đăng ký API và kiểm tra đặc tả"]
    U05["UC-02-05 Đăng ký API bằng trình hướng dẫn"]
    U06["UC-02-06 Kiểm tra hai lớp, sửa lỗi"]
    U07["UC-02-07 Bí mật, API trùng"]
    U08["UC-02-08 Đồng bộ lại đặc tả từ URL"]
    U09["UC-02-09 Tự đăng ký từ luồng PH-04"]
    U10["UC-02-10 Sinh khung route cho PH-04"]
  end
  IE --> U01 & U04 & U10
  SV --> U03 & U05 & U06 & U07 & U08 & U10
  SO --> U07
  TA --> U03
  HK --> U02
  P15 --> U02
  P4 --> U09
```

Hình 1 cho thấy chủ dịch vụ là tác nhân của hầu hết UC ở giai đoạn đưa API vào danh mục, còn tra cứu (UC-02-01) mở cho mọi vai trò. UC-02-02 và UC-02-09 là UC máy: HTTT khai thác và PH-15 đọc danh mục, PH-04 đẩy API sinh từ luồng vào.

```{.mermaid caption="Use case backend, gói sử dụng và vòng đời API"}
flowchart LR
  SV(["Chủ dịch vụ"])
  CA(["Người duyệt dịch vụ"])
  TA(["Quản trị tenant"])
  TO(["Vận hành tenant"])
  SO(["Cán bộ ATTT"])
  subgraph BG["Backend và gói sử dụng"]
    U11["UC-02-11 Backend, cân bằng tải, sức khỏe"]
    U12["UC-02-12 Tạo gói, xác thực, hạn mức"]
    U13["UC-02-13 Công bố gói"]
    U14["UC-02-14 Ngừng khuyến nghị, đóng, sao chép gói"]
  end
  subgraph VD["Vòng đời API"]
    U15["UC-02-15 Thử TEST, gửi duyệt"]
    U16["UC-02-16 Duyệt bốn mắt, công bố ra gateway"]
    U17["UC-02-17 Tạm ngừng khẩn, tiếp tục"]
    U18["UC-02-18 Phiên bản mới, so sánh, tác động"]
    U19["UC-02-19 Ngừng khuyến nghị có lộ trình"]
    U20["UC-02-20 Ngừng hẳn, hủy nháp, xóa API"]
    U21["UC-02-21 Mức hiển thị, cổng nhà phát triển"]
    U22["UC-02-22 Chuyển chủ quản"]
  end
  SV --> U11 & U12 & U13 & U14 & U15 & U18 & U19 & U20 & U21
  CA --> U13 & U14 & U16 & U19 & U20 & U21
  TA --> U16 & U22
  TO --> U11 & U17
  SO --> U17
```

Hình 2 gom hai nhóm: chuẩn bị API (backend, gói) và điều phối vòng đời. Người duyệt dịch vụ xuất hiện ở sáu UC có bốn mắt; quản trị tenant chỉ xác nhận lần hai ở UC-02-16 và làm UC-02-22; tạm ngừng khẩn (UC-02-17) là UC duy nhất không cần duyệt.

```{.mermaid caption="Use case đăng ký sử dụng API"}
flowchart LR
  OR(["Đầu mối đơn vị khai thác"])
  SV(["Chủ dịch vụ"])
  CA(["Người duyệt dịch vụ"])
  SO(["Cán bộ ATTT"])
  TO(["Vận hành tenant"])
  BQ(["Bộ cấp quyền PH-02"])
  LH(["Lịch PH-02"])
  subgraph DKSD["Đăng ký sử dụng"]
    U23["UC-02-23 Gửi đăng ký sử dụng"]
    U24["UC-02-24 Duyệt hoặc từ chối"]
    U25["UC-02-25 Cấp phạm vi truy cập"]
    U26["UC-02-26 Xem đăng ký theo API, theo HTTT"]
    U27["UC-02-27 Tạm ngừng, thu hồi, hủy"]
    U28["UC-02-28 Gia hạn, rà soát định kỳ"]
  end
  OR --> U23 & U26 & U27 & U28
  SV --> U24 & U26 & U27
  CA --> U24 & U26
  SO --> U27
  TO --> U25 & U27
  BQ --> U25
  LH --> U28
```

Hình 3 cho thấy đường đi của một đăng ký: đầu mối gửi (UC-02-23), người duyệt quyết định (UC-02-24), bộ cấp quyền biến quyết định thành phạm vi thật (UC-02-25, UC máy; TO chỉ thử lại khi lỗi), rồi các UC theo dõi và chấm dứt. Tạm ngừng, thu hồi do ba vai trò khác nhau thực hiện theo mục đích khác nhau (UC-02-27).

```{.mermaid caption="Use case đồng bộ quốc gia, chất lượng, tích hợp và quản trị"}
flowchart LR
  TO(["Vận hành tenant"])
  TA(["Quản trị tenant"])
  PA(["Quản trị nền tảng"])
  SV(["Chủ dịch vụ"])
  HT(["Lịch, sự kiện PH-02"])
  PH(["PH-03, PH-04, PH-15"])
  subgraph QG["Đồng bộ quốc gia"]
    U29["UC-02-29 Đồng bộ lên Nền tảng quốc gia"]
    U30["UC-02-30 Theo dõi, thử lại, quá hạn"]
  end
  subgraph CL["Chất lượng và thông báo"]
    U31["UC-02-31 Khai báo SLA"]
    U32["UC-02-32 Chốt kỳ SLA"]
    U33["UC-02-33 Thông báo thay đổi"]
    U34["UC-02-34 Thống kê sử dụng"]
  end
  subgraph QT["Tích hợp và quản trị"]
    U35["UC-02-35 Giao diện nội bộ cho PH-03, 04, 15"]
    U36["UC-02-36 Đối soát gateway"]
    U37["UC-02-37 Di trú từ APIM cũ"]
    U38["UC-02-38 Bộ luật và tham số"]
  end
  HT --> U29 & U32 & U33 & U36
  TO --> U30 & U36
  TA --> U30 & U37 & U38
  PA --> U37 & U38
  SV --> U31 & U33 & U34
  PH --> U35
```

Hình 4 gom các UC mà phần lớn do hệ thống tự chạy (đồng bộ, chốt kỳ, thông báo, đối soát) và người chỉ can thiệp khi có ngoại lệ hoặc cần quyết định. Nhờ vậy nghĩa vụ pháp lý (đăng ký danh mục) và minh bạch chất lượng (SLA) không phụ thuộc việc ai đó nhớ làm.

## 5. Bảng tổng hợp use case và truy vết

Bốn bảng dưới nối UC với FR, màn hình, API, REQ, quy trình, hệ cũ và đối chiếu ngược FR sang UC. Mã FR ghi rút gọn ba chữ số (001 là FR-02-001); mã API cũng rút gọn (API-02-014 ghi 014 khi cùng dòng đã có tiền tố).

### 5.1. Use case và FR

Bảng dưới nối mỗi use case với các chức năng (FR) mà nó hiện thực, để kiểm tra mọi FR đều có use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-02-01 | Tra cứu danh mục, xem chi tiết, cách gọi và tải đặc tả | IE, mọi vai trò | M | 001, 002, 003, 005, 006 |
| UC-02-02 | Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển | HTTT khai thác, PH-15 | M | 004 |
| UC-02-03 | Phân loại, gắn thẻ API và quản lý bộ phân loại | SV, TA | M | 007, 008 |
| UC-02-04 | Xem dịch vụ sự kiện trong danh mục | IE | S | 009 |
| UC-02-05 | Đăng ký API mới bằng trình hướng dẫn | SV | M | 010, 011, 014, 015, 024 |
| UC-02-06 | Kiểm tra đặc tả hai lớp và sửa lỗi | SV | M | 016, 017, 019 |
| UC-02-07 | Xử lý phát hiện bí mật, dữ liệu cá nhân thật và API trùng chức năng | SV, SO | M | 018, 020 |
| UC-02-08 | Đồng bộ lại đặc tả từ URL nguồn | SV, lịch | S | 012 |
| UC-02-09 | Tự đăng ký API từ luồng REST của PH-04 | PH-04 | M | 013 |
| UC-02-10 | Sinh khung route cho PH-04 từ đặc tả | SV, IE | M | 026 |
| UC-02-11 | Khai báo backend, cân bằng tải và theo dõi sức khỏe | SV, TO | M | 022, 023, 025 |
| UC-02-12 | Tạo gói sử dụng: điều kiện, kiểu xác thực, hạn mức | SV | M | 027, 028, 029 |
| UC-02-13 | Công bố gói sử dụng | SV, CA | M | 030 |
| UC-02-14 | Ngừng khuyến nghị, đóng và sao chép gói | SV, CA | M | 031, 032, 033 |
| UC-02-15 | Thử trên TEST và gửi duyệt công bố API | SV | M | 034, 036 |
| UC-02-16 | Duyệt bốn mắt và công bố API ra gateway | CA, TA | M | 035, 036 |
| UC-02-17 | Tạm ngừng khẩn và tiếp tục API | SO, TO | M | 037 |
| UC-02-18 | Tạo phiên bản mới, so sánh và phân tích tác động | SV | M | 042, 043, 044 |
| UC-02-19 | Ngừng khuyến nghị API có lộ trình | SV, CA | M | 038 |
| UC-02-20 | Ngừng hẳn, hủy bản nháp và xóa API | SV, CA | M | 039, 040 |
| UC-02-21 | Đặt mức hiển thị và hiện ở cổng nhà phát triển | SV, CA | M | 041 |
| UC-02-22 | Chuyển chủ quản API | TA | S | 045 |
| UC-02-23 | Gửi đăng ký sử dụng API | OR | M | 046 |
| UC-02-24 | Duyệt hoặc từ chối đăng ký sử dụng | SV, CA | M | 047 |
| UC-02-25 | Cấp phạm vi truy cập theo đăng ký đã duyệt | Bộ cấp quyền PH-02 | M | 048 |
| UC-02-26 | Xem đăng ký theo API và theo HTTT | SV, OR | M | 049, 050 |
| UC-02-27 | Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký | SO, SV, OR, TO | M | 051 |
| UC-02-28 | Gia hạn và rà soát định kỳ đăng ký | OR, lịch | S | 052 |
| UC-02-29 | Đồng bộ danh mục lên Nền tảng quốc gia | Lịch, sự kiện | M | 053 |
| UC-02-30 | Theo dõi đồng bộ, thử lại và xử lý quá hạn | TO, TA | M | 054 |
| UC-02-31 | Khai báo cam kết chất lượng dịch vụ (SLA) | SV | M | 055 |
| UC-02-32 | Chốt kỳ tuân thủ SLA và cảnh báo | Lịch | M | 056 |
| UC-02-33 | Thông báo thay đổi cho bên khai thác | Hệ thống, SV | M | 057 |
| UC-02-34 | Xem thống kê sử dụng dịch vụ | SV, CA, TA | S | 058 |
| UC-02-35 | PH-03, PH-04, PH-15 đọc dữ liệu công bố qua giao diện nội bộ | PH-03, PH-04, PH-15 | M | 059 |
| UC-02-36 | Đối soát cấu hình công bố với gateway | TO, lịch | C | 060 |
| UC-02-37 | Di trú API, gói, đăng ký từ APIM cũ | TA, PA | M | 061 |
| UC-02-38 | Quản lý bộ luật kiểm tra và tham số phân hệ | TA, PA | M | 021, 062 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Bảng dưới nối mỗi use case với màn hình và API mà người dùng hoặc hệ thống dùng khi thực hiện nó.

| UC | UI | API |
|---|---|---|
| UC-02-01 | UI-02-01, 02 | API-02-001, 002, 003, 006, 007, 090, 091 |
| UC-02-02 | UI-02-01 | API-02-004, 005, 081 |
| UC-02-03 | UI-02-02, 03, 14 | API-02-008, 009, 010, 011, 012 |
| UC-02-04 | UI-02-01 | API-02-013 |
| UC-02-05 | UI-02-02, 03 | API-02-014, 015, 018, 019, 022, 030 |
| UC-02-06 | UI-02-03, 04 | API-02-020, 021, 022, 092 |
| UC-02-07 | UI-02-03, 04, 10 | API-02-020, 021, 023, 093, 094 |
| UC-02-08 | UI-02-02 | API-02-016, 095 |
| UC-02-09 | UI-02-02 (nhãn "Sinh từ luồng") | API-02-017; EVT-04-04, 07 |
| UC-02-10 | UI-02-02 | API-02-032, 007, 095 |
| UC-02-11 | UI-02-02, 03, 01 | API-02-026, 027, 028, 029, 031 |
| UC-02-12 | UI-02-06, 07 | API-02-033, 034, 035, 036, 096 |
| UC-02-13 | UI-02-06, 10 | API-02-037, 044, 045 |
| UC-02-14 | UI-02-06, 10 | API-02-038, 039, 040, 041, 044, 096 |
| UC-02-15 | UI-02-02, 03 | API-02-042, 043, 047 |
| UC-02-16 | UI-02-10, 02 | API-02-044, 098, 045, 046, 047, 082 |
| UC-02-17 | UI-02-02 | API-02-048, 049 |
| UC-02-18 | UI-02-02, 05 | API-02-054, 055, 056 |
| UC-02-19 | UI-02-13, 10, 05 | API-02-050, 044, 056 |
| UC-02-20 | UI-02-13, 02, 10 | API-02-051, 052, 044 |
| UC-02-21 | UI-02-02, 10 | API-02-053, 044 |
| UC-02-22 | UI-02-02 | API-02-057 |
| UC-02-23 | UI-02-09, 01, 02 | API-02-058 |
| UC-02-24 | UI-02-10 | API-02-044, 098, 045, 046 |
| UC-02-25 | UI-02-08 | API-02-067, 068 |
| UC-02-26 | UI-02-02, 08 | API-02-059, 060 |
| UC-02-27 | UI-02-08, 02 | API-02-061, 062, 063, 064 |
| UC-02-28 | UI-02-08 | API-02-065, 066 |
| UC-02-29 | UI-02-12 | API-02-069, 071, 095; EVT-02-14 |
| UC-02-30 | UI-02-12, 01 | API-02-070, 071, 072 |
| UC-02-31 | UI-02-02, 03 | API-02-073, 074 |
| UC-02-32 | UI-02-11, 01, 02 | API-02-074, 075, 097; EVT-02-13 |
| UC-02-33 | UI-02-13 | API-02-076, 077; EVT-02-12 |
| UC-02-34 | UI-02-11, 02 | API-02-078, 079 |
| UC-02-35 | — | API-02-080, 081, 082, 007 |
| UC-02-36 | UI-02-17 | API-02-083, 084, 095; EVT-02-15 |
| UC-02-37 | UI-02-16 | API-02-085, 086, 087 |
| UC-02-38 | UI-02-15, 17 | API-02-024, 025, 088, 089 |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Bảng dưới nối mỗi use case với yêu cầu nghiệp vụ (REQ), quy trình liên quan và chức năng hệ cũ mà use case thay thế hoặc kế thừa.

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-02-01 | REQ-02 | Khai thác dịch vụ | LGC-APIM-001; LGC-APIM-017 |
| UC-02-02 | REQ-02 | Khai thác dịch vụ | Không có (năng lực mới, CMP-LAW-03) |
| UC-02-03 | REQ-02 | Công bố dịch vụ | Không có (năng lực mới) |
| UC-02-04 | REQ-02, REQ-10 | Khai thác dịch vụ | Không có (năng lực mới) |
| UC-02-05 | REQ-02 | Kết nạp HTTT → công bố dịch vụ | LGC-APIM-002; LGC-APIM-003; LGC-APIM-004 |
| UC-02-06 | REQ-02 | Kết nạp HTTT → công bố dịch vụ | LGC-APIM-003 |
| UC-02-07 | REQ-02 | Kết nạp HTTT → công bố dịch vụ | Không có (năng lực mới, CMP-LAW-05) |
| UC-02-08 | REQ-02 | Công bố dịch vụ | Không có (năng lực mới) |
| UC-02-09 | REQ-02, REQ-04 | Thiết kế, phát hành luồng | LGC-BUS-028 |
| UC-02-10 | REQ-02, REQ-04 | Thiết kế, phát hành luồng | Không có (năng lực mới) |
| UC-02-11 | REQ-02, REQ-03, REQ-13 | Công bố dịch vụ | LGC-APIM-002; LGC-APIM-018 |
| UC-02-12 | REQ-02, REQ-03 | Công bố dịch vụ | LGC-APIM-009; LGC-APIM-010; LGC-APIM-011 |
| UC-02-13 | REQ-02, REQ-03 | Công bố dịch vụ | LGC-APIM-009 |
| UC-02-14 | REQ-02, REQ-03 | Nâng phiên bản, ngừng dùng | LGC-APIM-009 |
| UC-02-15 | REQ-02 | Kết nạp HTTT → công bố dịch vụ | LGC-APIM-004 |
| UC-02-16 | REQ-02 | Kết nạp HTTT → công bố dịch vụ | LGC-APIM-004; LGC-APIM-006 |
| UC-02-17 | REQ-02, REQ-03, REQ-13 | Sự cố ATTT | LGC-APIM-005 |
| UC-02-18 | REQ-02 | Nâng phiên bản, ngừng dùng | Không có (năng lực mới) |
| UC-02-19 | REQ-02, REQ-03, REQ-13 | Nâng phiên bản, ngừng dùng | LGC-APIM-008 |
| UC-02-20 | REQ-02, REQ-03, REQ-13 | Nâng phiên bản, ngừng dùng | LGC-APIM-008 |
| UC-02-21 | REQ-02, REQ-15 | Công bố dịch vụ | LGC-APIM-006 (LGC-APIM-007 thuộc PH-15) |
| UC-02-22 | REQ-02 | Quản trị (sáp nhập, đổi tổ chức) | Không có (năng lực mới) |
| UC-02-23 | REQ-02, REQ-09, REQ-12 | Khai thác dịch vụ | LGC-APIM-016; LGC-APIM-021 |
| UC-02-24 | REQ-02, REQ-09, REQ-12 | Khai thác dịch vụ | LGC-APIM-016 |
| UC-02-25 | REQ-02, REQ-03, REQ-12 | Khai thác dịch vụ | Không có (năng lực mới, SEC-24, SEC-26) |
| UC-02-26 | REQ-02, REQ-09, REQ-12 | Khai thác dịch vụ | LGC-APIM-016; LGC-APIM-021 |
| UC-02-27 | REQ-02, REQ-03, REQ-12 | Sự cố ATTT | LGC-APIM-016; LGC-APIM-021 |
| UC-02-28 | REQ-02, REQ-09, REQ-12 | Khai thác dịch vụ | LGC-APIM-016; LGC-APIM-021 |
| UC-02-29 | REQ-02, REQ-14 | Đồng bộ danh mục quốc gia | Không có (nghĩa vụ CMP-LAW-03, CMP-LAW-19) |
| UC-02-30 | REQ-02, REQ-14 | Đồng bộ danh mục quốc gia | Không có (nghĩa vụ CMP-LAW-03) |
| UC-02-31 | REQ-02, REQ-13, REQ-16 | Công bố dịch vụ | Không có (năng lực mới) |
| UC-02-32 | REQ-02, REQ-13, REQ-16 | Vận hành | Không có (năng lực mới) |
| UC-02-33 | REQ-02 | Nâng phiên bản, ngừng dùng | Không có (năng lực mới) |
| UC-02-34 | REQ-02, REQ-13, REQ-16 | Vận hành | Không có (năng lực mới) |
| UC-02-35 | REQ-02, REQ-03, REQ-15 | Công bố dịch vụ | Không có (điểm nối PH-03, PH-04, PH-15) |
| UC-02-36 | REQ-02, REQ-03, REQ-13 | Vận hành | Không có (năng lực mới) |
| UC-02-37 | REQ-02, REQ-22 | Di trú APIM cũ (strangler) | LGC-APIM-002; LGC-APIM-003; LGC-APIM-009; LGC-APIM-016; LGC-APIM-021 |
| UC-02-38 | REQ-02, REQ-18 | Quản trị | Không có (năng lực mới) |

: Use case, REQ, quy trình và hệ cũ

### 5.4. FR đối chiếu sang use case

Bảng cho thấy mỗi FR có đúng một UC chính và (nếu có) các UC phối hợp. Cột "Mức" lấy từ danh sách chức năng của FRS.

| FR | Mức | UC chính | UC phối hợp |
|---|---|---|---|
| FR-02-001 | M | UC-02-01 | UC-02-26 |
| FR-02-002 | M | UC-02-01 | — |
| FR-02-003 | M | UC-02-01 | — |
| FR-02-004 | M | UC-02-02 | UC-02-35 |
| FR-02-005 | M | UC-02-01 | UC-02-25 |
| FR-02-006 | M | UC-02-01 | UC-02-10, UC-02-35 |
| FR-02-007 | M | UC-02-03 | UC-02-05 |
| FR-02-008 | S | UC-02-03 | — |
| FR-02-009 | S | UC-02-04 | — |
| FR-02-010 | M | UC-02-05 | — |
| FR-02-011 | M | UC-02-05 | UC-02-37 |
| FR-02-012 | S | UC-02-08 | — |
| FR-02-013 | M | UC-02-09 | — |
| FR-02-014 | M | UC-02-05 | UC-02-09 |
| FR-02-015 | S | UC-02-05 | — |
| FR-02-016 | M | UC-02-06 | UC-02-15 |
| FR-02-017 | M | UC-02-06 | UC-02-15 |
| FR-02-018 | M | UC-02-07 | UC-02-15 |
| FR-02-019 | M | UC-02-06 | UC-02-05 |
| FR-02-020 | S | UC-02-07 | UC-02-16 |
| FR-02-021 | S | UC-02-38 | — |
| FR-02-022 | M | UC-02-11 | UC-02-05 |
| FR-02-023 | M | UC-02-11 | — |
| FR-02-024 | M | UC-02-05 | UC-02-37 |
| FR-02-025 | S | UC-02-11 | UC-02-01 |
| FR-02-026 | M | UC-02-10 | UC-02-09 |
| FR-02-027 | M | UC-02-12 | UC-02-37 |
| FR-02-028 | M | UC-02-12 | — |
| FR-02-029 | M | UC-02-12 | — |
| FR-02-030 | M | UC-02-13 | UC-02-16 |
| FR-02-031 | M | UC-02-14 | UC-02-19 |
| FR-02-032 | M | UC-02-14 | UC-02-20 |
| FR-02-033 | S | UC-02-14 | UC-02-18 |
| FR-02-034 | M | UC-02-15 | UC-02-05 |
| FR-02-035 | M | UC-02-16 | UC-02-13, 14, 19, 20, 21, 24 |
| FR-02-036 | M | UC-02-16 | UC-02-15 |
| FR-02-037 | M | UC-02-17 | UC-02-33 |
| FR-02-038 | M | UC-02-19 | UC-02-33 |
| FR-02-039 | M | UC-02-20 | UC-02-33 |
| FR-02-040 | M | UC-02-20 | — |
| FR-02-041 | M | UC-02-21 | UC-02-29 |
| FR-02-042 | M | UC-02-18 | — |
| FR-02-043 | M | UC-02-18 | UC-02-15 |
| FR-02-044 | M | UC-02-18 | UC-02-19, UC-02-20 |
| FR-02-045 | S | UC-02-22 | — |
| FR-02-046 | M | UC-02-23 | — |
| FR-02-047 | M | UC-02-24 | — |
| FR-02-048 | M | UC-02-25 | UC-02-24 |
| FR-02-049 | M | UC-02-26 | — |
| FR-02-050 | M | UC-02-26 | UC-02-23 |
| FR-02-051 | M | UC-02-27 | — |
| FR-02-052 | S | UC-02-28 | — |
| FR-02-053 | M | UC-02-29 | UC-02-21 |
| FR-02-054 | M | UC-02-30 | — |
| FR-02-055 | M | UC-02-31 | UC-02-05 |
| FR-02-056 | M | UC-02-32 | UC-02-31 |
| FR-02-057 | M | UC-02-33 | UC-02-17, 19, 20, 31 |
| FR-02-058 | S | UC-02-34 | — |
| FR-02-059 | M | UC-02-35 | UC-02-09, UC-02-10 |
| FR-02-060 | C | UC-02-36 | — |
| FR-02-061 | M | UC-02-37 | — |
| FR-02-062 | M | UC-02-38 | — |

: FR đối chiếu sang use case

## 6. Đặc tả chi tiết use case

Chương này đặc tả 38 UC cho kỹ sư và kiểm thử viên. UC đi theo bảy nhóm nghiệp vụ, theo thứ tự một API trải qua: tra cứu (6.1 đến 6.4), đăng ký và kiểm tra đặc tả (6.5 đến 6.10), backend và gói (6.11 đến 6.14), vòng đời (6.15 đến 6.22), đăng ký sử dụng (6.23 đến 6.28), đồng bộ quốc gia và chất lượng (6.29 đến 6.34), tích hợp và quản trị (6.35 đến 6.38). Số mục `6.n` trùng số UC (6.5 là UC-02-05).

### 6.1. UC-02-01 · Tra cứu danh mục, xem chi tiết, cách gọi và tải đặc tả

::: dac-ta
**Mục tiêu.** Cán bộ kỹ thuật tìm đúng API trong danh mục của tỉnh, hiểu API làm gì, gọi ở địa chỉ nào, cần xác thực và phạm vi gì, rồi tải đặc tả OpenAPI để dựng tích hợp mà không phải hỏi từng đơn vị.

**Tác nhân chính.** `ROLE-INTEGRATION_ENGINEER` (An); cũng dùng cho VW, AU, OR, SV.

**Tác nhân phụ.** PH-13 (SLA thực tế), PH-01 (đầu mối kỹ thuật của HTTT cung cấp), kho đối tượng Garage (tệp đặc tả).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-001, 002, 003, 005, 006.

**Truy vết.** REQ-02; quy trình Khai thác dịch vụ; LGC-APIM-001; LGC-APIM-017.

**Tiền điều kiện.** An đã đăng nhập tenant `T68` và có `PERM-02-read`; danh mục có ít nhất một API có phiên bản `PUBLISHED`.

**Kích hoạt.** An mở menu "Kết nối & API → Danh mục API" (`/ket-noi/api`, UI-02-01).

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu. Phiên bản `DRAFT`, `PENDING` của đơn vị khác không hiện (BR-02-039); đối tượng của tenant khác không lộ sự tồn tại (BR-02-033).

**Đảm bảo thành công.** An có đường dẫn gọi, mẫu gọi, tệp đặc tả đã gộp tham chiếu và thấy SLA cam kết cạnh số đo thực tế của API cần dùng.

**Luồng chính.**

1. Hệ thống mở UI-02-01 và gọi API-02-001 với mặc định: trạng thái khác `RETIRED`, API có cảnh báo (SLA không đạt, đồng bộ quốc gia lỗi, gateway lệch) xếp trước, rồi theo thời gian cập nhật giảm dần; năm thẻ tổng Tất cả, Đang chạy, Chờ duyệt, Sắp ngừng, Cần chú ý hiện ở đầu trang.
2. An gõ "hộ tịch" vào ô tìm kiếm. Hệ thống gọi API-02-003 tìm toàn văn trên tên, mô tả, thẻ, tên thao tác và trả `tra-cuu-ho-tich` cùng `dang-ky-khai-sinh` với p95 ≤ 500 ms (NFR-02-002).
3. An lọc theo phân loại `RESTRICTED`; bộ lọc ghi vào đường dẫn để chia sẻ (tuân thủ FR-00-022).
4. An bấm dòng `tra-cuu-ho-tich`. Hệ thống gọi API-02-002, xác nhận API thuộc `T68`, dựng tám tab Tổng quan, Phiên bản, Backend, Gói sử dụng, Đăng ký, Thống kê, SLA, Lịch sử; vì An là IE nên tab Đăng ký và Thống kê chỉ hiện số tổng.
5. Ở tab Tổng quan, hệ thống hiện đường dẫn sử dụng (API-02-006): địa chỉ gateway `https://api.t68.gov.vn` ghép context-path `/ho-tich/tra-cuu-ho-tich/v1`, kiểu xác thực của từng gói, phạm vi cần có `api:tra-cuu-ho-tich:tich-hop-bao-mat` và đoạn mẫu `curl` có giá trị giữ chỗ.
6. An mở tab Phiên bản, chọn `1.0.0` và bấm "Tải đặc tả". Hệ thống gọi API-02-007, trả tệp `tra-cuu-ho-tich-1.0.0.yaml` đã gộp tham chiếu ngoài, kèm `ETag`.
7. An mở tab SLA. Hệ thống hiện cam kết (p99 3.000 ms, sẵn sàng 99,5%) cạnh số đo thực tế kỳ `2026-10` (p99 2.140 ms, sẵn sàng 99,7%) lấy từ PH-13.

**Luồng thay thế.**

- **A1. (bước 3) An bấm một thẻ tổng.** Hệ thống áp bộ lọc nhanh tương ứng, ví dụ "Sắp ngừng" chỉ giữ API có phiên bản `DEPRECATED`; quay lại bước 4.
- **A2. (bước 4) An mở phiên bản cũ.** An chọn phiên bản ở bộ chọn đầu trang; mọi tab hiển thị theo phiên bản đó; với phiên bản `DEPRECATED` hệ thống hiện thêm hạn chuyển đổi, phiên bản kế nhiệm, số bên chưa chuyển.
- **A3. (bước 1) An bấm "Xuất".** Hệ thống xuất danh sách theo bộ lọc hiện tại ra Excel hoặc CSV (tuân thủ FR-00-030); use case kết thúc.

**Luồng ngoại lệ.**

- **E1. API không có hoặc thuộc tenant khác (bước 4).** ERR-02-001 (404, cùng thân với "không tồn tại"); "Không tìm thấy API {mã}." UC kết thúc.
- **E2. Tham số lọc sai miền, `size` lớn hơn 200 (bước 1, 2).** ERR-02-003 (400); danh sách giữ bộ lọc hợp lệ gần nhất.
- **E3. PH-13 không khả dụng (bước 7).** Tab SLA hiện cam kết kèm "Số liệu cập nhật lúc {thời điểm}"; không chặn xem; nhật ký ghi ERR-02-034.
- **E4. Phiên bản chưa có đặc tả để tải (bước 6).** Nút "Tải đặc tả" bị khóa và ghi "Phiên bản chưa công bố"; chỉ phiên bản đã công bố mới tải được (BR-02-001).

**Quy tắc áp dụng.** BR-02-001, 013, 033, 039.

**Màn hình, API.** UI-02-01, 02; API-02-001, 002, 003, 006, 007, 090, 091.
:::

### 6.2. UC-02-02 · Cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển

::: dac-ta
**Mục tiêu.** HTTT khai thác và cổng nhà phát triển PH-15 đọc danh mục API kèm đặc tả và điều kiện sử dụng theo đúng mức hiển thị, để nghĩa vụ công khai thông tin dịch vụ chia sẻ được thực hiện mà không lộ backend hay danh sách bên đăng ký.

**Tác nhân chính.** HTTT khai thác `HT-MOTCUA` (máy, scope `catalog:read`); PH-15 (scope `catalog:portal-read`).

**Tác nhân phụ.** PH-03 (giới hạn tần suất, gateway).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-004.

**Truy vết.** REQ-02; quy trình Khai thác dịch vụ; CMP-LAW-03 (năng lực mới, không có LGC tương ứng).

**Tiền điều kiện.** Tài khoản máy đã có scope; ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED` có mức hiển thị phù hợp với chủ thể.

**Kích hoạt.** PH-15 nạp danh mục theo lịch hoặc HTTT gọi `GET /catalog/apis`.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; không bao giờ trả backend, địa chỉ nội bộ, danh sách bên đăng ký hoặc phiên bản nháp.

**Đảm bảo thành công.** Bên gọi nhận đúng tập API được phép thấy; `304` khi chưa đổi.

**Luồng chính.**

1. `HT-MOTCUA` gọi API-02-004 kèm token máy và `If-None-Match` của lần trước.
2. Hệ thống xác định chủ thể từ token: HTTT khai thác trong `T68`, PH-15 hoặc người dùng không đăng nhập ở cổng công khai.
3. Hệ thống chọn tập API được thấy: chủ thể trong `T68` thấy `TENANT`, `NATIONAL`, `PUBLIC`; người không đăng nhập ở cổng công khai chỉ thấy `PUBLIC` (BR-02-037).
4. Hệ thống chỉ giữ phiên bản `PUBLISHED`, `DEPRECATED`; phiên bản `SUSPENDED` hiện nhãn "Tạm ngừng" ở chi tiết, phiên bản nháp bị loại.
5. Hệ thống dựng mục danh mục: mã, tên, mô tả, chủ quản, `dataClass`, SLA cam kết và thực tế, phạm vi cần có, trạng thái, số phiên bản, liên kết tới đặc tả và tài liệu.
6. Hệ thống tính `ETag` theo băm nội dung; khớp `If-None-Match` thì trả `304`, không thì trả `200` kèm `Cache-Control: private, max-age=300`.

**Luồng thay thế.**

- **A1. (bước 1) PH-15 đồng bộ gia tăng.** PH-15 gọi API-02-081 với `updatedSince`; hệ thống chỉ trả mục đổi sau thời điểm đó kèm `removed[]` là mã đã gỡ; quay lại bước 6.
- **A2. (bước 1) Bên gọi xem một API cụ thể.** Bên gọi gọi API-02-005 (`GET /catalog/apis/{apiCode}`); hệ thống áp cùng quy tắc ở bước 3 và 4.

**Luồng ngoại lệ.**

- **E1. Token thiếu hoặc không có scope `catalog:read` (bước 1).** ERR-02-014 (`401`, `403`); không có màn hình, nhật ký an ninh ghi lại.
- **E2. API không thuộc tập được thấy (bước 3).** Không xuất hiện trong danh sách; gọi thẳng chi tiết trả ERR-02-001 (404).
- **E3. Vượt giới hạn tần suất.** `429` do gateway PH-03, tiêu đề `Retry-After`; không phải lỗi của PH-02.

**Quy tắc áp dụng.** BR-02-001, 033, 037.

**Màn hình, API.** UI-02-01 (cùng dữ liệu); API-02-004, 005, 081.
:::

### 6.3. UC-02-03 · Phân loại, gắn thẻ API và quản lý bộ phân loại

::: dac-ta
**Mục tiêu.** Mỗi API có nhóm phân loại và thẻ đúng để dễ tìm, và quản trị tenant giữ bộ phân loại gọn, thống nhất toàn tỉnh.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan) gắn thẻ; `ROLE-TENANT_ADMIN` (Quang) quản lý bộ phân loại.

**Tác nhân phụ.** Không.

**Mức ưu tiên.** M (gắn thẻ), S (quản lý bộ phân loại) · MVP.

**FR hiện thực.** FR-02-007, 008.

**Truy vết.** REQ-02; quy trình Công bố dịch vụ; không có LGC (SRS hệ thống PH-02 ghi "phân loại, gắn thẻ").

**Tiền điều kiện.** Lan có `PERM-02-create` với API của `SO-TUPHAP`; Quang có quyền quản trị phân hệ (đề nghị, động từ `admin`).

**Kích hoạt.** Lan sửa khối "Phân loại" ở tab Tổng quan (UI-02-02) hoặc bước 1 của UI-02-03; Quang mở UI-02-14 (`/ket-noi/quan-tri/phan-loai`).

**Đảm bảo tối thiểu.** Không đổi `categoryCode` đã dùng thành mã khác; thay đổi nhóm không làm đổi context-path của phiên bản đã `PUBLISHED` (BR-02-022).

**Đảm bảo thành công.** API có nhóm và thẻ mới; bộ phân loại phản ánh cây nhóm do Quang chỉnh.

**Luồng chính.**

1. Lan mở API `tra-cuu-ho-tich` ở UI-02-02 và chọn "Sửa phân loại".
2. Lan chọn nhóm `ho-tich`, mức phân loại dữ liệu `RESTRICTED`, khai `containsPersonalData = true` và thêm thẻ `khai-sinh`, `dinh-danh`.
3. Hệ thống kiểm tra nhóm có trong bộ phân loại, `stateSecret = false`, và `dataClass` không mâu thuẫn với mức hiển thị hiện có (BR-02-007, BR-02-037); mâu thuẫn thì ERR-02-043.
4. Hệ thống lưu qua API-02-008, ghi kiểm toán giá trị trước và sau, phát EVT-02-02 (`changedFields = category, tags`).
5. Quang mở UI-02-14 (cây nhóm và bảng), thêm nhóm con `ho-tich/khai-sinh`, đổi tên nhóm `khac` thành "Khác" và gọi API-02-009, 010, 011.
6. Quang gộp nhóm `dan-su` vào `ho-tich`; hệ thống hiện số API bị ảnh hưởng (7) trước khi xác nhận, rồi chuyển API sang nhóm đích (API-02-012) mà không đổi `apiCode` hay context-path đã công bố.

**Luồng thay thế.**

- **A1. (bước 2) Lan khai dữ liệu thuộc bí mật nhà nước.** Hệ thống từ chối ở bước 3 (xem E2).
- **A2. (bước 6) Quang xóa nhóm còn API.** Hệ thống yêu cầu chọn nhóm đích trước khi xóa; nhóm trống mới xóa được.

**Luồng ngoại lệ.**

- **E1. Mức hiển thị không phù hợp mức phân loại (bước 3).** ERR-02-043 (422); "Mức hiển thị {mức} không phù hợp với dữ liệu mức {phân loại}." Quay lại bước 2.
- **E2. Khai `stateSecret = true` (bước 3).** ERR-02-016 (422); "Dữ liệu thuộc danh mục bí mật nhà nước không được công bố trên Datahub." UC kết thúc, không lưu.
- **E3. Mã nhóm trùng, kể cả nhóm đã xóa (bước 5).** ERR-02-002 (409); "Mã {mã} đã được dùng (kể cả đối tượng đã xóa hoặc ngừng). Chọn mã khác."
- **E4. Lan không thuộc tổ chức chủ quản (bước 1).** ERR-02-014 (403); "Bạn không thuộc đơn vị chủ quản của HTTT này."

**Quy tắc áp dụng.** BR-02-007, 021, 022, 037.

**Màn hình, API.** UI-02-02, 03, 14; API-02-008, 009, 010, 011, 012.
:::

### 6.4. UC-02-04 · Xem dịch vụ sự kiện trong danh mục

::: dac-ta
**Mục tiêu.** Kỹ sư tìm được topic sự kiện đang hoạt động ngay trong danh mục dịch vụ, cùng một chỗ với API, và biết vào PH-10 để đăng ký.

**Tác nhân chính.** `ROLE-INTEGRATION_ENGINEER` (An).

**Tác nhân phụ.** PH-10 (topic và lược đồ sự kiện).

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-02-009.

**Truy vết.** REQ-02, REQ-10; quy trình Khai thác dịch vụ; Q02-05; không có LGC (năng lực mới).

**Tiền điều kiện.** An có `PERM-02-read`; PH-10 có topic `ACTIVE` của `T68`.

**Kích hoạt.** An bật bộ lọc "Dịch vụ sự kiện" ở UI-02-01.

**Đảm bảo tối thiểu.** Không đăng ký, duyệt hay đổi vòng đời topic ở PH-02 (BR-02-038); chỉ hiển thị.

**Đảm bảo thành công.** An thấy topic `t68.dat-dai.thua-dat.updated.v1` kèm mô tả, lược đồ, chủ quản và liên kết sang PH-10.

**Luồng chính.**

1. An mở UI-02-01 và bật bộ lọc "Dịch vụ sự kiện".
2. Hệ thống gọi API-02-013, lấy từ PH-10 danh sách topic `ACTIVE` của `T68` kèm mô tả và lược đồ (qua API của PH-10; PH-02 không giữ bản chép riêng ngoài bộ đệm).
3. Hệ thống trộn topic vào danh sách với nhãn "Sự kiện", ẩn các cột chỉ có nghĩa với API (backend, gói).
4. An bấm topic `t68.dat-dai.thua-dat.updated.v1`; hệ thống hiện chi tiết chỉ đọc: mô tả, lược đồ, chủ quản, phiên bản và nút "Mở ở PH-10" để đăng ký.

**Luồng thay thế.**

- **A1. (bước 2) PH-10 không khả dụng.** Hệ thống hiển thị phần đã đệm kèm "Số liệu cập nhật lúc {thời điểm}"; quay lại bước 3.

**Luồng ngoại lệ.**

- **E1. Topic thuộc tenant khác (bước 2).** Không xuất hiện; truy cập trực tiếp trả ERR-02-001 (404); "Không tìm thấy dịch vụ."
- **E2. Topic không còn `ACTIVE` (bước 4).** Dòng biến khỏi danh sách ở lần nạp kế; chi tiết đang mở hiện "Dịch vụ đã ngừng ở PH-10".
- **E3. Người dùng thử đăng ký topic ngay ở PH-02.** Không có nút; hướng dẫn "Đăng ký ở mục Sự kiện" (BR-02-038).

**Quy tắc áp dụng.** BR-02-033, 038.

**Màn hình, API.** UI-02-01; API-02-013.
:::

### 6.5. UC-02-05 · Đăng ký API mới bằng trình hướng dẫn

::: dac-ta
**Mục tiêu.** Chủ dịch vụ đưa một API mới vào danh mục qua năm bước có hướng dẫn, đủ hợp đồng (đặc tả OpenAPI, nhóm, mức phân loại, context-path), và kết thúc bằng một bản nháp sẵn sàng khai backend, gói rồi gửi duyệt.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan, `SO-TUPHAP`).

**Tác nhân phụ.** PH-01 (kiểm tra HTTT), kho đối tượng Garage (lưu đặc tả), dịch vụ quét mã độc (DD-12).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-010, 011, 014, 015, 024 (và 019 ở bước đặc tả, chi tiết ở UC-02-06).

**Truy vết.** REQ-02; quy trình Kết nạp HTTT → công bố dịch vụ; LGC-APIM-002; LGC-APIM-003; LGC-APIM-004.

**Tiền điều kiện.** Lan có `PERM-02-create`; HTTT `HT-TUPHAP` `ACTIVE` ở PH-01 và thuộc `SO-TUPHAP`; Lan có tệp đặc tả `tra-cuu-ho-tich.yaml` (OpenAPI 3.1, 320 KB, 6 thao tác).

**Kích hoạt.** Lan bấm "+ Đăng ký API" ở UI-02-01, mở UI-02-03 (`/ket-noi/api/moi`).

**Đảm bảo tối thiểu.** Chưa có API nào được tạo nếu Lan thoát giữa chừng (bản nháp của trình hướng dẫn chỉ giữ 7 ngày); không có route nào ở gateway; không chuỗi nào trong đặc tả bị ghi ra nhật ký.

**Đảm bảo thành công.** API `tra-cuu-ho-tich` và phiên bản `1.0.0` ở `DRAFT`, đặc tả lưu ở kho đối tượng (băm `sha256` ở CSDL), context-path `/ho-tich/tra-cuu-ho-tich/v1`, chưa công bố.

**Luồng chính.**

1. Bước 1 "Thông tin". Lan nhập mã `tra-cuu-ho-tich`, tên "Tra cứu thông tin hộ tịch", mô tả tiếng Việt 20…4.000 ký tự, HTTT cung cấp `HT-TUPHAP`, đơn vị chủ quản `SO-TUPHAP`, nhóm `ho-tich`, mức phân loại `RESTRICTED`, `containsPersonalData = true`, số phiên bản đầu `1.0.0`.
2. Hệ thống kiểm tra mã theo mẫu `^[a-z][a-z0-9-]{2,62}$` và chưa dùng kể cả mã đã xóa, HTTT `ACTIVE` ở PH-01, Lan thuộc đơn vị chủ quản, `stateSecret = false`; đồng thời đề xuất context-path `/ho-tich/tra-cuu-ho-tich/v1` và kiểm tra không trùng, không xung đột tiền tố (API-02-030, FR-02-024).
3. Bước 2 "Đặc tả". Lan bấm "Tải mẫu đặc tả" để tham khảo (API-02-019, FR-02-015), rồi chọn "Tải tệp" `tra-cuu-ho-tich.yaml`.
4. Hệ thống kiểm tra kích thước ≤ 10 MiB và kiểu nội dung theo nội dung tệp (chỉ YAML, JSON), quét mã độc, phân tích cú pháp bằng bộ phân tích an toàn (giới hạn alias YAML, độ sâu), gộp tham chiếu ngoại tuyến hợp lệ, tính `sha256`, lưu vào kho đối tượng (API-02-015).
5. Hệ thống liệt kê 6 thao tác tìm thấy và chạy kiểm tra không lưu (UC-02-06); Lan sửa lỗi nếu có rồi tiếp tục.
6. Bước 3 "Kiểm tra và xem trước". Hệ thống chạy lớp 1, lớp 2, quét bí mật (UC-02-06, 07) và phát hiện API trùng chức năng; Lan chỉ đi tiếp khi không còn lỗi mức `ERROR`.
7. Bước 4 "Backend và gói". Lan khai ít nhất một backend và một gói (UC-02-11, 12) hoặc bỏ qua để làm sau; API ở `DRAFT` không bị chặn.
8. Bước 5 "Rà soát". Hệ thống hiện bản xem trước mục danh mục; Lan bấm "Lưu nháp".
9. Hệ thống gọi API-02-014 kèm `Idempotency-Key`, tạo API và phiên bản `1.0.0` `DRAFT`, đặt `origin = OPENAPI`, ghi kiểm toán (mã API, HTTT, đơn vị, `dataClass`, băm đặc tả), phát EVT-02-01 và trả `201` kèm `Location`, `ETag`.

**Luồng thay thế.**

- **A1. (bước 3) Lan nạp bằng "Dán nội dung" hoặc "Nhập từ URL".** URL phải là `https`, nằm trong danh sách egress của tenant, chờ tối đa 15 giây, tối đa 3 lần chuyển hướng; bật `autoRefresh` thì hệ thống đặt lịch đồng bộ lại (UC-02-08). Quay lại bước 4.
- **A2. (bước 4) Đặc tả là Swagger 2.0 hoặc OpenAPI 3.0.** Hệ thống chuyển sang 3.1, ghi `x-datahub-converted-from`, báo các điểm không chuyển được; quay lại bước 5.
- **A3. (bước 8) Lan bấm "Lưu và gửi duyệt".** Hệ thống gộp bước 9 với UC-02-15 trong một giao dịch; nếu thiếu điều kiện, API vẫn được lưu `DRAFT` và hiện danh sách điều kiện còn thiếu (ERR-02-012).
- **A4. (sau bước 9) Lan sửa khi còn nháp.** Lan bấm "Sửa" ở UI-02-02, đổi mô tả hoặc thay đặc tả kèm `If-Match` (API-02-018, FR-02-014); phiên bản đã `PUBLISHED` chỉ cho sửa mô tả, thẻ, đầu mối, SLA, mô tả thao tác.
- **A5. Lan thoát giữa chừng.** Bản nháp của trình hướng dẫn giữ 7 ngày ở trình duyệt và máy chủ, không tạo API.

**Luồng ngoại lệ.**

- **E1. Mã API đã dùng (bước 2).** ERR-02-002 (409); "Mã tra-cuu-ho-tich đã được dùng (kể cả đối tượng đã xóa hoặc ngừng). Chọn mã khác." Quay lại bước 1.
- **E2. HTTT cung cấp không `ACTIVE` (bước 2).** ERR-02-004 (422); "HTTT {mã} chưa được kết nạp hoặc không ở trạng thái hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước." UC kết thúc.
- **E3. Dữ liệu thuộc bí mật nhà nước (bước 2).** ERR-02-016 (422); "Dữ liệu thuộc danh mục bí mật nhà nước không được công bố trên Datahub." UC kết thúc.
- **E4. Context-path trùng hoặc xung đột (bước 2).** ERR-02-019 (422); "Đường dẫn {đường dẫn} đã được dùng hoặc xung đột với {đường dẫn khác}." Quay lại bước 1.
- **E5. Đặc tả vượt kích thước (bước 4).** ERR-02-009 (413); "Đặc tả vượt 10 MiB. Rút gọn hoặc tách thành nhiều API." Quay lại bước 3.
- **E6. Đặc tả sai cú pháp (bước 4).** ERR-02-005 (422); "Đặc tả sai cú pháp ở dòng {n}, cột {m}: {mô tả}." Quay lại bước 3.
- **E7. URL không tải được (bước 4, nhánh A1).** ERR-02-010 (422); "Không tải được đặc tả từ địa chỉ này (địa chỉ không nằm trong danh sách cho phép hoặc không phản hồi)."
- **E8. Lan không thuộc đơn vị chủ quản (bước 2, A4).** ERR-02-014 (403); "Bạn không thuộc đơn vị chủ quản của HTTT này."
- **E9. Hai người sửa cùng lúc (A4).** ERR-02-015 (412); "Thông tin vừa được người khác thay đổi. Tải lại để xem." kèm nút "Xem khác biệt".

**Quy tắc áp dụng.** BR-02-001, 007, 014, 015, 021, 022, 028, 030, 032.

**Màn hình, API.** UI-02-02, 03; API-02-014, 015, 018, 019, 030 (kèm API-02-022 ở bước đặc tả).
:::

### 6.6. UC-02-06 · Kiểm tra đặc tả hai lớp và sửa lỗi

::: dac-ta
**Mục tiêu.** Chủ dịch vụ biết ngay đặc tả có đúng chuẩn OpenAPI 3.1 (lớp 1) và đạt quy ước nền tảng (lớp 2) hay chưa, sửa đúng vị trí, nhiều vòng nhanh, không phải lưu bản nháp trước.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan); công cụ CI của nhà thầu dùng cùng giao diện bằng token người dùng.

**Tác nhân phụ.** Không (bộ kiểm tra chạy trong PH-02).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-016, 017, 019.

**Truy vết.** REQ-02; quy trình Kết nạp HTTT → công bố dịch vụ; LGC-APIM-003.

**Tiền điều kiện.** Lan có `PERM-02-create`; phiên bản có đặc tả (đã nạp ở UC-02-05) hoặc đang gõ ở trình soạn thảo.

**Kích hoạt.** Trình soạn thảo ở UI-02-03 gọi kiểm tra sau 800 ms ngừng gõ; hoặc Lan bấm "Kiểm tra lại" ở UI-02-04; hoặc UC-02-15 chạy lại khi gửi duyệt.

**Đảm bảo tối thiểu.** Kiểm tra không lưu (API-02-022) không ghi gì vào CSDL và không lưu nội dung; kết quả đã sửa được đánh dấu `resolved` chứ không xóa.

**Đảm bảo thành công.** Kết quả kiểm tra hai lớp ghi cho đúng băm đặc tả; `summary` `{errors: 0, warnings: 3, infos: 1}`; `canContinue = true`.

**Luồng chính.**

1. Lan dán nội dung đặc tả vào trình soạn thảo ở bước 2 của UI-02-03; sau 800 ms hệ thống gọi API-02-022 (kiểm tra không lưu) và áp giới hạn 60 lần mỗi giờ mỗi người (`02.lint.max-per-hour`).
2. Hệ thống kiểm tra cú pháp YAML hoặc JSON và `openapi` là `3.1.x`, rồi lược đồ OpenAPI, `operationId` không trùng, tham số đường dẫn khớp khuôn, `$ref` giải được (lớp 1). Kết quả: 1 lỗi `OAS-REF-UNRESOLVED` ở `#/paths/~1ho-tich~1{soDinhDanh}/get/responses/200`.
3. Hệ thống chạy 15 luật lớp 2 trên cây đặc tả: 3 lỗi (thiếu mã lỗi `429` ở `getCivilRecord`, mô tả bằng tiếng Anh ở hai thao tác, thao tác `POST` thiếu `Idempotency-Key`) và 3 cảnh báo (thiếu `example`).
4. Giao diện hiện thẻ tổng "4 lỗi · 3 cảnh báo", danh sách theo mức và khung đặc tả tô sáng dòng lỗi; `canContinue = false`, nút "Tiếp tục" bị khóa.
5. Lan sửa tham chiếu, thêm mã lỗi, dịch mô tả, thêm tiêu đề; hệ thống kiểm tra lại sau mỗi lần ngừng gõ; lỗi đã sửa chuyển `resolved`.
6. Khi `errors = 0`, hệ thống đặt `canContinue = true`. Lan lưu phiên bản (UC-02-05 bước 9); hệ thống chạy lại kiểm tra trên đúng băm đã lưu, ghi kết quả hai lớp (`STANDARD`, `CONVENTION`), tóm tắt `{errors: 0, warnings: 3, infos: 1}`.

**Luồng thay thế.**

- **A1. (bước 6) Cảnh báo có lý do chính đáng.** Lan bấm "Chấp nhận cảnh báo" kèm lý do (ví dụ "thao tác trả tệp, không có ví dụ"); phát hiện chuyển `ACKNOWLEDGED`, người duyệt sẽ thấy lý do; luật mức `ERROR` không cho chấp nhận.
- **A2. (bước 1) Công cụ CI của nhà thầu.** CI gọi API-02-022 với `Accept: application/sarif+json` và nhận kết quả dạng SARIF để hiện trong quy trình CI.
- **A3. (bước 2) Đặc tả trên 5.000 thao tác.** Hệ thống kiểm tra theo lô, hiện tiến độ (tuân thủ FR-00-054) và trả kết quả khi xong (≤ 20 giây với đặc tả 10 MiB, NFR-02-003).
- **A4. (bước 3) Lớp 1 còn lỗi.** Hệ thống chỉ chạy các luật lớp 2 không phụ thuộc cấu trúc.

**Luồng ngoại lệ.**

- **E1. Còn lỗi lớp 1 khi gửi duyệt (UC-02-15).** ERR-02-006 (422); "Đặc tả còn {n} lỗi. Sửa các lỗi dưới đây rồi kiểm tra lại." hiện ở dải đầu UI-02-04.
- **E2. Còn lỗi lớp 2 mức `ERROR` khi gửi duyệt.** ERR-02-007 (422); "Đặc tả còn {n} lỗi theo quy ước nền tảng. Mở kết quả kiểm tra để xem hướng dẫn sửa."
- **E3. Đặc tả không đọc được (bước 2).** ERR-02-005 (422); "Đặc tả sai cú pháp ở dòng {n}, cột {m}."
- **E4. Vượt số lần kiểm tra mỗi giờ (bước 1).** ERR-02-036 (429); "Đã kiểm tra quá nhiều lần. Thử lại sau {n} giây."
- **E5. Đặc tả quá phức tạp để kiểm tra nhanh (bước 1).** ERR-02-003 (400); "Đặc tả quá phức tạp để kiểm tra nhanh. Lưu bản nháp để kiểm tra nền."
- **E6. Đang có lần kiểm tra khác cùng đặc tả (bước 6).** ERR-02-035 (409); "Đang kiểm tra, vui lòng chờ."
- **E7. Chấp nhận cảnh báo không nêu lý do (A1).** ERR-02-041 (400); "Cần nêu lý do chấp nhận cảnh báo."

**Quy tắc áp dụng.** BR-02-001, 002, 014, 015, 016.

**Màn hình, API.** UI-02-03, 04; API-02-020, 021, 022, 092 (chấp nhận cảnh báo ở luồng thay thế A1).
:::

### 6.7. UC-02-07 · Xử lý phát hiện bí mật, dữ liệu cá nhân thật và API trùng chức năng

::: dac-ta
**Mục tiêu.** Đặc tả không bao giờ mang khóa, token, mật khẩu hay số định danh thật ra danh mục công khai, và người duyệt thấy trước các API gần giống để quyết định có gom về một dịch vụ dùng chung hay không.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan); `ROLE-SECURITY_OFFICER` (Dũng) khi có nghi lộ lọt.

**Tác nhân phụ.** `ROLE-CATALOG_APPROVER` (Minh) quyết định về API trùng ở UC-02-16; trung tâm thông báo (FR-00-060).

**Mức ưu tiên.** M (quét bí mật), S (phát hiện trùng) · MVP.

**FR hiện thực.** FR-02-018, 020.

**Truy vết.** REQ-02; quy trình Kết nạp HTTT → công bố dịch vụ; CMP-LAW-05, CMP-LAW-10; SEC-32 (không có LGC, năng lực mới).

**Tiền điều kiện.** Phiên bản có đặc tả; bộ quét bí mật khả dụng; với phát hiện trùng, đặc tả đã đạt lớp 1.

**Kích hoạt.** Hệ thống quét cùng lúc với kiểm tra lớp 1, 2; luôn quét lại khi gửi duyệt và khi duyệt; phát hiện trùng chạy ở bước 3 của UI-02-03, khi gửi duyệt và khi mở màn duyệt UI-02-10.

**Đảm bảo tối thiểu.** Chuỗi khớp mẫu bí mật không bao giờ được ghi vào kết quả, nhật ký, vết, sự kiện; chỉ ghi vị trí, mã mẫu và 4 ký tự cuối đã che. Khi bộ quét lỗi, hệ thống không cho qua.

**Đảm bảo thành công.** Phiên bản không còn phát hiện `SECRET` mức `ERROR` mới đi tiếp; quyết định về API gần giống gắn vào yêu cầu duyệt.

**Luồng chính.**

1. Lan nạp đặc tả có phần ví dụ chứa `Authorization: Bearer eyJhbGciOi…` và một số định danh 12 chữ số hợp lệ cấu trúc.
2. Hệ thống quét mọi giá trị chuỗi (`example`, `examples`, `default`, `enum`, `description`, `servers`, `x-*`) với chín mẫu `SCAN-02-01…09` và loại giá trị giữ chỗ hợp lệ như `{token}`, `<API_KEY>`, `***`.
3. Hệ thống ghi hai phát hiện `ERROR` lớp `SECRET` (`SCAN-02-04` và `SCAN-02-07`) kèm vị trí và 4 ký tự cuối đã che; giao diện nhảy tới dòng lỗi ở UI-02-04.
4. Hệ thống chặn gửi duyệt, duyệt và công bố phiên bản này (BR-02-015) và gửi cảnh báo qua trung tâm thông báo cho Lan; vì mẫu là token có dạng còn hiệu lực, hệ thống báo thêm Dũng để xử lý như nghi lộ lọt.
5. Dũng đối chiếu với nhật ký phát hành khóa, xác nhận token là giá trị thật của hệ thống thử nghiệm và yêu cầu thu hồi ở nơi cấp.
6. Lan thay hai giá trị bằng giữ chỗ `<TOKEN>` và `012345678901` thuộc dải giữ chỗ, bấm "Kiểm tra lại"; phát hiện chuyển `RESOLVED`.
7. Ở bước 3 của UI-02-03, hệ thống chuẩn hóa các khuôn (phương thức, đường dẫn), so với mọi API còn hiệu lực theo ba độ đo (tỷ lệ khuôn trùng, độ tương đồng mô tả, độ trùng tên trường phản hồi) và hiện tối đa 5 API có điểm từ `02.duplicate.threshold` (0,8): `tra-cuu-giay-khai-sinh` của Sở Y tế, điểm 0,84, lý do "khuôn trùng 4/6, trường chung `hoTen`, `ngaySinh`".
8. Lan ghi chú vào hồ sơ lý do `tra-cuu-ho-tich` phục vụ cấp bản sao có xác thực, khác `tra-cuu-giay-khai-sinh`; hệ thống lưu ghi chú và vẫn cho gửi duyệt (chỉ cảnh báo).
9. Ở UC-02-16, Minh thấy danh sách API gần giống trên màn duyệt và chọn "Khác nhau, vẫn công bố" kèm lý do; hệ thống ghi API được so, điểm, quyết định, lý do vào kiểm toán.

**Luồng thay thế.**

- **A1. (bước 3) Phát hiện nhầm.** Lan bấm "Đánh dấu không phải bí mật" kèm lý do cho đúng giá trị đó (ví dụ mã tham chiếu mẫu); phát hiện chuyển `ACKNOWLEDGED` chỉ khi Dũng xác nhận (`PERM-02-operate`); chưa xác nhận thì vẫn chặn.
- **A2. (bước 7) Lan chọn "API này là phiên bản thay thế của API khác".** Hệ thống bỏ cảnh báo trùng với API đó.
- **A3. (bước 9) Minh chọn "Gom về API có sẵn".** Phiên bản được trả về `DRAFT` kèm ý kiến; Lan cân nhắc nạp lại như phiên bản của API sẵn có.

**Luồng ngoại lệ.**

- **E1. Phát hiện bí mật (bước 3).** ERR-02-008 (422); "Đặc tả có giá trị giống khóa hoặc dữ liệu cá nhân thật tại {vị trí}. Thay bằng giá trị giữ chỗ rồi kiểm tra lại." Quay lại bước 6.
- **E2. Bộ quét lỗi (bước 2).** ERR-02-034 (503); "Chưa quét được bí mật, tạm không gửi duyệt được." Không bao giờ cho qua khi quét lỗi; Lan thử lại sau.
- **E3. Đánh dấu không phải bí mật mà thiếu lý do (A1).** ERR-02-041 (400); "Cần nêu lý do."
- **E4. Bộ so sánh trùng chưa sẵn sàng (bước 7).** Hệ thống ghi `skipped`, không chặn công bố; nhật ký ghi ERR-02-034.
- **E5. Không có API gần giống (bước 7).** Danh sách rỗng, không cảnh báo; không phải lỗi.

**Quy tắc áp dụng.** BR-02-007, 008, 015.

**Màn hình, API.** UI-02-03 (bước 3), 04, 10; API-02-020, 021, 023, 093 (đánh dấu không phải bí mật ở A1), 094 (SO xác nhận).
:::

### 6.8. UC-02-08 · Đồng bộ lại đặc tả từ URL nguồn

::: dac-ta
**Mục tiêu.** Đặc tả trong danh mục không lệch khỏi hệ thống thật khi chủ dịch vụ nạp từ URL: hệ thống định kỳ kiểm tra, báo khi nguồn đổi và để chủ dịch vụ quyết định áp dụng hay không.

**Tác nhân chính.** Lịch của PH-02; `ROLE-SERVICE_OWNER` (Lan) khi bấm "Đồng bộ ngay" hoặc quyết định áp dụng.

**Tác nhân phụ.** HTTT nguồn `HT-TUPHAP` (máy chủ phục vụ URL đặc tả), trung tâm thông báo.

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-02-012.

**Truy vết.** REQ-02; quy trình Công bố dịch vụ; không có LGC (SRS cũ FR-02-003 bước 4).

**Tiền điều kiện.** Đặc tả có `source = URL` và `autoRefresh = true` (ví dụ `https://tuphap.t68.gov.vn/v3/api-docs`); phiên bản không `RETIRED`.

**Kích hoạt.** Lịch mỗi `02.spec.url-refresh-hours` giờ (mặc định 24); hoặc Lan bấm "Đồng bộ ngay" ở tab Phiên bản (UI-02-02).

**Đảm bảo tối thiểu.** Đặc tả đang dùng của phiên bản không bao giờ bị thay âm thầm; bản tải về chỉ được lưu như "đề xuất cập nhật".

**Đảm bảo thành công.** `lastCheckedAt` được cập nhật; nếu nguồn đổi thì có một đề xuất cập nhật kèm khác biệt chờ Lan.

**Luồng chính.**

1. Lịch 02:00 kích hoạt; hệ thống tải lại URL với các kiểm tra như UC-02-05 bước 4 (`https`, nằm trong egress, chờ 15 giây).
2. Hệ thống chuẩn hóa nội dung (bỏ khoảng trắng, sắp khóa) và tính băm; so với băm đang lưu.
3. Băm giống nhau thì hệ thống cập nhật `lastCheckedAt` và kết thúc, không ghi kiểm toán.
4. Băm khác nhau: hệ thống lưu bản tải về thành đề xuất cập nhật, tính khác biệt và phân loại phá vỡ như UC-02-18; kết quả `changed`, `breakingCount = 2`.
5. Hệ thống phát EVT-02-07 và gửi Lan thông báo "Đặc tả nguồn của tra-cuu-ho-tich 1.0.0 đã thay đổi; có 2 thay đổi phá vỡ."
6. Phiên bản đang `DRAFT`: Lan mở đề xuất, xem khác biệt và bấm "Áp dụng"; hệ thống thay đặc tả, đánh dấu kết quả kiểm tra cũ lỗi thời và chạy lại UC-02-06.

**Luồng thay thế.**

- **A1. (bước 6) Phiên bản đã khóa từ `PENDING` trở đi.** Hệ thống chỉ cảnh báo, hợp đồng đã duyệt không đổi, và đề nghị Lan tạo phiên bản mới (UC-02-18).
- **A2. (bước 6) Lan bấm "Bỏ qua".** Đề xuất cập nhật được đóng; lần đồng bộ sau so với đặc tả đang dùng.
- **A3. (bước 1) Nguồn không truy cập được.** Hệ thống tăng bộ đếm lỗi; sau 3 lần liên tiếp ghi cảnh báo "Không đọc được đặc tả nguồn" cho Lan và tạm ngừng đồng bộ tự động.

**Luồng ngoại lệ.**

- **E1. URL bị chặn bởi egress hoặc trả lỗi (khi Lan bấm tay).** ERR-02-010 (422); "Không tải được đặc tả từ địa chỉ này."
- **E2. Đang có lần đồng bộ chạy.** ERR-02-035 (409); "Đang đồng bộ, vui lòng chờ."
- **E3. Phiên bản `RETIRED`.** ERR-02-011 (409); "Không thực hiện được ở trạng thái RETIRED hiện tại."

**Quy tắc áp dụng.** BR-02-001, 014.

**Màn hình, API.** UI-02-02 (tab Phiên bản); API-02-016, 095 (tiến độ tác vụ).
:::

### 6.9. UC-02-09 · Tự đăng ký API từ luồng REST của PH-04

::: dac-ta
**Mục tiêu.** Mọi luồng có điểm vào REST đã phát hành ở PH-04 tự có mặt trong danh mục như một API ở bản nháp, đi cùng quy trình công bố như mọi API, để danh mục không bỏ sót dịch vụ nào.

**Tác nhân chính.** PH-04 `dh-integration` (token dịch vụ, scope `catalog:flow-sync`).

**Tác nhân phụ.** `ROLE-SERVICE_OWNER` (Lan) nhận việc hoàn thiện; PH-01 (HTTT sở hữu luồng); trung tâm thông báo.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-013 (và 014 khi Lan hoàn thiện mô tả).

**Truy vết.** REQ-02, REQ-04; quy trình Thiết kế, phát hành luồng; LGC-BUS-028.

**Tiền điều kiện.** Luồng `ho-tich-khai-sinh` phiên bản 4 có `rest` DSL và đã được duyệt phát hành ở PH-04; HTTT sở hữu luồng `HT-TUPHAP` `ACTIVE`.

**Kích hoạt.** PH-04 phát EVT-04-04 (`version.approved`) rồi EVT-04-07 (`deployment.status-changed` sang `SYNCED`) cho luồng có điểm vào REST.

**Đảm bảo tối thiểu.** Sự kiện không mất (nằm trong hàng đợi chờ xử lý khi PH-02 lỗi); API sinh từ luồng không bao giờ tự công bố hay tự ngừng.

**Đảm bảo thành công.** API `ho-tich-khai-sinh` có `origin = FLOW`, phiên bản `DRAFT` với backend `FLOW`, phần hợp đồng khóa không sửa tay, Lan có việc hoàn thiện.

**Luồng chính.**

1. Hệ thống nhận sự kiện kèm `flowCode`, `versionNo`, môi trường, `restOperations[]`, HTTT sở hữu và tra `flowRef` trong danh mục; chưa có.
2. Hệ thống tạo API mới: `origin = FLOW`, `apiCode = ho-tich-khai-sinh`, `ownerOrgCode = SO-TUPHAP` theo HTTT sở hữu luồng, `dataClass` lấy từ nhãn của luồng (mặc định `INTERNAL`), `visibility = TENANT`.
3. Hệ thống đọc đặc tả OpenAPI do PH-04 sinh qua API nội bộ và chạy kiểm tra như UC-02-06; kết quả `ERROR` không chặn việc tạo nhưng chặn công bố.
4. Hệ thống tạo phiên bản `DRAFT` với backend loại `FLOW` trỏ tới điểm vào của luồng ở môi trường tương ứng.
5. Hệ thống gắn nhãn "Sinh từ luồng", khóa phần hợp đồng (đường dẫn, lược đồ) không cho sửa tay (BR-02-030), chỉ cho sửa mô tả, phân loại, gói, SLA.
6. Hệ thống tạo việc cho Lan: "API sinh từ luồng ho-tich-khai-sinh cần hoàn thiện mô tả và gói, rồi gửi duyệt."; phát EVT-02-01, EVT-02-02; ghi kiểm toán với chủ thể là tài khoản dịch vụ PH-04.
7. Về sau luồng đổi hợp đồng ở phiên bản 5: hệ thống tạo phiên bản API tương ứng theo số chính; khi luồng bị gỡ, hệ thống đánh dấu phiên bản "mất backend" và báo Lan, không tự ngừng.

**Luồng thay thế.**

- **A1. (bước 4) Luồng chỉ phát hành ở TEST.** Hệ thống tạo API nháp nhưng không cho gửi duyệt cho tới khi luồng có phiên bản ở môi trường thật.
- **A2. (bước 1) API đã tồn tại với `flowRef` này.** Hệ thống chỉ cập nhật phiên bản `DRAFT` có sẵn hoặc tạo phiên bản mới, không tạo API thứ hai.

**Luồng ngoại lệ.**

- **E1. Mã luồng trùng một API nhập tay có sẵn (bước 2).** ERR-02-002 (409) ghi nhật ký; hệ thống tạo việc cho TA: "API {mã} đã có, chọn Liên kết với luồng hoặc đổi mã."
- **E2. Không đọc được đặc tả từ PH-04 (bước 3).** ERR-02-034 (503); thử lại 3 lần lùi mũ rồi đưa vào hàng chờ, cảnh báo TO ở UI-02-17.
- **E3. Luồng chưa có HTTT sở hữu (bước 2).** ERR-02-004 (422); sự kiện vào hàng "chờ xử lý" (`flowSyncStatus = PENDING_OWNER`), TA nhận việc gán HTTT.
- **E4. Lan sửa phần hợp đồng của API sinh từ luồng (sau bước 6).** ERR-02-011 (409); "Phần hợp đồng của API này sinh từ luồng, hãy sửa ở PH-04."

**Quy tắc áp dụng.** BR-02-001, 023, 030.

**Màn hình, API.** UI-02-02 (nhãn "Sinh từ luồng"); API-02-017 (nội bộ); sự kiện EVT-04-04, EVT-04-07.
:::

### 6.10. UC-02-10 · Sinh khung route cho PH-04 từ đặc tả

::: dac-ta
**Mục tiêu.** Khi API chưa có backend REST sẵn, chủ dịch vụ dựng được khung luồng ở PH-04 từ chính đặc tả, mỗi thao tác một route theo khung chín chặng chuẩn, để kỹ sư chỉ điền phần logic riêng và không thể "quên" kiểm quyền, ghi vết, xử lý lỗi.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan) khởi tạo; `ROLE-INTEGRATION_ENGINEER` (An) hoàn thiện ở PH-04.

**Tác nhân phụ.** PH-04 (tạo luồng, sinh `rest` DSL, phát hành), PH-05 (kết nối đích, nếu có).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-026.

**Truy vết.** REQ-02, REQ-04; quy trình Thiết kế, phát hành luồng; PH-04 FR-04-003 (nguồn `API_SPEC`); không có LGC (SRS cũ FR-02-010).

**Tiền điều kiện.** Phiên bản `tra-cuu-ho-tich 1.0.0` ở `DRAFT` và đạt lớp 1; Lan có quyền ở không gian làm việc `ws-tuphap` của PH-04; PH-04 khả dụng.

**Kích hoạt.** Lan bấm "Tạo luồng từ API này" ở tab Backend của UI-02-02.

**Đảm bảo tối thiểu.** PH-02 không sinh logic nghiệp vụ (BR-02-010); nếu PH-04 lỗi, vòng đời API vẫn tiếp tục được, chỉ chưa gửi duyệt được vì thiếu backend `ACTIVE`.

**Đảm bảo thành công.** Luồng nháp `tra-cuu-ho-tich` có ở PH-04 với 6 route chín chặng; backend `FLOW` ở `PLACEHOLDER` trong PH-02; An nhận liên kết mở trình thiết kế.

**Luồng chính.**

1. Lan chọn không gian làm việc `ws-tuphap` và mã luồng (mặc định bằng mã API); hệ thống kiểm tra quyền của Lan ở không gian đó qua PH-04 và mã luồng chưa dùng.
2. Hệ thống gọi PH-04 tạo luồng với `origin = API_SPEC`, `apiRef` là API này, kèm đầu mối và nhãn phân loại dữ liệu (API-02-032); trả `202` kèm `operationId`.
3. PH-04 đọc đặc tả đã gộp tham chiếu từ PH-02 (API-02-007, scope `catalog:flow-sync`), sinh `rest` DSL: mỗi thao tác một route `direct:{operationId}` theo khung chín chặng, lược đồ yêu cầu và phản hồi gắn vào chặng kiểm tra lược đồ, phạm vi quyền lấy từ khai báo `security` của thao tác.
4. PH-04 trả mã luồng, `designerUrl` và `pendingFill = 3` (ba chỗ đích đến không suy được, đánh dấu "Cần điền").
5. Hệ thống tạo backend loại `FLOW` ở trạng thái `PLACEHOLDER` trỏ tới luồng; backend này chưa tính là backend `ACTIVE`.
6. Hệ thống phát EVT-02-02 (`changedFields = backends`), ghi kiểm toán và hiện cho Lan liên kết "Mở trình thiết kế".
7. An mở trình thiết kế, điền ba chỗ còn thiếu và phát hành luồng; PH-04 phát EVT-04-07; PH-02 chuyển backend sang `ACTIVE` (UC-02-09 xử lý phía sự kiện).

**Luồng thay thế.**

- **A1. (bước 2) PH-04 không khả dụng.** Yêu cầu vào hàng chờ; Lan thấy "Chưa tạo được luồng vì phân hệ Tích hợp chưa sẵn sàng. Yêu cầu đã được xếp hàng."; vòng đời API vẫn tiếp tục nhưng chưa gửi duyệt được (ERR-02-021).
- **A2. (bước 6) Lan để kỹ sư khác làm.** Lan gửi liên kết cho An; An cần có quyền ở không gian làm việc.

**Luồng ngoại lệ.**

- **E1. Mã luồng đã dùng (bước 1).** ERR-02-002 (409); "Mã luồng {mã} đã được dùng. Chọn mã khác." Quay lại bước 1.
- **E2. Đặc tả chưa đạt lớp 1 (bước 1).** ERR-02-006 (422); "Đặc tả còn lỗi, chưa sinh khung luồng được."
- **E3. Lan không có quyền ở không gian làm việc (bước 1).** ERR-02-014 (403); "Bạn không có quyền ở không gian làm việc này."
- **E4. PH-04 không khả dụng (bước 2).** ERR-02-034 (503); "Chưa tạo được luồng vì phân hệ Tích hợp chưa sẵn sàng. Yêu cầu đã được xếp hàng."
- **E5. Gửi duyệt khi backend `FLOW` còn `PLACEHOLDER`.** ERR-02-021 (422); "Chưa đủ điều kiện: phiên bản chưa có backend hoạt động." (UC-02-15 bước 3).

**Quy tắc áp dụng.** BR-02-010, 024.

**Màn hình, API.** UI-02-02 (tab Backend); API-02-032, API-02-007, API-02-095 (tiến độ tác vụ).
:::

### 6.11. UC-02-11 · Khai báo backend, cân bằng tải và theo dõi sức khỏe

::: dac-ta
**Mục tiêu.** Chủ dịch vụ chỉ cho gateway biết lời gọi API đi tới đâu (một hay nhiều backend, hoặc một luồng), gateway chia tải và loại backend hỏng đúng cấu hình; vận hành thấy backend nào đang hỏng và từ lúc nào.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan) khai báo; `ROLE-TENANT_OPERATOR` (Chi) theo dõi.

**Tác nhân phụ.** PH-05 (kết nối HTTP của HTTT cung cấp), PH-04 (xác minh luồng), PH-03 và APISIX (trạng thái nút), PH-13 (tỷ lệ lỗi, độ trễ).

**Mức ưu tiên.** M (khai báo, cân bằng tải), S (xem sức khỏe) · MVP.

**FR hiện thực.** FR-02-022, 023, 025.

**Truy vết.** REQ-02, REQ-03, REQ-13; quy trình Công bố dịch vụ; LGC-APIM-002; LGC-APIM-018.

**Tiền điều kiện.** Phiên bản `DRAFT` (khai báo); với loại `SYSTEM`, kết nối `ndxp-ho-tich` (loại `oauth2-client`) của `HT-TUPHAP` đã được cấp cho API ở PH-05 và môi trường TEST đã bật; với xem sức khỏe, phiên bản `PUBLISHED`, `SUSPENDED` hoặc `DEPRECATED`.

**Kích hoạt.** Lan bấm "+ Thêm backend" ở tab Backend của UI-02-02 (hoặc bước 4 của UI-02-03); Chi mở tab Backend của phiên bản đã công bố.

**Đảm bảo tối thiểu.** Cấu hình lưu ở PH-02 chưa ảnh hưởng gateway cho tới khi công bố; phiên bản đã `PUBLISHED` không bao giờ đổi backend trực tiếp mà phải qua duyệt.

**Đảm bảo thành công.** Phiên bản có hai backend `ACTIVE` kèm cấu hình chia tải và kiểm tra sức khỏe; Chi thấy trạng thái từng nút trong khoảng làm mới 30 giây.

**Luồng chính.**

1. Lan chọn loại "HTTT cung cấp" (`SYSTEM`) và chọn kết nối `ndxp-ho-tich`.
2. Hệ thống kiểm tra kết nối tồn tại, cùng HTTT `HT-TUPHAP`, môi trường tương ứng đã bật; kiểm tra đích theo BR-02-023: TLS tối thiểu 1.2, địa chỉ nằm trong danh sách đích cho phép của tenant, không trỏ tới địa chỉ nội bộ control plane, loopback, link-local hay dịch vụ siêu dữ liệu đám mây.
3. Hệ thống đặt trọng số mặc định 100, lưu backend `ACTIVE`, đánh dấu `configDirty` (API-02-026, 027) và trả `201`.
4. Lan thêm backend thứ hai `ho-tich-b` trọng số 50 cho cùng phiên bản.
5. Lan mở khối "Cân bằng tải và sức khỏe" (API-02-028): `balancer = ROUND_ROBIN`, `readTimeoutMs = 30000`, `retries = 1`, kiểm tra chủ động đường dẫn `/health` mỗi 10 giây, loại khỏi vòng chia tải sau 3 lần lỗi liên tiếp.
6. Hệ thống kiểm tra miền giá trị, thời gian chờ không vượt `02.backend.max-timeout-ms`, `retries` chỉ áp cho `GET`, `HEAD`, `PUT`, `DELETE` (`POST` chỉ khi thao tác khai `x-datahub-idempotent: true`), đường dẫn sức khỏe nằm trong danh sách được phép của backend; lưu và ghi kiểm toán giá trị trước, sau.
7. Về sau, khi API đã công bố, Chi mở tab Backend. Hệ thống gọi PH-03 và PH-13 (API-02-031), ghép với cấu hình và hiện: `ho-tich-a` `HEALTHY`, `ho-tich-b` `UNHEALTHY` từ 09:12 với tỷ lệ lỗi 18% và p95 4.200 ms trong 1 giờ; trạng thái tổng `DEGRADED`.
8. Khi không còn backend khỏe, trạng thái tổng là `DOWN`; hệ thống hiện dải "Không còn backend nào đáp ứng" và đưa API vào thẻ "Cần chú ý" ở UI-02-01.

**Luồng thay thế.**

- **A1. (bước 1) Backend loại luồng.** Lan chọn "Luồng tích hợp" và tên điểm vào; hệ thống hỏi PH-04 xác minh luồng tồn tại, cùng tenant, có điểm vào REST; quay lại bước 3.
- **A2. (bước 3) Lan chọn "Dùng cho môi trường kiểm thử TEST".** Backend chỉ áp ở TEST; khi sang môi trường thật phải khai riêng.
- **A3. (bước 5) Lan chọn "Dùng mặc định nền tảng".** Hệ thống áp bộ giá trị mặc định (`ROUND_ROBIN`, chờ kết nối 3.000 ms, chờ phản hồi 30.000 ms, thử lại 1 lần).
- **A4. (bước 3) Phiên bản đã `PUBLISHED`.** Thêm hoặc đổi backend tạo yêu cầu `BACKEND_CHANGE` cần CA duyệt (UC-02-16) trước khi đẩy xuống gateway.
- **A5. (bước 7) PH-13 không khả dụng.** Hệ thống hiện trạng thái từ PH-03 kèm nhãn "Thiếu số liệu độ trễ".

**Luồng ngoại lệ.**

- **E1. Kết nối hoặc luồng không tồn tại, khác HTTT (bước 2).** ERR-02-020 (422); "Backend không hợp lệ: {lý do}."
- **E2. Đích ngoài danh sách cho phép (bước 2).** ERR-02-020 (422); "Đích {máy chủ} chưa có trong danh sách đích cho phép. Đề nghị quản trị tenant bổ sung."
- **E3. Vượt số backend tối đa mỗi phiên bản (bước 4).** ERR-02-040 (422); "Vượt trần {n} do nền tảng đặt."
- **E4. Phiên bản đang `PENDING` (bước 3, 6).** ERR-02-038 (409); "Phiên bản đang chờ duyệt, không sửa được. Rút lại yêu cầu duyệt trước."
- **E5. Thời gian chờ vượt trần của tỉnh (bước 6).** ERR-02-040 (422); "Thời gian chờ vượt trần {n} ms của tỉnh."
- **E6. Thử lại cho `POST` chưa khai lặp lại được (bước 6).** ERR-02-003 (400); "Không thử lại tự động cho thao tác ghi chưa khai là lặp lại được."
- **E7. PH-03 không khả dụng (bước 7).** ERR-02-034 (503); "Chưa lấy được trạng thái từ cổng API. Thử lại sau." Hệ thống hiện lần cuối đã biết kèm thời điểm.
- **E8. Phiên bản chưa công bố (bước 7).** ERR-02-011 (409); "Phiên bản chưa công bố nên chưa có số liệu sức khỏe."

**Quy tắc áp dụng.** BR-02-023, 024, 028.

**Màn hình, API.** UI-02-01, 02 (tab Backend), 03 (bước 4); API-02-026, 027, 028, 029, 031.
:::

### 6.12. UC-02-12 · Tạo gói sử dụng: điều kiện, kiểu xác thực, hạn mức

::: dac-ta
**Mục tiêu.** Chủ dịch vụ tạo một gói cho phiên bản API: ai được xin, tự duyệt hay duyệt tay, xác thực bằng gì, được gọi nhanh đến đâu và những thao tác nào; hệ thống chặn kiểu xác thực yếu cho dữ liệu nhạy cảm.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan).

**Tác nhân phụ.** PH-01 (kiểm tra HTTT được xin), PH-12 (realm Keycloak, CA HTTT của OpenBao hỗ trợ `private_key_jwt`, `tls_client_auth`), PH-03 (thực thi hạn mức, chỉ nhận khai báo sau khi công bố).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-027, 028, 029.

**Truy vết.** REQ-02, REQ-03; quy trình Công bố dịch vụ; LGC-APIM-009; LGC-APIM-010; LGC-APIM-011 (LGC-APIM-012…015 do PH-03 làm chính, PH-02 chỉ khai báo).

**Tiền điều kiện.** Lan có `PERM-02-create` với API của `SO-TUPHAP`; phiên bản `tra-cuu-ho-tich 1.0.0` ở `DRAFT` và đặc tả đạt lớp 1; chưa vượt 10 gói mỗi phiên bản.

**Kích hoạt.** Lan bấm "+ Tạo gói" ở tab Gói sử dụng của UI-02-02 hoặc ở UI-02-06, mở UI-02-07.

**Đảm bảo tối thiểu.** Gói `STAGING` chưa nhận đăng ký, chưa có cấu hình ở gateway; mã gói bất biến và không dùng lại.

**Đảm bảo thành công.** Gói `tich-hop-bao-mat` ở `STAGING` với `authType = OAUTH2_MTLS`, hạn mức và thao tác cho phép đã khai, sẵn sàng gửi duyệt (UC-02-13).

**Luồng chính.**

1. Lan chọn phiên bản `1.0.0`, nhập mã gói `tich-hop-bao-mat`, tên, mô tả và điều khoản sử dụng.
2. Hệ thống kiểm tra mã theo mẫu, duy nhất trong phiên bản và chưa từng dùng kể cả gói đã đóng, Lan thuộc tổ chức chủ quản.
3. Lan chọn đối tượng được xin là "Danh sách HTTT cụ thể" gồm `HT-MOTCUA`, `HT-YTE`; hệ thống kiểm tra từng HTTT tồn tại ở PH-01.
4. Lan chọn "Duyệt tay" vì API mức `RESTRICTED` không cho tự duyệt (`02.subscription.auto-approve.max-class` mặc định `INTERNAL`), thời hạn mỗi đăng ký 12 tháng, đơn giá thông tin 0 đồng; hệ thống tạo gói `STAGING` (API-02-033, 034), phát EVT-02-08 và chuyển sang phần "Bảo mật".
5. Hệ thống liệt kê kiểu xác thực và đánh dấu kiểu bị cấm với mức `RESTRICTED` (chỉ `OAUTH2_PKJWT`, `OAUTH2_MTLS` được phép). Lan chọn `OAUTH2_MTLS`.
6. Hệ thống xác nhận tenant đã có CA HTTT và realm cấu hình `tls_client_auth`, sinh khuôn phạm vi `api:tra-cuu-ho-tich:tich-hop-bao-mat` và phạm vi từng thao tác từ khai báo `security` của đặc tả, rồi lưu kiểu xác thực (API-02-036).
7. Ở phần "Hạn mức và đường dẫn", hệ thống đề xuất mặc định cho `RESTRICTED`: 10 lượt mỗi giây, 300 lượt mỗi phút, 20.000 lượt mỗi ngày. Lan giữ giá trị, chọn thao tác cho phép `getCivilRecord`, `searchCivilRecords` và thêm mẫu cấm `/admin/*`.
8. Hệ thống kiểm tra thứ tự hợp lý (giây, phút, giờ, ngày, tháng), không vượt trần tenant, mỗi `operationId` có trong đặc tả; so hạn mức giờ của gói với hạn mức giờ cam kết SLA, lớn hơn thì cảnh báo "Gói cho phép nhiều hơn năng lực đã cam kết". Lan lưu; gói ở `STAGING` chờ công bố.

**Luồng thay thế.**

- **A1. (bước 1) Lan bấm "Tạo từ mẫu gói".** Hệ thống điền sẵn bộ ba `cong-khai`, `tich-hop-noi-bo`, `tich-hop-bao-mat` cho Lan chỉnh.
- **A2. (bước 5) API `danh-muc-dan-toc` mức `PUBLIC` chọn `KEYLESS`.** Hệ thống hiện cảnh báo "Mọi người gọi được API này không cần danh tính" và buộc tích xác nhận; `KEYLESS` chỉ hợp lệ khi mức hiển thị cũng là `PUBLIC` và chịu giới hạn tần suất theo IP ở PH-03.
- **A3. (bước 5) Giai đoạn chuyển đổi.** Với dữ liệu `PUBLIC`, `INTERNAL`, tenant được dùng `OAUTH2_SECRET` hoặc `API_KEY` với bí mật ≥ 256 bit, hạn ≤ 180 ngày; gói hiện nhãn "Giai đoạn chuyển đổi".
- **A4. (bước 7) Lan chọn "Không giới hạn" cho hạn mức tháng.** Chỉ chấp nhận với `PUBLIC`, `INTERNAL`; còn lại bắt buộc có hạn mức ngày.
- **A5. (sau bước 8) Gói đã `PUBLISHED`.** Chỉ cho nâng hạn mức, thêm thao tác, sửa mô tả (BR-02-017); muốn hạ hạn mức hoặc đổi xác thực thì tạo gói mới và ngừng khuyến nghị gói cũ (UC-02-14).

**Luồng ngoại lệ.**

- **E1. Mã gói đã dùng (bước 2).** ERR-02-002 (409); "Mã gói {mã} đã được dùng. Chọn mã khác."
- **E2. Vượt số gói tối đa (bước 1).** ERR-02-040 (422); "Phiên bản đã đạt số gói tối đa ({n})."
- **E3. HTTT được xin không tồn tại ở PH-01 (bước 3).** ERR-02-026 (422); "HTTT {mã} chưa được kết nạp hoặc không hoạt động."
- **E4. Tự duyệt với dữ liệu mức cao (bước 4).** ERR-02-003 (400); "Dữ liệu mức {mức} không cho tự duyệt đăng ký."
- **E5. Kiểu xác thực không hợp mức phân loại (bước 5).** ERR-02-022 (422); "Dữ liệu mức {mức} yêu cầu xác thực {kiểu tối thiểu}. Chọn kiểu mạnh hơn." Quay lại bước 5.
- **E6. Realm hoặc CA chưa sẵn sàng (bước 6).** ERR-02-034 (503); "Tỉnh chưa bật xác thực {kiểu}. Liên hệ quản trị tenant."
- **E7. Hạn mức sai thứ tự (bước 8).** ERR-02-023 (422); "Hạn mức không hợp lý: {mô tả}."
- **E8. Thao tác không có trong đặc tả (bước 7).** ERR-02-037 (422); "Thao tác {operationId} không có trong đặc tả."
- **E9. Hạn mức vượt trần tenant (bước 8).** ERR-02-040 (422); "Hạn mức vượt trần {giá trị} của tỉnh."
- **E10. Phiên bản `PENDING` hoặc `RETIRED` (bước 1).** ERR-02-038 (409) hoặc ERR-02-011 (409); "Phiên bản đang chờ duyệt, không sửa được. Rút lại yêu cầu duyệt trước."
- **E11. Hạ hạn mức gói đã công bố (A5).** ERR-02-011 (409); "Gói đã công bố không hạ hạn mức. Tạo gói mới và ngừng khuyến nghị gói này."

**Quy tắc áp dụng.** BR-02-016, 017, 021, 024, 026, 028, 032, 040.

**Màn hình, API.** UI-02-06, 07; API-02-033, 034, 035, 036, 096 (danh sách gói toàn tenant).
:::

### 6.13. UC-02-13 · Công bố gói sử dụng

::: dac-ta
**Mục tiêu.** Gói bắt đầu nhận đăng ký sử dụng sau khi người có thẩm quyền rà soát điều kiện truy cập, kiểu xác thực và hạn mức; việc rà soát tuân theo nguyên tắc bốn mắt.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan) gửi; `ROLE-CATALOG_APPROVER` (Minh) duyệt.

**Tác nhân phụ.** PH-03 (nhận nhóm consumer, hạn mức), trung tâm thông báo, hộp "Việc của tôi".

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-030.

**Truy vết.** REQ-02, REQ-03; quy trình Công bố dịch vụ; LGC-APIM-009.

**Tiền điều kiện.** Gói `tich-hop-bao-mat` `STAGING` đã khai đủ xác thực và hạn mức; phiên bản `PUBLISHED`, hoặc `PENDING` trong cùng đợt duyệt; Lan, người sửa gần nhất và Minh là ba người khác nhau.

**Kích hoạt.** Lan bấm "Gửi duyệt gói" ở UI-02-06.

**Đảm bảo tối thiểu.** Gói không sang `PUBLISHED` khi chưa có quyết định duyệt hợp lệ hoặc khi PH-03 chưa nhận cấu hình; gói không nhận đăng ký trong thời gian đó.

**Đảm bảo thành công.** Gói `PUBLISHED`; cấu hình gói (nhóm consumer, hạn mức) có ở gateway; Lan được thông báo.

**Luồng chính.**

1. Lan bấm "Gửi duyệt gói". Hệ thống kiểm tra gói đủ điều kiện (đã khai xác thực, hạn mức) và phiên bản không ở trạng thái cuối.
2. Hệ thống tạo yêu cầu duyệt loại `PLAN_PUBLISH` gắn gói và đưa vào "Việc của tôi" của Minh (API-02-037).
3. Minh mở yêu cầu ở UI-02-10 và xem điều kiện đăng ký (HTTT được xin `HT-MOTCUA`, `HT-YTE`), kiểu xác thực `OAUTH2_MTLS`, hạn mức, đơn giá thông tin, các cảnh báo.
4. Hệ thống áp luồng phụ bốn mắt LP-02-01: người gửi, người sửa gần nhất và người duyệt phải khác nhau.
5. Minh chọn "Duyệt" kèm ý kiến (API-02-044, 045). Hệ thống chuyển gói sang `PUBLISHED` và chuyển cấu hình xuống PH-03 theo luồng phụ LP-02-02; chờ xác nhận nạp.
6. Hệ thống phát EVT-02-08, ghi kiểm toán (người gửi, người duyệt, ý kiến, trạng thái trước và sau) và thông báo Lan; gói bắt đầu nhận đăng ký (UC-02-23).

**Luồng thay thế.**

- **A1. (bước 2) Gói đi kèm phiên bản đang `PENDING`.** Yêu cầu của gói gộp vào yêu cầu duyệt phiên bản (UC-02-16); gói chỉ sang `PUBLISHED` khi phiên bản sang `PUBLISHED`.
- **A2. (bước 5) Minh từ chối.** Gói về `STAGING` kèm ý kiến, Lan sửa rồi gửi lại.
- **A3. (bước 5) Minh chọn "Hỏi thêm".** Yêu cầu chuyển `CLARIFICATION`, Lan trả lời trên cùng yêu cầu; không tính là quyết định.

**Luồng ngoại lệ.**

- **E1. Gói chưa đủ điều kiện (bước 1).** ERR-02-012 (409); "Gói còn thiếu: {danh sách}." kèm liên kết tới từng mục thiếu.
- **E2. Người gửi hoặc người sửa gần nhất tự duyệt (bước 4).** ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."
- **E3. Từ chối không nêu lý do (bước 5).** ERR-02-041 (400); "Cần nêu lý do khi trả lại."
- **E4. PH-03 không nhận cấu hình trong thời hạn (bước 5).** ERR-02-033 (503); "Cổng API chưa nhận cấu hình gói. Hệ thống sẽ thử lại, gói chưa nhận đăng ký."
- **E5. Phiên bản ở trạng thái cuối (bước 1).** ERR-02-011 (409); "Không thực hiện được ở trạng thái {trạng thái} hiện tại."

**Quy tắc áp dụng.** BR-02-008, 016, 028.

**Màn hình, API.** UI-02-06, 10; API-02-037, 044, 045.
:::

### 6.14. UC-02-14 · Ngừng khuyến nghị, đóng và sao chép gói

::: dac-ta
**Mục tiêu.** Chủ dịch vụ thay một gói cũ bằng gói mới mà không cắt bất ngờ những HTTT đang dùng: ngừng nhận đăng ký mới, báo bên đang dùng, đóng hẳn khi không còn ai, và mang các gói sang phiên bản mới khỏi dựng lại.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan); `ROLE-CATALOG_APPROVER` (Minh).

**Tác nhân phụ.** PH-03 (gỡ cấu hình gói), UC-02-33 (thông báo), bên đăng ký đang dùng gói.

**Mức ưu tiên.** M (ngừng khuyến nghị, đóng), S (sao chép) · MVP.

**FR hiện thực.** FR-02-031, 032, 033.

**Truy vết.** REQ-02, REQ-03; quy trình Nâng phiên bản, ngừng dùng; LGC-APIM-009.

**Tiền điều kiện.** API `ho-so-dat-dai` phiên bản `1.2.0` có gói `tich-hop-noi-bo` `PUBLISHED` (3 đăng ký `ACTIVE`) và gói kế nhiệm `tich-hop-bao-mat` `PUBLISHED` cùng phiên bản.

**Kích hoạt.** Lan bấm "Ngừng khuyến nghị" ở UI-02-06.

**Đảm bảo tối thiểu.** Không đóng gói khi còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED`; mã gói đã hủy hay đóng giữ chỗ vĩnh viễn.

**Đảm bảo thành công.** Gói cũ `DEPRECATED` rồi `CLOSED` khi không còn ai dùng; gói kế nhiệm nhận đăng ký mới; phiên bản mới có sẵn gói sao chép ở `STAGING`.

**Luồng chính.**

1. Lan chọn gói `tich-hop-noi-bo`, nhập lý do "Chuyển sang xác thực mTLS", gói kế nhiệm `tich-hop-bao-mat`, hạn chuyển đổi `31/05/2027`.
2. Hệ thống kiểm tra gói kế nhiệm cùng phiên bản và đang `PUBLISHED`, đếm đăng ký hiệu lực (3) và hiện cho Lan; vì còn đăng ký nên hạn phải từ hôm nay cộng `02.deprecation.min-days` (180 ngày, tức từ 25/05/2027); `31/05/2027` đạt.
3. Hệ thống tạo yêu cầu duyệt `PLAN_DEPRECATE` (API-02-038); Minh duyệt ở UI-02-10 theo UC-02-16 (bốn mắt).
4. Khi duyệt, hệ thống chuyển gói `DEPRECATED`, khóa nhận đăng ký mới, giữ các đăng ký hiện có, phát EVT-02-08 và EVT-02-12; UC-02-33 thông báo ba bên đang dùng kèm gói kế nhiệm và hạn; hệ thống đặt lịch nhắc 90, 30, 7 ngày.
5. Sau khi cả ba bên chuyển sang gói kế nhiệm và đăng ký cũ đóng, Lan chọn "Đóng gói" ở gói `tich-hop-noi-bo`, nhập lý do.
6. Hệ thống đếm đăng ký hiệu lực của gói là 0, tạo yêu cầu duyệt; Minh duyệt; hệ thống chuyển gói `CLOSED`, yêu cầu PH-03 gỡ cấu hình gói (API-02-039), ghi kiểm toán.
7. Khi Lan tạo phiên bản `2.0.0` (UC-02-18), hệ thống đề xuất sao chép gói. Lan chọn `tich-hop-bao-mat` từ `1.2.0` sang `2.0.0` với `keepCodes = true`.
8. Hệ thống sao chép khai báo (điều kiện, xác thực, hạn mức, đường dẫn cho phép) sang gói `STAGING` của phiên bản đích, đối chiếu thao tác cho phép với đặc tả `2.0.0` (thao tác không còn bị loại và báo), kiểm tra lại ràng buộc xác thực theo `dataClass` hiện hành và trả danh sách gói kèm cảnh báo (API-02-040).

**Luồng thay thế.**

- **A1. (bước 3) Gói chưa có đăng ký nào.** Hệ thống bỏ bước thông báo và hạn; Minh duyệt nhanh.
- **A2. (bước 5) Lan hủy một gói `STAGING` chưa từng công bố.** Hệ thống xóa mềm gói, giữ chỗ mã vĩnh viễn, không cần duyệt (API-02-041).
- **A3. (bước 5) Còn đăng ký lẻ.** Lan chọn "Chuyển các đăng ký còn lại sang gói kế nhiệm"; hệ thống tạo đăng ký mới `ACTIVE` ở gói kế nhiệm cho từng HTTT (kế thừa mục đích, thời hạn) và đóng đăng ký cũ.
- **A4. (bước 7) Lan không chọn gói nào để sao chép.** Lan tạo gói mới theo UC-02-12.

**Luồng ngoại lệ.**

- **E1. Gói không `PUBLISHED` (bước 1).** ERR-02-011 (409); "Chỉ gói đang công bố mới ngừng khuyến nghị được."
- **E2. Hạn quá ngắn khi còn đăng ký (bước 2).** ERR-02-031 (422); "Hạn chuyển đổi tối thiểu {n} ngày kể từ hôm nay."
- **E3. Gói kế nhiệm không hợp lệ (bước 2).** ERR-02-003 (400); "Gói kế nhiệm phải cùng phiên bản và đang công bố."
- **E4. Người gửi tự duyệt (bước 3).** ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."
- **E5. Đóng gói khi còn đăng ký hiệu lực (bước 6).** ERR-02-024 (409); "Còn {n} đăng ký đang dùng gói này. Chuyển hoặc thu hồi trước khi đóng." kèm danh sách.
- **E6. Đóng gói còn `PUBLISHED` (bước 5).** ERR-02-011 (409); "Ngừng khuyến nghị gói trước khi đóng."
- **E7. Đóng gói không nêu lý do (bước 5).** ERR-02-041 (400); "Cần nêu lý do đóng gói."
- **E8. Mã gói trùng ở phiên bản đích (bước 8).** ERR-02-002 (409); "Phiên bản đích đã có gói {mã}. Bỏ chọn hoặc đổi mã."
- **E9. Phiên bản đích không `DRAFT` (bước 8).** ERR-02-038 (409); "Phiên bản đang chờ duyệt, không sửa được. Rút lại yêu cầu duyệt trước."
- **E10. PH-03 không nhận lệnh gỡ cấu hình (bước 6).** ERR-02-033 (503); hệ thống thử lại, gói giữ `DEPRECATED` cho tới khi gỡ xong, cảnh báo TO.

**Quy tắc áp dụng.** BR-02-004, 008, 016, 018, 019, 021, 028, 029, 035.

**Màn hình, API.** UI-02-06, 10; API-02-038, 039, 040, 041, 044, 096.
:::

### 6.15. UC-02-15 · Thử trên TEST và gửi duyệt công bố API

::: dac-ta
**Mục tiêu.** Chủ dịch vụ kiểm chứng API bằng lời gọi thật ở môi trường thử rồi nộp một hồ sơ hoàn chỉnh cho người duyệt; hệ thống kiểm tra lại mọi điều kiện ở thời điểm nộp để người duyệt không mất công xem hồ sơ chưa đạt.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan).

**Tác nhân phụ.** PH-03 và APISIX môi trường TEST (nạp cấu hình thử), `ROLE-CATALOG_APPROVER` (Minh) nhận việc.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-034, 036 (chế độ thử).

**Truy vết.** REQ-02; quy trình Kết nạp HTTT → công bố dịch vụ; LGC-APIM-004.

**Tiền điều kiện.** Phiên bản `tra-cuu-ho-tich 1.0.0` `DRAFT`; Lan có `PERM-02-create` và `PERM-02-submit`; đặc tả đạt hai lớp kiểm tra; đã có backend `ACTIVE`, gói `tich-hop-bao-mat` đủ khai báo và SLA.

**Kích hoạt.** Lan bấm "Thử trên TEST" rồi "Gửi duyệt" ở UI-02-02, hoặc "Lưu và gửi duyệt" ở bước 5 của UI-02-03.

**Đảm bảo tối thiểu.** Chế độ thử không đổi trạng thái vòng đời, không đồng bộ quốc gia và không thông báo bên khai thác. Khi gửi duyệt thất bại, phiên bản vẫn `DRAFT` và nguyên nội dung.

**Đảm bảo thành công.** Phiên bản `PENDING`, nội dung bị khóa; yêu cầu duyệt `VERSION_PUBLISH` nằm trong "Việc của tôi" của Minh kèm ảnh chụp kết quả kiểm tra.

**Luồng chính.**

1. Lan bấm "Thử trên TEST". Hệ thống kiểm tra phiên bản `DRAFT` đạt kiểm tra đặc tả, backend và gói có cấu hình cho TEST (API-02-047, `environment = TEST`).
2. Hệ thống dựng bộ cấu hình: một route cho mỗi thao tác có trong đặc tả (SEC-43), upstream từ backend `ACTIVE`, nhóm consumer và chính sách của gói, lược đồ kiểm tra yêu cầu; chuyển PH-03 sinh ảnh chụp có chữ ký và chờ APISIX TEST xác nhận (luồng phụ LP-02-02).
3. Hệ thống ghi `lastTestDeploy {env: TEST, sha256, at, result: OK}`; trạng thái vòng đời không đổi.
4. Lan gọi thử bằng client thử nghiệm: hai lời gọi `getCivilRecord` và `searchCivilRecords` trả `200`.
5. Lan nhập ghi chú "API cho Cổng một cửa dùng" và bấm "Gửi duyệt" (API-02-042).
6. Hệ thống chạy lại lớp 1, lớp 2 và quét bí mật trên đúng băm đang lưu (UC-02-06, 07); còn `ERROR` thì từ chối.
7. Hệ thống kiểm tra các điều kiện còn lại và gom mọi điều kiện thiếu vào một danh sách: có ít nhất một backend `ACTIVE` với tổng trọng số lớn hơn 0; có ít nhất một gói đủ khai báo; đã khai SLA; mô tả tiếng Việt đủ độ dài; mức hiển thị hợp lệ với `dataClass`; không còn cảnh báo mở chưa chấp nhận.
8. Hệ thống kiểm tra phiên bản đã chạy thử TEST thành công trong 30 ngày trên đúng băm đặc tả (`02.submit.require-test-deploy` mặc định bật) và kiểm tra thay đổi phá vỡ so với phiên bản `PUBLISHED` cùng API (phiên bản đầu nên không có).
9. Hệ thống chuyển phiên bản `PENDING`, khóa đặc tả, backend, gói, SLA, tạo yêu cầu `VERSION_PUBLISH` kèm ảnh chụp kết quả kiểm tra và danh sách API gần giống, đưa vào "Việc của tôi" của Minh.
10. Hệ thống ghi kiểm toán (người gửi, băm đặc tả, tóm tắt kiểm tra, ghi chú), phát EVT-02-04, trả `202` kèm `reviewRequestId` và thông báo Lan "Đã gửi duyệt phiên bản 1.0.0."

**Luồng thay thế.**

- **A1. (sau bước 10) Lan rút lại khi chưa ai quyết định.** Lan bấm "Rút lại" (API-02-043); phiên bản về `DRAFT`, yêu cầu duyệt chuyển `WITHDRAWN`.
- **A2. (bước 1) Lan thử ở STAGING.** Cùng luồng, `environment = STAGING`; chỉ kết quả ở TEST được tính cho điều kiện bước 8.
- **A3. (bước 1) Chi (TO) thử lại sau lỗi tạm thời.** TO có `PERM-02-operate` bấm "Thử lại", cùng luồng.
- **A4. (bước 8) Tỉnh tắt `02.submit.require-test-deploy`.** Hệ thống bỏ điều kiện thử TEST; các điều kiện khác giữ nguyên.
- **A5. (bước 5) "Lưu và gửi duyệt" từ UI-02-03.** Việc lưu bản nháp và gửi duyệt chạy trong một giao dịch; thiếu điều kiện thì chỉ lưu `DRAFT`.

**Luồng ngoại lệ.**

- **E1. Đặc tả còn lỗi (bước 6).** ERR-02-006, ERR-02-007 hoặc ERR-02-008 (422); "Đặc tả còn lỗi, mở kết quả kiểm tra để xem hướng dẫn sửa."
- **E2. Thiếu điều kiện (bước 7, 8).** ERR-02-012 (409); "Chưa đủ điều kiện gửi duyệt: {danh sách}." kèm liên kết tới từng mục thiếu, ví dụ "chưa thử trên TEST", "chưa khai SLA", "thiếu backend hoạt động" (ERR-02-021).
- **E3. Có thay đổi phá vỡ mà giữ số chính (bước 8).** ERR-02-017 (409); "Có {n} thay đổi phá vỡ tương thích. Tăng số phiên bản chính rồi gửi lại." kèm liên kết UI-02-05.
- **E4. Phiên bản không `DRAFT` (bước 5).** ERR-02-011 (409); "Chỉ phiên bản nháp mới gửi duyệt được."
- **E5. PH-03 hoặc APISIX TEST không nhận cấu hình (bước 2).** ERR-02-033 (503); "Cổng API chưa nhận cấu hình, hệ thống đang thử lại. Phiên bản giữ nguyên trạng thái hiện tại."
- **E6. Lan thiếu quyền gửi duyệt (bước 5).** ERR-02-014 (403); "Bạn không thuộc đơn vị chủ quản của HTTT này."

**Quy tắc áp dụng.** BR-02-001, 003, 008, 015, 024, 028.

**Màn hình, API.** UI-02-02, 03 (bước 5); API-02-042, 043, 047.
:::

### 6.16. UC-02-16 · Duyệt bốn mắt và công bố API ra gateway

::: dac-ta
**Mục tiêu.** Người thứ hai chịu trách nhiệm cho việc đưa một phiên bản API ra môi trường thật; sau khi duyệt, API gọi được qua cổng trong vòng 30 giây và xuất hiện trong danh mục. Cùng màn hình duyệt dùng cho công bố gói, ngừng khuyến nghị, ngừng hẳn, nâng mức hiển thị, thay đổi backend và đăng ký sử dụng.

**Tác nhân chính.** `ROLE-CATALOG_APPROVER` (Minh); `ROLE-TENANT_ADMIN` (Quang) xác nhận lần hai với API `SENSITIVE`.

**Tác nhân phụ.** `ROLE-SERVICE_OWNER` (Lan) nhận kết quả; PH-03 (bộ đồng bộ cấu hình) và APISIX; hộp "Việc của tôi" (PH-18); PH-15 và PH-14 nhận sự kiện sau công bố.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-035, 036.

**Truy vết.** REQ-02; quy trình Kết nạp HTTT → công bố dịch vụ; LGC-APIM-004; LGC-APIM-006.

**Tiền điều kiện.** Có yêu cầu duyệt `VERSION_PUBLISH` ở `PENDING` (UC-02-15); Minh có `PERM-02-publish` và không giữ vai trò SV của chính API này; không trong khoảng đóng băng thay đổi môi trường thật.

**Kích hoạt.** Minh mở việc từ "Việc của tôi" (UI-02-10, `/viec-cua-toi`).

**Đảm bảo tối thiểu.** Không có phiên bản nào lên `PUBLISHED` khi chưa đủ quyết định `APPROVE` hợp lệ và băm đặc tả khớp bản đã duyệt; công bố lỗi giữa chừng không để gateway ở trạng thái nửa vời (phiên bản giữ `PENDING`, thử lại, cảnh báo TO).

**Đảm bảo thành công.** Phiên bản `PUBLISHED`; route, upstream, consumer có ở gateway; mục danh mục cập nhật; bản ghi đồng bộ quốc gia đã xếp nếu mức hiển thị `NATIONAL`, `PUBLIC`.

**Luồng chính.**

1. Minh mở yêu cầu. Hệ thống hiện hồ sơ: thông tin API, đặc tả (trình xem), kết quả kiểm tra ba lớp, kết quả chạy thử TEST, backend, gói, SLA, phân loại, mức hiển thị, danh sách API gần giống và báo cáo khác biệt với phiên bản trước.
2. Hệ thống kiểm tra Minh khác người gửi (Lan), khác người sửa gần nhất đặc tả hoặc gói, và không giữ vai trò SV của chính API này (luồng phụ LP-02-01).
3. Minh rà soát các điểm bắt buộc: phân loại dữ liệu `RESTRICTED` hợp lý, kiểu xác thực `OAUTH2_MTLS`, hạn mức, SLA; quyết định về API gần giống (`tra-cuu-giay-khai-sinh`, UC-02-07 bước 9); tick xác nhận ba cảnh báo còn mở.
4. Minh bấm "Duyệt" kèm ý kiến (API-02-044, 045).
5. Hệ thống kiểm tra lần cuối: băm đặc tả khớp bản đã gửi, không có lỗi mới, rồi chạy công bố môi trường `PROD` (API-02-047).
6. Hệ thống dựng bộ cấu hình công bố: route cho từng thao tác trong đặc tả (chỉ thao tác có trong đặc tả, SEC-43), upstream từ backend `ACTIVE` kèm cân bằng tải và kiểm tra sức khỏe, nhóm consumer và chính sách cho từng gói `PUBLISHED`, lược đồ kiểm tra yêu cầu sinh từ đặc tả.
7. Hệ thống chuyển cho PH-03 sinh ảnh chụp cấu hình có chữ ký và số phiên bản tăng dần; PH-03 chờ APISIX xác nhận đã nạp (lan truyền ≤ 10 giây) và trả xác nhận trong 30 giây (luồng phụ LP-02-02; API-02-082).
8. Hệ thống chuyển phiên bản `PUBLISHED`, đặt `publishedAt`, chuyển gói `STAGING` đi kèm sang `PUBLISHED`, cập nhật chỉ mục danh mục.
9. Hệ thống xếp đồng bộ quốc gia nếu mức hiển thị `NATIONAL`, `PUBLIC` (UC-02-29), phát EVT-02-05, ghi kiểm toán (người duyệt, số phiên bản cấu hình gateway, băm cấu hình, thời gian từ duyệt tới gọi được) và thông báo Lan "tra-cuu-ho-tich 1.0.0 đã công bố, gọi được ở /ho-tich/tra-cuu-ho-tich/v1".

**Luồng thay thế.**

- **A1. (bước 4) API `SENSITIVE`.** Sau quyết định của Minh, yêu cầu ở `AWAITING_SECOND`; hệ thống tạo việc xác nhận cho Quang (TA, khác Minh); đủ hai xác nhận mới sang bước 5 (BR-02-008).
- **A2. (bước 4) Minh bấm "Trả lại".** Minh nhập ý kiến bắt buộc; phiên bản về `DRAFT` (gói về `STAGING`), Lan nhận thông báo kèm ý kiến.
- **A3. (bước 4) Minh bấm "Hỏi thêm".** Yêu cầu về `CLARIFICATION`; Lan trả lời trên cùng yêu cầu, nội dung bị khóa không đổi; không tính là quyết định.
- **A4. (bước 6) Phiên bản mới cùng số chính với phiên bản đang chạy.** Hệ thống kiểm tra tương thích ngược và mọi gói đang có đăng ký đều có gói cùng mã ở phiên bản mới (BR-02-035); nếu gói khác mã, Minh chọn ánh xạ gói ở bước duyệt. Ở bước 8, hệ thống chuyển đăng ký `ACTIVE` sang gói cùng mã của phiên bản mới và đưa phiên bản cũ sang `RETIRED` với lý do `SUPERSEDED`, phát EVT-02-06 và thông báo bên khai thác.
- **A5. (bước 1) Yêu cầu loại khác.** Với `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `BACKEND_CHANGE`, `VISIBILITY_RAISE`, `SUBSCRIPTION`, màn duyệt hiển thị hồ sơ theo loại; ở bước 5 hệ thống chạy hành động tương ứng (UC-02-13, 14, 19, 20, 21, 24).
- **A6. (bước 7) PH-03 chưa xác nhận.** Chi (TO) bấm "Thử lại công bố" (API-02-047 kèm `reviewRequestId`); hệ thống cũng tự thử lại tối đa 5 lần trong 15 phút.
- **A7. Yêu cầu quá `02.review.overdue-days` ngày làm việc.** Hệ thống nhắc người duyệt, báo TA và phát EVT-02-16.

**Luồng ngoại lệ.**

- **E1. Vi phạm bốn mắt (bước 2).** ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt." Nút "Duyệt" khóa; UC kết thúc với Minh.
- **E2. Trả lại không có lý do (bước 4).** ERR-02-041 (400); "Cần nêu lý do khi trả lại."
- **E3. Hồ sơ đã đổi sau khi gửi (bước 5).** ERR-02-015 (412); "Hồ sơ đã thay đổi sau khi gửi duyệt. Mở lại để xem." Hệ thống không công bố, đưa phiên bản về `DRAFT` và báo cả hai bên.
- **E4. Yêu cầu đã có quyết định (bước 1).** ERR-02-011 (409); "Yêu cầu này đã có quyết định."
- **E5. Không có quyền với loại yêu cầu (bước 1).** ERR-02-014 (403); "Bạn không có quyền xử lý loại yêu cầu này."
- **E6. PH-03 hoặc APISIX không xác nhận trong 30 giây (bước 7).** ERR-02-033 (503); phiên bản giữ `PENDING`, hệ thống thử lại tối đa 5 lần trong 15 phút rồi cảnh báo TO; Lan thấy "Cổng API chưa nhận cấu hình, hệ thống đang thử lại. Phiên bản giữ nguyên trạng thái hiện tại."
- **E7. Context-path xung đột phát sinh sau khi duyệt (bước 6).** ERR-02-019 (422); phiên bản giữ `PENDING`, báo TA; "Đường dẫn {đường dẫn} đã được dùng hoặc xung đột với {đường dẫn khác}."
- **E8. Có thay đổi phá vỡ mà giữ số chính (bước 6).** ERR-02-017 (409); "Có {n} thay đổi phá vỡ tương thích. Tăng số phiên bản chính rồi gửi lại."
- **E9. Đang đóng băng thay đổi môi trường thật (bước 5).** ERR-02-039 (423); "Đang trong khoảng đóng băng thay đổi môi trường thật tới {thời điểm}." Quyết định duyệt giữ nguyên, việc công bố chờ hết đóng băng.
- **E10. Thiếu gói cùng mã cho đăng ký đang có (A4).** ERR-02-012 (409); "Chưa đủ điều kiện: {danh sách}."

**Quy tắc áp dụng.** BR-02-001, 003, 008, 014, 022, 026, 028, 035.

**Màn hình, API.** UI-02-10, 02; API-02-044, 098 (chi tiết yêu cầu duyệt), 045, 046, 047, 082.
:::

```{.mermaid caption="Trình tự duyệt bốn mắt và công bố API ra gateway"}
sequenceDiagram
  autonumber
  participant SV as Lan, chủ dịch vụ
  participant C as PH-02
  participant H as Việc của tôi
  participant CA as Minh, người duyệt
  participant TA as Quang, quản trị tenant
  participant P3 as PH-03 bộ đồng bộ cấu hình
  participant AP as APISIX
  SV->>C: Gửi duyệt phiên bản
  C->>H: Tạo việc VERSION_PUBLISH cho CA
  CA->>H: Mở việc
  H->>C: Lấy hồ sơ, kết quả kiểm tra, API gần giống
  CA->>C: Duyệt kèm ý kiến
  C->>C: Kiểm tra bốn mắt, băm hồ sơ không đổi
  alt API mức SENSITIVE
    C->>H: Tạo việc xác nhận lần hai cho TA
    TA->>C: Xác nhận
  end
  C->>P3: Bộ cấu hình công bố
  P3->>AP: Ảnh chụp cấu hình có chữ ký
  AP-->>P3: Đã nạp số phiên bản
  P3-->>C: Xác nhận trong 30 giây
  C->>C: Đặt PUBLISHED, xếp đồng bộ quốc gia
  C-->>SV: Thông báo đã công bố
```

Hình trên cho thấy việc duyệt luôn đi qua "Việc của tôi" dùng chung, không có đường tắt; API ra gateway chỉ sau khi PH-03 xác nhận APISIX đã nạp, và riêng dữ liệu Nhạy cảm cần người thứ hai sau Minh.

### 6.17. UC-02-17 · Tạm ngừng khẩn và tiếp tục API

::: dac-ta
**Mục tiêu.** Cán bộ ATTT hoặc vận hành chặn ngay một API khi phát hiện lỗi nghiêm trọng hay sự cố an ninh, rồi cho chạy lại sau khi xử lý xong; bên khai thác được báo ngay, đăng ký giữ nguyên.

**Tác nhân chính.** `ROLE-SECURITY_OFFICER` (Dũng), `ROLE-TENANT_OPERATOR` (Chi); `ROLE-TENANT_ADMIN` (Quang) tiếp tục thay.

**Tác nhân phụ.** PH-03 và APISIX (đẩy cấu hình), UC-02-33 (thông báo bắt buộc), `ROLE-SERVICE_OWNER` (Lan) nhận thông báo.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-037.

**Truy vết.** REQ-02, REQ-03, REQ-13; quy trình Sự cố ATTT; LGC-APIM-005.

**Tiền điều kiện.** Phiên bản `tra-cuu-ho-tich 1.0.0` `PUBLISHED` (tạm ngừng) hoặc `SUSPENDED` (tiếp tục); người thực hiện có `PERM-02-operate`.

**Kích hoạt.** Dũng bấm "Tạm ngừng" hoặc "Tiếp tục" ở UI-02-02.

**Đảm bảo tối thiểu.** Tạm ngừng không xóa đăng ký, phạm vi hay consumer; thời hạn tạm ngừng không vượt `02.suspend.max-days`; thông báo bên khai thác không lộ chi tiết sự cố ATTT.

**Đảm bảo thành công.** Trong ≤ 30 giây, route của phiên bản trả `503` mã `API_SUSPENDED` (hoặc phục hồi khi tiếp tục); bên khai thác và chủ dịch vụ đã được thông báo.

**Luồng chính.**

1. Dũng bấm "Tạm ngừng" ở phiên bản `1.0.0`, chọn nhóm lý do `SECURITY`, nhập "Nghi lộ chứng thư của HT-YTE", `expectedResumeAt` `27/11/2026 17:00` và xác nhận (tuân thủ FR-00-050). Hệ thống kiểm tra phiên bản `PUBLISHED`.
2. Hệ thống chuyển phiên bản `SUSPENDED`, đặt `suspendedBy`, `suspendedAt` và `suspendDeadline` bằng hiện tại cộng 30 ngày (API-02-048); không cần duyệt (BR-02-034).
3. Hệ thống yêu cầu PH-03 đẩy cấu hình mới: route trả `503` thân RFC 9457 mã `API_SUSPENDED` kèm `Retry-After`; không gỡ consumer, không đổi đăng ký (luồng phụ LP-02-02, hiệu lực ≤ 30 giây).
4. Hệ thống gửi thông báo bắt buộc cho mọi bên đăng ký `ACTIVE` và Lan (UC-02-33, loại `SUSPENSION`) với lý do ở mức tổng quát; gắn nhãn "Khẩn" và báo Quang ngay.
5. Sau khi xử lý xong, Dũng bấm "Tiếp tục" kèm ghi chú (API-02-049). Hệ thống kiểm tra quyền tiếp tục theo BR-02-034: vì Dũng ngừng với nhóm `SECURITY` nên chỉ Dũng hoặc Quang tiếp tục được.
6. Hệ thống kiểm tra backend khỏe (UC-02-11 bước 7), khôi phục route, đẩy cấu hình qua PH-03, phát EVT-02-06 và thông báo `RESUMPTION` cho các bên.
7. Nếu chưa tiếp tục, sau 80% thời hạn (24 ngày) hệ thống nhắc Quang; quá hạn thì tạo việc bắt buộc: tiếp tục hoặc ngừng khuyến nghị (UC-02-19).

**Luồng thay thế.**

- **A1. (bước 1) Chi tạm ngừng do `BACKEND_FAILURE`.** Cùng luồng; người tiếp tục là Chi hoặc Quang.
- **A2. (bước 1) Tạm ngừng khẩn.** SO, TO không cần duyệt; hệ thống ghi nhãn "Khẩn" và thông báo TA ngay (BR-02-034).

**Luồng ngoại lệ.**

- **E1. Phiên bản không `PUBLISHED` (bước 1).** ERR-02-011 (409); "Chỉ API đang công bố mới tạm ngừng được."
- **E2. Thiếu lý do (bước 1).** ERR-02-041 (400); "Cần nêu lý do tạm ngừng."
- **E3. Người tiếp tục không đủ quyền (bước 5).** ERR-02-014 (403); "Chỉ người đã tạm ngừng hoặc quản trị tenant mới tiếp tục được."
- **E4. PH-03 không nhận lệnh (bước 3, 6).** ERR-02-033 (503); "Cổng API chưa nhận lệnh. Hệ thống đang thử lại."; trạng thái hiển thị theo thực tế ở gateway và cảnh báo TO.

**Quy tắc áp dụng.** BR-02-028, 029, 034.

**Màn hình, API.** UI-02-02; API-02-048, 049.
:::

### 6.18. UC-02-18 · Tạo phiên bản mới, so sánh và phân tích tác động

::: dac-ta
**Mục tiêu.** Chủ dịch vụ phát triển API tiếp từ phiên bản có sẵn, thấy chính xác thay đổi nào làm hỏng bên khai thác và bên nào bị ảnh hưởng, để chọn đúng số phiên bản và lập lộ trình chuyển đổi.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan).

**Tác nhân phụ.** PH-13 (lượt gọi theo HTTT, theo thao tác), PH-01 (đầu mối kỹ thuật của bên đăng ký).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-042, 043, 044.

**Truy vết.** REQ-02; quy trình Nâng phiên bản, ngừng dùng; không có LGC (SRS cũ FR-02-006).

**Tiền điều kiện.** API `ho-so-dat-dai` có phiên bản `1.2.0` `PUBLISHED` và không có phiên bản `DRAFT`, `PENDING` khác; Lan có `PERM-02-create`.

**Kích hoạt.** Lan bấm "Tạo phiên bản mới" ở tab Phiên bản của UI-02-02.

**Đảm bảo tối thiểu.** Phiên bản nguồn không đổi; kết quả so sánh và phân tích tác động không làm thay đổi dữ liệu; số hiệu phiên bản không bao giờ dùng lại.

**Đảm bảo thành công.** Phiên bản `2.0.0` `DRAFT` với nội dung sao chép; Lan có báo cáo khác biệt, danh sách bên bị ảnh hưởng và khuyến nghị lộ trình.

**Luồng chính.**

1. Lan chọn phiên bản nguồn `1.2.0` và các thành phần sao chép `spec`, `backends`, `plans`, `sla` (mặc định cả bốn).
2. Hệ thống đề xuất số hiệu theo mức thay đổi dự kiến; Lan nhập `2.0.0`. Hệ thống kiểm tra đúng định dạng `MAJOR.MINOR.PATCH`, lớn hơn mọi phiên bản hiện có, chưa dùng kể cả đã xóa.
3. Hệ thống tạo phiên bản `DRAFT` `2.0.0`, sao chép thành phần được chọn (gói theo UC-02-14 bước 7, 8), sinh context-path `/dat-dai/ho-so-dat-dai/v2` theo số chính mới (API-02-054) và nói rõ phiên bản mới sẽ chạy song song ở đường dẫn mới.
4. Lan sửa đặc tả: đổi tên trường phản hồi `maThua` thành `soThua`, thêm tham số bắt buộc `nam`, thêm giá trị `enum` mới ở phản hồi.
5. Lan mở UI-02-05 (`/ket-noi/api/ho-so-dat-dai/so-sanh?tu=1.2.0&den=2.0.0`). Hệ thống gọi API-02-055, đọc hai đặc tả đã gộp tham chiếu, so theo cấu trúc và phân loại từng thay đổi: 2 `BREAKING` (đổi tên trường phản hồi, thêm tham số bắt buộc), 3 `COMPATIBLE`, 1 `UNCERTAIN` (mở rộng `enum` phản hồi).
6. Hệ thống tổng hợp `breaking = true`, đề xuất tăng `MAJOR`, đối chiếu với số hiệu `2.0.0` (`versionViolation = false`) và hiện hai nhóm thay đổi (đỏ phá vỡ, xanh tương thích) cùng khung đặc tả song song.
7. Lan xác nhận thay đổi `UNCERTAIN` là phá vỡ kèm lý do; hệ thống ghi kiểm toán người xác nhận và lý do.
8. Lan mở khối "Bên bị ảnh hưởng" (API-02-056). Hệ thống lấy đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` của `1.2.0` (5 bên) kèm đầu mối kỹ thuật, lấy từ PH-13 số lượt gọi 30 ngày theo thao tác, giao với tập thay đổi `BREAKING` và chỉ ra 3 bên thật sự gọi thao tác bị phá vỡ, xếp theo lượt gọi giảm dần.
9. Hệ thống khuyến nghị lộ trình: 3 bên cần chuyển, hạn tối thiểu 180 ngày. Lan bấm "Tạo lộ trình ngừng dùng" để mở UI-02-13 với kế nhiệm `2.0.0` điền sẵn (UC-02-19).

**Luồng thay thế.**

- **A1. (bước 2) Lan nhập số hiệu cùng số chính, ví dụ `1.3.0`.** Hệ thống nói rõ phiên bản sẽ thay thế `1.2.0` khi công bố và chỉ được phép nếu tương thích ngược (BR-02-035); đường dẫn không đổi.
- **A2. (bước 1) Lan bỏ chọn sao chép đặc tả.** Lan nạp đặc tả hoàn toàn mới (UC-02-05 bước 3, 4) cho thay đổi lớn.
- **A3. (bước 5) Đặc tả rất lớn.** So sánh chạy nền với tiến độ (tuân thủ FR-00-054); sinh báo cáo ≤ 3 giây với hai đặc tả 5.000 dòng (NFR-02-004).
- **A4. (bước 8) Lan bấm "Xuất danh sách".** Hệ thống xuất danh sách bên bị ảnh hưởng để gửi từng đơn vị (tuân thủ FR-00-030); tệp không chứa số lượt gọi chi tiết theo thao tác của đơn vị khác.
- **A5. (bước 8) PH-13 không khả dụng.** Danh sách chỉ có đăng ký kèm nhãn "Chưa có số lượt gọi; hiển thị theo đăng ký."

**Luồng ngoại lệ.**

- **E1. Đã có bản nháp khác (bước 1).** ERR-02-011 (409); "API đã có phiên bản đang soạn {số}. Hoàn tất hoặc hủy bản đó trước."
- **E2. Số hiệu không hợp lệ hoặc không tăng (bước 2).** ERR-02-018 (422); "Số phiên bản phải dạng MAJOR.MINOR.PATCH và lớn hơn {số hiện có}."
- **E3. Số hiệu đã dùng (bước 2).** ERR-02-002 (409); "Mã {số} đã được dùng (kể cả đối tượng đã xóa hoặc ngừng). Chọn mã khác."
- **E4. Vượt số phiên bản tối đa mỗi API (bước 2).** ERR-02-040 (422); "Vượt trần {n} do nền tảng đặt."
- **E5. Một trong hai phiên bản thiếu đặc tả hợp lệ (bước 5).** ERR-02-001 (404) hoặc ERR-02-006 (422); "Cần đặc tả hợp lệ ở cả hai phiên bản để so sánh."
- **E6. Đã có lần so sánh chạy cho cùng cặp (bước 5).** ERR-02-035 (409); "Đang so sánh, vui lòng chờ."
- **E7. Gửi duyệt khi có phá vỡ mà giữ số chính (UC-02-15).** ERR-02-017 (409); "Có {n} thay đổi phá vỡ tương thích. Tăng số phiên bản chính rồi gửi lại."

**Quy tắc áp dụng.** BR-02-003, 004, 006, 014, 021, 033, 035.

**Màn hình, API.** UI-02-02 (tab Phiên bản), 05; API-02-054, 055, 056.
:::

### 6.19. UC-02-19 · Ngừng khuyến nghị API có lộ trình

::: dac-ta
**Mục tiêu.** Bên khai thác biết một phiên bản sẽ ngừng, ngày nào, chuyển sang đâu, có đủ thời gian nâng cấp; mỗi lời gọi tới phiên bản cũ đều mang cảnh báo trong tiêu đề phản hồi.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan) đề nghị; `ROLE-CATALOG_APPROVER` (Minh) duyệt.

**Tác nhân phụ.** PH-03 (thêm tiêu đề cảnh báo), UC-02-33 (thông báo bắt buộc và nhắc theo lịch), bên đăng ký `ACTIVE`.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-038 (cùng 044, 057 qua UC-02-18 và UC-02-33).

**Truy vết.** REQ-02, REQ-03, REQ-13; quy trình Nâng phiên bản, ngừng dùng; LGC-APIM-008 (ngừng dùng có báo trước).

**Tiền điều kiện.** Phiên bản `ho-so-dat-dai 1.2.0` `PUBLISHED` hoặc `SUSPENDED`; phiên bản kế nhiệm `2.0.0` `PUBLISHED`; Lan có `PERM-02-submit`.

**Kích hoạt.** Lan bấm "Ngừng khuyến nghị" ở UI-02-02, mở UI-02-13 (lộ trình ngừng dùng).

**Đảm bảo tối thiểu.** Phiên bản không bao giờ tự ngừng hẳn; không cắt bên khai thác; hạn chuyển đổi không rút ngắn dưới mức tối thiểu trừ khi có lý do khẩn chính đáng và TA đồng ý.

**Đảm bảo thành công.** Phiên bản `1.2.0` `DEPRECATED` kèm `sunsetAt = 31/05/2027`, kế nhiệm `2.0.0`; gói `DEPRECATED`; mọi bên đăng ký đã nhận thông báo; lịch nhắc đã đặt.

**Luồng chính.**

1. Lan chọn phiên bản kế nhiệm `2.0.0`, hạn `31/05/2027`, nhập lý do "Chuyển sang v2 bảo mật hơn" và hướng dẫn chuyển. Hệ thống hiện 5 bên đăng ký `ACTIVE` và 3 bên chưa có đăng ký ở `2.0.0` (API-02-056).
2. Hệ thống kiểm tra kế nhiệm `PUBLISHED`, cùng API và số hiệu cao hơn.
3. Hệ thống kiểm tra `sunsetAt` không sớm hơn hôm nay cộng `02.deprecation.min-days` (180 ngày, tức từ 25/05/2027); `31/05/2027` đạt.
4. Hệ thống tạo yêu cầu duyệt `VERSION_DEPRECATE` kèm lộ trình (API-02-050); Minh duyệt theo UC-02-16 (bốn mắt).
5. Khi duyệt, hệ thống chuyển phiên bản `DEPRECATED`, đặt `sunsetAt`, `successorVersionId`; các gói của phiên bản chuyển `DEPRECATED` (UC-02-14).
6. Hệ thống yêu cầu PH-03 thêm tiêu đề `Deprecation`, `Sunset` và `Link: rel="successor-version"` vào mọi phản hồi của phiên bản (RFC 9745, RFC 8594), và phát thông báo bắt buộc `DEPRECATION` cho 5 bên kèm hướng dẫn chuyển (UC-02-33).
7. Hệ thống lập lịch nhắc ở mốc 90, 30, 7 ngày trước hạn và hằng tuần trong tháng cuối cho bên chưa chuyển; tháng cuối còn ai gọi thì báo cả Lan và Quang.

**Luồng thay thế.**

- **A1. (sau bước 4) Lan rút đề nghị khi chưa duyệt.** Yêu cầu chuyển `WITHDRAWN`, phiên bản giữ nguyên.
- **A2. (sau bước 5) Lan lùi `sunsetAt` ra xa hơn.** Không cần duyệt lại; chỉ được lùi, không được rút ngắn; hệ thống thông báo lại các bên.
- **A3. (bước 3) Hạn ngắn hơn tối thiểu vì lý do khẩn.** Lan nêu lý do khẩn chính đáng; yêu cầu duyệt chỉ đi tiếp khi Quang (TA) đồng ý trong yêu cầu; ngoại lệ được ghi kiểm toán.
- **A4. (bước 2) Không có kế nhiệm.** Lan tick `confirmNoSuccessor` và hệ thống hiện cảnh báo "ngừng hẳn dịch vụ"; yêu cầu duyệt nêu rõ điều này.

**Luồng ngoại lệ.**

- **E1. Thiếu kế nhiệm mà không xác nhận (bước 2).** ERR-02-032 (422); "Chưa có phiên bản kế nhiệm. Chọn phiên bản kế nhiệm hoặc xác nhận ngừng hẳn dịch vụ."
- **E2. Hạn quá ngắn (bước 3).** ERR-02-031 (422); "Hạn chuyển đổi tối thiểu {n} ngày. Chọn ngày muộn hơn {ngày}."
- **E3. Số hiệu kế nhiệm không cao hơn (bước 2).** ERR-02-018 (422); "Số phiên bản phải dạng MAJOR.MINOR.PATCH và lớn hơn {số hiện có}."
- **E4. Thiếu lý do (bước 1).** ERR-02-041 (400); "Cần nêu lý do ngừng khuyến nghị."
- **E5. Phiên bản không ở trạng thái cho phép (bước 1).** ERR-02-011 (409); "Không thực hiện được ở trạng thái {trạng thái} hiện tại."
- **E6. Người gửi tự duyệt (bước 4).** ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."
- **E7. PH-03 không nhận tiêu đề cảnh báo (bước 6).** ERR-02-033 (503); trạng thái vẫn chuyển `DEPRECATED`, tiêu đề được thử lại và cảnh báo TO ở UI-02-17.

**Quy tắc áp dụng.** BR-02-004, 005, 008, 018, 028, 029.

**Màn hình, API.** UI-02-13, 10, 05; API-02-050, 044, 056.
:::

### 6.20. UC-02-20 · Ngừng hẳn, hủy bản nháp và xóa API

::: dac-ta
**Mục tiêu.** Một phiên bản kết thúc đời sống an toàn: gỡ khỏi gateway, đóng gói, giữ hồ sơ làm bằng chứng; hệ thống không bao giờ tự ngừng hẳn khi còn bên khai thác. Cũng là nơi hủy bản nháp chưa công bố và xóa mềm API khai nhầm.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan); `ROLE-CATALOG_APPROVER` (Minh).

**Tác nhân phụ.** PH-03 (gỡ route, consumer), UC-02-29 (rút danh mục quốc gia), UC-02-33 (thông báo), `ROLE-TENANT_ADMIN` (Quang) khôi phục API xóa mềm.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-039, 040.

**Truy vết.** REQ-02, REQ-03, REQ-13; quy trình Nâng phiên bản, ngừng dùng; LGC-APIM-008.

**Tiền điều kiện.** Ngừng hẳn: phiên bản `ho-so-dat-dai 1.2.0` `DEPRECATED` tới hạn `31/05/2027` hoặc ngừng sớm; hủy nháp: phiên bản `DRAFT`; xóa API: mọi phiên bản `DRAFT` hoặc `RETIRED` và không còn đăng ký `PENDING`, `ACTIVE`, `SUSPENDED`.

**Kích hoạt.** Hệ thống đề nghị khi tới hạn `sunsetAt`; hoặc Lan bấm "Ngừng hẳn" ở UI-02-13, "Hủy bản nháp" ở UI-02-02, "Xóa API" ở menu "⋯" của UI-02-02.

**Đảm bảo tối thiểu.** Không có ngừng hẳn hay xóa nào khi còn đăng ký hiệu lực; không có tùy chọn "ép" bỏ qua đăng ký; đặc tả, phiên bản, đăng ký lịch sử giữ vĩnh viễn kể cả khi đã xóa mềm (BR-02-014).

**Đảm bảo thành công.** Phiên bản `RETIRED`, route và consumer đã gỡ, gói `CLOSED`, context-path giữ chỗ 12 tháng; hoặc API xóa mềm với mã và context-path giữ chỗ vĩnh viễn.

**Luồng chính.**

1. Tới hạn `31/05/2027`, hệ thống đếm đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` còn lại của `1.2.0` (1 bên, `HT-YTE`) và số lượt gọi 7 ngày gần nhất (UC-02-18 bước 8).
2. Còn đăng ký hiệu lực nên hệ thống không tự ngừng: báo Lan, Minh, Quang "Còn 1 bên đang dùng", nhắc lại hằng tuần và gợi ý lùi hạn (UC-02-19 nhánh A2) hoặc thu hồi đăng ký (UC-02-27).
3. Sau khi `HT-YTE` chuyển sang `2.0.0` và đăng ký cũ đóng, Lan tạo đề nghị ngừng hẳn với lý do (API-02-051); hệ thống tạo yêu cầu duyệt `VERSION_RETIRE`.
4. Minh duyệt theo UC-02-16. Hệ thống chuyển phiên bản `RETIRED`, yêu cầu PH-03 gỡ route và consumer, chuyển các gói còn lại sang `CLOSED`.
5. Hệ thống giữ chỗ context-path 12 tháng, giữ vĩnh viễn đặc tả và lịch sử, chuyển mục danh mục sang "Đã ngừng", xếp bản ghi rút danh mục quốc gia (UC-02-29), phát EVT-02-06 và thông báo `RETIREMENT` cho chủ dịch vụ, người duyệt và các bên từng đăng ký.
6. Về sau, với API `thu-nghiem-dat-dai` khai nhầm chỉ có phiên bản `DRAFT`: Lan bấm "Xóa API". Hệ thống hiện tác động (1 phiên bản, 0 đăng ký lịch sử, 0 phiên bản đang phục vụ).
7. Lan nhập lý do "Khai nhầm" và gõ lại mã API `thu-nghiem-dat-dai` để xác nhận (tuân thủ FR-00-050).
8. Hệ thống kiểm tra mọi phiên bản `DRAFT` hoặc `RETIRED` và không còn đăng ký hiệu lực, xóa mềm API (`deletedAt`), giữ chỗ mã và context-path vĩnh viễn, rút API khỏi danh mục và chỉ mục tìm kiếm, phát EVT-02-03, ghi kiểm toán, thông báo Lan và Quang, trả `204` (API-02-052).

**Luồng thay thế.**

- **A1. (bước 3) Không còn đăng ký, muốn ngừng sớm trước hạn.** Lan chọn "Ngừng sớm trước hạn"; cho phép với duyệt của Minh, không cần chờ `sunsetAt`.
- **A2. (bước 3) Hủy bản nháp.** Với phiên bản `DRAFT` chưa từng công bố, Lan nhập lý do và xác nhận; hệ thống chuyển `DRAFT` sang `RETIRED` không qua duyệt, không có route nào để gỡ.
- **A3. (sau bước 8) Quang khôi phục API đã xóa mềm trong 30 ngày.** API trở lại với phiên bản `RETIRED`, `DRAFT` như trước khi xóa (tuân thủ FR-00-051).

**Luồng ngoại lệ.**

- **E1. Còn đăng ký hiệu lực khi ngừng hẳn (bước 3).** ERR-02-030 (409); "Còn {n} bên đang dùng phiên bản này. Chuyển hoặc thu hồi đăng ký trước, hoặc lùi hạn ngừng."
- **E2. Còn phiên bản đang chạy hoặc còn đăng ký khi xóa (bước 8).** ERR-02-030 (409); "API còn phiên bản đang phục vụ hoặc còn {n} bên đăng ký. Ngừng dùng có báo trước trước khi xóa."
- **E3. Phiên bản không `DEPRECATED` hoặc `DRAFT` (bước 3).** ERR-02-011 (409); "Chỉ phiên bản đã ngừng khuyến nghị mới ngừng hẳn được."
- **E4. Thiếu lý do (bước 3, 7).** ERR-02-041 (400); "Cần nêu lý do." hoặc "Cần nêu lý do xóa."
- **E5. Gõ sai mã xác nhận (bước 7).** ERR-02-003 (400); "Mã xác nhận không khớp."
- **E6. PH-03 không gỡ được route (bước 4).** ERR-02-033 (503); phiên bản giữ `DEPRECATED` cho tới khi gỡ xong; cảnh báo TO.
- **E7. Không có quyền xóa (bước 6).** ERR-02-014 (403); "Bạn không thuộc đơn vị chủ quản của HTTT này."

**Quy tắc áp dụng.** BR-02-006, 008, 014, 020, 021, 028, 029.

**Màn hình, API.** UI-02-13, 02, 10; API-02-051, 052, 044.
:::

### 6.21. UC-02-21 · Đặt mức hiển thị và hiện ở cổng nhà phát triển

::: dac-ta
**Mục tiêu.** Chủ dịch vụ quyết định API được thấy tới đâu: chỉ HTTT trong tỉnh, lên danh mục quốc gia cho cơ quan khác, hoặc công khai ở cổng nhà phát triển; hệ thống chặn mức hiển thị trái mức phân loại dữ liệu.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan); `ROLE-CATALOG_APPROVER` (Minh) duyệt khi nâng mức.

**Tác nhân phụ.** PH-15 (hiển thị theo `portalPublished`), UC-02-29 (đồng bộ quốc gia), UC-02-33 (thông báo khi hạ mức).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-041.

**Truy vết.** REQ-02, REQ-15; quy trình Công bố dịch vụ; LGC-APIM-006 (LGC-APIM-007 thuộc PH-15, PH-02 giữ thuộc tính).

**Tiền điều kiện.** API `danh-muc-dan-toc` (mức `PUBLIC`) có phiên bản `PUBLISHED`, mức hiển thị hiện tại `TENANT`; Lan có `PERM-02-submit`.

**Kích hoạt.** Lan sửa khối "Hiển thị" ở tab Tổng quan của UI-02-02.

**Đảm bảo tối thiểu.** Mức hiển thị luôn hợp lệ với `dataClass` (BR-02-037); hạ mức có hiệu lực ngay; nâng mức không có hiệu lực cho tới khi có duyệt.

**Đảm bảo thành công.** API có mức hiển thị mới; PH-15 phản ánh trong vài giây; bản ghi đồng bộ quốc gia được xếp khi cần.

**Luồng chính.**

1. Lan chọn mức `PUBLIC` và bật công tắc "Hiện ở cổng nhà phát triển"; hệ thống giải thích hệ quả từng mức.
2. Hệ thống kiểm tra BR-02-037: `PUBLIC` chỉ với dữ liệu `PUBLIC` (đạt).
3. Vì là nâng mức, Lan nhập lý do "Công khai danh mục dân tộc cho nhà phát triển"; hệ thống tạo yêu cầu duyệt `VISIBILITY_RAISE` (API-02-053).
4. Minh duyệt theo UC-02-16.
5. Hệ thống áp mức `PUBLIC`, đặt `portalPublished = true`, cập nhật danh mục, xếp đồng bộ quốc gia (UC-02-29), phát EVT-02-02 với `changedFields = visibility, portalPublished`, ghi kiểm toán (mức trước, sau, lý do, người duyệt).
6. PH-15 chỉ hiển thị API có phiên bản `PUBLISHED`, `DEPRECATED` và `portalPublished = true` theo đúng mức của người xem.
7. Về sau Lan hạ mức xuống `TENANT`: hệ thống áp ngay, cập nhật danh mục, phát sự kiện cho PH-15, xếp bản ghi rút ở danh mục quốc gia và gửi thông báo `VISIBILITY_LOWERED`.

**Luồng thay thế.**

- **A1. (bước 1) Chỉ gỡ khỏi cổng.** Lan tắt công tắc "Hiện ở cổng nhà phát triển" mà giữ mức hiển thị; có hiệu lực ngay, không cần duyệt.
- **A2. (bước 1) API `tra-cuu-ho-tich` mức `RESTRICTED` chọn `NATIONAL`.** Hợp lệ (chỉ `SENSITIVE` không được `NATIONAL`) nhưng vẫn cần duyệt vì là nâng mức.
- **A3. (bước 7) Đang có bên ngoài tenant đã gọi qua Nền tảng quốc gia.** Hệ thống cảnh báo trước khi áp và thông báo bên đăng ký.

**Luồng ngoại lệ.**

- **E1. Mức không phù hợp mức phân loại (bước 2).** ERR-02-043 (422); "Mức hiển thị {mức} không phù hợp với dữ liệu mức {phân loại}." Ví dụ `PUBLIC` cho `tra-cuu-ho-tich` mức `RESTRICTED`.
- **E2. Nâng mức không có lý do (bước 3).** ERR-02-041 (400); "Cần nêu lý do nâng mức hiển thị."
- **E3. API chưa công bố mà đòi hiện ở cổng (bước 1).** ERR-02-011 (409); "API chưa công bố nên chưa hiện ở cổng nhà phát triển được."
- **E4. Người gửi tự duyệt (bước 4).** ERR-02-013 (403); "Bạn là người gửi duyệt hoặc sửa gần nhất nên không được tự duyệt."

**Quy tắc áp dụng.** BR-02-008, 009, 037.

**Màn hình, API.** UI-02-02 (tab Tổng quan), 10; API-02-053, 044.
:::

### 6.22. UC-02-22 · Chuyển chủ quản API

::: dac-ta
**Mục tiêu.** Khi sáp nhập hoặc đổi tổ chức, quản trị tenant chuyển trách nhiệm một API sang đơn vị khác để API không "mồ côi" mà bên khai thác không bị gián đoạn.

**Tác nhân chính.** `ROLE-TENANT_ADMIN` (Quang); PA cùng quyền quản trị phân hệ.

**Tác nhân phụ.** PH-01 (kiểm tra đơn vị, HTTT đích), UC-02-33 (thông báo thông tin).

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-02-045.

**Truy vết.** REQ-02; quy trình Quản trị (sáp nhập, đổi tổ chức); Q02-07; không có LGC (năng lực mới).

**Tiền điều kiện.** Quang có quyền quản trị phân hệ (đề nghị, động từ `admin`); API chưa xóa; đơn vị `SO-NOIVU` và HTTT `HT-NOIVU` `ACTIVE` ở PH-01.

**Kích hoạt.** Quang chọn "Chuyển chủ quản" ở menu "⋯" của UI-02-02.

**Đảm bảo tối thiểu.** Không thay đổi người đã gửi duyệt (để kiểm toán); không sửa tự động backend loại `SYSTEM` còn trỏ HTTT cũ; không gián đoạn API đang chạy.

**Đảm bảo thành công.** API có chủ quản mới; quyền sửa của SV theo đơn vị mới; việc rà soát backend được giao.

**Luồng chính.**

1. Quang chọn đơn vị chủ quản mới `SO-NOIVU` và HTTT cung cấp mới `HT-NOIVU` cho API `ho-so-dat-dai` (API-02-057).
2. Hệ thống kiểm tra đơn vị và HTTT đích tồn tại và `ACTIVE` ở PH-01.
3. Hệ thống hiện tác động: 1 yêu cầu duyệt đang chờ, 2 đăng ký chờ duyệt, SV của đơn vị cũ sẽ mất quyền sửa, 2 backend loại `SYSTEM` còn trỏ HTTT cũ.
4. Quang nhập lý do "Sáp nhập Sở theo Nghị quyết số 12/NQ-HĐND" và số văn bản, xác nhận (tuân thủ FR-00-050).
5. Hệ thống đổi `ownerOrgCode`, `providerSystemCode`; chuyển các yêu cầu duyệt đang chờ cho người có quyền của đơn vị mới, giữ nguyên người đã gửi.
6. Hệ thống cảnh báo các backend `SYSTEM` còn dùng kết nối của HTTT cũ và giao SV mới rà soát trong 30 ngày (không đổi tự động).
7. Hệ thống thông báo đơn vị cũ, đơn vị mới và bên đăng ký (thông tin, không bắt buộc, loại `OWNER_CHANGED`), phát EVT-02-02 (`changedFields = ownerOrgCode, providerSystemCode`) và ghi kiểm toán (đơn vị cũ, mới, HTTT cũ, mới, lý do, số văn bản).

**Luồng thay thế.**

- **A1. (bước 1) Chỉ đổi HTTT cung cấp, giữ đơn vị chủ quản.** Hệ thống bỏ việc chuyển yêu cầu duyệt ở bước 5.
- **A2. (bước 5) API có yêu cầu đang xử lý khóa nội dung.** Hệ thống không chặn; yêu cầu đi theo đơn vị mới.

**Luồng ngoại lệ.**

- **E1. Đơn vị hoặc HTTT đích không hợp lệ (bước 2).** ERR-02-004 (422); "HTTT hoặc đơn vị đích không tồn tại hoặc chưa hoạt động."
- **E2. Thiếu lý do (bước 4).** ERR-02-041 (400); "Cần nêu lý do chuyển chủ quản."
- **E3. Không có quyền (bước 1).** ERR-02-014 (403); "Bạn không có quyền chuyển chủ quản API."

**Quy tắc áp dụng.** BR-02-028, 032.

**Màn hình, API.** UI-02-02; API-02-057.
:::

### 6.23. UC-02-23 · Gửi đăng ký sử dụng API

::: dac-ta
**Mục tiêu.** Đầu mối của một đơn vị xin dùng API của đơn vị khác cho HTTT của mình, nêu rõ mục đích và khối lượng dự kiến; chỉ HTTT đã kết nạp mới xin được nên luôn có chủ thể chịu trách nhiệm.

**Tác nhân chính.** `ROLE-ORG_REQUESTER` (Hạnh, Văn phòng UBND tỉnh `VP-UBND`).

**Tác nhân phụ.** PH-01 (hồ sơ HTTT `HT-MOTCUA`), PH-13 (số liệu hạn mức), hộp "Việc của tôi" của người duyệt.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-046.

**Truy vết.** REQ-02, REQ-09, REQ-12; quy trình Khai thác dịch vụ; LGC-APIM-016; LGC-APIM-021.

**Tiền điều kiện.** Hạnh có `PERM-02-subscribe`; `HT-MOTCUA` `ACTIVE` ở PH-01 và thuộc tổ chức của Hạnh; phiên bản `tra-cuu-ho-tich 1.0.0` `PUBLISHED` và gói `tich-hop-bao-mat` `PUBLISHED` có `HT-MOTCUA` trong đối tượng được xin.

**Kích hoạt.** Hạnh bấm "Đăng ký sử dụng" ở UI-02-01 hoặc UI-02-02, mở UI-02-09.

**Đảm bảo tối thiểu.** Mỗi HTTT chỉ có một đăng ký hiệu lực cho một phiên bản (BR-02-027); đăng ký chưa được duyệt không mang phạm vi nào.

**Đảm bảo thành công.** Đăng ký `PENDING` kèm yêu cầu duyệt cho Lan và Minh (hoặc `ACTIVE` kèm tiến trình cấp phạm vi khi tự duyệt); Hạnh biết ai sẽ duyệt.

**Luồng chính.**

1. Hạnh chọn API `tra-cuu-ho-tich`, phiên bản `1.0.0` (mặc định phiên bản `PUBLISHED` mới nhất), gói `tich-hop-bao-mat`, HTTT `HT-MOTCUA`; hệ thống hiện điều khoản của gói và SLA cam kết.
2. Hệ thống kiểm tra `HT-MOTCUA` `ACTIVE` và thuộc tổ chức của Hạnh, gói `PUBLISHED`, HTTT nằm trong đối tượng được xin của gói, và chưa có đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` cho cùng phiên bản.
3. Hạnh nhập mục đích "Xác minh khai sinh khi tiếp nhận hồ sơ cấp thẻ BHYT trẻ em" (không dưới 20 ký tự), khối lượng dự kiến 3.000 lượt mỗi ngày, thao tác cần dùng `getCivilRecord`, căn cứ pháp lý "Quyết định 1234/QĐ-UBND" (bắt buộc vì API chứa dữ liệu cá nhân và ở mức `RESTRICTED`).
4. Hệ thống đối chiếu khối lượng với hạn mức của gói (20.000 lượt mỗi ngày) và hạn mức giờ cam kết SLA (5.000); không vượt nên không có cảnh báo.
5. Hạnh tick xác nhận đã đọc điều khoản. Hệ thống gọi API-02-058 kèm `Idempotency-Key` và tạo đăng ký `PENDING`.
6. Gói không bật tự duyệt, nên hệ thống tạo yêu cầu duyệt `SUBSCRIPTION` cho SV của tổ chức chủ quản API (Lan) và CA (Minh), phát EVT-02-09 và thông báo Hạnh "Đăng ký đang chờ duyệt." kèm `reviewRequestId`; trả `201`.

**Luồng thay thế.**

- **A1. (bước 6) Gói bật `autoApprove` và `dataClass` không vượt `02.subscription.auto-approve.max-class`.** Ví dụ gói `tich-hop-noi-bo` của `ho-so-dat-dai` mức `INTERNAL`: hệ thống bỏ qua duyệt, chuyển ngay `ACTIVE` và chạy UC-02-25.
- **A2. (bước 1) Phiên bản đang `DEPRECATED`.** Hệ thống cảnh báo "Phiên bản sắp ngừng, nên đăng ký phiên bản mới" và gợi ý phiên bản kế nhiệm; vẫn cho gửi nếu CA cho phép ngoại lệ cho gói `DEPRECATED`, không thì ERR-02-025.
- **A3. (bước 4) Khối lượng vượt hạn mức.** Hệ thống cảnh báo; Hạnh vẫn tiếp tục được nhưng người duyệt thấy cảnh báo.
- **A4. (sau bước 6) Hạnh rút đăng ký đang chờ.** Đăng ký chuyển `CANCELLED` (UC-02-27).
- **A5. (bước 1) Mở từ danh sách theo HTTT.** Hạnh bấm "Đăng ký phiên bản mới" ở dòng đăng ký phiên bản `DEPRECATED` của UC-02-26; UI-02-09 mở với API và phiên bản kế nhiệm điền sẵn.

**Luồng ngoại lệ.**

- **E1. HTTT chưa kết nối hoặc không hoạt động (bước 2).** ERR-02-026 (422); "HTTT {mã} chưa được kết nạp hoặc không hoạt động. Hoàn tất kết nạp ở mục Hệ thống thành viên trước."
- **E2. Gói không nhận đăng ký (bước 2).** ERR-02-025 (409); "Gói {mã} không nhận đăng ký mới. Chọn gói khác."
- **E3. HTTT ngoài đối tượng của gói (bước 2).** ERR-02-028 (422); "HTTT của bạn không thuộc nhóm được dùng gói này."
- **E4. Đã có đăng ký hiệu lực (bước 2).** ERR-02-027 (409); "HTTT đã có đăng ký {trạng thái} cho phiên bản này."
- **E5. Thiếu mục đích, khối lượng hoặc căn cứ pháp lý (bước 3).** ERR-02-029 (422); "Cần nêu mục đích và khối lượng dự kiến."
- **E6. Hạnh không phải đầu mối của đơn vị (bước 2).** ERR-02-014 (403); "Bạn không phải đầu mối của đơn vị này."
- **E7. Gửi lại cùng `Idempotency-Key` với thân khác (bước 5).** ERR-02-042 (422); "Yêu cầu trùng khóa nhưng khác nội dung. Tải lại trang rồi gửi lại."

**Quy tắc áp dụng.** BR-02-011, 012, 026, 027.

**Màn hình, API.** UI-02-09, 01, 02; API-02-058.
:::

### 6.24. UC-02-24 · Duyệt hoặc từ chối đăng ký sử dụng

::: dac-ta
**Mục tiêu.** Bên cung cấp và người duyệt dịch vụ quyết định ai được dùng API trên cơ sở mục đích, khối lượng và hồ sơ HTTT đề nghị, để dữ liệu chỉ tới đúng người cần.

**Tác nhân chính.** `ROLE-CATALOG_APPROVER` (Minh) với API mức từ `RESTRICTED`; `ROLE-SERVICE_OWNER` (Lan) với API dưới mức `RESTRICTED` của tổ chức mình.

**Tác nhân phụ.** PH-01 (hồ sơ HTTT khai thác), UC-02-25 (cấp phạm vi), hộp "Việc của tôi", trung tâm thông báo.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-047.

**Truy vết.** REQ-02, REQ-09, REQ-12; quy trình Khai thác dịch vụ; LGC-APIM-016.

**Tiền điều kiện.** Đăng ký của `HT-MOTCUA` ở `PENDING` kèm yêu cầu duyệt `SUBSCRIPTION` (UC-02-23); người duyệt có `PERM-02-approve-subscription` và khác người gửi.

**Kích hoạt.** Minh mở yêu cầu từ "Việc của tôi" (UI-02-10), hoặc từ tab Đăng ký của UI-02-02.

**Đảm bảo tối thiểu.** Không đăng ký nào `ACTIVE` khi chưa có quyết định hợp lệ; từ chối luôn kèm lý do gửi lại cho người gửi.

**Đảm bảo thành công.** Đăng ký `ACTIVE` kèm `decidedBy`, `decidedAt`, `expiresAt` và đã chuyển sang UC-02-25; hoặc `REJECTED` kèm lý do.

**Luồng chính.**

1. Minh mở yêu cầu. Hệ thống hiện mục đích, khối lượng 3.000 lượt mỗi ngày, căn cứ pháp lý, hồ sơ `HT-MOTCUA` ở PH-01 (đơn vị, cấp độ ATTT, đầu mối), lịch sử đăng ký trước và cảnh báo hạn mức (không có).
2. Hệ thống kiểm tra Minh khác người gửi (Hạnh) và có quyền với API này (luồng phụ LP-02-01).
3. Vì API mức `RESTRICTED`, hệ thống yêu cầu quyết định của CA hoặc TA; Lan có thể bấm "Đề xuất duyệt" nhưng SV một mình không đủ (BR-02-026).
4. Minh chọn "Duyệt" kèm ý kiến, đặt hạn mức riêng `approvedDailyCalls = 2000` thấp hơn gói và `expiresAt = 26/11/2027` (API-02-044, 045, 046).
5. Hệ thống chuyển đăng ký `ACTIVE`, ghi `decidedBy`, `decidedAt`, `expiresAt`, rồi chạy UC-02-25.
6. Hệ thống ghi kiểm toán (người duyệt, quyết định, ý kiến, hạn mức riêng, thời hạn), thông báo Hạnh và đầu mối kỹ thuật của `HT-MOTCUA` (không kèm dữ liệu Hạn chế qua thư) và phát EVT-02-10 khi cấp thành công.

**Luồng thay thế.**

- **A1. (bước 4) Minh từ chối.** Đăng ký chuyển `REJECTED`; ý kiến bắt buộc được gửi lại Hạnh; hệ thống phát EVT-02-11.
- **A2. (bước 4) Minh chọn "Hỏi thêm".** Đăng ký giữ `PENDING` kèm câu hỏi; Hạnh trả lời ngay trên yêu cầu; không tính là quyết định.
- **A3. (bước 1) Lan duyệt đăng ký của API dưới mức `RESTRICTED`.** Lan có `PERM-02-approve-subscription` với API của tổ chức mình nên duyệt trực tiếp, cùng luồng từ bước 2 (Lan khác người gửi).
- **A4. Yêu cầu quá `02.review.overdue-days` ngày làm việc.** Hệ thống nhắc người duyệt và báo TA (EVT-02-16).

**Luồng ngoại lệ.**

- **E1. Người duyệt cũng là người gửi (bước 2).** ERR-02-013 (403); "Bạn là người gửi đăng ký này nên không được tự duyệt."
- **E2. Từ chối không có lý do (bước 4).** ERR-02-041 (400); "Cần nêu lý do từ chối."
- **E3. SV duyệt một mình dữ liệu từ `RESTRICTED` (bước 3).** ERR-02-014 (403); "Dữ liệu mức {mức} cần người duyệt dịch vụ quyết định."
- **E4. Đăng ký đã có quyết định (bước 1).** ERR-02-011 (409); "Đăng ký này đã được xử lý."
- **E5. HTTT khai thác không còn `ACTIVE` lúc duyệt (bước 5).** ERR-02-026 (422); "HTTT {mã} không còn hoạt động, không duyệt được."

**Quy tắc áp dụng.** BR-02-008, 012, 026.

**Màn hình, API.** UI-02-10; API-02-044, 098, 045, 046.
:::

### 6.25. UC-02-25 · Cấp phạm vi truy cập theo đăng ký đã duyệt

::: dac-ta
**Mục tiêu.** Biến đăng ký đã duyệt thành quyền gọi thật một cách tự động: gắn phạm vi `api:{mã API}:{mã gói}` vào định danh máy của HTTT và đăng ký HTTT làm consumer của gói ở gateway, để không ai cấp quyền bằng tay và không cấp nhầm.

**Tác nhân chính.** Bộ cấp quyền của PH-02 (máy).

**Tác nhân phụ.** PH-01 (định danh máy của HTTT), PH-12 (Keycloak, OPA), PH-03 và APISIX; `ROLE-ORG_REQUESTER` (Hạnh) khi cần xin định danh; `ROLE-TENANT_OPERATOR` (Chi) khi thử lại.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-048.

**Truy vết.** REQ-02, REQ-03, REQ-12; quy trình Khai thác dịch vụ; SEC-24, SEC-26 (năng lực mới, không có LGC).

**Tiền điều kiện.** Đăng ký `ACTIVE` của `HT-MOTCUA` chưa có `grantStatus = GRANTED`; `HT-MOTCUA` có định danh máy ở PH-01 (client Keycloak `ht-motcua` và chứng thư vì gói `OAUTH2_MTLS`).

**Kích hoạt.** Ngay sau UC-02-24 duyệt, hoặc sau tự duyệt ở UC-02-23, hoặc khi Chi bấm "Cấp lại" (API-02-068).

**Đảm bảo tối thiểu.** Không bao giờ cấp lỏng: thiếu định danh thì chờ, không bỏ qua; không có đường cấp tay (BR-02-025); phần đã gắn thành công không bị gỡ vội để tránh trạng thái nửa vời mà được đánh dấu để dọn.

**Đảm bảo thành công.** `grantStatus = GRANTED`; phạm vi gắn ở Keycloak; consumer gắn ở gateway; thời gian từ duyệt tới gọi được p95 ≤ 30 giây (NFR-02-005).

**Luồng chính.**

1. Hệ thống tính phạm vi `api:tra-cuu-ho-tich:tich-hop-bao-mat` và, vì đăng ký giới hạn thao tác, phạm vi con `api:tra-cuu-ho-tich:tich-hop-bao-mat:getCivilRecord`.
2. Hệ thống hỏi PH-01 định danh máy của `HT-MOTCUA` phù hợp kiểu xác thực của gói; nhận client `ht-motcua` và chứng thư.
3. Hệ thống yêu cầu PH-12 gắn phạm vi vào client Keycloak và cập nhật chính sách OPA theo phạm vi; chờ xác nhận.
4. Hệ thống yêu cầu PH-03 thêm consumer vào nhóm của gói kèm hạn mức riêng 2.000 lượt mỗi ngày; PH-03 sinh ảnh chụp cấu hình mới và chờ APISIX xác nhận nạp (luồng phụ LP-02-02).
5. Đủ hai xác nhận, hệ thống đặt `grantStatus = GRANTED` và `grantedAt`, thông báo `HT-MOTCUA` "Đã cấp quyền, bạn có thể gọi API" kèm đường dẫn (UC-02-01 bước 5).
6. Hệ thống ghi kiểm toán (phạm vi cấp, client, kết quả từng bên, số lần thử) và phát EVT-02-10.

**Luồng thay thế.**

- **A1. (bước 2) `HT-MOTCUA` chưa có định danh máy.** Hệ thống đặt `grantStatus = AWAITING_CREDENTIAL` và tạo việc cho Hạnh "Xin cấp định danh ứng dụng ở mục Hệ thống thành viên"; không phải lỗi; tiếp tục tự động từ bước 3 khi PH-01 cấp xong.
- **A2. (bước 3) Gói `KEYLESS` hoặc `API_KEY`.** Gói `KEYLESS` bỏ bước PH-12, chỉ cập nhật bộ đếm hạn mức theo IP ở PH-03; gói `API_KEY`: khóa do PH-01 cấp, PH-03 giữ băm khóa.
- **A3. (bước 5) Chi bấm "Cấp lại".** Sau `FAILED`, Chi gọi API-02-068; hệ thống chạy lại từ bước 1.
- **A4. (bước 3, 4) Lỗi một trong hai bên.** Hệ thống thử lại lùi dần tối đa 5 lần trong 15 phút; hết lần mà chưa xong thì đặt `grantStatus = FAILED` và cảnh báo TO; phần đã gắn thành công được đánh dấu để dọn.

**Luồng ngoại lệ.**

- **E1. PH-12 hoặc PH-03 không khả dụng (bước 3, 4).** ERR-02-033 (503) hoặc ERR-02-034 (503); hệ thống thử lại như A4; HTTT thấy "Quyền của HTTT đang được cấp, thử lại sau ít phút."
- **E2. Phạm vi trái chính sách (bước 2).** ERR-02-022 (422), ví dụ mức Nhạy cảm mà HTTT chưa có mTLS; đăng ký chuyển `AWAITING_CREDENTIAL` kèm hướng dẫn; "Dữ liệu mức {mức} yêu cầu xác thực {kiểu tối thiểu}. Chọn kiểu mạnh hơn."
- **E3. Hết số lần thử (A4).** `grantStatus = FAILED`, cảnh báo TO ở UI-02-12 và UI-02-17; Chi thử lại bằng A3.

**Quy tắc áp dụng.** BR-02-016, 025.

**Màn hình, API.** UI-02-08 (cột trạng thái cấp); API-02-067, 068.
:::

```{.mermaid caption="Trình tự cấp phạm vi truy cập sau khi duyệt đăng ký"}
sequenceDiagram
  autonumber
  participant CA as Minh, người duyệt
  participant C as PH-02 bộ cấp quyền
  participant P1 as PH-01
  participant P12 as PH-12 Keycloak, OPA
  participant P3 as PH-03 bộ đồng bộ cấu hình
  participant AP as APISIX
  CA->>C: Duyệt đăng ký
  C->>P1: Lấy định danh máy của HT-MOTCUA
  P1-->>C: clientId, kiểu xác thực
  C->>P12: Gắn phạm vi api:tra-cuu-ho-tich:tich-hop-bao-mat
  P12-->>C: Đã gắn
  C->>P3: Thêm consumer vào nhóm của gói
  P3->>AP: Ảnh chụp cấu hình mới
  AP-->>P3: Đã nạp
  P3-->>C: Xác nhận
  C->>C: Đặt GRANTED, ghi kiểm toán
  C-->>CA: Hoàn tất, thông báo HTTT khai thác
```

Hình trên cho thấy quyền gọi chỉ thành hình khi cả hai nơi xác nhận (định danh và gateway); thiếu một bên thì đăng ký ở trạng thái chờ cấp, không có cửa sau.

### 6.26. UC-02-26 · Xem đăng ký theo API và theo HTTT

::: dac-ta
**Mục tiêu.** Chủ dịch vụ biết ai đang dùng API của mình, theo gói nào, từ khi nào, lượt gọi ra sao; đầu mối đơn vị khai thác thấy HTTT của mình đang dùng những API nào, API nào sắp ngừng để chủ động nâng cấp.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan) xem theo API; `ROLE-ORG_REQUESTER` (Hạnh) xem theo HTTT.

**Tác nhân phụ.** PH-13 (lượt gọi 30 ngày), PH-01 (danh sách HTTT, đầu mối), `ROLE-CATALOG_APPROVER`, `ROLE-TENANT_ADMIN`, `ROLE-TENANT_OPERATOR` cùng xem ở mức tenant.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-049, 050.

**Truy vết.** REQ-02, REQ-09, REQ-12; quy trình Khai thác dịch vụ; LGC-APIM-016; LGC-APIM-021.

**Tiền điều kiện.** API và HTTT tồn tại; người dùng xem được theo vai trò và tổ chức.

**Kích hoạt.** Lan mở tab Đăng ký của UI-02-02; Hạnh mở "Kết nối & API → Đăng ký sử dụng" (`/ket-noi/dang-ky`, UI-02-08).

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; mọi người chỉ thấy phần được phép (BR-02-033); CA, TA xem chi tiết đăng ký của API không thuộc tổ chức mình được ghi kiểm toán mức tóm tắt.

**Đảm bảo thành công.** Người dùng có danh sách đăng ký lọc, phân trang kèm thẻ tổng và nút hành động hợp lệ.

**Luồng chính.**

1. Lan mở tab Đăng ký của `tra-cuu-ho-tich`. Hệ thống kiểm tra Lan thuộc tổ chức chủ quản (quyền xem chi tiết).
2. Hệ thống truy vấn đăng ký của API theo bộ lọc và phân trang (API-02-059), mặc định ẩn trạng thái cuối (`REJECTED`, `CANCELLED`, `EXPIRED`) trừ khi lọc.
3. Hệ thống ghép lượt gọi 30 ngày và lần gọi gần nhất từ PH-13 theo từng HTTT khai thác.
4. Hệ thống tính các thẻ tổng: theo trạng thái (`ACTIVE` 4, `PENDING` 1), theo gói, 1 đăng ký sắp hết hạn trong 30 ngày, 0 đăng ký quá hạn rà soát.
5. Lan bấm dòng `HT-MOTCUA` để mở chi tiết, hoặc thao tác theo quyền (UC-02-27).
6. Hạnh mở UI-02-08. Hệ thống xác định tập HTTT Hạnh được xem: chỉ HTTT thuộc `VP-UBND` (API-02-060).
7. Hệ thống truy vấn đăng ký theo bộ lọc, kèm tên API, phiên bản, trạng thái vòng đời của phiên bản và gói; đánh dấu đăng ký trỏ phiên bản `DEPRECATED` (kèm hạn và kế nhiệm), `SUSPENDED`, và đăng ký sắp hết hạn trong 30 ngày.
8. Hệ thống trả danh sách, các thẻ tổng và nút hành động hợp lệ theo trạng thái và quyền (hủy, gia hạn, đăng ký phiên bản mới); Hạnh bấm "Xuất" để xuất danh sách (tuân thủ FR-00-030).

**Luồng thay thế.**

- **A1. (bước 1) Người dùng không đủ quyền chi tiết.** Ví dụ An (IE): chỉ thấy thẻ tổng, danh sách bị ẩn kèm "Bạn không có quyền xem danh sách bên đăng ký."
- **A2. (bước 8) Hạnh bấm "Đăng ký phiên bản mới" ở dòng trỏ tới phiên bản `DEPRECATED`.** Hệ thống mở UI-02-09 với API và phiên bản kế nhiệm điền sẵn (UC-02-23).
- **A3. (bước 7) TA, CA, TO xem theo HTTT.** Hệ thống xem được mọi HTTT trong tenant; xem hàng loạt hoặc xuất được ghi kiểm toán mức tóm tắt.

**Luồng ngoại lệ.**

- **E1. API hoặc HTTT không thuộc tập được xem (bước 1, 6).** ERR-02-001 (404); "Không tìm thấy đối tượng."
- **E2. Tham số lọc sai (bước 2, 7).** ERR-02-003 (400); danh sách giữ bộ lọc hợp lệ gần nhất.
- **E3. PH-13 không khả dụng (bước 3).** Danh sách vẫn hiện, cột lượt gọi ghi "Chưa có số liệu"; nhật ký ghi ERR-02-034.
- **E4. PH-01 không khả dụng (bước 6).** Hệ thống dùng danh sách HTTT đã đệm với nhãn "Chưa cập nhật lúc {thời điểm}"; nhật ký ghi ERR-02-034.

**Quy tắc áp dụng.** BR-02-033.

**Màn hình, API.** UI-02-02 (tab Đăng ký), 08; API-02-059, 060.
:::

### 6.27. UC-02-27 · Tạm ngừng, tiếp tục, thu hồi, hủy đăng ký

::: dac-ta
**Mục tiêu.** Chấm dứt hoặc tạm dừng quyền dùng API khi cần: cán bộ ATTT tạm ngừng khi nghi lộ định danh, bên cung cấp thu hồi khi HTTT vi phạm hoặc hết căn cứ, đơn vị khai thác tự hủy khi không còn dùng; HTTT được báo kèm lý do.

**Tác nhân chính.** `ROLE-SECURITY_OFFICER` (Dũng) tạm ngừng, tiếp tục; `ROLE-SERVICE_OWNER` (Lan) thu hồi; `ROLE-ORG_REQUESTER` (Hạnh) hủy; `ROLE-TENANT_OPERATOR` (Chi) tạm ngừng khi vận hành.

**Tác nhân phụ.** PH-03 và APISIX (gỡ, gắn consumer), PH-12 (gỡ phạm vi), PH-01 (tạm ngừng HTTT), UC-02-33 (thông báo).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-051.

**Truy vết.** REQ-02, REQ-03, REQ-12; quy trình Sự cố ATTT; LGC-APIM-016; LGC-APIM-021.

**Tiền điều kiện.** Đăng ký `ACTIVE` hoặc `SUSPENDED` (tiếp tục, thu hồi), `ACTIVE` hoặc `PENDING` (hủy); người thực hiện có quyền theo hành động (`PERM-02-operate`, `PERM-02-approve-subscription`, `PERM-02-subscribe`).

**Kích hoạt.** Người dùng bấm "Tạm ngừng", "Tiếp tục", "Thu hồi" hoặc "Hủy đăng ký" ở UI-02-08 hoặc tab Đăng ký của UI-02-02.

**Đảm bảo tối thiểu.** Với tạm ngừng và thu hồi, trạng thái chỉ đổi khi gateway đã áp dụng; thu hồi và hủy không khôi phục được; hồ sơ đăng ký giữ vĩnh viễn.

**Đảm bảo thành công.** Quyền dùng API bị chặn (hoặc phục hồi) trong ≤ 30 giây (NFR-02-005); HTTT và đầu mối đã được báo; kiểm toán ghi hành động, lý do, người thực hiện, thời điểm hiệu lực ở gateway.

**Luồng chính.**

1. Dũng mở đăng ký của `HT-YTE` ở UI-02-08, bấm "Tạm ngừng" và nhập lý do "Nghi lộ khóa riêng của client ht-yte". Hệ thống kiểm tra quyền theo hành động và đăng ký `ACTIVE`.
2. Hệ thống hiện hộp xác nhận (tuân thủ FR-00-050) nêu ảnh hưởng: `HT-YTE` sẽ không gọi được ngay, 12.400 lượt gọi 7 ngày gần đây.
3. Dũng xác nhận. Hệ thống gỡ consumer khỏi nhóm của gói qua PH-03, giữ nguyên đăng ký và phạm vi (API-02-061); khi gateway áp dụng thì đăng ký sang `SUSPENDED`.
4. Hệ thống thông báo `HT-YTE` và đầu mối kèm lý do ở mức tổng quát (UC-02-33, loại `SUBSCRIPTION_DECISION`), ghi kiểm toán và phát EVT-02-11.
5. Sau khi xử lý xong, Dũng bấm "Tiếp tục" (API-02-062). Hệ thống kiểm tra quyền theo BR-02-034 (do SO tạm ngừng vì an ninh thì chỉ SO hoặc TA tiếp tục) và `HT-YTE` vẫn `ACTIVE` ở PH-01, gắn lại consumer, rồi thông báo.
6. Thu hồi: Lan chọn đăng ký của `HT-DVC` đã hết căn cứ pháp lý, bấm "Thu hồi" (API-02-063) và nhập lý do. Hệ thống gỡ consumer, yêu cầu PH-12 gỡ phạm vi khỏi client; đăng ký sang `REVOKED`, không khôi phục được; muốn dùng lại phải gửi đăng ký mới.
7. Hủy: Hạnh bấm "Hủy đăng ký" (API-02-064) ở đăng ký của `HT-MOTCUA` mà đơn vị không còn dùng; hệ thống gỡ consumer và phạm vi, đăng ký sang `CANCELLED`.

**Luồng thay thế.**

- **A1. PH-01 tạm ngừng hoặc thu hồi một HTTT.** PH-02 tự chuyển mọi đăng ký `ACTIVE` của HTTT đó sang `SUSPENDED` với lý do `SYSTEM_SUSPENDED` và khôi phục khi HTTT `ACTIVE` lại.
- **A2. (bước 7) Hạnh hủy đăng ký còn `PENDING`.** Đăng ký sang `CANCELLED` ngay, không có gì để gỡ ở gateway.
- **A3. (bước 1) Chi (TO) tạm ngừng khi vận hành.** Cùng luồng; Chi hoặc Quang tiếp tục được.

**Luồng ngoại lệ.**

- **E1. Trạng thái không hợp lệ (bước 1).** ERR-02-011 (409); "Không thực hiện được ở trạng thái {trạng thái} hiện tại."
- **E2. Thiếu lý do khi tạm ngừng hoặc thu hồi (bước 1, 6).** ERR-02-041 (400); "Cần nêu lý do."
- **E3. Người tiếp tục không đủ quyền (bước 5).** ERR-02-014 (403); "Chỉ Cán bộ ATTT đã tạm ngừng hoặc quản trị tenant mới tiếp tục được."
- **E4. PH-03 hoặc PH-12 không nhận (bước 3, 6).** ERR-02-033 (503) hoặc ERR-02-034 (503); hệ thống thử lại, đăng ký giữ trạng thái cũ cho tới khi gateway áp dụng.

**Quy tắc áp dụng.** BR-02-028, 029, 034.

**Màn hình, API.** UI-02-08, 02; API-02-061, 062, 063, 064.
:::

### 6.28. UC-02-28 · Gia hạn và rà soát định kỳ đăng ký

::: dac-ta
**Mục tiêu.** Quyền gọi API không tồn tại mãi khi mục đích đã hết hoặc người phụ trách đã đổi: mỗi đăng ký có hạn, tới kỳ đầu mối phải xác nhận còn dùng và còn đúng mục đích; đăng ký bỏ quên tự hết hạn.

**Tác nhân chính.** Lịch của PH-02; `ROLE-ORG_REQUESTER` (Hạnh) gia hạn.

**Tác nhân phụ.** `ROLE-CATALOG_APPROVER` (Minh) xác nhận với dữ liệu từ `RESTRICTED`; PH-01 (kiểm tra HTTT); trung tâm thông báo.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-02-052.

**Truy vết.** REQ-02, REQ-09, REQ-12; quy trình Khai thác dịch vụ; LGC-APIM-016; LGC-APIM-021 (SEC-27).

**Tiền điều kiện.** Đăng ký `ACTIVE` của `HT-MOTCUA` có `expiresAt = 26/12/2026`; `02.subscription.review-months` lớn hơn 0.

**Kích hoạt.** Lịch 06:00 giờ Việt Nam hằng ngày; hoặc Hạnh bấm "Gia hạn" ở UI-02-08.

**Đảm bảo tối thiểu.** Gia hạn không làm gián đoạn quyền gọi (phạm vi, consumer giữ nguyên); đăng ký hết hạn không tự sống lại.

**Đảm bảo thành công.** `expiresAt` mới ghi kèm lịch sử gia hạn; hoặc đăng ký `EXPIRED` và quyền đã gỡ.

**Luồng chính.**

1. Ngày `26/11/2026`, lịch tìm đăng ký sẽ hết hạn trong 30 ngày, tạo việc "Rà soát đăng ký" cho Hạnh và nhắc lại ở mốc 14 và 3 ngày trước hạn.
2. Hạnh mở UI-02-08, bấm "Gia hạn", xác nhận còn dùng đúng mục đích và cập nhật khối lượng dự kiến từ 3.000 lên 3.500 lượt mỗi ngày (API-02-065).
3. Hệ thống kiểm tra `HT-MOTCUA` vẫn `ACTIVE` ở PH-01.
4. Vì API mức `RESTRICTED`, hệ thống tạo yêu cầu duyệt `SUBSCRIPTION` loại gia hạn cho Minh và trả `202`.
5. Minh duyệt theo UC-02-24; hệ thống đặt `expiresAt` bằng ngày hiện tại cộng thời hạn gói (12 tháng), ghi lịch sử gia hạn và kiểm toán (người xác nhận, mục đích cập nhật, hạn cũ, hạn mới).
6. Nếu tới hạn mà chưa gia hạn, hệ thống chuyển đăng ký `EXPIRED`, gỡ consumer và phạm vi như thu hồi (UC-02-27 bước 6), thông báo Hạnh và Lan, phát EVT-02-11; HTTT phải gửi đăng ký mới nếu muốn dùng lại.

**Luồng thay thế.**

- **A1. (bước 4) Dữ liệu thấp hơn `RESTRICTED`.** Hệ thống gia hạn tự động, không tạo yêu cầu duyệt.
- **A2. (bước 2) Hạnh chọn "Không còn dùng".** Đăng ký chuyển `CANCELLED` ngay (UC-02-27).
- **A3. Gói không thời hạn.** Đăng ký không có `expiresAt`, không vào lịch này.
- **A4. Đăng ký gần hết hạn.** UI-02-08 và tab Đăng ký gắn nhãn "Sắp hết hạn".

**Luồng ngoại lệ.**

- **E1. HTTT không còn `ACTIVE` (bước 3).** ERR-02-026 (422); "HTTT {mã} không còn hoạt động nên không gia hạn được."
- **E2. Đăng ký không còn hiệu lực khi bấm gia hạn (bước 2).** ERR-02-011 (409); "Đăng ký đã hết hạn. Gửi đăng ký mới."
- **E3. Chưa tới thời điểm cho phép gia hạn (bước 2).** ERR-02-003 (400); "Chỉ gia hạn khi còn dưới 60 ngày."

**Quy tắc áp dụng.** BR-02-012, 026, 028.

**Màn hình, API.** UI-02-08; API-02-065, 066.
:::

### 6.29. UC-02-29 · Đồng bộ danh mục lên Nền tảng quốc gia

::: dac-ta
**Mục tiêu.** Mọi API được phép công khai ngoài tỉnh (mức hiển thị `NATIONAL`, `PUBLIC`) đều có mặt trong danh mục dịch vụ chia sẻ của Nền tảng quốc gia, tự động khi công bố hoặc thay đổi và định kỳ hằng ngày, không phụ thuộc việc ai đó nhớ làm.

**Tác nhân chính.** Lịch và bộ xử lý sự kiện của PH-02 (máy); `ROLE-TENANT_OPERATOR` (Chi) khi bấm "Đồng bộ ngay".

**Tác nhân phụ.** PH-14 (bộ điều hợp quốc gia: xác thực, chữ ký, giới hạn tần suất), Nền tảng chia sẻ, điều phối dữ liệu quốc gia, bảng outbox `ph02_catalog`.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-053.

**Truy vết.** REQ-02, REQ-14; quy trình Đồng bộ danh mục quốc gia; CMP-LAW-03, CMP-LAW-19; ADR-057 (nghĩa vụ mới, không có LGC).

**Tiền điều kiện.** Có phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED` hoặc `RETIRED` của API có mức hiển thị `NATIONAL`, `PUBLIC` và `dataClass` khác `SENSITIVE`; PH-14 đã cấu hình kết nối tới Nền tảng quốc gia của `T68`; `02.sync.enabled = true`.

**Kích hoạt.** EVT-02-05, 06 (công bố, đổi trạng thái); EVT-02-02 (đổi mô tả, mức hiển thị, chủ quản); lịch `02.sync.cron` (mặc định `0 0 2 * * *` giờ Việt Nam); hoặc Chi bấm "Đồng bộ ngay" ở UI-02-12.

**Đảm bảo tối thiểu.** Lệnh đồng bộ không mất khi PH-14 ngừng (ghi cùng giao dịch với sự kiện gốc qua outbox); sự cố đồng bộ không chặn vòng đời API; gói gửi đi không bao giờ chứa backend, địa chỉ nội bộ, danh sách bên đăng ký hay dữ liệu cá nhân.

**Đảm bảo thành công.** Bản ghi đồng bộ `ACKED` kèm `nationalRef`, `ackedAt`; danh mục quốc gia có (hoặc rút) mục tương ứng; EVT-02-14 đã phát.

**Luồng chính.**

1. Sau khi Lan nâng `danh-muc-dan-toc` lên `PUBLIC` được duyệt (UC-02-21), hệ thống chọn các phiên bản cần gửi: đủ điều kiện (mức hiển thị, `dataClass`, trạng thái) và băm nội dung hiện tại khác băm lần `ACKED` gần nhất (hoặc chưa từng gửi).
2. Hệ thống dựng gói thông tin dịch vụ theo định dạng Nền tảng quốc gia (ánh xạ cấu hình ở PH-14): mã dịch vụ quốc gia, tên, mô tả, đơn vị chủ quản, loại dữ liệu, mức phân loại, địa chỉ gọi công khai, liên kết tới đặc tả, phạm vi cần có, SLA cam kết, trạng thái, phiên bản, đầu mối.
3. Hệ thống ghi bản ghi đồng bộ `QUEUED` kèm `payloadHash` trong cùng giao dịch với sự kiện gốc (outbox).
4. Bộ gửi lấy tối đa 50 bản ghi mỗi lượt (`02.sync.batch-size`) và gửi sang PH-14 với `Idempotency-Key` là `payloadHash`.
5. PH-14 gọi Nền tảng quốc gia bằng thông tin xác thực và chứng thư của tenant; nhận xác nhận, PH-14 báo lại; hệ thống đặt bản ghi `ACKED`, lưu `nationalRef`, `ackedAt`.
6. Hệ thống phát EVT-02-14 mỗi lần đổi trạng thái đồng bộ và cập nhật chỉ số `catalog_national_sync_status`.
7. Mỗi ngày 02:00, lịch đối chiếu băm toàn bộ API đủ điều kiện, quét cả bản ghi `FAILED`, `REJECTED` có thể thử lại; khi API bị xóa, hạ mức xuống `TENANT` hoặc phiên bản `RETIRED`, hệ thống gửi bản ghi rút `WITHDRAW` thay cho bản ghi đăng ký.

**Luồng thay thế.**

- **A1. (bước 5) Nền tảng quốc gia từ chối.** Bản ghi `REJECTED` kèm mã và lý do của nền tảng; hệ thống thông báo Lan và Chi (xử lý ở UC-02-30).
- **A2. (bước 5) Lỗi tạm thời, hết thời gian chờ.** Bản ghi `FAILED`, thử lại lùi dần sau 1, 5, 15, 60 phút rồi mỗi 6 giờ.
- **A3. (bước 1) PH-14 chưa triển khai hoặc tenant chưa bật kết nối quốc gia (`02.sync.enabled = false`).** Hệ thống vẫn ghi bản ghi `QUEUED`, hiện "Chờ kết nối Nền tảng quốc gia" và không tính quá hạn.
- **A4. (bước 1) Chi bấm "Đồng bộ ngay".** Chi chọn `scope = ALL_PENDING` hoặc danh sách API; hệ thống trả `202` kèm `syncRunId` (API-02-069) rồi chạy từ bước 2.

**Luồng ngoại lệ.**

- **E1. PH-14 hoặc Nền tảng quốc gia không khả dụng (bước 4, 5).** ERR-02-034 (503); bản ghi `FAILED` vào hàng thử lại; khi Chi bấm tay, "Chưa kết nối được Nền tảng quốc gia. Yêu cầu đã xếp hàng."
- **E2. Nền tảng quốc gia từ chối (A1).** Thông báo "Nền tảng quốc gia từ chối API {mã}: {lý do}. Sửa thông tin rồi gửi lại." hiện ở UI-02-12 và gửi Lan, Chi.
- **E3. API chưa đủ điều kiện khi bấm gửi tay (A4).** ERR-02-044 (409); "API {mã} chưa đủ điều kiện đồng bộ quốc gia (chưa công bố hoặc mức hiển thị là nội bộ)."
- **E4. Đang có lần gửi cho cùng API (bước 4, A4).** ERR-02-035 (409); "Đang đồng bộ API này."

**Quy tắc áp dụng.** BR-02-009, 037.

**Màn hình, API.** UI-02-12; API-02-069, 071, 095 (tiến độ tác vụ); sự kiện EVT-02-14.
:::

### 6.30. UC-02-30 · Theo dõi đồng bộ, thử lại và xử lý quá hạn

::: dac-ta
**Mục tiêu.** Cán bộ vận hành biết API nào đã lên danh mục quốc gia, API nào bị từ chối hoặc kẹt, xử lý từng trường hợp và được cảnh báo khi quá hạn đăng ký, để nghĩa vụ pháp lý không rơi vào im lặng.

**Tác nhân chính.** `ROLE-TENANT_OPERATOR` (Chi); `ROLE-TENANT_ADMIN` (Quang).

**Tác nhân phụ.** `ROLE-SERVICE_OWNER` (Lan) sửa thông tin bị từ chối; UC-02-29 (gửi lại); PH-13 và trung tâm thông báo (cảnh báo tuân thủ).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-054.

**Truy vết.** REQ-02, REQ-14; quy trình Đồng bộ danh mục quốc gia; CMP-LAW-03 (không có LGC).

**Tiền điều kiện.** Có bản ghi đồng bộ; Chi và Quang có `PERM-02-operate`.

**Kích hoạt.** Chi mở UI-02-12 (`/ket-noi/dong-bo-quoc-gia`); hoặc lịch kiểm tra quá hạn mỗi giờ.

**Đảm bảo tối thiểu.** Cảnh báo quá hạn luôn bật khi còn API quá hạn; xem trạng thái không ghi kiểm toán, lệnh thử lại và gửi lại có ghi.

**Đảm bảo thành công.** Bản ghi mới `QUEUED` được tạo khi thử lại, gửi lại; Chi và Quang biết tức thì tình trạng tuân thủ.

**Luồng chính.**

1. Chi mở UI-02-12. Hệ thống hiện các thẻ tổng (API-02-070): Đã đồng bộ 41, Đang chờ 2, Lỗi tạm thời 1, Bị từ chối 1, Quá hạn 1, kèm thời điểm đồng bộ thành công gần nhất.
2. Hệ thống liệt kê bản ghi theo bộ lọc: mỗi dòng có API, phiên bản, hành động, trạng thái, số lần thử, lý do, thời điểm; mục quá hạn nổi lên đầu.
3. Hệ thống xác định quá hạn là API đủ điều kiện đồng bộ mà chưa có bản ghi `ACKED` cho phiên bản hiện tại sau `02.sync.overdue-days` (7 ngày); cờ quá hạn hiện cả ở thẻ "Cần chú ý" của UI-02-01.
4. Chi mở bản ghi bị từ chối của `ho-so-dat-dai` với lý do "thiếu mô tả đơn vị chủ quản"; hệ thống tạo việc cho Lan sửa thông tin.
5. Lan sửa mô tả; Chi bấm "Gửi lại" (API-02-071). Hệ thống tạo bản ghi `QUEUED` mới và UC-02-29 chạy từ bước 2.
6. Khi có API quá hạn, hệ thống gửi cảnh báo tuân thủ cho Quang và Chi qua trung tâm thông báo (tuân thủ FR-00-060) và cập nhật chỉ số `catalog_national_sync_overdue_total` ở PH-13; nhắc lại hằng ngày tới khi xử lý.
7. Hệ thống gom các từ chối theo mã lý do để Quang nhận ra lỗi hệ thống (ví dụ sai ánh xạ ở PH-14) thay vì lỗi của từng chủ dịch vụ.

**Luồng thay thế.**

- **A1. (bước 4) Bản ghi từ chối do dữ liệu chủ dịch vụ khai.** Hệ thống tạo việc cho SV sửa rồi tự gửi lại khi sửa xong, không cần Chi bấm.
- **A2. (bước 5) Bản ghi `FAILED`.** Chi bấm "Thử lại" thay cho "Gửi lại"; cùng luồng.

**Luồng ngoại lệ.**

- **E1. API chưa đủ điều kiện khi gửi lại (bước 5).** ERR-02-044 (409); "API {mã} chưa đủ điều kiện đồng bộ quốc gia."
- **E2. Đang có lần gửi cho cùng API (bước 5).** ERR-02-035 (409); "Đang đồng bộ API này."
- **E3. Người bấm không có quyền (bước 5).** ERR-02-014 (403); "Bạn không có quyền chạy đồng bộ."
- **E4. PH-14 không khả dụng khi bấm gửi (bước 5).** ERR-02-034 (503); "Chưa kết nối được Nền tảng quốc gia. Yêu cầu đã xếp hàng."

**Quy tắc áp dụng.** BR-02-009, 029.

**Màn hình, API.** UI-02-12, 01; API-02-070, 071, 072.
:::

### 6.31. UC-02-31 · Khai báo cam kết chất lượng dịch vụ (SLA)

::: dac-ta
**Mục tiêu.** Chủ dịch vụ nêu rõ API cam kết điều gì (độ trễ, tỷ lệ sẵn sàng, số lượt tối đa mỗi giờ, giờ phục vụ) để bên khai thác biết trước và hệ thống có chuẩn đối chiếu ở UC-02-32.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan).

**Tác nhân phụ.** UC-02-33 (thông báo khi cam kết kém đi), PH-13 (số đo năng lực backend để cảnh báo).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-055.

**Truy vết.** REQ-02, REQ-13, REQ-16; quy trình Công bố dịch vụ; không có LGC (năng lực mới).

**Tiền điều kiện.** Phiên bản `DRAFT` (khai lần đầu) hoặc `PUBLISHED`, `SUSPENDED`, `DEPRECATED` (sửa); Lan có `PERM-02-create`.

**Kích hoạt.** Lan sửa khối "Cam kết chất lượng" ở tab SLA của UI-02-02, hoặc bước 4 của UI-02-03.

**Đảm bảo tối thiểu.** Cam kết kém đi không có hiệu lực ngay mà chỉ sau thời gian báo trước; lịch sử cam kết giữ vĩnh viễn.

**Đảm bảo thành công.** API có cam kết SLA rõ ràng, hiển thị trong danh mục cạnh số đo thực tế; điều kiện "đã khai SLA" của UC-02-15 đạt.

**Luồng chính.**

1. Lan mở tab SLA của `tra-cuu-ho-tich 1.0.0` (`DRAFT`). Hệ thống gợi ý giá trị theo `dataClass` và theo các API tương tự của tenant.
2. Lan nhập `latencyP99Ms = 3000`, `availability = 0,995`, `hourlyLimit = 5000`, `serviceHours = 07:30-17:30 T2-T6`, `maintenanceWindows = CN 00:00-04:00`, `supportContact = ht.sotuphap@t68.gov.vn` (API-02-073).
3. Hệ thống kiểm tra miền giá trị và nhất quán: hạn mức giờ cam kết không nhỏ hơn hạn mức giờ của mọi gói (nhỏ hơn thì cảnh báo ngược, UC-02-12).
4. Hệ thống đối chiếu cam kết với năng lực backend đã đo (nếu có) và cảnh báo khi cam kết cao hơn đáng kể số đo thực tế gần nhất.
5. Hệ thống lưu ngay ở bản nháp; SLA là điều kiện bắt buộc để gửi duyệt (UC-02-15).
6. Sau khi công bố, Lan nâng `availability` từ `0,995` lên `0,998`: có hiệu lực ngay. Lan hạ xuống `0,990`: hệ thống đặt `effectiveFrom` sau `02.sla.worsen-notice-days` (30 ngày) kể từ lúc thông báo và gửi thông báo bắt buộc `SLA_WORSENED` (UC-02-33, API-02-074).
7. Hệ thống ghi lịch sử cam kết (vĩnh viễn) và kiểm toán giá trị trước, sau, `effectiveFrom`; phát EVT-02-02 (`changedFields = sla`) và, khi kém đi, EVT-02-12.

**Luồng thay thế.**

- **A1. (bước 1) Lan chọn "Dùng mẫu theo mức phân loại".** Hệ thống điền giá trị mặc định nền tảng đề xuất.
- **A2. (bước 6) Cam kết kém đi đang trong thời gian báo trước.** Hệ thống lưu `effectiveFrom`, hiện cả cam kết hiện hành lẫn cam kết chờ hiệu lực; không phải lỗi.

**Luồng ngoại lệ.**

- **E1. Giá trị ngoài miền (bước 3).** ERR-02-003 (400); "Giá trị {tên trường} nằm ngoài khoảng cho phép."
- **E2. Sửa khi phiên bản đang chờ duyệt (bước 2).** ERR-02-038 (409); "Phiên bản đang chờ duyệt, không sửa được. Rút lại yêu cầu duyệt trước."
- **E3. Gửi duyệt khi chưa khai SLA (UC-02-15).** ERR-02-012 (409); "Chưa đủ điều kiện gửi duyệt: chưa khai SLA."

**Quy tắc áp dụng.** BR-02-013, 029, 031.

**Màn hình, API.** UI-02-02 (tab SLA), 03 (bước 4); API-02-073, 074.
:::

### 6.32. UC-02-32 · Chốt kỳ tuân thủ SLA và cảnh báo

::: dac-ta
**Mục tiêu.** Mỗi tháng hệ thống tự so cam kết SLA với số đo thực tế, hiển thị cả hai cạnh nhau trong danh mục để minh bạch với bên khai thác, và cảnh báo khi dịch vụ liên tục không đạt cam kết.

**Tác nhân chính.** Lịch của PH-02 (máy).

**Tác nhân phụ.** PH-13 (số đo), PH-16 (nhận chỉ số tuân thủ), trung tâm thông báo; `ROLE-SERVICE_OWNER` (Lan), `ROLE-CATALOG_APPROVER` (Minh), `ROLE-TENANT_ADMIN` (Quang) nhận cảnh báo; `ROLE-TENANT_ADMIN` chốt lại kỳ khi cần.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-056.

**Truy vết.** REQ-02, REQ-13, REQ-16; quy trình Vận hành; không có LGC (năng lực mới).

**Tiền điều kiện.** Phiên bản có cam kết SLA và đã `PUBLISHED` ít nhất một phần của kỳ.

**Kích hoạt.** Lịch 02:00 ngày 1 hằng tháng chốt kỳ trước; tính tạm theo ngày lúc 03:00 cho kỳ hiện tại; người dùng mở UI-02-11.

**Đảm bảo tối thiểu.** Không kết luận đạt hay không đạt khi chưa đủ dữ liệu (BR-02-031); khoảng tạm ngừng do quyết định quản lý, cửa sổ bảo trì đã khai và ngoài giờ phục vụ không bị tính vào lỗi.

**Đảm bảo thành công.** Kỳ tuân thủ ghi vào bảng với `met`, `status`, `consecutiveBreaches`; danh mục hiện cam kết cạnh thực tế; EVT-02-13 đã phát; PH-16 có chỉ số.

**Luồng chính.**

1. Ngày `01/12/2026` 02:00, lịch chốt kỳ `2026-11`. Hệ thống lấy từ PH-13, cho mỗi phiên bản: độ trễ p99 ở gateway, tổng lượt gọi, số lượt lỗi do hệ thống (`5xx`, hết thời gian chờ, backend không đáp ứng; không tính `4xx` do bên gọi), thời gian ngừng trong giờ phục vụ.
2. Hệ thống loại khỏi tính toán thời gian `SUSPENDED` do quyết định quản lý, cửa sổ bảo trì đã khai và thời gian ngoài giờ phục vụ.
3. Hệ thống tính tỷ lệ sẵn sàng thực tế, p99 thực tế và lượt cao nhất mỗi giờ; so từng chỉ tiêu với cam kết hiệu lực trong kỳ (kể cả cam kết kém đi theo `effectiveFrom`).
4. Với `ho-so-dat-dai 1.2.0`: kỳ có 30 ngày dữ liệu và 184.000 lượt gọi (đủ ngưỡng `02.sla.min-days-data` = 7 và `02.sla.min-calls` = 1.000); sẵn sàng thực tế `0,981` thấp hơn cam kết `0,995` nên kết luận `BREACHED`.
5. Hệ thống ghi kỳ tuân thủ (`met` đạt khi cả ba chỉ tiêu đạt) và đếm số kỳ không đạt liên tiếp: 3 (`2026-09`, `2026-10`, `2026-11`), bằng `02.sla.breach-periods`; hệ thống gửi cảnh báo cho Lan, Minh, Quang kèm gợi ý: điều chỉnh cam kết cho thực tế (UC-02-31), cải thiện backend, hoặc xem xét ngừng dùng.
6. Hệ thống phát EVT-02-13, cập nhật danh mục (cam kết cạnh thực tế, nhãn "Không đạt 3 kỳ liên tiếp") và chuyển chỉ số tuân thủ cho PH-16; API này xếp đầu danh sách ở UI-02-01 (UC-02-01 bước 1).

**Luồng thay thế.**

- **A1. (bước 4) Kỳ chưa đủ dữ liệu.** Kỳ có dưới 7 ngày dữ liệu hoặc dưới 1.000 lượt gọi: kết luận `INSUFFICIENT`, hiển thị "Chưa đủ dữ liệu", không đếm vào chuỗi không đạt.
- **A2. (sau bước 6) Quang chốt lại kỳ.** Sau khi PH-13 bổ sung dữ liệu bị trễ, Quang bấm "Chốt lại kỳ" ở UI-02-11; hệ thống tính lại và ghi `recalculatedAt`, kiểm toán người và lý do.
- **A3. (bước 1) Tính tạm theo ngày.** Lúc 03:00 hằng ngày hệ thống tính tạm cho kỳ hiện tại để UI-02-11 hiện xu hướng; không phát cảnh báo.

**Luồng ngoại lệ.**

- **E1. PH-13 không khả dụng khi chốt kỳ (bước 1).** ERR-02-034 (503) ghi nhật ký; kỳ để `PENDING`, thử lại mỗi giờ tới 24 giờ; danh mục hiển thị kỳ gần nhất kèm thời điểm.
- **E2. Phiên bản không có cam kết (bước 1).** Hệ thống bỏ qua, không phải lỗi.
- **E3. Tham số lọc ở UI-02-11 sai (khi người dùng xem).** ERR-02-003 (400).

**Quy tắc áp dụng.** BR-02-013, 031.

**Màn hình, API.** UI-02-11, 01, 02; API-02-074, 075, 097 (tổng hợp SLA toàn tenant); sự kiện EVT-02-13.
:::

### 6.33. UC-02-33 · Thông báo thay đổi cho bên khai thác

::: dac-ta
**Mục tiêu.** Mọi bên đang dùng API biết ngay khi API thay đổi theo cách ảnh hưởng tới họ (phiên bản mới phá vỡ, ngừng khuyến nghị, tạm ngừng, SLA kém đi, ngừng hẳn), và chủ dịch vụ biết ai đã nhận.

**Tác nhân chính.** Hệ thống (theo sự kiện); `ROLE-SERVICE_OWNER` (Lan) khi gửi thông báo tay.

**Tác nhân phụ.** PH-01 (đầu mối kỹ thuật), trung tâm thông báo và thư điện tử (FR-00-060), PH-15 và PH-18 (nhận EVT-02-12), bên đăng ký `HT-MOTCUA`, `HT-YTE`, `HT-DVC`.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-057.

**Truy vết.** REQ-02; quy trình Nâng phiên bản, ngừng dùng; không có LGC (năng lực mới).

**Tiền điều kiện.** Có sự kiện thuộc các loại ở bảng loại thông báo của FRS (`VERSION_PUBLISHED_BREAKING`, `DEPRECATION`, `DEPRECATION_REMINDER`, `SUSPENSION`, `RESUMPTION`, `RETIREMENT`, `SLA_WORSENED`, `VISIBILITY_LOWERED`, `SUBSCRIPTION_DECISION`, `ANNOUNCEMENT`, `OWNER_CHANGED`); có ít nhất một bên nhận.

**Kích hoạt.** Hệ thống nhận sự kiện từ UC-02-14, 16, 17, 19, 20, 21, 22, 27, 31; hoặc Lan bấm "Gửi thông báo" ở UI-02-13.

**Đảm bảo tối thiểu.** Thông báo bắt buộc không tắt được ở phía bên nhận; nội dung không bao giờ chứa dữ liệu Hạn chế hay Nhạy cảm (tuân thủ FR-00-062); thư điện tử chỉ chứa liên kết vào ứng dụng.

**Đảm bảo thành công.** Mọi bên nhận có bản ghi `SENT` (hoặc `READ`); trong ứng dụng ≤ 15 phút, thư ≤ 1 giờ (NFR-02-015); Lan thấy trạng thái từng bên.

**Luồng chính.**

1. Sau khi Minh duyệt ngừng khuyến nghị `ho-so-dat-dai 1.2.0` (UC-02-19), hệ thống xác định bên nhận: HTTT có đăng ký `PENDING`, `ACTIVE`, `SUSPENDED` của phiên bản (5 bên), gộp trùng theo HTTT, kèm đầu mối kỹ thuật từ PH-01.
2. Hệ thống dựng nội dung từ mẫu loại `DEPRECATION`: API, phiên bản, điều thay đổi, thời điểm hiệu lực `31/05/2027`, việc bên nhận cần làm, liên kết tới chi tiết.
3. Hệ thống gửi qua thông báo trong ứng dụng, thư điện tử tới đầu mối kỹ thuật (chỉ chứa liên kết) và phát EVT-02-12 cho PH-15 (đăng trên trang tài liệu) và PH-18.
4. Loại bắt buộc (BR-02-029) không cho bên nhận tắt; loại thông tin tuân theo tùy chọn kênh của người dùng (tuân thủ FR-00-061).
5. Hệ thống ghi từng lần gửi `SENT`, `READ`, `FAILED` theo bên nhận; thất bại thì thử lại 3 lần (5, 30, 120 phút); vẫn thất bại thì cảnh báo Lan và đánh dấu bên nhận chưa nhận được trên UI-02-13.
6. Lan mở UI-02-13 và gửi thông báo tay loại `ANNOUNCEMENT`: tiêu đề "Bảo trì 02/12/2026 00:00-04:00", nội dung không quá 2.000 ký tự, `audience = ALL_ACTIVE` (API-02-076); hệ thống gửi theo bước 3 đến 5 và trả `202` kèm `noticeId`, số bên nhận (API-02-077 xem trạng thái từng bên).

**Luồng thay thế.**

- **A1. (bước 1) Không có bên nhận.** Hệ thống bỏ qua, ghi `NO_RECIPIENTS`; không phải lỗi.
- **A2. (bước 6) Thông báo tay nhiều lần.** Loại thông tin, tối đa `02.notice.announcement-max-per-day` (3) lần mỗi API mỗi ngày.
- **A3. (bước 6) `audience` là `PLAN` hoặc `SYSTEMS`.** Hệ thống chỉ gửi cho bên đăng ký của gói hoặc danh sách HTTT đã chọn.

**Luồng ngoại lệ.**

- **E1. Gửi thư thất bại hoặc không có đầu mối (bước 3, 5).** ERR-02-034 chỉ ghi nhật ký; thông báo trong ứng dụng vẫn gửi; cảnh báo Lan "Không gửi được thư tới {HTTT}."
- **E2. Thông báo tay vượt số lần cho phép (bước 6).** ERR-02-036 (429); "Đã gửi quá số thông báo cho phép hôm nay."
- **E3. Thiếu tiêu đề hoặc nội dung (bước 6).** ERR-02-003 (400); "Cần nhập tiêu đề và nội dung."

**Quy tắc áp dụng.** BR-02-004, 029.

**Màn hình, API.** UI-02-13; API-02-076, 077; sự kiện EVT-02-12.
:::

### 6.34. UC-02-34 · Xem thống kê sử dụng dịch vụ

::: dac-ta
**Mục tiêu.** Chủ dịch vụ, người duyệt và quản trị thấy mức sử dụng thực của từng API (số lượt, số bên dùng, tỷ lệ lỗi, độ trễ, xu hướng, API không ai dùng) làm căn cứ duy trì, nâng cấp hay ngừng dịch vụ.

**Tác nhân chính.** `ROLE-SERVICE_OWNER` (Lan), `ROLE-CATALOG_APPROVER` (Minh), `ROLE-TENANT_ADMIN` (Quang); VW chỉ xem số tổng.

**Tác nhân phụ.** PH-13 (chuỗi số đo), PH-16 (nhận chỉ số tổng).

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-02-058.

**Truy vết.** REQ-02, REQ-13, REQ-16; quy trình Vận hành; không có LGC (năng lực mới).

**Tiền điều kiện.** Phiên bản đã từng `PUBLISHED`; PH-13 có số đo.

**Kích hoạt.** Người dùng mở tab Thống kê ở UI-02-02 hoặc UI-02-11; PH-16 gọi định kỳ.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; tên bên khai thác chỉ hiện cho người có quyền chi tiết; truy cập chi tiết bên khai thác của API không thuộc tổ chức mình được ghi kiểm toán.

**Đảm bảo thành công.** Người dùng có chuỗi số liệu, xếp hạng bên khai thác, cờ API không dùng và có thể xuất bảng số liệu.

**Luồng chính.**

1. Lan mở tab Thống kê của `ho-so-dat-dai`, chọn `window = 30d`, `groupBy = day`.
2. Hệ thống gọi API-02-078, lấy từ PH-13 chuỗi thời gian theo phiên bản: số lượt gọi, số HTTT khác nhau, tỷ lệ lỗi `4xx` và `5xx`, độ trễ p50, p95, p99.
3. Hệ thống tính xu hướng so với kỳ trước (ví dụ lượt gọi tăng 12%) và xếp hạng các bên khai thác theo lượt gọi; vì Lan là SV của API này nên thấy tên từng bên, người xem khác chỉ thấy "Bên khai thác A, B…".
4. Hệ thống đánh dấu API không dùng (không có lượt gọi trong 90 ngày dù có đăng ký `ACTIVE`) và gợi ý Lan rà soát hoặc ngừng khuyến nghị (UC-02-19).
5. Hệ thống tổng hợp cấp tenant: số API theo trạng thái, tổng lượt gọi, API dùng nhiều nhất, tỷ lệ API đạt SLA (API-02-079) và chuyển chỉ số tổng cho PH-16.
6. Lan bấm "Xuất" để xuất bảng số liệu theo bộ lọc (tuân thủ FR-00-030).

**Luồng thay thế.**

- **A1. (bước 1) Khoảng thời gian tùy chọn.** Người dùng chọn bằng bộ chọn ngày; khoảng quá 12 tháng bị từ chối (ERR-02-003).
- **A2. (bước 3) Người xem chỉ có `PERM-02-read`.** Chỉ thấy số tổng và xếp hạng ẩn danh.

**Luồng ngoại lệ.**

- **E1. PH-13 không khả dụng (bước 2).** Hệ thống hiện số liệu gần nhất đã đệm: "Số liệu cập nhật lúc {thời điểm}."; nhật ký ghi ERR-02-034.
- **E2. Phiên bản chưa có số đo (bước 2).** Khung rỗng với "Chưa có số liệu sử dụng."
- **E3. Tham số khoảng thời gian sai (bước 1).** ERR-02-003 (400); "Khoảng thời gian không hợp lệ."

**Quy tắc áp dụng.** BR-02-033.

**Màn hình, API.** UI-02-11, 02 (tab Thống kê); API-02-078, 079.
:::

### 6.35. UC-02-35 · PH-03, PH-04, PH-15 đọc dữ liệu công bố qua giao diện nội bộ

::: dac-ta
**Mục tiêu.** Các phân hệ liền kề đọc dữ liệu công bố từ PH-02 theo một giao diện chuẩn, ổn định, chỉ đọc: PH-03 lấy dữ liệu để sinh ảnh chụp cấu hình gateway, PH-15 lấy danh mục để hiển thị, PH-04 lấy đặc tả để dựng luồng. Không phân hệ nào đọc thẳng bảng của PH-02.

**Tác nhân chính.** PH-03 (scope `catalog:gateway-read`), PH-15 (scope `catalog:portal-read`), PH-04 (scope `catalog:flow-sync`).

**Tác nhân phụ.** PH-13, PH-16 (scope `catalog:metrics-read`, nhận chỉ số tuân thủ ở mức tổng); APISIX (nhận ảnh chụp từ PH-03).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-059.

**Truy vết.** REQ-02, REQ-03, REQ-15; quy trình Công bố dịch vụ; ADR-013, SEC-15 (điểm nối kiến trúc, không có LGC).

**Tiền điều kiện.** Tài khoản dịch vụ của phân hệ gọi đã được cấp scope tương ứng khi triển khai (không cấp cho người hay HTTT khai thác).

**Kích hoạt.** PH-03 sau EVT-02-05, 06, 08, 10, 11 hoặc khi đối soát; PH-15 khi nạp danh mục; PH-04 khi tạo luồng từ API; PH-13, PH-16 theo lịch.

**Đảm bảo tối thiểu.** Mọi giao diện chỉ đọc và idempotent, không thay đổi dữ liệu; truy cập bị từ chối được ghi nhật ký an ninh (SEC-61); sự cố của PH-02 không làm PH-03 đổi hay mất cấu hình đang chạy (NFR-02-008).

**Đảm bảo thành công.** Phân hệ gọi nhận bộ dữ liệu đúng giao diện, nhất quán với PH-02, kèm `ETag` và `X-DH-Source-Version`.

**Luồng chính.**

1. Phân hệ gọi trình token dịch vụ qua mesh mTLS; PH-02 kiểm tra danh tính SPIFFE và scope (SEC-15, SEC-26).
2. PH-03 gọi API-02-080 với `environment = PROD` và `sinceConfigVersion`. PH-02 trả bộ dữ liệu công bố: API, phiên bản `PUBLISHED`, `DEPRECATED`, `SUSPENDED`, backend kèm cấu hình cân bằng tải và kiểm tra sức khỏe, gói, đăng ký `ACTIVE` kèm consumer, thao tác từ đặc tả, cùng `sourceVersion` tăng dần và băm toàn bộ.
3. PH-03 sinh ảnh chụp cấu hình có chữ ký, đẩy xuống APISIX và báo kết quả nạp qua API-02-082 (luồng phụ LP-02-02).
4. PH-15 gọi API-02-081 với `updatedSince`, `page`, `size`; PH-02 trả danh mục như UC-02-02 kèm các mục `portalPublished`, tệp đặc tả đã gộp và danh sách mã đã gỡ.
5. PH-04 gọi API-02-007; PH-02 trả đặc tả đã gộp tham chiếu của phiên bản cùng đầu mối và nhãn phân loại (UC-02-10 bước 3).
6. PH-13, PH-16 gọi theo lịch; PH-02 trả chỉ số tuân thủ ở mức tổng (số API theo trạng thái, kỳ SLA đạt, đồng bộ quốc gia, đăng ký theo trạng thái), không chứa tên bên khai thác.
7. Mọi giao diện hỗ trợ `If-None-Match` với `ETag` và trả `304` khi chưa đổi; hợp đồng giữ tương thích ngược ở `v1` (NFR-02-018).

**Luồng thay thế.**

- **A1. (bước 2) PH-03 kéo theo sự kiện.** PH-03 nhận sự kiện báo thay đổi rồi mới gọi lấy dữ liệu.
- **A2. (bước 2) Mất sự kiện.** PH-03 gọi định kỳ 5 phút để bù (kéo theo lịch).

**Luồng ngoại lệ.**

- **E1. Thiếu scope hoặc sai danh tính (bước 1).** ERR-02-014 (403); không có màn hình, lỗi ghi nhật ký an ninh; bên gọi thấy lỗi trong nhật ký của mình.
- **E2. Môi trường không hợp lệ (bước 2).** ERR-02-003 (400).
- **E3. PH-02 đang bảo trì hoặc lỗi.** `503` kèm `Retry-After`; PH-03 giữ cấu hình đang chạy và không đổi gì (NFR-02-008); PH-15 dùng danh mục đã đệm.

**Quy tắc áp dụng.** BR-02-025, 033.

**Màn hình, API.** Không có màn riêng; API-02-080, 081, 082 (và API-02-007 cho PH-04).
:::

### 6.36. UC-02-36 · Đối soát cấu hình công bố với gateway

::: dac-ta
**Mục tiêu.** Phát hiện sớm khi cấu hình đang chạy ở gateway lệch khỏi những gì PH-02 đã công bố (route thừa, route thiếu, backend sai, consumer sai) do lỗi đồng bộ hoặc sửa tay, để không có API "ma" hay API đã công bố mà không gọi được.

**Tác nhân chính.** Lịch của PH-02 (máy, mỗi 5 phút); `ROLE-TENANT_OPERATOR` (Chi) và `ROLE-TENANT_ADMIN` (Quang) khi chạy tay và đẩy lại.

**Tác nhân phụ.** PH-03 (số phiên bản, băm cấu hình, danh sách route thực tế), APISIX, `ROLE-SECURITY_OFFICER` (Dũng) nhận cảnh báo route thừa.

**Mức ưu tiên.** C · Đợt 2.

**FR hiện thực.** FR-02-060.

**Truy vết.** REQ-02, REQ-03, REQ-13; quy trình Vận hành; ADR-013, SEC-65 (năng lực mới, không có LGC).

**Tiền điều kiện.** PH-03 cho biết số phiên bản và băm cấu hình đã nạp của từng pod APISIX ở môi trường `PROD`.

**Kích hoạt.** Lịch mỗi 5 phút; hoặc Chi bấm "Đối soát ngay" ở UI-02-17.

**Đảm bảo tối thiểu.** Route thừa không bao giờ bị tự gỡ (có thể là tấn công hoặc sửa tay), chỉ cảnh báo; lượt đối soát tự động chỉ ghi nhật ký vận hành, lệnh đẩy lại và tự sửa có ghi kiểm toán.

**Đảm bảo thành công.** Bản ghi đối soát lưu 90 ngày; `inSync = true` hoặc cảnh báo mở kèm chi tiết lệch; lệch được phát hiện ≤ 10 phút (NFR-02-020).

**Luồng chính.**

1. Lịch kích hoạt; hệ thống hỏi PH-03 số phiên bản cấu hình và băm đã nạp của từng pod APISIX ở môi trường `PROD`.
2. Hệ thống tính cấu hình mong đợi từ dữ liệu công bố (UC-02-35) và so với danh sách route, upstream, consumer thực tế do PH-03 báo.
3. Hệ thống phân loại lệch: `MISSING_ROUTE`, `EXTRA_ROUTE`, `UPSTREAM_MISMATCH`, `CONSUMER_MISMATCH`, `VERSION_BEHIND` (gateway chậm hơn phiên bản mong đợi quá 60 giây). Lượt hôm nay phát hiện `MISSING_ROUTE` cho `tra-cuu-ho-tich 1.0.0` và `EXTRA_ROUTE` `/ho-tich/thu-nghiem`.
4. Hệ thống tạo cảnh báo cho Chi và Quang, hiển thị chi tiết lệch ở UI-02-17 và gắn API vào thẻ "Cần chú ý" ở UI-02-01; riêng `EXTRA_ROUTE` báo thêm Dũng.
5. `02.reconcile.auto-repair` đang `false`, nên Chi mở UI-02-17, xem chi tiết và bấm "Đẩy lại cấu hình" cho `PROD`; hệ thống gọi PH-03 dựng lại ảnh chụp ngay (luồng phụ LP-02-02).
6. Hệ thống phát EVT-02-15, cập nhật chỉ số `catalog_gateway_drift_total` và ghi kiểm toán lệnh đẩy lại (người, môi trường, kết quả); lượt đối soát kế tiếp ghi `inSync = true`.

**Luồng thay thế.**

- **A1. (bước 5) `02.reconcile.auto-repair = true`.** Với lệch thuộc `MISSING_ROUTE`, `UPSTREAM_MISMATCH`, `CONSUMER_MISMATCH`, `VERSION_BEHIND`, hệ thống tự yêu cầu PH-03 dựng và đẩy lại; `EXTRA_ROUTE` không tự gỡ mà chỉ cảnh báo Dũng.
- **A2. (bước 1) Chi bấm "Đối soát ngay".** Hệ thống chạy ngay và trả `202`.
- **A3. (bước 3) Không có lệch.** Hệ thống ghi `inSync = true`, cập nhật chỉ số, kết thúc.

**Luồng ngoại lệ.**

- **E1. PH-03 không khả dụng (bước 1).** ERR-02-034 (503); hệ thống bỏ qua lượt, cảnh báo nếu quá 15 phút không đối soát được.
- **E2. Môi trường không có gateway (bước 1).** Hệ thống bỏ qua, ghi nhật ký.
- **E3. Đang có lần đối soát chạy (bước 1, A2).** ERR-02-035 (409); "Đang đối soát, vui lòng chờ."

**Quy tắc áp dụng.** BR-02-025.

**Màn hình, API.** UI-02-17; API-02-083, 084, 095 (tiến độ tác vụ); sự kiện EVT-02-15.
:::

### 6.37. UC-02-37 · Di trú API, gói, đăng ký từ APIM cũ

::: dac-ta
**Mục tiêu.** Đưa định nghĩa API, plan và subscription của khối API Management cũ sang danh mục mới theo cách strangler: giữ liên tục cho HTTT đang chạy nhưng buộc bổ sung phần còn thiếu (đặc tả OpenAPI, phân loại, xác thực phù hợp) và không mang khóa cũ sang.

**Tác nhân chính.** `ROLE-TENANT_ADMIN` (Quang); `ROLE-PLATFORM_ADMIN` (Hà) hỗ trợ.

**Tác nhân phụ.** PH-01 (HTTT trong `applicationMap`, định danh máy), dịch vụ quét mã độc (DD-12), kho đối tượng Garage, PH-05 (kết nối cho backend `SYSTEM` về sau).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-02-061.

**Truy vết.** REQ-02, REQ-22; quy trình Di trú APIM cũ (strangler); LGC-APIM-002; LGC-APIM-003; LGC-APIM-009; LGC-APIM-016; LGC-APIM-021.

**Tiền điều kiện.** Có tệp xuất `apim-export-20261120.zip` (38 MiB, JSON của API, plan, subscription, Application) và bảng ánh xạ `applicationMap` (Application cũ sang HTTT mới) đã chuẩn bị cùng PH-01; Quang có quyền quản trị phân hệ (đề nghị, động từ `admin`).

**Kích hoạt.** Quang bấm "Nhập từ APIM cũ" ở UI-02-16 (`/ket-noi/quan-tri/nhap-apim-cu`).

**Đảm bảo tối thiểu.** Khóa và bí mật của hệ cũ không bao giờ được nhập (BR-02-036); mọi chuỗi giống khóa trong tệp bị loại và báo; ghi theo nguyên tắc tất cả hoặc không cho mỗi API; nhập lại không nhân đôi (idempotent theo `legacyId`).

**Đảm bảo thành công.** API, gói, đăng ký mới nằm ở `DRAFT`, `STAGING`, `SUSPENDED`; báo cáo đối chiếu số lượng khớp nguồn; không khóa API nào được nhập.

**Luồng chính.**

1. Quang tải tệp gói xuất và `applicationMap`. Hệ thống quét mã độc, kiểm tra định dạng và kích thước ≤ 50 MiB.
2. Quang chạy `mode = PREVIEW` (API-02-085). Hệ thống phân tích và hiện bản xem trước theo từng API (tuân thủ FR-00-032): tên, phiên bản, mô tả, context-path cũ, backend, trạng thái cũ, plan, subscription, kèm đề xuất ánh xạ và các vấn đề phải xử lý.
3. Với mỗi API, hệ thống đề xuất tạo API `origin = LEGACY` ở `DRAFT`: giữ tên, mô tả; backend chuyển thành loại `SYSTEM` chờ kết nối PH-05; context-path cũ giữ làm bí danh `legacyPath` cho giai đoạn chạy song song; có Swagger thì nạp làm đặc tả (UC-02-05), không thì đặc tả khung "Cần bổ sung".
4. Hệ thống ánh xạ plan: bốn trạng thái cũ sang `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED`; Keyless hoặc API key sang kiểu xác thực tương ứng và kiểm tra ràng buộc mức phân loại (BR-02-016), vi phạm thì đánh dấu "Cần nâng xác thực" thay vì chặn nhập.
5. Hệ thống ánh xạ subscription theo `applicationMap`: tạo đăng ký ở `SUSPENDED` với lý do `MIGRATED_AWAITING_CREDENTIAL` cho tới khi HTTT mới có định danh máy ở PH-01 (BR-02-036).
6. Quang xem, sửa ánh xạ (ví dụ đổi mã hai API trùng), bấm "Xác nhận nhập" (`mode = COMMIT`, API-02-086). Hệ thống ghi tất cả hoặc không cho từng API và trả `201` kèm `importId`.
7. Hệ thống sinh báo cáo đối chiếu (API-02-087): nguồn có 42 API, 61 plan, 187 subscription; đã nhập 40 API, 58 plan, 171 subscription; không nhập 2 API trùng mã (cùng 3 plan, 12 subscription) và 4 subscription có HTTT không `ACTIVE`; kèm tổng kiểm tra và danh sách chưa nhập có lý do. API chưa có đặc tả hợp lệ không thể gửi duyệt cho tới khi bổ sung (UC-02-15).

**Luồng thay thế.**

- **A1. (bước 2) Chỉ kiểm tra, không ghi.** Quang chạy `mode = PREVIEW`, chỉ nhận bản xem trước và báo cáo; use case kết thúc.
- **A2. (bước 6) Nhập một phần.** Quang chọn `scope = SELECTED` kèm `legacyIds[]`, bỏ chọn API có lỗi; hệ thống nhập phần còn lại.
- **A3. (bước 1) Hà hỗ trợ.** PA có cùng quyền quản trị phân hệ; Hà có thể chạy từng bước thay Quang.

**Luồng ngoại lệ.**

- **E1. Tệp sai định dạng (bước 1).** ERR-02-045 (400); "Tệp không phải gói xuất APIM hợp lệ: {lý do}."
- **E2. Tệp quá lớn (bước 1).** ERR-02-009 (413); "Tệp vượt 50 MiB."
- **E3. Mã API sau chuyển đã dùng (bước 3).** ERR-02-002 (409) cho API đó; các API khác vẫn nhập được; bản xem trước đề xuất đổi mã.
- **E4. HTTT trong `applicationMap` không `ACTIVE` (bước 5).** ERR-02-004 (422) cho các đăng ký liên quan; chúng không nhập và được liệt kê.
- **E5. Đang có lần nhập khác chạy (bước 2, 6).** ERR-02-035 (409); "Đang có lần nhập khác chạy."
- **E6. Dịch vụ quét mã độc không khả dụng (bước 1).** ERR-02-034 (503); hệ thống từ chối nhận tệp, Quang thử lại sau.

**Quy tắc áp dụng.** BR-02-015, 016, 021, 036.

**Màn hình, API.** UI-02-16; API-02-085, 086, 087.
:::

### 6.38. UC-02-38 · Quản lý bộ luật kiểm tra và tham số phân hệ

::: dac-ta
**Mục tiêu.** Quản trị nền tảng giữ bộ luật kiểm tra mặc định, quản trị tenant điều chỉnh vừa phải bộ luật và các ngưỡng, thời hạn, lịch của PH-02 theo thực tế tỉnh mà không phải phát hành lại phần mềm, trong trần do nền tảng đặt.

**Tác nhân chính.** `ROLE-TENANT_ADMIN` (Quang); `ROLE-PLATFORM_ADMIN` (Hà).

**Tác nhân phụ.** PH-18 (kho tham số `02.*`), `ROLE-SECURITY_OFFICER` (Dũng) nhận thông báo khi đổi tham số bảo mật.

**Mức ưu tiên.** M (tham số), S (bộ luật) · MVP.

**FR hiện thực.** FR-02-021, 062.

**Truy vết.** REQ-02, REQ-18; quy trình Quản trị; Q02-04; không có LGC (năng lực mới).

**Tiền điều kiện.** Quang và Hà có quyền quản trị phân hệ (đề nghị, động từ `admin`); PH-18 khả dụng hoặc đọc giá trị mặc định đã đệm.

**Kích hoạt.** Quang mở UI-02-15 "Bộ luật kiểm tra" hoặc UI-02-17 "Cài đặt phân hệ".

**Đảm bảo tối thiểu.** Không tắt hay hạ luật cấu trúc và bảo mật, không hạ mức `ERROR` mặc định của lớp 1; thay đổi luật chỉ áp cho lần kiểm tra tiếp theo, phiên bản `PUBLISHED` không bị ảnh hưởng; giá trị tham số luôn trong miền và trần nền tảng.

**Đảm bảo thành công.** Bộ luật hiệu lực của tenant có số phiên bản mới; tham số mới có hiệu lực trong 60 giây; kiểm toán ghi giá trị trước, sau, lý do, người sửa.

**Luồng chính.**

1. Quang mở UI-02-15 (API-02-024): 15 luật lớp 2 và 9 mẫu quét bí mật (chỉ đọc), mức mặc định, mức hiệu lực ở tenant, số API đang vi phạm.
2. Quang nâng luật `LINT-02-06` (thiếu `example`) từ `WARNING` lên `ERROR`. Hệ thống kiểm tra thay đổi hợp lệ: không tắt hay hạ luật cấu trúc và bảo mật, không hạ mức `ERROR` mặc định của lớp 1.
3. Hệ thống hiện "Ảnh hưởng ước tính": 6 phiên bản `DRAFT` sẽ phát sinh lỗi mới, 0 phiên bản `PUBLISHED` bị ảnh hưởng.
4. Hệ thống lưu theo phiên bản bộ luật (`rulesetVersion` tăng dần, API-02-025) và ghi kiểm toán luật, mức cũ, mức mới, người đổi, lý do; các kiểm tra tiếp theo dùng bộ luật mới, kết quả cũ giữ số phiên bản bộ luật đã dùng.
5. Hà phát hành luật mới theo bản triển khai nền tảng; luật mới ở mức `WARNING` trong 30 ngày rồi mới thành `ERROR` để chủ dịch vụ kịp sửa.
6. Quang mở UI-02-17 (API-02-088): danh sách tham số `02.*` kèm mặc định, miền, giá trị hiệu lực, ý nghĩa.
7. Quang sửa `02.deprecation.min-days` từ 180 lên 240 và `02.review.overdue-days` từ 5 xuống 3, nêu lý do "Quy định nội bộ của tỉnh". Hệ thống kiểm tra kiểu và miền giá trị, trần do PA đặt cho tenant, và phụ thuộc giữa tham số (`02.deprecation.min-days` không nhỏ hơn mốc nhắc lớn nhất là 90).
8. Hệ thống ghi giá trị qua PH-18 (API-02-089), hiệu lực trong 60 giây nhờ bộ đệm, hiện tác động ước tính (ví dụ 4 yêu cầu duyệt hiện có sẽ vào diện quá hạn), ghi kiểm toán; tham số liên quan bảo mật (ngưỡng tự duyệt, bật quét bí mật) sinh thông báo cho Dũng.

**Luồng thay thế.**

- **A1. (bước 2) Quang bấm "Về mặc định" ở UI-02-15.** Hệ thống khôi phục mức mặc định nền tảng cho luật đó hoặc cả nhóm.
- **A2. (bước 7) Quang bấm "Về mặc định" cho một tham số hoặc cả nhóm.** Hệ thống áp giá trị mặc định ở bảng tham số của FRS.

**Luồng ngoại lệ.**

- **E1. Cố tắt luật cấu trúc hoặc hạ luật lớp 1 (bước 2).** ERR-02-003 (400); "Luật {mã} là luật bắt buộc, không thể tắt hoặc hạ mức."
- **E2. Thiếu quyền (bước 2, 7).** ERR-02-014 (403); "Bạn không có quyền thay đổi bộ luật."
- **E3. Giá trị ngoài miền (bước 7).** ERR-02-003 (400); "Giá trị {tham số} phải nằm trong {a}…{b}."
- **E4. Vượt trần nền tảng đặt (bước 7).** ERR-02-040 (422); "Giá trị vượt trần {giá trị} do nền tảng đặt."
- **E5. Thiếu lý do thay đổi (bước 7).** ERR-02-041 (400); "Cần nêu lý do thay đổi."
- **E6. PH-18 không khả dụng (bước 8).** ERR-02-034 (503); "Không lưu được tham số lúc này. Thử lại sau."

**Quy tắc áp dụng.** BR-02-002, 028.

**Màn hình, API.** UI-02-15, 17; API-02-024, 025, 088, 089.
:::

## 7. Luồng phụ dùng chung

Bảy đoạn xử lý dưới đây lặp ở nhiều UC nên được đặc tả một lần ở đây; UC chỉ viện dẫn mã `LP-02-nn`. Mỗi luồng phụ nêu các bước, mã lỗi khi không đạt và UC dùng nó.

| Mã | Luồng phụ | Các bước | Dùng ở |
|---|---|---|---|
| LP-02-01 | Bốn mắt | Hệ thống so người duyệt với người gửi duyệt và người sửa gần nhất đặc tả hoặc gói; trùng thì khóa nút "Duyệt" và trả ERR-02-013 nếu gọi thẳng API. SV không giữ vai trò CA trong cùng tenant (D02-08 §4). API mức `SENSITIVE` cần thêm xác nhận lần hai của TA khác CA (trạng thái `AWAITING_SECOND`) | UC-02-13, 14, 16, 19, 20, 21, 24 |
| LP-02-02 | Đẩy cấu hình xuống gateway và chờ xác nhận | (1) PH-02 dựng bộ cấu hình theo môi trường; (2) chuyển PH-03 sinh ảnh chụp có chữ ký, số phiên bản tăng dần; (3) PH-03 ghi vào kho cấu hình, APISIX nạp, lan truyền ≤ 10 giây; (4) PH-03 báo xác nhận qua API-02-082 trong 30 giây; (5) không xác nhận thì thử lại lùi dần tối đa 5 lần trong 15 phút rồi cảnh báo TO, trả ERR-02-033; đối tượng giữ trạng thái trước, không nửa vời | UC-02-13, 14, 15, 16, 17, 19, 20, 25, 27, 36 |
| LP-02-03 | Hành động quan trọng cần xác nhận và lý do | Hộp xác nhận nêu ảnh hưởng (số bên đăng ký, lượt gọi 7 ngày) theo FR-00-050; mọi chuyển trạng thái trừ tạo mới bắt buộc có lý do, thiếu trả ERR-02-041; kiểm toán ghi giá trị trước, sau (BR-02-028) | UC-02-14, 17, 19, 20, 21, 22, 27, 38 |
| LP-02-04 | Thông báo bắt buộc | Sự kiện thay đổi (phiên bản phá vỡ, ngừng khuyến nghị, tạm ngừng, tiếp tục, ngừng hẳn, SLA kém đi, hạ mức hiển thị, quyết định đăng ký) chuyển UC-02-33; bên nhận không tắt được; nội dung không chứa dữ liệu Hạn chế hay Nhạy cảm | UC-02-14, 17, 19, 20, 21, 22, 27, 31 |
| LP-02-05 | Dịch vụ phụ thuộc không khả dụng | PH-01, PH-04, PH-10, PH-12, PH-13, PH-14, PH-18, kho đối tượng lỗi: trả ERR-02-034; dữ liệu đọc thì dùng bản đã đệm kèm nhãn "Cập nhật lúc {thời điểm}"; lệnh ghi thì vào hàng đợi (outbox), thử lại lùi dần; không bao giờ làm gián đoạn API đang chạy (NFR-02-008) | UC-02-01, 04, 07, 09, 10, 11, 25, 26, 29, 32, 34, 36 |
| LP-02-06 | Cách ly tenant | Đối tượng của tenant khác trả `404` cùng thân với "không tồn tại" (ERR-02-001), không tiết lộ sự tồn tại; phiên bản `DRAFT`, `PENDING` chỉ hiện cho tổ chức chủ quản, TA, CA, PA (BR-02-039) | UC-02-01 đến 04, 26, 34, 35 |
| LP-02-07 | Sửa đồng thời và gửi lặp | Lệnh ghi mang `If-Match` với `ETag`; lệch trả ERR-02-015 kèm nút "Xem khác biệt". Lệnh tạo mang `Idempotency-Key`; cùng khóa khác thân trả ERR-02-042; cùng khóa cùng thân trả lại kết quả lần đầu | UC-02-05, 12, 23, 37 |

: Luồng phụ dùng chung

## 8. Tổng hợp mã mới và đối chiếu

Tập này không tạo mã FR, API, ERR, UI, BR hay EVT mới (bảy operation API-02-092…098 do tập API bổ sung đã được gắn vào các UC ở bảng 5.2 và mục "Màn hình, API" của UC-02-06, 07, 08, 10, 12, 14, 16, 24, 29, 32, 36). Mã mới của tập: `UC-02-01…38`, `LP-02-01…07` và câu hỏi mở `Q02-45…49` (dải UC của D00-04 §3.1).

Đối chiếu độ phủ (đã kiểm theo bảng 5.4):

| Chỉ tiêu | Kết quả |
|---|---|
| Mỗi FR mức M thuộc ít nhất một UC | 50/50 FR mức M có UC chính |
| FR mức S, C | 11/11 FR mức S và 1/1 FR mức C có UC chính (FR-02-060 ở UC-02-36) |
| Mỗi UC có FR hiện thực | 38/38 |
| Mỗi UC có màn hình | 37/38; chỉ UC-02-35 không có màn hình (FR-02-059 không có màn); lỗi của UC máy nêu nơi người vận hành thấy ở luồng ngoại lệ |
| Mỗi UC có API | 38/38 (UC máy nêu API nội bộ hoặc sự kiện) |
| Mọi `ERR-02-nnn` nêu trong luồng ngoại lệ | Có thật trong FRS §9.1 |
| Mọi mục `LGC` của PH-02 (15 mục) | Có UC (bảng 5.3): LGC-APIM-001; 002, 003, 004, 005, 006, 008, 009, 010, 011, 016, 017, 018, 021 và LGC-BUS-028 |

: Đối chiếu độ phủ của tập use case

Bảy UC máy (UC-02-02, 09, 25, 29, 32, 33, 35) không có màn hình thao tác riêng; sáu trong số đó có màn hình chỉ để xem kết quả (UI-02-01, 02, 08, 12, 11, 13) nên bảng 5.2 vẫn nêu UI cho chúng, riêng UC-02-35 không có màn hình nào theo FRS.

Các câu dưới đây là biến thể theo ngữ cảnh của UC. Bảng chuẩn đã có đủ 45 mã ERR-02 ở D02-03-PH02 §9.2 và D03-06-PH02 §5.2 (đồng bộ ở lượt rà soát); khi hiển thị, câu trong UC thay cho câu chuẩn ở đúng ngữ cảnh nêu trong cột UC, các chỗ khác dùng câu chuẩn:

| Mã lỗi | Câu đề nghị | UC |
|---|---|---|
| ERR-02-014 | "Bạn không có quyền xử lý loại yêu cầu này." (UC-02-16) và "Bạn không có quyền chuyển chủ quản API." (UC-02-22) | UC-02-16, 22 |
| ERR-02-040 | "Vượt trần {n} do nền tảng đặt." | UC-02-11, 18 |
| ERR-02-035 | "Đang so sánh, vui lòng chờ." | UC-02-18 |
| ERR-02-042 | "Yêu cầu trùng khóa nhưng khác nội dung. Tải lại trang rồi gửi lại." | UC-02-23 |
| ERR-02-001 | "Không tìm thấy đối tượng." (dùng chung cho đăng ký, HTTT, dịch vụ sự kiện) | UC-02-04, 26 |
| ERR-02-003 | "Khoảng thời gian không hợp lệ." | UC-02-34 |

: Câu thông báo mới đề nghị đồng bộ

Các việc ngoài quyền sửa của tập này (các đề nghị với D02-03-PH02 §9.2, D03-06-PH02 §5.2 và D03-04-PH02 về tên API-02-072, 090, 091 đã được thực hiện ở lượt rà soát chéo):

| Tài liệu | Đề nghị |
|---|---|
| D05-02-PH02 | Sinh ca kiểm thử từ mỗi luồng chính (dương), luồng thay thế và luồng ngoại lệ của tập này; thêm ca xuyên UC cho tiêu chí chấp nhận phân hệ: vòng đời trọn vẹn UC-02-05 → 06 → 11 → 12 → 15 → 16 → 23 → 24 → 25 và ca ngừng dùng UC-02-18 → 19 → 20 (còn đăng ký thì không tự ngừng hẳn) |
| PH-01 FRS (khi viết) | Định nghĩa sự kiện tạm ngừng, thu hồi HTTT mà UC-02-27 nhánh A1 tiêu thụ (`SYSTEM_SUSPENDED`), và trạng thái "chờ cấp định danh" của UC-02-25 nhánh A1 |
| PH-12 FRS (khi viết) | Xác nhận giao diện gắn và gỡ phạm vi `api:{mã API}:{mã gói}` lên client Keycloak, cập nhật chính sách OPA (UC-02-25, 27) |
| PH-18 FRS (khi viết) | Xác nhận tạo việc "Rà soát đăng ký", "Hoàn thiện API sinh từ luồng", "Gán HTTT sở hữu luồng" trong hộp "Việc của tôi" (UC-02-09, 28, 30) |

: Đề nghị đồng bộ phát sinh từ tập use case

## 9. Câu hỏi mở

> **Câu hỏi mở Q02-45:** UC-02-16 bước 5 gặp khoảng đóng băng thay đổi môi trường thật (ERR-02-039) sau khi Minh đã duyệt. Quyết định duyệt có giữ nguyên để tự công bố khi hết đóng băng, hay phải duyệt lại. Đề xuất: giữ quyết định, tự công bố khi hết đóng băng nếu băm hồ sơ không đổi; ai đặt khoảng đóng băng (PH-18 hay D03-09) cần được nêu ở SDD PH-02.

> **Câu hỏi mở Q02-46:** UC-02-17 bước 4 thông báo tạm ngừng chỉ nêu lý do ở mức tổng quát để không lộ chi tiết sự cố ATTT. Mẫu câu theo từng nhóm lý do (`SECURITY`, `BACKEND_FAILURE`, `LEGAL`, `OTHER`) cần Cán bộ ATTT duyệt. Đề xuất: bốn mẫu cố định, không cho người tạm ngừng sửa tự do ở nhóm `SECURITY`.

> **Câu hỏi mở Q02-47:** UC-02-24 nhánh A3 cho SV duyệt trực tiếp đăng ký của API dưới mức `RESTRICTED` (BR-02-026). Người duyệt dịch vụ (CA) có cần được báo hoặc nhận báo cáo định kỳ về các đăng ký mà họ không duyệt không. Đề xuất: giữ SV duyệt trực tiếp, CA nhận tóm tắt tuần qua trung tâm thông báo, không thêm bước duyệt.

> **Câu hỏi mở Q02-48:** UC-02-25 nhánh A1 để đăng ký ở `AWAITING_CREDENTIAL` khi HTTT chưa có định danh máy, nhưng FRS chưa nêu thời hạn chờ. Đăng ký treo quá lâu làm sai số liệu quy mô và rà soát quyền. Đề xuất: sau 30 ngày chưa có định danh, nhắc OR; sau 60 ngày chuyển `CANCELLED` với lý do `NO_CREDENTIAL`; cần bổ sung vào FR-02-048 và thêm tham số `02.subscription.credential-wait-days`.

> **Câu hỏi mở Q02-49:** UC-02-37 bước 3 giữ context-path cũ làm bí danh `legacyPath` trong giai đoạn chạy song song, FRS để TA đặt hạn nhưng chưa có mặc định. Đề xuất: mặc định 6 tháng kể từ ngày nhập, nhắc ở mốc 30 ngày và 7 ngày, gia hạn một lần tối đa 3 tháng với lý do; cần bổ sung vào FR-02-061 và FR-02-024.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và quy chuẩn K-TRINH-BAY: 38 use case (7 UC máy) phủ 62 FR của D02-03-PH02, mỗi UC một khối đặc tả 15 mục với dữ liệu minh họa tenant `T68`; bốn sơ đồ use case tổng; bốn bảng truy vết (UC ↔ FR, UC ↔ màn hình ↔ API, UC ↔ REQ ↔ quy trình ↔ hệ cũ, FR → UC); hai sơ đồ trình tự (duyệt bốn mắt và công bố, cấp phạm vi truy cập); bảy luồng phụ dùng chung; năm câu hỏi mở Q02-45…49 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: gắn API-02-092…098 vào 11 use case; thống nhất xưng hô "Bạn" trong câu thông báo; sửa route UI-02-14, UI-02-16 cho khớp tập màn hình; ghi chú câu thông báo biến thể theo ngữ cảnh; thêm câu mở cho các mục chỉ có bảng |
