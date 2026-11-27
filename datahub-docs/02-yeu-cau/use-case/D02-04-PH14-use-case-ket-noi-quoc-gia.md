---
ma_tai_lieu: D02-04-PH14
ten: Đặc tả use case phân hệ PH-14 Kết nối quốc gia
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-14
mo_ta: Đặc tả 38 use case của phân hệ Kết nối quốc gia theo vòng đời thật của một kết nối tới các nền tảng quốc gia ở tỉnh, từ khai báo nền tảng, dịch vụ, chứng thư, hạn mức tới gọi dịch vụ, chiều vào, đồng bộ, đối soát và cắt chuyển từ hệ cũ, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH14 FRS; D03-04-PH14 API; D03-06-PH14 Màn hình; D05-02-PH14 Test case
---

# D02-04-PH14 · Đặc tả use case Kết nối quốc gia

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả 38 use case của PH-14, cổng ra duy nhất của tỉnh tới các nền tảng cấp quốc gia (NDXP, NDOP và nơi nhận đăng ký danh mục dịch vụ). Mỗi use case là một việc nghiệp vụ trọn vẹn có người thực hiện, điều kiện, luồng chính, luồng thay thế và luồng ngoại lệ, để hội đồng thẩm định thấy hệ thống phục vụ ai và kỹ sư, kiểm thử viên dùng ngay làm căn cứ thiết kế màn hình, API và ca kiểm thử.

**Phạm vi.** 38 use case phủ toàn bộ 57 yêu cầu chức năng của [D02-03-PH14](../frs/D02-03-PH14-frs-ket-noi-quoc-gia.md): 48 FR mức M, 8 FR mức S và 1 FR mức C (FR-14-057 gom vào UC-14-36). Use case đi theo vòng đời thật của một kết nối quốc gia: quản trị khai báo nền tảng và dịch vụ, Cán bộ ATTT nạp chứng thư, hai người cùng duyệt bật nền tảng, HTTT của tỉnh gọi dịch vụ đã được cung cấp lại, cổng quốc gia ký số, đếm hạn mức, dùng đệm, chịu lỗi, nhận yêu cầu từ trung ương, đồng bộ danh mục, đối soát giao dịch và cắt chuyển khỏi kết nối NGSP cũ.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-03 và CMP-LAW-19 (Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu), CMP-LAW-12 (Thông tư 13/2017, đang chờ đối chiếu), CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025), CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026, TCVN 14423:2026), CMP-LAW-16 (Luật An ninh mạng 116/2025) và CMP-LAW-01 (Luật Dữ liệu số).

**Những điểm hội đồng cần lưu ý.** (1) Ba use case then chốt về an toàn là UC-14-09 (gọi dịch vụ: mục đích khai thác, ký số, xác minh chữ ký, đệm, hạn mức trong một lượt), UC-14-18 (chứng thư: người nạp khác người duyệt, cả hai xác thực nhiều yếu tố) và UC-14-21 (chữ ký sai xử lý như sự cố an ninh). (2) Tám loại thay đổi cần người thứ hai duyệt (BR-14-022) xuất hiện ở UC-14-02, 04, 05, 08, 18, 20, 22, 26, 31, 36; mỗi nơi dùng chung một luồng phụ (LP-14-01). (3) HTTT của tỉnh không bao giờ giữ thông tin xác thực quốc gia: UC-14-07 và UC-14-09 chỉ cho HTTT gọi bằng token của Datahub. (4) Ba use case chạy bằng máy (UC-14-09, 16, 27) gần như không có giao diện riêng nhưng quyết định hành vi lúc chạy nên được đặc tả cùng mức chi tiết. (5) Có 5 câu hỏi mở riêng của tập use case ở chương 9, ngoài 14 câu hỏi của FRS.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Use case | 38 (UC-14-01…38), chia sáu nhóm |
| FR được phủ | 57 trên 57 (M: 48, S: 8, C: 1) |
| Luồng phụ dùng chung | 6 (LP-14-01…06) |
| Tác nhân người | 8 vai trò (PA, TA, TO, SO, IE, IA, AU, VW) |
| Tác nhân máy và hệ thống | HTTT tỉnh, cổng quốc gia, PH-02, 03, 04, 06, 07, 09, 12, 13, OpenBao, NDXP, NDOP |
| Mã mới của tập | UC-14-01…38, LP-14-01…06, Q14-45…49 |

: Con số chính của tập use case PH-14

## 1. Giới thiệu

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các phân hệ và hệ thống bên ngoài để hoàn thành từng việc nghiệp vụ của PH-14: từ khai báo nền tảng quốc gia tới khai thác, đối soát và chuyển đổi từ hệ cũ. Phạm vi là toàn bộ FR-14-001…057. Chức năng dùng chung FR-00 (đăng nhập, phân quyền, kiểm toán, hộp "Việc của tôi", thông báo) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Hành vi chi tiết từng bước (kiểm tra, mã lỗi, câu thông báo) nằm ở FR tương ứng; use case mô tả trình tự và vai trò. Tài liệu không đặc tả thiết kế bên trong (D03-02-PH14), bảng dữ liệu (D03-03-PH14) hay định nghĩa API (D03-04-PH14).

### 1.2. Người đọc

Bảng dưới chỉ ra mỗi nhóm người đọc nên đọc phần nào của tài liệu này, để hội đồng thẩm định, đội phát triển và đội kiểm thử không phải đọc toàn bộ ba mươi tám use case.

| Người đọc | Phần cần đọc |
|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 3 (tác nhân), chương 4 (sơ đồ tổng), chương 5 (truy vết) |
| Kỹ sư giao diện, BFF | Chương 6, đối chiếu mục "Màn hình, API" của từng use case |
| Kỹ sư `dh-integration`, `dh-runtime` | Chương 6 (nhất là UC-14-09, 16, 23…25, 27) và chương 7 |
| Cán bộ ATTT | UC-14-18…21, 34, 35 |
| Kiểm thử viên | Chương 6: mỗi luồng chính, thay thế, ngoại lệ là một ca kiểm thử ở D05-02-PH14 |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và tài liệu tham chiếu

Thuật ngữ, chữ viết tắt và vai trò (PA, TA, TO, SO, IE, IA, AU, VW) dùng chung với [D02-03-PH14](../frs/D02-03-PH14-frs-ket-noi-quoc-gia.md) §1.4 và D00-01. Tài liệu tham chiếu: D02-03-PH14 (FRS, nguồn của mọi mã lỗi và câu thông báo), D03-04-PH14 (API), D03-06-PH14 (màn hình), D05-02-PH14 (ca kiểm thử), D02-08 (ma trận phân quyền), D00-03 phần A (kiểm kê hệ cũ NGSP).

### 1.4. Cấu trúc tài liệu

Tài liệu đi từ quy ước đọc, tác nhân và sơ đồ tổng, qua các bảng truy vết, đến đặc tả chi tiết từng use case; bảng dưới nêu nội dung từng chương.

| Chương | Nội dung |
|---|---|
| 2 | Quy ước đọc đặc tả |
| 3 | Tác nhân và use case chính của từng tác nhân |
| 4 | Sơ đồ use case tổng, sáu hình theo nhóm |
| 5 | Bảng tổng hợp: use case và FR, màn hình, API, REQ, quy trình, hệ cũ |
| 6 | Đặc tả chi tiết 38 use case, mỗi use case một khối 15 mục |
| 7 | Sáu luồng phụ dùng chung |
| 8 | Tổng hợp mã mới và đối chiếu |
| 9 | Câu hỏi mở |

: Cấu trúc của tài liệu

## 2. Quy ước đọc đặc tả

Mỗi use case đặc tả bằng một khối hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ (kèm mã lỗi và câu thông báo lấy từ FRS §9.2), Quy tắc áp dụng, Màn hình và API. Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `3a`) và quay lại luồng chính. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh và kết thúc use case hoặc quay lại bước nêu rõ. Mã lỗi có số từ 101 trở lên là lỗi của cổng quốc gia (mặt phẳng dữ liệu): người dùng cuối là cán bộ HTTT nhận lỗi qua trường `detail` của API, hoặc người vận hành xem ở UI-14-12.

Dữ liệu ví dụ đều giả lập, tỉnh `T68`. Người dùng: **Lan** (TA, Sở KH&CN), **An** (IE), **Bình** (IA), **Chi** (TO), **Dũng** (SO), **Hà** (PA), **Mai** (AU). HTTT: `HT-TUPHAP` (Sở Tư pháp), `HT-DVC` (cổng dịch vụ công), `HT-MOTCUA`, `HT-QLVB`, `HT-BAOCAO`. Nền tảng: `ndxp-t68` (NDXP), `ndop-t68` (NDOP, đặc tả tạm). Dịch vụ: `lltp-tra-trang-thai`, `bhxh-tra-ho-gia-dinh`, `dkdn-ho-so-trong-ngay`, `vbqppl-tim-toan-van`. Số liệu ví dụ lấy theo giả định tỉnh quy mô vừa của D02-01 (GĐ-01…07).

## 3. Tác nhân

Tác nhân chính là người hoặc hệ thống khởi động use case và nhận kết quả; tác nhân phụ tham gia một bước. Bảng dưới liệt kê tác nhân và các use case mà tác nhân là chính.

| Tác nhân | Loại | Use case chính |
|---|---|---|
| ROLE-TENANT_ADMIN (Lan) | Chính | 01, 02, 04, 06, 07, 17, 22, 26, 31, 36, 37, 38 (và mọi UC của IE) |
| ROLE-INTEGRATION_ENGINEER (An) | Chính | 01, 02, 04…08, 37, 38 |
| ROLE-INTEGRATION_APPROVER (Bình) | Chính | 02, 04, 05, 08, 18, 20, 22, 31, 36 (người duyệt) |
| ROLE-TENANT_OPERATOR (Chi) | Chính | 03, 17, 23, 24, 25, 29, 32, 33 |
| ROLE-SECURITY_OFFICER (Dũng) | Chính | 03, 18…21, 26, 34, 35 |
| ROLE-PLATFORM_ADMIN (Hà) | Chính | 01, 04, 15 (đối tượng `COMMON`) |
| ROLE-AUDITOR (Mai), ROLE-VIEWER | Chính | 33, 35 (Mai); xem ở 01, 04, 32 |
| HTTT của tỉnh (scope `national.invoke.*`) | Chính (máy) | 09, 10, 11, 12, 14 |
| Cổng quốc gia (`dh-runtime`, hồ sơ `national-gateway`) | Chính (máy) | 09, 16, 23, 25 |
| PH-04 | Chính (máy) | 10, 13, 27 |
| PH-07 | Chính (máy) | 15 |
| PH-06 | Chính (máy) | 30 |
| NDXP, NDOP (hệ thống ngoài) | Chính (máy) ở 27, 28; phụ ở các UC còn lại | 27, 28 |
| OpenBao | Phụ | 01, 09, 16, 17, 18, 27, 33, 34 |
| PH-02, PH-03 | Phụ | 07, 26, 29, 35 |
| PH-05, PH-09, PH-12, PH-13, PH-18 | Phụ | Nhiều use case |
| Valkey, Kafka, PostgreSQL | Phụ | 09, 10, 23, 24 |

: Tác nhân của PH-14 và use case chính

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, sơ đồ tổng chia sáu hình theo nhóm nghiệp vụ: nền tảng và dịch vụ (Hình 1), gọi dịch vụ và bộ điều hợp (Hình 2), xác thực, chữ ký và chứng thư (Hình 3), hạn mức, đệm và chịu lỗi (Hình 4), chiều vào và đồng bộ (Hình 5), giám sát và chuyển đổi (Hình 6).

```{.mermaid caption="Use case nền tảng và dịch vụ quốc gia"}
flowchart LR
  TA([Quản trị tenant])
  IE([Kỹ sư tích hợp])
  IA([Người duyệt tích hợp])
  TO([Vận hành tenant])
  SO([Cán bộ ATTT])
  subgraph NT["Nền tảng"]
    U01["UC-14-01 Khai báo nền tảng"]
    U02["UC-14-02 Bật nền tảng"]
    U03["UC-14-03 Tạm ngừng, ngừng dùng"]
  end
  subgraph DV["Dịch vụ và định tuyến"]
    U04["UC-14-04 Khai báo dịch vụ"]
    U05["UC-14-05 Nạp đặc tả"]
    U06["UC-14-06 Đối chiếu danh mục"]
    U07["UC-14-07 Cung cấp lại"]
    U08["UC-14-08 Bảng định tuyến"]
  end
  TA --> U01 & U02 & U04 & U06 & U07
  IE --> U01 & U02 & U04 & U05 & U06 & U07 & U08
  IA --> U02 & U08
  TO --> U03
  SO --> U03
```

Hình 1 cho thấy hai bước đứng đầu mọi việc của phân hệ: có nền tảng được bật (nhóm trái) rồi mới có dịch vụ và định tuyến (nhóm phải). Chỉ UC-14-02 và UC-14-08 có người duyệt vì đó là hai điểm bốn mắt của nhóm; tạm ngừng (UC-14-03) cố ý không cần duyệt để vận hành chặn được ngay khi có sự cố.

```{.mermaid caption="Use case gọi dịch vụ quốc gia và bộ điều hợp"}
flowchart LR
  HT([HTTT của tỉnh])
  P4([PH-04])
  P7([PH-07])
  subgraph GOI["Gọi dịch vụ"]
    U09["UC-14-09 Gọi qua điểm gọi chung"]
    U10["UC-14-10 Gọi bất đồng bộ"]
  end
  subgraph BDH["Bộ điều hợp theo nhóm"]
    U11["UC-14-11 Tư pháp, hộ tịch"]
    U12["UC-14-12 Bảo hiểm xã hội"]
    U13["UC-14-13 Hồ sơ cấp mã ĐVQHNS"]
    U14["UC-14-14 Doanh nghiệp, văn bản"]
    U15["UC-14-15 Danh mục dùng chung"]
  end
  HT --> U09 & U10 & U11 & U12 & U14
  P4 --> U10 & U13
  P7 --> U15
  U11 -.->|dùng| U09
  U12 -.->|dùng| U09
  U13 -.->|dùng| U09
  U14 -.->|dùng| U09
```

Hình 2 cho thấy UC-14-09 là lõi dùng chung: mọi bộ điều hợp theo nhóm (nét đứt) đi qua cùng một điểm gọi với cùng chuỗi kiểm tra, ký, đệm, hạn mức. UC-14-15 tách riêng vì khách gọi là PH-07, không phải HTTT, và đi qua cổng tiếp hợp có quy tắc riêng (BR-14-036).

```{.mermaid caption="Use case xác thực, chữ ký số và chứng thư"}
flowchart LR
  GW([Cổng quốc gia])
  TA([Quản trị tenant])
  TO([Vận hành tenant])
  SO([Cán bộ ATTT])
  IA([Người duyệt tích hợp])
  subgraph XT["Xác thực"]
    U16["UC-14-16 Lấy và làm mới token"]
    U17["UC-14-17 Xoay thông tin xác thực"]
  end
  subgraph CT["Chứng thư và chữ ký"]
    U18["UC-14-18 Nạp, kích hoạt chứng thư"]
    U19["UC-14-19 Theo dõi hạn, thu hồi"]
    U20["UC-14-20 Chuỗi tin cậy và CRL"]
    U21["UC-14-21 Sự cố chữ ký"]
  end
  GW --> U16
  TA --> U17
  TO --> U17
  SO --> U18 & U19 & U20 & U21
  IA --> U18 & U20
```

Hình 3 gom các use case nhạy cảm nhất của phân hệ vào tay Cán bộ ATTT: người giữ chứng thư không phải người quyết định dữ liệu nào đi đâu (nhóm dịch vụ do kỹ sư tích hợp quản lý ở Hình 1). Cổng quốc gia là tác nhân chính duy nhất của UC-14-16 vì token được lấy và làm mới hoàn toàn bằng máy.

```{.mermaid caption="Use case hạn mức, đệm và chịu lỗi"}
flowchart LR
  GW([Cổng quốc gia])
  TA([Quản trị tenant])
  TO([Vận hành tenant])
  U22["UC-14-22 Hạn mức, phân bổ"]
  U23["UC-14-23 Đếm hạn mức, ưu tiên"]
  U24["UC-14-24 Đệm, dữ liệu quá hạn"]
  U25["UC-14-25 Ngắt mạch, thử lại"]
  TA --> U22
  TO --> U23 & U24 & U25
  GW --> U23 & U25
```

Hình 4 cho thấy hạn mức do trung ương áp là tài nguyên khan hiếm: tỉnh khai báo và phân bổ một lần (UC-14-22), còn việc đếm, hoãn tác vụ nền, dùng đệm và ngắt mạch chạy tự động ở cổng, người vận hành chỉ giám sát và can thiệp tay.

```{.mermaid caption="Use case chiều vào và đồng bộ"}
flowchart LR
  TA([Quản trị tenant])
  SO([Cán bộ ATTT])
  TO([Vận hành tenant])
  IA([Người duyệt tích hợp])
  NX([NDXP])
  P6([PH-06])
  subgraph VAO["Chiều vào"]
    U26["UC-14-26 Đăng ký điểm cuối"]
    U27["UC-14-27 Tiếp nhận yêu cầu"]
    U28["UC-14-28 Thông báo thay đổi"]
  end
  subgraph DB["Đồng bộ"]
    U29["UC-14-29 Danh mục dịch vụ lên Bộ"]
    U30["UC-14-30 Cầu nối dữ liệu chủ"]
    U31["UC-14-31 Công bố dữ liệu mở"]
  end
  TA --> U26 & U31
  SO --> U26
  TO --> U29
  IA --> U31
  NX --> U27 & U28
  P6 --> U30
```

Hình 5 phân biệt hai chiều: chiều vào do trung ương khởi động (NDXP là tác nhân chính ở UC-14-27, 28) nên điểm cuối phải đăng ký và duyệt trước (UC-14-26); đồng bộ do tỉnh khởi động theo lịch hoặc theo yêu cầu và luôn có biên nhận để đối soát.

```{.mermaid caption="Use case giám sát, đối soát, quản trị và chuyển đổi"}
flowchart LR
  TO([Vận hành tenant])
  SO([Cán bộ ATTT])
  AU([Kiểm toán viên])
  TA([Quản trị tenant])
  IE([Kỹ sư tích hợp])
  subgraph GS["Giám sát và đối soát"]
    U32["UC-14-32 Tổng quan, kiểm tra chủ động"]
    U33["UC-14-33 Tra cứu, đối soát"]
    U34["UC-14-34 Xem nội dung đầy đủ"]
    U35["UC-14-35 Nhật ký khai thác"]
  end
  subgraph QT["Quản trị và chuyển đổi"]
    U36["UC-14-36 Tham số, báo cáo"]
    U37["UC-14-37 Chạy song song"]
    U38["UC-14-38 Nhập hệ cũ, cắt chuyển"]
  end
  TO --> U32 & U33
  SO --> U33 & U34 & U35
  AU --> U33 & U35
  TA --> U36 & U37 & U38
  IE --> U37 & U38
```

Hình 6 cho thấy kiểm toán viên chỉ đi tới bằng chứng đã che nội dung (UC-14-33, 35); nội dung thô chỉ Cán bộ ATTT xem được, có lý do và để lại vết (UC-14-34). Ba use case chuyển đổi (UC-14-37, 38) là phần tạm thời, dừng khi kết nối NGSP cũ được tắt.

## 5. Bảng tổng hợp use case và truy vết

Chương này gồm ba bảng: use case với FR hiện thực, use case với màn hình và API, use case với REQ, quy trình và chức năng hệ cũ. Mức ưu tiên theo FR cao nhất của use case; use case có FR mức S hoặc C ghi rõ đợt.

### 5.1. Use case và FR

Bảng dưới nối từng use case với các yêu cầu chức năng FR-14 mà nó hiện thực, kèm tác nhân chính và mức ưu tiên.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-14-01 | Khai báo nền tảng quốc gia và kiểm tra kết nối | TA | M | 001, 002, 047 |
| UC-14-02 | Gửi duyệt và duyệt bật nền tảng | TA, IA | M | 003 |
| UC-14-03 | Tạm ngừng, tiếp tục và ngừng dùng nền tảng | TO, SO | M | 003 |
| UC-14-04 | Khai báo dịch vụ quốc gia và xem hợp đồng | IE | M | 004, 005, 006 |
| UC-14-05 | Nạp đặc tả có phiên bản và xử lý thay đổi phá vỡ | IE | M | 008 |
| UC-14-06 | Đối chiếu danh mục dịch vụ với NDXP | IE | M | 007 |
| UC-14-07 | Cung cấp lại dịch vụ quốc gia cho HTTT | IE | M | 009 |
| UC-14-08 | Quản lý bảng định tuyến | IE, IA | M | 012, 013 |
| UC-14-09 | Gọi dịch vụ quốc gia qua điểm gọi chung | HTTT (máy) | M | 010, 011, 012, 014, 015, 026, 027 |
| UC-14-10 | Gọi bất đồng bộ qua hàng chờ | HTTT, PH-04 | M | 016 |
| UC-14-11 | Tra cứu lý lịch tư pháp và hộ tịch | HTTT | M | 017, 018 |
| UC-14-12 | Tra cứu dữ liệu bảo hiểm xã hội | HTTT | M | 019 |
| UC-14-13 | Đồng bộ hồ sơ cấp mã số ĐVQHNS | PH-04 | M | 020 |
| UC-14-14 | Tra cứu đăng ký doanh nghiệp và văn bản quy phạm | HTTT | M | 021, 022 |
| UC-14-15 | Kéo danh mục dùng chung quốc gia cho PH-07 | PH-07 | M | 023 |
| UC-14-16 | Lấy và làm mới token của nền tảng | Cổng quốc gia | M | 024 |
| UC-14-17 | Xoay vòng và cấp lại thông tin xác thực | TO, TA | M | 025 |
| UC-14-18 | Nạp và kích hoạt chứng thư số | SO, IA | M | 028 |
| UC-14-19 | Theo dõi hạn, thay thế và thu hồi chứng thư | SO | M | 029 |
| UC-14-20 | Cập nhật chuỗi tin cậy và danh sách thu hồi | SO | M | 030 |
| UC-14-21 | Xử lý sự cố chữ ký | SO | M | 027, 031 |
| UC-14-22 | Khai báo hạn mức và phân bổ theo HTTT | TA | M | 032, 034 |
| UC-14-23 | Đếm hạn mức, cảnh báo và hoãn theo ưu tiên | Cổng quốc gia, TO | M | 033 |
| UC-14-24 | Quản lý đệm và dữ liệu quá hạn | TO | M (035, 037), S (036) | 035, 036, 037 |
| UC-14-25 | Ngắt mạch và thử lại | Cổng quốc gia, TO | M | 038 |
| UC-14-26 | Đăng ký và bật điểm cuối chiều vào | TA, SO | M | 039 |
| UC-14-27 | Tiếp nhận yêu cầu từ quốc gia và chuyển luồng PH-04 | NDXP | M | 040, 041 |
| UC-14-28 | Tiếp nhận thông báo thay đổi từ quốc gia | NDXP | S, Đợt 2 | 042 |
| UC-14-29 | Đồng bộ danh mục dịch vụ lên Bộ | TO | M | 043, 046 |
| UC-14-30 | Cầu nối đồng bộ dữ liệu chủ hai chiều | PH-06 | S, Đợt 3 | 044 |
| UC-14-31 | Công bố dữ liệu mở lên NDOP | TA, IA | S, Đợt 3 | 045, 046 |
| UC-14-32 | Theo dõi tổng quan và kiểm tra kết nối chủ động | TO | M | 047, 048 |
| UC-14-33 | Tra cứu, đối soát giao dịch và xuất bằng chứng | TO, AU, SO | M (049), S, Đợt 2 (051) | 049, 051 |
| UC-14-34 | Xem nội dung bản tin đầy đủ có lý do | SO | M | 050 |
| UC-14-35 | Nhật ký khai thác và cảnh báo bất thường | SO, AU | M (052), S, Đợt 2 (053) | 052, 053 |
| UC-14-36 | Tham số phân hệ và báo cáo hạn mức, đệm | TA | M (tham số), C, Đợt 3 (báo cáo) | 054, 057 |
| UC-14-37 | Chạy song song với kết nối NGSP cũ | TA, IE | S | 055 |
| UC-14-38 | Nhập cấu hình dịch vụ từ hệ cũ và cắt chuyển | TA, IE | S | 056 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Bảng dưới nối từng use case với màn hình UI-14 người dùng thao tác và các API-14 mà màn hình gọi, để đội phát triển và kiểm thử lần theo được một luồng nghiệp vụ.

| UC | UI | API |
|---|---|---|
| UC-14-01 | UI-14-02, 03 | API-14-001, 002, 003, 004, 059 |
| UC-14-02 | UI-14-02, 03, 17 | API-14-003, 008, 009 |
| UC-14-03 | UI-14-02, 03, 17 | API-14-005, 006, 007 |
| UC-14-04 | UI-14-04, 05 | API-14-010, 011, 012, 013 |
| UC-14-05 | UI-14-05 | API-14-018, 019, 020 |
| UC-14-06 | UI-14-06 | API-14-014, 015, 016, 017 |
| UC-14-07 | UI-14-05 | API-14-021, 022, 023 |
| UC-14-08 | UI-14-07, 17 | API-14-024, 025, 026, 027, 028 |
| UC-14-09 | UI-14-05, 12, 13 | API-14-075 |
| UC-14-10 | UI-14-12 | API-14-076, 077, 078 |
| UC-14-11 | UI-14-04, 05, 12 | API-14-075, 076 |
| UC-14-12 | UI-14-04, 05, 13 | API-14-075 |
| UC-14-13 | UI-14-04, 05, 09 | API-14-075 |
| UC-14-14 | UI-14-04, 05 | API-14-075 |
| UC-14-15 | UI-14-04, 11 | API-14-079, 080, 081, 082, 083 |
| UC-14-16 | UI-14-03 | API-14-040 |
| UC-14-17 | UI-14-03 | API-14-039, 040 |
| UC-14-18 | UI-14-08, 17 | API-14-030, 032, 033 |
| UC-14-19 | UI-14-08 | API-14-029, 031, 034 |
| UC-14-20 | UI-14-08, 17 | API-14-035, 036 |
| UC-14-21 | UI-14-14, 08 | API-14-037, 038 |
| UC-14-22 | UI-14-09, 17 | API-14-041, 042, 044, 045 |
| UC-14-23 | UI-14-01, 09 | API-14-041, 043 |
| UC-14-24 | UI-14-09, 05 | API-14-046, 047 |
| UC-14-25 | UI-14-01 | API-14-086 |
| UC-14-26 | UI-14-10, 17 | API-14-048, 049, 050, 051, 052, 090 |
| UC-14-27 | UI-14-10 | API-14-084 |
| UC-14-28 | UI-14-10 | API-14-085 |
| UC-14-29 | UI-14-11 | API-14-053, 054, 055, 057 |
| UC-14-30 | UI-14-11 | API-14-056 |
| UC-14-31 | UI-14-11 | API-14-087, 088, 053, 055, 057 |
| UC-14-32 | UI-14-01, 02 | API-14-058, 059, 060 |
| UC-14-33 | UI-14-12 | API-14-061, 062, 064 |
| UC-14-34 | UI-14-12 | API-14-063 |
| UC-14-35 | UI-14-13 | API-14-065, 066, 067, 068 |
| UC-14-36 | UI-14-16, 13 | API-14-069, 070, 071 |
| UC-14-37 | UI-14-15 | API-14-072, 073, 089 |
| UC-14-38 | UI-14-15 | API-14-074 |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Cột LGC ghi chức năng hệ cũ (kiểm kê D00-03 phần A) mà use case thay thế; "Không" nghĩa là chức năng mới, không có ở hệ cũ.

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-14-01 | REQ-14, REQ-13 | BP-06 | LGC-NGSP-008 (khai báo nền tảng thay phụ lục kết nối) |
| UC-14-02 | REQ-14 | BP-06 | Không |
| UC-14-03 | REQ-14 | BP-06, BP-07 | Không |
| UC-14-04 | REQ-14 | BP-06 | LGC-NGSP-001…007 (dịch vụ theo nhóm) |
| UC-14-05 | REQ-14 | BP-06 | LGC-NGSP-001…007 |
| UC-14-06 | REQ-14 | BP-06 | LGC-NGSP-001…008 |
| UC-14-07 | REQ-14, REQ-02 | BP-06, BP-01 | LGC-NGSP-001…007 |
| UC-14-08 | REQ-14 | BP-06 | Không |
| UC-14-09 | REQ-14, REQ-09 | BP-06 | LGC-NGSP-001…007 (nền chung) |
| UC-14-10 | REQ-14, REQ-04 | BP-06, BP-02 | LGC-NGSP-001, LGC-NGSP-002 |
| UC-14-11 | REQ-14 | BP-06 | LGC-NGSP-001, LGC-NGSP-002 |
| UC-14-12 | REQ-14, REQ-09 | BP-06, BP-01 | LGC-NGSP-003 |
| UC-14-13 | REQ-14 | BP-06 | LGC-NGSP-004 |
| UC-14-14 | REQ-14 | BP-06 | LGC-NGSP-005, LGC-NGSP-007 |
| UC-14-15 | REQ-14, REQ-07 | BP-03, BP-06 | LGC-NGSP-006, LGC-DMDC-019 |
| UC-14-16 | REQ-14 | BP-06 | LGC-NGSP-008 |
| UC-14-17 | REQ-14 | BP-06, BP-07 | LGC-NGSP-008 |
| UC-14-18 | REQ-14 | BP-06 | Không |
| UC-14-19 | REQ-14 | BP-06, BP-07 | Không |
| UC-14-20 | REQ-14 | BP-06 | Không |
| UC-14-21 | REQ-14 | BP-06, BP-07 | Không |
| UC-14-22 | REQ-14 | BP-06, BP-01 | Không |
| UC-14-23 | REQ-14, REQ-13 | BP-06, BP-07 | Không |
| UC-14-24 | REQ-14 | BP-06 | Không |
| UC-14-25 | REQ-14 | BP-06, BP-07 | Không |
| UC-14-26 | REQ-14, REQ-03 | BP-06 | Không |
| UC-14-27 | REQ-14, REQ-03, REQ-04 | BP-06, BP-02 | LGC-NGSP-001 (nhận hồ sơ đăng ký) |
| UC-14-28 | REQ-14, REQ-07 | BP-03, BP-06 | LGC-DMDC-019 |
| UC-14-29 | REQ-14, REQ-02, REQ-13 | BP-03, BP-06 | Không |
| UC-14-30 | REQ-14, REQ-06 | BP-06 | Không |
| UC-14-31 | REQ-14, REQ-09 | BP-06 | Không |
| UC-14-32 | REQ-14, REQ-13 | BP-07 | Không |
| UC-14-33 | REQ-14, REQ-13 | BP-07 | Không |
| UC-14-34 | REQ-14, REQ-13, REQ-09 | BP-07 | Không |
| UC-14-35 | REQ-14, REQ-13, REQ-09 | BP-07 | Không |
| UC-14-36 | REQ-14, REQ-13, REQ-18 | BP-06 | Không |
| UC-14-37 | REQ-14, REQ-22 | BP-09 | LGC-NGSP-008 |
| UC-14-38 | REQ-14, REQ-22 | BP-09 | LGC-NGSP-008 |

: Use case, REQ, quy trình và hệ cũ

## 6. Đặc tả chi tiết use case

Sáu nhóm dưới đây theo thứ tự UC-14-01…38. Mỗi use case một khối hai cột 15 mục; luồng nào đi qua nhiều thành phần có sơ đồ trình tự ngay sau khối.

**Nhóm 1 · Nền tảng và dịch vụ quốc gia (UC-14-01…08).** Nhóm này dựng "bảng chỉ đường" mà mọi lượt gọi sau đó dựa vào: nền tảng nào được bật, dịch vụ nào có hợp đồng và đặc tả nào, dịch vụ nào đã được cung cấp lại cho HTTT, lượt gọi đi đường nào. Quản trị tenant và kỹ sư tích hợp là người làm chính; hai điểm bốn mắt là bật nền tảng (UC-14-02) và luật định tuyến (UC-14-08).

### 6.1. UC-14-01 · Khai báo nền tảng quốc gia và kiểm tra kết nối

::: dac-ta
**Mục tiêu.** Quản trị tenant có một nền tảng quốc gia ở trạng thái `DRAFT`, gắn với kết nối đã có ở PH-05, và có kết quả kiểm tra kết nối đạt trong 24 giờ để đủ điều kiện gửi duyệt bật; địa chỉ, cách xác thực nằm ở cấu hình, bí mật không đi qua PH-14.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan).

**Tác nhân phụ.** ROLE-INTEGRATION_ENGINEER (An) hỗ trợ khai kết nối; PH-05; OpenBao; NDXP (đích kiểm tra); bộ chạy kiểm tra.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-001, 002, 047.

**Truy vết.** REQ-14, REQ-13; quy trình BP-06; LGC-NGSP-008 (thay phụ lục kết nối NGSP).

**Tiền điều kiện.** Lan có `PERM-14-admin`; kết nối `ndxp-oauth` loại `oauth2-client` đã tạo ở PH-05 (UC-05-01) với giá trị TEST; địa chỉ đích đã có trong danh sách egress của `T68`.

**Kích hoạt.** Lan bấm "+ Khai báo nền tảng" ở UI-14-02.

**Đảm bảo tối thiểu.** Không có thông tin xác thực nào được lưu ở PH-14 hay hiển thị ở giao diện; thất bại giữa chừng thì không có nền tảng nửa vời.

**Đảm bảo thành công.** Nền tảng `ndxp-t68` ở `DRAFT`, có bản ghi kiểm tra kết nối đạt gần nhất, sự kiện EVT-14-01 đã phát.

**Luồng chính.**

1. Lan mở UI-14-02. Hệ thống gọi API-14-001 và hiện danh sách nền tảng của `T68` (đang trống) kèm thẻ tổng theo trạng thái và sức khỏe.
2. Lan bấm "+ Khai báo nền tảng". Hệ thống mở trình hướng dẫn UI-14-03.
3. Lan chọn loại `NDXP`, nhập mã `ndxp-t68`, tên "NDXP của tỉnh T68", đơn vị chủ quản "Cục Chuyển đổi số quốc gia", chọn kết nối `ndxp-oauth`, cách xác thực `PRIVATE_KEY_JWT`, thời hạn chờ mặc định 15.000 ms.
4. Lan bấm "Tiếp tục". Hệ thống gọi API-14-002 kèm `Idempotency-Key`: kiểm tra quyền, mã theo mẫu và chưa dùng, kết nối tồn tại cùng tenant và loại phù hợp với `authMode`, địa chỉ nằm trong egress.
5. Hệ thống lưu nền tảng ở `DRAFT`, ghi kiểm toán, phát EVT-14-01, trả `201` và chuyển Lan sang bước "Kiểm tra kết nối".
6. Lan bấm "Kiểm tra kết nối". Hệ thống gọi API-14-059; bộ chạy kiểm tra phân giải tên miền, mở TCP, bắt tay TLS và lấy token thử, mỗi bước ghi kết quả và thời gian.
7. Hệ thống hiện kết quả từng bước: DNS 12 ms, TCP 31 ms, TLS 58 ms (chứng thư máy chủ hết hạn 14/09/2027), token 240 ms, tất cả đạt. Nền tảng chuyển `TESTED`.
8. Lan thấy nút "Gửi duyệt bật" sáng lên; use case tiếp tục ở UC-14-02.

**Luồng thay thế.**

- **3a. Nền tảng dùng đặc tả tạm.** Với `ndop-t68` (NDOP chưa công bố đặc tả), Lan đặt `specStatus = PROVISIONAL`; giao diện hiện nhãn "đặc tả tạm thời" trên mọi thẻ và danh sách (BR-14-025).
- **3b. Nhân bản.** Lan bấm "Nhân bản" trên một nền tảng sẵn có để khai báo nhanh môi trường thử của trung ương; mã phải đổi.
- **3c. Hà khai báo nền tảng dùng chung.** Quản trị nền tảng (Hà) chọn `scope = COMMON` cho nền tảng `ndxp-common` phục vụ danh mục dùng chung toàn quốc (UC-14-15); chỉ PA có tùy chọn này.
- **4a. Địa chỉ chưa trong egress.** Hệ thống vẫn lưu bản khai báo và tạo đề nghị bổ sung egress cho Lan; bước 6 trả `EGRESS_DENIED` kèm lối tắt tới đề nghị, kiểm tra lại sau khi được bổ sung.
- **6a. Kiểm tra sâu.** Lan chọn "Kiểm tra sâu" (`deep = true`): hệ thống thêm một lời gọi nhẹ tới thao tác `healthOperation` ở mức ưu tiên `BACKGROUND`, có tính hạn mức.

**Luồng ngoại lệ.**

- **E1. Mã đã dùng (bước 4).** ERR-14-002; "Mã ndxp-t68 đã được dùng (kể cả nền tảng đã ngừng dùng). Chọn mã khác."; quay lại bước 3.
- **E2. Kết nối không tồn tại hoặc sai loại (bước 4).** ERR-14-005; "Kết nối ndxp-oauth không tồn tại hoặc loại không phù hợp với cách xác thực đã chọn."; quay lại bước 3.
- **E3. Không phải PA mà chọn `COMMON` (bước 4).** Lỗi 403 theo FR-00; "Chỉ quản trị nền tảng được khai báo nền tảng dùng chung toàn quốc."
- **E4. OpenBao không khả dụng khi kiểm tra tham chiếu bí mật (bước 4).** ERR-14-035; "Kho bí mật tạm thời không khả dụng. Thử lại sau ít phút."; không lưu gì.
- **E5. Chưa đặt thông tin xác thực ở môi trường đang kiểm tra (bước 6).** ERR-14-034; "Chưa có thông tin xác thực cho nền tảng này ở môi trường TEST. Khai ở kết nối ndxp-oauth trong phân hệ Bộ điều hợp."
- **E6. Kiểm tra tay quá nhiều (bước 6).** ERR-14-029; "Đã kiểm tra quá 20 lần trong một giờ. Thử lại sau 12 phút."; nút "Kiểm tra kết nối" bị khóa.
- **E7. Một bước kiểm tra không đạt (bước 7).** Nền tảng giữ `DRAFT`; kết quả kèm gợi ý (ví dụ "Chứng thư máy chủ do CA lạ cấp, cập nhật chuỗi tin cậy ở UC-14-20"); Lan sửa rồi kiểm tra lại.

**Quy tắc áp dụng.** BR-14-005, 006, 025, 029, 031.

**Màn hình, API.** UI-14-02, 03; API-14-001, 002, 003, 004, 059.
:::

### 6.2. UC-14-02 · Gửi duyệt và duyệt bật nền tảng

::: dac-ta
**Mục tiêu.** Nền tảng chỉ nhận lưu lượng thật sau khi hai người khác nhau đồng ý, để một cấu hình sai hay một người dùng đơn lẻ không đưa được lưu lượng ra trung ương.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan, người đề nghị); ROLE-INTEGRATION_APPROVER (Bình, người duyệt).

**Tác nhân phụ.** Hộp "Việc của tôi" (FR-00-070); ROLE-INTEGRATION_ENGINEER (An) có thể là người đề nghị; Kafka; cổng quốc gia.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-003 (đề nghị và duyệt bật).

**Truy vết.** REQ-14; BP-06; không có chức năng tương ứng ở hệ cũ.

**Tiền điều kiện.** Nền tảng `ndxp-t68` ở `TESTED` với kiểm tra kết nối đạt trong 24 giờ trên đúng phiên bản kết nối; nếu có dịch vụ yêu cầu ký thì đã có chứng thư `ACTIVE` đúng mục đích (UC-14-18); Lan có `PERM-14-admin`, Bình có `PERM-14-approve`.

**Kích hoạt.** Lan bấm "Gửi duyệt bật" ở UI-14-03.

**Đảm bảo tối thiểu.** Nền tảng không chuyển `ACTIVE` khi chưa có người duyệt hợp lệ; mọi lần gửi, duyệt, từ chối đều có kiểm toán.

**Đảm bảo thành công.** Nền tảng `ACTIVE`; cổng quốc gia nạp cấu hình trong 30 giây; kiểm toán ghi người đề nghị, người duyệt, ý kiến, kết quả kiểm tra tham chiếu.

**Luồng chính.**

1. Lan bấm "Gửi duyệt bật". Hệ thống kiểm tra kiểm tra kết nối đạt trong 24 giờ, chứng thư `ACTIVE` cho dịch vụ ký, chưa có yêu cầu đang chờ.
2. Hệ thống gọi API-14-008, chuyển nền tảng sang `PENDING_ACTIVATION` và tạo việc trong hộp "Việc của tôi" của người có `PERM-14-approve`; Lan nhận phản hồi `202` kèm `pendingApprovalId`.
3. Bình mở việc ở UI-14-17 và xem tóm tắt: kết nối `ndxp-oauth`, kết quả kiểm tra 09:40 hôm nay đạt, chứng thư `cks-t68-2026` còn 301 ngày, 6 dịch vụ `DRAFT` sẽ chịu ảnh hưởng.
4. Bình chọn "Duyệt" và nhập ý kiến. Hệ thống gọi API-14-009 và kiểm tra Bình khác Lan và khác người sửa gần nhất (LP-14-01).
5. Hệ thống chuyển nền tảng sang `ACTIVE`, ghi kiểm toán, phát EVT-14-01.
6. Cổng quốc gia nhận sự kiện và nạp cấu hình mới trong 30 giây; Lan nhận thông báo "Nền tảng ndxp-t68 đã được bật".

**Luồng thay thế.**

- **3a. Từ chối.** Bình chọn "Từ chối" kèm lý do (10…500 ký tự, LP-14-02); nền tảng về `TESTED`, Lan nhận thông báo và có thể sửa rồi gửi lại.
- **1a. An đề nghị thay Lan.** An (có `PERM-14-admin` được TA cấp) gửi duyệt; Lan hoặc Bình duyệt được vì khác An.
- **4a. Người duyệt là TA khác.** `PERM-14-approve` cũng thuộc TA; TA thứ hai duyệt được nếu khác người đề nghị.

**Luồng ngoại lệ.**

- **E1. Chưa kiểm tra đạt trong 24 giờ (bước 1).** ERR-14-008; "Hãy chạy kiểm tra kết nối đạt trong 24 giờ gần đây trước khi gửi duyệt."; nút "Kiểm tra kết nối" sáng; quay lại UC-14-01 bước 6.
- **E2. Thiếu chứng thư ký (bước 1).** ERR-14-037; "Nền tảng có dịch vụ yêu cầu ký số nhưng chưa có chứng thư đang dùng đúng mục đích."; chuyển sang UC-14-18.
- **E3. Đã có yêu cầu chờ duyệt (bước 1).** ERR-14-006; "Đã có yêu cầu kích hoạt đang chờ duyệt cho đối tượng này."
- **E4. Người duyệt trùng người đề nghị hoặc người sửa gần nhất (bước 4).** ERR-14-007; "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."; nút "Duyệt" bị khóa ở giao diện.
- **E5. Trạng thái không cho phép (bước 1 hoặc 4).** ERR-14-004; "Đối tượng đang ở trạng thái ACTIVE hoặc đã được người khác sửa, không thực hiện được thao tác này. Tải lại và thử lại."

**Quy tắc áp dụng.** BR-14-017, 022.

**Màn hình, API.** UI-14-02, 03, 17; API-14-003, 008, 009.
:::

### 6.3. UC-14-03 · Tạm ngừng, tiếp tục và ngừng dùng nền tảng

::: dac-ta
**Mục tiêu.** Vận hành chặn được ngay lưu lượng tới một nền tảng khi trung ương báo sự cố hoặc khi nghi ngờ lộ khóa, mà không mất cấu hình; ngừng dùng hẳn khi nền tảng không còn được sử dụng.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi) tạm ngừng, tiếp tục; ROLE-SECURITY_OFFICER (Dũng) tạm ngừng khẩn cấp; ROLE-TENANT_ADMIN (Lan) ngừng dùng và tiếp tục sau khẩn cấp.

**Tác nhân phụ.** Cổng quốc gia; Kafka; PH-13 (cảnh báo); HTTT đang gọi.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-003 (tạm ngừng, tiếp tục, ngừng dùng).

**Truy vết.** REQ-14; BP-06, BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Tạm ngừng: nền tảng `ACTIVE`; Chi, Dũng có `PERM-14-operate`. Tiếp tục: nền tảng `SUSPENDED`. Ngừng dùng: Lan có `PERM-14-admin`.

**Kích hoạt.** Chi bấm "Tạm ngừng" ở UI-14-02 khi trung ương thông báo bảo trì từ 22:00 đến 23:30; hoặc Dũng bấm khi nghi lộ khóa.

**Đảm bảo tối thiểu.** Lượt đang chạy kết thúc không quá 30 giây, không có lượt mới lọt qua sau 30 giây; mọi chuyển trạng thái có người, lý do, thời điểm.

**Đảm bảo thành công.** Nền tảng ở trạng thái đích (`SUSPENDED`, `ACTIVE` hoặc `RETIRED`) đúng máy trạng thái; cổng đã nạp cấu hình.

**Luồng chính.**

1. Chi chọn `ndxp-t68` ở UI-14-02, bấm "Tạm ngừng". Hệ thống hiện hộp xác nhận nêu số HTTT và số lượt gọi 24 giờ sẽ bị ảnh hưởng (38 HTTT, 41.200 lượt).
2. Chi nhập lý do "Trung ương bảo trì 22:00-23:30 theo công văn 456/CĐS" và xác nhận. Hệ thống gọi API-14-005, kiểm tra lý do 10…500 ký tự và trạng thái `ACTIVE`.
3. Hệ thống chuyển nền tảng `SUSPENDED`, ghi kiểm toán, phát EVT-14-01.
4. Cổng quốc gia nạp cấu hình và từ chối lượt mới tới nền tảng này trong 30 giây với ERR-14-117; lượt đang chạy kết thúc không quá 30 giây. HTTT gọi lúc 22:05 nhận `503` kèm câu "Dịch vụ hoặc nền tảng đã ngừng hoặc đang tạm ngừng, không nhận lượt mới".
5. Lúc 23:35, Chi bấm "Tiếp tục". Hệ thống gọi API-14-006, chuyển nền tảng về `ACTIVE`, phát EVT-14-01; cổng nhận lượt mới trong 30 giây.
6. Hệ thống gửi thông báo cho TA và TO của `T68` về mỗi lần chuyển trạng thái (tuân thủ FR-00-060).

**Luồng thay thế.**

- **1a. Tạm ngừng khẩn cấp.** Dũng nghi khóa của tỉnh bị lộ nên bấm "Tạm ngừng" mà không cần duyệt. Nền tảng chuyển `SUSPENDED` kèm dấu "tạm ngừng bởi ATTT"; chỉ TA mới tiếp tục được, Chi không (E3).
- **5a. Ngừng dùng.** Lan bấm "Ngừng dùng" với lý do "Chuyển sang nền tảng mới"; hệ thống gọi API-14-007, chuyển `RETIRED` (trạng thái cuối, mã không dùng lại). Nền tảng `SUSPENDED` cũng ngừng dùng được.
- **5b. Tiếp tục sau khi xoay thông tin xác thực.** Nếu lý do tạm ngừng là nghi lộ khóa, Lan chỉ tiếp tục sau khi UC-14-17 hoàn tất và kiểm tra kết nối đạt.

**Luồng ngoại lệ.**

- **E1. Thiếu hoặc quá ngắn lý do (bước 2).** ERR-14-003; "Giá trị lý do không hợp lệ: cần từ 10 đến 500 ký tự."
- **E2. Trạng thái không cho phép (bước 2 hoặc 5).** ERR-14-004; "Đối tượng đang ở trạng thái ACTIVE hoặc đã được người khác sửa, không thực hiện được thao tác này. Tải lại và thử lại." (ví dụ tạm ngừng nền tảng đã `SUSPENDED`).
- **E3. Chi tiếp tục nền tảng bị ATTT tạm ngừng (bước 5).** Lỗi 403 theo FR-00; "Nền tảng đang bị tạm ngừng bởi cán bộ ATTT, chỉ quản trị tỉnh được tiếp tục."
- **E4. HTTT gọi trong lúc tạm ngừng.** ERR-14-117 (503) ở phía bên gọi; giao dịch ghi `REJECTED`, người vận hành thấy ở UI-14-12.

**Quy tắc áp dụng.** BR-14-022 (không áp dụng cho tạm ngừng), 032.

**Màn hình, API.** UI-14-02, 03, 17; API-14-005, 006, 007.
:::

### 6.4. UC-14-04 · Khai báo dịch vụ quốc gia và xem hợp đồng

::: dac-ta
**Mục tiêu.** Kỹ sư tích hợp khai báo một dịch vụ quốc gia với đủ chính sách vận hành (nhóm, giao thức, mức nhạy cảm, đệm, ký số, ưu tiên, yêu cầu mục đích), và xem trọn hợp đồng, đặc tả, nhãn đối chiếu, hạn mức, lịch sử của dịch vụ ở một nơi.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** ROLE-INTEGRATION_APPROVER (Bình) khi giảm kiểm soát; ROLE-PLATFORM_ADMIN (Hà) cho dịch vụ `COMMON`.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-004, 005, 006.

**Truy vết.** REQ-14; BP-06; LGC-NGSP-001…007 (dịch vụ theo nhóm).

**Tiền điều kiện.** An có `PERM-14-service`; nền tảng `ndxp-t68` tồn tại, không `RETIRED`.

**Kích hoạt.** An bấm "+ Khai báo dịch vụ" ở UI-14-04, hoặc chấp nhận một đề xuất "thêm mới" từ đối chiếu danh mục (UC-14-06).

**Đảm bảo tối thiểu.** Cấu hình tự mâu thuẫn không bao giờ được lưu; thay đổi chính sách không làm đứt lượt gọi đang chạy.

**Đảm bảo thành công.** Dịch vụ `vbqppl-tim-toan-van` ở `DRAFT` với đủ chính sách; sự kiện EVT-14-02 đã phát; hệ thống nhắc nạp đặc tả.

**Luồng chính.**

1. An mở UI-14-04, lọc nhóm `VBQPPL`. Hệ thống gọi API-14-010 và hiện danh sách (chưa có dịch vụ nào), dịch vụ mang nhãn `SPEC_CHANGED`, `DISCONTINUED` xếp đầu.
2. An bấm "+ Khai báo dịch vụ" và nhập: mã `vbqppl-tim-toan-van`, nền tảng `ndxp-t68`, `Service-code` `VBQPPL_TIM_TOAN_VAN`, nhóm `VBQPPL`, giao thức `REST`, thao tác `READ`, mức `PUBLIC`.
3. An đặt `cacheable = true`, `cacheTtlSeconds = 3600`, `staleAllowed = true`, `priority = NORMAL`, `signingMode = NONE`, `verifyMode = NONE`, `purposeRequired = false`, thời hạn chờ 15.000 ms.
4. An bấm "Lưu". Hệ thống gọi API-14-011 kèm `Idempotency-Key`: kiểm tra quyền, mã theo mẫu và chưa dùng, nền tảng tồn tại, tính nhất quán chính sách (không đệm khi `SENSITIVE` hay ghi), thời hạn đệm không vượt `14.cache.max-ttl-seconds`.
5. Hệ thống lưu dịch vụ `DRAFT`, ghi kiểm toán, phát EVT-14-02, trả `201`, và nhắc An nạp đặc tả (UC-14-05) để dịch vụ chuyển `ACTIVE` được.
6. An mở chi tiết dịch vụ ở UI-14-05. Hệ thống gọi API-14-012 và hiện các tab Tổng quan, Hợp đồng, Đặc tả, Đệm và hạn mức, Cung cấp lại, Lịch sử với chỉ số 24 giờ, mức dùng hạn mức, danh sách HTTT được cấp quyền gọi.
7. An sửa `cacheTtlSeconds` thành 1800 qua API-14-013 kèm `If-Match`; thay đổi có hiệu lực ở cổng trong 30 giây, không khởi động lại.

**Luồng thay thế.**

- **2a. Điền sẵn từ đối chiếu.** Khi đến từ UC-14-06, biểu mẫu đã có mã, `Service-code`, nhóm; An chỉ bổ sung chính sách.
- **7a. Giảm kiểm soát một dịch vụ `ACTIVE`.** Khi An hạ mức nhạy cảm, tắt `signingMode` hoặc tắt `purposeRequired`, hệ thống đòi lý do và tạo yêu cầu duyệt, giữ cấu hình cũ tới khi Bình duyệt (LP-14-01); tăng kiểm soát có hiệu lực ngay.
- **6a. Xem phiên bản đặc tả cũ.** An chọn phiên bản cũ ở tab "Đặc tả" để so sánh với bản đang dùng.
- **1b. Dịch vụ dùng chung toàn quốc.** Hà khai báo dịch vụ ở nền tảng `COMMON`; tenant khác thấy và dùng được nhưng không sửa (BR-14-029).

**Luồng ngoại lệ.**

- **E1. Mã đã dùng (bước 4).** ERR-14-002; "Mã dịch vụ vbqppl-tim-toan-van đã được dùng (kể cả dịch vụ đã ngừng). Chọn mã khác."
- **E2. Nền tảng không tồn tại (bước 4).** ERR-14-001; "Không tìm thấy nền tảng ndxp-t68."
- **E3. Dịch vụ mức Nhạy cảm hoặc thao tác ghi mà bật đệm (bước 4).** ERR-14-038; "Dịch vụ mức Nhạy cảm hoặc dịch vụ ghi không được bật đệm."
- **E4. Thời hạn đệm vượt trần (bước 4).** ERR-14-036; "Thời hạn đệm vượt mức tối đa 86400 giây của tỉnh."
- **E5. Hai người sửa cùng lúc (bước 7).** ERR-14-004 (412); "Dịch vụ đã được người khác sửa. Xem khác biệt và chọn ghi đè hoặc tải lại."
- **E6. Dịch vụ không tồn tại hoặc thuộc tenant khác (bước 6).** ERR-14-001; "Không tìm thấy dịch vụ vbqppl-tim-toan-van."

**Quy tắc áp dụng.** BR-14-002, 014, 022, 024, 025, 029.

**Màn hình, API.** UI-14-04, 05; API-14-010, 011, 012, 013.
:::

### 6.5. UC-14-05 · Nạp đặc tả có phiên bản và xử lý thay đổi phá vỡ

::: dac-ta
**Mục tiêu.** Đặc tả (OpenAPI, WSDL, XSD, lược đồ JSON) của từng dịch vụ được giữ theo phiên bản, kiểm tra hợp lệ, so sánh với bản đang dùng; thay đổi phá vỡ không lọt vào môi trường thật khi chưa được duyệt; lệch so với trung ương được phát hiện trong 24 giờ.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** ROLE-INTEGRATION_APPROVER (Bình); bộ chạy kiểm tra tự động; dịch vụ quét mã độc; cổng quốc gia.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-008.

**Truy vết.** REQ-14; BP-06; LGC-NGSP-001…007.

**Tiền điều kiện.** Dịch vụ `hotich-tra-ket-qua` (SOAP) tồn tại ở `DRAFT`, `ACTIVE` hoặc `DEPRECATED`; An có `PERM-14-service`.

**Kích hoạt.** An bấm "Nạp đặc tả" ở UI-14-05; hoặc bộ chạy kiểm tra lấy `specUrl` mỗi 24 giờ (nhánh 1a).

**Đảm bảo tối thiểu.** Phiên bản đã `ACTIVE` bất biến; tệp lỗi hay nhiễm mã độc không được lưu; cổng không bao giờ chạy bằng đặc tả chưa kích hoạt.

**Đảm bảo thành công.** Có đúng một phiên bản `ACTIVE` cho dịch vụ; bản cũ `SUPERSEDED`; nhãn `SPEC_CHANGED` được xóa; cổng nạp đặc tả mới trong 30 giây.

**Luồng chính.**

1. An tải tệp `hotich-v1.3.0.wsdl` (1,2 MB), chọn loại `WSDL`, nhập `specVersion = 1.3.0` và ghi chú "Trung ương đổi tên trường ngày sinh".
2. Hệ thống gọi API-14-019 và kiểm tra tệp: ≤ 5 MB, quét mã độc, phân tích XML cấm khai báo DTD và thực thể ngoài (chống XXE).
3. Hệ thống tính `checksum`, so với phiên bản 1.2.0 đang `ACTIVE` (không trùng số phiên bản khác nội dung).
4. Hệ thống tính khác biệt có cấu trúc: thao tác, tham số, kiểu, trường bắt buộc; phát hiện trường `ngaySinh` bị xóa nên đánh dấu `breaking = true`.
5. Hệ thống lưu phiên bản 1.3.0 ở `DRAFT` và hiển thị bảng khác biệt; vì `breaking`, yêu cầu tăng số chính của hợp đồng và duyệt bởi Bình (LP-14-01).
6. An tăng hợp đồng lên 2.0 và gửi duyệt; Bình xem khác biệt, duyệt. Hệ thống ghi kiểm toán, giữ bản 1.3.0 `DRAFT` chờ kích hoạt.
7. An bấm "Kích hoạt" (API-14-020). Hệ thống kiểm tra dịch vụ và nền tảng đủ điều kiện, đặt 1.3.0 `ACTIVE`, 1.2.0 `SUPERSEDED`, xóa nhãn `SPEC_CHANGED`, phát EVT-14-02.
8. Cổng quốc gia nạp đặc tả mới trong 30 giây; An thử chuyển đổi một bản tin mẫu ở tab "Đặc tả" để xác nhận.

**Luồng thay thế.**

- **1a. Phát hiện lệch tự động.** Bộ chạy kiểm tra lấy `specUrl` qua egress, thấy khác bản `ACTIVE`: hệ thống không thay gì, đặt nhãn `SPEC_CHANGED`, tạo cảnh báo cho An và lưu bản tải về ở `DRAFT` để so sánh; An tiếp tục từ bước 4.
- **4a. Thay đổi tương thích.** Không có trường bị xóa hay đổi kiểu: `breaking = false`, bước 5 và 6 bỏ qua duyệt, An kích hoạt ngay.
- **7a. Đặc tả cho dịch vụ `DRAFT`.** Kích hoạt đặc tả đầu tiên cùng điều kiện nền tảng `ACTIVE` đưa dịch vụ sang `ACTIVE` (UC-14-04 bước 5).

**Luồng ngoại lệ.**

- **E1. Tệp không đọc được, vượt giới hạn hay không an toàn (bước 2).** ERR-14-011; "Tệp đặc tả không đọc được: thực thể ngoài không được phép."
- **E2. Trùng số phiên bản khác nội dung (bước 3).** ERR-14-010; "Phiên bản 1.3.0 đã tồn tại với nội dung khác. Dùng số phiên bản mới."
- **E3. Thay đổi phá vỡ chưa duyệt (bước 7).** ERR-14-012; "Đặc tả có thay đổi phá vỡ ở trường ngaySinh. Cần người duyệt xác nhận và tăng số chính của hợp đồng."
- **E4. Chưa đủ điều kiện kích hoạt (bước 7).** ERR-14-009; "Dịch vụ chưa có đặc tả đang dùng hoặc nền tảng chưa hoạt động nên chưa kích hoạt được."
- **E5. Không tải được `specUrl` (nhánh 1a).** ERR-14-131; cảnh báo cho An, cổng tiếp tục dùng bản đã lưu; "Không lấy được đặc tả từ xa. Hệ thống dùng bản đã lưu."
- **E6. Người duyệt trùng người đề nghị (bước 6).** ERR-14-007; "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."

**Quy tắc áp dụng.** BR-14-022, 024, 025.

**Màn hình, API.** UI-14-05; API-14-018, 019, 020.
:::

### 6.6. UC-14-06 · Đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP

::: dac-ta
**Mục tiêu.** Khi nhận được danh mục dịch vụ hiện hành của NDXP, đối chiếu từng dịch vụ và gán nhãn Còn, Đổi đặc tả hoặc Ngừng, để dịch vụ đổi đặc tả chỉ phải sửa bộ điều hợp và dịch vụ ngừng bị chặn trước khi gây lỗi cho người dân (GĐ-02).

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Lan); dịch vụ quét mã độc; cổng quốc gia (nguồn từ xa); NDXP; PH-13 (thông báo cho chủ HTTT).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-007.

**Truy vết.** REQ-14; BP-06; LGC-NGSP-001…008; GĐ-02.

**Tiền điều kiện.** An có `PERM-14-service`; có nguồn danh mục hiện hành: tệp JSON, CSV, XLSX từ trung ương hoặc nền tảng hỗ trợ thao tác liệt kê dịch vụ; chưa có phiên đối chiếu cùng nền tảng đang chạy.

**Kích hoạt.** An bấm "Đối chiếu danh mục" ở UI-14-06 và chọn nguồn.

**Đảm bảo tối thiểu.** Chạy thử không làm đổi nhãn nào; tệp lỗi không được áp dụng một phần.

**Đảm bảo thành công.** Nhãn đối chiếu của các dịch vụ được chọn đã cập nhật; phiên `SERVICE_RECONCILE` lưu 3 năm.

**Luồng chính.**

1. An chọn nền tảng `ndxp-t68`, nguồn `FILE`, tải `danh-muc-dich-vu-2026-11.xlsx` (214 dòng), giữ `dryRun = true`.
2. Hệ thống gọi API-14-014, kiểm tra tệp (loại, ≤ 10 MB, quét mã độc) và đọc từng dòng, báo lỗi theo dòng và cột nếu có.
3. Hệ thống ghép từng dòng với dịch vụ đã khai báo theo `nationalServiceCode` và nền tảng; so dấu vân tay đặc tả (địa chỉ, phiên bản, lược đồ) với bản đang dùng.
4. Hệ thống lưu phiên đối chiếu và hiện kết quả xem trước qua API-14-015: trong 48 dịch vụ đã khai báo, 44 `STILL`, 3 `SPEC_CHANGED`, 1 `DISCONTINUED`; 6 dịch vụ có trong danh mục mà chưa khai báo (thêm mới).
5. An chọn các đề xuất cần áp dụng và bấm "Áp dụng" (API-14-016); với `SPEC_CHANGED`, hệ thống tạo việc nạp đặc tả cho An (UC-14-05); với `DISCONTINUED`, chuyển dịch vụ `DEPRECATED` và thông báo chủ HTTT đang được cấp quyền gọi; với "thêm mới", mở UC-14-04 điền sẵn.
6. Hệ thống phát EVT-14-02 và hiện tổng kết: 3 việc nạp đặc tả, 1 dịch vụ ngừng ảnh hưởng 2 HTTT, 6 đề xuất thêm mới.

**Luồng thay thế.**

- **1a. Nguồn từ xa.** An chọn `REMOTE`; hệ thống gọi thao tác liệt kê dịch vụ của nền tảng qua cổng. Nền tảng không hỗ trợ thao tác liệt kê thì hệ thống hướng dẫn dùng tệp.
- **5a. Gán nhãn tay.** An đổi nhãn một dịch vụ riêng lẻ qua API-14-017 kèm lý do (ví dụ trung ương xác nhận dịch vụ vẫn còn dù không có trong tệp).
- **1b. Chạy thật ngay.** An đặt `dryRun = false` khi đã tin nguồn; hệ thống vẫn hiển thị kết quả trước khi gán nhãn.

**Luồng ngoại lệ.**

- **E1. Tệp không đọc được hoặc thiếu cột bắt buộc (bước 2).** ERR-14-032; "Dòng 37, cột Service-code: để trống. Chưa có dữ liệu nào được áp dụng."
- **E2. Đã có phiên đối chiếu cùng nền tảng (bước 2).** ERR-14-026; "Đang có phiên cùng loại chạy. Chờ phiên đó xong rồi thử lại."
- **E3. Nền tảng từ xa không phản hồi (nhánh 1a).** ERR-14-101; "Nền tảng quốc gia chưa phản hồi. Dùng tệp danh mục hoặc thử lại sau."

**Quy tắc áp dụng.** BR-14-024, 025.

**Màn hình, API.** UI-14-06; API-14-014, 015, 016, 017.
:::

### 6.7. UC-14-07 · Cung cấp lại dịch vụ quốc gia cho HTTT của tỉnh

::: dac-ta
**Mục tiêu.** Đóng gói một dịch vụ quốc gia thành API của Datahub trong danh mục dịch vụ, để HTTT của tỉnh đăng ký, được duyệt và gọi bằng token Datahub mà không biết, không giữ thông tin xác thực quốc gia, đồng thời chỉ nhận trường dữ liệu cần thiết.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Lan); người duyệt công bố ở PH-02 (ROLE-CATALOG_APPROVER, Khoa); PH-02; PH-03 (APISIX); cổng quốc gia; HTTT `HT-TUPHAP` (đăng ký sử dụng ở bước sau).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-009.

**Truy vết.** REQ-14, REQ-02; BP-06, BP-01; LGC-NGSP-001…007.

**Tiền điều kiện.** Dịch vụ `lltp-tra-trang-thai` `ACTIVE` với đặc tả `ACTIVE`; chưa có cung cấp lại cho dịch vụ này ở `T68`; An có `PERM-14-service`.

**Kích hoạt.** An bấm "Cung cấp lại cho HTTT" ở tab "Cung cấp lại" của UI-14-05.

**Đảm bảo tối thiểu.** PH-14 không tự công bố API; trường ngoài danh sách `responseFields` không bao giờ trả cho HTTT; khi PH-02 lỗi không có cung cấp lại nửa vời.

**Đảm bảo thành công.** `service_exposure` ở `ACTIVE`; API loại "dịch vụ quốc gia" có trong danh mục PH-02; tuyến APISIX đã thêm; cổng đã nạp hợp đồng, trường trả về và hạn mức.

**Luồng chính.**

1. An chọn dịch vụ, nhập đường dẫn `/quoc-gia/tu-phap/lltp/trang-thai`, `contractVersion = 1.0`, danh sách trường được trả (`dossierCode`, `status`, `receivedAt`, `resultDate`), hạn mức mặc định 200 lượt mỗi ngày cho mỗi HTTT, `requiresApproval = true`.
2. Hệ thống gọi API-14-022 và kiểm tra dịch vụ đủ điều kiện, đường dẫn không xung đột với API khác ở PH-02, `responseFields` chỉ gồm trường có trong đặc tả; với dịch vụ `RESTRICTED` trở lên, trường định danh phải được chọn có chủ đích (không chọn thì cảnh báo).
3. Hệ thống gọi PH-02 tạo bản nháp API loại "dịch vụ quốc gia" kèm hợp đồng, gói, hạn mức mặc định; `service_exposure` ở `PENDING_PUBLISH`; An thấy `201`.
4. Khoa duyệt công bố ở PH-02; PH-02 phát sự kiện đã công bố; PH-03 thêm tuyến APISIX tới cổng quốc gia.
5. Hệ thống PH-14 nhận sự kiện, đặt cung cấp lại `ACTIVE`, ghi kiểm toán, phát EVT-14-14; cổng nạp hợp đồng và hạn mức.
6. HTTT `HT-TUPHAP` thấy API trong danh mục và đăng ký sử dụng như mọi API khác (BP-01, ngoài phân hệ). Từ lúc đăng ký được duyệt, HTTT gọi được qua UC-14-09/11.

**Luồng thay thế.**

- **2a. Sửa trường trả về hoặc hạn mức mặc định.** An gọi API-14-022 lần nữa; hệ thống tạo phiên bản hợp đồng mới. Thay đổi tương thích giữ số chính, thay đổi phá vỡ cần tăng số chính và chạy song song hai phiên bản theo quy định PH-02.
- **5a. Gỡ cung cấp lại.** An bấm "Gỡ"; API ở PH-02 sang `DEPRECATED`, hệ thống phát EVT-14-14, HTTT đang dùng nhận thông báo từ PH-02.
- **4a. Khoa từ chối.** PH-02 báo từ chối; cung cấp lại trở về nháp, An sửa theo ý kiến rồi gửi lại.

**Luồng ngoại lệ.**

- **E1. Dịch vụ chưa đủ điều kiện hoặc đường dẫn xung đột (bước 2).** ERR-14-025; "Dịch vụ lltp-tra-trang-thai chưa đủ điều kiện cung cấp lại: đường dẫn đã được API khác dùng."
- **E2. PH-02 không khả dụng (bước 3).** ERR-14-027; "Phân hệ liên quan chưa phản hồi. Thử lại sau ít phút."; không tạo bản nháp.
- **E3. Dịch vụ không tồn tại hoặc thuộc tenant khác (bước 1).** ERR-14-001; "Không tìm thấy dịch vụ lltp-tra-trang-thai."

**Quy tắc áp dụng.** BR-14-007, 009, 024, 029.

**Màn hình, API.** UI-14-05; API-14-021, 022, 023.
:::

### 6.8. UC-14-08 · Quản lý bảng định tuyến

::: dac-ta
**Mục tiêu.** Phân công dữ liệu giữa các nền tảng quốc gia và đích dự phòng được cấu hình tập trung, có căn cứ văn bản, có mô phỏng trước khi áp dụng, có hai người duyệt, và nạp nóng không khởi động lại.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An, tạo, sửa); ROLE-INTEGRATION_APPROVER (Bình, duyệt).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Lan); cổng quốc gia; Kafka.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-012 (mô phỏng), FR-14-013.

**Truy vết.** REQ-14; BP-06; không có ở hệ cũ (SRS cũ FR-14-002).

**Tiền điều kiện.** An có `PERM-14-route`, Bình có `PERM-14-approve`; hai dịch vụ `lltp-tra-trang-thai` và `lltp-tra-trang-thai-b` `ACTIVE` ở hai nền tảng khác nhau.

**Kích hoạt.** An bấm "+ Thêm luật" hoặc "Sửa" ở UI-14-07.

**Đảm bảo tối thiểu.** Luật chưa được duyệt không bao giờ có hiệu lực; luật mâu thuẫn không được lưu.

**Đảm bảo thành công.** Luật `ACTIVE` đã nạp ở mọi bản sao cổng trong 30 giây; kiểm toán có người đề nghị, người duyệt, căn cứ.

**Luồng chính.**

1. An nhập luật: khớp nhóm `LLTP`, thao tác `READ`, đích chính `lltp-tra-trang-thai`, dự phòng `lltp-tra-trang-thai-b`, `allowFallback = true`, `priority = 100`, căn cứ "Công văn 123/CĐS ngày 10/11/2026 về phân công kết nối" (giả định).
2. An bấm "Mô phỏng". Hệ thống gọi API-14-028 và cho thấy lượt gọi mẫu `getStatus` sẽ đi tới `lltp-tra-trang-thai`, và nếu đích chính ngắt mạch thì chuyển sang `lltp-tra-trang-thai-b` với `routedVia = FALLBACK`.
3. An bấm "Lưu". Hệ thống gọi API-14-025: kiểm tra không trùng khóa khớp và `priority` với luật `ACTIVE`, hai đích tồn tại và `ACTIVE`, dự phòng chỉ cho thao tác đọc cùng nhóm dữ liệu, có căn cứ văn bản.
4. An bấm "Gửi duyệt". Hệ thống tạo việc cho Bình ở UI-14-17 và trả `202`.
5. Bình xem luật, kết quả mô phỏng, chọn "Duyệt" (API-14-027); hệ thống kiểm tra Bình khác An (LP-14-01).
6. Hệ thống đặt luật `ACTIVE`, ghi kiểm toán kèm căn cứ, phát EVT-14-03; cổng nạp bảng mới trong 30 giây.
7. Từ lượt gọi sau, UC-14-09 bước định tuyến dùng luật mới; chuyển hướng dự phòng ghi `national_fallback_total` và cảnh báo `routing.fallback`.

**Luồng thay thế.**

- **3a. Sửa luật.** An sửa luật đang `ACTIVE` qua API-14-026; thay đổi đi lại vòng duyệt, luật cũ vẫn chạy tới khi duyệt.
- **6a. Tắt tạm.** An đặt `DISABLED` cho luật mà không xóa; chỉ luật chưa từng `ACTIVE` mới xóa được.
- **1a. Không dự phòng.** Với dữ liệu chỉ có ở một nền tảng, An đặt `allowFallback = false`; khi đích hỏng, lượt gọi trả lỗi rõ ràng ngay (ERR-14-103) thay vì thử dự phòng vô ích.

**Luồng ngoại lệ.**

- **E1. Trùng luật (bước 3).** ERR-14-013; "Đã có luật cùng điều kiện và cùng mức ưu tiên. Đổi mức ưu tiên hoặc sửa luật đó."
- **E2. Đích chưa hoạt động (bước 3).** ERR-14-014; "Dịch vụ đích lltp-tra-trang-thai-b chưa ở trạng thái hoạt động."
- **E3. Dự phòng không hợp lệ (bước 3).** ERR-14-015; "Dự phòng chỉ dùng cho thao tác đọc và cùng nhóm dữ liệu."
- **E4. Thiếu căn cứ (bước 3).** ERR-14-016; "Nhập căn cứ văn bản của thay đổi này."
- **E5. Người duyệt trùng người đề nghị (bước 5).** ERR-14-007; "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."
- **E6. Lượt gọi không khớp luật nào (bước 7).** ERR-14-105 ở bên gọi; "Chưa cấu hình đường đi cho dịch vụ lltp-tra-trang-thai. Liên hệ quản trị tỉnh để bổ sung luật định tuyến."

**Quy tắc áp dụng.** BR-14-022, 023, 032.

**Màn hình, API.** UI-14-07, 17; API-14-024, 025, 026, 027, 028.
:::

**Nhóm 2 · Gọi dịch vụ quốc gia và bộ điều hợp (UC-14-09…15).** Đây là đường chạy chính của phân hệ. UC-14-09 đặc tả chuỗi kiểm tra và xử lý của mỗi lượt gọi; UC-14-10 là biến thể bất đồng bộ; UC-14-11…14 là bốn bộ điều hợp theo nhóm dịch vụ, mỗi bộ chỉ đặc tả phần khác biệt (thao tác, kiểm tra tham số, chính sách đệm, ưu tiên) và dùng lại UC-14-09 cho phần chung; UC-14-15 là cổng riêng của PH-07.

### 6.9. UC-14-09 · Gọi dịch vụ quốc gia qua điểm gọi chung

::: dac-ta
**Mục tiêu.** HTTT của tỉnh gọi mọi dịch vụ quốc gia qua một điểm duy nhất với cùng cách xác thực, cùng cấu trúc phản hồi và cùng nhật ký; HTTT không biết nền tảng nào đứng sau, không giữ thông tin xác thực quốc gia và không phải tự xử lý hạn mức, ký số, đệm.

**Tác nhân chính.** HTTT của tỉnh (`HT-DVC`, scope `national.invoke.dkdn`), hoặc luồng PH-04 qua Kamelet `dh-national-invoke`.

**Tác nhân phụ.** Cổng quốc gia (`dh-runtime`, hồ sơ `national-gateway`); OPA; PH-09; Valkey (đệm, bộ đếm); OpenBao; NDXP; Kafka.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-010, 011, 012, 014, 015, 026, 027.

**Truy vết.** REQ-14, REQ-09; BP-06; LGC-NGSP-001…007 (nền chung của bảy nhóm).

**Tiền điều kiện.** `HT-DVC` đã đăng ký sử dụng API cung cấp lại của dịch vụ `dkdn-du-lieu-moi-nhat` và được duyệt ở PH-02 (UC-14-07); dịch vụ và nền tảng `ACTIVE`; token Datahub còn hạn.

**Kích hoạt.** `HT-DVC` gọi API-14-075 (hoặc đường dẫn cung cấp lại) qua APISIX, ví dụ để lấy dữ liệu doanh nghiệp mã số `0101234567` phục vụ giải quyết hồ sơ.

**Đảm bảo tối thiểu.** Mọi lượt, kể cả bị từ chối, có một giao dịch ở trạng thái cuối và nhật ký khai thác; không bản tin nào gửi đi khi chưa qua kiểm tra mục đích; không dữ liệu nào trả về khi chữ ký không hợp lệ; thông tin xác thực quốc gia không rời OpenBao.

**Đảm bảo thành công.** `HT-DVC` nhận dữ liệu đã xác minh kèm `transactionCode`, biết dữ liệu từ đệm hay gọi thật; hạn mức đã trừ nếu gọi thật.

**Luồng chính.**

1. `HT-DVC` gọi API-14-075 với `serviceCode = dkdn-du-lieu-moi-nhat`, `operation = getLatestEnterpriseData`, `params = {"enterpriseCode":"0101234567"}`, `purposeCode = GIAI_QUYET_TTHC`, `freshData = false`.
2. Hệ thống lấy tenant `T68` từ token đã xác minh, lấy mã HTTT từ `azp` (không từ nội dung yêu cầu) và kiểm tra scope.
3. Hệ thống kiểm tra dịch vụ tồn tại, nền tảng `ACTIVE`; thao tác `READ` nên không cần `Idempotency-Key`.
4. Hệ thống kiểm tra mục đích và ủy quyền (LP-14-05): OPA xác nhận đăng ký sử dụng còn hiệu lực và mục đích nằm trong tập đã đăng ký.
5. Hệ thống kiểm tra `params` theo lược đồ đầu vào của hợp đồng (mã số đúng 10 hoặc 13 chữ số).
6. Dịch vụ `cacheable` và `freshData = false`: hệ thống tra đệm khóa có tiền tố `T68`; chưa có (MISS) nên đi tiếp.
7. Hệ thống định tuyến theo bảng (UC-14-08), kiểm tra bộ ngắt mạch không mở, kiểm tra hạn mức và trừ một lượt (UC-14-23).
8. Hệ thống lấy token nền tảng (UC-14-16), ký bản tin bằng OpenBao `transit` khi `signingMode` khác `NONE`, chuyển đổi sang giao thức của dịch vụ và gửi qua egress với thời hạn chờ 15.000 ms.
9. Hệ thống xác minh chữ ký phản hồi theo `verifyMode`, phân loại lỗi nếu có, chuyển phản hồi về JSON chuẩn, giữ trường được phép theo hợp đồng và lưu vào đệm 3.600 giây.
10. Hệ thống ghi giao dịch `T68-20261126-0000184320` trạng thái `SUCCEEDED`, ghi nhật ký khai thác, phát EVT-14-11 và trả `200` kèm `meta` (`fromCache = false`, `signatureVerified = true`, `durationMs = 412`).

**Luồng thay thế.**

- **6a. Trúng đệm.** Lượt gọi thứ hai của `HT-MOTCUA` cho cùng mã số trong 3.600 giây: ủy quyền mục đích vẫn được kiểm trước (BR-14-015), rồi hệ thống trả dữ liệu đệm, giao dịch `COMPLETED_CACHE`, `meta.fromCache = true`, `cacheAgeSeconds = 420`, không trừ hạn mức.
- **1a. Cần dữ liệu tươi.** `freshData = true` bỏ qua đệm khi còn hạn mức; hết hạn mức thì ERR-14-104 như E8.
- **7a. Đích chính không khả dụng.** Luật cho phép dự phòng, thao tác `READ`, dịch vụ dự phòng cùng nhóm: hệ thống chuyển hướng, đánh dấu `routedVia = FALLBACK`, ghi cảnh báo `routing.fallback`.
- **9a. Dữ liệu đệm quá hạn.** Khi nền tảng lỗi hoặc hết hạn mức, dịch vụ `staleAllowed` và có đệm quá hạn: hệ thống trả dữ liệu kèm `stale = true` (UC-14-24).
- **1b. Thao tác ghi hoặc lô.** Thao tác ghi bắt buộc `Idempotency-Key`; thao tác dài hoặc lô dùng UC-14-10.

**Luồng ngoại lệ.**

- **E1. Dịch vụ không tồn tại (bước 3).** ERR-14-001 (404); "Không tìm thấy dịch vụ dkdn-du-lieu-moi-nhat."
- **E2. Dịch vụ hoặc nền tảng đã ngừng hay đang tạm ngừng (bước 3).** ERR-14-117 (503); giao dịch `REJECTED`; "Dịch vụ hoặc nền tảng đã ngừng hoặc đang tạm ngừng, không nhận lượt mới."
- **E3. Thiếu `Idempotency-Key` ở thao tác ghi (bước 3).** ERR-14-003 (400); "Giá trị Idempotency-Key không hợp lệ: bắt buộc với thao tác ghi." Trùng khóa khác nội dung: ERR-14-116 (409).
- **E4. HTTT không được phép hoặc mục đích sai (bước 4).** ERR-14-106 (403); "HTTT HT-DVC không được phép gọi dịch vụ này vì mục đích đã nêu. Kiểm tra đăng ký sử dụng ở danh mục dịch vụ."; giao dịch `REJECTED` vẫn được ghi.
- **E5. Thiếu mã thủ tục hoặc mã hồ sơ (bước 4).** ERR-14-107 (422); "Dịch vụ này yêu cầu mã thủ tục và mã hồ sơ. Bổ sung rồi gọi lại."
- **E6. OPA hoặc PH-09 không khả dụng (bước 4).** ERR-14-132 (503); "Chưa kiểm tra được quyền khai thác nên yêu cầu bị từ chối để bảo đảm an toàn. Thử lại sau ít phút."; từ chối an toàn, không bỏ qua kiểm tra.
- **E7. Tham số sai lược đồ (bước 5).** ERR-14-108 (422); "Dữ liệu gửi đi không đúng mẫu của dịch vụ: enterpriseCode."
- **E8. Không có luật định tuyến (bước 7).** ERR-14-105 (422); "Chưa cấu hình đường đi cho dịch vụ dkdn-du-lieu-moi-nhat. Liên hệ quản trị tỉnh để bổ sung luật định tuyến."
- **E9. Hết hạn mức (bước 7).** ERR-14-104 (429); "Đã dùng hết hạn mức truy vấn dkdn-du-lieu-moi-nhat. Bộ đếm đặt lại lúc 00:00 ngày 27/11/2026." Phản hồi kèm `cache.available`.
- **E10. Không ký được (bước 8).** ERR-14-112 (503); không gửi; thao tác bất đồng bộ ở lại hàng chờ. Chứng thư ký hết hạn hoặc bị thu hồi: ERR-14-113 (503). OpenBao không khả dụng: ERR-14-035 (503).
- **E11. Nền tảng từ chối thông tin xác thực (bước 8).** ERR-14-114 (502); cổng làm mới token một lần rồi cảnh báo TO (UC-14-16).
- **E12. Không kết nối được, ngắt mạch, quá hạn chờ (bước 8).** ERR-14-101 (502), ERR-14-103 (503; "Nền tảng quốc gia tạm thời không phản hồi. Hệ thống sẽ thử lại tự động, hãy gọi lại sau ít phút."), ERR-14-115 (504; "Nền tảng quốc gia không trả lời trong 15 giây.").
- **E13. Chữ ký phản hồi không hợp lệ (bước 9).** ERR-14-109 (502), ERR-14-110 hoặc ERR-14-111; "Không thể tin cậy dữ liệu nhận được. Sự cố đã được ghi nhận và báo cán bộ an toàn thông tin."; không trả dữ liệu, mở sự cố chữ ký (UC-14-21).
- **E14. Lỗi nghiệp vụ của trung ương (bước 9).** ERR-14-102 (404 hoặc 422); "Nền tảng quốc gia từ chối yêu cầu: không tìm thấy doanh nghiệp."
- **E15. Phản hồi sai cấu trúc (bước 9).** ERR-14-128 (502); "Phản hồi từ nền tảng quốc gia không đúng cấu trúc. Sự cố đã được ghi nhận."
- **E16. Lỗi nội bộ (bất kỳ bước).** ERR-14-127 (500); "Hệ thống gặp lỗi. Sự cố đã được ghi nhận, hãy báo mã truy vết 7f3c… cho bộ phận hỗ trợ."

**Quy tắc áp dụng.** BR-14-001, 002, 003, 006, 007, 008, 012, 015, 020, 021, 023, 029, 030, 037.

**Màn hình, API.** UI-14-12 (tra giao dịch sau khi gọi), UI-14-13 (nhật ký khai thác), UI-14-05 (thử chuyển đổi), UI-14-07 (mô phỏng định tuyến); API-14-075.
:::

```{.mermaid caption="Trình tự một lượt gọi dịch vụ quốc gia từ HTTT tới NDXP"}
sequenceDiagram
  autonumber
  participant H as HTTT HT-DVC
  participant A as APISIX
  participant G as Cổng quốc gia
  participant O as OPA và PH-09
  participant V as Valkey
  participant B as OpenBao
  participant N as NDXP
  H->>A: Gọi API quốc gia kèm token Datahub
  A->>G: Chuyển tiếp sau khi xác minh token
  G->>O: Kiểm tra đăng ký, mục đích, mã hồ sơ
  O-->>G: Cho phép
  G->>V: Tra đệm và trừ hạn mức
  V-->>G: MISS, còn hạn mức
  G->>B: Lấy token nền tảng và ký băm bản tin
  B-->>G: Token và chữ ký
  G->>N: Gửi bản tin đã ký qua egress
  N-->>G: Phản hồi kèm chữ ký
  G->>G: Xác minh chữ ký, chuyển JSON, lưu đệm, ghi giao dịch
  G-->>H: 200 dữ liệu và meta
```

Hình cho thấy HTTT chỉ nói với APISIX bằng token Datahub; mọi thông tin xác thực và khóa ký nằm giữa cổng và OpenBao, và mục đích được kiểm tra trước khi chạm đệm hay nền tảng. Mỗi lượt kết thúc bằng một giao dịch có thể tra ở UC-14-33.

### 6.10. UC-14-10 · Gọi bất đồng bộ qua hàng chờ

::: dac-ta
**Mục tiêu.** HTTT gửi thao tác ghi hoặc lô tra cứu mà không phải chờ; yêu cầu không mất khi nền tảng quốc gia gián đoạn và chỉ được gửi một lần.

**Tác nhân chính.** HTTT của tỉnh (`HT-MOTCUA`, scope `national.invoke.hotich`); luồng PH-04 khi gửi lô.

**Tác nhân phụ.** Cổng quốc gia; hàng chờ Kafka; bộ xử lý; PH-10 (thông báo kết quả); NDXP; ROLE-TENANT_OPERATOR (Chi) xem hàng chờ.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-016.

**Truy vết.** REQ-14, REQ-04; BP-06, BP-02; LGC-NGSP-001, LGC-NGSP-002 (nhận hồ sơ, đăng ký).

**Tiền điều kiện.** Dịch vụ `hotich-dang-ky-su-kien` `ACTIVE`; `HT-MOTCUA` đã đăng ký sử dụng và có `Idempotency-Key` (ULID).

**Kích hoạt.** `HT-MOTCUA` gọi API-14-076; hoặc UC-14-09 chuyển yêu cầu vào hàng chờ khi nền tảng đang ngắt mạch và dịch vụ cho phép gọi chậm.

**Đảm bảo tối thiểu.** Yêu cầu đã trả `202` không bao giờ mất; không có gửi trùng; thao tác ghi quá hạn chờ không được gửi lại trước khi đối soát.

**Đảm bảo thành công.** `async_request` ở một trạng thái cuối (`SUCCEEDED` hoặc `FAILED`) trong 72 giờ; kết quả lưu mã hóa; giao dịch được ghi.

**Luồng chính.**

1. `HT-MOTCUA` gửi yêu cầu đăng ký khai sinh: `serviceCode = hotich-dang-ky-su-kien`, `operation = registerEvent`, `payload` 18 KB, `purposeCode = GIAI_QUYET_TTHC`, `procedureCode = 1.001193`, `caseCode = HS-2026-11-004512`, `Idempotency-Key = 01JD8Z…`, `expireAfterHours = 24`.
2. Hệ thống kiểm tra quyền, mục đích, lược đồ như UC-14-09 bước 2 đến 5 (không đạt thì trả lỗi ngay, không vào hàng chờ).
3. Hệ thống kiểm tra hàng chờ còn chỗ, ghi `async_request` ở `QUEUED` và đặt bản tin đã mã hóa vào hàng chờ trong cùng một giao dịch (outbox), rồi trả `202` kèm `requestId` và `statusUrl`.
4. Bộ xử lý lấy yêu cầu theo thứ tự ưu tiên của dịch vụ (`ESSENTIAL` trước), chuyển `SENDING`, chạy đường UC-14-09 từ bước 6 (đệm bỏ qua vì thao tác ghi).
5. NDXP không trả lời trong thời hạn chờ. Bộ xử lý chuyển giao dịch `UNKNOWN_RESULT` và không gửi lại; nó gọi `getDossierStatus` theo `caseCode` để đối soát (BR-14-030).
6. NDXP xác nhận đã nhận hồ sơ. Bộ xử lý cập nhật `SUCCEEDED`, lưu kết quả mã hóa, phát EVT-14-11.
7. `HT-MOTCUA` tra API-14-077 với `requestId` và nhận `200` kèm kết quả; nếu đã đăng ký sự kiện ở PH-10 thì nhận thông báo.

**Luồng thay thế.**

- **7a. Hủy khi chưa gửi.** `HT-MOTCUA` gọi API-14-078 khi yêu cầu còn `QUEUED`; hệ thống hủy và ghi kiểm toán.
- **4a. Nền tảng đang ngắt mạch.** Yêu cầu nằm lại hàng chờ; hệ thống phát EVT-14-10 khi hàng chờ tích lũy; khi nền tảng sống lại bộ xử lý gửi lần lượt theo ưu tiên.
- **5a. Thao tác đọc hoặc ghi idempotent.** Bộ xử lý thử lại theo UC-14-25 thay vì đối soát.
- **6a. Yêu cầu quá hạn.** Yêu cầu quá `14.queue.max-age-hours` (hoặc `expireAfterHours`) chuyển `FAILED` với lý do hết hạn; HTTT được thông báo.
- **7b. Chi xem hàng chờ.** Chi mở UI-14-12 thấy yêu cầu theo trạng thái, số lần thử; xả hoặc hủy cần `PERM-14-operate`.

**Luồng ngoại lệ.**

- **E1. Hàng chờ đầy (bước 3).** ERR-14-118 (503); "Hàng chờ gửi quốc gia đang đầy. Thử lại sau ít phút."
- **E2. Trùng `Idempotency-Key` khác nội dung (bước 3).** ERR-14-116 (409); "Khóa chống trùng đã dùng cho yêu cầu khác nội dung." Cùng nội dung thì trả lại `requestId` cũ.
- **E3. Không tìm thấy yêu cầu khi tra (bước 7).** ERR-14-129 (404); "Không tìm thấy yêu cầu 01JD8Z…"
- **E4. Hủy yêu cầu đã gửi (nhánh 7a).** ERR-14-130 (409); "Yêu cầu đã được gửi, không hủy được. Dùng tra trạng thái để biết kết quả."
- **E5. Không được phép theo mục đích (bước 2).** ERR-14-106 (403) hoặc ERR-14-107 (422) như UC-14-09 E4, E5; không vào hàng chờ.
- **E6. Không ký được (bước 4).** ERR-14-112; bản tin ở lại hàng chờ và gửi sau khi ký được (BR-14-001).

**Quy tắc áp dụng.** BR-14-020, 030, 031.

**Màn hình, API.** UI-14-12; API-14-076, 077, 078.
:::

```{.mermaid caption="Trình tự UC-14-10 khi thao tác ghi quá hạn chờ"}
sequenceDiagram
  autonumber
  participant H as HT-MOTCUA
  participant G as Cổng quốc gia
  participant Q as Hàng chờ Kafka
  participant W as Bộ xử lý
  participant N as NDXP
  H->>G: registerEvent kèm Idempotency-Key
  G->>Q: Ghi async_request và bản tin mã hóa cùng giao dịch
  G-->>H: 202 kèm requestId
  W->>Q: Lấy yêu cầu theo ưu tiên
  W->>N: Gửi bản tin đã ký
  N-->>W: Quá hạn chờ
  W->>N: getDossierStatus theo caseCode
  N-->>W: Đã nhận
  W->>G: Cập nhật SUCCEEDED, lưu kết quả mã hóa
  H->>G: Tra requestId
  G-->>H: 200 kết quả
```

Hình nhấn mạnh hai điều: HTTT nhận `202` ngay nên không bị chặn, và khi chưa rõ kết quả hệ thống đối soát bằng tra trạng thái thay vì gửi lại, nên hồ sơ hộ tịch không bị đăng ký trùng.

### 6.11. UC-14-11 · Tra cứu lý lịch tư pháp và hộ tịch

::: dac-ta
**Mục tiêu.** HTTT của Sở Tư pháp và cổng dịch vụ công tra danh sách, trạng thái hồ sơ lý lịch tư pháp, đánh dấu hồ sơ thành công, đăng ký hộ tịch và tra kết quả qua NDXP, giữ đủ chức năng hệ cũ trong khung kiểm soát mới (mục đích, không lộ thông tin xác thực, không đăng ký trùng).

**Tác nhân chính.** HTTT `HT-TUPHAP` (scope `national.invoke.lltp`, `national.invoke.hotich`).

**Tác nhân phụ.** Cổng quốc gia; NDXP; PH-09.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-017, 018 (cùng nền: FR-14-010, 011, 014, 016, 026, 027).

**Truy vết.** REQ-14; BP-06; LGC-NGSP-001, LGC-NGSP-002.

**Tiền điều kiện.** Dịch vụ nhóm `LLTP` và `HO_TICH` `ACTIVE`; `HT-TUPHAP` đã đăng ký sử dụng, mục đích và mã hồ sơ hợp lệ; chính sách mặc định không đệm, mức `SENSITIVE`, ưu tiên `ESSENTIAL`.

**Kích hoạt.** Cán bộ Sở Tư pháp xử lý hồ sơ trên `HT-TUPHAP`, hệ thống này gọi API-14-075 hoặc API-14-076.

**Đảm bảo tối thiểu.** Thao tác ghi không bao giờ gửi lại tự động khi kết quả chưa rõ; không đăng ký hộ tịch trùng; không thông tin xác thực nào lộ cho HTTT.

**Đảm bảo thành công.** Hồ sơ được tra, đánh dấu hoặc đăng ký đúng một lần ở trung ương; mỗi lượt có giao dịch kèm mã hồ sơ.

**Luồng chính.**

1. `HT-TUPHAP` gọi `listDossiers` của nhóm `LLTP` với `from = 2026-11-01`, `to = 2026-11-20`, `status = DANG_XU_LY`, `size = 50`. Hệ thống chạy UC-14-09 bước 2 đến 8 (không đệm vì `SENSITIVE`).
2. Bộ điều hợp `LLTP` kiểm tra khoảng thời gian không quá 31 ngày, gửi, xác minh, theo con trỏ phân trang và trả `items[]` (mã hồ sơ, người yêu cầu, trạng thái, ngày).
3. `HT-TUPHAP` gọi `getDossierStatus` với `dossierCode = LLTP-2026-000123` và nhận `item` (trạng thái `DA_CO_KET_QUA`, thời điểm, ghi chú).
4. Sau khi trả kết quả cho người dân, `HT-TUPHAP` gọi `markDossierSuccess` kèm `Idempotency-Key`, `dossierCode`, `resultNote`. Bộ điều hợp bỏ qua đệm và gửi qua đường ghi.
5. `HT-TUPHAP` đăng ký hộ tịch: gọi `registerEvent` của nhóm `HO_TICH` với `eventType = KHAI_SINH`, `subjects[]`, `eventDate`, `place`, `Idempotency-Key`. Bộ điều hợp tạo khóa chống trùng từ `Idempotency-Key` kết hợp `caseCode`.
6. NDXP quá hạn chờ. Giao dịch chuyển `UNKNOWN_RESULT`; bộ điều hợp gọi `getDossierStatus` theo `caseCode` để đối soát, thấy hồ sơ đã được tiếp nhận nên chuyển `SUCCEEDED`; người gọi nhận `200` kèm mã hồ sơ.
7. Cổng ghi giao dịch và nhật ký khai thác cho từng lượt, kèm mã hồ sơ của `HT-TUPHAP`.

**Luồng thay thế.**

- **5a. Gửi nhiều sự kiện.** Lô nhiều sự kiện đăng ký dùng UC-14-10, mỗi sự kiện một `Idempotency-Key` riêng.
- **5b. Gửi lại cùng khóa cùng nội dung.** Bộ điều hợp trả lại kết quả lần đầu, không gửi trùng.
- **4a. Hồ sơ nhận qua chiều vào.** Nếu trung ương đẩy hồ sơ xuống (Q14-01), luồng đi qua UC-14-27 thay vì thao tác `submitRegistration` chiều ra.
- **6a. Đối soát thấy chưa nhận.** Giao dịch chuyển `FAILED`; HTTT được phép gửi lại với cùng `Idempotency-Key`.

**Luồng ngoại lệ.**

- **E1. Không tìm thấy hồ sơ (bước 3).** ERR-14-102 (404); "Không tìm thấy hồ sơ lý lịch tư pháp LLTP-2026-000123."
- **E2. Khoảng thời gian quá rộng (bước 2).** ERR-14-108 (422); "Khoảng thời gian tra tối đa 31 ngày mỗi lượt."
- **E3. Sự kiện hộ tịch sai loại hoặc thiếu trường (bước 5).** ERR-14-108 (422); "Dữ liệu đăng ký hộ tịch thiếu hoặc sai: eventDate."
- **E4. Trùng khóa chống trùng khác nội dung (bước 5).** ERR-14-116 (409); "Khóa chống trùng đã dùng cho yêu cầu khác nội dung."
- **E5. Trung ương từ chối đăng ký (bước 5).** ERR-14-102 (422); "Nền tảng quốc gia từ chối hồ sơ: trùng sự kiện đã đăng ký."
- **E6. Thao tác ghi quá hạn chờ (bước 4 hoặc 5).** Người gọi thấy "Chưa xác nhận được hồ sơ đã gửi, hệ thống đang đối soát. Không gửi lại."
- **E7. Hết hạn mức (bước 1).** ERR-14-104 (429) như UC-14-09 E9; dịch vụ `ESSENTIAL` vẫn được gọi ở mức dùng 95% trở lên (UC-14-23).

**Quy tắc áp dụng.** BR-14-008, 009, 014, 020, 030.

**Màn hình, API.** UI-14-04, 05, 12; API-14-075, 076.
:::

### 6.12. UC-14-12 · Tra cứu dữ liệu bảo hiểm xã hội

::: dac-ta
**Mục tiêu.** HTTT của tỉnh tra hộ gia đình theo mã số BHXH, tìm mã số theo tiêu chí và tra dữ liệu hộ gia đình, với kiểm soát mục đích chặt vì mỗi lượt có thể trả dữ liệu cá nhân của nhiều người.

**Tác nhân chính.** HTTT `HT-DVC` (scope `national.invoke.bhxh`).

**Tác nhân phụ.** Cổng quốc gia; PH-09; OPA; NDXP; ROLE-SECURITY_OFFICER (Dũng) xem nhật ký khai thác ở UC-14-35.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-019 (cùng nền: FR-14-010, 011, 035, 052, 053).

**Truy vết.** REQ-14, REQ-09; BP-06, BP-01; LGC-NGSP-003.

**Tiền điều kiện.** Dịch vụ nhóm `BHXH` `ACTIVE` (mức `RESTRICTED`, ưu tiên `ESSENTIAL`, đệm 300 giây theo giả định ở Q14-08); `HT-DVC` có mục đích hợp lệ trong sổ hoạt động xử lý ở PH-09 và đã khai mã hồ sơ.

**Kích hoạt.** Cán bộ một cửa trên `HT-DVC` tra thông tin hộ để giải quyết thủ tục trợ cấp.

**Đảm bảo tối thiểu.** Không trả thừa trường ngoài hợp đồng; không tra mò (cần hai tiêu chí định danh); mọi lượt, kể cả bị từ chối, có nhật ký kèm mục đích.

**Đảm bảo thành công.** `HT-DVC` nhận đúng dữ liệu cần cho thủ tục; nhật ký khai thác ghi số bản ghi trả về.

**Luồng chính.**

1. `HT-DVC` gọi `findInsuranceNo` với `fullName = Nguyễn Văn A`, `birthDate = 1980-05-12`, `idNumber`, kèm `purposeCode = GIAI_QUYET_TTHC`, `procedureCode = 1.002345`, `caseCode = HS-2026-11-007788`.
2. Hệ thống chạy UC-14-09 bước 2 đến 5; PH-09 xác nhận mục đích có trong sổ hoạt động xử lý DLCN của `HT-DVC` và có cơ sở pháp lý.
3. Bộ điều hợp `BHXH` kiểm tra có ít nhất hai tiêu chí định danh (đủ ba), gửi, xác minh, chuyển đổi và trả `items[]` gồm mã số BHXH và họ tên.
4. `HT-DVC` gọi `getHouseholdByInsuranceNo` với mã số vừa tìm được. Hệ thống tra đệm: khóa gồm tenant, dịch vụ, tham số chuẩn hóa; ủy quyền mục đích được kiểm trước khi đọc đệm (BR-14-015); MISS nên gọi thật.
5. Bộ điều hợp lọc trường theo `responseFields` của hợp đồng cung cấp lại, chỉ giữ trường mục đích cần, và trả `item` (hộ, thành viên).
6. `HT-DVC` gọi `getHouseholdData` với `householdCode`; bộ điều hợp giới hạn số thành viên trả về tối đa `14.bhxh.max-members` (30).
7. Cổng ghi giao dịch và nhật ký khai thác kèm số bản ghi trả về để UC-14-35 phát hiện tra hàng loạt.

**Luồng thay thế.**

- **4a. Trúng đệm.** Lượt tra lại trong 300 giây của một cán bộ khác cùng mục đích trả từ đệm, giao dịch `COMPLETED_CACHE`, không trừ hạn mức.
- **6a. Hộ quá đông.** Hộ có 38 thành viên: bộ điều hợp trả 30 và đánh dấu `truncated = true`; cán bộ tra thêm theo từng thành viên.
- **2a. Tắt đệm.** Nếu chủ quản dữ liệu không cho đệm (Q14-08), TA đặt `cacheable = false` ở UC-14-04; bước 4 luôn gọi thật.

**Luồng ngoại lệ.**

- **E1. Không đủ tiêu chí tìm (bước 3).** ERR-14-108 (422); "Cần ít nhất hai tiêu chí định danh để tìm mã số bảo hiểm xã hội."
- **E2. Không tìm thấy (bước 3 hoặc 4).** ERR-14-102 (404); "Không tìm thấy dữ liệu bảo hiểm xã hội phù hợp."
- **E3. Không được phép theo mục đích (bước 2).** ERR-14-106 (403); "HTTT HT-DVC không được phép gọi dịch vụ này vì mục đích đã nêu. Kiểm tra đăng ký sử dụng ở danh mục dịch vụ."
- **E4. Thiếu mã thủ tục hoặc mã hồ sơ (bước 1).** ERR-14-107 (422); "Dịch vụ này yêu cầu mã thủ tục và mã hồ sơ. Bổ sung rồi gọi lại."
- **E5. PH-09 hoặc OPA không khả dụng (bước 2).** ERR-14-132 (503); từ chối an toàn.
- **E6. Gọi ngoài khung giờ cho phép.** Nếu tenant đặt `14.purpose.allowed-hours`, lượt ngoài khung giờ bị từ chối với ERR-14-106.

**Quy tắc áp dụng.** BR-14-008, 009, 014, 015.

**Màn hình, API.** UI-14-04, 05, 13; API-14-075.
:::

### 6.13. UC-14-13 · Đồng bộ hồ sơ cấp mã số ĐVQHNS

::: dac-ta
**Mục tiêu.** Luồng của tỉnh đồng bộ hồ sơ thủ tục cấp mã số đơn vị có quan hệ với ngân sách theo khoảng thời gian, xem chi tiết và lấy tổng hợp kết quả giải quyết, mà không chiếm hạn mức của dịch vụ công.

**Tác nhân chính.** Luồng PH-04 `dvqhns-dong-bo-ho-so` (chạy theo lịch 01:30 hằng đêm).

**Tác nhân phụ.** HTTT `HT-TAICHINH` (người dùng kết quả); cổng quốc gia; NDXP; PH-02.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-020 (cùng nền: FR-14-010, 033, 034).

**Truy vết.** REQ-14; BP-06; LGC-NGSP-004.

**Tiền điều kiện.** Dịch vụ nhóm `DVQHNS` `ACTIVE`; đồng bộ theo khoảng thời gian khai `priority = BACKGROUND`, chi tiết hồ sơ `NORMAL`, đệm chi tiết 300 giây.

**Kích hoạt.** Bộ lập lịch PH-04 khởi động luồng lúc 01:30; hoặc người dùng chạy tay từ `HT-TAICHINH`.

**Đảm bảo tối thiểu.** Tác vụ nền không bao giờ làm cạn hạn mức của dịch vụ thiết yếu; lô vượt giới hạn trang không trả thiếu im lặng.

**Đảm bảo thành công.** Luồng nhận đủ hồ sơ từ `watermark` lần trước tới nay, kèm `watermark` mới để lần sau bắt đầu.

**Luồng chính.**

1. Luồng PH-04 gọi `listDossiersByRange` với `from` là `watermark` lần trước (2026-11-25T01:30:00+07:00), `to = 2026-11-26T01:30:00+07:00`, `size = 100`.
2. Hệ thống chạy UC-14-09; ở bước hạn mức, mức dùng hôm nay mới 41% nên lượt `BACKGROUND` được chạy.
3. Bộ điều hợp kiểm tra khoảng không quá 31 ngày và `size` không quá 100, rồi theo con trỏ phân trang tới hết hoặc tới `14.adapter.max-pages`.
4. Bộ điều hợp trả `items[]` (312 hồ sơ, 4 trang) kèm `watermark` là thời điểm cập nhật lớn nhất.
5. Luồng PH-04 khử trùng theo mã hồ sơ, lưu và lưu `watermark` cho lần sau.
6. Với mỗi hồ sơ mới, luồng gọi `getDossier` (đệm 300 giây) để lấy chi tiết; cuối cùng gọi `getResolutionSummary` với `unitCode` của tỉnh để `HT-TAICHINH` có tổng hợp.

**Luồng thay thế.**

- **2a. Mức dùng từ 70%.** Lượt `BACKGROUND` bị hoãn: ERR-14-104 với `reason = DEFERRED`; luồng ghi nhận và thử lại ở chu kỳ sau, dịch vụ công không bị ảnh hưởng (UC-14-23).
- **1a. Đồng bộ lại một khoảng đã chạy.** Bộ điều hợp không đảm bảo trùng lặp; luồng tiêu thụ khử trùng theo mã hồ sơ.
- **3a. Khoảng quá rộng.** Luồng chia thành các khoảng 7 ngày thay vì một lượt 31 ngày.

**Luồng ngoại lệ.**

- **E1. Khoảng thời gian quá rộng hoặc vượt số trang (bước 3).** ERR-14-108 (422); "Khoảng thời gian tối đa 31 ngày, số trang tối đa 100. Chia nhỏ khoảng tra."; kèm `partial`.
- **E2. Không tìm thấy hồ sơ (bước 6).** ERR-14-102 (404); "Không tìm thấy hồ sơ DVQHNS-2026-000871."
- **E3. Hết hạn mức (bước 2).** ERR-14-104 (429); tác vụ nền được hoãn, không gây lỗi cho dịch vụ thiết yếu.
- **E4. Nền tảng không phản hồi.** ERR-14-101 hoặc ERR-14-103; luồng PH-04 thử lại theo chính sách, `watermark` giữ nguyên.

**Quy tắc áp dụng.** BR-14-008, 013.

**Màn hình, API.** UI-14-04, 05, 09; API-14-075.
:::

### 6.14. UC-14-14 · Tra cứu đăng ký doanh nghiệp và văn bản quy phạm pháp luật

::: dac-ta
**Mục tiêu.** HTTT tra dữ liệu doanh nghiệp mới nhất, hồ sơ trong ngày và văn bản quy phạm pháp luật nhanh nhờ đệm, vẫn bảo đảm tươi khi cần, và không tốn hạn mức cho dữ liệu công khai.

**Tác nhân chính.** HTTT `HT-DVC` (scope `national.invoke.dkdn`, `national.invoke.vbqppl`); `HT-QLVB` tra văn bản.

**Tác nhân phụ.** Cổng quốc gia; Valkey; NDXP.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-021, 022 (cùng nền: FR-14-010, 035).

**Truy vết.** REQ-14; BP-06; LGC-NGSP-005, LGC-NGSP-007.

**Tiền điều kiện.** Dịch vụ nhóm `DKDN` (mức `INTERNAL`, đệm 3.600 giây, hồ sơ trong ngày 300 giây, mục đích bắt buộc) và `VBQPPL` (mức `PUBLIC`, đệm 86.400 giây cho danh mục, 3.600 giây cho tìm kiếm, không cần mục đích) `ACTIVE`.

**Kích hoạt.** Cán bộ trên `HT-DVC` tra doanh nghiệp; cán bộ trên `HT-QLVB` tìm văn bản căn cứ.

**Đảm bảo tối thiểu.** Mã số doanh nghiệp sai mẫu không bao giờ gửi đi; khóa đệm cô lập theo tenant; ủy quyền luôn kiểm trước khi đọc đệm.

**Đảm bảo thành công.** HTTT nhận dữ liệu từ đệm hoặc gọi thật, đúng cấu trúc, đúng giới hạn kích thước.

**Luồng chính.**

1. `HT-DVC` gọi `getLatestEnterpriseData` với `enterpriseCode = 0101234567` và `purposeCode = GIAI_QUYET_TTHC`. Bộ điều hợp `DKDN` kiểm tra mã số gồm 10 hoặc 13 chữ số.
2. Hệ thống tra đệm theo khóa dịch vụ và mã số; MISS nên gọi thật qua UC-14-09, lưu đệm 3.600 giây.
3. Vài phút sau cán bộ khác tra lại: trúng đệm, trả trong 8 ms, không trừ hạn mức; nhật ký khai thác vẫn ghi mã số đã băm.
4. `HT-DVC` gọi `listDossiersToday` với `status = DA_TIEP_NHAN`, `size = 50` (đệm 300 giây) và `getDossier` cho một hồ sơ.
5. `HT-QLVB` gọi `searchFullText` với `keyword = "đất đai"`, `from = 2025-01-01`. Bộ điều hợp `VBQPPL` kiểm tra từ khóa 1…200 ký tự, chuẩn hóa không dấu để tạo khóa đệm; kết quả 120 văn bản, trang 1 gồm 20.
6. `HT-QLVB` gọi `getDocument` lấy toàn văn; nội dung lớn trả bằng luồng, giới hạn theo `14.adapter.max-response-mb`; tệp đính kèm là liên kết tải tạm thời.
7. `HT-QLVB` gọi `listFields`, `listIssuers`, `listDocumentTypes` để dựng ô chọn lọc; ba danh mục lấy từ đệm 24 giờ.

**Luồng thay thế.**

- **1a. Người dân đang chờ kết quả vừa cập nhật.** `freshData = true` bỏ qua đệm khi còn hạn mức.
- **5a. Tra danh mục người ký, chức danh.** `listSigners` với từ khóa; `listPositions` không tham số; cùng cơ chế đệm.
- **2a. Nền tảng sự cố.** Dịch vụ `staleAllowed`: hệ thống trả dữ liệu đệm quá hạn có cờ `stale = true` (UC-14-24).

**Luồng ngoại lệ.**

- **E1. Mã số doanh nghiệp sai mẫu (bước 1).** ERR-14-108 (422); "Mã số doanh nghiệp gồm 10 hoặc 13 chữ số."
- **E2. Không tìm thấy doanh nghiệp (bước 2).** ERR-14-102 (404); "Không tìm thấy doanh nghiệp có mã số 0101234567."
- **E3. Từ khóa rỗng hoặc quá dài (bước 5).** ERR-14-108 (422); "Từ khóa tìm kiếm từ 1 đến 200 ký tự."
- **E4. Không tìm thấy văn bản (bước 6).** ERR-14-102 (404); "Không tìm thấy văn bản 42/2026/NĐ-CP."
- **E5. Phản hồi vượt giới hạn kích thước (bước 6).** ERR-14-108 (422); cổng không trả thiếu im lặng; "Phản hồi vượt giới hạn 10 MB. Thu hẹp bộ lọc."
- **E6. Không được phép theo mục đích (bước 1).** ERR-14-106 (403) như UC-14-09 E4.

**Quy tắc áp dụng.** BR-14-008, 015.

**Màn hình, API.** UI-14-04, 05; API-14-075.
:::

### 6.15. UC-14-15 · Kéo danh mục dùng chung quốc gia cho PH-07

::: dac-ta
**Mục tiêu.** PH-07 đồng bộ danh mục dùng chung quốc gia trong vòng 24 giờ qua một cổng duy nhất mà không giữ thông tin xác thực hay chứng thư của NDXP.

**Tác nhân chính.** PH-07 (bộ lập lịch đồng bộ, scope `national.catalog.read`, `national.catalog.propose`).

**Tác nhân phụ.** ROLE-PLATFORM_ADMIN (Hà) khai báo kết nối `NDXP_DMDC` ở tenant `COMMON`; cổng quốc gia; NDXP.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-023 (cùng nền: FR-14-007, 042).

**Truy vết.** REQ-14, REQ-07; BP-03, BP-06; LGC-NGSP-006, LGC-DMDC-019.

**Tiền điều kiện.** Dịch vụ nhóm `DMDC` `ACTIVE` ở nền tảng `NDXP` của tenant hoặc của `COMMON`; PH-07 có lịch đồng bộ.

**Kích hoạt.** Bộ lập lịch PH-07 gọi API-14-079 mỗi đêm; hoặc người dùng PH-07 yêu cầu đồng bộ một danh mục.

**Đảm bảo tối thiểu.** Chỉ PH-07 gọi được cổng; PH-14 không lưu dữ liệu danh mục, chỉ chuyển tiếp; đồng bộ nền không làm ngưng dịch vụ thiết yếu.

**Đảm bảo thành công.** PH-07 có dữ liệu và `remoteVersion` của danh mục; lần chạy không đổi phiên bản được bỏ qua bằng `304`.

**Luồng chính.**

1. PH-07 gọi `listCatalogs` (API-14-079) với token dịch vụ. Cổng kiểm tra scope và rằng người gọi là PH-07.
2. Cổng chọn kết nối `NDXP_DMDC`: của `T68` nếu có, không thì của `COMMON`. Cổng chạy đường chung với hạn mức mức `BACKGROUND`, token, ký số nếu dịch vụ yêu cầu, gửi, xác minh.
3. Cổng trả `items[]` (`remoteCode`, `name`, `remoteVersion`, `updatedAt`); PH-07 chọn danh mục `DM_DANTOC`.
4. PH-07 gọi `getCatalogStructure` (API-14-080) và nhận `fields[]` (tên, kiểu, bắt buộc) kèm `remoteVersion = 17`.
5. PH-07 gọi `getCatalogData` (API-14-081) với `ifVersionNot = 17`. Phiên bản ở nguồn vẫn 17 nên cổng trả `304`; PH-07 bỏ qua lần chạy.
6. Hôm sau nguồn lên phiên bản 18: cổng phân trang phía nguồn (1.000 bản ghi mỗi trang), trả luồng `items[]`, `remoteVersion = 18`, `nextPage` tới hết.
7. PH-07 muốn bổ sung một mã còn thiếu: gọi `proposeEntries` (API-14-082) kèm `Idempotency-Key`, `entries[]`, `reason`. Cổng gửi đề xuất, trả `202` và `proposalId`; PH-07 tra trạng thái qua API-14-083.

**Luồng thay thế.**

- **1a. Đồng bộ theo yêu cầu.** Người dùng PH-07 yêu cầu ngay; cổng dùng đường chung với ưu tiên `NORMAL` thay vì `BACKGROUND`.
- **2a. Khai báo ở `COMMON`.** Hà khai báo một lần nền tảng và dịch vụ `DMDC` ở `COMMON` (UC-14-01, 04) để mọi tỉnh dùng chung; tenant có kết nối riêng thì ưu tiên kết nối riêng.
- **6a. Thông báo thay đổi từ trung ương.** Khi trung ương báo danh mục đổi (UC-14-28), PH-07 được nhận EVT-14-17 và gọi sớm hơn lịch.

**Luồng ngoại lệ.**

- **E1. Không phải PH-07 hoặc thiếu scope (bước 1).** Lỗi 403 theo FR-00; "Chỉ phân hệ Danh mục dùng chung được gọi cổng này."
- **E2. Danh mục không tồn tại ở nguồn (bước 4).** ERR-14-102 (404); "Không tìm thấy danh mục DM_DANTOC trên nền tảng quốc gia."
- **E3. NDXP không phản hồi (bước 2 đến 6).** ERR-14-101 (502) hoặc ERR-14-103 (503); PH-07 ghi `FAILED` và thử lại lượt sau.
- **E4. Hết hạn mức (bước 2).** ERR-14-104 (429); lần đồng bộ nền chờ tới chu kỳ sau.
- **E5. Trùng `Idempotency-Key` khác nội dung (bước 7).** ERR-14-116 (409); "Khóa chống trùng đã dùng cho yêu cầu khác nội dung."
- **E6. Không tìm thấy đề xuất khi tra (bước 7).** ERR-14-129 (404); "Không tìm thấy yêu cầu 8c2f…"

**Quy tắc áp dụng.** BR-14-006, 013, 036.

**Màn hình, API.** UI-14-04, 11; API-14-079, 080, 081, 082, 083.
:::

```{.mermaid caption="Trình tự PH-07 lấy dữ liệu danh mục quốc gia qua cổng tiếp hợp"}
sequenceDiagram
  autonumber
  participant P7 as PH-07
  participant G as Cổng NDXP_DMDC
  participant Q as Hạn mức, ngắt mạch
  participant B as OpenBao
  participant N as NDXP
  P7->>G: getCatalogData kèm ifVersionNot
  G->>Q: Trừ hạn mức BACKGROUND, kiểm ngắt mạch
  G->>B: Lấy hoặc làm mới token
  G->>N: Gửi yêu cầu phân trang qua egress
  N-->>G: Trang dữ liệu và remoteVersion
  G-->>P7: items, remoteVersion, nextPage hoặc 304
```

Hình cho thấy PH-07 chỉ làm việc với cổng PH-14, còn hạn mức, token, ký số và egress do cổng lo; khi `remoteVersion` không đổi thì cổng trả `304` và PH-07 bỏ qua lần chạy, tiết kiệm băng thông và hạn mức.

**Nhóm 3 · Xác thực, chữ ký số và chứng thư (UC-14-16…21).** Nhóm này giữ hai điều ở ranh giới với trung ương: Datahub chứng minh được mình là ai (token OAuth, chữ ký bằng chứng thư của tỉnh) và kiểm chứng được bên kia là ai (xác minh chữ ký theo chuỗi tin cậy). Quyết định cốt lõi là khóa riêng không rời OpenBao: cổng chỉ gửi giá trị băm vào `transit/sign`. Phần lớn use case thuộc Cán bộ ATTT, tách khỏi kỹ sư tích hợp để người giữ khóa không đồng thời quyết định dữ liệu nào đi đâu.

### 6.16. UC-14-16 · Lấy và làm mới token của nền tảng

::: dac-ta
**Mục tiêu.** Cổng quốc gia luôn có token hợp lệ trước mỗi lượt gọi bằng `client_credentials`, không dùng khóa tĩnh trong tài liệu như hệ cũ; quản trị thử lấy token để biết thông tin xác thực còn đúng mà không ai thấy được token hay bí mật.

**Tác nhân chính.** Cổng quốc gia (`dh-runtime`, hồ sơ `national-gateway` của `T68`).

**Tác nhân phụ.** OpenBao; egress gateway; cổng token của nền tảng; ROLE-TENANT_OPERATOR (Chi) chạy thử tay.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-024.

**Truy vết.** REQ-14; BP-06; LGC-NGSP-008 (nâng cấp từ Consumer Key và Secret).

**Tiền điều kiện.** Nền tảng `ndxp-t68` có kết nối `ndxp-oauth` ở PH-05 với thông tin xác thực đã đặt cho môi trường đang chạy; `authMode = PRIVATE_KEY_JWT`.

**Kích hoạt.** Cổng cần token (chưa có, hoặc còn dưới `14.token.refresh-before-seconds` = 60 giây); hoặc Chi bấm "Thử lấy token" ở UI-14-03.

**Đảm bảo tối thiểu.** Token và bí mật không bao giờ được ghi đĩa, nhật ký, vết hay phản hồi API; lỗi xác thực không bị thử lại dồn dập.

**Đảm bảo thành công.** Cổng có token còn hạn trong bộ nhớ và hẹn làm mới trước hạn; lượt thử tay trả kết quả `OK` kèm thời hạn, không trả token.

**Luồng chính.**

1. Cổng kiểm tra token trong bộ nhớ của bản sao: còn hạn hơn 60 giây thì dùng ngay, không gọi ra ngoài.
2. Khi cần làm mới, cổng lấy khóa "một luồng làm mới mỗi nền tảng mỗi bản sao" để nhiều yêu cầu không cùng xin token một lúc.
3. Cổng đọc thông tin xác thực từ OpenBao bằng danh tính Kubernetes của pod, ở đường dẫn của đúng tenant `T68`.
4. Với `PRIVATE_KEY_JWT`, cổng dựng JWT xác thực, gửi băm tới `transit/sign` để ký (khóa không rời OpenBao) rồi gọi địa chỉ token của nền tảng qua egress bằng TLS 1.2 trở lên với grant `client_credentials`.
5. Nền tảng trả token `expires_in = 3600` giây. Cổng lưu token và thời điểm hết hạn trong bộ nhớ, hẹn làm mới lúc còn 60 giây, rồi dùng token cho lượt gọi (UC-14-09 bước 8).
6. Khi Chi bấm "Thử lấy token", hệ thống gọi API-14-040 và trả `200` kèm `result = OK`, `expiresInSeconds = 3600`, `scope = ndxp.read`; không trả token.

**Luồng thay thế.**

- **4a. Chỉ hỗ trợ `CLIENT_SECRET`.** Trong giai đoạn chuyển đổi cổng dùng xác thực Basic với bí mật ở OpenBao; hệ thống hiện cảnh báo và đòi bí mật có hạn không quá 180 ngày (SEC-24).
- **4b. `TLS_CLIENT_AUTH`.** Cổng dùng chứng thư TLS khách (khóa ở OpenBao PKI) thay vì bí mật.
- **1a. Nhiều bản sao.** Mỗi bản sao giữ token riêng; không bản sao nào chia sẻ token qua đĩa hay Kafka.

**Luồng ngoại lệ.**

- **E1. Chưa đặt thông tin xác thực (bước 3).** ERR-14-034; "Chưa có thông tin xác thực cho nền tảng này ở môi trường PROD. Khai ở kết nối ndxp-oauth trong phân hệ Bộ điều hợp."
- **E2. Nền tảng từ chối thông tin xác thực, `invalid_client` (bước 4).** ERR-14-114 (502); "Nền tảng quốc gia từ chối thông tin xác thực của tỉnh. Kiểm tra với đơn vị quản lý nền tảng."; cổng không thử lại quá một lần trong 5 phút cho cùng nền tảng, đặt nền tảng `DEGRADED` và cảnh báo SO.
- **E3. Không kết nối được địa chỉ token (bước 4).** ERR-14-101 (502); "Không kết nối được tới cổng cấp token của nền tảng."
- **E4. OpenBao không khả dụng (bước 3 hoặc 4).** ERR-14-035 (503); "Kho bí mật tạm thời không khả dụng. Thử lại sau ít phút."; không có token mới nên lượt cần gọi thật bị từ chối.

**Quy tắc áp dụng.** BR-14-005, 031.

**Màn hình, API.** UI-14-03; API-14-040.
:::

### 6.17. UC-14-17 · Xoay vòng và cấp lại thông tin xác thực

::: dac-ta
**Mục tiêu.** Thông tin xác thực với nền tảng được xoay định kỳ và khi nghi lộ mà không gián đoạn dịch vụ; khi cắt chuyển khỏi NGSP cũ, khóa của hệ cũ chắc chắn bị thu hồi ở trung ương.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); ROLE-TENANT_ADMIN (Lan); ROLE-SECURITY_OFFICER (Dũng) khi buộc xoay.

**Tác nhân phụ.** PH-05 (ghi bí mật một chiều, UC-05-04); OpenBao; cổng quốc gia; đơn vị quản lý nền tảng ở trung ương (ngoài hệ thống); PH-13.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-025 (cùng nền: FR-14-024).

**Truy vết.** REQ-14; BP-06, BP-07; LGC-NGSP-008.

**Tiền điều kiện.** Nền tảng `ACTIVE` hoặc `TESTED`; Chi có `PERM-14-operate`; người vận hành đã nhận thông tin xác thực mới từ trung ương.

**Kích hoạt.** Hệ thống nhắc khi bí mật quá 76 ngày (cảnh báo trước hạn 90 ngày 14 ngày); hoặc Chi bấm "Xoay thông tin xác thực" ở UI-14-03; hoặc Dũng buộc xoay khi có sự cố.

**Đảm bảo tối thiểu.** Giá trị cũ giữ nguyên nếu giá trị mới không đạt; không giá trị bí mật nào hiện ở giao diện hay nhật ký.

**Đảm bảo thành công.** Một bộ thông tin xác thực hiệu lực, tuổi bí mật đặt lại, bí mật cũ đã được thu hồi ở trung ương và ghi biên nhận.

**Luồng chính.**

1. Chi bấm "Xoay thông tin xác thực" ở UI-14-03. Hệ thống hiện ba bước: nhận khóa mới từ trung ương, nhập giá trị mới ở kết nối PH-05, kiểm tra.
2. Chi nhận khóa mới từ trung ương (ngoài hệ thống) và đặt giá trị chờ ở kết nối `ndxp-oauth` của PH-05 (UC-05-04).
3. Hệ thống gọi API-14-039 (`rotationState = PENDING_VERIFY`) và lấy token thử bằng giá trị chờ (API-14-040). Đạt.
4. Chi xác nhận chuyển. Cổng bắt đầu cửa sổ chuyển tiếp 24 giờ (`rotationState = OVERLAP`): thử bí mật mới trước, nếu bị từ chối xác thực thì dùng bí mật cũ và đếm `national_secret_fallback_total`; hệ thống phát EVT-14-01.
5. Hết 24 giờ, hệ thống chuyển `AWAITING_REVOCATION` và nhắc Chi xác nhận trung ương đã hủy khóa cũ, yêu cầu nhập `revocationReceipt` (ví dụ "CV 987/CĐS ngày 27/11/2026").
6. Chi nhập biên nhận. Hệ thống đóng cửa sổ, đánh dấu bí mật cũ đã thu hồi, đặt lại bộ đếm tuổi bí mật, ghi kiểm toán, `rotationState = DONE`.

**Luồng thay thế.**

- **1a. Buộc xoay khẩn cấp.** Dũng nghi lộ khóa: nhập `reason`; cổng tạm ngừng nền tảng (UC-14-03), bí mật cũ bị vô hiệu ngay sau khi giá trị mới đạt kiểm tra.
- **5a. Cắt chuyển khỏi NGSP cũ.** UC-14-37 bắt buộc bước 5 và 6 trước khi cho đóng phiên chạy song song; thiếu biên nhận thì không đóng được.
- **4a. Cửa sổ chuyển tiếp.** Nếu bí mật mới bị từ chối ở một lượt, cổng dùng bí mật cũ cho lượt đó và cảnh báo Chi; không mất lượt gọi.

**Luồng ngoại lệ.**

- **E1. Giá trị mới bị nền tảng từ chối (bước 3).** ERR-14-114 (502); "Thông tin xác thực mới bị nền tảng từ chối. Giữ nguyên thông tin cũ."
- **E2. Chưa đặt giá trị chờ ở PH-05 (bước 3).** ERR-14-034 (422); "Hãy nhập thông tin xác thực mới ở kết nối ndxp-oauth trước."
- **E3. Chưa nhập xác nhận thu hồi khi cắt chuyển (bước 6).** ERR-14-004 (409); "Cần xác nhận trung ương đã hủy khóa cũ trước khi đóng chạy song song."
- **E4. Buộc xoay thiếu lý do (nhánh 1a).** ERR-14-003 (400); "Giá trị lý do không hợp lệ: cần từ 10 đến 500 ký tự."
- **E5. OpenBao không khả dụng (bước 2 hoặc 3).** ERR-14-035 (503); "Kho bí mật tạm thời không khả dụng. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-14-005, 031, 034.

**Màn hình, API.** UI-14-03; API-14-039, 040.
:::

### 6.18. UC-14-18 · Nạp và kích hoạt chứng thư số

::: dac-ta
**Mục tiêu.** Cán bộ ATTT nạp chứng thư số chuyên dùng của tỉnh, chứng minh nó khớp khóa trong OpenBao mà không lấy khóa ra, và chỉ đưa vào dùng sau khi người thứ hai duyệt, vì chứng thư quyết định toàn bộ khả năng ký của tỉnh.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng, nạp và yêu cầu kích hoạt); ROLE-INTEGRATION_APPROVER (Bình, duyệt).

**Tác nhân phụ.** OpenBao `transit`; hộp "Việc của tôi"; ROLE-PLATFORM_ADMIN (Hà) cho chứng thư `COMMON`; cổng quốc gia; PH-12 (xác thực nhiều yếu tố).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-028 (nền: FR-14-026).

**Truy vết.** REQ-14; BP-06; không có ở hệ cũ.

**Tiền điều kiện.** Khóa riêng đã được tạo hoặc nhập (BYOK) trong OpenBao `transit` theo quy trình ATTT, có `keyRef = transit/keys/dh-t68-national-sign`; chứng thư công khai đã được cơ quan cấp phát hành; Dũng có `PERM-14-cert`, Bình có `PERM-14-approve`, cả hai xác thực nhiều yếu tố.

**Kích hoạt.** Dũng bấm "Nạp chứng thư" ở UI-14-08.

**Đảm bảo tối thiểu.** Khóa riêng không bao giờ rời OpenBao; chứng thư chưa được duyệt không bao giờ dùng để ký; người nạp không tự duyệt được.

**Đảm bảo thành công.** Chứng thư `cks-t68-2026` ở `ACTIVE`; chứng thư cũ cùng mục đích chuyển `SUPERSEDED` sau 72 giờ; cổng nạp trong 30 giây.

**Luồng chính.**

1. Dũng tải tệp `tinh-t68-2026.p7b`, chọn mục đích `SIGNING`, nhập `keyRef` và ghi chú "Cấp theo công văn 301/CA-CV".
2. Hệ thống gọi API-14-030 và kiểm tra định dạng, chuỗi chứng thư tới một neo tin cậy đã cấu hình, khoảng hiệu lực và mục đích sử dụng khóa `digitalSignature`.
3. Hệ thống kiểm tra khớp khóa: ký thử một giá trị băm ngẫu nhiên qua `transit/sign` rồi xác minh bằng khóa công khai trong chứng thư.
4. Hệ thống lưu chứng thư ở `UPLOADED`, ghi kiểm toán, phát EVT-14-04 và trả `201`.
5. Dũng bấm "Yêu cầu kích hoạt" và xác thực nhiều yếu tố. Hệ thống gọi API-14-032, chuyển `PENDING_ACTIVATION` và tạo việc cho người có `PERM-14-approve`.
6. Bình mở việc ở UI-14-17, xem chủ thể, số sê-ri, hiệu lực (01/12/2026 đến 30/11/2027), mục đích; xác thực nhiều yếu tố và chọn "Duyệt" (API-14-033). Hệ thống kiểm tra Bình khác Dũng (LP-14-01, LP-14-03).
7. Hệ thống đặt `cks-t68-2026` `ACTIVE`; chứng thư cũ `cks-t68-2025` chuyển `SUPERSEDED` sau `14.cert.overlap-hours` = 72 giờ để xác minh các bản tin còn bay; phát EVT-14-04.
8. Cổng nạp chứng thư mới trong 30 giây; từ lượt ký tiếp theo cổng dùng `cks-t68-2026`, giao dịch ghi `certCode`.

**Luồng thay thế.**

- **6a. Từ chối.** Bình từ chối kèm lý do (LP-14-02); chứng thư về `UPLOADED`, Dũng nhận thông báo và có thể sửa rồi yêu cầu lại.
- **1a. Chứng thư chỉ để xác thực TLS khách.** Mục đích `TLS_CLIENT`; khóa lưu ở OpenBao PKI thay vì `transit`.
- **6b. TA khác duyệt.** `PERM-14-approve` cũng thuộc TA; TA khác Dũng duyệt được.
- **1b. Chứng thư `COMMON`.** Hà nạp chứng thư dùng chung toàn quốc cho nền tảng `COMMON`.

**Luồng ngoại lệ.**

- **E1. Tệp không đọc được hoặc không đúng chuỗi (bước 2).** ERR-14-019 (422); "Chứng thư không đọc được hoặc không thuộc chuỗi tin cậy đã cấu hình."
- **E2. Chưa tới hạn hiệu lực hoặc đã hết hạn (bước 2).** ERR-14-021 (409); "Chứng thư chưa tới hạn hiệu lực hoặc đã hết hạn."
- **E3. Không khớp khóa (bước 3).** ERR-14-020 (422); "Chứng thư không khớp với khóa transit/keys/dh-t68-national-sign trong kho bí mật."
- **E4. OpenBao không khả dụng (bước 3 hoặc 7).** ERR-14-035 (503); "Kho bí mật tạm thời không khả dụng. Thử lại sau ít phút."
- **E5. Đã có yêu cầu chờ duyệt (bước 5).** ERR-14-006 (409); "Đã có yêu cầu kích hoạt đang chờ duyệt cho đối tượng này."
- **E6. Người duyệt trùng người nạp (bước 6).** ERR-14-007 (403); "Bạn không thể tự duyệt chứng thư do mình nạp."
- **E7. Chưa xác thực nhiều yếu tố (bước 5 hoặc 6).** Lỗi xác thực lại theo FR-00 (SEC-23); thao tác không được ghi nhận.
- **E8. Trạng thái không cho phép (bước 5 hoặc 6).** ERR-14-004 (409); "Đối tượng đang ở trạng thái ACTIVE hoặc đã được người khác sửa, không thực hiện được thao tác này. Tải lại và thử lại."

**Quy tắc áp dụng.** BR-14-004, 017, 018, 022.

**Màn hình, API.** UI-14-08, 17; API-14-030, 032, 033.
:::

```{.mermaid caption="Trình tự UC-14-18 nạp và kích hoạt chứng thư với hai lớp xác nhận"}
sequenceDiagram
  autonumber
  participant D as Dũng cán bộ ATTT
  participant S as Dịch vụ quản trị PH-14
  participant B as OpenBao transit
  participant I as Bình người duyệt
  participant G as Cổng quốc gia
  D->>S: Tải chứng thư, chọn mục đích, keyRef
  S->>S: Kiểm tra định dạng, chuỗi, hiệu lực
  S->>B: Ký thử băm ngẫu nhiên
  B-->>S: Chữ ký thử
  S->>S: Xác minh bằng khóa công khai trong chứng thư
  D->>S: Yêu cầu kích hoạt kèm xác thực nhiều yếu tố
  I->>S: Duyệt kèm xác thực nhiều yếu tố
  S->>S: Kiểm tra người duyệt khác người nạp
  S->>G: EVT-14-04 nạp chứng thư mới trong 30 giây
```

Hình cho thấy ba lớp bảo vệ trước khi chứng thư được dùng: kiểm tra định dạng và chuỗi, chứng minh khớp khóa bằng ký thử mà không lấy khóa ra, và duyệt bởi người thứ hai có xác thực nhiều yếu tố.

### 6.19. UC-14-19 · Theo dõi hạn, thay thế và thu hồi chứng thư

::: dac-ta
**Mục tiêu.** Cán bộ ATTT và quản trị được cảnh báo sớm và nhiều lần trước khi chứng thư hết hạn, vì chứng thư hết hạn mà chưa có bản thay thế làm ngưng toàn bộ khai thác dữ liệu quốc gia; đồng thời thu hồi được chứng thư khi cần và không xóa nhầm chứng thư còn cần xác minh giao dịch cũ.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Bộ chạy kiểm tra (06:00 hằng ngày); ROLE-TENANT_ADMIN (Lan) nhận cảnh báo; PH-13; PH-12 (thông báo).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-029.

**Truy vết.** REQ-14; BP-06, BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Có ít nhất một chứng thư từ `UPLOADED` trở đi; Dũng có `PERM-14-cert`.

**Kích hoạt.** Bộ chạy kiểm tra chạy lúc 06:00 giờ Việt Nam và khi khởi động; hoặc Dũng bấm "Thu hồi" ở UI-14-08.

**Đảm bảo tối thiểu.** Chứng thư hết hạn hay bị thu hồi không bao giờ được dùng để ký; chứng thư còn giao dịch trong thời hạn lưu không bị xóa.

**Đảm bảo thành công.** Trạng thái chứng thư đúng máy trạng thái; cảnh báo được gửi đúng mốc 60, 30, 7 ngày.

**Luồng chính.**

1. Lúc 06:00 ngày 26/11/2026, bộ chạy kiểm tra tính số ngày còn lại của mọi chứng thư `ACTIVE` và `EXPIRING`: `cks-t68-2025` có `notAfter = 2026-12-20`, còn 24 ngày; đặt `national_cert_days_remaining = 24`.
2. Chứng thư đã chuyển `EXPIRING` từ khi còn 60 ngày; hệ thống đã phát EVT-14-05 mức `INFO` (60 ngày) và `WARNING` (30 ngày, ngày 20/11), gửi thông báo cho Dũng và Lan.
3. Dũng mở UI-14-08 (API-14-029, 031), thấy bảng chứng thư với cột đếm ngược màu vàng và biểu ngữ "Chứng thư cks-t68-2025 còn 24 ngày" trên UI-14-01.
4. Dũng khởi động gia hạn bằng UC-14-18: nạp `cks-t68-2026`; khi được duyệt, chứng thư cũ chuyển `SUPERSEDED` sau 72 giờ.
5. Đến 7 ngày trước hạn mà chưa có chứng thư thay thế, hệ thống phát EVT-14-05 mức `CRITICAL` và hiện biểu ngữ trên mọi trang của phân hệ cho tới khi có chứng thư thay thế `ACTIVE`.
6. Chứng thư `SUPERSEDED` và `EXPIRED` được giữ để xác minh giao dịch cũ (BR-14-019).

**Luồng thay thế.**

- **5a. Hết hạn không còn thay thế.** Chứng thư quá `notAfter` mà không còn chứng thư cùng mục đích dùng được: hệ thống đặt `EXPIRED`, chặn việc ký, phát cảnh báo mức cao nhất; cổng trả ERR-14-113 cho lượt cần ký (BR-14-017).
- **3a. Thu hồi.** Dũng nghi khóa bị lộ nên bấm "Thu hồi" `cks-t68-2025`, nhập lý do và xác nhận (API-14-034); chứng thư chuyển `REVOKED`; nếu đó là chứng thư dùng được cuối cùng thì áp nhánh 5a.
- **3b. Xóa chứng thư tải nhầm.** Chỉ xóa được chứng thư `UPLOADED` chưa từng `ACTIVE`.

**Luồng ngoại lệ.**

- **E1. Xóa chứng thư còn giao dịch cần xác minh (bước 6).** ERR-14-022 (409); "Chứng thư này còn được dùng để xác minh giao dịch trong thời hạn lưu nên không xóa được."
- **E2. Thu hồi chứng thư ở trạng thái cuối (nhánh 3a).** ERR-14-004 (409); "Chứng thư đã hết hạn, bị thu hồi hoặc được thay thế."
- **E3. Thiếu lý do thu hồi (nhánh 3a).** ERR-14-003 (400); "Nhập lý do thu hồi."
- **E4. Lượt gọi cần ký khi không còn chứng thư dùng được.** ERR-14-113 (503) ở bên gọi; "Chứng thư ký số đã hết hạn nên kết nối quốc gia tạm dừng. Liên hệ cán bộ an toàn thông tin."

**Quy tắc áp dụng.** BR-14-017, 019.

**Màn hình, API.** UI-14-08; API-14-029, 031, 034.
:::

### 6.20. UC-14-20 · Cập nhật chuỗi tin cậy và danh sách thu hồi

::: dac-ta
**Mục tiêu.** Việc xác minh chữ ký phản hồi luôn dựa trên chuỗi tin cậy đúng của trung ương và danh sách thu hồi mới, để không chấp nhận chứng thư giả hay đã bị thu hồi và không từ chối nhầm khi trung ương đổi chứng thư.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Bộ chạy kiểm tra; ROLE-INTEGRATION_APPROVER (Bình) duyệt thay đổi neo; cơ quan cấp chứng thư (địa chỉ CRL, OCSP); cổng quốc gia.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-030.

**Truy vết.** REQ-14; BP-06; không có ở hệ cũ.

**Tiền điều kiện.** Có ít nhất một neo tin cậy đã cấu hình cho nền tảng `ndxp-t68`; địa chỉ CRL, OCSP trong egress.

**Kích hoạt.** Bộ chạy kiểm tra làm mới mỗi `14.trust.refresh-hours` = 24 giờ; hoặc Dũng bấm "Làm mới ngay" ở UI-14-08.

**Đảm bảo tối thiểu.** CRL có chữ ký sai bị bỏ, không dùng; thay đổi neo tin cậy không có hiệu lực khi chưa duyệt.

**Đảm bảo thành công.** Mọi bản sao cổng dùng cùng chuỗi tin cậy và CRL trong 30 giây; thời điểm làm mới được ghi.

**Luồng chính.**

1. Bộ chạy kiểm tra tải CRL tại địa chỉ ghi trong chứng thư của cơ quan cấp, qua egress, hoặc tra OCSP.
2. Bộ chạy kiểm tra xác minh chữ ký của CRL bằng chứng thư của cơ quan cấp; đạt.
3. Bộ chạy kiểm tra cập nhật bộ nhớ của mọi bản sao cổng và ghi `crlLastRefreshedAt`.
4. Dũng mở UI-14-08, thấy mục "Chuỗi tin cậy" (API-14-035) với 2 neo, CRL làm mới 06:12 hôm nay, tuổi 3 giờ.
5. Cơ quan cấp công bố chứng thư trung gian mới. Bộ chạy kiểm tra đề xuất thêm vào danh sách neo; Dũng bấm "Đề nghị thêm neo" và tải tệp.
6. Hệ thống tạo việc duyệt cho Bình (LP-14-01); Bình duyệt; hệ thống nạp neo mới cho mọi bản sao cổng trong 30 giây, phát EVT-14-04.

**Luồng thay thế.**

- **1a. Làm mới thủ công.** Dũng bấm "Làm mới ngay" (API-14-036), nhất là sau sự cố chữ ký do trung ương đổi chứng thư (UC-14-21).
- **1b. Tải CRL thất bại.** Bộ chạy kiểm tra thử lại 3 lần cách nhau 5 phút rồi ghi cảnh báo; quá `14.crl.max-age-days` = 7 ngày chưa làm mới được thì cảnh báo mức cao.
- **3a. CRL quá hạn.** Chế độ `14.crl.fail-mode = SOFT` (mặc định) vẫn xác minh và ghi cảnh báo; `HARD` từ chối bản tin; đổi chế độ là thay đổi tham số bảo mật cần hai người (UC-14-36).
- **5a. Bớt neo.** Dũng đề nghị gỡ neo hết dùng; cùng vòng duyệt.

**Luồng ngoại lệ.**

- **E1. Chữ ký CRL sai (bước 2).** Bỏ bản tải về, ghi cảnh báo vận hành, không có mã lỗi cho người dùng; chỉ số `national_crl_age_seconds` tăng.
- **E2. Tệp neo không hợp lệ (bước 5).** ERR-14-019 (422); "Chứng thư neo không đọc được."
- **E3. Người duyệt trùng người đề nghị (bước 6).** ERR-14-007 (403); "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."
- **E4. Không tải được CRL liên tục.** Cảnh báo vận hành cho Dũng và Chi; lượt gọi vẫn xác minh theo chế độ `SOFT` hoặc bị từ chối theo `HARD` (ERR-14-110).

**Quy tắc áp dụng.** BR-14-002, 018.

**Màn hình, API.** UI-14-08, 17; API-14-035, 036.
:::

### 6.21. UC-14-21 · Xử lý sự cố chữ ký

::: dac-ta
**Mục tiêu.** Chữ ký phản hồi sai không bị coi là lỗi kỹ thuật thông thường: đó có thể là tấn công xen giữa hoặc lỗi cấu hình nghiêm trọng, nên được ghi nhận, báo ngay Cán bộ ATTT trong 1 phút, không dùng dữ liệu và xử lý có hồ sơ đến khi kết luận.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Cổng quốc gia (mở sự cố); ROLE-TENANT_ADMIN (Lan) nhận thông báo; PH-13 (SIEM, sự cố ATTT); cơ quan chức năng (ngoài hệ thống).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-027, 031.

**Truy vết.** REQ-14; BP-06, BP-07; THR-53; không có ở hệ cũ.

**Tiền điều kiện.** FR-14-027 hoặc FR-14-040 vừa từ chối một bản tin vì lý do chữ ký; Dũng có `PERM-14-operate` và `PERM-14-audit-read`.

**Kích hoạt.** Tự động khi xác minh thất bại; Dũng mở UI-14-14 khi nhận cảnh báo.

**Đảm bảo tối thiểu.** Dữ liệu của giao dịch có chữ ký sai không bao giờ được dùng hay trả cho HTTT; mọi sự cố có bản ghi giữ 5 năm.

**Đảm bảo thành công.** Sự cố `RESOLVED` kèm phân loại, hành động, kết luận; nền tảng ra khỏi `SECURITY_HOLD` nếu đã vào.

**Luồng chính.**

1. Lúc 10:42 cổng xác minh phản hồi dịch vụ `lltp-tra-trang-thai` và thấy chứng thư của NDXP không thuộc chuỗi tin cậy. Cổng từ chối dữ liệu (ERR-14-110 ở bên gọi) và tạo `signature_incident` ở `OPEN`, loại `UNTRUSTED_CHAIN`, gắn giao dịch và chứng thư đối tác, dấu vết kỹ thuật đã che.
2. Trong 1 phút hệ thống gửi cảnh báo cho Dũng và Lan, hiện biểu ngữ đỏ không ẩn được trên UI-14-01, và chuyển sự kiện an ninh sang PH-13 để đẩy SIEM (EVT-14-06).
3. Đến 10:48 đã có 5 sự cố cùng nền tảng trong 10 phút (bằng `14.signature.hold-threshold`): hệ thống đặt `ndxp-t68` `SECURITY_HOLD`, từ chối mọi lượt cần dữ liệu mới, phát EVT-14-01.
4. Dũng mở UI-14-14 (API-14-037), xem chi tiết rồi bấm "Xác nhận" (API-14-038, `ACKNOWLEDGED`); biểu ngữ đỏ biến mất.
5. Dũng phân loại "Trung ương đổi chứng thư", chọn hành động "Làm mới chuỗi tin cậy" và thực hiện UC-14-20 (đề nghị thêm neo mới, Bình duyệt).
6. Dũng nhập kết luận "CA trung gian của NDXP đổi ngày 26/11, đã bổ sung neo" và bấm "Kết thúc" (`RESOLVED`). Hệ thống kiểm tra không còn sự cố chưa xác nhận, giải trừ `SECURITY_HOLD` kèm lý do, ghi kiểm toán, phát EVT-14-01.

**Luồng thay thế.**

- **5a. Nghi tấn công.** Dũng tạm ngừng nền tảng (UC-14-03), mở sự cố ATTT ở PH-13 theo quy trình SEC-72 và báo cơ quan chức năng theo mốc SEC-74.
- **3a. Dưới ngưỡng.** Ít sự cố hơn ngưỡng thì nền tảng không vào `SECURITY_HOLD`; từng lượt vẫn bị từ chối riêng.
- **5b. Lỗi cấu hình của tỉnh.** Phân loại "Lỗi cấu hình" (ví dụ lệch đồng hồ nên `STALE_TIMESTAMP`): Dũng nhờ Chi kiểm tra NTP trước khi kết thúc.

**Luồng ngoại lệ.**

- **E1. Kết thúc chưa có kết luận (bước 6).** ERR-14-003 (400); "Nhập kết luận xử lý trước khi kết thúc sự cố."
- **E2. Giải trừ khi còn sự cố chưa xác nhận (bước 6).** ERR-14-004 (409); "Còn sự cố chữ ký chưa xác nhận. Xử lý trước khi giải trừ."
- **E3. Bên gọi gặp lỗi chữ ký (bước 1).** ERR-14-109, ERR-14-110 hoặc ERR-14-111 (502); "Không thể tin cậy dữ liệu nhận được. Sự cố đã được ghi nhận và báo cán bộ an toàn thông tin." Cụ thể: chữ ký không khớp (109), chứng thư không thuộc chuỗi hoặc bị thu hồi (110), thời điểm ký ngoài khoảng hoặc bản tin lặp (111).
- **E4. Lượt gọi trong `SECURITY_HOLD` cần dữ liệu mới (bước 3).** Cổng từ chối lượt (mô tả ở FRS §4.3); HTTT có thể dùng đệm nếu dịch vụ cho phép. FRS chưa quy định mã lỗi và câu thông báo riêng cho trường hợp này, xem Q14-46.

**Quy tắc áp dụng.** BR-14-002, 003.

**Màn hình, API.** UI-14-14, 08; API-14-037, 038.
:::

**Nhóm 4 · Hạn mức, đệm và chịu lỗi (UC-14-22…25).** Hạn mức truy vấn do trung ương áp cho cả tỉnh là tài nguyên khan hiếm: vượt thì mọi HTTT bị từ chối, kể cả dịch vụ công đang có người dân chờ. Vì vậy nhóm này là thành phần thiết yếu chứ không phải tối ưu. Thứ tự cổng chặn của một lượt gọi (đã đặc tả ở UC-14-09 bước 6, 7) là: ủy quyền mục đích, đệm (trúng thì không tốn hạn mức), phân bổ theo HTTT, ưu tiên theo mức dùng, hạn mức dịch vụ và nền tảng, ngắt mạch, và cuối cùng là đệm quá hạn như lưới an toàn.

### 6.22. UC-14-22 · Khai báo hạn mức và phân bổ theo HTTT

::: dac-ta
**Mục tiêu.** Quản trị tenant ghi lại hạn mức truy vấn mà trung ương thông báo kèm căn cứ văn bản, rồi chia cho từng HTTT để một HTTT tra nhiều không nuốt hết phần của HTTT khác; cổng đếm và chặn đúng theo con số đã duyệt.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan, `PERM-14-quota`).

**Tác nhân phụ.** ROLE-INTEGRATION_APPROVER (Bình, duyệt hạn mức môi trường thật); cổng quốc gia; Kafka; PH-02 (hạn mức mặc định từ cung cấp lại).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-032, 034.

**Truy vết.** REQ-14; BP-06, BP-01; không có ở hệ cũ.

**Tiền điều kiện.** Nền tảng `ndxp-t68` và dịch vụ `lltp-tra-trang-thai` tồn tại; Lan có `PERM-14-quota`; Bình có `PERM-14-approve`; trung ương đã thông báo hạn mức bằng văn bản.

**Kích hoạt.** Lan bấm "+ Hạn mức" hoặc "Phân bổ" ở UI-14-09.

**Đảm bảo tối thiểu.** Hạn mức chưa được duyệt không có hiệu lực ở môi trường thật; tổng phân bổ không bao giờ vượt hạn mức; mức dùng của chu kỳ đang chạy không bị đặt lại khi đổi hạn mức.

**Đảm bảo thành công.** Hạn mức `ACTIVE` kèm căn cứ và hiệu lực từ `effectiveFrom`; phân bổ theo HTTT đã lưu; cổng nạp trong 30 giây.

**Luồng chính.**

1. Lan chọn phạm vi là dịch vụ `lltp-tra-trang-thai`, chu kỳ `DAY`, giới hạn 30.000, `effectiveFrom = 2026-12-01T00:00:00+07:00`, căn cứ "Văn bản số 88/CĐS-HTKT ngày 05/11/2026 về hạn mức kết nối" (giả định).
2. Hệ thống gọi API-14-042 và kiểm tra giới hạn là số nguyên dương, chu kỳ hợp lệ, căn cứ văn bản không rỗng.
3. Lan bấm "Gửi duyệt". Hệ thống tạo việc cho Bình (LP-14-01) và trả `202`; Bình duyệt.
4. Hệ thống đặt hạn mức có hiệu lực từ `effectiveFrom`, ghi kiểm toán kèm căn cứ, phát EVT-14-08; cổng nạp trong 30 giây.
5. Lan mở bảng "Phân bổ theo HTTT" (API-14-044) và nhập cho dịch vụ này: `HT-MOTCUA` 18.000, `HT-TUPHAP` 8.000, `HT-DVC` 2.000 mỗi ngày; phần 2.000 còn lại là vùng đệm chung.
6. Hệ thống gọi API-14-045 cho từng HTTT, kiểm tra tổng 28.000 không vượt 30.000, lưu, ghi kiểm toán, phát EVT-14-08.
7. Từ lượt gọi sau, cổng kiểm tra phân bổ của HTTT trước hạn mức chung (UC-14-23).

**Luồng thay thế.**

- **2a. Môi trường thử.** Hạn mức ở môi trường thử không cần duyệt.
- **1a. Trung ương đổi hạn mức.** Lan tạo bản mới với căn cứ mới; bản cũ chuyển `SUPERSEDED` và vẫn xem được.
- **5a. Lấy mặc định từ cung cấp lại.** Lan chọn "Dùng mặc định từ hợp đồng" để lấy `defaultAllocation` đã khai ở UC-14-07.
- **5b. Không giới hạn cho dịch vụ thiết yếu.** Lan đặt phân bổ `UNLIMITED` cho dịch vụ thiết yếu của `HT-MOTCUA` (vẫn chịu hạn mức chung).
- **1b. Hạn mức theo nền tảng.** Lan để trống dịch vụ để áp cho cả nền tảng (ví dụ 50.000 mỗi ngày).

**Luồng ngoại lệ.**

- **E1. Thiếu căn cứ (bước 2).** ERR-14-016 (422); "Nhập căn cứ văn bản của hạn mức (số, ngày, trích yếu)."
- **E2. Giới hạn hoặc chu kỳ không hợp lệ (bước 2).** ERR-14-017 (422); "Giới hạn phải là số nguyên lớn hơn 0 và chu kỳ là giờ, ngày hoặc tháng."
- **E3. Giảm hạn mức dưới tổng phân bổ (bước 2).** Lan giảm xuống 25.000 trong khi đã phân bổ 28.000: ERR-14-018 (422); "Tổng phân bổ cho các HTTT (28.000) vượt giới hạn mới. Giảm phân bổ trước."
- **E4. Phân bổ vượt hạn mức (bước 6).** ERR-14-018 (422); "Tổng phân bổ (31.000) vượt hạn mức 30.000. Giảm phân bổ của một HTTT."
- **E5. Người duyệt trùng người đề nghị (bước 3).** ERR-14-007 (403); "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."
- **E6. Dữ liệu đã bị sửa (bước 2 hoặc 6).** ERR-14-004 (412 khi `If-Match` lệch, 409 khi trạng thái không cho phép); "Đối tượng đang ở trạng thái ACTIVE hoặc đã được người khác sửa, không thực hiện được thao tác này. Tải lại và thử lại."

**Quy tắc áp dụng.** BR-14-011, 012, 013, 022.

**Màn hình, API.** UI-14-09, 17; API-14-041, 042, 044, 045.
:::

### 6.23. UC-14-23 · Đếm hạn mức, cảnh báo ngưỡng và hoãn theo ưu tiên

::: dac-ta
**Mục tiêu.** Cổng đếm chính xác số lượt đã gọi ra quốc gia trong từng chu kỳ, chặn trước khi vượt, cảnh báo khi tiến gần và nhường hạn mức cho dịch vụ thiết yếu, để tỉnh không bao giờ bị trung ương từ chối vì vượt hạn mức mà không biết trước.

**Tác nhân chính.** Cổng quốc gia (máy); ROLE-TENANT_OPERATOR (Chi) theo dõi.

**Tác nhân phụ.** Valkey (bộ đếm); PostgreSQL (`quota_usage`); PH-13; ROLE-TENANT_ADMIN (Lan) nhận cảnh báo.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-033 (nền: FR-14-034).

**Truy vết.** REQ-14, REQ-13; BP-06, BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Có hạn mức `ACTIVE` áp cho lượt gọi (nếu không có thì không chặn nhưng vẫn đếm); phân bổ theo HTTT đã khai ở UC-14-22.

**Kích hoạt.** Bước 7 của UC-14-09, trước khi gửi ra ngoài; mỗi lần thử lại (UC-14-25) cũng đi qua bước này.

**Đảm bảo tối thiểu.** Lượt chưa tới được nền tảng vì lỗi cục bộ được hoàn lại; không bỏ kiểm tra hạn mức khi Valkey lỗi; tác vụ nền không làm ngưng dịch vụ thiết yếu.

**Đảm bảo thành công.** Bộ đếm đúng; cảnh báo ngưỡng phát một lần mỗi ngưỡng mỗi chu kỳ; lượt bị từ chối kèm `resetAt` và thông tin đệm khả dụng.

**Luồng chính.**

1. Cổng xác định mọi hạn mức áp cho lượt `lltp-tra-trang-thai` của `HT-MOTCUA`: hạn mức dịch vụ (30.000 mỗi ngày) và hạn mức nền tảng (50.000 mỗi ngày), ở mọi chu kỳ.
2. Cổng kiểm tra phân bổ của `HT-MOTCUA` (18.000) trước hạn mức chung, rồi tăng nguyên tử bộ đếm ở Valkey theo từng (tenant, phạm vi, chu kỳ, cửa sổ) và so với giới hạn.
3. Đến 14:05, mức dùng hạn mức nền tảng cắt ngưỡng 70%: cổng phát EVT-14-07 một lần, hệ thống gửi thông báo cho Lan và Chi (tuân thủ FR-00-060); từ giờ đó dịch vụ `BACKGROUND` (đồng bộ hồ sơ ĐVQHNS) bị hoãn với ERR-14-104 `DEFERRED`.
4. Đến 16:30 mức dùng chạm 85%, thẻ chuyển vàng; đến 17:10 chạm 95%: chỉ dịch vụ `ESSENTIAL` được gọi, dịch vụ `NORMAL` nhận ERR-14-104 hoặc dùng đệm.
5. Mỗi phút cổng ghi bộ đếm vào `quota_usage` ở PostgreSQL để không mất khi Valkey khởi động lại.
6. Chi mở UI-14-01 và UI-14-09 (API-14-041, 043): bảng hạn mức hiện đã dùng, giới hạn, tỷ lệ, `forecastExhaustAt` (dự báo cạn 21:40) và khuyến nghị tăng thời hạn đệm.
7. Lúc 00:00 ngày 27/11 bộ đếm đặt lại; các ngưỡng được phép phát lại.

**Luồng thay thế.**

- **2a. Valkey không khả dụng.** Cổng chuyển sang đếm cục bộ ở mỗi bản sao, giới hạn chia đều theo số bản sao đang chạy, ghi cảnh báo "đếm suy giảm"; không bỏ kiểm tra.
- **2b. Lỗi cục bộ.** Lượt không tới được nền tảng vì không ký được, không có token hoặc ngắt mạch: cổng hoàn lại lượt đã trừ; lượt đã gửi, kể cả bị nền tảng trả lỗi, vẫn tính.
- **2c. Trúng đệm.** Lượt trúng đệm không qua bước này nên không tốn hạn mức (UC-14-24).
- **4a. Hạn mức hết nhưng có đệm quá hạn.** Cổng trả dữ liệu đệm có cờ `stale` thay vì lỗi (UC-14-24).

**Luồng ngoại lệ.**

- **E1. Hết hạn mức dịch vụ hoặc nền tảng (bước 2).** ERR-14-104 (429); "Đã dùng hết hạn mức lltp-tra-trang-thai: 30.000 trên 30.000 lượt mỗi ngày. Bộ đếm đặt lại lúc 00:00 ngày 27/11/2026."; kèm `resetAt`, `cache.available`.
- **E2. HTTT hết phần được giao (bước 2).** ERR-14-104 (429, `scope = SYSTEM`); "HTTT HT-MOTCUA đã dùng hết phần hạn mức được giao. Liên hệ quản trị tỉnh để điều chỉnh."
- **E3. Bị hoãn do ưu tiên (bước 3).** ERR-14-104 (429, `reason = DEFERRED`); "Tác vụ nền được hoãn để dành hạn mức cho dịch vụ công. Thử lại sau 00:00 ngày 27/11/2026."
- **E4. Đếm suy giảm khi Valkey lỗi.** Không có mã lỗi riêng; Chi thấy cảnh báo "Bộ đếm hạn mức đang chạy ở chế độ suy giảm" ở UI-14-01.

**Quy tắc áp dụng.** BR-14-012, 013.

**Màn hình, API.** UI-14-01, 09; API-14-041, 043.
:::

### 6.24. UC-14-24 · Quản lý đệm và dữ liệu quá hạn

::: dac-ta
**Mục tiêu.** Cổng đệm phản hồi theo thời hạn riêng của từng dịch vụ để không chạm hạn mức trong giờ cao điểm, vận hành vô hiệu đệm được khi dữ liệu ở quốc gia đã đổi, và khi quốc gia gián đoạn dịch vụ công vẫn tiếp tục bằng dữ liệu đệm quá hạn có cờ rõ ràng.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); cổng quốc gia (tự động).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Lan, vô hiệu toàn bộ); Valkey; HTTT bên gọi; PH-13.

**Mức ưu tiên.** M (đệm, dữ liệu quá hạn), S (vô hiệu đệm thủ công).

**FR hiện thực.** FR-14-035, 036, 037.

**Truy vết.** REQ-14; BP-06; không có ở hệ cũ.

**Tiền điều kiện.** Dịch vụ `dkdn-du-lieu-moi-nhat` `cacheable = true`, `cacheTtlSeconds = 3600`, `staleAllowed = true`; Valkey sẵn sàng; Chi có `PERM-14-operate`.

**Kích hoạt.** Tự động ở bước 6 của UC-14-09; Chi bấm "Vô hiệu đệm" ở UI-14-09.

**Đảm bảo tối thiểu.** Không đệm dịch vụ mức `SENSITIVE`, thao tác ghi, hay lỗi; khóa đệm luôn có tiền tố tenant; ủy quyền mục đích luôn được kiểm trước khi đọc đệm; dữ liệu quá hạn luôn kèm cờ `stale`.

**Đảm bảo thành công.** Tỷ lệ trúng đệm đạt tối thiểu 60% với dịch vụ tra cứu được đệm; vô hiệu đệm có hiệu lực ở lượt gọi tiếp theo; dịch vụ công không đứng khi quốc gia sự cố.

**Luồng chính.**

1. Hệ thống tính khóa đệm gồm tenant `T68`, dịch vụ, thao tác và băm của `params` đã chuẩn hóa; kiểm tra HTTT đã qua ủy quyền mục đích, rồi tra đệm; trúng thì trả `HIT` kèm `cacheAgeSeconds`.
2. 40 lượt cùng khóa (cùng mã số doanh nghiệp) đến cùng lúc khi chưa có đệm: hệ thống chỉ cho một lượt gọi thật, 39 lượt còn lại chờ kết quả đó (gộp lượt trùng).
3. Phản hồi thành công đã xác minh được lưu với thời hạn mềm 3.600 giây và thời hạn cứng cộng `14.cache.stale-max-seconds` (86.400 giây).
4. Chi mở UI-14-09 (API-14-046): tỷ lệ trúng 64%, tiết kiệm 12.400 lượt trong ngày, 3 lần phục vụ dữ liệu cũ.
5. Trung ương báo dữ liệu doanh nghiệp vừa đổi hàng loạt. Chi bấm "Vô hiệu đệm", chọn phạm vi `SERVICE` với `dkdn-du-lieu-moi-nhat`, nhập lý do và xác nhận (FR-00-050).
6. Hệ thống gọi API-14-047, xóa các khóa khớp tiền tố tenant và dịch vụ theo từng lô, không chặn lưu lượng, trả số khóa đã xóa (1.846), ghi kiểm toán, phát EVT-14-09; lượt gọi tiếp theo lấy dữ liệu tươi và tốn hạn mức.
7. Lúc 11:20 NDXP không phản hồi. Với lượt gọi không trúng đệm mềm, cổng nhận ERR-14-103, thấy dịch vụ `staleAllowed`, thao tác `READ`, mức không phải `SENSITIVE`, có mục đệm trong thời hạn cứng nên trả `200` với `meta.stale = true`, `X-DH-Cache: STALE`, `Warning: 110`.

**Luồng thay thế.**

- **5a. Vô hiệu một khóa.** Chi chọn `KEY` kèm `params` để xóa đúng một khóa.
- **5b. Vô hiệu toàn bộ.** Chọn `ALL` chỉ Lan được phép.
- **5c. Vô hiệu tự động.** Khi nhận thông báo thay đổi từ trung ương (UC-14-28) hoặc kích hoạt đặc tả mới (UC-14-05), hệ thống tự xóa đúng khóa thông báo nêu hoặc cả dịch vụ.
- **7a. Bên gọi từ chối dữ liệu cũ.** HTTT gửi `X-DH-Accept-Stale: false` và nhận lỗi gốc thay vì dữ liệu đệm.
- **1a. Valkey không khả dụng.** Cổng bỏ qua đệm, gọi thật nhưng vẫn kiểm tra hạn mức, ghi cảnh báo; không trả lỗi cho người dùng vì lý do đệm.
- **1b. Bên gọi cần dữ liệu tươi.** `freshData = true` bỏ qua đệm khi còn hạn mức.

**Luồng ngoại lệ.**

- **E1. Vô hiệu toàn bộ bởi người không phải TA (bước 5).** Lỗi 403 theo FR-00; "Chỉ quản trị tỉnh được xóa toàn bộ đệm."
- **E2. Phạm vi sai (bước 5).** ERR-14-003 (400); "Phạm vi vô hiệu đệm không hợp lệ."
- **E3. Không có đệm phù hợp khi quốc gia lỗi (bước 7).** ERR-14-103 hoặc ERR-14-104; "Nền tảng quốc gia chưa phản hồi và chưa có dữ liệu lưu tạm phù hợp. Thử lại sau."
- **E4. Hết hạn mức khi cần dữ liệu tươi.** ERR-14-104 (429) kèm gợi ý "gọi lại với dữ liệu đệm" nếu có đệm.
- **E5. Cấu hình đệm mâu thuẫn khi khai báo dịch vụ.** ERR-14-038 hoặc ERR-14-036 ở UC-14-04: "Dịch vụ mức Nhạy cảm hoặc dịch vụ ghi không được bật đệm."

**Quy tắc áp dụng.** BR-14-014, 015, 016.

**Màn hình, API.** UI-14-09, 05; API-14-046, 047.
:::

### 6.25. UC-14-25 · Ngắt mạch và thử lại

::: dac-ta
**Mục tiêu.** Khi một nền tảng đang lỗi, cổng tạm ngừng gọi để không dồn thêm tải và không làm chậm mọi HTTT chờ vô ích; lỗi thoáng qua được hấp thụ bằng thử lại đúng chỗ mà không lãng phí hạn mức.

**Tác nhân chính.** Cổng quốc gia (máy); ROLE-TENANT_OPERATOR (Chi) ép mở hoặc đóng tay.

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng) cũng có quyền ép; PH-13, PH-04 (nhận EVT-14-10); NDXP.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-038 (nền: FR-14-015).

**Truy vết.** REQ-14; BP-06, BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Nền tảng `ndxp-t68` `ACTIVE`; Chi có `PERM-14-operate`.

**Kích hoạt.** Mỗi lượt gửi ra nền tảng; hoặc Chi bấm "Ép mở", "Ép đóng" ở UI-14-01.

**Đảm bảo tối thiểu.** Thao tác ghi không idempotent không bao giờ thử lại tự động; thử lại không tiêu hết hạn mức; lỗi xác thực không thử lại quá một lần trong 5 phút.

**Đảm bảo thành công.** Bộ ngắt mạch ở trạng thái đúng với tình trạng nền tảng; lượt gọi được trả lỗi nhanh hoặc dùng đệm; hàng chờ không mất.

**Luồng chính.**

1. Cổng ghi kết quả mỗi lượt gửi vào cửa sổ trượt của (`ndxp-t68`, nhóm `LLTP`).
2. NDXP bắt đầu trả `503`. Trong cửa sổ có 24 lượt với 15 lỗi (62%), vượt `14.breaker.failure-ratio` = 0,5 và đủ `14.breaker.min-calls` = 20: bộ ngắt mạch chuyển `OPEN` trong 30 giây, phát EVT-14-10 cho PH-13 và PH-04.
3. Trong lúc `OPEN`, cổng trả ngay ERR-14-103 hoặc dùng dữ liệu đệm quá hạn nếu được phép (UC-14-24), không gọi ra nền tảng.
4. Hết 30 giây, bộ ngắt mạch chuyển `HALF_OPEN` và cho 3 lượt thăm dò; cả ba đạt nên chuyển `CLOSED`.
5. Với lỗi `retryable` của thao tác `READ`, cổng thử lại tối đa 2 lần với độ trễ tăng theo hàm mũ có nhiễu từ 200 ms, không vượt tổng `timeoutMs`; mỗi lần thử lại đi qua kiểm tra hạn mức (UC-14-23) và bị bỏ qua nếu mức dùng đã đạt ngưỡng chỉ dành cho dịch vụ thiết yếu.
6. Với thao tác ghi không idempotent, cổng không thử lại; kết quả chưa rõ chuyển `UNKNOWN_RESULT` và đối soát (UC-14-10).

**Luồng thay thế.**

- **2a. Ép mở trước bảo trì.** Trung ương báo bảo trì lúc 22:00; Chi bấm "Ép mở" (API-14-086), nhập lý do, hệ thống ghi kiểm toán và giữ bộ ngắt mạch mở tới khi Chi "Ép đóng".
- **4a. Thăm dò không đạt.** Bộ ngắt mạch quay về `OPEN` thêm 30 giây.
- **3a. Gọi bất đồng bộ.** Yêu cầu ở lại hàng chờ và gửi khi nền tảng hồi phục (UC-14-10); hàng chờ tích lũy phát EVT-14-10.
- **5a. Thao tác ghi idempotent.** Bộ xử lý thử lại như thao tác đọc vì gửi lại không gây trùng.

**Luồng ngoại lệ.**

- **E1. Nền tảng ngắt mạch, không đệm, không dự phòng (bước 3).** ERR-14-103 (503); "Nền tảng quốc gia tạm thời không phản hồi. Hệ thống sẽ thử lại tự động, hãy gọi lại sau ít phút."
- **E2. Lỗi xác thực (bước 5).** Không thử lại quá một lần trong 5 phút cho cùng nền tảng (BR-14-031); ERR-14-114 (502).
- **E3. Ép mở hoặc đóng thiếu lý do (nhánh 2a).** ERR-14-003 (400); "Giá trị lý do không hợp lệ: cần từ 10 đến 500 ký tự."
- **E4. Quá hạn chờ (bước 5).** ERR-14-115 (504); "Nền tảng quốc gia không trả lời trong 15 giây."

**Quy tắc áp dụng.** BR-14-030, 031.

**Màn hình, API.** UI-14-01; API-14-086.
:::

**Nhóm 5 · Chiều vào và đồng bộ (UC-14-26…31).** Chiều vào có yêu cầu ngược với chiều ra: tần suất thấp nhưng phải luôn sẵn sàng, điểm cuối nằm ở vùng biên nên phải có bảo vệ riêng, và nguồn gọi phải được xác minh nghiêm ngặt trước khi bất cứ thứ gì chạm vào lõi (xác minh trước, xử lý sau). Đồng bộ là các luồng theo lô hoặc theo lịch giữa Datahub và nền tảng quốc gia: bất đồng bộ, có biên nhận, có đối soát số gửi với số được chấp nhận, thử lại an toàn nhờ chống trùng.

### 6.26. UC-14-26 · Đăng ký và bật điểm cuối chiều vào

::: dac-ta
**Mục tiêu.** Tỉnh khai báo địa chỉ mà nền tảng quốc gia sẽ gọi vào, danh sách nguồn được phép (mã đơn vị gửi, vân tay chứng thư mTLS, dịch vụ được gọi) và luồng PH-04 xử lý từng dịch vụ, để chỉ nguồn đã đăng ký mới gọi được và mỗi điểm cuối gắn đúng một tenant.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan, khai báo); ROLE-SECURITY_OFFICER (Dũng, xác nhận vân tay và bật).

**Tác nhân phụ.** PH-04 (luồng xử lý); PH-03 (nạp tuyến APISIX); đơn vị quản lý nền tảng ở trung ương (nhận đăng ký, ngoài hệ thống); Kafka.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-039.

**Truy vết.** REQ-14, REQ-03; BP-06; không có ở hệ cũ (SRS cũ FR-14-011).

**Tiền điều kiện.** Nền tảng `ndxp-t68` `ACTIVE`; luồng `lltp-nhan-ho-so` đã phát hành ở PH-04; dịch vụ `nhan-ho-so-lltp` khai `direction = INBOUND`; Lan có `PERM-14-admin`, Dũng có `PERM-14-cert`; tỉnh có văn bản của trung ương nêu chứng thư và mã đơn vị gửi.

**Kích hoạt.** Lan bấm "+ Điểm cuối chiều vào" ở UI-14-10.

**Đảm bảo tối thiểu.** Điểm cuối chưa được xác nhận không nhận bản tin nào; không điểm cuối nào dùng chung giữa hai tenant; người khai báo không tự bật.

**Đảm bảo thành công.** Điểm cuối `ndxp-vao-t68` ở `ACTIVE`; tuyến APISIX đã nạp với mTLS, giới hạn tần suất và WAF; kiểm toán đủ.

**Luồng chính.**

1. Lan nhập mã `ndxp-vao-t68`, chọn nền tảng `ndxp-t68`, khai một nguồn được phép: `senderCode = NDXP-QG`, `certFingerprint` (SHA-256, 64 ký tự hexa), `serviceCodes = ["nhan-ho-so-lltp"]`; ánh xạ `nhan-ho-so-lltp` sang luồng `lltp-nhan-ho-so`; `signatureRequired = true`, `rateLimitPerSecond = 20`, `maxMessageKb = 512`.
2. Hệ thống gọi API-14-049 và kiểm tra mã và đường dẫn chưa dùng, danh sách nguồn không rỗng, luồng tồn tại và đã phát hành ở PH-04.
3. Hệ thống lưu điểm cuối ở `DRAFT` và hiển thị thông tin để Lan gửi đăng ký với trung ương: địa chỉ đầy đủ `https://inbound.t68.gov.vn/inbound/v1/ndxp-vao-t68/nhan-ho-so-lltp`, chứng thư mTLS máy chủ, địa chỉ egress nếu cần.
4. Lan gửi đăng ký với trung ương (ngoài hệ thống) và nhận lại văn bản xác nhận chứng thư của nguồn.
5. Dũng mở việc ở UI-14-17 và đối chiếu vân tay chứng thư của nguồn với văn bản của trung ương, rồi bấm "Xác nhận" (API-14-090). Hệ thống kiểm tra Dũng khác Lan (LP-14-01) và chuyển điểm cuối sang `ACTIVE`.
6. Hệ thống phát EVT-14-13; PH-03 nạp tuyến APISIX cho điểm cuối; hệ thống ghi kiểm toán toàn bộ thay đổi.
7. Lan mở danh sách nguồn (API-14-051) và thấy `NDXP-QG` trạng thái hoạt động; thống kê bản tin vào trên UI-14-10 bắt đầu có số liệu từ lượt đầu tiên (UC-14-27).

**Luồng thay thế.**

- **1a. Thêm hoặc bớt một nguồn.** Lan sửa danh sách nguồn qua API-14-052; thay đổi trên điểm cuối đã `ACTIVE` cũng cần Dũng xác nhận lại.
- **6a. Tạm ngưng.** Lan hoặc Dũng đặt điểm cuối `SUSPENDED` qua API-14-050; có hiệu lực trong 30 giây.
- **1b. Tắt kiểm tra chữ ký.** `signatureRequired = false` chỉ do Dũng đặt và phải nêu lý do (ví dụ nền tảng chưa hỗ trợ ký ở giai đoạn thử), có ghi kiểm toán.
- **5a. Từ chối xác nhận.** Dũng từ chối kèm lý do (LP-14-02) vì vân tay không khớp văn bản; điểm cuối về `DRAFT`.

**Luồng ngoại lệ.**

- **E1. Mã đã dùng (bước 2).** ERR-14-002 (409); "Mã ndxp-vao-t68 đã được dùng (kể cả đối tượng đã ngừng dùng). Chọn mã khác."
- **E2. Mã hoặc đường dẫn trùng (bước 2).** ERR-14-023 (409); "Mã hoặc đường dẫn điểm cuối đã được dùng."
- **E3. Danh sách nguồn rỗng (bước 2).** ERR-14-024 (422); "Khai báo ít nhất một nguồn được phép gọi vào."
- **E4. Luồng chưa tồn tại hoặc chưa phát hành (bước 2).** ERR-14-039 (422); "Luồng lltp-nhan-ho-so chưa tồn tại hoặc chưa được phát hành ở phân hệ Tích hợp."
- **E5. Người xác nhận trùng người khai báo (bước 5).** ERR-14-007 (403); "Người xác nhận phải khác người khai báo."
- **E6. PH-04 không khả dụng (bước 2).** ERR-14-027 (502); "Phân hệ liên quan chưa phản hồi. Thử lại sau ít phút."
- **E7. Trạng thái không cho phép (bước 5 hoặc 6a).** ERR-14-004 (409); "Đối tượng đang ở trạng thái ACTIVE hoặc đã được người khác sửa, không thực hiện được thao tác này. Tải lại và thử lại."

**Quy tắc áp dụng.** BR-14-022, 027, 028.

**Màn hình, API.** UI-14-10, 17; API-14-048, 049, 050, 051, 052, 090.
:::

### 6.27. UC-14-27 · Tiếp nhận yêu cầu từ quốc gia và chuyển luồng PH-04

::: dac-ta
**Mục tiêu.** Nền tảng quốc gia gọi vào tỉnh (xác minh dữ liệu địa phương, chuyển hồ sơ) và nhận phản hồi đã ký, trong khi lõi tích hợp của tỉnh chỉ thấy bản tin đã xác minh và luồng PH-04 không phải biết gì về mTLS hay chữ ký.

**Tác nhân chính.** NDXP (hệ thống ngoài, nguồn `NDXP-QG`).

**Tác nhân phụ.** APISIX vùng biên (PH-03); cổng quốc gia; luồng PH-04 `lltp-nhan-ho-so`; OpenBao `transit`; Valkey (chống phát lại); ROLE-SECURITY_OFFICER (Dũng) nhận cảnh báo.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-040, 041 (nền: FR-14-026, 027).

**Truy vết.** REQ-14, REQ-03, REQ-04; BP-06, BP-02; LGC-NGSP-001 (nhận hồ sơ đăng ký).

**Tiền điều kiện.** Điểm cuối `ndxp-vao-t68` `ACTIVE`; nguồn `NDXP-QG` được phép với `nhan-ho-so-lltp`; chứng thư của nguồn thuộc chuỗi tin cậy (UC-14-20); luồng `lltp-nhan-ho-so` đã phát hành.

**Kích hoạt.** NDXP gọi `POST /inbound/v1/ndxp-vao-t68/nhan-ho-so-lltp` qua vùng biên.

**Đảm bảo tối thiểu.** Không bản tin nào chưa xác minh chạm luồng PH-04; mọi lần từ chối có giao dịch để Cán bộ ATTT xem; phản hồi không bao giờ trả khi chưa ký; lỗi không tiết lộ cấu hình nội bộ.

**Đảm bảo thành công.** NDXP nhận phản hồi có chữ ký của tỉnh; giao dịch `INBOUND` ở `SUCCEEDED`.

**Luồng chính.**

1. NDXP gọi điểm cuối với tiêu đề `Service-code = NHAN_HO_SO_LLTP`, `messageId = MSG-20261126-0007731`, thân bản tin ký số, kèm chứng thư mTLS.
2. APISIX vùng biên chấm dứt mTLS, đối chiếu vân tay chứng thư với nguồn được phép của điểm cuối, áp giới hạn tần suất và WAF, rồi gắn tenant `T68` của điểm cuối vào tiêu đề nội bộ (tenant không lấy từ nội dung bản tin).
3. Cổng kiểm tra điểm cuối `ACTIVE`, nguồn được phép với dịch vụ, cỡ và định dạng bản tin theo hợp đồng chiều vào.
4. Cổng xác minh chữ ký bản tin theo UC-14-09 bước 9 (chuỗi tin cậy, thu hồi, băm, thời điểm).
5. Cổng kiểm tra `messageId` chưa gặp trong 10 phút ở Valkey và thời điểm ký trong cửa sổ để chống phát lại; ghi giao dịch `INBOUND` ở `RECEIVED`.
6. Cổng tra luồng PH-04 theo ánh xạ và chuyển bản tin đã xác minh qua mesh kèm tenant, `traceparent`, `transactionCode`.
7. Luồng xử lý nghiệp vụ (ghi hồ sơ vào HTTT Sở Tư pháp) và trả kết quả trong `14.inbound.timeout-ms` = 10.000 ms.
8. Cổng dựng phản hồi theo hợp đồng chiều vào, kiểm tra lược đồ, gửi băm tới OpenBao `transit/sign` để ký, trả `200` kèm chữ ký cho NDXP và ghi giao dịch `SUCCEEDED`; hệ thống phát EVT-14-11.

**Luồng thay thế.**

- **5a. Gửi lại cùng `messageId`.** NDXP không nhận được biên nhận nên gửi lại: cổng trả lại kết quả đã có (nếu xong) thay vì xử lý lại.
- **7a. Xử lý lâu.** Dịch vụ cần xử lý lâu: cổng trả ngay `202` kèm biên nhận ký số và gửi kết quả sau qua chiều ra (UC-14-10).
- **7b. Lỗi nghiệp vụ có chủ ý.** Luồng trả "không tìm thấy hồ sơ": cổng chuyển thành lỗi theo định dạng trung ương quy định (mặc định RFC 9457), không phải lỗi hệ thống.
- **4a. Dịch vụ không yêu cầu ký.** Điểm cuối có `signatureRequired = false` (đã có lý do và kiểm toán) thì bước 4 bỏ qua, vẫn giữ mTLS và chống phát lại.

**Luồng ngoại lệ.** Lỗi trả theo định dạng mà trung ương quy định khi có (Q14-06), mặc định RFC 9457; nội dung không tiết lộ cấu hình nội bộ.

- **E1. Chứng thư mTLS không hợp lệ (bước 2).** ERR-14-120 (401); "Chứng thư của nguồn gọi không hợp lệ."
- **E2. Vượt giới hạn tần suất (bước 2).** ERR-14-123 (429); "Quá nhiều yêu cầu, thử lại sau."
- **E3. Nguồn không được phép với dịch vụ (bước 3).** ERR-14-119 (403); "Nguồn gọi không được phép với dịch vụ này."; cảnh báo cho Dũng.
- **E4. Bản tin sai định dạng hoặc thiếu chữ ký (bước 3).** ERR-14-121 (400); "Bản tin không đúng định dạng hoặc thiếu chữ ký."
- **E5. Chữ ký không hợp lệ (bước 4).** ERR-14-109, ERR-14-110 hoặc ERR-14-111; từ chối, mở sự cố chữ ký (UC-14-21), phát EVT-14-06.
- **E6. Bản tin lặp hoặc nghi phát lại (bước 5).** ERR-14-122 (409); "Bản tin đã được nhận trước đó."
- **E7. Luồng PH-04 lỗi, quá hạn hoặc chưa nhận xử lý (bước 7).** ERR-14-124 (502); "Dịch vụ tạm thời chưa nhận xử lý."; nội dung đã che; cảnh báo cho Chi ở UI-14-10.
- **E8. Không ký được phản hồi (bước 8).** ERR-14-112 (503); phản hồi không được trả khi chưa ký (BR-14-001).

**Quy tắc áp dụng.** BR-14-001, 002, 003, 027, 028.

**Màn hình, API.** UI-14-10; API-14-084.
:::

```{.mermaid caption="Trình tự UC-14-27 tiếp nhận yêu cầu chiều vào và trả phản hồi có ký"}
sequenceDiagram
  autonumber
  participant N as NDXP
  participant A as APISIX vùng biên
  participant G as Cổng quốc gia
  participant F as Luồng PH-04
  participant B as OpenBao transit
  N->>A: POST inbound kèm chứng thư mTLS và bản tin ký
  A->>A: Đối chiếu vân tay, WAF, giới hạn tần suất
  A->>G: Chuyển tiếp kèm tenant của điểm cuối
  G->>G: Kiểm tra nguồn, định dạng, chữ ký, chống phát lại
  G->>F: Chuyển bản tin đã xác minh
  F-->>G: Kết quả nghiệp vụ
  G->>B: Gửi băm phản hồi cần ký
  B-->>G: Chữ ký
  G-->>N: 200 phản hồi có chữ ký
```

Hình cho thấy mọi kiểm tra nặng diễn ra trước khi bản tin chạm luồng PH-04: APISIX chặn ở biên bằng mTLS, WAF và giới hạn tần suất, cổng xác minh nguồn, chữ ký và chống phát lại; phản hồi của tỉnh cũng được ký bằng khóa ở OpenBao.

### 6.28. UC-14-28 · Tiếp nhận thông báo thay đổi từ quốc gia

::: dac-ta
**Mục tiêu.** Khi danh mục, dữ liệu hoặc đặc tả dịch vụ ở quốc gia thay đổi, nền tảng đẩy thông báo để tỉnh vô hiệu đệm ngay, báo PH-07 kéo danh mục sớm và báo kỹ sư tích hợp khi dịch vụ đổi đặc tả.

**Tác nhân chính.** NDXP (hệ thống ngoài).

**Tác nhân phụ.** Cổng quốc gia; PH-07 (nhận EVT-14-17); ROLE-INTEGRATION_ENGINEER (An) nhận cảnh báo; Valkey.

**Mức ưu tiên.** S, Đợt 2.

**FR hiện thực.** FR-14-042 (nền: FR-14-036).

**Truy vết.** REQ-14, REQ-07; BP-03, BP-06; LGC-DMDC-019 (đồng bộ danh mục).

**Tiền điều kiện.** Điểm cuối `ndxp-vao-t68` `ACTIVE` có dịch vụ chiều vào loại `NOTIFICATION`; nguồn `NDXP-QG` được phép.

**Kích hoạt.** NDXP gọi `POST /inbound/v1/ndxp-vao-t68/notifications`.

**Đảm bảo tối thiểu.** Cùng bộ kiểm tra như UC-14-27 trước khi làm bất cứ việc gì; thông báo về đối tượng không có trong hệ thống không gây lỗi.

**Đảm bảo thành công.** Đệm không phục vụ dữ liệu đã đổi; PH-07 đồng bộ sớm; An biết dịch vụ đổi đặc tả ngay; NDXP nhận biên nhận `202`.

**Luồng chính.**

1. NDXP gọi điểm cuối thông báo với `notificationType = CATALOG_CHANGED`, `objectCodes = ["DM_DANTOC"]`, `effectiveAt`, `messageId`.
2. Cổng xử lý như UC-14-27 bước 2 đến 5 (xác thực mTLS, kiểm tra nguồn, chữ ký, chống phát lại).
3. Cổng kiểm tra `notificationType` thuộc tập cho phép (`CATALOG_CHANGED`, `DATA_CHANGED`, `SERVICE_CHANGED`).
4. Với `CATALOG_CHANGED`, cổng phát EVT-14-17 để PH-07 kéo ngay danh mục `DM_DANTOC` (UC-14-15).
5. Cổng trả biên nhận `202` và ghi giao dịch.
6. Một thông báo khác `DATA_CHANGED` với `objectCodes = ["0101234567"]`: cổng vô hiệu các khóa đệm của dịch vụ doanh nghiệp liên quan (UC-14-24), phát EVT-14-09.
7. Một thông báo `SERVICE_CHANGED` với `objectCodes = ["LLTP_TRA_TRANG_THAI"]`: cổng đặt nhãn đề xuất `SPEC_CHANGED` cho dịch vụ khớp và tạo cảnh báo cho An để nạp đặc tả mới (UC-14-05, UC-14-06).

**Luồng thay thế.**

- **4a. Đối tượng không có trong hệ thống.** Thông báo nêu mã không có: cổng vẫn trả `202`, ghi `ignored = true` vào giao dịch.
- **6a. Thông báo không nêu đối tượng.** Hệ thống vô hiệu cả dịch vụ thay vì một khóa.

**Luồng ngoại lệ.**

- **E1. Loại thông báo sai hoặc thiếu trường (bước 3).** ERR-14-121 (400); "Thông báo không đúng định dạng."
- **E2. Lỗi xác thực hoặc nguồn (bước 2).** ERR-14-120 (401), ERR-14-119 (403), ERR-14-122 (409), ERR-14-123 (429) như UC-14-27 E1 đến E6.
- **E3. Chữ ký không hợp lệ (bước 2).** ERR-14-109 (502) và mở sự cố chữ ký (UC-14-21).

**Quy tắc áp dụng.** BR-14-024, 027, 028.

**Màn hình, API.** UI-14-10; API-14-085.
:::

### 6.29. UC-14-29 · Đồng bộ danh mục dịch vụ lên Bộ

::: dac-ta
**Mục tiêu.** Tự động thực hiện nghĩa vụ đăng ký các dịch vụ chia sẻ dữ liệu đã phát hành của tỉnh lên hệ thống của Bộ, để nghĩa vụ này không phụ thuộc việc ai đó nhớ làm thủ công, có biên nhận để chứng minh, và thấy ngay khi không đồng bộ được quá lâu.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); bộ đồng bộ theo lịch.

**Tác nhân phụ.** PH-02 (nguồn danh mục, scope `national.sync.trigger`); cổng quốc gia; hệ thống đăng ký của Bộ (nền tảng loại `REGISTRY`); ROLE-TENANT_ADMIN (Lan); ROLE-SECURITY_OFFICER (Dũng) nhận cảnh báo tuân thủ.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-043, 046.

**Truy vết.** REQ-14, REQ-02, REQ-13; BP-03, BP-06; không có ở hệ cũ.

**Tiền điều kiện.** Nền tảng loại `REGISTRY` tên `dkdv-bo` `ACTIVE`; định dạng đăng ký của hệ thống nhận đã cấu hình (Q14-05); Chi có `PERM-14-sync`.

**Kích hoạt.** Lịch `14.sync.catalog-cron` lúc 02:00 hằng ngày; hoặc PH-02 báo có dịch vụ chia sẻ mới `PUBLISHED`; hoặc Chi bấm "Đồng bộ ngay" ở UI-14-11.

**Đảm bảo tối thiểu.** Chỉ dịch vụ chia sẻ đã `PUBLISHED` của đúng tenant được gửi, API nội bộ không bao giờ gửi; một bản ghi lỗi không chặn các bản ghi khác; gửi lại không tạo bản ghi trùng.

**Đảm bảo thành công.** Phiên `sync_run` ghi đủ `sent`, `accepted`, `rejected`, `pending`; thời điểm đồng bộ thành công gần nhất cập nhật.

**Luồng chính.**

1. Lúc 02:00 bộ đồng bộ tạo phiên `SERVICE_CATALOG` với `trigger = SCHEDULE`, `onlyChanged = true`, lấy từ PH-02 danh sách dịch vụ chia sẻ `PUBLISHED` của `T68` (14 dịch vụ).
2. Bộ đồng bộ so với lần thành công trước bằng băm mô tả, chọn 3 dịch vụ mới hoặc đã đổi.
3. Bộ đồng bộ chuyển từng dịch vụ sang định dạng của hệ thống nhận và kiểm tra theo lược đồ (không đạt thì bản ghi đó `REJECTED_LOCAL`, các bản khác vẫn đi tiếp).
4. Bộ đồng bộ gửi qua cổng bằng đường ghi có chống trùng theo (mã dịch vụ, phiên bản), ký số nếu nền tảng yêu cầu.
5. Hệ thống của Bộ trả biên nhận từng dịch vụ: 2 `ACCEPTED`, 1 `REJECTED` kèm lý do "thiếu đơn vị cung cấp"; bộ đồng bộ đối soát số gửi (3) bằng tổng ba loại.
6. Bộ đồng bộ ghi `sync_run`, phát EVT-14-12 (PH-02, PH-13 nhận) và cập nhật thời điểm đồng bộ thành công.
7. Chi mở UI-14-11 (API-14-053, 055) lúc 08:10, thấy phiên `SUCCEEDED` kèm 1 bản ghi bị từ chối; chi tiết từng bản ghi hiện lý do đã che.
8. Chi nhờ chủ dịch vụ bổ sung "đơn vị cung cấp" ở PH-02, rồi chọn bản ghi lỗi và bấm "Thử lại" (API-14-057). Hệ thống tạo phiên con liên kết phiên gốc, gửi lại và nhận `ACCEPTED`.

**Luồng thay thế.**

- **1a. Chạy thử.** `dryRun = true` chỉ trả danh sách sẽ gửi và các lỗi kiểm tra cục bộ (API-14-054).
- **4a. Hệ thống Bộ không hỗ trợ lô.** Bộ đồng bộ gửi từng dịch vụ với nhịp `14.sync.rate-per-minute` = 60.
- **8a. Ghi nhận không gửi lại.** Chi ghi nhận bản ghi bị từ chối kèm ghi chú xử lý để đóng việc.
- **7a. Xuất báo cáo lệch.** Chi xuất CSV báo cáo lệch và xem số ngày kể từ lần đồng bộ thành công gần nhất.
- **1b. Đồng bộ toàn bộ.** `onlyChanged = false` gửi toàn bộ 14 dịch vụ.

**Luồng ngoại lệ.**

- **E1. Hệ thống của Bộ không khả dụng (bước 4).** Phiên `FAILED`, thử lại với độ trễ tăng dần trong 24 giờ; khi Chi chạy tay: ERR-14-103 (503); "Hệ thống đăng ký của Bộ chưa phản hồi. Hệ thống sẽ thử lại tự động."
- **E2. Quá 7 ngày không đồng bộ thành công (BR-14-026).** Cảnh báo tuân thủ cho Lan, Dũng và lãnh đạo; "Đã 7 ngày chưa đăng ký được danh mục dịch vụ lên hệ thống của Bộ."
- **E3. Bộ từ chối một dịch vụ (bước 5).** ERR-14-028 (422); "Hệ thống của Bộ từ chối dịch vụ dv-tra-cuu-ho-tich: thiếu đơn vị cung cấp."; thông báo chủ dịch vụ ở PH-02.
- **E4. PH-02 không khả dụng (bước 1).** ERR-14-027 (502); "Danh mục dịch vụ chưa phản hồi. Thử lại sau ít phút."
- **E5. Đã có phiên đang chạy (bước 1 hoặc 8).** ERR-14-026 (409); "Đang có một phiên đồng bộ danh mục dịch vụ. Chờ phiên đó xong."
- **E6. Quá số lần thử lại (bước 8).** ERR-14-004 (409); "Bản ghi đã thử lại tối đa 5 lần. Xử lý thủ công hoặc ghi nhận."

**Quy tắc áp dụng.** BR-14-026, 030, 035.

**Màn hình, API.** UI-14-11; API-14-053, 054, 055, 057.
:::

```{.mermaid caption="Trình tự UC-14-29 đồng bộ danh mục dịch vụ lên hệ thống của Bộ"}
sequenceDiagram
  autonumber
  participant L as Lịch hoặc sự kiện PH-02
  participant S as Bộ đồng bộ PH-14
  participant P as PH-02
  participant G as Cổng quốc gia
  participant R as Hệ thống đăng ký của Bộ
  L->>S: Kích hoạt phiên đồng bộ
  S->>P: Lấy dịch vụ chia sẻ PUBLISHED
  P-->>S: Danh sách dịch vụ
  S->>S: Chọn dịch vụ mới hoặc đổi, chuyển định dạng, kiểm tra
  S->>G: Gửi qua đường ghi có chống trùng
  G->>R: Đăng ký dịch vụ, ký nếu yêu cầu
  R-->>G: Biên nhận từng dịch vụ
  G-->>S: ACCEPTED, REJECTED, PENDING
  S->>S: Đối soát, ghi phiên, phát EVT-14-12
```

Hình cho thấy bộ đồng bộ chỉ gửi phần thay đổi của các dịch vụ chia sẻ đã phát hành, nhận biên nhận từng dịch vụ và đối soát số gửi với số chấp nhận, từ chối và chờ trước khi ghi phiên và phát sự kiện.

### 6.30. UC-14-30 · Cầu nối đồng bộ dữ liệu chủ hai chiều

::: dac-ta
**Mục tiêu.** PH-06 đồng bộ dữ liệu chủ hai chiều với CSDL tổng hợp quốc gia qua một cầu nối duy nhất, bảo đảm không gửi lô chưa ánh xạ hoặc chưa qua kiểm tra bảo vệ dữ liệu.

**Tác nhân chính.** PH-06 (scope `national.sync.trigger`).

**Tác nhân phụ.** ROLE-TENANT_OPERATOR (Chi); PH-07 (ánh xạ ngữ nghĩa); PH-09 (kiểm tra trường); cổng quốc gia; CSDL tổng hợp quốc gia.

**Mức ưu tiên.** S, Đợt 3.

**FR hiện thực.** FR-14-044 (nền: FR-14-046).

**Truy vết.** REQ-14, REQ-06; BP-06; không có ở hệ cũ (SRS cũ FR-14-013).

**Tiền điều kiện.** PH-06 đã đưa vào dùng; ánh xạ ngữ nghĩa ở PH-07 đủ cho tập trường cần gửi; PH-09 đã phân loại trường; phạm vi gửi lên đã chốt (Q14-13).

**Kích hoạt.** PH-06 gọi API-14-056 theo lịch hoặc theo thay đổi; hoặc nền tảng quốc gia thông báo cập nhật (UC-14-28).

**Đảm bảo tối thiểu.** Không lô nào gửi đi khi thiếu ánh xạ hoặc bị PH-09 chặn; gửi lại không tạo bản ghi trùng.

**Đảm bảo thành công.** Phiên `MASTER_DATA` ghi đối soát từng bản ghi; bản ghi lệch được báo cho PH-06.

**Luồng chính.**

1. PH-06 gọi API-14-056 với `direction = UP`, `entity = ORGANIZATION`, `batchRef = PH06-20261126-004` (lô 420 bản ghi).
2. Bộ đồng bộ nhận lô và kiểm tra mọi trường đã có ánh xạ ở PH-07.
3. Bộ đồng bộ gọi PH-09 kiểm tra lô không chứa trường bị cấm gửi ra ngoài tỉnh.
4. Bộ đồng bộ ký và gửi lô qua đường ghi có chống trùng theo `batchRef`.
5. CSDL tổng hợp trả kết quả; bộ đồng bộ đối soát từng bản ghi (415 nhận, 5 lệch) và báo bản ghi lệch cho PH-06 qua EVT-14-12 kèm tham chiếu lô.
6. Bộ đồng bộ ghi `sync_run` với `kind = MASTER_DATA`; Chi xem ở UI-14-11.
7. Chiều xuống (`direction = DOWN`): bộ đồng bộ kéo cập nhật từ CSDL tổng hợp qua cổng, xác minh chữ ký và chuyển lô cho PH-06.

**Luồng thay thế.**

- **5a. Gửi lại bản ghi lệch.** Sau khi PH-06 sửa, lô gửi lại mang `batchRef` mới liên kết tới lô gốc.
- **7a. Kích hoạt từ thông báo.** NDXP báo có cập nhật (`DATA_CHANGED`): PH-06 được báo và gọi chiều xuống sớm.

**Luồng ngoại lệ.**

- **E1. Thiếu ánh xạ ở PH-07 (bước 2).** ERR-14-125 (422); "Lô dữ liệu chủ có trường chưa ánh xạ sang từ điển quốc gia: taxCode. Bổ sung ánh xạ ở phân hệ Danh mục dùng chung."
- **E2. PH-09 chặn (bước 3).** ERR-14-126 (403); "Lô dữ liệu chủ chứa trường không được gửi ra ngoài tỉnh: soCCCD."
- **E3. CSDL tổng hợp không khả dụng (bước 4).** ERR-14-103 (503); lô được giữ trong hàng chờ.
- **E4. PH-06, PH-07 hoặc PH-09 không khả dụng.** ERR-14-027 (502); "Phân hệ liên quan chưa phản hồi. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-14-009, 010, 030.

**Màn hình, API.** UI-14-11; API-14-056.
:::

### 6.31. UC-14-31 · Công bố dữ liệu mở lên NDOP

::: dac-ta
**Mục tiêu.** Tỉnh công bố các tập dữ liệu mở (công khai, không chứa dữ liệu cá nhân) lên Nền tảng dữ liệu mở quốc gia theo lô và theo lịch, kèm siêu dữ liệu, thay cho việc đăng thủ công.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan, đề nghị); ROLE-INTEGRATION_APPROVER (Bình, duyệt lần công bố đầu).

**Tác nhân phụ.** PH-07 (nguồn danh mục công khai); PH-09 (kiểm tra trường); cổng quốc gia; NDOP.

**Mức ưu tiên.** S, Đợt 3.

**FR hiện thực.** FR-14-045 (nền: FR-14-046).

**Truy vết.** REQ-14, REQ-09; BP-06; không có ở hệ cũ.

**Tiền điều kiện.** Nền tảng `ndop-t68` loại `NDOP` `ACTIVE` (đang `specStatus = PROVISIONAL`); danh mục `DM_DVHC` ở mức `PUBLIC` tại PH-07; Lan có `PERM-14-sync`, Bình có `PERM-14-approve`.

**Kích hoạt.** Lan bấm "+ Tập dữ liệu mở" ở UI-14-11; hoặc lịch cập nhật của tập đã duyệt.

**Đảm bảo tối thiểu.** Không trường dữ liệu cá nhân hay mức Hạn chế trở lên nào được công bố; tập chưa duyệt lần đầu không được gửi.

**Đảm bảo thành công.** Tập `dvhc-t68` được công bố và cập nhật theo lịch; phiên `OPEN_DATA` có biên nhận.

**Luồng chính.**

1. Lan chọn nguồn `CATALOG` mã `DM_DVHC`, nhập `datasetCode = dvhc-t68`, tiêu đề "Đơn vị hành chính tỉnh T68", `license = CC-BY`, `updateFrequency = MONTHLY`, `format = CSV`.
2. Hệ thống gọi API-14-087; PH-09 xác nhận nguồn không chứa trường dữ liệu cá nhân hay trường mức Hạn chế trở lên.
3. Hệ thống kiểm tra siêu dữ liệu đủ trường theo đặc tả NDOP đang dùng và hiện nhãn "đặc tả tạm thời" vì `PROVISIONAL`.
4. Vì là lần công bố đầu, hệ thống tạo việc duyệt cho Bình (LP-14-01); Bình duyệt.
5. Bộ đồng bộ chuyển tập sang CSV, gửi theo lô qua cổng với chống trùng theo (mã tập, phiên bản).
6. NDOP trả biên nhận; hệ thống ghi `sync_run` với `kind = OPEN_DATA`, lên lịch lần cập nhật tiếp theo (đầu tháng sau) và phát EVT-14-12.
7. Lan theo dõi phiên ở UI-14-11 (API-14-053, 055, 057) và thử lại nếu có bản ghi lỗi như UC-14-29.

**Luồng thay thế.**

- **1a. Nguồn là tệp.** `sourceKind = FILE` với tệp đã qua kiểm tra mã độc.
- **7a. Gỡ công bố.** Lan gọi API-14-088 kèm lý do; hệ thống gửi yêu cầu gỡ, tập chuyển `WITHDRAWN` và không còn theo lịch.
- **4a. Lần cập nhật sau.** Các lần cập nhật theo lịch của tập đã duyệt không cần duyệt lại.

**Luồng ngoại lệ.**

- **E1. Nguồn có trường bị cấm (bước 2).** ERR-14-126 (403); "Nguồn chứa trường không được công bố: soDienThoai. Loại trường đó khỏi tập dữ liệu mở."
- **E2. NDOP từ chối (bước 6).** ERR-14-028 (422); "Nền tảng dữ liệu mở từ chối tập dvhc-t68: thiếu trường giấy phép."
- **E3. NDOP không khả dụng (bước 5).** ERR-14-103 (503); lô thử lại theo lịch.
- **E4. Người duyệt trùng người đề nghị (bước 4).** ERR-14-007 (403); "Bạn không thể tự duyệt yêu cầu do mình đề nghị hoặc sửa gần nhất. Nhờ người khác duyệt."
- **E5. PH-07 hoặc PH-09 không khả dụng (bước 2).** ERR-14-027 (502); "Phân hệ liên quan chưa phản hồi. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-14-009, 010, 022, 025.

**Màn hình, API.** UI-14-11; API-14-087, 088, 053, 055, 057.
:::

**Nhóm 6 · Giám sát, đối soát, quản trị và chuyển đổi (UC-14-32…38).** Cả tỉnh dùng chung một tài khoản khai thác tại NDXP nên PH-14 là điểm kiểm soát mục đích: mỗi lượt gọi có HTTT, mục đích và mã hồ sơ, 100% có nhật ký (KPI-07). Nhóm này cho vận hành thấy tình trạng kết nối, cho Cán bộ ATTT và kiểm toán viên tra bằng chứng mà không lộ nội dung cá nhân, và cho quản trị tenant điều chỉnh tham số, chạy song song và cắt chuyển khỏi kết nối NGSP cũ theo mô hình thay dần (BP-09).

### 6.32. UC-14-32 · Theo dõi tổng quan và kiểm tra kết nối chủ động

::: dac-ta
**Mục tiêu.** Phát hiện sớm khi một nền tảng quốc gia mất kết nối hoặc suy giảm (không quá 3 phút) trước khi người dân gặp lỗi, và cho vận hành, Cán bộ ATTT, lãnh đạo thấy ở một màn hình tình trạng kết nối: nền tảng nào khỏe, hạn mức sắp cạn lúc nào, chứng thư nào sắp hết hạn, có sự cố chữ ký không.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi).

**Tác nhân phụ.** Bộ chạy kiểm tra; ROLE-TENANT_ADMIN (Lan) nhận cảnh báo; PH-13 (kho chỉ số); NDXP; mọi vai trò có `PERM-14-read` xem.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-047, 048.

**Truy vết.** REQ-14, REQ-13; BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Nền tảng `ndxp-t68` ở trạng thái từ `DRAFT` trở đi, địa chỉ trong egress; Chi đã chọn tenant `T68`.

**Kích hoạt.** Bộ chạy kiểm tra mỗi `14.health.interval-seconds` = 60 giây ở môi trường thật; Chi mở UI-14-01 (tự làm mới mỗi 30 giây); hoặc Chi bấm "Kiểm tra kết nối" ở UI-14-02.

**Đảm bảo tối thiểu.** Kiểm tra không ghi bí mật, không đổi dữ liệu cấu hình; kho chỉ số lỗi không làm hỏng màn tổng quan.

**Đảm bảo thành công.** Mức sức khỏe đúng với tình trạng thật; gián đoạn có thời gian bắt đầu và kết thúc; Chi thấy ngay việc cần làm trước.

**Luồng chính.**

1. Bộ chạy kiểm tra phân giải tên miền, mở TCP, bắt tay TLS, lấy token (UC-14-16) cho `ndxp-t68`; mỗi bước ghi kết quả và thời gian.
2. Bộ chạy kiểm tra kết hợp kết quả chủ động với tỷ lệ lỗi và độ trễ thật của 5 phút gần nhất (đánh giá thụ động) để xếp mức: `HEALTHY` khi mọi bước đạt và tỷ lệ lỗi dưới 5%; `DEGRADED` khi p95 gấp đôi đường chuẩn hoặc lỗi từ 5% đến dưới 50%; `UNHEALTHY` khi hai chu kỳ liên tiếp thất bại ở TCP, TLS hoặc token hoặc lỗi từ 50%.
3. Lúc 09:14 hai chu kỳ liên tiếp lấy token thất bại: mức đổi sang `UNHEALTHY`, hệ thống phát EVT-14-15, đặt chỉ số `national_connectivity_status`, cập nhật thẻ ở UI-14-01, 02 và bộ ngắt mạch mở theo UC-14-25.
4. Quá 5 phút `UNHEALTHY` (09:19), hệ thống phát cảnh báo mức cao cho Chi và Lan; nếu `14.health.notify-platform-contact = true` thì gửi thông báo tới đầu mối kỹ thuật của nền tảng.
5. Chi mở UI-14-01 (API-14-060): ba thẻ (NDXP `UNHEALTHY`, NDOP `HEALTHY` kèm nhãn "đặc tả tạm thời", hệ thống đăng ký của Bộ vừa đồng bộ lúc 02:00); hàng chỉ số 24 giờ: 41.200 lượt gọi, 98,6% thành công, p95 640 ms, 64% trúng đệm, 3 lượt phục vụ dữ liệu cũ.
6. Bảng hạn mức: `bhxh-tra-ho-gia-dinh` đã dùng 18.600 trên 20.000 (93%), dự báo cạn lúc 21:40; hai biểu ngữ vàng: chứng thư còn 24 ngày và hạn mức BHXH; nếu có sự cố chữ ký chưa xác nhận thì biểu ngữ đỏ nằm trên cùng.
7. Chi bấm thẻ NDXP để mở UI-14-02, bấm "Kiểm tra kết nối" (API-14-059) và đọc kết quả từng bước kèm gợi ý khắc phục. Lúc 09:31 token lấy được; mức về `HEALTHY`, hệ thống ghi thời gian gián đoạn (09:14 đến 09:31) phục vụ báo cáo chất lượng.

**Luồng thay thế.**

- **5a. Chọn khoảng thời gian khác.** Chi đổi khoảng và lọc theo nền tảng.
- **5b. Kho chỉ số không khả dụng.** Màn hiển thị phần đọc từ PostgreSQL (hạn mức, chứng thư, sự cố) kèm ghi chú "Số liệu lưu lượng tạm thời chưa có".
- **1a. Kiểm tra sâu.** `deep = true` gọi thêm một thao tác nhẹ `healthOperation` ở ưu tiên `BACKGROUND`, có tính hạn mức.
- **7a. Địa chỉ ngoài egress.** Kết quả `EGRESS_DENIED` kèm lối tắt tạo đề nghị bổ sung egress.
- **6a. Lọc nhanh.** Chi bấm thẻ "Mất kết nối" để danh sách nền tảng lọc `health = UNHEALTHY`.

**Luồng ngoại lệ.**

- **E1. Vượt số lần kiểm tra tay mỗi giờ (bước 7).** ERR-14-029 (429); "Đã kiểm tra quá 20 lần trong một giờ. Thử lại sau 12 phút."
- **E2. Địa chỉ ngoài danh sách egress (bước 7).** Kết quả `EGRESS_DENIED`, không phải lỗi HTTP; "Địa chỉ chưa được phép đi ra ngoài. Đề nghị quản trị tỉnh bổ sung vào danh sách đích."
- **E3. Bộ chạy kiểm tra không khả dụng.** Giao diện hiển thị "Chưa có dữ liệu kiểm tra", mức `UNKNOWN`.
- **E4. Kho chỉ số không phản hồi (bước 5).** Không có mã lỗi riêng; vùng biểu đồ hiển thị "Chưa lấy được số liệu lưu lượng. Thử lại sau."

**Quy tắc áp dụng.** BR-14-003, 006, 029, 031.

**Màn hình, API.** UI-14-01, 02; API-14-058, 059, 060.
:::

### 6.33. UC-14-33 · Tra cứu, đối soát giao dịch và xuất bằng chứng

::: dac-ta
**Mục tiêu.** Tra được một giao dịch quốc gia theo mã giao dịch, mã truy vết hoặc mã hồ sơ để biết nó đã đi thế nào, và có gói bằng chứng có chữ ký khi trung ương hay HTTT khiếu nại ("chúng tôi không nhận được yêu cầu"), mà không lộ nội dung cá nhân.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); ROLE-AUDITOR (Mai); ROLE-SECURITY_OFFICER (Dũng, xuất bằng chứng).

**Tác nhân phụ.** OpenBao (ký gói); PH-13 (vết `traceId`); kho lưu trữ WORM.

**Mức ưu tiên.** M (tra cứu, đối soát), S, Đợt 2 (xuất bằng chứng).

**FR hiện thực.** FR-14-049, 051.

**Truy vết.** REQ-14, REQ-13; BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Chi, Mai, Dũng có `PERM-14-audit-read`; Dũng có thêm `PERM-14-audit-reveal`; có giao dịch trong khoảng tra.

**Kích hoạt.** Chi nhận khiếu nại từ `HT-TUPHAP` rằng hồ sơ hộ tịch chưa có phản hồi, mở UI-14-12 và nhập mã vào ô tra nhanh.

**Đảm bảo tối thiểu.** Nội dung bản tin luôn ở dạng đã che; giao dịch của tenant khác trả như không tồn tại; mỗi gói bằng chứng có chữ ký và đóng dấu thời gian.

**Đảm bảo thành công.** Người tra thấy dòng thời gian đầy đủ của giao dịch; gói bằng chứng JSON và PDF có hạn tải 24 giờ.

**Luồng chính.**

1. Chi nhập `caseCode = HS-2026-11-004512` vào ô tra nhanh. Hệ thống gọi API-14-061, kiểm tra quyền và khoảng thời gian (tối đa 92 ngày) rồi trả các giao dịch của tenant khớp mã.
2. Chi chọn giao dịch `T68-20261126-0000184320`. Hệ thống gọi API-14-062 và hiện chi tiết: dòng thời gian từng bước (mục đích, đệm, hạn mức, ký, gửi, xác minh), kết quả xác minh chữ ký và chứng thư đã dùng, mã hồ sơ, `traceId` kèm liên kết tới vết ở PH-13, nội dung bản tin dạng đã che.
3. Chi thấy giao dịch ở trạng thái `SUCCEEDED`, nguồn gọi thật, `durationMs = 412`; một giao dịch khác của cùng hồ sơ tô đỏ vì lỗi chữ ký, kèm nguyên nhân và liên kết tới sự cố (UC-14-21).
4. Chi xuất danh sách theo bộ lọc hiện tại (tuân thủ FR-00-030).
5. Dũng chọn hai giao dịch, bấm "Xuất bằng chứng" và nhập lý do "Đối soát khiếu nại HT-TUPHAP ngày 26/11". Hệ thống gọi API-14-064, kiểm tra không quá 100 giao dịch.
6. Hệ thống dựng gói: mỗi giao dịch có mã, thời điểm, dịch vụ, chiều, trạng thái, băm bản tin gửi và nhận, kết quả xác minh, số sê-ri chứng thư, `traceId`; ký gói bằng khóa `transit` riêng của tenant cho mục đích bằng chứng, đóng dấu thời gian.
7. Hệ thống tạo tệp JSON và PDF, ghi kiểm toán và trả liên kết tải hết hạn sau 24 giờ; gói lớn chạy nền và thông báo khi xong (tuân thủ FR-00-054).
8. Mai (kiểm toán viên) nhận gói do Dũng chuyển và kiểm chứng chữ ký, băm; không cần nhìn nội dung cá nhân.

**Luồng thay thế.**

- **1a. Giao dịch cũ hơn 12 tháng.** Hệ thống truy xuất từ kho lưu trữ bằng yêu cầu chạy nền; chỉ siêu dữ liệu 5 năm được giữ ngoài bảng nóng.
- **5a. Cần cả nội dung.** `includePayload = true`: hệ thống áp quy trình UC-14-34 (xác thực lại, lý do, vết) trước khi đưa nội dung vào gói.
- **5b. Gói chỉ gồm giao dịch lỗi chữ ký.** Dùng làm hồ sơ gửi cơ quan chuyên trách khi báo sự cố (SEC-74).
- **2a. Tra theo mã truy vết.** `traceId` hoặc `transactionCode` trả đúng một bản ghi.

**Luồng ngoại lệ.**

- **E1. Không tìm thấy giao dịch hoặc thuộc tenant khác (bước 2).** ERR-14-001 (404); "Không tìm thấy giao dịch T68-20261126-0000184320."
- **E2. Khoảng thời gian quá rộng (bước 1).** ERR-14-003 (400); "Khoảng thời gian tra tối đa 92 ngày."
- **E3. Quá 100 giao dịch (bước 5).** ERR-14-003 (400); "Mỗi lần xuất tối đa 100 giao dịch."
- **E4. Không ký được gói (bước 6).** ERR-14-035 (503); "Kho bí mật tạm thời không khả dụng nên chưa ký được gói bằng chứng."
- **E5. Thiếu lý do xuất (bước 5).** ERR-14-003 (400); "Giá trị lý do không hợp lệ: cần từ 10 đến 500 ký tự."

**Quy tắc áp dụng.** BR-14-020, 021, 029.

**Màn hình, API.** UI-14-12; API-14-061, 062, 064.
:::

### 6.34. UC-14-34 · Xem nội dung bản tin đầy đủ có lý do

::: dac-ta
**Mục tiêu.** Cán bộ ATTT xem được nội dung đầy đủ của bản tin gửi và nhận khi thật sự cần (điều tra sự cố, giải quyết khiếu nại), với lý do, xác thực lại và vết đầy đủ, vì nội dung có thể chứa dữ liệu cá nhân.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng, `PERM-14-audit-reveal`).

**Tác nhân phụ.** OpenBao `transit` (giải mã bằng khóa tenant); PH-12 (xác thực nhiều yếu tố); ROLE-TENANT_ADMIN (Lan) nhận thông báo; PH-13 (SIEM).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-14-050.

**Truy vết.** REQ-14, REQ-13, REQ-09; BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Giao dịch còn nội dung lưu trong `14.txn.payload-retention-days` (mặc định 30 ngày, tenant có thể đặt 0 là không lưu); Dũng đã xác thực nhiều yếu tố trong phiên.

**Kích hoạt.** Dũng bấm "Xem nội dung đầy đủ" ở chi tiết giao dịch (UI-14-12).

**Đảm bảo tối thiểu.** Nội dung chỉ hiển thị cho người có quyền riêng, một lần, trong 60 giây, kèm hình mờ có tên người xem; mỗi lần xem có kiểm toán ngay lúc hiển thị.

**Đảm bảo thành công.** Dũng xem được nội dung; kiểm toán ghi người, giao dịch, lý do, mã phiếu, thời điểm, trường đã xem; Lan được thông báo.

**Luồng chính.**

1. Dũng mở giao dịch `T68-20261126-0000184320`, bấm "Xem nội dung đầy đủ", nhập lý do "Điều tra khiếu nại hồ sơ HS-2026-11-004512" và mã phiếu hỗ trợ `HT-2026-1187`.
2. Hệ thống yêu cầu xác thực lại nhiều yếu tố (step-up, LP-14-03); Dũng xác thực đạt.
3. Hệ thống kiểm tra nội dung còn trong thời hạn lưu (giao dịch 6 ngày trước, còn 24 ngày).
4. Hệ thống gọi API-14-063, giải mã nội dung bằng khóa của tenant ở OpenBao `transit` và hiển thị trong 60 giây kèm hình mờ "Dũng, 26/11/2026 10:05", sau đó che lại.
5. Hệ thống ghi kiểm toán ngay lúc hiển thị (người, giao dịch, lý do, mã phiếu, thời điểm, trường đã xem) và gửi thông báo cho Lan.
6. Hệ thống đếm số lần xem đầy đủ mỗi người mỗi ngày; nếu vượt `14.reveal.max-per-day` = 20 thì phát EVT-14-16 cảnh báo cho SO trưởng.

**Luồng thay thế.**

- **1a. Chỉ cần chứng minh sự tồn tại.** Dũng dùng UC-14-33 (xuất bằng chứng chỉ có băm) thay vì xem nội dung.
- **4a. Hết 60 giây.** Nội dung bị che lại; muốn xem tiếp phải bấm lại, nhập lại lý do và bị đếm thêm một lần.
- **3a. Tenant tắt lưu nội dung.** Với `14.txn.payload-retention-days = 0`, nút "Xem nội dung đầy đủ" vô hiệu kèm giải thích; chỉ còn băm và siêu dữ liệu.

**Luồng ngoại lệ.**

- **E1. Chưa xác thực lại (bước 2).** ERR-14-030 (403); "Cần xác thực lại bằng yếu tố thứ hai để xem nội dung đầy đủ."
- **E2. Nội dung quá hạn lưu hoặc không được lưu (bước 3).** ERR-14-031 (404); "Nội dung bản tin đã quá thời hạn lưu hoặc tỉnh không bật lưu nội dung."
- **E3. Thiếu lý do (bước 1).** ERR-14-003 (400); "Nhập lý do xem nội dung đầy đủ (từ 10 ký tự)."
- **E4. Người không có `PERM-14-audit-reveal` (bước 1).** Lỗi 403 theo FR-00; nút không hiện ở giao diện.
- **E5. OpenBao không khả dụng (bước 4).** ERR-14-035 (503); "Kho bí mật tạm thời không khả dụng. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-14-021.

**Màn hình, API.** UI-14-12; API-14-063.
:::

### 6.35. UC-14-35 · Nhật ký khai thác và cảnh báo bất thường

::: dac-ta
**Mục tiêu.** Trả lời được "HTTT nào đã khai thác dịch vụ quốc gia nào, bao nhiêu lượt, vì mục đích gì, cho hồ sơ nào, khi nào" cho thanh tra (KPI-07), và phát hiện trong 15 phút HTTT tra cứu bất thường để xử lý có hồ sơ, vì cả tỉnh dùng chung một tài khoản và rủi ro lạm dụng nằm ở đây (THR-51).

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-AUDITOR (Mai).

**Tác nhân phụ.** Bộ phân tích (chạy mỗi 15 phút); ROLE-TENANT_ADMIN (Lan); PH-02 (thu hồi quyền gọi); PH-13 (SIEM).

**Mức ưu tiên.** M (nhật ký, báo cáo), S, Đợt 2 (cảnh báo bất thường).

**FR hiện thực.** FR-14-052, 053.

**Truy vết.** REQ-14, REQ-13, REQ-09; BP-07; không có ở hệ cũ.

**Tiền điều kiện.** Có giao dịch trong khoảng báo cáo; cảnh báo cần có `usage_hourly` ít nhất 7 ngày để có đường chuẩn; Dũng có `PERM-14-audit-read` và `PERM-14-operate`.

**Kích hoạt.** Mai mở UI-14-13 và chọn khoảng thời gian; bộ phân tích chạy mỗi 15 phút.

**Đảm bảo tối thiểu.** Nhật ký thường không chứa nội dung bản tin hay dữ liệu cá nhân; mỗi cảnh báo đã mở phải có quyết định kèm lý do mới kết thúc.

**Đảm bảo thành công.** 100% lượt khai thác có nhật ký đủ thông tin cho thanh tra; cảnh báo bất thường được phát hiện trong 15 phút và xử lý có hồ sơ.

**Luồng chính.**

1. Mai mở UI-14-13, chọn tháng 11/2026, `groupBy = SYSTEM`. Hệ thống gọi API-14-065, kiểm tra khoảng không quá 92 ngày và đọc bảng `usage_hourly`.
2. Hệ thống hiện bảng và biểu đồ: số lượt, số lượt từ đệm, tỷ lệ lỗi, tổng số bản ghi trả về, mức dùng hạn mức, xếp hạng HTTT (`HT-MOTCUA` 52%, `HT-DVC` 31%, `HT-TUPHAP` 12%).
3. Mai bấm dòng `HT-DVC` để xem danh sách giao dịch (UC-14-33) và bấm "Xuất Excel" (API-14-066); báo cáo trên 10.000 dòng chạy nền (tuân thủ FR-00-031) và việc xuất được ghi kiểm toán.
4. Lúc 15:00 bộ phân tích thấy `HT-BAOCAO` tra 812 đối tượng khác nhau trong một giờ với dịch vụ BHXH, vượt `14.anomaly.lookups-per-hour` = 500, trong khi đường chuẩn 7 ngày chỉ khoảng 60.
5. Hệ thống tạo cảnh báo `anomaly_alert` ở `OPEN` kèm bằng chứng tóm tắt (số liệu, giao dịch mẫu), gửi Dũng và Lan trong 15 phút, phát EVT-14-16 để PH-13 đẩy vào SIEM.
6. Dũng mở cảnh báo ở UI-14-13 (API-14-067), xem các giao dịch liên quan và thấy `HT-BAOCAO` không có mã hồ sơ thủ tục tương ứng. Dũng chọn "Đề nghị thu hồi quyền gọi dịch vụ của HTTT" kèm lý do.
7. Hệ thống gọi API-14-068, chuyển đề nghị sang PH-02 xử lý, ghi quyết định, kết thúc cảnh báo (`RESOLVED`), phát EVT-14-16.

**Luồng thay thế.**

- **6a. Xác nhận hợp lệ.** Dũng thấy đợt tra là đối chiếu cuối tháng của `HT-BAOCAO` nên chọn "Xác nhận hợp lệ" kèm lý do.
- **6b. Tạm dừng dịch vụ cho HTTT.** Dũng chọn tạm dừng dịch vụ BHXH cho riêng `HT-BAOCAO` trong lúc điều tra.
- **4a. Cửa sổ đã báo.** Lan khai trước "cửa sổ đã báo" cho đợt tra hợp lệ định kỳ (có lý do và hạn) để bộ phân tích không phát cảnh báo trong thời gian đó.
- **1a. Nhật ký cũ hơn 12 tháng.** Lấy từ kho lưu trữ WORM bằng yêu cầu chạy nền (SEC-62).
- **4b. Các quy tắc khác.** Ngoài tra hàng loạt, bộ phân tích còn bắt tăng đột biến hơn 5 lần so với trung bình 7 ngày cùng giờ, hơn 50 lượt ngoài giờ làm việc, và một `caseCode` tra hơn 5 đối tượng.

**Luồng ngoại lệ.**

- **E1. Khoảng thời gian quá rộng (bước 1).** ERR-14-003 (400); "Khoảng thời gian báo cáo tối đa 92 ngày."
- **E2. Kết thúc cảnh báo chưa có lý do (bước 7).** ERR-14-003 (400); "Nhập lý do khi xác nhận hợp lệ hoặc đề nghị thu hồi."
- **E3. PH-02 không khả dụng khi đề nghị thu hồi (bước 7).** ERR-14-027 (502); "Chưa gửi được đề nghị thu hồi. Thử lại sau."
- **E4. Tổng hợp giờ hiện tại chưa sẵn sàng.** Không có mã lỗi; ghi chú "Số liệu giờ hiện tại đang được tổng hợp".

**Quy tắc áp dụng.** BR-14-008, 009, 020, 029.

**Màn hình, API.** UI-14-13; API-14-065, 066, 067, 068.
:::

### 6.36. UC-14-36 · Tham số phân hệ và báo cáo hạn mức, đệm

::: dac-ta
**Mục tiêu.** Quản trị tenant điều chỉnh tham số vận hành của PH-14 theo thực tế của tỉnh trong miền an toàn, tham số bảo mật cần người thứ hai duyệt; và lập báo cáo định kỳ về hạn mức, hiệu quả đệm làm bằng chứng khi đề nghị trung ương nâng hạn mức.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan).

**Tác nhân phụ.** ROLE-INTEGRATION_APPROVER (Bình, duyệt tham số bảo mật); PH-18 (lưu tham số); cổng quốc gia; lãnh đạo nhận báo cáo.

**Mức ưu tiên.** M (tham số), C, Đợt 3 (báo cáo).

**FR hiện thực.** FR-14-054, 057.

**Truy vết.** REQ-14, REQ-13, REQ-18; BP-06; không có ở hệ cũ.

**Tiền điều kiện.** Lan có `PERM-14-admin`; PH-18 sẵn sàng (nếu không, dùng bản đệm 60 giây rồi giá trị mặc định); báo cáo cần dữ liệu `quota_usage` và `usage_hourly` trong kỳ.

**Kích hoạt.** Lan mở UI-14-16 và bấm "Sửa"; hoặc bộ lập lịch lập báo cáo ngày 01 hằng tháng lúc 07:00, hoặc Lan bấm "Lập báo cáo" ở UI-14-13.

**Đảm bảo tối thiểu.** Giá trị ngoài miền hoặc mâu thuẫn không được lưu; thay đổi tham số bảo mật không có hiệu lực khi chưa duyệt; báo cáo gửi qua liên kết, không đính kèm dữ liệu.

**Đảm bảo thành công.** Tham số mới có hiệu lực ở cổng trong 30 giây không khởi động lại; báo cáo có liên kết tải 30 ngày.

**Luồng chính.**

1. Lan mở UI-14-16 (API-14-070). Hệ thống hiện từng tham số `14.*` với giá trị hiện tại, mặc định, miền, ý nghĩa; tham số bảo mật (★) có nhãn riêng.
2. Lan sửa `14.cache.stale-max-seconds` từ 86.400 xuống 43.200 và `14.quota.background-defer-ratio` từ 0,7 xuống 0,6. Hệ thống gọi API-14-071, kiểm tra giá trị nằm trong miền và ràng buộc giữa tham số (`14.quota.essential-only-ratio` = 0,95 vẫn lớn hơn 0,6).
3. Lan sửa `14.signature.hold-threshold` (★) từ 5 xuống 3. Vì là tham số bảo mật, hệ thống tạo yêu cầu duyệt cho Bình và trả `202`.
4. Bình duyệt (LP-14-01). Hệ thống lưu giá trị mới ở PH-18, ghi kiểm toán với giá trị trước và sau.
5. Cổng quốc gia và bộ chạy kiểm tra làm mới tham số trong 30 giây.
6. Ngày 01/12/2026 lúc 07:00 hệ thống lập báo cáo tháng 11 (API-14-069): mức dùng cao nhất theo dịch vụ, số ngày vượt 70%, 85%, 95%, số lượt trúng đệm (tiết kiệm 372.000 lượt), số lượt bị hoãn hoặc từ chối.
7. Hệ thống đưa khuyến nghị: "BHXH vượt 95% trong 4 ngày, đề nghị trung ương nâng hạn mức"; "tăng thời hạn đệm cho `vbqppl-tim-toan-van`"; lưu báo cáo PDF hạn tải 30 ngày và gửi thông báo có liên kết cho lãnh đạo (tuân thủ FR-00-062).

**Luồng thay thế.**

- **2a. Khôi phục mặc định.** Lan khôi phục một tham số về mặc định; tham số bảo mật khôi phục cũng cần duyệt nếu làm giảm kiểm soát.
- **6a. Khoảng tùy chọn.** Lan lập báo cáo cho khoảng tùy chọn (tối đa 92 ngày) thay vì theo tháng, định dạng `XLSX`.
- **1a. PH-18 không khả dụng.** Cổng dùng bản đệm 60 giây rồi giá trị mặc định.
- **6b. Tháng chưa kết thúc.** Báo cáo chỉ cho xem tạm.

**Luồng ngoại lệ.**

- **E1. Giá trị ngoài miền hoặc mâu thuẫn (bước 2).** ERR-14-036 (422); "Giá trị của 14.quota.background-defer-ratio phải nằm trong 0,5…0,95."
- **E2. Người duyệt trùng người sửa (bước 4).** ERR-14-007 (403); "Bạn không thể tự duyệt thay đổi tham số do mình sửa."
- **E3. Không có dữ liệu trong kỳ (bước 6).** ERR-14-001 (404); "Chưa có dữ liệu sử dụng trong kỳ này."
- **E4. Dữ liệu đã bị sửa bởi người khác (bước 2).** ERR-14-004 (412 khi `If-Match` lệch, 409 khi trạng thái không cho phép); "Đối tượng đang ở trạng thái ACTIVE hoặc đã được người khác sửa, không thực hiện được thao tác này. Tải lại và thử lại."

**Quy tắc áp dụng.** BR-14-011, 013, 022.

**Màn hình, API.** UI-14-16, 13; API-14-069, 070, 071.
:::

### 6.37. UC-14-37 · Chạy song song với kết nối NGSP cũ

::: dac-ta
**Mục tiêu.** Trong giai đoạn thay dần, đối chiếu kết quả của đường mới (PH-14) với đường cũ (LGSP cũ qua NGSP) trên cùng yêu cầu đọc thật, để quyết định cắt chuyển từng dịch vụ có căn cứ mà không gián đoạn dịch vụ công và không ghi trùng lên hệ thống quốc gia.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan); ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** Luồng cắt chuyển của PH-04 (gửi quan sát); hệ cũ (đường cũ); cổng quốc gia; HTTT.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-14-055 (nền: FR-14-025).

**Truy vết.** REQ-14, REQ-22; BP-09; LGC-NGSP-008 (thông tin xác thực hệ cũ).

**Tiền điều kiện.** Dịch vụ `dkdn-du-lieu-moi-nhat` thao tác `READ` đã `ACTIVE` ở PH-14; thông tin xác thực mới đã cấp, không dùng khóa của hệ cũ; An và Lan có `PERM-14-service`.

**Kích hoạt.** Lan mở UI-14-15 và bấm "Bắt đầu chạy song song" cho dịch vụ.

**Đảm bảo tối thiểu.** HTTT vẫn nhận kết quả từ đường cũ trong suốt thời gian chạy song song; khác biệt chỉ để cảnh báo, không bao giờ tự sửa kết quả; chạy song song không tốn hạn mức của dịch vụ thiết yếu.

**Đảm bảo thành công.** Dịch vụ được đánh dấu "sẵn sàng cắt chuyển" khi đủ tỷ lệ khớp, số ngày, số mẫu; phiên chỉ đóng sau khi xác nhận thu hồi khóa cũ.

**Luồng chính.**

1. Lan chọn dịch vụ `dkdn-du-lieu-moi-nhat`, `sampleRatio = 0,1`, `ignoreFields = ["dataTime"]`, `startAt = 2026-12-01T00:00:00+07:00`, `observationSource = PH04_FLOW`. Hệ thống gọi API-14-072 và kiểm tra dịch vụ không phải thao tác ghi.
2. HTTT vẫn gọi đường cũ để nhận kết quả thật; luồng cắt chuyển của PH-04 sao yêu cầu đọc sang PH-14 theo tỷ lệ mẫu và gửi kết quả đường cũ cho PH-14 như một quan sát (API-14-089).
3. PH-14 gọi đường mới ở ưu tiên `BACKGROUND` và so sánh kết quả hai đường sau khi bỏ trường biến động (thời điểm, mã giao dịch).
4. Hệ thống ghi từng cặp: khớp, khác ở trường nào, lỗi một bên; tính tỷ lệ khớp theo ngày.
5. Lan và An theo dõi ở UI-14-15 (API-14-073): sau 7 ngày liên tục tỷ lệ khớp 99,4% với 3.420 mẫu; hệ thống đánh dấu "sẵn sàng cắt chuyển" vì đạt `14.parallel.match-ratio` = 0,99, `14.parallel.min-days` = 7, `14.parallel.min-samples` = 1.000.
6. An xem 21 cặp khác nhau (`differences[]`): đa số do đường cũ làm tròn ngày; An ghi nhận không cần sửa.
7. Trước khi đóng phiên, hệ thống yêu cầu hoàn tất xác nhận thu hồi khóa cũ ở UC-14-17 (nhập `revocationReceipt`). Lan đóng phiên; hệ thống phát EVT-14-12.

**Luồng thay thế.**

- **1a. Dịch vụ có hạn mức thấp.** Lan đặt tỷ lệ mẫu thấp hơn 10%, hoặc hệ thống tự giảm tỷ lệ mẫu và cảnh báo khi hạn mức quá thấp để lấy mẫu; không có lỗi.
- **5a. Dừng sớm.** Lan dừng chạy song song bất kỳ lúc nào; mẫu đã ghi giữ 90 ngày.
- **7a. Dịch vụ ghi.** Thao tác ghi (đăng ký hộ tịch, nhận hồ sơ) không chạy song song được; cắt chuyển một lần theo dịch vụ ghi, ngoài giờ cao điểm, sau khi phần đọc cùng nhóm đã đạt (Q14-11).

**Luồng ngoại lệ.**

- **E1. Dịch vụ là thao tác ghi (bước 1).** ERR-14-033 (409); "Chỉ chạy song song cho thao tác đọc, để không ghi trùng lên hệ thống quốc gia."
- **E2. Đã có phiên cho dịch vụ này (bước 1).** ERR-14-033 (409); "Dịch vụ này đang chạy song song."
- **E3. Chưa nhập xác nhận thu hồi khóa cũ (bước 7).** ERR-14-004 (409); "Cần xác nhận trung ương đã hủy khóa cũ trước khi đóng chạy song song."
- **E4. Dịch vụ không tồn tại (bước 1).** ERR-14-001 (404); "Không tìm thấy dịch vụ dkdn-du-lieu-moi-nhat."

**Quy tắc áp dụng.** BR-14-013, 033, 034.

**Màn hình, API.** UI-14-15; API-14-072, 073, 089.
:::

### 6.38. UC-14-38 · Nhập cấu hình dịch vụ từ hệ cũ và cắt chuyển

::: dac-ta
**Mục tiêu.** Đưa danh sách dịch vụ của phụ lục NGSP hệ cũ vào PH-14 thành các bản nháp dịch vụ kèm bảng ánh xạ mã cũ sang mã mới, mà không nhập Consumer Key, Secret hay thông tin xác thực nào của hệ cũ; rồi dẫn tới cắt chuyển có kiểm soát.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An); ROLE-TENANT_ADMIN (Lan).

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng) nhận cảnh báo lộ bí mật; dịch vụ quét mã độc; PH-03, PH-04 (chuyển tuyến).

**Mức ưu tiên.** S.

**FR hiện thực.** FR-14-056 (nền: FR-14-007, 008, 025, 055).

**Truy vết.** REQ-14, REQ-22; BP-09; LGC-NGSP-008 (Consumer Key và Secret của hệ cũ không di trú).

**Tiền điều kiện.** An có `PERM-14-service`; có tệp đã chuẩn bị theo mẫu (mã cũ, tên, `Service-code`, nhóm, loại thao tác); nền tảng `ndxp-t68` `ACTIVE`.

**Kích hoạt.** An bấm "Nhập từ hệ cũ" ở UI-14-15.

**Đảm bảo tối thiểu.** Không giá trị bí mật nào được lưu; ghi theo kiểu tất cả hoặc không; tệp lỗi không áp dụng một phần.

**Đảm bảo thành công.** Các bản nháp dịch vụ `DRAFT` nhãn `UNKNOWN` kèm bảng `legacyMap`; báo cáo nêu vị trí bí mật dạng rõ đã bị bỏ.

**Luồng chính.**

1. An tải tệp mẫu về (tuân thủ FR-00-033), điền từ phụ lục NGSP và tải lên `phu-luc-ngsp.xlsx` (41 dòng) với `mode = PREVIEW`, `onDuplicate = SKIP`. Hệ thống kiểm tra loại, kích thước, quét mã độc (SEC-45).
2. Hệ thống gọi API-14-074, phân tích từng dòng (báo lỗi theo dòng, cột) và hiện bản xem trước chưa ghi gì: 40 dịch vụ sẽ tạo, 1 trùng mã bỏ qua.
3. Hệ thống quét tìm bí mật dạng rõ và thấy cột `secret` ở dòng 3. Hệ thống không lưu giá trị, đánh dấu vị trí và báo Dũng (BR-14-034).
4. An xem báo cáo, đổi `mode = APPLY` và xác nhận. Hệ thống ghi theo kiểu tất cả hoặc không: tạo 40 bản nháp dịch vụ `DRAFT`, nhãn `UNKNOWN`, ghi `legacyCode` sang `serviceCode`, phát EVT-14-02.
5. Hệ thống sinh báo cáo: tạo 40, bỏ qua 1, trùng 1, vị trí bí mật (dòng 3); An tải `legacyMap` về.
6. Hệ thống gợi ý bước tiếp: đối chiếu với danh mục hiện hành (UC-14-06), nạp đặc tả (UC-14-05), cấp lại thông tin xác thực (UC-14-17).
7. Với mỗi dịch vụ: An chạy song song (UC-14-37), khi sẵn sàng An phối hợp PH-03, PH-04 chuyển lưu lượng HTTT sang đường mới; Lan xác nhận khóa cũ đã thu hồi ở trung ương (UC-14-17) rồi đóng phiên chạy song song.

**Luồng thay thế.**

- **2a. Chỉ xem.** `mode = PREVIEW` chỉ trả báo cáo, không ghi gì.
- **4a. Ghi đè bản nháp.** `onDuplicate = OVERWRITE_DRAFT` ghi đè bản nháp cùng mã chưa kích hoạt.
- **3a. Bí mật dạng rõ.** Dũng xử lý lộ lọt theo quy trình sự cố ATTT ở PH-13 và yêu cầu cấp lại khóa (UC-14-17) trước khi cắt chuyển.

**Luồng ngoại lệ.**

- **E1. Tệp không hợp lệ (bước 2).** ERR-14-032 (422); "Dòng 12, cột Service-code: để trống. Chưa có dữ liệu nào được nhập."
- **E2. Phát hiện bí mật dạng rõ (bước 3).** Không lỗi, cảnh báo; "Tệp chứa thông tin xác thực dạng rõ ở dòng 3. Giá trị không được lưu. Cán bộ ATTT cần xử lý lộ lọt và cấp lại khóa."
- **E3. Nền tảng đích không tồn tại (bước 1).** ERR-14-001 (404); "Không tìm thấy nền tảng ndxp-t68."
- **E4. Chưa xác nhận thu hồi khóa cũ khi đóng chạy song song (bước 7).** ERR-14-004 (409); "Cần xác nhận trung ương đã hủy khóa cũ trước khi đóng chạy song song."

**Quy tắc áp dụng.** BR-14-024, 025, 034.

**Màn hình, API.** UI-14-15; API-14-074.
:::

## 7. Luồng phụ dùng chung

Sáu luồng dưới đây lặp lại ở nhiều use case. Use case chỉ viện dẫn mã luồng phụ ở bước dùng nó; chi tiết kiểm tra và mã lỗi nằm ở FR tương ứng.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-14-01 | Bốn mắt: hệ thống tạo việc ở hộp "Việc của tôi" cho người có `PERM-14-approve` (tuân thủ FR-00-070, FR-00-071), so người duyệt với người đề nghị và người sửa gần nhất; trùng thì khóa nút "Duyệt" ở UI-14-17 và trả ERR-14-007 nếu gọi thẳng API; có hai người thì ghi cả hai vào kiểm toán | UC-14-02, 04, 05, 08, 18, 20, 22, 26, 31, 36 |
| LP-14-02 | Lý do bắt buộc: hộp thoại có ô lý do 10…500 ký tự; thiếu hoặc sai độ dài trả ERR-14-003 với câu "Giá trị lý do không hợp lệ: cần từ 10 đến 500 ký tự." | UC-14-02, 03, 17, 18, 20, 25, 26, 33, 34, 35 |
| LP-14-03 | Xác thực lại nhiều yếu tố (step-up, SEC-23): trước thao tác nhạy cảm hệ thống đòi yếu tố thứ hai ở PH-12; chưa đạt thì thao tác không được ghi nhận (xem nội dung đầy đủ trả ERR-14-030) | UC-14-18, 33, 34 |
| LP-14-04 | Kết quả bất đồng bộ: lệnh dài trả `202` kèm mã tác vụ (`requestId`, `runId`) và đường dẫn tra; giao diện hỏi lại theo kết quả hoặc nghe thông báo; kết quả giữ theo thời hạn của từng chức năng (72 giờ với yêu cầu gửi quốc gia, 24 giờ với liên kết tải) | UC-14-10, 29, 30, 31, 33, 35, 36 |
| LP-14-05 | Kiểm tra mục đích khai thác và ghi giao dịch: OPA kiểm tra đăng ký sử dụng, mục đích, khung giờ; PH-09 kiểm tra sổ hoạt động xử lý DLCN với dịch vụ từ mức `RESTRICTED`; kiểm tra mã thủ tục, mã hồ sơ; từ chối thì trả ERR-14-106 hoặc ERR-14-107, OPA hay PH-09 không khả dụng thì từ chối an toàn ERR-14-132; mọi lượt, kể cả bị từ chối, có giao dịch | UC-14-09, 10, 11, 12, 13, 14, 27 |
| LP-14-06 | Lỗi chuẩn hóa: lỗi trả theo RFC 9457 kèm mã truy vết; mã lỗi không có trong bảng thông báo hiển thị theo FR-00-080 (câu lấy từ trường `detail`, kèm mã lỗi, nút "Sao chép mã truy vết"); lỗi nội bộ không lường trước là ERR-14-127 | Mọi use case |

: Luồng phụ dùng chung của PH-14

## 8. Tổng hợp mã mới và đối chiếu

Tập này không tạo mã FR, API, ERR, UI, EVT hay BR mới; mọi mã dẫn từ [D02-03-PH14](../frs/D02-03-PH14-frs-ket-noi-quoc-gia.md). Mã mới của tập: UC-14-01…38, LP-14-01…06 và câu hỏi mở Q14-45…49. Dải câu hỏi mở của tập use case là 45–49 theo D00-04 §3.1 nên tập này đã dùng hết dải; câu hỏi phát sinh thêm khi thiết kế được ghi ở tập tiếp theo.

Bảng dưới là truy vết ngược từ FR sang use case, để kiểm tra mọi FR có ít nhất một use case. FR ghi ba chữ số cuối của `FR-14-nnn`; FR mức M thuộc ít nhất một use case, FR mức S, C ghi đợt.

| Nhóm FR | FR → UC | Ghi chú |
|---|---|---|
| A · Nền tảng và dịch vụ | 001 → 01; 002 → 01; 003 → 02, 03; 004 → 04; 005 → 04; 006 → 04; 007 → 06; 008 → 05; 009 → 07 | FR-14-003 chia hai use case: bật có duyệt (UC-14-02) và tạm ngừng, tiếp tục, ngừng dùng (UC-14-03) |
| B · Gọi dịch vụ và định tuyến | 010 → 09; 011 → 09; 012 → 08, 09; 013 → 08; 014 → 09; 015 → 09; 016 → 10 | UC-14-09 là lõi dùng chung của mọi bộ điều hợp |
| C · Bộ điều hợp theo nhóm | 017 → 11; 018 → 11; 019 → 12; 020 → 13; 021 → 14; 022 → 14; 023 → 15 | Bảy nhóm dịch vụ của phụ lục NGSP |
| D · Xác thực, chữ ký, chứng thư | 024 → 16; 025 → 17; 026 → 09, 18; 027 → 09, 21; 028 → 18; 029 → 19; 030 → 20; 031 → 21 | FR-14-026, 027 được dùng ở UC-14-09 và UC-14-27 |
| E · Hạn mức, đệm, chịu lỗi | 032 → 22; 033 → 23; 034 → 22, 23; 035 → 24; 036 → 24 (mức S, MVP); 037 → 24; 038 → 25 | |
| F · Chiều vào | 039 → 26; 040 → 27; 041 → 27; 042 → 28 (mức S, Đợt 2) | |
| G · Đồng bộ | 043 → 29; 044 → 30 (mức S, Đợt 3); 045 → 31 (mức S, Đợt 3); 046 → 29, 31 | |
| H · Giám sát, đối soát | 047 → 01, 32; 048 → 32; 049 → 33; 050 → 34; 051 → 33 (mức S, Đợt 2); 052 → 35; 053 → 35 (mức S, Đợt 2) | |
| I · Quản trị, chuyển đổi | 054 → 36; 055 → 37 (mức S, MVP); 056 → 38 (mức S, MVP); 057 → 36 (mức C, Đợt 3) | |

: Truy vết ngược từ FR sang use case

Kết quả đối chiếu: 57 FR của FRS đều có use case, gồm 48 FR mức M, 8 FR mức S (036, 042, 044, 045, 051, 053, 055, 056) và 1 FR mức C (057). Chức năng xuyên suốt FR-14-010 được hiện thực ở UC-14-09 và dùng lại ở UC-14-10…15; FR-14-011 xuất hiện ở UC-14-09 và dùng lại bằng LP-14-05; FR-14-024 ở UC-14-16 và dùng lại ở UC-14-09 bước 8. Mỗi use case có ít nhất một FR, một màn hình hoặc API (use case máy UC-14-09, 16, 27 gắn với API-14-075, API-14-040, API-14-084) và một `ERR-14-nnn` có thật ở FRS §9.1.

## 9. Câu hỏi mở

Các câu hỏi dưới đây phát sinh khi đặc tả use case và chưa có trong 14 câu hỏi của FRS (Q14-01…14). Mỗi câu nêu use case bị ảnh hưởng và cách tập này tạm xử lý.

> **Câu hỏi mở Q14-45:** UC-14-03 nhánh 1a cho Cán bộ ATTT tạm ngừng khẩn cấp nền tảng mà không cần duyệt, và chỉ quản trị tenant mới tiếp tục được. Cần chủ đầu tư và đơn vị vận hành xác nhận có đặt thời hạn bắt buộc quản trị tenant xem xét lại sau tạm ngừng khẩn cấp (đề xuất 4 giờ làm việc), và khi quản trị tenant vắng thì ai thay thế (người duyệt tích hợp hay trực lãnh đạo). Tạm thời tập này theo FRS: chỉ TA tiếp tục.

> **Câu hỏi mở Q14-46:** UC-14-21 bước 6 cho Cán bộ ATTT tự giải trừ trạng thái `SECURITY_HOLD` (xảy ra khi từ 5 sự cố chữ ký trong 10 phút). Cần xác nhận có cần bốn mắt khi giải trừ như với kích hoạt chứng thư hay không. Ngoài ra FRS chưa có mã lỗi và câu thông báo riêng cho lượt gọi bị chặn vì `SECURITY_HOLD` (UC-14-21 E4); đề xuất dùng ERR-14-117 (503) kèm `reason = SECURITY_HOLD`, hoặc thêm một mã lỗi mới ở dải mặt phẳng điều khiển khi D03-04-PH14 chốt danh mục lỗi.

> **Câu hỏi mở Q14-47:** UC-14-26 theo FR-14-039: Quản trị tenant khai báo, Cán bộ ATTT xác nhận vân tay chứng thư của nguồn rồi điểm cuối mới `ACTIVE`. BR-14-022 đòi người thứ hai duyệt khi bật điểm cuối chiều vào. Cần xác nhận người xác nhận của Cán bộ ATTT có thỏa BR-14-022 (người thứ hai) hay cần thêm Người duyệt tích hợp duyệt bật như với nền tảng (UC-14-02). Tạm thời tập này coi Cán bộ ATTT là người thứ hai.

> **Câu hỏi mở Q14-48:** UC-14-37 chạy song song sao yêu cầu đọc sang đường mới. Với dịch vụ mức `SENSITIVE` (lý lịch tư pháp, hộ tịch), mỗi lượt sao là thêm một lần tra cứu dữ liệu cá nhân ngoài nhu cầu của hồ sơ. Cần PH-09 và đơn vị thẩm định Luật BVDLCN 91/2025 xác nhận có coi lượt sao là khai thác đúng mục đích, hay chỉ cho chạy song song với dịch vụ mức `RESTRICTED` trở xuống và dùng bộ hồ sơ thử cho mức `SENSITIVE`. Tạm thời UC-14-37 dùng ví dụ dịch vụ mức `INTERNAL`.

> **Câu hỏi mở Q14-49:** UC-14-13 và UC-14-23: từ mức dùng hạn mức 70% dịch vụ `BACKGROUND` (đồng bộ hồ sơ ĐVQHNS) bị hoãn; nếu mức dùng ở trên 70% cả ngày thì hồ sơ không được đồng bộ trong ngày. Cần chủ quản dịch vụ (Sở Tài chính) xác nhận độ trễ đồng bộ tối đa chấp nhận được (giả định 24 giờ, cơ sở: đồng bộ chạy hằng đêm) và có cho phép dịch vụ nền dùng phần hạn mức chưa phân bổ khi dịch vụ thiết yếu không cần hay không.

**Quyết định đã chốt ngày 27/11/2026.** Các điểm dưới đây từng là đề nghị hoặc câu hỏi, nay chốt theo đề xuất kỹ thuật; phần việc ở tập của phân hệ khác do tập đó ghi.

- UC-14-07: PH-02 có loại API "dịch vụ quốc gia" nhận bản nháp từ PH-14 và phát sự kiện đã công bố; PH-14 chỉ tạo bản nháp, không tự công bố.
- UC-14-26: PH-03 có tuyến chiều vào `/inbound/v1/*` ở vùng biên với mTLS, giới hạn tần suất, WAF và bộ lọc vân tay nạp từ EVT-14-13. PH-02 và PH-03 ghi vào FRS của mình khi PH-14 chốt hợp đồng.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây cần sửa ở tài liệu dùng chung hoặc tài liệu của phân hệ khác; tập này không sửa trực tiếp vì các luồng viết chạy song song. Đề nghị thực hiện trong đợt đồng bộ cuối.

| Tài liệu | Nội dung đề nghị | Lý do |
|---|---|---|
| D03-06-PH14 §5.2 (bảng thông báo) | Thêm các câu thông báo tập UC viết thêm cho mã lỗi dùng chung: ERR-14-003 với lý do ("Giá trị lý do không hợp lệ: cần từ 10 đến 500 ký tự."), ERR-14-003 khi sai phạm vi vô hiệu đệm; câu 403 theo FR-00 cho các trường hợp "Chỉ quản trị nền tảng được khai báo nền tảng dùng chung toàn quốc.", "Nền tảng đang bị tạm ngừng bởi cán bộ ATTT, chỉ quản trị tỉnh được tiếp tục." (UC-14-03 E3) | Mỗi luồng ngoại lệ của UC cần một câu người dùng nhìn thấy; FRS chỉ có câu cho 39 mã mặt phẳng điều khiển |
| D03-04-PH14 §6 (mã lỗi) | Quyết định mã lỗi và câu thông báo cho lượt gọi bị chặn vì `SECURITY_HOLD` (Q14-46) | FRS §4.3 mô tả trạng thái nhưng chưa có mã lỗi riêng |
| D02-08 §3.1, §5 | Như mục "Đề nghị đồng bộ" của D02-03-PH14: thêm mười quyền `PERM-14-*` còn thiếu và sáu scope máy; tập UC dùng đúng các quyền đó | Kiểm tra mã đang báo thiếu định nghĩa các quyền này |
| D00-03 phần A, §4.7 | Thêm cột "UC" cho các mục `LGC-NGSP-001…008`, `LGC-DMDC-019` theo bảng 5.3 của tập này (UC-14-11…15, 16, 17, 37, 38) | Truy vết hệ cũ → FR → UC liền mạch |
| D02-04-PH02, D02-04-PH03 (khi viết) | UC-14-07 cần PH-02 có loại API "dịch vụ quốc gia" nhận bản nháp từ PH-14 và phát sự kiện đã công bố; UC-14-26 cần PH-03 nạp tuyến chiều vào có mTLS, giới hạn tần suất, WAF | PH-14 chỉ tạo bản nháp, không tự công bố |
| D02-04-PH07, D02-04-PH06, D02-04-PH09 (khi viết) | UC-14-15 (PH-07 là bên gọi cổng tiếp hợp), UC-14-30 (PH-06 gọi cầu nối), UC-14-12 và UC-14-31 (PH-09 kiểm tra mục đích và trường) cần UC đối ứng ở phía các phân hệ này | Hai đầu của cùng một luồng phải khớp |

: Đề nghị đồng bộ của tập use case PH-14

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và quy chuẩn K-TRINH-BAY: 38 use case, sáu sơ đồ use case, ba bảng truy vết, sáu luồng phụ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: ETag lệch trả 412 ở các luồng ngoại lệ; chốt Q404: PH-02 thêm loại API dịch vụ quốc gia nhận bản nháp, PH-03 thêm tuyến chiều vào /inbound/v1 (mTLS, giới hạn tần suất, WAF) |
