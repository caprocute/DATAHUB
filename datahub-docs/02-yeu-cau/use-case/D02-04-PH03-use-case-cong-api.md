---
ma_tai_lieu: D02-04-PH03
ten: Đặc tả use case phân hệ PH-03 Cổng API
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư dh-connect và gateway, cán bộ ATTT, kiểm thử viên
phan_he: PH-03
mo_ta: Đặc tả 31 use case của phân hệ Cổng API theo ba vòng việc thật của một tỉnh gồm phục vụ lượt gọi, kiểm soát an ninh và phát hành cấu hình, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH03 FRS; D03-04-PH03 API; D03-06-PH03 Màn hình; D05-02-PH03 Test case; D02-08 Ma trận phân quyền
---

# D02-04-PH03 · Đặc tả use case Cổng API

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu đặc tả 31 use case của PH-03, phủ toàn bộ 59 FR của [D02-03-PH03](../frs/D02-03-PH03-frs-cong-api.md) (47 FR mức M, 11 FR mức S, 1 FR mức C). Use case đi theo ba vòng việc thật ở một tỉnh. **Vòng thứ nhất là phục vụ lượt gọi:** một HTTT gọi API qua gateway, bị từ chối đúng chốt khi không đủ điều kiện, bị giới hạn công bằng khi dùng quá mức, và vẫn được phục vụ khi Valkey hoặc backend gặp sự cố. **Vòng thứ hai là kiểm soát an ninh:** Cán bộ ATTT thu hồi token, tạm ngừng khẩn cấp, chặn địa chỉ, chuyển chế độ WAF, duyệt ngoại lệ, mở route ra Internet và theo dõi cảnh báo, luôn với nguyên tắc người đề nghị khác người duyệt. **Vòng thứ ba là phát hành cấu hình:** từ khi API được công bố ở PH-02 tới khi từng nút APISIX nạp ảnh chụp đã ký, có quay lui và theo dõi nút. Phần còn lại là hạn mức, tra nhật ký, báo cáo, tham số và chuyển đổi từ hệ cũ.

**Phạm vi.** Mỗi use case đặc tả bằng khối 15 mục (mục tiêu, tác nhân, FR hiện thực, truy vết, tiền điều kiện, các luồng, mã lỗi kèm câu thông báo lấy từ FRS §9.2, quy tắc, màn hình và API). Ví dụ dùng tenant `T68` và dữ liệu giả lập. Phân hệ gồm hai đơn vị triển khai: `apisix` (mặt phẳng dữ liệu) và `dh-connect` (mặt phẳng điều khiển); các use case của mặt phẳng dữ liệu có tác nhân chính là HTTT gọi API hoặc chính APISIX và không có màn hình riêng.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-09 (Công văn 631/THH-THHT: quản lý API, OAuth, giới hạn tần suất, chống từ chối dịch vụ), CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026: TLS, WAF, kiểm soát truy cập, nhật ký), CMP-LAW-16 (Luật An ninh mạng 116/2025), CMP-LAW-05 (Luật BVDLCN 91/2025: không ghi dữ liệu cá nhân vào nhật ký lượt gọi), CMP-LAW-03 (NĐ 278/2025).

**Những điểm hội đồng cần lưu ý.** (1) Năm use case có người duyệt thứ hai (UC-03-13, 14, 15, 16, 25); đều dùng chung một luồng bốn mắt LP-03-01, tự duyệt bị chặn ở giao diện và ở API (ERR-03-008). (2) Hai use case thu hồi và chặn khẩn cấp (UC-03-10, 11) có hiệu lực không quá 60 giây (mục tiêu 30 giây) nhờ đường nhanh qua Valkey song song với ảnh chụp cấu hình (LP-03-05). (3) UC-03-08 và UC-03-06 cho thấy gateway không dừng khi Valkey hoặc backend hỏng: hạn mức mở có cảnh báo, backend hỏng bị trả `503` nhanh (khác SRS cũ, Q03-03). (4) UC-03-26 và UC-03-01 bảo đảm nhật ký lượt gọi chỉ có siêu dữ liệu, không thân bản tin, không giá trị tiêu đề xác thực (BR-03-007). (5) UC-03-31 nhập cấu hình từ gateway cũ không bao giờ nhập khóa API hay bí mật của hệ cũ (FR-00-093); mọi HTTT dùng khóa API được gắn cờ cấp lại thông tin xác thực. (6) FR-03-034 (chuyển đổi gRPC, mức C, Đợt 3) chỉ là một nhánh của UC-03-07 và có thể bỏ khỏi phạm vi nếu không có nhu cầu (Q03-07 của FRS).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Use case | 31 (mức M: 27, mức S: 4) |
| FR được phủ | 59 trên 59 (47 M, 11 S, 1 C); mỗi FR thuộc ít nhất một use case |
| Use case có người duyệt thứ hai | 5 use case có bốn mắt trực tiếp (UC-03-13, 14, 15, 16, 25) |
| Use case có tác nhân chính là máy (HTTT, APISIX, phân hệ khác) | 12 (UC-03-01 đến 08, 10, 19, 20, 23) |
| Sơ đồ use case tổng | 4 hình, chia theo nhóm để đọc được trên khổ A4 |
| Luồng phụ dùng chung | 5 (LP-03-01…05) |
| Câu hỏi mở mới | 5 (Q03-45…49) |

: Con số chính của tập use case PH-03

## 1. Giới thiệu

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các phân hệ và hệ thống bên ngoài để hoàn thành từng việc nghiệp vụ của PH-03, từ một lượt gọi API đi qua gateway tới việc phát một ảnh chụp cấu hình xuống các nút APISIX. Phạm vi là toàn bộ FR-03-001…059. Chức năng dùng chung FR-00 (đăng nhập, chọn tenant, phân quyền, kiểm toán chung, hộp "Việc của tôi", thông báo, hiển thị lỗi) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Hành vi chi tiết của từng chốt (tham số, ngưỡng, định dạng thân lỗi RFC 9457) nằm ở FR tương ứng; use case mô tả trình tự và vai trò để kỹ sư dựng màn hình, API và kiểm thử viên viết ca.

PH-03 không soạn, duyệt hay công bố API (PH-02), không cấp token hay viết chính sách OPA (PH-12), không lưu lâu dài nhật ký lượt gọi (PH-13). Các use case ở đây chỉ mô tả điểm giao tiếp với các phân hệ đó.

### 1.2. Người đọc

| Người đọc | Phần cần đọc |
|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 4 (sơ đồ tổng), chương 5 (truy vết), chương 8 (độ phủ FR) |
| Cán bộ ATTT, quản trị tenant | Chương 6 các use case 03, 10 đến 18, 25, chương 7 |
| Kỹ sư giao diện, BFF | Chương 6, đối chiếu cột "Màn hình, API" và bảng 5.2 |
| Kỹ sư gateway, `dh-connect` | Chương 6 các use case 01 đến 09, 19 đến 24 |
| Kiểm thử viên | Chương 6: mỗi luồng chính, luồng thay thế, luồng ngoại lệ là một ca kiểm thử ở D05-02-PH03 |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và tài liệu tham chiếu

Thuật ngữ, chữ viết tắt và vai trò dùng chung với [D02-03-PH03](../frs/D02-03-PH03-frs-cong-api.md) §1.4 và D00-01. Các từ dùng nhiều trong tài liệu này: **route** (quy tắc định tuyến của gateway), **consumer** (hình chiếu của một client HTTT trên gateway), **ảnh chụp cấu hình** (tệp khai báo đầy đủ của gateway, có số phiên bản và chữ ký), **nút** (một pod APISIX), **cửa vào** (`INT` hoặc `EXT`). Tài liệu tham chiếu: D02-03-PH03 (FRS, nguồn của mọi mã lỗi và câu thông báo), D02-08 (ma trận phân quyền), D03-04-PH03 (API), D03-06-PH03 (màn hình), D05-02-PH03 (ca kiểm thử), `docs/07-srs/SRS-PH-03-gateway.md` (SRS cũ của repo, nguồn kế thừa).

### 1.4. Cấu trúc tài liệu

| Chương | Nội dung |
|---|---|
| 2 | Quy ước đọc đặc tả và dữ liệu ví dụ |
| 3 | Tác nhân |
| 4 | Sơ đồ use case tổng (bốn hình) |
| 5 | Bảng tổng hợp use case và ba bảng truy vết (FR, màn hình và API, REQ và hệ cũ) |
| 6 | Đặc tả chi tiết 31 use case |
| 7 | Năm luồng phụ dùng chung |
| 8 | Mã mới và độ phủ FR |
| 9 | Câu hỏi mở |

: Cấu trúc của tài liệu

## 2. Quy ước đọc đặc tả

Mỗi use case đặc tả bằng một khối hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ (kèm câu thông báo), Quy tắc áp dụng, Màn hình và API. Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `5a`) và quay lại luồng chính. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh, mã lỗi `ERR-03-nnn` và câu thông báo trong ngoặc kép lấy từ FRS §9.1, §9.2 và từng FR.

Hai điểm riêng của PH-03. **Thứ nhất,** use case của mặt phẳng dữ liệu (UC-03-01 đến 08) có tác nhân chính là HTTT gọi API hoặc APISIX; câu thông báo ở luồng ngoại lệ là nội dung `detail` của thân lỗi RFC 9457 trả cho bên gọi (mã `ERR-03-101…130`), còn người vận hành xem lại đúng các câu đó ở UI-03-09 qua `traceId` (LP-03-04). **Thứ hai,** mọi use case làm đổi cấu hình gateway (dừng API, hạn mức, ngoại lệ WAF, chế độ WAF, cửa vào, chứng thư, mẫu chính sách) kết thúc bằng một lần tổng hợp, kiểm tra, ký, phát và nạp (LP-03-03); luồng chính chỉ nêu "kích hoạt LP-03-03" kèm số giây mục tiêu, không lặp lại các bước đó.

Dữ liệu ví dụ đều giả lập: tenant `T68`; người dùng **Lan** (TA, Sở KH&CN), **Chi** (TO), **Dũng** (SO), **Hà** (PA), **Phong** (PO), **Thảo** (AU); HTTT `HT-QLVB` (consumer `ht-qlvb`), `HT-TUPHAP` (`ht-tuphap`), `HT-DVC` (`ht-dvc`), `HT-BAOCAO` (`ht-baocao`); route `tra-cuu-ho-tich.v1` (API của `HT-TUPHAP`, phạm vi `hotich.read`) và `gui-van-ban.v1` (API của `HT-QLVB`); host `api.t68.datahub.gov.vn`. Thời điểm ví dụ là ngày 26/11/2026.

## 3. Tác nhân

Tác nhân người lấy theo vai trò chuẩn của D02-08; tác nhân hệ thống là phân hệ, thành phần hạ tầng hoặc HTTT. Cột "Use case chính" ghi số `UC-03-nn` mà tác nhân là người bắt đầu hoặc người quyết định.

| Tác nhân | Loại | Use case chính |
|---|---|---|
| HTTT gọi API (client máy, `ROLE-PARTNER_SYSTEM` khi là đối tác thanh toán) | Chính (máy) | 01, 02, 03, 04, 07 |
| Bên gọi từ Internet (HTTT ngoài, nhà cung cấp thanh toán, cổng nhà phát triển) | Chính (máy) | 05 |
| APISIX (mặt phẳng dữ liệu) | Chính (máy) | 06, 08 |
| `dh-connect` và bộ đồng bộ cấu hình | Chính (máy) | 19, 20 |
| ROLE-TENANT_ADMIN (TA, Lan) | Chính | 16, 24, 25, 27, 28, 29 và nhiều use case xem |
| ROLE-TENANT_OPERATOR (TO, Chi) | Chính | 09, 11, 14, 21, 22, 26 |
| ROLE-SECURITY_OFFICER (SO, Dũng) | Chính | 11, 12, 13, 14, 15, 16, 18 |
| ROLE-PLATFORM_ADMIN (PA, Hà) | Chính | 17, 30, 31 |
| ROLE-PLATFORM_OPERATOR (PO, Phong) | Chính | 22 |
| ROLE-AUDITOR (AU, Thảo) | Chính (chỉ đọc) | 26 |
| PH-12 Định danh và phân quyền | Chính (máy) | 10 |
| PH-01 Kết nạp HTTT | Chính (máy) | 23 |
| PH-02 Danh mục dịch vụ | Chính (máy) | 19 |
| PH-13 Giám sát và kiểm toán | Phụ | 01, 06, 18, 22, 26, 27 |
| PH-20 Quản trị tenant | Phụ | 25, 30 |
| Valkey, OpenBao, Garage, Git và Argo CD, OPA, cert-manager | Phụ (hạ tầng) | Nhiều use case |
| Backend của route (HTTT, luồng `dh-runtime`) | Phụ | 01, 06, 07, 09 |

: Tác nhân của PH-03 và use case chính

## 4. Sơ đồ use case tổng

Ba mươi mốt use case chia bốn hình theo nhóm việc để chữ đủ lớn trên khổ A4: lượt gọi qua gateway (Hình 1), kiểm soát an ninh (Hình 2), cấu hình và phát hành (Hình 3), quan sát, quản trị và chuyển đổi (Hình 4). Mỗi hình chỉ nối tác nhân chính với use case; người duyệt thứ hai và tác nhân phụ nêu ở chương 6.

```{.mermaid caption="Use case lượt gọi qua gateway"}
flowchart TB
  HT(["HTTT gọi API"])
  BN(["Bên gọi từ Internet"])
  AX(["APISIX"])
  TO(["Vận hành tỉnh"])
  subgraph LG["Lượt gọi qua gateway"]
    U01["UC-03-01 Gọi API thành công"]
    U02["UC-03-02 Gọi bằng mTLS và token ràng buộc"]
    U03["UC-03-03 Chặn chéo tenant, tiêu đề giả"]
    U04["UC-03-04 Vượt hạn mức, hạn ngạch"]
    U05["UC-03-05 Gọi qua cửa Internet có WAF"]
    U06["UC-03-06 Bảo vệ khi backend lỗi"]
    U07["UC-03-07 WebSocket, gRPC"]
    U08["UC-03-08 Suy giảm khi Valkey mất"]
    U09["UC-03-09 Dừng, mở API, phiên bản song song"]
  end
  HT --> U01 & U02 & U03 & U04 & U07
  BN --> U05
  AX --> U06 & U08
  TO --> U09
```

Hình 1 gom chín use case của mặt phẳng dữ liệu. UC-03-01 là đường đi chuẩn đi qua mọi chốt; các use case còn lại là biến thể có điều kiện riêng (mTLS, chéo tenant, vượt hạn mức, cửa Internet, backend lỗi, mất Valkey). UC-03-09 là use case duy nhất ở nhóm này do người vận hành bắt đầu.

```{.mermaid caption="Use case kiểm soát an ninh"}
flowchart TB
  P12(["PH-12"])
  SO(["Cán bộ ATTT"])
  TO(["Vận hành tỉnh"])
  TA(["Quản trị tỉnh"])
  PA(["Quản trị nền tảng"])
  subgraph AN["Kiểm soát an ninh"]
    U10["UC-03-10 Thu hồi token khẩn cấp"]
    U11["UC-03-11 Tạm ngừng khẩn cấp"]
    U12["UC-03-12 Chặn địa chỉ nguồn"]
    U13["UC-03-13 Đổi chế độ WAF"]
    U14["UC-03-14 Ngoại lệ luật WAF"]
    U15["UC-03-15 Luật vá ảo"]
    U16["UC-03-16 Mở route ra Internet"]
    U17["UC-03-17 Chứng thư biên và TLS"]
    U18["UC-03-18 Cảnh báo an ninh"]
  end
  P12 --> U10
  SO --> U11 & U12 & U13 & U15 & U18
  TO --> U14
  TA --> U16
  PA --> U17
```

Hình 2 cho thấy Cán bộ ATTT là tác nhân của phần lớn use case an ninh vì họ vừa đề nghị vừa duyệt. Ở UC-03-14 (TO đề nghị, SO duyệt) và UC-03-16 (TA đề nghị, SO duyệt) người đề nghị và người duyệt là hai vai trò khác nhau; ở UC-03-13 và UC-03-15 SO đề nghị còn TA hoặc SO khác duyệt. Chỉ PH-12 được gọi đường thu hồi token (UC-03-10).

```{.mermaid caption="Use case cấu hình, phát hành và hạn mức"}
flowchart TB
  P2(["PH-02"])
  P1(["PH-01"])
  CP(["dh-connect và bộ đồng bộ"])
  OP(["TA, TO, SO, PA"])
  PO(["Vận hành nền tảng"])
  TA(["Quản trị tỉnh"])
  subgraph CH["Cấu hình và phát hành"]
    U19["UC-03-19 Tổng hợp, kiểm tra, ký"]
    U20["UC-03-20 Phát và nút nạp"]
    U21["UC-03-21 Quay lui cấu hình"]
    U22["UC-03-22 Theo dõi nút"]
    U23["UC-03-23 Đồng bộ consumer"]
    U24["UC-03-24 Mẫu chính sách, chạy thử"]
    U25["UC-03-25 Hạn mức tenant và route"]
  end
  P2 --> U19
  CP --> U20
  OP --> U21
  PO --> U22
  P1 --> U23
  TA --> U24 & U25
```

Hình 3 là trục phát hành: UC-03-19 và UC-03-20 là hai nửa của đường từ dữ liệu nguồn tới nút gateway và được mọi use case đổi cấu hình dùng lại (LP-03-03). UC-03-21 là lối thoát khi một lần phát gây sự cố; UC-03-22 cho biết nút nào đã nhận phiên bản nào.

```{.mermaid caption="Use case quan sát, quản trị và chuyển đổi"}
flowchart TB
  OB(["TA, TO, SO, AU"])
  TO(["Vận hành tỉnh"])
  TA(["Quản trị tỉnh"])
  PA(["Quản trị nền tảng"])
  subgraph QS["Quan sát, quản trị, chuyển đổi"]
    U26["UC-03-26 Tra và xuất nhật ký lượt gọi"]
    U27["UC-03-27 Tổng quan và báo cáo sử dụng"]
    U28["UC-03-28 Kiểm tra tổng hợp"]
    U29["UC-03-29 Tham số gateway"]
    U30["UC-03-30 Chuyển tiếp tenant sáp nhập"]
    U31["UC-03-31 Nhập cấu hình từ gateway cũ"]
  end
  OB --> U26
  TO --> U27
  TA --> U28 & U29
  PA --> U30 & U31
```

Hình 4 gom việc đọc số liệu (UC-03-26, 27, 28), việc chỉnh tham số của tỉnh (UC-03-29) và hai use case chuyển đổi do quản trị nền tảng làm (sáp nhập tỉnh, nhập từ gateway cũ).

## 5. Bảng tổng hợp use case và truy vết

### 5.1. Use case và FR

Cột "Mức" là mức cao nhất của các FR hiện thực. Mỗi FR thuộc ít nhất một use case; bảng ngược từ FR sang use case ở chương 8.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-03-01 | HTTT gọi API thành công qua gateway | HTTT gọi API | M | 001, 012, 013, 015, 016, 017, 019, 020, 021, 025, 028, 029, 032, 050, 052 |
| UC-03-02 | Gọi API bằng mTLS và token ràng buộc chứng thư | HTTT gọi API | M | 002, 014, 015 |
| UC-03-03 | Chặn lượt gọi chéo tenant và tiêu đề nội bộ giả | HTTT gọi API | M | 012, 013, 050 |
| UC-03-04 | Vượt hạn mức, hạn ngạch và cảnh báo ngưỡng | HTTT gọi API | M | 021, 022, 025 |
| UC-03-05 | Bên ngoài gọi qua cửa Internet có WAF và kiểm tra lược đồ | Bên gọi từ Internet | M | 001, 003, 005, 009, 010, 011 |
| UC-03-06 | Gateway bảo vệ khi backend lỗi | APISIX | M | 027, 029, 030, 031 |
| UC-03-07 | Dùng WebSocket và chuyển đổi gRPC | HTTT gọi API | M | 033, 034 |
| UC-03-08 | Suy giảm có kiểm soát khi Valkey mất | APISIX | M | 025, 026 |
| UC-03-09 | Dừng, mở API và phiên bản API song song | TO | M | 035, 036 |
| UC-03-10 | Thu hồi token khẩn cấp | PH-12 | M | 018 |
| UC-03-11 | Tạm ngừng khẩn cấp route hoặc consumer | SO, TO | M | 047 |
| UC-03-12 | Chặn địa chỉ nguồn tự động và thủ công | SO | M | 003, 004 |
| UC-03-13 | Đổi chế độ WAF có bốn mắt | SO, TA | M | 005, 006 |
| UC-03-14 | Xử lý cảnh báo giả bằng ngoại lệ luật WAF | TO, SO | M | 007 |
| UC-03-15 | Soạn và duyệt luật vá ảo khẩn cấp | SO | S | 008 |
| UC-03-16 | Mở route ra cửa Internet | TA, SO | M | 038 |
| UC-03-17 | Quản lý chứng thư biên, hồ sơ TLS và bộ CA khách | PA | M | 001, 002, 049 |
| UC-03-18 | Nhận và xử lý cảnh báo an ninh của gateway | SO, TO | M | 054 |
| UC-03-19 | Tổng hợp, kiểm tra hợp lệ và ký cấu hình | PH-02 | M | 039, 040, 041 |
| UC-03-20 | Phát ảnh chụp và nút gateway nạp cấu hình | `dh-connect`, bộ đồng bộ | M | 042, 043 |
| UC-03-21 | Quay lui cấu hình khi phát gây sự cố | TO, PA, TA, SO | M | 044 |
| UC-03-22 | Theo dõi nút gateway và trạng thái đồng bộ | PO, TO | M | 045 |
| UC-03-23 | Đồng bộ consumer khi kết nạp, tạm ngừng HTTT | PH-01 | M | 046 |
| UC-03-24 | Quản lý mẫu chính sách và chạy thử chính sách | PA, TA | M | 048, 057 |
| UC-03-25 | Đặt hạn mức toàn tenant và hạn mức theo route | TA | M | 023, 024 |
| UC-03-26 | Tra cứu và xuất nhật ký lượt gọi | TO, SO, TA, AU | M | 050, 051 |
| UC-03-27 | Xem tổng quan lưu lượng và báo cáo sử dụng | TO, TA | M | 052, 055, 058 |
| UC-03-28 | Cấu hình kiểm tra tổng hợp cho API quan trọng | TA | S | 053 |
| UC-03-29 | Điều chỉnh tham số gateway của tỉnh | TA | M | 003, 011, 056 |
| UC-03-30 | Chuyển tiếp lượt gọi của tỉnh đã sáp nhập | PA | S | 037 |
| UC-03-31 | Nhập cấu hình từ gateway cũ | PA, TA | S | 059 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Use case của mặt phẳng dữ liệu (UC-03-01 đến 08) không có màn hình thao tác; cột UI ghi nơi người vận hành xem lại kết quả. API của mặt phẳng dữ liệu là chính API của dịch vụ được gọi qua gateway; cột API chỉ ghi API quản trị `/api/gateway/v1` liên quan.

| UC | UI | API |
|---|---|---|
| UC-03-01 | — (xem lại ở UI-03-09) | API-03-001, 002, 021, 022, 055, 074, 075 |
| UC-03-02 | UI-03-05, 12 | API-03-012, 016, 035 |
| UC-03-03 | — (xem lại ở UI-03-07, 09) | API-03-074, 084 |
| UC-03-04 | UI-03-05, 06 | API-03-029, 030 |
| UC-03-05 | UI-03-03, 07, 15, 16 | API-03-002, 009, 036, 039, 050, 051, 086, 087 |
| UC-03-06 | UI-03-03, 06 | API-03-005, 006, 010, 029 |
| UC-03-07 | UI-03-03 | API-03-002 |
| UC-03-08 | UI-03-01 | API-03-077 |
| UC-03-09 | UI-03-02, 03 | API-03-001, 002, 003, 004, 007 |
| UC-03-10 | UI-03-05 | API-03-053, 054 |
| UC-03-11 | UI-03-02, 05 | API-03-017, 018, 019, 020 |
| UC-03-12 | UI-03-15 | API-03-036, 037, 038 |
| UC-03-13 | UI-03-07, 17 | API-03-039, 040, 041, 071, 072, 073 |
| UC-03-14 | UI-03-07, 08, 17 | API-03-039, 042, 043, 044, 045, 046 |
| UC-03-15 | UI-03-08, 17 | API-03-047, 048, 049, 071, 072, 073 |
| UC-03-16 | UI-03-03, 17 | API-03-008, 071, 072, 073 |
| UC-03-17 | UI-03-12 | API-03-031…035, 068, 069, 070 |
| UC-03-18 | UI-03-01, 07 | API-03-084, 085 |
| UC-03-19 | UI-03-10 | API-03-056, 057, 058, 059 |
| UC-03-20 | UI-03-10, 11 | API-03-060, 063, 064 |
| UC-03-21 | UI-03-10 | API-03-056, 061, 062 |
| UC-03-22 | UI-03-11 | API-03-063, 064 |
| UC-03-23 | UI-03-04, 05 | API-03-011…015 |
| UC-03-24 | UI-03-13, 14 | API-03-065, 066, 067, 088 |
| UC-03-25 | UI-03-06, 17 | API-03-023…028, 071, 072, 073 |
| UC-03-26 | UI-03-09, 05 | API-03-074, 075, 076 |
| UC-03-27 | UI-03-01 | API-03-077, 078, 079, 089, 090 |
| UC-03-28 | UI-03-01 | API-03-080, 081, 082, 083 |
| UC-03-29 | UI-03-16 | API-03-086, 087 |
| UC-03-30 | UI-03-16 | API-03-094, 095, 096 |
| UC-03-31 | UI-03-18 | API-03-091, 092, 093 |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Cột "Quy trình" dùng tên quy trình ở FRS §2.5 kèm mã BP của D02-01 khi có; cột "LGC" ghi chức năng hệ cũ ở D00-03 phần A mà use case thay thế hoặc nâng cấp. "Không" nghĩa là chức năng mới của Datahub, không có bản tương ứng ở hệ cũ.

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-03-01 | REQ-03 | Công bố → phục vụ lượt gọi | LGC-APIM-011; 012, 013, 014, 015, 022; LGC-BUS-041 |
| UC-03-02 | REQ-03, REQ-12 | Kết nạp HTTT (BP-01) | LGC-APIM-011; LGC-BUS-041 |
| UC-03-03 | REQ-03, REQ-20 | Sự cố ATTT (BP-07) | Không |
| UC-03-04 | REQ-03 | Vận hành lượt gọi | LGC-APIM-012; 013; LGC-NFR-006 |
| UC-03-05 | REQ-03 | Xử lý cảnh báo giả của WAF | LGC-APIM-015; phần WAF không có ở hệ cũ |
| UC-03-06 | REQ-03 | Vận hành lượt gọi | LGC-APIM-018; LGC-NFR-006 |
| UC-03-07 | REQ-03 | Công bố → phục vụ lượt gọi | Không |
| UC-03-08 | REQ-03 | Vận hành lượt gọi | LGC-NFR-006 |
| UC-03-09 | REQ-03, REQ-02 | Công bố API (PH-02) | LGC-APIM-005; 017 |
| UC-03-10 | REQ-03, REQ-12 | Sự cố ATTT (BP-07) | Không |
| UC-03-11 | REQ-03 | Sự cố ATTT (BP-07) | LGC-APIM-005 |
| UC-03-12 | REQ-03 | Sự cố ATTT (BP-07) | Không |
| UC-03-13 | REQ-03 | Xử lý cảnh báo giả của WAF | Không |
| UC-03-14 | REQ-03 | Xử lý cảnh báo giả của WAF | Không |
| UC-03-15 | REQ-03 | Sự cố ATTT (BP-07) | Không |
| UC-03-16 | REQ-03, REQ-20 | Công bố API (PH-02) | Không |
| UC-03-17 | REQ-03 | Gia hạn chứng thư biên | LGC-BUS-041 |
| UC-03-18 | REQ-03, REQ-13 | Sự cố ATTT (BP-07) | Không |
| UC-03-19 | REQ-03 | Công bố API (PH-02) | LGC-APIM-011; 012, 013, 014, 015 |
| UC-03-20 | REQ-03 | Công bố API (PH-02) | Không |
| UC-03-21 | REQ-03 | Vận hành, sự cố cấu hình | Không |
| UC-03-22 | REQ-03, REQ-13 | Vận hành lượt gọi | LGC-APIM-023; 024, 025 |
| UC-03-23 | REQ-01, REQ-03 | Kết nạp HTTT (BP-01) | LGC-APIM-019; 020 |
| UC-03-24 | REQ-03 | Công bố API (PH-02) | LGC-APIM-015 |
| UC-03-25 | REQ-03, REQ-20 | Khởi tạo và quản trị tenant (BP-08) | LGC-APIM-012; 013 |
| UC-03-26 | REQ-03, REQ-13 | Sự cố ATTT, thanh tra (BP-07) | LGC-APIM-022 |
| UC-03-27 | REQ-03, REQ-13, REQ-16 | Giám sát, báo cáo (BP-07) | LGC-APIM-022; 026 |
| UC-03-28 | REQ-03, REQ-13 | Giám sát, báo cáo (BP-07) | Không |
| UC-03-29 | REQ-03, REQ-18 | Quản trị tenant (BP-08) | Không |
| UC-03-30 | REQ-20, REQ-03 | Sáp nhập tỉnh (BP-08) | Không |
| UC-03-31 | REQ-22 | Chuyển đổi từ hệ cũ (BP-09) | LGC-APIM-002…005, 009…015, 019…021 |

: Use case, REQ, quy trình và hệ cũ

## 6. Đặc tả chi tiết use case

Chương này đặc tả 31 use case theo sáu nhóm: lượt gọi qua gateway (6.1 đến 6.9), kiểm soát an ninh (6.10 đến 6.18), cấu hình và phát hành (6.19 đến 6.25), quan sát và quản trị (6.26 đến 6.29), chuyển đổi (6.30, 6.31). Số mục `6.n` trùng số `UC-03-nn`.

### 6.1. UC-03-01 · HTTT gọi API thành công qua gateway

::: dac-ta
**Mục tiêu.** Một HTTT đã đăng ký gọi được API của HTTT khác qua một điểm vào duy nhất, chỉ lượt gọi hợp lệ mới tới backend, và mọi lượt gọi để lại siêu dữ liệu truy vết được mà không lộ nội dung.

**Tác nhân chính.** HTTT gọi API (`HT-QLVB`, consumer `ht-qlvb`).

**Tác nhân phụ.** Keycloak (PH-12), Valkey, OPA sidecar, backend `HT-TUPHAP`, PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-001, 012, 013, 015, 016, 017, 019, 020, 021, 025, 028, 029, 032, 050, 052.

**Truy vết.** REQ-03; quy trình Công bố → phục vụ lượt gọi; LGC-APIM-011; 012, 013, 014, 015, 022; LGC-BUS-041.

**Tiền điều kiện.** Consumer `ht-qlvb` ở `ACTIVE`; `HT-QLVB` có đăng ký sử dụng còn hiệu lực với route `tra-cuu-ho-tich.v1` (gói chuẩn OAuth 2.1, 20 lượt/giây và 600 lượt/60 giây, đường dẫn cho phép `/ho-tich/*`); route ở `ACTIVE` ở cửa `INT` trong ảnh chụp đang chạy; OPA đã nạp gói chính sách của route; client có phạm vi `hotich.read`.

**Kích hoạt.** `HT-QLVB` gửi `GET https://api.t68.datahub.gov.vn/api/hotich/v1/ho-tich/123` kèm `Authorization: Bearer …` và `traceparent`.

**Đảm bảo tối thiểu.** Lượt gọi bị từ chối ở bất kỳ chốt nào không tới backend; nhật ký chỉ có siêu dữ liệu, không có thân bản tin, giá trị tiêu đề `Authorization` hay giá trị tham số truy vấn (BR-03-007).

**Đảm bảo thành công.** Backend nhận đúng một yêu cầu mang `X-DH-Tenant: T68`, `X-DH-Consumer: ht-qlvb`, `traceparent`; bên gọi nhận phản hồi `200` kèm `X-Trace-Id` và `X-RateLimit-*`; một bản ghi siêu dữ liệu `status = 200` ở PH-13.

**Luồng chính.**

1. `HT-QLVB` lấy token `client_credentials` từ realm `dh-t68` của Keycloak (ngoài PH-03) rồi gửi yêu cầu tới `apisix-int`. Gateway kết thúc TLS 1.3 và chọn host của T68 theo SNI (FR-03-001).
2. Gateway xác minh chữ ký token bằng JWKS đã đệm, kiểm `iss`, `aud`, `exp` với dung sai đồng hồ 30 giây; không gọi Keycloak cho lượt gọi này (FR-03-012).
3. Gateway xóa mọi tiêu đề `X-DH-*` do bên gọi gửi, đối chiếu claim `tenant = T68` với realm `dh-t68` và với tenant của route, rồi đặt `X-DH-Tenant`, `X-DH-Client`, `X-DH-Consumer` (FR-03-013).
4. Gateway kiểm tra phương thức bảo mật của lượt gọi (OAuth 2.1) khớp gói, rồi kiểm tra consumer `ht-qlvb` có đăng ký hiệu lực với route (FR-03-015, 016).
5. Gateway kiểm tra token có phạm vi `hotich.read` và đường dẫn `/ho-tich/123` nằm trong danh sách cho phép của gói (FR-03-017, 020).
6. Gateway tăng bộ đếm ở Valkey cho khóa `T68:rl:ht-qlvb:tra-cuu-ho-tich.v1:1`; còn 19 trên 20 lượt (FR-03-021).
7. Gateway gọi OPA cục bộ với `tenant`, `consumer`, `scopes`, `method`, `path`, `apiClassification`; OPA trả `allow` trong dưới 50 ms (FR-03-019).
8. Gateway khớp route theo host, đường dẫn, phương thức, chọn một nút khỏe của upstream, gắn `traceparent` rồi chuyển tiếp qua mTLS của mesh (FR-03-028, 029, 032).
9. Backend trả `200`. Gateway trả cho `HT-QLVB` kèm `X-Trace-Id`, `X-RateLimit-Limit: 20`, `X-RateLimit-Remaining: 19`, `X-RateLimit-Reset` (FR-03-025).
10. Gateway ghi bản ghi siêu dữ liệu (`ts`, `tenant`, `traceId`, `routeCode`, `consumerCode`, `status`, `latencyMs`, `authResult`, `limitResult`, `opaResult`) vào bộ đệm đĩa rồi gửi PH-13, và phát chỉ số, vết OpenTelemetry (FR-03-050, 052).

**Luồng thay thế.**

- **2a. Route công khai dữ liệu mở (`KEYLESS`).** Gateway không yêu cầu token; bước 2 đến 5 và 6 theo consumer được bỏ qua, hạn mức theo địa chỉ nguồn vẫn áp dụng; OPA vẫn được gọi để có nhật ký quyết định; `consumerCode` trong nhật ký để trống (FR-03-015, 050).
- **5a. Consumer thuộc nhóm `ESSENTIAL`.** Hạn mức tần suất ở bước 6 được nhân hệ số 1,5 (`gw.rate.essentialFactor`), tức tối đa 30 lượt/giây (FR-03-021).
- **8a. Lượt gọi đến từ giao diện.** BFF của `dh-console` gọi gateway bằng token của người dùng; mọi bước giống `HT-QLVB`, tenant lấy từ token, không có đường riêng (FR-03-013).

**Luồng ngoại lệ.**

- **E1. Thiếu token (bước 2).** ERR-03-102 (401) kèm `WWW-Authenticate: Bearer realm="datahub"`; "Thiếu thông tin xác thực. Gửi token truy cập trong tiêu đề Authorization."
- **E2. Token sai chữ ký, `kid` lạ, `iss` hoặc `aud` sai (bước 2).** ERR-03-103 (401); "Token không hợp lệ. Lấy token mới từ máy chủ định danh."
- **E3. Token hết hạn (bước 2).** ERR-03-104 (401); "Token đã hết hạn. Lấy token mới rồi gọi lại."
- **E4. Phương thức xác thực sai gói (bước 4).** ERR-03-130 (403); "API này yêu cầu xác thực bằng OAuth 2.1. Phương thức bạn dùng không được chấp nhận."
- **E5. Chưa đăng ký hoặc đăng ký hết hiệu lực (bước 4).** ERR-03-111 (403); "HTTT của bạn chưa đăng ký sử dụng API này hoặc đăng ký đã hết hiệu lực. Liên hệ chủ dịch vụ hoặc quản trị Datahub."
- **E6. HTTT đang bị tạm ngừng (bước 4).** ERR-03-127 (403); "HTTT của bạn đang bị tạm ngừng truy cập. Liên hệ quản trị Datahub."
- **E7. Thiếu phạm vi (bước 5).** ERR-03-107 (403); "Token thiếu phạm vi quyền hotich.read. Xin cấp thêm phạm vi này cho HTTT của bạn."
- **E8. Đường dẫn bị chặn hoặc ngoài gói (bước 5).** ERR-03-113 (403); "Đường dẫn này không nằm trong phạm vi gói sử dụng của HTTT của bạn."
- **E9. Vượt tần suất (bước 6).** ERR-03-116 (429) kèm `Retry-After`; xem UC-03-04.
- **E10. OPA từ chối (bước 7).** ERR-03-112 (403); "Yêu cầu không được phép theo chính sách truy cập. {lý do}. Liên hệ chủ quản dữ liệu nếu cần cấp quyền."
- **E11. OPA không phản hồi trong 50 ms hoặc JWKS đệm quá 24 giờ (bước 2, 7).** Đóng an toàn, ERR-03-124 (503) kèm `Retry-After: 30`; "Dịch vụ ủy quyền tạm thời không khả dụng. Thử lại sau."
- **E12. Không có route khớp, route `PENDING`, hoặc phương thức không cho phép (bước 8).** ERR-03-114 (404, hoặc 405 kèm `Allow`); "Không tìm thấy dịch vụ hoặc đường dẫn."
- **E13. Mọi lỗi trên.** Gateway vẫn ghi bản ghi siêu dữ liệu với `errorCode` tương ứng, các trường sau chốt lỗi để trống (bước 10); người vận hành tra theo `traceId` ở UC-03-26.

**Quy tắc áp dụng.** BR-03-001, 002, 004, 005, 007, 008, 014, 023, 024.

**Màn hình, API.** Không có màn thao tác; xem lại ở UI-03-09. API-03-001, 002, 021, 022, 055, 074, 075.
:::

### 6.2. UC-03-02 · Gọi API bằng mTLS và token ràng buộc chứng thư

::: dac-ta
**Mục tiêu.** HTTT làm việc với dữ liệu mức Hạn chế hoặc Nhạy cảm chỉ gọi được khi cùng xuất trình chứng thư khách đã đăng ký và token gắn với đúng chứng thư đó, để token bị lộ riêng lẻ không dùng được.

**Tác nhân chính.** HTTT gọi API (`HT-TUPHAP`, consumer `ht-tuphap`, xác thực `MTLS`).

**Tác nhân phụ.** Bộ CA tin cậy của cửa vào, danh sách thu hồi chứng thư (CRL), PH-12.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-002, 014, 015.

**Truy vết.** REQ-03, REQ-12; quy trình Kết nạp HTTT (BP-01); LGC-APIM-011; LGC-BUS-041.

**Tiền điều kiện.** Consumer `ht-tuphap` có vân tay SHA-256 chứng thư khách trong thông tin xác thực công khai (đồng bộ ở UC-03-23); route `tra-cuu-cong-dan.v1` khai `requireMtls = true`; chứng thư khách do CA nằm trong bộ CA tin cậy cấp, còn hạn.

**Kích hoạt.** `HT-TUPHAP` bắt tay TLS 1.3 tới `api.t68.datahub.gov.vn`, xuất trình chứng thư khách, gửi token có claim `cnf.x5t#S256`.

**Đảm bảo tối thiểu.** Lượt gọi thiếu hoặc sai chứng thư không tới backend và không lộ lý do chi tiết cho bên gọi; gateway không giữ khóa riêng của client.

**Đảm bảo thành công.** Gateway xác nhận chuỗi chứng thư hợp lệ, vân tay chứng thư khớp `cnf` của token và vân tay đã đăng ký; lượt gọi đi tiếp như UC-03-01 từ bước kiểm tra phạm vi.

**Luồng chính.**

1. `HT-TUPHAP` bắt tay TLS 1.3 và xuất trình chứng thư khách. Gateway kiểm tra chuỗi tới CA tin cậy, thời hạn, và trạng thái thu hồi (FR-03-002).
2. Gateway tính vân tay SHA-256 của chứng thư và giữ cho các chốt sau.
3. Gateway xác minh token như UC-03-01 bước 2, 3, rồi đối chiếu `cnf.x5t#S256` của token với vân tay chứng thư của kết nối (FR-03-014).
4. Gateway đối chiếu vân tay đó với danh sách vân tay đã đăng ký cho consumer `ht-tuphap` (tối đa hai vân tay trong giai đoạn xoay chứng thư).
5. Gateway kiểm tra phương thức xác thực của lượt gọi (`MTLS` kèm token) khớp phương thức của gói (FR-03-015).
6. Gateway tiếp tục kiểm tra đăng ký, phạm vi, hạn mức, OPA, định tuyến như UC-03-01 bước 4 đến 10.

**Luồng thay thế.**

- **4a. Xoay chứng thư.** `HT-TUPHAP` đổi sang chứng thư mới trong giai đoạn chuyển giao: PH-01 đã thêm vân tay mới vào danh sách của consumer (UC-03-23) nên cả chứng thư cũ lẫn mới đều qua; sau khi chuyển xong PH-01 gỡ vân tay cũ.
- **1a. Route không yêu cầu mTLS.** Gateway bỏ qua bước 1 đến 4 và dùng xác thực OAuth 2.1 thường (UC-03-01).

**Luồng ngoại lệ.**

- **E1. Không xuất trình chứng thư ở route yêu cầu mTLS, hoặc chuỗi, hạn, thu hồi không đạt (bước 1).** ERR-03-108 (403); "Chứng thư của HTTT không hợp lệ hoặc không được phép. Kiểm tra chứng thư và liên hệ quản trị Datahub."
- **E2. Gateway không đọc được CRL quá 24 giờ (bước 1).** Đóng an toàn: từ chối mọi chứng thư của CA đó với ERR-03-108 và phát cảnh báo Nghiêm trọng cho PA (UC-03-18).
- **E3. Token không có `cnf` hoặc `cnf` không khớp chứng thư (bước 3).** ERR-03-108 (403); "Token không đi cùng chứng thư đã đăng ký của HTTT. Gọi lại bằng đúng chứng thư." Từ ba lượt trong 10 phút, luật GW-A04 phát cảnh báo Nghiêm trọng cho SO.
- **E4. Chứng thư mới chưa có trong danh sách vân tay đã đăng ký (bước 4).** ERR-03-108 như E3; PH-01 phải cập nhật vân tay trước khi HTTT chuyển chứng thư.
- **E5. Phương thức xác thực sai gói (bước 5).** ERR-03-130 (403); "API này yêu cầu xác thực bằng chứng thư mTLS. Phương thức bạn dùng không được chấp nhận."

**Quy tắc áp dụng.** BR-03-003, 004, 014, 022.

**Màn hình, API.** UI-03-05 (thông tin xác thực công khai), UI-03-12 (bộ CA khách); API-03-012, 016, 035.
:::

### 6.3. UC-03-03 · Chặn lượt gọi chéo tenant và tiêu đề nội bộ giả

::: dac-ta
**Mục tiêu.** Không HTTT nào đọc được dữ liệu của tỉnh khác bằng cách dùng token của tỉnh mình hoặc tự khai tiêu đề `X-DH-*`; mọi nỗ lực như vậy bị chặn và báo cho Cán bộ ATTT.

**Tác nhân chính.** HTTT gọi API (ví dụ `ht-tinhkhac` của tenant `T70`, hoặc kẻ giả mạo).

**Tác nhân phụ.** PH-13 (SIEM), SO của T68.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-012, 013, 050.

**Truy vết.** REQ-03, REQ-20; quy trình Sự cố ATTT (BP-07); chức năng mới (SEC-80).

**Tiền điều kiện.** Route `tra-cuu-ho-tich.v1` thuộc tenant `T68`; bảng ánh xạ host với tenant có trong ảnh chụp đang chạy; luật cảnh báo GW-A03 đã cài ở PH-13.

**Kích hoạt.** Một client có token hợp lệ của realm `dh-t70` gửi yêu cầu tới `api.t68.datahub.gov.vn`, kèm tiêu đề giả `X-DH-Tenant: T68`.

**Đảm bảo tối thiểu.** Backend của T68 không nhận lượt gọi nào mang tenant do bên gọi tự khai; phản hồi không tiết lộ đối tượng của tenant khác có tồn tại hay không (BR-03-028).

**Đảm bảo thành công.** Lượt gọi bị chặn với `401`; sự kiện an ninh "truy cập chéo tenant" được ghi và cảnh báo Nghiêm trọng tới SO trong tối đa 5 phút.

**Luồng chính.**

1. Gateway kết thúc TLS và xác minh chữ ký token của realm `dh-t70`; chữ ký hợp lệ (FR-03-012).
2. Gateway xóa tiêu đề `X-DH-Tenant: T68` do bên gọi gửi, cùng mọi tiêu đề `X-DH-*` khác (FR-03-013).
3. Gateway đối chiếu claim `tenant = T70` với realm `dh-t70` (khớp), rồi với tenant của route là `T68` (không khớp).
4. Gateway trả `401` ERR-03-106 và không chuyển tiếp lượt gọi.
5. Gateway ghi sự kiện an ninh gồm tenant của token, tenant của route, client, địa chỉ nguồn, `traceId`, rồi phát EVT-03-09 (FR-03-013, 050).
6. PH-13 đánh giá luật GW-A03 (có bất kỳ lượt ERR-03-106 do route khác tenant), tạo cảnh báo Nghiêm trọng và thông báo cho SO của T68 (xem UC-03-18).
7. Bản ghi siêu dữ liệu của lượt gọi có `status = 401`, `errorCode = ERR-03-106`; SO tra theo `traceId` ở UC-03-26.

**Luồng thay thế.**

- **3a. Token hợp lệ của T68 nhưng bên gọi tự gửi `X-DH-Tenant: T70`.** Tiêu đề giả đã bị xóa ở bước 2; gateway đặt `X-DH-Tenant: T68` từ token; lượt gọi đi tiếp như UC-03-01 và không phát sinh lỗi. Backend chỉ thấy tenant do gateway chứng thực.
- **3b. Route dùng chung `COMMON` (ví dụ danh mục quốc gia).** Gateway chấp nhận token của mọi realm tenant hợp lệ và lấy tenant từ token; bước 3 không báo lỗi.

**Luồng ngoại lệ.**

- **E1. Tenant của token không khớp realm hoặc route (bước 3).** ERR-03-106 (401); "Token không thuộc tỉnh của API này. Lấy token từ máy chủ định danh của đúng tỉnh."
- **E2. Host không thuộc tenant nào (bước 3).** ERR-03-114 (404); "Không tìm thấy dịch vụ."
- **E3. Chữ ký token sai (bước 1).** ERR-03-103 (401); "Token không hợp lệ. Lấy token mới từ máy chủ định danh." Không tính là truy cập chéo tenant vì chưa xác minh được danh tính.
- **E4. PH-13 không khả dụng (bước 6).** Gateway vẫn chặn lượt gọi; sự kiện nằm ở bộ đệm đĩa và gửi lại sau; cảnh báo chỉ phát được khi PH-13 trở lại.

**Quy tắc áp dụng.** BR-03-002, 007, 023, 026, 028.

**Màn hình, API.** Không có màn thao tác; sự kiện xem ở UI-03-07, UI-03-09. API-03-074, 084.
:::

### 6.4. UC-03-04 · Vượt hạn mức, hạn ngạch và cảnh báo ngưỡng

::: dac-ta
**Mục tiêu.** Mỗi HTTT chỉ dùng API trong phần đã khai ở gói; khi vượt thì nhận lời giải thích đúng tầng và biết chờ bao lâu; khi sắp hết hạn ngạch thì đầu mối được báo trước.

**Tác nhân chính.** HTTT gọi API (`HT-QLVB`).

**Tác nhân phụ.** Valkey, `dh-connect` (tác vụ đọc mức dùng mỗi 5 phút), đầu mối HTTT, TA.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-021, 022, 025.

**Truy vết.** REQ-03; quy trình Vận hành lượt gọi; LGC-APIM-012; 013; LGC-NFR-006.

**Tiền điều kiện.** Gói của `HT-QLVB` ở route `tra-cuu-ho-tich.v1` có hạn mức 20 lượt/giây (`burst` = 0 trong ví dụ), 600 lượt/60 giây và hạn ngạch 50.000 lượt/ngày; Valkey truy cập được.

**Kích hoạt.** `HT-QLVB` gửi 25 lượt gọi trong cùng một giây, hoặc tổng lượt gọi trong ngày chạm 40.000.

**Đảm bảo tối thiểu.** Lượt bị từ chối không tới backend và không làm tăng tải của HTTT khác; hạn mức tính theo HTTT, không theo địa chỉ IP (BR-03-005); hạn ngạch không dùng để tính tiền (BR-03-020).

**Đảm bảo thành công.** Hai mươi lượt đầu qua; năm lượt sau nhận `429` đúng mã; đầu mối `HT-QLVB` và TA nhận thông báo khi dùng 80% hạn ngạch ngày.

**Luồng chính.**

1. Với mỗi lượt gọi đã qua đăng ký, gateway tăng bộ đếm cửa sổ trượt cho khóa `T68:rl:ht-qlvb:tra-cuu-ho-tich.v1:1` và `…:60` (FR-03-021).
2. Hai mươi lượt đầu trong giây còn hạn mức; phản hồi mang `X-RateLimit-Limit: 20` và `X-RateLimit-Remaining` giảm dần (FR-03-025).
3. Lượt thứ 21 vượt giới hạn: gateway từ chối ngay, không tới backend, trả `429` ERR-03-116 kèm `Retry-After: 1`, thân RFC 9457 có `retryAfterSeconds`, `limit`, `windowSeconds` (FR-03-021, 025).
4. Hạn ngạch ngày tăng theo từng lượt đi qua với khóa `T68:quota:ht-qlvb:tra-cuu-ho-tich.v1:DAY:20261126`; phản hồi có thêm `X-Quota-Remaining` (FR-03-022).
5. Mỗi 5 phút `dh-connect` đọc bộ đếm hạn ngạch; khi `HT-QLVB` lần đầu đạt 80% (40.000 lượt) trong ngày, hệ thống phát EVT-03-07 và gửi thông báo trong ứng dụng cho đầu mối `HT-QLVB` và Lan (tuân thủ FR-00-060).
6. Khi đạt 100%, hệ thống phát EVT-03-07 thêm một lần; lượt gọi sau đó bị từ chối `429` ERR-03-117 kèm `Retry-After` và `X-Quota-Reset`.
7. Sang 00:00 ngày 27/11/2026 (múi giờ `Asia/Ho_Chi_Minh`) khóa mới được tạo; bộ đếm bắt đầu lại từ 0.

**Luồng thay thế.**

- **3a. `HT-QLVB` thuộc nhóm `ESSENTIAL`.** Hạn mức tần suất tối đa 30 lượt/giây (hệ số 1,5); khi vượt hạn ngạch ngày, gateway vẫn cho qua kèm cảnh báo cho tới khi vượt 20% hạn ngạch (60.000 lượt) rồi mới chặn (BR-03-009).
- **3b. Route không có hạn mức.** Phản hồi không có tiêu đề `X-RateLimit-*` (FR-03-025).
- **6a. Đối tác có thỏa thuận riêng.** PH-02 cấp gói riêng với hạn ngạch cao hơn; gateway không có logic riêng.

**Luồng ngoại lệ.**

- **E1. Vượt tần suất (bước 3).** ERR-03-116 (429); "HTTT ht-qlvb đã dùng hết 20 lượt trong 1 giây cho API tra-cuu-ho-tich.v1. Thử lại sau 1 giây."
- **E2. Vượt hạn ngạch (bước 6).** ERR-03-117 (429); "HTTT ht-qlvb đã dùng hết hạn ngạch 50.000 lượt/ngày cho API tra-cuu-ho-tich.v1. Hạn ngạch đặt lại lúc 00:00 27/11/2026."
- **E3. Valkey không khả dụng (bước 1).** Gateway không từ chối vì lý do này: tần suất đếm cục bộ, hạn ngạch mở có cảnh báo, phản hồi mang `X-RateLimit-Degraded: true`; xem UC-03-08.
- **E4. Thông báo không gửi được (bước 5).** Sự kiện EVT-03-07 nằm ở outbox và phát khi Kafka trở lại; gateway không bị ảnh hưởng.

**Quy tắc áp dụng.** BR-03-005, 009, 020, 023, 024.

**Màn hình, API.** UI-03-05 (tab Hạn mức và mức dùng), UI-03-06; API-03-029, 030.
:::

### 6.5. UC-03-05 · Bên ngoài gọi qua cửa Internet có WAF và kiểm tra lược đồ

::: dac-ta
**Mục tiêu.** Lượt gọi từ Internet tới những API được phép mở (callback của nhà cung cấp thanh toán, cổng nhà phát triển) bị lọc bởi chuỗi chốt rẻ trước đắt sau: giới hạn theo địa chỉ, kích thước, WAF, lược đồ, rồi mới tới xác thực.

**Tác nhân chính.** Bên gọi từ Internet (ví dụ máy chủ của nhà cung cấp thanh toán gọi `POST /api/payment/v1/ipn`).

**Tác nhân phụ.** `apisix-ext` (vùng Z1), Coraza WAF, OPA, backend của PH-19.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-001, 003, 005, 009, 010, 011.

**Truy vết.** REQ-03; quy trình Xử lý cảnh báo giả của WAF; LGC-APIM-015; WAF và chống tràn không có ở hệ cũ (CMP-LAW-09, CMP-LAW-08).

**Tiền điều kiện.** Route `thanh-toan-ipn.v1` ở cửa `EXT` đã được SO duyệt (UC-03-16), có lược đồ OpenAPI và `ipAllowCidrs` của nhà cung cấp; WAF ở chế độ `BLOCK`, mức hoang tưởng 1 cho API máy; `gw.body.maxBytes` = 1 MiB.

**Kích hoạt.** Máy chủ nhà cung cấp gửi `POST https://api.t68.datahub.gov.vn/api/payment/v1/ipn` từ địa chỉ `203.0.113.25`.

**Đảm bảo tối thiểu.** Lượt gọi độc hại bị cắt ở chốt sớm nhất có thể; thông báo lỗi không nêu mã luật WAF hay lược đồ nội bộ; không thân yêu cầu nào được ghi vào nhật ký (BR-03-007).

**Đảm bảo thành công.** Yêu cầu sạch qua đủ chốt, tới xác thực và backend; phản hồi mang tiêu đề bảo mật và không lộ phiên bản máy chủ.

**Luồng chính.**

1. Gateway xác định địa chỉ nguồn thật từ giao thức PROXY, kiểm tra thuộc `ipAllowCidrs` của route và đếm kết nối, tốc độ: tối đa 100 kết nối đồng thời và 200 yêu cầu/giây cho mỗi địa chỉ (FR-03-003).
2. Gateway so `Content-Length` với giới hạn 1 MiB của route (FR-03-009).
3. Coraza chạy bộ luật OWASP CRS ở mức hoang tưởng 1, cộng điểm bất thường; tổng điểm dưới ngưỡng 5 nên yêu cầu đi tiếp (FR-03-005).
4. Gateway xác thực token hoặc chữ ký theo gói và qua các chốt như UC-03-01 bước 2 đến 7.
5. Sau xác thực, plugin `request-validation` kiểm tra thân JSON theo lược đồ OpenAPI: độ sâu không quá 32, mảng không quá 10.000 phần tử, `Content-Type` thuộc danh sách khai báo (FR-03-009).
6. Gateway chuyển tiếp tới backend; phản hồi được xóa `Server`, `X-Powered-By`, thêm `Strict-Transport-Security`, `X-Content-Type-Options`, `Referrer-Policy`, `X-Trace-Id` (FR-03-011).
7. Gateway ghi siêu dữ liệu và chỉ số `dh_gateway_waf_duration_seconds`; chỉ ghi tên tham số truy vấn, không ghi giá trị.

**Luồng thay thế.**

- **3a. Route thân là tệp nhị phân đã kiểm lược đồ.** PA duyệt `skipBody = true` nên WAF chỉ quét tiêu đề và tham số (FR-03-005).
- **4a. Trình duyệt của cổng nhà phát triển gọi từ `https://portal.t68.gov.vn`.** Gateway trả `204` cho `OPTIONS` với `Access-Control-Allow-Origin` đúng nguồn gốc đã khai; nguồn gốc lạ không nhận tiêu đề CORS và trình duyệt tự chặn (FR-03-010, mức S, Đợt 2).
- **1a. Địa chỉ thuộc danh sách tin cậy (NDXP, bộ giám sát tổng hợp).** Miễn giới hạn theo địa chỉ ở bước 1; hạn mức theo HTTT vẫn áp dụng.

**Luồng ngoại lệ.**

- **E1. Vượt kết nối hoặc tốc độ theo địa chỉ (bước 1).** ERR-03-119 (429) kèm `Retry-After`; "Quá nhiều yêu cầu từ địa chỉ của bạn trong thời gian ngắn. Thử lại sau {n} giây." Mỗi lần từ chối cộng vào bộ đếm của UC-03-12.
- **E2. Đọc tiêu đề hoặc thân quá chậm (bước 1).** Gateway đóng kết nối sau 10 giây (tiêu đề) hoặc 30 giây (thân); bên gọi không nhận phản hồi HTTP; chỉ số `dh_gateway_slow_client_total` tăng.
- **E3. Thân quá lớn (bước 2).** ERR-03-115 (413); "Nội dung gửi lên vượt giới hạn 1 MiB của API này. Giảm kích thước hoặc dùng kênh tải tệp."
- **E4. WAF chặn (bước 3).** ERR-03-109 (403); "Yêu cầu bị từ chối bởi tường lửa ứng dụng. Nếu bạn cho rằng đây là nhầm lẫn, gửi mã truy vết {traceId} cho quản trị Datahub." Sự kiện (mã luật, điểm, route, `traceId`, đoạn khớp đã che) hiện ở UI-03-07.
- **E5. Sai lược đồ, JSON quá sâu, XML có DTD, `Content-Type` sai (bước 5).** ERR-03-101 (400); "Yêu cầu không đúng định dạng: {danh sách lỗi theo trường}."
- **E6. Route chỉ ở cửa `INT` nhưng bị gọi từ Internet.** ERR-03-114 (404); "Không tìm thấy dịch vụ hoặc đường dẫn." (như không tồn tại).
- **E7. Lỗi nội bộ gateway (bất kỳ bước).** ERR-03-129 (500); "Hệ thống gặp sự cố. Gửi mã truy vết {traceId} cho quản trị Datahub."
- **E8. Cảnh báo giả của WAF.** Vận hành thấy lượt hợp lệ bị chặn ở E4 thì đề nghị ngoại lệ có thời hạn (UC-03-14).

**Quy tắc áp dụng.** BR-03-001, 005, 007, 012, 013, 014, 015, 023.

**Màn hình, API.** UI-03-03, 07, 15, 16; API-03-002, 009, 036, 039, 050, 051, 086, 087.
:::

### 6.6. UC-03-06 · Gateway bảo vệ khi backend lỗi

::: dac-ta
**Mục tiêu.** Một backend chậm hoặc hỏng không làm treo gateway và không kéo theo các HTTT khác: nút hỏng bị loại, lỗi trả về nhanh, lưu lượng ưu tiên thấp bị giảm để nhường cho dịch vụ thiết yếu.

**Tác nhân chính.** APISIX (mặt phẳng dữ liệu).

**Tác nhân phụ.** Backend của route `gui-van-ban.v1` (hai nút), TO (nhận cảnh báo), PH-13.

**Mức ưu tiên.** M · MVP (điều tiết theo tình trạng backend ở Đợt 2).

**FR hiện thực.** FR-03-027, 029, 030, 031.

**Truy vết.** REQ-03; quy trình Vận hành lượt gọi; LGC-APIM-018; LGC-NFR-006; Q03-03.

**Tiền điều kiện.** Upstream `qlvb-backend` có hai nút `10.1.4.7:8080` và `10.1.4.8:8080`, kiểm tra sức khỏe `/readyz` mỗi 5 giây; route có thời hạn chờ kết nối 3.000 ms, đọc 10.000 ms; ngắt mạch 5 lỗi liên tiếp, mở 10 giây; consumer có nhóm ưu tiên `ESSENTIAL`, `NORMAL` hoặc `LOW`.

**Kích hoạt.** Nút `10.1.4.8` ngừng trả lời lúc 09:20, sau đó cả hai nút cùng lỗi.

**Đảm bảo tối thiểu.** Gateway không thử lại lượt gọi đã gửi thân hoặc phương thức không an toàn (`POST`, `PUT`, `PATCH`, `DELETE`) để tránh thực hiện hai lần; trạng thái mạch và sức khỏe nằm ở bộ nhớ từng nút, không ảnh hưởng cấu hình lưu.

**Đảm bảo thành công.** Nút hỏng bị loại trong tối đa 15 giây và lượt gọi chuyển sang nút còn lại không lỗi; khi mọi nút hỏng, lượt gọi nhận `503` nhanh thay vì chờ hết thời hạn; hạn mức tự hồi phục khi backend ổn định.

**Luồng chính.**

1. Gateway gọi `/readyz` của từng nút mỗi 5 giây; nút `10.1.4.8` thất bại 3 lần liên tiếp (15 giây) bị đánh dấu không khỏe và loại khỏi vòng; lượt gọi chuyển hết sang `10.1.4.7` (FR-03-029, 030).
2. Kiểm tra thụ động bổ sung: nút trả `5xx` hoặc lỗi kết nối quá ngưỡng trong cửa sổ cũng bị loại (FR-03-030).
3. Nút còn lại cũng hỏng: plugin `api-breaker` đếm 5 lỗi liên tiếp thì mở mạch; mọi lượt gọi tiếp theo nhận ngay `503` ERR-03-120 kèm `Retry-After` bằng thời gian mở còn lại (FR-03-031).
4. Sau 10 giây mạch nửa mở, cho một lượt thăm dò đi qua; thất bại thì mở lại với thời gian gấp đôi, tối đa 60 giây (FR-03-031).
5. Khi tỉ lệ lỗi hoặc độ trễ p95 của upstream vượt ngưỡng (20% hoặc gấp 3 lần mức nền 24 giờ, với ít nhất 30 lượt trong 1 phút), plugin `dh-adaptive-throttle` nhân hạn mức nhóm `LOW` với 0,5; còn vượt sau 1 phút thì nhóm `NORMAL` nhân 0,75 và `LOW` nhân 0,25; nhóm `ESSENTIAL` giữ nguyên (FR-03-027).
6. Gateway phát EVT-03-09 khi mạch mở lần đầu trong 10 phút và khi bắt đầu điều tiết; luật GW-A11 và cảnh báo Cao tới Chi (TO) (xem UC-03-18).
7. Khi backend ổn định 2 phút liên tục, hệ số điều tiết tăng dần mỗi 30 giây thêm 0,1 tới 1,0; nút phục hồi đạt 2 lần kiểm tra liên tiếp thì được đưa lại vòng (FR-03-027, 030).

**Luồng thay thế.**

- **1a. Backend của HTTT ngoài không có `/readyz`.** PA chọn kiểm tra TCP hoặc chỉ dùng kiểm tra thụ động (FR-03-030).
- **3a. Backend chậm nhưng hợp lệ (báo cáo lớn).** PA tăng `readMs` cho riêng route, không quá 30.000 ms (trần của Công văn 631) (FR-03-031).
- **5a. Backend không phản hồi hoàn toàn.** Bỏ qua điều tiết, chuyển sang ngắt mạch trả lỗi nhanh (FR-03-027).

**Luồng ngoại lệ.**

- **E1. Mọi nút không khỏe (bước 1).** ERR-03-120 (503) kèm `Retry-After: 5`; "Dịch vụ tạm thời không khả dụng. Thử lại sau 5 giây." Cảnh báo Cao.
- **E2. Quá hạn chờ đọc (bước 3).** ERR-03-121 (504); "Dịch vụ phía sau không phản hồi kịp. Thử lại; nếu lặp lại, gửi mã truy vết {traceId} cho quản trị."
- **E3. Mạch đang mở (bước 3).** ERR-03-120 (503) kèm `Retry-After`; "Dịch vụ đang được bảo vệ vì lỗi liên tiếp. Thử lại sau {s} giây."
- **E4. Backend trả phản hồi sai giao thức (bước 2).** ERR-03-122 (502); "Dịch vụ phía sau trả về phản hồi không hợp lệ."
- **E5. Bị điều tiết (bước 5).** ERR-03-116 (429) kèm `X-DH-Throttled: true`; "Dịch vụ gui-van-ban.v1 đang quá tải nên hạn mức của HTTT bạn tạm giảm. Thử lại sau {s} giây."
- **E6. Dưới 30 lượt trong 1 phút (bước 5).** Không điều tiết để tránh quyết định theo ít dữ liệu.
- **E7. Chủ dịch vụ muốn giữ lưu lượng vào backend duy nhất dù lỗi cao.** Hệ mới không làm vậy (khác SRS cũ); xem câu hỏi mở Q03-03 ở FRS và Q03-45.

**Quy tắc áp dụng.** BR-03-009, 011, 023.

**Màn hình, API.** UI-03-03 (tab Backend và sức khỏe), UI-03-06 (hệ số điều tiết); API-03-005, 006, 010, 029.
:::

### 6.7. UC-03-07 · Dùng WebSocket và chuyển đổi gRPC

::: dac-ta
**Mục tiêu.** HTTT dùng được API kết nối dài (WebSocket) và nén nội dung với cùng mức bảo vệ như API thường; khi có nhu cầu thật, gọi dịch vụ gRPC bằng REST/JSON mà không tự viết lớp chuyển đổi.

**Tác nhân chính.** HTTT gọi API (`HT-BAOCAO`, consumer `ht-baocao`).

**Tác nhân phụ.** Backend của route `bao-cao-truc-tuyen.v1` (WebSocket), backend gRPC (Đợt 3).

**Mức ưu tiên.** M (WebSocket, nén) · C (gRPC, Đợt 3).

**FR hiện thực.** FR-03-033, 034.

**Truy vết.** REQ-03; quy trình Công bố → phục vụ lượt gọi; yêu cầu mới theo CMP-LAW-09 (HTTP, HTTPS, WebSocket).

**Tiền điều kiện.** Route khai báo `protocols` gồm `wss` và nén `gzip`; consumer đã có đăng ký hiệu lực; `gw.ws.maxPerConsumer` = 50, `gw.ws.idleTimeoutSeconds` = 120. Nhánh gRPC: có bộ `.proto` đã duyệt ở PH-02 và plugin `grpc-transcode` thuộc danh mục được duyệt (Đợt 3).

**Kích hoạt.** `HT-BAOCAO` gửi yêu cầu `Upgrade: websocket` tới `wss://api.t68.datahub.gov.vn/api/baocao/v1/stream`.

**Đảm bảo tối thiểu.** Kết nối WebSocket qua đủ chuỗi chốt lúc bắt tay; kết nối chỉ được mở khi mọi chốt cho qua; không dữ liệu nào bị ghi vào nhật ký.

**Đảm bảo thành công.** Khung dữ liệu chuyển hai chiều; kết nối nhàn rỗi bị đóng đúng hạn; phản hồi HTTP trên 1 KiB được nén khi bên gọi yêu cầu.

**Luồng chính.**

1. Gateway nhận yêu cầu `Upgrade` ở route cho phép WebSocket và chạy đủ chuỗi chốt (TLS, WAF theo tiêu đề, xác thực, hạn mức, OPA) ở lúc bắt tay (FR-03-033).
2. Gateway chuyển tiếp nâng cấp tới backend rồi chuyển khung dữ liệu hai chiều; kết nối tính một lượt gọi vào hạn mức khi bắt tay.
3. Gateway đóng kết nối nhàn rỗi sau 120 giây; khung lớn hơn 1 MiB bị đóng với mã 1009.
4. Khi token bị thu hồi (UC-03-10), gateway đóng kết nối; token hết hạn tự nhiên không cắt kết nối đang mở nhưng sau tối đa 10 phút bên gọi phải nâng cấp lại.
5. Với yêu cầu HTTP thường có `Accept-Encoding: gzip`, gateway nén phản hồi trên 1 KiB, trừ nội dung đã nén.
6. Nhánh gRPC (Đợt 3): quản trị chọn bộ `.proto` đã duyệt, ánh xạ đường dẫn REST sang phương thức gRPC; gateway nhận REST/JSON, gọi upstream `grpc`, chuyển phản hồi về JSON và ánh xạ lỗi gRPC sang mã HTTP (`UNAVAILABLE` sang 503, `DEADLINE_EXCEEDED` sang 504, `PERMISSION_DENIED` sang 403, `INVALID_ARGUMENT` sang 400) (FR-03-034).

**Luồng thay thế.**

- **1a. Route không bật WebSocket.** Yêu cầu `Upgrade` bị coi như yêu cầu thường (xem E2).
- **6a. Cặp chuyển đổi ngược (gRPC sang REST).** Chưa hỗ trợ ở bản này (xem E3).
- **6b. Không có HTTT cần gRPC trong 12 tháng đầu.** FR-03-034 có thể bỏ khỏi phạm vi (Q03-07 của FRS).

**Luồng ngoại lệ.**

- **E1. Vượt số kết nối WebSocket của HTTT (bước 2).** ERR-03-116 (429); "HTTT đang giữ quá 50 kết nối WebSocket cho API này. Đóng bớt kết nối rồi thử lại."
- **E2. Route chưa bật WebSocket (bước 1).** ERR-03-101 (400); "API này không hỗ trợ WebSocket."
- **E3. Cặp chuyển đổi không hỗ trợ (bước 6).** ERR-03-125 (501); "Gateway chưa hỗ trợ kiểu chuyển đổi giao thức này."
- **E4. `.proto` hoặc ánh xạ sai khi cấu hình (bước 6).** ERR-03-005 (422); "Cấu hình chuyển đổi gRPC không hợp lệ: {lỗi}."
- **E5. Chốt xác thực hoặc hạn mức từ chối lúc bắt tay (bước 1).** Mã lỗi như UC-03-01 (ERR-03-102…107, 116…118); kết nối không được mở.

**Quy tắc áp dụng.** BR-03-001, 017.

**Màn hình, API.** UI-03-03 (tab Chính sách); API-03-002.
:::

### 6.8. UC-03-08 · Suy giảm có kiểm soát khi Valkey mất

::: dac-ta
**Mục tiêu.** Sự cố Valkey chỉ làm hạn mức kém chính xác chứ không làm ngừng gateway: lượt gọi vẫn được phục vụ, hạn mức đếm cục bộ, đội vận hành biết ngay.

**Tác nhân chính.** APISIX (mặt phẳng dữ liệu).

**Tác nhân phụ.** Valkey, PO và TO (nhận cảnh báo), PH-13, `dh-connect`.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-025, 026.

**Truy vết.** REQ-03; quy trình Vận hành lượt gọi; LGC-NFR-006; NFR-00-012.

**Tiền điều kiện.** Ba bản sao `apisix-int`; plugin `limit-count` cho phép suy giảm; plugin `limit-req` cục bộ nằm trong chuỗi chốt; `gw.degrade.localDivisorMode` = `REPLICAS`.

**Kích hoạt.** Lệnh tới Valkey quá 50 ms hoặc lỗi kết nối lúc 14:02.

**Đảm bảo tối thiểu.** Không lượt gọi nào bị từ chối vì Valkey mất; không mất dữ liệu cấu hình; danh sách chặn token dùng bộ đệm cục bộ gần nhất.

**Đảm bảo thành công.** Hạn mức còn hiệu lực theo số bản sao; phản hồi mang `X-RateLimit-Degraded: true`; cảnh báo Nghiêm trọng phát trong tối đa 1 phút; khi Valkey trở lại, nút tự thoát suy giảm.

**Luồng chính.**

1. Plugin ở một nút phát hiện lệnh Valkey quá 50 ms nên chuyển nút sang chế độ suy giảm; ngắt mạch phía Valkey 5 giây rồi thử lại (FR-03-026).
2. Tần suất theo giây, phút và hạn mức tenant chuyển sang đếm cục bộ từng nút, giới hạn bằng giới hạn gốc chia cho số bản sao đang chạy (làm tròn lên): với 20 lượt/giây và ba bản sao, mỗi nút cho 7 lượt/giây.
3. Hạn ngạch giờ, ngày, tháng mở: lượt gọi được cho qua và không đếm.
4. Mỗi phản hồi mang `X-RateLimit-Degraded: true`; tiêu đề `X-RateLimit-Remaining` bị bỏ vì không tính được (FR-03-025).
5. Gateway ghi chỉ số `dh_gateway_valkey_up = 0` và phát EVT-03-09; luật GW-A07 phát cảnh báo Cao cho Phong (PO) và Chi (TO) sau 1 phút (xem UC-03-18).
6. Màn Tổng quan lưu lượng (UC-03-27) hiện biểu tượng suy giảm ở thẻ nút và Valkey.
7. Valkey trở lại: nút về chế độ thường; bộ đếm theo chu kỳ bắt đầu lại từ 0 (chấp nhận sai lệch trong chu kỳ đang chạy); `dh-connect` nạp lại danh sách chặn token từ bảng `revoked_token`; gateway phát EVT-03-09 báo kết thúc suy giảm.

**Luồng thay thế.**

- **2a. Hồ sơ `QM-NHO` chỉ có một bản sao APISIX.** Giới hạn cục bộ chính là giới hạn gốc (FR-03-026).
- **1a. Valkey chậm nhưng chưa mất.** Giữ chế độ thường, tăng chỉ số `dh_gateway_valkey_latency_seconds`, cảnh báo Cao khi p99 vượt 20 ms.

**Luồng ngoại lệ.**

- **E1. Suy giảm kéo dài trên 15 phút (bước 5).** Cảnh báo leo thang, đề nghị PA xem xét tăng bản sao Valkey.
- **E2. Token vừa thu hồi trong lúc Valkey mất.** Chỉ có hiệu lực chặn khi Valkey trở lại hoặc khi token hết hạn (tối đa 5 phút); xem UC-03-10.
- **E3. PH-13 không khả dụng (bước 5).** Gateway vẫn chạy; cảnh báo chưa phát được, màn hình báo "Chưa có số liệu" (ERR-03-026: "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau.").

**Quy tắc áp dụng.** BR-03-024, 025.

**Màn hình, API.** UI-03-01; API-03-077.
:::

### 6.9. UC-03-09 · Dừng, mở API và phiên bản API song song

::: dac-ta
**Mục tiêu.** Vận hành dừng một API ngay khi cần (bảo trì backend, sự cố) và mở lại trong vài giây không chờ phát hành; HTTT có đủ thời gian chuyển sang phiên bản mới khi phiên bản cũ ngừng dùng.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi).

**Tác nhân phụ.** PH-02 (nhận trạng thái "Đang dừng", khai `deprecatedAt`, `sunsetAt`), HTTT gọi API, đầu mối HTTT.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-035, 036.

**Truy vết.** REQ-03, REQ-02; quy trình Công bố API (PH-02); LGC-APIM-005; 017.

**Tiền điều kiện.** Chi có `PERM-03-operate`; route `gui-van-ban.v1` ở `ACTIVE`; phiên bản `v1` của API đã có `deprecatedAt` và `sunsetAt` cách nhau tối thiểu 180 ngày ở PH-02, `v2` cùng `ACTIVE`.

**Kích hoạt.** Chi bấm "Dừng API" ở UI-03-02 vì sẽ bảo trì backend lúc 22:00; hoặc `v1` đang trong thời gian ngừng dùng.

**Đảm bảo tối thiểu.** Thất bại ở bất kỳ bước nào thì cấu hình đang chạy không đổi; mọi thao tác dừng, mở đều có lý do và ghi kiểm toán.

**Đảm bảo thành công.** Route `STOPPED` trả `503` kèm lý do trong 10 giây (mục tiêu) sau thao tác; PH-02 hiển thị "Đang dừng"; phiên bản cũ phục vụ song song kèm tiêu đề ngừng dùng cho tới `sunsetAt`.

**Luồng chính.**

1. Chi mở UI-03-03 của `gui-van-ban.v1`, bấm "Dừng API", nhập lý do "Bảo trì CSDL Sở TT&TT 22:00–23:00" và câu hiển thị cho bên gọi; hệ thống yêu cầu xác nhận lần hai (tuân thủ FR-00-050; LP-03-02).
2. Hệ thống kiểm tra route ở trạng thái cho phép dừng (`ACTIVE`) và đổi sang `STOPPED` (FR-03-036).
3. Hệ thống kích hoạt LP-03-03 theo đường nhanh; sau khi nút nạp (mục tiêu 10 giây), lượt gọi tới route nhận `503` ERR-03-123 kèm `Retry-After`.
4. Hệ thống đồng bộ trạng thái ngược về PH-02 và phát EVT-03-03; kiểm toán ghi người thao tác, route, lý do, trạng thái trước và sau, số phiên bản ảnh chụp.
5. Lúc 23:05 Chi bấm "Mở API"; hệ thống đổi `STOPPED` về `ACTIVE` bằng cùng cơ chế, ghi kiểm toán cả hai chiều.
6. Phiên bản song song: `v1` và `v2` là hai route riêng phân biệt bằng đường dẫn `/api/vanban/v1/…` và `/api/vanban/v2/…`. Với `v1` đã `deprecatedAt`, gateway thêm `Deprecation: true`, `Sunset: {ngày HTTP}` và `Link: <đường dẫn v2>; rel="successor-version"` vào mọi phản hồi (FR-03-035).
7. Trước `sunsetAt` 30 ngày, hệ thống thông báo đầu mối các HTTT vẫn đang gọi `v1` (đọc từ nhật ký 7 ngày).
8. Tới `sunsetAt`, `v1` chuyển `SUNSET`, lượt gọi nhận `410` ERR-03-126; sau thêm 30 ngày (`gw.sunset.retainDays`) chuyển `RETIRED` và không còn trong ảnh chụp.

**Luồng thay thế.**

- **1a. Dừng có hẹn giờ.** Chi nhập `from` 22:00 và `to` 23:00; hệ thống đặt ảnh chụp theo lịch và tự mở khi hết (FR-03-036).
- **6a. Chủ dịch vụ gia hạn phiên bản cũ.** PH-02 đổi `sunsetAt`; ảnh chụp mới có hạn mới.
- **1b. Sự cố an ninh, không phải bảo trì.** Dùng tạm ngừng khẩn cấp (UC-03-11).

**Luồng ngoại lệ.**

- **E1. Route đã ở trạng thái đích (bước 2).** ERR-03-019 (409); "API đang ở trạng thái STOPPED."
- **E2. Route `PENDING`, `SUNSET` hoặc `RETIRED` (bước 2).** ERR-03-023 (409); "Không thể dừng hoặc mở API ở trạng thái {trạng thái}."
- **E3. Lượt gọi tới route đang dừng (bước 3).** ERR-03-123 (503); "API gui-van-ban.v1 đang tạm dừng: Bảo trì CSDL Sở TT&TT 22:00–23:00. Thử lại sau."
- **E4. Gọi `v1` sau `sunsetAt` (bước 8).** ERR-03-126 (410); "Phiên bản v1 của API gui-van-ban đã ngừng phục vụ từ {ngày}. Chuyển sang phiên bản v2."
- **E5. Khoảng ngừng dùng ngắn hơn 180 ngày khi PH-02 phát hành.** Bị chặn ở kiểm tra cấu hình, ERR-03-005 (422); "Phiên bản cũ phải được duy trì tối thiểu 180 ngày sau khi công bố ngừng dùng." (UC-03-19).

**Quy tắc áp dụng.** BR-03-010, 029, 030.

**Màn hình, API.** UI-03-02, UI-03-03 (tab Phiên bản); API-03-001, 002, 003, 004, 007.
:::

### 6.10. UC-03-10 · Thu hồi token khẩn cấp

::: dac-ta
**Mục tiêu.** Khi một HTTT bị lộ khóa hoặc một tài khoản bị khóa, token đã phát của họ bị chặn ở gateway trong không quá 60 giây (thực tế dưới 15 giây), không chờ token hết hạn 5 phút.

**Tác nhân chính.** PH-12 (gọi bằng scope `gateway:revoke`).

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng, người ra quyết định ở PH-12), `dh-connect`, Valkey, HTTT bị thu hồi.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-018.

**Truy vết.** REQ-03, REQ-12; quy trình Sự cố ATTT (BP-07); chức năng mới (SEC-25).

**Tiền điều kiện.** Valkey truy cập được; plugin `dh-revocation` nạp ở mọi nút; tài khoản máy của PH-12 có scope `gateway:revoke`.

**Kích hoạt.** Lúc 09:30, Dũng phát hiện khóa của `HT-QLVB` bị lộ và vô hiệu client `ht-qlvb` ở PH-12; PH-12 gọi API-03-053 với `kind = SUBJECT`, `sub = ht-qlvb`, `notBefore` = thời điểm hiện tại, `reason` "Lộ khóa client".

**Đảm bảo tối thiểu.** Bản ghi thu hồi được lưu bền ở `ph03_gateway.revoked_token` để dựng lại khi Valkey mất; việc thu hồi luôn có người hoặc dịch vụ gọi và lý do trong kiểm toán.

**Đảm bảo thành công.** Mọi token của `ht-qlvb` phát hành trước `notBefore` bị chặn với `401` ở mọi nút trong tối đa 60 giây; token mới cấp sau khi khóa client được xoay vẫn dùng được.

**Luồng chính.**

1. PH-12 gọi API-03-053 với danh tính cần chặn; `dh-connect` kiểm tra scope `gateway:revoke` (FR-03-018).
2. `dh-connect` lưu bản ghi vào `revoked_token` và ghi khóa `T68:revoked:sub:ht-qlvb` vào Valkey với thời hạn bằng đời sống còn lại của token cộng dung sai; trả `202` kèm `revocationId` và `effectiveBy`.
3. Plugin `dh-revocation` ở mỗi nút tra khóa Valkey cho mọi lượt gọi đã qua chốt chữ ký, có bộ đệm cục bộ 5 giây.
4. Lúc 09:30:12, `HT-QLVB` gọi API với token cũ; gateway thấy token có `iat` trước `notBefore` nên trả `401` ERR-03-105 và ghi sự kiện vào nhật ký an ninh.
5. Dũng mở UI-03-05, tab "Thu hồi" của consumer `ht-qlvb` (API-03-054) để xem bản ghi, thời điểm hiệu lực và số lượt đã bị chặn.
6. Khi khóa client đã được xoay, `HT-QLVB` lấy token mới và gọi lại bình thường.
7. Khóa Valkey tự xóa khi token cũ hết hạn tự nhiên; bản ghi `revoked_token` được dọn sau 24 giờ.

**Luồng thay thế.**

- **1a. Thu hồi một token cụ thể.** PH-12 gửi `kind = JTI` với `jti` và `tokenExpiresAt`; chỉ token đó bị chặn.
- **1b. Thu hồi theo người dùng giao diện.** PH-12 gửi `kind = SUBJECT` với `sub` của người dùng bị khóa; token giao diện của họ bị chặn tương tự.

**Luồng ngoại lệ.**

- **E1. Token đã thu hồi (bước 4).** ERR-03-105 (401); "Token đã bị thu hồi. Liên hệ quản trị Datahub nếu cần cấp lại."
- **E2. Gọi API-03-053 không có scope `gateway:revoke` (bước 1).** ERR-03-022 (403); lỗi giữa hai dịch vụ nên thân RFC 9457 nêu scope còn thiếu, không có câu hiển thị cho người dùng.
- **E3. Valkey không khả dụng (bước 2, 3).** Nút dùng bộ đệm cục bộ gần nhất; token vừa thu hồi chỉ bị chặn khi Valkey trở lại hoặc khi token hết hạn (tối đa 5 phút); cảnh báo GW-A07 phát; khi Valkey trở lại `dh-connect` nạp lại các bản ghi chưa hết hạn (xem UC-03-08).
- **E4. Dũng không thấy bản ghi (bước 5).** Người dùng không có `PERM-03-read` hoặc xem sai tenant; hệ thống trả như không tồn tại, ERR-03-001 (404).

**Quy tắc áp dụng.** BR-03-021, 025.

**Màn hình, API.** UI-03-05; API-03-053, 054.
:::

### 6.11. UC-03-11 · Tạm ngừng khẩn cấp route hoặc consumer

::: dac-ta
**Mục tiêu.** Khi có sự cố an ninh, vận hành chặn ngay một HTTT hoặc một API khỏi gateway trong tối đa 30 giây, không chờ quy trình phát hành, rồi mở lại khi xử lý xong.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-TENANT_OPERATOR (Chi), ROLE-TENANT_ADMIN và ROLE-PLATFORM_ADMIN cùng có `PERM-03-operate`.

**Tác nhân phụ.** Valkey, `dh-connect`, bộ đồng bộ, PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-047.

**Truy vết.** REQ-03; quy trình Sự cố ATTT (BP-07); LGC-APIM-005; SEC-25, SEC-72, SEC-73.

**Tiền điều kiện.** Đối tượng tồn tại ở tenant `T68`; người thực hiện có `PERM-03-operate`; plugin `dh-kill-switch` nạp ở mọi nút.

**Kích hoạt.** Cảnh báo GW-A02 (thất bại xác thực vượt 50 lượt/phút) cho thấy consumer `ht-dvc` bị dò khóa; lúc 10:12 Dũng bấm "Tạm ngừng khẩn cấp" ở UI-03-05.

**Đảm bảo tối thiểu.** Việc tạm ngừng không xóa dữ liệu; không cần người duyệt nhưng luôn có lý do, kiểm toán và sự kiện; nếu đường nhanh lỗi thì đường bền vững vẫn hoàn tất.

**Đảm bảo thành công.** Lượt gọi của `ht-dvc` nhận `403` trong tối đa 30 giây kể từ lệnh; bản ghi `EN-03-12` ở `ACTIVE`; consumer ở `SUSPENDED` trong ảnh chụp.

**Luồng chính.**

1. Dũng chọn consumer `ht-dvc`, nhập lý do "Nghi lộ khóa, cảnh báo GW-A02 lúc 10:09" (10 đến 500 ký tự) và xác nhận lần hai (tuân thủ FR-00-050; LP-03-02).
2. Hệ thống kiểm tra đối tượng thuộc tenant và chưa bị tạm ngừng khẩn cấp (FR-03-047).
3. Hệ thống ghi `EN-03-12` và ghi khóa `T68:kill:CONSUMER:ht-dvc` vào Valkey (đường nhanh); plugin `dh-kill-switch` ở mọi nút tra khóa với bộ đệm cục bộ 5 giây (LP-03-05).
4. Hệ thống đồng thời kích hoạt LP-03-03 sinh ảnh chụp mới có `ht-dvc` ở trạng thái `SUSPENDED` (đường bền vững phòng khi Valkey mất).
5. Lượt gọi của `ht-dvc` nhận `403` ERR-03-127 trong tối đa 30 giây; hệ thống phát EVT-03-04 và EVT-03-09, ghi kiểm toán gồm người thực hiện, đối tượng, lý do, thời điểm.
6. Sau khi điều tra và xoay khóa, Dũng bấm "Mở lại", nhập lý do "Đã xoay khóa, xác nhận với đầu mối HT-DVC"; hệ thống xóa khóa Valkey, đặt `liftedAt`, sinh ảnh chụp mới và ghi kiểm toán, sự kiện chiều mở lại.

**Luồng thay thế.**

- **1a. Tạm ngừng một route.** Chi chọn route `gui-van-ban.v1` ở UI-03-02 (API-03-019); lượt gọi nhận `503` ERR-03-123 thay vì `403`.
- **1b. Tạm ngừng cả HTTT với mọi client.** Dùng PH-01 tạm ngừng HTTT; PH-01 đặt `state = SUSPENDED` cho từng consumer qua FR-03-046 (UC-03-23); tạm ngừng ở PH-03 áp cho từng consumer.
- **3a. Valkey không khả dụng.** Đường nhanh lỗi; hệ thống báo "áp dụng qua ảnh chụp, dự kiến ≤ 60 giây" và vẫn hoàn tất qua bước 4.

**Luồng ngoại lệ.**

- **E1. Đối tượng đã bị tạm ngừng (bước 2).** ERR-03-019 (409); "HTTT ht-dvc đã đang bị tạm ngừng khẩn cấp từ 10:12 26/11/2026."
- **E2. Không tìm thấy hoặc thuộc tenant khác (bước 2).** ERR-03-001 (404); "Không tìm thấy route hoặc HTTT ht-dvc."
- **E3. Lý do dưới 10 ký tự khi gọi API trực tiếp (bước 1).** ERR-03-003 (400); "Giá trị của reason phải thuộc 10…500 ký tự." Trên giao diện, nút "Xác nhận" bị khóa.
- **E4. Người dùng không có `PERM-03-operate` (bước 1).** ERR-03-022 (403); "Bạn không có quyền tạm ngừng khẩn cấp."
- **E5. Lượt gọi của consumer hoặc tới route bị tạm ngừng (bước 5).** ERR-03-127 (403); "HTTT của bạn đang bị tạm ngừng truy cập. Liên hệ quản trị Datahub." Hoặc ERR-03-123 (503); "API gui-van-ban.v1 đang tạm dừng. Thử lại sau."

**Quy tắc áp dụng.** BR-03-021, 029.

**Màn hình, API.** UI-03-02, UI-03-05; API-03-017, 018, 019, 020.
:::

### 6.12. UC-03-12 · Chặn địa chỉ nguồn tự động và thủ công

::: dac-ta
**Mục tiêu.** Một địa chỉ đang dò quét hoặc tấn công bị cắt khỏi nền tảng trong tối đa 60 giây, tự gỡ sau 15 phút nếu là chặn tự động; Cán bộ ATTT chặn tay được khi có thông tin tình báo mà không chặn nhầm hạ tầng nền tảng.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Plugin `dh-ip-block`, Valkey, PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-003, 004.

**Truy vết.** REQ-03; quy trình Sự cố ATTT (BP-07); CMP-LAW-09; SEC-10, SEC-64.

**Tiền điều kiện.** Valkey truy cập được; tham số `gw.ip.autoBlock.threshold` = 10 và `gw.ip.autoBlock.minutes` = 15 có trong ảnh chụp; Dũng có `PERM-03-waf`.

**Kích hoạt.** Địa chỉ `198.51.100.77` bị từ chối 10 lần trong 60 giây ở chốt giới hạn hoặc WAF; hoặc Dũng bấm "Chặn địa chỉ" ở UI-03-15.

**Đảm bảo tối thiểu.** Không chặn nhầm địa chỉ thuộc danh sách tin cậy hoặc dải hạ tầng; mọi lần chặn có nguồn (`AUTO` hay người), lý do và thời hạn.

**Đảm bảo thành công.** Địa chỉ bị chặn nhận `403` ERR-03-110 ở đầu chuỗi chốt, không tốn thêm xử lý; khóa tự xóa khi hết hạn; bản ghi `EN-03-14` đổi trạng thái đúng.

**Luồng chính.**

1. Mỗi lần địa chỉ `198.51.100.77` vượt giới hạn kết nối hoặc tốc độ (FR-03-003) hoặc bị WAF chặn, bộ đếm vi phạm trong cửa sổ 60 giây của địa chỉ đó tăng một.
2. Lần vi phạm thứ 10, plugin `dh-ip-block` ghi khóa `T68:ipblock:198.51.100.77/32` vào Valkey với thời hạn 15 phút và ghi sự kiện an ninh; hệ thống phát EVT-03-09 (FR-03-004).
3. Mọi nút tra khóa này ở chốt thứ hai của chuỗi; lượt gọi tiếp theo từ địa chỉ đó nhận `403` ERR-03-110.
4. Dũng mở UI-03-15, thấy bản ghi nguồn `AUTO`, số lần vi phạm đã đếm và thời điểm hết hạn.
5. Dũng cũng nhận được thông tin tình báo về dải `198.51.100.0/26`; ông bấm "Chặn địa chỉ", nhập `cidr` `198.51.100.0/26`, `durationMinutes` 1.440, lý do "Dải quét dò theo cảnh báo của cơ quan chuyên trách".
6. Hệ thống kiểm tra dải không thuộc danh sách tin cậy hoặc dải hạ tầng, ghi `EN-03-14` và khóa Valkey; trả `201` kèm `blockId`, `expiresAt`.
7. Khi hết hạn, khóa tự xóa và bản ghi chuyển `EXPIRED`; Dũng cũng có thể bấm "Bỏ chặn" để xóa khóa ngay, bản ghi chuyển `LIFTED`.

**Luồng thay thế.**

- **5a. Chặn một dải rộng do nhiều địa chỉ cùng tấn công.** Hệ thống cảnh báo số HTTT đang dùng địa chỉ trong dải (đọc từ nhật ký 7 ngày) trước khi Dũng xác nhận.
- **1a. Một đơn vị sau NAT cần hạn mức cao hơn.** Dũng đưa dải đó vào danh sách tin cậy kèm lý do; hạn mức theo HTTT vẫn áp dụng (FR-03-003).
- **2a. Tham số chặn tự động đổi.** TA hoặc PA đổi ở UC-03-29.

**Luồng ngoại lệ.**

- **E1. Địa chỉ thuộc danh sách tin cậy hoặc dải hạ tầng (bước 6).** ERR-03-024 (422); "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn."
- **E2. Dải quá rộng hoặc thiếu lý do (bước 6).** ERR-03-003 (400); "Chỉ được chặn dải không rộng hơn /24 (IPv4) hoặc /56 (IPv6) và phải nêu lý do."
- **E3. Valkey không khả dụng (bước 2, 6).** Chặn thủ công lưu vào `EN-03-14` và áp dụng khi Valkey trở lại; chặn tự động tạm dùng bộ nhớ từng nút; cảnh báo GW-A07.
- **E4. Địa chỉ bị chặn gọi tới (bước 3).** ERR-03-110 (403); "Yêu cầu bị từ chối." Không kèm chi tiết.
- **E5. Không xác định được địa chỉ nguồn thật (thiếu PROXY từ bộ cân bằng tải).** Gateway dùng địa chỉ của kết nối và phát cảnh báo cấu hình.

**Quy tắc áp dụng.** BR-03-001, 005, 023.

**Màn hình, API.** UI-03-15; API-03-036, 037, 038.
:::

### 6.13. UC-03-13 · Đổi chế độ WAF có bốn mắt

::: dac-ta
**Mục tiêu.** WAF vào PROD an toàn: chạy phát hiện trước, đủ 14 ngày và đã xử lý cảnh báo giả mới được chuyển sang chặn, với hai người khác nhau chịu trách nhiệm; khi WAF quá tải thì giữ dịch vụ trước rồi báo.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng, người đề nghị).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Lan, người duyệt), `dh-connect`, `dh-waf-guard` ở nút, PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-005, 006.

**Truy vết.** REQ-03; quy trình Xử lý cảnh báo giả của WAF; SEC-11; ADR-033.

**Tiền điều kiện.** WAF nạp ở cả hai cửa vào, `gw.waf.mode` = `DETECT` từ 02/11/2026 (đã 24 ngày); số sự kiện chưa xử lý (cảnh báo giả) 6, thấp hơn `gw.waf.fpReviewMax` = 20; Dũng có `PERM-03-waf`, Lan có `PERM-03-approve`.

**Kích hoạt.** Dũng bấm "Đổi chế độ WAF" ở UI-03-07 để chuyển phạm vi `TENANT` sang `BLOCK`; hoặc nút APISIX phát hiện WAF quá tải.

**Đảm bảo tối thiểu.** Chế độ cũ vẫn chạy cho tới khi ảnh chụp mới được nạp; việc tự hạ ở nút không đổi cấu hình lưu.

**Đảm bảo thành công.** Ảnh chụp mới có chế độ `BLOCK` đã được nút nạp; kiểm toán ghi người đề nghị, người duyệt, ý kiến, chế độ trước và sau.

**Luồng chính.**

1. Dũng chọn phạm vi `TENANT`, chế độ `BLOCK`, nhập lý do "Đã chạy DETECT 24 ngày, 6 cảnh báo giả đã có ngoại lệ hoặc đã loại" (FR-03-006).
2. Hệ thống kiểm tra đã chạy `DETECT` ít nhất 14 ngày và số cảnh báo giả chưa xử lý dưới ngưỡng.
3. Hệ thống tạo yêu cầu thay đổi `EN-03-15` chờ duyệt và đưa vào hộp "Việc của tôi" của Lan (LP-03-01; tuân thủ FR-00-070).
4. Lan mở UI-03-17, xem số sự kiện `DETECT` 14 ngày qua theo luật rồi bấm "Duyệt" kèm ý kiến "Đồng ý".
5. Hệ thống kích hoạt LP-03-03: sinh ảnh chụp mới với `gw.waf.mode = BLOCK`, các nút nạp trong 10 giây; hệ thống phát EVT-03-01.
6. Sau đó nếu `dh_gateway_waf_duration_seconds` p99 của một nút vượt 15 ms liên tục 2 phút, plugin `dh-waf-guard` chuyển WAF của riêng nút đó sang `DETECT` tạm thời, phát EVT-03-09 và cảnh báo Nghiêm trọng GW-A06 tới Dũng và Hà (UC-03-18).
7. Khi p99 dưới ngưỡng 5 phút liên tục, nút tự trở lại `BLOCK`.

**Luồng thay thế.**

- **1a. Chuyển sang `DETECT` khi cảnh báo giả diện rộng.** Vẫn cần người thứ hai duyệt nhưng yêu cầu được đánh dấu khẩn và thông báo đẩy tới Lan.
- **4a. Lan từ chối.** Yêu cầu sang `REJECTED` kèm lý do bắt buộc (tuân thủ FR-00-072); chế độ không đổi.
- **4b. Tenant chỉ có một Cán bộ ATTT và Dũng là người đề nghị.** Lan (TA) duyệt như bước 4; với đề nghị do TA lập thì SO duyệt (FRS §3.3).

**Luồng ngoại lệ.**

- **E1. Chưa đủ 14 ngày chạy phát hiện (bước 2).** ERR-03-027 (422); "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)."
- **E2. Người duyệt trùng người đề nghị (bước 4).** ERR-03-008 (403); "Bạn đã đề nghị thay đổi này nên không thể tự duyệt."
- **E3. Phát ảnh chụp lỗi (bước 5).** Chế độ cũ vẫn chạy; ERR-03-014 (502) "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại." hoặc ERR-03-015 (503) "Dịch vụ ký cấu hình tạm thời không khả dụng. Thử lại sau; cấu hình đang chạy không đổi."
- **E4. Yêu cầu bị chặn ở chế độ `BLOCK` (sau bước 5).** ERR-03-109 (403) cho bên gọi; vận hành xử lý theo UC-03-14.

**Quy tắc áp dụng.** BR-03-010, 019.

**Màn hình, API.** UI-03-07, UI-03-17; API-03-039, 040, 041, 071, 072, 073.
:::

### 6.14. UC-03-14 · Xử lý cảnh báo giả bằng ngoại lệ luật WAF

::: dac-ta
**Mục tiêu.** Một lượt gọi hợp lệ bị WAF chặn nhầm được thông qua trong thời hạn ngắn, có lý do và hai người chịu trách nhiệm; không có ngoại lệ vĩnh viễn và không có ngoại lệ chỉ một người quyết.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi, người đề nghị).

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng, người duyệt), `dh-connect`, bộ đồng bộ, PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-007.

**Truy vết.** REQ-03; quy trình Xử lý cảnh báo giả của WAF; CMP-LAW-08; SEC-07, SEC-11; ADR-033.

**Tiền điều kiện.** Có sự kiện WAF chặn ở UI-03-07 làm căn cứ: luật `942100` chặn trường `ghiChu` của route `tra-cuu-ho-tich.v1`; Chi có `PERM-03-waf-request`, Dũng có `PERM-03-waf-approve`.

**Kích hoạt.** `HT-TUPHAP` báo yêu cầu hợp lệ bị `403`; Chi tìm theo `traceId` và bấm "Đề nghị ngoại lệ" trên dòng sự kiện chặn.

**Đảm bảo tối thiểu.** Ngoại lệ chưa duyệt không có hiệu lực ở gateway; ngoại lệ chỉ áp cho đúng một route và một mã luật.

**Đảm bảo thành công.** Ngoại lệ `ACTIVE` có hạn tối đa 90 ngày; lượt gọi tương tự đi qua sau khi nút nạp ảnh chụp mới; ngoại lệ tự hết hạn đúng ngày.

**Luồng chính.**

1. Chi chọn sự kiện chặn; hệ thống điền sẵn `routeCode` `tra-cuu-ho-tich.v1`, `ruleId` `942100`, mẫu yêu cầu đã che (FR-03-007).
2. Chi nhập lý do "Trường ghiChu chứa dấu nháy hợp lệ trong văn bản hành chính" và hạn 30 ngày; hệ thống kiểm tra mã luật có trong CRS, lý do từ 20 ký tự, hạn không quá 90 ngày.
3. Hệ thống kiểm tra chưa có ngoại lệ còn hiệu lực cho cặp route và mã luật, tạo `EN-03-07` ở `REQUESTED` và việc chờ duyệt cho Dũng (LP-03-01).
4. Dũng xem căn cứ, số lần chặn 7 ngày và mẫu yêu cầu đã che, bấm "Duyệt" kèm ý kiến.
5. Ngoại lệ chuyển `ACTIVE`, đặt `expiresAt`; hệ thống kích hoạt LP-03-03 và phát EVT-03-05; sau khi nút nạp, lượt gọi tương tự của `HT-TUPHAP` đi qua.
6. Còn 7 ngày hết hạn, ngoại lệ chuyển `EXPIRING`, hệ thống phát EVT-03-06 thông báo Dũng và Lan; hết hạn thì chuyển `EXPIRED` và ảnh chụp kế tiếp gỡ ngoại lệ.

**Luồng thay thế.**

- **4a. Dũng từ chối.** Ngoại lệ sang `REJECTED`, ý kiến lý do bắt buộc; Chi sửa cấu hình phía `HT-TUPHAP` hoặc đề nghị lại.
- **6a. Thu hồi sớm.** Dũng thu hồi ngoại lệ đang hiệu lực (API-03-046) kèm lý do; ảnh chụp mới gỡ ngoại lệ; muốn kéo dài phải đề nghị lại từ đầu.
- **4b. Tenant chỉ có một Cán bộ ATTT.** Người đề nghị không tự duyệt được; PA duyệt thay, kiểm toán ghi "duyệt thay" (đề xuất Q03-02 của FRS).

**Luồng ngoại lệ.**

- **E1. Thiếu lý do, quá 90 ngày hoặc mã luật không có (bước 2).** ERR-03-009 (422); "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày."
- **E2. Đã có ngoại lệ còn hiệu lực cho cặp route và mã luật (bước 3).** ERR-03-010 (409); "Route này đã có ngoại lệ cho luật 942100 đến {ngày}. Thu hồi ngoại lệ cũ hoặc chờ hết hạn."
- **E3. Tự duyệt (bước 4).** ERR-03-008 (403); "Bạn đã đề nghị ngoại lệ này nên không thể tự duyệt."
- **E4. Phát ảnh chụp lỗi (bước 5).** ERR-03-014 hoặc ERR-03-015 như UC-03-13 E3; ngoại lệ ở `ACTIVE` nhưng chưa tới nút, lượt gọi vẫn bị chặn tới khi ảnh chụp phát được.

**Quy tắc áp dụng.** BR-03-006, 019.

**Màn hình, API.** UI-03-07, UI-03-08, UI-03-17; API-03-039, 042, 043, 044, 045, 046.
:::

### 6.15. UC-03-15 · Soạn và duyệt luật vá ảo khẩn cấp

::: dac-ta
**Mục tiêu.** Khi có lỗ hổng chưa có bản vá ở một backend, Cán bộ ATTT triển khai luật WAF tạm trong không quá 4 giờ kể từ khi có thông tin, sau khi thử khô và có người thứ hai duyệt.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Lan, người duyệt), Coraza (thử khô), `dh-connect`.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-03-008.

**Truy vết.** REQ-03; quy trình Sự cố ATTT (BP-07); SEC-09, SEC-11; ADR-033.

**Tiền điều kiện.** Có thông tin lỗ hổng (số cảnh báo hoặc mã CVE giả lập `CVE-2026-90001` của phần mềm quản lý văn bản `HT-QLVB`); WAF ở `BLOCK` hoặc `DETECT`; Dũng có `PERM-03-waf`, Lan có `PERM-03-approve`.

**Kích hoạt.** Dũng bấm "Thêm luật vá ảo" ở UI-03-08 lúc 13:00.

**Đảm bảo tối thiểu.** Luật sai cú pháp hoặc chặn quá 1% mẫu sạch không bao giờ tới gateway; luật luôn có hạn và căn cứ.

**Đảm bảo thành công.** Luật `ACTIVE` có hiệu lực trong vài phút sau duyệt; nội dung luật được băm và lưu đầy đủ ở kiểm toán.

**Luồng chính.**

1. Dũng nhập luật SecLang (không quá 4 KiB), phạm vi `routeCode` `gui-van-ban.v1`, căn cứ `CVE-2026-90001` và hạn 30 ngày (FR-03-008).
2. Hệ thống kiểm tra cú pháp bằng Coraza ở chế độ thử khô, chạy luật trên bộ yêu cầu mẫu sạch của tenant và hiển thị "Số mẫu: 1.200, sẽ chặn: 3" (0,25%).
3. Hệ thống tạo `EN-03-08` và yêu cầu thay đổi chờ duyệt; vì là luật khẩn, thông báo đẩy tới Lan (LP-03-01).
4. Lan xem kết quả thử khô, bấm "Duyệt".
5. Hệ thống kích hoạt LP-03-03 sinh ảnh chụp mới chứa luật và phát EVT-03-01; luật `ACTIVE` lúc 13:25.
6. Khi CRS cập nhật có luật tương đương hoặc luật hết hạn, Dũng bấm "Gỡ" (API-03-049) hoặc luật tự hết hạn; ảnh chụp kế tiếp gỡ luật.

**Luồng thay thế.**

- **1a. Phạm vi `TENANT` thay vì từng route.** Hệ thống thêm bước cảnh báo "ảnh hưởng mọi route" và yêu cầu Dũng xác nhận.
- **4a. Lan từ chối.** Luật không tới gateway; Dũng chỉnh luật và gửi lại.

**Luồng ngoại lệ.**

- **E1. Luật sai cú pháp hoặc chặn quá 1% mẫu sạch (bước 2).** ERR-03-005 (422); "Luật không hợp lệ hoặc chặn nhầm quá 1% yêu cầu mẫu. Xem chi tiết lỗi bên dưới."
- **E2. Thiếu căn cứ hoặc quá 90 ngày (bước 1).** ERR-03-009 (422); "Luật vá ảo cần có căn cứ (mã CVE hoặc số cảnh báo) và thời hạn không quá 90 ngày." (câu mới, ghi ở mục 8).
- **E3. Tự duyệt (bước 4).** ERR-03-008 (403); "Bạn đã đề nghị thay đổi này nên không thể tự duyệt."
- **E4. Chưa phát được ảnh chụp (bước 5).** ERR-03-014 hoặc ERR-03-015 như UC-03-13 E3; luật chưa có hiệu lực, hệ thống thử lại theo lũy thừa và cảnh báo Cao.

**Quy tắc áp dụng.** BR-03-006, 019.

**Màn hình, API.** UI-03-08, UI-03-17; API-03-047, 048, 049, 071, 072, 073.
:::

### 6.16. UC-03-16 · Mở route ra cửa Internet

::: dac-ta
**Mục tiêu.** Chỉ những API thật sự cần mở ra Internet (callback thanh toán, cổng nhà phát triển) mới có mặt ở `apisix-ext`; mặc định mọi API chỉ ở cửa mạng nội bộ, và không API nào ra ngoài mà không qua hai người.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan, người đề nghị).

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng, người duyệt), `dh-connect`, PH-19 (chủ route callback).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-038.

**Truy vết.** REQ-03, REQ-20; quy trình Công bố API (PH-02); SEC-13; ADR-033.

**Tiền điều kiện.** Route `thanh-toan-ipn.v1` đã `ACTIVE` ở cửa `INT`; có lược đồ OpenAPI và chính sách OPA; WAF ở chế độ `BLOCK`; route bắt buộc xác thực; nhà cung cấp có dải nguồn cố định `203.0.113.0/27`.

**Kích hoạt.** Lan bấm "Mở ra Internet" ở UI-03-03.

**Đảm bảo tối thiểu.** Route chưa đủ điều kiện hoặc chưa duyệt không bao giờ có mặt ở `apisix-ext`; đưa route về `INT` luôn thực hiện được ngay.

**Đảm bảo thành công.** `exposure = EXT` kèm `ip-restriction` theo dải nguồn; nút `apisix-ext` nạp route và áp đủ chuỗi chốt; kiểm toán ghi người đề nghị, người duyệt, lý do, dải nguồn.

**Luồng chính.**

1. Lan chọn route, nhập lý do "Nhà cung cấp thanh toán gọi callback IPN từ Internet", dải nguồn `203.0.113.0/27`, `wafParanoia` 1 (FR-03-038).
2. Hệ thống kiểm tra route có lược đồ, có chính sách OPA, không `KEYLESS`, WAF chế độ `BLOCK` ở PROD.
3. Hệ thống tạo yêu cầu thay đổi chờ Dũng duyệt (LP-03-01); trả `202` kèm `requestId`.
4. Dũng xem lý do, điều kiện đã đạt và dải nguồn ở UI-03-17, bấm "Duyệt" kèm ý kiến.
5. Hệ thống kích hoạt LP-03-03: ảnh chụp mới gắn route vào nhóm `apisix-ext`; hệ thống phát EVT-03-03.
6. Lượt gọi từ Internet tới route đi qua UC-03-05.
7. Khi không còn cần, Lan bấm "Đưa về mạng nội bộ"; việc này có hiệu lực ngay, không cần duyệt lại (giảm bề mặt tấn công).

**Luồng thay thế.**

- **1a. Callback của nhà cung cấp thanh toán (PH-19).** Dùng mẫu route `EXT` có sẵn: giới hạn theo dải nguồn đã công bố, xác minh chữ ký ở DU (SEC-48), hạn mức riêng.
- **4a. Dũng từ chối.** Route giữ `INT`; ý kiến lý do bắt buộc.

**Luồng ngoại lệ.**

- **E1. Route chưa đủ điều kiện ra cửa ngoài (bước 2).** ERR-03-011 (422); "Route chưa đủ điều kiện mở ra Internet: WAF chưa ở chế độ chặn."
- **E2. Tự duyệt (bước 4).** ERR-03-008 (403); "Bạn đã đề nghị thay đổi này nên không thể tự duyệt."
- **E3. Lượt gọi từ Internet tới route vẫn ở `INT`.** ERR-03-114 (404); "Không tìm thấy dịch vụ hoặc đường dẫn."
- **E4. Ảnh chụp bị từ chối vì thiếu quyết định duyệt còn hiệu lực (CHK-09).** ERR-03-011 (422) ở danh sách lỗi ảnh chụp (UC-03-19).

**Quy tắc áp dụng.** BR-03-015, 019.

**Màn hình, API.** UI-03-03 (tab Cửa vào), UI-03-17; API-03-008, 071, 072, 073.
:::

### 6.17. UC-03-17 · Quản lý chứng thư biên, hồ sơ TLS và bộ CA khách

::: dac-ta
**Mục tiêu.** Chứng thư TLS của các host ở cửa vào luôn còn hạn và gia hạn không gián đoạn, khóa riêng không rời kho bí mật; HTTT cũ chưa có TLS 1.3 có đường kết nối tạm thời có hạn; bộ CA tin cậy cho mTLS được quản lý có kiểm soát.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà).

**Tác nhân phụ.** cert-manager, OpenBao (PKI), External Secrets, bộ đồng bộ cấu hình, ROLE-TENANT_ADMIN (Lan, xem và gia hạn thủ công).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-001, 002, 049.

**Truy vết.** REQ-03; quy trình Gia hạn chứng thư biên; LGC-BUS-041; SEC-12, SEC-35.

**Tiền điều kiện.** cert-manager và nhà phát hành đã cấu hình; External Secrets đồng bộ Secret từ OpenBao; Hà có `PERM-03-admin` và `PERM-03-operate`.

**Kích hoạt.** Tác vụ quét chứng thư mỗi giờ thấy chứng thư host `api.t68.datahub.gov.vn` còn 29 ngày; hoặc Hà mở UI-03-12.

**Đảm bảo tối thiểu.** Khóa riêng không bao giờ nằm ở Git hay bucket; gia hạn thất bại không làm đổi chứng thư đang chạy.

**Đảm bảo thành công.** Chứng thư mới được nạp không cắt kết nối; không còn chứng thư hết hạn; ngoại lệ TLS 1.2 có hạn, có host chuyên dụng và hiển thị rõ để theo dõi thanh lý.

**Luồng chính.**

1. Hà mở UI-03-12 thấy danh sách chứng thư của hai cửa vào: host, nhà phát hành, thời điểm hết hạn, trạng thái, nơi dùng (API-03-068, 069).
2. Khi còn dưới 30 ngày, cert-manager tự gia hạn; khóa riêng mới sinh và lưu ở OpenBao (FR-03-049).
3. External Secrets cập nhật Secret trong namespace gateway; bộ đồng bộ điền chứng thư mới vào `apisix.yaml` và APISIX nạp lại không mất kết nối (LP-03-03).
4. Hà xem hồ sơ TLS mặc định ở UI-03-12 (TLS 1.3, bộ mã, OCSP stapling bật) và số lần bắt tay bị từ chối theo lý do (API-03-031).
5. HTTT cũ `HT-DATDAI` chỉ có TLS 1.2: Hà tạo ngoại lệ TLS gắn host chuyên dụng `tls12.t68.datahub.gov.vn`, hạn 90 ngày, lý do và HTTT hưởng ngoại lệ (API-03-033); route của `HT-DATDAI` được gắn thêm host này (FR-03-001).
6. Khi `HT-DATDAI` đã nâng cấp, Hà thu hồi ngoại lệ (API-03-034); ảnh chụp kế tiếp gỡ host chuyên dụng.
7. Hà cập nhật bộ CA tin cậy cho mTLS (thêm CA do tỉnh chấp nhận); thay đổi đi theo ảnh chụp có kiểm tra hợp lệ (FR-03-002, 049).

**Luồng thay thế.**

- **2a. Gia hạn thủ công.** Lan hoặc Hà bấm "Gia hạn ngay" (API-03-070).
- **2b. Chứng thư do CA bên ngoài cấp.** Hà nhập chứng thư thủ công; hệ thống kiểm tra chuỗi, hạn, khớp khóa riêng và host trước khi nhận (hồ sơ HT-A, Q03-09 của FRS).
- **3a. Chứng thư khách của consumer sắp hết hạn trong 30 ngày.** Lượt gọi vẫn qua, thêm `X-DH-Cert-Expires-In-Days`; hệ thống báo chủ HTTT (FR-03-002).

**Luồng ngoại lệ.**

- **E1. Chứng thư nhập sai chuỗi, hết hạn hoặc không khớp khóa (bước 7, 2b).** ERR-03-016 (422); "Chứng thư không hợp lệ: {lý do}."
- **E2. OpenBao hoặc nhà phát hành không khả dụng khi gia hạn (bước 2).** ERR-03-015 (503); "Dịch vụ cấp chứng thư tạm thời không khả dụng. Hệ thống sẽ thử lại; chứng thư hiện tại còn hiệu lực đến {ngày}."
- **E3. Gia hạn thủ công khi đã có lần gia hạn đang chạy.** ERR-03-019 (409); "Chứng thư đã ở trạng thái đang gia hạn."
- **E4. Ngoại lệ TLS quá 180 ngày hoặc thiếu lý do (bước 5).** ERR-03-003 (400); "Thời hạn ngoại lệ không được quá 180 ngày và phải có lý do."
- **E5. Chứng thư còn dưới 7 ngày mà gia hạn tự động chưa thành công.** Cảnh báo Nghiêm trọng GW-A10 tới Hà; kiểm tra cấu hình CHK-13 chặn phát cấu hình mới chứa host đó (ERR-03-016) cho tới khi chứng thư được gia hạn.
- **E6. Bên gọi dùng TLS dưới 1.2 hoặc bộ mã yếu.** Kết nối bị đóng ở bắt tay, không có phản hồi HTTP; số lần từ chối hiện ở UI-03-12.
- **E7. SNI không khớp host nào.** ERR-03-128 (421); "Địa chỉ truy cập không thuộc dịch vụ nào của nền tảng."

**Quy tắc áp dụng.** BR-03-003, 016.

**Màn hình, API.** UI-03-12; API-03-031…035, 068, 069, 070.
:::

### 6.18. UC-03-18 · Nhận và xử lý cảnh báo an ninh của gateway

::: dac-ta
**Mục tiêu.** Cán bộ ATTT và vận hành biết trong vài phút khi gateway có dấu hiệu bị tấn công hoặc suy giảm an ninh (WAF chặn dồn dập, dò khóa, truy cập chéo tenant, cấu hình giả mạo, chứng thư sắp hết hạn), và sự kiện ra được SIEM của tỉnh.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-TENANT_OPERATOR (Chi) và ROLE-TENANT_ADMIN cùng nhận cảnh báo.

**Tác nhân phụ.** PH-13 (đánh giá luật, gửi thông báo), SIEM của tỉnh, APISIX.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-054.

**Truy vết.** REQ-03, REQ-13; quy trình Sự cố ATTT (BP-07); CMP-LAW-16; SEC-61, SEC-63, SEC-64.

**Tiền điều kiện.** Chỉ số và sự kiện an ninh của gateway đã về PH-13 (UC-03-26, FR-03-050, 052); bộ luật GW-A01…A13 đã cài ở PH-13; Dũng có `PERM-03-operate` để xác nhận.

**Kích hoạt.** Luật GW-A01 khớp: WAF chặn trên route `tra-cuu-ho-tich.v1` vượt 100 lượt/phút lúc 15:41.

**Đảm bảo tối thiểu.** Gateway vẫn chạy khi PH-13 không khả dụng; cảnh báo cùng loại và đối tượng trong 15 phút được gộp, không gửi lặp.

**Đảm bảo thành công.** Cảnh báo được tạo với mức độ, loại, đối tượng, số liệu minh chứng; Dũng nhận thông báo; thời gian phát hiện luật Nghiêm trọng không quá 5 phút; cảnh báo được xác nhận có ghi chú.

**Luồng chính.**

1. PH-13 đánh giá luật mỗi phút trên chỉ số và nhật ký của gateway; GW-A01 khớp (FR-03-054).
2. PH-13 tạo cảnh báo mức Cao, loại WAF, đối tượng route `tra-cuu-ho-tich.v1`, kèm số liệu: 142 lượt chặn trong 1 phút, gấp 14 lần mức nền 24 giờ.
3. PH-13 thông báo trong ứng dụng cho Dũng và Chi (tuân thủ FR-00-060) và gửi thư điện tử; với mức Nghiêm trọng, PH-13 thêm kênh đẩy ra SIEM qua syslog RFC 5424 hoặc OTLP.
4. Dũng mở UI-03-01 thấy cảnh báo trong khung "Cảnh báo đang mở", bấm vào để sang UI-03-07 đã lọc sẵn theo route và luật.
5. Dũng thấy 142 sự kiện cùng một luật `942100` từ dải `198.51.100.0/26`; ông quyết định chặn dải (UC-03-12) và ghi chú.
6. Dũng bấm "Xác nhận" kèm ghi chú "Đã chặn dải 198.51.100.0/26"; cảnh báo chuyển `ACKNOWLEDGED` và tiếp tục theo dõi tới khi hết điều kiện (API-03-085).

**Luồng thay thế.**

- **3a. Tỉnh chưa có SIEM.** Dùng bộ luật trên Loki và Grafana trong gói Datahub (SEC-63).
- **2a. Cảnh báo giả.** Nếu lượt bị chặn là hợp lệ, vận hành đề nghị ngoại lệ (UC-03-14) thay vì chặn địa chỉ.
- **1a. Các luật khác.** GW-A03 (truy cập chéo tenant, UC-03-03), GW-A04 (token không khớp chứng thư, UC-03-02), GW-A05 (nút từ chối ảnh chụp, UC-03-20), GW-A06 (WAF tự hạ, UC-03-13), GW-A07 (Valkey mất, UC-03-08), GW-A09 (nút lệch, UC-03-22), GW-A10 (chứng thư, UC-03-17), GW-A11 (kiểm tra tổng hợp, UC-03-28), GW-A12 (hạn mức tenant, UC-03-25), GW-A13 (bỏ nhật ký do bộ đệm đầy, UC-03-26) theo cùng luồng này.

**Luồng ngoại lệ.**

- **E1. PH-13 không khả dụng (bước 1 đến 3).** Gateway vẫn chạy; cảnh báo không phát được; `dh-connect` hiển thị "chưa có số liệu cảnh báo" và API trả ERR-03-026 (503); "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau."
- **E2. Cảnh báo trùng quá nhiều (bước 2).** Hệ thống gộp theo loại và đối tượng trong 15 phút, không gửi lặp.
- **E3. Người xác nhận không có `PERM-03-operate` (bước 6).** ERR-03-022 (403); "Bạn không có quyền xác nhận cảnh báo."

**Quy tắc áp dụng.** BR-03-007.

**Màn hình, API.** UI-03-01, UI-03-07; API-03-084, 085.
:::

### 6.19. UC-03-19 · Tổng hợp, kiểm tra hợp lệ và ký cấu hình

::: dac-ta
**Mục tiêu.** Dữ liệu đã được duyệt ở các phân hệ khác trở thành một cấu hình gateway nhất quán, đã kiểm tra, có số phiên bản và chữ ký; con người không bao giờ viết tay cấu hình APISIX và cấu hình sai không bao giờ tới gateway.

**Tác nhân chính.** PH-02 (phát sự kiện API công bố làm kích hoạt).

**Tác nhân phụ.** PH-01, PH-12, PH-20 (nguồn dữ liệu), OpenBao (ký), ROLE-TENANT_ADMIN và ROLE-PLATFORM_ADMIN (kích hoạt thủ công, `PERM-03-publish`).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-039, 040, 041.

**Truy vết.** REQ-03; quy trình Công bố API (PH-02); LGC-APIM-011; 012, 013, 014, 015; SEC-36, SEC-65.

**Tiền điều kiện.** Các phân hệ nguồn trả được dữ liệu (nếu không, dùng bản chiếu gần nhất); mẫu chính sách đã bật cho tenant (UC-03-24); tenant `T68` không ở trạng thái "giữ" sau quay lui; khóa ký `transit/keys/dh-gateway-snapshot` ở OpenBao khả dụng.

**Kích hoạt.** Lúc 11:00, PH-02 phát sự kiện "API `gui-van-ban.v2` đã công bố"; hoặc tác vụ đối chiếu 5 phút; hoặc Lan bấm "Tổng hợp lại" ở UI-03-10.

**Đảm bảo tối thiểu.** Cấu hình đang chạy không đổi nếu tổng hợp, kiểm tra hoặc ký không thành công; ảnh chụp bị từ chối được báo lại cho người phát hành cùng danh sách lỗi.

**Đảm bảo thành công.** Ảnh chụp `SIGNED` có `snapshotVersion` tăng đơn điệu (ví dụ 10413), `contentHash`, chữ ký ECDSA P-256 và danh sách phiên bản nguồn; bản ghi `EN-03-09` truy được nguồn gốc dữ liệu.

**Luồng chính.**

1. `dh-connect` nhận sự kiện của PH-02 và gom các sự kiện cùng tenant trong 3 giây thành một lần tổng hợp (FR-03-039).
2. Hệ thống đọc từ PH-02, PH-01, PH-12, PH-20 và cơ sở của PH-03 các bản ghi nguồn: API, phiên bản, backend, lược đồ OpenAPI, gói, đăng ký, consumer, gói chính sách OPA, host và hạn mức, ngoại lệ WAF, ghi đè hạn mức, chuyển tiếp tenant.
3. Hệ thống dựng mô hình cấu hình, kết xuất thành mảnh tenant `T68` (tách nhóm `EXT` và `INT` theo `exposure`) và ghép với mảnh các tenant khác cùng phần dùng chung `COMMON` thành bản ghép nền tảng của site; ghi `EN-03-09` ở `BUILT`.
4. Hệ thống chạy kiểm tra hợp lệ: cú pháp theo bộ kiểm tra của chính phiên bản APISIX đang chạy, rồi 18 quy tắc CHK-01 đến CHK-18 (lược đồ OpenAPI, chính sách OPA, danh mục plugin, trùng host, phương thức bảo mật theo mức phân loại, CORS, thời hạn chờ, hạn mức trong trần, chứng thư còn hạn…) (FR-03-040).
5. Không có lỗi: ảnh chụp chuyển bước ký. Hệ thống chuẩn hóa bản ghép (YAML chính tắc), tính `contentHash` SHA-256, cấp `snapshotVersion` từ bộ đếm của site trong giao dịch có khóa, lập manifest rồi gửi băm manifest tới OpenBao transit để ký (FR-03-041).
6. Ảnh chụp chuyển `SIGNED`; hệ thống chuyển tiếp sang UC-03-20 để phát; kiểm toán ghi nguyên nhân kích hoạt, danh sách phiên bản nguồn, số route và consumer, hash nội dung.

**Luồng thay thế.**

- **4a. Chạy thử không phát.** Lan hoặc Hà gọi API-03-058; hệ thống trả `{valid, errors[], warnings[]}` và không tạo ảnh chụp.
- **4b. Lỗi chỉ ở route của một API.** Khi `gw.snapshot.isolateBadRoute` bật (mặc định tắt), hệ thống cô lập route lỗi (hiển thị `PENDING` kèm lỗi) và vẫn phát phần còn lại.
- **3a. Chỉ đổi phần dùng chung `COMMON`.** Hệ thống chỉ tổng hợp lại mảnh `COMMON` và ghép, không đụng mảnh tenant.
- **2a. Phân hệ nguồn không trả dữ liệu.** Dùng bản chiếu gần nhất, ghi chỉ số `dh_gateway_source_stale_seconds{source}`; quá 24 giờ thì cảnh báo; không dừng tổng hợp các tenant khác.

**Luồng ngoại lệ.**

- **E1. Cấu hình không hợp lệ (bước 4).** Ảnh chụp sang `REJECTED`, hệ thống phát EVT-03-12 và thông báo người phát hành (tuân thủ FR-00-060); cấu hình đang chạy không đổi. ERR-03-005 (422); "Cấu hình gateway không hợp lệ: {n} lỗi. Xem danh sách bên dưới."
- **E2. Route thiếu lược đồ OpenAPI hoặc chính sách OPA (CHK-02, CHK-03).** ERR-03-012 (422); "Route gui-van-ban.v2 thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền nên chưa được phát."
- **E3. Plugin hoặc mẫu chính sách ngoài danh mục (CHK-04).** ERR-03-013 (422); "Route gui-van-ban.v2 dùng plugin {tên} không có trong danh mục được duyệt."
- **E4. Hạn mức vượt trần hợp đồng (CHK-12).** ERR-03-018 (422); "Hạn mức phải nằm trong trần của tỉnh ({trần} lượt/giây)."
- **E5. Chứng thư host còn dưới 7 ngày (CHK-13).** ERR-03-016 (422); "Chứng thư không hợp lệ: còn hạn dưới 7 ngày."
- **E6. Hai người cùng bấm tổng hợp.** Một lần chạy; lần còn lại nhận ERR-03-006 (409); "Đang có một lần tổng hợp cấu hình cho tỉnh này. Chờ lần đó hoàn tất."
- **E7. Tenant đang bị giữ sau quay lui.** Lần bấm thủ công nhận ERR-03-006 (409); "Cấu hình tỉnh này đang bị giữ sau lần quay lui đến {thời điểm}. Bỏ giữ trước khi tổng hợp." Sự kiện từ phân hệ khác xếp hàng.
- **E8. OpenBao hoặc dịch vụ ký không khả dụng (bước 5).** ERR-03-015 (503); "Dịch vụ ký cấu hình tạm thời không khả dụng. Thử lại sau; cấu hình đang chạy không đổi." Ảnh chụp giữ `BUILT`, thử lại theo lũy thừa tới 1 giờ rồi cảnh báo Cao.

**Quy tắc áp dụng.** BR-03-014, 016, 017, 018, 026.

**Màn hình, API.** UI-03-10; API-03-056, 057, 058, 059.
:::

### 6.20. UC-03-20 · Phát ảnh chụp và nút gateway nạp cấu hình

::: dac-ta
**Mục tiêu.** Ảnh chụp đã ký tới mọi nút gateway trong vài giây qua hai đường (bucket và Git), và mỗi nút tự nạp nguyên tử, không lượt gọi nào lỗi, không bao giờ nạp cấu hình giả hoặc cũ hơn bản đang chạy.

**Tác nhân chính.** `dh-connect` (phát) và bộ đồng bộ cấu hình cạnh mỗi pod APISIX (nạp).

**Tác nhân phụ.** Garage (bucket `dh-platform-gateway`), Git cấu hình và Argo CD, APISIX, ROLE-PLATFORM_ADMIN và ROLE-TENANT_ADMIN (phát thủ công), ROLE-PLATFORM_OPERATOR (xem kết quả).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-042, 043.

**Truy vết.** REQ-03; quy trình Công bố API (PH-02); ADR-005, ADR-013; NFR-00-012; SEC-65.

**Tiền điều kiện.** Ảnh chụp 10413 ở `SIGNED`; bucket và Git truy cập được; bộ đồng bộ có khóa công khai của khóa ký (ConfigMap) và quyền đọc bucket, Secret chứng thư.

**Kích hoạt.** Ngay sau khi ký, hoặc người có `PERM-03-publish` bấm "Phát" ở UI-03-10.

**Đảm bảo tối thiểu.** Cấu hình sai, giả hoặc cũ không bao giờ thay cấu hình đang chạy; nút khi mất mọi nguồn vẫn phục vụ bằng cấu hình đã nạp.

**Đảm bảo thành công.** Con trỏ `current` ở bucket trỏ tới phiên bản 10413; Git có commit tương ứng; mọi nút chạy 10413 trong mục tiêu 10 giây (giới hạn yêu cầu 60 giây); ảnh chụp ở `APPLIED`.

**Luồng chính.**

1. Hệ thống ghi tệp vào bucket tại `snapshots/{site}/10413/` và cuối cùng cập nhật con trỏ `current` (ghi con trỏ sau cùng để nút không đọc bản dở) (FR-03-042).
2. Hệ thống tạo commit vào kho Git cấu hình, thư mục `gateway/{site}/`; Argo CD cập nhật ConfigMap `apisix-config`.
3. Hệ thống xác nhận đã ghi vào bucket (bắt buộc) và Git (nếu lỗi thì xếp hàng thử lại tới 1 giờ), chuyển ảnh chụp sang `PUBLISHED` và phát EVT-03-01.
4. Bộ đồng bộ ở mỗi pod phát hiện con trỏ `current` đổi (kiểm tra mỗi 5 giây), tải manifest và bản ghép (FR-03-043).
5. Bộ đồng bộ kiểm chữ ký bằng khóa công khai tin cậy và `contentHash`, rồi kiểm 10413 lớn hơn `runningVersion` 10412.
6. Bộ đồng bộ chọn phần của nhóm mình (`INT` cho `apisix-int`), điền chứng thư và khóa riêng từ Secret đã gắn (khóa riêng không bao giờ ở Git hay bucket) và kiểm bằng bộ kiểm tra cấu hình của APISIX.
7. Đạt thì ghi `apisix.yaml` bằng đổi tên nguyên tử; APISIX tự nạp lại không mất kết nối; yêu cầu đang xử lý dùng cấu hình cũ, yêu cầu mới dùng cấu hình mới.
8. Nút cập nhật `dh_gateway_config_version = 10413` và `dh_gateway_config_applied_timestamp`; PH-13 thu thập; khi mọi nút đã nạp, ảnh chụp sang `APPLIED` (xem UC-03-22).

**Luồng thay thế.**

- **1a. Bucket không ghi được nhưng Git ghi được.** Ảnh chụp tới nút qua ConfigMap (chậm hơn, phụ thuộc chu kỳ Argo CD); trạng thái `PUBLISHED` kèm cờ `fastPathDown`.
- **4a. `dh-connect` và bucket cùng ngừng, pod bị lập lịch lại.** Nút dùng bản trong ConfigMap `apisix-config` đã gắn kết (bản Git gần nhất) và nếu bucket sống lại thì lấy bản mới nhất.
- **3a. Phát thủ công.** Lan hoặc Hà bấm "Phát" cho một ảnh chụp đã ký.

**Luồng ngoại lệ.**

- **E1. Cả bucket và Git đều không ghi được (bước 1, 2).** ERR-03-014 (502); "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại." Ảnh chụp giữ `SIGNED`, thử lại theo lũy thừa, cảnh báo Cao.
- **E2. Ảnh chụp mới hơn đã được phát trước (phát chen) (bước 1).** ERR-03-006 (409); "Đang có lần phát cấu hình khác. Chờ lần đó hoàn tất." Bản cũ hơn không được phát.
- **E3. Chữ ký hoặc hash sai (bước 5).** Nút từ chối, giữ bản đang chạy, ghi `result="bad_signature"`; luật GW-A05 phát cảnh báo Nghiêm trọng "nghi cấu hình giả mạo" cho Dũng và Hà (UC-03-18).
- **E4. Phiên bản không lớn hơn bản đang chạy (bước 5).** Nút bỏ qua (chống nạp lùi), không có cảnh báo.
- **E5. Cấu hình không qua bộ kiểm tra của APISIX (bước 6).** Nút từ chối, giữ bản cũ, đặt `result="invalid"`, cảnh báo Cao; `dh-connect` thấy nút `FAILED` ở UC-03-22.
- **E6. Mất kết nối bucket (bước 4).** Nút giữ cấu hình hiện tại và tiếp tục phục vụ.

**Quy tắc áp dụng.** BR-03-010, 016, 018.

**Màn hình, API.** UI-03-10, UI-03-11; API-03-060, 063, 064.
:::

### 6.21. UC-03-21 · Quay lui cấu hình khi phát gây sự cố

::: dac-ta
**Mục tiêu.** Khi một lần phát cấu hình gây sự cố, vận hành đưa gateway về trạng thái của một phiên bản trước bằng một thao tác trong vài chục giây, có dấu vết, mà vẫn giữ nguyên tắc số phiên bản chỉ tăng.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); ROLE-TENANT_ADMIN, ROLE-SECURITY_OFFICER và ROLE-PLATFORM_ADMIN cùng có `PERM-03-operate`.

**Tác nhân phụ.** `dh-connect`, bộ đồng bộ, PH-02 (nhận EVT-03-02).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-044.

**Truy vết.** REQ-03; quy trình Vận hành, sự cố cấu hình; ADR-009; SEC-65.

**Tiền điều kiện.** Ảnh chụp 10413 vừa phát làm route `gui-van-ban.v2` trỏ nhầm upstream, lượt gọi lỗi; có phiên bản trước 10412 đã `APPLIED` còn ở bucket hoặc Git; Chi có `PERM-03-operate`.

**Kích hoạt.** Chi chọn phiên bản 10412 ở UI-03-10 và bấm "Quay lui".

**Đảm bảo tối thiểu.** Số phiên bản không bao giờ lùi: quay lui sinh ảnh chụp mới; nếu quay lui không thực hiện được thì cấu hình đang chạy không đổi.

**Đảm bảo thành công.** Gateway chạy nội dung của 10412 dưới số phiên bản mới 10414; tenant ở trạng thái giữ 24 giờ; sự cố được khắc phục trong vài chục giây; kiểm toán ghi phiên bản đích, phiên bản mới, lý do, tóm tắt so sánh, thời hạn giữ.

**Luồng chính.**

1. Chi mở so sánh giữa phiên bản hiện tại 10413 và 10412 (API-03-062) để biết route, hạn mức nào sẽ đổi (FR-03-044).
2. Chi nhập lý do "Route gui-van-ban.v2 trỏ nhầm upstream, lượt gọi lỗi 502" và `holdHours` 24 mặc định, rồi xác nhận lần hai (LP-03-02).
3. Hệ thống kiểm tra phiên bản đích còn đọc được và các đối tượng tham chiếu (consumer, chứng thư, upstream) còn tồn tại.
4. Hệ thống tạo ảnh chụp mới có nội dung của 10412, chạy kiểm tra, ký và phát theo đường ưu tiên (UC-03-19, 20); trả `202` kèm `newSnapshotVersion` 10414, `restoredFrom` 10412, `holdUntil`.
5. Hệ thống đặt tenant ở trạng thái giữ 24 giờ: sự kiện từ PH-02, PH-01 xếp hàng, không tự tổng hợp lại, để lần đối chiếu định kỳ không âm thầm hoàn tác việc quay lui.
6. Hệ thống phát EVT-03-02 và EVT-03-01.
7. Sau khi PH-02 sửa upstream của `gui-van-ban.v2`, Chi bấm "Bỏ giữ"; hệ thống tổng hợp lại từ dữ liệu nguồn mới nhất (UC-03-19).

**Luồng thay thế.**

- **1a. Chỉ một route có vấn đề.** Dùng dừng API (UC-03-09) hoặc tạm ngừng khẩn cấp (UC-03-11), không cần quay lui cả mảnh tenant.
- **4a. Quay lui phạm vi `PLATFORM`.** Chỉ Hà (PA) thực hiện được.
- **7a. Hết `holdHours` mà chưa bỏ giữ.** Hệ thống cảnh báo nhưng không tự bỏ giữ.

**Luồng ngoại lệ.**

- **E1. Phiên bản đích tham chiếu đối tượng đã bị xóa hoặc chứng thư hết hạn (bước 3).** ERR-03-007 (422); "Không thể quay lui về phiên bản 10409: consumer ht-cu không còn hợp lệ."
- **E2. Có lần phát đang chạy (bước 4).** ERR-03-006 (409); "Đang có lần phát cấu hình khác. Chờ lần đó hoàn tất."
- **E3. Quay lui `PLATFORM` do người không phải PA (bước 4).** ERR-03-022 (403); "Bạn không có quyền quay lui cấu hình toàn nền tảng."
- **E4. Bấm "Tổng hợp lại" khi tenant đang giữ.** ERR-03-006 (409); "Cấu hình tỉnh này đang bị giữ sau lần quay lui đến {thời điểm}. Bỏ giữ trước khi tổng hợp."

**Quy tắc áp dụng.** BR-03-016, 018.

**Màn hình, API.** UI-03-10; API-03-056, 061, 062.
:::

### 6.22. UC-03-22 · Theo dõi nút gateway và trạng thái đồng bộ

::: dac-ta
**Mục tiêu.** Sau mỗi lần phát, vận hành biết ngay nút nào đã nhận phiên bản nào và nút nào lệch hoặc lỗi; nút lệch được phát hiện trong dưới 2 phút. Use case thay màn "danh sách gateway đang kết nối" và "giám sát CPU, Java heap" của hệ cũ.

**Tác nhân chính.** ROLE-PLATFORM_OPERATOR (Phong); ROLE-TENANT_OPERATOR (Chi).

**Tác nhân phụ.** PH-13 (Mimir cung cấp chỉ số), `dh-connect`.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-045.

**Truy vết.** REQ-03, REQ-13; quy trình Vận hành lượt gọi; LGC-APIM-023; 024, 025; ADR-005, ADR-011.

**Tiền điều kiện.** Các nút phát chỉ số Prometheus; PH-13 thu thập và truy vấn được; site có sáu nút (3 `apisix-ext`, 3 `apisix-int`).

**Kích hoạt.** Phong mở UI-03-11 sau khi UC-03-20 phát ảnh chụp 10413; hoặc tác vụ đánh giá trạng thái mỗi 30 giây của `dh-connect`.

**Đảm bảo tối thiểu.** Màn hình không bao giờ hiển thị số liệu sai; khi không có số liệu thì nói rõ "không có số liệu" thay vì số 0.

**Đảm bảo thành công.** Bảng nút phản ánh đúng `runningVersion`, `desiredVersion`, `syncState` của từng nút; nút lệch kéo dài phát cảnh báo.

**Luồng chính.**

1. `dh-connect` truy vấn PH-13 lấy chỉ số của mọi pod APISIX theo cửa và site (FR-03-045).
2. Hệ thống so `runningVersion` của từng nút với `desiredVersion` (phiên bản của ảnh chụp `PUBLISHED` mới nhất của site), rồi gán `syncState`: `IN_SYNC` (cùng phiên bản), `LAGGING` (lệch quá 60 giây), `FAILED` (nạp lỗi ở lần gần nhất), `UNKNOWN` (không có chỉ số quá 2 phút).
3. Hệ thống tính trạng thái ảnh chụp: mọi nút `IN_SYNC` thì `APPLIED`; còn nút `LAGGING` thì `PARTIAL`.
4. Phong thấy bảng nút: tên pod, cửa, site, phiên bản chạy, độ trễ nạp, kết quả lần nạp cuối, tuổi JWKS, tình trạng Valkey, chế độ WAF, CPU, bộ nhớ, kết nối; tóm tắt "5 `IN_SYNC`, 1 `LAGGING`, 0 `FAILED`".
5. Phong mở chi tiết nút `apisix-int-3` (API-03-064): đang chạy 10412, lệch 74 giây, kết quả lần nạp cuối `invalid`.
6. Nút `LAGGING` hoặc `FAILED` quá 2 phút kích hoạt luật GW-A09: cảnh báo Cao tới Phong và Hà (UC-03-18).
7. Phong chuyển thông tin cho đội phát cấu hình; sau khi nút nạp được 10413, trạng thái ảnh chụp chuyển `APPLIED`.

**Luồng thay thế.**

- **1a. PH-13 không truy vấn được.** Màn hình hiển thị "không có số liệu" thay vì sai số liệu.
- **2a. Nút mới khởi động.** Nút ở `UNKNOWN` cho tới khi phát chỉ số đầu tiên.

**Luồng ngoại lệ.**

- **E1. Không đọc được số liệu từ PH-13 (bước 1).** ERR-03-026 (503); "Chưa lấy được số liệu nút gateway từ hệ thống giám sát. Thử lại sau."
- **E2. Nút không tồn tại (bước 5).** ERR-03-001 (404); "Không tìm thấy nút apisix-int-9."
- **E3. Người không có `PERM-03-read`.** ERR-03-022 (403); "Bạn không có quyền xem trạng thái nút gateway."

**Quy tắc áp dụng.** BR-03-016.

**Màn hình, API.** UI-03-11; API-03-063, 064.
:::

### 6.23. UC-03-23 · Đồng bộ consumer khi kết nạp, tạm ngừng HTTT

::: dac-ta
**Mục tiêu.** Khi HTTT được kết nạp, tạm ngừng hoặc đổi chứng thư ở PH-01, gateway biết trong vài giây: tạo consumer, nhận phần công khai của thông tin xác thực, áp trạng thái; gateway không bao giờ giữ bí mật của client.

**Tác nhân chính.** PH-01 (saga kết nạp, gọi bằng scope `gateway:sync`).

**Tác nhân phụ.** PH-12 (tạo client ở Keycloak), `dh-connect`, bộ đồng bộ, ROLE-TENANT_ADMIN (xem ở UI-03-04, 05).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-046.

**Truy vết.** REQ-01, REQ-03; quy trình Kết nạp HTTT (BP-01); LGC-APIM-019; 020; SEC-24; D03-01 §7.3 (saga).

**Tiền điều kiện.** HTTT `HT-QLVB` đang kết nạp ở PH-01; PH-12 đã tạo client `ht-qlvb` ở realm `dh-t68` kèm chứng thư đã đăng ký; PH-01 có scope `gateway:sync`.

**Kích hoạt.** Bước "tạo consumer" của saga kết nạp; hoặc PH-01 đổi trạng thái HTTT; hoặc xoay chứng thư, khóa của client.

**Đảm bảo tối thiểu.** Không trường bí mật nào được lưu hay ghi log; gọi lặp với cùng `Idempotency-Key` cho cùng kết quả; bước sau của saga lỗi thì consumer được gỡ để bù trừ.

**Đảm bảo thành công.** Consumer `ht-qlvb` ở `ACTIVE` kèm phần công khai của thông tin xác thực, có trong ảnh chụp đang chạy; saga thấy `syncState = IN_SYNC` trong ≤ 10 giây.

**Luồng chính.**

1. PH-01 gọi `PUT /consumers/ht-qlvb` với `systemCode` `HT-QLVB`, `state` `ACTIVE`, `priorityGroup` `NORMAL`, `authMethod` `MTLS`, kèm `Idempotency-Key` (API-03-013, FR-03-046).
2. `dh-connect` kiểm tra scope `gateway:sync`, tenant lấy từ token, mã đúng mẫu `^[a-z][a-z0-9-]{2,62}$` và chưa dùng cho HTTT khác, nhóm ưu tiên hợp lệ.
3. `dh-connect` lưu consumer và gọi `PUT /consumers/ht-qlvb/credentials` lưu phần công khai: vân tay SHA-256 của chứng thư (tối đa 2), `certNotAfter` (API-03-014).
4. Hệ thống từ chối mọi trường trông như bí mật (khóa riêng, `client_secret`, khóa API dạng rõ).
5. Hệ thống kích hoạt LP-03-03 (UC-03-19, 20), phát EVT-03-04 và trả `202` kèm `effectiveBy` (dự kiến 10 giây).
6. Saga gọi `GET /consumers/ht-qlvb` (API-03-012) tới khi `syncState = IN_SYNC` thì coi bước hoàn tất; `HT-QLVB` gọi API thành công theo UC-03-01.
7. Khi HTTT bị tạm ngừng ở PH-01, PH-01 đặt `state = SUSPENDED` bằng cùng API; lượt gọi của consumer nhận `403` ERR-03-127 trong vài giây.

**Luồng thay thế.**

- **3a. Xoay chứng thư.** PH-01 thêm vân tay mới vào danh sách của consumer (tối đa 2 vân tay cùng lúc), gỡ vân tay cũ sau khi HTTT chuyển xong (UC-03-02).
- **3b. HTTT dùng khóa API trong giai đoạn chuyển đổi.** PH-01 gửi `apiKeyHash` (SHA-256 hex) và `apiKeyNotAfter` tối đa 180 ngày; không gửi khóa dạng rõ.
- **6a. Bước sau của saga thất bại.** PH-01 gọi `DELETE /consumers/ht-qlvb` (API-03-015) để bù trừ; consumer bị xóa mềm.

**Luồng ngoại lệ.**

- **E1. Mã consumer đã thuộc HTTT khác (bước 2).** ERR-03-002 (409); "Mã ht-qlvb đã được dùng cho HTTT khác."
- **E2. Dữ liệu có trường bí mật hoặc sai dạng (bước 4).** ERR-03-003 (400); "Không gửi bí mật tới gateway. Chỉ gửi vân tay chứng thư hoặc băm khóa."
- **E3. Xóa consumer còn đăng ký hiệu lực (bước 6a).** ERR-03-017 (409); "HTTT còn {n} đăng ký sử dụng đang hiệu lực. Thu hồi đăng ký trước khi gỡ."
- **E4. Gọi thiếu scope (bước 2).** ERR-03-022 (403); lỗi giữa hai dịch vụ nên thân RFC 9457 nêu scope còn thiếu.
- **E5. Ảnh chụp bị từ chối khi tổng hợp.** Consumer đã lưu nhưng chưa có ở gateway; saga không thấy `IN_SYNC` nên chờ rồi báo lỗi quá hạn ở PH-01; xử lý theo UC-03-19 E1.

**Quy tắc áp dụng.** BR-03-021, 022.

**Màn hình, API.** UI-03-04, UI-03-05; API-03-011…015.
:::

### 6.24. UC-03-24 · Quản lý mẫu chính sách và chạy thử chính sách

::: dac-ta
**Mục tiêu.** Chính sách của mọi API thống nhất và rà soát được một lần nhờ bộ mẫu duyệt sẵn; trước khi phát cấu hình hoặc khi điều tra vì sao một HTTT bị chặn, quản trị biết một yêu cầu giả định sẽ đi qua gateway thế nào mà không tác động lưu lượng thật.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan).

**Tác nhân phụ.** ROLE-PLATFORM_ADMIN (Hà, phát hành mẫu theo bản phát hành), ROLE-SECURITY_OFFICER (Dũng, cùng chạy thử), PH-02 (gán mẫu cho gói), OPA.

**Mức ưu tiên.** M (mẫu chính sách) · S, Đợt 2 (chạy thử).

**FR hiện thực.** FR-03-048, 057.

**Truy vết.** REQ-03; quy trình Công bố API (PH-02); LGC-APIM-015; SEC-26, SEC-42.

**Tiền điều kiện.** Bản phát hành nền tảng mang danh mục mười một mẫu đã ký (`tpl-api-oauth2`, `tpl-api-mtls`, `tpl-api-open-data`, `tpl-ui-bff`, `tpl-callback-ext`, `tpl-websocket`, `tpl-sandbox-static`, `tpl-ai-egress`, `tpl-platform-int`, `tpl-inbound-ndxp`, `tpl-migration-shadow`); Lan có `PERM-03-admin`; có ảnh chụp đang chạy và gói chính sách OPA hiện hành.

**Kích hoạt.** Lan mở UI-03-13; sau đó mở UI-03-14 và bấm "Chạy thử".

**Đảm bảo tối thiểu.** Không plugin nào ngoài danh mục được chạy; chạy thử không gọi backend, không đọc hay ghi bộ đếm Valkey và không nhận token hay khóa thật.

**Đảm bảo thành công.** Trạng thái bật, tắt mẫu của tenant được lưu và kiểm toán; kết quả chạy thử nêu từng chốt `PASS`, `BLOCK` hoặc `SKIP`, mã lỗi, chính sách áp dụng và mã HTTP dự kiến.

**Luồng chính.**

1. Lan mở UI-03-13 thấy mười một mẫu kèm danh sách plugin có thứ tự, tham số mặc định và miền cho phép chỉnh (FR-03-048).
2. Lan tắt mẫu `tpl-websocket` cho tenant vì tỉnh chưa có API kết nối dài; hệ thống kiểm tra chưa route nào dùng mẫu này rồi lưu và ghi kiểm toán.
3. Khi PH-02 soạn gói cho API mới, PH-02 chọn mẫu `tpl-api-oauth2` và chỉnh tham số trong miền; tham số ngoài miền bị từ chối ở kiểm tra cấu hình (UC-03-19).
4. Lan mở UI-03-14, nhập `host` `api.t68.datahub.gov.vn`, `method` `GET`, `path` `/api/hotich/v1/ho-tich/123`, `consumerCode` `ht-qlvb`, `claims` `{"scope":"hotich.read"}` (FR-03-057).
5. Hệ thống kiểm tra đầu vào không chứa token hay khóa thật, rồi bộ mô phỏng của `dh-connect` đi qua từng chốt theo thứ tự ở FRS §2.4: chọn route, phương thức bảo mật, đăng ký, phạm vi, đường dẫn, hạn mức hiệu lực; chạy Coraza thử trên mẫu yêu cầu và OPA đánh giá khô.
6. Hệ thống trả kết quả: mọi chốt `PASS`, hạn mức hiệu lực 20 lượt/giây, `expectedStatus` 200.
7. Lan đổi `claims` thành `{"scope":"khac.read"}` và chạy lại: chốt phạm vi `BLOCK` với ERR-03-107, `expectedStatus` 403, các chốt sau `SKIP`.

**Luồng thay thế.**

- **4a. Mô phỏng trên ảnh chụp `BUILT` chưa phát.** Lan chọn `snapshotVersion` của ảnh chụp chưa phát và so sánh kết quả với ảnh chụp đang chạy để biết thay đổi có làm đổi kết quả không.
- **2a. Tenant cần một biến thể không có trong danh mục.** Lan gửi đề nghị tới Hà để thêm mẫu ở bản phát hành sau; không có đường tự thêm.
- **2b. Nền tảng phát hành phiên bản mẫu mới.** PH-03 tổng hợp lại các route dùng mẫu, mặc định áp phiên bản mới ở lần phát kế tiếp kèm ghi chú thay đổi.

**Luồng ngoại lệ.**

- **E1. Mẫu hoặc plugin ngoài danh mục (bước 3).** ERR-03-013 (422); "Mẫu chính sách hoặc plugin {tên} không có trong danh mục được duyệt."
- **E2. Tham số ngoài miền cho phép (bước 3).** ERR-03-003 (400); "Tham số {tên} nằm ngoài miền cho phép của mẫu {mã}."
- **E3. Tắt mẫu đang được route dùng (bước 2).** ERR-03-019 (409) kèm danh sách route dùng; "Mẫu tpl-api-oauth2 đang được {n} route dùng."
- **E4. Đầu vào chạy thử có token hoặc khóa thật (bước 5).** ERR-03-003 (400); "Không nhập token hoặc khóa thật. Chỉ nhập phạm vi (scope) và thông tin giả định."
- **E5. Ảnh chụp chọn không còn (bước 4a).** ERR-03-001 (404); "Không tìm thấy ảnh chụp cấu hình phiên bản {v}."

**Quy tắc áp dụng.** BR-03-014, 017, 027.

**Màn hình, API.** UI-03-13, UI-03-14; API-03-065, 066, 067, 088.
:::

### 6.25. UC-03-25 · Đặt hạn mức toàn tenant và hạn mức theo route

::: dac-ta
**Mục tiêu.** Một tỉnh không chiếm hết năng lực gateway dùng chung; quản trị điều chỉnh nhanh hạn mức khi cao điểm hoặc sự cố mà không phải sửa gói ở PH-02, và việc hạ hạn mức có người thứ hai duyệt.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan, người đặt).

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng, người duyệt khi hạ), PH-20 (cung cấp trần hợp đồng), PH-13 (lưu lượng trung bình 7 ngày).

**Mức ưu tiên.** M (hạn mức tenant) · S, Đợt 2 (hạn mức theo route).

**FR hiện thực.** FR-03-023, 024.

**Truy vết.** REQ-03, REQ-20; quy trình Khởi tạo và quản trị tenant (BP-08); LGC-APIM-012; 013; SEC-86; D03-10 §5.3.

**Tiền điều kiện.** Hạn mức hợp đồng của `T68` là 800 lượt/giây (trần) và hiện hành 500 lượt/giây (mặc định); Lan có `PERM-03-limit` và `PERM-03-approve`; consumer `ht-qlvb` và route `tra-cuu-ho-tich.v1` tồn tại.

**Kích hoạt.** Lan mở UI-03-06; GW-A12 báo `T68` dùng trên 80% hạn mức liên tục 1 phút trước ngày nộp hồ sơ cao điểm.

**Đảm bảo tối thiểu.** Không hạn mức nào vượt trần hợp đồng hay thấp hơn mức tối thiểu 10; hạ hạn mức không có hiệu lực khi chưa được duyệt.

**Đảm bảo thành công.** Hạn mức mới nằm trong ảnh chụp đang chạy; `EN-03-06` lưu đúng phạm vi; kiểm toán ghi người đặt, người duyệt, giá trị trước và sau, `validTo`, lý do.

**Luồng chính.**

1. Lan nâng tạm hạn mức tenant lên 700 lượt/giây có `validTo` 02/12/2026, lý do "Cao điểm nộp hồ sơ"; hệ thống kiểm tra không vượt trần 800 (FR-03-023).
2. Hệ thống lưu và kích hoạt LP-03-03; phát EVT-03-11; trả `200` kèm hạn mức hiệu lực `{limitPerSecond: 700, burst, validTo, ceiling: 800}`. Hết `validTo` hạn mức tự về 500.
3. Sau cao điểm, Lan muốn hạ hạn mức mặc định xuống 400 để tiết kiệm năng lực; vì là hạ nên hệ thống tạo yêu cầu thay đổi `EN-03-15` chờ duyệt và trả `202` (LP-03-01).
4. Dũng mở UI-03-17, xem giá trị trước và sau rồi bấm "Duyệt"; hệ thống phát ảnh chụp mới và EVT-03-11.
5. Lan thêm hạn mức riêng: phạm vi `CONSUMER_ROUTE`, consumer `ht-qlvb`, route `tra-cuu-ho-tich.v1`, giới hạn 100, cửa sổ 60 giây, dung sai 10, `validTo` 31/12/2026, lý do "Giảm tạm do HT-QLVB gọi lặp lỗi" (FR-03-024).
6. Hệ thống cảnh báo giới hạn 100 thấp hơn lưu lượng trung bình 7 ngày của cặp này (đọc từ PH-13); Lan xác nhận; hệ thống lưu `EN-03-06` và phát ảnh chụp mới.
7. Ở gateway, một lượt gọi phải qua mọi hạn mức khớp, đánh giá từ cụ thể đến chung: `CONSUMER_ROUTE`, rồi `ROUTE`, rồi `TENANT`; từ chối ở tầng nào thì mã lỗi phản ánh tầng đó (ERR-03-116 hoặc ERR-03-118).

**Luồng thay thế.**

- **1a. Tăng hạn mức không cần duyệt.** Chỉ hạ hạn mức tenant mới cần người thứ hai (BR-03-019).
- **5a. Hạn mức theo `ROUTE` hoặc `CONSUMER`.** Lan chọn phạm vi khác; hệ thống kiểm tra mức không vượt hạn mức tenant.
- **5b. Đối tượng thuộc nhóm `ESSENTIAL`.** Cảnh báo ở bước 6 mạnh hơn.

**Luồng ngoại lệ.**

- **E1. Đặt vượt trần hợp đồng hoặc dưới mức tối thiểu 10 (bước 1, 3).** ERR-03-018 (422); "Hạn mức phải từ 10 đến 800 lượt/giây theo hợp đồng của tỉnh."
- **E2. Hạn mức theo route vượt trần của tỉnh (bước 5).** ERR-03-018 (422); "Hạn mức phải nằm trong trần của tỉnh (800 lượt/giây)."
- **E3. Người hạ hạn mức tự duyệt (bước 4).** ERR-03-008 (403); "Bạn đã đề nghị thay đổi này nên không thể tự duyệt."
- **E4. Route hoặc HTTT không tồn tại hoặc thuộc tenant khác (bước 5).** ERR-03-001 (404); "Không tìm thấy route hoặc HTTT ht-qlvb."
- **E5. Gateway từ chối vì vượt hạn mức tenant (bước 7).** ERR-03-118 (429) kèm `Retry-After: 1`; "Tỉnh T68 đang vượt hạn mức 500 lượt/giây của nền tảng. Thử lại sau giây lát."
- **E6. Gateway từ chối vì vượt hạn mức riêng cặp consumer–route (bước 7).** ERR-03-116 (429); "HTTT ht-qlvb đã dùng hết 100 lượt trong 60 giây cho API tra-cuu-ho-tich.v1. Thử lại sau {s} giây."

**Quy tắc áp dụng.** BR-03-005, 019.

**Màn hình, API.** UI-03-06, UI-03-17; API-03-023…028, 071, 072, 073.
:::

### 6.26. UC-03-26 · Tra cứu và xuất nhật ký lượt gọi

::: dac-ta
**Mục tiêu.** Vận hành, Cán bộ ATTT và kiểm toán viên tìm một lượt gọi lỗi trong vài giây và xuất bằng chứng phục vụ điều tra, trong khi nhật ký chỉ có siêu dữ liệu, không thân bản tin và không dữ liệu cá nhân. Use case thay màn "Log request của Application" ở hệ cũ.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); ROLE-SECURITY_OFFICER (Dũng), ROLE-TENANT_ADMIN (Lan) và ROLE-AUDITOR (Thảo) cùng có `PERM-03-log-read`.

**Tác nhân phụ.** PH-13 (ClickHouse giữ siêu dữ liệu), gateway (ghi bản ghi), OTel Collector (che dữ liệu lần hai).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-050, 051.

**Truy vết.** REQ-03, REQ-13; quy trình Sự cố ATTT, thanh tra (BP-07); LGC-APIM-022; CMP-LAW-05; SEC-32, SEC-61.

**Tiền điều kiện.** Siêu dữ liệu đã có ở PH-13; người dùng đã chọn tenant `T68`; người dùng có `PERM-03-log-read`.

**Kích hoạt.** Đầu mối `HT-TUPHAP` báo yêu cầu bị `403` lúc 09:14; Chi mở UI-03-09 và dán `traceId` `4bf92f3577b34da6a3ce929d0e0e4736` vào ô tìm.

**Đảm bảo tối thiểu.** Không bản ghi nào chứa thân yêu cầu, thân phản hồi, giá trị `Authorization`, khóa API, cookie hay giá trị tham số truy vấn; đối tượng của tenant khác không bao giờ trả về.

**Đảm bảo thành công.** Chi thấy đúng lượt gọi cùng kết quả từng chốt trong p95 ≤ 3 giây; lượt xuất có kiểm toán và tệp tải được trong 24 giờ.

**Luồng chính.**

1. Sau mỗi lượt gọi, gateway lập bản ghi siêu dữ liệu và gửi qua bộ đệm đĩa tới PH-13; Collector kiểm tra lần hai theo mẫu (số định danh 12 số, số điện thoại, thư điện tử) rồi PH-13 ghi với nhãn `tenant` bắt buộc (FR-03-050).
2. Chi tra theo `traceId`: hệ thống bỏ giới hạn khoảng thời gian mặc định và tìm trong 12 tháng (FR-03-051).
3. Hệ thống truy vấn kho của PH-13 với điều kiện tenant lấy từ token và trả danh sách phân trang; `srcIp` chỉ hiển thị vì Chi có `PERM-03-log-read`.
4. Chi mở dòng duy nhất: `status` 403, `errorCode` ERR-03-109, `wafResult` `BLOCK`, `routeCode` `tra-cuu-ho-tich.v1`, `consumerCode` `ht-tuphap`, `snapshotVersion` 10412, cùng liên kết sang vết ở PH-13.
5. Chi bấm "Đề nghị ngoại lệ" để sang UC-03-14, hoặc quay lại danh sách lọc theo `consumerCode` và khoảng 09:00 đến 10:00.
6. Thảo cần bằng chứng cho đợt thanh tra: lọc `status` ≥ 400 trong 7 ngày rồi bấm "Xuất"; vì trên 10.000 dòng nên tác vụ chạy nền và thông báo khi xong (tuân thủ FR-00-031); tệp hạn tải 24 giờ, tối đa 100.000 dòng mỗi lần.
7. Hệ thống ghi kiểm toán việc xuất và việc xem chi tiết có `srcIp`: người dùng, bộ lọc, số dòng, thời điểm.

**Luồng thay thế.**

- **1a. Route dữ liệu mở (`KEYLESS`).** Bản ghi có `consumerCode` để trống, địa chỉ nguồn vẫn ghi.
- **3a. Mở từ tab "Nhật ký" ở UI-03-05.** Bộ lọc `consumerCode` điền sẵn.
- **6a. Tra theo `traceId` cũ hơn 31 ngày.** Được phép trong 12 tháng vì bỏ giới hạn khoảng mặc định.

**Luồng ngoại lệ.**

- **E1. Khoảng thời gian quá rộng (bước 3).** ERR-03-021 (400); "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất."
- **E2. Kho của PH-13 không khả dụng (bước 3).** ERR-03-026 (503); "Chưa truy vấn được nhật ký lượt gọi. Thử lại sau."
- **E3. Người không có quyền (bước 3).** ERR-03-022 (403); "Bạn không có quyền xem nhật ký lượt gọi."
- **E4. Xuất vượt số dòng tối đa (bước 6).** ERR-03-021 (400) với gợi ý thu hẹp bộ lọc.
- **E5. Bộ đệm đĩa của gateway đầy do PH-13 ngừng lâu (bước 1).** Gateway bỏ bản ghi cũ nhất, tăng `dh_gateway_accesslog_dropped_total` và cảnh báo Cao GW-A13; không ảnh hưởng lượt gọi.
- **E6. Đối tượng của tenant khác.** Trả như không tồn tại, ERR-03-001 (404), cùng thân với đối tượng không có thật.

**Quy tắc áp dụng.** BR-03-007, 023, 028.

**Màn hình, API.** UI-03-09, UI-03-05; API-03-074, 075, 076.
:::

### 6.27. UC-03-27 · Xem tổng quan lưu lượng và báo cáo sử dụng

::: dac-ta
**Mục tiêu.** Vận hành nắm sức khỏe của cổng trong một màn hình đầu ca trực, và quản trị tỉnh có báo cáo theo HTTT, route, gói để rà soát đăng ký và lập kế hoạch năng lực; số liệu chỉ phục vụ bảo vệ hệ thống và thống kê, không tính tiền.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi, xem tổng quan); ROLE-TENANT_ADMIN (Lan, xem và xuất báo cáo).

**Tác nhân phụ.** PH-13 (Mimir, ClickHouse), gateway (phát chỉ số).

**Mức ưu tiên.** M (chỉ số, bảng điều khiển) · S, Đợt 2 (báo cáo sử dụng).

**FR hiện thực.** FR-03-052, 055, 058.

**Truy vết.** REQ-03, REQ-13, REQ-16; quy trình Giám sát, báo cáo (BP-07); LGC-APIM-022; 026; KPI-03, KPI-04.

**Tiền điều kiện.** Chỉ số và siêu dữ liệu đã về PH-13; người dùng đã chọn tenant; bản tổng hợp theo ngày của siêu dữ liệu có ở PH-13.

**Kích hoạt.** Chi mở UI-03-01 lúc 07:55 đầu ca; Lan mở tab "Báo cáo sử dụng" và chọn kỳ tháng 11/2026.

**Đảm bảo tối thiểu.** Khi PH-13 không trả số liệu, màn hình hiển thị "Chưa có số liệu" chứ không hiển thị số 0 gây hiểu nhầm; mọi số liệu là của đúng tenant.

**Đảm bảo thành công.** Chi thấy tình hình cổng với độ trễ số liệu không quá 15 giây; Lan có báo cáo đúng kỳ, loại các lượt kiểm tra tổng hợp, và tệp xuất có kiểm toán.

**Luồng chính.**

1. Mỗi nút APISIX phơi chỉ số Prometheus ở cổng quản lý (không ở cổng dữ liệu) và phát span OTLP cho từng chốt chính; Prometheus của PH-13 lấy mẫu mỗi 15 giây (FR-03-052).
2. Chi mở UI-03-01, chọn khoảng `1h`; hệ thống truy vấn PH-13 (API-03-077) và hiển thị năm thẻ: lượt gọi mỗi giây, tỉ lệ lỗi, độ trễ thêm p95 so mục tiêu 50 ms, kết nối đang mở, nút đồng bộ "6/6" (FR-03-055).
3. Hệ thống hiển thị biểu đồ lưu lượng tách `2xx`, `4xx`, `5xx` và phần bị gateway từ chối (WAF, hạn mức, xác thực), hai bảng xếp hạng HTTT và route (API-03-078, 079), khung cảnh báo đang mở và dải kiểm tra tổng hợp.
4. Chi thấy `ht-qlvb` dùng 91% hạn mức nên bấm vào HTTT để lọc cả trang; bấm cột lỗi để mở UI-03-09 đã lọc sẵn (UC-03-26). Màn hình tự làm mới 15 giây.
5. Lan mở tab "Báo cáo sử dụng", chọn kỳ `thang` 11/2026, `groupBy` `CONSUMER` (FR-03-058).
6. Hệ thống kiểm tra khoảng thời gian không quá 12 tháng, truy vấn bản tổng hợp ngày ở PH-13 theo tenant của token, loại các lượt `synthetic`, và tính mỗi nhóm: số lượt, tỉ lệ `4xx`, `5xx`, p95, byte vào ra, số lượt bị từ chối theo lý do, mức dùng so với hạn ngạch (API-03-089).
7. Lan có `PERM-03-log-read` nên bấm "Xuất" xlsx; trên 10.000 dòng thì chạy nền (tuân thủ FR-00-031); xuất có kiểm toán (API-03-090).

**Luồng thay thế.**

- **2a. PA hoặc PO xem tổng hợp liên tenant.** Chỉ ở mức tổng, không có chi tiết từng tenant; xem chi tiết tenant khác phải đi đường truy cập liên tenant có lý do (ngoài PH-03).
- **5a. Chủ dịch vụ chỉ muốn xem HTTT dùng API của mình.** Bộ lọc route lấy theo API thuộc tổ chức của họ (ROLE-SERVICE_OWNER ở PH-02).
- **1a. Tỉnh nhỏ không có PH-13 đầy đủ.** Chỉ số vẫn phơi ra để công cụ giám sát khác lấy.

**Luồng ngoại lệ.**

- **E1. PH-13 không khả dụng (bước 2, 6).** ERR-03-026 (503); "Chưa lấy được số liệu lưu lượng. Thử lại sau." Màn hình hiển thị "Chưa có số liệu".
- **E2. Khoảng thời gian báo cáo quá 12 tháng (bước 6).** ERR-03-021 (400); "Báo cáo chỉ gồm 12 tháng gần nhất."
- **E3. Khoảng chọn không hợp lệ (bước 2).** ERR-03-003 (400); "Giá trị của khoang phải thuộc 15m, 1h, 24h, 7d."
- **E4. Collector hoặc Prometheus không khả dụng (bước 1).** Gateway đệm vết cục bộ có giới hạn và bỏ điểm cũ nhất khi đầy; chỉ số là kéo nên chỉ thiếu điểm lấy mẫu.
- **E5. Số chuỗi chỉ số vượt trần 500 giá trị nhãn `consumer` (bước 1).** Nhãn gộp `other`, cảnh báo Trung bình (Q03-08 của FRS).

**Quy tắc áp dụng.** BR-03-007, 020, 023, 028.

**Màn hình, API.** UI-03-01; API-03-077, 078, 079, 089, 090.
:::

### 6.28. UC-03-28 · Cấu hình kiểm tra tổng hợp cho API quan trọng

::: dac-ta
**Mục tiêu.** Sự cố của một API quan trọng được phát hiện trong dưới 3 phút, trước khi người dân và HTTT gặp lỗi, bằng cách gọi thử đúng đường đi thật qua gateway mỗi phút.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan).

**Tác nhân phụ.** Bộ chạy kiểm tra (hồ sơ `probe` của `dh-runtime`), Keycloak, OpenBao, ROLE-TENANT_OPERATOR (Chi, nhận cảnh báo), PH-02 (đánh dấu `critical`).

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-03-053.

**Truy vết.** REQ-03, REQ-13; quy trình Giám sát, báo cáo (BP-07); D03-01 §4.3; KPI-03.

**Tiền điều kiện.** API `tra-cuu-ho-tich.v1` được PH-02 đánh dấu `critical`; có consumer kiểm tra `dh-synthetic-t68` với phạm vi chỉ-đọc và gói riêng (hạn mức tách khỏi HTTT thật); Lan có `PERM-03-admin`.

**Kích hoạt.** Lan bấm "Thêm kiểm tra" ở UI-03-01.

**Đảm bảo tối thiểu.** Kiểm tra chỉ dùng yêu cầu đọc không tác dụng phụ; lượt kiểm tra không tăng bộ đếm hạn mức của HTTT thật, không gọi backend ngoài phạm vi đã khai và bị loại khỏi báo cáo sử dụng (BR-03-027).

**Đảm bảo thành công.** Lịch kiểm tra chạy mỗi 60 giây không cần `dh-connect`; kết quả lên, xuống, độ trễ hiển thị ở UI-03-01; hai lần thất bại liên tiếp phát cảnh báo Cao tới Chi.

**Luồng chính.**

1. Lan khai báo kiểm tra: `checkCode` `ht-tra-cuu-ho-tich`, `routeCode` `tra-cuu-ho-tich.v1`, `method` `GET`, `path` `/ho-tich/KT-0001`, `expectedStatus` `[200]`, `timeoutMs` 10.000, `intervalSeconds` 60 (API-03-081).
2. Hệ thống kiểm tra phương thức an toàn (GET hoặc HEAD) và tồn tại consumer kiểm tra, lưu kiểm tra (FR-03-053).
3. Cấu hình kiểm tra được phát tới bộ chạy qua ảnh chụp hoặc ConfigMap (LP-03-03); bộ chạy không cần `dh-connect` khi chạy.
4. Mỗi 60 giây bộ chạy lấy token của consumer kiểm tra từ Keycloak (bí mật từ OpenBao) rồi gọi API qua địa chỉ thật của cửa vào.
5. Bộ chạy so mã trả về và nội dung kỳ vọng, đo độ trễ, ghi `dh_gateway_synthetic_up{check}` và `dh_gateway_synthetic_duration_seconds{check}`; lượt gọi được đánh dấu `synthetic = true` trong nhật ký.
6. Lúc 15:10 và 15:11 kiểm tra thất bại liên tiếp: luật GW-A11 phát cảnh báo Cao tới Chi và hệ thống phát EVT-03-09 (UC-03-18).
7. UI-03-01 hiển thị từng kiểm tra: lên hay xuống, độ trễ p95, thời điểm thất bại gần nhất. Lan sửa hoặc xóa kiểm tra khi cần (API-03-082, 083); mọi thay đổi có kiểm toán.

**Luồng thay thế.**

- **1a. API cần dữ liệu đầu vào đặc thù.** Dùng đối tượng kiểm tra do chủ dịch vụ cung cấp, ghi rõ ở cấu hình kiểm tra.
- **1b. API không có yêu cầu an toàn.** Không được khai báo kiểm tra tổng hợp.

**Luồng ngoại lệ.**

- **E1. Thiếu consumer kiểm tra hoặc gói (bước 2).** ERR-03-001 (404); "Chưa có consumer kiểm tra cho tỉnh. Tạo consumer kiểm tra trước."
- **E2. Khai báo phương thức ghi (bước 2).** ERR-03-003 (400); "Kiểm tra tổng hợp chỉ dùng phương thức đọc (GET, HEAD)."
- **E3. Kiểm tra vượt hạn mức riêng (bước 4).** Bộ chạy giảm tần suất và phát cảnh báo Trung bình.
- **E4. Không lấy được token (bước 4).** Kiểm tra tính là thất bại; cảnh báo theo bước 6.

**Quy tắc áp dụng.** BR-03-027.

**Màn hình, API.** UI-03-01; API-03-080, 081, 082, 083.
:::

### 6.29. UC-03-29 · Điều chỉnh tham số gateway của tỉnh

::: dac-ta
**Mục tiêu.** Quản trị tỉnh chỉnh tham số vận hành của gateway (giới hạn theo địa chỉ, thời hạn chờ, lấy mẫu vết, ngưỡng cảnh báo) trong miền nền tảng cho phép, mà không sửa mã hay cấu hình tay.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Lan).

**Tác nhân phụ.** ROLE-PLATFORM_ADMIN (Hà, đặt trần nền tảng và tiêu đề bảo mật mặc định), ROLE-SECURITY_OFFICER (Dũng, duyệt danh sách địa chỉ tin cậy).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-03-056, 003, 011.

**Truy vết.** REQ-03, REQ-18; quy trình Quản trị tenant (BP-08); NFR-00-052; D03-10 §5.3.

**Tiền điều kiện.** Tenant `T68` ở `ACTIVE`; có bảng tham số mặc định (FRS §8.2); Lan có `PERM-03-admin`.

**Kích hoạt.** Lan mở UI-03-16 vì các sở dùng chung địa chỉ sau NAT của Sở TT&TT bị `429` ERR-03-119 quá thường xuyên, rồi bấm "Lưu".

**Đảm bảo tối thiểu.** Mọi giá trị nằm trong miền và trần; tham số rủi ro cao không đổi ở đây mà đi qua chức năng có bốn mắt.

**Đảm bảo thành công.** Tham số mới có phiên bản, có kiểm toán và nằm trong ảnh chụp đang chạy trong 60 giây (thường dưới 10 giây).

**Luồng chính.**

1. Hệ thống hiển thị tham số hiện hành kèm mặc định, miền, trần nền tảng và người sửa gần nhất (FR-03-056).
2. Lan đổi `gw.ip.apiReqPerSecond` từ 200 lên 300 (miền 20 đến 2.000) và `gw.trace.successSampling` từ 0,05 lên 0,1; bấm "Lưu" kèm `If-Match` (API-03-087).
3. Hệ thống kiểm tra từng giá trị theo kiểu, miền, trần và kiểm tra `If-Match` còn khớp.
4. Hệ thống lưu giá trị mới có phiên bản, ghi kiểm toán (khóa, giá trị trước và sau, người sửa) và kích hoạt LP-03-03 vì tham số ảnh hưởng cấu hình gateway.
5. Giá trị có hiệu lực trong 60 giây; chốt giới hạn theo địa chỉ (UC-03-05) dùng ngưỡng 300 từ ảnh chụp mới (FR-03-003).
6. Lan cũng thêm dải địa chỉ của Sở TT&TT vào `gw.ip.trustedCidrs`; vì danh sách tin cậy do SO duyệt, hệ thống chuyển đề xuất cho Dũng và ghi kiểm toán khi Dũng duyệt.
7. Hà đặt tiêu đề bảo mật mặc định của nền tảng (xóa `Server`, `X-Powered-By`, thêm `Strict-Transport-Security`, `X-Content-Type-Options`, `Referrer-Policy`) và route nào cần giữ một tiêu đề của backend phải khai danh sách tiêu đề được phép qua mẫu chính sách (FR-03-011; UC-03-24).

**Luồng thay thế.**

- **2a. Đặt lại về mặc định cho một khóa.** Lan xóa giá trị riêng của tenant; ảnh chụp mới dùng mặc định nền tảng.
- **4a. Tham số hạn mức tenant.** Hệ thống phát thêm EVT-03-11.

**Luồng ngoại lệ.**

- **E1. Giá trị sai kiểu hoặc ngoài miền (bước 3).** ERR-03-003 (400); "Giá trị của gw.ip.apiReqPerSecond phải thuộc 20…2.000."
- **E2. Vượt trần nền tảng (bước 3).** ERR-03-018 (422); "gw.ip.apiReqPerSecond không được vượt 2.000 theo hợp đồng của tỉnh."
- **E3. ETag cũ vì người khác sửa trước (bước 3).** ERR-03-004 (412); "Tham số vừa được người khác sửa. Tải lại để xem thay đổi."
- **E4. Thử đổi tham số rủi ro cao ở đây (`gw.waf.mode`, `gw.tenantRateLimit.perSecond`, `exposure`).** ERR-03-003 (400); tham số đó đổi ở UC-03-13, 25, 16.

**Quy tắc áp dụng.** BR-03-005, 013, 016, 019.

**Màn hình, API.** UI-03-16; API-03-086, 087.
:::

### 6.30. UC-03-30 · Chuyển tiếp lượt gọi của tỉnh đã sáp nhập

::: dac-ta
**Mục tiêu.** Khi hai tỉnh sáp nhập, HTTT của tỉnh cũ vẫn gọi được API theo địa chỉ cũ trong thời gian chuyển tiếp (mặc định 180 ngày): gateway chuyển lượt gọi sang API tương ứng của tenant đích kèm tiêu đề cảnh báo, rồi chấm dứt đúng hạn.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà).

**Tác nhân phụ.** PH-20 (chuyển tenant nguồn sang `MERGED`, cung cấp bảng ánh xạ API), HTTT của tenant nguồn (ví dụ `ht-cu-t69`), đầu mối HTTT.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-03-037.

**Truy vết.** REQ-20, REQ-03; quy trình Sáp nhập tỉnh (BP-08); D03-10 §5.4.

**Tiền điều kiện.** Tenant nguồn `T69` ở `MERGED`; tenant đích `T68` ở `ACTIVE`; có bảng ánh xạ API nguồn sang API đích do PH-20 cung cấp; HTTT của `T69` đã được cấp song song thông tin xác thực ở `T68`.

**Kích hoạt.** PH-20 chuyển `T69` sang `MERGED`; Hà tạo chuyển tiếp ở UI-03-16.

**Đảm bảo tối thiểu.** Chuyển tiếp không bao giờ bỏ qua cách ly tenant: lượt gọi luôn được xác thực bằng token của tenant đích; không có hai route của hai tenant trùng host và đường dẫn.

**Đảm bảo thành công.** HTTT của tỉnh cũ không bị gián đoạn, nhận `Deprecation`, `Sunset`, `Link` trong thời gian chuyển tiếp; tới `endAt` địa chỉ cũ trả `410`.

**Luồng chính.**

1. Hà tạo chuyển tiếp: `fromTenant` `T69`, `toTenant` `T68`, `startAt` 01/01/2027, `endAt` mặc định 180 ngày sau, `routeMap` các route nguồn sang route đích, `identityMode` `TOKEN_OF_TARGET` (API-03-095).
2. Hệ thống kiểm tra tenant nguồn `MERGED`, tenant đích `ACTIVE`, các route đích tồn tại (FR-03-037).
3. Hệ thống kích hoạt LP-03-03 sinh ảnh chụp mới cho cả hai tenant: host của tenant nguồn có route chuyển tiếp trỏ route đích; phát EVT-03-10.
4. Một HTTT gọi địa chỉ cũ; gateway xác thực bằng token của tenant đích, đặt `X-DH-Tenant` là `T68` và chuyển tới route đích.
5. Gateway thêm `Deprecation: true`, `Sunset: {endAt}` và `Link` tới địa chỉ mới vào phản hồi.
6. Mỗi tuần hệ thống thống kê HTTT còn gọi địa chỉ cũ và gửi đầu mối.
7. Tới `endAt`, chuyển tiếp kết thúc (API-03-096), phát EVT-03-10; host nguồn trả `410`.

**Luồng thay thế.**

- **4a. HTTT chưa đổi thông tin xác thực.** Token của tenant nguồn bị từ chối bằng ERR-03-106 kèm hướng dẫn nhận thông tin xác thực mới.
- **7a. Kết thúc sớm.** Hà bấm "Kết thúc" trước `endAt` khi không còn HTTT gọi địa chỉ cũ.

**Luồng ngoại lệ.**

- **E1. Tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp (bước 2).** ERR-03-025 (409); "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy."
- **E2. Token của tenant nguồn (bước 4a).** ERR-03-106 (401); "Địa chỉ này đã chuyển sang tỉnh T68. Dùng thông tin xác thực mới của tỉnh T68."
- **E3. Gọi địa chỉ cũ sau `endAt` (bước 7).** ERR-03-126 (410); "Địa chỉ này đã ngừng phục vụ từ {ngày}. Chuyển sang địa chỉ của tỉnh T68." (câu mới, ghi ở mục 8).
- **E4. Route đích trong `routeMap` không tồn tại (bước 2).** ERR-03-025 (409) với thông tin route thiếu; Hà bổ sung ánh xạ rồi tạo lại.

**Quy tắc áp dụng.** BR-03-026, 030.

**Màn hình, API.** UI-03-16; API-03-094, 095, 096.
:::

### 6.31. UC-03-31 · Nhập cấu hình từ gateway cũ

::: dac-ta
**Mục tiêu.** Hỗ trợ chuyển đổi dần (strangler) từ gateway cũ: biến gói xuất cấu hình của hệ cũ thành đề xuất cho PH-02, PH-01 và bảng ánh xạ để chạy song song, không phải khai lại thủ công hàng trăm API; tuyệt đối không nhập khóa API hay thông tin xác thực của hệ cũ.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà); ROLE-TENANT_ADMIN (Lan) cùng có `PERM-03-admin`.

**Tác nhân phụ.** Dịch vụ quét mã độc (DD-12), PH-02 và PH-01 (nhận đề xuất), đầu mối HTTT.

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-03-059.

**Truy vết.** REQ-22; quy trình Chuyển đổi từ hệ cũ (BP-09); LGC-APIM-002…005, 009…015, 019…021; FR-00-090, 093.

**Tiền điều kiện.** Có gói xuất cấu hình hệ cũ (JSON, không quá 50 MiB) hoặc quyền đọc chỉ-đọc qua cầu nối chuyển đổi; tenant `T68` đang ở giai đoạn chuyển đổi.

**Kích hoạt.** Hà tải gói `lgsp-apim-export-2026-11.json` (38 MiB) ở UI-03-18 và bấm "Phân tích".

**Đảm bảo tối thiểu.** Cấu hình gateway đang chạy không đổi; không khóa API hay bí mật nào của hệ cũ được lưu; áp dụng từng phần được phép và có thể áp dụng lại.

**Đảm bảo thành công.** Có bản ghi nhập, báo cáo phân tích và bảng `legacyMap` (API cũ sang route mới, plan cũ sang chính sách mới); danh sách HTTT phải cấp lại thông tin xác thực rõ ràng.

**Luồng chính.**

1. Hà tải gói; hệ thống quét mã độc, kiểm tra định dạng và kích thước (FR-03-059).
2. Hệ thống phân tích gói: API (tên, phiên bản, `context-path`, backend), plan (Keyless, API key, rate limit, quota, whitelist, blacklist), application, subscription.
3. Hệ thống ánh xạ sang mô hình mới: API sang đề xuất API ở PH-02 với mã route đề xuất; plan sang `securityMode`, hạn mức, hạn ngạch, đường dẫn; application sang đề xuất HTTT, consumer ở PH-01.
4. Hệ thống không nhập khóa API hay thông tin xác thực của hệ cũ: mọi HTTT dùng API key được gắn cờ "cấp lại thông tin xác thực OAuth 2.1 hoặc mTLS"; plan Keyless cho API không phải dữ liệu mở được gắn cờ cần quyết định (FR-00-093).
5. Hệ thống lập báo cáo (ví dụ giả lập: 412 API, 530 plan, 118 application, 760 subscription; 96 HTTT cần cấp lại thông tin xác thực; 9 plan Keyless cần quyết định; 14 chính sách tùy biến không ánh xạ được) và cảnh báo xung đột mã; Hà xem và sửa ánh xạ.
6. Hà bấm "Áp dụng"; hệ thống gửi đề xuất tới PH-02 và PH-01 qua API của họ (mỗi đề xuất vào hàng chờ duyệt thường lệ) và lưu `legacyMap` để so sánh khi chạy song song (API-03-093).
7. Khi chạy song song, đội vận hành dùng `legacyMap` đối chiếu lượt gọi hệ cũ và Datahub rồi chuyển dần lưu lượng (BP-09).

**Luồng thay thế.**

- **6a. Chỉ phân tích, không áp dụng.** Dùng để ước lượng khối lượng chuyển đổi và danh sách HTTT phải cấp lại thông tin xác thực (`mappingMode` mặc định `PROPOSE_ONLY`).
- **1a. Đọc qua cầu nối chỉ-đọc.** Hệ thống lấy cấu hình trực tiếp từ gateway cũ thay vì tải tệp; các bước sau như nhau.

**Luồng ngoại lệ.**

- **E1. Gói không đọc được hoặc thiếu trường bắt buộc (bước 1, 2).** ERR-03-020 (422); "Gói cấu hình hệ cũ không đọc được: {lý do}."
- **E2. Tệp chứa mã độc (bước 1).** ERR-03-020 (422) với lý do "tệp bị từ chối bởi bộ quét".
- **E3. PH-02 hoặc PH-01 không nhận đề xuất (bước 6).** Kết quả áp dụng từng phần; báo cáo nêu mục chưa gửi; Hà có thể áp dụng lại.
- **E4. Người dùng không có `PERM-03-admin`.** ERR-03-022 (403); "Bạn không có quyền nhập cấu hình từ gateway cũ."

**Quy tắc áp dụng.** BR-03-014, 029.

**Màn hình, API.** UI-03-18; API-03-091, 092, 093.
:::

## 7. Luồng phụ dùng chung

Năm luồng dưới đây lặp lại ở nhiều use case; use case chỉ nêu mã `LP-03-nn` thay vì lặp từng bước.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-03-01 | Bốn mắt: người đề nghị tạo yêu cầu thay đổi `EN-03-15` ở trạng thái chờ duyệt; hệ thống đưa việc vào hộp "Việc của tôi" của người duyệt (FR-00-070); người duyệt xem giá trị trước và sau rồi duyệt hoặc từ chối kèm ý kiến (từ chối bắt buộc lý do, FR-00-072); hệ thống so người duyệt với người đề nghị theo tài khoản, trùng thì khóa nút "Duyệt" và trả ERR-03-008 (403) nếu gọi thẳng API (FR-00-071) | UC-03-13, 14, 15, 16, 25 |
| LP-03-02 | Lý do bắt buộc và xác nhận lần hai: thao tác ảnh hưởng vận hành có hộp thoại xác nhận (FR-00-050) và ô lý do 10 đến 500 ký tự; thiếu lý do thì giao diện khóa nút, API trả ERR-03-003 (400) | UC-03-09, 11, 12, 21 |
| LP-03-03 | Từ thay đổi tới nút nạp: tổng hợp, kiểm tra hợp lệ, ký (UC-03-19), phát và nút nạp (UC-03-20), mục tiêu 10 giây (giới hạn yêu cầu 60 giây); thất bại ở bước nào thì cấu hình đang chạy không đổi và hệ thống thử lại theo lũy thừa | UC-03-09, 11, 13, 14, 15, 16, 17, 21, 23, 24, 25, 28, 29, 30 |
| LP-03-04 | Truy vết lượt gọi: mọi phản hồi của gateway có `X-Trace-Id`; người vận hành dán `traceId` vào UI-03-09 để thấy kết quả từng chốt, mã `ERR-03-1nn` và liên kết sang vết ở PH-13 (UC-03-26); lỗi có người nhìn trực tiếp luôn nêu `traceId` trong câu thông báo | UC-03-01, 03, 04, 05, 06, 26 |
| LP-03-05 | Đường nhanh và đường bền cho hiệu lực khẩn: lệnh ghi khóa vào Valkey (`T68:revoked:…`, `T68:kill:…`, `T68:ipblock:…`) để mọi nút thấy trong vài giây qua bộ đệm cục bộ 5 giây, đồng thời ghi bản ghi bền ở `ph03_gateway` và (với tạm ngừng khẩn cấp) sinh ảnh chụp mới; Valkey mất thì dựng lại khóa từ bảng bền | UC-03-10, 11, 12 |

: Luồng phụ dùng chung

## 8. Tổng hợp mã mới và đối chiếu

Tập này không tạo mã FR, BR, API, UI, ERR, EVT mới. Mã mới: `UC-03-01…31`, `LP-03-01…05`, câu hỏi mở `Q03-45…49`. Bảng dưới là chiều ngược của mục 5.1: mỗi FR của FRS thuộc những use case nào. Không có FR nào bị bỏ sót; FR-03-034 (mức C, Đợt 3) chỉ là nhánh của UC-03-07; các FR vừa là cơ chế dùng chung vừa có use case riêng (FR-03-025, 050, 052) xuất hiện ở nhiều use case.

| FR | Mức | Use case |
|---|---|---|
| 001 | M | UC-03-01, UC-03-05, UC-03-17 |
| 002 | M | UC-03-02, UC-03-17 |
| 003 | M | UC-03-05, UC-03-12, UC-03-29 |
| 004 | S | UC-03-12 |
| 005 | M | UC-03-05, UC-03-13 |
| 006 | M | UC-03-13 |
| 007 | M | UC-03-14 |
| 008 | S | UC-03-15 |
| 009 | M | UC-03-05 |
| 010 | S | UC-03-05 |
| 011 | M | UC-03-05, UC-03-29 |
| 012 | M | UC-03-01, UC-03-03 |
| 013 | M | UC-03-01, UC-03-03 |
| 014 | M | UC-03-02 |
| 015 | M | UC-03-01, UC-03-02 |
| 016 | M | UC-03-01 |
| 017 | M | UC-03-01 |
| 018 | M | UC-03-10 |
| 019 | M | UC-03-01 |
| 020 | M | UC-03-01 |
| 021 | M | UC-03-01, UC-03-04 |
| 022 | M | UC-03-04 |
| 023 | M | UC-03-25 |
| 024 | S | UC-03-25 |
| 025 | M | UC-03-01, UC-03-04, UC-03-08 |
| 026 | M | UC-03-08 |
| 027 | S | UC-03-06 |
| 028 | M | UC-03-01 |
| 029 | M | UC-03-01, UC-03-06 |
| 030 | M | UC-03-06 |
| 031 | M | UC-03-06 |
| 032 | M | UC-03-01 |
| 033 | M | UC-03-07 |
| 034 | C | UC-03-07 |
| 035 | S | UC-03-09 |
| 036 | M | UC-03-09 |
| 037 | S | UC-03-30 |
| 038 | M | UC-03-16 |
| 039 | M | UC-03-19 |
| 040 | M | UC-03-19 |
| 041 | M | UC-03-19 |
| 042 | M | UC-03-20 |
| 043 | M | UC-03-20 |
| 044 | M | UC-03-21 |
| 045 | M | UC-03-22 |
| 046 | M | UC-03-23 |
| 047 | M | UC-03-11 |
| 048 | M | UC-03-24 |
| 049 | M | UC-03-17 |
| 050 | M | UC-03-01, UC-03-03, UC-03-26 |
| 051 | M | UC-03-26 |
| 052 | M | UC-03-01, UC-03-27 |
| 053 | S | UC-03-28 |
| 054 | M | UC-03-18 |
| 055 | M | UC-03-27 |
| 056 | M | UC-03-29 |
| 057 | S | UC-03-24 |
| 058 | S | UC-03-27 |
| 059 | S | UC-03-31 |

: Độ phủ FR của các use case (số FR là phần sau `FR-03-`)

Một số câu thông báo ở luồng ngoại lệ chưa có trong FRS §9.2 (do nêu rõ tên đối tượng hoặc là lỗi quyền chung). Các câu này được viết mới để dùng ngay trong use case và đề nghị đưa vào D03-06-PH03 §5.2 ở đợt đồng bộ.

| Use case | Mã lỗi | Câu mới |
|---|---|---|
| UC-03-11 E4 | ERR-03-022 | "Bạn không có quyền tạm ngừng khẩn cấp." |
| UC-03-15 E2 | ERR-03-009 | "Luật vá ảo cần có căn cứ (mã CVE hoặc số cảnh báo) và thời hạn không quá 90 ngày." |
| UC-03-17 E3 | ERR-03-019 | "Chứng thư đã ở trạng thái đang gia hạn." |
| UC-03-18 E3 | ERR-03-022 | "Bạn không có quyền xác nhận cảnh báo." |
| UC-03-21 E3 | ERR-03-022 | "Bạn không có quyền quay lui cấu hình toàn nền tảng." |
| UC-03-22 E2, E3 | ERR-03-001, ERR-03-022 | "Không tìm thấy nút {nodeId}." và "Bạn không có quyền xem trạng thái nút gateway." |
| UC-03-24 E3, E5 | ERR-03-019, ERR-03-001 | "Mẫu {mã} đang được {n} route dùng." và "Không tìm thấy ảnh chụp cấu hình phiên bản {v}." |
| UC-03-30 E3 | ERR-03-126 | "Địa chỉ này đã ngừng phục vụ từ {ngày}. Chuyển sang địa chỉ của tỉnh {đích}." |
| UC-03-31 E4 | ERR-03-022 | "Bạn không có quyền nhập cấu hình từ gateway cũ." |

: Câu thông báo mới đề nghị đưa vào D03-06-PH03

## 9. Câu hỏi mở

> **Câu hỏi mở Q03-45:** UC-03-06 (E7) giữ nguyên hành vi `503` nhanh khi mọi backend không khỏe (BR-03-011, Q03-03 của FRS). Với dịch vụ công thiết yếu có đúng một backend, có cho phép cấu hình ngoại lệ "giữ lưu lượng vào backend dù lỗi cao" có hai người duyệt (UC-03-16 kiểu bốn mắt) hay không. Đề xuất: không có ngoại lệ ở MVP; chủ dịch vụ bổ sung backend dự phòng hoặc dùng `ESSENTIAL` để được ưu tiên. Cần ý kiến vận hành tỉnh.

> **Câu hỏi mở Q03-46:** UC-03-11 cho tạm ngừng khẩn cấp có hiệu lực ngay, không cần người duyệt (FRS §3.3), kể cả khi người thực hiện là TO. Một thao tác nhầm có thể chặn HTTT thiết yếu. Đề xuất: giữ nguyên hiệu lực ngay nhưng thông báo tức thì cho SO và TA, và nhắc xem xét lại sau 4 giờ nếu chưa mở lại. Cần ý kiến đơn vị thẩm định ATTT.

> **Câu hỏi mở Q03-47:** LP-03-01 so người duyệt với người đề nghị theo tài khoản, không theo vai trò. Ở tenant nhỏ (`QM-NHO`) chỉ có một TA và một SO: đề nghị do TA lập (UC-03-16, 25) thì SO duyệt, đề nghị do SO lập (UC-03-13, 15) thì TA duyệt, nên vẫn đủ hai người; nhưng nếu một người đồng thời giữ cả hai vai trò thì không còn bốn mắt. Cần xác nhận hệ thống chặn gán đồng thời `ROLE-TENANT_ADMIN` và `ROLE-SECURITY_OFFICER` cho một tài khoản ở PH-12, hay chấp nhận "duyệt thay" bởi PA (liên quan Q03-02 của FRS).

> **Câu hỏi mở Q03-48:** UC-03-26 hiển thị địa chỉ nguồn (`srcIp`) của lượt gọi cho người có `PERM-03-log-read`. Với lượt gọi từ giao diện, địa chỉ nguồn có thể là địa chỉ của cán bộ cá nhân nên có thể là dữ liệu cá nhân theo Luật BVDLCN 91/2025. Cần xác nhận thời hạn lưu 12 tháng của nhật ký lượt gọi có áp dụng cho trường này, và có cần che bớt octet cuối với vai trò AU hay không.

> **Câu hỏi mở Q03-49:** UC-03-31 giả định gateway cũ xuất được gói cấu hình JSON gồm API, plan, application, subscription. Chưa có tệp mẫu thật từ hệ cũ, nên bộ phân tích dựa trên mô tả ở `docs/` và SRS cũ. Cần lấy một gói xuất thật từ tỉnh thí điểm (đã ẩn khóa) để xác nhận định dạng và đo khối lượng thực trước khi thiết kế UI-03-18 chi tiết.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu dùng chung; các việc dưới đây để đợt đồng bộ cuối thực hiện.

| Tài liệu | Đề nghị |
|---|---|
| D03-06-PH03 | Đã thực hiện ở bản 0.1 của tập màn hình (bảng thông báo §5.2 và truy vết UI → FR); đợt rà soát chéo đã đối chiếu UI với UC qua FR, không phát hiện UI nào thiếu use case |
| D03-04-PH03 | Không bổ sung cột use case vào bảng API (theo mẫu PH-05, truy vết API → UC đi qua FR ở §5.2 của tập này); lỗi giữa hai dịch vụ (ERR-03-022 ở UC-03-10, 23) không cần câu hiển thị cho người dùng |
| D05-02-PH03 | Đã thực hiện ở bản 0.1 của tập test case (ma trận UC → TC ở §8.6 sinh tự động, đủ 31 UC) |
| D00-04 §3.2 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi hợp nhất tập này: UC-03 (31) |

: Đề nghị đồng bộ của tập use case PH-03

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và quy chuẩn K-TRINH-BAY: 31 use case (27 M, 4 S) mỗi use case một khối 15 mục, phủ đủ 59 FR của D02-03-PH03; 4 sơ đồ use case tổng; ba bảng truy vết (FR, màn hình và API, REQ, quy trình và hệ cũ); 5 luồng phụ dùng chung LP-03-01…05; bảng độ phủ FR; 5 câu hỏi mở Q03-45…49 |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Chốt câu hỏi mở đợt đồng bộ: Q394, Q398, Q414, Q416, Q429 (danh mục mười một mẫu chính sách) |

