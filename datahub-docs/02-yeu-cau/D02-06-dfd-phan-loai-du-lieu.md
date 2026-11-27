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
2. **Datahub chủ yếu là đường ống.** Phần lớn dữ liệu cá nhân chỉ **đi qua** (tra cứu, sự kiện) và không được lưu, trừ hàng đợi lỗi có mã hóa, giữ tối đa 7 ngày. Dữ liệu cá nhân **lưu lại** tập trung ở năm nơi: dữ liệu chủ PH-06, quyền riêng tư PH-09, quy trình PH-11, thanh toán PH-19 và nhật ký kiểm toán (chỉ dạng băm).
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

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D02-02 | SRS | Giao diện ngoài IF-01…IF-09 |
| D02-07 | Từ điển dữ liệu | DD-08 mức phân loại, DD-09 phân loại trường |
| D03-01 | SAD | Đơn vị triển khai, cụm CSDL, bốn mức bảo vệ, dữ liệu đi qua và lưu lại |
| D03-07 | Thiết kế ATTT | Tài sản AS-01…AS-20, vùng Z0…Z7, quy tắc xử lý theo mức, SEC-30…39 |
| D03-03-PH01…PH20 | CSDL phân hệ | Schema, bucket, khóa mã hóa |
| D02-03-PH09 | FRS Quyền riêng tư | Enum `DataClass`, `PersonalDataType`, `PersonalDataCategory` |
| ADR-032, 041, 047, 053, 057, 073, 181, 182, 183 | Quyết định kiến trúc | Mã hóa trường, lũy đẳng, phân vùng, ảnh chụp danh mục, đồng bộ quốc gia, cầu nối Pulsar, DLQ, phát lại, di trú |

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

Ngoài năm nhóm nghiệp vụ, vật liệu khóa và bí mật (khóa ký, khóa mã hóa, mật khẩu kết nối, thông tin xác thực của HTTT) mang nhãn kỹ thuật **BM** ("tối mật kỹ thuật" ở D03-07 §3.1). Nhãn BM chỉ xuất hiện ở OpenBao (DS-14) và ở chặng bàn giao thông tin xác thực một lần của luồng kết nạp (mục 6.7).

### 2.2. Căn cứ pháp lý của từng nhóm

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

Sơ đồ ngữ cảnh coi Datahub là một tiến trình duy nhất và chỉ vẽ dữ liệu trao đổi với chín giao diện ngoài của SRS cùng ba nhóm người dùng. Mỗi luồng mang nhãn nhóm dữ liệu cao nhất có thể đi trên nó.

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
  IF02 <-->|"DF-04 dữ liệu nguồn · theo hợp đồng"| DH
  IF03 <-->|"DF-05 tra cứu quốc gia · CN2"| DH
  IF04 -->|"DF-06 danh mục quốc gia · CK"| DH
  IF05 <-->|"DF-07 giao dịch, IPN, đối soát · TC"| DH
  IF06 -->|"DF-08 định danh công dân · CN1"| DH
  IF07 -->|"DF-09 dữ liệu di trú · CN1, TC"| DH
  DH -->|"DF-10 nhật ký an ninh · NB"| IF08
  DH -->|"DF-11 liên kết thông báo · NB"| IF09
```

Người đọc cần thấy ba điều ở hình. Thứ nhất, chỉ bốn luồng (DF-01, DF-05, DF-07, DF-09) chắc chắn mang dữ liệu cá nhân hoặc tài chính do Datahub chủ động xử lý; hai luồng DF-03, DF-04 mang dữ liệu "theo hợp đồng", tức Datahub chỉ chuyển tiếp và áp biện pháp theo mức của hợp đồng. Thứ hai, luồng ra IF-08 và IF-09 chỉ mang dữ liệu nội bộ: nhật ký an ninh đã che và thư chỉ chứa liên kết (FR-00-062). Thứ ba, DF-02 là luồng duy nhất ra ngoài mang nhãn BM, vì nhà phát triển tự lấy thông tin xác thực của ứng dụng ở cổng PH-15; chặng này có bảo vệ riêng ở mục 6.7.

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

Sơ đồ chỉ vẽ luồng giữa miền với nhau và với kho; luồng ra thực thể ngoài đã có ở mức 0.

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
  P2 -->|"tra cứu danh mục · CK"| P3
  P3 -->|"chính sách che, mục đích · NB"| P2
  P4 -->|"vai trò, chính sách · NB"| P1
  P1 & P2 & P3 & P5 -->|"bản ghi kiểm toán · NB, băm CN"| A
  P4 <-->|"xử lý lại · đến CN2"| D
  P1 & P2 & P3 & P4 -->|"mô tả dịch vụ, nhật ký đã che · CK, NB"| P6
```

Hình làm rõ ba điều. Thứ nhất, Kafka (DS-09) là trục nối các miền, nên mức của topic quyết định mức của mọi miền tiêu thụ nó. Thứ hai, chỉ miền 2.0 và 4.0 chạm vào DLQ, là kho duy nhất có thể chứa bản sao dữ liệu đi qua. Thứ ba, mọi mũi tên vào 6.0 chỉ mang CK hoặc NB: trợ lý AI chỉ được lập chỉ mục mô tả dịch vụ, tài liệu và nhật ký đã che (SEC-49).

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
  DS11[("DS-11 Garage<br/>nat-evidence")]
  DS19[("DS-19 DLQ")]
  SRC <-->|"bản ghi, tệp · theo hợp đồng"| P22
  P22 <-->|"bản tin chuẩn · theo hợp đồng"| P21
  P21 <-->|"sự kiện · theo hợp đồng"| P23
  P23 <--> DS09
  P23 -->|"lược đồ · NB"| DS10
  P21 <-->|"yêu cầu, kết quả · CN2"| P24
  P24 <-->|"bản tin ký số · CN2"| QG
  P24 -->|"đệm kết quả · đến CN1, mã hóa"| DS13
  P24 -->|"bằng chứng giao dịch · CN2, mã hóa"| DS11
  P21 & P22 & P24 -->|"cấu hình, siêu dữ liệu · NB"| DS02
  P21 & P23 -->|"bản tin lỗi · theo hợp đồng"| DS19
```

Hai chặng đáng chú ý. PH-14 chỉ đệm phản hồi đến mức Hạn chế và mã hóa giá trị bằng khóa tenant trước khi vào Valkey; phản hồi mức Nhạy cảm không bao giờ vào đệm (FR-14-035). Bằng chứng giao dịch quốc gia (FR-14-051) là bản tin đã ký, được lưu mã hóa ở bucket `dh-{tenant}-nat-evidence` để phục vụ đối soát và khiếu nại; xem nội dung đầy đủ cần lý do và ghi kiểm toán (FR-14-050).

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
  DS11[("DS-11 Garage<br/>rdm, mdm-pii, dq")]
  DS13[("DS-13 Valkey<br/>đệm danh mục")]
  DS14[("DS-14 OpenBao<br/>khóa pii, hmac")]
  QG -->|"danh mục · CK"| P31
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

PH-08 đọc dữ liệu mẫu để đo chất lượng nhưng chỉ lưu kết quả đã che và băm có khóa (bucket `dh-{tenant}-dq-hmac`), không lưu giá trị gốc. PH-09 không lưu dữ liệu nghiệp vụ của chủ thể; nó lưu siêu dữ liệu phân loại và hồ sơ yêu cầu của chủ thể (CN1: thông tin liên hệ của người yêu cầu).

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
```

PH-11 là nơi dữ liệu hồ sơ thủ tục có thể vào biến quy trình; các biến gắn nhãn Nhạy cảm được mã hóa trường và lưu ở bucket `dh-{tenant}-bpm-pii` khi lớn. PH-12 không giữ mật khẩu ngoài Keycloak (DS-07). PH-13 chỉ ghi băm có khóa của khóa nghiệp vụ nhạy cảm (`object_key_hmac`), không ghi giá trị (D03-07 §7).

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

Hai lớp chặn: (1) bộ lập chỉ mục từ chối nguồn mang nhãn Hạn chế trở lên trừ khi tenant bật và mô hình chạy nội bộ (ADR-170, ADR-171); (2) câu hỏi của người dùng đi qua bộ lọc phát hiện mẫu số định danh, số điện thoại, số thẻ trước khi gửi mô hình (ADR-173). Công cụ đọc dữ liệu thật của trợ lý dùng token của chính người dùng, chỉ đọc (ADR-172), nên không vượt quyền của người hỏi.

## 5. Danh mục kho dữ liệu và phân loại

Bảng dưới là danh mục 19 kho dữ liệu, mỗi kho gắn tài sản ở D03-07 §3.1, nhóm dữ liệu chứa, mức cao nhất và biện pháp chính. Cột "CN2 giải mã được" cho biết kho có chứa DLCN nhạy cảm ở dạng mà một người có khóa giải mã đọc được hay không; đây là danh sách kho cần ưu tiên khi đánh giá tác động và khi xử lý sự cố lộ lọt.

| Mã | Kho | Tài sản | Phân hệ | Nhóm chứa | Mức cao nhất | CN2 giải mã được | Biện pháp chính |
|---|---|---|---|---|---|---|---|
| DS-01 | pg-core: `ph01_onboarding`, `ph02_catalog`, `ph03_gateway`, `ph15_portal` | AS-06 | PH-01, 02, 03, 15 | CK, NB, CN1 | Hạn chế | Không | Mã hóa volume, RLS tenant |
| DS-02 | pg-core: `ph04`, `ph05_adapter`, `ph10_event`, `ph14_national` | AS-06 | PH-04, 05, 10, 14 | NB, CN1 (siêu dữ liệu giao dịch quốc gia) | Hạn chế | Không | Mã hóa volume, RLS; không lưu thân bản tin |
| DS-03 | pg-core: `ph06_mdm`, `ph07_rdm`, `ph08_dq`, `ph09_privacy` | AS-06 | PH-06, 07, 08, 09 | CK, NB, CN1, CN2 | Nhạy cảm | Có (bản ghi vàng PH-06) | Mã hóa trường ADR-032, HMAC tìm kiếm, RLS |
| DS-04 | pg-core: `ph11_bpm`, `ph12_iam`, `ph16_kpi`, `ph18_ops`, `ph20_tenant` | AS-06 | PH-11, 12, 16, 18, 20 | NB, CN1, CN2 (biến quy trình) | Nhạy cảm | Có (biến quy trình PH-11) | Mã hóa trường, RLS |
| DS-05 | pg-core: `ph13_audit.audit_event` | AS-16 | PH-13 | NB, băm CN | Hạn chế | Không | Chuỗi băm, không ghi giá trị Nhạy cảm |
| DS-06 | pg-payment: `ph19_payment` | AS-02 | PH-19 | TC, CN1, CN2 (tài khoản hoàn tiền) | Nhạy cảm | Có | Mã hóa trường ADR-048, phân vùng tháng ADR-047, cụm riêng TPH-0 |
| DS-07 | pg-iam: realm Keycloak | AS-10 | PH-12 | CN1 (tài khoản cán bộ), BM (băm mật khẩu, bí mật TOTP) | Hạn chế | Không | Cụm riêng TPH-0, Z6 |
| DS-08 | pg-core: `ph17_assist` (pgvector) | AS-03 | PH-17 | CK, NB | Nội bộ, trần Hạn chế | Không | RLS theo tenant, cấm nguồn Nhạy cảm |
| DS-09 | Kafka: topic `{tenant}.*` | AS-04 | PH-10 và mọi DU | Theo hợp đồng, tới CN2 | Nhạy cảm | Có (thân bản tin topic Nhạy cảm, mã hóa ở tầng ứng dụng) | ACL theo topic, mã hóa thân bản tin topic Nhạy cảm, thời hạn giữ theo topic |
| DS-10 | Apicurio (pg-infra) | AS-04 | PH-10 | NB | Nội bộ | Không | Lược đồ, không dữ liệu |
| DS-11 | Garage: bucket `dh-{tenant}-*` | AS-07 | Mọi phân hệ có tệp | CK, CN1, CN2, TC | Nhạy cảm | Có (tệp nhập tạm, mdm-pii, bpm-pii, nat-evidence) | SSE-C với khóa từ OpenBao cho bucket ≥ Hạn chế; tệp nhập tạm ≤ 24 giờ |
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

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: phân loại năm nhóm, DFD mức 0, mức 1 tổng thể và sáu miền, mười chín kho, tám luồng mức 2, ma trận và kiểm chứng |
