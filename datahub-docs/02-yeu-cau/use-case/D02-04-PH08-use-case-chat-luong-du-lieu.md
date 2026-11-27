---
ma_tai_lieu: D02-04-PH08
ten: Đặc tả use case phân hệ PH-08 Chất lượng dữ liệu
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-08
mo_ta: Đặc tả 27 use case của phân hệ Chất lượng dữ liệu (DQ), mỗi use case một khối 15 mục kèm sơ đồ trình tự, mã lỗi và câu thông báo lấy từ FRS, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH08 FRS; D03-02-PH08 SDD; D03-03-PH08 CSDL; D03-04-PH08 API; D03-06-PH08 Màn hình; D05-02-PH08 Kiểm thử
---

# D02-04-PH08 · Đặc tả use case Chất lượng dữ liệu

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 27 use case của PH-08, phủ toàn bộ 61 FR (36 mức M, 21 mức S, 4 mức C) của [D02-03-PH08](../frs/D02-03-PH08-frs-chat-luong-du-lieu.md). Use case đi theo vòng đo và cải thiện chất lượng dữ liệu của một tỉnh: cán bộ quản lý dữ liệu khai báo miền và đối tượng đo, soạn bộ quy tắc sáu chiều, người duyệt kích hoạt theo bốn mắt; hệ thống đo theo lịch hằng tháng, theo sự kiện và trực tuyến, ghi bản ghi lỗi có dấu vân tay, tính điểm và xu hướng; lỗi được gom thành phiếu giao chủ quản sửa ở nguồn rồi đo lại kiểm chứng; kết quả đi vào bảng điều khiển, cảnh báo, báo cáo kỳ và báo cáo chính thức hằng năm. Căn cứ pháp lý: CMP-LAW-01 (Luật Dữ liệu 60/2024), CMP-LAW-02 (NĐ 165/2025), CMP-LAW-03 (NĐ 278/2025, thay NĐ 47/2020 mà SRS cũ dẫn); điều khoản cụ thể chưa xác minh nên ghi ở Q08-01 của FRS.

Bốn điểm hội đồng cần lưu ý. Thứ nhất, hệ cũ (Viettel 2021) không có chức năng chất lượng dữ liệu nên 27 use case là năng lực mới; chỉ sáu mục LGC liên quan gián tiếp (§5.3). Thứ hai, PH-08 chỉ đo và giao việc, không sửa dữ liệu nguồn: lỗi được coi là hết khi lần đo kiểm chứng không còn thấy dấu vân tay của nó, không phải khi chủ quản tự báo (UC-08-21). Thứ ba, năm loại quyết định có hậu quả lớn đều qua bốn mắt: kích hoạt bộ quy tắc, trọng số và ngưỡng, ngoại lệ chấp nhận, công bố báo cáo, xuất lỗi có trường Nhạy cảm. Thứ tư, bản ghi lỗi không lưu giá trị gốc của trường Nhạy cảm, chỉ lưu giá trị che hoặc băm (BR-08-012).

## 1. Giới thiệu

Chương này nói tài liệu dùng để làm gì, phủ những gì, ai nên đọc phần nào, thuật ngữ và các tài liệu cần mở song song.

### 1.1. Mục đích

Tài liệu đặc tả 27 use case (ca sử dụng) của PH-08 Chất lượng dữ liệu. Mỗi use case mô tả trọn một mục tiêu nghiệp vụ của một tác nhân theo từng bước tương tác với hệ thống, kèm nhánh thay thế, tình huống ngoại lệ có mã lỗi và câu thông báo người dùng nhìn thấy, các đảm bảo hệ thống giữ dù thành công hay thất bại, và một sơ đồ trình tự cho thấy thứ tự gọi giữa các thành phần. Tài liệu nối FRS (hệ thống phải làm gì) với D03-02 SDD, D03-03 CSDL, D03-04 API và D03-06 màn hình (làm thế nào); kiểm thử viên dùng luồng chính, thay thế, ngoại lệ làm khung kịch bản `TS-08-nn` ở D05-02-PH08.

### 1.2. Phạm vi

Phạm vi là toàn bộ FR-08-001…061. Tài liệu mô tả trình tự giữa tác nhân và hệ thống, dữ liệu ví dụ và cách xử lý khi sai lệch; ràng buộc chi tiết từng bước (kiểu, miền giá trị, thứ tự kiểm tra) nằm ở FR và không chép lại. Chức năng dùng chung FR-00 (đăng nhập, chọn tenant, danh sách, kiểm toán, "Việc của tôi", thông báo, xác nhận thao tác) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Mọi enum, trạng thái, tên trường, quyền, tham số `08.*`, mã màn hình, mã sự kiện dùng đúng Phụ lục A và chương 8, 9, 10 của FRS.

Ngoài phạm vi: lưu và hợp nhất bản ghi vàng (PH-06); quản lý bảng mã (PH-07); sửa dữ liệu ở HTTT nguồn (chủ quản); che dữ liệu khi trả (PH-09); KPI tổng hợp (PH-16); điều phối luồng (PH-04); gửi thông báo (kênh thông báo chung PH-13); thuật toán thực thi SQL đẩy xuống và CEL (SDD D03-02-PH08).

### 1.3. Người đọc

Hội đồng thẩm định đọc tóm tắt, chương 4, 5, 9. Sở KH&CN và Trung tâm dữ liệu rà UC-08-05…09, 19…22, 25…27. Kỹ sư `dh-data` (package `vn.datahub.data.dq`), `dh-console`, PH-04 đọc chương 6 (luồng, mã lỗi, mục "Màn hình, API") và các sơ đồ trình tự. Kiểm thử viên coi mỗi luồng chính, thay thế, ngoại lệ là ít nhất một phép kiểm trong `TS-08-nn`.

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01; thuật ngữ riêng theo FRS §1.4 và §4.1. Bảng chỉ nhắc các từ dày đặc trong luồng.

| Thuật ngữ | Giải thích |
|---|---|
| Chất lượng dữ liệu (DQ) | Mức độ dữ liệu đáp ứng sáu chiều: đầy đủ, chính xác, nhất quán, kịp thời, duy nhất, hợp lệ |
| Đối tượng đo (asset) | Tập dữ liệu được đo: domain PH-06, danh mục PH-07, bảng hoặc khung nhìn của HTTT, hoặc bản tin trên luồng PH-04 |
| CDE (critical data element) | Phần tử dữ liệu trọng yếu của đối tượng đo, mang phân loại PH-09 |
| Hồ sơ dữ liệu (profiling) | Thống kê cột (tỷ lệ rỗng, số giá trị khác nhau, phân vị) làm căn cứ viết quy tắc |
| Bộ quy tắc | Tập quy tắc của một đối tượng đo, có phiên bản `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `ACTIVE`, `SUPERSEDED`, `RETIRED` |
| CEL | Common Expression Language, ngôn ngữ biểu thức kiểm tra mức bản ghi |
| Pushdown | Dịch quy tắc tập hợp thành truy vấn SQL chạy ngay tại nguồn, trên bản sao chỉ đọc |
| Bản ghi lỗi (finding) | Một bản ghi vi phạm một quy tắc; nhận dạng bằng dấu vân tay `fingerprint` nên theo dõi được qua các kỳ |
| Phiếu khắc phục (issue) | Việc giao tổ chức chủ quản sửa một nhóm lỗi, có SLA theo mức nghiêm trọng |
| Ngoại lệ (waiver) | Chấp nhận có hạn một nhóm lỗi, không tính vào mẫu số điểm |
| `INCOMPLETE_DIMENSIONS` | Cờ trên ảnh chụp điểm khi một chiều không có điểm |
| DS, DA, DO, TA, TO, SO, PA, AU, VW | Cán bộ quản lý dữ liệu, người duyệt dữ liệu, chủ quản dữ liệu, quản trị tenant, vận hành tenant, cán bộ ATTT, quản trị nền tảng, kiểm toán, người xem (FRS §3.1) |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

[D02-03-PH08 FRS](../frs/D02-03-PH08-frs-chat-luong-du-lieu.md) (nguồn chuẩn: §3 tác nhân, §4 máy trạng thái, §7 quy tắc nghiệp vụ, §8.2 tham số, §9 mã lỗi, thông báo, sự kiện, API, §10.1 màn hình, Phụ lục A); D02-01 (REQ, BP); D02-02 SRS §5; D02-08 (quyền, vai trò); D00-01 (hệ mã); D00-04 (sổ tra cứu gọn); K-UC, K-TRINH-BAY; `docs/07-srs/SRS-PH-08-dq.md` (SRS cũ của repo); mẫu cùng loại D02-04-PH06.

### 1.6. Cấu trúc tài liệu

Chương 2 quy ước đọc; 3 tác nhân; 4 sơ đồ use case tổng (năm hình); 5 bảng tổng hợp, ma trận truy vết FR, UI, API, REQ, LGC; 6 hai mươi bảy khối đặc tả kèm sơ đồ trình tự; 7 luồng phụ dùng chung; 8 mã mới và đề nghị đồng bộ; 9 câu hỏi mở.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ · Quy tắc áp dụng · Màn hình, API. Đoạn văn trước khối nói bối cảnh; sau khối là sơ đồ trình tự Mermaid và một đoạn thuyết minh.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3). Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-08-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép, nguyên văn FRS §9.2 (dấu `{…}` do máy chủ điền). Mã ERR-08-101…119 là lỗi runtime, người vận hành thấy ở UI-08-12, UI-08-19, UI-08-20 hoặc PH-13. Luồng phụ dùng chung ghi `LP-08-nn`, đặc tả một lần ở chương 7.

Quy ước chung không nhắc lại từng use case: lệnh ghi qua `/api/dq/v1` mang `Idempotency-Key`, lệnh sửa mang `If-Match` (sai phiên bản: ERR-08-004, 409; thiếu: ERR-00-428); đối tượng tenant khác trả như không tồn tại (ERR-08-001, 404); thiếu quyền chức năng trả ERR-00-403, chưa đăng nhập ERR-00-401; truy vấn chạy dưới RLS theo `tenant_id`; mọi thao tác ghi sinh kiểm toán, không ghi được kiểm toán thì từ chối (ERR-08-054, 503). Dữ liệu ví dụ giả lập, tenant `T68`.

| Vai | Người hoặc đối tượng | Ghi chú |
|---|---|---|
| DS | **Lan** (Trung tâm dữ liệu tỉnh) | Soạn quy tắc, chạy đo, mở phiếu, soạn báo cáo |
| DA | **Hùng** (lãnh đạo Sở KH&CN) | Duyệt bộ quy tắc, ngoại lệ, báo cáo; cặp loại trừ với DS |
| DO | **Phúc** (Sở Tư pháp, chủ quản hộ tịch), **Thảo** (Sở Giáo dục) | Nhận phiếu, sửa ở nguồn |
| TA, TO, SO, PA | **Mai**, **Chi**, **Dũng**, **Hà** | Quản trị tenant, vận hành, ATTT, nền tảng |
| Đối tượng đo | `MDM-CITIZEN` (domain PH-06), `RDM-DVHC` (danh mục PH-07), `SRC-HOTICH` (bảng `khai_sinh` qua kết nối `conn-hotich-ro`), `FLOW-LLTP` (bản tin luồng PH-04) | Giả định: 200 HTTT, tỉnh T01 quy mô vừa |
| Bộ quy tắc, lần đo, phiếu | `RS-CITIZEN` v3, `SC-202611-0007`, `ISS-2026-0042` | Mã ví dụ, không phải mã thật |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-08 có chín nhóm tác nhân người và các tác nhân hệ thống. DS và DA là cặp loại trừ trong tenant (FRS §3.3): người soạn hoặc gửi duyệt không được duyệt. Người đo (DS) không phải người sửa (DO), và DO không tự xác nhận phiếu đã sửa. PH-04 và PH-06 là tác nhân chính của use case máy với máy (kiểm tra trực tuyến). Bộ thực thi đo dùng vai trò CSDL `dq_reader` chỉ có quyền `SELECT` trên khung nhìn hợp đồng do PH-06 cấp và trên nguồn của kết nối PH-05 chỉ đọc.

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính | Use case tham gia |
|---|---|---|---|
| DS | ROLE-DATA_STEWARD | `PERM-08-asset`, `rule-admin`, `run`, `finding-read`, `remediate`, `report`, `export` | 01…06, 08…11, 13…15, 17…19, 21, 22, 23, 25…26 |
| DA | ROLE-DATA_APPROVER | `PERM-08-approve`, `finding-read`, `export` | 07, 09, 17, 18, 24…26 |
| DO | ROLE-DATA_OWNER | `PERM-08-read`, `finding-read`, `remediate` (○ tổ chức mình), chấp thuận xuất | 17, 20, 21, 22, 24 |
| TA | ROLE-TENANT_ADMIN | `PERM-08-asset`, `rule-admin`, `run`, `remediate`, `report`, `config` | 01, 02, 10, 19, 23, 25, 27 |
| TO | ROLE-TENANT_OPERATOR | `PERM-08-run`, `read` | 10, 11, 13, 16, 23 |
| SO, AU | ROLE-SECURITY_OFFICER, ROLE-AUDITOR | `PERM-08-audit-read`; SO thêm `finding-read` | 17, 27 |
| VW | ROLE-VIEWER | `PERM-08-read` (chỉ tổng hợp) | 24, 25 |
| PA | ROLE-PLATFORM_ADMIN | Mẫu `COMMON`, trần tham số, so sánh liên tenant | 06, 24, 27 |
| PH-04 | `dh-runtime` | Scope `dq.check` | 15 |
| PH-06 | Dữ liệu chủ | `dq.check`; cấp khung nhìn hợp đồng, phát EVT-06 | 02, 11, 14, 16, 22 |
| PH-05, PH-07, PH-09 | Bộ điều hợp, danh mục, quyền riêng tư | Kết nối chỉ đọc, chỉ số hồ sơ; tra mã, sự kiện phát hành; phân loại trường | 02, 04, 11, 14 |
| PH-13, PH-16, PH-18 | Giám sát, KPI, job | Nhận cảnh báo, KPI; PH-18 chỉ kích hoạt thêm lần đo theo yêu cầu (phụ thuộc mềm) | 10, 12, 23, 26 |
| HTTT thành viên | ROLE-PARTNER_SYSTEM | Scope `dq.read` (thẻ điểm dữ liệu của mình) | 24 |

: Tác nhân và use case tham gia

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, 27 use case chia thành năm hình theo vòng đời: khai báo và hồ sơ, quy tắc, đo, bản ghi lỗi và khắc phục, theo dõi và quản trị. Mermaid không có ký pháp UML use case nên dùng `flowchart`: hình bo tròn là tác nhân người, hình hai viền là tác nhân hệ thống, hình chữ nhật bo góc là use case; đường liền nối tác nhân với use case mà họ tham gia.

```{.mermaid caption="Use case khai báo miền, đối tượng đo và hồ sơ dữ liệu"}
flowchart TB
  TA([TA, DS])
  DO([DO])
  P[[PH-05, PH-06, PH-07, PH-09]]
  subgraph G1["Khai báo"]
    U01(UC-08-01 Khai báo miền)
    U02(UC-08-02 Đăng ký đối tượng đo, CDE)
    U03(UC-08-03 Xem, ngừng, khôi phục)
    U04(UC-08-04 Hồ sơ dữ liệu)
    U01 ~~~ U02 ~~~ U03 ~~~ U04
  end
  TA --- U01 & U02 & U03 & U04
  DO -.- U01
  P --- U02 & U04
```

Hình cho thấy miền chất lượng gắn tổ chức chủ quản (DO) trước, rồi đối tượng đo mới được đăng ký từ ba nguồn PH-06, PH-07, PH-05 và lấy phân loại trường từ PH-09.

```{.mermaid caption="Use case soạn, duyệt và kích hoạt quy tắc"}
flowchart TB
  DS([DS])
  DA([DA])
  PA([PA])
  subgraph G2["Quy tắc"]
    U05(UC-08-05 Soạn bộ quy tắc)
    U06(UC-08-06 Quy tắc nâng cao, mẫu, chạy thử)
    U07(UC-08-07 Gửi duyệt, duyệt, kích hoạt)
    U08(UC-08-08 So sánh, sao chép, nhập, xuất)
    U09(UC-08-09 Trọng số và ngưỡng)
    U05 ~~~ U06 ~~~ U07 ~~~ U08 ~~~ U09
  end
  DS --- U05 & U06 & U07 & U08 & U09
  DA --- U07 & U09
  PA -.- U06
```

Hình cho thấy DS soạn và chạy thử, DA quyết định kích hoạt bộ quy tắc và trọng số theo bốn mắt; PA chỉ giữ thư viện quy tắc mẫu ở `COMMON`.

```{.mermaid caption="Use case đo theo lô, theo sự kiện và trực tuyến"}
flowchart TB
  DS([DS, TO])
  SYS[[Hệ thống đo, bộ lập lịch nội bộ]]
  EXT[[PH-04, PH-06, PH-07]]
  subgraph G3["Đo"]
    U10(UC-08-10 Lịch và đo theo yêu cầu)
    U11(UC-08-11 Đo lô, ghi lỗi)
    U12(UC-08-12 Điểm, xu hướng)
    U13(UC-08-13 Phụ thuộc không khả dụng)
    U14(UC-08-14 Đo tăng dần theo sự kiện)
    U15(UC-08-15 Kiểm tra trực tuyến từ luồng)
    U16(UC-08-16 Cổng PH-06, giám sát)
    U10 ~~~ U11 ~~~ U12 ~~~ U13 ~~~ U14 ~~~ U15 ~~~ U16
  end
  DS --- U10 & U16
  SYS --- U11 & U12 & U13 & U14
  EXT --- U14 & U15 & U16
```

Hình cho thấy ba đường vào của phép đo: lịch và yêu cầu (người), sự kiện PH-06, PH-07 (hệ thống), và gọi trực tuyến từ PH-04, PH-06 (máy). Mọi đường đều đi qua cùng bộ quy tắc `ACTIVE`.

```{.mermaid caption="Use case bản ghi lỗi và khắc phục"}
flowchart TB
  DS([DS])
  DA([DA])
  DO([DO])
  subgraph G4["Lỗi và khắc phục"]
    U17(UC-08-17 Tra cứu, xem, xuất lỗi)
    U18(UC-08-18 Ngoại lệ chấp nhận)
    U19(UC-08-19 Mở phiếu, phân công, SLA)
    U20(UC-08-20 Xử lý, báo đã sửa)
    U21(UC-08-21 Đo kiểm chứng)
    U22(UC-08-22 Từ chối, chuyển, leo thang)
    U17 ~~~ U18 ~~~ U19 ~~~ U20 ~~~ U21 ~~~ U22
  end
  DS --- U17 & U18 & U19 & U21 & U22
  DA --- U17 & U18
  DO --- U17 & U20 & U22
```

Hình cho thấy tách vai: DS đo và giao việc, DO sửa ở nguồn, DA quyết định ngoại lệ và xuất lỗi nhạy cảm; xác nhận cuối cùng thuộc về lần đo kiểm chứng của hệ thống.

```{.mermaid caption="Use case cảnh báo, bảng điều khiển, báo cáo và quản trị"}
flowchart TB
  DS([DS, DA])
  VW([VW, AU, SO])
  TA([TA])
  subgraph G5["Theo dõi và quản trị"]
    U23(UC-08-23 Cảnh báo)
    U24(UC-08-24 Bảng điều khiển, thẻ điểm)
    U25(UC-08-25 Báo cáo kỳ và năm)
    U26(UC-08-26 Xuất, ký, phân phối, KPI)
    U27(UC-08-27 Tham số, lưu giữ, kiểm toán)
    U23 ~~~ U24 ~~~ U25 ~~~ U26 ~~~ U27
  end
  DS --- U23 & U25 & U26
  VW --- U24 & U27
  TA --- U27
```

Hình cho thấy lãnh đạo và người xem chỉ đọc tổng hợp (UC-08-24), báo cáo đi qua soạn, duyệt, công bố (UC-08-25, 26), còn TA và kiểm toán làm việc ở lớp tham số và nhật ký (UC-08-27).

## 5. Bảng tổng hợp use case và truy vết

Chương này là danh sách chính thức 27 use case, đặt trước phần chi tiết để tra nhanh. Bảng 5.3 là nguồn của mục "Truy vết" trong từng khối đặc tả; bảng 5.2 là nguồn của mục "Màn hình, API" và là ma trận use case với màn hình. Hệ cũ không có chức năng chất lượng dữ liệu nên cột LGC chủ yếu là "—".

### 5.1. Use case và FR

Bảng liệt kê 27 use case, tác nhân chính, mức ưu tiên cao nhất trong các FR của use case và FR hiện thực (số đuôi của `FR-08-nnn`). Cả 61 FR (mức M, S, C) thuộc ít nhất một use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-08-01 | Khai báo miền chất lượng, chủ quản và cán bộ phụ trách | TA, DS | M | 001 |
| UC-08-02 | Đăng ký đối tượng đo và khai báo CDE | DS, TA | M | 002, 003, 004, 005 |
| UC-08-03 | Tìm, xem, ngừng và khôi phục đối tượng đo | DS, DO | M | 006, 007 |
| UC-08-04 | Chạy hồ sơ dữ liệu và gợi ý quy tắc | DS | S | 008, 009, 010, 011 |
| UC-08-05 | Soạn bộ quy tắc và định nghĩa quy tắc theo chiều | DS | M | 012, 013, 022 |
| UC-08-06 | Quy tắc nâng cao, thư viện mẫu và chạy thử | DS, PA | M | 014, 015, 016 |
| UC-08-07 | Gửi duyệt, duyệt, kích hoạt và ngừng bộ quy tắc | DS, DA | M | 017, 018 |
| UC-08-08 | So sánh phiên bản, sao chép, nhập và xuất bộ quy tắc | DS | S | 019, 020 |
| UC-08-09 | Cấu hình trọng số và ngưỡng có duyệt | DS, DA | M | 021 |
| UC-08-10 | Lập lịch đo, đo theo yêu cầu, theo dõi và hủy | DS, TO | M | 023, 024, 030 |
| UC-08-11 | Đo theo lô, đối chiếu danh mục và ghi bản ghi lỗi | Hệ thống | M | 026, 027, 036 |
| UC-08-12 | Tính điểm có trọng số, so kỳ trước và xu hướng | Hệ thống | M | 028, 029 |
| UC-08-13 | Xử lý phụ thuộc không khả dụng khi đo | Hệ thống, TO | M | 031 |
| UC-08-14 | Đo tăng dần theo sự kiện PH-06, PH-07 | Hệ thống | S | 025 |
| UC-08-15 | Kiểm tra trực tuyến bản ghi từ luồng PH-04 | PH-04 | S | 032, 033 |
| UC-08-16 | Cổng chất lượng cho PH-06 và giám sát kiểm tra trực tuyến | PH-06, DS, TO | C | 034, 035 |
| UC-08-17 | Tra cứu, xem chi tiết và xuất bản ghi lỗi | DS, DO, DA | M | 037, 038, 039 |
| UC-08-18 | Đề nghị và duyệt ngoại lệ chấp nhận | DS, DA | S | 040 |
| UC-08-19 | Mở phiếu khắc phục, phân công và theo dõi SLA | DS, TA | M | 041, 042 |
| UC-08-20 | Nhận, xử lý và báo đã sửa phiếu khắc phục | DO | M | 043 |
| UC-08-21 | Đo lại kiểm chứng và xác nhận phiếu | Hệ thống, DS | M | 044 |
| UC-08-22 | Từ chối, chuyển, leo thang phiếu và chuyển lỗi sang PH-06 | DO, DS | S | 045, 046 |
| UC-08-23 | Khai báo, phát và xử lý cảnh báo chất lượng | DS, TO | S | 047, 048, 049 |
| UC-08-24 | Xem bảng điều khiển, thẻ điểm và so sánh liên tenant | VW, DS, DO, PA | M | 050, 051, 061 |
| UC-08-25 | Sinh, duyệt và công bố báo cáo kỳ, báo cáo năm | DS, DA | M | 052, 053, 054 |
| UC-08-26 | Xuất, ký số, phân phối báo cáo và đẩy chỉ số sang PH-16, PH-13 | DS, hệ thống | S | 055, 056, 057 |
| UC-08-27 | Tham số tenant, lưu giữ dữ liệu đo và nhật ký kiểm toán | TA, SO, AU | M | 058, 059, 060 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Bảng này là ma trận use case với màn hình (UI) và API. UC-08-11 đến UC-08-14 là use case máy, không có màn riêng; kết quả xem ở UI-08-12 và UI-08-11.

| UC | Màn hình | API |
|---|---|---|
| UC-08-01 | UI-08-19 | API-08-001…004 |
| UC-08-02 | UI-08-03, 04 | API-08-006, 008, 009, 013…018 |
| UC-08-03 | UI-08-02, 04 | API-08-005, 007, 010…012 |
| UC-08-04 | UI-08-05 | API-08-019…024 |
| UC-08-05 | UI-08-06, 07 | API-08-025…027, 029…033, 053 |
| UC-08-06 | UI-08-08, 06 | API-08-031, 032, 034…037 |
| UC-08-07 | UI-08-07, 09 | API-08-038…042 |
| UC-08-08 | UI-08-09, 06 | API-08-028, 030, 043…046 |
| UC-08-09 | UI-08-10 | API-08-047…052, 132 |
| UC-08-10 | UI-08-11, 04, 12 | API-08-054…063, 067 |
| UC-08-11 | UI-08-12 (xem kết quả) | API-08-061, 064, 067 |
| UC-08-12 | UI-08-12, 04 | API-08-065, 066 |
| UC-08-13 | UI-08-12 | API-08-061, 063 |
| UC-08-14 | UI-08-11 (xem kết quả) | API-08-060, 061, 130, 131 |
| UC-08-15 | UI-08-20 | API-08-068, 069, 071, 072 |
| UC-08-16 | UI-08-20 | API-08-068, 070…072 |
| UC-08-17 | UI-08-13, 14 | API-08-073…078 |
| UC-08-18 | UI-08-14, 13 | API-08-079…083 |
| UC-08-19 | UI-08-13, 15 | API-08-078, 084…087 |
| UC-08-20 | UI-08-15, 16 | API-08-085, 086, 088…090, 097 |
| UC-08-21 | UI-08-16 | API-08-086, 090, 091 |
| UC-08-22 | UI-08-15, 16 | API-08-092…096 |
| UC-08-23 | UI-08-17 | API-08-098…103 |
| UC-08-24 | UI-08-01, 04 | API-08-104…106, 128 |
| UC-08-25 | UI-08-18 | API-08-107…115 |
| UC-08-26 | UI-08-18, 19 | API-08-116…122 |
| UC-08-27 | UI-08-19, 04 | API-08-123…127 |

: Use case, màn hình và API

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

BP-10 "Đánh giá và cải thiện chất lượng dữ liệu" là quy trình do FRS đề nghị bổ sung (Phụ lục B của FRS); BP-02, 03, 07 đã có ở D02-01.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-08-01, 03, 04 | REQ-08 (04 thêm REQ-05) | BP-10 | — |
| UC-08-02 | REQ-08, REQ-06, REQ-07, REQ-05, REQ-09 | BP-10 | LGC-DMDC-006, 007, 008 (gián tiếp) |
| UC-08-05, 06, 07, 08, 09 | REQ-08 | BP-10 | LGC-NGSP-003, 005 (nguồn đối chiếu của 05, 06) |
| UC-08-10, 12, 13 | REQ-08 | BP-10 | — |
| UC-08-11 | REQ-08, REQ-07 | BP-10 | LGC-DMDC-006, 007, 008 (gián tiếp) |
| UC-08-14 | REQ-08, REQ-06, REQ-07 | BP-03, BP-10 | LGC-DMDC-006, 007, 008 (gián tiếp) |
| UC-08-15 | REQ-08, REQ-04 | BP-02 | — |
| UC-08-16 | REQ-08, REQ-06, REQ-13 | BP-02, BP-07 | LGC-BUS-027 (gián tiếp) |
| UC-08-17, 18 | REQ-08, REQ-09 | BP-10 | — |
| UC-08-19…22 | REQ-08 (22 thêm REQ-06) | BP-10 | — |
| UC-08-23 | REQ-08, REQ-13 | BP-07 | — |
| UC-08-24 | REQ-08, REQ-20 | BP-10 | — |
| UC-08-25 | REQ-08 | BP-10 | — |
| UC-08-26 | REQ-08, REQ-13, REQ-16 | BP-07, BP-10 | — |
| UC-08-27 | REQ-08 | BP-10 | — |

: Use case, REQ, quy trình và LGC

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực (số đuôi `UC-08-nn`). Không FR nào bị bỏ trống; FR-08-036 (ghi bản ghi lỗi) hiện thực ở UC-08-11 nhưng cũng chạm UC-08-15 khi bật `08.inline.persist-findings`.

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 01 | 022 | 05 | 043 | 20 |
| 002 | 02 | 023 | 10 | 044 | 21 |
| 003 | 02 | 024 | 10 | 045 | 22 |
| 004 | 02 | 025 | 14 | 046 | 22 |
| 005 | 02 | 026 | 11 | 047 | 23 |
| 006 | 03 | 027 | 11 | 048 | 23 |
| 007 | 03 | 028 | 12 | 049 | 23 |
| 008 | 04 | 029 | 12 | 050 | 24 |
| 009 | 04 | 030 | 10 | 051 | 24 |
| 010 | 04 | 031 | 13 | 052 | 25 |
| 011 | 04 | 032 | 15 | 053 | 25 |
| 012 | 05 | 033 | 15 | 054 | 25 |
| 013 | 05 | 034 | 16 | 055 | 26 |
| 014 | 06 | 035 | 16 | 056 | 26 |
| 015 | 06 | 036 | 11 | 057 | 26 |
| 016 | 06 | 037 | 17 | 058 | 27 |
| 017 | 07 | 038 | 17 | 059 | 27 |
| 018 | 07 | 039 | 17 | 060 | 27 |
| 019 | 08 | 040 | 18 | 061 | 24 |
| 020 | 08 | 041 | 19 | | |
| 021 | 09 | 042 | 19 | | |

: Ma trận FR và use case

### 5.5. FR repo, REQ và LGC liên quan

Bảng ánh xạ 16 FR của SRS cũ (`docs/07-srs/SRS-PH-08-dq.md`, gọi là "FR repo") sang FR mới và use case; mã cũ đổi nghĩa ở bản mới (FRS §11.3). Sau bảng là kết luận về LGC liên quan gián tiếp.

| FR repo | Nội dung cũ | FR mới | UC |
|---|---|---|---|
| 001 | Quản lý miền dữ liệu và bộ luật | 001, 012, 017, 018 | UC-08-01, 05, 07 |
| 002 | Định nghĩa luật theo chiều | 013, 014 | UC-08-05, 06 |
| 003 | Trọng số và ngưỡng đạt | 021 | UC-08-09 |
| 004 | Nhập, xuất, sao chép bộ luật | 020 | UC-08-08 |
| 005 | Lập lịch và kích hoạt quét | 002, 004, 023, 024, 030 | UC-08-02, 10 |
| 006 | Thực thi kiểm tra sáu chiều | 026, 027, 031, 036 | UC-08-11, 13 |
| 007 | Chấm điểm có trọng số | 028 | UC-08-12 |
| 008 | So sánh với kỳ trước | 029 | UC-08-12 |
| 009 | Kiểm tra đồng bộ (inline) | 032, 033 | UC-08-15 |
| 010 | Sinh báo cáo chất lượng kỳ | 052, 053 | UC-08-25 |
| 011 | Báo cáo chính thức hằng năm | 054 | UC-08-25 |
| 012 | Phân phối báo cáo và thông báo | 048, 056 | UC-08-23, 26 |
| 013 | Mở ticket khắc phục từ finding | 041, 042 | UC-08-19 |
| 014 | Cập nhật tiến độ khắc phục | 043, 044, 045 | UC-08-20, 21, 22 |
| 015 | Đánh giá lại sau khắc phục | 044 | UC-08-21 |
| 016 | Đẩy chỉ số sang PH-16 | 057 | UC-08-26 |

: Ánh xạ FR repo sang FR mới và use case

| LGC, REQ | Kết luận | UC |
|---|---|---|
| LGC-DMDC-006, 007, 008 (nhập danh mục Excel, CSV, API) | PH-07 làm chính; PH-08 chỉ đo chất lượng danh mục sau nhập, không thay chức năng | UC-08-02, 11, 14 |
| LGC-BUS-027 (thống kê theo endpoint) | PH-13 làm chính; PH-08 bổ sung thống kê lỗi chất lượng theo luồng | UC-08-16 |
| LGC-NGSP-003, 005 (BHXH, đăng ký kinh doanh) | PH-14 làm chính; PH-08 dùng dữ liệu làm nguồn đối chiếu chiều nhất quán | UC-08-05, 06 |
| REQ-08 | Chất lượng dữ liệu, năng lực mới; thêm REQ-04, 05, 06, 07, 09, 13, 16, 20 ở bảng 5.3 | Cả 27 UC |

: LGC và REQ liên quan

## 6. Đặc tả chi tiết use case

Chương này đặc tả 27 use case theo vòng đời: khai báo (UC-08-01…04), quy tắc (05…09), đo (10…16), lỗi và khắc phục (17…22), cảnh báo, báo cáo và quản trị (23…27). Mỗi use case một khối 15 mục; nhánh thay thế và ngoại lệ chỉ ghi điều khác với FR, hành vi từng bước xem FR tương ứng.

### 6.1. UC-08-01 · Khai báo miền chất lượng, chủ quản và cán bộ phụ trách

Miền chất lượng là tầng giao trách nhiệm: mỗi miền có một tổ chức chủ quản (DO) và một cán bộ phụ trách (DS), nên mọi lỗi và phiếu về sau biết giao cho ai.

::: dac-ta
**Mục tiêu.** Tenant có miền `DAN-CU` (Dân cư) gắn Sở Tư pháp làm chủ quản và Lan làm cán bộ phụ trách, sẵn sàng nhận đối tượng đo.

**Tác nhân chính.** TA (Mai), DS (Lan).

**Tác nhân phụ.** Danh bạ tổ chức và người dùng (PH-01), DO (Phúc, người được gán).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-001.

**Truy vết.** REQ-08; BP-10 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Mai có `PERM-08-asset`; tổ chức chủ quản `ACTIVE` ở PH-01; Lan có vai DS.

**Kích hoạt.** Mai chọn "Thêm miền" ở tab Miền của UI-08-19.

**Đảm bảo tối thiểu.** Không tạo miền thiếu chủ quản hoặc cán bộ phụ trách; mọi thay đổi có kiểm toán.

**Đảm bảo thành công.** Miền ở trạng thái dùng được; đối tượng đo của miền hiện cho DO của tổ chức chủ quản (BR-08-026).

**Luồng chính.**
1. Mai nhập mã `DAN-CU`, tên "Dân cư", chọn tổ chức chủ quản "Sở Tư pháp" và cán bộ phụ trách Lan.
2. Hệ thống gọi API-08-002 kèm `Idempotency-Key`, kiểm mã chưa dùng và hai bên hợp lệ.
3. Hệ thống tạo miền, ghi kiểm toán, trả `201`.
4. Mai mở lại miền (API-08-003) thấy chủ quản, cán bộ phụ trách và số đối tượng đo bằng 0.

**Luồng thay thế.**
- **1a. Đổi chủ quản hoặc cán bộ.** Mai sửa (API-08-004 kèm `If-Match`); phiếu đang mở giữ chủ quản cũ, phiếu mới theo chủ quản mới.
- **1b. Xem danh sách.** Lan lọc miền theo tổ chức (API-08-001).

**Luồng ngoại lệ.**
- **E1. Mã trùng (bước 2).** ERR-08-002 (409): "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Thiếu hoặc sai chủ quản, cán bộ (bước 2).** ERR-08-008 (422): "Miền {mã} cần tổ chức chủ quản và cán bộ phụ trách hợp lệ trước khi dùng."
- **E3. Sửa bằng bản cũ (1a).** ERR-08-004 (409): "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."

**Quy tắc áp dụng.** BR-08-026.

**Màn hình, API.** UI-08-19; API-08-001…004; kịch bản TS-08-01.
:::

```{.mermaid caption="Trình tự khai báo miền chất lượng"}
sequenceDiagram
  actor TA
  participant C as dh-console
  participant Q as dq-control
  participant P as PH-01
  TA->>C: Nhập miền DAN-CU, chủ quản, cán bộ
  C->>Q: POST /domains (API-08-002)
  Q->>P: Kiểm tổ chức và người dùng
  P-->>Q: Hợp lệ
  Q->>Q: Tạo miền, ghi kiểm toán
  Q-->>C: 201
```

Hình cho thấy việc kiểm tổ chức và người dùng diễn ra ở PH-01 trước khi miền được tạo, nên không có miền mồ côi.

### 6.2. UC-08-02 · Đăng ký đối tượng đo và khai báo CDE

Đối tượng đo có bốn loại; ba loại đầu đăng ký bằng wizard bốn bước: loại, nguồn, trường, CDE. Loại `FLOW_MESSAGE` chỉ dùng cho kiểm tra trực tuyến (UC-08-15).

::: dac-ta
**Mục tiêu.** Đối tượng đo `MDM-CITIZEN` (domain `CITIZEN` của PH-06) ở trạng thái `ACTIVE`, có ít nhất một CDE kèm phân loại PH-09.

**Tác nhân chính.** DS (Lan); TA.

**Tác nhân phụ.** PH-06 (khung nhìn hợp đồng), PH-07 (danh mục), PH-05 (kết nối chỉ đọc), PH-09 (phân loại).

**Mức ưu tiên.** M (đăng ký nguồn HTTT qua PH-05 là S) · Đợt 3.

**FR hiện thực.** FR-08-002, FR-08-003, FR-08-004, FR-08-005.

**Truy vết.** REQ-08, REQ-06, REQ-07, REQ-05, REQ-09; BP-10; LGC-DMDC-006…008 (gián tiếp).

**Tiền điều kiện.** Có `PERM-08-asset`; miền đã khai báo (UC-08-01); với `MDM_DOMAIN`, domain `ACTIVE` và đã có khung nhìn `ph06_mdm.v_dq_{domain}` (Q08-08).

**Kích hoạt.** Lan bấm "Đăng ký đối tượng" ở UI-08-02, mở wizard UI-08-03.

**Đảm bảo tối thiểu.** Không đăng ký CSDL control của Datahub; không đọc bảng vật lý của PH-06 (BR-08-004, BR-08-005). Nháp `DRAFT` giữ nguyên khi lỗi.

**Đảm bảo thành công.** `asset_status = ACTIVE`; có lịch tự tạo `08.scan.default-cron` (ngày 1, 02:00) và, nếu `08.profile.on-activate`, một lần hồ sơ.

**Luồng chính.**
1. Lan chọn loại `MDM_DOMAIN`, nguồn là domain `CITIZEN` (API-08-016), miền `DAN-CU`, mã `MDM-CITIZEN`.
2. Hệ thống tạo nháp (API-08-006), đọc lược đồ khung nhìn hợp đồng và liệt kê trường (API-08-013).
3. Lan chọn khóa bản ghi `goldenId` và đánh dấu CDE: `soDinhDanh`, `hoTen`, `ngaySinh`, `maDonViHanhChinh`.
4. Hệ thống lấy phân loại từng CDE từ PH-09 (API-08-015); `soDinhDanh` là `SENSITIVE`.
5. Lan bấm "Kích hoạt"; hệ thống kiểm có ít nhất một CDE (BR-08-031), đặt `ACTIVE` (API-08-009), tạo lịch mặc định.

**Luồng thay thế.**
- **1a. Danh mục PH-07.** Chọn `RDM_CATALOG` `DVHC` (API-08-017), khóa là mã mục.
- **1b. Nguồn HTTT.** Chọn kết nối `conn-hotich-ro` rồi bảng `khai_sinh` (API-08-018 khám phá lược đồ); bảng phải có khóa bản ghi.
- **4a. Phân loại chưa xác nhận.** Hệ thống cảnh báo vàng, che trường như `SENSITIVE`, không chặn.

**Luồng ngoại lệ.**
- **E1. Domain chưa sẵn sàng (bước 1).** ERR-08-009 (422): "Domain {mã} chưa sẵn sàng cho đo chất lượng. Đề nghị PH-06 cấp khung nhìn hợp đồng."
- **E2. Danh mục chưa phát hành (1a).** ERR-08-010 (422): "Danh mục {mã} chưa phát hành ở PH-07."
- **E3. Kết nối sai loại (1b).** ERR-08-011 (422): "Kết nối {mã} không phải kết nối chỉ đọc được cấp cho chất lượng dữ liệu."
- **E4. Bảng thuộc CSDL control (1b).** ERR-08-012 (422): "Không đo được bảng {tên}. Bảng không tồn tại hoặc thuộc CSDL quản trị của Datahub."
- **E5. Khóa sai (bước 3).** ERR-08-013 (422): "Khóa bản ghi {cột} không có trong bảng {tên}."
- **E6. Phân loại chưa xác nhận (4a).** ERR-08-047 (422, chỉ cảnh báo): "Trường {đường dẫn} chưa có phân loại xác nhận ở PH-09. Giá trị sẽ được che như dữ liệu Nhạy cảm."

**Quy tắc áp dụng.** BR-08-003, BR-08-004, BR-08-005, BR-08-012, BR-08-031.

**Màn hình, API.** UI-08-03, 04; API-08-006, 008, 009, 013…018; kịch bản TS-08-02.
:::

```{.mermaid caption="Trình tự đăng ký đối tượng đo từ domain PH-06"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant M as PH-06
  participant G as PH-09
  DS->>Q: Chọn domain CITIZEN, miền DAN-CU
  Q->>M: Đọc lược đồ khung nhìn hợp đồng
  M-->>Q: Danh sách trường
  DS->>Q: Chọn khóa và CDE
  Q->>G: Tra phân loại từng CDE
  G-->>Q: soDinhDanh SENSITIVE
  DS->>Q: Kích hoạt (API-08-009)
  Q->>Q: Tạo lịch mặc định, hồ sơ đầu tiên
```

Hình cho thấy PH-08 chỉ đọc lược đồ qua khung nhìn hợp đồng của PH-06 và lấy phân loại từ PH-09, không tự suy ra mức nhạy cảm.

### 6.3. UC-08-03 · Tìm, xem, ngừng và khôi phục đối tượng đo

Đối tượng ngừng khỏi vòng đo khi nguồn thôi dùng hoặc đang bảo trì; khôi phục được trong thời hạn lưu giữ. Đối tượng bị ngừng không còn lịch đo nhưng điểm cũ giữ nguyên.

::: dac-ta
**Mục tiêu.** Người dùng tìm và xem đối tượng trong phạm vi của mình; DS tạm ngừng, khôi phục hoặc ngừng hẳn đối tượng không còn cần đo.

**Tác nhân chính.** DS (Lan); DO (Phúc, chỉ xem).

**Tác nhân phụ.** bộ lập lịch nội bộ (tạm dừng lịch), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-006, FR-08-007.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-read`; để ngừng hoặc khôi phục cần `PERM-08-asset`.

**Kích hoạt.** Lan mở UI-08-02, hoặc bấm "Tạm ngừng" ở UI-08-04.

**Đảm bảo tối thiểu.** Điểm, lỗi, phiếu đã có không bị xóa khi ngừng.

**Đảm bảo thành công.** `asset_status` chuyển đúng (`SUSPENDED`, `ACTIVE`, `RETIRED`); lịch đo tương ứng dừng hoặc chạy lại.

**Luồng chính.**
1. Lan mở UI-08-02, lọc theo miền `DAN-CU`, loại `SOURCE_DATASET`, kết luận `FAIL` (API-08-005).
2. Hệ thống trả danh sách theo phạm vi; Phúc chỉ thấy đối tượng của Sở Tư pháp (BR-08-026).
3. Lan mở `SRC-HOTICH` (API-08-007) xem thẻ điểm, CDE, lịch.
4. Lan bấm "Tạm ngừng" kèm lý do (API-08-010); hệ thống đặt `SUSPENDED` và tạm dừng lịch.

**Luồng thay thế.**
- **4a. Khôi phục.** Lan bấm "Tiếp tục" (API-08-011); hệ thống đặt `ACTIVE`, bật lại lịch.
- **4b. Ngừng hẳn.** Lan bấm "Ngừng" (API-08-012); đối tượng `RETIRED`, phiếu còn mở được đóng với lý do đối tượng ngừng.
- **4c. Đang có lần đo.** Hệ thống hủy lần `QUEUED`, đợi lần `RUNNING` kết thúc (BR-08-020).

**Luồng ngoại lệ.**
- **E1. Ngoài phạm vi tổ chức (bước 3).** ERR-08-032 (403): "Đối tượng {mã} không thuộc tổ chức của anh/chị."
- **E2. Trạng thái không cho phép (bước 4).** ERR-08-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E3. Thiếu lý do (bước 4).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."
- **E4. Tham số lọc sai (bước 1).** ERR-08-045 (422): "Tham số {tên} không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-08-020, BR-08-026, BR-08-028.

**Màn hình, API.** UI-08-02, 04; API-08-005, 007, 010…012; kịch bản TS-08-03.
:::

```{.mermaid caption="Trình tự tạm ngừng và khôi phục đối tượng đo"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant S as Bộ lập lịch nội bộ
  DS->>Q: Tạm ngừng SRC-HOTICH kèm lý do (API-08-010)
  Q->>Q: Đặt SUSPENDED, hủy lần QUEUED
  Q->>S: Tạm dừng lịch đo
  Q-->>DS: 200
  DS->>Q: Tiếp tục (API-08-011)
  Q->>S: Bật lại lịch
```

Hình cho thấy ngừng đối tượng đồng thời dừng lịch ở bộ lập lịch nội bộ, nên không còn lần đo chạy ngầm trên nguồn đã ngừng.

### 6.4. UC-08-04 · Chạy hồ sơ dữ liệu và gợi ý quy tắc

Hồ sơ dữ liệu giúp DS biết cột nào hay trống, trùng, lệch trước khi viết quy tắc. Với trường Nhạy cảm, hồ sơ không lưu giá trị gốc (BR-08-012).

::: dac-ta
**Mục tiêu.** Lan có hồ sơ từng cột của `SRC-HOTICH` và nhận gợi ý quy tắc để đưa vào bản nháp.

**Tác nhân chính.** DS (Lan).

**Tác nhân phụ.** Nguồn đo qua kết nối PH-05, PH-05 (đẩy chỉ số).

**Mức ưu tiên.** S (FR-08-010, 011 là C) · Đợt 3.

**FR hiện thực.** FR-08-008, FR-08-009, FR-08-010, FR-08-011.

**Truy vết.** REQ-08, REQ-05; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-asset`; đối tượng loại `MDM_DOMAIN`, `RDM_CATALOG` hoặc `SOURCE_DATASET`.

**Kích hoạt.** Lan bấm "Chạy hồ sơ" ở UI-08-05, hoặc tự chạy khi kích hoạt đối tượng.

**Đảm bảo tối thiểu.** Lần hồ sơ lỗi không làm đổi bộ quy tắc hay điểm; chỉ `SELECT` trong cửa sổ giờ, timeout 15 phút (BR-08-025).

**Đảm bảo thành công.** `profile_run.status = SUCCEEDED`; thống kê từng cột (tỷ lệ rỗng, số giá trị khác nhau, phân vị) xem được.

**Luồng chính.**
1. Lan bấm "Chạy hồ sơ" (API-08-019), chọn mẫu hoặc toàn bộ.
2. Hệ thống kiểm không có lần hồ sơ hoặc lần đo đang chạy, tạo `profile_run` `QUEUED`.
3. Bộ thực thi tính thống kê bằng DataSketches, che giá trị mẫu theo phân loại, đặt `SUCCEEDED`.
4. Lan mở thẻ cột (API-08-022) thấy `ngaySinh` rỗng 3,2%, `soDinhDanh` trùng 0,4%.
5. Lan bấm "Gợi ý quy tắc" (API-08-023), chọn quy tắc `NOT_NULL ngaySinh` để thêm vào nháp (API-08-031).

**Luồng thay thế.**
- **1a. So lần trước.** Lan xem chênh lệch so với lần hồ sơ trước ở UI-08-05.
- **3a. PH-05 đẩy chỉ số.** Nguồn đã có chỉ số hồ sơ thì PH-05 gọi API-08-024 (nội bộ); hệ thống nhận, không tự đọc nguồn.

**Luồng ngoại lệ.**
- **E1. Đang có lần chạy (bước 2).** ERR-08-028 (409): "Đối tượng đang có lần chạy {mã}. Đợi lần này xong hoặc hủy."
- **E2. Bản tin trên luồng (bước 1).** ERR-08-050 (422): "Đối tượng loại bản tin trên luồng không chạy hồ sơ hoặc đo theo lô."
- **E3. Hồ sơ thất bại (bước 3).** ERR-08-111: "Lần hồ sơ {mã} thất bại: {nguyên nhân}." (hiển thị ở UI-08-05, PH-13)
- **E4. Nguồn không đọc được (bước 3).** ERR-08-105 (503): "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau."
- **E5. Lô chỉ số PH-05 sai định dạng (3a).** ERR-08-118 (422): "Lô dữ liệu từ {nguồn} sai định dạng: {chi tiết}."

**Quy tắc áp dụng.** BR-08-012, BR-08-025.

**Màn hình, API.** UI-08-05; API-08-019…024; kịch bản TS-08-04.
:::

```{.mermaid caption="Trình tự chạy hồ sơ dữ liệu và gợi ý quy tắc"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant W as dq-worker
  participant N as Nguồn (bản sao chỉ đọc)
  DS->>Q: Chạy hồ sơ (API-08-019)
  Q->>W: Giao tác vụ hồ sơ
  W->>N: SELECT thống kê theo cột
  N-->>W: Số đếm, phân vị
  W->>Q: Lưu profile_column đã che
  DS->>Q: Gợi ý quy tắc (API-08-023)
  Q-->>DS: Danh sách quy tắc đề xuất
```

Hình cho thấy chỉ bộ thực thi chạm tới nguồn, bằng truy vấn đọc, và kết quả đã che trước khi lưu.

### 6.5. UC-08-05 · Soạn bộ quy tắc và định nghĩa quy tắc theo chiều

Mỗi quy tắc thuộc đúng một trong sáu chiều và dùng một toán tử của chiều đó (FRS §4.1). Mỗi bộ có tối đa một bản nháp và một phiên bản `ACTIVE` (BR-08-006).

::: dac-ta
**Mục tiêu.** Lan có bản nháp phiên bản 4 của `RS-CITIZEN` với các quy tắc đủ sáu chiều.

**Tác nhân chính.** DS (Lan).

**Tác nhân phụ.** PH-07 (danh mục cho chiều hợp lệ), đối tượng đo nguồn đối chiếu.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-012, FR-08-013, FR-08-022.

**Truy vết.** REQ-08; BP-10; LGC-NGSP-003, 005 (nguồn đối chiếu, gián tiếp).

**Tiền điều kiện.** Có `PERM-08-rule-admin`; đối tượng `MDM-CITIZEN` `DRAFT` hoặc `ACTIVE`.

**Kích hoạt.** Lan bấm "Tạo phiên bản nháp" ở UI-08-06, mở trình soạn UI-08-07.

**Đảm bảo tối thiểu.** Phiên bản `ACTIVE` đang chạy không đổi trong lúc sửa nháp.

**Đảm bảo thành công.** Nháp có ít nhất một quy tắc bật; mọi quy tắc qua kiểm tra trường, toán tử, chiều.

**Luồng chính.**
1. Lan tạo phiên bản nháp từ bản `ACTIVE` (API-08-029); hệ thống sao các quy tắc sang nháp.
2. Lan thêm quy tắc `R-NS-01`: chiều `COMPLETENESS`, toán tử `NOT_NULL`, trường `ngaySinh`, mức `MAJOR` (API-08-031).
3. Lan thêm `R-MA-01`: chiều `VALIDITY`, toán tử `IN_RDM`, trường `maDonViHanhChinh`, danh mục `DVHC` (BR-08-003).
4. Hệ thống kiểm trường thuộc lược đồ, toán tử đúng chiều, tham số hợp lệ; lưu quy tắc, đặt nháp "chưa chạy thử".
5. Lan lọc bảng quy tắc theo chiều, trạng thái (API-08-053) để rà độ phủ CDE.

**Luồng thay thế.**
- **2a. Sửa hoặc xóa quy tắc.** API-08-032, API-08-033; mỗi sửa làm mất dấu chạy thử (BR-08-006).
- **3a. Chiều nhất quán.** `EQ_SOURCE` chọn đối tượng đo và trường đối chiếu, ví dụ ngày sinh với nguồn BHXH.
- **1a. Quy tắc gợi ý.** Thêm từ UC-08-04.

**Luồng ngoại lệ.**
- **E1. Đã có nháp (bước 1).** ERR-08-022 (409): "Bộ quy tắc {mã} đang có bản nháp phiên bản {n} do {người} tạo."
- **E2. Trường không có (bước 2).** ERR-08-014 (422): "Trường {đường dẫn} không có trong đối tượng đo {mã}."
- **E3. Toán tử sai chiều (bước 2).** ERR-08-015 (422): "Toán tử {toán tử} không dùng được cho chiều {chiều}."
- **E4. Tham số sai (bước 2).** ERR-08-016 (422): "Tham số {tên} của quy tắc {mã} không hợp lệ: {chi tiết}." Quy tắc `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE` mà đặt `INLINE` hoặc `BOTH` cũng bị mã này, với tham số `execMode` (BR-08-017).
- **E5. Thiếu danh mục (bước 3).** ERR-08-017 (422): "Quy tắc chiều Hợp lệ phải chọn danh mục PH-07 để đối chiếu."
- **E6. Thiếu nguồn đối chiếu (3a).** ERR-08-018 (422): "Quy tắc chiều Nhất quán phải chọn đối tượng đo và trường để đối chiếu."
- **E7. Phiên bản chưa có quy tắc bật.** ERR-08-021 (422): "Phiên bản {n} chưa có quy tắc nào đang bật."

**Quy tắc áp dụng.** BR-08-003, BR-08-006, BR-08-017, BR-08-031.

**Màn hình, API.** UI-08-06, 07; API-08-025…027, 029…033, 053; kịch bản TS-08-05.
:::

```{.mermaid caption="Trình tự soạn bản nháp và thêm quy tắc"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant R as PH-07
  DS->>Q: Tạo nháp từ phiên bản ACTIVE (API-08-029)
  Q-->>DS: Nháp v4 kèm quy tắc đã sao
  DS->>Q: Thêm quy tắc IN_RDM DVHC (API-08-031)
  Q->>R: Kiểm danh mục DVHC đã phát hành
  R-->>Q: Hợp lệ
  Q->>Q: Kiểm trường, toán tử, chiều
  Q-->>DS: 201, nháp chưa chạy thử
```

Hình cho thấy danh mục của chiều hợp lệ được kiểm ngay lúc soạn ở PH-07, thay vì để đến lúc đo mới phát hiện.

### 6.6. UC-08-06 · Quy tắc nâng cao, thư viện mẫu và chạy thử

Điều kiện không diễn đạt được bằng toán tử có sẵn dùng biểu thức CEL (mức bản ghi) hoặc vị từ SQL có kiểm soát (mức tập, chỉ chạy lô). Quy tắc mẫu ở `COMMON` (CCCD, MST, SĐT, email, ĐVHC) giúp tỉnh không phải viết lại.

::: dac-ta
**Mục tiêu.** Lan thêm quy tắc kiểm cấu trúc CCCD từ mẫu `TPL-CCCD` và một biểu thức CEL, rồi chạy thử trên mẫu 5.000 bản ghi.

**Tác nhân chính.** DS (Lan); PA (Hà, quản mẫu `COMMON`).

**Tác nhân phụ.** Nguồn đo (bản sao chỉ đọc), PH-07.

**Mức ưu tiên.** M (FR-08-014, 015 là S) · Đợt 3.

**FR hiện thực.** FR-08-014, FR-08-015, FR-08-016.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có nháp (UC-08-05); `08.rule.sql-predicate-enabled` bật nếu dùng `SQL_PREDICATE`.

**Kích hoạt.** Lan mở ngăn kéo UI-08-08 từ trình soạn.

**Đảm bảo tối thiểu.** Chạy thử không ghi bản ghi lỗi, không đổi điểm; giá trị Nhạy cảm che (BR-08-012).

**Đảm bảo thành công.** Quy tắc có kết quả chạy thử (số đạt, vi phạm, mẫu vi phạm đã che); dấu "đã chạy thử" gắn với nội dung hiện tại.

**Luồng chính.**
1. Lan chọn "Thêm từ thư viện" (API-08-035), chọn `TPL-CCCD`; hệ thống điền toán tử `REGEX` cộng CEL cho mã tỉnh, giới tính, thế kỷ (Q08-16).
2. Lan thêm quy tắc `CEL_EXPRESSION`: `ngayCap >= ngaySinh + duration("5110d")`.
3. Hệ thống kiểm biểu thức (API-08-034): cú pháp, kiểu, chi phí.
4. Lan bấm "Chạy thử", cỡ mẫu 5.000 (API-08-037).
5. Hệ thống chạy trên mẫu theo seed 64 bit, trả đạt 4.912, vi phạm 88, kèm mười mẫu đã che.

**Luồng thay thế.**
- **2a. Vị từ SQL.** Chỉ điều kiện trên cột của bảng đang đo; chạy lô, không chạy trực tuyến (BR-08-017).
- **1a. PA sửa mẫu.** Hà tạo phiên bản mẫu mới (API-08-036); quy tắc đã dùng giữ phiên bản cũ (BR-08-032).
- **4a. Chạy lại cùng seed.** Cho cùng tập mẫu (BR-08-019).

**Luồng ngoại lệ.**
- **E1. CEL sai (bước 3).** ERR-08-019 (422): "Biểu thức không hợp lệ ở vị trí {dòng}:{cột}: {chi tiết}."
- **E2. SQL vi phạm danh sách cho phép (2a).** ERR-08-020 (422): "Vị từ SQL dùng {thành phần} không được phép. Chỉ được viết điều kiện trên cột của bảng đang đo."
- **E3. Mẫu quá lớn (bước 4).** ERR-08-031 (422): "Chạy thử tối đa {n} bản ghi. Giảm kích thước mẫu."
- **E4. Nguồn không đọc được (bước 5).** ERR-08-105 (503): "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau."

**Quy tắc áp dụng.** BR-08-012, BR-08-017, BR-08-019, BR-08-032.

**Màn hình, API.** UI-08-08, 06; API-08-031, 032, 034…037; kịch bản TS-08-06.
:::

```{.mermaid caption="Trình tự kiểm biểu thức CEL và chạy thử"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant W as dq-worker
  participant N as Nguồn chỉ đọc
  DS->>Q: Kiểm biểu thức (API-08-034)
  Q-->>DS: Hợp lệ, chi phí thấp
  DS->>Q: Chạy thử mẫu 5.000 (API-08-037)
  Q->>W: Giao chạy thử kèm seed
  W->>N: Lấy mẫu, chạy quy tắc
  W-->>Q: Đạt, vi phạm, mẫu che
  Q-->>DS: Kết quả, đánh dấu đã chạy thử
```

Hình cho thấy chạy thử đi qua bộ thực thi giống lúc đo thật nhưng không ghi lỗi, nên kết quả dự báo sát điểm sau kích hoạt.

### 6.7. UC-08-07 · Gửi duyệt, duyệt, kích hoạt và ngừng bộ quy tắc

Bộ quy tắc quyết định điểm của mọi lần đo sau, nên kích hoạt qua bốn mắt: Lan gửi, Hùng duyệt (LP-08-01). Phiên bản mới `ACTIVE` đẩy phiên bản cũ sang `SUPERSEDED`.

::: dac-ta
**Mục tiêu.** Phiên bản 4 của `RS-CITIZEN` có hiệu lực từ 01/12/2026, được duyệt bởi người khác người soạn.

**Tác nhân chính.** DS (Lan, gửi), DA (Hùng, duyệt).

**Tác nhân phụ.** Kafka, `dq-inline` (bộ đệm), PH-13, "Việc của tôi".

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-017, FR-08-018.

**Truy vết.** REQ-08; FR-00-071, ADR-046; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Nháp đã chạy thử nội dung hiện tại và có quy tắc bật; Hùng có `PERM-08-approve`, khác Lan.

**Kích hoạt.** Lan bấm "Gửi duyệt" ở UI-08-07; Hùng mở việc ở UI-08-09.

**Đảm bảo tối thiểu.** Phiên bản `PENDING_APPROVAL` khóa nội dung; từ chối đưa về `DRAFT`, phiên bản `ACTIVE` cũ vẫn chạy.

**Đảm bảo thành công.** Phiên bản 4 `ACTIVE`, phiên bản 3 `SUPERSEDED`; phát EVT-08-01.

**Luồng chính.**
1. Lan bấm "Gửi duyệt" kèm ghi chú (API-08-038); hệ thống kiểm đã chạy thử, đặt `PENDING_APPROVAL`.
2. Hệ thống đẩy việc vào "Việc của tôi" của Hùng.
3. Hùng xem so sánh với phiên bản 3 (UC-08-08), bấm "Duyệt" chọn hiệu lực ngay (API-08-039); hệ thống kiểm Hùng khác Lan.
4. Hệ thống kích hoạt (API-08-041): đặt v4 `ACTIVE`, v3 `SUPERSEDED`, ghi kiểm toán.
5. Hệ thống phát EVT-08-01; `dq-inline` nạp lại bộ đệm.

**Luồng thay thế.**
- **3a. Từ chối.** Hùng nhập lý do ≥ 20 ký tự (API-08-040); phiên bản về `DRAFT`.
- **3b. Hiệu lực tương lai.** Phiên bản `APPROVED` rồi tự `ACTIVE` đến `effectiveFrom`.
- **5a. Ngừng bộ quy tắc.** Lan hoặc Hùng ngừng (API-08-042); phiên bản `ACTIVE` thành `RETIRED`, đối tượng hết điểm mới.

**Luồng ngoại lệ.**
- **E1. Chưa chạy thử (bước 1).** ERR-08-053 (422): "Chạy thử phiên bản sau lần sửa cuối trước khi gửi duyệt."
- **E2. Không có quy tắc bật (bước 1).** ERR-08-021 (422): "Phiên bản {n} chưa có quy tắc nào đang bật."
- **E3. Tự duyệt (bước 3).** ERR-08-005 (403): "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."
- **E4. Từ chối thiếu lý do (3a).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."
- **E5. Sai trạng thái (bước 4).** ERR-08-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

**Quy tắc áp dụng.** BR-08-006, BR-08-007, BR-08-008.

**Màn hình, API.** UI-08-07, 09; API-08-038…042; kịch bản TS-08-07.
:::

```{.mermaid caption="Trình tự gửi duyệt và kích hoạt bộ quy tắc bốn mắt"}
sequenceDiagram
  actor DS
  actor DA
  participant Q as dq-control
  participant K as Kafka
  participant I as dq-inline
  DS->>Q: Gửi duyệt v4 (API-08-038)
  Q->>Q: Khóa nội dung, PENDING_APPROVAL
  Q-->>DA: Việc cần duyệt
  DA->>Q: Duyệt (API-08-039)
  Q->>Q: Kiểm DA khác DS
  Q->>Q: v4 ACTIVE, v3 SUPERSEDED
  Q->>K: EVT-08-01 ruleset.activated
  K->>I: Nạp lại bộ đệm quy tắc
```

Hình cho thấy việc kiểm "người duyệt khác người gửi" nằm trước khi phiên bản đổi trạng thái, và bộ đệm trực tuyến chỉ nạp lại sau khi phát sự kiện.

### 6.8. UC-08-08 · So sánh phiên bản, sao chép, nhập và xuất bộ quy tắc

DA cần thấy phiên bản mới khác phiên bản cũ ở đâu trước khi duyệt; DS cần tái dùng bộ quy tắc giữa đối tượng tương tự hoặc giữa tỉnh với nhau.

::: dac-ta
**Mục tiêu.** Hùng thấy đúng các quy tắc thêm, bớt, đổi giữa hai phiên bản; Lan sao chép `RS-CITIZEN` sang đối tượng tương tự hoặc nhập, xuất bộ quy tắc dạng YAML hoặc JSON.

**Tác nhân chính.** DS (Lan); DA (Hùng, xem so sánh).

**Tác nhân phụ.** Không.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-019, FR-08-020.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-read`; sao chép, nhập cần `PERM-08-rule-admin`.

**Kích hoạt.** Mở tab lịch sử ở UI-08-09, hoặc bấm "Sao chép", "Nhập", "Xuất" ở UI-08-06.

**Đảm bảo tối thiểu.** Nhập hoặc sao chép lỗi không tạo bản nháp dở.

**Đảm bảo thành công.** Có bản so sánh; hoặc có bản nháp mới `DRAFT` ở đối tượng đích; hoặc có tệp xuất.

**Luồng chính.**
1. Hùng mở UI-08-09, chọn phiên bản 3 và 4; hệ thống gọi API-08-043 và hiện quy tắc thêm, bớt, đổi tham số, trọng số.
2. Lan bấm "Sao chép" (API-08-044) sang `MDM-CITIZEN-BAK` (đối tượng tương thích).
3. Hệ thống kiểm mọi trường quy tắc có ở đối tượng đích, tạo bản nháp phiên bản 1.
4. Lan bấm "Xuất" (API-08-045), chọn YAML, tải tệp.

**Luồng thay thế.**
- **1a. Lịch sử.** Lan xem danh sách phiên bản và người đổi (API-08-028, 030).
- **2a. Nhập tệp.** Lan chọn tệp YAML (API-08-046); hệ thống kiểm lược đồ rồi tạo nháp.
- **3a. Ánh xạ trường.** Đích thiếu trường thì Lan khai báo ánh xạ rồi sao chép lại.

**Luồng ngoại lệ.**
- **E1. Đích thiếu trường (bước 3).** ERR-08-026 (422): "Đối tượng đích thiếu trường {danh sách}. Khai báo ánh xạ trường trước khi sao chép."
- **E2. Tệp sai định dạng (2a).** ERR-08-025 (422): "Tệp không đúng định dạng bộ quy tắc ở {vị trí}: {chi tiết}."
- **E3. Tệp quá lớn (2a).** ERR-08-046 (413): "Tệp vượt {n} MB."
- **E4. Đích đã có nháp (bước 3).** ERR-08-022 (409): "Bộ quy tắc {mã} đang có bản nháp phiên bản {n} do {người} tạo."

**Quy tắc áp dụng.** BR-08-006, BR-08-012.

**Màn hình, API.** UI-08-09, 06; API-08-028, 030, 043…046; kịch bản TS-08-08.
:::

```{.mermaid caption="Trình tự so sánh phiên bản và sao chép bộ quy tắc"}
sequenceDiagram
  actor DA
  actor DS
  participant Q as dq-control
  DA->>Q: So sánh v3 và v4 (API-08-043)
  Q-->>DA: Quy tắc thêm, bớt, đổi
  DS->>Q: Sao chép sang đối tượng đích (API-08-044)
  Q->>Q: Kiểm trường tương thích
  Q-->>DS: Nháp phiên bản 1 ở đối tượng đích
```

Hình cho thấy so sánh là thao tác chỉ đọc, còn sao chép luôn tạo bản nháp mới và phải qua chạy thử, duyệt như mọi bộ quy tắc.

### 6.9. UC-08-09 · Cấu hình trọng số và ngưỡng có duyệt

Trọng số sáu chiều và ngưỡng đạt, cảnh báo quyết định kết luận của mọi lần đo, nên có phiên bản và bốn mắt. Đổi cấu hình không hồi tố điểm quá khứ (BR-08-008).

::: dac-ta
**Mục tiêu.** Cấu hình trọng số mới (tổng 1,0) và ngưỡng đạt 80, cảnh báo 70 có hiệu lực sau khi Hùng duyệt.

**Tác nhân chính.** DS (Lan, soạn), DA (Hùng, duyệt).

**Tác nhân phụ.** PH-13 (việc cần duyệt).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-021.

**Truy vết.** REQ-08; FR-00-071; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Lan có `PERM-08-rule-admin`; Hùng có `PERM-08-approve`.

**Kích hoạt.** Lan mở UI-08-10 và bấm "Tạo cấu hình mới".

**Đảm bảo tối thiểu.** Cấu hình đang hiệu lực không đổi cho tới khi bản mới được duyệt.

**Đảm bảo thành công.** Cấu hình mới `ACTIVE` với `weightConfigId`; lần đo sau ghi mã này; điểm cũ giữ nguyên.

**Luồng chính.**
1. Lan kéo sáu thanh trượt: đầy đủ 0,20, chính xác 0,20, nhất quán 0,15, kịp thời 0,10, duy nhất 0,15, hợp lệ 0,20; đặt ngưỡng 80 và 70 (API-08-048).
2. Hệ thống kiểm tổng bằng 1 (dung sai 0,001), ngưỡng hợp lệ; Lan bấm "Xem trước" (API-08-132) để thấy điểm giả định tính lại từ ảnh chụp đầy đủ gần nhất của từng đối tượng, không ghi dữ liệu.
3. Lan bấm "Gửi duyệt" (API-08-050).
4. Hùng xem xem trước, bấm "Duyệt" (API-08-051); hệ thống kiểm Hùng khác Lan.
5. Hệ thống đặt cấu hình `ACTIVE`; so kỳ khác cấu hình sẽ gắn cờ `WEIGHTS_CHANGED`.

**Luồng thay thế.**
- **1a. Sửa nháp.** Lan sửa cấu hình nháp (API-08-049) trước khi gửi.
- **4a. Từ chối.** Hùng từ chối kèm lý do (API-08-052); cấu hình về nháp.

**Luồng ngoại lệ.**
- **E1. Tổng khác 1 (bước 2).** ERR-08-023 (422): "Tổng trọng số sáu chiều phải bằng 1 (hiện là {tổng})."
- **E2. Ngưỡng sai (bước 2).** ERR-08-024 (422): "Ngưỡng cảnh báo phải nhỏ hơn hoặc bằng ngưỡng đạt và trong khoảng 0 đến 100."
- **E2a. Chưa có ảnh chụp để xem trước (bước 2).** ERR-08-027 (422): "Đối tượng {mã} chưa có bộ quy tắc đang hiệu lực."
- **E3. Tự duyệt (bước 4).** ERR-08-005 (403): "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."
- **E4. Từ chối thiếu lý do (4a).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."

**Quy tắc áp dụng.** BR-08-002, BR-08-007, BR-08-008, BR-08-023.

**Màn hình, API.** UI-08-10; API-08-047…052, 132; kịch bản TS-08-09.
:::

```{.mermaid caption="Trình tự cấu hình trọng số và ngưỡng có duyệt"}
sequenceDiagram
  actor DS
  actor DA
  participant Q as dq-control
  DS->>Q: Tạo cấu hình trọng số, ngưỡng (API-08-048)
  Q->>Q: Kiểm tổng bằng 1, ngưỡng hợp lệ
  DS->>Q: Xem trước điểm giả định (API-08-132)
  Q-->>DS: Điểm hiện hành và điểm giả định
  DS->>Q: Gửi duyệt (API-08-050)
  DA->>Q: Duyệt (API-08-051)
  Q->>Q: Kiểm DA khác DS, đặt ACTIVE
```

Hình cho thấy xem trước tác động đến trước khi gửi duyệt, để người duyệt quyết định dựa trên hệ quả thật lên điểm gần nhất.

### 6.10. UC-08-10 · Lập lịch đo, đo theo yêu cầu, theo dõi và hủy

Mặc định mỗi đối tượng `ACTIVE` được đo ngày 1 hằng tháng lúc 02:00 (BR-08-001). DS, TO thêm lịch, đo ngay khi cần, theo dõi tiến độ và hủy khi nguồn đang quá tải.

::: dac-ta
**Mục tiêu.** `MDM-CITIZEN` có lịch đo đầy đủ hằng tháng; Chi đo theo yêu cầu một lần `SC-202611-0007` và theo dõi tới `SUCCEEDED`.

**Tác nhân chính.** DS (Lan), TO (Chi).

**Tác nhân phụ.** bộ lập lịch nội bộ (Quartz, ShedLock), `dq-worker`, PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-023, FR-08-024, FR-08-030.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-run`; đối tượng `ACTIVE` có bộ quy tắc `ACTIVE` và cấu hình trọng số hiệu lực.

**Kích hoạt.** Lan lập lịch ở UI-08-11; Chi bấm "Đo ngay" ở UI-08-04.

**Đảm bảo tối thiểu.** Mỗi đối tượng tối đa một lần `QUEUED` hoặc `RUNNING` (BR-08-020); lần hủy không có điểm.

**Đảm bảo thành công.** Lần đo `SUCCEEDED` hoặc `PARTIAL` có ảnh chụp điểm; lần `FAILED`, `CANCELLED` không có điểm.

**Luồng chính.**
1. Lan tạo lịch `FULL`, cron `0 0 2 1 * ?` (API-08-055); hệ thống kiểm cron không dày hơn `08.scan.min-interval-hours`.
2. Chi bấm "Đo ngay", chọn chế độ `FULL` (API-08-059); hệ thống kiểm hạn mức `08.scan.manual-per-hour`, tạo lần đo `QUEUED`.
3. Hệ thống chia tác vụ 200.000 bản ghi, xếp cho bộ thực thi (UC-08-11), lần đo sang `RUNNING`.
4. Chi theo dõi tiến độ theo tác vụ ở UI-08-12 (API-08-061, 067).
5. Xong, hệ thống đặt `SUCCEEDED`, phát EVT-08-02.

**Luồng thay thế.**
- **1a. Tạm dừng lịch.** API-08-057, 058 (dừng, tiếp tục); sửa lịch API-08-056.
- **2a. Chế độ `SAMPLE`.** Chi chọn cỡ mẫu 100 đến 1.000.000; không dùng cho báo cáo năm (BR-08-010).
- **4a. Hủy.** Chi bấm "Hủy" (API-08-062); lần đo `CANCELLED`.
- **5a. Chạy lại.** Lần `FAILED` được chạy lại thành lần mới `rerunOf` (API-08-063).

**Luồng ngoại lệ.**
- **E1. Chưa có bộ quy tắc (bước 2).** ERR-08-027 (422): "Đối tượng {mã} chưa có bộ quy tắc đang hiệu lực."
- **E2. Đang có lần chạy (bước 2).** ERR-08-028 (409): "Đối tượng đang có lần chạy {mã}. Đợi lần này xong hoặc hủy."
- **E3. Cron sai hoặc quá dày (bước 1).** ERR-08-029 (422): "Lịch {biểu thức} không hợp lệ hoặc dày hơn mức cho phép ({n} giờ một lần)."
- **E4. Lịch trùng (bước 1).** ERR-08-049 (409): "Đối tượng {mã} đã có lịch {chế độ} {biểu thức}."
- **E5. Cỡ mẫu sai (2a).** ERR-08-030 (422): "Kích thước mẫu phải từ 100 đến 1.000.000 bản ghi; lần đo cho báo cáo năm phải đo toàn bộ."
- **E6. Vượt hạn mức (bước 2).** ERR-08-052 (429): "Đã đạt {n} lần đo theo yêu cầu trong một giờ. Thử lại sau {phút} phút."
- **E7. Chờ quá hạn.** ERR-08-119: "Lần đo {mã} chờ quá {n} giờ và đã bị hủy." (UI-08-11)

**Quy tắc áp dụng.** BR-08-001, BR-08-010, BR-08-019, BR-08-020.

**Màn hình, API.** UI-08-11, 04, 12; API-08-054…063, 067; kịch bản TS-08-10.
:::

```{.mermaid caption="Trình tự đo theo yêu cầu và theo dõi tiến độ"}
sequenceDiagram
  actor TO
  participant Q as dq-control
  participant S as Bộ lập lịch nội bộ
  participant W as dq-worker
  TO->>Q: Đo ngay FULL (API-08-059)
  Q->>Q: Kiểm hạn mức, tạo lần đo QUEUED
  Q->>W: Chia tác vụ, giao bộ thực thi
  S->>Q: Kích hoạt theo lịch hằng tháng
  W-->>Q: Tiến độ từng tác vụ
  TO->>Q: Xem tiến độ (API-08-061)
  W-->>Q: Xong, SUCCEEDED
```

Hình cho thấy lịch nội bộ và yêu cầu thủ công cùng đi vào một hàng đợi lần đo, nên quy tắc "một lần chạy mỗi đối tượng" áp dụng chung.

### 6.11. UC-08-11 · Đo theo lô, đối chiếu danh mục và ghi bản ghi lỗi

Đây là use case máy: bộ thực thi nhận từng tác vụ của lần đo, dịch quy tắc tập hợp thành SQL đẩy xuống nguồn, chạy quy tắc mức bản ghi bằng CEL, đối chiếu danh mục PH-07 cho chiều hợp lệ và ghi bản ghi lỗi.

::: dac-ta
**Mục tiêu.** Mỗi quy tắc của bộ `ACTIVE` có kết quả `PASSED` hoặc `FAILED` kèm số đạt, vi phạm; mỗi vi phạm thành bản ghi lỗi có dấu vân tay, che theo phân loại.

**Tác nhân chính.** Hệ thống (`dq-worker`).

**Tác nhân phụ.** Nguồn đo qua khung nhìn hợp đồng PH-06 hoặc kết nối PH-05, PH-07 (ảnh chụp danh mục), PH-09.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-026, FR-08-027, FR-08-036.

**Truy vết.** REQ-08, REQ-07; BP-10; LGC-DMDC-006…008, LGC-NGSP-003, 005 (gián tiếp).

**Tiền điều kiện.** Lần đo `QUEUED` đã được xếp; bộ quy tắc và cấu hình trọng số hiệu lực; tài khoản `dq_reader` chỉ `SELECT`.

**Kích hoạt.** Có bộ thực thi rảnh trong cửa sổ giờ `08.scan.window`.

**Đảm bảo tối thiểu.** Không ghi vào nguồn; truy vấn tối đa 15 phút, 2 truy vấn đồng thời mỗi kết nối (BR-08-025); không lưu giá trị gốc trường Nhạy cảm.

**Đảm bảo thành công.** Kết quả quy tắc, bản ghi lỗi (phân vùng theo tháng) và số đếm đúng; lỗi cũ mà kỳ này không còn thấy chuyển `RESOLVED`.

**Luồng chính.**
1. Hệ thống đặt lần đo `RUNNING`, lấy một tác vụ (200.000 bản ghi).
2. Hệ thống dịch quy tắc tập hợp (`NOT_NULL`, `UNIQUE_IN_ASSET`) thành SQL đẩy xuống và chạy; quy tắc mức bản ghi chạy bằng CEL.
3. Với quy tắc `IN_RDM`, hệ thống đối chiếu ảnh chụp danh mục `DVHC` của PH-07, không sao bảng mã (BR-08-003).
4. Với mỗi vi phạm, hệ thống tính `fingerprint = HMAC-SHA256(khóa tenant; tenantId, assetCode, ruleCode, recordKey)` (BR-08-013); lỗi mới ghi `OPEN`, lỗi đã có tăng số lần thấy.
5. Hệ thống che giá trị theo phân loại: `SENSITIVE` lưu HMAC, `RESTRICTED` che một phần (BR-08-012).
6. Hệ thống đặt `RESOLVED` cho lỗi có phủ quy tắc mà kỳ này không còn thấy (BR-08-034), lưu kết quả quy tắc, chuyển sang UC-08-12.

**Luồng thay thế.**
- **2a. Nhiều tác vụ.** Các tác vụ chạy song song trong hạn mức kết nối; tác vụ lỗi được thử lại.
- **3a. Danh mục lớn.** Hơn `08.rdm.snapshot-max-items` thì tra lô theo FR-07-027.
- **4a. Lỗi cấu trúc.** Bản ghi thiếu khóa ghi là lỗi `CRITICAL` cấu trúc.

**Luồng ngoại lệ.**
- **E1. Nguồn không đọc được (bước 2).** ERR-08-105 (503): "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau." (lần đo `FAILED`; xem UC-08-13)
- **E2. Quy tắc lỗi khi chạy (bước 2).** ERR-08-107: "Quy tắc {mã} lỗi khi chạy: {chi tiết}." (kết quả `ERROR`)
- **E3. Bản ghi thiếu khóa (4a).** ERR-08-109: "{n} bản ghi thiếu khóa và được ghi là lỗi cấu trúc."
- **E4. Vượt trần lỗi lưu (bước 4).** ERR-08-110: "Quy tắc {mã} có hơn {n} bản ghi lỗi. Chỉ lưu {n} bản ghi đầu, số đếm vẫn đủ."
- **E5. Lần đo quá giờ (bước 2).** ERR-08-106: "Lần đo {mã} vượt {n} giờ và đã dừng."
- **E6. Trường không còn ở nguồn (bước 2).** ERR-08-116: "Trường {đường dẫn} không còn ở nguồn. Quy tắc {mã} không chạy được."

**Quy tắc áp dụng.** BR-08-003, BR-08-004, BR-08-012, BR-08-013, BR-08-017, BR-08-025, BR-08-034.

**Màn hình, API.** UI-08-12 (xem kết quả); API-08-061, 064, 067; kịch bản TS-08-11.
:::

```{.mermaid caption="Trình tự thực thi một tác vụ đo theo lô"}
sequenceDiagram
  participant W as dq-worker
  participant N as Nguồn chỉ đọc
  participant R as PH-07
  participant F as Kho kết quả
  W->>N: SQL pushdown cho quy tắc tập hợp
  N-->>W: Số đạt, khóa vi phạm
  W->>R: Lấy ảnh chụp danh mục DVHC
  R-->>W: Danh sách mã
  W->>W: CEL mức bản ghi, tính fingerprint, che giá trị
  W->>F: Ghi kết quả quy tắc và bản ghi lỗi
```

Hình cho thấy chỉ số đếm và khóa vi phạm đi về từ nguồn, còn che giá trị và tính dấu vân tay làm trong bộ thực thi trước khi ghi.

### 6.12. UC-08-12 · Tính điểm có trọng số, so kỳ trước và xu hướng

Sau khi mọi tác vụ xong, hệ thống tổng hợp điểm từng chiều theo `POOLED`, điểm tổng có trọng số, so với ảnh chụp liền trước để ra xu hướng và kết luận.

::: dac-ta
**Mục tiêu.** Lần đo có ảnh chụp điểm bất biến: điểm sáu chiều, điểm tổng, kết luận `PASS`, `WARN` hoặc `FAIL`, xu hướng, cờ nếu có.

**Tác nhân chính.** Hệ thống (`dq-worker`).

**Tác nhân phụ.** Kafka, PH-13, PH-16.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-028, FR-08-029.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Mọi tác vụ của lần đo kết thúc; có cấu hình trọng số hiệu lực.

**Kích hoạt.** Tác vụ cuối của lần đo xong.

**Đảm bảo tối thiểu.** Không bịa điểm: lần `FAILED` không có ảnh chụp; ảnh chụp đã ghi không sửa (BR-08-009).

**Đảm bảo thành công.** Ảnh chụp có `weightConfigId`; sự kiện EVT-08-02 (kèm `flags`, `score`, `verdict`) đã phát.

**Luồng chính.**
1. Hệ thống tính điểm chiều: `100 × Σ pass / Σ (pass + fail)`, loại `SKIPPED`, `ERROR` và lỗi `WAIVED` khỏi mẫu số (BR-08-022).
2. Hệ thống tính điểm tổng `Σ score_d × w_d / Σ w_d` trên chiều có điểm, làm tròn hai chữ số, ví dụ 87,35.
3. Hệ thống đối chiếu ngưỡng 80 và 70 để đặt kết luận `PASS` (BR-08-023).
4. Hệ thống so ảnh chụp kỳ trước (API-08-066): Δ = +2,10 nên `IMPROVED` (dải ±1,0, BR-08-024).
5. Hệ thống lưu ảnh chụp, phát EVT-08-02; DS xem điểm, so kỳ ở UI-08-12, UI-08-04 (API-08-065).

**Luồng thay thế.**
- **2a. Thiếu chiều.** Chiều không có quy tắc hoặc mọi quy tắc `SKIPPED` thì điểm rỗng, ảnh chụp gắn `INCOMPLETE_DIMENSIONS`.
- **4a. Giảm mạnh.** Δ ≤ −5,0 thì `DEGRADED` và phát EVT-08-04; kết luận chuyển `FAIL` thì phát EVT-08-05.
- **4b. Khác cấu hình.** Hai kỳ khác `weightConfigId` thì gắn `WEIGHTS_CHANGED`; chưa có kỳ trước thì `BASELINE`.

**Luồng ngoại lệ.**
- **E1. Chưa có trọng số hiệu lực (bước 1).** ERR-08-027 (422): "Đối tượng {mã} chưa có bộ quy tắc đang hiệu lực."
- **E2. Đẩy sự kiện chậm quá 24 giờ (bước 5).** ERR-08-113: "Chưa đẩy được {n} bản tin KPI chất lượng dữ liệu sang PH-16." (UI-08-19, PH-13)

**Quy tắc áp dụng.** BR-08-002, BR-08-008, BR-08-009, BR-08-021, BR-08-022, BR-08-023, BR-08-024.

**Màn hình, API.** UI-08-12, 04; API-08-065, 066; kịch bản TS-08-12.
:::

```{.mermaid caption="Trình tự tính điểm và so kỳ trước"}
sequenceDiagram
  participant W as dq-worker
  participant D as Kho điểm
  participant K as Kafka
  W->>D: Đọc kết quả quy tắc của lần đo
  W->>W: Điểm chiều POOLED, điểm tổng, kết luận
  W->>D: Đọc ảnh chụp kỳ trước
  W->>W: Δ điểm, xu hướng, cờ
  W->>D: Lưu ảnh chụp bất biến
  W->>K: EVT-08-02 scan.completed
```

Hình cho thấy ảnh chụp chỉ ghi một lần sau khi đã có đủ điểm, kỳ trước và cờ, nên không có ảnh chụp nửa chừng.

### 6.13. UC-08-13 · Xử lý phụ thuộc không khả dụng khi đo

Khi PH-07 hay nguồn lỗi, hệ thống không bịa điểm: chiều phụ thuộc bị bỏ qua và ảnh chụp mang cờ, hoặc lần đo thất bại rõ ràng để vận hành xử lý.

::: dac-ta
**Mục tiêu.** Lần đo kết thúc `PARTIAL` (có cờ) hoặc `FAILED` đúng nguyên nhân; DS, TO biết điểm này chưa đủ chiều và không dùng cho báo cáo năm.

**Tác nhân chính.** Hệ thống; TO (Chi, xử lý).

**Tác nhân phụ.** PH-07, nguồn đo, PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-031.

**Truy vết.** REQ-08; BP-10, BP-07; hệ cũ: không có.

**Tiền điều kiện.** Lần đo `RUNNING`.

**Kích hoạt.** Truy vấn nguồn, gọi PH-07 hoặc một quy tắc trả lỗi sau lần thử lại.

**Đảm bảo tối thiểu.** Không ghi điểm sai; mọi quy tắc không chạy được có trạng thái `SKIPPED` hoặc `ERROR` kèm lý do.

**Đảm bảo thành công.** `scan_status` phản ánh đúng; Chi chạy lại được (UC-08-10) và báo cáo năm bị chặn khi còn cờ `INCOMPLETE_DIMENSIONS`.

**Luồng chính.**
1. Hệ thống gọi PH-07 đối chiếu `DVHC` trong khoảng 02:10 đến 02:40 và nhận lỗi liên tục sau các lần thử.
2. Hệ thống đặt quy tắc `IN_RDM` là `SKIPPED` với lý do "PH-07 gián đoạn".
3. Hệ thống tính điểm các chiều còn lại; chiều `VALIDITY` không có điểm, ảnh chụp gắn `INCOMPLETE_DIMENSIONS`.
4. Hệ thống đặt lần đo `PARTIAL`, phát EVT-08-02 kèm cờ và gửi thông báo cho DS.
5. Chi mở UI-08-12, thấy chiều Hợp lệ tô xám kèm lý do, bấm "Chạy lại" (API-08-063) khi PH-07 phục hồi.

**Luồng thay thế.**
- **1a. Nguồn lỗi hẳn.** Lần đo `FAILED`, không có điểm, phát EVT-08-03; chạy lại tạo lần mới `rerunOf`.
- **1b. Tỷ lệ phủ thấp.** Tác vụ lỗi làm tỷ lệ bản ghi đã đo dưới `08.scan.min-coverage` (95%) thì không có điểm.

**Luồng ngoại lệ.**
- **E1. PH-07 không khả dụng (bước 2).** ERR-08-108: "Không đối chiếu được danh mục {mã}. Chiều Hợp lệ bị bỏ qua ở lần đo này." (UI-08-12, thẻ điểm)
- **E2. Nguồn không khả dụng (1a).** ERR-08-105 (503): "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau."
- **E3. Quá thời gian tối đa (bước 1).** ERR-08-106: "Lần đo {mã} vượt {n} giờ và đã dừng."

**Quy tắc áp dụng.** BR-08-001, BR-08-009, BR-08-010, BR-08-022.

**Màn hình, API.** UI-08-12; API-08-061, 063; kịch bản TS-08-13.
:::

```{.mermaid caption="Trình tự khi PH-07 không khả dụng trong lần đo"}
sequenceDiagram
  participant W as dq-worker
  participant R as PH-07
  participant Q as dq-control
  actor TO
  W->>R: Đối chiếu danh mục DVHC
  R-->>W: Lỗi, thử lại vẫn lỗi
  W->>W: Quy tắc IN_RDM SKIPPED
  W->>Q: Lần đo PARTIAL, cờ INCOMPLETE_DIMENSIONS
  Q-->>TO: Thông báo qua PH-13
  TO->>Q: Chạy lại khi PH-07 phục hồi (API-08-063)
```

Hình cho thấy lỗi của một phụ thuộc chỉ làm mất chiều liên quan chứ không làm hỏng cả lần đo, và vận hành là bên quyết định chạy lại.

### 6.14. UC-08-14 · Đo tăng dần theo sự kiện PH-06, PH-07

Khi bản ghi vàng đổi hoặc danh mục được phát hành, hệ thống đo lại đúng phần bị ảnh hưởng thay vì chờ đến kỳ sau. Ảnh chụp tăng dần không thay ảnh chụp đầy đủ.

::: dac-ta
**Mục tiêu.** Lỗi liên quan thay đổi vừa xảy ra được cập nhật trong vòng cửa sổ gom 15 phút mà không đo lại cả đối tượng.

**Tác nhân chính.** Hệ thống (`dq-incremental`).

**Tác nhân phụ.** PH-06 (EVT-06-01…04, 10), PH-07 (EVT-07-03, 05, 10), Kafka.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-025.

**Truy vết.** REQ-08, REQ-06, REQ-07; BP-03, BP-10; LGC-DMDC-006…008 (gián tiếp).

**Tiền điều kiện.** Đối tượng `ACTIVE` có bộ quy tắc hiệu lực, đã có lần đo `FULL` gần nhất và đã bật đo tăng dần (TO bật bằng API-08-130, tắt bằng API-08-131 kèm lý do).

**Kích hoạt.** Nhận sự kiện từ PH-06 hoặc PH-07.

**Đảm bảo tối thiểu.** Sự kiện sai định dạng bị bỏ qua và ghi nhật ký, không chặn hàng đợi; xử lý lặp một sự kiện không tạo lỗi trùng (inbox).

**Đảm bảo thành công.** Lần đo `INCREMENTAL` (trigger `EVENT`) cập nhật bản ghi lỗi của khóa đổi; điểm đầy đủ chờ lần `FULL` kế tiếp.

**Luồng chính.**
1. PH-06 phát EVT-06-02 `t68.mdm.golden.updated.v1`; hệ thống ghi vào inbox và gom `goldenId` trong cửa sổ `08.incremental.batch-window-minutes`.
2. Hết cửa sổ, hệ thống tạo lần đo `INCREMENTAL` cho các khóa đã gom.
3. Hệ thống chạy các quy tắc áp dụng trên khóa đó (như UC-08-11), cập nhật lỗi `OPEN` hoặc `RESOLVED`.
4. PH-07 phát EVT-07-05 phát hành danh mục `DVHC` thì hệ thống tạo lần đo cho đối tượng có quy tắc `IN_RDM` trỏ danh mục đó.
5. Hệ thống phát EVT-08-06 gộp theo lần đo nếu có lỗi mới.

**Luồng thay thế.**
- **1a. Hợp nhất, tách.** EVT-06-03 thì lỗi của bản bị hợp nhất chuyển `RESOLVED` lý do `RECORD_REMOVED`; EVT-06-04 gom cả hai `goldenId`.
- **1b. Mô hình đổi.** EVT-06-10 thì so lại lược đồ đối tượng `MDM_DOMAIN`.
- **4a. Danh mục ngừng.** EVT-07-03 thì cảnh báo quy tắc `IN_RDM` trỏ danh mục ngừng (UC-08-23).
- **2a. Vượt 100.000 khóa đổi.** Hệ thống bỏ lần tăng dần, chờ lần `FULL` (BR-08-033).

**Luồng ngoại lệ.**
- **E1. Sự kiện sai định dạng (bước 1).** ERR-08-118 (422): "Lô dữ liệu từ {nguồn} sai định dạng: {chi tiết}." (PH-13, vận hành)
- **E2. Lược đồ nguồn đổi (bước 3).** ERR-08-116: "Trường {đường dẫn} không còn ở nguồn. Quy tắc {mã} không chạy được."

**Quy tắc áp dụng.** BR-08-020, BR-08-033, BR-08-034.

**Màn hình, API.** UI-08-11 (xem kết quả); API-08-060, 061, 130, 131; kịch bản TS-08-14.
:::

```{.mermaid caption="Trình tự đo tăng dần theo sự kiện PH-06"}
sequenceDiagram
  participant M as PH-06
  participant K as Kafka
  participant I as dq-incremental
  participant W as dq-worker
  M->>K: EVT-06-02 golden.updated
  K->>I: Nhận sự kiện, ghi inbox
  I->>I: Gom khóa trong cửa sổ 15 phút
  I->>W: Lần đo INCREMENTAL cho khóa đổi
  W->>W: Chạy quy tắc, cập nhật lỗi
  W->>K: EVT-08-06 finding.opened
```

Hình cho thấy PH-08 chỉ phản ứng với sự kiện đã gom theo cửa sổ, không gọi ngược PH-06, nên không tăng tải cho dữ liệu chủ.

### 6.15. UC-08-15 · Kiểm tra trực tuyến bản ghi từ luồng PH-04

Luồng tích hợp thêm bước Kamelet `dh-dq-check` để kiểm bản tin trước khi chuyển tiếp. Ngân sách thời gian p95 ≤ 50 ms, mặc định `08.inline.timeout-ms` 40.

::: dac-ta
**Mục tiêu.** Luồng `LLTP-GUI` nhận kết luận `PASS`, `WARN` hoặc `FAIL` kèm danh sách vi phạm cho từng bản tin, trong ngân sách thời gian.

**Tác nhân chính.** PH-04 `dh-runtime` (scope `dq.check`).

**Tác nhân phụ.** `dq-inline` (bộ đệm quy tắc), PH-07 (đối chiếu), kỹ sư tích hợp.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-032, FR-08-033.

**Truy vết.** REQ-08, REQ-04; BP-02; hệ cũ: không có.

**Tiền điều kiện.** Đối tượng `FLOW-LLTP` (loại `FLOW_MESSAGE`) `ACTIVE` có quy tắc `exec_mode` `INLINE` hoặc `BOTH` và cấu hình trực tuyến (chế độ, `on_dependency_failure`).

**Kích hoạt.** Luồng PH-04 gọi `POST /api/dq/v1/checks:evaluate` (API-08-068).

**Đảm bảo tối thiểu.** Thân bản tin không lưu và không vào nhật ký (mặc định `08.inline.persist-findings` tắt); lỗi phụ thuộc không làm treo luồng.

**Đảm bảo thành công.** Có kết luận và vi phạm; phút có `FAIL` được gộp vào EVT-08-13.

**Luồng chính.**
1. Luồng PH-04 gửi bản ghi (≤ 64 KB) kèm mã đối tượng `FLOW-LLTP`.
2. Hệ thống kiểm lược đồ và bật trực tuyến, nạp quy tắc từ bộ đệm.
3. Hệ thống chạy quy tắc mức bản ghi (toán tử trực tuyến, CEL dưới giới hạn chi phí), bỏ quy tắc chỉ chạy lô (BR-08-017).
4. Ở chế độ `STRICT`, lỗi `CRITICAL` hoặc `MAJOR` cho `FAIL`, chỉ `MINOR` cho `WARN`; ở `ADVISORY` không bao giờ `FAIL`: có vi phạm ở mức nào cũng `WARN` kèm danh sách, không vi phạm thì `PASS` (BR-08-016).
5. Hệ thống trả `200` kèm `verdict`, vi phạm; Kamelet đặt tiêu đề `dh-dq-verdict`, `dh-dq-violations`, luồng định tuyến theo kết luận (đưa vào DLQ lý do `DQ_FAIL` khi `FAIL`).

**Luồng thay thế.**
- **1a. Gọi lô.** Luồng gửi tối đa 100 bản ghi một lần (API-08-069), nhận kết luận từng bản ghi.
- **3a. Phụ thuộc lỗi.** `FAIL_OPEN` trả `PASS` cờ `degraded`; `FAIL_CLOSED` trả lỗi (BR-08-018).
- **2a. Chưa có quy tắc.** Hệ thống trả `PASS` không vi phạm.

**Luồng ngoại lệ.**
- **E1. Sai lược đồ, quá 64 KB hoặc lô quá 100 bản ghi (bước 2).** ERR-08-101 (422): "Bản ghi không đúng lược đồ của đối tượng {mã}: {chi tiết}."
- **E2. Chưa bật trực tuyến (bước 2).** ERR-08-102 (404): "Đối tượng {mã} chưa bật kiểm tra trực tuyến."
- **E3. Vượt ngân sách khi `FAIL_CLOSED` (bước 3).** ERR-08-103 (504): "Kiểm tra chất lượng vượt {n} ms."
- **E4. Phụ thuộc lỗi khi `FAIL_CLOSED` (3a).** ERR-08-104 (503): "Dịch vụ đối chiếu danh mục tạm thời không khả dụng."

**Quy tắc áp dụng.** BR-08-016, BR-08-017, BR-08-018.

**Màn hình, API.** UI-08-20; API-08-068, 069, 071, 072; kịch bản TS-08-15.
:::

```{.mermaid caption="Trình tự kiểm tra trực tuyến trong luồng PH-04"}
sequenceDiagram
  participant F as Luồng PH-04
  participant I as dq-inline
  participant R as PH-07
  F->>I: checks:evaluate bản tin (API-08-068)
  I->>I: Nạp quy tắc từ bộ đệm
  I->>R: Đối chiếu danh mục nếu có IN_RDM
  R-->>I: Kết quả
  I-->>F: verdict, violations
  F->>F: Định tuyến theo verdict
```

Hình cho thấy toàn bộ việc kiểm diễn ra trong một lần gọi đồng bộ, và quyết định định tuyến vẫn thuộc về luồng PH-04.

### 6.16. UC-08-16 · Cổng chất lượng cho PH-06 và giám sát kiểm tra trực tuyến

PH-06 có thể gọi cùng API để chặn bản ghi ứng viên chất lượng thấp trước khi đối sánh. DS và TO theo dõi tình hình gọi theo phút để chỉnh quy tắc và chế độ.

::: dac-ta
**Mục tiêu.** PH-06 nhận kết luận cổng cho từng bản ghi ứng viên; Lan, Chi thấy lưu lượng, tỷ lệ `FAIL`, top quy tắc vi phạm, độ trễ p95 theo bên gọi.

**Tác nhân chính.** PH-06 (cổng); DS (Lan), TO (Chi) giám sát.

**Tác nhân phụ.** `dq-inline`, PH-13, PH-04 (bảng luồng).

**Mức ưu tiên.** C (FR-08-034 là S) · Đợt 3.

**FR hiện thực.** FR-08-034, FR-08-035.

**Truy vết.** REQ-08, REQ-06, REQ-13; BP-02, BP-07; LGC-BUS-027 (gián tiếp).

**Tiền điều kiện.** Đối tượng `MDM-CITIZEN` bật cổng trực tuyến (API-08-071); PH-06 có scope `dq.check`; Lan, Chi có `PERM-08-read`.

**Kích hoạt.** PH-06 gọi API-08-068 cho ứng viên; Lan mở UI-08-20.

**Đảm bảo tối thiểu.** Cổng lỗi không làm mất ứng viên: `FAIL_OPEN` cho qua kèm cờ `degraded`.

**Đảm bảo thành công.** Ứng viên bị `FAIL` ở `STRICT` bị từ chối với lý do `DQ_GATE` ở PH-06; thống kê phút lưu 90 ngày.

**Luồng chính.**
1. PH-06 gọi `checks:evaluate` kèm ứng viên `CITIZEN` (API-08-068).
2. Hệ thống đánh giá như UC-08-15 và trả `FAIL` vì `soDinhDanh` thiếu.
3. PH-06 từ chối ứng viên với lý do `DQ_GATE`; hệ thống cộng vào thống kê phút `dq_inline_stat`.
4. Lan mở UI-08-20, xem biểu đồ theo phút, top quy tắc, bên gọi (API-08-070).
5. Chi chỉnh chế độ `ADVISORY` sang `STRICT` ở cấu hình trực tuyến (API-08-071), có hiệu lực ngay.

**Luồng thay thế.**
- **2a. Phút có `FAIL`.** Hệ thống gộp và phát EVT-08-13 cho PH-13 và bảng luồng PH-04.
- **5a. Xem cấu hình hiện tại.** API-08-072.

**Luồng ngoại lệ.**
- **E1. Chưa bật trực tuyến (bước 1).** ERR-08-102 (404): "Đối tượng {mã} chưa bật kiểm tra trực tuyến."
- **E2. Phụ thuộc lỗi khi `FAIL_CLOSED` (bước 2).** ERR-08-104 (503): "Dịch vụ đối chiếu danh mục tạm thời không khả dụng."
- **E3. Ngoài phạm vi (bước 5).** ERR-08-032 (403): "Đối tượng {mã} không thuộc tổ chức của anh/chị."
- **E4. Tham số thống kê sai (bước 4).** ERR-08-045 (422): "Tham số {tên} không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-08-016, BR-08-018, BR-08-028.

**Màn hình, API.** UI-08-20; API-08-068, 070…072; kịch bản TS-08-16.
:::

```{.mermaid caption="Trình tự cổng chất lượng PH-06 và thống kê theo phút"}
sequenceDiagram
  participant M as PH-06
  participant I as dq-inline
  participant S as Thống kê phút
  actor DS
  M->>I: checks:evaluate ứng viên CITIZEN
  I-->>M: FAIL, soDinhDanh thiếu
  M->>M: Từ chối ứng viên, lý do DQ_GATE
  I->>S: Cộng dq_inline_stat
  DS->>S: Xem biểu đồ theo phút (API-08-070)
```

Hình cho thấy quyết định từ chối thuộc PH-06; PH-08 chỉ trả kết luận và ghi thống kê để DS chỉnh quy tắc.

### 6.17. UC-08-17 · Tra cứu, xem chi tiết và xuất bản ghi lỗi

Bản ghi lỗi chỉ chứa khóa bản ghi và giá trị đã che. DS, DO tra cứu theo quy tắc, mức, trạng thái; DO chỉ thấy lỗi của tổ chức mình (BR-08-026). Xuất lỗi có trường Nhạy cảm cần DO chấp thuận.

::: dac-ta
**Mục tiêu.** Lan tìm và xem lỗi `R-NS-01` của `MDM-CITIZEN`, truy về nguồn gốc, và xuất danh sách cho chủ quản.

**Tác nhân chính.** DS (Lan); DO (Phúc); DA (Hùng).

**Tác nhân phụ.** SO (xem lỗi đã che), kho tệp xuất.

**Mức ưu tiên.** M (FR-08-039 là S) · Đợt 3.

**FR hiện thực.** FR-08-037, FR-08-038, FR-08-039.

**Truy vết.** REQ-08, REQ-09; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-finding-read`; xuất cần `PERM-08-export`.

**Kích hoạt.** Lan mở UI-08-13; chọn một dòng thì mở ngăn kéo UI-08-14.

**Đảm bảo tối thiểu.** Không có giá trị gốc trường `SENSITIVE` ở màn hình, tệp, nhật ký.

**Đảm bảo thành công.** Danh sách đúng phạm vi; tệp xuất chỉ có giá trị đã che, hạn tải 24 giờ.

**Luồng chính.**
1. Lan lọc lỗi theo đối tượng, quy tắc, mức `MAJOR`, trạng thái `OPEN` (API-08-073); có thể nhóm theo quy tắc (API-08-078).
2. Hệ thống trả trang kết quả đã che theo phân loại.
3. Lan mở lỗi `F-1042` (API-08-074): quy tắc, lịch sử các kỳ, số lần mở lại, nguồn gốc (lần đo, phiên bản quy tắc).
4. Lan bấm "Xuất" (API-08-075); lỗi không có trường Nhạy cảm thì hệ thống tạo tệp ngay.
5. Lan tải tệp (API-08-077) trong 24 giờ.

**Luồng thay thế.**
- **1a. Tìm theo khóa cá nhân.** Dùng `POST /findings:search` (API-08-129), giá trị khóa không vào đường dẫn hay nhật ký.
- **4a. Có trường Nhạy cảm.** Phúc (DO) chấp thuận (API-08-076), Hùng duyệt (bốn mắt, LP-08-01); khi đó tệp mới sẵn sàng.

**Luồng ngoại lệ.**
- **E1. Ngoài phạm vi tổ chức (bước 3).** ERR-08-032 (403): "Đối tượng {mã} không thuộc tổ chức của anh/chị."
- **E2. Tệp chưa chấp thuận hoặc hết hạn (bước 5).** ERR-08-041 (409, 410): "Tệp xuất {mã} chưa được chấp thuận hoặc đã hết hạn tải."
- **E3. Tự duyệt (4a).** ERR-08-005 (403): "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."
- **E4. Tạo tệp thất bại (bước 4).** ERR-08-112: "Không tạo được {báo cáo hoặc tệp} {mã}. Thử lại sau."

**Quy tắc áp dụng.** BR-08-007, BR-08-012, BR-08-026, BR-08-027.

**Màn hình, API.** UI-08-13, 14; API-08-073…078; kịch bản TS-08-17.
:::

```{.mermaid caption="Trình tự xuất bản ghi lỗi có trường Nhạy cảm"}
sequenceDiagram
  actor DS
  actor DO
  actor DA
  participant Q as dq-control
  DS->>Q: Xuất lỗi (API-08-075)
  Q-->>DO: Chờ chấp thuận vì có trường Nhạy cảm
  DO->>Q: Chấp thuận (API-08-076)
  DA->>Q: Duyệt bốn mắt
  Q->>Q: Tạo tệp giá trị đã che, hạn 24 giờ
  DS->>Q: Tải tệp (API-08-077)
```

Hình cho thấy tệp chỉ được tạo sau khi cả chủ quản và người duyệt đồng ý, và luôn chứa giá trị đã che.

### 6.18. UC-08-18 · Đề nghị và duyệt ngoại lệ chấp nhận

Có lỗi mà tổ chức chấp nhận tồn tại có thời hạn, ví dụ dữ liệu lịch sử chưa thể bổ sung. Ngoại lệ không bao giờ vô thời hạn, tối đa 180 ngày.

::: dac-ta
**Mục tiêu.** Nhóm lỗi `R-NS-01` của dữ liệu trước năm 2000 được `WAIVED` trong 90 ngày, không tính vào mẫu số điểm nhưng vẫn được đếm và nêu ở báo cáo.

**Tác nhân chính.** DS (Lan, đề nghị), DA (Hùng, duyệt).

**Tác nhân phụ.** PH-13.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-040.

**Truy vết.** REQ-08; FR-00-071; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Lan có `PERM-08-finding-read`, `PERM-08-rule-admin` hoặc quyền đề nghị; Hùng có `PERM-08-approve`.

**Kích hoạt.** Lan bấm "Đề nghị ngoại lệ" ở UI-08-14.

**Đảm bảo tối thiểu.** Ngoại lệ chưa duyệt không đổi trạng thái lỗi.

**Đảm bảo thành công.** Ngoại lệ `ACTIVE`; lỗi phủ chuyển `WAIVED`; phát EVT-08-10; hết hạn thì lỗi về `OPEN`.

**Luồng chính.**
1. Lan chọn phạm vi cụ thể (đối tượng, quy tắc, điều kiện lọc), hạn 90 ngày và lý do (API-08-079).
2. Hệ thống kiểm hạn ≤ 180 ngày, phạm vi không rỗng, tạo ngoại lệ `PENDING_APPROVAL`.
3. Hùng xem phạm vi và số lỗi bị phủ, bấm "Duyệt" (API-08-081); hệ thống kiểm Hùng khác Lan.
4. Hệ thống đặt `ACTIVE`, chuyển lỗi phủ sang `WAIVED`, phát EVT-08-10.
5. Khi `validUntil` qua, hệ thống đặt `EXPIRED`, lỗi về `OPEN`, tính điểm từ lần đo kế tiếp.

**Luồng thay thế.**
- **3a. Từ chối.** Hùng từ chối kèm lý do (API-08-082), ngoại lệ `REJECTED`.
- **5a. Thu hồi sớm.** Lan hoặc Hùng thu hồi (API-08-083), ngoại lệ `REVOKED`.

**Luồng ngoại lệ.**
- **E1. Quá hạn tối đa hoặc phạm vi rỗng (bước 2).** ERR-08-033 (422): "Ngoại lệ tối đa {n} ngày và phải có phạm vi lỗi cụ thể."
- **E2. Tự duyệt (bước 3).** ERR-08-005 (403): "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."
- **E3. Thiếu lý do (bước 1).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."

**Quy tắc áp dụng.** BR-08-007, BR-08-009, BR-08-021.

**Màn hình, API.** UI-08-14, 13; API-08-079…083; kịch bản TS-08-18.
:::

```{.mermaid caption="Trình tự đề nghị và duyệt ngoại lệ chấp nhận"}
sequenceDiagram
  actor DS
  actor DA
  participant Q as dq-control
  participant K as Kafka
  DS->>Q: Đề nghị ngoại lệ 90 ngày (API-08-079)
  Q-->>DA: Việc cần duyệt
  DA->>Q: Duyệt (API-08-081)
  Q->>Q: Ngoại lệ ACTIVE, lỗi phủ WAIVED
  Q->>K: EVT-08-10 waiver.approved
```

Hình cho thấy chỉ sau khi người thứ hai duyệt thì lỗi mới đổi trạng thái và rời mẫu số điểm.

### 6.19. UC-08-19 · Mở phiếu khắc phục, phân công và theo dõi SLA

Lỗi được gom thành nhóm (đối tượng, quy tắc) rồi thành một phiếu giao tổ chức chủ quản. SLA theo mức: `CRITICAL` 5, `MAJOR` 15, `MINOR` 30 ngày làm việc (giả định).

::: dac-ta
**Mục tiêu.** Nhóm lỗi `R-NS-01` thành phiếu `ISS-2026-0042` giao Sở Tư pháp, có hạn xử lý theo mức.

**Tác nhân chính.** DS (Lan); TA.

**Tác nhân phụ.** DO (Phúc, người nhận), PH-13 ("Việc của tôi").

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-041, FR-08-042.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-remediate`; nhóm lỗi `OPEN` chưa thuộc phiếu mở khác; miền có chủ quản.

**Kích hoạt.** Lan bấm "Mở phiếu" ở UI-08-13; hoặc hệ thống tự mở khi `FAIL` và lỗi `CRITICAL` mới vượt `08.issue.auto-open-critical` (100).

**Đảm bảo tối thiểu.** Mỗi lỗi chỉ thuộc một phiếu mở.

**Đảm bảo thành công.** Phiếu `ASSIGNED` cho tổ chức chủ quản; lỗi thành `IN_REMEDIATION`; phát EVT-08-07.

**Luồng chính.**
1. Lan chọn nhóm lỗi 1.240 bản ghi, bấm "Mở phiếu" (API-08-084).
2. Hệ thống kiểm lỗi chưa thuộc phiếu khác, tạo phiếu `OPEN`, tính hạn theo mức cao nhất.
3. Lan giao cho Sở Tư pháp (API-08-087); phiếu `ASSIGNED`.
4. Hệ thống đưa phiếu vào "Việc của tôi" của Phúc, phát EVT-08-07.
5. Lan theo dõi hộp việc ở UI-08-15, lọc quá hạn, sắp hạn (API-08-085, 086).

**Luồng thay thế.**
- **1a. Tự mở.** Hệ thống gộp theo đối tượng và quy tắc, giao ngay chủ quản.
- **3a. Đổi người nhận.** Lan giao lại cho tổ chức khác khi phiếu `OPEN` hoặc `ASSIGNED`.
- **5a. Quá hạn.** Quá hạn 5 ngày leo thang cấp 1, 10 ngày cấp 2 (UC-08-22).

**Luồng ngoại lệ.**
- **E1. Lỗi đã thuộc phiếu khác (bước 2).** ERR-08-034 (409): "Có {n} bản ghi lỗi đã thuộc phiếu {mã}. Bỏ chọn hoặc gắn vào phiếu đó."
- **E2. Miền thiếu chủ quản (bước 3).** ERR-08-008 (422): "Miền {mã} cần tổ chức chủ quản và cán bộ phụ trách hợp lệ trước khi dùng."
- **E3. Ngoài phạm vi (bước 5).** ERR-08-032 (403): "Đối tượng {mã} không thuộc tổ chức của anh/chị."

**Quy tắc áp dụng.** BR-08-015, BR-08-026, BR-08-035.

**Màn hình, API.** UI-08-13, 15; API-08-078, 084…087; kịch bản TS-08-19.
:::

```{.mermaid caption="Trình tự mở phiếu và giao cho chủ quản"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant K as Kafka
  actor DO
  DS->>Q: Mở phiếu từ nhóm lỗi (API-08-084)
  Q->>Q: Kiểm lỗi, tính hạn theo mức
  DS->>Q: Giao Sở Tư pháp (API-08-087)
  Q->>K: EVT-08-07 issue.created
  K-->>DO: Việc của tôi
```

Hình cho thấy phiếu được giao qua "Việc của tôi" của PH-13, nên DO nhận việc mà không cần vào PH-08 để tìm.

### 6.20. UC-08-20 · Nhận, xử lý và báo đã sửa phiếu khắc phục

DO sửa ở nguồn bằng công cụ của chính HTTT; PH-08 không sửa dữ liệu. DO cập nhật tiến độ, trao đổi trên phiếu rồi báo đã sửa kèm mô tả việc đã làm.

::: dac-ta
**Mục tiêu.** Phiếu `ISS-2026-0042` chuyển `IN_PROGRESS` rồi `FIXED`, kèm mô tả việc đã sửa, chờ đo kiểm chứng.

**Tác nhân chính.** DO (Phúc).

**Tác nhân phụ.** DS (Lan, trao đổi), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-043.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Phiếu `ASSIGNED` cho tổ chức của Phúc; Phúc có `PERM-08-remediate` (○).

**Kích hoạt.** Phúc mở phiếu từ "Việc của tôi" hoặc UI-08-15.

**Đảm bảo tối thiểu.** Mọi trao đổi và đổi trạng thái ghi vào dòng thời gian phiếu, không xóa.

**Đảm bảo thành công.** Phiếu `FIXED` kèm ghi chú ≥ 20 ký tự; hệ thống lên lịch đo kiểm chứng (UC-08-21).

**Luồng chính.**
1. Phúc mở phiếu (API-08-086), xem danh sách lỗi (đã che) và hạn.
2. Phúc bấm "Nhận việc" (API-08-088); phiếu `IN_PROGRESS`.
3. Phúc ghi tiến độ, hỏi Lan về quy tắc (API-08-089); Lan trả lời trên cùng phiếu (API-08-097).
4. Phúc sửa dữ liệu ở HTTT hộ tịch rồi bấm "Báo đã sửa" kèm mô tả (API-08-090).
5. Hệ thống đặt `FIXED`, phát EVT-08-08, báo Lan.

**Luồng thay thế.**
- **3a. Phiếu mở lại.** Kiểm chứng còn lỗi thì phiếu `REOPENED`, Phúc nhận lại về `IN_PROGRESS`.
- **4a. Sửa một phần.** Phúc ghi tiến độ nhiều lần trước khi báo đã sửa.

**Luồng ngoại lệ.**
- **E1. Thiếu mô tả (bước 4).** ERR-08-036 (422): "Mô tả việc đã sửa (tối thiểu 20 ký tự) trước khi báo đã sửa."
- **E2. Sai trạng thái (bước 2).** ERR-08-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E3. Phiếu của tổ chức khác (bước 1).** ERR-08-032 (403): "Đối tượng {mã} không thuộc tổ chức của anh/chị."

**Quy tắc áp dụng.** BR-08-014, BR-08-026.

**Màn hình, API.** UI-08-15, 16; API-08-085, 086, 088…090, 097; kịch bản TS-08-20.
:::

```{.mermaid caption="Trình tự DO xử lý phiếu và báo đã sửa"}
sequenceDiagram
  actor DO
  participant Q as dq-control
  participant H as HTTT hộ tịch
  actor DS
  DO->>Q: Nhận việc (API-08-088)
  DO->>Q: Ghi tiến độ, hỏi DS (API-08-089)
  Q-->>DS: Thông báo
  DO->>H: Sửa dữ liệu tại nguồn
  DO->>Q: Báo đã sửa kèm mô tả (API-08-090)
  Q->>Q: Phiếu FIXED, lên lịch kiểm chứng
```

Hình cho thấy việc sửa diễn ra ở HTTT của chủ quản, ngoài PH-08; PH-08 chỉ ghi nhận lời báo và chờ kiểm chứng.

### 6.21. UC-08-21 · Đo lại kiểm chứng và xác nhận phiếu

Chủ quản không tự xác nhận. Phiếu chỉ `VERIFIED` khi lần đo `VERIFY` không còn thấy dấu vân tay các lỗi của phiếu, hoặc DS xác nhận có lý do.

::: dac-ta
**Mục tiêu.** Phiếu `FIXED` được hệ thống đo lại phạm vi liên quan và đóng `VERIFIED`, hoặc mở lại `REOPENED` kèm các lỗi còn thấy.

**Tác nhân chính.** Hệ thống; DS (Lan, xác nhận thủ công).

**Tác nhân phụ.** PH-06 (nếu lỗi ở bản ghi vàng), nguồn đo, DO (Phúc).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-044.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Phiếu `FIXED`; đối tượng còn bộ quy tắc hiệu lực.

**Kích hoạt.** Phúc bấm "Đã sửa" (API-08-090) và phiếu sang `FIXED` (hệ thống đợi `08.verify.wait-mdm-minutes` nếu nguồn là PH-06, `08.verify.wait-source-minutes` nếu là `SOURCE_DATASET`); hoặc Lan bấm "Xác nhận" (API-08-091).

**Đảm bảo tối thiểu.** Lỗi kỹ thuật khi đo kiểm chứng giữ phiếu ở `FIXED`, không tự mở lại (BR-08-014).

**Đảm bảo thành công.** Phiếu `VERIFIED`, lỗi `RESOLVED`, phát EVT-08-09; hoặc `REOPENED` kèm danh sách lỗi còn lại.

**Luồng chính.**
1. Khi phiếu sang `FIXED`, hệ thống tự tạo lần đo trigger `VERIFY` (không qua API-08-059, API này chỉ nhận `MANUAL`, `ANNUAL`) cho đúng quy tắc và khóa của phiếu.
2. Hệ thống chạy như UC-08-11 trên phạm vi đó.
3. Lần đo sạch: các lỗi `RESOLVED`, phiếu `VERIFIED`, phát EVT-08-09.
4. Báo Phúc và Lan; Lan xem kết quả ở UI-08-16.

**Luồng thay thế.**
- **3a. Còn lỗi.** Phiếu `REOPENED`, lỗi còn thấy hiện cho Phúc, về `IN_PROGRESS` khi Phúc nhận lại.
- **1a. Xác nhận thủ công.** Lan xác nhận (API-08-091, `mode = MANUAL`) kèm lý do ≥ 50 ký tự khi không đo lại được (ví dụ nguồn đã ngừng); Lan cũng có thể yêu cầu đo lại (`mode = SCAN`).
- **2a. `SAMPLE`.** Lần đo mẫu chỉ giải quyết lỗi nằm trong mẫu (BR-08-034).

**Luồng ngoại lệ.**
- **E1. DO tự xác nhận (bước 3).** ERR-08-035 (403): "Chủ quản không tự xác nhận phiếu. Hệ thống sẽ đo lại để kiểm chứng."
- **E2. Đo kiểm chứng lỗi kỹ thuật (bước 2).** ERR-08-115: "Đo kiểm chứng phiếu {mã} lỗi kỹ thuật. Hệ thống sẽ thử lại."
- **E3. Thiếu lý do xác nhận (1a).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."

**Quy tắc áp dụng.** BR-08-014, BR-08-034.

**Màn hình, API.** UI-08-16; API-08-086, 090, 091; kịch bản TS-08-21.
:::

```{.mermaid caption="Trình tự đo lại kiểm chứng phiếu khắc phục"}
sequenceDiagram
  participant Q as dq-control
  participant W as dq-worker
  participant K as Kafka
  actor DO
  Q->>W: Lần đo VERIFY cho khóa của phiếu
  W->>W: Chạy quy tắc trên phạm vi phiếu
  W-->>Q: Không còn thấy fingerprint
  Q->>Q: Lỗi RESOLVED, phiếu VERIFIED
  Q->>K: EVT-08-09 issue.verified
  Q-->>DO: Thông báo đã kiểm chứng
```

Hình cho thấy kết luận "đã sửa" do lần đo của hệ thống đưa ra, không do lời báo của DO.

### 6.22. UC-08-22 · Từ chối, chuyển, leo thang phiếu và chuyển lỗi sang PH-06

DO từ chối phiếu không thuộc mình; DS chuyển đúng đơn vị, hủy hoặc leo thang phiếu quá hạn; lỗi của bản ghi vàng thì chuyển sang hàng đợi người quản lý của PH-06.

::: dac-ta
**Mục tiêu.** Phiếu về đúng người chịu trách nhiệm, phiếu quá hạn được leo thang, lỗi bản ghi vàng được xử lý bằng công cụ của PH-06.

**Tác nhân chính.** DO (Phúc, từ chối), DS (Lan, chuyển, leo thang, hủy).

**Tác nhân phụ.** PH-06 (hàng đợi steward), PH-13.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-045, FR-08-046.

**Truy vết.** REQ-08, REQ-06; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-remediate`; với chuyển PH-06, đối tượng là `MDM_DOMAIN`.

**Kích hoạt.** Phúc bấm "Từ chối"; hoặc hệ thống phát hiện phiếu quá hạn; hoặc Lan bấm "Chuyển PH-06".

**Đảm bảo tối thiểu.** Mọi chuyển, leo thang ghi vào dòng thời gian phiếu.

**Đảm bảo thành công.** Phiếu về `ASSIGNED` cho đơn vị đúng hoặc `CANCELLED`; mục hàng đợi PH-06 tạo với lý do `DQ_FINDING`.

**Luồng chính.**
1. Phúc từ chối phiếu vì lỗi thuộc Sở Giáo dục, kèm lý do (API-08-092); phiếu `REJECTED`.
2. Lan chuyển cho Sở Giáo dục (API-08-093); phiếu `ASSIGNED`.
3. Sau 5 ngày quá hạn, hệ thống leo thang cấp 1 báo lãnh đạo của chủ quản (API-08-094), cấp 2 sau 10 ngày, phát EVT-08-08.
4. Với lỗi bản ghi vàng, Lan bấm "Chuyển hàng đợi PH-06" (API-08-095); PH-06 tạo mục cho người quản lý dữ liệu.

**Luồng thay thế.**
- **2a. Hủy phiếu.** Lan hủy (API-08-096), phiếu `CANCELLED` kèm lý do.
- **3a. Lan leo thang tay.** Lan gọi API-08-094 trước hạn khi lỗi `CRITICAL`.

**Luồng ngoại lệ.**
- **E1. Thiếu lý do (bước 1).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."
- **E2. Lỗi không thuộc bản ghi vàng (bước 4).** ERR-08-051 (422): "Chỉ lỗi của bản ghi vàng mới chuyển được sang hàng đợi dữ liệu chủ."
- **E3. Sai trạng thái (bước 2).** ERR-08-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Gửi thông báo thất bại (bước 3).** ERR-08-114: "Cảnh báo hoặc thông báo {mã} chưa gửi được tới kênh thông báo."

**Quy tắc áp dụng.** BR-08-004, BR-08-015, BR-08-026.

**Màn hình, API.** UI-08-15, 16; API-08-092…096; kịch bản TS-08-22.
:::

```{.mermaid caption="Trình tự chuyển lỗi bản ghi vàng sang hàng đợi PH-06"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant M as PH-06
  DS->>Q: Chuyển hàng đợi PH-06 (API-08-095)
  Q->>Q: Kiểm lỗi thuộc bản ghi vàng
  Q->>M: Tạo mục hàng đợi DQ_FINDING
  M-->>Q: Mã mục
  Q-->>DS: Phiếu ghi liên kết sang PH-06
```

Hình cho thấy PH-08 không tự sửa bản ghi vàng mà giao việc cho steward của PH-06, đúng ranh giới phân hệ.

### 6.23. UC-08-23 · Khai báo, phát và xử lý cảnh báo chất lượng

Cảnh báo báo cho DS, TO khi điểm giảm mạnh, vượt ngưỡng hoặc quy tắc trỏ danh mục đã ngừng. PH-08 chỉ quyết định khi nào cảnh báo; kênh gửi là của PH-13.

::: dac-ta
**Mục tiêu.** Có quy tắc cảnh báo "điểm `MDM-CITIZEN` giảm ≥ 5 điểm", cảnh báo được gửi qua PH-13 và người nhận xác nhận hoặc tắt tiếng.

**Tác nhân chính.** DS (Lan), TO (Chi).

**Tác nhân phụ.** PH-13 (kênh thông báo), Kafka.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-047, FR-08-048, FR-08-049.

**Truy vết.** REQ-08, REQ-13; BP-07; hệ cũ: không có.

**Tiền điều kiện.** Lan có `PERM-08-rule-admin`; Chi có `PERM-08-read`.

**Kích hoạt.** Lan tạo quy tắc ở UI-08-17; điều kiện thỏa sau một lần đo.

**Đảm bảo tối thiểu.** Mỗi quy tắc và đối tượng chỉ có một cảnh báo chưa `RESOLVED` (BR-08-029).

**Đảm bảo thành công.** Cảnh báo `FIRING` gửi tới người nhận; sau xác nhận hoặc hết điều kiện thì `ACKNOWLEDGED` hoặc `RESOLVED`.

**Luồng chính.**
1. Lan tạo quy tắc cảnh báo: điều kiện "điểm giảm ≥ 5", mức `HIGH`, người nhận Chi (API-08-099).
2. Lần đo sau, điểm giảm 6,2; hệ thống mở cảnh báo `FIRING`, phát EVT-08-12.
3. PH-13 gửi qua kênh của Chi; nhắc lại mỗi `08.alert.repeat-hours` (4 giờ) nếu chưa xác nhận.
4. Chi xác nhận (API-08-102); cảnh báo `ACKNOWLEDGED`.
5. Lần đo kế tiếp điểm hồi phục, hệ thống đặt `RESOLVED` và phát EVT-08-12.

**Luồng thay thế.**
- **4a. Tắt tiếng.** Chi tắt tiếng tối đa 7 ngày kèm lý do ≥ 20 ký tự (API-08-103); hết hạn mà điều kiện còn thì về `FIRING`.
- **1a. Sửa quy tắc.** API-08-100; xem danh sách API-08-098, 101.

**Luồng ngoại lệ.**
- **E1. Quy tắc cảnh báo sai (bước 1).** ERR-08-037 (422): "Quy tắc cảnh báo {mã} không hợp lệ: {chi tiết}."
- **E2. Gửi thất bại (bước 3).** ERR-08-114: "Cảnh báo hoặc thông báo {mã} chưa gửi được tới kênh thông báo." (UI-08-17)
- **E3. Sai trạng thái (bước 4).** ERR-08-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Thiếu lý do khi tắt tiếng (4a).** ERR-08-007 (422): "Nhập lý do (tối thiểu {n} ký tự)."
- **E5. Tắt tiếng quá 7 ngày (4a).** ERR-08-042 (422): "Giá trị {giá trị} của {khóa} ngoài khoảng cho phép {miền}."

**Quy tắc áp dụng.** BR-08-024, BR-08-029.

**Màn hình, API.** UI-08-17; API-08-098…103; kịch bản TS-08-23.
:::

```{.mermaid caption="Trình tự phát và xác nhận cảnh báo"}
sequenceDiagram
  participant Q as dq-control
  participant K as Kafka
  participant N as PH-13
  actor TO
  Q->>Q: Điểm giảm 6,2 thỏa điều kiện
  Q->>K: EVT-08-12 alert.fired FIRING
  K->>N: Chuyển tới kênh thông báo
  N-->>TO: Cảnh báo HIGH
  TO->>Q: Xác nhận (API-08-102)
```

Hình cho thấy PH-08 chỉ phát sự kiện, còn việc gửi qua kênh thuộc PH-13; xác nhận của người nhận quay lại PH-08.

### 6.24. UC-08-24 · Xem bảng điều khiển, thẻ điểm và so sánh liên tenant

Lãnh đạo xem điểm tỉnh, thẻ miền, xu hướng 13 tháng; DS, DO xem thẻ điểm từng đối tượng. VW chỉ thấy số tổng hợp. PA xem so sánh liên tenant ở dạng ẩn danh.

::: dac-ta
**Mục tiêu.** Hùng và lãnh đạo thấy điểm chất lượng của tỉnh, miền cần chú ý, việc tồn, trong một màn hình.

**Tác nhân chính.** VW, DS, DO (xem theo phạm vi); PA (so sánh).

**Tác nhân phụ.** HTTT thành viên (đọc thẻ điểm, scope `dq.read`).

**Mức ưu tiên.** M (FR-08-061 là C) · Đợt 3.

**FR hiện thực.** FR-08-050, FR-08-051, FR-08-061.

**Truy vết.** REQ-08, REQ-20; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-read`; so sánh liên tenant chỉ khi tenant bật `08.benchmark.opt-in`.

**Kích hoạt.** Mở UI-08-01 hoặc UI-08-04.

**Đảm bảo tối thiểu.** VW không mở được danh sách bản ghi lỗi; DO chỉ thấy tổ chức mình; không nêu tên tenant khác (BR-08-030).

**Đảm bảo thành công.** Số liệu lấy từ ảnh chụp mới nhất đã công bố vào bảng điều khiển; so sánh ẩn danh khi nhóm đủ lớn.

**Luồng chính.**
1. Hùng mở UI-08-01; hệ thống gọi API-08-104 và hiện điểm tỉnh, tỷ lệ đối tượng đã đo, lỗi `CRITICAL` mở, phiếu quá hạn.
2. Hùng thấy thẻ miền (điểm, kết luận, radar sáu chiều), miền `FAIL` lên đầu, thẻ có cờ thiếu chiều mang huy hiệu.
3. Hùng mở thẻ điểm tổ chức, miền (API-08-105) rồi thẻ đối tượng `MDM-CITIZEN` (API-08-106) ở UI-08-04.
4. Phúc (DO) mở cùng màn và chỉ thấy đối tượng Sở Tư pháp.

**Luồng thay thế.**
- **1a. VW.** Thấy điểm, xu hướng, số lỗi, không có liên kết sang danh sách lỗi.
- **3a. So sánh liên tenant.** Hà bật chế độ so sánh (API-08-128): xếp hạng theo nhóm ẩn danh, không tên tenant.
- **1b. HTTT đọc thẻ điểm.** Gọi API-08-106 bằng scope `dq.read`, chỉ dữ liệu của mình.

**Luồng ngoại lệ.**
- **E1. Nhóm so sánh nhỏ (3a).** ERR-08-044 (422): "Chưa đủ {n} tỉnh tham gia để so sánh ẩn danh."
- **E2. Đối tượng chưa có bộ quy tắc (bước 3).** ERR-08-027 (422): "Đối tượng {mã} chưa có bộ quy tắc đang hiệu lực."
- **E3. Ngoài phạm vi (bước 4).** ERR-08-032 (403): "Đối tượng {mã} không thuộc tổ chức của anh/chị."

**Quy tắc áp dụng.** BR-08-001, BR-08-026, BR-08-030.

**Màn hình, API.** UI-08-01, 04; API-08-104…106, 128; kịch bản TS-08-24.
:::

```{.mermaid caption="Trình tự dựng bảng điều khiển theo phạm vi người xem"}
sequenceDiagram
  actor U as DA hoặc DO
  participant C as dh-console
  participant Q as dq-control
  U->>C: Mở tổng quan
  C->>Q: GET /dashboard (API-08-104)
  Q->>Q: Lọc theo vai và tổ chức
  Q-->>C: Điểm tỉnh, thẻ miền, việc tồn
  C-->>U: Hiển thị theo phạm vi
```

Hình cho thấy việc lọc theo vai và tổ chức diễn ra ở máy chủ, nên giao diện không nhận số liệu ngoài phạm vi người xem.

### 6.25. UC-08-25 · Sinh, duyệt và công bố báo cáo kỳ, báo cáo năm

Báo cáo kỳ (tháng) tự sinh nháp. Báo cáo chính thức hằng năm chỉ công bố khi mỗi đối tượng trong phạm vi có lần đo `FULL` thành công trong năm, không từ ảnh chụp có cờ `INCOMPLETE_DIMENSIONS`.

::: dac-ta
**Mục tiêu.** Báo cáo năm 2026 của tỉnh T68 được soạn, có khuyến nghị, được Hùng duyệt và công bố, bất biến.

**Tác nhân chính.** DS (Lan, soạn), DA (Hùng, duyệt).

**Tác nhân phụ.** bộ lập lịch nội bộ (tự sinh nháp), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-052, FR-08-053, FR-08-054.

**Truy vết.** REQ-08; FR-00-071; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Lan có `PERM-08-report`; Hùng có `PERM-08-approve`, khác Lan.

**Kích hoạt.** Lan bấm "Lập báo cáo năm" ở UI-08-18; hoặc hệ thống tự sinh nháp tháng (`08.report.auto-draft`).

**Đảm bảo tối thiểu.** Báo cáo `PUBLISHED` không sửa được; sai sót xử lý bằng thu hồi và báo cáo thay thế.

**Đảm bảo thành công.** Báo cáo `PUBLISHED` có `contentHash`; phát EVT-08-11; báo cáo năm chỉ dùng lần đo `FULL`.

**Luồng chính.**
1. Lan bấm "Kiểm tra sẵn sàng" (API-08-115); hệ thống liệt kê đối tượng thiếu lần đo `FULL` hoặc thiếu chiều.
2. Chi chạy bù đo `FULL` trigger `ANNUAL` cho đối tượng còn thiếu (UC-08-10).
3. Lan sinh báo cáo (API-08-107, `reportType = ANNUAL`), thêm khuyến nghị, sửa nháp (API-08-110).
4. Lan gửi duyệt (API-08-111); hệ thống kiểm có khuyến nghị.
5. Hùng duyệt và công bố (API-08-112); hệ thống kiểm Hùng khác Lan, đặt `PUBLISHED`, phát EVT-08-11.

**Luồng thay thế.**
- **5a. Từ chối.** Hùng từ chối (API-08-113), báo cáo về `DRAFT`.
- **5b. Thu hồi.** Hùng thu hồi báo cáo kèm lý do (API-08-114), báo cáo `WITHDRAWN`; Lan lập báo cáo thay thế.
- **3a. Báo cáo kỳ.** `PERIODIC`, `AD_HOC` dùng cùng bước 3 đến 5 với ảnh chụp đầy đủ mới nhất.

**Luồng ngoại lệ.**
- **E1. Chưa đủ điều kiện năm (bước 1, 4).** ERR-08-038 (422): "Chưa đủ điều kiện báo cáo chính thức năm {năm}: {n} đối tượng thiếu lần đo toàn bộ hoặc có điểm thiếu chiều."
- **E2. Thiếu khuyến nghị (bước 4).** ERR-08-039 (422): "Báo cáo cần ít nhất một khuyến nghị trước khi gửi duyệt."
- **E3. Báo cáo đã công bố (bước 3).** ERR-08-040 (409): "Báo cáo {mã} đã công bố và không sửa được. Thu hồi và lập báo cáo thay thế."
- **E4. Tự duyệt (bước 5).** ERR-08-005 (403): "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."
- **E5. Kỳ không có lần đo thành công (bước 3).** ERR-08-056 (422): "Không có lần đo thành công nào trong kỳ {kỳ} để lập báo cáo."

**Quy tắc áp dụng.** BR-08-007, BR-08-009, BR-08-010, BR-08-011.

**Màn hình, API.** UI-08-18; API-08-107…115; kịch bản TS-08-25.
:::

```{.mermaid caption="Trình tự soạn, duyệt và công bố báo cáo năm"}
sequenceDiagram
  actor DS
  actor DA
  participant Q as dq-control
  participant K as Kafka
  DS->>Q: Kiểm tra sẵn sàng (API-08-115)
  Q-->>DS: Danh sách đối tượng thiếu FULL
  DS->>Q: Sinh báo cáo, thêm khuyến nghị (API-08-107)
  DS->>Q: Gửi duyệt (API-08-111)
  DA->>Q: Duyệt và công bố (API-08-112)
  Q->>Q: PUBLISHED, băm nội dung
  Q->>K: EVT-08-11 report.published
```

Hình cho thấy điều kiện đo `FULL` được kiểm trước khi soạn, và báo cáo chỉ bất biến sau khi người thứ hai công bố.

### 6.26. UC-08-26 · Xuất, ký số, phân phối báo cáo và đẩy chỉ số sang PH-16, PH-13

Báo cáo đã công bố xuất ra PDF hoặc XLSX, ký số tùy chọn, phân phối cho người đăng ký. Hệ thống cũng đẩy chỉ số sang PH-16 (KPI) và PH-13 (vận hành).

::: dac-ta
**Mục tiêu.** Báo cáo `PUBLISHED` có tệp PDF ký số, gửi người đăng ký; KPI chất lượng dữ liệu hiện ở PH-16.

**Tác nhân chính.** DS (Lan); hệ thống (đẩy chỉ số).

**Tác nhân phụ.** Dịch vụ ký số của nền tảng, PH-13, PH-16.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-08-055, FR-08-056, FR-08-057.

**Truy vết.** REQ-08, REQ-13, REQ-16; BP-07, BP-10; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-08-report`; báo cáo `PUBLISHED`.

**Kích hoạt.** Lan bấm "Xuất" ở UI-08-18; hoặc có ảnh chụp đầy đủ mới, báo cáo công bố.

**Đảm bảo tối thiểu.** Tệp xuất chứa số liệu đã che; đẩy chỉ số lỗi thì giữ hàng chờ, gửi lại.

**Đảm bảo thành công.** Có tệp PDF ký số hoặc XLSX tải được; người đăng ký nhận thông báo; EVT-08-14 đã phát.

**Luồng chính.**
1. Lan chọn định dạng PDF kèm ký số (API-08-116); hệ thống sinh tệp.
2. Hệ thống ký bằng chứng thư cơ quan (Q08-06), gắn `contentHash` (API-08-118).
3. Lan tải tệp (API-08-117).
4. Hệ thống phân phối cho người đăng ký (API-08-120) qua PH-13.
5. Hệ thống phát EVT-08-14 `t68.dq.kpi.published.v1` cho PH-16; lỗi vận hành sang PH-13 (API-08-122 xem lịch sử).

**Luồng thay thế.**
- **1a. XLSX.** Không ký số.
- **4a. Đăng ký, hủy nhận.** API-08-119, API-08-121.

**Luồng ngoại lệ.**
- **E1. Ký số thất bại (bước 2).** ERR-08-048 (422): "Không ký số được báo cáo {mã}: {nguyên nhân}."
- **E2. Sinh tệp thất bại (bước 1).** ERR-08-112: "Không tạo được {báo cáo hoặc tệp} {mã}. Thử lại sau."
- **E3. Phân phối thất bại (bước 4).** ERR-08-114: "Cảnh báo hoặc thông báo {mã} chưa gửi được tới kênh thông báo."
- **E4. Đẩy KPI chậm (bước 5).** ERR-08-113: "Chưa đẩy được {n} bản tin KPI chất lượng dữ liệu sang PH-16."

**Quy tắc áp dụng.** BR-08-009, BR-08-012.

**Màn hình, API.** UI-08-18, 19; API-08-116…122; kịch bản TS-08-26.
:::

```{.mermaid caption="Trình tự xuất, ký số và đẩy KPI"}
sequenceDiagram
  actor DS
  participant Q as dq-control
  participant G as Dịch vụ ký số
  participant K as Kafka
  DS->>Q: Xuất PDF, ký số (API-08-116)
  Q->>G: Ký chứng thư cơ quan
  G-->>Q: Chữ ký
  Q-->>DS: Tệp tải được
  Q->>K: EVT-08-14 kpi.published cho PH-16
```

Hình cho thấy việc ký do dịch vụ nền tảng thực hiện, còn PH-08 chỉ gắn kết quả vào báo cáo và đẩy KPI qua sự kiện.

### 6.27. UC-08-27 · Tham số tenant, lưu giữ dữ liệu đo và nhật ký kiểm toán

TA chỉnh 40 tham số `08.*` trong trần của PA, chạy dọn dữ liệu theo thời hạn lưu giữ; SO, AU xem nhật ký kiểm toán PH-08.

::: dac-ta
**Mục tiêu.** Mai chỉnh tham số, xem trước và chạy dọn dữ liệu; Dũng tra nhật ký ai đã làm gì với đối tượng, quy tắc, báo cáo.

**Tác nhân chính.** TA (Mai); SO (Dũng), AU.

**Tác nhân phụ.** PA (trần tham số), bộ lập lịch nội bộ (job dọn), nhật ký chung.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-08-058, FR-08-059, FR-08-060.

**Truy vết.** REQ-08; BP-10; hệ cũ: không có.

**Tiền điều kiện.** Mai có `PERM-08-config`; Dũng, AU có `PERM-08-audit-read`.

**Kích hoạt.** Mai mở UI-08-19; Dũng mở tab nhật ký hoặc UI-08-04.

**Đảm bảo tối thiểu.** Không đặt thời hạn lưu dưới sàn (BR-08-028); không ghi được kiểm toán thì từ chối thao tác.

**Đảm bảo thành công.** Tham số hiệu lực ở lần đo kế tiếp; dữ liệu quá hạn được dọn; nhật ký đầy đủ, không sửa.

**Luồng chính.**
1. Mai đổi `08.scan.window` thành `23:00-05:00` (API-08-124); hệ thống kiểm miền và trần.
2. Hệ thống lưu, ghi kiểm toán giá trị cũ, mới, người đổi.
3. Mai xem trước dọn dữ liệu (API-08-126): lỗi quá 13 tháng, kết quả quy tắc quá 24 tháng.
4. Job dọn chạy theo lịch, ghi kết quả (API-08-125).
5. Dũng lọc nhật ký theo đối tượng, người, thời gian (API-08-127), xuất nếu cần.

**Luồng thay thế.**
- **1a. Xem tham số.** API-08-123, hiện mặc định, giá trị hiện tại và trần PA.
- **5a. AU.** Chỉ xem, không xuất giá trị đã che.

**Luồng ngoại lệ.**
- **E1. Ngoài miền hoặc trần (bước 1).** ERR-08-042 (422): "Giá trị {giá trị} của {khóa} ngoài khoảng cho phép {miền}."
- **E2. Lưu giữ dưới sàn (bước 1).** ERR-08-043 (422): "Thời gian lưu {loại} không được dưới {n} {đơn vị}."
- **E3. Dọn thất bại (bước 4).** ERR-08-117: "Lần dọn dữ liệu {ngày} chưa hoàn tất: {nguyên nhân}."
- **E4. Không ghi được kiểm toán (bước 2).** ERR-08-054 (503): "Hệ thống tạm thời không ghi được nhật ký. Thao tác chưa được thực hiện."

**Quy tắc áp dụng.** BR-08-007, BR-08-028.

**Màn hình, API.** UI-08-19, 04; API-08-123…127; kịch bản TS-08-27.
:::

```{.mermaid caption="Trình tự đổi tham số tenant và ghi kiểm toán"}
sequenceDiagram
  actor TA
  participant Q as dq-control
  participant A as Nhật ký kiểm toán
  TA->>Q: Đổi 08.scan.window (API-08-124)
  Q->>Q: Kiểm miền giá trị và trần PA
  Q->>A: Ghi giá trị cũ, mới, người đổi
  A-->>Q: Đã ghi
  Q-->>TA: 200, hiệu lực từ lần đo kế tiếp
```

Hình cho thấy kiểm toán được ghi trước khi trả kết quả, nên thao tác không có dấu vết sẽ không được thực hiện.

## 7. Luồng phụ dùng chung

Ba luồng phụ dưới đây lặp lại ở nhiều use case nên đặc tả một lần; bước ghi "theo LP-08-nn". Mã lỗi và câu thông báo vẫn ghi ở luồng ngoại lệ của use case dùng.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-08-01 | Bốn mắt: hệ thống so người duyệt với người soạn hoặc người gửi; trùng thì khóa nút "Duyệt" và trả ERR-08-005 (403) nếu gọi thẳng API. DS và DA là cặp loại trừ trong tenant. Duyệt cần ý kiến, từ chối cần lý do (FR-00-071, ADR-046) | UC-08-07, 09, 17, 18, 25 |
| LP-08-02 | Lý do bắt buộc: quyết định và thao tác thủ công cần lý do, thiếu thì ERR-08-007 (422) "Nhập lý do (tối thiểu {n} ký tự)." | UC-08-03, 07, 09, 18, 21, 22 |
| LP-08-03 | Phạm vi tổ chức: DO chỉ xem và xử lý đối tượng, lỗi, phiếu của tổ chức mình, VW chỉ thấy tổng hợp, ngoài phạm vi trả ERR-08-032 (403) (BR-08-026) | UC-08-03, 16, 17, 19, 20, 24 |

: Luồng phụ dùng chung và use case dùng

## 8. Tổng hợp mã mới và đối chiếu

### 8.1. Mã mới và độ phủ

Tập này không tạo mã FR, BR, API, ERR, EVT, UI mới. Mã của tập: UC-08-01…27, LP-08-01…03, câu hỏi Q08-45…49 (đã chốt ở FRS 0.2); đề nghị kịch bản kiểm thử TS-08-01…27 ứng với UC-08-01…27 cho D05-02-PH08. Cả 61 FR thuộc ít nhất một use case (§5.4). Mọi mã ERR, EVT, API, UI, PERM, enum và tham số `08.*` lấy đúng FRS chương 8, 9, 10 và Phụ lục A; câu thông báo lấy nguyên văn FRS §9.2.

### 8.2. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Bảy đề nghị của bản 0.1 đã được FRS 0.2 xử lý (FRS chương 15); cột cuối ghi kết quả. Tập này không sửa tệp nào ngoài tập của mình.

| Mã | Tài liệu | Đề nghị | Kết quả ở FRS 0.2 |
|---|---|---|---|
| ĐN-UC-01 | D02-03-PH08 (FR-08-017, FR-08-021) | Ghi rõ ai là "người đề nghị" khi đối tượng không có DS riêng; nêu DA dự phòng cấp tỉnh | Đã hấp thụ: FR-08-017 bước 3, 3a; Q08-18 |
| ĐN-UC-02 | D02-03-PH08 (FR-08-016) | Không mất dấu "đã chạy thử" khi chỉ đổi mô tả quy tắc | Đã hấp thụ: FR-08-016 bước 4 |
| ĐN-UC-03 | D02-03-PH08 (FR-08-044) | Nêu API tạo lần đo `VERIFY` | Đã hấp thụ theo hướng khác: hệ thống tự tạo `VERIFY` khi báo đã sửa; UC-08-21 đã sửa theo |
| ĐN-UC-04 | D02-03-PH08 (FR-08-046), D02-03-PH06 | Mã lý do `DQ_FINDING`, `DQ_GATE`, SLA, người nhận ở PH-06 | Phần PH-08 đã hấp thụ; phần PH-06 dồn đợt đồng bộ cuối |
| ĐN-UC-05 | D03-06-PH08 | Câu thông báo theo ngữ cảnh cho ERR-08-005, 006, 007 | Dồn cho tập màn hình; MH 0.2 đã làm |
| ĐN-UC-06 | D05-02-PH08 | Dựng `TS-08-01…27` ứng với UC | Dồn cho tập kiểm thử; TC 0.2 có TS-08-01…35 phủ mọi UC |
| ĐN-UC-07 | D02-08 | Xác nhận 11 quyền PERM-08, cặp loại trừ DS và DA, scope máy | Đã hấp thụ vào FRS Phụ lục B (thêm `dq.ingest`); sửa D02-08 dồn đợt đồng bộ cuối |

: Đề nghị đồng bộ cho tài liệu khác

## 9. Câu hỏi mở

Năm câu hỏi Q08-45…49 của bản 0.1 đã được FRS 0.2 chốt, không còn mở ở tập này.

| Mã | Câu hỏi bản 0.1 | Kết quả |
|---|---|---|
| Q08-45 | Tenant chỉ có một người giữ `PERM-08-approve` thì bốn mắt bị chặn (UC-08-07, 09) | Buộc có DA dự phòng do TA chỉ định, không duyệt ngoài hệ thống (Q08-18, FR-08-017 bước 3a) |
| Q08-46 | Bản sao chỉ đọc chậm đồng bộ làm đo `VERIFY` thấy lỗi cũ (UC-08-21) | Tham số `08.verify.wait-source-minutes` (Q08-19) |
| Q08-47 | Ứng viên bị `DQ_GATE` vào hàng đợi nào, có tính vào bản ghi lỗi không (UC-08-16) | Không tính vào bản ghi lỗi, chỉ thống kê phút (FR-08-035 bước 4); phía PH-06 dồn đợt cuối |
| Q08-48 | PH-06 từ chối chuyển lỗi bản ghi vàng thì ai đóng phiếu (UC-08-22) | Trả phiếu về DS với lý do (FR-08-046) |
| Q08-49 | Đối tượng `FLOW_MESSAGE` và điều kiện báo cáo năm (UC-08-25) | Loại khỏi điều kiện sẵn sàng (FR-08-054 bước 1, BR-08-010) |

: Câu hỏi mở của bản 0.1 và kết quả

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-UC và K-TRINH-BAY: 27 use case phủ 61 FR, năm sơ đồ use case, mỗi use case một sơ đồ trình tự, ma trận UC với FR, UI, API, REQ, LGC, ánh xạ FR repo, bảy đề nghị đồng bộ, câu hỏi mở Q08-45…49 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ theo FRS 0.2: lịch đo do bộ lập lịch nội bộ (PH-18 là phụ thuộc mềm), dấu vân tay HMAC-SHA256, đo `VERIFY` do hệ thống tự tạo (UC-08-21 sửa theo FR-08-044, lý do xác nhận thủ công ≥ 50 ký tự), bảy đề nghị ĐN-UC-01…07 và Q08-45…49 đã được FRS xử lý; rà chéo cuối: xem trước trọng số API-08-132, bật, tắt đo tăng dần API-08-130, 131, `POST /findings:search` API-08-129, `ADVISORY` trả `WARN` khi có vi phạm, lô trực tuyến tối đa 100 bản ghi, ERR-08-016 cho `INLINE` với toán tử chỉ chạy lô, ERR-08-042 cho hạn tắt tiếng, ERR-08-056 cho kỳ không có lần đo |
