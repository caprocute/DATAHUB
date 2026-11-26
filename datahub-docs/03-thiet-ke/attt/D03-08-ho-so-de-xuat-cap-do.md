---
ma_tai_lieu: D03-08
ten: Hồ sơ đề xuất cấp độ và phương án bảo vệ (bản mẫu)
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Cơ quan chủ quản, Bộ phận chuyên trách an ninh mạng, Đơn vị thẩm định, Hội đồng thẩm định, Đơn vị vận hành, Nhà cung cấp nền tảng
mo_ta: Bản mẫu hồ sơ đề xuất cấp độ và phương án bảo vệ cho hệ thống Datahub theo Nghị định 331/2026/NĐ-CP, gồm thông tin chung, mô tả hệ thống, thuyết minh cấp độ 3, phương án bảo vệ, lộ trình cấp độ 4 và kế hoạch kiểm tra, để mỗi tỉnh hoặc nền tảng dùng chung điền và trình thẩm định.
tai_lieu_lien_quan: D03-07 Thiết kế ATTT; D03-09 Hạ tầng, triển khai, DR; D03-01 SAD; D03-10 Thiết kế đa tenant; D05-01 Kế hoạch kiểm thử tổng thể; D05-04 Kế hoạch kiểm thử bảo mật
---

# D03-08 · Hồ sơ đề xuất cấp độ và phương án bảo vệ (bản mẫu)

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu là bản mẫu hồ sơ đề xuất cấp độ an ninh mạng và phương án bảo vệ cho hệ thống thông tin Datahub. Mỗi tỉnh tự vận hành, hoặc đơn vị vận hành nền tảng dùng chung, sao bản mẫu, điền chỗ trống và trình thẩm định theo Nghị định 331/2026/NĐ-CP. Hồ sơ đề xuất **cấp độ 3** và chứng minh Datahub sẵn sàng nâng lên cấp độ 4 khi điều kiện kích hoạt xảy ra.

**Phạm vi.** Hai hồ sơ triển khai: `HT-A` (tỉnh độc lập tại trung tâm dữ liệu của tỉnh) và `HT-B` (nền tảng dùng chung trên cloud Chính phủ, kèm hồ sơ rút gọn cho từng tỉnh). Phần thiết kế kỹ thuật chi tiết không chép lại mà dẫn chiếu D03-07, D03-09, D05-01 và nộp kèm.

**Căn cứ pháp lý.** CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15); CMP-LAW-17 (Nghị định 331/2026/NĐ-CP, Điều 8, 25, 30, 31, 39); STD-06 (TCVN 14423:2026, chương 5 cho cấp độ 3, Phụ lục A cho hạ tầng vật lý); CMP-LAW-05 và CMP-LAW-18 (Luật BVDLCN 91/2025/QH15 và Nghị định 356/2025/NĐ-CP, căn cứ ước tính số chủ thể dữ liệu cá nhân); CMP-LAW-01 (Luật Dữ liệu 60/2024/QH15).

**Những điểm hội đồng cần lưu ý.** (1) Thành phần chính xác của hồ sơ theo Điều 25 và mẫu biểu kèm theo chưa đối chiếu toàn văn (Q320); cấu trúc bản mẫu theo thông lệ và sẽ chỉnh khi có văn bản. (2) Kết luận cấp độ 3 dựa chắc chắn vào ngưỡng số chủ thể dữ liệu cá nhân (TCD-01, TCD-02); với `HT-B` là đề xuất có điều kiện vì phạm vi liên tỉnh có thể đòi cấp độ 4 (Q323). (3) Datahub được xem là một hệ thống duy nhất, không chia nhỏ để hạ cấp (Điều 8). (4) Sáu yếu tố `CD4-nn` được theo dõi để đánh giá lại cấp độ. (5) Ba câu hỏi Q320, Q321, Q323 chặn việc trình hồ sơ và cần trả lời trước. (6) Số liệu quy mô trong bản mẫu là ước tính từ D03-09 và phải thay bằng số khảo sát của tỉnh trước khi trình.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Cấp độ đề xuất | 3 (`HT-A`); 3 có điều kiện (`HT-B`) |
| Tiêu chí xác định cấp độ được áp dụng | 7 (TCD-01…TCD-07) |
| Yếu tố có thể đẩy lên cấp độ 4 | 6 (CD4-01…06) |
| Trường thông tin cần điền | 23 trường `TT-nn` ở Phụ lục C (TT-01…TT-52) |
| Câu hỏi mở | 10 trong dải Q320…Q329, ba câu chặn trình hồ sơ |
| Hồ sơ triển khai | 2 (`HT-A`, `HT-B`) |

: Con số chính của bản mẫu hồ sơ đề xuất cấp độ

## 1. Mục đích và cách dùng bản mẫu

### 1.1. Mục đích

Tài liệu này là **bản mẫu** của hồ sơ đề xuất cấp độ an ninh mạng cho hệ thống thông tin Datahub (nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh, thế hệ kế tiếp của LGSP). Mỗi lần triển khai — cho một tỉnh tự vận hành tại Trung tâm dữ liệu (TTDL) tỉnh, hoặc cho nền tảng dùng chung trên cloud Chính phủ — đơn vị lập hồ sơ sao bản mẫu, điền các chỗ trống trong ngoặc vuông, bỏ những đoạn không áp dụng cho hồ sơ triển khai của mình, rồi trình thẩm định theo Nghị định 331/2026/NĐ-CP về bảo vệ an ninh mạng đối với hệ thống thông tin.

Hồ sơ trả lời ba câu hỏi mà đơn vị thẩm định cần: hệ thống là gì, xử lý dữ liệu gì và ở quy mô nào (mục 3, 4); vì sao hệ thống thuộc cấp độ được đề xuất và không thuộc cấp độ khác (mục 5); và chủ quản bảo vệ hệ thống bằng cách nào, kiểm chứng ra sao trước khi đưa vào vận hành (mục 6, 7, 8). Phần thiết kế kỹ thuật chi tiết không chép lại ở đây mà dẫn chiếu tới thiết kế an toàn thông tin D03-07 (danh mục biện pháp `SEC-nn` và ma trận tuân thủ mục 11), thiết kế hạ tầng D03-09 và kế hoạch kiểm thử D05-01, D05-04. Các tài liệu đó được nộp kèm như thành phần của hồ sơ.

### 1.2. Thành phần hồ sơ

Thành phần chính xác của "Hồ sơ đề xuất cấp độ và phương án bảo vệ" theo Điều 25 Nghị định 331/2026 và các mẫu biểu kèm theo **chưa được đối chiếu toàn văn**. Bản mẫu này dựng theo cấu trúc thông lệ của hồ sơ cấp độ trong khung cũ (Nghị định 85/2016 và Thông tư 12/2022/TT-BTTTT), gồm ba khối: văn bản đề nghị thẩm định; thuyết minh đề xuất cấp độ; phương án bảo vệ. Khi có mẫu biểu chính thức, đơn vị lập hồ sơ chuyển nội dung tương ứng sang mẫu, giữ nguyên lập luận. Bảng dưới đây liệt kê các thành phần dự kiến, mục tương ứng trong bản mẫu và tài liệu nộp kèm.

| STT | Thành phần dự kiến | Nội dung | Vị trí trong bản mẫu | Tài liệu nộp kèm |
|---|---|---|---|---|
| 1 | Văn bản (tờ trình) đề nghị thẩm định cấp độ | Đề nghị của đơn vị vận hành hoặc chủ quản gửi đơn vị thẩm định | Mục 2 | — |
| 2 | Thuyết minh đề xuất cấp độ | Thông tin chung, mô tả hệ thống, quy mô dữ liệu, lập luận theo tiêu chí | Mục 3, 4, 5 | D03-01 SAD |
| 3 | Phương án bảo vệ | Biện pháp quản lý và kỹ thuật theo nhóm yêu cầu TCVN 14423:2026 cấp độ 3 | Mục 6 | D03-07 (mục 5, 11, 12), D03-09 |
| 4 | Lộ trình đáp ứng cấp độ cao hơn | Điểm chờ và điều kiện nâng cấp | Mục 7 | D03-07 mục 10 |
| 5 | Kế hoạch kiểm tra, đánh giá trước vận hành | Phạm vi, phương pháp, bằng chứng | Mục 8 | D05-01, D05-04 |
| 6 | Thuyết minh chuyển tiếp | Quan hệ với hồ sơ cấp độ của LGSP cũ | Mục 9 | — |
| 7 | Phụ lục | Danh mục tài sản, văn bản viện dẫn, bảng điền thông tin | Phụ lục A, B, C | — |

: Thành phần hồ sơ

> **Câu hỏi mở Q320:** Điều 25 Nghị định 331/2026/NĐ-CP và mẫu biểu kèm theo (hoặc thông tư hướng dẫn của Bộ Công an, nếu có) quy định chính xác thành phần "Hồ sơ đề xuất cấp độ và phương án bảo vệ" gồm những tài liệu nào, theo mẫu nào, nộp bản giấy hay điện tử, số bộ? Bản mẫu này phải được chuyển sang mẫu chính thức khi có câu trả lời; cấu trúc ba khối ở bảng trên là giả định theo thông lệ khung cũ.

### 1.3. Hai hồ sơ triển khai, hai loại hồ sơ cấp độ

Datahub có một bộ mã nhưng hai cách đặt lên hạ tầng (D03-09 mục 3, ADR-036), và mỗi cách dẫn tới một loại hồ sơ cấp độ khác nhau về chủ thể và phạm vi. Bảng dưới đây giúp đơn vị lập hồ sơ chọn đúng nhánh trước khi điền.

| Khía cạnh | Hồ sơ `HT-A`: tỉnh độc lập on-prem | Hồ sơ `HT-B`: nền tảng dùng chung trên cloud Chính phủ |
|---|---|---|
| Hệ thống được xác định cấp độ | "Nền tảng tích hợp, chia sẻ dữ liệu tỉnh [Tên tỉnh]" — toàn bộ cụm Datahub tại TTDL tỉnh và site DR | (1) "Nền tảng Datahub dùng chung" — toàn bộ nền tảng phục vụ mọi tỉnh; (2) phần sử dụng của từng tỉnh, xem mục 5.6 |
| Chủ quản | [Cơ quan chủ quản] của tỉnh (UBND tỉnh hoặc cơ quan được giao) | Nền tảng: [Chủ quản nền tảng] (chưa xác định, Q323); phần của tỉnh: [Cơ quan chủ quản] của tỉnh |
| Số bộ hồ sơ | Một bộ cho mỗi tỉnh | Một bộ cho nền tảng, cộng một hồ sơ rút gọn cho mỗi tỉnh tham gia |
| Hồ sơ quy mô dùng để ước tính (D03-09 §2.2) | `QM-NHO`, `QM-VUA` hoặc `QM-LON` | `QM-CHUNG` |
| Ai lập | Đơn vị vận hành của tỉnh, nhà cung cấp hỗ trợ | Đơn vị vận hành nền tảng; tỉnh lập phần của mình |

: Hai hồ sơ triển khai, hai loại hồ sơ cấp độ

Trong toàn bản mẫu, đoạn chỉ áp dụng cho một hồ sơ được mở đầu bằng nhãn **[HT-A]** hoặc **[HT-B]**; đoạn không có nhãn áp dụng cho cả hai.

### 1.4. Quy ước chỗ điền

Chỗ điền được viết trong ngoặc vuông, ví dụ `[Tên tỉnh]`, `[Cơ quan chủ quản]`, `[Số dân]`. Mỗi chỗ điền có một mã `TT-nn` (trường thông tin) tổng hợp ở Phụ lục C, kèm nguồn số liệu và người chịu trách nhiệm cung cấp. Số liệu ước tính trong bản mẫu (lấy từ hồ sơ quy mô D03-09) được đánh dấu "ước tính" và **phải được thay bằng số liệu khảo sát của tỉnh** trước khi trình; đơn vị thẩm định có quyền yêu cầu giải trình phương pháp tính. Bản mẫu không chứa địa chỉ IP, tên máy chủ hay bí mật thật; dải địa chỉ trong sơ đồ là ví dụ giả lập.

### 1.5. Người đọc và cách đọc

Bản mẫu có hai nhóm người dùng: người lập hồ sơ (điền, rút gọn, trình) và người thẩm định, phê duyệt (đọc để kết luận). Bảng dưới đây gợi ý từng nhóm đọc phần nào.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Đơn vị lập hồ sơ (đơn vị vận hành, nhà cung cấp) | Chương 1, Phụ lục C | Chọn nhánh `HT-A` hoặc `HT-B`, điền các trường `TT-nn`, bỏ đoạn không áp dụng |
| Cơ quan chủ quản | Chương 2, 5, 7 | Ký đề nghị, chấp nhận cấp độ, quyết định chấp nhận rủi ro và điều kiện nâng cấp |
| Bộ phận chuyên trách an ninh mạng | Chương 5, 6, 8 | Rà soát lập luận cấp độ, phương án bảo vệ và kế hoạch kiểm tra |
| Đơn vị thẩm định, hội đồng thẩm định | Tóm tắt, chương 3 đến 6, 13 | Kiểm tra hệ thống, quy mô dữ liệu, lý do cấp độ và các câu hỏi còn mở |
| Đơn vị vận hành, nhà cung cấp nền tảng | Chương 6, 8, 9 | Biết biện pháp phải triển khai và bằng chứng phải có trước vận hành |

: Người đọc và phần cần đọc của bản mẫu hồ sơ

### 1.6. Thuật ngữ và chữ viết tắt

Bảng dưới đây giải thích các thuật ngữ riêng của bản mẫu; thuật ngữ chung xem D00-01.

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| `HT-A`, `HT-B` | Hồ sơ triển khai tỉnh độc lập on-prem; hồ sơ nền tảng dùng chung trên cloud Chính phủ (mục 1.3) |
| `QM-NHO`, `QM-VUA`, `QM-LON`, `QM-CHUNG` | Hồ sơ quy mô dùng để ước tính tài nguyên và số chủ thể dữ liệu (D03-09 §2.2) |
| Chủ quản | Cơ quan, tổ chức chịu trách nhiệm cuối cùng về an ninh mạng của hệ thống, phê duyệt cấp độ |
| Bộ phận chuyên trách ANM | Đơn vị giúp chủ quản quản lý an ninh mạng, rà soát hồ sơ trước khi trình |
| TTDL | Trung tâm dữ liệu |
| DLCN | Dữ liệu cá nhân |
| `TCD-nn`, `CD4-nn`, `TT-nn` | Mã tiêu chí cấp độ, yếu tố có thể đẩy lên cấp độ 4, trường thông tin cần điền (mục 11) |
| Hồ sơ nền tảng, hồ sơ rút gọn của tỉnh | Hồ sơ cấp độ của nền tảng dùng chung; hồ sơ cho phần sử dụng của một tỉnh (mục 5.6) |
| Cổng `RG-4` | Cổng phát hành cuối trước vận hành chính thức (D05-01) |

: Thuật ngữ và chữ viết tắt của bản mẫu hồ sơ

### 1.7. Tài liệu tham chiếu

Bảng dưới đây liệt kê các tài liệu mà hồ sơ dẫn chiếu hoặc nộp kèm. Văn bản pháp lý đầy đủ ở Phụ lục B.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| CMP-LAW-17 | Nghị định 331/2026/NĐ-CP | Căn cứ chính: tiêu chí cấp độ, hồ sơ, thẩm định, phê duyệt |
| STD-06 | TCVN 14423:2026 | Yêu cầu cơ bản theo nhóm cho cấp độ 3 và 4 (chương 5 và 6) |
| D03-07 | Thiết kế an toàn thông tin | Nguồn của phương án bảo vệ: biện pháp `SEC-nn`, ma trận tuân thủ, lộ trình cấp độ 4 |
| D03-09 | Thiết kế hạ tầng, triển khai, DR | Sơ đồ vật lý, hồ sơ quy mô, sao lưu và khôi phục |
| D03-01 | Kiến trúc tổng thể (SAD) | Thuyết minh kiến trúc nộp kèm |
| D03-10 | Thiết kế đa tenant | Cách ly tenant của hồ sơ nền tảng |
| D05-01, D05-04 | Kế hoạch kiểm thử tổng thể (D05-01); kế hoạch kiểm thử bảo mật (D05-04, dự kiến Đợt 5) | Kế hoạch kiểm tra trước vận hành (mục 8) |
| D00-01 | Quy ước mã và thuật ngữ | Mã mới đề xuất ở mục 11 |

: Tài liệu tham chiếu của bản mẫu hồ sơ

### 1.8. Cấu trúc tài liệu

Cấu trúc bám thành phần hồ sơ ở mục 1.2. Bảng dưới đây cho biết nội dung từng chương và người đọc chính.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 1 | Mục đích, thành phần hồ sơ, hai hồ sơ triển khai, quy ước điền, cách đọc | Đơn vị lập hồ sơ |
| 2 | Văn bản đề nghị thẩm định (mẫu văn bản hành chính) | Chủ quản, đơn vị thẩm định |
| 3 | Thông tin chung về hệ thống, vai trò các bên | Đơn vị thẩm định |
| 4 | Mô tả hệ thống: kiến trúc, sơ đồ vật lý, thành phần, kết nối, dữ liệu | Đơn vị thẩm định, chuyên trách ANM |
| 5 | Thuyết minh đề xuất cấp độ, trình tự thẩm định và phê duyệt | Hội đồng thẩm định, chủ quản |
| 6 | Phương án bảo vệ theo nhóm yêu cầu | Chuyên trách ANM, vận hành |
| 7 | Lộ trình đáp ứng cấp độ 4 | Chủ quản |
| 8 | Kế hoạch kiểm tra, đánh giá trước vận hành | Chuyên trách ANM, vận hành |
| 9 | Chuyển tiếp từ LGSP cũ | Chủ quản, thẩm định |
| 10 | Phụ lục A, B, C: tài sản, văn bản viện dẫn, bảng điền | Đơn vị lập hồ sơ |
| 11 đến 13 | Mã mới, truy vết, câu hỏi mở | Người điều phối tài liệu, hội đồng |

: Cấu trúc tài liệu và người đọc chính của từng chương

## 2. Văn bản đề nghị thẩm định (mẫu)

Văn bản đề nghị là thành phần đầu tiên của hồ sơ. Nội dung dưới đây là khung để đơn vị lập hồ sơ chuyển sang thể thức văn bản hành chính của cơ quan; thể thức, số hiệu và người ký theo quy định về công tác văn thư.

> **[Tên cơ quan đề nghị]** — Số: [Số văn bản] — [Địa danh], ngày [ngày] tháng [tháng] năm [năm]
>
> **V/v đề nghị thẩm định hồ sơ đề xuất cấp độ hệ thống thông tin "[Tên hệ thống]"**
>
> Kính gửi: [Đơn vị thẩm định].
>
> Căn cứ Luật An ninh mạng số 116/2025/QH15; Nghị định số 331/2026/NĐ-CP về bảo vệ an ninh mạng đối với hệ thống thông tin; TCVN 14423:2026 An ninh mạng – Hệ thống thông tin – Yêu cầu cơ bản; [Quyết định phê duyệt dự án/nhiệm vụ đầu tư số …];
>
> [Tên cơ quan đề nghị] đã xây dựng hồ sơ đề xuất cấp độ cho hệ thống thông tin "[Tên hệ thống]", do [Cơ quan chủ quản] là chủ quản, [Đơn vị vận hành] là đơn vị vận hành. Hệ thống là nền tảng tích hợp, chia sẻ dữ liệu của [Tên tỉnh / các tỉnh sử dụng nền tảng], kết nối [số HTTT] hệ thống thông tin của các sở, ngành, địa phương với nhau và với Nền tảng chia sẻ, điều phối dữ liệu quốc gia (NDXP), Nền tảng thanh toán trực tuyến (PayGov).
>
> Căn cứ tiêu chí tại Nghị định 331/2026/NĐ-CP, [Tên cơ quan đề nghị] đề xuất hệ thống ở **cấp độ 3**, với lý do chính là hệ thống xử lý dữ liệu cá nhân của [số ước tính] chủ thể dữ liệu cá nhân cơ bản và [số ước tính] chủ thể dữ liệu cá nhân nhạy cảm, vượt ngưỡng 100.000 và 10.000 chủ thể. Phương án bảo vệ được xây dựng theo yêu cầu cấp độ 3 của TCVN 14423:2026 và đã chừa sẵn điểm nâng lên cấp độ 4.
>
> Hồ sơ gửi kèm gồm: thuyết minh đề xuất cấp độ và phương án bảo vệ; thiết kế kiến trúc tổng thể; thiết kế an toàn thông tin; thiết kế hạ tầng, triển khai và khôi phục thảm họa; kế hoạch kiểm tra, đánh giá trước khi đưa vào vận hành; [ý kiến của bộ phận chuyên trách an ninh mạng, nếu mẫu yêu cầu].
>
> Đầu mối liên hệ: [Họ tên, chức vụ, điện thoại công vụ, thư điện tử công vụ].
>
> Đề nghị [Đơn vị thẩm định] xem xét, thẩm định./.

Đơn vị thẩm định và người phê duyệt phụ thuộc cấp độ. Theo kết quả tra cứu ban đầu, với cấp độ 3 thì chủ quản phê duyệt sau khi đơn vị chuyên trách về an ninh mạng thẩm định; với cấp độ 4 thì Bộ Công an chủ trì thẩm định. Phân công này chưa được đối chiếu toàn văn Nghị định 331/2026, nên đơn vị lập hồ sơ phải xác nhận trước khi gửi (Q321). Với hồ sơ `HT-B`, nếu nền tảng được xác định cấp độ 4 (mục 5.5) thì văn bản gửi Bộ Công an.

> **Câu hỏi mở Q321:** Theo Nghị định 331/2026, ở cấp độ 3 ai thẩm định (bộ phận chuyên trách an ninh mạng của chủ quản, Công an tỉnh, hay đơn vị chuyên trách của Bộ Công an) và ai phê duyệt (người đứng đầu cơ quan chủ quản hay UBND tỉnh)? Thời hạn thẩm định là bao lâu? Câu trả lời quyết định ô "Kính gửi" và luồng trình ký.

## 3. Thông tin chung về hệ thống

### 3.1. Thông tin định danh

Bảng dưới đây là thông tin định danh hệ thống và các bên liên quan. Cột "Ví dụ/gợi ý" giúp người điền hiểu loại thông tin cần ghi; cột cuối cho biết khác biệt giữa hai hồ sơ.

| Mã | Trường | Ví dụ/gợi ý | Khác biệt `HT-A` / `HT-B` |
|---|---|---|---|
| TT-01 | Tên hệ thống | "Nền tảng tích hợp, chia sẻ dữ liệu tỉnh [Tên tỉnh] (Datahub)" | `HT-B`: "Nền tảng Datahub dùng chung" |
| TT-02 | Tên viết tắt, mã hệ thống | `DATAHUB-[MÃ TỈNH]` | `HT-B`: `DATAHUB-CHUNG` |
| TT-03 | Cơ quan chủ quản | [Cơ quan chủ quản], người đứng đầu là chủ quản theo Điều 31 Nghị định 331/2026 | `HT-B`: [Chủ quản nền tảng] |
| TT-04 | Đơn vị vận hành | [Đơn vị vận hành], thường là Trung tâm Chuyển đổi số / TTDL tỉnh | `HT-B`: [Đơn vị vận hành nền tảng] |
| TT-05 | Bộ phận chuyên trách an ninh mạng | [Bộ phận chuyên trách ANM] được chủ quản giao bằng quyết định | Cả hai; `HT-B` có thêm bộ phận chuyên trách của nền tảng |
| TT-06 | Nhà cung cấp nền tảng phần mềm | [Nhà cung cấp] | — |
| TT-07 | Bên cung cấp hạ tầng | `HT-A`: TTDL tỉnh [Tên TTDL]; site DR [Tên site DR] | `HT-B`: [Nhà cung cấp cloud Chính phủ], vùng chính và vùng DR |
| TT-08 | Đầu mối an ninh mạng 24/7 | [Họ tên, điện thoại công vụ, thư điện tử công vụ] | Cả hai |
| TT-09 | Văn bản phê duyệt đầu tư | [Số, ngày quyết định phê duyệt dự án hoặc thuê dịch vụ] | — |
| TT-10 | Thời điểm dự kiến vận hành chính thức | [T0 + n tháng], sau cổng `RG-4` của D05-01 | — |
| TT-11 | Hệ thống thay thế | LGSP hiện hành của [Tên tỉnh], số quyết định phê duyệt cấp độ (nếu có) [Số QĐ] | Xem mục 9 |

: Thông tin định danh

### 3.2. Vai trò các bên

Bốn bên chịu trách nhiệm an ninh mạng cho Datahub, theo mô hình trách nhiệm chia sẻ ở D03-07 mục 12. **Chủ quản** chịu trách nhiệm cuối cùng: phê duyệt cấp độ, ban hành quy chế, bố trí bộ phận chuyên trách, chấp nhận rủi ro tồn dư và thực hiện nghĩa vụ thông báo. **Đơn vị vận hành** vận hành hằng ngày, giám sát và xử lý sự cố mức đầu. **Nhà cung cấp nền tảng** chịu trách nhiệm an toàn của phần mềm (vòng đời phát triển an toàn, bản vá, chuỗi cung ứng), và ở hồ sơ `HT-B` chịu thêm trách nhiệm vận hành an toàn toàn bộ phần nền tảng. **Bên cung cấp hạ tầng** chịu trách nhiệm an toàn vật lý, mạng nền, ảo hóa. Ranh giới giữa các bên được ghi trong hợp đồng, vì Điều 30 Nghị định 331/2026 cho phép hệ cấp độ 3–4 dùng chung hạ tầng cloud hoặc TTDL đạt yêu cầu và trách nhiệm phải phân định được khi kiểm tra.

**[HT-A]** Chủ quản và đơn vị vận hành thuộc cùng một tỉnh; nhà cung cấp hỗ trợ theo hợp đồng bảo trì; TTDL tỉnh là bên cung cấp hạ tầng. Bộ phận chuyên trách an ninh mạng của chủ quản thẩm định hồ sơ (nếu Q321 xác nhận) và kiểm tra định kỳ.

**[HT-B]** Có hai tầng chủ quản. Chủ quản nền tảng chịu trách nhiệm về toàn bộ nền tảng và hồ sơ cấp độ của nền tảng; chủ quản của mỗi tỉnh chịu trách nhiệm về phần cấu hình, người dùng, HTTT kết nối và dữ liệu trong tenant của tỉnh mình, và là bên kiểm soát dữ liệu cá nhân của tỉnh (D03-07 §6.2). Mục 5.6 trình bày cách hai tầng hồ sơ quan hệ với nhau.

## 4. Mô tả hệ thống

### 4.1. Mục tiêu

Datahub là điểm trung chuyển có kiểm soát cho mọi trao đổi dữ liệu giữa các hệ thống thông tin (HTTT) của [Tên tỉnh] với nhau và với các nền tảng quốc gia. Hệ thống phục vụ bốn mục tiêu nghiệp vụ được chủ đầu tư phê duyệt ở BRD (D02-01): mọi trao đổi dữ liệu đi qua một điểm có kiểm soát và có nhật ký (BO-01); dịch vụ công trực tuyến không gián đoạn vì nền tảng tích hợp, với độ sẵn sàng data plane ≥ 99,9% mỗi tháng (BO-02, NFR-00-010); tuân thủ pháp luật về dữ liệu và an ninh mạng, trong đó hồ sơ cấp độ được phê duyệt trước khi vận hành chính thức là chỉ tiêu KPI-08 (BO-04); và một nền tảng dùng chung được cho nhiều tỉnh để giảm chi phí triển khai lặp (BO-06). Hệ thống thay thế LGSP hiện hành theo cách thay dần (strangler), mỗi khối của hệ cũ được cắt chuyển khi khối thay thế đạt cổng `RG-5` (D05-01 §6.2).

### 4.2. Phạm vi và ranh giới hệ thống

Ranh giới hệ thống quyết định cái gì được xác định cấp độ cùng nhau và cái gì là hệ thống bên ngoài có hồ sơ riêng. Ranh giới được vạch theo nguyên tắc: mọi thành phần do chủ quản Datahub vận hành và cùng phục vụ chức năng tích hợp, chia sẻ dữ liệu đều nằm trong một HTTT duy nhất, kể cả các thành phần hỗ trợ (giám sát, sao lưu, chuỗi cung ứng). Nguyên tắc này đáp ứng yêu cầu cấm chia nhỏ hình thức để hạ cấp độ tại Điều 8 Nghị định 331/2026 (mục 5.2).

**Trong phạm vi** gồm 20 phân hệ PH-01…PH-20 đóng gói thành hai ứng dụng giao diện (`dh-console`, `dh-portal`), sáu đơn vị triển khai (DU) Spring Boot (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`, `dh-payment`, `dh-assist`), DU Camel Quarkus `dh-runtime`; các thành phần bên thứ ba chạy trên cùng cụm (APISIX kèm WAF Coraza, Kafka và Apicurio, PostgreSQL trên CloudNativePG, ClickHouse cho siêu dữ liệu lượt gọi, Garage, Valkey, Keycloak, OPA, OpenBao, bộ quan sát OpenTelemetry/Mimir/Loki/Tempo/Grafana); công cụ triển khai và chuỗi cung ứng (kho Git cấu hình, Argo CD, Harbor, đường ống CI/CD); hạ tầng cụm Kubernetes tại site chính và site DR; kho sao lưu và kho WORM; các cầu nối tạm với LGSP cũ trong giai đoạn chuyển đổi.

**Ngoài phạm vi** là các HTTT thành viên của sở, ngành, xã; NDXP và các CSDL quốc gia; PayGov và kênh thanh toán; VNeID; hệ thống giám sát an ninh mạng (SIEM/SOC) của tỉnh; bản thân LGSP cũ. Các hệ này có chủ quản và hồ sơ cấp độ riêng. Datahub xử lý ranh giới với chúng theo giả định chúng có thể bị xâm phạm (D03-07 §1.2): xác thực máy–máy, kiểm tra đầu vào, giới hạn đích ra ngoài. **[HT-B]** Hạ tầng cloud (phòng máy, mạng ảo, ảo hóa, lưu trữ khối) thuộc hồ sơ cấp độ của nhà cung cấp cloud; nền tảng Datahub kế thừa biện pháp của tầng này theo Điều 30 (Q329).

### 4.3. Người dùng

Người dùng của Datahub gồm người và hệ thống. Bảng dưới đây nêu nhóm người dùng, cách truy cập và số lượng ước tính theo hồ sơ quy mô của D03-09 §2.2; tỉnh thay bằng số liệu thực ở `TT-20`.

| Nhóm | Mô tả | Truy cập | `QM-NHO` | `QM-VUA` | `QM-LON` | `QM-CHUNG` |
|---|---|---|---|---|---|---|
| Quản trị nền tảng và quản trị tỉnh | Cấu hình tenant, người dùng, chính sách | `dh-console` qua mạng nội bộ/TSLCD, bắt buộc MFA (SEC-23) | ~10 | ~20 | ~40 | ~700 (34 tỉnh) + ~20 nền tảng |
| Cán bộ nghiệp vụ, người duyệt | Duyệt kết nạp, duyệt luồng, đối soát thanh toán, quản lý danh mục | `dh-console` | ~490 | ~1.980 | ~5.960 | ~69.000 |
| Kỹ sư tích hợp, nhà thầu HTTT | Đăng ký API, thử nghiệm, lấy thông tin xác thực | `dh-portal` (cổng nhà phát triển) | trong tổng trên | trong tổng trên | trong tổng trên | trong tổng trên |
| HTTT thành viên | Gọi API, nhận sự kiện, webhook | OAuth 2.1 `client_credentials` + mTLS hoặc `private_key_jwt` (SEC-24) | 50 | 200 | 500 | ~6.000 |
| Công dân (gián tiếp) | Trình duyệt chuyển hướng qua PayGov khi thanh toán | Không có tài khoản Datahub | — | — | — | — |
| Người dùng đồng thời trên giao diện | Cao điểm | — | 50 | 200 | 500 | 3.000 |

: Người dùng

Công dân không đăng nhập Datahub; dữ liệu của họ chỉ đi qua hoặc được lưu do HTTT khác gửi tới. Đây là điểm khác biệt quan trọng khi tính số chủ thể dữ liệu cá nhân ở mục 4.9: số tài khoản người dùng nhỏ, nhưng số chủ thể có dữ liệu được xử lý lớn hơn nhiều bậc.

### 4.4. Kiến trúc logic

Sơ đồ dưới đây là kiến trúc logic của Datahub, thể hiện các vùng tin cậy `Z0`…`Z7` (D03-07 §3.3) và các thành phần chính trong từng vùng. Mũi tên là chiều khởi tạo kết nối được phép.

```{.mermaid caption="Sơ đồ kiến trúc logic theo các vùng tin cậy Z0…Z7"}
flowchart TB
  subgraph Z0["Z0 Bên ngoài"]
    U["Cán bộ, kỹ sư tích hợp"]
    H["HTTT thành viên"]
    ND["NDXP, CSDL quốc gia"]
    PG["PayGov"]
  end
  subgraph Z1["Z1 Biên"]
    EG["APISIX biên + WAF"]
  end
  subgraph Z2["Z2 Cổng API"]
    AP["APISIX + OPA"]
    BFF["BFF console/portal"]
  end
  subgraph Z3["Z3 Control plane"]
    DU["6 DU Spring Boot<br/>PH-01…20"]
  end
  subgraph Z4["Z4 Data plane"]
    RT["dh-runtime<br/>PH-04, 05, 14"]
    EGW["Egress gateway"]
  end
  subgraph Z5["Z5 Dữ liệu"]
    DB[("PostgreSQL")]
    KF[("Kafka")]
    S3[("Garage")]
    CH[("ClickHouse")]
  end
  subgraph Z6["Z6 Bảo mật lõi"]
    KC["Keycloak"]
    BAO["OpenBao"]
    WORM[("Kho WORM")]
  end
  subgraph Z7["Z7 Quản trị"]
    PAM["Bastion / PAM"]
    ARGO["Argo CD, Harbor, Git"]
  end
  U & H & PG -->|443 TLS| EG --> AP & BFF
  AP --> DU & RT
  DU --> DB & KF & S3
  AP --> KF --> CH
  DU & RT --> BAO
  AP & BFF --> KC
  RT & DU --> EGW --> ND & PG
  DU -.-> WORM
  PAM --> ARGO --> DU & RT
```

Sơ đồ cho thấy ba tính chất mà phương án bảo vệ dựa vào. Thứ nhất, không có đường nào từ bên ngoài vào thẳng vùng ứng dụng hay vùng dữ liệu mà không qua biên (WAF, TLS) và cổng API (xác thực, ủy quyền OPA, giới hạn tốc độ). Thứ hai, mọi kết nối ra ngoài, kể cả tới NDXP và PayGov, chỉ đi qua egress gateway có danh sách đích khai báo (SEC-16), nên một thành phần bị chiếm quyền không thể tùy ý gửi dữ liệu ra ngoài. Thứ ba, con người chỉ truy cập hạ tầng qua vùng quản trị Z7 có VPN, MFA và ghi phiên (SEC-19, SEC-28); không có thao tác tay trên môi trường vận hành ngoài quy trình GitOps (SEC-07, SEC-59).

### 4.5. Sơ đồ vật lý và phân vùng mạng

Sơ đồ vật lý chi tiết, dải địa chỉ và quy tắc tường lửa nằm ở D03-09 §3.1 (`HT-A`) và §3.2 (`HT-B`), nộp kèm hồ sơ. Vùng tin cậy logic của D03-07 và vùng mạng hạ tầng của D03-09 được hiện thực chồng lên nhau: vùng mạng hạ tầng là lớp tường lửa của TTDL hoặc nhóm bảo mật của cloud, vùng logic là namespace Kubernetes với network policy từ chối mặc định (SEC-13, SEC-14). Bảng dưới đây ánh xạ hai cách chia để đơn vị thẩm định đối chiếu hai tài liệu.

| Vùng mạng hạ tầng (D03-09 §3) | Vùng logic (D03-07) | Namespace (D03-09 §4.2) | Thành phần chính |
|---|---|---|---|
| Internet, mạng TSLCD/nội bộ tỉnh | Z0 | — | Người dùng, HTTT, NDXP, PayGov |
| DMZ | Z1 và phần ra của Z4 | `dh-edge` | Cân bằng tải, chống DDoS, `apisix-ext` kèm WAF, egress gateway |
| Vùng ứng dụng (node pool không trạng thái) | Z2, Z3, Z4, phần Keycloak của Z6 | `dh-gateway`, `dh-control`, `dh-payment`, `dh-assist`, `dh-runtime`, `dh-rt-{tenant}`, `dh-iam` | `apisix-int`, BFF, DU, `dh-runtime`, Keycloak |
| Vùng dữ liệu (node pool có trạng thái) | Z5 (`pg-iam` thuộc Z6) | `dh-db`, `dh-kafka`, `dh-olap`, `dh-s3`, `dh-cache` | PostgreSQL, Kafka, Garage, ClickHouse, Valkey |
| Vùng quản trị | Z7; OpenBao niêm phong và kho sao lưu thuộc Z6 | `dh-obs`, `dh-system`, `dh-secrets` (Z6), `istio-system`, `kube-system` | Bastion, Harbor, Git, OpenBao niêm phong, kho sao lưu S3 bất biến, NTP, DNS |
| Liên site | — | — | Sao chép CSDL, Kafka MirrorMaker 2, Garage, Harbor, Git |

: Đối chiếu vùng mạng hạ tầng với vùng tin cậy logic, namespace và thành phần

**[HT-A]** Sơ đồ dưới đây là bản rút gọn của D03-09 §3.1 cho hồ sơ tỉnh độc lập, đủ để đơn vị thẩm định thấy vị trí hệ thống trong TTDL tỉnh.

```{.mermaid caption="Sơ đồ vật lý và phân vùng mạng của hồ sơ tỉnh độc lập HT-A"}
flowchart TB
  subgraph NGOAI["Internet"]
    DEV["Nhà phát triển"]
    NDXP["NDXP"]
    PAY["PayGov"]
  end
  subgraph TSLCD["Mạng TSLCD / nội bộ tỉnh"]
    HTTT["HTTT sở, ngành, xã"]
    CB["Cán bộ"]
  end
  subgraph SITE1["TTDL [Tên tỉnh] - site chính"]
    subgraph DMZ["DMZ 10.10.0.0/24 (ví dụ)"]
      LB["Cân bằng tải, chống DDoS"]
      EGO["apisix-ext + WAF"]
      EGR["Egress gateway"]
    end
    subgraph APPZ["Vùng ứng dụng 10.20.0.0/22 (ví dụ)"]
      EGI["apisix-int + WAF"]
      CORE["APISIX, DU, dh-runtime, Keycloak"]
    end
    subgraph DATAZ["Vùng dữ liệu 10.30.0.0/24 (ví dụ)"]
      STORE[("PostgreSQL, Kafka,<br/>Garage, ClickHouse")]
    end
    subgraph MGMTZ["Vùng quản trị 10.40.0.0/24 (ví dụ)"]
      ADM["Bastion, Harbor, Git,<br/>OpenBao niêm phong"]
      BK[("Kho sao lưu bất biến")]
    end
  end
  SITE2["Site DR [Tên site DR]<br/>cụm dự phòng active–standby"]
  DEV --> LB --> EGO --> CORE
  HTTT & CB --> EGI --> CORE
  CORE --> STORE
  CORE --> EGR --> NDXP & PAY
  ADM --> CORE
  STORE --> BK
  STORE -->|Sao chép bất đồng bộ, mã hóa| SITE2
```

Hồ sơ tỉnh độc lập có hai cửa vào tách biệt: cửa ngoài trong DMZ chỉ phục vụ cổng nhà phát triển và callback PayGov, cửa trong phục vụ HTTT và cán bộ trên mạng TSLCD, nhờ đó giao diện quản trị không bao giờ lộ ra Internet. Vùng ứng dụng và vùng dữ liệu là hai dải nút khác nhau, nên tường lửa của TTDL chặn được luồng ở tầng nút độc lập với network policy trong cụm — hai lớp phòng thủ không phụ thuộc nhau. Site DR nhận dữ liệu sao chép liên tục và chạy ở quy mô tối thiểu (ADR-034); mục tiêu RPO ≤ 15 phút, RTO ≤ 1 giờ cho data plane và ≤ 4 giờ cho control plane (NFR-00-014).

**[HT-B]** Nền tảng dùng chung có cấu trúc tương tự nhưng hiện thực bằng mạng ảo và nhóm bảo mật của cloud, mỗi vùng cloud có một cụm workload và một cụm quản trị, tenant ở chế độ `SHARED` được xếp vào các ô CSDL (mỗi ô khoảng 8–10 tenant) và tenant có yêu cầu cao hơn dùng `DEDICATED_DB` (D03-09 §3.2, D03-10). Sơ đồ dưới đây chỉ thể hiện các điểm khác `HT-A` có ý nghĩa với hồ sơ cấp độ.

```{.mermaid caption="Sơ đồ phân lớp trách nhiệm và vùng mạng của nền tảng dùng chung HT-B"}
flowchart TB
  subgraph TINH["Các tỉnh tham gia"]
    T1["HTTT, cán bộ tỉnh 1"]
    TN["HTTT, cán bộ tỉnh n"]
  end
  subgraph CLOUD1["Cloud Chính phủ - vùng 1 (site chính)"]
    subgraph HATANG["Tầng hạ tầng - thuộc hồ sơ của nhà cung cấp cloud"]
      CLB["Cân bằng tải, chống DDoS, mạng ảo"]
    end
    subgraph WL["Cụm workload Datahub - thuộc hồ sơ nền tảng"]
      SH["Biên, APISIX, DU, dh-runtime<br/>Keycloak: mỗi tỉnh một realm"]
      CELL[("Ô CSDL dùng chung<br/>RLS theo tenant")]
      DED[("CSDL riêng<br/>DEDICATED_DB")]
    end
    subgraph MG["Cụm quản trị - thuộc hồ sơ nền tảng"]
      OPS["Argo CD, Harbor, LGTM,<br/>OpenBao niêm phong"]
    end
  end
  CLOUD2["Cloud Chính phủ - vùng 2 (site DR)"]
  T1 & TN --> CLB --> SH
  SH --> CELL & DED
  OPS --> WL
  WL -->|Sao chép| CLOUD2
```

Sơ đồ phân ba lớp trách nhiệm tương ứng ba hồ sơ: tầng hạ tầng cloud có hồ sơ của nhà cung cấp cloud; cụm workload và cụm quản trị thuộc hồ sơ nền tảng; còn phần cấu hình, người dùng và dữ liệu của mỗi tỉnh nằm trong tenant và thuộc hồ sơ rút gọn của tỉnh đó (mục 5.6). Cách ly giữa các tỉnh được thực thi ở tầng hạ tầng (RLS, ACL Kafka, realm Keycloak, khóa mã hóa riêng theo tenant), không chỉ ở mã ứng dụng (SEC-80…88).

### 4.6. Danh mục thành phần và tài sản

Danh mục tài sản đầy đủ có mã `AS-nn` ở D03-07 §3.1 và được kiểm kê tự động hằng ngày từ kho Git cấu hình và Harbor (SEC-04). Bảng dưới đây gom tài sản theo nhóm để đơn vị thẩm định nắm quy mô; Phụ lục A là bảng chi tiết để tỉnh điền số lượng thực tế.

| Nhóm | Tài sản (mã D03-07) | Mức dữ liệu cao nhất | Mức quan trọng với sẵn sàng |
|---|---|---|---|
| Ứng dụng control plane | AS-01, AS-02 (`dh-payment`), AS-03 (`dh-assist`), AS-05 (giao diện) | Nhạy cảm | Trung bình–cao |
| Data plane | AS-04 (APISIX, `dh-runtime`, Kafka) | Nhạy cảm (dữ liệu đi qua) | Rất cao |
| Kho dữ liệu | AS-06 (PostgreSQL), AS-07 (Garage), AS-09 (Valkey), ClickHouse (chưa có mã, xem mục 11) | Nhạy cảm | Cao |
| Bảo mật lõi | AS-10 (Keycloak), AS-11 (OpenBao), AS-12 (chính sách OPA) | Bí mật kỹ thuật | Rất cao |
| Nhật ký và giám sát | AS-08 (kho WORM), AS-15 (quan sát), AS-16 (nhật ký kiểm toán) | Hạn chế (đã che) | Trung bình |
| Triển khai, chuỗi cung ứng | AS-13 (cấu hình, Argo CD), AS-14 (kho mã, CI, Harbor, khóa ký) | Nội bộ; khóa ký là bí mật kỹ thuật | Cao |
| Sao lưu | AS-17 | Nhạy cảm (trường vẫn mã hóa) | Cao khi DR |
| Hạ tầng | AS-18 (nút, etcd, Cilium, Istio) | Bí mật kỹ thuật | Rất cao |
| Thông tin xác thực ra ngoài | AS-19 (client NDXP, khóa PayGov) | Bí mật kỹ thuật | Cao |

: Danh mục thành phần và tài sản

Quy mô phần cứng phụ thuộc hồ sơ quy mô: theo D03-09 §5.5, `HT-A` tối thiểu ba máy chủ vật lý là ba vùng lỗi độc lập (bốn máy với `QM-VUA` trở lên) ở mỗi site; `HT-B` dùng tài nguyên cloud trên tối thiểu ba vùng sẵn sàng mỗi vùng cloud (D03-09 §5.6). Số lượng chính xác điền ở `TT-30`.

### 4.7. Kết nối với hệ thống bên ngoài

Bảng dưới đây liệt kê các kết nối ra ngoài ranh giới hệ thống, chiều khởi tạo và biện pháp bảo vệ. Đây là các điểm đơn vị thẩm định thường kiểm tra kỹ nhất vì là nơi dữ liệu rời khỏi phạm vi kiểm soát của chủ quản.

| Kết nối | Chiều | Dữ liệu trao đổi | Bảo vệ | Biện pháp |
|---|---|---|---|---|
| HTTT thành viên gọi API | Vào | Dữ liệu nghiệp vụ, có thể chứa DLCN cơ bản và nhạy cảm | TLS 1.3 (1.2 với bộ mã an toàn cho hệ cũ); OAuth 2.1 client_credentials; mTLS hoặc private_key_jwt bắt buộc với hợp đồng mức Nhạy cảm; OPA theo mục đích | SEC-11, 12, 24, 26, 43 |
| Webhook tới HTTT | Ra | Sự kiện nghiệp vụ | HTTPS, chữ ký HMAC-SHA256, chống phát lại; đích khai báo trước | SEC-16, 47 |
| NDXP và CSDL quốc gia (PH-14) | Ra | Tra cứu dân cư, đất đai, doanh nghiệp… cho TTHC | Token do NDXP cấp, TLS, địa chỉ ra cố định; bắt buộc mã mục đích và chấp thuận; nhật ký có băm khóa tra cứu | SEC-16, 37, 60; NĐ 278/2025 |
| PayGov (PH-19) | Vào và ra | Yêu cầu thanh toán, kết quả, tệp đối soát | Callback có chữ ký, khóa ký trong OpenBao transit; không tin kết quả từ trình duyệt | SEC-36, 48, 67 |
| Danh mục dùng chung quốc gia | Ra | Danh mục (không chứa DLCN) | TLS, egress có danh sách | SEC-16 |
| SIEM/SOC của tỉnh hoặc cơ quan chuyên trách | Ra | Log an ninh đã lọc DLCN | Syslog TLS hoặc OTLP qua mTLS | SEC-63, 66 |
| LGSP cũ (giai đoạn chuyển đổi) | Hai chiều | Bản tin qua cầu nối Pulsar–Kafka, gateway cũ – APISIX; dữ liệu di trú | Kết nối trong mạng nội bộ, tài khoản riêng có thời hạn, tháo bỏ khi cắt chuyển khối | Mục 9 |

: Kết nối với hệ thống bên ngoài

> **Câu hỏi mở Q322:** NDXP và PayGov có yêu cầu riêng về cấp độ an ninh mạng tối thiểu của LGSP cấp tỉnh kết nối vào (ví dụ bắt buộc cấp độ 3 đã phê duyệt mới cấp thông tin xác thực) không? Với `HT-B`, một nền tảng gọi thay nhiều tỉnh thì đăng ký kết nối theo nền tảng hay theo từng tỉnh (liên quan Q334 của D03-09)?

### 4.8. Loại và khối lượng dữ liệu xử lý

Datahub xử lý hai loại dữ liệu khác nhau về bản chất (SAD §8.3). **Dữ liệu đi qua** là nội dung bản tin giữa các HTTT: mặc định không lưu, chỉ lưu siêu dữ liệu (ai gọi, gọi gì, khi nào, kết quả); nội dung chỉ lưu tạm trong hàng đợi lỗi tối đa 7 ngày, được mã hóa. **Dữ liệu lưu lại** là dữ liệu Datahub làm chủ: danh mục dùng chung, dữ liệu chủ công dân và tổ chức (PH-06), giao dịch thanh toán (PH-19), cấu hình, tài khoản người dùng, nhật ký kiểm toán. Mỗi trường dữ liệu được gán một trong bốn mức phân loại nội bộ (Công khai, Nội bộ, Hạn chế, Nhạy cảm), quyết định cách lưu, ghi log và hiển thị (D03-07 §3.2).

Bảng dưới đây tóm tắt khối lượng dữ liệu theo hồ sơ quy mô, lấy từ D03-09 §2.2–2.4; tỉnh điền số liệu khảo sát ở `TT-21`…`TT-23`.

| Chỉ số | `QM-NHO` | `QM-VUA` | `QM-LON` | `QM-CHUNG` |
|---|---|---|---|---|
| Lượt gọi API/ngày | 1 triệu | 5 triệu | 15 triệu | 170 triệu |
| Trong đó tới NDXP qua PH-14 (10%) | 0,1 triệu | 0,5 triệu | 1,5 triệu | 17 triệu |
| Sự kiện Kafka nghiệp vụ/ngày | 0,3 triệu | 2 triệu | 6 triệu | 70 triệu |
| Giao dịch thanh toán/ngày (ước tính) | ~10.000 | ~50.000 | ~150.000 | ~1,7 triệu |
| CSDL nghiệp vụ sau 12 tháng | 60 GB | 250 GB | 700 GB | 6,5 TB |
| Kho tệp nghiệp vụ sau 12 tháng | 50 GB | 200 GB | 600 GB | 6 TB |
| Kho WORM kiểm toán | 20 GB/năm | 60 GB/năm | 180 GB/năm | 2 TB/năm |

: Loại và khối lượng dữ liệu xử lý

Toàn bộ dữ liệu, kể cả bản sao lưu, nhật ký và site DR, được lưu trong lãnh thổ Việt Nam (ràng buộc ở BRD và D03-09 §3.2).

### 4.9. Ước tính số chủ thể dữ liệu cá nhân

Số chủ thể dữ liệu cá nhân (DLCN) là tiêu chí quyết định cấp độ của Datahub (mục 5.3), nên phương pháp ước tính được trình bày tường minh để đơn vị thẩm định kiểm tra lại. Ba quy ước được áp dụng. Một, "xử lý" được hiểu theo Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15, bao gồm cả thu thập, truyền đưa và lưu trữ, nên dữ liệu đi qua cũng được tính dù Datahub không lưu nội dung; nếu đơn vị thẩm định chỉ tính dữ liệu lưu lại, bảng vẫn cho kết luận như nhau vì riêng PH-19 và PH-06 đã vượt ngưỡng. Hai, số chủ thể là số người khác nhau trong 12 tháng, không phải số lượt. Ba, "DLCN nhạy cảm" ở đây là khái niệm pháp lý theo Luật 91/2025 và Nghị định 356/2025, **khác** với mức phân loại nội bộ "Nhạy cảm" của Datahub: ví dụ số định danh cá nhân được Datahub xếp mức Nhạy cảm để mã hóa trường, nhưng về pháp lý có thể là DLCN cơ bản; ngược lại dữ liệu sức khỏe, tài chính đi qua từ HTTT ngành là DLCN nhạy cảm dù Datahub không lưu.

| Nguồn | Loại DLCN | Cơ sở ước tính | `QM-NHO` (~[1] triệu dân) | `QM-VUA` (~[2,5] triệu dân) | `QM-LON` (~[5] triệu dân) | `QM-CHUNG` |
|---|---|---|---|---|---|---|
| PH-14 tra cứu CSDL quốc gia về dân cư (đi qua) | Cơ bản | Lượt tra cứu/ngày × 365, giả định mỗi người được tra trung bình 1–3 lần/năm | ≥ 300.000 | ≥ 1 triệu | ≥ 2 triệu | ≥ 30 triệu |
| Bản tin giữa HTTT ngành (đi qua): y tế, bảo hiểm, tư pháp, lao động | Cơ bản và nhạy cảm | Tỷ lệ dân có giao dịch TTHC liên thông trong năm | ≥ 100.000 nhạy cảm | ≥ 250.000 nhạy cảm | ≥ 500.000 nhạy cảm | ≥ 10 triệu nhạy cảm |
| PH-19 giao dịch thanh toán (lưu lại) | Cơ bản; thông tin tài khoản có thể là nhạy cảm | Giao dịch/năm chia số giao dịch trung bình mỗi người | ≥ 200.000 | ≥ 500.000 | ≥ 1 triệu | ≥ 15 triệu |
| PH-06 dữ liệu chủ công dân (lưu lại, đợt 3) | Cơ bản | Tỷ lệ dân có bản ghi vàng sau 12 tháng bật phân hệ | 50–100% dân số | 50–100% dân số | 50–100% dân số | 50–100% dân số các tỉnh dùng PH-06 |
| Tài khoản người dùng, nhật ký kiểm toán (lưu lại) | Cơ bản (cán bộ) | Số tài khoản | ~500 | ~2.000 | ~6.000 | ~70.000 |
| **Tổng hợp (lấy giá trị lớn nhất, không cộng trùng)** | Cơ bản | | **≥ 300.000** | **≥ 1 triệu** | **≥ 2 triệu** | **≥ 30 triệu** |
| | Nhạy cảm | | **≥ 100.000** | **≥ 250.000** | **≥ 500.000** | **≥ 10 triệu** |

: Ước tính số chủ thể dữ liệu cá nhân

Các con số là cận dưới thận trọng; tỉnh điền dân số thực ở `TT-24` và số liệu lưu lượng của LGSP cũ ở `TT-25` để tính lại theo cùng phương pháp. Kết luận quan trọng là **ngay ở hồ sơ quy mô nhỏ nhất, số chủ thể vượt ngưỡng 100.000 (cơ bản) ít nhất ba lần và ngưỡng 10.000 (nhạy cảm) ít nhất mười lần**, nên sai số của phương pháp ước tính không làm thay đổi kết luận cấp độ 3. Điều cần chú ý ngược lại là chiều cao: nếu Nghị định 331/2026 có ngưỡng DLCN cho cấp độ 4, các con số ở cột `QM-LON` và `QM-CHUNG`, và cả PH-06 ở mọi cột khi được bật, phải được so với ngưỡng đó (mục 5.5).

> **Câu hỏi mở Q325:** Cách đếm chủ thể DLCN để áp tiêu chí cấp độ có tính dữ liệu chỉ truyền đưa qua (không lưu) không, và đếm theo năm, theo thời điểm hay lũy kế? Danh mục DLCN nhạy cảm theo Luật 91/2025 và Nghị định 356/2025 có bao gồm thông tin tài khoản thanh toán và dữ liệu tiền án, tiền sự đi qua Datahub không? Cần pháp chế của chủ quản xác nhận để bảng 4.9 dùng đúng định nghĩa.

## 5. Thuyết minh đề xuất cấp độ

### 5.1. Phương pháp

Cấp độ được xác định theo ba bước: vạch ranh giới một HTTT duy nhất (mục 4.2, 5.2); áp từng tiêu chí của Nghị định 331/2026 lên hệ thống và ghi cấp độ tối thiểu mà mỗi tiêu chí đòi hỏi (mục 5.3); lấy cấp cao nhất trong các kết quả theo Điều 8 (mục 5.4). Tiêu chí được đánh mã `TCD-nn` để truy vết; mã này là mã nội bộ của hồ sơ, không phải số điều khoản của nghị định. Những tiêu chí mà nội dung chính xác chưa được đối chiếu toàn văn được đánh dấu và có câu hỏi mở; hồ sơ không viện dẫn số khoản, điểm chưa xác minh.

### 5.2. Một hệ thống, không chia nhỏ

Điều 8 Nghị định 331/2026 cấm chia nhỏ hệ thống về hình thức để hạ cấp độ. Datahub có những bộ phận mà nếu tách riêng có thể trông như hệ cấp thấp — trợ lý AI PH-17 chỉ được nhận dữ liệu tối đa mức Hạn chế, danh mục dùng chung PH-07 hầu như không có DLCN, cổng nhà phát triển PH-15 chỉ chứa tài liệu API. Hồ sơ **không** tách các phần đó, vì chúng dùng chung cụm Kubernetes, CSDL, Keycloak, OpenBao, mạng và đội vận hành với phần xử lý DLCN; một lỗ hổng ở PH-17 hay PH-15 là đường vào cho toàn bộ hệ thống. Toàn bộ nền tảng, kể cả site DR, giám sát, sao lưu và chuỗi cung ứng, được xác định một cấp độ.

**[HT-B]** Lập luận tương tự áp dụng theo chiều ngang: nền tảng dùng chung là một HTTT, không phải 34 HTTT nhỏ ghép lại. Không được lập hồ sơ cho từng tenant với số chủ thể của riêng tỉnh đó để né ngưỡng của nền tảng; số chủ thể của nền tảng là tổng (không trùng lặp) của mọi tỉnh tham gia.

### 5.3. Áp dụng từng tiêu chí

Bảng dưới đây áp từng nhóm tiêu chí lên Datahub. Cột "Cấp tối thiểu" là cấp độ mà riêng tiêu chí đó đòi hỏi; cột cuối cho biết mức chắc chắn của việc áp dụng.

| Mã | Tiêu chí (theo chủ đề) | Đánh giá với Datahub | Cấp tối thiểu `HT-A` | Cấp tối thiểu `HT-B` | Mức chắc chắn |
|---|---|---|---|---|---|
| TCD-01 | Xử lý DLCN của từ 100.000 chủ thể DLCN cơ bản trở lên | Mục 4.9: ≥ 300.000 ở `QM-NHO`, ≥ 30 triệu ở `QM-CHUNG` | 3 | 3 | Đã tra ngưỡng |
| TCD-02 | Xử lý DLCN nhạy cảm của từ 10.000 chủ thể trở lên | Mục 4.9: ≥ 100.000 ở `QM-NHO` | 3 | 3 | Đã tra ngưỡng; định nghĩa nhạy cảm cần đối chiếu (Q325) |
| TCD-03 | Đối tượng phục vụ và phạm vi: hệ phục vụ hoạt động của cơ quan nhà nước và cung cấp dịch vụ cho người dân trên phạm vi tỉnh | Là nền tảng tích hợp cấp tỉnh, phục vụ dịch vụ công trực tuyến của cả tỉnh | ≥ 3 (theo thông lệ khung cũ) | Liên tỉnh: có thể 4 (Q323) | Cần đối chiếu |
| TCD-04 | Hạ tầng thông tin dùng chung, nền tảng số dùng chung | Datahub là hạ tầng dùng chung của tỉnh; `HT-B` dùng chung nhiều tỉnh | ≥ 3 | Có thể 4 (Q323) | Cần đối chiếu |
| TCD-05 | Mức độ ảnh hưởng khi bị phá hoại: tới quyền lợi hợp pháp của tổ chức, cá nhân; tới hoạt động của cơ quan nhà nước; tới quốc phòng, an ninh | Ngừng Datahub làm gián đoạn liên thông TTHC và thanh toán toàn tỉnh; lộ dữ liệu ảnh hưởng số lớn công dân; không xử lý bí mật nhà nước | 3 | 3, có thể 4 nếu ảnh hưởng được đánh giá ở quy mô quốc gia | Cần đối chiếu thang ảnh hưởng |
| TCD-06 | Xử lý thông tin thuộc bí mật nhà nước | Datahub không được thiết kế và không được phép trao đổi bí mật nhà nước; quy chế kết nối cấm HTTT gửi dữ liệu mật | Không áp dụng | Không áp dụng | Chắc chắn về thiết kế |
| TCD-07 | Xử lý dữ liệu quan trọng, dữ liệu cốt lõi theo Luật Dữ liệu 60/2024, hoặc là thành phần của CSDL quốc gia | Datahub không là CSDL quốc gia; khai thác CSDL quốc gia qua NDXP với vai trò bên xử lý; PH-06 có thể bị xếp là dữ liệu quan trọng của tỉnh | 3 (nếu PH-06 không bị xếp dữ liệu quan trọng) | 3 hoặc 4 | Chưa xác định (Q324) |

: Áp dụng từng tiêu chí

Hai tiêu chí TCD-01 và TCD-02 là căn cứ chắc chắn nhất và đủ một mình đưa hệ thống lên tối thiểu cấp độ 3. Các tiêu chí TCD-03, TCD-04, TCD-05 theo thông lệ khung cũ cũng dẫn tới cấp độ 3 cho hệ cấp tỉnh; chúng được nêu để hồ sơ đầy đủ chứ không phải để củng cố một kết luận đã chắc.

> **Câu hỏi mở Q324:** Theo Luật Dữ liệu 60/2024 và văn bản hướng dẫn, danh mục dữ liệu quan trọng, dữ liệu cốt lõi do ai ban hành và dữ liệu chủ công dân cấp tỉnh (PH-06, bản ghi vàng hợp nhất từ nhiều HTTT) có thuộc danh mục đó không? Nghị định 331/2026 có gắn việc xử lý dữ liệu quan trọng, dữ liệu cốt lõi với cấp độ 4 không? Câu trả lời có thể đẩy hồ sơ lên cấp độ 4 khi bật PH-06.

### 5.4. Kết luận và lý do đề xuất cấp độ 3

[Tên cơ quan đề nghị] đề xuất hệ thống "[Tên hệ thống]" ở **cấp độ 3**. Lý do được tóm lại trong bốn ý. Một, hệ thống chắc chắn đáp ứng tiêu chí số chủ thể DLCN của cấp độ 3 (TCD-01, TCD-02) với khoảng cách lớn so với ngưỡng, nên không thể đề xuất cấp độ 1 hay 2. Hai, theo nguyên tắc lấy cấp cao nhất của Điều 8, cấp độ của hệ thống là cấp cao nhất trong các tiêu chí đáp ứng; với các thông tin đã xác minh, không tiêu chí nào chắc chắn đòi cấp độ 4 cho hồ sơ `HT-A`. Ba, hệ thống không xử lý bí mật nhà nước và không là CSDL quốc gia, hai đặc điểm theo thông lệ thường gắn với cấp độ cao hơn. Bốn, phương án bảo vệ (mục 6) đáp ứng đủ 18 nhóm yêu cầu cấp độ 3 của TCVN 14423:2026 và đã chừa sẵn điểm nâng lên cấp độ 4 (mục 7), nên nếu đơn vị thẩm định kết luận khác thì việc nâng cấp là bổ sung biện pháp chứ không thiết kế lại.

**[HT-A]** Kết luận cấp độ 3 vững với ba điều kiện: PH-06 chưa được bật, hoặc đã bật nhưng Q324 xác nhận không phải dữ liệu quan trọng; Nghị định 331/2026 không có ngưỡng DLCN cấp độ 4 thấp hơn số chủ thể của tỉnh (Q323); và tỉnh không giao Datahub phục vụ hệ thống liên tỉnh. Khi một trong ba điều kiện thay đổi, chủ quản phải đánh giá lại cấp độ (mục 5.5).

**[HT-B]** Đề xuất cấp độ 3 cho nền tảng dùng chung là **đề xuất có điều kiện**. Nền tảng tập trung dữ liệu của hàng chục tỉnh, với số chủ thể cùng bậc với dân số cả nước, nên khả năng tiêu chí phạm vi (TCD-03, TCD-04) hoặc một ngưỡng DLCN cao hơn đòi cấp độ 4 là đáng kể. Hồ sơ khuyến nghị chủ quản nền tảng xin ý kiến đơn vị chuyên trách của Bộ Công an về cấp độ **trước khi** hoàn thiện hồ sơ, và lập dự toán theo hai phương án (cấp độ 3; cấp độ 3 cộng nhóm SEC-90…99).

### 5.5. Các điều kiện làm hệ thống phải lên cấp độ 4

Bảng dưới đây liệt kê các yếu tố có thể đẩy Datahub lên cấp độ 4, đánh giá mức khả năng với từng hồ sơ và việc phải làm khi yếu tố xảy ra. Mã `CD4-nn` là mã nội bộ để theo dõi; mỗi yếu tố gắn với một sự kiện kích hoạt đánh giá lại cấp độ.

| Mã | Yếu tố | `HT-A` | `HT-B` | Khi xảy ra |
|---|---|---|---|---|
| CD4-01 | Nghị định 331/2026 có ngưỡng số chủ thể DLCN cho cấp độ 4 và số chủ thể của hệ vượt ngưỡng | Có thể với `QM-LON` hoặc khi bật PH-06 | Khả năng cao | Đánh giá lại, lập hồ sơ điều chỉnh cấp độ |
| CD4-02 | Dữ liệu do hệ xử lý được xếp là dữ liệu quan trọng/cốt lõi (PH-06), hoặc hệ được giao làm thành phần của CSDL quốc gia | Có thể khi bật PH-06 | Có thể | Như trên; kích hoạt SEC-90, SEC-92 trước tiên |
| CD4-03 | Hệ phục vụ nhiều tỉnh hoặc phạm vi liên vùng (nền tảng dùng chung) | Không | Đang có — cần xác định đây có phải tiêu chí cấp độ 4 không | Xin ý kiến Bộ Công an (Q323) |
| CD4-04 | Mức ảnh hưởng khi ngừng hoạt động được đánh giá ở quy mô quốc gia (ví dụ gián đoạn thanh toán, liên thông TTHC của nhiều tỉnh cùng lúc) | Không | Có thể | Như CD4-03 |
| CD4-05 | Một tenant trên nền tảng dùng chung tự xác định cấp độ 4 (ví dụ tỉnh giao xử lý dữ liệu đặc thù) | — | Có thể | Tenant chuyển `DEDICATED_DB`/`DEDICATED_CLUSTER`, áp SEC-90…99 cho tenant đó |
| CD4-06 | Thay đổi pháp luật hoặc yêu cầu của cơ quan có thẩm quyền | Có thể | Có thể | Theo yêu cầu |

: Các điều kiện làm hệ thống phải lên cấp độ 4

Câu hỏi then chốt là CD4-03: việc một nền tảng phục vụ nhiều tỉnh tự nó có phải yếu tố cấp độ 4 không. Lập luận ủng hộ: phạm vi ảnh hưởng vượt một địa phương, hậu quả khi bị tấn công có tính hệ thống. Lập luận ngược lại: mỗi tenant được cách ly ở tầng hạ tầng và mật mã (SEC-80…88), nên sự cố ở một tỉnh không lan; Điều 30 cho phép hệ cấp độ 3 dùng chung hạ tầng cloud, tức bản thân việc dùng chung không mặc nhiên nâng cấp độ. Hồ sơ không tự kết luận điểm này.

> **Q323 (đã chốt 25/11/2026):** phần (b): mỗi tỉnh là chủ quản tenant của mình (như Q311); phần (a) về tiêu chí cấp độ 4 vẫn chờ pháp chế đối chiếu NĐ 331/2026. *Câu hỏi gốc:* (a) Nghị định 331/2026 có tiêu chí cấp độ 4 dựa trên số chủ thể DLCN (ngưỡng bao nhiêu), trên phạm vi phục vụ liên tỉnh, liên vùng, hay trên vai trò nền tảng dùng chung không? (b) Ai là chủ quản của nền tảng dùng chung (cơ quan trung ương được giao, một tỉnh đầu mối, hay doanh nghiệp cung cấp dịch vụ cho thuê), và hồ sơ của từng tỉnh lập đầy đủ hay rút gọn? Câu hỏi này trùng một phần với Q311 của D03-07; câu trả lời quyết định cấp độ và số bộ hồ sơ của `HT-B`.

### 5.6. Hồ sơ nền tảng dùng chung: chủ quản và quan hệ với hồ sơ của tỉnh

**[HT-B]** Mục này đề xuất mô hình hai tầng hồ sơ, chờ trả lời Q323. Bảng dưới đây so sánh ba phương án tổ chức chủ quản đã cân nhắc.

| Phương án | Mô tả | Ưu điểm | Nhược điểm |
|---|---|---|---|
| A. Một chủ quản nền tảng, tỉnh lập hồ sơ rút gọn | Cơ quan được giao (trung ương hoặc tỉnh đầu mối) là chủ quản nền tảng, lập một hồ sơ cho toàn nền tảng; mỗi tỉnh lập hồ sơ rút gọn cho phần sử dụng của mình, dẫn chiếu hồ sơ nền tảng | Một phương án bảo vệ thống nhất; tỉnh không phải thẩm định lại phần dùng chung; khớp tinh thần Điều 30 | Cần văn bản giao chủ quản; tỉnh phụ thuộc tiến độ hồ sơ nền tảng |
| B. Mỗi tỉnh là chủ quản của "hệ của mình", nền tảng là hạ tầng | Mỗi tỉnh lập hồ sơ đầy đủ coi nền tảng như hạ tầng dịch vụ | Tỉnh tự chủ | Phần dùng chung bị thẩm định 34 lần; không ai chịu trách nhiệm cuối cùng cho tầng nền tảng; dễ bị xem là chia nhỏ |
| C. Doanh nghiệp cung cấp dịch vụ là chủ quản nền tảng | Nền tảng là dịch vụ thuê; doanh nghiệp lập hồ sơ cho nền tảng | Đơn giản cho tỉnh | Chủ quản theo Điều 31 là người đứng đầu cơ quan; vai trò doanh nghiệp cần xác minh |

: Hồ sơ nền tảng dùng chung: chủ quản và quan hệ với hồ sơ của tỉnh

Bản mẫu chọn **phương án A** làm mặc định. Theo đó, hồ sơ nền tảng xác định cấp độ cho toàn bộ nền tảng theo tổng số chủ thể và phạm vi của mọi tỉnh tham gia (mục 5.2), và phương án bảo vệ của nền tảng bao gồm mọi biện pháp `SEC-nn` ở phần trách nhiệm N và H của D03-07 §12. Hồ sơ rút gọn của mỗi tỉnh gồm: thông tin chung (mục 3) với chủ quản là cơ quan của tỉnh; mô tả phần sử dụng (số HTTT kết nối, người dùng, loại dữ liệu, số chủ thể của tỉnh); dẫn chiếu quyết định phê duyệt cấp độ của nền tảng; và phương án bảo vệ cho phần trách nhiệm C (cấu hình tenant, tài khoản và phân quyền, phân loại dữ liệu và mục đích SEC-37, máy trạm người dùng, ứng phó sự cố phía tỉnh). Hai quy tắc ràng buộc quan hệ giữa hai tầng: cấp độ của phần sử dụng của tỉnh không cao hơn cấp độ đã phê duyệt của nền tảng, trừ khi tenant đó chạy chế độ cách ly riêng có biện pháp bổ sung (CD4-05); và mọi thay đổi làm điều chỉnh cấp độ nền tảng phải được thông báo cho chủ quản của mọi tỉnh.

### 5.7. Trình tự thẩm định và phê duyệt

Trình tự dưới đây dựng theo Điều 25 Nghị định 331/2026 ở mức đã tra (phê duyệt cấp độ lần đầu dựa trên hồ sơ đề xuất cấp độ và phương án bảo vệ); các bước và thời hạn cụ thể chờ Q320, Q321.

```{.mermaid caption="Sơ đồ quy trình thẩm định, phê duyệt cấp độ và vận hành"}
flowchart TB
  A["Đơn vị vận hành lập hồ sơ<br/>theo bản mẫu D03-08"] --> B["Bộ phận chuyên trách ANM<br/>rà soát nội bộ"]
  B --> C{"Cấp độ đề xuất"}
  C -->|Cấp độ 3| D["Đơn vị thẩm định cấp độ 3<br/>(Q321)"]
  C -->|Cấp độ 4| E["Bộ Công an chủ trì thẩm định"]
  D & E --> F["Chủ quản phê duyệt cấp độ<br/>và phương án bảo vệ"]
  F --> G["Triển khai phương án,<br/>kiểm tra trước vận hành (mục 8)"]
  G --> H["Vận hành chính thức<br/>sau cổng RG-4"]
```

Sơ đồ thể hiện ba điểm. Thứ nhất, ở cấp độ 3, bộ phận chuyên trách ANM rà soát nội bộ, đơn vị thẩm định kiểm tra hồ sơ rồi chủ quản phê duyệt cấp độ và phương án bảo vệ (đơn vị thẩm định cụ thể chờ Q321); ở cấp độ 4 Bộ Công an chủ trì thẩm định. Hồ sơ được phê duyệt **trước** khi vận hành chính thức, vì BRD đặt phê duyệt cấp độ là điều kiện nghiệm thu (KPI-08) và D05-01 đặt "hồ sơ cấp độ có bằng chứng kiểm thử" là tiêu chí ra của cổng `RG-4`. Bước kiểm tra trước vận hành nằm sau phê duyệt phương án nhưng trước vận hành chính thức, để bằng chứng kiểm tra phản ánh hệ thống thật đã triển khai.

## 6. Phương án bảo vệ

### 6.1. Nguyên tắc và nguồn

Phương án bảo vệ của hồ sơ là danh mục biện pháp `SEC-01`…`SEC-88` định nghĩa ở D03-07 mục 5 và 9, áp dụng cho cả hai hồ sơ triển khai, với phân công thực hiện theo D03-07 §12. Hồ sơ không chép lại nội dung biện pháp; bảng ở mục 6.2 tóm lược theo nhóm yêu cầu của TCVN 14423:2026 cấp độ 3 (chương 5), và **ma trận đầy đủ là D03-07 mục 11a**, nộp kèm như một phần của phương án. Mỗi biện pháp ở D03-07 có tiêu chí đo được và cách kiểm chứng, nên phương án có thể kiểm tra được chứ không chỉ là cam kết. Tên các nhóm 5.1–5.18 được ghi theo chủ đề vì chưa đối chiếu toàn văn, trừ các mục đã xác định (5.1, 5.2, 5.13, 5.15, 5.17, 5.18); với hồ sơ thẩm định theo khung cũ, D03-07 mục 11b cung cấp ánh xạ sang TCVN 11930:2017 và Thông tư 12/2022.

### 6.2. Yêu cầu theo nhóm của TCVN 14423:2026 cấp độ 3

Bảng dưới đây là tóm lược phương án. Cột "Tham số chính" nêu một hai ngưỡng tiêu biểu để đơn vị thẩm định thấy mức chặt của biện pháp; ngưỡng đầy đủ ở D03-07.

| Nhóm (số mục) | Biện pháp | Tham số chính | Nơi chi tiết |
|---|---|---|---|
| Quản lý rủi ro (5.1) | SEC-06 | Đánh giá rủi ro khi khởi tạo, mỗi 6 tháng và khi đổi kiến trúc; mô hình STRIDE | D03-07 §4 |
| Quản lý tài sản (5.2) | SEC-04 | Kiểm kê tự động hằng ngày (chặt hơn mức 1 lần/năm) | D03-07 §3.1; Phụ lục A |
| Chính sách, tổ chức, nhân sự (cần đối chiếu số mục) | SEC-01, 02, 03, 05 | Quy chế ban hành trước vận hành; thu hồi quyền ≤ 24 giờ; đào tạo ≥ 1 lần/năm | Mục 6.3 |
| Cấu hình và thay đổi (cần đối chiếu) | SEC-07, 50, 51, 52, 59, 65 | Mọi thay đổi PROD qua Git có người thứ hai duyệt; CIS Benchmark; phát hiện lệch cấu hình hằng giờ | D03-07 §5.2, 5.7 |
| Tài khoản, xác thực, kiểm soát truy cập (cần đối chiếu) | SEC-20…29, 85 | MFA cho mọi vai trò quản trị; mật khẩu ≥ 14 ký tự; khóa phiên nhàn rỗi 15 phút; vô hiệu tài khoản sau 45 ngày (quản trị 30 ngày); token 5 phút | D03-07 §5.4 |
| Lỗ hổng và vá (cần đối chiếu) | SEC-09, 57 | Quét liên tục; vá hệ điều hành hằng tháng; chặn CRITICAL khi phát hành | D03-07 §5.2 |
| Nhật ký (cần đối chiếu) | SEC-60, 61, 62 | Kiểm toán chỉ-thêm, chuỗi băm, WORM 5 năm; log an ninh 12 tháng trực tuyến | D03-07 §7; ADR-031 |
| Phòng chống mã độc (cần đối chiếu) | SEC-54, 45 | Phát hiện hành vi lúc chạy (eBPF); quét tệp tải lên | D03-07 §5.6, 5.7 |
| Trình duyệt, thư điện tử (cần đối chiếu) | SEC-44; quy chế máy trạm của chủ quản | CSP chặt, cookie an toàn; thư điện tử chỉ gửi liên kết | D03-07 §5.6 |
| Hạ tầng mạng (cần đối chiếu) | SEC-10…19 | Tám vùng Z0–Z7; network policy từ chối mặc định; mTLS STRICT; egress có danh sách | D03-07 §5.3; D03-09 §3, §4 |
| Bảo vệ dữ liệu, mật mã (cần đối chiếu) | SEC-30…39, 80…88 | Mã hóa volume; mã hóa trường Nhạy cảm bằng khóa riêng theo tenant (ADR-032); che DLCN trong log | D03-07 §5.5, §6, §9 |
| Sao lưu, khôi phục (cần đối chiếu) | SEC-70, 71 | Sao lưu bất biến ngoài site; RPO ≤ 15 phút; RTO ≤ 1 giờ data plane; diễn tập DR hằng quý | D03-09 §7, §8 |
| Giám sát và phòng thủ (5.13) | SEC-63, 64, 66, 67 | Đẩy log ra SIEM/SOC; MTTD ≤ 5 phút cho luật mức cao | D03-07 §7.4, 7.5 |
| Nhà cung cấp, chuỗi cung ứng (cần đối chiếu) | SEC-05, 55…58 | Điều khoản ATTT trong hợp đồng, báo sự cố ≤ 24 giờ; ảnh ký cosign, SBOM, mục tiêu SLSA mức 3 | D03-07 §5.2, 5.7 |
| Ứng phó sự cố (5.15) | SEC-72…75 | Phân loại ≤ 30 phút; 8 playbook; diễn tập 2 lần/năm; thông báo vi phạm DLCN ≤ 72 giờ | D03-07 §8 |
| Phát triển ứng dụng an toàn (5.17) | SEC-40…49 | OWASP ASVS 5.0 mức 2; SAST, DAST, kiểm thử API trong CI | D03-07 §5.6; D04-01, D04-02 |
| Quản lý kiểm tra an ninh mạng (5.18) | SEC-08, 42, 87 | Pentest độc lập ≥ 1 lần/năm và trước phát hành lớn; kube-bench hằng quý; kiểm thử rò rỉ chéo tenant hằng ngày | Mục 8; D05-01 §5.5, 5.6 |
| An toàn vật lý (Phụ lục A) | Yêu cầu đối với bên cung cấp hạ tầng | Mục 6.4 | D03-07 §12; D03-09 |

: Yêu cầu theo nhóm của TCVN 14423:2026 cấp độ 3

### 6.3. Yêu cầu quản lý

**Tổ chức và nhân sự chuyên trách.** Điều 31 Nghị định 331/2026 quy định người đứng đầu là chủ quản và phải bố trí bộ phận hoặc nhân sự chuyên trách an ninh mạng phù hợp cấp độ. Hồ sơ cam kết chủ quản ban hành quyết định giao [Bộ phận chuyên trách ANM] trước khi vận hành (SEC-02), với ít nhất một đầu mối liên lạc 24/7 (`TT-08`). Bản mẫu đề xuất mức tối thiểu sau, chờ xác nhận theo Q327: **[HT-A]** bộ phận chuyên trách của chủ quản có tối thiểu 2 người, trong đó 1 người phụ trách Datahub, cộng đội vận hành tối thiểu 2 người đã qua đào tạo Kubernetes (D03-09 §3.1); **[HT-B]** đơn vị vận hành nền tảng có bộ phận an ninh mạng riêng trực 24/7, và mỗi tỉnh có tối thiểu 1 đầu mối an ninh mạng cho phần tenant. Mọi nhân sự có quyền vào vùng Z7 ký cam kết bảo mật, được kiểm tra lý lịch và đào tạo hằng năm (SEC-03).

> **Câu hỏi mở Q327:** Nghị định 331/2026 Điều 31 (hoặc văn bản hướng dẫn) quy định số lượng, tiêu chuẩn năng lực tối thiểu của nhân sự chuyên trách an ninh mạng cho hệ cấp độ 3 không, và có cho phép thuê ngoài dịch vụ (ví dụ SOC, đơn vị vận hành nền tảng) thay một phần nhân sự chuyên trách không?

**Quy chế.** Trước vận hành chính thức, chủ quản ban hành bộ quy chế gồm: chính sách an ninh mạng chung; quy chế quản lý tài khoản và phân quyền; quy chế kết nối, chia sẻ dữ liệu qua Datahub (vai trò các bên với DLCN, cấm truyền bí mật nhà nước, yêu cầu xác thực theo mức phân loại); quy chế ứng phó sự cố; quy chế làm việc với nhà cung cấp và nhà thầu (SEC-01, SEC-05). D03-07 §5.2 nêu nội dung bắt buộc của từng quy chế.

**Kiểm tra, đánh giá định kỳ.** Sau khi vận hành, chủ quản tổ chức tự đánh giá theo ma trận D03-07 mục 11 hằng năm, đánh giá cấu hình theo CIS hằng quý và kiểm thử xâm nhập độc lập ít nhất hằng năm và khi thay đổi lớn (SEC-08); kết quả và kế hoạch khắc phục được lưu làm bằng chứng cho kiểm tra của cơ quan có thẩm quyền. Tần suất bắt buộc theo Nghị định 331/2026 cần đối chiếu (Q328); nếu quy định chặt hơn thì áp quy định.

**Ứng phó sự cố.** Quy trình sáu bước, bốn mức sự cố P1–P4, bảng RACI và mốc báo cáo ở D03-07 §8 là phương án ứng phó của hồ sơ. Hai nghĩa vụ pháp lý được thiết kế thành nhánh song song ngay khi phân loại: thông báo vi phạm DLCN tới Cục A05 trong 72 giờ (Luật 91/2025) và báo cáo sự cố an ninh mạng tới cơ quan có thẩm quyền (thời hạn chờ Q309 của D03-07). Ở `HT-B`, nhà cung cấp nền tảng báo chủ quản tỉnh bị ảnh hưởng ≤ 1 giờ với sự cố P1 (SEC-05).

### 6.4. Yêu cầu vật lý tại TTDL (Phụ lục A TCVN 14423:2026)

Datahub không sở hữu phòng máy; yêu cầu an toàn vật lý được đáp ứng bởi bên cung cấp hạ tầng và đưa vào hồ sơ bằng hai cách. **[HT-A]** TTDL tỉnh cung cấp văn bản xác nhận đáp ứng Phụ lục A cho phòng máy đặt Datahub ở cả site chính và site DR: kiểm soát ra vào có ghi nhật ký, giám sát hình ảnh, nguồn điện dự phòng (UPS và máy phát), làm mát dự phòng, phòng cháy chữa cháy, giám sát môi trường; ba máy chủ là ba vùng lỗi độc lập về nguồn và chuyển mạch (D03-09 §3.1); đĩa mã hóa nên tháo đĩa không đọc được dữ liệu (SEC-30). **[HT-B]** Nhà cung cấp cloud chứng minh bằng hồ sơ cấp độ đã phê duyệt của hạ tầng cloud và kết quả đánh giá theo bộ tiêu chí an ninh mạng cho nền tảng điện toán đám mây (Quyết định 8297/QĐ-BCA-A05, chưa xác minh chi tiết), toàn bộ hạ tầng đặt trong lãnh thổ Việt Nam. Danh mục bằng chứng điền ở `TT-40`, `TT-41`.

> **Câu hỏi mở Q329:** Với `HT-B`, hạ tầng cloud Chính phủ phải có cấp độ đã phê duyệt không thấp hơn cấp độ của nền tảng Datahub không, và hồ sơ nền tảng kế thừa biện pháp của tầng cloud theo Điều 30 bằng hình thức nào (dẫn chiếu quyết định phê duyệt, biên bản đánh giá theo Quyết định 8297/QĐ-BCA-A05, hay điều khoản hợp đồng)?

## 7. Lộ trình đáp ứng cấp độ 4

Hệ thống được thiết kế "sẵn sàng cấp độ 4" theo ADR-030: kiến trúc không chứa quyết định nào phải làm lại khi nâng cấp, các biện pháp bổ sung cắm được vào điểm đã chừa, và có bảng chênh lệch để lập dự toán. Bảng điểm chờ `SEC-90`…`SEC-99` ở D03-07 §10.2 là lộ trình của hồ sơ. Bảng dưới đây xếp các biện pháp thành ba bước theo thứ tự nên làm khi một yếu tố ở mục 5.5 xảy ra; thời gian tính từ quyết định nâng cấp (mốc N).

| Bước | Biện pháp | Gắn với yếu tố | Thời gian dự kiến |
|---|---|---|---|
| 1. Khóa và cách ly dữ liệu | SEC-90 (HSM cho khóa gốc và KEK, chỉ bọc lại khóa dữ liệu), SEC-92 (CSDL riêng theo tenant) | CD4-01, CD4-02, CD4-05 | N + 3 tháng |
| 2. Quản trị và giám sát | SEC-93 (mạng quản trị out-of-band), SEC-94 (PAM ghi phiên mọi truy cập), SEC-95 (SOC 24/7), SEC-97 (máy trạm quản trị chuyên dụng), SEC-98 (DLP, UEBA) | Mọi yếu tố | N + 6 tháng |
| 3. Sẵn sàng và đảm bảo | SEC-91 (hai TTDL active–active cho data plane), SEC-96 (pentest 2 lần/năm, red team), SEC-99 (build kín, hai người duyệt phát hành) | Mọi yếu tố | N + 9 tháng |

: Lộ trình đáp ứng cấp độ 4

Ảnh hưởng tập trung ở hạ tầng và tổ chức, không ở mã ứng dụng: đội phát triển chỉ đổi cấu hình (địa chỉ seal PKCS#11, chế độ tenant) và chạy tác vụ bọc lại khóa. Danh sách cần đối chiếu lại với chương 6 TCVN 14423:2026 khi có toàn văn (Q310 của D03-07). Ở `HT-B`, bước 1 có thể áp riêng cho tenant cấp độ 4 mà không nâng cả nền tảng; bước 2 và 3 thường phải áp cho nền tảng.

## 8. Kế hoạch kiểm tra, đánh giá trước khi đưa vào vận hành

Trước vận hành chính thức, hệ thống được kiểm tra để chứng minh phương án bảo vệ đã được triển khai thật, không chỉ trên giấy. Kế hoạch dựa trên D05-01 (kế hoạch kiểm thử tổng thể, §5.5 kiểm thử bảo mật, §5.6 kiểm thử rò rỉ chéo tenant, §6.2 cổng phát hành) và D05-04 (kế hoạch kiểm thử bảo mật chi tiết: bảng kiểm ASVS, kịch bản pentest, ánh xạ từng `SEC-nn`). Bảng dưới đây liệt kê hạng mục kiểm tra, người thực hiện và bằng chứng đưa vào hồ sơ.

| Hạng mục | Nội dung | Thực hiện | Bằng chứng | Ngưỡng đạt |
|---|---|---|---|---|
| Tự đánh giá theo ma trận | Kiểm từng dòng D03-07 mục 11a với hệ đã triển khai | Bộ phận chuyên trách ANM, nhà cung cấp | Bảng tự đánh giá có minh chứng từng dòng | 100% dòng Đạt hoặc có ngoại lệ được chủ quản chấp thuận |
| Kiểm thử bảo mật tự động | SAST, SCA, quét bí mật, DAST, quét cấu hình | Đường ống CI (D05-01 §5.5) | Báo cáo SARIF tập trung | 0 CRITICAL; 0 HIGH chưa có ngoại lệ (NFR-00-023) |
| Bảng kiểm ASVS 5.0 mức 2 | Từng yêu cầu L2 | Đội kiểm thử (D05-04) | Bảng kiểm có minh chứng | 100% yêu cầu áp dụng Đạt hoặc ngoại lệ (NFR-00-024) |
| Kiểm thử rò rỉ chéo tenant | Mọi endpoint, mọi tầng lưu trữ | Tự động (D05-01 §5.6) | Kết quả chạy | 100% đạt |
| Đánh giá cấu hình hạ tầng | kube-bench theo CIS, kiểm tra TLS, network policy | Đơn vị vận hành | Báo cáo kube-bench, testssl | 0 vi phạm mức cao |
| Kiểm thử xâm nhập độc lập | Hộp xám, OWASP WSTG, API Top 10 2023, leo thang liên tenant | Đơn vị độc lập (Q362 của D05-01) | Báo cáo pentest, biên bản tái kiểm | 0 phát hiện Critical/High còn mở |
| Diễn tập DR và sao lưu | Chuyển site, khôi phục từ kho bất biến | Đơn vị vận hành | Biên bản diễn tập (D03-09 §7.10) | Đạt RPO/RTO của NFR-00-014 |
| Kiểm tra phát hiện và ứng phó | Sinh sự kiện an ninh mẫu, chạy một playbook | Bộ phận chuyên trách ANM | Nhật ký cảnh báo, biên bản | Cảnh báo ≤ 5 phút; playbook hoàn tất đúng RACI |
| Kiểm tra vật lý | Xác nhận Phụ lục A | Bên cung cấp hạ tầng | Văn bản xác nhận | Đủ mục |

: Kế hoạch kiểm tra, đánh giá trước khi đưa vào vận hành

Các hạng mục trên là tiêu chí ra của cổng `RG-4` (D05-01 §6.2). Báo cáo tổng hợp kết quả kiểm tra được chủ quản xem xét trước khi quyết định đưa vào vận hành; nếu Nghị định 331/2026 yêu cầu đánh giá bởi tổ chức được cấp phép hoặc bởi cơ quan có thẩm quyền, kết quả ở bảng là đầu vào cho đánh giá đó (Q328).

> **Câu hỏi mở Q328:** Nghị định 331/2026 có bắt buộc kiểm tra, đánh giá an ninh mạng trước khi đưa hệ cấp độ 3 vào vận hành do tổ chức độc lập được cấp phép thực hiện không, và tần suất kiểm tra, đánh giá định kỳ bắt buộc với cấp độ 3 là bao nhiêu? Liên quan Q360, Q362 của D05-01.

## 9. Chuyển tiếp từ LGSP cũ

Datahub thay thế LGSP hiện hành của tỉnh theo cách thay dần, nên trong một giai đoạn hai hệ cùng chạy và nối với nhau qua cầu nối tạm. Điều 39 Nghị định 331/2026 quy định hệ đang đầu tư trước 01/7/2026 được thẩm định theo Nghị định 85/2016 trong 6 tháng và trong 12 tháng phải đáp ứng nghị định mới. Bảng dưới đây nêu cách xử lý cho bốn tình huống; tỉnh chọn tình huống và điền `TT-11`, `TT-50`.

| Tình huống | Xử lý với Datahub | Xử lý với LGSP cũ |
|---|---|---|
| S1. LGSP cũ đã được phê duyệt cấp độ theo Nghị định 85; Datahub là dự án mới | Lập hồ sơ mới theo Nghị định 331 và TCVN 14423:2026 bằng bản mẫu này | Giữ quyết định cũ cho phần còn chạy; trong 12 tháng rà soát đáp ứng nghị định mới hoặc hoàn tất cắt chuyển; quyết định cũ hết hiệu lực khi khối cuối cùng ngừng |
| S2. LGSP cũ đã được phê duyệt; Datahub là nâng cấp, mở rộng của chính hệ đó | Lập hồ sơ điều chỉnh cấp độ cho hệ sau nâng cấp theo khung mới; phương án bảo vệ là của Datahub | Như S1 |
| S3. LGSP cũ chưa được phê duyệt cấp độ | Lập hồ sơ mới cho Datahub; ưu tiên rút ngắn thời gian cùng chạy | Không lập hồ sơ riêng tốn kém cho hệ sắp ngừng; đưa phần còn chạy và cầu nối vào phụ lục rủi ro chuyển tiếp của hồ sơ Datahub, kèm biện pháp bù (cô lập mạng, giám sát tăng cường, hạn cắt chuyển); chờ xác nhận chấp nhận cách làm này (Q326) |
| S4. Dự án Datahub được phê duyệt đầu tư trước 01/7/2026 | Có thể thẩm định theo Nghị định 85 nếu còn trong thời hạn 6 tháng; bản mẫu khuyến nghị vẫn lập theo khung mới vì phải đáp ứng nghị định mới trong 12 tháng; dùng ma trận D03-07 mục 11b nếu thẩm định theo khung cũ | Như S1 hoặc S3 |

: Chuyển tiếp từ LGSP cũ

Trong mọi tình huống, cầu nối tạm (Pulsar–Kafka, gateway cũ – APISIX, đọc dữ liệu di trú) nằm **trong** ranh giới Datahub và được bảo vệ như thành phần của Datahub: tài khoản riêng có thời hạn, đích khai báo, ghi kiểm toán, tháo bỏ khi cắt chuyển khối tương ứng (cổng `RG-5`). LGSP cũ nằm ngoài ranh giới và được coi là hệ có thể bị xâm phạm.

> **Câu hỏi mở Q326:** Mốc 6 tháng và 12 tháng của Điều 39 tính từ 01/7/2026 hay từ ngày Nghị định 331/2026 có hiệu lực? Datahub được coi là hệ mới hay nâng cấp của LGSP cũ (S1 hay S2)? Với tỉnh mà LGSP cũ chưa được phê duyệt cấp độ (S3), có được xử lý phần còn chạy bằng phụ lục rủi ro chuyển tiếp trong hồ sơ Datahub không? Liên quan Q300 của D03-07.

## 10. Phụ lục

### Phụ lục A. Danh mục tài sản (mẫu điền)

Bảng dưới đây là mẫu kiểm kê tài sản nộp kèm hồ sơ. Cột mã và mô tả lấy từ D03-07 §3.1; tỉnh điền số lượng và phiên bản từ báo cáo kiểm kê tự động (SEC-04) tại thời điểm lập hồ sơ.

| Mã | Tài sản | Số lượng/bản sao | Phiên bản | Vị trí (site, vùng) | Đơn vị quản lý |
|---|---|---|---|---|---|
| AS-01…03, AS-05 | DU control plane, `dh-payment`, `dh-assist`, giao diện | [ ] | [ ] | [Site], Z3 | [ ] |
| AS-04 | APISIX, `dh-runtime`, Kafka | [ ] | [ ] | [Site], Z2/Z4/Z5 | [ ] |
| AS-06, AS-07, AS-09 | PostgreSQL CNPG, Garage, Valkey | [ ] | [ ] | [Site], Z5 | [ ] |
| (chưa có mã) | ClickHouse siêu dữ liệu lượt gọi | [ ] | [ ] | [Site], Z5 | [ ] |
| AS-08, AS-16 | Kho WORM, nhật ký kiểm toán | [ ] | [ ] | [Site], Z6/Z5 | [ ] |
| AS-10, AS-11, AS-12 | Keycloak, OpenBao, chính sách OPA | [ ] | [ ] | [Site], Z6 | [ ] |
| AS-13, AS-14, AS-15 | Argo CD và Git, CI và Harbor, bộ quan sát | [ ] | [ ] | [Site], Z7 | [ ] |
| AS-17 | Kho sao lưu bất biến | [ ] | [ ] | [Vị trí ngoài site] | [ ] |
| AS-18 | Máy chủ, nút K8s, thiết bị mạng | [ ] | [ ] | [Site, giá máy] | [ ] |
| AS-19 | Thông tin xác thực NDXP, PayGov | [ ] | — | OpenBao | [ ] |

: Phụ lục A. Danh mục tài sản (mẫu điền)

### Phụ lục B. Văn bản viện dẫn

Văn bản được chia hai nhóm như D03-07 §2.2; mã `CMP-LAW-nn` và `STD-nn` theo D03-07. Văn bản hiện hành là căn cứ chính; văn bản kế thừa chỉ dùng đối chiếu hoặc khi thẩm định theo chuyển tiếp.

| Nhóm | Văn bản | Dùng ở mục |
|---|---|---|
| Hiện hành | Luật An ninh mạng số 116/2025/QH15 (CMP-LAW-16) | 2, 6.3 |
| Hiện hành | Nghị định 331/2026/NĐ-CP — Điều 8, 25, 30, 31, 39 đã tra; thành phần hồ sơ, tiêu chí cấp độ 4 chưa xác minh (CMP-LAW-17) | 1.2, 5, 6.3, 9 |
| Hiện hành | TCVN 14423:2026, chương 5 (cấp độ 3), chương 6 (cấp độ 4), Phụ lục A (STD-06) | 6, 7 |
| Hiện hành | Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 (CMP-LAW-05); Nghị định 356/2025/NĐ-CP (CMP-LAW-18) | 4.9, 6.3 |
| Hiện hành | Luật Dữ liệu số 60/2024/QH15 (CMP-LAW-01) | 5.3 |
| Hiện hành | Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu bắt buộc (CMP-LAW-19) | 4.7 |
| Hiện hành | Quyết định 8297/QĐ-BCA-A05 về tiêu chí an ninh mạng cho cloud phục vụ CPĐT, chưa xác minh chi tiết (CMP-LAW-20) | 6.4 |
| Tham khảo kỹ thuật | OWASP ASVS 5.0 (STD-03), OWASP API Security Top 10 2023 (STD-07), CIS Kubernetes Benchmark (STD-08), SLSA (STD-09) | 6.2, 8 |
| Kế thừa | Nghị định 85/2016/NĐ-CP (CMP-LAW-06), chỉ khi áp dụng chuyển tiếp | 9 |
| Kế thừa | Thông tư 12/2022/TT-BTTTT (CMP-LAW-07); TCVN 11930:2017 (CMP-LAW-08), đã bị TCVN 14423:2026 thay thế | 1.2, 6.1 |
| Hết hiệu lực | Nghị định 13/2023/NĐ-CP (CMP-LAW-04), thay bởi Luật 91/2025 và Nghị định 356/2025 | 4.9 |

: Phụ lục B. Văn bản viện dẫn

### Phụ lục C. Bảng điền thông tin

Bảng dưới đây tổng hợp mọi chỗ điền của bản mẫu, nguồn và người cung cấp. Hồ sơ chỉ được trình khi mọi dòng bắt buộc đã điền.

| Mã | Thông tin | Nguồn | Người cung cấp | Bắt buộc |
|---|---|---|---|---|
| TT-01…TT-11 | Thông tin định danh (mục 3.1) | Quyết định giao nhiệm vụ, phê duyệt đầu tư | Chủ quản | Có |
| TT-20 | Số người dùng theo nhóm | Khảo sát, danh sách tài khoản LGSP cũ | Đơn vị vận hành | Có |
| TT-21 | Số HTTT kết nối, số API, số luồng | Danh mục của LGSP cũ, kế hoạch kết nối | Đơn vị vận hành | Có |
| TT-22 | Lượt gọi API/ngày, tỷ lệ tới NDXP | Nhật ký gateway LGSP cũ (Q330 của D03-09) | Đơn vị vận hành | Có |
| TT-23 | Giao dịch thanh toán/ngày | Số liệu PayGov của tỉnh | Đơn vị thụ hưởng | Có nếu bật PH-19 |
| TT-24 | Dân số tỉnh; số chủ thể DLCN cơ bản, nhạy cảm (mục 4.9) | Niên giám thống kê; tính theo phương pháp mục 4.9 | Chủ quản, pháp chế | Có |
| TT-25 | Có bật PH-06 trong phạm vi hồ sơ không | Kế hoạch triển khai | Chủ quản | Có |
| TT-30 | Số máy chủ, thiết bị theo site | D03-09 §5.5/5.6, hợp đồng hạ tầng | Bên cung cấp hạ tầng | Có |
| TT-40 | Văn bản xác nhận an toàn vật lý (Phụ lục A TCVN 14423:2026) | TTDL tỉnh hoặc nhà cung cấp cloud | Bên cung cấp hạ tầng | Có |
| TT-41 | Quyết định cấp độ của hạ tầng cloud | Nhà cung cấp cloud | Bên cung cấp hạ tầng | `HT-B` |
| TT-50 | Tình huống chuyển tiếp S1–S4, số quyết định cấp độ của LGSP cũ | Hồ sơ LGSP cũ | Chủ quản | Có |
| TT-51 | Quyết định giao bộ phận chuyên trách ANM, danh sách nhân sự | Chủ quản | Chủ quản | Có |
| TT-52 | Quyết định phê duyệt cấp độ của nền tảng (cho hồ sơ rút gọn của tỉnh) | Chủ quản nền tảng | Chủ quản nền tảng | `HT-B` |

: Phụ lục C. Bảng điền thông tin

## 11. Mã và thuật ngữ mới đề xuất bổ sung D00-01

Tài liệu dùng ba loại mã nội bộ mới, đề xuất luồng lõi bổ sung vào D00-01 §3.1. Tài liệu cũng đề xuất D03-07 bổ sung mã tài sản cho ClickHouse (ví dụ `AS-20`), vì thành phần này có ở D03-09 và SAD nhưng chưa có trong kiểm kê D03-07 §3.1.

| Mã | Đối tượng | Định nghĩa tại | Ví dụ |
|---|---|---|---|
| `TCD-{nn}` | Tiêu chí xác định cấp độ được áp dụng trong hồ sơ (mã nội bộ, không phải số điều khoản) | D03-08 §5.3 | `TCD-01` |
| `CD4-{nn}` | Yếu tố có thể đẩy hệ thống lên cấp độ 4, kích hoạt đánh giá lại | D03-08 §5.5 | `CD4-03` |
| `TT-{nn}` | Trường thông tin cần điền trong bản mẫu hồ sơ | D03-08 Phụ lục C | `TT-24` |

: Mã và thuật ngữ mới đề xuất bổ sung D00-01

Thuật ngữ đề xuất: **hồ sơ nền tảng** (hồ sơ cấp độ của nền tảng dùng chung, do chủ quản nền tảng lập) và **hồ sơ rút gọn của tỉnh** (hồ sơ cho phần sử dụng của một tỉnh trên nền tảng dùng chung, dẫn chiếu hồ sơ nền tảng), định nghĩa ở mục 5.6; **DLCN nhạy cảm (pháp lý)** để phân biệt với mức phân loại nội bộ "Nhạy cảm" (mục 4.9).

## 12. Truy vết

Bảng dưới đây cho biết yêu cầu nào được tài liệu này đáp ứng và ở mục nào.

| Nguồn | Nội dung | Mục đáp ứng |
|---|---|---|
| BO-04, KPI-08 | Hồ sơ cấp độ 3 được phê duyệt trước vận hành chính thức | 2, 5, 5.7, 8 |
| BO-06, NFR-00-060 | Nền tảng dùng chung nhiều tỉnh | 1.3, 5.2, 5.6 |
| RB-06 (D02-02) | Đạt cấp độ 3, sẵn sàng cấp độ 4 | 5.4, 6, 7 |
| SH-07 (D02-01) | Cơ quan chuyên trách cần hồ sơ đầy đủ | 1.2, 2 |
| REQ-09 | Phân loại dữ liệu, kiểm soát khai thác theo mục đích | 4.8, 4.9, 6.2 |
| NFR-00-010, NFR-00-014 | Sẵn sàng, RPO/RTO | 4.5, 6.2, 8 |
| NFR-00-020…029 | Yêu cầu bảo mật tối thiểu | 6.2 (qua D03-07 mục 11d) |
| NFR-00-024 | ASVS 5.0 mức 2 | 6.2, 8 |
| ADR-030 | Cấp độ 3, chừa điểm cấp độ 4 | 5.4, 7 |
| ADR-031, ADR-032 | Nhật ký WORM; mã hóa trường | 6.2 |
| ADR-034, ADR-036 | DR hai site; hai hồ sơ triển khai | 1.3, 4.5 |
| LGC-NFR-008 | Yêu cầu ATTT máy chủ, CSDL, ứng dụng của hệ cũ | 6.2 |
| D05-01 RG-4 | Hồ sơ cấp độ có bằng chứng kiểm thử | 8 |

: Truy vết

## 13. Câu hỏi mở

Danh sách dưới đây tổng hợp câu hỏi mở của tài liệu (dải Q320–Q329). Ba câu hỏi Q320, Q321, Q323 chặn việc trình hồ sơ và cần được trả lời trước tiên.

| Mã | Nội dung tóm tắt | Mục | Người trả lời |
|---|---|---|---|
| Q320 | Thành phần hồ sơ và mẫu biểu theo Điều 25 Nghị định 331/2026 | 1.2 | Pháp chế, bộ phận chuyên trách ANM |
| Q321 | Ai thẩm định, ai phê duyệt cấp độ 3; thời hạn | 2 | Pháp chế, Công an tỉnh |
| Q322 | Yêu cầu cấp độ tối thiểu của NDXP, PayGov với LGSP kết nối; đăng ký theo nền tảng hay theo tỉnh | 4.7 | Đơn vị quản lý NDXP, PayGov |
| Q323 | Tiêu chí cấp độ 4 (ngưỡng DLCN, phạm vi liên tỉnh, nền tảng dùng chung); chủ quản của nền tảng dùng chung | 5.3, 5.5, 5.6 | Chủ đầu tư, Bộ Công an |
| Q324 | PH-06 có là dữ liệu quan trọng/cốt lõi; quan hệ với cấp độ 4 | 5.3 | Pháp chế, cơ quan quản lý dữ liệu |
| Q325 | Cách đếm chủ thể DLCN; định nghĩa DLCN nhạy cảm áp cho dữ liệu đi qua | 4.9 | Pháp chế |
| Q326 | Mốc thời hạn Điều 39; Datahub là hệ mới hay nâng cấp; xử lý LGSP cũ chưa phê duyệt | 9 | Pháp chế, chủ quản |
| Q327 | Số lượng, tiêu chuẩn nhân sự chuyên trách theo Điều 31; thuê ngoài | 6.3 | Pháp chế, chủ quản |
| Q328 | Kiểm tra trước vận hành bởi tổ chức độc lập; tần suất kiểm tra định kỳ cấp độ 3 | 6.3, 8 | Pháp chế, Bộ Công an |
| Q329 | Cấp độ yêu cầu của hạ tầng cloud và hình thức kế thừa biện pháp theo Điều 30 | 4.2, 6.4 | Nhà cung cấp cloud, Bộ Công an |

: Câu hỏi mở

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: bản mẫu hồ sơ đề xuất cấp độ theo Nghị định 331/2026/NĐ-CP gồm văn bản đề nghị, thông tin chung, mô tả hệ thống, thuyết minh cấp độ 3, phương án bảo vệ, lộ trình cấp độ 4, kế hoạch kiểm tra, chuyển tiếp từ LGSP cũ, phụ lục |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Giữ nguyên cấu trúc mẫu hồ sơ và văn bản đề nghị; thêm Tóm tắt cho hội đồng thẩm định, người đọc (1.5), thuật ngữ (1.6), tài liệu tham chiếu (1.7), cấu trúc tài liệu (1.8); viết lại chú thích bảng và hình, tách ba chú thích trùng; đổi ba sơ đồ sang chiều dọc; bổ sung thuyết minh sơ đồ thẩm định, phê duyệt cấp độ 3 |
