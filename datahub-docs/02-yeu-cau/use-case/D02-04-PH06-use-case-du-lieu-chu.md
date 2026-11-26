---
ma_tai_lieu: D02-04-PH06
ten: Đặc tả use case phân hệ PH-06 Dữ liệu chủ
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-06
mo_ta: Đặc tả 28 use case của phân hệ Dữ liệu chủ (MDM), mỗi use case một khối 15 mục kèm mã lỗi và câu thông báo lấy từ FRS, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH06 FRS; D03-02-PH06 SDD; D03-03-PH06 CSDL; D03-04-PH06 API; D03-06-PH06 Màn hình; D05-02-PH06 Kiểm thử
---

# D02-04-PH06 · Đặc tả use case Dữ liệu chủ

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 28 use case của PH-06, phủ toàn bộ 60 FR (54 mức M, 6 mức S) của [D02-03-PH06](../frs/D02-03-PH06-frs-du-lieu-chu.md). Use case đi theo đường đi của một bản ghi dữ liệu chủ ở tỉnh: quản trị khai báo domain `CITIZEN`, `ORGANIZATION`, `ADDRESS` và nguồn; HTTT, luồng PH-04, sự kiện PH-10 hoặc tệp đưa bản ghi ứng viên vào; hệ thống chuẩn hóa, đối sánh (xác định, xác suất trực tuyến, Splink theo lô) rồi tạo hoặc cập nhật bản ghi vàng; trường hợp nghi ngờ vào hàng đợi cho người quản lý dữ liệu; HTTT tra cứu, resolve, nhận sự kiện; PH-06 đối chiếu với CSDL quốc gia qua PH-14 và xử lý yêu cầu của chủ thể dữ liệu. Căn cứ pháp lý như FRS: CMP-LAW-01 (Luật Dữ liệu), CMP-LAW-03 (NĐ 278/2025, thay NĐ 47/2020), CMP-LAW-05 và CMP-LAW-04 (Luật BVDLCN 91/2025, NĐ 356/2025), CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026).

Bốn điểm hội đồng cần lưu ý. Thứ nhất, hệ cũ (Viettel 2021) không có MDM nên không có chức năng cũ để so sánh; 28 use case là năng lực mới, chỉ LGC-NGSP-003, LGC-NGSP-005, LGC-DMDC-015 và 019 liên quan gián tiếp (§5.3). Thứ hai, quyết định có hậu quả lớn đều qua bốn mắt: kích hoạt mô hình, bộ quy tắc, thứ tự ưu tiên nguồn, hợp nhất rủi ro cao, hoàn tác quá hạn, xuất dữ liệu (LP-06-01). Thứ ba, mọi thay đổi bản ghi vàng ghi ảnh chụp trước thay đổi nên hoàn tác được trong 90 ngày (UC-06-20), và kết quả máy không ghi đè quyết định của người (BR-06-023). Thứ tư, CSDL quốc gia là chuẩn cho nhân thân; lệch bất thường (> 5%) làm đồng bộ tự động dừng chứ không áp hàng loạt (UC-06-25).

## 1. Giới thiệu

Chương này nói tài liệu dùng để làm gì, phủ những gì, ai cần đọc phần nào, thuật ngữ và tài liệu cần mở song song.

### 1.1. Mục đích

Tài liệu đặc tả 28 use case (ca sử dụng) của PH-06 Dữ liệu chủ. Mỗi use case mô tả trọn một mục tiêu nghiệp vụ của một tác nhân theo từng bước tương tác với hệ thống, kèm nhánh thay thế, tình huống ngoại lệ có mã lỗi và câu thông báo người dùng nhìn thấy, và các đảm bảo hệ thống giữ dù thành công hay thất bại. Tài liệu nối FRS (hệ thống phải làm gì) với D03-02 SDD, D03-03 CSDL, D03-04 API và D03-06 màn hình (làm thế nào); kiểm thử viên dùng luồng chính, thay thế, ngoại lệ làm khung kịch bản `TS-06-nn` ở D05-02-PH06.

### 1.2. Phạm vi

Phạm vi là toàn bộ FR-06-001…060. Tài liệu mô tả trình tự giữa tác nhân và hệ thống, dữ liệu ví dụ và cách xử lý khi sai lệch; ràng buộc chi tiết từng bước (kiểu, miền giá trị, thứ tự kiểm tra) nằm ở FR và không chép lại. Chức năng dùng chung FR-00 (đăng nhập, chọn tenant, danh sách, kiểm toán, "Việc của tôi", thông báo, xác nhận thao tác) không đặc tả lại; bước dựa vào chúng ghi "Tuân thủ FR-00-nnn". Mọi enum, trạng thái, tên trường, quyền, tham số `06.*`, mã màn hình, mã sự kiện dùng đúng Phụ lục A và §8.2 của FRS.

Ngoài phạm vi: dữ liệu nghiệp vụ gốc của HTTT (PH-06 chỉ giữ bản ghi vàng, không thay nguồn); thuật toán chi tiết Splink và `pg_trgm` (SDD D03-02-PH06); gọi trực tiếp CSDL quốc gia (qua PH-14, BR-06-032); domain cán bộ công chức, thửa đất (Q06-04).

### 1.3. Người đọc

Hội đồng thẩm định đọc tóm tắt, chương 4, 5, 9. Sở KH&CN và Trung tâm dữ liệu rà UC-06-12…20, 25…28. Kỹ sư `dh-data`, `dh-console`, PH-04 đọc chương 6 (luồng, mã lỗi, mục "Màn hình, API") và sơ đồ trình tự. Kiểm thử viên coi mỗi luồng chính, thay thế, ngoại lệ là ít nhất một phép kiểm trong `TS-06-nn`.

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01; thuật ngữ riêng theo FRS §1.4 và §4.1. Bảng chỉ nhắc các từ dày đặc trong luồng.

| Thuật ngữ | Giải thích |
|---|---|
| Dữ liệu chủ (MDM) | Dữ liệu cốt lõi dùng chung giữa nhiều hệ thống (công dân, tổ chức, địa chỉ), giữ ở một bản ghi chuẩn |
| Bản ghi vàng (golden record) | Bản ghi chuẩn duy nhất của một thực thể, gộp từ nhiều bản ghi nguồn, mỗi thuộc tính có nguồn gốc riêng (BR-06-009) |
| Bản ghi ứng viên | Bản ghi do một nguồn gửi tới, chưa gắn với bản ghi vàng; qua chuẩn hóa và đối sánh mới được liên kết |
| Đối sánh | So khớp ứng viên với bản ghi vàng: xác định (theo khóa định danh), xác suất trực tuyến (`pg_trgm`, trọng số), theo lô (Splink) |
| Ba vùng ngưỡng | `MATCH` tự hợp nhất, `POSSIBLE_MATCH` vào hàng đợi, `NO_MATCH` tạo bản ghi mới |
| Sống sót (survivorship) | Cách chọn giá trị thắng cho từng thuộc tính khi các nguồn mâu thuẫn |
| Liên kết chéo nguồn (xref) | Cặp `(sourceCode, sourceKey)` gắn với một `goldenId` |
| DS, DA, DO, TA, TO, SO, PA, AU, VW | Người quản lý dữ liệu, người duyệt dữ liệu, chủ quản dữ liệu, quản trị tenant, vận hành tenant, cán bộ ATTT, quản trị nền tảng, kiểm toán, người xem (FRS §3.1) |
| DSR | Yêu cầu của chủ thể dữ liệu (biết, sửa, hạn chế xử lý) |
| `LOCKED` | Trạng thái bản ghi vàng đang có thao tác chờ duyệt hoặc chủ thể yêu cầu hạn chế |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

[D02-03-PH06 FRS](../frs/D02-03-PH06-frs-du-lieu-chu.md) (nguồn chuẩn: §3 tác nhân, §4 máy trạng thái, §9 mã lỗi, thông báo, sự kiện, API, §10.1 màn hình, Phụ lục A); D02-01 (REQ, BP); D02-02 SRS §5; D02-08 (quyền, vai trò); D00-01 (hệ mã); D00-04 (sổ tra cứu gọn); K-UC, K-TRINH-BAY; `docs/07-srs/SRS-PH-06-mdm.md` (SRS cũ của repo).

### 1.6. Cấu trúc tài liệu

Chương 2 quy ước đọc; 3 tác nhân; 4 sơ đồ tổng (năm hình); 5 bảng tổng hợp và truy vết; 6 hai mươi tám khối đặc tả; 7 luồng phụ; 8 mã mới và đề nghị cho FRS; 9 câu hỏi mở.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ · Quy tắc áp dụng · Màn hình, API. Đoạn văn trước khối nói bối cảnh; sau khối là sơ đồ khi use case có từ ba thành phần trở lên trao đổi.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3) và nêu bước quay lại. Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-06-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép (nguyên văn FRS §9.2 hoặc khối FR; dấu `{…}` do máy chủ điền). Lỗi ERR-06-101…114 là lỗi nền (job, đồng bộ), không trả cho người gọi API, vận hành thấy ở UI-06-01, 12, 14, 18. Luồng phụ dùng chung ghi `LP-06-nn`, đặc tả một lần ở chương 7.

Quy ước chung không nhắc lại từng use case: lệnh ghi qua `/api/mdm/v1` mang `Idempotency-Key` và `If-Match` khi sửa (xung đột: ERR-06-004, 409); đối tượng tenant khác trả như không tồn tại (ERR-06-001, 404); mọi truy vấn chạy dưới RLS theo `tenant_id`; mọi thao tác ghi sinh kiểm toán. Dữ liệu ví dụ giả lập, tenant `T68`.

| Vai | Người hoặc hệ thống | Ghi chú |
|---|---|---|
| DS | ROLE-DATA_STEWARD | `PERM-06-read`, `update`, `merge`, `config`, `steward`, `ingest`, `sync`, `dsr` (○ theo tổ chức) | 02, 04, 06…09, 12, 13, 15…21, 23…25, 27 |
| DA | ROLE-DATA_APPROVER | `PERM-06-approve`, `merge`, `steward`, `export`, `sync` | 03, 04, 09, 11, 12, 14, 15, 18…20, 23, 25 |
| TA, TO | **Mai** (Sở KH&CN), **Chi** (Trung tâm dữ liệu) | Quản trị tenant, vận hành |
| SO, DO, PA | **Dũng** (ATTT), **Phúc** (Sở Tư pháp), **Hà** (đơn vị vận hành nền tảng) | |
| Nguồn | `HT-HOTICH`, `HT-GIAODUC`, `HT-BHXH`, `QG-DANCU`, `QG-DKDN`, `FILE-XA-00004` | `SourceKind`: `SECTOR_AUTHORITATIVE`, `SECTOR_RELATED`, `NATIONAL_DB`, `FILE_BATCH` |
| Bản ghi vàng | `G-10234` (CCCD `001090012345`), `G-10871` | Công dân giả lập "Nguyễn Văn A", sinh 15/01/1990, xã `00004` |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-06 có chín nhóm tác nhân người và các tác nhân hệ thống. Người duyệt dữ liệu chỉ quyết định thao tác do người khác đề nghị; DS và DA là cặp loại trừ trong tenant (FRS §3.3). HTTT và phân hệ khác là tác nhân chính của use case máy với máy (nạp, resolve, tra cứu). Job Splink chỉ có quyền trên bảng staging và kết quả, không ghi bản ghi vàng.

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính | Use case tham gia |
|---|---|---|---|
| DS | ROLE-DATA_STEWARD | `PERM-06-read`, `update`, `merge`, `config`, `steward`, `ingest`, `sync`, `dsr` (○ theo tổ chức) | 02, 04, 06…09, 12, 13, 15…21, 23…25, 27 |
| DA | ROLE-DATA_APPROVER | `PERM-06-approve`, `merge`, `steward`, `export`, `sync` | 03, 04, 09, 11, 12, 14, 15, 18…20, 23, 25 |
| DO | ROLE-DATA_OWNER | `PERM-06-export` (○) | 23, 24 |
| TA | ROLE-TENANT_ADMIN | `PERM-06-config`, `merge`, `operate`, `sync`, `dsr` | 02…04, 06, 08, 09, 11, 12, 15, 17, 20, 24…26, 28 |
| TO | ROLE-TENANT_OPERATOR | `PERM-06-operate`, `read` | 07, 11, 26 |
| SO | ROLE-SECURITY_OFFICER | `PERM-06-audit-read`, `dsr` | 16, 26, 27 |
| PA | ROLE-PLATFORM_ADMIN | gói nền `COMMON` | 01 |
| AU, VW | ROLE-AUDITOR, ROLE-VIEWER | `PERM-06-audit-read` (AU), `PERM-06-read` | 16, 26 |
| HTTT thành viên | ROLE-PARTNER_SYSTEM | `mdm:ingest`, `mdm:read`, `mdm:resolve`, `mdm:search`, `mdm:xref` | 05, 21, 22, 24 |
| PH-04 | `dh-integration`, `dh-runtime` | `mdm:ingest`, `mdm:resolve`, `mdm:xref` | 05, 21, 22 |
| PH-07, PH-09, PH-10, PH-14, PH-08, PH-13 | Phân hệ | Mã danh mục; mục đích, che; topic; đồng bộ quốc gia; chỉ số | 01, 02, 05, 07, 21…27 |
| Job Splink | Job K8s | Tài khoản CSDL riêng | 11 |

: Tác nhân và use case tham gia

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, 28 use case chia thành năm hình theo vòng đời: cấu hình, nạp và chuẩn hóa, đối sánh và hàng đợi, bản ghi vàng, cung cấp và vận hành. Mermaid không có ký pháp UML use case nên dùng `flowchart`: hình bo tròn là tác nhân người, hình hai viền là tác nhân hệ thống, hình chữ nhật bo góc là use case; đường liền nối tác nhân với use case mà họ tham gia.

```{.mermaid caption="Use case cấu hình domain, nguồn và quy tắc"}
flowchart TB
  PA([PA])
  TA([TA, DS])
  DA([DA])
  P7[[PH-07, PH-09]]
  subgraph CF["Cấu hình"]
    U01(UC-06-01 Gói nền)
    U02(UC-06-02 Soạn mô hình)
    U03(UC-06-03 Duyệt, kích hoạt domain)
    U04(UC-06-04 Nguồn, ưu tiên nguồn)
    U08(UC-06-08 Soạn bộ quy tắc)
    U09(UC-06-09 Nhãn, đánh giá, kích hoạt quy tắc)
    U15(UC-06-15 Quy tắc sống sót)
    U01 ~~~ U02 ~~~ U03 ~~~ U04 ~~~ U08 ~~~ U09 ~~~ U15
  end
  PA --- U01
  TA --- U02 & U03 & U04 & U08 & U09 & U15
  DA --- U03 & U04 & U09 & U15
  P7 --- U01 & U02
```

Hình cho thấy quản trị soạn, người duyệt dữ liệu quyết định: mô hình, thứ tự ưu tiên nguồn, bộ quy tắc (kèm đánh giá precision, recall) và quy tắc sống sót đều qua bốn mắt. PH-07 và PH-09 cung cấp danh mục và phân loại.

```{.mermaid caption="Use case nạp và chuẩn hóa ứng viên"}
flowchart TB
  SRC[[HTTT, PH-04, PH-10]]
  DS([DS, TA])
  TO([TO])
  subgraph IN["Nạp ứng viên"]
    U05(UC-06-05 Nạp qua API, luồng, sự kiện)
    U06(UC-06-06 Nạp tệp lô)
    U07(UC-06-07 Chuẩn hóa, xử lý ứng viên lỗi)
    U05 ~~~ U06 ~~~ U07
  end
  SRC --- U05
  DS --- U06 & U07
  TO --- U07
```

Hình cho thấy ba kênh nạp tự động (API, luồng PH-04, sự kiện PH-10) và một kênh tệp có xem trước đều dồn về chuẩn hóa; bản ghi sai nằm lại ở danh sách ứng viên cho DS xử lý.

```{.mermaid caption="Use case đối sánh và hàng đợi người quản lý dữ liệu"}
flowchart TB
  SYS[[Hệ thống đối sánh]]
  J[[Job Splink]]
  TO([TA, TO])
  DS([DS])
  DA([DA])
  subgraph MT["Đối sánh, hàng đợi"]
    U10(UC-06-10 Đối sánh tự động)
    U11(UC-06-11 Job lô Splink)
    U12(UC-06-12 Hàng đợi, SLA)
    U13(UC-06-13 So sánh, quyết định)
    U14(UC-06-14 Duyệt bốn mắt)
    U10 ~~~ U11 ~~~ U12 ~~~ U13 ~~~ U14
  end
  SYS --- U10
  J --- U11
  TO --- U11
  DS --- U12 & U13
  DA --- U11 & U12 & U14
```

Hình cho thấy máy chỉ tự quyết ở vùng chắc chắn; cặp nghi ngờ qua UC-06-12 và 13 đến người, hợp nhất rủi ro cao còn qua DA (UC-06-14). DA cũng xác nhận job lô vượt ngưỡng an toàn (UC-06-11).

```{.mermaid caption="Use case thao tác trên bản ghi vàng"}
flowchart TB
  DS([DS, TA])
  DA([DA])
  SO([SO, AU])
  subgraph GR["Bản ghi vàng"]
    U16(UC-06-16 Xem, lịch sử, nguồn gốc)
    U17(UC-06-17 Sửa tay, ngừng, khôi phục)
    U18(UC-06-18 Hợp nhất thủ công)
    U19(UC-06-19 Tách, gỡ liên kết)
    U20(UC-06-20 Hoàn tác)
    U16 ~~~ U17 ~~~ U18 ~~~ U19 ~~~ U20
  end
  DS --- U16 & U17 & U18 & U19 & U20
  DA --- U18 & U19 & U20
  SO --- U16
```

Hình cho thấy mọi thao tác thủ công đều có lý do và ảnh chụp trước; hợp nhất, tách, hoàn tác quá hạn cần DA. SO, AU chỉ xem.

```{.mermaid caption="Use case cung cấp dữ liệu, đồng bộ quốc gia và vận hành"}
flowchart TB
  H[[HTTT, PH-04, PH-08]]
  P14[[PH-14, PH-09]]
  DS([DS, DA, DO])
  TA([TA, TO, SO])
  subgraph CP["Cung cấp, đồng bộ, vận hành"]
    U21(UC-06-21 Tra cứu, xref, tìm kiếm)
    U22(UC-06-22 Resolve trực tuyến)
    U23(UC-06-23 Xuất có kiểm soát)
    U24(UC-06-24 Đăng ký nhận, phát sự kiện)
    U25(UC-06-25 Đồng bộ quốc gia, lệch)
    U26(UC-06-26 Dashboard, job, nhật ký)
    U27(UC-06-27 Yêu cầu chủ thể)
    U28(UC-06-28 Lưu giữ, tham số)
    U21 ~~~ U22 ~~~ U23 ~~~ U24 ~~~ U25 ~~~ U26 ~~~ U27 ~~~ U28
  end
  H --- U21 & U22 & U24
  P14 --- U21 & U22 & U25 & U27
  DS --- U23 & U24 & U25 & U27
  TA --- U26 & U28 & U25
```

Hình cho thấy mọi đường ra đi qua mục đích PH-09 và nhật ký truy cập; PH-14 là cửa duy nhất tới CSDL quốc gia.

## 5. Bảng tổng hợp use case và truy vết

Chương này là danh sách chính thức 28 use case, đặt trước phần chi tiết để tra nhanh. Bảng 5.3 là nguồn của mục "Truy vết" trong từng khối đặc tả; bảng 5.2 là nguồn của mục "Màn hình, API". Hệ cũ (Viettel 2021) không có MDM nên cột LGC chủ yếu là "—" (năng lực mới); kết luận về LGC liên quan gián tiếp ở §5.5.

### 5.1. Use case và FR

Bảng dưới liệt kê 28 use case, tác nhân chính, mức ưu tiên cao nhất và FR hiện thực (số đuôi của `FR-06-nnn`). Cả 54 FR mức M và 6 FR mức S đều thuộc ít nhất một use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-06-01 | Nạp gói domain nền và xem domain | PA | M | 001, 007 |
| UC-06-02 | Soạn mô hình domain, khóa định danh và phân loại | TA, DS | M | 002, 003, 004, 005 |
| UC-06-03 | Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain | TA, DS, DA | M | 006 |
| UC-06-04 | Đăng ký nguồn và khai báo ưu tiên nguồn có phê duyệt | TA, DS, DA | M | 008, 009 |
| UC-06-05 | Nạp ứng viên qua API, luồng PH-04 và sự kiện PH-10 | HTTT, PH-04 | M | 010, 011, 012, 016 |
| UC-06-06 | Nạp tệp lô có xem trước | DS | M | 013 |
| UC-06-07 | Chuẩn hóa ứng viên và xử lý ứng viên lỗi | Hệ thống, DS | M | 014, 015, 017 |
| UC-06-08 | Soạn bộ quy tắc đối sánh, khóa gom nhóm và ngưỡng | TA, DS | M | 018, 019, 023 |
| UC-06-09 | Tập nhãn, chạy thử, đánh giá và kích hoạt bộ quy tắc | DS, DA | M | 018, 024, 025, 026 |
| UC-06-10 | Đối sánh tự động và tạo, cập nhật bản ghi vàng | Hệ thống | M | 020, 021, 034 |
| UC-06-11 | Chạy job đối sánh theo lô bằng Splink | TA, TO | M | 022 |
| UC-06-12 | Hàng đợi người quản lý: nhận việc, phân công và theo dõi SLA | DS, DA | M | 027, 028, 032 |
| UC-06-13 | So sánh cạnh nhau và quyết định khớp, không khớp, hoãn | DS | M | 029, 030 |
| UC-06-14 | Duyệt bốn mắt hợp nhất rủi ro cao | DA | M | 031 |
| UC-06-15 | Cấu hình quy tắc sống sót, xem trước tác động và áp lại | TA, DS, DA | M | 033, 042 |
| UC-06-16 | Xem chi tiết bản ghi vàng, lịch sử và nguồn gốc thuộc tính | DS, DA, SO, AU | M | 035, 041, 043 |
| UC-06-17 | Sửa tay thuộc tính, ngừng và khôi phục bản ghi vàng | DS, TA | M | 036, 040 |
| UC-06-18 | Hợp nhất bản ghi vàng thủ công | DS, DA | M | 037 |
| UC-06-19 | Tách bản ghi vàng và gỡ liên kết chéo nguồn | DS, DA | M | 038, 044 |
| UC-06-20 | Hoàn tác thao tác trên bản ghi vàng | DS, DA | M | 039 |
| UC-06-21 | Tra cứu, tra ID nguồn và tìm kiếm bản ghi vàng có che dữ liệu | HTTT, PH-04, DS | M | 045, 046, 048, 052 |
| UC-06-22 | Giải quyết bản ghi trực tuyến (resolve) | HTTT, PH-04 | M | 047 |
| UC-06-23 | Xuất dữ liệu chủ có kiểm soát | DS, DO, DA | M | 049 |
| UC-06-24 | Đăng ký nhận cập nhật và phát sự kiện thay đổi bản ghi vàng | TA, DS, DO | M | 050, 051 |
| UC-06-25 | Đồng bộ với CSDL tổng hợp quốc gia và xử lý danh sách lệch | Hệ thống, DS, DA | M | 053, 054 |
| UC-06-26 | Vận hành: dashboard, lịch job và nhật ký | TO, TA, SO | M | 055, 056, 057 |
| UC-06-27 | Tiếp nhận và xử lý yêu cầu của chủ thể dữ liệu | DS, SO | M | 058 |
| UC-06-28 | Chính sách lưu giữ, dọn dữ liệu và tham số theo tenant | TA | M | 059, 060 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình, API và kiểm thử

Mỗi use case có ít nhất một màn hình hoặc API; UC-06-10 và UC-06-22 là use case máy, không có màn riêng (kết quả xem ở UI-06-11, UI-06-01).

| UC | Màn hình | API |
|---|---|---|
| UC-06-01 | UI-06-07 | API-06-001,002,012 |
| UC-06-02 | UI-06-07 | API-06-003-007, 013 |
| UC-06-03 | UI-06-07 | API-06-008-011 |
| UC-06-04 | UI-06-08 | API-06-014-020 |
| UC-06-05 | UI-06-08, 18 | API-06-016, 021, 022 |
| UC-06-06 | UI-06-11 | API-06-023-025 |
| UC-06-07 | UI-06-11 | API-06-026-029 |
| UC-06-08 | UI-06-09 | API-06-030-032, 036 |
| UC-06-09 | UI-06-09, 13 | API-06-033-035, 037-040 |
| UC-06-10 | Không | API-06-071 (dùng chung logic) |
| UC-06-11 | UI-06-12 | API-06-041-044 |
| UC-06-12 | UI-06-04, 01 | API-06-045, 047, 050 |
| UC-06-13 | UI-06-05 | API-06-046, 048 |
| UC-06-14 | UI-06-05 | API-06-049, 061 |
| UC-06-15 | UI-06-10, 08 | API-06-051-055 |
| UC-06-16 | UI-06-03 | API-06-056, 063-065 |
| UC-06-17 | UI-06-03 | API-06-057, 062 |
| UC-06-18 | UI-06-06, 02 | API-06-058, 061 |
| UC-06-19 | UI-06-06, 03 | API-06-059, 061, 066, 067 |
| UC-06-20 | UI-06-03, 06 | API-06-060, 061 |
| UC-06-21 | UI-06-02, 03 | API-06-056, 068-070, 072 |
| UC-06-22 | Không | API-06-071 |
| UC-06-23 | UI-06-15 | API-06-073-076 |
| UC-06-24 | UI-06-15, 18 | API-06-077-079 |
| UC-06-25 | UI-06-14 | API-06-080-084 |
| UC-06-26 | UI-06-01, 12, 18 | API-06-041, 044, 085-089 |
| UC-06-27 | UI-06-16 | API-06-090-092 |
| UC-06-28 | UI-06-17, 12 | API-06-093-096 |

: Use case, màn hình và API

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

BP-01…09 theo D02-01; BP-10 "Quản lý dữ liệu chủ" là đề nghị bổ sung (FRS Phụ lục B). "—" là năng lực mới, không có ở hệ cũ.

| UC | REQ | BP | Chức năng hệ cũ (LGC) |
|---|---|---|---|
| UC-06-01 | REQ-06 | BP-08 | — |
| UC-06-02 | REQ-06, REQ-09 | BP-10 (đề nghị) | — |
| UC-06-03 | REQ-06 | BP-10 | — |
| UC-06-04 | REQ-06 | BP-01, BP-10 | — (LGC-NGSP-003, 005 là nguồn qua PH-14) |
| UC-06-05 | REQ-06, REQ-04, REQ-10 | BP-04 | — |
| UC-06-06 | REQ-06 | BP-10 | — |
| UC-06-07 | REQ-06, REQ-07 | BP-10 | — (LGC-DMDC-015, 019 là PH-07 cung cấp mã ĐVHC) |
| UC-06-08 | REQ-06 | BP-10 | — |
| UC-06-09 | REQ-06 | BP-10 | — |
| UC-06-10 | REQ-06 | BP-10 | — |
| UC-06-11 | REQ-06 | BP-10 | — |
| UC-06-12 | REQ-06 | BP-10 | — |
| UC-06-13 | REQ-06 | BP-10 | — |
| UC-06-14 | REQ-06 | BP-10 | — |
| UC-06-15 | REQ-06 | BP-10 | — |
| UC-06-16 | REQ-06 | BP-10 | — |
| UC-06-17 | REQ-06 | BP-10 | — |
| UC-06-18 | REQ-06 | BP-10 | — |
| UC-06-19 | REQ-06 | BP-10 | — |
| UC-06-20 | REQ-06 | BP-10 | — |
| UC-06-21 | REQ-06, REQ-09 | BP-10 | — (LGC-NGSP-003 làm chính ở PH-14) |
| UC-06-22 | REQ-06, REQ-09 | BP-04, BP-10 | — |
| UC-06-23 | REQ-06, REQ-09 | BP-10 | — |
| UC-06-24 | REQ-06, REQ-10 | BP-04 | — |
| UC-06-25 | REQ-06, REQ-14 | BP-06 | — (LGC-NGSP-003, 005 liên quan gián tiếp) |
| UC-06-26 | REQ-06, REQ-13, REQ-18 | BP-07 | — |
| UC-06-27 | REQ-06, REQ-09 | BP-10 | — |
| UC-06-28 | REQ-06, REQ-20 | BP-10 | — |

: Use case, REQ, BP và LGC

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực (số đuôi `UC-06-nn`). Không FR nào bị bỏ trống; FR có nhiều use case là FR dùng chung (FR-06-018 ở UC-06-08, 09; FR-06-052 là quy tắc xuyên suốt, hiện thực ở UC-06-21 và LP-06-04).

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 01 | 021 | 10 | 041 | 16 |
| 002 | 02 | 022 | 11 | 042 | 15 |
| 003 | 02 | 023 | 08 | 043 | 16 |
| 004 | 02 | 024 | 09 | 044 | 19 |
| 005 | 02 | 025 | 09 | 045 | 21 |
| 006 | 03 | 026 | 09 | 046 | 21 |
| 007 | 01 | 027 | 12 | 047 | 22 |
| 008 | 04 | 028 | 12 | 048 | 21 |
| 009 | 04 | 029 | 13 | 049 | 23 |
| 010 | 05 | 030 | 13 | 050 | 24 |
| 011 | 05 | 031 | 14 | 051 | 24 |
| 012 | 05 | 032 | 12 | 052 | 21 |
| 013 | 06 | 033 | 15 | 053 | 25 |
| 014 | 07 | 034 | 10 | 054 | 25 |
| 015 | 07 | 035 | 16 | 055 | 26 |
| 016 | 05 | 036 | 17 | 056 | 26 |
| 017 | 07 | 037 | 18 | 057 | 26 |
| 018 | 08, 09 | 038 | 19 | 058 | 27 |
| 019 | 08 | 039 | 20 | 059 | 28 |
| 020 | 10 | 040 | 17 | 060 | 28 |

: Ma trận FR và use case

### 5.5. FR cũ của repo, REQ và LGC liên quan

Bảng ánh xạ FR của SRS cũ (`docs/07-srs/SRS-PH-06-mdm.md`, 13 FR) sang FR mới và use case; mã màn hình, thực thể cũ đổi nghĩa ở bản này (FRS §11.2). Sau đó là kết luận về LGC liên quan gián tiếp.

| FR cũ | Nội dung | FR mới | UC |
|---|---|---|---|
| FR-06-001 cũ | Nạp bản ghi ứng viên | 010-013, 016, 017 | UC-06-05, 06, 07 |
| FR-06-002 cũ | Chuẩn hóa | 014, 015 | UC-06-07 |
| FR-06-003 cũ | Đối sánh xác định | 020 | UC-06-10 |
| FR-06-004 cũ | Đối sánh xác suất, ngưỡng | 018, 019, 021, 023-026 | UC-06-08, 09, 10 |
| FR-06-005 cũ | Hàng đợi người quản lý | 027-032 | UC-06-12, 13, 14 |
| FR-06-006 cũ | Ưu tiên nguồn, sống sót | 008, 009, 033, 042 | UC-06-04, 15 |
| FR-06-007 cũ | Bản ghi vàng, lịch sử | 034, 041 | UC-06-10, 16 |
| FR-06-008 cũ | Hợp nhất, tách | 037, 038 | UC-06-18, 19 |
| FR-06-009 cũ | Nguồn gốc, liên kết nguồn | 043-045 | UC-06-16, 19, 21 |
| FR-06-010 cũ | Hoàn tác | 039 | UC-06-20 |
| FR-06-011 cũ | Đồng bộ quốc gia | 053, 054 | UC-06-25 |
| FR-06-012 cũ | Tra cứu, resolve | 035, 046, 047 | UC-06-16, 21, 22 |
| FR-06-013 cũ | Sự kiện thay đổi | 050, 051 | UC-06-24 |

: Ánh xạ FR cũ của repo sang FR mới và use case

| LGC, REQ | Kết luận | UC |
|---|---|---|
| LGC-NGSP-003 (BHXH hộ gia đình) | Phân hệ dùng dữ liệu, không thay chức năng; PH-14 làm chính, PH-06 nhận làm nguồn dữ liệu công dân | UC-06-04, 21, 25 |
| LGC-NGSP-005 (dữ liệu ĐKKD) | Phân hệ dùng dữ liệu, không thay chức năng; PH-14 làm chính, nguồn cho domain `ORGANIZATION` | UC-06-04, 25 |
| LGC-DMDC-015, 019 (danh mục, ĐVHC) | Phân hệ dùng dữ liệu, không thay chức năng; PH-07 cung cấp mã ĐVHC hiện hành | UC-06-02, 07 |
| REQ-06 | Quản lý dữ liệu chủ dùng chung (công dân, tổ chức, địa chỉ), đối sánh, hợp nhất; thêm REQ-04, 07, 09, 10, 13, 14, 18, 20 ở bảng 5.3 | Cả 28 UC |

: LGC và REQ liên quan

## 6. Đặc tả chi tiết use case

Chương này đặc tả 28 use case theo nhóm vòng đời: cấu hình (UC-06-01…04), nạp (05…07), đối sánh và hàng đợi (08…14), bản ghi vàng (15…20), cung cấp và đồng bộ (21…25), vận hành (26…28). Mỗi use case một khối 15 mục; nhánh thay thế và ngoại lệ chỉ ghi điều khác với FR, hành vi từng bước xem FR tương ứng.

### 6.1. UC-06-01 · Nạp gói domain nền và xem domain

Khi tenant mới được khởi tạo (BP-08), tỉnh có ngay ba domain chuẩn `CITIZEN`, `ORGANIZATION`, `ADDRESS` giống nhau giữa các tỉnh để đối sánh, đồng bộ quốc gia và PH-04 dùng chung một mô hình.

::: dac-ta
**Mục tiêu.** Tenant có ba domain nền ở trạng thái `ACTIVE` kèm mô hình, khóa định danh, bộ quy tắc mặc định; người dùng xem được danh sách domain và phiên bản mô hình hiện hành.

**Tác nhân chính.** PA, ROLE-PLATFORM_ADMIN (Hà).

**Tác nhân phụ.** PH-20 (sự kiện khởi tạo tenant), PH-07 (danh mục nền), DS, TA, HTTT (đọc lược đồ).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-001, FR-06-007.

**Truy vết.** REQ-06; BP-08 (khởi tạo tenant), BP-10 đề nghị; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Tenant `T68` `ACTIVE`; PH-07 đã nạp ĐVHC, giới tính, dân tộc, quốc tịch; Hà có `PERM-06-config` gói `COMMON`.

**Kích hoạt.** Sự kiện khởi tạo tenant của PH-20, hoặc Hà bấm "Nạp gói nền" ở UI-06-07.

**Đảm bảo tối thiểu.** Không domain nào nạp dở: lỗi ở domain nào thì domain đó không xuất hiện, các domain đã nạp giữ nguyên.

**Đảm bảo thành công.** Ba domain `ACTIVE`, mỗi domain một phiên bản mô hình `ACTIVE`; phát EVT-06-10 cho từng domain.

**Luồng chính.**
1. Hà mở UI-06-07, bấm "Nạp gói nền". Hệ thống gọi API-06-012 kèm `Idempotency-Key`.
2. Hệ thống kiểm tra danh mục tham chiếu ở PH-07 (ĐVHC, giới tính, dân tộc, quốc tịch).
3. Hệ thống tạo `CITIZEN`, `ORGANIZATION`, `ADDRESS` với phiên bản mô hình 1, khóa định danh `CCCD_12` (`CITIZEN`), `MST_10_13` (`ORGANIZATION`), bộ quy tắc mặc định.
4. Hệ thống đặt mô hình `ACTIVE`, phát EVT-06-10, ghi kiểm toán.
5. Lan mở UI-06-07; hệ thống gọi API-06-001, hiện cây domain kèm số bản ghi vàng; Lan chọn `CITIZEN` (API-06-002) xem thuộc tính, khóa, phân loại.

**Luồng thay thế.**
- **1a. Khởi tạo tự động.** PH-20 phát sự kiện, hệ thống chạy bước 2 đến 4 không cần thao tác.
- **5a. Xem phiên bản cũ.** Lan chọn phiên bản `SUPERSEDED`, giao diện gắn nhãn "Đã thay thế".
- **1b. Nạp lại domain đã ngừng.** Tạo phiên bản mới `DRAFT`, đi qua UC-06-03.

**Luồng ngoại lệ.**
- **E1. Thiếu danh mục ở PH-07 (bước 2).** ERR-06-003 (400): "Thiếu danh mục {mã} ở PH-07. Nạp gói danh mục nền trước."
- **E2. Gói nền không tồn tại (bước 1).** ERR-06-001 (404): "Không có gói domain nền phiên bản {n}."
- **E3. Domain không có hoặc thuộc tenant khác (bước 5).** ERR-06-001 (404): "Không tìm thấy domain {mã} trong tỉnh đang làm việc."
- **E4. Tham số lọc sai (bước 5).** ERR-06-047 (422): "Tham số {tên} không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-06-016, BR-06-017.

**Màn hình, API.** UI-06-07; API-06-001, 002, 012; kịch bản TS-06-01.
:::

### 6.2. UC-06-02 · Soạn mô hình domain, khóa định danh và phân loại

Tỉnh thêm thuộc tính địa phương (ví dụ `ethnicity`, `occupation`) hoặc tạo domain mới mà không sửa mã. Mọi thay đổi đi qua một bản nháp; bản `ACTIVE` không sửa trực tiếp (BR-06-017).

::: dac-ta
**Mục tiêu.** Có bản nháp mô hình hợp lệ: thuộc tính có kiểu, khóa định danh kèm kiểm tra, phân loại PH-09 cho từng thuộc tính, và biết rõ khác biệt, mức tương thích so với bản `ACTIVE`.

**Tác nhân chính.** TA (Mai), DS (Lan).

**Tác nhân phụ.** PH-09 (phân loại), PH-07 (danh mục tham chiếu).

**Mức ưu tiên.** M · Đợt 3 (FR-06-005 mức S).

**FR hiện thực.** FR-06-002, FR-06-003, FR-06-004, FR-06-005.

**Truy vết.** REQ-06, REQ-09; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-06-config`; domain chưa có bản nháp khác.

**Kích hoạt.** Mai bấm "Tạo bản nháp" từ phiên bản `ACTIVE` hoặc "+ Domain mới" ở UI-06-07.

**Đảm bảo tối thiểu.** Phiên bản `ACTIVE` không đổi; nháp lưu được dù chưa đầy đủ.

**Đảm bảo thành công.** Bản nháp `DRAFT` qua kiểm tra, sẵn sàng gửi duyệt (UC-06-03).

**Luồng chính.**
1. Mai tạo nháp phiên bản 2 của `CITIZEN` (API-06-005); hệ thống chép từ phiên bản 1.
2. Mai thêm thuộc tính `ethnicity` kiểu `CODE_REF` trỏ danh mục dân tộc PH-07, đặt đa trị, `matchable = false`. Hệ thống lưu qua API-06-006.
3. Mai mở tab "Khóa định danh", đặt `CCCD_12` làm khóa `deterministic = true` và bấm "Thử kiểm tra" với `001090012345` (API-06-013); hệ thống trả `VALID`; thử `001090012346` trả `INVALID_CHECKSUM`.
4. Mai mở cột "Phân loại", đề xuất `DataClass` `RESTRICTED` cho `ethnicity`; trạng thái `PROPOSED`. PH-09 xác nhận thì thành `CONFIRMED`.
5. Mai chọn hai phiên bản, bấm "So sánh" (API-06-007). Hệ thống hiện khác biệt và `CompatLevel`: thêm thuộc tính không bắt buộc là `NON_BREAKING`.
6. Hệ thống đánh dấu nháp sẵn sàng gửi duyệt khi mọi thuộc tính DLCN đã `CONFIRMED`.

**Luồng thay thế.**
- **2a. Ẩn thay vì xóa.** Thuộc tính đã có dữ liệu chỉ ẩn (`hidden = true`); xóa thật chỉ với thuộc tính mới thêm trong nháp.
- **3a. Khóa không xác định.** Mã BHXH `deterministic = false` chỉ là thuộc tính so sánh trọng số cao.
- **4a. PH-09 đổi phân loại sau kích hoạt.** PH-06 nhận sự kiện và áp ngay cho che, nhật ký; nâng lên `SENSITIVE` khởi động job mã hóa lại (`REENCRYPT`).

**Luồng ngoại lệ.**
- **E1. Tên thuộc tính trùng (bước 2).** ERR-06-002 (409): "Thuộc tính {tên} đã có trong domain."
- **E2. Danh mục chưa phát hành (bước 2).** ERR-06-003 (400): "Danh mục {mã} chưa phát hành ở PH-07."
- **E3. Khóa không phải kiểu `IDENTIFIER` (bước 3).** ERR-06-009 (422): "Thuộc tính {tên} phải có kiểu Định danh để làm khóa."
- **E4. Biểu thức kiểm tra không an toàn (bước 3).** ERR-06-003 (400): "Biểu thức kiểm tra không hợp lệ hoặc có nguy cơ chạy quá lâu."
- **E5. Thiếu khóa và tổ hợp đối sánh (bước 6).** ERR-06-009 (422): "Domain cần ít nhất một khóa định danh hoặc ba thuộc tính dùng được cho đối sánh."
- **E6. Thuộc tính DLCN chưa phân loại (bước 6).** ERR-06-010 (422): "Thuộc tính {tên} là dữ liệu cá nhân nhưng chưa có phân loại được PH-09 xác nhận."
- **E7. Đã có nháp khác hoặc sửa đồng thời (bước 1, 2).** ERR-06-006 (409): "Domain {mã} đang có bản nháp phiên bản {n} do {người} tạo."; ERR-06-004 (409): "Bản nháp đã được người khác sửa. Tải lại để xem thay đổi."
- **E8. PH-09 không khả dụng (bước 4).** ERR-06-021 (503): "Chưa kết nối được phân hệ Quyền riêng tư. Lưu nháp được, gửi duyệt sau."

**Quy tắc áp dụng.** BR-06-001, BR-06-016, BR-06-017.

**Màn hình, API.** UI-06-07; API-06-003, 004, 005, 006, 007, 013; kịch bản TS-06-02.
:::

### 6.3. UC-06-03 · Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain

Điểm kiểm soát bốn mắt đầu tiên của phân hệ: mô hình chỉ có hiệu lực khi người thứ hai (DA) duyệt (LP-06-01).

::: dac-ta
**Mục tiêu.** Đưa phiên bản mô hình vào dùng sau khi DA khác người gửi duyệt; tạm ngừng hoặc ngừng domain khi tỉnh không còn quản lý.

**Tác nhân chính.** TA, DS (gửi duyệt); DA (Hùng) duyệt.

**Tác nhân phụ.** PH-09 (kiểm lại phân loại), PH-04 và HTTT nguồn (nhận EVT-06-10).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-006.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Nháp qua kiểm tra UC-06-02; domain `ACTIVE` hoặc `DRAFT` (domain mới); người duyệt có `PERM-06-approve`.

**Kích hoạt.** Mai bấm "Gửi duyệt" ở UI-06-07; Hùng nhận việc ở "Việc của tôi" (FR-00-070).

**Đảm bảo tối thiểu.** Phiên bản `ACTIVE` đang chạy không đổi cho tới khi duyệt xong.

**Đảm bảo thành công.** Phiên bản mới `ACTIVE`, phiên bản cũ `SUPERSEDED`; phát EVT-06-10.

**Luồng chính.**
1. Mai bấm "Gửi duyệt" (API-06-008); hệ thống kiểm phân loại PH-09 lần cuối, đặt `PENDING_APPROVAL`.
2. Hùng mở việc, xem khác biệt và `CompatLevel` (UC-06-02 bước 5).
3. Hùng chọn "Duyệt" (API-06-009); hệ thống kiểm Hùng khác Mai (LP-06-01).
4. Hệ thống đặt phiên bản `ACTIVE`, phiên bản trước `SUPERSEDED`, phát EVT-06-10, báo Mai.
5. Khi thay đổi `BREAKING`, hệ thống gợi ý tạo job áp lại (UC-06-15) trước khi áp.

**Luồng thay thế.**
- **3a. Từ chối.** Hùng chọn "Từ chối" (API-06-010) kèm lý do ≥ 20 ký tự; phiên bản `REJECTED`, Mai sửa lại về `DRAFT`.
- **1a. Tạm ngừng, tiếp tục, ngừng domain.** TA gọi API-06-011; ngừng chỉ khi không còn bản ghi vàng hoạt động.

**Luồng ngoại lệ.**
- **E1. Hùng là người gửi duyệt (bước 3).** ERR-06-005 (403): "Anh/chị là người gửi duyệt nên không được tự duyệt."
- **E2. Từ chối không lý do (3a).** ERR-06-007 (422): "Nhập lý do từ chối (tối thiểu 20 ký tự)."
- **E3. Ngừng domain còn bản ghi vàng (1a).** ERR-06-011 (422): "Domain còn {n} bản ghi vàng đang hoạt động, không ngừng được."
- **E4. Trạng thái không cho thao tác (bước 1, 3).** ERR-06-006 (409): "Phiên bản đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."
- **E5. Thuộc tính DLCN chưa phân loại (bước 1).** ERR-06-010 (422); câu như UC-06-02 E6.

**Quy tắc áp dụng.** BR-06-016, BR-06-017.

**Màn hình, API.** UI-06-07; API-06-008, 009, 010, 011; kịch bản TS-06-03.
:::

### 6.4. UC-06-04 · Đăng ký nguồn và khai báo ưu tiên nguồn có phê duyệt

Thứ tự "nguồn nào thắng khi mâu thuẫn" là quyết định quản lý có căn cứ văn bản, không phải của đội kỹ thuật (BR-06-004). CSDL quốc gia luôn mức 1 với thuộc tính thẩm quyền quốc gia (BR-06-003).

::: dac-ta
**Mục tiêu.** HTTT được đăng ký làm nguồn cho domain với mức tin cậy 1 đến 5 và thứ tự ưu tiên được duyệt, có số, ngày văn bản căn cứ.

**Tác nhân chính.** TA, DS (Lan) đề nghị; DA (Hùng) duyệt.

**Tác nhân phụ.** PH-01 (trạng thái HTTT), PH-14 (nguồn quốc gia), PH-04, PH-10.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-008, FR-06-009.

**Truy vết.** REQ-06; BP-01 (HTTT đã kết nạp mới đăng ký được), BP-10 đề nghị; hệ cũ: không có (LGC-NGSP-003, 005 là nguồn qua PH-14, §5.3).

**Tiền điều kiện.** HTTT `ACTIVE` ở PH-01 (trừ `NATIONAL_DB`, `MANUAL_ENTRY`); domain `ACTIVE`; Lan có `PERM-06-config`.

**Kích hoạt.** Lan bấm "+ Thêm nguồn" ở UI-06-08.

**Đảm bảo tối thiểu.** Không nguồn nào gửi được dữ liệu khi chưa `ACTIVE`; ưu tiên cũ giữ cho tới khi duyệt.

**Đảm bảo thành công.** Nguồn `ACTIVE` kèm kênh nạp; bảng ưu tiên mới có hiệu lực, job áp lại sống sót được tạo (UC-06-15).

**Luồng chính.**
1. Lan chọn HTTT `HT-HOTICH`, domain `CITIZEN`, `SourceKind = SECTOR_AUTHORITATIVE`, kênh `EVENT`, mức tin cậy 4; gửi API-06-015. Hệ thống kiểm HTTT `ACTIVE` và tạo nguồn `DRAFT`.
2. Lan kích hoạt nguồn; hệ thống đặt `ACTIVE`, ghi kiểm toán.
3. Lan mở tab "Ưu tiên nguồn" (API-06-018), kéo `HT-HOTICH` lên trên `HT-GIAODUC` cho thuộc tính `fullName`, nhập căn cứ "Quyết định 123/QĐ-UBND ngày 05/11/2026" và bấm "Đề nghị áp dụng" (API-06-019).
4. Hùng duyệt (API-06-020); hệ thống kiểm Hùng khác Lan.
5. Hệ thống áp bảng ưu tiên mới, hiện "Xem trước tác động" và đề nghị job áp lại.

**Luồng thay thế.**
- **2a. Tạm ngừng, tiếp tục, ngừng nguồn (API-06-017).** Ngừng không xóa liên kết; liên kết giữ `ACTIVE` nhưng không nhận cập nhật.
- **3a. Nguồn mới chưa có mức.** Dùng mức thấp nhất của loại nguồn kèm cảnh báo "chưa có ưu tiên được duyệt".
- **4a. Từ chối.** Hùng từ chối kèm lý do; bảng cũ giữ.

**Luồng ngoại lệ.**
- **E1. HTTT chưa `ACTIVE` (bước 1).** ERR-06-012 (422): "HTTT {mã} chưa ở trạng thái hoạt động trong danh mục HTTT."
- **E2. Mã nguồn trùng (bước 1).** ERR-06-002 (409): "Mã nguồn {mã} đã được dùng."
- **E3. Domain chưa `ACTIVE` (bước 1).** ERR-06-006 (409): "Domain {mã} chưa được kích hoạt."
- **E4. Thiếu căn cứ (bước 3).** ERR-06-013 (422): "Nhập số, ngày văn bản phê duyệt thứ tự ưu tiên nguồn."
- **E5. Hạ nguồn quốc gia khỏi mức 1 ở thuộc tính thẩm quyền (bước 3).** ERR-06-035 (422): "Thuộc tính {tên} thuộc thẩm quyền CSDL quốc gia, nguồn quốc gia phải ở mức 1."
- **E6. Tự duyệt (bước 4).** ERR-06-005 (403): "Anh/chị là người đề nghị nên không được tự duyệt."

**Quy tắc áp dụng.** BR-06-003, BR-06-004, BR-06-032.

**Màn hình, API.** UI-06-08; API-06-014…020; kịch bản TS-06-04.
:::

### 6.5. UC-06-05 · Nạp ứng viên qua API, luồng PH-04 và sự kiện PH-10

Ba kênh tự động cùng đi qua kiểm tra nguồn, lược đồ và chống trùng; chỉ khác cách bản ghi tới. Hệ không thể gọi API (SOAP, CSDL) dùng luồng PH-04; hệ đã phát sự kiện nghiệp vụ dùng PH-10.

::: dac-ta
**Mục tiêu.** Bản ghi từ nguồn đã đăng ký được nhận một lần, đúng thứ tự phiên bản, và sẵn sàng chuẩn hóa; gửi lại không tạo trùng.

**Tác nhân chính.** HTTT nguồn (`mdm:ingest`).

**Tác nhân phụ.** Luồng PH-04 `dh-runtime`, PH-10 (topic nguồn), `dh-data`.

**Mức ưu tiên.** M · Đợt 3 (FR-06-012 mức S).

**FR hiện thực.** FR-06-010, FR-06-011, FR-06-012, FR-06-016.

**Truy vết.** REQ-06, REQ-04, REQ-10; BP-04 (tiêu thụ sự kiện nguồn); hệ cũ: không có.

**Tiền điều kiện.** Nguồn `ACTIVE` có kênh tương ứng (`API`, `FLOW`, `EVENT`) cho domain; domain `ACTIVE`.

**Kích hoạt.** HTTT gọi API-06-021; hoặc luồng PH-04 gọi API-06-022; hoặc sự kiện đến topic nguồn.

**Đảm bảo tối thiểu.** Không mất bản tin: lỗi thì trả lỗi hoặc vào DLQ; mỗi `(sourceCode, sourceKey, sourceVersion)` xử lý một lần (BR-06-028).

**Đảm bảo thành công.** Ứng viên `RECEIVED` (hoặc `DUPLICATE`, `SUPERSEDED`); phát EVT-06-07 dạng gộp.

**Luồng chính.**
1. `HT-HOTICH` gửi `POST /domains/CITIZEN/candidates` (API-06-021) kèm `Idempotency-Key`, `operation = UPDATE`, `sourceKey = KS-2026-00871`, `sourceVersion`.
2. Hệ thống kiểm token khớp nguồn đã đăng ký `ACTIVE` cho domain.
3. Hệ thống kiểm lược đồ domain và `sourceKey` bắt buộc.
4. Hệ thống chống trùng: `(sourceCode, sourceKey, sourceVersion)` đã có thì `DUPLICATE`; phiên bản nhỏ hơn bản đã nhận thì `SUPERSEDED`, không ghi đè (BR-06-029).
5. Hệ thống lưu ứng viên `RECEIVED` (trường DLCN mã hóa envelope) và trả `202` kèm danh sách `candidateId`.
6. Hệ thống phát EVT-06-07 và chuyển ứng viên sang chuẩn hóa (UC-06-07).

**Luồng thay thế.**
- **1a. Luồng PH-04.** Bước `dh-mdm-ingest-sink` gửi lô 500 bản qua API-06-022; khi PH-06 trả `429` luồng giãn theo `Retry-After`; PH-06 không khả dụng thì luồng thử lại, bản tin vào DLQ PH-04.
- **1b. Sự kiện PH-10.** `dh-data` nhận sự kiện `t68.hotich.khai-sinh.registered.v1`, dựng bản ghi theo ánh xạ trường đã khai báo ở nguồn (API-06-016); loại sự kiện trong `deleteEventTypes` thành `operation = DELETE`.
- **4a. Nguồn xóa bản ghi.** `DELETE` chuyển liên kết sang `DETACHED` (`SOURCE_DELETED`); bản ghi vàng không bị xóa, nếu hết liên kết thì vào hàng đợi `ORPHANED`.
- **4b. Nguồn không có số phiên bản.** Dùng `sourceUpdatedAt`; trùng thời điểm thì so băm nội dung.

**Luồng ngoại lệ.**
- **E1. Bên gửi không phải nguồn đăng ký (bước 2).** ERR-06-014 (403): "Hệ thống {mã} chưa được đăng ký làm nguồn cho domain {domain}."
- **E2. Thiếu `sourceKey` (bước 3).** ERR-06-016 (422): "Bản ghi thiếu sourceKey nên không truy vết ngược được."
- **E3. Sai lược đồ (bước 3).** ERR-06-017 (422): "Bản ghi không đúng mô hình {domain} phiên bản {n}: {danh sách trường}."; kênh sự kiện: ERR-06-110, bản tin vào DLQ PH-10.
- **E4. Lô quá lớn (bước 1).** ERR-06-018 (413): "Mỗi lần gửi tối đa 500 bản ghi."
- **E5. Vượt hạn mức (bước 1).** ERR-06-048 (429): "Vượt hạn mức {n} bản ghi mỗi phút của nguồn. Thử lại sau {giây} giây."
- **E6. `Idempotency-Key` dùng lại với nội dung khác (bước 1).** ERR-06-015 (409): "Idempotency-Key {khóa} đã dùng cho nội dung khác trong 24 giờ."
- **E7. Luồng không khớp nguồn (1a).** ERR-06-014, hiển thị ở nhật ký luồng PH-04: "Luồng {mã} không được gửi dữ liệu thay nguồn {nguồn}."

**Quy tắc áp dụng.** BR-06-018, BR-06-028, BR-06-029.

**Màn hình, API.** Không có màn riêng (cấu hình kênh ở UI-06-08, lỗi ở UI-06-18); API-06-016, 021, 022; kịch bản TS-06-05.
:::

### 6.6. UC-06-06 · Nạp tệp lô có xem trước

Dành cho dữ liệu lịch sử hoặc đơn vị chưa có kết nối. Tệp chứa DLCN nên được quét mã độc, từ chối công thức, macro và báo lỗi theo dòng trước khi ghi.

::: dac-ta
**Mục tiêu.** DS nạp một tệp Excel hoặc CSV vào danh sách ứng viên, thấy trước lỗi từng dòng và chỉ ghi khi đồng ý.

**Tác nhân chính.** DS (Lan), TA.

**Tác nhân phụ.** Kho đối tượng, dịch vụ quét mã độc, PH-07.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-013.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-ingest`; nguồn `FILE-XA-00004` `ACTIVE` kênh `FILE`.

**Kích hoạt.** Lan bấm "Nhập tệp" ở UI-06-11.

**Đảm bảo tối thiểu.** Chưa xác nhận thì không ứng viên nào được ghi; chế độ mặc định "tất cả hoặc không".

**Đảm bảo thành công.** Các dòng hợp lệ thành ứng viên `RECEIVED` kèm báo cáo lỗi; phát EVT-06-07.

**Luồng chính.**
1. Lan tải tệp mẫu của domain `CITIZEN`, điền 12.000 dòng và tải lên (API-06-023).
2. Hệ thống quét mã độc, kiểm khuôn mẫu và cột, từ chối công thức, macro.
3. Hệ thống kiểm từng dòng theo lược đồ (cảnh báo chuẩn hóa nếu có) và trả báo cáo xem trước: tổng, hợp lệ, lỗi theo dòng (API-06-025).
4. Lan xem lỗi, chọn "Tất cả hoặc không" và bấm "Xác nhận" (API-06-024).
5. Hệ thống ghi ứng viên theo kênh `FILE`, áp chống trùng (UC-06-05 bước 4), phát EVT-06-07.

**Luồng thay thế.**
- **4a. "Chỉ nạp dòng hợp lệ".** Lan chọn chế độ này; dòng lỗi nằm lại trong báo cáo tải về (che DLCN).

**Luồng ngoại lệ.**
- **E1. Tệp quá lớn (bước 1).** ERR-06-018 (413): "Tệp vượt 50 MB hoặc 200.000 dòng. Chia tệp nhỏ hơn."
- **E2. Sai khuôn (bước 2).** ERR-06-019 (422): "Tệp không đúng khuôn mẫu của domain {mã}: thiếu cột {cột}."
- **E3. Có công thức, macro (bước 2).** ERR-06-019 (422): "Tệp chứa công thức hoặc macro. Lưu lại dạng giá trị rồi tải lên."
- **E4. Dòng sai lược đồ (bước 3).** ERR-06-017 (422): "Bản ghi không đúng mô hình {domain} phiên bản {n}: {danh sách trường}."

**Quy tắc áp dụng.** BR-06-015, BR-06-028.

**Màn hình, API.** UI-06-11; API-06-023, 024, 025; kịch bản TS-06-06.
:::

### 6.7. UC-06-07 · Chuẩn hóa ứng viên và xử lý ứng viên lỗi

Hệ thống đưa giá trị về dạng chuẩn (tên Việt có và không dấu, ngày ISO 8601, số định danh đã kiểm, địa chỉ theo ĐVHC hiện hành của PH-07); DS xem ứng viên đang ở bước nào, vì sao bị từ chối và xử lý lại.

::: dac-ta
**Mục tiêu.** Mọi ứng viên có dạng chuẩn để đối sánh chính xác; ứng viên lỗi được tìm ra nguyên nhân và xử lý lại hoặc loại bỏ có lý do.

**Tác nhân chính.** Hệ thống `mdm-normalize`; DS (Lan) xử lý ứng viên lỗi.

**Tác nhân phụ.** PH-07 (ĐVHC, danh mục), TO (xem), TA.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-014, FR-06-015, FR-06-017.

**Truy vết.** REQ-06, REQ-07; BP-10 đề nghị; hệ cũ: không có; LGC-DMDC-015, 019 (PH-07 cung cấp mã ĐVHC, §5.3).

**Tiền điều kiện.** Ứng viên `RECEIVED`; xem cần `PERM-06-read`, xử lý lại và loại bỏ cần `PERM-06-ingest`.

**Kích hoạt.** Ứng viên mới; hoặc Lan mở tab "Ứng viên" ở UI-06-11; hoặc nút "Xem trước chuẩn hóa" (API-06-029).

**Đảm bảo tối thiểu.** Ứng viên không mất; thiếu PH-07 thì giữ `NORMALIZATION_PENDING` và tự thử lại.

**Đảm bảo thành công.** Ứng viên `NORMALIZED` kèm cảnh báo `NormalizationWarning`, hoặc `DISCARDED` có lý do.

**Luồng chính.**
1. Hệ thống chuẩn hóa họ tên ("Nguyễn Văn A" thành `nameAscii` "nguyen van a"), ngày về ISO 8601 kèm `DatePrecision`, số định danh về `IdentifierStatus` (`VALID`, `INVALID_CHECKSUM`, `PLACEHOLDER`, `MISSING`).
2. Hệ thống chuẩn hóa địa chỉ về mã ĐVHC hiện hành (mã cũ chuyển qua PH-07, giữ `legacyAdminUnitCode`).
3. Hệ thống đặt `NORMALIZED`, ghi cảnh báo nếu có, chuyển đối sánh (UC-06-10).
4. Lan lọc tab "Ứng viên" theo `REJECTED` hoặc cảnh báo, mở ứng viên (API-06-026, 027); giá trị DLCN che.
5. Sau khi nguồn sửa, Lan bấm "Xử lý lại" (API-06-028 `:reprocess`); ứng viên quay về chuẩn hóa.

**Luồng thay thế.**
- **1a. Domain `ORGANIZATION`.** Tên bỏ tiền tố loại hình (`Công ty TNHH`) vào `orgFormToken` để so phần lõi.
- **2a. Mã ĐVHC tách thành nhiều xã mới.** Không tự chọn; giữ mã cũ, cảnh báo `ADMIN_UNIT_SPLIT`, đối sánh dùng cấp tỉnh.
- **4a. Tải báo cáo lỗi theo nguồn (CSV, che DLCN)** để gửi đơn vị chủ quản sửa tại nguồn (BR-06-014).
- **5a. Loại bỏ.** Lan chọn `:discard` kèm lý do ≥ 20 ký tự; ứng viên `DISCARDED`.

**Luồng ngoại lệ.**
- **E1. Số định danh sai kiểm tra (bước 1).** Không lỗi; cảnh báo `IDENTIFIER_INVALID` ở UI-06-11: "Số định danh {3 số cuối} không đúng quy tắc, không dùng làm khóa."
- **E2. Mã ĐVHC không tồn tại (bước 2).** ERR-06-020, cảnh báo trên ứng viên: "Mã ĐVHC {mã} không có trong danh mục tại ngày {ngày}."
- **E3. PH-07 không khả dụng (bước 2).** ERR-06-021 (503); ứng viên `NORMALIZATION_PENDING`, thử lại mỗi 5 phút tối đa 24 giờ; vận hành thấy ở UI-06-01: "Chuẩn hóa địa chỉ đang chờ phân hệ Danh mục: {n} bản ghi."
- **E4. Ứng viên không xử lý lại được (bước 5).** ERR-06-006 (409): "Ứng viên {id} đang ở trạng thái {trạng thái}, không xử lý lại được."
- **E5. Thiếu lý do loại bỏ (5a).** ERR-06-007 (422): "Nhập lý do loại bỏ (tối thiểu 20 ký tự)."

**Quy tắc áp dụng.** BR-06-001, BR-06-008, BR-06-015, BR-06-033.

**Màn hình, API.** UI-06-11; API-06-026, 027, 028, 029; kịch bản TS-06-07.
:::

### 6.8. UC-06-08 · Soạn bộ quy tắc đối sánh, khóa gom nhóm và ngưỡng

Bộ quy tắc là cấu hình có phiên bản, không sửa mã. Ba ranh giới `MATCH`, `POSSIBLE_MATCH`, `NO_MATCH` quyết định cân bằng giữa rủi ro hợp nhất sai và khối lượng việc của người.

::: dac-ta
**Mục tiêu.** Có bộ quy tắc nháp hợp lệ gồm quy tắc xác định, xác suất, loại trừ, khóa gom nhóm và ngưỡng, sẵn sàng chạy thử và đánh giá (UC-06-09).

**Tác nhân chính.** TA, DS (Lan).

**Tác nhân phụ.** Job Splink (huấn luyện m, u), DA.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-018, FR-06-019, FR-06-023.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-config`; domain `ACTIVE`; không sửa được bộ quy tắc `ACTIVE`.

**Kích hoạt.** Lan bấm "Tạo phiên bản mới" ở UI-06-09.

**Đảm bảo tối thiểu.** Bộ quy tắc `ACTIVE` đang chạy không đổi.

**Đảm bảo thành công.** Bộ quy tắc `DRAFT` hợp lệ (API-06-031, 032).

**Luồng chính.**
1. Lan tạo nháp từ bộ `ACTIVE` hoặc bộ mặc định của gói nền (API-06-031).
2. Lan thêm quy tắc xác suất: `fullName` so `JARO_WINKLER`, `dateOfBirth` so `DATE_TOLERANCE`, `permanentAddress` so `ADMIN_UNIT`, kèm trọng số; thêm quy tắc loại trừ "hai CCCD khác nhau" (`EXCLUSION`).
3. Lan khai báo khóa gom nhóm (ví dụ `nameAscii` rút gọn + năm sinh); thuộc tính nhạy cảm chỉ dùng `hmac()`. Hệ thống trả thống kê khối (API-06-036).
4. Lan đặt `autoMergeThreshold = 0,92`, `reviewThreshold = 0,80` trên thanh trượt kèm biểu đồ phân bố điểm.
5. Hệ thống lưu qua API-06-032, kiểm cú pháp, miền ngưỡng; Lan chuyển sang UC-06-09 để chạy thử, đánh giá.

**Luồng thay thế.**
- **2a. Chế độ tham số Splink.** Thay trọng số tay bằng m, u huấn luyện từ job `BATCH_MATCH` `trainOnly = true` (UC-06-11).
- **3a. Khối quá lớn (> 2.000 bản ghi).** Đối sánh trực tuyến chỉ lấy 200 ứng viên giống nhất theo `pg_trgm`, ghi `mdm_block_truncated_total`.
- **4a. `autoMergeEnabled = false`.** Mọi `MATCH` xác suất thành `POSSIBLE_MATCH`; xác định vẫn tự liên kết.

**Luồng ngoại lệ.**
- **E1. Quy tắc hoặc khóa gom nhóm sai (bước 2, 3).** ERR-06-022 (422): "Bộ quy tắc không hợp lệ: {chi tiết}."; "Khóa gom nhóm {biểu thức} không hợp lệ: thuộc tính nhạy cảm phải dùng hmac()."
- **E2. Ngưỡng ngoài miền (bước 4).** ERR-06-023 (422): "Ngưỡng tự hợp nhất phải từ 0,90 trở lên và cao hơn ngưỡng xem xét ít nhất 0,10."
- **E3. Sửa đồng thời.** ERR-06-004 (409): "Bản nháp đã được người khác sửa. Tải lại để xem thay đổi."

**Quy tắc áp dụng.** BR-06-001, BR-06-006, BR-06-016, BR-06-020.

**Màn hình, API.** UI-06-09; API-06-030, 031, 032, 036; kịch bản TS-06-08.
:::

### 6.9. UC-06-09 · Tập nhãn, chạy thử, đánh giá và kích hoạt bộ quy tắc

Bộ quy tắc chỉ kích hoạt khi đánh giá trên tập nhãn khóa ≥ 1.000 cặp đạt precision ≥ 99,9% và recall ≥ 98% (BR-06-021); đây là chốt chặn chất lượng của cả phân hệ.

::: dac-ta
**Mục tiêu.** Biết khách quan bộ quy tắc nháp xử lý dữ liệu thật ra sao và chỉ đưa vào dùng bản đạt chuẩn, có DA duyệt.

**Tác nhân chính.** DS (Lan), TA; DA (Hùng) duyệt.

**Tác nhân phụ.** Job K8s `mdm-splink`, PH-13 (EVT-06-11).

**Mức ưu tiên.** M · Đợt 3 (FR-06-024 mức S).

**FR hiện thực.** FR-06-018, FR-06-024, FR-06-025, FR-06-026.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Bộ quy tắc `DRAFT` hoặc `TESTING`; domain `ACTIVE`.

**Kích hoạt.** "Chạy thử" hoặc "Đánh giá" ở UI-06-09; tạo tập nhãn ở UI-06-13.

**Đảm bảo tối thiểu.** Chạy thử, đánh giá không đổi bản ghi vàng nào.

**Đảm bảo thành công.** Bản đạt chuẩn sang `ACTIVE`, bản cũ `SUPERSEDED`, phát EVT-06-11; bản không đạt bị chặn gửi duyệt.

**Luồng chính.**
1. Lan tạo tập nhãn `EVALUATION` (API-06-038) và thêm cặp `MATCH`, `NO_MATCH` do người gán (API-06-039); khóa tập khi đủ 1.000 cặp.
2. Lan bấm "Chạy thử" với mẫu 10.000 (API-06-033); hệ thống chạy job `RULE_DRY_RUN`, báo số cặp mỗi vùng, mẫu cặp đổi kết luận so với bản `ACTIVE`.
3. Lan bấm "Đánh giá" (API-06-034); job `ACCURACY_EVAL` tính precision, recall, danh sách FP, FN (API-06-040).
4. Bản đạt: Lan bấm "Gửi duyệt" (API-06-035); bộ quy tắc sang `PENDING_APPROVAL`.
5. Hùng duyệt (LP-06-01); hệ thống đặt `ACTIVE`, phát EVT-06-11.

**Luồng thay thế.**
- **2a. Mẫu `QUEUE_HISTORY`.** Dùng cặp đã có quyết định thủ công, cho biết bộ mới đồng ý với người bao nhiêu phần trăm.
- **4a. Đánh giá hằng tháng không đạt.** Với `06.match.auto-disable-on-fail = true` hệ thống tắt tự hợp nhất, cảnh báo ở UI-06-01.
- **5a. Từ chối.** Hùng từ chối kèm lý do; bộ về `DRAFT`.

**Luồng ngoại lệ.**
- **E1. Tập nhãn nhỏ (bước 3).** ERR-06-026 (422): "Tập nhãn cần tối thiểu 1.000 cặp, hiện có {n}."
- **E2. Gửi duyệt khi chưa đạt (bước 4).** ERR-06-024 (422): "Phiên bản {n} chưa đạt: precision {p}%, recall {r}%."
- **E3. Mẫu ngoài miền (bước 2).** ERR-06-047 (422): "Cỡ mẫu phải từ 1.000 đến 100.000."
- **E4. Đang có job cùng loại (bước 2, 3).** ERR-06-025 (409): "Domain {mã} đang có job {jobId} chạy."
- **E5. Tập đã khóa hoặc mã trùng (bước 1).** ERR-06-006 (409): "Tập nhãn {mã} đã khóa. Tạo phiên bản mới để thêm cặp."; ERR-06-002 (409): "Mã tập nhãn {mã} đã được dùng."
- **E6. Tự duyệt (bước 5).** ERR-06-005 (403): "Anh/chị là người gửi duyệt nên không được tự duyệt."

**Quy tắc áp dụng.** BR-06-004, BR-06-021.

**Màn hình, API.** UI-06-09, UI-06-13; API-06-033, 034, 035, 037, 038, 039, 040; kịch bản TS-06-09.
:::

### 6.10. UC-06-10 · Đối sánh tự động và tạo, cập nhật bản ghi vàng

Đây là lõi của phân hệ, chạy không có người. Khóa định danh hợp lệ cho kết luận chắc chắn; không có khóa thì chấm điểm xác suất bằng `pg_trgm`. Kết quả chia ba vùng; chỉ vùng chắc chắn tự ghi.

::: dac-ta
**Mục tiêu.** Mỗi ứng viên được gắn đúng bản ghi vàng hoặc tạo bản ghi mới, hoặc chuyển người khi nghi ngờ; mọi ghi đè đều có lịch sử.

**Tác nhân chính.** Hệ thống (`mdm-match-online`, `mdm-golden`).

**Tác nhân phụ.** PH-07, Kafka (outbox), DS (nhận mục hàng đợi).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-020, FR-06-021, FR-06-034.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Ứng viên `NORMALIZED`; bộ quy tắc `ACTIVE`.

**Kích hoạt.** Ứng viên chuyển `NORMALIZED`.

**Đảm bảo tối thiểu.** Không hợp nhất khi nghi ngờ (BR-06-002); mọi thay đổi ghi ảnh chụp trước trong cùng giao dịch, không ghi được thì hủy (BR-06-005).

**Đảm bảo thành công.** Ứng viên `LINKED` (kèm `source_xref`) hoặc `QUEUED`; phát EVT-06-01 hoặc EVT-06-02.

**Luồng chính.**
1. Ứng viên từ `HT-GIAODUC` "Nguyen Van A, 15/01/1990, xã 00004" không có CCCD hợp lệ.
2. Hệ thống đếm thuộc tính `matchable` có giá trị (≥ `minAttributes`, BR-06-015); đủ thì lấy khối theo khóa gom nhóm (tối đa 200 ứng viên).
3. Hệ thống chấm điểm từng thuộc tính, áp quy tắc loại trừ, được `G-10234` điểm 0,94 ≥ `autoMergeThreshold`: kết luận `MATCH`, phương thức `PROBABILISTIC_ONLINE`.
4. Hệ thống ghi ảnh chụp `golden_history`, liên kết `source_xref`, tính lại sống sót từng thuộc tính theo nguồn, tăng `version`.
5. Hệ thống đặt ứng viên `LINKED`, phát EVT-06-02 qua outbox.

**Luồng thay thế.**
- **1a. Có CCCD hợp lệ.** Đối sánh xác định, `MATCH` phương thức `DETERMINISTIC`; khóa khớp nhưng ngày sinh lệch > 2 ngày thì vẫn `MATCH`, cảnh báo `CRITICAL_CONFLICT` cho sống sót (UC-06-15).
- **3a. Điểm trong vùng xem xét hoặc hai ứng viên cùng vượt ngưỡng (chênh < 0,03).** `POSSIBLE_MATCH`, lý do `POSSIBLE_MATCH` hoặc `MULTIPLE_CANDIDATES`; tạo mục hàng đợi (UC-06-12).
- **3b. `NO_MATCH`.** Tạo bản ghi vàng `ACTIVE` mới, phát EVT-06-01.
- **2a. Thiếu thuộc tính.** `POSSIBLE_MATCH` lý do `INSUFFICIENT_ATTRIBUTES` nếu có ứng viên trong khối, ngược lại `NO_MATCH`.
- **4a. Không thuộc tính nào đổi.** Chỉ cập nhật liên kết, không tăng `version`, không phát sự kiện.
- **4b. Bản ghi vàng đích đã `MERGED`.** Chuyển theo `mergedInto` rồi áp.

**Luồng ngoại lệ.**
- **E1. Truy vấn quá 800 ms (bước 2, 3).** Ngắt, `POSSIBLE_MATCH` lý do `TIMEOUT`; cảnh báo ở UI-06-01 khi > 1%: "Đối sánh trực tuyến chậm: {tỷ lệ}% lượt quá giờ."
- **E2. Hai bản ghi vàng cùng khóa định danh (1a).** ERR-06-112; kết luận `CONFLICT`, mục `IDENTIFIER_CONFLICT` ưu tiên cao nhất; UI-06-01: "Phát hiện {n} bản ghi vàng cùng số định danh. Cần xử lý ngay."
- **E3. Không ghi được lịch sử (bước 4).** ERR-06-111; giao dịch hủy, ứng viên giữ `NORMALIZED`, thử lại 3 lần giãn dần; UI-06-11: "Không lưu được lịch sử bản ghi vàng nên chưa cập nhật. Đã ghi nhận để xử lý lại."
- **E4. Không giải mã được trường nhạy cảm (bước 3).** ERR-06-113; UI-06-18: "Không giải mã được trường nhạy cảm, đang trả dạng che."

**Quy tắc áp dụng.** BR-06-001, BR-06-002, BR-06-005, BR-06-009, BR-06-015, BR-06-018, BR-06-020, BR-06-029.

**Màn hình, API.** Không có màn riêng (kết quả ở UI-06-11, UI-06-01); API-06-071 dùng chung logic; kịch bản TS-06-10.
:::

```{.mermaid caption="Hoạt động đối sánh một ứng viên"}
flowchart TB
  A["Ứng viên NORMALIZED"] --> B{"Có khóa định danh hợp lệ?"}
  B -->|"Có"| C["Đối sánh xác định theo khóa"]
  B -->|"Không"| D{"Đủ minAttributes?"}
  D -->|"Không"| N["NO_MATCH hoặc POSSIBLE_MATCH INSUFFICIENT_ATTRIBUTES"]
  D -->|"Đủ"| E["Gom nhóm và chấm điểm pg_trgm"]
  C --> F{"Kết luận"}
  E --> F
  F -->|"MATCH"| G["Liên kết, sống sót, ảnh chụp, EVT-06-02"]
  F -->|"NO_MATCH"| H["Tạo bản ghi vàng, EVT-06-01"]
  F -->|"POSSIBLE_MATCH, CONFLICT"| I["Mục hàng đợi, EVT-06-08"]
```

Hình cho thấy chỉ hai nhánh tự ghi (`MATCH`, `NO_MATCH`); mọi trường hợp nghi ngờ, xung đột định danh hay thiếu thuộc tính đều dừng ở hàng đợi, không bị hợp nhất ngầm.

### 6.11. UC-06-11 · Chạy job đối sánh theo lô bằng Splink

Việc trực tuyến không so được mọi cặp trong khối, nên nạp ban đầu hoặc rà trùng định kỳ chạy theo lô. Job không bao giờ ghi thẳng vào bảng bản ghi vàng.

::: dac-ta
**Mục tiêu.** Khử trùng toàn bộ dữ liệu một lần (hoặc định kỳ), cặp nghi ngờ vào hàng đợi, và có cơ chế dừng khi kết quả bất thường.

**Tác nhân chính.** TA, TO (Chi); lịch tự động (UC-06-26).

**Tác nhân phụ.** Job K8s `mdm-splink`, DA (xác nhận vượt ngưỡng), PH-13, PH-18.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-022.

**Truy vết.** REQ-06; BP-10 đề nghị; D03-01 (Splink theo lô); hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-operate`; bộ quy tắc `ACTIVE` (hoặc `TESTING` với `dryRun`); không có job `BATCH_MATCH` khác của domain.

**Kích hoạt.** Chi bấm "Chạy job" ở UI-06-12 hoặc lịch 01:00 Chủ nhật.

**Đảm bảo tối thiểu.** Job `FAILED` không đổi bản ghi vàng nào; từng cặp áp trong giao dịch riêng; staging bị xóa.

**Đảm bảo thành công.** Job `SUCCEEDED` hoặc `PARTIALLY_SUCCEEDED`; phát EVT-06-09.

**Luồng chính.**
1. Chi chọn `domainCode = CITIZEN`, `scope = FULL_INITIAL` (API-06-042); job `QUEUED`.
2. `PREPARING`: hệ thống xuất thuộc tính `matchable` đã chuẩn hóa sang bảng staging, trường `SENSITIVE` dạng HMAC.
3. `RUNNING`: khởi Job K8s `mdm-splink` (tài khoản chỉ đọc staging); job chấm điểm cặp trong khối, ghi bảng kết quả.
4. Số cặp `MATCH` ≤ 5% số bản ghi vào: sang `APPLYING`.
5. Hệ thống áp từng cặp trong giao dịch riêng: `MATCH` hợp nhất (`PROBABILISTIC_BATCH`), `POSSIBLE_MATCH` tạo mục hàng đợi; bỏ qua cặp đã có quyết định thủ công (BR-06-023).
6. Job `SUCCEEDED`, xóa staging, phát EVT-06-09; Chi theo dõi ở API-06-043.

**Luồng thay thế.**
- **1a. `dryRun = true`.** Dừng sau bước 3, báo số cặp theo vùng và mẫu 100 cặp, không áp.
- **1b. `trainOnly = true`.** Ước lượng m, u bằng EM, lưu vào bộ quy tắc nháp mới.
- **4a. Vượt ngưỡng an toàn.** `AWAITING_CONFIRMATION`, giao việc DA; Hùng xác nhận (API-06-044 `:confirm`) thì tiếp `APPLYING`, từ chối thì `CANCELLED`.
- **5a. Bản ghi đổi sau thời điểm xuất.** Bỏ qua cặp (ERR-06-104), job `PARTIALLY_SUCCEEDED`.

**Luồng ngoại lệ.**
- **E1. Job trùng (bước 1).** ERR-06-025 (409): "Domain {mã} đang có job đối sánh {jobId} chạy."
- **E2. Lỗi đọc staging (bước 3).** ERR-06-101, `FAILED`; UI-06-12: "Job {id} lỗi khi đọc dữ liệu: {chi tiết}. Không bản ghi vàng nào bị đổi."
- **E3. Quá giờ tối đa 4 giờ (bước 3).** ERR-06-102, `FAILED`.
- **E4. Hết bộ nhớ (bước 3).** ERR-06-103, `FAILED`, gợi ý chuyển chế độ Spark.
- **E5. Vượt ngưỡng an toàn (4a).** ERR-06-105, `AWAITING_CONFIRMATION`.

**Quy tắc áp dụng.** BR-06-022, BR-06-023.

**Màn hình, API.** UI-06-12; API-06-041, 042, 043, 044; kịch bản TS-06-11.
:::

```{.mermaid caption="Trình tự job đối sánh theo lô bằng Splink"}
sequenceDiagram
  actor TO
  participant M as dh-data
  participant PG as pg-core ph06_mdm
  participant J as Job K8s mdm-splink
  actor DA
  TO->>M: Chạy job BATCH_MATCH (API-06-042)
  M->>PG: Xuất staging, HMAC cho trường nhạy cảm
  M->>J: Khởi Job K8s
  J->>PG: Đọc staging, chấm điểm, ghi kết quả
  J-->>M: Hoàn tất
  alt Cặp MATCH vượt 5% đầu vào
    M-->>DA: Việc xác nhận áp kết quả
    DA->>M: Xác nhận (API-06-044)
  end
  M->>PG: Áp từng cặp, tạo mục hàng đợi
  M->>M: Phát EVT-06-09 job.finished
```

Hình cho thấy Job Splink chỉ chạm staging và bảng kết quả; mọi thay đổi bản ghi vàng đi qua `dh-data` nên có lịch sử, lineage và sự kiện như đường trực tuyến.

### 6.12. UC-06-12 · Hàng đợi người quản lý: nhận việc, phân công và theo dõi SLA

Mỗi kết luận không chắc chắn thành một việc rõ ràng, xếp theo mức khẩn để xung đột định danh và bản ghi nhiều nguồn được xử lý trước.

::: dac-ta
**Mục tiêu.** Nhóm người quản lý chia việc không chồng chéo, việc không bị bỏ quên, quá tải được phát hiện sớm.

**Tác nhân chính.** DS (Lan), DA (Hùng), TA.

**Tác nhân phụ.** Hệ thống `mdm-steward`, PH-13, "Việc của tôi".

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-027, FR-06-028, FR-06-032.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-steward`; có mục `OPEN`; phân công cho người khác cần DA hoặc TA.

**Kích hoạt.** Lan mở UI-06-04, bấm "Nhận việc tiếp theo"; job định kỳ 15 phút theo dõi SLA.

**Đảm bảo tối thiểu.** Mục hàng đợi không bị xử lý song song; cặp trong vùng xem xét không bao giờ tự quyết (BR-06-002).

**Đảm bảo thành công.** Mục `ASSIGNED` cho đúng một người; mục quá hạn được nâng ưu tiên, cảnh báo phát ra.

**Luồng chính.**
1. Hệ thống tạo mục từ `POSSIBLE_MATCH`, `CONFLICT`, xung đột thuộc tính quan trọng, bản ghi mồ côi; tính ưu tiên (`IDENTIFIER_CONFLICT` cao nhất, nguồn nhiều, `RiskLevel`); phát EVT-06-08.
2. Lan mở UI-06-04, lọc theo domain, lý do (`QueueReason`), quá hạn (API-06-045).
3. Lan bấm "Nhận việc tiếp theo" (API-06-047 `:claim`); mục `ASSIGNED`, giữ trong `06.queue.hold-minutes` = 30 phút.
4. Lan chuyển sang UC-06-13 để quyết định.
5. Mỗi 15 phút hệ thống kiểm SLA `06.queue.sla-days` = 7: quá hạn thì nâng ưu tiên; quá `06.queue.escalate-after-days` = 14 thì giao DA phân công lại; số mục mở > `06.queue.max-open` = 500 thì cảnh báo PH-13 (API-06-050).

**Luồng thay thế.**
- **3a. Phân công.** Hùng chọn tối đa 100 mục quá hạn, bấm `:assign` cho Lan.
- **3b. Trả lại.** Lan bấm `:release`, hoặc hết hạn giữ 30 phút: mục về `OPEN`.
- **1a. Dữ liệu đổi trong lúc chờ.** Mục `CANCELLED` lý do `STALE`, đối sánh lại; cặp vẫn trong vùng xem xét thì sinh mục mới, giữ người đang nhận.
- **5a. PH-13 không nhận cảnh báo.** Giữ cảnh báo ở UI-06-01: "Hàng đợi có {n} mục mở, vượt ngưỡng {m}."

**Luồng ngoại lệ.**
- **E1. Mục đã có người nhận (bước 3).** ERR-06-027 (409): "Mục này vừa được {người} nhận. Hệ thống chuyển anh/chị sang mục kế tiếp."
- **E2. Mục ngoài phạm vi tổ chức (bước 3).** ERR-06-028 (403): "Mục thuộc dữ liệu của tổ chức khác, anh/chị không được xử lý."

**Quy tắc áp dụng.** BR-06-002, BR-06-015, BR-06-019.

**Màn hình, API.** UI-06-04, UI-06-01; API-06-045, 047, 050; kịch bản TS-06-12.
:::

### 6.13. UC-06-13 · So sánh cạnh nhau và quyết định khớp, không khớp, hoãn

Màn hình quan trọng nhất của phân hệ: hai bản ghi cạnh nhau, điểm từng thuộc tính, nguồn, thời điểm; DS quyết định kèm lý do để hệ thống liên kết hoặc tách đúng và giải trình được.

::: dac-ta
**Mục tiêu.** DS quyết định đúng một mục trong khoảng một phút (trung vị ≤ 60 giây, NFR-06-017) và để lại lý do giải trình được.

**Tác nhân chính.** DS (Lan).

**Tác nhân phụ.** PH-09 (bỏ che `PERM-09-unmask`), DA (nếu rủi ro cao).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-029, FR-06-030.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Mục `ASSIGNED` cho Lan, còn hiệu lực; `PERM-06-steward`, hợp nhất cần thêm `PERM-06-merge`.

**Kích hoạt.** Lan mở mục ở UI-06-04, vào UI-06-05.

**Đảm bảo tối thiểu.** Không hợp nhất hai bản ghi có khóa định danh xác định khác nhau (BR-06-006); không ghi được nhật ký truy cập thì không hiện dữ liệu (BR-06-010).

**Đảm bảo thành công.** Mục `RESOLVED` (rủi ro thấp, `NO_MATCH`), `DEFERRED`, hoặc `PENDING_APPROVAL` (rủi ro cao, UC-06-14); quyết định lưu kèm lý do, nhãn thêm vào tập nhãn.

**Luồng chính.**
1. Lan mở UI-06-05; hệ thống gọi API-06-046, hiện hai cột, điểm 0,86, từng thuộc tính tô theo `ComparisonLevel` (`EXACT`, `FUZZY_HIGH`, `DIFFERENT`…); giá trị `SENSITIVE` che.
2. Hệ thống ghi nhật ký truy cập, mục đích "xử lý hàng đợi".
3. Lan chọn "Cùng một thực thể" (phím M), nhập lý do "Cùng CCCD ở nguồn thứ ba, khác chính tả tên." (≥ 20 ký tự).
4. Hệ thống gọi API-06-048 `:decide` (`MATCH`); tính `RiskLevel` theo BR-06-019.
5. `LOW`: hệ thống hợp nhất ngay (FR-06-034, phương thức `MANUAL`), mục `RESOLVED`, phát EVT-06-03; màn tự chuyển mục kế tiếp.

**Luồng thay thế.**
- **3a. "Khác nhau" (N).** Hệ thống ghi `negativeLink` giữa hai bản ghi, mục `RESOLVED`, thêm nhãn `NO_MATCH`.
- **3b. "Hoãn" (H).** Mục `DEFERRED` kèm ghi chú cần thêm thông tin.
- **3c. Bỏ che `SENSITIVE`.** Lan có `PERM-09-unmask` nhập lý do; PH-09 trả giá trị rõ cho phiên, nhật ký đánh dấu.
- **3d. Sửa quyết định trong 24 giờ.** Mở lại mục từ lịch sử khi chưa có thao tác phụ thuộc; sau đó dùng UC-06-20.
- **4a. `HIGH`.** Chuyển UC-06-14.

**Luồng ngoại lệ.**
- **E1. Mục lỗi thời (bước 1, 4).** ERR-06-030 (409): "Dữ liệu của cặp đã thay đổi. Xem lại trước khi quyết định."
- **E2. Thiếu lý do (bước 3).** ERR-06-007 (422): "Nhập lý do (tối thiểu 20 ký tự)."
- **E3. Hai số định danh khác nhau (bước 4).** ERR-06-029 (422): "Hai bản ghi có số định danh khác nhau nên không được hợp nhất. Kiểm tra lại dữ liệu nguồn."
- **E4. Bản ghi vàng đang khóa (bước 4).** ERR-06-031 (409): "Bản ghi vàng {id} đang có thao tác chờ duyệt."
- **E5. Không ghi được nhật ký truy cập (bước 2).** ERR-06-039 (503): "Chưa ghi được nhật ký truy cập nên không hiển thị dữ liệu. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-06-006, BR-06-008, BR-06-010, BR-06-019, BR-06-023, BR-06-026.

**Màn hình, API.** UI-06-05; API-06-046, 048; kịch bản TS-06-13.
:::

### 6.14. UC-06-14 · Duyệt bốn mắt hợp nhất rủi ro cao

Hợp nhất có hậu quả lớn chỉ có hiệu lực khi người thứ hai có thẩm quyền đồng ý. Rủi ro cao theo BR-06-019: hợp nhất hai bản ghi vàng cùng có ≥ 3 liên kết, có thuộc tính quan trọng khác nhau, điểm < 0,95 với hợp nhất vàng với vàng, hợp nhất thủ công ≥ 3 bản ghi, hoặc tách bản ghi có ≥ 3 liên kết.

::: dac-ta
**Mục tiêu.** Hợp nhất, tách, hoàn tác rủi ro cao được DA xem lại trước khi có hiệu lực, giải trình được người đề nghị, người duyệt và tác động.

**Tác nhân chính.** DA (Hùng).

**Tác nhân phụ.** DS (Lan, người đề nghị), `dh-data`, Kafka, "Việc của tôi".

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-031.

**Truy vết.** REQ-06; FR-00-071, ADR-046; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Mục `PENDING_APPROVAL` hoặc `golden_operation` `PENDING_APPROVAL` (từ UC-06-13, 18, 19, 20); hai bản ghi vàng `LOCKED`; Hùng có `PERM-06-approve`, `PERM-06-merge`.

**Kích hoạt.** Hùng mở việc ở "Việc của tôi" hoặc UI-06-05 chế độ duyệt.

**Đảm bảo tối thiểu.** Trong lúc chờ, bản ghi `LOCKED` vẫn tra cứu được và nhận cập nhật nguồn nhưng không nhận hợp nhất, tách, sửa tay khác.

**Đảm bảo thành công.** Thao tác thực hiện trong một giao dịch, bản ghi mở khóa, mục `RESOLVED`; hoặc bị từ chối và bản ghi trở lại như cũ.

**Luồng chính.**
1. Hùng mở mục; hệ thống hiện so sánh như UC-06-13 cộng quyết định, lý do của Lan và tác động (số liên kết chuyển, thuộc tính đổi giá trị sau sống sót).
2. Hùng bấm "Duyệt" (API-06-049 hoặc API-06-061 `:approve`); hệ thống kiểm Hùng khác Lan (LP-06-01).
3. Hệ thống thực hiện thao tác trong một giao dịch: ảnh chụp, chuyển liên kết, sống sót lại, bản ghi bị hợp nhất `MERGED` (`mergedInto`).
4. Hệ thống mở khóa, mục `RESOLVED`, phát EVT-06-03 (hoặc EVT-06-04 khi duyệt tách), báo Lan.

**Luồng thay thế.**
- **2a. Từ chối.** Hùng chọn "Từ chối" kèm ý kiến ≥ 20 ký tự; mục về `ASSIGNED` cho Lan, bản ghi mở khóa.
- **2b. DA đổi `survivorId`.** Coi như từ chối kèm đề nghị, quay lại Lan.
- **1a. Chờ quá lâu.** Quá 2 ngày làm việc nhắc DA, quá 5 ngày giao DA khác của tenant.

**Luồng ngoại lệ.**
- **E1. Tự duyệt (bước 2).** ERR-06-005 (403): "Anh/chị là người đề nghị hợp nhất nên không được tự duyệt."
- **E2. Từ chối thiếu ý kiến (2a).** ERR-06-007 (422): "Nhập lý do từ chối (tối thiểu 20 ký tự)."
- **E3. Bản ghi đổi trong lúc chờ (bước 2, 3).** ERR-06-030 (409): "Một trong hai bản ghi đã thay đổi trong lúc chờ duyệt. Yêu cầu người đề nghị xem lại."

**Quy tắc áp dụng.** BR-06-005, BR-06-019, BR-06-023.

**Màn hình, API.** UI-06-05; API-06-049, 061; kịch bản TS-06-14.
:::

```{.mermaid caption="Trình tự quyết định và duyệt bốn mắt hợp nhất rủi ro cao"}
sequenceDiagram
  actor DS
  actor DA
  participant S as mdm-steward
  participant G as mdm-golden
  participant K as Kafka
  DS->>S: Quyết định MATCH kèm lý do (API-06-048)
  S->>S: Tính rủi ro theo BR-06-019 là HIGH
  S->>G: Khóa hai bản ghi vàng LOCKED
  S-->>DA: Việc cần duyệt
  DA->>S: Duyệt (API-06-049)
  S->>G: Hợp nhất trong một giao dịch
  G->>G: Ảnh chụp, chuyển liên kết, sống sót
  G->>K: EVT-06-03 golden.merged
  S-->>DS: Mục RESOLVED
```

Hình cho thấy hai bản ghi bị khóa từ lúc đề nghị đến lúc DA quyết định và chỉ một giao dịch duy nhất thực hiện hợp nhất, nên không có trạng thái nửa chừng.

### 6.15. UC-06-15 · Cấu hình quy tắc sống sót, xem trước tác động và áp lại

::: dac-ta
**Mục tiêu.** Quy định cách chọn giá trị thắng cho từng thuộc tính (nguồn quốc gia, ưu tiên nguồn, độ mới, độ đầy đủ) và áp lại có kiểm soát khi đổi cấu hình.

**Tác nhân chính.** TA, DS (Lan) soạn; DA (Hùng) duyệt, xác nhận áp lại hàng loạt.

**Tác nhân phụ.** Job `SURVIVORSHIP_REAPPLY`, PH-13.

**Mức ưu tiên.** M · Đợt 3 (FR-06-042 mức S).

**FR hiện thực.** FR-06-033, FR-06-042.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Domain `ACTIVE`; bảng ưu tiên nguồn đã duyệt (UC-06-04).

**Kích hoạt.** Lan mở UI-06-10; hoặc nút "Xem trước tác động" ở UI-06-08, UI-06-10.

**Đảm bảo tối thiểu.** Xem trước không đổi dữ liệu; thuộc tính thẩm quyền quốc gia luôn do nguồn quốc gia (BR-06-003).

**Đảm bảo thành công.** Quy tắc `ACTIVE`; bản ghi đổi giá trị đã áp lại, có `batchOperationId` hoàn tác được.

**Luồng chính.**
1. Lan đặt cho `fullName` chiến lược `SOURCE_PRIORITY`, cho `phone` `MOST_RECENT`, cho `dateOfBirth` `NATIONAL_AUTHORITY`; lưu (API-06-052) và gửi duyệt (API-06-053 `:submit`).
2. Lan bấm "Xem trước tác động" (API-06-054); hệ thống báo số bản ghi đổi giá trị, ví dụ 1.340 trên 1,2 triệu.
3. Hùng duyệt (API-06-053 `:approve`, LP-06-01).
4. Hệ thống tạo job `SURVIVORSHIP_REAPPLY` (API-06-055); nếu > 1.000 bản ghi thì chờ Hùng xác nhận.
5. Job áp lại theo từng bản ghi, ghi ảnh chụp và `batchOperationId`, phát EVT-06-02 gộp tối đa 500 `goldenId` mỗi sự kiện (`changeType = SURVIVORSHIP_REAPPLY`).

**Luồng thay thế.**
- **1a. Xung đột thuộc tính quan trọng cùng mức, cùng thời điểm (chênh ≤ 24 giờ).** Với `criticalConflictToQueue = true`, giữ giá trị cũ và tạo mục `CRITICAL_CONFLICT`.
- **5a. Hoàn tác cả lô.** Dùng UC-06-20 với `batchOperationId`.

**Luồng ngoại lệ.**
- **E1. Chiến lược sai kiểu (bước 1).** ERR-06-022 (422): "Chiến lược {chiến lược} không áp được cho thuộc tính kiểu {kiểu}."
- **E2. Bỏ thẩm quyền quốc gia (bước 1).** ERR-06-035 (422): "Thuộc tính {tên} thuộc thẩm quyền CSDL quốc gia, không đổi được chiến lược đầu."
- **E3. Tự duyệt (bước 3).** ERR-06-005 (403): "Anh/chị là người gửi duyệt nên không được tự duyệt."
- **E4. Đang có job áp lại (bước 4).** ERR-06-025 (409): "Domain {mã} đang có job áp lại {jobId}."

**Quy tắc áp dụng.** BR-06-003, BR-06-004, BR-06-005.

**Màn hình, API.** UI-06-10, UI-06-08; API-06-051…055; kịch bản TS-06-15.
:::

### 6.16. UC-06-16 · Xem chi tiết bản ghi vàng, lịch sử và nguồn gốc thuộc tính

Dùng để trả lời khiếu nại: giá trị này từ đâu, lúc nào, theo quy tắc nào, và ngày 01/3 hệ thống hiển thị giá trị gì.

::: dac-ta
**Mục tiêu.** Thấy toàn bộ bản ghi vàng, lịch sử thay đổi, so sánh hai phiên bản và nguồn gốc từng thuộc tính, dữ liệu nhạy cảm được che.

**Tác nhân chính.** DS (Lan), DA, TA, SO, AU.

**Tác nhân phụ.** PH-09 (che, `PERM-09-unmask`).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-035, FR-06-041, FR-06-043.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-read`.

**Kích hoạt.** Lan mở `G-10234` từ UI-06-02 hoặc hàng đợi.

**Đảm bảo tối thiểu.** Không ghi được nhật ký truy cập thì không trả dữ liệu (BR-06-010); `SENSITIVE` luôn che nếu thiếu `PERM-09-unmask`.

**Đảm bảo thành công.** Người dùng thấy giá trị, nguồn, thời điểm, phiên bản; mỗi lượt xem có bản ghi `access_log`.

**Luồng chính.**
1. Lan mở UI-06-03; hệ thống gọi API-06-056, hiện tab Thuộc tính (kèm nhãn nguồn, độ tin cậy), Nguồn liên kết, Nguồn gốc, Lịch sử, Thao tác; ghi nhật ký truy cập.
2. Lan bấm nhãn nguồn của `permanentAddress`; tab Nguồn gốc (API-06-065) hiện nguồn, `sourceUpdatedAt`, thời điểm nhận, quy tắc sống sót, giá trị trước.
3. Lan mở tab Lịch sử (API-06-063), chọn phiên bản 3 và 5, bấm "So sánh" (API-06-064).
4. Lan nhập `asOf = 2026-03-01` để xem trạng thái tại thời điểm đó.

**Luồng thay thế.**
- **1a. Xem `SENSITIVE` đầy đủ.** Người có `PERM-09-unmask` nhập lý do, PH-09 trả giá trị rõ trong phiên, nhật ký đánh dấu bỏ che.
- **2a. Đề nghị sửa tại nguồn.** Từ mục lineage tạo yêu cầu sửa tại nguồn mà không đổi bản ghi vàng (BR-06-014).
- **1b. Bản ghi `MERGED`.** Trả `200` kèm `mergedInto`, liên kết tới bản sống sót.

**Luồng ngoại lệ.**
- **E1. Không tìm thấy (bước 1).** ERR-06-001 (404): "Không tìm thấy bản ghi vàng {id}."
- **E2. Không ghi được nhật ký (bước 1).** ERR-06-039 (503): "Chưa ghi được nhật ký truy cập nên không hiển thị dữ liệu. Thử lại sau ít phút."
- **E3. Phiên bản không có (bước 3).** ERR-06-001 (404): "Bản ghi {id} không có phiên bản {n}."
- **E4. Thuộc tính không thuộc domain (bước 2).** ERR-06-003 (400): "Domain {mã} không có thuộc tính {tên}."

**Quy tắc áp dụng.** BR-06-009, BR-06-010, BR-06-026.

**Màn hình, API.** UI-06-03; API-06-056, 063, 064, 065; kịch bản TS-06-16.
:::

### 6.17. UC-06-17 · Sửa tay thuộc tính, ngừng và khôi phục bản ghi vàng

Sửa trên bản ghi vàng chỉ là biện pháp tạm, có hạn, luôn kèm yêu cầu sửa tại nguồn (BR-06-014). Không xóa bản ghi vàng; chỉ ngừng (BR-06-007).

::: dac-ta
**Mục tiêu.** DS sửa tạm một giá trị sai rõ ràng, hoặc đưa ra khỏi sử dụng bản ghi không còn ý nghĩa, và khôi phục khi cần.

**Tác nhân chính.** DS (Lan), TA.

**Tác nhân phụ.** HTTT nguồn (nhận EVT-06-15), nguồn thẩm quyền.

**Mức ưu tiên.** M · Đợt 3 (FR-06-036 mức S).

**FR hiện thực.** FR-06-036, FR-06-040.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Sửa: `PERM-06-update`, bản ghi `ACTIVE`, thuộc tính không thẩm quyền quốc gia. Ngừng, khôi phục: `PERM-06-merge`.

**Kích hoạt.** Nút "Sửa" cạnh thuộc tính hoặc "Ngừng", "Khôi phục" ở UI-06-03; mục hàng đợi `ORPHANED`.

**Đảm bảo tối thiểu.** Ảnh chụp trước thay đổi; thao tác hoàn tác được (UC-06-20).

**Đảm bảo thành công.** Thuộc tính đổi với chiến lược `MANUAL_OVERRIDE` có hạn, yêu cầu sửa tại nguồn được tạo; hoặc bản ghi `RETIRED` hay `ACTIVE` trở lại.

**Luồng chính.**
1. Lan bấm "Sửa" cạnh `phone` của `G-10234`, nhập giá trị mới, lý do "Công dân xuất trình giấy tờ ngày 24/11/2026." và hạn hiệu lực.
2. Hệ thống gọi API-06-057 với `If-Match`, kiểm lý do ≥ 20 ký tự, bản ghi không `LOCKED`.
3. Hệ thống ghi ảnh chụp, đặt `MANUAL_OVERRIDE`, tăng `version`, tạo yêu cầu sửa tại nguồn, phát EVT-06-02 và EVT-06-15.
4. Với bản ghi mồ côi (hết liên kết), Lan chọn "Ngừng" lý do `ORPHANED` (API-06-062 `:retire`); bản ghi `RETIRED`, phát EVT-06-05.
5. Khôi phục: Lan bấm "Khôi phục" (`:restore`); bản ghi `ACTIVE`, phát EVT-06-06.

**Luồng thay thế.**
- **3a. Nguồn sửa trước hạn.** Hệ thống tự bỏ `MANUAL_OVERRIDE`, đóng yêu cầu sửa.
- **4a. `DECEASED`, `DISSOLVED` từ nguồn thẩm quyền.** Ghi `lifeStatus`, giữ `ACTIVE` để HTTT tra hồ sơ lịch sử; chỉ ngừng khi Lan xác nhận.

**Luồng ngoại lệ.**
- **E1. Thuộc tính thẩm quyền quốc gia (bước 2).** ERR-06-035 (422): "Thuộc tính {tên} chỉ được sửa tại CSDL quốc gia. Hướng dẫn công dân liên hệ cơ quan đăng ký."
- **E2. Thiếu lý do (bước 2, 4).** ERR-06-007 (422): "Nhập lý do (tối thiểu 20 ký tự)."
- **E3. Bản ghi đang khóa (bước 2).** ERR-06-031 (409): "Bản ghi vàng {id} đang có thao tác chờ duyệt."
- **E4. Sửa đồng thời (bước 2).** ERR-06-004 (409): "Bản ghi đã được cập nhật. Tải lại để xem giá trị mới."
- **E5. Ngừng khi còn liên kết hiệu lực (bước 4).** ERR-06-036 (422): "Bản ghi còn {n} nguồn liên kết hiệu lực. Gỡ liên kết hoặc chọn lý do có căn cứ từ nguồn thẩm quyền."

**Quy tắc áp dụng.** BR-06-005, BR-06-007, BR-06-008, BR-06-014, BR-06-025.

**Màn hình, API.** UI-06-03; API-06-057, 062; kịch bản TS-06-17.
:::

### 6.18. UC-06-18 · Hợp nhất bản ghi vàng thủ công

Dùng khi người quản lý phát hiện trùng ngoài hàng đợi, ví dụ qua khiếu nại.

::: dac-ta
**Mục tiêu.** Gộp 2 đến 10 bản ghi vàng cùng domain thành một, giữ liên kết nguồn, chọn được giá trị thắng cho thuộc tính xung đột.

**Tác nhân chính.** DS (Lan), TA; DA (Hùng) duyệt khi rủi ro cao.

**Tác nhân phụ.** Kafka, HTTT đã lưu `goldenId`.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-037.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-merge`; mọi bản ghi `ACTIVE`, cùng domain.

**Kích hoạt.** Lan chọn bản ghi từ UI-06-02, bấm "Hợp nhất" (UI-06-06).

**Đảm bảo tối thiểu.** Không hợp nhất khóa định danh xác định khác nhau (BR-06-006); lỗi thì không bản ghi nào đổi.

**Đảm bảo thành công.** Bản ghi bị hợp nhất `MERGED` (`mergedInto = survivorId`), liên kết chuyển sang bản sống sót; hoàn tác được 90 ngày.

**Luồng chính.**
1. Lan chọn `G-10234` và `G-10871`, chọn `survivorId = G-10234` (mặc định bản nhiều liên kết nhất), nhập lý do.
2. Hệ thống kiểm cùng domain, đều `ACTIVE`, không có cặp khóa xác định khác nhau, lý do hợp lệ.
3. Hệ thống hiện xem trước: giá trị sống sót từng thuộc tính, số liên kết chuyển, xung đột; Lan chọn giá trị cho thuộc tính xung đột (`attributeOverrides`).
4. Lan xác nhận (API-06-058); hệ thống tính rủi ro (BR-06-019).
5. `LOW`: thực hiện ngay, trả `200`; `HIGH`: tạo thao tác `PENDING_APPROVAL`, khóa bản ghi, trả `202`, sang UC-06-14.
6. Khi thực hiện, hệ thống ghi ảnh chụp mọi bản ghi, chuyển liên kết, tính lại sống sót, ghi `golden_operation` `MERGE`, phát EVT-06-03.

**Luồng thay thế.**
- **3a. `attributeOverrides`.** Ghi như sửa tay (UC-06-17) cùng thao tác.
- **6a. HTTT tra `goldenId` cũ.** Nhận `200` kèm `mergedInto` (chuyển hướng).

**Luồng ngoại lệ.**
- **E1. Khóa định danh khác nhau (bước 2).** ERR-06-029 (422): "Hai bản ghi có số định danh khác nhau nên không được hợp nhất."
- **E2. Bản ghi không còn `ACTIVE` (bước 2).** ERR-06-006 (409): "Bản ghi {id} đang ở trạng thái {trạng thái}."
- **E3. Khác domain (bước 2).** ERR-06-003 (400): "Chỉ hợp nhất được bản ghi cùng domain."
- **E4. Thiếu lý do (bước 2).** ERR-06-007 (422): "Nhập lý do (tối thiểu 20 ký tự)."
- **E5. Bản ghi đang khóa (bước 2).** ERR-06-031 (409): "Bản ghi vàng {id} đang có thao tác chờ duyệt."

**Quy tắc áp dụng.** BR-06-005, BR-06-006, BR-06-008, BR-06-019.

**Màn hình, API.** UI-06-06, UI-06-02; API-06-058, 061; kịch bản TS-06-18.
:::

### 6.19. UC-06-19 · Tách bản ghi vàng và gỡ liên kết chéo nguồn

Sửa một hợp nhất nhầm: hai người khác nhau bị trộn thành một hồ sơ. Gỡ một liên kết sai không cần tách cả bản ghi.

::: dac-ta
**Mục tiêu.** Tách các liên kết nguồn của một bản ghi vàng thành hai hoặc nhiều bản ghi đúng thực thể; hoặc gỡ một liên kết sai.

**Tác nhân chính.** DS (Lan), TA; DA (Hùng) duyệt khi bản ghi có ≥ 3 liên kết.

**Tác nhân phụ.** Kafka, HTTT đã lưu `goldenId`, HTTT nguồn (nhận EVT-06-14).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-038, FR-06-044.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-merge` (tách), `PERM-06-update` (gỡ); bản ghi `ACTIVE`, không `LOCKED`, tách cần ≥ 2 liên kết hiệu lực.

**Kích hoạt.** Tab "Nguồn liên kết" ở UI-06-03; nút "Tách" ở UI-06-06.

**Đảm bảo tối thiểu.** Mỗi liên kết thuộc đúng một nhóm sau tách; lỗi thì không đổi gì.

**Đảm bảo thành công.** Hai (hoặc hơn) bản ghi vàng, `negativeLink` ngăn đối sánh hợp nhất lại (BR-06-023); phát EVT-06-04.

**Luồng chính.**
1. Lan mở tab "Nguồn liên kết" của `G-10234` (API-06-066): thấy `HT-HOTICH`, `HT-GIAODUC`, `HT-BHXH` thuộc hai người khác nhau.
2. Lan bấm "Tách", phân nhóm A (ở lại `G-10234`) và nhóm B (`HT-GIAODUC`), nhập lý do.
3. Hệ thống kiểm mọi liên kết thuộc đúng một nhóm, ≥ 2 nhóm; gợi ý phân bổ theo bản ghi vàng cũ nếu từng là kết quả hợp nhất.
4. Lan xác nhận (API-06-059); hệ thống tính rủi ro; `HIGH` chờ DA (UC-06-14).
5. Hệ thống ghi ảnh chụp, khôi phục `G-10871` từ `MERGED` hoặc tạo bản ghi mới, chuyển liên kết, tính lại sống sót, ghi `negativeLink`, phát EVT-06-04 (và EVT-06-01 khi tạo mới).

**Luồng thay thế.**
- **2a. Gỡ một liên kết.** Lan bấm "Gỡ" (API-06-067 `:detach`) kèm `RelinkMode` (`NEW_GOLDEN` hoặc `REMATCH`); hệ thống đặt `XrefStatus = DETACHED`, phát EVT-06-14.
- **2b. Bản ghi chỉ còn liên kết đó.** Sau gỡ chuyển hàng đợi `ORPHANED` đề nghị ngừng.

**Luồng ngoại lệ.**
- **E1. Phân bổ thiếu hoặc trùng (bước 3).** ERR-06-032 (422): "Mỗi bản ghi nguồn phải thuộc đúng một nhóm sau khi tách."
- **E2. Chỉ một liên kết (bước 2).** ERR-06-032 (422): "Bản ghi chỉ có một nguồn liên kết, không có gì để tách."
- **E3. Bản ghi đang khóa (bước 4).** ERR-06-031 (409): "Bản ghi vàng {id} đang có thao tác chờ duyệt."
- **E4. Liên kết không hiệu lực (2a).** ERR-06-006 (409): "Liên kết đã ở trạng thái {trạng thái}."
- **E5. Thiếu lý do (bước 2).** ERR-06-007 (422): "Nhập lý do (tối thiểu 20 ký tự)."

**Quy tắc áp dụng.** BR-06-008, BR-06-018, BR-06-019, BR-06-023.

**Màn hình, API.** UI-06-06, UI-06-03; API-06-059, 061, 066, 067; kịch bản TS-06-19.
:::

```{.mermaid caption="Trình tự tách bản ghi vàng hợp nhất nhầm"}
sequenceDiagram
  actor DS
  participant G as mdm-golden
  participant PG as pg-core
  participant K as Kafka
  participant H as HTTT đăng ký nhận
  DS->>G: Tách G-10234 thành nhóm A và B (API-06-059)
  G->>PG: Ảnh chụp G-10234
  G->>PG: Khôi phục G-10871 từ MERGED, chuyển liên kết nhóm B
  G->>PG: Sống sót lại hai bản ghi, ghi negativeLink
  G->>K: EVT-06-04 golden.split
  K-->>H: Thông báo G-10234 tách thành G-10234 và G-10871
```

Hình cho thấy HTTT đã lưu `goldenId` cũ nhận sự kiện tách rồi tra lại bản ghi nguồn của mình bằng UC-06-21 để biết bản ghi nào giờ thuộc `G-10871`.

### 6.20. UC-06-20 · Hoàn tác thao tác trên bản ghi vàng

Hoàn tác là thao tác mới, không xóa lịch sử (BR-06-024); là biện pháp sửa sai chính cho hợp nhất nhầm.

::: dac-ta
**Mục tiêu.** Đưa bản ghi về trạng thái trước một thao tác sai (hợp nhất, tách, sửa tay, ngừng, áp lại) mà không mất dữ liệu nguồn mới.

**Tác nhân chính.** DS (Lan), TA trong 90 ngày; DA (Hùng) duyệt khi quá hạn.

**Tác nhân phụ.** Kafka, HTTT đăng ký nhận.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-039.

**Truy vết.** REQ-06; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-merge`; thao tác `APPLIED`, chưa `UNDONE`.

**Kích hoạt.** Tab "Thao tác" ở UI-06-03, nút "Hoàn tác".

**Đảm bảo tối thiểu.** Lịch sử giữ cả thao tác gốc và thao tác hoàn tác; lỗi thì không đổi gì.

**Đảm bảo thành công.** Thao tác gốc `UNDONE`; thao tác `UNDO` mới trỏ gốc; bản ghi trở về như trước, cập nhật nguồn đến sau được áp lại.

**Luồng chính.**
1. Lan mở tab "Thao tác" của `G-10234`, chọn hợp nhất ngày 20/11/2026, bấm "Hoàn tác", nhập lý do.
2. Hệ thống tải thao tác và ảnh chụp trước thao tác (API-06-060).
3. Hệ thống tìm thao tác thủ công phụ thuộc sau đó; có thì yêu cầu xác nhận (`confirmDependents`).
4. Hệ thống khôi phục trạng thái, liên kết theo ảnh chụp, áp lại các cập nhật nguồn đến sau, ghi `UNDO`.
5. Hệ thống phát sự kiện ngược với gốc: hoàn tác hợp nhất phát EVT-06-04, hoàn tác tách phát EVT-06-03, còn lại EVT-06-02.

**Luồng thay thế.**
- **3a. Có thao tác phụ thuộc.** Lan xem danh sách và đánh dấu xác nhận để hoàn tác cả chuỗi.
- **3b. Quá `06.undo.window-days` = 90.** Tạo đề nghị chờ DA duyệt (API-06-061); Hùng duyệt thì thực hiện.
- **1a. Hoàn tác `NO_MATCH` của hàng đợi.** Gỡ `negativeLink`, đối sánh lại cặp.
- **1b. Hoàn tác cả lô.** Dùng `batchOperationId` (UC-06-15).

**Luồng ngoại lệ.**
- **E1. Có thao tác phụ thuộc, chưa xác nhận (bước 3).** ERR-06-033 (409): "Có {n} thao tác sau phụ thuộc vào thao tác này. Xem danh sách và xác nhận để hoàn tác cả chuỗi."
- **E2. Quá hạn (3b).** ERR-06-034 (403): "Thao tác đã quá {n} ngày. Đề nghị hoàn tác đã được gửi người duyệt dữ liệu."
- **E3. Đã hoàn tác (bước 2).** ERR-06-006 (409): "Thao tác này đã được hoàn tác."
- **E4. Tự duyệt (3b).** ERR-06-005 (403): "Anh/chị là người đề nghị nên không được tự duyệt."

**Quy tắc áp dụng.** BR-06-005, BR-06-024.

**Màn hình, API.** UI-06-03, UI-06-06; API-06-060, 061; kịch bản TS-06-20.
:::

```{.mermaid caption="Hoạt động hoàn tác một thao tác"}
flowchart TB
  A["DS chọn thao tác APPLIED"] --> B{"Còn trong 90 ngày?"}
  B -->|"Không"| C["Đề nghị hoàn tác chờ DA duyệt"]
  C --> D{"DA duyệt?"}
  D -->|"Không"| Z["Giữ nguyên, báo DS"]
  D -->|"Có"| E
  B -->|"Có"| E{"Có thao tác phụ thuộc?"}
  E -->|"Có, chưa xác nhận"| F["ERR-06-033, DS xác nhận chuỗi"]
  F --> G
  E -->|"Không hoặc đã xác nhận"| G["Khôi phục theo ảnh chụp"]
  G --> H["Áp lại cập nhật nguồn đến sau"]
  H --> I["Ghi UNDO, phát EVT-06-02, 03 hoặc 04"]
```

Hình cho thấy hai cổng kiểm soát trước khi khôi phục (hạn 90 ngày, thao tác phụ thuộc) và bước áp lại cập nhật nguồn để hoàn tác không làm mất dữ liệu mới.

### 6.21. UC-06-21 · Tra cứu, tra ID nguồn và tìm kiếm bản ghi vàng có che dữ liệu

Cửa khai thác dữ liệu chủ cho HTTT và người dùng. Mọi lượt trả dữ liệu phải có mục đích được PH-09 chấp thuận và nhật ký truy cập; giá trị che theo phân loại.

::: dac-ta
**Mục tiêu.** HTTT đổi khóa của hệ mình sang `goldenId` và ngược lại, lấy bản ghi vàng theo ID hoặc khóa định danh; DS tìm bản ghi khi không có khóa, mà không biến thành công cụ thu thập DLCN hàng loạt.

**Tác nhân chính.** HTTT, PH-04, PH-08 (`mdm:read`, `mdm:xref`, `mdm:search`); DS (Lan).

**Tác nhân phụ.** PH-09 (mục đích, che), OPA, Valkey (bộ đệm 60 giây).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-045, FR-06-046, FR-06-048, FR-06-052.

**Truy vết.** REQ-06, REQ-09; BP-10 đề nghị; hệ cũ: không có; LGC-NGSP-003 (tra BHXH hộ gia đình làm chính ở PH-14, §5.3).

**Tiền điều kiện.** Bên gọi có scope hoặc `PERM-06-read` và mục đích PH-09 cho domain; nguồn của bên gọi `ACTIVE`.

**Kích hoạt.** HTTT gọi API-06-068, 069, 070, 056 hoặc 072; Lan nhập tiêu chí ở UI-06-02.

**Đảm bảo tối thiểu.** Không ghi được nhật ký truy cập thì không trả dữ liệu (BR-06-010); PH-09 không khả dụng thì chỉ trả `PUBLIC` kèm `X-Datahub-Masking: fallback`.

**Đảm bảo thành công.** Bên gọi nhận bản ghi hoặc danh sách trong phạm vi mục đích, che đúng phân loại; mỗi lượt có `access_log`.

**Luồng chính.**
1. `HT-GIAODUC` gọi `GET /domains/CITIZEN/xrefs/HT-GIAODUC/HS-0099` (API-06-068) kèm `X-Purpose`; hệ thống trả `goldenId = G-10234`.
2. Hệ thống kiểm scope, mục đích, hạn mức; tra theo khóa định danh dùng `POST` (API-06-070) để khóa không vào log cổng.
3. Hệ thống trả bản ghi (API-06-056) kèm nguồn và độ tin cậy từng thuộc tính, che theo phân loại và mục đích.
4. Lan tìm trên UI-06-02 "Nguyễn Văn A" kèm năm sinh 1990 (API-06-072); mặc định `ACTIVE`.
5. Hệ thống ghi nhật ký truy cập; trả danh sách che DLCN.

**Luồng thay thế.**
- **1a. Tra lô.** Tối đa 500 khóa (API-06-069).
- **1b. Ứng viên chưa liên kết (`QUEUED`).** Trả `status = PENDING` kèm `candidateId`.
- **3a. Bản ghi `MERGED`.** Trả `mergedInto`; **3b. `RETIRED`.** Trả `410`.
- **4a. Chọn thêm trạng thái `MERGED`, `RETIRED`** trong bộ lọc.

**Luồng ngoại lệ.**
- **E1. Không có liên kết hoặc bản ghi (bước 1, 3).** ERR-06-050 (404): "Không có bản ghi vàng cho {nguồn}/{khóa}."; "Không có bản ghi vàng khớp khóa đã gửi."
- **E2. Thiếu mục đích (bước 2).** ERR-06-037 (403): "Yêu cầu thiếu mục đích khai thác được chấp thuận cho dữ liệu này."
- **E3. Đã ngừng (3b).** ERR-06-001 (410): "Bản ghi vàng {id} đã ngừng sử dụng: {lý do}."
- **E4. Lô quá lớn (1a).** ERR-06-018 (413): "Mỗi lần tra tối đa 500 khóa."
- **E5. Tìm quá rộng (bước 4).** ERR-06-040 (422): "Nhập thêm tiêu chí: họ tên cần đi kèm ngày sinh, năm sinh hoặc xã."
- **E6. Vượt ngưỡng hàng loạt (bước 4).** ERR-06-038 (403): "Anh/chị đã xem quá {n} bản ghi trong {phút} phút. Truy cập hàng loạt cần phê duyệt."
- **E7. Không ghi được nhật ký (bước 5).** ERR-06-039 (503): "Chưa ghi được nhật ký truy cập nên không trả dữ liệu."

**Quy tắc áp dụng.** BR-06-010, BR-06-013, BR-06-018, BR-06-026, LP-06-04.

**Màn hình, API.** UI-06-02, UI-06-03; API-06-056, 068, 069, 070, 072; kịch bản TS-06-21.
:::

### 6.22. UC-06-22 · Giải quyết bản ghi trực tuyến (resolve)

Luồng PH-04 làm giàu bản tin hoặc HTTT kiểm tra trùng trước khi tạo hồ sơ: gửi một bản ghi (có hoặc không có CCCD) và nhận ngay bản ghi vàng tương ứng.

::: dac-ta
**Mục tiêu.** Bên gọi biết chắc khi nào được dùng kết quả: `200` là khớp, `202` chưa có kết luận (không được ghi dữ liệu theo), `404` không khớp.

**Tác nhân chính.** HTTT, PH-04 `dh-runtime` (`mdm:resolve`).

**Tác nhân phụ.** PH-09, `pg-core`, nhật ký truy cập, DS (nhận mục hàng đợi).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-047.

**Truy vết.** REQ-06, REQ-09; BP-04, BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** Bộ quy tắc `ACTIVE`; mục đích PH-09 cho domain; hạn mức còn.

**Kích hoạt.** Gọi API-06-071.

**Đảm bảo tối thiểu.** Không đổi bản ghi vàng (trừ mục hàng đợi khi `LOOKUP_OR_QUEUE`); không lưu giá trị gửi lên.

**Đảm bảo thành công.** Trả `outcome` (`MatchOutcome`) kèm `goldenId`, điểm, phương thức, thuộc tính đã che.

**Luồng chính.**
1. Luồng PH-04 gửi `POST /domains/CITIZEN:resolve` với `attributes`, `mode = LOOKUP_ONLY`, `X-Purpose`.
2. Hệ thống kiểm scope, mục đích, hạn mức; chuẩn hóa tại chỗ, không lưu ứng viên.
3. Hệ thống đối sánh xác định rồi xác suất (UC-06-10 bước 1 đến 3).
4. `MATCH`: trả `200`, `goldenId = G-10234`, điểm 0,94, thuộc tính che theo mục đích.
5. Hệ thống ghi nhật ký truy cập; chỉ trả sau khi đã ghi (BR-06-010).

**Luồng thay thế.**
- **4a. `POSSIBLE_MATCH`.** Trả `202` kèm tối đa 3 ứng viên (`goldenId`, điểm, thuộc tính che); `LOOKUP_OR_QUEUE` thì tạo mục hàng đợi, trả `queueItemId`, phát EVT-06-08.
- **4b. `NO_MATCH`.** Trả `404` ERR-06-050 kèm `outcome = NO_MATCH`.

**Luồng ngoại lệ.**
- **E1. Thiếu thuộc tính tối thiểu (bước 2).** ERR-06-003 (400): "Cần ít nhất {n} thuộc tính để đối sánh: {danh sách}."
- **E2. Vượt hạn mức (bước 1).** ERR-06-048 (429): "Vượt hạn mức {n} lượt mỗi phút."
- **E3. Thiếu mục đích (bước 2).** ERR-06-037 (403): "Yêu cầu thiếu mục đích khai thác được chấp thuận cho dữ liệu này."
- **E4. Không ghi được nhật ký (bước 5).** ERR-06-039 (503): "Chưa ghi được nhật ký truy cập nên không trả dữ liệu."

**Quy tắc áp dụng.** BR-06-002, BR-06-010, BR-06-026.

**Màn hình, API.** Không có màn; API-06-071; kịch bản TS-06-22.
:::

```{.mermaid caption="Trình tự giải quyết trực tuyến khi luồng PH-04 làm giàu bản tin"}
sequenceDiagram
  participant R as dh-runtime luồng PH-04
  participant M as dh-data mdm-serve
  participant P9 as PH-09
  participant PG as pg-core
  participant A as Nhật ký truy cập
  R->>M: Resolve hồ sơ kèm X-Purpose (API-06-071)
  M->>P9: Kiểm mục đích và phạm vi thuộc tính
  P9-->>M: Cho phép fullName, dateOfBirth
  M->>PG: Đối sánh xác định rồi pg_trgm
  PG-->>M: MATCH 0,94
  M->>A: Ghi nhật ký truy cập
  A-->>M: Đã ghi
  M-->>R: 200 goldenId, thuộc tính che theo mục đích
```

Hình cho thấy dữ liệu chỉ rời `dh-data` sau khi mục đích được kiểm và nhật ký truy cập xác nhận đã ghi.

### 6.23. UC-06-23 · Xuất dữ liệu chủ có kiểm soát

::: dac-ta
**Mục tiêu.** Trích xuất dữ liệu chủ cho mục đích hợp pháp (thống kê, chuyển cơ quan có thẩm quyền) chỉ khi có phê duyệt, tối thiểu hóa trường, tệp mã hóa, thủy vân.

**Tác nhân chính.** DS (Lan) đề nghị; DO (Phúc) và DA (Hùng) chấp thuận.

**Tác nhân phụ.** PH-09 (mục đích), kho đối tượng, job `EXPORT`.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-049.

**Truy vết.** REQ-06, REQ-09; BP-10 đề nghị; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-export`; mục đích xuất được PH-09 ghi nhận.

**Kích hoạt.** Lan bấm "Đề nghị xuất" ở UI-06-15.

**Đảm bảo tối thiểu.** Chưa đủ chấp thuận thì không có tệp; tệp hết hạn sau 24 giờ.

**Đảm bảo thành công.** `ExportStatus = READY`, tệp mã hóa có thủy vân tải được trong 24 giờ; ghi vết đặc biệt (BR-06-013).

**Luồng chính.**
1. Lan chọn domain `ORGANIZATION`, trường `taxCode`, `legalName`, `ExportFormat = CSV`, mục đích, 5.000 bản ghi (API-06-073); trạng thái `PENDING_APPROVAL`.
2. Phúc (DO nguồn chủ quản) chấp thuận (API-06-075 `:approve`); Hùng (DA) chấp thuận; cả hai khác Lan.
3. Hệ thống đặt `APPROVED`, chạy job `EXPORT` (`GENERATING`), áp che theo phân loại, mã hóa, thủy vân.
4. Trạng thái `READY`; Lan tải qua API-06-076 trong 24 giờ.
5. Hệ thống ghi nhật ký truy cập, kiểm toán.

**Luồng thay thế.**
- **2a. ≤ 100 bản ghi chỉ trường `PUBLIC`, `INTERNAL`.** Chỉ cần DA duyệt.
- **2b. Từ chối.** `REJECTED` kèm lý do.

**Luồng ngoại lệ.**
- **E1. Vượt giới hạn hoặc chưa duyệt (bước 1, 4).** ERR-06-041 (422): "Yêu cầu xuất vượt {n} bản ghi hoặc chưa được chấp thuận."
- **E2. Tệp hết hạn (bước 4).** ERR-06-042 (410): "Tệp xuất đã hết hạn tải. Tạo đề nghị mới nếu còn cần."
- **E3. Tự chấp thuận (bước 2).** ERR-06-005 (403): "Anh/chị là người đề nghị nên không được tự chấp thuận."

**Quy tắc áp dụng.** BR-06-013, BR-06-026, BR-06-027, LP-06-01.

**Màn hình, API.** UI-06-15; API-06-073, 074, 075, 076; kịch bản TS-06-23.
:::

### 6.24. UC-06-24 · Đăng ký nhận cập nhật và phát sự kiện thay đổi bản ghi vàng

::: dac-ta
**Mục tiêu.** HTTT được báo khi bản ghi vàng mình quan tâm đổi, qua sự kiện không chứa giá trị thuộc tính (chỉ mã, phiên bản, tên thuộc tính đổi, nguồn gây đổi).

**Tác nhân chính.** TA, DS đề nghị thay HTTT; DO (Phúc) chấp thuận; hệ thống (outbox) phát.

**Tác nhân phụ.** PH-10 (topic, subscription), PH-09 (mục đích), HTTT nhận, PH-08.

**Mức ưu tiên.** M · Đợt 3 (FR-06-051 mức S).

**FR hiện thực.** FR-06-050, FR-06-051.

**Truy vết.** REQ-06, REQ-10; BP-04 (phát sự kiện bản ghi vàng); hệ cũ: không có.

**Tiền điều kiện.** HTTT `ACTIVE` ở PH-01; mục đích PH-09; topic `t68.mdm.*` đã cấp phát ở PH-10 (FR-10-067).

**Kích hoạt.** Lan bấm tab "Đăng ký nhận" ở UI-06-15; commit giao dịch có bản ghi outbox.

**Đảm bảo tối thiểu.** Sự kiện không mất: outbox giữ, phát lại khi Kafka sẵn sàng (BR-06-012).

**Đảm bảo thành công.** Đăng ký `ACTIVE` kèm subscription PH-10; sự kiện EVT-06-01…06 tới HTTT.

**Luồng chính.**
1. Lan đề nghị cho `HT-GIAODUC` nhận `SubscriptionScope = LINKED_ONLY` domain `CITIZEN` (API-06-078); `PENDING_APPROVAL`.
2. Phúc chấp thuận (API-06-079 `:approve`); hệ thống tạo subscription ở PH-10, đặt `ACTIVE`.
3. Bản ghi `G-10234` đổi; cùng giao dịch ghi outbox.
4. Hệ thống phát EVT-06-02 `t68.mdm.golden.updated.v1` gồm `goldenId`, `version`, tên thuộc tính đổi, nguồn gây đổi.
5. `HT-GIAODUC` nhận sự kiện, gọi tra cứu (UC-06-21) với mục đích đã chấp thuận để lấy giá trị.

**Luồng thay thế.**
- **2a. Tạm ngừng, tiếp tục, thu hồi (API-06-079).** Thu hồi cũng thu hồi subscription ở PH-10.
- **4a. Áp lại hàng loạt.** Gộp tối đa 500 `goldenId` mỗi sự kiện.
- **4b. Kafka không khả dụng.** Outbox giữ; quá 50 lần thử ERR-06-109, UI-06-18: "Có {n} sự kiện dữ liệu chủ chưa phát được quá {phút} phút."

**Luồng ngoại lệ.**
- **E1. HTTT thiếu mục đích hoặc thỏa thuận (bước 1).** ERR-06-043 (422): "HTTT {mã} chưa có mục đích khai thác dữ liệu chủ được chấp thuận."
- **E2. Tự chấp thuận (bước 2).** ERR-06-005 (403): "Anh/chị là người đề nghị nên không được tự chấp thuận."

**Quy tắc áp dụng.** BR-06-012, BR-06-026.

**Màn hình, API.** UI-06-15, UI-06-18; API-06-077, 078, 079; kịch bản TS-06-24.
:::

### 6.25. UC-06-25 · Đồng bộ với CSDL tổng hợp quốc gia và xử lý danh sách lệch

CSDL quốc gia là chuẩn cho thuộc tính thẩm quyền (BR-06-003); Datahub không ghi đè nguồn gốc và không gọi thẳng, mọi trao đổi qua PH-14 (BR-06-032). Tỷ lệ lệch cao bất thường thường là lỗi ánh xạ chứ không phải dữ liệu thật khác, nên đồng bộ tự dừng thay vì áp hàng loạt.

::: dac-ta
**Mục tiêu.** Bản ghi vàng luôn theo CSDL quốc gia cho nhân thân; tỉnh thấy ngay lệch bất thường và xử lý từng lệch có giải trình.

**Tác nhân chính.** Hệ thống theo lịch; DS (Lan), DA (Hùng), TA (`PERM-06-sync`).

**Tác nhân phụ.** PH-14, CSDL quốc gia (`QG-DANCU`, `QG-DKDN`), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-053, FR-06-054.

**Truy vết.** REQ-06, REQ-14; BP-06 (khai thác dữ liệu quốc gia); hệ cũ: LGC-NGSP-003, LGC-NGSP-005 liên quan gián tiếp (§5.3).

**Tiền điều kiện.** Kết nối PH-14 thông; nguồn `NATIONAL_DB` `ACTIVE`; đồng bộ không `PAUSED`.

**Kích hoạt.** Sự kiện thay đổi từ PH-14; lịch đối chiếu 00:30 hằng đêm; "Chạy đồng bộ" ở UI-06-14.

**Đảm bảo tối thiểu.** Thuộc tính thẩm quyền quốc gia không bị giữ giá trị địa phương; lệch vượt ngưỡng không được áp.

**Đảm bảo thành công.** `nationalSyncedAt` cập nhật; mỗi lệch có kết luận hoặc nằm trong danh sách xử lý.

**Luồng chính.**
1. Job `NATIONAL_RECONCILE` gửi lô khóa định danh qua PH-14, nhận giá trị quốc gia (API-06-081).
2. Hệ thống so với bản ghi vàng, ghi lệch phân `DiscrepancySeverity` (`CRITICAL` nhân thân, `MAJOR`, `MINOR`).
3. Tỷ lệ lệch ≤ `06.sync.pause-ratio` = 5%: lệch thuộc tính thẩm quyền áp tự động theo giá trị quốc gia (`NATIONAL_SYNC`), phát EVT-06-02; lệch khác vào danh sách; phát EVT-06-12.
4. Lan mở UI-06-14 tab "Danh sách lệch" (API-06-083), chọn 40 lệch `MINOR` ngày sinh, chọn `ACCEPT_NATIONAL` (API-06-084).
5. Hệ thống áp, cập nhật `DiscrepancyStatus`, biểu đồ tỷ lệ lệch theo thời gian.

**Luồng thay thế.**
- **3a. Tỷ lệ lệch > 5%.** Hệ thống chuyển `SyncState = PAUSED`, không áp, phát EVT-06-13, cảnh báo DA, TA (ERR-06-107).
- **4a. `REPORT_TO_NATIONAL`.** Gửi báo cáo qua PH-14 và tạo yêu cầu sửa tại nguồn địa phương; `IGNORE` cần lý do; `KEEP_LOCAL` chỉ cho thuộc tính địa phương.
- **5a. "Tiếp tục" sau tạm dừng (API-06-082).** DS, DA xác nhận đã điều tra, chọn áp hoặc bỏ các lệch của lượt dừng; "Áp tất cả theo quốc gia" cần DA xác nhận khi > 1.000 lệch.
- **1a. Chiều lên.** Job `NATIONAL_SYNC_UP` chỉ gửi thuộc tính trong `06.sync.up-attributes` (mặc định rỗng, Q06-02).

**Luồng ngoại lệ.**
- **E1. PH-14 không khả dụng (bước 1).** ERR-06-106; hàng chờ giữ; sau 24 giờ UI-06-14: "Chưa kết nối được dịch vụ quốc gia từ {thời điểm}. Tra cứu nội bộ vẫn hoạt động."
- **E2. Lệch vượt ngưỡng (3a).** ERR-06-107; UI-06-14, UI-06-01: "Đồng bộ tự động đã tạm dừng: tỷ lệ lệch {x}% vượt 5%. Điều tra trước khi tiếp tục."
- **E3. Dữ liệu quốc gia mâu thuẫn nội bộ (bước 2).** ERR-06-108; không áp, báo đơn vị quản lý qua PH-14.
- **E4. Chạy khi đang tạm dừng (bước 1).** ERR-06-044 (409): "Đồng bộ quốc gia đang tạm dừng do lệch vượt ngưỡng."
- **E5. Gửi lên thuộc tính không được phép (1a).** ERR-06-045 (422): "Thuộc tính {tên} không thuộc danh mục được gửi lên CSDL quốc gia."
- **E6. Giữ địa phương cho thuộc tính thẩm quyền (bước 4).** ERR-06-035 (422): "Thuộc tính {tên} thuộc thẩm quyền CSDL quốc gia, không giữ giá trị địa phương được."
- **E7. Bỏ qua thiếu lý do (4a).** ERR-06-007 (422): "Nhập lý do bỏ qua lệch (tối thiểu 20 ký tự)."

**Quy tắc áp dụng.** BR-06-003, BR-06-011, BR-06-014, BR-06-025, BR-06-032.

**Màn hình, API.** UI-06-14; API-06-080, 081, 082, 083, 084; kịch bản TS-06-25.
:::

```{.mermaid caption="Trình tự đối chiếu với CSDL quốc gia và tạm dừng khi lệch vượt ngưỡng"}
sequenceDiagram
  participant J as Job NATIONAL_RECONCILE
  participant P14 as PH-14
  participant QG as CSDL quốc gia
  participant M as dh-data
  actor DA
  J->>P14: Lô khóa định danh
  P14->>QG: Gọi dịch vụ dân cư
  QG-->>P14: Giá trị quốc gia
  P14-->>J: Kết quả
  J->>M: So với bản ghi vàng, ghi lệch
  alt Tỷ lệ lệch trên 5 phần trăm
    M->>M: Đồng bộ PAUSED, phát EVT-06-13
    M-->>DA: Cảnh báo, việc điều tra
  else Trong ngưỡng
    M->>M: Áp thuộc tính thẩm quyền, EVT-06-02
  end
```

Hình cho thấy quyết định tạm dừng nằm ở `dh-data` sau khi so sánh cả lượt, không phải áp từng bản ghi; áp hàng loạt khi lỗi ánh xạ sẽ làm hỏng dữ liệu trên diện rộng.

### 6.26. UC-06-26 · Vận hành: dashboard, lịch job và nhật ký

::: dac-ta
**Mục tiêu.** Lãnh đạo và vận hành thấy tình trạng dữ liệu chủ, lập lịch và chạy lại job, tra nhật ký xử lý và nhật ký truy cập.

**Tác nhân chính.** TO (Chi), TA; SO (Dũng), AU; DS, DA, VW xem dashboard.

**Tác nhân phụ.** PH-13 (chỉ số), PH-18, Quartz.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-055, FR-06-056, FR-06-057.

**Truy vết.** REQ-06, REQ-13, REQ-18; BP-07 (giám sát); hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-read` (dashboard, nhật ký xử lý), `PERM-06-operate` (lịch), `PERM-06-audit-read` (nhật ký truy cập).

**Kích hoạt.** Mở UI-06-01, UI-06-12 hoặc UI-06-18.

**Đảm bảo tối thiểu.** Số liệu cũ hơn 30 phút hiển thị nhãn thời điểm, không lỗi; nhật ký truy cập giữ 12 tháng trực tuyến, 5 năm WORM (BR-06-031).

**Đảm bảo thành công.** Lịch mới có hiệu lực ngay; job lỗi chạy lại từ bước dở; cảnh báo bất thường hiện đúng nơi.

**Luồng chính.**
1. Hùng mở UI-06-01 (API-06-085): số bản ghi vàng theo domain, tỷ lệ tự động 30 ngày, hàng đợi mở, precision, recall, trạng thái đồng bộ.
2. Chi mở UI-06-12 (API-06-086); sửa lịch `BATCH_MATCH` thành 02:00 Chủ nhật (API-06-087); hệ thống kiểm cron.
3. Job `FAILED`: Chi chạy lại với `fromStep = APPLYING` (API-06-044 `:rerun`); hệ thống tạo job mới tham chiếu job cũ.
4. Job chạy sai: Chi hủy (`:cancel`, lý do); Job K8s dừng, cặp đã áp giữ nguyên, hoàn tác được bằng `batchOperationId`.
5. Dũng mở UI-06-18, tra nhật ký truy cập theo `goldenId` (API-06-089); nhật ký xử lý ở API-06-088.

**Luồng thay thế.**
- **1a. VW.** Chỉ thấy số tổng hợp, không liên kết tới bản ghi.
- **5a. Chủ thể yêu cầu biết ai đã truy cập.** SO trích theo `goldenId` (UC-06-27).
- **5b. Truy cập bất thường.** > 100 bản ghi khác nhau trong 10 phút ghi vết đặc biệt (BR-06-013).

**Luồng ngoại lệ.**
- **E1. Lịch sai hoặc dày hơn 1 giờ (bước 2).** ERR-06-047 (422): "Lịch {cron} không hợp lệ hoặc dày hơn 1 giờ."
- **E2. Chạy lại khi kết quả đã xóa (bước 3).** ERR-06-006 (409): "Kết quả của job {id} đã hết hạn giữ. Chạy lại từ đầu."
- **E3. Không ghi được nhật ký truy cập (bước 5).** ERR-06-039 (503); vận hành thấy ở UI-06-18: "Ghi nhật ký truy cập thất bại {n} lần trong 5 phút."

**Quy tắc áp dụng.** BR-06-010, BR-06-013, BR-06-022, BR-06-031.

**Màn hình, API.** UI-06-01, UI-06-12, UI-06-18; API-06-041, 044, 085, 086, 087, 088, 089; kịch bản TS-06-26.
:::

### 6.27. UC-06-27 · Tiếp nhận và xử lý yêu cầu của chủ thể dữ liệu

::: dac-ta
**Mục tiêu.** Thực hiện quyền của công dân theo Luật BVDLCN đối với dữ liệu chủ: được biết dữ liệu và người truy cập, yêu cầu sửa (tại nguồn), yêu cầu hạn chế xử lý.

**Tác nhân chính.** DS (Lan), SO (Dũng), TA (`PERM-06-dsr`).

**Tác nhân phụ.** PH-09 (kênh tiếp nhận, chính sách), HTTT nguồn, chủ thể dữ liệu.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-058.

**Truy vết.** REQ-06, REQ-09; BP-10 đề nghị; CMP-LAW-05, CMP-LAW-04; hệ cũ: không có.

**Tiền điều kiện.** Yêu cầu có thông tin xác minh danh tính (qua PH-09 hoặc đối chiếu giấy tờ).

**Kích hoạt.** PH-09 chuyển yêu cầu; hoặc Lan tạo ở UI-06-16 khi công dân đến trực tiếp.

**Đảm bảo tối thiểu.** Hạn trả lời theo `06.dsr.sla-days` (giả định 10 ngày làm việc, Q06-01); dữ liệu chủ có nguồn thẩm quyền không bị xóa.

**Đảm bảo thành công.** Yêu cầu `COMPLETED` hoặc `FORWARDED_TO_SOURCE`; báo cáo lưu 5 năm.

**Luồng chính.**
1. Lan tạo yêu cầu `ACCESS` (API-06-090) kèm `verificationRef`; hệ thống đặt `RECEIVED`, tính `dueAt`.
2. Hệ thống tìm bản ghi vàng theo khóa; Lan xác nhận đúng người.
3. Hệ thống lập báo cáo: thuộc tính đang giữ (giá trị rõ cho chính chủ thể), nguồn từng thuộc tính, danh sách HTTT và mục đích đã truy cập 12 tháng.
4. Lan duyệt nội dung, hoàn thành (API-06-092 `:complete`); hệ thống báo PH-09 để trả lời công dân.
5. Quá hạn 2 ngày trước SLA hệ thống cảnh báo Dũng.

**Luồng thay thế.**
- **1a. `RECTIFICATION`.** Hệ thống xác định nguồn qua lineage; thuộc tính thẩm quyền quốc gia thì hướng dẫn tới cơ quan đăng ký; thuộc tính khác thì chuyển nguồn (`:forward`, `FORWARDED_TO_SOURCE`), phát EVT-06-15, có thể sửa tay tạm (UC-06-17).
- **1b. `RESTRICTION`.** Bản ghi `LOCKED` cờ `restricted`; PH-09 chỉ cho mục đích bắt buộc theo luật.
- **1c. Yêu cầu xóa.** PH-06 không xóa dữ liệu chủ có nguồn thẩm quyền; trả lời căn cứ pháp lý, chuyển PH-09 xử lý.
- **2a. Không có bản ghi.** Trả lời "không xử lý dữ liệu chủ về chủ thể", `COMPLETED`.

**Luồng ngoại lệ.**
- **E1. Chưa xác minh danh tính (bước 1).** ERR-06-046 (422): "Yêu cầu chưa có thông tin xác minh danh tính của chủ thể dữ liệu."
- **E2. Thiếu lý do từ chối (`:reject`).** ERR-06-007 (422): "Nhập lý do (tối thiểu 20 ký tự)."

**Quy tắc áp dụng.** BR-06-014, BR-06-030.

**Màn hình, API.** UI-06-16; API-06-090, 091, 092; kịch bản TS-06-27.
:::

### 6.28. UC-06-28 · Chính sách lưu giữ, dọn dữ liệu và tham số theo tenant

::: dac-ta
**Mục tiêu.** Giữ dữ liệu đủ lâu cho truy vết, hoàn tác, giải trình và không lâu hơn cần thiết với dữ liệu trung gian chứa DLCN; chỉnh ngưỡng vận hành trong miền cho phép.

**Tác nhân chính.** TA (Mai); job `RETENTION_PURGE`; PA đặt trần.

**Tác nhân phụ.** SO (giữ pháp lý), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-06-059, FR-06-060.

**Truy vết.** REQ-06, REQ-20; BP-10 đề nghị; CMP-LAW-05; hệ cũ: không có.

**Tiền điều kiện.** `PERM-06-config`.

**Kích hoạt.** Mai mở UI-06-17; job dọn 03:00 hằng ngày.

**Đảm bảo tối thiểu.** Đối tượng bị `legalHold` không bị dọn; không xóa bản ghi vàng (BR-06-007).

**Đảm bảo thành công.** Chính sách, tham số có hiệu lực kèm kiểm toán; dữ liệu hết hạn được `DELETE`, `ANONYMIZE` hoặc `ARCHIVE_COLD`.

**Luồng chính.**
1. Mai mở UI-06-17, tab "Lưu giữ" (API-06-093); sửa thời hạn giữ ứng viên đã liên kết (API-06-094).
2. Hệ thống kiểm không thấp hơn mức tối thiểu của loại đối tượng.
3. Mai mở tab "Tham số" (API-06-095), đổi `06.queue.sla-days` từ 7 sang 5 (API-06-096).
4. Hệ thống kiểm miền, ghi kiểm toán, áp ngay.
5. Job `RETENTION_PURGE` hằng ngày dọn ứng viên, kết quả đối sánh, staging quá hạn; ghi số liệu vào UI-06-12.

**Luồng thay thế.**
- **1a. Giữ pháp lý.** Mai đặt `legalHold` cho bản ghi hoặc nguồn khi có thanh tra; dừng dọn mọi dữ liệu liên quan.
- **3a. "Đặt lại mặc định"** cho một tham số.

**Luồng ngoại lệ.**
- **E1. Dưới mức tối thiểu (bước 2).** ERR-06-049 (422): "Thời hạn lưu {loại} không được thấp hơn {n} ngày."
- **E2. Giá trị ngoài miền (bước 4).** ERR-06-047 (422): "Giá trị {giá trị} của {khóa} ngoài miền {miền}."
- **E3. Sửa đồng thời (bước 4).** ERR-06-004 (409): "Tham số đã được người khác sửa. Tải lại để xem giá trị mới."
- **E4. Dọn gặp đối tượng giữ pháp lý (bước 5).** ERR-06-114; UI-06-12: "bỏ qua {n} đối tượng do giữ pháp lý".

**Quy tắc áp dụng.** BR-06-007, BR-06-020, BR-06-031.

**Màn hình, API.** UI-06-17, UI-06-12; API-06-093, 094, 095, 096; kịch bản TS-06-28.
:::

## 7. Luồng phụ dùng chung

Năm luồng phụ dưới đây lặp lại ở nhiều use case nên đặc tả một lần; bước ghi "theo LP-06-nn". Mã lỗi và câu thông báo vẫn ghi ở luồng ngoại lệ của use case dùng.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-06-01 | Bốn mắt: hệ thống so người duyệt với người đề nghị hoặc người quyết định ở bước trước; trùng thì khóa nút "Duyệt" và trả ERR-06-005 (403) nếu gọi thẳng API. DS và DA là cặp loại trừ trong tenant; áp dụng cả với TA. Duyệt cần ý kiến, từ chối cần lý do ≥ 20 ký tự (FR-00-071, ADR-046) | UC-06-03, 04, 09, 14, 15, 20, 23, 24, 25 |
| LP-06-02 | Lý do bắt buộc: quyết định và thao tác thủ công cần lý do ≥ 20 ký tự, thiếu thì ERR-06-007 (422) "Nhập lý do (tối thiểu 20 ký tự)." (BR-06-008) | UC-06-07, 13, 14, 17, 18, 19, 20, 25, 27 |
| LP-06-03 | Xung đột đồng thời: lệnh sửa mang `If-Match`, sai phiên bản trả ERR-06-004 (409); bản ghi đang `LOCKED` trả ERR-06-031 (409); mục đã có người nhận trả ERR-06-027 | UC-06-02, 08, 12, 13, 17, 19, 28 |
| LP-06-04 | Khai thác có mục đích: mọi lượt trả dữ liệu kiểm scope, mục đích PH-09 (ERR-06-037), che theo phân loại, vượt ngưỡng hàng loạt (ERR-06-038), ghi nhật ký truy cập trước khi trả (ERR-06-039). PH-09 không khả dụng thì chỉ trả `PUBLIC` kèm `X-Datahub-Masking: fallback` (FR-06-052) | UC-06-13, 16, 21, 22, 23, 24 |
| LP-06-05 | Phụ thuộc không khả dụng: PH-07 hoặc PH-09 trả ERR-06-021 (503), giữ nháp hoặc ứng viên và thử lại; PH-14 trả ERR-06-106, giữ hàng chờ, tra cứu nội bộ vẫn hoạt động | UC-06-02, 07, 25 |

: Luồng phụ dùng chung và use case dùng

## 8. Tổng hợp mã mới và đối chiếu

### 8.1. Mã mới và độ phủ

Tập này không tạo mã FR, BR, API, ERR, EVT, UI mới. Mã của tập: UC-06-01…28, LP-06-01…05, câu hỏi mở Q06-45…49; đề nghị kịch bản kiểm thử TS-06-01…28 ứng với UC-06-01…28 (1 − 1) cho D05-02-PH06. Cả 60 FR thuộc ít nhất một use case (§5.4). FR-06-052 là yêu cầu xuyên suốt, hiện thực ở UC-06-21 và LP-06-04, áp dụng cho mọi đường ra của UC-06-13, 16, 22, 23, 24. Mọi mã ERR, EVT, API, UI, PERM, enum và tham số `06.*` trong tập lấy đúng FRS §8.2, §9, §10.1 và Phụ lục A; câu thông báo lấy nguyên văn từ khối FR hoặc FRS §9.2.

### 8.2. Đề nghị cho FRS

| Mã | Nội dung | Nơi dùng |
|---|---|---|
| ĐN-UC-01 | FR-06-030 cho "sửa quyết định trong 24 giờ" nhưng §9.4 chỉ có `:decide`; đề nghị nêu `:reopen` hoặc quy định `:decide` ghi đè trong 24 giờ | UC-06-13 nhánh 3d |
| ĐN-UC-02 | Tab "Thao tác" của UI-06-03 chưa có API liệt kê thao tác theo bản ghi; đề nghị thêm `GET /domains/{domainCode}/golden-records/{goldenId}/operations` | UC-06-20 bước 1 |
| ĐN-UC-03 | FR-06-025 khóa tập nhãn (`locked`) nhưng chưa có API; đề nghị `POST /label-sets/{labelSetCode}:lock` | UC-06-09 bước 1 |
| ĐN-UC-04 | API-06-044 `:confirm` chưa nêu từ chối (`ApprovalDecision`) khi job `AWAITING_CONFIRMATION`; đề nghị tham số `decision` | UC-06-11 nhánh 4a |
| ĐN-UC-05 | FR-06-058 chưa có chức năng và API gỡ hạn chế xử lý (bản ghi `LOCKED` cờ `restricted` về `ACTIVE`) khi hết hạn chế | UC-06-27 nhánh 1b |
| ĐN-UC-06 | ERR-06-005 có bốn biến thể câu (người gửi duyệt, người đề nghị, người đề nghị hợp nhất, tự chấp thuận); đề nghị một câu tham số hóa hành động ở §9.2 | UC-06-03, 04, 14, 23 |
| ĐN-UC-07 | FR-06-026 chưa nêu bước tự tắt tự hợp nhất khi đánh giá tháng không đạt dù có tham số `06.match.auto-disable-on-fail`; đề nghị bổ sung luồng | UC-06-09 nhánh 4a |

: Đề nghị bổ sung cho FRS

### 8.3. Đề nghị đồng bộ cho tập khác

D03-06-PH06 lấy câu thông báo từ chương 6 và thêm câu cho ERR-06-003, 006 theo từng ngữ cảnh; D03-04-PH06 thêm ba API ở ĐN-UC-02, 03, 04; D05-02-PH06 dựng TS-06-nn ứng với UC-06-nn, luồng Splink và đồng bộ quốc gia dùng dữ liệu `T90…T99`; D02-08 xác nhận chín quyền mới và cặp loại trừ DS, DA.

## 9. Câu hỏi mở

> **Câu hỏi mở Q06-45:** UC-06-14 bước 2: khi tenant chỉ có một DA và chính DA đó là người đề nghị (TA có `PERM-06-merge`), hợp nhất rủi ro cao bị chặn vì ERR-06-005. Tập này giả định mục chờ quá 5 ngày giao DA khác của tenant, nếu không có thì chuyển lãnh đạo Sở KH&CN ngoài hệ thống; cần FRS chốt có DA dự phòng cấp tỉnh hay không.

> **Câu hỏi mở Q06-46:** UC-06-22 nhánh 4a: HTTT dùng `LOOKUP_OR_QUEUE` có thể làm đầy hàng đợi. Đề xuất hạn mức số mục hàng đợi do một nguồn tạo mỗi giờ, đặt trong `06.*`; cần FRS thêm tham số.

> **Câu hỏi mở Q06-47:** UC-06-20: khi hoàn tác hợp nhất, HTTT đã nhận EVT-06-03 và có thể đã hành động theo `goldenId` hợp nhất (cấp giấy tờ, ghi hồ sơ). Có cần thông báo riêng, hay chỉ EVT-06-04 là đủ; cần thống nhất với chủ quản dữ liệu.

> **Câu hỏi mở Q06-48:** UC-06-27 nhánh 1b: bản ghi `LOCKED` cờ `restricted` có tiếp tục nhận cập nhật từ nguồn và đồng bộ quốc gia không; đề xuất vẫn nhận cập nhật nhưng không cho khai thác ngoài mục đích bắt buộc theo luật; cần pháp chế xác nhận.

> **Câu hỏi mở Q06-49:** UC-06-06: tệp lô chứa DLCN (CCCD) tải qua trình duyệt máy cán bộ; thời gian lưu tệp gốc sau khi nạp và có bắt buộc truyền qua kênh quản lý của Trung tâm dữ liệu hay không. Đề xuất xóa tệp gốc sau 72 giờ, theo chính sách lưu giữ của UC-06-28.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-UC và K-TRINH-BAY: 28 use case phủ 60 FR, năm sơ đồ use case, sơ đồ trình tự cho bốn mắt, tách, resolve, đồng bộ quốc gia, job Splink, sơ đồ hoạt động cho đối sánh và hoàn tác; ma trận truy vết FR cũ, REQ, LGC |
