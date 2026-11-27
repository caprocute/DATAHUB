---
ma_tai_lieu: D02-06
ten: Sơ đồ luồng dữ liệu (DFD) và phân loại dữ liệu của Datahub
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kiến trúc sư, kỹ sư phát triển, cán bộ ATTT, chủ quản dữ liệu
mo_ta: Sơ đồ luồng dữ liệu mức 0, mức 1 theo sáu miền và mức 2 cho tám luồng trọng yếu, kèm năm nhóm phân loại dữ liệu được đánh dấu trên từng luồng và từng kho lưu trữ.
tai_lieu_lien_quan: D02-02 SRS; D02-07 Từ điển dữ liệu; D03-01 SAD; D03-07 Thiết kế ATTT; D03-03 CSDL 20 phân hệ; D02-03-PH09 Quyền riêng tư
---

# D02-06 · Sơ đồ luồng dữ liệu và phân loại dữ liệu

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu cho hội đồng và đội thiết kế cùng một bức tranh: dữ liệu nào đi vào Datahub, đi qua những tiến trình nào, được lưu ở kho nào, đi ra cho ai, và mỗi chặng mang loại dữ liệu gì. Từ bức tranh đó mới chứng minh được rằng mỗi luồng có dữ liệu cá nhân hay dữ liệu tài chính đều có biện pháp bảo vệ tương xứng, đúng yêu cầu phân loại của Luật Dữ liệu 60/2024, Luật Bảo vệ dữ liệu cá nhân 91/2025 và hồ sơ cấp độ 3 theo Nghị định 331/2026.

**Phạm vi.** DFD mức 0 (ngữ cảnh) với chín giao diện ngoài IF-01…IF-09; DFD mức 1 tổng thể và cho sáu miền (kết nối và API, tích hợp và sự kiện, dữ liệu dùng chung, nền tảng và vận hành, thanh toán, trợ lý AI); DFD mức 2 cho tám luồng trọng yếu theo dàn ý (tra cứu đồng bộ, tra cứu CSDL quốc gia, phát và nhận sự kiện, đồng bộ danh mục, thanh toán và đối soát, xử lý bản tin lỗi, kết nạp, di trú từ hệ cũ). Phân loại dữ liệu theo năm nhóm (công khai, nội bộ, dữ liệu cá nhân cơ bản, dữ liệu cá nhân nhạy cảm, dữ liệu tài chính), đánh dấu trên 19 kho và mọi luồng của các sơ đồ.

**Căn cứ.** Luật Dữ liệu 60/2024/QH15 (phân loại dữ liệu, CMP-LAW-01); Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025/NĐ-CP (dữ liệu cá nhân cơ bản, nhạy cảm); Nghị định 331/2026/NĐ-CP (ngưỡng chủ thể dữ liệu cá nhân của cấp độ 3); Nghị định 278/2025/NĐ-CP (kết nối, chia sẻ qua nền tảng quốc gia); TCVN 14423:2026 nhóm yêu cầu bảo vệ dữ liệu. Tài liệu kế thừa bốn mức bảo vệ của D03-01 §8.2 và D03-07 §3.2, không định nghĩa lại.

**Những điểm hội đồng cần lưu ý.**

1. **Hai trục, không mâu thuẫn.** Dàn ý yêu cầu năm nhóm theo nội dung; SAD và thiết kế ATTT dùng bốn mức bảo vệ (Công khai, Nội bộ, Hạn chế, Nhạy cảm). Tài liệu giữ cả hai: nhóm nói dữ liệu *là gì* (để áp luật), mức nói phải *bảo vệ thế nào* (để kỹ sư cài đặt). Bảng 2.1 quy đổi một chiều từ nhóm sang mức tối thiểu.
2. **Datahub chủ yếu là đường ống.** Phần lớn dữ liệu cá nhân chỉ **đi qua** (tra cứu, sự kiện) và không được lưu, trừ hàng đợi lỗi có mã hóa, giữ tối đa 7 ngày. Dữ liệu cá nhân nhạy cảm **lưu lại** ở dạng giải mã được chỉ có ở năm phân hệ: dữ liệu chủ PH-06, quy trình PH-11, bằng chứng tra cứu quốc gia PH-14, hàng đợi lỗi PH-18 (tối đa 7 ngày) và thanh toán PH-19; nhật ký kiểm toán PH-13 chỉ giữ dạng băm.
3. **Không có luồng dữ liệu cá nhân nhạy cảm nào tới trợ lý AI** và không có dữ liệu nào ra khỏi lãnh thổ; hai điều này được kiểm bằng chính sách OPA và quy tắc egress, không chỉ bằng quy định.
4. Một số chi tiết của Nghị định 356/2025 (mẫu hồ sơ, miễn trừ cho cơ quan nhà nước) chưa đối chiếu toàn văn; tài liệu ghi thành câu hỏi mở thay vì giả định.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Giao diện ngoài trên DFD mức 0 | 9 (IF-01…IF-09) |
| Sơ đồ DFD | 1 mức 0, 7 mức 1 (tổng thể và sáu miền), 8 mức 2 |
| Kho dữ liệu được phân loại | 19 (DS-01…DS-19) |
| Nhóm phân loại theo nội dung / mức bảo vệ | 5 / 4 |
| Kho chứa dữ liệu cá nhân nhạy cảm dạng có thể giải mã | 7 (DS-03, DS-04, DS-06, DS-09, DS-11, DS-18, DS-19) |

: Con số chính của DFD và phân loại dữ liệu

## Giới thiệu tài liệu

### Mục đích

Tài liệu mô tả đường đi của dữ liệu ở ba mức chi tiết và gán nhóm phân loại cho từng luồng và từng kho, để làm căn cứ cho thiết kế ATTT (D03-07), hồ sơ cấp độ (D03-08), đánh giá tác động xử lý dữ liệu cá nhân của PH-09 và kiểm thử bảo mật.

### Phạm vi

Gồm dữ liệu nghiệp vụ và dữ liệu vận hành có thể chứa thông tin của người hoặc tổ chức. Không vẽ luồng thuần kỹ thuật không mang dữ liệu nghiệp vụ (nhịp tim, đồng bộ cấu hình Argo CD, sao chép bản sao PostgreSQL), trừ khi luồng đó là nơi dữ liệu nghiệp vụ được nhân bản (sao lưu, DR).

### Người đọc

Mỗi nhóm người đọc dùng một phần khác nhau của tài liệu.

| Người đọc | Đọc | Để làm gì |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, 3 | Thấy phạm vi dữ liệu và căn cứ phân loại |
| Cán bộ ATTT, chủ quản dữ liệu | Chương 2, 5, 6 | Kiểm tra biện pháp theo nhóm dữ liệu; lập DPIA |
| Kiến trúc sư, kỹ sư | Chương 4, 6, 8 | Biết dữ liệu nào đi đâu, gắn nhãn phân loại khi thiết kế |
| Kiểm thử viên bảo mật | Chương 6, 8 | Lấy điểm kiểm soát làm ca kiểm thử |

: Người đọc và phần cần đọc của D02-06

### Thuật ngữ và chữ viết tắt

Thuật ngữ riêng của tài liệu; thuật ngữ chung ở D00-01.

| Thuật ngữ | Nghĩa |
|---|---|
| DFD | Sơ đồ luồng dữ liệu (Data Flow Diagram): thực thể ngoài, tiến trình, kho dữ liệu và luồng |
| Thực thể ngoài | Người hoặc hệ thống ngoài ranh giới Datahub, gửi hoặc nhận dữ liệu |
| Tiến trình | Một chức năng biến đổi dữ liệu; đánh số `n.0` ở mức 1, `n.m` ở mức 2 |
| Kho dữ liệu | Nơi dữ liệu nằm lại sau khi tiến trình kết thúc; mã `DS-nn` |
| Luồng | Dữ liệu di chuyển giữa hai phần tử; mã `DF-nn` ở mức 0, ghi nhãn nhóm trên mũi tên |
| Dữ liệu đi qua | Nội dung bản tin giữa hai HTTT; mặc định không lưu (D03-01 §8.3) |
| Dữ liệu lưu lại | Dữ liệu Datahub làm chủ: danh mục, dữ liệu chủ, giao dịch, cấu hình |
| DLCN | Dữ liệu cá nhân |
| Mức hợp đồng | Mức phân loại của một API, topic hoặc luồng, bằng mức cao nhất của các trường trong lược đồ (D03-07 §3.2) |

: Thuật ngữ dùng trong DFD và phân loại dữ liệu

### Tài liệu tham chiếu

Sơ đồ và phân loại dựa trên các tài liệu sau; khi lệch, tài liệu gốc đúng và điểm lệch được ghi vào đề nghị đồng bộ.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D02-02 | SRS | Giao diện ngoài IF-01…IF-09 |
| D02-07 | Từ điển dữ liệu | DD-08 mức phân loại, DD-09 phân loại trường |
| D03-01 | SAD | Đơn vị triển khai, cụm CSDL, bốn mức bảo vệ, dữ liệu đi qua và lưu lại |
| D03-07 | Thiết kế ATTT | Tài sản AS-01…AS-20, vùng Z0…Z7, quy tắc xử lý theo mức, SEC-30…39 |
| D03-03-PH01…PH20 | CSDL phân hệ | Schema, bucket, khóa mã hóa |
| D02-03-PH09 | FRS Quyền riêng tư | Enum `DataClass`, `PersonalDataType`, `PersonalDataCategory` |
| ADR-032, 041, 047, 048, 053, 057, 073, 170…174, 181, 182, 183 | Quyết định kiến trúc | Mã hóa trường, lũy đẳng, phân vùng, mã hóa thanh toán, ảnh chụp danh mục, đồng bộ quốc gia, cầu nối Pulsar, trợ lý AI, DLQ, phát lại, di trú |

: Tài liệu tham chiếu của D02-06

### Cấu trúc tài liệu

Chương 1 nêu ký hiệu; chương 2 định nghĩa phân loại; chương 3 đến 6 đi từ tổng quát tới chi tiết; chương 7, 8 tổng hợp ma trận và cách kiểm chứng.

| Chương | Nội dung |
|---|---|
| 1 | Ký hiệu và quy ước |
| 2 | Phân loại dữ liệu: năm nhóm, bốn mức, quy tắc gán |
| 3 | DFD mức 0, ngữ cảnh |
| 4 | DFD mức 1: tổng thể và sáu miền |
| 5 | Danh mục kho dữ liệu và phân loại |
| 6 | DFD mức 2 cho tám luồng trọng yếu |
| 7 | Ma trận nhóm dữ liệu theo phân hệ và vùng mạng |
| 8 | Thực thi và kiểm chứng phân loại |
| 9 | Giả định, câu hỏi mở, đề nghị đồng bộ |

: Cấu trúc chương của D02-06

## 1. Ký hiệu và quy ước

Sơ đồ dùng ký hiệu Yourdon–DeMarco giản lược, vẽ bằng Mermaid để sinh lại được cùng tài liệu. Mỗi sơ đồ có ranh giới Datahub là một khung; mọi thứ ngoài khung là thực thể ngoài.

| Phần tử | Hình | Mã | Ví dụ |
|---|---|---|---|
| Thực thể ngoài | Hình chữ nhật | Theo giao diện SRS `IF-nn`, hoặc tên tác nhân | `IF-03` NDXP |
| Tiến trình | Hình viên thuốc | `n.0` mức 1, `n.m` mức 2 | `2.0` Tích hợp và sự kiện |
| Kho dữ liệu | Hình trụ | `DS-nn` (chương 5) | `DS-06` pg-payment |
| Luồng | Mũi tên có nhãn | Nhãn ghi dữ liệu và nhóm, ví dụ "Kết quả tra cứu · CN2" | |
| Ranh giới | Khung | Datahub, hoặc vùng mạng `Z0…Z7` khi cần | |

: Ký hiệu dùng trong các sơ đồ luồng dữ liệu

Nhãn nhóm trên luồng viết tắt theo chương 2: **CK** công khai, **NB** nội bộ, **CN1** DLCN cơ bản, **CN2** DLCN nhạy cảm, **TC** tài chính. Một luồng mang nhiều nhóm thì ghi nhóm cao nhất trước. Luồng mà nhóm phụ thuộc hợp đồng (ví dụ lượt gọi API giữa hai HTTT) ghi "theo hợp đồng", nghĩa là mức của API hoặc topic do PH-09 xác nhận.

## 2. Phân loại dữ liệu

Chương này định nghĩa năm nhóm dữ liệu theo nội dung, quy đổi sang bốn mức bảo vệ đã có, nêu cách gán nhóm cho dữ liệu đi qua và dữ liệu lưu lại, và các quy tắc xử lý riêng của từng nhóm bổ sung cho D03-07 §3.2.

### 2.1. Năm nhóm và quy đổi sang mức bảo vệ

Mỗi nhóm có một mức bảo vệ tối thiểu. Chủ quản dữ liệu được nâng mức (ví dụ dữ liệu nội bộ về cấu hình an ninh lên Hạn chế) nhưng không được hạ dưới mức tối thiểu.

| Nhóm | Mã | Định nghĩa | Ví dụ trong Datahub | Mức tối thiểu (`DataClass`) | `PersonalDataType` |
|---|---|---|---|---|---|
| Công khai | CK | Dữ liệu được công bố hoặc được phép công bố rộng rãi | Tên, mã danh mục dùng chung; mô tả API công khai; tài liệu cổng nhà phát triển; dữ liệu mở công bố lên NDOP | Công khai (`PUBLIC`) | `NONE` |
| Nội bộ | NB | Dữ liệu vận hành, cấu hình, số liệu tổng hợp không gắn với cá nhân | Cấu hình luồng, route, gói sử dụng; số liệu lưu lượng; chỉ tiêu KPI; nhật ký vận hành đã che | Nội bộ (`INTERNAL`) | `NONE` |
| DLCN cơ bản | CN1 | Thông tin gắn với một người cụ thể hoặc giúp xác định một người, thuộc loại cơ bản theo Luật 91/2025 | Họ tên, ngày sinh, giới tính, số định danh, số điện thoại, thư điện tử, địa chỉ của công dân và của cán bộ đầu mối; mã số thuế cá nhân; số sổ BHXH | Hạn chế (`RESTRICTED`); riêng số định danh và số sổ BHXH khi đi cùng dữ liệu nhân thân: Nhạy cảm | `BASIC` |
| DLCN nhạy cảm | CN2 | DLCN thuộc danh mục nhạy cảm của Luật 91/2025, NĐ 356/2025 | Sức khỏe, sinh trắc, di truyền, tiền án (lý lịch tư pháp), dân tộc, tôn giáo, quan điểm chính trị, vị trí theo dõi, dữ liệu trẻ em, thông tin tài khoản ngân hàng của cá nhân | Nhạy cảm (`SENSITIVE`) | `SENSITIVE` |
| Tài chính | TC | Dữ liệu về khoản thu, giao dịch, đối soát, hoàn tiền và tài khoản thụ hưởng | Giao dịch thanh toán, số tiền, mã tham chiếu nhà cung cấp, tệp đối soát, biên bản chênh lệch, cấu hình kênh thu | Hạn chế (`RESTRICTED`); phần gắn người nộp hoặc tài khoản cá nhân: Nhạy cảm | `NONE`, hoặc `SENSITIVE` khi có `FINANCIAL_ACCOUNT` |

: Năm nhóm dữ liệu theo nội dung và mức bảo vệ tối thiểu tương ứng

Ba điểm cần giải thích. Thứ nhất, nhóm TC chồng một phần lên CN2: thông tin tài khoản ngân hàng của cá nhân vừa là dữ liệu tài chính vừa là DLCN nhạy cảm (`FINANCIAL_ACCOUNT` trong Phụ lục A của FRS PH-09); khi chồng, áp cả hai bộ quy tắc. Thứ hai, số định danh cá nhân về pháp lý là DLCN cơ bản, nhưng thiết kế ATTT xếp vào mức Nhạy cảm (D03-01 §8.2) vì nó là khóa liên kết mọi CSDL quốc gia; tài liệu này giữ quyết định đó. Thứ ba, dữ liệu thuộc danh mục bí mật nhà nước không phải là nhóm thứ sáu mà là **nhãn chặn** `STATE_SECRET`: Datahub từ chối công bố API hay topic mang nhãn này (FR-02-007, FR-09-007), nên không có luồng nào trên sơ đồ được phép mang nó.

Ngoài năm nhóm nghiệp vụ, vật liệu khóa và bí mật (khóa ký, khóa mã hóa, mật khẩu kết nối, thông tin xác thực của HTTT) mang nhãn kỹ thuật **BM** ("tối mật kỹ thuật" ở D03-07 §3.1). Nhãn BM chỉ xuất hiện ở bốn nơi: OpenBao (DS-14); gói bàn giao thông tin xác thực một lần của luồng kết nạp ở kho đối tượng (DS-11, mục 6.7); luồng DF-02 khi nhà phát triển tự lấy khóa ứng dụng ở cổng PH-15; và nguồn hệ cũ ở chặng 6.8-a trước khi bị loại. Băm mật khẩu và bí mật TOTP trong Keycloak (DS-07) xếp mức Hạn chế theo AS-10, không mang nhãn BM.

### 2.2. Căn cứ pháp lý của từng nhóm

Mỗi nhóm kéo theo nghĩa vụ pháp lý khác nhau; bảng dưới gắn nghĩa vụ với phân hệ chịu trách nhiệm thực hiện.

| Nhóm | Căn cứ chính | Nghĩa vụ chính phát sinh | Phân hệ thực hiện |
|---|---|---|---|
| CK | Luật Dữ liệu 60/2024 (dữ liệu mở); NĐ 278/2025 (chia sẻ qua nền tảng quốc gia) | Công bố đúng nguồn, đúng phiên bản; giữ toàn vẹn | PH-07, PH-14 (NDOP), PH-15 |
| NB | Luật Dữ liệu 60/2024; TCVN 14423:2026 | Kiểm soát truy cập theo vai trò; giữ toàn vẹn cấu hình | Mọi phân hệ |
| CN1 | Luật 91/2025; NĐ 356/2025 | Cơ sở pháp lý cho mỗi hoạt động xử lý; quyền của chủ thể (biết, truy cập, chỉnh sửa, xóa); thông báo vi phạm trong 72 giờ | PH-09 sổ xử lý, yêu cầu chủ thể |
| CN2 | Luật 91/2025; NĐ 356/2025; NĐ 331/2026 (≥ 10.000 chủ thể nhạy cảm thì tối thiểu cấp độ 3) | Như CN1, cộng đánh giá tác động (DPIA) gửi Cục A05; mã hóa; hạn chế người xem | PH-09 DPIA, chấp thuận mục đích; PH-06, PH-14 |
| TC | Luật Kế toán, quy định thu nộp ngân sách qua dịch vụ công trực tuyến (căn cứ cụ thể theo BRD PH-19); TCVN 14423:2026 | Đúng tới từng đồng; lưu chứng từ; không sửa lịch sử; đối soát hằng ngày | PH-19 |

: Căn cứ pháp lý và nghĩa vụ theo nhóm dữ liệu

### 2.3. Quy tắc gán nhóm

Datahub gán nhóm theo hai cách khác nhau cho hai loại dữ liệu đã phân biệt ở D03-01 §8.3.

**Dữ liệu lưu lại** được gán ở mức trường. Mỗi cột của bảng nghiệp vụ có nhãn `@Classified(level=…)` trên thực thể Java và dòng tương ứng ở `ph09_privacy.field_classification` (DD-09); cột CN2 được mã hóa trường theo ADR-032. Bảng hoặc tệp có nhiều nhóm thì kho chứa nó mang nhóm cao nhất ở các khâu không tách được trường (sao lưu, sao chép DR).

**Dữ liệu đi qua** không được Datahub đọc hiểu theo trường. Mỗi API (PH-02), topic (PH-10) và luồng tích hợp (PH-04) mang **mức hợp đồng** bằng mức cao nhất của các trường trong lược đồ đã đăng ký, có thuộc tính `x-dh-classification` trong OpenAPI hoặc JSON Schema. Chủ dịch vụ khai mức khi đăng ký, PH-09 quét gợi ý và cán bộ ATTT xác nhận (FR-09-006). Mức hợp đồng quyết định cách xác thực bên khai thác, cách ghi DLQ và việc có cần chấp thuận mục đích hay không.

```{.mermaid caption="Quy trình gán nhóm và mức cho trường dữ liệu và cho hợp đồng"}
flowchart TB
  A["Trường mới trong thực thể<br/>hoặc lược đồ API, topic"] --> B{"Là dữ liệu của người<br/>hoặc giúp xác định người?"}
  B -->|Có| C{"Thuộc danh mục<br/>nhạy cảm NĐ 356?"}
  C -->|Có| CN2["CN2 · Nhạy cảm"]
  C -->|Không| CN1["CN1 · Hạn chế<br/>số định danh: Nhạy cảm"]
  B -->|Không| D{"Là giao dịch, số tiền,<br/>tài khoản thụ hưởng?"}
  D -->|Có| TC["TC · Hạn chế"]
  D -->|Không| E{"Được phép công bố?"}
  E -->|Có| CK["CK · Công khai"]
  E -->|Không| NB["NB · Nội bộ"]
  CN2 & CN1 & TC & CK & NB --> F["PH-09: PROPOSED → CONFIRMED<br/>cán bộ ATTT xác nhận"]
  F --> G["Mức hợp đồng = mức cao nhất<br/>của các trường"]
```

Hình cho thấy câu hỏi đầu tiên luôn là "có phải dữ liệu của người không", vì nhóm CN1, CN2 kéo theo nghĩa vụ pháp lý nặng nhất. Mọi nhãn đều đi qua trạng thái `PROPOSED` rồi mới `CONFIRMED` (FR-09-004), nên một trường mới chưa được xác nhận được xử lý như mức Hạn chế cho tới khi có kết luận (quy tắc an toàn mặc định, đề xuất bổ sung ở Q375).

PH-09 chủ yếu thuộc Đợt 2. Trong MVP chưa có PH-09, nhãn được khai báo ngay trong mã và lược đồ (`@Classified` ở thực thể, `x-dh-classification` ở OpenAPI và lược đồ sự kiện, theo DD-09), đúng cách D03-07 §3.2 gắn nhãn ở mức trường; thư viện log dùng chung đọc `@Classified` để che (SEC-32). Khi bật PH-09, các khai báo này được nhập một lần thành phần tử dữ liệu ở trạng thái `CONFIRMED` (FR-09-003).

### 2.4. Quy tắc xử lý bổ sung theo nhóm

Bảng quy tắc theo bốn mức của D03-07 §3.2 (lưu trữ, truyền, log, kiểm toán, hiển thị, xuất tệp, bộ nhớ đệm, môi trường thử, gửi AI, thư, sao lưu, thời hạn) áp dụng nguyên vẹn. Bảng dưới chỉ ghi những quy tắc **thêm** mà nhóm nội dung đòi hỏi, không lặp lại bảng đó.

| Nhóm | Quy tắc thêm | Nơi thực thi |
|---|---|---|
| CK | Dữ liệu công bố phải có nguồn và phiên bản; ảnh chụp danh mục có tổng kiểm tra SHA-256 | PH-07 (ADR-053), PH-14 NDOP |
| NB | Cấu hình an ninh (chính sách OPA, cấu hình WAF, danh sách IP) nâng lên Hạn chế | PH-03, PH-12 |
| CN1 | Mỗi hoạt động xử lý có dòng trong sổ xử lý PH-09 (mục đích, cơ sở pháp lý, thời hạn); yêu cầu của chủ thể được trả lời đúng hạn | PH-09 |
| CN2 | DPIA trước khi kích hoạt hợp đồng; chấp thuận mục đích của chủ quản dữ liệu; khóa mã hóa riêng cho tenant; không đệm ở PH-14 (FR-14-035); không tới PH-17; DLQ mã hóa, ≤ 7 ngày | PH-09, PH-14, PH-17, PH-18, OPA |
| TC | Lịch sử trạng thái giao dịch chỉ thêm, không sửa (ADR-043); tệp đối soát gốc lưu kèm SHA-256 làm chứng cứ; số tiền kiểu `T-MONEY` không làm tròn; Datahub không nhận số thẻ (người nộp nhập trên trang nhà cung cấp); nhật ký tích hợp quá 12 tháng chuyển kho lưu trữ (ADR-047) | PH-19 |
| Mọi nhóm | Không chuyển dữ liệu ra ngoài lãnh thổ Việt Nam; egress chỉ tới đích trong danh sách | Egress gateway Z4, SEC-1x |

: Quy tắc xử lý bổ sung theo nhóm dữ liệu

## 3. DFD mức 0, ngữ cảnh

Sơ đồ ngữ cảnh coi Datahub là một tiến trình duy nhất và chỉ vẽ dữ liệu trao đổi với chín giao diện ngoài của SRS cùng hai nhóm người dùng. Mỗi luồng mang nhãn nhóm dữ liệu cao nhất có thể đi trên nó.

```{.mermaid caption="DFD mức 0: Datahub và các thực thể ngoài, có nhãn nhóm dữ liệu trên luồng"}
flowchart TB
  U1["Người dùng nội bộ<br/>cán bộ, quản trị, kỹ sư"]
  U2["Nhà phát triển,<br/>nhà thầu HTTT"]
  IF01["IF-01 HTTT của tỉnh"]
  IF02["IF-02 Hệ thống cũ<br/>CSDL, FTP, SOAP"]
  IF03["IF-03 NDXP và<br/>CSDL quốc gia"]
  IF04["IF-04 Danh mục<br/>dùng chung quốc gia"]
  IF05["IF-05 PayGov và<br/>kênh thanh toán"]
  IF06["IF-06 VNeID"]
  IF07["IF-07 LGSP cũ"]
  IF08["IF-08 Giám sát ATTT"]
  IF09["IF-09 Thư, SMS"]
  DH(["0 · Datahub"])
  U1 <-->|"DF-01 thao tác, kết quả · CN2"| DH
  U2 <-->|"DF-02 tài liệu, khóa ứng dụng · CK, BM"| DH
  IF01 <-->|"DF-03 lượt gọi API, sự kiện · theo hợp đồng"| DH
  DH <-->|"DF-04 dữ liệu nguồn · theo hợp đồng"| IF02
  DH <-->|"DF-05 tra cứu quốc gia · CN2"| IF03
  IF04 -->|"DF-06 danh mục quốc gia · CK"| DH
  DH <-->|"DF-07 giao dịch, IPN, đối soát · TC"| IF05
  IF06 -->|"DF-08 định danh công dân · CN1"| DH
  IF07 -->|"DF-09 dữ liệu di trú · CN1, TC"| DH
  DH -->|"DF-10 nhật ký an ninh · NB"| IF08
  DH -->|"DF-11 liên kết thông báo · NB"| IF09
```

Người đọc cần thấy ba điều ở hình. Thứ nhất, chỉ năm luồng (DF-01, DF-05, DF-07, DF-08, DF-09) chắc chắn mang dữ liệu cá nhân hoặc tài chính do Datahub chủ động xử lý; hai luồng DF-03, DF-04 mang dữ liệu "theo hợp đồng", tức Datahub chỉ chuyển tiếp và áp biện pháp theo mức của hợp đồng. Thứ hai, luồng ra IF-08 và IF-09 chỉ mang dữ liệu nội bộ: nhật ký an ninh đã che và thư chỉ chứa liên kết (FR-00-062). Thứ ba, DF-02 là luồng duy nhất ra ngoài mang nhãn BM, vì nhà phát triển tự lấy thông tin xác thực của ứng dụng ở cổng PH-15; chặng này có bảo vệ riêng ở mục 6.7.

| Mã | Từ → đến | Dữ liệu | Nhóm cao nhất | Kênh, bảo vệ |
|---|---|---|---|---|
| DF-01 | Người dùng ↔ Datahub | Thao tác quản trị, xem dữ liệu chủ, tra cứu giao dịch | CN2 | HTTPS qua WAF, OIDC, MFA cho vai trò quản trị; che mặc định trường Nhạy cảm |
| DF-02 | Nhà phát triển ↔ Datahub | Tài liệu API, sandbox, thông tin xác thực ứng dụng | CK, BM | HTTPS, OIDC; bí mật hiện một lần |
| DF-03 | HTTT ↔ Datahub | Lượt gọi API, sự kiện, webhook | Theo hợp đồng | OAuth 2.1 hoặc mTLS (SEC-24) theo mức hợp đồng |
| DF-04 | Hệ thống cũ ↔ Datahub | Bản ghi CSDL, tệp, bản tin SOAP | Theo hợp đồng | Bộ điều hợp PH-05, tài khoản chỉ đọc, kiểm toán truy cập CSDL (ADR-067) |
| DF-05 | NDXP ↔ Datahub | Yêu cầu và kết quả tra cứu dân cư, tư pháp, BHXH, ĐKKD | CN2 | Token NDXP, ký số bản tin, kiểm tra mục đích (FR-14-011) |
| DF-06 | Danh mục quốc gia → Datahub | Cấu trúc và dữ liệu danh mục | CK | REST qua PH-14, đồng bộ theo lịch (ADR-057) |
| DF-07 | PayGov ↔ Datahub | Yêu cầu thanh toán, IPN, tệp đối soát, hoàn tiền | TC | Ký HMAC hoặc chữ ký nhà cung cấp, mTLS, lũy đẳng |
| DF-08 | VNeID → Datahub | Định danh liên kết của người dùng khi bật | CN1 | OIDC |
| DF-09 | LGSP cũ → Datahub | Danh mục, HTTT, API, giao dịch lịch sử | CN1, TC | JDBC chỉ đọc, cầu nối Pulsar; loại bỏ thông tin xác thực cũ |
| DF-10 | Datahub → giám sát ATTT | Sự kiện an ninh | NB | Syslog RFC 5424 hoặc OTLP qua TLS |
| DF-11 | Datahub → thư, SMS | Thông báo chỉ có liên kết | NB | SMTP/TLS, REST |

: Luồng dữ liệu mức 0 và nhóm dữ liệu cao nhất

## 4. DFD mức 1

Mức 1 tách Datahub thành sáu tiến trình theo miền, trùng với cách gom phân hệ thành đơn vị triển khai ở D03-01 §4.2. Mục 4.1 vẽ cả sáu miền cùng các kho dùng chung; mục 4.2 đến 4.7 vẽ từng miền ở mức phân hệ.

### 4.1. Tổng thể sáu miền

Sơ đồ chỉ vẽ luồng giữa miền với nhau và với kho; luồng với thực thể ngoài, kể cả IF-07 (di trú, mục 6.8), IF-08 (nhật ký an ninh) và IF-09 (thư, SMS), đã có ở mức 0 và được gộp vào nút "Thực thể ngoài". Một số cạnh nối tiến trình với kho trong các sơ đồ mức 1, mức 2 không ghi nhãn khi nhóm dữ liệu trùng với luồng vào tiến trình đó.

```{.mermaid caption="DFD mức 1 tổng thể: sáu miền, kho dùng chung và nhóm dữ liệu trên luồng"}
flowchart TB
  EXT["Thực thể ngoài<br/>IF-01…IF-09, người dùng"]
  subgraph DH[Datahub]
    P1(["1.0 Kết nối và API<br/>PH-01, 02, 03, 15"])
    P2(["2.0 Tích hợp và sự kiện<br/>PH-04, 05, 10, 14"])
    P3(["3.0 Dữ liệu dùng chung<br/>PH-06, 07, 08, 09"])
    P4(["4.0 Nền tảng và vận hành<br/>PH-11, 12, 13, 16, 18, 20"])
    P5(["5.0 Thanh toán<br/>PH-19"])
    P6(["6.0 Trợ lý AI<br/>PH-17"])
    K[("DS-09 Kafka")]
    A[("DS-05 Nhật ký kiểm toán<br/>DS-12 WORM")]
    D[("DS-19 DLQ")]
  end
  EXT <-->|"API, sự kiện · theo hợp đồng"| P1
  P1 -->|"lượt gọi đã xác thực · theo hợp đồng"| P2
  P2 <-->|"sự kiện · theo hợp đồng"| K
  P2 -->|"bản tin lỗi · đến CN2, mã hóa"| D
  P3 -->|"sự kiện danh mục, dữ liệu chủ · CK, CN1"| K
  P5 -->|"sự kiện giao dịch · TC"| K
  P5 -->|"bản tin lỗi · đến TC"| D
  P2 -->|"tra cứu danh mục · CK"| P3
  P3 -->|"chính sách che, mục đích · NB"| P2
  P4 -->|"vai trò, chính sách · NB"| P1
  K -->|"sự kiện kiểm toán · NB, băm CN"| P4
  P4 -->|"bản ghi kiểm toán · NB"| A
  P4 <-->|"xử lý lại · đến CN2"| D
  K -->|"sự kiện thay đổi đã che · CK, NB"| P6
```

Hình làm rõ ba điều. Thứ nhất, Kafka (DS-09) là trục nối các miền, nên mức của topic quyết định mức của mọi miền tiêu thụ nó. Thứ hai, miền 2.0, 4.0 và 5.0 gửi bản tin lỗi vào DLQ; DLQ là kho chung duy nhất giữ bản sao dữ liệu đi qua của mọi luồng, bên cạnh các bản lưu có chủ đích và có thời hạn khác (thời hạn giữ topic Kafka, nội dung giao dịch quốc gia của PH-14, tệp nhập tạm) được nêu ở chương 5. Thứ ba, mọi miền gửi bản ghi kiểm toán và sự kiện thay đổi qua Kafka, nên PH-13 (trong 4.0) và trợ lý AI (6.0) chỉ nhận dữ liệu từ topic; mũi tên vào 6.0 chỉ mang CK hoặc NB vì bộ lập chỉ mục theo sự kiện (ADR-174) chỉ nhận mô tả dịch vụ, tài liệu và nhật ký đã che theo quy tắc SEC-49.

### 4.2. Miền 1.0 Kết nối và API

Miền này giữ hồ sơ HTTT, danh mục API, cấu hình cổng và cổng nhà phát triển. Dữ liệu cá nhân của miền là thông tin đầu mối của HTTT (CN1); dữ liệu đi qua cổng API mang mức hợp đồng.

```{.mermaid caption="DFD mức 1 miền Kết nối và API"}
flowchart TB
  HT["IF-01 HTTT"]
  ND["Người dùng, nhà phát triển"]
  P11(["1.1 Kết nạp HTTT<br/>PH-01"])
  P12(["1.2 Danh mục dịch vụ<br/>PH-02"])
  P13(["1.3 Cổng API<br/>PH-03"])
  P15(["1.4 Cổng nhà phát triển<br/>PH-15"])
  DS01[("DS-01 pg-core<br/>ph01, ph02, ph03, ph15")]
  DS11[("DS-11 Garage<br/>onboarding, catalog, portal")]
  DS15[("DS-15 Git cấu hình<br/>ảnh chụp gateway")]
  DS14[("DS-14 OpenBao")]
  ND -->|"hồ sơ, đầu mối · CN1"| P11
  P11 --> DS01
  P11 -->|"tài liệu hồ sơ · CN1"| DS11
  P11 -->|"khóa, chứng thư · BM"| DS14
  ND -->|"đặc tả API, gói · CK, NB"| P12
  P12 --> DS01
  P12 -->|"route, gói, đăng ký · NB"| P13
  P13 -->|"ảnh chụp có ký · NB"| DS15
  HT <-->|"lượt gọi · theo hợp đồng"| P13
  ND <-->|"tài liệu, sandbox · CK"| P15
  P15 -->|"đọc danh mục · CK"| P12
```

Đầu mối HTTT là DLCN cơ bản của cán bộ (họ tên, thư điện tử, điện thoại) nên DS-01 mang CN1 ở các cột đó; tài liệu kết nạp (công văn, quyết định) có thể chứa chữ ký và số định danh nên bucket onboarding mang CN1 và được mã hóa phía máy chủ. Cổng API không lưu nội dung lượt gọi, chỉ ghi siêu dữ liệu (DS-17).

### 4.3. Miền 2.0 Tích hợp và sự kiện

Miền này chạy luồng tích hợp, bộ điều hợp, sự kiện và kết nối quốc gia. Đây là miền có dữ liệu đi qua nhiều nhất; dữ liệu lưu lại chủ yếu là cấu hình (NB) và giao dịch quốc gia ở dạng siêu dữ liệu.

```{.mermaid caption="DFD mức 1 miền Tích hợp và sự kiện"}
flowchart TB
  SRC["IF-02 Hệ thống cũ, nguồn"]
  QG["IF-03 NDXP"]
  P21(["2.1 Luồng tích hợp<br/>PH-04"])
  P22(["2.2 Bộ điều hợp<br/>PH-05"])
  P23(["2.3 Sự kiện<br/>PH-10"])
  P24(["2.4 Kết nối quốc gia<br/>PH-14"])
  DS02[("DS-02 pg-core<br/>ph04, ph05, ph10, ph14")]
  DS09[("DS-09 Kafka")]
  DS10[("DS-10 Apicurio")]
  DS13[("DS-13 Valkey")]
  DS11[("DS-11 kho đối tượng<br/>dh-nat-payload")]
  DS19[("DS-19 DLQ")]
  SRC <-->|"bản ghi, tệp · theo hợp đồng"| P22
  P22 <-->|"bản tin chuẩn · theo hợp đồng"| P21
  P21 <-->|"sự kiện · theo hợp đồng"| P23
  P23 <--> DS09
  P23 -->|"lược đồ · NB"| DS10
  P21 <-->|"yêu cầu, kết quả · CN2"| P24
  P24 <-->|"bản tin ký số · CN2"| QG
  P24 -->|"đệm kết quả · đến CN1, mã hóa"| DS13
  P24 -->|"nội dung giao dịch · CN2, mã hóa"| DS11
  P21 & P22 & P24 -->|"cấu hình, siêu dữ liệu · NB"| DS02
  P21 & P23 -->|"bản tin lỗi · theo hợp đồng"| DS19
```

Hai chặng đáng chú ý. PH-14 chỉ đệm phản hồi đến mức Hạn chế và mã hóa giá trị bằng khóa tenant trước khi vào Valkey; phản hồi mức Nhạy cảm không bao giờ vào đệm (FR-14-035). Nội dung yêu cầu và phản hồi của giao dịch quốc gia được lưu mã hóa AES-256-GCM bằng DEK của tenant (khóa transit `dh-{tenant}-pii`) ở bucket `dh-nat-payload`, khóa đối tượng `{tenant}/{yyyy}/{MM}/{mã giao dịch}.{req,res}.enc`, thời hạn theo tham số `14.txn.payload-retention-days` (mặc định 30 ngày, tối đa 180, bằng 0 thì không ghi). Xem nội dung đầy đủ cần lý do và ghi kiểm toán (FR-14-050); xuất gói bằng chứng ký bằng khóa transit `dh-{tenant}-nat-evidence` là tính năng Đợt 2 (FR-14-051).

### 4.4. Miền 3.0 Dữ liệu dùng chung

Miền này giữ danh mục dùng chung, dữ liệu chủ, chất lượng dữ liệu và quyền riêng tư. Đây là miền có nhiều DLCN **lưu lại** nhất, do PH-06 giữ bản ghi vàng của công dân và tổ chức.

```{.mermaid caption="DFD mức 1 miền Dữ liệu dùng chung"}
flowchart TB
  QG["IF-04 Danh mục quốc gia"]
  HT["IF-01 HTTT nguồn"]
  P31(["3.1 Danh mục dùng chung<br/>PH-07"])
  P32(["3.2 Dữ liệu chủ<br/>PH-06"])
  P33(["3.3 Chất lượng dữ liệu<br/>PH-08"])
  P34(["3.4 Quyền riêng tư<br/>PH-09"])
  DS03[("DS-03 pg-core<br/>ph06, ph07, ph08, ph09")]
  DS11[("DS-11 Garage<br/>ảnh chụp danh mục, tệp nhập")]
  DS13[("DS-13 Valkey<br/>đệm danh mục")]
  DS14[("DS-14 OpenBao<br/>khóa pii, hmac")]
  QG -->|"danh mục qua PH-14 · CK"| P31
  P31 --> DS03
  P31 -->|"ảnh chụp · CK"| DS11
  P31 -->|"đệm hai tầng · CK"| DS13
  HT -->|"bản ghi nguồn · CN1, CN2"| P32
  P32 -->|"bản ghi vàng · CN2 mã hóa trường"| DS03
  P32 -->|"khóa dữ liệu · BM"| DS14
  P32 & P31 -->|"mẫu dữ liệu · đến CN2"| P33
  P33 -->|"phát hiện lỗi · đến CN1, đã che"| DS03
  P34 -->|"phân loại, chính sách che · NB"| DS03
  P34 -->|"sổ xử lý, yêu cầu chủ thể · CN1"| DS03
```

PH-08 đọc dữ liệu mẫu để đo chất lượng nhưng chỉ lưu kết quả đã che và băm có khóa trong `ph08_dq`, không lưu giá trị gốc. Bản ghi vàng của PH-06 mã hóa trường bằng khóa transit `dh-{tenant}-mdm-pii` và băm tìm kiếm bằng `dh-{tenant}-mdm-hmac` của OpenBao (DS-14); đó là khóa, không phải bucket. PH-09 không lưu dữ liệu nghiệp vụ của chủ thể; nó lưu siêu dữ liệu phân loại và hồ sơ yêu cầu của chủ thể (CN1: thông tin liên hệ của người yêu cầu).

### 4.5. Miền 4.0 Nền tảng và vận hành

Miền này gồm quy trình liên thông, định danh, giám sát kiểm toán, báo cáo chỉ tiêu, vận hành và quản trị tenant.

```{.mermaid caption="DFD mức 1 miền Nền tảng và vận hành"}
flowchart TB
  ND["Người dùng nội bộ"]
  VN["IF-06 VNeID"]
  P41(["4.1 Quy trình liên thông<br/>PH-11"])
  P42(["4.2 Định danh, phân quyền<br/>PH-12"])
  P43(["4.3 Giám sát, kiểm toán<br/>PH-13"])
  P44(["4.4 Báo cáo chỉ tiêu<br/>PH-16"])
  P45(["4.5 Vận hành, xử lý lỗi<br/>PH-18"])
  P46(["4.6 Quản trị tenant<br/>PH-20"])
  DS04[("DS-04 pg-core<br/>ph11, ph12, ph16, ph18, ph20")]
  DS05[("DS-05 ph13_audit")]
  DS07[("DS-07 pg-iam")]
  DS16[("DS-16 LGTM")]
  DS12[("DS-12 WORM")]
  DS19[("DS-19 DLQ")]
  ND -->|"hồ sơ quy trình · đến CN2"| P41
  P41 -->|"biến quy trình · CN2 mã hóa"| DS04
  ND & VN -->|"tài khoản, định danh · CN1"| P42
  P42 --> DS07
  P43 -->|"bản ghi kiểm toán · NB, băm CN"| DS05
  DS05 -->|"neo băm, bản sao · NB"| DS12
  P43 -->|"log, chỉ số, vết · NB đã che"| DS16
  P44 -->|"chỉ tiêu tổng hợp · NB"| DS04
  P45 <-->|"mục lỗi · theo hợp đồng"| DS19
  P46 -->|"cấu hình tỉnh · NB"| DS04
  DS04 ~~~ P43
  DS07 ~~~ P45
```

PH-11 là nơi dữ liệu hồ sơ thủ tục có thể vào biến quy trình; các biến gắn nhãn Nhạy cảm và `result_enc` được mã hóa envelope bằng khóa transit `dh-{tenant}-bpm-pii` rồi lưu trong `ph11_bpm` (DS-04); cách giữ biến lớn còn mở ở Q11-50. PH-12 không giữ mật khẩu ngoài Keycloak (DS-07). PH-13 chỉ ghi băm có khóa của khóa nghiệp vụ nhạy cảm (`object_key_hmac`), không ghi giá trị (D03-07 §7).

### 4.6. Miền 5.0 Thanh toán

Miền thanh toán có cụm CSDL riêng `pg-payment` và kho WORM riêng, vì dữ liệu tài chính phải sống khi control plane ngừng và không được sửa.

```{.mermaid caption="DFD mức 1 miền Thanh toán"}
flowchart TB
  DT["HTTT đối tác<br/>dịch vụ công"]
  PG["IF-05 PayGov, NCC"]
  KT["Kế toán đối soát"]
  P51(["5.1 Giao dịch và IPN"])
  P52(["5.2 Đối soát và chênh lệch"])
  P53(["5.3 Hoàn tiền"])
  P54(["5.4 Tra cứu, báo cáo"])
  DS06[("DS-06 pg-payment")]
  DS11[("DS-11 Garage<br/>payment, archive")]
  DS12[("DS-12 WORM<br/>payment-worm")]
  DT -->|"yêu cầu thanh toán · TC, CN1"| P51
  P51 <-->|"khởi tạo, IPN · TC"| PG
  P51 -->|"giao dịch, lịch sử · TC"| DS06
  P51 -->|"webhook có ký · TC"| DT
  PG -->|"tệp đối soát · TC"| P52
  KT -->|"tệp tải lên · TC"| P52
  P52 -->|"tệp gốc, SHA-256 · TC"| DS11
  P52 -->|"phiên, chênh lệch · TC"| DS06
  P52 -->|"biên bản đã chốt · TC"| DS12
  KT -->|"đề nghị hoàn · TC"| P53
  P53 <-->|"lệnh hoàn · TC"| PG
  DS06 -->|"danh sách, chỉ số · TC đã che"| P54
```

Thông tin người nộp (họ tên, mã hồ sơ) đi kèm yêu cầu thanh toán là CN1 và được mã hóa trường theo ADR-048. Tài khoản thụ hưởng của đơn vị nhận là TC; tài khoản cá nhân khi hoàn tiền là CN2.

### 4.7. Miền 6.0 Trợ lý AI

Trợ lý AI là miền duy nhất có giới hạn trần về nhóm dữ liệu: tối đa Hạn chế, không bao giờ CN2.

```{.mermaid caption="DFD mức 1 miền Trợ lý AI"}
flowchart TB
  ND["Người dùng nội bộ"]
  SRC["Miền 1.0 đến 4.0"]
  P61(["6.1 Lập chỉ mục"])
  P62(["6.2 Hỏi đáp, gợi ý"])
  MD["Mô hình ngôn ngữ<br/>qua APISIX ai-proxy"]
  DS08[("DS-08 ph17_assist<br/>pgvector")]
  SRC -->|"mô tả dịch vụ, tài liệu, log đã che · CK, NB"| P61
  P61 -->|"vector theo tenant · CK, NB"| DS08
  ND -->|"câu hỏi · NB"| P62
  P62 <-->|"truy hồi · CK, NB"| DS08
  P62 <-->|"lời nhắc đã lọc · đến Hạn chế"| MD
  P62 -->|"trả lời có nguồn · CK, NB"| ND
```

Hai lớp chặn: (1) bộ lập chỉ mục từ chối nguồn mang nhãn Hạn chế trở lên trừ khi tenant bật và mô hình chạy nội bộ (SEC-49; mô hình nội bộ theo ADR-170, ADR-171); (2) câu hỏi của người dùng đi qua bộ lọc phát hiện mẫu số định danh, số điện thoại, số thẻ trước khi gửi mô hình (ADR-173). Công cụ đọc dữ liệu thật của trợ lý dùng token của chính người dùng, chỉ đọc (ADR-172), nên không vượt quyền của người hỏi.

## 5. Danh mục kho dữ liệu và phân loại

Bảng dưới là danh mục 19 kho dữ liệu, mỗi kho gắn tài sản ở D03-07 §3.1, nhóm dữ liệu chứa, mức cao nhất và biện pháp chính. Cột "CN2 giải mã được" cho biết kho có chứa DLCN nhạy cảm ở dạng mà một người có khóa giải mã đọc được hay không; đây là danh sách kho cần ưu tiên khi đánh giá tác động và khi xử lý sự cố lộ lọt.

| Mã | Kho | Tài sản | Phân hệ | Nhóm chứa | Mức cao nhất | CN2 giải mã được | Biện pháp chính |
|---|---|---|---|---|---|---|---|
| DS-01 | pg-core: `ph01_onboarding`, `ph02_catalog`, `ph03_gateway`, `ph15_portal` | AS-06 | PH-01, 02, 03, 15 | CK, NB, CN1 | Hạn chế | Không | Mã hóa volume, RLS tenant |
| DS-02 | pg-core: `ph04`, `ph05_adapter`, `ph10_event`, `ph14_national` | AS-06 | PH-04, 05, 10, 14 | NB, CN1 (định danh người gọi trong siêu dữ liệu giao dịch quốc gia; tham số định danh chỉ ở dạng băm) | Hạn chế | Không | Mã hóa volume, RLS; không lưu thân bản tin |
| DS-03 | pg-core: `ph06_mdm`, `ph07_rdm`, `ph08_dq`, `ph09_privacy` | AS-06 | PH-06, 07, 08, 09 | CK, NB, CN1, CN2 | Nhạy cảm | Có (bản ghi vàng PH-06) | Mã hóa trường ADR-032, HMAC tìm kiếm, RLS |
| DS-04 | pg-core: `ph11_bpm`, `ph12_iam`, `ph16_kpi`, `ph18_ops`, `ph20_tenant` | AS-06 | PH-11, 12, 16, 18, 20 | NB, CN1, CN2 (biến quy trình) | Nhạy cảm | Có (biến quy trình PH-11) | Mã hóa trường, RLS |
| DS-05 | pg-core: `ph13_audit.audit_event` | AS-16 | PH-13 | NB, băm CN | Hạn chế | Không | Chuỗi băm, không ghi giá trị Nhạy cảm |
| DS-06 | pg-payment: `ph19_payment` | AS-02 | PH-19 | TC, CN1, CN2 (tài khoản hoàn tiền) | Nhạy cảm | Có | Mã hóa trường ADR-048, phân vùng tháng ADR-047, cụm riêng TPH-0 |
| DS-07 | pg-iam: realm Keycloak | AS-10 | PH-12 | CN1 (tài khoản cán bộ), băm mật khẩu và bí mật TOTP xếp mức Hạn chế theo AS-10 | Hạn chế | Không | Cụm riêng TPH-0, Z6 |
| DS-08 | pg-core: `ph17_assist` (pgvector) | AS-03 | PH-17 | CK, NB | Nội bộ, trần Hạn chế | Không | RLS theo tenant, cấm nguồn Nhạy cảm |
| DS-09 | Kafka: topic `{tenant}.*` | AS-04 | PH-10 và mọi DU | Theo hợp đồng, tới CN2 | Nhạy cảm | Có (thân bản tin topic Nhạy cảm, mã hóa ở tầng ứng dụng) | ACL theo topic, mã hóa thân bản tin topic Nhạy cảm, thời hạn giữ theo topic |
| DS-10 | Apicurio (pg-infra) | AS-04 | PH-10 | NB | Nội bộ | Không | Lược đồ, không dữ liệu |
| DS-11 | Kho đối tượng: bucket `dh-{tenant}-*` (Garage) và `dh-nat-payload` của PH-14 | AS-07 | Mọi phân hệ có tệp | CK, CN1, CN2, TC, BM (gói bàn giao thông tin xác thực PH-01) | Nhạy cảm | Có (tệp nhập tạm, nội dung giao dịch quốc gia) | SSE-C với khóa từ OpenBao cho bucket ≥ Hạn chế; tệp nhập tạm ≤ 24 giờ |
| DS-12 | Ceph RGW: bucket WORM (kiểm toán, `payment-worm`) | AS-08 | PH-13, PH-19 | NB, TC | Hạn chế | Không | Object Lock 5 năm, tách bucket với sao lưu |
| DS-13 | Valkey | AS-09 | PH-03, 07, 14, BFF | CK, NB, CN1 (đã mã hóa) | Hạn chế | Không | Khóa có tiền tố tenant, TTL ≤ 15 phút cho Hạn chế; không giá trị Nhạy cảm rõ |
| DS-14 | OpenBao | AS-11 | Mọi DU | BM | Tối mật kỹ thuật | Không (là nơi giữ khóa) | Z6, transit không cho xuất khóa |
| DS-15 | Kho Git cấu hình | AS-13 | PH-03, PH-04 | NB | Nội bộ | Không | Commit ký, cấm bí mật trong YAML |
| DS-16 | LGTM: Loki, Mimir, Tempo | AS-15 | PH-13 | NB (đã che) | Hạn chế | Không | Che ba lớp SEC-32, quét mẫu hằng ngày |
| DS-17 | ClickHouse `dh-olap` | AS-20 | PH-03, PH-13, PH-16 | NB (siêu dữ liệu lượt gọi) | Hạn chế | Không | Không chứa nội dung bản tin, giữ 12 tháng |
| DS-18 | Sao lưu: Barman, Velero, bản sao ngoài site | AS-17 | Vận hành | Mọi nhóm | Nhạy cảm | Có (như kho gốc, trường vẫn mã hóa) | Mã hóa trước khi rời site; hủy KEK làm bản sao không giải được |
| DS-19 | DLQ: topic `{tenant}.ops.dlq.v1` và chỉ mục `ph18_ops` | AS-04, AS-06 | PH-18 | Theo hợp đồng, tới CN2 | Nhạy cảm | Có | Mã hóa bằng khóa tenant, tự xóa ≤ 7 ngày với hợp đồng Nhạy cảm, xem payload cần quyền và lý do (ADR-181) |

: Mười chín kho dữ liệu, nhóm dữ liệu chứa và biện pháp chính

Bảy kho có CN2 giải mã được là DS-03, DS-04, DS-06, DS-09, DS-11, DS-18, DS-19; trong đó DS-09 và DS-19 chỉ giữ dữ liệu đi qua trong thời hạn ngắn. Đây là phạm vi tối thiểu của hồ sơ DPIA và của kịch bản ứng phó lộ lọt dữ liệu cá nhân trong D03-07.

## 6. DFD mức 2 cho tám luồng trọng yếu

Tám luồng dưới đây là những luồng dàn ý yêu cầu vẽ chi tiết, vì chúng mang dữ liệu cá nhân hoặc tài chính, hoặc là nơi dữ liệu được nhân bản. Mỗi mục có sơ đồ, thuyết minh, bảng chặng (đánh số theo mục, ví dụ `6.1-a`) và các điểm kiểm soát dùng làm đầu vào cho kiểm thử bảo mật D05-04.

### 6.1. Tra cứu đồng bộ giữa hai HTTT

Một HTTT của sở gọi API do HTTT khác công bố, qua cổng APISIX; có thể đi qua một luồng chuyển đổi trong `dh-runtime`. Đây là luồng lưu lượng lớn nhất; nội dung không được lưu.

```{.mermaid caption="DFD mức 2 luồng tra cứu đồng bộ giữa hai HTTT"}
flowchart TB
  HG["HTTT gọi"]
  HC["HTTT cung cấp"]
  subgraph DH[Datahub]
    P1(["6.1.1 Xác thực,<br/>kiểm đăng ký"])
    P2(["6.1.2 Hạn mức,<br/>ủy quyền OPA"])
    P3(["6.1.3 Chuyển đổi<br/>luồng PH-04"])
    P4(["6.1.4 Ghi siêu dữ liệu"])
    V[("DS-13 Valkey<br/>bộ đếm")]
    O[("DS-17 dh-olap")]
    L[("DS-16 LGTM")]
  end
  HG -->|"6.1-a yêu cầu, token · theo hợp đồng"| P1
  P1 --> P2
  P2 <-->|"6.1-b bộ đếm · NB"| V
  P2 -->|"6.1-c yêu cầu · theo hợp đồng"| P3
  P3 <-->|"6.1-d gọi, phản hồi · theo hợp đồng"| HC
  P3 -->|"6.1-e phản hồi · theo hợp đồng"| HG
  P1 & P3 -->|"6.1-f siêu dữ liệu · NB"| P4
  P4 --> O
  P4 --> L
```

Điều người đọc cần thấy: nội dung (6.1-a, c, d, e) chỉ ở trong bộ nhớ của APISIX và `dh-runtime`; mọi thứ đi vào kho (6.1-b, f) là nội bộ. Khi luồng không cần chuyển đổi, 6.1.3 bị bỏ và APISIX chuyển thẳng tới HTTT cung cấp.

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.1-a | Yêu cầu, token máy, `traceparent` | Theo hợp đồng | TLS 1.3; OAuth 2.1, mTLS bắt buộc với hợp đồng Nhạy cảm (SEC-24) |
| 6.1-b | Bộ đếm hạn mức theo consumer, tenant | NB | Khóa có tiền tố tenant |
| 6.1-c, d, e | Thân yêu cầu và phản hồi | Theo hợp đồng | mTLS mesh trong cụm; egress tới HTTT cung cấp theo danh sách |
| 6.1-f | Ai gọi, gọi gì, khi nào, kết quả, kích thước | NB | Không ghi thân, không ghi tham số truy vấn chứa định danh; che theo mẫu ở OTel Collector |

: Chặng của luồng tra cứu đồng bộ

Điểm kiểm soát: (1) `X-DH-Tenant` do APISIX đặt, không tin header của client (SEC-80); (2) OPA từ chối hợp đồng có trường Nhạy cảm nếu `purpose` không được chấp thuận cho HTTT gọi (SEC-37); (3) bước `log` trong luồng PH-04 bị lint cấm ghi thân bản tin hợp đồng Nhạy cảm (SEC-46); (4) lỗi chuyển đổi đưa bản tin vào DLQ theo mục 6.6, không ghi vào log.

### 6.2. Tra cứu CSDL quốc gia

HTTT của tỉnh tra cứu dữ liệu dân cư, lý lịch tư pháp, hộ tịch, BHXH hoặc đăng ký doanh nghiệp qua điểm gọi chung của PH-14, tới NDXP. Đây là luồng mang CN2 với khối lượng lớn nhất, và là lý do chính khiến Datahub ở cấp độ 3.

```{.mermaid caption="DFD mức 2 luồng tra cứu CSDL quốc gia qua PH-14"}
flowchart TB
  HT["HTTT tỉnh"]
  NDXP["IF-03 NDXP, CSDL quốc gia"]
  subgraph DH[Datahub]
    P1(["6.2.1 Cổng API<br/>xác thực"])
    P2(["6.2.2 Kiểm mục đích,<br/>hạn mức"])
    P3(["6.2.3 Tra đệm"])
    P4(["6.2.4 Chuyển đổi,<br/>ký số, gọi"])
    P5(["6.2.5 Xác minh chữ ký,<br/>chuẩn hóa lỗi"])
    C[("DS-13 Valkey<br/>đệm đã mã hóa")]
    Q[("DS-02 ph14_national<br/>hạn mức, giao dịch")]
    E[("DS-11 dh-nat-payload")]
    B[("DS-14 OpenBao<br/>khóa ký, token")]
  end
  HT -->|"6.2-a yêu cầu, mục đích · CN2"| P1
  P1 --> P2
  P2 <-->|"6.2-b hạn mức, chấp thuận · NB"| Q
  P2 --> P3
  P3 <-->|"6.2-c kết quả đệm · đến CN1, mã hóa"| C
  P3 -->|"không trúng đệm"| P4
  P4 <-->|"6.2-d khóa ký, token · BM"| B
  P4 <-->|"6.2-e bản tin ký số · CN2"| NDXP
  P4 --> P5
  P5 -->|"6.2-f nội dung giao dịch · CN2, mã hóa"| E
  P5 -->|"6.2-g siêu dữ liệu giao dịch · NB"| Q
  P5 -->|"6.2-h kết quả · CN2"| HT
```

Hình cho thấy kiểm mục đích (6.2.2) đứng **trước** tra đệm (6.2.3): một HTTT không được chấp thuận không thể đọc được kết quả mà HTTT khác đã làm nóng đệm (BR-14-015). Phản hồi mức Nhạy cảm bỏ qua đệm hoàn toàn.

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.2-a | Tham số tra cứu (số định danh, họ tên), mã mục đích | CN2 | mTLS bắt buộc; `purpose` trong token |
| 6.2-b | Hạn mức, chấp thuận mục đích | NB | RLS tenant |
| 6.2-c | Kết quả đệm của dịch vụ `cacheable` | Đến CN1 | Mã hóa giá trị bằng khóa tenant; khóa đệm là băm tham số; không đệm dịch vụ Nhạy cảm |
| 6.2-d | Khóa ký số, token OAuth của nền tảng | BM | OpenBao transit, không xuất khóa |
| 6.2-e | Yêu cầu và phản hồi đã ký | CN2 | TLS, ký và xác minh chữ ký; egress chỉ tới địa chỉ NDXP |
| 6.2-f | Nội dung yêu cầu, phản hồi đã ký | CN2 | Mã hóa bằng DEK tenant, quyền xem đầy đủ có lý do (FR-14-050), giữ mặc định 30 ngày, tối đa 180 |
| 6.2-g | Mã giao dịch, thời điểm, kết quả, `fromCache` | NB | Không ghi tham số định danh rõ, chỉ băm có khóa |
| 6.2-h | Kết quả tra cứu | CN2 | Như 6.2-a |

: Chặng của luồng tra cứu CSDL quốc gia

Điểm kiểm soát: (1) mọi lượt gọi có `purpose` thuộc danh sách chủ quản chấp thuận (FR-14-011); (2) cảnh báo khai thác bất thường theo HTTT (FR-14-053, UC-SEC ở D03-07); (3) không có kết quả Nhạy cảm trong Valkey (kiểm bằng quét mẫu); (4) chữ ký phản hồi không hợp lệ được xử lý như sự cố an ninh (FR-14-031).

### 6.3. Phát và nhận sự kiện

HTTT phát sự kiện vào topic qua cổng sự kiện của PH-10; HTTT nhận qua đẩy webhook hoặc kéo. Sự kiện được Kafka giữ theo thời hạn của topic, nên đây là dữ liệu đi qua có thời gian nằm lại.

```{.mermaid caption="DFD mức 2 luồng phát và nhận sự kiện qua PH-10"}
flowchart TB
  HP["HTTT phát"]
  HN["HTTT nhận"]
  subgraph DH[Datahub]
    P1(["6.3.1 Cổng API<br/>scope publish"])
    P2(["6.3.2 Kiểm phong bì,<br/>lược đồ, chống trùng"])
    P3(["6.3.3 Phân phối<br/>đẩy, kéo"])
    R[("DS-10 Apicurio")]
    K[("DS-09 Kafka<br/>topic tenant")]
    D[("DS-19 DLQ")]
  end
  HP -->|"6.3-a sự kiện CloudEvents · theo hợp đồng"| P1
  P1 --> P2
  P2 <-->|"6.3-b lược đồ · NB"| R
  P2 -->|"6.3-c sự kiện hợp lệ · theo hợp đồng"| K
  K -->|"6.3-d sự kiện · theo hợp đồng"| P3
  P3 -->|"6.3-e webhook có ký, hoặc kéo · theo hợp đồng"| HN
  P3 -->|"6.3-f gửi hỏng quá số lần · theo hợp đồng"| D
```

Mức hợp đồng của topic được PH-09 xác nhận khi tạo topic; topic Nhạy cảm có thân bản tin mã hóa ở tầng ứng dụng trước khi vào Kafka và thời hạn giữ ngắn hơn mặc định.

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.3-a | Phong bì CloudEvents và dữ liệu | Theo hợp đồng | OAuth 2.1 hoặc mTLS, scope publish theo topic |
| 6.3-b | Lược đồ JSON hoặc Avro | NB | Kiểm tương thích (ADR-070) |
| 6.3-c, d | Sự kiện đã kiểm | Theo hợp đồng | ACL topic theo service account (ADR-072); mã hóa thân topic Nhạy cảm |
| 6.3-e | Sự kiện tới bên nhận | Theo hợp đồng | Webhook ký HMAC; bên nhận phải có subscription được duyệt |
| 6.3-f | Sự kiện gửi hỏng | Theo hợp đồng | Theo mục 6.6 |

: Chặng của luồng phát và nhận sự kiện

Điểm kiểm soát: (1) subscription tới topic có trường Nhạy cảm cần chấp thuận của chủ quản qua PH-09; (2) topic luôn có tiền tố tenant, không có topic dùng chung giữa tenant trừ `COMMON` chỉ đọc; (3) cầu nối Pulsar–Kafka giai đoạn chuyển đổi đi qua cùng 6.3.2 (ADR-073).

### 6.4. Đồng bộ danh mục

PH-07 đồng bộ danh mục quốc gia qua PH-14 theo lịch, phát hành phiên bản mới, sinh ảnh chụp và phân phối tới mọi nơi dùng. Đây là luồng dữ liệu công khai, nhưng tính toàn vẹn quan trọng vì sai danh mục làm sai mọi hồ sơ dùng nó.

```{.mermaid caption="DFD mức 2 luồng đồng bộ và phân phối danh mục dùng chung"}
flowchart TB
  QG["IF-04 Danh mục quốc gia"]
  DS["Cán bộ quản lý dữ liệu"]
  HT["HTTT, luồng tích hợp"]
  subgraph DH[Datahub]
    P1(["6.4.1 Lấy dữ liệu<br/>qua PH-14"])
    P2(["6.4.2 So khác biệt,<br/>quyết định áp dụng"])
    P3(["6.4.3 Phát hành<br/>phiên bản"])
    P4(["6.4.4 Sinh ảnh chụp,<br/>phân phối"])
    DB[("DS-03 ph07_rdm")]
    S3[("DS-11 rdm<br/>ảnh chụp")]
    VK[("DS-13 Valkey L2")]
    K[("DS-09 Kafka")]
  end
  QG -->|"6.4-a cấu trúc, dữ liệu · CK"| P1
  P1 --> P2
  P2 <-->|"6.4-b phiên bản hiện hành · CK"| DB
  P2 -->|"có phá vỡ: chờ xác nhận"| DS
  DS -->|"6.4-c xác nhận · NB"| P3
  P2 -->|"không phá vỡ, tự áp dụng"| P3
  P3 --> DB
  P3 --> P4
  P4 -->|"6.4-d ảnh chụp, SHA-256 · CK"| S3
  P4 -->|"6.4-e sự kiện phát hành · CK"| K
  P4 -->|"6.4-f đệm hai tầng · CK"| VK
  VK -->|"6.4-g tra cứu · CK"| HT
```

Hình cho thấy hai nhánh của ADR-057: thay đổi không phá vỡ được tự áp dụng, thay đổi phá vỡ chờ cán bộ xác nhận. Ảnh chụp có tổng kiểm tra để `dh-runtime` từ chối ảnh hỏng.

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.4-a | Danh mục quốc gia | CK | Qua PH-14, token NDXP; thời gian chờ 60 giây, thử lại 3 lần |
| 6.4-b | Phiên bản hiện hành | CK | Khóa tư vấn theo nguồn, không chạy song song |
| 6.4-c | Quyết định xác nhận | NB | Bốn mắt khi phá vỡ, ghi kiểm toán |
| 6.4-d | Tệp JSON, CSV nén | CK | SHA-256 trong `catalog_version`; bucket chỉ đọc cho runtime |
| 6.4-e, f, g | Sự kiện, mục đệm, kết quả tra cứu | CK | Khóa đệm theo `version_id`, không bao giờ cũ |

: Chặng của luồng đồng bộ danh mục

Điểm kiểm soát: (1) cảnh báo khi lần đồng bộ thành công cuối quá 26 giờ; (2) danh mục đơn vị hành chính sau sáp nhập giữ lịch sử kế thừa (ADR-055); (3) danh mục có thuộc tính động gắn nhãn Hạn chế (ví dụ danh bạ cán bộ) không được phân phối qua đệm công khai mà qua API có xác thực.

### 6.5. Thanh toán và đối soát

HTTT dịch vụ công tạo giao dịch thu phí, lệ phí; người nộp thanh toán trên trang của nhà cung cấp; Datahub nhận kết quả, báo cho HTTT và đối soát hằng ngày với tệp của nhà cung cấp.

```{.mermaid caption="DFD mức 2 luồng thanh toán và đối soát PH-19"}
flowchart TB
  DT["HTTT đối tác"]
  NN["Người nộp"]
  NCC["IF-05 PayGov, NCC"]
  KT["Kế toán đối soát"]
  subgraph DH[Datahub]
    P1(["6.5.1 Tạo giao dịch,<br/>lũy đẳng"])
    P2(["6.5.2 Khởi tạo tại NCC"])
    P3(["6.5.3 Nhận IPN<br/>đúng một lần"])
    P4(["6.5.4 Báo kết quả<br/>webhook"])
    P5(["6.5.5 Thu thập,<br/>so khớp"])
    P6(["6.5.6 Xử lý chênh lệch,<br/>chốt phiên"])
    DB[("DS-06 pg-payment")]
    F[("DS-11 payment")]
    W[("DS-12 payment-worm")]
  end
  DT -->|"6.5-a yêu cầu, thông tin người nộp · TC, CN1"| P1
  P1 -->|"6.5-b giao dịch CREATED · TC, CN1 mã hóa"| DB
  P1 --> P2
  P2 <-->|"6.5-c khởi tạo, URL thanh toán · TC"| NCC
  NN -->|"6.5-d thẻ, tài khoản · nhập ở trang NCC"| NCC
  NCC -->|"6.5-e IPN có ký · TC"| P3
  P3 -->|"6.5-f lịch sử trạng thái · TC"| DB
  P3 --> P4
  P4 -->|"6.5-g kết quả có ký · TC"| DT
  NCC -->|"6.5-h tệp đối soát · TC"| P5
  KT -->|"6.5-i tệp tải lên · TC"| P5
  P5 -->|"6.5-j tệp gốc, SHA-256 · TC"| F
  P5 --> P6
  KT -->|"6.5-k đề xuất, phê duyệt · TC"| P6
  P6 -->|"6.5-l chênh lệch, phiên · TC"| DB
  P6 -->|"6.5-m biên bản đã chốt · TC"| W
```

Chặng 6.5-d nằm **ngoài** ranh giới Datahub: người nộp nhập thẻ hoặc tài khoản trên trang của nhà cung cấp, Datahub không bao giờ nhận số thẻ. Lượt người nộp quay về trang dịch vụ không làm đổi trạng thái giao dịch; chỉ IPN có ký, truy vấn chủ động hoặc xử lý chênh lệch có phê duyệt mới đổi (ADR-043).

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.5-a | Mã hồ sơ, số tiền, họ tên người nộp, `Idempotency-Key` | TC, CN1 | Xác thực đối tác (ROLE-PARTNER_SYSTEM), mTLS, chống trùng (ADR-041) |
| 6.5-b, f | Giao dịch, lịch sử trạng thái | TC, CN1 | Mã hóa trường người nộp (ADR-048); lịch sử chỉ thêm; phân vùng tháng (ADR-047) |
| 6.5-c | Yêu cầu khởi tạo, URL | TC | Ký theo đặc tả NCC; egress tới NCC |
| 6.5-e | IPN | TC | Xác minh chữ ký, chống phát lại bằng nonce, cách ly IPN bất thường (FR-19-031) |
| 6.5-g | Kết quả tới đối tác | TC | Webhook ký HMAC (ADR-044), gửi lại có giới hạn |
| 6.5-h, i, j | Tệp đối soát | TC | Lưu tệp gốc trước khi phân tích, SHA-256, không nạp lại tệp trùng |
| 6.5-k, l | Đề xuất xử lý chênh lệch | TC | Phê duyệt bốn mắt (ADR-046), MFA cho `ROLE-PAYMENT_ACCOUNTANT` |
| 6.5-m | Biên bản đối soát | TC | Object Lock 5 năm |

: Chặng của luồng thanh toán và đối soát

Điểm kiểm soát: (1) tổng tiền theo ngày của Datahub khớp tệp NCC tới từng đồng, chênh lệch có bản ghi; (2) không có số thẻ, số tài khoản cá nhân dạng rõ ở mọi kho (quét mẫu Luhn ở DS-06, DS-16); (3) hoàn tiền vào tài khoản cá nhân là CN2, chỉ vai trò thanh toán có MFA xem được.

### 6.6. Xử lý bản tin lỗi

Bản tin không xử lý được ở luồng tích hợp, cổng sự kiện hoặc phân hệ nghiệp vụ vào hàng đợi lỗi hợp nhất của PH-18; người vận hành xem, sửa, phát lại qua lối vào của nguồn. Đây là nơi chung duy nhất giữ bản sao dữ liệu đi qua của mọi luồng; các bản lưu có thời hạn khác do từng phân hệ tự quản (chương 5).

```{.mermaid caption="DFD mức 2 luồng xử lý bản tin lỗi PH-18"}
flowchart TB
  SRC["Nguồn lỗi<br/>PH-04, PH-10, PH-19…"]
  VH["Vận hành tỉnh"]
  DY["Người duyệt"]
  subgraph DH[Datahub]
    P1(["6.6.1 Nhận mục lỗi,<br/>khử trùng"])
    P2(["6.6.2 Phân loại,<br/>chỉ mục"])
    P3(["6.6.3 Xem có lý do"])
    P4(["6.6.4 Phát lại<br/>qua nguồn"])
    P5(["6.6.5 Dọn theo hạn"])
    K[("DS-19 topic DLQ")]
    IX[("DS-04 ph18_ops<br/>chỉ mục")]
    A[("DS-05 kiểm toán")]
  end
  SRC -->|"6.6-a bản tin, ngữ cảnh lỗi · theo hợp đồng, mã hóa"| K
  K --> P1
  P1 -->|"6.6-b siêu dữ liệu lỗi · NB"| P2
  P2 --> IX
  VH -->|"6.6-c yêu cầu xem, lý do · NB"| P3
  P3 <-->|"6.6-d payload · theo hợp đồng, che"| K
  P3 -->|"6.6-e lượt xem · NB"| A
  VH -->|"6.6-f lệnh phát lại · NB"| P4
  DY -->|"6.6-g duyệt loạt lớn · NB"| P4
  P4 -->|"6.6-h bản tin phát lại · theo hợp đồng"| SRC
  P5 -->|"xóa quá hạn"| K
```

Payload trong DLQ đã được nguồn mã hóa trước khi gửi, nên chỉ mục ở `ph18_ops` chỉ chứa siêu dữ liệu (lý do, công đoạn, mã lỗi, luồng, `traceparent`). Xem payload là thao tác riêng, cần quyền, lý do và sinh bản ghi kiểm toán.

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.6-a | Bản tin lỗi kèm ngữ cảnh chuẩn | Theo hợp đồng | Mã hóa bằng khóa tenant; thiếu trường bắt buộc thì `POISON` (BR-18-013) |
| 6.6-b | Lý do, số lần thử, mã lỗi | NB | Không chứa giá trị của thân |
| 6.6-c, e | Lý do xem, lượt xem | NB | Ghi kiểm toán bắt buộc |
| 6.6-d | Payload | Theo hợp đồng | Che theo chính sách PH-09; trường Nhạy cảm hiện tối đa 60 giây khi có `PERM-09-unmask` |
| 6.6-f, g | Lệnh phát lại | NB | Vượt ngưỡng `18.dlq.replay.approval-threshold` cần người thứ hai (ADR-182) |
| 6.6-h | Bản tin phát lại | Theo hợp đồng | Đi lại đúng lối vào của nguồn, qua đủ kiểm tra như lần đầu |

: Chặng của luồng xử lý bản tin lỗi

Điểm kiểm soát: (1) mục DLQ của hợp đồng Nhạy cảm tự xóa sau tối đa 7 ngày; (2) không có đường phát lại nào bỏ qua kiểm tra của nguồn; (3) xuất payload hàng loạt bị cấm, chỉ xem từng mục.

### 6.7. Kết nạp HTTT

Đơn vị đề nghị kết nạp HTTT; quản trị tỉnh thẩm định, phê duyệt; Datahub cấp định danh ứng dụng và bàn giao thông tin xác thực một lần cho đầu mối kỹ thuật.

```{.mermaid caption="DFD mức 2 luồng kết nạp HTTT PH-01"}
flowchart TB
  OR["Cán bộ đầu mối"]
  TA["Quản trị tỉnh,<br/>người thẩm định"]
  KT["Đầu mối kỹ thuật"]
  subgraph DH[Datahub]
    P1(["6.7.1 Lập, nộp hồ sơ"])
    P2(["6.7.2 Kiểm tra,<br/>thẩm định, duyệt"])
    P3(["6.7.3 Cấp định danh<br/>ứng dụng"])
    P4(["6.7.4 Bàn giao<br/>một lần"])
    DB[("DS-01 ph01_onboarding")]
    F[("DS-11 onboarding,<br/>handover")]
    KC[("DS-07 pg-iam<br/>client")]
    B[("DS-14 OpenBao<br/>PKI, bí mật")]
    K[("DS-09 Kafka")]
  end
  OR -->|"6.7-a hồ sơ, đầu mối · CN1"| P1
  OR -->|"6.7-b tài liệu đính kèm · CN1"| F
  P1 --> DB
  TA -->|"6.7-c ý kiến, quyết định · NB"| P2
  P2 --> DB
  P2 --> P3
  P3 -->|"6.7-d client · NB"| KC
  P3 -->|"6.7-e chứng thư, bí mật · BM"| B
  P3 -->|"6.7-f HTTT ACTIVE · NB"| K
  P3 --> P4
  P4 -->|"6.7-g gói bàn giao mã hóa · BM"| F
  P4 -->|"6.7-h liên kết tải một lần · BM"| KT
```

Thông tin xác thực chỉ tồn tại rõ ở hai nơi: OpenBao và gói bàn giao mã hóa tải một lần. Sau khi tải, gói bị xóa và không còn bản sao nào đọc lại được (FR-01-022).

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.7-a | Thông tin HTTT, đầu mối (họ tên, chức vụ, thư, điện thoại) | CN1 | Che một phần trong log; RLS theo tổ chức |
| 6.7-b | Công văn, quyết định, sơ đồ hệ thống | CN1 | Quét mã độc, SSE-C, hạn giữ theo hồ sơ |
| 6.7-c | Ý kiến thẩm định | NB | Bốn mắt, ý kiến bắt buộc (FR-00-072) |
| 6.7-d | Client Keycloak | NB | Tạo qua API quản trị trong Z6 |
| 6.7-e | Chứng thư client, bí mật | BM | PKI OpenBao, khóa riêng không rời HTTT khi HTTT tự sinh CSR |
| 6.7-f | Sự kiện trạng thái HTTT | NB | Topic tenant |
| 6.7-g, h | Gói bàn giao | BM | Mã hóa, liên kết một lần, hạn 72 giờ, gửi qua kênh khác với mật khẩu giải mã |

: Chặng của luồng kết nạp HTTT

Điểm kiểm soát: (1) không gửi bí mật qua thư (FR-00-062); (2) đầu mối là DLCN của cán bộ, có cơ sở pháp lý là thực hiện nhiệm vụ, ghi trong sổ xử lý PH-09; (3) rà soát quyền định kỳ thu hồi định danh không dùng (PH-01 nhóm E).

### 6.8. Di trú từ hệ cũ

Công cụ `dh-migrate` đọc dữ liệu hệ LGSP cũ bằng kết nối chỉ đọc, chuyển đổi và ghi vào phân hệ đích qua API nhập của chính phân hệ đó. Giai đoạn chạy song song có thêm cầu nối Pulsar–Kafka.

```{.mermaid caption="DFD mức 2 luồng di trú từ hệ LGSP cũ"}
flowchart TB
  CU["IF-07 LGSP cũ<br/>CSDL Aita, APIM, PayGov, Pulsar"]
  VH["Vận hành, người duyệt"]
  subgraph DH[Datahub]
    P1(["6.8.1 Đọc nguồn<br/>chỉ đọc"])
    P2(["6.8.2 Chuyển đổi,<br/>loại thông tin xác thực"])
    P3(["6.8.3 Ghi qua API nhập<br/>phân hệ đích"])
    P4(["6.8.4 Đối chiếu,<br/>báo cáo"])
    P5(["6.8.5 Cầu nối<br/>Pulsar–Kafka"])
    DST[("DS-01, 02, 03, 06<br/>phân hệ đích")]
    OPS[("DS-04 ph18_ops<br/>lần chạy, báo cáo")]
    K[("DS-09 Kafka")]
  end
  CU -->|"6.8-a bản ghi cũ · CN1, TC, BM"| P1
  P1 --> P2
  P2 -->|"6.8-b bản ghi chuẩn · CN1, TC"| P3
  VH -->|"6.8-c duyệt chạy thật · NB"| P3
  P3 -->|"6.8-d nhập lũy đẳng · CN1, TC"| DST
  P3 --> P4
  P4 -->|"6.8-e số lượng, tổng kiểm tra · NB"| OPS
  CU -->|"6.8-f sự kiện cũ · theo hợp đồng"| P5
  P5 -->|"6.8-g CloudEvents · theo hợp đồng"| K
```

Thông tin xác thực cũ (mật khẩu, API key, khóa của HTTT) có trong nguồn ở chặng 6.8-a nhưng bị loại ở 6.8.2 và đánh dấu "cấp lại", không bao giờ vào kho của Datahub (ADR-183). Mọi lần chạy thật cần bốn mắt; chạy thử không ghi.

| Chặng | Dữ liệu | Nhóm | Bảo vệ |
|---|---|---|---|
| 6.8-a | Danh mục, HTTT, API, plan, subscription, topic, luồng XML, giao dịch lịch sử | CN1, TC, BM | Tài khoản JDBC chỉ đọc (IF-07), kết nối TLS nếu nguồn hỗ trợ, trong mạng quản trị |
| 6.8-b | Bản ghi đã chuẩn hóa | CN1, TC | Trong bộ nhớ Job; không ghi tệp trung gian chứa CN ra đĩa không mã hóa |
| 6.8-c | Quyết định chạy thật | NB | Bốn mắt, ghi kiểm toán |
| 6.8-d | Bản ghi nhập vào đích | CN1, TC | Qua API nhập (scope `ops:migration-import`), áp RLS và kiểm tra nghiệp vụ của đích |
| 6.8-e | Báo cáo đối chiếu | NB | Không chứa giá trị, chỉ số lượng và tổng kiểm tra |
| 6.8-f, g | Sự kiện giai đoạn song song | Theo hợp đồng | Subscription Failover riêng, chống trùng theo `id` |

: Chặng của luồng di trú từ hệ cũ

Điểm kiểm soát: (1) quét kết quả di trú không có trường thông tin xác thực; (2) báo cáo đối chiếu số lượng và tổng kiểm tra từng loại đạt trước cắt chuyển; (3) giao dịch thanh toán lịch sử mang nguồn chuyển `MIGRATION` và không phát webhook lại cho đối tác.

## 7. Ma trận nhóm dữ liệu

Hai ma trận dưới giúp trả lời nhanh hai câu hỏi thường gặp khi thẩm định: phân hệ nào xử lý nhóm dữ liệu nào, và nhóm nào đi qua ranh giới vùng mạng nào.

### 7.1. Phân hệ và nhóm dữ liệu

Ký hiệu: **L** phân hệ lưu lại nhóm dữ liệu đó; **Q** chỉ cho đi qua hoặc xử lý trong bộ nhớ; **—** không xử lý.

| PH | CK | NB | CN1 | CN2 | TC |
|---|---|---|---|---|---|
| PH-01 Kết nạp HTTT | — | L | L | — | — |
| PH-02 Danh mục dịch vụ | L | L | L (đầu mối dịch vụ) | — | — |
| PH-03 Cổng API | — | L | Q | Q | Q |
| PH-04 Lõi tích hợp | — | L | Q | Q | Q |
| PH-05 Bộ điều hợp | — | L | Q | Q | Q |
| PH-06 Dữ liệu chủ | — | L | L | L | — |
| PH-07 Danh mục dùng chung | L | L | L (danh mục có thuộc tính cá nhân) | — | — |
| PH-08 Chất lượng dữ liệu | — | L | Q (lưu đã che) | Q (lưu băm) | — |
| PH-09 Quyền riêng tư | — | L | L (yêu cầu chủ thể) | Q | — |
| PH-10 Sự kiện | — | L | Q | Q | Q |
| PH-11 Quy trình liên thông | — | L | L | L | — |
| PH-12 Định danh, phân quyền | — | L | L (tài khoản cán bộ) | — | — |
| PH-13 Giám sát, kiểm toán | — | L | L (định danh người thao tác) | Băm | — |
| PH-14 Kết nối quốc gia | — | L | L (đệm, mã hóa) | L (nội dung giao dịch, mã hóa, ≤ 180 ngày) | — |
| PH-15 Cổng nhà phát triển | L | L | L (tài khoản nhà phát triển) | — | — |
| PH-16 Báo cáo chỉ tiêu | L | L | — | — | — |
| PH-17 Trợ lý AI | L | L | — | — | — |
| PH-18 Vận hành, xử lý lỗi | — | L | L (DLQ) | L (DLQ, ≤ 7 ngày) | L (DLQ) |
| PH-19 Thanh toán | — | L | L | L (tài khoản hoàn tiền) | L |
| PH-20 Quản trị tenant | — | L | L (đầu mối tỉnh) | — | — |

: Phân hệ và nhóm dữ liệu được lưu lại hoặc chỉ đi qua

Ma trận cho thấy năm phân hệ lưu CN2 ở dạng giải mã được (PH-06, PH-11, PH-14, PH-18, PH-19) cộng PH-13 lưu băm; đây là các phân hệ cần DPIA riêng và cần bộ ca kiểm thử che dữ liệu đầy đủ ở D05-02.

### 7.2. Nhóm dữ liệu qua ranh giới vùng mạng

Ma trận dưới dùng tám vùng tin cậy của D03-07 §3.3; ô "—" nghĩa là nhóm đó không được phép đi qua ranh giới.

| Ranh giới | CK | NB | CN1 | CN2 | TC | Kiểm soát |
|---|---|---|---|---|---|---|
| Z0 → Z1 (vào biên) | Có | Có | Có | Có | Có | WAF, TLS 1.3 |
| Z1 → Z2 (vào cổng) | Có | Có | Có | Có | Có | Token, mTLS theo mức hợp đồng |
| Z2 → Z3, Z4 | Có | Có | Có | Có | Có | mTLS mesh, OPA |
| Z3, Z4 → Z5 (vào kho) | Có | Có | Có | Mã hóa trường | Có | Service account được liệt kê, RLS |
| Z3, Z4 → Z6 | — | Có | — | — | Có (WORM) | Yêu cầu khóa, ký; ghi bản ghi kiểm toán và sổ giao dịch vào WORM; không dữ liệu nghiệp vụ khác |
| Z4 → Z0 (egress) | Có | Có (nhật ký an ninh, thư) | Có | Có (NDXP) | Có (NCC) | Egress gateway, danh sách đích; cấm đích ngoài lãnh thổ |
| Z5 → site DR, sao lưu ngoài site | Có | Có | Có | Mã hóa | Có | Mã hóa trước khi rời site |
| Z3 → mô hình AI | Có | Có | Chỉ khi tenant bật và mô hình nội bộ | — | — | APISIX ai-proxy, bộ lọc lời nhắc |

: Nhóm dữ liệu được phép đi qua từng ranh giới vùng mạng

## 8. Thực thi và kiểm chứng phân loại

Phân loại chỉ có giá trị khi được thực thi bằng máy và kiểm chứng định kỳ. Bảng dưới nêu nơi thực thi và cách kiểm chứng cho từng khâu; tiêu chí đo lấy từ D03-07 và các FRS.

| Khâu | Thực thi | Kiểm chứng | Tiêu chí |
|---|---|---|---|
| Khai báo trường | `@Classified` trên thực thể, `x-dh-classification` trong OpenAPI, JSON Schema | CI lint: trường không có nhãn làm đỏ cổng | 100% trường của API công bố có nhãn |
| Xác nhận nhãn | PH-09 `PROPOSED` → `CONFIRMED` | Báo cáo trường chưa xác nhận hằng tuần | 0 trường `PROPOSED` quá 14 ngày ở hợp đồng `ACTIVE` |
| Mã hóa trường CN2 | Thư viện `dh-crypto`, ADR-032 | Quét CSDL tìm mẫu số định danh rõ | 0 kết quả (SEC-31) |
| Log, trace | Che ba lớp SEC-32 | Quét mẫu hằng ngày trên Loki | 0 giá trị Nhạy cảm (NFR-00-029) |
| Đệm | PH-14 chặn đệm Nhạy cảm; khóa có tiền tố tenant | Quét mẫu Valkey theo lịch | 0 giá trị Nhạy cảm rõ |
| Ủy quyền theo mục đích | OPA kiểm `purpose` | Ca kiểm thử âm ở D05-02 PH-09, PH-14 | 100% hợp đồng Nhạy cảm có chấp thuận trước khi kích hoạt (SEC-37) |
| DLQ | Mã hóa, hạn 7 ngày | Tác vụ dọn báo cáo hằng ngày | 0 mục Nhạy cảm quá 7 ngày |
| Trợ lý AI | Bộ lập chỉ mục chặn nguồn ≥ Hạn chế; bộ lọc lời nhắc | Ca kiểm thử tiêm lệnh, rò rỉ ở D05-02 PH-17 | 0 đoạn chỉ mục từ nguồn Nhạy cảm |
| Egress | Danh sách đích ở egress gateway | Hubble ghi luồng bị chặn | 0 kết nối ra đích ngoài danh sách |
| Môi trường DEV, TEST | Chỉ dữ liệu sinh với CN2 | Quét mẫu cơ sở dữ liệu TEST | 0 số định danh hợp lệ thật |

: Nơi thực thi và cách kiểm chứng phân loại theo khâu

DFD trong tài liệu này phải được rà lại khi thêm phân hệ, thêm giao diện ngoài hoặc thêm kho; mỗi lần đổi, cập nhật chương 5 và ma trận chương 7 trước khi đổi thiết kế ATTT.

## 9. Giả định, câu hỏi mở và đề nghị đồng bộ

### 9.1. Giả định

Thiếu số liệu thật về khối lượng và loại dữ liệu của tỉnh thí điểm, tài liệu dùng các giả định sau.

| Mã | Giả định | Cơ sở |
|---|---|---|
| GĐ-DFD-01 | Tỉnh thí điểm T01 xử lý DLCN của trên 100.000 chủ thể cơ bản và trên 10.000 chủ thể nhạy cảm, nên áp ngưỡng cấp độ 3 của NĐ 331/2026 | Quy mô tỉnh vừa (GĐ-01…07 ở D02-01), tra cứu dân cư và lý lịch tư pháp phục vụ TTHC |
| GĐ-DFD-02 | Datahub không nhận số thẻ hoặc thông tin đăng nhập ngân hàng của người nộp | Mô hình chuyển hướng tới trang NCC của PH-19 |
| GĐ-DFD-03 | HTTT của tỉnh khai mức hợp đồng trung thực; PH-09 quét gợi ý để phát hiện khai thiếu | FR-09-005, FR-09-006 |

: Giả định của DFD và phân loại dữ liệu

### 9.2. Câu hỏi mở

> **Câu hỏi mở Q375:** Trường mới chưa được xác nhận nhãn (`PROPOSED`) có nên được xử lý như mức Hạn chế theo mặc định không? Đề xuất: có, để an toàn mặc định; cần PH-09 bổ sung quy tắc.

> **Câu hỏi mở Q376:** Nghị định 356/2025 có miễn trừ hoặc đơn giản hóa hồ sơ DPIA cho cơ quan nhà nước xử lý DLCN khi thực hiện nhiệm vụ theo luật không? Chưa đối chiếu toàn văn.

> **Câu hỏi mở Q377:** Số định danh cá nhân là DLCN cơ bản về pháp lý nhưng được xếp mức Nhạy cảm về kỹ thuật. Có cần ghi rõ quyết định này vào sổ xử lý PH-09 để giải trình khi kiểm tra không?

> **Câu hỏi mở Q378:** Thời hạn giữ nội dung giao dịch quốc gia (`dh-nat-payload`) nên đặt bao nhiêu ngày cho từng loại dịch vụ? PH-14 cho mặc định 30 ngày, tối đa 180; cần chủ quản dữ liệu chốt con số và ghi vào sổ xử lý PH-09.

| Mã | Câu hỏi | Người trả lời |
|---|---|---|
| Q375 | Xử lý mặc định trường chưa xác nhận nhãn | Kiến trúc sư ATTT, nhóm PH-09 |
| Q376 | Miễn trừ DPIA theo NĐ 356/2025 | Pháp chế |
| Q377 | Ghi quyết định mức của số định danh | Cán bộ ATTT, chủ quản dữ liệu |
| Q378 | Thời hạn giữ nội dung giao dịch quốc gia | Chủ quản dữ liệu |

: Câu hỏi mở của D02-06

### 9.3. Đề nghị đồng bộ

Các điểm sau gom vào đợt đồng bộ cuối:

1. D03-01 §8.2 và D03-07 §3.2: thêm dẫn chiếu tới bảng 2.1 (năm nhóm sang bốn mức) để hai trục phân loại nhất quán.
2. D00-01 §3.1: thêm mã `DS-nn` (kho dữ liệu) với tài liệu gốc D02-06; thêm viết tắt nhóm CK, NB, CN1, CN2, TC.
3. D00-04 §3.1: dải câu hỏi mở Q375–Q379 cho D02-06; giả định GĐ-DFD-01…03.
4. D03-07 §3.1: AS-03 ghi "Hạn chế (tối đa)" cho DU AI; khớp với DS-08 ở đây là "Nội bộ, trần Hạn chế" vì chỉ mục chỉ nhận CK, NB khi tenant chưa bật mô hình nội bộ.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: phân loại năm nhóm, DFD mức 0, mức 1 tổng thể và sáu miền, mười chín kho, tám luồng mức 2, ma trận và kiểm chứng |
