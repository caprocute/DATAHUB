---
ma_tai_lieu: D02-04-PH01
ten: Đặc tả use case phân hệ PH-01 Kết nạp hệ thống thông tin
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, quản trị tỉnh, kỹ sư dh-connect, kiểm thử viên
phan_he: PH-01
mo_ta: Đặc tả 34 use case của phân hệ Kết nạp hệ thống thông tin theo vòng đời thật của một HTTT thành viên ở tỉnh, từ lập hồ sơ, thẩm định, cấp và bàn giao định danh đến tạm ngừng, rà soát quyền và danh bạ đầu mối, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH01 FRS; D03-04-PH01 API; D03-06-PH01 Màn hình; D05-02-PH01 Test case
---

# D02-04-PH01 · Đặc tả use case Kết nạp hệ thống thông tin

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả 34 use case (UC) của PH-01 theo đúng thứ tự một hệ thống thông tin (HTTT) của sở, ngành, huyện, xã đi qua Datahub: đơn vị khai hồ sơ, quản trị tỉnh phân công và thẩm định, người có thẩm quyền phê duyệt, hệ thống cấp định danh SANDBOX và bàn giao một lần, đơn vị kiểm thử, quản trị tỉnh kích hoạt môi trường thật; sau đó là vận hành (xoay vòng, thay đổi hồ sơ, mở rộng phạm vi), tạm ngừng hoặc chấm dứt, rà soát quyền định kỳ và danh bạ đầu mối. Mỗi UC nêu ai làm, điều kiện đầu vào, từng bước kiểm chứng được, nhánh thay thế, nhánh lỗi kèm mã `ERR-01-nnn` và câu thông báo người dùng nhìn thấy.

**Phạm vi.** 34 UC phủ đủ 51 yêu cầu chức năng của [D02-03-PH01](../frs/D02-03-PH01-frs-ket-nap-httt.md): 41 FR mức M, 9 FR mức S và 1 FR mức C đều thuộc ít nhất một UC. Bốn UC có nhánh thuộc Đợt 2 (UC-01-25, UC-01-29 phần báo cáo, UC-01-30 phần xuất danh bạ, UC-01-34). Ba UC (UC-01-13, UC-01-25, UC-01-26) và một phần UC-01-27, UC-01-31 do hệ thống tự chạy nên tác nhân chính là `dh-connect`. Việc tạo client OAuth thuộc PH-12, cấu hình consumer và hạn mức thuộc PH-03, đăng ký sử dụng API thuộc PH-02; PH-01 chỉ điều phối và ghi nhận.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-03 (đầu mối kết nối, căn cứ khai thác dữ liệu), CMP-LAW-09 (chỉ HTTT đã kết nạp mới có định danh, mọi trao đổi qua LGSP), CMP-LAW-06 và CMP-LAW-08 (quản lý tài khoản, bí mật, rà soát quyền, nhật ký), CMP-LAW-05 (dữ liệu liên hệ đầu mối là dữ liệu cá nhân), CMP-LAW-01 (chia sẻ dữ liệu có căn cứ).

**Những điểm hội đồng cần lưu ý.** (1) Con người thẩm định trước khi máy cấp quyền: UC-01-10 buộc mỗi mục dữ liệu đề nghị có kết luận riêng (chấp thuận, thu hẹp, từ chối) và UC-01-12 chỉ tạo trần phạm vi từ các mục đã chấp thuận. (2) Thông tin xác thực chỉ đi qua một đường duy nhất là UC-01-15: liên kết dùng một lần, đúng đầu mối, đăng nhập hai yếu tố, bản sao bí mật bị hủy sau lần mở đầu. (3) Mọi điểm "bốn mắt" (lập, thẩm định, phê duyệt, kích hoạt, chấm dứt, xác nhận thao tác khẩn) đều có UC và mã lỗi `ERR-01-017` kiểm chứng được. (4) Cắt quyền khi có sự cố (UC-01-20 đến UC-01-22) đặt trạng thái và chặn ở cổng trước, gọi PH-12, PH-03 sau và thử lại; hiệu lực ≤ 60 giây (NFR-01-008). (5) Có năm câu hỏi mở (Q01-45…49) ở chương 9; hai câu (Q01-45, Q01-47) liên quan đến tenant nhỏ chỉ có một quản trị tỉnh.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Use case | 34 (UC-01-01…34), 5 nhóm: hồ sơ và thẩm định, định danh và bàn giao, vòng đời, rà soát và danh bạ, di trú và quản trị |
| FR được phủ | 51 trên 51 (M 41, S 9, C 1); UC-01-20 và UC-01-21 dùng chung FR-01-033 |
| Luồng chính, thay thế, ngoại lệ | 34 luồng chính, 105 nhánh thay thế, 158 nhánh ngoại lệ (đếm ở chương 6) |
| Luồng phụ dùng chung | 8 (LP-01-01…08) |
| Độ phủ mã của FRS | 88 trên 88 API, 17 trên 17 màn hình, 15 trên 15 sự kiện, 54 trên 54 mã lỗi `ERR-01-nnn` đều xuất hiện ở ít nhất một UC (API-01-087, 088 và ERR-01-051…054 do tập API bổ sung, đã đồng bộ ở bản 0.2) |
| Sơ đồ | 5 hình (4 hình use case theo nhóm, 1 hình đặt UC lên vòng đời HTTT), 2 sơ đồ trình tự |
| Câu hỏi mở | 5 (Q01-45…49) |

: Con số chính của tập use case PH-01

## 1. Giới thiệu

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các phân hệ khác và hệ thống bên ngoài để hoàn thành từng việc nghiệp vụ của PH-01. Phạm vi là toàn bộ FR-01-001…051. Chức năng dùng chung FR-00 (đăng nhập, phân quyền, hộp "Việc của tôi", thông báo, kiểm toán, xuất tệp) không đặc tả lại; bước nào dựa vào chúng ghi "tuân thủ FR-00-nnn". Hành vi chi tiết từng bước (kiểm tra, ngưỡng, bảng dữ liệu vào) ở FR tương ứng; UC mô tả trình tự và vai trò, nên một UC có thể gom nhiều FR (ví dụ UC-01-06 gồm FR-01-011 và FR-01-012). PH-01 không nằm trên đường dữ liệu: PH-01 ngừng hoạt động thì HTTT đã kết nạp vẫn trao đổi bình thường (NFR-01-007), nên các UC ở đây là việc quản trị và hành chính chứ không phải lưu lượng nghiệp vụ.

### 1.2. Người đọc

Bảng dưới trình bày người đọc.

| Người đọc | Phần cần đọc |
|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 4 (sơ đồ tổng), chương 5 (truy vết), chương chi tiết các UC mang bốn mắt và cắt quyền (UC-01-12, 15, 17, 20, 21, 22) |
| Quản trị tỉnh, cán bộ đầu mối | Chương 6, nhóm UC của vai trò mình (chương 3 chỉ ra UC theo tác nhân) |
| Kỹ sư dh-connect, giao diện, BFF | Chương 6, đối chiếu cột Màn hình, API và chương 7 (luồng phụ) |
| Kiểm thử viên | Chương 6: mỗi luồng chính, thay thế, ngoại lệ là một ca kiểm thử ở D05-02-PH01 |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và tài liệu tham chiếu

Thuật ngữ, chữ viết tắt (OR, TA, IE, SO, TO, DO, PA, PO, VW, AU), trạng thái HTTT (`DRAFT`, `SUBMITTED`, `APPROVED`, `ACTIVE`, `SUSPENDED`, `TERMINATED`, `REJECTED`) và khái niệm (hồ sơ kết nạp, trần phạm vi, bàn giao, kỳ rà soát) dùng chung với [D02-03-PH01](../frs/D02-03-PH01-frs-ket-nap-httt.md) §1.4 và §4, cùng D00-01. Tài liệu tham chiếu: D02-03-PH01 (FRS, nguồn của mọi mã lỗi, câu thông báo, quy tắc BR-01), D02-08 (ma trận phân quyền), D02-07 (thực thể DD-03, DD-04, DD-05), D03-04-PH01 (API), D03-06-PH01 (màn hình), D05-02-PH01 (ca kiểm thử), D03-07 (biện pháp SEC-23, 24, 25, 27, 33).

### 1.4. Cấu trúc tài liệu

Tài liệu đi từ quy ước đọc (chương 2) và tác nhân (chương 3) tới sơ đồ use case tổng (chương 4), bảng tổng hợp và truy vết (chương 5), đặc tả chi tiết 34 use case (chương 6), luồng phụ dùng chung (chương 7), tổng hợp mã và đối chiếu (chương 8), rồi câu hỏi mở (chương 9) và đề nghị đồng bộ (chương 10). Kỹ sư và kiểm thử viên đọc chương 5 để tìm use case theo FR, màn hình hay API, sau đó đọc đặc tả ở chương 6.

## 2. Quy ước đọc đặc tả

Mỗi UC đặc tả bằng một khối hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ (kèm câu thông báo), Quy tắc áp dụng, Màn hình và API. Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `3a`) và quay lại luồng chính trừ khi nêu khác. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh và kết thúc UC hoặc quay lại bước nêu rõ. Câu thông báo trong ngoặc kép lấy từ FRS §9.2; câu nào FRS chưa có thì ghi ở chương 10 để đồng bộ. Mức ưu tiên (M, S, C) và đợt (MVP, Đợt 2) theo FRS §5.

Dữ liệu ví dụ đều giả lập, tenant `T68`: **Lan** (OR, Sở Tư pháp, người lập hồ sơ), **Phúc** (đầu mối kỹ thuật, nhân sự nhà thầu của Sở Tư pháp), **Minh** (TA), **Quang** (TA thứ hai), **An** (IE), **Dũng** (SO), **Chi** (TO), **Hà** (PA), **Hoa** (AU), **Khôi** (đầu mối kỹ thuật của Văn phòng UBND). HTTT: `HT-HOTICH` (hộ tịch điện tử, đang kết nạp, hồ sơ `HS-KN-2026-0007`, mức Hạn chế nên dùng khóa công khai), `HT-QLVB` và `HT-DATDAI` (đã `ACTIVE`), `HT-TUPHAP` (HTTT của Sở Tư pháp đã kết nạp từ trước), `HT-DVC` (Cổng dịch vụ công, mức Nội bộ, còn dùng chuỗi bí mật trong giai đoạn chuyển tiếp, đầu mối kỹ thuật Khôi). Văn bản căn cứ và số liệu trong ví dụ là giả lập, không phải văn bản thật.

## 3. Tác nhân

Tác nhân người dùng vai trò chuẩn của D02-08; tác nhân hệ thống là phân hệ khác hoặc dịch vụ ngoài. Một người có thể giữ nhiều vai trò nhưng phải tuân theo bốn mắt (LP-01-02).

| Tác nhân | Loại | UC chính |
|---|---|---|
| ROLE-ORG_REQUESTER (OR, Lan) | Chính | 02…07, 11, 14, 16, 18, 19, 23, 24, 28, 30, 31 |
| Đầu mối kỹ thuật của HTTT (OR hoặc đầu mối đã khai, Phúc) | Chính | 14, 15, 18 |
| ROLE-TENANT_ADMIN (TA, Minh) | Chính | 01, 08, 10 (bước pháp lý), 12, 17, 20, 21, 22, 23, 24, 27, 29, 31, 32, 33 |
| ROLE-INTEGRATION_ENGINEER (IE, An) | Chính | 08 (nhận việc), 09 |
| ROLE-SECURITY_OFFICER (SO, Dũng) | Chính | 10 (bước ATTT), 20, 21, 22, 27, 29 |
| ROLE-TENANT_OPERATOR (TO, Chi) | Phụ | 07, 13, 16 (nhận cảnh báo, xem) |
| ROLE-DATA_OWNER (DO) | Phụ | 01 (xem hồ sơ có dữ liệu của tổ chức mình) |
| ROLE-VIEWER, ROLE-AUDITOR (VW, AU, Hoa) | Chính | 01, 29 (xem, xuất báo cáo), 30, 34 |
| ROLE-PLATFORM_ADMIN (PA, Hà) | Chính | 32, 33 |
| ROLE-PLATFORM_OPERATOR (PO) | Phụ | 08, 13, 16, 22 (nhận leo thang, cảnh báo) |
| `dh-connect` (bộ điều phối saga, tác vụ nền) | Chính (máy) | 13, 25, 26, 27, 31 |
| PH-02, PH-03, PH-04, PH-05, PH-10, PH-13, PH-14, PH-15 | Chính (máy) khi đọc bản sao; phụ ở UC khác | 26 (chính); nhiều UC (phụ) |
| PH-12 (Keycloak, OPA), OpenBao | Phụ | 13, 14, 15, 17, 18, 19, 20, 21, 22 |
| PH-18, PH-20, Kafka và Debezium, dịch vụ quét mã độc, kho đối tượng | Phụ | Nhiều UC |
| HTTT thành viên (hệ ngoài gọi API) | Phụ | 14, 16, 18 |

: Tác nhân của PH-01 và use case chính

## 4. Sơ đồ use case tổng

34 UC vượt ngưỡng đọc được trên một trang A4, nên sơ đồ tổng chia bốn hình theo nhóm nghiệp vụ (Hình 1 đến Hình 4); Hình 5 đặt các nhóm UC lên vòng đời của HTTT để thấy thứ tự thực hiện. Sơ đồ chỉ vẽ tác nhân chính; tác nhân phụ ở từng UC.

```{.mermaid caption="Use case lập hồ sơ, nộp và thẩm định (UC-01-01 đến UC-01-12)"}
flowchart LR
  OR([Cán bộ đầu mối OR])
  TA([Quản trị tỉnh TA])
  IE([Kỹ sư tích hợp IE])
  SO([Cán bộ ATTT SO])
  XEM([Người xem, kiểm toán])
  subgraph HS["Hồ sơ HTTT và đầu mối"]
    U01[UC-01-01 Tra cứu, xem, xuất]
    U02[UC-01-02 Tạo hồ sơ nháp]
    U03[UC-01-03 Khai năng lực kỹ thuật]
    U04[UC-01-04 Khai nhu cầu, tài liệu]
    U05[UC-01-05 Quản lý đầu mối]
    U06[UC-01-06 Kiểm tra và nộp]
    U07[UC-01-07 Tiến độ, rút, xóa]
  end
  subgraph THD["Thẩm định và phê duyệt"]
    U08[UC-01-08 Phân công, hạn, tham vấn]
    U09[UC-01-09 Thẩm định kỹ thuật]
    U10[UC-01-10 Thẩm định pháp lý, ATTT]
    U11[UC-01-11 Trả bổ sung, nộp lại]
    U12[UC-01-12 Phê duyệt, từ chối]
  end
  OR --> U02 & U03 & U04 & U05 & U06 & U07 & U11
  TA --> U01 & U02 & U08 & U10 & U12
  IE --> U09 & U08
  SO --> U10
  XEM --> U01
```

Hình 1 cho thấy đơn vị (OR) làm trọn nhóm hồ sơ, còn ba vai trò của tỉnh chia nhau nhóm thẩm định. TA xuất hiện ở bước phân công và phê duyệt; IE và SO chỉ ghi được kết luận cho bước được TA phân công (quy tắc OPA ở FRS §3.2). Không vai trò nào vừa lập hồ sơ vừa thẩm định rồi phê duyệt chính hồ sơ ấy (LP-01-02).

```{.mermaid caption="Use case định danh ứng dụng và bàn giao (UC-01-13 đến UC-01-19, UC-01-25)"}
flowchart LR
  OR([Đầu mối OR])
  TA([Quản trị tỉnh TA])
  DH([dh-connect])
  HT([HTTT thành viên])
  subgraph DD["Định danh và bàn giao"]
    U13[UC-01-13 Cấp định danh SANDBOX]
    U14[UC-01-14 Đăng ký khóa, ký CSR]
    U15[UC-01-15 Bàn giao một lần]
    U16[UC-01-16 Kiểm thử SANDBOX]
    U17[UC-01-17 Kích hoạt PRODUCTION]
  end
  subgraph VH["Vận hành định danh"]
    U18[UC-01-18 Xoay vòng]
    U19[UC-01-19 Xem, thu hồi, nhắc hạn]
    U25[UC-01-25 Tự vô hiệu, bật lại]
  end
  DH --> U13 & U19 & U25
  TA --> U13 & U17 & U18 & U19 & U25
  OR --> U14 & U15 & U16 & U18 & U19 & U25
  HT --> U16
```

Hình 2 gom tám UC xoay quanh định danh ứng dụng. UC-01-13 là use case máy: saga chạy sau phê duyệt, TA chỉ can thiệp khi saga lỗi. UC-01-15 là điểm duy nhất hiển thị bí mật; UC-01-17 là điểm duy nhất cấp định danh PRODUCTION.

```{.mermaid caption="Use case vòng đời thành viên (UC-01-20 đến UC-01-26)"}
flowchart LR
  OR([Đầu mối OR])
  TA([Quản trị tỉnh TA])
  SO([Cán bộ ATTT SO])
  PK(["PH-02, 03, 04, 05, 10, 13, 14, 15"])
  DH([dh-connect])
  subgraph VD["Tạm ngừng, chấm dứt, thay đổi"]
    U20[UC-01-20 Tạm ngừng, khôi phục]
    U21[UC-01-21 Chấm dứt tư cách]
    U22[UC-01-22 Xử lý khẩn của SO]
    U23[UC-01-23 Đề nghị thay đổi hồ sơ]
    U24[UC-01-24 Đề nghị mở rộng phạm vi]
  end
  subgraph DB["Đồng bộ"]
    U26[UC-01-26 Đồng bộ trạng thái, bản sao đọc]
  end
  TA --> U20 & U21 & U22 & U23 & U24
  SO --> U20 & U21 & U22
  OR --> U23 & U24
  DH --> U26
  PK --> U26
```

Hình 3 gom các thao tác thay đổi trạng thái sau khi HTTT hoạt động. SO và TA cùng thao tác cắt quyền, nhưng thao tác khẩn của SO (UC-01-22) luôn cần TA xác nhận bổ sung trong 24 giờ, còn chấm dứt thường (UC-01-21) cần người duyệt thứ hai. UC-01-26 nối PH-01 với mọi phân hệ khác qua sự kiện và bản sao đọc.

```{.mermaid caption="Use case rà soát quyền, danh bạ đầu mối, di trú và quản trị (UC-01-27 đến UC-01-34)"}
flowchart LR
  OR([Đầu mối OR])
  TA([Quản trị tỉnh TA])
  SO([Cán bộ ATTT SO])
  PA([Quản trị nền tảng PA])
  AU([Kiểm toán, người xem])
  DH([dh-connect])
  subgraph RS["Rà soát quyền định kỳ"]
    U27[UC-01-27 Mở kỳ, tổng hợp, kiểm tra căn cứ]
    U28[UC-01-28 Gửi xác nhận, đơn vị phản hồi]
    U29[UC-01-29 Xử lý kết quả, báo cáo]
  end
  subgraph DBA["Danh bạ đầu mối"]
    U30[UC-01-30 Tra cứu, xuất danh bạ]
    U31[UC-01-31 Cảnh báo thiếu đầu mối]
  end
  subgraph QT["Di trú và quản trị"]
    U32[UC-01-32 Nhập HTTT từ hệ cũ]
    U33[UC-01-33 Tham số phân hệ]
    U34[UC-01-34 Thống kê kết nạp]
  end
  TA --> U27 & U29 & U31 & U32 & U33
  SO --> U27 & U29
  OR --> U28 & U30 & U31
  AU --> U29 & U30 & U34
  PA --> U32 & U33
  DH --> U27 & U31
```

Hình 4 là nhóm hậu kiểm và hỗ trợ. Rà soát quyền (UC-01-27 đến UC-01-29) là cơ chế đặc quyền tối thiểu theo thời gian: quyền không dùng hoặc hết căn cứ bị thu hẹp. Danh bạ đầu mối là điều kiện để mọi UC gửi thư, nhắc việc hay bàn giao có người nhận; tổ chức thiếu đầu mối kỹ thuật không nộp được hồ sơ mới (UC-01-31, UC-01-06).

```{.mermaid caption="Các nhóm use case đặt trên vòng đời HTTT thành viên"}
flowchart TB
  A["Tạo hồ sơ nháp (DRAFT)<br/>UC-01-02, 03, 04, 05"] --> B["Kiểm tra và nộp (SUBMITTED)<br/>UC-01-06"]
  B --> C["Phân công, thẩm định<br/>UC-01-08, 09, 10"]
  C -->|"Thiếu thông tin<br/>UC-01-11"| A
  C --> D["Phê duyệt (APPROVED)<br/>UC-01-12"]
  D --> E["Cấp định danh SANDBOX, bàn giao, kiểm thử<br/>UC-01-13, 14, 15, 16"]
  E --> F["Kích hoạt PRODUCTION (ACTIVE)<br/>UC-01-17"]
  F --> G["Vận hành: xoay vòng, thay đổi, mở rộng, rà soát<br/>UC-01-18, 19, 23, 24, 25, 27, 28, 29"]
  G --> H["Tạm ngừng, chấm dứt (SUSPENDED, TERMINATED)<br/>UC-01-20, 21, 22"]
  H -->|"Khôi phục<br/>UC-01-20"| G
```

Hình 5 là bản đồ để đọc chương 6 theo thứ tự thời gian. Các UC xuyên suốt (UC-01-01 tra cứu, UC-01-07 tiến độ, UC-01-26 đồng bộ, UC-01-30, 31 danh bạ, UC-01-32 đến 34 quản trị) không gắn một trạng thái nên không vẽ vào hình.

## 5. Bảng tổng hợp use case và truy vết

### 5.1. Use case và FR

Bảng dưới liệt kê 34 UC cùng tác nhân chính, mức ưu tiên và FR hiện thực. Mức của UC lấy theo FR cao nhất mà UC hiện thực; cột FR ghi ba chữ số cuối của `FR-01-nnn`.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-01-01 | Tra cứu, xem chi tiết và xuất danh sách HTTT thành viên | Mọi vai trò có `PERM-01-read` | M | 001, 002, 050 |
| UC-01-02 | Tạo hồ sơ kết nạp nháp và sửa có tự lưu | OR, TA | M | 003, 004, 010 |
| UC-01-03 | Khai hồ sơ năng lực kỹ thuật và nhóm HTTT | OR, TA | M | 006 |
| UC-01-04 | Khai nhu cầu khai thác, căn cứ pháp lý và tài liệu đính kèm | OR, TA | M | 005, 007 |
| UC-01-05 | Quản lý đầu mối liên hệ của HTTT | OR, TA | M | 008 |
| UC-01-06 | Kiểm tra hợp lệ và nộp hồ sơ | OR, TA | M | 011, 012 |
| UC-01-07 | Theo dõi tiến độ, rút hồ sơ và xóa nháp | OR, TA | S | 009, 019 |
| UC-01-08 | Phân công, theo dõi hạn thẩm định và tham vấn | TA, IE, SO | M | 016 |
| UC-01-09 | Thẩm định kỹ thuật và tác động hạn mức quốc gia | IE | M | 013, 015 |
| UC-01-10 | Thẩm định căn cứ pháp lý và ATTT từng mục | TA, SO | M | 014 |
| UC-01-11 | Trả bổ sung và nộp lại hồ sơ | TA, IE, SO, OR | M | 017 |
| UC-01-12 | Phê duyệt hoặc từ chối kết nạp | TA | M | 018 |
| UC-01-13 | Cấp định danh SANDBOX sau phê duyệt (saga) | `dh-connect`, TA | M | 020 |
| UC-01-14 | Đăng ký khóa công khai hoặc yêu cầu ký chứng thư | Đầu mối kỹ thuật, TA | M | 021 |
| UC-01-15 | Nhận bàn giao thông tin xác thực một lần | Đầu mối kỹ thuật | M | 022 |
| UC-01-16 | Kiểm thử kết nối ở SANDBOX | OR, HTTT thành viên | M | 023 |
| UC-01-17 | Kích hoạt môi trường thật (PRODUCTION) | TA | M | 024 |
| UC-01-18 | Xoay vòng thông tin xác thực | OR, TA, SO | M | 025 |
| UC-01-19 | Xem danh sách, thu hồi định danh và nhắc hạn | OR, TA, `dh-connect` | M | 026, 027, 028 |
| UC-01-20 | Tạm ngừng và khôi phục HTTT | TA, SO | M | 029, 030, 033 |
| UC-01-21 | Chấm dứt tư cách thành viên | TA, SO | M | 031, 033 |
| UC-01-22 | Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT | SO, TA | M | 032 |
| UC-01-23 | Đề nghị thay đổi hồ sơ HTTT đã kết nạp | OR, TA | S | 034 |
| UC-01-24 | Đề nghị mở rộng trần phạm vi khai thác | OR, TA | M | 035 |
| UC-01-25 | Tự vô hiệu định danh không hoạt động và bật lại | `dh-connect`, TA | S (Đợt 2) | 036 |
| UC-01-26 | Đồng bộ trạng thái và cung cấp bản sao đọc cho phân hệ khác | `dh-connect`, PH-02…15 | M | 037, 038 |
| UC-01-27 | Mở kỳ rà soát, tổng hợp mức sử dụng, kiểm tra hiệu lực căn cứ | TA, SO, `dh-connect` | M | 039, 040, 043 |
| UC-01-28 | Gửi xác nhận cho đơn vị chủ quản và nhận phản hồi | TA, SO, OR | M | 041 |
| UC-01-29 | Xử lý kết quả rà soát và lập báo cáo | TA, SO | M | 042, 044 |
| UC-01-30 | Tra cứu và xuất danh bạ đầu mối | Mọi người dùng nội bộ; TA, AU (xuất) | M | 045, 047 |
| UC-01-31 | Cảnh báo tổ chức thiếu đầu mối và nhắc cập nhật | `dh-connect`, TA, OR | M | 046 |
| UC-01-32 | Nhập HTTT từ hệ cũ | TA, PA | M | 048 |
| UC-01-33 | Cấu hình tham số phân hệ theo tenant | TA, PA | M | 049 |
| UC-01-34 | Xem thống kê kết nạp và thời gian xử lý | TA, SO, VW, AU | S (Đợt 2) | 051 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Bảng dưới nối từng UC với màn hình (UI-01-nn) và API (API-01-nnn) của FRS §9.4 và §10.1. UC máy (UC-01-13, UC-01-26) chỉ có màn hình ở phần người dùng quan sát tiến độ.

| UC | UI | API |
|---|---|---|
| UC-01-01 | UI-01-03, 04 | API-01-001, 002, 003, 085, 088 |
| UC-01-02 | UI-01-01 | API-01-004, 005, 020, 021 |
| UC-01-03 | UI-01-01 | API-01-010, 011 |
| UC-01-04 | UI-01-01 | API-01-006, 007, 008, 009, 012, 013 |
| UC-01-05 | UI-01-01, 04 | API-01-014, 015, 016, 017 |
| UC-01-06 | UI-01-01 | API-01-022, 023 |
| UC-01-07 | UI-01-02, 04 | API-01-018, 019, 034 |
| UC-01-08 | UI-01-05, 06 | API-01-027, 028, 029, 030 |
| UC-01-09 | UI-01-06 | API-01-024, 026 |
| UC-01-10 | UI-01-06 | API-01-025 |
| UC-01-11 | UI-01-02, 06 | API-01-031, 023 |
| UC-01-12 | UI-01-07 | API-01-032, 033 |
| UC-01-13 | UI-01-08 | API-01-035, 036, 087; EVT-01-05 |
| UC-01-14 | UI-01-08 | API-01-037, 038 |
| UC-01-15 | UI-01-09 | API-01-039, 040, 041; EVT-01-09, 10 |
| UC-01-16 | UI-01-10 | API-01-042, 043 |
| UC-01-17 | UI-01-10 | API-01-044 |
| UC-01-18 | UI-01-08, 09, 11 | API-01-045, 046; EVT-01-06 |
| UC-01-19 | UI-01-04, 08, 11 | API-01-047, 048, 049, 050; EVT-01-07, 08 |
| UC-01-20 | UI-01-04, 11 | API-01-051, 052, 056 |
| UC-01-21 | UI-01-11 | API-01-053, 056, 059 |
| UC-01-22 | UI-01-11 | API-01-054, 055; EVT-01-15 |
| UC-01-23 | UI-01-04, 07 | API-01-057, 058, 059 |
| UC-01-24 | UI-01-04, 06 | API-01-060, 059; EVT-01-11 |
| UC-01-25 | UI-01-04 | API-01-061 |
| UC-01-26 | — | API-01-062, 063, 064; EVT-01-03, 04, 11 |
| UC-01-27 | UI-01-12 | API-01-065, 066, 067, 068, 073 |
| UC-01-28 | UI-01-12, 13 | API-01-069, 070, 071 |
| UC-01-29 | UI-01-12 | API-01-072, 074, 075, 088; EVT-01-12 |
| UC-01-30 | UI-01-14 | API-01-076, 077, 079, 088 |
| UC-01-31 | UI-01-14 | API-01-078; EVT-01-14 |
| UC-01-32 | UI-01-15 | API-01-080, 081, 082 |
| UC-01-33 | UI-01-16 | API-01-083, 084 |
| UC-01-34 | UI-01-17 | API-01-086 |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Bảng dưới nối UC với yêu cầu nghiệp vụ REQ (FRS §11.4), quy trình BP của D02-01 và chức năng hệ cũ LGC (FRS §11.1). Bốn mục LGC của PH-01 đều có UC nâng cấp tương ứng.

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-01-01 | REQ-01 | BP-01 | LGC-APIM-019 |
| UC-01-02, 03, 04, 05 | REQ-01 | BP-01 | LGC-APIM-020; LGC-HUB-010, LGC-HUB-011 (vai trò `PUBLISHER`, `SUBSCRIBER`, UC-01-02) |
| UC-01-06, 07 | REQ-01 | BP-01 | LGC-APIM-020 |
| UC-01-08, 10, 11, 12 | REQ-01 | BP-01 | LGC-APIM-020 |
| UC-01-09 | REQ-01, REQ-14 | BP-01 | LGC-APIM-020 |
| UC-01-13, 14, 15 | REQ-01, REQ-12 | BP-01 | LGC-APIM-020 |
| UC-01-16, 17 | REQ-01 | BP-01 | LGC-APIM-020 |
| UC-01-18, 19 | REQ-01, REQ-12 | BP-01, BP-07 | LGC-APIM-019 |
| UC-01-20, 21, 22 | REQ-01, REQ-13 | BP-07 | LGC-HUB-010, LGC-HUB-011 (tạm ngừng lan sang PH-10) |
| UC-01-23, 24 | REQ-01 | BP-01 | LGC-APIM-020 |
| UC-01-25 | REQ-01, REQ-12 | BP-07 | — |
| UC-01-26 | REQ-01, REQ-13 | BP-02, BP-04 | LGC-HUB-010, LGC-HUB-011 |
| UC-01-27, 28, 29 | REQ-01, REQ-12 | BP-07 | — |
| UC-01-30, 31 | REQ-01 | BP-01, BP-07 | — |
| UC-01-32 | REQ-01, REQ-22 | BP-08, BP-09 | LGC-APIM-019; LGC-APIM-020; LGC-HUB-010, LGC-HUB-011 |
| UC-01-33 | REQ-01 | BP-08 | — |
| UC-01-34 | REQ-01 | BP-01 | — |

: Use case, REQ, quy trình và hệ cũ

### 5.4. Độ phủ FR theo use case

Bảng dưới đối chiếu ngược: mỗi FR của FRS thuộc UC nào, để kiểm tra không FR nào bị bỏ sót. FR-01-033 dùng ở hai UC (tạm ngừng và chấm dứt).

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| FR-01-001 | UC-01-01 | FR-01-018 | UC-01-12 | FR-01-035 | UC-01-24 |
| FR-01-002 | UC-01-01 | FR-01-019 | UC-01-07 | FR-01-036 | UC-01-25 |
| FR-01-003 | UC-01-02 | FR-01-020 | UC-01-13 | FR-01-037 | UC-01-26 |
| FR-01-004 | UC-01-02 | FR-01-021 | UC-01-14 | FR-01-038 | UC-01-26 |
| FR-01-005 | UC-01-04 | FR-01-022 | UC-01-15 | FR-01-039 | UC-01-27 |
| FR-01-006 | UC-01-03 | FR-01-023 | UC-01-16 | FR-01-040 | UC-01-27 |
| FR-01-007 | UC-01-04 | FR-01-024 | UC-01-17 | FR-01-041 | UC-01-28 |
| FR-01-008 | UC-01-05 | FR-01-025 | UC-01-18 | FR-01-042 | UC-01-29 |
| FR-01-009 | UC-01-07 | FR-01-026 | UC-01-19 | FR-01-043 | UC-01-27 |
| FR-01-010 | UC-01-02 | FR-01-027 | UC-01-19 | FR-01-044 | UC-01-29 |
| FR-01-011 | UC-01-06 | FR-01-028 | UC-01-19 | FR-01-045 | UC-01-30 |
| FR-01-012 | UC-01-06 | FR-01-029 | UC-01-20 | FR-01-046 | UC-01-31 |
| FR-01-013 | UC-01-09 | FR-01-030 | UC-01-20 | FR-01-047 | UC-01-30 |
| FR-01-014 | UC-01-10 | FR-01-031 | UC-01-21 | FR-01-048 | UC-01-32 |
| FR-01-015 | UC-01-09 | FR-01-032 | UC-01-22 | FR-01-049 | UC-01-33 |
| FR-01-016 | UC-01-08 | FR-01-033 | UC-01-20, UC-01-21 | FR-01-050 | UC-01-01 |
| FR-01-017 | UC-01-11 | FR-01-034 | UC-01-23 | FR-01-051 | UC-01-34 |

: Độ phủ FR theo use case

## 6. Đặc tả chi tiết use case

Các mục dưới đây đặc tả từng UC theo khối 15 mục của chương 2, xếp theo năm nhóm: hồ sơ (6.1 đến 6.7), thẩm định và phê duyệt (6.8 đến 6.12), định danh và bàn giao (6.13 đến 6.19, 6.25), vòng đời (6.20 đến 6.24, 6.26), rà soát, danh bạ, di trú và quản trị (6.27 đến 6.34). Số mục 6.x trùng số UC để dễ tra.

### 6.1. UC-01-01 · Tra cứu, xem chi tiết và xuất danh sách HTTT thành viên

::: dac-ta
**Mục tiêu.** Người dùng tìm đúng HTTT, xem trọn hồ sơ trong đúng phạm vi quyền và xuất danh sách khi cần, mà không lộ sự tồn tại của đối tượng ngoài phạm vi.

**Tác nhân chính.** Mọi vai trò có `PERM-01-read`: TA (Minh), OR (Lan), AU (Hoa), SO, IE, VW; DO và OR chỉ thấy phạm vi của mình (○).

**Tác nhân phụ.** PH-02 (tab "API đang dùng"), PH-13 (lần dùng cuối của định danh), tác vụ xuất nền (FR-00-031).

**Mức ưu tiên.** M · MVP (FR-01-050 mức S).

**FR hiện thực.** FR-01-001, 002, 050.

**Truy vết.** REQ-01; BP-01; LGC-APIM-019 (Application nâng cấp thành HTTT thành viên).

**Tiền điều kiện.** Người dùng đã đăng nhập và chọn tenant `T68`; với xem chi tiết, HTTT tồn tại trong tenant.

**Kích hoạt.** Người dùng mở menu Kết nối & API › Hệ thống thành viên (UI-01-03) hoặc đường dẫn `/ket-noi/he-thong/{ma}`.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; đối tượng của tenant khác hoặc ngoài phạm vi vai trò trả như không tồn tại, cùng thân phản hồi (BR-01-030).

**Đảm bảo thành công.** Người dùng thấy danh sách, chi tiết đúng phạm vi quyền; bản xuất, nếu có, được ghi kiểm toán và không chứa thư điện tử, điện thoại, `secret_ref`, địa chỉ IP.

**Luồng chính.**

1. Minh mở UI-01-03. Hệ thống gọi API-01-001, hiển thị năm thẻ tổng (số HTTT theo trạng thái, nhóm, cờ cảnh báo) và danh sách 20 dòng đầu; HTTT có cờ cảnh báo xếp trước trong cùng trạng thái.
2. Minh bấm thẻ "Quá hạn rà soát". Hệ thống lọc ngay, ghi bộ lọc lên đường dẫn (FR-00-022); cờ này tính từ `lastReviewAt` quá 6 tháng.
3. Minh gõ "hộ tịch" vào ô tìm kiếm. Hệ thống trả các HTTT khớp tên hoặc mã, ví dụ `HT-HOTICH`.
4. Minh bấm dòng `HT-QLVB`. Hệ thống gọi API-01-002, trả hồ sơ kèm `ETag` và danh sách hành động khả dụng theo trạng thái và quyền (ví dụ "Tạm ngừng", "Xoay vòng").
5. Hệ thống hiển thị các tab Hồ sơ, Ứng dụng và thông tin xác thực (không có bí mật), Đầu mối, API đang dùng (từ PH-02), Phụ thuộc, Lịch sử (API-01-003); thư điện tử, điện thoại đầu mối hiện theo quyền (FR-00-034).
6. Minh bấm "Xuất Excel". Hệ thống kiểm tra phạm vi quyền (xuất toàn bộ tenant chỉ TA, AU, PA), dưới 5.000 dòng trả ngay qua API-01-085, ghi kiểm toán xuất kèm bộ lọc và số dòng.

**Luồng thay thế.**

- **1a. Người dùng là OR hoặc DO.** Lan chỉ thấy HTTT có `owner_org_id` là Sở Tư pháp; DO chỉ thấy HTTT có nhu cầu thuộc dữ liệu của tổ chức mình; số liệu thẻ tổng tính trong phạm vi đó.
- **2a. Lưu bộ lọc thường dùng.** Minh đặt tên "Quá hạn rà soát" và lưu (FR-00-024); lần sau chọn từ danh sách bộ lọc.
- **4a. Hồ sơ chưa duyệt xong.** Hồ sơ `SUBMITTED` mở chỉ đọc kèm khối tiến độ (UC-01-07); hồ sơ `DRAFT` mở thẳng trình hướng dẫn sửa (UC-01-02).
- **6a. Từ 5.000 dòng.** Hệ thống chạy nền theo FR-00-031 và thông báo khi tệp sẵn sàng.

**Luồng ngoại lệ.**

- **E1. Bộ lọc sai miền (bước 2).** ERR-01-003 (400); "Giá trị bộ lọc {tên} không hợp lệ."; giữ bộ lọc cũ.
- **E2. Không có kết quả (bước 3).** Danh sách rỗng; "Không có hệ thống nào khớp. Bỏ bớt bộ lọc hoặc bấm + Tạo hồ sơ."
- **E3. HTTT không thấy hoặc thuộc tenant khác (bước 4).** ERR-01-001 (404, cùng thân); "Không tìm thấy hệ thống {mã}."
- **E4. PH-02 không khả dụng (bước 5).** Tab "API đang dùng" báo "Chưa tải được danh sách API. Thử lại sau."; các tab khác vẫn hiển thị; ERR-01-046 ghi nhật ký.
- **E5. Không có dòng để xuất (bước 6).** `204`; "Không có dữ liệu để xuất."

**Quy tắc áp dụng.** BR-01-007, BR-01-030.

**Màn hình, API.** UI-01-03, 04; API-01-001, 002, 003, 085.
:::

### 6.2. UC-01-02 · Tạo hồ sơ kết nạp nháp và sửa có tự lưu

::: dac-ta
**Mục tiêu.** Đơn vị có một hồ sơ nháp cho HTTT mới với mã được giữ chỗ và số hồ sơ duy nhất, sửa nhiều lần mà không mất dữ liệu.

**Tác nhân chính.** ROLE-ORG_REQUESTER (Lan, Sở Tư pháp); TA (Minh) lập thay đơn vị.

**Tác nhân phụ.** PH-20 (danh mục tổ chức), PH-18 (mẫu văn bản, thông báo), kho đối tượng (tệp mẫu).

**Mức ưu tiên.** M · MVP (FR-01-010 mức S).

**FR hiện thực.** FR-01-003, 004, 010.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020; LGC-HUB-010, LGC-HUB-011 (vai trò `PUBLISHER`, `SUBSCRIBER` của HTTT).

**Tiền điều kiện.** Lan có `PERM-01-create` (○ Sở Tư pháp); tổ chức chủ quản có trong danh mục PH-20 và đang hoạt động.

**Kích hoạt.** Lan bấm "+ Tạo hồ sơ" ở UI-01-03, mở bước 1 của UI-01-01.

**Đảm bảo tối thiểu.** Nếu tạo không thành công thì mã HTTT không bị giữ; nội dung nháp đã lưu không mất khi mất kết nối.

**Đảm bảo thành công.** HTTT `HT-HOTICH` ở `DRAFT`, `revisionNo = 0`, số hồ sơ `HS-KN-2026-0007`; mã `HT-HOTICH` bị giữ vĩnh viễn (BR-01-018).

**Luồng chính.**

1. Lan mở UI-01-01 bước 1 và bấm "Tải mẫu văn bản". Hệ thống gọi API-01-020, 021 và trả mẫu đề nghị của `T68` (chưa có thì mẫu mặc định của nền tảng, FR-01-010); giao diện hiện gợi ý ngắn cạnh từng trường.
2. Lan nhập mã `HT-HOTICH`, tên "Hộ tịch điện tử Sở Tư pháp", tổ chức chủ quản "Sở Tư pháp", đơn vị vận hành "Trung tâm CNTT Sở Tư pháp", cấp độ ATTT `L3`, vai trò `CONSUMER`, địa chỉ cơ sở `https://hotich.t68.gov.vn`, dải IP cho phép `10.68.20.0/28`; bấm "Lưu và tiếp tục".
3. Hệ thống kiểm tra theo thứ tự: lược đồ (ERR-01-003), tổ chức tồn tại và hoạt động ở PH-20 (ERR-01-004), tổ chức khớp tổ chức của người nộp (ERR-01-006), mã chưa dùng kể cả HTTT đã chấm dứt hoặc bị từ chối (ERR-01-002), địa chỉ `https` và CIDR hợp lệ (ERR-01-049).
4. Hệ thống gọi API-01-004: tạo HTTT `DRAFT`, `revisionNo = 0`, sinh số hồ sơ `HS-KN-2026-0007`, ghi lịch sử, kiểm toán và outbox trong cùng giao dịch (BR-01-031); trả hồ sơ; giao diện chuyển sang bước 2.
5. Lan điền các bước tiếp (UC-01-05, 03, 04). Mỗi 30 giây khi có thay đổi, giao diện gửi API-01-005 kèm `If-Match`; hệ thống lưu, tăng `version`, trả `ETag` mới; màn hình hiện "Đã lưu 09:52".
6. Hệ thống chấp nhận thiếu trường bắt buộc ở nháp (chỉ kiểm sai dạng); thiếu sót được liệt kê ở UC-01-06.

**Luồng thay thế.**

- **2a. TA lập thay đơn vị.** Minh chọn tổ chức "Sở Tư pháp" trong `T68`; hồ sơ ghi `createdBy` là Minh và `onBehalfOf` là Sở Tư pháp; đầu mối của Sở vẫn là người nhận bàn giao sau này.
- **2b. Hồ sơ từ nhập hệ cũ.** UC-01-32 tạo hồ sơ `DRAFT` qua cùng quy tắc kiểm tra ở bước 3.
- **5a. Mất kết nối.** Giao diện giữ bản nháp cục bộ và báo "Chưa lưu được, đang thử lại"; khi nối lại gửi bản cục bộ kèm `ETag` cuối đã biết; nếu máy chủ đã đổi, hiện hộp so sánh để Lan chọn giữ bản nào.
- **5b. Hồ sơ bị trả bổ sung.** Các trường cần bổ sung tô đỏ kèm yêu cầu của người thẩm định (UC-01-11).

**Luồng ngoại lệ.**

- **E1. Mã đã dùng (bước 3).** ERR-01-002 (409); "Mã HT-HOTICH đã được dùng (kể cả hệ thống đã chấm dứt). Chọn mã khác."; quay lại bước 2.
- **E2. Tổ chức không có hoặc ngừng hoạt động (bước 3).** ERR-01-004 (422); "Tổ chức chủ quản không có trong danh mục hoặc đã ngừng hoạt động. Liên hệ quản trị tỉnh."
- **E3. Người nộp không thuộc tổ chức khai báo (bước 3).** ERR-01-006 (403); "Anh/chị không thuộc tổ chức {tên}. Chọn tổ chức của mình hoặc nhờ quản trị tỉnh lập hồ sơ."
- **E4. Địa chỉ không phải `https` hoặc IP sai dạng (bước 3).** ERR-01-049 (422); "Địa chỉ {giá trị} không hợp lệ. Chỉ nhận https và dải CIDR hợp lệ."
- **E5. Người khác đã sửa hồ sơ (bước 5).** ERR-01-007 (412); "Hồ sơ vừa được {tên} cập nhật lúc {giờ}. Xem khác biệt để quyết định giữ bản nào."
- **E6. Hồ sơ không còn `DRAFT` (bước 5).** ERR-01-005 (409); "Hồ sơ đã nộp, không sửa được. Dùng Rút hồ sơ nếu cần sửa."
- **E7. Không có mẫu cho mã yêu cầu (bước 1).** ERR-01-001 (404); "Không tìm thấy mẫu {mã}."

**Quy tắc áp dụng.** BR-01-018, BR-01-024, BR-01-031.

**Màn hình, API.** UI-01-01 (bước 1, 2); API-01-004, 005, 020, 021.
:::

### 6.3. UC-01-03 · Khai hồ sơ năng lực kỹ thuật và nhóm HTTT

::: dac-ta
**Mục tiêu.** Người thẩm định có đủ thông tin kỹ thuật (giao thức, số kết nối đồng thời, có API hay chỉ có CSDL) để xác nhận nhóm HTTT và chọn chiến lược bộ điều hợp ở PH-05.

**Tác nhân chính.** OR (Lan), TA (Minh) khi lập thay.

**Tác nhân phụ.** PH-05 (dùng số kết nối đồng thời và loại CSDL ở bước sau kết nạp).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-006.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** `HT-HOTICH` ở `DRAFT`; Lan có `PERM-01-create`.

**Kích hoạt.** Lan điền phần "Năng lực kỹ thuật" ở bước 3 của UI-01-01.

**Đảm bảo tối thiểu.** Dữ liệu sai miền không được lưu; nhóm xác nhận (`confirmedGroup`) không bị đổi.

**Đảm bảo thành công.** Hồ sơ kỹ thuật được lưu kèm `proposedGroup` và lời giải thích; `confirmedGroup` để trống cho người thẩm định.

**Luồng chính.**

1. Lan khai `systemKind`, công nghệ, `hasApi = true`, `apiSpecKind = OPENAPI`, `underMaintenance = true`, `replacementPlanned = false`, `criticality = NORMAL`, `maxConcurrentConnections = 20`, `expectedDailyCalls = 2000`, giờ vận hành "24/7, bảo trì CN 22:00"; bấm "Lưu".
2. Hệ thống gọi API-01-010, kiểm tra miền giá trị (sai: ERR-01-003 kèm danh sách lỗi theo trường).
3. Hệ thống tính nhóm đề xuất theo bảng quy tắc của FR-01-006 (thứ tự: sắp thay thế → nhóm 4; có API chuẩn còn bảo trì → nhóm 1; có API còn lại → nhóm 2; không API có CSDL → nhóm 3). Với ví dụ, `proposedGroup = 1` kèm lời giải thích "Có API chuẩn và còn bảo trì: kết nối trực tiếp."
4. Hệ thống lưu hồ sơ kỹ thuật và `proposedGroup`; để trống `confirmedGroup`; trả kết quả cho giao diện.
5. Giao diện hiển thị nhóm đề xuất và nhãn "Chờ người thẩm định xác nhận".

**Luồng thay thế.**

- **1a. HTTT không có API.** Lan khai `hasApi = false`, `dbType = ORACLE`; hệ thống đề xuất nhóm 3 và yêu cầu thêm `cdcLogEnabled` (`YES`, `NO`, `UNKNOWN`) để PH-05 chuẩn bị CDC.
- **3a. Hệ thống có kế hoạch thay thế.** `replacementPlanned = true` cho nhóm 4 kèm cảnh báo "Hệ thống có kế hoạch thay thế. Nên cân nhắc chờ hệ thống mới."; Lan vẫn tiếp tục được.
- **3b. Không đủ thông tin phân nhóm.** `proposedGroup = null`; Lan chọn "Đề nghị khảo sát trực tiếp"; lựa chọn ghi vào hồ sơ, không chặn nộp, người thẩm định sắp lịch khảo sát.

**Luồng ngoại lệ.**

- **E1. Số kết nối đồng thời không hợp lệ (bước 2).** ERR-01-003 (400); "Số kết nối đồng thời tối đa phải là số nguyên từ 1. Hỏi đơn vị vận hành hệ thống để biết giá trị này."
- **E2. Nhóm 3 thiếu loại CSDL (bước 2).** ERR-01-003 (400); "Hệ thống không có API cần khai loại CSDL để chuẩn bị bắt thay đổi dữ liệu."
- **E3. Hồ sơ không còn `DRAFT` (bước 2).** ERR-01-005 (409); "Hồ sơ đã nộp, không sửa được. Dùng Rút hồ sơ nếu cần sửa."

**Quy tắc áp dụng.** BR-01-025 (thay đổi sau kết nạp phân mức duyệt), BR-01-031.

**Màn hình, API.** UI-01-01 (bước 3); API-01-010, 011.
:::

### 6.4. UC-01-04 · Khai nhu cầu khai thác, căn cứ pháp lý và tài liệu đính kèm

::: dac-ta
**Mục tiêu.** Đơn vị nêu từng loại dữ liệu HTTT muốn khai thác hoặc cung cấp, kèm văn bản căn cứ cho từng dòng, để người thẩm định đánh giá theo mục thay vì duyệt cả gói.

**Tác nhân chính.** OR (Lan), TA (Minh) khi lập thay.

**Tác nhân phụ.** Danh mục loại dữ liệu của tenant (PH-07 hoặc PH-09, Q01-16), dịch vụ quét mã độc (DD-12), kho đối tượng.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-005, 007.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** `HT-HOTICH` ở `DRAFT`; Lan có `PERM-01-create`.

**Kích hoạt.** Lan thêm dòng ở bảng "Dữ liệu đề nghị" hoặc kéo thả tệp vào khu tải tài liệu của UI-01-01 bước 3.

**Đảm bảo tối thiểu.** Tệp nhiễm mã độc, sai định dạng hoặc quá cỡ không được lưu; dữ liệu thuộc danh mục bí mật nhà nước không vào hồ sơ (BR-01-004).

**Đảm bảo thành công.** Danh sách nhu cầu và tài liệu được cập nhật; mỗi dòng `CONSUME` có cờ "Thiếu căn cứ" nếu chưa đủ; chưa có kết luận thẩm định.

**Luồng chính.**

1. Lan chọn loại tài liệu `LEGAL_BASIS` và kéo tệp `QD-1234-UBND.pdf` (4 MB) vào khu tải. Hệ thống kiểm tra hồ sơ `DRAFT` (ERR-01-005) và cỡ tệp ≤ 20 MB theo `attachment.maxSizeMb` (ERR-01-012).
2. Hệ thống xác định kiểu tệp theo nội dung (Apache Tika), chỉ nhận PDF, DOCX, XLSX, PNG, JPG (ERR-01-013), gửi tệp quét mã độc (nhiễm hoặc không quét được: ERR-01-014).
3. Hệ thống lưu tệp vào bucket của tenant với mã hóa phía máy chủ, tính SHA-256, ghi `scanStatus = CLEAN`, trả mô tả tài liệu (API-01-007).
4. Lan thêm dòng nhu cầu: chiều `CONSUME`, loại dữ liệu "Thông tin công dân", phạm vi "Tra cứu theo số định danh", mức phân loại dự kiến `RESTRICTED`; nhập căn cứ: số "1234/QĐ-UBND", ngày 12/03/2026, cơ quan "UBND tỉnh T68", chọn tệp đã tải.
5. Hệ thống kiểm tra loại dữ liệu có trong danh mục (ERR-01-003) và không thuộc danh mục bí mật nhà nước (ERR-01-016), lưu dòng qua API-01-012; dòng thiếu căn cứ được lưu nhưng tô đỏ "Thiếu căn cứ".
6. Lan thêm dòng chiều `PROVIDE` "Dữ liệu hộ tịch" mức `INTERNAL`; dòng này không bắt buộc căn cứ nhưng bắt buộc mức phân loại.
7. Hệ thống trả danh sách dòng kèm cờ thiếu sót; Lan xem tệp qua liên kết ký 60 giây (API-01-008).

**Luồng thay thế.**

- **4a. Một văn bản cho nhiều dòng.** Lan chọn cùng tệp ở nhiều dòng; hệ thống không lưu lặp tệp.
- **6a. Xóa tài liệu.** Chỉ ở `DRAFT`, xóa mềm 30 ngày (FR-00-051, API-01-009); tài liệu đã được người thẩm định trích dẫn làm căn cứ ở vòng trước không xóa được, chỉ thay bản mới (ERR-01-005).
- **7a. Hồ sơ đang xem ở trạng thái khác.** Người xem có `PERM-01-read` vẫn tải được tài liệu ở mọi trạng thái trong phạm vi quyền.

**Luồng ngoại lệ.**

- **E1. Tệp quá cỡ (bước 1).** ERR-01-012 (413); "Tệp lớn hơn {n} MB. Nén hoặc chia nhỏ tệp."
- **E2. Định dạng không được phép (bước 2).** ERR-01-013 (415); "Chỉ nhận PDF, DOCX, XLSX, PNG, JPG."
- **E3. Quét mã độc không đạt (bước 2).** ERR-01-014 (422); "Tệp không qua kiểm tra an toàn và đã bị loại. Kiểm tra máy rồi tải lại."
- **E4. Dịch vụ quét hoặc kho tệp không khả dụng (bước 2, 3).** ERR-01-046 (503); "Dịch vụ lưu tệp tạm thời không khả dụng, tệp chưa được lưu. Thử lại sau."
- **E5. Dữ liệu thuộc danh mục bí mật nhà nước (bước 5).** ERR-01-016 (422); "Dữ liệu này thuộc danh mục bí mật nhà nước, không kết nối qua Datahub."; dòng không được lưu.
- **E6. Ngày ban hành văn bản sau ngày hiện tại (bước 5).** ERR-01-003 (400); lỗi hiện tại trường ngày.
- **E7. Căn cứ không đủ số, ngày, cơ quan (bước 7).** Lưu được; khi kiểm tra hợp lệ (UC-01-06) trả ERR-01-015 (422); "Mục {tên} chưa có căn cứ pháp lý. Bổ sung số, ngày, cơ quan ban hành văn bản cho phép khai thác."

**Quy tắc áp dụng.** BR-01-001, BR-01-004, BR-01-026, BR-01-031.

**Màn hình, API.** UI-01-01 (bước 3); API-01-006, 007, 008, 009, 012, 013.
:::

### 6.5. UC-01-05 · Quản lý đầu mối liên hệ của HTTT

::: dac-ta
**Mục tiêu.** Mỗi HTTT luôn có ít nhất một đầu mối kỹ thuật còn hoạt động, có tài khoản và thư điện tử công vụ, để mọi nhắc việc, cảnh báo và bàn giao có người nhận.

**Tác nhân chính.** OR (Lan), TA (Minh).

**Tác nhân phụ.** PH-12 (tìm tài khoản theo thư điện tử, DD-06), PH-18 (thông báo, thư bị trả lại).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-008.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT tồn tại, chưa `TERMINATED` hoặc `REJECTED`; người dùng có `PERM-01-create` (○).

**Kích hoạt.** Người dùng thêm, sửa, thay thế hoặc bỏ đầu mối ở UI-01-01 bước 2 hoặc tab Đầu mối của UI-01-04.

**Đảm bảo tối thiểu.** Không bao giờ bỏ đầu mối kỹ thuật cuối cùng của HTTT; không đầu mối nào có thư ngoài miền công vụ.

**Đảm bảo thành công.** Đầu mối được lưu ở DD-04 với cờ công khai đúng quy tắc; đầu mối cũ giữ lại ở trạng thái `INACTIVE`; EVT-01-13 đã phát.

**Luồng chính.**

1. Lan thêm đầu mối: loại `TECHNICAL`, họ tên "Phúc Hoàng", chức vụ "Kỹ sư hệ thống", thư `phuc.hoang@tuphap.t68.gov.vn`, điện thoại `+84912345678`, cờ công khai bật.
2. Hệ thống gọi API-01-015, kiểm tra thư thuộc miền trong `contact.allowedEmailDomains` (ERR-01-011), chưa trùng trong HTTT (ERR-01-003), điện thoại dạng `+84…` (ERR-01-003).
3. Hệ thống tìm tài khoản người dùng của `T68` có cùng thư điện tử: có thì gắn `userAccountId`; chưa có thì để trống và gắn cờ "Chưa có tài khoản" (cần có trước khi nhận bàn giao, UC-01-15, Q01-46).
4. Hệ thống áp quy tắc công khai: `SECURITY` luôn không công khai; `BUSINESS` và `TECHNICAL` mặc định công khai trong phạm vi tenant (BR-01-027).
5. Hệ thống lưu, ghi `lastConfirmedAt`, phát EVT-01-13 (chỉ mã HTTT và loại, không kèm dữ liệu liên hệ) và hiển thị đầu mối trong danh sách.
6. Lan thêm đầu mối `BUSINESS` "Hà Lê" và `SECURITY` "Khánh Phạm"; hồ sơ nay đủ ba loại đầu mối.

**Luồng thay thế.**

- **1a. Thay thế đầu mối.** Khi Phúc chuyển công tác, Lan chọn Phúc và nhập đầu mối mới; hệ thống thêm đầu mối mới, đặt Phúc `INACTIVE`, hủy liên kết bàn giao đang chờ nhắm tới Phúc (UC-01-15) và thông báo cho cả hai.
- **1b. Đổi đầu mối của HTTT `ACTIVE`.** Áp dụng ngay, không cần duyệt (BR-01-025 mức `NONE`), nhưng thông báo quản trị tỉnh.
- **1c. Sửa thông tin đầu mối.** Sửa họ tên, chức vụ, điện thoại bằng API-01-016; sửa thư điện tử chạy lại kiểm tra bước 2, 3.

**Luồng ngoại lệ.**

- **E1. Thư ngoài miền công vụ (bước 2).** ERR-01-011 (422); "Thư điện tử phải thuộc miền {danh sách}. Dùng thư công vụ của cơ quan."
- **E2. Bỏ hoặc vô hiệu đầu mối kỹ thuật cuối cùng (bước 1a, API-01-017).** ERR-01-050 (409); "HTTT phải còn ít nhất một đầu mối kỹ thuật. Thêm đầu mối mới trước khi bỏ người này."
- **E3. Điện thoại sai dạng (bước 2).** ERR-01-003 (400); "Số điện thoại cần theo dạng +84…"
- **E4. HTTT đã chấm dứt hoặc bị từ chối.** ERR-01-005 (409); không sửa đầu mối.

**Quy tắc áp dụng.** BR-01-013, BR-01-025, BR-01-027, BR-01-028.

**Màn hình, API.** UI-01-01 (bước 2), UI-01-04 (tab Đầu mối); API-01-014, 015, 016, 017.
:::

### 6.6. UC-01-06 · Kiểm tra hợp lệ và nộp hồ sơ

::: dac-ta
**Mục tiêu.** Hồ sơ chỉ vào hàng đợi thẩm định khi đã đủ điều kiện; đơn vị biết toàn bộ thiếu sót một lần, không bị từ chối từng lỗi nhỏ.

**Tác nhân chính.** OR (Lan), TA (Minh) có `PERM-01-submit`.

**Tác nhân phụ.** PH-20, kho tệp, PH-18 (thông báo), Kafka qua outbox.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-011, 012.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** `HT-HOTICH` ở `DRAFT`; chưa có hồ sơ khác đang xử lý cho cùng HTTT.

**Kích hoạt.** Lan bấm "Kiểm tra hợp lệ" ở bước 4 hoặc "Gửi duyệt" ở bước 5 của UI-01-01.

**Đảm bảo tối thiểu.** Hồ sơ không đủ điều kiện không bao giờ sang `SUBMITTED`; kiểm tra không có tác dụng phụ ngoài việc lưu kết quả gần nhất.

**Đảm bảo thành công.** `HT-HOTICH` ở `SUBMITTED`, `reviewStage = WAITING_ASSIGN`, `revisionNo = 1`, các bước thẩm định đã tạo với hạn; EVT-01-01 đã phát.

**Luồng chính.**

1. Lan bấm "Kiểm tra hợp lệ". Hệ thống gọi API-01-022 và chạy toàn bộ 13 kiểm tra của FR-01-011 mà không dừng ở lỗi đầu tiên.
2. Với mỗi thiếu sót, hệ thống ghi vị trí trường, mô tả, hướng dẫn và mức `ERROR` (chặn nộp) hoặc `WARNING` (cho nộp, báo người thẩm định); trả `valid`, `errorCount`, `warningCount`, `issues[]` và lưu kết quả kèm dấu thời gian.
3. Kết quả ví dụ: `errorCount = 1` ("Tải văn bản đề nghị có chữ ký lãnh đạo đơn vị theo mẫu ở phần Hướng dẫn."). Lan tải tệp `REQUEST_LETTER` (UC-01-04) rồi kiểm tra lại: `valid = true`, `warningCount = 0`.
4. Lan bấm "Gửi duyệt". Hệ thống hiện hộp xác nhận nêu người sẽ thẩm định và hạn dự kiến.
5. Hệ thống gọi API-01-023, kiểm tra trạng thái `DRAFT` (ERR-01-005), `If-Match` khớp (ERR-01-007), chạy lại FR-01-011 (còn `ERROR`: ERR-01-008 kèm đủ danh sách).
6. Hệ thống đặt `SUBMITTED`, `reviewStage = WAITING_ASSIGN`, tăng `revisionNo`, khóa nội dung; tạo bước `TECHNICAL` và `LEGAL` (luôn có), bước `SECURITY` vì `securityLevel = L3` và có nhu cầu mức `RESTRICTED`; mỗi bước có `dueAt` tính theo `review.slaWorkingDays` (2 ngày làm việc).
7. Hệ thống phát EVT-01-01, đưa việc vào hộp "Việc của tôi" của người nhận bước (UC-01-08) và thông báo Lan "Hồ sơ HS-KN-2026-0007 đã được tiếp nhận, hạn thẩm định dự kiến {ngày}".

**Luồng thay thế.**

- **3a. Chỉ có cảnh báo.** HTTT thuộc nhóm 4 hoặc chưa đủ thông tin phân nhóm: kết quả `WARNING`, vẫn nộp được; cảnh báo hiển thị cho người thẩm định.
- **5a. Nộp lại sau khi bị trả bổ sung.** Cùng luồng; hệ thống so sánh với vòng trước và giữ nguyên kết luận của bước mà dữ liệu liên quan không đổi (BR-01-032, UC-01-11).
- **1a. Hệ thống phụ thuộc không khả dụng.** Kiểm tra liên quan trả `WARNING` "Chưa kiểm tra được" thay vì chặn; ở bước 5, nếu vẫn chưa kiểm tra được mục bắt buộc thì chặn nộp (ERR-01-046).

**Luồng ngoại lệ.**

- **E1. Hồ sơ còn thiếu sót mức `ERROR` (bước 5).** ERR-01-008 (422); "Hồ sơ còn {n} thiếu sót. Xem danh sách và sửa trước khi nộp."; quay lại bước 1.
- **E2. Tổ chức còn HTTT khác thiếu đầu mối kỹ thuật (bước 1, 5).** ERR-01-010 (422); "Tổ chức còn hệ thống {mã} chưa có đầu mối kỹ thuật. Bổ sung đầu mối trước khi kết nạp hệ thống mới."
- **E3. Đã có hồ sơ khác đang xử lý cho cùng HTTT (bước 5).** ERR-01-009 (409); "Đã có hồ sơ {số hồ sơ} đang xử lý cho hệ thống này."
- **E4. Mục nhu cầu thiếu căn cứ, bí mật nhà nước, cấp độ ATTT thấp (bước 1, 5).** ERR-01-015, ERR-01-016, ERR-01-047 theo từng thiếu sót; câu thông báo như UC-01-04 và "Dữ liệu mức {mức} cần HTTT cấp độ từ {L} và xác thực bằng {phương thức}."
- **E5. Hồ sơ vừa bị người khác sửa (bước 5).** ERR-01-007 (412); "Hồ sơ vừa được {tên} cập nhật lúc {giờ}. Xem khác biệt để quyết định giữ bản nào."
- **E6. Danh mục tổ chức không khả dụng (bước 5).** ERR-01-046 (503); "Chưa kiểm tra được tổ chức chủ quản. Thử lại sau."; hồ sơ giữ `DRAFT`.
- **E7. Hồ sơ không còn `DRAFT` (bước 5).** ERR-01-005 (409); "Hồ sơ đã nộp, không sửa được. Dùng Rút hồ sơ nếu cần sửa."

**Quy tắc áp dụng.** BR-01-001, BR-01-004, BR-01-013, BR-01-017, BR-01-026, BR-01-028, BR-01-031, BR-01-032.

**Màn hình, API.** UI-01-01 (bước 4, 5); API-01-022, 023.
:::

### 6.7. UC-01-07 · Theo dõi tiến độ, rút hồ sơ và xóa nháp

::: dac-ta
**Mục tiêu.** Đơn vị biết hồ sơ đang chờ ai, bao lâu, bị trả vì lý do gì; và có thể rút hồ sơ chưa duyệt hoặc xóa nháp không cần nữa mà không mất bằng chứng thẩm định.

**Tác nhân chính.** OR (Lan), TA (Minh); IE, SO xem tiến độ.

**Tác nhân phụ.** PH-18 (thông báo, thư chỉ chứa liên kết), tác vụ dọn nháp.

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-01-009, 019.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** Có hồ sơ; để rút, hồ sơ `SUBMITTED` chưa có quyết định phê duyệt; để xóa, hồ sơ `DRAFT`.

**Kích hoạt.** Lan mở UI-01-02 từ danh sách hoặc từ liên kết trong thông báo; hoặc bấm "Rút hồ sơ", "Xóa hồ sơ"; hoặc tác vụ dọn nháp chạy hằng ngày.

**Đảm bảo tối thiểu.** Không xóa cứng hồ sơ đã nộp ít nhất một lần (BR-01-011); mã HTTT không dùng lại (BR-01-018).

**Đảm bảo thành công.** Người dùng thấy dòng thời gian đúng; hồ sơ rút về `DRAFT` kèm lý do hoặc hồ sơ nháp bị xóa mềm; người thẩm định không còn việc của hồ sơ đó.

**Luồng chính.**

1. Lan mở UI-01-02 của `HS-KN-2026-0007`. Hệ thống gọi API-01-034 và dựng dòng thời gian từ lịch sử trạng thái và các bước: nộp, phân công, thẩm định kỹ thuật, pháp lý, ATTT, phê duyệt, cấp định danh, bàn giao, kiểm thử, kích hoạt; mỗi mốc có thời điểm và thời gian ở bước.
2. Hệ thống hiển thị "đang chờ": vai trò (không hiển thị tên cá nhân người thẩm định), hạn dự kiến và trạng thái quá hạn hay chưa.
3. Lan thấy hồ sơ đang `IN_REVIEW`, bấm "Rút hồ sơ" vì phát hiện sai cấp độ ATTT; hệ thống hiện hộp xác nhận nêu hệ quả (FR-00-050).
4. Lan nhập lý do "Khai sai cấp độ ATTT, cần sửa và nộp lại". Hệ thống gọi API-01-019, kiểm tra trạng thái `SUBMITTED` (ERR-01-005), có lý do (ERR-01-033).
5. Hệ thống đóng các bước đang mở với kết quả `WITHDRAWN` (giữ lịch sử), chuyển `SUBMITTED → DRAFT`, ghi lý do, thông báo người thẩm định, phát EVT-01-03; việc biến mất khỏi hộp "Việc của tôi" của họ.
6. Mỗi lần hồ sơ đổi trạng thái, hệ thống gửi thông báo trong ứng dụng và thư chỉ chứa liên kết (FR-00-060 đến 062).

**Luồng thay thế.**

- **1a. Hồ sơ bị trả bổ sung.** Màn hình hiện danh sách yêu cầu bổ sung và các trường cần sửa (UC-01-11).
- **3a. Xóa hồ sơ nháp chưa từng nộp.** Lan bấm "Xóa hồ sơ"; hệ thống (API-01-018) xóa mềm hồ sơ cùng tài liệu, giữ 30 ngày để khôi phục (FR-00-051); mã vẫn bị giữ 30 ngày rồi giải phóng.
- **3b. Hồ sơ đã nộp ít nhất một lần bị xóa.** Không xóa cứng; sau 90 ngày không hoạt động ẩn khỏi danh sách mặc định, giữ bằng chứng thẩm định (BR-01-011).
- **3c. Tác vụ dọn nháp.** Hồ sơ nháp không cập nhật quá `draft.retentionDays` (90 ngày) bị xóa mềm; 14 ngày trước đó hệ thống nhắc người lập (BR-01-024).
- **6a. Đặt kênh nhận thông báo.** Người dùng chọn kênh theo FR-00-061.

**Luồng ngoại lệ.**

- **E1. Hồ sơ chưa từng nộp (bước 1).** Trang hiện "Hồ sơ chưa nộp. Hoàn tất các bước và bấm Gửi duyệt."
- **E2. Hồ sơ đã có quyết định (bước 4).** ERR-01-005 (409); "Hồ sơ đã có quyết định, không rút được."
- **E3. Thiếu lý do rút (bước 4).** ERR-01-033 (400); "Nhập lý do rút hồ sơ."
- **E4. Không thấy hồ sơ (bước 1).** ERR-01-001 (404); "Không tìm thấy hệ thống {mã}."

**Quy tắc áp dụng.** BR-01-011, BR-01-018, BR-01-024, BR-01-030.

**Màn hình, API.** UI-01-02, UI-01-04; API-01-018, 019, 034.
:::

### 6.8. UC-01-08 · Phân công, theo dõi hạn thẩm định và tham vấn

::: dac-ta
**Mục tiêu.** Mỗi bước thẩm định có đúng một người chịu trách nhiệm và một hạn xử lý; hồ sơ không nằm im quá hạn mà không ai hay, và đồng hồ hạn không chạy khi hồ sơ đang chờ đơn vị hoặc chờ ý kiến tham vấn.

**Tác nhân chính.** TA (Minh) phân công; IE (An), SO (Dũng) và người thẩm định pháp lý do TA chỉ định (Quang, TA thứ hai) nhận việc.

**Tác nhân phụ.** Hộp "Việc của tôi" (FR-00-070), PH-18 (thông báo, lịch nghỉ của tenant), PO (nhận leo thang).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-016.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `SUBMITTED`, `reviewStage = WAITING_ASSIGN`; có người đúng quyền cho từng loại bước (Q01-45).

**Kích hoạt.** Hồ sơ được nộp (UC-01-06) tạo việc; Minh mở hàng đợi UI-01-05; tác vụ nhắc việc chạy mỗi giờ.

**Đảm bảo tối thiểu.** Không giao việc cho người lập hoặc nộp hồ sơ; hồ sơ quá hạn luôn được nhắc và leo thang.

**Đảm bảo thành công.** Mỗi bước có `assigneeId`, `startedAt`, `dueAt`; `reviewStage = IN_REVIEW`; thời gian tham vấn được cộng vào `pausedMillis` và hạn dời tương ứng.

**Luồng chính.**

1. Sau khi nộp, ba bước của `HS-KN-2026-0007` xuất hiện trong "Việc của tôi" của mọi người có quyền làm bước đó: IE cho `TECHNICAL`, SO cho `SECURITY`, TA cho `LEGAL`. Hàng đợi UI-01-05 (API-01-027) hiện hồ sơ với hạn 2 ngày làm việc.
2. An bấm "Nhận việc" cho bước `TECHNICAL`. Minh gọi API-01-028 để giao bước `SECURITY` cho Dũng và bước `LEGAL` cho Quang (không giao cho chính mình vì Minh sẽ phê duyệt, UC-01-12).
3. Hệ thống kiểm tra người được giao không phải người lập hay nộp hồ sơ và có đúng quyền (ERR-01-017); đặt `reviewStage = IN_REVIEW`, ghi `assigneeId`, `startedAt`.
4. Tác vụ nhắc việc chạy mỗi giờ: dùng 80% hạn thì nhắc người xử lý; quá `review.slaWorkingDays` thì nhắc lần hai tới người xử lý và TA; quá `escalate.afterWorkingDays` (3 ngày làm việc) thì leo thang tới TA và PO và đánh dấu "Quá hạn" ở UI-01-03.
5. Dũng cần ý kiến của An về phương thức xác thực nên bấm "Tham vấn" (API-01-029), chọn An và nhập câu hỏi. Hệ thống đặt `reviewStage = CONSULTING`, ghi `pausedAt`.
6. An trả lời; Dũng bấm "Tiếp tục" (API-01-030). Hệ thống cộng `pausedMillis`, dời `dueAt` tương ứng và đặt lại `reviewStage = IN_REVIEW`.
7. Mọi tính toán ngày làm việc dùng lịch nghỉ của tenant ở PH-18.

**Luồng thay thế.**

- **2a. Phân công lại.** Minh đổi người xử lý; việc cũ biến mất khỏi hộp của người trước; lịch sử ghi người cũ, người mới.
- **1a. Chờ phân công quá 1 ngày làm việc.** Hệ thống nhắc Minh phân công.
- **4a. Hồ sơ đang bị trả bổ sung.** Đồng hồ hạn dừng trong thời gian hồ sơ ở `DRAFT`; hệ thống nhắc đơn vị sau 14 ngày (UC-01-11, BR-01-032).

**Luồng ngoại lệ.**

- **E1. Giao việc cho người lập hồ sơ (bước 2, 3).** ERR-01-017 (403); "Không giao được: người này đã lập hồ sơ."
- **E2. Bước đã đóng hoặc hồ sơ ở trạng thái khác (bước 2, 5, 6).** ERR-01-020 (409); "Bước thẩm định này đã đóng hoặc hồ sơ đang ở trạng thái khác."
- **E3. Người được hỏi tham vấn không có quyền xem hồ sơ (bước 5).** ERR-01-003 (400); "Chọn người có quyền xem hồ sơ này."

**Quy tắc áp dụng.** BR-01-017, BR-01-032.

**Màn hình, API.** UI-01-05, 06; API-01-027, 028, 029, 030.
:::

### 6.9. UC-01-09 · Thẩm định kỹ thuật và tác động hạn mức quốc gia

::: dac-ta
**Mục tiêu.** Kỹ sư tích hợp xác nhận nhóm HTTT, loại bộ điều hợp, hạn mức đề xuất và phương thức xác thực tối thiểu, đồng thời biết hồ sơ ảnh hưởng thế nào tới hạn mức dữ liệu quốc gia còn lại trước khi người có thẩm quyền phê duyệt.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An), được phân công bước `TECHNICAL`.

**Tác nhân phụ.** PH-14 (hạn mức quốc gia còn lại), PH-05 (nhận loại bộ điều hợp và số kết nối đồng thời sau kết nạp).

**Mức ưu tiên.** M · MVP (FR-01-015 mức S).

**FR hiện thực.** FR-01-013, 015.

**Truy vết.** REQ-01, REQ-14; BP-01; LGC-APIM-020.

**Tiền điều kiện.** Bước `TECHNICAL` còn mở, giao cho An; An không phải người lập hay nộp hồ sơ.

**Kích hoạt.** An mở việc từ "Việc của tôi" hoặc UI-01-05, vào tab Kỹ thuật của UI-01-06.

**Đảm bảo tối thiểu.** Không ghi kết luận nếu vi phạm bốn mắt hoặc chọn xác thực yếu hơn mức tối thiểu; PH-14 lỗi không chặn việc hoàn tất bước.

**Đảm bảo thành công.** Bước `TECHNICAL` có kết quả `PASS` hoặc `FAIL`, `confirmedGroup` đã lưu, EVT-01-02 đã phát.

**Luồng chính.**

1. An xem hồ sơ kỹ thuật của `HT-HOTICH`: nhóm đề xuất 1, giao thức REST, `maxConcurrentConnections = 20`, tài liệu OpenAPI đính kèm.
2. Hệ thống gọi API-01-026: xác định nhu cầu thuộc dịch vụ quốc gia ("Tra cứu thông tin công dân"), lấy hạn mức còn lại của `T68` từ PH-14 (ví dụ 1.000.000 lượt mỗi tháng), ước lượng mức dùng thêm 2.000 lượt/ngày × 30 ngày × hệ số cao điểm 1,5 (giả định) = 90.000 lượt, tức 9% hạn mức còn lại.
3. Hệ thống phân mức tác động `LOW` (< 20%; `MEDIUM` từ 20 đến 50%; `HIGH` trên 50%) và hiển thị gợi ý; An xác nhận nhóm (`confirmedGroup = 1`), chọn loại bộ điều hợp `REST`, hạn mức đề xuất 2.000 lượt/ngày, ước tính công sức 3 ngày-người.
4. Hệ thống tính phương thức xác thực tối thiểu theo mức phân loại cao nhất của nhu cầu: `RESTRICTED` bắt buộc `PRIVATE_KEY_JWT` hoặc `MTLS` (BR-01-019, SEC-24); An chọn `PRIVATE_KEY_JWT`; giao diện không cho chọn yếu hơn mức tối thiểu.
5. An chọn `PASS`, nhập ý kiến "Có API OpenAPI 3.0, đủ năng lực kết nối". Hệ thống gọi API-01-024, kiểm tra An không phải người lập hoặc nộp (ERR-01-017), bước còn mở (ERR-01-020), ghi bước, phát EVT-01-02 và cập nhật hộp việc.

**Luồng thay thế.**

- **2a. HTTT không có nhu cầu quốc gia.** Hệ thống ghi "Không áp dụng" và bỏ qua đánh giá hạn mức.
- **3a. Nhóm 3 (không có API).** An xác nhận HTTT cấp được quyền đọc nhật ký giao dịch (`cdcFeasible = YES`); nếu không, chọn `FALLBACK` và ghi phương án thay thế (truy vấn khai báo, tệp).
- **3b. Mức tác động `HIGH`.** Hệ thống cảnh báo hạn mức đề xuất vượt hạn mức quốc gia còn lại; An ghi đề nghị điều chỉnh hoặc xin nâng hạn mức; không chặn.
- **5a. Cần thêm thông tin từ đơn vị.** An dùng UC-01-11 (trả bổ sung) thay vì chọn `FAIL`.

**Luồng ngoại lệ.**

- **E1. An là người lập hoặc nộp hồ sơ (bước 5).** ERR-01-017 (403); "Anh/chị đã lập hoặc nộp hồ sơ này nên không thẩm định được."
- **E2. Bước đã đóng (bước 5).** ERR-01-020 (409); "Bước thẩm định này đã đóng hoặc hồ sơ đang ở trạng thái khác."
- **E3. Chọn `FAIL` thiếu nhóm hoặc ý kiến (bước 5).** ERR-01-019 (422); "Nhập nhóm HTTT đã xác nhận và ý kiến thẩm định."
- **E4. Chọn xác thực yếu hơn mức tối thiểu (bước 4, 5).** ERR-01-047 (422); "Dữ liệu mức {mức} bắt buộc xác thực bằng {phương thức}."
- **E5. PH-14 không khả dụng (bước 2).** ERR-01-046 (503) ghi nhật ký; "Chưa lấy được hạn mức quốc gia. Ghi nhận xét thủ công hoặc thử lại."; An vẫn hoàn tất bước, hồ sơ gắn nhãn "Chưa đánh giá hạn mức" cho người phê duyệt.

**Quy tắc áp dụng.** BR-01-016, BR-01-017, BR-01-019, BR-01-026.

**Màn hình, API.** UI-01-06 (tab Kỹ thuật); API-01-024, 026.
:::

### 6.10. UC-01-10 · Thẩm định căn cứ pháp lý và ATTT từng mục

::: dac-ta
**Mục tiêu.** Mỗi mục nhu cầu khai thác có một kết luận riêng (chấp thuận, chấp thuận thu hẹp, từ chối) do con người đưa ra; Cán bộ ATTT xác nhận cấp độ ATTT và phương thức xác thực. Quyền sau này của HTTT không bao giờ rộng hơn phạm vi được duyệt.

**Tác nhân chính.** Người thẩm định pháp lý (TA hoặc người TA phân công, ví dụ Quang); ROLE-SECURITY_OFFICER (Dũng) cho bước ATTT.

**Tác nhân phụ.** Cơ sở dữ liệu quốc gia về văn bản pháp luật (liên kết để tự kiểm chứng), danh mục bí mật nhà nước (Q01-08).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-014.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** Bước `LEGAL` hoặc `SECURITY` còn mở và giao cho người thẩm định; người đó không phải người lập hay nộp hồ sơ.

**Kích hoạt.** Người thẩm định mở tab "Pháp lý" hoặc "ATTT" của UI-01-06.

**Đảm bảo tối thiểu.** Việc thẩm định căn cứ do người thực hiện, không tự động hóa (BR-01-002); mục thuộc danh mục bí mật nhà nước chỉ có thể bị từ chối.

**Đảm bảo thành công.** Mọi mục có kết luận; bước ghi `PASS` hoặc `FAIL`; EVT-01-02 đã phát; trần phạm vi dự kiến hiện ở bản xem trước của người phê duyệt.

**Luồng chính.**

1. Quang xem tóm tắt hồ sơ và bảng nhu cầu; mở văn bản căn cứ "1234/QĐ-UBND ngày 12/03/2026" ngay ở khung bên phải, kèm liên kết tới cơ sở dữ liệu quốc gia về văn bản pháp luật để tự kiểm chứng hiệu lực.
2. Với mục "Thông tin công dân, tra cứu theo số định danh", Quang kiểm tra căn cứ còn hiệu lực và tương xứng phạm vi; chọn `NARROWED`, nhập phạm vi được duyệt "Tra cứu theo số định danh, không gồm lịch sử cư trú" và ý kiến.
3. Với mục "Lịch sử cư trú", Quang chọn `REJECTED` và nhập ý kiến "Văn bản không nêu thẩm quyền khai thác lịch sử cư trú".
4. Với mục thuộc danh mục bí mật nhà nước (nếu có), hệ thống vô hiệu nút "Chấp thuận" kèm giải thích; kết luận chỉ có thể `REJECTED`.
5. Quang bấm "Hoàn tất". Hệ thống gọi API-01-025 (`legal`), kiểm tra mọi mục đã có kết luận (ERR-01-018), mục thu hẹp có phạm vi và mục thu hẹp, từ chối có ý kiến (ERR-01-019), Quang không phải người lập hay nộp (ERR-01-017).
6. Hệ thống tính kết quả bước: có ít nhất một mục `APPROVED` hoặc `NARROWED` thì `PASS`; mọi mục `REJECTED` thì `FAIL` kèm đề xuất từ chối cho người phê duyệt; ghi bước, phát EVT-01-02, đưa trần phạm vi dự kiến (một mục `NARROWED`) vào bản xem trước.
7. Dũng mở tab ATTT, đối chiếu cấp độ ATTT khai báo `L3` với quyết định phê duyệt cấp độ "88/QĐ-STTTT ngày 05/01/2026" (số liệu giả lập), xác nhận phương thức xác thực `PRIVATE_KEY_JWT` khớp BR-01-019; chọn `PASS` (API-01-025 `security`).

**Luồng thay thế.**

- **2a. Căn cứ chưa rõ.** Quang dùng UC-01-11 và nêu cụ thể cần bổ sung gì.
- **2b. Cần ý kiến chuyên môn khác.** Quang dùng tham vấn ở UC-01-08; đồng hồ hạn tạm dừng trong thời gian tham vấn.
- **2c. Chấp thuận nguyên văn.** Chọn `APPROVED`; không bắt buộc ý kiến.
- **7a. Cấp độ ATTT thấp hơn yêu cầu.** Dũng chọn `FAIL` kèm điều kiện cần đáp ứng, hoặc dùng UC-01-11 để đơn vị cập nhật cấp độ.

**Luồng ngoại lệ.**

- **E1. Còn mục chưa đánh giá (bước 5).** ERR-01-018 (422); "Còn {n} mục chưa có kết luận. Đánh giá hết các mục rồi hoàn tất."
- **E2. Thu hẹp thiếu phạm vi hoặc thu hẹp, từ chối thiếu ý kiến (bước 5).** ERR-01-019 (422); "Mục {tên}: nhập {phạm vi được duyệt | ý kiến}."
- **E3. Chấp thuận dữ liệu bí mật nhà nước (bước 4).** ERR-01-016 (422); "Dữ liệu thuộc danh mục bí mật nhà nước, chỉ được từ chối."
- **E4. Người thẩm định đã lập hoặc nộp hồ sơ (bước 5).** ERR-01-017 (403); "Anh/chị đã tham gia hồ sơ này nên không thực hiện được bước này. Nhờ người khác."
- **E5. Xác nhận phương thức xác thực yếu hơn mức tối thiểu (bước 7).** ERR-01-047 (422); "Dữ liệu mức {mức} bắt buộc xác thực bằng {phương thức}."
- **E6. Bước đã đóng (bước 5, 7).** ERR-01-020 (409); "Bước thẩm định này đã đóng hoặc hồ sơ đang ở trạng thái khác."

**Quy tắc áp dụng.** BR-01-001, BR-01-002, BR-01-003, BR-01-004, BR-01-017, BR-01-019, BR-01-026.

**Màn hình, API.** UI-01-06 (tab Pháp lý, ATTT); API-01-025.
:::

### 6.11. UC-01-11 · Trả bổ sung và nộp lại hồ sơ

::: dac-ta
**Mục tiêu.** Người xử lý đòi đơn vị bổ sung đúng chỗ thiếu mà không làm mất công thẩm định đã làm; đơn vị sửa rồi nộp lại, chỉ phần có thay đổi bị thẩm định lại.

**Tác nhân chính.** Người thẩm định được phân công (An, Dũng, Quang) hoặc TA (Minh) trả; OR (Lan) nộp lại.

**Tác nhân phụ.** PH-18 (thông báo kèm danh sách yêu cầu).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-017.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `SUBMITTED` có bước thẩm định còn mở hoặc đang chờ phê duyệt.

**Kích hoạt.** Quang bấm "Trả bổ sung" ở UI-01-06 hoặc Minh bấm ở UI-01-07.

**Đảm bảo tối thiểu.** Nội dung hồ sơ giữ nguyên; lịch sử các bước giữ lại (kết quả `RETURNED`).

**Đảm bảo thành công.** HTTT về `DRAFT` kèm `returnReason` và danh sách yêu cầu; sau khi nộp lại `revisionNo` tăng, bước có dữ liệu không đổi giữ kết luận.

**Luồng chính.**

1. Quang nêu yêu cầu bổ sung gắn với trường: "Bổ sung số và ngày văn bản cho phép khai thác dữ liệu hộ khẩu" (mục "Thông tin công dân").
2. Hệ thống gọi API-01-031, kiểm tra có ít nhất một yêu cầu (ERR-01-033) và bước còn mở (ERR-01-020).
3. Hệ thống đóng mọi bước đang mở với kết quả `RETURNED`, chuyển `SUBMITTED → DRAFT`, ghi `returnReason`, mở khóa nội dung, thông báo Lan kèm danh sách yêu cầu và phát EVT-01-02.
4. Lan mở hồ sơ: các trường liên quan tô đỏ kèm yêu cầu của Quang. Lan sửa (UC-01-02, UC-01-04); thời gian hồ sơ ở `DRAFT` không tính vào hạn thẩm định; hệ thống nhắc sau 14 ngày chưa nộp lại.
5. Lan nộp lại bằng UC-01-06 (API-01-023). `revisionNo` tăng lên 2; hệ thống so với vòng trước, giữ kết luận bước `TECHNICAL` và `SECURITY` vì dữ liệu liên quan không đổi; chỉ bước `LEGAL` thẩm định lại, hạn mới 2 ngày làm việc.

**Luồng thay thế.**

- **1a. Người phê duyệt yêu cầu bổ sung ở một cấp cụ thể.** Minh ghi rõ `stepType = LEGAL`; khi nộp lại, chỉ bước đó thẩm định lại, các bước còn lại giữ kết luận nếu dữ liệu không đổi.
- **4a. Đơn vị không nộp lại.** Sau 14 ngày hệ thống nhắc; nếu hồ sơ nháp quá 90 ngày không cập nhật thì bị xóa mềm theo UC-01-07.

**Luồng ngoại lệ.**

- **E1. Không có yêu cầu cụ thể (bước 2).** ERR-01-033 (400); "Nêu ít nhất một nội dung cần bổ sung."
- **E2. Hồ sơ không ở giai đoạn thẩm định (bước 2).** ERR-01-020 (409); "Bước thẩm định này đã đóng hoặc hồ sơ đang ở trạng thái khác."
- **E3. Nộp lại còn thiếu sót (bước 5).** ERR-01-008 (422); "Hồ sơ còn {n} thiếu sót. Xem danh sách và sửa trước khi nộp."

**Quy tắc áp dụng.** BR-01-017, BR-01-032.

**Màn hình, API.** UI-01-02, 06; API-01-031, 023.
:::

### 6.12. UC-01-12 · Phê duyệt hoặc từ chối kết nạp

::: dac-ta
**Mục tiêu.** Người có thẩm quyền quyết định cuối cùng dựa trên kết luận từng mục; quyết định phê duyệt tạo ra trần phạm vi bằng đúng phạm vi được duyệt và khởi động việc cấp định danh SANDBOX.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Minh), không phải người lập, nộp hay thẩm định hồ sơ này.

**Tác nhân phụ.** PH-12 (xác thực lại hai yếu tố), bộ điều phối saga của `dh-connect` (UC-01-13), PH-18.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-018.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `SUBMITTED`, `reviewStage = WAITING_APPROVAL`, mọi bước thẩm định có kết luận; Minh có `PERM-01-approve`.

**Kích hoạt.** Minh mở việc "Duyệt kết nạp" ở UI-01-07 qua hộp "Việc của tôi".

**Đảm bảo tối thiểu.** Không có quyết định nếu vi phạm bốn mắt hoặc chưa xác thực lại hai yếu tố; không bao giờ tạo trần rộng hơn phạm vi được duyệt (BR-01-003).

**Đảm bảo thành công.** HTTT `APPROVED`, `provisionStage = PROVISIONING`, trần phạm vi (EN-01-04) đã tạo, lịch sử, kiểm toán và outbox ghi cùng giao dịch, EVT-01-03 đã phát.

**Luồng chính.**

1. Minh mở UI-01-07. Hệ thống hiển thị tóm tắt: HTTT, tổ chức, cấp độ ATTT `L3`, nhóm 1, trần phạm vi sẽ cấp (một mục `NARROWED`), phương thức xác thực tối thiểu `PRIVATE_KEY_JWT`, hạn mức 2.000 lượt/ngày, tác động hạn mức quốc gia `LOW`, ý kiến ba bước thẩm định.
2. Minh chọn "Duyệt". Hệ thống yêu cầu xác thực lại hai yếu tố trong 5 phút (LP-01-01).
3. Hệ thống gọi API-01-032 và kiểm tra bốn mắt: Minh khác Lan (người lập, nộp) và khác An, Quang, Dũng (người thẩm định) (LP-01-02).
4. Hệ thống tạo trần phạm vi từ các mục `APPROVED`, `NARROWED`, chuyển `SUBMITTED → APPROVED`, đặt `provisionStage = PROVISIONING`, ghi lịch sử, kiểm toán và outbox cùng giao dịch (BR-01-031) rồi phát EVT-01-03 (và EVT-01-11 cho trần phạm vi mới).
5. Hệ thống thông báo Lan "HTTT HT-HOTICH đã được phê duyệt, đang cấp định danh thử"; saga UC-01-13 bắt đầu.

**Luồng thay thế.**

- **2a. Từ chối.** Minh chọn "Từ chối" và nhập lý do "Căn cứ pháp lý không đủ cho mọi mục"; hệ thống (API-01-033) chuyển `SUBMITTED → REJECTED`, thông báo đơn vị kèm lý do và hướng lập hồ sơ mới (mã `HT-HOTICH` không dùng lại, BR-01-018).
- **1a. Cần bổ sung.** Minh dùng UC-01-11 để trả hồ sơ.
- **1b. Quá hạn phê duyệt.** Sau `approve.slaWorkingDays` (1 ngày) hệ thống nhắc Minh, leo thang theo UC-01-08.

**Luồng ngoại lệ.**

- **E1. Người duyệt đã lập, nộp hoặc thẩm định hồ sơ (bước 3).** ERR-01-017 (403); "Anh/chị đã tham gia hồ sơ này nên không duyệt được. Nhờ người khác." Với tenant chỉ có một TA, xem Q01-47.
- **E2. Hồ sơ chưa đủ kết luận (bước 1, 3).** ERR-01-020 (409); "Hồ sơ chưa đủ kết luận thẩm định."
- **E3. Từ chối thiếu lý do (bước 2a).** ERR-01-033 (400); "Nhập lý do từ chối."
- **E4. Quá thời hạn xác thực lại (bước 2).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."

**Quy tắc áp dụng.** BR-01-003, BR-01-009, BR-01-017, BR-01-018, BR-01-031.

**Màn hình, API.** UI-01-07; API-01-032, 033.
:::

### 6.13. UC-01-13 · Cấp định danh SANDBOX sau phê duyệt (saga)

::: dac-ta
**Mục tiêu.** Sau phê duyệt, HTTT có định danh SANDBOX đúng phương thức xác thực, scope dữ liệu rỗng, không bí mật nào đi qua PH-01; lỗi giữa chừng không để lại client mồ côi ở PH-12 hay consumer ở PH-03.

**Tác nhân chính.** `dh-connect` (bộ điều phối saga); TA (Minh) xử lý khi saga thất bại.

**Tác nhân phụ.** PH-12 (tạo client), OpenBao (bí mật), PH-03 (consumer, hạn mức), PH-13 và PH-18 (cảnh báo, thông báo), PO.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-020.

**Truy vết.** REQ-01, REQ-12; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `APPROVED`, `provisionStage = PROVISIONING`; trần phạm vi đã tạo; PH-12, PH-03, OpenBao khả dụng (không thì thử lại, xem E1).

**Kích hoạt.** EVT-01-03 `SUBMITTED → APPROVED` qua outbox; hoặc Minh bấm "Thử lại cấp định danh" (API-01-035) khi `PROVISION_FAILED`.

**Đảm bảo tối thiểu.** PH-01 không bao giờ nhận hay lưu bí mật; khi saga dừng giữa chừng, các bước đã làm được bù trừ theo thứ tự ngược.

**Đảm bảo thành công.** Định danh SANDBOX `ACTIVE` ở EN-01-08 kèm `secret_ref` hoặc `jwksRef`; `provisionStage = SANDBOX_READY` hoặc `AWAITING_KEY`; EVT-01-05 đã phát; kiểm toán ghi từng bước saga và thời gian; mục tiêu p95 ≤ 5 phút (NFR-01-004).

**Luồng chính.**

1. `dh-connect` nhận EVT-01-03, tạo bản ghi định danh SANDBOX ở trạng thái chờ và sinh `sagaId` làm khóa lũy đẳng cho mọi lệnh gọi tiếp theo.
2. `dh-connect` gọi PH-12 tạo client `t68-HT-HOTICH-sbx` với `authMethod = PRIVATE_KEY_JWT` (mức `RESTRICTED`); scope ban đầu chỉ gồm scope môi trường thử, không có scope dữ liệu nào (BR-01-003).
3. `dh-connect` gọi PH-03 tạo consumer SANDBOX gắn client, hạn mức `sandbox.quotaPerDay` (1.000 lượt mỗi ngày) và danh sách IP cho phép `10.68.20.0/28`.
4. `dh-connect` đặt định danh `ACTIVE` ở môi trường `SANDBOX` và `provisionStage = AWAITING_KEY` (chờ đầu mối đăng ký khóa ở UC-01-14).
5. `dh-connect` phát EVT-01-05, ghi kiểm toán toàn bộ saga và thông báo Lan, Phúc "Định danh thử đã sẵn sàng" kèm liên kết tới UI-01-08 (thư chỉ chứa liên kết, LP-01-06).
6. UI-01-08 hiển thị khối tiến độ cấp định danh qua API-01-036: từng bước, thời gian, bước đang chờ.

```{.mermaid caption="Trình tự saga cấp định danh SANDBOX (UC-01-13)"}
sequenceDiagram
  participant K as Kafka, outbox
  participant C as dh-connect PH-01
  participant I as PH-12 Keycloak
  participant G as PH-03 APISIX
  participant D as Đầu mối kỹ thuật
  K->>C: EVT-01-03 SUBMITTED sang APPROVED
  C->>C: Tạo định danh SANDBOX chờ, sinh sagaId
  C->>I: Tạo client t68-HT-HOTICH-sbx, scope môi trường thử
  I-->>C: clientId, secret_ref nếu có
  C->>G: Tạo consumer SANDBOX, hạn mức 1.000 lượt mỗi ngày
  G-->>C: consumerId
  C->>C: Đặt AWAITING_KEY hoặc SANDBOX_READY, phát EVT-01-05
  C-->>D: Thư chỉ chứa liên kết tới UI-01-08 hoặc UI-01-09
  Note over C,G: Lỗi giữa chừng thì bù trừ ngược rồi thử lại sau 1, 2, 4, 8, 15 phút
```

Hình trên cho thấy saga chạy do sự kiện, mỗi lệnh gọi mang cùng `sagaId` để thử lại không tạo trùng client. PH-01 chỉ giữ tham chiếu (`secret_ref`, `jwksRef`); bí mật, nếu có, chỉ nằm ở OpenBao.

**Luồng thay thế.**

- **2a. Phương thức `CLIENT_SECRET` (mức `INTERNAL`, giai đoạn chuyển tiếp, BR-01-019).** PH-12 ghi bí mật vào OpenBao ở `kv/dh/t68/clients/{systemCode}/sandbox` và trả `secret_ref`; ở bước 4 `provisionStage = SANDBOX_READY`; `dh-connect` kích hoạt bàn giao tự động tới đầu mối kỹ thuật (UC-01-15).
- **3a. Lỗi giữa chừng.** Sau bước 3 lỗi thì gỡ consumer ở PH-03; sau bước 2 lỗi thì xóa client ở PH-12 và hủy bí mật ở OpenBao; rồi thử lại toàn bộ theo lịch lùi 1, 2, 4, 8, 15 phút, tối đa 24 giờ.
- **4a. Saga ở `PROVISION_FAILED`.** Minh xử lý nguyên nhân rồi bấm "Thử lại cấp định danh" (API-01-035); saga chạy lại với `sagaId` mới và không tạo trùng.

**Luồng ngoại lệ.**

- **E1. PH-12 không khả dụng (bước 2).** ERR-01-021 (503); hồ sơ giữ `APPROVED`, `provisionStage = PROVISIONING`, không mất tiến trình; khối tiến độ ở UI-01-08 hiện "Đang chờ dịch vụ định danh, hệ thống sẽ tự thử lại."
- **E2. Client trùng ở PH-12 (bước 2).** ERR-01-022 (409); saga dừng, `provisionStage = PROVISION_FAILED`, cảnh báo Minh "Mã client đã tồn tại ở PH-12, cần xử lý thủ công."
- **E3. Kho bí mật không khả dụng (bước 2a).** ERR-01-023 (503); thử lại theo lịch lùi; UI-01-08 báo đang thử lại (FRS §9.2 chưa có câu riêng cho ngữ cảnh saga, xem chương 10).
- **E4. Quá 24 giờ chưa thành công.** `provisionStage = PROVISION_FAILED`; cảnh báo mức cao tới TA và PO ở PH-13.

**Quy tắc áp dụng.** BR-01-003, BR-01-005, BR-01-007, BR-01-019, BR-01-031.

**Màn hình, API.** UI-01-08; API-01-035, 036; EVT-01-05.
:::

### 6.14. UC-01-14 · Đăng ký khóa công khai hoặc yêu cầu ký chứng thư

::: dac-ta
**Mục tiêu.** HTTT đăng ký khóa công khai hoặc chứng thư của riêng mình để xác thực với Datahub; khóa riêng không bao giờ rời HTTT và PH-01 không bao giờ nhận khóa riêng.

**Tác nhân chính.** Đầu mối kỹ thuật (Phúc, OR ○) hoặc TA (Minh) có `PERM-01-credential`.

**Tác nhân phụ.** PH-12 (đăng ký khóa, đặt `tls_client_auth`), OpenBao PKI (ký CSR), PH-03 (gắn dấu vân tay vào consumer).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-021.

**Truy vết.** REQ-01, REQ-12; BP-01; LGC-APIM-020.

**Tiền điều kiện.** Có định danh `auth_method` là `PRIVATE_KEY_JWT` hoặc `MTLS`; `provisionStage = AWAITING_KEY` hoặc định danh đang xoay vòng (UC-01-18).

**Kích hoạt.** Phúc bấm "Đăng ký khóa" hoặc "Gửi yêu cầu chứng thư" ở UI-01-08.

**Đảm bảo tối thiểu.** Khóa sai thuật toán, quá yếu hoặc chứa thành phần khóa riêng không được ghi; không lưu khóa riêng ở bất cứ đâu.

**Đảm bảo thành công.** `jwksRef` (hoặc `cert_fingerprint`, `expires_at`) đã ghi; PH-12 và PH-03 đã nhận khóa; `provisionStage = SANDBOX_READY`; EVT-01-05 đã phát (EVT-01-06 khi xoay vòng).

**Luồng chính.**

1. Phúc sinh cặp khóa ES256 (P-256) trên máy của HTTT `HT-HOTICH`, tải tập khóa công khai JWKS với `kid = hotich-2026-11` lên UI-01-08.
2. Hệ thống gọi API-01-037 và kiểm tra thuật toán `ES256` (P-256) hoặc `PS256` với RSA từ 3072 bit, `kid` duy nhất, không chứa thành phần khóa riêng (sai: ERR-01-027).
3. Hệ thống gửi khóa tới PH-12 đăng ký cho client `t68-HT-HOTICH-sbx`, ghi `jwksRef` và dấu vân tay khóa.
4. Hệ thống đặt `provisionStage = SANDBOX_READY`, phát EVT-01-05 và thông báo Lan, Minh "HTTT HT-HOTICH đã sẵn sàng kiểm thử SANDBOX" (UC-01-16).
5. UI-01-08 hiển thị dấu vân tay rút gọn của khóa và hạn của định danh.

**Luồng thay thế.**

- **1a. `MTLS` dùng CA của Datahub.** Nếu đơn vị chọn mTLS thay vì khóa công khai, Phúc tải CSR PKCS#10 với `CN = HT-HOTICH.t68` (mẫu `{systemCode}.{tenant}`). Hệ thống (API-01-038) kiểm tra khóa ECDSA P-256 hoặc RSA 3072, `CN` đúng mẫu, không có phần mở rộng ngoài chính sách (ERR-01-028); gọi OpenBao PKI ký bằng vai trò `pki-http-clients` của tenant, thời hạn theo `credential.maxLifetimeDays`; trả chuỗi chứng thư; ghi `cert_fingerprint` SHA-256 và `expires_at`; PH-12 đặt `tls_client_auth`, PH-03 gắn dấu vân tay.
- **1b. `MTLS` dùng CA do tỉnh chấp nhận.** Phúc tải chứng thư; hệ thống kiểm tra chuỗi tới CA đã nạp trong danh sách tin cậy của tenant (ERR-01-028 nếu sai).
- **1c. Xoay vòng.** Cho phép tối đa hai khóa `kid` (hoặc hai dấu vân tay) cùng hiệu lực trong thời gian chuyển tiếp (UC-01-18).

**Luồng ngoại lệ.**

- **E1. Khóa sai thuật toán, quá yếu, chứa khóa riêng hoặc `kid` trùng (bước 2).** ERR-01-027 (422); "Khóa không hợp lệ: dùng ES256 (P-256) hoặc PS256 (RSA ≥ 3072 bit), chỉ tải khóa công khai."
- **E2. CSR sai tên, khóa yếu hoặc chứng thư không thuộc CA tin cậy (bước 1a, 1b).** ERR-01-028 (422); "Yêu cầu chứng thư không hợp lệ: {lý do}."
- **E3. OpenBao hoặc PH-12 không khả dụng (bước 3, 1a).** ERR-01-023 hoặc ERR-01-021 (503); "Dịch vụ cấp chứng thư tạm thời không khả dụng. Thử lại sau."
- **E4. Định danh không ở trạng thái cho phép (bước 2).** ERR-01-030 (409); "Định danh không còn dùng được. Cấp định danh mới."

**Quy tắc áp dụng.** BR-01-007, BR-01-019, BR-01-020.

**Màn hình, API.** UI-01-08; API-01-037, 038.
:::

### 6.15. UC-01-15 · Nhận bàn giao thông tin xác thực một lần

::: dac-ta
**Mục tiêu.** Đầu mối đúng người nhận được thông tin xác thực đúng một lần, qua đường duy nhất của Datahub (liên kết dùng một lần, đăng nhập hai yếu tố); người khác mở liên kết không lấy được gì và Cán bộ ATTT được cảnh báo.

**Tác nhân chính.** Đầu mối kỹ thuật của HTTT có tài khoản (ví dụ Khôi, Văn phòng UBND, nhận định danh `CLIENT_SECRET` của `HT-DVC`).

**Tác nhân phụ.** PH-12 (Keycloak: đăng nhập, xác thực hai yếu tố), OpenBao (bọc phản hồi), PH-18 (thư), PH-13 và SO (nhận cảnh báo an ninh); TA, OR tạo lại liên kết.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-022.

**Truy vết.** REQ-01, REQ-12; BP-01; LGC-APIM-020.

**Tiền điều kiện.** Định danh `CLIENT_SECRET` `ACTIVE` có `secret_ref`; đầu mối `TECHNICAL` có tài khoản (`userAccountId`); bàn giao `PENDING` còn hạn 24 giờ.

**Kích hoạt.** Khôi bấm liên kết trong thư "Định danh đã sẵn sàng" (thư chỉ chứa liên kết); hoặc Minh, Lan bấm "Tạo lại liên kết".

**Đảm bảo tối thiểu.** Không có bí mật trong thư điện tử, CSDL PH-01, nhật ký, vết, bộ nhớ đệm; liên kết không bị tiêu hao khi OpenBao lỗi; người không phải đầu mối không lấy được gì.

**Đảm bảo thành công.** Bàn giao `OPENED` kèm `openedBy`, `openedAt`, `openedIp`; mọi bản sao bí mật của bàn giao ở OpenBao bị hủy; EVT-01-09 đã phát; Khôi đã lưu bí mật.

**Luồng chính.**

1. Khi định danh sẵn sàng, hệ thống (API-01-039) yêu cầu OpenBao tạo bản sao bí mật được bọc phản hồi (response wrapping, chỉ mở được một lần) hết hạn sau `handover.ttlHours` (24 giờ); chỉ lưu SHA-256 của liên kết và `wrapAccessor`, không lưu liên kết gốc.
2. Hệ thống gửi thư tới thư công vụ của Khôi; thư chỉ có liên kết `/ket-noi/ban-giao/{token}` và hướng dẫn, không có bí mật (LP-01-06).
3. Khôi mở liên kết; hệ thống buộc đăng nhập một lần qua Keycloak và xác thực hai yếu tố mới, không dựa vào phiên cũ (chưa đạt: ERR-01-035).
4. Hệ thống gọi API-01-040: băm `token`, tìm bàn giao `PENDING` (không có, đã dùng, hết hạn hoặc bị hủy: ERR-01-024), kiểm tra tài khoản đăng nhập đúng là tài khoản của đầu mối nhận (sai: ERR-01-025, tăng `failedAttempts`, phát EVT-01-10).
5. Hệ thống yêu cầu OpenBao mở bản bọc (một lần) và lấy được bí mật.
6. Hệ thống trả `clientId`, `clientSecret`, điểm cuối token, địa chỉ API của môi trường, phương thức xác thực, hạn mức, đường dẫn hướng dẫn kết nối, kèm `Cache-Control: no-store`; thân phản hồi không ghi vào nhật ký, vết hay bộ nhớ đệm.
7. Hệ thống đánh dấu `OPENED`, ghi người mở, thời điểm, địa chỉ IP; hủy mọi phiên bản bản sao bí mật của bàn giao ở OpenBao; phát EVT-01-09.
8. UI-01-09 hiển thị bí mật với nút Sao chép, Tải về và cảnh báo "Thông tin này chỉ hiển thị MỘT LẦN. Lưu vào nơi an toàn ngay." Khôi lưu vào kho bí mật của đơn vị rồi bấm "Đã lưu, đóng".

```{.mermaid caption="Trình tự bàn giao thông tin xác thực một lần (UC-01-15)"}
sequenceDiagram
  participant C as dh-connect PH-01
  participant B as OpenBao
  participant M as Đầu mối kỹ thuật
  participant I as PH-12 Keycloak
  participant S as Cán bộ ATTT
  C->>B: Tạo bản sao bí mật bọc phản hồi, hạn 24 giờ
  B-->>C: wrapAccessor và mã bọc
  C->>M: Thư chỉ chứa liên kết dùng một lần
  M->>C: Mở liên kết ban-giao
  C->>I: Buộc đăng nhập và xác thực hai yếu tố mới
  I-->>C: Danh tính và mức xác thực
  alt Đúng đầu mối
    C->>B: Mở bản bọc, chỉ một lần
    B-->>C: Bí mật
    C-->>M: Hiển thị bí mật một lần, no-store
    C->>B: Hủy mọi bản sao còn lại
  else Sai người mở
    C-->>M: ERR-01-025 và ghi vết
    C->>S: EVT-01-10 cảnh báo an ninh
  end
```

Hình trên là điểm duy nhất của Datahub hiển thị một bí mật. Hai điều hội đồng cần thấy: liên kết trong thư vô dụng nếu rơi vào tay người khác (cần đúng tài khoản và xác thực hai yếu tố), và sau lần mở đầu bản sao ở OpenBao bị hủy nên không còn nơi nào lấy lại được.

**Luồng thay thế.**

- **1a. Liên kết hết hạn chưa mở.** Minh hoặc Lan bấm "Tạo lại liên kết" (API-01-041); hệ thống hủy bàn giao cũ (`CANCELLED`), tạo bản bọc mới từ bí mật còn lưu ở OpenBao và ghi vết.
- **1b. Định danh `PRIVATE_KEY_JWT` hoặc `MTLS` không có bí mật.** Trang chỉ hiển thị thông tin kết nối (không cần bọc), vẫn yêu cầu đăng nhập đúng đầu mối và ghi vết.
- **1c. Đầu mối được thay trước khi mở.** Bàn giao đang chờ nhắm đầu mối cũ bị hủy; tạo lại cho đầu mối mới (UC-01-05).
- **8a. Làm mất bí mật sau khi đã mở.** Không sinh lại liên kết cũ; dùng xoay vòng (UC-01-18).

**Luồng ngoại lệ.**

- **E1. Liên kết đã dùng, hết hạn hoặc bị hủy (bước 4).** ERR-01-024 (410); "Liên kết bàn giao đã được sử dụng hoặc hết hạn. Nếu chưa nhận được thông tin, liên hệ quản trị tỉnh để xoay bí mật và nhận liên kết mới."
- **E2. Người mở không phải đầu mối đã khai báo (bước 4).** ERR-01-025 (403); "Tài khoản này không phải đầu mối nhận bàn giao. Sự việc đã được ghi nhận."; EVT-01-10 báo Dũng.
- **E3. Mở sai quá `handover.maxFailedOpens` (5) lần (bước 4).** ERR-01-026 (429); liên kết bị hủy; "Liên kết đã bị khóa do thử sai nhiều lần. Liên hệ quản trị tỉnh."
- **E4. Chưa xác thực hai yếu tố mới (bước 3).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."
- **E5. OpenBao không khả dụng (bước 1, 5).** ERR-01-023 (503); liên kết chưa bị tiêu hao; "Kho bí mật tạm thời không khả dụng. Mở lại liên kết sau ít phút."
- **E6. HTTT đang `SUSPENDED` khi tạo lại liên kết (bước 1a).** ERR-01-048 (409); "Hệ thống đang tạm ngừng, không tạo liên kết bàn giao mới. Chờ khôi phục hoặc xoay định danh."
- **E7. Đầu mối chưa có tài khoản khi tạo liên kết (bước 1).** ERR-01-003 (400); "Đầu mối {tên} chưa có tài khoản. Nhờ quản trị tỉnh tạo tài khoản rồi tạo lại liên kết." (xem Q01-46)

**Quy tắc áp dụng.** BR-01-005, BR-01-006, BR-01-007, BR-01-009.

**Màn hình, API.** UI-01-09; API-01-039, 040, 041; EVT-01-09, 10.
:::

### 6.16. UC-01-16 · Kiểm thử kết nối ở SANDBOX

::: dac-ta
**Mục tiêu.** HTTT chứng minh gọi được API sandbox bằng định danh vừa nhận trước khi được cấp PRODUCTION; đơn vị và tỉnh nhìn cùng một kết quả kèm hướng dẫn khắc phục từng lỗi.

**Tác nhân chính.** HTTT thành viên (gọi API sandbox); OR (Lan) theo dõi kết quả.

**Tác nhân phụ.** PH-03 (điểm cuối sandbox), PH-13 (nhật ký theo định danh), PH-18 (thông báo); TA, IE, SO, TO xem (`PERM-01-read`).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-023.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** `HT-HOTICH` `APPROVED`, `provisionStage = SANDBOX_READY`; đầu mối đã nhận bàn giao hoặc đã đăng ký khóa.

**Kích hoạt.** HTTT gọi điểm cuối sandbox; tác vụ thu thập kết quả chạy mỗi 5 phút; hoặc Lan bấm "Làm mới kết quả" ở UI-01-10.

**Đảm bảo tối thiểu.** SANDBOX chỉ có dữ liệu giả; định danh SANDBOX không gọi được dữ liệu thật (BR-01-034).

**Đảm bảo thành công.** Bản ghi kiểm thử EN-01-10 mới; khi đạt tiêu chí, `readyToActivate = true` và Minh nhận thông báo.

**Luồng chính.**

1. HTTT `HT-HOTICH` lấy token bằng định danh SANDBOX (JWT ký bằng khóa đã đăng ký) rồi gọi 5 lần API mẫu "tra cứu công dân" với dữ liệu giả: 4 lần thành công, 1 lần `400` do sai tham số.
2. Mỗi 5 phút hệ thống lấy từ PH-13 (nguồn nhật ký của PH-03) số lượt xác thực thành công, số lượt gọi API thành công và mã lỗi nổi bật theo định danh SANDBOX; ghi một bản ghi EN-01-10.
3. Hệ thống đánh giá tiêu chí: có ít nhất 1 lần xác thực thành công và ít nhất `sandbox.requiredSuccessfulCalls` (3) lượt API thành công trong 7 ngày gần nhất; với `MTLS` có thêm bắt tay chứng thư thành công.
4. Lan mở UI-01-10 và thấy kết quả cho cả hai bên, kèm hướng dẫn khắc phục cho lượt `400` ("Sai tham số `soDinhDanh`: cần 12 chữ số").
5. Khi đạt đủ tiêu chí, hệ thống đặt `readyToActivate = true` và thông báo Minh "HTTT HT-HOTICH đã kiểm thử đạt, chờ kích hoạt".
6. Quá `sandbox.maxDays` (30 ngày) kể từ lúc có định danh mà chưa đạt: hệ thống cảnh báo Minh và PO, đề nghị liên hệ đơn vị hoặc chấm dứt (UC-01-21).

**Luồng thay thế.**

- **1a. Xác thực lỗi liên tục.** Từ 20 lượt `invalid_client` trong 1 giờ: hệ thống nghi bí mật bị lộ hoặc cấu hình sai, đề nghị xoay bí mật (UC-01-18) và báo Dũng.
- **4a. Làm mới ngay.** Lan bấm "Làm mới kết quả" (API-01-042) thay vì chờ 5 phút; kết quả xem ở API-01-043.

**Luồng ngoại lệ.**

- **E1. Thiếu dữ liệu nhật ký từ PH-13 (bước 2, 4a).** ERR-01-046 (503) ghi nhật ký; "Chưa lấy được kết quả kiểm thử. Thử làm mới sau."
- **E2. Kiểm thử chưa đạt (bước 4).** Hiển thị lỗi cụ thể kèm hướng dẫn, không coi là lỗi hệ thống; nút "Kích hoạt" bị vô hiệu; nếu cố gọi, UC-01-17 trả ERR-01-031 (422); "Chưa đủ lượt kiểm thử đạt ở môi trường thử. Xem kết quả và khắc phục."

**Quy tắc áp dụng.** BR-01-008, BR-01-034.

**Màn hình, API.** UI-01-10; API-01-042, 043.
:::

### 6.17. UC-01-17 · Kích hoạt môi trường thật (PRODUCTION)

::: dac-ta
**Mục tiêu.** HTTT chỉ có định danh PRODUCTION sau khi kiểm thử SANDBOX đạt và được người có thẩm quyền, không phải người nộp hồ sơ, xác nhận; định danh mới không có scope dữ liệu nào.

**Tác nhân chính.** TA (Minh) có `PERM-01-approve`, không phải người nộp hồ sơ.

**Tác nhân phụ.** PH-12, PH-03, OpenBao, PH-02 (công bố API của HTTT `PROVIDER`), PH-18.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-024.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `APPROVED`, `readyToActivate = true`; có đầu mối `TECHNICAL` hoạt động; cấp độ ATTT còn đạt yêu cầu theo trần phạm vi.

**Kích hoạt.** Minh bấm "Kích hoạt môi trường thật" ở UI-01-10.

**Đảm bảo tối thiểu.** Không có định danh PRODUCTION nếu thiếu kiểm thử đạt, thiếu xác nhận hoặc vi phạm bốn mắt; nếu saga lỗi, HTTT giữ `APPROVED`.

**Đảm bảo thành công.** `APPROVED → ACTIVE`, `activatedAt` ghi; client PRODUCTION `t68-HT-HOTICH` và consumer PRODUCTION đã tạo; EVT-01-03, EVT-01-05 đã phát; scope dữ liệu rỗng.

**Luồng chính.**

1. Minh mở UI-01-10. Hệ thống hiển thị danh sách điều kiện kích hoạt (kiểm thử đạt, đầu mối kỹ thuật, cấp độ ATTT, định danh SANDBOX còn hạn) đều đạt.
2. Minh bấm "Kích hoạt môi trường thật" và xác nhận. Hệ thống kiểm tra Minh không phải người nộp hồ sơ (ERR-01-017) và yêu cầu xác thực lại hai yếu tố (LP-01-01).
3. Hệ thống gọi API-01-044, kiểm tra kiểm thử đạt (ERR-01-031) và điều kiện kích hoạt (ERR-01-032).
4. Hệ thống chạy saga như UC-01-13 cho môi trường PRODUCTION: client `t68-HT-HOTICH`, consumer PRODUCTION với hạn mức đã thẩm định (2.000 lượt/ngày), scope ban đầu rỗng; scope dữ liệu chỉ gắn khi đăng ký sử dụng ở PH-02 được duyệt và nằm trong trần phạm vi (BR-01-003).
5. Với `PRIVATE_KEY_JWT`, hệ thống dùng lại khóa đã đăng ký hoặc yêu cầu đăng ký mới (UC-01-14); với `CLIENT_SECRET`, bàn giao một lần cho đầu mối (UC-01-15).
6. Hệ thống chuyển `APPROVED → ACTIVE`, ghi `activatedAt`, phát EVT-01-03 và EVT-01-05, thông báo Lan. Định danh SANDBOX vẫn dùng để thử, chỉ định danh PRODUCTION gọi được dữ liệu thật.

**Luồng thay thế.**

- **4a. HTTT chỉ có vai trò `PROVIDER`.** Vẫn kích hoạt PRODUCTION để PH-02 công bố API của HTTT; scope dữ liệu rỗng.

**Luồng ngoại lệ.**

- **E1. Kiểm thử SANDBOX chưa đạt (bước 3).** ERR-01-031 (422); "Chưa đủ lượt kiểm thử đạt ở môi trường thử. Xem kết quả và khắc phục."
- **E2. Thiếu điều kiện kích hoạt (bước 3).** ERR-01-032 (422); "Chưa đủ điều kiện kích hoạt: {danh sách}."
- **E3. Người nộp tự kích hoạt (bước 2).** ERR-01-017 (403); "Anh/chị đã tham gia hồ sơ này nên không thực hiện được bước này. Nhờ người khác."
- **E4. Chưa xác thực lại hai yếu tố (bước 2).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."
- **E5. PH-12, PH-03 không khả dụng (bước 4).** ERR-01-021 (503); saga thử lại, HTTT giữ `APPROVED`; "Đang chờ dịch vụ định danh, hệ thống sẽ tự thử lại."

**Quy tắc áp dụng.** BR-01-003, BR-01-008, BR-01-013, BR-01-017, BR-01-026.

**Màn hình, API.** UI-01-10; API-01-044.
:::

### 6.18. UC-01-18 · Xoay vòng thông tin xác thực

::: dac-ta
**Mục tiêu.** Thay bí mật, khóa hoặc chứng thư định kỳ hoặc khi nghi lộ mà HTTT không gián đoạn: thông tin cũ và mới cùng hiệu lực trong thời gian chuyển tiếp, sau đó cái cũ bị gỡ.

**Tác nhân chính.** OR (Lan), TA (Minh) có `PERM-01-credential`; SO (Dũng) buộc xoay khi có sự cố (`PERM-01-suspend`); `dh-connect` nhắc khi sắp hết hạn.

**Tác nhân phụ.** PH-12, OpenBao, PH-03, PH-10 (nhận EVT-01-06), đầu mối kỹ thuật (Khôi).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-025.

**Truy vết.** REQ-01, REQ-12; BP-01, BP-07; LGC-APIM-019.

**Tiền điều kiện.** Định danh `ACTIVE`, không đang `ROTATING`.

**Kích hoạt.** Lan bấm "Xoay vòng" ở UI-01-08; Dũng bấm "Buộc xoay" ở UI-01-11; hoặc nhắc hạn (UC-01-19).

**Đảm bảo tối thiểu.** Nếu PH-12 hoặc OpenBao lỗi thì định danh giữ `ACTIVE`, chưa đổi gì; không bí mật nào lưu ở PH-01.

**Đảm bảo thành công.** Định danh `ROTATING` rồi về `ACTIVE` sau chuyển tiếp; thông tin cũ bị gỡ ở PH-12, PH-03 và OpenBao; EVT-01-06 phát khi bắt đầu và khi kết thúc; kiểm toán ghi lý do.

**Luồng chính.**

1. Lan bấm "Xoay vòng" cho định danh PRODUCTION `CLIENT_SECRET` của `HT-DVC`. Hệ thống yêu cầu xác thực lại hai yếu tố (LP-01-01).
2. Hệ thống gọi API-01-045, kiểm tra định danh `ACTIVE` (ERR-01-030) và không đang xoay (ERR-01-029).
3. PH-12 tạo bí mật mới và giữ bí mật cũ hiệu lực song song (client có hai bí mật); bí mật mới ghi OpenBao; hệ thống tạo bàn giao một lần (UC-01-15) tới Khôi.
4. Hệ thống đặt `ROTATING`, `rotationEndsAt = now + credential.rotationOverlapDays` (7 ngày), phát EVT-01-06 để PH-03 và PH-10 cập nhật.
5. Khôi nhận bí mật mới qua UC-01-15 và đổi cấu hình `HT-DVC`.
6. Khi hết thời gian chuyển tiếp hoặc Lan bấm "Kết thúc chuyển tiếp" (API-01-046) sau khi HTTT đã đổi, hệ thống gỡ bí mật cũ ở PH-12 và PH-03, hủy bản sao ở OpenBao, đưa định danh về `ACTIVE`, tính lại `expires_at` và phát EVT-01-06.
7. Hệ thống ghi kiểm toán kèm lý do và người thực hiện.

**Luồng thay thế.**

- **3a. `PRIVATE_KEY_JWT` hoặc `MTLS`.** Đầu mối đăng ký khóa kế tiếp hoặc gửi CSR mới (UC-01-14); PH-12 giữ hai `kid`, PH-03 giữ hai dấu vân tay cùng hiệu lực trong thời gian chuyển tiếp.
- **1a. Xoay khẩn khi nghi lộ.** Dũng bấm "Buộc xoay" với `overlapDays = 0`: thông tin cũ vô hiệu ngay, HTTT có thể gián đoạn đến khi nhận thông tin mới; Dũng có thể kèm tạm ngừng (UC-01-20).
- **1b. Xoay do nhắc hạn.** Lan bắt đầu từ nhãn "Sắp hết hạn" ở UC-01-19.

**Luồng ngoại lệ.**

- **E1. Đang xoay vòng (bước 2).** ERR-01-029 (409); "Đang trong thời gian chuyển tiếp tới {thời điểm}. Kết thúc hoặc chờ hết hạn."
- **E2. Định danh đã thu hồi hoặc hết hạn (bước 2).** ERR-01-030 (409); "Định danh không còn dùng được. Cấp định danh mới."
- **E3. Thiếu lý do khi xoay do sự cố (bước 1a).** ERR-01-033 (400); "Nhập lý do cho thao tác này."
- **E4. PH-12 hoặc OpenBao không khả dụng (bước 3).** ERR-01-021 hoặc ERR-01-023 (503); định danh giữ `ACTIVE`; "Đang chờ dịch vụ định danh, hệ thống sẽ tự thử lại." hoặc "Kho bí mật tạm thời không khả dụng. Mở lại liên kết sau ít phút."
- **E5. Chưa xác thực lại hai yếu tố (bước 1).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."

**Quy tắc áp dụng.** BR-01-009, BR-01-020, BR-01-021.

**Màn hình, API.** UI-01-08, 09, 11; API-01-045, 046; EVT-01-06.
:::

### 6.19. UC-01-19 · Xem danh sách, thu hồi định danh và nhắc hạn

::: dac-ta
**Mục tiêu.** Đơn vị và tỉnh luôn biết định danh nào còn hiệu lực hay sắp hết hạn; thu hồi được ngay khi cần; định danh hết hạn tự bị vô hiệu, không để định danh "treo".

**Tác nhân chính.** OR (Lan) xem; TA (Minh) thu hồi; `dh-connect` nhắc hạn lúc 06:00 hằng ngày.

**Tác nhân phụ.** PH-12, PH-03, OpenBao, PH-13 (`last_used_at`), PH-18, SO (nhận cảnh báo cắt quyền chưa xong).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-026, 027, 028.

**Truy vết.** REQ-01, REQ-12; BP-01, BP-07; LGC-APIM-019.

**Tiền điều kiện.** HTTT có ít nhất một định danh (từ `APPROVED`); thu hồi cần `PERM-01-credential` hoặc `PERM-01-suspend`.

**Kích hoạt.** Mở tab "Ứng dụng và thông tin xác thực" (UI-01-04) hoặc UI-01-08; bấm "Thu hồi"; tác vụ hằng ngày.

**Đảm bảo tối thiểu.** Không API nào trả bí mật; thu hồi luôn đặt trạng thái và chặn ở cổng trước, phần còn lại thử lại cho tới khi xong.

**Đảm bảo thành công.** Danh sách đúng phạm vi; định danh `REVOKED` hoặc `EXPIRED` bị cắt quyền trong ≤ 60 giây; đầu mối nhận nhắc đủ mốc 30, 14, 7 ngày.

**Luồng chính.**

1. Lan mở UI-01-08 của `HT-QLVB`. Hệ thống gọi API-01-049, 050, kiểm tra phạm vi OR rồi trả mỗi định danh: môi trường, `auth_method`, `client_id`, trạng thái, `expires_at`, số ngày còn lại, `last_used_at` (PH-13), dấu vân tay rút gọn, tuổi bí mật, scope hiệu lực lấy từ PH-12; không bao giờ trả bí mật.
2. Lúc 06:00, `dh-connect` tìm định danh còn đúng 30, 14, 7 ngày tới hạn, gửi nhắc tới đầu mối `TECHNICAL` và TA (thư chỉ chứa liên kết), phát EVT-01-08 và gắn nhãn "Sắp hết hạn" ở UI-01-08 (API-01-048).
3. Minh phát hiện định danh PRODUCTION của `HT-DATDAI` nghi bị lộ và bấm "Thu hồi". Hệ thống hiện hộp xác nhận nêu hệ quả, yêu cầu lý do và xác thực lại hai yếu tố.
4. Vì đây là định danh PRODUCTION cuối cùng của HTTT `ACTIVE`, hệ thống cảnh báo "HTTT sẽ không còn định danh dùng được" và đề nghị tạm ngừng thay vì thu hồi; Minh xác nhận tiếp tục (`confirmImpact = true`).
5. Hệ thống gọi API-01-047: đưa client vào danh sách chặn của APISIX (hiệu lực ≤ 60 giây), gọi PH-12 vô hiệu client và thu hồi toàn bộ token, gọi PH-03 gỡ consumer (LP-01-05).
6. Hệ thống hủy bí mật ở OpenBao, hủy bàn giao đang chờ (`CANCELLED`), đặt định danh `REVOKED`, thông báo đầu mối, ghi kiểm toán và phát EVT-01-07.
7. Đến ngày hết hạn mà chưa xoay (UC-01-18): hệ thống đặt `EXPIRED`, vô hiệu client ở PH-12, gỡ consumer ở PH-03, phát EVT-01-07 với `reason = EXPIRED`; HTTT vẫn `ACTIVE` nhưng TA nhận cảnh báo mức cao "HTTT {mã} không còn định danh dùng được".

**Luồng thay thế.**

- **1a. PH-12 không khả dụng khi lấy scope.** Cột scope hiện "Chưa tải được"; các cột khác vẫn hiển thị.
- **2a. Đầu mối đã bắt đầu xoay trước hạn.** Hệ thống dừng nhắc cho định danh đó.
- **2b. Chuỗi bí mật quá tuổi.** Quá `credential.secretMaxLifetimeDays` (180 ngày): đánh dấu "Quá hạn bí mật" và nhắc như sắp hết hạn.
- **5a. Cắt quyền một phần lỗi.** Hệ thống vẫn đặt `REVOKED` ở PH-01 và thêm vào danh sách chặn trước, rồi thử lại các bước còn lại và cảnh báo Dũng "Việc cắt quyền chưa hoàn tất".

**Luồng ngoại lệ.**

- **E1. Không thấy định danh hoặc HTTT thuộc tenant khác (bước 1).** ERR-01-001 (404); "Không tìm thấy hệ thống {mã}."
- **E2. Thiếu lý do thu hồi (bước 3).** ERR-01-033 (400); "Nhập lý do thu hồi."
- **E3. Chưa xác nhận tác động (bước 4).** ERR-01-034 (409); "Đây là định danh cuối cùng của hệ thống đang hoạt động. Xác nhận để tiếp tục."
- **E4. Chưa xác thực lại hai yếu tố (bước 3).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."
- **E5. Định danh đã thu hồi hoặc hết hạn (bước 5).** ERR-01-030 (409); "Định danh không còn dùng được. Cấp định danh mới."
- **E6. Thư nhắc không gửi được (bước 2).** Hệ thống ghi nhận, nhắc Minh và đánh dấu đầu mối "Thư điện tử không hoạt động" (UC-01-31).

**Quy tắc áp dụng.** BR-01-007, BR-01-009, BR-01-020, BR-01-023, BR-01-030.

**Màn hình, API.** UI-01-04, 08, 11; API-01-047, 048, 049, 050; EVT-01-07, 08.
:::

### 6.20. UC-01-20 · Tạm ngừng và khôi phục HTTT

::: dac-ta
**Mục tiêu.** Cắt rồi khôi phục quyền của một HTTT nhanh và có kiểm soát: biết trước tác động lên các HTTT, luồng, sự kiện phụ thuộc; sau khi tạm ngừng không phân hệ nào còn phục vụ HTTT đó; khôi phục chỉ khi đủ điều kiện.

**Tác nhân chính.** TA (Minh) và SO (Dũng) có `PERM-01-suspend`.

**Tác nhân phụ.** PH-02, PH-04, PH-05, PH-10 (cung cấp dữ liệu tác động và nhận EVT-01-03), PH-12, PH-03 và APISIX (cắt quyền), PH-18, PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-029, 030, 033.

**Truy vết.** REQ-01, REQ-13; BP-07; LGC-HUB-010, LGC-HUB-011 (bên phát, bên nhận ở PH-10 ngừng theo).

**Tiền điều kiện.** Tạm ngừng: HTTT `ACTIVE`. Khôi phục: HTTT `SUSPENDED`, không có thao tác khẩn chờ xác nhận (UC-01-22); nếu bị tạm ngừng vì nghi lộ bí mật thì các định danh đã được xoay.

**Kích hoạt.** Minh hoặc Dũng bấm "Tạm ngừng" hoặc "Khôi phục" ở UI-01-04 hay UI-01-11; hoặc hệ thống gọi khi toàn bộ căn cứ pháp lý hết hiệu lực (UC-01-27).

**Đảm bảo tối thiểu.** Khi cắt quyền ở PH-12 hoặc PH-03 lỗi, trạng thái `SUSPENDED` vẫn giữ và việc cắt quyền được thử lại, không hoàn tác.

**Đảm bảo thành công.** HTTT `SUSPENDED` (hoặc `ACTIVE` sau khôi phục); `enforcement = DONE`; cổng API từ chối HTTT ≤ 60 giây (NFR-01-008); EVT-01-03 đã phát; PH-10, PH-02, PH-04, PH-05 đã cập nhật.

**Luồng chính.**

1. Minh mở UI-01-11 của `HT-QLVB` và bấm "Phân tích tác động" (API-01-056). Hệ thống gọi PH-02 (API đã công bố, đăng ký sử dụng đang hoạt động, lượt gọi 30 ngày), PH-04 và PH-05 (luồng, kết nối nguồn), PH-10 (bên phát, bên nhận, topic); tính `impactLevel`: `NONE`, `LOW` (chỉ nội bộ HTTT), `MEDIUM` (có HTTT khác phụ thuộc), `HIGH` (HTTT `CRITICAL` hoặc từ 5 HTTT phụ thuộc). Ví dụ `MEDIUM` vì `HT-DVC` và `HT-DATDAI` đang phụ thuộc.
2. Minh chọn mã lý do, nhập lý do "Đơn vị đề nghị tạm ngừng để nâng cấp hệ thống" và thời hạn dự kiến 3 ngày (`expectedUntil`). Hệ thống yêu cầu xác thực lại hai yếu tố (LP-01-01).
3. Hệ thống gọi API-01-051, kiểm tra HTTT `ACTIVE` (ERR-01-005), lý do đủ (ERR-01-033) và vì có phụ thuộc nên `confirmImpact = true` (ERR-01-034).
4. Hệ thống đặt `SUSPENDED`, `enforcement = PENDING`, ghi lịch sử và outbox trong cùng giao dịch.
5. Hệ thống trước hết đẩy client vào danh sách chặn của APISIX (hiệu lực ≤ 60 giây), rồi gọi PH-12 vô hiệu mọi client và thu hồi token, gọi PH-03 vô hiệu consumer; xong từng bước thì ghi `enforcement = DONE` (LP-01-05).
6. Hệ thống phát EVT-01-03: PH-10 tạm ngừng bên phát và bên nhận gắn HTTT, PH-02 tạm ngừng đăng ký sử dụng, PH-04 và PH-05 đánh dấu (UC-01-26).
7. Hệ thống thông báo đơn vị chủ quản kèm lý do và ghi kiểm toán.
8. Ba ngày sau Minh bấm "Khôi phục" (API-01-052). Hệ thống hiện lý do đã tạm ngừng và danh sách việc cần làm (xoay bí mật, bổ sung căn cứ nếu có).
9. Hệ thống kiểm tra quyền theo mã lý do và không còn thao tác khẩn chờ xác nhận (ERR-01-036), rồi các điều kiện: có đầu mối kỹ thuật, trần phạm vi còn hiệu lực, cấp độ ATTT đạt (ERR-01-032).
10. Minh xác thực lại hai yếu tố; hệ thống đặt `ACTIVE`, `enforcement = PENDING`.
11. Hệ thống gỡ danh sách chặn, gọi PH-12 bật lại client còn hạn (định danh `EXPIRED` không bật lại, cần cấp mới) và PH-03 bật consumer.
12. Hệ thống phát EVT-01-03: PH-10 tiếp tục bên phát, bên nhận do PH-01 tạm ngừng (không tiếp tục bên do SO hay bên tự tạm ngừng vì nguyên nhân khác); thông báo đơn vị và ghi kiểm toán.

**Luồng thay thế.**

- **1a. Một phân hệ không khả dụng khi phân tích.** Kết quả `partial = true` kèm phân hệ thiếu; Minh vẫn quyết định, hệ thống nhắc "Chưa đầy đủ".
- **2a. Tạm ngừng có hẹn.** `expectedUntil` giúp nhắc Minh khi đến hạn xem xét khôi phục; hệ thống không tự khôi phục.
- **2b. Toàn bộ căn cứ pháp lý hết hiệu lực.** UC-01-27 đề nghị Minh tạm ngừng cả HTTT với lý do `LEGAL_EXPIRED` thay vì từng mục.
- **9a. Bị tạm ngừng vì nghi lộ bí mật.** Chỉ Dũng khôi phục, hoặc Minh khi Dũng đồng ý bằng văn bản ghi trong lý do (BR-01-010).
- **12a. Trần một số mục hết hiệu lực trong lúc tạm ngừng.** HTTT vẫn khôi phục; các mục đó giữ `SUSPENDED` (UC-01-27).

**Luồng ngoại lệ.**

- **E1. Thiếu hoặc quá ngắn lý do (bước 3, 10).** ERR-01-033 (400); "Nhập lý do tạm ngừng (ít nhất 10 ký tự)." hoặc "Nhập lý do cho thao tác này."
- **E2. Có đối tượng phụ thuộc chưa xác nhận (bước 3).** ERR-01-034 (409); "Có {n} đối tượng đang phụ thuộc hệ thống này. Xem danh sách và xác nhận để tiếp tục."
- **E3. HTTT không ở trạng thái phù hợp (bước 3, 9).** ERR-01-005 (409); câu hiển thị lấy từ trường `detail` theo FR-00-080.
- **E4. PH-12 hoặc PH-03 lỗi khi cắt quyền (bước 5).** Trạng thái vẫn `SUSPENDED`, `enforcement = PENDING`, thử lại theo lịch lùi và cảnh báo Dũng "Việc cắt quyền của {mã} chưa hoàn tất"; không hoàn tác.
- **E5. Khôi phục HTTT bị SO tạm ngừng vì nghi lộ bí mật khi chưa có đồng ý (bước 9).** ERR-01-036 (409); "HTTT bị tạm ngừng vì nghi lộ bí mật. Cần Cán bộ ATTT đồng ý trước khi khôi phục."
- **E6. Thiếu điều kiện khôi phục (bước 9).** ERR-01-032 (422); "Chưa đủ điều kiện khôi phục: {danh sách}."
- **E7. Chưa xác thực lại hai yếu tố (bước 2, 10).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."
- **E8. Phân hệ khác không khả dụng (bước 1).** ERR-01-046 ghi nhật ký; "Chưa lấy được dữ liệu từ {phân hệ}; danh sách có thể thiếu."

**Quy tắc áp dụng.** BR-01-009, BR-01-010, BR-01-015, BR-01-023.

**Màn hình, API.** UI-01-04, 11; API-01-051, 052, 056.
:::

### 6.21. UC-01-21 · Chấm dứt tư cách thành viên

::: dac-ta
**Mục tiêu.** Kết thúc tư cách thành viên của một HTTT một cách có kiểm soát: có người đề nghị và người duyệt khác nhau, biết trước tác động, cắt toàn bộ quyền, nhưng giữ nguyên hồ sơ và lịch sử để truy vết.

**Tác nhân chính.** TA (Minh) hoặc SO (Dũng) đề nghị (`PERM-01-suspend`); TA khác (Quang) duyệt (`PERM-01-approve`).

**Tác nhân phụ.** PH-12, PH-03, OpenBao, PH-02 (ngừng dịch vụ HTTT đã công bố), PH-10 (đóng bên phát, bên nhận), PH-04, PH-05, PH-18.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-031, 033.

**Truy vết.** REQ-01, REQ-13; BP-07; LGC-HUB-010, LGC-HUB-011.

**Tiền điều kiện.** HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`.

**Kích hoạt.** Minh bấm "Chấm dứt" ở UI-01-11.

**Đảm bảo tối thiểu.** Không xóa cứng hồ sơ (BR-01-011); người đề nghị không duyệt chính đề nghị của mình (BR-01-017); mã HTTT không dùng lại (BR-01-018).

**Đảm bảo thành công.** HTTT `TERMINATED`; mọi định danh `REVOKED`; bí mật ở OpenBao bị hủy; hồ sơ, lịch sử, bước thẩm định giữ nguyên; EVT-01-03 đã phát.

**Luồng chính.**

1. Minh mở UI-01-11 của `HT-DATDAI` và chọn "Chấm dứt". Hệ thống hiện phân tích tác động (API-01-056, như bước 1 của UC-01-20).
2. Minh nhập lý do "Đơn vị sáp nhập, hệ thống ngừng vận hành" và căn cứ, xác nhận tác động (ERR-01-034 nếu còn phụ thuộc mà chưa xác nhận) và xác thực lại hai yếu tố.
3. Hệ thống gọi API-01-053: tạo yêu cầu thay đổi loại `TERMINATE` ở trạng thái chờ duyệt và đưa việc vào hộp "Việc của tôi" của Quang (TA khác Minh).
4. Quang xem tóm tắt và quyết định (API-01-059); hệ thống kiểm tra Quang khác người đề nghị (ERR-01-017) và yêu cầu xác thực lại hai yếu tố.
5. Khi duyệt, hệ thống đặt `enforcement = PENDING` và đợi các giao dịch đang xử lý hoàn tất tối đa `terminate.drainMinutes` (5 phút) rồi cắt.
6. Hệ thống gọi PH-12 thu hồi mọi client và token, gọi PH-03 gỡ consumer và cấu hình định tuyến, hủy mọi bí mật ở OpenBao, hủy bàn giao đang chờ; đặt mọi định danh `REVOKED` (LP-01-05).
7. Hệ thống chuyển `TERMINATED`, giữ nguyên toàn bộ hồ sơ, lịch sử, bước thẩm định, định danh đã thu hồi; phát EVT-01-03 để PH-02 ngừng các dịch vụ HTTT đã công bố và PH-10 đóng bên phát, bên nhận.
8. Hệ thống thông báo đơn vị chủ quản kèm lý do và ghi kiểm toán chi tiết.

**Luồng thay thế.**

- **2a. HTTT `APPROVED` quá hạn kiểm thử.** Quá `sandbox.maxDays` ngày chưa kiểm thử đạt và đơn vị không phản hồi sau hai lần nhắc: Minh đề nghị chấm dứt với lý do "Quá hạn kiểm thử"; bước 5 bỏ qua thời gian chờ vì chưa có lưu lượng thật.
- **4a. Người duyệt không đồng ý.** Yêu cầu `TERMINATE` bị từ chối ở mức yêu cầu; HTTT giữ nguyên trạng thái.

**Luồng ngoại lệ.**

- **E1. Còn phụ thuộc chưa xác nhận (bước 2).** ERR-01-034 (409); "Có {n} đối tượng phụ thuộc. Xem danh sách và xác nhận."
- **E2. Người duyệt trùng người đề nghị (bước 4).** ERR-01-017 (403); "Anh/chị đã đề nghị nên không duyệt được. Nhờ quản trị khác." Tenant chỉ có một TA: xem Q01-47.
- **E3. Thiếu lý do (bước 2).** ERR-01-033 (400); "Nhập lý do chấm dứt."
- **E4. Giao dịch còn xử lý sau thời gian chờ (bước 5).** Hệ thống vẫn cắt; các giao dịch đó nhận lỗi `401` từ cổng; cảnh báo PH-13 "Cắt {n} giao dịch đang xử lý".
- **E5. PH-12 hoặc PH-03 lỗi (bước 6).** Trạng thái vẫn đặt, `enforcement = PENDING`, thử lại và cảnh báo Dũng (BR-01-023).
- **E6. Chưa xác thực lại hai yếu tố (bước 2, 4).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."

**Quy tắc áp dụng.** BR-01-009, BR-01-011, BR-01-017, BR-01-018, BR-01-023.

**Màn hình, API.** UI-01-11; API-01-053, 056, 059.
:::

### 6.22. UC-01-22 · Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT

::: dac-ta
**Mục tiêu.** Khi nghi bị xâm nhập hoặc lộ bí mật, Cán bộ ATTT cắt quyền HTTT ngay lập tức, không chờ ai duyệt; để bảo đảm kiểm soát, quản trị tỉnh phải xác nhận bổ sung trong 24 giờ.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); TA (Minh) xác nhận.

**Tác nhân phụ.** PH-12, PH-03, APISIX, OpenBao, PH-13, PH-18, PO (nhận cảnh báo); playbook sự cố ở D03-07.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-032.

**Truy vết.** REQ-01, REQ-13; BP-07; LGC-HUB-010, LGC-HUB-011.

**Tiền điều kiện.** HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`; Dũng có `PERM-01-suspend`.

**Kích hoạt.** Dũng bấm "Xử lý khẩn" ở UI-01-11; hoặc theo playbook sự cố.

**Đảm bảo tối thiểu.** Hiệu lực ngay, không chờ phê duyệt hay giao dịch đang xử lý; quá hạn xác nhận thì cảnh báo mức cao nhưng không tự hoàn tác (hoàn tác tự động có thể mở lại lỗ hổng).

**Đảm bảo thành công.** HTTT `SUSPENDED` hoặc `TERMINATED`; bản ghi EN-01-12 từ `PENDING_CONFIRM` sang `CONFIRMED`; EVT-01-15 và EVT-01-03 đã phát; cổng API từ chối HTTT ≤ 60 giây.

**Luồng chính.**

1. Dũng phát hiện thông tin xác thực của `HT-QLVB` xuất hiện trên một kênh công khai. Dũng mở UI-01-11, chọn "Xử lý khẩn", chế độ `SUSPEND`, nhập lý do "Nghi lộ bí mật client, phát hiện lúc 14:05"; hệ thống yêu cầu xác thực lại hai yếu tố (LP-01-01).
2. Hệ thống gọi API-01-054: không chờ phê duyệt và không chờ giao dịch đang xử lý, đặt `SUSPENDED` và `enforcement = PENDING`.
3. Hệ thống đẩy client vào danh sách chặn của APISIX ngay, gọi PH-12 vô hiệu client và thu hồi token, gọi PH-03 gỡ consumer, hủy bí mật ở OpenBao (LP-01-05).
4. Hệ thống tạo bản ghi EN-01-12 `PENDING_CONFIRM` với hạn `emergency.confirmHours` (24 giờ) và gửi việc xác nhận cho TA (không phải Dũng).
5. Hệ thống phát EVT-01-15 và EVT-01-03; thông báo Minh, PO và đơn vị chủ quản kèm lý do.
6. Minh xem lý do và tác động rồi bấm "Xác nhận" (API-01-055); hệ thống ghi `CONFIRMED`.
7. Đơn vị xoay định danh (UC-01-18); Dũng đồng ý và Minh khôi phục (UC-01-20).

**Luồng thay thế.**

- **1a. Chế độ `TERMINATE`.** Xác nhận ở bước 6 là xác nhận không đảo ngược; muốn lập lại HTTT phải lập hồ sơ mới với mã mới (BR-01-018).
- **6a. TA đảo ngược (chỉ chế độ `SUSPEND`).** Minh khôi phục theo UC-01-20, cần Dũng đồng ý (BR-01-010).
- **6b. TA vắng.** TA khác xác nhận; FRS còn nêu PA nhưng ma trận quyền chỉ cấp `PERM-01-approve` cho TA (Q01-47).
- **6c. Quá hạn xác nhận.** Hệ thống đặt `OVERDUE`, phát cảnh báo mức cao tới Minh và PO; thao tác vẫn có hiệu lực.

**Luồng ngoại lệ.**

- **E1. Thiếu lý do (bước 1).** ERR-01-033 (400); "Nhập lý do xử lý khẩn."
- **E2. Xác nhận lần hai hoặc đã quá hạn đóng (bước 6).** ERR-01-036 (409); "Thao tác khẩn này đã được xử lý."
- **E3. Chưa xác thực lại hai yếu tố (bước 1).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."
- **E4. PH-12 hoặc PH-03 lỗi (bước 3).** Trạng thái vẫn đặt; hệ thống thử lại và cảnh báo Dũng như E4 của UC-01-20.

**Quy tắc áp dụng.** BR-01-009, BR-01-010, BR-01-023.

**Màn hình, API.** UI-01-11; API-01-054, 055; EVT-01-15.
:::

### 6.23. UC-01-23 · Đề nghị thay đổi hồ sơ HTTT đã kết nạp

::: dac-ta
**Mục tiêu.** Đơn vị cập nhật hồ sơ của HTTT đã hoạt động: thay đổi nhỏ áp dụng ngay, thay đổi ảnh hưởng an ninh qua duyệt, và phạm vi dữ liệu không bao giờ mở rộng bằng đường thay đổi thường.

**Tác nhân chính.** OR (Lan) đề nghị; TA (Minh) duyệt, thêm SO (Dũng) khi đổi cấp độ ATTT hoặc IP.

**Tác nhân phụ.** PH-03 (IP, hạn mức), PH-10 (cấp độ ATTT), PH-02, PH-04, PH-05 (nhận EVT-01-04), OR của tổ chức mới khi đổi chủ quản.

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-01-034.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `ACTIVE`, `SUSPENDED` hoặc `APPROVED`; Lan có `PERM-01-create` (○).

**Kích hoạt.** Lan bấm "Sửa" ở UI-01-04.

**Đảm bảo tối thiểu.** Thay đổi chờ duyệt không ảnh hưởng giá trị đang chạy; mức `FULL` không bao giờ áp dụng trực tiếp.

**Đảm bảo thành công.** Thay đổi mức `NONE` áp dụng ngay; mức `TECHNICAL` áp dụng sau duyệt và đồng bộ xuống phân hệ khác; EVT-01-04 đã phát.

**Luồng chính.**

1. Lan mở UI-01-04 của `HT-TUPHAP`, bấm "Sửa", đổi dải IP cho phép từ `10.68.20.0/28` sang `10.68.20.0/27` và sửa mô tả HTTT.
2. Hệ thống so với bản hiện hành và tự phân loại: sửa mô tả mức `NONE`, đổi IP mức `TECHNICAL` (BR-01-025).
3. Hệ thống áp dụng ngay phần mức `NONE`, ghi lịch sử và phát EVT-01-04.
4. Hệ thống gọi API-01-057 cho phần mức `TECHNICAL`: tạo yêu cầu thay đổi chờ duyệt (EN-01-13) và đưa việc cho Minh và Dũng (đổi IP cần SO thẩm định theo phân công).
5. Minh duyệt ở UI-01-07 (API-01-059, khác người đề nghị). Hệ thống áp dụng và đồng bộ: IP cho phép và hạn mức xuống PH-03, cấp độ ATTT lên PH-10 (EVT-01-04); thông báo Lan.
6. Lan xem danh sách yêu cầu thay đổi và kết quả (API-01-058).

**Luồng thay thế.**

- **2a. Đổi cấp độ ATTT, địa chỉ cơ sở hoặc hạn mức.** Mức `TECHNICAL`, xử lý như bước 4, 5.
- **2b. Đổi phạm vi dữ liệu.** Mức `FULL`: hệ thống chuyển sang UC-01-24 và không áp dụng trực tiếp.
- **2c. Đổi chủ quản.** Cần OR của tổ chức mới xác nhận và Minh duyệt (BR-01-029).
- **2d. Thay đổi không có hiệu lực thực.** Giá trị trùng: trả `200`, không tạo yêu cầu.
- **5a. Minh từ chối.** Yêu cầu bị từ chối kèm lý do; giá trị đang chạy không đổi; Lan nhận thông báo.

**Luồng ngoại lệ.**

- **E1. Đang có yêu cầu thay đổi chờ duyệt (bước 4).** ERR-01-038 (409); "Đã có thay đổi chờ duyệt. Chờ quyết định trước khi gửi thay đổi mới."
- **E2. Cố sửa phạm vi dữ liệu bằng đường thường (bước 2b).** ERR-01-037 (422); "Mở rộng phạm vi phải qua thẩm định pháp lý lại. Dùng Đề nghị mở rộng phạm vi."
- **E3. Địa chỉ hoặc IP không hợp lệ (bước 1).** ERR-01-049 (422); "Địa chỉ {giá trị} không hợp lệ. Chỉ nhận https và dải CIDR hợp lệ."
- **E4. Cấp độ ATTT thấp hơn yêu cầu của trần (bước 2a).** ERR-01-047 (422); "Dữ liệu mức {mức} cần HTTT cấp độ từ {L} và xác thực bằng {phương thức}."
- **E5. Người duyệt trùng người đề nghị (bước 5).** ERR-01-017 (403); "Anh/chị đã tham gia hồ sơ này nên không thực hiện được bước này. Nhờ người khác."

**Quy tắc áp dụng.** BR-01-012, BR-01-025, BR-01-029.

**Màn hình, API.** UI-01-04, 07; API-01-057, 058, 059.
:::

### 6.24. UC-01-24 · Đề nghị mở rộng trần phạm vi khai thác

::: dac-ta
**Mục tiêu.** HTTT đã kết nạp muốn khai thác thêm dữ liệu phải qua thẩm định pháp lý lại như hồ sơ mới; trần phạm vi chỉ mở rộng đúng các mục được chấp thuận, và định danh không tự mở rộng.

**Tác nhân chính.** OR (Lan) đề nghị; người thẩm định được phân công (Quang, Dũng); TA (Minh) duyệt.

**Tác nhân phụ.** PH-02 (nhận EVT-01-11, chặn đăng ký vượt trần, Q01-02), PH-14 (hạn mức quốc gia), PH-12.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-035.

**Truy vết.** REQ-01; BP-01; LGC-APIM-020.

**Tiền điều kiện.** HTTT `ACTIVE` hoặc `SUSPENDED`; không có đề nghị mở rộng đang chờ.

**Kích hoạt.** Lan bấm "Đề nghị mở rộng phạm vi" ở UI-01-04; hoặc đăng ký sử dụng ở PH-02 vượt trần và người dùng chọn xin mở rộng.

**Đảm bảo tối thiểu.** Trần và scope của định danh không đổi cho tới khi đề nghị được duyệt.

**Đảm bảo thành công.** Trần phạm vi có thêm các mục được chấp thuận; EVT-01-11 đã phát; scope chỉ gắn khi đăng ký sử dụng ở PH-02 được duyệt.

**Luồng chính.**

1. Lan bấm "Đề nghị mở rộng phạm vi" ở UI-01-04 của `HT-TUPHAP` và khai mục mới "Dữ liệu đất đai, tra cứu theo mã thửa": chiều `CONSUME`, mức `RESTRICTED`, căn cứ "45/NQ-HĐND ngày 20/06/2026" (số liệu giả lập) kèm tệp văn bản.
2. Hệ thống kiểm tra như UC-01-06: căn cứ đủ (ERR-01-015), không thuộc bí mật nhà nước (ERR-01-016), cấp độ ATTT đủ cho mức phân loại (ERR-01-047).
3. Hệ thống gọi API-01-060, tạo yêu cầu thay đổi mức `FULL` (EN-01-13), tạo bước `LEGAL` chỉ cho mục mới, thêm bước `SECURITY` nếu có mục mức Hạn chế hoặc Nhạy cảm cao hơn mức hiện có, thêm đánh giá hạn mức quốc gia nếu có dịch vụ quốc gia (UC-01-09).
4. Quang đánh giá từng mục mới như UC-01-10 (chấp thuận, thu hẹp, từ chối).
5. Minh duyệt (khác Lan, khác Quang). Hệ thống thêm các mục được chấp thuận vào trần phạm vi và phát EVT-01-11 để PH-02 biết trần mới.
6. Hệ thống không tự mở rộng định danh: scope chỉ gắn khi đăng ký sử dụng ở PH-02 được duyệt và nằm trong trần (BR-01-003); thông báo Lan.

**Luồng thay thế.**

- **1a. Xuất phát từ PH-02.** Đăng ký sử dụng vượt trần, người dùng chọn xin mở rộng; giao diện chuyển sang UI-01-04 với mục điền sẵn.
- **1b. Chỉ thu hẹp hoặc bỏ bớt mục.** Không cần thẩm định, áp dụng ngay (không mở rộng).
- **4a. Mọi mục mới bị từ chối.** Yêu cầu kết thúc, trần không đổi; Lan nhận lý do từng mục.

**Luồng ngoại lệ.**

- **E1. Mục thiếu căn cứ (bước 2).** ERR-01-015 (422); "Mục {tên} chưa có căn cứ pháp lý. Bổ sung số, ngày, cơ quan ban hành văn bản cho phép khai thác."
- **E2. Mục thuộc bí mật nhà nước (bước 2).** ERR-01-016 (422); "Dữ liệu này thuộc danh mục bí mật nhà nước, không kết nối qua Datahub."
- **E3. Cấp độ ATTT không đạt (bước 2).** ERR-01-047 (422); "Dữ liệu mức {mức} cần HTTT cấp độ từ {L} và xác thực bằng {phương thức}."
- **E4. Đã có đề nghị mở rộng đang chờ (bước 3).** ERR-01-038 (409); "Đã có thay đổi chờ duyệt. Chờ quyết định trước khi gửi thay đổi mới."
- **E5. Người duyệt trùng người đề nghị hoặc người thẩm định (bước 5).** ERR-01-017 (403); "Anh/chị đã tham gia hồ sơ này nên không duyệt được. Nhờ người khác."

**Quy tắc áp dụng.** BR-01-001, BR-01-003, BR-01-012.

**Màn hình, API.** UI-01-04, 06; API-01-060, API-01-059 (TA duyệt); EVT-01-11.
:::

### 6.25. UC-01-25 · Tự vô hiệu định danh không hoạt động và bật lại

::: dac-ta
**Mục tiêu.** Định danh PRODUCTION không dùng quá 90 ngày tự bị vô hiệu để giảm bề mặt tấn công (SEC-27); người có quyền bật lại được khi cần mà không phải cấp mới.

**Tác nhân chính.** `dh-connect` (tác vụ hằng ngày lúc 06:30); TA (Minh) hoặc OR (Lan) có `PERM-01-credential` bật lại.

**Tác nhân phụ.** PH-13 (`last_used_at`), PH-12, PH-03, PH-18.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-01-036.

**Truy vết.** REQ-01, REQ-12; BP-07.

**Tiền điều kiện.** Định danh PRODUCTION `ACTIVE` có `last_used_at` (nhận từ PH-13).

**Kích hoạt.** Tác vụ hằng ngày lúc 06:30 (khóa ShedLock); với bật lại, Lan bấm "Bật lại định danh" ở UI-01-04.

**Đảm bảo tối thiểu.** Khi PH-13 không khả dụng thì bỏ qua lượt chạy, tuyệt đối không tạm ngừng nhầm.

**Đảm bảo thành công.** Định danh có `disabled = true`, `disabledReason = INACTIVE`; EVT-01-07 `reason = INACTIVE`, `reversible = true`; hoặc định danh được bật lại.

**Luồng chính.**

1. Lúc 06:30, `dh-connect` lấy `last_used_at` của mọi định danh PRODUCTION từ PH-13.
2. Với định danh không dùng quá `inactivity.autoSuspendDays − 7` (83 ngày), hệ thống nhắc đầu mối "Định danh sắp bị tạm ngừng do không dùng".
3. Quá `inactivity.autoSuspendDays` (90 ngày), hệ thống đặt `disabled = true`, `disabledReason = INACTIVE` (trạng thái định danh giữ `ACTIVE` vì DD-05 không có trạng thái tạm ngừng riêng), gọi PH-12 vô hiệu client và PH-03 gỡ consumer.
4. Hệ thống phát EVT-01-07 với `reason = INACTIVE`, `reversible = true`, thông báo đầu mối và Minh; UI-01-04 hiện nhãn "Đã tạm ngừng do không dùng".
5. Khi cần dùng lại, Lan bấm "Bật lại định danh" kèm lý do. Hệ thống gọi API-01-061, PH-12 và PH-03 bật lại, không cấp bí mật mới.

**Luồng thay thế.**

- **1a. Không áp dụng.** HTTT đã `SUSPENDED`, định danh đang `ROTATING` hoặc định danh SANDBOX không tính.
- **5a. Định danh đã hết hạn.** Không bật lại; cấp lại bằng xoay vòng (UC-01-18).

**Luồng ngoại lệ.**

- **E1. PH-13 không khả dụng (bước 1).** Bỏ qua lượt chạy, cảnh báo vận hành, không tạm ngừng.
- **E2. Bật lại định danh `EXPIRED` (bước 5).** ERR-01-030 (409); "Định danh đã hết hạn. Cấp lại bằng xoay vòng."
- **E3. Thiếu lý do bật lại (bước 5).** ERR-01-033 (400); "Nhập lý do cho thao tác này."

**Quy tắc áp dụng.** BR-01-022.

**Màn hình, API.** UI-01-04; API-01-061; EVT-01-07.
:::

### 6.26. UC-01-26 · Đồng bộ trạng thái và cung cấp bản sao đọc cho phân hệ khác

::: dac-ta
**Mục tiêu.** Các phân hệ khác biết ngay HTTT nào đang hoạt động, bị tạm ngừng hay đã chấm dứt mà không phải hỏi PH-01 ở mỗi lượt gọi; tạm ngừng lan sang phân hệ khác trong chưa đầy một phút, và PH-01 dừng hoạt động không làm HTTT đã kết nạp mất kết nối (NFR-01-007).

**Tác nhân chính.** `dh-connect` (outbox, tác vụ đối chiếu); phân hệ tiêu thụ PH-02, PH-03, PH-04, PH-05, PH-10, PH-13, PH-14, PH-15 (scope `onboarding:internal-read`).

**Tác nhân phụ.** Kafka, Debezium, Apicurio (lược đồ sự kiện), PH-18 (hàng đợi lỗi).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-037, 038.

**Truy vết.** REQ-01, REQ-13; BP-02, BP-04; LGC-HUB-010, LGC-HUB-011 (PH-10 chỉ nhận bên phát, bên nhận là HTTT `ACTIVE`).

**Tiền điều kiện.** Một thay đổi trạng thái, thuộc tính hoặc đầu mối của HTTT xảy ra; phân hệ gọi API có token dịch vụ đúng scope.

**Kích hoạt.** Mỗi chuyển trạng thái (cùng giao dịch ghi outbox); tác vụ đối chiếu hằng giờ; phân hệ khác gọi API khi khởi tạo hoặc đối chiếu.

**Đảm bảo tối thiểu.** Không mất sự kiện khi `dh-connect` hỏng giữa chừng; không API hay sự kiện nào mang bí mật, `secret_ref` hay dữ liệu liên hệ cá nhân.

**Đảm bảo thành công.** Phân hệ tiêu thụ cập nhật trong ≤ 60 giây (ACL Kafka ≤ 2 phút); bản sao đọc khớp PH-01 sau mỗi lượt đối chiếu; độ trễ sự kiện p95 ≤ 5 giây từ commit đến Kafka (NFR-01-021).

**Luồng chính.**

1. Khi Minh tạm ngừng `HT-QLVB` (UC-01-20), hệ thống ghi bản ghi outbox trong cùng giao dịch với thay đổi (BR-01-031).
2. Debezium đọc outbox và phát lên topic `t68.connect.system.state-changed.v1` (EVT-01-03) với khóa `systemCode`, nên mọi thay đổi của một HTTT đến theo đúng thứ tự.
3. Phân hệ tiêu thụ cập nhật: PH-10 tạm ngừng bên phát, bên nhận trong ≤ 60 giây (ACL Kafka ≤ 2 phút); PH-02 tạm ngừng đăng ký sử dụng và dịch vụ công bố; PH-04, PH-05 cập nhật bản sao `external_system`.
4. Thay đổi thuộc tính (cấp độ ATTT, địa chỉ, đầu mối) phát EVT-01-04; thay đổi trần phạm vi phát EVT-01-11.
5. Mỗi giờ `dh-connect` phát một ảnh chụp trạng thái (`snapshot = true`, theo lô) để bù sự kiện lỡ; phân hệ tiêu thụ so khớp với bản sao của mình và sửa lệch.
6. PH-10 mới khởi động gọi `GET /internal/systems?updatedSince=…` (API-01-063) để đồng bộ gia tăng và `GET /internal/systems/{systemCode}` (API-01-064) để tra một HTTT. Hệ thống kiểm tra token dịch vụ và tenant (không đọc chéo tenant) và trả bản ghi rút gọn: `code`, `name`, `ownerOrgId`, `status`, `roles[]`, `securityLevel`, `group`, `baseUrls`, `clientIds[]`, `activatedAt`, `updatedAt`, `ceilingDataTypes[]`.
7. Hệ thống không trả dữ liệu liên hệ cá nhân, bí mật, `secret_ref` hay nội dung hồ sơ; thông tin liên hệ lấy qua API danh bạ với quyền riêng (UC-01-30).

**Luồng thay thế.**

- **3a. Phân hệ nghe chậm.** Tác vụ đối chiếu hằng giờ bù; tạm ngừng khẩn vẫn có hiệu lực ngay ở cổng nhờ danh sách chặn (UC-01-20).
- **5a. PH-20 tạm ngừng cả tenant.** PH-01 không đổi trạng thái từng HTTT; PH-03 chặn ở mức tenant.
- **6a. Phân hệ chỉ cần nghe thay đổi.** Dùng topic của bước 2; API chỉ dùng khi khởi tạo và đối chiếu (API-01-062 là điểm vào của tác vụ đối chiếu).

**Luồng ngoại lệ.**

- **E1. Kafka không khả dụng (bước 2).** Outbox giữ sự kiện, phát lại khi Kafka trở lại; cảnh báo PH-13 khi hàng đợi outbox quá 60 giây.
- **E2. Phân hệ tiêu thụ không xử lý được (bước 3).** Sự kiện vào hàng đợi lỗi của phân hệ đó (PH-18); PH-01 không bị chặn.
- **E3. Token thiếu scope (bước 6).** `403` theo lỗi xác thực dùng chung (FR-00-080), không có mã ERR riêng.
- **E4. Không thấy HTTT (bước 6).** ERR-01-001 (404).
- **E5. Quá giới hạn trang (bước 6).** ERR-01-003 (400).

**Quy tắc áp dụng.** BR-01-023, BR-01-030, BR-01-031.

**Màn hình, API.** Không có màn hình; API-01-062, 063, 064; EVT-01-03, 04, 11.
:::

### 6.27. UC-01-27 · Mở kỳ rà soát, tổng hợp mức sử dụng và kiểm tra hiệu lực căn cứ

::: dac-ta
**Mục tiêu.** Mọi quyền của HTTT đang hoạt động được rà soát ít nhất mỗi 6 tháng dựa trên mức sử dụng thực tế; quyền có căn cứ pháp lý hết hiệu lực bị tạm ngừng ngay, không chờ kỳ rà soát.

**Tác nhân chính.** TA (Minh), SO (Dũng) mở kỳ và xem số liệu; `dh-connect` mở kỳ theo lịch và chạy kiểm tra hiệu lực hằng ngày lúc 05:30.

**Tác nhân phụ.** PH-02 (danh mục dịch vụ, tạm ngừng đăng ký sử dụng), PH-13 (mức sử dụng), PH-12 (gỡ scope), PH-18 (thông báo).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-039, 040, 043.

**Truy vết.** REQ-01, REQ-12; BP-07.

**Tiền điều kiện.** Để mở kỳ: tenant không có kỳ rà soát nào đang mở; Minh hoặc Dũng có `PERM-01-suspend`. Để kiểm tra căn cứ: có mục trần phạm vi `ACTIVE` với `validUntil` hoặc được đánh dấu bãi bỏ.

**Kích hoạt.** Tác vụ lịch mỗi `accessReview.intervalMonths` (6 tháng); Minh bấm "Mở kỳ rà soát" ở UI-01-12; tác vụ 05:30 hằng ngày; Minh đánh dấu "Văn bản đã bị bãi bỏ".

**Đảm bảo tối thiểu.** PH-13 hoặc PH-02 không khả dụng thì mục chỉ bị đánh dấu "Chưa có số liệu", không có quyền nào bị thu hồi hay tạm ngừng nhầm.

**Đảm bảo thành công.** Kỳ `RS-2026-02` ở `OPEN` có đủ mục (HTTT, mục trần) kèm `usageInPeriod`, `unusedDays` và cờ; mục có căn cứ hết hiệu lực ở `SUSPENDED` kèm EVT-01-11.

**Luồng chính.**

1. Đến hạn 6 tháng, `dh-connect` (hoặc Minh bấm "Mở kỳ rà soát", API-01-065) kiểm tra không có kỳ đang mở (ERR-01-039), sinh `cycleCode = RS-2026-02`, đặt `OPEN`.
2. Hệ thống lấy mọi HTTT `ACTIVE` trong phạm vi và với mỗi cặp (HTTT, mục trần phạm vi) tạo một mục rà soát (EN-01-15); HTTT có `lastReviewAt` quá `intervalMonths` được gắn "Quá hạn rà soát".
3. Hệ thống tổng hợp mức sử dụng (API-01-068): với mỗi mục, xác định các API và scope thuộc loại dữ liệu qua danh mục dịch vụ ở PH-02; lấy từ PH-13 số lượt gọi thành công theo định danh và theo API trong khoảng thời gian của kỳ; tính `usageInPeriod` và `unusedDays`.
4. Hệ thống đặt cờ cho mục: `UNUSED_IN_PERIOD`, `UNUSED_OVER_12M` (không dùng quá `accessReview.unusedDays` = 365 ngày, đề xuất thu hồi), `CREDENTIAL_EXPIRING`, `LEGAL_EXPIRED`; hiển thị bảng "Phạm vi quyền" ở UI-01-12 và thông báo Minh, Dũng số HTTT, số mục, hạn dự kiến.
5. Hằng ngày lúc 05:30, `dh-connect` tìm mục trần `ACTIVE` có `validUntil` đã qua hoặc căn cứ bị đánh dấu bãi bỏ (API-01-073); đặt mục `SUSPENDED` với lý do `LEGAL_EXPIRED` và đặt cờ `legalExpired` ở mục rà soát nếu có kỳ đang mở.
6. Hệ thống phát EVT-01-11: PH-02 tạm ngừng đăng ký sử dụng thuộc mục đó, PH-12 gỡ scope tương ứng; thông báo đơn vị và Minh "Bổ sung căn cứ mới bằng Đề nghị mở rộng phạm vi".
7. Trước hạn 30 ngày, hệ thống nhắc đơn vị "Căn cứ {văn bản} sắp hết hiệu lực".

**Luồng thay thế.**

- **1a. Rà soát theo chuyên đề (sau sự cố).** Minh liệt kê tổ chức trong `scope`; kỳ này không cập nhật `lastReviewAt` toàn tenant.
- **3a. Mục không ánh xạ được tới API.** `usageInPeriod = null`, cờ `NO_USAGE_DATA`; người rà soát quyết định thủ công ở UC-01-29.
- **3b. Làm mới số liệu.** Minh bấm "Làm mới số liệu" khi PH-13 hoặc PH-02 trở lại.
- **5a. Toàn bộ trần của HTTT hết hiệu lực cùng lúc.** Hệ thống đề nghị Minh tạm ngừng HTTT (UC-01-20) với lý do `LEGAL_EXPIRED` thay vì từng mục.
- **5b. Đánh dấu thủ công văn bản bị bãi bỏ.** Minh nhập số hiệu và ngày văn bản; hệ thống xử lý như bước 5.
- **6a. Đơn vị có căn cứ mới.** Đơn vị dùng UC-01-24 (thẩm định lại); mục khôi phục sau khi được duyệt.

**Luồng ngoại lệ.**

- **E1. Đã có kỳ đang mở (bước 1).** ERR-01-039 (409); "Kỳ rà soát {mã} đang mở. Hoàn tất hoặc đóng kỳ đó trước."
- **E2. Chu kỳ ngoài miền cho phép (bước 1).** ERR-01-044 (422); "Giá trị {khóa} phải từ {min} đến {max}."
- **E3. Không có HTTT nào trong phạm vi (bước 2).** Kỳ vẫn mở với 0 mục; "Không có HTTT cần rà soát."
- **E4. PH-13 hoặc PH-02 không khả dụng (bước 3).** ERR-01-046 (503) ghi nhật ký; mục hiện "Chưa có số liệu"; kỳ vẫn tiếp tục.
- **E5. Mục đã `SUSPENDED` hoặc `REVOKED` (bước 5).** Bỏ qua, không phát lại sự kiện.
- **E6. Đánh dấu bãi bỏ thiếu số hiệu hoặc ngày (bước 5b).** ERR-01-003 (400); "Nhập số hiệu và ngày văn bản bị bãi bỏ."

**Quy tắc áp dụng.** BR-01-014, BR-01-015.

**Màn hình, API.** UI-01-12; API-01-065, 066, 067, 068, 073.
:::

### 6.28. UC-01-28 · Gửi xác nhận cho đơn vị chủ quản và nhận phản hồi

::: dac-ta
**Mục tiêu.** Mỗi đơn vị chủ quản tự xác nhận quyền nào còn cần, để tỉnh không thu hồi nhầm quyền đang dùng và không giữ quyền không còn cần.

**Tác nhân chính.** TA (Minh), SO (Dũng) gửi phiếu; OR (Lan) hoặc đầu mối của tổ chức trả lời.

**Tác nhân phụ.** PH-18 (thư chỉ chứa liên kết, hộp "Việc của tôi"), PH-12 (đăng nhập).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-041.

**Truy vết.** REQ-01, REQ-12; BP-07.

**Tiền điều kiện.** Kỳ `OPEN` đã có số liệu sử dụng (UC-01-27).

**Kích hoạt.** Minh bấm "Gửi xác nhận" ở UI-01-12; tác vụ nhắc hằng ngày.

**Đảm bảo tối thiểu.** Liên kết phiếu chỉ lưu dưới dạng băm, hết hạn sau 30 ngày; đơn vị không phản hồi vẫn được xử lý bằng đề xuất thu hẹp, kỳ không bị treo.

**Đảm bảo thành công.** Mỗi tổ chức có phản hồi hoặc đề xuất `REDUCE`; kỳ chuyển sang `DECIDING`.

**Luồng chính.**

1. Minh bấm "Gửi xác nhận" (API-01-069). Hệ thống nhóm các mục theo tổ chức chủ quản, tạo mỗi tổ chức một phiếu (EN-01-16) với liên kết hạn `accessReview.confirmLinkTtlDays` (30 ngày), chỉ lưu giá trị băm.
2. Hệ thống gửi thư tới đầu mối của tổ chức (thư chỉ có liên kết) và đưa việc vào "Việc của tôi" của OR; kỳ chuyển `WAITING`.
3. Lan mở liên kết, đăng nhập đúng tổ chức Sở Tư pháp và thấy UI-01-13 liệt kê các phạm vi của Sở kèm mức dùng thực tế (API-01-070).
4. Với mỗi mục Lan chọn "Còn cần" (`KEEP`), "Thu hẹp" (`REDUCE`, nêu phạm vi còn cần) hoặc "Không cần nữa" (`RELEASE`), rồi bấm "Gửi phản hồi" (API-01-071); hệ thống lưu phản hồi và `respondedAt`.
5. Đơn vị không phản hồi sau `accessReview.noResponseDays` (30 ngày): hệ thống đặt đề xuất `REDUCE` cho mọi mục của tổ chức đó và đánh dấu "Đơn vị chưa phản hồi".
6. Khi mọi tổ chức đã phản hồi hoặc hết hạn, kỳ chuyển `DECIDING`; hệ thống thông báo Minh, Dũng để xử lý ở UC-01-29.

**Luồng thay thế.**

- **2a. Nhắc đơn vị chưa trả lời.** Nhắc lần hai sau 14 ngày; quá hạn thì leo thang tới lãnh đạo đơn vị bằng thư do Minh soạn (không tự động).
- **3a. Đầu mối trả lời thay OR.** Người trả lời là đầu mối của tổ chức, đăng nhập đúng tổ chức.

**Luồng ngoại lệ.**

- **E1. Liên kết hết hạn hoặc đã trả lời (bước 3, 4).** ERR-01-040 (410); "Phiếu xác nhận đã hết hạn hoặc đã được trả lời. Liên hệ quản trị tỉnh."
- **E2. Người mở không thuộc tổ chức (bước 3).** ERR-01-025 (403); "Tài khoản này không thuộc tổ chức được hỏi."
- **E3. Thu hẹp không nêu phạm vi (bước 4).** ERR-01-003 (400); lỗi hiện ở dòng thiếu phạm vi.
- **E4. Kỳ không ở giai đoạn phù hợp (bước 1).** ERR-01-020 (409); câu hiển thị lấy từ `detail` (FR-00-080).

**Quy tắc áp dụng.** BR-01-014.

**Màn hình, API.** UI-01-12, 13; API-01-069, 070, 071.
:::

### 6.29. UC-01-29 · Xử lý kết quả rà soát và lập báo cáo

::: dac-ta
**Mục tiêu.** Mỗi mục rà soát có quyết định cuối cùng (giữ, thu hẹp, thu hồi) dựa trên số liệu thực tế và phản hồi của đơn vị; kỳ đóng lại có bằng chứng và báo cáo để kiểm toán.

**Tác nhân chính.** TA (Minh), SO (Dũng) xử lý; AU (Hoa), VW xem và xuất báo cáo.

**Tác nhân phụ.** PH-02 (hủy hoặc thu hẹp đăng ký vượt trần), PH-12 (gỡ scope), PH-18, tác vụ xuất nền (FR-00-054).

**Mức ưu tiên.** M · MVP (phần báo cáo FR-01-044 mức S, Đợt 2).

**FR hiện thực.** FR-01-042, 044.

**Truy vết.** REQ-01, REQ-12; BP-07.

**Tiền điều kiện.** Để xử lý: kỳ `DECIDING`. Để lập báo cáo: kỳ `CLOSED`.

**Kích hoạt.** Minh chọn mục ở UI-01-12 rồi bấm "Thu hồi phạm vi", "Thu hẹp" hoặc "Giữ"; Hoa bấm "Báo cáo".

**Đảm bảo tối thiểu.** Không thu hồi phạm vi đang có đăng ký sử dụng hoạt động khi chưa liệt kê và xác nhận tác động; quyết định thu hồi luôn có lý do và xác thực lại hai yếu tố.

**Đảm bảo thành công.** Mọi mục có quyết định riêng; kỳ `CLOSED`; `lastReviewAt` của từng HTTT cập nhật; EVT-01-11 và EVT-01-12 đã phát; bằng chứng kỳ giữ 5 năm (NFR-01-022).

**Luồng chính.**

1. Minh mở UI-01-12, kỳ `RS-2026-02`, lọc nhãn "Không dùng trong kỳ" và "Đơn vị chưa phản hồi"; xem từng mục kèm số liệu sử dụng, phản hồi và đề xuất của hệ thống.
2. Minh chọn 3 mục "Không dùng quá 12 tháng" của `HT-DATDAI`, bấm "Thu hồi phạm vi" và nhập lý do chung "Không dùng quá 12 tháng, đơn vị chưa phản hồi". Hệ thống yêu cầu xác thực lại hai yếu tố (LP-01-01).
3. Hệ thống gọi API-01-072: liệt kê các đăng ký sử dụng đang hoạt động bị ảnh hưởng và yêu cầu Minh xác nhận.
4. Với `REVOKE_SCOPE` hoặc `NARROW`, hệ thống cập nhật trần phạm vi (EN-01-04), phát EVT-01-11; PH-02 hủy hoặc thu hẹp các đăng ký sử dụng vượt trần, PH-12 gỡ scope tương ứng khỏi client.
5. Hệ thống ghi quyết định riêng cho từng mục và thông báo đơn vị chủ quản. Khi mọi mục đã có quyết định, kỳ chuyển `CLOSED`, hệ thống cập nhật `lastReviewAt` từng HTTT và phát EVT-01-12.
6. Hoa mở "Báo cáo" (API-01-074). Hệ thống tổng hợp số HTTT, số mục, số mục theo quyết định, tỷ lệ phản hồi theo tổ chức, danh sách thu hồi kèm lý do, thời gian xử lý; Hoa xuất PDF (API-01-075, báo cáo lớn chạy nền theo FR-00-054) và hệ thống ghi kiểm toán xuất.

**Luồng thay thế.**

- **2a. Giữ hoặc thu hẹp.** Dũng chọn "Giữ" cho mục đơn vị trả lời "Còn cần"; chọn "Thu hẹp" kèm phạm vi còn cần.
- **2b. Thu hồi hàng loạt.** Một lý do chung cho nhiều mục; mỗi mục vẫn ghi quyết định riêng.
- **6a. So sánh với kỳ trước.** Báo cáo thêm bảng thay đổi tỷ lệ phản hồi và số thu hồi so với kỳ liền trước.

**Luồng ngoại lệ.**

- **E1. Thiếu lý do (bước 2).** ERR-01-033 (400); "Nhập lý do cho quyết định."
- **E2. Quyết định không hợp lệ (bước 3).** ERR-01-041 (422); "Không giữ được mục có căn cứ hết hiệu lực. Chọn thu hồi hoặc bổ sung căn cứ ở Đề nghị mở rộng."
- **E3. Chưa xác thực lại hai yếu tố (bước 2).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."
- **E4. Kỳ chưa đóng khi lập báo cáo (bước 6).** ERR-01-020 (409); "Kỳ rà soát chưa hoàn tất, báo cáo chỉ có khi kỳ đã đóng."
- **E5. Kỳ không ở `DECIDING` khi xử lý (bước 2).** ERR-01-020 (409); câu hiển thị lấy từ `detail`.

**Quy tắc áp dụng.** BR-01-003, BR-01-009, BR-01-014.

**Màn hình, API.** UI-01-12; API-01-072, 074, 075; EVT-01-11, 12.
:::

### 6.30. UC-01-30 · Tra cứu và xuất danh bạ đầu mối

::: dac-ta
**Mục tiêu.** Cán bộ các cơ quan nhà nước trong tenant tìm được đầu mối kết nối, chia sẻ dữ liệu của cơ quan khác theo đúng quy định công khai đầu mối, trong khi đầu mối an ninh và dữ liệu cá nhân được bảo vệ bằng giới hạn tốc độ và kiểm toán xuất.

**Tác nhân chính.** Mọi người dùng nội bộ thuộc một tổ chức của tenant (An, Lan); TA (Minh), AU (Hoa) xuất toàn bộ.

**Tác nhân phụ.** PH-13 và PH-18 (gọi API theo `systemCode` khi cảnh báo, gửi thư), tác vụ xuất nền (FR-00-031).

**Mức ưu tiên.** M · MVP (xuất danh bạ FR-01-047 mức C, Đợt 2).

**FR hiện thực.** FR-01-045, 047.

**Truy vết.** REQ-01; BP-01, BP-07.

**Tiền điều kiện.** Người dùng đã đăng nhập, chọn tenant `T68` và thuộc một tổ chức của tenant (quyền cơ sở, không cần mã quyền riêng); xuất cần quyền xuất.

**Kích hoạt.** Người dùng mở menu Kết nối & API › Danh bạ đầu mối (UI-01-14); hoặc bấm "Xuất".

**Đảm bảo tối thiểu.** Đầu mối `SECURITY` và đầu mối không công khai chỉ TA, SO xem; mọi lượt tra cứu chịu giới hạn tốc độ; mọi lượt xuất được ghi kiểm toán kèm mục đích.

**Đảm bảo thành công.** Người dùng thấy danh sách đầu mối công khai đúng phạm vi; bản xuất có dòng ghi chú mục đích sử dụng và chỉ chứa đầu mối công khai (hoặc theo quyền TA, AU).

**Luồng chính.**

1. An cần liên hệ Sở Tư pháp: mở UI-01-14 và gõ "Tư pháp".
2. Hệ thống gọi API-01-076, kiểm tra giới hạn tốc độ `directory.rateLimitPerMinute` (60 lượt mỗi phút mỗi người dùng; vượt: ERR-01-045).
3. Hệ thống truy vấn đầu mối `ACTIVE` có cờ công khai của `T68`; không trả đầu mối `SECURITY` và đầu mối không công khai trừ khi người gọi là TA hoặc SO.
4. Hệ thống trả họ tên, chức vụ, điện thoại, thư điện tử, tổ chức, HTTT và `lastConfirmedAt`.
5. An bấm tổ chức "Sở Tư pháp"; hệ thống gọi API-01-077 và trả toàn bộ đầu mối công khai của cơ quan, gồm đầu mối của mọi HTTT cơ quan đó chủ quản.
6. Hoa bấm "Xuất", chọn bộ lọc và định dạng, nhập mục đích "Rà soát đầu mối phục vụ kiểm toán tuân thủ". Hệ thống (API-01-079) kiểm tra quyền xuất và mục đích; dưới 5.000 dòng trả ngay, từ 5.000 dòng chạy nền; thêm dòng ghi chú "Dữ liệu liên hệ cán bộ, chỉ dùng cho mục đích đã nêu"; ghi kiểm toán người xuất, bộ lọc, số dòng, mục đích.

**Luồng thay thế.**

- **1a. Phân hệ khác tra đầu mối.** PH-13 khi cảnh báo, PH-18 khi gửi thư gọi API theo `systemCode` và loại đầu mối với scope `onboarding:internal-read`.
- **6a. Có quyền xem nhưng không có quyền xuất.** Chỉ xuất được trang hiện hành, tối đa 100 dòng.

**Luồng ngoại lệ.**

- **E1. Vượt giới hạn tra cứu (bước 2, 6).** ERR-01-045 (429); "Bạn tra cứu quá nhanh. Thử lại sau {n} giây."
- **E2. Không thấy tổ chức (bước 5).** ERR-01-001 (404); "Không tìm thấy tổ chức."
- **E3. Thiếu mục đích khi xuất (bước 6).** ERR-01-033 (400); "Nhập mục đích sử dụng bản xuất."

**Quy tắc áp dụng.** BR-01-027, BR-01-030.

**Màn hình, API.** UI-01-14; API-01-076, 077, 079.
:::

### 6.31. UC-01-31 · Cảnh báo tổ chức thiếu đầu mối và nhắc cập nhật

::: dac-ta
**Mục tiêu.** Không có HTTT hoạt động nào mất đầu mối kỹ thuật mà không ai biết; thông tin đầu mối luôn được xác nhận định kỳ; tổ chức thiếu đầu mối không kết nạp thêm HTTT mới cho tới khi bổ sung.

**Tác nhân chính.** `dh-connect` (tác vụ hằng ngày lúc 06:15); TA (Minh) và OR (Lan) xử lý.

**Tác nhân phụ.** PH-12 (tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức), PH-18 (thư bị trả lại), PH-13 (cảnh báo).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-046.

**Truy vết.** REQ-01; BP-01, BP-07.

**Tiền điều kiện.** Tenant có ít nhất một HTTT `ACTIVE`.

**Kích hoạt.** Tác vụ lúc 06:15 hằng ngày; sự kiện PH-12 "tài khoản đầu mối bị vô hiệu hoặc chuyển tổ chức"; sự kiện PH-18 "thư gửi đầu mối bị trả lại".

**Đảm bảo tối thiểu.** Khi PH-12 hoặc PH-18 không khả dụng thì bỏ qua nguồn đó trong lượt chạy, không đánh dấu nhầm.

**Đảm bảo thành công.** Tổ chức thiếu đầu mối được đưa vào khối "Cần xử lý" của UI-01-14; EVT-01-14 đã phát; đầu mối có thông tin cũ được nhắc xác nhận.

**Luồng chính.**

1. Lúc 06:15, `dh-connect` tìm (a) tổ chức có HTTT `ACTIVE` mà không có đầu mối `TECHNICAL` đang hoạt động; (b) đầu mối có tài khoản bị vô hiệu hoặc không còn thuộc tổ chức (từ PH-12); (c) đầu mối có thư bị trả lại (từ PH-18); (d) đầu mối có `lastConfirmedAt` quá `directory.staleMonths` (12 tháng).
2. Với (b), (c): hệ thống đặt đầu mối `INACTIVE` hoặc gắn cờ "Thư điện tử không hoạt động" và nhắc Lan, Minh.
3. Với (d): hệ thống nhắc đầu mối xác nhận thông tin còn đúng bằng một nút bấm; xác nhận ghi `lastConfirmedAt`.
4. Với (a): hệ thống đánh dấu tổ chức "Thiếu đầu mối kỹ thuật", đưa vào khối "Cần xử lý" ở UI-01-14 (API-01-078), phát EVT-01-14 và nhắc Minh mỗi tuần.
5. Lan bổ sung đầu mối kỹ thuật mới (UC-01-05); đến lượt chạy sau, dấu "Thiếu đầu mối kỹ thuật" được gỡ.
6. Trong thời gian bị đánh dấu (a), tổ chức không nộp được hồ sơ HTTT mới: UC-01-06 trả ERR-01-010.

**Luồng thay thế.**

- **1a. Tổ chức giải thể, sáp nhập.** Minh chuyển HTTT sang tổ chức kế thừa bằng UC-01-23 (đổi chủ quản); tổ chức mới thừa hưởng đầu mối (Q01-10).

**Luồng ngoại lệ.**

- **E1. PH-12 hoặc PH-18 không khả dụng (bước 1).** Bỏ qua nguồn đó trong lượt chạy và ghi nhật ký.
- **E2. Bỏ đầu mối kỹ thuật cuối cùng (bước 5, theo UC-01-05).** ERR-01-050 (409); "HTTT phải còn ít nhất một đầu mối kỹ thuật. Thêm đầu mối mới trước khi bỏ người này."
- **E3. Nộp hồ sơ khi tổ chức còn thiếu đầu mối (bước 6).** ERR-01-010 (422); "Tổ chức còn hệ thống {mã} chưa có đầu mối kỹ thuật. Bổ sung đầu mối trước khi kết nạp hệ thống mới."

**Quy tắc áp dụng.** BR-01-013, BR-01-028.

**Màn hình, API.** UI-01-14; API-01-078; EVT-01-14.
:::

### 6.32. UC-01-32 · Nhập HTTT từ hệ cũ

::: dac-ta
**Mục tiêu.** Đưa Application, publisher, subscriber của hệ cũ vào Datahub thành hồ sơ HTTT nháp để đơn vị hoàn tất và được cấp lại định danh qua quy trình kết nạp, mà không mang theo bất kỳ thông tin xác thực cũ nào.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà), TA (Minh), PO có `PERM-18-migration`.

**Tác nhân phụ.** PH-20 (danh mục tổ chức), dịch vụ quét mã độc, hộp "Việc của tôi" (giao hồ sơ cho OR).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-048.

**Truy vết.** REQ-01, REQ-22; BP-08, BP-09; LGC-APIM-019; LGC-APIM-020; LGC-HUB-010, LGC-HUB-011.

**Tiền điều kiện.** Có tệp xuất từ hệ cũ (CSV, XLSX hoặc JSON) của Application, publisher, subscriber; các tổ chức của tenant đã có ở PH-20; Hà có `PERM-18-migration`, Minh có `PERM-01-create`.

**Kích hoạt.** Hà bấm "Nhập từ hệ cũ" ở UI-01-15.

**Đảm bảo tối thiểu.** Không đọc, không lưu, không chép thông tin xác thực của hệ cũ (BR-01-033, FR-00-093); ghi tất cả hoặc không ghi gì.

**Đảm bảo thành công.** Mọi bản ghi hợp lệ thành hồ sơ `DRAFT` có `legacy_ref`, giao cho OR của tổ chức; báo cáo đối chiếu có số bí mật bỏ qua khớp số cột bí mật của tệp nguồn; HTTT không tự `ACTIVE`.

**Luồng chính.**

1. Hà tải tệp `apim-apps-T68.xlsx` (18 dòng) lên UI-01-15. Hệ thống (API-01-080) kiểm tra kiểu tệp theo nội dung và quét mã độc như UC-01-04.
2. Hệ thống phân tích tệp ở pha xem trước (ADR-056) và ánh xạ cột; không đọc các cột thông tin xác thực (Client Secret, Consumer Key, khóa tham chiếu) và đếm số cột bị bỏ.
3. Hệ thống ghép tổ chức theo tên hoặc mã đơn vị với danh mục PH-20, gợi ý tổ chức gần đúng; mục không ghép được thì để "Chọn tổ chức".
4. Hệ thống gộp bản ghi trùng giữa ba nguồn theo `legacy_ref` hoặc tên chuẩn hóa thành một HTTT có nhiều vai trò (`CONSUMER`, `PUBLISHER`, `SUBSCRIBER`).
5. Hệ thống hiển thị bản xem trước (API-01-081): 18 bản ghi gộp thành 16 HTTT, 2 trùng HTTT đã có (bỏ qua), 14 hồ sơ sẽ tạo, 1 cảnh báo, 18 giá trị bí mật đã bỏ. Hà sửa gợi ý ghép tổ chức.
6. Hà bấm "Xác nhận" (API-01-082). Hệ thống tạo tất cả hồ sơ `DRAFT` hoặc không tạo gì, gắn `legacy_ref`, giao cho OR của tổ chức qua "Việc của tôi" kèm nhắc "Hoàn tất hồ sơ để cấp lại định danh".
7. Hệ thống trả báo cáo đối chiếu: số bản ghi đọc, số hồ sơ tạo, số trùng, số cảnh báo, số bí mật bỏ qua.

**Luồng thay thế.**

- **5a. Giá trị trông như bí mật ở cột không khai báo.** Hệ thống không chép và ghi cảnh báo "Phát hiện giá trị có thể là bí mật ở cột {tên}; đã bỏ qua."
- **7a. Nhập lại sau khi sửa tệp.** Hệ thống bỏ qua HTTT đã nhập nhờ `legacy_ref`, chỉ tạo phần mới.

**Luồng ngoại lệ.**

- **E1. Tệp sai cấu trúc hoặc thiếu cột bắt buộc (bước 2).** ERR-01-042 (400); "Tệp không đúng mẫu. Tải mẫu nhập và thử lại."
- **E2. Bản ghi trùng HTTT đã có (bước 5).** ERR-01-043 (409); hiển thị ở bản xem trước, không dừng cả tệp.
- **E3. Quá số dòng cho phép (bước 1).** ERR-01-044 (422); "Giá trị {khóa} phải từ {min} đến {max}." (`legacyImport.maxRows` mặc định 5.000)
- **E4. Tệp bị loại (bước 1).** ERR-01-012, ERR-01-013 hoặc ERR-01-014 với câu thông báo như E1 đến E3 của UC-01-04.
- **E5. Lỗi ghi giữa chừng (bước 6).** Hệ thống hoàn tác toàn bộ, không tạo hồ sơ nào; Hà thử lại.

**Quy tắc áp dụng.** BR-01-018, BR-01-033.

**Màn hình, API.** UI-01-15; API-01-080, 081, 082.
:::

### 6.33. UC-01-33 · Cấu hình tham số phân hệ theo tenant

::: dac-ta
**Mục tiêu.** Mỗi tỉnh điều chỉnh hạn thẩm định, hạn bàn giao, chu kỳ rà soát và các ngưỡng khác của PH-01 theo quy chế của mình, trong biên do nền tảng đặt, mọi thay đổi có lý do và có dấu vết.

**Tác nhân chính.** TA (Minh) và PA (Hà) có `PERM-18-config`.

**Tác nhân phụ.** PH-18 (đệm tham số 60 giây), PH-12 (xác thực lại hai yếu tố).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-01-049.

**Truy vết.** REQ-01; BP-08.

**Tiền điều kiện.** Người dùng có quyền sửa tham số; giá trị mới nằm trong miền cho phép.

**Kích hoạt.** Minh mở UI-01-16, sửa một tham số và bấm "Lưu".

**Đảm bảo tối thiểu.** Không giá trị nào vượt trần của nền tảng; nới lỏng tham số an ninh luôn có lý do và ghi kiểm toán mức cao.

**Đảm bảo thành công.** Phiên bản giá trị mới có hiệu lực trong ≤ 60 giây; lịch sử ghi người đổi, thời điểm, lý do.

**Luồng chính.**

1. Minh mở UI-01-16 (API-01-083). Hệ thống hiển thị khóa, giá trị hiện hành, mặc định, miền cho phép và ý nghĩa của từng tham số `onboarding.*`.
2. Minh đổi `review.slaWorkingDays` từ 2 sang 3 vì quy chế tiếp nhận hồ sơ của `T68` và nhập lý do "Theo Quyết định tiếp nhận hồ sơ số 15/QĐ-STTTT" (giả lập).
3. Hệ thống gọi API-01-084, kiểm tra giá trị trong miền 1…10 và không vượt trần của nền tảng (ERR-01-044).
4. Hệ thống lưu phiên bản mới kèm người đổi, thời điểm, lý do; giá trị có hiệu lực trong ≤ 60 giây theo đệm tham số của PH-18.
5. Minh đổi `handover.ttlHours` từ 24 lên 48 (nới lỏng). Hệ thống yêu cầu xác thực lại hai yếu tố (LP-01-01), yêu cầu lý do và ghi kiểm toán mức cao.

**Luồng thay thế.**

- **2a. Siết chặt.** Đổi `handover.ttlHours` từ 24 xuống 12 không cần thêm thủ tục ngoài xác thực lại; chỉ nới lỏng mới cần lý do và kiểm toán mức cao.
- **2b. Khôi phục mặc định.** Minh bấm "Đặt lại"; tham số quay về giá trị của nền tảng.
- **3a. PA đặt trần nền tảng.** Hà đặt giá trị mặc định và trần cho cả nền tảng; tenant chỉ chọn trong khoảng đó.

**Luồng ngoại lệ.**

- **E1. Giá trị ngoài miền hoặc vượt trần (bước 3).** ERR-01-044 (422); "Giá trị {khóa} phải từ {min} đến {max}."
- **E2. Thiếu lý do (bước 2, 5).** ERR-01-033 (400); "Nhập lý do cho thao tác này."
- **E3. Chưa xác thực lại hai yếu tố với tham số an ninh (bước 5).** ERR-01-035 (403); "Cần xác thực lại hai yếu tố để tiếp tục."

**Quy tắc áp dụng.** BR-01-009, BR-01-014, BR-01-020.

**Màn hình, API.** UI-01-16; API-01-083, 084.
:::

### 6.34. UC-01-34 · Xem thống kê kết nạp và thời gian xử lý

::: dac-ta
**Mục tiêu.** Quản trị tỉnh, cán bộ ATTT, lãnh đạo và kiểm toán xem được thời gian kết nạp thực tế so với chỉ tiêu KPI-05 (từ nộp đến gọi được API môi trường thật ≤ 5 ngày làm việc), hồ sơ nào đang chậm và quyền nào sắp đến hạn rà soát.

**Tác nhân chính.** TA (Minh), SO (Dũng), VW, AU (Hoa), PA (Hà) có `PERM-01-read`.

**Tác nhân phụ.** PH-13 (nhận chỉ số `onboarding_*` để vẽ trên bảng điều khiển chung).

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-01-051.

**Truy vết.** REQ-01; BP-01.

**Tiền điều kiện.** Có dữ liệu kết nạp trong khoảng thời gian chọn.

**Kích hoạt.** Người dùng mở UI-01-17.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; chỉ hiển thị số liệu tổng hợp, không bí mật, không dữ liệu liên hệ.

**Đảm bảo thành công.** Người dùng thấy số HTTT theo trạng thái, thời gian từng giai đoạn, tỷ lệ trả bổ sung, hồ sơ quá hạn; chỉ số `onboarding_*` đã phát cho PH-13.

**Luồng chính.**

1. Minh mở UI-01-17 và chọn khoảng "Quý 4 năm 2026".
2. Hệ thống gọi API-01-086, tính từ lịch sử trạng thái và các bước thẩm định: số HTTT theo trạng thái; thời gian trung vị và p90 của từng giai đoạn (nộp đến phân công, thẩm định, phê duyệt, cấp định danh, kiểm thử, kích hoạt); thời gian từ nộp đến kích hoạt để đối chiếu KPI-05.
3. Hệ thống tính tỷ lệ hồ sơ bị trả bổ sung, tỷ lệ từ chối, số hồ sơ quá hạn thẩm định, số định danh sắp hết hạn, số HTTT quá hạn rà soát.
4. Hệ thống trả số liệu kèm chuỗi theo tuần cho biểu đồ; giao diện hiển thị thẻ KPI-05 và các biểu đồ.
5. Hệ thống phát các chỉ số `onboarding_applications_total`, `onboarding_stage_duration_days`, `onboarding_members_total` và các chỉ số còn lại của NFR-01-015 cho PH-13.

**Luồng thay thế.**

- **4a. Xem danh sách đằng sau con số.** Minh bấm vào một số (ví dụ "Hồ sơ quá hạn"); giao diện mở UI-01-03 với bộ lọc tương ứng (UC-01-01).

**Luồng ngoại lệ.**

- **E1. Khoảng thời gian không hợp lệ (bước 1).** ERR-01-003 (400); "Khoảng thời gian không hợp lệ."
- **E2. Không có dữ liệu trong khoảng (bước 2).** Màn hình hiện "Chưa có hồ sơ trong khoảng thời gian này."

**Quy tắc áp dụng.** BR-01-030.

**Màn hình, API.** UI-01-17; API-01-086.
:::

## 7. Luồng phụ dùng chung

Tám luồng phụ dưới đây được nhiều UC dẫn lại để không lặp mô tả. Luồng phụ không phải UC: không có kích hoạt riêng, chỉ chạy bên trong UC dẫn tới nó. Mã lỗi, câu thông báo là của FRS §9.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-01-01 | Xác thực lại hai yếu tố: thao tác nhạy cảm yêu cầu người dùng xác thực lại bằng hai yếu tố trong vòng `mfa.stepUpMinutes` (5 phút) trước khi gọi API; quá hạn trả ERR-01-035 và giao diện mở hộp xác thực lại | UC-01-12, 17, 18, 19, 20, 21, 22, 29, 33 (và mở bàn giao ở UC-01-15) |
| LP-01-02 | Bốn mắt: hệ thống so người xử lý với người lập, người nộp, người đã thẩm định và người đề nghị của cùng hồ sơ; trùng thì khóa nút ở giao diện và trả ERR-01-017 nếu gọi thẳng API; không áp dụng cho tạo hồ sơ | UC-01-08, 09, 10, 12, 17, 21, 23, 24 |
| LP-01-03 | Lý do bắt buộc: hộp thoại có ô lý do (tối thiểu 10 ký tự khi tạm ngừng); thiếu trả ERR-01-033 | UC-01-07, 11, 12, 18, 19, 20, 21, 22, 25, 29, 33 |
| LP-01-04 | Phân tích tác động và xác nhận: hiển thị số đối tượng phụ thuộc từ PH-02, PH-04, PH-05, PH-10; người dùng phải xác nhận (`confirmImpact = true`) thì mới tiếp tục, thiếu trả ERR-01-034; phân hệ thiếu thì kết quả `partial` | UC-01-19, 20, 21 |
| LP-01-05 | Cắt quyền ưu tiên cổng trước: đặt trạng thái và chặn ở APISIX trước (hiệu lực ≤ 60 giây), sau đó gọi PH-12, PH-03 và thử lại theo lịch lùi cho tới khi xong; `enforcement` từ `PENDING` sang `DONE`; cảnh báo SO khi chưa xong | UC-01-19, 20, 21, 22, 25 |
| LP-01-06 | Thông báo chỉ chứa liên kết: thư và thông báo nhắc không bao giờ chứa bí mật hay dữ liệu liên hệ cá nhân; mọi thông tin xác thực chỉ qua UC-01-15 (FR-00-062) | UC-01-06, 07, 13, 15, 18, 19, 28 |
| LP-01-07 | Tệp tải lên: kiểm tra cỡ (≤ 20 MB theo tham số), kiểu theo nội dung (PDF, DOCX, XLSX, PNG, JPG), quét mã độc, lưu mã hóa vào bucket của tenant | UC-01-04, 32 |
| LP-01-08 | Phạm vi đối tượng: đối tượng của tenant khác hoặc ngoài phạm vi vai trò trả ERR-01-001 (404) cùng thân phản hồi, không lộ sự tồn tại (BR-01-030) | Mọi UC có đọc hoặc sửa một HTTT |

: Luồng phụ dùng chung

Ngoài tám luồng phụ trên, mọi UC có gọi API ghi dữ liệu còn chịu bốn lỗi chung của hợp đồng API (D03-04-PH01 §6), không lặp ở từng UC. ERR-01-051 (409): cùng `Idempotency-Key` nhưng thân yêu cầu khác, hiển thị "Yêu cầu này đã được gửi với nội dung khác. Tải lại trang rồi thử lại." ERR-01-054 (409): yêu cầu cùng khóa đang xử lý, hiển thị "Yêu cầu đang được xử lý. Chờ vài giây rồi xem kết quả." ERR-01-052 (401, 403): thiếu hoặc hết hạn xác thực, hoặc thiếu quyền, hiển thị "Anh/chị không có quyền thực hiện thao tác này hoặc phiên đã hết hạn. Đăng nhập lại hoặc liên hệ quản trị tỉnh." ERR-01-053 (409): kết quả bước saga bất đồng bộ không khớp bước đang chờ ở UC-01-13, chỉ ghi nhật ký vận hành và không hiện cho người dùng.

## 8. Tổng hợp mã mới và đối chiếu

Tập này không tạo mã FR, API, ERR, EVT, UI mới; mọi mã đó lấy từ [D02-03-PH01](../frs/D02-03-PH01-frs-ket-nap-httt.md). Mã mới của tập: UC-01-01…34 và LP-01-01…08. Số kế tiếp còn trống của UC là 35 và của luồng phụ là 09; câu hỏi mở Q01-45…49 (dải 45–49 dành cho UC).

Đối chiếu: (1) cả 51 FR của FRS thuộc ít nhất một UC (bảng 5.4); 41 FR mức M, 9 FR mức S và 1 FR mức C đều có UC, trong đó FR-01-033 dùng ở hai UC. (2) Mọi UC có FR, UI và API (bảng 5.1, 5.2); riêng UC-01-26 không có màn hình vì là use case máy. (3) Cả 88 API (API-01-001…088) được dẫn ở bảng 5.2; UC-01-26 dẫn API-01-062 là điểm vào của tác vụ đối chiếu. (4) 17 màn hình UI-01-01…17 và 15 sự kiện EVT-01-01…15 đều xuất hiện ở ít nhất một UC. (5) Bốn mục LGC của PH-01 (LGC-APIM-019; 020, LGC-HUB-010, 011) có UC ở bảng 5.3. (6) Mã lỗi `ERR-01-nnn` ở luồng ngoại lệ đều có trong FRS §9.1; câu thông báo lấy từ FRS §9.2, nơi FRS chưa có câu riêng thì lấy từ trường `detail` theo FR-00-080 (xem chương 10).

## 9. Câu hỏi mở

> **Câu hỏi mở Q01-45:** UC-01-08 và UC-01-10 giao bước thẩm định pháp lý cho "TA hoặc người TA chỉ định" nhưng D02-08 không có vai trò pháp chế và không mã quyền nào cho phép một người thẩm định ngoài TA ghi kết luận pháp lý ngoài quy tắc OPA "thẩm định theo phân công". Cần xác nhận người được TA chỉ định (ví dụ cán bộ pháp chế của sở) giữ vai trò chuẩn nào ở D02-08 và có cần tài khoản trong realm của tenant không. Giả định của tập: TA thứ hai (Quang) làm bước pháp lý để TA còn lại phê duyệt được; tenant chỉ có một TA thì bốn mắt không đạt (liên quan Q01-01).

> **Câu hỏi mở Q01-46:** UC-01-15 chỉ tạo được liên kết bàn giao khi đầu mối kỹ thuật đã có tài khoản người dùng ở tenant (ERR-01-003), nhưng UC-01-05 cho thêm đầu mối chưa có tài khoản. Cần chốt ai tạo tài khoản cho đầu mối (nhân sự nhà thầu, Q01-05) và trong bao lâu, vì bước này nằm trong chuỗi KPI-05 (NFR-01-020, thành phần PH-01 ≤ 3 ngày làm việc). Đề xuất: UC-01-05 tự gửi yêu cầu tạo tài khoản sang PH-12 ngay khi thêm đầu mối kỹ thuật mới, và UC-01-06 cảnh báo (mức `WARNING`) khi đầu mối kỹ thuật chưa có tài khoản.

> **Câu hỏi mở Q01-47:** UC-01-21 và UC-01-22 cho "TA khác hoặc PA" xác nhận khi TA vắng (FR-01-032), nhưng ma trận D02-08 chỉ cấp `PERM-01-approve` cho TA; PA không có quyền này, và PA vốn không thuộc tenant. Tenant nhỏ chỉ có một TA không thể duyệt chấm dứt (ERR-01-017) hay xác nhận thao tác khẩn khi chính TA đó đề nghị. Cần quyết định: cấp `PERM-01-approve` cho PA trong ngữ cảnh truy cập chéo tenant có kiểm toán, hay buộc tenant luôn có tối thiểu hai TA. Giả định của tập: mỗi tenant có tối thiểu hai TA.

> **Câu hỏi mở Q01-48:** UC-01-32 nhập HTTT từ hệ cũ ở trạng thái `DRAFT`; trong giai đoạn chạy song song (strangler), Application của hệ cũ vẫn gọi API ở hệ cũ trong khi hồ sơ mới ở Datahub chưa được duyệt. Cần xác định có thêm cờ (ví dụ `legacy_active`) để TA ưu tiên duyệt các HTTT đang hoạt động ở hệ cũ và để thống kê KPI-05 không tính nhầm thời gian chờ của chúng hay không. Đề xuất: thêm cờ chỉ đọc theo `legacy_ref`, không thêm trạng thái mới cho DD-03.

> **Câu hỏi mở Q01-49:** UC-01-07 cho đơn vị rút hồ sơ đang thẩm định về `DRAFT`, đóng các bước đang mở bằng kết quả `WITHDRAWN`. FRS chỉ nói bước có dữ liệu không đổi giữ kết luận khi nộp lại sau trả bổ sung (BR-01-032), chưa nói khi nộp lại sau rút. Cần xác nhận bước đã `PASS` trước khi rút có giữ kết luận nếu dữ liệu liên quan không đổi hay thẩm định lại từ đầu. Giả định của tập: giữ kết luận như trường hợp trả bổ sung để không phạt đơn vị vì tự sửa sớm.

## 10. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây thuộc tài liệu dùng chung hoặc tập khác, nằm ngoài quyền sửa của tập này; ghi lại để đợt đồng bộ cuối thực hiện. Không có đề xuất ADR mới.

| # | Tài liệu | Đề nghị |
|---|---|---|
| 1 | D02-03-PH01 §9.2 | **Đã đồng bộ ở bản 0.2 trừ ERR-01-023 ngữ cảnh saga và ERR-01-025 ngữ cảnh phiếu xác nhận (còn dùng câu của UC; cần FRS tách câu theo ngữ cảnh).** Bổ sung câu hiển thị cho ERR-01-005 (trạng thái không phù hợp, nhiều UC dùng), ERR-01-020 (kỳ hoặc bước không ở giai đoạn tương ứng), ERR-01-023 trong ngữ cảnh saga (UC-01-13, UC-01-18), ERR-01-025 cho phiếu xác nhận rà soát (UC-01-28: "Tài khoản này không thuộc tổ chức được hỏi.") và ERR-01-044 ("Giá trị {khóa} phải từ {min} đến {max}.") vì UC đang dùng câu tự đặt hoặc câu từ `detail` |
| 2 | D02-03-PH01 FR-01-032 | Luồng thay thế "TA vắng: PA hoặc TA khác xác nhận" mâu thuẫn ma trận quyền (PA không có `PERM-01-approve`); sửa theo kết luận của Q01-47 |
| 3 | D02-08 §3.1 | Theo kết luận Q01-45 và Q01-47: nếu thêm vai trò thẩm định pháp lý hoặc cấp `PERM-01-approve` cho PA thì cập nhật ma trận và cặp loại trừ ở §4 |
| 4 | D02-07, DD-03 | Theo Q01-48: nếu thêm cờ `legacy_active` thì ghi thuộc tính chỉ đọc theo `legacy_ref`; giữ nguyên bảy giá trị `status` |
| 5 | D05-02-PH01 (tập test case) | Dùng mỗi luồng chính, thay thế, ngoại lệ của chương 6 làm một ca kiểm thử; dùng bảng 5.4 làm danh sách kiểm tra độ phủ FR; thêm ca cho mỗi luồng phụ LP-01-01…08 |
| 6 | D03-06-PH01 (tập màn hình) | Đối chiếu bảng 5.2 (UC với UI) và câu thông báo ở chương 6; UC-01-26 không có màn hình |
| 7 | D00-04 §3.2 | Chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để thêm dải `UC-01-01…34`; cập nhật cột "Tài liệu" của PH-01 ở §2 khi đủ các tập |
| 8 | D00-03 phần B | Ghi UC của PH-01 vào cột UC của bốn hàng LGC (LGC-APIM-019; 020, LGC-HUB-010, 011) theo bảng 5.3 |

: Đề nghị đồng bộ với tài liệu dùng chung và tập khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và quy chuẩn trình bày K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu, quy ước, tác nhân, năm sơ đồ use case, bốn bảng truy vết (UC với FR, UI và API, REQ, BP, LGC; độ phủ FR), 34 use case theo khối 15 mục kèm hai sơ đồ trình tự, 8 luồng phụ dùng chung, 5 câu hỏi mở và 8 đề nghị đồng bộ. Nguồn: D02-03-PH01 (bảng FR, API, UI, ERR, BR và các FR liên quan), D02-08, D02-01, D00-03 phần A |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: đồng bộ API-01-087, 088, 059 vào bảng UC với API, ghi bốn lỗi chung ERR-01-051…054 ở chương 7, thêm mục 1.4 Cấu trúc tài liệu và đoạn mở cho các mục thiếu |
